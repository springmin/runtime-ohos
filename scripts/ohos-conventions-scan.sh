#!/usr/bin/env bash
# ============================================================================
# ohos-conventions-scan.sh
#
# Scan the added lines of the OHOS PR branches for fork-convention violations
# (see .github/instructions/conventions.instructions.md):
#   [COMPlus]      COMPlus_* env vars (DOTNET_* only)
#   [pragma-warning], [NoWarn]
#   [fork-local]   springmin/hqzing identifiers, docs/plans, final-evidence,
#                  /data/storage, /home/* and *.omo paths leaking into sources
#   [todo-nolink]  TODO without a link/issue
#   [tab]          tabs in C#/C++/MSBuild sources
#   [whitespace], [modes/new], [generated/eng-common], [tfm]
#
# Usage:
#   bash scripts/ohos-conventions-scan.sh [--base <ref>] <branch> [<branch>...]
#   bash scripts/ohos-conventions-scan.sh    # feature/openharmony vs its upstream/main merge-base
#
# Env:
#   OHOS_CONVENTIONS_OUT  write the report to this file (default: a temp file, printed below)
# ============================================================================
set -u

REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not in a git work tree" >&2; exit 2; }
cd "$REPO" || exit 2

BASE=""
BRANCHES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --base)
      [ $# -ge 2 ] || { echo "missing ref after --base" >&2; exit 2; }
      BASE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) BRANCHES+=("$1"); shift ;;
  esac
done
if [ "${#BRANCHES[@]}" -eq 0 ]; then
  BRANCHES=(feature/openharmony)
fi

TMPOUT=""
if [ -n "${OHOS_CONVENTIONS_OUT:-}" ]; then
  OUT="$OHOS_CONVENTIONS_OUT"
else
  TMPOUT="$(mktemp "${TMPDIR:-/tmp}/ohos-conventions.XXXXXX")" || exit 2
  OUT="$TMPOUT"
fi
: > "$OUT"
trap '[ -n "$TMPOUT" ] && rm -f "$TMPOUT"' 0 1 2 3 15

prepared() { # <branch> <base>
  local b="$1" base="$2"
  local mb
  mb="$(git merge-base "$base" "$b" 2>/dev/null)" || {
    echo "### $b: cannot resolve merge-base with $base" >> "$OUT"
    return 1
  }
  local diff; diff="$(git diff "$mb...$b" 2>/dev/null)"
  echo "### $b (base $(git rev-parse --short "$mb"))" >> "$OUT"
  # added lines with context of file
  local curfile=""
  echo "$diff" | while IFS= read -r line; do
    case "$line" in
      "+++ b/"*) curfile="${line#+++ b/}" ;;
      "+"*)
        [ "${line:0:3}" = "+++" ] && continue
        local add="${line:1}"
        case "$add" in
          *COMPlus_*) echo "  [COMPlus] $curfile: $add" >> "$OUT" ;;
        esac
        case "$add" in
          *"pragma warning disable"*) echo "  [pragma-warning] $curfile: $add" >> "$OUT" ;;
        esac
        case "$add" in
          *NoWarn*) echo "  [NoWarn] $curfile: $add" >> "$OUT" ;;
        esac
        case "$add" in
          *springmin*|*hqzing*|*docs/plans*|*final-evidence*|*/data/storage*|*/home/*|*.omo*) echo "  [fork-local] $curfile: $add" >> "$OUT" ;;
        esac
        case "$add" in
          *TODO*) case "$add" in *http*|*"#"*) ;; *) echo "  [todo-nolink] $curfile: $add" >> "$OUT" ;; esac ;;
        esac
        case "$curfile" in
          *.cs|*.cpp|*.h|*.c|*.targets|*.props|*.proj)
            printf '%s' "$add" | grep -q $'\t' && echo "  [tab] $curfile: $add" >> "$OUT"
            ;;
        esac
        ;;
    esac
  done
  # whitespace errors
  local ws; ws="$(git diff --check "$mb...$b" 2>/dev/null)"
  [ -n "$ws" ] && echo "  [whitespace] $ws" >> "$OUT"
  # mode changes
  local mc; mc="$(git diff --summary "$mb...$b" 2>/dev/null | grep -E 'mode change|create mode|delete mode')"
  [ -n "$mc" ] && echo "  [modes/new] $mc" >> "$OUT"
  # eng/common or generated files
  local bad; bad="$(git diff --name-only "$mb...$b" 2>/dev/null | grep -E '^eng/common/|_generated|\.g\.cs$|\.xlf$|WasiPoll')"
  [ -n "$bad" ] && echo "  [generated/eng-common] $bad" >> "$OUT"
  # hardcoded TFM
  echo "$diff" | grep -E '^\+' | grep -vE '^\+\+\+' | grep -nE 'net[0-9]+\.[0-9]+' | sed "s|^|  [tfm] $b: |" >> "$OUT"
  echo >> "$OUT"
}

rc=0
for b in "${BRANCHES[@]}"; do
  git rev-parse --verify -q "$b" >/dev/null || { echo "skip: no such ref '$b'" >&2; rc=1; continue; }
  base="$BASE"
  [ -n "$base" ] || base="upstream/main"
  prepared "$b" "$base" || rc=1
done

echo "scan written to $OUT"
cat "$OUT"
exit "$rc"
