#!/usr/bin/env bash
# sync-checkout.sh — fast-forward the owner's working checkout to a branch's remote head.
#
# Why this exists: workers build in isolated DETACHED worktrees and push `HEAD:<branch>`, so
# the owner's own checkout is left behind and he has to run `pull --ff-only` by hand. Twice
# that gap produced a checkout whose index looked like 16 staged reverts of the worker's
# fixes. The loop now closes the gap itself, after integrating a push.
#
# It is deliberately timid. It refuses rather than resolves:
#   - only fast-forward, never a merge, rebase or reset (no history invented, nothing lost)
#   - only if the checkout is ON that branch (never switches branches under the owner)
#   - only if the tree AND index are clean (never touches uncommitted or staged work)
#   - only if strictly behind (diverged → report, don't "fix")
# Anything else exits non-zero with the reason, for the loop to relay.
#
# Usage: sync-checkout.sh --repo DIR --branch NAME [--remote URL] [--dry-run]
# Exit: 0 synced or already current · 1 skipped (reason printed) · 2 usage

set -uo pipefail
REPO="" BRANCH="" REMOTE="" DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2;;
    --branch) BRANCH="$2"; shift 2;;
    --remote) REMOTE="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    *) echo "sync-checkout: unknown arg '$1'" >&2; exit 2;;
  esac
done
[ -n "$REPO" ] && [ -n "$BRANCH" ] || { echo "usage: sync-checkout.sh --repo DIR --branch NAME [--remote URL] [--dry-run]" >&2; exit 2; }
[ -d "$REPO/.git" ] || { echo "skip: $REPO is not a git checkout" >&2; exit 1; }

G() { git -C "$REPO" "$@"; }
say() { printf '%s\n' "$1"; }

cur="$(G branch --show-current 2>/dev/null || true)"
[ "$cur" = "$BRANCH" ] || { say "skip: checkout is on '${cur:-DETACHED}', not '$BRANCH' — not switching branches under the owner"; exit 1; }

# `status --porcelain` covers unstaged AND staged; both are the owner's, never ours to move
dirty="$(G status --porcelain 2>/dev/null | head -5)"
[ -z "$dirty" ] || { say "skip: uncommitted or staged changes present, leaving them alone:"; printf '%s\n' "$dirty"; exit 1; }

# ssh can be broken on this machine; allow an https remote with the gh credential helper
if [ -n "$REMOTE" ]; then
  G -c credential.helper='!gh auth git-credential' fetch --quiet "$REMOTE" "$BRANCH" 2>/dev/null || { say "skip: fetch from $REMOTE failed"; exit 1; }
else
  G fetch --quiet origin "$BRANCH" 2>/dev/null || { say "skip: fetch from origin failed (try --remote https://…)"; exit 1; }
fi
target="$(G rev-parse --short FETCH_HEAD 2>/dev/null)"
head="$(G rev-parse --short HEAD 2>/dev/null)"
[ -n "$target" ] || { say "skip: could not resolve FETCH_HEAD"; exit 1; }
[ "$head" != "$target" ] || { say "already current at $head"; exit 0; }

# strictly behind == our HEAD is an ancestor of the target; anything else is divergence
G merge-base --is-ancestor HEAD FETCH_HEAD 2>/dev/null || {
  ahead="$(G rev-list --count FETCH_HEAD..HEAD 2>/dev/null || echo '?')"
  say "skip: checkout has DIVERGED ($ahead local commit(s) not on the remote) — owner must resolve"
  exit 1
}

[ "$DRY" -eq 1 ] && { say "would fast-forward $head → $target"; exit 0; }
G merge --ff-only FETCH_HEAD >/dev/null 2>&1 || { say "skip: ff-only merge refused"; exit 1; }
say "synced $head → $(G rev-parse --short HEAD)"
