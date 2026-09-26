# 测试方交接：kit #27、KIT-EXT2（Push/Account/Map）与「无 HMS 降级 + 新 payload 运行」判定点（2026-09-27）

> 承接 kit #26 交接（`2026-09-26-ohos-tester-handoff-kit26.md`）：P2-INTEROP/TASK-MIG/PLAT-GAP 已随 #26 交付，
> 其判定点（新 payload 首次运行 / 原生桥 ABI / PLAT-GAP 恢复路径）与 #25 的权限弹窗 / Share 面板 / Scan 返回 /
> AOT 启动判定点**继续有效**（本文 §2 给出口径）；JIT A/B 指令与 `probe:`×`xwe` 判定表
> （kit #24 交接 §3–§5）**一字未改**。本文只覆盖 #27 的增量与判定点。
> 结论先行：kit #27 = **KIT-EXT2** —— 壳（ArkTS）对 **Push / Account / Map** 三个 HarmonyOS（HMS）Kit 做
> **特性探测**（变量 import 成功才注册 sink；无 Kit/AGC/HMS 时优雅降级：sink 不注册 / 值 null，**绝不抛异常**；
> ui/shell abc 234,620 → **245,412 B**）；宿主新增 **12 个 kit sink**（托管导出契约 118/118 → **130/130**）与
> **FIX-R1-NAPI-6D** 边界加固，反向条目（host→托管回调）改走 **off-runtime marshaller**
> （**FIX-R1-MARSHAL-OFF**：`[UnmanagedCallersOnly]` + `delegate* unmanaged[Cdecl]` thunk）；交互回归门禁
> **329 / floor 309**；`OpenHarmonyHapPayloadZip` opt-out 在三套 preview pack 同步；发布波含 verify-kit
> abc 重锚（`898f4a1`）与 maui/sdk CI pin 推进（`75cdc26`）。测试方的新判定点：**无 HMS 环境必须降级不抛**
> （Push token / Account 授权 / Map 能力位）+ **新重建 payload 能否正常跑**（承 #26）。
> **kit #27（已发布 2026-09-26）**：tar **195,951,029 B** / `74211b6e…`；解压树 **`6abff90e…`**；sidecar 89 B /
> `cc26f830…`（内容 = kit sha）；5 个 hap 各 **~75.56 MB**（签名变体 75,559,923–75,559,990 B，未签名 73,388,632 B；
> zip **278** 条；`libs/arm64-v8a` **269** 项 = 14 `.so` + 254 payload + `.dotnet-payload.json`）；
> abc **245,412 B** / `0e31b619…`（`13.0.1.0`；headless **18,532 B** / `d7ec9ca7…` 未变）；hap 内宿主
> `libopenharmonyhost.so` **265,120 B** / `366720e0…`（= pack **261,024 B** / `2ea5fd92…` + 4096 B 签名块；
> `DT_NEEDED` 5、UND 239 无 denylist 命中、导出 **130/130**）；hap 内 hosting DLL **55,296 B** / `4c121725…`
> （#26 为 55,808 B / `38f5a3d2…`，marshal-off 重建）、Maui.Graphics 16,384 B / `01a09b32…`；
> `resources.index` **1588/1780** B；`dotnet.zip` **254** 项 / 0 `.so`；包内 `verify-kit.sh` = **53,999 B** /
> `7f3420d2…`（abc 期望重锚到 245,412，`ohos-workload 898f4a1`；`dotnet.zip` 254 与 index ≤ 2 KiB 不变）；
> `tester-run.sh` 仍为 **v8**（73,375 B / `6ca2093e…`，本轮未改动、未重传，与仓库副本逐字节一致）；
> bundle **30,508,149 B** / `bc30c65b…`（Sdk pack 305,204 B；sdk-ohos 锚点已更新到 `3eb480fb4b`，
> `versions.env` `WORKLOAD_BUNDLE_SHA256 = bc30c65b…`）。数字入口 = release「## Integrity」；以 release 说明与
> 随包 `SHA256SUMS` 为准。
> 注：kit #27 包内的 9 份 tester 文档是 **kit #26 修订（7 份仍写 #26；由 runtime-ohos `87d3ffd9c9c` 导出）**，
> 且**不写死任何 64-hex 哈希**；本文与 release 说明是本轮的权威版本。

## 1. kit #27 相对 #26 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1 | **KIT-EXT2 壳特性探测（Push/Account/Map）**：壳模板 `probePushKit`/`registerPushSink`（`@kit.PushKit` 的 `pushService.getToken()`/`deleteToken()`）、`registerAccountSink`（`@kit.AccountKit` 的 `createAuthorizationWithHuaweiIDRequest()` + `getQuickLoginAnonymousPhone`）、`probeMapKit`/`registerMapSink`（capability bits，bit0 = `@kit.MapKit` 可解析）；变量 `import()` 探测成功才注册 sink | ui/shell abc 由 234,620 → **245,412 B**（hap 各 ~75.56 MB）；**无 Kit/AGC/HMS 时 sink 不注册、查询返回 `Unavailable`/null/false，不崩不抛**；HarmonyOS SDK 变体（`ARKTS_SDK_FLAVOR=harmony`）+ HMS 设备才走真 Kit | **Push token / Account 授权 / Map 能力位**（§2；本包 hap 无对应 UI 入口，首选判定是「降级不抛」，无入口按「未测」登记） |
| 2 | **宿主 12 个 kit sink + 导出契约 118→130**：`ohos_host_push_*` / `ohos_host_account_*` / `ohos_host_map_*`（含托管错误码映射：Push `1000900010`/`1000900012`、Account `1001502014`/`1001500001`）+ **FIX-R1-NAPI-6D** 边界加固；hap 内宿主 240,544 → **265,120 B**（pack 236,448 → **261,024 B**） | 既有原生桥行为不变；推送/账号/地图探针在 OpenHarmony SDK 下如实返回不可用（**离线证据：四个新托管入口全部 `Unavailable`/null 且不抛**） | **无 HMS 降级不抛**（§2）+ 原生桥调用无 `EntryPointNotFoundException`/`DllNotFoundException` |
| 3 | **FIX-R1-MARSHAL-OFF（反向条目 off-runtime marshaller）**：host→托管回调不再依赖运行时 marshaller，hosting 与 maui 切片改 `[UnmanagedCallersOnly]` + `delegate* unmanaged[Cdecl]` thunk（套件侧用指针驱动 `NativeThunks` 条目，避免从托管直调） | hap 内 hosting DLL 55,808 → **55,296 B**；权限结果、A11Y、推送注册结果等**回调路径行为应与 #26 一致** | **回调路径回归**（§2；与 #26 原生桥 ABI 判定合并） |
| 4 | **交互回归门禁 329 / floor 309**：kit4/kit5/kit6（Push/Account/Map 契约 + 无 Kit 降级）；指针驱动条目（`NativeThunks`） | 无新 UI 入口；交付方 CI 门禁（不是设备项），测试方无需动作 | — |
| 5 | **payload-zip opt-out pack 同步**：`OpenHarmonyHapPayloadZip` opt-out 在三套 preview pack 一致（`OpenHarmony.Hap.targets` 55,473 → **57,750 B**；Sdk.nupkg 290,854 → **305,204 B**） | 交付 kit 的 5 个 hap 行为不变；自建 hap 时该开关走 `dotnet.zip` 回退布局（按设计不带 payload-in-libs marker） | 消费方自建 hap（可选；无入口则按「未做」登记） |
| 6 | **重建与打包 / 发布波**：重建 abc（两变体）/宿主/hosting/Graphics、重打包 bundle（30,508,149 B）并更新 sdk-ohos 锚；`898f4a1` 把包内 verify-kit abc 期望重锚 245,412，`75cdc26` 推进 maui/sdk CI pin（CI 5/5 success） | 校验步骤、证据字段与 #26 相同，**只换 abc 期望值（245,412/18,532）**；`tester-run.sh` v8 未变 | 校验时以 release「## Integrity」与包内 `verify-kit.sh` 为准 |
| 7 | **R2-2 AOT-MAUI 附加资产**（`aot-haps.tar.gz`，与 kit 并列发布，**不替换** JIT hap）：`test/hello-maui-app` 的 NativeAOT 变体（`PublishAot=true` → `libhello-maui-app.so` 进 `libs/arm64-v8a/`），一次 publish 产出 AOT / AOT-unsigned 两个 hap；宿主 `run_app` 路由已在本机 harness 跑通（dlopen + `openharmony_app_main` + bridge 注册） | 形态判定：app `.so`（`nm -D` 有 `openharmony_app_main`，带 `.codesign`）+ 宿主 + `libc++_shared.so` 在 `libs/arm64-v8a/`；`module.json` 与 kit 的 `hello-maui-app.hap` 同形（`libIsolation:true`，无 requestPermissions）；无 CoreCLR 运行库（无 `libcoreclr.so`/`libhostfxr.so`） | 设备侧 ArkTS 启动走 JIT 专用 `start_app`，AOT 的 `run_app` 路由仍是 follow-up：本轮按**打包/加载形态**验收，**勿**用 kit `verify-kit.sh` 的 JIT 期望值（14 `.so`）套 AOT hap（3 `.so`） |

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **无 HMS 降级不抛**（本轮核心；Push/Account/Map 共用） | 在 OpenHarmony SDK 包（当前 kit 的 5 个 hap）上启动并触发探针页/自检；有 harmony flavor 构建的探针再跑同一入口 | 三个 Kit 的探测入口返回 `Unavailable`/null/false（Push `GetTokenAsync`、Account `AuthorizeAsync`/`GetQuickLoginAnonymousPhoneAsync`、Map `QueryCapabilitiesAsync`/`MapKitImportable`/`IsSupported`），**无异常、无崩溃、无 `EntryPointNotFoundException`/`DllNotFoundException`** | 启动两行日志 + `files/dotnet-status.txt`（如有）+ hilog 原文；无入口登记「未测（本包无入口）」 |
| **Push token**（有 HMS/AGC 时） | 换 HarmonyOS SDK（`ARKTS_SDK_FLAVOR=harmony`）构建 → AGC 开通推送 + 含推送权益的 Profile（签名证书指纹/包名一致）→ HMS 设备上 `getToken()` | 返回 token 字符串；失败按错误码排查：`1000900010`（未开通/签名不匹配）、`1000900012` 等，映射为托管异常而非崩溃 | token 首尾片段（勿回传完整值）+ hilog 错误码原文；`deleteToken()` 结果 |
| **Account 授权**（有 HMS 时） | 同上条件 + AGC 申请 `quickLoginAnonymousPhone` scope（审批通过）；触发 `createAuthorizationWithHuaweiIDRequest()` | 授权成功返回**匿名手机号** + `authorizationCode`；未审批按 `1001502014` / `1001500001` 排查；拒绝授权按用户取消处理 | 授权页截图 + 状态原文；**明文手机号需服务端换取，客户端不回传** |
| **Map 能力位**（有 HMS/AGC 时） | 同上条件 + AGC 开通地图服务 + AppKey；读 capability bits（bit0 = `@kit.MapKit` 可解析） | 有 Kit 时 bit0=1、`MapKitImportable=true`/`IsSupported=true`；**无 Kit 时必须为 0/false 且不抛**；方案 (a) MapComponent overlay 需 harmony flavor + AppKey，排期中 | capability 值 + `QueryCapabilitiesAsync` 结果原文 |
| **新 payload 首次运行**（承 #26） | 重签 → 安装默认 hap → 启动 → 跑 `快速开始.md` §5 的 5 条冒烟 | 正常启动（`[maui] openharmony build …`/`[maui] accessibility provider status=1` 出现）、不崩、首帧正常；`verify-kit.sh` 全过（**新期望值 abc `245412`/`18532`**、`dotnet.zip` 254、index ≤ 2 KiB） | 启动两行日志 + `files/dotnet-status.txt`；失败附 `tester-run.sh` 证据包（`summary.txt` 各键） |
| **权限弹窗文案**（承 #25/#26） | 重签 `hello-maui-app-permissions.hap` → 安装 → 触发蓝牙/联系人/日历的运行时授权 | 弹窗出现且显示**理由文案**（`$string:permission_reason_*`）；允许/拒绝行为与 #24/#25 一致（本轮权限链**未改**） | 弹窗截图 + `[maui] permission …` 行；另可 `unzip -p <hap> module.json` 贴 `requestPermissions` 原文 |
| **原生桥 ABI / 回调路径**（承 #26，合并 marshal-off） | 任一原生桥：权限请求、`A11Y` 自检、Hybrid `Echo`/`Add`（可选分享/扫码探针页） | 返回值/回调与 #26 一致；**无** `EntryPointNotFoundException`/`DllNotFoundException`/参数错乱/乱码（host→托管回调走 marshal-off thunk） | 结果截图 + hilog 关键字（`验收说明.md` §5b） |
| **Share 面板 / Scan 返回**（承 #25） | OpenHarmony SDK 包下先跑降级路径；HarmonyOS SDK 变体 + HMS 设备才弹面板/返回 `originalValue` | OpenHarmony 包：`shareDispatch=False`/`scanSupported=False` → 返回不可用/空，**不崩** | 界面截图 + 状态行原文 |
| **AOT 启动**（承 #25） | 有 NativeAOT 发布的 hap 则安装启动；否则只做回归（本 kit 5 个 hap 是 JIT payload） | JIT payload 走 hostfxr 回退且行为与 #25/#26 相同 | 启动两行日志 + 进程存活 |
| **PLAT-GAP 恢复路径**（承 #26，可选） | 在装有 kit #27 workload 的机器上 `dotnet publish` 一个引用 `Microsoft.AspNetCore.App` 的 MAUI 项目（如 BlazorWebView），项目文件**不加**任何 KFR/RID/apphost workaround | restore/publish 成功，RID 默认为 `openharmony-arm64` | `dotnet publish` 输出 + 项目文件（证明无 workaround） |

> 本轮 kit 的 5 个 hap 仍是 **JIT payload**（hostfxr 回退路径）；Push/Account/Map 与 Share/Scan 的 sink 在 OpenHarmony SDK
> 下**不注册**；没有对应入口时按「未测（本包无入口）」登记，不要判失败。三个新能力的**完整点亮**需要
> HarmonyOS SDK 构建 + HMS 设备 + AGC 开通/审批（Push 开通、Account scope 审批、Map AppKey），本环境不可代办。

## 3. 启动路径与 JIT 判定（一字未改，承 #24/#25/#26）

- 启动相关修复不变：P17 跳过重复解压、H7 rawfile fd 直读、headless abc `13.0.1.0`、
  payload-in-libs（`libs/arm64-v8a/` 原地启动 + `.dotnet-payload.json` 校验，`dotnet.zip` 回退）；
  AOT export 路径与 hostfxr 回退均与 #25 相同（#27 重建了壳 abc 与宿主 `.so`，启动判定不变）。
- exec-memory 探针与 `xwe.txt` A/B **未变**（`tester-run.sh` v8 仍采集 `hilog/hilog-execmem.txt`；
  `summary.txt` 仍写 `execmem_capture`/`execmem_lines`）：判定表、A/B 指令与 NativeAOT 指引见
  `2026-09-24-ohos-tester-handoff-kit24.md` §3–§5。
- 最直接的回归检查：应用能起（`[maui] openharmony build …` 出现）、原生桥调用不抛
  `EntryPointNotFoundException`/`DllNotFoundException`、无 HMS 的 Kit 探测不崩 —— 这三点同时覆盖 #27 的核心增量。

## 4. 校验与取证（与 #26 相同，只换 abc 期望值）

1. 下载/校验/重签/安装同 `快速开始.md` §1/§3；kit 内 `verify-kit.sh`（**53,999 B / `7f3420d2…`**，abc 期望重锚修订）
   逐 hap 断言 abc **`245412`**/`18532`、`dotnet.zip` 254 项、`libs` 269 项 = 14 `.so` + 254 payload + marker、
   `resources.index` 1588/1780（≤ 2 KiB）；语义不变（FAIL → 退出码 1；WARN → 仍 `KIT OK`）。
   **用 #26 的旧期望值 `234620` 校验本包会 FAIL —— 那是脚本的预期行为，不是包坏。**
2. 一条命令取证（`tester-run.sh` **v8**，未变）：`sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60`
   → 证据包含 `hilog/hilog-{applib,dlopen,bootstrap,execmem}.txt`、`device/payload-*.txt`、
   `meta/kit-selfcheck.txt`（`kit_index_ok`/`payload=yes|no`）与 `summary.txt`。
3. 权限变体请额外回传：`unzip -p <hap> module.json` 的 `requestPermissions` 原文 + 运行时弹窗截图。
4. 有 harmony flavor / HMS 的测试者请附：`ARKTS_SDK_FLAVOR=harmony` 的构建出处、AGC 开通/审批截图、
   Push token（首尾片段）/Account 授权结果/Map capability 值，以及对应 hilog 错误码原文。

## 5. 仍未验证（如实边界）

- 本轮全部增量（壳 Push/Account/Map 探测、12 个 kit sink、NAPI 加固、marshal-off）**均未上机**：
  kit 的 hap 是自签名（`9568257`/`9568344` 属预期，先重签）。
- Push/Account/Map 的**真 Kit 调用**需 HarmonyOS SDK + HMS 设备 + AGC（Push 开通、Account scope 审批、
  Map AppKey）；当前只有**离线证据**（无 Kit/无 host 时四个新托管入口全部 `Unavailable`/null 且不抛）。
- 权限弹窗 / Share 面板 / Scan 返回 / AOT 启动四个判定点自 #25 起**仍未有真机回传**；PLAT-GAP 消费方路径
  自 #26 起仍待真机复测；stock kit（#22 起，含 #27）的首次设备复测仍待做
  （里程碑与判定点见 `2026-09-24-ohos-device-milestone.md` §6）。
- 批次注记：批末 `fa8a28e` 的 interaction CI 曾因旧 maui pin `1a754753` 红（run 36205005783）；
  `75cdc26` 推进到 `a0a2c087` 后 CI 5/5 success（interaction 36209459719 / pixel 36209459728 /
  host-export 36209459748 / ridgraph 36209459732 / markdownlint 36209459740）；sdk-ohos `3eb480fb4b` 的
  `ohos-install-tests` run 36213976053 亦 success。
- 包内 tester 文档为 kit #26 修订（7/9 仍写 #26；`签名与UDID指南.md`/`签名说明.txt` 与 #26 逐字节相同）：
  本文与 release 说明是本轮的权威版本。打包/发布侧：`workload-1.0.0-preview.24` 版本字符串未变，
  versioned/latest/SDK release 资产为 kit #27 原地替换（与 #25/#26 波次相同口径）。
