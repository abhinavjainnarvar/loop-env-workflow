# Owner's Voice Corpus — Claude Code session transcripts

Mined from local Claude Code session transcripts. Every sample below is text the
owner typed into a session prompt. Built 2026-07-29.

(Sibling document: `corpus-git-jira.md` covers commit / GitHub / Jira text, which is
lower confidence because agents wrote much of it under his account.)

---

## 1. Provenance and filter stats

### Source

| | |
|---|---|
| Root | `~/.claude/projects/**/*.jsonl` |
| `.jsonl` files on disk | 681 (~896 MB) |
| Files actually read | **64** — the top-level session files (`projects/<project>/<uuid>.jsonl`) |
| Files deliberately skipped | 617 — subagent transcripts under `<uuid>/subagents/**`. Every `user` turn in those has `isSidechain: true` and is the *orchestrator agent's* prompt, not the human's. Including them would have poisoned the corpus with agent prose. |
| Projects | work repo (`shopify-zero-retailer`, 587 msgs) and a personal project (1,637 msgs) |
| Worktree-suffixed project dirs | present but contain **no** transcripts (only `workflows/` scaffolding) — nothing lost |
| Date range | 2026-03 → 2026-07 |

### Filter funnel

| Stage | Count |
|---|---|
| `type == "user"` entries in top-level sessions | 32,454 |
| — dropped: entry carries `toolUseResult` (tool_result turn) | 28,291 |
| — dropped: `isMeta` harness entries | 547 |
| — dropped: non-`text` content blocks (tool_result etc.) | 414 |
| Surviving text blocks | 4,238 |
| — dropped: harness injections | 1,366 |
| ⤷ `<ide_opened_file>` | 580 |
| ⤷ `<task-notification>` | 510 |
| ⤷ `<local-command-stdout>` | 104 |
| ⤷ `This session is being continued…` | 92 |
| ⤷ `[Request interrupted` | 52 |
| ⤷ `<ide_selection>` | 28 |
| — dropped: slash-command boilerplate (`<command-name>` / `<command-message>` wrappers) | 274 → args harvested separately |
| — dropped: pasted non-prose blobs | 95 total |
| ⤷ paste with no human prose prefix | 67 |
| ⤷ pasted reviewer/agent report | 14 |
| ⤷ code paste | 12 |
| ⤷ long text carrying an em dash (see caveat) | 12 |
| ⤷ JSON blob / impersonal docs paste / stack trace / URL-only / quoted paste | 7 |
| — **trimmed**: long message = short human prefix + big paste → kept prefix only | 61 |
| — dropped: near-identical duplicates | 262 |
| **FINAL main corpus** | **2,224 messages** |
| **Slash-command args sub-corpus** (lower confidence) | **127** |

### Confidence

- **High** on the main corpus. These are prompt-submission turns from non-sidechain
  sessions; there is no path by which an agent writes into them.
- **~1–2 % residual noise.** Spot-checking the long tail found a handful of survivors
  that are pastes with conversational-looking text inside them (one Shopify docs
  excerpt, one URL-parameter dump, one keyword list). Too few to move any statistic.
- **Lower confidence on the slash-args sub-corpus.** `/review 424`, `/merged 413`,
  `/model opus` are clearly his. But several long `/goal …` and `/loop …` args in the
  work project are *agent-drafted handoff briefs he pasted back in* — line-wrapped at
  ~72 chars, em-dashes, "stacked on feat/…". Those are excluded from all lexicon and
  quantitative numbers.

### One methodological caveat (matters for the em-dash finding)

The paste filter drops long text containing an em dash, so the em-dash rate on the
full corpus is partly circular. To break the circle, the table below also reports the
**short subset (< 400 chars, 2,162 msgs / 97 % of the corpus)** which that rule never
touched. Em-dash rate there is **0.5 %**, and every one of those 11 hits is a code
snippet or UI string he pasted inline, **not his own sentence**. The anti-tell holds:
**he has never written an em dash in his own prose.**

---

## 2. Quantitative

| Metric | ALL | Work | Personal | Mar–May | Jun | Jul | Short subset |
|---|---|---|---|---|---|---|---|
| messages | 2,224 | 587 | 1,637 | 483 | 920 | 821 | 2,162 |
| median words | **12** | 14 | 12 | 10 | 14 | 13 | 12 |
| mean words | 18.5 | 20.3 | 17.9 | 13.6 | 20.9 | 18.7 | 16.1 |
| p90 words | 39 | 44 | 38 | 27 | 44 | 40 | 35 |
| p99 words | 101 | 101 | 104 | 69 | 112 | 99 | 65 |
| median sentences | **1** | 1 | 1 | 1 | 1 | 1 | 1 |
| ≤ 5 words | 18.1 % | 15.0 % | 19.2 % | 23.2 % | 15.0 % | 18.6 % | 18.6 % |
| ≤ 12 words (one-liners) | **50.4 %** | 45.8 % | 52.1 % | 60.7 % | 45.5 % | 49.9 % | 51.9 % |
| ≥ 60 words | 4.5 % | 5.1 % | 4.3 % | 1.2 % | 6.0 % | 4.8 % | 1.9 % |
| single-line messages | **91.9 %** | 88.6 % | 93.1 % | 93.6 % | 93.2 % | 89.5 % | 92.7 % |
| contains `?` | 28.1 % | 29.8 % | 27.5 % | 23.6 % | 29.7 % | 29.0 % | 27.4 % |
| is a pure question (ends `?`) | 15.8 % | 15.2 % | 16.0 % | 16.1 % | 15.9 % | 15.5 % | 15.9 % |
| starts with a capital | 66.9 % | 60.6 % | 69.1 % | **82.4 %** | 70.4 % | **53.7 %** | 66.4 % |
| starts lowercase | 31.7 % | 37.6 % | 29.5 % | 17.0 % | 27.5 % | **44.9 %** | 32.2 % |
| no terminal punctuation | **78.7 %** | 77.7 % | 79.0 % | 80.7 % | 78.2 % | 78.1 % | 79.1 % |
| has em dash / en dash | **0.5 %** | 1.2 % | 0.2 % | 0.2 % | 0.5 % | 0.6 % | **0.5 %** |
| has `!` | **0.2 %** | 0.2 % | 0.2 % | 0.2 % | 0.2 % | 0.2 % | 0.2 % |
| has emoji | **0.4 %** | 0.7 % | 0.3 % | 0.6 % | 0.3 % | 0.4 % | 0.4 % |
| has bullets / numbered list | 0.4 % | 0.2 % | 0.5 % | 0.2 % | 0.5 % | 0.4 % | 0.3 % |
| has markdown header | **0.0 %** | 0.0 % | 0.0 % | 0.0 % | 0.0 % | 0.0 % | 0.0 % |
| has code fence | **0.0 %** | 0.0 % | 0.0 % | 0.0 % | 0.0 % | 0.0 % | 0.0 % |
| has inline backtick | 0.1 % | 0.2 % | 0.1 % | 0.0 % | 0.1 % | 0.1 % | 0.0 % |
| has semicolon | 0.9 % | 1.2 % | 0.7 % | 0.0 % | 1.4 % | 0.7 % | 0.7 % |

Extra counts (whole corpus):

| | |
|---|---|
| messages dropping an apostrophe (`dont`, `lets`, `whats`, `im`) | 342 (15.4 %) |
| messages with an outright misspelling (`teh`, `pleae`, `alos`, `cna`, `verabage`, `deisgn`, `thbat`…) | 56 (**2.5 %**) |
| questions asked with **no** question mark | 420 (18.9 %) |
| messages stacking a second ask with "Also" | 282 (12.7 %) |
| ≤ 2-word messages, before dedupe | 225 / 2,486 (**9.1 %**) |
| emoji instances in his own prose | 1 (a marketing caption he was drafting) |
| exclamation marks in his own prose | 0 — all 5 `!` hits are inside pasted code or a password |
| markdown headers, code fences, tables authored by him | 0 |

Most-repeated whole messages before dedupe: `continue` ×51, `yes` ×22,
`yes please` ×19, `done` ×19, `try again` ×6, `sure` ×5.

---

## 3. Lexicon

### The spine of his phrasing (message-level counts, 2,224 msgs)

| Phrase | Msgs |
|---|---|
| `can you` | 465 |
| `lets` (bare, no apostrophe) | **216** |
| `let's` (with apostrophe) | **3** |
| `can we` | 214 |
| `also,` | 160 |
| `please` | 130 |
| `merge` / `merged` | 96 / 81 |
| `sure` | 90 |
| `why` | 83 |
| `should we` | 81 |
| `we should` | 64 |
| `again` | 64 |
| `do we` | 57 |
| `we need to` | 56 |
| `still` | 56 |
| `dont` | 49 |
| `first` | 41 |
| `what do you think` | 38 |
| `yes,` | 36 |
| `instead` | 34 |
| `i would like` | 32 |
| `i think` | 29 |
| `nice` | 28 |
| `wait` | 26 |
| `are we` | 26 |
| `i feel` | 24 |
| `did we` | 23 |
| `explain` | 22 |
| `i dont` | 22 |
| `fine` | 21 |
| `lets discuss` | 19 |
| `better` | 18 |
| `verify` | 16 |
| `seems` | 16 |
| `in detail` / `in details` | 16 / 4 |
| `makes sense` | 13 |
| `looks like` | 13 |
| `need not` | 12 |
| `right?` | 12 |
| `keep it` | 12 |
| `confirm` | 12 |
| `go ahead` | 9 |
| `got it` | 9 |
| `proceed` | 8 |
| `thanks` | 3 |
| `are you sure` | 3 |
| `could you` | **1** |
| `hold on` | 1 |
| `kindly` | **0** |
| `as per` | **0** |
| `lgtm` | **0** |

### Openers (first two words)

`can you` 290 · `can we` 94 · `yes please` 45 · `should we` 37 · `yes lets` 25 ·
`do we` 21 · `sounds good` 19 · `i have` 19 · `merged and` 18 · `did you` 18 ·
`i would` 17 · `we can` 17 · `is this` 17 · `this is` 16 · `there is` 16 ·
`i think` 13 · `i merged` 11 · `lets do` 11 · `i feel` 10 · `lets go` 9 ·
`got it` 9 · `what about` 9 · `i added` 9 · `looks good` 7 · `sure lets` 6

First word: `can` 393 · `i` 210 · `yes` 111 · `lets` 73 · `we` 64 · `what` 62 ·
`should` 57 · `merged` 44 · `please` 28 · `did` 26 · `why` 24 · `also` 21 ·
`wait` 16 · `done` 15.

### Indian-English / non-US constructions actually present

| | Msgs | Note |
|---|---|---|
| `need not` (for "doesn't need to") | 12 | strong marker: *"we need not add a server side guard"* |
| `till` (for "until") | 59 | *"from start till the end"* |
| `the same` as a standalone object | 48 | *"its the same result"*, *"Can we not do the same"* |
| `as of today` / `as of now` | 5 / 6 | |
| `can you please` | 15 | |
| `discuss about` | 5 | *"lets discuss about the differences"* |
| `explain me` | several | *"can you explain me the reason for this field"* |
| `behaviour`, `colours` (British spelling) | 12 / 9 | |
| `only` post-positioned | 43 | *"…and not entered the details only right"* |
| `right` as a tag question | 118 uses of `right` | *"detection wakes it by writing on the board right"* |
| `kindly`, `do the needful`, `revert back`, `prepone`, `good name` | **0** | he does *not* use the stereotyped set |

### Words he never uses

Zero hits across 2,224 messages: **delve, leverage, leveraging, seamless(ly),
furthermore, moreover, utilise, holistic, synergy, paradigm, pivotal, elevate,
unlock, empower, streamline, cutting-edge, best-in-class, landscape, realm, tapestry,
nuanced, intricate, meticulous, plethora, myriad, underscore, foster, facilitate,
endeavour, commence, ascertain, aforementioned, hence, therefore, whilst, amongst,
shall, apologies, "I apologize", certainly, absolutely, "dive into", "deep dive",
game-changer, bandwidth, "circle back", "touch base", low-hanging, "I'd be happy to",
"great question".**

`robust` 2, `utilize` 1, `crucial` 1, `thus` 1 — all four inside quoted or pasted
text, not his own sentences.

Also absent from his own prose: **markdown headers, bullets, bold, code fences,
tables, "TL;DR", "Note that", "It's worth noting", emoji, exclamation marks.**

---

## 4. Move patterns — verbatim samples

Tags: `[work MM]` / `[pers MM]`. Personal-project samples are redacted for private
specifics; sentence shape is untouched.

### (a) Opening a critique — states the defect flatly, then asks why

1. `[work 06]` "The UI looks really scattered. How can we improve the UX here?"
2. `[pers 06]` "Why dont we keep the query to one and maybe keep the variable name appropriate. Also shouldActivate appears bloated and maybe not necessary"
3. `[pers 07]` "The preview looks weird with a container outside the form"
4. `[pers 06]` "There is a big miscommunication here. We were supposed to render only the rsvp form and not the entire website with rsvp in it."
5. `[work 06]` "Can we update how the board looks? It is so difficult to read anything"
6. `[work 06]` "what is the status of branch 2818. i dont see anything in review.md. Half of the documents are outdated. 2716 is merged. That is not even updated on the board"
7. `[pers 07]` "The idea and the UI looks nice but the issue is with 3 different banners visible at the same time. We need to come up with a better approach here. Users will get confused."
8. `[pers 06]` "what the hell. I did not ask to run migration and seeds on production. How did that happen"

### (b) Requesting a change — `can you` / `can we` / `lets`, imperative, no hedging

9. `[pers 07]` "Please write it. Also, can you write e2e test cases to cover rsvp related use cases?"
10. `[work 07]` "Remove comments in app/javascript/consumer-app/pages/ReturnReasons/path.ts"
11. `[pers 06]` "Now files like [redacted]/templates/[redacted].json have hardcoded rsvp in the HTML. Can we cleanup those too as they wont be necessary"
12. `[work 06]` "Lets go to phase 3 and create a PR to the foundation branch instead this time"
13. `[pers 05]` "Lets fix this in a new worktree. Please use skill to create one from develop."
14. `[work 07]` "rebase now and check all the comments again"
15. `[work 07]` "can you check all the comments on 3211? update the branch and then let me know once ready"
16. `[work 07]` "Add #3209 to the monitor and also address comments. We should accept the newer comment instructions"

### (c) Verification question / challenging a claim

17. `[pers 07]` "Have we made the title more bold than usual recently or is it usual? Can you double check?"
18. `[work 07]` "If I understand correctly, the checkout url is stored in the local storage right? And if someone changes that, the browser will redirect to that URL? Are we passing any info that would create harm there. Can you double check"
19. `[pers 06]` "If I understand your approach correctly, we will update info on the details page and move website creation and related info also in select template step. Is that correct?"
20. `[work 06]` "Wait. we are running monitor to update the board right. It is independent of the loop. We are mentioning that at every wake, we do this. Is that correct or am I missing something"
21. `[pers 06]` "Can you tell me why the API returns 3 definitions but only 2 are visible"
22. `[work 06]` "Since, there are comments on PR 3975, why havent we resolved them?"
23. `[pers 04]` "i think the ci workflow changes are not present on develop. Can you double check"
24. `[work 06]` "2716 has already existing comments. Why were they not added? Dont make any changes? just curious"

### (d) Deciding / giving a go-ahead — one to five words, then the next instruction

25. `[pers 05]` "Yes"
26. `[pers 04]` "yes plesae"
27. `[pers 07]` "Lets go"
28. `[pers 05]` "Merged and deleted"
29. `[pers 07]` "merged 443. Yes, lets move to the-40, 41 and 42"
30. `[work 06]` "Yes add to 2716"
31. `[pers 06]` "Merged and deleted the branch. Lets move on to the next step"
32. `[pers 06]` "yes lets do them in the order you mentioned. Lets not step until the PRs are raised for them. We can combine them too if it makes sense."
33. `[work 07]` "yes lets prioritize all that we have listed so fatr"
34. `[pers 06]` "Sounds good to me. This is the right direction. Also, default state can be a neutral screen."

### (e) Setting scope / trimming verbosity

35. `[work 07]` "Can you even make it smaller and precise."
36. `[pers 05]` "Looks way too big. Lets keep it short and simple"
37. `[work 07]` "Bundle into #4051 and we need not add server side guard for now."
38. `[work 07]` "Lets not delete the worktrees whose PRs are not merged. Rest we can clean up."
39. `[work 06]` "lets not add team wide .mcp.json for now"
40. `[pers 06]` "We can do it in a follow up PR. Lets make a note of it"
41. `[work 07]` "only these 2 for now. Are we calling it UK or GB? Lets go to the other points now"
42. `[work 07]` "Post that comment. Keep it precise and then proceed with infra work"
43. `[work 06]` "We can ignore that part. Since, we are adding initial pages, we need not worry too much"

### (f) Reporting an observed bug — where, what he did, what he saw, then a hypothesis

44. `[pers 06]` "On develop, the onboarding flow template preview(step 2) does not show RSVP for some reason. Are we not passing the previously selected value in the first step"
45. `[pers 06]` "The error is still present"
46. `[pers 06]` "I am testing fix/[redacted] but it still shows the same UI. I rejected the RSVP."
47. `[pers 06]` "I debugged and I saw that the browser did not fetch rsvp-island.ts but after creating a new [record], it started working. Not sure how that could happen"
48. `[pers 06]` "I cleared cookies and it started working so the issue is different."
49. `[work 07]` "this is running locally so the issue is not on staging"
50. `[pers 05]` "Wait. What did we change? The issue is back. The story shows Home as active"
51. `[pers 06]` "The sign in page is going on infinite loop on prod. What happened"

### (g) Asking for status — blunt, often no question mark

52. `[pers 07]` "whats the status"
53. `[work 07]` "is loop running"
54. `[work 06]` "What happened? Why did we not create the PR? Why did we pause"
55. `[pers 06]` "whats the status and next action"
56. `[pers 07]` "is there anything pending after 400"
57. `[work 06]` "I am using my phone so can you tell me the status of board here"
58. `[pers 06]` "What is the status of everything we discussed and what are the remaining items"

### (h) Praise and acceptance — brief, and immediately followed by the next ask

59. `[pers 07]` "Looks good."
60. `[pers 07]` "Looks good. Can you update pr title and description"
61. `[pers 07]` "I like it. Lets add all of them"
62. `[pers 07]` "Perfect. Lets create a PR. Should we also push mp4 files or it is too much"
63. `[pers 06]` "I like the UI now. Can we make sure the content is not similar to [redacted] and we are providing information here"
64. `[pers 05]` "Thanks. lets go back to the previous conversation"

Praise is rare: only **19 messages** in 2,224 open with any positive word, and 14 of
those 19 attach a new request in the same message. `thanks` appears 3 times total.

---

## 5. Explicit style rules he stated

Quoted verbatim (redacted only where private). Strongest available evidence for what
he demands of writing.

> "the loop kernel.md contains too many technical verbage. Can we simplify the
> wordings and explanation. Also, update global claude.md to have empathy towards a
> technical reader and not use heavy words which are not used by software engineers
> on a daily basis. I need a simple technical language to grasp the overall
> understanding. Also, we need not produce a lot of content to explain. The content
> should always be simple and precise." `[work 07]`

> "Also, I would like to review all the comments and make sure it can be understood
> by a software engineer with 3 years of experience. Also, do not use highly
> technical verabage. Do not create your own technical references which others will
> not be aware of. Keep the comments empathetic to the reader and precise. Also, if
> there is no need to write a comment, remove it. If the code is enough that it does
> not really need a comment, lets clean up that too." `[work 07]`

> "I still feel teh review.md in loop-kernel is difficult to understand. What is LLM
> distillation? What is free prose parsing? … Build a system such that even a
> software engineer with a 3 years of exp can understand. Also, if you are using
> technical words which may be not common but it makes sense to use. Add their
> meaning in the brackets." `[work 07]`

> "Remove AI language. Use language which is friendly for most audiences. Remove
> hyphen from all the user friendly content as it feels like reading AI generated
> content." `[pers 07]`

> "make sure to remove dashes so that it doesnt look ai generated and the words
> should be understood by everyone and not be completely technical" `[pers 07]`

> "The blog's content is nice but it seem to be too AI written. … change the content
> in a way that it doenst seem AI written" `[pers 05]`

> "Can we also make content more empathetic towards a normal user and should not look
> like AI generated" `[pers 06]`

> "I think this blog is very wordy. People wouldnt read so much. Please keep it short
> and graphic for people to get the right message" `[pers 03]`

> "Can you explain in plain language so that it can be understood by anyone"
> `[work 06]`

> "Please use simpler language to explain." `[pers 06]`

> "CAn you explain me the issue in simple language" `[pers 07]`

> "Can you even make it smaller and precise." `[work 07]`

> "Please post the comment. Keep it clean, precise and keep the language very
> software engineer friendly" `[work 07]`

> "Can you create a plan for me to review on how to get this fixed? Please use simple
> words and provide good summary with depth below with examples so that it is easy to
> follow and share" `[work 07]`

> "For 5104, can we reduce the comments for fees.ts" `[work 06]`

> "why do we need these comments in [redacted]/brandingDraft.ts?" `[work 07]`
> (quoting back a 4-line explanatory comment block)

> "Can we reduce the amount of comments written here?" `[work 07]`

> "Does it make sense to have this comment ?" `[pers 06]` (quoting back a 3-line comment)

> "Do we need to simplify the comment there? Do we even need to mention about
> distance selling" `[work 07]`

> "Follow [colleague]'s minimal comment guide for this PR" `[work 07]`

> "How is my comment missed on denali PR 3570 about verbose comments" `[work 07]`

> "the wording needs to be changed: something very user friendly and not technical"
> `[pers 06]`

> "The title and name of the tasks are not easy to recollect. We need human friendly
> titles" `[work 07]`

> "Can we have timestamps also visible cleanly. Also, I only care about PST
> everywhere. We can have human readable timestamps everywhere" `[work 06]`

**Distilled rules, in his own terms**

1. Simple and precise. Don't produce a lot of content to explain.
2. Words a working software engineer says daily. No heavy verbiage, no invented terms.
   If an uncommon term is genuinely right, put its meaning in brackets.
3. Write so a 3-years-experience engineer understands it.
4. Empathy towards the reader.
5. No dashes / hyphens in prose — they read as AI-generated.
6. No AI language. Content must not "look AI generated".
7. Comment the *why*; if the code is clear, delete the comment.
8. Human-friendly, recollectable names and titles.
9. Short beats long. "People wouldn't read so much."

---

## 6. Register differences

**Work vs personal.** Nearly identical voice. Work is marginally longer (median 14 vs
12 words) and starts lowercase more often (37.6 % vs 29.5 %) — more mid-flight
one-liners between PR checks. Work carries the vocabulary of process (board, loop,
ticket, rebase, wake, phase, stack); personal carries product and growth vocabulary.
Politeness markers are the same in both. He is not more formal at work.

**Early (Mar–May) vs recent (Jul).** He does **not** get terser — he gets *longer and
more casual*:

| | Mar–May | Jul |
|---|---|---|
| median words | 10 | 13 |
| ≤ 12 words | 60.7 % | 49.9 % |
| ≥ 60 words | 1.2 % | 4.8 % |
| starts with a capital | 82.4 % | 53.7 % |

Two things changed. Sentence capitalisation collapsed (82 % → 54 %) — he stopped
bothering with the shift key. And messages grew because the work moved from "fix this"
to designing systems (loop engine, boards, review skills), which needs a paragraph.
Message *structure* never changed: single-line, no markdown, no terminal punctuation,
throughout.

**A distinct dictated register appears in Jul.** A handful of messages are clearly
voice-transcribed and left unedited — "So the first concern is that the reel is really
fast. Uh, every point should, uh, should be for as long as it takes for a person to
read it in normal pace." and "four q seven i would like to clarify few things the u i
on the return reasons page…". Same content, zero punctuation, filler words intact.

---

## 7. Ten style findings

1. **Median message is 12 words, one sentence, one line.** Half of everything he
   writes is ≤ 12 words. 92 % is a single line.
2. **He has never written an em dash.** 0.5 % of messages contain one; all are pasted
   code or UI strings. He has explicitly asked for dashes to be removed from prose
   because "it feels like reading AI generated content".
3. **Zero markdown.** No headers, no code fences, no bullets (0.4 %), no bold, no
   tables — ever. Structure is carried by "Also," not by formatting.
4. **No exclamation marks, no emoji.** Both effectively zero in his own prose.
5. **`lets`, not `let's`** — 216 vs 3. Apostrophes are dropped generally (`dont`,
   `whats`, `im`) in 15 % of messages.
6. **78.7 % of messages have no terminal punctuation**, and 19 % ask a question with
   no question mark ("is loop running", "whats the status").
7. **`can you` / `can we` is the request form** (679 messages). Not "please do X", not
   "I need you to". `please` appears in 130 messages, `kindly` in zero.
8. **He stacks a second ask with "Also,"** in 12.7 % of messages — one message, two or
   three unrelated requests, joined by "Also,".
9. **Typos ship.** 2.5 % of messages contain an outright misspelling (`teh`, `pleae`,
   `cna`, `verabage`, `deisgn`, `fatr`, `tjat`) and he never corrects them.
10. **Praise is rare and always transactional.** 19 messages in 2,224 open positively;
    14 of them attach the next request in the same breath. He never opens with a
    compliment before a critique.

Two more worth keeping: he **quotes the artefact back before criticising it** (pastes
the file path or the comment block, then asks "why do we need this"), and **`wait`
(26 messages) is his interrupt** — "Wait." on its own means stop and back up.

---

## 8. Insufficient evidence

- **How he writes to other humans.** Everything here is prompt-to-agent. Slack, PR
  descriptions, and Jira are excluded by design (agents wrote much of it under his
  account), so his register when addressing a colleague directly is unmeasured. The
  one proxy — "Post that comment. Keep it precise" — shows he *delegates* that voice
  rather than typing it.
- **Long-form prose.** Only 4.5 % of messages exceed 60 words and none are polished
  writing. No evidence of how he structures a document he writes himself.
- **Paragraph and section structure.** He never authored one in a prompt.
- **Apology / conflict register.** "My bad" appears twice; nothing stronger. No sample
  of him being wrong at length, pushing back on a person, or de-escalating.
- **Titles, headlines, commit messages in his own hand.** He reviews and rejects them
  ("we need human friendly titles") but rarely writes one, so the corpus shows his
  *taste* here, not his *output*.
- **Pre-March 2026.** Transcripts start 2026-03; the 35 messages from March are too
  few to establish a baseline for drift.
- **A third register (formal / external).** Nothing in the corpus is customer-facing or
  written for an audience outside his own tooling.

---

### Corpus artefacts

Machine-readable output lives in the session scratchpad (not checked in):
`corpus_main.jsonl` (2,224 records: `text`, `proj`, `month`, `trimmed`, `file`, `ts`)
and `corpus_args.jsonl` (127 slash-command args). Scripts: `extract.py`,
`analyze.py`, `moves.py`.
