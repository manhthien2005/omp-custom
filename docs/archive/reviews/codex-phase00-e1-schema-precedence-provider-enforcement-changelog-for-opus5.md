# Codex Phase 00 E1 Schema Precedence and Provider Enforcement Changelog for Opus 5

Date: 2026-08-09 through 2026-08-10<br>
Language: English<br>
Purpose: compact, evidence-linked peer-review handoff<br>
Peer model: Codex and Opus have equal authority; neither can unilaterally create joint closure

## 1. Current checkpoint

```yaml
checkpoint: E1-CALLER-ONLY-INVALID-RUN-006
task: E1
phase: "00"
codex_status: Tasks 1-10 and 10A complete; Task 11 stopped after CallerOnly attempt 1 INVALID_RUN
user_status: CallerOnly attempt 1 authorization consumed; replacement requires a new offline diagnosis/remediation checkpoint and explicit authorization
opus_status: quota unavailable; deferred audit pending
joint_closure: false
implementation_started: true
provider_process_attempts: 4
provider_requests: 22
raw_evidence_files: 20
agent_jtd_attempt_001: INVALID_RUN
agent_jtd_attempt_002: PASS
agent_jtd_case_record: PASS
agent_json_schema_attempt_001: PASS
agent_json_schema_case_record: PASS
caller_only_attempt_001: INVALID_RUN
caller_only_case_record: absent
case_records: 2
next_provider_case: none; the sequential wave is stopped at CallerOnly INVALID_RUN
next_eligible_action: offline CallerOnly sanitizer diagnosis and, if justified, a separately reviewed remediation checkpoint
next_provider_action_authorized: false
manifest_changed: false
template_changed: false
git_branch_changed: false
git_index_staged_paths: 0
parallel_mode: DISABLED
```

E1 remains `READY`, not `PASS`, and directly gates T-00.4; T-00.4, T-00.5, and
T-00.6 remain unstarted. The immutable `AgentJtd` attempt 1 remains `INVALID_RUN`
for the two harness defects described in section 26, while Attempt 2 remains its
authoritative `PASS`. `AgentJsonSchema` attempt 1 and its canonical second matrix
record also remain authoritative `PASS`. After a fresh complete matching preflight,
the separately authorized `CallerOnly` attempt 1 ran exactly once and was captured as
`INVALID_RUN/E1_SANITIZER_PROCESSING_ERROR`. The fail-closed projector refused the
attempt, no CallerOnly case record was created, and the sequential provider wave
stopped before `CallerOverAgent`.

Task 10A reproduced both harness defects from pinned source and synthetic raw shapes,
implemented them test-first, hardened duplicate-content redaction and metadata
validation, and completed the full offline gate as `E1-OFFLINE-GREEN-003`.
AgentJtd Attempt 2 consumed one provider process and seven actual provider requests
with no retry. AgentJsonSchema Attempt 1 consumed one provider process and three
actual provider requests with no retry. CallerOnly Attempt 1 consumed one provider
process and three actual provider requests with no retry before its sanitized stdout
artifact failed integrity processing at source line 6. Both existing canonical case
records remain `PASS`; both invalid historical attempts remain immutable and have no
manifest authority. No conclusion or manifest transition exists. No replacement
attempt or later provider case is currently authorized.

## 2. Codex-owned mutations in this checkpoint

| Path | Operation | Purpose | Current identity |
|---|---|---|---|
| `docs/superpowers/specs/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-design.md` | created, then status-approved | Complete approved E1 experiment design | 551 lines; 25,447 bytes; SHA-256 `4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30` |
| `docs/superpowers/plans/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-plan.md` | created, execution-reviewed, Tasks 1-10 and 10A checked, Task 11 stop/retry boundary recorded | File-by-file, test-first E1 execution plan with provider stop gates | 767 lines; 44,266 bytes; current SHA-256 `C06445019B99F517B77A4324014CC4C979D122CAB389514FF10AEEE05ADF80CF` |
| `scripts/tests/phase00-e1.Tests.ps1` | created, expanded test-first | Focused E1 contracts through the complete offline gate, raw projector, deterministic record derivation, and Attempt 1 harness regressions | 4,049 lines; 201,691 bytes; SHA-256 `FC95A553C1D8EC8CC8F74A1A7FC4B65ABD7E829EE114C1081BF91CD5D315811A` |
| `scripts/lib/phase00-e1-evidence.ps1` | created after verified RED, expanded test-first | Definitions, sanitization, provenance/oracles, fail-closed runner, raw-to-oracle projection, deterministic records, canonical writers, durable artifact validation, and Attempt 1 harness remediation | 6,635 lines; 288,856 bytes; SHA-256 `D75260914484CF155C3E2EE829E95C8C83A2E5FED2768159ED1C8F14FAFC8133` |
| `scripts/lib/phase00-e1-forwarder.mjs` | created after verified RED, expanded test-first | Secret-free deterministic projection and bounded loopback request/response relay | 382 lines; 12,435 bytes; SHA-256 `9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952` |
| `scripts/run-phase00-e1.ps1` | created after runner RED | Exact five-parameter entry point delegating to the evidence runner | 18 lines; 555 bytes; SHA-256 `5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7` |
| `docs/evidence/phase-00/E1/fixture/**` | created after verified RED | Exact offline config, seven blocking agents, and six controller prompts | 14 files; 7,891 bytes; tree SHA-256 `C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B` by the algorithm in section 20.3 |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-001*` and `attempt-002*` | runtime-created once per authorized attempt, now immutable | Preserve the first `INVALID_RUN` and the replacement `PASS` capture without overwrite | 10 files; 249,980 bytes; exact per-file hashes in sections 26.2 and 28.3 |
| `docs/evidence/phase-00/E1/case-1-agent-jtd.yml` | canonical writer-created from Attempt 2 only | First authoritative E1 matrix record | 105 lines; 3,654 bytes; SHA-256 `BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4` |
| `docs/evidence/phase-00/E1/raw/agent-json-schema/attempt-001*` | runtime-created once by the separately authorized process, now immutable | Preserve the first AgentJsonSchema capture without overwrite | 5 files; 62,597 bytes; exact per-file hashes in section 29.5 |
| `docs/evidence/phase-00/E1/case-1-agent-json-schema.yml` | canonical writer-created from AgentJsonSchema Attempt 1 only | Second authoritative E1 matrix record | 105 lines; 3,748 bytes; SHA-256 `56A7270C18EBC4BFEAE0AF1B7A9D98B75B2BD165CD2290CF7126B459BF10C33B` |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-001*` | runtime-created once by the separately authorized process, now immutable | Preserve the `INVALID_RUN` capture without overwrite or canonical projection | 5 files; 66,781 bytes; exact per-file hashes in section 30.6 |
| `scripts/lib/phase00-evidence.ps1` | modified narrowly | Conditionally load the focused E1 helper without breaking legacy copied helpers | 1,877 lines; 94,638 bytes; SHA-256 `403CD78585A4058986B280A07C7F2291488AFD79B3F3C513D6DAA667E6574BE5` |
| `scripts/validate-template.ps1` | modified narrowly | Register `Test-Phase00E1ArtifactContract` immediately after the manifest validator | 280 lines; 10,211 bytes; SHA-256 `45ED1190CDB223C771DE24E6A46AC9E29D062893940BDCA9FFDB6AEB18CF402B` |
| `scripts/tests/phase00-wave-a.Tests.ps1` | modified test-first | Require seven validators, E1 READY output, and legacy helper compatibility | 373 lines; 18,071 bytes; SHA-256 `68A1B58BC599D9FBA3B835412B7E2A86CFA164B5F0935BBCB4154DDF64CC57B4` |
| `docs/evidence/phase-00/T-00.3/conclusion.yml` | destination hash revalidated; prior raw untouched | Preserve T-00.3's strict binding after the authorized validator entrypoint changed | 197 lines; 9,069 bytes; SHA-256 `69A1A7EC648A9CC2CC190DCE3B40E1D7601D184DAD7D490E617A82DC4FD807C9` |
| `codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md` | created | Token-efficient reconstruction and peer-review entry point | self-hash reported externally at each checkpoint because embedding it would change it |

The design's pre-approval identity was 551 lines, 25,445 bytes, SHA-256
`4716F04C8529D0FE56E82FA8D34B95AAB013322273EF9886B5B9EBB8FC8C581E`.
The only design-file delta was its status/implementation-authority header after
explicit user approval.

AgentJtd Attempt 1 created only its five sanitized raw artifacts, and Task 10A did not
rewrite them. AgentJtd Attempt 2 and AgentJsonSchema Attempt 1 each created five new
no-overwrite raw artifacts and one canonical case record. CallerOnly Attempt 1 created
five new no-overwrite sanitized raw artifacts and no case record. No E1 conclusion,
manifest, template, registry, installer, normative spec, branch, or Git index entry
was changed by checkpoint 006.

## 3. Authority and locked environment

```yaml
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_worktree: dirty before this checkpoint; unrelated changes preserved
staged_paths_current: 0
pinned_source:
  path: _research/upstreams/oh-my-pi
  commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  version: 17.2.10
  worktree: clean
normative_runtime:
  version: omp/17.2.10
  sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
  preserved_source: C:/Users/MrThien/AppData/Local/omp/omp.exe.1786250147823.24932.bak
installed_delta:
  path: C:/Users/MrThien/AppData/Local/omp/omp.exe
  version: omp/17.2.12
  authority_for_e1: false
manifest_before_and_after:
  path: docs/evidence/phase-00/manifest.yml
  sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
  e1: READY
  t_00_4: NOT_STARTED
```

Authority order is the Phase 00 E1/T-00.4 spec, the approved Phase 00 evidence
design, pinned source, observed pinned-runtime behavior, then historical template
inputs. Runtime claims cannot close from source inference alone.

## 4. Source facts used by the design

| Fact | Pinned source anchor |
|---|---|
| schema precedence is caller presence > agent output > session output > none | `packages/coding-agent/src/task/structured-subagent.ts`, `resolveSchema`, lines 176-188 |
| `output` frontmatter is retained as an unknown schema value | `packages/coding-agent/src/discovery/helpers.ts`, `parseAgentFields`, lines 253-323 |
| task wire exposes caller `outputSchema` and `schemaMode` | `packages/coding-agent/src/task/types.ts`, task schemas around lines 109-175 and 195-256 |
| selected source/mode/status/data are returned as `structuredOutput` | `packages/coding-agent/src/task/executor.ts`, `finalizeSubprocessOutput` and result construction around lines 596-725 and 2208-2235 |
| strict-compatible schemas shape the `yield` tool and local validation retries | `packages/coding-agent/src/tools/yield.ts`, `YieldTool`, lines 241-307 and 360-420 |
| provider adapter emits explicit `strict: true` only through its strict compatibility path | `packages/ai/src/providers/openai-responses.ts`, lines 1351-1389 |
| `PI_NO_STRICT` is the supported process-local strict-wire bypass | `packages/ai/src/utils/schema/adapt.ts`, lines 5-35 |

These facts predict behavior. E1 still requires provider-backed transcripts.

## 5. Selected experiment design

E1 will create six case records backed by seven independent provider-backed OMP
process attempts:

1. agent JTD `output:` only;
2. agent JSON Schema `output:` only;
3. caller `outputSchema` only;
4. caller and agent schemas with mutually exclusive sentinels;
5. nested leaf with session schema only; and
6. provider strictness, using a strict-on arm and a process-local
   `PI_NO_STRICT=1` control arm.

Every process receives a fresh disposable root, disposable agent home, explicit
hash-verified OMP 17.2.10 executable, case session directory, bounded timeout, and
case-specific raw/derived artifacts. No product path is used as the fixture.

The provider execution wave permits one attempt per ordinary case and exactly the
two fixed case-5 arms. There is no automatic experiment-level rerun.

## 6. Material self-review correction

The conversationally approved draft originally planned only a strict-on case 5.
Codex rejected that as insufficient during written-spec self-review:

```text
strict:true request + valid output
```

does not by itself distinguish provider enforcement from voluntary model compliance.

The written design therefore adds a causal control:

- both arms use byte-identical schema and assignment fixtures;
- both use `schemaMode: strict`;
- strict-on runs with `PI_NO_STRICT` absent and must transmit `yield.strict: true`;
- strict-off runs in a separate process with `PI_NO_STRICT=1` and must omit the
  strict wire field;
- the assignment demands both a prohibited constant and `forbidden_extra`;
- strict-off must expose the invalid first attempt and one local rejection before
  correction;
- strict-on must conform on its first terminal-yield attempt with no local schema
  rejection.

If the strict-off first attempt is already valid, the discriminator did not fire.
The result is `INVALID_RUN`, not PASS, and no automatic prompt change/rerun occurs.

This correction increases the planned provider-backed process count from six to
seven while retaining six case records. The added process has evidentiary value and
is not a coverage expansion unrelated to E1.

## 7. Provider evidence boundary

Case 5 uses a disposable loopback forwarder in front of the unchanged OmniRoute
gateway. It persists only a sanitized projection of the `yield` tool definition,
strict-field presence/value, closed data-schema facts, sanitized parameter hash,
request path, and gateway status.

It does not persist authorization values, keys, cookies, complete bodies, private
prompts, encrypted reasoning, or OmniRoute database content. The conclusion is
bounded to OMP 17.2.10 + configured OmniRoute/OpenAI-Responses +
`codex/gpt-5.6-sol-high`. It makes no claim about OmniRoute's internal upstream.

Repository raw artifacts will be line-preserving sanitized event streams. Original
byte capture exists only under the verified temporary root and is removed after the
sanitized artifact and source/sanitized hashes are verified.

## 8. State-transition contract

```yaml
all_six_records_pass_including_both_case5_arms:
  E1: PASS
  T-00.4: READY
complete_behavioral_contradiction:
  E1: FAIL
  T-00.4: NOT_STARTED
complete_external_block:
  E1: BLOCKED_ENVIRONMENT
  T-00.4: NOT_STARTED
invalid_or_incomplete_capture_only:
  E1: READY
  T-00.4: NOT_STARTED
```

`INVALID_RUN` has no manifest state or contract power. The manifest stays unchanged
until a complete terminal evidence set exists. E1 PASS does not implement T-00.4.

## 9. Locked product pre-state

The four current historical schema files remain byte-identical and total 218 lines:

| Path | SHA-256 |
|---|---|
| `template/.omp/schemas/agent-result.schema.yml` | `A55B8E64DA16BB8205A6F815E9A8CD8DDE96BB8E085139435C71B785DCAE57D8` |
| `template/.omp/schemas/review-result.schema.yml` | `439D5B321739FE22792847C8D091668C58DEFC0244E8AD14A6328FE464A8182B` |
| `template/.omp/schemas/task-packet.schema.yml` | `78459082CC66C1F9320D3734B1BBA9C10F7DAA4E68EB4828B3D3879357DF2ABB` |
| `template/.omp/schemas/verification-result.schema.yml` | `2D6F05567482CAADB39E487BA7838DF24904ADFE12C66DEE180AA4B8D4DB627C` |

They are documentation-shaped contracts, not valid runtime JTD/JSON Schema blocks.
E1 does not convert them. That work belongs to T-00.4 after OQ-A closes.

The five production agent files also remain unchanged. E1 fixtures will live only
under the E1 evidence fixture and disposable runtime roots.

## 10. Planned test discipline

Provider execution remains forbidden until focused Pester tests and mutation
controls are green for:

- runtime pin enforcement;
- absence versus explicit null/empty caller schema;
- caller/agent/session result extraction;
- nested leaf attribution;
- recovered-versus-terminal retry precedence;
- strict request projection and sanitization;
- strict-off invalid-first / corrected-second sequence;
- forbidden property/constant detection;
- raw-to-derived hash linkage;
- protected-home equality; and
- manifest state derivation.

After runtime evidence, both PowerShell shells run the focused suite, all Phase 00
suites, the full validator, manifest/hash checks, protected product hashes, and the
zero-staged-path assertion.

## 11. Self-review evidence for this checkpoint

The design self-check asserted all of these as true:

- provisional status and no implementation authority;
- E1-before-T-00.4 ordering;
- seven process attempts and six records;
- nested leaf, not carrier, as case-4 oracle;
- strict-on and strict-off causal comparison;
- explicit prohibition on equating `schemaMode: strict` with provider strictness;
- `INVALID_RUN` has no manifest power;
- T-00.4 moves only to `READY` after E1 PASS;
- all named pinned-source symbols exist; and
- the changelog contract is present.

File hygiene after self-review:

```yaml
design_trailing_whitespace_lines: 0
staged_paths: 0
provider_process_attempts: 0
provider_requests: 0
```

## 12. Current authorized boundary

The user approved the written design and authorized Codex to proceed. The
`superpowers:writing-plans` workflow produced the implementation plan. The user had
already selected Codex-only inline execution in the current dirty worktree, so the
plan records `superpowers:executing-plans` as the execution workflow and explicitly
does not select subagent-driven execution.

Task 10 is reopened as `E1-OFFLINE-GATE-REOPENED-001`. The next authorized action is
to complete and re-freeze the offline raw-to-oracle projection and deterministic
record derivation. Task 11's seven-process live wave is not currently authorized.
The runner has still never been invoked with a fixture prompt at this checkpoint.

## 13. Questions for later Opus review

1. Does the strict-off arm make the provider-enforcement discriminator sufficiently
   causal without claiming knowledge of OmniRoute's internal upstream?
2. Is nested-leaf `structuredOutput.source: session` the correct case-4 observation,
   with carrier `source: caller` treated only as setup?
3. Is requiring both JTD and JSON Schema frontmatter probes appropriate for closing
   OQ-A as `BOTH_ACCEPTED` at the pinned runtime?
4. Are `INVALID_RUN`, FAIL, BLOCKED_ENVIRONMENT, and manifest transitions separated
   without evidence laundering?
5. Does the proposed sanitized event stream retain enough raw attribution while
   excluding private request/reasoning content?

Opus disagreement should cite the exact design section, source symbol, or missing
runtime discriminator. No Codex-only statement in this file is joint closure.

## 14. E1-PLAN-001 checkpoint evidence

### 14.1 Approval and plan identity

```yaml
written_design_user_approved: true
approved_design_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
implementation_plan:
  path: docs/superpowers/plans/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-plan.md
  lines: 730
  bytes: 40085
  baseline_sha256_before_task_checkmarks: F05AD6A9D4D9B153A1D0A07DF217C0494DBBF0421B7C3A1F0ABF4A9DA34CD844
  tasks: 13
  checkbox_steps: 97
execution_mode: CODEX_ONLY_INLINE_DIRTY_MAIN
provider_process_attempts: 0
provider_requests: 0
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
staged_paths: 0
joint_closure: false
```

### 14.2 Plan self-review

The plan was checked after writing:

- all 13 task headings are present in order;
- all 11 stable public function names appear in the plan;
- 50 Markdown fence lines form 25 balanced code blocks;
- 97 checkbox steps define reviewable RED/GREEN/hash/provider gates;
- trailing-whitespace lines: 0;
- unfinished implementation markers: 0;
- design-to-plan coverage explicitly maps every approved design invariant;
- no commit, branch, worktree, stage, push, PR, reset, or checkout action is
  authorized;
- no provider call is authorized before the offline gate;
- strict-off precedes strict-on and a non-PASS stops the wave;
- manifest changes remain conditional on complete adjudicable evidence; and
- E1 PASS only unlocks T-00.4 to `READY`.

### 14.3 Planned implementation order

1. focused RED surface;
2. definitions/status/safety;
3. sanitizer;
4. extraction and retry authority;
5. forwarder;
6. exact fixtures;
7. runner;
8. case and experiment oracles;
9. durable validator integration;
10. full offline gate;
11. seven sequential provider processes;
12. conclusion and exact manifest transition; and
13. full verification plus final Opus handoff.

This checkpoint authorizes implementation planning and the beginning of offline
test-first work. It does not assert E1 runtime behavior or joint acceptance.

### 14.4 Execution-review correction: blocking belongs to agent policy

Before writing the first test, Codex reviewed the plan against the pinned runtime
and found that deterministic blocking is selected by agent definition, not by a
caller wire argument:

- `_research/upstreams/oh-my-pi/packages/coding-agent/src/discovery/helpers.ts:299`
  parses agent-frontmatter `blocking`;
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/index.ts:707-725`
  derives `itemBlocking` from `effectiveAgent.blocking === true` and runs those
  agents inline; and
- the flat task wire schema at
  `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/types.ts:114-120`
  does not expose a caller `blocking` field.

The plan now requires `blocking: true` on all seven fixture agents, forbids prompts
from inventing a `blocking` task argument, and adds a mutation control that rejects
an async acknowledgement as an attributable case result. This correction occurred
before any E1 test or implementation code and before any provider call.

## 15. E1-RED-001 — Task 1 focused failing contract

### 15.1 Mutation

Created only `scripts/tests/phase00-e1.Tests.ps1`. The test conditionally loads the
future helper, enumerates the 11 stable E1 functions from the approved plan, and
asserts that none is missing. No production helper exists yet.

### 15.2 Verified RED

PowerShell 7.6.4:

```text
command: pwsh -NoProfile -Command <focused Invoke-Pester RED gate>
process_exit_code: 0
test_total: 1
passed: 0
failed: 1
decisive_failure: Expected 0 missing functions; observed 11
source_anchor: scripts/tests/phase00-e1.Tests.ps1:33
```

Windows PowerShell 5.1.26100.8875:

```text
command: powershell.exe -NoProfile -ExecutionPolicy Bypass -Command <focused Invoke-Pester RED gate>
process_exit_code: 0
test_total: 1
passed: 0
failed: 1
decisive_failure: Expected 0 missing functions; observed 11
source_anchor: scripts/tests/phase00-e1.Tests.ps1:33
```

The wrapper exits zero only because failure is the expected RED condition. Both
Pester runs parsed and loaded normally; there was no import, syntax, path, or test
harness error.

### 15.3 Boundary after RED

```yaml
focused_test_sha256: F4BC18E07FDF363EAADD492B6F9FE2935494F76388912E550F6D91FD915E8363
plan_current_sha256: 30B40F9CE7E2768C1AB285B000DD7E4D8CFED77986A7CAF22F3E2DE53526C291
plan_completed_steps: 4
plan_open_steps: 93
helper_exists: false
provider_process_attempts: 0
provider_requests: 0
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_changed: false
template_changed: false
staged_paths: 0
joint_closure: false
```

Task 2 may now implement only the minimum stable surface and the first
definition/status/safety behavior after adding its specific failing tests.

## 16. E1-TASK2-GREEN-001 — definitions, status, and safety

### 16.1 Implemented behavior

`scripts/lib/phase00-e1-evidence.ps1` now provides:

- seven ordered process definitions with exact matrix artifact, source, mode,
  agent, prompt, `PI_NO_STRICT` delta, sentinel property/value, forbidden
  property/value, and provider requirement;
- a three-field ordered attempt-analysis object constrained to `PASS`, `FAIL`,
  `BLOCKED_ENVIRONMENT`, or `INVALID_RUN`;
- strict lexical containment requiring cleanup targets to be normalized
  descendants of the OS temp boundary; and
- case-insensitive SHA-256 plus exact trimmed `omp/17.2.10` identity matching.

The other stable public functions are exported as empty TDD scaffolds. They do not
yet claim sanitization, extraction, oracle, writer, or durable-validator behavior;
each will receive a behavior-specific failing test before implementation.

### 16.2 RED/GREEN sequence

```yaml
surface_red:
  both_shells: "0/1 pass"
  cause: 11 stable functions absent
surface_minimum_green:
  both_shells: "1/1 pass"
definitions_red:
  pwsh: "1/2 pass"
  cause: case definition returned null
definitions_green:
  pwsh: "2/2 pass"
analysis_red:
  pwsh: "2/4 pass"
  causes:
    - analysis object returned null
    - invalid status was not rejected by empty scaffold
safety_red:
  pwsh: "4/6 pass"
  causes:
    - containment function absent
    - runtime identity function absent
final_green:
  pwsh_7_6_4: "6/6 pass; exit 0"
  windows_powershell_5_1_26100_8875: "6/6 pass; exit 0"
provider_process_attempts: 0
provider_requests: 0
```

### 16.3 Two diagnosed test-harness defects

1. Pester 3.4 `Should Throw` under PowerShell 7.6 reported that even a literal
   `throw "x"` did not throw. Direct invocation proved
   `New-Phase00E1Analysis -Status READY` emitted
   `ParameterBindingValidationException` with the four-state set. The test now
   uses explicit `try/catch` and asserts exception type/message; production
   validation was not weakened.
2. The initial sibling-prefix fixture concatenated a trailing-slash temp path
   with `-sibling`, producing the valid child `Temp\-sibling`. Diagnostics showed
   the other four unsafe paths were rejected. The test now trims the separator
   and correctly constructs `Temp-sibling`; production containment was unchanged.

One diagnostic unscoped Pester invocation observed 230/231 Phase 00 tests with the
same obsolete `Should Throw` assertion as the sole failure. It was diagnostic,
not an official full-suite checkpoint, and performed no provider call.

### 16.4 Checkpoint identities and boundaries

```yaml
helper:
  path: scripts/lib/phase00-e1-evidence.ps1
  lines: 193
  bytes: 6402
  sha256: E19EC00FC7805ECDDDE989EA6997D8DC0BE8A2DCF19606019513A16B528E9D43
focused_tests:
  path: scripts/tests/phase00-e1.Tests.ps1
  lines: 141
  bytes: 7652
  sha256: 15EDC4963E8E5E6CEE37288ED25A850209DB71816E53ED8792E967F88AE357E6
plan_current_sha256: A2E1D241F8C4BEEAAA12ACE23B6ABB9CF70BCFA021897C3E2E1DA4D4316D37BA
plan_completed_steps: 10
plan_open_steps: 87
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
raw_e1_directory_exists: false
template_changed: false
staged_paths: 0
joint_closure: false
```

## 17. E1-TASK3-GREEN-001 — line-preserving sanitization

### 17.1 Implemented behavior

`Protect-Phase00E1EventStream` now:

- hashes the source before opening any destination;
- rejects in-place operation and any pre-existing destination before changing
  bytes;
- reads through an explicitly disposed `ReadLines` enumerator and writes UTF-8
  without BOM to a new file;
- emits exactly one JSON object for every input line;
- replaces syntax-invalid and valid-non-object lines with typed, hash-only
  markers and makes the run `INVALID_RUN`;
- recursively redacts secret fields, private inputs/system prompts, reasoning,
  signatures, encrypted content, credential-shaped generic text, repository,
  disposable, and bounded live-home paths;
- preserves experiment task arguments, structured results, retry/provider/model
  facts, tool calls, and terminal metadata;
- redacts user/assistant prose contextually instead of deleting complete message
  envelopes;
- records source/sanitized hashes, counts, invalid line numbers, reason codes,
  and fixture hashes; and
- treats credential variable names as names, replacing them without pretending
  they are secret values.

### 17.2 Material correction to the plan pseudocode

The initial pseudocode listed `messages` as a blanket private key. Real OMP JSONL
shows that `agent_end.messages` also carries provider/model/stopReason/tool-call
and terminal provenance. Blanket deletion would destroy evidence required by the
oracle. The implementation now redacts prose/thinking inside message content while
retaining tool calls and terminal metadata. This is a privacy-and-attribution
correction, not a relaxation.

### 17.3 RED/GREEN evidence

```yaml
primary_valid_stream_red: "6/7 pass; empty scaffold returned null"
primary_valid_stream_green: "7/7 pass"
malformed_line_red: "7/8 pass; parse escape exposed a held ReadLines handle"
malformed_line_fix:
  - explicit iterator disposal
  - typed hash-only marker
  - INVALID_RUN reason
single_reason_array_failure: "7/8 pass; PowerShell unwrapped one code to string"
single_reason_array_fix: "explicit string[] artifact field"
in_place_red: "8/9 pass; no deliberate preflight refusal"
existing_destination_red: "9/10 pass; destination was overwriteable"
non_object_red: "10/11 pass; valid scalar/array lines incorrectly PASSed"
message_privacy_red: "11/12 pass; prose leaked and blanket messages lost metadata"
credential_text_red: "12/13 pass; credential-shaped generic text incorrectly PASSed"
final_green:
  pwsh_7_6_4: "13/13 pass; exit 0"
  windows_powershell_5_1_26100_8875: "13/13 pass; exit 0"
provider_process_attempts: 0
provider_requests: 0
```

### 17.4 Deterministic sanitizer sample

A disposable two-line sample was sanitized and deleted after verification:

```yaml
status: PASS
source_sha256: 1097F8FF1CDC2FBA24531F9F55F77B60FF376503012A46656313C4791921ED57
sanitized_sha256: DF8CC7BCD1F9A7C0DF67EC632B92384A6A551A063618EA623A5D96A30575E0FC
source_lines: 2
sanitized_lines: 2
secret_survived: false
temporary_directory_removed: true
```

### 17.5 Checkpoint identities and boundaries

```yaml
helper:
  lines: 532
  bytes: 19064
  sha256: EEFEE79D0DA5F8F0E9CA102B8BA6CC80D6BBD3C0E1D7501D9E861342BC081F82
focused_tests:
  lines: 493
  bytes: 26617
  sha256: 0A1429084DC267D57BECE58ABB59E47A3DD8C8B6979926A8C42D52E5D572561B
plan_current_sha256: 8C639C870577F3125FB6E03B7D5AB52CE31828221DBD73FFD281DDEEDBE208F1
plan_completed_steps: 15
plan_open_steps: 82
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
raw_e1_directory_exists: false
template_changed: false
staged_paths: 0
joint_closure: false
```

## 18. E1-TASK4-GREEN-001 — extraction, retry authority, and common oracle

### 18.1 Implemented behavior and current anchors

`scripts/lib/phase00-e1-evidence.ps1` now:

- dot-sources the unchanged shared runtime-evidence helper and fails closed if it
  is absent;
- recursively extracts only objects that contain `id`, `agent`, and
  `structuredOutput`, deduplicating by resolved origin path plus stable result
  identity while preserving one-based source line (`Get-Phase00E1StructuredResults`,
  line 596);
- canonicalizes task-call arguments in sorted order, removes only optional intent
  `i`, and preserves the semantic difference between absent and explicit-null
  `outputSchema` (`Get-Phase00E1CanonicalTaskArguments`, line 648;
  `Get-Phase00E1TaskCalls`, line 674);
- counts attributable assistant request starts, response ends, retry starts/ends,
  recovered retries, exhausted retry chains, provider/model pairs, and the
  authoritative terminal outcome (`Get-Phase00E1ProviderLedger`, line 734);
- reuses `Get-Phase00AuthoritativeAssistantOutcome`,
  `Get-Phase00ParentRecoveredProviderRetries`, and
  `Get-Phase00TerminalModelFailure` from the unchanged
  `scripts/lib/phase00-runtime-evidence.ps1`; and
- implements a common attempt oracle for exact source/runtime/provider pins, one
  attributable result, `valid` source/mode metadata, zero terminal/retry-exhausted
  failure, exit zero, sanitizer PASS, raw hashes/anchors, cleanup, child-process
  cleanup, and protected-surface equality (`Test-Phase00E1CommonAttempt`, line 849).

Focused test anchors are:

- structured-result extraction: `scripts/tests/phase00-e1.Tests.ps1:505`;
- task-call argument provenance: `scripts/tests/phase00-e1.Tests.ps1:571`;
- provider retry authority: `scripts/tests/phase00-e1.Tests.ps1:632`; and
- common attempt oracle: `scripts/tests/phase00-e1.Tests.ps1:717`.

### 18.2 Test-first evidence

```yaml
structured_result_red:
  result: "13/14 pass"
  cause: extractor returned zero results
structured_result_first_implementation_check:
  result: "13/14 pass"
  cause: PowerShell rejected the intentionally empty mandatory generic candidate list
  correction: add AllowEmptyCollection to the recursive accumulator parameter
structured_result_green: "14/14 pass"
task_call_red:
  result: "14/15 pass"
  cause: Get-Phase00E1TaskCalls absent
task_call_green: "15/15 pass"
provider_ledger_red:
  result: "15/17 pass"
  cause: empty public scaffold exposed no RequestCount
provider_ledger_green: "17/17 pass"
common_oracle_red:
  result: "17/19 pass"
  cause: Test-Phase00E1CommonAttempt absent
common_oracle_green: "19/19 pass"
final_green:
  pwsh_7_6_4: "19/19 pass; process exit 0"
  windows_powershell_5_1_26100_8875: "19/19 pass; process exit 0"
provider_process_attempts: 0
provider_requests: 0
```

Seven named common-oracle mutations prove deterministic outcomes:

| Mutation | Required status | Required reason |
|---|---|---|
| runtime 17.2.12 | `INVALID_RUN` | `E1_RUNTIME_IDENTITY_MISMATCH` |
| duplicate attributable result | `INVALID_RUN` | `E1_ATTRIBUTABLE_RESULT_COUNT` |
| missing raw anchor | `INVALID_RUN` | `E1_RAW_ANCHOR_MISSING` |
| protected product mutation | `INVALID_RUN` | `E1_PROTECTED_SURFACE_MUTATION` |
| terminal quota/environment error | `BLOCKED_ENVIRONMENT` | `E1_PROVIDER_ENVIRONMENT_BLOCK` |
| exhausted retry chain | `FAIL` | `E1_RETRY_EXHAUSTED` |
| wrong structured source | `FAIL` | `E1_STRUCTURED_SOURCE_MISMATCH` |

Safety/provenance invalidity is evaluated before an external environment block,
which is evaluated before behavioral contradiction. This prevents unsafe or
incomplete evidence from being laundered into either BLOCKED or FAIL.

Three diagnostic invocations were excluded from test evidence because the suite
did not validly execute: one nested-shell quoting error, unsupported Pester 3.4
`-Show`, and Windows script policy without process-local bypass. No source was
changed to accommodate them. The final Windows command used process-local
`-ExecutionPolicy Bypass`, matching prior checkpoints, and passed 19/19.

### 18.3 Protected-hash transcription correction

The Task 4 close check found that five agent hashes in the plan shared the correct
eight-character prefix and suffix but had incorrect middle characters. Such a
pattern is not a credible SHA-256 content delta. The current bytes independently
matched the authoritative T-00.3 conclusion at
`docs/evidence/phase-00/T-00.3/conclusion.yml:159-167`, so Codex corrected only
the plan literals:

| Path | Incorrect plan literal | Authoritative/current SHA-256 |
|---|---|---|
| `template/.omp/agents/explorer.md` | `EFF925B0D73EA258204D408D81F55FB9FC86273A3C2A9404BBF8CEF121F3CAE6` | `EFF925B0CF199144F306AE8F40226F8087ECF45297B0CEB270E07C3E9DF3CAE6` |
| `template/.omp/agents/implementer.md` | `6090C2299220139BE9BEDE7E17A42F67A489989B8A0C3B68D1B33A5C31E72A22` | `6090C229C4A6B9132B99F4540EA9788A2520BB358846C6ADC5482DD911E72A22` |
| `template/.omp/agents/reviewer.md` | `7960C0C5BAE3CA6B9D98062B6779579B309868976631140149E331EC85C3DE3` | `7960C0C595A2B11AD5DFDC9C9F2A591C34F5CCFC2C0ADF43D5EA70F94E3C3DE3` |
| `template/.omp/agents/tech-lead.md` | `47B3060A986105EB2382B192685B0C8ED1FBF873D20038BF1390053BAF016AD2` | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` |
| `template/.omp/agents/verifier.md` | `A3F49E18F1904EE1BD99CC2AF720E038BF3FC59DD46D2B809BB477AFB3C449E0` | `A3F49E18266587929D05B2DE28AD59D7B31E3832C20DAD5C201AB03348C449E0` |

The four schema hashes already matched. A machine comparison after correction
matched all nine protected paths. No template/product byte was changed by Codex.

### 18.4 Current identities and boundaries

```yaml
helper:
  path: scripts/lib/phase00-e1-evidence.ps1
  lines: 1024
  bytes: 40700
  sha256: DBAB7748B8CA154DEE909CCFB8C4A7F33319BAA23CC800459DA19A7590D391E1
focused_tests:
  path: scripts/tests/phase00-e1.Tests.ps1
  lines: 838
  bytes: 42516
  sha256: A9901D09197D53AB61EC06AE6F23CC9C975AA0AC5A241659CB4C023AA9446C64
shared_runtime_helper:
  path: scripts/lib/phase00-runtime-evidence.ps1
  lines: 637
  bytes: 29972
  sha256: 90143F56236A0B4B24C2D680FCE33D0DAEA42DBB7F97A09D8F251069FAF9E9D7
plan:
  lines: 736
  bytes: 40467
  sha256: 5EB8108AA1385CB0E1ED6C192D3361E3773908CA1F34A0B953BE08A651C4F56B
  completed_steps: 21
  open_steps: 76
approved_design_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
protected_paths_matched: 9/9
raw_e1_directory_exists: false
template_changed_by_codex: false
provider_process_attempts: 0
provider_requests: 0
staged_paths: 0
joint_closure: false
```

Task 4 is Codex-complete but not jointly closed. The next authorized action is
Task 5 offline forwarder TDD. No provider call is authorized.

## 19. E1-TASK5-GREEN-001 — deterministic sanitized forwarder

### 19.1 Implemented behavior and current anchors

`scripts/lib/phase00-e1-forwarder.mjs` now provides:

- recursively stable object-key ordering and uppercase SHA-256 for the exact
  sanitized `yield.parameters` object (`stable`, line 24; `sha256`, line 36);
- extraction of top-level OpenAI-Responses `yield` metadata while distinguishing
  explicit `strict:true`, explicit `strict:false`, omitted strict, missing yield,
  unrelated tools, and open versus closed `data` schemas (`projectYieldTool`,
  line 43; `createProjectionRecord`, line 65);
- a socket-free, exclusive-create `--project-only` mode (`runProjectOnly`, line
  164);
- fail-closed CLI parsing that accepts live bind only as `127.0.0.1:0` and target
  only as an HTTP(S) `127.0.0.1:<explicit-port>` origin with no credentials, path,
  query, or fragment (`parseCliArguments`, line 82);
- standard and `Connection`-nominated hop-by-hop header removal while retaining
  end-to-end headers and forwarding authorization only in memory
  (`stripHopByHopHeaders`, line 185);
- a POST-only `/v1/responses` relay with a 32 MiB bounded in-memory request,
  exact forwarded request bytes, normalized path/query, streamed response-byte
  parity, and one projection written after the upstream response ends
  (`relayRequest`, line 225); and
- ephemeral loopback binding, exclusive evidence output, exact ready/projection/
  closed record order, stored listen port, graceful stdin/signal shutdown, and
  closed-port verification support (`runLive`, line 287).

The projection has exactly these 15 persisted keys and no body/header/target
field: `allowed_data_properties`, `api`, `data_additional_properties`, `forwarded`,
`gateway`, `gateway_http_status`, `pi_no_strict_effective`, `record_type`,
`request_index`, `request_path`, `required_data_properties`,
`yield_parameters_sha256`, `yield_strict`, `yield_strict_field_present`, and
`yield_tool_present`. Ready and closed records each have exactly
`listen_host`, `listen_port`, and `record_type`.

Focused test anchors are:

- offline projection: `scripts/tests/phase00-e1.Tests.ps1:943`;
- unsafe endpoint/existing-evidence rejection: `scripts/tests/phase00-e1.Tests.ps1:1137`;
- disposable local relay: `scripts/tests/phase00-e1.Tests.ps1:1192`.

### 19.2 Test-first chronology and material corrections

```yaml
offline_projection_red:
  result: "19/21 pass"
  sole_causes:
    - forwarder module did not exist
    - project-only CLI did not exist
offline_projection_green: "21/21 pass"
live_relay_red:
  result: "21/22 pass"
  sole_cause: "CLI rejected --listen as unknown"
first_live_implementation_check:
  result: "21/22 pass"
  defect: "closed record read server.address() after close and persisted null port"
  correction: "capture the bound port at ready and reuse that immutable value at close"
live_green: "22/22 pass"
post_green_relay_refactor:
  changes:
    - normalize the forwarded path from the parsed URL
    - pipe upstream bytes with backpressure while delaying client end until projection write
    - pause stdin during shutdown
  verification: "22/22 pass"
hardening_tests:
  additions:
    - exact evidence-key allowlists
    - reject non-loopback bind
    - reject non-127.0.0.1 target
    - refuse existing evidence before ready/listen
  verification: "23/23 pass"
provider_process_attempts: 0
provider_requests: 0
```

No production behavior was weakened to make a test pass. The `listen_port:null`
result was treated as a real evidence defect because it would prevent later proof
that the exact bound port was closed.

### 19.3 Final runtime verification

```yaml
node:
  version: v24.16.0
  syntax_check: PASS
pester:
  powershell_7_6_4: "23/23 pass; 0 failed; 0 skipped; process exit 0"
  windows_powershell_5_1_26100_8875: "23/23 pass; 0 failed; 0 skipped; process exit 0"
live_relay:
  upstream: disposable 127.0.0.1 fake gateway only
  request_byte_parity: PASS
  response_binary_byte_parity: PASS
  authorization_forwarded_in_memory: PASS
  dynamic_request_hop_header_removed: PASS
  dynamic_response_hop_header_removed: PASS
  end_to_end_headers_preserved: PASS
  record_order: ready,projection,closed
  forwarder_port_closed: PASS
  fake_gateway_closed: PASS
  persisted_secret_scan_matches: []
safety:
  unsafe_listen_created_output: false
  unsafe_target_created_output: false
  existing_output_changed: false
  ready_emitted_before_rejection: false
provider_process_attempts: 0
provider_requests: 0
```

A deterministic socket-free projection probe used only synthetic sentinels and
was removed after verification:

```yaml
yield_parameters_sha256: BA45FA65ACE1C6653B74557015A2993085CF72FAF126D2CB01A76553DE05279C
projection_ndjson_sha256: D2B6E21056E73A94B933D3E141F9405FFB685F82171B3C60E77D78DA4AA9B48E
projection_bytes: 519
persisted_record_keys: 15/15 exact
secret_scan_matches: []
provider_calls: 0
hash_probe_temp_roots_after: 0
```

One pre-existing `phase00-e1-test-*` directory from an earlier Task 3 malformed-
line RED run was discovered during the Task 5 cleanup audit. It contains only the
129-byte synthetic `malformed-source.jsonl` test fixture, not provider output or
private user data. An exact-path deletion was attempted only after validating the
OS-temp parent and generated-name pattern, but the host command policy rejected
the delete before execution; no bytes changed. This historical test residue is
not part of a provider attempt and does not weaken the Task 5 relay-port cleanup
proof. It remains disclosed for Opus rather than being hidden or misreported.

### 19.4 Current identities and protected boundaries

```yaml
forwarder:
  path: scripts/lib/phase00-e1-forwarder.mjs
  lines: 382
  bytes: 12435
  sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
focused_tests:
  path: scripts/tests/phase00-e1.Tests.ps1
  lines: 1404
  bytes: 68896
  sha256: 24CD7C14EFE82D819F65A2B3FABB7391D8F0E9C029D1C3CE0C8A134BEF1246FD
evidence_helper_unchanged_sha256: DBAB7748B8CA154DEE909CCFB8C4A7F33319BAA23CC800459DA19A7590D391E1
shared_runtime_helper_unchanged_sha256: 90143F56236A0B4B24C2D680FCE33D0DAEA42DBB7F97A09D8F251069FAF9E9D7
plan:
  lines: 736
  bytes: 40467
  sha256: AA32E0B054F7452584803592FF34B6F6C331EEBA8278E002B100739B5ABB5EBB
  completed_steps: 27
  open_steps: 70
approved_design_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
protected_paths_matched: 9/9
raw_e1_directory_exists: false
template_changed_by_codex: false
provider_process_attempts: 0
provider_requests: 0
staged_paths: 0
joint_closure: false
```

Task 5 is Codex-complete but not jointly closed. The next authorized action is
Task 6 fixture-contract TDD. No provider call is authorized.

## 20. E1-TASK6-GREEN-001 — exact disposable fixture

### 20.1 Implemented fixture contract

Task 6 created exactly 14 files under `docs/evidence/phase-00/E1/fixture`:

- one project config disables startup plan mode, async, batch task shape, effort,
  and isolation; fixes task concurrency to one, recursion depth to two, and each
  subagent runtime to 180,000 ms;
- all seven agents are `blocking: true` with exact names and no model override;
- six non-carrier agents expose only `read` plus OMP's automatically added `yield`;
- the carrier exposes only `task` plus automatically added `yield`, and may spawn
  only `phase00-e1-session-leaf`;
- the JTD and JSON Schema agents own mutually attributable `output:` dialects;
- caller-only, carrier, leaf, and provider-strict agents omit `output:` entirely;
- the conflicting agent owns only `agent_sentinel=E1_AGENT_LOSES` while its
  controller supplies only `caller_sentinel=E1_CALLER_WINS`;
- the carrier's sole nested flat call omits `outputSchema` rather than sending
  null, allowing the leaf to exercise parent-session fallback; and
- six controller prompts each contain one parseable flat task argument object,
  one named agent, exact schema mode, no `blocking` argument, no eval/batch form,
  and one deterministic controller marker.

The two provider-strict environment arms resolve to the same agent and the same
single prompt file. That file contains the only assignment/schema bytes; it does
not mention `PI_NO_STRICT`. Therefore the planned process-local environment value,
not prompt drift, is the sole strict-arm fixture variable.

Fixture-contract helpers and tests are anchored at:

- single JSON-block parser: `scripts/tests/phase00-e1.Tests.ps1:159`;
- leading frontmatter extractor: `scripts/tests/phase00-e1.Tests.ps1:173`;
- fixture path/hash contract: `scripts/tests/phase00-e1.Tests.ps1:1450`;
- config contract: `scripts/tests/phase00-e1.Tests.ps1:1469`;
- seven-agent contract: `scripts/tests/phase00-e1.Tests.ps1:1493`;
- six-controller contract: `scripts/tests/phase00-e1.Tests.ps1:1565`;
- strict-arm identity contract: `scripts/tests/phase00-e1.Tests.ps1:1616`.

### 20.2 Test-first chronology

```yaml
fixture_red:
  result: "23/28 pass; 5/28 fail"
  failing_contracts:
    - exact fourteen-path/hash set
    - deterministic config
    - seven blocking agents
    - six flat controller prompts
    - shared strict-arm identity
  sole_cause: "docs/evidence/phase-00/E1/fixture did not exist"
first_fixture_implementation_check:
  result: "26/28 pass"
  fixture_path_and_hash_contract: PASS
  defects:
    - two Pester assertions passed an unevaluated static regex expression
  correction: "parenthesize [regex]::Escape calls in the test harness"
  fixture_bytes_changed_by_correction: false
fixture_green:
  powershell_7_6_4: "28/28 pass; 0 failed; 0 skipped; process exit 0"
  windows_powershell_5_1_26100_8875: "28/28 pass; 0 failed; 0 skipped; process exit 0"
provider_process_attempts: 0
provider_requests: 0
```

The 26/28 intermediate result is material because the fixed path/hash test had
already passed: both remaining failures were demonstrably test-expression syntax,
not fixture drift. Codex changed only the assertions before the 28/28 result.

### 20.3 Exact fixture identities

| Relative path under `docs/evidence/phase-00/E1/fixture` | Lines | Bytes | SHA-256 |
|---|---:|---:|---|
| `.omp/config.yml` | 13 | 210 | `C1B6B21417044393E91BE3079545959D42CB72F00E0601D8909DF58527E10619` |
| `agents/phase00-e1-agent-jtd.md` | 14 | 313 | `B6A9CA4AF3A4E0365C8D2166F1FB143C34779001DBCC11138777CDA0D45B9E79` |
| `agents/phase00-e1-agent-json-schema.md` | 18 | 431 | `2292140A382F80E8ADA2F0005626AD8E0716A180B004C4C78C81E33484DBE9E8` |
| `agents/phase00-e1-caller-only.md` | 10 | 272 | `1C266E64CAC83797E7D7DA052631F858D624B5DDC4D2AA048BB607C7E54676B1` |
| `agents/phase00-e1-caller-over-agent.md` | 18 | 550 | `E68AF921F59BA6FD7FD12ECF95DBC5FBBA2D800683AAF6D8843C405A401A1B24` |
| `agents/phase00-e1-session-carrier.md` | 16 | 686 | `02A737F9D61B7D0BE62B85AAA5B72F1820F7C44946A61B9B087A6EEE0EEF91B8` |
| `agents/phase00-e1-session-leaf.md` | 10 | 277 | `ECC6A1F4E415EF6E34893754EEE233676B440636FC376415E95BE8A3F1B9F801` |
| `agents/phase00-e1-provider-strict.md` | 11 | 563 | `F8E53C651A41707CA2226F3CE687F97236BB0F0600024E42E87ACD14B85293EA` |
| `prompts/agent-jtd.md` | 11 | 608 | `EE192EA1419604FDC8814F4A44D1B848F525DC41274DD6661C33A2877826742C` |
| `prompts/agent-json-schema.md` | 11 | 647 | `D5D1BD76225910C5112B1C6F07513B1CB6E677429A3B113699A47C395BD7B6B6` |
| `prompts/caller-only.md` | 11 | 753 | `5D6F452B7AD069CB09070EC7C297BD533F0F0E17B3565C3C82A216C71541BF17` |
| `prompts/caller-over-agent.md` | 11 | 824 | `6C1F4C76DEC505690B2E4D62FA259CCE885061FE753E7B6152629C034A8FF5E7` |
| `prompts/session-only.md` | 11 | 834 | `D93A14C4AF93541DB049C3A7154593FADF5275CCC07D2D912EFCEB20EF8BE817` |
| `prompts/provider-strict.md` | 11 | 923 | `15B1C1BA9133F89B1125FCD089F87147F282DC1AAF315FFB303322A46AC87113` |

Aggregate fixture identity:

```yaml
files: 14
bytes: 7891
tree_hash_algorithm: "SHA256(sorted UTF-8 relative-path + TAB + uppercase file SHA256 + LF)"
tree_manifest_bytes: 1329
tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
```

Strict shared-fixture discriminators:

```yaml
prompt_sha256: 15B1C1BA9133F89B1125FCD089F87147F282DC1AAF315FFB303322A46AC87113
assignment_utf8_sha256: D8F7E058CCD96702BAB3D6AF2698356736B9525785BB6C6684F0FBAAC12BE88A
output_schema_canonical_sha256: D40C5DF70D19DB184EC8E5A7FA651E05790BFC4579E29C1ABA0E214C95712E59
task_argument_keys: [agent, name, outputSchema, schemaMode, task]
schema_mode: strict
required: [allowed]
additional_properties: false
```

### 20.4 Current identities and protected boundaries

```yaml
focused_tests:
  path: scripts/tests/phase00-e1.Tests.ps1
  lines: 1635
  bytes: 84321
  sha256: 4A8196A13147C13B132285AB5A7C9E648F6EE26729A88A5DDB7C009F9F35F440
plan:
  lines: 736
  bytes: 40467
  sha256: 078B7F6D895BA3C24B57E9656F4909EBFFCE7B43E7596EF5743A0E34A8417AA4
  completed_steps: 38
  open_steps: 59
forwarder_unchanged_sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
evidence_helper_unchanged_sha256: DBAB7748B8CA154DEE909CCFB8C4A7F33319BAA23CC800459DA19A7590D391E1
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
protected_paths_matched: 9/9
raw_e1_directory_exists: false
template_changed_by_codex: false
provider_process_attempts: 0
provider_requests: 0
staged_paths: 0
joint_closure: false
```

Task 6 is Codex-complete but not jointly closed. The next authorized action is
Task 7 runner preflight/capture/cleanup TDD. No provider call is authorized.

## 21. E1-TASK7-GREEN-001 — fail-closed runner, capture, and cleanup

### 21.1 Implemented contract

`scripts/run-phase00-e1.ps1` now exposes only the approved `CaseId`, `Attempt`,
mandatory `OmpExecutable`, `Model`, and non-authorizing `AllowOverwrite` surface,
then delegates unchanged bound parameters to `Invoke-Phase00E1EvidenceCase`.

The runner implementation at
`scripts/lib/phase00-e1-evidence.ps1:2548` now performs this order:

1. validate the model identifier, derive the fixed attempt destinations, hash the
   absolute source executable, and invoke it only with `--version`;
2. require SHA-256
   `1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`,
   exact output `omp/17.2.10`, absent attempt destinations, 9/9 protected pins,
   and readable bounded live-home snapshots before creating a temp root;
3. for strict arms, also pin the unchanged forwarder source before temp creation;
4. create one GUID-named strict OS-temp descendant, copy/re-hash/re-version the
   runtime, copy only the fourteen fixtures, and write only the sanitized model
   catalog into the disposable agent home;
5. remove inherited OMP/PI/profile/config/broker/home controls from the child,
   install disposable home paths, prepend the copied runtime to process-local
   `PATH`, and set `PI_NO_STRICT=1` only for `ProviderStrictOffControl`;
6. launch the copied runtime from the disposable non-repository project with the
   exact approved arguments, including `--tools task`, while draining stdout and
   stderr concurrently and applying a 540-second tree-killing timeout;
7. for strict arms only, point the disposable catalog at a pinned ephemeral
   loopback forwarder, close it after OMP, verify exit/stream/child/port lifecycle,
   and retain only its already-sanitized request projection;
8. write original UTF-8 capture only below the verified temp root, sanitize stdout,
   stderr, every session JSONL, and the optional forwarder stream into new
   exclusive repository destinations, then reparse every line, re-hash every
   artifact, check line counts, and scan exact plus JSON-escaped secret values;
9. hash rather than persist private session-relative names, compare protected and
   bounded live-home snapshots, record remaining child PIDs, and delete only the
   revalidated generated temp root; and
10. write the exclusive, private-path-free run envelope only after cleanup.

The envelope deliberately separates capture integrity from behavioral
adjudication:

```yaml
capture_integrity_status: PASS | INVALID_RUN
case_status: null
case_oracle_evaluated: false
```

Therefore Task 7 cannot imply a case PASS. `INVALID_RUN` throws after preserving
the envelope and explicitly forbids automatic rerun. A nonzero OMP exit remains a
captured behavioral fact for Task 8 rather than being silently converted into a
capture failure.

Current implementation anchors:

- concurrent process capture/tree termination:
  `scripts/lib/phase00-e1-evidence.ps1:1125`;
- pinned runtime preflight: `scripts/lib/phase00-e1-evidence.ps1:1235`;
- disposable fixture/runtime/catalog construction:
  `scripts/lib/phase00-e1-evidence.ps1:1731`;
- bounded live-home snapshots: `scripts/lib/phase00-e1-evidence.ps1:2022`;
- exclusive path/secret-free envelope: `scripts/lib/phase00-e1-evidence.ps1:2129`;
- forwarder start/ready validation: `scripts/lib/phase00-e1-evidence.ps1:2237`;
- forwarder close/child/port validation:
  `scripts/lib/phase00-e1-evidence.ps1:2351`;
- full orchestration: `scripts/lib/phase00-e1-evidence.ps1:2548`;
- exact CLI surface/delegation: `scripts/run-phase00-e1.ps1:1-18`.

### 21.2 Test-first chronology and corrections

```yaml
initial_runner_red:
  result: "27/37 pass; 10 fail"
  absent_contracts:
    - eighteen runner helpers/public entry points
    - runner file and exact parameter surface
    - identity/destination/cleanup/environment/capture/fixture/sanitizer behavior
first_helper_implementation:
  result: "33/37 pass; 4 fail"
  newly_green:
    - pinned real-runtime preflight and all negative identity probes
    - overwrite and temp-root containment
    - concurrent 1 MiB stdout plus 1 MiB stderr capture
    - timed-out generated parent/child tree termination with zero survivors
    - strict environment isolation and protected snapshot mutations
fixture_and_sanitizer_helpers:
  result: "35/37 pass; 2 fail"
  failures: "test-harness-only"
  corrections:
    - single-quote the static regex so `$Attempt` is not interpolated
    - replace Pester-3 file-oriented `Should Not Contain` with explicit membership
coverage_gap_exposed:
  result: "37/37 pass"
  finding: "the public main function was still a deliberate throw placeholder"
orchestration_red_extension:
  result: "37/41 pass; 4 fail"
  new_controls:
    - complete preflight-to-envelope call order and no Task-8 adjudication
    - live-home mutation without path disclosure
    - exclusive private-path/secret-free run envelope
    - pinned forwarder start/close with zero gateway requests
intermediate_runner_green:
  result: "39/41 pass; 2 fail"
  remaining:
    - main orchestration still absent
    - JSON-escaped absolute path escaped the initial envelope scan
full_runner_first_green:
  powershell_7_6_4: "41/41 pass"
  windows_powershell_5_1: "40/41 pass"
  compatibility_defect: "one pipeline scalar lacked Count on Windows PowerShell"
  correction: "force explicit array counting; contract unchanged"
hardening:
  additions:
    - main-runner missing-executable proof creates neither temp root nor raw root
    - exact-secret scans recognize JSON-escaped values
    - process cleanup checks HasExited only after a successful Start
  result_both_shells: "42/42 pass"
status_vocabulary_self_review:
  red: "41/42 pass; CAPTURED fifth state rejected"
  correction: "capture_integrity_status PASS/INVALID_RUN; null unevaluated case"
final_green:
  powershell_7_6_4: "42/42 pass; 0 failed; 0 skipped; exit 0"
  windows_powershell_5_1_26100_8875: "42/42 pass; 0 failed; 0 skipped; exit 0"
```

The JSON-escaped path finding was an implementation defect, not a cosmetic test
change: JSON serializes Windows separators as `\\`. The final writer rejects the
literal, slash-normalized, backslash-normalized, and JSON-escaped forms before
opening the destination. The secret scanner applies the same principle to encoded
secret values.

The `CAPTURED` finding was also material. It was removed because the approved
attempt vocabulary has only PASS, FAIL, BLOCKED_ENVIRONMENT, and INVALID_RUN, and
Task 7 has no authority to adjudicate behavior.

Runner test anchors are:

- preflight/static/main-no-side-effect: `scripts/tests/phase00-e1.Tests.ps1:1655`;
- destination/cleanup containment: `scripts/tests/phase00-e1.Tests.ps1:1792`;
- concurrent streams/tree timeout: `scripts/tests/phase00-e1.Tests.ps1:1844`;
- strict environment isolation: `scripts/tests/phase00-e1.Tests.ps1:1910`;
- protected/live-home snapshots: `scripts/tests/phase00-e1.Tests.ps1:1991`;
- disposable fixture/exact wire: `scripts/tests/phase00-e1.Tests.ps1:2070`;
- sanitization/envelope verification: `scripts/tests/phase00-e1.Tests.ps1:2150`;
- zero-request strict forwarder lifecycle:
  `scripts/tests/phase00-e1.Tests.ps1:2280`.

### 21.3 Offline boundary evidence

```yaml
pinned_source_version_probe:
  executable_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
  exact_stdout: omp/17.2.10
  arguments: [--version]
  exit_code: 0
  stderr: empty
prompt_bearing_omp_process_attempts: 0
configured_omniroute_gateway_requests: 0
task7_forwarder_lifecycle_projection_count: 0
raw_e1_directory_exists: false
generated_e1_temp_roots_remaining: 0
targeted_forwarder_node_processes_remaining: 0
protected_paths_matched: 9/9
manifest:
  sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
  e1: READY
  t_00_4: NOT_STARTED
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
staged_paths: 0
template_changed_by_task7: false
joint_closure: false
```

The older forwarder relay test still uses only its own ephemeral fake loopback
upstream. The Task 7 lifecycle test starts the real pinned forwarder with the
configured gateway as its dormant target, sends no request, observes exactly
`ready,closed`, and verifies the port is closed. Neither test is a provider call.

### 21.4 Current identities

```yaml
runner:
  path: scripts/run-phase00-e1.ps1
  lines: 18
  bytes: 555
  sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
evidence_helper:
  path: scripts/lib/phase00-e1-evidence.ps1
  lines: 3075
  bytes: 126835
  sha256: 24E196F183E8C666C79C2F91AC7D8EE4922EFD0AA3568F5CF70DDB50AE2DFCA7
focused_tests:
  path: scripts/tests/phase00-e1.Tests.ps1
  lines: 2308
  bytes: 119721
  sha256: 33E9FDAF891BDE325006B9718E2AEA64C472E2E7401740141BA45DAF82134C08
forwarder:
  path: scripts/lib/phase00-e1-forwarder.mjs
  lines: 382
  bytes: 12435
  sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
fixture:
  files: 14
  bytes: 7891
  tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
plan:
  path: docs/superpowers/plans/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-plan.md
  lines: 736
  bytes: 40467
  sha256: 04D6C1FCD42F141D358A4106071B82A22C974205F847C9FD5C245FD5A0AE5A17
  checkbox_steps: 97
  completed_steps: 48
  open_steps: 49
design_unchanged_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
```

### 21.5 Review and next boundary

Task 7 is Codex-complete, not jointly closed. Opus should review the exact preflight
order, error-path sanitization/cleanup semantics, live-home boundary, strict
forwarder lifecycle, and the separation between capture-integrity PASS and an
unevaluated case before agreeing.

The next Codex action is Task 8 test-first implementation of the five ordinary
case oracles, the strict-off/strict-on pair oracle, and the matrix outcome. The
runner must not be executed with any fixture prompt, and no provider-backed attempt
is authorized, until Task 10 completes the full offline gate.

## 22. E1-TASK8-GREEN-001 — pure case, strict-pair, and matrix oracles

### 22.1 Normalized evidence contract and status ownership

`Test-Phase00E1Attempt` at `scripts/lib/phase00-e1-evidence.ps1:3540`
accepts only a case ID and one normalized evidence object. It does not read files,
launch processes, write artifacts, or mutate its input. The object separates:

- attributable structured results;
- the provider/retry ledger and normalized run record consumed by the existing
  common oracle;
- exact blocking definition/setup/execution facts;
- caller/agent/session schema-presence and child-initialization facts;
- strict-arm identity, environment, forwarder projection, terminal-yield attempt,
  local rejection/retry, and override facts.

Invalid design, capture, provenance, blocking, identity, or attribution returns
`INVALID_RUN` before behavioral interpretation. A complete external provider block
remains `BLOCKED_ENVIRONMENT`. A complete attributable contradiction returns FAIL.
Only then can a case-specific PASS be returned.

Every direct case requires one exact target blocking record. `SessionOnly` requires
both exact carrier and leaf records, selects the leaf result, requires caller-owned
carrier setup, and forbids caller/agent schema presence on the selected nested leaf.
Any async acknowledgement, missing blocking proof, carrier substitution, or wrong
result agent is `INVALID_RUN`.

Ordinary PASS reasons are distinct:

```yaml
AgentJtd: E1_AGENT_JTD_PASS
AgentJsonSchema: E1_AGENT_JSON_SCHEMA_PASS
CallerOnly: E1_CALLER_ONLY_PASS
CallerOverAgent: E1_CALLER_OVER_AGENT_PASS
SessionOnly: E1_SESSION_ONLY_PASS
```

Each requires the exact single expected data property/value. The caller-over-agent
case additionally rejects the agent-only property even when the caller sentinel is
present.

### 22.2 Strict-arm and cross-arm causal contract

The strict structural validator at
`scripts/lib/phase00-e1-evidence.ps1:3286` pins all of these independently of
cross-arm equality:

```yaml
prompt_sha256: 15B1C1BA9133F89B1125FCD089F87147F282DC1AAF315FFB303322A46AC87113
assignment_sha256: D8F7E058CCD96702BAB3D6AF2698356736B9525785BB6C6684F0FBAAC12BE88A
output_schema_sha256: D40C5DF70D19DB184EC8E5A7FA651E05790BFC4579E29C1ABA0E214C95712E59
agent_sha256: F8E53C651A41707CA2226F3CE687F97236BB0F0600024E42E87ACD14B85293EA
yield_parameters_sha256: BA45FA65ACE1C6653B74557015A2993085CF72FAF126D2CB01A76553DE05279C
agent: phase00-e1-provider-strict
model: codex/gpt-5.6-sol-high
runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
runtime_version: omp/17.2.10
gateway: omniroute:127.0.0.1:20128
```

Forwarder records must be attributable `/v1/responses` projections, have contiguous
one-based request indexes, equal the normalized provider-request count, retain the
pinned yield-parameter hash, and include a gateway status. After the common oracle
passes, at least one 2xx gateway response is required.

Strict-off PASS requires `PI_NO_STRICT` state `PRESENT_1`, omitted wire strict,
closed transmitted data schema, the prohibited first terminal yield, exactly one
schema rejection, exactly one retry, a second exact valid yield, no dynamic schema
override, and exact valid final data. If the first yield already conforms, status is
`INVALID_RUN/E1_STRICT_CONTROL_NOT_EXERCISED`, not PASS.

Strict-on PASS requires environment state `ABSENT`, explicit wire `strict:true`,
the same closed schema, one exact conforming provider-returned terminal yield,
zero local rejection/retry/override, no prohibited value/property anywhere in the
attempt, exact valid final data, and an attributable gateway response.

`Test-Phase00E1ProviderStrictPair` at
`scripts/lib/phase00-e1-evidence.ps1:3690` first requires equality of prompt,
assignment, output schema, agent fixture/name, yield parameters, model, runtime, and
gateway. It then applies arm precedence `INVALID_RUN`, `BLOCKED_ENVIRONMENT`, FAIL,
PASS. Only two PASS arms produce `E1_PROVIDER_STRICT_PAIR_PASS`.

### 22.3 Exact matrix adjudication

`Get-Phase00E1ExperimentOutcome` at
`scripts/lib/phase00-e1-evidence.ps1:3752` requires exactly these six unique record
IDs:

```yaml
- AgentJtd
- AgentJsonSchema
- CallerOnly
- CallerOverAgent
- SessionOnly
- ProviderStrictPair
```

A count mismatch is `E1_MATRIX_INCOMPLETE`; a duplicate/wrong set is
`E1_MATRIX_CASE_SET_INVALID`. For a complete set, the approved precedence is FAIL,
then BLOCKED_ENVIRONMENT, then any non-PASS as INVALID_RUN, else
`PASS/E1_ALL_SIX_CASES_PASS`.

### 22.4 Test-first chronology and named mutation controls

```yaml
task8_red:
  result: "42/49 pass; 7 fail"
  prior_task_regressions: 0
  sole_failure_cause: "Test-Phase00E1Attempt, Test-Phase00E1ProviderStrictPair, and Get-Phase00E1ExperimentOutcome were empty stubs"
first_green:
  powershell_7_6_4: "49/49 pass"
  windows_powershell_5_1_26100_8875: "49/49 pass"
hardening_additions:
  - missing raw artifact and missing raw hash
  - recovered-versus-terminal inversion
  - open provider data schema
  - forbidden final data hidden behind a valid first attempt
  - forwarder/provider request-count mismatch
hardening_intermediate:
  result: "49/50 pass; 1 fail"
  cause: "missing raw correctly also invalidated its anchor; expected result named only the first reason"
  correction: "retain exact two-code order; do not relax the oracle"
pair_precedence_addition:
  controls: [INVALID_RUN, FAIL, BLOCKED_ENVIRONMENT]
final_green:
  powershell_7_6_4: "51/51 pass; 0 failed; 0 skipped; exit 0"
  windows_powershell_5_1_26100_8875: "51/51 pass; 0 failed; 0 skipped; exit 0"
prompt_bearing_omp_process_attempts: 0
configured_omniroute_gateway_requests: 0
```

The exact named controls cover swapped source, explicit caller null, dual
sentinels, carrier substitution, nested caller schema, blocking/async attribution,
hidden override, strict flag/environment inversion, open schema, prohibited
attempt/final data, local retry/override, unexercised control, forwarder/request
count mismatch, every cross-arm identity field, recovered/terminal inversion,
missing raw/hash/anchor, runtime 17.2.12, protected mutation, incomplete/duplicate
matrix, and FAIL/BLOCKED/INVALID precedence.

Test anchors:

- normalized synthetic evidence builder:
  `scripts/tests/phase00-e1.Tests.ps1:2321`;
- five ordinary cases and mutations: `scripts/tests/phase00-e1.Tests.ps1:2558`;
- strict arms and mutations: `scripts/tests/phase00-e1.Tests.ps1:2612`;
- strict pair equality/status precedence:
  `scripts/tests/phase00-e1.Tests.ps1:2714`;
- exact six-record outcome: `scripts/tests/phase00-e1.Tests.ps1:2777`.

### 22.5 Current identities and boundary

```yaml
evidence_helper:
  path: scripts/lib/phase00-e1-evidence.ps1
  lines: 3796
  bytes: 159574
  sha256: F451DA623F5ADCC3B30AF16D37A438FF7FCFF62735870CC3B78F770537BEDA2F
focused_tests:
  path: scripts/tests/phase00-e1.Tests.ps1
  lines: 2819
  bytes: 142662
  sha256: 1ED0E4BF1BEC0DCD9F0B8B60584F1C9CF10EC0FAE273ADEB33CE9AB1A67C69C2
runner_unchanged_sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
forwarder_unchanged_sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
fixture_tree_unchanged_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
plan:
  lines: 736
  bytes: 40467
  sha256: 1C80418667083CCFD9AE31C9A7646EC5D54C1FBE0949C2102C967715A8D6FEF6
  checkbox_steps: 97
  completed_steps: 57
  open_steps: 40
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
raw_e1_directory_exists: false
generated_e1_temp_roots_remaining: 0
targeted_forwarder_processes_remaining: 0
protected_paths_matched: 9/9
staged_paths: 0
joint_closure: false
```

Task 8 is Codex-complete, not jointly closed. Task 9 may add only durable
READY-state validation and compatibility plumbing. It must not create runtime raw
evidence, run a fixture prompt, write a case record, or alter the manifest.

## 23. E1-TASK9-GREEN-001 — durable READY validation and integration

### 23.1 Contract registered without terminal authority

`Test-Phase00E1ArtifactContract` at
`scripts/lib/phase00-e1-evidence.ps1:3890` now emits five independent category
checks and one aggregate READY check:

```yaml
P00-E1-FIXTURE: exact 14-file fixture path set and precommitted hashes
P00-E1-RUNTIME: registered helpers, runner markers, seven cases, 17.2.10 pin, and strict-forwarder hash
P00-E1-PROTECTED-SURFACE: exact nine product hashes
P00-E1-MANIFEST: E1 READY/empty and T-00.4 NOT_STARTED/empty depending only on E1
P00-E1-CONCLUSION: exact terminal conclusion path absent while READY
P00-E1-READY: aggregate PASS only when every category passes
```

The targeted manifest reader starts at
`scripts/lib/phase00-e1-evidence.ps1:3826`. It does not grant raw files or derived
case files authority. A partial `INVALID_RUN` history can remain under `E1/raw`, but
with empty manifest artifacts and no conclusion it cannot move E1 or T-00.4. A
terminal conclusion while READY, a premature T-00.4 transition, fixture drift,
protected mutation, or missing runtime surface suppresses `P00-E1-READY` and emits
the corresponding FAIL code.

The general helper conditionally loads E1 at
`scripts/lib/phase00-evidence.ps1:1873-1876`; the repository validator registers it
immediately after the manifest validator at `scripts/validate-template.ps1:237`.
The loader remains optional: a fresh-process test copies only
`phase00-evidence.ps1`, proves it still loads, exports the legacy manifest validator,
and does not fabricate the absent E1 validator. E1-specific mutation fixtures copy
both helpers plus the runtime dependency.

### 23.2 RED-to-GREEN chronology

```yaml
integration_red:
  focused_e1: "51/58 pass; 7 fail"
  focused_e1_cause: empty Test-Phase00E1ArtifactContract stub
  wave_a: "25/27 pass; 2 fail"
  wave_a_causes:
    - E1 validator not exported through phase00-evidence.ps1
    - repository validator emitted no P00-E1-READY
first_implementation:
  focused_e1: "56/58 pass; 2 fail"
  cause: strict mode exposed a null Count from an empty inline manifest sequence
  correction: initialize the parsed sequence as a typed empty string array
post_contract_green:
  focused_e1: "58/58 pass"
  wave_a_initial: "26/27 pass; 1 fail"
  remaining_cause: T-00.3 correctly detected the changed validator destination hash
integration_correction:
  action: rebind only the T-00.3 validate-template destination hash and add explicit destination revalidation metadata
  rejected_action: weaken or bypass the T-00.3 hash check
  prior_t003_raw_rewritten: false
final:
  focused_e1_pwsh: "58/58 pass; exit 0"
  focused_e1_windows_powershell: "58/58 pass; exit 0"
  wave_a_pwsh: "27/27 pass; exit 0"
  wave_a_windows_powershell: "27/27 pass; exit 0"
```

The seven new E1 artifact tests cover canonical READY, unlisted partial
`INVALID_RUN` history, premature T-00.4 authority, forbidden READY conclusion,
fixture drift, protected drift, and missing runtime surface. One new Wave A test
covers a copied legacy helper with no E1 helper. Two existing Wave A tests were
strengthened from six to seven validators and to require `P00-E1-READY` without
changing the test count.

### 23.3 T-00.3 destination revalidation

Adding the seventh validator changed `scripts/validate-template.ps1` from SHA-256
`8BC04E7B86C5DEA5F760874E1EABC749EAD080774D1CCB51BD43641269153BF2` to
`45ED1190CDB223C771DE24E6A46AC9E29D062893940BDCA9FFDB6AEB18CF402B`.
T-00.3 conclusion destination row 14 intentionally binds the entire validator, so
its first integration run failed with `P00-T003-EVIDENCE` and
`P00-T003-MANIFEST`. The correction updates only that destination hash and adds:

```yaml
destination_revalidation_timestamp: "2026-08-10T01:33:35.4242802+07:00"
destination_revalidation_reason: E1_VALIDATOR_REGISTRATION
```

The original implementation timestamp, legacy-source identities, dispositions,
other 14 destination hashes, checks, non-claims, and every prior raw artifact remain
unchanged. The T-00.3 conclusion moved from SHA-256
`E1B877F5594149F754E2299670F19C910E7C478B1606222D12B7B2A204A5631B` to
`69A1A7EC648A9CC2CC190DCE3B40E1D7601D184DAD7D490E617A82DC4FD807C9`.

### 23.4 Full regression and exact deltas

```yaml
phase00_suites:
  files: 7
  powershell_7_6_4: "286/286 pass; 0 failed; 0 skipped; exit 0"
  windows_powershell_5_1_26100_8875: "286/286 pass; 0 failed; 0 skipped; exit 0"
test_count_reconciliation:
  pre_e1_baseline: 227
  tasks_1_through_8_added: 51
  task9_added: 8
  current_total: 286
validator:
  powershell_7_6_4: "99 passed; 1 warning; 0 failed; exit 0"
  windows_powershell_5_1_26100_8875: "99 passed; 1 warning; 0 failed; exit 0"
validator_delta_from_pre_e1:
  passes: "+6 E1 category/aggregate results (93 -> 99)"
  warnings: "unchanged at 1"
  warning: "template/.omp/RULES.md approximate token budget below target (226 < 300)"
```

### 23.5 Identities, non-actions, and next gate

```yaml
evidence_helper:
  path: scripts/lib/phase00-e1-evidence.ps1
  before_sha256: F451DA623F5ADCC3B30AF16D37A438FF7FCFF62735870CC3B78F770537BEDA2F
  after_sha256: 0B0D38BFCCDED8980E8507E65DD39CC838C3A3FB6E4767447DC3FA5BD07B7C88
general_helper:
  path: scripts/lib/phase00-evidence.ps1
  before_sha256: 6972F5C3686747FD5D6A7EB86AA1A09C33A6A411569E87EA7F9C3DDC2CC80F94
  after_sha256: 403CD78585A4058986B280A07C7F2291488AFD79B3F3C513D6DAA667E6574BE5
validator:
  before_sha256: 8BC04E7B86C5DEA5F760874E1EABC749EAD080774D1CCB51BD43641269153BF2
  after_sha256: 45ED1190CDB223C771DE24E6A46AC9E29D062893940BDCA9FFDB6AEB18CF402B
focused_tests:
  before_sha256: 1ED0E4BF1BEC0DCD9F0B8B60584F1C9CF10EC0FAE273ADEB33CE9AB1A67C69C2
  after_sha256: C151358B051E0BABCEC5E9A124DA30D065695381CEFE97AA1A7DF24F941A303C
wave_a_tests:
  before_sha256: A8AD2B13EA2D368ACEAD7872A1066334722E028FCDD8AA98B5903FA503B2524D
  after_sha256: 68A1B58BC599D9FBA3B835412B7E2A86CFA164B5F0935BBCB4154DDF64CC57B4
plan:
  sha256: 927B96616E15ED27F21FA414D4FB5572F2CB1E8CD6A11574F2335040F500E592
  checkbox_steps: 97
  completed_steps: 64
  open_steps: 33
manifest:
  sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
  e1: READY
  t_00_4: NOT_STARTED
runner_unchanged_sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
forwarder_unchanged_sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
fixture_tree_unchanged_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
protected_paths_matched: 9/9
raw_e1_directory_exists: false
generated_e1_temp_roots_remaining: 0
targeted_forwarder_node_processes_remaining: 0
prompt_bearing_omp_process_attempts: 0
configured_omniroute_gateway_requests: 0
staged_paths: 0
template_changed_by_task9: false
manifest_changed_by_task9: false
joint_closure: false
```

Task 9 is Codex-complete, not jointly closed. Task 10 is the next action and remains
fully offline: parse/static checks, two consecutive focused runs per shell, all
Phase 00 suites, validators, identity rechecks, and checkpoint
`E1-OFFLINE-GREEN-001`. No provider process or configured gateway request is
authorized before that checkpoint is frozen.

## 24. E1-OFFLINE-GREEN-001 — frozen pre-provider gate

### 24.1 Gate audit found and repaired an untested public-surface defect

The unfinished-surface scan found that both public functions required by the
approved plan were still empty even though the then-current 58 tests passed:

```powershell
function Write-Phase00E1CaseRecord {}
function Write-Phase00E1Conclusion {}
```

Task 11 must persist one immutable case record after each accepted process, and
Task 12 must derive the conclusion without ad-hoc serialization. Freezing a provider
gate with those writers empty would have made the live wave depend on untested code
written after provider evidence existed. Under Task 10's rule permitting E1-owned
changes only after a focused failure proved a defect, Codex added four tests first.

```yaml
writer_red: "58/62 pass; 4 fail"
failure_causes:
  - case writer returned no identity and wrote no file
  - invalid top-level shape was accepted by the empty function
  - conclusion writer returned no identity and wrote no file
  - both public writer definitions were empty
```

The implementation now provides:

- deterministic recursive YAML serialization with ordered mappings, safe quoted
  strings, invariant numeric formatting, UTF-8 without BOM, and LF endings;
- exact canonical top-level fields for case records and conclusions;
- exact six matrix case-ID/artifact/filename binding;
- case status limited to `PASS|FAIL|BLOCKED_ENVIRONMENT|INVALID_RUN`;
- conclusion status limited to terminal `PASS|FAIL|BLOCKED_ENVIRONMENT`;
- `joint_closure:false` enforced rather than merely documented;
- nonempty raw references and reason codes for case records, and nonempty case/raw
  references for conclusions;
- secret-shaped text rejection before file creation;
- an existing-destination refusal and atomic `FileMode.CreateNew` write; and
- returned path, SHA-256, byte count, and line count.

Current anchors are:

- recursive serializer: `scripts/lib/phase00-e1-evidence.ps1:3873`;
- exclusive writer: `scripts/lib/phase00-e1-evidence.ps1:3999`;
- case writer: `scripts/lib/phase00-e1-evidence.ps1:4047`;
- conclusion writer: `scripts/lib/phase00-e1-evidence.ps1:4127`;
- durable READY validator after the insertion:
  `scripts/lib/phase00-e1-evidence.ps1:4292`;
- writer tests: `scripts/tests/phase00-e1.Tests.ps1:2970`.

Hardening chronology after the RED was:

```yaml
first_implementation: "59/62 pass"
corrections:
  - test assertions now inspect ErrorRecord.Exception.Message
  - sequence properties are read directly instead of through an enumerating helper boundary
second_intermediate: "60/62 pass"
third_intermediate: "61/62 pass"
last_test_defect: top-level-key regex omitted numeric characters in t_00_4 keys
final_green:
  powershell_7_6_4: "62/62 pass"
  windows_powershell_5_1_26100_8875: "62/62 pass"
```

### 24.2 Static and repetition gate

```yaml
powershell_ast_parse:
  files: 6
  powershell_7_6_4_errors: 0
  windows_powershell_5_1_26100_8875_errors: 0
node_check:
  path: scripts/lib/phase00-e1-forwarder.mjs
  exit: 0
fixture_validation:
  total_files: 14
  config_yaml: PASS
  agent_frontmatter: 7/7
  prompt_json_blocks: 6/6
unfinished_scan:
  todo_tbd_pending_not_implemented_placeholder_markers: 0
  empty_public_functions: 0
focused_repetition:
  powershell_7_6_4_run_1: "62/62 pass"
  powershell_7_6_4_run_2: "62/62 pass"
  windows_powershell_5_1_26100_8875_run_1: "62/62 pass"
  windows_powershell_5_1_26100_8875_run_2: "62/62 pass"
generated_e1_temp_roots_after_repetition: 0
targeted_forwarder_node_processes_after_repetition: 0
```

No focused repetition used the configured gateway. The forwarder relay test used
only its ephemeral fake loopback upstream; the lifecycle test sent no request to its
dormant target.

### 24.3 Clean-process full verification

```yaml
phase00_suites:
  files: 7
  powershell_7_6_4: "290/290 pass; 0 failed; 0 skipped; exit 0"
  windows_powershell_5_1_26100_8875: "290/290 pass; 0 failed; 0 skipped; exit 0"
count_reconciliation:
  pre_e1_baseline: 227
  current_e1_suite: 62
  task9_wave_a_legacy_fixture_addition: 1
  total: 290
validator:
  powershell_7_6_4: "99 passed; 1 warning; 0 failed; exit 0"
  windows_powershell_5_1_26100_8875: "99 passed; 1 warning; 0 failed; exit 0"
warning: "template/.omp/RULES.md approximate token budget below target (226 < 300)"
t003_evidence_and_manifest_results: PASS
```

### 24.4 Frozen identities

```yaml
design:
  lines: 551
  bytes: 25447
  sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
plan:
  lines: 736
  bytes: 40467
  sha256: 0997D9C7B2513DF865FB59194C10D1DDCF66FD8C27A1CE2CE42F441B50BBE141
  checkbox_steps: 97
  completed_steps: 69
  open_steps: 28
e1_helper:
  lines: 4466
  bytes: 187183
  sha256: 877FFA0B975081669DC1396F9164FA2EEB68CDBF559A0EB138561F6E686E03F3
runtime_helper:
  lines: 637
  bytes: 29972
  sha256: 90143F56236A0B4B24C2D680FCE33D0DAEA42DBB7F97A09D8F251069FAF9E9D7
general_helper:
  lines: 1877
  bytes: 94638
  sha256: 403CD78585A4058986B280A07C7F2291488AFD79B3F3C513D6DAA667E6574BE5
forwarder:
  lines: 382
  bytes: 12435
  sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
runner:
  lines: 18
  bytes: 555
  sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
focused_tests:
  lines: 3091
  bytes: 155949
  sha256: BABD7489D932E9BBFF4747ACF0A8FEB069D04E375870C1812A3156630C2FBB31
wave_a_tests:
  lines: 373
  bytes: 18071
  sha256: 68A1B58BC599D9FBA3B835412B7E2A86CFA164B5F0935BBCB4154DDF64CC57B4
validator:
  lines: 280
  bytes: 10211
  sha256: 45ED1190CDB223C771DE24E6A46AC9E29D062893940BDCA9FFDB6AEB18CF402B
t003_conclusion:
  lines: 197
  bytes: 9069
  sha256: 69A1A7EC648A9CC2CC190DCE3B40E1D7601D184DAD7D490E617A82DC4FD807C9
fixture:
  files: 14
  bytes: 7891
  tree_manifest_bytes: 1329
  tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
manifest:
  lines: 179
  bytes: 5266
  sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
```

### 24.5 Authority and non-actions at the gate

```yaml
normative_runtime:
  path: C:/Users/MrThien/AppData/Local/omp/omp.exe.1786250147823.24932.bak
  sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
  version: omp/17.2.10
  version_probe_exit: 0
pinned_source:
  commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  dirty_paths: 0
repository:
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  staged_paths: 0
protected_paths_matched: 9/9
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
raw_e1_directory_exists: false
e1_case_records: 0
e1_conclusion_exists: false
generated_e1_temp_roots_remaining: 0
targeted_forwarder_node_processes_remaining: 0
prompt_bearing_omp_process_attempts: 0
configured_omniroute_gateway_requests: 0
template_changed_by_task10: false
manifest_changed_by_task10: false
joint_closure: false
```

Historical checkpoint `E1-OFFLINE-GREEN-002` authorized Task 11's first live wave but
was not E1 PASS. It was consumed by `AgentJtd` attempt 1, which stopped the wave at
`INVALID_RUN`; it no longer authorizes another provider process. Section 27 freezes
the remediated future-attempt identities at `E1-OFFLINE-GREEN-003`.

---

## 25. Replacement offline gate: production raw-to-oracle closure

### 25.1 Ruling and scope

Checkpoint `E1-OFFLINE-GREEN-002` supersedes both the provisional
`E1-OFFLINE-GREEN-001` claim and the temporary
`E1-OFFLINE-GATE-REOPENED-001` state. The reopening was valid: prior code could
capture immutable sanitized artifacts and pure oracles could adjudicate normalized
objects, but no production function bound those two layers. That gap is now closed.

This checkpoint authorizes only Task 11's seven sequential first-wave processes. It
does not assert E1 PASS, change the manifest, start T-00.4, authorize parallelism,
or grant a retry after a non-PASS arm.

### 25.2 Test-first chronology

```yaml
initial_red:
  total: 71
  passed: 60
  failed: 11
  preserved_prior_green: 60/60
  missing_behavior:
    - pinned-source preflight and runner ordering
    - persisted-session private-field sanitization and typed yield-error classification
    - immutable run-envelope/artifact projection into AttemptEvidence
    - nested-leaf and persisted provider-retry attribution
    - yield-only strict projection with global request indexes preserved
    - deterministic ordinary and strict-pair record builders
intermediate_green:
  total: 71
  passed: 65
  failed: 6
  remaining_causes:
    - two record builders not yet implemented
    - multiple git.exe candidates not reduced to one executable
    - synthetic evidence root incorrectly used as the forwarder-source root
final_green:
  total: 71
  passed: 71
  failed: 0
  skipped: 0
```

The final test corpus adds nine focused tests over the provisional 62-test gate;
the full Phase 00 total therefore moves from 290 to 299 without changing any other
Phase 00 suite.

### 25.3 Exact implementation changes and evidence anchors

| Concern | Production anchor | Test/evidence anchor | Result |
|---|---|---|---|
| Persisted-session private data | `scripts/lib/phase00-e1-evidence.ps1:286`, sanitizer dispatch around `:360-432` | `scripts/tests/phase00-e1.Tests.ps1:679` | camelCase `systemPrompt`, `session_init.task`, and private tool-result prose are redacted; only typed `yield_schema_validation` survives |
| Pinned upstream source | `scripts/lib/phase00-e1-evidence.ps1:1267` | `scripts/tests/phase00-e1.Tests.ps1:316` | exact commit, clean tree, and exact origin are required; multiple installed `git.exe` candidates are deterministically reduced to one |
| Persisted provider turns | `scripts/lib/phase00-e1-evidence.ps1:2787` | raw projection suite at `scripts/tests/phase00-e1.Tests.ps1:2878` | persisted `type: message` records become provider-ledger events; recovered errors are superseded by their successful turn |
| Repository containment and artifact binding | `scripts/lib/phase00-e1-evidence.ps1:3017`, `:3085` | hash/traversal controls in the raw projection suite | canonical relative paths, no `.`/`..`/backslashes/rooted paths/reparse points, exact attempt path sets, SHA-256, line counts, JSON object shape, fixture hashes, and run-envelope totals are revalidated |
| Controller/child separation | `scripts/lib/phase00-e1-evidence.ps1:3405`, `:3547`, `:4076` | ordinary projection and provider-summary assertions | controller stdout and the persisted controller session are consistency-checked but excluded from the selected child ledger; process totals count every persisted session once |
| Nested session attribution | `scripts/lib/phase00-e1-evidence.ps1:3547` | nested-leaf and carrier-substitution controls | SessionOnly uses the carrier's direct nested task result and the leaf provider ledger; substituting the carrier is `INVALID_RUN` |
| Strict request attribution | `scripts/lib/phase00-e1-evidence.ps1:3547`, structural oracle at `:4858` | strict projection control | all forwarder requests bind to the process ledger; only `yield_tool_present: true` records bind to the child, retaining raw indexes `2` or `2,3` rather than renumbering them |
| Gateway boundary | runner setup at `scripts/lib/phase00-e1-evidence.ps1:4163`, envelope field at `:4514` | both strict synthetic arms | immutable envelope now records and projector requires `target_origin: http://127.0.0.1:20128`; forwarder source hash, Node hash shape, lifecycle, port closure, counts, and loopback endpoint are bound |
| Projection fail-closed handoff | `scripts/lib/phase00-e1-evidence.ps1:5116` | synthetic projector-conflict mutation | `Attempt`, `ProjectionStatus`, and `ProjectionReasonCodes` are mandatory oracle inputs; projector invalidity cannot be silently adjudicated as PASS |
| Deterministic derived records | ordinary builder at `scripts/lib/phase00-e1-evidence.ps1:5519`; strict pair at `:5685` | record suite at `scripts/tests/phase00-e1.Tests.ps1:3028` | supplied analyses are recomputed; records contain bounded summaries, selected/process ledgers, exact raw hashes, and no `RawResult`, private prompt, reasoning, or full provider body |

The projector also adds the run envelope itself to `RunRecord.RawArtifacts`, binds
required anchors to exact artifact lines, requires controller persisted-result
equality with stdout, rejects missing selected-session initialization or yield tool
results, and aggregates remaining child PIDs across OMP and the strict forwarder.

### 25.4 Frozen identities

```yaml
checkpoint: E1-OFFLINE-GREEN-002
design:
  lines: 551
  bytes: 25447
  sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
plan:
  lines: 741
  bytes: 41485
  sha256: 4F024EC8DAC6E0C63CE8C92CEBBA6BEA71270352D49911EED2CEC93648F58925
  checkbox_steps: 99
  completed_steps: 71
  open_steps: 28
e1_helper:
  lines: 6469
  bytes: 281490
  sha256: 1BE37E1C8E6453CDFA0318B1A4030D97E6939E7EEA83FEA53BC00630DA0C0E6D
focused_tests:
  lines: 3870
  bytes: 192810
  sha256: 2D514C4B852591A78F7AF8217448EA2F408680C26C334C7A097A3E752F8EA997
runner:
  lines: 18
  bytes: 555
  sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
forwarder:
  lines: 382
  bytes: 12435
  sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
fixture:
  files: 14
  bytes: 7891
  tree_manifest_bytes: 1329
  tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
manifest:
  lines: 179
  bytes: 5266
  sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
node:
  version: v24.16.0
  path: C:/Program Files/nodejs/node.exe
  sha256: B3094D0B49F9AD602262A9921551737BB97637C05DD357A06AE98188D7290AA3
```

### 25.5 Final offline verification

```yaml
parse:
  pwsh_7_6_4_changed_ps1_errors: 0
  windows_powershell_5_1_26100_8875_changed_ps1_errors: 0
node_check:
  exit: 0
fixture_contract:
  matched: true
  unfinished_markers: 0
focused_repeat:
  pwsh_7_6_4: ["71/71", "71/71"]
  windows_powershell_5_1_26100_8875: ["71/71", "71/71"]
phase00_all:
  pwsh_7_6_4: "299 passed; 0 failed; 0 skipped"
  windows_powershell_5_1_26100_8875: "299 passed; 0 failed; 0 skipped"
validator:
  pwsh_7_6_4: "99 passed; 1 warning; 0 failed; exit 0"
  windows_powershell_5_1_26100_8875: "99 passed; 1 warning; 0 failed; exit 0"
warning: "pre-existing advisory: template/.omp/RULES.md approximate token budget 226 < 300"
```

### 25.6 Boundary proof and disclosed anomaly

```yaml
repository:
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  staged_paths: 0
pinned_source:
  commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  clean: true
  origin: https://github.com/can1357/oh-my-pi.git
normative_runtime:
  sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
  version: omp/17.2.10
  isolated_version_probe_exit: 0
  isolated_version_probe_timed_out: false
  remaining_runtime_processes: 0
protected_paths_matched: 9/9
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
raw_e1_directory_exists: false
e1_case_records: 0
e1_conclusion_exists: false
current_gate_generated_temp_roots_remaining: 0
pre_existing_disclosed_task3_test_residue: 1
targeted_forwarder_node_processes_remaining: 0
prompt_bearing_omp_process_attempts: 0
configured_omniroute_gateway_requests: 0
template_changed_by_task10: false
manifest_changed_by_task10: false
joint_closure: false
```

One non-provider diagnostic invoked the pinned executable's `--version` directly
with the inherited live environment and produced no output before Codex terminated
that probe. No prompt was supplied, no evidence destination was created, and a
process audit immediately afterward found zero remaining pinned-runtime processes.
The runner-equivalent isolated `--version` probe then completed with exit 0 and the
exact `omp/17.2.10` identity. This diagnostic is not counted as a provider process.

The one absolute `phase00-e1-test-*` temp directory is the already-disclosed Task 3
malformed-line RED residue from section 19.3: one 129-byte synthetic file, created
before this gate. Host policy rejected its prior exact-path deletion before execution.
No current Task 10 test root remains, and Codex did not retry or circumvent deletion.

### 25.7 Opus review focus

Opus should independently challenge these load-bearing claims before joint closure:

1. persisted `message` normalization counts one provider request per assistant turn
   and applies recovered-error supersession in the correct order;
2. main-session/result equality and direct-result selection cannot accidentally
   attribute nested or duplicated controller data to the selected child;
3. strict process totals bind all forwarder projections while selected-child totals
   bind only yield-bearing projections with unchanged global indexes;
4. the safe record builders omit private/raw payloads while retaining every fact the
   ordinary, strict-arm, strict-pair, and matrix oracles need; and
5. `E1-OFFLINE-GREEN-002` historically authorized only the first Task 11 wave, was
   consumed by Attempt 1, and cannot be interpreted as E1 PASS or retry authority.

---

## 26. AgentJtd attempt 1: immutable INVALID_RUN and enforced stop

### 26.1 Authorization, preflight, and one-process execution

Attempt 1 used `E1-OFFLINE-GREEN-002` exactly once. Immediately before launch:

```yaml
case: AgentJtd
attempt: 1
frozen_offline_hash_mismatches: 0
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
runtime_version: omp/17.2.10
runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
protected_paths_matched: 9/9
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
destination_absent: true
git_index_staged_paths: 0
gateway_tcp_127_0_0_1_20128: reachable
parallel_mode: DISABLED
```

Exact invocation:

```powershell
& scripts/run-phase00-e1.ps1 -CaseId AgentJtd -Attempt 1 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

The runner defaulted to `omniroute/codex/gpt-5.6-sol-high`. One prompt-bearing OMP
process started at `2026-08-10T02:52:39.5962918+07:00`, completed at
`2026-08-10T02:53:11.8063954+07:00`, returned exit code 0, did not time out, and left
no child PID. Post-capture validation returned `INVALID_RUN`; the wrapper exited
nonzero with the expected instruction to inspect Attempt 1 and not rerun
automatically. Codex stopped before `AgentJsonSchema` and did not invoke Attempt 2.

### 26.2 Immutable raw identity

These five repository artifacts are the complete Attempt 1 set. Their bytes were not
changed during diagnosis or remediation.

| Artifact | Lines | Bytes | Repository SHA-256 | Disposable source-capture SHA-256 | Metadata status |
|---|---:|---:|---|---|---|
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-001.run.json` | 319 | 14,499 | `5152D1AECD37E1A0595D85366647A7F30F8F0692FBBBD882B031B234D16E17E2` | n/a | `INVALID_RUN` |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-001.stdout.jsonl` | 134 | 85,498 | `65FC9906ABFA60E51FC3176447EA2F092354D2618C7528E7DAB0F9CB79DA8298` | `EE6422A3DE8CB463439F93AA097F465847C7D123A59CDF33CFCC0C25715BAA7C` | `PASS` |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-001.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` | same empty-file hash | `PASS` |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-001.sessions/session-001.jsonl` | 12 | 9,891 | `EF0191150A03CC48D87CDB99ABE113204A99F5A304DBC3CBAFD75EEA732BB47C` | `CC976A89C32E9AC0782AC492D6630DC2BB37F1D5F5388AC6C758D584A8B72799` | `PASS` |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-001.sessions/session-002.jsonl` | 32 | 23,947 | `8669C36C681A91B4D38C475B22E54EDD2C388AFA1D95F74ECBB67D87735145E5` | `099794EDA792645BB91F2BBB1CD6DE315FEDD1A80A228AFD1F983945F0C19C78` | `INVALID_RUN` |

Run-envelope facts:

```yaml
capture_integrity_status: INVALID_RUN
reason_codes:
  - E1_SANITIZER_UNPARSEABLE_LINE
  - E1_UNEXPECTED_SESSION_ARTIFACT
case_status: null
case_oracle_evaluated: false
operation_error_type: null
process_exit_code: 0
process_timed_out: false
remaining_child_pids: []
session_jsonl_source_count: 2
session_unexpected_file_count: 1
capture_verification:
  status: PASS
  artifacts: 4
  source_lines: 178
  sanitized_lines: 178
cleanup: {required: true, attempted: true, succeeded: true}
protected_repository: {unchanged: true, before_all_expected: true, after_all_expected: true, changed_count: 0}
live_agent_home: {unchanged: true, changed_count: 0}
forwarder: {required: false, artifact_present: false}
```

The physical hash/line verification passed; the separate sanitizer and inventory
contracts invalidated the attempt. Therefore the successful process exit is not a
case PASS and has no manifest authority.

### 26.3 Provider ledger and bounded non-authoritative observation

| Observation carrier | Requests | Attributed | Retries | Provider/model | Counting role |
|---|---:|---:|---:|---|---|
| stdout controller | 2 | 2 | 0 | `omniroute` / `codex/gpt-5.6-sol-high` | actual parent requests |
| persisted controller `session-001` | 2 | 2 | 0 | same | duplicate persistence view; not an additional process count |
| selected child `session-002` | 7 | 7 | 0 | same | actual child requests |

Thus Attempt 1 used one provider process and nine actual provider requests: two
controller requests plus seven child requests. There were no retry starts, retry
ends, recovered errors, exhausted retries, terminal provider failures, or forwarder
requests.

The sanitized artifacts safely corroborate behavior, but it is not adjudicated:

- `attempt-001.stdout.jsonl:69-111` is the blocking `task` execution;
- `:111` reports agent `phase00-e1-agent-jtd`, exit 0, `aborted:false`, seven child
  requests, structured source `agent`, mode `permissive`, status `valid`, and exactly
  one data key, `sentinel: E1_AGENT_JTD`;
- `attempt-001.sessions/session-002.jsonl:29-31` is the terminal `yield`; `:31` is a
  non-error result with status `success` and exactly the same single sentinel key;
- the child tool sequence is `hub`, `read`, three reads, `hub`, `read`, `hub`, then
  `yield` across `:7-31`.

These observations must not be promoted into `case-1-agent-jtd.yml`: three child
source lines were replaced by fail-closed markers and the ancillary-file inventory
was wrong. Attempt 2 must independently reproduce any case fact.

### 26.4 Unexpected-artifact root cause

The old runner recursively treated every non-`.jsonl` file under the session tree as
unexpected. Pinned OMP creates two normal sibling artifacts for a blocking child:

- `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/executor.ts:2640-2644`
  assigns `${id}.jsonl` as the child session file; and
- the same file at `:2151-2165` writes `${id}.md` to the same artifacts directory.

Attempt 1 observed exactly two JSONL files and one other file. Cleanup correctly
deleted the disposable tree, so the ancillary filename is no longer recoverable from
raw bytes; source plus the exact one-file shape strongly corroborates the expected
child `.md`, but the ledger does not claim direct post-cleanup filename evidence.

The remediation at `scripts/lib/phase00-e1-evidence.ps1:4233` now classifies only a
regular `.md` with a same-directory, same-stem `.jsonl` sibling as expected. Orphan
markdown, `.patch`, `.txt`, any other extension, and reparse-point files remain
unexpected. This is bounded to the fixture's pinned `task.isolation.mode: none`; a
patch artifact would still invalidate E1. New envelopes record
`session_capture.expected_output_file_count` at `:4766`; the projector accepts the
field's absence only for immutable legacy schema-version-1 attempts such as Attempt 1.

### 26.5 Sanitizer root cause and historical reason-code correction

The three persisted markers are:

| Sanitized line | Historical marker | Source-line SHA-256 |
|---:|---|---|
| 18 | `invalid_json_line` | `833C5C5DDD83DFA94B6E63A48F19CF56C58250B9E7EB408F31B7ABB1C7BFA327` |
| 19 | `invalid_json_line` | `218022298D84DD3B889FE008F7E2663106682CE151EA300736D943564AA58168` |
| 25 | `invalid_json_line` | `B644154C1E98BAEEF231BE76A3D83D9F06911933C8C12AC55EBC3FDA32E8BFBD` |

They were not malformed JSON. Pinned source serializes every session entry through
`stringifyJson` and native `JSON.stringify` at
`packages/utils/src/json.ts:21-22`, then emits one JSON line at
`packages/coding-agent/src/session/session-manager.ts:742-758`.

The sanitized sequence also narrows the affected shape without recovering private
text: `session-002:13` contains three `read` calls, `:17` is the directory-style read
result that sanitized successfully, and `:18-19` are the remaining file-read results;
`:23` makes another `read` call and `:25` is its marker. Pinned `read` details include
`displayContent.text`, `startLine`, and numeric/null `lineNumbers` at
`packages/coding-agent/src/tools/read.ts:730-752` and `:2824-2834`.

An offline reproduction using this exact valid file-read shape established:

```yaml
ConvertFrom_Json: PASS
old_Protect_Phase00E1Value: THROW
exception_type: System.Management.Automation.RuntimeException
exception_message: "The property 'Name' cannot be found on this object."
trigger: numeric values from details.displayContent.lineNumbers
```

Under the supported PowerShell runtimes, those numeric values reached the broad
`[pscustomobject]` branch before any scalar guard; StrictMode then failed at
`$Value.PSObject.Properties.Name`. The old event-stream `try/catch` covered both JSON
parsing and recursive protection, so it mislabeled the sanitizer exception as
`E1_SANITIZER_UNPARSEABLE_LINE`.

Attempt 1's bytes and reason string remain immutable. The corrected interpretation is
`valid JSON + sanitizer processing failure`; it is still `INVALID_RUN`. Future parse
failures remain `E1_SANITIZER_UNPARSEABLE_LINE`, while recursive processing failures
are now `E1_SANITIZER_PROCESSING_ERROR` with a `sanitizer_processing_error` marker.

A separate valid-JSON case-collision hardening was discovered while falsifying the
first hypothesis. Standard PowerShell projection rejects objects containing keys such
as `A` and `a`, even though JSON keys are case-sensitive. The cross-version fallback
now preserves normal-parser behavior and replaces only an ambiguous object with a
typed marker. This was not the Attempt 1 root cause and is not presented as one.

### 26.6 Stop-gate non-actions

```yaml
next_case_invoked: false
agent_jtd_attempt_002_invoked: false
automatic_rerun: false
case_records_created: 0
conclusion_created: false
manifest_changed: false
template_or_product_changed: false
raw_attempt_001_rewritten: false
branch_created: false
worktree_created: false
staged_paths: 0
commit_push_pr: false
joint_closure: false
```

---

## 27. E1-OFFLINE-GREEN-003: post-attempt harness remediation

### 27.1 Test-first chronology

```yaml
pre_attempt_baseline: "71/71 focused pass in both shells"
inventory_and_case_collision_red:
  result: "71/73 pass; 2 fail"
  failures:
    - valid case-colliding JSON was classified INVALID_RUN
    - session inventory function was absent
intermediate:
  result: "72/73 pass; 1 fail"
  cause: one test asserted the existing nested content-marker shape at the wrong level
  correction: test-only assertion path; production bytes unchanged
first_green: "73/73 in both shells"
numeric_file_read_red:
  result: "73/74 pass; 1 fail"
  failure: valid file-read metadata threw inside the sanitizer
numeric_file_read_green: "74/74 in both shells"
truncation_privacy_red:
  result: "73/74 pass; 1 fail"
  failure: details.truncation.content duplicated private file text
truncation_privacy_green: "74/74 in both shells"
processing_metadata_red:
  result: "72/74 pass; 2 fail"
  failures:
    - stderr metadata lacked ProcessingErrorLines
    - raw projector did not independently reject a nonempty ProcessingErrorLines list
final_green: "74/74 in both shells"
provider_processes_during_task10a: 0
provider_requests_during_task10a: 0
cumulative_provider_processes: 1
cumulative_provider_requests: 9
```

The final focused total is three tests above checkpoint 002: case-colliding JSON,
file-read scalar/privacy behavior, and exact session ancillary-file inventory.
Additional truncation and metadata controls were folded into existing test blocks.

### 27.2 Exact implementation changes

| Concern | Production anchor | Test anchor | Result |
|---|---|---|---|
| Scalar/object boundary | `scripts/lib/phase00-e1-evidence.ps1:395` | `scripts/tests/phase00-e1.Tests.ps1:534` | JSON scalar value types return before object/enumerable traversal; numeric vectors remain typed and do not throw |
| Duplicate private read content | helper `:377`, `:404`, `:425` | test `:534-611` | `displayContent` is fully redacted; only `truncation.content` is redacted while safe truncation metrics survive; `meta.truncation` metrics remain available |
| Valid case-colliding JSON | helper `:473-550` | test `:490` | normal `ConvertFrom-Json` remains first; PowerShell 7 uses `-AsHashtable`, 5.1 uses `JavaScriptSerializer`; only the ambiguous object becomes a typed marker with key-set hash |
| Parse/processing separation | helper `:552-671` | file-read test plus static metadata mutations | malformed JSON and recursive sanitizer exceptions now have distinct markers, line lists, and reason codes |
| Stable processing metadata | helper `:2090`, projector check at `:3404` | tests `:2463-2464`, `:3167` | stdout/session/forwarder and stderr metadata expose `ProcessingErrorLines`; a nonempty list fails raw projection even if status text is forged PASS |
| Expected child output | helper `:4233-4275`, runner use at `:4478`, envelope `:4766` | test `:2086` | exact sibling `.md` accepted but never copied into repository evidence; every other ancillary shape stays fail-closed |
| Execution contract | plan `docs/superpowers/plans/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-plan.md:607-656` | full gate below | Attempt 1 is preserved, the first wave remains stopped, and Attempt 2 requires explicit user authority |

Unchanged load-bearing surfaces:

```yaml
runner_entrypoint_sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
forwarder_sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
runtime_helper_sha256: 90143F56236A0B4B24C2D680FCE33D0DAEA42DBB7F97A09D8F251069FAF9E9D7
general_phase00_helper_sha256: 403CD78585A4058986B280A07C7F2291488AFD79B3F3C513D6DAA667E6574BE5
fixture_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
design_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
```

### 27.3 Final offline verification

```yaml
powershell_ast_parse:
  files: 7
  pwsh_7_6_4_errors: 0
  windows_powershell_5_1_26100_8875_errors: 0
node_check:
  path: scripts/lib/phase00-e1-forwarder.mjs
  exit: 0
unfinished_markers: 0
focused_repeat:
  pwsh_7_6_4: ["74/74", "74/74"]
  windows_powershell_5_1_26100_8875: ["74/74", "74/74"]
phase00_all:
  files: 7
  pwsh_7_6_4: "302 passed; 0 failed; 0 skipped; exit 0"
  windows_powershell_5_1_26100_8875: "302 passed; 0 failed; 0 skipped; exit 0"
validator:
  pwsh_7_6_4: "99 passed; 1 warning; 0 failed; exit 0"
  windows_powershell_5_1_26100_8875: "99 passed; 1 warning; 0 failed; exit 0"
warning: "pre-existing advisory: template/.omp/RULES.md approximate token budget 226 < 300"
git_diff_check:
  exit: 0
  note: "Git emitted only the existing phase-00-foundation.md CRLF-to-LF advisory"
```

Count reconciliation: checkpoint 002 had 299 Phase 00 tests, including 71 focused
E1 tests. Three new focused tests produce 302 total; no other suite count changed.

### 27.4 Frozen identities and boundary proof

```yaml
checkpoint: E1-OFFLINE-GREEN-003
plan:
  lines: 767
  bytes: 44266
  sha256: C06445019B99F517B77A4324014CC4C979D122CAB389514FF10AEEE05ADF80CF
  checkbox_steps: 110
  completed_steps: 82
  open_steps: 28
e1_helper:
  lines: 6635
  bytes: 288856
  sha256: D75260914484CF155C3E2EE829E95C8C83A2E5FED2768159ED1C8F14FAFC8133
focused_tests:
  lines: 4049
  bytes: 201691
  sha256: FC95A553C1D8EC8CC8F74A1A7FC4B65ABD7E829EE114C1081BF91CD5D315811A
fixture:
  files: 14
  bytes: 7891
  tree_manifest_bytes: 1329
  tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
manifest:
  lines: 179
  bytes: 5266
  sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
  e1: READY
  t_00_4: NOT_STARTED
repository:
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  staged_paths: 0
pinned_source:
  commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  clean: true
  origin: https://github.com/can1357/oh-my-pi.git
normative_runtime:
  version: omp/17.2.10
  sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
  isolated_version_probe_exit: 0
  isolated_version_probe_timed_out: false
protected_paths_matched: 9/9
raw_e1_files: 5
raw_attempt_001_hashes_unchanged: 5/5
attempt_002_exists: false
case_records: 0
conclusion_exists: false
current_gate_generated_temp_roots: 0
targeted_forwarder_or_pinned_runtime_processes: 0
pre_existing_disclosed_task3_test_residue: 1
template_changed_by_attempt_or_task10a: false
manifest_changed_by_attempt_or_task10a: false
joint_closure: false
```

The pre-existing residue remains
`C:/Users/MrThien/AppData/Local/Temp/phase00-e1-test-2b369a91c65548c0a43d2aa4ffde062b`,
created `2026-08-09T23:02:56.6315582+07:00`, containing the previously disclosed
129-byte synthetic malformed-line fixture. No deletion was retried or circumvented.

### 27.5 Authority and exact next action

`E1-OFFLINE-GREEN-003` supersedes checkpoint 002 only for future harness/runtime
identity. It does not change Attempt 1, assert E1 PASS, authorize provider traffic,
or start T-00.4. The first wave remains stopped.

The next provider action is exactly `AgentJtd` attempt 2, with a fresh complete
preflight and a new no-overwrite destination, only after explicit user authorization.
The command may differ from the historical invocation only by `-Attempt 2`; prompt,
fixture, model, pinned source/runtime, execution order, and sequential stop gate remain
frozen. A non-PASS Attempt 2 stops again. Only a PASS permits `AgentJsonSchema`
attempt 1.

### 27.6 Optimized Opus review packet

Opus should read sections 26-27 first, then inspect only the cited raw envelopes,
source anchors, helper/test anchors, and immutable hashes. Review questions:

1. Does pinned executor source justify accepting only same-stem sibling `.md` output
   without weakening unexpected-artifact fail-closure?
2. Does the valid-JSON reproduction prove numeric `ValueType` traversal—not JSON
   parsing—caused the three historical markers, and is the new processing-error split
   sufficiently independently validated?
3. Are `displayContent` and `truncation.content` fully redacted without discarding
   oracle-relevant metrics or typed facts?
4. Does the case-collision fallback preserve ordinary parsing and fail safely across
   PowerShell 7/5.1 without being misrepresented as the Attempt 1 cause?
5. Are the five Attempt 1 files truly unchanged and correctly denied case/manifest
   authority despite the bounded sentinel observation?
6. Is explicit user authorization plus a fresh preflight sufficient and necessary
   for Attempt 2, with no automatic retry authority implied by checkpoint 003?

Codex requests peer agreement or a concrete counterexample with exact path, line,
raw fact, or falsifying test. No joint closure is requested at this checkpoint.

---

## 28. E1-AGENT-JTD-PASS-004: authorized AgentJtd attempt 2

### 28.1 Authorization scope and fresh complete preflight

The user explicitly confirmed the bootstrap `MATCH` and authorized exactly
`AgentJtd` attempt 2. The authorization required a fresh complete preflight, one
sequential attempt with no automatic retry, an immediate stop before
`AgentJsonSchema`, and a complete English changelog update. It did not authorize a
second provider case, implementation changes, a manifest transition, or E1 closure.

The final preflight, immediately before the provider process, was:

```yaml
preflight_verdict: MATCH
checkpoint_input: E1-OFFLINE-GREEN-003
case: AgentJtd
attempt: 2
authority_hashes_matched: 14/14
changelog_before_sha256: ADBC1ABBD846932B1F8D5AAD7DB4684D32685912E6BA299BCB85F3678DCAE500
plan_sha256: C06445019B99F517B77A4324014CC4C979D122CAB389514FF10AEEE05ADF80CF
design_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
e1_helper_sha256: D75260914484CF155C3E2EE829E95C8C83A2E5FED2768159ED1C8F14FAFC8133
focused_tests_sha256: FC95A553C1D8EC8CC8F74A1A7FC4B65ABD7E829EE114C1081BF91CD5D315811A
runner_sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
forwarder_sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
runtime_model_catalog_sha256: 56782B3FE9F3555C863062F5C92F398A3D147E3D6D4F39408BADD99751A5F779
fixture_files_matched: 14/14
fixture_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
pinned_source_origin: https://github.com/can1357/oh-my-pi.git
runtime_version: omp/17.2.10
runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
runtime_version_probe_exit: 0
protected_paths_matched: 9/9
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
attempt_001_hashes_unchanged: 5/5
attempt_002_destination_absent: true
case_records_before: 0
conclusion_before: false
omniroute_api_key_available: true
gateway_tcp_127_0_0_1_20128: reachable
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
current_gate_generated_temp_roots: 0
targeted_forwarder_or_pinned_runtime_processes: 0
parallel_mode: DISABLED
provider_requests_during_preflight: 0
```

The preflight audit exposed and corrected two measurement-only defects before any
provider execution. An initial expected hash for
`scripts/tests/phase00-wave-a.Tests.ps1` was manually transcribed as
`68A1B58BC5999F...` instead of the recorded and observed
`68A1B58BC599D9F...`. The first process query also matched its own PowerShell command
line because that command line contained the forwarder filename. A read-only
falsification proved the repository hash matched the checkpoint exactly, the sole
matched process was the probe itself, actual Node forwarders were zero, and pinned
runtime processes were zero. The corrected process check constrained the forwarder
match to Node executables and repeated the complete preflight. No repository bytes,
evidence destinations, provider requests, permissions, or processes were changed to
obtain the final `MATCH`.

### 28.2 One-process execution and enforced stop

Exact invocation:

```powershell
& scripts/run-phase00-e1.ps1 -CaseId AgentJtd -Attempt 2 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

The entrypoint used its frozen default model
`omniroute/codex/gpt-5.6-sol-high`; no overwrite or retry switch was present.

```yaml
runner_exit: 0
capture_integrity_status: PASS
capture_reason_codes: []
process_started_at: 2026-08-10T08:33:18.9501644+07:00
process_completed_at: 2026-08-10T08:34:06.9111195+07:00
duration_seconds: 47.9609551
process_exit_code: 0
process_timed_out: false
remaining_child_pids: []
session_jsonl_source_count: 2
session_expected_output_file_count: 1
session_unexpected_file_count: 0
capture_verification:
  status: PASS
  artifacts: 4
  source_lines: 166
  sanitized_lines: 166
cleanup: {required: true, attempted: true, succeeded: true}
protected_repository: {unchanged: true, before_all_expected: true, after_all_expected: true, changed_count: 0}
live_agent_home_unchanged: true
operation_error_type: null
forwarder_required: false
provider_process_attempts_this_execution: 1
actual_provider_requests: 7
controller_requests: 2
child_requests: 5
automatic_retries: 0
automatic_rerun: false
agent_json_schema_invoked: false
```

Provider/request ledger:

| Observation carrier | Requests | Attributed | Response ends | Retry starts/ends | Role |
|---|---:|---:|---:|---:|---|
| controller stdout | 2 | 2 | 2 | 0/0 | actual controller requests |
| persisted controller `session-001` | 2 | 2 | 2 | 0/0 | duplicate persistence view; excluded from the process total |
| selected child `session-002` | 5 | 5 | 5 | 0/0 | actual child requests |

Thus Attempt 2 used one provider process and seven actual provider requests: two
controller plus five child requests. Recovered retries, exhausted retries, and
terminal provider failures were all zero. Across Attempt 1 and Attempt 2, the E1
ledger is now two provider processes and sixteen actual provider requests. The wave
stopped after Attempt 2; eligibility of the next case was not treated as authority.

### 28.3 Immutable Attempt 2 raw identity

Attempt 2 created exactly five new sanitized repository artifacts. The expected
same-stem child `.md` output was counted in the disposable inventory but was not
copied into repository evidence. No ancillary artifact was unexpected.

| Artifact | Lines | Bytes | Repository SHA-256 | Disposable source-capture SHA-256 | Metadata status |
|---|---:|---:|---|---|---|
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-002.run.json` | 315 | 14,488 | `7C5AA7841DBA9B324B850AE766320B6D7F43DA11310A2077500AE575A6A53EF3` | n/a | `PASS` |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-002.stdout.jsonl` | 129 | 73,825 | `78F8466FD1A8017E939F35CA9BC329E1BA6D214934643EE8D2D690DB4C754F19` | `0454A43A042816DF35C807512109117205E5BFF84225E196413FA1FC8E720351` | `PASS` |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-002.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` | same empty-file hash | `PASS` |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-002.sessions/session-001.jsonl` | 11 | 8,831 | `5A7B432586F50E2E0C6FC8DC4DD5A435FF777C8AF89873D913CEF00DE21BDC51` | `84C7254B27ED6DD2972856184C8A5CB5766597F1EE6FEB392232652492A0890D` | `PASS` |
| `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-002.sessions/session-002.jsonl` | 26 | 19,001 | `6242C975075769FBD9850FCED14AFD077560E531CE805FF7A001F0517854FD19` | `A3DF7C510461B433A0A0E3779E51063803908C942A5B6BC10A68FF5F2DD52A4F` | `PASS` |

The raw E1 directory now contains exactly ten files and 249,980 bytes. All five
Attempt 1 hashes still match section 26.2, so the invalid historical attempt remains
byte-for-byte unchanged. Attempt 2 is now immutable and must not be normalized,
rewritten, or overwritten.

### 28.4 Offline oracle and canonical case record

After the provider process stopped, the already-green pure bridge was used in this
order:

```powershell
$evidence = Read-Phase00E1AttemptEvidence -RepositoryRoot $root -CaseId AgentJtd -Attempt 2
$analysis = Test-Phase00E1Attempt -CaseId AgentJtd -AttemptEvidence $evidence
$record = New-Phase00E1CaseRecord -CaseId AgentJtd -AttemptEvidence $evidence -Analysis $analysis
Write-Phase00E1CaseRecord -Path docs/evidence/phase-00/E1/case-1-agent-jtd.yml -Record $record
```

The deterministic result was:

```yaml
case_status: PASS
reason_codes: [E1_AGENT_JTD_PASS]
attempt: 2
attributable_result_count: 1
selected_result_role: target
agent: phase00-e1-agent-jtd
caller_schema_state: ABSENT
agent_schema_state: PRESENT
agent_schema_dialect: JTD
session_schema_state: ABSENT
child_initialization_source: agent
structured_source: agent
structured_mode: permissive
structured_status: valid
data_property_names: [sentinel]
expected_sentinel_matches: true
forbidden_property_present: false
schema_override_observable: false
schema_override_observed: false
blocking_definition: true
blocking_setup: true
execution_mode: blocking
async_acknowledgement: false
selected_session_requests: 5
process_requests: 7
controller_stdout_duplicates_excluded: true
```

Safe required-event anchors, without transcript reproduction:

- `attempt-002.stdout.jsonl:67` is the controller `task` call and `:102` is its
  attributable blocking result;
- `attempt-002.sessions/session-002.jsonl:5` is the selected child initialization;
- child provider turns are anchored at `:7`, `:10`, `:13`, `:20`, and `:23`;
- the selected terminal `yield` call is at `:23`, and its non-error result is at `:25`.

Canonical record identity:

```yaml
path: docs/evidence/phase-00/E1/case-1-agent-jtd.yml
lines: 105
bytes: 3654
sha256: BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4
status: PASS
attempt: 2
```

No Attempt 1 observation was promoted into this record. Every raw reference in the
record points only to Attempt 2.

### 28.5 Post-attempt validation and boundary proof

The focused artifact validator was invoked directly after record derivation. It
returned six PASS results and zero failures:

```yaml
artifact_contract:
  passed: 6
  failed: 0
  codes:
    - P00-E1-FIXTURE
    - P00-E1-RUNTIME
    - P00-E1-PROTECTED-SURFACE
    - P00-E1-MANIFEST
    - P00-E1-CONCLUSION
    - P00-E1-READY
  ready_message: "E1 READY is valid; 10 unlisted history file(s) have no terminal authority."
test_suites_rerun_after_attempt_2: 0
test_suite_basis: E1-OFFLINE-GREEN-003 remains the unchanged implementation/test checkpoint
```

No implementation, fixture, test, plan, design, runner, or validator source changed,
so the complete historical offline counts in section 27.3 remain the applicable code
gate; they are not misreported as newly rerun tests.

Current boundary:

```yaml
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
manifest_changed: false
conclusion_exists: false
case_records: 1
agent_json_schema_raw_or_case_paths: 0
protected_paths_matched: 9/9
template_changed: false
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
current_gate_generated_temp_roots: 0
targeted_forwarder_or_pinned_runtime_processes: 0
pre_existing_disclosed_task3_test_residue: 1
pre_existing_residue_files: 1
pre_existing_residue_bytes: 129
branch_worktree_commit_push_pr: false
joint_closure: false
```

The only new repository evidence outside this changelog is the five-file Attempt 2
set and `case-1-agent-jtd.yml`. The disclosed old synthetic residue was not deleted,
modified, permission-changed, or otherwise touched.

### 28.6 Authority and exact next action

`AgentJtd` is now an authoritative `PASS` matrix row backed solely by Attempt 2.
This does not make E1 `PASS`: five matrix records, including the two-arm strict case,
are still missing. E1 remains `READY`, T-00.4 remains `NOT_STARTED`, no conclusion
exists, and the manifest is byte-identical.

The next possible provider action is exactly `AgentJsonSchema` attempt 1. It is
eligible because `AgentJtd` passed, but it is not authorized. The user explicitly
required this turn to stop before that case. A future execution requires a fresh
complete preflight, a new no-overwrite destination, sequential execution, and a new
explicit user authorization. A non-PASS result must stop the wave again.

No Codex-only result creates joint closure. Opus review remains pending, and
`joint_closure` remains false.

### 28.7 Optimized Opus review packet

Read sections 26-28 first. Then inspect only the Attempt 2 run envelope, the five
hashes in section 28.3, `case-1-agent-jtd.yml`, and the cited projector/oracle anchors.
Review questions:

1. Does the final preflight genuinely match checkpoint 003 after the two documented
   measurement errors are removed without weakening any gate?
2. Do the Attempt 2 envelope and four sanitized streams support capture `PASS`, one
   expected sibling output, zero unexpected artifacts, and successful cleanup?
3. Does the pure projector select exactly one blocking target result with agent JTD
   provenance, valid sentinel-only data, and no schema override?
4. Is the request ledger correctly seven actual requests rather than nine, with the
   two persisted controller events excluded as duplicates?
5. Is `case-1-agent-jtd.yml` derived exclusively from Attempt 2 while Attempt 1 remains
   immutable and denied authority?
6. Did Codex stop before `AgentJsonSchema`, preserve E1 `READY` and T-00.4
   `NOT_STARTED`, and avoid any conclusion, manifest, template, or Git-index change?

Codex requests peer agreement or a concrete counterexample with an exact path, line,
raw fact, hash, or falsifying test. No joint closure is claimed.

## 29. E1-AGENT-JSON-SCHEMA-PASS-005: authorized AgentJsonSchema attempt 1

### 29.1 Authorization scope and disposition of the prior probe mismatch

After checkpoint 004, the user explicitly authorized exactly `AgentJsonSchema`
attempt 1, including its fresh complete preflight, one provider process, deterministic
projection/oracle, applicable canonical case record, focused validation, boundary
proof, and this English changelog update. The authorization did not include Attempt 2,
`CallerOnly`, any later provider case, conclusion derivation, a manifest transition,
T-00.4, implementation repair, branch/worktree creation, staging, commit, push, or PR.

The first authorization correctly stopped before provider execution when the temporary
read-only preflight reporter emitted a fixture-tree `MISMATCH`. Two earlier reporter
renderings had also stopped on PowerShell-only measurement errors: empty-array
scalarization under strict mode and an invalid cast around an `if` statement. None of
these probes created an attempt, sent a provider request, or changed repository bytes.

The reported aggregate mismatch was then isolated without changing the repository:

```yaml
fixture_files_matched: 14/14
tree_manifest_utf8_bytes: 1329
expected_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
temporary_probe_call: Get-Phase00E1StringSha256 -Value $treeText
temporary_probe_result: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
helper_parameter_contract: Get-Phase00E1StringSha256 -Text <string>
contract_correct_call: Get-Phase00E1StringSha256 -Text $treeText
contract_correct_result: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
repository_fixture_drift: false
provider_processes_during_probe_diagnosis: 0
provider_requests_during_probe_diagnosis: 0
repository_mutations_during_probe_diagnosis: 0
```

The helper is a simple PowerShell function whose declared parameter is `Text`; the
temporary reporter's unrecognized `-Value` token did not bind that parameter, so the
helper hashed an empty string. A paired bad-call/good-call reproduction on the same 14
fixture hashes proved the cause. The user then explicitly authorized continuation while
Opus remained quota-limited. Only the transient reporter invocation was corrected; no
plan, design, helper, test, runner, fixture, template, manifest, or evidence file was
repaired or rewritten.

### 29.2 Fresh complete preflight immediately before provider execution

The complete preflight was rerun from the beginning after the paired reproduction. Its
final verdict, immediately before the single provider process, was `MATCH`:

```yaml
preflight_verdict: MATCH
checkpoint_input: E1-AGENT-JTD-PASS-004
case: AgentJsonSchema
attempt: 1
authority_hashes_matched: 14/14
changelog_before_sha256: E5E03E199C13B97AE8FE0C3BBC7EE9ED7D50B8AA19916954FC4BD8DD81BB38D8
plan_sha256: C06445019B99F517B77A4324014CC4C979D122CAB389514FF10AEEE05ADF80CF
design_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
e1_helper_sha256: D75260914484CF155C3E2EE829E95C8C83A2E5FED2768159ED1C8F14FAFC8133
focused_tests_sha256: FC95A553C1D8EC8CC8F74A1A7FC4B65ABD7E829EE114C1081BF91CD5D315811A
runner_sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
forwarder_sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
runtime_model_catalog_sha256: 56782B3FE9F3555C863062F5C92F398A3D147E3D6D4F39408BADD99751A5F779
general_evidence_helper_sha256: 403CD78585A4058986B280A07C7F2291488AFD79B3F3C513D6DAA667E6574BE5
template_validator_sha256: 45ED1190CDB223C771DE24E6A46AC9E29D062893940BDCA9FFDB6AEB18CF402B
wave_a_tests_sha256: 68A1B58BC599D9FBA3B835412B7E2A86CFA164B5F0935BBCB4154DDF64CC57B4
t_00_3_conclusion_sha256: 69A1A7EC648A9CC2CC190DCE3B40E1D7601D184DAD7D490E617A82DC4FD807C9
fixture_files_matched: 14/14
fixture_tree_manifest_bytes: 1329
fixture_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
agent_jtd_case_record_sha256: BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4
agent_jtd_attempt_001_hashes: 5/5
agent_jtd_attempt_002_hashes: 5/5
agent_jtd_raw_files: 10
agent_jtd_raw_bytes: 249980
case_records_before: 1
conclusion_before: false
agent_json_schema_destinations_absent: true
agent_json_schema_prior_raw_or_case_paths: 0
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
protected_paths_matched: 9/9
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
pinned_source_origin: https://github.com/can1357/oh-my-pi.git
runtime_path: C:/Users/MrThien/AppData/Local/omp/omp.exe.1786250147823.24932.bak
runtime_version: omp/17.2.10
runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
runtime_version_probe_exit: 0
runtime_version_probe_timed_out: false
omniroute_api_key_available: true
gateway_tcp_127_0_0_1_20128: reachable
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
dirty_paths_with_untracked_expansion: 311
dirty_status_preserved_during_preflight: true
current_gate_generated_temp_roots: 0
targeted_forwarder_processes: 0
targeted_pinned_runtime_processes: 0
pre_existing_residue_files: 1
pre_existing_residue_bytes: 129
pre_existing_residue_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
parallel_mode: DISABLED
provider_requests_during_final_preflight: 0
```

The preflight artifact contract also returned six PASS results and no failures:
`P00-E1-FIXTURE`, `P00-E1-RUNTIME`, `P00-E1-PROTECTED-SURFACE`,
`P00-E1-MANIFEST`, `P00-E1-CONCLUSION`, and `P00-E1-READY`.

### 29.3 Exact one-process execution and cleanup

Exact invocation:

```powershell
& scripts/run-phase00-e1.ps1 `
  -CaseId AgentJsonSchema `
  -Attempt 1 `
  -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

The entrypoint used its unchanged frozen default model
`omniroute/codex/gpt-5.6-sol-high`. There was no overwrite switch, retry switch,
parallel dispatch, second attempt, or later-case invocation.

```yaml
runner_started_at: 2026-08-10T09:11:32.5211902+07:00
runner_completed_at: 2026-08-10T09:11:48.4277687+07:00
provider_process_started_at: 2026-08-10T09:11:33.7123572+07:00
provider_process_completed_at: 2026-08-10T09:11:47.8748192+07:00
provider_process_id: 8960
provider_process_attempts_this_authorization: 1
runner_exit: 0
provider_process_exit: 0
timed_out: false
capture_integrity_status: PASS
sanitizer_status: PASS
capture_reason_codes: []
cleanup_required: true
cleanup_attempted: true
cleanup_succeeded: true
cleanup_error_type: null
descendant_pids_observed: []
remaining_child_pids: []
session_jsonl_source_count: 2
session_expected_sibling_output_count: 1
session_unexpected_file_count: 0
protected_repository_unchanged: true
protected_repository_changed_count: 0
live_agent_home_unchanged: true
live_agent_home_before_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
live_agent_home_after_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
```

The capture persisted only sanitized evidence. No private prompt, reasoning,
credential, complete provider body, or private transcript content is reproduced here.

### 29.4 Actual provider-request and retry accounting

The raw-event ledgers distinguish the provider process from actual model requests and
exclude duplicate persisted views:

| Evidence view | Role | Request lines | Response-end lines | Requests counted in process total |
|---|---|---:|---:|---:|
| `attempt-001.stdout.jsonl` | controller stdout view | 6, 80 | 66, 90 | 0; duplicates of persisted controller session |
| `attempt-001.sessions/session-001.jsonl` | controller persisted session | 1, 3 | 2, 4 | 2 |
| `attempt-001.sessions/session-002.jsonl` | blocking child persisted session | 1 | 2 | 1 |

```yaml
provider_process_attempts: 1
actual_provider_requests: 3
controller_requests: 2
child_requests: 1
attributed_requests: 3
unattributed_requests: 0
response_ends: 3
retry_starts: 0
retry_ends: 0
recovered_retries: 0
retry_exhausted: 0
terminal_provider_failures: 0
provider: omniroute
model: codex/gpt-5.6-sol-high
controller_stdout_duplicates_excluded: 2
cumulative_e1_provider_process_attempts: 3
cumulative_e1_actual_provider_requests: 19
```

The selected child session ledger independently contains one attributed request, one
response end, zero retry, and zero terminal failure. The process ledger contains the
two controller requests plus that one child request. Adding the stdout controller view
again would incorrectly report five; the canonical record therefore explicitly marks
`controller_stdout_duplicates_excluded: true`.

### 29.5 New immutable raw artifacts and event anchors

These five files are the complete new immutable raw set:

| Path | Lines | Bytes | SHA-256 | Source-capture SHA-256 |
|---|---:|---:|---|---|
| `docs/evidence/phase-00/E1/raw/agent-json-schema/attempt-001.stdout.jsonl` | 92 | 36,056 | `A0E3F9487ECF4928F1555B526BF4812EB1AE276848DBB553FD008B97890A8337` | `9F52ADEF5AAF562CD5100DD99EBB5291ADB8B88D6A667CF1E75A6D33861EA16C` |
| `docs/evidence/phase-00/E1/raw/agent-json-schema/attempt-001.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` | same empty-file hash |
| `docs/evidence/phase-00/E1/raw/agent-json-schema/attempt-001.sessions/session-001.jsonl` | 10 | 7,501 | `B5B27039508960CBAE38A0C6EC5FCA3F59D1CC1089A016A2FA3C3DF7F3AAD5E7` | `BFD323609A3D4AAF72FC133ED24B6F252765AECCEEE3F536CB396422B6C9F8E2` |
| `docs/evidence/phase-00/E1/raw/agent-json-schema/attempt-001.sessions/session-002.jsonl` | 10 | 4,484 | `7BCB86989E6A687D7DB4593ECC6605C62D5A7BD71A07FF262B55239C5BCE0E8A` | `BA15E7B9E30BB6975F8ECD1325E500826E183C645988157D7AB16F45F35928E7` |
| `docs/evidence/phase-00/E1/raw/agent-json-schema/attempt-001.run.json` | 315 | 14,556 | `7BB2ABE88756A15E23B0B14BDFF918E973BB7868E4752992A5A9BD616DBA2C9E` | n/a |

```yaml
new_raw_files: 5
new_raw_lines: 427
new_raw_bytes: 62597
new_raw_hashes_verified_after_capture: 5/5
all_e1_raw_files_after_capture: 15
all_e1_raw_bytes_after_capture: 312577
```

The deterministic projector required these sanitized anchors:

```yaml
selected_session_init: attempt-001.sessions/session-002.jsonl:5
selected_provider_turn: attempt-001.sessions/session-002.jsonl:7
selected_yield_call: attempt-001.sessions/session-002.jsonl:7
selected_yield_result: attempt-001.sessions/session-002.jsonl:9
controller_task_call: attempt-001.stdout.jsonl:67
controller_task_result: attempt-001.stdout.jsonl:75
```

All ten prior AgentJtd raw files were rehashed after this capture: Attempt 1 remains
`5/5`, Attempt 2 remains `5/5`, and their combined size remains 249,980 bytes. The
prior canonical record remains SHA-256
`BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4`.
No prior raw or derived evidence was rewritten.

### 29.6 Deterministic projector, oracle, and canonical record

The approved raw projector returned `PASS` with no projection reason code. The pure
oracle returned:

```yaml
case: AgentJsonSchema
attempt: 1
case_verdict: PASS
reason_codes:
  - E1_AGENT_JSON_SCHEMA_PASS
attributable_result_count: 1
selected_result_role: target
agent: phase00-e1-agent-json-schema
is_async_acknowledgement: false
caller_schema_state: ABSENT
agent_schema_state: PRESENT
agent_schema_dialect: JSON_SCHEMA
session_schema_state: ABSENT
child_initialization_source: agent
schema_source: agent
schema_mode: permissive
structured_status: valid
data_property_names:
  - sentinel
expected_sentinel_matches: true
forbidden_property_present: false
schema_override_observable: false
schema_override_observed: false
blocking_execution_count: 1
blocking_role: target
definition_blocking: true
setup_blocking: true
execution_mode: blocking
```

Because the result was valid, attributable, and terminal, the canonical writer created
exactly:

```yaml
case_record: docs/evidence/phase-00/E1/case-1-agent-json-schema.yml
case_record_status: PASS
case_record_lines: 105
case_record_bytes: 3748
case_record_sha256: 56A7270C18EBC4BFEAE0AF1B7A9D98B75B2BD165CD2290CF7126B459BF10C33B
regenerated_canonical_sha256: 56A7270C18EBC4BFEAE0AF1B7A9D98B75B2BD165CD2290CF7126B459BF10C33B
deterministic_byte_identity: true
```

The record was derived from Attempt 1 only. The canonical writer used create-new
semantics, and no overwrite or manual YAML editing occurred.

### 29.7 Focused artifact validation and boundary proof

The focused artifact contract was run after record creation and returned six PASS
results with zero failures:

```yaml
artifact_contract:
  - P00-E1-FIXTURE: PASS
  - P00-E1-RUNTIME: PASS
  - P00-E1-PROTECTED-SURFACE: PASS
  - P00-E1-MANIFEST: PASS
  - P00-E1-CONCLUSION: PASS
  - P00-E1-READY: PASS
new_raw_hashes: 5/5
prior_agent_jtd_raw_hashes: 10/10
static_authority_hashes_before_changelog_update: 14/14
case_record_deterministic_identity: PASS
```

No implementation or test file changed, so no historical test count is presented as a
new test run. The unchanged `E1-OFFLINE-GREEN-003` implementation/test checkpoint and
the fresh artifact contract remain distinct evidence layers.

Current boundary after adjudication:

```yaml
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
manifest_changed: false
conclusion_exists: false
case_records: 2
protected_paths_matched: 9/9
template_or_product_protected_changes: 0
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
current_gate_generated_temp_roots: 0
targeted_forwarder_or_pinned_runtime_processes: 0
pre_existing_residue_files: 1
pre_existing_residue_bytes: 129
pre_existing_residue_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
implementation_changed: false
fixture_changed: false
tests_changed: false
plan_changed: false
design_changed: false
template_changed: false
manifest_changed: false
branch_worktree_stage_commit_push_pr: false
joint_closure: false
```

The only authorized repository mutations in this checkpoint are the five new immutable
raw files, `case-1-agent-json-schema.yml`, and this changelog update. The disclosed old
synthetic residue was not deleted, modified, permission-changed, or otherwise touched.

### 29.8 Mandatory stop and exact next eligible action

`AgentJsonSchema` is now an authoritative `PASS` matrix row. This does not make E1
`PASS`: `CallerOnly`, `CallerOverAgent`, `SessionOnly`, and the paired provider-strict
record remain absent. E1 therefore remains `READY`, T-00.4 remains `NOT_STARTED`, no
conclusion exists, and the manifest is byte-identical.

The next possible provider action is exactly `CallerOnly` attempt 1. It is eligible
because both agent-schema cases passed, but it is not authorized. This authorization
was consumed by AgentJsonSchema Attempt 1 and required an immediate stop regardless of
verdict. No AgentJsonSchema Attempt 2, CallerOnly, later matrix case, strict arm,
conclusion, manifest transition, or T-00.4 action ran.

Opus remains quota-limited, so review is deferred rather than waived. No Codex-only
result creates joint closure; `joint_closure` remains false.

### 29.9 Optimized Opus audit packet

Recommended reading order:

1. section 29.1 for the exact temporary-probe root cause and paired reproduction;
2. section 29.2 for the final preflight and frozen identities;
3. `attempt-001.run.json` and the five hashes in section 29.5;
4. the six event anchors in section 29.5;
5. `case-1-agent-json-schema.yml` and the oracle facts in section 29.6;
6. section 29.7 for immutability, artifact-contract, and stop-boundary proof.

Concrete review questions:

1. Does the paired `-Value`/`-Text` reproduction prove that the earlier empty-input
   hash was solely a reporter invocation error, not fixture drift or a weakened gate?
2. Does the final preflight independently re-establish every checkpoint-004 identity,
   including all ten JTD raw hashes, before any AgentJsonSchema provider request?
3. Do the run envelope and sanitized streams prove exactly one provider process,
   successful cleanup, zero remaining children, and no unexpected session artifact?
4. Is the actual request count correctly three: two controller requests from persisted
   session 001 plus one blocking-child request from session 002, with the two stdout
   controller views excluded rather than double-counted?
5. Does the projector select exactly one blocking target result with agent JSON Schema
   provenance, permissive mode, valid sentinel-only data, and no override or forbidden
   property?
6. Is `case-1-agent-json-schema.yml` byte-for-byte reproducible from immutable Attempt 1
   evidence and isolated from all prior JTD evidence?
7. Did Codex preserve all static/protected/manifest/Git/temp/process/residue boundaries
   and stop before `CallerOnly` despite its newly eligible status?

Codex requests peer agreement or a concrete counterexample with an exact path, line,
raw fact, hash, or falsifying test. No joint closure is claimed.

## 30. CallerOnly Attempt 1: Complete Preflight, Immutable INVALID_RUN, and Mandatory Stop

Checkpoint: `E1-CALLER-ONLY-INVALID-RUN-006`.

This section records the complete fresh preflight, the single authorized CallerOnly
provider process, its fail-closed `INVALID_RUN` disposition, exact immutable artifacts,
post-attempt boundaries, and the mandatory stop before `CallerOverAgent`. It does not
reproduce private prompt text, message content, reasoning, credentials, provider
bodies, or any unsanitized transcript content.

### 30.1 Authorization scope and sequential stop contract

While Opus remained quota-limited, the user authorized Codex to continue the existing
locked E1 workflow. At checkpoint 005 the only eligible next process was `CallerOnly`
attempt 1. The authorization was therefore consumed by exactly this bounded sequence:

1. run a fresh complete preflight from the beginning;
2. stop without a provider process if any locked fact mismatched;
3. if and only if the preflight matched, run `CallerOnly` attempt 1 once;
4. perform no automatic retry;
5. project and adjudicate only if capture integrity passed;
6. stop after the result and update this English audit ledger.

The authorization did not include `CallerOnly` attempt 2, `CallerOverAgent`, any later
matrix case, either provider-strict arm, conclusion derivation, a manifest transition,
T-00.4, harness repair, branch/worktree creation, staging, commit, push, or PR. Parallel
provider execution remained disabled.

### 30.2 Measurement-only reporter fault and final complete preflight

The first fresh read-only preflight reporter completed its substantive checks but
stopped while rendering the message for an empty artifact-failure collection. Under
PowerShell StrictMode, direct member access on that empty collection
(`$artifactFailures.Code`) threw `System.Management.Automation.RuntimeException`.
This was a temporary reporting expression, not the E1 artifact contract, fixture,
runner, sanitizer, or provider process.

A paired offline reproduction established the reporting cause:

```yaml
input_collection_count: 0
strict_mode_direct_property_access_threw: true
direct_property_access_error_type: System.Management.Automation.RuntimeException
pipeline_property_projection_count: 0
repository_mutations_during_reproduction: 0
provider_processes_during_reproduction: 0
provider_requests_during_reproduction: 0
```

The reporter used an empty-safe pipeline projection and the complete preflight was
then rerun from the beginning. Its final verdict immediately before execution was
`MATCH`:

```yaml
preflight_verdict: MATCH
checkpoint_input: E1-AGENT-JSON-SCHEMA-PASS-005
case: CallerOnly
attempt: 1
authority_identities_matched: 15/15
changelog_before_sha256: FAC967E347ED7C389469C26E5210F81E7DEC925C84888EEFD20B886715ACA44B
design_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
plan_sha256: C06445019B99F517B77A4324014CC4C979D122CAB389514FF10AEEE05ADF80CF
e1_helper_sha256: D75260914484CF155C3E2EE829E95C8C83A2E5FED2768159ED1C8F14FAFC8133
focused_tests_sha256: FC95A553C1D8EC8CC8F74A1A7FC4B65ABD7E829EE114C1081BF91CD5D315811A
runner_sha256: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
forwarder_sha256: 9C88E5EA28991A9FD0FD67992E41D02B6FF2E2093752E5FB5351052A593ED952
runtime_model_catalog_sha256: 56782B3FE9F3555C863062F5C92F398A3D147E3D6D4F39408BADD99751A5F779
general_evidence_helper_sha256: 403CD78585A4058986B280A07C7F2291488AFD79B3F3C513D6DAA667E6574BE5
template_validator_sha256: 45ED1190CDB223C771DE24E6A46AC9E29D062893940BDCA9FFDB6AEB18CF402B
wave_a_tests_sha256: 68A1B58BC599D9FBA3B835412B7E2A86CFA164B5F0935BBCB4154DDF64CC57B4
t_00_3_conclusion_sha256: 69A1A7EC648A9CC2CC190DCE3B40E1D7601D184DAD7D490E617A82DC4FD807C9
fixture_files_matched: 14/14
fixture_bytes: 7891
fixture_tree_manifest_bytes: 1329
fixture_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
agent_jtd_case_record_sha256: BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4
agent_json_schema_case_record_sha256: 56A7270C18EBC4BFEAE0AF1B7A9D98B75B2BD165CD2290CF7126B459BF10C33B
prior_case_records_reprojected_and_oracled: 2/2 PASS
prior_case_records_regenerated_byte_identical: 2/2
prior_raw_hashes_matched: 15/15
prior_raw_files: 15
prior_raw_bytes: 312577
case_records_before: 2
conclusion_before: false
caller_only_destinations_absent: true
caller_only_prior_raw_or_case_paths: 0
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
artifact_contract_results: 6/6 PASS
protected_paths_matched: 9/9
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
runtime_path: C:/Users/MrThien/AppData/Local/omp/omp.exe.1786250147823.24932.bak
runtime_version: omp/17.2.10
runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
omniroute_api_key_available: true
gateway_tcp_127_0_0_1_20128: reachable
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
dirty_paths_with_untracked_expansion: 317
dirty_status_preserved_during_preflight: true
current_gate_generated_temp_roots: 0
targeted_forwarder_or_pinned_runtime_processes: 0
pre_existing_residue_files: 1
pre_existing_residue_bytes: 129
pre_existing_residue_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
parallel_mode: DISABLED
provider_requests_during_final_preflight: 0
```

The six preflight artifact-contract results were `P00-E1-FIXTURE`,
`P00-E1-RUNTIME`, `P00-E1-PROTECTED-SURFACE`, `P00-E1-MANIFEST`,
`P00-E1-CONCLUSION`, and `P00-E1-READY`, all `PASS`. The measurement-only reporter
fault created no attempt and did not weaken or substitute for this final preflight.

### 30.3 Exact one-process execution and cleanup

Exact invocation:

```powershell
& scripts/run-phase00-e1.ps1 `
  -CaseId CallerOnly `
  -Attempt 1 `
  -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

The omitted optional `-Model` parameter resolved to its locked default,
`omniroute/codex/gpt-5.6-sol-high`. The public entrypoint exited `1` only after the
runner had durably recorded `INVALID_RUN` and deliberately threw the mandatory-stop
message. The OMP provider process itself exited `0`.

```yaml
provider_process_attempts_this_authorization: 1
automatic_retry_invocations: 0
runner_entrypoint_exit: 1
runner_started_at: 2026-08-10T09:47:17.1950727+07:00
runner_completed_at: 2026-08-10T09:47:30.8045122+07:00
runner_duration_seconds: 13.609440
provider_process_id: 33828
provider_process_started_at: 2026-08-10T09:47:18.3848692+07:00
provider_process_completed_at: 2026-08-10T09:47:30.0987805+07:00
provider_process_duration_seconds: 11.713911
provider_process_exit: 0
timed_out: false
launch_invoked: true
argument_count: 23
prompt_sha256: 5D6F452B7AD069CB09070EC7C297BD533F0F0E17B3565C3C82A216C71541BF17
model: omniroute/codex/gpt-5.6-sol-high
descendant_pids_observed: []
remaining_child_pids: []
cleanup_required: true
cleanup_attempted: true
cleanup_succeeded: true
cleanup_error_type: null
operation_error_type: null
session_jsonl_source_count: 2
session_expected_sibling_output_count: 1
session_unexpected_file_count: 0
protected_repository_unchanged: true
protected_repository_changed_count: 0
live_agent_home_unchanged: true
live_agent_home_before_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
live_agent_home_after_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
```

Only sanitized repository evidence survived verified cleanup. No private prompt,
message content, reasoning, credential value, complete provider body, or unsanitized
transcript line is copied into this ledger.

### 30.4 Capture-integrity failure and retained diagnostic anchors

The run envelope records an integrity disposition, not a matrix-case oracle result:

```yaml
capture_integrity_status: INVALID_RUN
capture_reason_codes:
  - E1_SANITIZER_PROCESSING_ERROR
case_oracle_evaluated: false
case_status: null
```

The capture-verification layer still returned `PASS` for four sanitized artifacts,
143 source lines, and 143 retained sanitized lines. That narrower result proves the
stored artifact count, line preservation, and hash binding; it cannot override the
stdout sanitizer's `INVALID_RUN` status.

The sole failing sanitizer anchor is the typed marker at sanitized stdout line 6:

```yaml
marker_type: phase00_e1_redaction
marker_redacted: sanitizer_processing_error
error_type: System.Management.Automation.RuntimeException
source_line: 6
source_line_sha256: 46F025E51AD4848CF1CED22CFF587F13BF5C39D53757B5866B794D521AB3E12F
stdout_source_capture_sha256: E766CDA06DC053E0F01F256164601CC00CCB569AE4F6D4D7D12DA54C3C61E389
stdout_sanitized_sha256: 0642E3B13EE3D873B15886C1BBB4C06042EE659462DB2F70E80A7F51B1F3C767
stdout_source_lines: 123
stdout_sanitized_lines: 123
malformed_lines: []
invalid_shape_lines: []
processing_error_lines: [6]
credential_shaped_lines: []
```

All other retained streams passed sanitization: empty stderr and both persisted
session JSONL files. Because the unsanitized disposable source was correctly removed
after capture and only its SHA-256 remains, the exact source-line value that triggered
the generic runtime exception cannot be reconstructed from retained evidence. This
checkpoint therefore does not speculate that the trigger matches either prior JTD
harness defect. The proven root-cause boundary is limited to sanitizer processing of
stdout source line 6; exact trigger diagnosis requires a new offline checkpoint and
must not rewrite or rerun this attempt.

### 30.5 Actual provider-request and retry accounting

The run envelope explicitly marks its provider observations as per-artifact and not
deduplicated. The persisted sessions are therefore authoritative for the process
total; the controller stdout view is excluded as a duplicate view.

| Evidence view | Role | Retained provider-message source lines | Requests | Response ends | Counted in process total |
|---|---|---|---:|---:|---:|
| `attempt-001.stdout.jsonl` | controller stdout duplicate | start 111; ends 96 and 121; source line 6 is an integrity marker | 1 observable | 2 | 0 |
| `attempt-001.sessions/session-001.jsonl` | controller persisted session | 6, 9 | 2 | 2 | 2 |
| `attempt-001.sessions/session-002.jsonl` | named blocking child persisted session | 7 | 1 | 1 | 1 |

```yaml
provider_process_attempts: 1
actual_provider_requests: 3
controller_requests: 2
child_requests: 1
attributed_requests: 3
unattributed_requests: 0
response_ends: 3
retry_starts: 0
retry_ends: 0
recovered_retries: 0
retry_exhausted: 0
terminal_provider_failures: 0
provider: omniroute
model: codex/gpt-5.6-sol-high
controller_stdout_duplicates_excluded: true
cumulative_e1_provider_process_attempts: 4
cumulative_e1_actual_provider_requests: 22
```

The cumulative request total is the immutable JTD Attempt 1 count `9`, JTD Attempt 2
count `7`, AgentJsonSchema Attempt 1 count `3`, and CallerOnly Attempt 1 count `3`.
No retry event or terminal provider failure appears in either authoritative CallerOnly
persisted-session ledger.

### 30.6 New immutable raw artifacts

These five files are the complete new CallerOnly raw set:

| Path | Lines | Bytes | SHA-256 | Source-capture SHA-256 |
|---|---:|---:|---|---|
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-001.stdout.jsonl` | 123 | 40,569 | `0642E3B13EE3D873B15886C1BBB4C06042EE659462DB2F70E80A7F51B1F3C767` | `E766CDA06DC053E0F01F256164601CC00CCB569AE4F6D4D7D12DA54C3C61E389` |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-001.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` | same empty-file hash |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-001.sessions/session-001.jsonl` | 10 | 7,183 | `AB07175B14AF2C6B6E2782589127ADC14AAFBB4075613FC9F8D06E96080777B8` | `48FDC165B4FBE69CC4590E4A002B670E3565D66F115DB243EE06703EABEC7076` |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-001.sessions/session-002.jsonl` | 10 | 4,398 | `EDA0B6D39C41EF103383B6A6C84E768F4CC6C60D93C9A4F8FA0C37C88D794878` | `A5875E61475FB48BA9157F0A40AE6D26A3E5AD18E388F51F2A308E5D9EA94CD8` |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-001.run.json` | 321 | 14,631 | `C760778273BE41E1DFA20FA1BDAEFFB2D2A2FDF72B8600A54151956E865AD03C` | n/a |

```yaml
session_001_source_relative_path_sha256: C300EC2B8EBE5C5C59D9E91DB38FB5B8A1DB985214CF31BDE499B59DC5BCD928
session_002_source_relative_path_sha256: 55C74316C868EE333DEF7E125E46C421C1C648557CECC03628FDAF3546D83FBC
new_raw_files: 5
new_raw_lines: 464
new_raw_bytes: 66781
new_raw_hashes_verified_after_capture: 5/5
prior_raw_hashes_reverified_after_capture: 15/15
all_e1_raw_files_after_capture: 20
all_e1_raw_bytes_after_capture: 379358
```

No artifact was overwritten. The fifteen prior raw files, both existing canonical
records, and all static authority files remained at their preflight hashes.

### 30.7 Fail-closed projection and adjudication

The approved filesystem projector was invoked read-only against the immutable attempt
and rejected it before semantic extraction with the exact guard:

```yaml
projector_entrypoint: Read-Phase00E1AttemptEvidence
projector_threw: true
projector_error: E1_RUN_ENVELOPE_CAPTURE_NOT_PASS
projector_error_type: System.Management.Automation.RuntimeException
pure_case_oracle_invoked: false
case_record_writer_invoked: false
attempt_disposition: INVALID_RUN
reason_codes:
  - E1_SANITIZER_PROCESSING_ERROR
canonical_case_record: absent
```

This is the intended fail-closed boundary. The persisted sessions are sufficient for
sanitized process/request accounting, but they do not repair the failed stdout capture
and cannot authorize a semantic CallerOnly verdict. `case_status` therefore remains
`null`, no `case-2-caller-only.yml` exists, and the attempt has no conclusion or
manifest power.

### 30.8 Fresh artifact validation and boundary proof

The focused artifact contract was rerun after capture and returned six PASS results
with zero failures:

```yaml
artifact_contract:
  - P00-E1-FIXTURE: PASS
  - P00-E1-RUNTIME: PASS
  - P00-E1-PROTECTED-SURFACE: PASS
  - P00-E1-MANIFEST: PASS
  - P00-E1-CONCLUSION: PASS
  - P00-E1-READY: PASS
ready_message: "E1 READY is valid; 20 unlisted history file(s) have no terminal authority."
prior_raw_hashes: 15/15
new_raw_hashes: 5/5
raw_hash_mismatches: 0
static_authority_files_before_changelog_update: 14/14
fixture_tree_identity: 1/1
combined_authority_identities_before_changelog_update: 15/15
```

Current boundary after adjudication:

```yaml
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1: READY
manifest_t_00_4: NOT_STARTED
manifest_changed: false
conclusion_exists: false
case_records: 2
case_record_names:
  - case-1-agent-jtd.yml
  - case-1-agent-json-schema.yml
caller_only_case_record_exists: false
caller_only_attempt_002_paths: 0
later_provider_raw_roots_existing: []
protected_paths_matched: 9/9
template_or_product_protected_changes: 0
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
runtime_version: omp/17.2.10
runtime_version_probe_exit: 0
runtime_version_probe_stderr_present: false
runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
dirty_paths_with_untracked_expansion_after_capture: 322
current_gate_generated_temp_roots: 0
targeted_forwarder_or_pinned_runtime_processes: 0
pre_existing_residue_files: 1
pre_existing_residue_bytes: 129
pre_existing_residue_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
implementation_changed: false
fixture_changed: false
tests_changed: false
plan_changed: false
design_changed: false
template_changed: false
manifest_changed: false
branch_worktree_stage_commit_push_pr: false
joint_closure: false
```

The only authorized repository mutations in checkpoint 006 are the five immutable
CallerOnly raw files and this changelog update. The disclosed old synthetic residue at
`C:/Users/MrThien/AppData/Local/Temp/phase00-e1-test-2b369a91c65548c0a43d2aa4ffde062b`
remains one 129-byte `malformed-source.jsonl` file at SHA-256
`C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817`;
it was not deleted, modified, permission-changed, or otherwise touched.

### 30.9 Mandatory stop and exact next eligible action

The first non-PASS stop gate fired at CallerOnly Attempt 1. Consequently:

```yaml
sequential_wave_state: STOPPED
caller_only_attempt_001: INVALID_RUN
caller_only_attempt_002_run: false
caller_over_agent_run: false
session_only_run: false
provider_strict_off_control_run: false
provider_strict_on_run: false
conclusion_generated: false
manifest_transition_applied: false
next_provider_case_eligible: false
next_provider_action_authorized: false
```

`CallerOverAgent` is not eligible because its immediately preceding CallerOnly matrix
row did not produce an authoritative `PASS`. The next permissible work is offline,
read-only diagnosis of the sanitizer processing failure. Any remediation must be
test-first, preserve Attempt 1 byte-for-byte, complete a separately reviewed offline
checkpoint, and receive new explicit user authorization before a replacement attempt.
No automatic retry or inferred continuation is permitted.

Opus review is deferred because its quota is unavailable; it is not waived. Codex's
process report does not create joint closure, and `joint_closure` remains false.

### 30.10 Optimized Opus audit packet

Recommended reading order:

1. section 30.2 for authorization, the measurement-only reporter fault, and the final
   complete `MATCH` preflight;
2. `attempt-001.run.json` plus the five immutable hashes in section 30.6;
3. the typed stdout line-6 marker and its source-line hash in section 30.4;
4. the two persisted-session ledgers and deduplicated request accounting in section
   30.5;
5. the projector guard and absent case record in section 30.7;
6. section 30.8 for raw immutability, artifact-contract, manifest, protected-surface,
   process, temp, Git, and residue boundaries;
7. section 30.9 for the replacement-attempt authority contract.

Concrete review questions:

1. Does the paired empty-collection reproduction prove the initial preflight stop was
   limited to reporter rendering and that the final preflight reran every locked check?
2. Do the run envelope and stdout artifact metadata require
   `INVALID_RUN/E1_SANITIZER_PROCESSING_ERROR` despite the narrower four-artifact
   capture-verification result being `PASS`?
3. Is the diagnostic claim correctly bounded to stdout source line 6 without inventing
   an exact trigger that the retained sanitized evidence cannot prove?
4. Is the process request count correctly three from persisted session 001 (`2`) plus
   persisted session 002 (`1`), with the stdout controller view excluded?
5. Does `E1_RUN_ENVELOPE_CAPTURE_NOT_PASS` correctly prevent semantic projection,
   oracle evaluation, and creation of `case-2-caller-only.yml`?
6. Are all twenty raw files, both canonical records, the fixture tree, manifest,
   protected surfaces, pinned source/runtime, Git index, temp roots, and process
   boundaries accounted for without mutation or double counting?
7. Did Codex stop before `CallerOverAgent` and leave any replacement attempt dependent
   on a new offline checkpoint plus explicit authorization?

Codex requests peer agreement or a concrete counterexample with an exact path, line,
hash, raw metadata fact, or falsifying test. No joint closure is claimed.

## 31. E1-CALLER-ONLY-SANITIZER-GREEN-007: Root-Cause Proof and Replacement Offline Gate

### 31.1 Authority, scope, and outcome

The user explicitly authorized Codex to continue operating the locked E1 plan while
Opus has no quota, including the important tests required to establish a sound
foundation. Opus audit is deferred, not waived. This checkpoint performs only the
separately authorized offline diagnosis and remediation required by section 30.9.
It does not execute a provider case, does not retry CallerOnly automatically, and
does not rerun AgentJsonSchema.

```yaml
checkpoint: E1-CALLER-ONLY-SANITIZER-GREEN-007
completed_at: 2026-08-10T10:49:07.6763808+07:00
checkpoint_result: PASS
provider_execution_in_this_checkpoint: false
provider_attempt_delta: 0
provider_request_delta: 0
automatic_retry: false
caller_only_attempt_002_run: false
agent_json_schema_rerun: false
joint_closure: false
```

The checkpoint proves and repairs one sanitizer boundary defect, adds one focused
regression, completes a fresh two-shell offline gate, and preserves CallerOnly
Attempt 1 byte-for-byte. The next eligible action remains a fresh complete preflight,
followed only on exact `MATCH` by one no-overwrite CallerOnly replacement attempt.

### 31.2 Backward trace from the retained failure

The retained immutable stdout marker remains at sanitized line 6:

```yaml
artifact: docs/evidence/phase-00/E1/raw/caller-only/attempt-001.stdout.jsonl
sanitized_line: 6
source_line: 6
marker_type: phase00_e1_redaction
marker_kind: sanitizer_processing_error
error_type: System.Management.Automation.RuntimeException
source_line_sha256: 46F025E51AD4848CF1CED22CFF587F13BF5C39D53757B5866B794D521AB3E12F
```

The sanitizer had already parsed the line as JSON and accepted its top-level object
shape before `Protect-Phase00E1Value` threw. Safe event-shape inspection established
that line 6 occupied the first assistant `message_start` position, between the user
`message_end` at line 5 and streaming `message_update` records beginning at line 7.
No private prompt, message text, reasoning, tool arguments, provider payload, or raw
transcript content was printed or copied during this diagnosis.

The pinned upstream trace is:

1. `_research/upstreams/oh-my-pi/packages/ai/src/providers/openai-shared.ts:3175-3192`
   creates the initial Responses assistant message;
2. `_research/upstreams/oh-my-pi/packages/ai/src/providers/openai-responses.ts:696-698`
   publishes that object as the provider `start` partial;
3. `_research/upstreams/oh-my-pi/packages/agent/src/agent-loop.ts:1806-1826`
   snapshots it and emits the first assistant `message_start`; and
4. `_research/upstreams/oh-my-pi/packages/coding-agent/src/modes/print-mode.ts:58-74`
   prints `message_start` after removing only `providerPayload`.

Reconstructing the pinned initial message shape without an empty object sanitizes
successfully. The persisted final controller messages also sanitize successfully.
This rules out a general failure on the ordinary initial-message fields and confines
the defect to a transient valid JSON shape handled only by the stdout start event.

### 31.3 Proven sanitizer defect and bounded inference

Before remediation, `scripts/lib/phase00-e1-evidence.ps1:416` used:

```powershell
$propertyNames = @($Value.PSObject.Properties.Name)
```

Under the repository's strict mode, PowerShell treats `.Name` on an empty
`PSObject.Properties` collection as a missing property. A valid JSON object `{}` is
therefore converted to an empty `PSCustomObject` and throws:

```yaml
pwsh_7:
  empty_object: ERROR
  error_type: System.Management.Automation.RuntimeException
  fully_qualified_error_id: PropertyNotFoundStrict,Protect-Phase00E1Value
  nonempty_control: PASS
windows_powershell_5_1:
  empty_object: ERROR
  error_type: System.Management.Automation.RuntimeException
  fully_qualified_error_id: PropertyNotFoundStrict,Protect-Phase00E1Value
  nonempty_control: PASS
```

This independently reproduces the exact retained exception type on both supported
shells while the paired nonempty-object control passes. Auditing every branch reached
by an assistant `message_start` found no other expression that produces this exact
strict-mode failure for the accepted JSON-object shape.

The defect in empty-object handling is proven. Because the intentionally ephemeral
unsanitized capture was securely removed after Attempt 1, the exact nested property
path of the transient `{}` cannot be recovered and is not claimed. The evidence
supports the bounded inference that line 6 contained a valid empty object somewhere
in its transient event tree; it does not authorize reconstructing or exposing that
private source line.

### 31.4 Strict TDD RED

One behavioral regression was added at
`scripts/tests/phase00-e1.Tests.ps1:534`. It passes a synthetic valid
`message_start` containing a nested empty `usage.cost` object through the real
`Protect-Phase00E1EventStream` boundary and requires:

- capture status `PASS`;
- zero malformed, invalid-shape, and processing-error lines;
- one source line and one sanitized line;
- unchanged source bytes;
- preserved empty content and preserved empty object.

No mock and no source-text assertion is used. The production mutation caught by the
test is the failure to enumerate an empty JSON object safely.

The new test was observed failing before the implementation change in both shells:

```yaml
pwsh_7_red:
  process_exit_code: 0
  wrapper_contract: exact_expected_red
  total: 75
  passed: 74
  failed: 1
  only_failure: preserves valid nested empty JSON objects without invalidating the capture
  decisive_failure: expected_PASS_observed_INVALID_RUN
windows_powershell_5_1_red:
  process_exit_code: 0
  wrapper_contract: exact_expected_red
  total: 75
  passed: 74
  failed: 1
  only_failure: preserves valid nested empty JSON objects without invalidating the capture
  decisive_failure: expected_PASS_observed_INVALID_RUN
```

The wrappers returned zero only after verifying that exactly this one new test failed;
an import, syntax, path, or harness failure could not satisfy the RED gate.

### 31.5 Minimal implementation and focused GREEN

The only production change is at
`scripts/lib/phase00-e1-evidence.ps1:416`:

```powershell
$propertyNames = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
```

The pipeline enumerates zero properties as an empty array and preserves the order and
names of every nonempty object. It changes no redaction classification, JSON parsing,
line preservation, hashing, runner behavior, fixture, provider request, oracle,
case-record, conclusion, manifest, or product surface.

Fresh focused results after the change:

```yaml
pwsh_7_green:
  exit_code: 0
  total: 75
  passed: 75
  failed: 0
windows_powershell_5_1_green:
  exit_code: 0
  total: 75
  passed: 75
  failed: 0
```

The mutation check is direct: restoring the former `.Properties.Name` shortcut makes
the new regression return `INVALID_RUN` and recreates the verified RED result.

### 31.6 Complete replacement offline gate

All required offline gates were rerun after the implementation change:

```yaml
node_syntax:
  command: node --check scripts/lib/phase00-e1-forwarder.mjs
  node_version: v24.16.0
  exit_code: 0
focused_e1_pwsh_7:
  total: 75
  passed: 75
  failed: 0
  exit_code: 0
focused_e1_windows_powershell_5_1:
  total: 75
  passed: 75
  failed: 0
  exit_code: 0
all_phase00_pwsh_7:
  files: 7
  total: 303
  passed: 303
  failed: 0
  skipped: 0
  pending: 0
  exit_code: 0
all_phase00_windows_powershell_5_1:
  files: 7
  total: 303
  passed: 303
  failed: 0
  skipped: 0
  pending: 0
  exit_code: 0
validator_pwsh_7:
  passed: 99
  warnings: 1
  failed: 0
  exit_code: 0
validator_windows_powershell_5_1:
  passed: 99
  warnings: 1
  failed: 0
  exit_code: 0
validator_warning_text: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
```

The validator warning is the pre-existing advisory token-budget warning. It is not an
E1 error and neither the warned product file nor any protected product surface was
changed.

The direct artifact contract also returned six PASS results:

```yaml
artifact_contract:
  - P00-E1-FIXTURE: PASS
  - P00-E1-RUNTIME: PASS
  - P00-E1-PROTECTED-SURFACE: PASS
  - P00-E1-MANIFEST: PASS
  - P00-E1-CONCLUSION: PASS
  - P00-E1-READY: PASS
ready_message: "E1 READY is valid; 20 unlisted history file(s) have no terminal authority."
```

### 31.7 Transparent exclusion of diagnostic invocations

Several read-only diagnostic invocations are intentionally excluded from official
test evidence:

1. the first Windows PowerShell synthetic probes omitted process-local execution-policy
   bypass, so the helper could not be dot-sourced; the corrected bypassed probe produced
   the two-shell result in section 31.3;
2. Pester 3.4 `-TestName` did not select the nested `It` block and returned zero tests;
   the full focused file was then run with an exact one-failure RED wrapper;
3. the first Node syntax probe used the stale path
   `scripts/phase00-e1-forwarder.mjs`; the corrected registered path under
   `scripts/lib` passed;
4. metadata-only reporter probes initially assumed an artifact-contract `.Id` field
   instead of `.Code`, a nonexistent `E1/cases` directory, and one stale manifest
   path; corrected probes returned the identities and six PASS results recorded here;
5. one raw-root presence reporter tokenized `Test-Path -LiteralPath` incorrectly; the
   corrected probe confirmed that all four later-case raw roots remain absent.

These were command/reporting defects, not product or E1 runtime failures. They made no
provider request, wrote no raw evidence, changed no fixture or product file, and are
not counted as RED, GREEN, validator, preflight, or provider evidence.

### 31.8 Frozen identities and immutable-attempt proof

```yaml
changelog_before_sha256: D2970B77B44FF8B32B4E457A5E508E031D0B2DABBCDABE1AD84FB3E44678A53C
design_sha256: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
plan_sha256: C06445019B99F517B77A4324014CC4C979D122CAB389514FF10AEEE05ADF80CF
e1_helper_before:
  lines: 6635
  bytes: 288856
  sha256: D75260914484CF155C3E2EE829E95C8C83A2E5FED2768159ED1C8F14FAFC8133
e1_helper_after:
  lines: 6635
  bytes: 288880
  sha256: 63A4301EF187DF0E70F1F35CF7405F307D219136D53B6F215573F5F18B00C6ED
focused_tests_before:
  lines: 4049
  bytes: 201691
  sha256: FC95A553C1D8EC8CC8F74A1A7FC4B65ABD7E829EE114C1081BF91CD5D315811A
focused_tests_after:
  lines: 4092
  bytes: 203696
  sha256: 135105A89CE7EBF2F7C5D70CD1806FE7FE4B6C91A3A5366782F737E1C2DF766F
manifest:
  lines: 179
  bytes: 5266
  sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
  e1: READY
  t_00_4: NOT_STARTED
  changed: false
fixture_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
runtime_version: omp/17.2.10
runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
```

CallerOnly Attempt 1 remains exact:

```yaml
attempt_run_sha256: C760778273BE41E1DFA20FA1BDAEFFB2D2A2FDF72B8600A54151956E865AD03C
stdout_sha256: 0642E3B13EE3D873B15886C1BBB4C06042EE659462DB2F70E80A7F51B1F3C767
stderr_sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
session_001_sha256: AB07175B14AF2C6B6E2782589127ADC14AAFBB4075613FC9F8D06E96080777B8
session_002_sha256: EDA0B6D39C41EF103383B6A6C84E768F4CC6C60D93C9A4F8FA0C37C88D794878
attempt_002_paths: 0
caller_only_case_record_exists: false
```

The complete E1 raw tree remains `20` files and `379358` bytes. Its canonical
`relative-path|length|sha256` inventory hash is
`5704C1CD28477EC4F1D9042D1E69DFBC9889D7D0AA0771A28A526951E9282248`.
No raw file was added, removed, rewritten, or re-sanitized.

The two authoritative case records remain:

```yaml
agent_jtd_case_record_sha256: BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4
agent_json_schema_case_record_sha256: 56A7270C18EBC4BFEAE0AF1B7A9D98B75B2BD165CD2290CF7126B459BF10C33B
conclusion_exists: false
```

### 31.9 Protected, process, temp, and Git boundaries

All nine protected pins still match:

```yaml
protected_paths_matched: 9/9
template/.omp/schemas/agent-result.schema.yml: A55B8E64DA16BB8205A6F815E9A8CD8DDE96BB8E085139435C71B785DCAE57D8
template/.omp/schemas/review-result.schema.yml: 439D5B321739FE22792847C8D091668C58DEFC0244E8AD14A6328FE464A8182B
template/.omp/schemas/task-packet.schema.yml: 78459082CC66C1F9320D3734B1BBA9C10F7DAA4E68EB4828B3D3879357DF2ABB
template/.omp/schemas/verification-result.schema.yml: 2D6F05567482CAADB39E487BA7838DF24904ADFE12C66DEE180AA4B8D4DB627C
template/.omp/agents/explorer.md: EFF925B0CF199144F306AE8F40226F8087ECF45297B0CEB270E07C3E9DF3CAE6
template/.omp/agents/implementer.md: 6090C229C4A6B9132B99F4540EA9788A2520BB358846C6ADC5482DD911E72A22
template/.omp/agents/reviewer.md: 7960C0C595A2B11AD5DFDC9C9F2A591C34F5CCFC2C0ADF43D5EA70F94E3C3DE3
template/.omp/agents/tech-lead.md: 47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2
template/.omp/agents/verifier.md: A3F49E18266587929D05B2DE28AD59D7B31E3832C20DAD5C201AB03348C449E0
```

```yaml
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
dirty_paths_with_untracked_expansion: 322
targeted_forwarder_or_pinned_runtime_processes: 0
current_gate_generated_temp_roots: 0
pre_existing_residue_roots: 1
pre_existing_residue_files: 1
pre_existing_residue_bytes: 129
pre_existing_residue_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
branch_worktree_stage_commit_push_pr: false
```

The pre-existing synthetic residue at
`C:/Users/MrThien/AppData/Local/Temp/phase00-e1-test-2b369a91c65548c0a43d2aa4ffde062b`
was not deleted, modified, permission-changed, or used as current evidence.

Only the following repository content changed in this checkpoint:

1. `scripts/tests/phase00-e1.Tests.ps1` — one focused empty-object regression;
2. `scripts/lib/phase00-e1-evidence.ps1` — one safe property-enumeration line; and
3. this English changelog.

Fixture, prompt, runner, forwarder, runtime catalog, raw evidence, case records,
design, plan, manifest, conclusion, template, and product files are unchanged.

### 31.10 Provider ledger and exact next gate

```yaml
cumulative_e1_provider_attempts_before_checkpoint: 4
cumulative_e1_provider_attempts_after_checkpoint: 4
cumulative_e1_provider_requests_before_checkpoint: 22
cumulative_e1_provider_requests_after_checkpoint: 22
sequential_wave_state: OFFLINE_REMEDIATION_GREEN
caller_only_attempt_001: INVALID_RUN_IMMUTABLE
caller_only_attempt_002: NOT_RUN
caller_over_agent: NOT_RUN
session_only: NOT_RUN
provider_strict_off_control: NOT_RUN
provider_strict_on: NOT_RUN
next_required_action: FRESH_COMPLETE_PREFLIGHT
```

The fresh preflight must rerun the complete locked contract, including both-shell
offline results, artifact contract, runtime/source pins, fixture identity, raw and
case immutability, manifest/protected state, no-overwrite destinations, environment,
credentials, loopback, process, temp, residue, Git, and provider counters. Any
mismatch stops before provider execution.

Only if that preflight returns exact `MATCH` may Codex execute CallerOnly Attempt 2.
That execution must be one sequential no-overwrite attempt, must not use automatic
retry, and must stop immediately after durable adjudication. Later provider cases are
eligible only one at a time while every immediately preceding matrix row is an
authoritative `PASS`.

### 31.11 Optimized deferred Opus audit packet

Recommended reading order:

1. section 30.4 and immutable stdout line 6 for the retained failure boundary;
2. sections 31.2-31.3 for backward trace, exact two-shell reproduction, and the
   explicit limitation on the unretained nested property path;
3. sections 31.4-31.5 for strict RED, the one-line remediation, and focused GREEN;
4. section 31.6 for complete two-shell offline verification and artifact contract;
5. sections 31.8-31.9 for before/after identities, immutable raw evidence, protected
   pins, temp/process/Git boundaries, and the disclosed old residue; and
6. section 31.10 for provider counters and the fresh-preflight replacement contract.

Concrete review questions:

1. Does the empty-object probe reproduce the exact retained exception class and error
   ID on both supported shells while the paired nonempty object passes?
2. Is the distinction between the proven sanitizer defect and the unprovable exact
   transient property path stated narrowly enough?
3. Does the new regression exercise the real event-stream sanitizer and prove RED
   before the implementation change?
4. Is the one-line enumeration change the minimum PowerShell 5.1-compatible repair,
   with unchanged ordering and redaction semantics for nonempty objects?
5. Do `75/75`, `303/303`, both `99/1/0` validators, Node syntax, and the six artifact
   checks form a sufficient offline replacement gate?
6. Are CallerOnly Attempt 1, the other fifteen prior raw files, both authoritative case
   records, manifest, protected surfaces, source/runtime pins, and provider counters
   demonstrably unchanged?
7. Does the next-action contract prevent automatic retry and require a fresh complete
   `MATCH` preflight before exactly one CallerOnly replacement attempt?

Codex requests peer agreement or a concrete counterexample with an exact file, line,
hash, failing command, or falsifying test. No joint closure is claimed.

## 32. E1-CALLER-ONLY-PREFLIGHT-MISMATCH-008: Reporter Constant Fault and Mandatory Stop

### 32.1 Fresh preflight execution

After checkpoint 007, Codex began the separately gated fresh complete preflight for
`CallerOnly` attempt 2. The provider case was not started. The preflight reran the
offline execution gates from the beginning:

```yaml
checkpoint: E1-CALLER-ONLY-PREFLIGHT-MISMATCH-008
started_from: E1-CALLER-ONLY-SANITIZER-GREEN-007
target_case: CallerOnly
target_attempt: 2
focused_e1_pwsh_7: 75/75 PASS
focused_e1_windows_powershell_5_1: 75/75 PASS
all_phase00_pwsh_7: 303/303 PASS
all_phase00_windows_powershell_5_1: 303/303 PASS
node_syntax: PASS
validator_pwsh_7: "99 passed, 1 warning, 0 failed"
validator_windows_powershell_5_1: "99 passed, 1 warning, 0 failed"
validator_warning_text: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
provider_process_started: false
provider_request_delta: 0
```

The comprehensive read-only reporter then checked the locked authority hashes,
fourteen-file fixture, two prior case reprojections and byte-identical records,
twenty-file raw inventory, immutable CallerOnly Attempt 1, no-overwrite Attempt 2
destinations, absent later-case roots, case/conclusion/manifest boundary, six artifact
contracts, nine protected pins, pinned source/runtime, credential availability,
loopback reachability, Git state, live-home snapshot, temp/residue boundary, targeted
processes, and cumulative provider counters.

Its fail-closed result was:

```yaml
preflight_verdict: MISMATCH
failure_count: 1
failure_code:
  - LIVE_HOME_HASH
provider_execution_after_mismatch: false
automatic_retry: false
```

### 32.2 Immediate read-only diagnosis

The mismatch was caused by a transient reporter constant copied incorrectly by Codex.
The reporter compared the live-home snapshot against:

```text
A2CDAAE6F4BFE69CC4590E4A002B670E3565D66F115DB243EE06703EABEC7076
```

That value spliced the live-home prefix with characters from a persisted-session
source hash. It is not a locked repository identity and was never written into the
harness, fixture, plan, design, manifest, evidence, or product files.

The immediate read-only diagnostic recomputed the actual snapshot and compared it to
the genuine locked identity from checkpoints 006 and 007:

```yaml
live_home_surfaces: 1
live_home_files: 14
actual_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
locked_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
actual_matches_locked: true
```

This proves a reporter expectation fault, not live-home drift. It does not convert the
already emitted preflight verdict into `MATCH`, and Codex did not silently correct the
constant and continue to provider execution.

One earlier metadata-only exploration of the historical fixture-tree manifest format
also contained a malformed helper-call token. It is excluded from preflight evidence,
made no mutation, and was not used by the comprehensive reporter; the real fourteen
per-file fixture check in that reporter passed.

### 32.3 Preserved stop boundary

Post-mismatch checks are:

```yaml
caller_only_attempt_002_paths: 0
e1_raw_files: 20
e1_raw_bytes: 379358
caller_only_attempt_001_run_sha256: C760778273BE41E1DFA20FA1BDAEFFB2D2A2FDF72B8600A54151956E865AD03C
targeted_forwarder_or_pinned_runtime_processes: 0
git_index_staged_paths: 0
provider_attempts_before: 4
provider_attempts_after: 4
provider_requests_before: 22
provider_requests_after: 22
conclusion_exists: false
manifest_changed: false
product_or_template_changed: false
joint_closure: false
```

The only repository mutation in checkpoint 008 is this English changelog section.
The transient reporter command is not a repository artifact.

### 32.4 Exact next eligible action

The locked instruction requires a stop and report when a fresh preflight does not
match. Therefore no provider case is eligible in this checkpoint, even though the
sole discrepancy has been diagnosed as a measurement-only constant typo.

The next permissible action, after the user directs continuation, is:

1. construct the live-home expectation from the locked checkpoint identity without
   the erroneous transient constant;
2. rerun the complete preflight from the beginning;
3. stop again on any mismatch; and
4. only on an exact fresh `MATCH`, run one no-overwrite CallerOnly Attempt 2 with no
   automatic retry, then stop and adjudicate it before considering any later row.

No AgentJsonSchema rerun, CallerOverAgent execution, provider-strict execution,
conclusion, manifest transition, T-00.4 work, branch, worktree, stage, commit, push, or
PR is authorized by checkpoint 008.

Opus audit remains deferred for quota only. Codex claims no joint closure.

## 33. E1-CALLER-ONLY-PREFLIGHT-MISMATCH-009: StrictMode Scalarization in the Transient Reporter

### 33.1 Authorization and fresh offline execution gates

After checkpoint 008, the user explicitly directed Codex to proceed. That direction
authorized a new complete preflight and, only after an exact fresh `MATCH`, one
no-overwrite `CallerOnly` attempt 2. It did not authorize an `AgentJsonSchema` rerun,
an automatic retry, a later provider row, a conclusion, or a manifest transition.

Codex reran every offline execution gate from the beginning before constructing the
read-only reporter:

```yaml
checkpoint: E1-CALLER-ONLY-PREFLIGHT-MISMATCH-009
checkpoint_input: E1-CALLER-ONLY-PREFLIGHT-MISMATCH-008
target_case: CallerOnly
target_attempt: 2
focused_e1_pwsh_7:
  result: 75/75 PASS
  pester_elapsed: 14.35s
focused_e1_windows_powershell_5_1:
  result: 75/75 PASS
  pester_elapsed: 16.71s
all_phase00_pwsh_7:
  result: 303/303 PASS
  pester_elapsed: 42.59s
all_phase00_windows_powershell_5_1:
  result: 303/303 PASS
  pester_elapsed: 49.65s
node_syntax:
  command: node --check scripts/lib/phase00-e1-forwarder.mjs
  exit_code: 0
validator_pwsh_7: "99 passed, 1 warning, 0 failed"
validator_windows_powershell_5_1: "99 passed, 1 warning, 0 failed"
validator_warning_text: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
authority_hashes_post_stop: 12/12 MATCH
authority_hash_mismatches_post_stop: 0
provider_process_started_during_offline_gates: false
provider_request_delta_during_offline_gates: 0
```

The twelve authority identities used by the reporter included the changelog at its
checkpoint-008 identity plus the locked design, plan, remediated E1 helper, focused
tests, runner, forwarder, runtime model catalog, general Phase 00 helper, validator,
Wave A tests, and T-00.3 conclusion. The input changelog identity was:

```yaml
changelog_before_lines: 4156
changelog_before_bytes: 183816
changelog_before_sha256: 70D9CDBC84BABE22676D9C86EB123A9452D2AB652E4626AE29D31B3B96AC1970
e1_helper_sha256: 63A4301EF187DF0E70F1F35CF7405F307D219136D53B6F215573F5F18B00C6ED
focused_tests_sha256: 135105A89CE7EBF2F7C5D70CD1806FE7FE4B6C91A3A5366782F737E1C2DF766F
locked_live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
```

### 33.2 Official comprehensive reporter result

The new reporter used the genuine locked live-home identity shown above, not the bad
transient constant from checkpoint 008. It was read-only and intended to check all
authority hashes, the fourteen-file fixture, prior case reprojections and canonical
records, the immutable twenty-file raw inventory, `CallerOnly` attempt 1, every
attempt-2 destination, later-row absence, manifest and protected boundaries, pinned
source/runtime, credential availability, loopback reachability, Git state, live home,
temp residue, targeted processes, provider counters, the exact case definition, and a
full `template/.omp` inventory baseline.

The reporter did not complete. It reached the `TEMP_RESIDUE` check and threw under
PowerShell StrictMode. Its fail-closed result was:

```yaml
preflight_verdict: MISMATCH
reporter_exit_code: 4
failure_count: 1
failure_code: REPORTER_EXCEPTION_TEMP_RESIDUE_PROPERTYNOTFOUNDEXCEPTION
failed_component: transient read-only reporter
failed_repository_code: null
provider_process_started_after_mismatch: false
provider_request_delta_after_mismatch: 0
automatic_retry: false
agent_json_schema_rerun: false
caller_only_attempt_2_started: false
```

One unsuppressed Boolean (`True`) preceded the verdict because
`Assert-Phase00E1AttemptDestinations` returned its success value to the reporter's
stdout. It contained no private data and was not interpreted as a preflight fact.
Because the reporter's outer catch emitted only the terminal exception, this
checkpoint does not claim that the set of checks accumulated before the exception
was an authoritative `MATCH`, even though the subsequent targeted audit found the
listed repository and environment invariants intact.

### 33.3 Root-cause investigation

The failing reporter fragment assigned its one-file residue query through an `if`
statement whose selected branch contained an inner array expression:

```powershell
$tempFiles = if ($tempRoots.Count -eq 1) {
    @(Get-ChildItem -LiteralPath $tempRoots[0].FullName -File -Recurse -Force)
} else {
    @()
}
```

PowerShell enumerated the branch output before assignment. With exactly one residue
file, the assigned value became a scalar `System.IO.FileInfo`, not an array. Accessing
`$tempFiles.Count` under `Set-StrictMode -Version Latest` therefore raised
`PropertyNotFoundException`.

The minimal read-only reproduction established:

```yaml
temp_roots_runtime_type: System.Object[]
temp_roots_count: 1
temp_root_element_type: System.IO.DirectoryInfo
temp_files_runtime_type: System.IO.FileInfo
temp_files_count_access: PropertyNotFoundException
temp_file_index_access: PASS
temp_file_name: malformed-source.jsonl
temp_file_bytes: 129
temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
```

The residue itself exactly matches the locked pre-existing test residue. The fault is
therefore statement-output scalarization in Codex's transient reporter, not residue
drift, a harness defect, a product defect, or live-home drift. No repository fix was
applied in this checkpoint. A future reporter must array-wrap the complete conditional
expression, not merely the command inside one branch, and must suppress the successful
destination assertion output. That correction is not retroactive and cannot convert
this emitted `MISMATCH` into `MATCH`.

### 33.4 Excluded exploratory and post-stop diagnostics

The following read-only command issues are excluded from preflight authority and are
recorded so a later audit does not mistake them for provider activity or hidden
evidence:

1. an early checkpoint lookup used the obsolete `docs/plans/...` location before the
   current `docs/superpowers/plans/...` path was resolved;
2. object-shape exploration initially passed `ProjectRoot` to
   `Test-Phase00E1FixtureTree`, which selects disposable-fixture projection semantics,
   and queried nonexistent live-snapshot convenience properties; the corrected direct
   fixture call returned `14/14 MATCH`;
3. the first attempt to submit the reporter to the shell failed at orchestration
   composition with `SyntaxError: Invalid or unexpected token`; no shell command ran;
4. the first post-stop diagnostic also scalarized a zero-result `$laterRoots` query and
   stopped after reporting only the first two facts; the corrected diagnostic wrapped
   the whole pipeline and completed read-only at
   `2026-08-10T11:24:28.1692970+07:00`.

None of those commands created, removed, overwrote, re-sanitized, or adjudicated an E1
artifact. None invoked OMP for a provider case. They are not retries of the official
preflight or of a provider process.

### 33.5 Post-mismatch stop-boundary audit

The corrected post-stop diagnostic established:

```yaml
caller_only_attempt_002_existing_paths: 0
caller_only_case_record_exists: false
later_raw_roots: 0
e1_raw_files: 20
e1_raw_bytes: 379358
e1_raw_inventory_sha256: 5704C1CD28477EC4F1D9042D1E69DFBC9889D7D0AA0771A28A526951E9282248
provider_attempts_before: 4
provider_attempts_after: 4
provider_requests_before: 22
provider_requests_after: 22
authoritative_case_records: 2
conclusion_exists: false
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
protected_surface_matched: 9/9
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
temp_roots: 1
temp_files: 1
temp_file_bytes: 129
temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
targeted_forwarder_or_pinned_runtime_processes: 0
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 322
product_or_template_changed_by_checkpoint: false
joint_closure: false
```

The raw inventory remains byte-identical to checkpoint 008, so the four process and
twenty-two request counts did not change. The manifest remains `E1: READY` with no
authority and `T-00.4: NOT_STARTED`; the conclusion remains absent. The only repository
mutation in checkpoint 009 is this English changelog section.

### 33.6 Exact next eligible action

The locked instruction requires a stop and report after any fresh preflight mismatch.
Therefore `CallerOnly` attempt 2 is not eligible in checkpoint 009. Codex must not
silently correct the transient reporter and continue.

After a new user direction, the next permissible action is to construct a new
read-only reporter with the complete conditional array-wrapped, suppress its helper
return value, and rerun the complete preflight from the beginning. Any new mismatch
again requires a stop. Only a new exact `MATCH` can authorize exactly one no-overwrite
`CallerOnly` attempt 2, with no automatic retry; Codex must then stop and adjudicate
that result before considering any later provider row.

No `AgentJsonSchema` rerun, `CallerOverAgent` execution, provider-strict execution,
conclusion, manifest transition, T-00.4 implementation, branch, worktree, stage,
commit, push, or PR is authorized by this checkpoint. Opus audit remains deferred for
quota only, and Codex claims no joint closure.

## 34. E1-CALLER-ONLY-PASS-010: Authorized Replacement Capture and Canonical Case Record

### 34.1 Authorization and transient-reporter RED/GREEN

After checkpoint 009, the user explicitly authorized Codex to proceed. The authority
was limited to a new complete preflight and, only after a new exact `MATCH`, one
no-overwrite `CallerOnly` attempt 2. It did not authorize an automatic retry, an
`AgentJsonSchema` rerun, a later provider row, a conclusion, or a manifest transition.

Before the official preflight, Codex tested the one-variable correction to the
transient reporter against the actual locked residue. No repository file was changed:

```yaml
old_expression_red:
  expected_failure_observed: true
  runtime_type: System.IO.FileInfo
  failure_type: PropertyNotFoundException
fixed_expression_green:
  complete_conditional_array_wrapped: true
  runtime_type: System.Object[]
  item_count: 1
  destination_assertion_stdout_items: 0
repository_reporter_artifact_created: false
```

The correction array-wrapped the complete conditional expression and piped the
successful destination assertion to `Out-Null`. It did not alter the E1 helper,
runner, fixture, test suite, product/template, manifest, evidence history, pinned
runtime, or pinned source.

### 34.2 Fresh complete preflight

The complete offline execution gate was then rerun from the beginning:

```yaml
focused_e1_pwsh_7:
  result: 75/75 PASS
  pester_elapsed: 16.55s
focused_e1_windows_powershell_5_1:
  result: 75/75 PASS
  pester_elapsed: 16.64s
all_phase00_pwsh_7:
  result: 303/303 PASS
  pester_elapsed: 49.26s
all_phase00_windows_powershell_5_1:
  result: 303/303 PASS
  pester_elapsed: 49.15s
node_syntax:
  command: node --check scripts/lib/phase00-e1-forwarder.mjs
  exit_code: 0
validator_pwsh_7: "99 passed, 1 warning, 0 failed"
validator_windows_powershell_5_1: "99 passed, 1 warning, 0 failed"
validator_warning_text: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
provider_process_started_during_offline_gates: false
provider_request_delta_during_offline_gates: 0
```

The corrected comprehensive read-only reporter completed at
`2026-08-10T11:35:24.8086407+07:00` with:

```yaml
preflight_verdict: MATCH
checks: 66
failure_count: 0
authority_hashes: 12/12
changelog_before_lines: 4370
changelog_before_bytes: 193371
changelog_before_sha256: DD63AFF7214AB29A103BEE866BA523722108C6BA70D8C0A653064DB0329FF719
fixture_files: 14/14
fixture_bytes: 7891
prior_case_records: 2
prior_case_reprojections: 2/2 PASS
raw_files_before: 20
raw_bytes_before: 379358
raw_inventory_sha256_before: 5704C1CD28477EC4F1D9042D1E69DFBC9889D7D0AA0771A28A526951E9282248
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
pinned_runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
temp_roots: 1
temp_files: 1
targeted_processes: 0
provider_attempts_before: 4
provider_requests_before: 22
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before: 322
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
gateway_tcp_reachable: true
credential_present: true
parallel_execution: false
automatic_retry: false
agent_json_schema_rerun: false
```

Attempt 2 and `case-2-caller-only.yml` were both absent, the immutable Attempt 1
hashes still matched `5/5`, all later raw roots and the conclusion were absent, E1
remained `READY`, and T-00.4 remained `NOT_STARTED` immediately before execution.

### 34.3 Exact single provider execution

Only after the exact fresh `MATCH`, Codex invoked:

```powershell
& scripts/run-phase00-e1.ps1 -CaseId CallerOnly -Attempt 2 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

No `-AllowOverwrite` or `-Model` override was supplied. The runner therefore used the
locked default model `omniroute/codex/gpt-5.6-sol-high`. Exactly one OMP process was
started, and the command was not retried:

```yaml
case_id: CallerOnly
attempt: 2
runner_started_at: 2026-08-10T11:35:39.9343656+07:00
runner_completed_at: 2026-08-10T11:36:04.8388744+07:00
process_started_at: 2026-08-10T11:35:41.1714950+07:00
process_completed_at: 2026-08-10T11:36:04.1552841+07:00
process_id: 36108
process_exit_code: 0
process_timed_out: false
descendant_pids_observed: 0
remaining_child_pids: 0
cleanup_succeeded: true
operation_error_type: null
capture_integrity_status: PASS
provider_process_attempts_this_checkpoint: 1
automatic_retry: false
```

The run envelope deliberately did not evaluate the semantic case oracle. Its empty
capture-time case status and `case_oracle_evaluated: false` are correct: capture
integrity completed first, and Codex subsequently invoked the pure raw-to-oracle
projection before deriving any authoritative record.

### 34.4 Immutable sanitized Attempt 2 inventory

The single process created exactly five no-overwrite sanitized artifacts:

| Artifact | Bytes | Lines | SHA-256 |
|---|---:|---:|---|
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-002.stdout.jsonl` | 41041 | 123 | `AF19C4590CA42436AB82B9E6F07298BEECD2CB0B0B3E4091060894BB3863BA33` |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-002.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-002.sessions/session-001.jsonl` | 7205 | 10 | `F67EB0D6087B3182FF2EE3000D141CBE7468EEAE317F3AC265843674623D03E6` |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-002.sessions/session-002.jsonl` | 4464 | 10 | `0C3AAE84A96EB6D31B9A756A5DBB7B2500F3D8AA4E9B7B410EC45FE1E947A263` |
| `docs/evidence/phase-00/E1/raw/caller-only/attempt-002.run.json` | 14506 | 315 | `0D1E808B13ED01E2B9B79279FC9932A0DE1B32F792B77C62A0F0EDAEE55E6F7C` |

The source-capture anchors persisted inside the derived record are:

```yaml
stdout_source_capture_sha256: FF612F97CF5289047C6B6540DB2D1D73A3ADA9C7EAC1AAEEE7F952B0CC067CC6
stderr_source_capture_sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
session_001_source_capture_sha256: 693C9CD34A7A198AA540BEC2D6AA5661E93A4CF2BEABE45374BB2AF8373AC4D2
session_002_source_capture_sha256: 00F431AE0C8BB331F7DB9EC18817F7E6526A4878E4B5E4DC2DC2B4E2B37A3155
```

No private prompt, reasoning, credential value, complete provider body, or unsanitized
session content is reproduced in this changelog.

### 34.5 Pure-oracle adjudication

`Read-Phase00E1AttemptEvidence` successfully verified the run envelope and selected
the target persisted session without counting duplicated controller stdout events.
`Test-Phase00E1Attempt` then returned:

```yaml
status: PASS
reason_codes:
  - E1_CALLER_ONLY_PASS
attributable_result_count: 1
selected_result_role: target
child_initialization_source: caller
source: caller
mode: permissive
structured_status: valid
caller_schema_state: PRESENT
agent_schema_state: ABSENT
agent_schema_dialect: NONE
session_schema_state: ABSENT
data_property_names:
  - sentinel
expected_sentinel_matches: true
forbidden_property_present: false
schema_override_observable: true
schema_override_observed: true
selected_session_requests: 1
selected_session_attributed_requests: 1
selected_session_recovered_retries: 0
selected_session_retry_exhausted: false
selected_session_terminal_failure_found: false
process_requests: 3
process_attributed_requests: 3
process_recovered_retries: 0
process_retry_exhausted_count: 0
process_terminal_failure_count: 0
protected_surface_unchanged: true
cleanup_succeeded: true
remaining_child_pid_count: 0
```

This is direct runtime evidence that the caller-provided schema was observable and
won for the child result while agent and session schemas were absent. It does not
generalize beyond the pinned runtime, model, provider, fixture, and one captured
attempt.

### 34.6 Canonical case record

Only after the pure oracle returned `PASS`, Codex derived the canonical record in
memory, verified its planned identity, and created the previously absent destination
with the no-overwrite writer:

```yaml
path: docs/evidence/phase-00/E1/case-2-caller-only.yml
status: PASS
attempt: 2
reason_codes:
  - E1_CALLER_ONLY_PASS
lines: 105
bytes: 3677
sha256: 65620D40C323B3C0E8C8F925452846B70B1E258F873C01D4CD5427A009F90738
regenerated_canonical_sha256: 65620D40C323B3C0E8C8F925452846B70B1E258F873C01D4CD5427A009F90738
byte_identical: true
```

No record was written before adjudication, and the writer was invoked only once.

### 34.7 Post-attempt verification and preserved boundaries

The first read-only post-attempt audit command contained a PowerShell invocation-list
syntax error by repeating `-LiteralPath` inside an array expression. It failed before
performing any assertion, mutation, or provider action. Codex corrected only the
read-only path collection and reran the audit; this was not an Attempt 2 retry.

The corrected independent audit returned `PASS` with zero failures:

```yaml
caller_only_analysis: PASS
caller_only_reason: E1_CALLER_ONLY_PASS
caller_only_case_record_sha256: 65620D40C323B3C0E8C8F925452846B70B1E258F873C01D4CD5427A009F90738
raw_files_after: 25
raw_bytes_after: 446574
raw_inventory_sha256_after: EA0864984EDFCCEB9072B358E1445D30F73014C9C38C7DA4621C48BF9EF4B9A0
provider_attempts_before: 4
provider_attempts_after: 5
provider_requests_before: 22
provider_requests_after: 25
new_provider_processes: 1
new_provider_requests: 3
agent_json_schema_rerun: false
later_raw_roots: 0
case_records_after: 3
conclusion_exists: false
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
targeted_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 328
joint_closure: false
```

CallerOnly Attempt 1 remains immutable at its five checkpoint-008 hashes. Both prior
case records remain byte-identical. No later provider root exists. The manifest
remains `E1: READY` with no authority, T-00.4 remains `NOT_STARTED`, and no conclusion
was created. The product/template inventory, protected surfaces, live home, pinned
source, and pinned runtime were not changed by the attempt.

### 34.8 Stop boundary and exact next eligible action

The authorized `CallerOnly` replacement is complete and adjudicated `PASS`. Codex now
stops before `CallerOverAgent`, as required. This single row does not make E1 PASS and
does not authorize T-00.4 implementation.

After a new user direction, the next eligible provider row is `CallerOverAgent`
attempt 1. It requires its own complete fresh preflight, exact prior-PASS check,
no-overwrite destination check, and one sequential provider process. Any non-PASS or
preflight mismatch must stop the wave without retry.

No `AgentJsonSchema` rerun, `SessionOnly`, provider-strict arm, conclusion, manifest
transition, T-00.4 implementation, branch, worktree, stage, commit, push, or PR is
authorized by checkpoint 010. Opus audit remains deferred for quota only, and Codex
claims no joint closure.

## 35. E1-CALLER-OVER-AGENT-PREFLIGHT-TIMEOUT-011: Windows PowerShell Gate Incomplete

### 35.1 Authorization and fresh gate execution

After checkpoint 010, the user explicitly authorized Codex to proceed to the next
sequential row, `CallerOverAgent` attempt 1. The authority remained conditional on a
new complete preflight returning an exact `MATCH`. It did not authorize a provider
process after an incomplete gate, an automatic retry, an `AgentJsonSchema` rerun, a
later row, a conclusion, or a manifest transition.

The checkpoint input was exact before the fresh gate began:

```yaml
target_case: CallerOverAgent
target_attempt: 1
target_execution_order: 4
target_matrix_artifact: case-3-caller-over-agent
target_source: caller
target_mode: permissive
expected_caller_sentinel: E1_CALLER_WINS
forbidden_agent_sentinel: E1_AGENT_LOSES
changelog_before_lines: 4665
changelog_before_bytes: 204992
changelog_before_sha256: D8FADD88AC4F827B2EC6916D4F7FF7B424A4FFC96DACD8D04AACD57D55F1EFB7
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
caller_over_agent_attempt_001_existing_paths: 0
caller_over_agent_case_record_exists: false
```

Codex reran the gates from the beginning and obtained:

```yaml
focused_e1_pwsh_7:
  result: 75/75 PASS
  pester_elapsed: 13.43s
focused_e1_windows_powershell_5_1:
  result: 75/75 PASS
  pester_elapsed: 16.03s
all_phase00_pwsh_7:
  result: 303/303 PASS
  pester_elapsed: 43.02s
all_phase00_windows_powershell_5_1:
  result: INCOMPLETE_TIMEOUT
  configured_outer_timeout_ms: 60000
  observed_tool_wall_time: 62.1s
  tool_exit_code: 124
  pester_result_received: false
node_syntax_after_timeout: NOT_RUN_STOP_GATE
validator_pwsh_7_after_timeout: NOT_RUN_STOP_GATE
validator_windows_powershell_5_1_after_timeout: NOT_RUN_STOP_GATE
comprehensive_reporter_after_timeout: NOT_RUN_STOP_GATE
preflight_verdict: NOT_MATCHED_INCOMPLETE_TIMEOUT
provider_process_started: false
provider_request_delta: 0
automatic_retry: false
agent_json_schema_rerun: false
```

The Windows PowerShell command was the same complete `phase00*.Tests.ps1` Pester
selection used by earlier checkpoints. The outer execution tool terminated the command
after its configured sixty-second window and returned no Pester summary. Therefore
this checkpoint makes neither a `303/303 PASS` claim nor a test-failure claim for that
invocation. Without a complete result, the fresh preflight cannot be `MATCH`.

### 35.2 Read-only diagnosis

Codex did not rerun the timed-out gate. Immediate process inspection found no orphaned
Windows PowerShell/Pester process and no OMP or E1 forwarder process:

```yaml
pester_powershell_processes: 0
pinned_omp_or_e1_forwarder_processes: 0
caller_over_agent_attempt_001_existing_paths: 0
caller_over_agent_case_record_exists: false
```

The same complete Windows PowerShell suite had finished in `49.15s` during checkpoint
010, but that historical observation cannot classify the current invocation. The
available evidence proves only that the host-side sixty-second timeout was reached;
because partial Pester output was not returned, it cannot distinguish a transiently
slower successful run, a hang, or an internal test failure. No harness, test, product,
template, or evidence fix is justified from this incomplete observation.

A future authorized preflight should start from the beginning and give this non-provider
test process a host execution window safely above the observed duration, while leaving
the test selection and all E1 provider timeouts unchanged. That future invocation is a
new preflight, not a continuation or retroactive correction of checkpoint 011.

### 35.3 Post-timeout stop-boundary audit

The corrected read-only audit completed at
`2026-08-10T11:49:35.3288381+07:00` with zero failures:

```yaml
post_timeout_audit: PASS
failure_count: 0
caller_over_agent_attempt_001_existing_paths: 0
caller_over_agent_case_record_exists: false
raw_files: 25
raw_bytes: 446574
raw_inventory_sha256: EA0864984EDFCCEB9072B358E1445D30F73014C9C38C7DA4621C48BF9EF4B9A0
provider_attempts_before: 5
provider_attempts_after: 5
provider_requests_before: 25
provider_requests_after: 25
authoritative_case_records: 3
prior_caller_only_status: PASS
prior_caller_only_case_record_sha256: 65620D40C323B3C0E8C8F925452846B70B1E258F873C01D4CD5427A009F90738
later_raw_roots: 0
conclusion_exists: false
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
pester_processes: 0
pinned_omp_or_e1_forwarder_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 328
product_or_template_changed: false
joint_closure: false
```

No raw artifact, case record, conclusion, manifest field, protected surface, live-home
surface, product/template file, or Git index entry changed. The only repository
mutation in checkpoint 011 is this English changelog section.

### 35.4 Exact next eligible action

The locked fail-closed rule requires a stop after an incomplete fresh preflight.
`CallerOverAgent` attempt 1 is therefore not eligible in checkpoint 011, and Codex did
not invoke it.

After a new user direction, the next permissible action is to rerun the complete
preflight from the beginning with a sufficiently bounded host timeout for the full
Windows PowerShell suite. Any new failure, timeout, or reporter mismatch must stop
again. Only a new exact `MATCH` can authorize exactly one no-overwrite
`CallerOverAgent` attempt 1, with no automatic retry, followed by immediate
adjudication and another stop before `SessionOnly`.

No `AgentJsonSchema` rerun, `SessionOnly`, provider-strict arm, conclusion, manifest
transition, T-00.4 implementation, branch, worktree, stage, commit, push, or PR is
authorized by checkpoint 011. Opus audit remains deferred for quota only, and Codex
claims no joint closure.

## 36. E1-CALLER-OVER-AGENT-PREFLIGHT-REPORTER-ERROR-012: Pester 3 Result-Shape Mismatch

### 36.1 Continuing authority and fresh-cycle start

The user broadened Codex's execution authority to complete Phase 00, while the locked
fail-closed E1 contract remained unchanged: each provider row stays sequential,
no-overwrite, and non-retrying; a fresh complete preflight must return an exact `MATCH`
before a provider process may start. Codex therefore began a new preflight for
`CallerOverAgent` attempt 1 from the first gate rather than resuming checkpoint 011.

The checkpoint input was byte-identical to the checkpoint-011 stop boundary:

```yaml
target_case: CallerOverAgent
target_attempt: 1
target_execution_order: 4
target_matrix_artifact: case-3-caller-over-agent
target_source: caller
target_mode: permissive
expected_caller_sentinel: E1_CALLER_WINS
forbidden_agent_sentinel: E1_AGENT_LOSES
changelog_before_lines: 4815
changelog_before_bytes: 211150
changelog_before_sha256: EA62BE3386F73A7ABEA5B9651C78FB3AEE1A44ACF51E399A1A92CDD7A7968F5F
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
caller_over_agent_attempt_001_existing_paths: 0
caller_over_agent_case_record_exists: false
```

### 36.2 Focused PowerShell 7 observation and fail-closed verdict

The first gate executed the complete focused E1 suite. Pester itself completed all
tests and printed an unambiguous passing summary:

```yaml
focused_e1_pwsh_7_test_result:
  total: 75
  passed: 75
  failed: 0
  skipped: 0
  pending: 0
  pester_elapsed: 14.41s
host_tool_wall_time: 15.8s
transient_result_wrapper_exit_code: 1
transient_result_wrapper_json_received: false
preflight_verdict: NOT_MATCHED_TRANSIENT_REPORTER_ERROR
focused_e1_windows_powershell_5_1_after_error: NOT_RUN_STOP_GATE
all_phase00_pwsh_7_after_error: NOT_RUN_STOP_GATE
all_phase00_windows_powershell_5_1_after_error: NOT_RUN_STOP_GATE
node_syntax_after_error: NOT_RUN_STOP_GATE
validator_pwsh_7_after_error: NOT_RUN_STOP_GATE
validator_windows_powershell_5_1_after_error: NOT_RUN_STOP_GATE
comprehensive_reporter_after_error: NOT_RUN_STOP_GATE
provider_process_started: false
provider_request_delta: 0
automatic_retry: false
agent_json_schema_rerun: false
```

The repository test result is PASS, but the complete preflight invocation is not a
`MATCH`: the transient wrapper exited non-zero after the suite and failed to emit its
machine-readable summary. The fail-closed boundary therefore treats this cycle as
incomplete and does not infer eligibility from Pester's textual summary alone.

### 36.3 Systematic root-cause determination

Codex investigated the reporting layer without rerunning the suite or changing a
repository file. The loaded PowerShell 7 module is Pester `3.4.0`, not a Pester 5 result
shape. Its installed `Invoke-Pester -PassThru` implementation at
`C:/Program Files/WindowsPowerShell/Modules/Pester/3.4.0/Pester.psm1:336-348` selects
exactly these result properties:

```text
TagFilter, ExcludeTagFilter, TestNameFilter, TotalCount, PassedCount,
FailedCount, SkippedCount, PendingCount, Time, TestResult
```

The one-off wrapper incorrectly read `$r.Result.ToString()` and `$r.Duration`. Pester
3.4.0 exposes neither property; it exposes `Time` for elapsed duration. The first null
method call produced `InvalidOperation`, and the repeated `Result` read in the exit
condition made the wrapper exit 1 even though `FailedCount` was zero. This is a
measurement-only incompatibility in the transient command composed for checkpoint
012. It is not a defect in the repository test suite, E1 helper, runner, fixture,
provider, product/template, or pinned runtime.

The smallest valid correction for a future fresh cycle is to summarize the properties
Pester 3.4.0 actually returns and classify success from its counts (including
`FailedCount == 0` and the expected total), without referencing `Result` or `Duration`.
No repository implementation change is justified.

### 36.4 Post-error read-only boundary audit

The read-only audit completed at `2026-08-10T12:01:44.7356271+07:00`:

```yaml
post_error_audit: PASS
failure_count: 0
caller_over_agent_attempt_001_existing_paths: 0
caller_over_agent_case_record_exists: false
raw_files: 25
raw_bytes: 446574
raw_inventory_sha256: EA0864984EDFCCEB9072B358E1445D30F73014C9C38C7DA4621C48BF9EF4B9A0
provider_attempts_before: 5
provider_attempts_after: 5
provider_requests_before: 25
provider_requests_after: 25
authoritative_case_records: 3
prior_caller_only_case_record_sha256: 65620D40C323B3C0E8C8F925452846B70B1E258F873C01D4CD5427A009F90738
conclusion_exists: false
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
live_home_surfaces: 1
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
pester_processes: 0
pinned_omp_or_e1_forwarder_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 328
product_or_template_changed: false
joint_closure: false
```

The one historical 129-byte test residue remains present and was not deleted. No raw
artifact, case record, conclusion, manifest field, protected file, live-home file,
template file, product file, or Git index entry changed. The only repository mutation
in checkpoint 012 is this English changelog section.

### 36.5 Stop boundary and exact next eligible action

Codex stops at the first incomplete gate as required. `CallerOverAgent` attempt 1 was
not invoked, and no provider retry occurred.

The next permissible action is a completely new preflight from the focused PowerShell
7 gate, using only the Pester 3.4.0 `PassThru` properties verified above and preserving
the longer host timeout for the complete Windows PowerShell suite. Any mismatch,
failure, timeout, or reporter exception must stop again. Only a new exact `MATCH` may
authorize exactly one no-overwrite `CallerOverAgent` attempt 1.

No `AgentJsonSchema` rerun, `SessionOnly`, provider-strict arm, conclusion, manifest
transition, T-00.4 implementation, branch, worktree, stage, commit, push, or PR occurred
in checkpoint 012. Opus audit remains deferred for quota only, and Codex claims no joint
closure.

## 37. E1-CALLER-OVER-AGENT-PREFLIGHT-QUOTING-ERROR-013: Child Command Was Not Entered

### 37.1 Fresh-cycle gate results

Under the continuing Phase-00 authority, Codex began another complete preflight from
the first gate. The corrected Pester-3 result projection worked in PowerShell 7:

```yaml
focused_e1_pwsh_7:
  result: 75/75 PASS
  failed: 0
  skipped: 0
  pending: 0
  pester_elapsed: 14.15s
  transient_wrapper_exit_code: 0
focused_e1_windows_powershell_5_1:
  result: NOT_RUN_COMMAND_PARSE_ERROR
  child_test_process_reached_invoke_pester: false
  outer_tool_exit_code: 1
all_phase00_pwsh_7_after_error: NOT_RUN_STOP_GATE
all_phase00_windows_powershell_5_1_after_error: NOT_RUN_STOP_GATE
node_syntax_after_error: NOT_RUN_STOP_GATE
validator_pwsh_7_after_error: NOT_RUN_STOP_GATE
validator_windows_powershell_5_1_after_error: NOT_RUN_STOP_GATE
comprehensive_reporter_after_error: NOT_RUN_STOP_GATE
preflight_verdict: NOT_MATCHED_CHILD_COMMAND_PARSE_ERROR
provider_process_started: false
provider_request_delta: 0
automatic_retry: false
agent_json_schema_rerun: false
```

The Windows PowerShell child returned a parser error before any repository test ran:
`Missing ')' in method call`, followed by `.Time.TotalSeconds` and empty-pipeline
errors. A historical Windows PowerShell PASS cannot substitute for this incomplete
fresh cycle.

### 37.2 Root cause and minimal boundary proof

The error was traced to the two-shell command boundary. Codex supplied the child
`-Command` payload inside a double-quoted string interpreted first by the outer
PowerShell host. The outer host expanded every `$r` reference to its own nonexistent
value, so the child received fragments such as `.TotalCount` and
`.Time.TotalSeconds`. The child parser therefore failed before loading Pester or
touching the repository test suite.

This is a transient command-composition defect, separate from checkpoint 012's
Pester-result-shape defect. No repository code change is warranted. A no-test
diagnostic proved the minimal safe transport: encode the complete child script as
UTF-16LE Base64 and invoke Windows PowerShell with `-EncodedCommand`. That diagnostic
preserved every literal `$r` reference and returned:

```yaml
encoded_child_boundary_diagnostic:
  repository_test_executed: false
  input_shape: synthetic Pester-3-compatible result object
  output_total: 75
  output_passed: 75
  output_failed: 0
  output_time_seconds: 14.15
  exit_code: 0
transport_decision_for_next_cycle: Windows PowerShell -EncodedCommand
```

The next fresh cycle must use this transport for both Windows PowerShell gates. It
must not reuse the double-quoted nested `-Command` form.

### 37.3 Post-error stop-boundary audit

The read-only audit completed at `2026-08-10T12:04:52.0408562+07:00` with no boundary
drift:

```yaml
post_error_audit: PASS
failure_count: 0
changelog_before_lines: 4967
changelog_before_bytes: 217640
changelog_before_sha256: 7C3AB6A1F446D1B3F5FCF8A00E2B580FFB164FDF80576B5593993A35A7B5ADBD
caller_over_agent_attempt_001_existing_paths: 0
caller_over_agent_case_record_exists: false
raw_files: 25
raw_bytes: 446574
raw_inventory_sha256: EA0864984EDFCCEB9072B358E1445D30F73014C9C38C7DA4621C48BF9EF4B9A0
provider_attempts_before: 5
provider_attempts_after: 5
provider_requests_before: 25
provider_requests_after: 25
authoritative_case_records: 3
conclusion_exists: false
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
pester_processes: 0
pinned_omp_or_e1_forwarder_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 328
product_or_template_changed: false
joint_closure: false
```

The historical 129-byte test residue remains untouched. No provider artifact, case
record, conclusion, manifest field, protected surface, product/template file,
live-home file, or Git index entry changed. This English changelog section is the only
repository mutation in checkpoint 013.

### 37.4 Stop boundary and next eligible action

Codex stops because the fresh preflight did not complete. `CallerOverAgent` attempt 1
was not invoked and no provider retry occurred.

The next eligible action is another complete preflight from the first PowerShell 7
gate, with the Pester-3-compatible summary from checkpoint 012 and encoded child
transport from checkpoint 013. A fresh exact `MATCH` remains the sole authority for
one no-overwrite `CallerOverAgent` attempt 1.

No `AgentJsonSchema` rerun, `SessionOnly`, provider-strict arm, conclusion, manifest
transition, T-00.4 implementation, branch, worktree, stage, commit, push, or PR occurred
in checkpoint 013. Opus audit remains deferred for quota only, and Codex claims no joint
closure.

## 38. E1-CALLER-OVER-AGENT-PREFLIGHT-REPORTER-SYNTAX-014: Simplified Where-Object Operator Token

### 38.1 Fresh complete offline gate observations

Codex started a new preflight from the first gate. The Pester-3-compatible result
projection and encoded Windows PowerShell transport both worked. Every executable
offline gate before the final read-only reporter completed successfully:

```yaml
focused_e1_pwsh_7:
  result: 75/75 PASS
  failed: 0
  skipped: 0
  pending: 0
  pester_elapsed: 14.35s
focused_e1_windows_powershell_5_1:
  result: 75/75 PASS
  failed: 0
  skipped: 0
  pending: 0
  pester_elapsed: 16.80s
  transport: EncodedCommand
all_phase00_pwsh_7:
  files: 7
  result: 303/303 PASS
  failed: 0
  skipped: 0
  pending: 0
  pester_elapsed: 43.59s
all_phase00_windows_powershell_5_1:
  files: 7
  result: 303/303 PASS
  failed: 0
  skipped: 0
  pending: 0
  pester_elapsed: 50.26s
  transport: EncodedCommand
node_syntax:
  command: node --check scripts/lib/phase00-e1-forwarder.mjs
  exit_code: 0
validator_pwsh_7: "99 passed, 1 warning, 0 failed"
validator_windows_powershell_5_1: "99 passed, 1 warning, 0 failed"
validator_warning_text: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
provider_process_started_during_offline_gates: false
provider_request_delta_during_offline_gates: 0
```

The warning is the unchanged advisory RULES.md token-budget warning. It is not an E1
failure and the warned file remained byte-identical.

### 38.2 Final reporter exception and fail-closed verdict

The final comprehensive read-only reporter did not complete. It exited 4 with:

```yaml
reporter_verdict: MISMATCH
reporter_exception: System.Management.Automation.PSArgumentException
reporter_message: >-
  An operator is required to compare the two specified values. Include a valid
  operator in the command, and then try the command again.
failed_component: transient comprehensive reporter
repository_test_failure: false
provider_process_started: false
provider_request_delta: 0
automatic_retry: false
agent_json_schema_rerun: false
preflight_verdict: NOT_MATCHED_REPORTER_EXCEPTION
```

Although all test and validator processes passed, the locked preflight requires the
final reporter itself to complete with zero mismatches. A reporter exception therefore
prevents `CallerOverAgent` eligibility; Codex did not infer a `MATCH` from the earlier
green processes.

### 38.3 Systematic root-cause determination

The exception occurred at the reporter's first use of simplified `Where-Object`
comparison syntax. The transient command omitted whitespace between the comparison
operator and its right-hand value, for example:

```powershell
Where-Object Status -ne'PASS'
```

In the simplified `Where-Object -Property` grammar, PowerShell treats `-ne'PASS'` as
an invalid operator argument. The same no-whitespace form is accepted in an ordinary
expression or scriptblock predicate, which is why the reporter parsed and earlier
inline predicates ran before the artifact-contract filter threw.

A five-expression synthetic diagnostic isolated the grammar boundary:

```yaml
simplified_where_object_without_operator_whitespace:
  status_ne: FAIL_SAME_PSARGUMENTEXCEPTION
  status_eq: FAIL_SAME_PSARGUMENTEXCEPTION
  name_eq: FAIL_SAME_PSARGUMENTEXCEPTION
ordinary_inline_expression_without_whitespace: PASS
scriptblock_predicate_without_whitespace: PASS
```

The smallest robust correction is to use scriptblock predicates for every reporter
filter, with conventional operator whitespace:

```powershell
Where-Object { $_.Status -ne 'PASS' }
Where-Object { $_.Status -eq 'PASS' }
Where-Object { $_.Name -eq $expectedName }
```

A second synthetic diagnostic verified all three corrected predicates. No repository
implementation, test, fixture, product/template, runtime, or evidence fix is justified.

### 38.4 Post-error stop-boundary audit

The corrected independent audit completed at
`2026-08-10T12:14:12.3558090+07:00`:

```yaml
post_error_audit: PASS
failure_count: 0
changelog_before_lines: 5095
changelog_before_bytes: 222729
changelog_before_sha256: 1F9281F78B035559E815E5EEE8521FCA79FB879AC04BE73918FB6AAAF0219464
caller_over_agent_attempt_001_existing_paths: 0
caller_over_agent_case_record_exists: false
raw_files: 25
raw_bytes: 446574
raw_inventory_sha256: EA0864984EDFCCEB9072B358E1445D30F73014C9C38C7DA4621C48BF9EF4B9A0
provider_attempts_before: 5
provider_attempts_after: 5
provider_requests_before: 25
provider_requests_after: 25
authoritative_case_records: 3
conclusion_exists: false
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
pester_processes: 0
pinned_omp_or_e1_forwarder_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 328
product_or_template_changed: false
joint_closure: false
```

The historical 129-byte residue remains untouched. No provider artifact, case record,
conclusion, manifest field, protected surface, product/template file, live-home file,
or Git index entry changed. This English changelog section is the only repository
mutation in checkpoint 014.

### 38.5 Stop boundary and next eligible action

Codex stops at the incomplete final reporter. `CallerOverAgent` attempt 1 was not
invoked and no provider retry occurred.

The next eligible action is another complete preflight from the first PowerShell 7
gate, retaining the Pester-3 summary, encoded Windows PowerShell transport, and
scriptblock-only reporter filters proven across checkpoints 012-014. Only a fresh exact
`MATCH` may authorize one no-overwrite `CallerOverAgent` attempt 1.

No `AgentJsonSchema` rerun, `SessionOnly`, provider-strict arm, conclusion, manifest
transition, T-00.4 implementation, branch, worktree, stage, commit, push, or PR occurred
in checkpoint 014. Opus audit remains deferred for quota only, and Codex claims no joint
closure.

## 39. E1-CALLER-OVER-AGENT-PREFLIGHT-SCALARIZATION-015: Known Complete-Conditional Array Rule Regressed

### 39.1 Fresh cycle results before the reporter stop

Codex began another complete preflight from the first gate. All executable test,
syntax, and validator gates completed successfully:

```yaml
focused_e1_pwsh_7:
  result: 75/75 PASS
  pester_elapsed: 14.12s
focused_e1_windows_powershell_5_1:
  result: 75/75 PASS
  pester_elapsed: 16.58s
  transport: EncodedCommand
all_phase00_pwsh_7:
  files: 7
  result: 303/303 PASS
  pester_elapsed: 43.56s
all_phase00_windows_powershell_5_1:
  files: 7
  result: 303/303 PASS
  pester_elapsed: 50.06s
  transport: EncodedCommand
node_syntax:
  command: node --check scripts/lib/phase00-e1-forwarder.mjs
  exit_code: 0
validator_pwsh_7: "99 passed, 1 warning, 0 failed"
validator_windows_powershell_5_1: "99 passed, 1 warning, 0 failed"
validator_warning_text: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
provider_process_started_during_offline_gates: false
provider_request_delta_during_offline_gates: 0
```

The final comprehensive reporter then exited 4 before returning a result:

```yaml
reporter_verdict: MISMATCH
reporter_exception: System.Management.Automation.PropertyNotFoundException
reporter_message: "The property 'Count' cannot be found on this object."
failed_component: transient comprehensive reporter
preflight_verdict: NOT_MATCHED_REPORTER_EXCEPTION
provider_process_started: false
provider_request_delta: 0
automatic_retry: false
agent_json_schema_rerun: false
```

The green tests and validators cannot substitute for a completed reporter. Therefore
`CallerOverAgent` remained ineligible and was not invoked.

### 39.2 Phase-marker diagnosis and exact failing expression

A read-only diagnostic reran the reporter's individual observation phases with a
phase marker and exception stack. Authority-independent checks progressed through
fixture, prior-case reprojection, raw inventory, destinations, artifact contract,
protected surface, source, live home, and template inventory. The failure localized
to the `temp` phase and this exact access:

```powershell
$tempFiles = if ($expectedTemp.Count -eq 1) {
    @(Get-ChildItem -LiteralPath $expectedTemp[0].FullName -Recurse -File)
} else {
    @()
}
$tempFiles.Count
```

PowerShell enumerates output from an `if` expression during assignment. Although the
true branch contains `@(...)`, its single file is unwrapped after leaving the branch;
`$tempFiles` becomes `System.IO.FileInfo`, which has no `Count` property under
StrictMode.

This is not a new finding. Checkpoint 010 had already locked the required correction:
array-wrap the **complete conditional expression**, not only its branches. Checkpoint
015 accidentally regressed that known transient-reporter rule while reconstructing the
larger reporter. No repository implementation caused the regression.

The minimal comparison against the real locked residue returned:

```yaml
branch_only_wrapping:
  runtime_type: System.IO.FileInfo
  has_count_property: false
complete_conditional_wrapping:
  expression: '@(if (...) { @(...) } else { @() })'
  runtime_type: System.Object[]
  count: 1
  file_name: malformed-source.jsonl
  bytes: 129
  sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
```

The next reporter must preserve the checkpoint-010 form exactly:

```powershell
$tempFiles = @(if ($expectedTemp.Count -eq 1) {
    @(Get-ChildItem -LiteralPath $expectedTemp[0].FullName -Recurse -File)
} else {
    @()
})
```

No E1 helper, test, runner, fixture, product/template, manifest, source, runtime, or
evidence change is justified.

### 39.3 Post-error stop-boundary audit

The independent audit completed at `2026-08-10T12:21:57.2307425+07:00`:

```yaml
post_error_audit: PASS
failure_count: 0
changelog_before_lines: 5268
changelog_before_bytes: 228987
changelog_before_sha256: 740660CE2C1EFD77B9992B0665B8DA891A9D06CA5AB4752CAF12CC3732F1AC1E
caller_over_agent_attempt_001_existing_paths: 0
caller_over_agent_case_record_exists: false
raw_files: 25
raw_bytes: 446574
raw_inventory_sha256: EA0864984EDFCCEB9072B358E1445D30F73014C9C38C7DA4621C48BF9EF4B9A0
provider_attempts_before: 5
provider_attempts_after: 5
provider_requests_before: 25
provider_requests_after: 25
authoritative_case_records: 3
conclusion_exists: false
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
temp_files: 1
temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
pester_processes: 0
pinned_omp_or_e1_forwarder_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 328
product_or_template_changed: false
joint_closure: false
```

The old 129-byte residue was read and rehashed but not removed. No provider artifact,
case record, conclusion, manifest field, protected surface, product/template file,
live-home file, or Git index entry changed. This English changelog section is the only
repository mutation in checkpoint 015.

### 39.4 Stop boundary and next eligible action

Codex stops at the reporter exception. `CallerOverAgent` attempt 1 was not invoked and
no provider retry occurred.

The next eligible action is a complete preflight from the first PowerShell 7 gate,
retaining all four proven reporter/execution rules: Pester-3 fields, encoded Windows
child scripts, scriptblock `Where-Object` predicates, and complete-conditional array
wrapping. Only a new exact `MATCH` may authorize one no-overwrite `CallerOverAgent`
attempt 1.

No `AgentJsonSchema` rerun, `SessionOnly`, provider-strict arm, conclusion, manifest
transition, T-00.4 implementation, branch, worktree, stage, commit, push, or PR occurred
in checkpoint 015. Opus audit remains deferred for quota only, and Codex claims no joint
closure.

## 40. Checkpoint 016 — fresh complete preflight MATCH and `CallerOverAgent` attempt 1 PASS

### 40.1 Authority, scope, and fail-closed contract

The user explicitly approved Option A and authorized Codex to continue the Phase 00
program while Opus quota remains unavailable. This checkpoint retained the locked
execution contract:

- Codex-only execution; no subagent, branch, worktree, stage, commit, push, PR, reset,
  cleanup of unrelated dirt, or overwrite;
- a fresh complete preflight had to return exact `MATCH` before one provider process;
- E1 provider processes remain strictly sequential, with no automatic retry;
- `AgentJsonSchema` must not be rerun;
- E1 may not mutate product/template, live-home, protected, manifest, source, or runtime
  surfaces;
- raw provider evidence is immutable and is reported only through sanitized projections;
- any non-PASS, invalid, ambiguous, timeout, or preflight mismatch remains an immediate
  fail-closed stop; and
- `joint_closure: false`; Opus audit is deferred for quota, not replaced.

The approved Option A used a disposable, offline-only complete-preflight reporter outside
the repository. It was structurally unable to start a provider process: its runtime
allowlist admitted only the pinned executable's `--version` probe.

### 40.2 Reporter RED/GREEN development and lock

Test-first development observed RED while the reporter was absent, then GREEN only after
the reporter satisfied the complete-preflight contract. The reporter self-test covered:

1. complete conditional scalarization under both the old-RED and corrected-GREEN forms;
2. Pester 3 result fields;
3. scriptblock `Where-Object` predicates;
4. encoded Windows PowerShell child commands;
5. rejection of provider-capable runtime/script invocations; and
6. acceptance of the pinned runtime only for `--version`.

The full offline dry run completed in 143.7 seconds and returned:

```json
{"verdict":"PASS","self_test_checks":8,"dry_run_checks":88,"provider_capability":false,"provider_request_delta":0}
```

The exact artifacts were then locked and not modified before official consumption:

```yaml
reporter_path: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-016.ps1
reporter_lines: 1111
reporter_bytes: 53900
reporter_sha256: 17A38D320BCC41D02365AD1D9E68715A6939A03273DCFA3B98664D9CE6DECA58
reporter_parse_errors: 0
test_path: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-016.Tests.ps1
test_bytes: 3101
test_sha256: A1FB689E794BB228302D5EAA9131BBDE17675C26AF02FED7BDE807506C229BF0
```

Reporter development exposed and corrected ten offline-environment/reporting defects
before the official run: one syntax error, one helper-signature mismatch, safe Windows
CLIXML progress handling, the required trailing-LF inventory form, Pester 3's missing
`-Show` parameter, Pester console-stream classification, Windows execution-policy
handling, Windows PowerShell module-path isolation, scoped error-action behavior, and
validator-warning normalization after CLIXML deserialization. Three failed
Windows-Pester diagnostic cycles created six new test directories each. All 18 were
resolved under the OS temp root, identity-checked, and deleted; the pre-existing
129-byte historical residue was never selected or removed. A few ad-hoc read-only audit
commands also produced parser/noisy-output mistakes (including an empty pipeline form, a
`Get-History` name collision, and one missing whitespace token). Those commands had no
provider capability. Every corrected baseline check reconfirmed provider delta zero and
the exact historical residue identity before official execution.

### 40.3 Official fresh complete preflight

The official invocation first reverified the reporter SHA-256 above. It then ran once,
completed in 134.2 seconds, and returned exact `MATCH` with 73 checks and no failures.
The complete gate result was:

```yaml
verdict: MATCH
checks: 73
failures: []
focused_pester_pwsh7: 75/75 PASS (14.1 seconds)
focused_pester_windows_powershell: 75/75 PASS (16.59 seconds)
all_pester_pwsh7: 303/303 PASS (43.73 seconds)
all_pester_windows_powershell: 303/303 PASS (50.3 seconds)
node_syntax_exit: 0
validator_pwsh7: 99 passed, 1 warning, 0 failed
validator_windows_powershell: 99 passed, 1 warning, 0 failed
validator_warning: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
authority_hashes: 12/12 MATCH
fixture_files: 14
fixture_bytes: 7891
fixture_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
prior_case_records: 3
prior_case_reprojections: 3
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
pinned_source_origin: https://github.com/can1357/oh-my-pi.git
pinned_runtime_version: omp/17.2.10
pinned_runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
temp_files: 1
temp_file_bytes: 129
temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
raw_files_before: 25
raw_bytes_before: 446574
raw_inventory_sha256_before: EA0864984EDFCCEB9072B358E1445D30F73014C9C38C7DA4621C48BF9EF4B9A0
provider_attempts_before: 5
provider_requests_before: 25
provider_request_delta: 0
targeted_processes: 0
pester_processes: 0
gateway_tcp_reachable: true
credential_present: true
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths: 328
provider_capability: false
provider_process_started: false
automatic_retry: false
agent_json_schema_rerun: false
joint_closure: false
```

The one warning was the already-authorized exact RULES budget warning. No warning was
ignored by pattern broadening, and the provider attempt count, request count, and raw
inventory stayed byte-identical throughout the preflight.

### 40.4 Exactly one authorized provider execution

Only after exact `MATCH`, Codex invoked the locked runner once:

```powershell
& scripts/run-phase00-e1.ps1 -CaseId CallerOverAgent -Attempt 1 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

No `-AllowOverwrite`, `-Model`, retry, second provider process, or
`AgentJsonSchema` execution was used. The process completed with exit code zero in 20.3
seconds:

```yaml
case_id: CallerOverAgent
attempt: 1
capture_integrity_status: PASS
reason_codes: []
run_sha256: BA0D717E4E294190E3BEC96CB547835F9406D32902B0B2CE5331C7128570CCE7
provider_process_attempts: 1
```

### 40.5 Immutable raw evidence delta

Exactly five new raw artifacts appeared under the one authorized attempt:

| Artifact | Bytes | Lines | File SHA-256 |
|---|---:|---:|---|
| `raw/caller-over-agent/attempt-001.run.json` | 14559 | 315 | `BA0D717E4E294190E3BEC96CB547835F9406D32902B0B2CE5331C7128570CCE7` |
| `raw/caller-over-agent/attempt-001.sessions/session-001.jsonl` | 7509 | 10 | `79FA696E483A96A28F25D03B3802932A579BD1E3AA55C8BD5EEFD689CC303478` |
| `raw/caller-over-agent/attempt-001.sessions/session-002.jsonl` | 4508 | 10 | `F2697A14F1DF10217A008C4C41AA00963AE69B4208CADFABCAA5A03F8471C8DD` |
| `raw/caller-over-agent/attempt-001.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |
| `raw/caller-over-agent/attempt-001.stdout.jsonl` | 45845 | 133 | `B7B69E9F75F365A9B5544B4C0E3CEE9E84CD69D254855A76EF18D8E0A07808E8` |

The sanitized run record's source-capture hashes were independently projected as:

```yaml
stdout_capture_sha256: A48BAB3FCB72CDA55AE5876EDC709BF56E4F05B618051B666EF9062CE4F95C71
stderr_capture_sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
session_001_capture_sha256: 00261742CE0E977B109858F967E0A1ED8503B5AC5DE4249788D612D2BF40D7C9
session_002_capture_sha256: 1CBD839C426852917549444157951227A9F5758AA11CABD493EAB753A0B8B553
```

No raw transcript content is reproduced here. Inventory validation proved that the 25
pre-existing raw artifacts remained unchanged and that the total delta was exactly the
five files above:

```yaml
prior_raw_files: 25
prior_raw_bytes: 446574
prior_raw_inventory_sha256: EA0864984EDFCCEB9072B358E1445D30F73014C9C38C7DA4621C48BF9EF4B9A0
prior_raw_unchanged: true
target_raw_files: 5
target_raw_bytes: 72421
target_raw_inventory_sha256: C0A8A2FA19574E510BF46982FD2F584581E1B198E2F6E7215453E0AFAA45F0E0
total_raw_files: 30
total_raw_bytes: 518995
total_raw_inventory_sha256: 0585857B1455C63AA83856BE9C0C9AE8C6BB438149A42B588783E89EDE785B77
provider_attempts_after: 6
provider_requests_after: 28
provider_attempt_delta: 1
provider_request_delta: 3
```

### 40.6 Oracle projection and canonical record

`Read-Phase00E1AttemptEvidence` and `Test-Phase00E1Attempt` both returned PASS. The
authoritative projection was:

```yaml
status: PASS
reason_code: E1_CALLER_OVER_AGENT_PASS
projection_status: PASS
projection_reason_codes: []
attributable_results: 1
selected_agent: phase00-e1-caller-over-agent
selected_async: false
selected_source: caller
selected_mode: permissive
selected_structured_status: valid
selected_data_properties: [caller_sentinel]
expected_sentinel_present: true
forbidden_property_present: false
selected_ledger_requests: 1
selected_ledger_attributed: 1
selected_ledger_unattributed: 0
selected_ledger_response: 1
selected_ledger_retries: 0
selected_ledger_exhausted: false
selected_ledger_terminal: false
selected_model: omniroute/codex/gpt-5.6-sol-high
process_ledger_requests: 3
process_ledger_attributed: 3
process_ledger_unattributed: 0
process_ledger_response: 3
process_ledger_retries: 0
process_ledger_exhausted: 0
process_ledger_terminal: 0
child_source: caller
caller_schema: PRESENT
agent_schema: PRESENT
override_observable: true
override_observed: true
blocking_executions: 1
protected_unchanged: true
cleanup_complete: true
remaining_child_pids: 0
```

Only after that PASS, the canonical writer created exactly one matrix record:

```yaml
path: docs/evidence/phase-00/E1/case-3-caller-over-agent.yml
lines: 105
bytes: 3757
sha256: 58EA16AD5E39EAF62D01A44007B7165C8E3B8E4CB01FF8A90C99D85D020EEE8A
```

A safe temporary regeneration produced the same SHA-256 and byte-identical content; the
scratch artifact was then deleted. The authoritative record was never overwritten.

### 40.7 Independent post-attempt audit

The independent post-attempt audit completed at
`2026-08-10T13:18:01.8794598+07:00` with no failure:

```yaml
post_attempt_audit: PASS
failure_count: 0
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
authoritative_case_records: 4
conclusion_exists: false
later_provider_destinations_present: []
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
temp_files: 1
temp_file_name: malformed-source.jsonl
temp_file_bytes: 129
temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
targeted_omp_or_forwarder_processes: 0
pester_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 334
changelog_lines_before_append: 5437
changelog_bytes_before_append: 235207
changelog_sha256_before_append: B4A4AE7E623264B8AF851474DF2EBE336C6CA8A9C69CF2803C4333EEAEB5040A
product_or_template_changed: false
joint_closure: false
```

The three prior canonical records remained hash-identical:

```yaml
case-1-agent-jtd.yml: BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4
case-1-agent-json-schema.yml: 56A7270C18EBC4BFEAE0AF1B7A9D98B75B2BD165CD2290CF7126B459BF10C33B
case-2-caller-only.yml: 65620D40C323B3C0E8C8F925452846B70B1E258F873C01D4CD5427A009F90738
```

### 40.8 Disposable reporter disposal

After official consumption and the independent audit, the two exact locked disposable
files were deleted with their absolute paths resolved and verified absent:

```yaml
deleted_reporter: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-016.ps1
deleted_reporter_sha256: 17A38D320BCC41D02365AD1D9E68715A6939A03273DCFA3B98664D9CE6DECA58
deleted_test: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-016.Tests.ps1
deleted_test_sha256: A1FB689E794BB228302D5EAA9131BBDE17675C26AF02FED7BDE807506C229BF0
deleted_files_present_after: false
historical_temp_roots_after: 1
historical_temp_files_after: 1
historical_temp_bytes_after: 129
historical_temp_sha256_after: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
```

These two disposable reporter files are not recoverable through this repository. The
historical 129-byte residue remains present and unchanged.

### 40.9 Checkpoint boundary and next eligible action

Checkpoint 016 changed only the five new `CallerOverAgent` raw artifacts, the one new
canonical case record, and this English changelog. It did not change any product/template
file, helper, test, runner, fixture, manifest, protected surface, live-home file, pinned
source, pinned runtime, Git index entry, or prior E1 evidence.

`CallerOverAgent` attempt 1 is PASS. There was no retry and no `AgentJsonSchema` rerun.
The next eligible provider action is `SessionOnly` attempt 1, but it remains prohibited
until a new fresh complete preflight proves the updated 30-file/four-case checkpoint and
returns exact `MATCH`. `ProviderStrictOffControl`, `ProviderStrictOn`, the E1 conclusion,
the manifest transition, T-00.4 implementation, and later Phase 00 work remain unexecuted
at this boundary. Opus audit remains pending quota, and Codex claims no joint closure.

## 41. Checkpoint 017 — fresh complete preflight MATCH and `SessionOnly` attempt 1 PASS

### 41.1 Sequential authority and target boundary

The broad Phase 00 continuation authority remained subject to the locked E1 fail-closed
contract. Checkpoint 016 made `SessionOnly` attempt 1 the only eligible next provider
action, and only after a new complete preflight proved the updated 30-file/four-case
checkpoint. No provider-strict arm, `AgentJsonSchema` rerun, automatic retry, overwrite,
model override, branch, worktree, stage, commit, push, PR, reset, or unrelated cleanup
was authorized.

The preflight implementation remained disposable and outside the repository. It had no
E1 runner or evidence-case invocation path and allowed the pinned runtime only for the
fixed `--version` probe. `joint_closure` remained false.

### 41.2 Reporter TDD, measurement diagnostics, and final lock

Test-first construction observed the intended initial RED because reporter `017` did not
exist. A second RED exposed an over-broad structural test: it treated the E1 runner's
name in the 12-file authority hash table as if it were a command invocation. The test was
corrected to inspect PowerShell command ASTs, so the authority identity remained locked
while any real runner invocation remained forbidden.

The resulting self-test passed with:

```json
{"verdict":"PASS","reporter_parse_errors":0,"structural_forbidden_tokens":0,"reporter_self_test_checks":8,"provider_capability":false,"target_case":"SessionOnly","target_attempt":1}
```

The first full dry run executed every offline gate but correctly returned `FAIL` after
133.86 seconds because six console-output classification assertions were too strict:

```yaml
dry_run_verdict: FAIL
checks: 75
failures:
  - focused_pwsh
  - focused_windows
  - all_pwsh
  - all_windows
  - validator_pwsh
  - validator_windows
focused_pwsh: 75/75 PASS, exit 0, Pester 14.32 seconds
focused_windows: 75/75 PASS, exit 0, Pester 16.69 seconds
all_pwsh: 303/303 PASS, exit 0, Pester 44.13 seconds
all_windows: 303/303 PASS, exit 0, Pester 50.28 seconds
node_syntax_exit: 0
provider_attempts: 6
provider_requests: 28
provider_request_delta: 0
raw_inventory_sha256: 0585857B1455C63AA83856BE9C0C9AE8C6BB438149A42B588783E89EDE785B77
provider_capability: false
provider_process_started: false
```

The gates themselves were GREEN. The reporter had incorrectly rejected Pester's known
console stream on stderr despite structured sentinel counts and exit zero. It also
expected singular `warning` and forward slashes, while the validator's actual display
was `99 passed, 1 warnings, 0 failed` with Windows path separators. A direct read-only
validator diagnostic under both hosts confirmed exactly 99 passes, one expected RULES
warning, zero failures, and exit zero. The measurement layer was then narrowed to:

- classify Pester by the encoded child's structured result, exact counts, and exit code;
- normalize validator path separators before exact warning matching; and
- match the validator's actual plural display while preserving the locked semantic
  warning text.

No E1 helper, test, runner, fixture, product/template, manifest, evidence, source, or
runtime file was changed. Baseline remeasurement after the failed dry run proved 6
provider attempts, 28 provider requests, target destinations absent, and the one exact
historical temp residue.

The corrected full dry run then passed all 75 checks in 133.91 seconds:

```yaml
dry_run_verdict: PASS
failures: []
focused_pwsh: 75/75 PASS, Pester 14.22 seconds
focused_windows: 75/75 PASS, Pester 16.82 seconds
all_pwsh: 303/303 PASS, Pester 44.21 seconds
all_windows: 303/303 PASS, Pester 50.43 seconds
validator_pwsh: exact summary 1, exact warning 1, exit 0
validator_windows: exact summary 1, exact warning 1, exit 0
authority_hashes: 12/12 MATCH
prior_case_reprojections: 4/4 PASS
provider_request_delta: 0
```

The reporter and its test were then locked without further modification:

```yaml
reporter_path: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-017.ps1
reporter_lines: 760
reporter_bytes: 39543
reporter_sha256: 55D1D258DCCDDBC4E3A8B14BBE12C164FFC7424AEA5F620CA202AA82C43A9E65
reporter_parse_errors: 0
test_path: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-017.Tests.ps1
test_lines: 77
test_bytes: 2696
test_sha256: 387ECC7824E3EE399DE168A5DB8BE3B07A6880567711250D9F81371A169C3CC4
test_parse_errors: 0
```

### 41.3 Official fresh complete preflight

Immediately before official execution, the reporter SHA-256 was rechecked against the
locked value. The official preflight then ran once from the first gate, completed in
132.9 seconds, and returned exact `MATCH`:

```yaml
verdict: MATCH
checks: 75
failures: []
focused_pester_pwsh7: 75/75 PASS (14.35 seconds; process 15.54 seconds; exit 0)
focused_pester_windows_powershell: 75/75 PASS (16.54 seconds; process 17.29 seconds; exit 0)
all_pester_pwsh7: 303/303 PASS (44.05 seconds; process 45.00 seconds; exit 0)
all_pester_windows_powershell: 303/303 PASS (49.72 seconds; process 50.47 seconds; exit 0)
node_syntax_exit: 0
validator_pwsh7: 99 passed, 1 warning, 0 failed (exit 0; 1.05 seconds)
validator_windows_powershell: 99 passed, 1 warning, 0 failed (exit 0; 1.07 seconds)
validator_warning: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
authority_hashes: 12/12 MATCH
fixture_files: 14
fixture_bytes: 7891
fixture_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
prior_case_records: 4
prior_case_reprojections: 4/4 PASS
raw_files: 30
raw_bytes: 518995
raw_inventory_sha256: 0585857B1455C63AA83856BE9C0C9AE8C6BB438149A42B588783E89EDE785B77
provider_attempts: 6
provider_requests: 28
provider_request_delta: 0
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
temp_files: 1
targeted_processes: 0
pester_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths: 334
gateway_tcp_reachable: true
credential_present: true
provider_capability: false
provider_process_started: false
automatic_retry: false
agent_json_schema_rerun: false
target_case: SessionOnly
target_attempt: 1
joint_closure: false
```

Pester's console-stream field remained non-empty by environment design; it was not used
to waive any failure. Each encoded child emitted exactly one structured sentinel with
the exact pass/total counts above and exited zero. No provider or raw-evidence delta
occurred during the official preflight.

### 41.4 Exactly one authorized provider execution

Only after exact `MATCH`, Codex reverified the locked reporter hash and target absence,
then invoked:

```powershell
& scripts/run-phase00-e1.ps1 -CaseId SessionOnly -Attempt 1 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

There was no `-AllowOverwrite`, `-Model`, retry, parallel provider call, or
`AgentJsonSchema` rerun. The one provider process completed with exit zero in 31.3
seconds:

```yaml
case_id: SessionOnly
attempt: 1
capture_integrity_status: PASS
reason_codes: []
run_sha256: 745AA34BBDE7DFC4780ACE9CB64A83804FBE50228A6D7B022B475E3349480254
provider_process_attempts: 1
```

### 41.5 Immutable raw evidence delta

Exactly six new artifacts appeared under the authorized target:

| Artifact | Bytes | Lines | File SHA-256 |
|---|---:|---:|---|
| `raw/session-only/attempt-001.run.json` | 17279 | 361 | `745AA34BBDE7DFC4780ACE9CB64A83804FBE50228A6D7B022B475E3349480254` |
| `raw/session-only/attempt-001.sessions/session-001.jsonl` | 9488 | 10 | `FF9AF82B11C41A60E20CA59E3F11392F54427C9E7BA70C7E219D28592F5D21C4` |
| `raw/session-only/attempt-001.sessions/session-002.jsonl` | 9036 | 13 | `A0042A5AECE81DCA58FAF76B42601ECFB096E4C82E091366EE21F5113E38D424` |
| `raw/session-only/attempt-001.sessions/session-003.jsonl` | 4514 | 10 | `E19CBF6176EA958D26DF324C84E779148696A0D5DCA2F980635D394A86412C77` |
| `raw/session-only/attempt-001.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |
| `raw/session-only/attempt-001.stdout.jsonl` | 116550 | 153 | `5A6B257F0F73BBE940D21D0B719E5559917519B14EA66BB5CF1EEB9A81263130` |

The sanitized source-capture hashes were:

```yaml
stdout_capture_sha256: 4567BEE6829F0A496AB8E3CF969371D1D69F5266A940F8A14E6E956A2EB0EAC9
stderr_capture_sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
session_001_capture_sha256: ED1D037AF5D2A1AEF82764FEDC97621B779B90B23C6C7CB18EE38D1725F4C610
session_002_capture_sha256: 5AD853A18943C68948733AAA01C63CB6028EB902F309F5FE92E34B46D9980F08
session_003_capture_sha256: C79A82FFD6FA3D43F4DDEF6B26967DDF36C82AA25861E5850A1C27B846E2C7BC
```

No raw transcript content is reproduced. Inventory validation proved the prior raw tree
unchanged and the delta exact:

```yaml
prior_raw_files: 30
prior_raw_bytes: 518995
prior_raw_inventory_sha256: 0585857B1455C63AA83856BE9C0C9AE8C6BB438149A42B588783E89EDE785B77
target_raw_files: 6
target_raw_bytes: 156867
target_raw_inventory_sha256: 76BAC1554501A95843CCDBC3127B3EBDBFAD26CD06072EA185766D8C3E2072EF
total_raw_files: 36
total_raw_bytes: 675862
total_raw_inventory_sha256: A6EE0472CAB6CA0DFC5B3EA04BDCFD3814E07BED2A76957FC1824BF89EAB8DC9
provider_attempts_after: 7
provider_requests_after: 33
provider_attempt_delta: 1
provider_request_delta: 5
```

### 41.6 Oracle projection and canonical record

`Read-Phase00E1AttemptEvidence` and `Test-Phase00E1Attempt` returned unambiguous PASS:

```yaml
status: PASS
reason_code: E1_SESSION_ONLY_PASS
projection_status: PASS
projection_reason_codes: []
attributable_results: 1
selected_result_role: nested_leaf
selected_agent: phase00-e1-session-leaf
selected_async: false
selected_source: session
selected_mode: permissive
selected_structured_status: valid
selected_data_properties: [session_sentinel]
expected_sentinel_matches: true
forbidden_property_present: false
child_initialization_source: session
schema_override_observable: false
schema_override_observed: false
blocking_execution_count: 2
carrier_agent: phase00-e1-session-carrier
carrier_blocking: true
leaf_agent: phase00-e1-session-leaf
leaf_blocking: true
selected_ledger_requests: 1
selected_ledger_attributed: 1
selected_ledger_unattributed: 0
selected_ledger_response_ends: 1
selected_ledger_retries: 0
selected_ledger_exhausted: false
selected_ledger_terminal_failure: false
selected_model: omniroute/codex/gpt-5.6-sol-high
process_ledger_requests: 5
process_ledger_attributed: 5
process_ledger_unattributed: 0
process_ledger_response_ends: 5
process_ledger_retries: 0
process_ledger_exhausted_count: 0
process_ledger_terminal_failure_count: 0
controller_stdout_duplicates_excluded: true
protected_unchanged: true
cleanup_succeeded: true
remaining_child_pids: 0
```

Only after that PASS, the canonical writer created one record and refused any overwrite:

```yaml
path: docs/evidence/phase-00/E1/case-4-session-only.yml
lines: 118
bytes: 4201
sha256: 71EF04AA77F635A0A7706D50E66297C76D7D8E607709B5B2E1AB28C70158CA6A
scratch_regeneration_sha256: 71EF04AA77F635A0A7706D50E66297C76D7D8E607709B5B2E1AB28C70158CA6A
byte_identical: true
scratch_cleanup_succeeded: true
```

### 41.7 Independent post-attempt audit

The post-attempt audit completed at `2026-08-10T13:41:25.5675981+07:00`:

```yaml
post_attempt_audit: PASS
failure_count: 0
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
authoritative_case_records: 5
later_provider_destinations_present: []
conclusion_exists: false
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
temp_files: 1
temp_file_name: malformed-source.jsonl
temp_file_bytes: 129
temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
targeted_omp_or_forwarder_processes: 0
pester_processes: 0
reporter_sha256: 55D1D258DCCDDBC4E3A8B14BBE12C164FFC7424AEA5F620CA202AA82C43A9E65
test_sha256: 387ECC7824E3EE399DE168A5DB8BE3B07A6880567711250D9F81371A169C3CC4
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 341
changelog_lines_before_append: 5775
changelog_bytes_before_append: 249424
changelog_sha256_before_append: 918D848DE029278412AAC304ABBCBAC4223A87BECAE72FBE1B29715FF4034247
product_or_template_changed: false
joint_closure: false
```

All four prior case hashes remained exact, including
`case-3-caller-over-agent.yml` at
`58EA16AD5E39EAF62D01A44007B7165C8E3B8E4CB01FF8A90C99D85D020EEE8A`.

### 41.8 Disposable disposal and next eligible action

After official consumption and post-audit, the exact reporter and test were deleted and
verified absent:

```yaml
deleted_reporter: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-017.ps1
deleted_reporter_sha256: 55D1D258DCCDDBC4E3A8B14BBE12C164FFC7424AEA5F620CA202AA82C43A9E65
deleted_test: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-017.Tests.ps1
deleted_test_sha256: 387ECC7824E3EE399DE168A5DB8BE3B07A6880567711250D9F81371A169C3CC4
deleted_files_present_after: false
historical_temp_roots_after: 1
historical_temp_files_after: 1
historical_temp_bytes_after: 129
historical_temp_sha256_after: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
```

The disposable files are not recoverable through this repository. The historical
residue remains untouched.

Checkpoint 017 changed only six `SessionOnly` raw artifacts, the one canonical
`case-4-session-only.yml`, and this English changelog. `SessionOnly` attempt 1 is PASS;
there was no retry or `AgentJsonSchema` rerun.

The next eligible provider action is `ProviderStrictOffControl` attempt 1. It remains
prohibited until a new fresh complete preflight proves the 36-file/five-case checkpoint
and returns exact `MATCH`. The strict-on arm may run only after the off-control arm is
independently adjudicated. The paired canonical record, E1 conclusion, manifest
transition, T-00.4, and later Phase 00 work remain unexecuted at this boundary. Opus audit
remains pending quota, and Codex claims no joint closure.

## 42. Checkpoint 018 — `ProviderStrictOffControl` attempt 1 INVALID_RUN and fail-closed stop

### 42.1 Authority and pre-provider contract

Checkpoint 017 made `ProviderStrictOffControl` attempt 1 the only eligible next provider
action, subject to a fresh complete preflight. The strict-on arm remained explicitly
forbidden until the off-control arm had been independently adjudicated. The locked
contract still required an immediate stop on any non-PASS, invalid, ambiguous, timeout,
or mismatch result, with no automatic retry and no evidence overwrite.

Reporter `018` was disposable and outside the repository. Its test first observed RED
while the reporter was absent, then GREEN only after AST inspection proved there was no
E1 runner command and its fail-closed capability flags were false:

```json
{"verdict":"PASS","reporter_parse_errors":0,"runner_command_asts":0,"self_test_checks":8,"provider_capability":false,"target_case":"ProviderStrictOffControl","target_attempt":1}
```

The full dry run passed 75/75 checks in 134.85 seconds:

```yaml
dry_run_verdict: PASS
failures: []
focused_pwsh7: 75/75 PASS (15.88 seconds)
focused_windows_powershell: 75/75 PASS (16.51 seconds)
all_pwsh7: 303/303 PASS (43.72 seconds)
all_windows_powershell: 303/303 PASS (50.07 seconds)
node_syntax_exit: 0
validator_pwsh7: exact summary 1, exact warning 1, exit 0
validator_windows_powershell: exact summary 1, exact warning 1, exit 0
authority_hashes: 12/12 MATCH
fixture_files: 14
fixture_bytes: 7891
prior_case_records: 5
prior_case_reprojections: 5/5 PASS
raw_files: 36
raw_bytes: 675862
raw_inventory_sha256: A6EE0472CAB6CA0DFC5B3EA04BDCFD3814E07BED2A76957FC1824BF89EAB8DC9
provider_attempts: 7
provider_requests: 33
provider_request_delta: 0
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
strict_on_execution: false
provider_capability: false
```

The exact reporter and test were then locked:

```yaml
reporter_path: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-018.ps1
reporter_lines: 373
reporter_bytes: 29079
reporter_sha256: 0C57F113B2811FCC5EAEE3170B38CFEDAC115E462929F631BAB9F6C135C440AE
reporter_parse_errors: 0
test_path: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-018.Tests.ps1
test_lines: 57
test_bytes: 2510
test_sha256: 569111619F2B242021CAAEABDCB4D010942E726C6254D777FEBF1D7A8DCA797A
test_parse_errors: 0
```

### 42.2 Official fresh complete preflight

After a final reporter-hash check, the official preflight ran once from its first gate
and returned exact `MATCH` in 123.83 seconds:

```yaml
verdict: MATCH
checks: 75
failures: []
focused_pester_pwsh7: 75/75 PASS (13.40 seconds; process 14.46 seconds; exit 0)
focused_pester_windows_powershell: 75/75 PASS (15.54 seconds; process 16.23 seconds; exit 0)
all_pester_pwsh7: 303/303 PASS (40.62 seconds; process 41.43 seconds; exit 0)
all_pester_windows_powershell: 303/303 PASS (46.54 seconds; process 47.24 seconds; exit 0)
node_syntax_exit: 0
validator_pwsh7: 99 passed, 1 warning, 0 failed (exit 0; 0.94 seconds)
validator_windows_powershell: 99 passed, 1 warning, 0 failed (exit 0; 0.99 seconds)
validator_warning: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
authority_hashes: 12/12 MATCH
fixture_tree_sha256: C2034CD611733364DEC4145C7CFFE21F9ED61CF2141BBB5574060B713D7EC60B
prior_case_records: 5
prior_case_reprojections: 5/5 PASS
raw_files: 36
raw_bytes: 675862
raw_inventory_sha256: A6EE0472CAB6CA0DFC5B3EA04BDCFD3814E07BED2A76957FC1824BF89EAB8DC9
provider_attempts: 7
provider_requests: 33
provider_request_delta: 0
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
temp_files: 1
targeted_processes: 0
pester_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths: 341
gateway_tcp_reachable: true
credential_present: true
provider_capability: false
provider_process_started: false
automatic_retry: false
agent_json_schema_rerun: false
strict_on_execution: false
target_case: ProviderStrictOffControl
target_attempt: 1
joint_closure: false
```

No provider or raw-evidence delta occurred during the preflight.

### 42.3 Exactly one off-control provider execution

Only after exact `MATCH`, Codex reverified the reporter lock, off-control destination
absence, and strict-on destination absence, then invoked exactly:

```powershell
& scripts/run-phase00-e1.ps1 -CaseId ProviderStrictOffControl -Attempt 1 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

No `-AllowOverwrite`, model override, retry, strict-on call, parallel provider call, or
`AgentJsonSchema` rerun occurred. The one process completed with exit zero in 28.2
seconds and produced capture-integrity PASS:

```yaml
case_id: ProviderStrictOffControl
attempt: 1
capture_integrity_status: PASS
capture_reason_codes: []
run_sha256: DA8C7818BDDB81CCDCB6B82E82AC33B7BD3DF70D4E505533CFBC9105F4DC3C8A
provider_process_attempts: 1
```

Capture-integrity PASS did not pre-authorize a case verdict. The oracle was run only
after immutable capture completed.

### 42.4 Immutable raw evidence

Exactly six raw artifacts were added:

| Artifact | Bytes | Lines | File SHA-256 |
|---|---:|---:|---|
| `raw/provider-strict-off-control/attempt-001.forwarder.ndjson` | 1518 | 5 | `C2BD0E02B340EA73EA2E4926AA0CFE85A095CC42C58F6E0FA0D14CA1D70F8B0B` |
| `raw/provider-strict-off-control/attempt-001.run.json` | 17817 | 371 | `DA8C7818BDDB81CCDCB6B82E82AC33B7BD3DF70D4E505533CFBC9105F4DC3C8A` |
| `raw/provider-strict-off-control/attempt-001.sessions/session-001.jsonl` | 8868 | 10 | `B15E8624C3C356EC76C6BC4B0D345A4AF0501D21D64C44578C8F70FFC96F5E3A` |
| `raw/provider-strict-off-control/attempt-001.sessions/session-002.jsonl` | 3962 | 10 | `77C2990D8256A1D515C99703B3AD98F3048F583D10470AB782B57E487AD9DC30` |
| `raw/provider-strict-off-control/attempt-001.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |
| `raw/provider-strict-off-control/attempt-001.stdout.jsonl` | 54529 | 165 | `4D7F8F96999868F509534D19CA5A0C5DF1BD4EC10DC3F1B6DCF26FC582A91BA8` |

The sanitized source-capture hashes were:

```yaml
forwarder_capture_sha256: 9FF71C5611B8D9731C961FF1FF1977FA0BD0A0D972960231EDF0E2B8A457C53A
stdout_capture_sha256: 0DDDBD6576EE124CAA2AD6F450E254532D7E24AB0A8C5E7EF3A28366EF277EE1
stderr_capture_sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
session_001_capture_sha256: 4787057C4D9DF00E034BA9515F0DF6273F4FAE5D9AA16A516D27DF06D90386F4
session_002_capture_sha256: 1BB733443FDCFDB9897E01CE32767966AD11E2785937BFE11E6680CE6696A97B
```

No raw transcript is reproduced here. Inventory validation proved the previous 36-file
tree unchanged:

```yaml
prior_raw_files: 36
prior_raw_bytes: 675862
prior_raw_inventory_sha256: A6EE0472CAB6CA0DFC5B3EA04BDCFD3814E07BED2A76957FC1824BF89EAB8DC9
target_raw_files: 6
target_raw_bytes: 86694
target_raw_inventory_sha256: F32D0BE1A7F5738271814045076FE25ACE070DE68B3400A38036A4DDEA690343
total_raw_files: 42
total_raw_bytes: 762556
total_raw_inventory_sha256: 88CB924557B439D68D8B60BB98F5D1ED54E9D7A8667E0C42A2FBE8ADF2616383
provider_attempts_after: 8
provider_requests_after: 36
provider_attempt_delta: 1
provider_request_delta: 3
```

### 42.5 Oracle INVALID_RUN and exact identity mismatch

`Read-Phase00E1AttemptEvidence` projected the capture successfully with one attributable
result and no projection reason code. `Test-Phase00E1Attempt` nevertheless returned the
contractually terminal verdict:

```yaml
status: INVALID_RUN
reason_code: E1_STRICT_IDENTITY_MISMATCH
projection_status: PASS
projection_reason_codes: []
attributable_results: 1
```

Nine of ten locked identity fields matched exactly. Only the yield-parameters identity
differed:

```yaml
PromptSha256: MATCH
AssignmentSha256: MATCH
OutputSchemaSha256: MATCH
AgentSha256: MATCH
YieldParametersSha256:
  expected: BA45FA65ACE1C6653B74557015A2993085CF72FAF126D2CB01A76553DE05279C
  actual: DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE
  match: false
Agent: MATCH
Model: MATCH
RuntimeSha256: MATCH
RuntimeVersion: MATCH
Gateway: MATCH
```

The selected live forwarder projection independently carried the same actual
`DB58E598...4EEE` hash, so the sanitized capture and the forwarder evidence agree with
each other. Additional safe structural facts were:

```yaml
selected_forwarder_projection_count: 1
forwarder_yield_parameters_sha256: DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE
pi_no_strict_state: PRESENT_1
pi_no_strict_effective: true
yield_strict_field_present: false
local_schema_rejection_count: 0
local_schema_retry_count: 0
yield_attempt_count: 1
protected_unchanged: true
```

The expected `BA45...279C` constant is locked in
`scripts/lib/phase00-e1-evidence.ps1:5038` and mirrored by focused fixtures at
`scripts/tests/phase00-e1.Tests.ps1:2965` and
`scripts/tests/phase00-e1.Tests.ps1:3467`. The current focused tests synthesize that
identity; they do not prove that the pinned live runtime emits it under
`PI_NO_STRICT=1`. This diagnosis is read-only. No oracle, fixture, test, helper, or raw
artifact was changed, and no conclusion about strict behavior is claimed from an
identity-invalid arm.

### 42.6 Independent post-error audit

The post-error audit completed at `2026-08-10T13:57:52.0819284+07:00`:

```yaml
post_error_audit: PASS
failure_count: 0
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
authoritative_case_records: 5
strict_on_destination_present: false
case_5_present: false
conclusion_present: false
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
temp_roots: 1
temp_files: 1
temp_file_name: malformed-source.jsonl
temp_file_bytes: 129
temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
targeted_omp_or_forwarder_processes: 0
pester_processes: 0
reporter_sha256: 0C57F113B2811FCC5EAEE3170B38CFEDAC115E462929F631BAB9F6C135C440AE
test_sha256: 569111619F2B242021CAAEABDCB4D010942E726C6254D777FEBF1D7A8DCA797A
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_changelog_append: 347
changelog_lines_before_append: 6143
changelog_bytes_before_append: 264414
changelog_sha256_before_append: 5D73D66F0CB11610A3D6402595BDD8F1915629598498581E1100DC5BD7C46343
product_or_template_changed: false
joint_closure: false
```

One compact read-only audit command was parser-rejected before execution because a
`foreach` token lacked whitespace; the corrected audit above then passed. After reporter
disposal, another compact temp query falsely displayed zero roots due the same style of
parameter-token compression. Direct absolute-path verification proved the historical
root and file were still present, followed by the exact 1/1/129-byte/hash measurement
shown above. Neither measurement error had provider capability or mutated a file.

### 42.7 Reporter disposal and mandatory stop boundary

The exact reporter and test were deleted after official consumption and the post-error
audit, then verified absent. Direct absolute verification reconfirmed the historical
residue:

```yaml
deleted_reporter: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-018.ps1
deleted_reporter_sha256: 0C57F113B2811FCC5EAEE3170B38CFEDAC115E462929F631BAB9F6C135C440AE
deleted_test: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-018.Tests.ps1
deleted_test_sha256: 569111619F2B242021CAAEABDCB4D010942E726C6254D777FEBF1D7A8DCA797A
deleted_files_present_after: false
historical_root_present_after: true
historical_file_present_after: true
historical_temp_roots_after: 1
historical_temp_files_after: 1
historical_temp_bytes_after: 129
historical_temp_sha256_after: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
```

Checkpoint 018 changed only the six immutable off-control raw artifacts and this English
changelog. It did not create case 5, an E1 conclusion, or a manifest transition.

Codex stops on `INVALID_RUN` exactly as required. There is no automatic retry, and
attempt 1 must never be overwritten. `ProviderStrictOn` is not eligible. Any future
continuation requires a separately reviewed remediation decision for the strict identity
contract, preservation of attempt 1, a new complete preflight, and—only if explicitly
authorized by the remediated contract—a new attempt number. E1, T-00.4, and Phase 00
remain incomplete. Opus audit remains pending quota, and Codex claims no joint closure.

## 43. User-approved strict-control harness remediation before replacement attempt 2

Timestamp: `2026-08-10T15:17:53.6610024+07:00`

The user explicitly approved the fail-closed remediation design after checkpoint 018.
This checkpoint changes only the E1 evidence harness, its tests, and this English
changelog. It does not execute a provider, alter a fixture, modify a product/template
surface, create case 5, write an E1 conclusion, or transition the manifest.

### 43.1 Root cause established from the pinned OMP source

Read-only tracing through the pinned `omp/17.2.10` source established two coupled
harness-model defects and one genuine control outcome:

1. `packages/coding-agent/src/tools/yield.ts` constructs the real provider-facing
   `yield` parameters as a wrapper whose successful data schema is nested beneath
   `properties.result.anyOf[*].properties.data`. The old forwarder projected only
   `parameters.properties.data`, a synthetic path used by the tests but not by the
   pinned `YieldTool`.
2. `packages/ai/src/providers/openai-responses.ts` computes effective strictness from
   `!PI_NO_STRICT`, then passes that decision to `adaptSchemaForStrict`. Consequently,
   the strict-off arm transmits the upgraded non-strict parameters while the strict-on
   arm transmits the strict-adapted parameters. Their provider-wire parameter hashes
   are therefore intentionally arm-specific. The approved design and implementation
   plan require cross-arm equality for prompt, assignment, output schema, agent, model,
   runtime, and gateway; they do not require equality of the transmitted
   `YieldParametersSha256`.
3. Preserved off-control attempt 1 also genuinely failed to exercise the behavioral
   discriminator: its only provider-returned yield was already conforming, with no
   local schema rejection and no retry. Correcting the harness must not convert that
   historical attempt into PASS.

The approved remediation therefore preserves attempt 1 as immutable invalid history,
repairs the measurement/oracle contract, and permits exactly one separately authorized
replacement attempt 2 using the byte-identical frozen fixture. It does not weaken the
behavioral acceptance criteria and does not permit an automatic retry.

### 43.2 Test-first RED evidence

Tests were changed before implementation to model the real OMP wrapper and the two
observed arm-local wire identities:

```yaml
strict_off_yield_parameters_sha256: DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE
strict_on_yield_parameters_sha256: BA45FA65ACE1C6653B74557015A2993085CF72FAF126D2CB01A76553DE05279C
cross_arm_invariants:
  - PromptSha256
  - AssignmentSha256
  - OutputSchemaSha256
  - AgentSha256
  - Agent
  - Model
  - RuntimeSha256
  - RuntimeVersion
  - Gateway
arm_local_hash_consistency_required: true
```

Pester 3.4.0 initially matched zero tests when supplied `It` names; no test or provider
ran in that zero-match measurement. Re-running with the two enclosing `Describe` names
produced the required RED state:

```yaml
focused_red_total: 6
focused_red_passed: 3
focused_red_failed: 3
failure_1: pinned OMP YieldTool wrapper projected zero allowed properties instead of allowed
failure_2: valid arm-specific strict pair returned INVALID_RUN instead of PASS
failure_3: pair outcome propagation remained INVALID_RUN because the off arm was rejected by the old shared-hash oracle
duration_seconds: 1.57
provider_process_started: false
```

These failures reproduced the diagnosed defects rather than a syntax or environment
problem.

### 43.3 Minimal implementation

The following bounded changes were then made:

- `scripts/lib/phase00-e1-forwarder.mjs`
  - added `findYieldDataSchema`;
  - supports the legacy direct data path and the pinned wrapper path beneath
    `result` combinators;
  - returns a schema only when exactly one object candidate exists, so absence or
    ambiguity remains fail-closed;
  - retains canonical full-parameters hashing and the privacy-minimized projection.
- `scripts/lib/phase00-e1-evidence.ps1`
  - pins `DB58...4EEE` for `ProviderStrictOffControl` and `BA45...279C` for
    `ProviderStrictOn`;
  - retains the per-arm check that every selected forwarder projection hash equals
    that attempt's identity hash;
  - centralizes the true cross-arm invariant identity field list and uses it in both
    the pair oracle and `cross_arm_identity_equal` case-record observation;
  - updates both forwarder source pins to the remediated source hash.
- `scripts/tests/phase00-e1.Tests.ps1`
  - adds a regression fixture with the pinned `YieldTool` result wrapper;
  - makes synthetic strict-arm evidence use the correct arm-specific hashes;
  - removes the controlled provider-wire hash from cross-arm equality mutations;
  - explicitly proves that an intra-arm projection/identity hash mismatch is still
    `INVALID_RUN / E1_STRICT_IDENTITY_MISMATCH`.

The resulting file identities before this changelog append are:

| File | Bytes | Lines | SHA-256 |
|---|---:|---:|---|
| `scripts/lib/phase00-e1-forwarder.mjs` | 13191 | 404 | `9E646CE0453AC08A77CFE59E774B44C31679E1BBC0AF181EBAAF482FB6804B25` |
| `scripts/lib/phase00-e1-evidence.ps1` | 289943 | 6662 | `9742C38B2A1BED22D6555670C059CE598A25A73B758CBEAE93CEB9CA73990FC8` |
| `scripts/tests/phase00-e1.Tests.ps1` | 207693 | 4180 | `1E808806D83E057F13DC12CBCF2E662A668ED00C03B86F687BD90C3C235EFECA` |

The frozen `provider-strict.md`, `phase00-e1-provider-strict.md`, output schema,
assignment, model, runtime, gateway, and all fourteen E1 fixture files remain unchanged.

### 43.4 GREEN verification and follow-on corrections

The first focused run after implementation passed all six selected tests. The first
full run then intentionally exposed two remaining locations that encoded the old model:
the forwarder SHA pin and the case-record writer's whole-object identity comparison.
Those four failing assertions were:

```yaml
first_focused_green: 6/6 PASS
first_full_total: 76
first_full_passed: 72
first_full_failed: 4
remaining_defect_1: forwarder lifecycle rejected the new source SHA
remaining_defect_2: strict-pair case record reported cross_arm_identity_equal false
remaining_defect_3: READY artifact contract rejected the stale forwarder pin
remaining_defect_4: partial-history READY artifact contract rejected the stale forwarder pin
```

The pin and case-record comparison were corrected without changing the approved
semantics. The previously failing groups then passed `10/10`, followed by the complete
fresh GREEN run:

```yaml
focused_follow_on: 10/10 PASS (7.50 seconds)
full_pester: 76/76 PASS (17.11 seconds)
failed: 0
skipped: 0
node_syntax_exit: 0
powershell_parse_errors:
  phase00-e1-evidence.ps1: 0
  phase00-e1.Tests.ps1: 0
  run-phase00-e1.ps1: 0
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
provider_process_started: false
```

### 43.5 Historical attempt 1 remains immutable and invalid

The current helper deliberately rejects the historical attempt 1 lifecycle because its
run envelope pins the old forwarder source SHA `9C88...D952`, while the remediated
forwarder is `9E64...4B25`. A bounded re-read returned:

```yaml
projection_status: INVALID_RUN
projection_reason_codes:
  - E1_FORWARDER_LIFECYCLE_INVALID
analysis_status: INVALID_RUN
analysis_reason_codes:
  - E1_FORWARDER_LIFECYCLE_INVALID
identity_yield_parameters_sha256: DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE
selected_projection_yield_parameters_sha256: DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE
pi_no_strict_state: PRESENT_1
yield_attempt_count: 1
first_attempt_forbidden: false
local_schema_rejection_count: 0
local_schema_retry_count: 0
```

Only those safe fields were emitted; no transcript, prompt, reasoning, provider body, or
result payload was printed. This replay limitation does not overwrite or supersede the
official checkpoint-018 verdict. It adds a second reason the old capture cannot become
authoritative under the remediated harness, while the safe behavior facts independently
confirm the control was not exercised.

All six attempt-001 raw artifacts remain byte-identical:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `attempt-001.forwarder.ndjson` | 1518 | `C2BD0E02B340EA73EA2E4926AA0CFE85A095CC42C58F6E0FA0D14CA1D70F8B0B` |
| `attempt-001.run.json` | 17817 | `DA8C7818BDDB81CCDCB6B82E82AC33B7BD3DF70D4E505533CFBC9105F4DC3C8A` |
| `attempt-001.sessions/session-001.jsonl` | 8868 | `B15E8624C3C356EC76C6BC4B0D345A4AF0501D21D64C44578C8F70FFC96F5E3A` |
| `attempt-001.sessions/session-002.jsonl` | 3962 | `77C2990D8256A1D515C99703B3AD98F3048F583D10470AB782B57E487AD9DC30` |
| `attempt-001.stderr.jsonl` | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |
| `attempt-001.stdout.jsonl` | 54529 | `4D7F8F96999868F509534D19CA5A0C5DF1BD4EC10DC3F1B6DCF26FC582A91BA8` |

```yaml
attempt_1_raw_files: 6
attempt_1_raw_bytes: 86694
attempt_1_overwritten: false
```

### 43.6 Boundary state before fresh complete preflight

```yaml
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths: 347
changelog_lines_before_append: 6469
changelog_bytes_before_append: 277860
changelog_sha256_before_append: 662508D8F589C210B99A28DA32CA46A658D5A169121E7710F94720018B606391
targeted_provider_or_forwarder_processes: 0
strict_on_destination_present: false
off_attempt_2_destination_present: false
case_5_present: false
conclusion_present: false
historical_temp_file_present: true
historical_temp_file_bytes: 129
historical_temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
product_or_template_changed: false
fixture_changed: false
provider_process_started: false
automatic_retry: false
joint_closure: false
```

The next authorized action is a fresh complete preflight for
`ProviderStrictOffControl` attempt 2. Provider execution remains forbidden unless that
preflight returns exact `MATCH`. If it matches, exactly one attempt-2 process may run.
Any non-PASS/invalid/ambiguous/timeout result requires an immediate stop with no retry;
strict-on remains ineligible until the off-control attempt passes.

## 43.7 Fresh complete offline preflight after reporter remediation

Timestamp: `2026-08-10T18:20:29.5783285+07:00`

The disposable reporter self-test was run first under Windows PowerShell 5.1 with
Pester 3.4.0. It passed `9/9` with `0` failures, `0` skipped, and `0` pending. The
reporter was then run from the locked repository root in `-DryRun` mode. This was a
complete offline preflight for `ProviderStrictOffControl` attempt 2; it did not invoke
`scripts/run-phase00-e1.ps1`, the forwarder, the provider runtime, or any external
provider request.

```yaml
command: C:\Users\MrThien\AppData\Local\Temp\omp-phase00-e1-preflight-reporter-019.ps1 -DryRun
verdict: MATCH
checks: 97
failures: []
duration_seconds: 128.99
target_case: ProviderStrictOffControl
target_attempt: 2
focused_pester_pwsh7: 76/76
focused_pester_windows_powershell: 76/76
all_pester_pwsh7: 304/304
all_pester_windows_powershell: 304/304
validator_pwsh7: 99 passed / 1 warning / 0 failed
validator_windows_powershell: 99 passed / 1 warning / 0 failed
node_syntax_exit: 0
artifact_contract: 6/6
protected_surface: 9/9
fixture: 14 files / 7891 bytes / AF2F446644F0EBE91942FCA92F53A78363899D3390F2F66466FE1B997686168B
raw_before_after: 42 files / 762556 bytes / 88CB924557B439D68D8B60BB98F5D1ED54E9D7A8667E0C42A2FBE8ADF2616383
provider_before_after: 8 attempts / 36 requests / delta 0
pinned_source: 3a8591a8af5b6d200088d12ca75a5517cb064fa8 (clean)
pinned_runtime: omp/17.2.10 / 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
manifest: E1 READY; T-00.4 NOT_STARTED
targeted_processes_after: 0
pester_processes_after: 0
provider_process_started: false
automatic_retry: false
agent_json_schema_rerun: false
strict_on_execution: false
joint_closure: false
```

The preflight also preserved the disclosed historical residue at
`C:\Users\MrThien\AppData\Local\Temp\phase00-e1-test-2b369a91c65548c0a43d2aa4ffde062b\malformed-source.jsonl`
(`129` bytes, SHA-256 `C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817`).
The working tree remained on `main` at `62fecf277dc9d5e47d06319387eac747462214c1`,
with zero staged paths and the expected `347` expanded dirty paths. No product/template,
manifest, fixture, or immutable attempt-1 artifact changed.

This `MATCH` is an offline gate result, not an E1 PASS. Per Task 10A/Task 11, the next
and only eligible action is `AgentJtd` attempt 2, and it still requires explicit user
authorization in this session. No provider traffic was authorized or performed here.

## 43.8 Fail-closed no-op after incorrect target reconstruction

Timestamp: `2026-08-10T19:18:40.2259508+07:00`

The preceding sentence in section 43.7 reconstructed the next provider target
incorrectly from the older Task 10A/Task 11 plan state. The latest authoritative
checkpoint in sections 42.7 and 43.6 instead makes `ProviderStrictOffControl` attempt 2
the only eligible replacement attempt. `AgentJtd` attempt 2 had already completed at
`2026-08-10T08:34:07+07:00`, passed the current projector/oracle, and was already bound
to the canonical `case-1-agent-jtd.yml` record.

The user confirmed the explicitly stated but incorrect `AgentJtd` target. Before the
mistake was recognized, Codex ran this command once:

```powershell
pwsh.exe -NoProfile -File scripts/run-phase00-e1.ps1 -CaseId AgentJtd -Attempt 2 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak' -Model 'omniroute/codex/gpt-5.6-sol-high'
```

The canonical no-overwrite guard rejected the command at
`scripts/lib/phase00-e1-evidence.ps1:1527` because
`raw/agent-jtd/attempt-002.stdout.jsonl` already existed. The command exited `1` before
creating a provider process. There was no overwrite, retry, new raw artifact, case
record mutation, manifest mutation, or product/template mutation.

```yaml
command_outcome: FAIL_CLOSED_NO_OP
provider_process_started: false
automatic_retry: false
raw_files_after: 42
raw_bytes_after: 762556
raw_inventory_sha256_after: 88CB924557B439D68D8B60BB98F5D1ED54E9D7A8667E0C42A2FBE8ADF2616383
provider_attempts_after: 8
provider_requests_after: 36
targeted_processes_after: 0
agent_jtd_attempt_2_run_sha256: 7C5AA7841DBA9B324B850AE766320B6D7F43DA11310A2077500AE575A6A53EF3
agent_jtd_attempt_2_projection_status: PASS
agent_jtd_attempt_2_oracle_status: PASS
agent_jtd_attempt_2_reason_code: E1_AGENT_JTD_PASS
agent_jtd_case_record_sha256: BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4
```

Before that no-op, reporter 019 had been updated only to pin the section-43.7
changelog hash. Its resulting SHA-256 was
`FDABA3E04484D41F1908AA7F875D7ED35FA7D6B33C4E6F101DD8F195C38543B2`;
its self-test passed `9/9`, and its complete dry run returned `MATCH` with `97/97`
checks, provider-request delta zero, and target
`ProviderStrictOffControl` attempt 2. Because this incident append changes the
changelog identity again, that preflight cannot be reused for a provider call.

The corrected next action is a new reporter hash lock, self-test, and fresh complete
preflight for `ProviderStrictOffControl` attempt 2. The current-session confirmation
named `AgentJtd`, so it is not silently reinterpreted as authorization for the different
strict-off provider process. No strict-off attempt 2 or strict-on process ran at this
checkpoint, and no joint closure is claimed.

## 44. `ProviderStrictOffControl` attempt 2 INVALID_RUN — aborted-response forwarder lifecycle

Timestamp: `2026-08-10T19:30:51.6548525+07:00`

### 44.1 Exact authorization and fresh preflight

After section 43.8 corrected the target, the user explicitly authorized exactly
`ProviderStrictOffControl` attempt 2. The disposable reporter was updated only to pin
the new changelog identity `EB030071F5A1308FBF3D57DF0432CDE0058C4173CD878CEE53F5349E1127579D`.
Its resulting SHA-256 was
`BAF7CB6BB88DBF8659F29B281ED65DB1F3811C4AA63F191FE84AB7B43A1EBD97`;
the unchanged structural test SHA-256 was
`D98957E702AF826BC2E93575F1771A1397BDE88308450809CFA61CBC3CD2AA7E`.
The self-test passed `9/9` with zero failures, skipped, or pending tests.

The complete preflight then returned exact `MATCH` immediately before execution:

```yaml
verdict: MATCH
checks: 97
failures: []
duration_seconds: 171.01
target_case: ProviderStrictOffControl
target_attempt: 2
focused_pester_pwsh7: 76/76 PASS
focused_pester_windows_powershell: 76/76 PASS
all_pester_pwsh7: 304/304 PASS
all_pester_windows_powershell: 304/304 PASS
validator_pwsh7: 99 passed / 1 warning / 0 failed
validator_windows_powershell: 99 passed / 1 warning / 0 failed
node_syntax_exit: 0
authority_hashes: 17/17 MATCH
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
raw_files: 42
raw_bytes: 762556
raw_inventory_sha256: 88CB924557B439D68D8B60BB98F5D1ED54E9D7A8667E0C42A2FBE8ADF2616383
provider_attempts: 8
provider_requests: 36
provider_request_delta: 0
off_attempt_2_present: false
strict_on_present: false
provider_process_started: false
```

### 44.2 Exactly one authorized process and fail-closed result

After rechecking target absence and zero targeted processes, Codex invoked exactly:

```powershell
& scripts/run-phase00-e1.ps1 -CaseId ProviderStrictOffControl -Attempt 2 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

No `-AllowOverwrite`, model override, retry, parallel call, strict-on call, or
`AgentJsonSchema` rerun occurred. The OMP process started once, made three deduplicated
provider requests, received three response ends, made zero provider retries, exited
zero, and left no child process. The runner nevertheless and correctly stopped with:

```yaml
capture_integrity_status: INVALID_RUN
reason_code: E1_FORWARDER_LIFECYCLE_INVALID
case_status: null
case_oracle_evaluated: false
provider_process_attempts: 1
actual_provider_requests: 3
automatic_retries: 0
omp_exit_code: 0
omp_timed_out: false
capture_verification_status: PASS
capture_verification_reason_codes: []
sanitized_source_artifacts: 5
forwarder_required: true
forwarder_pi_no_strict_effective: true
forwarder_exit_code: -1
forwarder_timed_out: true
forwarder_port_closed: true
forwarder_remaining_child_pids: 0
forwarder_projection_count: 2
forwarder_record_count: 4
forwarder_request_indexes: [1, 3]
forwarder_record_types:
  - phase00_e1_forwarder_ready
  - phase00_e1_request_projection
  - phase00_e1_request_projection
  - phase00_e1_forwarder_closed
cleanup_succeeded: true
protected_repository_unchanged: true
live_home_unchanged: true
```

The runner error explicitly prohibited an automatic rerun. `ProviderStrictOn` remained
forbidden and was not started.

### 44.3 Immutable attempt-2 raw evidence

Exactly six no-overwrite artifacts were created and are now immutable:

| Artifact | Bytes | Lines | SHA-256 |
|---|---:|---:|---|
| `raw/provider-strict-off-control/attempt-002.forwarder.ndjson` | 1033 | 4 | `F263B2BA7653C236972AA4D504B9DFC0C6A9EBD91504E3D67563DC785462D0EE` |
| `raw/provider-strict-off-control/attempt-002.run.json` | 17826 | 372 | `DD6CC66440CBF34CC75CD8D7F717C3E33599C843A45A38BC6D65F5146CA2D759` |
| `raw/provider-strict-off-control/attempt-002.sessions/session-001.jsonl` | 7997 | 10 | `2F07F7B3520413D130F5D2405D65D14716AE4930C388A6FF0443576ADB1DE5C8` |
| `raw/provider-strict-off-control/attempt-002.sessions/session-002.jsonl` | 3964 | 10 | `697ED204F906ED7EB7300A39A46B410950C2C577C3CDA87A9DADD06223609326` |
| `raw/provider-strict-off-control/attempt-002.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |
| `raw/provider-strict-off-control/attempt-002.stdout.jsonl` | 53421 | 163 | `67FDFDB4E3AC9E340AFBAFDEFE91B73C530FE2FA565BEA74BDDC6FE1E17A5549` |

```yaml
prior_raw_files: 42
prior_raw_bytes: 762556
prior_raw_inventory_sha256: 88CB924557B439D68D8B60BB98F5D1ED54E9D7A8667E0C42A2FBE8ADF2616383
target_raw_files: 6
target_raw_bytes: 84241
target_raw_inventory_sha256: 1BFE44A93486F9D150DE8FEC5263BC7D16FC4F7E98D0036B5993E0127D9E3699
total_raw_files: 48
total_raw_bytes: 846797
total_raw_inventory_sha256: 82C100EA27151EA2B4EC79C8A9B4CD982D6B13484749C5B4527F934B2A6850F2
provider_attempts_after: 9
provider_requests_after: 39
provider_attempt_delta: 1
provider_request_delta: 3
```

No transcript, prompt, reasoning, provider body, or result payload is reproduced here.

### 44.4 Root cause confirmed by an offline abort probe

The provider/session metadata records three completed requests, while the forwarder
recorded only global request indexes 1 and 3. Index 2 was the child request that carried
the `yield` tool. Source tracing found the lifecycle race:

- `phase00-e1-forwarder.mjs:278-290` writes the privacy-minimized projection only on
  upstream response `end` and pipes the upstream response to the downstream client;
- it does not destroy the upstream response/request when the downstream client closes
  after consuming the terminal provider event but before the HTTP stream ends;
- `phase00-e1-forwarder.mjs:334-352` can therefore close the listener and write the
  final `phase00_e1_forwarder_closed` record while an orphaned upstream socket still
  keeps the Node process alive;
- `Stop-Phase00E1Forwarder` then waits 15 seconds, kills the still-live process, and
  correctly makes lifecycle validity false at
  `phase00-e1-evidence.ps1:2553-2618`.

This was reproduced without credentials, the configured gateway, or any provider call.
A disposable loopback gateway sent a response prefix and deliberately kept the upstream
HTTP response open; the downstream client consumed the prefix and disconnected. The
unmodified forwarder wrote `ready` and `closed`, wrote zero request projections, emitted
no stderr, and did not exit within the bounded 2.5-second observation window. The probe
then killed the process, removed its generated temp directory, and deleted its own
temporary script. This exactly falsifies the prior assumption that a `closed` record
implies the Node event loop has no live upstream handle.

The defect is in the evidence forwarder lifecycle, not a provider/product verdict. It
also conflicts with the approved design requirement at design lines 341 and 359-361 to
persist the sanitized request projection at the last-hop boundary and terminate the
forwarder before cleanup. No source was changed during this diagnosis.

### 44.5 Post-error boundary and mandatory stop

```yaml
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
strict_on_destination_present: false
case_5_present: false
conclusion_present: false
historical_temp_file_bytes: 129
historical_temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
targeted_processes_after: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_this_append: 353
joint_closure: false
```

Attempt 2 remains `INVALID_RUN` and immutable. There is no case-5 record, conclusion,
manifest transition, E1 PASS, T-00.4 start, strict-on eligibility, automatic retry, or
joint closure. The next possible work is an explicitly reviewed test-first remediation
of downstream-abort/upstream-handle lifecycle in the forwarder and its tests. Any future
replacement attempt must use a new attempt number, a new complete offline checkpoint,
and separate explicit user authorization; it is not authorized by this attempt-2 grant.

### 44.6 Disposable cleanup

After official consumption and the post-error audit, reporter 019, its structural test,
and the temporary offline abort-probe script were deleted and verified absent. The
reporter and test identities before deletion were respectively
`BAF7CB6BB88DBF8659F29B281ED65DB1F3811C4AA63F191FE84AB7B43A1EBD97`
and `D98957E702AF826BC2E93575F1771A1397BDE88308450809CFA61CBC3CD2AA7E`.
The disclosed historical `malformed-source.jsonl` residue remains present and unchanged
at `129` bytes with SHA-256
`C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817`.

## 45. Offline test-first remediation of the aborted-response forwarder lifecycle

Timestamp: `2026-08-10T19:58:29.4401454+07:00`

### 45.1 Approved scope and implementation authority

The user approved a narrowly scoped offline remediation after section 44 diagnosed the
forwarder lifecycle defect. Work remained sequential in the existing dirty `main`
workspace. No subagent, branch, worktree, staging, commit, reset, cleanup of user work,
provider process, provider request, raw-attempt rewrite, manifest transition, or strict-on
execution was authorized or performed.

The approved design addendum and its test-first implementation plan are:

| Artifact | Lines | Bytes | SHA-256 |
|---|---:|---:|---|
| `docs/superpowers/specs/2026-08-10-phase-00-e1-forwarder-abort-lifecycle-remediation-design.md` | 121 | 6140 | `5342C4AB17B4A2DF382FEF2F406967EB9D32854818777C662E45B62CAD111EC7` |
| `docs/superpowers/plans/2026-08-10-phase-00-e1-forwarder-abort-lifecycle-remediation-plan.md` | 364 | 20680 | `94DC949B0EC98291CE046BE6CDAF3C6BC76E2ECA123346B623822ACA2FBD9705` |

The plan has no unchecked step or placeholder. It preserves every fail-closed runner
oracle and treats `ProviderStrictOffControl` attempt 2 as immutable `INVALID_RUN`.

### 45.2 RED: real downstream abort reproduced by one focused regression

One Pester regression was added at
`scripts/tests/phase00-e1.Tests.ps1:1801-1992`. It starts the real E1 forwarder against
a disposable Node loopback gateway. The gateway returns HTTP `209`, writes the prefix
`E1_ABORT_PREFIX`, and deliberately leaves the upstream HTTP response open. A raw TCP
downstream consumes that prefix and disconnects before the controller sends `close`.

The first selection command incorrectly passed the `It` name to Pester 3.4.0's
`-TestName`, which filters `Describe` names; it selected `0` tests and was not accepted
as RED. No production source changed. The corrected exact `Describe` filter selected
one test and failed for the intended behavior:

```text
TOTAL=1 PASSED=0 FAILED=1
expected: exited=True;exit=0;projections=1;records=phase00_e1_forwarder_ready,phase00_e1_request_projection,phase00_e1_forwarder_closed;stderr_empty=True
actual:   exited=False;exit=-1;projections=0;records=phase00_e1_forwarder_ready,phase00_e1_forwarder_closed;stderr_empty=True
duration: 6.67 seconds
```

The test killed only its still-live disposable forwarder as bounded cleanup, stopped
the fake gateway, and removed its generated `phase00-e1-test-*` directory. This RED
matches the section-44 offline probe and proves the test catches the missing projection
and orphaned upstream handle rather than a syntax or fixture error.

### 45.3 Minimal GREEN implementation and source pins

The dependency-free forwarder now implements explicit relay ownership:

- `phase00-e1-forwarder.mjs:247` registers each upstream request in an active-relay
  set and provides idempotent `finish()` and `dispose()` operations;
- `phase00-e1-forwarder.mjs:301` persists the privacy-minimized projection exactly
  once as soon as upstream response headers establish the gateway status, before
  response headers or body bytes are relayed downstream;
- `phase00-e1-forwarder.mjs:348` disposes unfinished upstream response/request handles
  when the downstream closes;
- `phase00-e1-forwarder.mjs:387` makes `runLive` own the active-relay set; and
- `phase00-e1-forwarder.mjs:430` disposes a snapshot of all remaining relays after
  listener shutdown begins and before the sole `closed` record can complete the writer.

Normal response bytes and end-to-end headers remain unchanged. Local pre-forwarding
400/404/413 paths remain unchanged. Upstream errors remain fail-closed. Late response
callbacks observe a finished relay, destroy the late response, and cannot write after
the evidence writer closes.

The forwarder identity changed only after focused GREEN:

```yaml
forwarder_lines: 484
forwarder_bytes: 15532
forwarder_sha256_before: 9E646CE0453AC08A77CFE59E774B44C31679E1BBC0AF181EBAAF482FB6804B25
forwarder_sha256_after: D9CDAEB5FF4235658D10AD8371410E7F480ADEBDCD85C0F0EA13BFFCD53FA483
test_lines: 4359
test_bytes: 215345
test_sha256: 5C51E4294640F319656CFA4D594D79300A5EA55B91400532CDF89C2A82ABB9F1
evidence_helper_lines: 6662
evidence_helper_bytes: 289943
evidence_helper_sha256: 1357219ED83ABA0CB86DB711EB979678962FB0A59971187ED057FE7B4EA231CB
```

Exactly two executable source pins were updated to the new hash at
`phase00-e1-evidence.ps1:2394` and `phase00-e1-evidence.ps1:6554`. The old hash remains
unchanged inside immutable `attempt-002.run.json` because it truthfully identifies the
forwarder used for that historical attempt.

The focused GREEN chronology was:

```yaml
node_syntax_exit: 0
abort_regression_pwsh7: 1/1 PASS
abort_regression_duration_seconds: 1.53
normal_binary_relay_pwsh7: 1/1 PASS
normal_binary_relay_duration_seconds: 1.68
pin_lifecycle_and_ready_contract_pwsh7: 8/8 PASS
pin_lifecycle_and_ready_contract_windows_powershell: 8/8 PASS
```

The rejected destroy-only alternative would still lose the projection when the
downstream closes before upstream `end`. Relaxing the lifecycle oracle was also
rejected because it would bless a missing last-hop projection and a leaked handle.

### 45.4 Complete cross-shell offline verification

All verification was run after the final source and both pins were in place:

```yaml
node_check: PASS
focused_e1_pwsh7: 77/77 PASS
focused_e1_windows_powershell: 77/77 PASS
focused_delta_from_checkpoint_019: +1
all_phase00_pwsh7: 305/305 PASS
all_phase00_windows_powershell: 305/305 PASS
all_phase00_delta_from_checkpoint_019: +1
skipped_each_shell: 0
pending_each_shell: 0
repository_validator_pwsh7: 99 passed / 1 warning / 0 failed
repository_validator_windows_powershell: 99 passed / 1 warning / 0 failed
validator_exit_each_shell: 0
```

The sole validator warning remains the pre-existing advisory token-budget warning for
`template/.omp/RULES.md` (`226 < 300`). No new warning or failure appeared.

A direct sequential review of the final implementation against the approved design
found no Critical, Important, or Minor issue. The test exercises the real TCP/HTTP
boundary, derives literal expected records independently of production helpers, and
would fail for each load-bearing mutation: projection moved back to `end`, missing
downstream disposal, duplicate projection, wrong index/status, missing `closed`, leaked
port/process, non-zero exit, or stderr output.

### 45.5 Immutable and protected boundary audit

The final read-only audit returned:

```yaml
artifact_contract: 6/6 PASS
artifact_contract_codes:
  - P00-E1-FIXTURE
  - P00-E1-RUNTIME
  - P00-E1-PROTECTED-SURFACE
  - P00-E1-MANIFEST
  - P00-E1-CONCLUSION
  - P00-E1-READY
protected_surface: 9/9 MATCH
fixture_files: 14
fixture_bytes: 7891
fixture_inventory_sha256: AF2F446644F0EBE91942FCA92F53A78363899D3390F2F66466FE1B997686168B
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
raw_files: 48
raw_bytes: 846797
raw_inventory_sha256: 82C100EA27151EA2B4EC79C8A9B4CD982D6B13484749C5B4527F934B2A6850F2
provider_attempts: 9
provider_requests: 39
provider_attempt_delta_during_remediation: 0
provider_request_delta_during_remediation: 0
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
strict_on_destination_present: false
case_5_present: false
conclusion_present: false
authoritative_case_records: 5
targeted_processes_after: 0
historical_temp_roots: 1
historical_temp_file_bytes: 129
historical_temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_this_append: 355
changelog_lines_before_append: 7002
changelog_bytes_before_append: 302230
changelog_sha256_before_append: 17EFA6DF19B2CE7E4F577EF847B5CC4AED706D2C245035E4A117CEE5080BB58A
```

All six `ProviderStrictOffControl` attempt-2 files remain byte-identical to section
44.3, including forwarder SHA
`F263B2BA7653C236972AA4D504B9DFC0C6A9EBD91504E3D67563DC785462D0EE`
and run SHA
`DD6CC66440CBF34CC75CD8D7F717C3E33599C843A45A38BC6D65F5146CA2D759`.
The two session hashes, empty stderr hash, and stdout hash also match section 44.3
exactly. The one disclosed historical temp residue is the only matching temp root;
all remediation test directories were removed.

### 45.6 Status and next gate

This remediation is an offline harness GREEN, not an E1 experiment PASS. Attempt 2
remains immutable `INVALID_RUN` with `E1_FORWARDER_LIFECYCLE_INVALID`; it is not
reinterpreted, repaired in place, or selected. There is still no strict-on attempt,
case-5 record, conclusion, manifest transition, E1 PASS, T-00.4 start, automatic retry,
or joint closure.

The only possible next provider action is `ProviderStrictOffControl` attempt 3. It is
not authorized by this remediation approval. Before it can run, a new disposable
reporter must pin the final design, plan, changelog, forwarder, helper, test, raw,
protected, runtime, and source identities; its structural self-test must pass; a fresh
complete offline preflight must return exact `MATCH`; the attempt-3 destination must be
absent; and the user must give separate explicit authorization. `ProviderStrictOn`
remains ineligible unless the replacement strict-off control passes.

## 46. Fresh offline preflight for replacement `ProviderStrictOffControl` attempt 3

Timestamp: `2026-08-10T20:28:15.0182644+07:00`

### 46.1 Sequential scope and disposable reporter identity

Following section 45, Codex performed one fresh, complete, offline-only preflight for
the only eligible next case, `ProviderStrictOffControl` attempt 3. The work remained
sequential in the existing dirty `main` workspace. No subagent, branch, worktree,
staging, commit, reset, provider process, provider request, raw-artifact write, retry,
strict-on execution, manifest transition, or conclusion derivation was authorized or
performed.

The disposable reporter and its structural self-test were independently hashed before
execution:

| Artifact | Lines | Bytes | SHA-256 |
|---|---:|---:|---|
| `C:/Users/MrThien/AppData/Local/Temp/omp-phase00-e1-preflight-reporter-020.ps1` | 672 | 34367 | `B416BF8E4E515D5BDAE37288FC2305D42DCB3FF3E829C4EBC8FB76BB2DB200F4` |
| `C:/Users/MrThien/AppData/Local/Temp/omp-phase00-e1-preflight-reporter-020.Tests.ps1` | 86 | 4191 | `1439A1026252400DD18D478E5344ED473EFA96FD0E3165825387B2A3F3710C3B` |

The structural contract passed `9/9` with zero failures, skips, or pending tests. It
locks target case `ProviderStrictOffControl`, target attempt `3`, the fail-closed
provider flags, the exact `77` focused and `305` complete Phase 00 test counts, the
absence of the attempt-3 destination, and the absence of strict-on, case-5, and
conclusion destinations. Its AST contract permits the pinned runtime only for the
exact version probe and contains no E1 runner/provider invocation, overwrite, model
override, retry loop, or parallel execution.

### 46.2 Fresh complete preflight result

The reporter was invoked in dry-run mode from the repository root:

```powershell
& 'C:/Users/MrThien/AppData/Local/Temp/omp-phase00-e1-preflight-reporter-020.ps1' -DryRun
```

It completed with the exact fail-closed verdict below. The `101` checks are the full
reporter gate set; the increase from section 45 reflects the two remediation authority
documents now pinned and checked before and after the run.

```yaml
verdict: MATCH
mode: DRY_RUN
checks: 101
failures: []
target_case: ProviderStrictOffControl
target_attempt: 3
focused_pester_pwsh7: 77/77 PASS
focused_pester_windows_powershell: 77/77 PASS
all_phase00_pwsh7: 305/305 PASS
all_phase00_windows_powershell: 305/305 PASS
skipped_each_shell: 0
pending_each_shell: 0
validator_pwsh7: 99 passed / 1 warning / 0 failed
validator_windows_powershell: 99 passed / 1 warning / 0 failed
validator_warning: "approx-token-budget below target (226 < 300): template/.omp/RULES.md"
node_syntax_exit: 0
authority_hashes: 19/19 MATCH
fixture_files: 14
fixture_bytes: 7891
fixture_inventory_sha256: AF2F446644F0EBE91942FCA92F53A78363899D3390F2F66466FE1B997686168B
prior_case_records: 5
prior_case_reprojections: 5/5 PASS
raw_files: 48
raw_bytes: 846797
raw_inventory_sha256: 82C100EA27151EA2B4EC79C8A9B4CD982D6B13484749C5B4527F934B2A6850F2
provider_attempts: 9
provider_requests: 39
provider_request_delta: 0
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_runtime_version: omp/17.2.10
pinned_runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
historical_temp_file_bytes: 129
historical_temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
targeted_processes: 0
pester_processes: 0
gateway_tcp_reachable: true
credential_present: true
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths: 355
provider_capability: false
provider_process_started: false
automatic_retry: false
agent_json_schema_rerun: false
strict_on_execution: false
joint_closure: false
```

The 19/19 authority lock was:

```yaml
docs/superpowers/specs/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-design.md: 4A4C6CEFC5896B95591EB365CBB05F82FE2FDF6E20AF5B7E180CCAF39C54FB30
docs/superpowers/plans/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-plan.md: C06445019B99F517B77A4324014CC4C979D122CAB389514FF10AEEE05ADF80CF
docs/superpowers/specs/2026-08-10-phase-00-e1-forwarder-abort-lifecycle-remediation-design.md: 5342C4AB17B4A2DF382FEF2F406967EB9D32854818777C662E45B62CAD111EC7
docs/superpowers/plans/2026-08-10-phase-00-e1-forwarder-abort-lifecycle-remediation-plan.md: 94DC949B0EC98291CE046BE6CDAF3C6BC76E2ECA123346B623822ACA2FBD9705
scripts/lib/phase00-evidence.ps1: 403CD78585A4058986B280A07C7F2291488AFD79B3F3C513D6DAA667E6574BE5
scripts/lib/phase00-runtime-evidence.ps1: 90143F56236A0B4B24C2D680FCE33D0DAEA42DBB7F97A09D8F251069FAF9E9D7
scripts/lib/phase00-e1-forwarder.mjs: D9CDAEB5FF4235658D10AD8371410E7F480ADEBDCD85C0F0EA13BFFCD53FA483
scripts/lib/phase00-e1-evidence.ps1: 1357219ED83ABA0CB86DB711EB979678962FB0A59971187ED057FE7B4EA231CB
scripts/run-phase00-e1.ps1: 5C37E04BBD80F9D3233C9478432F6B88787B8FF93EAD1E9EDD1A89F3901D6FD7
scripts/validate-template.ps1: 45ED1190CDB223C771DE24E6A46AC9E29D062893940BDCA9FFDB6AEB18CF402B
scripts/tests/phase00-e1.Tests.ps1: 5C51E4294640F319656CFA4D594D79300A5EA55B91400532CDF89C2A82ABB9F1
spec/phases/phase-00-foundation.md: F0251A10AFE35BFA5EBF83FBBB99E18A05C47D79390D6ACD3198F307F3B7964C
docs/evidence/phase-00/manifest.yml: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md: 9115C02E7FCBAAA0ABF3382C6919087B993D784F62F79922EDB33831A8A99F64
docs/evidence/phase-00/E1/case-1-agent-jtd.yml: BAEB4AA668F2983A646B159CEF220DD4A454BCA6370E5D6536C5142C4C8E70B4
docs/evidence/phase-00/E1/case-1-agent-json-schema.yml: 56A7270C18EBC4BFEAE0AF1B7A9D98B75B2BD165CD2290CF7126B459BF10C33B
docs/evidence/phase-00/E1/case-2-caller-only.yml: 65620D40C323B3C0E8C8F925452846B70B1E258F873C01D4CD5427A009F90738
docs/evidence/phase-00/E1/case-3-caller-over-agent.yml: 58EA16AD5E39EAF62D01A44007B7165C8E3B8E4CB01FF8A90C99D85D020EEE8A
docs/evidence/phase-00/E1/case-4-session-only.yml: 71EF04AA77F635A0A7706D50E66297C76D7D8E607709B5B2E1AB28C70158CA6A
```

The one validator warning is the already-authorized advisory token-budget warning; no
warning was accepted through a broadened pattern. The reporter also reprojected the
five prior case records into disposable temp output and verified that the historical
raw tree, protected surface, fixture tree, live home, template `.omp`, source commit,
runtime identity, and disclosed historical residue remained unchanged.

### 46.3 Mandatory boundary before provider execution

This is an offline eligibility checkpoint only. It proves that attempt 3 may be
considered, not that it has run or passed. Attempt 2 remains immutable
`INVALID_RUN` with `E1_FORWARDER_LIFECYCLE_INVALID`; it is not repaired in place or
reclassified. The attempt-3 destination is still absent. There is still no strict-on
attempt, case-5 record, conclusion, manifest transition, E1 PASS, T-00.4 start,
automatic retry, provider capability, or joint closure.

Appending this checkpoint changes the changelog identity. The pre-append changelog was
`7208` lines, `311825` bytes, SHA-256
`9115C02E7FCBAAA0ABF3382C6919087B993D784F62F79922EDB33831A8A99F64`. Therefore the
reported `MATCH` is not itself a provider-execution authorization after this append:
any attempt-3 execution must first run a new disposable reporter against the final
post-append changelog hash and then receive separate explicit user authorization.

### 46.4 Disposable cleanup

After recording this checkpoint, reporter 020 and its structural self-test are deleted
and verified absent. The historical `malformed-source.jsonl` residue remains disclosed
and unchanged at `129` bytes with SHA-256
`C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817`. No other temp
roots or user files are removed.

## 47. `ProviderStrictOffControl` attempt 3 INVALID_RUN — control not exercised

Timestamp: `2026-08-10T20:55:59.4309471+07:00`

### 47.1 Exact authorization and final-state preflight

The user explicitly authorized exactly one replacement `ProviderStrictOffControl`
attempt 3. This authorization did not include an automatic retry, attempt 4,
`ProviderStrictOn`, another matrix case, a case record, conclusion derivation,
manifest transition, T-00.4, branch/worktree creation, staging, commit, push, or joint
closure. Work remained sequential with no subagent.

Reporter 021 was recovered from the exact final reporter-020 deletion record, then
changed only for its disposable identifier and the post-section-46 changelog SHA-256.
Several in-memory archive-extraction attempts failed before file creation; none wrote
repository state or had provider capability. The final reporter identities were:

| Artifact | Lines | Bytes | SHA-256 |
|---|---:|---:|---|
| `C:/Users/MrThien/AppData/Local/Temp/omp-phase00-e1-preflight-reporter-021.ps1` | 672 | 34367 | `25F973484F2A6DC6228796C12FB2804E4B065DDB8DED7FEB0BC649A659C09F31` |
| `C:/Users/MrThien/AppData/Local/Temp/omp-phase00-e1-preflight-reporter-021.Tests.ps1` | 86 | 4191 | `9BE4D11644F87E3EBCF3C286D25634EA5EE47B5A1DA3DC74B3FBD70C1BA76989` |

Both files parsed with zero syntax errors. The structural contract passed `9/9`
with zero failures, skips, or pending tests. The fresh complete preflight then returned:

```yaml
verdict: MATCH
mode: DRY_RUN
checks: 101
failures: []
duration_seconds: 181.88
target_case: ProviderStrictOffControl
target_attempt: 3
focused_pester_pwsh7: 77/77 PASS
focused_pester_windows_powershell: 77/77 PASS
all_phase00_pwsh7: 305/305 PASS
all_phase00_windows_powershell: 305/305 PASS
skipped_each_shell: 0
pending_each_shell: 0
validator_pwsh7: 99 passed / 1 warning / 0 failed
validator_windows_powershell: 99 passed / 1 warning / 0 failed
node_syntax_exit: 0
authority_hashes: 19/19 MATCH
artifact_contract: 6/6 PASS
protected_surface: 9/9 MATCH
prior_case_reprojections: 5/5 PASS
raw_files: 48
raw_bytes: 846797
raw_inventory_sha256: 82C100EA27151EA2B4EC79C8A9B4CD982D6B13484749C5B4527F934B2A6850F2
provider_attempts: 9
provider_requests: 39
provider_request_delta: 0
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
targeted_processes: 0
pester_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths: 355
provider_capability: false
provider_process_started: false
automatic_retry: false
strict_on_execution: false
joint_closure: false
```

The sole validator warning was the unchanged advisory token-budget warning for
`template/.omp/RULES.md` (`226 < 300`). Immediately before provider execution,
reporter SHA, structural-test SHA, changelog SHA
`2A0B71F43882E5665B7403128D293064A84E2CF5F5599FD1BAF8BA46A23E28EE`,
attempt-3 destination absence, strict-on/case-5/conclusion absence, process count zero,
branch, HEAD, and zero staged paths were reverified.

### 47.2 Exactly one provider process and capture-integrity PASS

Only after exact `MATCH`, Codex consumed the authorization with exactly:

```powershell
& scripts/run-phase00-e1.ps1 -CaseId ProviderStrictOffControl -Attempt 3 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

There was no `-AllowOverwrite`, model override, retry loop, strict-on call, parallel
provider call, or later-case execution. The runner started at
`2026-08-10T20:52:20.2384845+07:00`, completed in `20.75` seconds, and returned:

```yaml
case_id: ProviderStrictOffControl
attempt: 3
capture_integrity_status: PASS
capture_reason_codes: []
run_sha256: 13DA25DFB9F8030ACCA4D73353E9D1A8805FEF537E37B856CC6ED9B3B8023393
provider_process_attempts: 1
process_exit_code: 0
process_timed_out: false
remaining_child_pids: 0
cleanup_required: true
cleanup_attempted: true
cleanup_succeeded: true
capture_verification_status: PASS
capture_artifact_count: 5
capture_source_lines: 185
capture_sanitized_lines: 185
session_jsonl_sources: 2
session_unexpected_files: 0
protected_unchanged: true
live_home_unchanged: true
```

The remediated forwarder completed its lifecycle cleanly:

```yaml
forwarder_source_sha256: D9CDAEB5FF4235658D10AD8371410E7F480ADEBDCD85C0F0EA13BFFCD53FA483
forwarder_exit_code: 0
forwarder_timed_out: false
forwarder_remaining_child_pids: 0
forwarder_port_closed: true
forwarder_projection_count: 3
forwarder_record_count: 5
forwarder_record_types:
  - phase00_e1_forwarder_ready
  - phase00_e1_request_projection
  - phase00_e1_request_projection
  - phase00_e1_request_projection
  - phase00_e1_forwarder_closed
forwarder_lifecycle_valid: true
```

Capture-integrity PASS only made the immutable artifacts eligible for projection. It
did not pre-authorize a case PASS or a canonical case record.

### 47.3 Immutable attempt-3 raw evidence

Exactly six raw files were added:

| Artifact | Bytes | Lines | SHA-256 |
|---|---:|---:|---|
| `attempt-003.forwarder.ndjson` | 1518 | 5 | `2823DAF81CAE68A1A5DFCD9AF2E8650542AB702469A3963A2AED7537C9C1BCF4` |
| `attempt-003.run.json` | 17817 | 371 | `13DA25DFB9F8030ACCA4D73353E9D1A8805FEF537E37B856CC6ED9B3B8023393` |
| `attempt-003.sessions/session-001.jsonl` | 7895 | 10 | `04A73B9E42ACB38F78C519055A7C99D25299A3CFF07D5475AD746B25A6B46812` |
| `attempt-003.sessions/session-002.jsonl` | 3965 | 10 | `6F40A2DC3668D4272B11B25AB30CE50AEEB72B14269A0E3C1C78E7DEA6C0C6C5` |
| `attempt-003.stderr.jsonl` | 0 | 0 | `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` |
| `attempt-003.stdout.jsonl` | 54571 | 160 | `094D8F7ADB6A75F93949AE459622EC048DADAA65A021501772D5DA3C3EAF314A` |

The privacy-preserving source-capture identities were:

```yaml
forwarder_source_capture_sha256: A321AC01D6A86FC7AF761348EEF66F3DE84836164E34E9DBBBD25074A5F023D6
stdout_source_capture_sha256: 0E9DFB4CDDC31575E9B8A3AFE135CD1D83611DE8D7CDE12D23EC8440E1F0176A
stderr_source_capture_sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
session_001_source_capture_sha256: 617F2BE2D0055061A0DB74F967877BA8629C0D048BBDF224952E03A57E608635
session_002_source_capture_sha256: 33292F4EA1AA0EC6C8E4171A5F5247B8AE592B0463E76ABF190BB43A3D5AEC03
```

No transcript or provider body is reproduced here. The pre-existing 48-file tree was
recomputed after capture and remained byte-identical:

```yaml
prior_raw_files: 48
prior_raw_bytes: 846797
prior_raw_inventory_sha256: 82C100EA27151EA2B4EC79C8A9B4CD982D6B13484749C5B4527F934B2A6850F2
attempt_3_raw_files: 6
attempt_3_raw_bytes: 85766
total_raw_files: 54
total_raw_bytes: 932563
total_raw_inventory_sha256: 910D0AE12E4064F486FE1B80A40348F0F48D2965B76C7B2903A030381CDDEE2F
provider_attempts_before: 9
provider_attempts_after: 10
provider_attempt_delta: 1
provider_requests_before: 39
provider_requests_after: 42
provider_request_delta: 3
```

The established audit request counter is deliberately per sanitized session artifact
and is not deduplicated across carriers. The selected target ledger independently
contained one attributed provider request, one response end, and no provider retry.
This does not change the fact that exactly one runner/provider process was invoked.

### 47.4 Projection PASS, oracle INVALID_RUN

The current helper projected the immutable attempt without a capture or structural
projection error, but the strict-off oracle returned the fail-closed status:

```yaml
projection_status: PASS
projection_reason_codes: []
analysis_status: INVALID_RUN
analysis_reason_codes:
  - E1_STRICT_CONTROL_NOT_EXERCISED
attributable_results: 1
selected_forwarder_projections: 1
all_forwarder_projections: 3
identity_yield_parameters_sha256: DB58E598EDFCAAB815558716F24EED4D61FD2B9F5057608E8409C6369B234EEE
pi_no_strict_state: PRESENT_1
selected_request_index: 2
selected_gateway_http_status: 200
selected_yield_strict_field_present: false
selected_yield_strict: null
selected_pi_no_strict_effective: true
yield_attempt_count: 1
first_yield_provider_returned: true
first_yield_terminal: true
first_yield_data:
  allowed: E1_STRICT_ALLOWED
first_yield_local_validation_rejected: false
local_schema_rejection_count: 0
local_schema_retry_count: 0
schema_override_count: 0
selected_provider_request_count: 1
selected_provider_retry_start_count: 0
selected_provider_retry_end_count: 0
child_initialization_source: caller
schema_override_observable: true
schema_override_observed: true
```

The control requires the first strict-off provider result to exercise the forbidden
shape, be rejected locally for schema, and be followed by the expected second yield.
Instead, this run returned the allowed final shape on the first yield. Therefore the
control was not exercised and cannot support any conclusion about strict enforcement.
The status is `INVALID_RUN`, not PASS or FAIL. No canonical provider-strict case
record is written.

### 47.5 Independent post-error boundary audit

The read-only audit after oracle adjudication returned:

```yaml
artifact_contract: 6/6 PASS
artifact_codes:
  - P00-E1-FIXTURE
  - P00-E1-RUNTIME
  - P00-E1-PROTECTED-SURFACE
  - P00-E1-MANIFEST
  - P00-E1-CONCLUSION
  - P00-E1-READY
protected_surface: 9/9 MATCH
authoritative_case_records: 5/5 MATCH
manifest_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
manifest_e1_state: READY
manifest_t004_state: NOT_STARTED
strict_on_destination_present: false
case_5_present: false
conclusion_present: false
live_home_files: 14
live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
template_dot_omp_files: 18
template_dot_omp_bytes: 49970
template_dot_omp_inventory_sha256: 475B4BEE51995E9C34E0D5697A79754AFFFD5289FF23474C5CA94E0E095B2685
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
pinned_source_clean: true
pinned_runtime_version: omp/17.2.10
pinned_runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
historical_temp_roots: 1
historical_temp_file_bytes: 129
historical_temp_file_sha256: C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817
targeted_processes: 0
pester_processes: 0
git_branch: main
git_head: 62fecf277dc9d5e47d06319387eac747462214c1
git_index_staged_paths: 0
git_dirty_expanded_paths_before_this_append: 361
changelog_lines_before_append: 7363
changelog_bytes_before_append: 320106
changelog_sha256_before_append: 2A0B71F43882E5665B7403128D293064A84E2CF5F5599FD1BAF8BA46A23E28EE
```

The run changed only the six new attempt-3 raw artifacts. All earlier raw attempts,
five authoritative case records, protected repository files, live agent home, template
surface, manifest, source checkout, and historical temp residue remain unchanged.

### 47.6 Disposable cleanup and mandatory stop

After official consumption, reporter 021 and its structural test are deleted and
verified absent. Their last identities are the hashes in section 47.1. No generated
reprojection directory or targeted process remains; the one disclosed historical temp
residue remains intact.

Attempt 3 is immutable `INVALID_RUN` with
`E1_STRICT_CONTROL_NOT_EXERCISED`. Attempts 1, 2, and 3 are not overwritten,
reinterpreted, or selected. There is no automatic retry and `ProviderStrictOn` is
ineligible. No case-5 record, conclusion, manifest transition, E1 PASS, T-00.4 start,
or joint closure is claimed. Any future continuation requires a separately reviewed
decision for how to make the strict-off control deterministically exercise its
forbidden first result, followed by a new complete preflight, a new attempt number,
and separate explicit user authorization.

### 47.7 Final read-only recheck correction

After reporter disposal, one compact verification expression omitted whitespace around
PowerShell's `-eq` operator and therefore printed an invalid artifact count of `0/6`
while also emitting six `Where-Object` errors. That value was rejected immediately;
the command had no provider capability and changed no file. The corrected read-only
query returned exact `6/6 PASS`, protected surface `9/9 MATCH`, projection `PASS`,
analysis `INVALID_RUN / E1_STRICT_CONTROL_NOT_EXERCISED`, attempt-3 run SHA
`13DA25DFB9F8030ACCA4D73353E9D1A8805FEF537E37B856CC6ED9B3B8023393`, reporter and
test absent, and zero staged paths.
