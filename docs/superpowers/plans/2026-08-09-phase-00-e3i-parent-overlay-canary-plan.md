# Phase 00 E3-I Parent-Overlay Canary Evidence Implementation Plan

> **Historical-plan correction:** P00-CX-028 supersedes this plan's terminal adjudication
> assumptions. Attempts 4 and 5 are `INVALID_RUN`, current E3-I authority is `READY`, and the
> authoritative correction plan is
> `2026-08-09-phase-00-e3il-terminal-precedence-correction-plan.md`. Historical execution
> steps below are preserved for auditability.

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task and
> `superpowers:test-driven-development` for every helper or runner behavior. Steps use
> checkbox (`- [ ]`) syntax for tracking. This engagement is inline/solo; do not dispatch
> subagents.

**Goal:** Produce durable, fail-closed OMP 17.2.10 evidence that child configuration
reads miss both a live parent runtime override and a parent CLI overlay, while preserving
the canary's exact `[read, yield, hub]` controlled effective surface and keeping E3-I
diagnostic-only.

**Architecture:** A parent-scoped project custom-tool factory performs the one approved,
default-main-CLI-host `pi.pi.settings.override` mutation but returns no tool for isolated
child cwd values. Two
provider-backed parent sessions execute nine sequential read-only canaries across project,
runtime-override, and CLI-overlay states. A strict PowerShell analyzer combines parent
JSONL, nested canary JSONL, child diagnostics, snapshots, and run metadata into I1-I4
evidence without granting parallel authority.

**Tech Stack:** PowerShell 5.1-compatible scripts, Pester 4 assertions, TypeScript custom
tool fixture loaded by OMP, OMP 17.2.10, JSON/JSONL/YAML evidence, Git read-only
inspection, and pinned OMP TypeScript source.

## Global Constraints

- Work inline in the current user-authorized dirty `main` workspace at repository HEAD
  `62fecf277dc9d5e47d06319387eac747462214c1`.
- Do not create a branch or worktree for the official workspace; do not stage, commit,
  push, pull, reset, checkout, or create a pull request there. A local baseline commit is
  allowed only inside the verified OS-temporary fixture because OMP isolation requires a
  Git parent. Replace official-repository commit checkpoints with fresh tests, SHA-256
  ledgers, and English changelog checkpoints.
- Do not dispatch subagents. The only subagents in scope are the nine OMP canaries created
  by the experiment itself.
- Preserve every pre-existing user/Codex worktree change. Touch only the files listed by
  this plan unless a failing test proves an additional E3-I-owned edit is necessary.
- Pin runtime claims to an explicitly selected, copy-hashed OMP `17.2.10` executable and upstream source commit
  `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.
- Never print, serialize, or copy a credential value. Provider credentials may only be
  consumed from the already configured process environment.
- Never write to the live OMP home. Relocate `PI_CODING_AGENT_DIR`; compare live-home
  metadata before and after every selected provider attempt.
- Keep all project/session/agent roots under a verified OS-temporary directory. Resolve
  and validate a deletion target before cleanup; never delete a repository root, home,
  unresolved variable, or glob target.
- Keep `parallel_mode: DISABLED`, E3-M deferred, and Phase 00 `IN_PROGRESS` for every E3-I
  result. E3-I is characterization only and never returns an allow-parallel decision.
- Do not implement E3-L, E3-M, product preflight, workflow dispatch, or installation.
- Execute provider sessions sequentially. No retry is automatic. Preserve and classify an
  attempt before an explicitly numbered retry; never overwrite raw history.
- Use `apply_patch` for every authored source, spec, fixture, interpreted-evidence, design,
  manifest, and changelog edit. The reviewed runner alone may mechanically generate raw
  runtime captures and run metadata. Do not use ad-hoc shell redirection for repository
  mutations.
- Run every focused and full Pester suite under both PowerShell 7 and Windows PowerShell
  5.1. A shell-specific evidence meaning is a defect, not a waiver.
- Opus peer review remains pending quota. Codex PASS is provisional and cannot jointly
  close E3-I.

**Approved and amended design:**
`docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md`

**Amendment discovered during planning:** Pinned source forwards project custom-tool paths
to subagents and force-includes registered tools. The plan therefore uses a cwd-gated
factory: parent cwd returns the essential override tool, isolated child cwd returns `[]`.
Every child `session_init.tools` must equal `[read, yield, hub]` after process-local
user-profile discovery isolation.

**Attempt 1 correction amendment:** The first provider attempt is preserved and classified
`INVALID_RUN`. It proved that the advertised `CustomToolContext.settings` is omitted by the
actual project-tool SDK bridge and that the nested PowerShell diagnostic is corrupted by
outer-shell variable expansion. The corrected harness uses the exported settings proxy only
for the exact default main-CLI host, runs the direct `omp config get ... --json` command,
copies one explicitly selected 17.2.10 executable into the disposable root, prepends that
copy for nested resolution, and treats unattributed live-home concurrency as
`INVALID_RUN`, never semantic `FAIL`. This amendment supersedes any older snippet below
that conflicts with those rules.

**Attempt 2 correction amendment:** The second provider attempt is also preserved and
classified `INVALID_RUN`. It exposed three independent methodology facts: an empty JSON
object from the real override call broke a StrictMode property enumerator; the runner then
misclassified that parser exception by matching historical overload text anywhere in the
transcript; and the canary contract contradicted TaskTool's mandatory `yield` protocol while
ambient user-profile MCP discovery widened the child surface. The corrected harness handles
empty `PSCustomObject` values, never promotes parser/provenance exceptions by transcript
regex, invalidates recovered nested provider errors, relocates process-local `USERPROFILE`,
requires controlled `[read, yield, hub]`, and requires exactly one terminal `yield` with the
fixed acknowledgement and zero other child calls. The executable steps below have been
reconciled to this correction; older reviewed copies with `[read, hub]`, zero-tool-call, or
"do not call tools" language are obsolete.

**Attempt 3 runtime adjudication amendment:** The third Session A launch used the fully
corrected harness and produced the exact parent sequence, both boolean-false direct
diagnostics, the parent-only `false -> true` runtime override, three
`APPLY_FALSE_CAPTURE_ONLY` samples, three `APPLY_TRUE_NO_DIFF` samples, six exact
`[read, yield, hub]` surfaces, one conforming terminal `yield` and zero forbidden calls per
canary, positive costs, and six clean boundary predicates. Nevertheless,
`e3i-project-2` recovered from `server_is_overloaded` via an internal auto-retry. The existing
regression correctly classifies the entire attempt `INVALID_RUN /
E3I_NESTED_PROVIDER_RECOVERY`. Attempt 3 is preserved and non-selected; no Session B or
Attempt 4 was launched. The execution batch is stopped pending a fresh external-state check,
fresh gate, and renewed user authorization.

**Attempt 4 terminal amendment:** Renewed authorization was followed by a fresh successful
gateway/model check and complete PowerShell 7/Windows PowerShell 5.1 gate. Attempt 4 again
produced all nine parent tool calls, exact diagnostics and override attestation, three
`APPLY_FALSE_CAPTURE_ONLY` rows, three `APPLY_TRUE_NO_DIFF` rows, six exact canary surfaces
and yields, positive cost rows, and six clean mutation predicates. The parent then ended on
an unrecovered `server_is_overloaded` terminal message. Per the unchanged decision table,
the experiment terminates `BLOCKED_ENVIRONMENT / P00-RUNTIME-PROVIDER-OVERLOAD`; Attempt 4
is non-selected, Session B and Attempt 5 were not launched, I1-I4 PASS files are absent, and
the manifest lists only the complete terminal adjudication and conclusion artifacts.

---

## File Responsibility Map

| Path | Action | Single responsibility |
| --- | --- | --- |
| `spec/phases/phase-00-foundation.md` | Modify | Correct only E3-I's false `/settings`/`Settings.set` runtime-override procedure |
| `docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md` | Modify at final adjudication | Record planning amendment and terminal implementation status/evidence |
| `scripts/lib/phase00-e3i-evidence.ps1` | Create | Strict transcript, child diagnostic, canary, summary, and I1-I4 decisions |
| `scripts/run-phase00-e3i.ps1` | Create | Disposable setup, process execution, snapshotting, raw capture, sanitization, and cleanup |
| `scripts/tests/phase00-e3i.Tests.ps1` | Create | All E3-I unit, negative, fixture, runner, and durable-evidence tests |
| `docs/evidence/phase-00/E3-I/fixture/.omp/config.yml` | Create | Project `rcopy/apply:false` baseline |
| `docs/evidence/phase-00/E3-I/fixture/overlay.yml` | Create | Parent CLI `apply:true` overlay |
| `docs/evidence/phase-00/E3-I/fixture/.omp/agents/phase00-e3i-canary.md` | Create | Blocking `[read]` canary with one mandatory terminal `yield` and no forbidden call |
| `docs/evidence/phase-00/E3-I/fixture/.omp/tools/phase00-e3i-runtime-override.ts` | Create | Parent-cwd-only, default-main-CLI `pi.pi.settings.override(..., true)` tool |
| `docs/evidence/phase-00/E3-I/fixture/prompts/session-a.md` | Create | Exact project-control then runtime-override call sequence |
| `docs/evidence/phase-00/E3-I/fixture/prompts/session-b.md` | Create | Exact CLI-overlay call sequence |
| `docs/evidence/phase-00/E3-I/raw/*` | Create during execution | Sanitized parent/canary attempts and run metadata, never overwritten |
| `docs/evidence/phase-00/E3-I/I1.yml` | Create after observation | Project-control adjudication |
| `docs/evidence/phase-00/E3-I/I2.yml` | Create after observation | Runtime-override divergence adjudication |
| `docs/evidence/phase-00/E3-I/I3.yml` | Create after observation | CLI-overlay divergence adjudication |
| `docs/evidence/phase-00/E3-I/I4.yml` | Create after observation | Nine-canary safety/reliability/cost adjudication |
| `docs/evidence/phase-00/E3-I/conclusion.yml` | Create after observation | Aggregate E3-I outcome and authority limits |
| `docs/evidence/phase-00/manifest.yml` | Modify after adjudication | E3-I terminal state/artifacts only; parallel stays disabled |
| `codex-phase00-execution-changelog-for-opus5.md` | Append | Exact English mutation, evidence, hashes, debugging, and review ledger |

The E3-I helper may consume these existing interfaces without modifying them:

```powershell
Read-Phase00JsonLines -Path <string>                         # phase00-runtime-evidence.ps1
Get-Phase00PropertyValue -Object <object> -Name <string>     # phase00-runtime-evidence.ps1
Test-Phase00HasProperty -Object <object> -Name <string>      # phase00-runtime-evidence.ps1
Get-Phase00TerminalModelFailure -Events <object[]>           # phase00-runtime-evidence.ps1
Protect-Phase00EvidenceText -Text <string> `
  -RepositoryRoot <string> -DisposableRoot <string>          # phase00-runtime-evidence.ps1
Get-Phase00ConfigCommandClassification `
  -ExpectedKey <string> -ExitCode <int> -Stdout <string> `
  -Stderr <string> -Context <string>                         # phase00-config-evidence.ps1
```

Do not move process or filesystem functions out of the closed E3-A/E3-H runner. E3-I owns
equivalent narrowly-scoped runner functions to avoid modifying a previously closed slice.

---

### Task 1: Correct the E3-I normative primitive and establish the RED/GREEN harness

**Files:**

- Modify: `spec/phases/phase-00-foundation.md:424-427`
- Create: `scripts/tests/phase00-e3i.Tests.ps1`
- Create: `scripts/lib/phase00-e3i-evidence.ps1`

**Interfaces:**

- Consumes: pinned source facts for `Settings.set`, `Settings.override`, and summary text.
- Produces: `New-Phase00E3IAnalysis` and `Get-Phase00E3ISummaryBranch` for every later task.

- [ ] **Step 1: Record the exact pre-edit authority hashes**

Run:

```powershell
Get-FileHash -Algorithm SHA256 `
  spec/phases/phase-00-foundation.md, `
  docs/evidence/phase-00/manifest.yml, `
  docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md
git branch --show-current
git rev-parse HEAD
git diff --cached --name-only
```

Expected: branch `main`, HEAD `62fecf277dc9d5e47d06319387eac747462214c1`, zero
staged files. Preserve the hashes for P00-CX-021.

- [ ] **Step 2: Write the initial failing Pester contract**

Create `scripts/tests/phase00-e3i.Tests.ps1` with this bootstrap and first assertions:

```powershell
#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runtimeHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-runtime-evidence.ps1'
$configHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-config-evidence.ps1'
$e3iHelperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-e3i-evidence.ps1'
$runnerPath = Join-Path $repositoryRoot 'scripts\run-phase00-e3i.ps1'
$script:e3iHelperLoaded = $false
$script:e3iRunnerLoaded = $false

. $runtimeHelperPath
. $configHelperPath
if (Test-Path -LiteralPath $e3iHelperPath -PathType Leaf) {
    . $e3iHelperPath
    $script:e3iHelperLoaded = $true
}
if (Test-Path -LiteralPath $runnerPath -PathType Leaf) {
    . $runnerPath
    $script:e3iRunnerLoaded = $true
}

function Assert-E3IHelperLoaded { $script:e3iHelperLoaded | Should Be $true }
function Assert-E3IRunnerLoaded { $script:e3iRunnerLoaded | Should Be $true }

Describe 'E3-I merge-summary classifier' {
    It 'classifies only the two exact merge-summary branches' {
        Assert-E3IHelperLoaded
        (Get-Phase00E3ISummaryBranch `
            '<merge-summary>Isolation: no changes captured.</merge-summary>').Branch |
            Should Be 'APPLY_FALSE_CAPTURE_ONLY'
        (Get-Phase00E3ISummaryBranch `
            '<merge-summary>No changes to apply.</merge-summary>').Branch |
            Should Be 'APPLY_TRUE_NO_DIFF'
        (Get-Phase00E3ISummaryBranch `
            '<merge-summary>Nothing changed.</merge-summary>').Branch |
            Should Be 'CONTRADICTION'
    }
}
```

- [ ] **Step 3: Run the focused test and confirm RED**

Run in PowerShell 7:

```powershell
Invoke-Pester -Path scripts/tests/phase00-e3i.Tests.ps1 -PassThru
```

Expected: failure because `Get-Phase00E3ISummaryBranch` does not exist. Do not add a test
that greps the normative Markdown: it would test prose wording rather than runtime behavior.

- [ ] **Step 4: Apply the narrow normative correction**

Replace only the current E3-I paragraph at lines 424-427 with:

```markdown
Run the same shape a second time with an **in-session runtime override** instead of a CLI
overlay. Use a disposable project custom tool whose parent-scoped execute path calls
`pi.pi.settings.override("task.isolation.apply", true)` exactly once, records the value
immediately before and after, and calls neither `Settings.set()` nor any flush/save path.
The `pi.pi.settings` surface is permitted only because this experiment launches the default
main CLI and runtime behavior must corroborate the pinned identity chain. The advertised
project-tool `ctx.settings` surface is not executable on v17.2.10 because
`sdk.ts:885-894,938-955` omits it.
`Settings.override()` writes the non-persistent in-memory `#overrides` layer
(`config/settings.ts:518-526`). The normal `/settings` selector is **not** this primitive:
it calls `Settings.set()` (`modes/components/settings-selector.ts:1272-1282`), which updates
global settings and queues persistence (`config/settings.ts:498-505`). The custom-tool
factory MUST return no tools for the isolated child cwd; otherwise the override tool would
contaminate the canary surface because custom-tool paths are forwarded to subagents and
registered tools are force-included (`structured-subagent.ts:439-440`,
`sdk.ts:1980-1990,3025-3036`). This runtime-override variant is the harder case and the one
no external read can catch.
```

Do not edit E3-L or E3-M in this task.

Review the resulting E3-I diff directly against pinned source and record before/after
SHA-256. Normative prose is an authority artifact, not production code; its correctness is
established by source reconciliation and peer review rather than a brittle text-presence
test.

- [ ] **Step 5: Implement the minimal summary decision helper**

Create `scripts/lib/phase00-e3i-evidence.ps1`:

```powershell
#Requires -Version 5.1
Set-StrictMode -Version 2.0

function New-Phase00E3IAnalysis {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PASS','FAIL','INVALID_RUN','BLOCKED_ENVIRONMENT')]
        [string]$Status,
        [Parameter(Mandatory)][string[]]$Reasons,
        [hashtable]$Data = @{}
    )
    $result = [ordered]@{ Status = $Status; Reasons = @($Reasons) }
    foreach ($key in $Data.Keys) { $result[$key] = $Data[$key] }
    [pscustomobject]$result
}

function Get-Phase00E3ISummaryBranch {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Text)

    $match = [regex]::Match(
        $Text.Replace("`r`n", "`n"),
        '(?s)<merge-summary>\s*(.*?)\s*</merge-summary>'
    )
    if (-not $match.Success) {
        return [pscustomobject]@{ Branch = 'CONTRADICTION'; Summary = $null }
    }
    $summary = $match.Groups[1].Value.Trim()
    if ($summary.StartsWith('Isolation:', [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{
            Branch = 'APPLY_FALSE_CAPTURE_ONLY'
            Summary = $summary
        }
    }
    if ($summary -eq 'No changes to apply.') {
        return [pscustomobject]@{
            Branch = 'APPLY_TRUE_NO_DIFF'
            Summary = $summary
        }
    }
    [pscustomobject]@{ Branch = 'CONTRADICTION'; Summary = $summary }
}
```

- [ ] **Step 6: Run the focused test and confirm GREEN in both shells**

Run:

```powershell
pwsh -NoProfile -Command `
  "Invoke-Pester -Path scripts/tests/phase00-e3i.Tests.ps1 -PassThru"
powershell.exe -NoProfile -Command `
  "Invoke-Pester -Path scripts/tests/phase00-e3i.Tests.ps1 -PassThru"
```

Expected: both shells report zero failed tests. Record actual totals; do not predict or
invent them.

- [ ] **Step 7: Record Task 1's no-Git checkpoint**

Run:

```powershell
git diff --check
git diff --cached --name-only
Get-FileHash -Algorithm SHA256 `
  spec/phases/phase-00-foundation.md, `
  scripts/lib/phase00-e3i-evidence.ps1, `
  scripts/tests/phase00-e3i.Tests.ps1
```

Expected: diff check succeeds and staged-file count remains zero.

---

### Task 2: Implement strict parent/canary transcript primitives

**Files:**

- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify: `scripts/lib/phase00-e3i-evidence.ps1`

**Interfaces:**

- Consumes: `Get-Phase00PropertyValue`, `Test-Phase00HasProperty`, and
  `Get-Phase00ConfigCommandClassification` from existing helpers.
- Produces:
  `Get-Phase00E3IToolEventPairs -Events object[]`,
  `Get-Phase00E3IChildDiagnosticCommand`,
  `ConvertFrom-Phase00E3IChildDiagnostic -ToolResult object`,
  `Get-Phase00E3ITaskSample -Pair object -ExpectedId string`, and
  `Get-Phase00E3ICanarySession -Events object[] -ExpectedId string`.

- [ ] **Step 1: Add RED tests for exact pairing and child diagnostics**

Add local event factories and tests:

```powershell
function New-E3IToolStart([string]$Id, [string]$Name, $Arguments) {
    [pscustomobject]@{
        type = 'tool_execution_start'; toolCallId = $Id
        toolName = $Name; args = $Arguments
    }
}
function New-E3IToolEnd([string]$Id, [string]$Name, $Result, [bool]$IsError = $false) {
    [pscustomobject]@{
        type = 'tool_execution_end'; toolCallId = $Id
        toolName = $Name; result = $Result; isError = $IsError
    }
}

Describe 'E3-I strict transcript primitives' {
    It 'pairs mixed parent tools once and in start order' {
        Assert-E3IHelperLoaded
        $events = @(
            (New-E3IToolStart 'b1' 'bash' @{ command = 'probe' }),
            (New-E3IToolEnd 'b1' 'bash' @{ content = @() }),
            (New-E3IToolStart 't1' 'task' @{ tasks = @(@{ name = 'e3i-project-1' }) }),
            (New-E3IToolEnd 't1' 'task' @{ content = @() })
        )
        $pairs = @(Get-Phase00E3IToolEventPairs -Events $events)
        @($pairs.ToolName) | Should Be @('bash','task')
    }

    It 'rejects duplicate, unpaired, reversed, and unnamed events' {
        Assert-E3IHelperLoaded
        { Get-Phase00E3IToolEventPairs -Events @(
            (New-E3IToolStart 'x' 'task' @{}),
            (New-E3IToolStart 'x' 'task' @{}),
            (New-E3IToolEnd 'x' 'task' @{})
        ) } | Should Throw
        { Get-Phase00E3IToolEventPairs -Events @(
            (New-E3IToolEnd 'x' 'task' @{})
        ) } | Should Throw
    }

    It 'accepts only the exact direct OMP false child diagnostic object' {
        Assert-E3IHelperLoaded
        $json = '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"known"}'
        $toolResult = @{
            content = @(@{ type = 'text'; text = "$json`n`n`nWall time: 0.12 seconds" })
        }
        $result = ConvertFrom-Phase00E3IChildDiagnostic -ToolResult $toolResult
        $result.Status | Should Be 'OBSERVED'
        $result.Value | Should Be $false
    }

    It 'invalidates extra keys, string false, wrong key, malformed JSON, and bash suffix ambiguity' {
        Assert-E3IHelperLoaded
        foreach ($payload in @(
            '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"known","extra":1}',
            '{"key":"task.isolation.apply","value":"false","type":"boolean","description":"known"}',
            '{"key":"other","value":false,"type":"boolean","description":"known"}',
            'not-json',
            '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"known"}{"second":true}'
        )) {
            $text = "$payload`n`n`nWall time: 0.12 seconds"
            $result = ConvertFrom-Phase00E3IChildDiagnostic -ToolResult @{
                content = @(@{ type = 'text'; text = $text })
            }
            $result.Status | Should Be 'INVALID_RUN'
        }
        $bare = ConvertFrom-Phase00E3IChildDiagnostic -ToolResult @{
            content = @(@{ type = 'text'; text =
                '{"key":"task.isolation.apply","value":false,"type":"boolean","description":"known"}' })
        }
        $bare.Status | Should Be 'INVALID_RUN'
    }
}
```

- [ ] **Step 2: Run focused Pester and confirm RED**

Run:

```powershell
Invoke-Pester -Path scripts/tests/phase00-e3i.Tests.ps1 -PassThru
```

Expected: new tests fail because the four transcript functions are absent.

- [ ] **Step 3: Implement exact mixed-tool pairing**

Append this contract to the helper:

```powershell
function Get-Phase00E3IToolEventPairs {
    param([Parameter(Mandatory)][object[]]$Events)

    $starts = @{}; $ends = @{}; $startIndex = @{}; $endIndex = @{}
    for ($index = 0; $index -lt $Events.Count; $index++) {
        $event = $Events[$index]
        $type = [string](Get-Phase00PropertyValue $event 'type')
        if ($type -notin @('tool_execution_start','tool_execution_end')) { continue }
        $id = [string](Get-Phase00PropertyValue $event 'toolCallId')
        $name = [string](Get-Phase00PropertyValue $event 'toolName')
        if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($name)) {
            throw "Tool event at index $index lacks identity."
        }
        if ($type -eq 'tool_execution_start') {
            if ($starts.ContainsKey($id)) { throw "Duplicate tool start '$id'." }
            $starts[$id] = $event; $startIndex[$id] = $index
        } else {
            if ($ends.ContainsKey($id)) { throw "Duplicate tool end '$id'." }
            $ends[$id] = $event; $endIndex[$id] = $index
        }
    }
    $ids = @($starts.Keys + $ends.Keys | Sort-Object -Unique)
    if ($ids.Count -eq 0) { throw 'No parent tool events found.' }
    $pairs = foreach ($id in $ids) {
        if (-not $starts.ContainsKey($id) -or -not $ends.ContainsKey($id)) {
            throw "Unpaired tool event '$id'."
        }
        if ([int]$startIndex[$id] -ge [int]$endIndex[$id]) {
            throw "Tool end does not follow start for '$id'."
        }
        $startName = [string](Get-Phase00PropertyValue $starts[$id] 'toolName')
        $endName = [string](Get-Phase00PropertyValue $ends[$id] 'toolName')
        if ($startName -ne $endName) { throw "Tool name mismatch for '$id'." }
        [pscustomobject][ordered]@{
            ToolCallId = $id; ToolName = $startName
            StartIndex = [int]$startIndex[$id]; EndIndex = [int]$endIndex[$id]
            Start = $starts[$id]; End = $ends[$id]
        }
    }
    @($pairs | Sort-Object StartIndex)
}
```

- [ ] **Step 4: Implement strict text and child-diagnostic extraction**

Append:

```powershell
function Get-Phase00E3IResultText {
    param([Parameter(Mandatory)]$ToolResult)
    $content = @(Get-Phase00PropertyValue $ToolResult 'content')
    if ($content.Count -ne 1 -or
        (Get-Phase00PropertyValue $content[0] 'type') -ne 'text') {
        throw 'Expected exactly one text content item.'
    }
    [string](Get-Phase00PropertyValue $content[0] 'text')
}

function Get-Phase00E3IPropertyNames {
    param([Parameter(Mandatory)]$Object)
    if ($Object -is [System.Collections.IDictionary]) {
        return @($Object.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    }
    @($Object.PSObject.Properties.Name | Sort-Object)
}

function Get-Phase00E3IChildDiagnosticCommand {
    'omp config get task.isolation.apply --json'
}

function ConvertFrom-Phase00E3IChildDiagnostic {
    param([Parameter(Mandatory)]$ToolResult)
    try {
        $text = (Get-Phase00E3IResultText $ToolResult).Replace("`r`n", "`n")
        $wrapper = [regex]::Match(
            $text,
            '(?s)\A(?<payload>.+?)\n\n\nWall time: [0-9]+(?:\.[0-9]+)? seconds\s*\z'
        )
        if (-not $wrapper.Success) { throw 'Bash result wrapper mismatch.' }
        $parsed = $wrapper.Groups['payload'].Value.Trim() | ConvertFrom-Json -ErrorAction Stop
        $properties = @($parsed.PSObject.Properties.Name | Sort-Object)
        if (($properties -join ',') -ne 'description,key,type,value') {
            throw 'Child diagnostic shape mismatch.'
        }
        if ($parsed.key -ne 'task.isolation.apply' -or $parsed.type -ne 'boolean' -or
            $parsed.value -isnot [bool] -or $parsed.description -isnot [string] -or
            [string]::IsNullOrWhiteSpace($parsed.description)) {
            throw 'Child diagnostic contract mismatch.'
        }
        [pscustomobject]@{ Status = 'OBSERVED'; Value = [bool]$parsed.value; Raw = $parsed }
    } catch {
        [pscustomobject]@{ Status = 'INVALID_RUN'; Value = $null; Error = $_.Exception.Message }
    }
}
```

The parser requires the known bash `Wall time:` wrapper and extracts exactly one payload.
Bare JSON, more than one JSON object, or another suffix remains invalid.

- [ ] **Step 5: Add RED tests for task samples and nested canary sessions**

Use a synthetic task result with one `details.results` entry containing
`durationMs=1200`, `tokens=34`, `exitCode=0`, and a rendered `<merge-summary>`. Add one
synthetic canary JSONL array with:

```powershell
@(
    [pscustomobject]@{
        type = 'session_init'; agent = 'phase00-e3i-canary'
        tools = @('read','yield','hub'); readOnly = $true
    },
    [pscustomobject]@{ type = 'agent_start' },
    [pscustomobject]@{
        type = 'message'
        message = [pscustomobject]@{
            role = 'assistant'
            content = @([pscustomobject]@{
                type = 'toolCall'; name = 'yield'
                arguments = [ordered]@{
                    type = 'result'
                    result = [ordered]@{
                        data = [ordered]@{
                            acknowledgement = 'PHASE00_E3I_CANARY_OK'
                        }
                    }
                }
            })
        }
    },
    [pscustomobject]@{ type = 'agent_end'; isTerminal = $true }
)
```

Assert the exact sample ID, branch, positive duration/tokens, exact controlled tool surface,
one conforming terminal `yield`, and zero forbidden calls. Add negative tests for two result
rows, missing duration, zero tokens,
`tools=@('read','yield','hub','phase00_e3i_override_apply_true')`, a `hub` start, and a
missing or malformed terminal `yield`.

- [ ] **Step 6: Run Pester and confirm the new tests are RED**

Expected: failure because `Get-Phase00E3ITaskSample` and
`Get-Phase00E3ICanarySession` are absent.

- [ ] **Step 7: Implement the task-sample and canary-session contracts**

Implement these exact return properties:

```powershell
function Get-Phase00E3ITaskSample {
    param([Parameter(Mandatory)]$Pair, [Parameter(Mandatory)][string]$ExpectedId)
    if ($Pair.ToolName -ne 'task') { throw 'Expected a task pair.' }
    $args = Get-Phase00PropertyValue $Pair.Start 'args'
    $tasks = @(Get-Phase00PropertyValue $args 'tasks')
    $topLevelProperties = @(Get-Phase00E3IPropertyNames $args)
    $itemProperties = if ($tasks.Count -eq 1) {
        @(Get-Phase00E3IPropertyNames $tasks[0])
    } else { @() }
    if (($topLevelProperties -join ',') -ne 'context,tasks' -or
        (Get-Phase00PropertyValue $args 'context') -ne
            'Phase 00 E3-I sequential behavioral canary' -or
        $tasks.Count -ne 1 -or
        ($itemProperties -join ',') -ne 'agent,isolated,name,task' -or
        (Get-Phase00PropertyValue $tasks[0] 'name') -ne $ExpectedId -or
        (Get-Phase00PropertyValue $tasks[0] 'agent') -ne 'phase00-e3i-canary' -or
        (Get-Phase00PropertyValue $tasks[0] 'task') -ne
            'Submit the exact acknowledgement required by your agent contract through its required terminal yield. Do not call any other tool.' -or
        (Get-Phase00PropertyValue $tasks[0] 'isolated') -ne $true) {
        throw "Task arguments mismatch for '$ExpectedId'."
    }
    $toolResult = Get-Phase00PropertyValue $Pair.End 'result'
    if ((Get-Phase00PropertyValue $Pair.End 'isError') -eq $true) {
        throw "Task '$ExpectedId' returned a tool error."
    }
    $details = Get-Phase00PropertyValue $toolResult 'details'
    $results = @(Get-Phase00PropertyValue $details 'results')
    if ($results.Count -ne 1) { throw "Task '$ExpectedId' has non-unit result cardinality." }
    $row = $results[0]
    $duration = [long](Get-Phase00PropertyValue $row 'durationMs')
    $tokens = [long](Get-Phase00PropertyValue $row 'tokens')
    $output = [string](Get-Phase00PropertyValue $row 'output')
    if ((Get-Phase00PropertyValue $row 'id') -ne $ExpectedId -or
        [int](Get-Phase00PropertyValue $row 'exitCode') -ne 0 -or
        (Get-Phase00PropertyValue $row 'aborted') -eq $true -or
        $output.Trim() -ne 'PHASE00_E3I_CANARY_OK' -or
        $duration -le 0 -or $tokens -le 0) {
        throw "Task result contract mismatch for '$ExpectedId'."
    }
    $branch = Get-Phase00E3ISummaryBranch (Get-Phase00E3IResultText $toolResult)
    [pscustomobject][ordered]@{
        Id = $ExpectedId; Branch = $branch.Branch; Summary = $branch.Summary
        DurationMs = $duration; Tokens = $tokens
        Requests = [int](Get-Phase00PropertyValue $row 'requests')
        ResolvedModel = [string](Get-Phase00PropertyValue $row 'resolvedModel')
    }
}

function Get-Phase00E3ICanarySession {
    param(
        [Parameter(Mandatory)][object[]]$Events,
        [Parameter(Mandatory)][string]$ExpectedId
    )
    $init = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'session_init'
    })
    if ($init.Count -ne 1 -or
        (Get-Phase00PropertyValue $init[0] 'agent') -ne 'phase00-e3i-canary' -or
        (Get-Phase00PropertyValue $init[0] 'readOnly') -ne $true) {
        throw "Canary '$ExpectedId' lacks one valid session_init."
    }
    $tools = @(Get-Phase00PropertyValue $init[0] 'tools')
    if (($tools -join ',') -ne 'read,yield,hub') {
        throw "Canary '$ExpectedId' tool surface is '$($tools -join ',')'."
    }
    $calls = @($Events | Where-Object {
        (Get-Phase00PropertyValue $_ 'type') -eq 'tool_execution_start'
    })
    [pscustomobject][ordered]@{
        Id = $ExpectedId; Tools = $tools; ReadOnly = $true
        ToolCallCount = $calls.Count; YieldCallCount = 1; ForbiddenToolCallCount = 0
        ToolNames = @($calls | ForEach-Object { Get-Phase00PropertyValue $_ 'toolName' })
        OverrideToolPresent = $tools -contains 'phase00_e3i_override_apply_true'
    }
}
```

- [ ] **Step 8: Run focused Pester in both shells and checkpoint hashes**

Expected: zero failures in both shells, `git diff --check` succeeds, zero staged files.

---

### Task 3: Implement exact session and I1-I4 adjudication

**Files:**

- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify: `scripts/lib/phase00-e3i-evidence.ps1`

**Interfaces:**

- Consumes: paired parent events, nine parsed task samples, nine parsed nested canary
  sessions, boundary evidence, and the existing terminal-model-failure classifier.
- Produces:
  `Test-Phase00E3ISessionA`, `Test-Phase00E3ISessionB`,
  `Test-Phase00I1Evidence`, `Test-Phase00I2Evidence`,
  `Test-Phase00I3Evidence`, and `Test-Phase00I4Evidence`.

- [ ] **Step 1: Add RED tests for the two exact parent sequences**

Build synthetic complete sequences with these names:

```powershell
$sessionASequence = @(
    'bash','task','task','task','phase00_e3i_override_apply_true',
    'bash','task','task','task'
)
$sessionATaskIds = @(
    'e3i-project-1','e3i-project-2','e3i-project-3',
    'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
)
$sessionBSequence = @('bash','task','task','task')
$sessionBTaskIds = @('e3i-cli-1','e3i-cli-2','e3i-cli-3')
```

Assert complete sequences are accepted. For each session, remove one call, add one call,
swap two calls, duplicate a tool result, mark a result as error, and change one task ID;
assert `INVALID_RUN`, never `FAIL` or `PASS`.

For each bash pair, assert the start args contain exactly `command` and `timeout`, the
command equals `Get-Phase00E3IChildDiagnosticCommand`, and timeout is integer `60`. For
the Session A override pair, assert its start args object has zero properties. A different
command, timeout, bash argument, or override parameter is `INVALID_RUN` because it no
longer executed the reviewed evidence procedure.

- [ ] **Step 2: Add RED tests for the override attestation**

The accepted override result has one text content item and details equal to:

```json
{
  "probe": "phase00-e3i-runtime-override-v1",
  "setting": "task.isolation.apply",
  "before": false,
  "operation": "pi.pi.settings.override",
  "requested": true,
  "after": true,
  "calledSet": false,
  "calledFlushOrSave": false,
  "scope": "parent-only"
}
```

Reject `before:true`, `after:false`, another operation, `calledSet:true`,
`calledFlushOrSave:true`, or extra properties as `FAIL` when a complete attestation is
attributable. A tool execution error is `INVALID_RUN`: no attestation exists to contradict.

- [ ] **Step 3: Add RED tests for I1-I4 and outcome separation**

Cover all of these cases explicitly:

```text
I1 PASS: child false + 3 project APPLY_FALSE_CAPTURE_ONLY + 3 clean canary sessions
I2 PASS: override false->true + child false + 3 runtime APPLY_TRUE_NO_DIFF + no persistence
I3 PASS: child false + 3 CLI APPLY_TRUE_NO_DIFF + no override call + 3 clean canary sessions
I4 PASS: 9 positive duration/token samples + 9 [read,yield,hub] sessions + one exact terminal yield and zero forbidden calls each + all boundaries clean
FAIL: wrong complete summary, child true, setter persistence, leaked override tool, hub call, parent/live mutation
INVALID_RUN: malformed JSONL, missing/extra/reordered calls, missing canary file, timeout, cleanup uncertainty
BLOCKED_ENVIRONMENT: parent or nested-canary terminal auth, quota,
                     overload/connection, or model-unavailable event
```

Assert no returned object contains `ALLOW_PARALLEL`.

- [ ] **Step 4: Run the focused tests and confirm RED**

Expected: failures because the session and case adjudicators do not exist.

- [ ] **Step 5: Implement the exact sequence validators**

Use one shared validator with immutable expected arrays:

```powershell
function Test-Phase00E3IParentSequence {
    param(
        [Parameter(Mandatory)][ValidateSet('A','B')][string]$Session,
        [Parameter(Mandatory)][object[]]$Pairs
    )
    $expected = if ($Session -eq 'A') {
        @('bash','task','task','task','phase00_e3i_override_apply_true','bash','task','task','task')
    } else { @('bash','task','task','task') }
    $actual = @($Pairs.ToolName)
    if (($actual -join ',') -ne ($expected -join ',')) {
        return New-Phase00E3IAnalysis INVALID_RUN @('E3I_PARENT_SEQUENCE_MISMATCH') @{
            Expected = $expected; Actual = $actual
        }
    }
    New-Phase00E3IAnalysis PASS @('E3I_PARENT_SEQUENCE_EXACT') @{
        Expected = $expected; Actual = $actual
    }
}
```

`Test-Phase00E3ISessionA` must parse diagnostics from pair indexes 0 and 5, samples from
indexes 1-3 and 6-8, and override details from index 4. `Test-Phase00E3ISessionB` must
parse its diagnostic from index 0 and samples from indexes 1-3. Neither function may
search for a favorable subsequence.

Implement `Test-Phase00E3IChildDiagnosticInvocation -Pair` to enforce the exact bash
start-argument contract above before passing `Pair.End.result` to
`ConvertFrom-Phase00E3IChildDiagnostic`.

Before sample adjudication, call `Get-Phase00TerminalModelFailure` on the parent events and
on every available nested canary event array. A parent environment block wins before
required-canary cardinality because the provider may fail before spawning any canary. For
a non-terminal parent, any nested environment block yields `BLOCKED_ENVIRONMENT`; a nested
non-environment terminal failure yields `INVALID_RUN`. Only after those checks may a
missing expected canary file become `E3I_CANARY_PROVENANCE_MISSING`.

- [ ] **Step 6: Implement strict override-result parsing**

Implement `ConvertFrom-Phase00E3IOverrideResult -ToolResult` by parsing `details` and
requiring the sorted property set:

```text
after,before,calledFlushOrSave,calledSet,operation,probe,requested,scope,setting
```

Return `PASS/E3I_OVERRIDE_ATTESTED` only for the exact object shown in Step 2. A complete
wrong object returns `FAIL/E3I_OVERRIDE_CONTRADICTION`; malformed or absent details return
`INVALID_RUN/E3I_OVERRIDE_EVIDENCE_INVALID`.

- [ ] **Step 7: Implement I1-I4 as conjunctions, not scorecards**

Use these exact reason codes:

```powershell
I1 pass: E3I_PROJECT_CONTROL_CONFIRMED
I2 pass: E3I_RUNTIME_OVERRIDE_DIVERGENCE_CONFIRMED
I3 pass: E3I_CLI_OVERLAY_DIVERGENCE_CONFIRMED
I4 pass: E3I_CANARY_SAFETY_RELIABILITY_CONFIRMED

semantic fail:
  E3I_CHILD_VALUE_CONTRADICTION
  E3I_SUMMARY_BRANCH_CONTRADICTION
  E3I_OVERRIDE_CONTRADICTION
  E3I_OVERRIDE_PERSISTED
  E3I_CANARY_TOOL_SURFACE_CONTAMINATED
  E3I_CANARY_TOOL_CALLED
  E3I_PARENT_MUTATION
  E3I_LIVE_HOME_MUTATION

invalid run:
  E3I_PARENT_SEQUENCE_MISMATCH
  E3I_EVENT_PAIRING_INVALID
  E3I_CANARY_PROVENANCE_MISSING
  E3I_COST_OBSERVATION_MISSING
  E3I_TIMEOUT
  E3I_CLEANUP_UNCERTAIN
```

Each `Test-Phase00I*Evidence` returns `New-Phase00E3IAnalysis`. PASS requires every
predicate; do not average repeated samples. `Test-Phase00I4Evidence` accepts a boundary
object with exact booleans:

```powershell
[pscustomobject]@{
    ParentContentUnchanged = $true
    ParentHeadUnchanged = $true
    ParentStatusUnchanged = $true
    FixtureHashesUnchanged = $true
    LiveHomeUnchanged = $true
    CleanupSucceeded = $true
}
```

- [ ] **Step 8: Run focused Pester in both shells and record the GREEN checkpoint**

Expected: all E3-I decision tests pass, zero warnings promoted by the test runner, diff
check passes, zero staged files.

---

### Task 4: Build the parent-scoped fixture and disposable runner test-first

**Files:**

- Create: `docs/evidence/phase-00/E3-I/fixture/.omp/config.yml`
- Create: `docs/evidence/phase-00/E3-I/fixture/overlay.yml`
- Create: `docs/evidence/phase-00/E3-I/fixture/.omp/agents/phase00-e3i-canary.md`
- Create: `docs/evidence/phase-00/E3-I/fixture/.omp/tools/phase00-e3i-runtime-override.ts`
- Create: `docs/evidence/phase-00/E3-I/fixture/prompts/session-a.md`
- Create: `docs/evidence/phase-00/E3-I/fixture/prompts/session-b.md`
- Create: `scripts/run-phase00-e3i.ps1`
- Modify: `scripts/tests/phase00-e3i.Tests.ps1`

**Interfaces:**

- Consumes: all Task 2/3 analyzers and existing sanitization/config helpers.
- Produces:
  `Get-Phase00E3IParentArguments`, `Initialize-Phase00E3IFixture`,
  `Assert-Phase00E3IDisposableRoot`, `Remove-Phase00E3IDisposableDirectory`,
  `Get-Phase00E3IRepositorySnapshot`, `Compare-Phase00E3IRepositorySnapshot`,
  `Get-Phase00E3IDirectoryMetadataSnapshot`,
  `Compare-Phase00E3IDirectoryMetadataSnapshot`,
  `Invoke-Phase00E3ICapturedProcess`, `Copy-Phase00E3ICanaryArtifacts`,
  `Write-Phase00E3IUtf8NoBom`, and `Invoke-Phase00E3IEvidenceSession`.

- [ ] **Step 1: Add RED fixture and runner-surface tests**

Assert all six fixture files and the runner exist. Dot-source the runner and assert the
seven functions above exist. Assert:

```powershell
$a = @(Get-Phase00E3IParentArguments -Session A -FixtureRoot 'P' `
    -SessionDirectory 'S' -OverlayPath 'O' -Model 'M' -Prompt 'PROMPT')
$b = @(Get-Phase00E3IParentArguments -Session B -FixtureRoot 'P' `
    -SessionDirectory 'S' -OverlayPath 'O' -Model 'M' -Prompt 'PROMPT')
($a -contains '--config') | Should Be $false
($b -join ' ') | Should Match '--config O'
($a -join ' ') | Should Match '--tools task,bash'
($b -join ' ') | Should Match '--tools task,bash'
```

Add negative cleanup tests proving a repository path, user-home path, filesystem root,
and path outside OS temp are rejected. Assert all twelve runner functions named in the
interface block exist after the runner is dot-sourced.

- [ ] **Step 2: Run focused Pester and confirm RED**

Expected: missing fixture/runner failures.

- [ ] **Step 3: Create the exact configuration and canary fixtures**

Project config:

```yaml
task:
  isolation:
    mode: rcopy
    apply: false
```

CLI overlay:

```yaml
task:
  isolation:
    apply: true
```

Canary agent:

```markdown
---
name: phase00-e3i-canary
description: Blocking Phase 00 E3-I terminal-yield-only behavioral canary.
tools: read
blocking: true
---

This is a non-mutating Phase 00 characterization canary. Do not call read, hub, any MCP
tool, or any other capability. Do not modify any file or external state. Make exactly one
tool call: terminal `yield` with `type: "result"` and
`result.data.acknowledgement: "PHASE00_E3I_CANARY_OK"`. Do not send assistant prose first.
```

- [ ] **Step 4: Create the parent-cwd-only custom tool**

Use the complete module below:

```ts
import path from "node:path";
import type { CustomToolFactory } from "@oh-my-pi/pi-coding-agent";

const normalize = (value: string): string =>
  path.resolve(value).replace(/[\\/]+$/, "").toLowerCase();

const factory: CustomToolFactory = (pi) => {
  const parentCwd = process.env.OMP_PHASE00_E3I_PARENT_CWD;
  if (!parentCwd || normalize(pi.cwd) !== normalize(parentCwd)) return [];

  return {
    name: "phase00_e3i_override_apply_true",
    label: "Phase 00 E3-I Runtime Override",
    description: "Sets only task.isolation.apply=true in the disposable parent session.",
    loadMode: "essential",
    parameters: pi.zod.object({}),
    async execute() {
      const currentParent = process.env.OMP_PHASE00_E3I_PARENT_CWD;
      if (!currentParent || normalize(pi.cwd) !== normalize(currentParent)) {
        throw new Error("P00_E3I_PARENT_SCOPE_MISMATCH");
      }
      const before = pi.pi.settings.get("task.isolation.apply");
      pi.pi.settings.override("task.isolation.apply", true);
      const after = pi.pi.settings.get("task.isolation.apply");
      const details = {
        probe: "phase00-e3i-runtime-override-v1",
        setting: "task.isolation.apply",
        before,
        operation: "pi.pi.settings.override",
        requested: true,
        after,
        calledSet: false,
        calledFlushOrSave: false,
        scope: "parent-only",
      };
      return {
        content: [{ type: "text", text: JSON.stringify(details) }],
        details,
      };
    },
  };
};

export default factory;
```

Do not add parameters, an unreviewed settings fallback, `set`, `clearOverride`, flush,
save, filesystem writes, or process execution. `pi.pi.settings` is the selected
default-main-CLI primitive and must not be generalized to other host modes.

- [ ] **Step 5: Create the exact child diagnostic command in both prompts**

Both prompts must use this one bash command verbatim for each diagnostic, with
`timeout: 60` and no other bash argument:

```text
omp config get task.isolation.apply --json
```

The parent must not infer or restate the result; the analyzer consumes the paired bash
tool result.

- [ ] **Step 6: Create `session-a.md` with the exact call sequence**

The prompt must instruct exactly:

```text
1. Call bash once with the reviewed child diagnostic command.
2. Call task three separate times, one item per call, in this order:
   e3i-project-1, e3i-project-2, e3i-project-3.
3. Call phase00_e3i_override_apply_true once with {}.
4. Call bash once with the same reviewed child diagnostic command.
5. Call task three separate times, one item per call, in this order:
   e3i-runtime-1, e3i-runtime-2, e3i-runtime-3.
6. Make no other tool call and finish with exactly E3I_SESSION_A_DONE.
```

Every task call uses one item with this exact shape, substituting only the reviewed name:

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

The prompt explicitly forbids batching, concurrency, retries, substituted IDs, skipped
calls, extra diagnostics, source/config reads, and direct configuration edits.

- [ ] **Step 7: Create `session-b.md` with the exact call sequence**

The prompt must instruct exactly:

```text
1. Call bash once with the reviewed child diagnostic command.
2. Call task three separate times, one item per call, in this order:
   e3i-cli-1, e3i-cli-2, e3i-cli-3.
3. Do not call phase00_e3i_override_apply_true.
4. Make no other tool call and finish with exactly E3I_SESSION_B_DONE.
```

Use the same unit task shape from Step 6 with only the name changed.

- [ ] **Step 8: Implement runner bootstrap and argument construction**

Start `scripts/run-phase00-e3i.ps1` with:

```powershell
#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('A','B')][string]$Session = 'A',
    [string]$Model = 'omniroute/codex/gpt-5.6-sol-high',
    [ValidateRange(1,999)][int]$Attempt = 1,
    [string]$OmpExecutable,
    [switch]$AllowOverwrite
)
Set-StrictMode -Version 2.0

$script:Phase00E3IRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'lib\phase00-runtime-evidence.ps1')
. (Join-Path $PSScriptRoot 'lib\phase00-config-evidence.ps1')
. (Join-Path $PSScriptRoot 'lib\phase00-e3i-evidence.ps1')
```

`Get-Phase00E3IParentArguments` returns:

```powershell
$arguments = @(
    '-p','--mode','json','--cwd',$FixtureRoot,
    '--session-dir',$SessionDirectory,'--model',$Model,
    '--tools','task,bash','--approval-mode','yolo','--max-time','12m',
    '--no-extensions','--no-skills','--no-rules','--no-lsp','--no-title'
)
if ($Session -eq 'B') {
    $insert = [Array]::IndexOf($arguments, '--model')
    $arguments = @(
        $arguments[0..($insert-1)] + @('--config',$OverlayPath) +
        $arguments[$insert..($arguments.Count-1)]
    )
}
@($arguments + $Prompt)
```

- [ ] **Step 9: Implement disposable setup and parent-scope environment**

`Initialize-Phase00E3IFixture` must:

1. accept only a root under `[IO.Path]::GetTempPath()`;
2. create `agent`, `project`, and `sessions` sibling directories;
3. copy the reviewed fixture tree into `project`;
4. copy `docs/evidence/phase-00/environment/runtime-models.yml` to `agent/models.yml`;
5. initialize a disposable Git repository, configure only local invalid identity, add all,
   commit baseline, and return its HEAD;
6. return an environment hashtable without modifying process-global variables:

```powershell
@{
    PI_CODING_AGENT_DIR = [IO.Path]::GetFullPath($agentDirectory)
    OMP_PHASE00_E3I_PARENT_CWD = [IO.Path]::GetFullPath($projectRoot)
}
```

- [ ] **Step 10: Implement deterministic content/Git snapshots**

`Get-Phase00E3IRepositorySnapshot -ProjectRoot` must sort every file excluding `.git`,
hash each file, and hash the UTF-8 sequence `relative-path<TAB>sha256<LF>`. Return:

```powershell
[pscustomobject][ordered]@{
    ContentSha256 = $aggregateHash
    FileCount = $rows.Count
    Files = @($rows)
    Head = (& git -C $ProjectRoot rev-parse HEAD).Trim()
    Status = @(& git -C $ProjectRoot status --porcelain=v1 --untracked-files=all)
    FixtureHashes = [ordered]@{
        ProjectConfig = (Get-FileHash ...).Hash
        Overlay = (Get-FileHash ...).Hash
        Agent = (Get-FileHash ...).Hash
        OverrideTool = (Get-FileHash ...).Hash
        SessionA = (Get-FileHash ...).Hash
        SessionB = (Get-FileHash ...).Hash
    }
}
```

`Compare-Phase00E3IRepositorySnapshot` returns the six exact booleans required by the I4
boundary object. No comparison may ignore an added/deleted parent file.

- [ ] **Step 11: Implement live-home metadata and safe cleanup boundaries**

Copy the established relative-path, length, UTC-mtime, and SHA-256 directory metadata
semantics into the E3-I-named snapshot/compare functions. A missing directory is an empty
snapshot, not an error. The comparison returns before/after file counts, aggregate hashes,
changed paths, changed count, and `BoundaryResult` equal to `PASS` only for zero changes.

`Assert-Phase00E3IDisposableRoot` must require a non-root descendant of the OS temp path.
`Remove-Phase00E3IDisposableDirectory` calls that assertion immediately before
`Remove-Item -LiteralPath ... -Recurse -Force` and verifies the path no longer exists.

- [ ] **Step 12: Implement captured process execution and sanitization**

Copy the proven `ProcessStartInfo` semantics from the E3-A/E3-H runner into the new,
renamed `Invoke-Phase00E3ICapturedProcess`. Requirements:

```text
UseShellExecute=false
CreateNoWindow=true
RedirectStandardOutput=true
RedirectStandardError=true
argument-list API when present; exact Windows quoting fallback otherwise
async stdout/stderr reads before WaitForExit
timeout kills only the known child process tree
return ExitCode, Stdout, Stderr, StartedAt, CompletedAt, TimedOut
```

Sanitize with `Protect-Phase00EvidenceText` before writing any raw artifact. Redact the
repository and disposable roots. Do not serialize environment values; record only:

```json
{
  "PI_CODING_AGENT_DIR": "<DISPOSABLE_AGENT_DIR>",
  "OMP_PHASE00_E3I_PARENT_CWD": "<DISPOSABLE_PROJECT>"
}
```

- [ ] **Step 13: Preserve and validate nested canary JSONL before cleanup**

`Copy-Phase00E3ICanaryArtifacts` receives the expected session-specific IDs and searches
the disposable session directory recursively. For each ID it must find exactly one
`<id>.jsonl`, sanitize it, write it as
`<stem>.canary.<id>.jsonl`, parse it with `Read-Phase00JsonLines`, and return its parsed
events and hash. Zero or multiple matches is `E3I_CANARY_PROVENANCE_MISSING` and makes the
attempt `INVALID_RUN`.

- [ ] **Step 14: Implement `Invoke-Phase00E3IEvidenceSession`**

The function must perform this exact lifecycle:

```text
verify the explicitly selected OMP executable reports exactly 17.2.10
copy it into the verified disposable root and require source/copy SHA-256 equality
prepend the disposable runtime directory so nested `omp` resolves to the same copy
refuse overwrite of any existing stem artifact
snapshot live home
create verified disposable fixture
snapshot parent/config before
launch exactly one parent process
sanitize and persist parent stdout/stderr
strictly parse parent JSONL when present
classify a parent terminal provider failure before required-canary cardinality
preserve every canary JSONL that exists
if the parent is not terminal, require and strictly parse every expected canary JSONL
classify nested canary terminal provider failures before semantic adjudication
adjudicate Session A or Session B only after complete provenance exists
snapshot parent/config and live home after
write run JSON outside disposable root
verify and remove only disposable root
record cleanup result
return paths + analysis
```

Raw names are:

```text
session-a.stdout.jsonl / session-a.stderr.txt / session-a.run.json
session-b.stdout.jsonl / session-b.stderr.txt / session-b.run.json
session-a-attempt-NNN.* and session-b-attempt-NNN.* for N > 1
```

The script entry point calls the function only when not dot-sourced.

- [ ] **Step 15: Run fixture/runner tests in both shells without provider access**

Tests materialize and remove a caller-provided temp root, validate both argument arrays,
snapshot an added/deleted file, reject unsafe cleanup paths, and prove the caller process
does not gain `OMP_PHASE00_E3I_PARENT_CWD`. They do not invoke the provider.

Expected: zero failures, no `omp-phase00-e3i-*` temp root remains, diff check passes, zero
staged files.

---

### Task 5: Close static and direct-runtime readiness before provider execution

**Files:**

- Modify: `scripts/tests/phase00-e3i.Tests.ps1`
- Modify only if RED proves a defect: E3-I helper, runner, or fixture files
- Append: `codex-phase00-execution-changelog-for-opus5.md` as P00-CX-021

**Interfaces:**

- Consumes: complete helper/runner/fixture surface.
- Produces: provider-safe GREEN checkpoint and an exact pre-runtime mutation ledger.

- [ ] **Step 1: Run a read-only source-pin and fixture non-contamination audit**

Do not encode pinned upstream prose or line snippets as Pester assertions: that would test
source text rather than executable behavior and turn the suite into a change detector. Run
a read-only, hash-ledgered audit instead. Require pinned upstream HEAD
`3a8591a8af5b6d200088d12ca75a5517cb064fa8` and verify these source anchors:

```text
settings.ts:498-505          set -> global + queueSave
settings.ts:518-526          override -> #overrides, no queueSave
settings.ts:2143-2147        global -> project -> configOverlay -> overrides
structured-subagent.ts:315-317 live apply read
structured-subagent.ts:439-440 custom-tool paths forwarded to child
executor.ts:2675-2692        read agent widened with hub
executor.ts:2910-2916        isolated worktree becomes child cwd
sdk.ts:1980-1990             child reloads custom-tool factories
sdk.ts:3025-3036             registered tools force-included
custom-tools/types.ts:85-105 nominal settings declaration
sdk.ts:885-894,938-955       project-tool bridge omits settings
custom-tools/loader.ts:132-154 and index.ts:17 expose pi.pi.settings
main.ts:1282-1283,1545       default CLI shares initialized Settings with session
```

Also audit that the custom module contains exactly one `.override(` and zero `.set(`,
`.flush`, `.save`, `pi.exec`, filesystem-write calls, or general setting/value parameters.
Record the exact commands, source paths/lines, counts, and hashes in P00-CX-021. Pester
continues to cover executable factory/config/runner behavior only.

- [ ] **Step 2: Add a direct child config diagnostic control**

Use `Initialize-Phase00E3IFixture`, the explicitly selected/copy-hashed OMP executable, the relocated
agent environment, and project cwd to run:

```text
omp config get task.isolation.apply --json
```

Strictly parse it through the existing configuration helper and require boolean `false`.
This is direct fixture readiness only; it is not E3-I PASS and not parent-overlay evidence.

- [ ] **Step 3: Run focused E3-I tests in both shells**

Expected: all tests pass, including real disposable config read, without a provider call.

- [ ] **Step 4: Run all existing Phase 00 tests and validator in both shells**

Run each suite independently so failures are attributable:

```powershell
Invoke-Pester scripts/tests/phase00-wave-a.Tests.ps1 -PassThru
Invoke-Pester scripts/tests/phase00-e3j-e3k.Tests.ps1 -PassThru
Invoke-Pester scripts/tests/phase00-e3a-e3h.Tests.ps1 -PassThru
Invoke-Pester scripts/tests/phase00-e3i.Tests.ps1 -PassThru
& scripts/validate-template.ps1
```

Repeat through `powershell.exe -NoProfile`. Expected: zero failed tests and validator zero
failures/warnings in both shells.

- [ ] **Step 5: Append P00-CX-021**

Record in English:

- P00-CX-020 predecessor hash;
- every created/modified path with before/after SHA-256;
- exact normative correction and source anchors;
- planning amendment for custom-tool forwarding;
- RED test names and failure reasons actually observed;
- GREEN totals in both shells;
- direct config control result;
- live-home/temp-root checks;
- branch/HEAD/status/staged count;
- no provider call and no Git integration;
- next gate: Session A provider execution.

Never invent transient RED totals that were not captured.

---

### Task 6: Execute and adjudicate Session A

**Files:**

- Modify: `docs/evidence/phase-00/manifest.yml` (`E3-I: READY -> RUNNING` before launch)
- Create: `docs/evidence/phase-00/E3-I/raw/session-a*`
- Modify only if evidence proves a defect: E3-I helper, runner, fixture, or tests
- Append later to P00-CX-022; do not overwrite P00-CX-021

**Interfaces:**

- Consumes: provider-safe GREEN checkpoint.
- Produces: selected or preserved non-selected Session A raw evidence plus preliminary I1/I2.

- [ ] **Step 1: Verify the launch gate immediately before mutation**

Run focused tests once in PowerShell 7, verify the selected executable is OMP `17.2.10`, verify the model catalog
contains the requested model, confirm no selected Session A artifact exists, compare live
home with the last known metadata snapshot, and confirm zero staged files.

- [ ] **Step 2: Move only E3-I to `RUNNING`**

Patch the E3-I row only. Keep artifacts empty and decision null while running. Do not
change another row or `parallel_mode`.

- [ ] **Step 3: Execute Session A once**

Run:

```powershell
pwsh -NoProfile -File scripts/run-phase00-e3i.ps1 `
  -Session A -Model omniroute/codex/gpt-5.6-sol-high -Attempt 2 `
  -OmpExecutable <EXACT_17_2_10_EXECUTABLE>
```

Do not expose environment values in console summaries.

- [ ] **Step 4: Classify the attempt before any retry**

Apply this decision table:

```text
BLOCKED_ENVIRONMENT -> preserve artifacts; do not retry unchanged external state; skip Session B
FAIL                -> preserve artifacts; do not retry a semantic/safety contradiction
INVALID_RUN         -> preserve artifacts; identify the exact evidence/prompt/runner defect;
                       add a RED regression; fix to GREEN; only then use Attempt 2
PASS                -> select attempt; continue to preliminary I1/I2 checks
```

Never overwrite Attempt 1 or combine it with another attempt.

- [ ] **Step 5: Verify preliminary I1 and I2 from one selected Session A**

Require:

```text
two child diagnostics: false, false
project summaries: 3/3 APPLY_FALSE_CAPTURE_ONLY
override: false -> true through pi.pi.settings.override, parent-only default main CLI
runtime summaries: 3/3 APPLY_TRUE_NO_DIFF
six nested session_init.tools: [read,yield,hub]
six nested canary calls: exactly one conforming terminal yield and zero forbidden calls each
six positive duration/token observations
project content/HEAD/status/config hashes unchanged
live home unchanged
cleanup succeeded
```

Do not create I1/I2 YAML yet; retain the machine analysis in the run JSON until Session B
and I4 can be jointly checked.

---

### Task 7: Execute and adjudicate Session B

**Files:**

- Create: `docs/evidence/phase-00/E3-I/raw/session-b*`
- Modify only if evidence proves a defect: E3-I helper, runner, fixture, or tests
- Append later to P00-CX-022

**Interfaces:**

- Consumes: selected PASS Session A. Do not run Session B after Session A
  `BLOCKED_ENVIRONMENT`, `FAIL`, or unresolved `INVALID_RUN`.
- Produces: selected or preserved non-selected Session B raw evidence plus preliminary I3.

- [ ] **Step 1: Re-run the focused launch gate**

Require fresh E3-I GREEN, OMP version match, zero staged files, no selected Session B
artifact, and unchanged live-home baseline.

- [ ] **Step 2: Execute Session B once**

Run:

```powershell
pwsh -NoProfile -File scripts/run-phase00-e3i.ps1 `
  -Session B -Model omniroute/codex/gpt-5.6-sol-high -Attempt 1 `
  -OmpExecutable <EXACT_17_2_10_EXECUTABLE>
```

- [ ] **Step 3: Apply the same no-overwrite/no-automatic-retry classification table**

Preserve every attempt. Only a regression-backed correction may precede a numbered retry.

- [ ] **Step 4: Verify preliminary I3 from one selected Session B**

Require:

```text
child diagnostic: false
CLI summaries: 3/3 APPLY_TRUE_NO_DIFF
override tool calls: 0
three nested session_init.tools: [read,yield,hub]
three nested canary calls: exactly one conforming terminal yield and zero forbidden calls each
three positive duration/token observations
project content/HEAD/status/config hashes unchanged
live home unchanged
cleanup succeeded
```

The CLI overlay is established by the sanitized launch argument record and live behavior;
parent prose has no evidentiary authority.

---

### Task 8: Materialize I1-I4, conclusion, and the legal manifest outcome

**Files:**

- Create: `docs/evidence/phase-00/E3-I/I1.yml`
- Create: `docs/evidence/phase-00/E3-I/I2.yml`
- Create: `docs/evidence/phase-00/E3-I/I3.yml`
- Create: `docs/evidence/phase-00/E3-I/I4.yml`
- Create: `docs/evidence/phase-00/E3-I/conclusion.yml`
- Modify: `docs/evidence/phase-00/manifest.yml`
- Modify: `docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md`
- Modify: `scripts/tests/phase00-e3i.Tests.ps1`

**Interfaces:**

- Consumes: selected Session A/B raw/run artifacts or one terminal blocked/fail outcome.
- Produces: durable, hash-linked interpretation and one terminal E3-I manifest state.

- [ ] **Step 1: Generate the selected raw SHA-256 ledger**

Run `Get-FileHash -Algorithm SHA256` over every selected parent stdout/stderr/run file and
all nine selected canary JSONL files. Store the sorted `relative_path -> SHA256` output for
the interpreted YAML and P00-CX-022. Retain non-selected attempt hashes in a separate
`attempt_history` list.

- [ ] **Step 2: Add durable-evidence RED tests before materialization**

Tests must require all five interpreted YAML files, parse them, verify their case
IDs/statuses/raw hashes, re-hash every selected raw artifact, require nine unique canary
IDs, nine positive duration/token rows, nine `[read,yield,hub]` surfaces, one exact terminal
yield and zero forbidden calls per canary, and
the conclusion non-authority fields. Run the focused suite and confirm RED because the
interpreted files do not yet exist.

- [ ] **Step 3: Write I1-I4 with exact raw-to-field mappings**

Every case file uses these mandatory top-level keys:

```yaml
schema_version: 1
experiment: E3-I
case: I1
status: PASS
authority: characterization_only
expected: {}
observed: {}
raw_artifacts: []
source_anchors: []
non_claims: []
```

Populate only from exact selected run JSON paths:

| Case | Required observed mappings |
| --- | --- |
| I1 | Session A diagnostic 1 value; three project IDs/branches/summaries; three canary session hashes/tool surfaces/call counts |
| I2 | exact override details; Session A diagnostic 2 value; three runtime IDs/branches/summaries; before/after fixture hashes |
| I3 | Session B launch overlay attestation; diagnostic value; three CLI IDs/branches/summaries; override call count zero |
| I4 | all nine IDs/duration/tokens/model; all nine tool surfaces/call counts; both parent/live/cleanup boundary objects |

For each unknown-at-plan-time value, copy the exact machine observation; do not leave an
unresolved token or infer from prose. `non_claims` must include no OS sandbox, no universal
hub non-use, no atomic gate, no parallel authorization, and no E3-L/E3-M substitution.

- [ ] **Step 4: Write `conclusion.yml` as a strict conjunction**

PASS shape:

```yaml
schema_version: 1
experiment: E3-I
status: PASS
cases_required: [I1, I2, I3, I4]
cases_passed: [I1, I2, I3, I4]
decision: E3I_CHARACTERIZATION_PASS_NOT_PARALLEL_AUTHORITY
parallel_authorized: false
parallel_mode_after: DISABLED
e3_l_replaced: false
e3_m_replaced: false
opus_peer_review: PENDING_QUOTA
```

If provider execution is blocked or a complete contradiction fails, use that terminal
status and exact reason; never write partial PASS or reuse the PASS shape.

- [ ] **Step 5: Make the terminal manifest transition**

For PASS, change only E3-I to:

```yaml
  - id: E3-I
    kind: experiment
    state: PASS
    depends_on: [E3-A, E3-H]
    artifacts: [docs/evidence/phase-00/E3-I/I1.yml, docs/evidence/phase-00/E3-I/I2.yml, docs/evidence/phase-00/E3-I/I3.yml, docs/evidence/phase-00/E3-I/I4.yml, docs/evidence/phase-00/E3-I/conclusion.yml]
    decision: "I1-I4 characterize parent overlay divergence and canary safety; no parallel authority"
```

For `FAIL` or `BLOCKED_ENVIRONMENT`, use that state, list only the complete retained
terminal artifacts, and state the exact reason. Do not leave `RUNNING`. Do not change any
other experiment state. Assert root `parallel_mode: DISABLED` remains exact.

- [ ] **Step 6: Update the design status without rewriting its decisions**

Change the status line to the actual terminal result/date and add links/hashes for I1-I4
and conclusion. Preserve the planning amendment and review boundary. Do not rewrite a
failed observation into the expected design result.

- [ ] **Step 7: Run focused durable-evidence tests in both shells**

Expected: all E3-I tests pass for the actual terminal outcome, raw hashes match, manifest
contains no `RUNNING`, and parallel remains disabled.

---

### Task 9: Full closure verification and Opus-ready audit ledger

**Files:**

- Append: `codex-phase00-execution-changelog-for-opus5.md` as P00-CX-022
- Modify only if verification proves an E3-I-owned defect: files listed in Tasks 1-8

**Interfaces:**

- Consumes: complete E3-I terminal artifact set.
- Produces: fresh cross-shell verification checkpoint and exhaustive Opus handoff.

- [ ] **Step 1: Run every test suite separately under PowerShell 7**

```powershell
Invoke-Pester scripts/tests/phase00-wave-a.Tests.ps1 -PassThru
Invoke-Pester scripts/tests/phase00-e3j-e3k.Tests.ps1 -PassThru
Invoke-Pester scripts/tests/phase00-e3a-e3h.Tests.ps1 -PassThru
Invoke-Pester scripts/tests/phase00-e3i.Tests.ps1 -PassThru
& scripts/validate-template.ps1
```

Expected: zero failures and zero validator warnings/failures. Record exact totals.

- [ ] **Step 2: Repeat the full suite under Windows PowerShell 5.1**

Invoke the same five commands through `powershell.exe -NoProfile`. Expected: identical
meaning, zero failures, zero validator warnings/failures.

- [ ] **Step 3: Run artifact integrity and safety checks**

Verify freshly:

```text
all E3-I YAML parses
all run JSON parses
every parent/canary JSONL non-empty line parses to one object
all selected raw hash references match
no selected artifact contains a real disposable/repository/home path
no selected artifact contains credential-name/value material
no incomplete-work marker exists in the E3-I scope
no trailing whitespace exists in the E3-I scope
no omp-phase00-e3i-* temp root remains
current live-home metadata matches the final selected snapshot
Git diff check passes
branch and HEAD remain unchanged
staged file count is zero
```

- [ ] **Step 4: Append exhaustive P00-CX-022 in English**

Record:

1. P00-CX-021 predecessor hash.
2. User-approved design and planning amendment.
3. Exact source anchors and normative correction.
4. Every file created/modified/removed with before/after SHA-256 and location.
5. Every raw selected and non-selected attempt with status, reason, and SHA-256.
6. Exact I1-I4 observations and non-claims.
7. Any RED/GREEN/debugging cycle actually observed.
8. Cross-shell focused/full totals and validator totals.
9. YAML/JSON/JSONL/hash/path/secret/live-home/temp-root integrity counts.
10. Manifest before/intermediate/final states and unchanged parallel/E3-M state.
11. Branch, HEAD, dirty-entry count, zero staged files, and no Git integration.
12. Credential handling and the standing recommendation to rotate the previously exposed
    local gateway key; never include that key's value.
13. Opus challenge list: factory scoping, child tool surfaces, pairing, exact summaries,
    override non-persistence, snapshots, classification, hashes, and non-authority.

- [ ] **Step 5: Re-run the complete verification after P00-CX-022**

Documentation can break validators or integrity scans. Repeat Tasks 9.1-9.3 after the
changelog append. Only this post-documentation run supports the handoff claim.

- [ ] **Step 6: Report the self-referential final changelog hash outside the log**

Compute and report the final SHA-256 of
`codex-phase00-execution-changelog-for-opus5.md` in the user handoff. The entry pins its
immediate predecessor and every non-log artifact; the response pins the final log itself.

---

## Execution Stop Conditions

Stop the execution batch and report evidence rather than continuing when any of these is
true:

- the selected OMP executable is not exactly 17.2.10 or pinned source HEAD differs;
- a credential/auth/provider permission blocker requires new authority;
- the live OMP home changes;
- the disposable target cannot be proven safe for cleanup;
- the custom override tool appears in any canary `session_init.tools`;
- any canary omits/malforms its one terminal `yield`, or calls any other tool, especially
  `hub`;
- a parent repository snapshot changes;
- a semantic FAIL occurs in a complete attributable run;
- an INVALID_RUN lacks a regression-backed correction;
- the manifest cannot express the required terminal state without changing unrelated rows;
- a pre-existing user change overlaps an E3-I edit and cannot be preserved.

Provider quota/auth/overload/model unavailability is `BLOCKED_ENVIRONMENT`, not FAIL.
Model sequence deviation, missing provenance, timeout, or cleanup uncertainty is
`INVALID_RUN`, not `BLOCKED_ENVIRONMENT`. A complete wrong summary, wrong divergence,
override persistence, contaminated canary surface, canary tool call, or measured mutation
is `FAIL` and must not be retried into PASS.

## Plan Completion Definition

This plan is complete only when the actual terminal outcome is durably represented,
cross-shell verified, hash-linked, and recorded for Opus. A PASS additionally requires all
13 acceptance criteria from the amended design. Regardless of outcome, Phase 00 remains
in progress, E3-M remains deferred, and parallel mode remains disabled.
