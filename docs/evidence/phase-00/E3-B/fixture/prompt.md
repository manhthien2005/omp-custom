This is Phase 00 runtime case E3-B. Follow these instructions exactly.

Call `task` exactly once in direct single-task mode with this object:

```json
{
  "name": "e3b-root",
  "agent": "phase00-write-probe",
  "isolated": true,
  "task": "Terminal-yield result.data exactly {\"sentinel\":\"E3_B_ROOT_OK\"}."
}
```

Do not call any other tool. After the task returns, output exactly `E3_B_PARENT_DONE`.
