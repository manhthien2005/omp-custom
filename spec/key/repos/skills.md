# Repo Report — skills (anthropics/skills)

> Authority boundary: This repository report is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.


> **Path:** `_research/upstreams/skills`
> **SHA:** `b29e7cf65e5cb78a5ac33d582270551bc74a14eb`
> **License:** **Split, verified per-file.** No root LICENSE (`ls -a` shows only
> `.claude-plugin`, `.gitignore`, `README.md`, `skills`, `spec`, `template`,
> `THIRD_PARTY_NOTICES.md`). 16 of 17 skill directories carry their own `LICENSE.txt`:
> **12 are Apache-2.0** (`algorithmic-art`, `brand-guidelines`, `canvas-design`, `claude-api`,
> `frontend-design`, `internal-comms`, `mcp-builder`, **`skill-creator`**, `slack-gif-creator`,
> `theme-factory`, `webapp-testing`, `web-artifacts-builder`); **4 are proprietary** —
> `docx`, `pdf`, `pptx`, `xlsx`, each opening "© 2025 Anthropic, PBC. All rights reserved."
> `doc-coauthoring` has **no** license file at all. Frontmatter mirrors this:
> `license: Complete terms in LICENSE.txt` on the Apache ones,
> `license: Proprietary. LICENSE.txt has complete terms` on the four
> (e.g. `skills/xlsx/SKILL.md` frontmatter, `skills/pdf/SKILL.md` frontmatter).
> **Consequence: `skill-creator` and everything under it is Apache-2.0 and may be copied with
> attribution + NOTICE.**
> **Size:** 411 tracked files (`git ls-files | wc -l`) — but 245 of those are `.ttf`/OFL font
> files under `skills/canvas-design/canvas-fonts/` and OOXML `.xsd` schemas triplicated across
> `docx`/`pptx`/`xlsx`. Non-font, non-schema markdown+code is ~120 files.
> **Read this pass:** `skills/skill-creator/SKILL.md` (485L, full); all three
> `skill-creator/scripts/{run_eval.py,improve_description.py,run_loop.py}` (full);
> `skill-creator/agents/grader.md` (full); `skill-creator/references/schemas.md` (full);
> `template/SKILL.md`; `spec/agent-skills-spec.md`; all 17 skill frontmatters with line/word
> counts; every `LICENSE.txt` header.

## 1. What this repo is

Anthropic's **first-party skill collection and packaging reference** — 17 skills, most of them
capability wrappers around file formats and rendering (`docx`, `pdf`, `pptx`, `xlsx`,
`canvas-design`, `theme-factory`, `slack-gif-creator`, `web-artifacts-builder`). Two are
different in kind: `claude-api` is a pure reference skill with an aggressive routing trigger,
and **`skill-creator` is a meta-skill with a working automated description optimizer** — the
only executable trigger-eval loop in the entire five-repo corpus. The repo's thesis is that a
SKILL.md body is an *index* over bundled scripts and reference files, and that the description
is the load-bearing artifact because it is the only thing always in context.

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| A-1 | **Automated description optimizer** | Full closed loop: eval → improve → re-eval, up to N iterations, returning the best description | `skill-creator/scripts/run_loop.py:47-241` | A |
| A-2 | **Trigger eval by synthetic command file** | Writes a temp `.claude/commands/<name>-skill-<uuid8>.md` carrying only `description:` + a one-line body, so the description enters `available_skills`, then runs `claude -p <query>` and watches the stream for a `Skill` or `Read` tool call naming that file | `run_eval.py:51-68`, detection at `:133-168`, cleanup at `:179-181` | A |
| A-3 | **Early-exit stream detection** | Uses `--include-partial-messages` and returns as soon as `content_block_delta`'s accumulated `input_json` contains the skill name — and returns **False immediately** if the first tool_use is anything other than `Skill`/`Read` | `run_eval.py:133-141` (`else: return False`), `:143-148` | A |
| A-4 | **Trigger rate over repeated runs, thresholded** | `--runs-per-query` default **3**; `trigger_rate = triggers/runs`; pass is `rate >= 0.5` for positives and `rate < 0.5` for negatives | `run_eval.py:227-242`, defaults at `:266-267` | A |
| A-5 | **Train/test split, stratified, blinded** | 40% holdout (`--holdout 0.4`), stratified by `should_trigger`, seed 42; **the improver never sees test scores** — history is filtered with `{k: v for k, v in h.items() if not k.startswith("test_")}` | `run_loop.py:24-44`, blinding at `:194-198` | A |
| A-6 | **Best-by-test-score selection** | Winner chosen on the held-out set, not the train set: `best = max(history, key=lambda h: h["test_passed"] or 0)` | `run_loop.py:216-222` | A |
| A-7 | **Improver prompt: generalize, don't enumerate** | "what I DON'T want you to do is produce an ever-expanding list of specific queries… Instead, try to generalize from the failures to broader categories of user intent" — with **the token cost given as the reason**: "it's injected into ALL queries and there might be a lot of skills, so we don't want to blow too much space on any given description" | `improve_description.py:127-132` | A |
| A-8 | **Hard length ceiling with a self-healing retry** | Prompt states "not more than about 100-200 words… hard limit of 1024 characters". If output still exceeds 1024, one fresh call quotes the too-long version back and asks for a rewrite | `improve_description.py:132`, retry at `:163-182` | A |
| A-9 | **Four description rules, stated to the improver** | (1) imperative — "Use this skill for" not "this skill does"; (2) focus on **user intent**, not implementation; (3) "**competes with other skills for Claude's attention** — make it distinctive"; (4) on repeated failure, change sentence structure entirely | `improve_description.py:134-140` | A |
| A-10 | **Deliberate style variance across iterations** | "be creative and mix up the style in different iterations since you'll have multiple opportunities… we'll just grab the highest-scoring one at the end" | `improve_description.py:140` | A |
| A-11 | **Anti-overfit failure feedback format** | Failures are fed back as two labelled buckets with per-query trigger counts: `FAILED TO TRIGGER (should have triggered but didn't)` and `FALSE TRIGGERS (triggered but shouldn't have)`, each `"query" (triggered N/M times)` | `improve_description.py:91-101` | A |
| A-12 | **Previous-attempt memory with an anti-repeat instruction** | "PREVIOUS ATTEMPTS (do NOT repeat these — try something structurally different)" plus each attempt's score and per-query results | `improve_description.py:103-118` | A |
| A-13 | **Full transcript logging of every improve call** | Writes `improve_iter_<n>.json` with prompt, response, parsed description, `char_count`, `over_limit`, and any rewrite round | `improve_description.py:149-189` | A |
| A-14 | **Precision/recall/accuracy per iteration** | Verbose mode computes tp/fn/fp/tn over *runs* (not queries) and prints `precision=… recall=… accuracy=…` per train and test set | `run_loop.py:154-171` | A |
| A-15 | **Negative-query design rules** | 20 queries, 8-10 each way. Negatives must be **near-misses**: "queries that share keywords or concepts with the skill but actually need something different… adjacent domains, ambiguous phrasing where a naive keyword match would trigger but shouldn't". Explicit anti-rule: "'Write a fibonacci function' as a negative test for a PDF skill is too easy — it doesn't test anything" | `skill-creator/SKILL.md:339`, `:356-358` | A |
| A-16 | **Realistic-query rule with a worked contrast** | Bad: `"Format this data"`. Good: a 60-word first-person query with a filename typo, a guessed path, and column letters. Rules include lowercase, abbreviations, typos, casual speech, mixed lengths | `skill-creator/SKILL.md:348-352` | A |
| A-17 | **"Claude only consults skills it can't easily handle"** | Simple one-step queries may not trigger *regardless of description quality*, so they are poor test cases. Directly shapes fixture design | `skill-creator/SKILL.md:396-400` | A |
| A-18 | **Undertrigger correction: make descriptions "pushy"** | "Claude has a tendency to 'undertrigger' skills… please make the skill descriptions a little bit 'pushy'", with a before/after that appends "Make sure to use this skill whenever the user mentions X, Y, Z, even if they don't explicitly ask for a 'dashboard.'" | `skill-creator/SKILL.md:67` | A |
| A-19 | **Anti-MUST writing style** | "Try to explain to the model why things are important in lieu of heavy-handed musty MUSTs"; and "If you find yourself writing ALWAYS or NEVER in all caps, or using super rigid structures, that's a **yellow flag**" | `skill-creator/SKILL.md:139`, `:302` |A |
| A-20 | **Three-level progressive disclosure, named** | Metadata (always, ~100 words) → SKILL.md body (on trigger, <500 lines) → bundled resources (unlimited; "scripts can execute without loading") | `skill-creator/SKILL.md:86-98` | A |
| A-21 | **Baseline pairing enforced in the same turn** | "For each test case, spawn two subagents in the same turn — one with the skill, one without. This is important: don't spawn the with-skill runs first and then come back for baselines later" | `skill-creator/SKILL.md:169-186` | A |
| A-22 | **Snapshot-as-baseline for skill edits** | When *improving* a skill, `cp -r <skill-path> <workspace>/skill-snapshot/` **before editing** and point the baseline agent at the snapshot | `skill-creator/SKILL.md:186` | A |
| A-23 | **Grader must reject surface compliance** | PASS requires "the evidence reflects genuine task completion, not just surface-level compliance"; FAIL includes "correct filename but empty/wrong content" and "meets the assertion by coincidence" | `agents/grader.md:39-40`, `:92-97` | A |
| A-24 | **Grader extracts and verifies *unstated* claims** | Beyond the given expectations, pull factual/process/quality claims out of the transcript and verify each, flagging the unverifiable | `agents/grader.md:43-59`, schema at `:152-165` | A |
| A-25 | **Grader critiques the eval set itself** | "A passing grade on a weak assertion is worse than useless — it creates false confidence." Emits `eval_feedback.suggestions` naming non-discriminating assertions | `agents/grader.md:9`, `:68-79`, `:171-182` | A |
| A-26 | **Burden of proof on the expectation** | "When uncertain: The burden of proof to pass is on the expectation." No partial credit | `agents/grader.md:99`, `:223` | A |
| A-27 | **Repeated-work signal → bundle a script** | "If all 3 test cases resulted in the subagent writing a `create_docx.py`… that's a strong signal the skill should bundle that script" | `skill-creator/SKILL.md:304` | A |
| A-28 | **Read transcripts, not just outputs** | "if it looks like the skill is making the model waste a bunch of time doing things that are unproductive, you can try getting rid of the parts of the skill that are making it do that" | `skill-creator/SKILL.md:300` | A |
| A-29 | **`claude-api`'s TRIGGER/SKIP description** | A description that is a routing *program*: a TRIGGER clause listing token patterns, an anticipatory counter-rationalization ("don't skip because it 'looks like a one-liner'"), and a SKIP clause naming the competing providers plus **a grep to run first**. 1,077 chars — the longest in the corpus | `skills/claude-api/SKILL.md` frontmatter (block scalar) | A |
| A-30 | **Explicit negative routing in descriptions** | `xlsx`: "Do NOT trigger when the primary deliverable is a Word document, HTML report, standalone Python script, database pipeline, or Google Sheets API integration, even if tabular data is involved." `docx`: "Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks" | `skills/xlsx/SKILL.md` frontmatter; `skills/docx/SKILL.md` frontmatter | A |
| A-31 | **Template is 6 lines** | The canonical new-skill template is frontmatter plus `# Insert instructions below`. No required sections, no rationalization table | `template/SKILL.md:1-6` | A |
| A-32 | **`spec/agent-skills-spec.md` is a 3-line stub** | Contains a heading and an external pointer only | `spec/agent-skills-spec.md` (3 lines total) | A |
| A-33 | **`quick_validate.py` / `package_skill.py`** | Structural validation and `.skill` packaging | `skill-creator/scripts/` (listed, **not read**) | D |

### The description-craft rules, consolidated

Because this is our highest-value question, here is every concrete rule this repo states about
writing a description, with citations. Note that several **contradict superpowers** — see §5.

| Rule | Source |
|---|---|
| Third person always; "inconsistent point-of-view can cause discovery problems" | `writing-skills/anthropic-best-practices.md:189-195` (vendored copy in superpowers; this repo's own statement is `skill-creator/SKILL.md:67`) |
| Include **both** what it does and when to use it | `skill-creator/SKILL.md:67`; anthropic-best-practices `:187`, `:199` |
| Imperative: "Use this skill for", not "this skill does" | `improve_description.py:135` |
| Focus on user **intent**, not implementation detail | `improve_description.py:136` |
| It **competes** with other skills — be distinctive and immediately recognizable | `improve_description.py:137` |
| ~100-200 words target; 1024 chars hard limit, truncated beyond | `improve_description.py:132` |
| Generalize from failures to categories of intent; never accumulate a query list | `improve_description.py:127-131` |
| Be "pushy" — Claude undertriggers | `skill-creator/SKILL.md:67` |
| Name the adjacent domain you do **not** own ("Do NOT trigger when…") | `skills/xlsx`, `skills/docx` frontmatter |
| For a reference skill, encode the skip condition as an executable check (a grep) | `skills/claude-api/SKILL.md` frontmatter |
| On repeated eval failure, change sentence structure, not just words | `improve_description.py:138` |

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| A-4 trigger rate over 3 runs, 0.5 threshold | `evals/triggers/<skill>.yml` schema (spec/11 §D) + spec/13 L3 | **zero** at runtime; tokens only when the eval is run | **ADOPT** | Our spec/11 §D stores one positive and one negative per skill with no repetition and no threshold. A single sample on a stochastic trigger is not a test. This is the cheapest correctness upgrade available |
| A-5 + A-6 train/test split, blinded, best-by-test | Same | zero | **ADOPT** | With 3 skills and ≤10 planned, our eval sets are small and overfitting is the default outcome. Blinding the improver is 4 lines of logic |
| A-11 failure feedback in two labelled buckets | Fixture result format | zero | **ADOPT** | Distinguishing false-negative from false-positive is what tells you whether to widen or narrow a description |
| A-14 precision/recall/accuracy | Eval report | zero | **ADAPT** | Useful; compute over runs not queries as they do. One extra function |
| A-15 near-miss negative rule | Every negative fixture we write | zero | **ADOPT** | Our current negatives ("Rename this variable" against `systematic-debugging`, spec/11 §D) are exactly the "too easy" case their rule forbids. This is a **defect in our spec**, see §5 |
| A-16 realistic-query rule | Fixture authoring guidance | zero | **ADOPT** | Our fixtures are terse abstractions; theirs are 60-word messy user turns. Cost is zero, realism is free |
| A-17 "simple queries don't trigger regardless" | Fixture authoring guidance | zero | **ADOPT** | Prevents us from writing fixtures that can never pass and then "fixing" descriptions to chase them |
| A-9 four description rules | `template/.omp/skills/*` frontmatter | **persistent** — this is the listing | **ADOPT** | Directly governs the ≤80-token-per-description and ≤900-token-sum budget |
| A-30 explicit negative routing | Our three (soon ≤10) descriptions | persistent | **ADOPT — already partly done** | Our shipped descriptions already carry `Do NOT activate for: …` (`template/.omp/skills/evidence-before-completion/SKILL.md:5`). Verified independently arrived at; this repo confirms it |
| A-1 + A-2 automated optimizer | spec/13 L3 harness | zero to hold; per-run model cost | **ADAPT, do not port** | The *loop* is exactly what we want. The *implementation* is `claude -p` + a synthetic `.claude/commands/` file — a Claude Code harness trick. OMP is our runtime; we would need an OMP-native equivalent (spawn a session with a listing containing only the skill under test). Trigger: when the library reaches 6+ skills, hand-tuning descriptions against a 900-token sum stops being tractable |
| A-8 self-healing length retry | Our description authoring | zero | **ADAPT** | Our ceiling is ~80 tokens (≈320 chars), far tighter than their 1024. Same retry shape, different constant |
| A-19 anti-MUST style | Our skill bodies | lazy | **DEFER** | Head-on collision with superpowers' authority principle and with our own Iron Law. See §4 |
| A-20 three-level disclosure | spec/11 skill inventory | persistent/lazy/zero | **ADOPT** | We already do this implicitly; naming the three levels with their cost tiers makes the budget arguments legible |
| A-21 baseline in the same turn | spec/13 L3 procedure | tokens per run | **ADOPT** | Cheap discipline that prevents drift between arms of a comparison |
| A-22 snapshot before editing | Skill-change procedure; pairs with `registry/skill-lock.yml` | zero | **ADOPT** | Makes "did this edit help?" answerable. Our skill-lock records a hash but no snapshot |
| A-23 + A-26 grader anti-surface-compliance | `diff-reviewer` contract (spec/10) and the L3 grader | lazy | **ADOPT** | *This is our enemy stated in someone else's words.* "correct filename but empty/wrong content"; "meets the assertion by coincidence"; "the burden of proof to pass is on the expectation" — all three are false-completion detectors |
| A-24 verify unstated claims | `diff-reviewer` contract | lazy | **ADOPT** | Extracting claims from a worker's report and checking each against the diff is precisely the anti-false-completion review we need. Their three types (factual/process/quality) are a usable taxonomy |
| A-25 grader critiques the eval set | spec/13 governance | zero | **ADAPT** | "A passing grade on a weak assertion is worse than useless." Applies to our L1/L2 static checks too |
| A-27 repeated-work → bundle a script | Skill-authoring guidance | zero | **DEFER** | Real signal, but we ship no skill scripts today and OMP script bundling is unverified. Trigger: first time two workers independently write the same helper |
| A-28 read transcripts not outputs | spec/13 procedure | zero | **ADOPT** | The check that catches a skill making a worker *waste* turns — a cost defect invisible in outputs |
| A-29 `claude-api` TRIGGER/SKIP form | Not for us at 1,077 chars | persistent | **REJECT (form), ADOPT (idea)** | The idea — an executable skip check inside a description — is excellent. At 1,077 chars it is ~270 tokens for one description, 30% of our entire listing budget. Take the pattern, not the length |
| A-31 6-line template | Our skill template | zero | **REJECT** | A template with no required sections produces bodies with no rationalization table. superpowers' and addyosmani's structured templates are strictly better for discipline skills |
| A-33 packaging scripts | — | — | **REJECT** | Harness. OMP is the runtime |

## 4. What this repo does that we deliberately will not

**Treat "pushy" descriptions as the default fix for undertriggering.**
`skill-creator/SKILL.md:67` instructs authors to append clauses like "Make sure to use this
skill whenever the user mentions dashboards, data visualization, internal metrics… even if
they don't explicitly ask for a 'dashboard.'" That works when the listing is paid once in a
main session. Under our verified multiplier every pushy clause is re-paid in every subagent,
and pushiness inflates length precisely where we have the least room. Our lever for
undertriggering is different and cheaper: `autoloadSkills` makes the gate unconditional for
the two agents that can produce a false completion (spec/11 §B), so we do not need the
description to win an attention contest.

**Descriptions in the 400-1,077 char range.** Measured across all 17 frontmatters: mean 437
chars, max 1,077 (`claude-api`), total 7,430 chars ≈ 1,857 tokens. That total alone is
**double our entire 900-token listing budget** for 17 skills. `xlsx` is 1,010 chars, `pptx`
991, `docx` 862. These are essays. Our ceiling of ~80 tokens (~320 chars) per description is
a different regime, and it is not a matter of being less thorough — it is that they pay once
and we pay 4-5 times.

**The `claude-api` description as a model.** Read it in full; it is genuinely clever
engineering — a TRIGGER list of literal token patterns, a pre-emptive counter to the "looks
like a one-liner" rationalization, a SKIP clause that names five competing providers, and an
instruction to run a specific `grep -rE` *before* reading any file. But it is ~270 tokens
resident forever, and its own SKIP logic exists because the TRIGGER is so broad it would
otherwise fire constantly. That is a description compensating for its own aggression. We take
the negative-routing idea and refuse the arms race.

**`skill-creator`'s conversational register.** The body is 485 lines / 5,205 words of
second-person prose: "Cool? Cool." (`:30`), "there's a trend now where the power of Claude is
inspiring plumbers to open up their terminals" (`:34`), "we are trying to create billions a
year in economic value here!" (`:306`), "Sorry in advance but I'm gonna go all caps here"
(`:451`). It is well-judged for a human-facing interactive tool. It is also ~7,000 tokens on
invocation, and roughly a third of the body is platform branching — Claude.ai (`:420-441`),
Cowork (`:445-455`), each restating the same loop with mechanics removed. We take the
scripts, the schemas, and the rules. We do not take the body.

**Four proprietary skills.** `docx`, `pdf`, `pptx`, `xlsx` are "All rights reserved". Read
their descriptions for *craft* only; copy nothing, quote nothing beyond fair citation. The
non-obvious risk is `skills/{docx,pptx,xlsx}/scripts/office/` — the OOXML validators and
helpers are triplicated across the three proprietary skills and are the most reusable-looking
code in the repo. They are not available to us.

**`spec/agent-skills-spec.md` as an authority.** It is 3 lines: a heading and a pointer. Any
recorded expectation that this path holds a specification is stale — see §5.

## 5. Contradictions with our current spec or registry

**1. Our negative trigger fixtures violate the rule this repo states (defect in spec/11 §D).**

Our claim, `spec/11-skills-rules-and-quality-gates.md:136-141`, defines the negative cases:

| Skill | Negative trigger (ours) |
|---|---|
| `evidence-before-completion` | "What does this function do?" |
| `systematic-debugging` | "Rename this variable" |
| `task-triage` | "Fix the typo on line 12" |

Their rule, `skill-creator/SKILL.md:358`: *"The key thing to avoid: don't make should-not-trigger
queries obviously irrelevant. 'Write a fibonacci function' as a negative test for a PDF skill
is too easy — it doesn't test anything. The negative cases should be genuinely tricky."*

All three of ours are the too-easy case, and one is close to their exact counter-example.
A useful negative for `evidence-before-completion` would be a near-miss: *"the build finished
and I'm reporting the failure — three tests are red"* (a status report about a failure, which
must **not** gate) versus the positive *"fix is in, tests pass"*. The current fixtures cannot
fail, so they measure nothing. **This is a real gap, not a wording preference.** Recommend
amending spec/11 §D with the near-miss rule and one worked near-miss per skill.

**2. Our fixture design has no repetition and no threshold.** spec/11 §D stores
`should_trigger` / `should_not_trigger` prompt lists. Trigger is model judgment over a
description — inherently stochastic. `run_eval.py:266` defaults to `--runs-per-query 3` with a
0.5 threshold (`:267`, applied at `:227-234`) precisely because single samples lie. Our schema
should carry `runs` and `threshold` fields or we will chase noise. Not a false claim in the
spec — an omission with the same effect.

**3. Direct conflict between two of our sources on skill wording, currently unrecorded.**

| Source | Position |
|---|---|
| superpowers | Authority language is the mechanism. "'YOU MUST' removes decision fatigue"; "✅ Write code before test? Delete it. Start over. No exceptions. / ❌ Consider writing tests first when feasible" (`superpowers/skills/writing-skills/persuasion-principles.md:14-28`) |
| anthropics | "Try to explain to the model why things are important in lieu of heavy-handed musty MUSTs" (`skill-creator/SKILL.md:139`); "If you find yourself writing ALWAYS or NEVER in all caps… that's a **yellow flag** — if possible, reframe and explain the reasoning… That's a more humane, powerful, and effective approach" (`:302`) |

Both are first-hand practitioner claims; neither ships data. superpowers' own
`Match the Form to the Failure` table (`writing-skills/SKILL.md:459-474`) actually *resolves*
it: prohibition + rationalization table for **discipline** failures (agent knows the rule and
skips it), positive recipe for **shaping** failures (output has the wrong form). Our three
skills are all discipline skills, so the Iron Law form is right for them — but the resolution
should be recorded, because the next maintainer reading `skill-creator` will otherwise
conclude our all-caps gates are a defect. **Recommend a note in spec/11, not a change.**

**4. `spec/key/02-repo-synthesis.md:644` (SD-10) is confirmed, and the reason is stronger than
recorded.** SD-10 says stop watching this repo's `spec/` because it is "now an external URL".
Verified: `spec/agent-skills-spec.md` is **3 lines total**. Not merely relocated — there is no
specification content at this path at all. The record understates it.

**5. `spec/key/02-repo-synthesis.md:47` records 0 adopted mechanisms from this repo
("Mechanism | SKILL.md frontmatter shape | 0 (+ registry correction)").** §3 above finds 14
ADOPT rows, all zero-cost or listing-cost-neutral, concentrated in
`skill-creator/scripts/` and `agents/grader.md` — which the prior cluster pass did not open
(its own coverage note says "~9 anthropics skills", and the scripts are named as
NOT READ). The `0` is an artifact of coverage, not a judgment that survived reading. The
license correction recorded at `00-method.md:176` and `04-decision-log.md:802-811` is
independently confirmed above and is exactly right.

## 6. Cost profile

| Adopted item | Tier | Cost | Basis |
|---|---|---|---|
| A-4/A-5/A-6/A-11/A-14 eval schema upgrades | **zero** | Fixture files never enter a context. Running them costs model calls: their default is 3 runs × 20 queries = 60 `claude -p` invocations per description candidate, × up to 5 iterations. For us, per skill under test, budget ~30-60 short sessions per tuning pass | `run_eval.py:266` (`runs-per-query 3`), `run_loop.py:251` (`max-iterations 5`), `skill-creator/SKILL.md:339` (20 queries) |
| A-9/A-30 description rules | **persistent** | No added cost; they *are* the budget rule. Our target: ≤80 tokens each, ≤900 sum. Their actual mean is 437 chars ≈ 109 tokens — already over our per-description ceiling, which is why we take the rules and not the sizing | Measured over all 17 frontmatters: 7,430 chars total, mean 437, max 1,077 |
| A-23/A-24/A-26 grader rules | lazy (in `diff-reviewer`'s contract, read on spawn) | ~150-250 tokens of contract text, paid once per reviewer spawn | `agents/grader.md:39-40`, `:43-59`, `:92-99` — ~35 lines condensed to ~10 |
| A-20 three-level disclosure | documentation | zero | — |
| A-21/A-22/A-28 procedure items | zero | Authoring/eval-time only | — |
| A-1/A-2 optimizer (if built OMP-native) | zero resident; per-run model cost | Deferred. Estimate ~200-400 short sessions to tune a 10-skill listing once, at ~1-2k tokens each ≈ 0.2-0.8M tokens per full tuning pass. **Estimate**, basis: 20 queries × 3 runs × 5 iterations × 10 skills, with each run a 1-3 turn session | Derived from their defaults; not measured |

The honest summary: everything valuable here is **zero-cost at runtime**. This repo's
contribution to us is method and measurement, not content. Not one line of its skill bodies
belongs in our listing.

## 7. Coverage and limits (MANDATORY)

**Files read in full:**
`skills/skill-creator/SKILL.md` (485L) · `skills/skill-creator/scripts/run_eval.py` (311L) ·
`skills/skill-creator/scripts/improve_description.py` (248L) ·
`skills/skill-creator/scripts/run_loop.py` (329L) ·
`skills/skill-creator/agents/grader.md` (224L) ·
`skills/skill-creator/references/schemas.md` (431L) · `template/SKILL.md` (6L) ·
`spec/agent-skills-spec.md` (3L) · header of all 16 `LICENSE.txt` files.

**Files sampled (head/grep/partial only):**
Frontmatter + line/word counts of all 17 `skills/*/SKILL.md` (via script — I read every
`name`, `description`, and `license` field, but **not** the bodies) · `git ls-files` inventory
· per-description char-length measurement across all 17.

**Not opened:**
All 17 skill **bodies** except `skill-creator` — including `algorithmic-art` (404L),
`claude-api` (546L, 9,555 words, the largest body in the repo), `doc-coauthoring` (375L),
`pdf` (314L) + `pdf/forms.md` + `pdf/reference.md`, `pptx` (238L), `mcp-builder` (236L) +
its 4 `reference/` files, `slack-gif-creator` (254L), `canvas-design` (129L), `xlsx` (99L),
`webapp-testing` (95L), `docx` (91L), `brand-guidelines` (73L), `web-artifacts-builder` (73L),
`theme-factory` (59L), `frontend-design` (55L), `internal-comms` (32L) ·
`skill-creator/scripts/{aggregate_benchmark.py,generate_report.py,package_skill.py,quick_validate.py,utils.py,__init__.py}`
· `skill-creator/agents/{analyzer.md,comparator.md}` ·
`skill-creator/eval-viewer/{generate_review.py,viewer.html}` ·
`skill-creator/assets/eval_review.html` ·
all `claude-api/{csharp,curl,go,java,php,python,ruby,shared,typescript}/**` (~50 files, incl.
20 `shared/managed-agents-*.md`) · all `pdf/scripts/*.py` (8 files) ·
all `{docx,pptx,xlsx}/scripts/**` (~110 files: `office/validators/`, `office/helpers/`,
`office/schemas/**.xsd`) · `slack-gif-creator/core/*.py` (4) ·
`webapp-testing/{examples,scripts}/*.py` (4) · `internal-comms/examples/*.md` (4) ·
`theme-factory/themes/*.md` (10) · `algorithmic-art/templates/*` ·
`canvas-design/canvas-fonts/**` (~150 font + OFL files) · `README.md` ·
`THIRD_PARTY_NOTICES.md` · `.claude-plugin/marketplace.json`.

**Claims that need a live run before use:**
- A-2's synthetic-command-file trick is read from source and is unambiguous in intent, but I
  did **not execute** `run_eval.py`. Whether a `.claude/commands/*.md` file reliably surfaces
  in `available_skills` on the current Claude Code build is unverified — **grade B on
  behavior**, A on what the code does. This matters only if we tried to port it, which §3 says
  we should not.
- A-17 ("Claude only consults skills for tasks it can't easily handle") is asserted prose with
  no experiment. It is load-bearing for fixture design, so treat as **B** and validate against
  our own runtime before we discard a fixture on its authority.
- A-18's "Claude has a tendency to undertrigger" is undated and unquantified. Model-version
  dependent by nature.
- A-19's anti-MUST claim ("more humane, powerful, and effective") ships no measurement.
- The token estimate in §6 for a full OMP-native tuning pass is arithmetic on their defaults,
  not an observation. Labelled estimate.

**Suspected but not verified:**
- The license split may not be stable across future commits: `doc-coauthoring` having **no**
  `LICENSE.txt` while its 16 siblings each have one looks like an oversight rather than an
  intentional grant or denial. Treat `doc-coauthoring` as all-rights-reserved by default. Our
  registry should record it as *unlicensed/unknown*, not as Apache by proximity.
- `office/` under `docx`, `pptx`, and `xlsx` appear to be **identical copies** (same filenames,
  same schema tree). I compared file *lists*, not contents. If they are identical, the repo's
  411-file count overstates distinct content by ~80 files — relevant only to our size record.
- I found no CI configuration in the tracked files, so I cannot say whether
  `quick_validate.py` runs on PRs. No `.github/` directory appears in `git ls-files`.
