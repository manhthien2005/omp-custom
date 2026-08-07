# Final Adoption Plan
<!-- Generated: 2026-08-07 — Phase 2 -->

## Status: Research complete — ready for Phase 3 Architecture

The mechanism matrix, conflict matrix, and authority map are internally consistent.
No unresolved conflicts remain. Proceed to implementing Workflow v0.

---

## Adopted mechanisms — implementation map

### Coding Constitution (AGENTS.md)

| Principle | Source | Implementation |
|-----------|--------|----------------|
| Think before coding | Karpathy (rewritten) | `template/.omp/AGENTS.md` § Coding Constitution |
| Simplicity first | Karpathy (rewritten) | `template/.omp/AGENTS.md` § Coding Constitution |
| Surgical changes | Karpathy (rewritten) | `template/.omp/AGENTS.md` § Coding Constitution |
| Goal-driven execution | Karpathy (rewritten) | `template/.omp/AGENTS.md` § Coding Constitution |
| No false completion | superpowers (rewritten) | `template/.omp/AGENTS.md` § Coding Constitution |
| Root-cause fixes | superpowers (rewritten) | `template/.omp/AGENTS.md` § Coding Constitution |
| Own prompts / context / control flow | 12FA principles | `template/.omp/AGENTS.md` § Workflow Architecture |
| No duplicate orchestration | plan constraint | `template/.omp/AGENTS.md` § Runtime section |

### Agent Definitions

| Agent | File | Primary Sources |
|-------|------|----------------|
| tech-lead | `template/.omp/agents/tech-lead.md` | plan DNA, 12FA (control-flow ownership), spec-kit (clarification) |
| explorer | `template/.omp/agents/explorer.md` | aider (repo-map, symbol-first), mini-swe-agent (small surface) |
| implementer | `template/.omp/agents/implementer.md` | mini-swe-agent (minimal loop), andrej-karpathy (surgical changes) |
| verifier | `template/.omp/agents/verifier.md` | superpowers (verification-before-completion, rewritten) |
| reviewer | `template/.omp/agents/reviewer.md` | addyosmani (quality gates), superpowers (anti-rationalization) |

### Workflows

| Workflow | File | Sources |
|----------|------|---------|
| quick | `template/.omp/workflows/quick.md` | plan (triage→inspect→implement→verify→report) |
| standard | `template/.omp/workflows/standard.md` | plan + spec-kit (mini-spec, acceptance scenarios) |
| orchestrated | `template/.omp/workflows/orchestrated.md` | plan + 12FA (structured outputs) + addyosmani (quality gates) |

### Skills

| Skill | File | Sources |
|-------|------|---------|
| task-triage | `template/.omp/skills/task-triage/SKILL.md` | spec-kit (clarification gate), plan DNA |
| systematic-debugging | `template/.omp/skills/systematic-debugging/SKILL.md` | superpowers (4-phase process, rewritten) |
| evidence-before-completion | `template/.omp/skills/evidence-before-completion/SKILL.md` | superpowers (iron law, rewritten) |

### Schemas

| Schema | File | Sources |
|--------|------|---------|
| task-packet | `template/.omp/schemas/task-packet.schema.yml` | plan DNA, 12FA structured outputs, spec-kit acceptance criteria |
| agent-result | `template/.omp/schemas/agent-result.schema.yml` | plan DNA, 12FA compact errors |
| verification-result | `template/.omp/schemas/verification-result.schema.yml` | superpowers evidence-before-completion (rewritten) |
| review-result | `template/.omp/schemas/review-result.schema.yml` | addyosmani (quality gates), plan DNA |

### Policies

| Policy | File | Sources |
|--------|------|---------|
| context-budget | `template/.omp/policies/context-budget.yml` | muratcankoylan/ASCE, plan DNA |
| model-routing | `template/.omp/policies/model-routing.yml` | oh-my-pi modelRoles, ECC routing patterns |
| workflow-sizing | `template/.omp/policies/workflow-sizing.yml` | plan DNA (quick/standard/orchestrated criteria) |
| quality-gates | `template/.omp/policies/quality-gates.yml` | addyosmani (API, security, performance, ADR, release/rollback) |
| escalation | `template/.omp/policies/escalation.yml` | plan DNA |

---

## Rejected mechanisms log

| Mechanism | Source | Rejection reason |
|-----------|--------|-----------------|
| Subagent-driven-development (SDD) | superpowers | Duplicate OMP task.batch orchestration |
| dispatching-parallel-agents | superpowers | Duplicate OMP task.batch |
| finishing-a-development-branch | superpowers | Duplicate OMP task.isolation git workflow |
| bootstrap enforcement / session-start hooks | superpowers | Not compatible with OMP YoLo mode baseline |
| Full ECC hooks / memory / instinct | ECC | Violates memory=off and uncontrolled-memory constraints |
| ECC full orchestration runtime | ECC | Second runtime violation |
| Full spec-kit CLI | spec-kit | External Python dependency; concepts adopted natively |
| Full OpenSpec CLI | OpenSpec | External Node dependency; concepts adopted natively |
| Serena (v0) | serena | OMP LSP sufficient for v0; evaluate later |
| Repomix (default) | repomix | Context flood risk; conditional use only |
| Context7 (default) | context7 | Retrieval-order last resort; conditional use only |
| Verbatim anthropics/skills content | anthropics/skills | No license file; only format is authoritative |
| Verbatim andrej-karpathy-skills CLAUDE.md | andrej-karpathy-skills | No license; principles independently rewritten |
| Persistent memory / autolearn | oh-my-pi baseline | memory.backend=off per baseline constraint |
| Always-on multi-reviewer workflow | plan | Unnecessary token cost for quick/standard tasks |
| Full promptfoo integration | promptfoo | External tool; local deterministic scripts are primary |

---

## Implementation sequence for Workflow v0

1. `template/.omp/config.yml` — model roles abstraction only (no baseline settings duplication)
2. `template/.omp/AGENTS.md` — coding constitution + workflow architecture principles
3. `template/.omp/RULES.md` — critical invariants only
4. `template/.omp/agents/tech-lead.md`
5. `template/.omp/agents/explorer.md`
6. `template/.omp/agents/implementer.md`
7. `template/.omp/agents/verifier.md`
8. `template/.omp/agents/reviewer.md`
9. `template/.omp/workflows/quick.md`
10. `template/.omp/workflows/standard.md`
11. `template/.omp/workflows/orchestrated.md`
12. `template/.omp/skills/task-triage/SKILL.md`
13. `template/.omp/skills/systematic-debugging/SKILL.md`
14. `template/.omp/skills/evidence-before-completion/SKILL.md`
15. `template/.omp/schemas/*.schema.yml` (4 schemas)
16. `template/.omp/policies/*.yml` (5 policies)
17. `scripts/validate-template.ps1`
18. `scripts/bootstrap.ps1` and `scripts/install-template.ps1`
19. `evals/` — initial benchmark fixtures

---

## Open questions (resolved)

All research questions are resolved. No architecture violations detected. Proceeding to implementation.
