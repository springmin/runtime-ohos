# HarmonyOS (linux-ohos) Runtime Porting — Upstream PR Preparation

**Branch:** `feature/ohos-cross-runtime`
**Baseline:** `dotnet/runtime` main (`278ba422a1a`)
**Scope:** Add `linux-ohos` (HarmonyOS / OpenHarmony) as a supported Unix RID for
CoreCLR, NativeAOT, native libs, host, and packs.
**Validation:** Full `clr.native+libs+host+packs -os linux-ohos -arch arm64 --cross`
cross-build succeeded (`0 Warning(s) 0 Error(s)`, 16 min), OHOS sandbox fixes
verified in produced binaries.

---

## 1. Summary of Changes

The port follows the established `linux-bionic` (Android NDK) pattern: HarmonyOS
ships an NDK whose CMake toolchain (`ohos.toolchain.cmake`) sets
`CMAKE_SYSTEM_NAME=OHOS` and provides `aarch64-unknown-linux-ohos-clang` wrappers
plus a musl-based sysroot. The runtime therefore:

1. Recognizes `-os linux-ohos` end-to-end (build.sh → RID graph → packs → products).
2. Routes native builds through the OHOS NDK toolchain (no rootfs, no distro
   container — the NDK is self-contained, like Android/bionic).
3. Defines a `TARGET_OHOS` compile-time macro (mirroring `TARGET_ANDROID`) so
   platform guards can exclude OHOS where its sysroot/ABI differs.
4. Carries a small set of sandbox/runtime fixes required by the OHOS app sandbox
   (seccomp-blocked NUMA syscalls, read-only `/tmp`, no robust pthread mutexes,
   no LTTng/gssapi in sysroot).

Total: **34 source/build files, ~230 inserted lines** (plus this doc). No public
API surface added. `OperatingSystem.IsOhos()` is `internal` (mirrors `IsHaiku()`).

---

## 2. Proposed PR Split

The port is deliberately split into **4 independent PRs** so each is reviewable
and mergeable on its own. Order matters only for the CI/validation story.

### PR A — Build infrastructure: `-os linux-ohos` + NDK toolchain plumbing
*(the "enable the target" PR, everything needed to cross-build native pieces)*

| File | Change |
|---|---|
| `eng/build.sh` | Add `linux-ohos` case → `os=linux` + `__PortableTargetOS=linux-ohos`; skip ROOTFS_DIR pass (NDK is self-contained); usage text |
| `eng/RuntimeIdentifier.props` | `PortableOS=linux-ohos`; `TargetsLinuxOhos=true`; exclude from `TargetsLinuxGlibc` |
| `eng/native/build-commons.sh` | OHOS branch: `OHOS_NDK_HOME` required, inject `ohos.toolchain.cmake` + `tryrun.cmake`, map arch→`OHOS_ARCH` (`arm64-v8a`/`armeabi-v7a`/`x86_64`), `__Compiler=default`; skip rootfs creation |
| `eng/native/gen-buildsys.sh` | Don't require ROOTFS_DIR for linux-ohos; don't override the NDK toolchain |
| `eng/native/configureplatform.cmake` | `CMAKE_SYSTEM_NAME=OHOS` → normalize to `linux` + `CLR_CMAKE_HOST_LINUX_MUSL` + `CLR_CMAKE_HOST_OHOS`; set `CLR_CMAKE_TARGET_OHOS` |
| `eng/native/configurecompiler.cmake` | OHOS flags: `-Qunused-arguments` (NDK `--gcc-toolchain` unused warning vs `-Werror`), `-fno-emulated-tls` + `-ftls-model=global-dynamic` (arm64 asm TLS match); `TARGET_OHOS` define |
| `eng/native/configuretools.cmake` | Hint `find_program` at compiler dir (NDK tools outside PATH) |
| `eng/Subsets.props` | `DefaultSubsets` for `TargetsLinuxOhos` (incl. `clr.nativeaotruntime`+`clr.nativeaotlibs`); `_BuildAnyCrossArch` includes OHOS |
| `eng/liveBuilds.targets` | `CoreCLRArtifactsPath` → `linux-ohos.<arch>.<config>` |
| `src/coreclr/runtime.proj` | `_BuildNativeTargetOS=linux-ohos` |
| `src/native/libs/build-native.proj` / `.sh` | `_BuildNativeTargetOS=linux-ohos`; exclude OHOS from auto-cross detection |
| `src/native/corehost/corehost.proj` | `_CoreHostUnixTargetOS=linux-ohos` |

### PR B — RID graph + packs: make `linux-ohos-*` first-class RIDs
*(the "ship the products" PR, depends on PR A for CI legs)*

| File | Change |
|---|---|
| `src/libraries/Microsoft.NETCore.Platforms/src/runtime.json` | Add `linux-ohos`, `linux-ohos-arm`, `linux-ohos-arm64`, `linux-ohos-x64` (import `linux`/`linux-<arch>`) |
| `eng/targetingpacks.targets` | Add `linux-ohos-{arm,arm64,x64}` to CoreCLR + Mono runtime pack RIDs; `linux-ohos-{arm64,x64}` to NativeAOT pack RIDs |
| `src/native/eventpipe/ds-portable-rid.c` | `TARGET_OHOS` → `PORTABLE_RID_OS "linux-ohos"` |
| `src/installer/pkg/sfx/Microsoft.NETCore.App/Microsoft.NETCore.App.Runtime.CoreCLR.sfxproj` | Disable `PublishReadyToRun` for OHOS (no PGO data yet) |

### PR C — CoreCLR/PAL/native-libs compile fixes for the OHOS sysroot
*(the "it actually builds" PR)*

| File | Change |
|---|---|
| `src/coreclr/clr.featuredefines.props` + `clrfeatures.cmake` | Disable `FEATURE_EVENTSOURCE_XPLAT` (no LTTng in OHOS sysroot) |
| `src/coreclr/pal/src/configure.cmake` | Don't fatal-error on missing LTTng for OHOS |
| `src/coreclr/pal/src/CMakeLists.txt` | Skip `gcc_s`/`pthread`/`rt` link for OHOS (like Android) |
| `src/native/external/zstd.cmake` | `ZSTD_USE_C90_QSORT=1` for OHOS (no `qsort_r`) |
| `src/native/libs/CMakeLists.txt` | OHOS → `System.Security.Cryptography.Native` (OpenSSL built for OHOS via `OPENSSL_*` cache vars), skip `System.Net.Security.Native` (no krb5) |
| `src/native/libs/System.Net.Security.Native/extra_libs.cmake` | No `LIBGSS` link for OHOS (dlopen on demand like Linux) |
| `src/native/libs/System.Native/CMakeLists.txt` | OHOS in the "no robust mutex" list |
| `src/native/libs/System.Native/pal_interfaceaddresses.c` | `TARGET_OHOS` uses `ecmd.speed` directly (no `ethtool_cmd_speed`) |
| `src/native/corehost/apphost/static/CMakeLists.txt` | Skip `NATIVE_LIBS_EMBEDDED` + `System.Net.Security.Native-Static` for OHOS; replace `WHOLE_ARCHIVE` genex with traditional `-Wl,--whole-archive` (linker compat) |
| `src/coreclr/tools/aot/crossgen2/crossgen2_publish.csproj` | `PublishAot=false` + `NativeCompilationDuringPublish=false` (crossgen2 is a host IL tool) |

### PR D — Runtime sandbox fixes for OHOS
*(the "works inside the OHOS sandbox" PR; smallest, highest-value)*

| File | Change |
|---|---|
| `src/coreclr/gc/unix/numasupport.cpp` | Guard all NUMA syscalls (`get_mempolicy`/`mbind`) with `!TARGET_OHOS` — seccomp blocks them → SIGSYS crash |
| `src/libraries/System.Private.CoreLib/src/System/IO/SharedMemoryManager.Unix.cs` | Return `Path.GetTempPath()` instead of hardcoded `/tmp/` (OHOS mounts `/tmp` read-only; honors `TMPDIR`) |
| `src/libraries/System.Private.CoreLib/src/System/Threading/NamedMutex.Unix.cs` | `UsePThreadMutexes` excludes OHOS (no robust pthread mutexes in sysroot) |
| `src/libraries/System.Private.CoreLib/src/System/OperatingSystem.cs` | `internal static bool IsOhos()` (compile-time `TARGET_OHOS`; mirrors `IsHaiku()`) |
| `src/libraries/System.Private.CoreLib/src/System.Private.CoreLib.Shared.projitems` | `TARGET_OHOS` define constant from `TargetsLinuxOhos` |
| `src/coreclr/nativeaot/System.Private.CoreLib/src/System.Private.CoreLib.csproj` + `Test.CoreLib.csproj` | `IntermediatesDir` → `linux-ohos.<arch>.<config>` for NativeAOT |

---

## 3. Design Decisions & Rationale

### 3.1 Why `linux-ohos` (not a new `ohos` OS)?
- HarmonyOS kernel is Linux; libc is musl (OpenHarmony "musl 4.0"). Treating it as
  a `linux` flavor with `__PortableTargetOS=linux-ohos` (exactly like
  `linux-bionic`/`linux-musl`) reuses the entire Linux path and only overrides
  what differs. RID import: `linux-ohos-*` → `linux-*` (so `RuntimeInformation`
  and pack resolution inherit Linux behavior).

### 3.2 Why `TARGET_OHOS` (not reuse `TARGET_LINUX_MUSL`)?
- The sysroot is musl-based, but several OHOS specifics are *not* shared with
  plain `linux-musl` (Alpine): no LTTng, no krb5/gssapi, no robust mutexes, no
  `qsort_r`, seccomp-blocked NUMA syscalls, read-only `/tmp`. A dedicated macro
  (mirroring `TARGET_ANDROID`, which also sits on a musl-ish libc) keeps every
  guard explicit and grep-able.

### 3.3 Why NDK toolchain and no rootfs?
- OHOS apps build against the official NDK (like Android). The NDK ships
  `ohos.toolchain.cmake` + clang wrappers + sysroot; there is no distro container
  to rootfs. `build-commons.sh` injects the toolchain file and skips the
  `.tools/rootfs` creation path (mirrors how `linux-bionic` avoids rootfs).

### 3.4 Why disable NUMA probe / use TMPDIR / drop robust mutexes?
These are **sandbox requirements**, not performance choices:
- `get_mempolicy`/`mbind` are blocked by the OHOS seccomp policy → the NUMA probe
  would SIGSYS-crash the process at startup. The probe is compiled out entirely
  (GC falls back to single-node, which is correct for phones).
- `/tmp` is mounted read-only in the app sandbox → shared-memory files (named
  mutexes, memory-mapped files) must live under `TMPDIR`. `Path.GetTempPath()`
  already honors `TMPDIR`; the hardcoded `/tmp/` was the only offender.
- The sysroot's pthread lacks robust mutex support → `NamedMutex` falls back to
  the shared-memory-file implementation (already the path for OpenBSD/Haiku).

### 3.5 Why `PublishReadyToRun=false` for OHOS?
- No PGO data exists for `linux-ohos`, so crossgen2 R2R would produce suboptimal
  images; the SDK already disables R2R the same way for NetBSD/illumos/Solaris/Haiku.

### 3.6 Why the crossgen2 `PublishAot=false`?
- `crossgen2` is a **host** tool shipped as self-contained IL. On RIDs whose RID
  graph advertises NativeAOT (linux-ohos now does), the SDK would otherwise try
  to AOT-publish it and fail for lack of a NativeAOT runtime pack for that tool.
  The property pins the existing intent explicitly.

---

## 4. Validation Evidence

| Check | Result |
|---|---|
| Full cross-build `clr.native+libs+host+packs -os linux-ohos -arch arm64 --cross -c Release` | ✅ `Build succeeded. 0 Warning(s) 0 Error(s)` (16:17) |
| `libcoreclr.so` | ✅ ELF aarch64, stripped, produced |
| NUMA fix in binary | ✅ `objdump` of `libcoreclr.so`: **0** references to `get_mempolicy`/`mbind` |
| `System.Private.CoreLib.dll` (linux-ohos) | ✅ built; contains `GetTempPath` path |
| Packs | ✅ `Microsoft.NETCore.App.Runtime.linux-ohos-arm64`, `Runtime.NativeAOT.linux-ohos-arm64`, `Microsoft.DotNet.ILCompiler`, apphost-pack, crossgen2, `dotnet-runtime-11.0.0-dev-linux-ohos-arm64.tar.gz` all produced |
| RID graph | ✅ `linux-ohos`, `linux-ohos-arm64`, `linux-ohos-x64`, `linux-ohos-arm` present |
| qemu-aarch64 smoke | ✅ (previous port validation; see `docs/plans/2026-08-13-ohos-cross-compile.md`) |

**Build environment (for CI / reproduction):**
- `OHOS_NDK_HOME` → HarmonyOS NDK root (contains `native/build/cmake/ohos.toolchain.cmake`)
- OpenSSL for OHOS (aarch64 static) passed via `-DOPENSSL_ROOT_DIR/INCLUDE_DIR/CRYPTO_LIBRARY/SSL_LIBRARY`
- ICU for OHOS passed via `-DCMAKE_ICU_DIR`
- RID graph injection: build uses the repo's own RID graph (no external SDK patch
  needed for the runtime repo itself)

---

## 5. Known Limitations / Follow-ups (not blockers)

- **No PGO data** → R2R disabled for OHOS (3.5). Can be revisited when a PGO leg exists.
- **No CI legs yet** → the four PRs should add `linux-ohos` legs to
  `eng/pipelines/runtime.yml` (mirror the `linux-bionic` cross legs) once the
  infra PRs land. CI leg YAML is intentionally **not** part of this port to keep
  the diff minimal; adding it is the immediate next step.
- **LTTng/EventPipe** → `FEATURE_EVENTSOURCE_XPLAT` off for OHOS; EventPipe-only
  eventing still works (same as Windows/macOS).
- **TLS in singlefilehost** → `System.Net.Security.Native-Static` excluded from
  the singlefilehost static link for OHOS; apphosts rely on dlopen of the shared
  lib (same as Android path).
- **`OperatingSystem.IsOhos()` is `internal`** — no public API change in this port;
  a public `OperatingSystem.IsOhos()` would need API review and a separate PR.

---

## 6. How to Rebase / Apply Upstream

The branch tracks upstream `main` and is rebased/merged regularly:
```bash
git fetch upstream main
git merge upstream/main            # or: git rebase upstream/main
# re-run the cross-build to confirm (section 4)
./build.sh clr.native+libs+host+packs -os linux-ohos -arch arm64 --cross \
  -c Release -lc Release -rc Release \
  /p:IncludeSymbols=false /p:DebugSymbols=false \
  -cmakeargs "-DOPENSSL_ROOT_DIR=<ohos-openssl> -DOPENSSL_INCLUDE_DIR=<ohos-openssl>/include \
  -DOPENSSL_CRYPTO_LIBRARY=<ohos-openssl>/lib/libcrypto.a -DOPENSSL_SSL_LIBRARY=<ohos-openssl>/lib/libssl.a \
  -DCMAKE_ICU_DIR=<ohos-icu>"
```

---

## 7. File Inventory (complete)

```
eng/build.sh
eng/RuntimeIdentifier.props
eng/Subsets.props
eng/liveBuilds.targets
eng/native/build-commons.sh
eng/native/configurecompiler.cmake
eng/native/configureplatform.cmake
eng/native/configuretools.cmake
eng/native/gen-buildsys.sh
eng/targetingpacks.targets
src/coreclr/clr.featuredefines.props
src/coreclr/clrfeatures.cmake
src/coreclr/gc/unix/numasupport.cpp
src/coreclr/nativeaot/System.Private.CoreLib/src/System.Private.CoreLib.csproj
src/coreclr/nativeaot/Test.CoreLib/src/Test.CoreLib.csproj
src/coreclr/pal/src/CMakeLists.txt
src/coreclr/pal/src/configure.cmake
src/coreclr/runtime.proj
src/coreclr/tools/aot/crossgen2/crossgen2_publish.csproj
src/installer/pkg/sfx/Microsoft.NETCore.App/Microsoft.NETCore.App.Runtime.CoreCLR.sfxproj
src/libraries/Microsoft.NETCore.Platforms/src/runtime.json
src/libraries/System.Private.CoreLib/src/System.Private.CoreLib.Shared.projitems
src/libraries/System.Private.CoreLib/src/System/IO/SharedMemoryManager.Unix.cs
src/libraries/System.Private.CoreLib/src/System/OperatingSystem.cs
src/libraries/System.Private.CoreLib/src/System/Threading/NamedMutex.Unix.cs
src/native/corehost/apphost/static/CMakeLists.txt
src/native/corehost/corehost.proj
src/native/eventpipe/ds-portable-rid.c
src/native/external/zstd.cmake
src/native/libs/CMakeLists.txt
src/native/libs/System.Native/CMakeLists.txt
src/native/libs/System.Native/pal_interfaceaddresses.c
src/native/libs/System.Net.Security.Native/extra_libs.cmake
src/native/libs/build-native.proj
src/native/libs/build-native.sh
```
*(35 files total; the historical log `docs/plans/2026-08-13-ohos-cross-compile.md` and
`build-local-linux.sh` are local dev aids and are **excluded** from the PRs.)*

---

## 8. Post-Review Fixes (2026-08-27)

Two shared build-infra files were initially changed unconditionally; both are
now **guarded to OHOS only**, so non-OHOS platforms get byte-identical behavior
to upstream:

| File | Before (unconditional) | After (OHOS-guarded) |
|---|---|---|
| `eng/native/configuretools.cmake` | `find_program(... HINTS compiler_dir)` for all platforms | `HINTS` only under `if(CLR_CMAKE_HOST_OHOS)`; other platforms use the upstream `find_program` verbatim |
| `src/native/corehost/apphost/static/CMakeLists.txt` | `$<LINK_LIBRARY:WHOLE_ARCHIVE,runtimeinfo>` replaced with `-Wl,--whole-archive` for all platforms | OHOS: `target_link_options(...-Wl,--whole-archive...)` inside `if(CLR_CMAKE_TARGET_OHOS)`; other platforms keep `$<LINK_LIBRARY:WHOLE_ARCHIVE,runtimeinfo>` (CMake maps to `/WHOLEARCHIVE` on Windows, `-force_load` on Apple) |

**Why OHOS needs the traditional flag:** the HarmonyOS NDK ships lld 15, which
CMake 4.x rejects for the `WHOLE_ARCHIVE` CXX link feature (`WHOLE_ARCHIVE not
supported for CXX link language`, see problem log #34). The NDK's own CMake
3.28.2 does not have this restriction, but the repo build uses the host CMake.

**Validation:** re-ran `clr.native -os linux-ohos -arch arm64 --cross` — the
singlefilehost link now takes the OHOS branch:
`[1/2] Linking CXX executable Corehost.Static/singlefilehost` → `0 Warnings 0 Errors`.
`singlefilehost` output verified as aarch64 ELF (musl interpreter).
