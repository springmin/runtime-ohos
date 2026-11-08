# OpenHarmony NativeAOT static OpenSSL

Status: implementation and device validation complete (2026-11-04). The system CA-store contract
is confirmed from `security_certificate_manager` and re-tested on the device; a second image and
longer throughput sampling remain optional follow-ups.

## Problem

An OpenHarmony NativeAOT application that ships no `libssl.so.3`/`libcrypto.so.3` cannot use the
crypto archive in the NativeAOT runtime pack: that archive is the **dlopen shim** built with
`FEATURE_DISTRO_AGNOSTIC_SSL=1` (and `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC=1`). The shim contains
`opensslshim.c.o` and resolves OpenSSL through `dlopen`; when the payload has only static archives,
it fails closed even if the app link also includes `libssl.a`/`libcrypto.a`.

`StaticOpenSslLinking=true` is not the OpenHarmony path. The upstream target invokes
`build-local.sh`, which is Linux-only and does not cross-compile; it also builds the crypto shim
against the host. OpenHarmony needs a prebuilt direct archive plus the target OpenSSL static
libraries.

## Design

The runtime native archive and the application link must use the same OpenSSL:

1. `src/native/libs/build-native.sh -aotstaticopenssl` sets
   `FEATURE_DISTRO_AGNOSTIC_SSL=0` and `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC=0` (in addition to
   `CMAKE_STATIC_LIB_LINK=1`). `System.Security.Cryptography.Native.OpenSsl-Static` then compiles
   the source objects without `opensslshim.c` and calls the static OpenSSL symbols directly.
   `-linkstaticopenssl` keeps its old meaning for the shared runtime library; the new switch only
   changes the static archive.
2. `scripts/build-ohos-aot-static-openssl.sh` configures and builds that target, then stages a
   self-contained directory:
   - `libSystem.Security.Cryptography.Native.OpenSsl.a` (direct, no shim)
   - `libssl.a`
   - `libcrypto.a`
   - `SHA256SUMS`, `build-info.txt`, OpenSSL license
3. The workload HAP target (`OpenHarmony.Hap.targets`) exposes
   `OpenHarmonyStaticOpenSsl=true` and `OpenHarmonyStaticOpenSslDir=<dir>`. Before `IlcCompile`
   it removes the runtime pack's shim archive from `LinkerArg`, appends the direct archive and
   `-L<dir> -Wl,-Bstatic -lssl -lcrypto -Wl,-Bdynamic`. After `Publish` and before HAP staging it
   deletes any shared crypto files from the publish directory.
4. The app project keeps `PublishAot=true`, `PublishAotUsingRuntimePack=true`, `NativeLib=Shared`,
   and `OpenHarmonyRuntimeMode=aot`; it does **not** set `StaticOpenSslLinking`.

The SDK pack still ships the shim archive by default; an app opts into the static path with the
two properties above. The static OpenSSL archives are supplied by the app builder (license and
provider redistribution obligations stay with the app), not embedded in the public SDK pack.

## Build

```sh
export OHOS_SDK_ROOT=/path/to/ohos-sdk
export OHOS_NDK_HOME="$OHOS_SDK_ROOT"
export ICU_DIR=/path/to/ohos-icu

runtime-ohos/scripts/build-ohos-aot-static-openssl.sh \
    --openssl-dir /path/to/openssl-static \
    --icu-dir "$ICU_DIR" \
    --out-dir /path/to/ohos-aot-static-openssl
```

The OpenSSL inputs must be OpenHarmony arm64 static archives built with `-fPIC`. The script checks
that the produced archive has no `opensslshim.c.o` and reports the staged SHA256SUMS.

Then publish the app with:

```sh
dotnet publish MyApp.csproj -c Release -r openharmony-arm64 \
    -p:PublishAot=true -p:PublishAotUsingRuntimePack=true -p:NativeLib=Shared \
    -p:OpenHarmonyRuntimeMode=aot -p:OpenHarmonyHapPackage=true \
    -p:OpenHarmonyStaticOpenSsl=true \
    -p:OpenHarmonyStaticOpenSslDir=/path/to/ohos-aot-static-openssl
```

`OpenHarmonyStaticCryptoArchive=<path>` can override the direct archive when the directory layout
is different. The HAP target rejects `StaticOpenSslLinking=true` instead of silently invoking the
host-only local build.

## Evidence (HAD-W24, OpenHarmony 7.0.0.111)

Artifacts from the static probe:

| artifact | size |
|---|---:|
| direct crypto archive | 1,031,218 B |
| static `libssl.a` | 1,797,202 B |
| static `libcrypto.a` | 10,122,824 B |
| `libProbe.so` (static link) | 11,688,608 B |
| signed HAP | 14,844,714 B (`9427996ecd637efa93574c24aef4aa1834a49f8ec2fd8aae7817217a49e2e22a`) |

`readelf -d libProbe.so` lists only `libc.so`; `nm -D -u` has no unresolved OpenSSL symbols;
`ar t` of the crypto archive has no `opensslshim.c.o` (535 undefined OpenSSL symbols are resolved
by the static libs at app link). The HAP `libs/arm64-v8a/` contains only `libProbe.so`,
`libopenharmonyhost.so` and `libc++_shared.so`; there is no `libssl.so.3`,
`libcrypto.so.3` or crypto shim `.so`, and the nested `resources/rawfile/dotnet.zip` has no
crypto entries either (three payload entries in the final probe HAP).

Device probe result with `OpenHarmonyTrustMode=both` (custom root + system store):

- SHA-256, AES-GCM, RSA, ECDSA: `PASS`
- X.509 create, expired certificate, default chain rejection, custom-root chain: `PASS`
- `SslStream` custom root, self-signed rejection, wrong-host rejection, expired rejection,
  TLS 1.3: `PASS`
- public HTTPS and default-trust `SslStream`: `PASS`
- `failures=0`

The probe's direct `DllImport("libcrypto.so.3", "OpenSSL_version")` logging intentionally fails in
the static build (there is no `libcrypto.so.3`); this is a probe diagnostic, not a crypto failure.
All managed `System.Security.Cryptography`/`SslStream` calls above use the statically linked
archive.

Off-device gates after the target/host changes: `selftest-hap-targets.sh` is
**128 checks / 0 failed / 1 skipped** (T14 covers the static linker rewrite and the active
preview.31 default CA directory); `selftest-host-trust.sh` is **9 checks / 0 failed** with
**28/28** host-trust unit cases.

### Startup

Measured from the device epoch immediately before `aa start` to the managed
`openssl-probe started` log line, after HAP installation (cold) or `aa force-stop` (warm):

| scenario | runs (ms) | average |
|---|---|---:|
| cold (install + start) | 437, 447, 469 | 451 |
| warm (force-stop + start) | 454, 480, 411, 439, 420 | 441 |

`aa start` itself took 304-366 ms in the warm runs and 319-355 ms in the cold runs.

### TLS throughput

The probe runs a 64 MiB loopback TLS session through `SslStream` after the crypto checks. The
static runs measured 64 MiB in 101-321 ms, **199-633 MB/s** (median 238.58 MB/s across five warm
runs; the fastest warm run was 632.96 MB/s and a cold run 626.88 MB/s). The spread is the
loopback scheduler/allocator, not a link failure; the same binary uses only the static OpenSSL
archives.

### Memory

Ten-minute RSS/HWM sample from the static AOT probe (one process, 30 threads after startup):

| elapsed | VmRSS (kB) | VmHWM (kB) |
|---|---:|---:|
| +0.5 min | 126,076 | 126,240 |
| +1 min | 117,172 | 126,240 |
| +3 min | 117,704 | 126,240 |
| +5 min | 118,592 | 126,240 |
| +7 min | 119,448 | 126,240 |
| +8.5 min | 119,660 | 126,240 |
| +10 min | 119,140 | 126,240 |

After the one-time startup/allocator warm-up (RSS dropped from 126 MB to 117 MB by the first
minute), the process stayed within ~117.1-119.7 MB for the remaining nine minutes, with a
short-lived 121.3 MB sample and 30-35 threads. The five-minute earlier run showed a one-time
12 MB step; the ten-minute run did not repeat it. No monotonic memory trend is visible in this
window.

## System CA store contract

The formal store is `/system/etc/security/certificates`:
`openharmony/security_certificate_manager@2d9792c` (`config/BUILD.gn`) installs the 125
OpenSSL-hashed system CAs with `relative_install_dir = "security/certificates"` into the
`system` and `updater` images. The `/etc/ssl/certs/cacert.pem` file observed on HAD-W24 is not
produced by that part and is not guaranteed across images.

The host default was therefore switched to `/system/etc/security/certificates`, with a
compatibility fallback to `/etc/ssl/certs` when the default directory is absent. Re-tested on
HAD-W24 with a static AOT HAP:

```text
trust: mode=both ... dir=/system/etc/security/certificates app=1 system=1
ssl_cert_dir_env=/system/etc/security/certificates
http_default_trust=PASS
sslstream_public_default=PASS
failures=0
```

## Remaining work

- Repeat the TLS throughput loop and memory sample on a second image if one becomes available.
- Decide whether the direct archive/static OpenSSL layout belongs in a release asset or stays a
  builder-supplied directory. The current solution keeps it outside the public SDK pack.

## Files

- `src/native/libs/build-native.sh` — `-aotstaticopenssl`
- `src/native/libs/build-native.proj` — `AotStaticOpenSsl` pass-through
- `scripts/build-ohos-aot-static-openssl.sh` — archive/layout builder
- `ohos-workload/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.31/targets/OpenHarmony.Hap.targets`
  — `OpenHarmonyStaticOpenSsl` / `OpenHarmonyStaticOpenSslDir`
- `ohos-workload/src/OpenHarmonyHost/host_trust.c` / `host_trust.h` — formal system CA
  directory and compatibility fallback
- `ohos-workload/docs/openharmony-hap-packaging.md` — packaging/static-OpenSSL/CA contract
