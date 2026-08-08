# Repo Report — ECC

> **Path:** `_research/upstreams/ECC` ("Everything Claude Code")
> **SHA:** `9aac8585ab887d9c51252730240b25d9cca180da` (`git -C ECC rev-parse HEAD`)
> **License:** **MIT**, `LICENSE:1-3`: `MIT License` / `Copyright (c) 2026 Affaan Mustafa`.
> **But the repo-level grant is not the whole story, and this matters for reuse.** 18 of 282
> skills carry their own `license:` field in frontmatter, and `metadata.origin` shows **76 of
> 282 skills are not ECC-authored**: 42 `community`, 8 `ECC direct-port adaptation`, 1
> `ECC-community`, and 5 attributed to named third parties including
> `Health1 Super Speciality Hospitals — contributed by Dr. Keyur Patel` (×4),
> `"Ronald Skelton - Founder, RapportScore.ai"`, `oh-my-agent-check`, and `Flox`. Anything we
> lift must be checked against its own `origin`/`license` line, not the root LICENSE.
> **Size:** 3,438 tracked files. Verified composition by directory count this pass:
> **282 skills** (`SKILL.md` files), **67 agents**, **94 commands**, **122 rule files**,
> **11 JSON schemas**, **1,510 docs** — of which **1,399 are translations**
> (ja-JP 522, zh-CN 416, tr 142, es 142, ko-KR 64, zh-TW 58, pt-BR 47, de-DE 2, vi-VN 1),
> leaving ~111 English docs.
> **Read this pass:** all 282 skill frontmatter blocks (programmatically extracted and
> analysed); 8 skills read in full; 3 agents read in full; all 3 install manifests; 2 of 11
> schemas; the 4 count-bearing root files; the GateGuard skill in full. Prior coverage read
> it as a negative control only, never mined it.

## 1. What this repo is

A **plugin collection** for Claude Code — the largest artifact in this batch by an order of
magnitude, and the only one that is a *catalog* rather than a runtime, methodology, or
convention. It ships agents, skills, commands, rules, hooks, MCP configs, an install system,
and a partial Rust rewrite (`ecc2/`). It targets 12+ harnesses simultaneously
(`manifests/install-modules.json` `targets` arrays list `claude`, `cursor`, `antigravity`,
`codex`, `codebuddy`, `joycode`, `qwen`, `zed`, `hermes`, `openclaw`, `kimi`).

Our recorded verdict is "negative control: breadth without an enforced execution model."
That verdict survives this pass. **What does not survive is the claim that it contains
nothing worth taking.** See §3 — one skill in the library is better craft on our own core
problem than anything we have written.

## 2. Verifying the count-drift claim

Asked for explicitly. **The drift is real, larger than recorded, and internally
self-documented — which makes it a better case study than a simple inconsistency.**

| Source | Agents | Commands | Skills | Evidence `file:line` |
|---|---|---|---|---|
| **Directory count (ground truth, this pass)** | **67** | **94** | **282** | `git ls-files agents \| grep -c '\.md$'` = 67; `commands` = 94; `git ls-files skills \| grep -c 'SKILL.md$'` = 282 |
| `AGENTS.md` | 67 | 94 | 282 | `AGENTS.md:3`, and again `:154-155` |
| `README.md` | 67 | 94 | 282 | `README.md:119`, `:123-125`, `:969-971` |
| `SOUL.md` | **30** | **60** | **135** | `SOUL.md:4` |
| `WORKING-CONTEXT.md` | **47** | **79** | **181** | `WORKING-CONTEXT.md:13` |
| `README.md` release note | 67 | 94 | **281** | `README.md:1769` |

**Corrections to our recorded claim:**

1. **`AGENTS.md` is not wrong — it is exactly right.** `spec/key/02-repo-synthesis.md:594`
   says agents and commands were "verified by directory count this pass: 67 and 94". This
   pass confirms the skills figure too: **282 is accurate**. The framing of "counts disagree
   across its own files" is correct but should not imply `AGENTS.md` is among the wrong ones.
2. **The drift is worse than three-way.** `SOUL.md` is off by **factors of 2.2 / 1.6 / 2.1**,
   and `README.md:1769` says 281 skills while `README.md:124` says 282 — a **same-file**
   inconsistency, which is the sharpest single instance.
3. **The repo knows it drifts and has a process that keeps failing.**
   `WORKING-CONTEXT.md` is a running log of *catalog re-sync events*: `:117` records a sync
   at *"`36` agents, `68` commands, and `142` skills"*, `:145` a later one at
   *"(`38` agents, `72` commands, `156` skills)"*, `:147` *"re-synced the repo to `159`
   skills"*, `:149` *"re-synced the repo to `162` skills"*, `:151` *"brings the public
   catalog to `39` agents and `163` skills"*. So the current figure (`:13`, 181 skills) is
   **not a typo — it is a stale snapshot from a manual sync ritual performed at least five
   times and still 101 skills behind.**

**The actual lesson, which is not "they can't count":** they have *many* places that must be
updated by hand when the catalog changes, and no generated single source of truth. Every
count is a hand-maintained denormalization of a directory listing that a one-line command
produces exactly. The failure is **architectural, not clerical** — and it is the same failure
class as `.omp/policies/`: artifacts with no mechanical link to the thing they describe drift
to zero accuracy and stay there.

**Directly applicable to us.** Our `registry/*` and `spec/*` carry counts of agents, skills,
and settings keys. Any count we write by hand will drift. The remedy is not diligence — they
had diligence, five documented times — it is that a count must either be **generated** or
**asserted in a check that fails**. This is `spec/13`'s territory, and it is the single
highest-value thing this repo teaches, arriving as a negative result.

## 3. Mining: how I sampled, and what passed the filter

### 3.1 Sampling method (stated, because "systematically not randomly" was the instruction)

Random sampling of 282 skills would waste the budget on `energy-procurement` and
`customs-trade-compliance`. I used **four deterministic strata**, all computed over the full
population, so nothing was chosen by impression:

- **Stratum A — full-population frontmatter census.** Extracted `name` + `description` from
  all 282 `SKILL.md` files programmatically. This is 100% coverage of the *routing surface*,
  which is also the only part OMP would inject (§4). Gave: description length distribution
  (min 14, p50 197, p90 324, max 992 chars), `metadata.origin` distribution, `license:`
  presence, and the count of skills using explicit `TRIGGER when` / `DO NOT TRIGGER` routing
  hints (**4 of 282**).
- **Stratum B — name-match against our four workers and our metric.** Grepped skill and agent
  names for `verif|review|explor|implement|test|debug` and for the meta-layer
  `skill|agent|prompt|context|token|orchestr|subagent|memory|learn`. Everything a template
  with an explorer/implementer/verifier/diff-reviewer could plausibly borrow is in this set.
- **Stratum C — the mechanism layer, not the content layer.** All 3 install manifests, 11
  schema *names* (2 read in full), and the hook-bearing skills. Rationale: a catalog's
  transferable engineering is in how it *manages* 282 items, not in item 147.
- **Stratum D — the outliers.** Largest skills by bytes (top 20) and largest agents by bytes
  (top 25), to see whether size correlates with substance. It does not: the top of the skill
  list is `windows-desktop-e2e` (30 KB), `quality-nonconformance` (30 KB),
  `energy-procurement` (30 KB) — domain content, irrelevant to us.

**Read in full (11 files):** `skills/loop-design-check`, `skills/gateguard`,
`skills/context-budget`, `skills/verification-loop`, `skills/delivery-gate`,
`skills/strategic-compact`, `skills/recursive-decision-ledger` (partial, ~70 lines),
`skills/skill-stocktake` (partial, ~70 lines), `skills/token-budget-advisor` (partial, ~60
lines), `agents/code-explorer`, `agents/gan-evaluator` (partial). Plus all 3 manifests and
2 schemas.

### 3.2 What passed

**One find is genuinely excellent, and I want to be plain that it is better than what we
have written on the same subject.**

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| **`loop-design-check`'s five failure modes + boundary-with-done-criterion + independent judge** (`skills/loop-design-check/SKILL.md:100-113`) | `/orchestrated` and `/standard` command bodies; the verifier and diff-reviewer agent bodies | `zero` — ~10 lines of prose in files already loaded when the command runs | **ADOPT** | Detail below. This is the best single artifact in 3,438 files and it lands squarely on our headline metric |
| **"Prefer reconciliation over assertion for the done-criterion"** (`:56`) | Verifier agent body; acceptance criteria in `/standard` | `zero` | **ADOPT** | *"'All tests pass' can be gamed (loosen asserts, fake mocks, swallow exceptions); 'diff vs the reference < 0.01' can't."* An anchor to external fact outranks a self-produced assertion. Our verifier currently accepts "tests pass" as terminal |
| **Front-load every clarification; a loop will not stop to ask** (`:106`, failure mode #4) | Task-packet convention | `zero` | **ADOPT** | *"Counts on the agent asking mid-run → **it won't; it runs the wrong answer to the end**."* This is our false-completion mode stated as a design rule, and it converges with 12-factor F13 (pre-fetch) from a completely different direction — one from token economics, one from failure analysis |
| **The 4-condition build gate** (`:37-40`) | `spec/13`, or the decision log | `zero` | **ADAPT** | *"① the task repeats weekly or more ② verification can be automated ③ the token budget can take it ④ the agent has tools that actually run and see the result. Miss any one → don't build a loop."* A subtract-first gate. *"A repo that doesn't deserve a loop will only have its errors amplified by one"* (`:40`) is the `.omp/policies/` lesson stated prospectively |
| **Install modules with a declared `cost` tier** (`manifests/install-modules.json`; `schemas/install-modules.schema.json:78-85` enums `light\|medium\|heavy`, and `:103-104` makes `cost` **and** `stability` *required*) | `spec/12` (installation) and `spec/14` (governance) | `zero` at runtime | **ADAPT** | 34 modules, each with required `cost` and `stability` (7 `beta` / 27 `stable`), composed into named profiles. `install-profiles.json` even ships a `minimal` profile described as *"Low-context … but no hook runtime"*. **A catalog that made cost a required schema field.** Our skill cap of 10 is a number in prose; theirs is a required field a validator can enforce |
| **`context-budget`'s per-component token attribution** (`skills/context-budget/SKILL.md:26-49`, `:130-136`) | `spec/05 §I` budget check; `spec/13` L1 | `lazy` if ever a skill; `zero` as a check | **ADAPT** | Two lines are directly ours: *"Agent descriptions are loaded always: even if the agent is never invoked, its description field is present in every Task tool context"* (`:134`) and *"each tool schema costs ~500 tokens; a 30-tool server costs more than all your skills combined"* (`:133`). The second reframes our cap-at-10 debate: if MCP tool schemas dominate, we are optimizing the smaller term |
| **`delivery-gate`'s deterministic/inferential split** (`skills/delivery-gate/SKILL.md:11-17`, `:21-28`) | Verifier vs diff-reviewer division of labour | `zero` | **ADAPT** | *"delivery-gate checks machine-verifiable facts; self-audit checks output quality"* — and crucially, the regex heuristic **never blocks on its own** *"because regex heuristics can false-positive"* (`:28`). A gate that knows which of its signals are trustworthy enough to block. Our verifier/diff-reviewer split is the same idea without the stated rule |
| **`skill-stocktake`'s change-diff mode** (`skills/skill-stocktake/SKILL.md`, Quick Scan flow) | `spec/13` eval harness | `zero` design; `per-spawn` when run | **DEFER** | Re-evaluate only what changed since a cached `results.json`; if the diff is empty, *report "No changes since last run." and stop*. Correct instinct for a re-runnable eval. **Trigger:** when `spec/13`'s harness exists and full re-runs become the bottleneck. Not before |

**The loop-design-check detail, because it earns it.** 143 lines. Its structure is
write-a-loop (5 steps) then review-a-loop (5 failure modes + 3 red lines), and the review
half is the part we need:

- **#2** — *"'Verification' written as 'check if it looks ok' → agent confidently says fine
  and stops."* Review question: *"Is the judge the defendant itself?"* Antibody: independent
  judge, deterministic rules. **This is false-completion, named and diagnosed.**
- **#3**, which they mark *(worst)* — *"Only gates on 'all tests pass' → agent deletes the
  tests."* Antibody: *"Done-criterion **+ boundary** together (the Goodhart antibody)."*
- The **three iron rules** on plan/build/judge (`:76`): *"① the judge must be independent —
  not the same agent as Build (grading your own homework always inflates); ② deterministic
  rules — pytest / reconciliation diff / type check / diff, never 'looks right'; ③ Build may
  not edit the acceptance conditions to pass."*
- The **worked example** (`:115-127`) reviews a naive "fix the failing tests overnight" loop
  and catches #3, #2, #4, and a red line, closing: *"The naive loop and the reviewed loop
  differ by four lines of constraint — and that's the difference between 'wakes you to a
  deleted test suite' and 'wakes you to a clean PR.'"*

Iron rule ③ is a specific gap in our design worth stating on its own: **our implementer
must not be able to edit the acceptance criteria it is judged against.** Our `/standard`
flow has the coordinator set criteria and the implementer work; nothing in the spec forbids
the implementer from proposing revised criteria that the coordinator then accepts. That is
the Goodhart channel, in our own topology.

Two honest caveats. First, the skill's own *mechanism* half (servo/regulator loop types,
`/goal`, `/loop`, `/schedule`, cron) is a loop controller — **rejected by constraint**; only
the judgment half transfers. Second, it is 143 lines of unmeasured prose. Its five failure
modes are asserted from experience, not measured. Grade **C** on efficacy, **A** on what it
says.

## 4. Pricing the negative lesson: what 282 skills cost a session

Asked for explicitly, and it is the sharpest number in this report.

**The mechanism, verified.** OMP renders the skill listing into the system prompt as
`- {{name}}: {{description}}` per skill (`prompts/system/system-prompt.md:29-33`, inside
`<skills>`), preceded by *"If one matches your task, you MUST read `skill://<name>`"*. The
listing is built from `loadSkills(...)` (`system-prompt.ts:716-721`) and **the same `skills`
array is passed into every subagent spawn** (`task/executor.ts:3025`: `skills:
options.skills`). The subagent's prompt is the default prompt with the agent body spliced in
(`:3031-3046`) — the skills block is *not* removed. So the listing is `persistent` in the
coordinator **and re-paid in full per spawn**.

**The measurement.** I rendered ECC's 282 skills in exactly OMP's format — extracted `name`
and `description` from each of the 282 `SKILL.md` frontmatter blocks and emitted
`- name: description`:

- **282 lines, 62,821 characters**
- **≈ 17,400 tokens** (chars ÷ 3.6; **estimate**, basis: mixed prose-with-identifiers, which
  tokenizes denser than the ÷4 rule of thumb for pure code and looser than ÷1.3-per-word for
  pure prose)
- Description length: min 14, **p50 197**, p90 324, max **992** characters

**The cost, per session:**

| Scenario | Skill-listing tokens |
|---|---|
| Coordinator only, one turn | ~17,400 |
| Coordinator + 4 worker spawns (`/standard`) | ~87,000 |
| Coordinator + 10 spawns (a plausible `/orchestrated` run) | **~191,000** |

**~191,000 tokens of pure catalog listing** — before a single file is read, a single task
described, or a single result returned. Against a 200K window that is the entire budget; even
on a 1M window it is ~19% consumed by a table of contents.

**Our cap of 10 skills, same arithmetic:** at ECC's median description (197 chars), 10 skills
≈ 2,000 chars ≈ **560 tokens**; ×11 contexts ≈ **6,100 tokens**. That is **1/31st** of ECC's
figure. The cap is not conservatism — it is the difference between a workable session and an
unworkable one.

**Two refinements that change how we should spend the cap:**

1. **Description length is the lever, not skill count.** ECC's p90 is 324 chars and its max is
   992 (`loop-design-check` itself, whose description is a 992-char multilingual trigger
   list). Ten skills at 992 chars ≈ 2,750 tokens × 11 ≈ **30,000 tokens** — *more than 50
   skills at 197 chars in the coordinator alone*. **The budget constraint should be stated in
   characters of listing, not in number of skills.** A 10-skill cap with no length bound is
   an unbounded cap.
2. **ECC's own advice contradicts ECC's own catalog, usefully.** `context-budget:133` says
   *"each tool schema costs ~500 tokens; a 30-tool server costs more than all your skills
   combined."* At 17,400 tokens their listing exceeds a 30-tool MCP server by ~15%. Their
   auditing skill's rule of thumb was written for a much smaller catalog and never revisited.
   **A cost heuristic outlives the conditions that made it true** — which argues our cap
   needs a *check*, not a *convention* (§2's lesson again).

**Corollary for `spec/11`:** ECC's structure — 282 skills across 34 install modules, only a
subset installed per profile — is the *right* architecture for a large catalog: subset at
install time so the listing only carries what is active. We cannot use it (a 10-skill library
needs no module system), but it explains why breadth is *possible* for them and impossible
for us. Their `minimal` profile exists for exactly this reason. **If our library ever needs
to exceed the cap, install-time subsetting with a declared `cost` field is the shape to
copy** — not lazy loading, which does not help because the *listing* is what costs.

## 5. GateGuard: the case study in unverified quantitative claims

Asked for explicitly. The claim is worse-constructed than reported, and instructively so.

**What is claimed.** The `description` — the field OMP injects into every context — asserts:
*"Measurably improves output quality by +2.25 points vs ungated agents"*
(`skills/gateguard/SKILL.md:3`). The body, under the heading **`## Evidence`** (`:35`), gives:

> *"Two independent A/B tests, identical agents, same task:"*
>
> | Task | Gated | Ungated | Gap |
> | Analytics module | 8.0/10 | 6.5/10 | +1.5 |
> | Webhook validator | 10.0/10 | 7.0/10 | +3.0 |
> | **Average** | **9.0** | **6.75** | **+2.25** |
>
> — `:37-43`

**What is wrong with it, in ascending order of severity:**

1. **n = 2.** Two tasks, one trial each. With observations of +1.5 and +3.0 the spread is
   twice the smaller effect. No variance is reportable from n=2, and none is reported.
2. **The rubric is undefined.** Scores are "8.0/10" against no published rubric, no anchors,
   and no statement of who or what scored. The body says the difference is *"design depth"*
   (`:45`) — an unoperationalized construct.
3. **The judge is unnamed and probably not independent.** If an LLM scored, this is
   `loop-design-check`'s failure mode #2 — *"Is the judge the defendant itself?"* — **from
   the same repository, 273 directories away.**
4. **No raw data, no protocol, no seeds, no model version.** "Two independent A/B tests" is
   the entire method section. Nothing is reproducible.
5. **The confound is stated by the authors and not controlled.** `:121`: *"Both A/B test
   agents assumed ISO-8601 dates when real data used `%Y/%m/%d %H:%M`."* Both arms shared a
   defect that the gate's data-schema question targets directly. That is not a test of
   gating in general — it is one favourable instance, in a sample of two.
6. **Aggregation is invalid even granting everything.** Averaging two ordinal rubric scores
   into "9.0 vs 6.75" and reporting a difference to **three significant figures** from n=2 is
   false precision on its face.
7. **"Measurably" is doing rhetorical work.** The word converts an anecdote into an apparent
   measurement, and it sits in the field with the widest distribution in the whole system —
   every context, every spawn.
8. **A stronger claim nearby has no evidence at all.** `:21`: *"LLM self-evaluation doesn't
   work … This is verified experimentally."* No experiment, no citation, no data. Repeated at
   `:120`.
9. **Uninspectable numbers sit beside inspectable ones.** `:120` also reports *"4 rounds of
   automated code review (CodeRabbit + Greptile) with 9 real bugs found and fixed"* — a
   checkable claim in the same file, which makes the unbacked ones look equally solid by
   association.

**What evidence would have been needed.** For a claim of the form *"gating improves output
quality by X points"*:

- **n ≥ 30 tasks per arm**, drawn from a pre-registered pool, with the sampling frame stated.
- **A published rubric** with per-dimension anchors, released *before* scoring.
- **Blind scoring by a judge independent of the gate's author**, ideally ≥2 raters with an
  inter-rater agreement statistic. If an LLM judge, then its model, prompt, and temperature,
  plus a human-agreement calibration on a subsample.
- **Effect size with a confidence interval**, not a point difference. "+2.25" without a CI is
  not a result.
- **Both arms identical except the gate** — same model version, same seeds where available,
  same task order, randomized assignment.
- **A cost column.** The gate spends turns (deny → investigate → retry). A quality gain of
  +2.25 at 3× the tokens may be a *loss* on tokens-per-accepted-outcome. **No cost is
  reported anywhere.** This is the omission that matters most for us: by our metric the study
  does not even measure the right quantity.
- **Published raw data**, so a reader can recompute.
- **A pre-registered hypothesis**, so the two tasks are not selected post hoc.

**The honest complication, which I will not paper over: the underlying mechanism is probably
sound.** *"asking 'list every file that imports this module' forces the LLM to run Grep and
Read. The investigation itself creates context that changes the output"* (`:23`) is a
plausible and testable claim, convergent with 12-factor F13 (pre-fetch) and with
mini-swe-agent's separated submission protocol (read the patch before submitting). **The
mechanism deserves a real experiment; the claim as written is not one.** The failure is not
that they were wrong — it is that they attached a number to an intuition and put the number
in the field with the widest blast radius in the system.

**Why this belongs in our decision log.** This is the exact pattern named in
`_CONTRACT.md`'s anti-patterns as *"unpriced quality claims"* and identified as *"the exact
pattern that produced nine inert YAML files."* GateGuard is the mature form: an unpriced
quality claim that acquired a decimal point. **Any number in our spec that cannot name its
n, its rubric, its judge, and its cost should be marked grade D and stripped of its decimal
places.**

## 6. Cost profile

| §3 row | Where paid | Estimate and basis |
|---|---|---|
| `loop-design-check` judgment half (5 failure modes, boundary+done-criterion, independent judge, iron rule ③) | `zero` marginal — prose in workflow command bodies and agent bodies already loaded when used | ~250–400 tokens total if compressed to the 5 review questions + 3 iron rules (**estimate**, ~1.3 tokens/word). We would **not** import the 143-line skill; we would extract ~15 lines |
| Reconciliation-over-assertion | `zero` | ~40 tokens in the verifier body. May *increase* `per-action` cost if it means running an extra reconciliation command — that is the point of the rule, and it should be priced when the verifier is written |
| Front-load clarifications | `zero` to state; `per-spawn` to honour (bigger packets) | Same trade as 12-factor F13: ~100–300 tokens of packet against 2–5 discovery turns. Two upstreams now independently recommend it, which raises confidence in direction but not in magnitude |
| 4-condition build gate | `zero` | A decision-log entry. Costs nothing and vetoes work |
| `cost` as a required schema field | `zero` at runtime | Authoring + a `spec/13` check. The check is the whole value; a `cost` field nobody validates is `.omp/policies/` |
| `context-budget` attribution rules | `zero` as a check; **`lazy`** if ever a skill (it should not be — it would consume 1/10th of the cap to audit the cap) | Its two useful lines are ~50 tokens folded into `spec/05` |
| `delivery-gate` deterministic/inferential split | `zero` | ~30 tokens of division-of-labour rule |
| `skill-stocktake` change-diff | — | DEFER; no cost until `spec/13` exists |
| **The catalog itself (negative)** | `persistent` **× (1 + spawns)** | **~17,400 tokens per context; ~191,000 for a 10-spawn run.** Measured this pass. The reason we ship 10, not 282 |

## 7. Coverage and limits  (MANDATORY)

**Files read in full (16):**
- Skills (5 complete): `skills/loop-design-check/SKILL.md` (143 lines),
  `skills/gateguard/SKILL.md` (134), `skills/context-budget/SKILL.md` (137),
  `skills/verification-loop/SKILL.md` (130), `skills/delivery-gate/SKILL.md` (127)
- Skills (partial, ~60–70 lines each): `skills/strategic-compact/SKILL.md`,
  `skills/recursive-decision-ledger/SKILL.md`, `skills/skill-stocktake/SKILL.md`,
  `skills/token-budget-advisor/SKILL.md`
- Agents: `agents/code-explorer.md` (79 lines, complete); `agents/gan-evaluator.md`
  (frontmatter + first ~60 lines)
- Manifests (all 3, complete): `manifests/install-modules.json`,
  `manifests/install-profiles.json`, `manifests/install-components.json`
- Schemas (2 of 11): `schemas/install-modules.schema.json`,
  `schemas/provenance.schema.json`
- `LICENSE` head
- OMP cross-checks for §4, opened to verify the cited lines only:
  `prompts/system/system-prompt.md:20-45`, `system-prompt.ts:716-721`,
  `task/executor.ts:3020-3046`

**Programmatic full-population analysis (100% of a defined surface):**
- **All 282 `SKILL.md` frontmatter blocks** — `name`, `description`, `metadata.origin`,
  `license`. This is complete coverage of the *routing surface* and is what §4's 17,400-token
  figure is computed from. It is **not** coverage of the 282 bodies.
- **All 67 agent frontmatter blocks** — field census: 67 each have `name`, `description`,
  `model`, `tools`; 5 add `color`. No agent uses an output-schema field.
- Directory counts for every component type; `docs/` locale breakdown; `wc -c` size
  distributions for all skills and all agents; consecutive-duplicate-line scan across all 67
  agents (found 1 file affected, `agents/homelab-architect.md`).
- `grep` census of routing-hint style: **4 of 282** skills use `TRIGGER when` /
  `DO NOT TRIGGER`; **48 of 282** use "use this skill when" phrasing.

**Not opened — and this is the large number:**
- **271 of 282 skill bodies.** I read 5 fully and 4 partially. **This is the dominant limit
  of the report.** My claim that `loop-design-check` is the best artifact in the repo is a
  claim about the ~11 bodies I read plus 282 descriptions, not about 282 bodies. There is
  plausibly comparable craft in bodies I never opened — Stratum B surfaced
  `agent-self-evaluation`, `agent-architecture-audit`, `agent-harness-construction`,
  `agent-eval`, `eval-harness`, `benchmark-methodology`, `prompt-optimizer`,
  `parallel-execution-optimizer`, `plan-orchestrate`, `team-agent-orchestration`,
  `dynamic-workflow-mode`, `intent-driven-development`, and `iterative-retrieval` as
  plausibly relevant by name, and **I opened none of them.** A follow-up pass on that named
  list of 13 is the highest-value remaining work on this repo.
- **64 of 67 agent bodies.** I read 1 fully, 1 partially, and censused all 67 frontmatters.
  25 are language-specific reviewers (`java-reviewer`, `vue-reviewer`, …); I read none, and
  reviewer craft is directly relevant to our diff-reviewer.
- **All 94 commands.** Not one opened. Our workflow commands (`/quick`, `/standard`,
  `/orchestrated`) are the closest analogue to a command, so this is a real gap.
- **All 122 rule files.** Two were visible to me only because they appear in this session's
  CLAUDE.md context (`everything-claude-code-guardrails.md`, `node.md`) — I did not open them
  from the clone and do not treat them as read.
- **9 of 11 schemas**, including `hooks.schema.json`, `memory.schema.json`,
  `state-store.schema.json`, `plugin.schema.json`.
- **All 247 script files and all 239 test files.** So every hook mechanism named in a skill
  body — `scripts/hooks/gateguard-fact-force.js` (`gateguard:96`),
  `skills/delivery-gate/hooks/quality-gate.py`, `suggest-compact.js` — is **unverified as
  implemented**. I described what the skills *say* their hooks do.
- **All 1,510 docs** (1,399 translations + ~111 English), including
  `docs/ECC-2.0-GA-ROADMAP.md` and `docs/ECC-PRO-SECURITY-ROADMAP.md`, which mention
  GateGuard and might contain the missing methodology. **If a real GateGuard study exists in
  `docs/`, §5 would need revision.** I grepped for `2.25` across all `*.md` and found only
  the skill file and its ja-JP/zh-CN translations — which is evidence against a fuller study
  existing, but grep for one number is not a search for a methodology.
- **`ecc2/`** (21 files, Rust), `.kiro/` (153), `.agents/` (89), `.opencode/` (81),
  `.cursor/` (69), `legacy-command-shims/` (13), `docker/`, `integrations/`, `scaffolds/`,
  `plugins/`, `contexts/`, `examples/`, `assets/`.

**Claims that need a live run before use:**
- The **17,400-token** listing figure. The *character* count (62,821) is exact — I rendered
  all 282 lines in OMP's format. The token conversion is an estimate at chars÷3.6; a real
  tokenizer could move it ±25%. The ~191,000 multi-spawn figure inherits that uncertainty
  **and** assumes 10 spawns each paying the full listing. I verified the mechanism
  (`task/executor.ts:3025` passes `skills` into the spawn; the subagent prompt splice at
  `:3031-3046` preserves the default prompt's skills block) but **did not observe a rendered
  subagent prompt** to confirm the block appears verbatim. That single observation would move
  §4 from B to A and is cheap.
- Whether the `cost` field in `install-modules.json` is *consumed* by anything, or is
  documentation. It is schema-**required** (`install-modules.schema.json:103-104`), which is
  stronger than convention, but I did not read the installer (`scripts/`, unopened). If
  nothing reads it, this is their `.omp/policies/` and my ADAPT verdict should downgrade.
- Whether `loop-design-check`'s five failure modes actually reduce false completions. Grade
  **C** on efficacy. Adopting it is adopting well-argued prose, and we should say so rather
  than let its quality imply evidence.

**Anything I suspect but could not verify:**
- I suspect the 42 `community`-origin skills are the most variable in quality, and that
  `loop-design-check` (origin `ECC`) being excellent while `gateguard` (origin `community`)
  carries the fabricated statistic is not a coincidence. **n=2 on my side — the same error I
  criticize in §5.** Stated as a hypothesis for a future pass, not a finding.
- I suspect the count drift is *worse* than the 6 sources I found. I grepped 4 root files and
  `README.md`; 1,510 docs and 122 rules are unchecked, and translations were almost certainly
  synced at different times than their English originals (`docs/ja-JP/skills/gateguard/`
  carries the same `+2.25` table, so at least the translation pipeline propagates content
  faithfully).
- I suspect the 992-char `loop-design-check` description exists because its author was
  fighting for routing attention in a 282-skill listing — the description includes
  `中文触发：…` plus `English triggers: …` keyword lists. **If true, that is an emergent
  cost of catalog size: skills inflate their descriptions to be found, which inflates the
  listing, which makes finding harder.** A plausible feedback loop, and directly relevant to
  our cap — but I did not test it (e.g. by correlating description length against catalog
  growth in git history), so it is a suspicion.
