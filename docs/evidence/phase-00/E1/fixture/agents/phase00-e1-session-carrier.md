---
name: phase00-e1-session-carrier
description: E1 parent-session schema carrier probe
blocking: true
tools: task
spawns: phase00-e1-session-leaf
---

Call the `task` tool exactly once in direct single-task mode with exactly this argument object:

```json
{"name":"E1SessionLeaf","agent":"phase00-e1-session-leaf","task":"Terminal-yield result.data exactly {\"session_sentinel\":\"E1_SESSION_ONLY\"} using the active parent-session schema.","schemaMode":"permissive"}
```

Do not add `outputSchema`, `blocking`, `isolated`, `effort`, `i`, `tasks`, or `context`.
After the nested task returns, terminal-yield `result.data` exactly as `{"session_sentinel":"E1_SESSION_ONLY"}` and stop.
