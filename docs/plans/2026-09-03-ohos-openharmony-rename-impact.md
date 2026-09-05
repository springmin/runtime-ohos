# RID rename impact analysis: ohos → openharmony

**Date:** 2026-09-04 (device side)
**Context:** dotnet/runtime #132827 discussion — jkotas (09-04): "clarify matters more than
brevity. I would go with `openharmony`." jkoritzinsky/am11 have not yet weighed in; the
rename is **NOT final**.
**Scope:** RID/TargetOS **string-value** rename `ohos` → `openharmony` across the three
forks (runtime-ohos, sdk-ohos, aspnetcore-ohos) + published assets + local device feed.

## 0. Structural headline

The compile-time identifiers are **already renamed**: `TARGET_OPENHARMONY`,
`TargetsOpenHarmony`, `CLR_CMAKE_TARGET_OPENHARMONY`, `CLR_CMAKE_HOST_OPENHARMONY`
(38 sites across forks; zero `TARGET_OHOS`/`CLR_CMAKE_TARGET_OS_OHOS`/`FEATURE_OHOS`
remain). What remains is the **string layer**: `TargetOS`/RID value `'ohos'`, RID-graph
keys, RID lists, package-name segments, `PORTABLE_RID_OS "ohos"`. The identifier surface
does NOT need touching.

Word-boundary note: `\bohos` substring hits in `cohost`/`tohost`/`utilcodestaticnohost`
are noise; `linux-ohos` remnants exist only in docs/plans (7 files, 149 lines) —
zero in eng/src/CI. `linux_ohos`: zero everywhere.

## 1. runtime-ohos (15 non-doc files; 9 src + 6 eng)

Counts (`\bohos`, case-sensitive, word-boundary; excl .git/artifacts/.dotnet/bin/obj):

| Area | Files | Occurrences |
|---|---|---|
| src/coreclr | 3 | 11 |
| src/libraries | 1 | 7 |
| src/native | 3 | 3 |
| src/installer | 1 | 3 |
| src/tools | 1 | 2 |
| eng | 6 | 34 |
| docs/plans | 8 | 628 |
| src/mono, src/tests, .github, src/tasks | 0 | 0 |
| **Whole repo** | **23** | **688** |

Pattern totals: `\bohos` 23 files/688 occ (incl. 172 `linux-ohos`, all in docs);
`\bOHOS` 17/244; `(?i)openharmony` 40/256; `(?i)harmonyos` 6/67.

### A. RID graph & RID lists (pure replace)
- `src/libraries/Microsoft.NETCore.Platforms/src/runtime.json:2162` — `"ohos": {}`
  standalone base RID (imports nothing — no linux/musl link in graph)
- `runtime.json:2163-2177` — `ohos-arm`/`ohos-arm64`/`ohos-x64` each `#import: ["ohos"]`
- `eng/targetingpacks.targets:48` — CoreCLR framework-pack list adds `ohos-{arm,arm64,x64}`
- `eng/targetingpacks.targets:58` — **Mono-labelled list also carries the 3 ohos RIDs —
  anomaly**: src/mono has zero OHOS code and `eng/Subsets.props:80` says OHOS is
  CoreCLR+NativeAOT only (possible copy-paste artifact — resolve before renaming)
- `eng/targetingpacks.targets:70` — NativeAOT pack list: `ohos-arm64;ohos-x64` (no arm)
- `eng/targetingpacks.targets:77,83` — KnownILCompilerPack/KnownCrossgen2Pack: no ohos
  (host packs — no change)

### B. MSBuild OS/RID property plumbing
- `eng/RuntimeIdentifier.props:57` — **single derivation point**
  `<TargetsOpenHarmony Condition="'$(PortableOS)' == 'ohos'">` → must become new
  portable-OS token
- `:54` TargetsLinux includes ohos; `:58` TargetsLinuxGlibc excludes it (musl libc);
  `:12,52` comments
- `eng/Subsets.props:59` UseNativeAotForComponents disabled for TargetsOpenHarmony;
  `:80-81` OHOS default subsets `clr.nativeaotruntime+clr.nativeaotlibs+clr+libs+host+packs`
- `eng/common/**` — 0 matches (externally-synced tree untouched)

### C. Logic-bearing (NOT blind replace) — highest risk
1. `eng/native/configureplatform.cmake:12-20` — `CLR_CMAKE_HOST_OS` = tolower(
   CMAKE_SYSTEM_NAME). **NDK toolchain always reports `CMAKE_SYSTEM_NAME=OHOS`** →
   blind string rename silently breaks platform detection; must keep matching `OHOS`
   (rename derived var / add alias). `:346-348,367-368` target defaults from host.
2. `src/native/eventpipe/ds-portable-rid.c:15-16` — `#define PORTABLE_RID_OS "ohos"` —
   only native RID string constant emitted into diagnostics IPC payloads; parsed by
   external dotnet-diagnostics/dotnet-trace tooling → rename in lockstep or keep aligned.
3. `src/coreclr/nativeaot/BuildIntegration/Microsoft.NETCore.Native.Unix.targets:59`
   `CrossCompileAbi=ohos` → clang `--target=<arch>-linux-ohos` triple (consumed :82).
   Verify OHOS clang wrappers accept `aarch64-linux-openharmony`; token may stay `ohos`
   internally while RID renames.
4. `.../SingleEntry.targets:10,34-37` — `_originalTargetOS` parsed from RuntimeIdentifier;
   **auto-derives** package names `runtime.<os>-<arch>.Microsoft.DotNet.ILCompiler` and
   `Microsoft.NETCore.App.Runtime.NativeAOT.<rid>` → pack IDs follow the RID for free.
5. `eng/targetingpacks.targets:58` Mono anomaly (see A).

### D. Pure find/replace (string values)
- `eng/build.sh:35,150,314-315,634-635` (help text, rootfs exemption, `--os ohos` case)
- `eng/native/build-commons.sh:10,140-169,631,643` (NDK injection: `OHOS_NDK_HOME`,
  `ohos.toolchain.cmake`, `-DCMAKE_TOOLCHAIN_FILE`, `-DOHOS_ARCH`)
- `eng/native/gen-buildsys.sh:66-67,79-80`; `src/native/libs/build-native.sh:61`
- `SingleEntry.targets:44-51` — ohos → `_linuxLibcFlavor=musl` + `_targetOS=linux`
- `Unix.targets:30` (lld linker), `:167` (exclude System.Net.Security.Native),
  `:59` prefix check
- `src/coreclr/crossgen-corelib.proj:153-159` — `_CrossGenTargetOS` ohos→linux (`--targetos`)
- `src/tools/illink/src/ILLink.Tasks/build/Microsoft.NET.ILLink.targets:59-60` —
  `RuntimeIdentifier.StartsWith('ohos')` → managed NTLM (no GSSAPI in sysroot)
- `src/installer/pkg/projects/Microsoft.DotNet.ILCompiler/Microsoft.DotNet.ILCompiler.pkgproj:47-54`
  — when `PortableOS=='ohos'`, ships libstdc++/libgcc_s from `OHOS_CXXRUNTIME_DIR`
- `src/installer/pkg/sfx/Microsoft.NETCore.App/Microsoft.NETCore.App.Runtime.CoreCLR.sfxproj:29`
  — PublishReadyToRun=false when TargetsOpenHarmony

### No-impact confirmations
- `src/native/corehost` C++ & minipal: no ohos/openharmony RID detection (host RID
  inference never mentions OHOS; only apphost static CMakeLists guard)
- CoreCLR C++ uses `TARGET_OPENHARMONY` macros exclusively (e.g. clrfeatures.cmake:40,
  pal configure.cmake:627-628, numasupport.cpp, clrconfigvalues.h:637-644,
  zstd.cmake:46-47, libs CMakeLists:164-166, pal_io.c:1601-1604 inotify seccomp,
  pal_process.c:294-305 close_range, extra_libs.cmake:27-28 no krb5)
- CI: .github/workflows, .azuredevops, eng/pipelines all exist but **zero** ohos refs;
  es-metadata.yml zero — OHOS CI/packaging driven outside repo
- src/libraries C# (non-graph): only `TARGET_OPENHARMONY` DefineConstants
  (CoreLib.Shared.projitems:57) and `OperatingSystem.IsOpenHarmony()`
  (OperatingSystem.cs:224-228, `#if TARGET_OPENHARMONY`); MutexTests.cs:1044-1047 macro-only

## 2. sdk-ohos (~8 files)

- `eng/PortableRuntimeIdentifierGraph.ohos.json:475-490` — `"ohos": {}` + 3 arch →
  `#import [ohos]` (standalone, mirrors runtime.json). File itself may be renamed
  `.openharmony.json` — sync all consumers.
- `eng/RuntimeIdentifierGraph.ohos.json:4628-4643` — same (full graph)
- `src/Layout/redist/targets/GenerateBundledVersions.targets` — **8 RID-list sites**:
  Net110AppHostRids 295-296, Net110RuntimePackRids 315-316,
  Net110Crossgen2SupportedRids 466-467, Net100/Net110ILCompilerSupportedRids 525-526/
  531-532, Net100/Net110NativeAOTRuntimePackRids 606-607/612-613,
  AspNetCore110RuntimePackRids 635
- `src/Layout/redist/targets/Crossgen.targets:36` — `TargetOS.StartsWith('ohos')`→linux
  remap (crossgen2 whitelist)
- `src/Layout/Directory.Build.props`, `src/Layout/redist/redist.csproj` — TargetOsName/
  OSName==ohos conditions
- `src/Layout/redist/targets/GenerateLayout.targets:22-27` — copies the two graph JSONs
  into SDK layout (`RidGraphOverrideRuntimeJson`/`RidGraphOverridePortableJson`); graph
  filenames must be renamed in sync
- C#: `src/Cli/dotnet/OpenHarmonyEnvironmentDefaults.cs`, `src/Tasks/Microsoft.NET.Build.Tasks/OpenHarmonyCodesign.cs`,
  `src/Cli/dotnet-aot/NativeEntryPoint.cs`, `Program.cs` — identifiers already
  OpenHarmony; audit remaining `'ohos'` string literals individually
- Graph consumption chain: two JSONs → GenerateLayout.targets → SDK layout
  `dotnet/sdk/<ver>/RuntimeIdentifierGraph.json` → NETCoreSdkRuntimeIdentifierChain.
  **SDK graph must change in lockstep with runtime.json** or restore breaks on RID
  mismatch.

## 3. aspnetcore-ohos (4 files, ~12 lines — smallest surface)

- `Directory.Build.props:104-108` — TargetOsName=='ohos' condition (AOT exclude group)
- `Directory.Build.props:188` — SupportedRuntimeIdentifiers contains
  `ohos-x64;ohos-arm;ohos-arm64`
- `eng/Dependencies.props:121-123,146-148` — `_LatestRuntimePackageReference`
  `Microsoft.NETCore.App.Runtime.ohos-{x64,arm,arm64}` + `Crossgen2.ohos-*` — **binds to
  runtime pack IDs; must move in same commit as runtime rename**
- `src/Tools/Directory.Build.props:5` — BundledToolTargetRuntimeIdentifiers ohos-x64/arm/arm64
- `src/Components/Testing/testassets/NativeAotTestApp/NativeAotTestApp.csproj:19-20` —
  PublishAot exclude `StartsWith('ohos-')`

## 4. Published assets + local device state

- release `v11.0.0-rc.1.26451.1-ohos` — 13 assets, **12 carry ohos RID segment**:
  `Microsoft.NETCore.App.Runtime.ohos-arm64.*`, `Runtime.NativeAOT.ohos-arm64.*`
  (incl. stale preview.7 assets), `Host.ohos-arm64.*`, `Crossgen2.ohos-arm64.*`,
  `runtime.ohos-arm64.Microsoft.DotNet.ILCompiler.*` nupkg + 4 tar.gz; tag name itself
- Local device: feed (2 nupkg), `~/.nuget/packages/` (4 ohos package dirs), verified
  publish artifacts — all must be rebuilt/re-verified after rename

## 5. Rename strategy recommendations

1. **String layer across 3 forks (~27 files)** — mostly pure replace (RID graph keys,
   RID lists, build.sh values, remap conditions, ILLink/Crossgen2 shims). NuGet pack IDs
   auto-follow via SingleEntry `_originalTargetOS` derivation.
2. **4 logic decision points handled separately** (Section 1C): CMake detection (keep
   `OHOS` matching), PORTABLE_RID_OS (diagnostics lockstep), CrossCompileAbi (verify
   clang triple or keep internal `ohos` token), Mono RID-list anomaly (confirm deletion).
3. **External contracts stay** (recommended): `OHOS_NDK_HOME`/`OHOS_ARCH`/
   `OHOS_CXXRUNTIME_DIR`, `ohos.toolchain.cmake`, `ohos-assets` — NDK/asset-bundle env
   contracts outside repo RID scope.
4. **Release coordination**: tag, 12 assets, local feed/cache, device verification all
   re-issued in one version; consider compatibility alias if community consumers exist.

## 6. Decision dependencies (before code moves)

- jkotas 09-04 opinion not yet accepted by jkoritzinsky/am11 — wait for decision
- openharmony standalone root vs import linux (determines whether compile-level remap
  shims remain)
- whether `ohos` is kept as a RID alias (transition path)
