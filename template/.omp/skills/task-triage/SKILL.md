---
name: task-triage
description: >
  Use when an unprefixed request has unclear objective, scope, acceptance criteria, risk, or
  workflow size. Do not use after the user explicitly selects quick, standard, or orchestrated.
---

# Task Triage

## When to activate

**Activate this skill when:**
- The task description is vague or uses undefined terms
- Scope boundaries are not stated (what is in and out of scope)
- Acceptance criteria are missing or untestable
- Multiple valid interpretations exist and they would lead to different implementations
- The risk level or workflow size is unclear

**Do NOT activate when:**
- The task is a clear, specific, single-file bug fix with a stated verification command
- The task description already contains explicit acceptance criteria and scope
- The user has already answered all ambiguities in the same message

---

## Phase 1 — Understand

Read the task. Identify what is stated vs. what is assumed.

List any of these that are missing or unclear:
- **Objective** — what outcome does the user want?
- **Scope** — which files, modules, or systems are in scope?
- **Out-of-scope** — what should NOT change?
- **Acceptance criteria** — how will completion be verified? Are criteria testable?
- **Risk** — does this touch API surfaces, security, migrations, or shared state?

---

## Phase 2 — Clarify (when needed)

If any of the above are missing and cannot be reasonably inferred from the codebase:

1. State what you DO understand clearly.
2. Ask the minimum number of questions needed to proceed. Group all questions in one message.
3. Do not ask about minor implementation details that can be resolved through evidence.
4. Propose your best interpretation alongside the question to reduce round-trips:
   > "I interpret this as [X]. Is that correct, or did you mean [Y]?"

**Do not ask if evidence in the codebase resolves the question.** Check first, then ask only if still unclear.

---

## Phase 3 — Define

Once ambiguities are resolved (by asking or by reading the codebase), produce:

**Mini-spec:**
```
Objective: [one sentence]
Scope: [specific files/modules or "any file touched by X"]
Out-of-scope: [explicit exclusions]
Acceptance criteria:
  1. Given [state], when [action], then [outcome]
  2. ...
Verification command: [exact command to run]
Risk level: LOW | MEDIUM | HIGH
```

---

## Phase 4 — Select workflow size

| Criteria | Workflow |
|----------|---------|
| Single file, clear root cause, low risk, ≤ 2 acceptance criteria | **Quick** |
| Multiple files, behavior change, unclear root cause, tests needed | **Standard** |
| Cross-module, architecture change, API/security/migration risk | **Orchestrated** |

If in doubt between two sizes, select the larger one.

---

## Phase 5 — Confirm and proceed

State:
- Selected workflow: Quick / Standard / Orchestrated
- Mini-spec (objective, scope, acceptance criteria, verification)
- Any remaining risks or open questions

Then proceed with the selected workflow.
