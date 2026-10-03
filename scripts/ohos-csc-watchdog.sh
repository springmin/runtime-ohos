#!/usr/bin/env bash
# ============================================================================
# ohos-csc-watchdog.sh
#
# Runs a build command under a no-progress watchdog for the managed C# compiler
# (Roslyn `csc`). On this OHOS host csc occasionally livelocks in two shapes,
# both with frozen I/O counters and no output artifact for many minutes:
#
#   1. the concurrent-compilation spin: one thread burns CPU (~1 core user+sys)
#      while the rest park on futexes (reproduced/localised by
#      scripts/ohos-csc-spin-repro.sh);
#   2. the rarer idle deadlock: every thread parks on futexes, 0 CPU, seen with
#      the installer.tasks csc inside a real build even with
#      DOTNET_PROCESSOR_COUNT=1 (MSB6006 rc 137 after a manual kill).
#
# Design:
#   * The wrapped command is started as its own process-group leader
#     (`set -m`); every csc descendant inherits that PGID, so the watchdog can
#     claim only the compilers it owns even when several agents build on the
#     same host. A process is claimed when its PGID equals the wrapped command's
#     PID, or (fallback) its parent chain reaches that PID.
#   * A compiler is "csc" when its comm is `csc` or its cmdline names
#     `csc.dll` / a `bincore/csc` apphost (covers `dotnet exec csc.dll`).
#   * Progress for a compiler = a change in /proc/<pid>/io (rchar/wchar/syscr/
#     syscw) or in the `/out:` artifact (size/mtime, resolved from the cmdline
#     or its `@response-file`). CPU time alone is NOT progress: a spinning hung
#     compiler accumulates CPU forever, exactly like the repro's signature.
#   * No progress for CSC_WATCHDOG_IDLE_TIMEOUT seconds with <= idle CPU and no
#     D/Z state -> idle deadlock; no progress for CSC_WATCHDOG_SPIN_TIMEOUT
#     seconds while >= spin CPU -> spin livelock. Only then is the process tree
#     snapshotted to the evidence dir and SIGKILLed.
#   * Once a compiler was killed, the build attempt is expected to fail; the
#     whole command is retried once (CSC_WATCHDOG_RETRIES) and a second stall is
#     a hard error pointing at the evidence. A failure without any kill is
#     propagated immediately (never masked by a retry).
#
# Calibration (2026-10-03, this host): a healthy real csc compile keeps its
# /proc io counters nearly frozen after reading its inputs (Roslyn maps
# metadata) and only writes the /out: artifact at the end; under the heavy
# shared load of this box a healthy compile was observed with a 60s
# no-io/no-artifact window. The 1800s spin budget is therefore ~30x that
# observation, while the reproduced wedges lasted from 20 minutes to 8 hours.
# The idle deadlock (0 CPU + frozen io) is safe to catch much earlier (300s).
#
# Usage:
#   scripts/ohos-csc-watchdog.sh [options] -- <command> [args...]
#
#   --spin-timeout S    no-progress seconds with CPU spinning (default 1800; 0=off)
#   --idle-timeout S    no-progress seconds with ~no CPU       (default 300; 0=off)
#   --poll S            sample interval, >= 1                  (default 10)
#   --retries N         retries after a watchdog kill          (default 1)
#   --spin-cpu-pct P    CPU % of one core counted as spinning  (default 5)
#   --idle-cpu-pct P    CPU % of one core counted as idle      (default 1)
#   --drain S           wait for the command to exit post-kill (default 120)
#   --retry-delay S     sleep before a retry                   (default 5)
#   --log-dir DIR       evidence/log dir (default $CSC_WATCHDOG_LOG_DIR, else
#                       ./artifacts/log/csc-watchdog when ./artifacts exists,
#                       else ${TMPDIR:-/tmp}/csc-watchdog)
#   --quiet             only warnings/errors on console (evidence still written)
#   -h, --help          this help
#
# Env: every option above also reads CSC_WATCHDOG_SPIN_TIMEOUT,
#      CSC_WATCHDOG_IDLE_TIMEOUT, CSC_WATCHDOG_POLL, CSC_WATCHDOG_RETRIES,
#      CSC_WATCHDOG_SPIN_CPU_PCT, CSC_WATCHDOG_IDLE_CPU_PCT,
#      CSC_WATCHDOG_DRAIN, CSC_WATCHDOG_RETRY_DELAY, CSC_WATCHDOG_LOG_DIR,
#      CSC_WATCHDOG_SNAP_TIMEOUT (max seconds per /proc evidence read, default 5).
#      CSC_WATCHDOG=0 is honoured by callers (e.g. the interp fullbuild) to skip
#      the wrapper entirely; this script always watches when invoked.
#
# Exit: 0 = command succeeded; the command's exit code when it failed (after the
#       kill-triggered retry budget if one was used); 2 = usage error.
# ============================================================================
set -u

PROG="csc-watchdog"
log()  { [ "${QUIET:-0}" = 1 ] || printf '[%s] %s\n' "$PROG" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$PROG" "$*" >&2; }
die()  { printf '[%s] %s\n' "$PROG" "$*" >&2; usage >&2; exit 2; }

SPIN_TIMEOUT="${CSC_WATCHDOG_SPIN_TIMEOUT:-1800}"
IDLE_TIMEOUT="${CSC_WATCHDOG_IDLE_TIMEOUT:-300}"
POLL="${CSC_WATCHDOG_POLL:-10}"
RETRIES="${CSC_WATCHDOG_RETRIES:-1}"
SPIN_CPU_PCT="${CSC_WATCHDOG_SPIN_CPU_PCT:-5}"
IDLE_CPU_PCT="${CSC_WATCHDOG_IDLE_CPU_PCT:-1}"
DRAIN="${CSC_WATCHDOG_DRAIN:-120}"
RETRY_DELAY="${CSC_WATCHDOG_RETRY_DELAY:-5}"
LOG_DIR="${CSC_WATCHDOG_LOG_DIR:-}"
QUIET=0

usage() {
    cat <<'EOF'
usage: ohos-csc-watchdog.sh [options] -- <command> [args...]

Watches the managed C# compilers (csc) started by <command>: when one shows no
I/O/artifact progress for a configured duration (CPU spinning or fully idle),
snapshots /proc evidence, SIGKILLs its process tree and retries the whole
command once.

  --spin-timeout S    no-progress seconds with CPU spinning (default 1800; 0=off)
  --idle-timeout S    no-progress seconds with ~no CPU       (default 300; 0=off)
  --poll S            sample interval, >= 1                  (default 10)
  --retries N         retries after a watchdog kill          (default 1)
  --spin-cpu-pct P    CPU % of one core counted as spinning  (default 5)
  --idle-cpu-pct P    CPU % of one core counted as idle      (default 1)
  --drain S           wait for the command to exit post-kill (default 120)
  --retry-delay S     sleep before a retry                   (default 5)
  --log-dir DIR       evidence/log dir (default $CSC_WATCHDOG_LOG_DIR, else
                      ./artifacts/log/csc-watchdog when ./artifacts exists,
                      else ${TMPDIR:-/tmp}/csc-watchdog)
  --quiet             only warnings/errors on console (evidence still written)
  -h, --help          this help

Env equivalents: CSC_WATCHDOG_SPIN_TIMEOUT, CSC_WATCHDOG_IDLE_TIMEOUT,
CSC_WATCHDOG_POLL, CSC_WATCHDOG_RETRIES, CSC_WATCHDOG_SPIN_CPU_PCT,
CSC_WATCHDOG_IDLE_CPU_PCT, CSC_WATCHDOG_DRAIN, CSC_WATCHDOG_RETRY_DELAY,
CSC_WATCHDOG_LOG_DIR.

Exit: 0 = command succeeded; the command's exit code when it failed (after the
kill-triggered retry budget if one was used); 2 = usage error.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --spin-timeout)   [ $# -ge 2 ] || die "missing value for $1"; SPIN_TIMEOUT="$2"; shift 2 ;;
        --idle-timeout)   [ $# -ge 2 ] || die "missing value for $1"; IDLE_TIMEOUT="$2"; shift 2 ;;
        --poll)           [ $# -ge 2 ] || die "missing value for $1"; POLL="$2"; shift 2 ;;
        --retries)        [ $# -ge 2 ] || die "missing value for $1"; RETRIES="$2"; shift 2 ;;
        --spin-cpu-pct)   [ $# -ge 2 ] || die "missing value for $1"; SPIN_CPU_PCT="$2"; shift 2 ;;
        --idle-cpu-pct)   [ $# -ge 2 ] || die "missing value for $1"; IDLE_CPU_PCT="$2"; shift 2 ;;
        --drain)          [ $# -ge 2 ] || die "missing value for $1"; DRAIN="$2"; shift 2 ;;
        --retry-delay)    [ $# -ge 2 ] || die "missing value for $1"; RETRY_DELAY="$2"; shift 2 ;;
        --log-dir)        [ $# -ge 2 ] || die "missing value for $1"; LOG_DIR="$2"; shift 2 ;;
        --quiet)          QUIET=1; shift ;;
        -h|--help)        usage; exit 0 ;;
        --)               shift; break ;;
        *) die "unknown argument: $1 (the command must follow --)" ;;
    esac
done
[ $# -gt 0 ] || die "no command given (use: $PROG [options] -- <command> [args...])"

for v in SPIN_TIMEOUT IDLE_TIMEOUT POLL RETRIES SPIN_CPU_PCT IDLE_CPU_PCT DRAIN RETRY_DELAY; do
    eval "val=\${$v}"
    case "$val" in ''|*[!0-9]*) die "$v must be a non-negative integer (got '$val')" ;; esac
done
[ "$POLL" -ge 1 ] || die "--poll must be >= 1"

if [ -z "$LOG_DIR" ]; then
    if [ -d "$PWD/artifacts" ]; then
        LOG_DIR="$PWD/artifacts/log/csc-watchdog"
    else
        LOG_DIR="${TMPDIR:-/tmp}/csc-watchdog"
    fi
fi
mkdir -p "$LOG_DIR" || die "cannot create log dir: $LOG_DIR"

HZ="$(getconf CLK_TCK 2>/dev/null || echo 100)"
case "$HZ" in ''|*[!0-9]*) HZ=100 ;; esac
TIMEOUT_BIN="$(command -v timeout 2>/dev/null || true)"
SNAP_TIMEOUT="${CSC_WATCHDOG_SNAP_TIMEOUT:-5}"
LOG_FILE="$LOG_DIR/watchdog.log"

# ---- /proc helpers ----------------------------------------------------------
# stat fields after "pid (comm) ": 1 state, 2 ppid, 3 pgrp, 4 session,
# ..., 12 utime, 13 stime (proc(5) fields 3..15).
stat_fields() { # <pid> -> "state ppid pgrp session utime stime"
    local st rest
    st="$(cat "/proc/$1/stat" 2>/dev/null)" || return 1
    rest="${st#*) }"
    # shellcheck disable=SC2086
    set -- $rest
    printf '%s %s %s %s %s %s\n' "$1" "$2" "$3" "$4" "${12}" "${13}"
}

proc_state() { # <pid> -> one-letter state or empty
    local f; f="$(stat_fields "$1" 2>/dev/null)" || return 1
    printf '%s' "${f%% *}"
}

proc_cpu() { # <pid> -> utime+stime ticks or empty
    local f; f="$(stat_fields "$1" 2>/dev/null)" || return 1
    # shellcheck disable=SC2086
    set -- $f
    printf '%s' "$(( $5 + $6 ))"
}

proc_pgrp() {
    local f; f="$(stat_fields "$1" 2>/dev/null)" || return 1
    # shellcheck disable=SC2086
    set -- $f
    printf '%s' "$3"
}

proc_io() { # "rchar wchar syscr syscw" or empty
    # NOTE: this OHOS procfs returns the file one read at a time to bash's
    # `read` builtin (second read = EOF), so slurp it with one cat and parse.
    local all v r="" w="" sr="" sw=""
    all="$(cat "/proc/$1/io" 2>/dev/null)" || return 1
    [ -n "$all" ] || return 1
    # shellcheck disable=SC2086
    set -- $all
    while [ $# -gt 0 ]; do
        case "$1" in
            rchar:) r="$2"; shift 2 ;;
            wchar:) w="$2"; shift 2 ;;
            syscr:) sr="$2"; shift 2 ;;
            syscw:) sw="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    printf '%s %s %s %s' "$r" "$w" "$sr" "$sw"
}

# Resolve the compiler's /out: artifact from its cmdline or its @rsp file.
resolve_out() {
    local pid=$1 cmd tok rsp="" out=""
    cmd="$(tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null)"
    # shellcheck disable=SC2086
    for tok in $cmd; do
        case "$tok" in
            /out:*) out="${tok#/out:}"; break ;;
            @*)     rsp="${tok#@}" ;;
        esac
    done
    if [ -z "$out" ] && [ -n "$rsp" ] && [ -f "$rsp" ]; then
        out="$(grep -m1 -o '/out:[^ ]*' "$rsp" 2>/dev/null)" || out=""
        out="${out#/out:}"
    fi
    printf '%s' "$out"
}

out_sig() { # <path> -> "size:mtime" or "-"
    [ -n "$1" ] && [ -f "$1" ] || { printf '-'; return; }
    stat -c '%s:%Y' "$1" 2>/dev/null || printf '-'
}

is_csc_fast() { # <pid> -> 0 when it is a Roslyn compiler process (forkless)
    local pid=$1 comm tok
    IFS= read -r comm < "/proc/$pid/comm" 2>/dev/null || return 1
    [ "$comm" = "csc" ] && return 0
    [ "$comm" = "dotnet" ] || return 1
    while IFS= read -r -d '' tok; do
        case "$tok" in
            *csc.dll*|*bincore/csc*) return 0 ;;
        esac
    done < "/proc/$pid/cmdline" 2>/dev/null
    return 1
}

ancestor_of_wrap() { # <pid> (forkless ppid walk)
    local p=$1 i=0 pp st rest
    while [ "$p" != 0 ] && [ "$p" != 1 ] && [ "$i" -lt 12 ]; do
        IFS= read -r st < "/proc/$p/stat" 2>/dev/null || return 1
        rest="${st#*) }"
        # shellcheck disable=SC2086
        set -- $rest
        pp="$2"
        [ -n "$pp" ] || return 1
        [ "$pp" = "$WRAP_PID" ] && return 0
        p="$pp"; i=$((i + 1))
    done
    return 1
}

read_session() { # <pid> -> session id (forkless read of our own child)
    local st rest
    IFS= read -r st < "/proc/$1/stat" 2>/dev/null || return 1
    rest="${st#*) }"
    # shellcheck disable=SC2086
    set -- $rest
    printf '%s' "$4"
}

owns() { # <pid>: PGID of our wrapped command, or a parent chain into it
    local pid=$1 pgrp
    pgrp="$(proc_pgrp "$pid" 2>/dev/null)" || return 1
    [ "$pgrp" = "$WRAP_PID" ] && return 0
    ancestor_of_wrap "$pid"
}

descendants() { # <root-pid> -> descendants, one per line (pgrep -P walk: our tree only)
    local frontier="$1" next found="" p c
    while [ -n "$frontier" ]; do
        next=""
        for p in $frontier; do
            for c in $(pgrep -P "$p" 2>/dev/null); do
                next="$next $c"; found="$found $c"
            done
        done
        frontier="$next"
    done
    # shellcheck disable=SC2086
    printf '%s\n' $found
}

# ---- evidence ---------------------------------------------------------------
snapshot_proc() { # <pid> <dir>
    local pid=$1 dir=$2
    {
        echo "time: $(date '+%Y-%m-%dT%H:%M:%S%z')"
        echo "pid: $pid"
        echo "cmdline: $(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)"
        echo "out: ${OUT_PATH[$pid]:-<none>} (sig ${OUT_SIG[$pid]:-<none>})"
        echo "state: $(proc_state "$pid" 2>/dev/null)"
        echo "cpu_ticks: $(proc_cpu "$pid" 2>/dev/null)"
        echo "io: $(proc_io "$pid" 2>/dev/null)"
        echo "wchan: $(cat "/proc/$pid/wchan" 2>/dev/null)"
        echo "rsp: ${RSP_PATH[$pid]:-<none>}"
    } > "$dir/event.txt" 2>&1
    # procfs reads can stall on a wedged process; bound every one of them.
    for f in status stat io wchan smaps_rollup; do
        [ -r "/proc/$pid/$f" ] || continue
        if [ -n "$TIMEOUT_BIN" ]; then
            "$TIMEOUT_BIN" -s KILL "$SNAP_TIMEOUT" cat "/proc/$pid/$f" > "$dir/$f.txt" 2>/dev/null || true
        else
            cat "/proc/$pid/$f" > "$dir/$f.txt" 2>/dev/null || true
        fi
    done
    {
        for t in /proc/$pid/task/*; do
            [ -d "$t" ] || continue
            echo "$(basename "$t") $(cat "$t/comm" 2>/dev/null) $(awk '{print $3}' "$t/stat" 2>/dev/null) $(cat "$t/wchan" 2>/dev/null)"
        done
    } > "$dir/threads.txt" 2>&1
    ls -l "/proc/$pid/fd" > "$dir/fd.txt" 2>&1 || true
    if [ -n "${RSP_PATH[$pid]:-}" ] && [ -f "${RSP_PATH[$pid]}" ]; then
        cat "${RSP_PATH[$pid]}" > "$dir/csc.rsp" 2>/dev/null || true
    fi
    if [ -n "${OUT_PATH[$pid]:-}" ] && [ -f "${OUT_PATH[$pid]}" ]; then
        stat -c 'size=%s mtime=%Y' "${OUT_PATH[$pid]}" > "$dir/out-stat.txt" 2>&1 || true
    fi
    descendants "$pid" > "$dir/descendants.txt" 2>/dev/null || true
}

kill_stalled() { # <pid> <kind> <rate> <dt>
    local pid=$1 kind=$2 rate=$3 dt=$4 dir children c
    KILLED=1
    KILL_TS="$(date +%s)"
    dir="$LOG_DIR/event-a${ATTEMPT}-$(date +%Y%m%d-%H%M%S)-pid$pid"
    mkdir -p "$dir" || { warn "cannot create evidence dir $dir"; dir="$LOG_DIR"; }
    # Announce the decision before snapshotting: a procfs read of a wedged
    # process can stall and must never delay the kill (or hide the trigger).
    log "$kind stall pid=$pid (dt=${dt}s cpu=${rate}%) -> SIGKILL process tree; evidence: $dir"
    snapshot_proc "$pid" "$dir"
    {
        echo "decision: $kind stall"
        echo "no-progress seconds: $dt"
        echo "cpu rate %% of one core over window: $rate"
        echo "spin_timeout=$SPIN_TIMEOUT idle_timeout=$IDLE_TIMEOUT poll=$POLL"
        echo "attempt=$ATTEMPT/$((RETRIES + 1))"
    } >> "$dir/event.txt"
    children="$(descendants "$pid" 2>/dev/null || true)"
    # shellcheck disable=SC2086
    for c in $children; do kill -9 "$c" 2>/dev/null || true; done
    [ -n "$children" ] && printf '%s\n' "$children" >> "$dir/killed.txt"
    kill -9 "$pid" 2>/dev/null || true
    # SIGKILL is asynchronous; wait briefly so the drained build can proceed.
    local i=0
    while [ "$i" -lt 10 ] && kill -0 "$pid" 2>/dev/null; do sleep 1; i=$((i + 1)); done
    if kill -0 "$pid" 2>/dev/null; then
        warn "pid $pid survived SIGKILL after ${i}s (kernel-side spin?) -- leaving it for the operator"
    fi
    printf '[%s] %s stall killed at %s; evidence: %s\n' "$PROG" "$kind" "$(date '+%H:%M:%S')" "$dir" >> "$LOG_FILE"
}

# ---- sample state -----------------------------------------------------------
declare -A SEEN IO_PREV CPU_BASE PROGRESS OUT_PATH OUT_SIG RSP_PATH KILLED_PID
KILLED=0
KILL_TS=""

sample_pid() { # <pid> <now>
    local pid=$1 now=$2 io out state f cpu dt rate
    io="$(proc_io "$pid" 2>/dev/null)" || return 0
    state="$(proc_state "$pid" 2>/dev/null)" || return 0
    f="$(stat_fields "$pid" 2>/dev/null)" || return 0
    # shellcheck disable=SC2086
    set -- $f
    cpu=$(( $5 + $6 ))
    [ "${KILLED_PID[$pid]:-0}" = 1 ] && return 0

    if [ -z "${SEEN[$pid]:-}" ]; then
        SEEN[$pid]=1
        IO_PREV[$pid]="$io"
        CPU_BASE[$pid]="$cpu"
        PROGRESS[$pid]="$now"
        local cmdline tok
        cmdline="$(tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null)"
        # shellcheck disable=SC2086
        for tok in $cmdline; do
            case "$tok" in @*) RSP_PATH[$pid]="${tok#@}"; break ;; esac
        done
        OUT_PATH[$pid]="$(resolve_out "$pid")"
        OUT_SIG[$pid]="$(out_sig "${OUT_PATH[$pid]}")"
        log "watching pid=$pid comm=$(cat "/proc/$pid/comm" 2>/dev/null) out=${OUT_PATH[$pid]:-<unknown>}"
        return 0
    fi

    out="$(out_sig "${OUT_PATH[$pid]:-}")"
    if [ "$io" != "${IO_PREV[$pid]}" ] || [ "$out" != "${OUT_SIG[$pid]}" ]; then
        IO_PREV[$pid]="$io"
        OUT_SIG[$pid]="$out"
        CPU_BASE[$pid]="$cpu"
        PROGRESS[$pid]="$now"
        return 0
    fi

    dt=$(( now - ${PROGRESS[$pid]:-$now} ))
    [ "$dt" -le 0 ] && return 0
    rate=$(( (cpu - ${CPU_BASE[$pid]:-$cpu}) * 100 / (dt * HZ) ))
    [ "$rate" -lt 0 ] && rate=0

    if [ "$IDLE_TIMEOUT" -gt 0 ] && [ "$dt" -ge "$IDLE_TIMEOUT" ] && [ "$rate" -le "$IDLE_CPU_PCT" ] \
       && [ "$state" != "D" ] && [ "$state" != "Z" ] && [ "$state" != "X" ]; then
        KILLED_PID[$pid]=1
        kill_stalled "$pid" idle "$rate" "$dt"
    elif [ "$SPIN_TIMEOUT" -gt 0 ] && [ "$dt" -ge "$SPIN_TIMEOUT" ] && [ "$rate" -ge "$SPIN_CPU_PCT" ]; then
        KILLED_PID[$pid]=1
        kill_stalled "$pid" spin "$rate" "$dt"
    fi
}

monitor_round() {
    local now sid pid
    now="$(date +%s)"
    # Known compilers are sampled directly (they may be reparented but keep the
    # session). New ones are discovered with pgrep over our own session -- never
    # by reading foreign /proc entries, which can block on this kernel.
    for pid in "${!SEEN[@]}"; do
        [ "${SEEN[$pid]:-}" = 1 ] || continue
        sample_pid "$pid" "$now"
    done
    sid="$(read_session "$WRAP_PID" 2>/dev/null || true)"
    [ -n "$sid" ] || return 0
    for pid in $(pgrep -s "$sid" -x csc 2>/dev/null) $(pgrep -s "$sid" -x dotnet 2>/dev/null); do
        [ "${SEEN[$pid]:-}" = 1 ] && continue
        is_csc_fast "$pid" || continue
        owns "$pid" || continue
        sample_pid "$pid" "$now"
    done
}

# ---- run / retry loop -------------------------------------------------------
WRAP_PID=""
on_signal() {
    if [ -n "$WRAP_PID" ]; then
        warn "signal received; forwarding SIGTERM to the wrapped command group $WRAP_PID"
        kill -TERM -- "-$WRAP_PID" 2>/dev/null || true
        sleep 1
        kill -KILL -- "-$WRAP_PID" 2>/dev/null || true
    fi
    exit 130
}
trap on_signal INT TERM HUP

log "command: $(printf '%q ' "$@")"
log "limits: spin=${SPIN_TIMEOUT}s idle=${IDLE_TIMEOUT}s poll=${POLL}s retries=$RETRIES (0=off switch via timeout 0)"
log "evidence/log dir: $LOG_DIR"

ATTEMPT=1
while :; do
    if [ "$ATTEMPT" -gt 1 ]; then
        log "retry attempt $ATTEMPT/$((RETRIES + 1))"
    fi
    set -m   # the wrapped command becomes its own process-group leader (PGID == PID)
    "$@" &
    WRAP_PID=$!
    set +m
    log "started pid=$WRAP_PID (attempt $ATTEMPT/$((RETRIES + 1)))"

    while :; do
        st="$(proc_state "$WRAP_PID" 2>/dev/null)" || break
        case "$st" in Z|X|"") break ;; esac
        monitor_round
        # A killed compiler should make the command fail promptly. If it does
        # not, drain the wrapped process group so the retry starts cleanly.
        if [ "$KILLED" = 1 ] && [ -n "$KILL_TS" ] && [ "$DRAIN" -gt 0 ] \
           && [ $(( $(date +%s) - KILL_TS )) -ge "$DRAIN" ]; then
            warn "command still alive ${DRAIN}s after the csc kill; SIGKILLing its process group $WRAP_PID"
            kill -9 -- "-$WRAP_PID" 2>/dev/null || true
            KILL_TS=""
        fi
        sleep "$POLL"
    done

    rc=0
    wait "$WRAP_PID" 2>/dev/null || rc=$?
    WRAP_PID=""

    # If a kill happened the build is expected to fail; if it somehow does not
    # exit promptly, drain it so the retry can start on a clean process tree.
    if [ "${KILLED:-0}" = 1 ] && [ "$rc" -ne 0 ]; then
        log "attempt $ATTEMPT failed rc=$rc after a csc kill"
    elif [ "$rc" -ne 0 ]; then
        log "attempt $ATTEMPT failed rc=$rc (no csc kill; not retrying)"
        exit "$rc"
    else
        log "command succeeded rc=0 on attempt $ATTEMPT"
        exit 0
    fi

    if [ "$KILLED" = 1 ] && [ "$ATTEMPT" -le "$RETRIES" ]; then
        KILLED=0
        ATTEMPT=$((ATTEMPT + 1))
        log "sleeping ${RETRY_DELAY}s before retry"
        sleep "$RETRY_DELAY"
        continue
    fi
    if [ "$KILLED" = 1 ]; then
        warn "csc watchdog killed a stalled compiler and the retry budget is exhausted; evidence under $LOG_DIR"
        exit "$rc"
    fi
    exit "$rc"
done
