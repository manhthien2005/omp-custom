This is Phase 00 runtime case E3-E. Follow these instructions exactly.

Call `task` exactly once using one batch with shared context
`Phase 00 E3-E task-index integration order` and these three items in exact
array order:

```json
[
  {"name":"e3e-0","agent":"phase00-e3e-0","isolated":true,"task":"Terminal-yield result.data exactly {\"sentinel\":\"E3_E_0_OK\"}."},
  {"name":"e3e-1","agent":"phase00-e3e-1","isolated":true,"task":"Terminal-yield result.data exactly {\"sentinel\":\"E3_E_1_OK\"}."},
  {"name":"e3e-2","agent":"phase00-e3e-2","isolated":true,"task":"Terminal-yield result.data exactly {\"sentinel\":\"E3_E_2_OK\"}."}
]
```

Do not call any other tool. After the batch returns, output exactly
`E3_E_PARENT_DONE`.
