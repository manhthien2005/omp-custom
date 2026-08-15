This is Phase 00 runtime case A4. Follow the sequence exactly.

First inspect only the model-visible `task` tool schema in this request. For its
batch `tasks` item, derive the actual property names. Call `bash` exactly once.
The command string must begin with `powershell -NoProfile -Command`, and its
PowerShell body must call `Write-Output` once with the derived compact object. This
prevents the brush shell from interpreting `Write-Output` itself. The compact JSON
object contains exactly:

- `probe`: `phase00-task-item-wire-v1`
- `item_keys`: actual item property names sorted alphabetically
- `has_isolated`: whether `isolated` is visible on the item
- `has_apply`: whether `apply` is visible on the item
- `decision`: `RUN_RAW_NON_AUTHORITY_CONTROL` only when `has_isolated` is true
  and `has_apply` is false; otherwise `UNEXPECTED_TASK_ITEM_WIRE`

The bash attestation must finish before the eval call. Do not read source files or
configuration to create the attestation.

If the decision is `RUN_RAW_NON_AUTHORITY_CONTROL`, call JavaScript `eval` exactly
once with exactly this code:

```javascript
await tool.task({
  context: "Phase 00 A4 forced raw apply non-authority control",
  tasks: [{
    name: "a4-apply-probe",
    agent: "phase00-apply-probe",
    task: "Create the exact Phase 00 A4 sentinel required by your agent contract.",
    isolated: true,
    apply: false
  }]
})
```

Do not call the task tool directly. Do not alter, omit, or relocate the raw
`apply:false` field. The eval bridge is a controlled internal-call probe and does
not establish where model-call ArkType deletion occurs.

If the decision is unexpected, do not call eval or task. Do not call any other
tool. End with `A4_PARENT_DONE` and the decision.
