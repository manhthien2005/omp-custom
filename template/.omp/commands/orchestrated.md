# Orchestrated Workflow
<!-- Use when: cross-module, architecture change, multiple independent workstreams, or high-risk (API/security/migration) -->
<!-- Flow: parallel-exploration → architecture-review → dependency-graph → isolated-impl → verification → independent-review → integration → evidence-report -->

## When to use

- Task crosses module boundaries
- Architecture or API surface changes
- Multiple independent implementation workstreams exist
- Security, migration, or compatibility risk is present
- Parallel exploration would materially reduce total wall time

## Flow

```
parallel scoped exploration
  → architecture / specification review
  → dependency-aware task graph
  → isolated implementation (parallel where independent)
  → verification
  → independent review
  → integration validation
  → final evidence report
```

**Step 1 — Parallel scoped exploration**
Dispatch multiple Explorer agents in parallel, each scoped to a distinct subsystem.
Each Explorer returns ranked evidence for its scope.
Do NOT duplicate analysis across Explorers.

**Step 2 — Architecture / specification review**
Synthesize exploration findings. Produce:
- A mini-spec with acceptance criteria
- A risk assessment (security, API, migration, performance)
- Identification of independent vs. dependent workstreams
- Quality gates to enable (from `policy:quality-gates`)

If the architecture requires violating any constraint in AGENTS.md or RULES.md, stop and present the conflict to the user before proceeding.

**Step 3 — Dependency-aware task graph**
Build an explicit task graph:
- List each implementation unit
- Mark dependencies between units
- Identify which units can execute in parallel

**Step 4 — Isolated implementation**
For each independent unit: dispatch Implementer with an isolated task packet.
For dependent units: sequence after their dependencies complete.
Each Implementer runs inspect → edit → verify → compact within its isolated scope.

**Step 5 — Verification**
Dispatch Verifier after all implementation units complete.
Verifier runs fresh integration verification (not per-unit tests only).
Returns: decision, per-criterion evidence, failures.

**Step 6 — Independent review**
Dispatch Reviewer with the full diff (all changed files).
Enable applicable quality gates based on risk assessment:
- API change → API compatibility gate
- Security-touching → security gate
- Public interface change → breaking-change gate
- Infrastructure change → release/rollback readiness gate

**Step 7 — Integration validation**
If multiple workstreams were implemented: run integration tests across workstream boundaries.
If only one workstream: skip unless the task packet specifies integration tests.

**Step 8 — Final evidence report**
Compile: objective, task graph, files changed, acceptance criteria results, verification evidence, review findings, integration results, unresolved risks.

## Agent dispatch

| Step | Agents | Parallel? |
|------|--------|-----------|
| Exploration | Multiple Explorers | Yes (scoped) |
| Implementation | Multiple Implementers | Yes (independent units) |
| Verification | One Verifier | No (after all impl) |
| Review | One Reviewer | No (after verification) |
| Integration | Inline | No |

## Parallelism rules

- Parallelize ONLY genuinely independent work.
- Do not create multiple agents to repeat the same analysis.
- Respect `task.maxConcurrency` from config baseline (default: 4).
