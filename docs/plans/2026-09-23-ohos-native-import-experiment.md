# ArkTS native-module import forms: which abc record binds to our NAPI names?

**Date:** 2026-09-23
**Status:** artifacts uploaded to `sdk-ohos` release tag `device-test-kit`; device run pending (tester)
**Owners:** runtime-ohos RI1 experiment; artifacts built from the ohos-workload `cb7bc3e` host
**Related:** `2026-09-22-ohos-startup-crash-rootcause.md` (kit #14), `2026-09-19-ohos-hap-acceptance-for-testers.md`,
`2026-09-21-ohos-tester-selfsign.md`, `2026-09-21-ohos-signing-and-udid-guide.md`

## 1. Why this experiment

Kit #14 fails to bind the ArkTS shell's host import:

```text
Load native module failed, ModuleName: @app:com.example.hellomauiapp/entry/openharmonyhost
```

The currently shipped abc is a **non-normalized** (`useNormalizedOHMUrl=false`) build: es2abc turns
`import host from 'libopenharmonyhost.so'` into the record
`@app:<bundleName>/entry/openharmonyhost` - the `lib` prefix and `.so` suffix are stripped. On the
other side, the host `.so` (ohos-workload `cb7bc3e`, preview.24, 195,488 B,
sha256 `1b2fcac7...e8818`) registers its NAPI module under **two** `nm_modname` values:

* `openharmonyhost` (bare name, `g_hostModule`)
* `libopenharmonyhost.so` (file-name alias, `g_hostModuleFileAlias`)

Each alias logs which one bound:

```text
[openharmony-host] native module register function bound via alias 'openharmonyhost'
[openharmony-host] native module register function bound via alias 'libopenharmonyhost.so'
[openharmony-host] Init re-entered (module bound under more than one name)
```

This kit builds three minimal ArkTS haps (no .NET payload, one page each) to determine which import
form produces an abc record the device's ArkTS VM actually routes to those registration names.

## 2. Artifacts (unsigned; sign with the tester's own flow)

| Variant | Asset (`device-test-kit`) | Bundle | Size (B) | sha256 |
|---|---|---|---|---|
| A control | `hello-mauiapp-importprobe-a-unsigned.hap` | `com.example.hellomauiapp.importprobea` | 1479264 | `c4871259515fdee7afdacf5d9442f7fe3ad50583703e4c8f2510d9ec41ffb1ca` |
| B substituted | `hello-mauiapp-importprobe-b-unsigned.hap` | `com.example.hellomauiapp.importprobeb` | 1479272 | `7014f32ae4b27a9bfd15bef1226bc3ee90e4ed8c114976388938fecc50c3ed98` |
| C dynamic | `hello-mauiapp-importprobe-c-unsigned.hap` | `com.example.hellomauiapp.importprobec` | 1479656 | `7a2ecb186d4b922cab7dea17ae16bbb32570fdafe64be2a25fffcecb9c9543c1` |

Every hap carries the **same** `libopenharmonyhost.so`
(sha256 `1b2fcac7c9a0fd4466b69fa1e828f1d30d8ad79457aea21fd4f26fdd7d8e8818`, 195,488 B; unsigned) and the
same `libc++_shared.so` the demo publish ships
(sha256 `f957ec5d67a10e2769305d82a6f4b5dc52328e780b9bd04eb056f9fd63f2c078`, 1,271,736 B). No other native
libraries are needed: `readelf -d` on the alias host lists only platform libs plus `libc++_shared.so`
(no CoreCLR/hostfxr `DT_NEEDED`), so the runtime natives are intentionally absent.

### Per-variant import form and abc evidence

| Variant | ArkTS source form | abc evidence (`ark_disasm`) | Expected bind |
|---|---|---|---|
| A | `import host from 'libopenharmonyhost.so'` | `ModuleTag: REGULAR_IMPORT, local_name: host, import_name: default, module_request: @app:com.example.hellomauiapp.importprobea/entry/openharmonyhost` | record basename `openharmonyhost` should hit the bare `nm_modname`; this is the exact kit #14 shape, now retried against the alias-capable host |
| B | **substituted:** `import * as host from 'libopenharmonyhost.so'` (see below) | `ModuleTag: NAMESPACE_IMPORT, local_name: host, module_request: @app:com.example.hellomauiapp.importprobeb/entry/openharmonyhost` | same module_request as A, different import kind; if A and B differ, the VM cares about the ModuleTag |
| C | `loadNativeModule('openharmonyhost')` then `loadNativeModule('libopenharmonyhost.so')` | **no import record at all**; literals `lda.str "openharmonyhost"` / `lda.str "libopenharmonyhost.so"` and `tryldglobalbyname "loadNativeModule"` in `Index.aboutToAppear` | the raw string reaches the loader without es2abc record rewriting; `openharmonyhost` should hit the bare name, `libopenharmonyhost.so` the alias |

#### Variant B: the requested bare-name form is not expressible

`import host from 'openharmonyhost'` (no `lib`/`.so`) is rejected by the ets-loader:

```text
ArkTS Compiler Error 10505001
Cannot find module 'openharmonyhost' or its corresponding type declarations.
At File: .../entry/src/main/ets/pages/Index.ets:5:18
```

The loader only rewrites native specifiers matching the regex `/lib(\S+)\.so/`
(`getOhmUrlBySystemApiOrLibRequest` in the SDK's
`ets/build-tools/ets-loader/lib/ark_utils.js`), producing
`@app:<bundleName>/<moduleName>/<capture>` in the non-normalized path; every other specifier is
resolved as an external package (the build host also warns
`ohos.nativeResolver not supported on the current operating system`). An ambient
`declare module 'openharmonyhost'` shim does not change that - module resolution runs before type
declarations. B therefore uses the fallback candidate named in the experiment brief (namespace
import), which is the closest expressible static form and still differs from A in the emitted
record shape.

Variant C is expressible: the SDK declares
`declare function loadNativeModule(moduleName: string): Object;`
(`ets/build-tools/ets-loader/declarations/global.d.ts`, `@stagemodelonly`, `@atomicservice`,
`@since 12`; throws `10200301 - Loading native module failed`).

## 3. Build settings and provenance

* hvigor 6.26.4 + `@ohos/hvigor-ohos-plugin` (ohos-workload `.arkts-build` install), OpenHarmony SDK
  26.0.0.18 (`platformVersion 26.0.0`, `apiVersion 26`), node 26.8.1, openjdk@17.
* `compileSdkVersion`/`targetSdkVersion` `26.0.0`, **`compatibleSdkVersion 18`**,
  **`useNormalizedOHMUrl=false`** - the same settings as the shipping shell. The emitted abc header
  is `13.0.1.0` in all three variants (checked at byte offset 0x0c), matching the demo's
  `virtualMachine: ark13.0.1.0`.
* Packaged `module.json` copies the demo's 26-band fields verbatim except for `bundleName`:
  `minAPIVersion 50002014`, `targetAPIVersion 60101024`, `apiReleaseType Release`,
  `compileSdkVersion 6.0.2.130`, `compileSdkType HarmonyOS`, `debug true`,
  `deviceTypes phone/tablet/2in1`, `virtualMachine ark13.0.1.0`, `compileMode esmodule`.
* Hap assembly is manual (`module.json`, `ets/modules.abc`, `resources/base/**`,
  `libs/arm64-v8a/*.so`; ZIP_STORED, same member layout as `hello-maui-app-unsigned.hap` minus the
  .NET payload): hvigor's own `PackageHap` step fails on this host because
  `app_packing_tool.jar` is not installed.
* abc sha256: A `9566d36b912b06d1c5728e812e62f0d84115945ddadecee5308a5368449e9f56` (9,308 B),
  B `b60a42c7b7c94871e46edf25791b877f0a5204966da4db1dc494025e27d8b0fb` (9,316 B),
  C `e6ef6da43dbc217a7017cb50c6149251d05c0e8c3c1b1d2b854cebde33f6bd9f` (9,700 B).

### Upload confirmation

The three assets were uploaded to `springmin/sdk-ohos` release `device-test-kit` with the new names
above; the GitHub API digests were re-read after upload and all three match the local sha256 values
in the table. The 8 assets that existed before the upload (`device-test-kit.tar.gz`, its `.sha256`,
`hello-mauiapp-probe1..4-unsigned.hap`, `new-features-device-checklist.md`, `tester-run.sh`) were
unchanged by this upload.

## 4. Sign, install, start (tester)

The haps are **unsigned** and need the tester's usual self-sign flow (same steps as the delivery
kit's `hello-maui-app-unsigned.hap`): sign the hap, and make sure the ELF libraries inside
(`libopenharmonyhost.so`, `libc++_shared.so`) are signed by that flow as well - see
`2026-09-21-ohos-tester-selfsign.md`. Then:

```sh
D=<device-UDID>

hdc -t "$D" install hello-mauiapp-importprobe-a-unsigned.hap
hdc -t "$D" shell aa start -b com.example.hellomauiapp.importprobea -a EntryAbility

hdc -t "$D" install hello-mauiapp-importprobe-b-unsigned.hap
hdc -t "$D" shell aa start -b com.example.hellomauiapp.importprobeb -a EntryAbility

hdc -t "$D" install hello-mauiapp-importprobe-c-unsigned.hap
hdc -t "$D" shell aa start -b com.example.hellomauiapp.importprobec -a EntryAbility
```

The three bundle names differ, so all of them install side by side with the existing demo. Capture
each app's window of hilog; the interesting lines are the `IMPORTPROBE_*` markers, every
`Load native module failed` line, and the `[openharmony-host] native module register function
bound via alias ...` lines around them.

## 5. What to look for in hilog

Common chain (all variants):

```text
IMPORTPROBE ABILITY_ON_CREATE
IMPORTPROBE ABILITY_ON_WINDOW_STAGE_CREATE
IMPORTPROBE LOAD_CONTENT_OK
IMPORTPROBE_A|B|C PAGE_ABOUT_TO_APPEAR
```

| Signal | Meaning |
|---|---|
| `... registerXComponent=function` (and `host_type=object`) | the import bound; the module object is live and the shell fix is a one-line import change |
| `... registerXComponent=undefined` | the import resolved (no exception) but the module exported nothing - alias registration did not apply to this record |
| `Load native module failed, ModuleName: <record>` | the runtime could not load the module for that record; `<record>` is the exact lookup key (for A/B it should be `@app:<bundle>/entry/openharmonyhost`) |
| `[openharmony-host] native module register function bound via alias '...'` | the `.so` was loaded and registered under that name - a positive bind marker from the host itself |
| `[openharmony-host] Init re-entered (module bound under more than one name)` | both names bound (expected only if a flow looks the module up twice) |
| `IMPORTPROBE LOAD_CONTENT_FAIL {...}` | the page module failed to load; the JSON error is the evidence (no page markers follow) |
| C only: `C openharmonyhost LOAD_FAIL {...}` / `C libopenharmonyhost.so LOAD_FAIL {...}` | `loadNativeModule` rejected that name (BusinessError `10200301` = not found) |

For A and B the failure record is expected to be
`@app:com.example.hellomauiapp.importprobe{a,b}/entry/openharmonyhost`; if the log instead shows a
different `ModuleName`, that string is the actual lookup key and is the single most important
finding. For C the failure line contains the raw string passed to `loadNativeModule`.

## 6. Interpretation guide

| Observed outcome | Reading | Next action |
|---|---|---|
| Any variant logs `registerXComponent=function` | that import form binds on this device | make the shipping shell use that form (A/B: change import; C: replace the top-level host import with `loadNativeModule('...')` in `EntryAbility.onCreate`/`bootstrap`) |
| A and B both fail, C `libopenharmonyhost.so` binds | non-normalized `@app:...` records are not routed to native modules, but the raw file-name lookup is | move the shell to dynamic load of `libopenharmonyhost.so`, or ship `pkgContextInfo.json` and build normalized (`@normalized:Y&&&libopenharmonyhost.so&` is the known-working reference shape) |
| A and B both fail, C `openharmonyhost` binds | the VM looks up the bare registered name, and only the raw string reaches it | use `loadNativeModule('openharmonyhost')` in the shell |
| C both names fail with `10200301` | the loader's dynamic path cannot see the module either (namespace/packaging problem rather than record spelling) | investigate linker namespace / HAP lib loading; the record-form theory is exhausted |
| A fails, B binds (or vice versa) | the ModuleTag (default vs namespace) matters in the VM's native-module routing | mirror the binding kind in the shell |
| A/B/C all fail with the same `@app:.../entry/openharmonyhost` record | the record form is not the (only) blocker; the runtime never reaches the registration names | pursue normalized OHM + `pkgContextInfo.json` packaging and/or the runtime loader's app-lib namespace |

## 7. Limits and uncertainty

* All three haps are **unsigned**; the embedded host ELF is the unsigned build. If the tester's
  signing flow re-signs ELFs inside the hap, the signed copy is what the device runs - same code,
  same aliases. Do not mix in the pre-alias host (sha `0c15a68a...`, 150,432 B): it only registers
  `openharmonyhost` and would produce misleading B/C results.
* B is a substitution: the requested bare static specifier cannot be expressed (section 2). It still
  probes the "static namespace import" record shape, but it is not a direct test of
  `import host from 'openharmonyhost'`.
* Device runtime behavior is unknown until the tester runs the three apps; this document records
  the prepared artifacts and the expected bind for each variant, not observed device results.
* The `device-test-kit` release is concurrently maintained by other work; the "existing assets
  unchanged" check compares against the snapshot taken immediately before this upload.
