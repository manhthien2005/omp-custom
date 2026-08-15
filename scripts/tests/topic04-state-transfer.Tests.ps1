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
$evidencePath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Evidence.ps1'
$transferPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Transfer.ps1'
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'

if (-not (Test-Path -LiteralPath $transferPath -PathType Leaf)) {
    Write-Host 'FAIL [AT-TEST-TRANSFER-MISSING] Topic 04 transfer core is not installed.' -ForegroundColor Red
    exit 1
}

. $fixtureHelper
. $commonPath
. $storePath
. $gitPath
. $lifecyclePath
. $candidatePath
. $evidencePath
. $transferPath

$script:Assertions = 0

function Assert-Topic04Transfer {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic04TransferFailure {
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

function Invoke-Topic04TransferGit {
    param([Parameter(Mandatory)][string]$WorkingDirectory, [Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& git -C $WorkingDirectory @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git fixture command failed: $($output -join ' ')" }
    return ($output -join "`n").Trim()
}

function Get-Topic04TransferAuthority {
    param([Parameter(Mandatory)][object]$Context, [Parameter(Mandatory)][string]$TaskId)
    return Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
}

function New-Topic04TransferTask {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$SessionRef,
        [string]$Runtime = 'codex'
    )
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'create-task' -SessionRef $SessionRef -Runtime $Runtime -Request ([ordered]@{
            objective = 'Exercise checked ownership transfer.'
            authority = @('user')
            acceptance_criteria = @([ordered]@{ id = 'AC-001'; text = 'State transfer is exact.'; mandatory = $true })
            obligations = @()
            execution_mode = 'mutating'
            write_scope = @([ordered]@{ kind = 'subtree'; path = 'src' })
            owned_ignored_outputs = @()
            workflow_class = 'standard'
            locked_decisions = @()
        })
}

function Add-Topic04TransferCheckpoint {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$SessionRef,
        [string]$Kind = 'mandatory'
    )
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'checkpoint' -SessionRef $SessionRef -Request ([ordered]@{
            task_id = [string]$Authority.Contract.task_id
            kind = $Kind
            next_action = 'Continue from the durable state record.'
            blockers = @()
            open_risks = @('Revalidate workspace before mutation.')
            expected_revision = [long]$Authority.Revision.revision
            expected_revision_sha256 = [string]$Authority.RevisionSha256
            expected_lease_generation = [long]$Authority.Revision.lease_generation
        })
}

function Start-Topic04Transfer {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$Predecessor,
        [Parameter(Mandatory)][string]$Successor,
        [string]$SuccessorRuntime = 'codex'
    )
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'begin-handoff' -SessionRef $Predecessor -Request ([ordered]@{
            task_id = [string]$Authority.Contract.task_id
            successor_session_ref = $Successor
            successor_runtime = $SuccessorRuntime
            next_action = 'Reload authority and verify the exact workspace.'
            blockers = @()
            open_risks = @('Workspace may drift before acceptance.')
            expected_revision = [long]$Authority.Revision.revision
            expected_revision_sha256 = [string]$Authority.RevisionSha256
            expected_lease_generation = [long]$Authority.Revision.lease_generation
        })
}

function Complete-Topic04Transfer {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][object]$Handoff,
        [Parameter(Mandatory)][string]$SessionRef,
        [AllowNull()][long]$PredecessorRevision,
        [AllowNull()][string]$PredecessorRevisionSha256
    )
    $revision = if ($PSBoundParameters.ContainsKey('PredecessorRevision')) { $PredecessorRevision } else { [long]$Handoff.predecessor_revision }
    $sha = if ($PSBoundParameters.ContainsKey('PredecessorRevisionSha256')) { $PredecessorRevisionSha256 } else { [string]$Handoff.predecessor_revision_sha256 }
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'accept-handoff' -SessionRef $SessionRef -Request ([ordered]@{
            task_id = [string]$Authority.Contract.task_id
            handoff_id = [string]$Handoff.handoff_id
            predecessor_revision = [long]$revision
            predecessor_revision_sha256 = [string]$sha
            expected_revision = [long]$Authority.Revision.revision
            expected_revision_sha256 = [string]$Authority.RevisionSha256
            expected_lease_generation = [long]$Authority.Revision.lease_generation
        })
}

function Close-Topic04TransferTask {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$SessionRef
    )
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'close' -SessionRef $SessionRef -Request ([ordered]@{
            task_id = [string]$Authority.Contract.task_id
            terminal_status = 'cancelled'
            reason = 'Fixture complete.'
            expected_revision = [long]$Authority.Revision.revision
            expected_revision_sha256 = [string]$Authority.RevisionSha256
            expected_lease_generation = [long]$Authority.Revision.lease_generation
        })
}

function New-Topic04UserAuthorization {
    param([string]$Reason = 'The predecessor process is unavailable.')
    return [ordered]@{
        confirmed = $true
        authority = 'user'
        reason = $Reason
        observed_at = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [Globalization.CultureInfo]::InvariantCulture)
    }
}

try {
    $fixture = New-Topic04FixtureRoot -Label 'transfer-main'
    $repository = Initialize-Topic04GitFixture -Root $fixture
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository '.gitignore') -Content ".task/`n"
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "baseline`n"
    [void](Invoke-Topic04TransferGit -WorkingDirectory $repository -Arguments @('add', '.'))
    [void](Invoke-Topic04TransferGit -WorkingDirectory $repository -Arguments @('commit', '--quiet', '-m', 'transfer baseline'))

    $context = Resolve-AgentTasksContext -WorkingDirectory $repository
    $owner = 'codex:predecessor'
    $successor = 'codex:successor'
    $create = New-Topic04TransferTask -FixtureRoot $fixture -Repository $repository -SessionRef $owner
    Assert-Topic04Transfer ($create.ExitCode -eq 0) 'Transfer fixture task must be created.'
    $taskId = [string]$create.Parsed.data.task_id
    $authority = Get-Topic04TransferAuthority -Context $context -TaskId $taskId

    $withoutCheckpoint = Start-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $authority -Predecessor $owner -Successor $successor
    Assert-Topic04TransferFailure -Result $withoutCheckpoint -Code 'AT-HANDOFF-CHECKPOINT' -Scenario 'handoff without mandatory checkpoint'

    $checkpoint = Add-Topic04TransferCheckpoint -FixtureRoot $fixture -Repository $repository -Authority $authority -SessionRef $owner
    Assert-Topic04Transfer ($checkpoint.ExitCode -eq 0) 'Mandatory predecessor checkpoint must publish.'
    $authority = Get-Topic04TransferAuthority -Context $context -TaskId $taskId

    $prose = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'begin-handoff' -SessionRef $owner -Request ([ordered]@{
            task_id = $taskId; successor_session_ref = $successor; successor_runtime = 'codex'
            next_action = 'Read state.'; blockers = @(); open_risks = @(); handoff_prose = 'Trust this prose.'
            expected_revision = $authority.Revision.revision; expected_revision_sha256 = $authority.RevisionSha256
            expected_lease_generation = $authority.Revision.lease_generation
        })
    Assert-Topic04TransferFailure -Result $prose -Code 'AT-SCHEMA-UNKNOWN-PROPERTY' -Scenario 'model-authored handoff prose'

    $begin = Start-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $authority -Predecessor $owner -Successor $successor
    Assert-Topic04Transfer ($begin.ExitCode -eq 0 -and $begin.Parsed.data.handoff_id -ceq 'H000001') "Normal handoff must publish H000001 (exit=$($begin.ExitCode), code=$($begin.Parsed.code), stderr=$($begin.Stderr))."
    $transferring = Get-Topic04TransferAuthority -Context $context -TaskId $taskId
    $handoff = Read-AgentTasksJsonFile -LiteralPath (Join-Path $transferring.Root 'handoffs\H000001.json')
    Assert-Topic04Transfer (
        [string]$transferring.Revision.status -ceq 'transferring' -and
        [string]$transferring.Revision.owner_session_ref -ceq $owner -and
        [long]$transferring.Revision.lease_generation -eq 1
    ) 'Begin-handoff must retain predecessor ownership while marking the lease transferring.'
    Assert-Topic04Transfer (
        [string]$handoff.task_contract_hash -ceq (Get-AgentTasksSha256 -Value $transferring.Contract) -and
        [string]$handoff.authoritative_worktree -ceq [string]$transferring.Revision.authoritative_worktree -and
        [string]$handoff.checkpoint_id -ceq [string]$transferring.Revision.latest_checkpoint_id
    ) 'Handoff must bind the exact contract, worktree, and mandatory checkpoint.'

    $mutationDuringTransfer = Add-Topic04TransferCheckpoint -FixtureRoot $fixture -Repository $repository -Authority $transferring -SessionRef $owner
    Assert-Topic04TransferFailure -Result $mutationDuringTransfer -Code 'AT-TRANSFER-IN-PROGRESS' -Scenario 'unrelated mutation during transfer'

    $wrongSuccessor = Complete-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $transferring -Handoff $handoff -SessionRef 'codex:not-successor'
    Assert-Topic04TransferFailure -Result $wrongSuccessor -Code 'AT-HANDOFF-SUCCESSOR' -Scenario 'unnamed successor accepts handoff'
    $staleAccept = Complete-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $transferring -Handoff $handoff -SessionRef $successor `
        -PredecessorRevision ([long]$handoff.predecessor_revision - 1) -PredecessorRevisionSha256 ([string]$handoff.predecessor_revision_sha256)
    Assert-Topic04TransferFailure -Result $staleAccept -Code 'AT-HANDOFF-STALE' -Scenario 'stale predecessor identity'

    $accept = Complete-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $transferring -Handoff $handoff -SessionRef $successor
    Assert-Topic04Transfer ($accept.ExitCode -eq 0) "Named successor must accept an unchanged pre-candidate handoff (exit=$($accept.ExitCode), code=$($accept.Parsed.code), stderr=$($accept.Stderr))."
    $acceptedTransfer = Get-Topic04TransferAuthority -Context $context -TaskId $taskId
    Assert-Topic04Transfer (
        [string]$acceptedTransfer.Revision.status -ceq 'active' -and
        [string]$acceptedTransfer.Revision.owner_session_ref -ceq $successor -and
        [long]$acceptedTransfer.Revision.lease_generation -eq 2 -and
        [string]$acceptedTransfer.Revision.lease_status -ceq 'active'
    ) 'Accepted handoff must restore the prior status under a new lease generation.'
    Assert-Topic04Transfer (Test-Path -LiteralPath (Join-Path $acceptedTransfer.Root ('sessions\{0}.json' -f (Get-AgentTasksSha256 -Value $successor).Substring(0, 16)))) 'Handoff acceptance must publish successor session identity.'

    $predecessorClaim = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'claim' -SessionRef $owner -Request ([ordered]@{
            task_id = $taskId; expected_revision = $acceptedTransfer.Revision.revision
            expected_revision_sha256 = $acceptedTransfer.RevisionSha256
            expected_lease_generation = $acceptedTransfer.Revision.lease_generation
        })
    Assert-Topic04TransferFailure -Result $predecessorClaim -Code 'AT-SESSION-OWNER' -Scenario 'predecessor mutation after accepted handoff'
    $closedFirst = Close-Topic04TransferTask -FixtureRoot $fixture -Repository $repository -Authority $acceptedTransfer -SessionRef $successor
    Assert-Topic04Transfer ($closedFirst.ExitCode -eq 0) 'First transfer fixture must close.'

    $recoveryOwner = 'codex:recovery-predecessor'
    $recoverySuccessor = 'codex:recovery-successor'
    $createRecovery = New-Topic04TransferTask -FixtureRoot $fixture -Repository $repository -SessionRef $recoveryOwner
    Assert-Topic04Transfer ($createRecovery.ExitCode -eq 0) 'Recovery fixture task must be created.'
    $recoveryId = [string]$createRecovery.Parsed.data.task_id
    $recoveryAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $recoveryId
    $environmentEvidence = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'record-evidence' -SessionRef $recoveryOwner -Request ([ordered]@{
            task_id = $recoveryId; evidence_type = 'provider_environment'; producer = 'deterministic_probe'
            covered_ac_ids = @(); observation = [ordered]@{ status = 'PASS'; available = $true }
            validity_triggers = @([ordered]@{ kind = 'environment_change' })
            environment_fingerprint = [ordered]@{ runtime = 'pwsh'; version = $PSVersionTable.PSVersion.ToString(); platform = 'win32'; status = 'available' }
            expected_revision = $recoveryAuthority.Revision.revision; expected_revision_sha256 = $recoveryAuthority.RevisionSha256
            expected_lease_generation = $recoveryAuthority.Revision.lease_generation
        })
    Assert-Topic04Transfer ($environmentEvidence.ExitCode -eq 0) 'Recovery fixture must record uncertain environment evidence.'
    $recoveryAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $recoveryId
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "pre-handoff work`n"
    $recoveryCheckpoint = Add-Topic04TransferCheckpoint -FixtureRoot $fixture -Repository $repository -Authority $recoveryAuthority -SessionRef $recoveryOwner
    Assert-Topic04Transfer ($recoveryCheckpoint.ExitCode -eq 0) 'Recovery predecessor checkpoint must publish.'
    $recoveryAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $recoveryId
    $recoveryBegin = Start-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $recoveryAuthority -Predecessor $recoveryOwner -Successor $recoverySuccessor
    Assert-Topic04Transfer ($recoveryBegin.ExitCode -eq 0) 'Recovery fixture handoff must begin.'
    $recoveryAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $recoveryId
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "post-handoff drift`n"

    $elapsedClaim = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'claim' -SessionRef $recoverySuccessor -Request ([ordered]@{
            task_id = $recoveryId; expected_revision = $recoveryAuthority.Revision.revision
            expected_revision_sha256 = $recoveryAuthority.RevisionSha256
            expected_lease_generation = $recoveryAuthority.Revision.lease_generation
        })
    Assert-Topic04TransferFailure -Result $elapsedClaim -Code 'AT-SESSION-OWNER' -Scenario 'elapsed-time takeover'

    $currentSnapshot = Get-AgentTasksWorkspaceSnapshot -WorkingDirectory $repository -OwnedIgnoredOutputs @($recoveryAuthority.Contract.owned_ignored_outputs)
    $reconciliation = [ordered]@{
        workspace_snapshot_sha256 = Get-AgentTasksTransferWorkspaceHash -Snapshot $currentSnapshot
        disposition = 'validated_current_workspace'
    }
    $takeoverWithoutAuthority = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'takeover' -SessionRef $recoverySuccessor -Request ([ordered]@{
            task_id = $recoveryId; successor_session_ref = $recoverySuccessor; successor_runtime = 'codex'
            user_authorization = [ordered]@{ confirmed = $false; authority = 'user'; reason = 'No confirmation.'; observed_at = (Get-AgentTasksUtcTimestamp) }
            reconciliation = $reconciliation
            expected_revision = $recoveryAuthority.Revision.revision; expected_revision_sha256 = $recoveryAuthority.RevisionSha256
            expected_lease_generation = $recoveryAuthority.Revision.lease_generation
        })
    Assert-Topic04TransferFailure -Result $takeoverWithoutAuthority -Code 'AT-TAKEOVER-AUTHORITY' -Scenario 'takeover without explicit user authority'

    $takeoverWithWrongWorkspace = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'takeover' -SessionRef $recoverySuccessor -Request ([ordered]@{
            task_id = $recoveryId; successor_session_ref = $recoverySuccessor; successor_runtime = 'codex'
            user_authorization = New-Topic04UserAuthorization
            reconciliation = [ordered]@{ workspace_snapshot_sha256 = ('0' * 64); disposition = 'validated_current_workspace' }
            expected_revision = $recoveryAuthority.Revision.revision; expected_revision_sha256 = $recoveryAuthority.RevisionSha256
            expected_lease_generation = $recoveryAuthority.Revision.lease_generation
        })
    Assert-Topic04TransferFailure -Result $takeoverWithWrongWorkspace -Code 'AT-TAKEOVER-RECONCILIATION' -Scenario 'takeover with stale workspace reconciliation'

    $takeover = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'takeover' -SessionRef $recoverySuccessor -Request ([ordered]@{
            task_id = $recoveryId; successor_session_ref = $recoverySuccessor; successor_runtime = 'codex'
            user_authorization = New-Topic04UserAuthorization
            reconciliation = $reconciliation
            expected_revision = $recoveryAuthority.Revision.revision; expected_revision_sha256 = $recoveryAuthority.RevisionSha256
            expected_lease_generation = $recoveryAuthority.Revision.lease_generation
        })
    Assert-Topic04Transfer ($takeover.ExitCode -eq 0 -and $takeover.Parsed.data.handoff_id -ceq 'H000002') 'User-authorized takeover must publish a recovery handoff.'
    $takenOver = Get-Topic04TransferAuthority -Context $context -TaskId $recoveryId
    Assert-Topic04Transfer (
        [string]$takenOver.Revision.owner_session_ref -ceq $recoverySuccessor -and
        [long]$takenOver.Revision.lease_generation -eq 2 -and
        @($takenOver.Revision.invalidated_evidence_ids) -contains 'E000001'
    ) 'Takeover must transfer authority and invalidate uncertain prior evidence.'
    Assert-Topic04Transfer (([IO.File]::ReadAllText((Join-Path $repository 'src/output.txt'))) -ceq "post-handoff drift`n") 'Takeover must not reset, delete, or revert workspace bytes.'
    $closedRecovery = Close-Topic04TransferTask -FixtureRoot $fixture -Repository $repository -Authority $takenOver -SessionRef $recoverySuccessor
    Assert-Topic04Transfer ($closedRecovery.ExitCode -eq 0) 'Recovery fixture must close.'

    $candidateOwner = 'codex:candidate-predecessor'
    $candidateSuccessor = 'codex:candidate-successor'
    $candidateCreate = New-Topic04TransferTask -FixtureRoot $fixture -Repository $repository -SessionRef $candidateOwner
    $candidateId = [string]$candidateCreate.Parsed.data.task_id
    $candidateAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $candidateId
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "candidate transfer`n"
    $freeze = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'freeze' -SessionRef $candidateOwner -Request ([ordered]@{
            task_id = $candidateId; acceptance_inputs = @(); scope_dispositions = @()
            expected_revision = $candidateAuthority.Revision.revision; expected_revision_sha256 = $candidateAuthority.RevisionSha256
            expected_lease_generation = $candidateAuthority.Revision.lease_generation
        })
    Assert-Topic04Transfer ($freeze.ExitCode -eq 0 -and $freeze.Parsed.data.candidate_id -ceq 'C1') "Candidate transfer fixture must freeze C1 (exit=$($freeze.ExitCode), code=$($freeze.Parsed.code), stderr=$($freeze.Stderr))."
    $candidateAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $candidateId
    $candidateCheckpoint = Add-Topic04TransferCheckpoint -FixtureRoot $fixture -Repository $repository -Authority $candidateAuthority -SessionRef $candidateOwner
    Assert-Topic04Transfer ($candidateCheckpoint.ExitCode -eq 0) 'Candidate handoff still requires a mandatory checkpoint.'
    $candidateAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $candidateId
    $candidateBegin = Start-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $candidateAuthority -Predecessor $candidateOwner -Successor $candidateSuccessor
    Assert-Topic04Transfer ($candidateBegin.ExitCode -eq 0) 'Candidate-bound handoff must begin.'
    $candidateTransferring = Get-Topic04TransferAuthority -Context $context -TaskId $candidateId
    $candidateHandoff = Read-AgentTasksJsonFile -LiteralPath (Join-Path $candidateTransferring.Root 'handoffs\H000001.json')
    Assert-Topic04Transfer ([string]$candidateHandoff.candidate_hash -ceq [string]$freeze.Parsed.data.candidate_hash) 'Candidate handoff must bind the exact frozen candidate bytes.'
    $candidateAccept = Complete-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $candidateTransferring -Handoff $candidateHandoff -SessionRef $candidateSuccessor
    Assert-Topic04Transfer ($candidateAccept.ExitCode -eq 0) 'Unchanged candidate handoff must accept after rehash.'
    $candidateAccepted = Get-Topic04TransferAuthority -Context $context -TaskId $candidateId
    $candidateClose = Close-Topic04TransferTask -FixtureRoot $fixture -Repository $repository -Authority $candidateAccepted -SessionRef $candidateSuccessor
    Assert-Topic04Transfer ($candidateClose.ExitCode -eq 0) 'Candidate transfer fixture must close.'

    $locksRoot = Join-Path $context.StateRoot 'locks'
    $deadLockId = 'stale-owner'
    $deadLockPath = Join-Path $locksRoot ('task-{0}.lock' -f (ConvertTo-AgentTasksLockId -Id $deadLockId))
    [void](New-Item -ItemType Directory -Path $deadLockPath)
    [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $deadLockPath 'owner.json') -Value ([ordered]@{
        schema_version = 1; record_type = 'lock_owner'; created_at = '2000-01-01T00:00:00.000Z'
        host = [Environment]::MachineName; process_id = 2147483646; process_start_time = '2000-01-01T00:00:00.000Z'
    }))
    $workspaceHashBeforeRecovery = Get-AgentTasksSha256 -LiteralPath (Join-Path $repository 'src/output.txt')
    $lockWithoutAuthority = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'recover-lock' -SessionRef 'codex:lock-recovery' -Request ([ordered]@{
            lock_domain = 'task'; lock_id = $deadLockId
            user_authorization = [ordered]@{ confirmed = $false; authority = 'user'; reason = 'Not confirmed.'; observed_at = (Get-AgentTasksUtcTimestamp) }
        })
    Assert-Topic04TransferFailure -Result $lockWithoutAuthority -Code 'AT-LOCK-RECOVERY-AUTHORITY' -Scenario 'lock recovery without explicit user authority'
    $recoveredLock = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'recover-lock' -SessionRef 'codex:lock-recovery' -Request ([ordered]@{
            lock_domain = 'task'; lock_id = $deadLockId; user_authorization = New-Topic04UserAuthorization
        })
    Assert-Topic04Transfer ($recoveredLock.ExitCode -eq 0 -and -not (Test-Path -LiteralPath $deadLockPath)) 'Confirmed recovery must remove one exact stale lock.'
    Assert-Topic04Transfer ((Get-AgentTasksSha256 -LiteralPath (Join-Path $repository 'src/output.txt')) -ceq $workspaceHashBeforeRecovery) 'Lock recovery must not change workspace bytes.'

    $liveLockId = 'live-owner'
    $liveLockPath = Join-Path $locksRoot ('task-{0}.lock' -f (ConvertTo-AgentTasksLockId -Id $liveLockId))
    [void](New-Item -ItemType Directory -Path $liveLockPath)
    [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $liveLockPath 'owner.json') -Value ([ordered]@{
        schema_version = 1; record_type = 'lock_owner'; created_at = '2000-01-01T00:00:00.000Z'
        host = [Environment]::MachineName; process_id = $PID; process_start_time = Get-AgentTasksProcessStartTime
    }))
    $liveRecovery = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'recover-lock' -SessionRef 'codex:lock-recovery' -Request ([ordered]@{
            lock_domain = 'task'; lock_id = $liveLockId; user_authorization = New-Topic04UserAuthorization
        })
    Assert-Topic04TransferFailure -Result $liveRecovery -Code 'AT-LOCK-ACTIVE' -Scenario 'old lock whose exact process instance is alive'
    Assert-Topic04Transfer (Test-Path -LiteralPath $liveLockPath -PathType Container) 'Live lock must remain intact regardless of elapsed time.'

    $malformedLockId = 'malformed-owner'
    $malformedLockPath = Join-Path $locksRoot ('task-{0}.lock' -f (ConvertTo-AgentTasksLockId -Id $malformedLockId))
    [void](New-Item -ItemType Directory -Path $malformedLockPath)
    Set-Topic04Utf8File -LiteralPath (Join-Path $malformedLockPath 'owner.json') -Content "{}`n"
    $malformedRecovery = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'recover-lock' -SessionRef 'codex:lock-recovery' -Request ([ordered]@{
            lock_domain = 'task'; lock_id = $malformedLockId; user_authorization = New-Topic04UserAuthorization
        })
    Assert-Topic04TransferFailure -Result $malformedRecovery -Code 'AT-LOCK-OWNER' -Scenario 'malformed lock owner authority'
    Assert-Topic04Transfer (Test-Path -LiteralPath $malformedLockPath -PathType Container) 'Malformed lock authority must remain for manual inspection.'

    $remoteLockId = 'remote-owner'
    $remoteLockPath = Join-Path $locksRoot ('task-{0}.lock' -f (ConvertTo-AgentTasksLockId -Id $remoteLockId))
    [void](New-Item -ItemType Directory -Path $remoteLockPath)
    [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $remoteLockPath 'owner.json') -Value ([ordered]@{
        schema_version = 1; record_type = 'lock_owner'; created_at = '2000-01-01T00:00:00.000Z'
        host = 'unobservable-host'; process_id = 2147483646; process_start_time = '2000-01-01T00:00:00.000Z'
    }))
    $remoteRecovery = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'recover-lock' -SessionRef 'codex:lock-recovery' -Request ([ordered]@{
            lock_domain = 'task'; lock_id = $remoteLockId; user_authorization = New-Topic04UserAuthorization
        })
    Assert-Topic04TransferFailure -Result $remoteRecovery -Code 'AT-LOCK-LIVENESS' -Scenario 'lock owner on an unobservable host'

    $malformedOwner = 'codex:malformed-predecessor'
    $malformedSuccessor = 'codex:malformed-successor'
    $malformedCreate = New-Topic04TransferTask -FixtureRoot $fixture -Repository $repository -SessionRef $malformedOwner
    Assert-Topic04Transfer ($malformedCreate.ExitCode -eq 0) 'Malformed-handoff fixture task must be created.'
    $malformedTaskId = [string]$malformedCreate.Parsed.data.task_id
    $malformedAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $malformedTaskId
    $malformedCheckpoint = Add-Topic04TransferCheckpoint -FixtureRoot $fixture -Repository $repository -Authority $malformedAuthority -SessionRef $malformedOwner
    Assert-Topic04Transfer ($malformedCheckpoint.ExitCode -eq 0) 'Malformed-handoff fixture checkpoint must publish.'
    $malformedAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $malformedTaskId
    $malformedBegin = Start-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $malformedAuthority -Predecessor $malformedOwner -Successor $malformedSuccessor
    Assert-Topic04Transfer ($malformedBegin.ExitCode -eq 0) 'Malformed-handoff fixture must begin transfer.'
    $malformedAuthority = Get-Topic04TransferAuthority -Context $context -TaskId $malformedTaskId
    $malformedHandoffPath = Join-Path $malformedAuthority.Root 'handoffs\H000001.json'
    $malformedHandoff = Read-AgentTasksJsonFile -LiteralPath $malformedHandoffPath
    $malformedHandoff.next_action = 'Tampered after publication.'
    Set-Topic04Utf8File -LiteralPath $malformedHandoffPath -Content (($malformedHandoff | ConvertTo-Json -Depth 64 -Compress) + "`n")
    $tamperedAccept = Complete-Topic04Transfer -FixtureRoot $fixture -Repository $repository -Authority $malformedAuthority -Handoff $malformedHandoff -SessionRef $malformedSuccessor
    Assert-Topic04TransferFailure -Result $tamperedAccept -Code 'AT-HANDOFF-STALE' -Scenario 'tampered immutable handoff record'

    Write-Host ("PASS Topic 04 state transfer ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-TRANSFER] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
