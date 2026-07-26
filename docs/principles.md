# Loop principles — the settled rules this system is built on

One page, so nothing has to be re-derived or re-litigated. Each principle names its
enforcement (a script, a skill rule, or a test) — a principle without enforcement is
just a wish. Provenance: the 5-lens design review (`loop-kernel-review.md`), the
owner decisions in the board's `tickets/loop-kernel/decisions.md`, and the retro
backlog (`<board>/system/loop-improvements.md`).

## Truth & state
1. **Truth = recompute-from-world.** GitHub/Jira/CI are the source of truth; board
   state is a recomputed cache, never trusted blindly. This is why the full
   event-sourced kernel was rejected — an event log becomes confidently wrong the
   moment the world changes without an event. *(Enforced: orchestrate step 2;
   verify-before-integrate.)*
2. **The board has exactly one writer** — the loop. Everything else (humans,
   producers, Loopdeck) only appends commands to the inbox. *(Enforced: skill rules;
   Loopdeck has no write endpoint beyond `/api/inbox`; tests prove board.md
   bit-identical.)*
3. **No inbox message is ever lost or duplicated.** Append-only queue + cursor =
   exactly-once; append and archive serialize under one flock, and archive keeps
   everything past the cursor by construction. *(Enforced: `system/inbox.sh`; the
   40-appender × 7-archive race test.)*
4. **Liveness is explicit, not inferred**: `system/state.json` heartbeat each
   wake/step + the lease's renewed-ts. Stale heartbeat + expired lease = dead loop.
   *(Enforced: orchestrate step 1; Loopdeck renders it.)*

## Topology
5. **One execution loop per board; split by BOARD, never by use-case.**
   Heterogeneous work rides one loop via per-ticket skills + per-ticket file
   context; the loop is a thin dispatcher holding no deep in-head context (that's
   what survives restarts/compaction). New use-case = new skill + ticket type, not a
   new loop. *(Enforced: `system/loop-lock.sh` — session lease, TTL, exit-3 = STOP;
   the 20-way race test; orchestrate step 0.)*
6. **Producers many, consumer one.** Any number of sensors/humans/sessions may
   surface work (append `ingest`); only the loop executes. Producer-surfaced rows go
   through triage + a human bucket-confirmation before any build.

## Gates & security
7. **A gate clears only on human evidence, never an agent's line.** Agents may set
   `awaiting-*` states and yield — never flip a gate, write an approval, or resolve
   a review thread. *(Enforced: run-ticket + orchestrate rules.)*
8. **Gate verbs are parsed deterministically, never guessed from prose** — a
   misread `note` must never become an `approve`. Applies everywhere: the inbox
   (`parse_cmd.sh`), Loopdeck's modal (explicit verb dropdown; server-side verb
   whitelist; newline-stripping so one request = one command). *(Enforced: parse_cmd
   tests; loopdeck write-guard tests.)*
9. **Workers never write the inbox or emit a gate verb** (prompt-injection
   surface: they read untrusted PR/Jira/web content). The loop drops agent-origin
   gate verbs. *Remaining full fix (OPEN): channel-authenticated gate-auth —
   approvals proven by a channel only the human can post to, not by `id -un`.*
10. **Provably-safe automation only.** The reaper removes a worktree only when
    clean AND fully pushed AND old; dirty/unpushed → a human. Same shape everywhere:
    when in doubt, surface — don't act. *(Enforced: `system/reaper.sh` + tests.)*
11. **Lint, don't refuse.** On a one-person board the owner can always override
    (`--force` steal on the lock; hand-edits win) — the system warns, it doesn't
    hard-block its owner.

## Human interface
12. **Verbatim over distilled.** Journals/decisions render the actual files —
    formatting may improve (markdown rendering is lossless), content is never
    LLM-summarized; distillation drops the *why*. *(Enforced: Loopdeck drawer +
    raw toggle.)*
13. **Slugs are for machines; humans get titles** (the spec/plan H1) and a digest
    (`brief.md`) rather than per-event pings (pager fatigue).
14. **Board rows stay one line**; all verbose detail lives in `tickets/<KEY>/*`.
    A multi-PR ticket is ONE row/card at its least-advanced state, per-PR badges.

## Meta
15. **The engine improves only through the owner-gated backlog** — retro PROPOSES
    to `<board>/system/loop-improvements.md`; the loop never rewrites its own
    machinery. (The backlog lives board-side on purpose: it's a living queue, not
    code. 23 open proposals as of 2026-07-25 — mostly judgment guards.)
16. **Everything in this repo is enforced by a test where possible** —
    `bash tests/run.sh`. A red suite blocks a ship, same as the private-references
    grep gate that runs before every commit (see the repo's commit discipline).
