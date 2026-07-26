# loop-env-workflow

Versioned home for the **loop-engineering system** — the board-driven orchestration
engine, its hardening, and the Loopdeck dashboard. This repo is the *code*; the live
board **state** stays in `~/planning/boards/` (runtime data, not versioned here).

## Layout
```
skills/      ENGINE — how the loop runs (orchestrate, run-ticket, trace-pair,
             add-ticket, triage, incident, retro). Canonical source; symlinked
             into ~/.claude/skills/ by install.sh.
system/      ENGINE — shell guards run by the loop:
               parse_cmd.sh     deterministic inbox-verb parser (gate-integrity)
               pr_state.sh      PR → gate state
               risk_floors.sh   forced sec-pass / hard-to-undo floors
               loop-lock.sh     single-loop (split-brain) lease  ← new
             Symlinked into ~/planning/boards/system/ by install.sh.
loopdeck/    UI — the local read-only dashboard over the board (design in docs/;
             implementation is a later slice).
docs/        loop-kernel-review.md (the 5-lens verdict), loopdeck-design.md.
tests/       e2e/integration tests. `bash tests/run.sh`.
install.sh   symlink the engine into the live locations (idempotent; --check/--unlink).
```

## Design decisions (settled)
- **Don't build the full event-sourced kernel** — it hardens a failure that's never
  happened (gate-forgery) and inverts the load-bearing *recompute-from-world* truth
  model. Build the light version + fix the real concurrency/integrity holes. See
  `docs/loop-kernel-review.md`.
- **One execution loop per board.** Split by *board* (independent state), never by
  *use-case* — heterogeneous work rides one loop via per-ticket skills + file context.
  `loop-lock.sh` enforces it.

## What's built
- `system/loop-lock.sh` — the single-loop lock (session-identity + TTL lease, atomic
  `mkdir` mutex, `--force` escape hatch). Fully tested incl. a 20-way race.
- Wired into `orchestrate` step 1 (acquire on start, renew each wake, stop if evicted).

## Next
- Inbox TOCTOU fix, worker reaper (the remaining concurrency holes in the review).
- `state.json` emission + the Loopdeck local server/SPA (`loopdeck/`).

## Test
```
bash tests/run.sh
```
