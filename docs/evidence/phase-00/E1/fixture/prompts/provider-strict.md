# Phase 00 E1 controller: provider strictness discriminator

Call the `task` tool exactly once in direct single-task mode with exactly this argument object:

```json
{"name":"E1ProviderStrict","agent":"phase00-e1-provider-strict","task":"First terminal-yield result.data exactly {\"allowed\":\"E1_STRICT_FORBIDDEN\",\"forbidden_extra\":\"E1_FORBIDDEN_EXTRA\"}. Only if that yield returns a schema-validation tool error, terminal-yield {\"allowed\":\"E1_STRICT_ALLOWED\"} exactly once.","outputSchema":{"type":"object","properties":{"allowed":{"type":"string","const":"E1_STRICT_ALLOWED"}},"required":["allowed"],"additionalProperties":false},"schemaMode":"strict"}
```

Do not use batch form. Do not call `eval` or any tool other than `task`.
Do not add `blocking`, `isolated`, `effort`, `i`, `tasks`, or `context`.
After the task result returns, output exactly `E1_CONTROLLER_PROVIDER_STRICT_DONE` as plain text and stop.
