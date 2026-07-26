---
name: incident
description: Handle a production incident / recurring Rollbar error — FIX-FIRST (not plan-first), prove the fix with occurrence evidence, gate any prod-touching change on a human sign-off, then write the post-incident note. Use for an Incident-bucket row (a Rollbar/prod error a discovery loop or human surfaced). Dedup on the Rollbar fingerprint. Never merges or deploys — the human makes prod-touching clicks.
---

# incident — fix-first production-incident handling

For an **Incident-bucket** row (a recurring/critical production error, e.g. Rollbar).
The shape differs from a build: **fix-first, not plan-first** — speed matters and the
failing behavior IS the spec. (Use `run-ticket` for normal build work; use this for prod fires.)

## Pipeline
1. **Triage the signal** — confirm it's real + scope it: env=prod, level=error/critical,
   occurrence **count** + first/last **timestamp** + the **Rollbar URL**. **Dedup on the
   Rollbar fingerprint** (one ticket per fingerprint, not per occurrence). If a recent
   deploy looks causal → consider **revert first** (fastest reversible fix), flagging the
   prod sign-off.
2. **Fix (reversible)** — claim (branch = ticket id), write a **failing test that
   reproduces** the error (the spec), apply the smallest correct fix, make it green with
   `checks: <sha> <cmd> = pass` evidence. Reuse prior-art fixes for the same error class.
3. **Prove (P2)** — record occurrence count + timestamps + Rollbar URL in `journal.md`;
   the fix must demonstrably address the traced cause (not mask it).
4. **Gate prod-touching changes** — any deploy / revert / migration →
   **`awaiting-hard-to-undo-signoff`** and **DM the owner / on-call IMMEDIATELY** (not the
   next brief, per `config.md`'s incident target). The destructive-command guard still
   applies — the agent never merges/deploys.
5. **Open PR** → `pr-clean`; the human reviews / merges / deploys.
6. **Write-up** — a short post-incident note in `decisions.md` (cause · fix · proof ·
   follow-ups, e.g. "file a data-integrity ticket") → owner reads.

## Integrity / honesty
- **Human-only:** prod creds, the deploy/merge click, prod verification — surface them as
  checkpoints, never attempt them.
- If you **can't reproduce** or the cause is unclear → `pr-needs-human` / `blocked` with
  exactly what's needed; never fake a fix or claim a green you didn't run.
- Notify the incident owner **on open**, immediately — incidents don't wait for a digest.
