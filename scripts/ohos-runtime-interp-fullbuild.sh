#!/usr/bin/env bash
# ============================================================================
# ohos-runtime-interp-fullbuild.sh
#
# R2-INTERP-FULL: build a *feature-enabled* openharmony-arm64 CoreCLR
# (FEATURE_INTERPRETER=1) together with the class libraries, i.e. the
# `libcoreclr.so` that can actually load libclrinterpreter.so and honour
# DOTNET_InterpMode=3. This is the follow-up of
# scripts/ohos-runtime-clrinterpreter-build.sh (R1 spike: component-level
# libclrinterpreter.so only; its placeholder OpenSSL/ICU satisfied configure
# but the full link needs real cross assets).
#
# Differences vs the R1 spike script:
#   * real OHOS aarch64 ICU 75.1 + OpenSSL 3.3.1 (default: r2 scratch, override
#     with ICU_DIR / OPENSSL_DIR),
#   * build subset `clr+libs` (native coreclr/VM + src/native/libs + managed
#     libraries) instead of `clr.native` ConfigureOnly,
#   * verifies the produced libcoreclr.so (wide strings / NEEDED) and stages
#     libclrinterpreter.so next to it.
#
# Host quirks (unchanged from R1, all host-environment only, no source edits,
# eng/common untouched):
#   1. `uname -s` = HarmonyOS -> PATH `uname` shim reporting Linux for -s.
#   2. global.json bootstrap SDK is not public -> $SCR/dotnet layout alias.
#   3. OHOS seccomp blocks MSBuild node sockets -> /m:1 + no msbuild server.
#   4. Static-graph restore PNSE on OHOS -> RestoreUseStaticGraphEvaluation=false.
#   5. `dotnet tool restore` unsupported -> _RepoToolManifest=/nonexistent.
#   6. cdac-build-tool missing RIDs -> patched RuntimeIdentifierGraphPath.
#   7. NDK lld cannot load its own libxml2.so.16 -> scratch copy + LD_LIBRARY_PATH.
#
# Usage: scripts/ohos-runtime-interp-fullbuild.sh [--jobs N] [--configure-only]
# Env: REPO SCR DOTNET_INSTALL_DIR OHOS_NDK_HOME ICU_DIR OPENSSL_DIR JOBS
#      SUBSET (default clr.native; clr+libs / clr+libs+packs also used upstream,
#              but the clr.tools host tools trip NETSDK1084 on the ohos-arm64 RID)
#      NUGET_CONFIG (if set, passed as /p:RestoreConfigFile; on this host all
#              NuGet feeds are unreachable, so a local-only config restores from
#              the global packages cache instead of hanging in socket retries)
# Logs: $SCR/logs/{configure,full-build}.log + .binlog
#
# NOTE (running the result): on HarmonyOS the hishell/CLI domain refuses
# file-backed PROT_EXEC for any freshly built (untrusted) ELF, so the produced
# libcoreclr.so can only be loaded from a signed HAP/app bundle. See
# docs/plans/2026-09-24-ohos-runtime-strategy.md R2-INTERP-FULL.
# ============================================================================
set -euo pipefail

# The interactive harmonybrew shell exports CPPFLAGS/CFLAGS/LDFLAGS pointing at
# ~/.harmonybrew (e.g. ICU 78 headers), which would shadow the real cross ICU
# 75.1 used by src/native/libs. Sanitize (host-env only, no source change).
unset CPPFLAGS CFLAGS CXXFLAGS LDFLAGS

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCR="${SCR:-/data/storage/el2/base/tmp/opencode/r2-interp}"
DOTNET_HOST="${DOTNET_INSTALL_DIR:-$HOME/.dotnet}"
OHOS_NDK_HOME="${OHOS_NDK_HOME:-/storage/Users/currentUser/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_1}"
ICU_DIR="${ICU_DIR:-$SCR/icu}"
OPENSSL_DIR="${OPENSSL_DIR:-$SCR/openssl}"
JOBS="${JOBS:-4}"
CONFIGURE_ONLY=0
RESTORE_ARGS=()
if [ -n "${NUGET_CONFIG:-}" ]; then
  RESTORE_ARGS=("/p:RestoreConfigFile=$NUGET_CONFIG")
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --jobs)           JOBS="${2:?missing value}"; shift 2 ;;
    --configure-only) CONFIGURE_ONLY=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -f "$REPO/global.json" ] || { echo "not a runtime-ohos checkout: $REPO" >&2; exit 1; }
[ -f "$OHOS_NDK_HOME/native/llvm/bin/clang" ] || { echo "OHOS_NDK_HOME looks wrong: $OHOS_NDK_HOME" >&2; exit 1; }
[ -f "$ICU_DIR/lib/libicuuc.a" ] || { echo "ICU missing at $ICU_DIR (see ohos-ci-env.sh or provision-deps.sh)" >&2; exit 1; }
[ -f "$OPENSSL_DIR/lib/libcrypto.a" ] || { echo "OpenSSL missing at $OPENSSL_DIR" >&2; exit 1; }
export OHOS_NDK_HOME

mkdir -p "$SCR"/{bin,libs,logs}

# --- 1. uname shim -----------------------------------------------------------
REAL_UNAME="$(command -v uname)"
cat > "$SCR/bin/uname" <<EOF
#!/bin/sh
if [ "\$1" = "-s" ]; then
  echo Linux
  exit 0
fi
exec $REAL_UNAME "\$@"
EOF
chmod +x "$SCR/bin/uname"
export PATH="$SCR/bin:$PATH"

# --- 1b. nproc cap shim ------------------------------------------------------
# eng/native/build-commons.sh derives __NumProc from `nproc` (20 here); with
# several other agents building on this box, cap the native -j to $JOBS.
REAL_NPROC="$(command -v nproc || true)"
if [ -n "$REAL_NPROC" ]; then
  cat > "$SCR/bin/nproc" <<EOF
#!/bin/sh
echo $JOBS
EOF
  chmod +x "$SCR/bin/nproc"
fi

# --- 2. dotnet layout alias ($DOTNET_INSTALL_DIR) ----------------------------
if [ "$DOTNET_HOST" != "$SCR/dotnet" ]; then
  GLOBAL_VER="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["sdk"]["version"])' "$REPO/global.json")"
  INST_VER="$(ls "$DOTNET_HOST/sdk" | sort | tail -1)"
  mkdir -p "$SCR/dotnet/sdk"
  for e in "$DOTNET_HOST"/*; do
    [ "$(basename "$e")" = "sdk" ] && continue
    ln -sfn "$e" "$SCR/dotnet/$(basename "$e")"
  done
  ln -sfn "$DOTNET_HOST/sdk/$INST_VER" "$SCR/dotnet/sdk/$GLOBAL_VER"
  echo "dotnet layout: $SCR/dotnet (alias $GLOBAL_VER -> $INST_VER)"
fi
export DOTNET_INSTALL_DIR="$SCR/dotnet"

# --- 3. lld libxml2 workaround ----------------------------------------------
if [ -f "$OHOS_NDK_HOME/native/llvm/lib/libxml2.so.16" ]; then
  cp -f "$OHOS_NDK_HOME/native/llvm/lib/libxml2.so.16" "$SCR/libs/libxml2.so.16"
fi
export LD_LIBRARY_PATH="$SCR/libs${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# --- 4. openharmony-* RID graph ----------------------------------------------
SDK_GRAPH="$(ls "$DOTNET_HOST"/sdk/*/PortableRuntimeIdentifierGraph.json | sort | tail -1)"
python3 - "$SDK_GRAPH" "$SCR/ridgraph.json" <<'PYEOF'
import json
import sys
src, dst = sys.argv[1], sys.argv[2]
graph = json.load(open(src))
runtimes = graph["runtimes"]
add = {
    "openharmony":       {"#import": ["any"]},
    "openharmony-arm":   {"#import": ["openharmony", "linux-musl-arm"]},
    "openharmony-arm64": {"#import": ["openharmony", "linux-musl-arm64"]},
    "openharmony-x64":   {"#import": ["openharmony", "linux-musl-x64"]},
}
added = [k for k in add if k not in runtimes]
for k in added:
    runtimes[k] = add[k]
json.dump(graph, open(dst, "w"), indent=2)
print(f"ridgraph: {src} -> {dst} (added: {', '.join(added) or 'none'})")
PYEOF

# --- 5. configure / build ----------------------------------------------------
export DOTNET_NOLOGO=1
export MSBUILDDISABLENODEREUSE=1
export DOTNET_CLI_USE_MSBUILD_SERVER=0

cd "$REPO"
CMAKE_ARGS=(
  "-DCMAKE_SYSTEM_NAME=OHOS"
  "-DHAVE_CLOCK_MONOTONIC_COARSE_EXITCODE=0" "-DHAVE_CLOCK_REALTIME_EXITCODE=0"
  "-DHAVE_CLOCK_THREAD_CPUTIME_EXITCODE=0" "-DHAVE_MMAP_DEV_ZERO_EXITCODE=0"
  "-DHAVE_PROCFS_CTL_EXITCODE=1" "-DHAVE_PROCFS_STAT_EXITCODE=0" "-DHAVE_PROCFS_STATM_EXITCODE=0"
  "-DHAVE_SCHED_GETCPU_EXITCODE=0" "-DHAVE_SCHED_GET_PRIORITY_EXITCODE=0"
  "-DHAVE_WORKING_CLOCK_GETTIME_EXITCODE=0" "-DHAVE_WORKING_GETTIMEOFDAY_EXITCODE=0"
  "-DONE_SHARED_MAPPING_PER_FILEREGION_PER_PROCESS_EXITCODE=1"
  "-DREALPATH_SUPPORTS_NONEXISTENT_FILES_EXITCODE=1"
  "-DHAVE_SHM_OPEN_THAT_WORKS_WELL_ENOUGH_WITH_MMAP_EXITCODE=0"
  "-DHAVE_BROKEN_FIFO_KEVENT_EXITCODE=1" "-DHAVE_BROKEN_FIFO_SELECT_EXITCODE=1"
  "-DOPENSSL_ROOT_DIR=$OPENSSL_DIR" "-DOPENSSL_INCLUDE_DIR=$OPENSSL_DIR/include"
  "-DOPENSSL_CRYPTO_LIBRARY=$OPENSSL_DIR/lib/libcrypto.a"
  "-DOPENSSL_SSL_LIBRARY=$OPENSSL_DIR/lib/libssl.a" "-DCMAKE_ICU_DIR=$ICU_DIR"
)
SUBSET="${SUBSET:-clr.native}"
[ "$CONFIGURE_ONLY" = "1" ] && SUBSET="clr.native"
EXTRA=(/p:ConfigureOnly=true) ; [ "$CONFIGURE_ONLY" != "1" ] && EXTRA=()

echo "== full build ($SUBSET, FEATURE_INTERPRETER=1) =="
echo "ICU_DIR=$ICU_DIR"
echo "OPENSSL_DIR=$OPENSSL_DIR"
./build.sh -subset "$SUBSET" -os openharmony -arch arm64 --cross -c Release -lc Release -rc Release \
  -clrinterpreter \
  /p:UseBootstrapLayout=true \
  /p:RuntimeIdentifierGraphPath="$SCR/ridgraph.json" \
  /p:ApiCompatValidateAssemblies=false /p:IncludeSymbols=false \
  /p:PreReleaseVersionLabel=rc /p:PreReleaseVersion=1 /p:OfficialBuildId=20260901.109 \
  /p:_RepoToolManifest=/nonexistent-r2interp \
  /p:RestoreUseStaticGraphEvaluation=false \
  /p:GenerateRestoreUseStaticGraphEvaluationBinlog=false \
  "${RESTORE_ARGS[@]}" \
  "${EXTRA[@]}" \
  "/m:1" /v:minimal "/bl:$SCR/logs/full-build.binlog" \
  -cmakeargs "${CMAKE_ARGS[*]}" 2>&1 | tee "$SCR/logs/full-build.log"

OBJ="$REPO/artifacts/obj/coreclr/openharmony.arm64.Release"
BIN="$REPO/artifacts/bin/coreclr/openharmony.arm64.Release"
echo "== evidence =="
grep -m1 FEATURE_INTERPRETER "$OBJ/CMakeCache.txt" || true
for f in "$BIN/libcoreclr.so" "$BIN/libclrinterpreter.so" "$OBJ/interpreter/libclrinterpreter.so"; do
  [ -f "$f" ] && { ls -l "$f"; sha256sum "$f"; }
done
if [ -f "$BIN/libcoreclr.so" ]; then
  readelf -d "$BIN/libcoreclr.so" | grep -E 'NEEDED|SONAME' || true
  python3 - "$BIN/libcoreclr.so" <<'PY'
import sys
data = open(sys.argv[1], "rb").read()
for w in ("clrinterpreter", "InterpMode", "InterpreterName"):
    print(w, "->", "YES" if (w.encode("utf-32-le") in data or w.encode("utf-16-le") in data) else "no")
PY
fi
