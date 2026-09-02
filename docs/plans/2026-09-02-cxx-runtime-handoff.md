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
