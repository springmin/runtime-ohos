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

## 1. 能力矩阵

| 能力 | 我们当前状态（引用覆盖矩阵） | 可用 Kit/技能 | 关键 API（import / 权限 / syscap / 设备） | 落地到 MAUI 的形态 | 工作量 | 风险 | 建议 |
|---|---|---|---|---|---|---|---|
| TTS（TextToSpeech） | 链路已接、sink 如实返回不可用（覆盖矩阵 §4；审计 §5c；`OpenHarmonyTextToSpeech.cs:1-9`、`Index.ets:2223`） | **无**：25 Kit 无 Core Speech Kit；`02-development` 检索 `CoreSpeechKit`/`textToSpeech` 0 命中 | 无（技能未提供；本机 SDK 无 `@kit.CoreSpeechKit`/`@ohos.ai.tts`） | 平台扩展（替换现有 TTS sink） | S（待引擎） | 无引擎可用 | **维持门控**（此前判定不变） |
| Map / POI / 路线 | 未实现（覆盖矩阵 §4；审计 §7/§20） | Map Kit：`hmos-map-kit-{map-creation,poi-search,route-planning}` | `import { map, mapCommon, MapComponent } from '@kit.MapKit'`；`site.searchByText(params): Promise<SearchByTextResult>`；`navi` 路线/导航；需 AGC 开通地图服务 + AppKey | 平台扩展（无 Essentials 对应）/仅文档 | L* | AGC AppKey、HMS 设备 | 维持门控；记录 HarmonyOS 分支 |
| 系统分享面板 / 多文件 | 文本 + 单文件（隐式 `sendData` Want）；多文件记录在案 no-op（覆盖矩阵 §2 `Share` 行、§4；`OpenHarmonyAppLauncher.cs:22,193`） | Share Kit：`hmos-share-kit-panel-share`（one-sdk 语料） | `import { systemShare } from '@kit.ShareKit'`；`new systemShare.SharedData({ utd, content\|uri })`；`new systemShare.ShareController(data).show(context, opts)`；≤500 条/200KB；起始 4.1.0(11)；手机/平板/2in1 | Essentials `Share` 多文件分支（平台扩展） | M* | HMS 设备；`utd`/uri 语义 | 维持门控；记录 HarmonyOS 分支 |
| 扫码（默认 / 自定义） | 未实现（无 Essentials 对应；相机 picker 已有） | Scan Kit：`hmos-scan-kit-defaultscan`/`-customscan` | `import { scanBarcode, scanCore } from '@kit.ScanKit'`；`scanBarcode.startScanForResult(ctx)`；`canIUse('SystemCapability.Multimedia.Scan.ScanBarcode')`；默认免 CAMERA、自定义需 `ohos.permission.CAMERA`；起始 4.0.0(10) | 平台扩展（新增） | M* | 设备 syscap | 维持门控；记录 HarmonyOS 分支 |
| 远端推送（Push） | 本地通知已实现（覆盖矩阵 §1b BATCH-3 `PostNotifications`）；华为 Push 未实现 | Push Kit：`hmos-push-kit`（+token/notification/background/voip） | `import { pushService } from '@kit.PushKit'`；`pushService.getToken(): Promise<string>`；需 AGC 开通推送 + 含推送权限 Profile；无需 module 权限 | 平台扩展（Push token / 消息） | M* | AGC 开通 + 签名绑定 | 维持门控 |
| 账号一键登录 | WebAuthenticator 诚实降级（覆盖矩阵 §3：`FeatureNotSupportedException` + status） | Account Kit：`hmos-account-kit-quicklogin-client` | `import { authentication, loginComponentManager } from '@kit.AccountKit'`；`createAuthorizationWithHuaweiIDRequest()` + `scopes=['quickLoginAnonymousPhone']`；`LoginWithHuaweiIDButton`；syscap `SystemCapability.AuthenticationServices.HuaweiID.UIComponent`；设备 Phone/PC2in1/Tablet/TV（TV 自 5.1.1(19)） | 平台扩展 / 仅文档（与 WebAuthenticator 生态不同） | L* | 权限审批（1001502014）+ 服务端换号 | 维持门控 |
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

**前提**：7 个重点项全部是 HMS Kit；当前 OpenHarmony SDK 探针 0 命中 → 本机栈内**均不能补齐**；「可补齐」
= 换 HarmonyOS SDK + HMS 设备 + 满足 AGC/权益/签名后的最小交付。TTS 为「技能库 + SDK」双否。按补齐可行性排序：

| # | 项 | 是否真能补齐 | 技能内 API 证据（原文） | 最小可交付 / 验收点 |
|---|---|---|---|---|
| 1 | 系统分享面板 / 多文件（Share） | **可补齐\***（技能覆盖最完整、无权限申请、直接映射 Essentials `Share`） | `import { systemShare } from '@kit.ShareKit'`；`let controller: systemShare.ShareController = new systemShare.ShareController(data)`；`controller.show(context, {...})`；`new systemShare.SharedData({ utd: utd.UniformDataType.PLAIN_TEXT, content: 'Hello HarmonyOS' })`；`controller.on('shareCompleted', ...)` | 交付：壳 `systemShare` sink + host `ohos_host_share_multi` + `ShareMultipleFilesRequest` 分支；验收：多文件面板弹出、`shareCompleted` 回执、OpenHarmony 上仍走既有 no-op |
| 2 | 扫码（Scan） | **可补齐\***（默认界面单 API、免 CAMERA 权限、`canIUse` 自检） | `import { scanBarcode, scanCore } from '@kit.ScanKit'`；`scanBarcode.startScanForResult(this.uiContext.getHostContext())`；`const isScanBarCode = canIUse('SystemCapability.Multimedia.Scan.ScanBarcode')` | 交付：平台扩展（默认界面扫码）+ 壳 sink；验收：返回 `result.originalValue`；不支持设备走 syscap 分支 |
| 3 | Map（Map Kit） | **可补齐\***（地图 / POI / 路线技能齐全） | `import { map, mapCommon, MapComponent } from '@kit.MapKit'`；`import { site } from '@kit.MapKit'`；`site.searchByText(params): Promise<SearchByTextResult>`；`navi` 路线规划 | 交付：`IMapService`（嵌入 MapComponent 平台视图）或仅 AppLinking 跳花瓣地图；验收：渲染 + POI + WGS84→GCJ02 |
| 4 | Push（Push Kit） | **可补齐\***（token 链路简单，但依赖 AGC 开通） | `import { pushService } from '@kit.PushKit'`；`pushService.getToken().then((token: string) => ...)` | 交付：token 获取 + 上报；验收：日志出现 token；失败按 1000900010 排查 |
| 5 | 账号一键登录（Account Kit） | **可补齐\***（门槛最高：权限审批 + 服务端换号） | `import { authentication, loginComponentManager } from '@kit.AccountKit'`；`new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest()`；`authRequest.scopes = ['quickLoginAnonymousPhone']`；`LoginWithHuaweiIDButton({ params: { loginType: loginComponentManager.LoginType.QUICK_LOGIN, ... } })` | 交付：登录页 + 匿名手机号获取 + 服务端换取明文手机号；验收：无 1001502014 / 1001500001 |
| 6 | TTS（Core Speech Kit） | **不能补齐**（技能库与 SDK 双否） | 技能库无 Core Speech Kit；SDK 无 `@kit.CoreSpeechKit`/`@ohos.ai.tts`；sink 注释 `Index.ets:2223`（静态 import `Cannot find module`） | 维持：sink 如实 `-1`；待 SDK 含引擎时替换 sink（S） |
| 7 | Live View | **可补齐\***（非 MAUI 能力；需权益审批 + 场景白名单） | `import { liveViewManager } from '@kit.LiveViewKit'`；`liveViewManager.isLiveViewEnabled()`；`liveViewManager.startLiveView(view)`；syscap `SystemCapability.LiveView.LiveViewService` | 仅记录：有明确业务场景（配送/打车/计时…）再立项 |

\* 仅 HarmonyOS SDK + HMS 设备分支且满足 AGC/权益/签名门槛；当前 OpenHarmony 栈不可用。未进 Top：**Payment**
（需商户体系）、**Ads**（编译期可得但设备侧不确定）——均按「仅记录」处置。

## 3. 仍不可行 / 需外部条件

- **Hot Reload**：`hdc` 被组织策略拦截（`E00C001`）；且需 `dotnet watch`/agent、设备通道与运行时 metadata update——三项均不在 Kit 技能覆盖范围（最终状态 §2 D4）。
- **arm32**：无 32 位设备验证路径；N13/S1a/A1 只发 arm64/x64；启动条件 = 拿到 32 位设备/模拟器（arm32 差距分析 §0）。
- **HMS Kit 通道（Share/Scan/Map/Push/Account/LiveView/Payment 共性）**：需 ① 以 HarmonyOS SDK（DevEco/HMS）替换 OpenHarmony SDK 并切换 `runtimeOS`；② AGC 侧开通/审批（推送、地图服务 AppKey、一键登录权限、实况窗权益、支付商户）；③ 签名证书指纹绑定 + 含权益的 Profile；④ HMS 设备。属项目级决策，不在本切片单点修复范围。
- **WebAuthenticator**：无 Kit 可解，维持诚实降级；工程路径见覆盖矩阵 §3（①–④，前三件可离设备，工作量 M）。
- **MediaElement**：无 Kit 门控；如落地需在平台层自建 AudioKit/MediaKit/AVSessionKit 播放器（以社区工具包契约为准）。
- **SecureStorage 硬件路径**：待真机确认 HUKS 应答；否则维持每安装文件密钥（已记录非硬件后备）。

## 4. 不确定项

1. **探针边界**：本机 SDK 结论为静态文件遍历（0 命中）；动态 `import()` 缺失模块能否过 hvigor 编译未实测——TTS 静态 import 已证 `Cannot find module`（`Index.ets:2223-2225`），接入 HMS Kit 不能假定可绕行。
2. **设备差异**：技能仅对 Share（手机/平板/2in1）、Account（Phone/PC2in1/Tablet/TV）、Scan（syscap 自检）、LiveView（syscap）给出设备/能力信息；Map/Push/Payment 的设备清单未标注，真机 `canIUse` 未取证。
3. **AGC 门槛**：Push `1000900010`（未开通/签名）、Account `1001502014`（未申请 scope 权限）、Map AppKey、LiveView 权益与场景白名单、Payment 商户/证书——均需 AGC 侧人工操作/审批，本环境不可代办。
4. **Ads 例外**：`@kit.AdsKit` 在 SDK 中存在且 API 可编译（`AdLoader.loadAd` / `advertising.showAd`），但 OpenHarmony 设备是否有广告服务/广告位未证（预期 801 / 21800003）。
5. **版本映射**：技能为 HarmonyOS 6.x 文档（起始版本 4.0.0(10)–6.0.2(22)），与本机 API 26 OpenHarmony Beta SDK 的波段映射未验证。
6. **真机待证**：TTS `-1`、SecureStorage HUKS 分支、Share 多文件面板、Scan syscap 分支均未上设备。

## 5. 结论

- **可补齐（条件性，仅 HarmonyOS 分支）5 项**：Share、Scan、Map、Push、Account；**仅记录 3 项**：LiveView、Payment、Ads；**维持门控 6 项**：TTS（双否）、Hot Reload、arm32、WebAuthenticator、SecureStorage 兜底、MediaElement。
- 在当前 OpenHarmony SDK 26.0.0.18 + OpenHarmony 设备上，本轮技能核查**未改变任何既有门控**；新增的确切信息是「这些 Kit 在 HarmonyOS 侧确有其事，且有可引用的 API 证据」，可作为未来切换 HarmonyOS 工具链时的落地清单。
