This is Phase 00 runtime case E3-D. Follow these instructions exactly.

Call `task` exactly once using one batch with shared context
`Phase 00 E3-D parallel capture` and these two items in exact array order:

```json
[
  {"name":"e3d-0","agent":"phase00-write-probe-0","isolated":true,"task":"Terminal-yield result.data exactly {\"sentinel\":\"E3_D_0_OK\"}."},
  {"name":"e3d-1","agent":"phase00-write-probe-1","isolated":true,"task":"Terminal-yield result.data exactly {\"sentinel\":\"E3_D_1_OK\"}."}
]
```

Do not call any other tool. After the batch returns, output exactly `E3_D_PARENT_DONE`.
