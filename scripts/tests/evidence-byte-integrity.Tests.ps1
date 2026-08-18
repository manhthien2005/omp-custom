#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$repairScript = Join-Path $repositoryRoot 'scripts\repair-evidence-byte-integrity.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-byte-integrity-test-'
$tempRoots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-ByteIntegrity {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Get-TestSha256 {
    param([Parameter(Mandatory)][AllowEmptyCollection()][byte[]]$Bytes)
    return [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData($Bytes)
    ).ToLowerInvariant()
}

function Write-TestBytes {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][AllowEmptyCollection()][byte[]]$Bytes)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllBytes($Path, $Bytes)
}

function New-TestSnapshotEntry {
    param([string]$Path, [byte[]]$ExpectedBytes)
    return [ordered]@{
        record_type = 'candidate_snapshot_entry'
        status = '??'
        path = $Path
        current_exists = $true
        current_bytes = $ExpectedBytes.Length
        current_sha256 = Get-TestSha256 -Bytes $ExpectedBytes
        baseline_sha256 = $null
    }
}

function New-TestRetiredSnapshotEntry {
    param([string]$Path)
    return [ordered]@{
        record_type = 'candidate_snapshot_entry'
        status = 'D '
        path = $Path
        current_exists = $false
        current_bytes = $null
        current_sha256 = $null
        baseline_sha256 = $null
    }
}

function Write-TestSnapshot {
    param([string]$Path, [object[]]$Entries)
    $lines = @($Entries | ForEach-Object { $_ | ConvertTo-Json -Compress })
    [IO.File]::WriteAllText($Path, ($lines -join "`n") + "`n", $utf8)
}

function Remove-TestRoot {
    param([string]$Path)
    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $requiredPrefix = [IO.Path]::GetFullPath($tempBase).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar + $tempPrefix
    if (-not $fullPath.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing cleanup outside guarded temp prefix: $fullPath"
    }
    if (Test-Path -LiteralPath $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
}

function Invoke-RepairCli {
    param([string[]]$Arguments)
    $output = & pwsh -NoLogo -NoProfile -File $repairScript @Arguments 2>&1
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = @($output) }
}

if (-not (Test-Path -LiteralPath $repairScript -PathType Leaf)) {
    throw 'repair-evidence-byte-integrity.ps1 is missing'
}
Assert-ByteIntegrity (Test-Path -LiteralPath $repairScript -PathType Leaf) 'Repair script should be present after the RED check.'

try {
    $tempRoot = Join-Path $tempBase ($tempPrefix + [Guid]::NewGuid().ToString('N'))
    [void]$tempRoots.Add($tempRoot)
    $fixtureRoot = Join-Path $tempRoot 'repo'
    [void](New-Item -ItemType Directory -Path $fixtureRoot -Force)
    & git -C $fixtureRoot init --quiet

    $exactBytes = $utf8.GetBytes("exact`n")
    $allCrlfBytes = $utf8.GetBytes("all`r`ncrlf`r`n")
    $finalLfBytes = $utf8.GetBytes("final`r`nlf`n")
    $lfBytes = $utf8.GetBytes("all`ncrlf`n")
    $finalLfCurrentBytes = $utf8.GetBytes("final`nlf`n")
    $invalidExpectedBytes = $utf8.GetBytes("expected`n")

    Write-TestBytes (Join-Path $fixtureRoot 'exact.txt') $exactBytes
    Write-TestBytes (Join-Path $fixtureRoot 'all-crlf.txt') $lfBytes
    Write-TestBytes (Join-Path $fixtureRoot 'final-lf.txt') $finalLfCurrentBytes
    Write-TestBytes (Join-Path $fixtureRoot 'invalid.txt') $utf8.GetBytes("wrong`n")
    $fixtureSnapshot = Join-Path $fixtureRoot 'snapshot.jsonl'
    Write-TestSnapshot $fixtureSnapshot @(
        (New-TestSnapshotEntry 'exact.txt' $exactBytes),
        (New-TestSnapshotEntry 'all-crlf.txt' $allCrlfBytes),
        (New-TestSnapshotEntry 'final-lf.txt' $finalLfBytes)
    )

    . $repairScript

    $beforeBytes = [IO.File]::ReadAllBytes((Join-Path $fixtureRoot 'all-crlf.txt'))
    $plan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $fixtureSnapshot -Source WorkingTree
    $defaultInvocation = Invoke-RepairCli @('-RepositoryRoot', $fixtureRoot, '-SnapshotPath', $fixtureSnapshot)
    Assert-ByteIntegrity ($defaultInvocation.ExitCode -eq 2 -and [Convert]::ToHexString($beforeBytes) -eq [Convert]::ToHexString([IO.File]::ReadAllBytes((Join-Path $fixtureRoot 'all-crlf.txt')))) 'Default preflight altered bytes.'
    Assert-ByteIntegrity (($plan.Entries | Where-Object Path -eq 'exact.txt').Classification -eq 'exact') 'Exact LF bytes were not classified as exact.'
    Assert-ByteIntegrity (($plan.Entries | Where-Object Path -eq 'all-crlf.txt').Classification -eq 'recoverable') 'All-CRLF candidate was not recoverable.'
    Assert-ByteIntegrity (($plan.Entries | Where-Object Path -eq 'final-lf.txt').Classification -eq 'recoverable') 'CRLF-with-final-LF candidate was not recoverable.'

    $readOnly = Invoke-RepairCli @('-RepositoryRoot', $fixtureRoot, '-SnapshotPath', $fixtureSnapshot, '-Json')
    $readOnlyPlan = ($readOnly.Output -join "`n") | ConvertFrom-Json
    Assert-ByteIntegrity ($readOnly.ExitCode -eq 2 -and $readOnlyPlan.Status -eq 'REPAIR_REQUIRED') 'Read-only repairable state did not return REPAIR_REQUIRED with exit 2.'

    $applied = Invoke-RepairCli @('-RepositoryRoot', $fixtureRoot, '-SnapshotPath', $fixtureSnapshot, '-Apply', '-Json')
    $appliedPlan = ($applied.Output -join "`n") | ConvertFrom-Json
    Assert-ByteIntegrity ($applied.ExitCode -eq 0 -and $appliedPlan.Counts.Written -eq 2) 'Apply did not write both recoverable candidates.'
    $postApply = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $fixtureSnapshot -Source WorkingTree
    Assert-ByteIntegrity ($postApply.Counts.Recoverable -eq 0) 'Post-apply preflight still reported recoverable paths.'

    $rootedSnapshot = Join-Path $fixtureRoot 'rooted.jsonl'
    Write-TestSnapshot $rootedSnapshot @((New-TestSnapshotEntry ([IO.Path]::GetFullPath((Join-Path $fixtureRoot 'exact.txt'))) $exactBytes))
    $rootedPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $rootedSnapshot -Source WorkingTree
    Assert-ByteIntegrity ($rootedPlan.Counts.Invalid -eq 1) 'Rooted snapshot path was not rejected.'

    $parentSnapshot = Join-Path $fixtureRoot 'parent.jsonl'
    Write-TestSnapshot $parentSnapshot @((New-TestSnapshotEntry '../escape.txt' $exactBytes))
    $parentPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $parentSnapshot -Source WorkingTree
    Assert-ByteIntegrity ($parentPlan.Counts.Invalid -eq 1) 'Parent snapshot path was not rejected.'

    $missingSnapshot = Join-Path $fixtureRoot 'missing.jsonl'
    Write-TestBytes (Join-Path $fixtureRoot 'all-crlf.txt') $lfBytes
    Write-TestSnapshot $missingSnapshot @(
        (New-TestSnapshotEntry 'all-crlf.txt' $allCrlfBytes),
        (New-TestSnapshotEntry 'missing.txt' $exactBytes)
    )
    $missingPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $missingSnapshot -Source WorkingTree
    $missingWrites = 0
    $missingResult = Invoke-EvidenceByteIntegrityRepair -Plan $missingPlan -WriteBytes { param($Path, $Bytes) $missingWrites++; [IO.File]::WriteAllBytes($Path, $Bytes) }
    Assert-ByteIntegrity ($missingResult.Status -eq 'FAIL' -and $missingWrites -eq 0) 'Missing file was not rejected before writes.'

    $invalidSnapshot = Join-Path $fixtureRoot 'invalid.jsonl'
    Write-TestSnapshot $invalidSnapshot @(
        (New-TestSnapshotEntry 'all-crlf.txt' $allCrlfBytes),
        (New-TestSnapshotEntry 'invalid.txt' $invalidExpectedBytes)
    )
    $invalidPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $invalidSnapshot -Source WorkingTree
    $invalidWrites = 0
    $invalidResult = Invoke-EvidenceByteIntegrityRepair -Plan $invalidPlan -WriteBytes { param($Path, $Bytes) $invalidWrites++; [IO.File]::WriteAllBytes($Path, $Bytes) }
    Assert-ByteIntegrity ($invalidResult.Status -eq 'FAIL' -and $invalidWrites -eq 0) 'Unexpected mismatch was not rejected before writes.'
    Assert-ByteIntegrity ([Convert]::ToHexString([IO.File]::ReadAllBytes((Join-Path $fixtureRoot 'all-crlf.txt'))) -eq [Convert]::ToHexString($lfBytes)) 'A valid repairable file changed while another entry was invalid.'

    $rollbackSnapshot = Join-Path $fixtureRoot 'rollback.jsonl'
    Write-TestBytes (Join-Path $fixtureRoot 'all-crlf.txt') $lfBytes
    Write-TestBytes (Join-Path $fixtureRoot 'final-lf.txt') $finalLfCurrentBytes
    Write-TestSnapshot $rollbackSnapshot @(
        (New-TestSnapshotEntry 'all-crlf.txt' $allCrlfBytes),
        (New-TestSnapshotEntry 'final-lf.txt' $finalLfBytes)
    )
    $rollbackPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $rollbackSnapshot -Source WorkingTree
    $script:RollbackWriteCalls = 0
    $rollbackResult = Invoke-EvidenceByteIntegrityRepair -Plan $rollbackPlan -WriteBytes {
        param($Path, $Bytes)
        $script:RollbackWriteCalls++
        if ($script:RollbackWriteCalls -eq 2) { throw 'simulated second-write failure' }
        [IO.File]::WriteAllBytes($Path, $Bytes)
    }
    Assert-ByteIntegrity ($rollbackResult.Status -eq 'FAIL' -and $rollbackResult.Rollback.Count -eq 1 -and [Convert]::ToHexString([IO.File]::ReadAllBytes((Join-Path $fixtureRoot 'all-crlf.txt'))) -eq [Convert]::ToHexString($lfBytes)) 'Second-write failure did not roll back the first write.'

    $indexPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $rollbackSnapshot -Source Index
    $indexResult = Invoke-EvidenceByteIntegrityRepair -Plan $indexPlan
    Assert-ByteIntegrity ($indexResult.Status -eq 'FAIL') 'Apply with Source Index was not refused.'

    [IO.File]::WriteAllText((Join-Path $fixtureRoot '.gitattributes'), "* -text`n", $utf8)
    Write-TestBytes (Join-Path $fixtureRoot 'exact.txt') $exactBytes
    Write-TestBytes (Join-Path $fixtureRoot 'all-crlf.txt') $allCrlfBytes
    Write-TestBytes (Join-Path $fixtureRoot 'final-lf.txt') $finalLfBytes
    & git -C $fixtureRoot add .gitattributes exact.txt all-crlf.txt final-lf.txt
    $stagedPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $fixtureSnapshot -Source Index
    Assert-ByteIntegrity ($stagedPlan.Status -eq 'PASS' -and $stagedPlan.Counts.Exact -eq 3) 'Index source did not report staged -text fixture bytes as exact.'

    $limitationPath = 'spec/phases/phase-00-foundation.md'
    Write-TestBytes (Join-Path $fixtureRoot $limitationPath) $utf8.GetBytes("mutated`n")
    $limitationSnapshot = Join-Path $fixtureRoot 'limitation.jsonl'
    Write-TestSnapshot $limitationSnapshot @((New-TestSnapshotEntry $limitationPath $utf8.GetBytes("expected`n")))
    $limitationPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $limitationSnapshot -Source WorkingTree
    Assert-ByteIntegrity ($limitationPlan.Counts.Invalid -eq 1 -and $limitationPlan.Counts.Unrecoverable -eq 0) 'Mutated closed-limitation path was not rejected.'

    $emptyBytes = [byte[]]::new(0)
    Write-TestBytes (Join-Path $fixtureRoot 'empty.txt') $emptyBytes
    $emptySnapshot = Join-Path $fixtureRoot 'empty.jsonl'
    Write-TestSnapshot $emptySnapshot @((New-TestSnapshotEntry 'empty.txt' $emptyBytes))
    $emptyPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $emptySnapshot -Source WorkingTree
    Assert-ByteIntegrity ($emptyPlan.Status -eq 'PASS' -and $emptyPlan.Counts.Exact -eq 1 -and $emptyPlan.Counts.Missing -eq 0) 'A zero-byte working-tree file was not classified as exact.'

    & git -C $fixtureRoot add empty.txt
    $emptyIndexPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $emptySnapshot -Source Index
    Assert-ByteIntegrity ($emptyIndexPlan.Status -eq 'PASS' -and $emptyIndexPlan.Counts.Exact -eq 1 -and $emptyIndexPlan.Counts.Missing -eq 0) 'A zero-byte staged blob was not classified as exact.'

    $retiredSnapshot = Join-Path $fixtureRoot 'retired.jsonl'
    Write-TestSnapshot $retiredSnapshot @(
        (New-TestSnapshotEntry 'exact.txt' $exactBytes),
        (New-TestRetiredSnapshotEntry 'retired-away.txt')
    )
    $retiredPlan = New-EvidenceByteIntegrityPlan -RepositoryRoot $fixtureRoot -SnapshotPath $retiredSnapshot -Source WorkingTree
    Assert-ByteIntegrity ($retiredPlan.Status -eq 'PASS' -and $retiredPlan.Entries.Count -eq 1 -and $retiredPlan.Counts.Missing -eq 0) 'A current_exists=false snapshot entry was not skipped.'

    $cleanupRefused = $false
    try { Remove-TestRoot $tempBase } catch { $cleanupRefused = $true }
    Assert-ByteIntegrity $cleanupRefused 'Cleanup allowed a path outside the guarded temp prefix.'
}
finally {
    foreach ($tempRoot in $tempRoots) { Remove-TestRoot $tempRoot }
}

Write-Host "PASS: evidence byte integrity ($script:Assertions assertions)." -ForegroundColor Green
