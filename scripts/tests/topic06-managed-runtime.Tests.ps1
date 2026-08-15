#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$installer = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic06-runtime-'
$roots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0

function Assert-Topic06Runtime {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic06RuntimeRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path -Force)
    [void]$roots.Add([IO.Path]::GetFullPath($path))
    return $path
}

function Install-Topic06RuntimeFixture {
    param([Parameter(Mandatory)][string]$Project, [string]$OmpPath)
    $arguments = @(
        '-NoProfile', '-File', $installer, '-Target', 'project', '-ProjectDir', $Project,
        '-Components', 'agents,workflows,skills,state,agents-md,rules-md,config,agent-boundary',
        '-DryRun:$false'
    )
    if ($OmpPath) { $arguments += @('-OmpPath', $OmpPath) }
    $output = @(& pwsh @arguments 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output -join [Environment]::NewLine }
}

function Invoke-Topic06Launcher {
    param(
        [Parameter(Mandatory)][string]$Launcher,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$InputText = '',
        [string]$WorkingDirectory = ''
    )
    $pushed = $false
    try {
        if ($WorkingDirectory) {
            Push-Location -LiteralPath $WorkingDirectory
            $pushed = $true
        }
        $output = if ($InputText) {
            @($InputText | & pwsh -NoProfile -File $Launcher @Arguments 2>&1)
        } else {
            @(& pwsh -NoProfile -File $Launcher @Arguments 2>&1)
        }
        $exitCode = $LASTEXITCODE
    } finally {
        if ($pushed) { Pop-Location }
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = $output -join [Environment]::NewLine; Lines = $output }
}

try {
    $fakeRoot = New-Topic06RuntimeRoot
    $fakeOmp = Join-Path $fakeRoot 'fake-omp.cmd'
    $capture = Join-Path $fakeRoot 'args.txt'
    [IO.File]::WriteAllText($fakeOmp, @'
@echo off
if "%~1"=="--version" (
  echo omp/17.2.12
  exit /b 0
)
> "%TOPIC06_OMP_CAPTURE%" echo %*
exit /b 0
'@, [Text.ASCIIEncoding]::new())
    $fakeProject = Join-Path $fakeRoot 'project'
    [void](New-Item -ItemType Directory -Path $fakeProject)
    $fakeInstall = Install-Topic06RuntimeFixture -Project $fakeProject -OmpPath $fakeOmp
    Assert-Topic06Runtime ($fakeInstall.ExitCode -eq 0) "Fake-runtime installation failed: $($fakeInstall.Output)"
    $fakeLauncher = Join-Path $fakeProject '.omp\bin\omp-managed.ps1'
    $env:TOPIC06_OMP_CAPTURE = $capture
    try {
        $launch = Invoke-Topic06Launcher -Launcher $fakeLauncher `
            -Arguments @('--config', 'caller.yml', '--mode', 'rpc', '--', '--no-session')
    } finally {
        Remove-Item Env:TOPIC06_OMP_CAPTURE -ErrorAction SilentlyContinue
    }
    Assert-Topic06Runtime ($launch.ExitCode -eq 0) "Managed fake launch failed: $($launch.Output)"
    $captured = Get-Content -Raw -LiteralPath $capture
    $runtime = Get-Content -Raw -LiteralPath (Join-Path $fakeProject '.omp\contracts\runtime.json') | ConvertFrom-Json
    $callerIndex = $captured.IndexOf('--config caller.yml', [StringComparison]::Ordinal)
    $managedIndex = $captured.LastIndexOf("--config $($runtime.paths.overlay)", [StringComparison]::Ordinal)
    Assert-Topic06Runtime ($captured.Contains("--trusted-extension $($runtime.paths.wrapper)", [StringComparison]::Ordinal)) `
        'Launcher did not inject the exact trusted wrapper.'
    $wrapperIndex = $captured.IndexOf("--trusted-extension $($runtime.paths.wrapper)", [StringComparison]::Ordinal)
    $continuityIndex = $captured.IndexOf("--trusted-extension $($runtime.paths.continuity_adapter)", [StringComparison]::Ordinal)
    Assert-Topic06Runtime ($wrapperIndex -ge 0 -and $continuityIndex -gt $wrapperIndex -and $managedIndex -gt $continuityIndex) `
        'Launcher did not keep the continuity adapter final among trusted extensions.'
    Assert-Topic06Runtime ($callerIndex -ge 0 -and $managedIndex -gt $callerIndex) `
        'Managed overlay was not the final config overlay.'

    Remove-Item -LiteralPath $capture -Force
    $blocked = Invoke-Topic06Launcher -Launcher $fakeLauncher -Arguments @('--extension=shadow.js', '--version')
    Assert-Topic06Runtime ($blocked.ExitCode -ne 0 -and -not (Test-Path -LiteralPath $capture)) `
        'Launcher did not reject caller extension shadowing before OMP invocation.'

    $noSession = Invoke-Topic06Launcher -Launcher $fakeLauncher -Arguments @('--no-session')
    Assert-Topic06Runtime ($noSession.ExitCode -ne 0 -and -not (Test-Path -LiteralPath $capture)) `
        'Launcher did not reject --no-session in the OMP option region.'

    $actualProject = New-Topic06RuntimeRoot
    $actualInstall = Install-Topic06RuntimeFixture -Project $actualProject
    Assert-Topic06Runtime ($actualInstall.ExitCode -eq 0) "Actual-runtime installation failed: $($actualInstall.Output)"
    $launcher = Join-Path $actualProject '.omp\bin\omp-managed.ps1'
    $rpc = Invoke-Topic06Launcher -Launcher $launcher `
        -Arguments @('--mode', 'rpc', '--no-skills', '--no-rules') `
        -InputText '{"id":"topic06-state","type":"get_state"}' `
        -WorkingDirectory $actualProject
    Assert-Topic06Runtime ($rpc.ExitCode -eq 0) "Managed RPC startup failed: $($rpc.Output)"
    $frames = @($rpc.Lines | ForEach-Object {
        $line = [string]$_
        if ($line.StartsWith('{', [StringComparison]::Ordinal)) {
            try { $line | ConvertFrom-Json } catch { $null }
        }
    } | Where-Object { $null -ne $_ })
    $response = @($frames | Where-Object {
        $_.type -ceq 'response' -and $_.id -ceq 'topic06-state' -and $_.command -ceq 'get_state'
    })[0]
    Assert-Topic06Runtime ($response.success -eq $true) 'Managed RPC did not return a successful state response.'
    $tasks = @($response.data.dumpTools | Where-Object { $_.name -ceq 'task' })
    Assert-Topic06Runtime (
        $tasks.Count -eq 1 -and
        [string]$tasks[0].description -ceq
            'Dispatch one closed managed Scout, Worker, or Reviewer work unit through the Topic 06 boundary.'
    ) 'Trusted wrapper did not replace the native task surface exactly once.'

    $overlay = Join-Path $actualProject '.omp\contracts\managed-runtime.yml'
    Assert-Topic06Runtime (
        (Get-Content -Raw -LiteralPath $overlay -Encoding UTF8) -ceq "task:`n  softRequestBudget: 200`ncontextPromotion:`n  enabled: false`ncompaction:`n  enabled: false`n  strategy: off`n  midTurnEnabled: false`n  thresholdPercent: -1`n  thresholdTokens: -1`n  keepRecentTokens: 20000`n  autoContinue: false`n  idleEnabled: false`n  remoteEnabled: false`n  remoteStreamingV2Enabled: false`n  supersedeReads: true`n  dropUseless: true`n"
    ) 'Installed managed overlay bytes drifted from the combined continuity profile.'

    $tamperTargets = [ordered]@{
        wrapper = Join-Path $actualProject '.omp\extensions\agent-task-boundary.js'
        continuity = Join-Path $actualProject '.omp\extensions\context-continuity.js'
        agent = Join-Path $actualProject '.omp\agents\cheap-scout.md'
        state = Join-Path $actualProject '.omp\state\manifest.json'
        component = Join-Path $actualProject '.omp\contracts\component-manifest.json'
    }
    foreach ($entry in $tamperTargets.GetEnumerator()) {
        $original = [IO.File]::ReadAllBytes([string]$entry.Value)
        try {
            Add-Content -LiteralPath ([string]$entry.Value) -Value '// drift'
            $tampered = Invoke-Topic06Launcher -Launcher $launcher -Arguments @('--version') `
                -WorkingDirectory $actualProject
            Assert-Topic06Runtime ($tampered.ExitCode -ne 0) `
                "Launcher accepted hash drift in the $($entry.Key) boundary surface."
        } finally {
            [IO.File]::WriteAllBytes([string]$entry.Value, $original)
        }
    }

    Write-Host "PASS: Topic 06 managed runtime ($script:Assertions assertions)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item Env:TOPIC06_OMP_CAPTURE -ErrorAction SilentlyContinue
    foreach ($root in $roots) {
        $resolved = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 06 runtime cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) {
            for ($attempt = 1; $attempt -le 20; $attempt++) {
                try {
                    Remove-Item -LiteralPath $resolved -Recurse -Force
                    break
                } catch {
                    if ($attempt -eq 20) { throw }
                    Start-Sleep -Milliseconds 100
                }
            }
        }
    }
}
