#!/usr/bin/env bash
# PRODUCER: surface Slack messages that may need a response as awaiting-triage rows.
# Requires env: SLACK_BOT_TOKEN (rule-6 secret), SLACK_CHANNEL_ID. Optional: SLACK_MY_UID (default U0380FT09SS).
# Mechanical detection only (@-mention me OR a question mark); the loop/human decides respond-vs-ignore.
# Dedup: slack_seen.txt (message ts). Cursor: slack_cursor.txt (newest ts seen).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; APPEND="$HERE/inbox_append.sh"
ST="$HERE/state"; SEEN="$ST/slack_seen.txt"; CUR="$ST/slack_cursor.txt"; mkdir -p "$ST"; touch "$SEEN"
: "${SLACK_BOT_TOKEN:?set SLACK_BOT_TOKEN}"; : "${SLACK_CHANNEL_ID:?set SLACK_CHANNEL_ID}"
MY_UID="${SLACK_MY_UID:-U0380FT09SS}"; BOARD="${BOARD:-$HOME/planning/boards/board.md}"
oldest=$(cat "$CUR" 2>/dev/null || echo 0)
resp=$(curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  "https://slack.com/api/conversations.history?channel=$SLACK_CHANNEL_ID&oldest=$oldest&limit=50")
echo "$resp" | jq -e '.ok' >/dev/null 2>&1 || { echo "slack api error: $(echo "$resp" | jq -r '.error // "unknown"')"; exit 1; }
newest=$(echo "$resp" | jq -r '[.messages[].ts] | max // empty')
echo "$resp" | jq -r --arg me "$MY_UID" '
  .messages[] | select(.subtype == null)
  | select((.text|contains("<@"+$me+">")) or (.text|test("\\?")))
  | [.ts, (.text|gsub("\n";" ")|.[0:80]), (.user//"?")] | @tsv' \
| while IFS=$'\t' read -r ts text user; do
    grep -qxF "$ts" "$SEEN" && continue
    echo "$ts" >> "$SEEN"
    "$APPEND" "ingest SLACK-$(echo "$ts" | tr -d .)"
      "Slack ts=$ts user=$user channel=$SLACK_CHANNEL_ID · _producer:slack-inbox via ${RUN_SOURCE:-cli} $(TZ=America/Los_Angeles date '+%a %b %-d, %-I:%M %p %Z')_ · loop: respond or ignore"
  done
[ -n "$newest" ] && echo "$newest" > "$CUR"
exit 0
