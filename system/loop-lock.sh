#!/usr/bin/env bash
# loop-lock.sh — enforce "exactly one execution loop per board" (split-brain guard).
#
# The board's integrity rests on a single writer of board.md. "One loop" was only
# convention; this makes it real. A loop acquires a lease on start and renews it each
# wake; a second loop that tries to start while a FRESH foreign lease exists aborts.
#
# Identity  = session id (the loop's Claude session). Liveness = renewed-within-TTL.
#   We deliberately do NOT use pid liveness: the loop invokes this CLI as a short-lived
#   subprocess each wake, so any recorded pid is ephemeral and would look "dead" moments
#   later. The session that keeps renewing is alive; one that stops is reclaimed at TTL.
#   The owner escape hatch for a crashed loop is `acquire --force` (steal) or `release`.
#
# Portable: no flock (absent on stock macOS). The read-modify-write critical section is
# guarded by an atomic `mkdir` mutex, which is POSIX-atomic everywhere.
#
# Usage:
#   loop-lock.sh acquire  --session ID [--board DIR] [--ttl S] [--force]
#   loop-lock.sh renew    --session ID [--board DIR] [--ttl S]
#   loop-lock.sh release  --session ID [--board DIR]
#   loop-lock.sh check              [--board DIR] [--ttl S]   # 0=free/stale, 3=foreign-fresh
#   loop-lock.sh status             [--board DIR]             # human-readable, always 0
#
# Exit: 0 ok · 2 usage · 3 held by a live foreign loop (acquire/renew lost) · 4 mutex timeout
set -euo pipefail

BOARD_DIR="${BOARD_DIR:-$HOME/planning/boards}"
SESSION="${LOOP_SESSION:-}"
LEASE_TTL="${LEASE_TTL:-2700}"   # 45m — longer than a normal wake gap, so a live loop never self-evicts between wakes
FORCE=0
MUTEX_WAIT_MS=2000

cmd="${1:-}"; shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --session) SESSION="$2"; shift 2;;
    --board)   BOARD_DIR="$2"; shift 2;;
    --ttl)     LEASE_TTL="$2"; shift 2;;
    --force)   FORCE=1; shift;;
    *) echo "loop-lock: unknown arg '$1'" >&2; exit 2;;
  esac
done

LOCK="$BOARD_DIR/system/loop.lock"
MUTEX="$BOARD_DIR/system/.loop-lock.mutex"
now() { date +%s; }
mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || now; }

mutex_acquire() {
  mkdir -p "$BOARD_DIR/system"          # the mutex's parent must exist for the atomic mkdir to work
  local waited=0
  while ! mkdir "$MUTEX" 2>/dev/null; do
    if [ -d "$MUTEX" ] && [ "$(( $(now) - $(mtime "$MUTEX") ))" -gt 10 ]; then
      rm -rf "$MUTEX" 2>/dev/null && continue    # reclaim a mutex orphaned by a crashed holder
    fi
    sleep 0.02; waited=$((waited + 20))
    [ "$waited" -ge "$MUTEX_WAIT_MS" ] && { echo "loop-lock: mutex timeout" >&2; return 4; }
  done
}
mutex_release() { rmdir "$MUTEX" 2>/dev/null || true; }

lf() { [ -f "$LOCK" ] && sed -n "s/^$1=//p" "$LOCK" | head -1 || true; }

write_lock() {  # write_lock <acquired_ts>
  mkdir -p "$BOARD_DIR/system"
  local tmp="$LOCK.tmp.$$"
  { echo "session=$SESSION"; echo "host=$(hostname)"; echo "acquired=$1"; echo "renewed=$(now)"; } > "$tmp"
  mv -f "$tmp" "$LOCK"
}

# none | ours | foreign-live | foreign-stale — identity by session, liveness by TTL only
holder_state() {
  [ -f "$LOCK" ] || { echo none; return; }
  local hsession hrenew
  hsession=$(lf session); hrenew=$(lf renewed)
  { [ -n "$SESSION" ] && [ "$hsession" = "$SESSION" ]; } && { echo ours; return; }
  [ "$(( $(now) - ${hrenew:-0} ))" -ge "$LEASE_TTL" ] && echo foreign-stale || echo foreign-live
}

require_session() { [ -n "$SESSION" ] || { echo "loop-lock: --session (or \$LOOP_SESSION) required for '$cmd'" >&2; exit 2; }; }

case "$cmd" in
  acquire)
    require_session
    mutex_acquire || exit $?
    trap mutex_release EXIT
    case "$(holder_state)" in
      none|foreign-stale) write_lock "$(now)"; echo "acquired ($SESSION)";;
      ours)               write_lock "$(lf acquired)"; echo "re-acquired ($SESSION)";;
      foreign-live)
        if [ "$FORCE" -eq 1 ]; then write_lock "$(now)"; echo "STOLEN from $(lf session) (--force)";
        else echo "loop-lock: held by a live loop (session=$(lf session), renewed $(( $(now) - $(lf renewed) ))s ago) — aborting to avoid split-brain (use --force to steal)" >&2; exit 3; fi;;
    esac
    ;;
  renew)
    require_session
    mutex_acquire || exit $?
    trap mutex_release EXIT
    case "$(holder_state)" in
      ours) write_lock "$(lf acquired)"; echo "renewed";;
      none) write_lock "$(now)"; echo "renewed (re-created — lock was gone)";;
      *)    echo "loop-lock: lease lost — another loop (session=$(lf session)) now holds it; this loop must STOP" >&2; exit 3;;
    esac
    ;;
  release)
    require_session
    mutex_acquire || exit $?
    trap mutex_release EXIT
    if [ "$(holder_state)" = "ours" ]; then rm -f "$LOCK"; echo "released"; else echo "not held by us — no-op"; fi
    ;;
  check)
    [ "$(holder_state)" = "foreign-live" ] && { echo "foreign-live"; exit 3; } || { holder_state; exit 0; }
    ;;
  status)
    if [ -f "$LOCK" ]; then
      cat "$LOCK"; echo "age=$(( $(now) - $(lf renewed) ))s ttl=${LEASE_TTL}s state=$(holder_state)"
    else echo "no lock held (board free)"; fi
    ;;
  *)
    echo "usage: loop-lock.sh {acquire|renew|release|check|status} [--session ID] [--board DIR] [--ttl S] [--force]" >&2
    exit 2;;
esac
