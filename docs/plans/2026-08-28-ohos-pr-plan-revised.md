# OHOS Runtime+SDK PR Plan — Revised (2026-08-28, post NativeAOT E2E)

**Status:** PR #132827 (runtime sandbox fixes) in review; NativeAOT end-to-end
verified (qemu); SDK RID declarations + codesign done. This plan revises the
remaining PR split given: (1) runtime NativeAOT BuildIntegration fixes landed
locally, (2) SDK has 19 source changes incl. OhosCodesign, (3) reviewer
feedback (TargetOpenHarmony rename, TMPDIR scoping) is incorporated.

---

## Overview — what exists now

### Runtime repo (`feature/ohos-cross-runtime`), 43 files vs upstream

| Group | Files | Status |
|---|---|---|
| Sandbox fixes | `numasupport.cpp`, `SharedMemoryManager`, `NamedMutex`, `OperatingSystem`, `projitems`, `MutexTests` | **PR #132827 (in review)** |
| Build infra (`-os linux-ohos`, NDK) | `build.sh`, `RuntimeIdentifier.props`, `Subsets.props`, `liveBuilds.targets`, `build-commons.sh`, `configureplatform/compiler/tools.cmake`, `gen-buildsys.sh`, `runtime.proj`, `build-native.*`, `corehost.proj` | local |
| RID graph + packs | `runtime.json`, `targetingpacks.targets`, `ds-portable-rid.c`, `sfxproj` | local |
| sysroot compile fixes | `clr.featuredefines.props`, `clrfeatures.cmake`, `pal/*`, `zstd.cmake`, `libs/CMakeLists.txt`, `extra_libs.cmake`, `pal_interfaceaddresses.c`, `apphost/static`, `System.Native/CMakeLists.txt` | local |
| **NativeAOT BuildIntegration** | `SingleEntry.targets`, `Native.Unix.targets` (4 fixes) | **local (new)** |
| NativeAOT csproj paths | `nativeaot/System.Private.CoreLib.csproj`, `Test.CoreLib.csproj` | local |
| (upstream merge residue) | SmtpClient/Zstandard/async tests | NOT ours — exclude |

### SDK repo (`feature/ohos-cross-sdk`), 19 source files vs upstream

| Group | Files | Status |
|---|---|---|
| RID graph | `eng/RuntimeIdentifierGraph.ohos.json`, `PortableRuntimeIdentifierGraph.ohos.json` | local (dedicated files) |
| RID declarations | `src/Layout/redist/targets/GenerateBundledVersions.targets` (6 ohos RIDs: AppHost/Crossgen2/ILCompiler/NativeAOT) | local |
| Codesign | `OhosCodesign.cs`, `Microsoft.NET.Sdk.targets` (auto-sign) | local |
| OHOS env defaults | `OhosEnvironmentDefaults.cs`, `Program.cs` | local |
| redist runtimeconfig | `redist.csproj`, `GenerateLayout.targets` | local |
| SDK tools AOT exclusion | `Directory.Build.props/targets` (NativeAotSupported=false for ohos), `dn.csproj`, `dotnet-aot.*` | local |
| **RID graph injection** | `Directory.Build.props` (Host/Runtime pack versions flow) | local |

---

## Revised PR split

### Runtime repo (3 PRs after #132827)

#### PR-R2 — Build infrastructure: `-os linux-ohos` + NDK toolchain (16 files)
*Enables cross-build; defines `TargetOpenHarmony` + `TARGET_OPENHARMONY` that everything keys off.*

Same as before (build.sh, RuntimeIdentifier.props, Subsets.props, liveBuilds.targets,
build-commons.sh, configureplatform/compiler/tools.cmake, gen-buildsys.sh, runtime.proj,
build-native.proj/.sh, corehost.proj, System.Native/CMakeLists.txt) — includes the
`UseNativeAotForComponents` OHOS exclusion (crossgen2 stays IL) and `TargetOpenHarmony` naming.

#### PR-R3 — sysroot compile fixes + NativeAOT support (13 files)
*Make OHOS build & AOT publish actually work.*

| File | Change |
|---|---|
| `clr.featuredefines.props` + `clrfeatures.cmake` | Disable LTTng (no LTTng in sysroot) |
| `pal/src/configure.cmake` + `pal/src/CMakeLists.txt` | No LTTng fatal; skip gcc_s/pthread/rt link |
| `native/external/zstd.cmake` | `ZSTD_USE_C90_QSORT=1` (no qsort_r) |
| `native/libs/CMakeLists.txt` | Cryptography.Native via OpenSSL cache vars; skip Net.Security (no krb5) |
| `extra_libs.cmake` | No LIBGSS for OHOS (dlopen) |
| `pal_interfaceaddresses.c` | `ecmd.speed` directly (no ethtool_cmd_speed) |
| `apphost/static/CMakeLists.txt` | Skip NATIVE_LIBS_EMBEDDED + Net.Security-Static; WHOLE_ARCHIVE OHOS-guarded |
| `nativeaot/BuildIntegration/Microsoft.NETCore.Native.Unix.targets` | **NEW: OHOS ABI/lld/Net.Security skip** |
| `nativeaot/BuildIntegration/Microsoft.DotNet.ILCompiler.SingleEntry.targets` | **NEW: libcFlavor ohos→musl** |

#### PR-R4 — RID graph + packs (4 files)
*runtime.json, targetingpacks.targets, ds-portable-rid.c, sfxproj (R2R off).*

### SDK repo (2 PRs)

#### PR-S1 — OHOS RID support + codesign (14 files)
*Makes `-r linux-ohos-*` usable from the SDK and signs build outputs.*

| File | Change |
|---|---|
| `eng/RuntimeIdentifierGraph.ohos.json` + `PortableRuntimeIdentifierGraph.ohos.json` | linux-ohos RID graph |
| `GenerateBundledVersions.targets` | 6 ohos RIDs (AppHost/Crossgen2/ILCompiler/NativeAOT packs) |
| `Directory.Build.props` | flow Host/Runtime pack versions for local dev packs |
| `src/Tasks/.../OhosCodesign.cs` + `Microsoft.NET.Sdk.targets` | auto `.codesign` on build/publish for linux-ohos RID |
| `src/Cli/dotnet/OhosEnvironmentDefaults.cs` + `Program.cs` | OHOS runtime defaults (W^X off, Invariant) |
| `src/Layout/redist/redist.csproj` + `GenerateLayout.targets` | bake OHOS runtimeconfig into redist |
| `src/Cli/dotnet-aot/*` + `dn.csproj` + `test/dotnet-aot.Tests.csproj` | SDK tools AOT exclusion (linux-musl/ohos) |
| `src/Layout/Directory.Build.props` | dotnet-aot is-native-build exclusion for ohos |

#### PR-S2 — NativeAOT publish support in SDK (small, optional)
*If users should `-p:PublishAot=true` from the SDK without manual pack juggling:
BundledVersions already declares the ILCompiler/NativeAOT RIDs, so this is
mostly validation + possibly version alignment. Could be folded into PR-S1.*

---

## Order rationale

1. **Runtime PR-R2 first** (build infra) — enables everything; reviewers need it
   to understand R3/R4.
2. **Runtime PR-R3 second** (sysroot + NativeAOT) — A+C combined now; without it
   OHOS doesn't build or AOT-publish. NativeAOT BuildIntegration is the new
   verified piece.
3. **Runtime PR-R4 third** (RID/packs) — pure data, non-blocking.
4. **SDK PR-S1** (parallel/tracked) — consumes runtime RIDs; can proceed once
   R-R2/R-R4 land so the SDK's RID declarations match real packs.
5. **SDK PR-S2** — validation/alignment of AOT publish from SDK.

## Key facts driving this split

- **NativeAOT is verified E2E** (qemu) — the BuildIntegration fixes are proven,
  so PR-R3 can confidently include them.
- **SDK's `NativeAotSupported=false` for ohos** targets SDK-internal tools only
  (dotnet-aot/dn build), NOT user publish — no conflict with runtime AOT support.
- **`TargetOpenHarmony` naming** (jkotas) applies across both repos; SDK uses RID
  strings (`linux-ohos-*`) so it's naturally consistent.
- **Exclude upstream merge residue** (SmtpClient etc.) from all PRs.

## Validation

- Runtime: full `clr.native+libs+host+packs -os linux-ohos -arm64 --cross` build
  (0 errors) + NativeAOT publish E2E (qemu run).
- SDK: `dotnet publish -r linux-ohos-arm64 -p:PublishAot=true` with local feed
  (documented in C.6 of the runtime plan).
- Standard platform CI matrix must pass (no-op guarantee).
