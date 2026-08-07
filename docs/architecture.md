# Architecture — OMP Workflow Template v0
<!-- Authoritative architecture document for Workflow v0 -->

## Design constraints

1. OMP is the sole coding-agent runtime and orchestration engine.
2. OmniRoute is the sole model gateway.
3. No second runtime is introduced.
4. No external CLI dependencies are required for core operation.
5. Every adopted mechanism maps to a real OMP capability.
6. Every major component can be removed independently.
7. The template can be customized at project level.

---

## Component overview

```
template/.omp/
├── config.yml          Model role aliases (only; no baseline duplication)
├── AGENTS.md           Persistent project context: coding constitution + workflow overview
├── RULES.md            Sticky critical invariants (re-attached each turn)
│
├── agents/             Custom task agents (OMP-native discovery)
│   ├── tech-lead.md    Workflow coordinator; owns final result
│   ├── explorer.md     Symbol-first codebase investigation
│   ├── implementer.md  Minimal inspect→edit→verify loop
│   ├── verifier.md     Independent fresh verification
│   └── reviewer.md     Evidence-backed code review
│
├── workflows/          Workflow definitions (OMP commands)
│   ├── quick.md        5-step narrow/low-risk flow
│   ├── standard.md     8-step multi-file/behavior-change flow
│   └── orchestrated.md 8-step cross-module/high-risk flow
│
├── skills/             OMP skills (lazy-loaded via skill:// URLs)
│   ├── task-triage/    Clarification gate + workflow sizing
│   ├── systematic-debugging/   4-phase root-cause debugging
│   └── evidence-before-completion/  Verification iron law
│
├── schemas/            Structured result contracts (YAML documentation)
│   ├── task-packet.schema.yml
│   ├── agent-result.schema.yml
│   ├── verification-result.schema.yml
│   └── review-result.schema.yml
│
└── policies/           Operational policies (referenced by agents and skills)
    ├── context-budget.yml     Token targets + retrieval order
    ├── model-routing.yml      Role → model mapping rationale
    ├── workflow-sizing.yml    Quick/Standard/Orchestrated selection criteria
    ├── quality-gates.yml      Risk-based review gate definitions
    └── escalation.yml         When to stop and escalate
```

---

## Agent responsibilities and boundaries

| Agent | Owns | Does not own |
|-------|------|-------------|
| tech-lead | Workflow selection, task packets, result validation, final report | Implementation, verification, code review |
| explorer | File/symbol mapping, evidence ranking | Implementation, planning |
| implementer | Code changes, root-cause fixes, per-unit tests | Verification (independent), review |
| verifier | Independent verification, evidence collection | Implementation, review |
| reviewer | Diff review, spec compliance, risk assessment | Implementation, self-merge |

No two agents share a primary responsibility. Responsibilities do not overlap.

---

## Workflow selection

```
Task arrives
    │
    ▼
task-triage skill (when ambiguous)
    │
    ▼
Tech Lead classifies:
    ├─ Quick     → single file, low risk, clear target
    ├─ Standard  → multi-file, behavior change, unclear root cause
    └─ Orchestrated → cross-module, high risk, architecture change
```

---

## Specification system

This template provides a lightweight optional specification system synthesized from Spec Kit and OpenSpec:

```
For a new change:
  openspec/changes/<name>/
  ├── proposal.md         Why and what (scope, intent, out-of-scope)
  ├── design.md           Technical approach (optional)
  ├── tasks.md            Implementation checklist
  └── specs/              Delta specs
      └── <domain>/
          └── spec.md     ADDED/MODIFIED/REMOVED requirements

Current state of truth:
  openspec/specs/
  └── <domain>/
      └── spec.md         Requirements + Given/When/Then scenarios

When change is complete:
  openspec/changes/archive/<date>-<name>/   # Preserved for history
```

This system is **optional** and requires no external CLI. Files are plain Markdown.

---

## Context flow (no transcript forwarding)

```
User → Tech Lead
         │
         ├─ Task packet (no transcript) → Explorer → agent-result
         ├─ Task packet (no transcript) → Implementer → agent-result
         ├─ Task packet (no transcript) → Verifier → verification-result
         └─ Task packet (no transcript) → Reviewer → review-result
         │
         ▼
       Final report to user
```

Each agent receives only task-relevant context. No agent receives the parent conversation history.

---

## Token budget design

| Layer | Budget | Type |
|-------|--------|------|
| AGENTS.md | 600–1,200 tokens | Persistent |
| RULES.md | 300–700 tokens | Sticky |
| Each agent system prompt | 500–1,200 tokens | Per-subagent |
| Skill descriptions (all) | ~200 tokens total | Persistent list |
| Skill bodies | 800–2,000 each | Lazy (on demand) |
| Task packet | 300–800 tokens | Per-task |
| Worker result | 200–600 tokens | Per-result |

OMP shake compaction handles runtime context management. No persistent memory.

---

## Installation design

```
Template project (this repo)
         │
         ▼
scripts/install-template.ps1
    --dry-run (default)      Show planned changes, no modification
    --target project|user    Install to project .omp/ or user ~/.omp/agent/
    --components [list]      Selective installation
         │
         ▼
Timestamped backup → ~/.omp/agent.backup-<timestamp>/
         │
         ▼
Install selected components
         │
         ▼
scripts/validate-template.ps1    Verify structure + token budgets + secrets
         │
         ▼
OMP config sanity check
```

Rollback: `scripts/uninstall-template.ps1 -BackupDir <path>`
