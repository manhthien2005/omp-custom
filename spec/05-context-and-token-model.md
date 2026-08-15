# 05 — Context and Token Model

<!-- topic05-projection:context -->
## Topic 05 compact retrieval overlay (KD-029)

Choose the most source-fit accessible level within a bounded retrieval budget. Optional CodeGraph
is useful for relationship/blast-radius hypotheses, while native retrieval remains the baseline
and the required corroboration for absence. Carry the compact cited overlay across boundaries;
do not duplicate raw graph output plus an equivalent summary. Cheap Scout token volume is
reported separately from premium/core workflow context and is never estimated.

## Durable checkpoints and offload tiers (KD-028)

Compact checkpoints preserve next action, blockers, risks, lineage, and worktree binding before
compaction, handoff, stop, or user wait. `.task/<task-id>` and runtime artifacts are transient raw
offload, not lifecycle authority or acceptance evidence. Only bounded sanitized artifacts are
content-addressed and promoted. Prompts receive compact projections/IDs, never raw authority or a
second compactor's state.

> OPUS PROPOSED SPEC v1 | What loads when, what each budget is, and where the current template overspends.
>
> **Topic 02 supersession boundary:** role names below are frozen-baseline examples, not
> topology authority. Token controls attach to responsibilities selected by Topic 03.
>
> **KD-027 projection:** Cheap Scout may spend abundant cheap retrieval tokens but remains
> read-only/advisory. Core-token accounting covers Tech Lead, Worker, and Reviewer; benefit-gated
> spawn prevents delegation overhead when inline work is cheaper. Worker defaults `high`, hard
> Worker and Reviewer use `xhigh`.

---

## A. The Metric

The decision order is **quality gates → validated accepted-outcome rate → core workflow
tokens per validated accepted outcome → latency tie-breaker**. No weighted score can trade a
failure in an earlier term for a gain in a later one (`spec/key/03 §A`, KD-024).

“Accepted” means the objective is complete, every mandatory criterion has PASS evidence,
required verification/review is clear, no blocking authority or scope issue remains, and the
Tech Lead records acceptance against an immutable candidate. `cancelled` and
`terminally_blocked` are the other terminal task outcomes. Waived results remain outside the
validated denominator; `partial`, recoverable `blocked`, `waiting_for_user`, and rework are
nonterminal observations.

The accounting boundary is the whole task cycle, beginning when the task contract is accepted
and ending at one of its three terminal outcomes. It includes failures, rejected candidates,
retrieval, retries, rework, handoff/compaction, and Scout fallback. The primary ledger is
`core_workflow_tokens`; `cheap_scout_tokens` and `raw_total_tokens` are unweighted telemetry.
A zero accepted-outcome denominator is infinite cost. Exact fields, frozen dual baselines, and
promotion thresholds are canonical in `13-validation-and-evaluation.md §C`.

This distinction decides every trade-off below. Any change that saves core tokens by
weakening verification is not a saving; it moves cost from the measured column to the
unmeasured one. Latency is recorded for reliability and used only as a final tie-breaker.

Concretely, the following are never acceptable token reductions:

- Skipping required independent verification because the candidate author reported success.
- Dropping the failing-test-first step on a bug fix.
- Reducing thinking level on a high-risk task.
- Trimming acceptance criteria to fewer than the change needs.
- Suppressing uncertainty to avoid a clarification round-trip.

---

## B. What Loads, and When

Four distinct lifetimes. Confusing them is the source of most token waste.

| Tier | Loaded | Cost model |
|---|---|---|
| Persistent | Every turn of every session | Paid once per turn, forever |
| Sticky | Re-attached near the current turn | Paid per turn, survives compaction |
| Per-session | Once per subagent session | Paid per spawn |
| Lazy | Only when referenced | Paid only on use |

Assignments:

- **Persistent** — `AGENTS.md`; the skill *listing* (name + description of every
  discovered skill).
- **Sticky** — `RULES.md`. Verified: `discovery/builtin.ts:416` forces
  `alwaysApply` regardless of frontmatter, so it survives compaction.
- **Per-session** — each agent's system prompt body; each task packet.
- **Lazy** — skill bodies, read via `skill://<name>`.

The skill *listing* being persistent while skill *bodies* are lazy is the
progressive-disclosure mechanism that makes skills cheap. It also means a skill's
`description` is load-bearing: it is the only part most sessions ever pay for,
and it is what the model uses to decide whether to pay for the body.

---

## C. Budgets

Adopted from `context-budget.yml` as **provisional defaults pending Phase 06 evaluation** (CR-19).
These targets represent initial baselines based on role complexity; actual optimal values
will be validated through A/B testing before being promoted to production recommendations.

| Component | Target | Warn above | Tier |
|---|---|---|---|
| `AGENTS.md` | 600–1,200 | 1,500 | persistent |
| `RULES.md` | 300–700 | 800 | sticky |
| Agent system prompt | 500–1,200 | 1,500 | per-session |
| Skill description | 30–80 | 120 | persistent |
| Skill body | 800–2,000 | 2,500 | lazy |
| Task packet | 300–800 | 1,200 | per-task |
| Worker result | 200–600 | 1,000 | per-result |

`validate-template.ps1` already checks the first three. It does not check skill
descriptions, skill bodies, or — because they are runtime artifacts — packets and
results. Packets and results are enforced by contract in the agent prompts, not
statically.

The request ceiling is a separate runtime boundary. `task.softRequestBudget` defaults to
200 requests; after the wrap-up notice, 1.5× the budget forces a stop and returns a partial
yield (`config/settings-schema.ts:4676-4692`, `task/executor.ts:1568-1596,1821-1826`). Task
packets must be scoped to finish inside that boundary. A forced softRequestBudget partial yield
is nonterminal and requires recovery or redispatch. It cannot supply completion evidence even
when its prose looks complete.

---

## D. The Two Prohibitions

**Task packets must not contain the parent transcript.** This is `RULES.md`
invariant 4 and it is the single most important token rule in the system. A
packet carrying the parent conversation defeats the entire purpose of
delegation: the subagent pays for context it cannot act on, and the parent pays
again when the result comes back. Packets carry objective, scope, criteria,
file references, and constraints — nothing that reads as history.

**Worker results must not contain chain-of-thought or full transcripts.** The
Tech Lead needs the conclusion and the evidence, not the path taken. A result
that quotes 200 lines of test output to prove 12 tests passed has spent ~1,500
tokens to convey what "12 passed, 0 failed, exit 0" conveys in ten.

Both prohibitions are stated in `context-budget.yml` under `must_not_contain`
and both are correct. They need to appear in the agent prompts, not only in a
policy file no agent reads.

---

## E. Where the Current Template Overspends

### E-1. `read-summarize: false` on the former Explorer adapter — P1 defect

The global baseline sets `read.summarize.enabled = true`. Explorer's frontmatter
sets `read-summarize: false`, which `parseAgentFields` reads
(`discovery/helpers.ts:300`) and honours. The field works. That is the problem.

Explorer's own instructions say it must not dump full files and should prefer
symbol lookup. Its frontmatter disables the mechanism that would summarize the
files it does read. The two are in direct opposition, and the frontmatter wins
because it is machinery and the instruction is prose.

Explorer's job is ranked evidence — file paths, line references, symbol names,
brief context. Summarized reads are *better* input for that than full contents.
Recommend removing the override.

### E-2. `read-summarize: false` on the former Verifier adapter — P1, weaker case

More defensible: verification needs exact output, and a summarizer that elides
the one line showing which assertion failed has destroyed the evidence.

But the Verifier gets its evidence from `bash` command output, which
`read.summarize` does not touch. The override only affects files it reads with
`read` — mostly test files and source, where summaries are adequate.

Recommend removing it. A selected exact-output verification responsibility may disable read
summarization only when a fixture shows that summaries lose required file evidence, and the
selected contract records why. Command output from `bash` is unaffected by this setting.

### E-3. Reviewer scope creep — P1

`reviewer.md` says to read "the actual changed files and their diff context."
"Diff context" is unbounded — it can be read as the whole file. For a large
file with a three-line change, that is a full-file read to review three lines.

Recommend: diff first (`git diff`), then targeted expansion only where a finding
requires it, and only the enclosing symbol. Bound it explicitly in the prompt.

### E-4. Constitution duplication risk

`validate-template.ps1` section 3 already guards this: it warns if constitutional
phrases from `AGENTS.md` appear verbatim in agent files. This check is well
designed and should be extended to the skill bodies, which currently are not
scanned.

The reason it matters: `AGENTS.md` is persistent and every agent inherits it.
A rule repeated in five agent prompts is paid six times.

---

## F. Progressive Retrieval

Adopted from `context-budget.yml` as **guidance** (CR-20: not rigid gates — authority ordering is task-dependent).

```
1. Local code and types (LSP symbols, current file, related modules)
2. Local documentation (README, docs/, comments)
3. Official versioned documentation
4. Context7 (version-specific library docs)
5. Broader web research
```

**Guidance, not exhaustion gates**: prefer project executable truth for "what this repo currently does"; prefer version-matched official docs for external API/runtime semantics. If the current level cannot answer the question within a reasonable retrieval budget, escalate rather than continuing to search. Most retrieval failures are jumps from level 1 to level 5 — a web search for something the type definition next to the callsite already answered. But "exhaust level N before descending" is not the rule — the rule is: use the most authoritative source for the specific question type, within a bounded retrieval budget.

Every skipped level uses a named reason and is disclosed in the retrieval result. The reason
context7_unavailable is the disclosed named skip when level 4 is unavailable; it authorizes
the next fitting accessible source under the same bounded-escalation rule, never a silent
fallback or backtrack.

web_unavailable is disclosed when level 5 is unavailable; a freshness contract remains
unresolved and cannot be accepted without authoritative evidence. There is no implicit level 6
and no permission to substitute model memory for a current-source requirement.

Levels 4 and 5 are not wired in v0. Context7 is available as an MCP tool in this
environment but is not part of the template; `web_search` is in the Tech Lead's
allowlist only.

> **ENVIRONMENT ASSUMPTION (CR-18)**: Context7 availability and `web_search` access depend on the runtime environment. These are not public-source-verifiable facts — verify with a sanitized runtime discovery transcript.

---

## G. Filesystem Offloading

When a result is large but must persist, write it to a file and pass the path.

**Thresholds are provisional v0 starting values pending phase-03 calibration (CR-19)** —
same status as the §C budget table. They are engineering estimates of where a result stops
being worth carrying inline, not measured optima. Phase-03 T-03.7 records offload frequency
and whether crossing a threshold predicts a worse outcome, then adjusts. Do not cite them as
validated.

| Artifact | Threshold (provisional) | Destination | Isolation-safe? |
|---|---|---|---|
| Exploration evidence | >2,000 tokens | `.task/<id>/exploration.md` | Non-isolated retained workspace only |
| Verification output | >500 tokens | quote key lines only; full output to `.task/<id>/verify.log` | Non-isolated retained workspace only |
| Review findings | >1,000 tokens | `.task/<id>/review.md` | Non-isolated retained workspace only |

This is how a worker returns a large finding without putting it in the parent's
context: the result carries `artifacts: [".task/impl-001/review.md"]` and the
Tech Lead reads it only if it needs to.

`.task/` must be gitignored. It is session scratch, not project content.

**CR-10 — Isolated workers must use the OMP artifact manager, not `.task/`.**

An isolated worker operates in a temporary worktree that is torn down after the task
lifecycle completes. A gitignored `.task/<id>/...` file inside the isolated worktree
does not propagate through git branch/patch merge, and is destroyed when the worktree
is cleaned up. The path reference passed in the result is invalid in the parent.

For every selected isolated worker: use the OMP native artifact manager
(executor options for parent artifact manager adoption, available in `sdk.ts`).
The child session adopts the parent artifact manager, and artifacts are stored in
the parent artifact domain — remaining valid after isolation teardown.

The `.task/<id>/...` pattern is safe **only** for a non-isolated worker whose working tree
persists through the full Tech Lead lifecycle. That may be Standard or sequential,
non-isolated Orchestrated execution. Offload safety follows effective isolation and
artifact-retention responsibility, independent of workflow name.

---

## H. Compaction

The frozen baseline's `shake` setting is historical evidence only. KD-031 selects this managed
profile:

```
contextPromotion.enabled    = false
compaction.enabled          = false
compaction.strategy         = off
compaction.midTurnEnabled   = false
compaction.thresholdPercent = -1
compaction.thresholdTokens  = -1
compaction.keepRecentTokens = 20000
compaction.autoContinue     = false
compaction.idleEnabled      = false
compaction.remoteEnabled    = false
compaction.remoteStreamingV2Enabled = false
compaction.supersedeReads   = true
compaction.dropUseless      = true
```

`supersedeReads = true` matters for the workflows: when a file is read twice,
the earlier read is dropped. This makes the "re-read after edit" pattern cheap
and removes the incentive to cache file contents in the conversation.

The template implements no summarizer. After exact Topic 04 task arming, `/safe-compact` accepts
no arguments and authorizes one native `ctx.compact({ mode: "soft" })` context-full transaction.
It writes and verifies a local recovery artifact first, schedules no continuation or retry, and
rejects built-in `/compact`, `shake`, `snapcompact`, automatic handoff, and remote compaction as
managed fallbacks.

---

## I. Lifecycle Boundary for Compaction and Handoff

Safe compaction preserves the current task, candidate lineage, session identity, workflow,
ownership, and acceptance state. It rescues context for the same work; neither the compacted
summary, recovery artifact, injected continuity kernel, nor conversation history becomes
lifecycle authority. The next normal prompt receives one fresh Topic 04-derived kernel exactly
once; no hidden continuation is scheduled.

Handoff creates a successor session for the same open task and non-competing candidate
lineage. The predecessor loses active ownership after an accepted handoff. Before mutation,
the successor must reconcile the contract and workspace with the handoff; generated handoff
text is a context carrier, not authoritative task state.

Durable task/candidate/session storage, identifiers, and recovery leases remain Topic 04
work. This section fixes conceptual identity only.

At the managed pressure boundary, ordinary provider dispatch stops. The main session uses
`/safe-compact` or explicit Topic 04 handoff. A bounded subagent aborts as failed/partial and is
not automatically retried. If one safe compaction leaves pressure unresolved, stop and hand off
or request user action rather than invoking rescue shake.

---

## I-1. Topic 06 projection boundary

An agent packet is a deterministic, role-minimal view of one Topic 04 work unit. It excludes the
parent transcript, hidden reasoning, credentials, unrelated task state, and Worker CLAIM when the
consumer is Reviewer. A result is similarly compact: structured role output plus an
`agent_boundary_receipt`, never a raw session transcript.

The projection is assembled at dispatch time and discarded as authority after its provisional
outcome is recorded. Topic 04 retains the canonical task/candidate/criterion/evidence state. The
managed runtime sets `task.softRequestBudget: 200`; the 300-request forced partial remains
nonterminal and must be narrowed or repartitioned, not reported as completion.

---

## J. Verification

- `validate-template.ps1` checks budgets for `AGENTS.md`, `RULES.md`, and all
  five agent prompts (already implemented).
- Extend it to skill descriptions (30–120) and skill bodies (800–2,500).
- Extend the constitutional-phrase scan to skill bodies.
- No agent prompt or skill body contains a task-packet example with a transcript.
- `.task/` appears in `.gitignore`.

---

## J. Open Items

| # | Item | Position |
|---|---|---|
| C-1 | Remove unjustified `read-summarize: false` from selected discovery roles | Yes — it contradicts compact-evidence responsibilities |
| C-2 | Permit unsummarized reads for a selected exact-output responsibility | Only with a fixture-backed written condition |
| C-3 | Bound selected review-path "diff context" | Diff first, enclosing symbol only on demand |
| C-4 | Enforce packet/result budgets at runtime | Not possible statically; contract-only in v0 |
| C-5 | Wire Context7 as level 4 | Deferred past v0 |
