#!/usr/bin/env bash
# ============================================================================
# ohos-runtime-clrinterpreter-build.sh
#
# R1-INTERP-SPIKE reproducer: cross-build `libclrinterpreter.so` for
# openharmony-arm64 (Release) with FEATURE_INTERPRETER=1 on an OHOS aarch64
# build host, WITHOUT linking the full coreclr. `clr.native` still configures
# src/native/libs (Crypto/Globalization), which is why placeholder OpenSSL/ICU
# only satisfies configure; the interpreter target links neither.
#
# For a full interpreter-enabled `libcoreclr.so` + runtime pack, provision the
# real cross assets first and run the standard pack build instead:
#   sdk-ohos eng/ohos-install/build/ohos-ci-env.sh   # OHOS OpenSSL + ICU
#   ./build.sh clr+libs+host+packs -os openharmony -arch arm64 --cross \
#             -c Release -lc Release -rc Release -clrinterpreter
# (then scripts/ohos-runtime-clrinterpreter-overlay.sh can verify/stage).
#
# Host quirks preserved by this script (no source edits, eng/common untouched):
#   1. `uname -s` reports HarmonyOS -> Arcade's synced
#      eng/common/native/init-os-and-arch.sh rejects it; a PATH `uname` shim
#      reports Linux for `-s` only.
#   2. global.json wants bootstrap SDK 11.0.100-rc.1.26420.103 (not on the
#      public feeds); a $SCR/dotnet layout aliases the installed SDK version.
#   3. OHOS seccomp blocks MSBuild out-of-proc node control sockets
#      (SocketException 13) -> `/m:1` + DOTNET_CLI_USE_MSBUILD_SERVER=0.
#   4. Static-graph restore's NuGet.Build.Tasks.Console throws
#      PlatformNotSupportedException on OHOS -> RestoreUseStaticGraphEvaluation=false.
#   5. `dotnet tool restore` fails on OHOS -> _RepoToolManifest=/nonexistent
#      (native clr build does not need those tools).
#   6. cdac-build-tool is not in the restore graph -> RuntimeIdentifierGraphPath
#      patched with the openharmony-* RIDs.
#   7. OHOS NDK lld cannot load its bundled llvm/lib/libxml2.so.16 -> scratch
#      copy + LD_LIBRARY_PATH.
#
# Usage: scripts/ohos-runtime-clrinterpreter-build.sh [--vm-smoke] [--jobs N]
#   --vm-smoke   also compile the interpreter-critical VM TUs
#                (eeconfig/precode/method/codeman/jitinterface/interpexec)
#                that prove the VM side builds under FEATURE_INTERPRETER=1.
# Env overrides: REPO, SCR, DOTNET_INSTALL_DIR (host layout), OHOS_NDK_HOME, JOBS
# Output: $SCR/logs/{configure,build-interp,build-vm-interp}.log
#         $OBJ/interpreter/libclrinterpreter.so{,.dbg}
# ============================================================================
set -euo pipefail

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCR="${SCR:-/data/storage/el2/base/tmp/opencode/ohos-interp-build}"
DOTNET_HOST="${DOTNET_INSTALL_DIR:-$HOME/.dotnet}"
OHOS_NDK_HOME="${OHOS_NDK_HOME:-/storage/Users/currentUser/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_1}"
JOBS="${JOBS:-4}"
VM_SMOKE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --vm-smoke) VM_SMOKE=1; shift ;;
    --jobs)     JOBS="${2:?missing value}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -f "$REPO/global.json" ] || { echo "not a runtime-ohos checkout: $REPO" >&2; exit 1; }
[ -f "$OHOS_NDK_HOME/native/llvm/bin/clang" ] || { echo "OHOS_NDK_HOME looks wrong: $OHOS_NDK_HOME" >&2; exit 1; }
export OHOS_NDK_HOME

mkdir -p "$SCR"/{bin,libs,logs,openssl/{include,lib},icu/{include,lib}}

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

# --- 4. placeholder OpenSSL/ICU (configure only; interpreter links neither) --
for a in libcrypto.a libssl.a; do printf '!<arch>\n' > "$SCR/openssl/lib/$a"; done
for a in libicudata.a libicui18n.a libicuuc.a; do printf '!<arch>\n' > "$SCR/icu/lib/$a"; done

# --- 5. openharmony-* RID graph ----------------------------------------------
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

# --- 6. configure (ConfigureOnly) -------------------------------------------
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
  "-DOPENSSL_ROOT_DIR=$SCR/openssl" "-DOPENSSL_INCLUDE_DIR=$SCR/openssl/include"
  "-DOPENSSL_CRYPTO_LIBRARY=$SCR/openssl/lib/libcrypto.a"
  "-DOPENSSL_SSL_LIBRARY=$SCR/openssl/lib/libssl.a" "-DCMAKE_ICU_DIR=$SCR/icu"
)
echo "== configure (clr.native, ConfigureOnly) =="
./build.sh -subset clr.native -os openharmony -arch arm64 --cross -c Release -lc Release -rc Release \
  -clrinterpreter \
  /p:ConfigureOnly=true \
  /p:UseBootstrapLayout=true \
  /p:RuntimeIdentifierGraphPath="$SCR/ridgraph.json" \
  /p:ApiCompatValidateAssemblies=false /p:IncludeSymbols=false \
  /p:PreReleaseVersionLabel=rc /p:PreReleaseVersion=1 /p:OfficialBuildId=20260901.109 \
  /p:_RepoToolManifest=/nonexistent-r1interp \
  /p:RestoreUseStaticGraphEvaluation=false \
  /p:GenerateRestoreUseStaticGraphEvaluationBinlog=false \
  "/m:1" /v:minimal "/bl:$SCR/logs/configure.binlog" \
  -cmakeargs "${CMAKE_ARGS[*]}" 2>&1 | tee "$SCR/logs/configure.log"

OBJ="$REPO/artifacts/obj/coreclr/openharmony.arm64.Release"
grep -m1 FEATURE_INTERPRETER "$OBJ/CMakeCache.txt" || true

# --- 7. interpreter shared library ------------------------------------------
echo "== build clrinterpreter =="
cmake --build "$OBJ" --target clrinterpreter -j "$JOBS" 2>&1 | tee "$SCR/logs/build-interp.log"

# --- 8. optional VM TU smoke ------------------------------------------------
if [ "$VM_SMOKE" = "1" ]; then
  echo "== build interpreter-critical VM TUs =="
  ninja -C "$OBJ" -j "$JOBS" \
    vm/wks/CMakeFiles/cee_wks_core.dir/__/eeconfig.cpp.o \
    vm/wks/CMakeFiles/cee_wks_core.dir/__/precode.cpp.o \
    vm/wks/CMakeFiles/cee_wks_core.dir/__/method.cpp.o \
    vm/wks/CMakeFiles/cee_wks.dir/__/codeman.cpp.o \
    vm/wks/CMakeFiles/cee_wks_core.dir/__/jitinterface.cpp.o \
    vm/wks/CMakeFiles/cee_wks_core.dir/__/interpexec.cpp.o \
    2>&1 | tee "$SCR/logs/build-vm-interp.log"
fi

# --- 9. summary -------------------------------------------------------------
SO="$OBJ/interpreter/libclrinterpreter.so"
echo "== artifact =="
ls -l "$SO" "$SO.dbg"
sha256sum "$SO" "$SO.dbg"
file "$SO"
readelf -d "$SO" | grep -E 'NEEDED|SONAME' || true
echo "stage next to libcoreclr.so / into the pack with:"
echo "  scripts/ohos-runtime-clrinterpreter-overlay.sh $SO --dir <layout>|--pack <pack.nupkg>"
echo "remember: the target coreclr must also be built with -clrinterpreter."
