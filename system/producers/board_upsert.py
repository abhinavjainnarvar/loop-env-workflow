#!/usr/bin/env python3
"""Idempotent find-or-insert of a board row (header + labeled-detail format), keyed by KEY.
Usage: board_upsert.py KEY "TITLE" STATE "NOTES"
- If a row for KEY already exists: SKIP (the loop owns its state; producers never overwrite it).
- Else: insert a new ticket block under '### ⏳ Your turn' (an ingested item awaits owner
  triage / bucket-confirm). TITLE now shows on the identity line; NOTES becomes the detail line.
Block format:
    - **KEY** · `state` · TITLE · [↗](tickets/KEY/review.md)
      - NOTES
The loop relabels the detail (→ you: / ⏳ loop: / ⚠) when it triages. Deep detail → review.md.
Env: BOARD (default ~/planning/boards/board.md)."""
import sys, re, os
BOARD = os.environ.get("BOARD", os.path.expanduser("~/planning/boards/board.md"))
key, title, state, notes = (sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
s = open(BOARD).read()
if re.search(rf"^- \*\*{re.escape(key)}\*\* ", s, re.M):
    print(f"skip (exists): {key}"); sys.exit(0)
block = (
    f"- **{key}** · `{state}` · {title} · [↗](tickets/{key}/review.md)\n"
    f"  - {notes}\n\n"
)
lines = s.splitlines(keepends=True)
for i, l in enumerate(lines):
    if l.strip().startswith("### ") and "Your turn" in l:
        # insert after the header AND its following blank line (keeps block spacing)
        j = i + 2 if i + 1 < len(lines) and lines[i + 1].strip() == "" else i + 1
        lines.insert(j, block)
        break
else:
    sys.stderr.write("ERROR: no '### ⏳ Your turn' group found in board\n"); sys.exit(1)
open(BOARD, "w").write("".join(lines))
print(f"added under Your turn: {key} ({state})")
