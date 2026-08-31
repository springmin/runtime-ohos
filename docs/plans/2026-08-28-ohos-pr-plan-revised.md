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

---

## 7. Post-review updates (2026-08-30/31)

### 7.1 Naming: OPENHARMONY (jkotas + am11 review, #132827)

Per reviewer feedback, all OHOS identifiers renamed to OPENHARMONY (kernel-agnostic,
matches the HarmonyOS/OpenHarmony distinction):

| Old | New | Scope |
|---|---|---|
| `TARGET_OHOS` | `TARGET_OPENHARMONY` | compile-time macro (numasupport, pal, CoreLib) |
| `TargetsOhos` / `TargetOpenHarmony` | `TargetsOpenHarmony` (plural, jkotas 08-30) | MSBuild props (RID props, subsets, native build, NativeAOT) |
| `IsOhos()` | `IsOpenHarmony()` | OperatingSystem |
| `CLR_CMAKE_TARGET_OHOS` | `CLR_CMAKE_TARGET_OPENHARMONY` | CMake |
| SDK `OhosCodesign` / `OhosEnvironmentDefaults` | `OpenHarmonyCodesign` / `OpenHarmonyEnvironmentDefaults` | SDK (renamed 08-31) |

The **`linux-ohos` RID string is unchanged** (HarmonyOS PC ships linux-ohos +
harmony-ohos kernels; the ohos RID migration is a separate tracked decision).

### 7.2 PR ordering guidance (am11, #132827)

am11: the first PR for a new platform should touch `eng/` (+ `src/coreclr`)
to define the platform in the repo, not `src/libraries` changes while nothing
defines the platform. This is the OpenBSD port's model (eng/ + coreclr first,
then per-library PRs, arcade upstreamed separately).

**Action:** the follow-up PRs are already infra-first (PR-R2 build infra touches
eng/ + coreclr). Reorder so **PR-R2 (infra) lands before any further libraries
changes**. PR #132827 (libraries sandbox fixes) stays as the standalone minimal
first PR but is understood to be the exception; reviewers asked for infra-first
going forward.

### 7.3 SDK class-name rename (08-31)

SDK `OhosCodesign` → `OpenHarmonyCodesign`, `OhosEnvironmentDefaults` →
`OpenHarmonyEnvironmentDefaults` (files, classes, MSBuild targets, call sites).
`linux-ohos` RID checks unchanged. Commit `229abfcc51` on `feature/ohos-cross-sdk`.

---

## 8. ELF code-signing requirements: OpenHarmony vs HarmonyOS (2026-08-31)

### 8.1 Conclusion

**`.codesign` is mandatory on HarmonyOS (Huawei commercial), NOT on OpenHarmony (open source).**

| Platform | `.codesign` required to execute? | Enforcement point |
|---|---|---|
| **OpenHarmony** (open source, standard products e.g. rk3568/dayu200) | **No** — unsigned ELF runs directly | HAP install-time verify only (`security_appverify`), offline-passable with the pre-bundled public cert |
| **HarmonyOS** (commercial: PC/HiShell, NEXT, security level ≥3) | **Yes** — kernel-enforced | exec/dlopen checks fs-verity/dm-verity protection; unsigned → `permission denied` |

### 8.2 Evidence

1. **OpenHarmony kernel lacks the enforcement components.** GitHub code search on
   `openharmony/kernel_linux_common_modules` for `fs_security_verity` and `xpm`
   (the modules that reject unsigned ELFs with "not protected by dmverity" /
   `E_HM_PERM` in HarmonyOS kernel logs) returns **nothing** — they are
   HarmonyOS-commercial-kernel-private, not in the open source tree.
2. **Official docs wording** (`hapsigntool-overview.md`): signing is required
   "on devices that support the mandatory code signing mechanism" — a device
   capability, not an OpenHarmony global default; `-signCode 0` can disable it.
   The official mandate targets HAP packages + debug tools (lldb-server), not
   arbitrary ELFs.
3. **Independent deep-dive** (hqzing's HarmonyOS PC series, 2026): "this
   mechanism is a HarmonyOS-specific security feature. OpenHarmony does not
   enable this check by default and its current source has not fully
   implemented the binary verification logic." The OpenHarmony SDK ships the
   *signing* toolchain (binary-sign-tool) even though the OS doesn't enforce it
   ("upstream toolchain reverse-adapting to the downstream OS").
4. **`security_code_signature` is optional** — all logic is behind
   `code_signature_support_*` feature flags (bundle.json/BUILD.gn), and standard
   product definitions (productdefine/vendor) do not enable it by default.
5. **Our own qemu verification** confirms it: the unsigned `aot-test` ran
   directly under the musl loader — the plain loader does not check `.codesign`.

### 8.3 Files needing signing (on enforcing devices)

- Main executable (ET_EXEC) + all loaded `.so` (ET_DYN) must carry `.codesign`.
- `.o` object files must NOT be signed (lld emits multiple signatures → kernel
  rejects with `Operation not permitted`).
- Symlinks are skipped.

### 8.4 Official tools

| Tool | Purpose | Source |
|---|---|---|
| `binary-sign-tool` | ELF-only signing (bin/.so); `-selfSign 1` self-sign | OpenHarmony `developtools_hapsigner/binary_sign_tool/`, ships in Command Line Tools SDK (`openHarmony/toolchains/lib/`) |
| `hap-sign-tool` | HAP/HSP/HQF + ELF binary signing | OpenHarmony `developtools_hapsigner/`, ships in Command Line Tools SDK |

Self-sign (flags bit `0x10`) is sufficient to *run* on enforcing devices but does
not grant high-privilege capabilities (macOS Ad Hoc analogue).

### 8.5 Impact on this port

- **`OpenHarmonyCodesign` auto-signing is NOT redundant** — the primary target
  is HarmonyOS commercial (PC), where it is mandatory. Keep it.
- The signing is **device-level enforcement on commercial HarmonyOS**, whereas
  OpenHarmony open source treats it as optional; document this in the SDK PR
  description to preempt reviewer questions.
- Self-sign implementation (ElfSignInfo: fs-verity descriptor version=1,
  hashAlgo=1, log2BlockSize=12, csVersion=3, flags|0x10, signature=SHA256 of
  descriptor with signSize=0) matches the official `binary-sign-tool` algorithm
  (byte-identical verified).
- Do not sign `.o` files; only ET_EXEC/ET_DYN in the SDK's auto-sign pass.

### 8.6 References

- OpenHarmony `binary-sign-tool.md` (official docs, tool paths):
  https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/tools/binary-sign-tool.md
- `hapsigntool-overview.md` ("on devices that support the mandatory code
  signing mechanism"):
  https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/security/hapsigntool-overview.md
- `security_code_signature` (feature flags):
  https://github.com/openharmony/security_code_signature/blob/master/bundle.json
- `security_appverify` (HAP install verify + pre-bundled public cert):
  https://github.com/openharmony/security_appverify
- HarmonyOS PC code-signing deep dive (OpenHarmony not enforced):
  https://harmonypc.csdn.net/69f750d154b52172bc71a036.html
- Self-sign algorithm / ElfSignInfo format + kernel logs:
  https://jishuzhan.net/article/2074363691891437569
- Meituan HarmonyOS signing analysis (NEXT double-layer signing):
  https://tech.meituan.com/2025/01/06/OpenHarmony.html
- Community tooling notes (`.o` must not be signed):
  https://github.com/SwimmingTiger/command-line-tools
