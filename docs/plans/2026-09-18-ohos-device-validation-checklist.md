# OpenHarmony device validation checklist (2026-09-18)

Everything in this list is blocked on an install-eligible device (`hdc` is restricted in this
environment). Each step names the artifact, the command and the observable result, so a single
session on a device closes the whole port validation.

Updated 2026-09-21: §6 adds the S/T-series capabilities (Blazor/hybrid bridge page,
keep-screen-on, static asset fingerprint fallback + cache headers, file share, flashlight,
accessibility node count and the performance budget), and §0 names the preview.24 artifacts
they need. The older sections stay valid on the same hap.

Updated 2026-09-21 (kit #5): §0 records the kit identity check to run before installing
(sha256 + tree digest; the five haps need no `module.json` edits — legal bundle name and a
device-aligned profile), and §8 adds the P1–P4 startup-crash probe ladder and the fill-in
report template to what to return.

Updated 2026-09-22 (kit #7): the kit identity values live in the release notes, not here — §0
reads the tarball sha256 and the extracted-tree digest from the `device-test-kit` release notes
(`## Integrity`) or the `.sha256` sidecar, so a re-signed or repacked kit can never contradict
this document. Kit #28 measured values: tar **196,220,486 B** / `091dcc56…`, tree **`0a7a3215…`**,
sidecar `d7efd251…` (see `docs/plans/2026-09-26-ohos-tester-handoff-kit28.md` §0).

Updated 2026-09-24 (kit #21, historical snapshot — superseded by the kit #22/#23 notes below): the current kit is #21 — all five haps carry `libIsolation` plus the
complete security/performance/startup fix set since #17 (frame allocation 241,688 → 4,504 B/frame;
P17 extraction skip, H7 rawfile fd read, headless abc `13.0.1.0`) and `tester-run.sh` v6r2 now
collects app-lib/dlopen evidence, kmsg and the XPM/fs-verity probes automatically. The comparison
payloads (dynpkg/normalized/importb/importd/importprobe a–c) and P1–P4 remain on the same release.
Numbers stay in the release notes `## Integrity` (kit #28 measured: tar `196,220,486 B` / `091dcc56…`, tree `0a7a3215…`); the kit's `签名说明.txt` PA1 sentence is
historical wording (source fixed, next kit packaging).

Updated 2026-09-24 (kit #22): the current kit is #22 — a stock-runnable back-port of the on-device
milestone fixes: the host ships a 5-soname `DT_NEEDED` whitelist and resolves every optional system
API through dlopen/dlsym, every hap carries `resources.index` (restool legacy on the device band,
RestoolV2 on API 20), the bootstrap copies the payload ZIP by offset/length and mkdirs the payload
directory before inflating, and the generated shell project mirrors DevEco (`modelVersion 6.0.2`,
00302013 diagnostics). The 2026-09-24 device milestone (kit #18 + five local fixes, first full run)
is recorded in `2026-09-24-ohos-device-milestone.md`; **stock kit (from #22 on; #23 tool refresh, #24
payload-in-libs) has not been on a device yet**, so the checks below remain open — use the milestone §6
decision points (A host load / B bootstrap / C milestone regression) as the first pass/fail gates.

Updated 2026-09-24 (kit #24, historical snapshot — superseded by the #25–#28 notes below): **payload-in-libs + explicit W^X=0 + exec-memory probe**: the
hap `libs/arm64-v8a/` now carries the whole payload plus `.dotnet-payload.json` (the runtime starts
in place from the signed bundle directory; `dotnet.zip` stays as the fallback; the signed hap grows
from ~32.7 MB to ~75.3 MB). The host pins `DOTNET_EnableWriteXorExecute=0` on both launch paths and
adds the `xwe.txt` A/B switch plus the one-shot `OHOS_DOTNET probe: 1=… 2=… 3=… 4=…` line (token 1
anonymous RWX, 2 anonymous RW->RX, 3 memfd RX, 4 file RX; `OK` or errno). The bundled
`tester-run.sh` is now **v8** (`script_version=8`) and collects `hilog/hilog-execmem.txt`
(`execmem_capture`/`execmem_lines` in `summary.txt`) on top of `hilog/hilog-bootstrap.txt`,
`device/payload-files.txt`/`payload-marker.txt` and `meta/kit-selfcheck.txt`
(`kit_index_ok`, `payload=yes|no`). With payload-in-libs, `payload_present=no` is normal (that key
only reflects the fallback filesDir extraction). Judgement: `kit_index_ok=no` means the kit
predates #22 — re-download the current kit; `bootstrap_errors`/`rawfile_errors`>0 are reportable
signatures (see `hilog-bootstrap.txt`) and do not fail the round by themselves. JIT verdict table
and NativeAOT handoff: `2026-09-24-ohos-tester-handoff-kit24.md`; the kit #25 judgement points
(permission dialog copy / Share panel / Scan return / AOT startup): `2026-09-25-ohos-tester-handoff-kit25.md`;
the kit #26 incremental points (first run of the rebuilt payload / native-bridge ABI / PLAT-GAP consumer
path; still valid): `2026-09-26-ohos-tester-handoff-kit26.md`; the kit #27 incremental points (no-HMS
degradation must not throw for Push/Account/Map, first run of the rebuilt payload; history):
`2026-09-27-ohos-tester-handoff-kit27.md`; the kit #28 incremental points (Map overlay / Live View probe /
AOT start bridge / interpreter experiment): `2026-09-26-ohos-tester-handoff-kit28.md`.

Updated 2026-09-26 (kit #28 — current): **R2 — Map overlay / Live View probe / AOT start bridge /
interpreter**: the shell gains the `MapComponent` overlay as a harmony-flavor-only module
(`templates/ets/map/MapOverlay.ets`, literal `@kit.MapKit`, dynamic `'./map/MapOverlay'` import) driven
through `ohos_host_map_command`, with managed `OpenHarmonyMap` overlay APIs (`IsOverlayAvailable`,
show/hide/close, region, marker) and `Ready`/`MarkerClick`/`CameraIdle` events — on the default
OpenHarmony flavor `IsOverlayAvailable=false` and every overlay call degrades without throwing (the real
map needs `ARKTS_SDK_FLAVOR=harmony` plus an AGC map AppKey); the Live View probe (`canIUse` +
`@kit.LiveViewKit`, TIMER scene create/update/stop) registers no sink without the kit/entitlement
(`IsSupported=false`, Start/Update/Stop `Unavailable`, never throws); the host `start_app` route now
probes `lib<stem>.so` / `openharmony_app_main` and logs `aot=1` (falling back to hostfxr with `aot=0`),
so the AOT haps in `aot-haps.tar.gz` can launch from the shell; the interpreter stays a separate
experimental asset (`ohos-interpreter-pack.tar.gz`; `<files>/interp.txt` selects `DOTNET_InterpMode`,
logged as `interp=3 source=file`). Artifacts: abc **264,136 B** / headless 18,532 B, host export contract
**134/134**, suite **334/floor 314**; the kit `verify-kit.sh` re-anchors the abc expectation to `264136`
(the #27 value `245412` now FAILs by design). The kit's five haps are JIT payloads (hostfxr fallback,
`aot=0`); **stock kit (from #22 on, #28 included) has not been on a device yet**, so the checks below
remain open.

Updated 2026-09-27 (kit #27 — history): **KIT-EXT2 — Push / Account / Map**: the shell probes the three
HMS kits (`@kit.PushKit` `getToken()`/`deleteToken()`, `@kit.AccountKit`
`createAuthorizationWithHuaweiIDRequest()` + `getQuickLoginAnonymousPhone`, `@kit.MapKit` capability bits)
and only registers a sink when the variable `import()` succeeds — with no Kit/AGC/HMS everything returns
`Unavailable`/null/false and **never throws**. The host gains 12 kit sinks (`ohos_host_push_*`,
`ohos_host_account_*`, `ohos_host_map_*`; error-code mapping `1000900010`/`1000900012`,
`1001502014`/`1001500001`; export contract 118/118 -> **130/130**) plus the FIX-R1-NAPI-6D boundary
hardening, and the reverse entries (host -> managed callbacks) now marshal off the runtime
(`[UnmanagedCallersOnly]` + `delegate* unmanaged[Cdecl]` thunks; FIX-R1-MARSHAL-OFF). Artifacts:
signed hap ~75.56 MB (zip 278 entries; `libs` 269 = 14 `.so` + 254 payload + `.dotnet-payload.json`),
abc **245,412 B** / headless 18,532 B, in-hap host **265,120 B** / pack 261,024 B, in-hap hosting DLL
**55,296 B**, index 1588/1780 B, `dotnet.zip` 254 entries / 0 `.so`; the kit `verify-kit.sh` re-anchors
the abc expectation to `245412` (the #25/#26 value `234620` now FAILs by design). The kit's five haps
are JIT payloads (hostfxr fallback); **stock kit (from #22 on, #28 included) has not been on a device
yet**, so the checks below remain open.

Updated 2026-09-26 (kit #26; history): **P2-INTEROP + TASK-MIG + PLAT-GAP**: the managed hosting bridge is
fully source-generated `LibraryImport` (125 declarations = 44 hosting + 81 MAUI slice; zero `DllImport`;
the 118/118 host export contract is unchanged), hap packaging tasks are now compiled into the pack
(`tools/Microsoft.OpenHarmony.Tasks.dll`, six task assemblies; `OpenHarmony.Hap.targets` split +
`PlatformItems.targets`), and the ASP.NET Core KFR is pinned to the published `11.0.0-rc.1.26425.128`
band with `RuntimeIdentifier=openharmony-arm64` defaulted and `EnableAppHostPackDownload=false` — consumers
no longer need the per-project workaround. Artifacts: signed hap ~75.47 MB, abc 234,620 / headless 18,532,
in-hap host 240,544 B, in-hap hosting DLL 55,808 B. The kit #27/#28 waves carry these forward unchanged.

Updated 2026-09-25 (kit #25): **permission chain + Share/Scan feature probes + AOT startup
path**: the permissions hap declares every permission with a `reason` (`$string:permission_reason_*`) and a
`usedScene` (`EntryAbility`, `when=inuse`), and the pack targets gate the feature -> permission matrix at
the request point, so the runtime permission dialog must show the localized reason text. Share/Scan are
probed (`canIUse` + variable import) and degrade cleanly on the OpenHarmony SDK (`shareDispatch=False` /
`scanSupported=False`, sinks not registered); only the HarmonyOS SDK variant (`ARKTS_SDK_FLAVOR=harmony`,
HMS device) opens the share panel / returns a scan result. The host gains an AOT startup path
(`lib<stem>.so` -> `openharmony_app_main`, hostfxr fallback for the JIT payload). Rebuilt artifacts:
UI abc `234620` / headless `18532` (version `13.0.1.0`), hap `libs` 269 = 14 `.so` + 254 payload +
`.dotnet-payload.json`, hap zip 278 entries, `resources.index` 1588/1780 B, `dotnet.zip` 254 entries /
0 `.so`; the kit `verify-kit.sh` asserts these. Judgement points on that kit: permission dialog copy,
Share panel, Scan return, AOT startup — see `2026-09-25-ohos-tester-handoff-kit25.md` §2.

## 0. Artifacts

| Artifact | Where |
|---|---|
| `hello-maui-app.hap` (~21 MB, 26.0 band, `verify-app` success; siblings `-permissions`, `-api20`, `-api20-permissions`, `-unsigned`) | `ohos-workload/test/hello-maui-app/bin/Release/<tfm>/openharmony-arm64/` or the delivery kit |
| Delivery kit `device-test-kit.tar.gz` — current delivery kit (**kit #28**: R2 — Map overlay (harmony-flavor-only `MapComponent` overlay; default flavor answers `IsOverlayAvailable=false` and never throws; real map needs `ARKTS_SDK_FLAVOR=harmony` + AGC AppKey) / Live View probe+bridge (no Kit/entitlement -> `IsSupported=false`, calls `Unavailable`, never throws) / `start_app` AOT start bridge (`lib<stem>.so` -> `openharmony_app_main`, log `aot=1`, fallback `aot=0` -> hostfxr) / interpreter experiment (separate `ohos-interpreter-pack.tar.gz`; `<files>/interp.txt` -> `DOTNET_InterpMode`, log `interp=3 source=file`), on top of the #27 KIT-EXT2 Push/Account/Map probes + 12 host kit sinks (134/134 export contract) + FIX-R1-NAPI-6D / FIX-R1-MARSHAL-OFF, the #26 P2-INTEROP `LibraryImport` hosting / TASK-MIG compiled packaging tasks / PLAT-GAP consumer defaults, the #25 permission chain / Share-Scan probes / AOT startup path and #24 payload-in-libs + explicit W^X=0 + exec-memory probe; 5 haps + 8 zh-CN docs + `SHA256SUMS` + the hardened `verify-kit.sh` with per-hap payload-marker assertions and the re-anchored abc expectation `264136`; side assets `aot-haps.tar.gz` (AOT MAUI variant + README) and `ohos-interpreter-pack.tar.gz` (+ README/sidecar); size/sha256/tree digest read from the `device-test-kit` release notes `## Integrity` (kit #28 measured: tar 196,220,486 B / `091dcc56…`, tree `0a7a3215…`, sidecar `d7efd251…`), mirrored on `workload-latest`) | release `device-test-kit`, also attached to `workload-latest`; the same release carries the unsigned startup-crash probes P1–P4 (`hello-mauiapp-probe{1..4}-unsigned.hap`) |
| Workload bundle `openharmony-workload-1.0.0-preview.24.tar.gz` | GitHub release `workload-1.0.0-preview.24` (+ `workload-latest` with `SHA256SUMS`; the SDK release keeps an earlier snapshot) |
| Host library | `packs/Microsoft.OpenHarmony.Sdk/<ver>/hosts/arm64-v8a/libopenharmonyhost.so` (signed) |
| ArkTS shells | `packs/.../templates/ets/modules.abc` (headless) and `modules.ui.abc` (UI); preview.24 carries the T6/T8 archive (fingerprint fallback, keep-screen-on) |

**Step 0 — kit identity check (before installing anything).** Take the current tarball
size/sha256 and the extracted-tree digest from the `device-test-kit` release notes
(`## Integrity`; kit #28 measured: tar 196,220,486 B / `091dcc56…`, tree `0a7a3215…`; `workload-latest` mirrors them) or the `.sha256` sidecar. Then run the
quickstart's verify chain — ① `sha256sum -c device-test-kit.tar.gz.sha256` (or
`verify-kit.sh --anchor-file …`), ② extract, ③
`verify-kit.sh --expect-tree-digest <tree digest from the release notes>` — and confirm the
in-kit version line (`最终状态.md`「发布物」 or `README-交付说明.md`「构建基线」) reads
`1.0.0-preview.24`. Re-signed or pre-signed kits legitimately differ: compare only against the
release notes (or the sidecar) of the build you downloaded, never against a value copied into a
document. The five kit haps are already legal (`bundleName` matches the profile) and
band-aligned, so **no rename and no `module.json` edit** is needed.

The kit #23 verifier also asserts the payload facts per hap (`resources.index` present/non-empty,
abc `13.0.1.0` + current size (kit #28 rebuilt shell `264136`/headless `18532`; the #27 value `245412`
and the #25/#26 value `234620` now FAIL by design),
14 libs, `dotnet.zip` composition, host ELF dependency policy); kit #24 adds the
`libs/arm64-v8a/.dotnet-payload.json` payload-in-libs assertion (missing/inconsistent marker =
FAIL): `FAIL` exits 1, `WARN` stays `KIT OK`. It passes on kit #22 and **reports real defects on
kit #21 and older (they will FAIL — expected, not a tool bug)**; use the kit's own verifier for an
old kit.

## 1. Install and launch

```
hdc install -r hello-maui-app.hap          # or: bm install -p <extracted dir>
hdc shell aa start -a EntryAbility -b com.example.hellomauiapp
```
Expected: the app starts; the status file (`<filesDir>/dotnet-status.txt`) contains
`bridge attached: registered=True`, `[hello-maui-app] starting MAUI application`,
`[maui] window created (Window), content=ContentPage`.

Kit #5 and later replace the earlier rename/band workarounds, so the haps install and start
under the shipped `bundleName` as-is. `9568344` still means the debug profile does not carry
this device's UDID (send the UDID, or p7b + p12 + cer + keyAlias for the `--external` pre-sign
path in the signing guide §4c). If the app exits ~1 s after `aa start` (`exit 254` / `JsError`), go to §8's
probe ladder instead of retrying.

## 2. Rendering (pixel expectations)

The window is a `FlyoutPage` (drawer) whose detail is a `TabbedPage` (Home + Animations).

| # | Action | Expected |
|---|---|---|
| 2.1 | Look at the Home tab | dark-slate background, "MAUI on OpenHarmony" title, nav bar with the title, bottom tab bar with two tabs |
| 2.2 | Tap **Count** | label increments; the counter text persists after restart (Preferences) |
| 2.3 | Drag the 30-item **CollectionView** | list scrolls smoothly; the first visible row changes; tapping a row tints it |
| 2.4 | Drag the legacy **ListView** | rows scroll; `legacy row N` labels visible |
| 2.5 | Shapes row | orange rectangle, green ellipse, gold diagonal line |
| 2.6 | **Border** | blue rounded border around "inside border" |
| 2.7 | Value row | checkbox toggles, switch toggles, slider moves the progress bar, spinner rotates, stepper −/+, radio dot |
| 2.8 | **DatePicker** | month calendar opens; `<`/`>` change months; tapping a day updates the field |
| 2.9 | **TimePicker / Picker** | dropdown lists open, a selection updates the field |
| 2.10 | Search bar | tapping focuses; typing shows characters via the soft keyboard |
| 2.11 | **Entry** | tap focuses (caret), the ArkTS soft keyboard shows, typed text appears, **Enter** raises `Completed` (status label updates) |
| 2.12 | Animations tab | button runs FadeTo/TranslateTo/RotateTo visibly; carousel swipes (looping) and shows dots |

## 3. Interaction

| # | Action | Expected |
|---|---|---|
| 3.1 | Tap the tappable label | counter in its text increments (TapGestureRecognizer) |
| 3.2 | Drag inside the pan label | no crash; pan callbacks run (log) |
| 3.3 | Swipe the drawer open (hamburger at top-left) | drawer slides in; tapping an item switches; tapping outside closes |
| 3.4 | Switch tabs | content swaps; tab bar highlights the active tab |
| 3.5 | Navigation: from the drawer/second page use back | returns to the previous page; the back chevron appears only when the stack is deeper |

## 4. State and storage

| # | Action | Expected |
|---|---|---|
| 4.1 | Restart the app | the counter keeps its value (`Preferences`) |
| 4.2 | `SecureStorage` path | values are written through HUKS when the keystore kit is enabled in the shell project; otherwise the documented file fallback is used (see the HUKS plan) |
| 4.3 | Files | `AppDataDirectory` is `<filesDir>`; files written by the app are visible there |

## 5. Performance smoke

| # | Action | Expected |
|---|---|---|
| 5.1 | Scroll a 30-item list | no visible stutter; virtualization keeps only ~1 screen of item views (log line: `collection materialized=N of 30`) |
| 5.2 | Idle | CPU stays low (renderer redraws on request only; animation ticks only while indicators run) |

## 6. S/T-series capabilities (preview.24)

These items need the preview.24 pack (the S1/T5 page assets, the T6 shell archive and the T8
keep-screen-on sink all live in it). Triggers are in the demo (`hello-maui-app.hap`) unless a
step says otherwise; every step also names the managed call, so an item can be driven from any
page event when the demo build has no control for it. The log lines are in
`<filesDir>/dotnet-status.txt` or `hilog`.

### 6.1 Blazor/hybrid validation page (S1, T5)

The demo's Home tab embeds a `HybridWebView` (`HybridRoot=wwwroot`, `DefaultFile=index.html`,
400 px high). Its handler registers the extracted `wwwroot` tree with the shell, which serves
the page and its assets from the MAUI hybrid origin `https://0.0.0.1/`. The page
(`wwwroot/index.html` + `js/app.js`) is a dependency-free bridge smoke test whose header lists
the expected probe values.

| Probe | Expected on the Blazor root (`https://0.0.0.0/`) | Expected on the hybrid origin (`https://0.0.0.1/`, the demo) |
|---|---|---|
| `typeof window.external` | `object` | `object` |
| `typeof window.external.sendMessage` | `function` | `function` |
| `typeof window.external.receiveMessage` | `function` | `function` |
| `typeof window.dotnetHost` | `object` | `object` |
| `typeof window.dotnetHost.postMessage` | `function` | `function` |
| `typeof window.__dispatchMessageCallback` | `function` | `undefined` |
| `typeof window.HybridWebView` | `undefined` | `object`, but only when the page loads `_framework/hybridwebview.js` (see the note) |
| `typeof window.Blazor` | `object` (once `blazor.webview.js` loads) | `undefined` |
| `typeof window.__ohosDotNet` | `object` | `object` |

Note: the page header's hybrid column assumes a stock hybrid page, which loads
`_framework/hybridwebview.js` (that script assigns `window.HybridWebView`). The demo page loads
only `js/app.js`, so its `HybridWebView` row reads `undefined` and **Send ping** goes through
`window.external.sendMessage`; a plain WebView without any registration leaves every row
`undefined` and the page reports that no bridge function was found.

| # | Action | Expected |
|---|---|---|
| 6.1.1 | Open the Home tab | the page renders "OpenHarmony bridge test"; the location line shows `origin: https://0.0.0.1` and `readyState: complete`; the probe table fills within a few seconds (the shell injects after the load event; the page refreshes for 15 s) |
| 6.1.2 | Read the probe table | the hybrid-origin values above; the probe values themselves are the confirmation (the `[maui] web finished: <url>` line is only written for a plain `IWebView`, not for this `HybridWebView`) |
| 6.1.3 | Tap **Send ping** | the status line shows `sent #N via window.external.sendMessage` plus the JSON ping (`{"kind":"ohos-bridge-ping",...}`) and "waiting for a reply (the stock Blazor IPC does not answer plain JSON)"; the demo label under the WebView changes to `hybrid raw message: {...}` (the managed `RawMessageReceived` hook). "Sent, no reply" is the expected stock result; `send #N FAILED via ...` means the channel registration broke |
| 6.1.4 | Watch the inbound log (message area) | when the app sends a host message (there is no automatic reply), it appears as `[time] <channel>: <payload>`; on this origin the channel is `HybridWebViewMessageReceived` (the shell shim's `receiveMessage`). `__dispatchMessageCallback` stays `undefined`, so **Self test inbound** reports "self test skipped: ... not a function yet" — expected, not a failure |
| 6.1.5 | Blazor root only (a page served from `https://0.0.0.0/`) | the Blazor-root column above; `Blazor.start()` loads `_framework/blazor.webview.js` (it first fetches `_framework/blazor.modules.json`, staged in `wwwroot/_framework/`); `__dispatchMessageCallback` is a function and **Self test inbound** logs a labelled page loopback (not a host reply) |

### 6.2 Keep screen on (T8)

`DeviceDisplay.Current.KeepScreenOn = true` queues `ohos_host_keep_screen_on(1)`; the preview.24
shell sink resolves the last window (`getLastWindow`) and calls `setWindowKeepScreenOn(true)`.
The managed getter caches the last value the host accepted (queued), not the window's real
state.

| # | Action | Expected |
|---|---|---|
| 6.2.1 | Turn Keep screen on on (demo control that sets `DeviceDisplay.Current.KeepScreenOn = true`) | no exception; the getter reads `true`; no log line on success |
| 6.2.2 | Leave the app foregrounded and untouched until the device's screen timeout would fire (>= 1 min) | the screen does not dim or lock |
| 6.2.3 | Turn it off (`= false`) | the normal screen timeout behaviour returns; the getter reads `false` |
| 6.2.4 | Watch the logs | window service rejected: hilog `[maui] keep screen on failed: ...`; missing host export: `[maui] keep-screen-on bridge unavailable (no host library)` once and the value stays `false` |

### 6.3 Static web asset fingerprint fallback + cache headers (T6)

The preview.24 shell serves hybrid and Blazor payload files with a fingerprint fallback
(`name.<8-32 lowercase hex>.ext` -> `name.ext`, exact name first, one retry) and cache headers,
and the hybrid and Blazor bridges share the path. The demo page references base names only, so
the fallback itself needs a manual request.

| # | Action | Expected |
|---|---|---|
| 6.3.1 | Request a fingerprinted name whose base file exists (WebView devtools console, a page `fetch()`, or app-side `EvaluateJavaScriptAsync`), e.g. `https://0.0.0.1/js/app.0a1b2c3d.js` or `https://0.0.0.0/_framework/blazor.webview.713e519f.js` | 200 with the base file's content (`js/app.js` / `_framework/blazor.webview.js`); an existing exact name always wins |
| 6.3.2 | Request names that must not be rewritten (`app.settings.css`, `.hidden.css`, 7/33 hex digits) | 404 unless an exact file exists; ordinary dotted names are served unchanged |
| 6.3.3 | Probe the headers (devtools console: `fetch(url).then(r => r.headers.get('cache-control'))`) | fingerprinted: `public, max-age=31536000, immutable`; base names (`blazor.webview.js`, `hybridwebview.js`, the host page, app assets): `no-cache` |
| 6.3.4 | Watch the `[maui]` lines | the file path itself is silent; a plain-`IWebView` document logs `[maui] web finished: <url>` (the hybrid handler logs no web lifecycle line); registration/injection failures show `[maui] hybrid assets registration failed: ...`, `[maui] blazor assets registration failed: ...` or `[maui] blazor bootstrap injection failed: ...` |
| 6.3.5 | Traversal guard | `..`, `\` and encoded traversal still answer 404 (the fallback can only shorten the last file name) |

The shell implements no `If-None-Match`/`If-Modified-Since`: `no-cache` relies on the WebView
re-asking and the shell always returns the full 200 body.

### 6.4 Share file (S4)

`Share.RequestAsync(new ShareFileRequest { File = new ShareFile(path) })` builds a `file://`
URI and a MIME type from the extension, then dispatches an implicit
`ohos.want.action.sendData` Want with `FLAG_AUTH_READ_URI_PERMISSION` (shell kind 3; the plain
text share path is kind 1 and unchanged).

| # | Action | Expected |
|---|---|---|
| 6.4.1 | Share a small `.txt` from `AppDataDirectory` (demo share action, or the managed call above) | the system share/ability picker appears; choose a target app (chat/email/file manager) |
| 6.4.2 | In the target app, open or read the shared item | the file has the right name and content; `text/plain` for `.txt` (20 extensions are mapped, others `*/*`) |
| 6.4.3 | Repeat with a `.pdf` | same; the picker may be narrowed to `application/pdf` targets |
| 6.4.4 | Watch the logs | success: `[maui] ability start dispatched: kind=3`; failure: `[maui] share file request could not be dispatched (<mime>)` and hilog `[maui] ability start failed: kind=3 ...` |
| 6.4.5 | Multiple files | exactly 1 file uses the same path; 0 or >1 files keep the documented no-op and log `[maui] share multiple files request (N files) needs Share Kit (not in this SDK)` |

The URI is a sandbox absolute path (`file:///data/...`); the read flag expresses the grant, and
whether the receiver can actually open the file is what this run proves.

### 6.5 Flashlight (S3)

`Flashlight.Default.TurnOnAsync()` / `TurnOffAsync()` / `IsSupportedAsync()` map to op 1/0/2 on
the Camera Kit torch bridge. No manifest permission is needed (only camera input/session APIs
carry `ohos.permission.CAMERA`). `setTorchMode` is synchronous and the boolean means "the kit
accepted the request", not "the LED is lit".

| # | Action | Expected |
|---|---|---|
| 6.5.1 | Turn the flashlight on (demo control) | the rear-camera torch LED lights; the call returns without throwing |
| 6.5.2 | Turn it off | the LED goes dark |
| 6.5.3 | Query support | `IsSupportedAsync()` is `true` on a device with a torch; `false` without a torch/Camera Kit or before the shell sink registers |
| 6.5.4 | Watch the `[maui]` lines | success is silent; a failed request writes `[maui] flashlight turn-on unavailable (no host/sink, no torch or kit error)` (or the `-off` variant); the shell logs `[maui] flashlight request failed: <message>` (e.g. 7400102 camera not allowed, 7400201 service fatal) |

### 6.6 Accessibility node count + A11Y self-check (S2, Q2)

The shell's `A11Y` overlay button (bottom-left, 44×24, does not take layout) opens an
"Accessibility self-check" dialog with the provider status and, when the host library exports
the count, the number of published nodes (`host.accessibilityNodeCount()`).

| # | Action | Expected |
|---|---|---|
| 6.6.1 | Tap **A11Y** | the dialog shows `accessibilityStatus: <n> (<label>)` and `accessibilityNodeCount: <count>` |
| 6.6.2 | Read the status | 0 = not attached, 1 = attached (expected), 2 = frame node refused, 3 = custom node not created, 4 = custom node attached but provider refused; other values show `<n> (unknown status)`. 0 is normal before `onPageShow`; after the page is mounted expect 1 |
| 6.6.3 | Read the node count | the last published node count (the same value the provider serves). Record it: it must be > 0 on a rendered page, identical when the dialog is re-opened without a page change, and change after navigating or switching tabs |
| 6.6.4 | Older host library | the dialog shows `accessibilityNodeCount: unavailable` (the status still resolves) |
| 6.6.5 | Check the status file | `[maui] accessibility provider status=<n>` (1 = attached, the ideal value; report 2/3/4 or unknown values with the line) |

### 6.7 Performance budget

The frame-path budget is enforced by the off-device interaction suite
(`test/maui-platform-verify`); its `[verify] perf` line is the number to quote:

```
[verify] perf warmup=8 frames=200 nodes=... avg=...ms p50=...ms p95=...ms max=...ms max/avg=...
allocDelta=...B alloc/frame=...B elapsed=...ms budget=avg<=20ms,max<=250ms,max/avg<=100
warmupOk=True within=True
```

| # | Action | Expected |
|---|---|---|
| 6.7.1 | Take the perf line from a recent suite/CI log | `within=True`; budget avg <= 20 ms, max <= 250 ms, max/avg <= 100 (recent host runs: avg 3.1-10.4 ms, p95 3.9-14.7 ms, max 5.8-20.0 ms) |
| 6.7.2 | With hdc: run the §5 smoke (30-item scroll, animations) while recording `hdc hilog > log.txt` | no visible stutter; attach the log excerpt plus the suite's perf line — the device frame path has no separate perf line, so the suite line is the reference budget |
| 6.7.3 | Without hdc | judge by §5.1/§5.2 and the in-app behaviour; note "perf line not collected (no hdc)" in the report |

## 7. Known test-side items (not device blockers)

* the pixel harness's checkbox-stroke sample reads a neighbouring colour (the check line itself
  is verified); the selection-tint sample needs the tap re-checked with fresh frames;
* both are test-side and tracked in the port status document; the renderer behaviour they cover
  is verified by the other 10 pixel assertions.

## 8. Reporting back

Collect `dotnet-status.txt`, `hilog` excerpts around a tap/typing/animation and any crash
traces, and record them in the fill-in template `2026-09-21-ohos-device-report-template.md`
(one page; its §0–§1 also pin the kit version and hashes). **If the app exits at startup
(`exit 254` / `JsError`) or a step dies with no log line**, add the minimal evidence from
`2026-09-21-ohos-device-crash-diagnostics.md` and walk the probe ladder in
`2026-09-21-ohos-crash-probes.md` — P1 shell-only, P2 host `dlopen`, P3 host entry/`dlsym`,
P4 per-dependency; its decision table names the failing layer, and its P4 section has a
no-app 14-library self-check (`hdc shell ls -l /system/lib64/...`). The probe haps are
unsigned and live on the same `device-test-kit` release. With those, the port validation is
complete and the remaining work is upstream API approval only. `tester-run.sh` v8 already packs
the app-lib/bootstrap/payload/kit-selfcheck/exec-memory evidence into `tester-report-<stamp>.tar.gz`; quote
its `summary.txt` keys (`bootstrap_errors`/`rawfile_errors`/`libload_errors`/`payload_present`/
`payload_marker`/`kit_index_ok`/`execmem_capture`/`execmem_lines`) in the report.
