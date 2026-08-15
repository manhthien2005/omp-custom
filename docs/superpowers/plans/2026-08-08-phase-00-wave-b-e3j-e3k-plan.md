# Phase 00 Wave B Plan: E3-J and E3-K Runtime Characterization

> Status: approved for inline execution by the user on 2026-08-08. This plan
> implements the already-approved Phase 00 execution-evidence design. It does not
> enable template parallelism or modify the live OMP home.

## Goal

Produce reproducible, sanitized runtime evidence for the two highest-priority task
semantics gates:

- **E3-J:** prove or falsify the async blocking barrier, input-order result merge,
  preserved concurrency, the missing-`blocking` control, and the Verifier/Reviewer
  stage barriers.
- **E3-K:** prove or falsify that `task.batch: false` exposes the flat single-spawn
  model wire and gives a pre-dispatch signal that the parallel path must fall back
  to sequential dispatch.

E3-K has a manifest dependency on E3-J. Its runtime case must not start unless E3-J
has a valid PASS artifact.

## Safety Boundaries

1. Treat `C:/Users/MrThien/.omp/agent` as read-only.
2. Read existing provider authentication and global settings only through normal OMP
   startup. Do not copy, print, hash, or persist credentials.
3. Run every case in a unique disposable fixture root under the system temporary
   directory and force session storage into that root with `--session-dir`.
4. Load experiment settings through a process-local `--config` overlay.
5. Disable extension, skill, rule, LSP, and title discovery for the probe process so
   the recorded behavior has the smallest practical surface.
6. Preserve only sanitized stdout/stderr, command metadata, derived observations,
   source anchors, and fixture inputs. Remove the exact disposable root after the
   evidence has been captured.
7. Do not stage, commit, switch branches, push, or create a pull request.
8. Do not mark a case PASS from source inference. Source anchors explain an observed
   result but cannot replace the runtime observation required by the phase spec.

## Durable Files

### Runtime fixtures

- `docs/evidence/phase-00/E3-J/fixture/.omp/agents/phase00-blocking-probe.md`
- `docs/evidence/phase-00/E3-J/fixture/.omp/agents/phase00-background-probe.md`
- `docs/evidence/phase-00/E3-J/fixture/config.yml`
- `docs/evidence/phase-00/E3-J/fixture/prompts/J1-blocking-batch.md`
- `docs/evidence/phase-00/E3-J/fixture/prompts/J2-missing-blocking-control.md`
- `docs/evidence/phase-00/E3-J/fixture/prompts/J3-stage-barriers.md`
- `docs/evidence/phase-00/E3-K/fixture/.omp/agents/phase00-blocking-probe.md`
- `docs/evidence/phase-00/E3-K/fixture/config.yml`
- `docs/evidence/phase-00/E3-K/fixture/prompts/K1-flat-wire-fallback.md`

### Harness and validation

- `scripts/lib/phase00-runtime-evidence.ps1`
- `scripts/run-phase00-e3j-e3k.ps1`
- `scripts/tests/phase00-e3j-e3k.Tests.ps1`
- `scripts/validate-template.ps1`

### Generated evidence

- `docs/evidence/phase-00/E3-J/J1.yml`
- `docs/evidence/phase-00/E3-J/J2.yml`
- `docs/evidence/phase-00/E3-J/J3.yml`
- `docs/evidence/phase-00/E3-J/conclusion.yml`
- `docs/evidence/phase-00/E3-J/raw/J1.stdout.jsonl`
- `docs/evidence/phase-00/E3-J/raw/J1.stderr.txt`
- `docs/evidence/phase-00/E3-J/raw/J2.stdout.jsonl`
- `docs/evidence/phase-00/E3-J/raw/J2.stderr.txt`
- `docs/evidence/phase-00/E3-J/raw/J3.stdout.jsonl`
- `docs/evidence/phase-00/E3-J/raw/J3.stderr.txt`
- `docs/evidence/phase-00/E3-K/K1.yml`
- `docs/evidence/phase-00/E3-K/conclusion.yml`
- `docs/evidence/phase-00/E3-K/raw/K1.stdout.jsonl`
- `docs/evidence/phase-00/E3-K/raw/K1.stderr.txt`

If a process cannot start or the provider/runtime is unavailable, create the same
case record with `BLOCKED_ENVIRONMENT` and retain the exact sanitized diagnostic.
Never fabricate a missing raw artifact.

## Case Matrix and Acceptance Predicates

| Case | Runtime setup | Required direct observations | PASS predicate |
| --- | --- | --- | --- |
| J1 | `async.enabled=true`, `task.batch=true`, `task.maxConcurrency=3`, three `blocking:true` isolated probes | one batch task call; three settled results; result indexes `[0,1,2]`; timing payloads identify completion order `[2,0,1]`; at least two worker intervals overlap; task tool end occurs after every worker end | every observation is present and no spawn failed |
| J2 | same, but item 2 uses an agent with no `blocking` key | task response contains background-spawn text; inline `details.results` omits index 2; progress/async details identify the detached item; parent does not wait for or consume it before final response | missing-item control is discriminating and the process log is complete enough to prove the task-return boundary |
| J3 | `async.enabled=true`; blocking Verifier then blocking Reviewer | Verifier task starts and ends before Reviewer task starts; Reviewer task ends before the parent's final report starts; each child includes a non-zero timed delay | both stage barriers are visible in event order and timestamps |
| K1 | `task.batch=false`, `task.isolation.mode=none` | before the first task dispatch, parent emits a schema attestation from its model-visible tool surface; attestation says `task` exists and `tasks`/`context` do not; every actual task call is flat; two logical work items are dispatched in two sequential calls | preflight occurs before dispatch, no `tasks` array appears in task arguments, and call 2 starts only after call 1 ends |

### Timing rules

- Probe workers emit compact JSON containing `index`, `started_at_ms`, and
  `ended_at_ms` from one shell process around a controlled sleep.
- J1 sleep durations are intentionally separated to target completion order
  `[2,0,1]`. The result is judged from observed end timestamps, not requested
  durations.
- Two intervals overlap when `max(start_a,start_b) < min(end_a,end_b)`.
- Tool call boundaries come from the OMP JSON event stream; they are not inferred
  from the parent's prose.

## Source Anchors Used for Interpretation

Pinned OMP SHA: `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.

- `packages/coding-agent/src/task/types.ts:getTaskSchema` — dynamic batch/flat wire.
- `packages/coding-agent/src/task/index.ts:validateShapeParams` — batch fields are
  rejected when `task.batch` is disabled.
- `packages/coding-agent/src/task/index.ts:#execute` — per-item `blocking` split.
- `packages/coding-agent/src/task/index.ts:#runSyncSpawns` — concurrent inline fan-out.
- `packages/coding-agent/src/task/index.ts:mergeSyncPayloads` — input-index merge.
- `packages/coding-agent/src/modes/print-mode.ts:printableEvent` — JSON event stream.
- `packages/coding-agent/src/config/settings-schema.ts` — relevant defaults and types.

Line numbers recorded in the case artifacts are observational conveniences; symbols
and the pinned commit are the stable authority.

## Execution Tasks

### Task 1: Lock fixture and parser contracts with RED tests

- [x] Create tests for fixture frontmatter, process-local config, command safety, JSONL
  parsing, task event extraction, timing payload extraction, overlap calculation,
  order calculation, preflight-before-dispatch, and secret/path sanitization.
- [x] Add negative controls for truncated JSONL, missing result indexes, forged prose
  without task details, non-overlapping intervals, a K1 `tasks` argument, and a
  preflight emitted after dispatch.
- [x] Run the focused suite and record the expected RED failures before production
  helper/runner implementation.

### Task 2: Implement the runtime evidence helper

- [x] Parse one JSON object per non-empty stdout line and fail closed on malformed or
  truncated lines.
- [x] Extract task tool calls, updates, ends, result details, and parent final-message
  boundaries without trusting free-form summaries where structured details exist.
- [x] Extract only probe JSON bearing the expected discriminator and index.
- [x] Calculate completion order, stable result order, overlap pairs, and stage-call
  order.
- [x] Redact the exact disposable root and repository root; reject known credential
  key names if any survive sanitization.
- [x] Return explicit case status plus reasons. Missing evidence yields `INVALID_RUN`,
  never PASS.

### Task 3: Implement fixtures and the disposable runner

- [x] Create minimal custom agents. The blocking definition has `blocking: true`; the
  control definition is byte-equivalent except for that key and its description/name.
- [x] Make each probe execute exactly one supplied timing command and yield its exact
  compact JSON result.
- [x] Create separate E3-J and E3-K overlays with every relevant setting explicit.
- [x] Copy fixture inputs to a unique temp root, initialize a disposable Git repository
  for isolated J cases, and create one fixture-only baseline commit.
- [x] Invoke installed OMP `17.2.10` with the pinned runtime model, JSON print mode,
  forced temp session directory, explicit overlay, auto approval, and discovery
  reductions from the safety boundary.
- [x] Capture exit code/stdout/stderr/timestamps, sanitize them, and always clean only
  the verified disposable root.

### Task 4: Reach focused GREEN without a provider call

- [x] Run the parser/analyzer suite against synthetic JSONL fixtures.
- [x] Run it in PowerShell 7 and Windows PowerShell 5.1.
- [x] Confirm all negative controls fail with stable reason codes.
- [x] Run static checks for syntax, unsafe live-home write targets, placeholders,
  trailing whitespace, and accidental secrets.

### Task 5: Execute and adjudicate E3-J

- [x] Transition only E3-J `READY -> RUNNING` immediately before the first real run.
- [x] Run J1. If its runtime evidence is invalid, repair the harness and rerun under a
  new attempt directory; never overwrite the failed attempt without preserving it.
- [x] Run J2 only after J1 produces analyzable evidence.
- [x] Run J3 only after J2 produces analyzable evidence.
- [x] Create the J1-J3 records and E3-J conclusion. A FAIL is retained as a valid
  experiment result; `BLOCKED_ENVIRONMENT` is used only for an external capability
  block; incomplete evidence is `INVALID_RUN` and has no gate power.
- [x] Transition E3-J to PASS only if every predicate in the matrix holds. Otherwise
  set the appropriate non-PASS manifest state/decision and leave E3-K unstarted.

The initial environment block and all invalid attempts remain preserved. After the
user re-authenticated the Codex connection, J1 attempt 6, J2 attempt 1, and J3
attempt 2 independently satisfied every predicate. E3-J is therefore PASS; the
earlier blocked conclusion was replaced only after complete durable case records
and focused GREEN tests existed.

### Task 6: Execute and adjudicate E3-K only after E3-J PASS

- [x] Transition E3-K `NOT_STARTED -> READY -> RUNNING` after E3-J PASS is durable.
- [x] Run K1 and analyze the structured task arguments plus event ordering.
- [x] Create K1 and conclusion records.
- [x] Transition E3-K to PASS only if the flat-wire and sequential-fallback predicates
  all hold; otherwise preserve the observed non-PASS result.

### Task 7: Integrate artifact validation

- [x] Extend `scripts/lib/phase00-evidence.ps1` only if the common artifact contract
  cannot be validated cleanly from the runtime helper; avoid a second repository
  validation engine.
- [x] Reuse the existing `scripts/validate-template.ps1` integration to require and validate E3-J/E3-K records
  only when their manifest states require artifacts.
- [x] Add positive and negative integration tests.
- [x] Run focused tests, Wave A tests, and the full validator in both PowerShell
  environments.

### Task 8: Evidence and peer-review closure for this slice

- [x] Run `git diff --check`, inspect `git status --short`, confirm staged count zero,
  confirm the pinned upstream clone remains clean, and compare live OMP-home status
  against the frozen baseline without reading credential contents.
- [x] Hash every created/modified durable file.
- [x] Append an English Opus-facing changelog entry with exact files, anchors,
  before/after hashes, commands, outcomes, limitations, reruns, and review questions.
- [x] Mark only evidence-backed plan checkboxes.
- [x] State E3-J/E3-K status without claiming Phase 00 or peer closure.

## Stop Conditions

- If installed OMP is not exactly `17.2.10`, stop the runtime case and record the
  mismatch; do not reinterpret another version as the pinned surface.
- If the provider/model is unavailable, preserve the diagnostic and record
  `BLOCKED_ENVIRONMENT`.
- If the disposable path cannot be proven outside the repository and live OMP home,
  do not run cleanup or the experiment.
- If J1-J3 do not collectively PASS, do not execute E3-K because its manifest
  dependency is unsatisfied.
- If raw output contains a credential-shaped value, quarantine it outside the
  repository, record `INVALID_RUN`, improve sanitization, and rerun.

## Closure Boundary

Completing this plan can close E3-J and E3-K only. It cannot enable parallel v0:
E3-L and the guarded-dispatch gate E3-M remain authoritative for that decision, and
the manifest root must remain `parallel_mode: DISABLED`.

## Harness Checkpoint (before provider execution)

```yaml
tdd_red:
  powershell: 7.6.4
  total: 24
  passed: 0
  failed: 24
intermediate_debugging:
  first_green_attempt: {total: 24, passed: 8, failed: 16}
  second_green_attempt: {total: 24, passed: 12, failed: 12}
  third_green_attempt: {total: 24, passed: 19, failed: 5}
  root_causes:
    - PowerShell automatic variable Args shadowed a synthetic-event helper parameter
    - Pester 3 Should Throw did not reliably observe these function exceptions
  corrections:
    - renamed the helper parameter to InputArgs
    - replaced Should Throw with an explicit try/catch boolean assertion
final_green:
  pwsh_7_6_4: {total: 26, passed: 26, failed: 0}
  windows_powershell_5_1: {total: 26, passed: 26, failed: 0}
static:
  ast_parse_errors_pwsh: 0
  ast_parse_errors_windows_powershell: 0
  placeholders: 0
  trailing_whitespace: 0
  git_diff_check: PASS
runtime_provider_calls: 0
```

## Runtime and Post-Run Checkpoint

```yaml
runtime_attempts:
  - attempt: 1
    status: BLOCKED_ENVIRONMENT_WITH_FAILED_SAFETY_BOUNDARY
    process_exit_code: 0
    task_events: 0
    provider_result: connection failure before parent task dispatch
    live_home_metadata:
      before_file_count: 14
      after_file_count: 14
      changed_count: 3
      changed_paths: [agent.db-shm, agent.db-wal, models.db]
    contract_power: NONE
  - attempt: 2
    status: BLOCKED_ENVIRONMENT
    process_exit_code: 1
    task_events: 0
    provider_result: isolated agent home had no model catalog
    live_home_changed_count: 0
    cleanup_succeeded: true
  - attempt: 3
    status: BLOCKED_ENVIRONMENT
    process_exit_code: 0
    task_events: 0
    provider_result: 404 No active credentials for provider codex
    classifier_reason: P00-RUNTIME-PROVIDER-AUTH
    live_home_changed_count: 0
    cleanup_succeeded: true
adjudication:
  E3-J: BLOCKED_ENVIRONMENT
  J1: BLOCKED_ENVIRONMENT
  J2: NOT_RUN_SHARED_ENVIRONMENT_BLOCK
  J3: NOT_RUN_SHARED_ENVIRONMENT_BLOCK
  E3-K: NOT_STARTED
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
  runtime_semantics_conclusions_authorized: 0
post_runtime_tdd:
  hardening_red_1: {total: 28, passed: 25, failed: 3}
  hardening_green_1: {total: 28, passed: 28, failed: 0}
  cleanup_sanitizer_red: {total: 30, passed: 28, failed: 2}
  cleanup_sanitizer_green: {total: 30, passed: 30, failed: 0}
  model_catalog_red: {total: 31, passed: 30, failed: 1}
  model_catalog_green: {total: 31, passed: 31, failed: 0}
  blocked_artifact_red: {wave_a_total: 26, passed: 25, failed: 1}
  reproducible_live_home_metadata_red: {runtime_total: 33, passed: 32, failed: 1}
final_verification:
  pwsh_7_6_4:
    wave_a: {total: 26, passed: 26, failed: 0}
    runtime: {total: 33, passed: 33, failed: 0}
    repository_validator: {passed: 89, warnings: 0, failed: 0}
  windows_powershell_5_1:
    wave_a: {total: 26, passed: 26, failed: 0}
    runtime: {total: 33, passed: 33, failed: 0}
    repository_validator: {passed: 89, warnings: 0, failed: 0}
  ast_parse_errors_pwsh: 0
  ast_parse_errors_windows_powershell: 0
  yaml_secondary_parse_errors: 0
  json_parse_errors: 0
  jsonl_parse_errors: 0
  trailing_whitespace_hits: 0
  incomplete_marker_hits: 0
  suspicious_secret_value_hits: 0
  git_diff_check: PASS
  staged_files: 0
  pinned_clone_dirty_entries: 0
  remaining_disposable_roots: 0
peer_review: PENDING_OPUS_QUOTA
phase_00_status: IN_PROGRESS
```

The first attempt proved that forcing only `--session-dir` was insufficient to keep
the inherited live agent home read-only. The runner now forces
`PI_CODING_AGENT_DIR` to a separate disposable directory, copies a reviewed
non-secret model catalog there, automatically fingerprints live-home file metadata
before and after each attempt, and invalidates any future run that changes that
metadata. It never reads or hashes live credential contents.

### Resume attempt after user-reported login

```yaml
timestamp: 2026-08-08T23:43:00+07:00
preflight:
  omp_version: 17.2.10
  omniroute_port_20128: reachable
  focused_runtime_tests: {total: 33, passed: 33, failed: 0}
  attempt_004_preexisted: false
attempt_004:
  process_exit_code: 0
  status: BLOCKED_ENVIRONMENT
  parent_task_start_count: 1
  batch_items: 3
  child_exit_codes: [1, 1, 1]
  child_probe_timing_count: 0
  cleanup_succeeded: true
  live_home_changed_count: 0
gateway_root_cause:
  codex_connection_count: 1
  is_active: true
  test_status: expired
  error_code: "401.0"
  last_error_type: unauthorized
  has_access_token: true
  has_refresh_token: true
adjudication:
  E3-J: BLOCKED_ENVIRONMENT
  J2: NOT_RUN_SHARED_ENVIRONMENT_BLOCK
  J3: NOT_RUN_SHARED_ENVIRONMENT_BLOCK
  E3-K: NOT_STARTED
required_user_action: >-
  In the authenticated OmniRoute dashboard, refresh/re-authenticate the Codex
  connection and run its provider test until the status is active/success.
```

### Successful resume and E3-J/E3-K adjudication

```yaml
gateway_resolution:
  verified_at: 2026-08-08T23:53:21+07:00
  direct_inference: {http_status: 200, response_status: completed}
  final_connection_test_status: active
  credential_values_persisted: false
E3-J:
  J1:
    selected_attempt: 6
    status: PASS
    result_order: [0, 1, 2]
    completion_order: [2, 0, 1]
    overlap_pairs: [0-1, 0-2, 1-2]
  J2:
    selected_attempt: 1
    status: PASS
    inline_result_indexes: [0, 1]
    detached_index: 2
    detached_async_state: running
  J3:
    selected_attempt: 2
    status: PASS
    event_order: [verifier_end, reviewer_start, reviewer_end, final_message]
  adjudication: PASS
E3-K:
  K1:
    selected_attempt: 3
    status: PASS
    attestation_event_index: 177
    task_call_boundaries: [[294, 328], [441, 465]]
    preflight_before_dispatch: true
    sequential_fallback: true
    actual_flat_task_calls: true
  adjudication: PASS
  preserved_attempts:
    - attempt: 1
      original_status: INVALID_RUN
      re_adjudicated_status: PASS
      cause: analyzer parsed a JSON attestation plus wall-time suffix as one document
    - attempt: 2
      status: INVALID_RUN
      cause: server_is_overloaded
tdd_repairs:
  portable_timing_boundary: {red: 33/34, green: 34/34}
  J3_batch_wire_analyzer: {red: 32/34, green: 34/34}
  E3-J_final_artifact_contract: {red: 33/34, green: 34/34}
  K1_line_bounded_attestation_parser: {red: 31/34, green: 34/34}
  E3-K_final_artifact_contract: {red: 34/35, green: 35/35}
final_boundary:
  E3-J: PASS
  E3-K: PASS
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
  phase_00_status: IN_PROGRESS
  peer_review: PENDING_OPUS_QUOTA
fresh_verification:
  pwsh_7_6_4:
    wave_a: {total: 26, passed: 26, failed: 0}
    runtime: {total: 35, passed: 35, failed: 0}
    repository_validator: {passed: 89, warnings: 0, failed: 0}
  windows_powershell_5_1:
    wave_a: {total: 26, passed: 26, failed: 0}
    runtime: {total: 35, passed: 35, failed: 0}
    repository_validator: {passed: 89, warnings: 0, failed: 0}
  parsed: {yaml_documents: 12, run_json_documents: 12, jsonl_objects: 4289, errors: 0}
  ast_errors: {pwsh: 0, windows_powershell_utf8: 0, phase00_parsefile: 0}
  secret_value_hits: 0
  trailing_whitespace_hits: 0
  git_diff_check: PASS
  staged_files: 0
  pinned_clone_dirty_entries: 0
  remaining_disposable_roots: 0
```
