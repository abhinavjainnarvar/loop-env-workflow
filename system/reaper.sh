#!/usr/bin/env bash
# reaper.sh — audit (and optionally clean) worktrees a dead worker left behind.
#
# The hole this closes: a worker that dies mid-job leaves its git worktree on disk;
# the next dispatch for that ticket collides with it, and the board row sits stuck.
# Deterministic policy — the reaper only ever removes what is provably safe:
#   REMOVE  clean (no uncommitted changes) AND fully pushed (branch head == its
#           origin ref) — everything lives on the remote, a fresh worktree is cheap.
#   KEEP    anything dirty or with unpushed commits → flagged `needs-human`
#           (mirrors run-ticket's "never --force unrelated WIP" rule).
#   PRUNE   admin entries whose directory is already gone (`git worktree prune`).
#
# Default is a DRY-RUN report; nothing is touched without --apply.
#
# Usage: reaper.sh --repo DIR [--apply] [--min-age-mins N]
#   --min-age-mins  never touch a worktree younger than N minutes (default 60) —
#                   a live worker's checkout looks identical to an orphan; age is
#                   the tie-breaker (dispatches renew mtime as they work).
# Output: one line per worktree —  <verdict>|<path>|<branch>|<detail>
#   verdicts: removed | would-remove | needs-human | too-young | pruned-entries
# Exit: 0 (report complete) · 2 usage
set -euo pipefail

REPO="" APPLY=0 MIN_AGE_MINS=60
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2;;
    --apply) APPLY=1; shift;;
    --min-age-mins) MIN_AGE_MINS="$2"; shift 2;;
    *) echo "reaper: unknown arg '$1'" >&2; exit 2;;
  esac
done
[ -n "$REPO" ] && [ -d "$REPO/.git" ] || { echo "usage: reaper.sh --repo <main-checkout> [--apply] [--min-age-mins N]" >&2; exit 2; }

G(){ git -C "$REPO" "$@"; }
now=$(date +%s)
mtime(){ stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo "$now"; }

# 1) prune admin entries for already-deleted directories
pruned=$(G worktree list --porcelain | grep -c '^prunable' || true)
if [ "$APPLY" -eq 1 ]; then G worktree prune; fi
[ "${pruned:-0}" -gt 0 ] && echo "pruned-entries|$pruned stale admin entries|-|$([ $APPLY -eq 1 ] && echo pruned || echo would-prune)"

# 2) walk real worktrees (skip the main checkout itself)
main_top=$(G rev-parse --show-toplevel)
G worktree list --porcelain | awk '/^worktree /{print $2}' | while read -r wt; do
  [ "$wt" = "$main_top" ] && continue
  [ -d "$wt" ] || continue
  branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "?")
  age_mins=$(( (now - $(mtime "$wt")) / 60 ))

  if [ "$age_mins" -lt "$MIN_AGE_MINS" ]; then
    echo "too-young|$wt|$branch|${age_mins}m old (< ${MIN_AGE_MINS}m) — may be a live worker"
    continue
  fi
  # dirty? (uncommitted tracked changes or untracked files)
  if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
    echo "needs-human|$wt|$branch|uncommitted changes — never auto-removed"
    continue
  fi
  # unpushed? branch must have an upstream (or an origin/<branch>) at the same sha
  head_sha=$(git -C "$wt" rev-parse HEAD 2>/dev/null || echo "")
  remote_sha=$(git -C "$wt" rev-parse '@{u}' 2>/dev/null \
             || G rev-parse "origin/$branch" 2>/dev/null || echo "")
  if [ -z "$remote_sha" ] || [ "$head_sha" != "$remote_sha" ]; then
    echo "needs-human|$wt|$branch|unpushed commits (head ${head_sha:0:9} vs remote ${remote_sha:0:9}) — never auto-removed"
    continue
  fi
  # clean + pushed + old enough → safe
  if [ "$APPLY" -eq 1 ]; then
    G worktree remove --force "$wt" 2>/dev/null && echo "removed|$wt|$branch|clean + pushed (${age_mins}m old)" \
      || echo "needs-human|$wt|$branch|remove failed — inspect manually"
  else
    echo "would-remove|$wt|$branch|clean + pushed (${age_mins}m old) — run with --apply"
  fi
done
[ "$APPLY" -eq 1 ] && G worktree prune || true
