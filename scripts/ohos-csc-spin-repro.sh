#!/usr/bin/env bash
# ============================================================================
# ohos-csc-spin-repro.sh
#
# Reproduces the rc.2-era csc livelock on the HarmonyOS (OHOS) host: with several
# concurrent Roslyn compilations of a repo task project, a csc process sometimes
# stops making progress while burning CPU. The hung process shows
# `SIGKILL`-free 100% CPU (user+sys), ~40 threads, one spinning thread, the rest
# parked on futexes, frozen I/O counters and no output file — the signature the
# build workaround (`DOTNET_PROCESSOR_COUNT=1`) in
# scripts/ohos-runtime-interp-fullbuild.sh avoids.
#
# A second, rarer shape (0 CPU, all threads on futexes) wedged an installer.tasks
# csc inside a real build even with that workaround; this harness targets the
# CPU-spin shape.
#
# Localisation (2026-10-03, this host):
#   * Roslyn concurrency is required: `-parallel-` never hangs (0/4 rounds) and
#     `DOTNET_PROCESSOR_COUNT=1` never hangs (0/10). `DOTNET_PROCESSOR_COUNT=2`
#     still hangs (1/6), `=4` did not in 6 rounds but is not trusted.
#   * Nothing in the analyzer set is the trigger: `/skipanalyzers+` (diagnostic
#     analyzers skipped, generators still run) hangs (2/4), dropping all
#     diagnostic analyzers hangs (1/4), dropping StyleCop hangs (1/4) and
#     dropping all generators hangs (1/4).
#   * Server GC and JIT tiering are not the trigger: `DOTNET_gcServer=0`,
#     `DOTNET_gcConcurrent=0` and `DOTNET_TieredCompilation=0` all still hang.
#   * It is not rc.2-only: rc.1/rc.2 shared runtimes x rc.1/rc.2 Roslyn toolsets
#     all hang (rc2/rc2 0/6 was a quiet sample; the other three combos hung).
#   => platform/scheduler interaction with the concurrent managed workload, not
#      a single generator/analyzer; keep the managed side serialized.
#
# The repro needs a recorded csc response file of the HelixTestTasks task project
# (which compiles with the full analyzer set). `--capture` (the default when the
# rsp is missing) runs a cold `tasks` subset build once with the workaround and
# snapshots the response file MSBuild hands to csc; the stress phase then reuses
# it. Note the harness only drives csc directly, so the build itself is not run
# concurrently here.
#
# Usage:
#   scripts/ohos-csc-spin-repro.sh [--instances K] [--rounds R] [--timeout S]
#                                  [--stall S] [--rsp PATH] [--capture|--no-capture]
#                                  [--keep]
#   Defaults: K=24 R=6 timeout=75 stall=55.
#   Exit: 0 = no hang seen, 1 = livelock reproduced (evidence in $SCR/repro), 2 = setup error.
#
# Env: REPO, SCR (default /data/storage/el2/base/tmp/opencode/csc-spin-repro),
#      DOTNET_INSTALL_DIR (default $HOME/.dotnet), CSC_DOTNET (dotnet muxer used for
#      csc; default $DOTNET_INSTALL_DIR/dotnet), CSC_DLL (default: newest
#      microsoft.net.compilers.toolset package under $NUGET_PACKAGES),
#      OHOS_NDK_HOME, NUGET_CONFIG (optional restore config for --capture).
# ============================================================================
set -euo pipefail

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCR="${SCR:-/data/storage/el2/base/tmp/opencode/csc-spin-repro}"
DOTNET_HOST="${DOTNET_INSTALL_DIR:-$HOME/.dotnet}"
CSC_DOTNET="${CSC_DOTNET:-$DOTNET_HOST/dotnet}"
K="${K:-24}"
R="${R:-6}"
TIMEOUT="${TIMEOUT:-75}"
STALL="${STALL:-55}"
# The workdir the recorded response file expects (relative sources).
WORKDIR="${WORKDIR:-$REPO/src/tasks/HelixTestTasks}"
CAPTURE=""
KEEP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --instances) K="${2:?}"; shift 2 ;;
    --rounds)    R="${2:?}"; shift 2 ;;
    --timeout)   TIMEOUT="${2:?}"; shift 2 ;;
    --stall)     STALL="${2:?}"; shift 2 ;;
    --rsp)       RSP="${2:?}"; shift 2 ;;
    --capture)   CAPTURE=1; shift ;;
    --no-capture) CAPTURE=0; shift ;;
    --keep)      KEEP=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "${CSC_DLL:-}" ]; then
  CSC_DLL="$(ls -1 "$HOME/.nuget/packages/microsoft.net.compilers.toolset/"*/tasks/netcore/bincore/csc.dll 2>/dev/null | sort | tail -1 || true)"
fi
[ -n "${CSC_DLL:-}" ] && [ -f "$CSC_DLL" ] || { echo "csc.dll not found; set CSC_DLL" >&2; exit 2; }
[ -x "$CSC_DOTNET" ] || { echo "dotnet muxer not found at $CSC_DOTNET; set CSC_DOTNET" >&2; exit 2; }
mkdir -p "$SCR"/{logs,runs}
RSP="${RSP:-$SCR/helix.rsp}"

# --- capture phase -----------------------------------------------------------
if [ ! -f "$RSP" ] && [ "${CAPTURE:-1}" != "0" ]; then
  echo "== capture: cold tasks subset build (workaround on) ==" | tee "$SCR/logs/driver.log"
  SHIMS="$SCR/bin"
  mkdir -p "$SHIMS"
  REAL_UNAME="$(command -v uname)"
  cat > "$SHIMS/uname" <<EOF
#!/bin/sh
if [ "\$1" = "-s" ]; then echo Linux; exit 0; fi
exec $REAL_UNAME "\$@"
EOF
  cat > "$SHIMS/nproc" <<EOF
#!/bin/sh
echo "${JOBS:-4}"
EOF
  chmod +x "$SHIMS/uname" "$SHIMS/nproc"
  export PATH="$SHIMS:$PATH"
  export DOTNET_NOLOGO=1 MSBUILDDISABLENODEREUSE=1 DOTNET_CLI_USE_MSBUILD_SERVER=0
  export DOTNET_PROCESSOR_COUNT=1
  export OHOS_NDK_HOME="${OHOS_NDK_HOME:-/storage/Users/currentUser/.harmonybrew/Cellar/ohos-sdk/26.0.0.18_1}"
  RESTORE_ARGS=()
  [ -n "${NUGET_CONFIG:-}" ] && RESTORE_ARGS=("/p:RestoreConfigFile=$NUGET_CONFIG")
  (
    while :; do
      for f in /data/storage/el2/base/tmp/MSBuildTemp*/tmp*.rsp; do
        [ -f "$f" ] || continue
        if grep -q "HelixTestTasks" "$f" 2>/dev/null; then cp -f "$f" "$RSP.tmp" && mv -f "$RSP.tmp" "$RSP"; fi
      done
      [ -f "$RSP" ] && break
      sleep 1 &
      wait $! || true
    done
  ) &
  WATCH=$!
  set +e
  ( cd "$REPO" && timeout -s KILL "${CAPTURE_TIMEOUT:-1800}" ./build.sh -subset tasks -os openharmony -arch arm64 --cross -c Release -lc Release -rc Release \
      /p:UseBootstrapLayout=true \
      /p:ApiCompatValidateAssemblies=false /p:IncludeSymbols=false \
      /p:PreReleaseVersionLabel=rc /p:PreReleaseVersion=2 /p:OfficialBuildId=20260901.112 \
      /p:_RepoToolManifest=/nonexistent-cscspin \
      /p:RestoreUseStaticGraphEvaluation=false \
      /p:GenerateRestoreUseStaticGraphEvaluationBinlog=false \
      "${RESTORE_ARGS[@]}" \
      /m:1 /v:minimal ) > "$SCR/logs/capture-build.log" 2>&1
  CAPTURE_RC=$?
  set -e
  kill "$WATCH" 2>/dev/null || true
  echo "capture build rc=$CAPTURE_RC rsp=$RSP" | tee -a "$SCR/logs/driver.log"
  [ -f "$RSP" ] || { echo "could not capture a HelixTestTasks csc response file" >&2; exit 2; }
fi
[ -f "$RSP" ] || { echo "no rsp at $RSP (run with --capture or pass --rsp)" >&2; exit 2; }

# --- stress phase -------------------------------------------------------------
echo "== stress: K=$K R=$R timeout=${TIMEOUT}s stall=${STALL}s rsp=$RSP ==" | tee -a "$SCR/logs/driver.log"
GRACE="${GRACE:-20}"
HANG=0
for r in $(seq 1 "$R"); do
  t0=$(date +%s)
  rm -f "$SCR"/runs/r${r}-i*.rc "$SCR"/runs/r${r}-i*.dll "$SCR"/runs/r${r}-i*.log "$SCR"/runs/spin-r${r}-i*.txt
  pids=()
  for i in $(seq 1 "$K"); do
    out="$SCR/runs/r${r}-i${i}.dll"; rsp="$SCR/runs/r${r}-i${i}.rsp"
    sed "s|/out:[^ ]*|/out:$out|" "$RSP" > "$rsp"
    ( cd "$WORKDIR" && timeout -s KILL "$TIMEOUT" "$CSC_DOTNET" exec "$CSC_DLL" /noconfig "@$rsp" \
        > "${out%.dll}.log" 2>&1; echo $? > "${out%.dll}.rc" ) &
    pids+=($!)
  done
  deadline=$((t0 + TIMEOUT + GRACE))
  while :; do
    now=$(date +%s)
    alive=0
    for i in $(seq 1 "$K"); do
      pid="$(for p in $(pgrep -f "r${r}-i${i}.rsp" 2>/dev/null); do
               c=$(cat "/proc/$p/comm" 2>/dev/null || true)
               case "$c" in timeout) ;; *) echo "$p"; break ;; esac
             done)"
      [ -n "$pid" ] && alive=$((alive + 1))
      [ -z "$pid" ] && continue
      if [ $((now - t0)) -gt "$STALL" ]; then
        ev="$SCR/runs/spin-r${r}-i${i}.txt"
        [ -f "$ev" ] && continue
        {
          echo "== round=$r i=$i pid=$pid at $(date +%T) elapsed=$((now - t0))s"
          echo "-- cmdline: $(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)"
          grep -E "State|Threads|VmRSS|voluntary|nonvoluntary" "/proc/$pid/status" 2>/dev/null
          echo "-- io:"; cat "/proc/$pid/io" 2>/dev/null
          echo "-- thread comm histogram:"
          for t in /proc/$pid/task/*; do cat "$t/comm" 2>/dev/null; echo; done | sort | uniq -c | sort -rn
          echo "-- wchan histogram:"
          for t in /proc/$pid/task/*; do cat "$t/wchan" 2>/dev/null; echo; done | sort | uniq -c | sort -rn | head
        } > "$ev" 2>&1
        echo "[captured] r$r i$i pid=$pid -> $ev" | tee -a "$SCR/logs/driver.log"
      fi
    done
    if [ "$alive" = 0 ]; then break; fi
    if [ "$now" -gt "$deadline" ]; then
      echo "[watchdog] r$r: $alive instance(s) past $((TIMEOUT + GRACE))s; forcing SIGKILL" | tee -a "$SCR/logs/driver.log"
      pkill -9 -f "r${r}-i[0-9]*\.rsp" 2>/dev/null || true
      sleep 5
      still="$(pgrep -f "r${r}-i[0-9]*\.rsp" 2>/dev/null | wc -l)"
      echo "[watchdog] r$r: survivors after SIGKILL: $still (a kernel-side spin can ignore SIGKILL; they are left for the operator)" | tee -a "$SCR/logs/driver.log"
      break
    fi
    sleep 3
  done
  wait "${pids[@]}" 2>/dev/null || true
  t1=$(date +%s)
  hangs=0
  for i in $(seq 1 "$K"); do
    rc="$(cat "$SCR/runs/r${r}-i${i}.rc" 2>/dev/null || echo missing)"
    [ "$rc" = "137" ] || [ "$rc" = "missing" ] && hangs=$((hangs + 1))
  done
  [ "$hangs" -gt 0 ] && HANG=1
  echo "round $r: wall=$((t1 - t0))s hangs=$hangs" | tee -a "$SCR/logs/driver.log"
done

if [ "$HANG" = "1" ]; then
  echo "REPRODUCED: at least one csc livelock (evidence under $SCR/runs); keeping the workaround is required" | tee -a "$SCR/logs/driver.log"
  [ "$KEEP" = "1" ] || true
  exit 1
fi
echo "no hang in $R rounds x $K instances" | tee -a "$SCR/logs/driver.log"
exit 0
