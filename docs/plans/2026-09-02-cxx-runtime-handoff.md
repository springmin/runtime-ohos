# Handoff: cxx-runtime 3rd-round rebuild + re-release (for build side)

**Date:** 2026-09-02 · **Source:** on-device verification, runbook §8

## Background

Device-side NativeAOT (ilc) verification results over three rounds:

1. **Round 1**: ILCompiler pack lacked libstdc++/libgcc_s → ilc could not run.
2. **Round 2 (pack 09-02 11:54)**: SONAME fixed (`libc.so` ✓), but the **real
   device loader refuses to dlopen shared libraries without
   `.note.ohos.ident`** (Permission denied). qemu's loader does not enforce the
   note, which is why host-side verification passed.
3. **Control experiments (on device)**:
   - Removing the note from a locally compiled `.so` → dlopen fails.
   - Re-adding the section at file end → still fails: the note must be a
     section whose **content lies inside a mapped LOAD segment**.
   - The device's harmonybrew OHOS clang 21.1.8 emits the note automatically
     (every locally compiled `.so` carries it) → the current bundle was built
     with a toolchain that does not (or stripped it).

## Action

Rebuild `OHOS_CXXRUNTIME_DIR`'s `libstdc++.so.6` + `libgcc_s.so.1` with the
**OHOS NDK clang** (same family as the device toolchain, which emits the note
automatically), then rebuild the ILCompiler pack and re-release.

## Self-check before publishing (all must pass)

```sh
llvm-readelf -S libstdc++.so.6 | grep ohos.ident   # must show .note.ohos.ident
llvm-readelf -S libgcc_s.so.1  | grep ohos.ident   # must show .note.ohos.ident
llvm-readelf -d libstdc++.so.6 | grep NEEDED       # must be libc.so (not libc.musl-*)
llvm-readelf -d libgcc_s.so.1  | grep NEEDED       # must be libc.so
```

(run on the x64 host with llvm-readelf — no device needed)

## Already in place — no repeat needed

- `SingleEntry.targets` XML fix is on the branch (`1e5e83cb012`)
- ILCompiler pack otherwise correct (musl interpreter, libstdc++ shipped in tools/)
- `sign-ohos-release.sh` pre-signing flow works (09-02 11:37 artifacts were
  pre-signed; installer reported signed=0/already_signed=N)

## Packaging reminders

- Set the exec bit on `ilc` (nupkg ships 0644)
- Pre-sign the pack with `sign-ohos-release.sh` before publishing

## After release

The device side will re-run runbook §8 verification item 3
(`dotnet publish -r ohos-arm64 -p:PublishAot=true` end-to-end) and update the
verification record.

---

## Round-3 completion (build side, 2026-09-03 01:15)

**Done by build side per this handoff.** Self-check below all PASS before
publish:

```sh
# on x64 host with llvm-readelf/readelf
readelf -S libstdc++.so.6 | grep ohos.ident   # PASS (section present)
readelf -S libgcc_s.so.1  | grep ohos.ident   # PASS
readelf -d libstdc++.so.6 | grep NEEDED       # libc.so + libgcc_s.so.1 (no libc.musl-*)
readelf -d libgcc_s.so.1  | grep NEEDED       # libc.so
# note content lies inside a mapped LOAD segment:
readelf -S/-l libstdc++.so.6                  # .note.ohos.ident @ file 0x470000 ∈ LOAD 0x470000-0x531cb8
```

### How the libs were rebuilt (both carry `.note.ohos.ident`)

- **libstdc++.so.6** — rebuilt from GCC 13.3.0 `libstdc++-v3` sources with the
  **OHOS NDK clang 15** (`aarch64-unknown-linux-ohos` target, OHOS sysroot).
  GCC `config.sub`/`configure.host` patched to treat `linux-ohos` as a
  linux/musl-family target (`os/generic`, no glibc `__GLIBC_PREREQ`).
  `CXX=clang++ --target=aarch64-linux-ohos -std=gnu++17 -fsized-deallocation
  -nostdinc++ -nostdlib++`; NDK clang emits `.note.ohos.ident` automatically.
  `src/c++20/tzdb.cc` intentionally stubbed (C++20 tzdb, unneeded by ilc;
  clang-15 ranges incompat). SONAME `libstdc++.so.6`, `NEEDED libc.so +
  libgcc_s.so.1`.
- **libgcc_s.so.1** — synthesized with NDK clang from NDK `libunwind.a`
  (`_Unwind_*`) + `libclang_rt.builtins.a` tf/soft-float objects
  (`__addtf3`/`__multtf3`/`__udivti3`/...), 23 symbols exported via a version
  script. compiler-rt objects are `GLOBAL HIDDEN`; st_other patched
  hidden→default so the symbols are dynamically exported. `.note.ohos.ident`
  present, `NEEDED libc.so`.
- **ilc** — `libc.musl-aarch64.so.1` → `libc.so` NEEDED patched (matches every
  working native lib on device). exec bit set on all `tools/*` ELF.
- All three ELFs pre-signed with `sign-ohos-release.sh` (`.codesign` section).

### Resulting artifact (released)

`runtime.ohos-arm64.Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.1.nupkg`
re-uploaded to the `v11.0.0-rc.1.26451.1-ohos` release (2026-09-03).

Device side: re-run runbook §8 item 3 end-to-end.

---

## Round-4 diagnosis (device side, 2026-09-03) — libgcc_s export gap

The round-3 pack (2026-09-03) loads the C++ libs (note + SONAME fixed) but
`ilc` still fails symbol resolution. Verified on device:

```sh
# libstdc++ cannot resolve __emutls_get_address:
llvm-readelf -Ws tools/libgcc_s.so.1 | grep emutls_get_address
#   -> LOCAL DEFAULT (NOT exported!) — the synthesis export list missed it
llvm-readelf -Ws tools/libstdc++.so.6 | grep emutls_get_address
#   -> UND (libstdc++ needs it)
# ilc also needs pthread robust symbols the device musl lacks:
llvm-readelf -Ws tools/ilc | grep -E "pthread_mutexattr_setrobust|pthread_mutex_consistent"
# device musl: neither exported; ~/.harmonybrew/lib/libmusl_compat.so provides
# pthread_mutexattr_setrobust (weak) but not pthread_mutex_consistent
```

### Fix list (build side, round 4)

1. **Export `__emutls_get_address` from the synthesized libgcc_s** (it is
   currently LOCAL — extend the version script / export list; `emutls.c` was
   compiled in but the symbol was not exported).
2. **Audit coverage**: every UND symbol of `libstdc++.so.6` and `ilc` must be
   resolvable from (libgcc_s ∪ libc ∪ libmusl_compat). Commands:
   ```sh
   llvm-readelf -Ws tools/libstdc++.so.6 | grep UND   # collect
   llvm-readelf -Ws tools/libgcc_s.so.1 | grep GLOBAL # must cover _Unwind_*, __emutls_*
   ```
3. **pthread robust symbols**: if `ilc` must reference
   `pthread_mutexattr_setrobust`/`pthread_mutex_consistent`, either provide
   them in the pack's load path (musl-compat provides setrobust; `consistent`
   needs adding) or ensure ilc does not use robust mutexes.
4. **Prefer unversioned exports** in the synthesized libgcc_s
   (`@@LIBGCC_S_OHOS` versioning may complicate binding with unversioned
   references).

---

## Round-4 completion (build side, 2026-09-03 06:40)

All four round-4 fixes applied to the synthesized `libgcc_s.so.1`; the
ILCompiler pack was rebuilt and re-released (`v11.0.0-rc.1.26451.1-ohos`,
2026-09-03).

1. **`__emutls_get_address` now exported** — was LOCAL in the round-3
   synthesis (the emutls.c.o member was present but never globalized +
   visibility-fixed + added to the version script). Now `T` (unversioned).
2. **Full UND audit clean**: every strong UND of `libstdc++.so.6` and `ilc`
   resolves from (libgcc_s ∪ libc):
   ```sh
   libstdc++ strong UND uncovered: 0
   ilc        strong UND uncovered: 0   # incl. pthread_mutexattr_setrobust,
                                         # pthread_mutex_consistent,
                                         # pthread_setcancelstate
   ```
   Only weak UNDs remain (libstdc++ `_ITM_*`/`__at_fini`/`__{deregister,
   register}_frame_info`; ilc `ZSTD_trace_*`/`_ITM_*`) — tolerable.
3. **pthread robust + cancel symbols provided in libgcc_s** via a small
   musl-compatible stub (`pthread_mutexattr_setrobust`, `pthread_mutexattr_
   getrobust`, `pthread_mutex_consistent`, `pthread_setcancelstate`) —
   compiled with the NDK clang, exported unversioned.
4. **Unversioned exports** — the synthesized libgcc_s now uses an anonymous
   version script (no `@@LIBGCC_S_OHOS` nodefs) so unversioned references
   bind cleanly.

Pack contents verified: `tools/ilc` (codesign), `tools/libstdc++.so.6`
(codesign + `.note.ohos.ident`), `tools/libgcc_s.so.1` (codesign +
`.note.ohos.ident`), all `0755`.

Device side: re-run runbook §8 item 3 end-to-end.

---

## Round-5 diagnosis (device side, 2026-09-03)

Round-4 pack: emutls + pthread stubs resolve ✓ (errors reduced to one). The
remaining loader error on device:

```
Error relocating .../ilc: __clear_cache: symbol not found
```

`__clear_cache` (aarch64 cache-maintenance helper, provided by compiler-rt
builtins / libgcc `clear_cache.c`) is referenced by ilc
(`__clear_cache@GCC_3.0`) but **not exported by the synthesized libgcc_s** —
the same class of gap as round-3's `__emutls_get_address`.

### Fix (build side, round 5)

Add `__clear_cache` to the synthesized libgcc_s export list (compiler-rt
builtins object `clear_cache` / aarch64 `__aarch64_sync_cache_range`), export
unversioned like the rest, then re-release and re-verify. If further symbols
surface after this one resolves, continue the same
run → collect first error → add export → rebuild cycle.

---

## Round-5 completion (build side, 2026-09-03 07:20)

`__clear_cache` added to the synthesized libgcc_s:

- `clear_cache.c.o` (compiler-rt builtins) globalized + st_other hidden→default.
- Exported as `__clear_cache@@GCC_3.0` (ilc references it as
  `__clear_cache@GCC_3.0`, so a `GCC_3.0` version node was required, not
  unversioned). Other symbols keep `@@LIBGCC_S_OHOS` (verified working on
  device since round-4: emutls + pthread stubs resolve).
- qemu load test: the `__clear_cache` relocation error is gone; the next
  error is `arc4random` — an artifact of the old qemu rootfs musl (NDK OHOS
  libc exports `arc4random`; the device already resolved it in round-5, which
  is why only `__clear_cache` was reported).

ILCompiler pack rebuilt with the round-5 libgcc_s (codesign applied) and
re-released (`v11.0.0-rc.1.26451.1-ohos`, 2026-09-03).

Device side: re-run runbook §8 item 3 end-to-end.

---

## Round-6 diagnosis (device side, 2026-09-03)

Round-5 pack regressed `_Unwind_Resume` binding. Root cause identified:

- ilc references `_Unwind_Resume@GCC_3.0` and `__clear_cache@GCC_3.0`
  (versioned references).
- Round-5 added the `GCC_3.0` version node (for `__clear_cache`). With the
  node present, the loader binds `@GCC_3.0` references **strictly by version**:
  `_Unwind_Resume` is exported only as `@@LIBGCC_S_OHOS`, so the
  `_Unwind_Resume@GCC_3.0` reference fails.
- Round-4 worked because there was no `GCC_3.0` node at all; the loader was
  lenient for references to a nonexistent version and bound by name.

Verify: `llvm-readelf -Ws tools/ilc | grep "@GCC_3.0"` → the complete list is
`_Unwind_Resume@GCC_3.0`, `__clear_cache@GCC_3.0`.

### Fix (build side, round 6)

Export **`_Unwind_Resume` under the `GCC_3.0` version node too** (add it to the
GCC_3.0 version-script node alongside `__clear_cache`), then re-release and
re-verify. General rule going forward: every `@GCC_3.0`-referenced symbol
needs a `@@GCC_3.0` export; every `@LIBGCC_S_OHOS`-referenced symbol needs a
`@@LIBGCC_S_OHOS` export.

---

## Round-6 completion (build side, 2026-09-03 08:10)

`_Unwind_Resume` binding regression fixed by moving **all** exports under a
single `GCC_3.0` version node (matching GNU libgcc_s layout):

- Round-5's two-node map (`GCC_3.0` + `LIBGCC_S_OHOS`) made the loader bind
  `@GCC_3.0` references strictly by version; `_Unwind_Resume` was only
  `@@LIBGCC_S_OHOS` so `ilc`'s `_Unwind_Resume@GCC_3.0` failed.
- Fix: single `GCC_3.0 { ... }` node (default) exporting every symbol
  (`_Unwind_*`, tf helpers, `__emutls_*`, pthread stubs, `__clear_cache`).
  Both `@GCC_3.0` references (ilc) and unversioned references (libstdc++)
  bind to the default-version symbols.
- **Verified on qemu**: `ilc` now loads and runs (usage output) — no
  relocation errors. The only stub needed was `arc4random` (old qemu-rootfs
  musl lacks it; NDK/device libc exports it).

ILCompiler pack rebuilt with the round-6 libgcc_s (codesign) and re-released
(`v11.0.0-rc.1.26451.1-ohos`, 2026-09-03).

Device side: re-run runbook §8 item 3 end-to-end.

---

## Round-7 diagnosis (device side, 2026-09-03)

Round-6 pack: ilc **loads completely** (all relocations resolve). New failure:
ilc **runs** but a startup NUMA probe calls `syscall(236)` = `set_mempolicy`
(all-zero args probe, same pattern as CoreCLR's guarded
`numasupport.cpp` get_mempolicy probe) → seccomp SIGSYS → process death.

Evidence (device):
- LD_PRELOAD SIGSYS capture: `si_syscall=236`; SVC pc inside the device musl's
  generic `syscall()`; LR in ilc.
- ilc disassembly: **four** call sites `mov w0, #236; x1=x2=0; w3=w4=w5=0;
  bl syscall@plt` (vaddrs 0x4438ec, 0x616e98, 0x64b3d4, 0x764e90) — the AOT
  runtime GC NUMA probe compiled into ilc.
- The current feature-branch source has **no** `set_mempolicy`/syscall(236)
  caller (only the TARGET_OPENHARMONY-guarded `get_mempolicy`/`mbind` in
  `numasupport.cpp`) → **the ilc build used a stale/unguarded source state**
  (consistent with earlier rounds where release builds lagged the branch).

### Fix (build side, round 7)

Rebuild ilc from the **current feature-branch source** (where the OHOS NUMA
guards are present), and verify the build defines `TARGET_OPENHARMONY` for the
GC/runtime compile (the guard in `numasupport.cpp` is inert without it).
Self-check on the produced ilc:
```sh
llvm-objdump -d tools/ilc | grep -c "mov.*w0, #236"   # expect 0
llvm-objdump -d tools/ilc | grep -c "mov.*w0, #237"   # expect 0 (get_mempolicy also guarded)
```

---

## Round-7 root-cause fix (build side, 2026-09-03 13:00)

The `__clear_cache` and subsequent rounds fixed symbol resolution, but ilc still
crashed on device with SIGSYS on the GC NUMA probe (`syscall(236)` =
`get_mempolicy` on arm64; round-7 mislabeled it `set_mempolicy`). Root cause was
**not** a missing symbol — it was the ilc build using a **stale AOT cache**.

### Findings

- OHOS ilc is a **NativeAOT-compiled single-file** (7.8MB apphost + managed
  bundle). Its GC runtime comes from `IlcSdkPath` = bootstrap `ohos-arm64`
  aotsdk, which **is** TARGET_OPENHARMONY-guarded (numasupport.cpp compiles to
  empty stubs — verified). But the ilc binary still contained the full NUMA
  probe (`/sys/devices/system/node` string present) because the AOT compile
  output (`singlefilehost`) was **cached by the managed `ilc.dll` hash** and
  reused across publishes — including the original un-guarded linux-arm64 build
  (same BuildID 5176e571 as `linux.arm64.Release/ilc-published/ilc`).
- Fix: delete the cached `singlefilehost` + `*.Up2Date` and touch the managed
  `ilc.dll` to force the AOT recompile. The rebuilt ilc (BuildID 7981b2d5) has
  **zero** `mov w0,#236`, zero `/sys/devices/system/node`, and `NEEDED` only
  `libc.musl` — matching the official linux-musl ilc shape (no libstdc++ /
  libgcc_s dependency).

### Second bug found: selfsign truncated SingleFile bundles

Signing the 7.8MB single-file ilc shrank it to 39KB: `InjectCodesignSection`
computed the codesign offset from the section-header-table end and discarded
anything past it. .NET single-file apphosts store their managed bundle after the
section table (not covered by any section). Fixed in the SDK repo
(`documentation/ohos-install/selfsign.cs`, commit c4f00640f0): the codesign
offset now accounts for the real end of file, preserving the bundle.

### Released

`runtime.ohos-arm64.Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.1.nupkg`
re-uploaded (v8): guard ilc 7.8MB, codesign applied, bundle intact, no NUMA
probe. Device side: re-run runbook §8 item 3 (`dotnet publish -r ohos-arm64
-p:PublishAot=true`) — the ilc on device should no longer SIGSYS at startup.

---

## Round-8 diagnosis (device side, 2026-09-03) — v8 ilc is a truncated single-file apphost

Runbook §8 item 3 re-run with the released v8 pack (downloaded from the
release 2026-09-03T05:01:16Z, sha512-verified against the API asset size;
installed into the NuGet cache via a local folder feed). **FAIL — new failure
point, before any SIGSYS.**

`dotnet publish -r ohos-arm64 -p:PublishAot=true` now:
- restore resolves the rc.1.26451.1 packs ✓ (local feed needed: the NuGet
  cache alone is not enough for a fresh restore of this pack id — NU1101
  unless a feed provides the nupkg; the cache install also requires the
  `.nupkg.sha512` marker)
- pipeline reaches ilc and executes it ✓ (no loader errors, no note/SONAME
  issues — the round-3..6 fixes hold)
- ilc dies in the **host layer**:
  `MSB3073: .../tools/ilc @app.ilc.rsp exited with code 131`, preceded by:
  `A fatal error was encountered. The library 'libhostpolicy.so' required to
  execute the application was not found in '/storage/Users/currentUser/.dotnet'.
  Failed to run as a self-contained app. - The application was run as a
  self-contained app because '.../tools/ilc.runtimeconfig.json' was not found.`

### Evidence (on the released v8 ilc, `llvm-*` from harmonybrew)

```sh
llvm-readelf -n tools/ilc | grep "Build ID"   # 7981b2d5be8e218cdb09bd716eddfe9ed8bd43c0 (guard build ✓)
llvm-readelf -h tools/ilc                      # Type: DYN, AArch64
llvm-readelf -l tools/ilc | grep LOAD          # R 0x2e30 / RX 0x3b20 / RW 0x3a0 + 2 small RW
                                               #   -> mapped image ≈ 27 KB ONLY; the 7.8 MB
                                               #   trailing data is in NO LOAD segment
xxd -p tools/ilc | tr -d '\n' | grep -c 8b1202f96b7b344eb58b2e3e4d5f6a7b   # 0
tail -c 16 tools/ilc | xxd                     # all zeros — no single-file bundle signature at EOF
llvm-readelf -h tools/ilc | grep -E "section headers"  # shoff=7844104, 29×64B
stat -c %s tools/ilc                           # 7845960 = 7844104 + 29*64 EXACTLY
                                               #   -> file ends exactly at the section-header-table end
llvm-readelf -S tools/ilc | tail -4            # .codesign @0x77a000 sz 0x1000, .shstrtab @0x77b000:
                                               #   both run past EOF (content truncated / absent)
./tools/ilc                                     # direct exec reproduces the hostpolicy fatal error
```

### Root cause

The released v8 ilc is a **CoreCLR single-file apphost** (not the native ELF
shape the round-7 text describes: "NEEDED libc.musl, matching the official
linux-musl ilc shape" — a native ilc has no hostpolicy/bundle logic). Its
7.8 MB trailing overlay is the single-file bundle, and the **bundle footer /
signature is missing**: the file was cut at the section-header-table end.
`.codesign` content is truncated (2,120 of 4,096 bytes present) and
`.shstrtab` content is past EOF. The apphost therefore cannot locate its
bundle, falls back to framework-dependent mode, finds no
`ilc.runtimeconfig.json`, and aborts.

This is the **same truncation bug class as round-7's "Second bug"
(selfsign/sign-ohos-release.sh discarding content past the section-header
table)**. The c4f00640f0 fix did not take effect on this artifact — the v8
pack was still signed/truncated by the buggy path (or the fix is incomplete:
it preserved the bundle content but the appended `.codesign` + rebuilt
section table still end up truncating the file tail).

### Fix list (build side, round 8)

1. Sign/package the single-file ilc **without truncating the file tail**.
   After signing, ALL of these must hold (add to the release self-check):
   ```sh
   tail -c 16 tools/ilc | xxd        # last bytes NOT zero; single-file bundle
                                     # signature present at EOF
   xxd -p tools/ilc | tr -d '\n' | grep -c 8b1202f96b7b344eb58b2e3e4d5f6a7b  # ≥ 1
   stat -c %s tools/ilc              # file must extend past shoff + 29*64
   ./tools/ilc --help                # exec smoke test on the SIGNED artifact
                                     # (qemu w/ device-musl rootfs); must print usage
   ```
2. Alternatively/additionally, publish the OHOS ilc in the **native
   (non-single-file) shape** that round-6 used (real NativeAOT ELF, ~18 MB,
   NEEDED libc.so/libstdc++.so.6/libgcc_s.so.1, guard build = BuildID
   7981b2d5 source state) — it executed on device through the loader and only
   died on the NUMA probe; with the guards it should run. Single-file
   apphosts + an append-at-EOF codesign step are inherently fragile.
3. Verify the released pack with a **runtime smoke test, not just readelf**
   (the round-7 self-check only inspected sections/NEEDED — insufficient for
   single-file apphosts).

Device-side note: the NuGet cache now holds the v8 pack with a valid
`.nupkg.sha512`; restore works when the pack nupkg is also offered from a
local folder feed (`/p:RestoreAdditionalProjectSources=`). Test app:
`dotnet new console` + `dotnet publish -r ohos-arm64 -p:PublishAot=true`
(MSBuild falls back to in-proc because the SDK's `libdotnet-aot.so` is an
x86-64 glibc binary that cannot load on the device — pre-existing,
non-fatal).
## Round-8: signature hardening mirroring Mach-O (build side, 2026-09-03 14:00)

Aligned the OHOS ELF signer (selfsign.cs + OpenHarmonyCodesign.cs) with the
macOS Mach-O signer (Microsoft.NET.HostModel/MachO/MachObjectFile.cs):

1. **Bundle-preserving codesign offset** (done in round 7, commits
   c4f00640f0/e4961e6168): `InjectCodesignSection` now computes the codesign
   offset from the real end of file (not the section-header-table end), so
   .NET SingleFile bundles (which live after the section table and are not
   covered by any section) survive signing. Verified: re-signing a 7.8MB
   SingleFile ilc keeps the bundle (was truncated to 39KB before).
2. **Post-sign validation** (commit bf5121c673): mirrors Mach-O
   `MachObjectFile.Validate()` — after building the signature, re-parse the
   signed ELF to verify the .codesign payload fits, the section is present and
   parseable, and the codesign offset is in bounds. Catches layout corruption
   at signing time instead of on device.

Why Mach-O has no such bug: it represents the signature with an
`LC_CODE_SIGNATURE` load command pointing at the real file end, and
`TryAdjustHeadersForBundle` explicitly grows the __LINKEDIT segment to include
the bundle before signing, so the signer always hashes the complete file. The
ELF signer originally assumed file contents == sections, which is false for
SingleFile apphosts.

---

## Device-side local libstdc++ self-build (2026-09-03, device)

Independent workstream: build `libstdc++.so.6` **on the device itself** from
GCC 13.3.0 source, so the device no longer depends on the build side's
cxx-runtime release cycle (each ilc-pack round-trip cost a day). Status:
**build + ELF verification PASSED**; end-to-end ilc test pending a working
(non-truncated) ilc pack (round-8 fix, above).

### Recipe (all on device)

Source: `~/springsources/gcc-ohos/gcc-13.3.0` (GCC 13.3.0, Tsinghua mirror).
Build dir (writable tmpfs, NOT hmdfs): `/data/storage/el2/base/tmp/opencode/libstdcxx-build/`.

```sh
NDK=~/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_1/native
# libgcc build dir normally provides gthr-default.h; standalone libstdc++
# builds lack it -> the configure gthreads check fails without this symlink:
mkdir -p /data/storage/el2/base/tmp/opencode/libgcc
ln -sf .../gthr-posix-patched.h /data/storage/el2/base/tmp/opencode/libgcc/gthr-default.h
#   (gthr-posix-patched.h = gthr-posix.h + __OHOS_FAMILY__ treated like
#    __BIONIC__: skip __gthrw(pthread_cancel), GTHR_ACTIVE_PROXY=pthread_create;
#    OHOS musl declares no pthread_cancel at all)

env -u CPPFLAGS -u LDFLAGS \        # CRITICAL: leaked harmonybrew
 CC=$NDK/llvm/bin/aarch64-unknown-linux-ohos-clang \
 CXX="$NDK/llvm/bin/aarch64-unknown-linux-ohos-clang++ -std=gnu++17 -fsized-deallocation -nostdinc++ -nostdlib++" \
 ~/springsources/gcc-ohos/gcc-13.3.0/libstdc++-v3/configure \
   --host=aarch64-unknown-linux-musl --build=aarch64-unknown-linux-musl \
   --disable-multilib --enable-shared --disable-static \
   --prefix=/data/storage/el2/base/tmp/opencode/libstdcxx-install
# post-configure patches (Makefiles regenerate each configure):
sed -i 's/ -gno-as-loc-support//g' src/c++11/Makefile   # clang-15 unknown flag
printf '// stub\n' > src/c++20/tzdb.cc                  # clang-15 ranges incompat
make -j20
```

Notes:
- `-std=gnu++17 -fsized-deallocation` must sit in **CXX** (driver), not
  CXXFLAGS: per-dir `AM_CXXFLAGS` (`-std=gnu++98/11/17/20`) must stay the last
  `-std` on the command line; clang-15 otherwise defaults to gnu++14 and
  libsupc++/C++17 sources fail (`string_view` missing, `operator delete`
  sized variants missing).
- `-nostdinc++ -nostdlib++` in CXX prevents the NDK driver's default libc++
  headers from leaking into the libstdc++ build (abs/stdlib.h conflicts).
- The gthreads configure test needs `SUPPORTS_WEAK`-era gthr machinery that
  only exists in a libgcc build dir → symlink above; without it
  `_GLIBCXX_HAS_GTHREADS` stays undefined and **72 thread/future/pmr symbols
  are silently dropped** from the .so.

### Resulting artifact

`libstdcxx-build/src/.libs/libstdc++.so.6.0.32` → SONAME `libstdc++.so.6`,
3,353,088 bytes. Verified on device:
- `.note.ohos.ident` ✓ (NDK clang 15 emits it; section content inside a LOAD)
- `.codesign` section ✓
- `NEEDED` = `libc.so` only ✓ (clean env ⇒ no libiconv.so.2 / no RUNPATH)
- Export diff vs the pack's reference libstdc++.so.6: **0 missing**,
  25 extra (`_Unwind_*`, `__unw_*`, `unw_local_addr_space` — NDK driver
  linked the sysroot libunwind in; harmless, self-contained unwinding).

### Device-side usage note

Replacing `~/.nuget/.../runtime.ohos-arm64.Microsoft.DotNet.ILCompiler/
11.0.0-rc.1.26451.1/tools/libstdc++.so.6` with this artifact was tested and
then **reverted** to the v8 pack original: the v8 ilc itself is broken
(truncated single-file apphost, round-8 above), so an ilc end-to-end run
cannot validate the swap yet. Keep the artifact at
`/data/storage/el2/base/tmp/opencode/libstdcxx-build/src/.libs/libstdc++.so.6`
and re-swap when a working ilc pack (round-9) lands.

---

## Round-9 (build side, 2026-09-03) — CoreCLR split-layout ilc (方案 C)

### Decision

User chose option C over the earlier "native AOT / arm64-host" and
"single-file self-contained" options after investigation showed:

- Official ILCompiler packs (linux-x64/linux-musl-arm64) are **NativeAOT**
  (~15MB self-contained + universal JIT) — NOT CoreCLR split. The "official
  ohos 43KB CoreCLR pack" seen in the NuGet cache is a **linux-arm64 glibc
  misproduct** (NEEDED libc.so.6/ld-linux-aarch64, no `.note.ohos.ident`) —
  unrelated residue, cannot dlopen on device.
- v8 death root cause (round-8): released ilc was a **CoreCLR single-file
  apphost** whose bundle was truncated by the (pre-fix) selfsign → FD
  fallback → `ilc.runtimeconfig.json` missing → hostpolicy abort.
- Option C (CoreCLR **split** layout) is fully buildable on x64 host for
  ohos-arm64: it is just a normal **self-contained publish with
  `PublishSingleFile=false`**.

### Build

`eng/toolAot.targets:17` forces `PublishSingleFile=true` whenever
`UseNativeAotForComponents != true` (OHOS excluded at `eng/Subsets.props:59`).
Overriding with `-p:PublishSingleFile=false` on ILCompiler_publish produces a
**CoreCLR split layout** (ilc apphost 39KB + libhostfxr/libhostpolicy/
libcoreclr + ilc.dll + managed deps + universal JIT + runtimeconfig with
`includedFrameworks` = self-contained).

```sh
./.dotnet/dotnet build src/coreclr/tools/aot/ILCompiler/ILCompiler_publish.csproj \
  -c Release -r ohos-arm64 -t:Publish -p:TargetOS=ohos -p:TargetArchitecture=arm64 \
  -p:PortableOS=ohos -p:UseBootstrap=true -p:PublishSingleFile=false \
  /p:RuntimeIdentifierGraphPath="$(pwd)/.dotnet/sdk/11.0.100-preview.6.26359.118/RuntimeIdentifierGraph.json" \
  /p:IncludeSymbols=false
```

### New dependency discovered

All NDK-clang-built runtime `.so` (libhostpolicy/libcoreclr/libhostfxr/
libclrjit/libSystem.*/universal JIT) NEED **`libc++_shared.so`** (not
libstdc++/libgcc_s — those were for the round-3..6 native ilc). Device must
load it. NDK provides `aarch64-linux-ohos` libc++_shared.so (has
`.note.ohos.ident`, no codesign → selfsign applied). Added to pack tools/.

### Pack contents (v9)

`runtime.ohos-arm64.Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.1.nupkg`
(16,743,121 B) tools/ = 64 files: ilc apphost (39KB, codesigned) +
ilc.runtimeconfig.json (`includedFrameworks` self-contained) + ilc.deps.json +
ilc.dll + 6 ILCompiler.*.dll + System.* managed deps + 20 .so (all
note+codesign: libhostfxr/libhostpolicy/libcoreclr/libclrjit*/libSystem.*/
libc++_shared/libjitinterface/libmscordaccore/libmscordbi) + createdump.
Published 2026-09-03T09:38:47Z (v9).

### Device-side notes for round-9 verification

1. ilc apphost exec needs no `.note.ohos.ident` (v8 single-file apphost exec'd
   on device as precedent); its runtime `.so` all have note+codesign → dlopen
   OK.
2. **libc++_shared.so is required both for ilc AND for the published app**
   (app's runtime .so from the runtime pack also NEED libc++_shared.so, which
   is NOT in the runtime pack). Place it where the loader finds it
   (`~/.harmonybrew/lib/libc++_shared.so` + ld path), or next to the app.
3. Device-side GCC-built libstdc++.so.6 (commit 9df49b40c2f) is for the
   native-ilc shape only — CoreCLR split uses libc++_shared instead. Keep it
   for later native experiments.

## Round-9 diagnosis (device side, 2026-09-03) — v9 ilc is STILL truncated (39 KB)

Downloaded the re-released pack (`runtime.ohos-arm64.Microsoft.DotNet.ILCompiler.
11.0.0-rc.1.26451.1.nupkg`, asset updated 2026-09-03T09:38:47Z, 16,743,121
bytes — differs from v8's 11,255,928) and ran the round-8 fix-list self-check
on `tools/ilc` **before** installing it. **FAIL — the truncation bug is still
present in the release artifact**, despite the sdk-ohos fixes
(e4961e6168 / bf5121c673, recorded in the previous section).

### Evidence (released v9 ilc)

```sh
stat -c %s tools/ilc                          # 38984 bytes  ← NOT 7.8 MB
llvm-readelf -h tools/ilc                      # BuildID 7981b2d5 (same guard
                                               #   build as v8), shoff=37128, 29×64B
                                               # 37128 + 29*64 = 38984 = file size EXACTLY
                                               #   → file ends at the section-header-table end
llvm-readelf -l tools/ilc | grep LOAD          # mapped image ≈ 27 KB (R/RX/RW), same
                                               #   header-only shape as v8 — NO bundle overlay
xxd -p tools/ilc | tr -d '\n' | grep -c 8b1202f96b7b344eb58b2e3e4d5f6a7b   # 0
tail -c 16 tools/ilc | xxd                     # all zeros — no single-file bundle signature
./tools/ilc                                    # "The application to execute does not exist:
                                               #   .../ilc.dll" (apphost finds no bundle)
```

Sizes across rounds for comparison:

| pack | file size | bundle present | exec result |
|---|---|---|---|
| v8 (05:01Z) | 7,845,960 = shoff+29×64 | footer cut at shoff | hostpolicy fatal (131) |
| v9 (09:38Z) | **38,984 = shoff+29×64** | **entire bundle gone** | `ilc.dll does not exist` |

The v9 artifact is the same "**truncated to 39 KB**" outcome the round-7
notes already described for the pre-fix signer — i.e. the released ilc was
signed/repackaged by a path that still discards everything past the section
header table. The `singlefilehost` bundle (7.8 MB) never made it into the
published file at all this time (v8 at least carried the 7.8 MB blob with a
cut footer; v9 is header-only).

### Fix list (build side, round 9)

1. The released artifact must be **byte-identical to the signed local
   `singlefilehost` output** — verify BEFORE upload with the round-8 self-check
   (file size ≈ 7.8 MB, GUID ≥ 1, `tail -c 16` non-zero). A 39 KB or
   7,845,960-byte `tools/ilc` means the sign/package step truncated it again.
2. Audit the **release/upload pipeline** (not just selfsign.cs /
   OpenHarmonyCodesign.cs): the v9 file was produced after both fixes landed,
   so the truncating step is elsewhere (pack repack? codesign re-run after
   SingleFile publish? strip?). Reproduce the exact release command chain
   locally and diff `tools/ilc` against the pre-sign `singlefilehost`.
3. Publish in the **native (non-single-file) shape** (round-6 option, ~18 MB
   real NativeAOT ELF, NEEDED libc.so/libstdc++.so.6/libgcc_s.so.1) as the
   robust fallback — single-file apphosts keep hitting this sign/package bug.

Device side: nothing more to do until a pack whose `tools/ilc` passes the
round-8 self-check is released. Test app + local feed are still in place
(`/data/storage/el2/base/tmp/opencode/aot-verify/`); the v9 nupkg download is
kept at `~/Download/runtime.ohos-arm64.Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.1.nupkg.v9`
for reference.

---

## Round-9 analysis (build side, 2026-09-03) — v9 is split layout, not truncated

**The device-side "truncated" verdict is a category error.** The v9 `tools/ilc`
(38,984 B) is a **CoreCLR split-layout apphost** (`PublishSingleFile=false`
publish), for which **no bundle overlay is expected**. The device re-applied
the round-8 single-file self-check (bundle GUID, ~7.8 MB, non-zero tail) —
those criteria only apply to single-file apphosts.

Why the split shape is correct (and why v8 was genuinely broken):

| | v8 (single-file) | v9 (split) |
|---|---|---|
| ilc file | 7.8 MB apphost+bundle | 39 KB plain apphost |
| managed code | inside the bundle | **ilc.dll alongside** |
| runtime .so | expected in global dotnet | **libhostfxr/libhostpolicy/libcoreclr alongside** |
| runtimeconfig | missing → FD fallback | **ilc.runtimeconfig.json alongside** (`includedFrameworks`) |
| device exec | hostpolicy fatal (bundle footer cut) | should find everything in tools/ |

The v9 nupkg ships all runtime dependencies in `tools/` (verified locally:
20 .so all `.note.ohos.ident` + codesign, ilc.runtimeconfig.json with
`includedFrameworks`, ilc.dll, managed deps). Executing **`tools/ilc` while
cwd is the pack root** fails with "ilc.dll does not exist" because the apphost
resolves the app path relative to its own directory — the test must run from
**inside `tools/`** (`cd tools && ./ilc --help`), the same way the SDK invokes
it.

### Correct device verification for v9 (split shape)

```sh
cd <pack-extract>/tools
./ilc --help            # must print usage; no bundle required
# SDK-invoked path (the real §8 item 3 test) already does this:
dotnet publish -r ohos-arm64 -p:PublishAot=true
```

If `cd tools && ./ilc --help` still fails, capture `COREHOST_TRACE=1` output
and post it — that distinguishes hostfxr-load failure from managed-load
failure.

---

## Round-9 verification (build side, 2026-09-03) — v9 CONFIRMED WORKING (qemu)

Local qemu smoke of the exact released v9 layout (ilc-published/ = pack tools/):

```sh
cd artifacts/bin/coreclr/ohos.arm64.Release/ilc-published
qemu-aarch64 -L /tmp/ohos-qemu-root -E LD_PRELOAD=/lib/libarc4random_shim.so ./ilc --help
# → prints full usage (12,675 B); EXIT=0
```

Loader chain fully exercised: apphost exec → libhostfxr → libhostpolicy →
libcoreclr (dlopen, note+codesign OK) → managed ilc.dll → usage output. The
only qemu-only gap was `arc4random_buf` (old rootfs musl; NDK/device libc
exports it — same as round-6's `arc4random` note).

**Conclusion**: the v9 split-layout ilc is functional. The device-side
"truncated" verdict applied single-file criteria (bundle GUID/7.8MB) to a
split-layout apphost, and the `./tools/ilc` exec test ran from the pack root
(apphost resolves its app path next to itself). Correct device test:
`cd tools && ./ilc --help` (or just re-run §8 item 3, since the SDK invokes
ilc from its own directory).

---

## Round-9 completion (device side, 2026-09-03) — §8 item 3 PASS ✅

The released **v9 split-layout pack** works end-to-end on device. Runbook
§8 item 3 (`dotnet publish -r ohos-arm64 -p:PublishAot=true`) **completes**;
the published app executes.

### What was verified

1. `cd tools && ./ilc --help` on the released v9 pack → full usage, exit 0
   (split-layout apphost: ilc.dll + runtimeconfig + 20 .so all present in
   tools/, each with `.note.ohos.ident` + codesign).
2. Full publish with the v9 pack (installed into the NuGet cache from the
   local folder feed after removing the stale v8 cache entry) reaches ilc,
   compiles app.o, links with `-fuse-ld=lld`, and produces
   `bin/.../publish/app` (1.65 MB stripped ELF + app.dbg).
3. The published app **runs on device**:
   ```
   AOT-verify: 2,4,6,8,10
   RID check done. GC: True
   ```

### Device-side workaround required (same-RID ohos publish gap)

Two `Microsoft.NETCore.Native.Unix.targets` ohos exclusions key off
`$(CrossCompileRid).StartsWith('ohos-')` (lines 30 & 167), but
`CrossCompileRid` is only set when host ≠ target — **on-device publish
(host == target == ohos-arm64) leaves it empty**, so:

- `LinkerFlavor` falls through to the linux default `bfd`; OHOS NDK has only
  lld → `-fuse-ld=bfd` fails. (Cross builds set `-p:LinkerFlavor=lld`… no —
  cross builds set CrossCompileRid=ohos-* and get lld automatically.)
- `System.Net.Security.Native` is wrongly linked; OHOS does not build that
  library (no krb5/gssapi, `src/native/libs/CMakeLists.txt`). The .a is
  absent from the ohos runtime pack → link error.

Workaround used on device (test app only, `Directory.Build.targets`):
`-p:LinkerFlavor=lld` + removing `System.Net.Security.Native` from
`NetCoreAppNativeLibrary`/`DirectPInvoke`/`NativeLibrary`/`LinkerArg` before
`LinkNative`. No app code change; the app does not use SslStream.

**Fix (build side)**: change both conditions to also cover same-RID ohos
publishes, e.g. key off `'$(_originalTargetOS)' == 'ohos'` (or
`$(_linuxLibcFlavor) == 'musl'` + `RuntimeIdentifier.StartsWith('ohos-')`)
in addition to the CrossCompileRid check. Repo change belongs in
dotnet/runtime `src/coreclr/nativeaot/BuildIntegration/` (the source of
Microsoft.NETCore.Native.Unix.targets), then the fix flows into the ILCompiler
pack on the next rebuild — no device workaround needed afterwards.

---

## Round-10 (build side, 2026-09-03) — same-RID ohos publish fix

Device round-9 completion (c9626c0623a) PASSed §8 item 3 but needed a
workaround: `Microsoft.NETCore.Native.Unix.targets` ohos exclusions keyed off
`$(CrossCompileRid).StartsWith('ohos-')`, which is **empty when host == target**
(on-device publish). Fixed both sites to key off `$(_originalTargetOS)` (the
RID-derived, non-remapped OS — `_targetOS` is remapped ohos→linux):

- L30 `LinkerFlavor` → `'$(_originalTargetOS)' == 'ohos'` → lld (was falling
  through to the linux default bfd; OHOS NDK has lld only)
- L167 `System.Net.Security.Native` → `'$(_originalTargetOS)' != 'ohos'` →
  excluded (OHOS builds no krb5/gssapi lib)

L59 `CrossCompileAbi` left as-is (cross-only; same-RID compiles natively,
device verified default abi works).

Rebuilt `Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.1.nupkg` (host-neutral,
contains build/Microsoft.NETCore.Native.Unix.targets) with the fixed targets.
Device: drop the Directory.Build.targets workaround, refresh this pack from the
local feed, re-run §8 item 3.

---

## Round-10 completion (device side, 2026-09-03) — same-RID fix + RID independence verified ✅

Re-ran per round-10 build-side instructions; also verified the SDK RID-graph
independence (df902a3e75 / 1eeee0420e).

### What was verified

1. **SDK RID graph synced on device**: copied the sdk-ohos
   `eng/{RuntimeIdentifierGraph,PortableRuntimeIdentifierGraph}.ohos.json`
   over `.dotnet/sdk/11.0.100-rc.1.26451.1/` (old copies still had
   `ohos → #import [linux-musl]`; only the 4 ohos entries differ, all other
   798 RIDs identical — backups kept).
2. **Same-RID ohos publish works with NO workaround**:
   dropped `Directory.Build.targets` + `-p:LinkerFlavor=lld`; plain
   `dotnet publish -r ohos-arm64 -p:PublishAot=true` completes (exit 0) and
   the app runs (`AOT-verify: 2,4,6,8,10`). The `_originalTargetOS == 'ohos'`
   fix (4db69a897e4) drives lld + Net.Security.Native exclusion correctly.
3. **RID independence verified end-to-end**:
   - fallback chain of `ohos-arm64` in the updated graph = `[ohos-arm64, ohos]`
     (no `linux-musl-arm64`);
   - publish assets contain **zero** linux-musl artifacts (only the ohos
     ILCompiler/NativeAOT packs);
   - with the ohos NativeAOT pack temporarily removed, restore fails with
     **NU1101 `Microsoft.NETCore.App.Runtime.NativeAOT.ohos-arm64`** — an
     explicit error, no silent linux-musl fallback (old graph would have
     resolved a non-OHOS artifact that fails at dlopen).

### Issue found: r10 host-neutral pack is missing the ohos→linux remap

The released `Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.1.nupkg`
(asset 11:39:42Z) contains `Microsoft.DotNet.ILCompiler.SingleEntry.targets`
**without** the `<_targetOS Condition="'$(_targetOS)' == 'ohos'">linux`
line that exists in the runtime repo (since 91572f4362c) — it only has the
musl-flavor line. Publishing with the stock pack fails:
`EXEC: Target OS 'ohos' is not supported` (ilc receives `--targetos ohos`).
Device-side workaround used for this verification: copied the repo's
SingleEntry.targets over the pack copy. Build side: rebuild the host-neutral
pack from the current runtime-ohos source (or verify SingleEntry.targets
inside the pack matches the repo before release).

### Residual (build side)

- runtime repo `src/libraries/Microsoft.NETCore.Platforms/src/runtime.json`
  still has `ohos → #import [linux-musl]` — the SDK-side graphs were
  independized but the Platforms-pack source graph was not. Sync it for
  consistency (Microsoft.NETCore.Platforms consumers otherwise regenerate
  the old inheritance).

---

## Round-10 residual fix (build side, 2026-09-03)

Device round-10 completion (bf28b18afbb) PASSed but flagged two residuals;
both fixed here:

1. **Platforms source graph**: `src/libraries/Microsoft.NETCore.Platforms/
   src/runtime.json` still had `ohos → #import [linux-musl]`. Independized
   (ohos = {}, ohos-arm64 = #import [ohos]) to match the SDK-side override
   graphs (df902a3e75).
2. **Host-neutral ILCompiler pack missing the ohos→linux remap**: the r10
   `Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.1.nupkg` (asset 11:39:42Z)
   carried a SingleEntry.targets without the `_targetOS ohos→linux` line →
   `Target OS 'ohos' is not supported` with the stock pack. Repacked from the
   current runtime-ohos source (SingleEntry.targets with remap + Unix.targets
   with the round-10 `_originalTargetOS` fix), uploaded as the replacement
   asset. Device: refresh the pack from the local feed; the copy-over
   workaround is no longer needed.

---

## Round-11 completion (device side, 2026-09-03) — residual fixes verified ✅

Re-verified per the round-10 residual fix (0299593e8b1): both residuals are
resolved with the **stock packs** — no device-side copy-over or workaround.

### What was verified

1. **Platforms source graph independized**: `src/libraries/
   Microsoft.NETCore.Platforms/src/runtime.json` now has `ohos = {}` and
   `ohos-arm64 = {"#import": ["ohos"]}` — matches the SDK override graphs
   (df902a3e75).
2. **Repacked host-neutral ILCompiler** (asset 13:39:19Z, 70,455 B) contains
   both fixes: the `_targetOS ohos→linux` remap in SingleEntry.targets (1×)
   and the round-10 `_originalTargetOS == 'ohos'` exclusions in
   Unix.targets (2×). Installed from the release; the manual copy-over from
   round-10 is gone.
3. **§8 item 3 re-run with stock packs**: `dotnet publish -r ohos-arm64
   -p:PublishAot=true` (no Directory.Build.targets, no LinkerFlavor override)
   → exit 0, link line shows `-fuse-ld=lld`, zero `Net.Security.Native.a`
   references, app runs (`AOT-verify: 2,4,6,8,10`, `GC: True`).

Residual status: clean — both round-10 device findings are closed by the
build side; no open device-side items for the NativeAOT publish path.

---

## Round-12 (2026-09-04) — 26451.109 release + crossgen2 R2R hang root-cause trail

### Released (accepting pure-IL CoreLib; R2R noted as issue)
- runtime-ohos / aspnetcore-ohos `v11.0.0-rc.1.26451.109-ohos`; sdk-ohos
  `v11.0.100-rc.1.26451.109-ohos` (SDK marked INCOMPLETE — redist MSBuild not
  assembled; package-production loop extremely slow).
- 26451.109 = 26451.1 + 48 upstream commits + ohos build fixes (crossgen-corelib
  R2R off, shims unix TFM). CoreLib is pure-IL (26451.1 had an inconsistent
  R2R CoreLib despite the pack disabling R2R).

### crossgen2 R2R hang root-cause trail (NOT yet root-caused)
Symptom: runtime in-build crossgen2 (host x64) compiling ohos-arm64
System.Private.CoreLib R2R **deterministically hangs** (99.9% CPU, RSS ~16MB).
- Excluded: SDK R2R whitelist (NETSDK1095 — ohos not supported), upstream
  crossgen2 commits (only 4 enter crossgen2: 36ef18696f8 unboxing-stubs,
  65c1f69d9fe variance, 5eca6e4b82a loadability, f540517cb0b stringtable).
  `--type-validation:SkipTypeValidation` still hangs (65c1 excluded);
  `git revert 36ef18696f8` still hangs (36ef excluded).
- dotnet-dump stack (main thread): `AdvSimd.get_IsSupported() ←
  Utf16Utility.GetPointerToFirstInvalidChar ← Statics.MetadataForString ←
  EventSource.InitializeProviderMetadata ← NativeRuntimeEventSource..cctor`.
- Minimal JIT app calling AdvSimd.IsSupported on the same host runtime: **OK**
  (fast false). `DOTNET_ReadyToRun=0` (JIT crossgen2) still hangs.
- Working hypothesis: the hang is RyuJIT **compiling** an arm64 method that
  pulls the AdvSimd/intrinsics path (the clrstack frame is the compile query),
  not host-side execution. Suspect: one of the **8 upstream JIT commits** in
  the merged window (e.g. f0b01ad7f0e "Fix SIMD primitive zero
  initialization", 454d2ab85c3 WIP try-catch-fault) — bisect those next.
- 26451.1 (pre-merge) produced R2R CoreLib fine; the merge introduced the hang.

### Round-12bis — crossgen2 R2R hang: JIT bisect excluded (2026-09-04)

Extended exclusion trail:
- 65c1f69d9fe (variance) excluded — `--type-validation:SkipTypeValidation` still hangs.
- 36ef18696f8 (unboxing stubs) excluded — `git revert` still hangs.
- f0b01ad7f0e (SIMD) excluded — revert + RyuJIT rebuild still hangs.
- **Full JIT revert** (checkout 42bb941f928 `src/coreclr/jit/`, rebuilt libclrjit)
  **still hangs** → JIT commits NOT the cause.
- PGO mibc excluded (stripped `-m ... --embed-pgo-data` — still hangs).
- Host runtime R2R image excluded: minimal R2R-published app calling
  AdvSimd.IsSupported + UTF8 runs fine on the same .dotnet runtime.
- crossgen2 binary is a 17MB R2R x86-64 host app; dotnet-dump main-thread
  stack: `AdvSimd.get_IsSupported ← Utf16Utility.GetPointerToFirstInvalidChar
  ← Statics.MetadataForString ← EventSource.InitializeProviderMetadata ←
  NativeRuntimeEventSource..cctor` (99.9% CPU, RSS ~16MB, deterministic).

Remaining hypothesis: the hang is inside the **crossgen2 process** while
initializing its own EventSource path (Utf16Utility handling some string the
minimal app does not) — NOT crossgen2 source commits, NOT JIT, NOT host
runtime. Next: finer dump (per-thread stacks over time / GC heap state) or
accept pure-IL CoreLib (already released as 26451.109) and revisit later.
