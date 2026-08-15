# Repo Report — 12-factor-agents

> Authority boundary: This repository report is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.


> **Path:** `_research/upstreams/12-factor-agents`
> **SHA:** `d20c728368bf9c189d6d7aab704744decb6ec0cc` (`git -C 12-factor-agents rev-parse HEAD`)
> **License:** Split grant, stated in two places and consistent. `LICENSE` is Apache-2.0
> (`LICENSE:1-3`). `README.md:254-258` says *"All content and images are licensed under a
> CC BY-SA 4.0 License"* / *"Code is licensed under the Apache 2.0 License"*. Since the
> substance here is prose, **the parts we would quote are CC-BY-SA-4.0** — attribution plus
> share-alike on derivatives of the text. The code snippets are illustrative Python/BAML
> under Apache-2.0. Practical consequence: paraphrase and cite; do not lift paragraphs into
> our spec verbatim without attribution.
> **Size:** 499 tracked files (`git ls-files | wc -l`) — but only 15 are content. The rest
> is `img/` and site scaffolding.
> **Read this pass:** all 13 content files in full (`content/factor-01` … `factor-12`,
> `appendix-13-pre-fetch.md`), `README.md` in full, `LICENSE` head. Confirmed the nine
> single-digit filenames (`factor-1-…` … `factor-9-…`) are one-line redirect stubs, not
> content: `content/factor-1-natural-language-to-tool-calls.md:1` is
> `[Moved to factor-01-natural-language-to-tool-calls.md](./factor-01-…)`. Prior coverage
> was 4 of 13; this pass is 13 of 13.

## 1. What this repo is

A **methodology** — 1,500 lines of markdown, no runtime, no package. It argues that
production-grade LLM software is *mostly ordinary deterministic software* with LLM calls
placed deliberately, and enumerates twelve engineering properties that make that work.
Its own framing is anti-framework: *"Going all in on a framework and building what is
essentially a greenfield rewrite may be counter-productive"* (`README.md:186`). That framing
is why it is a genuinely awkward upstream for us: **we are a framework consumer by hard
constraint**, and several factors are instructions to be a framework author.

## 2. Mechanism inventory

Grades here mean: **A** = the file says exactly this at this line; **C** = our reading of
what it implies. Nothing in this repo executes, so no claim can be higher than "the text
says so".

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| F1 | NL → structured tool call | Translate an utterance into a typed call object; deterministic code dispatches on it | `factor-01-natural-language-to-tool-calls.md:5-31` | A |
| F2 | Prompts as first-class code | Reject "black box" `Agent(role=…, goal=…)` constructors; template prompts in-repo, test them like code | `factor-02-own-your-prompts.md:13-31`, `:77-83` | A |
| F3 | Own the context window | The message array is not sacred. Pack history into a custom (e.g. XML-ish) format chosen for token- and attention-efficiency | `factor-03-own-your-context-window.md:69-71`, `:120-140` | A |
| F3b | Hide resolved errors | *"Consider hiding errors and failed calls from context window once they are resolved"* | `factor-03-own-your-context-window.md:230` | A |
| F4 | Tools = discriminated union on `intent` | Per-variant required fields; LLM emits JSON, code decides execution | `factor-04-tools-are-structured-outputs.md:11-34` | A |
| F5 | Unify execution + business state | Don't keep a separate step/retry/waiting struct; infer execution state from the thread | `factor-05-unify-execution-state.md:11-26` | A |
| F6 | Launch/pause/resume as an API | Pause specifically *between tool selection and tool invocation* | `factor-06-launch-pause-resume.md:17-27` | A |
| F7 | Human contact is a tool call | `request_human_input` / `done_for_now` as first-class *intents*, not prose replies | `factor-07-contact-humans-with-tools.md:17-46` | A |
| F8 | Own your control flow | Hand-write the loop so you can break on specific intents, compact, judge, rate-limit, durably sleep | `factor-08-own-your-control-flow.md:10-18`, `:27-69` | A |
| F9 | Compact errors + consecutive-error counter | Append the error to context and retry; cap at ~3 consecutive, then break/escalate | `factor-09-compact-errors.md:31`, `:33-62` | A |
| F10 | Small focused agents, 3–20 steps | *"keeping agents focused on specific domains with 3-10, maybe 20 steps max"* | `factor-10-small-focused-agents.md:9` | A |
| F11 | Trigger from anywhere | Slack/email/SMS/cron entry points; outer-loop agents | `factor-11-trigger-from-anywhere.md:9-15` | A |
| F12 | Stateless reducer | Agent as `foldl` over events. Author's own note: *"This one is mostly just for fun."* | `factor-12-stateless-reducer.md:5` | A |
| F13 | Pre-fetch known context | *"If you already know what tools you'll want the model to call, just call them DETERMINISTICALLY"* | `appendix-13-pre-fetch.md:147` | A |

## 2b. Factor-by-factor verdict against our design

The task asked for all thirteen, each with: the claim, whether OMP already satisfies it,
and what it implies for us. Reading down this table is the fastest way to see that this
repo splits cleanly into *already-true-for-free*, *actionable*, and
*structurally-unavailable-to-us*.

| # | Their claim, compressed | Does OMP already satisfy it? | Implication for us |
|---|---|---|---|
| F1 | Convert NL to typed calls | **Yes, entirely.** Native tool-calling is the runtime's substrate | None. This is table stakes in 2026 and the factor reads as dated |
| F2 | Own your prompts; don't accept a framework's | **Partly — and this is the sharp one.** We do own agent bodies and workflow commands. We do *not* own `prompts/system/system-prompt.md`, the yield ladder, or the skill-listing renderer | **Adopt the discipline within our layer.** Every string we control is version-controlled markdown. Where OMP owns the string, record *that we don't own it* rather than pretending we tuned it |
| F3 | Own the context window; custom formats beat message arrays | **No, and we cannot.** OMP assembles the wire format | Only the *sub-lever* is available: we own what goes *into* a task packet and a result contract. See §3 |
| F3b | Hide resolved errors from context | **No.** OMP's history is append-only from our seat | Attaches to the *coordinator*: a worker's failed-attempt narrative should not be relayed into the main thread once superseded. This is a result-contract rule, not a runtime feature |
| F4 | Tools = discriminated union on `intent` | Partly. Our agent `output:` frontmatter carries structured output; whether it is a *tagged union* is a schema choice we make | Already reflected (per `spec/key/02 §D-3`). The remaining delta is per-variant *required* fields — a partial result and a completion should not validate against the same shape |
| F5 | Unify execution state and business state | **Yes, by accident.** The session transcript *is* the state; there is no second store we maintain | Confirms a non-decision. It also forbids one: any `.omp/state/*.json` progress ledger we might invent would violate F5 *and* rule 4 (no OMP consumer) |
| F6 | Launch/pause/resume, esp. between tool selection and invocation | **No.** `task` spawns run to completion or to a limit | Out of scope by the single-runtime constraint. Worth recording as a *known gap*, not a backlog item |
| F7 | Human contact via tool call | Partly. The permission prompt is OMP's; a worker cannot ask the user a question mid-run | Implication for topology: a worker that needs a human decision must **yield with a question**, not stall. That is a result-contract state we should name |
| F8 | Own your control flow | **No — structurally forbidden for us** | See §4. This is the factor that most directly contradicts our design |
| F9 | Compact errors, cap consecutive at ~3 | Partly. `MAX_SCHEMA_RETRIES = 3` matches the number for schema failures only | The generalization — *n consecutive failures of the same kind is a stop condition, not a retry* — is a coordinator rule we can write. See §3 |
| F10 | Small agents, 3–20 steps | **We satisfy this by design** (4 narrow workers) | Strongest external support for our topology. But note their bound is **steps**, not tokens; our budget model is tokens. See §5 |
| F11 | Trigger from anywhere (Slack/email/cron) | N/A — this is the vendor's product pitch (`factor-11:5` opens *"If you're waiting for the humanlayer pitch, you made it"*) | Reject. Not a defect; just not our problem |
| F12 | Agent as stateless reducer | N/A; author self-deprecates it | Reject as a mechanism. Keep as vocabulary |
| F13 | Pre-fetch context you know you'll need | **No, and this is the most under-used idea here** | Directly actionable on task packets. See §3 |

## 3. Transferable to omp-custom

Four rows survive rule 4. Each names where it attaches. Note that all four attach to
**things we author** (task packets, result schemas, coordinator checks) — none needs a
runtime change, which is exactly why they survive.

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| **F13 pre-fetch** — resolve deterministically-knowable facts before spawning, and put them in the packet | The `context` field of a `task` spawn (`task/executor.ts:3034` renders `context` into the subagent system prompt) | `per-spawn`, and **net-negative** in most cases | **ADOPT** | A worker that must `git rev-parse`, `ls`, and locate the test command spends 3–5 turns discovering what the coordinator already knew. Their line is the argument: *"just call them DETERMINISTICALLY and let the model do the hard part of figuring out how to use their outputs"* (`appendix-13-pre-fetch.md:147`). Paying ~200 packet tokens to remove ~3 discovery round-trips is the trade |
| **F9 consecutive-failure cap, generalized** — *n* same-kind failures ends the attempt instead of retrying | Coordinator logic in `/standard` and `/orchestrated`; the counter lives in the main session's own reasoning, not in a file | `zero` (a rule in a command body already in context) | **ADOPT** | We already have the number for one case (`MAX_SCHEMA_RETRIES = 3`). Their point is that the *pattern* generalizes: verifier fails the same way twice ⇒ the task is mis-partitioned, and a third spawn is tokens spent to learn nothing. Directly serves tokens-per-accepted-outcome |
| **F4 per-variant required fields** — a partial result must not satisfy the completion schema | Agent `output:` frontmatter (already our structured-output mechanism per `spec/06`) | `zero` (schema text already paid for) | **ADAPT** | The union *tag* is less valuable than the *per-variant required set*. If `status: complete` requires `verification_results` while `status: partial` does not, a forced partial yield (KD-011) fails validation instead of arriving as a plausible completion. This is the false-completion metric expressed as a schema constraint |
| **F3b hide resolved errors** — restated as a *relay* rule | Worker result contract + coordinator relay discipline | `zero`; saves `persistent` tokens in the main thread | **ADAPT** | We cannot edit history, but we control what a worker's result *says* and what the coordinator *repeats*. A worker that fixed its own false start should report the outcome, not the false start. Every line a worker narrates about a superseded attempt is paid again in the coordinator's context and again in the next worker's packet |

Two more are worth naming as **DEFER with a trigger** rather than silently dropping:

- **F2 applied to OMP's own strings.** *Trigger:* if L3 measurement attributes false
  completions to OMP's yield-ladder wording rather than to our agent bodies, then the
  `systemPrompt` override hook (`task/executor.ts:3031-3046`) becomes the attachment point
  and we start owning that string. Until measured, changing it is unpriced tuning.
- **F7 as a yield state.** *Trigger:* first observed instance of a worker stalling or
  guessing on a decision only the user can make. Then add a `needs_decision` variant to the
  result schema. Adding it pre-emptively is speculative.

## 4. What this repo does that we deliberately will not

**F8 — own your control flow. This factor contradicts our architecture, in its own words.**

> *"Build your own control structures that make sense for your specific use case."*
> — `factor-08-own-your-control-flow.md:10`

The factor then lists what owning the loop buys: *"summarization or caching of tool call
results / LLM-as-judge on structured output / context window compaction or other memory
management / logging, tracing, and metrics / client-side rate limiting / durable sleep /
pause / 'wait for event'"* (`:12-17`). We have **none** of those levers, and by our hard
constraint we may not build them. The escalation is explicit:

> *"the number one feature request I have for every AI framework out there is we need to be
> able to interrupt a working agent and resume later, ESPECIALLY between the moment of tool
> **selection** and the moment of tool **invocation**."* — `:73-74`

And the consequence they name for lacking it:

> *"you're forced to either: 1. Pause the task in memory … 2. Restrict the agent to only
> low-stakes, low-risk calls like research and summarization 3. Give the agent access to do
> bigger, more useful things, and just yolo hope it doesn't screw up"* — `:77-81`

That trichotomy is a fair description of our position, and we should stop being defensive
about it: **our answer is (2)-with-a-check.** Workers do bounded work; the coordinator
verifies before accepting. We do not get selection-time interception, so we buy safety at
the *acceptance* boundary instead of the *invocation* boundary. That is strictly weaker —
a worker can do a bad thing and we find out after — and the honest mitigation is the
diff-reviewer, not a claim that we solved it.

**F3 — own your context window.** Rejected for the same reason: OMP builds the wire format.
Attempting a custom packing format would mean a second prompt assembler, i.e. a second
runtime.

**F6 / F11 / F12.** F6 is unavailable (above). F11 is the vendor's product surface and
irrelevant to a template. F12 is disclaimed by its own author as *"mostly just for fun"*
(`factor-12-stateless-reducer.md:5`) — adopting it would be folder-shape envy applied to
vocabulary.

**F5, deliberately as a prohibition.** We satisfy F5 today by having no separate state
store. The value of recording it is that it forecloses a tempting future addition: a
`.omp/state/` progress ledger to "help workers resume". That would separate execution state
from business state (F5 violation) *and* have zero runtime consumers (rule 4) — the exact
`.omp/policies/` failure mode, twice over.

## 5. Contradictions with our current spec or registry

**5.1 `spec/key/02-repo-synthesis.md:481-483` under-claims this repo, and the under-claim
is the finding.** The recorded delta for `12-factor-agents` is the F4 discriminated union
(D-3). Having now read all thirteen factors, the highest-value content is **F13 pre-fetch**,
which appears nowhere in `spec/key`. F13 is not a philosophy — it is a concrete instruction
about what to put in a spawn packet, it has a named OMP attachment point, and it is
plausibly net-negative in tokens. Recording only F4 from a 13-factor document is the same
coverage failure the `repos/` folder was created to fix.

**5.2 A cost ceiling is confirmed absent here too, so `spec/key/02:475` stands.** That
entry says a cost ceiling *"has no verified OMP equivalent"* and grades the absence D
(*"Do not assert its absence"*). 12-factor-agents also has no cost ceiling — its bound is
consecutive errors (F9), not spend. So this repo neither supports nor refutes that
grade-D. Recorded so a future reader does not mistake two upstreams' silence for evidence.

**5.3 A units mismatch our token model should acknowledge.** F10 bounds an agent at
*"3-10, maybe 20 steps max"* (`factor-10-small-focused-agents.md:9`) — **steps**. `spec/05`
budgets **tokens**, and KD-011 bounds workers by **requests** (`task.softRequestBudget`).
These are three different units for one concept. The step count is the one that predicts
context-window degradation, which is the stated mechanism: *"As context grows, LLMs are
more likely to get lost or lose focus"* (`:11`). Not a falsified claim — a missing
conversion. If a `/standard` worker is sized at 20 steps and OMP stops it at 200 requests,
the *runtime* limit is ~10× looser than the *quality* limit, meaning the request budget will
essentially never be the thing that protects output quality. Worth stating explicitly in
`spec/05` rather than leaving the reader to assume `softRequestBudget` is a quality guard.
It is a runaway guard.

**No claim in `spec/00-16` or `registry/*` is made false by this repo.** The finding is
omission, not error.

## 6. Cost profile

| §3 row | Where the token is paid | Estimate and basis |
|---|---|---|
| F13 pre-fetch | `per-spawn`, in the packet's `context` field | ~100–300 tokens added per spawn (**estimate**; basis: a rendered pre-fetch block of repo root, branch, test command, and 3–6 relevant paths, measured as prose at ~1.3 tokens/word). Offsets 2–5 worker discovery turns. A discovery turn that reads two files costs far more than 300 tokens, so the trade is favorable whenever ≥1 turn is removed |
| F9 consecutive-failure cap | `zero` marginal — the rule lives in a workflow command body already loaded when the command runs | Saves one whole worker spawn on each hit. A `/standard` implementer spawn is the largest single unit of spend in our model, so this is the highest-leverage zero-cost row in the report |
| F4 per-variant required fields | `zero` marginal — the `output:` schema is already in the agent's frontmatter; this changes its *content*, not its size | May *reduce* size: `status: partial` variants need fewer required fields than a monolithic always-required schema. Real cost is authoring effort, plus a rejection path the coordinator must handle |
| F3b relay discipline | `zero` to state; saves `persistent` tokens in the coordinator | **Estimate, weakly grounded.** Savings scale with how chatty workers are about self-corrections, which we have not measured. Do not put a number on this before L3 |

Nothing here needs a new file, a new tool, or a runtime change. That is the clean read on
this upstream: its transferable content is **rules for text we already write**, which is the
cheapest possible class of adoption and the reason it survives rule 4 at all.

## 7. Coverage and limits  (MANDATORY)

**Files read in full (15):**
- `README.md`
- `content/factor-01-natural-language-to-tool-calls.md`
- `content/factor-02-own-your-prompts.md`
- `content/factor-03-own-your-context-window.md`
- `content/factor-04-tools-are-structured-outputs.md`
- `content/factor-05-unify-execution-state.md`
- `content/factor-06-launch-pause-resume.md`
- `content/factor-07-contact-humans-with-tools.md`
- `content/factor-08-own-your-control-flow.md`
- `content/factor-09-compact-errors.md`
- `content/factor-10-small-focused-agents.md`
- `content/factor-11-trigger-from-anywhere.md`
- `content/factor-12-stateless-reducer.md`
- `content/appendix-13-pre-fetch.md`
- `content/factor-1-natural-language-to-tool-calls.md` (1-line stub; diffed against
  `factor-01` to confirm the single-digit files are redirects, not alternate content)

**Files sampled (head/grep only):**
- `LICENSE` — first 20 lines, enough to confirm Apache-2.0 boilerplate
- OMP cross-checks, opened only to verify the attachment points I claim in §3:
  `oh-my-pi/packages/coding-agent/src/task/executor.ts:3020-3059` (the `context` and
  `systemPrompt` spawn options)

**Not opened:**
- `content/brief-history-of-software.md` (178 lines). It is narrative framing — DAGs →
  agents-as-loops. I read the compressed version of the same argument in `README.md:82-147`.
  **If it contains a mechanism, I would have missed it.** I judge that unlikely from the
  title and the README's summary, but that is a judgment, not a verification.
- All ~480 files under `img/` — screenshots and GIFs. Several factors carry meaning in
  images (F5's animation, F9's GIF, F12's two diagrams). **F12 in particular is
  substantially image-only**: its 12 lines of text are two image embeds plus a disclaimer.
  My "reject as a mechanism" verdict on F12 therefore rests on the author's own
  self-deprecation, not on having seen what the diagrams show.
- Site scaffolding (Next.js config, package files).

**Claims that need a live run before use:**
- The F13 pre-fetch cost estimate (~100–300 tokens/spawn) and, more importantly, the claim
  that it is *net-negative*. Both need L3 measurement: pre-fetch vs. no-pre-fetch on the
  same task, comparing total tokens to accepted outcome. Until then the direction is
  reasoned, the magnitude is not.
- Whether F4's per-variant required fields actually catch a forced partial yield in
  practice. That needs a deliberately budget-exhausted worker (KD-011's scenario) and an
  observation of whether the truncated result fails schema validation or slips through.

**Anything I suspect but could not verify:**
- I suspect F9's "~3" is folklore rather than a measured threshold. The text offers no
  measurement — *"You may want to implement an errorCounter … to limit to ~3 attempts …
  or whatever other logic makes sense for your use case"* (`factor-09-compact-errors.md:31`).
  That OMP independently uses 3 for `MAX_SCHEMA_RETRIES` is convergence, not corroboration.
  If we adopt 3, we adopt an unmeasured constant. Flagging it because this project has
  already been burned once by treating a plausible number as a verified one.
- I suspect F10's "3-10, maybe 20 steps" is likewise unmeasured; no citation accompanies it.
  It is the single external claim most load-bearing for our 4-worker topology, and it is
  grade-A-as-text but grade-D-as-evidence. Our topology should not be justified *primarily*
  by this sentence.
