# 鸿蒙 Kit 能力缺口复核（KIT-GAP，2026-09-24）

> **目的**：用新装鸿蒙 Kit 技能库（`harmonyos-agent-skills/02-development/**`：`hmos-one-sdk-skill` 25-Kit 语料
> + map-kit / scan-kit / push-kit / account-kit / live-view-kit / payment-kit / ads-kit 专项技能）重新盘点此前
> 判定「缺失 / 被门控」的能力，产出可补齐清单与 API 证据。
> **方法**：只读技能文档与代码；对**本机实际编译用 SDK**（`ohos-sdk 26.0.0.18_2`，
> `ohos-workload/scripts/build-arkts-shell.sh:52`）做逐模块探针。未上设备、未构建、未改代码。
> **口径**：本切片以 OpenHarmony SDK + `runtimeOS=OpenHarmony` 构建（`build-arkts-shell.sh:41,52`）。技能库中的
> Map/Share/Scan/Push/Account/LiveView/Payment 均为 **HarmonyOS（HMS）Kit**；SDK 探针：47 个 `@kit.*` 中
> `systemShare` / `MapComponentController` / `scanBarcode` / `pushService` / `HuaweiID` / `liveViewManager` /
> `paymentService` / `CoreSpeechKit` **全部 0 命中**。唯一例外是 **`@kit.AdsKit`**（`@ohos.advertising` +
> `@ohos.identifier.oaid` 存在）。下文「可补齐」一律指 **HarmonyOS SDK + HMS 设备分支**，不代表当前栈可用。
>
> **KIT-IMPL 回填（2026-09-25）**：本轮已做可行性实验并落地首批，结论如下（完整报告与日志：
> `/data/storage/el2/base/tmp/opencode/kit-impl/feasibility-report.md`、`probe-a*/`）：
>
> 1. **动态 import 结论**：字面量 `import('@kit.ShareKit')` 等在 OpenHarmony SDK 下是**硬编译错误**
>    （5 Kit 全部 `10505001 Cannot find module … or its corresponding type declarations`，`typeCheck` 真假皆然；
>    `@kit.AdsKit` 存在故正常解析，作为阳性对照）；**变量说明符 + 本地结构接口 cast** 可编译
>    （`CompileArkTS Finished`，abc `13.0.1.0`，224,076 B），运行时在无 Kit 设备抛错并被捕获 → 语言层面只能
>    做「特性探测 + 优雅降级」，无法在 OpenHarmony SDK 上静态编译 Kit 调用。
> 2. **HarmonyOS SDK 分支**：本构建机**无** HarmonyOS SDK（仅 `ohos-sdk 26.0.0.18_1/_2`；设备侧 DevEco 用的
>    `/data/app/sdk.org/sdk_1.0.0/default/hms/ets` 不在本机）。设备侧 DevEco 构建证据：`runtimeOS=HarmonyOS` +
>    `compatibleSdkVersion 6.1.0(23)` + `hms/ets` → abc **`13.0.1.0`**（11,124 B），**过 13.0.1.0 门禁**。
>    `build-arkts-shell.sh` 已增 opt-in `ARKTS_SDK_FLAVOR=harmony`（默认 openharmony 不变；SDK 根
>    `ARKTS_HARMONY_SDK_ROOT`/`DEVECO_SDK_HOME`、`externalApiPaths` 加 `hms/ets`、`runtimeOS=HarmonyOS`、
>    `compatibleSdkVersion 6.1.0(23)`；abc 头门禁仍为 `13.0.1.0`），selftest T14 覆盖两 flavor 与拒绝路径；
>    完整构建需在装有 HarmonyOS SDK 的机器执行。
> 3. **首批已落地（Share + Scan）**：壳侧 `canIUse`/变量 import 探测成功才注册 sink（Share：
>    `systemShare.SharedData/ShareController.show` 多文件；Scan：`canIUse('SystemCapability.Multimedia.Scan.ScanBarcode')` +
>    `scanBarcode.startScanForResult`），host 侧 `ohos_host_share_kit_share` / `ohos_host_scan_*`，托管侧
>    `OpenHarmonyShareKitBridge`（多文件分支）与 `OpenHarmonyScan`（平台扩展）；缺失/失败一律降级并记状态。
>    harness 新增 kit1/kit2/kit3 三条断言（324 [verify]，floor 304）。OpenHarmony 设备上两个 sink 均不注册，
>    降级路径已离线验证（`kit3`）。
> 4. **仍需外部条件**：**Push**（AGC 开通 + 含推送权限 Profile + `1000900010` 排障）、**Account**（一键登录
>    scope 审批 `1001502014` + 服务端换号）、**Map**（AGC AppKey）、LiveView/Payment（权益/商户）——均未落地；
>    且全部需要 **HMS 设备** 与 **HarmonyOS SDK 构建**才可真机验收。
>
> **KIT-EXT2 回填（2026-09-25，第二批 Push/Account/Map）**：沿用 Share/Scan 的「变量说明符
> `import()` + 本地结构接口 cast + 特性探测才注册 sink」模式，三 Kit 的**探测/降级链路已落地**，
> 真机点亮仍需外部条件：
>
> 1. **Push**：壳 `probePushKit`/`registerPushSink`（`pushService.getToken()`/`deleteToken()`），host
>    `ohos_host_push_{available,request,register_result,result}`（op 0/1），托管 `OpenHarmonyPush`
>    （`GetTokenAsync`/`DeleteTokenAsync`/`IsSupported`，错误码透传并命名 `1000900010` 签名/AGC、
>    `1000900012` 未开通权益、`1000900011/13/14` 网络/跨区/设备不支持）。无 Kit 设备：sink 不注册，
>    GetToken/DeleteToken 返回 `Unavailable`、`IsSupported=false`（kit6 离线证据）。
> 2. **Account**：壳 `probeAccountKit`/`registerAccountSink`（
>    `new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest()` + `state`
>    + `AuthenticationController.executeRequest`），op 0 = `quickLoginAnonymousPhone`
>    （`forceAuthorization=false`，回 payload=匿名手机号），op 1 = 通用授权（`serviceauthcode`
>    permission，回 payload=`response.data.authorizationCode`，服务端换取明文手机号）；host
>    `ohos_host_account_*`；托管 `OpenHarmonyAccount`（`GetQuickLoginAnonymousPhoneAsync`/
>    `AuthorizeAsync(scopes)`/`IsSupported`），命名 `1001502014`（未申请/未审批 scope）、
>    `1001500001`（指纹证书不符）、`1001502001/2012/2003/2005/2009/0002/0003`。
> 3. **Map（尽力）**：`MapComponent` 是 ArkUI 组件，编译期需要组件声明，OpenHarmony SDK 下无法表达
>    （字面量 import 硬错；组件调用无法用动态 cast 生成）。已落地**方案 (b) 能力探测 + 预留 sink**：
>    壳 `probeMapKit`/`registerMapSink` 回 capability bits（bit0 = `@kit.MapKit` 可解析；
>    bit1 = 覆盖层已实现 = 0），host `ohos_host_map_{available,probe,register_result,result}`，托管
>    `OpenHarmonyMap.QueryCapabilitiesAsync`/`IsSupported`（无 Kit 返回 null/false）。**方案 (a)**
>    （壳内 `MapComponent` 覆盖层由托管控制显隐，XComponent/ArkWeb 模式 + MapComponentController
>    的 marker/camera 转发）只能在 `ARKTS_SDK_FLAVOR=harmony` 分支 + AGC AppKey 下构建，落地方案与
>    前置见 `ohos-workload/docs/openharmony-hap-packaging.md`「Kit feature probes and AGC
>    prerequisites」。
> 4. **验证与门禁**：host 导出契约 118 → 130（`host-exports.txt` + `nm -D` 全命中）；UI/headless abc
>    重编（`13.0.1.0`；UI 245,412 B / headless 18,532 B）并同步 preview.22/23/24 的 abc-provenance；
>    交互套件新增 kit4/kit5/kit6 三条（329 行，floor 309）；OpenHarmony SDK/无 host 环境下三 Kit 的
>    sink 均不注册、四个托管入口全部 `Unavailable`/null 且不抛（kit6）。
> 5. **仍需外部条件（未变）**：① HarmonyOS SDK 构建（本机无）；② AGC：Push 开通+含推送权益 Profile、
>    Account 一键登录 scope 审批、Map 地图服务 AppKey；③ 签名证书指纹/包名与 AGC 一致；④ HMS 设备
>    真机验收。本环境不可代办。

## 1. 能力矩阵

| 能力 | 我们当前状态（引用覆盖矩阵） | 可用 Kit/技能 | 关键 API（import / 权限 / syscap / 设备） | 落地到 MAUI 的形态 | 工作量 | 风险 | 建议 |
|---|---|---|---|---|---|---|---|
| TTS（TextToSpeech） | 链路已接、sink 如实返回不可用（覆盖矩阵 §4；审计 §5c；`OpenHarmonyTextToSpeech.cs:1-9`、`Index.ets:2223`） | **无**：25 Kit 无 Core Speech Kit；`02-development` 检索 `CoreSpeechKit`/`textToSpeech` 0 命中 | 无（技能未提供；本机 SDK 无 `@kit.CoreSpeechKit`/`@ohos.ai.tts`） | 平台扩展（替换现有 TTS sink） | S（待引擎） | 无引擎可用 | **维持门控**（此前判定不变） |
| Map / POI / 路线 | 方案 (b) 已落地（能力探测 sink；覆盖矩阵 §4）；方案 (a) MapComponent overlay 排期（需 harmony flavor + AGC AppKey） | Map Kit：`hmos-map-kit-{map-creation,poi-search,route-planning}` | `import { map, mapCommon, MapComponent } from '@kit.MapKit'`；`site.searchByText(params): Promise<SearchByTextResult>`；`navi` 路线/导航；需 AGC 开通地图服务 + AppKey | 平台扩展（无 Essentials 对应）/仅文档 | L* | AGC AppKey、HMS 设备 | **KIT-EXT2 方案 (b) 已落地**：壳 `probeMapKit`/`registerMapSink` 能力位 + host `ohos_host_map_*` + 托管 `OpenHarmonyMap.QueryCapabilitiesAsync`/`MapKitImportable`/`IsSupported`（no-kit 返 null/false）；方案 (a) MapComponent 覆盖层已排期（需 harmony flavor + AppKey，见打包文档）；真机验收待 HMS 设备 |
| 系统分享面板 / 多文件 | 文本 + 单文件（隐式 `sendData` Want）；多文件已落地 Share Kit 分支（无 Kit 时记录在案 no-op）（覆盖矩阵 §2 `Share` 行、§4；`OpenHarmonyAppLauncher.cs:22,193`） | Share Kit：`hmos-share-kit-panel-share`（one-sdk 语料） | `import { systemShare } from '@kit.ShareKit'`；`new systemShare.SharedData({ utd, content\|uri })`；`new systemShare.ShareController(data).show(context, opts)`；≤500 条/200KB；起始 4.1.0(11)；手机/平板/2in1 | Essentials `Share` 多文件分支（平台扩展） | M* | HMS 设备；`utd`/uri 语义 | **KIT-IMPL 已落地**：壳 `registerShareKitSink` 探测成功才注册；无 Kit 时多文件仍走既有 no-op + 状态；真机验收待 HMS 设备 |
| 扫码（默认 / 自定义） | 未实现（无 Essentials 对应；相机 picker 已有） | Scan Kit：`hmos-scan-kit-defaultscan`/`-customscan` | `import { scanBarcode, scanCore } from '@kit.ScanKit'`；`scanBarcode.startScanForResult(ctx)`；`canIUse('SystemCapability.Multimedia.Scan.ScanBarcode')`；默认免 CAMERA、自定义需 `ohos.permission.CAMERA`；起始 4.0.0(10) | 平台扩展（新增） | M* | 设备 syscap | **KIT-IMPL 已落地**：壳 `registerScanSink`（canIUse+import 双门）+ 托管 `OpenHarmonyScan`（`IsSupported`/`ScanAsync`）；无 Kit 设备 `IsSupported=false`；真机验收待 HMS 设备 |
| 远端推送（Push） | 本地通知已实现（覆盖矩阵 §1b BATCH-3 `PostNotifications`）；华为 Push 探测链路已落地（特性探测：`GetTokenAsync`/`DeleteTokenAsync`；无 AGC/HMS 时 `Unavailable` 降级）——HMS/AGC 真机待验 | Push Kit：`hmos-push-kit`（+token/notification/background/voip） | `import { pushService } from '@kit.PushKit'`；`pushService.getToken(): Promise<string>`；需 AGC 开通推送 + 含推送权限 Profile；无需 module 权限 | 平台扩展（Push token / 消息） | M* | AGC 开通 + 签名绑定 | **KIT-EXT2 已实现（特性探测）**：壳 `@kit.PushKit` 变量探测 + `registerPushSink` + host 130 导出（`ohos_host_push_*`）+ 托管 `OpenHarmonyPush`（`GetTokenAsync`/`DeleteTokenAsync`，`1000900010`/`1000900012` 等映射；无 Kit 返 Unavailable）；AGC 开通 + Profile 后真机取 token，待 HMS 设备 |
| 账号一键登录 | WebAuthenticator 诚实降级（覆盖矩阵 §3：`FeatureNotSupportedException` + status）；Account Kit 探测链路已落地（特性探测：`AuthorizeAsync` + `getQuickLoginAnonymousPhone`；无 Kit 返 `Unavailable`）——scope 审批/HMS 真机待验 | Account Kit：`hmos-account-kit-quicklogin-client` | `import { authentication, loginComponentManager } from '@kit.AccountKit'`；`createAuthorizationWithHuaweiIDRequest()` + `scopes=['quickLoginAnonymousPhone']`；`LoginWithHuaweiIDButton`；syscap `SystemCapability.AuthenticationServices.HuaweiID.UIComponent`；设备 Phone/PC2in1/Tablet/TV（TV 自 5.1.1(19)） | 平台扩展 / 仅文档（与 WebAuthenticator 生态不同） | L* | 权限审批（1001502014）+ 服务端换号 | **KIT-EXT2 已实现（特性探测）**：壳 `registerAccountSink`（`AuthorizeAsync` + `getQuickLoginAnonymousPhone`；匿名手机号 + authorizationCode） + host `ohos_host_account_*` + 托管 `OpenHarmonyAccount`（`1001502014`/`1001500001` 等映射；无 Kit 返 Unavailable）；scope 审批后真机验收，待 HMS 设备 |
| Live View（实况窗） | 无记录（新评估） | Live View Kit：`hmos-live-view-kit-build-location` | `import { liveViewManager } from '@kit.LiveViewKit'`；`isLiveViewEnabled()`；`startLiveView(view)`；syscap `SystemCapability.LiveView.LiveViewService`；需权益 + 设备开关 + 场景白名单（9 类） | 仅文档（无 MAUI 对应） | L* | 权益审批 | 仅记录 |
| 支付（IAP / Payment） | 无记录（新评估） | Payment Kit：`hmos-payment-kit-huawei-payment-integration` | `import { paymentService } from '@kit.PaymentKit'`；`requestPayment(context, orderStr)`；`orderStr` 服务端预下单 | 仅文档 | L* | 商户 / 服务端 / 证书 | 仅记录 |
| 广告（Ads） | 无记录（新评估） | Ads Kit：`hmos-ads-kit-access`；**本机 SDK 唯一存在的相关 Kit** | `import { advertising, AdComponent, AutoAdComponent } from '@kit.AdsKit'`；`AdLoader.loadAd(...)`；`advertising.showAd(ad, opts, ctx)`；权限 `INTERNET` + `APP_TRACKING_CONSENT`；需 compatibleSdkVersion ≥ 5.0.5(17) | 平台扩展（可选） | M* | 设备广告服务 / 广告位（801、21800003） | 仅记录 |
| Hot Reload | 硬阻塞（最终状态 §2 D4：hdc 策略） | 无 Kit 相关 | —（`dotnet watch`/agent + 设备通道 + 运行时 metadata update） | — | — | `hdc` 组织策略 `E00C001` | 维持（外部条件） |
| arm32（`openharmony-arm`） | 暂缓（`2026-09-21-ohos-arm32-support-gap.md` §0） | 无 Kit 相关 | —（无 32 位设备；N13/S1a/A1 只发 arm64/x64） | — | L | 无设备验证路径 | 维持（需外部设备） |
| WebAuthenticator | 诚实降级（覆盖矩阵 §3 ①–④） | 无 Kit 可解 | —（壳 `onNewWant` + want 转交 + `module.json5` skills scheme 声明） | 平台扩展（工程改造） | M | 回调单实例 / 真机浏览器未证 | 维持门控；按矩阵路径推进 |
| SecureStorage | HUKS 优先、否则每安装文件密钥（覆盖矩阵 §2；`OpenHarmonySecureStorage.cs:1-3`） | `@kit.UniversalKeystoreKit`（在 SDK，非 25 Kit 技能） | HUKS 加解密（现有 sink） | 已在位 | S | HUKS 真机应答未证 | 维持；真机验证 HUKS 分支 |
| MediaElement | 未实现（覆盖矩阵 §3） | 无 Kit 覆盖 | —（OpenHarmony 侧可自建 AudioKit/MediaKit/AVSessionKit 播放层，非 Kit 门控） | 平台扩展（移植） | L | 社区工具包契约 | 维持（按需） |

\* 工作量为「仅 HarmonyOS 分支 + 满足外部门槛后」的估算；在当前 OpenHarmony SDK / 设备上均不可编译（探针 0 命中）。

## 2. Top 补齐建议（重点项逐条结论）

**前提**：7 个重点项全部是 HMS Kit；当前 OpenHarmony SDK 探针 0 命中 → 本机栈内**不能真调用**，只能以
「特性探测 + 降级」承载（Share/Scan/Push/Account/Map-(b) 已落地）；Kit 真调用 = 换 HarmonyOS SDK + HMS 设备
+ 满足 AGC/权益/签名后的最小交付。TTS 为「技能库 + SDK」双否。按补齐可行性排序：

| # | 项 | 是否真能补齐 | 技能内 API 证据（原文） | 最小可交付 / 验收点 |
|---|---|---|---|---|
| 1 | 系统分享面板 / 多文件（Share） | **可补齐\* + 首批已落地**（技能覆盖最完整、无权限申请、直接映射 Essentials `Share`） | `import { systemShare } from '@kit.ShareKit'`；`let controller: systemShare.ShareController = new systemShare.ShareController(data)`；`controller.show(context, {...})`；`new systemShare.SharedData({ utd: utd.UniformDataType.PLAIN_TEXT, content: 'Hello HarmonyOS' })`；`controller.on('shareCompleted', ...)` | 交付：壳 `registerShareKitSink` + host `ohos_host_share_kit_share` + `ShareMultipleFilesRequest` 分支；OpenHarmony 上 sink 不注册、仍走既有 no-op；shareCompleted 回执：壳侧 `shareCompleted` 日志（托管 IShare 契约在派发时完成）；真机验收待 HMS 设备 |
| 2 | 扫码（Scan） | **可补齐\* + 首批已落地**（默认界面单 API、免 CAMERA 权限、`canIUse` 自检） | `import { scanBarcode, scanCore } from '@kit.ScanKit'`；`scanBarcode.startScanForResult(this.uiContext.getHostContext())`；`const isScanBarCode = canIUse('SystemCapability.Multimedia.Scan.ScanBarcode')` | 交付：壳 `registerScanSink` + host `ohos_host_scan_*` + 托管 `OpenHarmonyScan`（`IsSupported`/`ScanAsync`）；验收：返回 `result.originalValue`；不支持设备走 syscap 分支（离线已验证 `IsSupported=false`/`ScanAsync=null`） |
| 3 | Map（Map Kit） | **已实现（特性探测，方案 (b)）\***；方案 (a) 覆盖层排期（需 harmony flavor + AGC AppKey） | `import { map, mapCommon, MapComponent } from '@kit.MapKit'`；`import { site } from '@kit.MapKit'`；`site.searchByText(params): Promise<SearchByTextResult>`；`navi` 路线规划 | 交付（b，已落地）：`OpenHarmonyMap.QueryCapabilitiesAsync`/`MapKitImportable`/`IsSupported`；交付（a，排期）：`IMapService`（嵌入 MapComponent 覆盖层）或仅 AppLinking 跳花瓣地图；验收：capability bit0=1、渲染 + POI + WGS84→GCJ02 |
| 4 | Push（Push Kit） | **已实现（特性探测）\***（`OpenHarmonyPush` 已落地；AGC 开通后真机取 token） | `import { pushService } from '@kit.PushKit'`；`pushService.getToken().then((token: string) => ...)` | 交付：壳 sink + host 130 导出 + 托管 `OpenHarmonyPush`（`GetTokenAsync`/`DeleteTokenAsync`，已落地）；验收：日志出现 token；失败按 1000900010/1000900012 排查 |
| 5 | 账号一键登录（Account Kit） | **已实现（特性探测）\***（scope 审批 + 服务端换号仍待外部） | `import { authentication, loginComponentManager } from '@kit.AccountKit'`；`new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest()`；`authRequest.scopes = ['quickLoginAnonymousPhone']`；`LoginWithHuaweiIDButton({ params: { loginType: loginComponentManager.LoginType.QUICK_LOGIN, ... } })` | 交付：托管 `OpenHarmonyAccount`（`AuthorizeAsync` + `getQuickLoginAnonymousPhone`，已落地）+ 登录页 + 服务端换取明文手机号；验收：无 1001502014 / 1001500001 |
| 6 | TTS（Core Speech Kit） | **不能补齐**（技能库与 SDK 双否） | 技能库无 Core Speech Kit；SDK 无 `@kit.CoreSpeechKit`/`@ohos.ai.tts`；sink 注释 `Index.ets:2223`（静态 import `Cannot find module`） | 维持：sink 如实 `-1`；待 SDK 含引擎时替换 sink（S） |
| 7 | Live View | **可补齐\***（非 MAUI 能力；需权益审批 + 场景白名单） | `import { liveViewManager } from '@kit.LiveViewKit'`；`liveViewManager.isLiveViewEnabled()`；`liveViewManager.startLiveView(view)`；syscap `SystemCapability.LiveView.LiveViewService` | 仅记录：有明确业务场景（配送/打车/计时…）再立项 |

\* 仅 HarmonyOS SDK + HMS 设备分支且满足 AGC/权益/签名门槛；当前 OpenHarmony 栈不可用。未进 Top：**Payment**
（需商户体系）、**Ads**（编译期可得但设备侧不确定）——均按「仅记录」处置。

## 3. 仍不可行 / 需外部条件

- **Hot Reload**：`hdc` 被组织策略拦截（`E00C001`）；且需 `dotnet watch`/agent、设备通道与运行时 metadata update——三项均不在 Kit 技能覆盖范围（最终状态 §2 D4）。
- **arm32**：无 32 位设备验证路径；N13/S1a/A1 只发 arm64/x64；启动条件 = 拿到 32 位设备/模拟器（arm32 差距分析 §0）。
- **HMS Kit 通道（剩余 Map/Push/Account/LiveView/Payment 共性）**：需 ① 以 HarmonyOS SDK（DevEco/HMS）替换 OpenHarmony SDK 并切换 `runtimeOS`（**Share/Scan 的 SDK 分支与探测代码已就绪，`ARKTS_SDK_FLAVOR=harmony`**）；② AGC 侧开通/审批（推送、地图服务 AppKey、一键登录权限、实况窗权益、支付商户）；③ 签名证书指纹绑定 + 含权益的 Profile；④ HMS 设备。Share/Scan 已落地降级+探测链路，**真机验收**仍需 ①+④；Push/Account/Map 等需 ①–④ 全部。
- **WebAuthenticator**：无 Kit 可解，维持诚实降级；工程路径见覆盖矩阵 §3（①–④，前三件可离设备，工作量 M）。
- **MediaElement**：无 Kit 门控；如落地需在平台层自建 AudioKit/MediaKit/AVSessionKit 播放器（以社区工具包契约为准）。
- **SecureStorage 硬件路径**：待真机确认 HUKS 应答；否则维持每安装文件密钥（已记录非硬件后备）。

## 4. 不确定项

1. **探针边界（已解，2026-09-25）**：动态 `import()` 已实测（KIT-IMPL probe a/a2/a3/a4）：**字面量说明符在 OpenHarmony SDK 下是硬编译错误**（5 Kit 全部 `10505001 Cannot find module …`，`typeCheck` 真假皆然；`@kit.AdsKit` 存在故解析正常，阳性对照）；**变量说明符 `import(name)` + 本地结构接口 cast** 可过编译（`CompileArkTS Finished`，abc `13.0.1.0`/224,076 B），运行时缺 Kit 抛错被 catch。因此 OpenHarmony flavor 只能承载「探测 + 降级」，Kit 调用需 HarmonyOS SDK 分支（见文首 KIT-IMPL 回填与 `probe-a*/` 日志）。
2. **设备差异**：技能仅对 Share（手机/平板/2in1）、Account（Phone/PC2in1/Tablet/TV）、Scan（syscap 自检）、LiveView（syscap）给出设备/能力信息；Map/Push/Payment 的设备清单未标注，真机 `canIUse` 未取证。
3. **AGC 门槛**：Push `1000900010`（未开通/签名）、Account `1001502014`（未申请 scope 权限）、Map AppKey、LiveView 权益与场景白名单、Payment 商户/证书——均需 AGC 侧人工操作/审批，本环境不可代办。
4. **Ads 例外**：`@kit.AdsKit` 在 SDK 中存在且 API 可编译（`AdLoader.loadAd` / `advertising.showAd`），但 OpenHarmony 设备是否有广告服务/广告位未证（预期 801 / 21800003）。
5. **版本映射**：技能为 HarmonyOS 6.x 文档（起始版本 4.0.0(10)–6.0.2(22)），与本机 API 26 OpenHarmony Beta SDK 的波段映射未验证。
6. **真机待证**：TTS `-1`、SecureStorage HUKS 分支、Share 多文件面板、Scan syscap 分支均未上设备。

## 5. 结论

- **已实现（特性探测）5 项**：Share、Scan、Push、Account、Map（方案 (b)）——自「有条件可补齐」转入；真机点亮待 HMS 设备 + AGC 开通/审批；**仅记录 3 项**：LiveView、Payment、Ads；**维持门控 6 项**：TTS（双否）、Hot Reload、arm32、WebAuthenticator、SecureStorage 兜底、MediaElement。
- 在当前 OpenHarmony SDK 26.0.0.18 + OpenHarmony 设备上，本轮技能核查**未改变任何既有运行时门控**（Kit 真调用仍需 HarmonyOS 分支）；新增的确切信息是「这些 Kit 在 HarmonyOS 侧确有其事，且有可引用的 API 证据」，可作为未来切换 HarmonyOS 工具链时的落地清单。
- **KIT-IMPL 更新（2026-09-25）**：① Share 与 Scan 的**特性探测平台扩展已落地**（壳/宿主/托管/断言），在 OpenHarmony 设备上如实降级、在 HMS 设备上自动启用——不再是纯文档项；② `ARKTS_SDK_FLAVOR=harmony` 已进 `build-arkts-shell.sh`（默认行为不变、abc `13.0.1.0` 门禁保留），完整 HarmonyOS 构建仍需一台装有 HarmonyOS SDK 的机器；③ **Map/Push/Account 仍需外部条件**（AGC 开通/审批：Push `1000900010`、Account `1001502014`、Map AppKey）与 HMS 设备，本环境不可代办；④ 真机验收项：Share 多文件面板与 `shareCompleted`、Scan `originalValue`、HarmonyOS flavor 的 abc 装载（DevEco 证据仅到「6.1.0(23) → 13.0.1.0」）。
- **KIT-EXT2 更新（2026-09-25，第二批）**：① **Push/Account** 的探测+降级链路已落地（壳 sink、host `ohos_host_push_*`/`ohos_host_account_*`、托管 `OpenHarmonyPush`/`OpenHarmonyAccount`、错误码映射与断言），**Map** 以方案 (b) 落地能力探测/预留 sink（`MapKitImportable`/`IsSupported`；方案 (a) 覆盖层已排期，需 harmony flavor + AppKey）；② host 导出契约 118 → 130，UI/headless abc 重编并同步三个 pack 的 provenance（`13.0.1.0`），交互套件 329 行/floor 309（新增 kit4/kit5/kit6）；③ 四个新托管入口在 OpenHarmony SDK/无 host 环境全部 `Unavailable`/null 且不抛（离线证据）；④ **外部条件不变**：HarmonyOS SDK 构建、AGC（Push 开通+Profile、Account scope 审批、Map AppKey）、签名指纹一致、HMS 设备。真机验收项新增：`getToken()` 成功与 `1000900010/1000900012` 排障、匿名手机号/authorizationCode 与服务端换号、Map capability bit0=1。
