# MAUI WebView 接线：ArkWeb 六小缺口 + BlazorWebView B1（2026-09-28）

**性质：** 实现 + 离线验证（真机渲染除外）。变更面 = maui-ohos `src/Core/src/Platform/OpenHarmony/**`
（WebView/Hybrid/Blazor 三 handler + `PublicAPI.Unshipped.txt`）· ohos-workload
`packs/**/templates/**`（ArkTS 壳，preview.22/23/24 三包同源）· `test/maui-platform-verify`（W 系列断言）·
`test/hello-maui-razor`（B1 复跑）。需求面 = ArkWeb 能力矩阵
（`2026-09-29-ohos-arkweb-capability-matrix.md`）第 7/9/10/13 项与可行性文档
（`2026-09-29-ohos-blazorwebview-feasibility.md`）§3-B1/B2 缺口 3/4。

## 1. 盘点结论

- 壳（Index.ets）已有：单 ArkWeb + 显隐、`runJavaScript`/`dotnetHost` JS 桥、
  onLoadIntercept 导航网关（B6）、onPageBegin/onPageEnd、hybrid/blazor 资产直供；缺：forward/refresh、
  历史状态回传、frame 定位、cookie 读写、DOM storage、onErrorReceive。
- 切片：`OpenHarmonyWebViewHandler` 仅 Source/Eval/EvaluateJS + Navigating；`IWebView.CanGoBack/
  GoBack/Reload/Navigated` 未映射；Hybrid/Blazor handler 均以整窗 show 代替 frame。
- B1：`OpenHarmonyBlazorWebViewHandler`（milestone 2b/3）与 `test/hello-maui-razor` 均在树内，
  历史 X4 已 publish 成功；本次复跑补新壳/新 handler 证据。

## 2. 六项接线（实现 + 断言）

| # | 缺口 | 实现 | 断言（离线） | 真机 |
|---|---|---|---|---|
| 1 | GoBack/GoForward/Reload + CanGoBack/Forward | 切片 `Invoke` 三个 case → 壳 `back/forward/refresh`；壳 `reportWebHistory()` 以 `history\|b\|f` 状态回传，切片写入 `IWebView.CanGoBack/Forward`、Navigating/Navigated 带 Back/Forward/Refresh 事件种类 | `w1/w2` 源钉 + `w3` 事件 drill（Back+Success / Refresh+Failure） | 回退/前进跨页、事件顺序 |
| 2 | Cookie/存储 | 壳 `WebCookieManager.configCookieSync/fetchCookieSync`（`cookie`/`cookieGet` 命令，读走上行 eval 结果通道）；`.domStorageAccess(true)`（对齐 Android 默认） | `w1/w2/w4`；`GetCookieAsync` 无宿主时 null 快速降级 | cookie 跨页保持、localStorage 重启读回 |
| 3 | frame/bounds（非整窗） | 壳 `frame` 命令（`x\ny\nw\nh`，0 维度=整窗）→ `position/width/height`；三 handler 的 `PlatformArrange` 统一 `SendPlatformFrame` | `w1/w2` 源钉 | 覆盖层与自绘内容几何对齐（DIP==vp 假设） |
| 4 | 导航/加载事件 | 壳 onPageEnd→`finished`、onErrorReceive→`error`（仅主框架）；切片 `Navigated(Success/Failure)` | `w1/w2/w3` | 真 error 页、状态时序 |
| 5 | JS bridge（最小） | 复用既有 `runJavaScript`（requestId 回传）与 `registerJavaScriptProxy`/dotnetHost → `JsMessage`；仅重构为共享的 `SendHostRequestAsync`（cookie 复用） | `w3`/既有 eval+JsMessage 断言（`webview` 系列） | eval 返回值、页面 postMessage 往返 |
| 6 | 加载失败清屏/占位 | 切片收到 `error` 发 `hide`（管理面背景即占位）+ `Navigated(Failure)` | `w2/w3` | 失败页视觉（白底/占位） |

缺口状态：矩阵 6 项「小」中 #7/#9/#10 已接线；#13/#11/#12（多窗口/文件选择/媒体权限）未在本批
范围（仍登记为小缺口）；本批新增的 frame/bounds、导航事件、失败占位是 B2 缺口 3/4 的前置。

## 3. B1 里程碑（本地）

- 复跑命令（X4 配方 + 本地 hook，见 §5 偏差）：`publish -c Release -f net11.0-openharmony26.0
  -r openharmony-arm64 -p:OpenHarmonyUIPage=pages/Index
  -p:OpenHarmonyArktsModulesAbc=dist/ets/modules.abc -p:OpenHarmonyHapPackage=true`。
- 结果：`PUBLISH_EXIT=0`，`sign-profile/sign-app/verify-app success`，签名 hap 75,889,768 B；
  hap 内 `ets/modules.abc` == 新壳（289,992 B / `e005f2366d72…`）；
  `resources/rawfile/dotnet.zip`（259 条）含 `wwwroot/index.html`、
  `wwwroot/_framework/blazor.webview.js`、`blazor.modules.json`、`js/app.js`，无 wasm/dot.js（native 模型）。
- harness：`w5` 钉 Razor SDK + `HostPage=wwwroot/index.html` + `#app` 根组件 + 三包
  `_OpenHarmonyStageBlazorAssets`（wwwroot/** + `@(StaticWebAsset)` 的 blazor.webview.js，缺则硬错）。
- **真机 BLZ 渲染仍是外部依赖**（首屏/`/counter` +1 与 `BLZ_*` 标记：`--blazor-probe`）。

## 4. 验证数字

- 切片构建（Release + `-warnaserror:IL2026,IL3050`）：0 error / 0 IL。
- 交互套件：`checks=398 total=398 floor=378 assert=True`（本批 +5：w1–w5；基线 391 之外另有在树
  的 SEC3 +2；floor 约定 total-20 不降级）；w1–w5 全 assert=True。
- 壳：ArkTS ui/headless 编译过；三包 `--install-packs` + 源同源（`3dafe030…`）；abc
  ui **289,992 B / `e005f2366d724309…`**、headless 20,916 B / `54a1a201…`（不变）。
- 宿主契约：`check-host-exports.py --cross-check` 143/143（本批未新增导出，复用既有
  `ohos_host_web_command` + `notifyWebEvalResult`）。
- 像素套件：`PIXEL ASSERTIONS PASSED`（2,399,269 次写像素）。
- 未构建 kit（按任务约束）。

## 5. 待真机项与本地环境偏差

- 待真机：六项各自「真机」列；重点 = frame 几何（MAUI DIP 与 ArkUI vp 同尺度假设）、历史状态/
  事件种类、cookie 跨页与 HttpOnly、`domStorageAccess` 持久化、error 清屏、B1 `BLZ_*` 两标记 +
  JS 往返。
- 本地偏差（仅命令行 hook，未改仓库文件）：① 包的 AspNetCore 钉 `11.0.0-rc.1.26425.128`，其 OH
  runtime pack 已不在任何 dnceng feed，钩子改指本机缓存 `26451.109`；② rc.2 MSBuild 的 `Exec`
  在本机按 Windows 批处理生成脚本（`exit %errorlevel%` 由 sh 执行必败），三个打包 Exec
  （restool/ohos_packing_tool/sign-hap.sh）用内联 `Process.Start` 任务等效替换。两者只影响本次
  本机复跑，pack 逻辑与产物路径不变。
