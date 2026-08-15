# Phase 00 E1 Schema Precedence and Provider Enforcement Design

Date: 2026-08-09<br>
Status: **APPROVED by the user in conversation on 2026-08-09**<br>
Implementation authority: design approved; execution remains gated by the implementation plan<br>
Future peer review: Opus 5, equal authority with Codex

## 1. Objective

Produce reproducible, provider-backed evidence for Phase 00 experiment E1 without
modifying the distributable template. E1 must determine:

1. which schema wins at runtime when caller, agent, and parent session may each
   provide a schema;
2. which `output:` frontmatter dialects work on the pinned OMP runtime;
3. whether the configured OmniRoute/OpenAI-Responses path receives and honors a
   strict closed `yield` contract; and
4. what exact, bounded conclusion may unlock T-00.4.

E1 is characterization, not product implementation. It creates a disposable
fixture, runner, tests, sanitized raw evidence, a conclusion, a manifest update,
and an English Opus handoff. It does not move or rewrite the four current template
schema files and does not add `output:` to production agents.

## 2. Why E1 is the next task

`docs/evidence/phase-00/manifest.yml` records:

- E1 as `READY` with no dependencies;
- T-00.4 as `NOT_STARTED`, depending on E1;
- T-00.5 as depending on T-00.3 and T-00.4; and
- T-00.6 as depending on T-00.4.

The normative Phase 00 spec forbids starting a dependent task against an unresolved
experiment. E1 is therefore the dependency-safe next task and the shortest route
to the schema re-homing work. T-00.4 must remain unimplemented during E1.

## 3. Governing authority

The experiment uses this authority order:

1. `spec/phases/phase-00-foundation.md`, T-00.E1 and T-00.4;
2. `docs/superpowers/specs/2026-08-08-phase-00-execution-evidence-design.md`;
3. pinned OMP source at
   `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (`v17.2.10`);
4. observed behavior of the hash-verified OMP 17.2.10 executable;
5. existing Phase 00 runner/evidence conventions; and
6. the four current `.omp/schemas/` files as historical input only.

Source establishes the expected control flow but cannot replace the provider
experiment:

- `task/structured-subagent.ts`, `resolveSchema` (lines 176-188): caller presence,
  then agent `output`, then session `outputSchema`, then none;
- `discovery/helpers.ts`, `parseAgentFields` (lines 253-323): `output` frontmatter
  is retained without imposing a dialect at discovery time;
- `tools/output-schema-validator.ts`, `buildOutputValidator`: JTD and JSON Schema
  normalization share the final validator path;
- `tools/jtd-to-json-schema.ts`, `jtdToJsonSchema`: JTD converts to JSON Schema;
- `tools/yield.ts`, `YieldTool` (lines 241-307 and 360-420): schema construction,
  strict compatibility, validation retries, and eventual override metadata;
- `task/executor.ts`, `finalizeSubprocessOutput` and `finalizeRunResult`: the chosen
  source, mode, status, data, and validation error are retained in
  `SingleResult.structuredOutput`;
- `providers/openai-responses.ts`, tool serialization (lines 1351-1389): provider
  `strict: true` is emitted only when strict mode is available, the tool remains
  strict-compatible, and `PI_NO_STRICT` is not active.

Symbols and the pinned commit are authoritative if later line numbers drift.

## 4. Locked pre-state and non-mutation boundary

Repository HEAD at design time is
`62fecf277dc9d5e47d06319387eac747462214c1`. The Git index has zero staged paths.
The worktree is intentionally dirty and unrelated changes are user-owned.

The current schema directory contains 218 physical lines:

| Path | Lines | SHA-256 |
|---|---:|---|
| `template/.omp/schemas/agent-result.schema.yml` | 52 | `A55B8E64DA16BB8205A6F815E9A8CD8DDE96BB8E085139435C71B785DCAE57D8` |
| `template/.omp/schemas/review-result.schema.yml` | 52 | `439D5B321739FE22792847C8D091668C58DEFC0244E8AD14A6328FE464A8182B` |
| `template/.omp/schemas/task-packet.schema.yml` | 63 | `78459082CC66C1F9320D3734B1BBA9C10F7DAA4E68EB4828B3D3879357DF2ABB` |
| `template/.omp/schemas/verification-result.schema.yml` | 51 | `2D6F05567482CAADB39E487BA7838DF24904ADFE12C66DEE180AA4B8D4DB627C` |

These files are documentation-shaped contracts, not valid JTD or JSON Schema
objects ready to paste into `output:`. E1 must not silently reinterpret them.
Their conversion and placement belong to T-00.4 after E1 closes OQ-A.

During E1, the following paths are immutable product surfaces:

- `template/.omp/schemas/**`;
- `template/.omp/agents/**`;
- template commands, skills, rules, config, installer, and registry component lists;
- all normative specs unless a later separately reviewed correction is authorized;
- prior raw evidence and historical Opus/Codex review packets; and
- the live OMP agent home and global settings.

No branch, worktree, stage, commit, push, reset, or checkout operation is authorized.

## 5. Alternatives considered

### 5.1 Source-only proof — rejected

This is cheap and sufficient to predict precedence, but it cannot establish the
configured gateway/model behavior required by CR-03A and T-00.E1 case 5. It would
launder a source fact into a provider claim.

### 5.2 One monolithic live transcript — rejected

A single parent session could dispatch every probe. It would reduce process setup,
but a parent error, context contamination, or malformed later call would weaken all
cases. Raw attribution and rerun boundaries would also be unnecessarily broad.

### 5.3 Independent capture-first cases — selected

Each case receives its own disposable root, OMP process, session directory, raw
capture, run record, adjudication, and provider-attempt count. Shared pure parsing
and sanitization code avoids duplication. A failed or invalid case never forces a
rerun of an already valid case.

The first authorized execution wave is one attempt per ordinary case plus one
strict-on arm and one strict-off control arm for case 5: seven provider-backed OMP
process attempts in total. No automatic experiment-level rerun is allowed.
OMP/provider-internal requests, overload retries, and schema retries are all counted
from raw events rather than described as one generic “provider call.”

## 6. Experiment architecture

### 6.1 Planned repository layout

```text
scripts/
├── run-phase00-e1.ps1
├── lib/phase00-e1-evidence.ps1
└── tests/phase00-e1.Tests.ps1

docs/evidence/phase-00/E1/
├── fixture/
│   ├── agents/
│   └── prompts/
├── raw/
│   └── <case-id>/attempt-001.*
├── case-1-agent-jtd.yml
├── case-1-agent-json-schema.yml
├── case-2-caller-only.yml
├── case-3-caller-over-agent.yml
├── case-4-session-only.yml
├── case-5-provider-strict.yml
└── conclusion.yml

codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md
```

The implementation plan may adjust helper boundaries, but it must retain one
case-specific artifact per row and one conclusion. Raw evidence must not be embedded
into the changelog.

### 6.2 Runner interface

The runner exposes an explicit case selector and attempt number, conceptually:

```powershell
./scripts/run-phase00-e1.ps1 `
  -CaseId <AgentJtd|AgentJsonSchema|CallerOnly|CallerOverAgent|SessionOnly|ProviderStrictOn|ProviderStrictOffControl> `
  -Attempt 1 `
  -OmpExecutable <absolute pinned executable> `
  -Model omniroute/codex/gpt-5.6-sol-high
```

Properties:

- PowerShell 5.1 compatible;
- `-OmpExecutable` is mandatory for provider-backed execution;
- refuses any executable whose SHA-256 is not
  `1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`;
- also requires exact version output `omp/17.2.10`;
- refuses overwrite unless a deliberate future `-AllowOverwrite` contract is
  separately tested;
- validates the resolved disposable root is a non-root descendant of the OS temp
  directory before creating or deleting anything;
- imposes a bounded wall-clock timeout;
- captures stdout and stderr concurrently to avoid pipe deadlock;
- records process exit code and every observable model request/retry event;
- sanitizes into new files and never rewrites captured raw bytes in place; and
- verifies cleanup without recursively deleting an unresolved path.

### 6.3 Disposable environment

Every case receives a newly generated root with:

- a disposable `PI_CODING_AGENT_DIR`;
- a copied sanitized `models.yml` using the runtime model catalog;
- project-local fixture agents and prompts;
- a case-specific session directory;
- a process-local PATH whose first OMP candidate is a verified copy of 17.2.10;
- no inherited project `.omp` content other than the fixture; and
- no write route to `template/.omp`.

The live installed OMP may remain 17.2.12. It is recorded as a non-authoritative
environment delta and must never be selected for E1.

The runner snapshots the protected live agent-home paths before and after each case.
Any detected write makes the run `INVALID_RUN`, even if schema behavior looked correct.

### 6.4 Capture layers

Each attempt records:

1. a line-preserving sanitized projection of process stdout JSONL and stderr;
2. parent, child, and nested session JSONL required to establish provenance;
3. a sanitized run envelope containing command, timestamps, exit code, runtime
   identity, fixture hashes, raw hashes, cleanup result, and request counts;
4. a derived case record containing only direct facts and interpretation; and
5. for case 5 only, a sanitized last-hop request projection from the local forwarder.

The original byte capture exists only inside the verified disposable root. The
sanitizer emits new repository artifacts, preserves one output JSON object per input
line, replaces secret/private fields with typed redaction markers, and records the
source-capture and sanitized-output hashes. It removes authorization material,
encrypted reasoning/signatures, and unrelated private prompts while retaining the
experiment fixture hashes, tool arguments/results, provider/model identifiers,
retry events, and terminal metadata required by the oracle. The original capture is
deleted with the disposable root after sanitization and verification.

In this design, “raw artifact” means this immutable, line-preserving sanitized event
stream—not an unsanitized provider call log. Derived records may quote its exact
event line numbers and hashes, but cannot replace it.

## 7. Case matrix and binary oracles

| Artifact | Effective inputs | Required source | Required data fact |
|---|---|---|---|
| case 1 JTD | agent JTD `output:` only | `agent` | JTD sentinel validates |
| case 1 JSON Schema | agent JSON Schema `output:` only | `agent` | JSON Schema sentinel validates |
| case 2 | caller JSON Schema only | `caller` | caller sentinel validates |
| case 3 | conflicting caller and agent schemas | `caller` | caller sentinel present; agent sentinel absent |
| case 4 | nested leaf with parent-session schema only | `session` | nested session sentinel validates |
| case 5 | closed caller schema plus `schemaMode: strict` | `caller` | provider boundary is strict and forbidden extra is absent |

Every case additionally requires:

- selected runtime and source identities match the pins;
- one attributable task result exists;
- `structuredOutput.status` is `valid`;
- exit code is zero unless the case contract explicitly characterizes a rejection;
- no retry-exhausted override is accepted as a pass;
- no terminal error is superseded by a later successful retry, and no recovered
  error is misclassified as terminal;
- raw artifact hashes and event anchors are present; and
- protected paths remain byte-identical.

### 7.1 Case 1A — agent `output:` with JTD

The fixture agent owns a closed JTD schema with a required constant-like sentinel
field and no caller `outputSchema`. The caller must omit the property entirely;
passing `null`, `{}`, or `true` still counts as caller presence and invalidates the
case design.

PASS requires `source: agent`, `status: valid`, the expected sentinel, and no
schema override. This is the runtime proof for the dialect already used by pinned
OMP bundled agents.

### 7.2 Case 1B — agent `output:` with JSON Schema

The fixture agent owns an equivalent closed JSON Schema and the caller again omits
`outputSchema` entirely. PASS has the same metadata requirements as case 1A.

If both agent-dialect cases pass, OQ-A records `BOTH_ACCEPTED`. The canonical
T-00.4 authoring form becomes JTD because pinned first-party agent definitions use
that form and OMP already owns the JTD-to-JSON-Schema conversion path. JSON Schema
remains a supported form, not the selected template convention.

### 7.3 Case 2 — caller only

The selected agent has no `output:` field. The task invocation carries one closed
JSON Schema with a unique caller-only sentinel. PASS requires `source: caller`,
`outputSchemaOverridesAgent: true` in the attributable setup/result path where
observable, and a valid caller sentinel.

### 7.4 Case 3 — caller overrides agent

The agent schema and caller schema require mutually exclusive property names and
sentinel values. The caller schema must win by presence, not by schema similarity.

PASS requires:

- `source: caller`;
- `mode` equals the requested mode;
- only the caller property/sentinel exists in final data;
- the agent-only property/sentinel is absent; and
- the child system/session initialization identifies the selected caller schema.

A generic object containing both sentinels is a failure, even if the task exits zero.

### 7.5 Case 4 — session only

The main controller spawns a carrier agent with a caller schema. This establishes
the carrier session's `outputSchema`. The carrier then invokes a leaf agent that:

- has no `output:` frontmatter;
- receives no caller `outputSchema` property at all; and
- is allowed by the carrier's explicit `spawns` contract.

The relevant result is the nested leaf result, not the carrier's outer result.
PASS requires the nested `SingleResult.structuredOutput` to report `source: session`
and valid session-sentinel data. The carrier's expected outer `source: caller` is a
setup fact only and cannot substitute for the nested observation.

### 7.6 Case 5 — strict provider boundary

The caller supplies a strict-compatible, closed JSON Schema with exactly one
allowed sentinel field, a required constant value `E1_STRICT_ALLOWED`, and
`additionalProperties: false`. The assignment explicitly asks the child to submit
the prohibited value `E1_STRICT_FORBIDDEN` and add `forbidden_extra`, creating two
independent discriminators required by CR-03A.

The case distinguishes three layers:

1. `resolveSchema` selects the caller schema;
2. `schemaMode: strict` makes retry-exhausted invalid completion fail closed; and
3. the OpenAI-Responses provider adapter emits strict tool metadata only when the
   generated `yield` schema remains strict-compatible and strict mode is not disabled.

`schemaMode: strict` alone must never be cited as proof of provider strictness.

## 8. Sanitized loopback forwarder for case 5

Both case 5 arms temporarily point their disposable model catalog at an ephemeral
loopback forwarder. The forwarder relays the request byte stream to the unchanged
OmniRoute gateway at `127.0.0.1:20128` and relays the response unchanged. It never
stores:

- authorization values;
- API keys or cookies;
- system, user, or assistant prompt content;
- complete request or response bodies;
- OmniRoute database content; or
- private model reasoning.

It persists only a projection of the request immediately before forwarding:

```yaml
gateway: omniroute
api: openai-responses
request_path: /v1/responses
yield_tool_present: true
yield_strict_field_present: true | false
yield_strict: true | false | null
yield_parameters_sha256: <hash of sanitized yield parameters only>
allowed_data_properties: [allowed]
required_data_properties: [allowed]
data_additional_properties: false
pi_no_strict_effective: true | false
forwarded: true
gateway_http_status: <integer>
```

The raw request body is handled in memory and discarded. The projection and the
exact sanitized `yield` parameter object are hashed. The forwarder is terminated
and its bound port is verified closed before cleanup.

The two arms use byte-identical assignment and output-schema fixtures. Both keep
`schemaMode: strict`, so the only intended provider-wire variable is process-local
`PI_NO_STRICT`:

- **strict-on arm:** `PI_NO_STRICT` is absent, the projection must show an explicit
  `yield.strict: true`, and provider-returned arguments must conform immediately;
- **strict-off control:** `PI_NO_STRICT=1`, the projection must show the strict field
  omitted, and the first provider-returned terminal `yield` attempt must contain the
  prohibited constant value or `forbidden_extra` before OMP's local validator rejects
  it. The byte-identical assignment tells the child to correct the result after a
  tool error, bounding the expected control to one invalid attempt followed by one
  valid attempt. The correction does not replace the first-attempt discriminator.

Case 5 PASS requires all of the following:

1. the projection proves `yield_strict: true` at the configured OmniRoute gateway
   boundary;
2. the transmitted data schema is closed and does not permit `forbidden_extra`;
3. the strict-off projection proves the strict field was omitted with
   `PI_NO_STRICT=1`;
4. both arms use the same contradictory assignment and schema hashes;
5. the strict-off first terminal-yield attempt contains the prohibited constant or
   `forbidden_extra`, proving that the prompt/model discriminator actually fired;
6. the strict-off first attempt produces exactly one attributable local schema
   rejection, the next terminal-yield attempt is valid, no schema override occurs,
   and the arm completes with valid structured output;
7. the strict-on first provider-returned terminal `yield` arguments that reach tool
   execution conform to the allowed schema;
8. `forbidden_extra` and the prohibited constant are absent from strict-on
   provider-returned arguments and final data;
9. the strict-on arm has no local yield schema-validation error, schema retry, or
   override before successful completion;
10. strict-on `structuredOutput` is
   `{source: caller, mode: strict, status: valid, ...}`; and
11. both arms receive attributable gateway responses rather than local mocks.

If the strict-off control also conforms on its first attempt, the run is
`INVALID_RUN`: it did not exercise the promised invalid-output discriminator, so the
strict-on arm has no causal comparison and no PASS power. There is no automatic
prompt tweak or rerun.

If the gateway rejects the request, the model emits an invalid call that OMP retries,
OMP strips or overrides fields, the provider falls back to text, or preflight stops
before a model call, the artifact records that exact behavior. None is silently
normalized into PASS.

The conclusion is bounded to the configured OMP 17.2.10 + OmniRoute +
`codex/gpt-5.6-sol-high` path. It does not claim anything about OmniRoute's internal
upstream routing or every provider supported by OMP.

## 9. Status and adjudication rules

Case status uses the common Phase 00 vocabulary:

- `PASS`: every case-specific and common oracle is satisfied;
- `FAIL`: a complete, attributable pinned-runtime observation contradicts an oracle;
- `BLOCKED_ENVIRONMENT`: a fully evidenced external capability prevents the case;
- `INVALID_RUN`: capture, provenance, isolation, sanitization, or attribution is
  incomplete.

`INVALID_RUN` is attempt history and has no manifest state or contract power.
E1 remains `READY` until a complete terminal evidence set exists; the runner does
not temporarily mutate the manifest to `RUNNING`.

Experiment adjudication:

| Condition | E1 manifest state | T-00.4 state |
|---|---|---|
| all six case records PASS, including both case 5 arms | `PASS` | `READY` |
| any complete case FAIL | `FAIL` | `NOT_STARTED` |
| required provider/environment capability is conclusively unavailable | `BLOCKED_ENVIRONMENT` | `NOT_STARTED` |
| any case only has INVALID_RUN evidence | retain `READY` | `NOT_STARTED` |

The conclusion must enumerate every case, raw hash, selected dialect result, provider
boundary, model, request/retry count, and limitation. A partial matrix cannot PASS.

## 10. T-00.4 and documentation effects

When E1 passes:

- OQ-A becomes `BOTH_ACCEPTED` if both dialect probes pass;
- JTD becomes the selected canonical template authoring form;
- caller `outputSchema` remains an explicit per-call override;
- agent `output:` remains the canonical worker-result schema location;
- session schema remains a fallback only when caller and agent are absent;
- strict-required calls must use both a strict-compatible schema and
  `schemaMode: strict`; and
- T-00.4 becomes `READY`, not automatically implemented.

E1 records any needed normative correction as `spec_effect: CHANGE`, with exact
downstream files. Actual schema migration and broad documentation cleanup remain
T-00.4/T-00.5 work so that experiment evidence and product mutations stay separable.

## 11. Test-first validation design

Implementation follows RED-to-GREEN development. Before the runner can call a
provider, focused Pester tests must fail for the missing behavior and then pass for:

- pinned executable hash/version rejection;
- fixture generation and absence-versus-null distinction for `outputSchema`;
- structured-result extraction for caller, agent, and session sources;
- nested leaf attribution rather than carrier-result substitution;
- terminal-event supersession and recovered-retry classification;
- strict request projection sanitization;
- forbidden-extra detection;
- raw/derived hash linkage;
- protected-home before/after comparison;
- exact per-case and experiment state derivation; and
- cleanup path containment.

Required mutation controls deliberately alter fixtures or derived inputs to prove
the oracle fails when:

- caller/agent/session source labels are swapped;
- case 3 contains both sentinels;
- the nested leaf accidentally receives caller `outputSchema`;
- case 5 has `strict: false` or an omitted strict field;
- `forbidden_extra` reaches tool execution or final data;
- a schema retry/override is hidden;
- a recovered provider error is treated as terminal or vice versa;
- a raw artifact/hash/required event is missing;
- OMP 17.2.12 is selected; or
- the protected live home changes.

Pure tests and mutation controls make no provider calls. Provider execution is
forbidden until those gates are green.

After evidence generation, verification includes:

1. the E1 focused suite in PowerShell 7;
2. the E1 focused suite in Windows PowerShell 5.1;
3. all Phase 00 Pester suites in both shells;
4. the full template validator in both shells;
5. manifest validation and destination/raw hash checks;
6. a targeted assertion that all four current template schema files and five
   production agent files remain byte-identical; and
7. `git diff --cached --name-only` remains empty.

## 12. Safety and failure containment

- Provider execution is sequential; E3-M and parallel mode remain disabled.
- No case runs against the repository root as its project fixture.
- No fixture may create a Git branch or worktree.
- The runner never records secrets or complete provider request bodies.
- Environment blocks are reported, not bypassed.
- A provider overload retry is preserved as an event chain and cannot be hidden by
  only recording the final response.
- A process timeout records remaining child processes and verifies termination.
- Cleanup operates only on an exact verified temp descendant and records whether
  deletion completed.
- Existing evidence, user edits, and historical review files remain untouched.

## 13. Changelog contract for Opus

The dedicated English handoff is the compact peer-review entry point. For every
checkpoint it records:

- objective and authority;
- exact files created or changed;
- before/after SHA-256 and relevant anchors;
- tests and commands with exit codes and compact decisive output;
- provider process/attempt/request/retry ledger;
- raw artifact paths and hashes;
- manifest and downstream state transitions;
- rejected alternatives and known limitations;
- protected/unrelated paths confirmed unchanged; and
- explicit Codex-only versus jointly accepted status.

It links raw evidence instead of copying transcripts. No claim is jointly closed
until Opus can review it later.

## 14. Acceptance criteria for the written design

This design is ready for implementation planning only when the user confirms that:

- E1, not T-00.4, is the current task;
- six independent case records backed by seven runtime process attempts are
  acceptable;
- case 4 uses the nested leaf as the session-precedence observation;
- case 5 uses a sanitized last-hop forwarder and makes no upstream-provider claim;
- the first execution wave permits one attempt per ordinary case, two fixed arms
  for case 5, and no automatic reruns;
- product schema/agent files remain immutable during E1;
- E1 PASS alone moves T-00.4 only to `READY`; and
- all mutations and evidence will be captured in the dedicated English Opus handoff.

After written-spec approval, Codex must invoke the writing-plans workflow and create
a file-by-file implementation plan before touching runner, test, fixture, evidence,
manifest, or product code.
