# BlazorWebView `.razor` mount under NativeAOT (FIX-BWVMount, 2026-10-02)

**Scope:** the last mile of B2 (MAUI hosting a Blazor Hybrid page). After FIX-BACKSIZE
the host page rendered inside its frame and the shell bridge objects existed, but the
`.razor` components never mounted; the page kept sending `__bwv:` attach messages that
died inside the WebView package.

## 1. Root cause

- The WebView package parses every `__bwv:` payload into `JsonElement[]` using its own
  static `JsonSerializerOptions` with a **reflection-only** resolver.
- Under NativeAOT there is no native code for the reflection-built
  `ArrayConverter<JsonElement[], JsonElement>`, so `AttachPage` threw before the page
  could attach. The host page itself was unaffected (it only needs the bridge object),
  which is why the failure looked like "component missing" rather than a crash.

## 2. Fix (maui-ohos `52b082a071`)

- Touching `OpenHarmonySliceJsonContext.Default.GetTypeInfo(typeof(JsonElement[]))` from
  the handler's static constructor keeps the array converter (and its metadata) in the
  AOT image; the package's own options are not modified.
- Diagnostics added so the sequence is observable from hilog: `[maui] blazor
  start/connect` status lines, a diag dispatcher wrapper, and a message-time `BLZ_DIAG`
  console probe (message accepted / dispatch in / enqueue / run / send).
- The razor sample gained the counter round-trip probe (ohos-workload `11ef0fc`:
  `BlazorCounter.razor`, `App.cs`, `_Imports.razor`, csproj).

## 3. Device evidence (HAD-W32, OpenHarmony 7.0.0.111, AOT)

```
[maui] blazor connect: hostPage=wwwroot/index.html services=set
marker: BLZ_DIAG message accepted head=__bwv:["AttachPage","https://0.0.0.0/",...
marker: BLZ_DIAG dispatch in / enqueue / run
marker: BLZ_DIAG send head=__bwv:["AttachToDocument",0,"#app"]
```

Screenshot (`fix-bwvmount/device/e3-click3.jpeg`): the app renders
"MAUI + Razor on OpenHarmony" → "host page loaded; shell bridge: …" →
**"BlazorWebView component (.razor)"** with `count: 0` and the `Blazor click` button.

## 4. Still open

- Counter click round-trip screenshot with count > 0 (the click probe timing vs the
  captured rounds; not yet a decisive pass/fail).
- One `hybrid message rejected` line remains (Hybrid static sink noise, by design).
- Suite/pixel/export gates for this commit are re-run in the FIX3/BWVMOUNT
  consolidation (baseline 554/534 · exports 150).

## 5. Commits

- maui-ohos `52b082a071` (slice: static-ctor type-info touch + diagnostics)
- ohos-workload `11ef0fc` (razor sample counter probe)
- runtime-ohos: this note (push pending; github.com direct was unreachable at write time)
