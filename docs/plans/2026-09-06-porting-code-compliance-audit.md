# Porting-code compliance audit: OHOS changes vs repo conventions

**Date:** 2026-09-06 (device side)
**Audit scope:** code intended for upstream PRs (dotnet/runtime #132827 sandbox + #132953 infra), plus fork-local additions that mirror upstream code style (sdk OpenHarmonyCodesign.cs / OpenHarmonyEnvironmentDefaults.cs). Sources of truth: each repo's .editorconfig, AGENTS.md, .github/instructions (runtime) / .github/memory (sdk), per-area AGENTS.md, docs/coding-guidelines, license-header templates.

## Audit surface

| Repo | Surface | Files | Type |
|---|---|---|---|
| runtime | #132827 | 6 (numasupport.cpp, SharedMemoryManager.Unix.cs, NamedMutex.Unix.cs, OperatingSystem.cs, projitems, MutexTests.cs) | all modifications |
| runtime | #132953 | 11 (eng props/sh/cmake + runtime.json + native CMake/sh) | all modifications |
| sdk | port files | OpenHarmonyCodesign.cs (new 503L), OpenHarmonyEnvironmentDefaults.cs (new 38L), RID graphs, layout targets, install scripts, docs | 2 new .cs + graphs/targets/scripts |
| aspnetcore | port changes | Directory.Build.props (RID list + TargetOsName), Dependencies.props, src/Tools/Directory.Build.props, NativeAotTestApp.csproj | modifications |

## Compliance by requirement

### 1. License headers — PASS
- runtime/sdk/aspnetcore all new/modified `.cs` carry the exact 2-line MIT header
  (`// Licensed to the .NET Foundation...`). Verified on every audited file.
- `.props/.targets/.csproj`/eng files: no header required by convention (aspnetcore + sdk confirmed; runtime eng files likewise headerless upstream). PASS.

### 2. Platform-code conventions (runtime) — PASS
- `#if defined(TARGET_LINUX) && !defined(TARGET_ANDROID) && !defined(TARGET_OPENHARMONY)` guards mirror existing TARGET_ANDROID pattern exactly (numasupport.cpp).
- `[NonVersionable] internal static bool IsOpenHarmony()` + XML doc, structurally identical to IsHaiku/IsOpenBSD (OperatingSystem.cs). Inserted in the file's semantic platform grouping (BSD/unix family adjacency); file is not strictly alphabetical, so placement is acceptable.
- projitems DefineConstants line identical in form to ILLUMOS/SOLARIS/HAIKU entries.
- NamedMutex exclusion appends `!OperatingSystem.IsOpenHarmony()` to the existing platform chain (FreeBSD/OpenBSD/Haiku pattern).
- configureplatform.cmake: OHOS detection block (tolower CMAKE_SYSTEM_NAME → linux+musl remap) + TARGET_OPENHARMONY derivation — consistent with file structure; review-sanctioned ("pretend linux flavor at compile level").
- configuretools/configurecompiler: NDK toolchain wiring mirrors the Android branch line-for-line (env check → toolchain file → tryrun.cmake → `__Compiler="default"` → arch map → error handling). Exemplary structural parity.
- runtime.json: independent base RID `"ohos": {}` with no linux import (jkotas "not pretending to be Linux" requirement); keys inserted in collating order (before "ol"); JSON valid.

### 3. C# style (runtime sandbox + sdk port) — PASS with notes
- File-scoped vs block namespaces: sdk OpenHarmonyEnvironmentDefaults.cs uses file-scoped (preferred for new code). OpenHarmonyCodesign.cs uses block-scoped — consistent with the existing src/Tasks area convention (upstream task files all block-scoped; sdk CONVENTIONS: "match existing-file style when an area is deliberately older"). Acceptable.
- TaskBase derivation + ExecuteCore + [Required] + Log.LogError/LogMessage: canonical MSBuild-task shape; net472-safe API usage verified (no HashData/ReadOnlySpan/RuntimeInformation). No hardcoded NETSDK diagnostic codes (Log errors are task-local, not resource diagnostics — resx rule not triggered).
- AOT safety: OpenHarmonyEnvironmentDefaults.cs is static + no reflection → AOT-safe; it IS linked into dotnet-aot via AotSourceFiles.props (correctly added — the project disables default compile items).
- Constants PascalCase, `_camelCase` fields, comments explain why. PASS.

### 4. Error strings / resx — PASS
- No new managed user-facing error strings added inline anywhere in the audited code; no NETSDK-style diagnostic introduced (the codesign task reports task-local errors via Log, consistent with e.g. other non-resource tasks). MutexTests/SharedMemoryManager add no strings.

### 5. Findings that should be fixed (low severity, reviewer-visible)

**F1. SharedMemoryManager.Unix.cs — misleading comment placement (runtime #132827)**
```csharp
// On non-Apple platforms, shared memory files live under the process temp directory.
#if TARGET_OPENHARMONY
    // OpenHarmony app sandboxes mount /tmp read-only, so use the process temp
    // directory (which honors TMPDIR on Unix and falls back to /tmp) ...
    return Path.GetTempPath();
#else
    return "/tmp/";          // <-- the outer comment contradicts this branch
#endif
```
The unconditional comment says non-Apple platforms use "the process temp directory", but the `#else` branch returns the hardcoded `"/tmp/"` (not GetTempPath). Move the sentence into the `#else` branch as `// Other platforms: shared memory files live under the fixed /tmp path (historical behavior).` or reword so it does not misdescribe the #else arm. Conventions: "stale/misplaced comments describing old behavior are worse than no comments".

**F2. NamedMutex.Unix.cs — missing per-platform exclusion comment (runtime #132827)**
The `UsePThreadMutexes` chain documents WHY each platform is excluded (macOS Rosetta, FreeBSD issue link, OpenBSD PR link, Haiku issue link) — the added `!OperatingSystem.IsOpenHarmony()` has no accompanying comment. Add one following the file's pattern, citing the reason (musl libc on OpenHarmony lacks robust process-shared mutex support / app-sandbox constraints) — mirroring the existing "See https://github.com/dotnet/runtime/issues/..." style if an issue exists.

**F3. sdk OpenHarmonyEnvironmentDefaults.cs — nitpicks (fork-local, not upstream-bound)**
- Comment "running on a ohos RID" → "an openharmony RID" (grammar + naming; the rename branch already updates the string).
- Hardcoded `TMPDIR=/data/storage/el2/base/tmp` device path — fine for the fork's device images, but if this file ever goes upstream it must derive the path, not hardcode it.

**F4. aspnetcore RID insertion placement (style judgment, no hard rule broken)**
`openharmony-x64;openharmony-arm;openharmony-arm64` inserted between `linux-musl-loongarch64` and `freebsd-x64` in Directory.Build.props + mirrored in Dependencies.props (both Runtime and Crossgen2 lists, no Version attribute, above the source-build fallback — all correct). The only upstream precedent for adding a whole OS (openbsd #65628) appends after the last OS block. No CI/tool enforces ordering; format constraints (single line, no whitespace) are respected. If reviewers prefer append-after-last, move the block after `haiku-x64` in both files. The TargetOsName condition + NativeAotSupported=false override are convention-correct (canonical condition grammar; pre-import load order correct; avoids editing the arcade denylist).

### 6. Docs / scripts / misc
- Fork-local docs (docs/plans, documentation/ohos-install, installonohos) sit outside the conventional doc layout in sdk (FILE_MAP + update-docs skill expectations) — acceptable for fork-private material; would need index/memory sync only if merged into sdk upstream (not planned).
- Stale fork AGENTS.md files claim "zero OHOS code" (sdk root + aspnetcore root) — now misleading; recommend updating or annotating.
- Scripts use `#!/usr/bin/env bash` + LF, matching repo style; no license headers needed on scripts.

## Verdict

- **Blocking issues: none.** All audited code satisfies the repos' normative requirements (headers, platform-guard patterns, resx discipline, analyzer/warning posture, naming, structure).
- **Recommended fixes before/around PR review: F1 + F2** (runtime #132827, comment correctness — cheap, avoids reviewer friction). F3/F4 optional.
- The runtime #132953 infra code and aspnetcore port changes are convention-clean; the 36ef/R2R-27.0 revert (issue #133296) remains the only upstream-blocking item, independent of style.
