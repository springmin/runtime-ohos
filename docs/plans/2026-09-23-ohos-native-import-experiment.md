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

## 8. RM1: lib-isolation packaging fix + no-rebuild device diagnostics

**Status (2026-09-24):** the template change shipped in kit #17 (the `libIsolation` repack) and every kit since (#18–#22) carries it; the current kit is **#22** (device-milestone back-port: host on-demand dlsym, `resources.index`, ZIP/mkdir, DevEco layout; `tester-run.sh` v6r2 unchanged). The candidate payloads (dynpkg/normalized/importb/importd/importprobe a–c) and P1–P4 all remain on the `device-test-kit` release for the next device re-test; the main choice is kit #22 itself. **Correction (2026-09-24):** the successful device run (kit #18 + five local fixes, `managed app hello-maui-app.dll started (UI shell)`) did not depend on RM1/alias; the direct chain was the host dlopen + bootstrap fixes — RM1/RH1 stay as harmless hardening (`2026-09-24-ohos-device-milestone.md` §2). The RM1 device half remains unproven (see §8.4/§8.5).
**Change:** `ohos-workload` `packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.{22,23,24}/templates/module.json.template`
now opens the `module` object with `"libIsolation":true` (all three files stay byte-identical).
The hap staging target `_OpenHarmonyStageHap` reads that template and writes the staged
`module.json` after the `@...@` replacements, so no target change was needed.

### 8.1 Key-name provenance (checked against source)

* OH bundle framework `services/bundlemgr/src/module_profile.cpp` parses the key through
  `MODULE_IS_LIB_ISOLATED`, defined `constexpr const char* MODULE_IS_LIB_ISOLATED = "libIsolation";`
  (`common_profile.h:434`), into `module.isLibIsolated`; BMS then persists it as `isLibIsolated`
  (`inner_bundle_info.cpp`).
* hvigor's `@ohos/hvigor-ohos-plugin` declares `libIsolation?: boolean;` in its module options
  (`src/options/configure/module-json-options.d.ts:101`); the SDK docs document the same key.

### 8.2 Why this is expected to fix the lookup (source chain)

For a non-isolated hap, BMS `ParserNativeSo` -> `UpdateNativeSoAttrs` (`module_profile.cpp`) sets only
the **app-level** `nativeLibraryPath` (`libs/<abi>` via `SetNativeLibraryPath` ->
`baseApplicationInfo_`); the module-level field stays empty. `GetEtsHapSoPath`
(`ets_native_lib_util.cpp:39-43`) returns early on an empty `hapInfo.nativeLibraryPath`, so no
`<bundle>/<module>` app-lib key is registered - only `default` (`:136`, `:145-153`). The runtime's
`requireNapi("openharmonyhost", true, "<bundle>/entry")` therefore misses the app-lib map and falls
back to the system lib dir (`Load native module failed`).

With `libIsolation:true` the same function takes the isolated branch and sets the **module-level**
path `<module>/libs/<abi>` (`SetModuleNativeLibraryPath` -> `InnerModuleInfo.nativeLibraryPath`), so
`GetEtsHapSoPath` builds `appLibPathKey = <bundle>/<module>` and logs
`appLibPathKey: com.example.hellomauiapp/entry, lib path: ...` - the key the `@app:` record /
`requireNapi` lookup searches.

### 8.3 Locally verified (demo publish, 26.0 band)

`dotnet publish test/hello-maui-app ... -p:OpenHarmonyHapPackage=true` (the demo publish):

* hap `module.json`, unsigned and signed, read back with `zipfile`: `"libIsolation":true` (a JSON
  boolean, not a string);
* `libs/arm64-v8a/` still carries all 14 entries including `libopenharmonyhost.so` - the packing
  tool keeps the flat layout; the module-folder layout is an install-time BMS effect;
* `ets/modules.abc` sha256 unchanged
  (`2d0eb8b4a70b88256d38b2740b07531243d5c28474d36313ef4c81e6baaddc50`, = `dist/ets/modules.abc`);
* signing step in the publish log: `sign-profile success`, `sign-app success`, `verify-app success`
  (independently re-run with `hap-sign-tool verify-app`: `hap verify successed!`).

**Build-environment note:** the publish resolves `_OpenHarmonySdkPackDir` to the *installed* workload
pack (`~/.dotnet/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/`), not the repo pack, and
`DOTNETSDK_WORKLOAD_PACK_ROOTS` does not override an installed workload. The repack chain must copy
this one template into the installed pack next to the abc sync (playbook §2), or the produced haps
stay non-isolated. (The installed copy was synced during this verification; the pre-change file is
kept at `/data/storage/el2/base/tmp/opencode/rm1/installed-module.json.template.orig`.)

### 8.4 Device diagnostics (no rebuild; work on the already installed app)

Clear the log first (`hdc -t "$D" shell "hilog -r"`), start/warm the app, then run one capture per
check. These localize the failure on the current non-isolated install without building anything.

| # | Check | Outcome -> meaning |
|---|---|---|
| 1 | `hdc -t "$D" shell "hilog -x \| grep -E 'SetAppLibPath\|appLibPathKey\|NativeLibPath\|lib path'"` | an `appLibPathKey: <bundle>/<module>` line -> the per-module key is registered (isolated build); only `default`/app-level paths -> `hapInfo.nativeLibraryPath` was empty, i.e. a non-isolated install (current kits); no `appLibPathKey`/`lib path` line at all -> the registration code did not run (wrong window, or the app died before it). `GetEtsHapSoPath` logs at DEBUG (`ets_native_lib_util.cpp:53-54`), so widen with `hilog -b D` if the level hides it. |
| 2 | `hdc -t "$D" shell "ls -l /data/storage/el1/bundle/libs/arm64/ \| grep openharmonyhost"` | a match -> the host was extracted to the shared app-level libs dir (current non-isolated behavior); no match -> locate it with `find /data/storage/el1/bundle -name libopenharmonyhost.so 2>/dev/null`: under a module-named folder means isolation already took effect, nowhere means the so was not extracted at all (a different install-time failure). |
| 3 | `hdc -t "$D" shell "hilog -x \| grep -E 'dlopen\|cannot find library\|openharmonyhost'"` | a `dlopen .../libopenharmonyhost.so` line -> the loader reached dlopen on the hap/app path; `cannot find library`/`No such file` -> the lookup fell back to the system lib dir and the file is absent there (the non-isolated miss); `[openharmony-host] native module register function bound via alias '...'` -> the `.so` loaded and registered under that name, and the alias string is the **decisive signal** for which `nm_modname` (bare `openharmonyhost` vs file alias `libopenharmonyhost.so`) the loader bound. |

### 8.5 Expectation for the lib-isolation build (next repack)

**2026-09-24 note:** the device milestone run did not test this expectation — the successful run did
not show a `Load native module failed` block, so the RM1 path/key half remains unproven and is kept
as harmless hardening (see `2026-09-24-ohos-device-milestone.md` §2/§5).

* Check 1 should gain `appLibPathKey: com.example.hellomauiapp/entry` (plus the existing `default`);
  that registration is the point of RM1 - the VM lookup for the `@app:<bundle>/entry/openharmonyhost`
  record finally has a key to hit.
* Check 2's `libs/arm64/` listing is expected to change: the isolated module's so's install under a
  module-scoped path. Use check 1's `lib path:` string as the ground truth for the exact location
  rather than the assumed layout.
* Check 3 should show the host loaded from that path, then the alias line. Either alias
  (`openharmonyhost` or `libopenharmonyhost.so`) is acceptable at the path level; if one alias binds
  but `registerXComponent` stays `undefined`, the remaining problem is the record/registration-name
  half (playbook §2/§3), not the path/key half. Success signal is unchanged from the kit #16 run:
  `registerXComponent=function`, first frame, no `Load native module failed`.

### 8.6 Fallbacks if lib isolation does not bind

Fixes B/C from `2026-09-23-ohos-napi-import-fix-playbook.md` §3/§4 remain as fallbacks: the dynamic
`loadNativeModule` shell change (only if probe C binds), and the normalized-OHM-URL +
`pkgContextInfo.json` packaging route (VM gate `IsNormalizedOhmUrlPack()`; normalized host record
`@normalized:Y&&&libopenharmonyhost.so&`, with the entry record re-verified on device because the
normalized entry form regressed before PA1). RM1 supersedes neither; it removes the path/key half of
the blocker and leaves only the name/record half to the probes.
