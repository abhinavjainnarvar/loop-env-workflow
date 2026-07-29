#!/usr/bin/env bash
# install.sh — point the LIVE locations at this repo (repo = single source of truth).
#   ~/.claude/skills/<skill>        -> <repo>/skills/<skill>
#   ~/planning/boards/system/<f>.sh -> <repo>/system/<f>.sh
# Idempotent. A real dir/file at a target is backed up to <target>.pre-repo once.
#   --check    report state, change nothing (exit 1 if anything not linked)
#   --unlink   restore: replace symlinks with copies from the repo
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DST="$HOME/.claude/skills"
SYSTEM_DST="${BOARD_DIR:-$HOME/planning/boards}/system"
SKILLS=(orchestrate run-ticket trace-pair add-ticket triage incident retro update-board voice)
SCRIPTS=(parse_cmd.sh pr_state.sh risk_floors.sh loop-lock.sh inbox.sh reaper.sh)
PRODUCERS=(board_upsert.py inbox_append.sh poll_jira_assigned.sh poll_pr_watch.sh poll_slack_inbox.sh run_producers.sh)
MODE="${1:-install}"
rc=0

link_one() {  # link_one <src> <dst>
  local src="$1" dst="$2"
  case "$MODE" in
    --check)
      if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then echo "  ok      $dst"; else echo "  UNLINKED $dst"; rc=1; fi;;
    --unlink)
      if [ -L "$dst" ]; then rm "$dst"; cp -R "$src" "$dst"; echo "  restored $dst (copy)"; fi;;
    install)
      if [ -L "$dst" ]; then
        [ "$(readlink "$dst")" = "$src" ] && { echo "  ok      $dst"; return; } || rm "$dst"
      elif [ -e "$dst" ]; then
        # back up OUTSIDE the target dir — a `.pre-repo` sibling inside
        # ~/.claude/skills registers as a duplicate skill (observed 2026-07-24)
        local bak="$HOME/.claude/skills-pre-repo-backup"
        mkdir -p "$bak"
        [ -e "$bak/$(basename "$dst")" ] || mv "$dst" "$bak/"   # keep the first backup only
        [ -e "$dst" ] && rm -rf "$dst"
      fi
      ln -s "$src" "$dst"; echo "  linked  $dst -> $src";;
  esac
}

echo "skills:";  mkdir -p "$SKILLS_DST"
for s in "${SKILLS[@]}";  do link_one "$REPO/skills/$s" "$SKILLS_DST/$s"; done
echo "system:";  mkdir -p "$SYSTEM_DST"
for f in "${SCRIPTS[@]}"; do link_one "$REPO/system/$f" "$SYSTEM_DST/$f"; done
echo "producers:";  mkdir -p "$SYSTEM_DST/producers"   # state/ stays live-only (runtime data, never versioned)
for f in "${PRODUCERS[@]}"; do link_one "$REPO/system/producers/$f" "$SYSTEM_DST/producers/$f"; done
echo "board helper:"
link_one "$REPO/board/board" "$(dirname "$SYSTEM_DST")/board"
exit "$rc"
