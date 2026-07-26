---
name: add-ticket
description: Intake a new piece of work onto a board as a well-formed, execution-ready row — interview for the load-bearing context (what + done-definition, risk bucket, parity-sensitivity, dependencies, repo/base), locate-or-create the Jira ticket, and write the board row + a spec stub. Use when adding a ticket/task to a board, filing work for the orchestrator to pick up, or "add this to the queue / board". This is a PRODUCER (writes to the board); it never executes the work.
---

# add-ticket — execution-ready intake (a board producer)

Adds ONE well-specified row to a board so the `orchestrate` loop + `run-ticket`
worker can act on it without guessing. **Producer only — never builds/runs the
work.** The cost of a vague row is paid downstream (a worker plans against
ambiguity), so spend the few questions here.

## Interview — categorize on every framework factor (§3). Ask the judgment
ones (AskUserQuestion); infer the rest and state the inference for confirmation.
You PROPOSE the categorization with a one-line *why*; the human confirms it here
(intake IS the confirmation moment — record it, see below).

**Intent**
1. **What + done-definition** — summary + acceptance criteria. *The worker's target.*

**Risk classification (drives proof + gates)**
2. **Bucket** — Light / Normal / High-risk / Answer-shaped / Incident. Sort by
   *how bad if wrong* + *what does done look like*, NOT the ticket label. Note the why.
3. **Proof level** — derive from the bucket and record it explicitly:
   Light→P0 (docs/format) or P1 (code); Normal→P1 (small) or P2; High-risk→P3;
   Incident→P2; Answer-shaped→no-code. (Anyone may raise it; never below the floor.)
4. **User-visible? y/n** — if yes → an **acceptance check** gate applies.
5. **Human-only flag** — any step an agent literally can't do (needs prod creds,
   a manual/device verification, a human-only sign-off)? List them → they become
   human checkpoints, not agent work.

**Automatic FLOORS — ENFORCE, don't just ask** (set once per repo in config.md)
6. **Hard-to-undo path?** (schema dirs, public-API files, terraform, migrations)
   → if yes, **bump bucket to High-risk** (P3) regardless of the initial pick.
7. **Security-sensitive path?** (auth, sessions, permissions, payments, webhook
   verify, secrets, uploads, raw SQL; major security-dep bumps) → if yes, set
   **security-pass = required** regardless of bucket.

**Approach gates**
8. **Plan** — Normal+ get a plan by default; capture if the approver **waives**
   it (`Plan: waived by <name>`), or the bug-fix shortcut (failing test = plan).
9. **Parity-sensitive?** — ports/migrates/replicates existing behavior? yes →
   worker runs `trace-pair`; **capture the source** (repo path / legacy file).
   greenfield → "no trace".

**Orchestration**
10. **Projects spanned** — which repos does this work touch? Write
    `spans=<proj>(<role>)[+<proj>(<role>)…]` using the effort's `config.md` project
    registry keys. Roles: `build`/`frontend`/`backend` = gets a claim+branch+PR;
    `ref` = read-only (traced / run locally, no PR); `maintain` = existing PR.
    Primary project first. Migration tickets usually span e.g.
    `denali(build)+szero(ref)` (trace szero, build denali) or
    `szero(backend)+denali(frontend)` when a backend change is needed. If ≥2 repos
    get PRs, capture **`merge-order=<up>→<down>`** (producer before consumer). A
    plain single-repo ticket is just `spans=<proj>(build)`.
11. **Dependencies / file-overlap** — independent (→ parallel) or stacks-on/
    overlaps `<KEY>` (→ one worktree, sequential). Drives the partition.
12. **Priority** — owner order (the loop works owner order, never its own).
    (Base branch per project = the registry's base; claim-lock branch = ticket id.)

**Links** — Jira key (or create), Figma, related PRs, docs.

**You PROPOSE the categorization; a human CONFIRMS it via an R1 channel.** Record
the proposal in spec.md as `Bucket PROPOSED: <…> — awaiting human confirmation`.
The required `Bucket confirmed by <name>` line is valid **only** when a human
supplies it through an R1 channel (a GitHub action or a human-signed commit —
reference.md R1), **never** a line an agent writes. *Why:* otherwise an agent
could self-classify Light and skip every gate. So:
- If a **human** is running this intake interactively, they confirm now by
  **editing the file themselves** (add `Bucket confirmed by <name>` / set the
  state) — a human edit, not a line you write for them.
- If an **agent/discovery loop** is running it, leave the bucket
  **PROPOSED/unconfirmed** and set state `awaiting-bucket-confirmation`; the
  orchestrator DMs the owner and does NOT build until the **owner flips it** (per
  config.md's approval mechanic). An agent must never write the confirmation
  itself — that's the inverse integrity rule.

## Which board
**Default `<board-dir>` = `~/planning/boards/`** (the single Narvar board). Always use
the **absolute path** — you may be invoked from any repo's terminal session, so never
rely on the cwd. (If more than one board ever exists, ask which; today there's one.)

## Then (follow the canonical layout — the board's `docs/board-structure.md`)
1. **Locate or create the Jira ticket** — if it exists, use its key; else invoke
   the `jira` skill to create it (Story/Bug, parent, estimate) and capture the key.
2. **Scaffold the ticket folder** `<board-dir>/tickets/<KEY>/`: write **`spec.md`**
   (the gathered intent — summary, acceptance criteria, bucket, user-visible,
   security-sensitive, parity+source, deps, repo/base, priority, links) and an
   empty **`journal.md`**. The rest (contract/plan/review/decisions/notifications)
   are created lazily as the pipeline reaches them.
3. **Do NOT write `board.md`** — the `orchestrate` loop is its SOLE writer (that's
   how add-ticket is safe to run from any session, any number, concurrently with the
   loop). Instead:
   - **(a)** Put the **full categorization string into `spec.md`** so the loop can
     build the row on ingest:
     `bucket=<B> proof=<P> · vis=<Y|N> · sec-pass=<Y|N> · human-only=<none|…> · plan=<required|waived|test-is-plan> · parity=<Y:src|N> · spans=<proj(role)[+…]> · merge-order=<up→down|n/a> · deps=<independent|stack:KEY> · pri=<n>`
     (These map 1:1 to gates: `vis=Y`→acceptance check; High-risk→hard-to-undo
     sign-off; `sec-pass=Y`→security pass; `plan=required`→plan-approval gate;
     `parity=Y`→trace-pair; `deps=stack`→sequential in one worktree.)
   - **(b)** **Append one line** to `<board-dir>/inbox.md` (atomic `>>`, never edit
     existing lines): `ingest <KEY>` — or use the helper `board ingest <KEY>`. The
     loop drains the inbox each wake, reads the spec, and writes the board row itself
     (bucket PROPOSED → it lands at `awaiting-bucket-confirmation`).
4. Report the ticket + Jira key (and that you queued an `ingest`). **Do not start
   the work, do not write `board.md`.** If the `orchestrate` loop is **already
   running**, its **inbox Monitor** sees the `ingest` append and brings the next
   wake forward — it ingests the row and proceeds, no re-arm. If the loop is
   **stopped**, the `ingest` line just waits durably in the inbox and is picked up
   the next time a loop runs — tell the owner to (re-)launch `/loop`. **Prefer adding the first
   ticket BEFORE launching** (launching on an empty board can let the goal stop
   immediately — see orchestrate). If the board's `config.md` doesn't exist yet,
   create it (repo, base, gh slug, Slack target, approvers, caps) per the
   canonical structure.

## Notes
- This is one of possibly several PRODUCERS (a human, a discovery loop, a triage
  loop) feeding the board; the ONE `orchestrate` loop consumes it.
- Keep it conversational, not a 20-field form — ask the missing load-bearing
  items, infer the obvious, confirm once, write the row.
