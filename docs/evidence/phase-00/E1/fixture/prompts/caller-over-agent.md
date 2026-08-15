# Phase 00 E1 controller: caller overrides agent

Call the `task` tool exactly once in direct single-task mode with exactly this argument object:

```json
{"name":"E1CallerOverAgent","agent":"phase00-e1-caller-over-agent","task":"Inspect the active terminal schema and terminal-yield only the property and constant it requires; never combine competing schema fields.","outputSchema":{"type":"object","properties":{"caller_sentinel":{"type":"string","const":"E1_CALLER_WINS"}},"required":["caller_sentinel"],"additionalProperties":false},"schemaMode":"permissive"}
```

Do not use batch form. Do not call `eval` or any tool other than `task`.
Do not add `blocking`, `isolated`, `effort`, `i`, `tasks`, or `context`.
After the task result returns, output exactly `E1_CONTROLLER_CALLER_OVER_AGENT_DONE` as plain text and stop.
