# BlazorWebView counter round-trip under NativeAOT (FIX-JSCALL, 2026-10-02)

**Scope:** kit #39 left a trusted click reaching the native BUTTON and `DispatchEventAsync`, but `count` stayed 0; the page probe showed `EnumConverter\`1[JSCallResultType] missing native code`.

## 1. Root cause
- `IpcSender.BeginInvokeJS` serializes `JSInvocationInfo.ResultType` (`JSCallResultType`) and `.CallType` (`JSCallType`) through the WebView package's static reflection-only `JsonSerializerOptionsProvider.Options`. Enums are value types: NativeAOT had no code for the resolver-built `EnumConverter<T>`/`JsonTypeInfo<T>` instantiations (FIX-BWVMount family).
- The renderer's attach interop call is fire-and-forget and died in `IpcCommon.Serialize`, so no interop methods registered (`attach-state=not-attached`); the FIX-BWVMount click probe then attached a stub interop and swallowed every later click - the count could never move.

## 2. Fix (maui-ohos `15d81f31b1`)
`OpenHarmonySliceJsonContext` gains `[JsonSerializable(typeof(JSCallResultType))]`, `[JSCallType]` and `[NavigationOptions]` (under the BlazorWebView gate); the handler static ctor touches those type infos plus `JsonElement[]`. Package options untouched; the stub-attach/synthetic-click probe is removed (`OpenHarmonyBlazorWebViewHandler`).

## 3. Same-family scan (IpcCommon over the package options) + prevention
- rooted now: `JsonElement[]` (inbound, BWVMount), `JSCallResultType`/`JSCallType` (BeginInvokeJS), `NavigationOptions` (Navigate).
- safe already: `byte[]` (non-generic `ByteArrayConverter`, resolver-added), long/string/bool/int (primitives already in the image), `ElementReference` (explicit non-generic converter), `DotNetObjectReference<T>` (reference-type shared generics).
- prevention: any new value type put on the wire needs a context entry + static-ctor touch; the harness pins the three roots. The upstream fix (package-owned source-gen context) is out of slice scope.

## 4. Device evidence (HAD-W32, OpenHarmony 7.0.0.111, AOT)
- hap 21,893,981 B / `6aa54c5d...`; shell abc 342,176/`1af2e2e70b25` (patched razor variant), host `384e552a...`; install OK, pid 60478.
- two `uitest uiInput click`s on the BUTTON: **count 0 -> 1 -> 2** (screenshots `fix-jscall/device/r0-page.jpeg`, `r1-click.jpeg`, `r2-click2.jpeg`); probe tail `| plain ok`.
- hilog: `missing native code`=0, `interop-call`/`attach-state`=0, `BeginInvokeDotNet` accepted=4, `send head=__bwv:["BeginInvokeJS",2,"Blazor._internal.attachW...`.

## 5. Gates / commits
- slice 0 error / 0 IL warning; app IL2026/IL3050/IL3051 = 0/0/0.
- suite checks=555 total=555 floor=535 assert=True (was 554/534, +1 FIX-JSCALL pin); exports 150/150 OK.
- commits: maui-ohos `15d81f31b1`（fast-forward 推送）, ohos-workload `2028cc2`（harness）+ `9073c65`（CI pin 三 workflow → `15d81f31b1`，注释 555/535、150/150）, runtime-ohos this note；合并树门禁复跑：切片 0/0 IL、交互 555/555 floor 535（declared==printed）、像素 PASS、导出 150/150；CI 5/5（interaction `36989506879` / pixel `36989506893` / host-export `36989506617` / ridgraph `36989506653` / markdownlint `36989506646`）。

## 6. Uncertain / open
- `blzProbe` is not defined by the razor sample, so that probe call reports a JSException after crossing the wire; `plain ok` proves the managed->JS half. Sample left untouched.
- `NavigationOptions` was rooted proactively; a live Navigate was not clicked on device this round.
- CI 首跑 interaction / pixel / host-export 三 workflow 在 slice checkout 处红（maui `15d81f31b1` 当时只在本地；补推后 `gh run rerun` attempt=2 全绿）；ridgraph / markdownlint 首跑即绿。
