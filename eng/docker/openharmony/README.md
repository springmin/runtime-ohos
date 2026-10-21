# OpenHarmony cross-build image (draft)

This image contains everything the OpenHarmony arm64 build needs, so CI jobs do
not have to download the SDK or build the target assets:

- OpenHarmony SDK 6.0-Release (NDK) at `/opt/ohos-sdk/linux`, `OHOS_NDK_HOME` set
- OpenSSL 3.3.1, static and PIC, at `/opt/ohos-assets/openssl`
- ICU 75.1, host + cross, static, at `/opt/ohos-assets/icu`
- `OHOS_CMAKE_ARGS` with `CMAKE_ICU_DIR` and the four `OPENSSL_*` paths

The recipe is the same one validated by the fork smoke workflow
(`.github/workflows/ohos-build-smoke.yml`).

## Build

```bash
docker build -t ohos-ci:6.0 .
```

## Verify

```bash
docker run --rm ohos-ci:6.0 bash -lc '
  test -f "$OHOS_NDK_HOME/native/build/cmake/ohos.toolchain.cmake"
  test -f "$OHOS_ICU_DIR/lib/libicuuc.a"
  test -f "$OHOS_OPENSSL_DIR/lib/libcrypto.a"
  echo ok
'
```

## Use

```bash
./build.sh clr.runtime+libs.native -os openharmony -arch arm64 -cross -c Release \
  -cmakeargs "$OHOS_CMAKE_ARGS"
```

For GitHub Actions, use the image as the job container; for Azure Pipelines,
add it as a container resource and point the platform entry at it. With the
image, the job no longer needs `preBuildSteps` for the SDK/OpenSSL/ICU.

## Upstream notes

- For `dotnet/dotnet-buildtools-prereqs-docker`, move this to
  `src/azurelinux/4.0/net12.0/cross/openharmony/<ver>/amd64/Dockerfile` and use
  the repository's Azure Linux base image instead of `ubuntu:24.04`.
- The OpenSSL and ICU tarballs are pinned by version; their sha256 values still
  need to be added to `build-ohos-assets.sh`.
- The image is a draft; it has not been built in this environment. The runtime
  build itself was validated by the fork smoke workflow.
