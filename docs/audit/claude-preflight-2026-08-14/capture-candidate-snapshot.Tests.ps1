#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'capture-candidate-snapshot.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-claude-audit-snapshot-'
$fixtureRoot = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
$script:Assertions = 0

function Assert-AuditSnapshot {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Write-Utf8Fixture {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$Content
    )
    $parent = Split-Path -Parent $LiteralPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllText($LiteralPath, $Content, [Text.UTF8Encoding]::new($false))
}

function Invoke-AuditSnapshotScript {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& pwsh -NoLogo -NoProfile -File $scriptPath @Arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join [Environment]::NewLine)
    }
}

try {
    [void](New-Item -ItemType Directory -Path $fixtureRoot)
    & git -C $fixtureRoot init -b audit-fixture | Out-Null
    & git -C $fixtureRoot config user.email audit-fixture@example.invalid
    & git -C $fixtureRoot config user.name 'Audit Fixture'

    Write-Utf8Fixture -LiteralPath (Join-Path $fixtureRoot 'tracked.txt') -Content "original`n"
    Write-Utf8Fixture -LiteralPath (Join-Path $fixtureRoot 'removed.txt') -Content "remove-me`n"
    & git -C $fixtureRoot add tracked.txt removed.txt
    & git -C $fixtureRoot commit -m baseline | Out-Null

    Write-Utf8Fixture -LiteralPath (Join-Path $fixtureRoot 'tracked.txt') -Content "changed`n"
    Remove-Item -LiteralPath (Join-Path $fixtureRoot 'removed.txt')
    Write-Utf8Fixture -LiteralPath (Join-Path $fixtureRoot 'untracked.txt') -Content "new`n"

    $packetRoot = Join-Path $fixtureRoot 'docs\audit\claude-preflight-2026-08-14'
    Write-Utf8Fixture -LiteralPath (Join-Path $packetRoot 'packet-only.txt') -Content "excluded`n"
    $snapshotPath = Join-Path $packetRoot 'snapshot.jsonl'

    $capture = Invoke-AuditSnapshotScript -Arguments @(
        '-RepositoryRoot', $fixtureRoot,
        '-OutputPath', $snapshotPath,
        '-Capture'
    )
    Assert-AuditSnapshot ($capture.ExitCode -eq 0) "Capture should succeed: $($capture.Output)"
    Assert-AuditSnapshot (Test-Path -LiteralPath $snapshotPath -PathType Leaf) 'Capture should write the JSONL snapshot.'

    $records = @(Get-Content -LiteralPath $snapshotPath | ForEach-Object { $_ | ConvertFrom-Json })
    $meta = $records[0]
    $entries = @($records | Select-Object -Skip 1)
    Assert-AuditSnapshot ($meta.record_type -ceq 'candidate_snapshot_metadata') 'First record should be metadata.'
    Assert-AuditSnapshot ($meta.branch -ceq 'audit-fixture') 'Metadata should record the fixture branch.'
    Assert-AuditSnapshot ($meta.staged_count -eq 0) 'Metadata should record zero staged paths.'
    Assert-AuditSnapshot ($meta.entry_count -eq 3) 'Snapshot should contain exactly modified, deleted, and untracked entries.'
    Assert-AuditSnapshot ($entries.Count -eq 3) 'JSONL should contain exactly three entry records.'
    Assert-AuditSnapshot (-not ($entries.path -contains 'docs/audit/claude-preflight-2026-08-14/packet-only.txt')) 'Packet paths must be excluded.'

    $modified = $entries | Where-Object path -CEQ 'tracked.txt'
    $deleted = $entries | Where-Object path -CEQ 'removed.txt'
    $untracked = $entries | Where-Object path -CEQ 'untracked.txt'
    Assert-AuditSnapshot ($modified.status -ceq ' M') 'Modified path should retain porcelain status.'
    Assert-AuditSnapshot ($deleted.status -ceq ' D') 'Deleted path should retain porcelain status.'
    Assert-AuditSnapshot ($untracked.status -ceq '??') 'Untracked path should retain porcelain status.'
    Assert-AuditSnapshot ($modified.current_sha256 -ceq (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $fixtureRoot 'tracked.txt')).Hash.ToLowerInvariant()) 'Modified current hash should match file bytes.'
    Assert-AuditSnapshot (-not [string]::IsNullOrWhiteSpace($modified.baseline_sha256)) 'Modified path should include a baseline hash.'
    Assert-AuditSnapshot ($deleted.current_exists -eq $false) 'Deleted path should record current_exists false.'
    Assert-AuditSnapshot (-not [string]::IsNullOrWhiteSpace($deleted.baseline_sha256)) 'Deleted path should include a baseline hash.'
    Assert-AuditSnapshot ([string]::IsNullOrWhiteSpace([string]$untracked.baseline_sha256)) 'Untracked path should not invent a baseline hash.'

    $manifestHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $snapshotPath).Hash
    $verify = Invoke-AuditSnapshotScript -Arguments @(
        '-RepositoryRoot', $fixtureRoot,
        '-InputPath', $snapshotPath,
        '-Verify'
    )
    Assert-AuditSnapshot ($verify.ExitCode -eq 0) "Unchanged candidate should verify: $($verify.Output)"
    Assert-AuditSnapshot ($verify.Output -match 'SNAPSHOT VERIFIED') 'Successful verification should report SNAPSHOT VERIFIED.'
    Assert-AuditSnapshot ((Get-FileHash -Algorithm SHA256 -LiteralPath $snapshotPath).Hash -ceq $manifestHashBefore) 'Verification must not rewrite the manifest.'

    Write-Utf8Fixture -LiteralPath (Join-Path $fixtureRoot 'untracked.txt') -Content "drifted`n"
    $drift = Invoke-AuditSnapshotScript -Arguments @(
        '-RepositoryRoot', $fixtureRoot,
        '-InputPath', $snapshotPath,
        '-Verify'
    )
    Assert-AuditSnapshot ($drift.ExitCode -ne 0) 'Candidate byte drift should fail verification.'
    Assert-AuditSnapshot ($drift.Output -match 'SNAPSHOT_MISMATCH') 'Drift failure should name SNAPSHOT_MISMATCH.'
    Assert-AuditSnapshot ((Get-FileHash -Algorithm SHA256 -LiteralPath $snapshotPath).Hash -ceq $manifestHashBefore) 'Failed verification must not rewrite the manifest.'

    "Audit snapshot tests: $script:Assertions PASS"
}
finally {
    $resolved = [IO.Path]::GetFullPath($fixtureRoot).TrimEnd('\', '/')
    $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
    $leaf = [IO.Path]::GetFileName($resolved)
    if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
        throw "Refusing unsafe test cleanup target: $resolved"
    }
    if (Test-Path -LiteralPath $resolved) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
