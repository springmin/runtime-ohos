# OHOS On-Device Verification — runtime / sdk / aspnetcore (2026-09-01)

**RID:** `ohos` (renamed from `linux-ohos`, jkoritzinsky review: kernel-agnostic)
**Branch:** `feature/ohos-cross-runtime` (runtime), `feature/ohos-cross-sdk` (sdk),
`feature/ohos-cross-compile` (aspnetcore) — all pushed, working trees clean.
**Version:** `11.0.0-rc.1.26451.1` (runtime/aspnetcore), `11.0.100-rc.1.26451.1` (sdk).
**Cross-build verified:** `-os ohos -arch arm64 --cross` produces
`ohos.arm64.Release/{libcoreclr.so, corerun, singlefilehost}` (aarch64).
**NativeAOT publish verified** on x64 host: `dotnet publish -r ohos-arm64 -p:PublishAot=true`
→ aarch64 musl ELF (qemu runs blocked by membarrier/mremap — device required).

This document is the on-device (HarmonyOS hardware) verification runbook. Run on
the device, fill in the checkboxes, and report back.

---

## 0. Prerequisites

- HarmonyOS device with developer mode + shell (HiShell) access.
- `binary-sign-tool` available (OHOS NDK `toolchains/lib/` or DevBox).
- Runtime/sdk/aspnetcore branches pushed with the `ohos` RID rename
  (commits `91572f4362c` / `02cc6e4058` / `bbe515e36e`).
- **Prefer the published rc.1.26451.1 release artifacts** (skip local rebuild):
  `dotnet-runtime-11.0.0-rc.1.26451.1-ohos-arm64.tar.gz`,
  `dotnet-sdk-11.0.100-rc.1.26451.1-ohos-arm64.tar.gz`,
  `aspnetcore-runtime-11.0.0-rc.1.26451.1-ohos-arm64.tar.gz`
  (springmin/{runtime,sdk,aspnetcore}-ohos releases; install via
  `sh install-dotnet-ohos.sh` from the sdk repo docs).

## 1. Runtime verification

### 1.1 Build (host, x64 cross-compile) — optional if using release artifacts

```sh
# from runtime repo, OHOS_NDK_HOME set
./build.sh -os ohos -arch arm64 --cross -c Release -lc Release -rc Release \
  /p:BuildHostTools=true \
  /p:RuntimeIdentifierGraphPath="$(pwd)/.dotnet/sdk/11.0.100-preview.6.26359.118/RuntimeIdentifierGraph.json" \
  /p:IncludeSymbols=false \
  /p:PreReleaseVersionLabel=rc /p:PreReleaseVersion=1 /p:OfficialBuildId=20260901.1 \
  -cmakeargs "-DOPENSSL_ROOT_DIR=/tmp/openssl-ohos -DOPENSSL_INCLUDE_DIR=/tmp/openssl-ohos/include \
  -DOPENSSL_CRYPTO_LIBRARY=/tmp/openssl-ohos/lib/libcrypto.a -DOPENSSL_SSL_LIBRARY=/tmp/openssl-ohos/lib/libssl.a \
  -DCMAKE_ICU_DIR=/tmp/icu-ohos-install"
```

> Note: the TestHost pack step has a pre-existing host/target corerun path mixup
> unrelated to the rename; core artifacts (libcoreclr.so/corerun/singlefilehost)
> are produced. If building only the runtime packs is needed, use the subsets
> that skip TestHost. Fixed in commits `6cd14639177` (RuntimeBinDir ohos path) —
> the TestHost pack now resolves `ohos.arm64.Release/corerun` correctly.

### 1.2 Deploy to device

```sh
# Collect artifacts (or extract the released dotnet-runtime-*.tar.gz)
ART=artifacts/bin/coreclr/ohos.arm64.Release
# Sign every ELF (HarmonyOS requires .codesign)
find $ART -type f -exec file {} \; | grep ELF | cut -d: -f1 | \
  xargs -I{} binary-sign-tool sign -inFile {} -outFile {} -selfSign 1
# Copy to device (adjust path/transport)
adb push $ART /data/local/tmp/dotnet-ohos
```

### 1.3 On-device checks

```sh
cd /data/local/tmp/dotnet-ohos
./dotnet --info
```

- [ ] **RID reports `ohos-arm64`** (not `linux-ohos-arm64`)
- [ ] Runtime version prints 11.0.0-rc.1.26451.1
- [ ] CoreCLR JIT loads (no "JIT banned" / exec-memory errors)

### 1.4 Runtime functional smoke

```sh
# Run a small app exercising JIT: LINQ, generics, threads, GC
./dotnet run --project <app> -r ohos-arm64
```

- [ ] LINQ / generics / lambdas execute
- [ ] `Task<int>` + threads complete
- [ ] Forced GC (GC.Collect) succeeds
- [ ] `get_mempolicy` is not called (NUMA fix active — no SIGSYS)

## 2. SDK verification

### 2.1 Build SDK redist (host) — optional if using release artifacts

```sh
# from sdk repo, with local feed (ohos packs) + updated RID graphs
./build.sh -os ohos -arch arm64 -c Release \
  /p:MicrosoftNETCoreAppHostPackageVersion=11.0.0-rc.1.26451.1 \
  /p:MicrosoftNETCoreAppRuntimePackageVersion=11.0.0-rc.1.26451.1 \
  /p:RestoreAdditionalProjectSources=$PWD/artifacts/ohos-local-feed \
  /p:RidGraphOverrideRuntimeJson=$PWD/eng/RuntimeIdentifierGraph.ohos.json \
  /p:RidGraphOverridePortableJson=$PWD/eng/PortableRuntimeIdentifierGraph.ohos.json \
  /p:IncludeAspNetCoreRuntime=false
```

### 2.2 On-device publish test

```sh
# on device, with the built SDK + runtime layout
dotnet publish -r ohos-arm64 -p:PublishAot=true   # NativeAOT path
dotnet publish -r ohos-arm64                      # CoreCLR self-contained path
```

- [ ] `dotnet publish -r ohos-arm64` restores/resolves `ohos-*` packs (not linux-ohos)
- [ ] NativeAOT publish produces a signed, runnable aarch64 ELF
- [ ] CoreCLR self-contained publish runs the app
- [ ] OpenHarmonyCodesign auto-signs outputs (`.codesign` present, `llvm-readelf -S`)

> **NativeAOT note (host-verified 2026-09-01):** publish needs a x64 host SDK whose
> BundledVersions includes `ohos-arm64` ILCompiler support (built with
> `-os linux -arch x64` + GenerateBundledVersions ohos lists). The ILCompiler pack
> must be the runtime-built one (ohos `_targetOS`→linux mapping in SingleEntry.targets,
> commit `91572f4362c`); the linked ELF is aarch64 musl. On-device run is the remaining
> gate (qemu membarrier/mremap limitation).

## 3. aspnetcore verification

### 3.1 Rebuild aspnetcore runtime for ohos — optional if using release artifacts

```sh
# from aspnetcore repo — pack references now use ohos-* (Dependencies.props)
# rebuild aspnetcore-runtime, target RID ohos-arm64
```

- [ ] `Microsoft.NETCore.App.Runtime.ohos-*` + `Crossgen2.ohos-*` resolve (not linux-ohos)
- [ ] `BundledToolTargetRuntimeIdentifiers` includes `ohos-*`

### 3.2 On-device web app

```sh
# build a minimal ASP.NET Core web app targeting ohos-arm64
dotnet new web -o hello && cd hello
dotnet publish -r ohos-arm64 -p:PublishAot=true   # or self-contained
# run on device
./hello
```

- [ ] Kestrel listens on a port, serves HTTP response
- [ ] Runtimeconfig resolves Microsoft.AspNetCore.App 11.0.0-rc.1.26451.1 (no version-mismatch)

## 4. Cross-cutting checks

- [ ] **XPM probe** (re-run if desired): `mmap(RWX)` / `mmap(RW)+mprotect(RX)` /
      `prctl(PR_SET_JITFORT)` / JIT-call — expect all OK on tested device
- [ ] **codesign**: all deployed ELFs carry `.codesign`; unsigned ELF fails with
      permission denied on enforcing devices (expected)
- [ ] **get_mempolicy**: app starts without SIGSYS (numasupport.cpp fix)
- [ ] **TMPDIR**: shared-memory files (named mutex) under `$TMPDIR` not `/tmp`

## 5. Report back

For each section, report:
- Device model + HarmonyOS version + kernel (linux-ohos vs harmony-ohos)
- Checkbox results (✅/❌ with error output)
- Any `ohos` RID regression (e.g., RID printed wrong, pack not found)

If all pass, the `ohos` rename is validated end-to-end; proceed to update the
upstream PRs (#132827 sandbox fixes, #132953 build infra) with the new RID once
jkoritzinsky confirms the final name (`ohos` vs `openharmony`).

---

## 6. Verification results — executed 2026-09-01 on HarmonyOS hardware

**Device**: HarmonyOS, HongMeng Kernel 1.13.0 (aarch64), HarmonyOS commercial.

**Artifacts tested**: released `v11.0.100-rc.1.26451.1-ohos` (sdk),
`v11.0.0-rc.1.26451.1-ohos` (runtime + aspnetcore) tarballs; installed via
`install-dotnet-ohos.sh` (SDK+runtime+aspnetcore; all ELFs signed).

### §1 Runtime — ✅ PASS (with one environment requirement)

- [x] RID reports `ohos-arm64` (not `linux-ohos-arm64`) — `dotnet --info`
- [x] Runtime version `11.0.0-rc.1.26451.1`; SDK `11.0.100-rc.1.26451.1`
- [x] CoreCLR JIT loads; full smoke app (LINQ/generics/delegates/`Task`+threads/
      forced GC) runs: `rid=ohos-arm64`, all checks OK
- [x] `get_mempolicy` not called (NUMA fix) — app starts without SIGSYS
- ⚠️ **W^X default (W^X=1) SIGSEGVs at startup; `DOTNET_EnableWriteXorExecute=0`
      required.** Root cause (probe-verified): the HongMeng kernel **denies
      `PROT_EXEC` on file-backed (memfd/shm) mappings — all variants
      (MAP_SHARED/MAP_PRIVATE, mprotect/direct mmap) return EACCES; anonymous
      private mappings are allowed**. CoreCLR's W^X double-mapping allocator
      (memfd-based) therefore cannot work. Fix committed:
      `clrconfigvalues.h` defaults `EnableWriteXorExecute` to 0 on
      `TARGET_OPENHARMONY` (mirrors riscv64 precedent) — commit
      `678ac21836c` on `feature/ohos-cross-runtime`. The released artifacts
      predate this fix; SDK-launched processes work because
      `OpenHarmonyEnvironmentDefaults` injects `DOTNET_EnableWriteXorExecute=0`.
- ⚠️ **Named mutex fails on released runtime**: `IOException: Read-only file
      system : '/tmp/.dotnet'` — the TMPDIR fix (`Path.GetTempPath()` on
      `TARGET_OPENHARMONY`) is **not in the released runtime build**. Verified
      `/tmp` is read-only and `$TMPDIR` writable on device. Requires a runtime
      rebuild from the current feature branch (which contains the fix).

### §2 SDK publish — ✅/❌ (split)

- [x] `dotnet publish -r ohos-arm64` (CoreCLR self-contained/framework-dependent)
      — restore resolves `ohos-*` packs from the local OHOS feed; published
      apphost runs (with W^X off as above)
- [x] `dotnet publish -r ohos-arm64 -p:PublishAot=true` — pipeline reaches
      `ilc` (ILCompiler found); **NativeAOT codegen itself FAILED on device**
- ❌ **Root cause**: the released ILCompiler pack
      (`runtime.ohos-arm64.Microsoft.DotNet.ILCompiler 11.0.0-preview.7.26381.103`)
      is **glibc-linked**: DT_NEEDED `libdl.so.2/libpthread.so.0/libstdc++.so.6/
      libm.so.6/libc.so.6/ld-linux-aarch64.so.1` — the device has only the musl
      loader (`/lib/ld-musl-aarch64.so.1`) and libc++; `ilc` cannot run
      ("No such file or directory"/loader errors). Additionally the pack was
      built without `.note.ohos.ident` (kernel exec check) and its files lack
      the exec bit (0644). **Requires rebuilding the ILCompiler pack from the
      current branch** (incl. `_targetOS→linux` SingleEntry mapping, commit
      `91572f4362c`) with the OHOS musl toolchain, then republishing.
- Workaround exercised on device: patch `ilc` interp →
      `/lib/ld-musl-aarch64.so.1` + sign with the SDK's own `selfsign` tool —
      exec succeeds but glibc deps remain unsatisfiable; not a viable path.

### §3 ASP.NET Core — ✅ PASS

- [x] Minimal web app published `-r ohos-arm64`, Kestrel listening on
      `http://127.0.0.1:5080`; `GET /` → "Hello from ASP.NET Core on OHOS!";
      `GET /info` → `RID=ohos-arm64`, HarmonyOS HongMeng Kernel 1.13.0
- [x] No version mismatch (Microsoft.AspNetCore.App 11.0.0-rc.1.26451.1)

### §4 Cross-cutting

- [x] XPM probe: anonymous `mmap(RWX)` / `mmap(RW)+mprotect(RX)` /
      `prctl(PR_SET_JITFORT)` (no-op) / JIT-call — **all OK**; **new finding:
      file-backed (memfd) `PROT_EXEC` denied (EACCES)** — see §1
- [x] codesign: SDK's built-in signer verified working — `OpenHarmonyCodesign`
      MSBuild task + `ElfSelfSigner` + standalone `selfsign` (built and run on
      device; preserves owner/perms, re-signs with `--force`). **Do not use
      system `binary-sign-tool`**: it changes ownership and write-seals signed
      files (subsequent writes denied), and cannot re-sign.
- [x] `get_mempolicy` → SIGSYS (TRAP, recoverable) confirmed on device
- [x] `/tmp` read-only confirmed; `$TMPDIR` writable; shared-memory dir under
      `$TMPDIR` — runtime fix required (see §1 named-mutex finding)

### §5 Conclusion

- **`ohos` RID rename validated end-to-end** (RID printed correctly, packs
  resolve, apps build/publish/run on device).
- **Three rebuild-and-republish items** for the next RC (current feature
  branch fixes them):
  1. Runtime: W^X default off (commit `678ac21836c`) + TMPDIR fix (in PR
     #132827) — released rc.1.26451.1 lacks both.
  2. ILCompiler pack: rebuild musl-linked, with ohos note + exec bit, from
     current branch; release as rc.1.26451.1 (or newer).
  3. SDK: `EnableWriteXorExecute` runtimeconfig bake for OHOS apps (currently
     only env-var injection via OpenHarmonyEnvironmentDefaults covers
     SDK-launched processes; direct-executed published apps need the bake or
     the runtime default from item 1).

---

## 6. Re-verification — rebuilt 2026-09-02 (items 1-3 from §5)

The three §5 rebuild items are now in the **re-released** `v11.0.0-rc.1.26451.1-ohos`
(2026-09-02 update). Re-run on device:

- [ ] **W^X default off**: `DOTNET_EnableWriteXorExecute` NOT set → app starts without
      SIGSEGV (W^X=0 baked as default; no env injection needed).
- [ ] **Named mutex / TMPDIR**: app using named mutex starts (no
      "Read-only file system : '/tmp/.dotnet'" — shared memory honors `$TMPDIR`).
- [ ] **Device-side NativeAOT (ilc)**: `dotnet publish -r ohos-arm64 -p:PublishAot=true`
      on device reaches `ilc` and completes. `ilc` now runs because the ILCompiler pack
      ships `libstdc++.so.6` + `libgcc_s.so.1` (aarch64 musl); install script
      (`install-dotnet-ohos.sh`) deploys them to `/lib` (or `$INSTALL_DIR/lib`).
      If ilc still can't load: `export LD_LIBRARY_PATH=$INSTALL_DIR/lib` (or /lib).
- [ ] **Direct-executed published app** (not SDK-launched): runs with W^X off by
      default (runtime default, no env needed).

---

## 7. Re-verification results — executed 2026-09-02 on HarmonyOS hardware

**Device:** HarmonyOS, HongMeng Kernel 1.13.0 (aarch64).
**Artifacts:** re-released `v11.0.100-rc.1.26451.1-ohos` (sdk) /
`v11.0.0-rc.1.26451.1-ohos` (runtime + aspnetcore, 2026-09-02 update) +
`runtime.ohos-arm64.Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.1.nupkg`.
**Install script:** `install-dotnet-ohos.sh` — ✅ works (all three tarballs
install, ELF signing, RID `ohos-arm64`).

### Results

- ❌ **W^X default off (§6 item 1): FAIL** — `dotnet run` works (SDK env
  injection), but a **directly executed** published app without
  `DOTNET_EnableWriteXorExecute` still SIGSEGVs; with `=0` it runs. The
  release runtime's compiled default is still W^X=1 — the
  `clrconfigvalues.h` default-off fix (`678ac21836c`) is **not in the release
  build**.
- ❌ **Named mutex / TMPDIR (§6 item 2): FAIL** — still
  `IOException: Read-only file system : '/tmp/.dotnet'`. The TMPDIR fix
  (projitems plural rename `4c77bcca431` + `SharedMemoryManager` TARGET_OPENHARMONY
  path) is **not in the release build**.
- ❌ **Device-side NativeAOT (§6 item 3): FAIL** — three blockers found in order:
  1. `MSB4024: XML comment cannot contain '--'` — `SingleEntry.targets` comment
     from `91572f4362c` contains `--targetos`. **Fixed** (branch commit
     `1e5e83cb012`); the pack must be rebuilt.
  2. SDK BundledVersions still pins preview.7 packs — worked around locally by
     patching the installed SDK + using the full rc.1 pack set from the release.
  3. **ilc executes (musl loader + codesign OK) but cannot load the shipped C++
     runtime**: the bundled `libstdc++.so.6`/`libgcc_s.so.1` have
     `DT_NEEDED libc.musl-aarch64.so.1`, which the **device's musl loader does
     not resolve** (it only self-identifies as `libc.so`; every working dotnet
     native lib NEEDs `libc.so`). The other machine verified the pack in qemu,
     where its sysroot musl provides the `libc.musl` name — the real device
     differs. Loading also fails via LD_LIBRARY_PATH (env is honored — proven
     with a control test); the mismatch is the NEEDED SONAME, not the search path.
- ❌ **Direct-executed published app (§6 item 4): FAIL** — same root cause as
  item 1 (W^X default not baked into the release runtime).

### Action items for the rebuild (other machine)

1. **Rebuild the runtime** from the current `origin/feature/ohos-cross-runtime`
   (includes W^X default-off `clrconfigvalues.h`, the projitems plural fix, the
   TMPDIR chain, the SIGSYS→ENOSYS PAL handler) and re-release.
2. **Rebuild the cxx-runtime bundle** (`OHOS_CXXRUNTIME_DIR`) with the **OHOS
   NDK musl** so `libstdc++.so.6`/`libgcc_s.so.1` carry `DT_NEEDED libc.so`
   (matching every working native lib on the device), not
   `libc.musl-aarch64.so.1`; alternatively pursue the §10.1 libstdc++→libc++
   conversion.
3. **Rebuild the ILCompiler pack** including the `SingleEntry.targets` XML fix
   (`1e5e83cb012`).
4. Pack `ilc` and the runtime libs with the exec bit set and pre-sign them
   (the new `sign-ohos-release.sh`), since the nupkg ships 0644/unsigned.

---

## 8. Re-verification round 2 — rebuilt release (2026-09-02 11:37+) results

**Artifacts:** rebuilt `v11.0.0-rc.1.26451.1-ohos` (2026-09-02T11:37 runtime / 11:54 ILCompiler / 11:58 SDK), **pre-signed** (install script reported signed=0, already_signed=27/49 — `sign-ohos-release.sh` works).

### Results

- ✅ **W^X default off (§6/§7 item 1): PASS** — directly executed published app
  runs without `DOTNET_EnableWriteXorExecute`; the `clrconfigvalues.h` default-off
  fix is in the rebuilt runtime.
- ✅ **Named mutex / TMPDIR (§6 item 2): PASS** — named mutex acquired,
  `Path.GetTempPath()` = `$TMPDIR` (`/data/storage/el2/base/tmp/`); the TMPDIR fix
  is in the rebuilt runtime.
- ❌ **Device-side NativeAOT (§6 item 3): STILL BLOCKED — new root cause found.**
  The rebuilt cxx-runtime fixed the SONAME (`libstdc++.so.6`/`libgcc_s.so.1` now
  carry `DT_NEEDED libc.so`), but the device loader **requires the
  `.note.ohos.ident` note on dlopen'd libraries**: control experiment — removing
  the note from a locally compiled `.so` makes `dlopen` fail with "Permission
  denied". The cross-built cxx-runtime libs lack the note → `ilc` cannot load
  them on the real device. (qemu's loader does not enforce the note, which is why
  the pack passed host-side verification.)
- ✅ **Direct-executed published app (§6 item 4): PASS** — same mechanism as the
  W^X item.

### Action item (other machine) — 3rd round cxx-runtime rebuild

Rebuild `OHOS_CXXRUNTIME_DIR` libstdc++/libgcc_s with the **OHOS NDK clang**
(the device-side harmonybrew clang 21.1.8 emits `.note.ohos.ident` automatically
— every locally compiled `.so` carries it; the current bundle was built with a
toolchain that did not). Device-loader requirement confirmed by control
experiments: dlopen of a `.so` without the note fails with "Permission denied";
the note must be present as a section with content in a mapped LOAD segment
(section-only-at-file-end and content-only injections both fail).

Self-check before publishing the rebuilt ILCompiler pack:
```sh
llvm-readelf -S libstdc++.so.6 | grep ohos.ident   # must show .note.ohos.ident
llvm-readelf -d libstdc++.so.6 | grep NEEDED       # must show libc.so (not libc.musl-*)
```
Then re-release the ILCompiler pack and re-verify on device (item 3).
