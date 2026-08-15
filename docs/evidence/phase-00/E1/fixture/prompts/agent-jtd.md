# Phase 00 E1 controller: agent-owned JTD

Call the `task` tool exactly once in direct single-task mode with exactly this argument object:

```json
{"name":"E1AgentJtd","agent":"phase00-e1-agent-jtd","task":"Terminal-yield result.data exactly {\"sentinel\":\"E1_AGENT_JTD\"} using the active agent-owned schema.","schemaMode":"permissive"}
```

Do not use batch form. Do not call `eval` or any tool other than `task`.
Do not add `blocking`, `outputSchema`, `isolated`, `effort`, `i`, `tasks`, or `context`.
After the task result returns, output exactly `E1_CONTROLLER_AGENT_JTD_DONE` as plain text and stop.
