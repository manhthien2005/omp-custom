#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RequestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$operation = 'unknown'
try {
    . (Join-Path $PSScriptRoot 'lib\AgentTasks.Common.ps1')
    . (Join-Path $PSScriptRoot 'lib\AgentTasks.Store.ps1')
    $gitModule = Join-Path $PSScriptRoot 'lib\AgentTasks.Git.ps1'
    $lifecycleModule = Join-Path $PSScriptRoot 'lib\AgentTasks.Lifecycle.ps1'
    $candidateModule = Join-Path $PSScriptRoot 'lib\AgentTasks.Candidate.ps1'
    $evidenceModule = Join-Path $PSScriptRoot 'lib\AgentTasks.Evidence.ps1'
    $projectionModule = Join-Path $PSScriptRoot 'lib\AgentTasks.Projection.ps1'
    $transferModule = Join-Path $PSScriptRoot 'lib\AgentTasks.Transfer.ps1'
    $retentionModule = Join-Path $PSScriptRoot 'lib\AgentTasks.Retention.ps1'
    if (Test-Path -LiteralPath $gitModule -PathType Leaf) { . $gitModule }
    if (Test-Path -LiteralPath $lifecycleModule -PathType Leaf) { . $lifecycleModule }
    if (Test-Path -LiteralPath $candidateModule -PathType Leaf) { . $candidateModule }
    if (Test-Path -LiteralPath $evidenceModule -PathType Leaf) { . $evidenceModule }
    if (Test-Path -LiteralPath $projectionModule -PathType Leaf) { . $projectionModule }
    if (Test-Path -LiteralPath $transferModule -PathType Leaf) { . $transferModule }
    if (Test-Path -LiteralPath $retentionModule -PathType Leaf) { . $retentionModule }

    $envelope = Read-AgentTasksEnvelope -Path $RequestPath
    $operation = [string]$envelope.operation
    $context = Resolve-AgentTasksContext -WorkingDirectory ([string]$envelope.working_directory)
    if ($operation -notin @('status', 'project-work-unit', 'project-continuity', 'migrate')) {
        Assert-AgentTasksRootMutationAllowed -Context $context
    }
    switch -CaseSensitive ($operation) {
        'init-project' {
            $initialized = Initialize-AgentTasksProject -Context $context -DisplayName ([string]$envelope.request.display_name)
            $data = [ordered]@{
                project_id = [string]$initialized.Identity.project_id
                state_root = [string]$context.StateRoot
                revision = [long]$initialized.Revision.revision
                existing = [bool]$initialized.Existing
            }
        }
        'status' {
            $data = Get-AgentTasksStatus -Context $context
        }
        'create-phase' {
            $data = Initialize-AgentTasksPhase -Context $context -Request $envelope.request
        }
        'transition-phase' {
            $data = Set-AgentTasksPhaseStatus -Context $context -Request $envelope.request
        }
        'create-task' {
            $data = New-AgentTasksTask -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref) -Runtime ([string]$envelope.runtime)
        }
        'set-continuity-contract' {
            $data = Set-AgentTasksContinuityContract -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref) -Runtime ([string]$envelope.runtime)
        }
        'bind-worktree' {
            $data = Bind-AgentTasksWorktree -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'checkpoint' {
            $mutation = Add-AgentTasksCheckpoint -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
            $data = [ordered]@{
                task_id = [string]$envelope.request.task_id
                revision = [long]$mutation.Revision.revision
                revision_sha256 = [string]$mutation.RevisionSha256
                checkpoint_id = [string]$mutation.Revision.latest_checkpoint_id
            }
        }
        'claim' {
            $data = Claim-AgentTasksTask -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'create-work-unit' {
            $mutation = New-AgentTasksWorkUnit -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
            $data = [ordered]@{
                task_id = [string]$envelope.request.task_id
                work_unit_id = [string]$envelope.request.work_unit_id
                revision = [long]$mutation.Revision.revision
                revision_sha256 = [string]$mutation.RevisionSha256
            }
        }
        'project-work-unit' {
            $data = Get-AgentTasksWorkUnitProjection -Context $context `
                -TaskId ([string]$envelope.request.task_id) `
                -WorkUnitId ([string]$envelope.request.work_unit_id)
        }
        'project-continuity' {
            $data = Get-AgentTasksContinuityProjection -Context $context `
                -SessionRef ([string]$envelope.session_ref) -Runtime ([string]$envelope.runtime)
        }
        'record-work-unit-outcome' {
            $mutation = Add-AgentTasksWorkUnitOutcome -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
            $data = [ordered]@{
                task_id = [string]$envelope.request.task_id
                work_unit_id = [string]$envelope.request.work_unit_id
                revision = [long]$mutation.Revision.revision
                revision_sha256 = [string]$mutation.RevisionSha256
            }
        }
        'freeze' {
            $data = New-AgentTasksFrozenCandidate -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'check' {
            $data = Test-AgentTasksCandidate -Context $context -TaskId ([string]$envelope.request.task_id) `
                -CandidateId ([string]$envelope.request.candidate_id)
        }
        'promote-artifact' {
            $data = Copy-AgentTasksPromotedArtifact -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'record-evidence' {
            $data = Add-AgentTasksEvidence -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'begin-handoff' {
            $data = Start-AgentTasksHandoff -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'accept-handoff' {
            $data = Complete-AgentTasksHandoff -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'takeover' {
            $data = Invoke-AgentTasksTakeover -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'close' {
            $data = Set-AgentTasksTerminalState -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'invalidate' {
            $data = Invalidate-AgentTasksHistory -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'cleanup' {
            $mode = if ($envelope.request.Contains('mode')) { [string]$envelope.request.mode } else { 'dry-run' }
            if ($mode -ceq 'dry-run') {
                $data = Get-AgentTasksCleanupPlan -Context $context -TaskId ([string]$envelope.request.task_id) -Mode $mode
            } elseif ($mode -ceq 'apply') {
                $data = Move-AgentTasksTaskToTrash -Context $context -TaskId ([string]$envelope.request.task_id)
            } else {
                Throw-AgentTasksError -Code 'AT-CLEANUP-MODE' -ExitCode 2 -SafeMessage 'Cleanup mode must be dry-run or apply.'
            }
        }
        'restore' {
            $data = Restore-AgentTasksTask -Context $context -TaskId ([string]$envelope.request.task_id)
        }
        'purge' {
            $data = Remove-AgentTasksPurgedTask -Context $context -TaskId ([string]$envelope.request.task_id) `
                -Confirmation ([string]$envelope.request.confirmation)
        }
        'recover-lock' {
            $data = Repair-AgentTasksLock -Context $context -Request $envelope.request `
                -SessionRef ([string]$envelope.session_ref)
        }
        'migrate' {
            $data = Invoke-AgentTasksMigration -Context $context -Request $envelope.request
        }
        default {
            Throw-AgentTasksError -Code 'AT-OPERATION-UNKNOWN' -ExitCode 2 -SafeMessage 'The requested operation is not part of the v1 protocol.'
        }
    }

    $result = New-AgentTasksResult -Ok $true -Code 'AT-OK' -Operation $operation -Data $data
    [Console]::Out.WriteLine((ConvertTo-AgentTasksCanonicalJson -Value $result))
    exit 0
} catch {
    if (-not (Get-Command ConvertTo-AgentTasksFailure -ErrorAction SilentlyContinue)) {
        [Console]::Out.WriteLine('{"code":"AT-INTERNAL","data":{"message":"An unexpected internal error occurred."},"ok":false,"operation":"unknown"}')
        [Console]::Error.WriteLine('AT-INTERNAL')
        exit 5
    }
    $failure = ConvertTo-AgentTasksFailure -Exception $_.Exception -Operation $operation
    [Console]::Out.WriteLine((ConvertTo-AgentTasksCanonicalJson -Value $failure.Result))
    [Console]::Error.WriteLine($failure.Diagnostic)
    exit $failure.ExitCode
}
