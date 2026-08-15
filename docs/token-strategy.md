# Token Strategy

<!-- topic05-doc:token -->
Cheap Scout may use abundant inexpensive retrieval tokens to protect premium Lead context, but its
tokens and raw provider totals remain visible separate telemetry. CodeGraph summaries must be
compact and must not duplicate raw graph payloads across sessions. Missing provider/cache usage is
`not_measured`, never estimated, and cannot support a promotion claim.

See `docs/research/token-impact-analysis.md` for the full analysis and
`docs/policies/context-budget.md` for the reconciled non-runtime reference.

## Core principle

> **quality gates first; then core workflow tokens per validated accepted outcome**

A validated accepted outcome has complete objective/criteria evidence, clear required gates,
no blocker, and Tech Lead acceptance. Failed attempts and rework remain charged to the same
task cycle; waived or partial results do not enter the denominator.

Report three unweighted ledgers: `core_workflow_tokens` is optimized;
`cheap_scout_tokens` is telemetry only; `raw_total_tokens` shows both. The Tech Lead may use a
configured Cheap Scout for read-only retrieval without a token quota, and falls back to the
needed Lead retrieval path if it fails. Exact accounting, dual baselines, and promotion gates
are defined in `spec/key/03-token-quality-model.md §A` and
`spec/13-validation-and-evaluation.md §C`.

## Runtime topology boundary

- Plain requests stay with the main-session Tech Lead and default to inline/no-spawn execution.
- Cheap Scout is optional read-only retrieval. Its tokens are intentionally not quota-gated:
  DeepSeek Flash at maximum reasoning is primary, DeepSeek Pro at maximum reasoning is fallback,
  then retrieval returns to the Tech Lead.
- Worker is benefit-gated: normal work uses `high`, hard bounded work uses Tech-Lead-selected
  `xhigh`.
- General Reviewer is risk-gated and always `xhigh`. Opus is preferred, not required; a same-model
  independent session is disclosed.
- Parallel writers are conditional on disjoint ownership and safe isolation; otherwise the valid
  plan runs sequentially.

## Per-component budgets

| Component | Target | Warn above |
|-----------|--------|-----------|
| AGENTS.md | 600–1,200 | 1,500 |
| RULES.md | 300–700 | 800 |
| Each agent prompt | 500–1,200 | 1,500 |
| Skill description stub | 30–80 | 120 |
| Skill body (lazy) | 800–2,000 | 2,500 |
| Task packet | 300–800 | 1,200 |
| Worker result | 200–600 | 1,000 |

`scripts/validate-template.ps1` applies an advisory `chars / 4` approximation to AGENTS, RULES,
and agent prompts. It is not an exact tokenizer. Skill values remain reference guidance;
task-packet and worker-result values are prompt contracts.

## Managed context continuity

The historical automatic-`shake` baseline is superseded. Managed sessions reassert
`contextPromotion.enabled=false`, `compaction.enabled=false`, `strategy=off`, thresholds `-1`,
and idle/mid-turn/auto-continue/remote paths off. `keepRecentTokens=20000`, `dropUseless=true`, and
`supersedeReads=true` remain part of the exact profile; read summarization stays separate.

After Topic 04 task arming, argument-free `/safe-compact` may spend one configured-model call on
OMP's native soft context-full summarizer. It first saves and verifies local recovery bytes, then
injects one canonical continuity kernel on the next normal prompt. It never schedules another
turn, retry, or handoff. This cost belongs to the same task cycle. At pressure, ordinary provider
dispatch stops; a bounded child fails/partial, and the main session either compacts once or hands
off explicitly.

## Template-level token savings

- Coding constitution in **one place** (AGENTS.md) — not repeated in agent prompts
- Skills are **lazy-loaded** — bodies not in context until triggered
- Task packets carry **no parent transcript** — only task-relevant context
- Worker results are **compact structured artifacts** — no chain-of-thought, no terminal dumps
- Progressive retrieval — local code first, web last
- Automatic semantic compaction and hidden continuation are disabled; explicit `/safe-compact`
  preserves authoritative task decisions through one bounded transaction
- The Topic 06 managed overlay fixes `task.softRequestBudget: 200`; the 300-request forced partial
  is rejected as nonterminal rather than counted as a successful cheap outcome
- Receipts carry verified identity and bounded facts only; Topic 04 retains durable authority

## When tokens are well-spent

| Addition | Justification |
|----------|--------------|
| AGENTS.md coding constitution | Prevents speculative abstractions and false completion (high-cost rework) |
| RULES.md sticky invariants | Keeps critical rules visible in long sessions |
| Task packet (structured) | Enables independent verification; prevents ambiguity rework |
| Systematic debugging skill | Only loaded when bug encountered; prevents multi-fix thrashing |
| Selected independent verification mechanism | Independent verification prevents false-completion acceptance |

## When tokens are not well-spent

- Independent review on every Quick task is unnecessary token cost unless the accepted task
  contract and risk require it.
- Full repository dumps (use progressive retrieval instead)
- Parent transcript forwarded to subagents (task packet only)
- Duplicate coding principles across agent definitions
