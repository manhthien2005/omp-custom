Execute the reviewed Phase 00 E3-I Session A procedure exactly. This is sequential
characterization only. Do not batch or parallelize calls. Do not retry, substitute IDs,
skip calls, add diagnostics, read source/config files, or edit configuration directly.

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
    "name": "e3i-project-1",
    "agent": "phase00-e3i-canary",
    "task": "Submit the exact acknowledgement required by your agent contract through its required terminal yield. Do not call any other tool.",
    "isolated": true
  }]
}
```

The three names are `e3i-project-1`, `e3i-project-2`, and `e3i-project-3`.

4. Call `phase00_e3i_override_apply_true` once with exactly `{}`.

5. Call `phase00_e3l_read_apply` once with exactly `{}`.

6. Call `bash` once with the exact same argument object from step 2.

7. Call `task` three separate times using the exact unit shape from step 3, in this exact
order: `e3i-runtime-1`, `e3i-runtime-2`, and `e3i-runtime-3`.

8. Make no other tool call and finish with exactly `E3I_SESSION_A_DONE`.
