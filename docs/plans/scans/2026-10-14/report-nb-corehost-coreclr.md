# NB — corehost + CoreCLR native (OpenHarmony port, pending upstream submission)

Files reviewed (working tree = `feature/openharmony`, clean @ `dc21ff203a4`):
`src/native/corehost/hostmisc/pal.h|pal.unix.c|pal.unix.cpp|pal.windows.c|pal.windows.cpp`,
`src/native/corehost/fxr/fx_muxer.cpp`, `src/native/corehost/apphost/static/CMakeLists.txt`,
`src/coreclr/minipal/Unix/doublemapping.cpp`, `src/coreclr/utilcode/executableallocator.cpp`,
`src/coreclr/vm/threads.cpp`, `src/coreclr/vm/threadstatics.cpp`, `src/coreclr/vm/eeconfig.h`,
`src/coreclr/inc/clrconfigvalues.h`, `src/coreclr/clrfeatures.cmake`, `src/native/eventpipe/ds-portable-rid.c`
(+ read-only: `src/installer/tests/HostActivation.Tests/SDKLookup.cs`, `eng/native/*`, plan docs under `docs/plans/`).

Fork deltas isolated with `git diff <merge-base 29afde21> HEAD -- <files>` and
`git log --no-merges --author=springmin -p` (commits `9eca9d3ac38`, `1fb5853e49f`, `cfdba659d11`).
Review-lessons checklist applied (`up-rehearse-c3/scan/review-lessons.md`).

---

## Findings

### ❌ Reserved write-barrier page is leaked when the executable commit fails
`src/coreclr/vm/threads.cpp:1207-1215`

`ExecutableAllocator::Reserve()` does not just hand out address space: `ReserveWithinRange` registers the block
(`AddRXBlock`, `executableallocator.cpp:703`) and `Release()` (`executableallocator.cpp:507-589`) is the only path that
returns it to the free list and unmaps it. On the `Commit(...)==NULL` fallback the fork clears `s_barrierCopy` without
releasing it, so the 64 KB reservation (and, in the double-mapped case, the `PROT_NONE` mapping) stays allocated for
process lifetime. Impact is bounded (one page, opt-in `DOTNET_UseGCWriteBarrierCopy=1`) but a reviewer will flag the
missing `Release` — and `Release` is safe on a reserved-but-uncommitted block in both allocator modes.
**Fix:** call `ExecutableAllocator::Instance()->Release(s_barrierCopy);` before `s_barrierCopy = NULL;`.

### ⚠️ Double-map "pre-check" is global, and its fallback silently disables W^X on platforms other than OpenHarmony
`src/coreclr/minipal/Unix/doublemapping.cpp:151-180`, `src/coreclr/utilcode/executableallocator.cpp:290`

The probe has no `TARGET_OPENHARMONY` guard, so every non-Apple platform that enables W^X (Linux glibc, Android,
FreeBSD, …) now pays 2×`mmap`+`mprotect`+2×`munmap` per process and, if that probe fails, silently continues with
`g_isWXorXEnabled = false` (fail-open) plus a new unconditional error line on a previously quiet fallback. Upstream
already fails open when the mapper cannot be *created*, but this adds a new, permission-class failure mode that turns a
security hardening off on platforms where the real mapping might still have succeeded (probe ≠ real
`mprotect(PROT_READ|PROT_EXEC)` over an existing RW mapping). Per review-lessons §2 (“keep others untouched, follow
existing platform precedent”), scope the probe to `#if defined(TARGET_OPENHARMONY)` (precedent: the RISCV64-only W^X
default) or gate it behind an explicit knob.
**Fix:** wrap the probe (and the “unavailable” log) in `#if defined(TARGET_OPENHARMONY)`, or make the W^X downgrade opt-in.

### ⚠️ corehost “optional” conflates “not published” with “present but unusable”
`src/native/corehost/fxr/fx_muxer.cpp:86-92`, `src/native/corehost/hostmisc/pal.h:234-239`

`try_invoke_aot_sdk` already returns early when the file does not exist (`fx_muxer.cpp:80`), so the newly demoted case is
exactly “`libdotnet-aot` exists but cannot be loaded”. After this change a stale/ABI-mismatched AOT SDK produces no
visible diagnostic at all (info only, i.e. only with `DOTNET_HOST_TRACE`), so a broken SDK layout silently costs the
AOT fast path on every launch. The commit’s justification (“stale or mismatched file can be left behind”) is the
debatable part, not the mechanism. Cross-platform coverage (unix + windows) and the doc/test work are compliant with
review-lessons §4.
**Fix:** keep info level for the absent case (already handled) and report present-but-unloadable at warning level
(or keep error), so real misconfiguration is not hidden.

### ⚠️ TLS fast-path change: rationale in the comment is not the real reason, and the evidence is harness-level
`src/coreclr/vm/threadstatics.cpp:1026-1031`

OpenHarmony and linux-musl share the same libc/TLS machinery; “built with native (non-emulated) TLS” describes Android,
not the musl early-out, so the carve-out is not justified by that property — what actually makes it safe is the probe
(and the fork’s own doc records the probe returning 0 on today’s OHOS musl, i.e. **no behaviour change**). Evidence is a
scratch harness “mechanically extracted from threadstatics.cpp” (`docs/plans/2026-09-23-ohos-tls-policy.md` §4), not an
in-tree/device run; per review-lessons §2/§3 (concise, accurate comments; don’t add platform-specific mechanisms without
a documented reason) upstream will either ask “why not musl in general?” or “no benefit, drop it”.
**Fix:** state the real invariant in ≤2 lines (“probe validates the resolver; current OHOS libc resolves dynamically →
unchanged”) or keep this change fork-local until the fast path can actually engage.

### 💡 Probe errno can be stale / from another call
`src/coreclr/minipal/Unix/doublemapping.cpp:157-176`

`errno` is sampled before `canDoubleMap` is evaluated and re-sampled after the two `munmap`s; when one `mmap` succeeds
and the other fails, the successful syscall may clobber `errno`, so the printed value can be wrong. The whole point of
WX-PATCH2 is the diagnostic, so a wrong errno undermines the only observable signal.
**Fix:** capture `errno` immediately after each failing call (or `mmap` RW first, check it, then probe RX).

### 💡 `sysconf(_SC_PAGE_SIZE)` result is not validated
`src/coreclr/minipal/Unix/doublemapping.cpp:156`

A `-1` return is cast to `size_t` → `SIZE_MAX` → `mmap` fails → probe returns false → double mapping (and hence W^X) is
disabled on a machine that supports it. `sysconf` failure is improbable, but the new code turned a cosmetic value into
a silent feature switch.
**Fix:** fall back to a default page size (or skip the probe) when `pageSize == 0 || pageSize == (size_t)-1`.

### 💡 One condition produces two error lines, and the probe overlaps the project’s own default
`src/coreclr/minipal/Unix/doublemapping.cpp:176`, `src/coreclr/utilcode/executableallocator.cpp:290`, `src/coreclr/inc/clrconfigvalues.h:637-643`

On OpenHarmony the W^X default is already 0, so `CreateDoubleMemoryMapper` is not even called unless a user/host sets
`DOTNET_EnableWriteXorExecute=1`; in that case the probe logs “cannot be made executable” and `Initialize()` immediately
logs “Double mapping … unavailable” for the same event. Also note the *other* half of WX-PATCH2 can barely fire: on the
non-double-mapped path `Commit()` requests `PAGE_READWRITE` (`executableallocator.cpp:499-503`), not exec, so the
Commit check is only reachable through the double-mapped path that the probe already screens. The commit narrative
should say this plainly (defence in depth for `xwe=1`, not a second fix), otherwise a reviewer sees two overlapping
changes.
**Fix:** drop or merge the duplicate message, and state the probe↔default-0 relationship in the commit/PR description.

### 💡 `AotSdkCannotBeLoadedFallsBackToManagedSdk` can pass without exercising the probe
`src/installer/tests/HostActivation.Tests/SDKLookup.cs:1204-1223`

The injected failure is real (a text file at the exact probed path, per-test layout so no cross-test pollution) and the
assertion works only without host tracing, which is a sound design given `trace_error` is unconditional and
`trace_*_v` share one stream. But it asserts only the *absence* of `"Failed to load"`, so it also passes if the AOT
probe was never reached (e.g. SDK resolution picks another directory) — it cannot distinguish “demoted” from “not
attempted”.
**Fix:** additionally assert the managed fallback ran (e.g. stdout marker of the mock SDK, or
`NotHaveStdOutContaining("mock AOT SDK invoked")` as `DispatchToAotSdk` does).

### 💡 TLS probe result is not cached, and it is now on OHOS’s JIT path
`src/coreclr/vm/threadstatics.cpp:1039-1041`, `src/coreclr/jitinterface.cpp:1228,1442`

`CanJITOptimizeTLSAccess()` is called per field-access query (not per thread — the fast-path area has no thread-creation
cost), and each call re-runs `IsValidTLSResolver()`: ~7 instruction reads + a call to the asm helper + 2 loads. Linux
arm64 already pays this, so it is not an OHOS-specific regression, but if the intent is the H3 performance item the
probe should be memoised once the result is known (separate change; don’t bundle).
**Fix:** cache the probe result in a function-local static (or at JIT-init) when this area is next touched.

### 💡 `eeconfig.h` gains a runtime setter for an init-only knob
`src/coreclr/vm/eeconfig.h:399-403`

`fIsWriteBarrierCopyEnabled` is otherwise written once from config during `EEConfig::Init`; adding a public setter makes
a config value mutable at runtime. It is currently safe (single-threaded `InitThreadManager`, before
`writebarriermanager.cpp` / `arm/stubs.cpp` / `jitinterfacex86.cpp` read the getter, and every `s_barrierCopy` consumer
is gated on the same flag), but upstream may prefer the fallback decision to live in the allocator/barrier-copy creation
site instead of mutating config.
**Fix:** keep as-is with a short comment saying the value is only mutated during EEStartup, or move the decision.
*(confidence: medium — this is a design preference, not a defect.)*

---

## verified-OK

- **corehost PAL plumbing**: `pal_try_load_library` / `pal::try_load_library` are implemented for *every* platform that
  builds hostmisc (`hostmisc/CMakeLists.txt:26-39` picks exactly one of `pal.windows.*` / `pal.unix.*`, and WASI/browser
  take the unix files), so there is no missing-symbol platform; `trace_info_v`/`trace_error_v` exist
  (`trace.c:259,277`) and the new `TRACE_ATTR_FORMAT_PRINTF(2, 3)` indices match the variadic signature; failure still
  leaves `*dll == NULL` on both platforms; no other `pal::load_library` caller changed; the new C symbol is not part of
  any host export list.
- **corehost behaviour test/doc**: `AotSdkCannotBeLoadedFallsBackToManagedSdk` injects a genuine load failure at the
  exact probed path, `sharedfx-lookup.md` documents the added fallback, and unix + windows were changed together
  (review-lessons §4).
- **WX-PATCH2 ordering fix is real and worth upstreaming on its own**: upstream called `Commit()` *before* checking
  `Reserve()`’s result and ignored its return value (`git show 29afde21:src/coreclr/vm/threads.cpp`), i.e. a failed
  `Reserve` could commit at an arbitrary address; the fork’s `Reserve → NULL-check → Commit` is strictly better. The
  `Commit() == NULL` check is not vacuous (`doublemapping.cpp:288-296` returns NULL when `mprotect` fails).
- **WX-PATCH2 fallback is self-consistent**: on failure the code reuses the existing supported configuration
  (`else` branch at `threads.cpp:1261-1272`: `JIT_WriteBarrier_Loc = RhpAssignRef`, `JIT_WriteBarrier_Table_Loc = NULL`,
  identical to `DOTNET_UseGCWriteBarrierCopy=0`), the config write happens in single-threaded EEStartup before any
  consumer, and `GetWriteBarrierCodeLocation` / `IsIPInWriteBarrierCodeCopy` / `AdjustWriteBarrierIP` all re-read the
  same flag, so the NULLed `s_barrierCopy` cannot be dereferenced.
- **WX-PATCH2 probe mechanics**: the probe reproduces the real sequence (reserve maps `PROT_NONE`,
  `CommitDoubleMappedMemory` = `mprotect(R|X)`; both verified in the same file), costs 5 syscalls once at startup, runs
  before any thread exists (no race), closes `fd` on every failure path and leaves the fd owned by `*pHandle` on
  success; the new `if (fd == -1)` diagnostic is only reachable on the Linux/FreeBSD memfd paths (the POSIX/Android
  branch already returned) — asymmetric but not a bug.
- **`clrconfigvalues.h` W^X default**: OHOS joins the pre-existing `TARGET_RISCV64` conditional, sits in the existing
  “Executable code” section (the two “DO NOT ADD ANY MORE CONFIG SWITCHES” sections are lines 729/767, untouched), the
  `#endif` comment matches the `#if` exactly, and the rationale is evidence-backed (fork device matrix: memfd/file RX
  denied in every domain, anonymous RWX works).
- **`clrfeatures.cmake` LTTng exclusion**: `CLR_CMAKE_TARGET_OPENHARMONY` is set before this file is evaluated
  (`configureplatform.cmake:368-370` ← `configuretools.cmake:1` ← `configurecompiler.cmake:1`, and
  `src/coreclr/CMakeLists.txt:5` includes it long before `clrdefinitions.cmake:1` includes `clrfeatures.cmake`), and the
  managed side agrees: `clr.featuredefines.props:44` defaults `FeatureXplatEventSource` only for `TargetOS == linux`,
  while OHOS builds carry `TargetOS=openharmony` (`eng/RuntimeIdentifier.props:52-57`) — so the warning in the comment
  about also changing `clr.featuredefines.props` does not bite.
- **`ds-portable-rid.c`**: `PORTABLE_RID_OS "openharmony"` matches the RID graph
  (`PortableRuntimeIdentifierGraph.json:67-85`, a top-level OS with `openharmony-arm64` etc. and no linux-musl import),
  and the line sits inside the existing `TARGET_UNIX` chain next to Android’s `linux-bionic` precedent.
- **TLS guard plumbing**: the new `&& !defined(TARGET_OPENHARMONY)` clause is live, not dead code (OHOS defines
  `TARGET_UNIX`/`TARGET_LINUX`/`TARGET_LINUX_MUSL`/`TARGET_ARM64`/`TARGET_OPENHARMONY`,
  `configureplatform.cmake:362-370` + `configurecompiler.cmake:859-864`), it only affects OpenHarmony, `IsValidTLSResolver`
  is compiled for OHOS (`threadstatics.cpp:810`) and is fail-safe (requires the exact static-resolver code sequence at
  `threadstatics.cpp:886-906`, otherwise the array indirection stays), and the changed area has no per-thread cost —
  `CanJITOptimizeTLSAccess()` has exactly two call sites, both JIT-time (`jitinterface.cpp:1228,1442`).
- **`static/CMakeLists.txt` OHOS deltas**: all three are platform-guarded — `NATIVE_LIBS_EMBEDDED` mirrors the Android
  exclusion under the shared TODO link, `System.Net.Security.Native-Static` is excluded consistently with
  `System.Net.Security.Native/extra_libs.cmake:27-31` (“no krb5 in the OHOS sysroot; the static apphost still links that
  macro” — which is why the `append_extra_security_libs` guard at line 192 stays), and the `WHOLE_ARCHIVE` workaround is
  OHOS-only with a one-line toolchain-contract comment (review-lessons §1 permits the NDK name there).

## Verdicts

| Area | Verdict |
|---|---|
| corehost optional AOT SDK load (`pal.*`, `fx_muxer.cpp`, test) | **upstream-worthy** — generic, cross-platform-consistent, doc + failure-injection test; fix the severity split (NB-3) first if you want an easy review. |
| WX-PATCH2 (`doublemapping.cpp` probe, `executableallocator.cpp`, `threads.cpp`, `eeconfig.h`) | **needs work, then split** — fix the leak (NB-1); upstream the `Reserve→check→Commit` + `Commit` return check + the `fd == -1` / “unavailable” diagnostics as a small generic PR; keep the pre-check (NB-2) fork-local or scope it to `TARGET_OPENHARMONY`. |
| TLS resolver fast path (`threadstatics.cpp`) | **keep fork-local / needs work** — behaviour-neutral today (probe returns 0), rationale in the comment is wrong, evidence is a scratch harness; either drop it from the upstream batch or re-frame with in-tree evidence. |
| `clrconfigvalues.h` OHOS W^X default 0 | **upstream-worthy as-is** (the fork’s `pr/ohos-wx-default` slice). |
| `clrfeatures.cmake` LTTng guard, `ds-portable-rid.c` | **upstream-worthy as-is** (small, platform-scoped, consistent managed/native, matches RID graph). |

*Out-of-group observation (not scored):* `eng/native/configureplatform.cmake:368-370` derives
`CLR_CMAKE_TARGET_OPENHARMONY` from the *host* OS, so an OHOS machine building a plain `-os linux` target would also get
`TARGET_OPENHARMONY`; it is deliberate for this port (the toolchain contract maps OHOS to linux), but if cross-target
builds from an OHOS host are ever supported, the flag should be derived from `CMAKE_SYSTEM_NAME` instead.
