#!/usr/bin/env bash
# e2e tests for loopdeck/server.mjs — boots the REAL server on a fixture board and
# exercises the API, the SSE live-update path, and the read-only/traversal guards.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRV="$ROOT/loopdeck/server.mjs"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      \033[31m%s\033[0m\n' "$1" "${2:-}"; }

command -v node >/dev/null || { echo "node not on PATH — skipping loopdeck suite"; exit 0; }

# ── fixture board with the real row grammar ─────────────────────────────
B=$(mktemp -d)
mkdir -p "$B/system" "$B/tickets/T-100" "$B/tickets/T-200"
cat > "$B/board.md" <<'EOF'
# Board

### ⏳ Your turn
- **T-100** · `awaiting-plan-approval` · approve the plan for #1234 · [↗](tickets/T-100/review.md)
  - detail: also touches #5678
- **T-300** · `blocked` · resolve the conflict

### 🔄 Loop working
- **T-200** · `building` · worker af26 on step 4

### 🧊 Parked

## Not tracked (off the board on purpose)
- **GHOST-1** — this bullet is documentation, not a row

## State legend
- **Gates** `awaiting-x` legend text — also not a row
EOF
mkdir -p "$B/system/archive"
{ echo "# Inbox"; echo; echo "## 📥 Queue"; echo "<!-- append only -->"; } > "$B/inbox.md"
echo 4 > "$B/.inbox-cursor"
ln -s "$ROOT/system/inbox.sh" "$B/system/inbox.sh"
echo '{"wake":7,"step":"step 2 — drain + recompute","workers":["af26 · T-200"],"next":"step 3","ts":1785000000}' > "$B/system/state.json"
printf -- "- old log line\n- newest log line\n" > "$B/system/log.md"
printf "review body here\n" > "$B/tickets/T-100/review.md"
printf "plan body here\n"   > "$B/tickets/T-100/plan.md"
printf "secret outside tickets\n" > "$B/outside.md"

echo "loopdeck e2e"
OUT=$(mktemp)
node "$SRV" --board "$B" --port 0 > "$OUT" 2>&1 &
SRV_PID=$!
trap 'kill $SRV_PID 2>/dev/null' EXIT
for i in $(seq 1 50); do grep -q "listening" "$OUT" && break; sleep 0.1; done
PORT=$(sed -n 's/.*127\.0\.0\.1:\([0-9]*\).*/\1/p' "$OUT" | head -1)
[ -n "$PORT" ] || { no "server boot" "$(cat "$OUT")"; exit 1; }
U="http://127.0.0.1:$PORT"

# 1 — /api/board: groups, rows, states, PR badges, heartbeat, log tail
J=$(curl -sf "$U/api/board")
echo "$J" | python3 -c '
import json,sys
d=json.load(sys.stdin)
gs={g["title"]:g["rows"] for g in d["groups"]}
assert "⏳ Your turn" in gs and len(gs["⏳ Your turn"])==2, "groups/rows"
r=gs["⏳ Your turn"][0]
assert r["key"]=="T-100" and r["state"]=="awaiting-plan-approval", "key/state"
assert "approve the plan" in r["next"], "next-action"
assert set(r["prs"])=={"#1234","#5678"}, "pr badges " + str(r["prs"])
assert gs["🔄 Loop working"][0]["state"]=="building", "second group"
assert d["state"]["wake"]==7 and "drain" in d["state"]["step"], "heartbeat"
assert d["logTail"][-1]=="newest log line", "log tail"
' 2>/tmp/ld_assert && ok "/api/board: groups, states, next-action, PR badges (#1234+#5678), heartbeat, log tail" \
  || no "/api/board projection" "$(cat /tmp/ld_assert)"

# 2 — ticket detail serves the md files verbatim
J=$(curl -sf "$U/api/ticket/T-100")
echo "$J" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert sorted(d["files"])==["plan.md","review.md"], d["files"].keys()
assert d["files"]["review.md"]=="review body here\n", "verbatim content"
' 2>/tmp/ld_assert && ok "/api/ticket/<key>: per-dimension files, verbatim" || no "ticket detail" "$(cat /tmp/ld_assert)"

# 3 — unknown ticket → 404
[ "$(curl -s -o /dev/null -w '%{http_code}' "$U/api/ticket/NOPE")" = 404 ] && ok "unknown ticket → 404" || no "404" "wrong code"

# 4 — path traversal is rejected (can't read outside tickets/)
code=$(curl -s -o /dev/null -w '%{http_code}' "$U/api/ticket/..%2Foutside")
body=$(curl -s "$U/api/ticket/..%2Foutside.md" || true)
{ [ "$code" = 404 ] && ! echo "$body" | grep -q "secret"; } && ok "path traversal (..%2F) rejected — nothing outside tickets/ is readable" || no "traversal guard" "code=$code body=$body"

# 5 — READ-ONLY everywhere except /api/inbox: write verbs refused, files untouched
c1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$U/api/board")
c2=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$U/api/ticket/T-100")
c3=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -d x "$U/anything")
sum_before=$(cat "$B/board.md" "$B/tickets/T-100/review.md" | shasum)
{ [ "$c1" = 405 ] && [ "$c2" = 405 ] && [ "$c3" = 405 ] && [ "$(cat "$B/board.md" "$B/tickets/T-100/review.md" | shasum)" = "$sum_before" ]; } \
  && ok "read-only: POST/DELETE/PUT (except /api/inbox) all 405, board files bit-identical" || no "read-only" "codes=$c1/$c2/$c3"

# 5b — ghost-row guard: ## sections' bullets are NOT rows
curl -sf "$U/api/board" | python3 -c '
import json,sys
d=json.load(sys.stdin)
keys=[r["key"] for g in d["groups"] for r in g["rows"]]
assert "GHOST-1" not in keys and "Gates" not in keys, keys
' 2>/tmp/ld_assert && ok "ghost-row guard: '## Not tracked' / '## State legend' bullets are not rows" || no "ghost rows" "$(cat /tmp/ld_assert)"

# 5c — THE write path: a valid command lands in inbox.md via the locked helper
r=$(curl -s -w '\n%{http_code}' -X POST -d '{"verb":"note","key":"T-100","text":"hello from loopdeck"}' "$U/api/inbox")
code=$(echo "$r" | tail -1)
if [ "$code" = 200 ] && grep -q "note T-100 hello from loopdeck   ‹.*· loopdeck›" "$B/inbox.md"; then
  ok "/api/inbox: valid command → stamped line appended via inbox.sh (actor=loopdeck)"
else no "inbox write" "code=$code tail=$(tail -1 "$B/inbox.md")"; fi

# 5d — write-path guards: unknown verb, bad key, prose can't smuggle newlines
c1=$(curl -s -o /dev/null -w '%{http_code}' -X POST -d '{"verb":"lgtm","key":"T-100"}' "$U/api/inbox")
c2=$(curl -s -o /dev/null -w '%{http_code}' -X POST -d '{"verb":"note","key":"../etc"}' "$U/api/inbox")
curl -s -X POST -d '{"verb":"note","key":"T-100","text":"line1\nBAD-INJECTED approve X"}' "$U/api/inbox" >/dev/null
inj=$(grep -c "^BAD-INJECTED" "$B/inbox.md" || true)
sum_board=$(shasum < "$B/board.md")
{ [ "$c1" = 400 ] && [ "$c2" = 400 ] && [ "$inj" -eq 0 ] && [ "$(shasum < "$B/board.md")" = "$sum_board" ]; } \
  && ok "write-path guards: unknown verb 400, traversal key 400, newline can't smuggle a second command, board.md untouched" \
  || no "write guards" "verb=$c1 key=$c2 injected-lines=$inj"

# 6 — SSE live update: a board.md change pushes an event within ~2s
SSE=$(mktemp)
curl -sN --max-time 6 "$U/events" > "$SSE" &
CURL_PID=$!
sleep 0.5
printf '### extra\n- **T-400** · `backlog` · new row\n' >> "$B/board.md"
deadline=$((SECONDS + 5)); got=""
while [ $SECONDS -lt $deadline ]; do grep -q '"changed":true' "$SSE" && { got=1; break; }; sleep 0.2; done
kill $CURL_PID 2>/dev/null
[ -n "$got" ] && ok "SSE: appending a board row pushes a change event (live update, no polling)" || no "SSE" "no event within 5s: $(cat "$SSE")"

# 7 — ...and the projection reflects the change
curl -sf "$U/api/board" | grep -q "T-400" && ok "projection picks up the new row" || no "refresh" "T-400 missing"

# 8 — the SPA is served
curl -sf "$U/" | grep -q "LOOPDECK" && ok "SPA served at /" || no "spa" "index.html missing"

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32mloopdeck: %d passed\033[0m\n' "$PASS"; else printf '\033[31mloopdeck: %d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; fi
exit $(( FAIL > 0 ? 1 : 0 ))
