#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Topic04TempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$script:Topic04TempPrefix = 'omp-topic04-'
$script:Topic04FixtureRoots = [Collections.Generic.List[string]]::new()

function New-Topic04FixtureRoot {
    param([string]$Label = 'fixture')

    $safeLabel = $Label -replace '[^A-Za-z0-9-]', '-'
    $path = Join-Path $script:Topic04TempBase (
        '{0}{1}-{2}' -f $script:Topic04TempPrefix, $safeLabel, [guid]::NewGuid().ToString('N')
    )
    [void](New-Item -ItemType Directory -Path $path)
    $resolved = [IO.Path]::GetFullPath($path)
    [void]$script:Topic04FixtureRoots.Add($resolved)
    return $resolved
}

function Remove-Topic04FixtureRoots {
    foreach ($path in @($script:Topic04FixtureRoots)) {
        $resolved = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if (
            $parent -cne $script:Topic04TempBase -or
            -not $leaf.StartsWith($script:Topic04TempPrefix, [StringComparison]::Ordinal)
        ) {
            throw "Refusing unsafe Topic 04 fixture cleanup target: $resolved"
        }

        if (Test-Path -LiteralPath $resolved) {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
    $script:Topic04FixtureRoots.Clear()
}

function Set-Topic04Utf8File {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $parent = Split-Path -Parent $LiteralPath
    if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllText($LiteralPath, $Content, [Text.UTF8Encoding]::new($false))
}

function Initialize-Topic04GitFixture {
    param([Parameter(Mandatory)][string]$Root)

    $repository = Join-Path $Root 'repository'
    [void](New-Item -ItemType Directory -Path $repository)
    & git -C $repository init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Failed to initialize Topic 04 Git fixture.' }
    & git -C $repository config user.name 'Topic 04 Test'
    & git -C $repository config user.email 'topic04@example.invalid'
    Set-Topic04Utf8File -LiteralPath (Join-Path $repository 'README.md') -Content "fixture`n"
    & git -C $repository add README.md
    & git -C $repository commit --quiet -m 'fixture baseline'
    if ($LASTEXITCODE -ne 0) { throw 'Failed to commit Topic 04 Git fixture baseline.' }
    return $repository
}

function Add-Topic04LinkedWorktree {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Root
    )

    $linked = Join-Path $Root 'linked-worktree'
    $branch = 'topic04-linked-{0}' -f [guid]::NewGuid().ToString('N')
    & git -C $Repository worktree add --quiet -b $branch $linked
    if ($LASTEXITCODE -ne 0) { throw 'Failed to add Topic 04 linked worktree.' }
    return $linked
}

function Get-Topic04TreeFingerprint {
    param([Parameter(Mandatory)][string]$LiteralPath)

    if (-not (Test-Path -LiteralPath $LiteralPath)) { return '<absent>' }
    $root = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    $rows = foreach ($item in Get-ChildItem -LiteralPath $root -Force -Recurse | Sort-Object FullName) {
        $relative = $item.FullName.Substring($root.Length).TrimStart('\', '/')
        if ($item.PSIsContainer) {
            "D|$relative"
        } else {
            "F|$relative|$((Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash)"
        }
    }
    return $rows -join "`n"
}

function Get-Topic04WorktreeFingerprint {
    param([Parameter(Mandatory)][string]$LiteralPath)

    $root = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    $rows = foreach ($item in Get-ChildItem -LiteralPath $root -Force -Recurse | Sort-Object FullName) {
        $relative = $item.FullName.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
        if ($relative -eq '.git' -or $relative.StartsWith('.git/', [StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($relative -eq '.agent-tasks' -or $relative.StartsWith('.agent-tasks/', [StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($item.PSIsContainer) {
            "D|$relative"
        } else {
            "F|$relative|$((Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash)"
        }
    }
    return $rows -join "`n"
}

function Invoke-Topic04Cli {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Json
    )

    $requestPath = Join-Path $FixtureRoot ('request-{0}.json' -f [guid]::NewGuid().ToString('N'))
    Set-Topic04Utf8File -LiteralPath $requestPath -Content $Json
    $stdoutPath = Join-Path $FixtureRoot ('stdout-{0}.txt' -f [guid]::NewGuid().ToString('N'))
    $stderrPath = Join-Path $FixtureRoot ('stderr-{0}.txt' -f [guid]::NewGuid().ToString('N'))
    $process = Start-Process -FilePath 'pwsh' -ArgumentList @(
        '-NoProfile', '-File', $CliPath, '-RequestPath', $requestPath
    ) -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    $stdout = if (Test-Path -LiteralPath $stdoutPath) { [IO.File]::ReadAllText($stdoutPath).Trim() } else { '' }
    $stderr = if (Test-Path -LiteralPath $stderrPath) { [IO.File]::ReadAllText($stderrPath).Trim() } else { '' }
    $parsed = $null
    if ($stdout) { $parsed = $stdout | ConvertFrom-Json -Depth 64 }
    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        Stdout = $stdout
        Stderr = $stderr
        Parsed = $parsed
        StdoutLineCount = @($stdout -split "`r?`n" | Where-Object { $_ -ne '' }).Count
    }
}

function Invoke-Topic04CliObject {
    param(
        [Parameter(Mandatory)][string]$CliPath,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][Collections.IDictionary]$Request,
        [string]$SessionRef = 'codex:test-session',
        [string]$Runtime = 'codex'
    )

    $envelope = [ordered]@{
        schema_version = 1
        operation = $Operation
        working_directory = [IO.Path]::GetFullPath($WorkingDirectory)
        session_ref = $SessionRef
        runtime = $Runtime
        request = $Request
    }
    $json = $envelope | ConvertTo-Json -Depth 64 -Compress
    return Invoke-Topic04Cli -CliPath $CliPath -FixtureRoot $FixtureRoot -Json $json
}
