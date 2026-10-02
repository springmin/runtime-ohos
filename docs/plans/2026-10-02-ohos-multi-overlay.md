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

## §FULL（MULTI-OVERLAY-FULL，彻底方案①，2026-10-02/03）

### 设计（N=2 槽池上的无限制退化与全通道正确）
- **LRU 槽复用（>N 控件）**：`OpenHarmonyOverlays` 新增 owner 契约
  `IOpenHarmonyOverlaySlotOwner`（`OnOverlaySlotPreempted` / `IsOverlaySlotEngaged`）与
  `Acquire(owner)`/`Release(slot, owner)`/`Touch(slot, owner)`。池满时 owner 感知 Acquire 抢占
  “未 engaged 优先、其后最久未用（LRU）”的槽，回调在锁外执行；旧 `Acquire()` 保持硬上限
  （无 owner 无法通知，防误抢）。被抢 handler 走 suspend：`_overlaySlot=-1`、`_overlayPreempted=true`；
  其 `PlatformArrange` 不再自动抢回（否则两个 suspend 的 handler 会因布局互相抢占成活锁），
  只有显式使用（Source/重载/eval/注册/首次领槽）才恢复：重新 `Acquire`、把 slot 计入注册键并
  重放 load/attach（WebView 重发 Source，Hybrid 重注册并重载 `0.0.0.1`，Blazor 重注册并重载
  `0.0.0.0`）。slot 只在 owner 匹配时可 Release/Touch，被抢者的迟到 disconnect 不会释放新主的槽。
- **同页多 Hybrid（invoke/消息全通道带槽）**：壳的 hybrid 桥状态全部按槽
  (`hybridBase/Root/DefaultFile/Registered/DocId/ServeLogs[]`)，`hybridFilePath(url, slot)`、
  `serveHybridFile(url, slot)`、`originEnvelope(payload, slot)`、`injectPageBridge(slot, ...)` 按槽
  服务默认文件与文档 id（同 origin 不同页）；`__hwvSendMessage`/`__hwvInvokeDotNet` 的拦截在
  `webOverlay(slot)` 内，消息与 invoke 都带自己的槽。invoke 不改宿主签名：
  `requestId = ((slot+1)<<24) | seq`（壳与 `OpenHarmonyOverlays.EncodeInvokeRequestId` 同步），
  托管 `TryDecodeInvokeRequestId` 后派发到持有该槽的 handler，结果以同一 id 回到该槽挂起的
  响应；旧无槽 id 仍回退“最后注册 hybrid”。
- **z-order 动态**：每槽 `@State webZOrder[]` 记录激活序，`onTouch(Down)` 与程序 show/load/data/
  注册都会 `noteWebActivation`，`.zIndex(this.webZOrder[slot])` 让最近激活的覆盖层置顶（不再固定
  slot1 在上）；触摸同时回传 `s<slot>|activate` 刷新托管 LRU。
- **全通道小修**：错误事件的 hide 支持槽 tag（只清失败槽，无 tag 仍全局）；hybrid `__hwv*` 端点
  接受 `Origin:<hybridOrigin>` + `Sec-Fetch-Site:same-origin` 的页内 fetch（CEF 把 fetch 报成
  非 main-frame，旧 isMainFrame 门把合法 invoke 打成 400）；壳 `publishAppContext` 的 appDir 改为
  与 EntryAbility 相同的 payload-in-libs 探测（此前无条件下发 `filesDir/dotnet`，让后注册 handler
  从过期/缺失的提取树服务并显示 Not Found）。
- 宿主/native 零改动：签名与导出不变（150/150）。

### 实现
- maui-ohos 切片（工作树，未推 pin）：`OpenHarmonyWebViewHandler.cs`、`OpenHarmonyHybridWebViewHandler.cs`、
  `OpenHarmonyBlazorWebViewHandler.cs`（owner/LRU/restore/replay、注册键含 slot、invoke 按槽派发）。
- ohos-workload：`src/Microsoft.OpenHarmony.Hosting/OpenHarmonyOverlays.cs`（owner LRU + invoke id codec）；
  壳 `packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.{22,23,24,28}/templates/ets/pages/Index.ets`（按槽
  hybrid 状态/invoke/serve、z-order、端点门、payload 解析）+ 重建 abc；`test/hello-maui-app`（两 Hybrid
  `hybrid-a/b.html` + 按需第三 Hybrid `hybrid-c.html`、EchoInvoker、Activate/LRU 按钮）；
  `test/maui-platform-verify`（+4 → 563/543，含池 LRU、invoke id、壳/切片断言）；`scripts/verify-kit.sh`、
  `scripts/selftest-verify-kit.sh` abc 期望 356,140。

### 验证
- headless 套件：`[suite] checks=563 total=563 floor=543 assert=True`；`selftest-verify-kit 108/0`、
  `selftest-build-arkts-shell 185/0`、`selftest-repo-hygiene 25/0`、host exports 150/150（native +
  `--cross-check` 切片 EntryPoint 全列出）。
- 壳 abc：UI **356,140 B**（sha256 `2a90f0d7b48136e426bb355161734ef6b152e94f54535afac133ae4dfc2c875d`；
  headless 24,324 不变），构建实测并装入 preview.22/23/24（provenance clean）+ 同步 preview.28。
- AOT hello-maui-app（本树 + 新 abc）：`libhello-maui-app.so` 18,807,568 B；IL2026/IL3050/IL3051 = 0/0/0；
  hap `ets/modules.abc` 356,140/`2a90f0d7b481`。真机 HAD-W32（hdc 127.0.0.1:35111），证据
  `/data/storage/el2/base/tmp/opencode/multi-ovl-full/device/`（`r13-*`）：
  ① 两 Hybrid 同页各自可交互（`r13-hybrids-interactive.jpeg`）：A 页 `invoke: "A-echo:Echo:1"`、B 页
  `invoke: "B-echo:Echo:1"`，托管 label 分别 `A raw: A-raw-ping` / `B raw: B-raw-ping`（per-slot 消息与
  invoke 请求/响应/回调闭环）；hilog `hybrid assets ... slot=0/1`、`web page (slot 0/1): https://0.0.0.1/`；
  ② 第三控件抢占（`r13-after-c.jpeg`）：点 “Add web C” 后按钮变 “web C added (3 web controls, 2 slots)”，
  A 区空白（被 C 抢 slot，LRU）、B 仍在、C 页 “Hybrid C” 出画；
  ③ 恢复重放（`r13-restore-a.jpeg`）：点 “Activate hybrid A” 后 A 重新出画、B 空白（被 A 抢）、C 仍在；
  `r13-restore-b.jpeg` 对称（B 恢复、A 空白、C 仍在），证明被抢槽的 suspend→恢复重放 load 语义。
- 提交：maui-ohos 切片提交 + ohos-workload（hosting/壳/套件/样例/文档/abc）经 `scripts/commit-paths.sh`
  分路径提交；CI pin（workflows 内 `15d81f31b1`）未动。

### 剩余缺口
- z-order 已实现并有断言/编译实测，但真机采用纵向不重叠布局，未取重叠控件的动态置顶截图；
  tester 可在重叠页复核。
- 三 HAP 启动模式（payload-in-libs 与 dotnet.zip 提取）仍按 EntryAbility 的标记选择；本轮修了壳侧
  appDir 的二次发布，但 zip 提取树在异常中断后的陈旧性由既有 marker 逻辑负责（未改）。
- hello-maui-app 的 Blazor `#app` 演示仍受 `_framework/blazor.webview.js` 的 payload staging 影响，
  本轮槽演示改用第三 Hybrid，未回归 Blazor 页在两种 payload 模式下的挂载。
- 两 Hybrid 的页内按钮走 fetch `__hwv*`（已按 Origin 门放行）；若 tester 用 stock
  `hybridwebview.js`（AOT 载荷未 stage 该脚本）仍需先补 `_framework/hybridwebview.js` 抽取。
