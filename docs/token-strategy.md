# Token Strategy

See `docs/research/token-impact-analysis.md` for the full analysis.

## Core principle

> **tokens per accepted outcome** — not lowest token count, not highest pass rate

A workflow that uses 20% more tokens but produces 50% fewer rewrites is more efficient.

## Per-component budgets

| Component | Target | Hard limit |
|-----------|--------|-----------|
| AGENTS.md | 600–1,200 | 1,500 |
| RULES.md | 300–700 | 800 |
| Each agent prompt | 500–1,200 | 1,500 |
| Skill description stub | 30–80 | 120 |
| Skill body (lazy) | 800–2,000 | 2,500 |
| Task packet | 300–800 | 1,200 |
| Worker result | 200–600 | 1,000 |

Run `.\scripts\validate-template.ps1` to check against these budgets.

## OMP mechanisms that reduce context

These are already configured in the global config baseline:

- **Shake compaction** (`compaction.strategy=shake`) — replaces tool results with `artifact://` references
- **`compaction.keepRecentTokens=20000`** — protects recent context from compaction
- **`compaction.dropUseless=true`** — elides zero-match searches and empty results
- **`compaction.supersedeReads=true`** — removes superseded reads
- **`read.summarize.enabled=true`** — returns structural summaries instead of full files

## Template-level token savings

- Coding constitution in **one place** (AGENTS.md) — not repeated in agent prompts
- Skills are **lazy-loaded** — bodies not in context until triggered
- Task packets carry **no parent transcript** — only task-relevant context
- Worker results are **compact structured artifacts** — no chain-of-thought, no terminal dumps
- Progressive retrieval — local code first, web last

## When tokens are well-spent

| Addition | Justification |
|----------|--------------|
| AGENTS.md coding constitution | Prevents speculative abstractions and false completion (high-cost rework) |
| RULES.md sticky invariants | Keeps critical rules visible in long sessions |
| Task packet (structured) | Enables independent verification; prevents ambiguity rework |
| Systematic debugging skill | Only loaded when bug encountered; prevents multi-fix thrashing |
| Verifier agent | Independent verification prevents false-completion acceptance |

## When tokens are not well-spent

- Reviewer on every Quick task (low-risk changes rarely need review)
- Full repository dumps (use progressive retrieval instead)
- Parent transcript forwarded to subagents (task packet only)
- Duplicate coding principles across agent definitions
