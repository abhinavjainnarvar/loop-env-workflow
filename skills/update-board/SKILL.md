---
name: update-board
description: Move a ticket on the Narvar board — approve / reject / hold / resume / retry / reprioritize / drop / ask / ingest / recompute / note — by queuing a command to the board inbox (the orchestrate loop then applies it). Use when the user types `/update-board <verb> <KEY> [text]` or asks to approve/reject/hold/etc a board ticket without a terminal. APPEND-ONLY to the inbox; you never edit board.md directly (the loop is its sole writer). The loop drains it; if no loop is running it queues durably.
---

# update-board — move a ticket by queuing a command (producer channel)

`/update-board <verb> <KEY> [text]` is how a human moves work on the board. Important:
you do **not** edit `board.md` — you **append one command to the inbox**, and the
`orchestrate` loop (the board's *sole writer*) applies it. The name is the **outcome**
("the board moves"); the **mechanism** is the append-only inbox, which is what keeps the
board single-writer and race-free.

## Vocabulary (one verb per invocation)
`approve` · `reject` · `changes` · `hold` · `resume` · `retry` · `priority` · `drop` ·
`ask` · `ingest` · `recompute` · `note` — e.g.:
- `/update-board approve 5056`
- `/update-board reject 5056 redesign Phase 2: split uploads out`
- `/update-board hold 5135 waiting on design`
- `/update-board recompute narvar/denali#2795`

## Do
1. Resolve the inbox: **`~/planning/boards/inbox.md`** (the single Narvar board; absolute
   path — you may be invoked from any repo's session). If another board is named, use its inbox.
2. **Append exactly one line, atomically** (never edit existing lines, never touch
   `board.md`). Use the shell helper if present, else the locked appender directly:
   ```
   ~/planning/boards/board <verb> <KEY> [text]
   # or, equivalently:
   ~/planning/boards/system/inbox.sh append "<verb> <KEY> [text]"
   ```
   (Both take the inbox flock, so an append can never race the loop's archive —
   never use a raw `>>`, which the archive could destroy mid-window.)
3. **Confirm** the queued line back to the user.
4. **Do NOT** run the loop, drain the inbox, or edit `board.md` — that's the consumer's job.

## Notes
- **Append-only + exactly-once:** any number of sessions can queue at once; the loop's
  cursor processes each line once, even mid-job.
- **Loop running** → its inbox Monitor wakes it and it acts shortly. **Not running** → the
  command **queues durably** and is applied next time a loop runs (tell the user which).
- Garbled/unknown verbs are safe to append — the loop's deterministic parser flags them and
  DMs the owner a clarifying question (it never guesses a gate).
- Sibling producer channels (same inbox): the shell helper `board`, a raw `echo >>`,
  `add-ticket` (new tickets), and the cron sensors.
