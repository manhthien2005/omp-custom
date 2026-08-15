This is Phase 00 runtime case E3-C. Follow these instructions exactly.

Call `task` exactly once in direct single-task mode with this object:

```json
{
  "name": "e3c-branch",
  "agent": "phase00-write-probe",
  "isolated": true,
  "task": "Terminal-yield result.data exactly {\"sentinel\":\"E3_C_BRANCH_OK\"}."
}
```

Do not call any other tool. After the task returns, output exactly `E3_C_PARENT_DONE`.
