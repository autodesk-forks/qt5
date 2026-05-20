#!/usr/bin/env bash
#
# SyncFromUpstream.sh
#
# For each configured branch, fetch from upstream github.com/qt/* and push to
# this fork's origin (git.autodesk.com/autodesk-forks/*). Operates on both the
# superproject and a configured set of LGPL/build-active submodules.
#
# Never touches the user's working tree: works directly on .git dirs and uses
# explicit refspecs. No local branch is created or checked out.
#
# Usage:
#   ./SyncFromUpstream.sh [options]
#
# Options:
#   -c, --config FILE      Path to config (default: sync-upstream.conf beside this script)
#       --branches "A B"   Override SYNC_BRANCHES from config
#       --only NAME[,N...] Limit to listed submodule(s); 'qt5' selects the superproject
#       --force            Use --force-with-lease on push (override ALLOW_FORCE_PUSH)
#       --fail-fast        Abort on first failure (override FAIL_FAST)
#       --dry-run          Fetch and report, but do not push
#   -h, --help             Show this help
#
# Works on macOS (default bash 3.2) and Windows Git Bash. Stays within bash 3.2 features.

set -u

#####################################################################
# Resolve paths and source config
#####################################################################

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_PATH/.." && pwd)"
DEFAULT_CONF="$SCRIPT_PATH/sync-upstream.conf"

CONF="$DEFAULT_CONF"
CLI_BRANCHES=""
CLI_REPOS=""
CLI_FORCE=0
CLI_FAIL_FAST=0
DRY_RUN=0

usage() {
    cat <<'EOF'
SyncFromUpstream.sh — fetch branches from upstream github.com/qt/* and push to origin.

Usage:
  ./SyncFromUpstream.sh [options]

Options:
  -c, --config FILE       Path to config (default: sync-upstream.conf beside this script)
      --branches "A B"    Override SYNC_BRANCHES from config
      --repos NAME[,N...] Limit to listed repo(s); 'qt5' selects the superproject
      --force             Use --force-with-lease on push (override ALLOW_FORCE_PUSH)
      --fail-fast         Abort on first failure (override FAIL_FAST)
      --dry-run           Fetch and report, but do not push
  -h, --help              Show this help

Operates directly on .git dirs; the working tree is never touched.
Works on macOS (bash 3.2+) and Windows Git Bash.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -c|--config)   CONF="$2"; shift 2 ;;
        --branches)    CLI_BRANCHES="$2"; shift 2 ;;
        --repos)       CLI_REPOS="$2"; shift 2 ;;
        --force)       CLI_FORCE=1; shift ;;
        --fail-fast)   CLI_FAIL_FAST=1; shift ;;
        --dry-run)     DRY_RUN=1; shift ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
done

if [ ! -f "$CONF" ]; then
    echo "ERROR: config file not found: $CONF" >&2
    exit 2
fi

# shellcheck disable=SC1090
. "$CONF"

[ -n "$CLI_BRANCHES" ]    && SYNC_BRANCHES="$CLI_BRANCHES"
[ "$CLI_FORCE" = "1" ]    && ALLOW_FORCE_PUSH=1
[ "$CLI_FAIL_FAST" = "1" ] && FAIL_FAST=1

: "${SYNC_BRANCHES:?SYNC_BRANCHES is empty}"
: "${UPSTREAM_BASE:?UPSTREAM_BASE is empty}"
: "${UPSTREAM_REMOTE:?UPSTREAM_REMOTE is empty}"
: "${ALLOW_FORCE_PUSH:=0}"
: "${FAIL_FAST:=0}"
: "${SKIP_IGNORED_SUBMODULES:=1}"
: "${SKIP_MODULES:=}"

cd "$REPO_ROOT"

#####################################################################
# Helpers
#####################################################################

# in_list NEEDLE HAYSTACK   -- word-membership test (whitespace-separated)
in_list() {
    needle="$1"; haystack="$2"
    for item in $haystack; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

# Resolve a relative submodule URL (../qtbase.git) against the superproject's
# origin URL. Echoes the absolute URL.
resolve_origin_url() {
    name="$1"
    rel="$(git config -f .gitmodules --get "submodule.${name}.url" || true)"
    [ -z "$rel" ] && { echo ""; return 1; }
    case "$rel" in
        http://*|https://*|git@*|ssh://*|git://*) echo "$rel"; return 0 ;;
    esac
    super_origin="$(git config --get remote.origin.url)"
    # Strip last path component of super_origin, then join with $rel (which
    # starts with "../"). Examples:
    #   super_origin = https://git.autodesk.com/autodesk-forks/qt5.git
    #   rel          = ../qtbase.git
    #   result       = https://git.autodesk.com/autodesk-forks/qtbase.git
    parent="${super_origin%/*}"
    case "$rel" in
        ../*) echo "${parent}/${rel#../}" ;;
        ./*)  echo "${super_origin%/*}/${rel#./}" ;;
        *)    echo "${parent}/${rel}" ;;
    esac
}

# Build the list of skipped submodules from .gitmodules (status=ignore).
ignored_submodules() {
    git config -f .gitmodules --get-regexp '^submodule\..*\.status$' 2>/dev/null \
        | awk '$2=="ignore"{ key=$1; sub(/^submodule\./,"",key); sub(/\.status$/,"",key); print key }'
}

# All submodule names, in .gitmodules order.
all_submodules() {
    git config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null \
        | awk '{ key=$1; sub(/^submodule\./,"",key); sub(/\.path$/,"",key); print key }'
}

#####################################################################
# Compute module work-list
#####################################################################

SKIP_SET="$SKIP_MODULES"
if [ "$SKIP_IGNORED_SUBMODULES" = "1" ]; then
    for m in $(ignored_submodules); do
        SKIP_SET="$SKIP_SET $m"
    done
fi

# Normalise --repos into a space-separated list.
REPOS_SET=""
if [ -n "$CLI_REPOS" ]; then
    REPOS_SET="$(echo "$CLI_REPOS" | tr ',' ' ')"
fi

WORK_LIST=""
for m in $(all_submodules); do
    if in_list "$m" "$SKIP_SET"; then continue; fi
    if [ -n "$REPOS_SET" ] && ! in_list "$m" "$REPOS_SET"; then continue; fi
    WORK_LIST="$WORK_LIST $m"
done

# Decide if we run the superproject. By default yes, unless --repos restricts to
# submodules and does not include 'qt5'.
INCLUDE_SUPER=1
if [ -n "$REPOS_SET" ] && ! in_list "qt5" "$REPOS_SET"; then
    INCLUDE_SUPER=0
fi

#####################################################################
# Result tracking
#####################################################################

RESULT_LOG="$(mktemp -t syncupstream.XXXXXX 2>/dev/null || mktemp)"
trap 'rm -f "$RESULT_LOG"' EXIT

# record STATUS  MODULE  BRANCH  DETAIL
record() {
    printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$RESULT_LOG"
}

#####################################################################
# sync_one  NAME  GIT_DIR  ORIGIN_URL_FOR_LAZY_INIT  BRANCH  INDEX  TOTAL
#####################################################################

sync_one() {
    name="$1"; git_dir="$2"; origin_for_init="$3"; branch="$4"
    idx="$5"; total="$6"

    printf '[%2d/%2d] %-22s %-12s ... ' "$idx" "$total" "$name" "$branch"

    # Lazy-init bare git dir for uninitialised submodules.
    if [ ! -d "$git_dir" ]; then
        if [ -z "$origin_for_init" ]; then
            echo "FAILED (cannot resolve origin URL)"
            record FAILED "$name" "$branch" "no-origin-url"
            return 1
        fi
        mkdir -p "$(dirname "$git_dir")"
        if ! git init --bare --quiet "$git_dir" 2>/dev/null; then
            echo "FAILED (git init --bare)"
            record FAILED "$name" "$branch" "init-bare"
            return 1
        fi
        if ! git --git-dir="$git_dir" remote add origin "$origin_for_init" 2>/dev/null; then
            # If origin already exists from a previous attempt, ignore.
            :
        fi
    fi

    upstream_url="${UPSTREAM_BASE}/${name}.git"

    # A) ensure upstream remote, idempotent
    if git --git-dir="$git_dir" remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
        cur="$(git --git-dir="$git_dir" remote get-url "$UPSTREAM_REMOTE")"
        if [ "$cur" != "$upstream_url" ]; then
            git --git-dir="$git_dir" remote set-url "$UPSTREAM_REMOTE" "$upstream_url" || {
                echo "FAILED (remote set-url)"
                record FAILED "$name" "$branch" "remote-set-url"
                return 1
            }
        fi
    else
        if ! git --git-dir="$git_dir" remote add "$UPSTREAM_REMOTE" "$upstream_url" 2>/dev/null; then
            echo "FAILED (remote add)"
            record FAILED "$name" "$branch" "remote-add"
            return 1
        fi
    fi

    # B) fetch single branch
    if ! git --git-dir="$git_dir" fetch --no-tags --prune --quiet "$UPSTREAM_REMOTE" \
            "+refs/heads/${branch}:refs/remotes/${UPSTREAM_REMOTE}/${branch}" 2>/dev/null; then
        # Distinguish missing-branch from network error: if HEAD ref now exists
        # for the remote, the fetch ran but the branch isn't there.
        if git --git-dir="$git_dir" ls-remote --exit-code --heads "$UPSTREAM_REMOTE" "$branch" >/dev/null 2>&1; then
            echo "FAILED (fetch)"
            record FAILED "$name" "$branch" "fetch"
        else
            echo "SKIPPED (no upstream branch)"
            record SKIPPED "$name" "$branch" "no-upstream-branch"
        fi
        return 1
    fi

    # C) verify the ref landed
    if ! git --git-dir="$git_dir" rev-parse --verify --quiet \
            "refs/remotes/${UPSTREAM_REMOTE}/${branch}^{commit}" >/dev/null; then
        echo "SKIPPED (no upstream branch)"
        record SKIPPED "$name" "$branch" "no-upstream-branch"
        return 1
    fi

    # D) push to origin
    if [ "$DRY_RUN" = "1" ]; then
        sha="$(git --git-dir="$git_dir" rev-parse "refs/remotes/${UPSTREAM_REMOTE}/${branch}")"
        echo "OK (dry-run would push ${sha:0:10})"
        record OK "$name" "$branch" "dry-run"
        return 0
    fi

    if [ "$ALLOW_FORCE_PUSH" = "1" ]; then
        push_args="--force-with-lease=refs/heads/${branch}"
    else
        push_args=""
    fi

    push_err="$(git --git-dir="$git_dir" push --quiet $push_args origin \
        "refs/remotes/${UPSTREAM_REMOTE}/${branch}:refs/heads/${branch}" 2>&1)"
    push_status=$?

    if [ $push_status -ne 0 ]; then
        case "$push_err" in
            *non-fast-forward*|*"non fast forward"*|*"rejected"*|*"failed to push"*)
                echo "FAILED (non-fast-forward)"
                record FAILED "$name" "$branch" "non-fast-forward"
                ;;
            *)
                echo "FAILED (push)"
                record FAILED "$name" "$branch" "push"
                ;;
        esac
        return 1
    fi

    echo "OK"
    record OK "$name" "$branch" ""
    return 0
}

#####################################################################
# Header
#####################################################################

# Count ops to populate the [idx/total] counter.
ops_per_branch=0
[ "$INCLUDE_SUPER" = "1" ] && ops_per_branch=$((ops_per_branch + 1))
for m in $WORK_LIST; do ops_per_branch=$((ops_per_branch + 1)); done
branch_count=0
for b in $SYNC_BRANCHES; do branch_count=$((branch_count + 1)); done
total_ops=$((ops_per_branch * branch_count))

skipped_count=0
for m in $(all_submodules); do
    in_list "$m" "$SKIP_SET" && skipped_count=$((skipped_count + 1))
done

echo "=============================================="
echo "Sync from upstream  github.com/qt/*  ->  origin"
echo "  Branches:        $SYNC_BRANCHES"
echo "  Modules:         $ops_per_branch per branch ($skipped_count skipped from .gitmodules)"
echo "  Upstream base:   $UPSTREAM_BASE"
echo "  Force push:      $([ "$ALLOW_FORCE_PUSH" = "1" ] && echo "yes (with lease)" || echo "no")"
echo "  Dry run:         $([ "$DRY_RUN" = "1" ] && echo "yes" || echo "no")"
echo "  Fail-fast:       $([ "$FAIL_FAST" = "1" ] && echo "yes" || echo "no")"
echo "=============================================="
echo ""

#####################################################################
# Main loop
#####################################################################

abort=0
op_idx=0

for branch in $SYNC_BRANCHES; do
    [ $abort -eq 1 ] && break

    if [ "$INCLUDE_SUPER" = "1" ]; then
        op_idx=$((op_idx + 1))
        sync_one "qt5" "$REPO_ROOT/.git" "" "$branch" "$op_idx" "$total_ops"
        rc=$?
        if [ $rc -ne 0 ] && [ "$FAIL_FAST" = "1" ]; then abort=1; break; fi
    fi

    for m in $WORK_LIST; do
        op_idx=$((op_idx + 1))
        gd="$REPO_ROOT/.git/modules/$m"
        origin_url="$(resolve_origin_url "$m")"
        sync_one "$m" "$gd" "$origin_url" "$branch" "$op_idx" "$total_ops"
        rc=$?
        if [ $rc -ne 0 ] && [ "$FAIL_FAST" = "1" ]; then abort=1; break; fi
    done
done

#####################################################################
# Summary
#####################################################################

ok_count=$(awk -F'\t' '$1=="OK"     {n++} END{print n+0}' "$RESULT_LOG")
skip_count=$(awk -F'\t' '$1=="SKIPPED"{n++} END{print n+0}' "$RESULT_LOG")
fail_count=$(awk -F'\t' '$1=="FAILED" {n++} END{print n+0}' "$RESULT_LOG")

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="
echo "  OK:       $ok_count"
echo "  SKIPPED:  $skip_count"
echo "  FAILED:   $fail_count"

if [ "$skip_count" -gt 0 ]; then
    echo ""
    echo "  Skipped:"
    awk -F'\t' '$1=="SKIPPED"{ printf "    %-22s %-12s  (%s)\n", $2, $3, $4 }' "$RESULT_LOG"
fi

if [ "$fail_count" -gt 0 ]; then
    echo ""
    echo "  Failed:"
    awk -F'\t' '$1=="FAILED"{ printf "    %-22s %-12s  (%s)\n", $2, $3, $4 }' "$RESULT_LOG"
    echo ""
    echo "  For non-fast-forward failures, re-run with --force after"
    echo "  confirming the overwrite is intended."
fi

[ "$fail_count" -gt 0 ] && exit 1
exit 0
