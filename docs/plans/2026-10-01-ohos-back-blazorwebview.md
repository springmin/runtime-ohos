# FIX-BACKSIZE：系统 Back 关抽屉 + BlazorWebView 期望尺寸（2026-10-01）

> 症状（承 FIX-DISMISS/FIX-WVP）：系统 Back 只把窗口收后台（壳/宿主无按键转发）；BlazorWebView
> `GetDesiredSize=0` → 排出的 frame 退化被壳忽略、控件自身不出画。本轮 scratch：
> `/data/storage/el2/base/tmp/opencode/fix-backsize/`（suite/abc/publish/device 日志与截图）。

## 根因
- Back：平台在页面 `onKeyEvent` 之前消费 Back（FIX-DISMISS 真机：窗口直接 BACKGROUND）；壳/宿主无转发。
- BlazorWebView：切片编译 `ViewHandlerOfT.Standard`（`GetDesiredSize => Size.Zero`），BlazorWebView 是
  唯一没有覆写的 web handler → 期望 0x0 → 父布局排 0 高 frame → `SendPlatformFrame` 退化 → 壳忽略
  （FIX-WVP 退化保护）。
- 连带（修期望尺寸后真机暴露）：BlazorWebView 的 frame 把单 ArkWeb 覆盖层从已注册 hybrid 的页面位置
  挪走（hybrid 区变空白）。

## 修复
- maui-ohos `be09a48817`：`OpenHarmonyFlyoutPageHandler`/`OpenHarmonyShellHandler` 订阅
  `OpenHarmonyBridge.BackPressed`（开抽屉时回写 `IsPresented` / `FlyoutOpen`+`FlyoutIsPresented`，
  返回 true；否则 false 交回系统默认）；`OpenHarmonyBlazorWebViewHandler.GetDesiredSize`（宽=约束、
  高=min(400,约束) 或显式 `HeightRequest`）+ `OpenHarmonyHybridWebViewHandler.HasRegisteredOverlay`
  为真时不下发 frame（hybrid 注册计数、disconnect 递减）。
- ohos-workload `9e6519e`：壳 `onBackPress(): boolean`（4 包同源，ui abc **342,160 / `ffda66da`**）；
  宿主 `host.backPressed`/`ohos_host_register_back_pressed`（int(*)(void)，导出 **149→150**，host
  `384e552a`）；hosting `BackPressed` 事件 + `CompleteBackPressed`；套件 +4 → **554/floor 534**；
  verify-kit 期望 341560→**342160**＋provenance 同步；`hello-maui-razor` 增 AOT 入口/属性
  （bundle 专属 abc **342,176 / `1af2e2e7`**）。

## 验证
- headless：`[suite] checks=554 total=554 floor=534 assert=True`；`selftest-build-arkts-shell 185/0`、
  `selftest-verify-kit 108/0`、导出 150/150；AOT publish IL2026/IL3050/IL3051=0。
- AOT 真机 `hello-maui-app`（hap 21,632,172 / `a0b24097a08a`；宿主 384e552a；lib 18,627,344）：
  d1 开抽屉（`web cmd suspend`×2）→ d2 Back → `web cmd resume` + `state #FOREGROUND`（**Back 关抽屉**）；
  d3 再 Back → `#BACKGROUND`（默认保留）；d0 vs d2 像素 mean **0.068**（抽屉全关）、d4/d6 复现 mean 0.004；
  hybrid 区与 FIX-WVP `w0-home` mean **0.0**（覆盖层位置恢复）。
- AOT 真机 `hello-maui-razor`（hap 21,242,720 / `c25a0408e4dc`）：Blazor 页在控件 frame 内出画
  （RSTree `Web [547,501][2573,1101]`，非整窗；此前退化 frame 被忽略）；无抽屉时 Back → `#BACKGROUND`。

## 不确定项 / 精确缺口
- BlazorWebView 的**组件挂载**未达成：host 页出画（`web page: https://0.0.0.0/`、桥对象齐全），但
  `BlazorWebView component (.razor)` 未挂载；每 ~3s 一条 `hybrid message rejected`（Hybrid 静态 sink
  对 Blazor 页消息的噪声日志），Blazor handler 无拒绝日志。下一环：在 manager 边界记录 JS→.NET 载荷，
  核对首个 `__bwv` 握手/挂载批次。
- 单覆盖层：hybrid 已注册时 Blazor 的 frame 被有意 withheld（多覆盖层仍是后续；Blazor-only 页不受影响）。
- pin 已收口（MAUI-CONSOLIDATE-FIX3，2026-10-01）：CI 三处 maui ref `47d79add01` → `be09a48817`
  （ow `641e6ea`），套件注释 554/534、导出 150/150；收口记录见
  `docs/plans/2026-10-01-ohos-fix3-consolidation.md`。
- 真机为共享桌面（脚本时段外偶发外部输入）；本报告只采信时序内状态/像素/hilog 一致的轮次。
