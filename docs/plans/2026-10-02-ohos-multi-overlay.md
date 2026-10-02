# MULTI-OVL：多 WebView 覆盖层共存（N=2）（2026-10-02）

> 设备 HAD-W32（hdc 127.0.0.1:35111）。件 = AOT hello-maui-app（新壳 abc 347,704 / `960c4c9c…`；
> headless 24,324 不变；宿主 150 导出不变），`libhello-maui-app.so` 18,803,472，IL 0/0/0。
> 证据 scratch `/data/storage/el2/base/tmp/opencode/multi-ovl/`：`device/`（h1-home / h3-foreground /
> h6-blazor-click + hilog-h0/h1）、`shell/`（abc 构建与同步日志）、`harness/`（套件）、`aot/`（publish）。

## 设计（最小可行：按 web 控件槽池，上限 2）
- 托管槽池 `OpenHarmonyOverlays`（hosting；Acquire/Release、上限 2）+ 线协议：每覆盖层命令参数首行
  `s<slot>`（frame/show/load/data/back/forward/refresh），注册 JSON 带 `slot` 字段，eval 前缀
  `s<slot>\n`，页事件回传 `s<slot>|state`，导航决策 `__OHNAV|s<slot>|<url>|<id>`；全局命令
  （hide/suspend/resume/cookie/cookieGet）不带 tag、作用于全部覆盖层。宿主签名/导出不变（150/150）。
- 壳：`@Builder webOverlay(0/1)` 在 `ContentSlot` 之后声明两个 ArkWeb（slot 1 叠在 slot 0 上），每槽
  controller/可见性/frame/挂起快照/JS 代理/文档标记/导航 marker 独立；hybrid 注册→其槽加载
  `0.0.0.1`，blazor 注册→其槽加载 `0.0.0.0`；FIX-WVP 单覆盖层仲裁（“已注册 hybrid 时 Blazor 只武装
  不加载”）与 FIX-BACKSIZE 的 frame withheld 一并移除。
- 切片：WebView/Hybrid/Blazor 三个 handler 连接领槽、断开释放；帧/加载/求值/导航事件按槽路由
  （无 tag 事件保持 fan-out，兼容旧壳/池满）。

## 实现
- maui-ohos `75c410e798`（切片）；ohos-workload `ff4559c`（壳 Index.ets×4 包 + abc/provenance +
  hosting + 套件 + verify-kit 期望 + 打包文档）。CI pin 未推进（套件对旧/新切片双模）。

## 验证
- headless：`[suite] checks=559 total=559 floor=539 assert=True`（+4：槽池、线编解码、双覆盖层壳、
  切片接线）；`selftest-verify-kit 108/0`、`selftest-build-arkts-shell 185/0`、
  `selftest-repo-hygiene 25/0`、exports 150/150。
- 真机（同一页两个 web 控件）：
  ① 两白区同时出画：上 = hybrid `origin https://0.0.0.1/ | readyState: complete`，下 = Blazor
  `origin https://0.0.0.0/`（此前单覆盖层下 Blazor 区空白）；hilog 两 origin 均有 `web serve` 与
  `web page (slot 0)`/`(slot 1)`；
  ② hybrid 覆盖层可交互：页内按钮 → 托管 label `hybrid raw message: {…, origin:
  https://0.0.0.1/, …}`（页→宿主闭环）；
  ③ Blazor 覆盖层可交互：页内点击使其 DOM 从 `sent #1` 前进到 `sent #2`（origin 0.0.0.0），
  `__bwv:["AttachPage","https://0.0.0.0/",…]` 被 Blazor handler 接受（hilog `BLZ_DIAG`）。

## 缺口/不确定项
- 上限 2：第 3 个并发 web 控件不出画（Acquire 返回 -1、退回 slot0 旧协议）；是否扩到 3 / LRU 池待定。
- 两 HybridWebView 同页未验证：hybrid invoke 通道（`host.notifyHybridInvoke`）无 slot，切片仍以
  “最后注册的 hybrid”为 invoker 归属；已验证组合为 Hybrid + BlazorWebView。
- 槽 z-order 固定 slot1 在 slot0 上（帧不重叠时可忽略；重叠控件需按注册顺序调整）。
- hello-maui-app 的 Blazor `#app`（BlazorCounter）未挂载：该样例缺 `modules.json`（既有限制；
  razor 样例在 kit #40 已挂载），多覆盖层路由本身工作（AttachPage 被接受）。
- Blazor 页滚动到 `#app` 与计数器点击未在真机取到；tester 机复核待做。
