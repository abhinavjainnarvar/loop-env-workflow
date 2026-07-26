#!/usr/bin/env bash
# Run all board producers once. Suitable for system cron / launchd every N minutes.
# ZERO Claude tokens — pure detection; writes the board, the board-Monitor wakes the consumer.
set -uo pipefail
# cron/launchd run with a minimal env — pin PATH + HOME so gh/jira/python3/jq resolve
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export HOME="${HOME:-/Users/abhinavjain}"
# who/what ran this: explicit RUN_SOURCE (e.g. set by the launchd plist) wins, else detect
USER_NOW="$(id -un 2>/dev/null)"
PPCMD="$(ps -o comm= -p "$PPID" 2>/dev/null | sed 's#.*/##')"
if [ -z "${RUN_SOURCE:-}" ]; then
  if [ -n "${XPC_SERVICE_NAME:-}" ] && printf '%s' "${XPC_SERVICE_NAME}" | grep -q board-producers; then RUN_SOURCE=launchd
  elif tty -s 2>/dev/null; then RUN_SOURCE=manual
  else RUN_SOURCE=background; fi
fi
export RUN_SOURCE
HERE="$(cd "$(dirname "$0")" && pwd)"; LOG="$HERE/state/producers.log"
{
  echo "=== $(TZ=America/Los_Angeles date '+%a %b %-d, %-I:%M %p %Z') run_producers · by: $RUN_SOURCE (user=$USER_NOW, ppid=$PPCMD) ==="
  "$HERE/poll_jira_assigned.sh" || echo "jira poller exit=$?"
  "$HERE/poll_pr_watch.sh"       || echo "pr poller exit=$?"
  if [ -n "${SLACK_BOT_TOKEN:-}" ] && [ -n "${SLACK_CHANNEL_ID:-}" ]; then
    "$HERE/poll_slack_inbox.sh"  || echo "slack poller exit=$?"
  else
    echo "slack: skipped (SLACK_BOT_TOKEN / SLACK_CHANNEL_ID not set)"
  fi
} >> "$LOG" 2>&1
