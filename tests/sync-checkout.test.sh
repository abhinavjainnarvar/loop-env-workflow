#!/usr/bin/env bash
# Tests for system/sync-checkout.sh — the loop closing the "your checkout is N behind" gap.
# Every refusal case matters more than the happy path: this thing runs against the owner's
# live working tree, so a wrong "fix" costs him real work.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SC="$ROOT/system/sync-checkout.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      \033[31m%s\033[0m\n' "$1" "${2:-}"; }

# scratch world: bare origin + a "owner" clone, one commit ahead on origin
mk() {
  W=$(mktemp -d); W=$(cd "$W" && pwd -P)
  git init -q --bare "$W/origin.git"
  git -C "$W" -c init.defaultBranch=main clone -q "$W/origin.git" own 2>/dev/null
  O="$W/own"
  git -C "$O" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
  git -C "$O" push -q origin main 2>/dev/null
  # a second clone stands in for the worker's detached worktree, pushing a new commit
  git -C "$W" clone -q "$W/origin.git" wk 2>/dev/null
  git -C "$W/wk" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "worker push"
  git -C "$W/wk" push -q origin main 2>/dev/null
  echo "$W"
}
head_of(){ git -C "$1" rev-parse --short HEAD; }

echo "sync-checkout.sh"

# 1 — happy path: on branch, clean, behind → fast-forwards
W=$(mk); O="$W/own"; before=$(head_of "$O")
out=$(bash "$SC" --repo "$O" --branch main 2>&1)
{ echo "$out" | grep -q "^synced" && [ "$(head_of "$O")" != "$before" ]; } \
  && ok "clean + behind → fast-forwards" || no "happy path" "$out"

# 2 — idempotent: running again reports already current, exit 0
out=$(bash "$SC" --repo "$O" --branch main 2>&1); rc=$?
{ [ "$rc" -eq 0 ] && echo "$out" | grep -q "already current"; } && ok "already current → exit 0, no-op" || no "idempotent" "rc=$rc $out"

# 3 — REFUSES when the tree is dirty (the owner's uncommitted work)
W=$(mk); O="$W/own"; echo "wip" > "$O/scratch.txt"; before=$(head_of "$O")
out=$(bash "$SC" --repo "$O" --branch main 2>&1); rc=$?
{ [ "$rc" -eq 1 ] && [ "$(head_of "$O")" = "$before" ] && echo "$out" | grep -q "uncommitted or staged"; } \
  && ok "dirty tree → refuses, HEAD untouched" || no "dirty refusal" "rc=$rc $out"

# 4 — REFUSES on a STAGED-only change (the exact shape of the two real incidents)
W=$(mk); O="$W/own"; echo "staged" > "$O/s.txt"; git -C "$O" add s.txt; before=$(head_of "$O")
out=$(bash "$SC" --repo "$O" --branch main 2>&1); rc=$?
{ [ "$rc" -eq 1 ] && [ "$(head_of "$O")" = "$before" ]; } \
  && ok "staged-only change → refuses (the real-incident shape)" || no "staged refusal" "rc=$rc $out"

# 5 — REFUSES when the checkout is on a different branch (never switches under the owner)
W=$(mk); O="$W/own"; git -C "$O" checkout -q -b sidework; before=$(head_of "$O")
out=$(bash "$SC" --repo "$O" --branch main 2>&1); rc=$?
{ [ "$rc" -eq 1 ] && [ "$(git -C "$O" branch --show-current)" = "sidework" ] && echo "$out" | grep -q "not switching branches"; } \
  && ok "on another branch → refuses, stays put" || no "branch refusal" "rc=$rc $out"

# 6 — REFUSES when diverged (local commit not on the remote) — never rebases/resets
W=$(mk); O="$W/own"
git -C "$O" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "owner local work"
before=$(head_of "$O")
out=$(bash "$SC" --repo "$O" --branch main 2>&1); rc=$?
{ [ "$rc" -eq 1 ] && [ "$(head_of "$O")" = "$before" ] && echo "$out" | grep -q "DIVERGED"; } \
  && ok "diverged → refuses, local commit preserved" || no "divergence refusal" "rc=$rc $out"

# 7 — --dry-run reports the move without making it
W=$(mk); O="$W/own"; before=$(head_of "$O")
out=$(bash "$SC" --repo "$O" --branch main --dry-run 2>&1)
{ echo "$out" | grep -q "would fast-forward" && [ "$(head_of "$O")" = "$before" ]; } \
  && ok "--dry-run reports without moving" || no "dry run" "$out"

# 8 — a non-repo path is refused, not crashed on
out=$(bash "$SC" --repo "$(mktemp -d)" --branch main 2>&1); rc=$?
{ [ "$rc" -eq 1 ] && echo "$out" | grep -q "not a git checkout"; } && ok "non-repo path → clean refusal" || no "non-repo" "rc=$rc $out"

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32msync-checkout: %d passed\033[0m\n' "$PASS"; else printf '\033[31msync-checkout: %d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; fi
exit $(( FAIL > 0 ? 1 : 0 ))
