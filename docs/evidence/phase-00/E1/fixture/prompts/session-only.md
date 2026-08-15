# Phase 00 E1 controller: parent-session fallback

Call the `task` tool exactly once in direct single-task mode with exactly this argument object:

```json
{"name":"E1SessionOnly","agent":"phase00-e1-session-carrier","task":"Call the allowed session leaf exactly once as specified by your role, then terminal-yield result.data exactly {\"session_sentinel\":\"E1_SESSION_ONLY\"}.","outputSchema":{"type":"object","properties":{"session_sentinel":{"type":"string","const":"E1_SESSION_ONLY"}},"required":["session_sentinel"],"additionalProperties":false},"schemaMode":"permissive"}
```

Do not use batch form. Do not call `eval` or any tool other than `task`.
Do not add `blocking`, `isolated`, `effort`, `i`, `tasks`, or `context`.
After the task result returns, output exactly `E1_CONTROLLER_SESSION_ONLY_DONE` as plain text and stop.
