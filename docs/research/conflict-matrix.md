# Conflict Matrix
<!-- Generated: 2026-08-07 — Phase 2 -->

## Purpose

This matrix identifies where multiple upstream sources propose mechanisms for the same concern, and records the resolution.

---

## 1. Subagent Orchestration (CRITICAL CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| oh-my-pi | `task` tool: batch, isolation, concurrency, recursion depth — native OMP orchestrator |
| superpowers | Subagent-driven-development (SDD), dispatching-parallel-agents |
| ECC | Full orchestration runtime |
| 12-factor-agents | Small focused agents + stateless reducer |
| mini-swe-agent | Minimal worker loop |

**Resolution:** OMP task subsystem is the sole orchestration authority. SDD, ECC runtime, and all parallel-agent frameworks are rejected. 12FA and mini-swe-agent principles inform agent *design* but add no runtime layer. The five custom agents in this template are discovered and dispatched by OMP's native `task` tool.

**Risk if violated:** Two orchestration engines would create conflicting loop control, duplicate compaction decisions, and context-forwarding collisions.

---

## 2. Planning Engine (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| superpowers | `writing-plans/SKILL.md` — plan document with reviewer |
| spec-kit | `plan` command template (`templates/commands/plan.md`) |
| OpenSpec | `tasks.md` artifact inside change folder |
| plan DNA (Tech Lead) | Tech Lead owns task decomposition and dependency graph |

**Resolution:** The Tech Lead agent owns planning for all workflow sizes. Plan artifacts are optional Markdown documents. The `task-triage` skill triggers clarification and planning steps. For feature-level work, the OpenSpec change-folder structure (proposal → spec → design → tasks) is available but not mandatory for every task. There is no external planning CLI.

---

## 3. Worktree / Isolation (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| oh-my-pi | `task.isolation.mode=auto` — OMP manages isolated workspaces per subagent |
| superpowers | `finishing-a-development-branch` skill with worktree management |

**Resolution:** OMP task isolation is the sole isolation mechanism. The superpowers branch-finishing skill is rejected. Isolation apply, merge, and commit strategies are controlled by `task.isolation.*` settings in config.yml.

---

## 4. Review Flow (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| superpowers | `requesting-code-review/SKILL.md` + `receiving-code-review/SKILL.md` |
| addyosmani/agent-skills | Multiple review-oriented skills (architecture-health, secure-code-review, etc.) |
| plan DNA | Dedicated Reviewer agent in Orchestrated workflow |

**Resolution:** The Reviewer agent (OMP task) is the primary review mechanism for the Orchestrated workflow. The superpowers requesting/receiving skills are rejected (they dispatch external reviewers; Reviewer agent is a dedicated task agent). Quality-gate criteria from addyosmani are extracted into `template/.omp/policies/quality-gates.yml`; they inform the Reviewer agent's system prompt, not a separate skill.

---

## 5. Specification System (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| spec-kit | Constitution + clarification + spec template + acceptance scenarios |
| OpenSpec | Delta specs (ADDED/MODIFIED/REMOVED) + change folders + archive lifecycle |
| plan DNA | Clarification gate in task-triage skill |

**Resolution:** Spec Kit and OpenSpec are synthesized into one internal specification system. Spec Kit contributes: constitution template, clarification gate, spec template structure (user stories + acceptance scenarios + success criteria). OpenSpec contributes: delta-spec format, change-folder structure, archive lifecycle. The task-triage skill contains the clarification gate trigger. No external CLI (neither `specify` nor `openspec`) is required or installed.

---

## 6. Context Management (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| oh-my-pi | Shake compaction, snapcompact, `compaction.keepRecentTokens`, `compaction.dropUseless` |
| muratcankoylan/ASCE | Context-budget policy, progressive retrieval, filesystem offloading |
| 12-factor-agents | Own your context window, no transcript forwarding |
| superpowers | Context management through subagent design |

**Resolution:** OMP compaction (shake strategy in config baseline) handles runtime context management. The context-budget policy (`template/.omp/policies/context-budget.yml`) documents token targets per component. 12FA "own your context" is an architecture principle, not a runtime layer. Progressive retrieval order is documented in the policy. No conflict: OMP handles the *mechanism*; policy documents the *intent*.

---

## 7. Memory System (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| oh-my-pi | `memory.backend=off`, `autolearn.enabled=false` — memory disabled in baseline |
| ECC | Mnemosyne-style memory backends |
| muratcankoylan/ASCE | Autonomous memory patterns |

**Resolution:** Memory is off per the config baseline. All memory and autolearn features are rejected for v0. Memory may be evaluated in a future phase only after benchmark evidence that it improves accepted outcomes without security degradation.

---

## 8. Duplicate Persistent Instructions (CONFLICT)

**Risk:** Multiple AGENTS.md / RULES.md / CLAUDE.md files + multiple agent system prompts that all repeat the same coding principles.

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| andrej-karpathy-skills | CLAUDE.md with coding principles |
| spec-kit | Constitution in AGENTS.md |
| 12-factor-agents | Architecture principles in system prompts |
| plan DNA | Coding constitution section in AGENTS.md |
| agents.md | AGENTS.md structural patterns |

**Resolution:** Coding constitution lives in **one place only**: `template/.omp/AGENTS.md` (project-level). Individual agent system prompts reference only agent-specific responsibilities. No agent repeats the full coding constitution. RULES.md holds only short critical invariants not covered by AGENTS.md. Zero duplication across agent definitions.

---

## 9. Git Workflow (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| superpowers | `finishing-a-development-branch` — specific git branch and PR flow |
| oh-my-pi | Task isolation commits, merge strategy (`task.isolation.merge=patch`) |

**Resolution:** OMP task isolation manages git commits (generic commit messages per baseline). The superpowers finishing skill is rejected. Git workflow beyond isolation is the user's responsibility; the template does not enforce a branch strategy.

---

## 10. Model Routing (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| oh-my-pi | `modelRoles.<role>` in config.yml — role-based routing through OmniRoute |
| ECC | Token/context profiles, model routing rules |
| addyosmani/agent-skills | Model selection criteria embedded in skills |

**Resolution:** OMP model roles via OmniRoute is the sole routing mechanism. ECC routing patterns are translated into `template/.omp/policies/model-routing.yml` as documentation only. Agents reference role aliases (`@tech-lead`, `@explorer`, etc.); the role → model mapping is a single config.yml file the user maintains.

---

## 11. Evaluation Infrastructure (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| promptfoo | External evaluation tool with assertions, A/B, regression |
| oh-my-pi | No built-in eval framework |
| plan DNA | Local deterministic scripts + optional promptfoo |

**Resolution:** Evaluation uses local deterministic scripts (`scripts/benchmark.ps1`, `scripts/validate-template.ps1`) as primary. Promptfoo is an optional external tool for model-graded evaluation only. No eval framework is bundled or required.

---

## 12. TDD Workflow (CONFLICT)

**Competing mechanisms:**

| Source | Mechanism |
|--------|-----------|
| superpowers | `test-driven-development/SKILL.md` — full TDD skill |
| andrej-karpathy-skills | "Fix the bug → write test that reproduces it" principle |
| addyosmani/agent-skills | Testing patterns in implementation discipline |

**Resolution:** TDD is adopted as a **risk-based principle** (not an always-on skill). The `systematic-debugging` skill references TDD for bug fixes. The implementation discipline in AGENTS.md includes risk-based TDD. No separate TDD skill in v0 (avoids duplicating the principle).

---

## Summary

| Conflict Area | Resolution | Authority |
|---------------|-----------|-----------|
| Subagent orchestration | OMP task subsystem only | oh-my-pi |
| Planning engine | Tech Lead agent + optional OpenSpec artifacts | plan DNA |
| Worktree/isolation | OMP task.isolation only | oh-my-pi |
| Review flow | Reviewer agent (Orchestrated only) + quality-gates.yml | plan DNA |
| Specification system | Spec Kit + OpenSpec synthesized; no external CLI | plan DNA |
| Context management | OMP compaction + context-budget policy | oh-my-pi + muratcankoylan |
| Memory system | Off (memory.backend=off) | oh-my-pi baseline |
| Duplicate instructions | Coding constitution in AGENTS.md only | plan DNA |
| Git workflow | OMP task isolation commits | oh-my-pi |
| Model routing | OMP modelRoles + OmniRoute | oh-my-pi |
| Evaluation | Local scripts + optional promptfoo | plan DNA |
| TDD | Risk-based principle in AGENTS.md, not separate skill | plan DNA |
