# OHOS Upstream PR Plan — Restructured on the BSD/Haiku Landing Model (2026-09-07)

**Status:** Draft for review. Reorganizes the remaining upstream PR backlog
(plan §13 of `2026-08-28-ohos-pr-plan-revised.md`) to match how the OpenBSD and
Haiku ports were actually landed upstream. Built from the merged-PR history of
`label:os-openbsd` (37 PRs, 2026-02→08) and `label:os-haiku` (16 PRs,
2023-05→2026-08), with file-level diffs for the model PRs.

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

## 2. Current OHOS upstream state (2026-09-07)

Open PRs (dotnet/runtime):

- **#132827** sandbox fixes (6 files, libraries+gc) — in review; blocked on
  RID-naming decision (`ohos` vs `openharmony`, jkotas 09-04 leans
  `openharmony`).
- **#132953** infra + RID graph (11 files, eng/+coreclr+RID; +133/-18) —
  jkotas's threads all answered 09-03; awaiting re-review; CI red on runtime
  leg.

Remaining feature-branch inventory (from plan §13 + inclusion audit
`2026-09-03-ohos-pr-inclusion-audit.md`): runtime P3-P7 (≈18 files),
SDK S1 (≈15 files), aspnetcore A1 (≈5 files).

---

## 3. Restructured plan (BSD/Haiku model)

### Runtime — remaining PRs, in submission order

| # | PR (new) | Old name | Files | Modeled on | Size target |
|---|---|---|---|---|---|
| N1 | **R-coreclr-sysroot-clrfeatures** | part of P4 | `clrfeatures.cmake` + `clr.featuredefines.props` (LTTng off) | #124991-style single concern | 1-2 files |
| N2 | **R-coreclr-sysroot-pal** | part of P4 | `pal/src/configure.cmake` + `pal/src/CMakeLists.txt` (no LTTng fatal, skip gcc_s/pthread/rt) | #124992 (pal_io.c) | 2 files |
| N3 | **R-native-sysroot-zstd** | part of P7 | `zstd.cmake` (C90 qsort) | #125546 (gssapi) | 1 file |
| N4 | **R-native-sysroot-libs** | part of P7 | `libs/CMakeLists.txt` + `extra_libs.cmake` (Crypto.Native via OpenSSL, no Net.Security) | #125562 (libs.native subset) | 2 files |
| N5 | **R-native-sysroot-apphost** | part of P7 | `apphost/static/CMakeLists.txt` (skip NATIVE_LIBS_EMBEDDED/Net.Security-Static, WHOLE_ARCHIVE guard) | single-concern | 1 file |
| N6 | ~~**R-native-System.Native-pal_io**~~ **canceled 2026-09-12** | — | `inotify_init1` is not trapped (audit Addendum 2) — no PR needed; guard removed on the feature branch | — | — |
| N7 | **R-native-System.Native-pal_process** | part of P6 | `pal_process.c` (close_range guard) | #124992 | 1 file |
| N8 | **R-native-System.Native-ifaddrs** | part of P6 | `pal_interfaceaddresses.c` (ecmd.speed) | #124992 | 1 file |
| N9 | **R-coreclr-W^X-default** | part of P4 | `clrconfigvalues.h` (W^X default off) | #125902 (cgroups) | 1 file |
| N10 | **R-crossgen-corelib-proj** | part of P4 | `crossgen-corelib.proj` | single-concern | 1 file |
| N11 | **R-AOT-Unix.targets** | P3 slice | `Microsoft.NETCore.Native.Unix.targets` (lld/Net.Security off, `_originalTargetOS`) | **#129906** (1-file NativeAOT) | 1 file |
| N12 | **R-AOT-SingleEntry** | P3 slice | `Microsoft.DotNet.ILCompiler.SingleEntry.targets` (libcFlavor) | #129906 | 1 file |
| N13 | **R-packs** | P5 | `targetingpacks.targets`, `ds-portable-rid.c`, sfxproj (R2R off), ILCompiler.pkgproj | #125088's data slice, kept separate | 3-4 files |

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

### aspnetcore — unchanged

| PR | Content |
|---|---|
| A1 | NativeAOT-for-ohos disable (Directory.Build.props), Dependencies.props ohos RIDs, App.Ref/Runtime suppressions (~5 files) |

### CI leg — LAST (OpenBSD rule 6)

A `runtime (Build linux-ohos-arm64 ...)` leg is planned only after N1-N13 are
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
| Total runtime PRs: P3-P7 = 5 | N1-N13 = **13** | granularity to the OpenBSD norm (median ≈15 lines/PR) |

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

1. **RID naming** (`ohos` vs `openharmony`) — blocks #132827 and #132953, and
   every file below carries the string. jkotas leaned `openharmony` 09-04;
   am11 argued `ohos` 09-01. No reply since 09-04.
2. **illink file** (was P3) — tools/ PR now or later, or fold into N12?
3. **OpenHarmonyCodesign upstream or downstream** — default downstream; needs
   one reviewer statement.
4. **CI leg timing** — OpenBSD waited until feature-complete; confirm we do
   the same rather than adding a leg to #132953.
5. Post this plan to tracking issue dotnet/runtime#132866 for reviewer
   sign-off (am11 requested stacked-PR visibility).
