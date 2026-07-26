# Loopdeck — design (folded from the claude.ai artifact, with reconciliation notes)

Canonical wireframes/visual: claude.ai artifact `6236b8dc-0c3a-4d2e-bc41-c12c34219c44`
("Loopdeck — design & wireframes"). This doc records the architecture + the deltas the
design review requires before implementation.

## The model — reader + producer, never a second writer
- Source of truth stays the board `.md` files; the loop stays the SOLE writer of board.md.
- **Local Node server**: watches the board dir, parses markdown → JSON, pushes diffs over
  a WebSocket. Its ONE write path: append a command to `inbox.md` (same as /update-board).
- **SPA on localhost** (React+Vite): Board + live-loop rail · Ticket detail (dev cycle /
  issues&fixes / plan+diagram / decisions / review) · chat-to-board modal · notifications.
- Worst-case failure mode: a stale render. It can never corrupt board state.

## What feeds what
| Source | Feeds |
|---|---|
| board.md | Kanban columns + cards |
| tickets/K/cycle.md | dev-cycle timeline |
| review/journal/decisions.md | issues & fixes |
| plan/contract.md | plan + Mermaid diagrams |
| brief.md | notifications / "needs you" |
| log.md + **system/state.json** | live loop (wake, step, workers) |

`state.json` is NEW and is an **engine** change: the loop emits `{wake, step, workers[],
next}` each wake/step so "running now" is exact, not log-scraped. It doubles as the
heartbeat the review asked for (a dead loop reads as dead).

## Reconciliation with the design review (MUST apply before building)
1. **No free-prose directive parsing in per-ticket chat** (wireframe 4 shows it).
   Review verdict: explicit verb controls only — the chat modal's verb dropdown
   (wireframe 3) is the pattern; a gate must never be guessed out of a sentence.
   Per-ticket chat = notes/read view + explicit action buttons.
2. **No "journal/decisions distilled from this thread" (LLM distillation).** Journal and
   decisions views render the actual files (typed events / hand-written audit), lossless.
3. **The two-columns question must be answered first**: the wireframe draws SHOPZ-5056 in
   "Needs you" AND "Held" at once. Decide: can one ticket be in two states (e.g. two PRs
   in flight)? Options: (a) one state per ticket, sub-badges for per-PR states;
   (b) card-per-PR grouped by ticket. Blocker for the board view's data model.
4. Notifications aggregate into the brief (digest), not per-event pings (pager fatigue).

## Build order (later slice — after the concurrency hardening)
1. `state.json` emission in orchestrate (engine side, tiny).
2. Server: watcher + parser + JSON API + WS (read-only first — no inbox write).
3. SPA: board view → ticket detail → live rail.
4. Inbox-command modal (the single write path) last, after read-only proves out.
