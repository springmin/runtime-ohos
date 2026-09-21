# OpenHarmony startup-crash probes P1/P2 (JsError / exit 254)

> Companion to `2026-09-21-ohos-device-crash-diagnostics.md`. The tester's device
> (OpenHarmony 7.0.0.105 / API 26 / 2in1, UDID `60CF7B27…F8A19`) installs the kit hap but the app
> exits ~1 s after `aa start` (`exit 254`, `AppKilledReporter` `reason=JsError`).
> These two minimal, standalone probes bisect the failure between three layers:
> **ArkTS shell/device SDK** (P1), **host .so dlopen** (P2), **.NET runtime/main startup** (neither fails).

## 0. Artifacts (unsigned — sign with the tester's own flow)

| probe | asset | size (bytes) | sha256 |
|---|---|---|---|
| P1 shell-only | `hello-mauiapp-probe1-unsigned.hap` | 11988 | `92ef933cf7e0eadce1b415f67362dbba0f533dfff8cbbde89ee0eb6c4dcbeac4` |
| P2 host-dlopen | `hello-mauiapp-probe2-unsigned.hap` | 178492 | `2ec1bf3f3db15bb04a538387c0f2385e3af37be3858d66dbdbc22abb5e2151ec` |

Download (uploaded to the existing `device-test-kit` tag; the two pre-existing assets were not modified):

```text
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe1-unsigned.hap
https://github.com/springmin/sdk-ohos/releases/download/device-test-kit/hello-mauiapp-probe2-unsigned.hap
```

Local build tree (scratch, not committed): `/data/storage/el2/base/tmp/opencode/pa/`.
Both haps are **unsigned**; bundle names are legal and identical in profile and `module.json`
(`com.example.hellomauiapp.probe1` / `com.example.hellomauiapp.probe2`) — **no rename, no
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
- The bundled `libopenharmonyhost.so` is **byte-identical to the kit's**
  (sha256 `5a8fd6b6630c06ca17b8e97870ff180ff43b778c0a0df6100e0062bd021af96d`).
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

## 2. Install and start (tester)

Sign both haps first with your existing debug flow (they are unsigned and need no profile editing):

```sh
hdc install hello-mauiapp-probe1-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe1 -a EntryAbility

hdc install hello-mauiapp-probe2-unsigned.hap
hdc shell aa start -b com.example.hellomauiapp.probe2 -a EntryAbility
```

## 3. Log capture and what to send back

```sh
D=60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19

hdc -t "$D" shell hilog -r
hdc -t "$D" shell hilog > probe-hilog.txt          # keep recording
# start each probe in another terminal, wait for the log chain to end, then Ctrl-C
grep -nE "PROBE1|PROBE2" probe-hilog.txt > probe-lines.txt
grep -inE "AppKilledReporter|JsError|jscrash|dlopen|Cannot|error" probe-hilog.txt >> probe-lines.txt
```

Send back:

1. `probe-lines.txt` — **all** `PROBE1` / `PROBE2` lines (do not truncate).
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

## 4. Decision table

| P1 (shell-only) | P2 (host-dlopen) | Conclusion | Next action |
|---|---|---|---|
| fails (`JsError`, no/failed `PROBE1` chain) | n/a | Device/firmware/SDK-band issue — plain ArkTS haps built by this toolchain do not run | Re-sign/reinstall, compare with a DevEco Empty Ability build in the same band; kit crash is not host-specific |
| ok | fails (`…_FAIL=<dlerror>`) | `libopenharmonyhost.so` cannot be mapped on this device; the `dlerror` text is the root cause | Fix native packaging per the error (e.g. bundle `libc++_shared.so` / missing system lib / namespace); then rerun P2 |
| ok | ok (`abs_NOW_OK`) | Host `.so` loads fine; the kit crash happens after the host is mapped — NAPI init or .NET runtime/main startup | Continue with the kit's `dotnet-status.txt` + hilog evidence; the loader is ruled out |
| ok | partial (EntryAbility chain ok, no page lines, `LOAD_CONTENT_FAIL`/`JsError`) | ArkTS NAPI/page-load path is the failure point, not the host binary | Send the `LOAD_CONTENT_FAIL` JSON and jscrash lines |

## 5. Build provenance (for reproduction)

- Toolchain: local OpenHarmony SDK 26.0.0.18 (`platformVersion 26.0.0`, `apiVersion 26`),
  hvigor 6.26.4 + `@ohos/hvigor-ohos-plugin` from `https://repo.harmonyos.com/npm`, node 26.8.1,
  openjdk@17 — the same environment used by `ohos-workload/scripts/build-arkts-shell.sh`
  (that script lives in the `ohos-workload` repo, not `runtime-ohos`).
- `arkCompile`: hvigor `entry:default@CompileArkTS` produced `ets/modules.abc`
  (P1 `2536eb34253231643b52ed851aa0e7182ee9d2f2b6af9538cd074c7c845940c1`, 9052 B;
  P2 `253ba65b573eef80995ef2016a4385f180cdea72ccb68fabcebb0790a63b2ab5`, 9496 B).
- hvigor's `PackageHap` step fails on this machine with the known missing
  `toolchains/lib/app_packing_tool.jar` (SDK packaging jar absent), so both haps were assembled
  manually with `python3 -m zipfile`-style code in the same layout as
  `device-test-kit/hello-maui-app-unsigned.hap` (all members **stored uncompressed**):
  `module.json`, `ets/modules.abc`, `resources/base/element/*.json`, `resources/base/media/app_icon.png`,
  `resources/base/profile/main_pages.json`, and for P2 only `libs/arm64-v8a/libprobe.so`
  (sha256 `1ca5ab3189046ba66ef25ca2e5cd198153a29d3b8173a345c4de20f93e6259f2`, 15352 B) plus the host `.so`.
- The `module.json` band values are authored (not hvigor-generated) because the local SDK reports
  `26.0.0.18 / Beta` while the kit ships the HarmonyOS 26 band; the hap metadata matches the kit's
  26-band exactly.

## 6. 给测试方的速用版（中文）

1. 用你的自签流程签这两个 hap（bundleName 已合法，**不用改名**，不用改 module.json）。
2. `hdc install …probe1-unsigned.hap` → `hdc shell aa start -b com.example.hellomauiapp.probe1 -a EntryAbility`；probe2 同理把后缀换成 `probe2`。
3. 抓 hilog，回传所有含 `PROBE1` / `PROBE2` 的行；若退出，再附 `AppKilledReporter`/`JsError` 前后各 200 行。
4. 结论对照：P1 失败 → 设备/SDK 侧问题；P1 正常、P2 失败 → 宿主 `.so` 加载失败（`dlerror` 原文即根因）；两个都正常 → 崩溃在 .NET 运行时/主启动（宿主加载已被排除）。
