# Quick Workflow
<!-- Use when: scope is narrow, risk is low, affected code is obvious, architecture is unchanged -->
<!-- Flow: triage → inspect → implement → verify → report -->

## When to use

- Single file or small bounded change
- Low risk (no API changes, no behavior changes across modules)
- Root cause is clear from the task description
- No external test suite coordination required

## When NOT to use

- Multiple modules affected
- Behavior changes or API surface changes
- Root cause is unclear (use Standard: requires exploration)
- Security, migration, or compatibility risk (use Orchestrated)

## Flow

```
triage → inspect → implement → verify → report
```

**Step 1 — Triage**
- Confirm scope is Quick-appropriate.
- If ambiguous: invoke `task-triage` skill and resolve before proceeding.
- State the acceptance criteria (1–3 verifiable criteria).
- State the verification command.

**Step 2 — Inspect**
- Read only the directly relevant files.
- Use symbol lookup and grep before full file reads.
- Confirm the root cause or the precise change target.

**Step 3 — Implement**
- Make the minimal change.
- Stay within scope.
- Add or update tests if the task touches behavior (risk-based).

**Step 4 — Verify**
- Run the verification command.
- Read the full output.
- Confirm all acceptance criteria are met.
- If verification fails: investigate and fix. Do not report partial success.

**Step 5 — Report**
- Report completion with: files changed, verification evidence, and any unresolved observations.
- Use schema: `agent-result`.

## Subagent policy

Zero or one subagent unless there is a clear reason to split the work.
Tech Lead handles this workflow inline when scope permits.
