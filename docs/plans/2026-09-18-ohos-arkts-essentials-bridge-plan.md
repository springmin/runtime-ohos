# ArkTS-bridged Essentials — integration plan (2026-09-18)

The remaining Essentials APIs need platform services that only the ArkTS side can reach
(`@ohos.*` modules). This document fixes the shape of that bridge so each API is a small,
repeatable addition rather than a new architecture.

## Bridge pattern (already proven by text input)

```
managed (IService)            P/Invoke  ohos_host_<feature>_*        host core
   request  ────────────────────────────────────────────────────────►  listener table
                                                                          │
   completion ◄──────── ohos_host_register_<feature>_result ◄────────────┘
                                                                          │
                                                       NAPI sink ─────────┘
                                                          │  JS call
                                                          ▼
                                                     ArkTS: @ohos.<module>
```

Requirements for every feature:

1. `ohos_host_<feature>_set_listener(fn)` + `ohos_host_register_<feature>_result(fn)` exports
   (function-pointer tables registered by the NAPI layer, like the text-input bridge).
2. A NAPI export `host.register<Feature>Sink(jsFn)` plus result forwarding.
3. ArkTS implementation in the pack's `Index.ets` using the matching `@ohos.*` module.
4. Managed side: `TaskCompletionSource` queue with request ids + timeout, registered in
   `UseOpenHarmony`; features without a sink behave like the current documented stubs.
5. Permissions declared in the template `module.json` (and the demo's).

## Per-API plan

| Essentials API | ArkTS module | Permission | Notes |
|---|---|---|---|
| `FilePicker` | `@ohos.file.picker` (document/photo picker) | - | returns a uri; the slice copies it into the cache dir and exposes an `FileResult` stream |
| `MediaPicker` | `@ohos.multimedia.cameraPicker` / `photoAccessHelper` | `ohos.permission.READ_IMAGEVIDEO` | capture + library pick |
| `Geolocation` | `@ohos.geoLocationManager` | `ohos.permission.APPROXIMATELY_LOCATION` / `LOCATION` | `getCurrentLocation` + `on('locationChange')` for the watcher |
| `Vibration` | `@ohos.vibrator` | `ohos.permission.VIBRATE` | duration/pattern mapping |
| `Permissions` | `@ohos.abilityAccessCtrl` | - | `requestPermissionsFromUser` with a manifest permission list; results map to `PermissionStatus` |
| `Connectivity` (real state) | `@ohos.net.connection` | `ohos.permission.GET_NETWORK_INFO` | `getDefaultNet`/`on('netAvailable')`; currently reports `Unknown` |
| `Launcher`/`Browser`/`Share` (real) | `@ohos.app.ability.wantAgent`, `@ohos.arkui.UIContext` share sheet | - | start an ability / share service |

## Ordering

1. **Permissions** first: `requestPermissionsFromUser` is needed by media/location and is the
   simplest request/response bridge (no streams).
2. **Vibration** (fire-and-forget) — validates the request path without results.
3. **Geolocation** (single + watcher) — validates long-lived callbacks.
4. **FilePicker/MediaPicker** — validates binary results (uri + stream copy).
5. **Connectivity/Launcher/Browser/Share** — replace the current honest stubs.

Each step ships with: host + NAPI + ArkTS changes, a pack version bump, demo wiring, a
headless regression where possible, and a status document under `docs/plans/`.

## Blocker found (2026-09-18)

Importing SDK kits from this shell project fails at compile time
(`Cannot find name 'vibrator'` / `Cannot find namespace 'huks'`) even though the project
targets API 26: the minimal generated project's compilation set does not include the SDK kit
declarations. Fixing it means generating/comparing against a DevEco project with the kits
enabled (module `dependencies`/`syscap` + the SDK's kit index) - that is the first task of
every bridge below, and the reason the ArkTS sinks currently answer "unavailable" while the
managed side already degrades deterministically.

## SDK-level findings (2026-09-18)

Checked directly against the installed SDK (`~/.harmonybrew/.../26.0.0.18_2`):

* `ets/kits/@kit.SensorServiceKit.d.ts` does `import vibrator from '@ohos.vibrator';
  export { sensor, vibrator };` and `ets/kits/@kit.UniversalKeystoreKit.d.ts` re-exports `huks`
  - so the official kit import forms used here are correct;
* `ets/build-tools/ets-loader/kit_configs/@kit.SensorServiceKit.json` maps `vibrator` to
  `@ohos.vibrator.d.ts` with `bindings: default` (same for the keystore kit), i.e. the SDK
  declares exactly the symbols the bridge uses;
* `ets/build-tools/ets-loader/main.js` pushes `<sdk>/ets/api`, `<sdk>/ets/arkts` and
  `<sdk>/ets/kits` into the compiler's system module paths, so the declarations are meant to be
  in scope automatically;
* the shell build now also exports `externalApiPaths` (api:arkts:kits) next to
  `DEVECO_SDK_HOME`.

Even so the compiler reports `Cannot find name 'vibrator'` / `Cannot find name 'huks'` at the
usage sites (the import statements themselves do not error), which points at the *loader
instance* hvigor actually runs rather than at the import syntax. Next step: compare the
loader/plugin versions used by a DevEco-generated project with this minimal project's
`node_modules/@ohos/hvigor*`, then pin the same versions in `hvigorfile`/`hvigor-config`.

## Correction (2026-09-18, later the same day)

The earlier "manual build resolves the modules" conclusion was **invalid**: the manual command
pointed `DEVECO_SDK_HOME` at `~/arkts-build/26.0.0`, which does not exist, so hvigor fell back
to its own default and the modules never resolved. Re-running with the real SDK root (and with
the script's staged root, which *does* symlink `ets`, `js`, `native`, `previewer`, `toolchains`)
reproduces the same `Cannot find name/namespace` errors, now together with the ArkTS strictness
errors (`arkts-no-noninferrable-arr-literals`, `arkts-no-untyped-obj-literals`,
`arkts-no-implicit-return-types`) that the strict forms must satisfy.

So the current state is: **the source has been rewritten to satisfy ArkTS strict rules and to use
the direct `@ohos.*` forms, but this toolchain does not surface the SDK declaration sets to the
project's compilation**, which is an environment/toolchain issue rather than a source issue.
Next investigation: instrument the loader's module resolution (or compare a
DevEco-generated project's `hvigor-config.json5`/plugin pinning) - everything else in the port
is independent of it.

## Verified working (2026-09-18, against the SDK) - superseded

Building the same page with the **project's own hvigor CLI** compiles the direct module forms:

```ts
import vibrator from '@ohos.vibrator';
import huks from '@ohos.security.huks';
```

including `huks.HuksOptions` type usage, the `HuksTag`/`HuksKeyAlg`/... constants and the
callback forms (`huks.generateKeyItem/encryptData/decryptData`) - `CompileArkTS` completes with
warnings only. The **kit** forms (`@kit.SensorServiceKit`, `@kit.UniversalKeystoreKit`) do not
resolve in this project, so the direct forms are the ones to use.

The *same* source fails when built through the pack build script, which means the script's
hvigor invocation/environment (not the source) is the remaining difference: the debug log shows
the script's build mixing two SDK roots (the real SDK's `ets-loader` and a staged
`arkts-shell-build/sdk/26.0.0` for tools). Next step: run the script's build with the same
invocation as the working one (`node node_modules/@ohos/hvigor/bin/hvigor.js --mode module -p
product=default assembleHap`) and/or stage the full SDK so both roots agree.

## Verified snippet (drop-in once the build path is aligned)

```ts
import vibrator from '@ohos.vibrator';
import huks from '@ohos.security.huks';
import util from '@ohos.util';

host.registerVibrationSink((durationMs: number) => {
  vibrator.startVibration({ type: 'time', duration: durationMs > 0 ? durationMs : 100 },
                          { id: 0, usage: 'unknown' });
});

host.registerKeystoreSink((requestId: number, op: string, alias: string, data: string) => {
  const helper = new util.Base64Helper();
  const options: huks.HuksOptions = {
    properties: [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
    ],
  };
  if (op === 'generate') {
    huks.generateKeyItem(alias, options, (err) => host.notifyKeystoreResult(requestId, err ? -1 : 0, ''));
  } else if (op === 'encrypt' || op === 'decrypt') {
    const input: huks.HuksOptions = { properties: options.properties, inData: helper.decodeSync(data) };
    const callback = (err, result) => host.notifyKeystoreResult(requestId,
      (err || !result || !result.outData) ? -1 : 0,
      (result && result.outData) ? helper.encodeToStringSync(result.outData) : '');
    if (op === 'encrypt') { huks.encryptData(alias, input, callback); }
    else { huks.decryptData(alias, input, callback); }
  } else {
    host.notifyKeystoreResult(requestId, -1, '');
  }
});
```

This snippet compiles with this SDK (CompileArkTS completes) when the project is built
manually; the same file fails through the pack build script, so the remaining work is the
script's project regeneration step (compare the regenerated project with the manually patched
state). The script's hvigor invocation was already aligned with the verified working command.

## Port audit (2026-09-18): what was missing and what remains

A systematic review against MAUI's control/capability list found and **fixed** four controls that
had no handler (they rendered as nothing): **BoxView**, **IndicatorView**, **Frame**, **Editor**
(multi-line text on the soft-keyboard bridge). It also **verified XAML**: a `MauiXaml` page
compiles through the MAUI source generator in this workload and lays out its controls
(`label='from XAML'`, button, BoxView all arranged).

### Second audit pass (type-driven, reflection over Microsoft.Maui.Controls)

Enumerating every public `View`/`Page` and checking it against the slice registry found four more
gaps, now **fixed**:

| Control | Was | Now |
|---|---|---|
| `GraphicsView` | no handler (nothing drawn) | `IGraphicsView` handler: the `IDrawable` paints through the compositor canvas; taps forward to `StartInteraction`/`EndInteraction`; pixel assertion passes (Magenta) |
| `ContentView`/`TemplatedView` | no handler (content never arranged) | content measured/arranged in the frame |
| `ImageButton` | rendered as a text button (source ignored) | `IImageSourcePart.Source` mapped, image bytes blitted |
| Modal pages (`PushModalAsync`) | not rendered (the host always used the window content) | the host renders the top of `Window.Navigation.ModalStack` and pops back cleanly |

Also confirmed by enumeration: `BoxView` implements `IShapeView` (it was already covered by the
shape handler; the dedicated handler is simply more precise).

Audited and still open (documented, none blocking the slice):

| Area | Status |
|---|---|
| `SwipeView`, `RefreshView` | no handler (pull-to-refresh/swipe gestures need their own interaction model) |
| `PinchGestureRecognizer`, `SwipeGestureRecognizer` | tap/pan dispatch exists; swipe/pinch not wired |
| `DisplayAlert`/`DisplayActionSheet` (Page) | needs an alert overlay (like the dropdown/popup overlay) |
| `ToolbarItem`s | not rendered in navigation/shell bars |
| Accessibility/semantics | not mapped to platform accessibility |
| `WebView`/`BlazorWebView` | out of scope (needs the ArkTS `Web` component + a bridge) |
| ArkTS-bridged Essentials | blocked by the hvigor toolchain not surfacing SDK declarations (see above) |

## Official sample configuration (found 2026-09-18 on the OpenHarmony sample repo)

`applications_app_samples` (branch `OpenHarmony-v6.1-Release`,
`code/DocsSample/ArkTS/Start/LearningArkTs/IntroductionToArkTS/build-profile.json5`) shows two
things this project was missing:

```json5
{
  "app": { "products": [ {
      "name": "default",
      "targetSdkVersion": 23,          // numeric, not '26.0.0'
      "compileSdkVersion": 23,
      "compatibleSdkVersion": 20,
      "runtimeOS": "OpenHarmony",
      "buildOption": { "strictMode": { "caseSensitiveCheck": true, "useNormalizedOHMUrl": true } }
  } ] },
  "modules": [ { "name": "entry", "srcPath": "./entry", "targets": [ { "name": "default", "applyToProducts": [ "default" ] } ] } ]
}
```

The `buildOption.strictMode` block is now emitted by the shell build script (matching the
official sample); the numeric SDK versions - together with a staged SDK directory named after
the numeric API level - are the next candidate, since hvigor's SDK/declaration resolution
follows the product version. The sample's `hvigorfile.ts` also confirms how SDK knowledge is
obtained in official projects:

```ts
const sdkInfo = appTask.getTaskService()!.getSdkInfo();
const etsApiDir = path.resolve(sdkInfo.getSdkToolchainsDir(), '../ets/api');
```

i.e. the declarations live at `<sdk>/<version>/ets/api`, which our staged root already provides
(522 api entries) - so the remaining difference is how the *version* is declared.

**Shipped while blocked:** the bridge shape for vibration
(`ohos_host_request_vibration`/`registerVibrationSink`) plus honest managed implementations for
permissions/geolocation/file picker/media picker (denied/false/FeatureNotSupported instead of
an unresolved-service exception).

## NDK alternatives — the ArkTS kit blocker is largely avoidable (2026-09-18)

Reading the installed SDK's **native headers** (`native/sysroot/usr/include`) shows a C API for
almost every capability that was blocked on ArkTS kit resolution. They are ordinary NDK APIs
(link with the same clang/CMake toolchain the host library already uses), so they can be exposed
through the existing host/NAPI bridge **without touching ArkTS at all**:

| Capability | NDK header (verified present) | Key entry points |
|---|---|---|
| Connectivity (real state) | `network/netmanager/net_connection.h` | `OH_NetConn_GetAllNets`, `OH_NetConn_GetConnectionProperties`, `OH_NetConn_GetDefaultHttpProxy`, `OH_NetConn_BindSocket` |
| Vibration | `sensors/vibrator.h` | `OH_Vibrator_PlayVibration`, `OH_Vibrator_Cancel` |
| Geolocation | `LocationKit/oh_location.h` | `OH_Location_IsLocatingEnabled`, `OH_Location_StartLocating`, `OH_Location_StopLocating`, `OH_Location_CreateRequestConfig` |
| Permissions | `accesstoken/ability_access_control.h` | ability access control (check/request) |
| Custom fonts | `native_drawing/drawing_font_mgr.h`, `drawing_register_font.h` | `OH_Drawing_FontMgrCreate`, `OH_Drawing_FontMgrCreateFontStyleSet`, register-font APIs |
| Soft keyboard / text editing | `inputmethod/inputmethod_controller_capi.h` | input method controller + text editor proxy |
| Accessibility | `arkui/native_interface_accessibility.h` | accessibility provider APIs |
| Window insets / safe area | `window_manager/oh_window.h` | window manager APIs |
| Media/file pickers | `multimedia/media_library/media_access_helper_capi.h` | media access helper (C API) |
| **WebView** | `web/native_interface_arkweb.h`, `web/arkweb_interface.h` | ArkWeb NDK (the component is usable from C) |
| Sensors | `sensors/oh_sensor.h` | `OH_Sensor_*` |

Genuinely ArkTS-only (still blocked without a DevEco toolchain or the ArkTS kit wiring):
* starting another ability (Launcher/Browser/Share) - `AbilityKit/ability_base/want.h` exists for
  building wants, but the start-ability call itself is not in the NDK;
* ArkUI dialogs (we implement our own overlay-based dialogs instead);
* anything that requires the ArkTS UI shell (the shell itself we already ship).

**Consequence for the plan:** the remaining Essentials/WebView/accessibility/font work should be
implemented as **NDK-backed bridge calls** (host exports + managed wrappers), not as ArkTS kit
imports. That removes the toolchain blocker from every item except ability-start.

## Batch A shipped (preview.16, 2026-09-18)

| Capability | Implementation |
|---|---|
| Vibration | `OH_Vibrator_PlayVibration` via `ohos_host_vibrate`; `IsSupported` = `OH_AT_CheckSelfPermission("ohos.permission.VIBRATE")` |
| Connectivity | `OH_NetConn_HasDefaultNet` / `GetDefaultNet` / `GetNetCapabilities` -> None/Local/Internet/Unknown |
| Permissions | `OH_AT_CheckSelfPermission` with a MAUI-permission -> OpenHarmony-name map (camera, microphone, location, storage, photos, vibrate, network state) |

Remaining batches (same NDK approach, no ArkTS):
B: Geolocation (`OH_Location_*`), custom fonts (`OH_Drawing_FontMgr*` + register-font + `IFontManager`)
C: file/media pickers (`media_access_helper`), IME (`inputmethod_controller`), window insets (`oh_window`), accessibility (`native_interface_accessibility`)
D: WebView on the ArkWeb NDK

## Current state

* [x] pattern proven (text input, redraw, text submit)
* [x] honest stubs in place for every API above (documented behaviour)
* [ ] permissions bridge
* [ ] vibration bridge
* [ ] geolocation bridge
* [ ] file/media picker bridge
* [ ] connectivity / launcher / browser / share bridges
