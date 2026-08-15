#Requires -Version 5.1
<#
.SYNOPSIS
    Static validation for the OMP workflow template.
.DESCRIPTION
    Checks required files exist, token budgets are in range, no constitutional
    phrases are duplicated into agent files, and YAML files are non-empty.
    Exit code: 0 = all passed, 1 = one or more failures.
.PARAMETER Verbose
    Print each check result as it runs.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
$script:passed   = 0
$script:failed   = 0
$script:warnings = 0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Pass([string]$msg) {
    $script:passed++
    Write-Verbose "  PASS  $msg"
}

function Write-Fail([string]$msg) {
    $script:failed++
    Write-Host "  FAIL  $msg" -ForegroundColor Red
}

function Write-Warn([string]$msg) {
    $script:warnings++
    Write-Host "  WARN  $msg" -ForegroundColor Yellow
}

function Get-ApproxTokens([string]$path) {
    $content = Get-Content -Raw -Path $path -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return 0 }
    # Approximate: chars / 4 (GPT-style rough estimate)
    return [int]($content.Length / 4)
}

function Test-RequiredFile([string]$rel) {
    $full = Join-Path $PSScriptRoot "..\$rel"
    if (Test-Path $full) {
        Write-Pass "exists: $rel"
    } else {
        Write-Fail "missing: $rel"
    }
}

# Advisory approximation with explicit target minimum, target maximum, and hard warning.
function Test-ApproxTokenBudget(
    [string]$rel,
    [int]$targetMin,
    [int]$targetMax,
    [int]$hardWarningAbove
) {
    $full = Join-Path $PSScriptRoot "..\$rel"
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        Write-Fail "approx-token-budget (file missing): $rel"
        return
    }
    $tokens = Get-ApproxTokens $full
    if ($tokens -lt $targetMin) {
        Write-Warn "approx-token-budget below target ($tokens < $targetMin): $rel"
    } elseif ($tokens -gt $hardWarningAbove) {
        Write-Warn "approx-token-budget above hard warning ($tokens > $hardWarningAbove): $rel"
    } elseif ($tokens -gt $targetMax) {
        Write-Warn "approx-token-budget above target ($tokens > $targetMax): $rel"
    } else {
        Write-Pass "approx-token-budget in target ($tokens): $rel"
    }
}

function Test-NoDuplicatePhrase([string]$rel, [string]$phrase) {
    $full = Join-Path $PSScriptRoot "..\$rel"
    if (-not (Test-Path $full)) {
        Write-Fail "phrase-check (file missing): $rel"
        return
    }
    $content = Get-Content -Raw -Path $full -Encoding UTF8
    if ($content -match [regex]::Escape($phrase)) {
        Write-Warn "constitutional phrase duplicated in ${rel}: '$phrase'"
    } else {
        Write-Pass "no phrase duplication '$phrase' in $rel"
    }
}

function Test-NonEmpty([string]$rel) {
    $full = Join-Path $PSScriptRoot "..\$rel"
    if (-not (Test-Path $full)) {
        Write-Fail "non-empty (file missing): $rel"
        return
    }
    $content = Get-Content -Raw -Path $full -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($content -and $content.Trim().Length -gt 10) {
        Write-Pass "non-empty: $rel"
    } else {
        Write-Fail "empty or near-empty: $rel"
    }
}

# ---------------------------------------------------------------------------
# Section 1: Required files
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 1: Required Files ===" -ForegroundColor Cyan

$required_files = @(
    "template\.omp\AGENTS.md",
    "template\.omp\RULES.md",
    "template\.omp\config.yml",
    "template\.omp\agents\cheap-scout.md",
    "template\.omp\agents\worker.md",
    "template\.omp\agents\reviewer.md",
    "template\.omp\commands\quick.md",
    "template\.omp\commands\standard.md",
    "template\.omp\commands\orchestrated.md",
    "template\.omp\skills\task-triage\SKILL.md",
    "template\.omp\skills\systematic-debugging\SKILL.md",
    "template\.omp\skills\evidence-before-completion\SKILL.md",
    "template\.omp\contracts\agent-boundary-schema.mjs",
    "template\.omp\contracts\agent-boundary-core.mjs",
    "template\.omp\contracts\agent-boundary-cli.mjs",
    "template\.omp\contracts\managed-state-client.mjs",
    "template\.omp\contracts\managed-runtime.yml",
    "template\.omp\contracts\component-manifest.json",
    "template\.omp\contracts\behavior-core-schema.mjs",
    "template\.omp\contracts\behavior-core.mjs",
    "template\.omp\contracts\behavior-manifest.json",
    "template\.omp\extensions\agent-task-boundary.js",
    "template\.omp\bin\omp-managed.ps1",
    "docs\policies\README.md",
    "docs\policies\context-budget.md",
    "docs\policies\model-routing.md",
    "docs\policies\quality-gates.md",
    "registry\upstreams.yml",
    "registry\licenses.yml",
    "registry\adoption-ledger.yml",
    "registry\rejected-mechanisms.yml",
    "registry\skill-lock.yml",
    "registry\omp-compatibility.yml",
    "docs\evidence\phase-00\manifest.yml",
    "docs\evidence\phase-00\environment\baseline.yml",
    "docs\evidence\phase-00\environment\repository-status-before.txt",
    "docs\evidence\current-product\topic-03\manifest.yml",
    "docs\evidence\current-product\topic-03\deepseek-smoke.yml",
    "docs\evidence\current-product\topic-04\adapter-gate.json",
    "docs\roles\tech-lead.md",
    "docs\task-state.md",
    "docs\agent-boundaries.md",
    "scripts\lib\phase00-evidence.ps1",
    "scripts\lib\topic03-topology-routing.ps1",
    "scripts\lib\topic04-durable-state.ps1",
    "scripts\validate-topic04-durable-state.ps1",
    "scripts\lib\topic05-codegraph.ps1",
    "scripts\lib\topic05-benchmark.ps1",
    "scripts\lib\topic05-progressive-retrieval.ps1",
    "scripts\validate-topic05-progressive-retrieval.ps1",
    "scripts\lib\topic06-agent-boundary.ps1",
    "scripts\validate-topic06-agent-boundary.ps1",
    "scripts\capture-topic06-evidence.ps1",
    "scripts\tests\topic06-contract-core.Tests.mjs",
    "scripts\tests\topic06-agent-contracts.Tests.mjs",
    "scripts\tests\topic06-result-receipt.Tests.mjs",
    "scripts\tests\topic06-omp-wrapper.Tests.mjs",
    "scripts\tests\topic06-state-projection.Tests.ps1",
    "scripts\tests\topic06-installer.Tests.ps1",
    "scripts\tests\topic06-managed-runtime.Tests.ps1",
    "scripts\tests\topic06-agent-boundary.Tests.ps1",
    "scripts\tests\topic06-validator-mutations.Tests.ps1",
    "scripts\tests\fixtures\topic06-boundary-e2e.mjs",
    "docs\evidence\current-product\topic-06\deterministic.json",
    "docs\evidence\current-product\topic-06\manifest.json",
    "codex-topic06-agent-boundary-contracts-changelog.md",
    "scripts\lib\topic08-behavior-core.ps1",
    "scripts\validate-topic08-behavior-core.ps1",
    "scripts\capture-topic08-evidence.ps1",
    "scripts\update-skill-lock.ps1",
    "scripts\tests\topic08-behavior-core.Tests.mjs",
    "scripts\tests\topic08-skill-contracts.Tests.mjs",
    "scripts\tests\topic08-agent-tasks-tool.Tests.mjs",
    "scripts\tests\topic08-behavior-gates.Tests.mjs",
    "scripts\tests\topic08-installer.Tests.ps1",
    "scripts\tests\topic08-validator-mutations.Tests.ps1",
    "docs\behavior-core.md",
    "codex-topic08-portable-behavior-core-runtime-adapters-changelog.md",
    "scripts\provision-codegraph.ps1",
    "scripts\cleanup-codegraph.ps1",
    "scripts\run-topic05-retrieval-benchmark.ps1",
    "scripts\tests\topic05-provisioning.Tests.ps1",
    "scripts\tests\topic05-adapter.Tests.ps1",
    "scripts\tests\topic05-tool.Tests.mjs",
    "scripts\tests\topic05-routing.Tests.ps1",
    "scripts\tests\topic05-installer.Tests.ps1",
    "scripts\tests\topic05-benchmark.Tests.ps1",
    "scripts\tests\topic05-progressive-retrieval.Tests.ps1",
    "scripts\tests\fixtures\topic05\fake-codegraph.mjs",
    "template\.omp\codegraph\upstream-lock.json",
    "template\.omp\codegraph\component-manifest.json",
    "template\.omp\codegraph\CODEGRAPH-LICENSE.txt",
    "template\.omp\codegraph\COMPONENT.md",
    "template\.omp\codegraph\safe-init.mjs",
    "template\.omp\codegraph\codegraph-process.ps1",
    "template\.omp\tools\codegraph-retrieve.js",
    "evals\retrieval\topic05\fixtures.json",
    "evals\retrieval\topic05\README.md",
    "docs\retrieval.md",
    "docs\superpowers\specs\2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-design.md",
    "docs\superpowers\plans\2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-plan.md",
    "template\.omp\state\agent-tasks.ps1",
    "template\.omp\state\manifest.json",
    "template\.omp\state\PROTOCOL.md",
    "template\.omp\state\schemas\agent-tasks-v1.schema.json",
    "template\.omp\state\lib\AgentTasks.Candidate.ps1",
    "template\.omp\state\lib\AgentTasks.Common.ps1",
    "template\.omp\state\lib\AgentTasks.Evidence.ps1",
    "template\.omp\state\lib\AgentTasks.Git.ps1",
    "template\.omp\state\lib\AgentTasks.Lifecycle.ps1",
    "template\.omp\state\lib\AgentTasks.Projection.ps1",
    "template\.omp\state\lib\AgentTasks.Retention.ps1",
    "template\.omp\state\lib\AgentTasks.Store.ps1",
    "template\.omp\state\lib\AgentTasks.Transfer.ps1",
    ".gitignore",
    "README.md",
    "CHANGELOG.md",
    "LICENSES.md"
)

foreach ($f in $required_files) {
    Test-RequiredFile $f
}

# ---------------------------------------------------------------------------
# Section 2: Token budgets
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 2: Token Budgets ===" -ForegroundColor Cyan

Test-ApproxTokenBudget "template\.omp\AGENTS.md"             600  1200  1500
Test-ApproxTokenBudget "template\.omp\RULES.md"              300   700   800
Test-ApproxTokenBudget "template\.omp\agents\cheap-scout.md" 500  1200  1500
Test-ApproxTokenBudget "template\.omp\agents\worker.md"      500  1200  1500
Test-ApproxTokenBudget "template\.omp\agents\reviewer.md"    500  1200  1500

# ---------------------------------------------------------------------------
# Section 3: No constitutional phrases in agent files
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 3: Constitutional Phrase Isolation ===" -ForegroundColor Cyan

# These phrases belong only in AGENTS.md (the constitution).
# Finding them verbatim in individual agent files means duplication.
$phrases = @(
    "think before coding",
    "simplicity first",
    "surgical changes"
)

$agent_files = @(
    "template\.omp\agents\cheap-scout.md",
    "template\.omp\agents\worker.md",
    "template\.omp\agents\reviewer.md"
)

foreach ($agent in $agent_files) {
    foreach ($phrase in $phrases) {
        Test-NoDuplicatePhrase $agent $phrase
    }
}

# ---------------------------------------------------------------------------
# Section 4: Executable contract and state-core files non-empty
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 4: Executable Contract and State-Core Files Non-Empty ===" -ForegroundColor Cyan

$boundary_files = @(
    "template\.omp\contracts\agent-boundary-schema.mjs",
    "template\.omp\contracts\agent-boundary-core.mjs",
    "template\.omp\contracts\agent-boundary-cli.mjs",
    "template\.omp\contracts\managed-state-client.mjs",
    "template\.omp\contracts\managed-runtime.yml",
    "template\.omp\contracts\component-manifest.json",
    "template\.omp\extensions\agent-task-boundary.js",
    "template\.omp\bin\omp-managed.ps1"
)

foreach ($boundaryFile in $boundary_files) {
    Test-NonEmpty $boundaryFile
}

$state_core_files = @(
    "template\.omp\state\agent-tasks.ps1",
    "template\.omp\state\manifest.json",
    "template\.omp\state\PROTOCOL.md",
    "template\.omp\state\schemas\agent-tasks-v1.schema.json",
    "template\.omp\state\lib\AgentTasks.Candidate.ps1",
    "template\.omp\state\lib\AgentTasks.Common.ps1",
    "template\.omp\state\lib\AgentTasks.Evidence.ps1",
    "template\.omp\state\lib\AgentTasks.Git.ps1",
    "template\.omp\state\lib\AgentTasks.Lifecycle.ps1",
    "template\.omp\state\lib\AgentTasks.Projection.ps1",
    "template\.omp\state\lib\AgentTasks.Retention.ps1",
    "template\.omp\state\lib\AgentTasks.Store.ps1",
    "template\.omp\state\lib\AgentTasks.Transfer.ps1"
)

foreach ($stateFile in $state_core_files) {
    Test-NonEmpty $stateFile
}

# ---------------------------------------------------------------------------
# Section 5: Phase 00 evidence and source-authority contracts
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 5: Phase 00 Contracts ===" -ForegroundColor Cyan

$phase00Helper = Join-Path $PSScriptRoot "lib\phase00-evidence.ps1"
$phase00HelperLoaded = $false
if (-not (Test-Path -LiteralPath $phase00Helper -PathType Leaf)) {
    Write-Fail "[P00-HELPER-MISSING] focused Phase 00 validator helper is missing"
} else {
    try {
        . $phase00Helper
        $phase00HelperLoaded = $true
    } catch {
        Write-Fail "[P00-HELPER-LOAD] failed to load Phase 00 validator helper: $($_.Exception.Message)"
    }
}

if ($phase00HelperLoaded) {
    $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $phase00Validators = @(
        "Test-Phase00ManifestContract",
        "Test-Phase00E1ArtifactContract",
        "Test-Phase00E3IArtifactContract",
        "Test-Phase00E3LArtifactContract",
        "Test-Phase00P00CX028CorrectionContract",
        "Test-Phase00E4ArtifactContract",
        "Test-Phase00E5ArtifactContract",
        "Test-Phase00T003PolicyRehomingContract",
        "Test-OmpRegistryContract",
        "Test-OmpCompatibilityContract"
    )

    foreach ($validatorName in $phase00Validators) {
        try {
            $contractResults = @(& $validatorName -RepositoryRoot $repositoryRoot)
            foreach ($result in $contractResults) {
                $message = "[$($result.Code)] $($result.Message)"
                switch ($result.Status) {
                    "PASS" { Write-Pass $message }
                    "WARN" { Write-Warn $message }
                    "FAIL" { Write-Fail $message }
                    default { Write-Fail "[P00-RESULT-STATUS] unknown validation status '$($result.Status)'" }
                }
            }
        } catch {
            Write-Fail "[P00-VALIDATOR-ERROR] $validatorName threw: $($_.Exception.Message)"
        }
    }
}

# ---------------------------------------------------------------------------
# Section 6: Topic 03 selected topology and routing contract
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 6: Topic 03 Topology and Routing ===" -ForegroundColor Cyan

$topic03Helper = Join-Path $PSScriptRoot "lib\topic03-topology-routing.ps1"
if (-not (Test-Path -LiteralPath $topic03Helper -PathType Leaf)) {
    Write-Fail "[T03-HELPER-MISSING] focused Topic 03 validator helper is missing"
} else {
    try {
        . $topic03Helper
        $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $topic03Results = @(Test-Topic03TopologyRoutingContract -RepositoryRoot $repositoryRoot)
        foreach ($result in $topic03Results) {
            $message = "[$($result.Code)] $($result.Message)"
            switch ($result.Status) {
                "PASS" { Write-Pass $message }
                "WARN" { Write-Warn $message }
                "FAIL" { Write-Fail $message }
                default { Write-Fail "[T03-RESULT-STATUS] unknown validation status '$($result.Status)'" }
            }
        }
    } catch {
        Write-Fail "[T03-VALIDATOR-ERROR] focused Topic 03 validation threw: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Section 7: Topic 04 durable task-state contract
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 7: Topic 04 Durable Task State ===" -ForegroundColor Cyan

$topic04Helper = Join-Path $PSScriptRoot "lib\topic04-durable-state.ps1"
if (-not (Test-Path -LiteralPath $topic04Helper -PathType Leaf)) {
    Write-Fail "[T04-HELPER-MISSING] focused Topic 04 validator helper is missing"
} else {
    try {
        . $topic04Helper
        $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $topic04Results = @(Test-Topic04DurableStateContract -RepositoryRoot $repositoryRoot)
        foreach ($result in $topic04Results) {
            $message = "[$($result.Code)] $($result.Message)"
            switch ($result.Status) {
                "PASS" { Write-Pass $message }
                "WARN" { Write-Warn $message }
                "FAIL" { Write-Fail $message }
                default { Write-Fail "[T04-RESULT-STATUS] unknown validation status '$($result.Status)'" }
            }
        }
    } catch {
        Write-Fail "[T04-VALIDATOR-ERROR] focused Topic 04 validation threw: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Section 8: Topic 05 progressive retrieval and optional CodeGraph
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 8: Topic 05 Progressive Retrieval ===" -ForegroundColor Cyan

$topic05Helper = Join-Path $PSScriptRoot "lib\topic05-progressive-retrieval.ps1"
if (-not (Test-Path -LiteralPath $topic05Helper -PathType Leaf)) {
    Write-Fail "[T05-HELPER-MISSING] focused Topic 05 validator helper is missing"
} else {
    try {
        . $topic05Helper
        $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $topic05Results = @(Test-Topic05ProgressiveRetrievalContract -RepositoryRoot $repositoryRoot)
        foreach ($result in $topic05Results) {
            $message = "[$($result.Code)] $($result.Message)"
            switch ($result.Status) {
                "PASS" { Write-Pass $message }
                "WARN" { Write-Warn $message }
                "FAIL" { Write-Fail $message }
                default { Write-Fail "[T05-RESULT-STATUS] unknown validation status '$($result.Status)'" }
            }
        }
    } catch {
        Write-Fail "[T05-VALIDATOR-ERROR] focused Topic 05 validation threw: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Section 9: Topic 06 managed agent boundary
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 9: Topic 06 Managed Agent Boundary ===" -ForegroundColor Cyan

$topic06Helper = Join-Path $PSScriptRoot "lib\topic06-agent-boundary.ps1"
if (-not (Test-Path -LiteralPath $topic06Helper -PathType Leaf)) {
    Write-Fail "[T06-HELPER-MISSING] focused Topic 06 validator helper is missing"
} elseif ($PSVersionTable.PSVersion -lt [version]'7.4.0') {
    Write-Fail "[T06-PWSH] Topic 06 validation requires pwsh 7.4 or newer"
} else {
    try {
        . $topic06Helper
        $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $skipTopic06Evidence = $env:OMP_TOPIC06_CAPTURE -ceq '1'
        $topic06Results = @(Test-Topic06AgentBoundaryContract -RepositoryRoot $repositoryRoot `
            -SkipEvidence:$skipTopic06Evidence)
        foreach ($result in $topic06Results) {
            $message = "[$($result.Code)] $($result.Message)"
            switch ($result.Status) {
                "PASS" { Write-Pass $message }
                "WARN" { Write-Warn $message }
                "FAIL" { Write-Fail $message }
                default { Write-Fail "[T06-RESULT-STATUS] unknown validation status '$($result.Status)'" }
            }
        }
    } catch {
        Write-Fail "[T06-VALIDATOR-ERROR] focused Topic 06 validation threw: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Section 10: Topic 07 safe context continuity
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 10: Topic 07 Safe Context Continuity ===" -ForegroundColor Cyan

$topic07Helper = Join-Path $PSScriptRoot "lib\topic07-context-continuity.ps1"
if (-not (Test-Path -LiteralPath $topic07Helper -PathType Leaf)) {
    Write-Fail "[T07-HELPER-MISSING] focused Topic 07 validator helper is missing"
} elseif ($PSVersionTable.PSVersion -lt [version]'7.4.0') {
    Write-Fail "[T07-PWSH] Topic 07 validation requires pwsh 7.4 or newer"
} else {
    try {
        . $topic07Helper
        $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $skipTopic07Evidence = $env:OMP_TOPIC07_CAPTURE -ceq '1'
        $topic07Results = @(Test-Topic07ContextContinuityContract -RepositoryRoot $repositoryRoot `
            -SkipEvidence:$skipTopic07Evidence)
        foreach ($result in $topic07Results) {
            $message = "[$($result.Code)] $($result.Message)"
            switch ($result.Status) {
                "PASS" { Write-Pass $message }
                "WARN" { Write-Warn $message }
                "FAIL" { Write-Fail $message }
                default { Write-Fail "[T07-RESULT-STATUS] unknown validation status '$($result.Status)'" }
            }
        }
    } catch {
        Write-Fail "[T07-VALIDATOR-ERROR] focused Topic 07 validation threw: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Section 11: Topic 08 portable behavior core
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 11: Topic 08 Portable Behavior Core ===" -ForegroundColor Cyan

$topic08Helper = Join-Path $PSScriptRoot "lib\topic08-behavior-core.ps1"
if (-not (Test-Path -LiteralPath $topic08Helper -PathType Leaf)) {
    Write-Fail "[T08-HELPER-MISSING] focused Topic 08 validator helper is missing"
} elseif ($PSVersionTable.PSVersion -lt [version]'7.4.0') {
    Write-Fail "[T08-PWSH] Topic 08 validation requires pwsh 7.4 or newer"
} else {
    try {
        . $topic08Helper
        $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $topic08Results = @(Test-Topic08BehaviorCore -RepositoryRoot $repositoryRoot -SkipEvidence)
        foreach ($result in $topic08Results) {
            $message = "[$($result.Code)] $($result.Message)"
            switch ($result.Status) {
                "PASS" { Write-Pass $message }
                "WARN" { Write-Warn $message }
                "FAIL" { Write-Fail $message }
                default { Write-Fail "[T08-RESULT-STATUS] unknown validation status '$($result.Status)'" }
            }
        }
    } catch {
        Write-Fail "[T08-VALIDATOR-ERROR] focused Topic 08 validation threw: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Section 12: Round 09-12 closure, evaluation, and release readiness
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 12: Round 09-12 Release Readiness ===" -ForegroundColor Cyan

$round0912Helper = Join-Path $PSScriptRoot "lib\round09-12-release-readiness.ps1"
if (-not (Test-Path -LiteralPath $round0912Helper -PathType Leaf)) {
    Write-Fail "[R0912-HELPER-MISSING] focused Round 09-12 validator helper is missing"
} elseif ($PSVersionTable.PSVersion -lt [version]'7.4.0') {
    Write-Fail "[R0912-PWSH] Round 09-12 validation requires pwsh 7.4 or newer"
} else {
    try {
        . $round0912Helper
        $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
        $skipRoundEvidence = $env:OMP_ROUND0912_CAPTURE -ceq '1'
        $roundResults = @(Test-Round0912ReleaseReadiness -RepositoryRoot $repositoryRoot `
            -SkipEvidence:$skipRoundEvidence)
        foreach ($result in $roundResults) {
            $message = "[$($result.Code)] $($result.Message)"
            switch ($result.Status) {
                "PASS" { Write-Pass $message }
                "WARN" { Write-Warn $message }
                "FAIL" { Write-Fail $message }
                default { Write-Fail "[R0912-RESULT-STATUS] unknown validation status '$($result.Status)'" }
            }
        }
    } catch {
        Write-Fail "[R0912-VALIDATOR-ERROR] focused Round 09-12 validation threw: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ("  Results: {0} passed, {1} warnings, {2} failed" -f $script:passed, $script:warnings, $script:failed) -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if ($script:failed -gt 0) {
    Write-Host "VALIDATION FAILED" -ForegroundColor Red
    exit 1
} elseif ($script:warnings -gt 0) {
    Write-Host "VALIDATION PASSED WITH WARNINGS" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "VALIDATION PASSED" -ForegroundColor Green
    exit 0
}
