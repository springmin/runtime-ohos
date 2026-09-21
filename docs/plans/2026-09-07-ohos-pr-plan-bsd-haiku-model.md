# OHOS Upstream PR Plan — Restructured on the BSD/Haiku Landing Model (2026-09-07)

**Status:** Draft for review. Reorganizes the remaining upstream PR backlog
(plan §13 of `2026-08-28-ohos-pr-plan-revised.md`) to match how the OpenBSD and
Haiku ports were actually landed upstream. Built from the merged-PR history of
`label:os-openbsd` (37 PRs, 2026-02→08) and `label:os-haiku` (16 PRs,
2023-05→2026-08), with file-level diffs for the model PRs.

**Update (2026-09-13):** RID naming **resolved as `openharmony`**; both open PR
branches and all three forks already carry the rename (see §5.1). Remaining
gates: #132953 re-review, the S1c codesign reviewer call, and the upstream
36ef/#133296 R2R-image fix.

**Update (2026-09-14):** re-reviewed against the current feature branch: added
N14-N16 for files that had no PR slot (`tryrun.cmake`, the libraries TFM
mapping, System.Console), marked the `OpenHarmonyInTreeR2R` gate and the
`dotnet selfsign` CLI as fork-local-only (never in PRs), and refreshed the
#132827/#132953 status in §2. The 36ef/#133296 item is resolved on the fork
(decision-table item 5: 27.1 + untrimmed split layout).

**Update (2026-09-21):** upstream/main moved `8f610270d37` (09-15) →
`35423f17d6e` (09-21); all held branches were re-rehearsed clean onto that tip
(§3 "Rebase rehearsal"). The two upstream reminder comments are now posted
(#132953 `#issuecomment-5757951166`, #132827 `#issuecomment-5757951615`) and
#132953 was renamed to the OpenHarmony wording on 09-16. Draft PR texts are
archived in the repo at `docs/plans/2026-09-21-ohos-pr-drafts.md` (the
`/data/.../tmp` copy was stale: old tips/sizes and an N2 body describing the
dropped configure.cmake exemption).

**Update (2026-09-21, arm32):** openharmony-arm (32-bit) was assessed and
**parked** until a 32-bit OHOS device is available for validation (§5 item 6).
Status quo: the RID graph keeps `openharmony-arm` as an addressable RID; the
pack/SDK/aspnetcore lists stay arm64/x64 (N13 `fed16fdbdc9`). Feasibility and
the enablement plan are recorded in
`docs/plans/2026-09-21-ohos-arm32-support-gap.md`.

---

## 1. The reference model — OpenBSD (37 merged PRs, Feb 24 → Aug 7 2026)

### 1.1 Actual landing sequence (merged date, size, one-line scope)

| Phase | PR(s) | Size | Scope | Landing |
|---|---|---|---|---|
| **0. Seed** | #124776 "Add OpenBSD target" | +2/-0 | `eng/build.sh` one case | 02-24 |
| | #124774 "Build mscordac" | +2/-2 | coreclr build | 02-24 |
| | #124775 "Set __NumProc" | +1/-1 | PAL | 02-24 |
| **1. Sysroot fixes, one file per PR** | #124991 pal_error_common.h | +8 | PAL | 02-28 |
| | #124999 minipal/thread.h | +6 | minipal | 02-28 |
| | #125011 "Link pthread" | +2 | build | 02-28 |
| | #124992 pal_io.c | +17 | PAL | 03-02 |
| | #125010 pal_memory.c | +14 | PAL | 03-21 |
| **2. Cross-build infra (first "big" PR)** | #125088 "initial cross-build support" | +133/-20, 14 files | eng/ cmake + targets | 03-04 |
| **3. Follow-up infra + coreclr** | #125089 skip cross-process mutex | +17 | PAL | 03-06 |
| | #125294 CMake definitions | +4 | eng | 03-14 |
| | #125546 gssapi headers | +2 | native libs | 03-14 |
| | #125562 libs.native subset | +79 | eng/libs | 03-16 |
| | #125557 non-portable probing | +26 | corehost | 03-26 |
| **4. Feature completion** | #125902 cgroups unsupported | +2 | PAL | 04-04 |
| | #127205 exception/seh.cpp | +2/-6 | PAL | 04-21 |
| | #127206 map/virtual.cpp | +7 | PAL | 04-21 |
| | #129057 CPalThread | +13 | PAL | 06-06 |
| | #129080 bootstrap build | +422/-123 | big infra | 06-11 |
| **5. Per-library ports** | #129078 Env.WorkingSet | +232 | libs | 06-08 |
| | #129103 getexepath | +14 | minipal | 06-08 |
| | #129124 ICU loading | +31 | native libs | 06-08 |
| | #129470 System.Diagnostics.Process | +622/-19 | libs | 06-24 |
| | #129475 System.Net.Http | +113 | libs | 06-23 |
| | #129479 System.Net.Security | +21 | libs | 06-18 |
| | #129583 FileSystemWatcher | +15 | libs | 06-19 |
| | #129279 Net.NetworkInformation | +133 | libs | 06-24 |
| **6. NativeAOT + tests** | #129906 NativeAOT execute-only | +6/-2, **1 file** | NativeAOT | 06-27 |
| | #129185/129621 test enabling | +8 / +51 | tests | 06-15/24 |
| | #129580 AOT libgssapi link | +2 | AOT libs | 06-19 |
| **7. CI leg — LAST** | #130761 "add openbsd-x64 CI leg" | +32/-4 | pipelines | 07-19 (≈5 mo after seed) |
| | #130449/130478/130547/131986 misc | 1 file each | misc | 07-13→08-07 |

### 1.2 Rules extracted from the OpenBSD sequence

1. **Seed PRs are tiny** (1-2 lines each, 3 on day one). A platform is first
   *named* in the build, nothing more.
2. **Each sysroot compile error is its own PR** (pal_io.c, pal_memory.c,
   pal_error_common.h, thread.h, gssapi — all separate, 2-30 lines).
3. **Cross-build infra is one larger PR** (#125088, 14 files, eng/-heavy),
   but it lands *after* the one-line seed and is followed by small infra
   patches, not bundled into it.
4. **NativeAOT adjustments are single-file PRs** (#129906 = 1 file, +6/-2),
   filed months after the core port.
5. **Per-library ports are split by System.\*** component, each its own PR,
   and they come late (feature-complete phase), sized 15-600 lines.
6. **The CI leg is the last PR**, ~5 months after the seed.
7. Overall cadence: seed → compile fixes → cross infra → feature fixes →
   libraries → NativeAOT/tests → CI. Mostly sequential with small parallel
   batches; nothing waits on a "mega-PR".

### 1.3 Haiku (16 PRs, 2023-05 → 2026-08) — confirms the model

| PR | Scope | Gap |
|---|---|---|
| #86303 "Initial build configuration" | eng/ + coreclr build | 2023-05 |
| #86391 "Configuration support" | eng config | +5 mo |
| #93907 "CoreCLR/PAL support" | coreclr PAL (16 files) | +12 mo |
| #109580 "Initial CoreCLR support" | coreclr | +1 mo |
| #114518-114523 (6 PRs, same week 2025-04) | context register / getexepath / IPC socket / libroot-as-libc / network — **one concern each** | batch |
| #121880 "Initial managed libraries support" | libs (+129) | +12 mo |
| #126701/127392/127502/131700 | native build fixes, flags cleanup | 2026 |

Same shape: config → PAL/CoreCLR slices → libraries → maintenance; small
single-concern PRs dominate; infra and CI wiring are separate.

---

## 2. Current OHOS upstream state (updated 2026-09-21)

Open PRs (dotnet/runtime):

- **#132827** sandbox fixes (6 files, libraries+gc) — in review; RID naming
  resolved as `openharmony`. The last reviewer ask (`akoeplinger` 09-14:
  `IsOSPlatform("openharmony")` in MutexTests) is in the current head
  `6ed2f9ab9a` (09-15); build/test legs green, only the known Helix/infra
  checks fail. **Awaiting approval** (no pending review request); reminder
  posted 2026-09-21 (`#issuecomment-5757951615`).
- **#132953** infra + RID graph (11 files, eng/+coreclr+RID; +134/-18) —
  **@jkotas APPROVED 2026-09-10**, renamed to the final OpenHarmony wording on
  09-16; the remaining review request is with @am11. Build/test legs green;
  only the known Helix/infra checks fail. Reminder posted 2026-09-21
  (`#issuecomment-5757951166`).

Remaining feature-branch inventory (from plan §13 + inclusion audit
`2026-09-03-ohos-pr-inclusion-audit.md`, refreshed 2026-09-14): runtime N1-N16
(≈26 files), SDK S1 (≈15 files), aspnetcore A1 (≈5 files).

---

## 3. Restructured plan (BSD/Haiku model)

### Runtime — remaining PRs, in submission order

| # | PR (new) | Old name | Files | Modeled on | Size target |
|---|---|---|---|---|---|
| N1 | **R-coreclr-sysroot-clrfeatures** | part of P4 | `clrfeatures.cmake` (LTTng off; `clr.featuredefines.props` needs no change) | #124991-style single concern | 1 file |
| N2 | **R-coreclr-sysroot-pal** | part of P4 | `pal/src/configure.cmake` + `pal/src/CMakeLists.txt` (no LTTng fatal, skip gcc_s/pthread/rt) | #124992 (pal_io.c) | 2 files |
| N3 | **R-native-sysroot-zstd** | part of P7 | `zstd.cmake` (C90 qsort) | #125546 (gssapi) | 1 file |
| N4 | **R-native-sysroot-libs** | part of P7 | `libs/CMakeLists.txt` + `extra_libs.cmake` (Crypto.Native via OpenSSL, no Net.Security) | #125562 (libs.native subset) | 2 files |
| N5 | **R-native-sysroot-apphost** | part of P7 | `apphost/static/CMakeLists.txt` (skip NATIVE_LIBS_EMBEDDED/Net.Security-Static, WHOLE_ARCHIVE guard) | single-concern | 1 file |
| N6 | ~~**R-native-System.Native-pal_io**~~ **canceled 2026-09-12** | — | `inotify_init1` is not trapped (audit Addendum 2) — no PR needed; guard removed on the feature branch | — | — |
| N7 | **R-native-System.Native-pal_process** | part of P6 | `pal_process.c` (close_range guard) | #124992 | 1 file |
| N8 | **R-native-System.Native-ifaddrs** | part of P6 | `pal_interfaceaddresses.c` (full ethtool speed: `speed_hi` + unknown normalisation) | #124992 | 1 file |
| N9 | **R-coreclr-W^X-default** | part of P4 | `clrconfigvalues.h` (W^X default off; rationale device-verified 2026-09-14) | #125902 (cgroups) | 1 file |
| N10 | **R-crossgen-corelib-proj** | part of P4 | `crossgen-corelib.proj` | single-concern | 1 file |
| N11 | **R-AOT-Unix.targets** | P3 slice | `Microsoft.NETCore.Native.Unix.targets` (lld/Net.Security off, `_originalTargetOS`) | **#129906** (1-file NativeAOT) | 1 file |
| N12 | **R-AOT-SingleEntry** | P3 slice | `Microsoft.DotNet.ILCompiler.SingleEntry.targets` (libcFlavor) | #129906 | 1 file |
| N13 | **R-packs** | P5 | `targetingpacks.targets`, `ds-portable-rid.c`, sfxproj (R2R off; submit **without** the `OpenHarmonyInTreeR2R` A/B gate), ILCompiler.pkgproj | #125088's data slice, kept separate | 3-4 files |
| N14 | **R-native-tryrun** | (new — not in #132953) | `eng/native/tryrun.cmake` (FIFO cross answers; consolidated 2026-09-14; upstream form **scoped to OHOS** via `CMAKE_SYSTEM_NAME STREQUAL OHOS`) | infra follow-up, #124992-style | 1 file |
| N15 | **R-libs-tfm-mapping** | old "PR-R3" slice | `libraries/Directory.Build.{props,targets}`, `sfx.proj`, `sfx-src.proj`, `sfx-finish.proj`, `shims/Directory.Build.props` (openharmony→linux/unix TFM) | #125562 (build mapping) | 6 files |
| N16 | **R-libs-console** | old "PR-R3" slice | `System.Console.csproj` (unix ConsolePal for OHOS + self-eliminating CA1416) | per-library port | 1 file |

**Positioning for the new slots:** N14 goes with the infra group (right after
#132953, alongside N1-N5); N15/N16 belong to the libraries phase with N15 first
(N16's TFM semantics depend on it).

**Review pass (2026-09-15, A/B):** the redundant `configure.cmake` exemption
was dropped, the ethtool speed fix is scoped to OHOS (Android untouched), the
crossgen/LTTng/version comments were rewritten, `PR-R3` references removed, the
SDK comments tightened, `OpenHarmonyCodesign` errors moved to `Strings.resx`
(NETSDK1247/1248 + 13 xlf), and the signer field renamed to `s_codesignName`.
The `extra_libs.cmake` openharmony clause was first dropped as dead code and
CI run `35034515891` proved it necessary (the static apphost evaluates the
macro) — restored with a comment in `d70f18a5050` (N4 `9e48c9e4a93`). Strict
placement pass: `ElfSigner.cs` moved to the tasks project root (flat layout)
and the sfxproj symbol target renamed `_RemoveDuplicateSymbolFiles`. Tips
updated below; evidence `final-evidence/ab-review-pass-20260915.txt`.

**Prepared (hold until #132953 merges):** fifteen single-concern branches;
fourteen are based on `pr/ohos-infra` (N16 stacked on N15) and **N13 is based
on latest `upstream/main`** (its sfxproj patch context had to track upstream's
WASM R2R refactor — conflict pre-solved: evidence
`final-evidence/post132953-rebase-rehearsal.txt` +
`n13-rebase-resolution.patch`), tips/sizes as of 2026-09-21: N1
`pr/ohos-clrfeatures` `d9428292318` (4+/3-), N2 `pr/ohos-pal` `0f9fcf089c4`
(1 file, 2+/2-), N3 `pr/ohos-zstd` `83dae1c2849` (2+/2-), N4
`pr/ohos-libs-native` `9e48c9e4a93` (9+), N5 `pr/ohos-apphost` `934173210f1`
(13+/4-), N7 `pr/ohos-pal-process` `c5e1dc3e4aa` (5+/2-), N8 `pr/ohos-ifaddrs`
`3eb1ab8f51c` (4+), N9 `pr/ohos-wx-default` `bb7e8e69e76` (4+/2-), N10
`pr/ohos-crossgen-corelib` `169c072d07c` (11+/1-), N11 `pr/ohos-aot-unix`
`91a2e8e5a62` (6+/1-), N12 `pr/ohos-aot-singleentry` `da4dc098a4a` (4+), N13
`pr/ohos-packs` `fed16fdbdc9` (44+/6-), N14 `pr/ohos-tryrun` `c2a5e90db55`
(9+), N15 `pr/ohos-libs-tfm` `01667c2c6d5` (23+/3-), N16 `pr/ohos-console`
`94f72514835` (6+/3-). N13 ships without the fork-local
`OpenHarmonyInTreeR2R` gate; N11 excludes the upstream-only
`IgnoreStandardErrorWarningFormat` attribute; N10's comment is neutralized
for upstream. Submission-ready PR texts (title/body/test), regenerated
2026-09-21: **`docs/plans/2026-09-21-ohos-pr-drafts.md`** (in-repo; the
`/data/.../tmp` copy is stale).

**Post-#132953 follow-ups (prepared, not in the N table):**

| Branch | Trigger | Delta vs `pr/ohos-infra` |
|---|---|---|
| `pr/ohos-tls-flag-cleanup` | after #132953 merges: drop the no-op `-ftls-model=global-dynamic` (§6.1) | 1 file, 3+/3- |
| `pr/ohos-shims-tfm-cleanup` | N15 review decides whether to fold the shims alignment in or land it right after | 6 files, 27+/3- |
| `pr/ohos-illink-ntlm` | after the dotnet/runtime#132866 tools/ ownership answer: separate tools PR or folded into the NativeAOT PR | 1 file, 2+ (base `upstream/main`) |

**Rebase rehearsal (2026-09-21):** re-run in a throwaway worktree against the
current `upstream/main` `35423f17d6e` (the 09-14/09-15 rehearsals were against
`8f610270d37`). Result: **all CLEAN** — `pr/ohos-infra` → `49ff06d3be`; the 13
`pr/ohos-infra`-based N branches (N1, N2, N3, N4, N5, N7, N8, N9, N10, N11,
N12, N14, N15) → `9fa88a8be6`, `7ff38eea4c`, `b3c6c90155`, `47e327066b`,
`8c48f3cb85`, `0b218e389e`, `8c75377751`, `2d71c78d1f`, `80fa4f3374`,
`e21b963ea7`, `729445273c`, `9b2efec3f9`, `39422e0ec6`; N16 →
`77f4ead81d`; N13 → `628239fd4d` (onto `main`) and `67af5e8820` (onto
post-infra; N13 was amended on 2026-09-21 to drop `openharmony-arm` from the
runtime/apphost pack RID lists, then re-rehearsed); follow-ups → `tls-flag-cleanup` `79e964f1bb`, `shims-tfm-cleanup`
`58b546de89`, `illink-ntlm` `86abe3ee71`. Evidence:
`/data/storage/el2/base/tmp/opencode/rebase-rehearsal-20260921.txt`.

**Review-fix pass (2026-09-15):** N15 now defaults `LibrariesBinPlaceTfm` to
`$(NetCoreAppCurrent)-$(TargetOS)` so non-OHOS platforms keep their binplace
items; N13's runtime-pack override is scoped to `TargetsOpenHarmony` and the
ILCompiler package comment/predicate are corrected. N15 re-verified CLEAN onto
latest `upstream/main` (`22b309484bf`).

**Cleanup pass (2026-09-15, P2):** N9's comment drops the dated lab note, N10's
CoreLib R2R comment is neutralized (branch and fork now agree), N1's LTTng guard
comment mentions OpenHarmony; the S1c `ElfSigner` is hardened (EI_DATA check,
size guard — `SHA256.HashData` was reverted for the net472 leg), the dead `ohos`
RID mapping is removed, and the
aspnetcore knowledge base is refreshed. Byte-level `GivenAElfSigner` tests now
cover the descriptor layout, the signature digest, trailing-data preservation
and the strip/re-sign paths.

**CI verification (2026-09-15):** run `34933398693` (runtime+aspnetcore+sdk,
`upload_release=false`) succeeded end to end, confirming the net472 signer fix
and the P0/P1/P2 changes build cleanly.

**CI failure + fix (2026-09-15):** run `34943908275` failed CA1418 in
`test/dotnet-aot.Tests` (it imports the dotnet-aot source list, so it compiles
`OpenHarmonyEnvironmentDefaults.cs`, but lacked the `SupportedPlatform` item);
fixed in sdk `ff67bd67bc` and folded into the S1b branch
(`pr/ohos-sdk-sandbox` `7ac75024d3`); re-run `35030612240`.

**Fork-local, never in PRs:** the `OpenHarmonyInTreeR2R` sfxproj gate and the
sdk `OHOS_IN_TREE_R2R` CI mode (in-tree R2R A/B, archived 2026-09-14), the
`dotnet selfsign` CLI (see the SDK section), the stock-crossgen2 overlay/PGO CI
scripts, and the fork docs/scripts excluded by the inclusion audit.
Fork-private paths were normalized on 2026-09-15: the sdk tooling now lives in
`eng/ohos-install/` (docs in `documentation/ohos-install/`) and the top-level
`installonohos/` directory is gone (evidence
`final-evidence/fork-local-migration-20260915.txt`). Artifact hygiene
(2026-09-16): the obsolete `libnuma-shim.so` + sources were removed (the runtime
embeds the fix) and the two build packs are no longer committed — the build
script downloads them on demand with pinned sha256 checks (evidence
`final-evidence/artifact-hygiene-20260916.txt`).

**Dropped from runtime:** `build-local-linux.sh`, `AGENTS.md` (audit: never
upstream). illink `Microsoft.NET.ILLink.targets` (was in P3) is held out — it
belongs to a tools/ concern and OpenBSD never mixed tools/ into platform PRs
(open question, see §5).

### SDK — one PR, but split submission order

| PR | Content | Note |
|---|---|---|
| S1a (first) | eng RID override graphs (independent ohos) + GenerateBundledVersions ohos RIDs | Pure data; consumable once runtime RID lands |
| S1b (second) | OpenHarmonyEnvironmentDefaults + Program.cs; Layout/redist runtimeconfig baking; dotnet-aot/dn ohos exclusion | Runtime-behavior half |
| S1c (third, **reviewer-gated**) | OpenHarmonyCodesign + selfsign + SDK.targets auto-sign | HarmonyOS-commercial-only; default **downstream** until reviewer call |

**Fork-local (not in any S1):** the `dotnet selfsign` CLI added 2026-09-14
(`src/Cli/dotnet/Commands/SelfSign/*`, the `Commands/SelfSign` Definitions class
with the `DotNetCommandDefinition`/`Parser` wiring, the `ElfSigner.cs` compile
include and `IsElf64` visibility) — it shares the S1c signer source but the CLI
surface is not proposed upstream; revisit only if S1c lands upstream. The
CI overlay/PGO/in-tree-A/B scripts are fork-local as well.

**Review-fix pass (2026-09-15):** the layout workload-manifest guard stays live
(on other platforms) with an OpenHarmony exemption; `OpenHarmonyCodesign` and the
`selfsign` CLI guard directory enumeration (read-only sandbox directories).

**Platform identity (2026-09-15):** S1b uses
`OperatingSystem.IsOSPlatform("openharmony")` plus
`<SupportedPlatform Include="openharmony" />` (CA1418 workaround until OHOS is a
known platform); decision record:
`docs/plans/2026-09-15-ohos-platform-identity.md`. TMPDIR follows the runtime
contract: the SDK does not set it; the install script persists a writable
default in the shell profiles.

**Prepared (2026-09-15):** S1a `pr/ohos-sdk-rids` `39b9eaa403` (5 files
+5192/-4, based on `upstream/main` `530aaa51fa`): the two
`eng/*.openharmony.json` graph snapshots, the `RidGraphOverride*` hook in
`PublishRuntimeIdentifierGraphFiles`, the `GenerateBundledVersions` openharmony
RID lists and the `ResolveReadyToRunCompilers` openharmony→linux mapping. The
`RidGraphOverride*` hook is part of S1a (generic hook + data), not fork-local.
S1b `pr/ohos-sdk-sandbox` `2464f1a835` + `4e1f331c99` (17 files +198/-15) is
stacked on S1a: the sandbox defaults (`OpenHarmonyEnvironmentDefaults`, redist
runtimeconfig baking, tests) and the SDK-build half (layout/installers/workloads/
NativeAOT, package-version overrides). Fork-local bits are excluded (the
`dotnet selfsign` CLI including the `dotnet.csproj` ElfSigner compile include,
docs/scripts/CI); S1c (the signer) stays reviewer-gated. Drafts:
`/data/storage/el2/base/tmp/opencode/pr-drafts-ohos.md`.

**Branch audit + rehearsal (2026-09-15):** all 17 prepared branches are pushed
and match the recorded tips; the contamination scan is clean. `upstream/main`
moved to `8f610270d37` during the audit; #132953's diff still applies CLEAN onto
it and all 15 held branches rebase CLEAN onto the simulated post-merge main
(N16 onto the rebased N15, N13 from the old upstream tip); evidence
`final-evidence/post-merge-rebase-rehearsal-20260915.txt` +
`pr-branches-audit-20260915.txt`. The sdk S1a/S1b branches rehearse CLEAN onto
`aeb6acf36a`. Finding: #132953's title still says "linux-ohos" while the body
and code use the final `openharmony` naming (retitle recommended; title edits
do not reset the approval).

### aspnetcore — unchanged

| PR | Content |
|---|---|
| A1 | NativeAOT-for-ohos disable keyed on the RID (Directory.Build.props), openharmony RID lists (`Dependencies.props` + BundledTool lists, arm64/x64), E2E `PublishAot` guards (NativeAotTestApp, PackageConsumer.App) — 5 files |

**Prepared (2026-09-15):** A1 `pr/ohos-aspnet-rids` `b7070c3748`, based on
latest `upstream/main` (`7b520eb5d3`), 5 files +21/-4. `openharmony-arm` is
dropped from `SupportedRuntimeIdentifiers` (the port ships x64/arm64 only) and
upstream's `fc95d7417c` NativeAotTestApp `DotNetBuild` line is preserved. The
fork's `feature/openharmony` applies the same arm removal and comment sync
(`4faef6a691`). Draft in `/data/storage/el2/base/tmp/opencode/pr-drafts-ohos.md`.

**Branch tips after the A/B review pass (2026-09-15):** N1 `d9428292318`,
N2 `0f9fcf089c4`, N3 `83dae1c2849`, N4 `9e48c9e4a93`, N5 `934173210f1`,
N7 `c5e1dc3e4aa`, N8 `3eb1ab8f51c`, N9 `bb7e8e69e76`, N10 `169c072d07c`,
N11 `91a2e8e5a62`, N12 `da4dc098a4a`, N13 `d2d512a2999`, N14 `c2a5e90db55`,
N15 `01667c2c6d5`, N16 `94f72514835`; `pr/ohos-infra` `cece42439a1` (under
review), `pr/ohos-sandbox-fixes` `6ed2f9ab9a6` (under review). sdk S1a
`pr/ohos-sdk-rids` `3c147cedbc`, S1b `pr/ohos-sdk-sandbox` `d97231e55c`;
aspnetcore A1 `pr/ohos-aspnet-rids` `b7070c3748`.

### CI leg — LAST (OpenBSD rule 6)

A `runtime (Build linux-ohos-arm64 ...)` leg is planned only after N1-N16 are
in, modeled on #130761 (+32/-4, eng/pipelines only). Not part of any earlier PR.

---

## 4. Ordering rationale vs the old plan

| Old plan (2026-08-28/09-03) | New plan | Why |
|---|---|---|
| P3 AOTtoolchain bundled Unix.targets + SingleEntry + illink | N11/N12 split (1 file each), illink held out | OpenBSD #129906 = single-file NativeAOT PR; no tools/ mixing |
| P4 sysroot bundled clrfeatures+pal+W^X+crossgen | N1/N2/N9/N10 (4 small PRs) | OpenBSD rule 2: each sysroot fix its own PR |
| P6 System.Native bundled 3 files | N6/N7/N8 | pal_io.c/pal_process.c/ifaddrs are 3 concerns (model: #124992 per file) |
| P7 native-sysroot bundled 5 files | N3/N4/N5 | per-library/per-file |
| P5 packs (4 files) | N13 kept together (data coherence) | exception to per-file; matches #125088's data inclusion |
| SDK S1 one-shot 15 files | S1a/S1b/S1c split by layer, codesign last | reviewer gate on codesign upstream-vs-downstream |
| — (CI leg absent from plan) | CI leg explicitly LAST | OpenBSD #130761 at +5 months |
| Total runtime PRs: P3-P7 = 5 | N1-N16 = **16** | granularity to the OpenBSD norm (median ≈15 lines/PR) |

**Kept from the old plan:**
- #132827 and #132953 stay as-is (already open; am11 acknowledged the
  libraries-first exception for #132827; splitting open PRs costs more than it
  saves).
- Order principle infra-first (jkotas/am11) is preserved — N1-N5 (compile
  fixes) precede library/native PRs, but each is now independently reviewable.
- N13 depends on N11/N12 (pack layout needs the AOT shape) — same dependency
  the old P5 had on P3.
- Exclusion list from the inclusion audit applies unchanged.

## 5. Open decision points

1. **RID naming — RESOLVED 2026-09-13: `openharmony`.** Both open PR branches
   carry the rename (`pr/ohos-infra` `runtime.json` `"openharmony"` + arch
   RIDs; `pr/ohos-sandbox-fixes` tip `cece42439a1`, rename commit
   `6f124bf2fb7`), and the three forks are in sync (`runtime-ohos`
   `d90f0865d92`, `aspnetcore-ohos` `5a6202d929`, sdk-ohos override graphs).
   Historical note: jkotas leaned `openharmony` 09-04; am11 argued `ohos`
   09-01.
2. **illink file** (was P3) — tools/ PR now or later, or fold into N12?
3. **OpenHarmonyCodesign upstream or downstream** — default downstream; needs
   one reviewer statement.
4. **CI leg timing** — OpenBSD waited until feature-complete; confirm we do
   the same rather than adding a leg to #132953.
5. Post this plan to tracking issue dotnet/runtime#132866 for reviewer
   sign-off (am11 requested stacked-PR visibility). **DONE 2026-09-14** —
   posted as `#issuecomment-5658511943` (N1-N16 inventory + the three open
   reviewer questions).
6. **arm32 (`openharmony-arm`) full support — PARKED 2026-09-21.** No 32-bit
   OHOS device is available for validation, so the pack/SDK/aspnetcore lists
   stay arm64/x64 (N13 `fed16fdbdc9`) and no arm build work starts; the RID
   graph keeps `openharmony-arm` as an addressable RID. Feasibility, the
   enablement plan (`ARM_SOFTFP` for openharmony+arm, NativeAOT armel mapping,
   arm32 signer) and the device readiness checklist are recorded in
   `docs/plans/2026-09-21-ohos-arm32-support-gap.md` — start there when a
   32-bit device (or a 32-bit-capable emulator) arrives.

## 6. Post-merge cleanups (deferred while PRs are in review)

1. **TLS: drop the no-op `-ftls-model=global-dynamic`** — `eng/native/configurecompiler.cmake:667`
   (the file is inside #132953). Keep `-fno-emulated-tls` (line 666) globally: the arm64 asm helpers
   and the JIT hardcode TLSDESC (`vm/arm64/asmhelpers.S:621-630`,
   `pal/inc/unixasmmacrosarm64.inc:424-443`, `jit/codegenarmarch.cpp:3422-3425`,
   `jit/helperexpansion.cpp:940`), so the model must not diverge per TU, and `initial-exec` is not an
   option (faster 2-instruction GOT load, but breaks the contract and risks static-TLS exhaustion).
   Measured with the OHOS NDK clang 15.0.4 (`--target=aarch64-linux-ohos -O2 -fPIC`):

   | flags | generated TLS access |
   |---|---|
   | (default) | `__emutls_v.x` + `bl __emutls_get_address` (emulated) |
   | `-fno-emulated-tls` | TLSDESC (`adrp :tlsdesc:` / `ldr` / `blr`) = global-dynamic |
   | `-fno-emulated-tls -ftls-model=global-dynamic` | byte-identical to the previous row (no-op) |

   Action after #132953 merges: one-line delete (own commit or a small flags-cleanup PR; Haiku
   precedents #126701/#127392/#127502/#131700). Prepared as `pr/ohos-tls-flag-cleanup`
   (rebase-verified 2026-09-21). If a reviewer touches these flags during the
   #132953 review, fold the deletion into the review response instead.

2. **TFM-scoped `KnownAppHostPack` replacement** — `eng/targetingpacks.targets:94`. The broad
   `Remove` deletes same-identity entries for every target framework. Evaluation-time metadata
   conditions are rejected (MSB4190) and a target-based replacement does not run under static-graph
   restore (verified 2026-09-13, CI run 34756598482), so the broad Remove stays until a design that
   survives both restore modes exists.

3. **SDK RID-graph overrides re-check** — `eng/RuntimeIdentifierGraph.openharmony.json` /
   `eng/PortableRuntimeIdentifierGraph.openharmony.json`. These are local bootstrap injections;
   drop them once the upstream Platforms package carries the openharmony RID (inclusion-audit open
   item 1).
