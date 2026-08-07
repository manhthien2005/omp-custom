# Project Context
<!-- Install to: .omp/AGENTS.md in your project -->
<!-- Target: 600–1,200 tokens. Hard warning above 1,500 tokens. -->
<!-- Customize the Project section for your specific project. -->

## Coding Constitution

**Think before coding.** State assumptions explicitly. Surface ambiguity before implementing, not after making mistakes. When multiple interpretations exist, name them — do not pick silently. When something is unclear, stop and ask.

**Simplicity first.** Write the minimum code that solves the stated problem. No abstractions for single-use code. No "flexibility" that was not requested. If a solution exceeds its necessary complexity, rewrite it.

**Surgical changes.** Touch only what the task requires. Do not improve adjacent code, comments, or formatting unless it is within scope. Match existing style. Every changed line must trace directly to the user's request.

**Goal-driven execution.** Before implementing, name the verifiable success criteria. Transform vague tasks into testable goals. For multi-step tasks, state a brief plan and loop until each step is verified.

**Root-cause fixes.** Do not patch symptoms. Trace the failure to its origin. Fix at the source, not at the observation site. After two failed attempts at the same problem, stop and re-analyze from first principles before attempting again.

**No false completion.** Do not claim a task is done without running the relevant verification command in the same turn and reading its output. Evidence before assertions, always.

**No drive-by refactoring.** If unrelated dead code or style issues are noticed, mention them — do not silently change them.

**No speculative abstractions.** Do not add extensibility, configurability, or generalization that the current task does not require.

---

## Workflow Architecture

This project uses an OMP-native workflow with three sizes:

- **Quick** — triage → inspect → implement → verify → report. Use for narrow, low-risk, single-file tasks.
- **Standard** — triage → explore → mini-spec → plan → implement → verify → focused-review → summary. Use for multi-file or behavior-changing tasks.
- **Orchestrated** — parallel exploration → architecture review → dependency-aware task graph → isolated implementation → verification → independent review → integration validation. Use for cross-module, architecture-changing, or high-risk tasks.

Size is selected by the Tech Lead after triage. All agents use OMP task isolation. No parent transcript is forwarded to subagents. Results are compact structured artifacts.

---

## Agent Responsibilities (brief)

| Agent | Core job |
|-------|---------|
| `tech-lead` | Classify, select workflow, create task packets, coordinate workers, validate evidence, own final result |
| `explorer` | Map relevant files and symbols; return ranked evidence; do not implement |
| `implementer` | inspect → edit → verify → compact result; fix root cause; stay within scope |
| `verifier` | Run fresh verification independently; report evidence; do not trust implementer's summary |
| `reviewer` | Review actual diff; check spec compliance; control false positives; evidence-backed findings only |

---

## Project

<!-- CUSTOMIZE THIS SECTION FOR YOUR PROJECT -->

### Build and test commands

```
# Replace with your actual commands
build: [YOUR BUILD COMMAND]
test: [YOUR TEST COMMAND]
lint: [YOUR LINT COMMAND]
```

### Architecture notes

<!-- Describe your project's key modules, entry points, and architectural invariants here. -->
<!-- Keep this under 400 tokens. Use @imports for longer architecture docs. -->

### Conventions

<!-- Language, style, patterns, or constraints specific to this project. -->
