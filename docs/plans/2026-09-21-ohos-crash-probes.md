# OpenHarmony startup-crash probes P1/P2/P3 (JsError / exit 254)

> Companion to `2026-09-21-ohos-device-crash-diagnostics.md`. The tester's device
> (OpenHarmony 7.0.0.105 / API 26 / 2in1, UDID `60CF7B27…F8A19`) installs the kit hap but the app
> exits ~1 s after `aa start` (`exit 254`, `AppKilledReporter` `reason=JsError`).
> These three minimal, standalone probes bisect the failure between four layers:
> **ArkTS shell/device SDK** (P1), **host .so dlopen** (P2), **host entry points / dlsym** (P3),
> **.NET runtime/main startup** (only reached when all three probes pass).

## 0. Artifacts (unsigned — sign with the tester's own flow)

| probe | asset | size (bytes) | sha256 |
|---|---|---|---|
| P1 shell-only | `hello-mauiapp-probe1-unsigned.hap` | 11988 | `92ef933cf7e0eadce1b415f67362dbba0f533dfff8cbbde89ee0eb6c4dcbeac4` |
| P2 host-dlopen | `hello-mauiapp-probe2-unsigned.hap` | 178492 | `70bbc687ba1f131185d72eae6b7dfaddf934d8a296726c792385b901eac9d7b0` |
| P3 host-entry | `hello-mauiapp-probe3-unsigned.hap` | 186002 | `5727e00f11c960b060628441b6119702027aa38414d25ddb0e7a4ea823486f3a` |

P2 and P3 embed the **current kit host** `libopenharmonyhost.so` (the FIX-A pinch-export build,
`Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/hosts/arm64-v8a/`,
sha256 `0c15a68ad46ca099d2ed510b9b3372565c7f0707641d1bfb63d26c1504dc3989`, 150432 B; byte-identical
to the pack copy in both haps), so their `dlopen`/`dlsym` results reflect the shipped artifact
rather than the earlier pre-pinch host.

Download (uploaded to the existing `device-test-kit` tag; P3 is a new asset name and none of the
pre-existing assets were modified):

```text
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe1-unsigned.hap
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe2-unsigned.hap
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe3-unsigned.hap
```

Local build trees (scratch, not committed): `/data/storage/el2/base/tmp/opencode/pa/` (P1/P2) and
`/data/storage/el2/base/tmp/opencode/rc/probe3/` (P3, copied from the `qb/` probe tree; the `qb/`
originals were not modified).
All three haps are **unsigned**; bundle names are legal and identical in profile and `module.json`
(`com.example.hellomauiapp.probe1` / `com.example.hellomauiapp.probe2` /
`com.example.hellomauiapp.probe3`) — **no rename, no `module.json` editing needed** before signing.

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
- The bundled `libopenharmonyhost.so` is **byte-identical to the current kit host**
  (`Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/hosts/arm64-v8a/`,
  sha256 `0c15a68ad46ca099d2ed510b9b3372565c7f0707641d1bfb63d26c1504dc3989`, 150432 B; the FIX-A
  build which exports `ohos_host_register_pinch` and has 120 dynamic `T` symbols).
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
  A missing library in the app's linker namespace (notably `libc++_shared.so`, which the kit hap
  does **not** bundle) shows up verbatim in the `dlerror` text.

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
  `libopenharmonyhost.so` (byte-identical to the current kit host, sha256
  `0c15a68a…3989`, 150432 B) with `RTLD_NOW|RTLD_GLOBAL`, then goes one step further than P2.
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
PROBE3 HOST_ENTRY_RESULT shim=<path>; hostpath=<path>; expected_host_sha256=0c15a68a…3989; abs_NOW_OK; dlsym.ohos_host_get_app_context=0x…; dlsym.ohos_host_get_avoid_area=0x…; dlsym.ohos_host_run_app=0x…; dlsym.ohos_host_start_app=0x…; dlsym.ohos_host_register_bridge=0x…; dlsym.RegisterHostModule=0x…; call.get_app_context=NULL; call.get_avoid_area=rc=1[…,…,…,…]
```

Any `dlsym.<name>=NULL` or `call.<name>=SKIP(no symbol)` is the decisive P3 failure evidence; a
getter crash (no result line after `PROBE3 PAGE_ABOUT_TO_APPEAR`) points at the host export itself.

## 2. Install and start (tester)

Sign all three haps first with your existing debug flow (they are unsigned and need no profile
editing):

```sh
hdc install hello-mauiapp-probe1-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe1 -a EntryAbility

hdc install hello-mauiapp-probe2-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe2 -a EntryAbility

hdc install hello-mauiapp-probe3-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe3 -a EntryAbility
```

## 3. Log capture and what to send back

```sh
D=60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19

hdc -t "$D" shell hilog -r
hdc -t "$D" shell hilog > probe-hilog.txt          # keep recording
# start each probe in another terminal, wait for the log chain to end, then Ctrl-C
grep -nE "PROBE1|PROBE2|PROBE3" probe-hilog.txt > probe-lines.txt
grep -inE "AppKilledReporter|JsError|jscrash|dlopen|Cannot|error" probe-hilog.txt >> probe-lines.txt
```

Send back:

1. `probe-lines.txt` — **all** `PROBE1` / `PROBE2` / `PROBE3` lines (do not truncate).
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

## 4. Decision table

| P1 (shell-only) | P2 (host-dlopen) | P3 (host-entry) | Conclusion | Next action |
|---|---|---|---|---|
| fails (`JsError`, no/failed `PROBE1` chain) | n/a | n/a | Device/framework issue — plain ArkTS haps built by this toolchain do not run | Re-sign/reinstall, compare with a DevEco Empty Ability build in the same band; kit crash is not host-specific |
| ok | fails (`…_FAIL=<dlerror>`) | n/a | Host `.so` dlopen fails — missing library / unresolved relocation / namespace or signature problem (the `dlerror` text is the root cause) | Fix native packaging per the error (e.g. bundle `libc++_shared.so` / missing system lib / namespace), then rerun P2 |
| ok | ok (`abs_NOW_OK`) | fails (`dlsym.…=NULL`, `call.…=SKIP`, or no `PROBE3 HOST_ENTRY_RESULT` line) | Host entry/dlsym mismatch — the `.so` maps but a key export is not resolvable/usable from the app linker namespace | Send the P3 line verbatim (missing/demangled export name); compare the shipped host's symbol table with the kit's expected imports |
| ok | ok | ok (`abs_NOW_OK` + all dlsyms `0x…` + both getter calls) | Everything below the managed runtime works; the kit crash happens in .NET runtime/main startup | Continue with the kit's `dotnet-status.txt` + hilog evidence; host dlopen and entry points are ruled out |
| ok | partial (EntryAbility chain ok, no page lines, `LOAD_CONTENT_FAIL`/`JsError`) | n/a | ArkTS NAPI/page-load path is the failure point, not the host binary | Send the `LOAD_CONTENT_FAIL` JSON and jscrash lines |

## 5. Build provenance (for reproduction)

- Toolchain: local OpenHarmony SDK 26.0.0.18 (`platformVersion 26.0.0`, `apiVersion 26`),
  hvigor 6.26.4 + `@ohos/hvigor-ohos-plugin` from `https://repo.harmonyos.com/npm`, node 26.8.1,
  openjdk@17 — the same environment used by `ohos-workload/scripts/build-arkts-shell.sh`
  (that script lives in the `ohos-workload` repo, not `runtime-ohos`).
- `arkCompile`: hvigor `entry:default@CompileArkTS` produced `ets/modules.abc`
  (P1 `2536eb34253231643b52ed851aa0e7182ee9d2f2b6af9538cd074c7c845940c1`, 9052 B;
  P2 `253ba65b573eef80995ef2016a4385f180cdea72ccb68fabcebb0790a63b2ab5`, 9496 B;
  P3 `3ed7a5a7e2d045f097f520b8eb6fd0275c13e00b457071ebe09c90a44382c643`, 9508 B).
- hvigor's `PackageHap` step fails on this machine with the known missing
  `toolchains/lib/app_packing_tool.jar` (SDK packaging jar absent), so all three haps were assembled
  manually with `python3 -m zipfile`-style code in the same layout as
  `device-test-kit/hello-maui-app-unsigned.hap` (all members **stored uncompressed**):
  `module.json`, `ets/modules.abc`, `resources/base/element/*.json`, `resources/base/media/app_icon.png`,
  `resources/base/profile/main_pages.json`, plus for P2 `libs/arm64-v8a/libprobe.so`
  (sha256 `1ca5ab3189046ba66ef25ca2e5cd198153a29d3b8173a345c4de20f93e6259f2`, 15352 B) and for P3
  `libs/arm64-v8a/libprobe3.so` (sha256
  `3fbf5f9a5b46d84a8acec4e8a86ec62ba131ca8f878c19bae2460afb3874267e`, 22848 B; built from
  `shim/probe3_shim.c` with the SDK clang, `NEEDED libc.so` only), plus the host `.so` (the P2/P3
  copies are byte-identical to the pack copy, sha256 `0c15a68a…3989`).
- The `module.json` band values are authored (not hvigor-generated) because the local SDK reports
  `26.0.0.18 / Beta` while the kit ships the HarmonyOS 26 band; the hap metadata matches the kit's
  26-band exactly.

## 6. 给测试方的速用版（中文）

1. 用你的自签流程签这三个 hap（bundleName 已合法，**不用改名**，不用改 module.json）。
2. `hdc install …probe1-unsigned.hap` → `hdc shell aa start -b com.example.hellomauiapp.probe1 -a EntryAbility`；probe2 / probe3 同理把后缀换成 `probe2` / `probe3`。
3. 抓 hilog，回传所有含 `PROBE1` / `PROBE2` / `PROBE3` 的行；若退出，再附 `AppKilledReporter`/`JsError` 前后各 200 行。
4. 结论对照：P1 失败 → 设备/框架侧问题；P1 正常、P2 失败 → 宿主 `.so` dlopen 失败（缺库/签名，`dlerror` 原文即根因）；P2 正常、P3 失败 → 宿主导出入口/dlsym 不匹配；三个全过 → 崩溃在 .NET 运行时/主启动（宿主 dlopen 与入口均已被排除）。
