#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtureHelper = Join-Path $repositoryRoot 'scripts\lib\topic04-test-fixtures.ps1'
$stateRoot = Join-Path $repositoryRoot 'template\.omp\state'
$cliPath = Join-Path $stateRoot 'agent-tasks.ps1'

. $fixtureHelper
. (Join-Path $stateRoot 'lib\AgentTasks.Common.ps1')
. (Join-Path $stateRoot 'lib\AgentTasks.Store.ps1')
. (Join-Path $stateRoot 'lib\AgentTasks.Git.ps1')
. (Join-Path $stateRoot 'lib\AgentTasks.Lifecycle.ps1')

$script:Assertions = 0

function Assert-Topic04E2E {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic04E2EFailure {
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

function Invoke-Topic04E2EGit {
    param([Parameter(Mandatory)][string]$Repository, [Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& git -C $Repository @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git fixture command failed: $($output -join ' ')" }
}

function Get-Topic04E2EAuthority {
    param([Parameter(Mandatory)][object]$Context, [Parameter(Mandatory)][string]$TaskId)
    return Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
}

function New-Topic04E2ETaskRequest {
    param(
        [Parameter(Mandatory)][string]$Objective,
        [string]$ExecutionMode = 'mutating',
        [string[]]$Obligations = @(),
        [object[]]$WriteScope = @()
    )
    return [ordered]@{
        objective = $Objective
        authority = @('user')
        acceptance_criteria = @(
            [ordered]@{ id = 'AC-001'; text = 'The exact candidate passes its deterministic check.'; mandatory = $true }
        )
        obligations = @($Obligations)
        execution_mode = $ExecutionMode
        write_scope = @($WriteScope)
        owned_ignored_outputs = @()
        workflow_class = 'standard'
        locked_decisions = @()
    }
}

function Freeze-Topic04E2ECandidate {
    param(
        [Parameter(Mandatory)][string]$Fixture,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$SessionRef
    )
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $Fixture -WorkingDirectory $Repository `
        -Operation 'freeze' -SessionRef $SessionRef -Request ([ordered]@{
            task_id = [string]$Authority.Contract.task_id
            acceptance_inputs = @([ordered]@{ path = 'config/contract.json'; role = 'contract_input' })
            scope_dispositions = @()
            expected_revision = [long]$Authority.Revision.revision
            expected_revision_sha256 = [string]$Authority.RevisionSha256
            expected_lease_generation = [long]$Authority.Revision.lease_generation
        })
}

function Get-Topic04E2EInputHashes {
    param([Parameter(Mandatory)][object]$Authority, [Parameter(Mandatory)][string]$CandidateId)
    $candidate = Read-AgentTasksJsonFile -LiteralPath (Join-Path $Authority.Root (Join-Path 'candidates' ($CandidateId + '.json')))
    return @($candidate.acceptance_inputs | ForEach-Object {
        [ordered]@{ path = [string]$_.path; sha256 = [string]$_.sha256 }
    })
}

function Add-Topic04E2ETestEvidence {
    param(
        [Parameter(Mandatory)][string]$Fixture,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$CandidateId,
        [Parameter(Mandatory)][string]$SessionRef
    )
    $inputHashes = Get-Topic04E2EInputHashes -Authority $Authority -CandidateId $CandidateId
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $Fixture -WorkingDirectory $Repository `
        -Operation 'record-evidence' -SessionRef $SessionRef -Request ([ordered]@{
            task_id = [string]$Authority.Contract.task_id
            evidence_type = 'test'
            producer = 'deterministic_runner'
            candidate_id = $CandidateId
            covered_ac_ids = @('AC-001')
            observation = [ordered]@{ status = 'PASS'; total = 1; failed = 0 }
            validity_triggers = @(
                [ordered]@{ kind = 'candidate_drift' },
                [ordered]@{ kind = 'acceptance_input_drift' }
            )
            acceptance_input_hashes = $inputHashes
            expected_revision = [long]$Authority.Revision.revision
            expected_revision_sha256 = [string]$Authority.RevisionSha256
            expected_lease_generation = [long]$Authority.Revision.lease_generation
        })
}

function Close-Topic04E2ETask {
    param(
        [Parameter(Mandatory)][string]$Fixture,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$SessionRef,
        [Parameter(Mandatory)][string]$TerminalStatus,
        [AllowNull()][string]$CandidateId = $null,
        [AllowNull()][string]$Reason = $null
    )
    $request = [ordered]@{
        task_id = [string]$Authority.Contract.task_id
        terminal_status = $TerminalStatus
        expected_revision = [long]$Authority.Revision.revision
        expected_revision_sha256 = [string]$Authority.RevisionSha256
        expected_lease_generation = [long]$Authority.Revision.lease_generation
    }
    if ($CandidateId) { $request.candidate_id = $CandidateId }
    if ($Reason) { $request.reason = $Reason }
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $Fixture -WorkingDirectory $Repository `
        -Operation 'close' -SessionRef $SessionRef -Request $request
}

try {
    $fixture = New-Topic04FixtureRoot -Label 'e2e'
    $repository = Initialize-Topic04GitFixture -Root $fixture
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "baseline`n"
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'config/contract.json') -Content "{`"version`":1}`n"
    Invoke-Topic04E2EGit -Repository $repository -Arguments @('add', '.')
    Invoke-Topic04E2EGit -Repository $repository -Arguments @('commit', '--quiet', '-m', 'e2e baseline')

    $owner = 'codex:e2e-owner'
    $create = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $owner -Request (
            New-Topic04E2ETaskRequest -Objective 'Exercise the complete accepted lifecycle.' `
                -Obligations @('test') -WriteScope @([ordered]@{ kind = 'subtree'; path = 'src' })
        )
    Assert-Topic04E2E ($create.ExitCode -eq 0) 'T1 mutating task must be created.'
    $context = Resolve-AgentTasksContext -WorkingDirectory $repository
    $taskId = [string]$create.Parsed.data.task_id

    $reader = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef 'codex:e2e-reader' -Request (
            New-Topic04E2ETaskRequest -Objective 'Observe without reserving a writer.' -ExecutionMode 'read_only'
        )
    Assert-Topic04E2E ($reader.ExitCode -eq 0) 'T2 read-only task may share the observation worktree.'

    $conflict = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef 'codex:e2e-conflict' -Request (
            New-Topic04E2ETaskRequest -Objective 'Illegal second writer.' `
                -WriteScope @([ordered]@{ kind = 'subtree'; path = 'docs' })
        )
    Assert-Topic04E2EFailure $conflict 'AT-WORKTREE-CONFLICT' 'second writer on T1 worktree'

    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "candidate one`n"
    $authority = Get-Topic04E2EAuthority -Context $context -TaskId $taskId
    $freezeOne = Freeze-Topic04E2ECandidate -Fixture $fixture -Repository $repository -Authority $authority -SessionRef $owner
    Assert-Topic04E2E ($freezeOne.ExitCode -eq 0 -and $freezeOne.Parsed.data.candidate_id -ceq 'C1') 'First freeze must publish C1.'

    $authority = Get-Topic04E2EAuthority -Context $context -TaskId $taskId
    $evidenceOne = Add-Topic04E2ETestEvidence -Fixture $fixture -Repository $repository -Authority $authority -CandidateId 'C1' -SessionRef $owner
    Assert-Topic04E2E ($evidenceOne.ExitCode -eq 0) 'C1 deterministic evidence must publish.'

    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "candidate two`n"
    $drift = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'check' -SessionRef $owner -Request ([ordered]@{ task_id = $taskId; candidate_id = 'C1' })
    Assert-Topic04E2EFailure $drift 'AT-CANDIDATE-DRIFT' 'C1 mutation'

    $authority = Get-Topic04E2EAuthority -Context $context -TaskId $taskId
    $freezeTwo = Freeze-Topic04E2ECandidate -Fixture $fixture -Repository $repository -Authority $authority -SessionRef $owner
    Assert-Topic04E2E ($freezeTwo.ExitCode -eq 0 -and $freezeTwo.Parsed.data.candidate_id -ceq 'C2') 'Refreeze must publish C2.'

    $authority = Get-Topic04E2EAuthority -Context $context -TaskId $taskId
    $staleClose = Close-Topic04E2ETask -Fixture $fixture -Repository $repository -Authority $authority `
        -SessionRef $owner -TerminalStatus 'accepted' -CandidateId 'C2'
    Assert-Topic04E2EFailure $staleClose 'AT-ACCEPTANCE-EVIDENCE' 'C1 evidence cannot satisfy C2'

    $evidenceTwo = Add-Topic04E2ETestEvidence -Fixture $fixture -Repository $repository -Authority $authority -CandidateId 'C2' -SessionRef $owner
    Assert-Topic04E2E ($evidenceTwo.ExitCode -eq 0) 'Fresh C2 deterministic evidence must publish.'
    $authority = Get-Topic04E2EAuthority -Context $context -TaskId $taskId
    $accepted = Close-Topic04E2ETask -Fixture $fixture -Repository $repository -Authority $authority `
        -SessionRef $owner -TerminalStatus 'accepted' -CandidateId 'C2'
    Assert-Topic04E2E ($accepted.ExitCode -eq 0 -and $accepted.Parsed.data.status -ceq 'accepted') 'Fully evidenced C2 must close accepted.'

    $handoffOwner = 'claude:e2e-owner'
    $handoffSuccessor = 'codex:e2e-successor'
    $handoffTask = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-task' -SessionRef $handoffOwner -Runtime 'claude' -Request (
            New-Topic04E2ETaskRequest -Objective 'Exercise a checked handoff and retention.' `
                -WriteScope @([ordered]@{ kind = 'subtree'; path = 'docs' })
        )
    Assert-Topic04E2E ($handoffTask.ExitCode -eq 0) 'Separate handoff task must be created after T1 closes.'
    $handoffTaskId = [string]$handoffTask.Parsed.data.task_id
    $handoffAuthority = Get-Topic04E2EAuthority -Context $context -TaskId $handoffTaskId

    $checkpoint = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'checkpoint' -SessionRef $handoffOwner -Runtime 'claude' -Request ([ordered]@{
            task_id = $handoffTaskId; kind = 'mandatory'; next_action = 'Accept the structured handoff.'
            blockers = @(); open_risks = @()
            expected_revision = [long]$handoffAuthority.Revision.revision
            expected_revision_sha256 = [string]$handoffAuthority.RevisionSha256
            expected_lease_generation = [long]$handoffAuthority.Revision.lease_generation
        })
    Assert-Topic04E2E ($checkpoint.ExitCode -eq 0) 'Mandatory handoff checkpoint must publish.'
    $handoffAuthority = Get-Topic04E2EAuthority -Context $context -TaskId $handoffTaskId

    $begin = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'begin-handoff' -SessionRef $handoffOwner -Runtime 'claude' -Request ([ordered]@{
            task_id = $handoffTaskId; successor_session_ref = $handoffSuccessor; successor_runtime = 'codex'
            next_action = 'Reload authority and continue.'; blockers = @(); open_risks = @()
            expected_revision = [long]$handoffAuthority.Revision.revision
            expected_revision_sha256 = [string]$handoffAuthority.RevisionSha256
            expected_lease_generation = [long]$handoffAuthority.Revision.lease_generation
        })
    Assert-Topic04E2E ($begin.ExitCode -eq 0) 'Handoff begin must publish an immutable transfer.'
    $handoffAuthority = Get-Topic04E2EAuthority -Context $context -TaskId $handoffTaskId
    $handoff = Read-AgentTasksJsonFile -LiteralPath (Join-Path $handoffAuthority.Root (Join-Path 'handoffs' ([string]$begin.Parsed.data.handoff_id + '.json')))

    $accept = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'accept-handoff' -SessionRef $handoffSuccessor -Request ([ordered]@{
            task_id = $handoffTaskId; handoff_id = [string]$handoff.handoff_id
            predecessor_revision = [long]$handoff.predecessor_revision
            predecessor_revision_sha256 = [string]$handoff.predecessor_revision_sha256
            expected_revision = [long]$handoffAuthority.Revision.revision
            expected_revision_sha256 = [string]$handoffAuthority.RevisionSha256
            expected_lease_generation = [long]$handoffAuthority.Revision.lease_generation
        })
    Assert-Topic04E2E ($accept.ExitCode -eq 0) 'Named successor must accept the unchanged handoff.'

    $handoffAuthority = Get-Topic04E2EAuthority -Context $context -TaskId $handoffTaskId
    $cancelled = Close-Topic04E2ETask -Fixture $fixture -Repository $repository -Authority $handoffAuthority `
        -SessionRef $handoffSuccessor -TerminalStatus 'cancelled' -Reason 'E2E handoff complete.'
    Assert-Topic04E2E ($cancelled.ExitCode -eq 0) 'Handoff task must close terminal before retention.'

    $dryRun = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'cleanup' -SessionRef $handoffSuccessor -Request ([ordered]@{ task_id = $handoffTaskId })
    Assert-Topic04E2E ($dryRun.ExitCode -eq 0 -and $dryRun.Parsed.data.mode -ceq 'dry-run') 'Cleanup must preview without mutation.'
    $archive = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'cleanup' -SessionRef $handoffSuccessor -Request ([ordered]@{ task_id = $handoffTaskId; mode = 'apply' })
    Assert-Topic04E2E ($archive.ExitCode -eq 0 -and $archive.Parsed.data.archived) 'Cleanup apply must archive to recoverable trash.'
    $restore = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'restore' -SessionRef $handoffSuccessor -Request ([ordered]@{ task_id = $handoffTaskId })
    Assert-Topic04E2E ($restore.ExitCode -eq 0 -and $restore.Parsed.data.restored) 'Restore must recover the archived authority.'

    [pscustomobject]@{
        status = 'PASS'
        assertions = $script:Assertions
        c1_hash = [string]$freezeOne.Parsed.data.candidate_hash
        c2_hash = [string]$freezeTwo.Parsed.data.candidate_hash
        c1_evidence_result = [string]$evidenceOne.Parsed.code
        c2_evidence_result = [string]$evidenceTwo.Parsed.code
        stale_c2_acceptance_result = [string]$staleClose.Parsed.code
        handoff_result = [string]$accept.Parsed.code
        archive_result = [string]$archive.Parsed.code
        restore_result = [string]$restore.Parsed.code
    } | ConvertTo-Json -Compress
    exit 0
} catch {
    Write-Host ("FAIL [AT-E2E] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
