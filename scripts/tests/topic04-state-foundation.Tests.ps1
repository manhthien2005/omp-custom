#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtureHelper = Join-Path $repositoryRoot 'scripts\lib\topic04-test-fixtures.ps1'
$commonPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Common.ps1'
$storePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Store.ps1'
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'
$schemaPath = Join-Path $repositoryRoot 'template\.omp\state\schemas\agent-tasks-v1.schema.json'

if (
    -not (Test-Path -LiteralPath $fixtureHelper -PathType Leaf) -or
    -not (Test-Path -LiteralPath $commonPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $storePath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $cliPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $schemaPath -PathType Leaf)
) {
    Write-Host 'FAIL [AT-TEST-CORE-MISSING] Topic 04 state foundation is not installed.' -ForegroundColor Red
    exit 1
}

. $fixtureHelper
. $commonPath
. $storePath

$script:Assertions = 0

function Assert-Topic04 {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic04ErrorCode {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Scenario
    )
    $script:Assertions++
    try {
        & $Action
        throw "[$Scenario] expected $Code but the operation succeeded."
    } catch {
        $actual = [string]$_.Exception.Data['AgentTasksCode']
        if ($actual -cne $Code) {
            throw "[$Scenario] expected $Code, got '$actual': $($_.Exception.Message)"
        }
    }
}

function New-Topic04EnvelopeJson {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [string]$Operation = 'status',
        [string]$RequestJson = '{}',
        [string]$Extra = ''
    )
    $working = $WorkingDirectory.Replace('\', '\\')
    return '{"schema_version":1,"operation":"' + $Operation + '","working_directory":"' +
        $working + '","session_ref":"codex:test-session","runtime":"codex","request":' +
        $RequestJson + $Extra + '}'
}

function New-Topic04RevisionValue {
    param(
        [Parameter(Mandatory)][int]$Revision,
        [AllowNull()][object]$PreviousRevision,
        [AllowNull()][object]$PreviousHash,
        [string[]]$SupportingRefs = @()
    )
    return [ordered]@{
        schema_version = 1
        record_type = 'project_state_revision'
        revision = $Revision
        revision_id = 'R{0:D6}' -f $Revision
        previous_revision = $PreviousRevision
        previous_revision_sha256 = $PreviousHash
        status = 'active'
        supporting_refs = @($SupportingRefs)
    }
}

try {
    $jsonRoot = New-Topic04FixtureRoot -Label 'json'

    $duplicatePath = Join-Path $jsonRoot 'duplicate.json'
    Set-Topic04Utf8File -LiteralPath $duplicatePath -Content '{"schema_version":1,"schema_version":1,"operation":"status","working_directory":"C:/x","session_ref":"s","runtime":"codex","request":{}}'
    Assert-Topic04ErrorCode -Code 'AT-JSON-DUPLICATE-KEY' -Scenario 'duplicate JSON key' -Action {
        Read-AgentTasksEnvelope -Path $duplicatePath
    }

    $unknownPath = Join-Path $jsonRoot 'unknown.json'
    Set-Topic04Utf8File -LiteralPath $unknownPath -Content '{"schema_version":1,"operation":"status","working_directory":"C:/x","session_ref":"s","runtime":"codex","request":{},"surprise":true}'
    Assert-Topic04ErrorCode -Code 'AT-SCHEMA-UNKNOWN-PROPERTY' -Scenario 'unknown envelope property' -Action {
        Read-AgentTasksEnvelope -Path $unknownPath
    }

    $deepPath = Join-Path $jsonRoot 'deep.json'
    $deepValue = '0'
    1..33 | ForEach-Object { $deepValue = '[' + $deepValue + ']' }
    Set-Topic04Utf8File -LiteralPath $deepPath -Content (New-Topic04EnvelopeJson -WorkingDirectory $jsonRoot -RequestJson ('{"value":' + $deepValue + '}'))
    Assert-Topic04ErrorCode -Code 'AT-JSON-LIMIT' -Scenario 'JSON depth limit' -Action {
        Read-AgentTasksEnvelope -Path $deepPath
    }

    $largePath = Join-Path $jsonRoot 'large.json'
    Set-Topic04Utf8File -LiteralPath $largePath -Content ('{"schema_version":1,"operation":"status","working_directory":"C:/x","session_ref":"s","runtime":"codex","request":{"padding":"' + ('x' * 1048576) + '"}}')
    Assert-Topic04ErrorCode -Code 'AT-JSON-LIMIT' -Scenario 'JSON byte limit' -Action {
        Read-AgentTasksEnvelope -Path $largePath
    }

    foreach ($number in @('1.5', '9007199254740992')) {
        $numberPath = Join-Path $jsonRoot ("number-$($number.Replace('.', '-')).json")
        Set-Topic04Utf8File -LiteralPath $numberPath -Content ('{"schema_version":' + $number + ',"operation":"status","working_directory":"C:/x","session_ref":"s","runtime":"codex","request":{}}')
        Assert-Topic04ErrorCode -Code 'AT-JSON-NUMBER' -Scenario "invalid JSON number $number" -Action {
            Read-AgentTasksEnvelope -Path $numberPath
        }
    }

    $first = [ordered]@{ b = 2; a = 1 }
    $second = [ordered]@{ a = 1; b = 2 }
    $firstHash = Get-AgentTasksSha256 -Value $first
    $secondHash = Get-AgentTasksSha256 -Value $second
    Assert-Topic04 ($firstHash -ceq $secondHash) 'Equivalent object insertion orders must hash identically.'
    Assert-Topic04 ($firstHash -ceq '43258CFF783FE7036D8A43033F830ADFC60EC037382473548AC742B888292777') 'Canonical JSON must match the hand-checked RFC 8785 fixture hash.'
    Assert-Topic04 ((ConvertTo-AgentTasksCanonicalJson -Value $first) -ceq '{"a":1,"b":2}') 'Canonical JSON must use ordinal property order.'

    $gitRoot = New-Topic04FixtureRoot -Label 'git-root'
    $repository = Initialize-Topic04GitFixture -Root $gitRoot
    $linked = Add-Topic04LinkedWorktree -Repository $repository -Root $gitRoot
    $mainContext = Resolve-AgentTasksContext -WorkingDirectory $repository
    $linkedContext = Resolve-AgentTasksContext -WorkingDirectory $linked
    Assert-Topic04 ($mainContext.IsGit -and $linkedContext.IsGit) 'Both Git fixtures must resolve as Git worktrees.'
    Assert-Topic04 ($mainContext.StateRoot -ceq $linkedContext.StateRoot) 'Main and linked worktrees must share one authority root.'
    Assert-Topic04 ($mainContext.GitDir -cne $linkedContext.GitDir) 'Main and linked worktrees must have distinct Git directories.'
    Assert-Topic04 ($mainContext.WorktreeRoot -cne $linkedContext.WorktreeRoot) 'Main and linked worktrees must have distinct worktree roots.'
    Assert-Topic04 ([IO.Path]::GetFileName($mainContext.StateRoot) -ceq 'agent-tasks') 'Git authority namespace must be agent-tasks.'

    $nonGitRoot = New-Topic04FixtureRoot -Label 'non-git-root'
    $nonGitContext = Resolve-AgentTasksContext -WorkingDirectory $nonGitRoot
    Assert-Topic04 (-not $nonGitContext.IsGit) 'Non-Git fixture must not resolve as Git.'
    Assert-Topic04 ($nonGitContext.StateRoot -ceq (Join-Path $nonGitRoot '.agent-tasks')) 'Non-Git state root must be project-local .agent-tasks.'

    $storeRoot = New-Topic04FixtureRoot -Label 'store'
    $stateDirectory = Join-Path $storeRoot 'state'
    [void](New-Item -ItemType Directory -Path $stateDirectory)
    $r1Path = Join-Path $stateDirectory 'R000001.json'
    $r1 = Publish-AgentTasksRecord -LiteralPath $r1Path -Value (New-Topic04RevisionValue -Revision 1 -PreviousRevision $null -PreviousHash $null)
    Assert-Topic04 (Test-Path -LiteralPath $r1Path -PathType Leaf) 'R000001 must publish exactly once.'
    Assert-Topic04ErrorCode -Code 'AT-STORE-IMMUTABLE' -Scenario 'immutable revision overwrite' -Action {
        Publish-AgentTasksRecord -LiteralPath $r1Path -Value (New-Topic04RevisionValue -Revision 1 -PreviousRevision $null -PreviousHash $null)
    }
    $r2Path = Join-Path $stateDirectory 'R000002.json'
    [void](Publish-AgentTasksRecord -LiteralPath $r2Path -Value (New-Topic04RevisionValue -Revision 2 -PreviousRevision 'R000001' -PreviousHash $r1.Sha256))
    $chain = Get-AgentTasksRevisionChain -StateDirectory $stateDirectory
    Assert-Topic04 ($chain.Status -ceq 'valid' -and $chain.Records.Count -eq 2) 'A contiguous two-revision chain must validate.'
    Assert-Topic04 ($chain.Records[1].previous_revision -ceq 'R000001') 'R000002 must name R000001.'
    Assert-Topic04 ($chain.Records[1].previous_revision_sha256 -ceq $r1.Sha256) 'R000002 must name the exact R000001 digest.'

    $gapDirectory = Join-Path $storeRoot 'gap-state'
    [void](New-Item -ItemType Directory -Path $gapDirectory)
    [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $gapDirectory 'R000001.json') -Value (New-Topic04RevisionValue -Revision 1 -PreviousRevision $null -PreviousHash $null))
    [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $gapDirectory 'R000003.json') -Value (New-Topic04RevisionValue -Revision 3 -PreviousRevision 'R000002' -PreviousHash ('A' * 64)))
    Assert-Topic04 ((Get-AgentTasksRevisionChain -StateDirectory $gapDirectory).Status -ceq 'reconcile_required') 'A revision gap must require reconciliation.'

    $malformedDirectory = Join-Path $storeRoot 'malformed-state'
    [void](New-Item -ItemType Directory -Path $malformedDirectory)
    Set-Topic04Utf8File -LiteralPath (Join-Path $malformedDirectory 'R000001.json') -Content '{broken'
    Assert-Topic04 ((Get-AgentTasksRevisionChain -StateDirectory $malformedDirectory).Status -ceq 'reconcile_required') 'Malformed revision JSON must require reconciliation.'

    $brokenDirectory = Join-Path $storeRoot 'broken-state'
    [void](New-Item -ItemType Directory -Path $brokenDirectory)
    $brokenPath = Join-Path $brokenDirectory 'R000001.json'
    [void](Publish-AgentTasksRecord -LiteralPath $brokenPath -Value (New-Topic04RevisionValue -Revision 1 -PreviousRevision $null -PreviousHash $null))
    $brokenText = [IO.File]::ReadAllText($brokenPath).Replace('"status":"active"', '"status":"blocked"')
    Set-Topic04Utf8File -LiteralPath $brokenPath -Content $brokenText
    Assert-Topic04 ((Get-AgentTasksRevisionChain -StateDirectory $brokenDirectory).Status -ceq 'reconcile_required') 'A revision hash break must require reconciliation.'

    $supportingDirectory = Join-Path $stateDirectory 'supporting'
    [void](New-Item -ItemType Directory -Path $supportingDirectory)
    [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $supportingDirectory 'O000001.json') -Value ([ordered]@{
        schema_version = 1; record_type = 'supporting'; supporting_id = 'O000001'; value = 'orphan'
    }))
    $orphanChain = Get-AgentTasksRevisionChain -StateDirectory $stateDirectory
    Assert-Topic04 ($orphanChain.Status -ceq 'valid') 'An orphan supporting record must not select a lifecycle transition.'
    Assert-Topic04 ($orphanChain.Orphans.Count -eq 1 -and $orphanChain.Orphans[0] -ceq 'O000001.json') 'An orphan supporting record must be reported.'

    $lockRoot = New-Topic04FixtureRoot -Label 'locks'
    [void](New-Item -ItemType Directory -Path (Join-Path $lockRoot 'locks'))
    $jobs = @(
        1..2 | ForEach-Object {
            Start-ThreadJob -ArgumentList $storePath, $lockRoot -ScriptBlock {
                param($modulePath, $stateRoot)
                . $modulePath
                try {
                    Invoke-WithAgentTasksLock -StateRoot $stateRoot -Domain repository -Id 'shared' -Action {
                        Start-Sleep -Milliseconds 500
                        'won'
                    }
                } catch {
                    [string]$_.Exception.Data['AgentTasksCode']
                }
            }
        }
    )
    $lockResults = @($jobs | Wait-Job | Receive-Job)
    $jobs | Remove-Job -Force
    Assert-Topic04 (@($lockResults | Where-Object { $_ -ceq 'won' }).Count -eq 1) 'Exactly one lock contender must own the lock.'
    Assert-Topic04 (@($lockResults | Where-Object { $_ -ceq 'AT-LOCK-HELD' }).Count -eq 1) 'The losing lock contender must fail closed.'

    $staleLock = Join-Path $lockRoot 'locks\repository-stale.lock'
    [void](New-Item -ItemType Directory -Path $staleLock)
    Set-Topic04Utf8File -LiteralPath (Join-Path $staleLock 'owner.json') -Content '{"schema_version":1,"record_type":"lock_owner","created_at":"2000-01-01T00:00:00Z","host":"fixture","process_id":1,"process_start_time":"2000-01-01T00:00:00Z"}'
    Assert-Topic04ErrorCode -Code 'AT-LOCK-HELD' -Scenario 'stale lock has no time expiry' -Action {
        Invoke-WithAgentTasksLock -StateRoot $lockRoot -Domain repository -Id 'stale' -Action { 'unexpected' }
    }

    $cliRoot = New-Topic04FixtureRoot -Label 'cli'
    $initJson = New-Topic04EnvelopeJson -WorkingDirectory $cliRoot -Operation 'init-project' -RequestJson '{"display_name":"Foundation Fixture"}'
    $init = Invoke-Topic04Cli -CliPath $cliPath -FixtureRoot $cliRoot -Json $initJson
    Assert-Topic04 ($init.ExitCode -eq 0 -and $init.Parsed.ok) 'init-project must succeed.'
    Assert-Topic04 ($init.StdoutLineCount -eq 1) 'init-project must emit one JSON document.'
    $authorityRoot = Join-Path $cliRoot '.agent-tasks'
    Assert-Topic04 (Test-Path -LiteralPath (Join-Path $authorityRoot 'project\identity.json')) 'init-project must publish project identity.'
    Assert-Topic04 (Test-Path -LiteralPath (Join-Path $authorityRoot 'project\state\R000001.json')) 'init-project must publish R000001.'
    Assert-Topic04 ([IO.File]::ReadAllText((Join-Path $authorityRoot '.gitignore')) -ceq "*`n!.gitignore`n") 'Non-Git authority must contain the exact nested ignore file.'
    $beforeSecondInit = Get-Topic04TreeFingerprint -LiteralPath $authorityRoot
    $secondInit = Invoke-Topic04Cli -CliPath $cliPath -FixtureRoot $cliRoot -Json $initJson
    $afterSecondInit = Get-Topic04TreeFingerprint -LiteralPath $authorityRoot
    Assert-Topic04 ($secondInit.ExitCode -eq 0 -and $beforeSecondInit -ceq $afterSecondInit) 'A second init-project must return identity without changing bytes.'

    $statusJson = New-Topic04EnvelopeJson -WorkingDirectory $cliRoot -Operation 'status'
    $beforeStatus = Get-Topic04TreeFingerprint -LiteralPath $authorityRoot
    $status = Invoke-Topic04Cli -CliPath $cliPath -FixtureRoot $cliRoot -Json $statusJson
    $afterStatus = Get-Topic04TreeFingerprint -LiteralPath $authorityRoot
    Assert-Topic04 ($status.ExitCode -eq 0 -and $status.Parsed.ok -and $status.Parsed.operation -ceq 'status') 'status must succeed.'
    Assert-Topic04 ($status.StdoutLineCount -eq 1) 'status must emit exactly one JSON document.'
    Assert-Topic04 ($beforeStatus -ceq $afterStatus) 'status must be read-only.'

    $unknownJson = New-Topic04EnvelopeJson -WorkingDirectory $cliRoot -Operation 'explode'
    $unknown = Invoke-Topic04Cli -CliPath $cliPath -FixtureRoot $cliRoot -Json $unknownJson
    Assert-Topic04 ($unknown.ExitCode -eq 2 -and $unknown.Parsed.code -ceq 'AT-OPERATION-UNKNOWN') 'Unknown operations must exit 2 with AT-OPERATION-UNKNOWN.'

    $secret = 'super-secret-value'
    $failure = ConvertTo-AgentTasksFailure -Exception ([InvalidOperationException]::new("internal $secret")) -Operation 'status'
    $failureJson = ConvertTo-AgentTasksCanonicalJson -Value $failure.Result
    Assert-Topic04 ($failure.ExitCode -eq 5 -and $failure.Result.code -ceq 'AT-INTERNAL') 'Unexpected errors must map to the internal fault envelope.'
    Assert-Topic04 (-not $failureJson.Contains($secret, [StringComparison]::Ordinal)) 'Internal failure envelopes must never leak exception details.'
    Assert-Topic04 (-not $failureJson.Contains('stack', [StringComparison]::OrdinalIgnoreCase)) 'Internal failure envelopes must not expose a stack.'

    $schema = [IO.File]::ReadAllText($schemaPath) | ConvertFrom-Json -Depth 64
    $requiredDefs = @(
        'operationEnvelope', 'resultEnvelope', 'projectIdentity', 'phaseContract',
        'phaseStateRevision', 'taskContract', 'taskStateRevision', 'sessionIdentity',
        'checkpoint', 'workUnitContract', 'workUnitOutcome', 'candidate', 'evidence',
        'handoff', 'artifactMetadata', 'lockOwner'
    )
    foreach ($definition in $requiredDefs) {
        Assert-Topic04 ($null -ne $schema.'$defs'.$definition) "Schema definition '$definition' must exist."
        $closedDefinition =
            ($schema.'$defs'.$definition.PSObject.Properties.Name -contains 'additionalProperties' -and $schema.'$defs'.$definition.additionalProperties -eq $false) -or
            ($schema.'$defs'.$definition.PSObject.Properties.Name -contains 'oneOf' -and @($schema.'$defs'.$definition.oneOf).Count -gt 0)
        Assert-Topic04 $closedDefinition "Schema definition '$definition' must be closed or an explicit closed union."
    }

    Write-Host ("PASS Topic 04 state foundation ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-FOUNDATION] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
