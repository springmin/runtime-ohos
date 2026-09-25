# 测试方交接：kit #25、权限链 / Share-Scan 探测 / AOT 启动判定点（2026-09-25）

> 承接 kit #24 交接（`2026-09-24-ohos-tester-handoff-kit24.md`）：JIT A/B 指令、`probe:`×`xwe` 判定表与
> NativeAOT 主路线（该文 §3–§5）**继续有效**，本文只覆盖 #25 的增量与判定点。
> 结论先行：kit #25 = kit #24 的**固化增量** —— 权限声明链（features → `reason`/`usedScene` + 请求点门禁）、
> Share/Scan 特性探测与降级、AOT 启动路径（app export → `openharmony_app_main`，hostfxr 回退）、
> present 缓存（窗口/generation 键控，无每帧 `mmap`）与导出契约 118/118；重建 UI/headless abc、宿主与托管程序集。
> **kit #25（已发布 2026-09-25）**：tar **195,567,555 B** / `e0502709…`；解压树 **`9014b428…`**；sidecar **`c5e5be98…`**；
> 5 个 hap 各 **~75.43 MB**（zip **278** 条 = 23 + 254 payload + marker；`libs/arm64-v8a` **269** 项 =
> 14 `.so` + 254 payload + `.dotnet-payload.json`；4 个签名变体 75,425,359–75,425,455 B、未签名 **73,255,934 B**）；
> abc **234,620 B** / `34325332…`（headless **18,532 B** / `d7ec9ca7…`）；hap 内宿主 **240,544 B** / `e02718bf…`
> （pack **236,448 B** / `8fa24895…`，导出契约 **118/118**）；`resources.index` **1588/1780** B；`dotnet.zip` **254** 项 / 0 `.so`；
> kit 内 `verify-kit.sh` = **53,999 B** / `74852e0b…`（含 #25 断言）；`tester-run.sh` 仍为 **v8**（73,375 B / `6ca2093e…`，
> 本轮未重传，与仓库副本逐字节一致）。数字入口 = release「## Integrity」；以 release 说明与随包 `SHA256SUMS` 为准。
> 注：本轮 kit 包内 9 份 tester 文档与 kit #24 同修订（仍写 #24）；本文与 release 说明是本轮的权威版本。

## 1. kit #25 相对 #24 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1 | **权限链**：`module.json` 的 5 项权限（`ohos.permission.ACCESS_BLUETOOTH`、`PRINT`、`READ_CONTACTS`、`READ_CALENDAR`、`WRITE_CALENDAR`）补齐 `reason`（`$string:permission_reason_*`）与 `usedScene`（`abilities=[EntryAbility]`、`when=inuse`）；打包期新增 feature→permission 矩阵 + 请求点扫描门禁（strict 可 error） | 权限变体的运行时授权弹窗应显示**理由文案**（不再是空/通用文案）；系统设置的应用权限页也应显示该理由 | **权限弹窗文案**（§2） |
| 2 | **Share/Scan 特性探测**：壳侧 `canIUse` + 变量 import 探测成功才注册 sink（Share：`systemShare.SharedData`/`ShareController.show` 多文件；Scan：`canIUse('SystemCapability.Multimedia.Scan.ScanBarcode')` + `scanBarcode.startScanForResult`），host 侧 `ohos_host_share_kit_share` / `ohos_host_scan_*`，托管侧 `OpenHarmonyShareKitBridge`（多文件分支）/ `OpenHarmonyScan`（`IsSupported`/`ScanAsync`）；缺失/失败一律降级并记状态 | 在 OpenHarmony SDK 上特性探测为 `shareDispatch=False`/`scanSupported=False`（sink 不注册）→ 分享/扫码调用应**干净降级**（返回不可用/空，不崩）；HarmonyOS SDK 变体（`ARKTS_SDK_FLAVOR=harmony`）才启用面板/扫码 | **Share 面板 / Scan 返回**（§2） |
| 3 | **AOT 启动路径**：宿主经应用自身 export 启动（`lib<stem>.so` → `openharmony_app_main`），JIT-only 入口（hostfxr → hostpolicy → coreclr）保留为回退 | JIT payload（本 kit 5 个 hap）仍走 hostfxr 回退启动；NativeAOT 发布的应用应经 app export 启动 | **AOT 启动**（§2） |
| 4 | **运行面固化**：present 缓存按窗口/generation 键控（无每帧 `mmap`）、宿主导出契约 118/118（纯 C 符号，`nm -D`/CI 门禁）、宿主 JSON 源生成（IL 告警 0）、targets 加固（FileWrites / RID 单源 / JSON `module.json` / 显式工具链 / 静态资产） | 帧路径无每帧 `mmap`；启动/绑定不回归（`[openharmony-host] … bound via alias '…'`）；hap 内托管 hosting 47,616 B | 回归：应用仍启动（§3） |
| 5 | **打包数字**：abc 234,620 / headless 18,532；宿主 240,544（hap 内）/ 236,448（pack）；libs 269 = 14 + 254 + marker；zip 278；index 1588/1780；dotnet.zip 254/0 `.so` | `verify-kit.sh` 的期望值随 #25 更新（旧 #24 壳大小只 WARN） | 校验时以 release「## Integrity」为准 |

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **权限弹窗文案**（权限变体） | 重签 `hello-maui-app-permissions.hap` → 安装 → 触发蓝牙/联系人/日历的运行时授权（`PRINT` 为 system_grant 不弹） | 弹窗出现且显示**理由文案**（`$string:permission_reason_*` 的本地化文本，而不是空/通用文案）；允许/拒绝行为与 kit #24 一致 | 弹窗截图 + `files/dotnet-status.txt` 的 `[maui] permission …` 行；另可 `unzip -p <hap> module.json` 贴 `requestPermissions` 原文 |
| **Share 面板**（分享特性） | 探针页触发分享（多文件分支优先）；OpenHarmony SDK 包下先跑降级路径 | OpenHarmony 包：`shareDispatch=False` → 调用返回不可用/空，**不崩**，状态如实记录；HarmonyOS SDK 变体（`ARKTS_SDK_FLAVOR=harmony`，需 HMS 设备）才应弹出系统分享面板并回报 `shareCompleted` | 界面截图 + hilog/`dotnet-status.txt` 的状态行；无入口登记「未测（本包无入口）」 |
| **Scan 返回**（扫码特性） | 探针页触发扫码 | OpenHarmony 包：`scanSupported=False`（`canIUse` 自检失败）→ `IsSupported=false`、`ScanAsync` 返回空/不可用，**不崩**；HarmonyOS 变体：默认扫码界面返回 `originalValue` | 界面截图 + 结果原文；无入口登记「未测（本包无入口）」 |
| **AOT 启动** | 若有 NativeAOT 发布的 hap：安装 → 启动；否则只做回归（本 kit 5 个 hap 是 JIT payload） | AOT hap 经 `lib<stem>.so` 的 `openharmony_app_main` export 启动；JIT payload 走 hostfxr 回退且行为与 kit #24 相同 | 启动两行日志 +（AOT）进程存活；AOT 冒烟结果（`aot-smoke`） |

> 本轮 kit 的 5 个 hap 均为 **JIT payload**（hostfxr 回退路径）；Share/Scan 两个 sink 在 OpenHarmony SDK
> 下**不注册**（`shareDispatch=False`/`scanSupported=False`），面板/扫码 UI 需 `ARKTS_SDK_FLAVOR=harmony`
> 的 HarmonyOS SDK 构建 + HMS 设备 —— 没有对应入口时按「未测（本包无入口）」登记，不要判失败。

## 3. 启动路径与 JIT 判定（承 kit #24）

- 本 kit 的启动相关修复不变：P17 跳过重复解压、H7 rawfile fd 直读、headless abc `13.0.1.0`、
  payload-in-libs（`libs/arm64-v8a/` 原地启动 + `.dotnet-payload.json` 校验，`dotnet.zip` 回退）。
- exec-memory 探针与 `xwe.txt` A/B **一字未改**（`tester-run.sh` v8 仍采集 `hilog/hilog-execmem.txt`；
  `summary.txt` 仍写 `execmem_capture`/`execmem_lines`）：判定表、A/B 指令与 NativeAOT 指引见
  `2026-09-24-ohos-tester-handoff-kit24.md` §3–§5。
- 新增 AOT 启动路径只是**多一条**入口（app export）；若宿主在 JIT payload 上找不到 AOT export，
  仍应回退 hostfxr 正常启动 —— 这也是本轮最直接的回归检查（应用能起、`[maui] openharmony build …` 出现）。

## 4. 校验与取证（与 #24 相同，只换期望值）

1. 下载/校验/重签/安装同 `快速开始.md` §1/§3；kit 内 `verify-kit.sh`（53,999 B / `74852e0b…`）逐 hap 断言
   abc `234620`/`18532`、`dotnet.zip` 254 项、`libs` 269 项 = 14 `.so` + 254 payload + marker、
   `resources.index` 1588/1780（≤ 2 KiB）；语义不变（FAIL → 退出码 1；WARN → 仍 `KIT OK`）。
2. 一条命令取证（`tester-run.sh` **v8**，未变）：`sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60`
   → 证据包含 `hilog/hilog-{applib,dlopen,bootstrap,execmem}.txt`、`device/payload-*.txt`、
   `meta/kit-selfcheck.txt`（`kit_index_ok`/`payload=yes|no`）与 `summary.txt`。
3. 权限变体请额外回传：`unzip -p <hap> module.json` 的 `requestPermissions` 原文 + 运行时弹窗截图。

## 5. 仍未验证（如实边界）

- 本轮全部新能力（权限链 `reason`/`usedScene` + 请求点门禁、Share/Scan 探测与降级、AOT 单入口、
  present 缓存、118/118 导出契约）**均未上机**：kit 的 hap 是自签名（`9568257`/`9568344` 属预期，先重签）。
- AOT 冒烟在本机被 SDK 门控 SKIP（`aot-smoke` → NETSDK1083/1203）；MAUI 应用（非 hello console）的
  NativeAOT HAP 打包与真机 E2E 仍未做。
- HarmonyOS SDK 分支需要在装有 HarmonyOS SDK 的机器上构建（本机仅 OpenHarmony SDK 26.0.0.18）；
  Share 多文件面板、Scan `originalValue`、HarmonyOS flavor abc 装载都仍需 HMS 设备验收。
- 包内 tester 文档与 kit #24 同修订（仍写 #24）：本文与 release 说明是本轮的权威版本。
- 平台缺口（跟进项）：RID 图把 `openharmony-*` 映射到 `linux-musl-*`，传递引用 `Microsoft.AspNetCore.App`
  （MAUI BlazorWebView 包）的项目会在 restore 阶段索要 `Microsoft.AspNetCore.App.Runtime.linux-musl-arm64`；
  演示项目逐项目绕过，workload 级 `KnownFrameworkReference`/包映射仍是后续工作。
