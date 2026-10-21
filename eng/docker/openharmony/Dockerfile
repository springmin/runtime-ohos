# syntax=docker/dockerfile:1

# OpenHarmony cross-build image: SDK/NDK plus the target-side static OpenSSL and
# ICU libraries. The image keeps the same recipe as the fork CI smoke workflow.
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG OHOS_SDK_URL=https://repo.huaweicloud.com/openharmony/os/6.0-Release/ohos-sdk-windows_linux-public.tar.gz
ARG OHOS_SDK_SHA=a315834ac133625efc912bd078f3e2b2550868d04aef1b5aa4f9679c8b3c9d8e
ARG OPENSSL_VERSION=3.3.1
ARG ICU_VERSION=75.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build python3 curl unzip perl ca-certificates \
        libssl-dev libicu-dev zlib1g-dev libxml2-dev libkrb5-dev \
    && rm -rf /var/lib/apt/lists/*

COPY build-ohos-assets.sh /usr/local/bin/build-ohos-assets
RUN chmod +x /usr/local/bin/build-ohos-assets \
    && OHOS_SDK_URL="$OHOS_SDK_URL" OHOS_SDK_SHA="$OHOS_SDK_SHA" \
       OPENSSL_VERSION="$OPENSSL_VERSION" ICU_VERSION="$ICU_VERSION" \
       /usr/local/bin/build-ohos-assets

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build python3 perl ca-certificates curl unzip \
        libssl-dev libicu-dev zlib1g-dev libxml2-dev libkrb5-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/ohos-sdk/linux /opt/ohos-sdk/linux
COPY --from=builder /opt/ohos-assets /opt/ohos-assets

ENV OHOS_NDK_HOME=/opt/ohos-sdk/linux \
    OHOS_ICU_DIR=/opt/ohos-assets/icu \
    OHOS_OPENSSL_DIR=/opt/ohos-assets/openssl \
    OHOS_CMAKE_ARGS="-DCMAKE_ICU_DIR=/opt/ohos-assets/icu -DOPENSSL_ROOT_DIR=/opt/ohos-assets/openssl -DOPENSSL_INCLUDE_DIR=/opt/ohos-assets/openssl/include -DOPENSSL_CRYPTO_LIBRARY=/opt/ohos-assets/openssl/lib/libcrypto.a -DOPENSSL_SSL_LIBRARY=/opt/ohos-assets/openssl/lib/libssl.a"

WORKDIR /workspace
CMD ["/bin/bash"]
