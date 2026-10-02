# FIX-BACKSIZE 合并收口（MAUI-CONSOLIDATE-FIX3 执行记录，2026-10-01）

> 三提交按依赖序推进：maui 平台切片 `be09a48817`（父 `47d79add01`）、ohos-workload 壳/宿主/套件
> `9e6519e`（父 `becc13e`）、runtime-ohos 设备证据 `59a26b4b4b1`。线性优先、禁强推；本步只推进
> CI pin 与套件计数（BlazorWebView/Dispatcher 的 BWVMOUNT 线并行，不碰同文件）。执行 scratch
> `/data/storage/el2/base/tmp/opencode/consol-fix3/`（preflight、切片 IL、导出复跑日志）。

## 1. 合并表

| 仓库 | 提交（父 → 子） | 内容 |
|---|---|---|
| maui-ohos | `47d79add01` → `be09a48817` | FIX-BACKSIZE：Back 路由（Flyout/Shell 订阅 `OpenHarmonyBridge.BackPressed`）+ BlazorWebView 期望尺寸 + hybrid 已注册时 withhold frame |
| ohos-workload | `becc13e` → `9e6519e` | 壳 `onBackPress(): boolean`（abc 342,160/`ffda66da`）+ 宿主 `ohos_host_register_back_pressed`（导出 149→150）+ hosting `BackPressed` + 套件 +4（554/floor 534） |
| ohos-workload（收口） | `9e6519e` → `641e6ea` | interaction/pixel/host-export 三 workflow：`MAUI_OHOS_REF` 47d79add01 → be09a48817（注释 554/534、导出 150/150） |
| runtime-ohos | `59a26b4b4b1`（证据） | FIX-BACKSIZE 设备证据 + 本收口记录（feature/openharmony） |

## 2. 对账（合并树实测）

- 交互套件 `[suite] checks=554 total=554 floor=534 assert=True`；`grep -c '[verify]'` == 554
  （declared==printed）；perf warmup/a11y `within=True`；像素 `PIXEL ASSERTIONS PASSED`。
- 切片 **0 error / 0 IL**；导出 **150/150**；本地 preflight **5/5 PASS**（repo gates/sh -n/
  markdownlint/交互/像素）。
- CI 5/5 全绿（push `641e6ea`）：交互 36952988901（554/554 floor 534）/ 像素 36952988887 /
  导出 36952988903 / ridgraph 36952988898 / markdownlint 36952988933；未推进 pin 的 `9e6519e`
  推送时交互为红（旧 tip 编译新断言），本 pin 提交修复。

## 3. 未决

- BlazorWebView 组件挂载：host 页出画、桥对象齐全，但 `.razor` 未挂载（BWVMOUNT 并行线）。
- 多覆盖层：hybrid 已注册时 Blazor 的 frame 被有意 withheld；多 overlay 仍是后续。
