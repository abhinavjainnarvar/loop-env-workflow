#!/usr/bin/env bash
# e2e tests for system/inbox.sh — the append/archive TOCTOU fix.
# The core promise under test: NO INBOX MESSAGE IS EVER LOST OR DUPLICATED,
# even when producers append concurrently with the loop's archive.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IB="$ROOT/system/inbox.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      \033[31m%s\033[0m\n' "$1" "${2:-}"; }

mkboard(){  # fresh board dir with a realistic inbox header; echoes the dir
  local d; d=$(mktemp -d)
  mkdir -p "$d/system/archive"
  { echo "# Inbox"; echo; echo "## 📥 Queue"; echo "<!-- append only -->"; } > "$d/inbox.md"
  echo 4 > "$d/.inbox-cursor"     # header is 4 lines
  echo "$d"
}
I(){ bash "$IB" "$@"; }   # run the cli
queue_lines(){ tail -n +5 "$1/inbox.md"; }

echo "inbox.sh e2e"

# 1 — append lands with the ‹ts · actor› stamp
d=$(mkboard)
I append --inbox "$d/inbox.md" --actor tester "approve K-1" >/dev/null 2>&1
if queue_lines "$d" | grep -q "approve K-1   ‹.*· tester›"; then ok "append writes the stamped command line"; else no "append format" "$(queue_lines "$d")"; fi

# 2 — archive moves consumed lines, keeps unprocessed tail, resets cursor
d=$(mkboard)
for k in 1 2 3 4 5; do I append --inbox "$d/inbox.md" --actor t "note K-$k x" >/dev/null 2>&1; done
echo 7 > "$d/.inbox-cursor"      # loop processed through line 7 = first 3 queue lines
out=$(I archive --inbox "$d/inbox.md" 2>&1)
a=$(grep -c "note K-" "$d/system/archive/inbox-archive.md" 2>/dev/null); k=$(queue_lines "$d" | grep -c "note K-")
c=$(cat "$d/.inbox-cursor")
if [ "$a" = 3 ] && [ "$k" = 2 ] && [ "$c" = 4 ] && queue_lines "$d" | head -1 | grep -q "K-4"; then
  ok "archive: consumed→archive (3), unprocessed tail kept in order (2), cursor reset to header"
else no "archive split" "out=$out archived=$a kept=$k cursor=$c"; fi

# 3 — idempotent: archiving with nothing consumed is a no-op
before=$(cat "$d/inbox.md")
I archive --inbox "$d/inbox.md" >/dev/null 2>&1
[ "$before" = "$(cat "$d/inbox.md")" ] && ok "archive with nothing consumed is a no-op" || no "no-op archive" "inbox changed"

# 4 — malformed inbox (no queue marker) → refuse, exit 2, file untouched
d=$(mktemp -d); mkdir -p "$d/system/archive"; echo "just prose" > "$d/inbox.md"; echo 1 > "$d/.inbox-cursor"
if I archive --inbox "$d/inbox.md" >/dev/null 2>&1; then no "malformed refusal" "archived a marker-less file"; else
  { [ "$?" -eq 2 ] && [ "$(cat "$d/inbox.md")" = "just prose" ]; } && ok "marker-less inbox: refused (exit 2), file untouched" || no "malformed rc" "$?"; fi

# 5 — THE TOCTOU RACE: 40 producers append WHILE the consumer archives in a loop.
#     Invariant: every message ends up in archive or inbox — exactly once.
d=$(mkboard)
N=40
( for i in $(seq 1 $N); do I append --inbox "$d/inbox.md" --actor "p$i" "note R-$i msg" >/dev/null 2>&1 & done; wait ) &
producers=$!
for round in 1 2 3 4 5 6; do
  # simulate the loop: read everything, mark it processed, then archive
  wc -l < "$d/inbox.md" | tr -d ' ' > "$d/.inbox-cursor"
  I archive --inbox "$d/inbox.md" >/dev/null 2>&1
  sleep 0.05
done
wait "$producers" 2>/dev/null
wc -l < "$d/inbox.md" | tr -d ' ' > "$d/.inbox-cursor"; I archive --inbox "$d/inbox.md" >/dev/null 2>&1
total=0; miss=""
for i in $(seq 1 $N); do
  c=$(grep -ch "note R-$i msg" "$d/system/archive/inbox-archive.md" 2>/dev/null || echo 0)
  c2=$(queue_lines "$d" | grep -c "note R-$i msg" || true)
  n=$((c + c2)); total=$((total + n))
  [ "$n" -ne 1 ] && miss="$miss R-$i=$n"
done
if [ "$total" -eq "$N" ] && [ -z "$miss" ]; then
  ok "TOCTOU RACE: $N concurrent appends across 7 archive cycles — every message exactly once (0 lost, 0 duplicated)"
else no "TOCTOU race" "total=$total/$N anomalies:$miss"; fi

# 6 — concurrent appends alone never interleave mid-line
d=$(mkboard)
( for i in $(seq 1 30); do I append --inbox "$d/inbox.md" --actor a "note C-$i aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" >/dev/null 2>&1 & done; wait )
badlines=$(queue_lines "$d" | grep -vc '^note C-[0-9]* a*   ‹.*›$' || true)
count=$(queue_lines "$d" | grep -c "note C-")
{ [ "$badlines" -eq 0 ] && [ "$count" -eq 30 ]; } && ok "30 parallel appends: all whole lines, none torn/interleaved" || no "append integrity" "count=$count torn=$badlines"

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32minbox: %d passed\033[0m\n' "$PASS"; else printf '\033[31minbox: %d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; fi
exit $(( FAIL > 0 ? 1 : 0 ))
