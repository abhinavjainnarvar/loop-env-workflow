#!/usr/bin/env bash
# e2e: the orchestrate step-0 lifecycle against loop-lock.sh — simulates two loops
# driving the exact acquire/renew/release sequence the skill prescribes, on a
# realistic throwaway board (structure mirrored from ~/planning/boards).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCK_SH="$ROOT/system/loop-lock.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      \033[31m%s\033[0m\n' "$1" "${2:-}"; }
L(){ bash "$LOCK_SH" "$@"; }

# a realistic board fixture
B=$(mktemp -d)
mkdir -p "$B/system" "$B/tickets/T-1"
printf '### ⏳ Your turn\n\n### 🔄 Loop working\n\n### 🧊 Parked\n' > "$B/board.md"
printf '## 📥 Queue\n' > "$B/inbox.md"
echo "loop-lock ⇄ orchestrate lifecycle e2e (board: $B)"

# ── the happy path: one loop's whole life ──────────────────────────────
# start
L acquire --session LOOP-A --board "$B" >/dev/null 2>&1 && ok "loop A starts: acquire ok" || no "A acquire" "exit=$?"
# wakes 1..3 renew
r=0; for w in 1 2 3; do L renew --session LOOP-A --board "$B" >/dev/null 2>&1 || r=$?; done
[ "$r" -eq 0 ] && ok "loop A renews across 3 wakes" || no "A renew" "exit=$r"

# ── the split-brain attempt: a cron fires a second loop while A is live ─
if L acquire --session LOOP-B --board "$B" >/dev/null 2>&1; then no "B blocked" "B wrongly started"; else
  [ "$?" -eq 3 ] && ok "loop B (cron duplicate) is blocked at start (exit 3 → per the skill it STOPS)" || no "B rc" "$?"; fi
# ...and A is unaffected on its next wake
L renew --session LOOP-A --board "$B" >/dev/null 2>&1 && ok "loop A keeps renewing after B's failed start" || no "A renew after B" "exit=$?"

# ── A dies silently; TTL expires; B can now start ──────────────────────
# (simulate death = no release; simulate TTL expiry by shrinking ttl for B's attempt)
sleep 2
if L acquire --session LOOP-B --board "$B" --ttl 1 >/dev/null 2>&1; then
  ok "after A goes silent past TTL, loop B starts (stale lease reclaimed)"
else no "B reclaim" "exit=$?"; fi

# ── the evicted loop notices: A's next renew must fail loudly ──────────
if L renew --session LOOP-A --board "$B" >/dev/null 2>&1; then no "A eviction" "A renewed after losing the lease"; else
  [ "$?" -eq 3 ] && ok "zombie loop A's next renew fails (exit 3 → per the skill it STOPS — no dual-writer window persists)" || no "A eviction rc" "$?"; fi

# ── clean shutdown ──────────────────────────────────────────────────────
L release --session LOOP-B --board "$B" >/dev/null 2>&1
[ ! -f "$B/system/loop.lock" ] && ok "loop B's clean shutdown releases the board" || no "release" "lock remains"

# ── board files were never touched by locking ──────────────────────────
grep -q '### 🔄 Loop working' "$B/board.md" && grep -q '## 📥 Queue' "$B/inbox.md" \
  && ok "locking never touches board.md / inbox.md (lock is isolated to system/)" \
  || no "board integrity" "board files changed"

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32morchestrate-lock e2e: %d passed\033[0m\n' "$PASS"; else printf '\033[31morchestrate-lock e2e: %d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; fi
exit $(( FAIL > 0 ? 1 : 0 ))
