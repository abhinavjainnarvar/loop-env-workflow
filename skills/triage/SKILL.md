---
name: triage
description: Autonomously categorize a producer-surfaced `awaiting-triage` board row — read the Jira/PR + the spec stub, apply the framework's §3 risk factors (bucket, proof, user-visible, security/hard-to-undo FLOORS, parity+source, spans, plan, deps, priority), write a full spec.md, and PROPOSE a bucket (leave the row at awaiting-bucket-confirmation). Use when the orchestrate loop has an `awaiting-triage` row — a sensor/producer ingested a ticket or PR and it needs categorizing before any work. The loop-driven counterpart to add-ticket (which interviews a human). PROPOSES only; a human confirms via an inbox `approve`; never builds or claims.
---

# triage — autonomously categorize a surfaced row (loop-driven)

A sensor/producer surfaced a row at **`awaiting-triage`** (it `ingest`ed a Jira ticket
or an authored PR and left a minimal `spec.md` stub). Turn it into a properly
categorized, execution-ready row **without a human interview** — read the source,
apply the §3 factors, write the spec, and **PROPOSE** a bucket. You never confirm the
bucket and never build. This is the autonomous twin of `add-ticket`.

## Ground it — read the source, don't guess
- The stub `tickets/<KEY>/spec.md` (what the producer wrote).
- The Jira ticket — `jira issue view <KEY>` (description, comments, labels, components).
- PR rows — `gh pr view <n> --repo <repo>` (title, files, base).
- Repo conventions — `CLAUDE.md` / `MIGRATION.md` when relevant.

## Categorize on every §3 factor (PROPOSE — a human confirms)
1. **What + done-definition** — summary + acceptance criteria.
2. **Bucket** — Light / Normal / High-risk / Answer-shaped / Incident, by *how bad if
   wrong* + *what does done look like* (NOT the label). One-line why.
3. **Proof level** — Light→P0/P1, Normal→P1/P2, High-risk→P3, Incident→P2.
4. **User-visible?** → acceptance check applies.
5. **Human-only steps** — prod creds, device/manual verification, human sign-offs.
6. **FLOORS — run `system/risk_floors.sh`** on the ticket's touched paths/terms (and
   the Jira/PR file list). Any `sec-pass=Y` / `hard-to-undo=Y` it returns is **FORCED**
   — raise rigor, never lower below it. This is **deterministic**, so a hallucinated
   "Light" can't drop a security/schema gate.
7. **Plan** — Normal+ → plan required; bug-fix shortcut (failing test = plan) where it fits.
8. **Parity-sensitive?** + **source** (repo path / legacy file) → worker runs `trace-pair`.
9. **Spans** — which repos (registry keys) + roles + `merge-order`.
10. **Deps** (independent / stack:KEY) + **priority**.

## Then
1. **Rewrite `tickets/<KEY>/spec.md`** with the full intent + the standard
   categorization string (the orchestrate `ingest` format), incl.
   `Bucket PROPOSED: <…> — awaiting human confirmation`.
2. **Leave the row at `awaiting-bucket-confirmation`** — the loop DMs the owner.
3. Do **NOT** claim, build, trace, or open anything. Triage ends at the proposal.

## Integrity
- You **PROPOSE**; a human **CONFIRMS** via an inbox `approve <KEY>` (R1). An agent that
  self-confirms its own categorization could classify Light and skip every gate — never.
- FLOORS come from `risk_floors.sh` (deterministic), not your judgment — they cannot be
  hallucinated away.
