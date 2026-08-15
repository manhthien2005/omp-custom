# Context Budget Reference

<!-- topic05-doc:context-budget -->
Progressive retrieval follows source fitness within a bounded budget, not mandatory exhaustion.
Native exact-text and current-source evidence remains the baseline. Optional CodeGraph is selected
only for fitting relationship questions, returns a compact cited hypothesis, and falls back
explicitly to native retrieval. Cheap Scout volume stays separate from premium/core context.

> OMP runtime: not loaded. This is human reference material; actionable rules are delivered
> through AGENTS/worker prompts and advisory static validation.

Retired source: context-budget.yml. The values below are provisional defaults pending evaluation,
not empirically established optima.

## Provisional component budgets

| Component | Target | Warn above | Load |
|---|---|---|---|
| `AGENTS.md` | 600–1,200 | 1,500 | persistent |
| `RULES.md` | 300–700 | 800 | sticky |
| Agent system prompt | 500–1,200 | 1,500 | per worker session |
| Skill description | 30–80 | 120 | persistent listing |
| Skill body | 800–2,000 | 2,500 | lazy |
| Task packet | 300–800 | 1,200 | per task |
| Worker result | 200–600 | 1,000 | per result |

## Enforcement level

| Category | Enforcement |
|---|---|
| AGENTS/RULES/agent prompt | advisory `chars / 4` static check with target minimum, target maximum, and hard warning |
| skill description/body | reference only; a more-specific skill contract wins |
| task packet/worker result | prompt contract only |
| optimality | not established until evaluation |

`chars / 4` is a rough size signal, not exact tokenization. Static warnings must not be reported as
provider token counts or proof that a component is optimally sized.

## Packet and result prohibitions

- A task packet must not contain the parent transcript, raw terminal history, a full repository
  dump, or unrelated architecture material. It carries only the objective, scope, acceptance
  criteria, constraints, relevant references, and verification commands.
- A worker result must not contain chain-of-thought or full transcripts. It returns the compact
  decision, changed files, decisive evidence, risks, and unresolved items.

## Progressive retrieval

Use the cheapest authoritative source that can answer the question, in this order:

1. local code and types, including symbol lookup and call sites;
2. local documentation and source comments;
3. official versioned documentation bundled with the dependency;
4. current version-specific library documentation through the approved Context7 transport;
5. broader web research as a last resort.

Prevent context degradation with KD-031's managed continuity profile: automatic semantic
compaction is off, recent retention remains 20,000 tokens, `dropUseless = true`, and read
summarization stays enabled unless an exact-evidence requirement overrides it. After Topic 04 task
arming, only argument-free `/safe-compact` may authorize one native soft context-full transaction;
it never auto-continues or retries. Use symbol search before full-file reads, never forward the
parent transcript, and replace large tool output with a stable artifact reference when the runtime
supports it.

## Filesystem offload boundary

- Non-isolated work may persist long exploration or review material under a task-scoped `.task/`
  path when the project convention provides one.
- Isolated workers must use the OMP artifact manager for retained output; a parent-worktree
  `.task/` path is not a universal cross-isolation transport.
- Verification output over roughly 500 tokens should be compacted to decisive lines; exploration
  over roughly 2,000 tokens and review findings over roughly 1,000 tokens should be retained as an
  artifact only when the consumer needs the detail.

These thresholds are guidance inherited from the retired source. Their optimality remains an
evaluation question.
