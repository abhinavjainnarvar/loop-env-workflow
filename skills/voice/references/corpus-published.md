# Owner voice corpus — SECONDARY (published artifacts: git / Jira / GitHub)

Owner: Abhinav Jain — git `abhinav.jain@narvar.com`, gh `abhinavjainnarvar`, jira `abhinav.jain`.

This is the **secondary** corpus. It exists to cross-check the primary corpus (session
transcripts, mined separately into `corpus.md`) against text he actually published.

Sources mined: git commits in `narvar/shopify-zero-retailer` (szero) and `narvar/denali`;
Jira descriptions + comments across DEVOPS, CPMT, MILE, CM, CPREF, CDP, HUB, TRACK, SHOPZ,
PEAK (2022-04 → 2026-07). GitHub review comments and PR descriptions are **incomplete** —
see [Insufficient evidence](#insufficient-evidence).

---

## Provenance + contamination

### The dating problem, measured

Agents have been publishing under his identity for months. In git, the
`Co-Authored-By: Claude` trailer is the reliable tell, and em-dashes are a strong secondary
tell. Both are **exactly zero** before 2025-08 and rise steeply after:

| Window | his commits | Claude trailer | em-dash, no trailer |
|---|---|---|---|
| szero, → 2025-07-31 | 463 | **0** | **0** |
| szero, 2025-08 → 2025-12 | 276 | 5 | 0 |
| szero, 2026-01 → 2026-05 | 292 | 58 | 5 |
| szero, 2026-06 → now | 76 | 65 | 1 |
| denali, 2026-01 → 2026-05 | 143 | 79 | 24 |
| denali, 2026-06 → now | 175 | 148 | 15 |

Jira contaminates later and more sharply than git. Of 189 Jira samples pulled, **26 are
agent-written, all from 2025-11 onward and clustered hard in 2026-05 → 2026-07** — the
12-ticket `[Denali P0]` series (SHOPZ-4929…4940) was created in a single batch on
2026-05-04. Jira agent tells: `h2.`/`h3.` scaffolding (Summary / Type / Priority /
Background / Current State / Code Analysis / Next Steps), `file:line` citations,
`{code:ruby}` blocks quoting source, ✅ bullets, em-dashes, and escaped-markdown artifacts
from ADF round-tripping (`\[loop pilot\]`, `trace\-pair`).

Four conclusions that shape everything below:

1. **git clean window: szero, 2024-10-08 → ~2025-07-25** (414 non-merge commits).
2. **Jira clean window: 2022-04 → ~2025-10**, with human samples still appearing as late as
   2026-05-04. Jira is the *longer and better* human record — 4 years deep, and it contains
   actual prose, which his commits do not.
3. **The git trailer alone is not sufficient.** 39 denali commits carry em-dashes *without*
   a trailer. Any filter that trusts only the trailer imports agent voice.
4. **denali is unusable as a voice source.** His first denali commit is 2026-04-21 — the
   repo only ever saw agent-era output. All 318 excluded.

Two artifacts deserve special mention as **calibration pairs** — places where his voice and
the agent's sit side by side under one identity:

- **SHOPZ-4196** (2025-11-06): human prose above, then a section he himself labelled
  `h2. Data Flow Diagram(With the help of Claude)`. He marks the boundary for us.
- **SHOPZ-4474** (2026-02-19): a plainly human comment, then hours later a full agent RCA
  on the same ticket (h2/h3, `redirect_url.rb:25`, "Option A / Option B / Option C",
  "Next Steps", trailing `----`).

### Counts

| Surface | Collected | Kept as likely-human | Excluded as likely-agent | Confidence |
|---|---|---|---|---|
| szero commit subjects | 1107 | **414** | 128 trailer + 5 em-dash + rest post-cutoff | **High** |
| szero commit bodies (prose) | 174 non-empty | **3** | ~70 (structured bullets, 2025-08+) | **High** |
| denali commits | 318 | **0** | 318 | High |
| Jira descriptions | ~114 inspected | **109** | 23 | **High** |
| Jira comments | 72 | **54** quoted (of ~69 human) | 3 | **High** |
| Jira issue titles | 268 reported | **all pre-2026** | — | High |
| GitHub review comments on others' PRs | — | **0** | — | n/a — incomplete |
| GitHub PR descriptions | — | **0** | — | n/a — incomplete |

**Total kept: ~580 samples across commits + Jira.** 5 further Jira descriptions were
excluded as **other-voice** — he is reporter but product wrote the body (SHOPZ-3301,
SHOPZ-3717, SHOPZ-3948, PEAK-727/753/754, several open "Alan: I just got off a call with…").
Those would have been the worst kind of contamination: human, but not *his*.

Confidence: **high** on commit-surface and Jira-surface findings. **None** on GitHub review
voice, and none on any claim that requires comparing his GitHub register to the other two.

---

## Verbatim samples

Provenance tag format: `id | date | why classified human`.

### Surface A — commit subjects, terse maintenance (his dominant git mode)

1. `Added comment` — `e7157ceb0` | 2024-11-12 | pre-cutoff, 13 chars, past tense, no ticket
2. `Remove` — `a9b02f927` | 2025-06-11 | single word
3. `Uncomment` — `523087035` | 2025-07-24 | single word
4. `clean up` — `0ddcce130` | 2025-06-23 | **all lowercase**
5. `Cleanup` — `c43e24ded` | 2025-06-25 | he writes it both ways two days apart
6. `update message` — `79bd0e9fb` | 2025-06-09 | all lowercase
7. `Update fix` — `03bb60ee1` | 2025-06-30 | near-content-free; unmistakably human
8. `Minor updates` — `f792e8e68` | 2025-07-03 | vague by choice
9. `Fix the test case` — `b4c81c06f` | 2025-07-31 | **definite article** where an agent writes "Fix failing test"
10. `Rename screens, Fix types, lint, eslint and ts config` — `75887ebae` | 2025-07-06 | **comma-splice with a mid-sentence capital `Fix`** — a signature tic
11. `Fix select item not being highlighted` — `90d70b744` | 2025-07-30 | names the *symptom*, not the change
12. `Removed unwanted packages` — `8c7701f3e` | 2025-02-19 | "unwanted", not "unused"
13. `Removed system tests running twice` — `bd43eddff` | 2025-07-30 | grammatically loose (he removed the duplication, not the tests)
14. `Take chatgpt suggestions` — `6d63fb252` | 2025-07-30 | the contamination-boundary marker *and* pure human voice
15. `Log the entire object to help debug issue with Adorn` — `bc197a033` | 2025-04-02 | purpose clause; names the merchant informally
16. `SHOPZ-0000: Add pubsub env for abhi (#2118)` — `e64f0d399` | 2024-10-08 | `SHOPZ-0000` = no ticket; calls himself **"abhi"**
17. `SHOP-2938: Comments from the previous PR` — `18ed907f8` | 2024-12-03 | **`SHOP-` typo for `SHOPZ-`**; noun phrase, not imperative
18. `SHOPZ-2874: Add local development debug Readme` — `2fa88df63` | 2024-10-31 | "Readme", not README

Only three commits in the clean window have prose bodies. The most telling:

19. `9ba961cb` | 2025-01-21 | `feat: [SHOPZ-3049]: Add finishing UI changes`
```
1. Add Order discounts in the UI
2.Add loading states
3. Disable buttons on loading
4. Add consumer preferences check field
```
Hand-typed numbered list, **missing space after `2.`**, inconsistent capitalisation, no
closing sentence, no impact statement.

### Surface B — Jira descriptions, the "Currently X / We need Y" frame

20. `MILE-308` | 2023-01-30 | plain prose, no headers, contraction-free but loose
```
Currently, the react components look lengthy because of multiple requests in a page. We can extract that and put it in a separate hook to keep the component neat and increase readability.
```

21. `CPMT-1903` | 2023-05-01 | long but header-free; one flowing explanation
```
Currently, the .env(git ignored) is used to run local environment but whenever someone adds anything new, they have to add it to .env.example . This could break environment for other developer as their .env file does not have the new value.
```

22. `CPREF-86` | 2024-02-05 | title *Increase Nginx rpm on profile QA04*; one sentence, and the justification is an emotion
```
It is irritating for developers to test with nginx rate limits.
```

23. `CPMT-1659` | 2023-03-01 | title *Upgrade to react 18*; body is one word
```
Upgrade
```

24. `CPMT-807` | 2022-07-18 | no period, no detail
```
Find a way to create a seamless experience for cropping UI feature
```

25. `SHOPZ-2925` | 2024-11-26 | **first person singular, future tense** — he narrates his own plan
```
Considering backend changes are not ready, I will use the temporary backend contract to create a hardcoded UI.
```

26. `SHOPZ-2938` | 2024-11-28 | trails off without a period; "type proof" for "type-safe"
```
Currently, the graphql queries are not type proof. Will add codegen to make it smooth
```

27. `SHOPZ-3386` | 2025-04-14 | **`Lets` with no apostrophe**, trailing space, no period
```
We have to provide classes: any everytime we useStyles. Lets preserve the types 
```

28. `MILE-388` | 2023-04-25 | reasoning in the open, ends by deferring the decision
```
The time entered can be sensitive to the timezone. If the expectation is to active the rates on all the locations across country at the same time; Lets say 9am for NY and 6am for Seattle, then we need the timezone input from the user. If not, we just need to know the time costs will be active in their local time. For eg., 9am for NY and 9am for Seattle.

We need to finalize our approach on this.
```
Note `to active` for "to activate", a semicolon used as a comma, and `For eg.,`.

29. `CPMT-959` | 2022-08-24 | bug report; opens by naming his own confusion
```
I am facing a weird issue on neohub. I have declared empty arrays as initial states and I'm passing them to the React component using context.
The issue is that the component is not receiving them as empty arrays. Instead it is receiving react elements.
```

30. `MILE-310` | 2023-01-30 | numbered options with an inline verdict — his native way of presenting a choice
```
There is another optimization which would be necessary for neohub. The UI is re-rendered every few seconds and it causes weird behaviours like popups closing automatically.

It is because of the subscription with Apollo server and we need that too.
There are 2 solutions:

# We can compare the 2 objects after converting them to string and set the subscription value only when it changes - easy to do
# Get rid of the subscription completely and derive the data from jwt. Add additional data if required from the server
```
The `- easy to do` appended to option 1 is the whole recommendation. No "Recommendation:" header.

31. `SHOPZ-3701` | 2025-06-24 | contains the slip `we will make sure of react-hook-form` (meant "make use of")
```
Shopify does not allow passing functions as arguments from one screen to another. This enforces us to build a global state management where all the screens can update the state.

Also, we will make sure of react-hook-form for the updating states.
```

32. `SHOPZ-4217` | 2025-11-17 | he ships the ticket unfinished and says so
```
As of today, we have an outdated version of Mui which is preventing us from build efficient UI/UX flows which are available in the newer versions of Mui. The plan is to upgrade to version 6.

A lot more details will be added here.
```

33. `SHOPZ-3913` | 2025-08-11 | after the analysis, the scope creep is labelled "Bonus"
```
The assets folder seem to have compression enabled while packs folder does not. Possible explanation: The assets folder is redirected from the rails server while js folder is not.
...
Bonus: Clean up is this piece of code does nothing
```

34. `SHOPZ-4096` | 2025-10-03 | hedged generalisation of a one-retailer fix
```
In SHOPZ-3843, we added an option to omit self serve drop box locations. This change was primarily added for that retailer and carrier as UPS.

If useful, we can add this for all the retailers given the filter implementation resourcetypes:locker/servicecenter works for other carriers as well.
```

### Surface C — Jira comments (the closest available proxy for review voice)

35. `CPMT-2677` | 2023-10-26 | defends a decision, then hands the judgement back
```
This has been done intentionally. I don't think user would like to update the email address to the same email address. If for some reason, the updating of email address was not successful, he would come back to this screen and try again. This is stored on the user's browser (session storage). Let me know if the behaviour doesn't make sense.
```

36. `MILE-229` | 2022-12-19 | how he opens a critique: hedged, then defers
```
Not sure if we need this as this becomes a part of https://narvar.atlassian.net/browse/MILE-134 . Let me know what you think
```

37. `MILE-222` | 2022-12-19 | same move a day earlier, "Let me" with no object
```
I am not sure if we need this ticket. It is already a part of https://narvar.atlassian.net/browse/MILE-134 . Let me know
```

38. `CPMT-785` | 2022-07-12 | states his assumption and invites correction rather than asking outright
```
I'm assuming the above list is a new list and not additional to the existing ones as some of the options are similar. Let me know if I'm correct.
```

39. `MILE-309` | 2023-02-06 | disagreement, softened by conditional consent
```
I feel the redirections on QA are pretty quick and I don't see the issue with lagging so far as I did on my local. If you agree, we can focus on this later if needed.
```

40. `SHOPZ-2525` | 2024-10-29 | design critique: agrees with a colleague first, then counter-proposes as a question
```
I agree with [~accountid:...], I am not sure if parentheses are the right way to communicate with the regular customer here. Minus would be easier to understand. Also, how about a strike through for something that was waived off? -$4.95-
```

41. `SHOPZ-3509` | 2025-09-18 | his longest human comment: proposal, mechanism, then four words of close
```
Post discussion with Alan, we came up with an alternate solution which would be quicker to implement.

Considering ShopNowv2 checkout already handles refund with gift card or original payment method, we will decide override the refund payment method while creating shop now return(happens on clicking on Shop Now button). We already pass shop_now field to the backend, we will use this to modify the refund method based on retailer/narvar admin selection.

...Attaching screenshot for reference.

Let me know what you think
```
Note `we will decide override` (missing "to"), `return(happens` with no space before the paren — both recur.

42. `SHOPZ-2866` | 2024-10-29 | how he deprioritises: verdict, one-line reason, done
```
The package has lots of deep dependencies on packages like express & react. This would require a really big upgrade. Parking it for now.
```

43. `SHOPZ-3420` | 2025-05-13 | how he closes a ticket
```
Closing this as we don't see any error in the past 21 days.
```

44. `PEAK-825` | 2026-01-12 | how he signals urgency — no label, no "P0", just the consequence
```
Deploying it as its breaking UX for users.
```
`its` for "it's".

45. `PEAK-727` | 2025-12-19 | how he asserts ownership over a risky deploy, and names a substitute
```
The ticket is approved but I'd prefer deploying myself once I am back as it involves close monitoring. If we still want to deploy, [~accountid:...] would be the ideal person to take it forward.
```

46. `SHOPZ-4474` | 2026-02-26 | how he challenges a config he suspects is wrong — one question, no accusation
```
The refund method rules seem to be configured incorrectly. Full store exchanges work only when the return does not have an exchange. Was this intentional?
```

47. `SHOPZ-3472` | 2025-06-16 | pushes back on a bug report, asks for evidence, then adds the structural reason
```
The user with view access should not be able to edit the settings. They will see the input fields but if they try to make any changes, it will throw an error. If it is not the case, can we get more details or a screen recording of the issue?

Also, the backend is protected with permissions so it is very less likely they were able to edit anything.
```
`it is very less likely` — Indian-English intensifier.

48. `SHOPZ-3843` | 2025-10-16 | two consecutive comments; asks for help, then closes the loop
```
I'm unable to transition the ticket to complete. Can you help me out?
```
```
Somehow it was showing me PR review. Maybe it was a cache. Thanks eitherways.
```
`eitherways` (for "either way" / "anyways") is a strong idiolect marker.

49. `SHOPZ-3198` | 2025-06-02 | apology-first, then two words
```
Apologies for seeing this late. Yes, you can.
```

50. `SHOPZ-2847` | 2024-11-20 | the entire comment
```
[~accountid:...] Yes
```

51. `PEAK-827` | 2026-01-12 | how he receives a correction
```
Good catch [~accountid:...] . I have updated the PR.
```

52. `SHOPZ-3256` | 2025-04-28 | commitment with a soft deadline
```
I will get this resolved in this week.
```

53. `SHOPZ-4602` | 2026-02-24 | status update: what he did, what's next, no headers
```
I debugged the issue and I could see there was an issue with how variables references were managed in javascript. I will test the fix and update the status.
```

54. `SHOPZ-3884` | 2025-09-05 | note the leading space before the mention — he types mentions inline, mid-thought
```
 [~accountid:...]By shipping protection tooltip, did you mean the one next to the item?
```

### Surface D — Jira titles

Same register for four straight years — imperative or symptom-naming, no template, typos intact:

| date | key | title |
|---|---|---|
| 2023-04-05 | DEVOPS-7580 | Artifactory is unavailable due to high **capcity** |
| 2023-10-30 | CPREF-9 | Setup **functioanal** test cases workflow |
| 2025-07-04 | SHOPZ-3734 | POS: Move extensions to a new repository (body: "**respository**") |
| 2025-07-30 | SHOPZ-3861 | **Unathorized** error on using update general admin API |
| 2024-10-31 | SHOPZ-2875 | Fix ws |
| 2023-09-13 | CPMT-2484 | Code cleanup |
| 2025-11-26 | SHOPZ-4278 | Button not visible unless hover |
| 2023-01-30 | MILE-310 | Prevent UI re-rendering every few seconds causing weird behaviours |
| 2024-07-24 | HUB-7868 | Old experiences having issues changing marketing assets on Track Editor page |
| 2023-03-20 | CM-26 | On finish setting up carrier. Create and redirect to carrier details screen |

Contrast the agent-era titles under the same account: *"Fix nil arithmetic in
CancelExpiredReturnJob#return_expired? (Rollbar #43867)"*, *"Surface
InvalidCustomerEmailError gracefully in calculateRefund resolver"*, *"[Org Policy Exception]
Allow public access on shopify-retailer bundle buckets in domain-shopify projects
(qa/st/prod)"*. Symbol-precise, bracket-tagged, parenthetical-ID'd. He never writes these.

---

## Observed patterns

### Length and structure

- **He does not write commit bodies.** 346 of 414 clean-window commits have an *entirely
  empty* body; 3 have prose (19). The subject is the whole message. Largest single
  divergence from agent output, which bodies everything.
- **Commit subject length: p10 = 13 chars, median = 41, p90 = 67.**
- **Jira descriptions are 1–4 sentences.** Median ~2. One-word bodies happen (23, 24).
  His longest human descriptions (21, 28, 30) are still one flowing block with a blank
  line, never sectioned.
- **No headers, no tables, no bold, no `file:line`, no code fences** in any human sample
  across 580. When he lists, it is Jira `*`/`#` markup or a hand-typed `1.` — never
  `- **Bold lead-in**: explanation` (10, 19, 30, and CM-27, MILE-425).
- **He leaves tickets deliberately unfinished** and says so in the body: *"A lot more
  details will be added here."* (32). An agent never ships an incomplete artifact.
- **Many small commits, then a squash.** He commits WIP freely and lets the PR squash
  assemble the narrative. He is not curating history.

### Punctuation and casing

- **Zero em-dashes in 580 human samples**, git and Jira alike. The single cleanest
  negative signal in the corpus. Also zero emoji, zero `!`, zero backticks in commits.
- Sentence case; **drops to all-lowercase when the item is throwaway** (4, 6).
- **Comma splices joining unrelated actions, with stray mid-sentence capitals** (10).
- **Frequently omits the final period** on a closing sentence (24, 26, 27, 34).
- **`Lets` for "Let's", `its` for "it's"** (27, 28, 44). No apostrophes in contractions of
  "let us".
- **`For eg.,`** — not "e.g." (28).
- **Missing space before an opening paren**: `return(happens`, `.env(git ignored)`,
  `Advanced → General(screenshot attached)` (21, 41).
- Uses `→` for UI paths (`Advanced → General`) and `#`/`*` Jira list markup, never markdown.
- **Typos are frequent and repeat**: respository, functioanal, Unathorized, notificaiton,
  capcity, mirco, everytime, eitherways.

### Verbs, tense, person

- Commits: imperative dominates (**Add 116, Fix 71, Update 57, Remove 20**), but he **slips
  tense freely** — Added / Adding / Removed / Fixing / Tested (1, 12, 13, and 11 more).
  Agents are rigidly imperative; he is not.
- Jira: **first person is constant** — "I am facing", "I will use", "I debugged",
  "I'd prefer", "I'm assuming". Also a collective **"we"** for team plans ("We need to",
  "we can", "we will"). Agents write in impersonal or reporting voice.
- **He names the symptom, not the change** (11, and titles: *Button not visible unless
  hover*, *Locations CSV upload throws success banner after failure*).

### How he opens a critique

Three moves, in order of frequency:

1. **Hedge, then defer**: "Not sure if we need this … Let me know what you think" (36, 37).
2. **State the assumption, invite correction**: "I'm assuming X … Let me know if I'm
   correct" (38). Also "I am assuming its a mistake … Shouldn't this be …?"
3. **One flat question, no accusation**: "Was this intentional?" (46), "did you mean the
   one next to the item?" (54).

He never opens with a severity label, a category header, or a compliment sandwich.

### How he asks for a change

Declarative need, then the mechanism: *"We need X"* / *"The fix would be to Y"* /
*"This should be prevented."* Occasionally softened to *"We can"* or *"It would be great
to have"* when it is his own idea rather than a defect.

### How he signals priority

**By consequence, never by label.** *"Deploying it as its breaking UX for users"* (44);
*"High vulnerabilities need to be taken care of in priority"* (SHOPZ-2865); *"It is
irritating for developers"* (22). Conversely, de-prioritising is equally blunt: *"Parking
it for now"* (42), *"This is not a high priority as there is no strict deadline"*
(SHOPZ-4857). He does not write P0/P1 or "Priority: Low" — the one Jira description that
does (*"Low (No functional impact, but good housekeeping)"*) is agent-written.

### How he closes

- To a person: **"Let me know"** / **"Let me know what you think"** / **"Let me know if the
  behaviour doesn't make sense"** — the single most reliable closing formula.
- On a ticket: **"Closing this as …"** / **"The work is completed here."** / **"Parking it
  for now."**
- Thanks are terse and slightly off-register: **"Thanks eitherways."**
- Apologies are frequent and lead the message: **"Apologies for seeing this late."**,
  **"Apologies. I have updated it to the latest status."**

### Impact, reasoning, hedging

- **Commits state the action only.** ~1 in 15 subjects carries a "to X" purpose clause
  (15); **none** carry a "this ensures/prevents X" consequence clause.
- **Jira states the reasoning, but as narrative, not as a labelled section.** The
  `Currently, X … We need / We can Y` frame does the work of a Context+Proposal template
  without any headers.
- **He hedges heavily in prose and not at all in commits.** "I feel", "I am not sure",
  "seem to", "possible explanation", "if useful", "it is very less likely", "I suspect".
  A commit subject is an assertion; a Jira comment is a proposal.
- **He puts the recommendation inline rather than in a Recommendation block** — see
  `- easy to do` tacked onto option 1 in (30).

### Technical shorthand

- **Tickets in commits**, three drifting forms: `SHOPZ-2874: Subject` (97, earliest),
  `feat: [SHOPZ-3122]: Subject`, `feat: [SHOPZ-3122] Subject` (160). `SHOPZ-0000` = no
  ticket. Typo'd to `SHOP-` twice. **178 of 414 clean-window subjects carry no ticket at all.**
- **Tickets in Jira**: bare key inline mid-sentence (*"In SHOPZ-3843, we added…"*,
  *"Following from SHOPZ-3756 where we…"*), or a pasted full Atlassian URL.
- **PRs**: bare `(#2118)` appended by GitHub's squash. In prose he says *"the previous PR"*
  or pastes the full github.com URL — never "PR #2938".
- **Files/code**: pastes a **full GitHub permalink with `#L34-L37`** rather than citing
  `path/file.tsx:34`. This is the inverse of the agent habit and a reliable discriminator.
- Lowercase for repos and apps: `szero`, `nth`, `neohub`, `nub-track`. Calls himself **"abhi"**.
- Conventional-commit prefixes are **inconsistent**: 267 of 445 have none; `feat:` 123,
  `fix:` 52, long tail of 1–2 (`docs`, `chore`, `style`, `refactor`, `test`, one `copy:`).
  Scopes (`fix(rma-edit):`) appear rarely and only mid-2025.

### Vocabulary

- **Recurring**: `Currently, …`, `As of today, …`, `We need to`, `The plan is to`,
  `Let me know`, `I'm assuming`, `Not sure if`, `for eg.`, `Lets`, `Also, …` as a
  sentence-opener, `Parking it for now`, `Fix lint`, `Fix tests`, `Update UI`,
  `Minor updates`, `Addressed PR comments`.
- **Distinctive word choices**: "weird" (behaviours, issue, alignment, errors) — used
  constantly; "irritating"; "unwanted" for unused; "neat" for clean; "Readme";
  "type proof" for type-safe; "Bonus:" for scope creep.
- **Indian-English markers**: `it is very less likely`, `eitherways`, `Do we have any test
  order`, `he can continue to send more otp` (generic "he" for the user), `Apologies` as a
  standalone, `Kindly`-adjacent politeness without the word.
- **Filler he never uses**: comprehensive, robust, ensure, leverage, properly, correctly,
  as expected, under the hood, gracefully, surface (as a verb), holistically. (`comprehensive`
  appears in his commit stream exactly once — 2025-11-14, agent.)

### Differences across surfaces

Now answerable for two of three:

| | commits | Jira |
|---|---|---|
| length | 1 line, 13–67 chars | 1–4 sentences |
| body | essentially never | always, brief |
| person | impersonal imperative | first person "I", collective "we" |
| hedging | none | heavy |
| reasoning | omitted | narrated ("Currently X / We need Y") |
| addressed to | no one | a named person, @-mentioned first |
| closing | none | "Let me know" |

The register shift is large. A voice system that learns only from his commits would produce
clipped impersonal fragments; only from Jira, chatty hedged prose. **GitHub review voice is
the missing third point** and is likely nearest the Jira register (both are addressed to a
person), but that is an inference, not an observation.

---

## Insufficient evidence

1. **GitHub review comments on other people's PRs** — the single highest-value missing
   source, since reviewing others is the least-delegated act. Got through: a background
   miner was dispatched against `narvar/shopify-zero-retailer` and `narvar/denali`
   (`gh search prs --reviewed-by` / `--commenter`, then `pulls/<N>/comments` +
   `issues/<N>/comments` + `pulls/<N>/reviews`, filtered to `user.login ==
   abhinavjainnarvar` on PRs authored by others). **It had not reported when I was told to
   finish. 0 samples classified.** To finish: re-run that enumeration restricted to
   `created < 2025-08-01`, then classify. Expect the Jira comment register (§C) to
   transfer; expect *inline* comments to be shorter still.
2. **His PR descriptions** — same miner, same gap. **0 samples.** Note the risk: PR bodies
   are the most-delegated artifact of all, so even pre-2025-08 ones need the em-dash /
   bold-header / `file:line` screen, not just a date filter.
3. **Real-time conversational register** — greetings, banter, interruption, frustration,
   thinking aloud. Jira comments are the closest proxy here and they are still
   asynchronous and semi-formal. The transcript corpus (`corpus.md`) is the only source for
   this, and this file cannot cross-check it.
4. **How he responds to being wrong at length.** I have "Good catch … I have updated the PR"
   (51) and "Apologies for seeing this late" (49) — both one-liners. No sample of him
   conceding a substantive technical argument.
5. **Long-form writing** — design docs, RFCs. His Denali migration plan lives in Google
   Docs (linked from SHOPZ-4926) and was not read. That is the one place his extended
   argumentative voice would exist.
6. **denali as a voice source** — permanently unavailable; his authorship there begins
   2026-04-21, entirely inside the agent era.

### How to use this file against `corpus.md`

Falsifiable predictions the transcript corpus should agree with:

- **Zero em-dashes.** 580 human samples, zero occurrences. If the transcript corpus shows
  him writing em-dashes, that finding is contaminated.
- No bold headers, no tables, no `file:line` citations. He pastes GitHub permalinks with
  `#L34-L37` instead.
- Short messages; frequent sub-5-word ones; occasional all-lowercase.
- `Lets`, `its`, `for eg.`, `eitherways`, `weird`, `irritating`, `Currently,`, `As of
  today,`, `Also,` as a sentence-opener, `Let me know`, `I'm assuming`, `Not sure if`,
  `Parking it for now`, `szero`, `nth`, `abhi`, `Readme`.
- Missing final periods; missing space before `(`; typos that repeat.
- Priority expressed as consequence, never as a label.
- Critique opens hedged and ends by handing the decision back.
- Never: comprehensive, robust, ensure, leverage, properly, gracefully, as expected.
