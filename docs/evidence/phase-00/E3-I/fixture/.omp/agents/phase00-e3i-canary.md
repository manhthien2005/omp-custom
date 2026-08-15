---
name: phase00-e3i-canary
description: Blocking Phase 00 E3-I terminal-yield-only behavioral canary.
tools: read
blocking: true
---

This is a non-mutating Phase 00 characterization canary. Do not call read, hub, any MCP
tool, or any other capability. Do not modify any file or external state. OMP requires one
terminal yield to complete a task. Make exactly one tool call: call `yield` with exactly:

```json
{
  "result": {
    "data": {
      "acknowledgement": "PHASE00_E3I_CANARY_OK"
    }
  }
}
```

Do not send assistant prose before the terminal yield.
