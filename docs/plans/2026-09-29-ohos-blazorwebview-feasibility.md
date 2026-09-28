# BlazorWebView / Blazor WASM 承载可行性（OpenHarmony，2026-09-29）

**性质：** 只读调研（不改代码）。基线：maui-ohos `feature/openharmony`、ohos-workload kit #31 资产、runtime-ohos 既有计划。
**结论先行：** 方案 A（ArkTS 独立宿主）已到「可签 hap + 机器判读标记」，随 kit #31 真机收口（S）；
方案 B1（MAUI Blazor Hybrid）实现已在、只缺真机（S）；方案 B2（MAUI WebView 载 Blazor WASM）可行但缺口集中（M）。
推荐次序：A 收渲染证据 → B1 收 Hybrid 证据 → B2 以「staging + 静态服务」为首个 spike。

## 1. 现物基线（本文结论的证据）

| 现物 | 位置 | 状态 |
|---|---|---|
| ArkTS 宿主 + rawfile/br/gzip + BLZ 标记 | ohos-workload `test/hello-blazorwasm/arkts-host/`（`Index.ets`、`pack-host.sh`） | publish/编译/打包/签名/verify-app 已过；26 MB 未签 hap；真机渲染待测 |
| WASM 站点发布配方 | ohos-workload `test/hello-blazorwasm/run-smoke.sh` + README | 默认 642 文件/52 MB；`--slim` 633/47 MB；嵌入 210 文件 |
| MAUI WebView handler（壳内隐藏 ArkWeb） | maui-ohos `src/Core/src/Platform/OpenHarmony/OpenHarmonyWebViewHandler.cs` | Source/Eval/EvaluateJS + dotnetHost 消息 + Navigating；无 GoBack/GoForward/Reload 映射 |
| MAUI BlazorWebView handler（Hybrid，进程内） | maui-ohos `.../OpenHarmonyBlazorWebView.cs`、`OpenHarmonyBlazorWebViewHandler.cs` | milestone 2b/3：`blazor` 注册 + WebViewManager + 根组件；`OPENHARMONY_BLAZOR_WEBVIEW` 门控 |
| MAUI Hybrid 演示与校验 | ohos-workload `test/hello-maui-razor/`、`test/maui-platform-verify/Program.cs` S1 | 构建/接线齐；校验仅源码契约+资产映射，设备端 `Blazor.start()` 未验 |
| 壳桥（web sink/eval/资产服务） | ohos-workload `packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets/pages/Index.ets` | `dotnetHost` 代理、`runJavaScript`、`onInterceptRequest` 直供（MIME 含 `application/wasm`）；未开 domStorage |
| aspnetcore-ohos Blazor 侧 | `aspnetcore-ohos` `feature/openharmony` | 仅 RID 列表/`NativeAotSupported=false`（`AGENTS.md:9`）；无 OH 特有 Blazor/WASM 改动 |
| 技能库 | runtime-ohos `.github/skills/` | 无 Blazor 指南（`mobile-platforms` 只覆盖 Apple/Android） |

## 2. 方案 A — ArkTS 宿主独立 hap（现状）

- 路径：`dotnet publish` 站点 → `resources/rawfile/blazor` → `Web.onInterceptRequest` 直供 → `onConsole` 转发 `BLZ_*` 到 hilog。
- 缺口：WebView 桥=无（WASM 自带 JS↔.NET）；资源加载=`https://blazor.local/` + 拦截（`app://` 未用；API 26 已有 `customizeSchemes`/`setWebSchemeHandler`）；interop=Blazor WASM 内建，无需宿主通道；导航/历史=SPA 回退，无深链/`onNewWant` 接入；Cookie/存储=未接（`WebCookieManager`/`domStorageAccess` 均未开）；权限=无（rawfile 直供不需要 INTERNET）。
- Spike（即 kit #31）：重签安装 → `tester-run.sh --blazor-probe`；**里程碑 = `hilog -x | grep BlazorWebHost` 含 `marker: BLZ_BOOT` + `marker: BLZ_RENDERED`**（人工：首屏 + `/counter` +1 + 截图）。
- 风险：真机首帧仍未验（headless 设备）；不覆盖原生 UI 融合。**工作量 S**（已就绪，待执行）。

## 3. 方案 B — MAUI 窗口内承载

**B1 `BlazorWebView`（Blazor Hybrid，进程内 CoreCLR；不加载 WASM）**
- 已实现：`AddMauiBlazorWebView().UsePlatformHandler<OpenHarmonyBlazorWebViewHandler>()`；app `wwwroot` 由 pack target（`_OpenHarmonyStageBlazorAssets`）打进 payload；壳 `blazor` 命令 + `window.external`/dotnetHost 通道。
- 缺口：WebView 桥=已有（eval + dotnetHost）；资源加载=payload 目录 + `https://0.0.0.0/` 拦截；interop=`window.external.receiveMessage` → `__dispatchMessageCallback` 已通；导航/历史=Source/Eval 映射、无 GoBack/GoForward/Reload；Cookie/存储=domStorage 未开、Cookie 未接；权限=无新增。
- Spike：hello-maui-razor 上设备，在 `index.html` 加装同款 BLZ 标记；**里程碑 = MAUI 窗口内出现 `BLZ_BOOT` + `BLZ_RENDERED` + 一次 `JS.InvokeVoidAsync` 往返**。**工作量 S**（验证补课）。

**B2 `WebView` 载 Blazor WASM 站点（严格含义：MAUI 无 WASM-aware `BlazorWebView`，WASM 只能走 WebView）**
- 缺口 1（staging）：`_OpenHarmonyStageBlazorAssets` 只收项目 `wwwroot`，有内容但无 `blazor.webview.js` 时硬报错；WASM 的 `publish/wwwroot`（`_framework/*.wasm`）不能原样走现有暂存。
- 缺口 2（服务/引导）：壳 `blazor` 注册是 Hybrid 引导（加载 `_framework/blazor.webview.js`、注入 callback 形 `window.external`、调 `Blazor.start()`）；WASM 站点用 `blazor.webassembly*.js` 且必须跳过该引导，否则多一次 404 脚本请求。
- 缺口 3（布局）：壳只有一个隐藏/显示的整窗 ArkWeb（web sink 无 frame/bounds 命令），WebView 不能作为 MAUI 布局中的子控件定位。
- 缺口 4（其余通道）：GoBack/GoForward/Reload 未映射（壳只有 `back`）；Cookie/存储默认关；深链/多窗口/媒体权限未接；WebView 桥（eval+dotnetHost）可直接复用。
- Spike 第一步：把 BLZ 站点以现有 payload 服务路径在 MAUI WebView 中加载，先只求 `BLZ_BOOT`；第二步换 `blazor.webassembly*.js`/专用注册模式拿 `BLZ_RENDERED`；**里程碑 = MAUI 窗口内两条 BLZ 标记**。**工作量 M**。

## 4. 方案 C — 混合/演进

- C1（建议）：A 拿渲染证据 → B1 拿 Hybrid 证据 → 把 A 的 rawfile 宿主与 MAUI payload 服务收敛为一条「静态 payload 服务」，按场景选 Hybrid（就地 UI）或 WebView+WASM（外部站点）。
- C2（长线，**工作量 L**）：为 MAUI `IBlazorWebView` 做 WASM-aware 平台实现（上游无此模型，需自维护）。

## 5. 风险

- 站点体积 26–71 MB 随 hap；WASM 发布依赖 dnceng rc.2 flight（不在 nuget.org），发布配方需随 SDK 版本复核。
- 壳 Web 覆盖层与 MAUI 自绘 XComponent 的层叠/几何是 B2 首要不确定项（自绘合成器路线见 `2026-09-22-ohos-render-route-decision.md`）。
- aspnetcore-ohos 无 OH 定制：任何 WASM 运行时/browser API 修正都要自行维护或回上游。
- 未决：B2 是否需要新的 pack staging target / 壳注册模式，取决于 B1 真机结果（先 Hybrid 后 WASM 的顺序可降风险）。
