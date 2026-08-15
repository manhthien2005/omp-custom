# Phase 00 E1 Schema Precedence and Provider Enforcement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a complete, reproducible E1 evidence matrix for schema dialect acceptance, caller/agent/session precedence, and strict provider-wire enforcement on pinned OMP 17.2.10, without modifying the distributable template.

**Architecture:** A PowerShell 5.1-compatible runner creates one isolated disposable environment per process, captures line-preserving event streams, sanitizes them into new repository artifacts, and derives case records through pure evidence functions. A dependency-free Node loopback forwarder records only the `yield` tool projection for the two strictness arms. A durable validator independently rechecks fixtures, hashes, raw-to-derived links, conclusions, protected surfaces, and the exact manifest transition.

**Tech Stack:** PowerShell 5.1 and 7, Pester 3.4-compatible assertions, Node.js built-ins (`http`, `crypto`, `fs`), YAML/JSONL evidence, pinned `omp/17.2.10`, OmniRoute OpenAI Responses.

## Global Constraints

- Execute Codex-only and inline in the current dirty `main` worktree, as already selected by the user. Do not create a branch, worktree, commit, staged entry, push, or pull request.
- Preserve unrelated user and historical changes. Never reset or normalize the dirty worktree.
- E1 is characterization only. Do not modify `template/.omp/**`, production agents, registry/installer contracts, or normative product specs.
- Accept only `omp/17.2.10` with SHA-256 `1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`. Installed OMP 17.2.12 is non-authoritative.
- Forbid provider calls until focused pure tests, mutation controls, validator registration, all Phase 00 tests, and both-shell validators are green.
- Execute provider processes sequentially: five ordinary probes, strict-off control, strict-on. Do not rerun automatically, mutate prompts, overwrite evidence, or parallelize. A replacement attempt after harness-caused `INVALID_RUN` requires a new offline checkpoint and explicit user authorization.
- Stop the wave on the first `FAIL`, `BLOCKED_ENVIRONMENT`, or `INVALID_RUN`. An invalid attempt has no manifest power.
- Keep unsanitized captures only in a verified disposable temp descendant. Repository evidence is sanitized, line-preserving, immutable, and hash-linked.
- Update the English Opus handoff after each task with exact paths, hashes, commands, exit codes, provider counts, limitations, and Codex-only status.
- Keep Windows PowerShell 5.1 and repository Pester syntax compatibility.
- Put `blocking: true` in every E1 fixture agent frontmatter. It is an agent policy in pinned OMP, not a caller `task` argument; prompts must not invent a `blocking` wire field.
- Leave `git diff --cached --name-only` empty at every checkpoint.
- E1 PASS may move T-00.4 only to `READY`; it must not implement T-00.4.

---

## File Responsibility Map

| Path | Responsibility | Operation | Task |
|---|---|---|---|
| `scripts/tests/phase00-e1.Tests.ps1` | Focused tests, synthetic event fixtures, mutation controls, offline forwarder/runner tests | Create | 1 |
| `scripts/lib/phase00-e1-evidence.ps1` | Definitions, sanitization, extraction, oracles, artifact writers, E1 validator | Create | 2-4 |
| `scripts/lib/phase00-e1-forwarder.mjs` | Offline projection CLI and sanitized loopback relay | Create | 5 |
| `scripts/run-phase00-e1.ps1` | Preflight, isolation, capture, derivation, cleanup | Create | 7 |
| `docs/evidence/phase-00/E1/fixture/.omp/config.yml` | Deterministic direct-task config | Create | 6 |
| `docs/evidence/phase-00/E1/fixture/agents/*.md` | Seven bounded fixture agents | Create | 6 |
| `docs/evidence/phase-00/E1/fixture/prompts/*.md` | Six exact controller prompts | Create | 6 |
| `scripts/lib/phase00-evidence.ps1` | Load the focused E1 helper | Modify narrowly | 9 |
| `scripts/validate-template.ps1` | Register the seventh Phase 00 validator | Modify narrowly | 9 |
| `scripts/tests/phase00-wave-a.Tests.ps1` | Assert validator export/entrypoint integration | Modify narrowly | 9 |
| `docs/evidence/phase-00/E1/raw/**` | Sanitized runtime evidence | Runtime-create | 11 |
| `docs/evidence/phase-00/E1/case-*.yml` | Six matrix records | Runtime-create | 11 |
| `docs/evidence/phase-00/E1/conclusion.yml` | Bounded experiment adjudication | Runtime-create | 12 |
| `docs/evidence/phase-00/manifest.yml` | Exact terminal E1/T-00.4 transition | Conditional modify | 12 |
| `codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md` | Compact Opus reconstruction ledger | Update every task | All |

## Locked Pre-State

```yaml
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
repository_worktree: dirty_before_e1
git_index_staged_paths: 0
pinned_source_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
normative_runtime_version: omp/17.2.10
normative_runtime_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
model: omniroute/codex/gpt-5.6-sol-high
api: openai-responses
gateway: http://127.0.0.1:20128/v1
manifest_before_sha256: 8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE
e1_before: READY
t_00_4_before: NOT_STARTED
parallel_mode: DISABLED
```

Protected hashes:

| Path | SHA-256 |
|---|---|
| `template/.omp/schemas/agent-result.schema.yml` | `A55B8E64DA16BB8205A6F815E9A8CD8DDE96BB8E085139435C71B785DCAE57D8` |
| `template/.omp/schemas/review-result.schema.yml` | `439D5B321739FE22792847C8D091668C58DEFC0244E8AD14A6328FE464A8182B` |
| `template/.omp/schemas/task-packet.schema.yml` | `78459082CC66C1F9320D3734B1BBA9C10F7DAA4E68EB4828B3D3879357DF2ABB` |
| `template/.omp/schemas/verification-result.schema.yml` | `2D6F05567482CAADB39E487BA7838DF24904ADFE12C66DEE180AA4B8D4DB627C` |
| `template/.omp/agents/explorer.md` | `EFF925B0CF199144F306AE8F40226F8087ECF45297B0CEB270E07C3E9DF3CAE6` |
| `template/.omp/agents/implementer.md` | `6090C229C4A6B9132B99F4540EA9788A2520BB358846C6ADC5482DD911E72A22` |
| `template/.omp/agents/reviewer.md` | `7960C0C595A2B11AD5DFDC9C9F2A591C34F5CCFC2C0ADF43D5EA70F94E3C3DE3` |
| `template/.omp/agents/tech-lead.md` | `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2` |
| `template/.omp/agents/verifier.md` | `A3F49E18266587929D05B2DE28AD59D7B31E3832C20DAD5C201AB03348C449E0` |

The five agent hashes are sourced from the authoritative T-00.3 conclusion at
`docs/evidence/phase-00/T-00.3/conclusion.yml:159-167` and were revalidated
against the current bytes before the Task 4 checkpoint. They supersede five
middle-corrupted transcription values that shared only the correct eight-character
prefix and suffix; no product file changed during that correction.

## Stable Public Interfaces

```text
Get-Phase00E1CaseDefinition -CaseId
New-Phase00E1Analysis -Status -ReasonCodes -Facts
Protect-Phase00E1EventStream -SourcePath -DestinationPath -RepositoryRoot -DisposableRoot -FixtureHashes
Get-Phase00E1StructuredResults -EventPaths
Get-Phase00E1ProviderLedger -Events
Read-Phase00E1AttemptEvidence -RepositoryRoot -CaseId -Attempt
Test-Phase00E1Attempt -CaseId -Events -RunRecord -ForwarderRecords
Test-Phase00E1ProviderStrictPair -StrictOffRun -StrictOnRun
Get-Phase00E1ExperimentOutcome -CaseRecords
New-Phase00E1CaseRecord -CaseId -AttemptEvidence -Analysis
New-Phase00E1ProviderStrictCaseRecord -StrictOffAttemptEvidence -StrictOffAnalysis -StrictOnAttemptEvidence -StrictOnAnalysis -PairAnalysis
Write-Phase00E1CaseRecord -Path -Record
Write-Phase00E1Conclusion -Path -Outcome
Test-Phase00E1ArtifactContract -RepositoryRoot
```

Runner parameters:

```text
scripts/run-phase00-e1.ps1
  -CaseId AgentJtd|AgentJsonSchema|CallerOnly|CallerOverAgent|SessionOnly|ProviderStrictOffControl|ProviderStrictOn
  -Attempt 1
  -OmpExecutable <absolute pinned executable>
  -Model omniroute/codex/gpt-5.6-sol-high
  [-AllowOverwrite]
```

Validator codes:

```text
P00-E1-READY
P00-E1-FIXTURE
P00-E1-RUNTIME
P00-E1-RAW
P00-E1-PRECEDENCE
P00-E1-SESSION
P00-E1-STRICT
P00-E1-SANITIZATION
P00-E1-CONCLUSION
P00-E1-MANIFEST
P00-E1-PROTECTED-SURFACE
```

Each case record uses ordered top-level fields:

```yaml
schema_version: 1
experiment: E1
case_id: AgentJtd
matrix_artifact: case-1-agent-jtd
status: PASS
attempt: 1
runtime: {}
inputs: {}
observations: {}
provider_ledger: {}
raw_artifacts: []
protected_surface: {}
reason_codes: []
limitations: []
```

The strict record contains separate `strict_off_control` and `strict_on` observations plus cross-arm equality checks. The conclusion contains exactly six matrix rows backed by at most seven first-wave processes.

---

## Task 1: Establish the Focused RED Contract

**Files:**

- Create: `scripts/tests/phase00-e1.Tests.ps1`
- Modify: `codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md`

- [x] Record branch, HEAD, staged count, manifest/design/protected hashes, absent planned files, installed/runtime delta, and zero provider counters.
- [x] Add a focused Pester surface test:

```powershell
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-e1-evidence.ps1'
if (Test-Path -LiteralPath $helperPath -PathType Leaf) { . $helperPath }

Describe 'Phase 00 E1 public evidence surface' {
    It 'exports every stable E1 function' {
        $names = @(
            'Get-Phase00E1CaseDefinition','New-Phase00E1Analysis',
            'Protect-Phase00E1EventStream','Get-Phase00E1StructuredResults',
            'Get-Phase00E1ProviderLedger','Test-Phase00E1Attempt',
            'Test-Phase00E1ProviderStrictPair','Get-Phase00E1ExperimentOutcome',
            'Write-Phase00E1CaseRecord','Write-Phase00E1Conclusion',
            'Test-Phase00E1ArtifactContract'
        )
        foreach ($name in $names) {
            (Get-Command $name -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        }
    }
}
```

- [x] Run RED in PowerShell 7 and Windows PowerShell 5.1. At least one assertion must fail because the stable surface is missing; import or syntax failure is not acceptable RED.
- [x] Record exact commands, totals, failure names, hashes, staged count, and zero provider calls in the Opus ledger.

## Task 2: Implement Definitions, Status Objects, and Safety Primitives

**Files:**

- Create: `scripts/lib/phase00-e1-evidence.ps1`
- Modify: `scripts/tests/phase00-e1.Tests.ps1`
- Modify: Opus ledger

- [x] Add failing tests for all seven process definitions. Assert exact execution order, matrix artifact, source, mode, prompt, agent, sentinel, provider requirement, and `PI_NO_STRICT` value.
- [x] Implement normalized analysis and definitions:

```powershell
#Requires -Version 5.1
Set-StrictMode -Version 2.0

function New-Phase00E1Analysis {
    param(
        [Parameter(Mandatory)][ValidateSet('PASS','FAIL','BLOCKED_ENVIRONMENT','INVALID_RUN')][string]$Status,
        [Parameter(Mandatory)][string[]]$ReasonCodes,
        [Parameter(Mandatory)]$Facts
    )
    [pscustomobject][ordered]@{ Status=$Status; ReasonCodes=@($ReasonCodes); Facts=$Facts }
}

function Get-Phase00E1CaseDefinition {
    param([Parameter(Mandatory)][ValidateSet(
        'AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent',
        'SessionOnly','ProviderStrictOffControl','ProviderStrictOn'
    )][string]$CaseId)
    $definitions = [ordered]@{
        AgentJtd = [ordered]@{ ExecutionOrder=1; MatrixArtifact='case-1-agent-jtd'; Source='agent'; Mode='permissive'; Agent='phase00-e1-agent-jtd'; Prompt='agent-jtd.md'; PiNoStrict=$null }
        AgentJsonSchema = [ordered]@{ ExecutionOrder=2; MatrixArtifact='case-1-agent-json-schema'; Source='agent'; Mode='permissive'; Agent='phase00-e1-agent-json-schema'; Prompt='agent-json-schema.md'; PiNoStrict=$null }
        CallerOnly = [ordered]@{ ExecutionOrder=3; MatrixArtifact='case-2-caller-only'; Source='caller'; Mode='permissive'; Agent='phase00-e1-caller-only'; Prompt='caller-only.md'; PiNoStrict=$null }
        CallerOverAgent = [ordered]@{ ExecutionOrder=4; MatrixArtifact='case-3-caller-over-agent'; Source='caller'; Mode='permissive'; Agent='phase00-e1-caller-over-agent'; Prompt='caller-over-agent.md'; PiNoStrict=$null }
        SessionOnly = [ordered]@{ ExecutionOrder=5; MatrixArtifact='case-4-session-only'; Source='session'; Mode='permissive'; Agent='phase00-e1-session-carrier'; Prompt='session-only.md'; PiNoStrict=$null }
        ProviderStrictOffControl = [ordered]@{ ExecutionOrder=6; MatrixArtifact='case-5-provider-strict'; Source='caller'; Mode='strict'; Agent='phase00-e1-provider-strict'; Prompt='provider-strict.md'; PiNoStrict='1' }
        ProviderStrictOn = [ordered]@{ ExecutionOrder=7; MatrixArtifact='case-5-provider-strict'; Source='caller'; Mode='strict'; Agent='phase00-e1-provider-strict'; Prompt='provider-strict.md'; PiNoStrict=$null }
    }
    [pscustomobject]$definitions[$CaseId]
}
```

- [x] Add exact expected sentinel/prohibited-property data and `RequiresProvider=$true` to each definition.
- [x] Add tests for unsafe cleanup targets and wrong runtime identities.
- [x] Implement strict temp-descendant and runtime identity checks:

```powershell
function Assert-Phase00E1DisposableDescendant {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$TempRoot)
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $temp = [IO.Path]::GetFullPath($TempRoot).TrimEnd('\','/')
    $prefix = $temp + [IO.Path]::DirectorySeparatorChar
    if ($full.Length -le $temp.Length -or -not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {
        throw "E1 disposable path is not a strict temp descendant: $full"
    }
    $full
}

function Test-Phase00E1OmpIdentity {
    param([Parameter(Mandatory)][string]$Sha256,[Parameter(Mandatory)][string]$Version)
    $Sha256.ToUpperInvariant() -eq '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' -and $Version.Trim() -eq 'omp/17.2.10'
}
```

- [x] Run focused GREEN in both shells and update the ledger with exact results and zero provider calls.

## Task 3: Implement Line-Preserving Sanitization

**Files:**

- Modify: `scripts/lib/phase00-e1-evidence.ps1`
- Modify: `scripts/tests/phase00-e1.Tests.ps1`
- Modify: Opus ledger

- [x] Add RED tests using a three-line JSONL fixture containing task arguments, structured output/retry metadata, secrets, paths, prompts, `thinkingSignature`, and `encrypted_content`.
- [x] Assert one parseable output object per input line; required experiment facts remain; secrets/private fields disappear; paths become typed markers; unparseable input emits one typed marker and makes the run `INVALID_RUN`; source and sanitized hashes are recorded.
- [x] Implement recursive value sanitization:

```powershell
function Protect-Phase00E1Value {
    param($Value,[string]$PropertyName,[hashtable]$Context)
    $secretKeys = @('authorization','apikey','api_key','cookie','set-cookie','thinkingsignature','encrypted_content')
    $privateKeys = @('reasoning','private_reasoning','system_prompt','messages','input')
    $key = ([string]$PropertyName).ToLowerInvariant()
    if ($key -in $secretKeys) { return [ordered]@{ redacted='secret'; field=$key } }
    if ($key -in $privateKeys) { return [ordered]@{ redacted='private_content'; field=$key } }
    if ($Value -is [string]) { return Protect-Phase00E1Text -Text $Value -Context $Context }
    if ($Value -is [Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($entryKey in $Value.Keys) {
            $copy[[string]$entryKey] = Protect-Phase00E1Value -Value $Value[$entryKey] -PropertyName ([string]$entryKey) -Context $Context
        }
        return $copy
    }
    if ($Value -is [Collections.IEnumerable] -and -not ($Value -is [string])) {
        return @($Value | ForEach-Object { Protect-Phase00E1Value -Value $_ -PropertyName $PropertyName -Context $Context })
    }
    $Value
}
```

- [x] Make `Protect-Phase00E1EventStream` stream with `[IO.File]::ReadLines`, write to a new file, and never rewrite or retain the complete source.
- [x] Run both-shell focused tests; record sample hashes, line equality, secret scan, staged count, and zero provider calls.

## Task 4: Implement Extraction, Retry Authority, and Common Oracles

**Files:**

- Modify: `scripts/lib/phase00-e1-evidence.ps1`
- Modify: `scripts/tests/phase00-e1.Tests.ps1`
- Modify: Opus ledger

- [x] Add synthetic RED cases for parent `result.details.results`, child sessions, nested leaf, duplicates, optional intent key `i`, absent versus null `outputSchema`, recovered errors, and terminal errors.
- [x] Implement canonical task arguments and property-presence checks:

```powershell
function Get-Phase00E1CanonicalTaskArguments {
    param([Parameter(Mandatory)]$Arguments)
    $copy = [ordered]@{}
    foreach ($name in @($Arguments.PSObject.Properties.Name | Sort-Object)) {
        if ($name -eq 'i') { continue }
        $copy[$name] = $Arguments.$name
    }
    [pscustomobject]$copy
}

function Test-Phase00E1PropertyPresent {
    param([Parameter(Mandatory)]$Object,[Parameter(Mandatory)][string]$Name)
    $null -ne $Object -and $Object.PSObject.Properties.Name -contains $Name
}
```

- [x] Recursively collect objects with `id`, `agent`, and `structuredOutput`, preserving origin path and one-based line. Deduplicate only by stable result identity plus origin.
- [x] Dot-source `phase00-runtime-evidence.ps1` and reuse authoritative-outcome, recovered-retry, and terminal-failure helpers. Mutation tests must prove superseded errors are recovered and unsuperseded errors are terminal.
- [x] Implement common PASS requirements: exact pins, one attributable result, valid status, expected source/mode, zero terminal failure, no retry-exhausted override, exit zero, raw hashes/anchors, cleanup success, and unchanged protected surfaces.
- [x] Run both-shell focused tests and update the ledger with zero provider calls.

## Task 5: Implement and Falsify the Sanitized Forwarder

**Files:**

- Create: `scripts/lib/phase00-e1-forwarder.mjs`
- Modify: `scripts/tests/phase00-e1.Tests.ps1`
- Modify: Opus ledger

- [x] Add offline RED tests for explicit `strict:true`, omitted strict, `strict:false`, missing yield, unrelated tools, closed/open data schemas, overwrite refusal, and secret-free output.
- [x] Implement deterministic projection:

```javascript
import { createHash } from "node:crypto";

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.keys(value).sort().map(key => [key, stable(value[key])]));
  }
  return value;
}

function sha256(value) {
  return createHash("sha256").update(JSON.stringify(stable(value)), "utf8").digest("hex").toUpperCase();
}

export function projectYieldTool(body, piNoStrictEffective) {
  const tools = Array.isArray(body?.tools) ? body.tools : [];
  const tool = tools.find(candidate => candidate?.name === "yield" || candidate?.function?.name === "yield");
  const strictPresent = Boolean(tool && Object.prototype.hasOwnProperty.call(tool, "strict"));
  const parameters = tool?.parameters ?? tool?.function?.parameters ?? null;
  const data = parameters?.properties?.data ?? null;
  return {
    gateway: "omniroute",
    api: "openai-responses",
    yield_tool_present: Boolean(tool),
    yield_strict_field_present: strictPresent,
    yield_strict: strictPresent ? tool.strict : null,
    yield_parameters_sha256: parameters === null ? null : sha256(parameters),
    allowed_data_properties: Object.keys(data?.properties ?? {}).sort(),
    required_data_properties: Array.isArray(data?.required) ? [...data.required].sort() : [],
    data_additional_properties: data?.additionalProperties ?? null,
    pi_no_strict_effective: piNoStrictEffective
  };
}
```

- [x] Add `--project-only <request> --output <ndjson> --pi-no-strict <true|false>` mode with no socket.
- [x] Add live loopback mode bound to `127.0.0.1:0`. Keep request body only in memory, persist only projection plus request index/path/forwarded/status, strip hop-by-hop headers, and relay response bytes unchanged.
- [x] Test live relay only against a disposable local fake gateway. Assert byte parity, ready/closed records, and closed port. This is not a provider call.
- [x] Run `node --check` and both-shell Pester tests; record Node version, projection hashes, port closure, secret scan, and zero provider calls.

## Task 6: Create Exact Config, Agents, and Prompts

**Files:**

- Create: `docs/evidence/phase-00/E1/fixture/.omp/config.yml`
- Create: `docs/evidence/phase-00/E1/fixture/agents/phase00-e1-agent-jtd.md`
- Create: `docs/evidence/phase-00/E1/fixture/agents/phase00-e1-agent-json-schema.md`
- Create: `docs/evidence/phase-00/E1/fixture/agents/phase00-e1-caller-only.md`
- Create: `docs/evidence/phase-00/E1/fixture/agents/phase00-e1-caller-over-agent.md`
- Create: `docs/evidence/phase-00/E1/fixture/agents/phase00-e1-session-carrier.md`
- Create: `docs/evidence/phase-00/E1/fixture/agents/phase00-e1-session-leaf.md`
- Create: `docs/evidence/phase-00/E1/fixture/agents/phase00-e1-provider-strict.md`
- Create: six files under `docs/evidence/phase-00/E1/fixture/prompts/`
- Modify: focused tests and Opus ledger

- [x] Add fixture-contract RED tests: paths, frontmatter, exact names, `blocking: true` on all seven agents, minimal tools, fixed prompt hashes, direct task mode, concurrency one, recursion two, bounded runtime, omission versus null, strict-arm byte identity.
- [x] Create deterministic config:

```yaml
plan:
  defaultOnStartup: false
async:
  enabled: false
task:
  batch: false
  enableEffort: false
  maxConcurrency: 1
  maxRecursionDepth: 2
  maxRuntimeMs: 180000
  isolation:
    mode: none
    apply: false
```

- [x] Create the JTD agent:

```yaml
---
name: phase00-e1-agent-jtd
description: E1 agent-owned JTD output probe
blocking: true
tools: read
spawns: ""
output:
  properties:
    sentinel:
      enum: [E1_AGENT_JTD]
---
```

Its body permits exactly one terminal yield: `{"sentinel":"E1_AGENT_JTD"}`.

- [x] Create the JSON Schema agent with `blocking: true` and this closed `output:`:

```yaml
output:
  type: object
  properties:
    sentinel:
      type: string
      const: E1_AGENT_JSON_SCHEMA
  required: [sentinel]
  additionalProperties: false
```

- [x] Create `phase00-e1-caller-only.md` with `blocking: true` and without any `output:` key; it yields only `E1_CALLER_ONLY`.
- [x] Create the blocking conflicting agent schema requiring only `agent_sentinel=E1_AGENT_LOSES`. Its body follows the active yield schema; the caller prompt supplies a mutually exclusive `caller_sentinel=E1_CALLER_WINS` schema.
- [x] Create a blocking carrier with `tools: task` and `spawns: phase00-e1-session-leaf`. Its sole nested call names the blocking leaf, passes the exact session-sentinel assignment and permissive mode, and omits `outputSchema`. The leaf has no `output:` key.
- [x] Create the blocking strict agent and one shared strict prompt. The prompt requires the first terminal yield to be `{"allowed":"E1_STRICT_FORBIDDEN","forbidden_extra":"E1_FORBIDDEN_EXTRA"}`, then exactly one correction to `{"allowed":"E1_STRICT_ALLOWED"}` only after a tool schema error.
- [x] Create six controller prompts. Each requires exactly one flat `task` call, the named agent, exact wire arguments, deterministic final marker, and no eval. No prompt may send a `blocking` field because blocking is selected by agent frontmatter. Agent-owned prompts explicitly forbid the `outputSchema` property.
- [x] Use these exact caller schemas:

```json
{"type":"object","properties":{"sentinel":{"type":"string","const":"E1_CALLER_ONLY"}},"required":["sentinel"],"additionalProperties":false}
{"type":"object","properties":{"caller_sentinel":{"type":"string","const":"E1_CALLER_WINS"}},"required":["caller_sentinel"],"additionalProperties":false}
{"type":"object","properties":{"session_sentinel":{"type":"string","const":"E1_SESSION_ONLY"}},"required":["session_sentinel"],"additionalProperties":false}
{"type":"object","properties":{"allowed":{"type":"string","const":"E1_STRICT_ALLOWED"}},"required":["allowed"],"additionalProperties":false}
```

- [x] Run fixture tests in both shells. Record every fixture hash and zero provider calls.

## Task 7: Implement Runner Preflight, Capture, and Cleanup

**Files:**

- Create: `scripts/run-phase00-e1.ps1`
- Modify: evidence helper, focused tests, Opus ledger

- [x] Add runner RED tests for missing executable, wrong hash/version, existing destination, unsafe cleanup roots, timeout termination, concurrent streams, strict environment isolation, protected-home delta, disposable model selection, `--tools task`, and non-repository cwd.
- [x] Implement exact runner parameters:

```powershell
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
    [string]$CaseId,
    [ValidateRange(1,999)][int]$Attempt = 1,
    [Parameter(Mandatory)][string]$OmpExecutable,
    [string]$Model = 'omniroute/codex/gpt-5.6-sol-high',
    [switch]$AllowOverwrite
)
Set-StrictMode -Version 2.0
```

- [x] Resolve an absolute executable, hash it, invoke only `--version` for identity, and reject mismatches before fixture creation.
- [x] Create a GUID root strictly beneath the OS temp directory with `agent-home`, `project/.omp/agents`, `sessions`, `capture`, and `runtime`. Copy and rehash the pinned executable. Copy only E1 fixtures and a sanitized runtime-model catalog.
- [x] Set process-local `PI_CODING_AGENT_DIR` and prepend the verified runtime directory to process-local PATH. Never inherit `PI_NO_STRICT` into strict-on; set it to `1` only for strict-off.
- [x] Build the OMP arguments exactly:

```powershell
$arguments = @(
    '-p','--mode','json',
    '--cwd',$disposableProject,
    '--session-dir',$sessionDirectory,
    '--config',$disposableConfig,
    '--model',$Model,
    '--tools','task',
    '--approval-mode','yolo',
    '--max-time','8m',
    '--no-extensions','--no-skills','--no-rules','--no-lsp','--no-title',
    $promptText
)
```

- [x] Drain stdout and stderr asynchronously to avoid deadlock:

```powershell
$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
    try { $process.Kill() } catch {}
    $timedOut = $true
}
$stdout = $stdoutTask.GetAwaiter().GetResult()
$stderr = $stderrTask.GetAwaiter().GetResult()
```

- [x] Snapshot the nine protected repository files and bounded live-agent-home surfaces before/after. A delta is `INVALID_RUN`.
- [x] Sanitize to new repository files, reparse every output line, verify hashes, scan secrets, then remove only the validated temp root. Record cleanup and remaining child PIDs.
- [x] Run runner-safety tests in both shells. Prompt-bearing OMP execution remains forbidden; provider counters remain zero.

## Task 8: Implement Case-Specific and Experiment Oracles

**Files:**

- Modify: evidence helper, focused tests, Opus ledger

- [x] Add ordinary-case RED tests:
  - Agent JTD: caller schema absent, source agent, sentinel only.
  - Agent JSON Schema: caller schema absent, source agent, sentinel only.
  - Caller only: agent schema absent, caller present, source caller, override fact where observable.
  - Caller-over-agent: caller-only sentinel present, agent sentinel absent, caller schema in child initialization.
  - Session only: outer caller result is setup only; nested leaf has no caller schema, source session, session sentinel.
- [x] Require the attributable agent definition/setup facts to show blocking execution for every direct and nested probe; reject an async job acknowledgement as a case result.
- [x] Implement `Test-Phase00E1Attempt` as a pure dispatcher returning `New-Phase00E1Analysis`.
- [x] Add strict-off tests and implementation. PASS requires omitted wire strict field with `PI_NO_STRICT=1`, first prohibited terminal yield, exactly one local rejection, next valid yield, no override, caller/strict/valid result, and attributable gateway response. A valid first attempt is `INVALID_RUN/E1_STRICT_CONTROL_NOT_EXERCISED`.
- [x] Add strict-on tests and implementation. PASS requires absent `PI_NO_STRICT`, explicit `yield.strict=true`, closed data schema, first-attempt conformance, no prohibited argument/final field, no local validation retry/override, caller/strict/valid result, and gateway response.
- [x] Add cross-arm equality checks for prompt, assignment, schema, agent, model, runtime, and gateway. Only `PI_NO_STRICT` and expected behavioral consequences may differ.
- [x] Implement exact experiment adjudication:

```powershell
function Get-Phase00E1ExperimentOutcome {
    param([Parameter(Mandatory)][object[]]$CaseRecords)
    if (@($CaseRecords).Count -ne 6) {
        return New-Phase00E1Analysis -Status INVALID_RUN -ReasonCodes @('E1_MATRIX_INCOMPLETE') -Facts ([ordered]@{ count=@($CaseRecords).Count })
    }
    if (@($CaseRecords | Where-Object status -eq 'FAIL').Count -gt 0) {
        return New-Phase00E1Analysis -Status FAIL -ReasonCodes @('E1_COMPLETE_CASE_CONTRADICTION') -Facts $CaseRecords
    }
    if (@($CaseRecords | Where-Object status -eq 'BLOCKED_ENVIRONMENT').Count -gt 0) {
        return New-Phase00E1Analysis -Status BLOCKED_ENVIRONMENT -ReasonCodes @('E1_REQUIRED_CAPABILITY_UNAVAILABLE') -Facts $CaseRecords
    }
    if (@($CaseRecords | Where-Object status -ne 'PASS').Count -gt 0) {
        return New-Phase00E1Analysis -Status INVALID_RUN -ReasonCodes @('E1_MATRIX_NONTERMINAL') -Facts $CaseRecords
    }
    New-Phase00E1Analysis -Status PASS -ReasonCodes @('E1_ALL_SIX_CASES_PASS') -Facts $CaseRecords
}
```

- [x] Run mutation controls for swapped sources, explicit null, dual sentinels, carrier substitution, nested caller schema, wrong strict flags, hidden forbidden data, hidden retry/override, recovered/terminal inversion, missing raw/hash/anchor, runtime 17.2.12, protected mutation, and incomplete matrix.
- [x] Run both-shell focused tests and record named controls with zero provider calls.

## Task 9: Register Durable Validation and READY-State Compatibility

**Files:**

- Modify: `scripts/lib/phase00-evidence.ps1`
- Modify: `scripts/validate-template.ps1`
- Modify: `scripts/tests/phase00-wave-a.Tests.ps1`
- Modify: focused tests and Opus ledger

- [x] Add integration RED: change six validators to seven, require exported `Test-Phase00E1ArtifactContract` and validator output `P00-E1-READY`.
- [x] Load the focused helper conditionally from `phase00-evidence.ps1`:

```powershell
$phase00E1HelperPath = Join-Path $PSScriptRoot 'phase00-e1-evidence.ps1'
if (Test-Path -LiteralPath $phase00E1HelperPath -PathType Leaf) {
    . $phase00E1HelperPath
}
```

- [x] Insert `Test-Phase00E1ArtifactContract` after the manifest validator in `validate-template.ps1`.
- [x] Implement READY validation: T-00.4 stays NOT_STARTED; no terminal conclusion; static E1 surface and protected hashes are valid; partial invalid history cannot claim terminal authority.
- [x] Preserve legacy copied test fixtures that intentionally contain only `phase00-evidence.ps1`; E1-specific fixtures copy both helpers.
- [x] Run Wave A, all Phase 00 tests, and full validator in both shells. Baseline before E1 was 227/227 tests and 93 validator passes plus one advisory warning; explain the exact new test delta.
- [x] Record hashes/anchors, exact outputs, warnings, protected hashes, staged zero, and provider zero.

## Task 10: Freeze the Offline Provider Gate

**Files:**

- Modify E1-owned files only if a focused failure proves a defect
- Modify: Opus ledger

- [x] Add RED/GREEN filesystem projections from immutable run envelopes and persisted-session JSONL into the exact normalized attempt-evidence shape consumed by the pure oracle. Prove repository containment, artifact hash/line binding, controller/child separation, semantic result attribution, nested-leaf selection, persisted provider retry precedence, strict yield attempts, and yield-bearing forwarder filtering without renumbering raw request indexes.
- [x] Add deterministic RED/GREEN case-record derivation so Task 11 never relies on ad-hoc manual interpretation before `Write-Phase00E1CaseRecord`.
- [x] Parse every changed PowerShell file in both shells; run `node --check`; validate fixture frontmatter/YAML; scan E1-owned files for unfinished markers.
- [x] Run focused E1 tests twice consecutively in both shells to detect leaked ports/temp state and ordering assumptions.
- [x] Run all Phase 00 tests and validators again in clean processes in both shells.
- [x] Confirm manifest hash remains `8E1A4AF2A80E9D77F741997B2614852DB236B26C70FFA7A7269EDB5AAE22E7CE`, all protected hashes match, staged paths are zero, provider raw evidence is absent, and provider counters are zero.
- [x] Record every implementation/fixture hash as checkpoint `E1-OFFLINE-GREEN-002`. The provisional `E1-OFFLINE-GREEN-001` checkpoint is superseded because it lacked a production raw-to-oracle bridge. `E1-OFFLINE-GREEN-002` authorizes only the sequential live wave and is not E1 PASS.

## Task 10A: Stop-Gate Diagnosis and Harness Remediation After AgentJtd Attempt 1

**Files:**

- Modify: `scripts/lib/phase00-e1-evidence.ps1`
- Modify: `scripts/tests/phase00-e1.Tests.ps1`
- Modify: this plan and the Opus ledger
- Preserve byte-for-byte: `docs/evidence/phase-00/E1/raw/agent-jtd/attempt-001*`

- [x] Execute only the authorized `AgentJtd` attempt 1 after its complete preflight. Record one OMP provider process and nine actual provider requests.
- [x] Classify the attempt `INVALID_RUN`, stop before `AgentJsonSchema`, create no case record, and leave the manifest unchanged.
- [x] Preserve all five sanitized attempt artifacts byte-for-byte and record their exact hashes, sizes, and line counts.
- [x] Prove from pinned upstream source that each blocking child writes sibling `${id}.jsonl` and `${id}.md` artifacts; accept only that exact `.md` pairing while keeping orphan markdown, patch, text, and reparse-point artifacts invalid.
- [x] Reproduce the sanitizer failure with valid file-read JSON. Establish that numeric `displayContent.lineNumbers` values entered the overly broad `[pscustomobject]` branch under StrictMode and threw `PropertyNotFoundException`; the old combined catch then mislabeled the processing failure as unparseable JSON.
- [x] Add RED/GREEN regressions for expected child output inventory, numeric scalars, duplicate file content in `displayContent` and `truncation.content`, parse-versus-processing error separation, processing-error metadata validation, and valid JSON objects with case-colliding keys in PowerShell 7 and 5.1.
- [x] Implement the narrow remediation without modifying the fixture, product/template, manifest, runner entrypoint, forwarder, pinned runtime, pinned source, or immutable Attempt 1 bytes.
- [x] Re-run the complete offline gate and freeze `E1-OFFLINE-GREEN-003`; this authorizes no provider process by itself.
- [ ] Obtain explicit user authorization before `AgentJtd` attempt 2. Do not infer authorization from the earlier first-wave approval.

## Task 11: Execute Provider Processes Sequentially

**Files:**

- Runtime-create: `docs/evidence/phase-00/E1/raw/**`
- Runtime-create: six case records
- Modify: Opus ledger after every process

- [ ] Before each process, verify prior PASS, pinned identity, frozen offline hashes, gateway reachability, absent destination, unchanged manifest/protected files, and staged zero. Failed preflight creates no attempt.
- [x] Run `AgentJtd` attempt 1; result `INVALID_RUN` from two harness defects. Preserve it as non-authoritative history and do not derive a case record.
- [ ] Run `AgentJtd` attempt 2 only after `E1-OFFLINE-GREEN-003` and explicit user authorization; continue only on PASS.
- [ ] Run `AgentJsonSchema` attempt 1; continue only on PASS.
- [ ] Run `CallerOnly` attempt 1; continue only on PASS.
- [ ] Run `CallerOverAgent` attempt 1; continue only on PASS.
- [ ] Run `SessionOnly` attempt 1; prove the nested leaf, not carrier, is the session observation. Continue only on PASS.
- [ ] Run `ProviderStrictOffControl` attempt 1 through the forwarder with process-local `PI_NO_STRICT=1`. Stop without rerun if the discriminator was not exercised.
- [ ] Run `ProviderStrictOn` attempt 1 only after strict-off PASS, with `PI_NO_STRICT` absent.
- [ ] Derive `case-5-provider-strict.yml` only after both arms complete and cross-arm hashes match.
- [x] Append the complete immutable Attempt 1 process/request/retry, raw-hash, cleanup, protected-surface, diagnosis, and remediation ledger.
- [ ] After every process, append process/request/retry counts, recovered/terminal chain, source/mode/status, sentinel facts, raw paths/hashes, cleanup, and protected checks to the ledger.
- [x] At the first non-PASS, do not invoke the next process, overwrite evidence, use attempt 2, or mutate the manifest. Record the exact next authorized action.

The pinned command form is:

```powershell
pwsh -NoProfile -File scripts/run-phase00-e1.ps1 -CaseId AgentJtd -Attempt 1 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak' -Model 'omniroute/codex/gpt-5.6-sol-high'
```

That command is historical and must not be repeated. If and only if the user grants
new authorization after `E1-OFFLINE-GREEN-003`, the replacement command changes only
`-Attempt 1` to `-Attempt 2`; it must still pass a fresh preflight and cannot overwrite
Attempt 1.

## Task 12: Derive Conclusion and Apply the Exact Manifest Transition

**Files:**

- Create: `docs/evidence/phase-00/E1/conclusion.yml`
- Conditional modify: `docs/evidence/phase-00/manifest.yml`
- Modify: focused tests and Opus ledger

- [ ] Test all adjudication branches:

| Evidence | E1 state | T-00.4 state |
|---|---|---|
| Six rows PASS, strict row has two PASS arms | PASS | READY |
| Any complete attributable case FAIL | FAIL | NOT_STARTED |
| Conclusive required capability unavailable | BLOCKED_ENVIRONMENT | NOT_STARTED |
| Incomplete or invalid evidence | retain READY | NOT_STARTED |

- [ ] Generate conclusion only from records. A PASS conclusion must state:

```yaml
open_question_a: BOTH_ACCEPTED
canonical_t_00_4_agent_output_dialect: JTD
precedence:
  order: [caller, agent, session]
provider_enforcement:
  boundary: OMP_17_2_10_TO_OMNIROUTE_OPENAI_RESPONSES
  strict_on_observed: true
  strict_off_control_exercised: true
upstream_provider_claim: none
spec_effect: CHANGE
t_00_4_effect: READY_ONLY
joint_closure: false
```

- [ ] Include six records, every provider process attempt including immutable invalid history, every raw hash, dialect/precedence results, provider/model boundary, request/retry counts, limitations, and exact future downstream files.
- [ ] Validate a temporary manifest projection before touching the real manifest.
- [ ] For PASS only: E1 READY to PASS; attach six case records plus conclusion; set a bounded decision; T-00.4 NOT_STARTED to READY. Do not change dependencies or start T-00.4.
- [ ] For terminal FAIL/BLOCKED, update only E1 and keep T-00.4 NOT_STARTED. For incomplete/invalid evidence, do not change the manifest.
- [ ] Prove 29 IDs/dependencies remain; all non-E1/T-00.4 entries are byte-identical; T-00.5/T-00.6/T-00.7 unchanged; only adjudication-authorized fields differ.
- [ ] Run focused tests in both shells and record the new manifest hash or explicit no-transition reason.

## Task 13: Final Verification and Opus Peer-Review Handoff

**Files:**

- Modify: Opus ledger
- Modify: this plan only to mark checkboxes and final identities

- [ ] Invoke the `superpowers:verification-before-completion` skill before any completion claim.
- [ ] Run focused E1 tests in both shells and record exact totals/exit codes.
- [ ] Run all Phase 00 tests in both shells and record exact totals/exit codes.
- [ ] Run the full validator in both shells and record pass/warn/fail counts and warning codes.
- [ ] Recompute every case/conclusion/raw hash; validate references, lines, anchors, sanitization, request-projection scope, deleted temp captures, closed ports, and no remaining child processes.
- [ ] Recheck all nine protected hashes, pinned source commit/cleanliness, branch/HEAD, staged zero, and preservation of unrelated dirty paths.
- [ ] Finalize the English handoff with verdict, `joint_closure:false`, changed-file table, before/after hashes and anchors, decisions, tests, seven-process ledger, evidence index, manifest effect, protected proof, limitations, Opus reading order, and an optimized review prompt.
- [ ] Do not embed raw transcripts; cite paths, hashes, and event lines.
- [ ] Confirm every design requirement maps to a test and implementation step, stable names/statuses agree, provider claims are bounded, and T-00.4 has not started.

---

## Required Verification Commands

Focused E1:

```powershell
pwsh -NoProfile -Command '$r=Invoke-Pester -Script scripts/tests/phase00-e1.Tests.ps1 -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '$r=Invoke-Pester -Script scripts/tests/phase00-e1.Tests.ps1 -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
```

All Phase 00:

```powershell
pwsh -NoProfile -Command '$files=Get-ChildItem -LiteralPath scripts/tests -Filter "phase00*.Tests.ps1" | Sort-Object Name | Select-Object -ExpandProperty FullName; $r=Invoke-Pester -Script $files -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '$files=Get-ChildItem -LiteralPath scripts/tests -Filter "phase00*.Tests.ps1" | Sort-Object Name | Select-Object -ExpandProperty FullName; $r=Invoke-Pester -Script $files -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
```

Full validator:

```powershell
pwsh -NoProfile -File scripts/validate-template.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate-template.ps1
```

## Design-to-Plan Coverage

| Approved requirement | Tasks | Falsification |
|---|---|---|
| Pinned authority | 2, 7 | wrong hash/version |
| No product mutation | Global, 7, 13 | nine protected hashes |
| Independent capture-first cases | 6, 7, 11 | per-case destinations/records |
| Caller > agent > session | 6, 8, 11 | swapped source, dual sentinel |
| Absence differs from null | 4, 6, 8 | explicit-null mutation |
| Nested leaf is session oracle | 6, 8, 11 | carrier substitution |
| Blocking result attribution | 6, 8, 11 | async acknowledgement substitution |
| Both frontmatter dialects | 6, 8, 11, 12 | two sentinel probes |
| Provider strict proof | 5, 8, 11 | strict false/omitted, forbidden data |
| Strict-off causal control | 5, 6, 8, 11 | valid-first becomes invalid run |
| Sanitized raw evidence | 3, 7, 13 | line/hash/secret checks |
| Retry supersession | 4, 8 | recovered/terminal inversion |
| Safe cleanup | 2, 5, 7, 13 | root/sibling/port/process checks |
| Offline gate before provider | 1-10 | zero-call ledger |
| Sequential bounded wave | 11 | prior-PASS stop rule |
| Exact state vocabulary | 2, 8, 12 | four adjudication branches |
| Unlock only T-00.4 READY | 12, 13 | exact manifest delta |
| Full Opus reconstruction | Every task, 13 | hashes, anchors, commands, ledger |

## Execution Mode

The user already selected Codex-only inline execution in the current dirty worktree. The subagent-driven option named in the mandatory plan header is therefore intentionally not selected. Execute task-by-task with `superpowers:executing-plans`, RED/GREEN gates, hash checkpoints instead of commits, and no provider call before Task 10 is fully green.
