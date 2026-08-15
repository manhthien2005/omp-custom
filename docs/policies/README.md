# Policy Reference

> OMP runtime: not loaded. This directory is human documentation outside the installed
> `.omp/` surface. Runtime behavior lives in the named command, agent, or validator consumer.

Retired source: five legacy YAML inputs, indexed below. These files preserve provenance and
explain the reconciled contracts; they are not an OMP discovery or execution surface.

| Retired source | Disposition | Runtime consumer | Human authority |
|---|---|---|---|
| `context-budget.yml` | REHOMED | AGENTS/worker prompts + advisory validator | `context-budget.md`, `spec/05` |
| `model-routing.yml` | REHOMED_WITH_SUPERSEDED_CLAUSES | Standard/Orchestrated dispatch prose | `model-routing.md`, `spec/09` |
| `workflow-sizing.yml` | REHOMED_WITH_SUPERSEDED_TIE_BREAK | Quick/Standard/Orchestrated | `spec/04` |
| `quality-gates.yml` | REHOMED | Standard/Orchestrated task-packet construction | `quality-gates.md`, `spec/11` |
| `escalation.yml` | REHOMED_BY_OWNER | worker stop clauses + main-session escalation | `spec/04`, `spec/15` |

Workflow sizing has no duplicate reference file: `spec/04-workflow-sizing.md` and the three
commands are authoritative. Escalation likewise has no standalone copy: worker-to-main outcomes
live in worker prompts, while user-authority decisions live in `template/.omp/AGENTS.md` and are
constrained by `spec/04-workflow-sizing.md` and `spec/15-security-and-failure-recovery.md`.

