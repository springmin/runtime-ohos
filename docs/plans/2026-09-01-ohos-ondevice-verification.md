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
