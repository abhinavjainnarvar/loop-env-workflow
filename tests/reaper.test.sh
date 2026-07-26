#!/usr/bin/env bash
# e2e tests for system/reaper.sh — orphaned-worktree cleanup on a real scratch git setup
# (bare origin + clone + worktrees in every state the policy distinguishes).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RP="$ROOT/system/reaper.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      \033[31m%s\033[0m\n' "$1" "${2:-}"; }

# ── scratch world: bare origin, main checkout, 4 worktrees ──────────────
W=$(mktemp -d); W=$(cd "$W" && pwd -P)   # resolve /var → /private/var (git reports physical paths)
git init -q --bare "$W/origin.git"
git -C "$W" -c init.defaultBranch=main clone -q "$W/origin.git" repo 2>/dev/null
R="$W/repo"
git -C "$R" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$R" push -q origin main 2>/dev/null

mkwt(){ # mkwt <name> → creates worktree on branch wt-<name>, pushes base commit
  git -C "$R" worktree add -q -b "wt-$1" "$W/wt-$1" main 2>/dev/null
  git -C "$W/wt-$1" push -q -u origin "wt-$1" 2>/dev/null
}
age(){ touch -t 202601010000 "$1"; }   # backdate a worktree well past min-age

mkwt clean;   age "$W/wt-clean"                                            # clean + pushed + old  → remove
mkwt dirty;   echo x > "$W/wt-dirty/junk.txt"; age "$W/wt-dirty"           # dirty (dirty FIRST, then backdate — the write bumps mtime) → keep
mkwt ahead
git -C "$W/wt-ahead" -c user.email=t@t -c user.name=t commit -q --allow-empty -m wip  # unpushed → keep
age "$W/wt-ahead"
mkwt young                                                                  # fresh (now)          → too-young
mkwt gone;    rm -rf "$W/wt-gone"                                           # dir deleted          → prunable entry

echo "reaper.sh e2e"
REPORT=$(bash "$RP" --repo "$R" 2>&1)   # dry run

# 1 — dry-run verdicts are exactly right, one per worktree
echo "$REPORT" | grep -q "would-remove|$W/wt-clean|wt-clean"  && ok "clean+pushed+old → would-remove" || no "clean verdict" "$REPORT"
echo "$REPORT" | grep -q "needs-human|$W/wt-dirty|wt-dirty|uncommitted"  && ok "dirty → needs-human (never auto-removed)" || no "dirty verdict" "$REPORT"
echo "$REPORT" | grep -q "needs-human|$W/wt-ahead|wt-ahead|unpushed"     && ok "unpushed commits → needs-human (never auto-removed)" || no "ahead verdict" "$REPORT"
echo "$REPORT" | grep -q "too-young|$W/wt-young|wt-young"                && ok "fresh worktree → too-young (a live worker is safe)" || no "young verdict" "$REPORT"
echo "$REPORT" | grep -q "pruned-entries"                                && ok "deleted-dir worktree → stale admin entry reported" || no "prunable" "$REPORT"

# 2 — dry run touched nothing
{ [ -d "$W/wt-clean" ] && [ -d "$W/wt-dirty" ]; } && ok "dry run removes nothing" || no "dry run side-effects" "a worktree vanished"

# 3 — apply: removes ONLY the safe one; keeps dirty/ahead/young; prunes the stale entry
bash "$RP" --repo "$R" --apply >/dev/null 2>&1
v_clean=$([ -d "$W/wt-clean" ] && echo present || echo gone)
v_dirty=$([ -d "$W/wt-dirty" ] && echo present || echo gone)
v_ahead=$([ -d "$W/wt-ahead" ] && echo present || echo gone)
v_young=$([ -d "$W/wt-young" ] && echo present || echo gone)
[ "$v_clean" = gone ]    && ok "--apply removes the clean+pushed orphan" || no "apply clean" "wt-clean $v_clean"
[ "$v_dirty" = present ] && ok "--apply preserves the dirty worktree"    || no "apply dirty" "wt-dirty $v_dirty"
[ "$v_ahead" = present ] && ok "--apply preserves unpushed work"          || no "apply ahead" "wt-ahead $v_ahead"
[ "$v_young" = present ] && ok "--apply preserves the young (live) worktree" || no "apply young" "wt-young $v_young"
git -C "$R" worktree list | grep -q "wt-gone" && no "prune" "stale entry survived" || ok "--apply prunes the deleted-dir admin entry"

# 4 — the branch survives the worktree removal (nothing lost)
git -C "$R" rev-parse --verify -q origin/wt-clean >/dev/null && ok "removed worktree's branch still on origin (nothing lost)" || no "branch survival" "origin/wt-clean missing"

# 5 — re-dispatch works: the collision the reaper exists to fix is gone
if git -C "$R" worktree add -q "$W/wt-clean" wt-clean 2>/dev/null; then
  ok "ticket re-dispatch can recreate the same worktree path (collision cleared)"
else no "re-dispatch" "worktree add failed"; fi

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32mreaper: %d passed\033[0m\n' "$PASS"; else printf '\033[31mreaper: %d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; fi
exit $(( FAIL > 0 ? 1 : 0 ))
