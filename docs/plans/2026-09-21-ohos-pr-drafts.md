# OHOS upstream PR drafts (dotnet/runtime, fork `springmin`)

States as of **2026-09-21** (re-verified against the branch tips below;
supersedes the `/data/.../tmp` copy and the 09-16 table).

Base for every branch: `pr/ohos-infra` (#132953) — stacked until it merges;
then rebase onto `main` and open. One commit per branch, single concern.
N16 is stacked on N15 (`pr/ohos-libs-tfm`); N13 (`pr/ohos-packs`) is based on
`upstream/main` and behaves only once #132953 (the `TargetsOpenHarmony`
property) has landed. `upstream/main` at the last rehearsal: `35423f17d6e`
(2026-09-21).

| PR | branch | commit | files | size |
|---|---|---|---|---|
| N1 | `pr/ohos-clrfeatures` | `d9428292318` | `src/coreclr/clrfeatures.cmake` | 4+/3- |
| N2 | `pr/ohos-pal` | `0f9fcf089c4` | `pal/src/CMakeLists.txt` | 2+/2- |
| N3 | `pr/ohos-zstd` | `83dae1c2849` | `src/native/external/zstd.cmake` | 2+/2- |
| N4 | `pr/ohos-libs-native` | `9e48c9e4a93` | `libs/CMakeLists.txt`, `Net.Security.Native/extra_libs.cmake` | 9+ |
| N5 | `pr/ohos-apphost` | `934173210f1` | `corehost/apphost/static/CMakeLists.txt` | 13+/4- |
| N7 | `pr/ohos-pal-process` | `c5e1dc3e4aa` | `libs/System.Native/pal_process.c` | 5+/2- |
| N8 | `pr/ohos-ifaddrs` | `3eb1ab8f51c` | `libs/System.Native/pal_interfaceaddresses.c` | 4+ |
| N9 | `pr/ohos-wx-default` | `bb7e8e69e76` | `src/coreclr/inc/clrconfigvalues.h` | 4+/2- |
| N10 | `pr/ohos-crossgen-corelib` | `169c072d07c` | `src/coreclr/crossgen-corelib.proj` | 11+/1- |
| N11 | `pr/ohos-aot-unix` | `91a2e8e5a62` | `AOT/Microsoft.NETCore.Native.Unix.targets` | 6+/1- |
| N12 | `pr/ohos-aot-singleentry` | `da4dc098a4a` | `AOT/Microsoft.DotNet.ILCompiler.SingleEntry.targets` | 4+ |
| N13 | `pr/ohos-packs` | `fed16fdbdc9` | `targetingpacks.targets`, `ds-portable-rid.c`, `ILCompiler.pkgproj`, `CoreCLR.sfxproj` | 44+/6- |
| N14 | `pr/ohos-tryrun` | `c2a5e90db55` | `eng/native/tryrun.cmake` | 9+ |
| N15 | `pr/ohos-libs-tfm` | `01667c2c6d5` | libraries TFM mapping (6 files) | 23+/3- |
| N16 | `pr/ohos-console` | `94f72514835` | `System.Console/src/System.Console.csproj` | 6+/3- |

Notes: N13 ships **without** the fork-local `OpenHarmonyInTreeR2R` gate and is
**based on latest `upstream/main`** (its sfxproj patch context had to track
upstream's WASM R2R refactor; conflict pre-solved, see
`final-evidence/post132953-rebase-rehearsal.txt` + `n13-rebase-resolution.patch`);
N11 excludes the upstream-only `IgnoreStandardErrorWarningFormat` attribute
(added upstream after the #132953 fork point); N10's comment is neutralized for
upstream (no fork-specific references). Review-fix pass 2026-09-15: N15 defaults
`LibrariesBinPlaceTfm`; N13 scopes the runtime-pack override to OpenHarmony and
fixes the ILCompiler comment/predicate. Cleanup pass (P2, 2026-09-15): N9/N10/N1
comments neutralized, dead `ohos` RID mapping removed.

**Review-risk notes:** N15's shims clause still keys off `'$(TargetOS)' ==
'openharmony'` while the rest of the set uses `TargetsOpenHarmony` (available
there — the root `Directory.Build.props` imports `eng/RuntimeIdentifier.props`)
— consider unifying so reviewers see one predicate. N16 suppresses CA1416
(`NoWarn`) only for the neutral-TFM OpenHarmony case; keep the "drops out once
the TFM mapping lands" sentence in the PR body so the suppression is clearly
temporary.

Rebase status: the 09-15 pre-flight (clean on the then-current main
`8f610270d37`) is **superseded** — `upstream/main` has since moved to
`35423f17d6e`; a re-run against that tip is recorded in the plan's 2026-09-21
update (see `docs/plans/2026-09-07-ohos-pr-plan-bsd-haiku-model.md`).

---

## N1 — `pr/ohos-clrfeatures`

**Title:** coreclr: disable the LTTng event source on OpenHarmony

**Body:**
```
OpenHarmony's sysroot has no liblttng-ust, and the platform is not an LTTng
target. Add CLR_CMAKE_TARGET_OPENHARMONY to the FEATURE_EVENTSOURCE_XPLAT
guard so OHOS builds fall back to EventPipe-only eventing, like Android.
```

**Test:** cross-build CoreCLR for openharmony-arm64 with the OHOS toolchain;
confirm the configure step leaves FEATURE_EVENTSOURCE_XPLAT unset.

---

## N2 — `pr/ohos-pal`

**Title:** coreclr: PAL build fixes for OpenHarmony

**Body:**
```
Match the Android handling on OHOS: skip linking gcc_s, pthread and rt — the
OpenHarmony toolchain provides them through its sysroot.
```

**Test:** cross-build the CLR for openharmony-arm64 and confirm `coreclrpal`
links.

---

## N3 — `pr/ohos-zstd`

**Title:** native: use the C90 qsort workaround for zstd on OpenHarmony

**Body:**
```
The OpenHarmony sysroot lacks qsort_r and zstd's autodetection does not
handle it; reuse the Android ZSTD_USE_C90_QSORT workaround.
```

**Test:** native libs cross-build for openharmony-arm64.

---

## N4 — `pr/ohos-libs-native`

**Title:** native: skip gssapi on OpenHarmony and use the OpenSSL crypto shim

**Body:**
```
OpenHarmony has no krb5/gssapi in its sysroot, so System.Net.Security.Native
cannot build there. Build System.Security.Cryptography.Native with the OHOS
OpenSSL (OPENSSL_* cache variables) instead, and return an empty LIBGSS in
the Net.Security extra-libs path.
```

**Test:** native libs cross-build; `System.Security.Cryptography.Native` is
produced and `System.Net.Security.Native` is skipped.

---

## N5 — `pr/ohos-apphost`

**Title:** corehost: singlefilehost fixes for OpenHarmony

**Body:**
```
- skip NATIVE_LIBS_EMBEDDED and System.Net.Security.Native-Static on OHOS;
- link runtimeinfo with explicit whole-archive flags: the
  $<LINK_LIBRARY:WHOLE_ARCHIVE> generator expression is not usable with the
  OpenHarmony NDK toolchain in this build.
```

**Test:** cross-build the static apphost and publish a single-file app for
openharmony-arm64.

---

## N7 — `pr/ohos-pal-process`

**Title:** System.Native: avoid close_range on OpenHarmony

**Body:**
```
The OpenHarmony seccomp policy traps close_range() with SIGSYS, so the
process dies before the fallback can run. Skip both the libc function and
the raw-syscall paths on TARGET_OPENHARMONY and use
SetCloexecForAllFdsFallback(). Revisit when OpenHarmony 7.1 relaxes the
policy.
```

**Test:** on OHOS, spawn a process with inherited handles configured
(`InheritedHandles`) and confirm the fallback path runs and the child execs.

---

## N8 — `pr/ohos-ifaddrs`

**Title:** System.Native: read the full ethtool speed on OpenHarmony

**Body:**
```
ethtool_cmd_speed() is not provided by the OpenHarmony UAPI headers
(TARGET_ANDROID already has its own path). Inline the computation
((speed_hi << 16) | speed) on TARGET_OPENHARMONY so link speeds above
65535 Mbps are reported correctly; Android is untouched.
```

**Test:** `NetworkInterface.GetAllNetworkInterfaces()` reports the expected
speed (e.g. 100000 for 100G) on OHOS.

---

## N9 — `pr/ohos-wx-default`

**Title:** coreclr: default EnableWriteXorExecute to 0 on OpenHarmony

**Body:**
```
The OpenHarmony kernel denies PROT_EXEC on file-backed (memfd/shm) mappings,
which the W^X double-mapping allocator depends on; anonymous executable
memory is allowed. Default to the RWX allocator on TARGET_OPENHARMONY,
matching the existing RISC-V workaround. Device-verified: memfd
mprotect(RX)/mmap(PROT_EXEC) -> EACCES; anonymous RW->RX + execution OK.
```

**Test:** run a JIT workload on an OHOS device with the default configuration;
no EACCES from the allocator.

---

## N10 — `pr/ohos-crossgen-corelib` (tip `169c072d07c`, 11+/1-)

**Title:** coreclr: keep the OpenHarmony CoreLib IL-only in-tree and map the crossgen2 target OS

**Body:**
```
The runtime build keeps the OpenHarmony CoreLib IL-only (the R2R image is
produced by the SDK build), and the crossgen2 target OS is remapped from
openharmony to linux, since OHOS R2R images are Linux ABI and crossgen2's
TargetOS whitelist has no openharmony entry. The mapping applies when
ReadyToRun is enabled from the command line.
```

**Test:** cross-build CoreLib with the OHOS toolchain; in-build R2R path emits
`--targetos:linux`; default path produces an IL-only CoreLib.

---

## N11 — `pr/ohos-aot-unix`

**Title:** AOT: use lld and the ohos clang ABI on OpenHarmony

**Body:**
```
The OpenHarmony NDK ships only lld, so select it as the linker flavor (like
bionic), use the 'ohos' clang ABI token for openharmony RIDs
(aarch64-linux-ohos), and skip the gssapi-based System.Net.Security.Native
library, which the OHOS sysroot does not provide.
```

**Test:** NativeAOT cross-publish for openharmony-arm64.

---

## N12 — `pr/ohos-aot-singleentry`

**Title:** AOT: map openharmony to linux/musl in the SingleEntry layout

**Body:**
```
ilc only knows the linux/android/osx/... target OS names; map openharmony to
linux while keeping the musl libc flavor, so the OpenHarmony RID
(kernel-agnostic, musl userland) links through the linux path.
```

**Test:** NativeAOT publish for openharmony-arm64.

---

## N13 — `pr/ohos-packs`

**Title:** packs: wire the OpenHarmony RID into the local pack graphs

**Body:**
```
Add openharmony-* to the local runtime, NativeAOT and apphost pack RID lists
and emit the 'openharmony' portable RID. The OHOS runtime pack stays IL-only
(crossgen2 target OS remapped to linux) and drops IL-directory pdb
duplicates; the ILCompiler package optionally ships the device C++ runtime.
```

**Test:** local-pack build for openharmony-arm64; runtime/apphost/ILCompiler
artifacts present; `ResolvedRuntimePack` override scoped to the target RID.

Note: the sfxproj hunk sits on top of #132953's sfxproj changes — submit
after #132953 (as with all branches).

**Resolved (2026-09-21):** `openharmony-arm` was dropped from the runtime and
apphost pack RID lists (tip `fed16fdbdc9`), matching A1 (arm64/x64 only). The
#132953 RID graph keeps `openharmony-arm` as an addressable RID — the graph
entry alone does not promise a pack; the pack lists are the published set and
now agree with the supported-arch matrix. Full arm32 support is **parked**
until a 32-bit OHOS device is available; the enablement plan (`ARM_SOFTFP`,
NativeAOT armel mapping, arm32 signer) and the device readiness checklist live
in `docs/plans/2026-09-21-ohos-arm32-support-gap.md`.

---

## N14 — `pr/ohos-tryrun`

**Title:** eng/native: pin the OHOS cross-build FIFO probe answers

**Body:**
```
OpenHarmony cross builds cannot run the FIFO probes, so set the two
HAVE_BROKEN_FIFO_* cache answers when CMAKE_SYSTEM_NAME is OHOS; other
linux-family cross targets keep their own probe results.
```

**Test:** `cmake -C eng/native/tryrun.cmake -DCMAKE_SYSTEM_NAME=OHOS` pins
both answers; `-DCMAKE_SYSTEM_NAME=Linux` / unset leaves them unset
(recorded in final-evidence/tryrun-scope-verify.txt).

---

## N15 — `pr/ohos-libs-tfm`

**Title:** libraries: compile OpenHarmony in the linux/unix TFM groups

**Body:**
```
There is no `-openharmony` TFM platform yet; OHOS compiles with the linux
(SFX/runtime) and unix (shims) TFMs via
LibrariesOpenHarmonySfxTfm/LibrariesOpenHarmonyShimsTfm, the MSBuild-layer
equivalent of the compile-level linux remap. No shipping TFM changes.
```

**Test:** libraries build for openharmony; SFX and shims resolve to the
linux/unix TFMs.

---

## N16 — `pr/ohos-console` (based on N15)

**Title:** System.Console: use the unix ConsolePal on OpenHarmony

**Body:**
```
OHOS has no TFM platform identifier, so the unix ConsolePal was not selected
and CA1416 flagged it. Include the unix sources for TargetsOpenHarmony and
suppress CA1416 only in that neutral-TFM case; the suppression drops out once
the TFM mapping lands.
```

**Test:** build System.Console for OHOS; Console works on device.

---

## A1 — `pr/ohos-aspnet-rids` (aspnetcore-ohos)

**Title:** Add the openharmony RIDs to the ASP.NET Core build

**Body:**
```
OpenHarmony is not a NativeAOT target yet: override NativeAotSupported=false
for openharmony targets (TargetOsName=openharmony or an openharmony-* runtime
identifier) so the bundled tools (dotnet-dev-certs, dotnet-user-jwts,
dotnet-user-secrets, aspnetcoretools) and the E2E NativeAOT harnesses do not
try to restore or link an ILCompiler pack that does not exist for the port.

Add openharmony-x64/openharmony-arm64 to SupportedRuntimeIdentifiers,
BundledToolTargetRuntimeIdentifiers and the Microsoft.NETCore.App.Runtime /
Crossgen2 package reference lists so the shared framework and the bundled
tools can build for the port. openharmony-arm is intentionally absent: the
port only ships x64 and arm64.
```

**Test:** the fork's `ohos-full-build` CI builds aspnetcore for
openharmony-arm64; the E2E AOT harnesses stay disabled on OHOS.

**Base/size:** `upstream/main` `7b520eb5d3`; tip `b7070c3748`; 5 files, +21/-4.

---

## S1a — `pr/ohos-sdk-rids` (sdk-ohos)

**Title:** Add the openharmony RIDs to the SDK's RID graphs and R2R resolution

**Body:**
```
The Microsoft.NETCore.Platforms RID graphs do not know the openharmony RIDs
yet, so the SDK cannot restore or build for them. Add the openharmony,
openharmony-arm64 and openharmony-x64 entries to local copies of both graphs
(runtime.json and PortableRuntimeIdentifierGraph.json; openharmony is a
standalone base RID, like the other community platforms) and a
RidGraphOverrideRuntimeJson / RidGraphOverridePortableJson hook in
PublishRuntimeIdentifierGraphFiles that lets the SDK layout use them instead of
the package copies. Once the runtime ships the RIDs in Microsoft.NETCore.Platforms
the overrides are no longer needed.

Also list the two shipped openharmony RIDs in the bundled RID lists (apphost,
crossgen2/ILCompiler, runtime packs, ASP.NET Core runtime packs) and map the
openharmony RID to the linux token in the crossgen2 target-OS resolution, since
crossgen2's platform whitelist has no openharmony entry.
```

**Test:** SDK layout with `/p:RidGraphOverrideRuntimeJson=... /p:RidGraphOverridePortableJson=...`;
`dotnet publish -r openharmony-arm64` resolves the RID; R2R resolution maps to
linux. Covered by the fork's `ohos-full-build` CI.

**Base/size:** `upstream/main` `530aaa51fa`; tip `3c147cedbc`; 5 files,
+5189/-4 (the graphs are snapshot data). Depends on the runtime shipping the
openharmony RIDs and packs:
the bundled RID lists (crossgen2/ILCompiler/runtime packs and the ASP.NET Core
runtime packs) only resolve to real packages once the runtime/aspnetcore ports
publish them; until then they are consumed at the local dev version.

---

## S1b — `pr/ohos-sdk-sandbox` (sdk-ohos, stacked on S1a)

**Title:** Run and build the .NET SDK on OpenHarmony

**Body:**
```
Runtime behavior:
- OpenHarmonyEnvironmentDefaults applies the sandbox defaults (W^X off,
  invariant globalization, telemetry opt-out, nologo) to the CLI and to every
  child process it spawns; the same two runtime switches are baked into the
  redist runtimeconfig, which GenerateCliRuntimeConfigurationFiles copies to
  every bundled tool, so the SDK runs on OHOS without external environment
  variables. TMPDIR is deliberately not set: the runtime reads the
  host-provided value through Path.GetTempPath().
- dotnet-aot only enables PublishAot where the vendored NativeAotSupported
  allows it, and the CA1418 analyzer is told about the openharmony platform in
  the projects that call OperatingSystem.IsOSPlatform. A new test pins the
  child-process defaults and asserts Apply() is a no-op off platform.

SDK build:
- Skip the installers for openharmony RIDs, use the product-moniker RID for the
  shared framework, and skip the workload manifests on OHOS (it ships no
  workloads).
- Map the openharmony TargetOS to the linux token for the layout crossgen2.
- NativeAotSupported=false for openharmony centrally (the vendored props do not
  exclude it). The pack version aliases can be overridden from the command line
  so the SDK can be built against a locally built runtime.
```

**Test:** on-device `dotnet --info` and a build without `DOTNET_*` env vars;
the fork's `ohos-full-build` CI.

**Base/size:** stacked on `pr/ohos-sdk-rids`; tip `d97231e55c`; 17 files,
+182/-15 (2 commits).
