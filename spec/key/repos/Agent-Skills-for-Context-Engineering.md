# Repo Report — Agent-Skills-for-Context-Engineering (muratcankoylan)

> **Path:** `_research/upstreams/Agent-Skills-for-Context-Engineering`
> **SHA:** `a1841d1ea3dadc70098d94b60fa7a4ab8875dc50`
> **License:** MIT. `LICENSE:1-3` — "MIT License / Copyright (c) 2025 Context Engineering Agent
> Skills Contributors". Root file present; no per-skill overrides.
> **Size:** 405 tracked files (`git ls-files | wc -l`), of which **219 are under `examples/`**
> and **96 under `researcher/`**. The skill library proper is 57 files (17 `SKILL.md` + 40
> supporting) plus a root `SKILL.md`.
> **Read this pass:** frontmatter of all 17 skills + root `SKILL.md`, with line/word counts and
> measured description lengths; `skills/context-compression/SKILL.md` (279L, full) as the
> representative body; `## When to Activate` blocks of `multi-agent-patterns`, `tool-design`,
> `evaluation`, `filesystem-context`, `bdi-mental-states`, `hosted-agents` (the `Do not
> activate` blocks are the mechanism under study); `## Gotchas` sections of
> `long-horizon-prompting`, `self-improvement-loops`, `harness-engineering` in full; section
> maps of those three; `researcher/fixtures/activation-cases.jsonl` (23 lines, sampled 4 in
> full); `researcher/benchmarks/router/prompts.jsonl` (56 lines, sampled 2);
> `researcher/benchmarks/scenarios/adversarial.jsonl` (7 lines, sampled 2);
> `researcher/claims/index.jsonl` (26 lines, sampled 2);
> `researcher/mechanisms/registry.jsonl` (22 lines, sampled 1);
> `researcher/scripts/skill_health.py:20-89` and `:170-229` (the scoring function);
> `CLAUDE.md` (via project context, full); root `SKILL.md:1-40`.

## 1. What this repo is

A **research corpus wearing skill frontmatter**, plus a file-based "researcher OS" that
discovers sources, proposes mechanisms, and gates their promotion. The 17 skills are
domain-expertise documents about agent engineering (compression, degradation, memory,
multi-agent topology, tool design, evaluation, harness design) — each ~230-410 lines, mean
~2,350 words, all conforming to an 8-section body standard enforced by a scoring script. It is
the only repo in the corpus that (a) writes **explicit "Do not activate" routing blocks in
every single skill**, (b) maintains a **claim-provenance ledger** binding every numeric
assertion to a dated source, and (c) ships a **model-graded skill-routing benchmark** with 56
labelled prompts.

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| M-1 | **`Do not activate` block in every skill** | Universal, not occasional: `grep -c "Do not activate" skills/*/SKILL.md` returns exactly **1 for all 17**. Each entry names the adjacent work *and* the owning skill | `skills/*/SKILL.md` (17/17); e.g. `context-compression/SKILL.md:20-24`, `tool-design/SKILL.md` "Do not activate…" block, `filesystem-context/SKILL.md` idem | A |
| M-2 | **Routing clauses inside the `description` itself** | Not just in the body. `context-fundamentals`: "Route operational work to the specialized skills: debugging attention failures goes to context-degradation, token-efficiency work goes to context-optimization, conversation summarization goes to context-compression, and project-shape decisions go to project-development." Also in `memory-systems`, `project-development`, `tool-design`, `long-horizon-prompting`, `self-improvement-loops` | `skills/context-fundamentals/SKILL.md` frontmatter; `skills/memory-systems/SKILL.md` frontmatter; `skills/tool-design/SKILL.md` frontmatter | A |
| M-3 | **Unit-of-work as the routing discriminator** | The cleanest boundary rule in the corpus: `tool-design` — "Use this when the unit of work is a single tool or a set of tools"; `project-development` — "Use this when the unit of work is a whole project or a multi-stage pipeline" | `skills/tool-design/SKILL.md` frontmatter; `skills/project-development/SKILL.md` frontmatter | A |
| M-4 | **Activation-case fixtures with three verdict classes** | `expected_primary_skill` + `acceptable_secondary_skills[]` + **`rejected_skills[]`** + a prose `reason`. The three-way split is the mechanism: it distinguishes "wrong" from "acceptable but not ideal" | `researcher/fixtures/activation-cases.jsonl` (23 cases); e.g. `activation-evaluation-vs-advanced-judge`, `activation-compression-vs-optimization` | A |
| M-5 | **Cases are named after the *boundary*, not the skill** | `activation-evaluation-vs-advanced-judge`, `activation-compression-vs-optimization`, `activation-optimization-vs-compression` — including **both directions of the same pair** | `researcher/fixtures/activation-cases.jsonl` case_ids | A |
| M-6 | **`reason` field states the discriminating criterion** | "General quality gates and regression suites belong to evaluation **unless** judge-specific calibration or autonomous control-surface design dominates" — a decision rule, not a restatement | `researcher/fixtures/activation-cases.jsonl` (`activation-evaluation-general-quality-gate`) | A |
| M-7 | **56-prompt router benchmark, same schema** | `prompts.jsonl` uses identical fields (`expected_primary_skill`/`acceptable_secondary_skills`/`rejected_skills`/`reason`) at 56 prompts vs the fixture set's 23 — a graded scale-up of the same test | `researcher/benchmarks/router/prompts.jsonl` (56 lines) | A |
| M-8 | **Published, dated router results** | Three dated result files (`2026-05-15.md`, `2026-05-15-v2.md`, `2026-05-19.md`) under `results-published/` | `researcher/benchmarks/router/results-published/` | B |
| M-9 | **Claim-provenance ledger** | Every numeric/benchmark/volatile claim gets a `claim-*` id with `claim_text`, `owning_skill`, `section`, `source_url`, `retrieved_at`, `evidence_strength`, **`volatility`**, `last_reviewed` | `researcher/claims/index.jsonl` (26 claims); e.g. `claim-multi-agent-token-multiplier` | A |
| M-10 | **Inline claim ids in prose** | Skill bodies cite their own ledger: "Artifact trail integrity is often the weakest dimension in compression evaluations (claim-context-compression-factory-benchmark)" | `context-compression/SKILL.md:44`, `:111`, `:171`; `long-horizon-prompting/SKILL.md` Gotchas 3,4,6,7,8,10 | A |
| M-11 | **Unknown claim ids are a validation failure** | `skill_health.py` collects `claim-*` tokens and diffs against the ledger; `numeric_claims_with_id / numeric_claims_total` is **15% of the health score** | `skill_health.py:71` (`CLAIM_ID_PATTERN`), `:173-176`, weight at `:207` | A |
| M-12 | **Numeric-claim detection by regex** | Six patterns catch `%`, `x`, `ms`, `s`, `tokens`, and `\d+(k\|K\|M\|B\|x)` — so any bare number in a skill body is *found* and then required to carry provenance | `skill_health.py:49-56` | A |
| M-13 | **Benchmark-name watchlist** | A literal set (`LoCoMo`, `LongMemEval`, `BrowseComp`, `SWE-bench`, `RULER`, `DMR`, `HotPotQA`, `MMLU`, `GSM8K`, `HumanEval`) so naming a benchmark triggers the provenance requirement | `skill_health.py:58-69` | A |
| M-14 | **Weighted skill-health score** | required_sections 0.20 · gotchas 0.15 (target 3) · code examples 0.10 (target 2) · internal-link resolution 0.15 · activation-case presence 0.10 · claim provenance 0.15 · mechanism registration 0.10 · frontmatter 0.05 | `skill_health.py:185-211` | A |
| M-15 | **8 required body sections** | `When to Activate`, `Core Concepts`, `Practical Guidance`, `Examples`, `Guidelines`, `Gotchas`, `Integration`, `References` | `skill_health.py:38-47` | A |
| M-16 | **Gotchas as the highest-signal section, with a target count** | `CLAUDE.md` skill-authoring rule 9: "**Include a Gotchas section**: experience-derived failure modes are the highest-signal content in any skill". The scorer sets `target=3` | `CLAUDE.md` (authoring rules); `skill_health.py:187` | A |
| M-17 | **Gotchas are named failure modes with a fix, not warnings** | "**Status-report theater**: Long runs drift into reporting activity instead of results, including fabricated completions. Require artifact-based reporting and evidence-traceable claims…; reject 'on track' without a pointer." Bold name + mechanism + countermeasure | `long-horizon-prompting/SKILL.md` Gotcha 6; `harness-engineering/SKILL.md` Gotchas 1-8; `self-improvement-loops/SKILL.md` Gotchas 1-9 | A |
| M-18 | **Mechanism registry with failure modes** | `mechanism_id`, `owning_skill`, `status`, `activation_scenario`, **`behavior_change`**, `evidence[]`, `failure_modes[]` — a mechanism is only registered if it names the behavior it changes | `researcher/mechanisms/registry.jsonl` (22 entries); e.g. `locked-editable-surfaces` | A |
| M-19 | **Adversarial benchmark scenarios for the *harness*** | 7 scenarios each with `class`, `expected_gate`, and a `deterministic_signal` — e.g. a reworded duplicate mechanism must be caught by mechanism overlap *before* corpus overlap; a credible author writing generic advice must be content-rejected | `researcher/benchmarks/scenarios/adversarial.jsonl` (7 lines) | A |
| M-20 | **Deterministic-before-model-judged ordering** | "structure, schema, rubric math, manifest sync, retrieval status, and registry shape must pass **before** any LLM judge is invoked" | `CLAUDE.md` (Key Design Principles) | A |
| M-21 | **Human-controlled merge as an invariant** | "agents may prepare PRs and pass gates, but push and merge always require explicit human approval"; and "Never invoke paid LLMs from the continuous loop" | `CLAUDE.md` (Key Design Principles; Researcher OS Rules 5) | A |
| M-22 | **Reference files carry a "Read when:" clause** | Every entry in `## References` states its trigger: "[Evaluation Framework Reference](./references/evaluation-framework.md) - Read when: building or calibrating a probe-based evaluation pipeline…" | `context-compression/SKILL.md:259-270` | A |
| M-23 | **Cross-skill references are plain text, deliberately** | "use plain text skill names (not links) in Integration sections to avoid cross-directory reference issues" | `CLAUDE.md` (Key Design Principles) | A |
| M-24 | **Skill metadata footer** | Created / Last Updated / Author / Version per skill | `context-compression/SKILL.md:274-279` | A |
| M-25 | **Tokens-per-task, not tokens-per-request** | "A strategy saving 0.5% more tokens per request but causing 20% more re-fetching costs more overall. Track re-fetching frequency as the primary quality signal" | `context-compression/SKILL.md:38-40` | A |
| M-26 | **Structured-summary sections as a forced checklist** | "Each section acts as a checklist the summarizer must populate, making omissions visible rather than silent." Concrete template: Session Intent / Files Modified / Decisions Made / Current State / Next Steps | `context-compression/SKILL.md:54-81` | A |
| M-27 | **Never compress tool definitions** | "Compressing function call schemas, API specs, or tool definitions destroys agent functionality entirely… Treat tool definitions as immutable anchors that bypass compression" | `context-compression/SKILL.md:234` | A |
| M-28 | **Compressed summaries hallucinate; early turns are irreplaceable** | Two independent gotchas: summarizers fabricate file paths and "round" numeric values (`:236`); the first turns hold constraints that cannot be re-derived and must be protected or extracted to a persistent preamble (`:240`) | `context-compression/SKILL.md:236`, `:240` | A |
| M-29 | **Probe-based evaluation over lexical metrics** | "A summary can score high on lexical overlap while missing the one file path the agent needs to continue." Four probe types: Recall / Artifact / Continuation / Decision | `context-compression/SKILL.md:96-107` | A |
| M-30 | **Probe evaluation gives false confidence** | The self-undercutting gotcha: "Probes can pass despite critical information being lost, because the probes test only what they ask about… rotate probe sets across evaluation runs" | `context-compression/SKILL.md:246` | A |
| M-31 | **"Prompt-stated budgets decay"** | "A budget or reminder stated once loses force as the trajectory grows; re-inject budget and verified-progress state periodically **from outside the loop**" (claim-long-horizon-give-up-drift) | `long-horizon-prompting/SKILL.md` Gotcha 8 | A |
| M-32 | **"Over-prescription backfires on frontier models"** | "Step-by-step scripts and stacked MUST/NEVER emphasis measurably degrade current-generation model output (claim-long-horizon-lean-prompt). Migrate old prompt stacks by starting from the minimal brief, not by accretion" | `long-horizon-prompting/SKILL.md` Gotcha 10 | A |
| M-33 | **"Only runtime enforcement survives optimization pressure"** | "Budget limits and safety rules stated in the seed prompt get dropped during self-rewrites, and explicit warnings do not reduce circumvention attempts" | `self-improvement-loops/SKILL.md` Gotcha 1 | A |
| M-34 | **"Self-reported success" as a named failure** | "Loops that evaluate from the agent's own report files inherit its over-optimism: noise declared as signal, bugs interpreted as breakthroughs, unfavorable runs omitted. **Bind every reported number to a raw artifact (log line, score file) at write time**" | `self-improvement-loops/SKILL.md` Gotcha 3 | A |
| M-35 | **"Same-model generator and evaluator"** | "optimization pressure exploits shared blind spots and the measured score diverges from true quality. Use an independent evaluator, ideally grounded in execution rather than judgment" | `self-improvement-loops/SKILL.md` Gotcha 7 | A |
| M-36 | **"Visible scorers get gamed"** | "Expose scores and traces, never evaluator internals" (claim-self-improvement-scorer-visibility) | `self-improvement-loops/SKILL.md` Gotcha 2 | A |
| M-37 | **"Cross-stage score cherry-picking"** | "When a reporting stage can see a pool of intermediate scores, it selects the most favorable one rather than the score of the artifact actually shipped. Bind reported scores to the submitted candidate deterministically" | `self-improvement-loops/SKILL.md` Gotcha 9 | A |
| M-38 | **"Mutable evaluator" / locked surfaces** | "If the agent can edit the metric, it may optimize the benchmark instead of the task. Keep rubrics and eval code locked during the run." Registered as mechanism `locked-editable-surfaces` with four surface classes: locked / editable / append-only / human-controlled | `harness-engineering/SKILL.md` Gotcha 1; `researcher/mechanisms/registry.jsonl` (`locked-editable-surfaces`) | A |
| M-39 | **"No discard record"** | "Without rejected-attempt logs, agents repeat failed ideas. Preserve failures with enough detail to avoid rediscovery" — implemented as `mechanisms/ledgers/rejected.jsonl` | `harness-engineering/SKILL.md` Gotcha 3; `researcher/mechanisms/ledgers/rejected.jsonl` | A |
| M-40 | **"Human approval ambiguity"** | "'Prepare a PR' is not 'merge a PR.' Make approval boundaries explicit in the harness" | `harness-engineering/SKILL.md` Gotcha 7 | A |
| M-41 | **"Complexity accretion"** | "Agents stack changes and rarely remove them. Require pruning rounds and **reward equal-quality simplification**" | `harness-engineering/SKILL.md` Gotcha 4 | A |
| M-42 | **Continuous loop + launchd daemons** | `loop_discover.py`, `loop_step.py`, `loop_daily.py`, `loop_status.py` plus macOS `.plist` service definitions and install/uninstall scripts | `researcher/scripts/loop_*.py`; `researcher/orchestration/launchd/*` | A |
| M-43 | **Run state machine with explicit subcommands** | `research_loop.py init/retrieve/evaluate/propose/novelty/validate-run/pr-ready/close`; "do not edit `run-state.json` by hand" | `CLAUDE.md` (Researcher OS Rules 1-2); `researcher/scripts/research_loop.py` (697L, **not read**) | B |
| M-44 | **17 skills as a single plugin, for a stated cache reason** | "Claude Code caches each plugin's `source` directory separately, so multiple plugins pointing to `source: "./"` would each cache a full copy of the repo" | `CLAUDE.md` (Plugin Architecture) | A |

### Fixture format, verified

**Activation case** (`researcher/fixtures/activation-cases.jsonl`, one JSON object per line):

```json
{"case_id":"activation-compression-vs-optimization",
 "prompt":"Summarize a long agent session into a compact handoff that preserves files, decisions, risks, and next actions.",
 "expected_primary_skill":"context-compression",
 "acceptable_secondary_skills":["filesystem-context"],
 "rejected_skills":["context-optimization"],
 "reason":"The work is compaction and handoff preservation rather than broader token-budget optimization."}
```

This is the **best trigger-fixture schema in the corpus**, and it beats addyosmani's on one
axis. addyosmani's negative fixture asserts *one* thing (owner outranks self); this asserts
three simultaneously — the right skill wins, a named set is *tolerable*, and a named set is
**wrong**. `rejected_skills` is the field we lack entirely: it encodes "this prompt looks like
X but must not route to X", which is exactly the near-miss that
`skill-creator/SKILL.md:358` demands and that our spec/11 §D negatives fail to be.

The `router/prompts.jsonl` set (56 prompts) reuses the identical schema, so the fixture format
scales from a 23-case regression gate to a 56-case graded benchmark with no schema change.

**Adversarial harness scenario** (`researcher/benchmarks/scenarios/adversarial.jsonl`):
`scenario_id`, `class` (`semantic_novelty`, `source_quality`, …), `description`,
`expected_gate`, `deterministic_signal`. These test the **gate**, not the skill — e.g. "A
credible author publishes generic agent advice with no implementable mechanism" must produce
`content_reject` via "content-curation gates G1 and G2 should fail". A test suite for the
acceptance criteria themselves.

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| M-1 `Do not activate` block in the body | Bodies of all our skills | lazy | **ADOPT — already partly done** | Our three shipped descriptions already carry `Do NOT activate for:` in the *description*. Adding the fuller form to the body costs ~40 lazy tokens and names the owner |
| M-2 routing clause in the description | Our descriptions | **persistent** | **ADAPT, carefully** | The idea is right and is the answer to "name the adjacent domain you do not own". The *execution* is what blows their budget: `context-fundamentals` spends 853 chars, over half of it on routing. At ≤80 tokens we can afford roughly one clause naming one neighbour, not four |
| M-3 unit-of-work discriminator | Our descriptions where two skills abut | persistent | **ADOPT** | The most token-efficient boundary statement available: "Use this when the unit of work is X" is ~10 tokens and settles a whole class of misroutes |
| M-4 + M-5 activation-case schema with `rejected_skills` | `evals/triggers/<skill>.yml` (spec/11 §D) | **zero** | **ADOPT — highest-value row here** | Fills the exact hole in our negatives. Combine with addyosmani's `owner`: `expected_primary` + `acceptable_secondary[]` + `rejected[]` + `reason` |
| M-5 name cases after the boundary, both directions | Same | zero | **ADOPT** | Free, and it forces us to write the reciprocal case. With ≤10 skills the pairs are enumerable |
| M-6 `reason` states the discriminating criterion | Same | zero | **ADOPT** | Turns a fixture into documentation of the boundary. When the case fails you already know which description to fix |
| M-7 same schema at two scales | spec/13 L2/L3 | zero | **ADOPT** | 20-30 regression cases in CI, expandable to a graded benchmark without a rewrite |
| M-9 + M-10 + M-11 claim provenance | `spec/key/` and `registry/` — **not** the skills | zero | **ADAPT** | We already do this by hand: `_CONTRACT.md` grades A-D and requires `file:line`. Their addition is `volatility` + `last_reviewed`, which is what makes a stale claim *findable*. Consider adding both fields to `registry/upstreams.yml` |
| M-12 + M-13 numeric-claim regex + benchmark watchlist | A validator over `spec/` and `registry/` | zero | **ADAPT** | Mechanically finds every unsourced number in our own spec. Our corpus has many (token counts, percentages, session counts). ~30 lines |
| M-14 weighted health score | Our skill validator | zero | **DEFER** | A single 0-1 score compresses away *which* rule failed, and their weights are unjustified (why is gotchas 0.15 and code 0.10?). Prefer addyosmani's pass/fail errors. Trigger: if we ever have enough skills that a ranked report beats a list |
| M-15 8 required sections | Our skill template | lazy | **REJECT** | Eight sections × 17 skills is why their bodies average 2,350 words. `Core Concepts` + `Practical Guidance` + `Examples` + `Guidelines` is four names for "the content". Our four (Overview / Rationalizations / Red Flags / Verification) are load-bearing; these are not |
| M-16 + M-17 Gotchas as named failure modes | Our skill bodies **and** worker contracts | lazy | **ADOPT** | The form — **bold name** + mechanism + countermeasure, one paragraph — is denser than a two-column rationalization table for *mechanism* failures, and complements it. Our red-flags lists are trip-wires; gotchas explain the trap |
| M-18 mechanism registry with `behavior_change` + `failure_modes` | `registry/adoption-ledger.yml` | zero | **ADOPT** | A registry entry that cannot be written without naming the behavior change is structurally immune to the `.omp/policies/` failure the contract's rule 4 exists to prevent |
| M-19 adversarial scenarios for the gate | spec/13 governance tests | zero | **ADAPT** | Testing the acceptance criteria themselves is a level we do not have. Their `deterministic_signal` field is the good part: the scenario names which check must fire |
| M-20 deterministic before model-judged | spec/13 tier ordering | zero | **ADOPT** | Corroborates addyosmani's three-tier cost model from a second source. Two independent sources ⇒ record as A |
| M-21 human-controlled merge; never paid LLMs in a loop | spec/14 governance; spec/15 | zero | **ADOPT** | Cheap, correct, and we have no such invariant written down |
| M-22 "Read when:" on every reference | Our skill bodies that link a reference | lazy | **ADOPT** | ~8 tokens per link and it converts a bare link into a conditional. Directly serves progressive disclosure: the agent knows whether to pay |
| M-23 plain-text skill cross-references | Our skill bodies | lazy | **ADOPT** | Same conclusion superpowers reaches by a different route (`writing-skills/SKILL.md:286-288`: no `@` links, they force-load). Two sources agree |
| M-24 metadata footer | Our skills | lazy (~15 tokens) | **DEFER** | Version/date belongs in `registry/skill-lock.yml`, which already has `last_reviewed` and `reviewer`. Duplicating it into the body pays tokens for git metadata. Trigger: if skills are ever distributed outside the repo |
| M-25 tokens-per-task not per-request | `spec/key/03-token-quality-model.md` | zero | **ADOPT** | The correct optimization target for our whole budget argument, stated crisply. A cheaper worker that re-explores costs more |
| M-26 structured handoff with mandatory sections | Worker report contract (spec/06 structured output) | per-action | **ADOPT** | "Each section acts as a checklist… making omissions visible rather than silent" is the anti-false-completion argument for a **required-field** report schema. Files Modified / Decisions / Current State / Next Steps maps onto our packet |
| M-27 never compress tool definitions | spec/05 context model | zero | **ADOPT (as a constraint)** | If we ever add compaction, this is the one hard exclusion |
| M-28 summaries hallucinate; protect early turns | spec/05; coordinator contract | zero | **ADOPT** | "Preserve identifiers verbatim in dedicated sections rather than embedding them in prose" is directly actionable for our packet design |
| M-29 + M-30 probe evaluation, and its limits | spec/13 | zero | **ADAPT** | The four probe types (Recall / Artifact / Continuation / Decision) are a ready-made post-compaction checklist. M-30's self-undercut ("rotate probe sets") keeps us honest |
| M-31 prompt-stated budgets decay | Workflow template design | zero | **ADOPT** | Argues that a token budget stated once in a long workflow stops binding — so it must be **re-injected**, which is an argument for `autoloadSkills` per spawn over a single up-front statement. Directly supports spec/11 §B |
| M-32 over-prescription backfires | Our skill bodies | zero | **DEFER, flagged** | Third source in the corpus on the MUST/NEVER question, and it lands *against* stacked emphasis. See §5.3 — this is now a three-way disagreement that our spec should record rather than silently resolve |
| M-33 only runtime enforcement survives | spec/15; skill design | zero | **ADOPT** | Sobering and correct: a rule in a prompt is advisory. Argues for validators over instructions wherever a check is mechanizable — which is also superpowers' rule (`writing-skills/SKILL.md:59`) |
| M-34 self-reported success; bind numbers to artifacts | `verifier` + `diff-reviewer` contracts | lazy | **ADOPT — this is our enemy, named** | "noise declared as signal, bugs interpreted as breakthroughs, unfavorable runs omitted" is a precise description of false completion, and the fix ("bind every reported number to a raw artifact at write time") is exactly `evidence-before-completion` |
| M-35 same-model generator and evaluator | spec/09 model routing; spec/10 review | zero | **ADOPT** | Our `implementer` and `diff-reviewer` may run the same model. This says the measured score then diverges from true quality, and prefers an evaluator "grounded in execution rather than judgment" — i.e. run the command, don't opine |
| M-36 visible scorers get gamed | `verifier` contract | zero | **ADAPT** | "Expose scores and traces, never evaluator internals." For us: the implementer should see *what* must pass, not the reviewer's rubric internals |
| M-37 cross-stage score cherry-picking | Coordinator report assembly | zero | **ADOPT** | A worker that can see several test runs will report the best one. Bind the reported result to the *shipped* artifact deterministically |
| M-38 locked / editable / append-only / human-controlled surfaces | spec/15; `registry/skill-lock.yml` | zero | **ADOPT** | A four-class taxonomy for every artifact a workflow can touch. `skill-lock.yml` is an attempt at "locked" without the vocabulary |
| M-39 keep a rejected ledger | `registry/rejected-mechanisms.yml` | zero | **ADOPT — already done** | We have exactly this file. Their contribution is the *reason*: "Without rejected-attempt logs, agents repeat failed ideas" — worth recording as the file's justification |
| M-40 "prepare a PR" ≠ "merge a PR" | spec/14 | zero | **ADOPT** | One sentence, closes a real ambiguity in an autonomous workflow |
| M-41 reward equal-quality simplification | `diff-reviewer` contract | lazy | **ADOPT** | Counters accretion. A reviewer that only ever adds findings ratchets complexity upward |
| M-42 continuous loop + launchd | — | — | **REJECT** | Loop controller. OMP is the only runtime; contract anti-pattern 3 |
| M-43 run state machine | — | — | **REJECT** | Same. Extract M-38's surface taxonomy from it and leave the machine |
| M-44 single-plugin cache argument | — | — | **REJECT** | Claude Code plugin packaging. No OMP attachment point |
| Any of the 17 skills as content | — | persistent | **REJECT** | See §4 |

## 4. What this repo does that we deliberately will not

**Ship 17 skills at these description lengths.** Measured across all 17 frontmatters: 6,578
chars, **mean 386, max 853** (`context-fundamentals`), ≈**1,644 tokens** for the listing.
Under our multiplier that is ~6,600-8,200 tokens per Standard workflow against a 900-token cap
— a ~730% overshoot. And the length is *structural*, not incidental: the routing clauses that
make M-2 work are what push `context-fundamentals` to 853 chars,
`long-horizon-prompting` to ~800, and `self-improvement-loops` to ~790. Their solution to
17 mutually-adjacent skills is to spend description tokens on a routing table. Ours is to have
fewer skills. Both are coherent; only one fits our budget.

**Skills that are domain essays.** Mean 2,350 words per body, 8 mandatory sections. Read
`context-compression` in full: it is a genuinely good 279-line document on compression
strategy, with benchmark tables, six evaluation dimensions, and seven gotchas. It is also
**knowledge, not process**. An agent invoking it learns a taxonomy; it does not change what the
agent *does* next. addyosmani's `docs/skill-anatomy.md:144` states the counter-principle
better than I can: "**Process over knowledge.** Skills are workflows, not reference docs. Steps,
not facts." By that test, `context-fundamentals` ("Use this for conceptual explanation,
onboarding, and background reading" — its own description), `bdi-mental-states`, `hosted-agents`,
and `project-development` are documentation in skill costume.

**`bdi-mental-states`.** 373 lines on Belief-Desire-Intention ontologies, RDF-to-belief
transformations, SPARQL competency questions, and JADE/JADEX framework integration. Genuine
academic content, zero attachment point in a four-worker coding workflow. This is the clearest
"should not be a skill *for us*" case in the corpus — and it costs listing tokens in every
session to advertise itself.

**`researcher/` as a whole (96 files).** A file-based research OS: run state machine, discovery
queue, source-evaluation rubrics, novelty gates, mechanism promotion with `--reviewed-by`,
launchd daemons, continuous loop. Impressive engineering, and out of scope by constraint. The
extractable craft is already captured above: M-18 (registry shape), M-19 (adversarial gate
tests), M-38 (surface taxonomy), M-9 (claim provenance), M-39 (rejected ledger). The loop,
the daemons, and the state machine are not ours to take.

**`examples/` (219 files — 54% of the repo).** Five demonstration projects including a book
SFT pipeline with a Gertrude Stein dataset, a digital-brain personal-CRM, and an
interleaved-thinking Python package. Not read, and not relevant: they demonstrate the skills'
subject matter, not skill craft.

**The weighted health score (M-14).** `skill_health.py:185-211` collapses eight checks into one
float with hand-set weights. Two problems for us: a 0.83 tells you nothing about *which* rule
failed, and the weights encode contestable priors (code examples at 0.10 for a library whose
own `CLAUDE.md` says "Examples use Python pseudocode: conceptual demonstrations… not
production-ready implementations"). addyosmani's binary errors-block-CI model is strictly more
actionable at our scale.

**Gotchas at 9-10 per skill.** `long-horizon-prompting` has 10, `self-improvement-loops` 9,
`harness-engineering` 8. Each is excellent individually; collectively they are ~600-900 tokens
per body. Their scorer targets **3** (`skill_health.py:187`) and they routinely triple it. We
take the *form* and cap the count.

## 5. Contradictions with our current spec or registry

**1. Our spec has no `rejected_skills` concept, and this repo shows why that is a gap.**
`spec/11-skills-rules-and-quality-gates.md:136-141` records one positive and one negative
prompt per skill. Their fixture carries **three** verdict classes per prompt —
`expected_primary_skill`, `acceptable_secondary_skills[]`, `rejected_skills[]`
(`researcher/fixtures/activation-cases.jsonl`). With three skills today and ≤10 planned, the
question that will actually break our library is "which of these two owns this prompt", and our
schema cannot express it. Not a false claim; a missing field with real consequences. Combined
with the near-miss defect (see `skills.md` §5) and the below-floor minimums (see
`agent-skills.md` §5), **spec/11 §D needs rewriting, not patching.**

**2. `spec/key/02-repo-synthesis.md`'s cluster read credited this repo with routing-aware
descriptions but did not measure them.** The dossier (`spec/key/dossiers/superpowers-skills.md:44`,
"A research corpus wearing skill frontmatter. Its one…") had the characterization right. What
was not recorded is the **number**: 1,644 listing tokens for 17 descriptions, mean 386 chars.
That number is the argument. It also reveals the trade the prose missed — their routing clauses
are *why* the descriptions are long, so "adopt routing-aware descriptions" is not free and must
be sized. Recommend attaching the measurement.

**3. The MUST/NEVER question is now a three-way disagreement, and our spec resolves it silently.**

| Source | Position | Evidence |
|---|---|---|
| superpowers | Authority language is the mechanism for discipline skills. "'YOU MUST' removes decision fatigue" | `superpowers/skills/writing-skills/persuasion-principles.md:14-28`, `:137-140` |
| anthropics | All-caps ALWAYS/NEVER is a "yellow flag"; explain the why instead | `skills/skill-creator/SKILL.md:139`, `:302` |
| **murat** | "Step-by-step scripts and **stacked MUST/NEVER emphasis measurably degrade** current-generation model output (claim-long-horizon-lean-prompt). Migrate old prompt stacks by starting from the minimal brief, not by accretion" | `long-horizon-prompting/SKILL.md` Gotcha 10 |

Two of three sources are against stacked imperatives, and murat's is the only one that claims
*measurement* and binds it to a provenance id. Our shipped skills use the Iron Law form. I do
not think that is wrong — superpowers' own `Match the Form to the Failure`
(`writing-skills/SKILL.md:459-474`) distinguishes *one* prohibition on a discipline failure
(fine) from *stacked* emphasis (which is what murat measures against), and our three skills each
carry one gate, not a stack. But the distinction is currently nowhere in our spec, so the next
maintainer meets three upstreams disagreeing and no recorded ruling. **Recommend spec/11 record
the resolution explicitly: one gate per discipline skill, no stacking, and never for shaping
failures.**

**4. M-31 supports a spec/11 decision that is currently justified on other grounds.**
spec/11 §A gives four reasons for preferring `autoloadSkills` over rule forwarding, all about
explicitness and token accounting. M-31 adds a fifth and stronger one: "A budget or reminder
stated once loses force as the trajectory grows; re-inject… periodically from outside the
loop." That is an argument that per-spawn injection is not merely tidier but *more effective*,
because a gate stated once in a long trajectory decays. Worth adding — it makes the DR-4
resolution robust to someone recomputing the token arithmetic.

**5. No factual contradiction found.** The one recorded claim I could check —
`spec/key/dossiers/superpowers-skills.md:7`, SHA `a1841d1ea3dad…` and "LICENSE present (MIT)" —
is confirmed exactly (`git rev-parse HEAD`; `LICENSE:1-3`).

## 6. Cost profile

| Adopted item | Tier | Cost | Basis |
|---|---|---|---|
| M-4/M-5/M-6/M-7 activation-case schema | **zero** | Fixture files never enter a context. ~20-30 JSONL lines for a 10-skill library, one line per boundary. Their 23 cases cover 17 skills | Measured: `activation-cases.jsonl` is 23 lines for 17 skills |
| M-2 routing clause in description | **persistent** | This is the one item with a real, recurring cost. Their mean description is 386 chars ≈ 97 tokens — **already over our ≤80-token ceiling before we add anything**. Budget at most ~10-15 tokens of routing per description ("not for X; that is Y's") and only where a boundary is genuinely contested | Measured over 17 frontmatters: 6,578 chars total, mean 386, max 853 |
| M-3 unit-of-work clause | persistent | ~10 tokens, replaces a longer enumeration | Measured from `tool-design`/`project-development` frontmatter |
| M-1 `Do not activate` in body | lazy | ~40-60 tokens per body, inside a body already paid for | Their blocks are 4-5 lines each |
| M-16/M-17 Gotchas | lazy | **Capped at 3**, ~60-80 tokens each ⇒ ~200 tokens per body. Their 8-10 per skill would be 600-900, which we refuse | Their scorer targets 3 (`skill_health.py:187`); measured bodies carry 8-10 |
| M-22 "Read when:" per reference | lazy | ~8 tokens per link | Measured from `context-compression/SKILL.md:259-270` |
| M-9/M-12/M-13 claim provenance + numeric-claim validator | **zero** | Applies to `spec/` and `registry/`, never to a context. Validator ~30-50 lines | `skill_health.py:49-69`, `:173-176` |
| M-18 registry `behavior_change` + `failure_modes` | zero | YAML fields in `registry/adoption-ledger.yml` | — |
| M-19/M-20/M-21/M-38/M-39/M-40 governance items | zero | Spec text only | — |
| M-25/M-27/M-28/M-31/M-33/M-35/M-37 findings | zero | Each is one to three sentences in spec/05, /09, /13, /15 | — |
| M-26 structured handoff schema | **per-action** | Required fields in a worker report. Cost is the report itself, which we already pay; the schema *reduces* variance and re-asking | `context-compression/SKILL.md:54-81` |
| M-34/M-36/M-41 contract clauses | lazy, in `verifier`/`diff-reviewer` contracts | ~100-150 tokens total | Estimate: three clauses condensed to ~6 lines |

**Nothing from this repo's 17 skill bodies or descriptions enters our listing.** Its
contribution is one fixture schema (zero cost), one description technique that must be
aggressively sized down, ~15 governance and failure-mode findings (zero cost), and a set of
named failure modes for the verifier and reviewer contracts (lazy, in text already paid for).

## 7. Coverage and limits (MANDATORY)

**Files read in full:**
`skills/context-compression/SKILL.md` (279L) · `researcher/fixtures/activation-cases.jsonl`
(4 of 23 objects read in full, all 23 line-counted) ·
`researcher/benchmarks/scenarios/adversarial.jsonl` (2 of 7) ·
`researcher/claims/index.jsonl` (2 of 26) · `researcher/mechanisms/registry.jsonl` (1 of 22) ·
`researcher/benchmarks/router/prompts.jsonl` (2 of 56) · `CLAUDE.md` (full, via project
context) · `LICENSE:1-3`.

**Files sampled (head/grep/partial only):**
Frontmatter of all 17 `skills/*/SKILL.md` + root `SKILL.md`, with line/word counts and
per-description char measurement · `## When to Activate` blocks (incl. the full
`Do not activate` list) of `multi-agent-patterns`, `tool-design`, `evaluation`,
`filesystem-context`, `bdi-mental-states`, `hosted-agents` · `## Gotchas` sections in full of
`long-horizon-prompting`, `self-improvement-loops`, `harness-engineering` · heading maps
(`grep '^## \|^### '`) of those same three · `researcher/scripts/skill_health.py:20-89` and
`:170-229` of 378 · line counts of all 17 `researcher/scripts/*.py` ·
root `SKILL.md:1-40` of 128 · `git ls-files researcher | head -50` of 96 ·
`git ls-files skills | grep -v SKILL.md` (all 40 supporting files listed, none opened).

**Not opened:**
**16 of 17 skill bodies** — `advanced-evaluation` (409L), `bdi-mental-states` (373L),
`context-degradation` (236L), `context-fundamentals` (210L), `context-optimization` (219L),
`evaluation` (284L), `filesystem-context` (296L), `harness-engineering` (234L — Gotchas only),
`hosted-agents` (301L), `latent-briefing` (167L), `long-horizon-prompting` (274L — Gotchas +
headings only), `memory-systems` (229L), `multi-agent-patterns` (267L),
`project-development` (304L), `self-improvement-loops` (254L — Gotchas only),
`tool-design` (296L) · all 40 skill supporting files, including 24 `references/*.md` and 12
`scripts/*.py` and `context-compression/tests/test_compression_evaluator.py` ·
**all 219 files under `examples/`** (5 projects: `book-sft-pipeline`, `digital-brain-skill`,
`llm-as-judge-skills`, `x-to-book-system`, `interleaved-thinking`) ·
**~90 of 96 files under `researcher/`** — notably `research_loop.py` (697L),
`validate_repo.py` (726L), `loop_step.py` (424L), `render_router_report.py` (403L),
`novelty_check.py` (276L), `validate_run.py` (265L), `loop_common.py` (228L),
`loop_daily.py` (218L), `validate_platform_compat.py` (214L), `check_activation_cases.py`
(145L), `run_benchmarks.py` (142L), `skill_frontmatter.py` (141L),
`compare_skill_revisions.py` (115L), all `researcher/rubrics/*`, `researcher/corpus/index.json`,
all three `router/results-published/*.md`, `benchmarks/goldens/adversarial-goldens.json`,
`benchmarks/sdk-runner/src/*.ts`, `benchmarks/effectiveness/tasks/**`,
`researcher/insights/*`, `researcher/llm-as-a-judge.md`, `orchestration/launchd/*` ·
all 9 `docs/*.md` · `README.md`, `CONTRIBUTING.md`, `AGENTS.md`, `CHANGELOG.md` ·
`.github/workflows/{validate,deploy-prompt-lab}.yml` · both plugin manifests · `assets/*`.

**Claims that need a live run before use:**
- Every `claim-*` id I cite (M-31's `claim-long-horizon-give-up-drift`, M-32's
  `claim-long-horizon-lean-prompt`, M-36's `claim-self-improvement-scorer-visibility`, M-10's
  `claim-context-compression-factory-benchmark`) — I read the **inline citation in the skill
  body**, and I read only 2 of 26 ledger entries. I did **not** verify that these specific ids
  exist in `researcher/claims/index.jsonl`, nor what their `source_url`, `evidence_strength`, or
  `volatility` values are. The *mechanism* (M-9/M-11, provenance is required and validated) is
  grade A from the script. The *individual claims* are **grade D until the ledger is read** —
  and M-32 in particular is load-bearing for §5.3, so it should be checked before we record a
  ruling on MUST/NEVER.
- M-32's "measurably degrade" is a claim about frontier-model behavior with no N, no model, and
  no date visible from the skill body. Treat as **B at best** pending the ledger entry.
- M-8's published router results: three dated files exist; I did not open them, so the actual
  routing accuracy of this 17-skill catalog is **unknown to me**. This matters — it is the one
  place in the corpus where someone measured whether description-level routing clauses actually
  work at 17 skills. Worth a follow-up read.
- M-43 (run state machine) is described in `CLAUDE.md`; `research_loop.py` (697L) is unread.
  Grade B on behavior.
- M-13's benchmark watchlist and M-12's regexes are read from source but I did not run
  `skill_health.py`, so I cannot confirm the gate currently passes at this SHA.

**Suspected but not verified:**
- `skill_health.py:197-198` scores `activation_score` and `mechanism_score` as **1.0 if ≥1 else
  0.5** — a floor of 0.5, not 0. So a skill with **no** activation case and **no** registered
  mechanism still scores 0.5 on both dimensions (0.10 + 0.10 weight ⇒ 0.10 of the total for
  free). Combined with `claim_score = 1.0` when `numeric_claims_total == 0` (`:193-196`), a
  skill containing no numbers, no activation case, and no mechanism collects full marks on
  three of eight dimensions **by omission**. If true this is a real hole in their gate, and it
  is the strongest concrete reason to prefer addyosmani's binary model. I read the scoring
  function but did not execute it against a crafted fixture, so: **suspected, not proven.**
- The `Do not activate` count of 17/17 came from `grep -c`, which counts *lines matching*, so
  each skill has exactly one such heading line. I verified the full block contents for only 7
  of 17 skills; the other 10 may have blocks of differing quality or entries that name no
  owning skill.
- `context-compression/SKILL.md:167-169` gives a compression-ratio table (98.6% / 98.7% /
  99.3%) with quality scores (3.70 / 3.44 / 3.35) on an unnamed scale, attributed to
  `claim-context-compression-factory-benchmark`. The body itself hedges — "Use these as
  source-specific benchmark figures, not universal constants" (`:171`) — which is good practice,
  but the scale is undefined in the body. Do not cite these numbers.
