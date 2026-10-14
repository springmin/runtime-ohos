# Rehearsal review M2 — MSBuild / proj / build-config surface (OpenHarmony port)

Repo: `/storage/Users/currentUser/springsources/runtime-ohos`, branch `feature/openharmony` @ `dc21ff203a4`.
Method: `git log --no-merges --author=springmin -p -- <file>` + full-file context + cross-check against the
PR branches (`pr/ohos-packs` `fed16fdbdc9`, `pr/ohos-libs-tfm` `2bab0935bf6`, `pr/ohos-console` `39b33de4e56`,
`pr/ohos-crossgen-corelib` `169c072d07c`, `pr/ohos-aot-unix` `91a2e8e5a62`, `pr/ohos-aot-singleentry` `da4dc098a4a`)
and the recorded decisions in `docs/plans/2026-09-07-ohos-pr-plan-bsd-haiku-model.md` / `docs/plans/2026-09-21-ohos-pr-drafts.md`.
`main...HEAD` includes upstream 11.0-rc2 drift (e.g. the WASM R2R pipeline in the sfxproj, `Crossgen2.props`
`Private=false`, the SingleEntry rewrite); every non-OpenHarmony hunk below was attributed via `git log -S` and excluded.

---

## Findings

### ❌ F1 — sfxproj still ships the fork-local `OpenHarmonyInTreeR2R` A/B gate and a fork/lab comment
`src/installer/pkg/sfx/Microsoft.NETCore.App/Microsoft.NETCore.App.Runtime.CoreCLR.sfxproj:29-32`
Evidence: the comment reads *"off by default in the fork (the out-of-tree stock-crossgen2 overlay ships the R2R
images). Set OpenHarmonyInTreeR2R=true to use the in-build crossgen2 path (A/B); the in-build tool is
probe-verified."* — fork reference + lab note + a knob that exists only for the fork A/B. The PR plan says
(the same words in `docs/plans/2026-09-07-...md:244` and `:346`): *"submit **without** the `OpenHarmonyInTreeR2R`
gate"*, and the N13 PR branch (`fed16fdbdc9`) carries the neutral form: `PublishReadyToRun` false for
`TargetsOpenHarmony` with the comment *"OpenHarmony runtime packs stay IL-only; the R2R image is produced by the
SDK build."* Precedent for no-PGO platforms is the netbsd/illumos/solaris/haiku line directly above.
Fix: restore the N13 form (drop the knob, one neutral comment); if the knob is kept fork-side, at least remove
"in the fork"/"probe-verified" and keep it out of the PR branch.

### ❌ F2 — `ResolvedRuntimePack` override is now disabled on every non-OpenHarmony platform
`eng/targetingpacks.targets:121-128`
Evidence: the added `'$(TargetsOpenHarmony)' == 'true' and` is serial, so on linux/windows/... the whole condition
is false and the pre-existing upstream override (`PackageDirectory="$(LocalRuntimePackDir)"`) no longer runs —
the opposite of commit `61503142c87`'s stated intent (*"so other platforms keep the upstream behavior"*).
`ResolvedFrameworkReference/RuntimePackPath` (line 132) is still applied unconditionally, so the hook is now
inconsistent (part local, part NuGet) on those platforms. Confidence: semantics certain; whether CI notices is not
verified here (the fork's Linux CI passing may mask it).
Fix: keep the upstream clause and scope only the RID restriction to OHOS, e.g.
`'$(LocalRuntimePackDir)' != '' and '%(ResolvedRuntimePack.FrameworkName)' == '$(LocalFrameworkOverrideName)' and ('$(TargetsOpenHarmony)' != 'true' or '%(ResolvedRuntimePack.RuntimeIdentifier)' == '$(TargetRid)')`.

### ⚠️ F3 — `KnownAppHostPack` replacement is not TFM-scoped, and its follow-up guard is dead
`eng/targetingpacks.targets:87-97`
Evidence: `Remove="$(LocalFrameworkOverrideName)"` wipes SDK `KnownAppHostPack` entries for *all* TargetFrameworks
(e.g. downlevel net10.0). The earlier attempt `e7472dbcc22` scoped removal to `$(NetCoreAppCurrent)` for exactly
this reason; the static-graph-restore revert (`1e9357aa1ac`) lost that scoping. After the Remove, the Include's
`'@(KnownAppHostPack->AnyHaveMetadataValue('TargetFramework', '$(NetCoreAppCurrent)'))' != 'true'` can no longer
see the entry that was just removed, so it is redundant — or, if another identity matches the TFM, it skips
re-adding and leaves no apphost pack at all.
Fix: express the replacement TFM-scoped in a form that survives both restore modes, or (precedent at lines 64-66,
where wasi-wasm is appended to the Mono pack) append the openharmony RIDs with a metadata-conditioned
`KnownAppHostPack Update`; drop the now-dead guard.

### ⚠️ F4 — Shims TFM uses `TargetOS`, the rest of the set (and the reviewed N15 PR) uses `TargetsOpenHarmony`
`src/libraries/shims/Directory.Build.props:11`
Evidence: the property it consumes is defined off `TargetsOpenHarmony`
(`src/libraries/Directory.Build.props:19`), but the consumer tests `'$(TargetOS)' == 'openharmony'`; the two can
disagree on the `TargetOS=AnyOS` + `__PortableTargetOS=openharmony` sentinel (the property is defined but the
branch is not taken → `net11.0-anyos`). `pr/ohos-libs-tfm` tip `2bab0935bf6` used `TargetsOpenHarmony`, and
`docs/plans/2026-09-21-ohos-pr-drafts.md` records the resolution *"so the whole set shares one predicate"*.
Fix: `Condition="'$(TargetsOpenHarmony)' == 'true'"` (keep it when folding the shims cleanup follow-up).

### ⚠️ F5 — System.Console unix-source clause is keyed to the build target OS, not to the neutral-TFM case
`src/libraries/System.Console/src/System.Console.csproj:201` (and the same shape at `:22`)
Evidence: `TargetsOpenHarmony` derives from `TargetOS`, so it is true in *every* inner build of an
OpenHarmony-targeted build, including the `-windows`/`-android`/`-ios`/... TFMs. `ConsolePal.Windows.cs` /
`ConsolePal.Android.cs` / `ConsolePal.iOS.cs` declare non-partial `internal static class ConsolePal`, while
`ConsolePal.Unix.cs` is `partial`, so compiling both is a duplicate-class error. Today's `libs` flow builds one
TFM per project (sfx-src/oob-src filter), so CI does not hit it — but a full project/solution build in an OHOS
configuration would (`dotnet build System.Console.csproj` builds all `TargetFrameworks`).
Fix: scope the OpenHarmony case to the documented neutral TFM:
`'$(TargetPlatformIdentifier)' == 'unix' or ('$(TargetsOpenHarmony)' == 'true' and '$(TargetPlatformIdentifier)' == '')`.

### ⚠️ F6 — CA1416 suppression is project-wide and untracked deferred work
`src/libraries/System.Console/src/System.Console.csproj:13-17`
Evidence: `NoWarn=$(NoWarn);CA1416` disables the platform analyzer for the whole project in the neutral OHOS case,
while the repo convention is no suppressions to pass builds / root-cause fixes, deferred work tracked by a
searchable TODO-with-issue, and analyzer severities centralized in `eng/CodeAnalysis.*.globalconfig`. Existing
CA1416 precedent in this repo is call-site `#pragma warning disable CA1416 // <reason>` (e.g.
`Common/src/Interop/Unix/System.Native/Interop.ForkAndExecProcess.cs:79`). The exit condition is documented in
prose only; the plan relies on the PR body to explain it.
Fix: either keep with a `TODO-OpenHarmony:`-style tracking marker next to it, or narrow it to
`ConsolePal.Unix.cs`-adjacent code (hand-off comment) so unrelated CA1416 stays visible.

### ⚠️ F7 — ILCompiler package ships device C++ runtime from a fork-only env var (silent no-op upstream)
`src/installer/pkg/projects/Microsoft.DotNet.ILCompiler/Microsoft.DotNet.ILCompiler.pkgproj:46-51`
Evidence: `OHOS_CXXRUNTIME_DIR` is a fork-side asset-bundle contract (documented as "external contracts stay" in
the fork's rename plan), not an NDK/SDK contract; with no producer or default in this repo the ItemGroup is a
silent no-op for upstream builds/CI, and it re-introduces `OHOS` naming in an upstream-visible file
(review rule: `ohos` only for toolchain contract names). The `'$(TargetsOpenHarmony)' == 'true'` conjunct is also
redundant — `'$(PackageTargetRuntime)' == 'openharmony-arm64'` already pins the RID.
Fix: either drop the ItemGroup from the PR (ship it with the device AOT enablement) or rename the contract
(`OPENHARMONY_CXXRUNTIME_DIR`) and document where it is produced; drop the redundant condition.

### 💡 F8 — openharmony→linux crossgen2 target-OS mapping is duplicated (and near-dead once F1 is fixed)
`src/coreclr/crossgen-corelib.proj:156-161` and `src/installer/pkg/sfx/Microsoft.NETCore.App/Microsoft.NETCore.App.Runtime.CoreCLR.sfxproj:65-67`
Both compute the same `TargetOS == 'openharmony' → 'linux'` mapping; with R2R disabled by default for OHOS the
mapping is only reachable via a command-line override. Define once (e.g. a `Crossgen2TargetOS` property next to
`eng/RuntimeIdentifier.props`) and consume in both, or defer the mapping to the PR that enables OpenHarmony R2R.

### 💡 F9 — comment hygiene nits
`sfxproj:65` says *"OHOS R2R images"* (platform name must be OpenHarmony); `crossgen-corelib.proj:25-27`'s
*"The default is overridable from the command line"* is noise (every property is command-line overridable);
the identical *"No -openharmony TFM: compile in the linux group"* comment is repeated in `sfx.proj:5`,
`sfx-src.proj:5`, `sfx-finish.proj:7` (one pointer to the property is enough); and after F1 the
`'$(PublishReadyToRun)' != 'true'` conjunct of `_RemoveDuplicateSymbolFiles` (`sfxproj:186`) becomes constant
for OHOS — simplify or keep only if the knob survives.

### 💡 F10 (low confidence) — sibling traversals were left out of the TFM mapping
`src/libraries/oob.proj:4`, `oob-src.proj:4`, `oob-trim.proj:4`, `apicompat/ApiCompat.proj:4`,
`tests.proj:5` still compute `$(NetCoreAppCurrent)-$(TargetOS)` (→ `net11.0-openharmony`, which no project
builds). `libs.oob` is part of the default `libs` expansion (`eng/Subsets.props:144-147`), so the OHOS build
does evaluate them; they appear to work only through the neutral-`net11.0` fallback of the TFM negotiation.
Confirm that is intended (upstream keeps one vertical TFM across sfx/oob/tests) or route them through
`LibrariesOpenHarmonySfxTfm`.

### 💡 F11 (low confidence, question) — device-hosted ilc cannot be resolved in-repo
`eng/targetingpacks.targets:79` lists host RIDs for `KnownILCompilerPack` but no `openharmony-*`, while the
pkgproj builds `runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler` (`PackageTargetRuntime == openharmony-arm64`)
for on-device AOT. If in-repo publishing on device is a supported flow, add `openharmony-arm64` to
`ILCompilerRuntimeIdentifiers`; otherwise this is fine.

---

## verified-OK

- `PortableRuntimeIdentifierGraph.json:67-86` — `openharmony` imports only `any` (matching win/browser/wasi, per the #132953 review fix `5a096525a4a`); arch RIDs import only `openharmony` (no `unix-*`/`linux-musl` inheritance); insertion point groups correctly; `runtime.json` untouched (`git diff main...HEAD --stat` shows only the portable graph), which matches the "runtime.json is frozen" rule.
- `crossgen-corelib.proj:25-27` — OHOS R2R gating is a plain unconditional disable, same shape as the netbsd/illumos/solaris/haiku line; `_CrossGenTargetOS` is defined inside `InvokeCrossgen2` immediately before its only use (`:173`), so no evaluation-order hazard. Matches N10 tip `169c072d07c` exactly.
- `Microsoft.DotNet.ILCompiler.SingleEntry.targets:36-46` — `_linuxLibcFlavor=musl` is set *before* the generic `linux-*` mapping, and the `openharmony → linux` mapping runs after the upstream `IlcTargetOS` override, so the override is honored; comment spells out OpenHarmony and names only the RID segment in lowercase. Matches N12 tip `da4dc098a4a`.
- `Microsoft.NETCore.Native.Unix.targets:29-30,59-61,169` — lld and the `System.Net.Security.Native` exclusion key off `_originalTargetOS`, which is correct for both cross and same-RID (on-device) builds; `CrossCompileAbi=ohos` yields the documented clang triple `aarch64-linux-ohos` (`:84`), and `ohos` there is an allowed toolchain-contract token with a one-line rationale. Matches N11 tip `91a2e8e5a62` (only upstream's later `IgnoreStandardErrorWarningFormat` attribute differs).
- `src/libraries/Directory.Build.props:14-20` — property is defined after the root `Directory.Build.props` import (`:12`), so `TargetsOpenHarmony` (eng/RuntimeIdentifier.props:57) is available; `shims/Directory.Build.props` imports `../Directory.Build.props` at line 3 *before* consuming `$(LibrariesOpenHarmonySfxTfm)`, so no empty-property/evaluation-order bug; the dead `LibrariesOpenHarmonyShimsTfm` property and its stale comments are gone (matches the `pr-ohos-shims-tfm-cleanup` patch).
- `Directory.Build.targets:92-122` — `LibrariesBinPlaceTfm` default restores the upstream value for non-OHOS; all three `BinPlaceTargetFrameworks` consumers use it; neutral-TFM projects still binplace correctly via the best-match fallback.
- `eng/targetingpacks.targets:48,55-62,67-74,95` — openharmony RIDs added to the framework-reference, NativeAOT and apphost lists; deliberately absent from the Mono-labelled pack with a one-line rationale; no other platform's list was edited.
- Remaining comments are tight and fork-neutral: `Directory.Build.props:14-17`, `sfx.proj/sfx-src.proj/sfx-finish.proj`, `shims/Directory.Build.props:7-10`, `System.Console.csproj:13-16`, `pkgproj:46-47`, `targetingpacks:87-88,121-123`, `SingleEntry:42-43,156-157`. No dated notes/lab records outside F1.
- `Microsoft.NETCore.App.Crossgen2.props` contains no OpenHarmony content at all (its `Private=false` / `Sdk.props` hunks are upstream `dfcb726e234` / `1c19e73c1d0`), so it needs no OHOS review.
