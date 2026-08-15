# Phase 00 E3-A/E3-H Settings Evidence Design

**Status:** Implemented and closure-verified on 2026-08-09; H3 amendment incorporated into the normative spec
**Scope:** Focused Phase 00 runtime characterization for E3-A and E3-H only
**Normative authority:** `spec/phases/phase-00-foundation.md:226-253,333-367`
**Parent design:** `docs/superpowers/specs/2026-08-08-phase-00-execution-evidence-design.md`
**Repository HEAD:** `62fecf277dc9d5e47d06319387eac747462214c1`
**Pinned OMP:** `17.2.10` at `3a8591a8af5b6d200088d12ca75a5517cb064fa8`

## 1. Decision

Execute E3-A and E3-H as one focused, sequential evidence slice. They share a
disposable settings fixture and a fail-closed parser, but retain independent case
records and conclusions. Do not include E3-L, E3-I, E3-G, migration work, or product
workflow behavior in this slice.

This option was selected over two alternatives:

1. E3-A/E3-H/E3-L in one plan would reuse setup, but would couple the diagnostic
   configuration surface to the separate live-session authority experiment.
2. The entire remaining Wave B in one plan would reduce planning overhead, but would
   make provider, isolation, nested-repository, and settings failures harder to
   distinguish and review.

The focused slice is the smallest unit that unlocks the next manifest dependencies
without weakening the evidence boundary.

## 2. Source Facts and Epistemic Boundary

The design begins from source facts at the pinned OMP commit:

- `docs/settings.md:15-26,91-107` defines the precedence order as defaults, global,
  project, CLI overlays, then runtime overrides. Native project discovery is scoped
  to `<cwd>/.omp/` and does not walk ancestors.
- `packages/coding-agent/src/cli/config-cli.ts:338-360` emits the single-key JSON
  object and exits non-zero for an unknown key.
- `packages/coding-agent/src/config/settings-schema.ts:4463,4497-4506` sets the
  defaults to `task.isolation.mode=none` and `task.isolation.apply=true`.
- `packages/coding-agent/src/task/types.ts:114-175,195-256` excludes `apply` from
  every model-facing task item and uses ArkType `"+": "delete"`.
- `packages/coding-agent/src/task/index.ts:568-577,584-599` derives the active task
  schema and description from live session settings.
- `packages/coding-agent/src/task/structured-subagent.ts:315-317` makes the session
  setting authoritative when task dispatch does not carry a trusted isolation apply
  override.

Source facts define the expected result, not the experiment verdict. E3-A/E3-H PASS
requires observed OMP 17.2.10 behavior. Conversely, a correct `omp config get` result
is diagnostic evidence only: it cannot authorize parallel dispatch because it cannot
observe a different parent process's CLI overlay or in-memory runtime override.

## 3. Architecture

The slice has four isolated units:

1. **Fixture definitions** describe global, project, overlay, nested-cwd, and task-wire
   inputs without containing credentials or absolute live-home paths.
2. **Settings evidence helper** parses only the exact `omp config get --json` object,
   validates key/type/value, classifies process/read failures, and returns stable
   diagnostic reason codes.
3. **Disposable runner** materializes one case under the OS temp directory, relocates
   `PI_CODING_AGENT_DIR`, invokes the absolute installed OMP executable, captures and
   sanitizes stdout/stderr/exit/timestamps, verifies live-home metadata did not change,
   and deletes only the proven disposable roots.
4. **Case records and conclusions** separate raw observations from interpretations and
   drive legal manifest transitions.

The helper is evidence infrastructure, not the future `/orchestrated` implementation.
It may return `DIAGNOSTIC_OK_NOT_AUTHORIZATION` or `REFUSE`; it must never return an
`ALLOW_PARALLEL` decision.

## 4. Disposable Settings Matrix

Every direct configuration case uses a fresh fixture. The runner launches the
installed executable by absolute path so PATH manipulation in a child-workflow case
cannot prevent the outer harness from starting OMP.

| Layer | Safe fixture value |
| --- | --- |
| Disposable global | `task.isolation.mode: none`, `task.isolation.apply: true` |
| Project root | `task.isolation.mode: rcopy`, `task.isolation.apply: false` |
| CLI overlay | `task.isolation.mode: rcopy`, `task.isolation.apply: true` |
| Nested cwd | `<fixture>/packages/foo`, with no local `.omp/` |

No case reads or modifies `C:/Users/MrThien/.omp/agent`. Provider-dependent cases copy
the reviewed non-secret model catalog into the disposable agent directory and consume
the existing process-local gateway credential without printing or persisting it.

## 5. E3-A Case Contract

### A1 — Intended project-root read

Run from the disposable project root:

```text
omp config get task.isolation.mode --json
omp config get task.isolation.apply --json
```

PASS requires exit code zero for both commands and exact parsed objects with:

```yaml
mode: {key: task.isolation.mode, value: rcopy, type: enum}
apply: {key: task.isolation.apply, value: false, type: boolean}
```

The artifact retains sanitized raw JSON and the parsed values independently.

### A2 — Unknown-key refusal control

Run `omp config get task.isolation.__phase00_unknown --json`. PASS requires a non-zero
exit, no accepted value object, and classification `CONFIG_KEY_UNKNOWN`. A zero exit,
parseable value, or generic PASS is a failed experiment.

### A3 — Cwd sensitivity

Run the same mode/apply commands from `<fixture>/packages/foo`. The ancestor project
configuration must not be discovered. PASS requires observed global values `none` and
`true`, a different result from A1, and classification
`CWD_PROJECT_CONFIG_NOT_DISCOVERED`. The shared raw capture may also support H4, but
E3-A and E3-H retain separate interpretation records.

### A4 — Per-item apply is not a supported control

A4 has two complementary observations:

1. A normal OMP parent emits an attestation of the model-visible batch task item keys.
   PASS requires `isolated` to be present and `apply` to be absent.
2. A controlled eval bridge invokes `tool.task` with a raw batch item containing
   `apply:false` while the authoritative session setting is `apply:true`. An isolated
   blocking worker writes one sentinel inside the disposable repository. PASS requires
   the sentinel to be applied to the disposable parent and the result to report applied
   changes, proving the forced raw field did not become a per-item capture-only control.

The eval bridge calls `TaskTool.execute` directly and therefore does not itself prove
where model-call ArkType deletion occurs. The supported-wire attestation plus the pinned
source anchor proves exclusion from the model contract; the forced raw runtime control
proves non-authority. The conclusion must not overstate the eval bridge as a normal
model-validation path.

E3-A PASS requires A1 through A4 PASS. A provider/environment failure in A4 yields
`BLOCKED_ENVIRONMENT`, not a partial PASS.

## 6. E3-H Case Contract

### H1 — Project overrides global

With disposable global `apply:true` and project `apply:false`, direct reads from the
project root must report `false`. The diagnostic decision is
`DIAGNOSTIC_OK_NOT_AUTHORIZATION`; it is not permission to dispatch.

### H2 — Project absent/default refusal

With no project `.omp/config.yml`, direct reads must report global/default
`mode:none` and `apply:true`. The evidence helper must return `REFUSE` with both
`ISOLATION_MODE_NONE` and `ISOLATION_APPLY_TRUE`, and the fallback classification must
be `SEQUENTIAL_NON_ISOLATED_DISCLOSED`.

### H3 — CLI overlay observability boundary

Attempt the documented global `--config` overlay on the `config get` subcommand in
both supported-looking argument positions. The installed OMP 17.2.10 command surface
rejects `--config` for the `config` subcommand: the command class exposes only
`--json`. The durable disposable run reproduced exit 1 with `Unknown option
'--config'` in both positions before settings initialization and accepted no value
object.

PASS therefore means **characterization PASS**, not precedence-read PASS: the helper
returns `REFUSE` with `CONFIG_CLI_OVERLAY_UNSUPPORTED` and
`CLI_OVERLAY_UNOBSERVABLE`. It must explicitly state that `omp config get` cannot
attest a parent launch overlay. Runtime overlay precedence remains an E3-I concern.
The selected record is `docs/evidence/phase-00/E3-H/H3.yml`. Its raw stdout, stderr,
and run-record SHA-256 values are respectively
`73CDD144895AF8ABFB41EA42BEFA5A4744B9E786F0C8EB98335A5AC108C9E55D`,
`6BDAC0AC268EB0F152267385F49878F40FFC228F7FB89EC86150DD26A10147EA`, and
`8641A2A59CE6764200D20EBD393273C92AD7B6881DF46AA9CCCDADC7CF8A7A1B`.

### H4 — Nested cwd refusal

Reuse the A3 raw observation. The helper must return `REFUSE`, name cwd scoping as the
likely cause, and classify the fallback as `SEQUENTIAL_NON_ISOLATED_DISCLOSED`. A
generic wrong-value message without cwd diagnosis fails H4.

### H5 — Workflow bash cannot execute the diagnostic

Launch an OMP print-mode parent by absolute executable path with a process-local PATH
that does not contain `omp`. The parent must attempt the exact config command through
its `bash` tool. PASS requires a structured bash failure before any task dispatch and
classification `CONFIG_COMMAND_UNAVAILABLE`; no model prose can substitute for the
tool event.

### H6 — Non-zero and unparseable fail-closed controls

Synthetic analyzer controls supply a non-zero generic process result and a zero-exit
non-JSON stdout result. Both must return `REFUSE` with distinct reasons
`CONFIG_READ_NONZERO` and `CONFIG_JSON_INVALID`. Neither control performs a provider
call or writes a durable raw runtime artifact.

E3-H PASS requires H1 through H6 PASS. H5 environment failure is
`BLOCKED_ENVIRONMENT`; analyzer incompleteness is `INVALID_RUN`; an observed precedence
or refusal contradiction is `FAIL`.

## 7. Data Flow and Artifact Layout

```text
reviewed fixture definition
  -> unique disposable global/project/overlay roots
  -> absolute OMP 17.2.10 invocation
  -> stdout/stderr/exit/timestamps + live-home metadata pair
  -> sanitizer and strict JSON parser
  -> case-specific analyzer
  -> case YAML + conclusion YAML
  -> manifest transition
  -> repository validator
  -> English Opus changelog with hashes
```

Durable paths:

```text
docs/evidence/phase-00/E3-A/
  fixture/
  raw/
  A1.yml
  A2.yml
  A3.yml
  A4.yml
  conclusion.yml
docs/evidence/phase-00/E3-H/
  fixture/
  raw/
  H1.yml
  H2.yml
  H3.yml
  H4.yml
  H5.yml
  H6.yml
  conclusion.yml
scripts/lib/phase00-config-evidence.ps1
scripts/run-phase00-e3a-e3h.ps1
scripts/tests/phase00-e3a-e3h.Tests.ps1
```

Raw names include the case ID and attempt number. Reruns never overwrite a prior
attempt. Case YAML identifies the selected attempt and explains why every unselected
attempt has no gate power.

## 8. Error Handling and Status Rules

- Missing stdout, malformed JSON, a mismatched key/type, incomplete provenance, or an
  unpaired tool event produces `INVALID_RUN`.
- Provider authentication, quota, overload, or unavailable model produces
  `BLOCKED_ENVIRONMENT` and preserves the exact sanitized terminal classification.
- An analyzable precedence, cwd, wire, or refusal contradiction produces `FAIL`.
- H3 is a characterization control: exact CLI rejection plus fail-closed refusal is
  PASS because it proves the concrete read mechanism cannot observe the overlay. It
  does not prove launch-session overlay precedence.
- Only complete observations satisfying every case predicate produce `PASS`.
- A child process may exit zero while containing a terminal model error; terminal
  event classification runs before case analysis.
- A correct config read returns `DIAGNOSTIC_OK_NOT_AUTHORIZATION`, never a parallel
  authorization result.
- Cleanup failure or any detected live-home metadata change invalidates the run.

## 9. Manifest Transitions

Execution is sequential even though E3-A and E3-H are independent:

```text
E3-A READY -> RUNNING -> PASS | FAIL | BLOCKED_ENVIRONMENT
E3-H READY -> RUNNING -> PASS | FAIL | BLOCKED_ENVIRONMENT
```

Only after both are durable PASS may these rows transition from `NOT_STARTED` to
`READY`:

```text
E3-B
E3-C
E3-I
E3-L
```

E3-M remains `DEFERRED_PARALLEL_DISABLED`, the manifest root remains
`parallel_mode: DISABLED`, and Phase 00 remains in progress. This slice cannot enable
parallel execution or authorize Phase 01/02 implementation.

## 10. Validation Strategy

Tests precede helper/runner implementation and cover:

- strict accepted JSON shape for enum and boolean values;
- key/type/value mismatches;
- unknown-key, non-zero, missing executable, and invalid-JSON refusal codes;
- correct precedence/refusal classifications for H1-H4, including H3's unsupported
  config-subcommand overlay surface;
- the invariant that no helper result contains `ALLOW_PARALLEL`;
- task-item schema attestation and forced-raw non-authority analysis;
- provider terminal-error classification;
- literal, slash-normalized, and JSON-escaped path sanitization;
- credential-shaped output rejection;
- exact disposable-root verification and bounded cleanup;
- live-home metadata equality;
- final E3-A/E3-H artifact requirements and legal manifest readiness transitions.

Fresh closure verification runs Wave A, E3-J/E3-K, and E3-A/E3-H Pester suites plus
the repository validator in PowerShell 7 and Windows PowerShell 5.1. It also parses
every new YAML/JSON/JSONL artifact, runs AST checks, scans for secret-shaped values and
incomplete markers, checks trailing whitespace and `git diff --check`, confirms zero
staged files, verifies the pinned upstream clone, and confirms no disposable roots
remain.

## 11. Non-Goals

- No E3-L live-session custom-tool experiment.
- No E3-I behavioral canary or E3-G nested-repository experiment.
- No `/orchestrated` product command implementation.
- No policy/schema migration or template installation.
- No writes to the live OMP home or global settings.
- No parallel-mode enablement or E3-M execution.
- No Git stage, commit, branch, push, or pull request.
- No normative spec patch unless direct evidence contradicts a load-bearing statement.

## 12. Acceptance Criteria

The slice design is satisfied when:

1. A1-A4 and H1-H6 each have complete, sanitized, reproducible evidence.
2. The installed OMP runtime's global/project precedence, cwd scoping, JSON shapes,
   and config-subcommand overlay limitation are recorded from direct commands rather
   than inferred from files.
3. The task wire excludes per-item `apply`, and a forced raw field cannot replace the
   authoritative session setting.
4. Every unsafe or unreadable configuration state returns a distinct fail-closed
   refusal classification with sequential fallback disclosure.
5. No diagnostic result is represented as parallel authorization.
6. E3-A/E3-H PASS unlocks only E3-B/E3-C/E3-I/E3-L readiness while parallel mode
   remains disabled.
7. Opus can reconstruct every design and execution mutation from the English changelog
   without relying on chat history.
