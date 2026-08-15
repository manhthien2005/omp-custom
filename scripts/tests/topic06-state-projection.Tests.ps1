#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtureHelper = Join-Path $repositoryRoot 'scripts\lib\topic04-test-fixtures.ps1'
$commonPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Common.ps1'
$storePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Store.ps1'
$gitPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Git.ps1'
$lifecyclePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Lifecycle.ps1'
$candidatePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Candidate.ps1'
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'

. $fixtureHelper
. $commonPath
. $storePath
. $gitPath
. $lifecyclePath
. $candidatePath

$script:Assertions = 0

function Assert-Topic06Projection {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic06ProjectionFailure {
    param(
        [Parameter(Mandatory)][object]$Result,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Scenario
    )
    $script:Assertions++
    if ($Result.ExitCode -eq 0 -or $Result.Parsed.code -cne $Code) {
        throw "[$Scenario] expected $Code, got exit=$($Result.ExitCode), code=$($Result.Parsed.code)."
    }
}

function Get-Topic06ProjectionHash {
    param([Parameter(Mandatory)][object]$Projection)

    $withoutHash = [ordered]@{}
    foreach ($property in $Projection.PSObject.Properties) {
        if ($property.Name -cne 'projection_sha256') {
            $withoutHash[$property.Name] = $property.Value
        }
    }
    return Get-AgentTasksSha256 -Value $withoutHash
}

function Get-Topic06Authority {
    param([Parameter(Mandatory)][object]$Context, [Parameter(Mandatory)][string]$TaskId)
    return Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
}

function Invoke-Topic06Project {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][string]$WorkUnitId,
        [string]$SessionRef = 'codex:topic06-owner'
    )
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'project-work-unit' -SessionRef $SessionRef -Request ([ordered]@{
            task_id = $TaskId
            work_unit_id = $WorkUnitId
        })
}

try {
    $fixture = New-Topic04FixtureRoot -Label 'topic06-projection'
    $repository = Initialize-Topic04GitFixture -Root $fixture
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "baseline`n"
    & git -C $repository add src/output.txt
    & git -C $repository commit --quiet -m 'projection baseline'
    if ($LASTEXITCODE -ne 0) { throw 'Failed to commit the projection fixture baseline.' }

    $owner = 'codex:topic06-owner'
    $successor = 'codex:topic06-successor'
    $create = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $owner -Request ([ordered]@{
            objective = 'Produce the bounded Topic 06 projection.'
            authority = @('user-approved-topic-06')
            acceptance_criteria = @(
                [ordered]@{ id = 'AC-001'; text = 'Projection is deterministic.'; mandatory = $true },
                [ordered]@{ id = 'AC-002'; text = 'Private authority stays private.'; mandatory = $true }
            )
            obligations = @('Run the focused projection tests.')
            execution_mode = 'mutating'
            write_scope = @([ordered]@{ kind = 'subtree'; path = 'src' })
            owned_ignored_outputs = @()
            workflow_class = 'standard'
            locked_decisions = @()
        })
    Assert-Topic06Projection ($create.ExitCode -eq 0) 'Projection fixture task must be created.'
    $taskId = [string]$create.Parsed.data.task_id
    $context = Resolve-AgentTasksContext -WorkingDirectory $repository
    $authority = Get-Topic06Authority -Context $context -TaskId $taskId

    $workUnit = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-work-unit' -SessionRef $owner -Request ([ordered]@{
            task_id = $taskId
            work_unit_id = 'WU-001'
            inputs = @('task contract', 'current source')
            outputs = @('src/output.txt')
            ownership = @('src')
            dependencies = @()
            completion_conditions = @('AC-001 and AC-002 remain checkable')
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    Assert-Topic06Projection ($workUnit.ExitCode -eq 0) 'Projection fixture work unit must be created.'
    $authority = Get-Topic06Authority -Context $context -TaskId $taskId

    $outcome = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'record-work-unit-outcome' -SessionRef $owner -Request ([ordered]@{
            task_id = $taskId
            work_unit_id = 'WU-001'
            status = 'completed'
            artifact_refs = @('src/output.txt')
            observed_summary = [ordered]@{ result = 'candidate bytes ready' }
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    Assert-Topic06Projection ($outcome.ExitCode -eq 0) 'Projection fixture outcome must be recorded.'

    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "candidate`n"
    $authority = Get-Topic06Authority -Context $context -TaskId $taskId
    $freeze = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'freeze' -SessionRef $owner -Request ([ordered]@{
            task_id = $taskId
            acceptance_inputs = @()
            scope_dispositions = @()
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    Assert-Topic06Projection ($freeze.ExitCode -eq 0) 'Projection fixture candidate must freeze.'
    $authority = Get-Topic06Authority -Context $context -TaskId $taskId

    $first = Invoke-Topic06Project -FixtureRoot $fixture -Repository $repository -TaskId $taskId -WorkUnitId 'WU-001'
    Assert-Topic06Projection ($first.ExitCode -eq 0) "project-work-unit must succeed (exit=$($first.ExitCode), code=$($first.Parsed.code), stderr=$($first.Stderr))."
    $projection = $first.Parsed.data
    Assert-Topic06Projection (
        (@($projection.PSObject.Properties.Name) -join ',') -ceq 'binding,cas,projection_sha256,record_type,schema_version,task,work_unit'
    ) 'Projection must have the exact closed top-level shape.'
    Assert-Topic06Projection (
        $projection.record_type -ceq 'work_unit_projection' -and
        $projection.task.task_id -ceq $taskId -and
        $projection.task.status -ceq 'candidate_frozen' -and
        $projection.work_unit.work_unit_id -ceq 'WU-001'
    ) 'Projection must preserve exact task and work-unit identity.'
    Assert-Topic06Projection (
        @($projection.task.acceptance_criteria).Count -eq 2 -and
        $projection.work_unit.outputs[0] -ceq 'src/output.txt' -and
        $projection.work_unit.ownership[0] -ceq 'src'
    ) 'Projection must preserve immutable acceptance and ownership contracts.'
    Assert-Topic06Projection (
        $projection.binding.candidate_id -ceq 'C1' -and
        $projection.binding.candidate_sha256 -ceq [string]$freeze.Parsed.data.candidate_hash -and
        $projection.binding.diff_ref -match '^[A-F0-9]{64}$' -and
        $projection.binding.artifact_refs[0] -ceq 'src/output.txt'
    ) 'Projection must reconcile candidate, diff, and artifact bindings.'
    Assert-Topic06Projection (
        $projection.cas.revision -eq $authority.Revision.revision -and
        $projection.cas.revision_sha256 -ceq $authority.RevisionSha256 -and
        $projection.cas.lease_generation -eq $authority.Revision.lease_generation
    ) 'Projection CAS must come from the current authoritative revision.'
    Assert-Topic06Projection (
        $projection.projection_sha256 -ceq (Get-Topic06ProjectionHash -Projection $projection)
    ) 'Projection hash must cover the canonical projection with its hash omitted.'

    $second = Invoke-Topic06Project -FixtureRoot $fixture -Repository $repository -TaskId $taskId -WorkUnitId 'WU-001'
    Assert-Topic06Projection (
        $second.ExitCode -eq 0 -and $second.Stdout -ceq $first.Stdout
    ) 'Repeated projection reads must be byte-stable.'

    $serialized = [string]$first.Stdout
    $privateNeedles = @(
        [string]$context.StateRoot,
        'record_hash',
        'revision_id',
        'previous_revision',
        'checkpoint_id',
        'owner_session_ref',
        'predecessor_session_ref',
        'observed_summary',
        'candidate bytes ready',
        'terminal_history',
        'credential'
    )
    Assert-Topic06Projection (
        @($privateNeedles | Where-Object { $serialized.Contains($_, [StringComparison]::OrdinalIgnoreCase) }).Count -eq 0
    ) 'Projection must not leak private authority, evidence, session, or provider fields.'

    $missing = Invoke-Topic06Project -FixtureRoot $fixture -Repository $repository -TaskId $taskId -WorkUnitId 'WU-404'
    Assert-Topic06ProjectionFailure -Result $missing -Code 'AT-WORK-UNIT-NOT-FOUND' -Scenario 'missing work unit projection'

    [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $authority.Root 'work-units\WU-UNLISTED.json') -Value ([ordered]@{
        schema_version = 1
        record_type = 'work_unit_contract'
        work_unit_id = 'WU-UNLISTED'
        inputs = @()
        outputs = @()
        ownership = @()
        dependencies = @()
        completion_conditions = @()
    }))
    $unlisted = Invoke-Topic06Project -FixtureRoot $fixture -Repository $repository -TaskId $taskId -WorkUnitId 'WU-UNLISTED'
    Assert-Topic06ProjectionFailure -Result $unlisted -Code 'AT-WORK-UNIT-UNLISTED' -Scenario 'unlisted work unit projection'

    $wrongSession = Invoke-Topic06Project -FixtureRoot $fixture -Repository $repository -TaskId $taskId -WorkUnitId 'WU-001' -SessionRef 'codex:not-owner'
    Assert-Topic06Projection (
        $wrongSession.ExitCode -eq 0 -and $wrongSession.Stdout -ceq $first.Stdout
    ) 'Read-only projection must not depend on the caller session when task authority has an active owner.'

    $checkpoint = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'checkpoint' -SessionRef $owner -Request ([ordered]@{
            task_id = $taskId
            kind = 'mandatory'
            next_action = 'Transfer the exact candidate.'
            blockers = @()
            open_risks = @('Successor must revalidate before mutation.')
            work_unit_id = 'WU-001'
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    Assert-Topic06Projection ($checkpoint.ExitCode -eq 0) 'Atomic handoff fixture checkpoint must publish.'
    $authority = Get-Topic06Authority -Context $context -TaskId $taskId
    $begin = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'begin-handoff' -SessionRef $owner -Request ([ordered]@{
            task_id = $taskId
            successor_session_ref = $successor
            successor_runtime = 'codex'
            next_action = 'Reload authority and validate the frozen candidate.'
            blockers = @()
            open_risks = @('Successor must revalidate before mutation.')
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    Assert-Topic06Projection ($begin.ExitCode -eq 0) 'begin-handoff must create the transfer.'
    $handoffProjection = $begin.Parsed.data.handoff_projection
    Assert-Topic06Projection ($null -ne $handoffProjection) 'begin-handoff must return its safe projection atomically.'
    Assert-Topic06Projection (
        (@($handoffProjection.PSObject.Properties.Name) -join ',') -ceq 'candidate,lifecycle,projection_sha256,record_type,schema_version,successor,task_contract,transfer'
    ) 'Handoff projection must have the exact closed top-level shape.'
    Assert-Topic06Projection (
        $handoffProjection.record_type -ceq 'handoff_projection' -and
        $handoffProjection.successor.session_ref -ceq $successor -and
        $handoffProjection.lifecycle.status -ceq 'transferring' -and
        $handoffProjection.transfer.handoff_id -ceq $begin.Parsed.data.handoff_id -and
        $handoffProjection.transfer.handoff_sha256 -ceq $begin.Parsed.data.handoff_hash
    ) 'Handoff projection must bind the exact successor and published transfer.'
    Assert-Topic06Projection (
        $handoffProjection.projection_sha256 -ceq (Get-Topic06ProjectionHash -Projection $handoffProjection)
    ) 'Handoff projection hash must cover the atomic safe projection.'
    $handoffSerialized = $handoffProjection | ConvertTo-Json -Depth 64 -Compress
    Assert-Topic06Projection (
        -not $handoffSerialized.Contains([string]$context.StateRoot, [StringComparison]::OrdinalIgnoreCase) -and
        -not $handoffSerialized.Contains($owner, [StringComparison]::Ordinal) -and
        -not $handoffSerialized.Contains('checkpoint', [StringComparison]::OrdinalIgnoreCase) -and
        -not $handoffSerialized.Contains('observed_summary', [StringComparison]::OrdinalIgnoreCase)
    ) 'Handoff projection must not expose authority paths, predecessor session, checkpoints, or raw outcomes.'

    $staleBegin = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'begin-handoff' -SessionRef $owner -Request ([ordered]@{
            task_id = $taskId
            successor_session_ref = 'codex:never-created'
            successor_runtime = 'codex'
            next_action = 'This must not publish.'
            blockers = @()
            open_risks = @()
            expected_revision = [long]$authority.Revision.revision
            expected_revision_sha256 = [string]$authority.RevisionSha256
            expected_lease_generation = [long]$authority.Revision.lease_generation
        })
    Assert-Topic06ProjectionFailure -Result $staleBegin -Code 'AT-CAS-REVISION' -Scenario 'stale handoff projection'
    Assert-Topic06Projection (
        -not (Test-Path -LiteralPath (Join-Path $authority.Root 'handoffs\H000002.json'))
    ) 'A stale CAS must not create a handoff or projection.'

    Write-Host "PASS: Topic 06 state projection ($script:Assertions assertions)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
