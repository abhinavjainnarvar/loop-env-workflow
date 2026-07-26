#!/usr/bin/env bash
# e2e/integration tests for system/loop-lock.sh — the single-loop (split-brain) guard.
# Pure bash + real filesystem; each test runs against a throwaway board dir.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCK_SH="$ROOT/system/loop-lock.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      \033[31m%s\033[0m\n' "$1" "${2:-}"; }

L(){ bash "$LOCK_SH" "$@"; }                 # run the cli
newboard(){ mktemp -d 2>/dev/null || mktemp -d -t loop; }
sess_of(){ sed -n 's/^session=//p' "$1/system/loop.lock" 2>/dev/null; }
renew_of(){ sed -n 's/^renewed=//p' "$1/system/loop.lock" 2>/dev/null; }
now(){ date +%s; }
ms(){ python3 -c 'import time;print(int(time.time()*1000))' 2>/dev/null || echo 0; }
# synthetic lock: mklock <board> <session> <pid> <host> <renewed_epoch>
mklock(){ mkdir -p "$1/system"; printf 'session=%s\npid=%s\nhost=%s\nacquired=%s\nrenewed=%s\n' "$2" "$3" "$4" "$5" "$5" > "$1/system/loop.lock"; }

echo "loop-lock.sh e2e"

# 1 — acquire on a free board
b=$(newboard)
if L acquire --session A --board "$b" >/dev/null 2>&1 && [ "$(sess_of "$b")" = A ]; then
  ok "acquire on a free board succeeds and records the session"
else no "acquire on a free board" "exit=$? session=$(sess_of "$b")"; fi

# 2 — re-acquire by the same session is idempotent (a restart of the same loop)
b=$(newboard); L acquire --session A --board "$b" >/dev/null 2>&1
if L acquire --session A --board "$b" >/dev/null 2>&1; then ok "re-acquire by the same session succeeds (idempotent)"; else no "re-acquire same session" "exit=$?"; fi

# 3 — THE split-brain guard: a second loop can't acquire a fresh foreign lease
b=$(newboard); L acquire --session A --board "$b" >/dev/null 2>&1
if L acquire --session B --board "$b" >/dev/null 2>&1; then no "foreign acquire while fresh" "B wrongly acquired; session=$(sess_of "$b")"; else
  rc=$?; { [ "$rc" -eq 3 ] && [ "$(sess_of "$b")" = A ]; } && ok "foreign acquire while lease is fresh is REJECTED (exit 3, holder unchanged)" || no "foreign acquire rc" "rc=$rc session=$(sess_of "$b")"; fi

# 4 — a stale (TTL-expired) lease is reclaimable
b=$(newboard); mklock "$b" OLD 999999 "not-this-host" $(( $(now) - 99999 ))
if L acquire --session B --board "$b" --ttl 60 >/dev/null 2>&1 && [ "$(sess_of "$b")" = B ]; then
  ok "a stale (past-TTL) foreign lease is reclaimed"; else no "stale reclaim" "exit=$? session=$(sess_of "$b")"; fi

# 5 — owner escape hatch: --force steals a live foreign lease (lint-don't-refuse)
b=$(newboard); L acquire --session A --board "$b" >/dev/null 2>&1
if L acquire --session B --board "$b" --force >/dev/null 2>&1 && [ "$(sess_of "$b")" = B ]; then
  ok "--force steals a live foreign lease (owner escape hatch for a crashed loop)"; else no "force steal" "exit=$? session=$(sess_of "$b")"; fi

# 6 — renew by the holder advances renewed_ts and keeps the holder
b=$(newboard); mklock "$b" A "$PPID" "$(hostname)" $(( $(now) - 5 )); before=$(renew_of "$b"); sleep 1
if L renew --session A --board "$b" >/dev/null 2>&1 && [ "$(renew_of "$b")" -gt "$before" ] && [ "$(sess_of "$b")" = A ]; then
  ok "renew by the holder advances the lease timestamp"; else no "renew advances" "before=$before after=$(renew_of "$b")"; fi

# 7 — renew after a foreign takeover fails (loud signal to STOP)
b=$(newboard); mklock "$b" B "$PPID" "$(hostname)" "$(now)"    # B took over
if L renew --session A --board "$b" >/dev/null 2>&1; then no "renew after takeover" "A wrongly renewed"; else
  [ "$?" -eq 3 ] && ok "renew after a foreign takeover FAILS (exit 3 — the evicted loop must stop)" || no "renew takeover rc" "rc=$?"; fi

# 8 — release by the holder clears the lock
b=$(newboard); L acquire --session A --board "$b" >/dev/null 2>&1
if L release --session A --board "$b" >/dev/null 2>&1 && [ ! -f "$b/system/loop.lock" ]; then
  ok "release by the holder removes the lock"; else no "release holder" "lock still present"; fi

# 9 — release by a non-holder is a no-op (can't evict someone else)
b=$(newboard); L acquire --session A --board "$b" >/dev/null 2>&1
L release --session B --board "$b" >/dev/null 2>&1
[ "$(sess_of "$b")" = A ] && ok "release by a non-holder is a no-op (can't evict the real holder)" || no "release non-holder" "session=$(sess_of "$b")"

# 10 — check reports foreign-fresh (3) vs free (0)
b=$(newboard)
L check --board "$b" >/dev/null 2>&1 && free_rc=0 || free_rc=$?
L acquire --session A --board "$b" >/dev/null 2>&1
L check --board "$b" >/dev/null 2>&1 && held_rc=0 || held_rc=$?
{ [ "$free_rc" -eq 0 ] && [ "$held_rc" -eq 3 ]; } && ok "check: free→0, live-foreign→3" || no "check codes" "free=$free_rc held=$held_rc"

# 11 — THE e2e race: 20 loops start at once, exactly ONE wins
b=$(newboard); mkdir -p "$b/system"; : > "$b/results"
for i in $(seq 1 20); do ( L acquire --session "S$i" --board "$b" --ttl 60 >/dev/null 2>&1; echo "$?" >> "$b/results" ) & done
wait
wins=$(grep -c '^0$' "$b/results" 2>/dev/null || echo 0)
{ [ "$wins" -eq 1 ] && [ -n "$(sess_of "$b")" ]; } && ok "RACE: exactly 1 of 20 concurrent acquires wins (split-brain prevented)" || no "race" "winners=$wins (expected exactly 1)"

# 12 — efficiency guard: an acquire must not SPIN. Real op is ~50ms (/usr/bin/time);
# the ceiling is generous only to absorb the python timer's cold-start, while still
# catching a mutex-timeout spin regression (that bug measured ~4800ms).
b=$(newboard); s=$(ms); L acquire --session A --board "$b" >/dev/null 2>&1; e=$(ms); d=$((e - s))
{ [ "$d" -ge 0 ] && [ "$d" -lt 2000 ]; } && ok "acquire does not spin (${d}ms, well under the 2000ms spin-regression ceiling)" || no "acquire spins" "${d}ms — investigate a mutex-timeout regression"

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32mloop-lock: %d passed\033[0m\n' "$PASS"; else printf '\033[31mloop-lock: %d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; fi
exit $(( FAIL > 0 ? 1 : 0 ))
