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
  `mkdir` mutex, `--force` escape hatch). Wired as orchestrate step 0 (acquire on
  start / renew each wake / exit-3 = STOP). Tested incl. a 20-way race.
- `system/inbox.sh` — race-free inbox: locked `append` + locked byte-exact `archive`
  (closes the archive/append TOCTOU that destroyed a producer's command). All writers
  delegate to it (the `board` helper, producers, /update-board); orchestrate 5d uses
  `archive`. Tested incl. 40 concurrent appends across 7 archive cycles → 0 lost/duped.
- `system/reaper.sh` — orphaned-worktree audit/cleanup: removes only clean+pushed+old
  worktrees (dry-run by default; dirty/unpushed → `needs-human`, young → untouched).
  Wired into orchestrate step 2. Tested on a scratch origin+worktree world.
- Orchestrate now writes a `system/state.json` heartbeat each wake/step (exact
  "what's running now" for Loopdeck / a watchdog; stale ts + expired lease = dead loop).

## Next
- Loopdeck (`loopdeck/`): local watcher/parser server + read-only SPA per
  `docs/loopdeck-design.md` (answer the two-columns data-model question first).
- Channel-authenticated gate-auth (the remaining prompt-injection full fix).

## Test
```
bash tests/run.sh
```
