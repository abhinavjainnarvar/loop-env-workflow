# Loop Kernel + Loopdeck — design review (2026-06-30)

## How this review was done

Five reviewers each looked at the design from one angle and tried to break it
(a "5-lens adversarial review" — each lens is deliberately skeptical, looking for
what fails rather than what works). The five angles: state integrity (can the data
go wrong?), concurrency + recovery (what happens under races and crashes?),
security + trust (can someone forge something?), operability + scale (is it painful
to run, does it hold up as it grows?), and architecture (is the whole idea sound?).
Raw output is in the workflow task file (`tasks/wrvl8hg40.output` plus the
operability re-run). This file is the summary and the final call.

First, some terms used below, in plain words:

- **The kernel** — the proposed new backend: one service that owns all state and is
  the only thing allowed to change it.
- **Event-sourced** — instead of storing "the current state," you store the full list
  of changes that happened ("ticket created", "moved to building", "approved"). The
  current state is rebuilt by replaying that list from the start.
- **Projection** — the current state you get *after* replaying all those events. It's a
  read-only view derived from the event list; you never edit it directly.
- **Gate** — a point where work can't move forward without a human decision (e.g. "done"
  needs your approval). "Forging a gate" = making it look like the human approved when
  they didn't.

## The verdict

**Don't build the full event-sourced kernel.** Two reasons.

1. **It fixes a problem we've never actually had, and skips the ones we keep having.**
   The kernel's main promise is "an agent can't forge a gate." But that has never
   happened — there's no recorded case of an agent faking an approval. Meanwhile,
   every open item in `loop-improvements.md` is a *judgment* miss (the loop or an agent
   decided something wrong) or a *verification* miss (we didn't check the real world and
   trusted a stale answer). The kernel doesn't help with any of those.

2. **It flips the one rule the whole system leans on.** Today, the source of truth is
   *the real world* — GitHub, Jira, CI — and we always recompute state by re-reading
   them ("truth = recompute-from-world"). The kernel would instead make its own local
   event list the source of truth. Those two are NOT the same thing: replaying our event
   list ("event-fold" — folding the list of events down into one current state) can
   disagree with what's actually true in the world. Example: someone force-merges a PR
   or hand-edits a ticket in Jira. The world just changed, but no event was written to
   our log — so our log now says something false, and confidently. Two of the five
   reviewers flagged this independently as the riskiest assumption in the design.

If we build *anything*, build the **light version**:
- Read the markdown board and produce a **projection** (a derived read-only view) for the
  dashboard — no new way to *write* state, just a nicer way to *read* what's already there.
- A thin **gate-skip validator** — a small check that flags "this ticket jumped past a
  required gate" without taking over the whole system.
- The one integrity piece worth doing properly: **channel-authenticated gate-auth** —
  make approvals provable by *where they came from* (a trusted channel only the human can
  post to), not by a username string anyone could type.

## Worth fixing NOW (independent of the kernel) — tracked in loop-improvements.md

These are real holes in the *current* system. They don't need the kernel.

1. **Prompt-injection could forge a gate** (the scariest one). "Prompt injection" =
   malicious text hidden in content an agent reads (a PR body, an issue comment) that
   tricks the agent into doing something it shouldn't. Here the risk: a worker reads
   untrusted content, gets tricked, and appends an approval line to the board. Today the
   only "proof" of who did something is the Unix username (`id -un`) — which is not real
   authentication (anyone/anything running as that user can write it). → **Partial fix
   applied**: workers are now forbidden from touching the inbox or writing gate lines, and
   the loop drops any gate command that came from an agent. **Full fix** = the
   channel-based approval above.

2. **No lock preventing two loops at once** ("split-brain" — two copies of the loop both
   think they're in charge and both act). Right now "only one loop runs" is just a
   convention, not enforced. A cron-triggered loop and a manual one can both drain the
   inbox and dispatch the same work twice. → Needs a real lock (only one loop can hold it).

3. **The inbox can drop a message when it's archived/truncated** — a TOCTOU bug.
   "TOCTOU" = Time-Of-Check to Time-Of-Use: you check something, then act on it, but it
   changed in the gap between the two. Here: a producer appends a new command to the inbox
   in the moment between the loop reading it and the loop truncating it — so that command
   gets thrown away unread. This directly breaks our "no message is ever missed" promise.
   → Fix with a file lock (`flock`) and only truncating the exact byte range we already
   consumed.

4. **No cleanup for dead workers or leftover worktrees** ("worker reaper"). If a worker
   dies mid-job, its ticket is stuck showing "building" forever, and its git worktree
   (the isolated checkout it was working in) is left behind — which then collides when we
   try to re-dispatch that ticket. → Need something that detects dead workers and cleans up.

5. **producers.log had grown to 444KB with no rotation** ("log rotation" = capping a log
   file's size by trimming or splitting it so it doesn't grow forever). → **DONE.**

## If the kernel were ever built — the parts the design is currently missing

(Only relevant if we revisit the full build. These are the gaps that would have to be
closed for it to be safe.)

- **A durable place to store the log, plus disaster recovery ("git substrate + DR").**
  "Substrate" = the underlying storage the whole thing sits on; here, a real git repo so
  the data is versioned and backed up. "DR" (disaster recovery) = a plan to get the data
  back if the machine/disk dies. The boards directory wasn't even a git repo before — the
  new `loop-env-workflow` repo fixes this.
- **Compaction / snapshots.** The event log grows forever, and every restart rebuilds
  state by replaying it from the very first event ("from genesis"). Eventually that's too
  slow. "Compaction" = periodically saving a snapshot of current state so you can replay
  from the snapshot instead of the beginning.
- **A plan for changing `lifecycle.json` over time ("schema evolution").** That file
  defines the allowed states and steps. If you rename a state, any ticket currently in the
  old state is stranded, and replaying old events breaks (they reference a state that no
  longer exists). → Needs a version number and rules validated as-of the time each event
  happened, not just against today's rules.
- **A way to see *why* a ticket is stuck ("rejected-transition debuggability").** When the
  service refuses to move a ticket, you need a view that says "here are the next legal
  moves, and here's the guard that's blocking you." Without it, the service is the opaque
  black box the reviewers were worried about — it says no and won't say why.
- **Real machinery for ordering and safe concurrent writes.** The design hand-waves these,
  but a multi-writer log needs them:
  - a **sequencer** — assigns each event a strictly increasing number (a "monotonic seq")
    so order is unambiguous. Don't use wall-clock timestamps for this; clocks drift, jump,
    and can go backwards.
  - **CAS** (compare-and-swap) — "only apply this change if the ticket is still in the
    state I expected" (`expected_from`). Stops two writers from clobbering each other.
  - **idempotency keys** — a unique id on each event so that if it's retried, it's applied
    once, not twice.
  - **atomic append** — writing an event either fully happens or not at all, never a
    half-written line.
  The design assumes "single writer" carries over from the current `board.md` (where the
  loop is the only writer). It does NOT — the new log has *many* producers writing to it,
  so all of the above becomes mandatory.

## Human factors (about the recently-added chat ideas)

- **Per-ticket chat**: keep it as a notes/read view, plus explicit buttons for actions —
  NOT "free-prose parsing." "Free-prose parsing" = trying to guess a command out of a
  sentence someone typed in plain English (e.g. reading "ok I think we can ship this" and
  deciding that means *approve*). That guessing is unreliable, especially for gates, so
  don't do it — give a clear "Approve" button instead of parsing prose.
- The journal and decision history should be built from the actual recorded events
  ("deterministic typed-event projections" — a view generated straight from the structured
  events, so the same events always produce the same view) or written by hand as an audit
  trail. It should **NOT** be "LLM distillation." "LLM distillation" = having an AI read
  everything and write a shorter summary. That's lossy (it silently drops detail) and it
  tends to drop the single most important thing — *why* a decision was made — which is
  exactly the part you'll need later.
- **Notifications**: collect them into one `brief.md` digest, don't send a separate DM
  every time any gated ticket moves. With several gated tickets that's a flood of pings
  ("pager fatigue" — so many alerts that you stop reading them and miss the real one).
- **Keep the hand-edit escape hatch.** On a one-person board, a strictly-enforced lifecycle
  mostly just gets in the owner's way. So when something looks off, **lint, don't refuse**
  — warn the owner ("this looks wrong"), but still let them do it. Don't hard-block.

## Dismissed or minor

- **projection-crash-consistency** (what happens if the service crashes mid-write to the
  read view) — already covered by the design, not a concern.
- **directive-parsing** — the current deterministic parser (fixed verbs, no guessing) is
  fine and should stay.
- **`.loop-ack` skill-drift** — a small inconsistency between the skill docs and behavior to
  reconcile; minor.
- **`state.json` should include a heartbeat** — a periodic "I'm alive" timestamp, so a dead
  loop actually reads as dead (right now a stopped loop can look like a running-but-idle one).
- **The wireframe drew one ticket (SHOPZ-5056) in two columns at once.** That surfaces a
  real data-model question: can a single ticket legitimately be in two states at the same
  time (e.g. two PRs in flight)? Worth answering before building the board view.
