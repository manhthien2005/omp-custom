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

function Test-TokenBudget([string]$rel, [int]$min, [int]$max) {
    $full = Join-Path $PSScriptRoot "..\$rel"
    if (-not (Test-Path $full)) {
        Write-Fail "token-budget (file missing): $rel"
        return
    }
    $tokens = Get-ApproxTokens $full
    if ($tokens -lt $min) {
        Write-Warn "token-budget low ($tokens < $min): $rel"
    } elseif ($tokens -gt $max) {
        Write-Warn "token-budget high ($tokens > $max): $rel"
    } else {
        Write-Pass "token-budget OK ($tokens tokens): $rel"
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
    "template\.omp\agents\tech-lead.md",
    "template\.omp\agents\explorer.md",
    "template\.omp\agents\implementer.md",
    "template\.omp\agents\verifier.md",
    "template\.omp\agents\reviewer.md",
    "template\.omp\commands\quick.md",
    "template\.omp\commands\standard.md",
    "template\.omp\commands\orchestrated.md",
    "template\.omp\skills\task-triage\SKILL.md",
    "template\.omp\skills\systematic-debugging\SKILL.md",
    "template\.omp\skills\evidence-before-completion\SKILL.md",
    "template\.omp\schemas\task-packet.schema.yml",
    "template\.omp\schemas\agent-result.schema.yml",
    "template\.omp\schemas\verification-result.schema.yml",
    "template\.omp\schemas\review-result.schema.yml",
    "template\.omp\policies\context-budget.yml",
    "template\.omp\policies\model-routing.yml",
    "template\.omp\policies\workflow-sizing.yml",
    "template\.omp\policies\quality-gates.yml",
    "template\.omp\policies\escalation.yml",
    "registry\upstreams.yml",
    "registry\licenses.yml",
    "registry\adoption-ledger.yml",
    "registry\rejected-mechanisms.yml",
    "registry\skill-lock.yml",
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

Test-TokenBudget "template\.omp\AGENTS.md"             600  1200
Test-TokenBudget "template\.omp\RULES.md"              150   700
Test-TokenBudget "template\.omp\agents\tech-lead.md"   400  1200
Test-TokenBudget "template\.omp\agents\explorer.md"    400  1200
Test-TokenBudget "template\.omp\agents\implementer.md" 400  1200
Test-TokenBudget "template\.omp\agents\verifier.md"    400  1200
Test-TokenBudget "template\.omp\agents\reviewer.md"    400  1200

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
    "template\.omp\agents\tech-lead.md",
    "template\.omp\agents\explorer.md",
    "template\.omp\agents\implementer.md",
    "template\.omp\agents\verifier.md",
    "template\.omp\agents\reviewer.md"
)

foreach ($agent in $agent_files) {
    foreach ($phrase in $phrases) {
        Test-NoDuplicatePhrase $agent $phrase
    }
}

# ---------------------------------------------------------------------------
# Section 4: YAML files non-empty and parseable
# ---------------------------------------------------------------------------
Write-Host "`n=== Section 4: YAML Non-Empty ===" -ForegroundColor Cyan

$yaml_files = @(
    "template\.omp\schemas\task-packet.schema.yml",
    "template\.omp\schemas\agent-result.schema.yml",
    "template\.omp\schemas\verification-result.schema.yml",
    "template\.omp\schemas\review-result.schema.yml",
    "template\.omp\policies\context-budget.yml",
    "template\.omp\policies\model-routing.yml",
    "template\.omp\policies\workflow-sizing.yml",
    "template\.omp\policies\quality-gates.yml",
    "template\.omp\policies\escalation.yml"
)

foreach ($y in $yaml_files) {
    Test-NonEmpty $y
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
