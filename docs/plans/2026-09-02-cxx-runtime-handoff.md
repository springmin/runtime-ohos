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
