#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Throw-AgentTasksError -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Common.ps1')
}

$script:AgentTasksLockStack = [Collections.Generic.List[object]]::new()

function Invoke-AgentTasksGitText {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $output = @(& git -C $WorkingDirectory @Arguments 2>$null)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        Throw-AgentTasksError -Code 'AT-GIT-UNAVAILABLE' -ExitCode 4 -SafeMessage 'Git metadata could not be resolved.'
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Text = (($output | ForEach-Object { [string]$_ }) -join "`n").Trim()
    }
}

function Resolve-AgentTasksAbsolutePath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$BasePath
    )

    if ([IO.Path]::IsPathFullyQualified($Path)) {
        return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    }
    return [IO.Path]::GetFullPath((Join-Path $BasePath $Path)).TrimEnd('\', '/')
}

function Resolve-AgentTasksContext {
    param([Parameter(Mandatory)][string]$WorkingDirectory)

    if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) {
        Throw-AgentTasksError -Code 'AT-WORKING-DIRECTORY' -ExitCode 4 -SafeMessage 'The working directory does not exist.'
    }
    try {
        $resolvedWorkingDirectory = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $WorkingDirectory).Path).TrimEnd('\', '/')
    } catch {
        Throw-AgentTasksError -Code 'AT-WORKING-DIRECTORY' -ExitCode 4 -SafeMessage 'The working directory could not be resolved.'
    }

    $inside = Invoke-AgentTasksGitText -WorkingDirectory $resolvedWorkingDirectory -Arguments @(
        'rev-parse', '--is-inside-work-tree'
    ) -AllowFailure
    if ($inside.ExitCode -eq 0 -and $inside.Text -ceq 'true') {
        $worktreeResult = Invoke-AgentTasksGitText -WorkingDirectory $resolvedWorkingDirectory -Arguments @(
            'rev-parse', '--show-toplevel'
        )
        $gitDirResult = Invoke-AgentTasksGitText -WorkingDirectory $resolvedWorkingDirectory -Arguments @(
            'rev-parse', '--path-format=absolute', '--git-dir'
        )
        $commonDirResult = Invoke-AgentTasksGitText -WorkingDirectory $resolvedWorkingDirectory -Arguments @(
            'rev-parse', '--path-format=absolute', '--git-common-dir'
        )
        $worktreeRoot = Resolve-AgentTasksAbsolutePath -Path $worktreeResult.Text -BasePath $resolvedWorkingDirectory
        $gitDir = Resolve-AgentTasksAbsolutePath -Path $gitDirResult.Text -BasePath $worktreeRoot
        $commonDir = Resolve-AgentTasksAbsolutePath -Path $commonDirResult.Text -BasePath $worktreeRoot
        return [pscustomobject]@{
            ProjectRoot = $worktreeRoot
            WorktreeRoot = $worktreeRoot
            GitDir = $gitDir
            GitCommonDir = $commonDir
            StateRoot = [IO.Path]::GetFullPath((Join-Path $commonDir 'agent-tasks')).TrimEnd('\', '/')
            LegacyStateRoot = [IO.Path]::GetFullPath((Join-Path $worktreeRoot '.agent-tasks')).TrimEnd('\', '/')
            IsGit = $true
        }
    }

    return [pscustomobject]@{
        ProjectRoot = $resolvedWorkingDirectory
        WorktreeRoot = $resolvedWorkingDirectory
        GitDir = $null
        GitCommonDir = $null
        StateRoot = [IO.Path]::GetFullPath((Join-Path $resolvedWorkingDirectory '.agent-tasks')).TrimEnd('\', '/')
        LegacyStateRoot = [IO.Path]::GetFullPath((Join-Path $resolvedWorkingDirectory '.agent-tasks')).TrimEnd('\', '/')
        IsGit = $false
    }
}

function Test-AgentTasksPathInside {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Candidate
    )

    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $candidateFull = [IO.Path]::GetFullPath($Candidate).TrimEnd('\', '/')
    if ($candidateFull -ceq $rootFull) { return $true }
    $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    return $candidateFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-AgentTasksPathInside {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Candidate
    )
    if (-not (Test-AgentTasksPathInside -Root $Root -Candidate $Candidate)) {
        Throw-AgentTasksError -Code 'AT-PATH-ESCAPE' -ExitCode 4 -SafeMessage 'The resolved path escapes its authority root.'
    }
}

function Copy-AgentTasksRecordWithHash {
    param([Parameter(Mandatory)][object]$Value)

    $copy = [ordered]@{}
    if ($Value -is [Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            if ([string]$key -cne 'record_hash') { $copy[[string]$key] = $Value[$key] }
        }
    } elseif ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            if ($property.Name -cne 'record_hash') { $copy[$property.Name] = $property.Value }
        }
    } else {
        Throw-AgentTasksError -Code 'AT-STORE-RECORD-TYPE' -ExitCode 4 -SafeMessage 'Only JSON objects can be published as authority records.'
    }
    $copy['record_hash'] = Get-AgentTasksSha256 -Value $copy
    return ,$copy
}

function Publish-AgentTasksRecord {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][object]$Value
    )

    $absolutePath = [IO.Path]::GetFullPath($LiteralPath)
    $parent = Split-Path -Parent $absolutePath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    $record = Copy-AgentTasksRecordWithHash -Value $Value
    $canonical = ConvertTo-AgentTasksCanonicalJson -Value $record
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($canonical + "`n")

    $stream = $null
    try {
        $stream = [IO.FileStream]::new(
            $absolutePath,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    } catch [IO.IOException] {
        if ($null -ne $stream) { $stream.Dispose(); $stream = $null }
        if (Test-Path -LiteralPath $absolutePath) {
            Throw-AgentTasksError -Code 'AT-STORE-IMMUTABLE' -ExitCode 3 -SafeMessage 'An immutable authority record already exists at the target path.'
        }
        Throw-AgentTasksError -Code 'AT-STORE-PUBLISH' -ExitCode 4 -SafeMessage 'The authority record could not be published.'
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }

    $fileHash = Get-AgentTasksSha256 -LiteralPath $absolutePath
    return [pscustomobject]@{
        Path = $absolutePath
        Sha256 = $fileHash
        RecordHash = [string]$record.record_hash
        Record = $record
    }
}

function Publish-AgentTasksBundle {
    param(
        [Parameter(Mandatory)][string]$FinalDirectory,
        [Parameter(Mandatory)][scriptblock]$Builder
    )

    $final = [IO.Path]::GetFullPath($FinalDirectory).TrimEnd('\', '/')
    if (Test-Path -LiteralPath $final) {
        Throw-AgentTasksError -Code 'AT-STORE-IMMUTABLE' -ExitCode 3 -SafeMessage 'An immutable authority bundle already exists at the target path.'
    }
    $parent = Split-Path -Parent $final
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    $temporary = Join-Path $parent ('.{0}.tmp-{1}' -f (Split-Path -Leaf $final), [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $temporary)
    try {
        & $Builder $temporary
        [IO.Directory]::Move($temporary, $final)
    } catch {
        if (Test-Path -LiteralPath $temporary -PathType Container) {
            Remove-Item -LiteralPath $temporary -Recurse -Force
        }
        if (Test-Path -LiteralPath $final) {
            Throw-AgentTasksError -Code 'AT-STORE-IMMUTABLE' -ExitCode 3 -SafeMessage 'An immutable authority bundle already exists at the target path.'
        }
        throw
    }
    return $final
}

function Get-AgentTasksRevisionChain {
    param([Parameter(Mandatory)][string]$StateDirectory)

    $records = [Collections.Generic.List[object]]::new()
    $orphans = [Collections.Generic.List[string]]::new()
    $status = 'valid'
    $reason = $null
    try {
        if (-not (Test-Path -LiteralPath $StateDirectory -PathType Container)) {
            throw 'state directory missing'
        }
        $files = @(Get-ChildItem -LiteralPath $StateDirectory -File -Filter 'R*.json' | Sort-Object Name)
        if ($files.Count -eq 0) { throw 'revision chain empty' }
        $previousId = $null
        $previousFileHash = $null
        $continuityInitialized = $false
        for ($index = 0; $index -lt $files.Count; $index++) {
            $expectedName = 'R{0:D6}.json' -f ($index + 1)
            if ($files[$index].Name -cne $expectedName) { throw 'revision gap' }
            $record = Read-AgentTasksJsonFile -LiteralPath $files[$index].FullName
            if ($record -isnot [Collections.IDictionary]) { throw 'revision is not an object' }
            $expectedId = 'R{0:D6}' -f ($index + 1)
            if ([string]$record.revision_id -cne $expectedId -or [long]$record.revision -ne ($index + 1)) {
                throw 'revision identity mismatch'
            }
            if (-not $record.Contains('record_hash')) { throw 'record hash missing' }
            $computedRecordHash = Get-AgentTasksSha256 -Value $record
            if ([string]$record.record_hash -cne $computedRecordHash) { throw 'record hash mismatch' }
            if ($index -eq 0) {
                if ($null -ne $record.previous_revision -or $null -ne $record.previous_revision_sha256) {
                    throw 'first revision has a predecessor'
                }
            } else {
                if ([string]$record.previous_revision -cne $previousId) { throw 'previous revision mismatch' }
                if ([string]$record.previous_revision_sha256 -cne $previousFileHash) { throw 'previous revision hash mismatch' }
            }
            if ([string]$record.record_type -ceq 'task_state_revision') {
                $hasWorkflowClass = $record.Contains('workflow_class')
                $hasLockedDecisions = $record.Contains('locked_decisions')
                if ($hasWorkflowClass -ne $hasLockedDecisions) { throw 'partial continuity classification' }
                if ($continuityInitialized -and -not $hasWorkflowClass) { throw 'continuity classification regressed' }
                if ($hasWorkflowClass) {
                    if ([string]$record.workflow_class -cnotin @('quick', 'standard', 'orchestrated')) { throw 'invalid workflow class' }
                    if ($record.locked_decisions -is [string] -or $record.locked_decisions -is [Collections.IDictionary] -or $record.locked_decisions -isnot [Collections.IEnumerable]) {
                        throw 'invalid locked decisions'
                    }
                    $priorDecisionId = $null
                    $decisionCount = 0
                    foreach ($decision in @($record.locked_decisions)) {
                        $decisionCount++
                        if ($decisionCount -gt 64 -or $decision -isnot [Collections.IDictionary]) { throw 'invalid locked decisions' }
                        if ($decision.Keys.Count -ne 3 -or -not $decision.Contains('decision_id') -or -not $decision.Contains('statement') -or -not $decision.Contains('authority_ref')) {
                            throw 'invalid locked decision shape'
                        }
                        $decisionId = [string]$decision.decision_id
                        if ($decision.decision_id -isnot [string] -or $decisionId -cnotmatch '^D-[A-Z0-9][A-Z0-9._-]{0,63}$') { throw 'invalid locked decision id' }
                        if ($null -ne $priorDecisionId -and [StringComparer]::Ordinal.Compare($priorDecisionId, $decisionId) -ge 0) { throw 'locked decisions are not canonical' }
                        foreach ($name in @('statement', 'authority_ref')) {
                            if ($decision[$name] -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$decision[$name])) { throw 'invalid locked decision string' }
                            $normalized = ([string]$decision[$name]).Replace("`r`n", "`n").Replace("`r", "`n").Normalize([Text.NormalizationForm]::FormC)
                            if ([string]$decision[$name] -cne $normalized -or $normalized.Contains([char]0)) { throw 'noncanonical locked decision string' }
                            $limit = if ($name -ceq 'statement') { 2048 } else { 512 }
                            if ([Text.UTF8Encoding]::new($false, $true).GetByteCount($normalized) -gt $limit) { throw 'locked decision string too large' }
                        }
                        $priorDecisionId = $decisionId
                    }
                    $continuityInitialized = $true
                }
            }
            [void]$records.Add($record)
            $previousId = $expectedId
            $previousFileHash = Get-AgentTasksSha256 -LiteralPath $files[$index].FullName
        }

        $referenced = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($record in $records) {
            if ($record.Contains('supporting_refs') -and $null -ne $record.supporting_refs) {
                foreach ($reference in @($record.supporting_refs)) { [void]$referenced.Add([string]$reference) }
            }
        }
        $legacySupportingDirectory = Join-Path $StateDirectory 'supporting'
        if (Test-Path -LiteralPath $legacySupportingDirectory -PathType Container) {
            foreach ($file in Get-ChildItem -LiteralPath $legacySupportingDirectory -File -Filter '*.json' | Sort-Object Name) {
                $id = [IO.Path]::GetFileNameWithoutExtension($file.Name)
                if (-not $referenced.Contains($id)) { [void]$orphans.Add($file.Name) }
            }
        }
        $supportingDirectory = Join-Path (Split-Path -Parent $StateDirectory) 'supporting'
        if (Test-Path -LiteralPath $supportingDirectory -PathType Container) {
            foreach ($file in Get-ChildItem -LiteralPath $supportingDirectory -File -Filter 'CC*.json' | Sort-Object Name) {
                $id = [IO.Path]::GetFileNameWithoutExtension($file.Name)
                if (-not $referenced.Contains($id)) { [void]$orphans.Add($file.Name) }
                $supporting = Read-AgentTasksJsonFile -LiteralPath $file.FullName
                if (
                    $supporting -isnot [Collections.IDictionary] -or
                    -not $supporting.Contains('record_hash') -or
                    [string]$supporting.record_hash -cne (Get-AgentTasksSha256 -Value $supporting) -or
                    [string]$supporting.record_type -cne 'continuity_contract_change' -or
                    [string]$supporting.continuity_change_id -cne $id
                ) { throw 'invalid continuity supporting record' }
            }
            foreach ($reference in $referenced) {
                if ([string]$reference -cmatch '^CC[0-9]{6}$' -and -not (Test-Path -LiteralPath (Join-Path $supportingDirectory ($reference + '.json')) -PathType Leaf)) {
                    throw 'continuity supporting record missing'
                }
            }
        }
    } catch {
        $status = 'reconcile_required'
        $reason = 'AT-REVISION-CHAIN'
    }

    return [pscustomobject]@{
        Status = $status
        ReasonCode = $reason
        Records = $records.ToArray()
        Orphans = $orphans.ToArray()
    }
}

function ConvertTo-AgentTasksLockId {
    param([Parameter(Mandatory)][string]$Id)

    if ([string]::IsNullOrWhiteSpace($Id)) {
        Throw-AgentTasksError -Code 'AT-LOCK-ID' -ExitCode 4 -SafeMessage 'A lock identifier is required.'
    }
    return [Uri]::EscapeDataString($Id).Replace('%', '_')
}

function Get-AgentTasksProcessStartTime {
    try {
        return (Get-Process -Id $PID).StartTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [Globalization.CultureInfo]::InvariantCulture)
    } catch {
        return 'unknown'
    }
}

function Invoke-WithAgentTasksLock {
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][ValidateSet('repository', 'phase', 'task')][string]$Domain,
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    $ranks = @{ repository = 0; phase = 1; task = 2 }
    $canonicalId = ConvertTo-AgentTasksLockId -Id $Id
    if ($script:AgentTasksLockStack.Count -gt 0) {
        $prior = $script:AgentTasksLockStack[$script:AgentTasksLockStack.Count - 1]
        if (
            $ranks[$Domain] -lt $prior.Rank -or
            ($ranks[$Domain] -eq $prior.Rank -and [StringComparer]::Ordinal.Compare($canonicalId, $prior.Id) -lt 0)
        ) {
            Throw-AgentTasksError -Code 'AT-LOCK-ORDER' -ExitCode 3 -SafeMessage 'The requested lock violates the canonical lock order.'
        }
    }

    $root = [IO.Path]::GetFullPath($StateRoot).TrimEnd('\', '/')
    $locksDirectory = Join-Path $root 'locks'
    [void](New-Item -ItemType Directory -Path $locksDirectory -Force)
    Assert-AgentTasksPathInside -Root $root -Candidate $locksDirectory
    $lockName = '{0}-{1}.lock' -f $Domain, $canonicalId
    $finalLock = Join-Path $locksDirectory $lockName
    $temporaryLock = Join-Path $locksDirectory ('.{0}.tmp-{1}' -f $lockName, [guid]::NewGuid().ToString('N'))
    $lockAcquired = $false
    [void](New-Item -ItemType Directory -Path $temporaryLock)
    try {
        [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporaryLock 'owner.json') -Value ([ordered]@{
            schema_version = 1
            record_type = 'lock_owner'
            created_at = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [Globalization.CultureInfo]::InvariantCulture)
            host = [Environment]::MachineName
            process_id = $PID
            process_start_time = Get-AgentTasksProcessStartTime
        }))
        try {
            [IO.Directory]::Move($temporaryLock, $finalLock)
            $lockAcquired = $true
        } catch [IO.IOException] {
            if (Test-Path -LiteralPath $temporaryLock) { Remove-Item -LiteralPath $temporaryLock -Recurse -Force }
            Throw-AgentTasksError -Code 'AT-LOCK-HELD' -ExitCode 3 -SafeMessage 'The authority lock is already held.'
        }
        [void]$script:AgentTasksLockStack.Add([pscustomobject]@{ Rank = $ranks[$Domain]; Id = $canonicalId })
        try {
            return & $Action
        } finally {
            $script:AgentTasksLockStack.RemoveAt($script:AgentTasksLockStack.Count - 1)
        }
    } finally {
        if (Test-Path -LiteralPath $temporaryLock) {
            Remove-Item -LiteralPath $temporaryLock -Recurse -Force
        }
        if ($lockAcquired -and (Test-Path -LiteralPath $finalLock)) {
            Assert-AgentTasksPathInside -Root $locksDirectory -Candidate $finalLock
            Remove-Item -LiteralPath $finalLock -Recurse -Force
        }
    }
}

function Get-AgentTasksUtcTimestamp {
    return [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [Globalization.CultureInfo]::InvariantCulture)
}

function Initialize-AgentTasksStateRoot {
    param([Parameter(Mandatory)][object]$Context)

    $stateRoot = [IO.Path]::GetFullPath($Context.StateRoot).TrimEnd('\', '/')
    [void](New-Item -ItemType Directory -Path $stateRoot -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $stateRoot 'locks') -Force)
    if (-not $Context.IsGit) {
        $ignorePath = Join-Path $stateRoot '.gitignore'
        if (-not (Test-Path -LiteralPath $ignorePath)) {
            [IO.File]::WriteAllText($ignorePath, "*`n!.gitignore`n", [Text.UTF8Encoding]::new($false))
        } elseif ([IO.File]::ReadAllText($ignorePath) -cne "*`n!.gitignore`n") {
            Throw-AgentTasksError -Code 'AT-STATE-ROOT-CONFLICT' -ExitCode 4 -SafeMessage 'The non-Git authority root contains an unexpected ignore policy.'
        }
    }
    return $stateRoot
}

function Initialize-AgentTasksProjectUnlocked {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$DisplayName
    )

    $stateRoot = Initialize-AgentTasksStateRoot -Context $Context
    $identityPath = Join-Path $stateRoot 'project\identity.json'
    $stateDirectory = Join-Path $stateRoot 'project\state'
    if (Test-Path -LiteralPath $identityPath -PathType Leaf) {
        $identity = Read-AgentTasksJsonFile -LiteralPath $identityPath
        $chain = Get-AgentTasksRevisionChain -StateDirectory $stateDirectory
        if ($chain.Status -cne 'valid') {
            Throw-AgentTasksError -Code 'AT-REVISION-CHAIN' -ExitCode 4 -SafeMessage 'Project authority requires reconciliation.'
        }
        return [pscustomobject]@{
            Identity = $identity
            Revision = $chain.Records[-1]
            Existing = $true
        }
    }

    $rootIdentity = [ordered]@{
        project_root = [string]$Context.ProjectRoot
        git_common_dir = $(if ($Context.IsGit) { [string]$Context.GitCommonDir } else { $null })
    }
    $projectId = 'P-' + (Get-AgentTasksSha256 -Value $rootIdentity).Substring(0, 16)
    $createdAt = Get-AgentTasksUtcTimestamp
    $projectDirectory = Join-Path $stateRoot 'project'
    [void](Publish-AgentTasksBundle -FinalDirectory $projectDirectory -Builder {
        param($temporaryProject)
        [void](New-Item -ItemType Directory -Path (Join-Path $temporaryProject 'state'))
        [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporaryProject 'identity.json') -Value ([ordered]@{
            schema_version = 1
            record_type = 'project_identity'
            project_id = $projectId
            display_name = $DisplayName
            project_root = [string]$Context.ProjectRoot
            worktree_root = [string]$Context.WorktreeRoot
            git_common_dir = $(if ($Context.IsGit) { [string]$Context.GitCommonDir } else { $null })
            is_git = [bool]$Context.IsGit
            created_at = $createdAt
        }))
        [void](Publish-AgentTasksRecord -LiteralPath (Join-Path $temporaryProject 'state\R000001.json') -Value ([ordered]@{
            schema_version = 1
            record_type = 'project_state_revision'
            revision = 1
            revision_id = 'R000001'
            previous_revision = $null
            previous_revision_sha256 = $null
            status = 'active'
            supporting_refs = @()
            created_at = $createdAt
        }))
    })
    foreach ($directory in @('phases', 'tasks', 'trash')) {
        [void](New-Item -ItemType Directory -Path (Join-Path $stateRoot $directory) -Force)
    }
    return [pscustomobject]@{
        Identity = Read-AgentTasksJsonFile -LiteralPath $identityPath
        Revision = (Get-AgentTasksRevisionChain -StateDirectory $stateDirectory).Records[-1]
        Existing = $false
    }
}

function Initialize-AgentTasksProject {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$DisplayName
    )

    $stateRoot = Initialize-AgentTasksStateRoot -Context $Context
    return Invoke-WithAgentTasksLock -StateRoot $stateRoot -Domain repository -Id 'authority' -Action {
        Initialize-AgentTasksProjectUnlocked -Context $Context -DisplayName $DisplayName
    }
}

function Get-AgentTasksStatus {
    param([Parameter(Mandatory)][object]$Context)

    $stateRoot = [IO.Path]::GetFullPath($Context.StateRoot).TrimEnd('\', '/')
    $identityPath = Join-Path $stateRoot 'project\identity.json'
    $stateDirectory = Join-Path $stateRoot 'project\state'
    if (-not (Test-Path -LiteralPath $identityPath -PathType Leaf)) {
        if (
            $Context.IsGit -and
            $Context.PSObject.Properties.Name -contains 'LegacyStateRoot' -and
            (Test-Path -LiteralPath (Join-Path $Context.LegacyStateRoot 'project\identity.json') -PathType Leaf)
        ) {
            $legacyIdentity = Read-AgentTasksJsonFile -LiteralPath (Join-Path $Context.LegacyStateRoot 'project\identity.json')
            $legacyTasks = if (Test-Path -LiteralPath (Join-Path $Context.LegacyStateRoot 'tasks')) {
                @(Get-ChildItem -LiteralPath (Join-Path $Context.LegacyStateRoot 'tasks') -Directory | Sort-Object Name | ForEach-Object Name)
            } else { @() }
            $legacyTrash = if (Test-Path -LiteralPath (Join-Path $Context.LegacyStateRoot 'trash')) {
                @(Get-ChildItem -LiteralPath (Join-Path $Context.LegacyStateRoot 'trash') -Directory | Sort-Object Name | ForEach-Object Name)
            } else { @() }
            return [ordered]@{
                project_id = [string]$legacyIdentity.project_id
                state_root = [string]$Context.LegacyStateRoot
                target_state_root = $stateRoot
                is_git = $true
                schema_version = [long]$legacyIdentity.schema_version
                mode = 'read_only_migration_required'
                project_revision = $null
                project_revision_sha256 = $null
                phases = @()
                tasks = $legacyTasks
                trash = $legacyTrash
            }
        }
        Throw-AgentTasksError -Code 'AT-STATE-NOT-INITIALIZED' -ExitCode 4 -SafeMessage 'Project authority has not been initialized.'
    }
    $identity = Read-AgentTasksJsonFile -LiteralPath $identityPath
    if ([long]$identity.schema_version -gt 1) {
        return [ordered]@{
            project_id = $(if ($identity.Contains('project_id')) { [string]$identity.project_id } else { $null })
            state_root = $stateRoot
            target_state_root = $stateRoot
            is_git = [bool]$Context.IsGit
            schema_version = [long]$identity.schema_version
            mode = 'read_only_newer_schema'
            project_revision = $null
            project_revision_sha256 = $null
            phases = @()
            tasks = @()
            trash = @()
        }
    }
    $chain = Get-AgentTasksRevisionChain -StateDirectory $stateDirectory
    if ($chain.Status -cne 'valid') {
        Throw-AgentTasksError -Code 'AT-REVISION-CHAIN' -ExitCode 4 -SafeMessage 'Project authority requires reconciliation.'
    }
    $phaseIds = if (Test-Path -LiteralPath (Join-Path $stateRoot 'phases')) {
        @(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'phases') -Directory | Sort-Object Name | ForEach-Object Name)
    } else { @() }
    $taskIds = if (Test-Path -LiteralPath (Join-Path $stateRoot 'tasks')) {
        @(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'tasks') -Directory | Sort-Object Name | ForEach-Object Name)
    } else { @() }
    $trashIds = if (Test-Path -LiteralPath (Join-Path $stateRoot 'trash')) {
        @(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'trash') -Directory | Sort-Object Name | ForEach-Object Name)
    } else { @() }
    $activeSet = [Collections.Generic.HashSet[string]]::new([string[]]@($taskIds), [StringComparer]::Ordinal)
    foreach ($trashId in $trashIds) {
        if ($activeSet.Contains([string]$trashId)) {
            Throw-AgentTasksError -Code 'AT-TASK-DUPLICATE' -ExitCode 4 -SafeMessage 'A task identifier exists in both active and trash authority.'
        }
    }
    return [ordered]@{
        project_id = [string]$identity.project_id
        state_root = $stateRoot
        target_state_root = $stateRoot
        is_git = [bool]$Context.IsGit
        schema_version = [long]$identity.schema_version
        mode = 'read_write'
        project_revision = [long]$chain.Records[-1].revision
        project_revision_sha256 = Get-AgentTasksSha256 -LiteralPath (Join-Path $stateDirectory ('R{0:D6}.json' -f [long]$chain.Records[-1].revision))
        phases = $phaseIds
        tasks = $taskIds
        trash = $trashIds
    }
}
