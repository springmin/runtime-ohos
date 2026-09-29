# WebView / Blazor Hybrid 真机验证卡（kit #32，2026-09-28）

> **2026-09-29 更新（kit #33，当前）**：kit #33 = #32 + **Blazor 回归修复**（读路径恢复 `blazor/<x>`、`_framework/dotnet.js` 物化、**双 hap 默认 CSP/`-nocsp` A/B**；FIX-BLZ-PATH/FIX-BLZ-JS）+ **MAUI TabbedPage 渲染/无障碍修复**（FIX-TABBED/A11Y-TABBED）+ **W5 四件**（T13/N3/T21/T22，套件 **470/floor 450**）+ **AOT v2 独立资产**（`aot-haps-v2.tar.gz` 17,323,220 / `265e014f…`）。**7 hap** = MAUI 5 重建（新壳 abc **294,976 B / `6cf7dda2…`**）+ Blazor 默认（27,216,958 / `69de2eea…`）与 `-nocsp`（27,216,659 / `c1ef7e06…`，包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）；bundle/preview.28 **77,689,347 B / `155960f4…`**（锚 `e7727959cc`）；整包 tar **218,138,546 B / `38e4d57a…`**、树 **`064cb001…`**、sidecar **`8297363e…`**、`SHA256SUMS` **17 项 / 1,517 B / `37031b9a…`**（dtk id 597711909 / sidecar 597714378；重签/重打包后必变）—— 数字以 release「## Integrity（kit #33）」与随包校验为准；判定点 = `docs/plans/2026-09-29-ohos-tester-handoff-kit33.md` + `docs/plans/2026-09-29-ohos-blazor-regression-retest-card.md`（#32 = 上一版，见其交接文）。

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
