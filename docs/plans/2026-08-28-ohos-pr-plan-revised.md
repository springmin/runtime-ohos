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

**Scope addition (2026-09-02, decided with owner):** the on-device
verification-era fixes stay on the dev branch and ship with R3 (NOT folded into
#132827):

- `clrconfigvalues.h` W^X default off (`678ac21836c`)
- `pal_process.c` close_range guard + `pal_io.c` inotify_init1 guard
  (`e8a1fe38fd7`)
- ILCompiler pack libstdc++/libgcc_s (`cb2ffa742b4`) + `SingleEntry.targets` XML
  fix (`1e5e83cb012`) + nativeaot `IntermediatesDir` cleanup


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

---

## 9. Runtime restrictions: OpenHarmony (open source) vs HarmonyOS (commercial) — JIT/W^X/seccomp (2026-08-31)

### 9.1 Conclusion

**Hardware-verified (2026-08-31, HarmonyOS HongMeng Kernel 1.13.0, aarch64):
neither OpenHarmony (open source) nor HarmonyOS (commercial, tested device)
enforces the W^X/JIT ban. CoreCLR with JIT is viable on both.** The earlier
assumption that HarmonyOS commercial "forcibly bans JIT" (XPM LSM) is
**falsified by on-device probes**: anonymous RWX mmap, RW→RX mprotect, the
JITFORT prctl, and a real JIT-then-execute round-trip all succeed, and a full
CoreCLR+JIT .NET 11.0 app (LINQ/generics/threads/GC) runs natively on the
device. XPM enforcement is device/vendor-configuration dependent (see §9.2.5),
so the W^X-off posture stays **defensive**, but it is not a hard blocker on the
tested hardware.

| Restriction | HarmonyOS 5.0 (commercial) — **hardware-verified** | OpenHarmony (open source) |
|---|---|---|
| W^X / anonymous exec memory | **Not enforced on tested device** (HongMeng Kernel 1.13.0: mmap(RWX) OK, RW→RX OK); XPM LSM may be active on other devices/vendor configs | **Not enforced** — JITFORT/XPM hooks exist but no open-source implementation registers them |
| seccomp whitelist | `get_mempolicy` → **SIGSYS verified on device** (TRAP, recoverable); mmap/mprotect allowed | Same policies — **allows `mmap;all`, `mprotect;all`, `memfd_create;all`**; default action is `TRAP` not KILL |
| JIT runtimes (V8/.NET CoreCLR) | **Allowed — verified**: full .NET 11.0 CoreCLR+JIT app runs on device | **Allowed** — QEMU TCG JIT runs; `dotnet --info` verified on OHOS musl rootfs |
| CoreCLR | **CoreCLR + NativeAOT both viable** (hardware-verified) | **CoreCLR + NativeAOT both viable** |

### 9.2 Evidence (kernel source-level, openharmony/kernel_linux_5.10)

1. **`prctl(PR_SET_JITFORT 0x6a6974)`** ("jit" ASCII) — `kernel/sys.c` case is a
   **no-op** (`error = 0; break;`). The kernel accepts it but does nothing by itself.
2. **`MAP_XPM` mmap flag (0x40)** + `mm->xpm_region` + `/proc/<pid>/xpm_region` —
   infrastructure exists for XPM (executable-permission management) regions.
3. **`mprotect(PROT_EXEC)` HCK hook** (`mm/mprotect.c`):
   ```c
   if (prot & PROT_EXEC) {
       CALL_HCK_LITE_HOOK(find_jit_memory_lhck, current, start, len, &error);
       if (error) { pr_info("JITINFO: mprotect protection triggered"); return error; }
   }
   ```
   `CALL_HCK_LITE_HOOK` is a **no-op when no module registers the hook** — the
   open-source kernel has NO registration implementation, so `error` stays 0 and
   mprotect(PROT_EXEC) is allowed.
4. **`security/xpm` LSM is NOT in the open-source kernel repo** — only the hook
   points + proc interface ship; the enforcing LSM is a vendor/commercial patch.
5. **Per-board configs differ**: `rk3568_standard_defconfig` has
   `CONFIG_HCK=y` + `CONFIG_SECURITY_XPM=y`, but `unionpi_tiger_standard_defconfig`
   does NOT — the hooks only bite if both enabled AND a module registers them.
6. **seccomp policies** (`startup_init/services/modules/seccomp/`):
   `app_normal.seccomp.policy` allows `mmap;all`, `mprotect;all`,
   `memfd_create;all`, `userfaultfd;all`, `ptrace;all`; `get_mempolicy` is NOT
   whitelisted → TRAP → SIGSYS (this is exactly the NUMA crash we fixed in
   `numasupport.cpp`). Default return value is `TRAP` (recoverable via SIGSYS
   handler), not `KILL_PROCESS`.
7. **JITFORT user-space**: `appspawn` `InitXpm(jitfortEnable, ...)` +
   `persist.security.jitfort.disabled` sysprop (true → JITFORT off). Community
   QEMU-on-OHOS patch shows JIT works by wrapping mmap(PROT_EXEC) with
   `prctl(PR_SET_JITFORT, 0, 0/1)`.

### 9.3 Implications for this port

- **`linux-ohos` CoreCLR (with JIT) is the right target for BOTH OpenHarmony
  open source and HarmonyOS commercial (hardware-verified on HongMeng Kernel
  1.13.0)** — our port (JIT + `DOTNET_EnableWriteXorExecute` + NUMA fix) is
  correct. The W^X-off + sandbox fixes are **defensive** everywhere (in case a
  vendor LSM is enabled on some device), not a hard requirement on the tested
  hardware.
- **NativeAOT remains a supported artifact** but is **no longer the only option
  for HarmonyOS commercial** — CoreCLR+JIT is verified running on a commercial
  device. Keep both paths (CoreCLR unified binary, NativeAOT for constrained
  devices or future XPM-enforcing firmware).
- **seccomp**: `get_mempolicy`/`mbind` avoidance (numasupport.cpp) is needed on
  both — **`get_mempolicy` → SIGSYS verified on device** (TRAP semantics;
  without the fix the GC probe would crash startup). mmap/mprotect are fine.
- **Docs**: the port docs currently assume "OHOS needs W^X off + sandbox fixes";
  clarify these are defensive (vendor LSM may or may not be enabled on a given
  device) rather than universally required.

### 9.4 References

- Kernel: `openharmony/kernel_linux_5.10` (prctl.h `PR_SET_JITFORT 0x6a6974`,
  `mm/mprotect.c` `find_jit_memory_lhck`, `fs/proc/xpm_region.c`, defconfigs)
- seccomp: `openharmony/startup_init/services/modules/seccomp/*.seccomp.policy`
- JITFORT: `openharmony/startup_appspawn` `InitXpm`, `MSG_EXT_NAME_JIT_PERMISSIONS`
- musl: `openharmony/third_party_musl` (`MAP_XPM`, `HM_PR_CHECK_ENCAPS`)
- Community: TermonyHQ/Termony (QEMU-on-OHOS JIT patch) — confirms JIT runs on
  OpenHarmony with prctl wrapping; QEMU TCG JIT works
- Our verification: `dotnet --info` (CoreCLR+JIT) on OHOS musl rootfs (qemu)

---

## 10. Port classification: OpenHarmony shared / HarmonyOS-only / OpenHarmony-only + unified-binary design (2026-08-31)

> **FACT UPDATE (hardware-verified 2026-08-31):** JIT **does run on HarmonyOS** —
> the bun port, an earlier dotnet runtime build, and now the full CoreCLR+JIT
> .NET 11.0 app on this device (HongMeng Kernel 1.13.0) have all been confirmed.
> The XPM hardware probe (§10.4) **passed all four checks** — exec-memory
> restrictions are not enforced on the tested device; this section documents the
> classification and the unified-design strategy without asserting a JIT ban.

### 10.1 Classification of all port changes

#### Shared (OpenHarmony + HarmonyOS) — ~85% of changes

| Change | Why (both platforms) |
|---|---|
| RID support (`RuntimeIdentifier.props`, `runtime.json`, `targetingpacks.targets`) | both use `linux-ohos` RID + musl |
| OHOS NDK toolchain (`build-commons.sh`, `configureplatform/compiler/tools.cmake`, `gen-buildsys.sh`) | same NDK cross-compile |
| NUMA fix (`numasupport.cpp`) | `get_mempolicy` not in either seccomp whitelist → SIGSYS |
| TMPDIR (`SharedMemoryManager.Unix.cs`) | both sandboxes mount `/tmp` read-only |
| robust-mutex fallback (`NamedMutex.Unix.cs`) | both sysroots lack robust pthread mutexes |
| `OperatingSystem.IsOpenHarmony()` | platform detection |
| NativeAOT BuildIntegration (ABI/lld/Net.Security skip) | both musl + NDK lld |
| No-LTTng/gssapi/qsort_r/zstd sysroot fixes | same sysroot |
| `OpenHarmonyEnvironmentDefaults` (TMPDIR/telemetry/nologo) | both sandbox environments |

**Items to verify as shared (added by review):**
- ICU / globalization data path (community OHOS branch added a dedicated compile flag)
- Full syscall-whitelist check: `rseq`, `membarrier`, `faccessat2`, `getrandom`, `tgkill`,
  `sched_getaffinity`, `prctl`, `clone3`
- GC large virtual-memory reservation (`USE_REGIONS`; dotnet/runtime#111649) — test
  whether OpenHarmony is also constrained before classifying

#### HarmonyOS-only — ~10%

| Change | Why |
|---|---|
| **codesign (`OpenHarmonyCodesign`)** | HarmonyOS kernel enforces `.codesign`; OpenHarmony ignores it (harmless) |
| **W^X handling** | HarmonyOS XPM LSM restricts anonymous executable memory (exact behavior TBD by hardware probe) |
| libstdc++ → libc++ dependency (CoreCLR native chain) | OHOS ships libc++, CoreCLR links libstdc++ (dotnet/runtime#103627) |
| fork+exec restriction (if child processes needed) | HarmonyOS NEXT restricts third-party fork |
| appspawn env-var filtering | `DOTNET_*` may be stripped → config via runtimeconfig.json |

#### OpenHarmony-only

**No code-level changes** — the only difference is the **deployment artifact**:
OpenHarmony can ship the CoreCLR layout (JIT), HarmonyOS may ship CoreCLR or
NativeAOT depending on the hardware probe outcome.

### 10.2 Unified design: one codebase, artifacts per platform

**One codebase** (already how the port is structured):
- Compile-time: `TARGET_OPENHARMONY` guard (done) — both platforms share the
  `linux-ohos` RID, so compile-time cannot distinguish them.
- Runtime capability probe (recommended addition): at startup, `mmap(RW) → write →
  mprotect(RX)` anonymous probe; if it fails, the environment enforces exec-memory
  restrictions (HarmonyOS with XPM active). This is the only reliable way to
  distinguish platforms under a unified binary.

**Artifacts:**
| Artifact | OpenHarmony | HarmonyOS |
|---|---|---|
| CoreCLR (JIT) layout | ✅ (verified in qemu) | ✅ (user-verified: bun + earlier dotnet build run) |
| NativeAOT binary | ✅ (dotnet/runtime#103627) | ✅ |
| codesign | optional (ignored) | required |

**Signing**: one signed artifact serves both — sign is the last build step, strip
before sign, zero modification after sign; OpenHarmony loader ignores the
signature data.

### 10.3 Key correction (from Oracle review)

The earlier "redist runtimeconfig W^X off" item was **directionally wrong**:
`EnableWriteXorExecute=0` produces **RWX** (not RW+RX split) — the form most
likely blocked by an exec-memory LSM; `=1` (RW→RX publish) is the W^X-compliant
form. But since JIT is user-verified running on HarmonyOS, the correct framing is:
**keep both values as configuration options and let the hardware probe decide**
(§10.4), rather than asserting one is blocked. If the probe shows exec-memory is
allowed, CoreCLR defaults work; if restricted, configure accordingly or ship
NativeAOT.

### 10.4 XPM hardware verification — **DONE (2026-08-31, HarmonyOS HongMeng Kernel 1.13.0, aarch64)**

Probe results (native compile + run on device):

| Probe | Result |
|---|---|
| PROBE1 `mmap(RWX)` | **OK** — anonymous RWX memory allowed |
| PROBE2 `mmap(RW)` + `mprotect(RX)` | **OK** — W^X-compliant JIT path works |
| PROBE3 `prctl(PR_SET_JITFORT)` | **ret=0, errno=0** — no-op, matches kernel-source finding (§9.2.1) |
| PROBE4 JIT-then-execute round-trip | **OK** — executed code from an RX page (aarch64 `ret`), returned 0 |

Supporting verification on the same device:

- **Full CoreCLR+JIT .NET 11.0.0-dev app runs natively** (RID `linux-ohos-arm64`):
  LINQ/generics/lambdas, `Task<int>` + threads, forced GC — all OK.
- **`get_mempolicy` → SIGSYS (signum 31)** confirmed via seccomp (TRAP semantics:
  a SIGSYS handler receives it and the process survives) — validates the
  `numasupport.cpp` NUMA fix on real hardware.

Conclusion: **XPM is not enforcing exec-memory restrictions on the tested
HarmonyOS device; CoreCLR (JIT) is the unified artifact.** Enforcement remains
possible on other devices/vendor configs (§9.2.5), so the defensive posture
stays.

The probe program used (aarch64-corrected, unbuffered output):
`xpm_probe.c` — 4 probes above; build with `cc xpm_probe.c -o xpm_probe && ./xpm_probe`.

```c
// xpm_probe.c — verify anonymous executable-memory policy on HarmonyOS
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

int main(void) {
    // Probe 1: mmap RWX (would be blocked if RWX is forbidden)
    unsigned char *p = mmap(NULL, 4096, PROT_READ|PROT_WRITE|PROT_EXEC,
                            MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED) {
        printf("PROBE1 mmap(RWX): FAILED errno=%d (%s)\n", errno, strerror(errno));
    } else {
        printf("PROBE1 mmap(RWX): OK\n");
        munmap(p, 4096);
    }

    // Probe 2: mmap RW then mprotect to RX (W^X-compliant JIT path)
    p = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED) {
        printf("PROBE2 mmap(RW): FAILED errno=%d\n", errno);
        return 1;
    }
    memset(p, 0xc3, 4096);  // write (RET opcode)
    if (mprotect(p, 4096, PROT_READ|PROT_EXEC) == 0) {
        printf("PROBE2 mmap(RW)+mprotect(RX): OK — W^X JIT path works\n");
    } else {
        printf("PROBE2 mmap(RW)+mprotect(RX): FAILED errno=%d (%s)\n",
               errno, strerror(errno));
    }
    munmap(p, 4096);

    // Probe 3: prctl(PR_SET_JITFORT) behavior (0x6a6974)
    long r = prctl(0x6a6974, 0, 0);
    printf("PROBE3 prctl(PR_SET_JITFORT): ret=%ld errno=%d\n", r, errno);

    // Probe 4: run a small JITted function (RW→RX, then call it)
    p = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    if (p != MAP_FAILED) {
        memset(p, 0xc3, 4096);  // ret
        if (mprotect(p, 4096, PROT_READ|PROT_EXEC) == 0) {
            int (*fn)(void) = (int (*)(void))p;
            int v = fn();
            printf("PROBE4 call JIT fn: OK returned=%d\n", v);
        } else {
            printf("PROBE4 call JIT fn: mprotect FAILED errno=%d\n", errno);
        }
        munmap(p, 4096);
    }
    return 0;
}
```

Build & run on the HarmonyOS machine:
```sh
# cross-compile with OHOS NDK, then sign (HarmonyOS requires .codesign)
aarch64-unknown-linux-ohos-clang xpm_probe.c -o xpm_probe
binary-sign-tool sign -inFile xpm_probe -outFile xpm_probe -selfSign 1
# copy to device, run in a normal app/shell context
./xpm_probe
```

Report back the four probe results; they determine:
- PROBE1/2 → whether anonymous exec memory is allowed (JIT feasible, CoreCLR
  defaults usable) or restricted (need W^X-off config or NativeAOT)
- PROBE3 → whether the JITFORT prctl gate is active
- PROBE4 → whether a real JIT-then-execute round-trip works end-to-end

### 10.5 Recommended path — **adopted (probe passed)**

- **PROBE1/2/4 OK** (hardware-verified): **CoreCLR layout is the unified
  artifact**; keep `EnableWriteXorExecute` configurable, default W^X-compliant
  (`=1`); NativeAOT remains available for constrained devices or future
  XPM-enforcing firmware.
- PROBE1/2 FAIL would have meant: HarmonyOS ships NativeAOT; OpenHarmony ships
  CoreCLR (dual-artifact, one codebase) — not needed on tested hardware.

### 10.6 Open items

- ICU data path on both platforms
- Full syscall whitelist verification (list in §10.1)
- GC `USE_REGIONS` / virtual-reservation behavior on HarmonyOS (dotnet/runtime#111649)
- Signing order & zero-modification verification on OpenHarmony regression

---

## 11. Pending maintainer discussion items (2026-09-01)

Tracked so the next @jkotas reply covers everything at once:

1. **CMake musl fact inheritance — RESOLVED 2026-09-02** (jkotas: "we can pretend
   that ohos is linux flavor when compiling C/C++ code... this is a local decision
   that can be revisited later"). The compile-level linux-flavor treatment
   (CLR_CMAKE_HOST_OS remap + TARGET_LINUX_MUSL) is accepted; the CMake identity
   refactor was **reverted** (commit 8b6923dbc49). The RID graph shape (ohos as its
   own base RID, `ohos -> linux-musl` libc inheritance) is the part that stays
   kernel-agnostic.
2. **NativeAOT SingleEntry.targets ohos→linux mapping** (`_targetOS == 'ohos'` → `linux`) —
   consistent with item 1's resolution: the mapping is a compile-level local decision
   and stays as-is (musl libcFlavor preserved).
3. **(superseded) SIGSYS→ENOSYS PAL handler — REJECTED 2026-09-02** (jkotas:
   "hacks that are trying to leverage holes in seccomp enforcement... should be done
   properly"). The handler (commit 70ba6f54f25) was **reverted**; seccomp-trapped
   syscalls are handled by compile-time `TARGET_OPENHARMONY` guards (close_range,
   inotify_init1, get_mempolicy) + existing runtime/musl fallbacks + the HarmonyOS
   7.1 whitelist channel.
4. **(resolved) seccomp audit** — see `2026-09-01-ohos-syscall-audit.md`; — `TARGET_LINUX_MUSL` / `CLR_CMAKE_HOST_LINUX_MUSL` kept for
   OHOS as an explicit fact (OpenHarmony libc is musl-based). Gates pushing the CMake identity
   refactor (`f924bf5824c`: OHOS keeps its own OS identity, no `CLR_CMAKE_HOST_OS=linux` remap).
2. **NativeAOT SingleEntry.targets ohos→linux mapping** (`_targetOS == 'ohos'` → `linux`, line
   44-50) — the MSBuild-layer equivalent of the old CMake "pretending to be Linux" remap.
   Consistent with item 1, this should become explicit identity + musl inheritance as well
   (ILC-side changes, PR-R3 scope). Raise together with item 1 so the principle is applied
   uniformly across the CMake and MSBuild layers.
3. **(resolved) seccomp audit** — 7 trapped syscalls, close_range/inotify_init1 guarded
   (see `2026-09-01-ohos-syscall-audit.md`); HarmonyOS 7.1 relaxes 3 of 4 bun-negotiated
   syscalls; `inotify_init1` needs a .NET-specific whitelist request or fallback.

---

## 12. PR plan re-review (2026-09-03)

Re-examined the plan against the actual PR state + review evolution. Net:
**the 4-PR runtime split has collapsed to 2 PRs (of 3); the RID-graph PR is
largely folded into the infra PR; one new review-driven item (ohos RID
independence) is now part of #132953.**

### 12.1 Actual state vs plan

| Planned | Actual (2026-09-03) |
|---|---|
| #132827 — sandbox (6 files) | OPEN, in review; waiting on jkoritzinsky naming reply (ohos vs OpenHarmony, am11 09-01) |
| PR-R2 — build infra (16 files) | **#132953 OPEN (11 files)**: build.sh, RuntimeIdentifier.props, Subsets.props, build-commons.sh, configureplatform/compiler/tools.cmake, gen-buildsys.sh, System.Native/CMakeLists.txt, build-native.sh, **+ runtime.json** (R4 leak) |
| PR-R3 — sysroot + NativeAOT (13 files) | **NOT submitted**; content lives on feature branch (review-adjusted) |
| PR-R4 — RID graph + packs (4 files) | runtime.json **folded into #132953**; targetingpacks.targets + ds-portable-rid.c + sfxproj still on feature |
| SDK PR-S1/S2 | **NOT submitted**; RID override graphs, OpenHarmonyCodesign, BundledVersions on `feature/ohos-cross-sdk` |

### 12.2 Review-driven changes since the plan (all landed on feature, mirrored into PRs where the reviewer asked)

1. **RID identity settled (3 revisions):** `linux-ohos` → `ohos` (jkoritzinsky,
   kernel-agnostic) → **`ohos` independent, NO `linux-musl` #import** (jkotas
   09-03: "should NOT import linux-musl - to avoid pretending to be Linux").
   runtime.json (`ohos={}`, `ohos-{arm,arm64,x64}=#import[ohos]`) pushed to
   #132953 (57ec5e393f4). SDK override graphs + Platforms source in sync.
2. **build.sh simplified** to the freebsd/haiku model — no `__PortableTargetOS=ohos`
   (jkotas 09-03); PortableOS derives from TargetOS=ohos directly.
3. **TargetOS is natively `ohos`** (155df040d43 on #132953) — not a linux flavor
   at the MSBuild identity level; TargetsLinux stays true (compile-level facts
   only). `TargetsOpenHarmony` drives the runtime-specific bits.
4. **Compile-level linux remap kept** (jkotas 09-02): configureplatform.cmake
   `CMAKE_SYSTEM_NAME=OHOS` → linux+musl; `_targetOS ohos→linux` in
   SingleEntry.targets. SIGSYS handler **rejected** → compile-time
   TARGET_OPENHARMONY guards instead.
5. **New runtime facts (device-verified, round 3-11):** ilc ships as a CoreCLR
   split-layout apphost (not single-file) with `libc++_shared.so` alongside;
   same-RID publish needs `_originalTargetOS`-keyed ohos exclusions in
   Native.Unix.targets (lld + no Net.Security.Native). These belong to R3/SDK.

### 12.3 Adjusted plan

1. **#132827** (sandbox) — unchanged; resolve the naming Q with jkoritzinsky
   (may need a rename pass if he picks OpenHarmony over ohos).
2. **#132953** (infra + RID graph core) — close jkotas's 2 threads (replied
   09-03); await am11 re-review. runtime.json inclusion makes the standalone
   R4 unnecessary for the runtime graph; **only `targetingpacks.targets`,
   `ds-portable-rid.c`, `sfxproj` remain** as a tiny follow-up (can fold into
   R3 or ship as a 3-file PR).
3. **Runtime R3** (next): sysroot compile fixes (clrfeatures.cmake,
   pal/src/{configure,CMakeLists}, zstd.cmake, libs/CMakeLists.txt,
   extra_libs.cmake, pal_interfaceaddresses.c, apphost/static,
   clrconfigvalues.h W^X default, pal close_range/inotify guards) +
   **NativeAOT BuildIntegration** (SingleEntry.targets remap,
   Native.Unix.targets `_originalTargetOS`/lld/Net.Security) + ILCompiler pack
   (libstdc++/libgcc_s, pkgproj). Use the **review-adjusted** feature-branch
   versions (guards, not the rejected SIGSYS handler).
4. **SDK PR-S1** (new, replaces old S1+S2): RID override graphs (independent
   ohos) + GenerateBundledVersions ohos RIDs + OpenHarmonyCodesign +
   OpenHarmonyEnvironmentDefaults + redist runtimeconfig + dotnet-aot
   exclusion. NativeAOT-publish support is already proven device-side; S2
   folds in as validation evidence.
5. **Validation evidence**: round 1-11 on-device (NativeAOT publish E2E PASS,
   app runs) supersedes the qemu-only check in §4 — cite in PR descriptions.

### 12.4 Open review items to track

- #132827 naming: ohos vs OpenHarmony (am11 leaning OpenHarmony full name) —
  affects RID strings repo-wide if changed again.
- Whether OpenHarmonyCodesign (HarmonyOS-commercial-only enforcement) belongs
  in upstream SDK or stays a downstream patch (§8: OpenHarmony does not
  enforce) — needs a reviewer call before SDK PR-S1.

### 12.5 Decision: no full "mac-style" OHOS branch-out (2026-09-03)

Reviewed whether OHOS should become a full independent branch like macOS
(ilc `TargetOS.OHOS` enum, `_targetOS` passthrough, `_IsOHOS` property face,
CMake decoupling — see `2026-09-03-nativeaot-platform-analysis.md` §7).
**Decision: not doing it — current state is sufficient.**

Rationale (owner-confirmed):
- The value of independence concentrates in the RID + MSBuild judgment plane,
  both already done: ohos is an independent RID (no linux-musl import,
  jkotas 09-03) and Native.Unix.targets keys off `_originalTargetOS`
  (round-10 fix).
- ilc has **no behavior split to make**: its OS logic is a Linux/Apple
  dichotomy and ohos matches linux on every point (analysis §3.2); a
  `TargetOS.OHOS` enum would be an empty dispatch + pure maintenance cost.
- jkotas 09-02 already accepted compile-level linux treatment — a mac-style
  `_targetOS` passthrough / CMake decouple would reopen that settled boundary
  without reviewer demand.
- Keep the compile-level linux remap + `TARGET_OPENHARMONY` guard hybrid
  (Android-style middle ground); revisit only if a real OHOS-specific ilc or
  runtime behavior appears.
