#!/usr/bin/env bash
# inbox.sh — race-free inbox operations (closes the archive/append TOCTOU).
#
# The bug this kills: orchestrate step 5d used to snapshot the inbox, then truncate it.
# A producer appending in the gap between the read and the truncate had its command
# DESTROYED — breaking the board's core "no message is ever missed" promise (a real
# instance was logged 2026-06-18). Fix per the design review: one exclusive lock held
# across BOTH append and archive, and the archive rewrites only what it actually read.
#
# Locking: POSIX fcntl.flock via python3 (macOS ships no flock(1) binary) on a sidecar
# `<inbox>.lck`. Every writer — the `board` helper, producers' inbox_append.sh, and the
# loop's archive — goes through here, so append/archive serialize and nothing interleaves.
#
# Verbs:
#   inbox.sh append [--inbox FILE] [--actor NAME] <line...>
#       Locked append of one command line, stamped `‹<Pacific ts> · <actor>›`
#       (actor defaults to $RUN_SOURCE or `id -un`, matching the old helpers).
#   inbox.sh archive [--inbox FILE] [--cursor FILE] [--archive FILE]
#       Locked drain-to-archive: moves queue lines AT OR BELOW the cursor into the
#       archive (dated section), keeps unprocessed lines (past the cursor) in place,
#       rewrites the inbox to header+tail atomically, and resets the cursor to the
#       new header length. Lines appended after the loop's last read are BY
#       DEFINITION past the cursor → kept. Nothing can be lost.
#       Prints `archived=N kept=M cursor=K`.
#
# Exit: 0 ok · 2 usage / inbox malformed (no queue marker)
set -euo pipefail

INBOX="${BOARD_INBOX:-$HOME/planning/boards/inbox.md}"
CURSOR=""
ARCHIVE=""
ACTOR="${RUN_SOURCE:-$(id -un)}"
cmd="${1:-}"; shift || true
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --inbox)   INBOX="$2"; shift 2;;
    --cursor)  CURSOR="$2"; shift 2;;
    --archive) ARCHIVE="$2"; shift 2;;
    --actor)   ACTOR="$2"; shift 2;;
    *) ARGS+=("$1"); shift;;
  esac
done
[ -n "$CURSOR" ]  || CURSOR="$(dirname "$INBOX")/.inbox-cursor"
[ -n "$ARCHIVE" ] || ARCHIVE="$(dirname "$INBOX")/system/archive/inbox-archive.md"

case "$cmd" in
  append)
    [ ${#ARGS[@]} -ge 1 ] || { echo "usage: inbox.sh append <line...>" >&2; exit 2; }
    LINE="${ARGS[*]}" STAMP="$(TZ=America/Los_Angeles date '+%a %b %-d, %-I:%M %p %Z')" \
    INBOX="$INBOX" ACTOR="$ACTOR" python3 - <<'PY'
import fcntl, os
inbox = os.environ["INBOX"]
line  = f'{os.environ["LINE"]}   ‹{os.environ["STAMP"]} · {os.environ["ACTOR"]}›\n'
os.makedirs(os.path.dirname(inbox) or ".", exist_ok=True)
with open(inbox + ".lck", "w") as lk:
    fcntl.flock(lk, fcntl.LOCK_EX)
    with open(inbox, "a", encoding="utf-8") as f:
        f.write(line); f.flush(); os.fsync(f.fileno())
print("queued")
PY
    ;;
  archive)
    INBOX="$INBOX" CURSOR="$CURSOR" ARCHIVE="$ARCHIVE" \
    STAMP="$(TZ=America/Los_Angeles date '+%a %b %-d, %-I:%M %p %Z')" python3 - <<'PY'
import fcntl, os, sys, tempfile
inbox, cursorf, archive = os.environ["INBOX"], os.environ["CURSOR"], os.environ["ARCHIVE"]
stamp = os.environ["STAMP"]
with open(inbox + ".lck", "w") as lk:
    fcntl.flock(lk, fcntl.LOCK_EX)          # excludes every append for the whole rewrite
    lines = open(inbox, encoding="utf-8").readlines()
    # header = through the queue marker, plus its explanatory comment if present
    hdr_end = None
    for i, l in enumerate(lines):
        if "Queue" in l and l.lstrip().startswith("##"):
            hdr_end = i + 1
            if hdr_end < len(lines) and lines[hdr_end].lstrip().startswith("<!--"):
                while hdr_end < len(lines):
                    hdr_end += 1
                    if "-->" in lines[hdr_end - 1]: break
            break
    if hdr_end is None:
        print("inbox.sh: no queue marker found — refusing to archive", file=sys.stderr); sys.exit(2)
    try:    cursor = int(open(cursorf).read().strip() or 0)
    except FileNotFoundError: cursor = hdr_end
    cursor = max(cursor, hdr_end)           # never treat header lines as queue
    consumed = lines[hdr_end:cursor]        # processed queue lines (≤ cursor)
    kept     = lines[cursor:]               # unprocessed — INCLUDING any append that
                                            # landed after the loop's read (always > cursor)
    if consumed:
        os.makedirs(os.path.dirname(archive), exist_ok=True)
        with open(archive, "a", encoding="utf-8") as a:
            a.write(f"\n## Archived {stamp}\n"); a.writelines(consumed)
    # atomic rewrite: header + kept tail, then cursor, while still holding the lock
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(inbox) or ".")
    with os.fdopen(fd, "w", encoding="utf-8") as t:
        t.writelines(lines[:hdr_end]); t.writelines(kept); t.flush(); os.fsync(t.fileno())
    os.replace(tmp, inbox)
    with open(cursorf, "w") as c:
        c.write(str(hdr_end))
    print(f"archived={len(consumed)} kept={len(kept)} cursor={hdr_end}")
PY
    ;;
  *)
    echo "usage: inbox.sh {append <line...>|archive} [--inbox F] [--cursor F] [--archive F] [--actor N]" >&2
    exit 2;;
esac
