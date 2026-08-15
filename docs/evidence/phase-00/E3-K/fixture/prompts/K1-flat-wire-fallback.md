This is Phase 00 runtime case K1. You must characterize the model-facing `task`
tool wire before any task dispatch.

First, inspect only the `task` tool schema visible to you in this request. Do not
read files or query configuration. Call `bash` once to emit one compact JSON object
with exactly these fields:

- `probe`: `phase00-task-wire-v1`
- `top_level_keys`: the actual top-level property names visible in the task tool
  input schema, sorted alphabetically
- `has_task`: whether top-level `task` is visible
- `has_tasks`: whether top-level `tasks` is visible
- `has_context`: whether top-level `context` is visible
- `decision`: `SEQUENTIAL_FALLBACK` only when `task` is visible and both `tasks`
  and `context` are absent; otherwise `UNEXPECTED_BATCH_WIRE`

Use a PowerShell `Write-Output` command for that attestation. This bash call must
complete before any task call.

If the decision is `SEQUENTIAL_FALLBACK`, perform the following two logical work
items as two separate task calls in order. Do not attempt a `tasks` array. Each call
must use agent `phase00-blocking-probe` and the stated name.

Call 1, name `flat-0`, assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(3);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':0,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

Wait for call 1 to return before issuing call 2.

Call 2, name `flat-1`, assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(3);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':1,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

If the decision is not `SEQUENTIAL_FALLBACK`, do not dispatch. Do not call any
other tool. End with `K1_PARENT_DONE` plus the decision.
