# ArkWeb 能力矩阵（MAUI WebView / BlazorWebView 需求视角，2026-09-29）

> 日期口径：文件名按撰写日；kit #31 发布日 = **2026-09-28**（RELEASE-VALUES `date`）。

**性质：** 只读调研；数据源逐行标注。需求面 = MAUI `WebView`/`HybridWebView`/`BlazorWebView`（Hybrid）与 Blazor WASM 站点承载。

**数据源与读法：**
- `OH26` = 本机 OpenHarmony SDK **26.0.0.18**（apiVersion 26，Beta），根 `/storage/Users/currentUser/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2/ets/`。
  行号 `web.d.ts:N` = `component/web.d.ts`；`webview.d.ts:N` = `api/@ohos.web.webview.d.ts`。
- `HM` = DevEco HarmonyOS SDK（CLT 6.0.1.251 / API 21）：ArkWeb 由同一 `openharmony/ets` 声明提供，`hms/ets` 无 ArkWeb 替代
  （`ohos-workload/scripts/setup-harmony-sdk.sh` 头 + `docs/openharmony-hap-packaging.md` §HarmonyOS SDK branch）。本机**未装 DevEco SDK、未实测**；
  「=OH」= 同源声明，且表中 API 首版均 ≤ s12（API 21 内可用）。
- `REPO` = maui-ohos `src/Core/src/Platform/OpenHarmony/**`；壳行号 = ohos-workload `packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets/pages/Index.ets`。

| # | API | OpenHarmony SDK | HarmonyOS SDK | syscap / 权限 | MAUI 侧现状（REPO） | 缺口 | 设备验证项 |
|---|---|---|---|---|---|---|---|
| 1 | `Web` 组件 + `WebviewController` | ✅ s9+（web.d.ts:5524；控制器别名 :41） | =OH | `SystemCapability.Web.Webview.Core`（webview.d.ts:29） | 壳内置单个 ArkWeb（壳:4902），显隐由 `show/hide` 控制 | 无 | 启动加载 + `onPageEnd` 日志 |
| 2 | `onInterceptRequest` + `WebResourceResponse`（含 `setResponseIsReady` 流式） | ✅ s9（web.d.ts:9433；响应类 :4139 / 流式 :4545） | =OH | 同上 | 壳 blazor/hybrid 资产直供（壳:4936）；hello-blazorwasm 同路径 | 无 | rawfile 200、`application/wasm`、br/gzip 协商 |
| 3 | `runJavaScript`（宿主 eval） | ✅ s9 回调 / s11 Promise（webview.d.ts:4908） | =OH | 同上 | 壳 `registerWebEvalSink`（壳:3260）；slice `EvaluateJavaScriptAsyncCore` | 无 | `EvaluateJavaScriptAsync("1+1")` 返回值 |
| 4 | `registerJavaScriptProxy` / `javaScriptProxy`（JS→宿主） | ✅ s9（webview.d.ts:4723；web.d.ts:8288） | =OH | 同上 | 壳 `registerDotNetHost`（壳:2368）→ `dotnetHost.postMessage` → `JsMessage` | 无 | JS 调 `dotnetHost.postMessage` 到托管侧 |
| 5 | `onLoadIntercept`（导航网关） | ✅ s10（web.d.ts:10439） | =OH | 同上 | 壳 B6 allow-list + slice `Navigating` 审批（壳:4909） | 无 | 页内跳转/外链拦截判定 |
| 6 | 自定义 scheme（`customizeSchemes` + `setWebSchemeHandler`/`WebSchemeHandler`） | ✅ s9 / s12（webview.d.ts:5551、6109、8691） | =OH | 同上 | 未用（统一走 https 伪源 + onInterceptRequest） | 无（备用路径就位） | 可选：`app://` 拦截（当前未采用） |
| 7 | 导航/历史（`loadUrl`/`backward`/`forward`/`refresh`） | ✅ s9–10（webview.d.ts:4201/4024/4005/4106） | =OH | 同上 | 壳 `load/back`（壳:3228-3238）；slice IWebView 仅 Source/Eval，无 GoBack/GoForward/Reload | 小 | 回退 + 载入新 URL |
| 8 | 深链 `onNewWant` | ✅（`api/@ohos.app.ability.UIAbility.d.ts:673`） | =OH | `SystemCapability.Ability.AbilityRuntime.AbilityCore`（:667） | `OpenHarmonyAppLinks.cs`（冷启动 want + onNewWant → Shell 路由）；壳 `templates/ets/entryability/EntryAbility.ets:281` | 无 | `aa start -U <uri>` 冷/热两态 |
| 9 | Cookie（`WebCookieManager`） | ✅ s9（webview.d.ts:1613；`fetchCookieSync`:1642 / `configCookieSync`:1717 / `clearAllCookiesSync`:1952） | =OH | 同上 | 无调用（slice 与壳均未接） | 小 | 写/读 cookie 跨页保持 |
| 10 | DOM 存储（`domStorageAccess` 默认 false；`WebStorage`） | ✅ s8+（web.d.ts:8108；webview.d.ts:943） | =OH | 同上 | 壳未开启；BLZ 宿主开了 `domStorageAccess(true)` | 小 | `localStorage` 写入后重启读回 |
| 11 | 文件访问（`fileAccess` 默认 false；`onShowFileSelector`；`setPathAllowingUniversalAccess`） | ✅（web.d.ts:8043/9219；webview.d.ts:6645，s12） | =OH | 同上 | 壳用宿主侧 `fileIo` 读 payload，不用 Web 文件权限；无文件选择器 | 小 | 页面 `<input type=file>` 选择 |
| 12 | 媒体/权限（`onPermissionRequest`；`geolocationAccess`） | ✅ s9（web.d.ts:9464/8224；权限文案 :9455） | =OH | 需 `ohos.permission.CAMERA`+`MICROPHONE`；定位需 `LOCATION`（module.json5 声明） | 壳无 `onPermissionRequest`/`geolocationAccess`/对应权限声明 | 小 | `getUserMedia` 授权弹窗（有 UI 设备） |
| 13 | 多窗口/弹窗（`multiWindowAccess`/`onWindowNew`/`onWindowExit`） | ✅ s9–11（web.d.ts:9837/9777/9817） | =OH | 同上 | 无（New 事件未接，OAuth 弹窗流程不可用） | 小 | `window.open` 新窗或改同窗 |
| 14 | 页面事件（`onPageBegin`/`onPageEnd`/`onConsole`/`onErrorReceive`） | ✅ s9（web.d.ts:8668/8629/8995/9033） | =OH | 同上 | 壳 `notifyWebEvent` + `onConsole`→hilog（BLZ 标记）；slice `OnPageEvent` 镜像 | 无 | `BLZ_BOOT`/`BLZ_RENDERED`/`BLZ_ERROR` |

**缺口统计：** 无 **8**（#1-6、#8、#14）· 小 **6**（#7、#9-13）· 大 **0**。标「小」者均为 API 已就位、MAUI 侧尚未接线；
**没有一项需要绕过 ArkWeb 能力缺失**——Blazor WASM 承载的阻塞在 MAUI 侧 staging/引导/布局（见可行性文档 §3-B2），不在 ArkWeb。
