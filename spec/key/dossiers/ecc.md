# Dossier: ECC (Everything Claude Code)

**Upstream:** `_research/upstreams/ECC` @ `9aac8585ab887d9c51252730240b25d9cca180da` (2026-08-06)
**Surveyed:** this pass, read-only. All line citations verified against the commit above.
**Scale:** 3,438 files — 67 agents, 282 skills, 94 commands, 122 rule files, 11 JSON schemas, 1,510 docs.

## What ECC is

A Claude Code **plugin** — an aggregation surface for agents, skills, commands, hooks, rules,
and MCP configs. Not a runtime. It ships breadth (67 agents, 282 skills) rather than an
enforced execution model.

ECC's own catalog counts disagree across its own files: `AGENTS.md:3` says 282 skills / 67
agents / 94 commands; `SOUL.md:4` says 30 agents / 135 skills / 60 commands;
`WORKING-CONTEXT.md` says 47 agents / 79 commands / 181 skills. That drift is itself the
diagnostic — ECC has no single source of truth for its own surface.

## Architectural relationship to omp-template

ECC is **breadth-first and additive**; omp-template is **depth-first and constrained**.

ECC has no context-budget *enforcement* (its `context-budget` skill is a manual audit, not a
policy), no structured result schemas between agents, and no workflow-sizing gate.
omp-template already has all three (`template/.omp/policies/*.yml`,
`template/.omp/schemas/*.schema.yml`).

So the value in ECC is **not architecture**. It is a set of specific mechanisms ECC got right
that omp-template's spec does not yet encode.

---

## Tier 1 — mechanisms worth adopting

### 1. False-positive control as an explicit reviewer contract

`agents/code-reviewer.md` — the strongest single file in the repo. Four parts:

- **Pre-Report Gate** (`:39-53`) — four questions before writing any finding: can I cite the
  exact line; can I name the concrete failure mode (input, state, bad outcome); have I read
  the surrounding context (callers, imports, tests); is the severity defensible. Any "no" or
  "unsure" ⇒ downgrade or drop.
- **HIGH/CRITICAL require proof** (`:55-64`) — exact snippet + line, specific failure scenario,
  and why existing guards (types, validation, framework defaults) do not catch it. "If you
  cannot produce all three, demote to MEDIUM or drop."
- **Named false-positive catalog** (`:76-111`) — 12 concrete patterns LLM reviewers mis-flag,
  each with its disqualifying condition. Examples: "consider adding error handling" when the
  caller or framework handles it; "magic number" for `200`/`404`/`1024`/`-1`; "function too
  long" for exhaustive switches or test tables ("length is not complexity"); "missing await"
  on intentionally detached fire-and-forget; security theater (`Math.random()` in animation
  or jitter, `eval` in a plugin system that *is* a code-loading surface). Closes with the
  calibration question: *"Would a senior engineer on this team actually change this in
  review?"*
- **Explicit permission to return nothing** (`:66-74`, `:297`) — "A clean review is a valid
  review. Do not manufacture findings to justify the invocation." And: "Do not withhold
  approval to appear rigorous."

**Delta for omp-template:** `template/.omp/agents/reviewer.md` has a "False-positive control
(mandatory)" section, but it is 4 generic bullets. ECC's version is a *catalog* — that is what
makes it operational. Port the catalog into `spec/10-verification-and-review.md` or the
reviewer agent.

### 2. Fail-closed adversarial verification of findings

`workflows/orch-review.workflow.js` — the most sophisticated executable in the repo. A second
pass that attempts to *refute* each CRITICAL/HIGH finding, with three failure modes explicitly
kept blocking:

- unverifiable ⇒ marked `unverified`, stays blocking; "an unverifiable CRITICAL must never be
  demoted" (`:247-248`)
- refuted but below `REFUTE_MIN_CONFIDENCE` ⇒ `uncertain`, stays blocking — "uncertainty must
  never demote a blocker" (`:259-260`, `:266`)
- a review dimension that *failed to run* ⇒ the whole verdict fails closed (`:214`)

Plus a subtle correctness rule: the verifier is told not to refute a finding merely because the
file is absent from the working tree, since the diff may be unapplied (`:130`).

Output contract: `{ verdict, incomplete, failedDimensions, blocking[], advisory[], stats }`
(`:29-31`).

**Delta for omp-template:** this is the missing half of false-positive control. ECC pairs
"don't over-report" with "uncertainty is not a refutation." omp-template's
`review-result.schema.yml` has BLOCKING/NON_BLOCKING/OBSERVATION but no verification stage and
no fail-closed rule.

### 3. Investigation-forcing gates instead of self-evaluation

`skills/gateguard/SKILL.md:21-34`:

> LLM self-evaluation doesn't work. Ask "did you violate any policies?" and the answer is
> always "no." This is verified experimentally. But asking "list every file that imports this
> module" forces the LLM to run Grep and Read. The investigation itself creates context that
> changes the output.

Three-stage gate: **DENY → FORCE → ALLOW**. First Edit/Write per file is blocked; four facts
demanded: (1) all files that import this file, (2) affected public functions/classes, (3) data
file schemas *with redacted or synthetic values*, (4) the user's current instruction quoted
verbatim. Destructive Bash gates every time; routine Bash gates once per session (`:75-90`).

Claimed effect: +2.25/10 average across two A/B tasks (8.0 vs 6.5, 10.0 vs 7.0) (`:35-43`).
**n=2 — treat as directional, not established.**

The load-bearing detail is in the anti-patterns (`:121`): both A/B agents assumed ISO-8601
dates when the real data used `%Y/%m/%d %H:%M`. Forcing a schema check eliminates that entire
bug class.

Implementation (`scripts/hooks/gateguard-fact-force.js`, 1,278 lines) solves the obvious
failure mode: only the first `GATEGUARD_FACT_FORCE_FULL_DENIALS` (default 3) denials print the
full four-fact block; later denials condense to one line, so near-identical blocks cannot
accumulate in the context window and amplify repetition loops. Also ships
`GATEGUARD_EXEMPT_GLOBS` for trees where "who imports this" carries no signal (tests,
generated artifacts, scratch dirs), and fails open on malformed operator regex rather than
crashing tool execution.

**Delta for omp-template:** a genuinely different lever from anything currently in the spec —
a *pre-action epistemics gate*, not a post-action review.

### 4. Separation of generation from evaluation, stated as a tractability claim

`skills/gan-style-harness/SKILL.md:17`:

> When asked to evaluate their own work, agents are pathological optimists — they praise
> mediocre output and talk themselves out of legitimate issues. But engineering a **separate
> evaluator** to be ruthlessly strict is far more tractable than teaching a generator to
> self-critique.

`agents/gan-evaluator.md:24-35` operationalizes it: "Your natural tendency is to be generous.
Fight it." Named cope-phrases banned ("overall good effort", "solid foundation"); "do NOT talk
yourself out of issues you found"; no points for effort or potential. Scoring calibration
(`:109-116`) anchors each point 1-10 to a human-quality referent (4-5 = "functional but
clearly AI-generated, tutorial-quality"; 7 = "a junior developer's solid work").

Two anti-patterns are direct constraints on omp-template's verifier/reviewer split:
- feedback must pass as a **file**, not inline (`:250`)
- the evaluator must **never** suggest a fix then evaluate that fix — "the evaluator only
  critiques; the generator fixes" (`:256`)

Best paragraph in ECC for design rationale, the harness-evolution principle (`:196-218`):

> Every harness component encodes an assumption about what the model can't do alone. When
> models improve, re-test those assumptions. Strip away what's no longer needed.

### 5. Anti-anchoring via context isolation — stated twice, independently

`skills/santa-method/SKILL.md` — dual independent reviewers, both must pass (`:48`); "if only
one reviewer catches an issue, that issue is real. The other reviewer's blind spot is exactly
the failure mode Santa Method exists to eliminate" (`:174`); fresh agents each round because
"prior context creates anchoring bias" (`:204`); max 3 iterations then escalate to human
(`:179-201`). Rubber-stamping mitigation is an explicit adversarial prompt: "Your job is to
find problems, not approve" (`:273`). Cost stated honestly at 2-3x generation (`:298-307`).

`skills/council/SKILL.md:53` — subagents get "**only the question and relevant context**, not
the full ongoing conversation. That is the anti-anchoring mechanism." Plus self-bias
guardrails: form your own position *before* reading the others (`:76`); "if two voices align
against your initial position, treat that as a real signal" (`:118-127`); always surface the
strongest dissent even if rejected.

**Delta for omp-template:** `RULES.md:4` already forbids forwarding parent transcripts, but
frames it as a *context-budget* rule. ECC's framing is stronger: it is an **epistemic
independence** rule. That reframing implies things the budget framing does not — fresh agents
per review round, and not feeding round N-1's verdict into round N.

### 6. Ceremony proportional to blast radius, as a scored table

`skills/orch-pipeline/SKILL.md:39-50` — four tiers (trivial / small / standard / large) scored
on three signals: files touched, new dependency or contract, design ambiguity. **Take the
highest tier any signal reaches.** Each tier gets a phase mask. Tie-breaker: anything touching
a security trigger or a public API/contract is *at least* standard, regardless of file count.
Convention: state the resulting tier in one line so the user can override.

Two human gates (`:78-85`): **GATE 1** after Plan (present task list, write no implementation
code until approved); **GATE 2** before Commit (present diff summary and proposed messages).
"Everything between the gates flows without stopping."

Security reviewer is pulled in **iff** the diff touches a named trigger list — auth/authz, user
input, DB queries, filesystem paths, external API calls, crypto, secrets (`:100-104`) — and
that trigger list exists as an executable regex in
`workflows/orch-review.workflow.js:48-49`.

Handoff is explicitly stateless: "The pipeline carries no hidden state — the planning docs *are*
the handoff" (`:108`).

**Delta for omp-template:** `workflow-sizing.yml` has 3 tiers with prose `use_when` lists.
ECC's max-of-three-signals rule plus the escape-hatch tie-breaker is a more decidable
classifier.

---

## Tier 2 — useful, narrower

**`skills/context-budget/SKILL.md`** — the numbers are the value:
- `words × 1.3` for prose, `chars / 4` for code-heavy files (`:132`)
- ~500 tokens per MCP tool schema, so "a 30-tool server costs more than all your skills
  combined" (`:133`)
- agent `description` frontmatter is present in **every** Task invocation whether or not the
  agent runs (`:134`); flag descriptions >30 words (`:64`)
- three-bucket classification: always needed / sometimes needed / rarely needed (`:56-58`)

Directly calibrates omp-template's `context-budget.yml`, which currently asserts token ranges
without an estimation method.

**`skills/delivery-gate/SKILL.md`** — the *taxonomy* is the contribution: deterministic
machine-verifiable checks (mtime, disk usage, regex) vs. reasoning gates — "together they form
defense in depth" (`:11-17`). Regex rationalization detection is **warning-only, never blocks**
because heuristics false-positive (`:23`, `:28`). And an honest self-limitation: "enforces the
**habit** of touching learning libraries, not the **quality** of what was recorded"
(`:108-110`). That is the right shape for any lint-like gate in a spec.

**`skills/strategic-compact/SKILL.md`** — "Tool count alone is a weak proxy for window
pressure" (`:39`), so it reads real `usage` records from the transcript and sums
`input_tokens + cache_read_input_tokens + cache_creation_input_tokens`. Window-scaled
thresholds (160k on 200k, 250k on 1M). Per-transition compact table (`:76-87`) where the two
most useful rows are the negative ones: **never mid-implementation** ("losing variable names,
file paths, and partial state is costly"), **always after a failed approach** ("clear the
dead-end reasoning before trying a new approach"). Persists/lost table (`:89`): files,
CLAUDE.md, TodoWrite, git state survive; intermediate reasoning, prior file reads, and
verbally-stated preferences do not.

**`agents/spec-miner.md`** — closest thing in ECC to omp-template's spec discipline, directly
relevant to `spec/key/dossiers`. Sample-and-expand with hard stops (`:57-68`): read entry files
first (≈70% of behavioral assertions), expand one level down each call chain, stop at an
external boundary, or after 3 consecutive files yield nothing new, or at 15 files total.
Unread files go in `<!-- deferred: ... -->`.

Two rules worth lifting verbatim:
- **"Never invent behavior"** (`:191`) — unknowns go in `<!-- uncertainty: reason -->`, never
  become a Requirement
- **"Flag, don't fix"** (`:196`) — "You're a miner, not a refactorer"

Plus the accountability line (`:195`): "A Requirement without `enforced` is a promise with no
accountability." And a stable `id` derived from the enforcement point so it survives
human-readable renames (`:90`, `:173`) — a good pattern for any spec that will be
delta-patched. Also `:192` — cross-validate docstrings against callers, because "the actual
contract is what callers rely on, not what docs claim."

**`rules/common/agents.md:44-52` — Delegation Completion Contract.** Documents a real observed
failure: research agents read the "always parallelize" rule, spawned children, and returned
"waiting for background agents" as their final answer. All children completed successfully;
all results were orphaned. Three rules: your final message *is* the deliverable; if you
delegate you own collection; "depth is an outcome, not a plan." The generalizable lesson:
**a parallelism rule without a completion contract produces zombie tasks.**

**`skills/rules-distill/SKILL.md`** — how to promote skill content into rules without
abstraction rot. Three-filter gate (`:78`, `:265`): appears in 2+ skills, expressible as
"do X"/"don't Y", has a named violation risk. "Deterministic collection, LLM judgment"
(`:264`) — scripts guarantee exhaustiveness, the model guarantees contextual understanding.
Hard stop: "Never modify rules automatically. Always require user approval" (`:173`).

---

## What to skip

- **The catalog itself.** 282 skills with heavy overlap — five near-identical `*-verification`
  skills; `agent-self-evaluation` vs `agent-evaluator` vs `agent-eval` vs `skill-comply`. ECC's
  own `WORKING-CONTEXT.md` lists overlap consolidation as active unfinished work.
- **`agent-self-evaluation` / `agents/agent-evaluator.md`** — 5-axis self-scoring. These
  contradict Tier-1 items 3 and 4: GateGuard says self-evaluation is experimentally useless,
  and gan-style-harness says agents self-evaluating are pathological optimists. ECC ships all
  three without reconciling them. Take the critique, not the artifact.
- **`skills/token-budget-advisor`** — asks the user to pick a 25/50/75/100% depth level before
  answering. Interaction tax, and it admits to being heuristic-only at ±15%.
- **The `Prompt Defense Baseline` block** — an identical 6-bullet prompt-injection preamble
  pasted into 66 of 67 agents plus `CLAUDE.md`. ~120 tokens × 67 = pure duplicated overhead
  that a single inherited rule would cover. A good example of exactly the anti-pattern
  omp-template's `context-budget.yml` exists to prevent.
- **`skills/taste`** (264 lines of angelcore music-video direction),
  `skills/recursive-decision-ledger`, and the domain verticals (healthcare, logistics, DeFi,
  energy procurement, customs/trade) — no bearing on a workflow harness.

---

## Two contradictions ECC leaves unresolved — worth resolving in spec

**1. Self-evaluation.** `gateguard:21` and `gan-style-harness:17` say it does not work;
`agent-self-evaluation` and `agents/agent-evaluator.md` are built on it. omp-template's
verifier already takes the right side ("Do not trust the implementer's test report — re-run and
re-read"), but the spec should state the *principle* so it is not re-litigated:
**evaluation requires a separate context, not a separate prompt.**

**2. Strictness vs. false positives.** `gan-evaluator:24` ("be ruthlessly strict", "do NOT talk
yourself out of issues") and `code-reviewer:29-111` (confidence filtering, drop unprovable
findings, zero findings is valid) pull in opposite directions, and ECC never reconciles them in
prose. The resolution is visible in `orch-review.workflow.js` but never stated:

> Strictness governs how hard you look. Confidence filtering governs what you report.
> Uncertainty resolves toward blocking, not toward silence.

That sentence is probably the single most useful thing to carry out of this survey.

---

## Key file paths (all under `_research/upstreams/ECC/`)

| Path | Why |
|---|---|
| `agents/code-reviewer.md` | Pre-report gate, proof requirement, false-positive catalog (`:29-111`, `:297`) |
| `workflows/orch-review.workflow.js` | Fail-closed adversarial finding verification (`:130-132`, `:214`, `:240-276`) |
| `skills/gateguard/SKILL.md` | DENY→FORCE→ALLOW fact-forcing (`:21-43`, `:121`) |
| `scripts/hooks/gateguard-fact-force.js` | Denial-fatigue cap, exempt globs, fail-open config parsing |
| `skills/gan-style-harness/SKILL.md` | Generator/evaluator separation; harness-evolution principle (`:17`, `:196-218`, `:248-258`) |
| `agents/gan-evaluator.md` | Anti-optimism calibration, scoring scale (`:24-35`, `:109-116`) |
| `skills/santa-method/SKILL.md` | Dual independent review, fresh-agent anti-anchoring (`:12`, `:174`, `:204`) |
| `skills/council/SKILL.md` | Context isolation as anti-anchoring; self-bias guardrails (`:53`, `:76`, `:118-127`) |
| `skills/orch-pipeline/SKILL.md` | Max-of-three-signals sizing, two gates, security trigger (`:39-50`, `:78-104`) |
| `skills/context-budget/SKILL.md` | Token estimation constants, MCP cost, always-loaded descriptions (`:56-58`, `:132-134`) |
| `skills/delivery-gate/SKILL.md` | Deterministic vs. reasoning gates; warning-only heuristics (`:11-28`, `:108-110`) |
| `skills/strategic-compact/SKILL.md` | Real-usage context signal; compact decision + survival tables (`:39`, `:76-99`) |
| `agents/spec-miner.md` | Sample-and-expand budget; never-invent / flag-don't-fix (`:57-68`, `:191-196`) |
| `rules/common/agents.md` | Delegation completion contract + the failure that motivated it (`:44-52`) |
| `skills/rules-distill/SKILL.md` | Skill→rule promotion filters, anti-abstraction safeguard (`:78`, `:262-265`) |
| `agents/silent-failure-hunter.md` | Swallowed-error taxonomy: empty catch, dangerous fallbacks (`.catch(() => [])`), lost stack traces |
| `skills/iterative-retrieval/SKILL.md` | 4-phase dispatch/evaluate/refine/loop, max 3 cycles, relevance ≥0.7 stop rule |
| `skills/verification-loop/SKILL.md` | 6-phase build→type→lint→test→security→diff gate; "If build fails, STOP" (`:31`) |
| `skills/eval-harness/SKILL.md` | pass@k vs pass^k; capability vs regression evals; 4 grader types |
| `scripts/hooks/config-protection.js` | Blocks weakening linter/formatter configs; allows first-time creation; fails closed on non-ENOENT stat errors |

---

## Gaps — NOT READ THIS PASS

Recorded honestly so a later pass knows what remains.

- **`skills/` — ~250 of 282 skill bodies.** Read in full: `verification-loop`,
  `delivery-gate`, `context-budget`, `token-budget-advisor`, `strategic-compact`,
  `search-first`, `iterative-retrieval`, `rules-distill`, `santa-method`, `council`,
  `gan-style-harness`, `gateguard`, `safety-guard`, `orch-pipeline`, `dynamic-workflow-mode`,
  `agent-self-evaluation`, `eval-harness`, `recursive-decision-ledger`, `taste`,
  `prompt-optimizer`, `agent-harness-construction`, `skill-comply`. Read partially (head only):
  `codebase-onboarding`, `agentic-engineering`, `unified-memory`, `continuous-learning-v2`,
  `skill-scout`, `blueprint`, `production-audit`, `repo-scan`, `agent-architecture-audit`.
  Everything else — name and description only.
- **`agents/` — 50 of 67 agent bodies.** Read in full: `code-reviewer`, `planner`,
  `code-explorer`, `silent-failure-hunter`, `security-reviewer`, `gan-evaluator`, `spec-miner`,
  `agent-evaluator`, `tdd-guide`. Read partially: `architect`, `code-architect`,
  `type-design-analyzer`, `comment-analyzer`, `code-simplifier`, `gan-generator`,
  `gan-planner`, `loop-operator`, `harness-optimizer`. The remaining ~50 are mostly
  language/framework reviewers and build resolvers — low expected novelty, but unverified.
- **`commands/` — 94 files, 2 read** (`harness-audit`, `quality-gate`). Names only for the
  rest. ECC itself calls `commands/` a legacy compatibility shim
  (`AGENTS.md:125-129`), so low priority.
- **`hooks/hooks.json` semantics beyond PreToolUse.** Read the PreToolUse and PreCompact
  blocks and the hooks README. Did NOT read the PostToolUse, Stop, SessionStart, or SessionEnd
  registrations in detail.
- **`scripts/` — ~everything except `gateguard-fact-force.js` (partial, first ~150 lines) and
  `config-protection.js` (full).** `scripts/harness-audit.js` (the deterministic 12-category
  scorer referenced by `/harness-audit`) was NOT read — only its command wrapper. This is the
  most likely remaining source of value in `scripts/`.
- **`schemas/` — 11 JSON schemas, none read.** Names only. `provenance.schema.json`,
  `state-store.schema.json`, and `memory.schema.json` may be relevant to omp-template's
  schema layer.
- **`rules/` — 122 files, 1 read in full (`rules/common/agents.md`).** Line counts collected
  for the 10 `rules/common/*` files (545 lines total). The 112 per-language rule files were
  NOT read.
- **`docs/` — 1,510 files, 1 read (`token-optimization.md`).** `ECC-2.0-REFERENCE-ARCHITECTURE.md`,
  `SELECTIVE-INSTALL-ARCHITECTURE.md`, `SESSION-ADAPTER-CONTRACT.md`, and
  `capability-surface-selection.md` look most relevant and were NOT read.
- **`ecc2/`, `src/`, `tests/`, `integrations/`, `plugins/`, `manifests/`** — not examined
  beyond directory file counts.
- **`the-security-guide.md` (28k), `the-longform-guide.md` (15k), `README.md` (113k)** — read
  only the head of `the-shortform-guide.md`. These are narrative guides; the mechanisms they
  describe are mostly covered by the skills already read, but that is an assumption, not a
  verified claim.
- **Unverified quantitative claim.** GateGuard's +2.25/10 improvement is self-reported from
  n=2 tasks with no published methodology. Cited above as directional only.
