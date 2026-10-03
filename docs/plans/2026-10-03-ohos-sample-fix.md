# SAMPLE-FIX：razor blzProbe / demo Blazor #app / stock hybridwebview.js 载荷抽取（2026-10-03）

> 件 = ohos-workload `7de4b7d` + `bd28e58` + `913df4d` + `2516857`（app.js 形状修正）、maui-ohos
> `1926cf68b6`；pin 未动（CI 仍 `07423dfe93`）。设备 HAD-W32（hdc 127.0.0.1:35111）AOT 实机；
> 证据 scratch `/data/storage/el2/base/tmp/opencode/sample-fix/`（`device/final`、`device/razor2`、
> `logs/`）。套件（含 L6/L-LEGACY 等并发 pin 的最新基线）：`checks=575 total=577 floor=557
> assert=True`（本波中间态 570/572 floor 552 亦绿；sample-fix pin 在两次运行均 assert=True）。
> `selftest-tasks 9/0`、`selftest-packs OK`；JIT publish `dotnet.zip` 257→260 项。

## 1. `blzProbe` 样例未定义（FIX-JSCALL §6 遗留）
- 根因：`BlazorCounter.razor` 以 `DotNetObjectReference` 调 `blzProbe` 复现 renderer attach 的
  序列化，但样例从未定义该 JS 函数：调用过线后 JSException，`| plain ok` 只证 managed→JS 半边。
- 修复：`wwwroot/js/app.js` 定义 `window.blzProbe`（`bd28e58`）：识别 interop reviver 物化后的
  DotNetObject 实例（`invokeMethodAsync`/`invokeMethod`，兼容 `__dotNetObject` 旧形），返回
  `dotnet-ref ok`；`BlazorCounter` 用 `InvokeAsync<string>` 取值（该 C# hunk 随 ZORDER-NAV
  `680f9ed` 落盘）。
- 真机（AOT）：首轮（`device/final` r0–r2）证明函数已执行且结果回传（`dotnet-ref missing | plain
  ok`，计数 `0→1→2`，无 JSException），但暴露出 interop reviver 会把线形
  `{"__dotNetObject":id}` 物化成 DotNetObject 实例；`2516857` 改为识别实例 API
  （`invokeMethodAsync`/`invokeMethod`）。重出 AOT hap 后（`device/razor2`）：r0/r1/r2 均为
  `probe: dotnet-ref ok`，计数 `0→1→2`（install success，pid 存活 `#FOREGROUND`）。

## 2. hello-maui-app 的 Blazor `#app` 未挂载
- 更正旧结论：不是「缺 `modules.json`」。`2fee278` 起样例已是 Razor SDK 工程，AOT 载荷内
  `wwwroot/_framework/blazor.modules.json` + `blazor.webview.js` 齐全（kit #41 AOT hap 复核）；
  真正原因是 `0e0129e` 把页面的 BlazorWebView 换成第三 Hybrid，`#app` 没有控制去挂载。
- 修复（`7de4b7d`）：恢复按需 BlazorWebView（`HostPage=wwwroot/index.html`、`#app` 挂
  `BlazorCounter`），与 hybrid C 共用固定高度 host（A+B+一个可见第三控件，点按互相 swap）；
  `[DynamicDependency(All, BlazorCounter)]` + `JsonSerializerIsReflectionEnabledByDefault=true`
  （与已真机验证的 razor 样例同配方）；host page 注释改为真实 staging 说明。
- 真机（`device/final` app 段，pid 46424 `#FOREGROUND`，install success）：Add Blazor 后
  `blazor assets origin=https://0.0.0.0/ … slot=0`、`web page (slot 0): https://0.0.0.0/`、
  `BLZ_DIAG message accepted head=__bwv:["AttachPage",…]`、`dispatch run/enqueue/done`、
  `BeginInvokeJS attachWebRendererInterop` eval `result="ok"`、`AttachToDocument,0,"#app"` eval
  `result="ok"`、`RenderBatch,1` 已发送；截图显示 Blazor host page（`origin:
  https://0.0.0.0/`）已出画。组件文本（`BlazorWebView component`/`count:`）在 host page 的
  `#app`（probe 表下方，超出 280-DIP 可视区）——挂载链路已闭环；可视区滚动取证见缺口。

## 3. stock `hybridwebview.js` 在 AOT 载荷的抽取
- 根因：`_framework/hybridwebview.js` 是 `Microsoft.Maui.dll` 的 embedded resource；handler 的
  运行时抽取只能写可写载荷（`dotnet.zip` 解压树），payload-in-libs（DEVCOMPAT JIT 与 AOT）的
  AppDir 是只读 bundle `libs/arm64-v8a/`，写失败 → shell 对 stock 脚本 404（样例页因此内联传输）。
- 修复（`913df4d` + maui `1926cf68b6`）：pack task `OpenHarmonyExtractEmbeddedResource` 从解析到的
  `Microsoft.Maui.dll`（copy-local → runtime → compile 候选，按 FullPath 批处理）抽到
  `<PublishDir>_framework/`（两份载荷都带：dotnet.zip + `libs/<abi>/`，路径保形）；handler 在
  只读根见已 stage 文件按成功返回，可写树保留覆盖语义。`hybrid-c.html` 改载 stock 脚本并走
  `window.HybridWebView.SendRawMessage`/`InvokeDotNet`（旧 pack 回退内联）。
- 真机（`device/final` app 段）：stock 页 `stock hybridwebview.js loaded`；点按后
  `sent raw C-raw-ping (stock)`、`invoke: "C-echo:Echo:1" (stock)`；hilog `hybrid assets
  slot=0/1`、`web page (slot 0/1)`，pid 存活 `#FOREGROUND`。JIT publish：publish 根 15,689 B、
  `libs/arm64-v8a/_framework/hybridwebview.js`、dotnet.zip `_framework/hybridwebview.js`
  （marker entries 257→260）；AOT hap 同项 + marker payloadEntries 8→9。

## 4. 门禁 / 提交
- commits：ohos-workload `7de4b7d`（#2）、`bd28e58`（#1）、`913df4d`（#3）、`2516857`（#1
  形状修正）；maui-ohos `1926cf68b6`（slice 只读根成功语义）；本篇 runtime-ohos。
- gates：交互套件最新基线 `575/577 floor 557`（L6 + L-LEGACY 等并发 pin 就位后复跑；本波
  sample-fix pin 全绿，只增）；`selftest-tasks 9/0`、`selftest-packs OK`；JIT/AOT publish
  IL2026/IL3050/IL3051 = 0/0/0。
- 推送：写作时 github.com 直连不可达（maui-ohos fetch 135 s 超时），全部提交留在本地；按
  「禁强推」纪律未做任何 force 操作，恢复网络后由协调方推送。

## 5. 缺口/不确定
- demo 的第三 web 控件为 swap 语义（C 与 Blazor 互斥占位）；同页四 web 控件仍需 3 槽。
- `#app` 组件文本在 host page 折线下：真机需在 Blazor 控件内上滑才可视；已在 §2 用 hilog
  `AttachToDocument`/`RenderBatch` 闭环证明挂载，滚动截图受共享桌面占用未取到。
- stock 脚本取构建时解析到的 `Microsoft.Maui.dll`；旧 pack 构建的应用仍走运行时抽取/内联回退。
- `blzProbe` 只覆盖 reference 序列化 + JS→.NET 字符串回传，不含 `[JSInvokable]` 反向调用（有意）。
