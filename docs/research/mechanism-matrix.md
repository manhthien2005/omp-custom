# Mechanism Matrix

> Authority boundary: This research file is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.

<!-- Generated: 2026-08-07 — Phase 2 -->

Historical research input only; no current design, execution, routing, fallback, topology, or capability authority.
ADOPT and ADAPT labels below record an earlier research pass and do not select current runtime behavior.
Current decisions live in the accepted design, key decision log, active specs, and Topic 03-selected manifest.

## Legend
- **Token impact**: + = adds tokens, - = reduces tokens, 0 = neutral, ? = unclear
- **Decision**: ADOPT | ADAPT | REJECT

---

## Section 1 — Runtime and Orchestration

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Agent definition (`.omp/agents/*.md` frontmatter) | oh-my-pi | Custom agent roles with dedicated system prompts and model routing | Native OMP mechanism | 0 | High | **ADOPT** | This IS the OMP agent contract. All five agents will be defined this way. |
| Task batch orchestration (`task.batch=true`) | oh-my-pi | Parallel subagent execution | Native OMP mechanism | 0 | High | **ADOPT** | Config baseline already set. Orchestrated workflow uses this. |
| Task isolation (`task.isolation.mode=auto`) | oh-my-pi | Isolated subagent filesystems | Native OMP mechanism | 0 | High | **ADOPT** | Config baseline already set. Prevents cross-contamination. |
| Model roles (`modelRoles.<role>`) | oh-my-pi | Decouple agent definition from concrete model | Native OMP mechanism | 0 | High | **ADOPT** | Model routing policy uses this; agents reference `@tech-lead`, `@explorer`, etc. |
| AGENTS.md context injection | oh-my-pi | Project-wide persistent instructions | Native OMP mechanism | + (persistent) | High | **ADOPT** | Primary vehicle for coding constitution and project rules. Target: 600–1,200 tokens. |
| RULES.md sticky rule | oh-my-pi | Hard invariants that survive long sessions | Native OMP mechanism | + (small, re-attached) | High | **ADOPT** | Use for critical-invariants only. Target: 300–700 tokens. |
| Shake compaction | oh-my-pi | Replace tool results with artifact:// references | Native OMP mechanism | - (reduces) | Neutral | **ADOPT** | Config baseline already uses shake. Reduces context without losing evidence. |
| LSP integration | oh-my-pi | Language-aware symbol lookup, diagnostics | Native OMP mechanism | 0 | High | **ADOPT** | Config baseline has `lsp.enabled=true`. Explorer agent leverages this. |
| Skill progressive disclosure (`skill://` URLs) | oh-my-pi | Load skill content on demand, not permanently | Native OMP mechanism | - (lazy load) | Neutral | **ADOPT** | Skills listed in system prompt but body loaded only when triggered. |
| `@` imports in AGENTS.md | oh-my-pi | Include sub-files without token duplication | Native OMP mechanism | - (or 0) | Neutral | **ADOPT** | Use to reference policy files from AGENTS.md without bloating main file. |

## Section 2 — Coding Constitution

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Think before coding | andrej-karpathy-skills / 12FA | Prevents assumption-driven code | None | 0 | High | **ADOPT** | Rewritten independently. Core constitutional principle. |
| Simplicity first | andrej-karpathy-skills | Prevents over-engineering | None | 0 | High | **ADOPT** | Rewritten. Core principle. |
| Surgical changes | andrej-karpathy-skills | Prevents scope creep in diffs | None | 0 | High | **ADOPT** | Rewritten. Core principle. |
| Goal-driven execution / verifiable success criteria | andrej-karpathy-skills | Prevents false completion | None | 0 | High | **ADOPT** | Rewritten. Merged with evidence-before-completion. |
| No false completion | superpowers (verification-before-completion) | Agent declares success without evidence | None | 0 | Critical | **ADOPT** | Rewritten as `evidence-before-completion` skill. |
| Root-cause fixes (not symptom patching) | superpowers (systematic-debugging) | Symptom fixes create regression debt | None | 0 | High | **ADOPT** | Rewritten as `systematic-debugging` skill. |
| No drive-by refactoring | andrej-karpathy-skills | Noise in diffs, unexpected breakage | None | 0 | High | **ADOPT** | Included in coding constitution. |
| No speculative abstractions | andrej-karpathy-skills | Unasked-for complexity | None | 0 | High | **ADOPT** | Included in coding constitution. |

## Section 3 — Workflow Architecture (12-Factor-Agents)

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Own your prompts | 12FA | Opaque framework prompts cause debugging hell | None | 0 | High | **ADOPT** | All prompts are explicit `.md` files. No hidden system prompts. |
| Own your context window | 12FA | Uncontrolled context degrades agent behavior | None | 0 | High | **ADOPT** | Context-budget policy. No parent transcript forwarding. |
| Own your control flow | 12FA | Framework owns routing → opaque failures | None | 0 | High | **ADOPT** | Tech Lead owns workflow selection. OMP task system is explicit. |
| Tools as structured outputs | 12FA | Unstructured results are hard to validate | None | 0 | High | **ADOPT** | Four YAML schemas (task-packet, agent-result, verification-result, review-result). |
| Compact errors into context | 12FA | Long error transcripts waste context | None | - (reduces) | High | **ADOPT** | Agent-result schema includes `known_risks` and `unresolved` fields, not raw logs. |
| Small focused agents | 12FA | Monolithic agents become unreliable | Slight overlap with OMP task recursion depth | 0 | High | **ADOPT** | Five agents with non-overlapping responsibilities. |
| Stateless reducer concept | 12FA | Hidden state makes agents unreliable | None | 0 | High | **ADOPT** | Worker results are durable artifacts, not in-memory state. |
| Pause/resume semantics | 12FA | Long-running tasks must survive interruption | Partial (OMP sessions persist) | 0 | Medium | **ADAPT** | Artifacts-on-disk provide implicit pause/resume; no explicit pause API needed for v0. |

## Section 4 — Specification System

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Clarification gate | spec-kit | Ambiguous requirements cause rework | None | 0 | High | **ADOPT** | Part of task-triage skill and Tech Lead contract. |
| Acceptance scenarios (Given/When/Then) | spec-kit | Vague success criteria | None | 0 | High | **ADOPT** | Included in task-packet schema `acceptance_criteria` field. |
| Project constitution | spec-kit | No shared project principles | None | + (one-time) | High | **ADOPT** | Implemented in AGENTS.md coding constitution section. |
| Delta specs (ADDED/MODIFIED/REMOVED) | OpenSpec | Brownfield spec changes require restating full spec | None | - (smaller than full spec) | High | **ADOPT** | Template `.openspec/` directory recommended for projects using this workflow. |
| Change folder (proposal, design, tasks, delta specs) | OpenSpec | Scattered spec artifacts | None | 0 | High | **ADOPT** | Template structure documented in docs/architecture.md. |
| Archive lifecycle | OpenSpec | Completed changes pollute active work area | None | 0 | Medium | **ADOPT** | Changes/ → changes/archive/; source of truth maintained in specs/. |
| Full spec-kit CLI | spec-kit | — | — | — | — | **REJECT** | External Python CLI. Not an OMP primitive. Concepts adopted natively. |
| Full OpenSpec CLI | OpenSpec | — | — | — | — | **REJECT** | External Node CLI. Not an OMP primitive. Concepts adopted natively. |

## Section 5 — Context and Token Policy

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Context-budget policy | muratcankoylan/ASCE | No explicit budget = slow degradation | None | - (prevents waste) | High | **ADOPT** | Formal policy YAML with per-component token targets. |
| Progressive retrieval ordering | muratcankoylan/ASCE | Agents fetch web before reading local code | None | - (avoids expensive calls) | High | **ADOPT** | local code → local docs → official docs → Context7 → web. |
| Filesystem offloading | muratcankoylan/ASCE | Results that don't need to stay in context | Partial (OMP artifact:// via shake) | - (reduces) | Neutral | **ADAPT** | OMP shake compaction handles this natively. Policy documents the approach. |
| No transcript forwarding to subagents | 12FA / muratcankoylan | Parent transcript bloats child context | None | - (significant) | High | **ADOPT** | Task-packet schema carries only task-relevant context. |
| Structured tool results | 12FA | Raw tool output wastes context | None | - | High | **ADOPT** | Worker results use structured YAML schemas. |
| No full-repo dumps | muratcankoylan / plan | Single context dump = context flood | None | - (prevents waste) | High | **ADOPT** | Progressive retrieval; repomix only for onboarding/audits. |

## Section 6 — Code Understanding

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Repository-map / symbol-first exploration | aider | Reading full files before understanding structure | None | - (reads less) | High | **ADOPT** | Explorer agent: symbols/references before full-file reads. |
| References and callers before full-file reads | aider | Unnecessary full-file context | None | - | High | **ADOPT** | Explorer agent contract. |
| OMP LSP hover/references | oh-my-pi | Semantic code navigation | Native OMP mechanism | 0 | High | **ADOPT** | Already in config baseline. |
| OMP read summaries | oh-my-pi | Full file reads add too many tokens | Native OMP mechanism | - | Neutral | **ADOPT** | `read.summarize.enabled=true` in baseline. |
| Serena semantic retrieval | serena | LSP insufficient for certain languages | None | ? | ? | **CONDITIONAL** | Evaluate when OMP LSP + native search is insufficient. Not in v0. |
| Repomix snapshots | repomix | Onboarding to unknown large codebase | None | + (targeted use) | Medium | **CONDITIONAL** | Use only for onboarding, architecture audits, external reviews. Not default. |
| Context7 library docs | context7 | Current versioned library documentation | None | + (targeted use) | High | **CONDITIONAL** | Last resort in retrieval order. Not default. |

## Section 7 — Agent Orchestration

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Tech Lead agent | plan DNA | Single responsible coordinator | None | + (one agent) | High | **ADOPT** | Owns workflow selection, task packets, result validation. |
| Explorer agent | plan DNA / aider | Dedicated codebase investigation | None | + (one agent) | High | **ADOPT** | Symbol-first; returns ranked evidence. Does not implement. |
| Implementer agent | plan DNA / mini-swe-agent | Focused implementation loop | None | + (one agent) | High | **ADOPT** | inspect→edit→verify→compact loop. |
| Verifier agent | plan DNA / superpowers | Independent verification (not trusting implementer) | None | + (one agent) | High | **ADOPT** | Runs fresh verification. Returns evidence, not assumptions. |
| Reviewer agent | plan DNA / addyosmani | Code review against actual diff | None | + (one agent) | High | **ADOPT** | Reviews diff only; false-positive control; evidence-backed findings. |
| Subagent-driven-development (SDD) | superpowers | Parallel subagent orchestration | Duplicate OMP task.batch | + (complex) | Medium | **REJECT** | OMP task.batch already handles parallel agents. SDD adds second orchestrator. |
| Dispatching-parallel-agents | superpowers | Parallel agent dispatch | Duplicate OMP task.batch | — | — | **REJECT** | Duplicate of OMP native mechanism. |
| Minimal worker loop | mini-swe-agent | Complexity governor | None | - | High | **ADOPT** | Implementer agent follows inspect→edit→verify→compact; no speculative loops. |
| Bundled scout/librarian/designer agents | oh-my-pi | Specialized read-only and design agents | Available in OMP | 0 | Medium | **CONDITIONAL** | Available post-v0 as optional specialists. Not in v0. |

## Section 8 — Implementation Discipline

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Risk-based TDD | superpowers | Tests only where they add value | None | 0 | High | **ADOPT** | TDD for new behavior, bug fixes, public APIs. Not for trivial changes. |
| Source-driven decisions | various | Agent invents rather than reads | None | 0 | High | **ADOPT** | Explorer returns evidence; Implementer reads before editing. |
| Incremental implementation | plan | Large changes have high failure risk | None | 0 | High | **ADOPT** | Standard workflow splits large tasks. Orchestrated workflow uses dependency graph. |
| Anti-rationalization | addyosmani | Agent defends poor design | None | 0 | Medium | **ADOPT** | Reviewer must verify, not rationalize. |

## Section 9 — Production Quality Gates

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| API compatibility gate | addyosmani | Breaking change ships undetected | None | 0 | High | **ADOPT** | quality-gates.yml; enabled by default for API-touching tasks. |
| Security gate | addyosmani / ECC | Security issues in untriaged code | None | 0 | High | **ADOPT** | quality-gates.yml; enabled by default. |
| Performance gate | addyosmani | Performance regression ships | None | 0 | Medium | **ADOPT** | quality-gates.yml; enabled when requested. |
| ADR / documentation gate | addyosmani | Architectural decisions undocumented | None | 0 | Medium | **CONDITIONAL** | Enabled for orchestrated workflow; off by default for quick/standard. |
| Release/rollback readiness | addyosmani | Deployment without rollback plan | None | 0 | High | **ADOPT** | quality-gates.yml; enabled for orchestrated workflow. |
| Always-on multi-reviewer workflow | various | Redundant review for all tasks | Expensive, unnecessary | + (high) | Low marginal | **REJECT** | Reviewer enabled selectively. Quick workflow has no reviewer by default. |

## Section 10 — Skill Engineering

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| SKILL.md frontmatter (`name`, `description`) | anthropics/skills / oh-my-pi | Skills must be triggerable by description | Native OMP requirement | 0 | High | **ADOPT** | Required for OMP native provider (requireDescription: true). |
| Progressive disclosure (body via skill://) | anthropics/skills / oh-my-pi | Skill body loaded only when needed | Native OMP mechanism | - (lazy) | High | **ADOPT** | Skill description in system prompt; body loaded on demand. |
| Positive trigger examples | anthropics/skills | Skill not triggered when it should be | None | 0 | High | **ADOPT** | Each skill has ≥2 positive trigger examples in SKILL.md. |
| Negative trigger examples | anthropics/skills | Skill triggered when it shouldn't be | None | 0 | High | **ADOPT** | Each skill has ≥2 negative trigger examples. |

## Section 11 — Evaluation

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Quality Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------------|----------|--------|
| Deterministic assertions | promptfoo | Test facts don't need LLM judging | None | - (no LLM call) | High | **ADOPT** | Validation script uses YAML schema validation and file checks. |
| Model-graded assertions | promptfoo | Subjective quality needs LLM grading | None | + (one LLM call) | Medium | **CONDITIONAL** | Only for plan coherence, maintainability, review usefulness. Not default. |
| Workflow A/B comparison | promptfoo | Workflow changes need before/after evidence | None | + (2× tokens) | High | **ADOPT** | Benchmark script records metrics for quick vs standard vs orchestrated. |
| Token/outcome metrics | promptfoo | Tokens per accepted outcome | None | 0 | High | **ADOPT** | Benchmark captures input/output tokens, tool calls, accepted outcome. |

## Section 12 — Governance

| Mechanism | Source | Problem Solved | OMP Overlap | Token Impact | Decision | Reason |
|-----------|--------|----------------|-------------|--------------|----------|--------|
| Upstream registry | plan | Provenance lost over time | None | 0 | **ADOPT** | registry/upstreams.yml with pinned commits, watched paths, adopted/rejected mechanisms. |
| Pinned commit hashes | plan | Upstream drift causes regressions | None | 0 | **ADOPT** | All 17 upstreams pinned. |
| Adoption ledger | plan | Why a mechanism was adopted is unknown 6 months later | None | 0 | **ADOPT** | registry/adoption-ledger.yml with rationale per mechanism. |
| Rejected mechanisms log | plan | Same bad ideas re-proposed | None | 0 | **ADOPT** | registry/rejected-mechanisms.yml. |
| Skill lock | plan | Skill body changed without review | None | 0 | **ADOPT** | registry/skill-lock.yml with content hashes. |
| Controlled promotion | plan | Upstream changes bypass review | None | 0 | **ADOPT** | Update process in scripts/update-upstreams.ps1. |
