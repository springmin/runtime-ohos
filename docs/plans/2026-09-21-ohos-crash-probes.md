# OpenHarmony startup-crash probes P1/P2/P3/P4 (JsError / exit 254)

> Companion to `2026-09-21-ohos-device-crash-diagnostics.md`. The tester's device
> (OpenHarmony 7.0.0.105 / API 26 / 2in1, UDID `60CF7B27…F8A19`) installs the kit hap but the app
> exits ~1 s after `aa start` (`exit 254`, `AppKilledReporter` `reason=JsError`).
>
> **2026-09-22 update**: the tester's evidence chain (E1–E5 plus the working `cc-switch` abc
> comparison: 37 vs 1–2 occurrence counts, missing record index entries) pinned the current kit
> crash to the shell abc entry record — fixed in kit #10 (`useNormalizedOHMUrl=false` +
> bundle-prefixed record, `ohos-workload c2c4a9a`/`6e55ae6`) and verified on device by the tester;
> see `2026-09-22-ohos-startup-crash-rootcause.md`. The same re-test surfaced a second pre-shell
> blocker, the abc bytecode version (`24.0.0.0` vs the device's `13.0.1.0` ceiling; hilog shows
> `export objects of native so is undefined` / `Cannot read property … of undefined`), fixed in
> kit #11 (`95c89a7`/`ef1c947`, §4.0b). The kit #11 re-test then surfaced a third blocker: the
> host `.so` did not load when the always-loaded ability module imported it, leaving `host`
> undefined (every guarded call logs `[maui] host export unavailable`; the first unguarded call,
> `registerXComponent` in the page's `.onLoad`, throws `TypeError` and the process exits 254).
> Covered in §4.0c; fixed in kit #12 (`ohos-workload 7e71c39` + shell archive `2411a8e`) by keeping
> the host's hostfxr surface dlopen-only (`build-host.sh` now fails if `libhostfxr` appears in
> `DT_NEEDED`) and routing every `host.<api>` access through the `hostCall` +
> `typeof host !== 'undefined'` guard. The kit #14 re-test then cleared every crash (the app now starts
> and stays alive, zero crash logs) but the screen is black: the host's napi registration name
> (`nm_modname = "openharmonyhost"`) no longer matches the abc's `useNormalizedOHMUrl=false` import
> record name (`@app:com.example.hellomauiapp/entry/openharmonyhost`), so the native module never
> loads and the host exports stay empty — see §4.0d and the table row (fix RH1, in flight). The
> P1–P4 ladder below still classifies **dlopen / host-entry / .NET-runtime** crashes; branch on
> the exact exit error first (§4.0/§4.0b/§4.0c). The install error `9568257 fail to verify pkcs7 file` is the
> expected rejection of the kit's self-signed haps (re-sign `hello-maui-app-unsigned.hap` first).
>
> **2026-09-24 update (kit #24: payload-in-libs + explicit W^X=0 + exec-memory probe):** all four branches above are fixed in the current kit — entry
> record (#10), abc bytecode version (#11), host `.so` load (#12), and the host napi
> registration-name mismatch (RH1 alias registrations, kit #16, plus the RM1 `libIsolation` repack,
> kit #17). The startup perf fixes ship as well (P17 extraction skip, H7 rawfile fd read, headless
> abc `13.0.1.0`). **Device evidence correction (2026-09-24):** the successful device run
> (`managed app hello-maui-app.dll started (UI shell)`, see `2026-09-24-ohos-device-milestone.md`)
> showed the RH1/RM1 name/path halves were **not** the critical blocker; the direct chain was the
> host `.so` dlopen on a reduced system image (10 missing libraries + 62 symbols), the missing
> `resources.index` (`GetRawFileContent failed`), the ZIP offset/length copy error (900003), the
> pre-inflate mkdir error (900002), and the hvigor abc build (00302013). Kit #22 back-ports all
> five (host `DT_NEEDED` whitelist of 5 + on-demand dlsym; restool `resources.index`; range copy;
> mkdir; DevEco `modelVersion 6.0.2` layout) and keeps RH1/RM1 as harmless hardening. Kit #24 adds
> payload-in-libs (payload starts in place from the signed `libs/<abi>/`) and the JIT verification
> device (explicit `DOTNET_EnableWriteXorExecute=0`, `xwe.txt` A/B, `OHOS_DOTNET probe:` line).
> The P1–P4
> ladder stays valid for any remaining dlopen / missing-dependency / host-entry / .NET-runtime
> crash; `tester-run.sh` v8 additionally collects the app-lib evidence
> (`hilog/hilog-applib.txt`, `hilog/hilog-dlopen.txt`, `device/app-libs-arm64.txt`), the
> bootstrap/rawfile signatures (`hilog/hilog-bootstrap.txt` + `summary.txt` counters), the
> payload state (`device/payload-files.txt` / `payload-marker.txt`), the exec-memory evidence
> (`hilog/hilog-execmem.txt` + `execmem_capture`/`execmem_lines`) and a local kit hap
> self-check (`meta/kit-selfcheck.txt`, `kit_index_ok`) automatically.
> Numbers for the current kit: release `## Integrity` + `2026-09-22-ohos-release-manifest.md`.
> JIT verdict table and NativeAOT handoff: `2026-09-24-ohos-tester-handoff-kit24.md`.
>
> These four minimal, standalone probes bisect the failure between five layers:
> **ArkTS shell/device SDK** (P1), **host .so dlopen** (P2), **host entry points / dlsym** (P3),
> **per-dependency preflight** (P4), **.NET runtime/main startup** (only reached when all four pass).

## 0. Artifacts (unsigned — sign with the tester's own flow)

| probe | asset | size (bytes) | sha256 |
|---|---|---|---|
| P1 shell-only | `hello-mauiapp-probe1-unsigned.hap` | 12004 | `bec893c2ea6120b360b45e5b7a61593d5799b0702d31856afaeba1f724c0a951` |
| P2 host-dlopen | `hello-mauiapp-probe2-unsigned.hap` | 215384 | `5bdce033d00a561dc22dd4196a4f17aa2e5d6df025682adbe98c30836f6c1960` |
| P3 host-entry | `hello-mauiapp-probe3-unsigned.hap` | 222954 | `43557cfe9c274406ad8cc4985eadace9eb4a7f13d560af2e452491727a5e5b6c` |
| P4 per-dependency | `hello-mauiapp-probe4-unsigned.hap` | 223178 | `d24d26cd168ee34ea6c6352e80d25a556a096765b0f95d163203b8789e3f8d63` |

> **2026-09-22 rebuild — built with `compatibleSdkVersion 18` (abc `13.0.1.0`), safe on the
> older device now:** all four haps were rebuilt with the toolchain setting the kit now uses
> (`compatibleSdkVersion 18` + `useNormalizedOHMUrl=false`, mirrored from
> `ohos-workload/scripts/build-arkts-shell.sh`), so each hap's `ets/modules.abc` header (bytes
> 0x0c–0x0f) reads `13.0.1.0` instead of `24.0.0.0`. The abc-version branch (§4.0b) no longer
> applies to them, so they are **safe to run on the older API≤23/API 24 device**. Only
> `ets/modules.abc` changed in P1–P3; P4 additionally swapped its shim for the full-path
> dependency probe (§1). All four stay **unsigned**. The four assets were replaced in place
> (`gh release upload --clobber`); the other `device-test-kit` assets were not modified. A later
> same-day host refresh replaced P2–P4 again (see the note under the table).

P2, P3 and P4 embed the **current `preview.24` pack host** — a byte-identical copy of
`Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/hosts/arm64-v8a/libopenharmonyhost.so` after the
2026-09-22 refresh, sha256
`2bcc904988f8e0cc501b61e1e221add7ae5f3ffe51d9f84cb8a3ca6aca8d3433`, 187296 B — so their
`dlopen`/`dlsym` results reflect the host the `preview.24` pack now ships (it still exports
`ohos_host_register_pinch` and has 167 dynamic `T` symbols). The P3/P4 shims carry this sha as
their compile-time `expected_host_sha256=` pin; P2's shim has no pin. The earlier 2026-09-22
rebuild had embedded the FIX-A pinch-export host (`0c15a68a…3989`, 150432 B); the host refresh
replaced only the P2/P3/P4 assets in place (`gh release upload --clobber`) and left P1 and the
other `device-test-kit` assets untouched. The in-kit signed host
(`886cdbfb540ef8fe5d7610b0b435f824a6ac00628e541792c79b0991b851ab98`, 138144 B) is a **different**
build; the probes exercise the pack host, not the kit's signed one.

Download (uploaded to the existing `device-test-kit` tag; the four probe assets were replaced in
place on 2026-09-22 with the abc-`13.0.1.0` rebuild, no other asset touched):

```text
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe1-unsigned.hap
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe2-unsigned.hap
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe3-unsigned.hap
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe4-unsigned.hap
```

Local build trees (scratch, not committed): the abc-`13.0.1.0` rebuild lives in
`/data/storage/el2/base/tmp/opencode/pd1/` (`probe1`…`probe4` + `build-probe.sh`, `make-hap*.py`,
`verify-haps.py`, `shim/`); it was copied from `/data/storage/el2/base/tmp/opencode/pa/` (P1/P2),
`/data/storage/el2/base/tmp/opencode/rc/probe3/` (P3) and
`/data/storage/el2/base/tmp/opencode/rz/probe4/` (P4) — those originals were not modified.
All four haps are **unsigned**; bundle names are legal and identical in profile and `module.json`
(`com.example.hellomauiapp.probe1` / `com.example.hellomauiapp.probe2` /
`com.example.hellomauiapp.probe3` / `com.example.hellomauiapp.probe4`) — **no rename, no
`module.json` editing needed** before signing.

## 1. What each probe proves

### P1 "shell-only" (`com.example.hellomauiapp.probe1`)

- One `EntryAbility` + one page with a single `Text`; **no XComponent, no native import, no payload**.
- Built with the same toolchain the kit's ArkTS shell uses (hvigor 6.26.4 + local SDK 26.0.0.18),
  with the kit's 26-band `module.json` metadata (`minAPIVersion 50002014`, `apiReleaseType Release`,
  `compileSdkType HarmonyOS`, `compileSdkVersion 6.0.2.130`, `virtualMachine ark13.0.1.0`, `debug true`).
- Proves: **this device runs a plain ArkTS hap produced by THIS SDK/toolchain with our band metadata.**
- If P1 also dies with `JsError`, the problem is below our host code (device/firmware/SDK band/packaging)
  and the kit crash is *not* about the .NET host.

Expected P1 log chain:
`PROBE1 ABILITY_ON_CREATE` → `PROBE1 ABILITY_ON_WINDOW_STAGE_CREATE` → `PROBE1 LOAD_CONTENT_OK`
→ `PROBE1 PAGE_ABOUT_TO_APPEAR` → `PROBE1 PAGE_ON_SHOW` → `PROBE1 ABILITY_ON_FOREGROUND`.

### P2 "host-dlopen" (`com.example.hellomauiapp.probe2`)

- Same shell plus `import probe from 'libprobe.so'` and a call in `aboutToAppear`.
- `libprobe.so` is a tiny NAPI shim that calls `dlopen("<app libs dir>/libopenharmonyhost.so",
  RTLD_NOW|RTLD_GLOBAL)` (then by soname as fallback), and returns the result or the exact
  `dlerror()` text as a string; the page logs it through ArkTS `hilog`.
- The bundled `libopenharmonyhost.so` is **byte-identical to the current `preview.24` pack host**
  (`Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/hosts/arm64-v8a/`,
  sha256 `2bcc904988f8e0cc501b61e1e221add7ae5f3ffe51d9f84cb8a3ca6aca8d3433`, 187296 B; the
  2026-09-22 refresh, which still exports `ohos_host_register_pinch` and has 167 dynamic `T`
  symbols).
- Proves two things:
  1. the ArkTS → NAPI → app-libs loading path works on this device (`libprobe.so` itself loads
     through the normal `@normalized:Y&&&libprobe.so&` import form, same form the kit uses for
     `libopenharmonyhost.so`), and
  2. whether `libopenharmonyhost.so` maps (all `DT_NEEDED` resolved, relocations bound), or the
     precise linker error if it does not.
- Why this matters: the kit shell has a top-level `import host from 'libopenharmonyhost.so'`.
  If that `.so` cannot be mapped, the import is the *first* thing that can explode in the kit app,
  so P2's `dlerror` text is the prime root-cause candidate for the `JsError`.
- The host `.so` links against: `libace_napi.z.so`, `libace_ndk.z.so`, `libhilog_ndk.z.so`,
  `libnative_window.so`, `libnative_drawing.so`, `libimage_source.so`, `libpixelmap.so`,
  `libohvibrator.z.so`, `libnet_connection.so`, `libability_access_control.so`,
  `liblocation_ndk.so`, `libohsensor.so`, **`libc++_shared.so`**, `libc.so`.
  A missing library **file** in the app's linker namespace (notably `libc++_shared.so`, which the
  kit hap does **not** bundle) shows up verbatim in the `dlerror` text. A *missing dependency* of
  one of these libraries is a different story and can crash the whole process — see the P2/P3
  caveat and P4 below.

Expected P2 log chain adds, after `PROBE2 PAGE_ABOUT_TO_APPEAR`:

```text
PROBE2 HOST_DLOPEN_RESULT shim=<path>; hostpath=<path>; abs_NOW_OK; napi_module_register=0x…
or
PROBE2 HOST_DLOPEN_RESULT shim=<path>; hostpath=<path>; abs_NOW_FAIL=<dlerror text>; soname_NOW_FAIL=<dlerror text>
```

If the shim import itself fails, there will be no `PROBE2 PAGE_ABOUT_TO_APPEAR`; the
`PROBE2 LOAD_CONTENT_FAIL` line (with the ArkTS error JSON) is then the evidence.

### P3 "host-entry" (`com.example.hellomauiapp.probe3`)

- Same shell plus `import probe from 'libprobe3.so'`; the shim dlopens the same bundled
  `libopenharmonyhost.so` (byte-identical to the current `preview.24` pack host, sha256
  `2bcc9049…3433`, 187296 B) with `RTLD_NOW|RTLD_GLOBAL`, then goes one step further than P2.
- Only after `dlopen` returns a handle, the shim:
  (a) `dlsym`s six key exports and reports each address: `ohos_host_get_app_context`,
  `ohos_host_get_avoid_area`, `ohos_host_run_app`, `ohos_host_start_app`,
  `ohos_host_register_bridge`, `RegisterHostModule`;
  (b) calls the two **side-effect-free getters** only:
  `ohos_host_get_app_context()` (mutex-protected read of the stored context snapshot; returns
  `NULL` before any app started — it never touches hostfxr) and
  `ohos_host_get_avoid_area(&t,&b,&l,&r)` (copies four stored ints, returns 1).
  The launchers/registration entries in (a) are stateful, so they are resolved but **not called**.
  The other getter-shaped exports (`ohos_host_network_access`, `ohos_host_check_permission`, …)
  touch platform services, so they are deliberately left out of the call set.
- Proves: whether the host's exported entry points are resolvable and callable from the app's
  linker namespace. P2 can pass while P3 fails if the `.so` maps but an export cannot be resolved
  or a getter faults (host entry/dlsym mismatch — e.g. ABI/toolchain drift in the shipped host).
- The bundled host sha256 is pinned in the shim as `expected_host_sha256=` and echoed in the
  result line, so the tester's log also confirms which host binary the hap carried.

Expected P3 log chain adds, after `PROBE3 PAGE_ABOUT_TO_APPEAR`:

```text
PROBE3 HOST_ENTRY_RESULT shim=<path>; hostpath=<path>; expected_host_sha256=2bcc9049…3433; abs_NOW_OK; dlsym.ohos_host_get_app_context=0x…; dlsym.ohos_host_get_avoid_area=0x…; dlsym.ohos_host_run_app=0x…; dlsym.ohos_host_start_app=0x…; dlsym.ohos_host_register_bridge=0x…; dlsym.RegisterHostModule=0x…; call.get_app_context=NULL; call.get_avoid_area=rc=1[…,…,…,…]
```

Any `dlsym.<name>=NULL` or `call.<name>=SKIP(no symbol)` is the decisive P3 failure evidence; a
getter crash (no result line after `PROBE3 PAGE_ABOUT_TO_APPEAR`) points at the host export itself.

> **P2/P3 caveat — a missing dependency is not always a `dlerror`.** Both probes assume the loader
> returns an error string when the host cannot be mapped. The native rehearsal proved that this
> only holds for a missing **file**: when a `dlopen`ed library has a *missing dependency*, the
> OpenHarmony dynamic linker can SIGSEGV the whole process instead of returning `NULL`/`dlerror` —
> so P2/P3 may die with no result line at all and no usable evidence. P4 resolves every
> dependency individually first so the missing name is produced cleanly before any host load.

### P4 "per-dependency" (`com.example.hellomauiapp.probe4`)

- Same shell plus `import probe from 'libprobe4.so'`. The P4 shim does **not** dlopen the host
  first: it walks the host's 14 `DT_NEEDED` names one at a time with
  `dlopen(name, RTLD_NOW|RTLD_LOCAL)` and returns one result line per name, which the page hilogs
  under `PROBE4`:
  `PROBE4|<soname>|ok` or `PROBE4|<soname>|FAIL|<dlerror text>`.
- The 14 names checked: `libace_napi.z.so`, `libace_ndk.z.so`, `libhilog_ndk.z.so`,
  `libnative_window.so`, `libnative_drawing.so`, `libimage_source.so`, `libpixelmap.so`,
  `libohvibrator.z.so`, `libnet_connection.so`, `libability_access_control.so`,
  `liblocation_ndk.so`, `libohsensor.so`, `libc++_shared.so`, `libc.so`.
- **Why one-by-one:** a missing *file* returns a clean `cannot find library …` error (verified in
  the native rehearsal), so each name is probed as a plain file first; a missing *dependency* of
  one of those libraries would only crash the process if the host were loaded directly (the P2/P3
  trap). P4 therefore names the exact missing dependency before the host is touched.
- Only if all 14 succeed does the shim `dlopen` the bundled `libopenharmonyhost.so`
  (`RTLD_NOW|RTLD_GLOBAL`) and log the outcome plus the pinned host sha256 and the
  `napi_module_register` address. If any dependency failed, it skips the host entirely and logs
  `PROBE4|host|skipped`.
- Proves: the exact missing dependency (if any) — or that all 14 files resolve, which rules out the
  missing-file branch for P2/P3 — without depending on the host dlopen succeeding.
- New in the 2026-09-22 rebuild: when a name's plain `dlopen(name)` fails, the shim also tries the
  three system lib dirs by full path — `/system/lib64/<name>`, `/system/lib64/ndk/<name>`,
  `/system/lib64/platformsdk/<name>` — and logs one extra line per attempt, stopping at the first
  hit: `PROBE4|<name>|path|<dir>/<name>|ok` (found there) or
  `PROBE4|<name>|path|<dir>/<name>|FAIL|<dlerror text>`. This pins whether a failing dependency is
  really absent or just invisible to the app's plain soname lookup, and names the path when it
  exists.
- The shim itself is minimal (soname `libprobe4.so`, `NEEDED libc.so` only, it does not link the
  host), so P4 still runs when the host's dependencies are unavailable.

Expected P4 log lines (after `PROBE4 PAGE_ABOUT_TO_APPEAR`; one hilog line per result):

```text
PROBE4|libace_napi.z.so|ok
…                                    (one line per name; a bad one is e.g.
                                      PROBE4|libc++_shared.so|FAIL|cannot find library "libc++_shared.so")
PROBE4|deps|14/14
PROBE4|host|ok|hostpath=/data/…/libs/arm64-v8a/libopenharmonyhost.so; expected_host_sha256=2bcc9049…3433; napi_module_register=0x…
```

or, when a dependency fails (the three `|path|` lines follow only a failed name; a hit short-circuits
the remaining dirs):

```text
PROBE4|<name>|FAIL|<dlerror text>
PROBE4|<name>|path|/system/lib64/<name>|FAIL|<dlerror text>
PROBE4|<name>|path|/system/lib64/ndk/<name>|ok
PROBE4|deps|13/14
PROBE4|host|skipped
```

(`/system/lib64/ndk/<name>|ok` above means the file exists under `ndk` but the plain soname lookup
could not see it; if all three `|path|` lines FAIL, the file is absent from those dirs too.)

## 2. Install and start (tester)

Sign all four haps first with your existing debug flow (they are unsigned and need no profile
editing):

```sh
hdc install hello-mauiapp-probe1-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe1 -a EntryAbility

hdc install hello-mauiapp-probe2-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe2 -a EntryAbility

hdc install hello-mauiapp-probe3-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe3 -a EntryAbility

hdc install hello-mauiapp-probe4-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe4 -a EntryAbility
```

### 2.1 Device self-check (no app, no signing)

The same 14 dependency files P4 probes can be checked directly on the device before installing
anything — a missing line here predicts the matching `PROBE4|…|FAIL`:

```sh
D=60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19

hdc -t "$D" shell ls -l \
  /system/lib64/libace_napi.z.so /system/lib64/libace_ndk.z.so \
  /system/lib64/libhilog_ndk.z.so /system/lib64/libnative_window.so \
  /system/lib64/libnative_drawing.so /system/lib64/libimage_source.so \
  /system/lib64/libpixelmap.so /system/lib64/libohvibrator.z.so \
  /system/lib64/libnet_connection.so /system/lib64/libability_access_control.so \
  /system/lib64/liblocation_ndk.so /system/lib64/libohsensor.so \
  /system/lib64/libc++_shared.so /system/lib64/libc.so
```

`ls -l` printing a file means it exists at a system path; `ls: …: No such file or directory`
names a dependency that is not there (for `libc++_shared.so` that is common — the kit hap must
bundle it under `libs/arm64-v8a/`). This self-check reads `/system/lib64` only; P4 repeats the
same lookup from inside the app's linker namespace, so the two can differ when a library exists
but is not visible to the app.

## 3. Log capture and what to send back

```sh
D=60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19

hdc -t "$D" shell hilog -r
hdc -t "$D" shell hilog > probe-hilog.txt          # keep recording
# start each probe in another terminal, wait for the log chain to end, then Ctrl-C
grep -nE "PROBE1|PROBE2|PROBE3|PROBE4" probe-hilog.txt > probe-lines.txt
grep -inE "AppKilledReporter|JsError|jscrash|dlopen|Cannot|error" probe-hilog.txt >> probe-lines.txt
```

Send back:

1. `probe-lines.txt` — **all** `PROBE1` / `PROBE2` / `PROBE3` / `PROBE4` lines (do not truncate).
2. If a probe exits: the `AppKilledReporter` / `JsError` / jscrash lines and ±200 lines around the
   first of them (the same format as the kit diagnostics doc §2).
3. Which probe reached its full expected chain (per §1) and which did not.

Interpretation for the P2 result string:

- `abs_NOW_OK; napi_module_register=0x…` → the host `.so` mapped and exposes the NAPI entry point.
- `abs_NOW_FAIL=<text>` / `soname_NOW_FAIL=<text>` → the `<text>` **is** the linker's reason
  (e.g. `cannot find library "libc++_shared.so"`, `cannot locate symbol …`, bad ELF, namespace denial).
  Send it verbatim; it directly names the fix.
- No `PROBE2 PAGE_ABOUT_TO_APPEAR` but `PROBE2 LOAD_CONTENT_FAIL …` → the NAPI module load / page
  load failed; the error JSON is the evidence.

Interpretation for the P3 result string:

- `abs_NOW_OK` plus every `dlsym.<name>=0x…` and
  `call.get_app_context=NULL; call.get_avoid_area=rc=1[…]` → the host `.so` mapped, all key
  exports resolved and both harmless getters ran; the failure is above the host entry points
  (NAPI init / .NET runtime/main startup).
- `abs_NOW_OK` but any `dlsym.<name>=NULL` or `call.<name>=SKIP(no symbol)` → **host entry/dlsym
  mismatch**: the `.so` maps but the entry cannot be resolved from the app's linker namespace.
  Send the offending line verbatim (it names the missing/demangled export).
- No `PROBE3 HOST_ENTRY_RESULT` line after `PROBE3 PAGE_ABOUT_TO_APPEAR` → a getter call crashed
  the process (or the shim import itself failed, then `PROBE3 LOAD_CONTENT_FAIL` is the evidence);
  send the `AppKilledReporter`/jscrash window.

Interpretation for the P4 result string:

- `PROBE4|deps|14/14` then `PROBE4|host|ok|… napi_module_register=0x…` → every host dependency
  exists on the device and the host maps; the missing-file branch is ruled out for P2/P3.
- any `PROBE4|<name>|FAIL|<text>` (followed by `PROBE4|host|skipped`) → **`<name>` is the exact
  dependency the loader cannot find**; that is the one to package into `libs/arm64-v8a/` (or fix
  its producer). Send the FAIL line verbatim.
- `PROBE4|<name>|path|<dir>/<name>|ok` (printed after a failing name) → the file **does exist** at
  `<dir>`; the app's soname search path / linker namespace is the problem rather than a missing
  file — send the `ok` path. All three `|path|…|FAIL` lines instead → the file is missing from
  those system dirs too, so bundle it into `libs/arm64-v8a/` (or fix its provider).
- `PROBE4|deps|14/14` but `PROBE4|host|FAIL|<text>` → all dependency files exist, yet the linker
  still refuses the host (missing symbol, bad relocation, namespace denial); the `host|FAIL` text
  is the root cause.
- no `PROBE4|deps|` line at all (page dies right after `PROBE4 PAGE_ABOUT_TO_APPEAR`) → the shim
  itself or a per-name `dlopen` crashed the process; send the jscrash window together with the
  device self-check output (§2.1).

## 4. Decision table

### 4.0 Branch on the exit error first: the shell abc entry record

If the app exits ~1 s after `aa start` (`exit 254`) and hilog shows

```text
ReferenceError: Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point
```

then this is the **shell abc entry-record issue** (the abc's record name/index does not match
`module.json` `srcEntry`), already root-caused from the tester's E1–E5 experiments and the
`cc-switch` comparison — see `2026-09-22-ohos-startup-crash-rootcause.md`. It happens **before**
any host `.so` load, so the P1–P4 ladder below is **not** the tool for it (the P1 shell-only
probe builds its own abc and can still pass). Fixed in kit #10 (PA1: `useNormalizedOHMUrl=false`,
bundle-prefixed record, `ohos-workload c2c4a9a`/`6e55ae6`) — re-sign the rebuilt kit and retest;
kits before #10 carry this defect, so re-sign and wait for / retest the rebuilt kit instead of
running P1–P4. The P1–P4
ladder still applies to the other classes (dlopen / missing dependency / host entry / .NET
runtime). The install error `9568257 fail to verify pkcs7 file` is the expected self-signed
rejection — re-sign `hello-maui-app-unsigned.hap` (see `自签说明.md`) before judging startup.

### 4.0b Branch on the exit error first: the abc bytecode version

If the process still exits shortly after `aa start` (or the page dies while the shell imports the
host `.so` / starts) and hilog shows

```text
export objects of native so is undefined
```

or a `Cannot read property '…' of undefined` thrown from the shell's host import, then the shell
`ets/modules.abc` was produced for a newer ark runtime than the device accepts. The abc version is
the 4-byte field at offset 12..15 (`18 00 00 00` = 24.0.0.0, `0d 00 01 00` = 13.0.1.0); API ≤23
runtimes top out at **13.0.1.0**, API 24+ devices accept **24.0.0.0**. Fixed in kit #11: the shell
is built with `compatibleSdkVersion 18` on the SDK 26 toolchain, so the abc is `13.0.1.0`
(`ohos-workload 95c89a7`, archive `ef1c947`). Check the shipped abc and the device before running
P1–P4:

```sh
xxd -l 16 modules.abc                  # 0d 00 01 00 = 13.0.1.0; 18 00 00 00 = 24.0.0.0
hdc shell param get const.ark.version  # device runtime ceiling (24.0.0.0 on API 26; 13.0.1.0 on API ≤23)
```

Like the entry-record branch, this happens before any host `.so` load, so P1–P4 are not the tool
for it; the ladder still covers dlopen / missing dependency / host entry / .NET runtime crashes.
Full mapping and background: `2026-09-22-ohos-arkts-abc-version-history.md` §5.

### 4.0c Branch on the exit error first: the host `.so` did not load (`host` is undefined)

If the abc parses (`xxd -l16 modules.abc` = `0d 00 01 00`) and the shell's `[maui]` lines appear
(the kit #10/#11 pre-shell branches are cleared), but the app still exits — typically at the
page/render stage — with

```text
[maui] host export unavailable: <api> …
Error type:TypeError
Error message:Cannot read property registerXComponent of undefined
```

then the static `import host from 'libopenharmonyhost.so'` in the always-loaded ability/page
module produced an undefined module: the host `.so` failed to load, so every `host.<api>` is
undefined. The `hostCall` guards log each export once (`host export unavailable`); the first
unguarded call (`registerXComponent` in the XComponent `onLoad` before kit #12) is then the crash
site. The load-time surface is the host's `DT_NEEDED` list: the HAP loader resolves it when the
ability module imports the `.so`, which is **before** `EntryAbility.onCreate` extracts
`dotnet.zip` into the payload directory, so a payload-only dependency (notably `libhostfxr.so`,
which lives inside `dotnet.zip`) cannot be satisfied. Huawei's official guidance: every
`DT_NEEDED` must be inside the HAP or provided by the system, or the app crashes at startup
(`faqs-jsvm-9`); a failed recursive `DT_NEEDED` load crashes around NAPI module initialisation;
and an `import` in an always-loaded `.ets` triggers the `dlopen` at app start. "export objects of
native so is undefined" is the same failure from the ArkTS side.

Check every load-time dependency against both places it can live:

```sh
unzip -p hello-maui-app.hap libs/arm64-v8a/libopenharmonyhost.so > /tmp/host.so
readelf -d /tmp/host.so | grep NEEDED                   # the load-time surface
unzip -l hello-maui-app.hap | grep 'libs/arm64-v8a/'    # ① the hap's own lib dir
hdc shell ls -l /system/lib64/<name>                    # ② the device system libs (per NEEDED name)
hdc shell hilog | grep -iE "dlopen|not found|cannot find library|export objects of native so"
```

Anything named in `NEEDED` that is neither in the hap's `libs/<abi>/` nor on the device is the
load-time cause. The host must not link a payload library: hostfxr is resolved at `startApp` time
through the host's own `dlopen`/`dlsym` table, never as a `DT_NEEDED`. Fixed in kit #12
(`ohos-workload 7e71c39`, shell archive `2411a8e`): the host carries no `libhostfxr` link
dependency, `scripts/build-host.sh` audits `DT_NEEDED` with `readelf` and fails the build if
`libhostfxr` appears, and **every** `host.<api>` access in the shell templates is routed through
`hostCall` + `typeof host !== 'undefined'` (including `registerXComponent`), so a host that fails
to load degrades to one `host export unavailable` log per API instead of a `TypeError` + exit
254. Like §4.0/§4.0b, this is a pre/around-host-load branch: the P1–P4 ladder remains for the
other classes.

### 4.0d Branch on the exit error first: the host's napi registration name (exports empty, black screen)

If the app **starts and stays alive** (no `exit 254`, no `JsError`) but the screen is black, and hilog shows

```text
Load native module failed, ModuleName: @app:com.example.hellomauiapp/entry/openharmonyhost
```

together with `[maui] host export unavailable: <api>` for (nearly) every host API, while the XComponent
lines show the surface was created and mounted:

```text
AceXcomponent: XComponent[ohos_dotnet_surface] AttachToMainTree …
AceXcomponent: XComponent[ohos_dotnet_surface] triggers onLoad and OnSurfaceCreated callback
```

then the host `.so` loaded, but registered its NAPI module under a name the abc does not import. Under
`useNormalizedOHMUrl=false` (the entry-record fix) the shell's `import host from 'libopenharmonyhost.so'`
compiles to the record name `@app:<bundleName>/entry/openharmonyhost`, while `host_napi.cpp` registers
`nm_modname = "openharmonyhost"`; the loader looks up the record name, finds no matching registered
module (hilog shows the `Load native module failed` line and **no** successful-load line), so `Init`
never runs and every export is `undefined`. The XComponent surface is created and handed to
`onLoad`/`OnSurfaceCreated`, but `setNodeContent`/`registerXComponent` are unavailable, so the surface
is never handed to .NET/MAUI → black screen. The working reference (`cc-switch`, `useNormalizedOHMUrl=true`)
uses the normalized record `@normalized:Y&&&libentry.so&` with `nm_modname = "libentry.so"` — the names
match there and it renders. Huawei's NAPI/NDK FAQ states the import name and the registered module name
must match (module `entry` ↔ `libentry.so` ↔ `nm_modname = "entry"`).

Cross-check on the device / in the shipped kit:

```sh
hdc shell hilog | grep -E "Load native module failed|host export unavailable|AceXcomponent"
# the .so registration name and the abc record name must be the same string form
```

Unlike the shell branches, this one is fixed: RH1 (alias registrations covering both naming
conventions plus a normalized shell build that keeps the corrected bundle name, with the entry
record re-verified) shipped in kit #16 and the RM1 `libIsolation` repack in kit #17 — both are in
the current kit (#24, payload-in-libs) and are **kept as harmless hardening**: the 2026-09-24 device run showed the
black-screen chain was the host dlopen + bootstrap issues, not this name/path half (see
`2026-09-24-ohos-device-milestone.md` §2). The diagnostic is part of `tester-run.sh` v8 (`hilog-applib` /
`hilog-dlopen` / `hilog-bootstrap` / `app-libs-arm64.txt` / `payload-*`). Like §4.0/§4.0b/§4.0c this is not a P1–P4 case (the
ladder still covers dlopen / missing dependency / host entry / .NET runtime crashes).

P4 is the authoritative row for missing dependencies: `PROBE4|<name>|FAIL|<dlerror>` names the
exact missing library, and a P2/P3 that dies without any result line is consistent with a missing
dependency (the loader SIGSEGVs the process instead of reporting a `dlerror`).

| P1 (shell-only) | P2 (host-dlopen) | P3 (host-entry) | P4 (per-dependency) | Conclusion | Next action |
|---|---|---|---|---|---|
| n/a — pre-shell (abc version) | n/a | n/a | n/a | Process exits, hilog shows `export objects of native so is undefined` / `Cannot read property … of undefined` — **abc bytecode version mismatch** (shell abc 24.0.0.0 vs the device's 13.0.1.0 ceiling) | Use a kit from #11 on (shell abc `13.0.1.0`, `compatibleSdkVersion 18`) and re-sign it; compare `xxd -l16 modules.abc` with `hdc shell param get const.ark.version` (§4.0b) |
| n/a — post-shell (`[maui]` logs, page/render) | n/a | n/a | n/a | `host` is undefined (`[maui] host export unavailable: <api>`; `Cannot read property registerXComponent of undefined` + exit 254) — **the host `.so` failed to load** (load-time `DT_NEEDED` resolution happens at ability import, before `dotnet.zip` is extracted) | Re-sign a kit from #12 on; compare `readelf -d libopenharmonyhost.so \| grep NEEDED` against the hap's `libs/<abi>/` and `hdc shell ls -l /system/lib64/<name>` (§4.0c) |
| n/a — post-shell (abc ok, `[maui]` logs; app **stays alive**, black screen) | n/a | n/a | n/a | App starts and stays alive (no `TypeError`/`JsError`/exit 254), `AceXcomponent` shows the XComponent created/mounted, but the screen is black and hilog shows `Load native module failed, ModuleName: @app:<bundle>/entry/openharmonyhost` plus every `[maui] host export unavailable: <api>` — **the host's napi registration name (`nm_modname`) does not match the abc import record name** under `useNormalizedOHMUrl=false`; the host exports are empty, so `setNodeContent`/`registerXComponent` never hand the surface to .NET | Fixed — RH1 (alias registrations covering both conventions, entry record kept) shipped in kit #16 and the RM1 `libIsolation` repack in kit #17; both are in the current kit (#24) as **harmless hardening** (2026-09-24 device evidence: the observed blocker chain was host dlopen + bootstrap — see `2026-09-24-ohos-device-milestone.md` §2). Verify with the §4.0d logs (`Load native module failed` vs the alias line `[openharmony-host] … bound via alias '…'`) and the `cc-switch` reference (`@normalized:Y&&&libentry.so&` ↔ `nm_modname = "libentry.so"`) |
| fails (`JsError`, no/failed `PROBE1` chain) | n/a | n/a | n/a | Device/framework issue — plain ArkTS haps built by this toolchain do not run | Re-sign/reinstall, compare with a DevEco Empty Ability build in the same band; kit crash is not host-specific |
| ok | fails (`…_FAIL=<dlerror>`) | n/a | n/a | Host `.so` dlopen fails — missing library file / unresolved relocation / namespace or signature problem (the `dlerror` text is the root cause) | Fix native packaging per the error (e.g. bundle `libc++_shared.so` / missing system lib / namespace), then rerun P2 |
| ok | ok (`abs_NOW_OK`) | fails (`dlsym.…=NULL`, `call.…=SKIP`, or no `PROBE3 HOST_ENTRY_RESULT` line) | n/a | Host entry/dlsym mismatch — the `.so` maps but a key export is not resolvable/usable from the app linker namespace | Send the P3 line verbatim (missing/demangled export name); compare the shipped host's symbol table with the kit's expected imports |
| ok | ok | ok (`abs_NOW_OK` + all dlsyms `0x…` + both getter calls) | ok (`deps\|14/14` + `host\|ok`) | Everything below the managed runtime works; the kit crash happens in .NET runtime/main startup | Continue with the kit's `dotnet-status.txt` + hilog evidence; host dlopen and entry points are ruled out |
| n/a — post-host (abc ok; host loaded or not) | n/a | n/a | n/a | `runtime/coreclr` `dlopen` fails with **fs-verity / XPM (codesigning)** errors (`unsigned file`, `is not protected by dmverity`, `lib_no_signed event waken: -9(E_HM_PERM)`, path = the extracted payload natives) — the payload natives were extracted at runtime from `dotnet.zip` and are **not covered by the HAP code signature** | Fixed by staging the runtime natives into `libs/<abi>/` (**PF1**), shipped since kit #22 (stages all 12 runtime natives + the host there); confirm with the kmsg probe in `2026-09-22-ohos-elf-signing-research.md` (Tester checklist / §6) and re-sign with `-signCode 1` |
| ok | dies with **no result line** (or a `dlopen` crash right after `PROBE2 PAGE_ABOUT_TO_APPEAR`) | dies / n/a | `<name>\|FAIL\|<dlerror>` + `deps\|<n>/14` + `host\|skipped` | A dependency of the host is missing; the loader crashed the host dlopen instead of returning a `dlerror`. P4 names the dependency | Package `<name>` into `libs/arm64-v8a/` (for `libc++_shared.so`) or fix its provider, then rerun P4 → P2/P3 |
| ok | n/a (not reached) | n/a | `deps\|<n>/14` with **several** `FAIL` lines, no `host` line | More than one dependency is missing (or one library drags the rest) | Fix every `PROBE4\|<name>\|FAIL` name, then rerun P4; the host is deliberately not loaded |
| ok | partial (EntryAbility chain ok, no page lines, `LOAD_CONTENT_FAIL`/`JsError`) | n/a | n/a | ArkTS NAPI/page-load path is the failure point, not the host binary | Send the `LOAD_CONTENT_FAIL` JSON and jscrash lines |

## 5. Build provenance (for reproduction)

- Toolchain: local OpenHarmony SDK 26.0.0.18 (`platformVersion 26.0.0`, `apiVersion 26`),
  hvigor 6.26.4 + `@ohos/hvigor-ohos-plugin` from `https://repo.harmonyos.com/npm`, node 26.8.1,
  openjdk@17 — the same environment used by `ohos-workload/scripts/build-arkts-shell.sh`
  (that script lives in the `ohos-workload` repo, not `runtime-ohos`).
- `arkCompile`: hvigor `entry:default@CompileArkTS` produced `ets/modules.abc`
  (P1 `11cbbf5dc88c811497b676b829336d44cef7b79956425a057b6dd4e8df76cdbd`, 9068 B;
  P2 `e50586941523be26d988a34cd2e073a17059952bc3a7b6764b3a9f2bed9fd588`, 9524 B;
  P3 `76d532f7b0ec34660bae5af3e90f75fe9f7e0e6e327f6ca4d2c5a1f09ad759b3`, 9532 B;
  P4 `b0de61628f6c822f109dbad57581c849322527c16eec5147df3818d1444639aa`, 9756 B) —
  the rebuilt header bytes 0x0c–0x0f read `0d 00 01 00` = `13.0.1.0`. The generated project
  mirrors `build-arkts-shell.sh` (`compatibleSdkVersion '18'` → es2abc
  `--target-api-version=18`, and `useNormalizedOHMUrl: false`, so the abc entry records are
  bundle-prefixed: `com.example.hellomauiapp.probeN/entry/ets/entryability/EntryAbility`).
- hvigor's `PackageHap` step fails on this machine with the known missing
  `toolchains/lib/app_packing_tool.jar` (SDK packaging jar absent), so all four haps were assembled
  manually with `python3 -m zipfile`-style code in the same layout as
  `device-test-kit/hello-maui-app-unsigned.hap` (all members **stored uncompressed**):
  `module.json`, `ets/modules.abc`, `resources/base/element/*.json`, `resources/base/media/app_icon.png`,
  `resources/base/profile/main_pages.json`, plus for P2 `libs/arm64-v8a/libprobe.so`
  (sha256 `1ca5ab3189046ba66ef25ca2e5cd198153a29d3b8173a345c4de20f93e6259f2`, 15352 B), for P3
  `libs/arm64-v8a/libprobe3.so` (sha256
  `b4503e1cd1fb8258faabb575cca825f4b3816322ecdc35c9429ffa6e95aa7652`, 22912 B; rebuilt
  2026-09-22 from `shim/probe3_shim.c` with the SDK clang + lld 23.1.1, `NEEDED libc.so` only,
  re-pinned to the `preview.24` host) and for P4
  `libs/arm64-v8a/libprobe4.so` (sha256
  `3ae26c9562b86c6c037f1e7df81cf1d898867d0e353a6fa7ea2864da64d991b9`, 22912 B; rebuilt
  2026-09-22 from `shim/probe4_shim.c` incl. the per-name full-path probe, with the harmonybrew
  clang 23.1.1 + lld 23.1.1 against the SDK sysroot
  (`--target=aarch64-linux-ohos --sysroot=<SDK>/native/sysroot -shared -fPIC --ld-path=<lld>
  -Wl,-soname,libprobe4.so`); `NEEDED libc.so` only — on this host the SDK-bundled clang-15 still
  cannot run its own `lld` (libxml2 load error)), plus the host `.so` (the P2/P3/P4 copies all
  carry the current `preview.24` pack host, sha256 `2bcc9049…3433`, 187296 B, pinned in the P3/P4
  shims; see the §0 note).
- The `module.json` band values are authored (not hvigor-generated) because the local SDK reports
  `26.0.0.18 / Beta` while the kit ships the HarmonyOS 26 band; the hap metadata matches the kit's
  26-band exactly.

## 6. 给测试方的速用版（中文）

0. **先分类**：安装报 `9568257`（自签名被拒）属预期 —— 先按 `自签说明.md` 重签 `hello-maui-app-unsigned.hap` 再装。安装成功后启动即退：
   - hilog 报 `ReferenceError: Cannot find module 'ets/entryability/EntryAbility' , which is application Entry Point` → 壳 abc 入口 record 缺陷（**kit #10 已修复**，测试方真机已确认；旧 kit 请换新 kit）；
   - hilog 报 `export objects of native so is undefined` / `Cannot read property … of undefined` → abc 字节码版本不符（**kit #11 已修复**：`13.0.1.0`；用 `xxd -l16 modules.abc` 与 `hdc shell param get const.ark.version` 对照）；
   - hilog 有 `[maui]` 日志、但出现 `[maui] host export unavailable: <api>` 或 `Cannot read property registerXComponent of undefined` → 宿主 `.so` 加载失败（壳 `host` 为 undefined；**kit #12 已修复**：宿主无 `libhostfxr` 链接依赖 + 壳全量守卫）；按 §4.0c 用 `readelf -d … | grep NEEDED` 对照 hap `libs/arm64-v8a/` 与设备系统库。
   - 应用能启动并**稳定存活、但黑屏**（无崩溃日志），hilog 出现 `Load native module failed, ModuleName: @app:…` 与大量 `[maui] host export unavailable` → napi 注册名与 abc import 记录名不匹配、host exports 为空（kit #16 别名 + kit #17 `libIsolation` 保留为**无害加固**；2026-09-24 设备证据表明黑屏直接链是宿主加载与 bootstrap，**kit #22 已回灌**，见 `2026-09-24-ohos-device-milestone.md` §2）；按 §4.0d 复核（`[openharmony-host] … bound via alias '…'` 出现即加载绑定成功）。
   以上四类都发生在宿主加载前/后、**先不要跑 P1–P4**（见 `docs/plans/2026-09-22-ohos-startup-crash-rootcause.md` §5b/§5c/§5d/§5e 与本文 §4.0/§4.0b/§4.0c/§4.0d）；其他退出原因才走下面 1–6（P1–P4 仍适用于 dlopen/缺库/宿主入口/.NET 运行时类）。
0b. **当前 kit（#24，payload-in-libs 正式版；#23 为同 #22 负载的工具刷新）**已含上述全部修复与启动修复（P17 解压跳过、H7 rawfile fd 直读、headless abc `13.0.1.0`），并含设备里程碑回灌（宿主 `DT_NEEDED` 5 + 可选 API 按需 dlsym、HAP `resources.index`、ZIP offset/length + mkdir、DevEco 工程布局）与 payload-in-libs（payload 随签名 `libs/arm64-v8a/` 原地运行 + `.dotnet-payload.json`）；`tester-run.sh` v8 会自动采集 app-lib 证据与别名注册行（`hilog-applib`/`hilog-dlopen`/`app-libs-arm64`）、`hilog-bootstrap`（bootstrap/rawfile 失败特征）、`payload-files`/`payload-marker`、`meta/kit-selfcheck`（`kit_index_ok`/`payload=yes|no`）与 exec-memory（`hilog-execmem.txt`），首帧判定一并写进 `summary.txt`。数字入口 = release「## Integrity」；里程碑见 `2026-09-24-ohos-device-milestone.md`。
1. 用你的自签流程签这四个 hap（bundleName 已合法，**不用改名**，不用改 module.json）。
2. `hdc install …probe1-unsigned.hap` → `hdc shell aa start -b com.example.hellomauiapp.probe1 -a EntryAbility`；probe2 / probe3 / probe4 同理把后缀换成 `probe2` / `probe3` / `probe4`。
3. 抓 hilog，回传所有含 `PROBE1` / `PROBE2` / `PROBE3` / `PROBE4` 的行；若退出，再附 `AppKilledReporter`/`JsError` 前后各 200 行。
4. 免安装自检：`hdc shell ls -l /system/lib64/<14 个库名>`（见 §2.1）；缺哪个文件，P4 就会报对应 `FAIL`。
5. P4 逐库自检：看 `PROBE4|deps|N/14`；任一行 `PROBE4|<库名>|FAIL|<dlerror>` → 该库名就是设备上缺的依赖，先补进 `libs/arm64-v8a/`（如 `libc++_shared.so`）再重跑。每个 FAIL 的库名后还会跟最多 3 条全路径探测行 `PROBE4|<库名>|path|/system/lib64[/ndk|/platformsdk]/<库名>|ok|FAIL|…`：任一条为 `ok` 说明文件其实在设备上该路径下（只是 soname 搜索不到），回传该 `ok` 路径即可；3 条全 `FAIL` 才是真的缺文件。P2/P3 若“没有结果行直接崩”，正符合“缺依赖时加载器 SIGSEGV”的现象 —— 由 P4 给出库名。
6. 结论对照：P1 失败 → 设备/框架侧问题；P4 报缺库 → 按库名补包（P1/P2/P3 的正常/崩溃以 P4 为准）；P1/P2/P3/P4 全过 → 崩溃在 .NET 运行时/主启动（宿主 dlopen 与入口均已被排除）。
