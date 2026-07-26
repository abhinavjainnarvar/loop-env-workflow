#!/usr/bin/env bash
# PRODUCER: surface NEWLY-assigned Jira tickets via the INBOX (never writes board.md).
# For each new ticket: write a minimal spec stub (its own folder) + append `ingest <KEY>`.
# The loop drains the inbox, reads the spec, and adds the row (→ awaiting-triage). Dedup: seen-set.
# First run SEEDS the seen-set (surfaces nothing) so the backlog doesn't flood.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APPEND="$HERE/inbox_append.sh"
TIX="$HOME/planning/boards/tickets"
SEEN="$HERE/state/jira_seen.txt"
ME="$(jira me 2>/dev/null)"; [ -z "$ME" ] && { echo "jira me failed (netrc/auth?)"; exit 1; }
touch "$SEEN"
SEED=0; [ ! -s "$SEEN" ] && SEED=1

jira issue list -a"$ME" --plain --no-headers --columns key,status,summary 2>/dev/null \
| while IFS=$'\t' read -r key status summary; do
    key="$(echo "$key" | xargs)"; [ -z "$key" ] && continue
    status="$(echo "$status" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    summary="$(echo "$summary" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    case "$status" in *Deployed*|*Verified*|*Dropped*|*Deprioritis*|*Done*|*Closed*) continue;; esac
    grep -qxF "$key" "$SEEN" && continue
    echo "$key" >> "$SEEN"
    [ "$SEED" -eq 1 ] && continue
    # write a minimal spec stub (ticket's own folder — no contention), then queue an ingest
    if [ ! -f "$TIX/$key/spec.md" ]; then
      mkdir -p "$TIX/$key"
      cat > "$TIX/$key/spec.md" <<SPEC
# $key — $summary

- Jira: https://narvar.atlassian.net/browse/$key  (status=$status)
- Producer-surfaced (jira-assigned) $(TZ=America/Los_Angeles date '+%a %b %-d, %-I:%M %p %Z') — NEEDS TRIAGE.
- Categorization: bucket UNKNOWN · spans=? · the loop/human classifies (framework §3) before any build.
SPEC
    fi
    "$APPEND" "ingest $key"
  done
[ "$SEED" -eq 1 ] && echo "seeded cursor with $(wc -l < "$SEEN" | xargs) current assignments (surfaced 0)"
exit 0
