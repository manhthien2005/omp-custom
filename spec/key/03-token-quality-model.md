# 03 — Token / Quality Decision Model

<!-- topic08-projection:behavior-core -->
> **Topic 08 cost projection:** descriptions are ≤80 approximate tokens, visible catalog ≤900,
> lazy bodies ≤900, and the sole current autoload body (Worker completion evidence) ≤500 per
> Worker spawn. Three is the selected roster, not a permanent cap; additions must fit the same
> manifest, provenance, trigger, and consumer accounting.

<!-- topic05-projection:token -->
> **KD-029 cost projection:** abundant Cheap Scout tokens may reduce expensive Lead retrieval, but
> Scout/raw/provider/cache totals remain separate truthful telemetry. Missing usage is
> `not_measured`; estimates and graph-vendor benchmark claims cannot justify promotion.

## KD-028 durable-state cost/quality rule

Raw `.task/` output and runtime artifacts are cheap transient transport, never acceptance evidence
or lifecycle authority. Promote only compact sanitized proof that binds the exact contract,
candidate, acceptance inputs, and relevant environment/source identity. Rehash at freeze,
verification, review, handoff, resume/takeover, and acceptance boundaries. The extra deterministic
hashing cost buys protection from stale plausible results; there is no global evidence TTL because
validity is trigger-based.

> How a cost/quality trade-off is judged in this project. Quality gates are authority;
> token cost and latency may distinguish only candidates that clear them.
>
> Every OMP setting named here is source-verified; the citation is `packages/coding-agent/src/<path>:<line>`
> in `_research/upstreams/oh-my-pi` @ `3a8591a`.
>
> **Topic 02 supersession boundary:** role names below are frozen-baseline examples, not
> topology authority. Cost decisions attach to responsibilities selected by Topic 03.

---

## A. The objective function

The project uses a lexicographic objective. A lower-priority term can never compensate for
a failure above it:

```text
1. clear every mandatory quality gate
2. maximize validated accepted-outcome rate
3. minimize core_workflow_tokens / validated_accepted_outcomes
4. use latency only as a final tie-breaker
```

There is no weighted quality score, model-price multiplier, premium-token equivalent, or
latency composite. This supersedes the earlier unqualified
`total_tokens / accepted_outcomes` formula. A cheap wrong run remains worse than an
expensive correct run, but a large volume of deliberately cheap Scout retrieval must not
distort the ledger used to optimize the expensive workflow core.

### A-1. Validated accepted outcome

A task contributes one validated accepted outcome only when all five conditions hold:

1. the task objective is complete;
2. every mandatory acceptance criterion has authoritative PASS evidence, with no SKIP or
   coverage gap;
3. every verification and review gate required by that task's contract is clear;
4. no blocking finding, unresolved authority conflict, or unresolved scope issue remains;
5. the Tech Lead records final acceptance.

The lifecycle has three terminal task outcomes: `accepted`, `cancelled`, and
`terminally_blocked`. `partial`, recoverable `blocked`, `waiting_for_user`, and rework are
nonterminal observations and remain inside the open task cycle.

`accepted_with_waiver` is an evaluation classification, not a shortcut around the task
contract. It remains outside the validated benchmark denominator and cannot silently promote
a candidate. If a waiver changes a mandatory criterion, that is a contract change: the old
candidate remains non-validated and a linked task contract must evaluate a new candidate.

### A-2. Full task-cycle accounting

The task cycle starts when the task contract is accepted and ends only at `accepted`,
`cancelled`, or `terminally_blocked`. It includes initial and repeated retrieval, rejected
candidates, schema/provider/workflow retries, verification and review rework, attributable
handoff or compaction, and fallback work after Scout failure. A genuinely new task contract
starts a new cycle.

Acceptance-bearing evidence binds to one immutable candidate snapshot. Any mutation after
freeze invalidates that snapshot's evidence; the next attempt is a new candidate within the
same task unless the contract itself changed.

Failed and rejected cycles remain in the aggregate numerator. Their tokens are not erased or
moved into the successful retry. Report three unweighted ledgers:

| Ledger | Contents | Decision role |
|---|---|---|
| `core_workflow_tokens` | Tech Lead plus every non-Scout worker/reviewer activity in the task cycle | Primary optimization ledger |
| `cheap_scout_tokens` | Optional read-only Cheap Scout retrieval | Telemetry only; never a routing or promotion gate |
| `raw_total_tokens` | Sum of the two ledgers using token fields actually emitted by the runtime/provider | Observational only |

If a token class is not exposed, report it as not measured; do not estimate it silently.
The aggregate metric is:

```text
sum(core_workflow_tokens across every attempted task cycle)
----------------------------------------------------------------
count(validated accepted outcomes)
```

Zero validated accepted outcomes means infinite cost, not zero cost. Models are not
weighted against one another. Provider cost, quota consumption, cache reads, and model
identity may be reported as diagnostics, but they do not alter the formula.

### A-3. Cheap Scout is deliberately simple

The Tech Lead decides whether a Cheap Scout is useful. The role may resolve to DeepSeek,
Gemini, or another suitable cheap model through configuration; workflow prose does not
hardcode a model ID. The Scout performs read-only retrieval and returns compact evidence.
If it is unavailable, fails, or returns unusable evidence, the workflow fails softly to the
retrieval path the Tech Lead needs. The Tech Lead rechecks critical evidence. Scout token
volume is telemetry, not a budget to optimize.

### A-4. Latency is not an objective

Record wall time, provider waits, and timeouts for diagnosis. A timeout, deadlock, or
unbounded wait is a reliability failure rather than a merely slow result. An explicit user
deadline becomes a task constraint. Otherwise latency is considered only when quality and
core-token efficiency are equivalent.

### A-5. Frozen dual baselines

Two baselines answer different questions:

- `stable_product_baseline`: the last promoted template, used for every candidate mechanism
  or optimization;
- `pinned_plain_omp_runtime_baseline`: pinned plain OMP without the template, used at release
  and major architecture checkpoints to prove the product still adds value.

Both arms freeze the fixture version, OMP binary SHA, provider/model policy, retry/timeout
policy, cache policy, and tool environment; template-bearing arms also freeze the template
artifact SHA. The stable baseline advances only after promotion and records the identity it
supersedes. A baseline never moves silently.

### A-6. Promotion

Every candidate first clears deterministic hard gates: all required operational/adversarial
gate fixtures pass, acceptance-criteria coverage is complete, no new false completion occurs,
no blocking or critical correctness/security regression occurs, and the observed validated
accepted-outcome rate does not decrease.

A candidate may then promote by either path defined operationally in `spec/13 §C`:

- **Efficiency win:** quality is statistically non-inferior, the observed acceptance rate is
  not lower, the one-sided 95% non-inferiority bound permits at most five percentage points of
  uncertainty, and core workflow tokens per validated accepted outcome improve by at least
  10% with a paired 95% interval supporting a real improvement.
- **Quality win:** the validated accepted-outcome rate is credibly better at 95% confidence,
  while the paired 95% bound keeps core workflow tokens per validated accepted outcome within
  a 10% regression ceiling.

Three independent paired runs per arm are a pilot minimum only; pilot evidence may reject an
obvious regression but cannot promote. Final runs follow a predeclared sequentially valid
adaptive procedure whose joint error control preserves at least 95% confidence across all
interim looks, both promotion paths, and every promotion-bearing bound. A nominal per-look 95%
interval cannot trigger adaptive promotion. Pilot data enter final inference only when that
procedure was frozen before the pilot and includes it as the first look. An inconclusive result
is deferred or rejected. Higher-risk comparisons may predeclare stricter thresholds;
thresholds cannot be loosened after final sampling begins. A user waiver is recorded
separately and is not a validated promotion.

### Never-acceptable reductions

These are cuts that move cost from the measured column into the unmeasured one:

| Cut | What it actually does |
|---|---|
| Remove required independent verification because the candidate author reported success | Removes the only independent evidence required by the accepted contract. The author is the worst judge of its own output because it knows what it intended. |
| Drop the failing-test-first step on a bug fix | Removes the proof the bug existed. A fix with no red-to-green transition is a guess. |
| Reduce thinking level on a high-risk task | Buys tokens with correctness on exactly the tasks where correctness is expensive to recover. |
| Trim acceptance criteria below what the change needs | Makes the run cheaper *to score*, not cheaper to produce. |
| Suppress a genuine ambiguity to avoid a clarification round-trip | One round-trip is cheaper than one wrong implementation, always. |

### The asymmetry that justifies the constraint

A false completion is not a neutral failure. It is worse than an outright error,
because an error stops the user and a false completion does not. The user builds on
it. Cost of discovery grows with time-since-introduction. This is why the constraint
is a hard gate rather than a weighted term.

---

## B. Cost tiers — where a token is actually paid

Four lifetimes. Conflating them is the single most common source of token waste in
agent templates, because a file's size matters far less than its tier.

| Tier | Paid | Multiplier | OMP surfaces in this tier |
|---|---|---|---|
| **Persistent** | Every turn, every session | × turns | `AGENTS.md`, skill *listing* (name + description), `SYSTEM.md` |
| **Sticky** | Every turn, survives compaction | × turns | `RULES.md` (`alwaysApply` forced at `discovery/builtin.ts:416`), rules with `alwaysApply: true` |
| **Per-spawn** | Once per subagent session | × spawns | agent prompt body, `autoloadSkills` bodies, the task packet |
| **Lazy** | Only when read | × uses | skill bodies via `skill://`, command bodies, `instructions/` matching a glob, artifact reads |
| **Zero** | Never enters a context | — | `docs/`, `registry/`, `spec/`, validation thresholds, generator inputs |

### The multiplier is the decision, not the size

A worked comparison, using the same 500 tokens in three tiers over a Standard workflow
(assume ~15 main-session turns, 3 spawns):

| Placement | Formula | Tokens paid |
|---|---|---|
| `RULES.md` (sticky) | 500 × 15 turns | **7,500** |
| `autoloadSkills` on 3 workers (per-spawn) | 500 × 3 | **1,500** |
| Lazy skill body, read twice | 500 × 2 | **1,000** |
| `docs/` (zero) | — | **0** |

Same content. 7,500 vs 0. This is why "make the file smaller" is usually the wrong
optimization and "move the file to a cheaper tier" is usually the right one.

**Corollary — the `RULES.md` budget is the tightest in the system.** At ≤700 tokens and
~15 turns it already costs ~10.5k per Standard workflow. Every line added there is
multiplied by every turn of every session forever. Only invariants that must be
enforceable *mid-turn* earn a place.

**Corollary — a skill's `description` is persistent and its body is not.** The
description is paid in every turn of every session that lists the skill; the body is
paid only when read. A 60-token description gating a 1,800-token body is the
progressive-disclosure mechanism working correctly. An overlong description defeats it
at the one place the cost is unavoidable. And a *missing* description is worse than
either: the skill is silently dropped (`requireDescription: true`, gate at
`discovery/helpers.ts:390-392`) — infinite cost per outcome, because the outcome never happens.

---

## C. Runtime levers OMP already provides

The template should reach for these before inventing anything. Each is a verified
setting or field, with the cost model it changes.

### C-1. Read summarization — `read.summarize.enabled` (default `true`)

Large reads return elided/summarized spans instead of raw content. Applies only to
files at or above `read.summarize.minTotalLines` = **100** (`config/settings-schema.ts:3331`);
shorter files are returned verbatim regardless. `read.defaultLimit` is 300 lines
(`:3258`). Elided spans unfold on demand (`unfoldUntil` 50, `unfoldLimit` 100 —
`:3342`, `:3354`).

Per-agent override is `read-summarize:` frontmatter (`discovery/helpers.ts:300`), threaded
into the child session as `read.summarize.enabled` (`task/executor.ts:2648`).

**Decision rule:** leave summarization ON unless the agent's contract requires exact
bytes. Setting `read-summarize: false` on a read-heavy role is a token regression with
no offsetting benefit — it is the mechanism that bounds the reads the role's own
instructions try to avoid. The one defensible exception is an agent whose *evidence*
is the literal file content; note that command output from `bash` is not affected by
this setting at all, so a command-output verification responsibility does not need the override.

### C-2. Managed continuity — automatic compaction off

OMP exposes `context-full | handoff | shake | snapcompact | off`
(`config/settings-schema.ts:2164-2198`), but native availability is not the selected product
policy. KD-031 sets the managed profile to `off` and disables automatic, idle, mid-turn, remote,
and auto-continue paths.

| Strategy | Mechanism | Cost profile |
|---|---|---|
| `/safe-compact` | One explicit native `mode: "soft"` local context-full transaction | One bounded configured-model summarization call |
| `snapcompact` / `shake` | Native mechanisms, not managed fallbacks | Outside the Topic 07 continuity guarantee |
| automatic/remote/handoff strategy | Disabled | No hidden summarization, continuation, or ownership transfer |

Two pruners are on by default and matter more than the strategy choice:

- `compaction.supersedeReads: true` (`:2346-2355`) — an older read of a file is pruned
  when a newer read supersedes it. **Consequence:** the read→edit→re-read pattern is
  nearly free, so caching file contents in the conversation is an anti-pattern.
- `compaction.dropUseless: true` (`:2357-2367`) — no-match and timeout results are pruned
  once consumed. **Consequence:** a failed grep costs almost nothing; exploratory search
  is cheap and should not be rationed.

`compaction.keepRecentTokens` = 20000 (`:2285`).

**Decision rule:** after the Topic 04 task is armed, `/safe-compact` may authorize one native soft
transaction. It accepts no focus text, persists verified local recovery bytes before the call,
and injects one canonical continuity kernel into the next normal prompt. It schedules no hidden
continuation and does not change task authority. Pressure aborts ordinary provider dispatch;
one unresolved attempt requires explicit handoff or user action.

### C-3. Artifact spill — keeps bulk out of context entirely

`tools.artifactSpillThreshold`, `artifactHeadBytes`, `artifactTailBytes`,
`artifactTailLines`, `tools.outputMaxColumns` (`config/settings-schema.ts:710`, `:754`,
`:734`, `:796`, `:776`). Oversized tool output is stored and replaced by a reference
plus head/tail. Hard caps on subagent output: `MAX_OUTPUT_BYTES` 500,000 and
`MAX_OUTPUT_LINES` 5,000 (`task/types.ts:53-56`).

**Decision rule:** prefer OMP's artifact manager over a hand-rolled `.task/<id>/` file
convention, and *especially* for isolated workers — an isolated worktree is torn down
after the task, so a gitignored scratch file inside it is destroyed and the path
returned in the result is invalid in the parent.

### C-4. Prewalk — plan strong, edit cheap

`prewalk` frontmatter (boolean or model pattern, `discovery/helpers.ts:302-306`) or
`task.agentPrewalk` record (`config/settings-schema.ts:4729-4732`). Plans on the strong
model, hands off to `smol` at the first edit/write (`:4733-4743`). A prewalk target
equal to the current model+level is detected and skipped (`task/executor.ts:2920-2950`).

**Decision rule:** DEFER. This is the highest-leverage untested token lever in the
runtime, and it is also the one most likely to trade quality invisibly. It requires an
A/B with a false-completion count before adoption — exactly the measurement
`spec/13` exists to produce.

### C-5. Effort — off by default

`task.enableEffort` default **`false`** (`config/settings-schema.ts:4582-4592`). The
per-call `effort` field is **absent from the wire schema** unless this is enabled
(`task/types.ts:202`). Ceiling is `task.maxEffort`, default `max` (`:4706-4718`).
Thinking budgets run 1,024 → 32,768 (`:5574-5584`).

**Decision rule:** per-dispatch `effort` is the right escalation lever — it does not
require editing agent files — but it must be enabled first. Any command prose that
passes `effort` without `task.enableEffort: true` is writing a field that gets stripped.

### C-6. Subagent budgets — already bounded

`task.softRequestBudget` default 200; crossing it injects one wrap-up notice, and
**1.5× forces a stop with a partial yield** (`config/settings-schema.ts:4676-4692`).
`task.maxRuntimeMs` default 0 = unlimited (`:4645-4662`). `task.agentIdleTtlMs` 420,000
parks idle agents to disk (`:4664-4674`).

**Decision rule:** runaway workers are already bounded by the runtime. The template does
not need its own turn counter. What it *does* need is to treat a partial yield as a
partial result rather than a completion.

### C-7. Per-spawn telemetry — the measurement surface already exists

Each spawn returns `tokens`, `requests`, `contextTokens`, `contextWindow`, `cost`, `usage`,
`durationMs`, `structuredOutput`, `modelRole`, `resolvedModel`, and
`resolvedModelIsFallback` (`task/types.ts:471-539`, `:428-434`, `:500-505`). Live
equivalents stream on `AgentProgress` over `task:subagent:{event,progress,lifecycle}`
(`:395-469`, `:59-65`).

The `tokens` field is documented as input + output + cacheWrite excluding cacheRead, but
`getUsageTokens()` falls back to provider `totalTokens` when the breakdown is missing and
explicitly notes that this fallback may include cacheRead (`task/executor.ts:759-782`).
Therefore the promotion harness derives its ledger only from the `usage` breakdown. Missing
input/output/cacheWrite attribution means `not_measured`; the display fallback is diagnostic,
not promotion evidence.

**Decision rule:** the benchmark harness reads runtime fields and never estimates. Model identity
is observable only by comparing returned modelRole and resolvedModel; resolvedModelIsFallback
covers retry fallback but not credential fallback. The benchmark and acceptance paths reconcile
`task.agentModelOverrides`, compare the exact expected identity, and separately reject a true
fallback flag.

---

## D. The decision procedure

Applied to every candidate mechanism in `02-repo-synthesis.md` and every design choice
in `01-dna.md`.

```
1. Does it name an OMP attachment point?
   NO  → it is documentation (docs/, zero tier) or it is a defect. Stop.
   YES → continue.

2. Which tier does the attachment point put it in?
   Persistent or sticky → the bar is highest. Justify against × turns.
   Per-spawn            → justify against × spawns, and name which agents.
   Lazy or zero         → cheap; the bar is usefulness, not cost.

3. Can it move to a cheaper tier without losing its guarantee?
   YES → move it. This is the default answer and it is usually available.
   NO  → state why the guarantee requires the expensive tier.

4. Does it weaken verification, evidence, or independence?
   YES → REJECT regardless of token savings. The constraint is hard.
   NO  → continue.

5. Is the benefit measurable?
   YES → ADOPT with the measurement named.
   NO  → DEFER until it is. An unmeasurable benefit cannot be defended
         later, and undefendable mechanisms accumulate.
```

Step 3 is where most of the value is. The `.omp/policies/` failure was a step-1 failure
(no attachment point), but the more common error is a step-3 failure: content that is
correct and useful, placed one tier more expensive than its guarantee requires.

---

## E. Worked applications

Six real decisions, run through §D.

### E-1. `evidence-before-completion` — where does it live?

| Option | Tier | Cost (Standard: ~15 turns, 3 spawns) | Guarantee |
|---|---|---|---|
| Lazy skill | lazy | ~0–500 | **None.** The model must choose to read it. The failure mode *is* a model that doesn't think to check. |
| `RULES.md` line | sticky | 500 × 15 = 7,500 | Strong for the main session |
| `autoloadSkills` on Worker only | per-spawn | ≤500 × Worker spawns | Deterministic injection at spawn (`task/executor.ts:3235-3248`) |

**Decision: `autoloadSkills` on Worker, plus a one-line sticky invariant for the main session.**
This is strictly stronger than lazy delivery for the candidate-producing role. The duplication
between the sticky line and the skill body is intentional: the two serve disjoint audiences, and
a future deduplication pass must not delete the Worker copy.

Body budget ≤500 tokens, hard. It is now paid per spawn, so growth compounds.

### E-2. The nine `policies/` and `schemas/` YAML files

Step 1: no attachment point. `policies/` and `schemas/` have zero discovery hooks in any
OMP provider.

**Decision: split by consumer, not by content.**

| Content | Destination | Tier |
|---|---|---|
| Result shapes | agent frontmatter `output:` | per-spawn (part of the prompt) |
| Risk→gates matrix | inlined table in `standard.md` / `orchestrated.md` | lazy (command body) |
| Workflow sizing signals | command prose + `AGENTS.md` role table | lazy + persistent |
| Escalation rules | agent "Must not" sections | per-spawn |
| Context budget numbers | `docs/` + validator thresholds | **zero** |
| Gate check details | `docs/policies/` | **zero** |

Net effect: 581 lines of inert YAML become a mix of enforced schema, lazily-loaded
prose, and zero-cost documentation. Nothing is deleted; everything is re-homed to a tier
that matches how it is actually consumed.

### E-3. LSP in worker allowlists

`task.enableLsp` is `false` by default (`config/settings-schema.ts:4615-4625`); the frozen
Phase-00 baseline sets it `true`. Effective LSP requires all four independent gates: `lsp` in
the selected worker allowlist, `task.enableLsp == true`, parent session not disabled and not
plan mode, and `lsp.enabled == true`. The parent/plan/settings conjunction is implemented in
`task/structured-subagent.ts:318-320` and `tools/index.ts:593`; the selected allowlist comes
from `task/executor.ts:2675-2678`. Permission is not provision, and no single gate proves the
selected symbol-aware contract can run.

An LSP tool result with details.success false is a failed capability result, not symbol-aware
evidence. The four gates only make the tool callable; an applicable working language server and
successful required calls are additional acceptance conditions (`lsp/index.ts:2145-2160`). A
silent switch to text retrieval after a failed semantic call changes the contract and must be
reconciled and revalidated.

Naively this reads as a cost (another tool, another turn). It is the opposite:
`lsp references` answers "who calls this" without loading callers, and `lsp symbols`
answers "what does this export" without loading the file. Both replace whole-file reads
with targeted queries.

**Decision: ADOPT for every selected LSP-consuming responsibility.** Topic 03 assigns the
capability from the selected contract, never from a role name. Do not add LSP to an exact-output
command-verification responsibility unless its selected contract also consumes symbol-aware
retrieval. The deeper point remains: `task.enableLsp: true` with no selected consumer listing
`lsp` pays a baseline deviation and receives nothing for it.

### E-4. `read-summarize: false` on the former Explorer adapter

The Explorer's own instructions say to prefer symbol lookup over full reads. Its
frontmatter disables the mechanism that would bound the reads it does perform. The
frontmatter wins, because it is machinery and the instruction is prose.

**Decision:** remove the override from any selected discovery role whose output is ranked
evidence—`file:line` plus brief context—because summarized reads are better input than full
contents.

For a selected exact-output verification responsibility, the case is weaker than it looks:
evidence from `bash` output is not touched by `read.summarize`; the override affects only files
read with `read`. **Decision:** remove it by default. Restore it only for a selected contract
when a fixture proves required file evidence is lost, and record why.

### E-5. Parallel exploration in `/orchestrated`

Two selected discovery workers over *different* modules can be legitimate. Two workers asked
the same question create duplicated reads, duplicated tokens, and no new information.

**Decision: parallelize only on genuine independence, and independence means disjoint
scope.** Size alone never justifies fan-out. A large sequential task is Standard with
more steps — spawning four agents to do four dependent things is strictly worse than one
agent doing them, because each handoff loses context and costs a spawn.

For selected parallel writers, independence additionally means **disjoint file sets**,
because `merge: patch` resolves conflicts at `git apply` time — a late, confusing failure
rather than an early, clear one.

### E-6. Constitution duplication

`AGENTS.md` is persistent and every agent inherits it. A rule repeated in five agent
prompts is paid once persistently and five more times per spawn.

**Decision: the constitution lives in `AGENTS.md` only; agent prompts state role-specific
contracts and nothing else.** The existing validator check that greps for constitutional
phrases in agent files is well designed and should extend to skill bodies, which are
currently unscanned.

---

## F. Budgets

Provisional pending Phase-06 measurement. These are the numbers the validator enforces;
they are baselines from role complexity, not measured optima.

| Component | Target | Warn | Tier | Multiplier |
|---|---|---|---|---|
| `AGENTS.md` | 600–1,200 | 1,500 | persistent | × turns |
| `RULES.md` | 300–700 | 800 | sticky | × turns |
| Agent prompt body | 500–1,200 | 1,500 | per-spawn | × spawns |
| Skill description | 30–80 | 120 | **persistent** | × turns |
| Skill body | 800–2,000 | 2,500 | lazy | × uses |
| `autoloadSkills` body | ≤500 | 500 | **per-spawn** | × spawns |
| Task packet | 300–800 | 1,200 | per-task | × spawns |
| Worker result | 200–600 | 1,000 | per-result | × spawns |
| Command body | — | — | lazy | × uses |

Two rows carry more weight than their size suggests: skill *description* is persistent
(the listing is always loaded), and `autoloadSkills` body is per-spawn (not lazy like an
ordinary skill body). Both are easy to misfile.

Command bodies are deliberately unbudgeted — they are lazy, loaded once per invocation,
and inlining a decision table there is the correct trade against a `policy:` reference
that resolves to nothing.

**Token counting must use a real tokenizer.** `chars / 4` misestimates markdown tables
and code fences badly, and this template is mostly markdown tables.

---

## G. The two prohibitions

Both are load-bearing and both belong in `RULES.md` for the main session and in the
dispatch site prose.

**Task packets must not contain the parent transcript.** A packet carrying the
conversation defeats delegation entirely: the subagent pays for context it cannot act
on, and the parent pays again when the result returns. Packets carry objective, scope,
acceptance criteria, verification commands, and `file:line` references — nothing that
reads as history.

**Worker results must not contain chain-of-thought or full transcripts.** The
orchestrator needs the conclusion and the evidence, not the path. A result quoting 200
lines of test output to prove 12 tests passed spent ~1,500 tokens to convey what
`12 passed, 0 failed, exit 0` conveys in ten.

A corollary for schema design: **do not add a schema field that invites narration.** A
required `reasoning` or `analysis` field works directly against both prohibitions, and
every required field the model struggles with burns one of three retries.

---

## H. What must be measured before any of this is a claim

Until `spec/13`'s L3/L4 evaluation runs, everything in this file is a well-reasoned
prediction. The claims that specifically need numbers:

| Claim | Measurement |
|---|---|
| Tier placement saves what §B computes | Token accounting per tier across a fixture set |
| `autoloadSkills` cost is ~1 body per spawn | Per-spawn `tokens` delta with autoload on vs off |
| Removing `read-summarize: false` reduces selected discovery cost | A/B on the same fixtures, same scope |
| LSP in allowlists is net-negative cost | A/B with `lsp` present vs absent, same tasks |
| Prewalk preserves quality | A/B with false-completion rate as the gate |
| The workflow beats no workflow | Baseline arm with no template installed |
| Transcripts can substantiate a provenance claim (KD-019) | phase-04 T-04.8 — measure what `history://<id>` actually carries |
| The nested-repo disable costs little in practice (KD-018) | Frequency of non-empty preflight across the fixture repos; a common hit makes A2 worth verifying |

The last two are different in kind from the rest and worth naming as such: the others measure
whether a lever *saves* tokens, while these measure whether a **safety** rule is affordable and
whether a **claim** is permitted at all. A safety rule that fails its measurement does not get
relaxed for cost — KD-018 is reversed only by OMP changing, not by the preflight proving
inconvenient.

Reporting a token count without the acceptance denominator is the specific failure this
model exists to prevent. A cheaper number next to a higher false-completion rate is a
regression being reported as an improvement.

---

## I. Topic 06 boundary accounting

The managed packet is a per-dispatch projection, not a transcript or a duplicate task record.
The receipt is a bounded observation, not a place for reasoning or raw logs. Topic 04 stores the
authoritative acceptance criteria and evidence identities; Topic 06 carries only the fields the
selected role needs and returns compact verified facts.

Cheap Scout tokens remain cheap-scout telemetry even when Flash falls back to Pro. Worker `high`
versus Tech-Lead-selected `xhigh`, and Reviewer fixed `xhigh`, remain visible as exact returned
identity. The wrapper refuses a forced partial at the 300-request boundary, so a schema-shaped
partial cannot improve token metrics by masquerading as an accepted outcome. The managed overlay
sets `task.softRequestBudget: 200`. Topic 07 additionally owns the exact disabled
automatic-compaction profile required by KD-031; this is continuity safety, not model routing or a
token-metric optimization.
