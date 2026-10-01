# FIX-DISMISS + FIX-WVP 合并收口（MAUI-CONSOLIDATE-FIX2 执行记录，2026-10-01）

> 两条并发修复线按依赖序合入主线（`maui-ohos` 平台切片 + `ohos-workload` 壳/宿主/套件）：
> 线性优先、禁强推。FIX-DISMISS = 抽屉外点关闭（默认版式 `Popover`）；FIX-WVP = Hybrid overlay
> px→vp / hybrid origin / z-order / 抽屉与切页挂起。执行 scratch
> `/data/storage/el2/base/tmp/opencode/fix2-consol/`（preflight、切片 IL、导出复跑日志）。

## 1. 合并表

| 仓库 | 提交（父 → 子） | 内容 |
|---|---|---|
| maui-ohos | `86b439ffc8` → `47d79add01` | FIX-DISMISS：`FlyoutPage` 默认版式改 `Popover`；FIX-WVP：Flyout/Tabbed 覆盖层 suspend/resume/hide |
| ohos-workload | `d00cf7e` → `acbe750` | FIX-DISMISS 套件 +2（546/526）；FIX-WVP 壳 Index.ets、四包 abc 341,560/24,324、hosting `WebCommandSent`、套件 +4（550/530） |
| ohos-workload（收口） | `becc13e` | interaction/pixel/host-export 三 workflow：`MAUI_OHOS_REF` 68ec598037 → 47d79add01 + 注释 550/530、导出 149/149 |
| runtime-ohos | `c2acc032ba5` / `c80335cbdf3` | 两条修复的根因与设备证据文档（已在 feature/openharmony） |

- 冲突：无 git 层冲突（两条线各自选择性暂存的改动都已在父提交里）；语义解 = 合并树同时含
  `Program.cs` 的 FIX-DISMISS + FIX-WVP 断言（550/530）与四包 abc。远端核对：maui
  `origin/feature/openharmony` = 47d79add01、ow `origin/master` = acbe750（gh api）。

## 2. 对账（合并树实测）

- 交互套件 `[suite] checks=550 total=550 floor=530 assert=True`；`grep -c '[verify]'` == 550
  （declared==printed，实测 = 544 + FIX-DISMISS 2 + FIX-WVP 4）；perf warmup/a11y `within=True`。
- 像素 `PIXEL ASSERTIONS PASSED`；导出 **149/149**；切片 **0 error / 0 IL**。
- 本地 preflight **5/5 PASS**（repo gates/sh -n/markdownlint/交互/像素）。
- CI 5/5 全绿（push `becc13e`）：交互 36830400978（550/550 floor 530，perf within=True）/ 像素
  36830401093 / 导出 36830400995 / ridgraph 36830401002 / markdownlint 36830400969。

## 3. 未决

- Back 关闭抽屉：需宿主/壳新增 `onBackPress` 转发 + host 导出 + 桥事件，未纳入本批。
- 多覆盖层：同页多 web 控件共享单 ArkWeb 覆盖层；多 overlay 后续。
- BlazorWebView 期望尺寸为 0（无 `GetDesiredSize`）→ frame 被忽略、自身不出画。
