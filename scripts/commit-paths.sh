#!/bin/sh
# commit-paths.sh - commit exactly the paths you own while other agents use the same checkout.
#
# Usage: sh scripts/commit-paths.sh -m <message> [--dry-run] -- <path> [<path>...]
#
# The guard, in order:
#   1. every <path> must show a change in `git status --porcelain -- <path>`; a clean, ignored or
#      unknown path is refused (almost always a typo or the wrong checkout);
#   2. only the listed paths are staged (`git add -A -- <path>...`); listing a directory covers
#      its whole subtree, and only that subtree;
#   3. if `git diff --cached --name-only` names anything outside the list, the run aborts and
#      prints those files: a concurrent agent staged work in parallel, and committing now would
#      sweep it in. Before exiting, the paths this run staged are unstaged again (best effort),
#      so the index is left as the run found it and the other agent can commit normally;
#   4. `git commit` runs with the fixed author springmin <springmin@hotmail.com>.
#
# Paths are repository-relative and must not be absolute or contain `..`; the script itself can
# run from any subdirectory of the work tree.
#
# --dry-run validates and prints the plan (per-path status, staged-set conflicts) without
# touching the index and without creating a commit.
#
# Exit code: 0 = committed (or dry-run plan printed); 1 = refused/aborted; 2 = usage error.
set -u

AUTHOR_NAME=springmin
AUTHOR_EMAIL=springmin@hotmail.com

MSG=
DRY_RUN=0

usage() {
    cat <<'EOF'
usage: sh scripts/commit-paths.sh -m <message> [--dry-run] -- <path> [<path>...]

Commits exactly the listed paths as springmin <springmin@hotmail.com>. Refuses a path without
changes, aborts when the staged set contains anything outside the list (concurrent work), and
prints the plan with --dry-run. Exit: 0 ok, 1 refused, 2 usage error.
EOF
}

warn() { printf 'commit-paths: %s\n' "$*" >&2; }
die_usage() { warn "$*"; usage >&2; exit 2; }
die_refuse() { warn "$*"; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        -m)
            [ $# -ge 2 ] || die_usage "missing message after -m"
            [ -n "$2" ] || die_usage "empty message"
            MSG="$2"
            shift 2
            ;;
        --dry-run) DRY_RUN=1; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        *) die_usage "unknown argument: $1 (paths must follow --)" ;;
    esac
done
[ -n "$MSG" ] || die_usage "missing -m <message>"
[ $# -gt 0 ] || die_usage "no paths given"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die_refuse "not inside a git work tree"
cd "$ROOT" || die_refuse "cannot enter work tree: $ROOT"

TMPD="$(mktemp -d "${TMPDIR:-/tmp}/commit-paths.XXXXXX" 2>/dev/null)" || die_refuse "cannot create a temp dir"
trap 'rm -rf "$TMPD"' 0 1 2 3 15
LIST="$TMPD/paths"
STAGED_BEFORE="$TMPD/staged-before"
STAGED_AFTER="$TMPD/staged-after"
EXTRAS="$TMPD/extras"
: > "$LIST"

# ---- 1. validate the path list and demand a visible change for each --------------------------
for p do
    case "$p" in
        /*) die_refuse "absolute path refused: $p" ;;
        ".."|../*|*/../*|*/..) die_refuse "path with '..' refused: $p" ;;
    esac
    [ -n "$p" ] || die_refuse "empty path"
    while :; do
        case "$p" in
            ./*) p="${p#./}" ;;
            *) break ;;
        esac
    done
    [ -n "$p" ] || die_refuse "path is empty after ./ normalization"
    printf '%s\n' "$p" >> "$LIST"
done

while IFS= read -r p; do
    ST="$(git status --porcelain -- "$p" 2>&1)" || die_refuse "git status failed for '$p': $ST"
    [ -n "$ST" ] || die_refuse "no changes for path: $p"
done < "$LIST"

# ---- 2./3. stage, then verify that nothing outside the list entered the index ----------------
# An entry is allowed when it equals a listed path or lives under a listed directory.
check_staged_extras() { # <staged-names-file> <extra-names-file>; returns 0 when there are none
    : > "$2"
    while IFS= read -r n; do
        [ -n "$n" ] || continue
        found=0
        while IFS= read -r p; do
            if [ "$n" = "$p" ]; then
                found=1
                break
            fi
            case "$n" in
                "$p"/*) found=1; break ;;
            esac
        done < "$LIST"
        [ "$found" = 1 ] || printf '%s\n' "$n" >> "$2"
    done < "$1"
    [ ! -s "$2" ]
}

git diff --cached --name-only > "$STAGED_BEFORE"

if [ "$DRY_RUN" = 1 ]; then
    printf 'commit-paths: dry-run plan\n'
    printf '  repo:    %s\n' "$ROOT"
    printf '  message: %s\n' "$MSG"
    printf '  paths (status):\n'
    while IFS= read -r p; do
        printf '    %s: %s\n' "$p" "$(git status --porcelain -- "$p" | head -n 1)"
    done < "$LIST"
    if [ -s "$STAGED_BEFORE" ]; then
        printf '  staged before (kept):\n'
        sed 's/^/    /' "$STAGED_BEFORE"
    fi
    if ! check_staged_extras "$STAGED_BEFORE" "$EXTRAS"; then
        printf '  staged outside the list (a real run would abort):\n'
        sed 's/^/    /' "$EXTRAS"
    fi
    printf '  dry-run: nothing staged, nothing committed\n'
    exit 0
fi

while IFS= read -r p; do
    git add -A -- "$p" || die_refuse "git add failed for '$p'"
done < "$LIST"

git diff --cached --name-only > "$STAGED_AFTER"
if ! check_staged_extras "$STAGED_AFTER" "$EXTRAS"; then
    warn "refusing to commit: staged set contains path(s) outside the list (concurrent work?):"
    sed 's/^/  /' "$EXTRAS" >&2
    while IFS= read -r n; do
        [ -n "$n" ] || continue
        grep -Fxq -- "$n" "$STAGED_BEFORE" 2>/dev/null && continue
        git reset -q -- "$n" 2>/dev/null || true
    done < "$STAGED_AFTER"
    warn "nothing committed; the paths staged by this run were unstaged again"
    exit 1
fi

# ---- 4. commit with the fixed author ---------------------------------------------------------
git -c user.name="$AUTHOR_NAME" -c user.email="$AUTHOR_EMAIL" commit -m "$MSG" || {
    warn "git commit failed; the paths stay staged for inspection"
    exit 1
}
git log -1 --format='commit-paths: committed %h %s'
