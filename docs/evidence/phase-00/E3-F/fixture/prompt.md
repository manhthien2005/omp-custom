This is Phase 00 runtime case E3-F. Follow these instructions exactly.

Call `task` exactly once using one batch with shared context
`Phase 00 E3-F stop-preserve-report conflict semantics` and these items in exact array order:

```json
[
  {"name":"e3f-0","agent":"phase00-e3f-0","isolated":true,"task":"Terminal-yield result.data exactly {\"sentinel\":\"E3_F_0_OK\"}."},
  {"name":"e3f-1","agent":"phase00-e3f-1","isolated":true,"task":"Terminal-yield result.data exactly {\"sentinel\":\"E3_F_1_OK\"}."},
  {"name":"e3f-2","agent":"phase00-e3f-2","isolated":true,"task":"Terminal-yield result.data exactly {\"sentinel\":\"E3_F_2_OK\"}."}
]
```

Do not call any other tool. After the batch returns, output exactly `E3_F_PARENT_DONE`.
