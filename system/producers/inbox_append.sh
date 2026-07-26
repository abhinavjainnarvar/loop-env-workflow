#!/usr/bin/env bash
# Locked append to the board inbox. Producers use this — they NEVER write board.md.
# Delegates to system/inbox.sh (flock) so an append can't race the loop's archive.
set -euo pipefail
INBOX="${BOARD_INBOX:-$HOME/planning/boards/inbox.md}"
"$(dirname "$0")/../inbox.sh" append --inbox "$INBOX" --actor "${RUN_SOURCE:-producer}" "$@" >/dev/null
