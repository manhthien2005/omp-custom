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
$retentionPath = Join-Path $repositoryRoot 'template\.omp\state\lib\AgentTasks.Retention.ps1'
$cliPath = Join-Path $repositoryRoot 'template\.omp\state\agent-tasks.ps1'

if (-not (Test-Path -LiteralPath $retentionPath -PathType Leaf)) {
    Write-Host 'FAIL [AT-TEST-RETENTION-MISSING] Topic 04 retention core is not installed.' -ForegroundColor Red
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
. $retentionPath

$script:Assertions = 0

function Assert-Topic04Retention {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Topic04RetentionFailure {
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

function Invoke-Topic04RetentionGit {
    param([Parameter(Mandatory)][string]$WorkingDirectory, [Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& git -C $WorkingDirectory @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git fixture command failed: $($output -join ' ')" }
    return ($output -join "`n").Trim()
}

function Get-Topic04RetentionManifest {
    param([Parameter(Mandatory)][string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return @() }
    return @(
        Get-ChildItem -LiteralPath $Root -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
            [ordered]@{
                path = [IO.Path]::GetRelativePath($Root, $_.FullName).Replace('\', '/')
                sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                length = [long]$_.Length
            }
        }
    )
}

function New-Topic04RetentionTask {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$SessionRef,
        [AllowNull()][string]$PhaseId = $null
    )
    $request = [ordered]@{
        objective = 'Exercise recoverable retention.'
        authority = @('user')
        acceptance_criteria = @([ordered]@{ id = 'AC-001'; text = 'Retention is safe.'; mandatory = $true })
        obligations = @()
        execution_mode = 'mutating'
        write_scope = @([ordered]@{ kind = 'subtree'; path = 'src' })
        owned_ignored_outputs = @()
        workflow_class = 'standard'
        locked_decisions = @()
    }
    if ($PhaseId) { $request.phase_id = $PhaseId }
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'create-task' -SessionRef $SessionRef -Request $request
}

function Close-Topic04RetentionTask {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][object]$Authority,
        [Parameter(Mandatory)][string]$SessionRef
    )
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'close' -SessionRef $SessionRef -Request ([ordered]@{
            task_id = [string]$Authority.Contract.task_id; terminal_status = 'cancelled'; reason = 'Fixture complete.'
            expected_revision = [long]$Authority.Revision.revision; expected_revision_sha256 = [string]$Authority.RevisionSha256
            expected_lease_generation = [long]$Authority.Revision.lease_generation
        })
}

function Invoke-Topic04Cleanup {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$TaskId,
        [AllowNull()][string]$Mode = $null
    )
    $request = [ordered]@{ task_id = $TaskId }
    if ($Mode) { $request.mode = $Mode }
    return Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $FixtureRoot -WorkingDirectory $Repository `
        -Operation 'cleanup' -SessionRef 'codex:retention' -Request $request
}

try {
    $fixture = New-Topic04FixtureRoot -Label 'retention-main'
    $repository = Initialize-Topic04GitFixture -Root $fixture
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'src/output.txt') -Content "baseline`n"
    [void](Invoke-Topic04RetentionGit -WorkingDirectory $repository -Arguments @('add', '.'))
    [void](Invoke-Topic04RetentionGit -WorkingDirectory $repository -Arguments @('commit', '--quiet', '-m', 'retention baseline'))
    $context = Resolve-AgentTasksContext -WorkingDirectory $repository

    $owner = 'codex:retention-owner'
    $create = New-Topic04RetentionTask -FixtureRoot $fixture -Repository $repository -SessionRef $owner
    Assert-Topic04Retention ($create.ExitCode -eq 0) 'Retention fixture task must be created.'
    $taskId = [string]$create.Parsed.data.task_id
    $authority = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId $taskId

    $activeCleanup = Invoke-Topic04Cleanup -FixtureRoot $fixture -Repository $repository -TaskId $taskId -Mode 'apply'
    Assert-Topic04RetentionFailure -Result $activeCleanup -Code 'AT-CLEANUP-BLOCKED' -Scenario 'archive active task'
    $close = Close-Topic04RetentionTask -FixtureRoot $fixture -Repository $repository -Authority $authority -SessionRef $owner
    Assert-Topic04Retention ($close.ExitCode -eq 0) 'Retention fixture task must become terminal.'

    $beforeDryRun = @(Get-Topic04RetentionManifest -Root $context.StateRoot)
    $dryRun = Invoke-Topic04Cleanup -FixtureRoot $fixture -Repository $repository -TaskId $taskId
    Assert-Topic04Retention (
        $dryRun.ExitCode -eq 0 -and $dryRun.Parsed.data.mode -ceq 'dry-run' -and $dryRun.Parsed.data.eligible
    ) 'Cleanup must default to an eligible dry-run for a terminal standalone task.'
    $afterDryRun = @(Get-Topic04RetentionManifest -Root $context.StateRoot)
    Assert-Topic04Retention ((ConvertTo-AgentTasksCanonicalJson -Value $beforeDryRun) -ceq (ConvertTo-AgentTasksCanonicalJson -Value $afterDryRun)) 'Cleanup dry-run must change no authority bytes.'
    Assert-Topic04Retention (
        [string]$dryRun.Parsed.data.source_path -ceq (Join-Path $context.StateRoot (Join-Path 'tasks' $taskId)) -and
        [string]$dryRun.Parsed.data.target_path -ceq (Join-Path $context.StateRoot (Join-Path 'trash' $taskId)) -and
        [long]$dryRun.Parsed.data.estimated_bytes -gt 0
    ) 'Cleanup plan must report exact paths and estimated bytes.'

    $archive = Invoke-Topic04Cleanup -FixtureRoot $fixture -Repository $repository -TaskId $taskId -Mode 'apply'
    Assert-Topic04Retention ($archive.ExitCode -eq 0 -and $archive.Parsed.data.archived) 'Cleanup apply must move the exact terminal task to trash.'
    Assert-Topic04Retention (
        -not (Test-Path -LiteralPath (Join-Path $context.StateRoot (Join-Path 'tasks' $taskId))) -and
        (Test-Path -LiteralPath (Join-Path $context.StateRoot (Join-Path 'trash' $taskId)) -PathType Container)
    ) 'Archive must leave one recoverable trash authority.'
    $trashedAuthority = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId $taskId
    Assert-Topic04Retention ([string]$trashedAuthority.Revision.status -ceq 'cancelled') 'Task identity must remain resolvable from trash.'

    $duplicateActive = Join-Path $context.StateRoot (Join-Path 'tasks' $taskId)
    Copy-Item -LiteralPath (Join-Path $context.StateRoot (Join-Path 'trash' $taskId)) -Destination $duplicateActive -Recurse
    $duplicateStatus = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'status' -Request ([ordered]@{})
    Assert-Topic04RetentionFailure -Result $duplicateStatus -Code 'AT-TASK-DUPLICATE' -Scenario 'duplicate active and trash task ID'
    $duplicateRestore = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'restore' -Request ([ordered]@{ task_id = $taskId })
    Assert-Topic04RetentionFailure -Result $duplicateRestore -Code 'AT-TASK-DUPLICATE' -Scenario 'restore over duplicate active task ID'
    Remove-Item -LiteralPath $duplicateActive -Recurse -Force

    $restore = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository -Operation 'restore' -Request ([ordered]@{ task_id = $taskId })
    Assert-Topic04Retention ($restore.ExitCode -eq 0 -and $restore.Parsed.data.restored) 'Restore must reverse the exact archive move.'
    $rearchive = Invoke-Topic04Cleanup -FixtureRoot $fixture -Repository $repository -TaskId $taskId -Mode 'apply'
    Assert-Topic04Retention ($rearchive.ExitCode -eq 0) 'Restored terminal task must be archivable again.'

    $wrongPurge = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'purge' -Request ([ordered]@{ task_id = $taskId; confirmation = ($taskId + '-wrong') })
    Assert-Topic04RetentionFailure -Result $wrongPurge -Code 'AT-PURGE-CONFIRMATION' -Scenario 'purge confirmation not byte-equal to task ID'
    Assert-Topic04Retention (Test-Path -LiteralPath (Join-Path $context.StateRoot (Join-Path 'trash' $taskId)) -PathType Container) 'Rejected purge must preserve trash bytes.'

    $dependentOwner = 'codex:dependent-owner'
    $dependentCreate = New-Topic04RetentionTask -FixtureRoot $fixture -Repository $repository -SessionRef $dependentOwner
    Assert-Topic04Retention ($dependentCreate.ExitCode -eq 0) 'A dependent fixture task must be created after archive.'
    $dependentId = [string]$dependentCreate.Parsed.data.task_id
    Assert-Topic04Retention ($dependentId -cne $taskId) 'Task IDs retained in trash must never be reused.'
    $dependentAuthority = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId $dependentId
    $archivedDependencyId = $taskId
    $dependencyMutator = {
        param($next)
        $next.dependency_task_ids = @($archivedDependencyId)
    }.GetNewClosure()
    $dependencyRevision = Write-AgentTasksRevision -StateRoot $context.StateRoot -TaskId $dependentId `
        -ExpectedRevision ([long]$dependentAuthority.Revision.revision) -ExpectedRevisionSha256 ([string]$dependentAuthority.RevisionSha256) `
        -ExpectedLeaseGeneration ([long]$dependentAuthority.Revision.lease_generation) -SessionRef $dependentOwner -Mutator $dependencyMutator
    Assert-Topic04Retention ([long]$dependencyRevision.Revision.revision -eq 2) 'Live dependency fixture must publish explicit task reference authority.'
    Assert-Topic04Retention (@($dependencyRevision.Revision.dependency_task_ids) -contains $taskId) 'Live dependency authority must reference the archived task ID.'
    $liveReferencePurge = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'purge' -Request ([ordered]@{ task_id = $taskId; confirmation = $taskId })
    Assert-Topic04RetentionFailure -Result $liveReferencePurge -Code 'AT-PURGE-LIVE-REFERENCE' -Scenario 'purge task required by nonterminal authority'
    $dependentAuthority = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId $dependentId
    $dependentClose = Close-Topic04RetentionTask -FixtureRoot $fixture -Repository $repository -Authority $dependentAuthority -SessionRef $dependentOwner
    Assert-Topic04Retention ($dependentClose.ExitCode -eq 0) 'Dependent fixture must become terminal.'
    $workspaceHashBeforePurge = Get-AgentTasksSha256 -LiteralPath (Join-Path $repository 'src/output.txt')
    $purge = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'purge' -Request ([ordered]@{ task_id = $taskId; confirmation = $taskId })
    Assert-Topic04Retention ($purge.ExitCode -eq 0 -and $purge.Parsed.data.purged) 'Exact confirmed purge must delete only unreferenced terminal trash authority.'
    Assert-Topic04Retention (-not (Test-Path -LiteralPath (Join-Path $context.StateRoot (Join-Path 'trash' $taskId)))) 'Purged task directory must no longer exist.'
    Assert-Topic04Retention ((Get-AgentTasksSha256 -LiteralPath (Join-Path $repository 'src/output.txt')) -ceq $workspaceHashBeforePurge) 'Purge must not change workspace bytes.'
    $retentionSource = [IO.File]::ReadAllText($retentionPath)
    Assert-Topic04Retention (
        $retentionSource -notmatch '(?im)(?:&\s*)?git(?:\.exe)?\s+worktree\s+(?:remove|prune)|Invoke-AgentTasksGit\w*[^\r\n]*(?:remove|prune)'
    ) 'Retention core must never invoke Git worktree deletion or pruning.'

    $phaseCreate = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'create-phase' -Request ([ordered]@{ phase_id = 'P-RETENTION'; objective = 'Retain phase references.'; authority = @('user'); dependencies = @(); exit_obligations = @() })
    Assert-Topic04Retention ($phaseCreate.ExitCode -eq 0) 'Dependency phase must be created.'
    $phaseAuthority = Get-AgentTasksPhaseAuthority -StateRoot $context.StateRoot -PhaseId 'P-RETENTION'
    $phaseStart = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'transition-phase' -Request ([ordered]@{
            phase_id = 'P-RETENTION'; target_status = 'active'; expected_revision = $phaseAuthority.Revision.revision
            expected_revision_sha256 = $phaseAuthority.RevisionSha256
        })
    Assert-Topic04Retention ($phaseStart.ExitCode -eq 0) 'Dependency phase must become active.'
    $phaseTaskOwner = 'codex:phase-task-owner'
    $phaseTask = New-Topic04RetentionTask -FixtureRoot $fixture -Repository $repository -SessionRef $phaseTaskOwner -PhaseId 'P-RETENTION'
    Assert-Topic04Retention ($phaseTask.ExitCode -eq 0) 'Phase-linked task must be created.'
    $phaseTaskId = [string]$phaseTask.Parsed.data.task_id
    $phaseTaskAuthority = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId $phaseTaskId
    $phaseTaskClose = Close-Topic04RetentionTask -FixtureRoot $fixture -Repository $repository -Authority $phaseTaskAuthority -SessionRef $phaseTaskOwner
    Assert-Topic04Retention ($phaseTaskClose.ExitCode -eq 0) 'Phase-linked task must become terminal.'
    $phaseBlockedCleanup = Invoke-Topic04Cleanup -FixtureRoot $fixture -Repository $repository -TaskId $phaseTaskId
    Assert-Topic04Retention (
        $phaseBlockedCleanup.ExitCode -eq 0 -and -not $phaseBlockedCleanup.Parsed.data.eligible -and
        @($phaseBlockedCleanup.Parsed.data.blockers.code) -contains 'AT-CLEANUP-DEPENDENCY'
    ) 'A nonterminal phase reference must block archive in dry-run.'
    $phaseAuthority = Get-AgentTasksPhaseAuthority -StateRoot $context.StateRoot -PhaseId 'P-RETENTION'
    $phaseAccept = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $fixture -WorkingDirectory $repository `
        -Operation 'transition-phase' -Request ([ordered]@{
            phase_id = 'P-RETENTION'; target_status = 'accepted'; expected_revision = $phaseAuthority.Revision.revision
            expected_revision_sha256 = $phaseAuthority.RevisionSha256
        })
    Assert-Topic04Retention ($phaseAccept.ExitCode -eq 0) 'Terminal phase must release its archive blocker.'
    $phaseArchive = Invoke-Topic04Cleanup -FixtureRoot $fixture -Repository $repository -TaskId $phaseTaskId -Mode 'apply'
    Assert-Topic04Retention ($phaseArchive.ExitCode -eq 0) 'Phase-linked task must archive after the phase becomes terminal.'

    $legacyFixture = New-Topic04FixtureRoot -Label 'retention-legacy-migration'
    $legacyProject = Join-Path $legacyFixture 'project'
    [void](New-Item -ItemType Directory -Path $legacyProject)
    $legacyInit = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $legacyFixture -WorkingDirectory $legacyProject `
        -Operation 'init-project' -Request ([ordered]@{ display_name = 'Legacy local authority' }) -SessionRef 'codex:legacy'
    Assert-Topic04Retention ($legacyInit.ExitCode -eq 0) 'Non-Git legacy authority must initialize.'
    $legacyRoot = Join-Path $legacyProject '.agent-tasks'
    $legacyManifest = @(Get-Topic04RetentionManifest -Root $legacyRoot)
    [void](Invoke-Topic04RetentionGit -WorkingDirectory $legacyProject -Arguments @('init', '--quiet'))
    [void](Invoke-Topic04RetentionGit -WorkingDirectory $legacyProject -Arguments @('config', 'user.email', 'topic04@example.invalid'))
    [void](Invoke-Topic04RetentionGit -WorkingDirectory $legacyProject -Arguments @('config', 'user.name', 'Topic 04'))
    $gitContext = Resolve-AgentTasksContext -WorkingDirectory $legacyProject

    $legacyStatus = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $legacyFixture -WorkingDirectory $legacyProject -Operation 'status' -Request ([ordered]@{})
    Assert-Topic04Retention (
        $legacyStatus.ExitCode -eq 0 -and $legacyStatus.Parsed.data.mode -ceq 'read_only_migration_required' -and
        [string]$legacyStatus.Parsed.data.state_root -ceq $legacyRoot
    ) 'Legacy local authority must become read-only after Git initialization.'
    $legacyMutation = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $legacyFixture -WorkingDirectory $legacyProject `
        -Operation 'init-project' -Request ([ordered]@{ display_name = 'Forbidden second root' })
    Assert-Topic04RetentionFailure -Result $legacyMutation -Code 'AT-ROOT-MIGRATION-REQUIRED' -Scenario 'mutation while legacy root requires migration'

    $interruptedTarget = Join-Path $gitContext.GitCommonDir 'agent-tasks.tmp-migrate-interrupted'
    [void](New-Item -ItemType Directory -Path $interruptedTarget)
    Set-Topic04Utf8File -LiteralPath (Join-Path $interruptedTarget 'partial.txt') -Content "partial`n"
    $interruptedMigration = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $legacyFixture -WorkingDirectory $legacyProject `
        -Operation 'migrate' -Request ([ordered]@{ migration_kind = 'legacy-root-to-git-common-dir'; target_schema_version = 1 })
    Assert-Topic04RetentionFailure -Result $interruptedMigration -Code 'AT-MIGRATION-RECOVERY-REQUIRED' -Scenario 'interrupted legacy-root migration'
    Assert-Topic04Retention (
        (Test-Path -LiteralPath $legacyRoot -PathType Container) -and
        -not (Test-Path -LiteralPath $gitContext.StateRoot)
    ) 'Interrupted migration must retain one canonical writable source and no target authority.'
    $recoverMigration = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $legacyFixture -WorkingDirectory $legacyProject `
        -Operation 'migrate' -Request ([ordered]@{ migration_kind = 'recover-legacy-root-to-git-common-dir'; target_schema_version = 1 })
    Assert-Topic04Retention ($recoverMigration.ExitCode -eq 0 -and -not (Test-Path -LiteralPath $interruptedTarget)) 'Explicit recovery must remove only unpublished migration temporaries.'

    $migrate = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $legacyFixture -WorkingDirectory $legacyProject `
        -Operation 'migrate' -Request ([ordered]@{ migration_kind = 'legacy-root-to-git-common-dir'; target_schema_version = 1 })
    Assert-Topic04Retention ($migrate.ExitCode -eq 0 -and $migrate.Parsed.data.migrated) 'Validated legacy authority must migrate to Git common dir.'
    $backupPath = [string]$migrate.Parsed.data.backup_path
    Assert-Topic04Retention (
        (Test-Path -LiteralPath $gitContext.StateRoot -PathType Container) -and
        -not (Test-Path -LiteralPath $legacyRoot) -and
        (Test-Path -LiteralPath (Join-Path $backupPath 'MIGRATED_READ_ONLY.json') -PathType Leaf)
    ) 'Migration must publish one target authority and a renamed read-only backup marker.'
    foreach ($entry in $legacyManifest) {
        $targetFile = Join-Path $gitContext.StateRoot ([string]$entry.path -replace '/', [IO.Path]::DirectorySeparatorChar)
        Assert-Topic04Retention (
            (Test-Path -LiteralPath $targetFile -PathType Leaf) -and
            (Get-AgentTasksSha256 -LiteralPath $targetFile) -ceq [string]$entry.sha256
        ) "Migrated target must preserve source bytes for $($entry.path)."
    }
    Assert-Topic04Retention (@(Get-ChildItem -LiteralPath $gitContext.GitCommonDir -Directory -Filter 'agent-tasks.tmp-migrate-*').Count -eq 0) 'Successful migration must leave no unpublished target root.'

    $beforeNoopMigration = @(Get-Topic04RetentionManifest -Root $gitContext.StateRoot)
    $noopMigration = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $legacyFixture -WorkingDirectory $legacyProject `
        -Operation 'migrate' -Request ([ordered]@{ migration_kind = 'schema'; target_schema_version = 1 })
    Assert-Topic04RetentionFailure -Result $noopMigration -Code 'AT-MIGRATION-NOT-REQUIRED' -Scenario 'v1-to-v1 schema migration'
    $afterNoopMigration = @(Get-Topic04RetentionManifest -Root $gitContext.StateRoot)
    Assert-Topic04Retention ((ConvertTo-AgentTasksCanonicalJson -Value $beforeNoopMigration) -ceq (ConvertTo-AgentTasksCanonicalJson -Value $afterNoopMigration)) 'No-op schema migration must change no bytes.'

    $newerFixture = New-Topic04FixtureRoot -Label 'retention-newer-schema'
    $newerRepository = Initialize-Topic04GitFixture -Root $newerFixture
    $newerInit = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $newerFixture -WorkingDirectory $newerRepository `
        -Operation 'init-project' -Request ([ordered]@{ display_name = 'Newer schema fixture' })
    Assert-Topic04Retention ($newerInit.ExitCode -eq 0) 'Newer-schema fixture must initialize at v1.'
    $newerContext = Resolve-AgentTasksContext -WorkingDirectory $newerRepository
    $identityPath = Join-Path $newerContext.StateRoot 'project\identity.json'
    $identity = Read-AgentTasksJsonFile -LiteralPath $identityPath
    $identity.schema_version = 2
    $rehash = Copy-AgentTasksRecordWithHash -Value $identity
    Set-Topic04Utf8File -LiteralPath $identityPath -Content ((ConvertTo-AgentTasksCanonicalJson -Value $rehash) + "`n")
    $newerStatus = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $newerFixture -WorkingDirectory $newerRepository -Operation 'status' -Request ([ordered]@{})
    Assert-Topic04Retention (
        $newerStatus.ExitCode -eq 0 -and $newerStatus.Parsed.data.mode -ceq 'read_only_newer_schema' -and
        [long]$newerStatus.Parsed.data.schema_version -eq 2
    ) 'Unknown newer schema must remain inspectable through status only.'
    $newerMutation = Invoke-Topic04CliObject -CliPath $cliPath -FixtureRoot $newerFixture -WorkingDirectory $newerRepository `
        -Operation 'create-task' -Request ([ordered]@{
            objective = 'Must refuse.'; authority = @('user'); acceptance_criteria = @(); obligations = @()
            execution_mode = 'read_only'; write_scope = @(); owned_ignored_outputs = @()
            workflow_class = 'standard'; locked_decisions = @()
        })
    Assert-Topic04RetentionFailure -Result $newerMutation -Code 'AT-SCHEMA-NEWER' -Scenario 'mutation against unknown newer schema'

    Write-Host ("PASS Topic 04 state retention ({0} assertions)" -f $script:Assertions) -ForegroundColor Green
    exit 0
} catch {
    Write-Host ("FAIL [AT-TEST-RETENTION] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    Remove-Topic04FixtureRoots
}
