---
name: retro
description: Pre-close loop retrospective — mine a just-finished ticket for loop friction (PR comments, rework, owner interventions) and propose concrete engine improvements. Run by orchestrate step 5c on a confirmed-done ticket, before archive.
---

# retro — turn a finished ticket into loop improvements

Run by `orchestrate` step 5c the moment a ticket is **confirmed `done`** (merged/closed
*from the world*), BEFORE it's archived (5d). Goal: mine the just-finished work for signals
of loop friction, root-cause each, and propose concrete improvements to the engine — so the
loop gets **better every ticket** instead of repeating the same mistakes.

## Inputs
`<board>/tickets/<KEY>/` — `spec.md`, `plan.md`, `journal.md`, `decisions.md`, `cycle.md`,
`review.md`, `notifications.md` — plus the ticket's PR(s) on GitHub.

## 1. Gather signals (measure friction — don't editorialize yet)
- **PR feedback** — per PR: count review comments + threads, split **bot vs human**, and
  classify each: `nit/style/copy` · `correctness/bug` · `regression` · `security` ·
  `design-question`. Flag any whose theme has appeared on **other** tickets (recurring =
  systemic).
- **Rework** — from `cycle.md` (the worker-runs ledger): # worker cycles, # re-pushes,
  # CI failures, # **reverts**, # times a "fix" had to be re-done. Any revert, or >1 cycle
  to land a change, is a signal.
- **Owner interventions** — from `decisions.md`, `brief.md`, and the inbox commands for this
  KEY (`ask`/`changes`/`reject`): every question the owner had to ask and every correction
  they made. **Split** genuine product/design decisions (NOT loop gaps — the loop *should*
  surface these to the human) from things **the loop should have caught itself** (spec gap,
  missing check, wrong assumption, unstated convention).

## 2. Diagnose (root-cause each)
For every signal that cost a cycle / a revert / an owner correction, ask: **why did the loop
not prevent it?** Trace it to a specific gap — a missing check in `run-ticket`, a
`pr_state`/`risk_floors` blind spot, a thin brief, a triage miss, an unstated AGENTS rule.
Mark each **avoidable** (a loop gap → becomes an improvement) or **inherent** (a real product
decision or external/infra cost → not an improvement, just noted).

## 3. Propose improvements
For each avoidable friction point: WHICH skill/file to change (`run-ticket`, `orchestrate`,
`system/pr_state.sh`, `triage`, a checklist, an AGENTS rule), WHAT the change is, and the
**evidence** (this KEY + any others). Tag each:
- `auto-low-risk` (e.g. add a checklist item / a lint) vs `owner-review` (changes loop
  behavior or policy).
- **Dedup** against existing `system/loop-improvements.md` — if the same gap already has a
  proposal, **bump its evidence list** (add this KEY) instead of duplicating. A gap seen on
  ≥3 tickets is escalated to the top.

## 4. Record + surface
- Write `tickets/<KEY>/retro.md` (signals + diagnosis + proposals) — it travels with the
  ticket into the archive.
- Append/merge proposals into **`system/loop-improvements.md`** (the cross-ticket backlog),
  one line each:
  `- [ ] <improvement> · target=<skill/file> · risk=<auto-low-risk|owner-review> · evidence=<KEY,…> (<n>)`
- Note it in `brief.md`: "N loop improvements proposed from <KEY> — see `system/loop-improvements.md`."

## Boundaries
- The retro **PROPOSES**; it does **NOT** edit the engine's own skills/scripts. Changing the
  loop's machinery is **owner-gated** — the owner reviews `loop-improvements.md` and says
  which to apply. The loop never silently rewrites itself.
- **Cheap by default:** a clean ticket (no comments, no rework, no owner questions) → a
  one-line "clean, no friction" `retro.md` and zero proposals. Don't manufacture findings.
- Run off **recorded truth** (`cycle.md`/`decisions.md`/the PR), never a worker's rosy
  self-report. A worker that says "all green" but whose `cycle.md` shows 3 re-pushes IS the
  signal.
