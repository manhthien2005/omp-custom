# Phase 00 E3-A/E3-H Settings Evidence Implementation Plan

**Execution status:** Implemented and Codex-adjudicated PASS on 2026-08-09; Opus
peer review remains pending quota and joint closure is not claimed.

> **Required sub-skill:** Execute this plan with `superpowers:executing-plans`; use
> `superpowers:test-driven-development` for every helper or runner behavior and
> `superpowers:verification-before-completion` before any closure claim.

**Goal:** Produce durable, fail-closed OMP 17.2.10 evidence for E3-A settings control
surface and E3-H configuration/refusal behavior, then make only the dependency-safe
manifest transitions supported by that evidence.

**Architecture:** A focused PowerShell evidence helper parses and adjudicates sanitized
process observations. A separate disposable runner owns filesystem/process boundaries.
Reviewed fixtures are copied into OS-temporary roots. Durable JSON/JSONL/TXT captures feed
case YAML, conclusions, the Phase 00 manifest, and the English Opus review changelog.

**Tech Stack:** PowerShell 5.1-compatible scripts, Pester 4 assertions, OMP 17.2.10,
YAML/JSON/JSONL evidence, Git read-only status/diff checks, pinned OMP TypeScript source.

**Global Constraints:** Work inline in the current user-authorized `main` workspace. Do
not create a branch, worktree, stage, commit, push, or pull request. Preserve all
pre-existing user changes. Never write to the live OMP home. Never print or persist a
credential value. Never claim that a subprocess `config get` authorizes parallel work.
Keep `parallel_mode: DISABLED`, keep E3-M deferred, and do not implement E3-I/E3-L or any
product workflow in this slice. Replace normal plan commit checkpoints with file hashes,
fresh test output, and an English Opus changelog entry.

**Approved design:**
`docs/superpowers/specs/2026-08-09-phase-00-e3a-e3h-design.md`

## Task 1: Lock the empirical H3 correction before implementation

**Files:**

- Modify: `spec/phases/phase-00-foundation.md:333-367`
- Modify: `docs/superpowers/specs/2026-08-09-phase-00-e3a-e3h-design.md`
- Create: `scripts/tests/phase00-e3a-e3h.Tests.ps1`
- Create: `scripts/lib/phase00-config-evidence.ps1`

### Step 1: Add a RED test for the config-subcommand flag surface

The test imports the new helper conditionally and asserts the source-backed classifier
contract. Start the file with:

```powershell
#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$configHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-config-evidence.ps1'
$runtimeHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-runtime-evidence.ps1'
$runnerPath = Join-Path $repositoryRoot 'scripts\run-phase00-e3a-e3h.ps1'
$script:configHelperLoaded = $false
$script:runnerLoaded = $false

if (Test-Path -LiteralPath $runtimeHelperPath -PathType Leaf) { . $runtimeHelperPath }
if (Test-Path -LiteralPath $configHelperPath -PathType Leaf) {
    . $configHelperPath
    $script:configHelperLoaded = $true
}
if (Test-Path -LiteralPath $runnerPath -PathType Leaf) {
    . $runnerPath
    $script:runnerLoaded = $true
}

function Assert-ConfigHelperLoaded { $script:configHelperLoaded | Should Be $true }

Describe 'E3-H H3 CLI overlay control surface' {
    It 'classifies an unsupported config-subcommand overlay as refusal, never authorization' {
        Assert-ConfigHelperLoaded
        $result = Get-Phase00ConfigCommandClassification `
            -ExpectedKey 'task.isolation.apply' `
            -ExitCode 1 `
            -Stdout '' `
            -Stderr "error: Unknown option '--config'." `
            -Context CliOverlay

        $result.Status | Should Be 'REFUSE'
        @($result.Reasons) -contains 'CONFIG_CLI_OVERLAY_UNSUPPORTED' | Should Be $true
        @($result.Reasons) -contains 'CLI_OVERLAY_UNOBSERVABLE' | Should Be $true
        (($result | ConvertTo-Json -Depth 8) -match 'ALLOW_PARALLEL') | Should Be $false
    }
}
```

### Step 2: Run the focused test and confirm RED

Run in PowerShell 7:

```powershell
Invoke-Pester -Path scripts/tests/phase00-e3a-e3h.Tests.ps1 -PassThru
```

Expected: failure because `scripts/lib/phase00-config-evidence.ps1` or
`Get-Phase00ConfigCommandClassification` does not yet exist.

### Step 3: Implement the minimum classifier needed for GREEN

Create `scripts/lib/phase00-config-evidence.ps1` with strict mode, a stable result
constructor, and the exact H3 branch:

```powershell
#Requires -Version 5.1
Set-StrictMode -Version 2.0

function New-Phase00ConfigDecision {
    param(
        [Parameter(Mandatory)][ValidateSet('OBSERVED','REFUSE','INVALID_RUN')][string]$Status,
        [Parameter(Mandatory)][string[]]$Reasons,
        $Observation = $null,
        [string]$Fallback = 'SEQUENTIAL_NON_ISOLATED_DISCLOSED',
        [string]$Context = 'DirectRead'
    )
    [pscustomobject][ordered]@{
        Status = $Status
        Reasons = @($Reasons)
        Observation = $Observation
        Fallback = $Fallback
        Context = $Context
    }
}

function Get-Phase00ConfigCommandClassification {
    param(
        [Parameter(Mandatory)][string]$ExpectedKey,
        [Parameter(Mandatory)][int]$ExitCode,
        [AllowEmptyString()][Parameter(Mandatory)][string]$Stdout,
        [AllowEmptyString()][Parameter(Mandatory)][string]$Stderr,
        [Parameter(Mandatory)][ValidateSet('DirectRead','ProjectRoot','NoProject','CliOverlay','NestedCwd','ToolUnavailable','Synthetic')][string]$Context
    )
    if ($Context -eq 'CliOverlay' -and $ExitCode -ne 0 -and
        $Stderr -match "(?i)Unknown option ['`\"]--config['`\"]") {
        return New-Phase00ConfigDecision -Status REFUSE `
            -Reasons @('CONFIG_CLI_OVERLAY_UNSUPPORTED','CLI_OVERLAY_UNOBSERVABLE') `
            -Context $Context
    }
    return New-Phase00ConfigDecision -Status INVALID_RUN `
        -Reasons @('CONFIG_CLASSIFIER_INCOMPLETE') -Context $Context
}
```

### Step 4: Run the focused test and confirm GREEN

Expected: the H3 unit test passes and the serialized result contains neither
`ALLOW_PARALLEL` nor an equivalent authorization field.

### Step 5: Correct the normative H3 expectation with explicit evidence boundaries

Patch `spec/phases/phase-00-foundation.md` only in E3-H. Preserve the original
precedence claim as a launch-session fact, but replace the impossible instruction that
`omp config get` itself consume `--config` with these load-bearing points:

- OMP 17.2.10's `config` subcommand accepts `--json` but rejects global `--config`.
- H3 must durably reproduce the rejection and fail closed with distinct user-facing
  reasons.
- The subprocess read cannot attest a parent's launch overlay.
- Actual launch-overlay precedence remains assigned to E3-I.
- This is characterization PASS only when the unsupported surface and refusal are both
  observed; it is not precedence-read PASS.

Add exact source anchors:

```text
packages/coding-agent/src/commands/config.ts:24-26
packages/coding-agent/src/cli/config-cli.ts:243-244
packages/coding-agent/src/main.ts:1283
```

The approved design already carries the preliminary amendment. After the durable H3
run, replace preliminary wording with the selected artifact paths and hashes.

### Step 6: Verify the task checkpoint

Run the focused test in both shells and compute SHA-256 for the spec, design, test, and
helper. Do not update the manifest yet.

## Task 2: Implement strict config parsing and fail-closed decisions with TDD

**Files:**

- Modify: `scripts/tests/phase00-e3a-e3h.Tests.ps1`
- Modify: `scripts/lib/phase00-config-evidence.ps1`
- Read/reuse: `scripts/lib/phase00-runtime-evidence.ps1`

### Step 1: Add RED parser tests

Add tests for all accepted and rejected shapes:

```powershell
Describe 'Strict omp config get parsing' {
    It 'accepts the exact enum object' {
        $json = '{"key":"task.isolation.mode","value":"rcopy","type":"enum","description":"Isolation backend"}'
        $result = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.mode' `
            -ExitCode 0 -Stdout $json -Stderr '' -Context ProjectRoot
        $result.Status | Should Be 'OBSERVED'
        $result.Observation.Value | Should Be 'rcopy'
        $result.Observation.Type | Should Be 'enum'
    }

    It 'accepts the exact boolean object' {
        $json = '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"Apply changes"}'
        $result = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout $json -Stderr '' -Context ProjectRoot
        $result.Status | Should Be 'OBSERVED'
        $result.Observation.Value | Should Be $false
        $result.Observation.Type | Should Be 'boolean'
    }

    It 'distinguishes unknown key, generic nonzero, invalid JSON, key mismatch, and type mismatch' {
        $unknown = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.__phase00_unknown' `
            -ExitCode 1 -Stdout '' -Stderr 'Unknown setting: task.isolation.__phase00_unknown' -Context DirectRead
        @($unknown.Reasons) -contains 'CONFIG_KEY_UNKNOWN' | Should Be $true

        $nonzero = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 9 -Stdout '' -Stderr 'generic failure' -Context Synthetic
        @($nonzero.Reasons) -contains 'CONFIG_READ_NONZERO' | Should Be $true

        $invalid = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout 'not-json' -Stderr '' -Context Synthetic
        @($invalid.Reasons) -contains 'CONFIG_JSON_INVALID' | Should Be $true

        $wrongKey = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.mode","value":"none","type":"enum","description":"x"}' -Stderr '' -Context Synthetic
        $wrongKey.Status | Should Be 'INVALID_RUN'
        @($wrongKey.Reasons) -contains 'CONFIG_KEY_MISMATCH' | Should Be $true

        $wrongType = Get-Phase00ConfigCommandClassification -ExpectedKey 'task.isolation.apply' `
            -ExitCode 0 -Stdout '{"key":"task.isolation.apply","value":"false","type":"boolean","description":"x"}' -Stderr '' -Context Synthetic
        $wrongType.Status | Should Be 'INVALID_RUN'
        @($wrongType.Reasons) -contains 'CONFIG_VALUE_TYPE_MISMATCH' | Should Be $true
    }
}
```

### Step 2: Confirm RED, then implement the parser

Add `ConvertFrom-Phase00ConfigJson` with these invariants:

- exactly one JSON object after trimming;
- `key`, `value`, `type`, and `description` present;
- returned key exactly equals `-ExpectedKey`;
- `task.isolation.mode` is type `enum` and a string value;
- `task.isolation.apply` is type `boolean` and a Boolean value;
- any mismatch returns `INVALID_RUN`, never a permissive observation.

Complete `Get-Phase00ConfigCommandClassification` in this order:

1. H3 unsupported-overlay signature;
2. unknown setting signature;
3. any remaining non-zero exit;
4. empty stdout;
5. strict JSON parse;
6. accepted observation.

Stable codes are:

```text
CONFIG_CLI_OVERLAY_UNSUPPORTED
CLI_OVERLAY_UNOBSERVABLE
CONFIG_KEY_UNKNOWN
CONFIG_READ_NONZERO
CONFIG_STDOUT_EMPTY
CONFIG_JSON_INVALID
CONFIG_KEY_MISMATCH
CONFIG_TYPE_MISMATCH
CONFIG_VALUE_TYPE_MISMATCH
```

### Step 3: Add RED isolation-decision tests

Add `Test-Phase00IsolationDiagnostic -ModeResult -ApplyResult -Context` tests for:

- `rcopy/false` -> `DIAGNOSTIC_OK_NOT_AUTHORIZATION`;
- `none/true` -> `REFUSE` with both unsafe-setting reasons;
- `rcopy/true` -> `REFUSE` with apply reason;
- nested cwd -> `REFUSE` plus `CWD_PROJECT_CONFIG_NOT_DISCOVERED`;
- any unreadable input -> `REFUSE` preserving the read-failure reason;
- no output field or serialized string may contain `ALLOW_PARALLEL`.

The exact safe result is:

```powershell
[pscustomobject][ordered]@{
    Decision = 'DIAGNOSTIC_OK_NOT_AUTHORIZATION'
    Reasons = @('CONFIG_VALUES_MATCH_CAPTURE_ONLY_EXPECTATION')
    Fallback = $null
    Context = 'ProjectRoot'
    Mode = 'rcopy'
    Apply = $false
}
```

Unsafe/default output uses `Decision = 'REFUSE'` and
`Fallback = 'SEQUENTIAL_NON_ISOLATED_DISCLOSED'`.

### Step 4: Implement, run focused tests, and refactor

Keep property access PowerShell 5.1-compatible. Reuse
`Protect-Phase00EvidenceText`, `Read-Phase00JsonLines`,
`Get-Phase00TaskEventPairs`, and `Get-Phase00TerminalModelFailure` from the existing
runtime helper rather than duplicating their behavior.

## Task 3: Lock fixture and disposable-runner boundaries with TDD

**Files:**

- Create: `docs/evidence/phase-00/E3-A/fixture/global-config.yml`
- Create: `docs/evidence/phase-00/E3-A/fixture/project-config.yml`
- Create: `docs/evidence/phase-00/E3-A/fixture/overlay-config.yml`
- Create: `docs/evidence/phase-00/E3-A/fixture/prompts/A4-apply-non-authority.md`
- Create: `docs/evidence/phase-00/E3-A/fixture/.omp/agents/phase00-apply-probe.md`
- Create: `docs/evidence/phase-00/E3-H/fixture/prompts/H5-config-command-unavailable.md`
- Create: `scripts/run-phase00-e3a-e3h.ps1`
- Modify: `scripts/tests/phase00-e3a-e3h.Tests.ps1`

### Step 1: Add RED fixture-contract tests

Require exact fixture values and safety:

```yaml
# global-config.yml
task:
  isolation:
    mode: none
    apply: true
```

```yaml
# project-config.yml
task:
  batch: true
  isolation:
    mode: rcopy
    apply: false
```

```yaml
# overlay-config.yml
task:
  batch: true
  isolation:
    mode: rcopy
    apply: true
```

Tests must reject a live-home path, credential variable name, credential-shaped value,
missing `blocking: true`, or a prompt that permits prose to substitute for tool output.

### Step 2: Add RED runner-surface tests

The runner must export these functions when dot-sourced:

```text
Get-Phase00ConfigCaseDefinition
Get-Phase00InstalledOmpPath
Get-Phase00ConfigProcessEnvironment
Get-Phase00ConfigCommandArguments
Get-Phase00ParentArguments
Get-Phase00PathWithoutOmp
Initialize-Phase00ConfigFixture
Invoke-Phase00CapturedProcess
Invoke-Phase00ConfigEvidenceCase
```

Assert:

- case set is `A1,A2,A3,A4,H2,H3,H5`;
- all OMP starts use the absolute pinned executable;
- direct reads set the child process working directory instead of relying on live cwd;
- `PI_CODING_AGENT_DIR` points to a unique disposable agent root;
- H3 generates both
  `omp --config <overlay> config get task.isolation.apply --json` and
  `omp config get task.isolation.apply --json --config <overlay>` rejection probes;
- H5 PATH retains required system/shell directories but excludes the installed OMP
  directory by normalized, case-insensitive comparison;
- no command record stores the real temporary or live-home path;
- existing raw attempts cannot be overwritten by default;
- cleanup accepts only a verified non-root descendant of the OS temp directory.

### Step 3: Implement the fixture materializer and process runner

`Initialize-Phase00ConfigFixture` creates, under one verified temporary root:

```text
agent/config.yml                 <- global-config.yml
project/.omp/config.yml          <- project-config.yml
project/packages/foo/            <- no local .omp
project/overlay.yml              <- overlay-config.yml
sessions/
```

For provider cases it additionally copies the reviewed
`docs/evidence/phase-00/environment/runtime-models.yml` to `agent/models.yml`, copies
the agent definition to `project/.omp/agents/`, and initializes a disposable Git
repository with a baseline commit.

`Invoke-Phase00CapturedProcess` must accept explicit executable, argument array,
working directory, environment map, stdout path, stderr path, and timeout. It captures
exit code and UTC timestamps without shell interpolation. It restores every process
environment variable in `finally`.

### Step 4: Add the exact A4 agent and prompt

The blocking agent executes one assignment: create `phase00-a4-sentinel.txt` with the
exact content `PHASE00_A4_APPLY_TRUE_SENTINEL`, verify the file, then yield a structured
success. The prompt orders the parent to:

1. inspect the visible batch `task` item schema;
2. emit through `bash` a compact `phase00-task-item-wire-v1` object containing sorted
   item keys, `has_isolated`, and `has_apply`;
3. only if `has_isolated=true` and `has_apply=false`, call JavaScript eval exactly once
   with:

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

The prompt must not claim that the eval bridge exercises model ArkType validation.

### Step 5: Add the exact H5 prompt

The parent receives only `bash`. It must call exactly:

```text
omp config get task.isolation.mode --json
```

It must stop after the structured non-zero tool result, must not call `task`, and must
end with `H5_PARENT_DONE`. The analyzer, not model prose, classifies
`CONFIG_COMMAND_UNAVAILABLE`.

### Step 6: Run runner/fixture tests in both shells

No provider process is launched in unit tests. Confirm all temporary test roots are
deleted and live-home metadata is unchanged.

## Task 4: Implement case analyzers with synthetic RED/GREEN evidence

**Files:**

- Modify: `scripts/lib/phase00-config-evidence.ps1`
- Modify: `scripts/tests/phase00-e3a-e3h.Tests.ps1`

### Step 1: Add analyzers and RED tests for direct cases

Implement and test:

```text
Test-Phase00A1Evidence
Test-Phase00A2Evidence
Test-Phase00A3Evidence
Test-Phase00H1Evidence
Test-Phase00H2Evidence
Test-Phase00H3Evidence
Test-Phase00H4Evidence
Test-Phase00H6Evidence
```

Each returns `New-Phase00RuntimeAnalysis` with `PASS`, `FAIL`, `INVALID_RUN`, or
`BLOCKED_ENVIRONMENT`. Required case predicates match the approved design as amended:

- A1: exact `rcopy/false` parsed observations;
- A2: unknown key non-zero and no accepted observation;
- A3: nested cwd exact `none/true` and cwd-difference classification;
- H1: global true + project false resolves false and remains diagnostic-only;
- H2: `none/true` refuses with both reason codes and disclosed sequential fallback;
- H3: both overlay placements reject the flag, no accepted value, and classifier refuses
  with both amended codes;
- H4: nested cwd refusal explicitly names cwd scoping;
- H6: generic non-zero and zero-exit non-JSON controls produce distinct refusal codes.

### Step 2: Add RED tests for A4 and H5 structured-event analyzers

Implement:

```text
Test-Phase00A4Evidence -Events <events> -SentinelObserved <bool>
Test-Phase00H5Evidence -Events <events>
```

A4 PASS requires all of:

- wire attestation before eval dispatch;
- `has_isolated=true`, `has_apply=false`;
- one eval call containing the forced raw object;
- eval result contains a successful task result;
- sentinel exists in the disposable parent after the call;
- result text/details report applied changes;
- no claim that eval proved ArkType deletion.

H5 PASS requires a paired bash start/end, exact command, non-zero structured result,
command-not-found shape, no task event, and the stable reason
`CONFIG_COMMAND_UNAVAILABLE`.

### Step 3: Add provider terminal-error tests

Feed an exit-zero JSONL stream with a terminal provider/auth/quota/overload/model error.
Require `BLOCKED_ENVIRONMENT`. A malformed or unpaired tool stream must be
`INVALID_RUN`. An analyzable semantic contradiction must be `FAIL`.

### Step 4: Run the complete new suite and refactor only while GREEN

Check both PowerShell editions. Do not proceed to provider execution until the entire
new suite is GREEN.

## Task 5: Execute A1-A3 and H1-H4/H6 without provider dependency

**Files:**

- Create: `docs/evidence/phase-00/E3-A/raw/A1.stdout.json`
- Create: `docs/evidence/phase-00/E3-A/raw/A1.stderr.txt`
- Create: `docs/evidence/phase-00/E3-A/raw/A1.run.json`
- Create: `docs/evidence/phase-00/E3-A/raw/A2.stdout.txt`
- Create: `docs/evidence/phase-00/E3-A/raw/A2.stderr.txt`
- Create: `docs/evidence/phase-00/E3-A/raw/A2.run.json`
- Create: `docs/evidence/phase-00/E3-A/raw/A3.stdout.json`
- Create: `docs/evidence/phase-00/E3-A/raw/A3.stderr.txt`
- Create: `docs/evidence/phase-00/E3-A/raw/A3.run.json`
- Create: `docs/evidence/phase-00/E3-H/raw/H2.stdout.json`
- Create: `docs/evidence/phase-00/E3-H/raw/H2.stderr.txt`
- Create: `docs/evidence/phase-00/E3-H/raw/H2.run.json`
- Create: `docs/evidence/phase-00/E3-H/raw/H3.stdout.txt`
- Create: `docs/evidence/phase-00/E3-H/raw/H3.stderr.txt`
- Create: `docs/evidence/phase-00/E3-H/raw/H3.run.json`
- Create: `docs/evidence/phase-00/E3-A/A1.yml`
- Create: `docs/evidence/phase-00/E3-A/A2.yml`
- Create: `docs/evidence/phase-00/E3-A/A3.yml`
- Create: `docs/evidence/phase-00/E3-H/H1.yml`
- Create: `docs/evidence/phase-00/E3-H/H2.yml`
- Create: `docs/evidence/phase-00/E3-H/H3.yml`
- Create: `docs/evidence/phase-00/E3-H/H4.yml`
- Create: `docs/evidence/phase-00/E3-H/H6.yml`
- Modify: `docs/evidence/phase-00/manifest.yml`

### Step 1: Record legal RUNNING transitions before execution

Set E3-A and E3-H from `READY` to `RUNNING`, preserving all other rows. Run the Wave A
manifest tests immediately. If the validator does not admit `RUNNING`, add only the
minimum canonical-state validator support with RED/GREEN tests before changing the
manifest.

### Step 2: Execute direct cases in dependency order

Run:

```powershell
& scripts/run-phase00-e3a-e3h.ps1 -CaseId A1 -Attempt 1
& scripts/run-phase00-e3a-e3h.ps1 -CaseId A2 -Attempt 1
& scripts/run-phase00-e3a-e3h.ps1 -CaseId A3 -Attempt 1
& scripts/run-phase00-e3a-e3h.ps1 -CaseId H2 -Attempt 1
& scripts/run-phase00-e3a-e3h.ps1 -CaseId H3 -Attempt 1
```

H1 references A1's selected raw observations. H4 references A3. H6 is created from
the unit-tested synthetic controls and explicitly records `runtime_call: false`.

### Step 3: Adjudicate immediately and preserve every attempt

If a case is invalid, fix only the harness cause, increment `-Attempt`, and retain the
prior raw capture. Case YAML names the selected attempt and states why every older
attempt has no gate power. Never use `-AllowOverwrite` for official execution.

### Step 4: Verify direct-case artifacts

Parse every JSON/YAML file, compare live-home before/after hashes, confirm cleanup,
scan for paths and credential shapes, and run both old and new tests before provider
work.

## Task 6: Execute provider-dependent A4 and H5 sequentially

**Files:**

- Create: `docs/evidence/phase-00/E3-A/raw/A4.stdout.jsonl`
- Create: `docs/evidence/phase-00/E3-A/raw/A4.stderr.txt`
- Create: `docs/evidence/phase-00/E3-A/raw/A4.run.json`
- Create: `docs/evidence/phase-00/E3-H/raw/H5.stdout.jsonl`
- Create: `docs/evidence/phase-00/E3-H/raw/H5.stderr.txt`
- Create: `docs/evidence/phase-00/E3-H/raw/H5.run.json`
- Create: `docs/evidence/phase-00/E3-A/A4.yml`
- Create: `docs/evidence/phase-00/E3-H/H5.yml`

### Step 1: Run A4 only after direct evidence is valid

```powershell
& scripts/run-phase00-e3a-e3h.ps1 -CaseId A4 -Attempt 1 `
  -Model omniroute/codex/gpt-5.6-sol-high
```

Before persisting output, the runner sanitizes repository/disposable path variants and
rejects credential-shaped text. Classify terminal provider failures before semantic
analysis. Verify the sentinel only inside the disposable parent, record the Boolean,
then clean the root.

### Step 2: Run H5 with the filtered PATH

```powershell
& scripts/run-phase00-e3a-e3h.ps1 -CaseId H5 -Attempt 1 `
  -Model omniroute/codex/gpt-5.6-sol-high
```

The outer harness launches the absolute OMP executable. The child parent process sees a
PATH without the OMP installation directory. The run fails if PATH filtering prevents
the parent or bash tool itself from operating, if any task dispatch occurs, or if prose
is used instead of the structured bash failure.

### Step 3: Handle environment blocks without weakening the verdict

Authentication, quota, overload, or unavailable model -> preserve sanitized evidence
and use `BLOCKED_ENVIRONMENT`. Do not convert it to PASS. A rerun after a genuine
environment fix uses the next attempt number.

## Task 7: Create conclusions and perform only evidence-supported manifest transitions

**Files:**

- Create: `docs/evidence/phase-00/E3-A/conclusion.yml`
- Create: `docs/evidence/phase-00/E3-H/conclusion.yml`
- Modify: `docs/evidence/phase-00/manifest.yml`
- Modify only if a RED integration test requires it:
  `scripts/lib/phase00-evidence.ps1`, `scripts/validate-template.ps1`
- Modify: `scripts/tests/phase00-e3a-e3h.Tests.ps1`

### Step 1: Add RED conclusion/manifest tests

Require A1-A4 PASS for E3-A PASS and H1-H6 PASS for E3-H PASS. Require every manifest
artifact path to exist. Require all case-selected hashes to match. Require
`parallel_mode: DISABLED` and E3-M `DEFERRED_PARALLEL_DISABLED`.

### Step 2: Write conclusions from selected attempts

Each conclusion records:

The E3-A conclusion sets `experiment: E3-A`, selects A1-A4, and uses the aggregate
status required by their selected attempts. The E3-H conclusion sets `experiment: E3-H`,
selects H1-H6, and does the same. Both use schema version 1 and contain explicit
`gate_power`, `non_claims`, `source_anchors`, and `artifact_hashes` fields.

E3-A non-claim: eval raw bridge does not locate the ArkType deletion boundary.
E3-H non-claim: `config get` does not attest a parent CLI/runtime override.

### Step 3: Apply the legal manifest result

If and only if both conclusions are durable PASS:

```text
E3-A -> PASS
E3-H -> PASS
E3-B -> READY
E3-C -> READY
E3-I -> READY
E3-L -> READY
```

Otherwise keep dependent rows `NOT_STARTED` and set only the completed experiment row
to its evidence-supported terminal state. Never enable E3-M or parallel mode.

### Step 4: Run the repository validator in both shells

Any validator edit must be preceded by a failing integration test and limited to the
new evidence contract. Do not relax existing Wave A or E3-J/E3-K checks.

## Task 8: Complete cross-shell verification and the Opus audit trail

**Files:**

- Modify: `codex-phase00-execution-changelog-for-opus5.md`
- Modify: `docs/superpowers/specs/2026-08-09-phase-00-e3a-e3h-design.md`
- Verify all files above

### Step 1: Invoke verification-before-completion

Run fresh in PowerShell 7 and Windows PowerShell 5.1:

```powershell
Invoke-Pester -Path scripts/tests/phase00-wave-a.Tests.ps1 -PassThru
Invoke-Pester -Path scripts/tests/phase00-e3j-e3k.Tests.ps1 -PassThru
Invoke-Pester -Path scripts/tests/phase00-e3a-e3h.Tests.ps1 -PassThru
& scripts/validate-template.ps1
```

Capture exact totals and exit codes; do not reuse earlier output.

### Step 2: Run structural and safety verification

Perform all of:

- YAML parse for manifest, A1-A4, H1-H6, and both conclusions;
- JSON/JSONL parse for every selected raw artifact;
- PowerShell AST parse for new/modified scripts and tests;
- repository-scoped credential-shape scan for the new slice;
- incomplete-work marker and unfinished-placeholder scan;
- trailing-whitespace scan and `git diff --check`;
- staged-file count equals zero;
- HEAD remains `62fecf277dc9d5e47d06319387eac747462214c1` unless the user changed it;
- pinned upstream remains `3a8591a8af5b6d200088d12ca75a5517cb064fa8`;
- no `omp-phase00-*` disposable roots from this slice remain;
- live OMP home metadata boundary remains unchanged.

### Step 3: Append one complete English Opus entry

The entry must include:

- exact files created and modified;
- exact line anchors for every normative/design change;
- the preliminary and durable H3 evidence and why the contract changed;
- every case verdict and selected/unselected attempt;
- every command, exit code, Pester total, validator total, and structural scan result;
- before/after manifest state table;
- source anchors and epistemic non-claims;
- SHA-256 for every durable artifact plus final design/spec/manifest/changelog hashes;
- disclosure that no Git integration or live-home mutation occurred;
- reminder that the local gateway credential should be rotated because it appeared in
  earlier assistant-only diagnostic output, while confirming it was not persisted.

### Step 4: Self-review the changelog as if Opus had no chat history

Check that Opus can reconstruct every mutation, rationale, evidence selection, and
remaining blocker using only the changelog and repository paths. Remove redundant prose
but not context, locations, proof, hashes, or non-claims.

### Step 5: Report the exact next gate

If both experiments PASS, Phase 00 remains in progress and the next dependency-safe
work is a newly designed slice chosen among E3-B/E3-C/E3-I/E3-L; parallel work remains
disabled. If either is blocked or failed, report that state and the exact evidence-backed
condition required to resume. Do not claim Phase 00 complete.

## Execution Closure Record

```yaml
cases: {A1: PASS, A2: PASS, A3: PASS, A4: PASS, H1: PASS, H2: PASS, H3: PASS_CHARACTERIZATION, H4: PASS, H5: PASS, H6: PASS}
manifest: {E3-A: PASS, E3-H: PASS, E3-B: READY, E3-C: READY, E3-I: READY, E3-L: READY, E3-M: DEFERRED_PARALLEL_DISABLED}
parallel_mode: DISABLED
full_pester_pwsh_7_6_4: {total: 105, passed: 105, failed: 0}
full_pester_windows_powershell_5_1: {total: 105, passed: 105, failed: 0}
repository_validator: {passed: 89, warnings: 0, failed: 0}
selected_raw_hash_references: {checked: 21, mismatches: 0}
pre_checkpoint_changelog_sha256: 18F436740B812C55B934865424A1AC62D3BDBE0C4CF8366770F9A8F1EC915014
phase_00_status: IN_PROGRESS
peer_review: PENDING_OPUS_QUOTA
```

The final fresh post-plan verification and final hashes are recorded in P00-CX-018 of
`codex-phase00-execution-changelog-for-opus5.md`. No plan item authorized E3-M,
parallel mode, product implementation, or Git integration.

## Plan Self-Review Checklist

- [x] Every approved A1-A4 and H1-H6 case has a test, execution path, artifact, and
  adjudication rule.
- [x] H3 records the actual OMP 17.2.10 CLI surface and does not falsely claim overlay
  precedence was read by `config get`.
- [x] No helper can return `ALLOW_PARALLEL`.
- [x] A4 separates model-wire attestation, raw eval non-authority, and source proof.
- [x] H5 requires structured tool evidence before refusal.
- [x] Direct and provider cases have distinct environment/error rules.
- [x] Reruns preserve earlier attempts.
- [x] Live-home and secret boundaries are mechanically checked.
- [x] Manifest transitions unlock only E3-B/E3-C/E3-I/E3-L after dual PASS.
- [x] Parallel mode remains disabled and E3-M remains deferred.
- [x] No placeholder implementation or Git integration step remains.
- [x] The final English changelog is sufficient for an independent Opus review.
