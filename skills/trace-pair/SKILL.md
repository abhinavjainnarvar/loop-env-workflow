---
name: trace-pair
description: Ground an understanding of existing code in verified fact before planning against it — two independent trace agents each produce a behavior contract (file:line + conclusion per behavior), a validator reconciles them, and divergences trigger a targeted re-trace. Use whenever you need a trustworthy "what does this code ACTUALLY do" baseline — porting/migrating a page or module, reproducing a bug, asserting parity between an old and new implementation, or any change where a wrong assumption about existing behavior is costly. Invoke before writing a plan for parity-sensitive work.
---

# trace-pair — anti-hallucination grounding for "what the code actually does"

Produces an **agreed behavior contract** of existing code that downstream work
(a plan, a port, a parity test) can trust. The point is to defeat the most
expensive failure mode: confidently planning against a *wrong* belief about how
the current code behaves. Verified by use on a real migration (caught nullable
fields + flag-gating details a single read would have guessed wrong).

## When to use
Parity-sensitive or assumption-heavy work: porting/migrating, bug repro,
old-vs-new equivalence, "does X already handle Y?". For trivial/greenfield work
a single read is fine — don't pay for the pair.

## The flow

1. **Spawn TWO trace agents in parallel, independently** (separate subagents, no
   shared context — they must not influence each other). Give each the same
   brief: read the real source (cite paths) and emit a **structured contract** —
   for every distinct behavior:
   - `behavior` (one line) · `evidence` (`path:line` or tight range) ·
     `conclusion` (the precise factual behavior: data shape, condition,
     ordering, side effect, nullability).
   Tell them to cover the dimensions that matter for the task (e.g. data fetch,
   feature-flag gating, permissions, rendering states, mutations, i18n, routing
   for a UI page) and to mark anything they couldn't confirm from source as
   `UNCONFIRMED` rather than guess. Read-only — never edit the source.

2. **Spawn ONE validator agent.** Give it both contracts + the source paths. It:
   - re-verifies the load-bearing claims **against the actual source** (don't
     take either tracer's word),
   - produces the **AGREED CONTRACT** (points both assert and it confirmed,
     with the file:line it checked),
   - lists **DIVERGENCES** and **UNCONFIRMED/GAPS**, resolving gaps from source
     where it can,
   - returns a **VERDICT: AGREE** (ground truth solid → proceed) or **DISAGREE**
     (naming exactly where).

3. **On DISAGREE** → spawn a fresh trace pair aimed at *exactly* the divergent
   point (not the whole thing); re-validate. Repeat until AGREE or escalate to a
   human if it won't converge (that's a legitimate "agents can't reach a
   conclusion" pause).

4. **Write the agreed contract to a file** (e.g. `tickets/<KEY>/contract.md`)
   with the confirmed behavior + the gaps to resolve/verify during build as
   explicit risks. This file is the ground truth the plan is written against.

## Output contract (what each agent returns)
- Tracers: a markdown contract grouped by dimension; terse; `UNCONFIRMED` where unsure.
- Validator: `AGREED CONTRACT` + `DIVERGENCES` + `GAPS` + `VERDICT: AGREE|DISAGREE`.

## Cost note
3 subagents per run (2 tracers + 1 validator), each isolated context. Reserve
the full pair+validator for parity-critical understanding; a single trace is
fine for low-stakes reads. It grounds *understanding* (upstream) — it does not
replace downstream test-first build + fresh-eyes review of the NEW code.
