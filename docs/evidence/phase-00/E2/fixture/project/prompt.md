# Phase 00 E2 worker-path probe

Call the `task` tool exactly once in direct single-task mode with exactly this
argument object:

```json
{"name":"E2CustomRole","agent":"phase00-e2-worker","task":"Terminal-yield result.data exactly {\"sentinel\":\"E2_CUSTOM_ROLE_OK\"}."}
```

Do not call any other tool. After the task returns, output exactly
`E2_CONTROLLER_DONE` and stop.
