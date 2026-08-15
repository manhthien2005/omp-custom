#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command Resolve-AgentTasksContext -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'AgentTasks.Store.ps1')
}

function Invoke-AgentTasksGitBytes {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @('-C', $WorkingDirectory) + $Arguments) {
        [void]$startInfo.ArgumentList.Add([string]$argument)
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEnd()
        [void]$process.StandardError.ReadToEnd()
        $process.WaitForExit()
    } catch {
        Throw-AgentTasksError -Code 'AT-GIT-UNAVAILABLE' -ExitCode 4 -SafeMessage 'Git could not be executed.'
    } finally {
        $exitCode = if ($process.HasExited) { $process.ExitCode } else { -1 }
        $process.Dispose()
    }
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        Throw-AgentTasksError -Code 'AT-GIT-UNAVAILABLE' -ExitCode 4 -SafeMessage 'Git metadata could not be resolved.'
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Text = $stdout }
}

function Get-AgentTasksRelativePath {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$LiteralPath
    )
    return ([IO.Path]::GetRelativePath($Root, $LiteralPath) -replace '\\', '/')
}

function Get-AgentTasksFileIdentity {
    param(
        [Parameter(Mandatory)][string]$WorktreeRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [string]$IndexMode = '000000',
        [AllowNull()][string]$IndexObjectId = $null
    )

    $normalized = $RelativePath -replace '\\', '/'
    $literalPath = [IO.Path]::GetFullPath((Join-Path $WorktreeRoot ($normalized -replace '/', [IO.Path]::DirectorySeparatorChar)))
    Assert-AgentTasksPathInside -Root $WorktreeRoot -Candidate $literalPath
    if (-not (Test-Path -LiteralPath $literalPath)) {
        $absent = [ordered]@{
            path = $normalized
            presence = 'absent'
            file_type = 'absent'
            mode = $IndexMode
            sha256 = $null
        }
        if ($IndexMode -ceq '160000') { $absent.gitlink_commit = $IndexObjectId }
        return $absent
    }
    $item = Get-Item -LiteralPath $literalPath -Force
    if ($IndexMode -ceq '160000') {
        $gitlinkCommit = $IndexObjectId
        if (-not $gitlinkCommit) {
            $result = Invoke-AgentTasksGitBytes -WorkingDirectory $literalPath -Arguments @('rev-parse', 'HEAD') -AllowFailure
            if ($result.ExitCode -eq 0) { $gitlinkCommit = $result.Text.Trim() }
        }
        $hash = if ($gitlinkCommit) { Get-AgentTasksSha256 -Value ([ordered]@{ mode = '160000'; commit = $gitlinkCommit }) } else { $null }
        $fileType = 'gitlink'
    } elseif ($IndexMode -ceq '120000' -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        $target = [string]$item.LinkTarget
        if (-not $target) { $target = [IO.File]::ReadAllText($literalPath) }
        $hash = Get-AgentTasksSha256 -Value $target
        $fileType = 'symlink'
    } elseif ($item.PSIsContainer) {
        $hash = $null
        $fileType = 'directory'
    } else {
        $hash = Get-AgentTasksSha256 -LiteralPath $literalPath
        $fileType = 'regular'
    }
    $identity = [ordered]@{
        path = $normalized
        presence = 'present'
        file_type = $fileType
        mode = $IndexMode
        sha256 = $hash
    }
    if ($fileType -ceq 'gitlink') { $identity.gitlink_commit = $gitlinkCommit }
    return $identity
}

function Get-AgentTasksGitIndexEntries {
    param([Parameter(Mandatory)][string]$WorktreeRoot)

    $entries = [Collections.Generic.List[object]]::new()
    $stageOutput = (Invoke-AgentTasksGitBytes -WorkingDirectory $WorktreeRoot -Arguments @('ls-files', '--stage', '-z')).Text
    foreach ($row in @($stageOutput -split "`0" | Where-Object { $_ })) {
        if ($row -match '^([0-9]{6})\s+([0-9a-fA-F]+)\s+([0-3])\t(.+)$') {
            [void]$entries.Add([ordered]@{
                path = ($Matches[4] -replace '\\', '/')
                mode = $Matches[1]
                object_id = $Matches[2].ToLowerInvariant()
                stage = [int]$Matches[3]
            })
        }
    }
    return @($entries.ToArray() | Sort-Object path, stage)
}

function Get-AgentTasksGitStatusPaths {
    param([Parameter(Mandatory)][string]$WorktreeRoot)

    $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $statusOutput = (Invoke-AgentTasksGitBytes -WorkingDirectory $WorktreeRoot -Arguments @(
        'status', '--porcelain=v2', '-z', '--untracked-files=all'
    )).Text
    $rows = @($statusOutput -split "`0")
    for ($index = 0; $index -lt $rows.Count; $index++) {
        $row = $rows[$index]
        if (-not $row) { continue }
        $path = $null
        if ($row.StartsWith('? ', [StringComparison]::Ordinal)) {
            $path = $row.Substring(2)
        } elseif ($row -match '^1 (?:\S+ ){7}(.+)$') {
            $path = $Matches[1]
        } elseif ($row -match '^2 (?:\S+ ){8}(.+)$') {
            $path = $Matches[1]
            $index++
        } elseif ($row -match '^u (?:\S+ ){9}(.+)$') {
            $path = $Matches[1]
        }
        if ($path) { [void]$paths.Add(($path -replace '\\', '/')) }
    }
    return @($paths | Sort-Object)
}

function Get-AgentTasksRegisteredSubmodules {
    param([Parameter(Mandatory)][string]$WorktreeRoot)

    $result = Invoke-AgentTasksGitBytes -WorkingDirectory $WorktreeRoot -Arguments @('submodule', 'status', '--recursive') -AllowFailure
    $entries = [Collections.Generic.List[object]]::new()
    if ($result.ExitCode -eq 0) {
        foreach ($line in @($result.Text -split "`r?`n" | Where-Object { $_ })) {
            if ($line -match '^([ +-U])([0-9a-fA-F]{40,64})\s+([^\s]+)') {
                [void]$entries.Add([ordered]@{
                    marker = $Matches[1]
                    commit = $Matches[2].ToLowerInvariant()
                    path = ($Matches[3] -replace '\\', '/')
                })
            }
        }
    }
    return @($entries.ToArray() | Sort-Object path)
}

function Test-AgentTasksNestedRepositories {
    param([Parameter(Mandatory)][string]$WorktreeRoot)

    $submodules = @(Get-AgentTasksRegisteredSubmodules -WorktreeRoot $WorktreeRoot)
    $submodulePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($submodule in $submodules) {
        [void]$submodulePaths.Add([string]$submodule.path)
        if ([string]$submodule.marker -in @('-', '+', 'U')) {
            Throw-AgentTasksError -Code 'AT-NESTED-REPOSITORY-DIRTY' -ExitCode 3 -SafeMessage 'A registered submodule is unavailable, divergent, or conflicted.'
        }
        $submoduleRoot = Join-Path $WorktreeRoot (([string]$submodule.path) -replace '/', [IO.Path]::DirectorySeparatorChar)
        $status = Invoke-AgentTasksGitBytes -WorkingDirectory $submoduleRoot -Arguments @('status', '--porcelain=v2', '--untracked-files=all') -AllowFailure
        if ($status.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($status.Text)) {
            Throw-AgentTasksError -Code 'AT-NESTED-REPOSITORY-DIRTY' -ExitCode 3 -SafeMessage 'A registered submodule contains uncommitted bytes.'
        }
    }

    $root = [IO.Path]::GetFullPath($WorktreeRoot).TrimEnd('\', '/')
    $gitMarkers = @(Get-ChildItem -LiteralPath $root -Force -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -ceq '.git' -and
        -not $_.FullName.StartsWith((Join-Path $root 'node_modules'), [StringComparison]::OrdinalIgnoreCase)
    })
    foreach ($marker in $gitMarkers) {
        $nestedRoot = Split-Path -Parent $marker.FullName
        if ($nestedRoot -ceq $root) { continue }
        $relative = Get-AgentTasksRelativePath -Root $root -LiteralPath $nestedRoot
        if ($submodulePaths.Contains($relative)) { continue }
        $status = Invoke-AgentTasksGitBytes -WorkingDirectory $nestedRoot -Arguments @('status', '--porcelain=v2', '--untracked-files=all') -AllowFailure
        if ($status.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($status.Text)) {
            Throw-AgentTasksError -Code 'AT-NESTED-REPOSITORY-DIRTY' -ExitCode 3 -SafeMessage 'An unregistered nested repository contains uncommitted bytes.'
        }
    }
    return $true
}

function Get-AgentTasksGitIdentity {
    param([Parameter(Mandatory)][string]$WorkingDirectory)

    $context = Resolve-AgentTasksContext -WorkingDirectory $WorkingDirectory
    if (-not $context.IsGit) {
        return [ordered]@{
            is_git = $false
            worktree_root = [string]$context.WorktreeRoot
            git_dir = $null
            git_common_dir = $null
            head = $null
            branch = $null
            detached = $false
        }
    }
    $head = (Invoke-AgentTasksGitBytes -WorkingDirectory $context.WorktreeRoot -Arguments @('rev-parse', 'HEAD')).Text.Trim()
    $branchResult = Invoke-AgentTasksGitBytes -WorkingDirectory $context.WorktreeRoot -Arguments @('symbolic-ref', '--quiet', '--short', 'HEAD') -AllowFailure
    $branch = if ($branchResult.ExitCode -eq 0) { $branchResult.Text.Trim() } else { $null }
    return [ordered]@{
        is_git = $true
        worktree_root = [string]$context.WorktreeRoot
        git_dir = [string]$context.GitDir
        git_common_dir = [string]$context.GitCommonDir
        head = $head
        branch = $branch
        detached = $null -eq $branch
    }
}

function Get-AgentTasksWorkspaceSnapshot {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [string[]]$OwnedIgnoredOutputs = @()
    )

    $context = Resolve-AgentTasksContext -WorkingDirectory $WorkingDirectory
    $identity = Get-AgentTasksGitIdentity -WorkingDirectory $WorkingDirectory
    if (-not $context.IsGit) {
        return [ordered]@{
            schema_version = 1
            record_type = 'workspace_snapshot'
            git = $identity
            entries = @()
            owned_ignored_outputs = @()
            captured_at = Get-AgentTasksUtcTimestamp
        }
    }

    $indexEntries = @(Get-AgentTasksGitIndexEntries -WorktreeRoot $context.WorktreeRoot)
    $indexByPath = @{}
    foreach ($entry in $indexEntries) {
        if ([long]$entry.stage -eq 0) { $indexByPath[[string]$entry.path] = $entry }
    }
    $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($path in @(Get-AgentTasksGitStatusPaths -WorktreeRoot $context.WorktreeRoot)) { [void]$paths.Add($path) }
    foreach ($ignored in $OwnedIgnoredOutputs) {
        [void]$paths.Add(($ignored -replace '\\', '/'))
    }

    $entries = foreach ($path in @($paths | Sort-Object)) {
        $indexEntry = if ($indexByPath.ContainsKey($path)) { $indexByPath[$path] } else { $null }
        $mode = if ($null -ne $indexEntry) { [string]$indexEntry.mode } else { '000000' }
        $objectId = if ($null -ne $indexEntry) { [string]$indexEntry.object_id } else { $null }
        Get-AgentTasksFileIdentity -WorktreeRoot $context.WorktreeRoot -RelativePath $path -IndexMode $mode -IndexObjectId $objectId
    }
    return [ordered]@{
        schema_version = 1
        record_type = 'workspace_snapshot'
        git = $identity
        entries = @($entries)
        index_entries = @($indexEntries)
        submodules = @(Get-AgentTasksRegisteredSubmodules -WorktreeRoot $context.WorktreeRoot)
        owned_ignored_outputs = @($OwnedIgnoredOutputs | Sort-Object -Unique)
        captured_at = Get-AgentTasksUtcTimestamp
    }
}
