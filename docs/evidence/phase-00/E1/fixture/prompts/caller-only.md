# Phase 00 E1 controller: caller-only schema

Call the `task` tool exactly once in direct single-task mode with exactly this argument object:

```json
{"name":"E1CallerOnly","agent":"phase00-e1-caller-only","task":"Terminal-yield result.data exactly {\"sentinel\":\"E1_CALLER_ONLY\"} using the active caller schema.","outputSchema":{"type":"object","properties":{"sentinel":{"type":"string","const":"E1_CALLER_ONLY"}},"required":["sentinel"],"additionalProperties":false},"schemaMode":"permissive"}
```

Do not use batch form. Do not call `eval` or any tool other than `task`.
Do not add `blocking`, `isolated`, `effort`, `i`, `tasks`, or `context`.
After the task result returns, output exactly `E1_CONTROLLER_CALLER_ONLY_DONE` as plain text and stop.
