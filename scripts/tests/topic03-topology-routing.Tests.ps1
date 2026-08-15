#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic03-topology-routing.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    Write-Host 'FAIL [T03-TEST-HELPER] focused Topic 03 validator helper is missing' -ForegroundColor Red
    exit 1
}
. $helperPath

$script:assertions = 0

function Set-Topic03FixtureFile {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $path = Join-Path $Root $RelativePath
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
}

function New-Topic03GoodFixture {
    param([Parameter(Mandatory)][string]$Root)

    Set-Topic03FixtureFile -Root $Root -RelativePath 'docs/superpowers/specs/2026-08-12-topic-03-agent-topology-model-routing-design.md' -Content @'
# Topic 03 Design
The selected runtime manifest has three logical agents: Cheap Scout, Worker, Reviewer.
Cheap Scout uses DeepSeek V4 Flash at `max`, then V4 Pro at `max`, then Tech Lead retrieval.
Worker uses `high` for moderate tasks and Tech Lead-selected `xhigh` for hard tasks.
Reviewer always uses `xhigh`.
Opus is never implicitly mandatory.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'spec/03-agent-topology.md' -Content @'
# Agent topology
The main-session Tech Lead is the default writer and final owner.
Default to no subagent spawn.
Every spawn requires a concrete benefit, bounded contract, output, stop condition, and fallback.
The selected spawnable manifest is exactly cheap-scout, worker, and reviewer.
Reviewer is mandatory for security, authentication, durable data, database migration, concurrency, public API, and destructive change concerns.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'spec/09-model-routing.md' -Content @'
# Model routing
Cheap Scout primary is omniroute/ds/deepseek-v4-flash:xhigh.
Cheap Scout availability fallback is omniroute/ds/deepseek-v4-pro:xhigh, then Tech Lead retrieval.
Worker defaults to high and may use xhigh for hard tasks selected by the Tech Lead.
Reviewer is fixed at xhigh.
Opus is a preference, not a gate; an available suitable strong model or a same-model separate session with disclosure is valid.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'spec/key/04-decision-log.md' -Content @'
## KD-027 — Benefit-gated three-agent topology and explicit model routing
The selected manifest is Cheap Scout, Worker, Reviewer; Tech Lead remains the main session.
Flash max falls back to Pro max only for availability, then Tech Lead retrieves inline.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'spec/phases/phase-02-core-orchestration.md' -Content @'
Topic 03 selects exactly cheap-scout, worker, reviewer. Spawn only after the benefit gate passes.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'spec/phases/phase-06-evaluation.md' -Content @'
Discover exactly the selected three-agent manifest and validate Scout xhigh, Worker high or xhigh, and Reviewer xhigh.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'template/.omp/agents/cheap-scout.md' -Content @'
---
name: cheap-scout
model: "@cheap-scout"
tools: read, grep, glob, web_search
spawns: ""
thinking-level: xhigh
read-summarize: false
---
Read-only advisory retrieval. Never edit, verify acceptance, review, integrate, or issue a verdict.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'template/.omp/agents/worker.md' -Content @'
---
name: worker
model: "@worker"
tools: read, grep, glob, edit, write, bash
spawns: ""
thinking-level: high
---
Implement one bounded work unit and return evidence.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'template/.omp/agents/reviewer.md' -Content @'
---
name: reviewer
model: "@reviewer"
tools: read, grep, glob, bash
spawns: ""
thinking-level: xhigh
read-summarize: false
---
General Reviewer. Review is mandatory for security, authentication, durable data, database migration, concurrency, public API, and destructive change concerns.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'template/.omp/AGENTS.md' -Content @'
The main-session Tech Lead is the default writer and final owner.
Default to no subagent spawn. Spawn only after naming a concrete benefit, contract, output, stop condition, and fallback.
Opus is a preference, not a gate. Use another suitable strong model or a same-model separate session with disclosure.
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'template/.omp/commands/quick.md' -Content 'Complete inline by default; spawn only for a stated concrete benefit.'
    Set-Topic03FixtureFile -Root $Root -RelativePath 'template/.omp/commands/standard.md' -Content 'Tech Lead selects Scout, Worker, or Reviewer only when the task contract benefits.'
    Set-Topic03FixtureFile -Root $Root -RelativePath 'template/.omp/commands/orchestrated.md' -Content 'Use dependency-aware bounded work; no fixed agent chain is required.'

    Set-Topic03FixtureFile -Root $Root -RelativePath 'template/.omp/config.yml' -Content @'
modelRoles:
  cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh
  worker: omniroute/codex/gpt-5.6-sol:high
  reviewer: omniroute/codex/gpt-5.6-sol:xhigh
retry:
  modelFallback: true
  usageAwareFallback: false
  fallbackChains:
    default: []
    cheap-scout:
      - omniroute/ds/deepseek-v4-pro:xhigh
    worker: []
    reviewer: []
task:
  enableEffort: true
  maxEffort: xhigh
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'scripts/install-template.ps1' -Content @'
$retiredAgentNames = @('explorer.md', 'implementer.md', 'tech-lead.md', 'verifier.md')
# Retirement happens only after the target backup succeeds.
foreach ($retiredAgentName in $retiredAgentNames) {
    $retiredAgentPath = Join-Path (Join-Path $dest_omp 'agents') $retiredAgentName
    if (Test-Path -LiteralPath $retiredAgentPath) {
        Remove-Item -LiteralPath $retiredAgentPath -Force
    }
}
'@

    Set-Topic03FixtureFile -Root $Root -RelativePath 'docs/evidence/current-product/topic-03/manifest.yml' -Content @'
{
  "schema_version": 1,
  "topic": "03",
  "candidate": "C1",
  "phase00_source": "T-00.3",
  "phase00_conclusion_sha256": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  "superseded_agents": [],
  "selected_agents": ["cheap-scout", "worker", "reviewer"],
  "current_files": [],
  "deepseek_environment": "ENVIRONMENT_BLOCKED"
}
'@
}

function Assert-NoFailures {
    param([Parameter(Mandatory)][object[]]$Results, [Parameter(Mandatory)][string]$Scenario)
    $script:assertions++
    $failures = @($Results | Where-Object Status -eq 'FAIL')
    if ($failures.Count -ne 0) {
        throw "[$Scenario] expected zero failures, got: $($failures.Code -join ', ')"
    }
}

function Assert-OnlyFailureCode {
    param(
        [Parameter(Mandatory)][object[]]$Results,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Scenario
    )
    $script:assertions++
    $failures = @($Results | Where-Object Status -eq 'FAIL')
    if ($failures.Count -ne 1 -or $failures[0].Code -ne $Code) {
        throw "[$Scenario] expected only FAIL '$Code', got: $($failures.Code -join ', ')"
    }
}

function Invoke-Topic03Mutation {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ExpectedCode,
        [Parameter(Mandatory)][scriptblock]$Mutate
    )

    $root = Join-Path ([IO.Path]::GetTempPath()) ("omp-topic03-{0}-{1}" -f $Name, [guid]::NewGuid().ToString('N'))
    try {
        [void](New-Item -ItemType Directory -Path $root -Force)
        New-Topic03GoodFixture -Root $root
        & $Mutate $root
        $results = @(Test-Topic03TopologyRoutingContract -RepositoryRoot $root)
        Assert-OnlyFailureCode -Results $results -Code $ExpectedCode -Scenario $Name
    } finally {
        if (Test-Path -LiteralPath $root -PathType Container) {
            Remove-Item -LiteralPath $root -Recurse -Force
        }
    }
}

$goodRoot = Join-Path ([IO.Path]::GetTempPath()) ("omp-topic03-good-{0}" -f [guid]::NewGuid().ToString('N'))
try {
    [void](New-Item -ItemType Directory -Path $goodRoot -Force)
    New-Topic03GoodFixture -Root $goodRoot
    Assert-NoFailures -Results @(Test-Topic03TopologyRoutingContract -RepositoryRoot $goodRoot) -Scenario 'complete good fixture'
} finally {
    if (Test-Path -LiteralPath $goodRoot -PathType Container) {
        Remove-Item -LiteralPath $goodRoot -Recurse -Force
    }
}

Invoke-Topic03Mutation -Name 'old-agent' -ExpectedCode 'T03-MANIFEST-OLD-AGENT' -Mutate {
    param($root)
    Set-Topic03FixtureFile -Root $root -RelativePath 'template/.omp/agents/explorer.md' -Content 'old agent'
}
Invoke-Topic03Mutation -Name 'scout-missing' -ExpectedCode 'T03-MANIFEST-SCOUT-MISSING' -Mutate {
    param($root)
    Remove-Item -LiteralPath (Join-Path $root 'template/.omp/agents/cheap-scout.md')
}
Invoke-Topic03Mutation -Name 'scout-write-tool' -ExpectedCode 'T03-SCOUT-WRITE-TOOL' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/agents/cheap-scout.md'
    (Get-Content -Raw $path).Replace('tools: read, grep, glob, web_search', 'tools: read, grep, glob, web_search, edit') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'scout-effort' -ExpectedCode 'T03-SCOUT-EFFORT' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/agents/cheap-scout.md'
    (Get-Content -Raw $path).Replace('thinking-level: xhigh', 'thinking-level: high') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'worker-effort' -ExpectedCode 'T03-WORKER-DEFAULT-EFFORT' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/agents/worker.md'
    (Get-Content -Raw $path).Replace('thinking-level: high', 'thinking-level: medium') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'reviewer-effort' -ExpectedCode 'T03-REVIEWER-EFFORT' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/agents/reviewer.md'
    (Get-Content -Raw $path).Replace('thinking-level: xhigh', 'thinking-level: high') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'techlead-spawnable' -ExpectedCode 'T03-TECHLEAD-SPAWNABLE' -Mutate {
    param($root)
    Set-Topic03FixtureFile -Root $root -RelativePath 'template/.omp/agents/tech-lead.md' -Content 'spawnable Tech Lead'
}
Invoke-Topic03Mutation -Name 'benefit-gate' -ExpectedCode 'T03-SPAWN-BENEFIT-GATE' -Mutate {
    param($root)
    $path = Join-Path $root 'spec/03-agent-topology.md'
    (Get-Content -Raw $path).Replace("Default to no subagent spawn.`r`n", '').Replace("Default to no subagent spawn.`n", '') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'review-risk' -ExpectedCode 'T03-REVIEW-RISK-GATE' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/agents/reviewer.md'
    (Get-Content -Raw $path).Replace('Review is mandatory for security, authentication, durable data, database migration, concurrency, public API, and destructive change concerns.', 'Review is optional.') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'opus-mandatory' -ExpectedCode 'T03-OPUS-MANDATORY' -Mutate {
    param($root)
    Add-Content -LiteralPath (Join-Path $root 'template/.omp/AGENTS.md') -Value 'Unavailable Opus blocks all review.'
}
Invoke-Topic03Mutation -Name 'scout-primary' -ExpectedCode 'T03-CONFIG-SCOUT-PRIMARY' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/config.yml'
    (Get-Content -Raw $path).Replace('omniroute/ds/deepseek-v4-flash:xhigh', 'omniroute/codex/gpt-5.6-sol') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'scout-fallback' -ExpectedCode 'T03-CONFIG-SCOUT-FALLBACK' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/config.yml'
    (Get-Content -Raw $path).Replace('      - omniroute/ds/deepseek-v4-pro:xhigh', '      []') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'worker-observable-effort' -ExpectedCode 'T03-CONFIG-WORKER-IDENTITY' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/config.yml'
    (Get-Content -Raw $path).Replace('worker: omniroute/codex/gpt-5.6-sol:high', 'worker: omniroute/codex/gpt-5.6-sol') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'reviewer-observable-effort' -ExpectedCode 'T03-CONFIG-REVIEWER-IDENTITY' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/config.yml'
    (Get-Content -Raw $path).Replace('reviewer: omniroute/codex/gpt-5.6-sol:xhigh', 'reviewer: omniroute/codex/gpt-5.6-sol:high') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'default-fallback' -ExpectedCode 'T03-CONFIG-DEFAULT-FALLBACK' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/config.yml'
    (Get-Content -Raw $path).Replace('    worker: []', "    worker:`n      - omniroute/ds/deepseek-v4-pro:xhigh") | Set-Content $path
}
Invoke-Topic03Mutation -Name 'effort-setting' -ExpectedCode 'T03-CONFIG-EFFORT' -Mutate {
    param($root)
    $path = Join-Path $root 'template/.omp/config.yml'
    (Get-Content -Raw $path).Replace('  enableEffort: true', '  enableEffort: false') | Set-Content $path
}
Invoke-Topic03Mutation -Name 'fixed-chain' -ExpectedCode 'T03-COMMAND-FIXED-CHAIN' -Mutate {
    param($root)
    Add-Content -LiteralPath (Join-Path $root 'template/.omp/commands/orchestrated.md') -Value 'Explorer -> Implementer -> Verifier'
}
Invoke-Topic03Mutation -Name 'stale-retirement' -ExpectedCode 'T03-INSTALL-STALE-AGENT' -Mutate {
    param($root)
    $path = Join-Path $root 'scripts/install-template.ps1'
    (Get-Content -Raw $path).Replace("'verifier.md'", "'retired.md'") | Set-Content $path
}
Invoke-Topic03Mutation -Name 'evidence-supersession' -ExpectedCode 'T03-EVIDENCE-SUPERSESSION' -Mutate {
    param($root)
    $path = Join-Path $root 'docs/evidence/current-product/topic-03/manifest.yml'
    (Get-Content -Raw $path).Replace('"phase00_source": "T-00.3"', '"phase00_source": "T-00.2"') | Set-Content $path
}

Write-Host "PASS Topic 03 topology/routing mutation tests ($script:assertions assertions)" -ForegroundColor Green
exit 0
