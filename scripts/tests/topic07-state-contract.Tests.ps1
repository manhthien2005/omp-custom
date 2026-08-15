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
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'

. $fixtureHelper
. $commonPath
. $storePath
. $gitPath
. $lifecyclePath

$script:Assertions = 0

function Assert-Topic07State {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic07Failure {
    param(
        [Parameter(Mandatory)][object]$Result,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Scenario
    )
    $script:Assertions++
    if ($Result.ExitCode -eq 0 -or $Result.Parsed.code -cne $Code) {
        throw "[$Scenario] expected $Code, got exit=$($Result.ExitCode) code=$($Result.Parsed.code)."
    }
}

function New-Topic07Decision {
    param(
        [string]$Id = 'D-001',
        [string]$Statement = 'Preserve the approved workflow class.',
        [string]$AuthorityRef = 'user:2026-08-13'
    )
    return [ordered]@{
        decision_id = $Id
        statement = $Statement
        authority_ref = $AuthorityRef
    }
}

function New-Topic07TaskRequest {
    param(
        [string]$WorkflowClass = 'standard',
        [object[]]$LockedDecisions = @()
    )
    return [ordered]@{
        objective = 'Exercise the Topic 07 continuity authority.'
        authority = @('user')
        acceptance_criteria = @([ordered]@{ id = 'AC-001'; text = 'Continuity is explicit.'; mandatory = $true })
        obligations = @('Run deterministic verification.')
        execution_mode = 'read_only'
        write_scope = @()
        owned_ignored_outputs = @()
        workflow_class = $WorkflowClass
        locked_decisions = @($LockedDecisions)
    }
}

function Get-Topic07TaskAuthority {
    param([Parameter(Mandatory)][object]$Context, [Parameter(Mandatory)][string]$TaskId)
    return Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
}

function New-Topic07ContinuityRequest {
    param(
        [Parameter(Mandatory)][object]$Authority,
        [string]$WorkflowClass = 'standard',
        [object[]]$LockedDecisions = @(),
        [string]$AuthorityRef = 'user:2026-08-13',
        [string]$Reason = 'Initialize the approved continuity contract.'
    )
    return [ordered]@{
        task_id = [string]$Authority.Revision.task_id
        workflow_class = $WorkflowClass
        locked_decisions = @($LockedDecisions)
        authority_ref = $AuthorityRef
        reason = $Reason
        expected_revision = [long]$Authority.Revision.revision
        expected_revision_sha256 = [string]$Authority.RevisionSha256
        expected_lease_generation = [long]$Authority.Revision.lease_generation
    }
}

function Convert-Topic07TaskToLegacy {
    param([Parameter(Mandatory)][string]$TaskRoot)

    $priorFileHash = $null
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $TaskRoot 'state') -File -Filter 'R*.json' | Sort-Object Name) {
        $record = Read-AgentTasksJsonFile -LiteralPath $file.FullName
        $legacy = [ordered]@{}
        foreach ($key in $record.Keys) {
            if ([string]$key -notin @('workflow_class', 'locked_decisions', 'record_hash')) {
                $legacy[[string]$key] = $record[$key]
            }
        }
        $legacy.previous_revision_sha256 = $priorFileHash
        $legacy.record_hash = Get-AgentTasksSha256 -Value $legacy
        Set-Topic04Utf8File -LiteralPath $file.FullName -Content ((ConvertTo-AgentTasksCanonicalJson -Value $legacy) + "`n")
        $priorFileHash = Get-AgentTasksSha256 -LiteralPath $file.FullName
    }
}

function Get-Topic07StateCounts {
    param([Parameter(Mandatory)][string]$TaskRoot)
    return [pscustomobject]@{
        Revisions = @(Get-ChildItem -LiteralPath (Join-Path $TaskRoot 'state') -File -Filter 'R*.json').Count
        Supporting = @(Get-ChildItem -LiteralPath (Join-Path $TaskRoot 'supporting') -File -Filter 'CC*.json' -ErrorAction SilentlyContinue).Count
    }
}

try {
    $fixture = New-Topic04FixtureRoot -Label 'topic07-state'
    $repository = Initialize-Topic04GitFixture -Root $fixture
    $context = Resolve-AgentTasksContext -WorkingDirectory $repository
    $owner = 'codex:topic07-owner'

    $missing = New-Topic07TaskRequest
    [void]$missing.Remove('workflow_class')
    [void]$missing.Remove('locked_decisions')
    $missingResult = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $owner -Runtime 'codex' -Request $missing
    Assert-Topic07Failure -Result $missingResult -Code 'AT-SCHEMA-REQUIRED' -Scenario 'new task continuity fields are required'

    $invalidWorkflow = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07TaskRequest -WorkflowClass 'STANDARD')
    Assert-Topic07Failure -Result $invalidWorkflow -Code 'AT-WORKFLOW-CLASS' -Scenario 'workflow class enum is exact'

    $unknownDecision = New-Topic07Decision
    $unknownDecision.extra = 'forbidden'
    $unknownResult = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07TaskRequest -LockedDecisions @($unknownDecision))
    Assert-Topic07Failure -Result $unknownResult -Code 'AT-SCHEMA-UNKNOWN-PROPERTY' -Scenario 'decision objects are closed'

    $duplicateResult = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07TaskRequest -LockedDecisions @(
            (New-Topic07Decision -Id 'D-001'), (New-Topic07Decision -Id 'D-001' -Statement 'Duplicate identity.')
        ))
    Assert-Topic07Failure -Result $duplicateResult -Code 'AT-DECISION-ID' -Scenario 'decision IDs are unique'

    $oversizeResult = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07TaskRequest -LockedDecisions @(
            (New-Topic07Decision -Statement ('x' * 2049))
        ))
    Assert-Topic07Failure -Result $oversizeResult -Code 'AT-DECISION-STRING' -Scenario 'decision strings are bounded'
    Assert-Topic07State (-not (Test-Path -LiteralPath (Join-Path $context.StateRoot 'tasks\T000001'))) 'Rejected create requests must not publish task authority.'

    $create = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07TaskRequest -WorkflowClass 'orchestrated' -LockedDecisions @(
            (New-Topic07Decision -Id 'D-020' -Statement 'Second ordinal decision.'),
            (New-Topic07Decision -Id 'D-003' -Statement 'First ordinal decision.')
        ))
    Assert-Topic07State ($create.ExitCode -eq 0) 'A valid continuity-aware task must be created.'
    $taskId = [string]$create.Parsed.data.task_id
    $authority = Get-Topic07TaskAuthority -Context $context -TaskId $taskId
    Assert-Topic07State ([string]$authority.Revision.workflow_class -ceq 'orchestrated') 'R000001 must store the workflow class.'
    Assert-Topic07State (@($authority.Revision.locked_decisions | ForEach-Object decision_id) -join ',' -ceq 'D-003,D-020') 'Locked decisions must be canonicalized in ordinal ID order.'
    Assert-Topic07State (Test-Path -LiteralPath (Join-Path $authority.Root 'supporting')) 'New task bundles must include the supporting-record directory.'

    $workUnit = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-work-unit' -SessionRef $owner -Runtime 'codex' -Request ([ordered]@{
            task_id = $taskId; work_unit_id = 'WU-LEGACY'; inputs = @('task contract'); outputs = @('projection')
            ownership = @('read-only'); dependencies = @(); completion_conditions = @('projection succeeds')
            expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
            expected_lease_generation = $authority.Revision.lease_generation
        })
    Assert-Topic07State ($workUnit.ExitCode -eq 0) 'The legacy fixture work unit must be created before conversion.'

    $authority = Get-Topic07TaskAuthority -Context $context -TaskId $taskId
    Convert-Topic07TaskToLegacy -TaskRoot $authority.Root
    $legacyAuthority = Get-Topic07TaskAuthority -Context $context -TaskId $taskId
    Assert-Topic07State (-not $legacyAuthority.Revision.Contains('workflow_class') -and -not $legacyAuthority.Revision.Contains('locked_decisions')) 'Legacy v1 task revisions must remain readable.'

    $status = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'status' -SessionRef 'codex:reader' -Runtime 'codex' -Request ([ordered]@{ task_id = $taskId })
    Assert-Topic07State ($status.ExitCode -eq 0) 'Status must remain available for legacy authority.'
    $projection = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'project-work-unit' -SessionRef 'codex:reader' -Runtime 'codex' -Request ([ordered]@{ task_id = $taskId; work_unit_id = 'WU-LEGACY' })
    Assert-Topic07State ($projection.ExitCode -eq 0) 'Read-only work-unit projection must remain available for legacy authority.'

    $legacyCounts = Get-Topic07StateCounts -TaskRoot $legacyAuthority.Root
    $blockedMutation = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'checkpoint' -SessionRef $owner -Runtime 'codex' -Request ([ordered]@{
            task_id = $taskId; kind = 'mandatory'; next_action = 'classify continuity'; blockers = @(); open_risks = @()
            expected_revision = $legacyAuthority.Revision.revision; expected_revision_sha256 = $legacyAuthority.RevisionSha256
            expected_lease_generation = $legacyAuthority.Revision.lease_generation
        })
    Assert-Topic07Failure -Result $blockedMutation -Code 'AT-CONTINUITY-CLASSIFICATION-REQUIRED' -Scenario 'legacy mutation is blocked pending classification'
    $afterBlocked = Get-Topic07StateCounts -TaskRoot $legacyAuthority.Root
    Assert-Topic07State ($afterBlocked.Revisions -eq $legacyCounts.Revisions -and $afterBlocked.Supporting -eq $legacyCounts.Supporting) 'Blocked legacy mutation must publish no revision or supporting record.'

    $initialize = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'set-continuity-contract' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07ContinuityRequest `
            -Authority $legacyAuthority -WorkflowClass 'standard' -LockedDecisions @((New-Topic07Decision -Id 'D-010')))
    Assert-Topic07State ($initialize.ExitCode -eq 0 -and $initialize.Parsed.data.continuity_change_id -ceq 'CC000001') 'Explicit CAS classification must initialize legacy continuity authority.'
    $initializedAuthority = Get-Topic07TaskAuthority -Context $context -TaskId $taskId
    Assert-Topic07State ($initializedAuthority.Revision.workflow_class -ceq 'standard' -and $initializedAuthority.Revision.supporting_refs[-1] -ceq 'CC000001') 'Classification must bind workflow and supporting record in one revision.'
    $cc1Path = Join-Path $initializedAuthority.Root 'supporting\CC000001.json'
    $cc1 = Read-AgentTasksJsonFile -LiteralPath $cc1Path
    Assert-Topic07State ($cc1.record_type -ceq 'continuity_contract_change' -and $null -eq $cc1.prior_workflow_class -and $cc1.new_workflow_class -ceq 'standard') 'The first supporting record must disclose legacy-to-current classification.'
    Assert-Topic07State ($cc1.record_hash -ceq (Get-AgentTasksSha256 -Value $cc1)) 'The continuity supporting record must be hash-valid.'

    $beforeRejected = Get-Topic07StateCounts -TaskRoot $initializedAuthority.Root
    $emptyAuthority = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'set-continuity-contract' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07ContinuityRequest -Authority $initializedAuthority -AuthorityRef ' ' -WorkflowClass 'quick')
    Assert-Topic07Failure -Result $emptyAuthority -Code 'AT-CONTINUITY-AUTHORITY' -Scenario 'authority reference is non-empty'
    $wrongOwner = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'set-continuity-contract' -SessionRef 'codex:not-owner' -Runtime 'codex' -Request (New-Topic07ContinuityRequest -Authority $initializedAuthority -WorkflowClass 'quick')
    Assert-Topic07Failure -Result $wrongOwner -Code 'AT-SESSION-OWNER' -Scenario 'only the owner session may reclassify'
    $wrongRuntime = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'set-continuity-contract' -SessionRef $owner -Runtime 'claude' -Request (New-Topic07ContinuityRequest -Authority $initializedAuthority -WorkflowClass 'quick')
    Assert-Topic07Failure -Result $wrongRuntime -Code 'AT-RUNTIME-OWNER' -Scenario 'only the owner runtime may reclassify'
    $staleRequest = New-Topic07ContinuityRequest -Authority $initializedAuthority -WorkflowClass 'quick'
    $staleRequest.expected_revision = 1
    $stale = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'set-continuity-contract' -SessionRef $owner -Runtime 'codex' -Request $staleRequest
    Assert-Topic07Failure -Result $stale -Code 'AT-CAS-REVISION' -Scenario 'stale revision is refused'
    $noOp = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'set-continuity-contract' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07ContinuityRequest `
            -Authority $initializedAuthority -WorkflowClass 'standard' -LockedDecisions @((New-Topic07Decision -Id 'D-010')))
    Assert-Topic07Failure -Result $noOp -Code 'AT-CONTINUITY-NOOP' -Scenario 'no-op classification is refused'
    $afterRejected = Get-Topic07StateCounts -TaskRoot $initializedAuthority.Root
    Assert-Topic07State ($afterRejected.Revisions -eq $beforeRejected.Revisions -and $afterRejected.Supporting -eq $beforeRejected.Supporting) 'Every rejected reclassification must leave authority unchanged.'

    $replace = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'set-continuity-contract' -SessionRef $owner -Runtime 'codex' -Request (New-Topic07ContinuityRequest `
            -Authority $initializedAuthority -WorkflowClass 'quick' -Reason 'User approved a bounded quick workflow.' -LockedDecisions @(
                (New-Topic07Decision -Id 'D-100' -Statement 'Keep the bounded recovery path.'),
                (New-Topic07Decision -Id 'D-002' -Statement 'Prefer the compact path.')
            ))
    Assert-Topic07State ($replace.ExitCode -eq 0 -and $replace.Parsed.data.continuity_change_id -ceq 'CC000002') 'A normal CAS reclassification must publish the next continuity record.'
    $replacedAuthority = Get-Topic07TaskAuthority -Context $context -TaskId $taskId
    Assert-Topic07State ($replacedAuthority.Revision.workflow_class -ceq 'quick') 'Normal reclassification must replace the workflow class.'
    Assert-Topic07State (@($replacedAuthority.Revision.locked_decisions | ForEach-Object decision_id) -join ',' -ceq 'D-002,D-100') 'Normal reclassification must replace and canonicalize locked decisions.'
    Assert-Topic07State (@($replacedAuthority.Revision.supporting_refs)[-1] -ceq 'CC000002') 'The new revision must bind the incremented supporting record.'

    Write-Host ("PASS Topic 07 state continuity contract ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-TOPIC07-STATE] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
