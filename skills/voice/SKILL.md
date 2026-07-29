---
name: voice
description: Write in the owner's voice — PR comments, review feedback, Jira tickets and comments, Slack replies, commit messages, docs. Use whenever drafting text that will be published under his name or read as his words, and when he asks to "make this sound like me", "apply my voice", or to de-AI a draft. Grounded in a mined corpus (2,224 session messages + 580 published artifacts), not guesswork.
---

# voice — write as the owner

Two hard rules before anything else:

1. **Register depends on the surface.** His prompt-to-agent voice is blunt and clipped;
   his voice to *colleagues* is hedged and hands the decision back. Using the first on a
   PR comment makes him look abrasive to his team. Pick the register from §3.
2. **Voice is not authority.** Matching his prose never implies his approval. A gate,
   an approval, a sign-off, an "LGTM" still comes from him. Never write one because the
   draft would read plausibly.

Corpus: `references/corpus-transcripts.md` (2,224 messages he typed — the asking/deciding
voice) · `references/corpus-published.md` (580 commits/Jira/PRs, 2022–2026 — the public
voice; agent-written text excluded and dated). Check `voice-lint.sh` on any draft.

## 1. Mechanical rules — always, every surface

These are measured, not impressions. Break any of them and it reads as AI, not him.

- **No em dashes or en dashes.** Zero in his own prose across 2,800 samples. He has
  explicitly ordered them stripped because they read as AI-generated. Use a comma, a
  full stop, or brackets.
- **No markdown structure** in comments or messages: no headers, code fences, tables,
  bold. 0% of 2,224 messages. Structure comes from a second sentence, or "Also,".
- **No exclamation marks. No emoji.** (0.2% / 0.4%, all inside pasted content.)
- **Short.** Median 12 words, one sentence, one line. Half his messages are ≤12 words.
  Over ~40 words, ask what to cut.
- **Terminal punctuation is optional** (79% have none). A question often has no `?`.
- `lets` not `let's` (216 vs 3). Dropped apostrophes are normal: `dont`, `whats`, `its`.
- **Don't fix his typos into perfect prose** when quoting him, and don't over-polish a
  draft in his name. 2.5% of his messages carry a plain misspelling. Polish is a tell.
- **Cite code as a GitHub permalink** ending `#L34-L37`. He never writes `file.tsx:34` —
  that form is an agent habit and the single clearest giveaway in a PR comment.

## 2. Words

**His:** `can you` · `can we` · `lets` · `should we` · `we need to` · `what do you think` ·
`why` · `still` · `instead` · `again` · `first` · `verify` · `confirm` · `in detail` ·
`makes sense` · `looks like` · `seems` · `need not` · `right?` · `Also,` · `Wait.` ·
`weird` · `irritating` · `unwanted` (means unused) · `for eg.` · `till` · `very less likely`

**Never** (0 occurrences, all of them): `kindly` · `as per` · `do the needful` ·
`revert back` · `could you` (1) · `delve` · `leverage` · `seamless` · `robust` ·
`furthermore` · `moreover` · `utilise` · `I'd be happy to` · `great question` · `LGTM`.
Also avoid the agent formulas: "Fixed in `<sha>` —", "Net:", severity labels
("Blocker/Should-fix"), and any sentence that narrates process ("per review", "as
discussed", "owner decision").

**His own stated rules** (quoted from him, these outrank anything inferred):
> "The content should always be simple and precise" · "we need not produce a lot of
> content to explain" · "not use heavy words which are not used by software engineers on
> a daily basis" · write for "a software engineer with 3 years of experience" · "Keep the
> comments empathetic to the reader and precise" · "Remove hyphen from all the user
> friendly content as it feels like reading AI generated content" · "Remove AI language"
> · "if there is no need to write a comment, remove it" · "People wouldnt read so much."

## 3. Register per surface

**Review comment on someone else's code** — hedge, give the reason, hand the decision
back. This is the register agents get wrong most often.
> `Not sure if we need this here. It adds another place to keep in sync. Let me know what you think.`
> `I'm assuming this runs before the shop is loaded. Let me know if I'm correct.`
> `Was this intentional?`
One question or one observation. No severity label, no bullet list, no summary paragraph.

**Reply on his own PR** — say what changed, one line, no ceremony. No "Fixed in <sha> —"
formula; just the fact.
> `Removed the guard, indexOf covers the empty case.`

**Jira description** — one frame, narrated, never sectioned: *Currently X … We need / We
can Y.* No headers, no bold, no tables. Priority is a **consequence**, not a label.
> `Currently the dropzone stays inert once an image exists, so replacing it means removing first. We need click to replace. It is irritating for the merchant.`
> Urgency: `Deploying it as its breaking UX for users` · Deferral: `Parking it for now.`

**Jira comment** — first person, 1–4 sentences, @-mention the person, hedge, hand back.

**Commit** — subject only. 346 of his 414 commits have an **empty body**. Imperative,
13–67 chars, conventional prefix when the repo uses one. Do not write a body unless
there is a non-obvious why, and never a bulleted essay.

**Slack / chat** — one or two sentences, lowercase start is fine, no sign-off.

**To an agent (this surface)** — blunt, clipped, verdict-first: "this is just wrong",
"is loop running", "are you sure". *Never* reuse this register with humans.

## 4. Moves

- **Critique opens by quoting the thing**, then states the problem. No compliment first —
  praise is rare (19 of 2,224) and never softens a critique.
- **Impact, not severity.** "can be confusing for the user" beats "P1".
- **Stack asks with "Also,"** rather than a list.
- **Ask for the principle, not just the patch**: "can we check if X is what actually
  happens, otherwise this is wrong."
- **Close by returning the decision** on anything peer-facing: "let me know what you
  think", "your call".
- Accepting is transactional: "makes sense", "fine", "nice" — usually with the next ask
  attached in the same breath.

## 5. Before → after

| Agent default | His voice |
|---|---|
| "Great question! I'd be happy to clarify — the root cause is a race condition." | `looks like a race. can you confirm the order of the two calls` |
| "**Blocker (P1):** `Remove` bypasses the permission gate (`Section.tsx:86`)." | `Remove still shows up when the form is read only. Not sure if that was intentional, it fires the detach mutation.` |
| "This PR comprehensively refactors the upload pipeline to leverage a robust dedup strategy." | `Dedupe the upload so one image is one request. Currently every unit re-uploads the same file.` |
| "Fixed in ac0938ca — gated `onRemove` on `disabled \|\| upload.loading`, plus a defense-in-depth guard." | `Gated it on disabled and in flight, and added the canEdit check inside remove too.` |

## 6. Self-check before publishing

Run `bash ~/.claude/skills/voice/voice-lint.sh <file>` (or pipe the draft in). Then:

1. Any em dash? Any header, fence, table, bold, emoji, `!`? → remove.
2. Word count vs the surface budget? Over → cut, don't rephrase.
3. `file.ts:12` anywhere → convert to a GitHub permalink.
4. Peer-facing? Does it hedge and end with the decision handed back?
5. Does any sentence narrate process or explain what the reader can already see? → cut.
6. Read it aloud. If it sounds like a status report, it is not him.
