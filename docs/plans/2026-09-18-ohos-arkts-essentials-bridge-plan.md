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

## Batch B shipped (preview.17, 2026-09-18)

| Capability | Implementation |
|---|---|
| Geolocation | `OH_Location_CreateRequestConfig` + `OH_LocationRequestConfig_SetCallback` + `StartLocating`/`StopLocating`; `GetLocationAsync` polls the latest fix, `GetLastKnownLocationAsync` reads it, `StartListeningForegroundAsync` raises `LocationChanged`; `IsEnabled` = location permission |
| Custom fonts | `OpenHarmonyFontManager` (`Microsoft.Maui.IFontManager`) resolves a family to a font file and the host applies `OH_Drawing_TypefaceCreateFromFile` to every text draw/measure (`ohos_host_set_font_file`) |

Note: the low-level `OH_Drawing_TextBlob` font API has no family setter, so the supported path is
a loaded typeface (file-based) rather than a family name.

## Batch C-1 verdict (corrected, 2026-09-18)

A broader grep (matching the full symbol names rather than one prefix) shows
`OH_InputMethodController_Attach` **is** present, together with the text-editor proxy
(`inputmethod_text_editor_proxy_capi.h`) and the input-method proxy
(`inputmethod_inputmethod_proxy_capi.h`). So the soft keyboard **can** be driven from the NDK:
the platform asks for an editor proxy, and the proxy's callbacks (insert/delete/get text) carry
the typing into the managed side. That replaces the ArkTS `TextInput` bridge with a native one.

`window_manager/oh_window.h` still has **no avoid-area query**, so safe-area handling stays with
the ArkTS window API.

## Batch C-1 verdict (first pass - superseded)

Checked the installed SDK headers directly:

* `inputmethod/inputmethod_controller_capi.h` exposes only
  `OH_InputMethodController_Detach` - **no `Attach`** and no text-editor proxy registration in this
  NDK, so an NDK-only soft-keyboard integration is not possible; the ArkTS input-method API (or
  the shell TextInput bridge we already ship) remains the path for real typing.
* `window_manager/oh_window.h` exposes window state APIs (status/navigation bar toggles, shown,
  touchable, focusable, brightness, ...) but **no avoid-area / safe-inset query**, so safe-area
  handling has to come from the ArkTS window API (`getWindowAvoidArea`).

Conclusion: batches **C-2 (pickers) and D (WebView)** remain the only paths for those
capabilities, and both require extending the ArkTS shell (a `Picker`/`Web` component exposed to
the managed side through NAPI). Batch A (vibration/connectivity/permissions) and batch B
(geolocation/fonts) are shipped and installed (preview.17).

## Batch C-1 shipped (preview.18, 2026-09-18)

The soft keyboard is now driven from the platform NDK: `OH_InputMethodController_Attach` with an
editor proxy plus `OH_InputMethodProxy_ShowKeyboard/HideKeyboard`, exposed as
`ohos_host_keyboard_show/hide`. `OpenHarmonyBridge.RequestTextInput` prefers the NDK path and
keeps the ArkTS shell request as a fallback, so focusing an Entry/Editor raises the real keyboard
without ArkTS. The proxy's text callbacks (`inputmethod_text_editor_proxy_capi.h`: insert/text,
delete forward/backward, get text of cursor, selection, enter key, ...) are the next step for
fully native typing.

Remaining: C-2 (pickers need a `Picker` component inside the ArkTS shell) and D (WebView needs a
`Web` component in the shell exposed through NAPI). Safe-area and accessibility stay with the
ArkTS APIs (documented above).

## Batch C-1 completed (preview.19, 2026-09-18): native typing

The editor proxy callbacks are registered before attaching (`OH_TextEditorProxy_SetInsertTextFunc`,
`SetDeleteForwardFunc`, `SetDeleteBackwardFunc`, `SetGetTextConfigFunc`), UTF-16 input is
converted to UTF-8, the host keeps the IME buffer and forwards whole-text updates through the
existing `TextInput` bridge; `ohos_host_keyboard_set_text` (hosting `SetKeyboardText`) seeds the
buffer with the focused Entry/Editor text so backspace edits real content. Typing therefore no
longer depends on ArkTS at all.

Remaining for the "everything" goal:
* C-2 pickers: a `Picker`/`PhotoViewPicker` component inside the ArkTS shell exposed through NAPI;
* D WebView: a `Web` component inside the shell (ArkWeb) exposed through NAPI;
* safe-area and accessibility: ArkTS window/accessibility APIs only (this NDK has neither).

## Items 3 and 4 shipped (preview.21 / preview.22, 2026-09-18)

* **WebView (preview.21)**: the shell embeds a hidden ArkWeb `Web` component; the managed
  `OpenHarmonyWebViewHandler` drives it with show/hide/load/data/back commands and mirrors page
  start into `IWebView.Navigating` (the Controls `Navigated` event is internal, logged).
* **Safe area (preview.22)**: the shell reports `window.getWindowAvoidArea` through
  `host.notifyAvoidArea`; the app host insets the arranged content so pages stay clear of system
  bars. Accessibility semantics remain ArkUI-node-bound and stay documented as a limitation.

Every remaining capability from the audit now has an implementation path: batches A/B/C-1 were
native (NDK), and C-2/D/4 use the ArkTS shell through the same NAPI bridge pattern.

## Gap item 1 progress (2026-09-18): DisplayAlert overlay

`DisplayAlert` now works: `OpenHarmonyAlertManager` (the Controls `IAlertManager`) captures
requests and `OpenHarmonyAlertHost` state is drawn by the compositor (scrim, dialog box,
Accept/Cancel) with taps resolving `AlertArguments`. Verified end to end (shown/pending -> tap ->
result=True). Action sheets and prompts remain simple (logged / null) pending list and text-input
overlays.

Action sheets and prompts are done as well: the sheet renders its option rows and resolves the
chosen string, and the prompt edits through the IME bridge (append on typing, Return accepts) with
completion ordered before hiding. Verified: sheet -> 'Beta', prompt -> 'hello!'; 103 checks.

Swipe gestures are done: SwipeGestureRecognizer rides the shared drag tracking, and dispatch uses
MAUI's two-phase contract (SendSwipe records deltas, DetectSwipe evaluates the threshold and raises
Swiped) filtered by Direction flags. Verified by dragging left over a left|right target ->
SwipeDirection.Left; 104 checks. Pointer hover and pinch stay open: PointerGestureRecognizer's
dispatch is internal to Controls (the slice compiles into a harness where internals are not
visible) and pinch needs a multi-touch bridge extension (the touch callback carries one point).

ToolbarItem is done: the navigation page mirrors the current page's toolbar items into the bar
(collection/property changes included), the bar draws them right-aligned with shared draw/hit
geometry, and taps activate through IMenuItemController (Clicked and Command, IsEnabled honored).
Verified: items=1 and tapping raises the command once; 106 checks. SwipeView and RefreshView remain
from item 1d (they need platform views beyond the chrome work already in place).

SwipeView is implemented: the handler lays the row out as a content view, mirrors leading/trailing
ISwipeItems into the platform view with IsOpen round-tripping, the compositor draws the revealed
panel, a completed horizontal drag (the renderer's Swipe track) opens/closes it, and taps activate
the item through IMenuItemController and close the row. Verified: items=1, drag -> open=True both
platform and ISwipeView, tap -> Clicked raised and row closed; 109 checks. Known gap:
SwipeItem.Invoked is not raised by that activation (Clicked/Command are); raising it needs the
internal invoked hook. RefreshView remains from item 1d.

RefreshView is implemented as well: the handler arranges its content like a content view and a
downward pull past 60px (the renderer's Swipe track) flips the platform IsRefreshing and notifies
the virtual view, so MAUI raises Refreshing and runs Command; a spinner arc is drawn while
refreshing and clearing IsRefreshing stops it. Verified: pull -> platform/virtual True with exactly
one command run, reset -> False; 112 checks.

Gap item 1 is therefore complete: DisplayAlert, action sheets, prompts, swipe gestures, toolbar
items, SwipeView and RefreshView all work and are covered by the harness. Remaining known limits
are recorded above (Pointer hover internals, pinch multi-touch bridge, SwipeItem.Invoked).

Gap item 2 has begun with the sensor kit: the host subscribes through the NDK sensor API
(OH_Sensor_GetInfos/CreateInfos/Subscribe/Unsubscribe, sampling interval in nanoseconds) and
forwards one reading per event to OpenHarmonyAccelerometer/OpenHarmonyGyroscope, which implement
the MAUI Essentials interfaces (G units for the accelerometer, rad/s for the gyroscope, SensorSpeed
mapped to intervals, ShakeDetected above 2.5g with a one second debounce). Install() replaces the
Essentials defaults through their backing fields. Verified headlessly: the defaults are our types,
IsSupported and Start/Stop run without throwing when the host library is missing; 114 checks.
Readings require device hardware (validation checklist). The Notification Kit part of item 2 and
the camera capture of item 3 remain.

The notification kit part of item 2 is implemented as well: OpenHarmonyNotifications.Show calls the
host export, which forwards to the NAPI layer, whose sink the ArkTS shell registers and publishes
through @ohos.notificationManager (basic text content, failures logged). Missing host library or
sink degrades to false instead of throwing - verified headlessly (False on a desktop, 115 checks).
Regenerating the shell archive (es2abc/hvigor) so the device shell contains the sink is the
remaining packaging step; publishing itself needs device hardware. Item 3 (camera capture) remains.

Gap item 3 (camera capture) is implemented by reusing the picker pipeline: CapturePhotoAsync and
CaptureVideoAsync send request kinds 3/4, the shell's picker sink runs cameraPicker.pick with the
back camera and returns the captured file base64 encoded through notifyPickerResult (failures are
logged and returned as errors), and IsCaptureSupported reports whether the host library is loadable.
Verified headlessly: captureSupported=False and CapturePhotoAsync returns null off-device without
throwing; 115 checks. Real capture needs device hardware and a rebuilt shell archive.

Packaging status (preview.23): prepare-packs.sh needed a fix (it wrote the FrameworkList/RuntimeList
files without creating the data directory) and now lays out the preview.23 Ref/Runtime packs; the
host was rebuilt and self-signed into the preview.23 SDK pack (sensor and notification exports) and
the shell templates were carried over with the notification sink and camera capture branch. Two
blockers remain: build-arkts-shell.sh cannot refresh the UI shell archive because the hvigor 6.26.4
tarball on the Huawei mirror returns 404 (so the archive still has no notification/camera code), and
pack-workload-bundle.sh resolves its version from a source that still yields preview.22. Rebuilding
the shell archive and the demo hap follows once hvigor is reachable or a local hvigor cache is used.

Preview.23 is published: the workload manifest moved to 1.0.0-preview.23 and pack-workload-bundle
plus publish-workload-release produced workload-1.0.0-preview.23 and refreshed workload-latest. The
SDK pack contains the rebuilt and self-signed host (sensor and notification exports) and the shell
templates with the notification sink and camera capture branch. The shell archive itself is still
stale: build-arkts-shell.sh can now install hvigor from a local file mirror (the Huawei tarball URL
404s) but then fails with "mkdir: '/project': Permission denied", i.e. the project base path is
empty in that run, so modules.abc/modules.ui.abc were not regenerated and the shipped archive still
lacks the notification and camera code. Fixing that path handling, rebuilding the archive, then
re-packing and rebuilding hello-maui-app.hap are the remaining packaging steps.

The shell archive blocker is resolved: build-arkts-shell.sh referenced HVIGOR_DIR one line before
assigning it (so the project path collapsed to /project) and the camera branch used
cameraPicker.CameraPosition, which cameraPicker does not export (it lives in
@ohos.multimedia.camera). With hvigor served from a local file mirror the shell now compiles -
dist/ets/modules.abc (23880 bytes) carries the notification sink and the camera capture branch and
is stored in the preview.23 pack as modules.ui.abc, and preview.23 was re-packed and re-published
with it. The demo hap is rebuilt from the same archive.

Preview.23 is complete: the SDK pack now also carries Sdk/targets/ridgraph (without them no hap
could be packaged), the hap target runs with -p:OpenHarmonyHapPackage=true, and hello-maui-app.hap
(21517056 bytes, signed) was rebuilt against the freshly compiled shell archive that contains the
notification sink and the camera capture branch. The bundle was re-packed and re-published with
workload-latest refreshed. Structure verified: module.json, ets/modules.abc, the ABI host library
and resources/rawfile/dotnet.zip are all present. Remaining: device validation (hdc is blocked by
the organization policy) per the validation checklist.

Limitations re-audit (2026-09-18): two of the recorded limits were liftable and are now closed.
SwipeItem.Invoked fires because activation calls the public ISwipeItem.OnInvoked() (Invoked plus
Clicked/Command), and pointer gestures work because OpenHarmonyPointer invokes the internal
SendPointerEntered/Exited/Moved/Pressed/Released through cached reflection with the renderer
dispatching enter/press on touch down and release/exit on touch up (entered/pressed/released/exited
all verified; 117 checks). The remaining limits are precisely scoped: pinch dispatch is public
(IPinchGestureController.SendPinchStarted/SendPinch/SendPinchEnded/Canceled) but the touch bridge
carries one point, so multi-touch requires extending the host, NAPI and shell; true hover needs an
onHover callback from the shell; accessibility semantics need an ArkUI node tree; and device
validation still needs hdc access.

Pinch is implemented through the bridge: the shell reports phase/scale/centre with notifyPinch, the
host stores the managed listener (ohos_host_register_pinch) and forwards it, and
OpenHarmonyWindowRenderer.HandlePinch routes to the deepest view owning a PinchGestureRecognizer
via the public IPinchGestureController. Verified headlessly with a synthesised gesture
(Started:1.0 Running:1.5 Running:2.0 Completed:1.0; 118 checks). The shell side turned out to be unnecessary: the XComponent touch
event already carries every point, so the host computes the pinch directly (distance between points
0 and 1, scale relative to the first two-finger event, Completed when the points drop to one) and
calls the managed listener. No ArkTS or NAPI change was required and the host library was rebuilt
and self-signed.

Real pointer hover is done too: the NDK mouse callback arrives as a touch move, so
HandlePointerMove tracks the hovered view and raises Exited/Entered on changes plus Moved on every
report (verified: moving over a pointer label raises Entered, moving away raises Exited; 119
checks). Pointer, pinch and SwipeItem.Invoked are therefore all closed; the only remaining
limitations are the architectural ones (accessibility needs an ArkUI node tree, BlazorWebView/Hybrid
WebView and the Hot Reload overlay need extra runtimes or dev tooling) and device validation, which
is blocked by the hdc organization policy.

Final state: the interaction regression is green at 119 checks, the pixel suite passes, preview.23
was republished with the pinch host and the refreshed hosting assembly (installed packs included)
and the demo hap was rebuilt and signed against it. Everything in the gap list is implemented; what
remains is device validation (blocked by the hdc organization policy) and the architectural items
(accessibility needs an ArkUI node tree; BlazorWebView/HybridWebView and the Hot Reload overlay need
extra runtimes or dev tooling).

Architecture-level work (all four accepted) is staged in batches. Batch D1 (visual diagnostics
overlay) is done: OpenHarmonyDiagnostics.Enabled outlines every view with its type name in the
compositor and counts the outlines (verified: 108 outlines in one frame; 120 checks). Batch D2
(accessibility) has its API inventory complete from the SDK: OH_ArkUI_NativeModule_GetNativeAccessibilityProvider,
OH_ArkUI_AccessibilityProviderRegisterCallback(WithInstance), OH_ArkUI_CreateAccessibilityElementInfo /
OH_ArkUI_AddAndGetAccessibilityElementInfo with the full ElementInfo setter surface (text, contents,
component type, screen rect, child/parent ids, clickable/enabled/focusable/editable/checked,
operation actions), OH_ArkUI_CreateAccessibilityEventInfo with OH_ArkUI_SendAccessibilityAsyncEvent
and OH_ArkUI_FindAccessibilityActionArgumentByKey for action arguments. Batch D3 (BlazorWebView and
HybridWebView) needs a JS<->.NET channel - ArkWeb provides registerJavaScriptProxy, runJavaScript and
postMessage - plus static-asset serving and the BlazorWebView handler in the slice. Batch D4 (Hot
Reload) depends on the dotnet-watch/HotReload agent, a device connection channel (hdc is blocked by
policy) and runtime metadata-update (EnC) support.

Still open from the gap list: Pinch/Pointer gestures (multi-touch needs a bridge extension),
SwipeView/RefreshView, ToolbarItem, sensor/notification kits, camera capture.

## Current state

* [x] pattern proven (text input, redraw, text submit)
* [x] honest stubs in place for every API above (documented behaviour)
* [ ] permissions bridge
* [ ] vibration bridge
* [ ] geolocation bridge
* [ ] file/media picker bridge
* [ ] connectivity / launcher / browser / share bridges
