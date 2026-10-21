# OpenHarmony CI smoke (fork)

Date: 2026-10-21

Workflow: `.github/workflows/ohos-build-smoke.yml` (branch `ci/ohos-smoke`)

Purpose: validate the OpenHarmony cross-build without the prereqs image. The
job downloads the OpenHarmony SDK, builds the target-side ICU/OpenSSL assets,
and cross-builds `clr.runtime+libs.native` for `openharmony-arm64`.

## Inputs

- SDK: `https://repo.huaweicloud.com/openharmony/os/6.0-Release/ohos-sdk-windows_linux-public.tar.gz`
  - SHA-256: `a315834ac133625efc912bd078f3e2b2550868d04aef1b5aa4f9679c8b3c9d8e`
  - Extract `linux/native-linux-x64-*.zip`; use `$RUNNER_TEMP/ohos-sdk/linux` as `OHOS_NDK_HOME`.
- OpenSSL 3.3.1: static, `no-shared no-tests no-async no-apps -fPIC`, `--libdir=lib`.
- ICU 75.1: host build (tools/data) + cross build, `--enable-static --disable-shared`,
  `--with-cross-build=<host build dir>`.

Both assets install into `$RUNNER_TEMP/ohos-assets` and are cached with key
`ohos-assets-${runner.os}-openssl-3.3.1-icu-75.1-v1`.

## Build

```bash
export OHOS_NDK_HOME="$RUNNER_TEMP/ohos-sdk/linux"
./build.sh clr.runtime+libs.native -os openharmony -arch arm64 -cross -c Release \
  -cmakeargs "-DCMAKE_ICU_DIR=$RUNNER_TEMP/ohos-assets/icu \
  -DOPENSSL_ROOT_DIR=$RUNNER_TEMP/ohos-assets/openssl \
  -DOPENSSL_INCLUDE_DIR=$RUNNER_TEMP/ohos-assets/openssl/include \
  -DOPENSSL_CRYPTO_LIBRARY=$RUNNER_TEMP/ohos-assets/openssl/lib/libcrypto.a \
  -DOPENSSL_SSL_LIBRARY=$RUNNER_TEMP/ohos-assets/openssl/lib/libssl.a"
```

## Results

- `39549305431` (head `0aec810eb6e`): success, 11 minutes, all steps green.
- `39555889909` (head `6505250a4bc`): success in 7 minutes with a cache hit
  (OpenSSL/ICU builds skipped). The same recipe plus build-output assertions
  (`libcoreclr.so`, `libSystem.Native.so`, `libSystem.Globalization.Native.so`,
  `libSystem.Security.Cryptography.Native.OpenSsl.so`).

## Notes

- The OHOS sysroot ships stub ICU (`libicu.so` is ~31 KB, headers incomplete) and
  no target OpenSSL headers/libraries; host `libicu-dev`/`libssl-dev` do not help
  a cross build.
- `OHOS_NDK_HOME` must be exported for `build-runtime.sh`; setting it only for the
  asset builds is not enough.
- `clr.runtime` alone still configures the static apphost, so it needs target
  OpenSSL even before `libs.native` is built.

## Follow-up

- `dotnet/dotnet-buildtools-prereqs-docker#1778`: decide whether the prereqs image
  is still required, or whether a download step is acceptable for the official leg.
- Upstream CI leg (issue thread `#132866`): add an `openharmony_arm64` leg using
  either the image or the download recipe above.
