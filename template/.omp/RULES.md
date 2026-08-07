# OMP Workflow Template — Critical Invariants
# This file is loaded as a STICKY RULE (re-attached near every turn).
# Keep this short. Background and context belong in AGENTS.md.

## Non-negotiable invariants

1. Never claim work is complete without running verification commands and reading the output.
2. Never commit or push unless the user explicitly asks.
3. Never modify files outside the declared task scope without user approval.
4. Never forward a parent conversation transcript to a subagent — pass only task-relevant context.
5. Never modify `~/.omp/agent/` or install files to the live OMP directory without explicit user approval.
6. Never expose secrets, API keys, credentials, or private data in any artifact or context file.
7. When verification fails, report the failure with evidence. Do not retry silently.
8. When a task is ambiguous, state the ambiguity and ask before implementing.
