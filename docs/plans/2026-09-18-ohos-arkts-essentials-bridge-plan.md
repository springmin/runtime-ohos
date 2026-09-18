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

**Shipped while blocked:** the bridge shape for vibration
(`ohos_host_request_vibration`/`registerVibrationSink`) plus honest managed implementations for
permissions/geolocation/file picker/media picker (denied/false/FeatureNotSupported instead of
an unresolved-service exception).

## Current state

* [x] pattern proven (text input, redraw, text submit)
* [x] honest stubs in place for every API above (documented behaviour)
* [ ] permissions bridge
* [ ] vibration bridge
* [ ] geolocation bridge
* [ ] file/media picker bridge
* [ ] connectivity / launcher / browser / share bridges
