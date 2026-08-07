# Standard Workflow
<!-- Use when: multiple files involved, behavior changes, root cause unclear, tests need attention -->
<!-- Flow: triage → exploration → mini-spec → plan → implementation → verification → focused-review → summary -->

## When to use

- Multiple files or modules may be affected
- Behavior change or new feature
- Root cause is not immediately clear (requires investigation)
- Tests or API compatibility need attention

## When NOT to use

- Narrow, low-risk, single-file change (use Quick)
- Architecture change, cross-module impact, or high security/migration risk (use Orchestrated)

## Flow

```
triage → exploration → mini-spec → plan → implementation → verification → focused-review → summary
```

**Step 1 — Triage**
Invoke `task-triage` skill. Confirm scope, risk, and whether Standard is the right size.
Identify open ambiguities and resolve before proceeding.

**Step 2 — Exploration (Explorer agent)**
Dispatch Explorer with task packet. Explorer returns:
- Relevant files and symbols
- Existing tests and conventions
- Architecture constraints
- Ranked evidence for planning

**Step 3 — Mini-spec**
Write a compact mini-spec (inline, not a full document):
- What will change (behavior contract, not implementation)
- 2–5 acceptance criteria in Given/When/Then format
- Out-of-scope declaration
- Risk level

**Step 4 — Plan**
List implementation steps with verification checkpoints. No more than 5–7 steps for Standard workflow.

**Step 5 — Implementation (Implementer agent)**
Dispatch Implementer with task packet derived from exploration results and mini-spec.
Implementer runs inspect → edit → verify → compact loop.

**Step 6 — Verification (Verifier agent)**
Dispatch Verifier with task packet. Verifier runs fresh, independent verification.
If FAIL: return result to Implementer or report unresolvable issue.

**Step 7 — Focused Review (Reviewer agent, optional)**
Enable when: API change, security-touching code, new public interface, or high-complexity diff.
Skip for: internal-only changes with no API surface, passing all criteria with low risk.

**Step 8 — Summary**
Report: objective, files changed, acceptance criteria results, verification evidence, unresolved items.

## Agent dispatch

| Step | Agent | Required |
|------|-------|---------|
| Exploration | Explorer | Yes |
| Implementation | Implementer | Yes |
| Verification | Verifier | Yes |
| Review | Reviewer | Risk-based |
