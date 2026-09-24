# NAPI import-form fix playbook (black-screen blocker #4)

**Date:** 2026-09-23
**Status:** ready-to-apply; **the import form itself is pending the device runs** of the running experiments
**Repos:** runtime-ohos (this doc) + ohos-workload (the change it lands in)
**Related:** `2026-09-23-ohos-native-import-experiment.md` (probe artifacts),
`2026-09-22-ohos-startup-crash-rootcause.md` §5d/§5e (kit #14 milestone + blocker #4)

**Legend:** ✅ confirmed (local evidence, or already landed) · ⏳ pending (device result or
in-flight research). Keep this doc hash-free; sizes/versions only.

> **2026-09-24 device-evidence correction (important):** the device now runs end-to-end with
> kit #18 + five local fixes; the successful log shows the host so serving its exports and the
> black-screen chain was the host `.so` dlopen on the reduced image + the bootstrap fixes
> (`resources.index` / ZIP offset / mkdir) + the hvigor abc build — **not** this playbook's
> record/registration-name route. Candidates A/B/C were not used on device; RH1/RM1 stay as
> harmless hardening. Back-port (kit #22) and evidence: `2026-09-24-ohos-device-milestone.md` and
> `2026-09-22-ohos-startup-crash-rootcause.md` §5f; the rest of this playbook is a fallback route.

> 摘要（中文）：黑屏阻塞 #4 的修复作战手册。问题 = 非标准化壳 abc 的 host 导入记录
> `@app:<bundle>/entry/openharmonyhost` 与宿主注册名不匹配。候选修复 A（壳 import 形式，
> 已构建命名空间导入变体）、B（`loadNativeModule` 动态加载）、C（打包侧 pkgContextInfo /
> app-lib `default` 路径键，研究进行中）；含精确 diff、重建/验证/入包/发布链、决策表与回滚。

## 1. Problem recap ✅

Non-normalized (`useNormalizedOHMUrl=false`) OHM-URL builds turn the shell's
`import host from 'libopenharmonyhost.so'` into the abc module request
`@app:<bundleName>/<moduleName>/openharmonyhost` (es2abc strips the `lib` prefix and the `.so`
suffix). The host `.so` registers its NAPI module under the bare name `openharmonyhost` and,
since the alias work landed, also under the file-name alias `libopenharmonyhost.so`. On the
device the lookup by the `@app:...` record fails — hilog
`Load native module failed, ModuleName: @app:com.example.hellmauiapp/entry/openharmonyhost` —
so `host` has no exports, the XComponent `registerXComponent` call never reaches .NET, the
process stays alive but the page is black. The problem is **record spelling vs registration
name**, not a missing library; the alias host is already in kit #16 and in the installed pack
(✅ `g_hostModuleFileAlias` / `HostInitBoundAsFile` present), but which abc record the ArkTS VM
routes to either name is still unproven (⏳ probes A/B/C on `device-test-kit` are the device
run).

## 2. Candidate fix A — change the shell's static host import

Two forms came out of the experiments. **A1 is the only one buildable with this SDK** (it is
what "the import-form experiment" physically produced); A2 is the literal module-name import
the brief asked for and is blocked at build time. Land whichever the device confirms.

### A1. Namespace import of the same `.so` specifier (built, ⏳ device)

Exact diff, 3 files per pack × `preview.{22,23,24}` (the three packs are byte-identical
mirrors today — all must stay identical):

```diff
--- a/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets/pages/Index.ets
+++ b/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets/pages/Index.ets
@@ -15,7 +15,7 @@
 import fileIo from '@ohos.file.fs';
-import host from 'libopenharmonyhost.so';
+import * as host from 'libopenharmonyhost.so';
 import picker from '@ohos.file.picker';
```

Same one-line change in
`packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.{22,23,24}/templates/ets/entryability/EntryAbility.ets`
(line 10) and `.../entryability/EntryAbility.ui.ets` (line 12).

What it changes in the abc ✅ (verified by disassembling the built variant): the host
`module_request` stays `@app:com.example.hellmauiapp/entry/openharmonyhost`; only the
`ModuleTag` changes `REGULAR_IMPORT / import_name: default` → `NAMESPACE_IMPORT`. The rest of
the module record set — including the entry record
`com.example.hellmauiapp.entry.ets.entryability.EntryAbility` — is identical.

### A2. Literal module-name import (requested; **not buildable**, do not ship)

```diff
-import host from 'libopenharmonyhost.so';
+import host from 'openharmonyhost';
```

Blocked twice with SDK 26.0.0.18 + hvigor 6.26.4: (1) ArkTS Compiler Error 10505001 / TS2307
`Cannot find module 'openharmonyhost' or its corresponding type declarations`; (2) after an
ambient `declare module 'openharmonyhost'` shim, es2abc/ets-loader 10311002 `Failed to resolve
OhmUrl` — the loader only rewrites native specifiers matching `/lib(\S+)\.so/`. Only apply
this if one of the running experiments lands a buildable route (e.g. loader/packaging change);
it is not a drop-in today.

### Rebuild ✅ (no host build needed)

```sh
cd /storage/Users/currentUser/springsources/ohos-workload
# hvigor packages are already cached under .arkts-build; offline fallback mirror:
#   HVIGOR_MIRROR=file:///data/storage/el2/base/tmp/opencode/npm-mirror
TYPECHECK=1 bash scripts/build-arkts-shell.sh
```

The script builds the repo templates (`preview.24`: `Index.ets` + `EntryAbility.ui.ets`) with
the compatible settings — `compatibleSdkVersion 18`, `useNormalizedOHMUrl=false`, abc version
gate `<= 13.0.1.0` — and writes `dist/ets/modules.abc`. Expected tail:
`ArkTS shell compiled: dist/ets/modules.abc (... abc version 13.0.1.0, compatibleSdkVersion 18)`.
If `TYPECHECK=1` flags pre-existing template issues, rerun without it (the shipping build does
not typecheck) and say so in the commit message.

### Verify before packaging ✅

```sh
S=/data/storage/el2/base/tmp/opencode/napi-fix && mkdir -p "$S"
AD=${OHOS_SDK_ROOT:-$HOME/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_2}/toolchains/ark_disasm
"$AD" dist/ets/modules.abc "$S/modules.pa"
grep -n 'ModuleTag: NAMESPACE_IMPORT, local_name: host, module_request: @app:com.example.hellmauiapp/entry/openharmonyhost' "$S/modules.pa"
grep -n '^\.record com\.example\.hellmauiapp\.entry\.ets\.entryability\.EntryAbility' "$S/modules.pa"
grep -c '@normalized' "$S/modules.pa"   # must print 0
python3 -c "raw=open('dist/ets/modules.abc','rb').read(0x10); print('.'.join(map(str,raw[0x0c:0x10])))"  # 13.0.1.0
```

Acceptance: the two host import lines carry the applied `ModuleTag`, exactly one
`EntryAbility` `.record`, no `@normalized`, version `13.0.1.0`. If the applied form is A2,
assert the record becomes the bare `openharmonyhost`/raw shape instead.

### Repack / publish chain ✅

```sh
cd /storage/Users/currentUser/springsources/ohos-workload
# 1) abc into the packs (and the installed pack MSBuild resolves)
for v in 22 23 24; do
  P=packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.$v/templates/ets
  cp dist/ets/modules.abc "$P/modules.ui.abc"
  [ -f "$P/modules.shell.abc" ] && cp dist/ets/modules.abc "$P/modules.shell.abc"
done
I=${DOTNET_ROOT:-$HOME/.dotnet}/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets
cp dist/ets/modules.abc "$I/modules.ui.abc" "$I/modules.shell.abc"
# 2) build-host.sh NOT needed (host unchanged; the alias host already ships)
# 3) bundle + checksums + publish + kit + preflight (dry-run without --publish)
bash scripts/release-all.sh --publish
```

`release-all.sh` runs, in order: `pack-workload-bundle.sh` → `release-checksums.sh` →
`publish-workload-release.sh --skip-kit --allow-clobber-mismatch --also-sdk-release <tag>` →
`make-device-test-kit.sh --publish` → `preflight.sh` (use `--skip-preflight` only if the
suites cannot run; `preflight.sh --quick` covers `sh -n` + markdownlint). The kit consumes
`dist/ets/modules.abc` directly; the pack copy is what third-party
`-p:OpenHarmonyUIPage=pages/Index` builds resolve, and release-all step 1 reports repo vs
installed drift — sync both or expect NOTE-DIFF.

### Risks / notes

* **Entry record must stay the kit #10 form** (`...ets.entryability.EntryAbility`); re-run the
  verification grep after every rebuild. RH1 already showed the normalized entry record
  regresses the device entry point.
* Whether the ArkTS VM routes a `NAMESPACE_IMPORT` record to the native module is exactly what
  probe B tests (⏳). If it does not bind, do not land A1 — use B or C.
* `import * as host` exposes a namespace object; the host exports must be reachable as its
  properties. Probe B's `registerXComponent=function` log is the on-device proof.
* Keep all three packs' templates byte-identical; a preview.24-only change leaves mirror drift
  the audit has repeatedly flagged.

## 3. Candidate fix B — dynamic load (only if probe C binds, ⏳)

Minimal sketch, keeping the existing guarded-call style (`this.hostCall(api, typeof host !==
'undefined' && typeof host.api === 'function', ...)`):

```ts
// remove: import host from 'libopenharmonyhost.so';
// loadNativeModule is a stage-model global (no import; throws BusinessError 10200301 if absent)
let host: any = undefined;
let hostLoadFailed: boolean = false;
function loadHost(): void {
  if (host !== undefined || hostLoadFailed) { return; }
  try { host = loadNativeModule('libopenharmonyhost.so'); }  // or 'openharmonyhost' per probe C
  catch (e) { hostLoadFailed = true; /* one-time hilog */ }
}
```

Call `loadHost()` once at the start of the page's `aboutToAppear()` and the ability's
`onCreate()`, before the first host call; the ~258 `host.*` call sites in `Index.ets` (12–13
in each ability template) then need no rewrite because the guards already tolerate an
undefined host.

Risks: the shell touches `host.*` synchronously in many places, so a single missed init point
degrades silently; the static import record disappears entirely (the probe C shape); `host`
becomes a mutable module-state variable instead of an import binding. This is materially
larger than A — budget a careful pass over the init points and the guards, and only land it if
probe C actually binds.

## 4. Candidate fix C — packaging side (⏳ placeholder, research in flight)

Fill this section once the in-flight runtime research lands (snapshot:
`/data/storage/el2/base/tmp/opencode/rj2/` — `nmm.cpp`, `module_path_helper.h`,
`main_thread.cpp`, `native_lib_util.cpp`, `js_module_manager.cpp`, `napi_module_loader.cpp`).
What is already visible there:

* `NativeModuleManager` resolves app modules through an app-lib path map keyed `"default"`
  (`nmm.cpp`: `pathKey = "default"`; `appLibPathMap_["default"] + nativeModulePath[0]`), and
  those paths are populated from the HAP's library dirs (`main_thread.cpp`,
  `native_lib_util.cpp`).
* Normalized OHM URLs are only resolved when the HAP ships `pkgContextInfo.json` (VM gate
  `IsNormalizedOhmUrlPack()`); the hvigor `loader_out` emits the file but the current manual
  HAP assembly does not ship it. The normalized host record is
  `@normalized:Y&&&libopenharmonyhost.so&` — the shape the file-name alias was added for —
  while the normalized entry record regressed the device entry before PA1.

The exact change (ship `pkgContextInfo.json` in the HAP / adjust the `default` app-lib path /
switch `useNormalizedOHMUrl=true`), its verification (normalized record shape + on-device
entry), and the tester steps are **pending**; do not apply until this section is filled from
that research (or its eventual `docs/plans/` doc).

## 5. Decision table — which result implies which fix

| Device result (`device-test-kit` probes / kit haps) | Reading | Land | Expected kit | Tester verification |
|---|---|---|---|---|
| Kit #16 (alias host, current import) binds: `[openharmony-host] ... bound via alias 'openharmonyhost'`, `registerXComponent=function`, first frame | the alias alone fixed it; no shell change | none | #17 (only repack if needed) | install re-signed kit haps → `[maui]` logs, first frame, no `Load native module failed`, no black screen |
| Probe B / importb haps bind (`NAMESPACE_IMPORT`) | static import form is enough | A1 one-liner | #17 | same as above, plus `bound via alias` marker |
| Probe C `loadNativeModule('openharmonyhost')` binds | the raw bare name reaches the loader | B with bare name | #17+ (larger change) | start + first frame, no `10200301` |
| Probe C `loadNativeModule('libopenharmonyhost.so')` binds | the raw file name reaches the loader | B with file name (or C if normalized packaging is preferred) | #17+ | same as above |
| A (control) binds, B fails | `REGULAR_IMPORT/default` is the working kind | none (keep current import) | #17 | current shell + alias host |
| A fails, B binds (or vice versa) | the `ModuleTag` matters in native-module routing | mirror the binding kind exactly | #17 | hilog shows the binding alias |
| A/B/C all fail with the same `@app:.../entry/openharmonyhost` record; C both names 10200301 | record spelling is not the (only) blocker; namespace/packaging problem | C placeholder | after research | entry + host records re-checked on device |

Kit numbering is informal (runtime-ohos plans still say #14, ohos-workload's rawfile refresh
says #15, the current app kit is labeled #16). Confirm the actual number in the
`device-test-kit` release notes before quoting it to testers. Tester flow is unchanged:
re-sign the outer hap and the inner ELFs, install, start, capture the app's hilog.

## 6. Rollback

* **A, B (shell-side, ohos-workload):** `git revert <commit>` (or
  `git checkout <last-good> -- packs/Microsoft.OpenHarmony.Sdk/*/templates/ets`) →
  `bash scripts/build-arkts-shell.sh` → re-sync the abc into the packs and the installed copy
  → `bash scripts/release-all.sh --publish`. No host rebuild.
* **Host-side (only if the alias host itself regresses):** revert the alias commit →
  `bash scripts/build-host.sh` → copy the signed `.so` into the pack and the installed copy →
  repack. Not needed for A/B/C: kit #16 and the installed pack already carry the alias host.
* **Kit:** release assets are addressed by fixed name (`device-test-kit.tar.gz` + sidecar), so
  keep the previous kit tarball + `.sha256` locally; roll back by re-uploading that tarball
  (`gh release upload --clobber`) or by re-running the publish chain from the last good
  templates. Never force-push; always restore by a normal publish.
* **C:** revert the packaging/loader switch in the same commit, then rebuild + repack.

## 7. Evidence on disk (scratch, not part of the release)

* `/data/storage/el2/base/tmp/opencode/rj1/` — namespace-import build (`dist-importb/ets/modules.abc`),
  `importb.pa` / `base.pa` disassembly, `evidence/imports-*.txt` + `records-*.txt` (only the
  host `ModuleTag` differs), `haps-importb/` (5 kit haps, converted), `README-importb.txt`.
* `/data/storage/el2/base/tmp/opencode/ri1/abc/` — probe A/B/C `ark_disasm` output;
  the 3 probe haps are on release `device-test-kit` per the experiment doc.
* `/data/storage/el2/base/tmp/opencode/rh1/` — alias host build + `alias-verify.out` (both
  registration names, 171 exports unchanged).
* `/data/storage/el2/base/tmp/opencode/rj2/` — OH runtime loader source snapshot for fix C.
* Current kit dir: `/data/storage/el2/base/tmp/opencode/device-test-kit/`.
