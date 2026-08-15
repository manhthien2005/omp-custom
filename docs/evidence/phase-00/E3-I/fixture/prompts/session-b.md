Execute the reviewed Phase 00 E3-I Session B procedure exactly. This is sequential
characterization only. Do not batch or parallelize calls. Do not retry, substitute IDs,
skip calls, add diagnostics, read source/config files, edit configuration directly, or call
`phase00_e3i_override_apply_true`.

1. Call `phase00_e3l_read_apply` once with exactly `{}`.

2. Call `bash` once with exactly this argument object:

```json
{
  "command": "omp config get task.isolation.apply --json",
  "timeout": 60
}
```

3. Call `task` three separate times, one item per call, in this exact order. Substitute
only the shown `name`; every other field is immutable:

```json
{
  "context": "Phase 00 E3-I sequential behavioral canary",
  "tasks": [{
    "name": "e3i-cli-1",
    "agent": "phase00-e3i-canary",
    "task": "Submit the exact acknowledgement required by your agent contract through its required terminal yield. Do not call any other tool.",
    "isolated": true
  }]
}
```

The three names are `e3i-cli-1`, `e3i-cli-2`, and `e3i-cli-3`.

4. Do not call `phase00_e3i_override_apply_true`.

5. Make no other tool call and finish with exactly `E3I_SESSION_B_DONE`.
