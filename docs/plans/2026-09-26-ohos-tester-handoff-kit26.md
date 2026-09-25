# 测试方交接：kit #26、P2-INTEROP / TASK-MIG / PLAT-GAP 与「新 payload 首次运行」判定点（2026-09-26）

> 承接 kit #25 交接（`2026-09-25-ohos-tester-handoff-kit25.md`）：权限弹窗文案、Share/Scan 探测降级、
> AOT 启动路径三个判定点**继续有效**（本文 §2 给出口径），JIT A/B 指令与 `probe:`×`xwe` 判定表
> （kit #24 交接 §3–§5）**一字未改**。本文只覆盖 #26 的增量与判定点。
> 结论先行：kit #26 = kit #25 的**互操作/打包/平台缺口收口** —— 托管 hosting 桥全量切到源生成
> **LibraryImport**（125 处，`DllImport` 归零；118/118 导出契约不变）、hap 打包任务迁为 **pack 内编译程序集**
> （`tools/Microsoft.OpenHarmony.Tasks.dll` + `Hap.targets` 拆分 + `PlatformItems.targets`）、**PLAT-GAP 消解**
> （AspNetCore KFR 固定发布波段、默认 RID `openharmony-arm64`、`EnableAppHostPackDownload=false`）——
> 测试方的新判定点只有一个：**新重建的 payload 能否正常跑**（外加原生桥 ABI 抽查与消费方恢复路径）。
> **kit #26（已发布 2026-09-26）**：tar **195,748,984 B** / `c8b13e56…`；解压树 **`2f247e40…`**；sidecar **`854135fc…`**；
> 5 个 hap 各 **~75.47 MB**（zip **278** 条 = 23 + 254 payload + marker；`libs/arm64-v8a` **269** 项 =
> 14 `.so` + 254 payload + `.dotnet-payload.json`；基包 75,474,023 B，4 个签名变体 75,474,022–75,474,054 B、未签名 **73,307,325 B**）；
> abc **234,620 B** / `34325332…`（headless **18,532 B** / `d7ec9ca7…`，与 #25 逐字节相同）；hap 内宿主
> **240,544 B** / `e02718bf…`（pack **236,448 B** / `8fa24895…`，与 #25 逐字节相同；导出契约 **118/118**）；
> hap 内 hosting DLL **55,808 B** / `38f5a3d2…`（#25 为 47,616 B）、Graphics 16,384 B；`resources.index`
> **1588/1780** B；`dotnet.zip` **254** 项 / 0 `.so`；kit 内 `verify-kit.sh` = **53,999 B** / `74852e0b…`
> （#25 修订、期望值未变）；`tester-run.sh` 仍为 **v8**（73,375 B / `6ca2093e…`，本轮未重传，与仓库副本逐字节一致）；
> bundle **30,501,359 B** / `7b9ccd6e…`（Sdk 包含 `tools/Tasks.dll` 32256 / `28c47cbf…`、`Hap.targets` 55473 / `2f2c234c…`、
> `PlatformItems.targets` 3918 / `70ac714b…`、`Sdk.targets` 5736 / `fd59a681…`），sdk-ohos 锚点已更新
> （`eng/ohos-install/versions.env` → `7b9ccd6e`，commit `f27b20f4cc`）。数字入口 = release「## Integrity」；以 release 说明与随包 `SHA256SUMS` 为准。
> 注：kit #26 包内的 9 份 tester 文档为 **kit #25 修订（仍写 #25）**，本轮由 runtime-ohos `94c7730fcfb` 导出；
> 本文与 release 说明是本轮的权威版本。

## 1. kit #26 相对 #25 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1 | **P2-INTEROP（hosting 全量 LibraryImport）**：托管 hosting 桥 44 处 `[DllImport]` 全改为源生成 `[LibraryImport]`（`StringMarshalling.Utf8`；thunk 用 `[UnmanagedFunctionPointer(Cdecl)]`），加上 MAUI 切片 81 处 = **125 处**，`DllImport` 归零；#24 起的 `check-host-exports.py` 对两种声明一视同仁，宿主导出契约仍 **118/118** | hap 内 hosting DLL 由 47,616 → **55,808 B**；所有原生桥（权限、无障碍、WebView、分享、扫码、剪贴板、截图等）的调用与回调**行为应与 #25 完全一致** | **新 payload 首次运行 + 原生桥 ABI**（§2） |
| 2 | **TASK-MIG（打包任务程序集化）**：hap 打包任务从包内联 targets 迁到 **pack 内编译程序集** `tools/Microsoft.OpenHarmony.Tasks.dll`（32,256 B；pack 内共 6 个任务程序集）；`OpenHarmony.Hap.targets` 拆分（55,473 B）+ 新增 `PlatformItems.targets`（3,918 B）；`Sdk.nupkg` 284,047 → 290,854 B | 用当前 workload 自建/重打包 hap 时走编译期任务（不再依赖内联 targets）；交付 kit 的 5 个 hap 行为不变 | 消费方自建 hap（可选；无入口则按「未做」登记）|
| 3 | **PLAT-GAP（消费方缺省化）**：AspNetCore `KnownFrameworkReference` 固定到已发布波段 **`11.0.0-rc.1.26425.128`**、默认 `RuntimeIdentifier=openharmony-arm64`、`EnableAppHostPackDownload=false` | 引用 `Microsoft.AspNetCore.App`（如 BlazorWebView）的 MAUI 项目 restore/publish **不再需要**逐项目 KFR/RID/apphost 规避；本 kit 的 5 个 hap 不受影响 | **PLAT-GAP 恢复路径**（§2）|
| 4 | **重建与打包**：Hosting / `Microsoft.OpenHarmony.dll` / Maui.Graphics 重建、bundle 重打包（30,501,359 B）并更新 sdk-ohos 锚点；`verify-kit.sh`/`tester-run.sh` 均未变 | 校验步骤、证据字段与 #25 相同；旧 #25 期望值继续适用 | 校验时以 release「## Integrity」为准 |

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **权限弹窗文案**（承 #25） | 重签 `hello-maui-app-permissions.hap` → 安装 → 触发蓝牙/联系人/日历的运行时授权（`PRINT` 为 system_grant 不弹） | 弹窗出现且显示**理由文案**（`$string:permission_reason_*` 本地化文本，而不是空/通用文案）；允许/拒绝行为与 #24/#25 一致 | 弹窗截图 + `files/dotnet-status.txt` 的 `[maui] permission …` 行；另可 `unzip -p <hap> module.json` 贴 `requestPermissions` 原文 |
| **Share 面板 / Scan 返回**（承 #25） | 探针页触发分享（多文件分支优先）与扫码；OpenHarmony SDK 包下先跑降级路径 | OpenHarmony 包：`shareDispatch=False`/`scanSupported=False` → 返回不可用/空，**不崩**；HarmonyOS SDK 变体（`ARKTS_SDK_FLAVOR=harmony`，需 HMS 设备）才弹面板 / 返回 `originalValue` | 界面截图 + 状态行原文；无入口登记「未测（本包无入口）」 |
| **AOT 启动**（承 #25） | 有 NativeAOT 发布的 hap 则安装启动；否则只做回归（本 kit 5 个 hap 是 JIT payload） | AOT hap 经 `lib<stem>.so` 的 `openharmony_app_main` export 启动；JIT payload 走 hostfxr 回退且行为与 #25 相同 | 启动两行日志 +（AOT）进程存活；AOT 冒烟结果（`aot-smoke`） |
| **新 payload 首次运行**（本轮新增） | 重签 → 安装默认 hap → 启动 → 跑 `快速开始.md` §5 的 5 条冒烟 | 正常启动（`[maui] openharmony build …`/`[maui] accessibility provider status=1` 出现）、不崩、首帧正常；`verify-kit.sh` 全过（期望值与 #25 相同：abc `234620`/`18532`、`dotnet.zip` 254、index ≤ 2 KiB） | 启动两行日志 + `files/dotnet-status.txt`；失败附 `tester-run.sh` 证据包（`summary.txt` 各键） |
| **原生桥 ABI（LibraryImport 重建）** | 任一原生桥：权限请求、`A11Y` 自检、Hybrid `Echo`/`Add`（可选分享/扫码探针页） | 返回值/回调与 #25 一致；**无** `EntryPointNotFoundException`/`DllNotFoundException`/参数错乱/乱码（UTF-8 编组） | 结果截图 + hilog 关键字（`验收说明.md` §5b）|
| **PLAT-GAP 恢复路径**（本轮新增，可选） | 在装有 kit #26 workload 的机器上 `dotnet publish` 一个引用 `Microsoft.AspNetCore.App` 的 MAUI 项目（如 BlazorWebView），项目文件**不加**任何 KFR/RID/apphost workaround | restore/publish 成功，RID 默认为 `openharmony-arm64`；Demo 恢复路径的真机运行仍待确认 | `dotnet publish` 输出 + 项目文件（证明无 workaround）|

> 本轮 kit 的 5 个 hap 仍是 **JIT payload**（hostfxr 回退路径），Share/Scan 的 sink 在 OpenHarmony SDK
> 下**不注册**；没有对应入口时按「未测（本包无入口）」登记，不要判失败。

## 3. 启动路径与 JIT 判定（一字未改，承 #24/#25）

- 启动相关修复不变：P17 跳过重复解压、H7 rawfile fd 直读、headless abc `13.0.1.0`、
  payload-in-libs（`libs/arm64-v8a/` 原地启动 + `.dotnet-payload.json` 校验，`dotnet.zip` 回退）；
  AOT export 路径与 hostfxr 回退均与 #25 相同（#26 只重建了托管 hosting 程序集，宿主 `.so` 与 #25 逐字节相同）。
- exec-memory 探针与 `xwe.txt` A/B **未变**（`tester-run.sh` v8 仍采集 `hilog/hilog-execmem.txt`；
  `summary.txt` 仍写 `execmem_capture`/`execmem_lines`）：判定表、A/B 指令与 NativeAOT 指引见
  `2026-09-24-ohos-tester-handoff-kit24.md` §3–§5。
- 最直接的回归检查：应用能起（`[maui] openharmony build …` 出现）、原生桥调用不抛
  `EntryPointNotFoundException`/`DllNotFoundException` —— 这三点同时覆盖 #26 的两项增量。

## 4. 校验与取证（与 #25 相同，只换 kit 编号）

1. 下载/校验/重签/安装同 `快速开始.md` §1/§3；kit 内 `verify-kit.sh`（53,999 B / `74852e0b…`，与 #25 同一修订）
   逐 hap 断言 abc `234620`/`18532`、`dotnet.zip` 254 项、`libs` 269 项 = 14 `.so` + 254 payload + marker、
   `resources.index` 1588/1780（≤ 2 KiB）；语义不变（FAIL → 退出码 1；WARN → 仍 `KIT OK`）。
2. 一条命令取证（`tester-run.sh` **v8**，未变）：`sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60`
   → 证据包含 `hilog/hilog-{applib,dlopen,bootstrap,execmem}.txt`、`device/payload-*.txt`、
   `meta/kit-selfcheck.txt`（`kit_index_ok`/`payload=yes|no`）与 `summary.txt`。
3. 权限变体请额外回传：`unzip -p <hap> module.json` 的 `requestPermissions` 原文 + 运行时弹窗截图。
4. 自建 hap 的测试者（TASK-MIG）请附：使用的 workload 版本、`dotnet publish` 命令与输出（证明走的是
   pack 内编译任务而非旧内联 targets）。

## 5. 仍未验证（如实边界）

- 本轮全部增量（LibraryImport hosting 重建、TASK-MIG 任务程序集、PLAT-GAP 缺省化）**均未上机**：
  kit 的 hap 是自签名（`9568257`/`9568344` 属预期，先重签）。
- PLAT-GAP 的「Demo 恢复路径」只有离机验证（restore/publish + 消费方项目不再需要 workaround）；
  BlazorWebView 等应用在设备上的运行仍待复测。
- 包内 tester 文档为 kit #25 修订（仍写 #25）：本文与 release 说明是本轮的权威版本。
- 权限弹窗/Share/Scan/AOT 四个判定点自 #25 起**仍未有真机回传**；stock kit（#22 起，含 #26）的
  首次设备复测仍待做（里程碑与判定点见 `2026-09-24-ohos-device-milestone.md` §6）。
- 批次注记：TASK-MIG 期间的批次 tip `123a223` 曾有一次 interaction CI 红灯（PG2 断言绑定迁移前内联
  targets），已在 `3b59258` 将断言重新锚定到 `src/Microsoft.OpenHarmony.Tasks/*.cs` 并本地复验
  （326 检查 / floor 306 绿）；当前 CI 全绿（`ohos-workload 7075b67`、`sdk-ohos f27b20f4cc`）。
- 打包/发布侧：`workload-1.0.0-preview.24` 版本字符串未变，versioned/latest 资产为 kit #26 原地替换
  （与 #25 波次相同口径）。
