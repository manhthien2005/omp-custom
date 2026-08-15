#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-AgentTasksTaskAuthority -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Lifecycle.ps1')
}

function Get-AgentTasksRootSchemaVersion {
    param([Parameter(Mandatory)][string]$StateRoot)
    $identityPath = Join-Path $StateRoot 'project\identity.json'
    if (-not (Test-Path -LiteralPath $identityPath -PathType Leaf)) { return $null }
    $identity = Read-AgentTasksJsonFile -LiteralPath $identityPath
    if (-not $identity.Contains('schema_version')) {
        Throw-AgentTasksError -Code 'AT-SCHEMA-VERSION' -ExitCode 4 -SafeMessage 'The authority schema version is missing.'
    }
    return [long]$identity.schema_version
}

function Assert-AgentTasksRootMutationAllowed {
    param([Parameter(Mandatory)][object]$Context)
    $targetVersion = Get-AgentTasksRootSchemaVersion -StateRoot $Context.StateRoot
    if ($null -ne $targetVersion -and [long]$targetVersion -gt 1) {
        Throw-AgentTasksError -Code 'AT-SCHEMA-NEWER' -ExitCode 4 -SafeMessage 'The authority schema is newer than this tool and is read-only.'
    }
    if ($Context.IsGit) {
        $legacyIdentity = Join-Path $Context.LegacyStateRoot 'project\identity.json'
        $targetIdentity = Join-Path $Context.StateRoot 'project\identity.json'
        if ((Test-Path -LiteralPath $legacyIdentity -PathType Leaf) -and (Test-Path -LiteralPath $targetIdentity -PathType Leaf)) {
            Throw-AgentTasksError -Code 'AT-ROOT-CONFLICT' -ExitCode 4 -SafeMessage 'Both legacy and Git-common-dir authorities exist.'
        }
        if (Test-Path -LiteralPath $legacyIdentity -PathType Leaf) {
            Throw-AgentTasksError -Code 'AT-ROOT-MIGRATION-REQUIRED' -ExitCode 3 -SafeMessage 'The legacy local authority is read-only until explicitly migrated.'
        }
    }
}

function Get-AgentTasksDirectoryByteLength {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Container)) { return 0L }
    $total = 0L
    foreach ($file in Get-ChildItem -LiteralPath $LiteralPath -File -Recurse -Force) { $total += [long]$file.Length }
    return $total
}

function Get-AgentTasksLiveReferenceBlockers {
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string]$TaskId
    )
    $terminal = @('accepted', 'cancelled', 'terminally_blocked')
    $blockers = [Collections.Generic.List[object]]::new()
    $phasesRoot = Join-Path $StateRoot 'phases'
    if (Test-Path -LiteralPath $phasesRoot -PathType Container) {
        foreach ($directory in Get-ChildItem -LiteralPath $phasesRoot -Directory | Sort-Object Name) {
            $phase = Get-AgentTasksPhaseAuthority -StateRoot $StateRoot -PhaseId $directory.Name
            if ([string]$phase.Revision.status -in $terminal) { continue }
            $linked = @($phase.Revision.linked_task_ids | Where-Object { $null -ne $_ })
            $dependencies = @($phase.Contract.dependencies | Where-Object { $null -ne $_ })
            if ($linked -contains $TaskId -or $dependencies -contains $TaskId) {
                [void]$blockers.Add([ordered]@{ code = 'AT-CLEANUP-DEPENDENCY'; ref_type = 'phase'; ref_id = $directory.Name })
            }
        }
    }
    $tasksRoot = Join-Path $StateRoot 'tasks'
    if (Test-Path -LiteralPath $tasksRoot -PathType Container) {
        foreach ($directory in Get-ChildItem -LiteralPath $tasksRoot -Directory | Sort-Object Name) {
            if ($directory.Name -ceq $TaskId) { continue }
            $task = Get-AgentTasksTaskAuthority -StateRoot $StateRoot -TaskId $directory.Name
            if ([string]$task.Revision.status -in $terminal) { continue }
            $revisionDependencies = if ($task.Revision.Contains('dependency_task_ids')) {
                @($task.Revision.dependency_task_ids | Where-Object { $null -ne $_ })
            } else { @() }
            $contractDependencies = if ($task.Contract.Contains('dependencies')) {
                @($task.Contract.dependencies | Where-Object { $null -ne $_ })
            } else { @() }
            if ($revisionDependencies -contains $TaskId -or $contractDependencies -contains $TaskId) {
                [void]$blockers.Add([ordered]@{ code = 'AT-CLEANUP-DEPENDENCY'; ref_type = 'task'; ref_id = $directory.Name })
            }
        }
    }
    return $blockers.ToArray()
}

function Get-AgentTasksCleanupPlan {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId,
        [string]$Mode = 'dry-run'
    )
    if ($Mode -notin @('dry-run', 'apply')) {
        Throw-AgentTasksError -Code 'AT-CLEANUP-MODE' -ExitCode 2 -SafeMessage 'Cleanup mode must be dry-run or apply.'
    }
    $source = [IO.Path]::GetFullPath((Join-Path $Context.StateRoot (Join-Path 'tasks' $TaskId)))
    $target = [IO.Path]::GetFullPath((Join-Path $Context.StateRoot (Join-Path 'trash' $TaskId)))
    Assert-AgentTasksPathInside -Root (Join-Path $Context.StateRoot 'tasks') -Candidate $source
    Assert-AgentTasksPathInside -Root (Join-Path $Context.StateRoot 'trash') -Candidate $target
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        if (Test-Path -LiteralPath $target -PathType Container) {
            Throw-AgentTasksError -Code 'AT-CLEANUP-ALREADY-ARCHIVED' -ExitCode 3 -SafeMessage 'The task is already archived.'
        }
        Throw-AgentTasksError -Code 'AT-TASK-NOT-FOUND' -ExitCode 3 -SafeMessage 'The cleanup task does not exist.'
    }
    if (Test-Path -LiteralPath $target) {
        Throw-AgentTasksError -Code 'AT-TASK-DUPLICATE' -ExitCode 4 -SafeMessage 'The task identifier already exists in trash.'
    }
    $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
    $blockers = [Collections.Generic.List[object]]::new()
    if ([string]$authority.Revision.status -notin @('accepted', 'cancelled', 'terminally_blocked')) {
        [void]$blockers.Add([ordered]@{ code = 'AT-CLEANUP-NONTERMINAL'; ref_type = 'task'; ref_id = $TaskId })
    }
    foreach ($blocker in @(Get-AgentTasksLiveReferenceBlockers -StateRoot $Context.StateRoot -TaskId $TaskId)) {
        [void]$blockers.Add($blocker)
    }
    return [ordered]@{
        task_id = $TaskId
        mode = $Mode
        eligible = $blockers.Count -eq 0
        blockers = @($blockers.ToArray())
        source_path = $source
        target_path = $target
        estimated_bytes = Get-AgentTasksDirectoryByteLength -LiteralPath $source
    }
}

function Move-AgentTasksTaskToTrash {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId
    )
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain repository -Id 'authority' -Action {
        return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $TaskId -Action {
            $plan = Get-AgentTasksCleanupPlan -Context $Context -TaskId $TaskId -Mode 'apply'
            if (-not $plan.eligible) {
                Throw-AgentTasksError -Code 'AT-CLEANUP-BLOCKED' -ExitCode 3 -SafeMessage 'The task is not eligible for archive.'
            }
            [IO.Directory]::Move([string]$plan.source_path, [string]$plan.target_path)
            return [ordered]@{
                task_id = $TaskId
                mode = 'apply'
                archived = $true
                source_path = [string]$plan.source_path
                target_path = [string]$plan.target_path
                estimated_bytes = [long]$plan.estimated_bytes
            }
        }
    }
}

function Restore-AgentTasksTask {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId
    )
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain repository -Id 'authority' -Action {
        return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $TaskId -Action {
            $source = [IO.Path]::GetFullPath((Join-Path $Context.StateRoot (Join-Path 'trash' $TaskId)))
            $target = [IO.Path]::GetFullPath((Join-Path $Context.StateRoot (Join-Path 'tasks' $TaskId)))
            Assert-AgentTasksPathInside -Root (Join-Path $Context.StateRoot 'trash') -Candidate $source
            Assert-AgentTasksPathInside -Root (Join-Path $Context.StateRoot 'tasks') -Candidate $target
            if (Test-Path -LiteralPath $target) {
                Throw-AgentTasksError -Code 'AT-TASK-DUPLICATE' -ExitCode 4 -SafeMessage 'The active task identifier already exists.'
            }
            if (-not (Test-Path -LiteralPath $source -PathType Container)) {
                Throw-AgentTasksError -Code 'AT-TASK-NOT-FOUND' -ExitCode 3 -SafeMessage 'The archived task does not exist.'
            }
            $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
            if ([string]$authority.Revision.status -notin @('accepted', 'cancelled', 'terminally_blocked')) {
                Throw-AgentTasksError -Code 'AT-RESTORE-NONTERMINAL' -ExitCode 4 -SafeMessage 'Only a terminal archived task can be restored.'
            }
            [IO.Directory]::Move($source, $target)
            return [ordered]@{ task_id = $TaskId; restored = $true; source_path = $source; target_path = $target }
        }
    }
}

function Remove-AgentTasksPurgedTask {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][string]$Confirmation
    )
    if ($Confirmation -cne $TaskId) {
        Throw-AgentTasksError -Code 'AT-PURGE-CONFIRMATION' -ExitCode 3 -SafeMessage 'Purge confirmation must exactly equal the task identifier.'
    }
    return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain repository -Id 'authority' -Action {
        return Invoke-WithAgentTasksLock -StateRoot $Context.StateRoot -Domain task -Id $TaskId -Action {
            $target = [IO.Path]::GetFullPath((Join-Path $Context.StateRoot (Join-Path 'trash' $TaskId)))
            Assert-AgentTasksPathInside -Root (Join-Path $Context.StateRoot 'trash') -Candidate $target
            if (Test-Path -LiteralPath (Join-Path $Context.StateRoot (Join-Path 'tasks' $TaskId))) {
                Throw-AgentTasksError -Code 'AT-TASK-DUPLICATE' -ExitCode 4 -SafeMessage 'The task also exists in active authority.'
            }
            if (-not (Test-Path -LiteralPath $target -PathType Container)) {
                Throw-AgentTasksError -Code 'AT-TASK-NOT-FOUND' -ExitCode 3 -SafeMessage 'The purge target is not an archived task.'
            }
            $authority = Get-AgentTasksTaskAuthority -StateRoot $Context.StateRoot -TaskId $TaskId
            if ([string]$authority.Revision.status -notin @('accepted', 'cancelled', 'terminally_blocked')) {
                Throw-AgentTasksError -Code 'AT-PURGE-NONTERMINAL' -ExitCode 3 -SafeMessage 'Only a terminal archived task can be purged.'
            }
            $references = @(Get-AgentTasksLiveReferenceBlockers -StateRoot $Context.StateRoot -TaskId $TaskId)
            if ($references.Count -gt 0) {
                Throw-AgentTasksError -Code 'AT-PURGE-LIVE-REFERENCE' -ExitCode 3 -SafeMessage 'A nonterminal authority still references the purge target.'
            }
            $bytes = Get-AgentTasksDirectoryByteLength -LiteralPath $target
            $purgesRoot = Join-Path $Context.StateRoot 'purges'
            [void](New-Item -ItemType Directory -Path $purgesRoot -Force)
            $purgeId = 'PG-' + [guid]::NewGuid().ToString('N')
            [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $purgesRoot ($purgeId + '.json')) -Value ([ordered]@{
                schema_version = 1
                record_type = 'task_purge'
                purge_id = $purgeId
                task_id = $TaskId
                terminal_revision_hash = [string]$authority.Revision.record_hash
                byte_length = [long]$bytes
                created_at = Get-AgentTasksUtcTimestamp
            }))
            Assert-AgentTasksPathInside -Root (Join-Path $Context.StateRoot 'trash') -Candidate $target
            Remove-Item -LiteralPath $target -Recurse -Force
            return [ordered]@{ task_id = $TaskId; purge_id = $purgeId; purged = $true; byte_length = [long]$bytes }
        }
    }
}

function Get-AgentTasksAuthorityRootManifest {
    param([Parameter(Mandatory)][string]$Root)
    $records = [Collections.Generic.List[object]]::new()
    foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse -Force | Sort-Object FullName) {
        if ($file.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
            Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'Migration source contains a reparse point.'
        }
        [void]$records.Add([ordered]@{
            path = [IO.Path]::GetRelativePath($Root, $file.FullName).Replace('\', '/')
            sha256 = Get-AgentTasksSha256 -LiteralPath $file.FullName
            length = [long]$file.Length
        })
    }
    return $records.ToArray()
}

function Assert-AgentTasksAuthorityRootValid {
    param([Parameter(Mandatory)][string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'Migration source authority does not exist.'
    }
    $identityPath = Join-Path $Root 'project\identity.json'
    if (-not (Test-Path -LiteralPath $identityPath -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'Migration source identity is missing.'
    }
    $identity = Read-AgentTasksJsonFile -LiteralPath $identityPath
    if ([long]$identity.schema_version -ne 1 -or [string]$identity.record_hash -cne (Get-AgentTasksSha256 -Value $identity)) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'Migration source identity is invalid.'
    }
    foreach ($stateDirectory in Get-ChildItem -LiteralPath $Root -Directory -Recurse -Force | Where-Object Name -ceq 'state') {
        $chain = Get-AgentTasksRevisionChain -StateDirectory $stateDirectory.FullName
        if ($chain.Status -cne 'valid') {
            Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'Migration source contains an invalid revision chain.'
        }
    }
    foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse -Filter '*.json' -Force) {
        $record = Read-AgentTasksJsonFile -LiteralPath $file.FullName
        if (-not $record.Contains('record_hash') -or [string]$record.record_hash -cne (Get-AgentTasksSha256 -Value $record)) {
            Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'Migration source contains an invalid authority record.'
        }
    }
}

function Copy-AgentTasksAuthorityRoot {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    if (Test-Path -LiteralPath $Destination) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-TARGET' -ExitCode 4 -SafeMessage 'Migration temporary target already exists.'
    }
    [void](New-Item -ItemType Directory -Path $Destination)
    foreach ($directory in Get-ChildItem -LiteralPath $Source -Directory -Recurse -Force | Sort-Object FullName) {
        if ($directory.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
            Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'Migration source contains a reparse point.'
        }
        $relative = [IO.Path]::GetRelativePath($Source, $directory.FullName)
        [void](New-Item -ItemType Directory -Path (Join-Path $Destination $relative) -Force)
    }
    foreach ($file in Get-ChildItem -LiteralPath $Source -File -Recurse -Force | Sort-Object FullName) {
        if ($file.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
            Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'Migration source contains a reparse point.'
        }
        $relative = [IO.Path]::GetRelativePath($Source, $file.FullName)
        $targetFile = Join-Path $Destination $relative
        [IO.File]::Copy($file.FullName, $targetFile, $false)
    }
}

function Test-AgentTasksManifestsEqual {
    param(
        [Parameter(Mandatory)][object[]]$Left,
        [Parameter(Mandatory)][object[]]$Right
    )
    return (ConvertTo-AgentTasksCanonicalJson -Value @($Left)) -ceq (ConvertTo-AgentTasksCanonicalJson -Value @($Right))
}

function Move-AgentTasksLegacyRoot {
    param([Parameter(Mandatory)][object]$Context)
    if (-not $Context.IsGit) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-CONTEXT' -ExitCode 3 -SafeMessage 'Legacy-root migration requires a Git worktree.'
    }
    $source = [IO.Path]::GetFullPath($Context.LegacyStateRoot).TrimEnd('\', '/')
    $target = [IO.Path]::GetFullPath($Context.StateRoot).TrimEnd('\', '/')
    if (Test-Path -LiteralPath $target) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-TARGET-EXISTS' -ExitCode 4 -SafeMessage 'The Git-common-dir target authority already exists.'
    }
    $temporaryMatches = @(Get-ChildItem -LiteralPath $Context.GitCommonDir -Directory -Filter 'agent-tasks.tmp-migrate-*' -ErrorAction SilentlyContinue)
    if ($temporaryMatches.Count -gt 0) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-RECOVERY-REQUIRED' -ExitCode 3 -SafeMessage 'An interrupted migration requires explicit recovery.'
    }
    Assert-AgentTasksAuthorityRootValid -Root $source
    $sourceManifest = @(Get-AgentTasksAuthorityRootManifest -Root $source)
    $sourceHash = Get-AgentTasksSha256 -Value $sourceManifest
    $lockPath = Join-Path $Context.ProjectRoot '.agent-tasks.migration.lock'
    if (Test-Path -LiteralPath $lockPath) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-LOCKED' -ExitCode 3 -SafeMessage 'Legacy-root migration is already locked.'
    }
    [void](New-Item -ItemType Directory -Path $lockPath)
    $lockAcquired = $true
    $temporary = Join-Path $Context.GitCommonDir ('agent-tasks.tmp-migrate-' + [guid]::NewGuid().ToString('N'))
    $backup = Join-Path $Context.ProjectRoot (
        '.agent-tasks.migrated-{0}-{1}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), $sourceHash.Substring(0, 8)
    )
    try {
        [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $lockPath 'owner.json') -Value ([ordered]@{
            schema_version = 1; record_type = 'migration_lock'; host = [Environment]::MachineName
            process_id = $PID; process_start_time = Get-AgentTasksProcessStartTime; created_at = Get-AgentTasksUtcTimestamp
        }))
        Copy-AgentTasksAuthorityRoot -Source $source -Destination $temporary
        $targetManifest = @(Get-AgentTasksAuthorityRootManifest -Root $temporary)
        if (-not (Test-AgentTasksManifestsEqual -Left $sourceManifest -Right $targetManifest)) {
            Throw-AgentTasksError -Code 'AT-MIGRATION-VERIFY' -ExitCode 4 -SafeMessage 'Migration copy verification failed.'
        }
        [IO.Directory]::Move($source, $backup)
        try {
            [IO.Directory]::Move($temporary, $target)
        } catch {
            if (-not (Test-Path -LiteralPath $source) -and (Test-Path -LiteralPath $backup)) {
                [IO.Directory]::Move($backup, $source)
            }
            throw
        }
        [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $backup 'MIGRATED_READ_ONLY.json') -Value ([ordered]@{
            schema_version = 1; record_type = 'migrated_backup_marker'; source_manifest_hash = $sourceHash
            target_root = $target; migrated_at = Get-AgentTasksUtcTimestamp
        }))
        $migrationsRoot = Join-Path $target 'migrations'
        [void](New-Item -ItemType Directory -Path $migrationsRoot -Force)
        $migrationId = 'MG-' + [guid]::NewGuid().ToString('N')
        [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $migrationsRoot ($migrationId + '.json')) -Value ([ordered]@{
            schema_version = 1; record_type = 'root_migration'; migration_id = $migrationId
            source_manifest_hash = $sourceHash; backup_path = $backup; target_root = $target
            created_at = Get-AgentTasksUtcTimestamp
        }))
        return [ordered]@{
            migration_id = $migrationId
            migrated = $true
            source_manifest_hash = $sourceHash
            target_state_root = $target
            backup_path = $backup
        }
    } finally {
        if ($lockAcquired -and (Test-Path -LiteralPath $lockPath)) {
            Remove-Item -LiteralPath $lockPath -Recurse -Force
        }
    }
}

function Repair-AgentTasksLegacyMigration {
    param([Parameter(Mandatory)][object]$Context)
    if (-not $Context.IsGit) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-CONTEXT' -ExitCode 3 -SafeMessage 'Migration recovery requires a Git worktree.'
    }
    if (Test-Path -LiteralPath $Context.StateRoot) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-TARGET-EXISTS' -ExitCode 4 -SafeMessage 'A target authority already exists; automatic recovery is refused.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Context.LegacyStateRoot 'project\identity.json') -PathType Leaf)) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-SOURCE' -ExitCode 4 -SafeMessage 'The canonical legacy source is unavailable.'
    }
    $removed = [Collections.Generic.List[string]]::new()
    foreach ($directory in Get-ChildItem -LiteralPath $Context.GitCommonDir -Directory -Filter 'agent-tasks.tmp-migrate-*' -ErrorAction SilentlyContinue) {
        $resolved = [IO.Path]::GetFullPath($directory.FullName)
        Assert-AgentTasksPathInside -Root $Context.GitCommonDir -Candidate $resolved
        Remove-Item -LiteralPath $resolved -Recurse -Force
        [void]$removed.Add($resolved)
    }
    return [ordered]@{ recovered = $true; removed_temporary_roots = $removed.ToArray(); source_state_root = [string]$Context.LegacyStateRoot }
}

function Invoke-AgentTasksSchemaMigration {
    param(
        [Parameter(Mandatory)][object]$Context,
        [long]$TargetSchemaVersion = 1
    )
    $version = Get-AgentTasksRootSchemaVersion -StateRoot $Context.StateRoot
    if ($null -eq $version) {
        Throw-AgentTasksError -Code 'AT-STATE-NOT-INITIALIZED' -ExitCode 4 -SafeMessage 'Project authority has not been initialized.'
    }
    if ([long]$version -gt 1) {
        Throw-AgentTasksError -Code 'AT-SCHEMA-NEWER' -ExitCode 4 -SafeMessage 'The authority schema is newer than this tool and cannot be downgraded.'
    }
    if ([long]$version -eq $TargetSchemaVersion) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-NOT-REQUIRED' -ExitCode 3 -SafeMessage 'The requested schema migration is not required.'
    }
    Throw-AgentTasksError -Code 'AT-MIGRATION-UNSUPPORTED' -ExitCode 3 -SafeMessage 'The requested schema migration is unsupported by this tool.'
}

function Invoke-AgentTasksMigration {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][Collections.IDictionary]$Request
    )
    $kind = [string]$Request.migration_kind
    $targetVersion = if ($Request.Contains('target_schema_version')) { [long]$Request.target_schema_version } else { 1L }
    if ($targetVersion -ne 1) {
        Throw-AgentTasksError -Code 'AT-MIGRATION-UNSUPPORTED' -ExitCode 3 -SafeMessage 'Only schema v1 is supported by this tool.'
    }
    switch -CaseSensitive ($kind) {
        'legacy-root-to-git-common-dir' { return Move-AgentTasksLegacyRoot -Context $Context }
        'recover-legacy-root-to-git-common-dir' { return Repair-AgentTasksLegacyMigration -Context $Context }
        'schema' { return Invoke-AgentTasksSchemaMigration -Context $Context -TargetSchemaVersion $targetVersion }
        default { Throw-AgentTasksError -Code 'AT-MIGRATION-KIND' -ExitCode 2 -SafeMessage 'The migration kind is unsupported.' }
    }
}
