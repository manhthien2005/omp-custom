# 03 — Token / Quality Decision Model

> How a cost/quality trade-off is judged in this project. This file is the tie-breaker
> when two candidate designs differ in token cost and neither is obviously wrong.
>
> Every OMP setting named here is source-verified; the citation is `packages/coding-agent/src/<path>:<line>`
> in `_research/upstreams/oh-my-pi` @ `3a8591a`.

---

## A. The objective function

```
minimize   total_tokens / accepted_outcomes
subject to false_completion_rate not increasing
```

**Tokens per accepted outcome**, not tokens. The denominator is what makes the metric
honest. A run that spends 15k and produces a rejected change did not cost 15k — it cost
15k plus the whole retry, plus the user's attention.

The constraint is doing real work. Without it the optimizer has a trivial solution:
delete the Verifier, halve the token count, and let wrong answers through. Every
token-reduction proposal in this project is therefore checked against the constraint
first and the objective second.

### Never-acceptable reductions

These are cuts that move cost from the measured column into the unmeasured one:

| Cut | What it actually does |
|---|---|
| Skip the Verifier because the Implementer said it passed | Removes the only independent evidence. The Implementer is the worst judge of its own output — it knows what it intended. |
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
this setting at all, so a Verifier reading test output does not need the override.

### C-2. Compaction — `compaction.strategy` (default `snapcompact`)

Enum: `context-full | handoff | shake | snapcompact | off` (`config/settings-schema.ts:2164-2198`).

| Strategy | Mechanism | Cost profile |
|---|---|---|
| `snapcompact` (default) | Archives history onto dense bitmap images the model reads back. **No LLM call.** | Zero compaction *output* tokens; image tokens on read-back |
| `shake` | Drops heavy content (tool results, large blocks) in place; recover via artifact | No LLM call; loses the dropped content unless re-read |
| `handoff` / `context-full` | Summarize-and-continue | Pays an LLM call per compaction |

Two pruners are on by default and matter more than the strategy choice:

- `compaction.supersedeReads: true` (`:2346-2355`) — an older read of a file is pruned
  when a newer read supersedes it. **Consequence:** the read→edit→re-read pattern is
  nearly free, so caching file contents in the conversation is an anti-pattern.
- `compaction.dropUseless: true` (`:2357-2367`) — no-match and timeout results are pruned
  once consumed. **Consequence:** a failed grep costs almost nothing; exploratory search
  is cheap and should not be rationed.

`compaction.keepRecentTokens` = 20000 (`:2285`).

**Decision rule:** the template does not implement its own compaction. It has no
summarize-the-conversation step in any command. OMP owns this, and a second compactor
would fight the first. If a strategy other than the default is wanted, that is a
`config.yml` line with a recorded reason — not prose in a command.

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

Each spawn returns `tokens` (input + output + cacheWrite, excluding cacheRead),
`requests`, `contextTokens`, `contextWindow`, `cost`, `usage`, `durationMs`,
`structuredOutput`, `modelRole`, `resolvedModel`, `resolvedModelIsFallback`
(`task/types.ts:471-539`, `:428-434`, `:500-505`). Live equivalents stream on
`AgentProgress` over `task:subagent:{event,progress,lifecycle}` (`:395-469`, `:59-65`).

**Decision rule:** the benchmark harness reads these fields. It does not estimate. And
because `resolvedModelIsFallback` is returned per spawn, a model-role misroute is
*observable at the result* — it is only silent if the caller ignores it.

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
| `autoloadSkills` on implementer + verifier | per-spawn | 500 × 2 = 1,000 | Deterministic injection at spawn (`task/executor.ts:3235-3248`) |

**Decision: `autoloadSkills` on the agents whose contract it governs, plus a one-line
sticky invariant for the main session.** 7.5× cheaper than the sticky-only option and
strictly stronger than lazy. The duplication between the sticky line and the skill body
is intentional and must be documented as such — the two serve disjoint audiences, and a
future deduplication pass would otherwise delete the worker copy.

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

`task.enableLsp` is `false` by default (`config/settings-schema.ts:4615-4625`); the
baseline sets it `true`. The tool must *also* be in the agent's `tools:` allowlist —
permission is not provision.

Naively this reads as a cost (another tool, another turn). It is the opposite:
`lsp references` answers "who calls this" without loading callers, and `lsp symbols`
answers "what does this export" without loading the file. Both replace whole-file reads
with targeted queries.

**Decision: ADOPT for explorer, implementer, reviewer.** Not verifier — it runs commands
and reads output; symbol navigation is outside its contract and invites scope creep into
review territory. Note the deeper point: `task.enableLsp: true` with no agent listing
`lsp` means the template pays a baseline deviation and receives nothing for it.

### E-4. `read-summarize: false` on the Explorer

The Explorer's own instructions say to prefer symbol lookup over full reads. Its
frontmatter disables the mechanism that would bound the reads it does perform. The
frontmatter wins, because it is machinery and the instruction is prose.

**Decision: REMOVE from Explorer.** Its output is ranked evidence — `file:line` plus
brief context — and summarized reads are *better* input for that than full contents.

For the Verifier the case is weaker than it looks: its evidence comes from `bash`
output, which `read.summarize` does not touch. The override only affects files it reads
with `read`. **Decision: remove, with a documented restore condition** — if a fixture
shows the Verifier missing failure detail because of summarization, restore it for the
Verifier only and record why.

### E-5. Parallel exploration in `/orchestrated`

Two Explorers over *different* modules: legitimate. Two Explorers asked the same
question: duplicated reads, duplicated tokens, no new information.

**Decision: parallelize only on genuine independence, and independence means disjoint
scope.** Size alone never justifies fan-out. A large sequential task is Standard with
more steps — spawning four agents to do four dependent things is strictly worse than one
agent doing them, because each handoff loses context and costs a spawn.

For parallel Implementers, independence additionally means **disjoint file sets**,
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
| Removing `read-summarize: false` reduces Explorer cost | A/B on the same fixtures, same scope |
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
