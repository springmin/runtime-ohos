# Build-side verification checklist: openharmony rename branch

**Date:** 2026-09-04 (device side)
**Branch:** `feature/openharmony-rename` (runtime-ohos `c3b52244033`, sdk-ohos
`fa70203de2`, aspnetcore-ohos `5a6202d929`) - pushed to all three forks.
**Context:** RID/TargetOS string rename `ohos` -> `openharmony` executed and
device-side lightweight verification done. This doc lists what the build side
must rebuild and verify with real compiles.

## What the device side already verified (no rebuild needed)

1. MSBuild property chain: `TargetOS=openharmony` -> `PortableOS=openharmony`
   -> `PortableTargetRid=openharmony-arm64`; `TargetsLinux=true`,
   `TargetsOpenHarmony=true`, glibc excluded - identical to pre-rename `ohos`.
2. NativeAOT SingleEntry derivation: RID `openharmony-arm64` ->
   `_originalTargetOS=openharmony` -> `_targetOS=linux` + musl libc ->
   package names `runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler` /
   `Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64`.
3. NuGet RID-graph consumption: restore with the renamed sdk graph
   (`eng/RuntimeIdentifierGraph.openharmony.json`) recognizes
   `openharmony-arm64`; without it NETSDK1083. Publish then fails only with
   NETSDK1084 (no apphost pack yet) - i.e. the SDK already looks for
   `Host.openharmony-arm64` packs, which do not exist until rebuilt.
4. All StartsWith conditions (illink managed-NTLM, codesign enable,
   aspnetcore AOT exclude, env defaults) match `openharmony*` and reject the
   old `ohos` RID.
5. All 19 changed XML files across the three forks parse; SingleEntry +
   Unix.targets load and remap correctly in MSBuild.
6. Bug found & fixed by the eval: Unix.targets XML comment contained `--`
   (MSB4024 load failure) - fixed in `c3b52244033`.

## What the build side must do

### 1. Rebuild runtime packs with `-os openharmony`
On the Linux build machine, from `feature/openharmony-rename`:

```sh
./build.sh clr.nativeaotruntime+clr.nativeaotlibs+clr+libs+host+packs \
  -os openharmony -a arm64 -c Release
```

Expected new pack IDs (vs the old `ohos-arm64` ones):
- `Microsoft.NETCore.App.Runtime.openharmony-arm64`
- `Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64`
- `Microsoft.NETCore.App.Host.openharmony-arm64`
- `Microsoft.NETCore.App.Crossgen2.openharmony-arm64`
- `runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler`
- `Microsoft.DotNet.ILCompiler` (host-neutral, unchanged)

Verify: `src/libraries/Microsoft.NETCore.Platforms` output runtime.json /
PortableRuntimeIdentifierGraph.json contain the openharmony family; pack
filenames use `openharmony-arm64`.

### 2. Publish the assets to the existing release (or a new one)
Re-issue the 12 RID-named assets (release tag currently
`v11.0.0-rc.1.26451.1-ohos` - decide whether to rename the tag or add a
parallel `-openharmony` tag; old `ohos` assets stay for rollback).

### 3. Rebuild the sdk + aspnetcore against the new packs
- sdk-ohos: layout build with
  `/p:RidGraphOverrideRuntimeJson=$PWD/eng/RuntimeIdentifierGraph.openharmony.json`
  and `PortableRuntimeIdentifierGraph.openharmony.json` (paths updated on the
  branch); verify the SDK layout copies the renamed graphs and the bootstrap
  SDK reports `RID: openharmony-arm64`.
- aspnetcore-ohos: restore resolves `Microsoft.NETCore.App.Runtime.openharmony-*`
  from the local feed (Dependencies.props updated on the branch).

### 4. Device-side publish verification (after packs exist)
The device will re-run `dotnet publish -r openharmony-arm64` against the new
feed and execute the app; RID self-report should read `openharmony-arm64`.

## Known scope boundaries (do not "fix" on the build side)

- `CrossCompileAbi=ohos` in Unix.targets is intentional (clang triple
  `aarch64-linux-ohos`; precedent: linux-bionic RID -> `android24` ABI, Apple
  -> macho/macabi/simulator). Comment cites this.
- `configureplatform.cmake` matching `CMAKE_SYSTEM_NAME=OHOS` is the NDK
  contract (official toolchain hardcodes OHOS) - do not rename.
- `eng/common/` untouched (external sync) - device-native builds need an
  arcade-side change for `init-os-and-arch.sh` (uname reports `HarmonyOS`),
  tracked separately from this rename.
- Mono RID list intentionally excludes openharmony (no Mono-on-OHOS packs;
  CoreCLR+NativeAOT only per jkotas review).
