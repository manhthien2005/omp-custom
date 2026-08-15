---
name: evidence-before-completion
description: >
  Use before a Worker returns completed or claims work is fixed, passing, or done. Do not use for
  progress, planning, or an honest partial, blocked, failed, or Cheap Scout result.
---

# Evidence Before Completion

## Rule

```
NO COMPLETION CLAIM WITHOUT FRESH VERIFICATION EVIDENCE IN THIS WORKER SESSION.
```

Before returning `completed`:

1. Read the packet's required verification commands and mandatory acceptance criteria.
2. Run every required command now in this Worker session.
3. Read complete output and exit status; do not infer success from silence.
4. Bind each passed observation to the acceptance criterion it supports.
5. Return `completed` only when all mandatory evidence exists. Otherwise return `partial`,
   `blocked`, or `failed` with the exact gap.

A prior run, another agent's report, code that merely looks correct, or a partial test set is not
fresh proof. Report observations through the Worker result schema. Never accept or close the parent
task; the Tech Lead owns integration and acceptance.
