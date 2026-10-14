# Scan Report — M1: Managed C# surface of the OpenHarmony port

- **Scope (4 files, per assignment):**
  - `src/libraries/System.Private.CoreLib/src/System/OperatingSystem.cs`
  - `src/libraries/System.Private.CoreLib/src/System/Threading/NamedMutex.Unix.cs`
  - `src/libraries/System.Private.CoreLib/src/System/IO/SharedMemoryManager.Unix.cs`
  - `src/libraries/System.Threading/tests/MutexTests.cs`
- **Repository / branch:** `dotnet/runtime` fork, `feature/openharmony` (upstream submission rehearsal)
- **Target framework:** `net11.0` (`$(NetCoreAppCurrent)` = 11.0, Directory.Build.props:71)
- **Scan depth:** standard (critical patterns + references selected by detected signals)
- **Hot-path context (provided):** `OperatingSystem.IsOSPlatform` / `IsLinux` are called at startup and by library platform/version checks; named-mutex open/wait paths run per lock; `SharedFilesPath` initializes once. All treated as warm paths.
- **OHOS hunks reviewed:** `springmin` commits `1e8807e053c`, `c00857406e0`, `071300a4811`, `4c77bcca431`, `40d622430ac`, `afe10e966b7`, `417ab220532`; full-file context and interactions checked. Upstream code in these files (e.g. `NamedMutexProcessDataNoPThreads`, `SharedMemoryId` ctor) is only judged where a hunk alters its behavior.
- **Method:** `analyzing-dotnet-performance` workflow (critical patterns → signal-selected topic references → scan recipes → Verify-the-Inverse → compound-allocation check → cross-file consistency), plus `.github/instructions/csharp.instructions.md` and `review-lessons.md` (rules from real PR review comments) as additional criteria. No files were modified during this scan.

## 1. Scan execution checklist

References loaded: `critical-patterns.md`, `memory-and-strings.md`, `collections-and-linq.md`, `io-and-serialization.md`, `async-patterns.md`, `structural-patterns.md` (always). Regex topic not selected (no `Regex` signals); its recipes were still run for a full checklist.

| Recipe (topic) | Hits in the 4 files | Where / verdict |
|---|---|---|
| `.IndexOf("` without StringComparison (critical) | 0 | — |
| `.Substring(` (critical/memory) | 2 | `SharedMemoryManager.Unix.cs:31,38` — upstream `SharedMemoryId` ctor, guarded by Ordinal `StartsWith`, small slices; not our hunk |
| `.StartsWith(` / `.EndsWith(` (critical) | 2 / 0 | `SharedMemoryManager.Unix.cs:28,36` — both `StringComparison.Ordinal` ✔ |
| `.Contains(` (critical) | 1 | `SharedMemoryManager.Unix.cs:44` — `Contains(char)` overload, culture-free ✔ |
| `.ToLower()` / `.ToUpper()` (memory) | 0 / 0 | ✔ |
| Chained `.Replace(...)` (memory) | 0 | ✔ |
| `params ` (memory) | 0 | ✔ |
| LINQ `.All(` / `.Any(` / `.Select/.Where/.OrderBy/.GroupBy/.Cast/.Take/.Aggregate` (collections) | 0 | ✔ |
| `new Dictionary<` / `new List<` (collections) | 0 / 0 | The two dictionaries in `SharedMemoryManager.Unix.cs` (`_uidToFileHandleMap:809`, `_processDataHeaders:873`) are fields built once and **mutated** after construction (`Add`/`Remove` under the creation/deletion lock) → `FrozenDictionary` not applicable |
| `static readonly Dictionary<` / `FrozenDictionary` (collections) | 0 / 0 | — |
| `StringComparer.CurrentCulture` (collections) | 0 | ✔ |
| `new Regex(` / `RegexOptions.Compiled` / `GeneratedRegex` (regex, not selected) | 0 / 0 / 0 | ✔ |
| `new HttpClient(` / `new JsonSerializerOptions` (I/O) | 0 / 0 | ✔ |
| `async void` (async) | 0 | ✔ |
| Unsealed non-abstract classes (structural, absence pattern) | 1 | `MutexTests.cs:15` (test class). Production classes in the touched files: 5/5 sealed or abstract → **0 unsealed** |
| `.Equals(` without `StringComparison` (targeted) | 0 | 4/4 `platform.Equals(..., StringComparison.*)` in `OperatingSystem.cs`; 2/2 Ordinal `StartsWith` |
| `stackalloc` (targeted) | 1 | `OperatingSystem.cs:114` — upstream, bounded 128 chars (256 B, under the 1 KB budget), value cached; not our hunk ✔ |
| `SR.Format` / `string.Format` (targeted, compound check) | 10 / 0 | Resource-loaded format strings only (`SR.IO_SharedMemory_*`) → not actionable per skill rule; no compile-time-literal `string.Format` |
| `Path.Combine` (compound check) | 11 | `NamedMutex.Unix.cs:3`, `SharedMemoryManager.Unix.cs:7`, `MutexTests.cs:1` — open/create paths and one test helper; not per-wait |
| `Thread.Sleep` (compound check) | 5 | `NamedMutex.Unix.cs:526,563` and `SharedMemoryManager.Unix.cs:462,478,712` — all in the NoPThreads poll/retry fallback (see F4) |

**Verify-the-Inverse results:** string comparisons 6/6 use an explicit `StringComparison`; sealed 5/6 classes (production 5/5); 0 of the reviewed hunks add a heap allocation on a warm path (details in the compound check below).

**Compound-allocation check (Step 3c):** (1) branched `.Replace()` chains — 0; (2) cross-method chaining — `IsOSPlatform` → `string.Equals` has no allocating intermediates; the test helper chains `Path.GetTempPath()` + `Path.Combine` (2 allocations, test-only, cold); (3) `+=` with embedded allocating calls — 0; (4) `string.Format` sites — only `SR.Format` resource strings (10), none fixable.

**Cross-file consistency check (Step 3b):** the managed robust-mutex exclusion (`NamedMutex.Unix.cs:87`) was compared against its sibling native gate `src/native/libs/System.Native/CMakeLists.txt:60-64`, whose comment explicitly requires the two lists to stay synchronized — they match (see ✅). The new `PlatformDetection` consumer of the platform-name alias was identified (`PlatformDetection.Unix.cs:18`) — see F1.

## 2. Findings

### F1. `IsOSPlatform("linux")` returns true on OHOS — contradicts the agreed design (1 instance) 🔴
**Tag:** correctness / platform-name semantics (not a perf regression; severity is contractual, "must settle before submission").
**Impact:** one OS now answers to two canonical platform names, and every consumer that probes `linux` gets Linux semantics on a non-Linux RID — the exact behavior the decided design excludes.
**File:** `OperatingSystem.cs:133-141` (commit `417ab220532`).
Evidence and consequences:
- Agreed design (`review-lessons.md` §3): `IsLinux() == true` while `IsOSPlatform("linux") == false`, already explained to jkotas, with an Android-style consistency follow-up. The current code makes `IsOSPlatform("linux"/"LINUX"/"Linux")` **true** on OHOS (`OSPlatformName` = `"OPENHARMONY"`, line 31).
- Upstream's own precedent keeps it false on the sibling Android configuration (`CheckPlatformTests.cs:121` asserts `!IsOSPlatform(OSPlatform.Linux)` for Android) — the alias is the only place in the tree that reports a Linux name without `OSPlatformName == "LINUX"`.
- `IsOSPlatformVersionAtLeast("linux", major, …)` (`OperatingSystem.cs:158-159`) now passes on OHOS, comparing the **OHOS kernel** version against a Linux/distro version guard.
- Name-based detection now disagrees with RID-based detection (`RuntimeInformation.RuntimeIdentifier` = `openharmony-*`), and flips test-infrastructure semantics: `PlatformDetection.IsLinux => RuntimeInformation.IsOSPlatform(OSPlatform.Linux)` (`PlatformDetection.Unix.cs:18`) becomes true on OHOS, switching Linux assumptions in ~11 test files (e.g. distro probing in `IsDistroAndVersion`).
- Motivation is real (MSBuild `NativeMethodsShared` picks sh vs Windows-style exec scripts via `IsOSPlatform(OSPlatform.Linux)`), but it serves an external repo and was to stay out of this submission/follow-up per the lessons; the macOS alias precedent (`#if TARGET_OSX` → `"MACOS"`) is coupled to a dedicated test (`OperatingSystemTests.OSX_Is_Treated_as_macOS`) — the OHOS alias ships with no test pinning it and no reviewer-visible design statement.
**Fix:** drop the alias, keep `"OPENHARMONY"` canonical. If it must land now: separate PR, jkotas sign-off, and a test mirroring `OSX_Is_Treated_as_macOS` (assert alias true and `IsOSPlatformVersionAtLeast` behavior); do not carry it silently inside the mutex/shared-memory change set.
**Caveat:** zero measurable runtime cost (see ✅ #6) and no allocation — the objection is semantic, not performance.

### F2. OHOS comment hygiene: verbose rationale and a factually wrong RID claim (3 sites) 🟡
**Tag:** comment hygiene + factual correctness (`review-lessons.md` §1/§2: only "what/why", one line where possible, no fork/history narrative, names are OpenHarmony-only).
**Impact:** the alias comment tells upstream reviewers something untrue about the RID layer and buries the actual decision in 8 lines; the other two comments add noise to otherwise minimal hunks.
**Files:**
- `OperatingSystem.cs:135-139` — "the fork maps openharmony-\* RIDs to linux-musl-\*" **contradicts the frozen design and the repo state**: `PortableRuntimeIdentifierGraph.json:67-71` maps `openharmony` → `import: ["any"]` only, and the decided rule is that the RID/package layer must not pretend to be Linux (the linux+musl mapping lives only in the C/C++ compile layer, e.g. `eng/native/configurecompiler.cmake:857-864`). The comment also uses fork narrative ("the fork") and 8 lines where the macOS precedent uses 2. If the alias survives F1, replace with 1-2 neutral lines, e.g. `// Accept "LINUX" as an alias; "OPENHARMONY" stays the canonical name.`
- `NamedMutex.Unix.cs:85-86` — every other platform in that block is one line; tighten to one line, e.g. `// On OpenHarmony, the sysroot lacks robust-mutex support.`
- `SharedMemoryManager.Unix.cs:418-424` — 3-line OHOS comment plus a `#else` comment that explains the unchanged upstream line ("historical behavior"); drop the `#else` comment and reduce the OHOS one to 1-2 lines (`// OpenHarmony sandboxes mount /tmp read-only; use the TMPDIR-aware temp path.`).
**Fix:** comments-only change, no behavior.

### F3. `IsLinux()` OHOS clause is dead code and obscures the design story (1 instance) 🟡
**Tag:** correctness clarity / minimal-diff (`review-lessons.md` §2/§3: don't add special mechanisms; the OHOS relation to Linux is explained once).
**Impact:** the added `|| TARGET_OPENHARMONY` term invites "why is OHOS special-cased here?" when in fact it is already covered by the Linux family mapping — and that mapping is the argument that supports the agreed `IsLinux() == true`.
**File:** `OperatingSystem.cs:187-192`.
Evidence: `eng/RuntimeIdentifier.props:54` sets `TargetsLinux` whenever `TargetOS == 'openharmony'`, and `System.Private.CoreLib.Shared.projitems:50` defines `TARGET_LINUX` from it. On OHOS, `(TARGET_LINUX && !TARGET_ANDROID)` is therefore **already true**; the new OR term never changes the result. (Same build also defines both `TARGET_LINUX` and `TARGET_OPENHARMONY`, which is why the `#elif TARGET_OPENHARMONY` placement before `#elif TARGET_LINUX` in `OSPlatformName` is load-bearing and correct.)
**Fix:** restore the upstream condition `#if TARGET_LINUX && !TARGET_ANDROID`; if the intent is to document that OHOS belongs to the Linux family, say it in the PR description (or the OSPlatformName comment), not in the preprocessor expression.

### F4. OHOS named mutexes use the NoPThreads fallback — bounded cost, no action (1 instance) ℹ️
**Tag:** performance (warm path: named-mutex create/open/wait).
**Impact:** on OHOS every named mutex takes the shared-file implementation: an extra in-process `Mutex`, a lock file, `FLock` syscalls per acquisition, `Thread.Sleep(1)` permission-race retries (bounded ×10, `SharedMemoryManager.Unix.cs:462,478,712`), and — when infinite waits meet timed waiters — a poll loop capped at `PollLoopMaximumSleepMilliseconds = 100` (`NamedMutex.Unix.cs:526,563`). Zero managed allocation is added, and this is the upstream fallback shape already used by macOS/OpenBSD/Haiku.
**File:** `NamedMutex.Unix.cs:85-87`.
Why this is correct rather than a defect: the native side is compiled against `pal_crossprocessmutex_unsupported.c` for OpenHarmony (`CMakeLists.txt:60-66`), so the pthread path cannot work; the managed and native lists agree (✅ #5). The comment's claim (missing `pthread_mutexattr_setrobust`/`pthread_mutex_consistent` in the musl sysroot) is consistent with that gate.
**Fix:** none recommended. Mention the fallback and its contention characteristics in the PR text; if the OHOS sysroot later gains robust mutexes, remove `IsOpenHarmony()` here **and** the `CLR_CMAKE_TARGET_OPENHARMONY` entry in `CMakeLists.txt` together (the file comment mandates sync).

### F5. Test-side polish in `MutexTests.cs` (test-only, cold) ℹ️
**Tag:** minor naming/coverage nit (not CI-catchable; drop if the reviewer wants zero noise).
**File:** `MutexTests.cs:1042-1049`.
- The derivation itself is **verified correct**: `Path.GetTempPath()` honors `TMPDIR` and falls back to `/tmp/` (`Path.Unix.cs:81-93`), and `.dotnet` / `shm` / `global` match `SharedMemoryManager.Unix.cs:16,20,805`, so the helper tracks the runtime for all three affected tests (replacing the previous `RuntimeIdentifier.StartsWith` check is an improvement — no string parsing).
- Nit 1: the platform literal `"openharmony"` uses non-canonical casing/name; prefer `"OpenHarmony"` (case-insensitive, so purely cosmetic) — and since F1 decides the alias, consider one direct assertion of the canonical name (`IsOSPlatform("OpenHarmony")`) so `OSPlatformName` has explicit coverage.
- Nit 2: the 4-line comment could be 2 lines; allocation cost (`Path.GetTempPath` + `Path.Combine` per access) is irrelevant in test code.

## 3. Review-lessons conformance summary

| Check | Result |
|---|---|
| Naming (OpenHarmony only; `IsOpenHarmony`/`TARGET_OPENHARMONY`) | ✔ 0 occurrences of "HarmonyOS" in the four files; identifier names follow the agreed convention |
| Scope (OHOS-only; no collateral changes) | ✔ other platforms restored byte-identical (`/tmp/`), no Android/other edits; `SharedFilesPath` consumers are exactly the two OHOS-touched files |
| Comments | ✖ F2 (verbose; wrong RID claim; fork narrative) |
| Minimal mechanism / precedent | ~ F3 (dead clause); ✔ `#if TARGET_OPENHARMONY` mirrors the `IsHaiku()` precedent rather than runtime probing |
| Linux relation口径 | ✖ F1`(IsOSPlatform("linux")==false` violated) ✔ `IsLinux()==true` |
| Tests for new behavior | ~ only indirect coverage of `OPENHARMONY` (via the shm path helper); nothing pins the alias semantics (F1) |
| No new public API / no Mono dependency / no CI-catchable nits reported | ✔ `IsOpenHarmony()` is `internal`; no Mono coupling |

## 4. Positive findings

- ✅ `OSPlatformName` adds `"OPENHARMONY"` **before** `#elif TARGET_LINUX` — correct and required, because OHOS builds define both `TARGET_LINUX` and `TARGET_OPENHARMONY`.
- ✅ `OperatingSystem.IsOpenHarmony()` (`internal`, `[NonVersionable]`, `#if`-constant) mirrors `IsHaiku()` exactly; no premature public API; the named-mutex guard becomes a compile-time constant.
- ✅ Managed `UsePThreadMutexes` and the native `pal_crossprocessmutex_unsupported.c` gate are synchronized as `CMakeLists.txt:60-64` demands; the added term is the minimum needed (Android is excluded by `FeatureCrossProcessMutex` being off for mobile-like targets).
- ✅ `SharedFilesPath` change is a compile-time, OHOS-only branch; non-OHOS platforms keep the historical `/tmp/` (diff-minimal, easily reviewable). The semantic caveat — `Global\`-scoped shared-memory files become app-sandbox-local on OHOS — is inherent to the read-only `/tmp` sandbox and now also mirrored by the tests.
- ✅ Test helper derivation matches the runtime layout exactly (`.dotnet`/`shm`/`global` under `TMPDIR`), and the previous `RuntimeIdentifier.StartsWith` probe was replaced with the platform API.
- ✅ No allocation or culture regressions introduced: the alias adds one length-mismatched `OrdinalIgnoreCase` comparison (0 allocations, ~free); no LINQ/regex/`params`/`ToLower`/`new collection` in any hunk; 6/6 string comparisons explicit; 5/5 production classes in the touched files sealed/abstract.

| Severity | Count | Top Issue |
|----------|-------|-----------|
| 🔴 Critical | 1 | `IsOSPlatform("linux")` alias on OHOS contradicts the agreed design (F1) |
| 🟡 Moderate | 2 | Wrong/verbose alias comment (F2); dead `TARGET_OPENHARMONY` clause in `IsLinux()` (F3) |
| ℹ️ Info | 2 | OHOS named mutexes use the NoPThreads fallback cost (F4); test-only polish (F5) |

> ⚠️ **Disclaimer:** These results are generated by an AI assistant and are non-deterministic. Findings may include false positives, miss real issues, or suggest changes that are incorrect for your specific context. Always verify recommendations with benchmarks and human review before applying changes to production code.
