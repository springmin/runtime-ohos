# WebView / Blazor Hybrid 真机验证卡（kit #32，2026-09-28）

> **2026-10-01 更新（kit #36，当前）**：kit #36 = #35 + **payload 原地直载（AOT 路径真机 BLZ）+ host 预注册缓冲 + 像素 Known 清零 + a11y 渲染帧修复 + rc.2 AOT pack `-r2`**（①壳 `findLibsPayloadDir` 兼容模块布局 `<bundleCodeDir>/<module>/libs/<abi>`——真机 hello-maui-wasm 直接自 `/data/storage/el1/bundle/entry/libs/arm64` 原地启动（`dotnet.zip not unpacked`，pid 49565）且 `BLZ_BOOT`/`BLZ_RENDERED` 双标记齐；②host 缓冲壳 `registerWebSink` 注册前到达的 web 命令（16 条 / 64 KiB，注册即 flush；套件 pin `moduleRoot`/`webPending`）；③像素套件不再有 `Known(...)`（selection tint 改字节量化精确断言 `#3959B3`）；④a11y `nodeCount 0` 根因 = shadow tree 未 publish，S2a pin `renderAttached=True`、`--a11y-probe` 实测 `status=1`、nodeCount 5/24 稳定；⑤rc.2 AOT pack 修正版 `-r2`（28,904,657 B / `542058cf…`，asset 601289590）修复 OpenSSL shim → 撤 rc.1 钉）；新壳 abc **339,964（`fc54d2b8…`）/24,324（`798b2477…`）**、hap 内宿主 **293,792（`cfbbe461…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,627,841 B / `9eb9cecf…`**、树 **`9764827c…`**、sidecar **`4d7062c3…`**；数字以 release「## Integrity（kit #36）」与随包校验为准；判定点 = `docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`（#35 = 上一版，见其交接文）。
> **2026-09-30 更新（kit #35，上一版）**：kit #35 = #34 + **W9/W10 并入主线**（W9A **B2：MAUI WebView 承载 Blazor WASM**——真机 `BLZ_BOOT`/`BLZ_RENDERED` 打通（pid 6157），#34 的 AOT 入口缺口由 W10 修复；W9B T14 收尾 + T21 字体缩放；W9C T8 不等高 TableView；W9D **T20 媒体传输层**（本机镜像无 MediaKit 属预期，`IsSupported=false` 降级不抛）+ T19 深链判定（热 `delivered=1`）；W10 **AOT 入口修复**（宿主自身 libs 解析 `lib<stem>.so` + `dotnet-status.txt` 可观测、壳 AOT payload 探针/`fs` 别名/静态资源指纹；rc.2 AOT 包 OpenSSL shim 缺陷 → 本地钉 rc.1）；新壳 abc **339,164（`74054e2d…`）**/headless **23,516（`6bce4063…`）**、hap 内宿主 **293,792（`983e8f74…`）**、导出 **149**、套件 **540/floor 520**；发布实测 tar **375,629,423 B / `419d42e2…`**、树 **`d3b1b317…`**、sidecar **`d7e79d39…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `2dd447a7…`**（发布已完成，以 release「## Integrity（kit #35）」与随包校验为准）；判定点 = `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`（#34 = 上一版，见其交接文）。

> 对象：kit #32 的 MAUI WebView 六项接线（壳 + 切片，`OpenHarmony{WebView,HybridWebView,BlazorWebView}Handler`）
> 与 B1 razor 独立资产（`hello-maui-razor`，bundle `com.example.hellomauirazor`）。每项 = 操作 → 期望 → 证据 → 判据；
> 失败回传「原文 + 截图」，无 hdc 时自动项登记「未测（无 hdc）」。资产 = 独立 `maui-razor-haps.tar.gz`（38,968,818 B / `5e549506…`；内未签 hap 73,656,242 B / `b4d305f0…`，abc 289,992）；kit tar 207,114,608 B / `8f690949…`（数字以 release「## Integrity（kit #32）」为准）。

| # | 不确定项 | 操作 | 期望 | 证据 / 判据 |
|---|---|---|---|---|
| 1 | frame 几何（MAUI DIP ↔ ArkUI vp） | MAUI 页内让 WebView 覆盖层与自绘控件并排（如半屏/带上边距），改一次 Margin/Size | WebView 只占控件 frame（非整窗）；几何与 MAUI 布局一致（DIP==vp 同尺度，无偏移/缩放） | 截图 + `--capture` 的 `frame` 行；判据：四边误差 ≤ 1 DIP |
| 2 | history 事件顺序 | WebView 载 A→B 两页，点返回→前进→刷新各一次 | 事件种类 Back/Forward/Refresh 顺序与操作一致，无重复导航 | hilog 事件行 + `summary`；判据：顺序一致 |
| 3 | CanGoBack/CanGoForward | A 页与 B 页分别读返回/前进可用性（`IWebView.CanGoBack/Forward`） | A 页 `CanGoBack=false`，B 页 `CanGoBack=true`；前进同理 | hilog 的 `history` 状态行（b/f 字段）；判据：布尔值与页面栈一致 |
| 4 | Cookie 跨页 | `SetCookie` 后导航到同源第二页，`GetCookieAsync` 读回 | 第二页请求携带 cookie；读回值一致（cookie/cookieGet 走上行 eval 通道） | hilog + `summary`；判据：跨页保持、读回一致 |
| 5 | Cookie HttpOnly | 设 HttpOnly cookie，页面 `document.cookie` 读取 | JS 不可见；宿主 `GetCookieAsync` 可见 | 证据原文；判据：JS 侧缺失、宿主侧存在 |
| 6 | DOM storage 持久化 | 页面 `localStorage.setItem`；杀进程重启应用后读回 | 键值仍在（`domStorageAccess(true)`） | 截图/日志；判据：重启后读回一致 |
| 7 | 加载失败清屏 | 加载必然失败的 URL（离线/不存在主机） | `Navigated(Failure)` + `error` 清屏占位，旧内容不残留、可继续导航 | hilog `error` 行 + 截图；判据：旧内容被清、无卡死 |
| 8 | B1 `BLZ_BOOT`/`BLZ_RENDERED` 进 MAUI 窗口 | 重签装 B1 razor hap → 启动 → 看窗口首屏；`hilog -x` 后 `grep BLZ`（页面带标记时） | 窗口显示 hello-maui-razor 首屏（无白屏）；带标记时两标记均出现且来自宿主 pid、无 `BLZ_ERROR` | hilog 原文 + 首屏截图；判据：首屏出 + 标记齐（无标记则标注 `B1 host without markers`，不判失败） |
| 9 | B1 JS 往返 | 进 `/counter` 点一次 `Click me`（或触发一次 `JS.InvokeVoidAsync` 往返） | 计数 0 → 1；往返无异常 | 截图 + 日志；判据：往返成功、计数变化 |

回传：`tester-report-*.tar.gz`（含 `hilog/`、`summary.txt`）+ 截图；B1 失败附 `hilog -x` 原文与 `bm dump -n com.example.hellomauirazor`（可用时）。
判读引用：`2026-09-28-ohos-tester-handoff-kit32.md` §2–§3；#31 的 ArkTS Blazor 宿主（`com.example.opendotnet`）见 `2026-09-29-ohos-tester-handoff-kit31.md` §2。**#33 的 Blazor 回归 A/B（默认 CSP 与 `-nocsp` 双 hap）另见 `2026-09-29-ohos-blazor-regression-retest-card.md`。**
