#!/usr/bin/env bash
# Build the direct NativeAOT crypto archive for OpenHarmony and stage it with
# the static OpenSSL libraries the app link needs.
#
# The normal OpenHarmony native build produces a dlopen-shim crypto archive
# (System.Security.Cryptography.Native.OpenSsl.a), which is what the NativeAOT
# runtime pack ships for apps that load libssl.so/libcrypto.so at runtime. A
# fully static app cannot use that archive even when it also links libssl.a/
# libcrypto.a: the shim still calls dlopen and fails closed when no shared
# OpenSSL exists. This script builds the same sources with
# FEATURE_DISTRO_AGNOSTIC_SSL=0 and FEATURE_DISTRO_AGNOSTIC_SSL_STATIC=0, so
# the archive contains direct OpenSSL calls and leaves the static libs to the
# application link.
#
# Usage:
#   scripts/build-ohos-aot-static-openssl.sh \
#     --openssl-dir /path/to/openssl-static \
#     [--icu-dir /path/to/ohos-icu] \
#     [--out-dir artifacts/bin/ohos-aot-static-openssl/openharmony-arm64] \
#     [--configuration Release] [--arch arm64] [--clean]
#
# --openssl-dir may be either an OpenSSL install prefix (include/ + lib/) or
# a build tree with include/ and libssl.a + libcrypto.a at its root. The
# libraries must be OpenHarmony arm64 static archives built with -fPIC.
#
# The resulting directory contains:
#   libSystem.Security.Cryptography.Native.OpenSsl.a
#   libssl.a
#   libcrypto.a
#   SHA256SUMS
#   build-info.txt
#
# Pass that directory to the workload HAP target:
#   -p:OpenHarmonyStaticOpenSsl=true \
#   -p:OpenHarmonyStaticOpenSslDir=<out-dir>
# See docs/plans/2026-11-04-ohos-nativeaot-static-openssl.md.

set -euo pipefail

usage() {
    sed -n '2,/^set -euo pipefail/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

OPENSSL_DIR=""
ICU_DIR="${ICU_DIR:-}"
OUT_DIR=""
CONFIGURATION=Release
ARCH=arm64
CLEAN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --openssl-dir)
            [ $# -ge 2 ] || { echo "error: --openssl-dir needs a path" >&2; exit 2; }
            OPENSSL_DIR="$2"; shift 2 ;;
        --icu-dir)
            [ $# -ge 2 ] || { echo "error: --icu-dir needs a path" >&2; exit 2; }
            ICU_DIR="$2"; shift 2 ;;
        --out-dir)
            [ $# -ge 2 ] || { echo "error: --out-dir needs a path" >&2; exit 2; }
            OUT_DIR="$2"; shift 2 ;;
        --configuration)
            [ $# -ge 2 ] || { echo "error: --configuration needs Release or Debug" >&2; exit 2; }
            CONFIGURATION="$2"; shift 2 ;;
        --arch)
            [ $# -ge 2 ] || { echo "error: --arch needs a value" >&2; exit 2; }
            ARCH="$2"; shift 2 ;;
        --clean)
            CLEAN=1; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            echo "error: unknown argument: $1" >&2
            usage >&2
            exit 2 ;;
    esac
done

if [ -z "$OPENSSL_DIR" ]; then
    echo "error: --openssl-dir is required" >&2
    usage >&2
    exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
BUILD_NATIVE="$REPO_ROOT/src/native/libs/build-native.sh"

if [ ! -x "$BUILD_NATIVE" ]; then
    echo "error: $BUILD_NATIVE is missing" >&2
    exit 1
fi

OPENSSL_DIR="$(cd "$OPENSSL_DIR" && pwd -P)"
if [ -f "$OPENSSL_DIR/lib/libssl.a" ] && [ -f "$OPENSSL_DIR/lib/libcrypto.a" ]; then
    OPENSSL_LIB_DIR="$OPENSSL_DIR/lib"
    OPENSSL_INCLUDE_DIR="$OPENSSL_DIR/include"
elif [ -f "$OPENSSL_DIR/libssl.a" ] && [ -f "$OPENSSL_DIR/libcrypto.a" ]; then
    OPENSSL_LIB_DIR="$OPENSSL_DIR"
    OPENSSL_INCLUDE_DIR="$OPENSSL_DIR/include"
else
    echo "error: --openssl-dir must contain include/ and libssl.a + libcrypto.a (either directly or under lib/)" >&2
    exit 1
fi

if [ ! -f "$OPENSSL_INCLUDE_DIR/openssl/opensslv.h" ]; then
    echo "error: OpenSSL headers not found under $OPENSSL_INCLUDE_DIR" >&2
    exit 1
fi

if [ -n "$ICU_DIR" ]; then
    ICU_DIR="$(cd "$ICU_DIR" && pwd -P)"
fi

OHOS_SDK_ROOT="${OHOS_SDK_ROOT:-${OHOS_NDK_HOME:-}}"
OHOS_NDK_HOME="${OHOS_NDK_HOME:-$OHOS_SDK_ROOT}"
if [ -z "$OHOS_SDK_ROOT" ] || [ -z "$OHOS_NDK_HOME" ]; then
    echo "error: set OHOS_SDK_ROOT (and optionally OHOS_NDK_HOME) to the OpenHarmony SDK root" >&2
    exit 1
fi
OHOS_SDK_ROOT="$(cd "$OHOS_SDK_ROOT" && pwd -P)"
OHOS_NDK_HOME="$(cd "$OHOS_NDK_HOME" && pwd -P)"
if [ ! -f "$OHOS_NDK_HOME/native/build/cmake/ohos.toolchain.cmake" ]; then
    echo "error: OHOS_NDK_HOME must contain native/build/cmake/ohos.toolchain.cmake (got $OHOS_NDK_HOME)" >&2
    exit 1
fi

OUT_CONFIG="net11.0-openharmony-aotstatic-$ARCH"
OUT_DIR="${OUT_DIR:-$REPO_ROOT/artifacts/bin/ohos-aot-static-openssl/openharmony-$ARCH}"
OUT_DIR="$(mkdir -p "$OUT_DIR" && cd "$OUT_DIR" && pwd -P)"

if [ "$CLEAN" = 1 ]; then
    rm -rf "$REPO_ROOT/artifacts/obj/native/$OUT_CONFIG"
fi

# The runtime native build's host-OS probe (eng/common/native/init-os-and-arch.sh)
# knows Linux/macOS/Android but not an OpenHarmony host. The build runs on a
# Linux CI host normally; on an OpenHarmony device/host use a tiny uname shim
# so the build system selects its Linux host paths while CMake still uses the
# OpenHarmony toolchain.
HOST_OS="$(uname -s 2>/dev/null || true)"
FAKE_UNAME_DIR=""
cleanup() {
    if [ -n "$FAKE_UNAME_DIR" ]; then rm -rf "$FAKE_UNAME_DIR"; fi
}
trap cleanup EXIT
case "$(printf '%s' "$HOST_OS" | tr '[:upper:]' '[:lower:]')" in
    openharmony|harmonyos)
        FAKE_UNAME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ohos-uname.XXXXXX")"
        cat > "$FAKE_UNAME_DIR/uname" <<'SHIM'
#!/bin/sh
case "${1:-}" in
    -s) echo Linux ;;
    -m) echo aarch64 ;;
    *) exec /usr/bin/uname "$@" ;;
esac
SHIM
        chmod +x "$FAKE_UNAME_DIR/uname"
        export PATH="$FAKE_UNAME_DIR:$PATH"
        ;;
esac

CMAKE_ARGS="-DOPENSSL_ROOT_DIR=$OPENSSL_DIR -DOPENSSL_INCLUDE_DIR=$OPENSSL_INCLUDE_DIR -DOPENSSL_SSL_LIBRARY=$OPENSSL_LIB_DIR/libssl.a -DOPENSSL_CRYPTO_LIBRARY=$OPENSSL_LIB_DIR/libcrypto.a"
if [ -n "$ICU_DIR" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_ICU_DIR=$ICU_DIR"
fi

export OHOS_NDK_HOME OHOS_SDK_ROOT
if [ -d "$OHOS_NDK_HOME/native/llvm/lib" ]; then
    export LD_LIBRARY_PATH="$OHOS_NDK_HOME/native/llvm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

echo "== configure direct NativeAOT crypto archive =="
"$BUILD_NATIVE" \
    -os openharmony \
    -arch "$ARCH" \
    -buildtype "$CONFIGURATION" \
    -aotstaticopenssl \
    -configureonly \
    -outconfig "$OUT_CONFIG" \
    -cmakeargs "$CMAKE_ARGS"

OBJ_DIR="$REPO_ROOT/artifacts/obj/native/$OUT_CONFIG"
ARCHIVE="$OBJ_DIR/System.Security.Cryptography.Native/libSystem.Security.Cryptography.Native.OpenSsl.a"

echo "== build System.Security.Cryptography.Native.OpenSsl-Static =="
ninja -C "$OBJ_DIR" System.Security.Cryptography.Native.OpenSsl-Static

if [ ! -f "$ARCHIVE" ]; then
    echo "error: build did not produce $ARCHIVE" >&2
    exit 1
fi
SHIM_MEMBER_COUNT="$(ar t "$ARCHIVE" | grep -c '^opensslshim\.c\.o$' || true)"
if [ "${SHIM_MEMBER_COUNT:-0}" -ne 0 ]; then
    echo "error: $ARCHIVE still contains opensslshim.c.o; the direct archive build did not take effect" >&2
    exit 1
fi
UNDEFINED_OPENSSL_COUNT="$(nm -u "$ARCHIVE" 2>/dev/null | grep -cE ' (SSL|X509|EVP|OPENSSL|ERR|BIO|CRYPTO|OSSL)_' || true)"
if [ "${UNDEFINED_OPENSSL_COUNT:-0}" -eq 0 ]; then
    echo "warning: $ARCHIVE has no undefined OpenSSL symbols; verify that it uses direct OpenSSL calls" >&2
fi

cp -f "$ARCHIVE" "$OUT_DIR/libSystem.Security.Cryptography.Native.OpenSsl.a"
cp -f "$OPENSSL_LIB_DIR/libssl.a" "$OUT_DIR/libssl.a"
cp -f "$OPENSSL_LIB_DIR/libcrypto.a" "$OUT_DIR/libcrypto.a"

OPENSSL_FOR_LICENSE="$OPENSSL_DIR"
if [ -f "$OPENSSL_FOR_LICENSE/LICENSE.txt" ]; then
    cp -f "$OPENSSL_FOR_LICENSE/LICENSE.txt" "$OUT_DIR/OpenSSL-LICENSE.txt"
fi

cat > "$OUT_DIR/build-info.txt" <<EOF
runtime_root=$REPO_ROOT
configuration=$CONFIGURATION
arch=$ARCH
openssl_dir=$OPENSSL_DIR
openssl_include=$OPENSSL_INCLUDE_DIR
openssl_lib=$OPENSSL_LIB_DIR
icu_dir=${ICU_DIR:-<not set>}
obj_dir=$OBJ_DIR
EOF
( cd "$OUT_DIR" && sha256sum libSystem.Security.Cryptography.Native.OpenSsl.a libssl.a libcrypto.a OpenSSL-LICENSE.txt 2>/dev/null > SHA256SUMS || true )

echo
echo "== staged $OUT_DIR =="
ls -lh "$OUT_DIR"
echo
echo "Use it with:"
echo "  -p:OpenHarmonyStaticOpenSsl=true -p:OpenHarmonyStaticOpenSslDir=$OUT_DIR"
