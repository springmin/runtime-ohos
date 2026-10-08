# PREPROBE-MERGE：PREPROBE-SWEEP 退役预探针并入主线（轻合并，2026-10-08）

> 口径：maui `feature/openharmony` ← `maint/preprobe-sweep` @ `f8ef3c89b4`（**--no-ff** merge **`619c40a483`**；合并树与 f8ef3c89b4 逐字节一致）· 普通推送、未强推；**不切 kit**（#54 待 rc.2，经 `cut-kit.sh` 触发）；#49–#53 资产零改动；无设备轮、无 kit 构建；ow = harness pin + 三 workflow（注释同步）。

## 1) 合并内容

- maui 4 文件（+102/−156）：`OpenHarmony{Accessibility,Screenshot,ShellExtras,WindowHandler}.cs`——退役 NativeLibrary 预探针族 → 直呼宿主导出 + `DllNotFound`/`EntryPointNotFound` 缓存 -1 降级（announce 保事件种 fallback、chrome/shell 保 managed 快照、Jpeg 保 PNG）；无导出/ABI 变更。

## 2) 门禁（合并树）

- 套件：合并树本体 **`checks=737 total=740 floor=720 assert=True`**（declared==printed、0 Unhandled、perf within）；加 pin 后 **`738/741 floor=721`** 实测两跑全绿（`preprobe sliceFiles=135 nativeLibraryUses=0`）。
- repo gates 全绿：ridgraph **byte-level 20**、packs 25、hap-targets **79**、tasks 9、repo-hygiene 25、host 三件 **84/26/47**、cut-kit **38/38**；sh -n 53/53；lint 0 issue；pixel **PIXEL ASSERTIONS PASSED**（首轮 MSBuild node 宿主抖动，按 fallback 重跑通过）。
- 导出 **164/164**（`check-host-exports.py --cross-check`）；四包（.22/.23/.24/.28）ui abc **542,936 / `f18f0855…`** + headless **24,324 / `798b2477…`**、provenance 一致、`EXPECT_ABC=542936,24324` 不变（未重锚）。
- 环境：scratch worktree 需物化 git-ignored `packs/**/hosts/**/libopenharmonyhost.so` 并设 `SDK_OHOS_ENG_GRAPH`（无 sibling `sdk-ohos` 时 RID 图 byte-level）；一次 frame-jitter 抖动（宿主 load≈28、jitter 2.14>2）重跑 **jitter=1.34** 通过——环境层，非合并内容。

## 3) harness pin（审计建议落地）

- `test/maui-platform-verify/Program.cs` +1 `[verify]`（`420e5c5`）：扫描编译进套件的切片目录（`*.cs`，135 文件）无 `NativeLibrary.` API 标记（叙述性提及允许）——防同类回归；total 740→**741**、floor 720→**721**。

## 4) pin / CI

- 三 workflow `MAUI_OHOS_REF`（默认+env）→ `619c40a483…`，注释同步（PREPROBE-SWEEP + 738/741 floor 721、164/164、542,936）；pin 提交 ow `3ecec5c`。
- CI **5/5** @ ow `3ecec5c`：interaction `37774165584` / pixel `37774165521` / host-export `37774165680` / ridgraph `37774165539` / markdownlint `37774165548`（全 success）。

## 5) 推送 / 状态

- maui `b914379269 → 619c40a483`（origin/feature/openharmony）；ow `ca94b55 → 420e5c5 → 3ecec5c`（origin/master）；本文件 + README 索引 + 覆盖审计 #20/L1 状态 → runtime `feature/openharmony`（commit-paths 限路径）。
- 不确定：真机未验（无设备；离线 + 宿主契约背书）；pin 只防托管侧 raw-loader 回归，不覆盖宿主/ABI；`IsCaptureSupported` 空路径探针依赖宿主先判空（自 `29f1fbf` 契约）。
