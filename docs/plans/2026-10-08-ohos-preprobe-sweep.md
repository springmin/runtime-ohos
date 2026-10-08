# PREPROBE-SWEEP：退役 NativeLibrary 预探针统一直呼 + 缓存降级（2026-10-08）

> 口径：maui `maint/preprobe-sweep` @ `f8ef3c89b4`（基 `b914379269`；新分支、普通推送、未并主线/未强推、不切 kit）· 1×离线套件构建兼跑（**737/740 floor 720 assert=True**、rc=0、0 Unhandled、perf 双 within）· 无设备 · ow 零改动/无新导出 · #53/#54 资产不动。

## 1) 清单（退役预探针 → 直呼位）

| 位 | 文件 | 导出 | 原用途 |
|---|---|---|---|
| a11y announce | `OpenHarmonyAccessibility.cs` | `ohos_host_accessibility_announce` | 文本携带广播；缺失退 `send_event`（事件种） |
| chrome title/rect | `OpenHarmonyWindowHandler.cs` | `ohos_host_set_window_title` / `_rect` | 主窗标题 / 矩形 |
| shell search | `OpenHarmonyShellExtras.cs` | `ohos_host_shell_search_set` / `_set_listener` | 搜索态发布 / 交互回呼注册 |
| shell flyout | `OpenHarmonyShellExtras.cs` | `ohos_host_shell_flyout_header` / `_footer` | 抽屉头/尾文本 |
| screenshot PNG | `OpenHarmonyScreenshot.cs` | `ohos_host_screenshot` | `IsCaptureSupported` 能力判定 |
| screenshot format | `OpenHarmonyScreenshot.cs` | `ohos_host_screenshot_format` | Jpeg 采集门 |

已先修（本波不含）：`release_for`（SEC7-A @ `b914379269`）、`provider_status_for`（A11Y-SELFCHECK）、action-listener（本就直呼+`EntryPointNotFound`）。

## 2) 改法

- 统一：直呼导出；`DllNotFound`/`EntryPointNotFound` 缓存 -1（成功 1）；老宿主保持原降级（announce→事件种 fallback；chrome/shell→managed 快照 + 单条 missing 状态行；Jpeg→PNG）。删 `ExportAvailable`/`AnnounceExportAvailable`/`IsFormatAvailable`；`LibraryImport` AOT 语义不变；对外行为逐字保留。
- 特例：`IsCaptureSupported` 直调 `ohos_host_screenshot("")`——宿主在入队前拒绝空路径（自 `29f1fbf` 起的契约），无快照副作用；只有加载/查找失败即不可用。

## 3) 红绿（日志 scratch `preprobe-sweep/`）

- 绿：`checks=737 total=740 floor=720 assert=True`、rc=0；`batch2 screenshot degraded supported=False fastFail=True`、`d1 announce route=True`、`l6 title heartbeat`、`audit search`、perf 双 within=True；D1/b2/l6/n4–n5 pin 全绿。
- 红控①（临时去 announce 缺失捕获）：`d1 announce threw DllNotFoundException`、`assert=False`、Unhandled、rc=134；红控②（临时去 screenshot 探针捕获）：`Unhandled DllNotFoundException`（`IsCaptureSupported`）、rc=134；均还原后复绿（上绿 = 最终树）。

## 4) 提交 / 余项

- 提交：maui `f8ef3c89b4` → `origin/maint/preprobe-sweep`（普通推送；未并 master/feature）；本文件 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；被拒 fetch/rebase）。
- 余项：loader 根因已由同波 `e0e04724070`（A11Y-EXPORT-ROOTCAUSE）定位——简单重载 `NativeLibrary.TryLoad(short)` 无 assembly 目录探测（P/Invoke 高层探测才命中）；本波即按其“直呼 + 缓存”建议清除同族残留（未逐点真机复验）；真机未验（无设备；离线 + 宿主契约背书，空路径探针依赖宿主先判空）；ow harness 未加“slice 无 `NativeLibrary`”源码 pin（本波 ow 零改动），建议下波一行 pin 收口。
