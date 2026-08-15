#Requires -Version 7.4
[CmdletBinding()]
param([switch]$SourceOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic07-context-continuity.ps1'
$installer = Join-Path $repositoryRoot 'scripts\install-template.ps1'
$sentinel = Join-Path $repositoryRoot 'scripts\tests\fixtures\topic07-provider-sentinel.mjs'
$runtimeProbe = Join-Path $repositoryRoot 'scripts\tests\fixtures\topic07-omp-runtime-probe.mjs'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic07-pressure-'
$roots = [Collections.Generic.List[string]]::new()
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    throw 'Topic 07 source-attachment helper is missing.'
}
. $helperPath

$script:Assertions = 0

function Assert-Topic07Canary {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic07CanaryRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path)
    $resolved = [IO.Path]::GetFullPath($path)
    [void]$roots.Add($resolved)
    return $resolved
}

function Initialize-Topic07CanaryProject {
    param([Parameter(Mandatory)][string]$Root)
    $project = Join-Path $Root 'repository'
    [void](New-Item -ItemType Directory -Path $project)
    & git -C $project init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the canary repository.' }
    & git -C $project config user.name 'Topic 07 Canary'
    & git -C $project config user.email 'topic07@example.invalid'
    [IO.File]::WriteAllText((Join-Path $project 'README.md'), "topic07 canary`n", [Text.UTF8Encoding]::new($false))
    & git -C $project add README.md
    & git -C $project commit --quiet -m 'canary baseline'
    if ($LASTEXITCODE -ne 0) { throw 'Could not commit the canary baseline.' }
    return $project
}

function Install-Topic07CanaryRuntime {
    param([Parameter(Mandatory)][string]$Project, [Parameter(Mandatory)][string]$OmpPath)
    $output = @(& pwsh -NoProfile -File $installer -Target project -ProjectDir $Project `
        -Components 'agents,workflows,skills,state,agents-md,rules-md,config,agent-boundary' `
        -OmpPath $OmpPath '-DryRun:$false' 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Canary runtime installation failed: $($output -join [Environment]::NewLine)"
    }
    return Get-Content -Raw -LiteralPath (Join-Path $Project '.omp\contracts\runtime.json') -Encoding UTF8 |
        ConvertFrom-Json
}

function Invoke-Topic07Process {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string[]]$Arguments,
        [AllowNull()][string]$InputLine,
        [Parameter(Mandatory)][Collections.IDictionary]$Environment,
        [int]$TimeoutMilliseconds = 30000,
        [string]$AcceptTimeoutMarker = ''
    )
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Executable
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) { [void]$startInfo.ArgumentList.Add($argument) }
    foreach ($entry in $Environment.GetEnumerator()) { $startInfo.Environment[[string]$entry.Key] = [string]$entry.Value }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        [void]$process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if ($null -ne $InputLine) {
            $process.StandardInput.WriteLine($InputLine)
            $process.StandardInput.Flush()
        } else {
            $process.StandardInput.Close()
        }
        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            try { $process.Kill($true) } catch {}
            try { $process.WaitForExit(5000) | Out-Null } catch {}
            $timeoutStdout = try { $stdoutTask.GetAwaiter().GetResult() } catch { '<stdout unavailable>' }
            $timeoutStderr = try { $stderrTask.GetAwaiter().GetResult() } catch { '<stderr unavailable>' }
            if ($AcceptTimeoutMarker -and $timeoutStdout.Contains($AcceptTimeoutMarker, [StringComparison]::Ordinal)) {
                return [pscustomobject]@{
                    ExitCode = 0
                    Stdout = $timeoutStdout
                    Stderr = $timeoutStderr
                    Combined = $timeoutStdout + $timeoutStderr
                    Lines = @($timeoutStdout -split "`r?`n" | Where-Object { $_ -ne '' })
                    ForcedStopAfterMarker = $true
                }
            }
            throw "OMP canary exceeded $TimeoutMilliseconds ms. Output: $timeoutStdout$timeoutStderr"
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Stdout = $stdout
            Stderr = $stderr
            Combined = $stdout + $stderr
            Lines = @($stdout -split "`r?`n" | Where-Object { $_ -ne '' })
            ForcedStopAfterMarker = $false
        }
    } finally {
        try { $process.StandardInput.Close() } catch {}
        $process.Dispose()
    }
}

function Get-Topic07PrefixedJson {
    param([Parameter(Mandatory)][object]$Result, [Parameter(Mandatory)][string]$Prefix)
    $lines = @($Result.Lines | Where-Object { ([string]$_).StartsWith($Prefix, [StringComparison]::Ordinal) })
    if ($lines.Count -ne 1) {
        throw "Expected one $Prefix record, got $($lines.Count). Output: $($Result.Combined)"
    }
    return ([string]$lines[0]).Substring($Prefix.Length) | ConvertFrom-Json -Depth 64
}

function Invoke-Topic07PressureCase {
    param(
        [Parameter(Mandatory)][string]$OmpPath,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][ValidateSet('blocked', 'control')][string]$Case
    )
    $root = New-Topic07CanaryRoot
    $project = Initialize-Topic07CanaryProject -Root $root
    $runtime = Install-Topic07CanaryRuntime -Project $project -OmpPath $OmpPath
    Assert-Topic07Canary ([string]$runtime.installed_omp_version -ceq $Version) `
        "Installed runtime identity drifted for OMP $Version."
    $counter = Join-Path $root 'provider-count.txt'
    [IO.File]::WriteAllText($counter, "0`n", [Text.UTF8Encoding]::new($false))
    $requestRoot = Join-Path $root 'requests'
    $sessionDir = Join-Path $root 'sessions'
    $agentHome = Join-Path $root 'agent-home'
    foreach ($directory in @($requestRoot, $sessionDir, $agentHome)) {
        [void](New-Item -ItemType Directory -Path $directory -Force)
    }
    $config = Join-Path $root 'canary.yml'
    [IO.File]::WriteAllText($config, @"
retry:
  enabled: false
  modelFallback: false
  usageAwareFallback: false
  fallbackChains:
    default: []
"@.Replace("`r`n", "`n"), [Text.UTF8Encoding]::new($false))

    $newSessionArguments = @(
        '--mode', 'rpc', '--no-skills', '--no-rules', '--no-tools', '--no-lsp', '--no-title',
        '--system-prompt', 'topic07 local pressure canary', '--session-dir', $sessionDir,
        '--model', 'topic07-sentinel/pressure-model',
        '--trusted-extension', $sentinel,
        '--trusted-extension', ([string]$runtime.paths.wrapper),
        '--trusted-extension', ([string]$runtime.paths.continuity_adapter),
        '--config', $config,
        '--config', ([string]$runtime.paths.overlay)
    )
    $environment = [ordered]@{
        PI_CODING_AGENT_DIR = $agentHome
        PI_TOKENIZER_ACCURATE = '0'
        OMP_TOPIC07_SENTINEL_COUNTER = $counter
        OMP_TOPIC07_RUNTIME_JSON = Join-Path $project '.omp\contracts\runtime.json'
        OMP_TOPIC07_REQUEST_ROOT = $requestRoot
        OMP_TOPIC07_CREATE_TASK = '1'
    }

    if ($Case -ceq 'blocked') {
        $seedFrame = [ordered]@{ id = 'topic07-seed'; type = 'prompt'; message = 'persist this local canary session' } |
            ConvertTo-Json -Compress
        $seed = Invoke-Topic07Process -Executable $OmpPath -WorkingDirectory $project `
            -Arguments $newSessionArguments -InputLine $seedFrame -Environment $environment
        $seedObservation = Get-Topic07PrefixedJson -Result $seed -Prefix 'TOPIC07_SENTINEL_RESULT='
        if ($seed.ExitCode -ne 0 -or [int]$seedObservation.sentinel_count -ne 1 -or
            -not (Test-Path -LiteralPath ([string]$seedObservation.session_file) -PathType Leaf)) {
            throw "Could not persist the seed session for OMP ${Version}: $($seed.Combined)"
        }
        [IO.File]::WriteAllText($counter, "0`n", [Text.UTF8Encoding]::new($false))
        $environment['OMP_TOPIC07_CREATE_TASK'] = '0'
        $arguments = @(
            '--mode', 'rpc', '--no-skills', '--no-rules', '--no-tools', '--no-lsp', '--no-title',
            '--resume', ([string]$seedObservation.session_file),
            '--trusted-extension', $sentinel,
            '--trusted-extension', ([string]$runtime.paths.wrapper),
            '--trusted-extension', ([string]$runtime.paths.continuity_adapter),
            '--config', $config,
            '--config', ([string]$runtime.paths.overlay)
        )
        $frame = [ordered]@{ id = 'topic07-blocked'; type = 'prompt'; message = ('p' * 120000) } |
            ConvertTo-Json -Compress
        $result = Invoke-Topic07Process -Executable $OmpPath -WorkingDirectory $project `
            -Arguments $arguments -InputLine $frame -Environment $environment
        $observation = Get-Topic07PrefixedJson -Result $result -Prefix 'TOPIC07_SENTINEL_RESULT='
    } else {
        $frame = [ordered]@{ id = 'topic07-control'; type = 'prompt'; message = 'control' } |
            ConvertTo-Json -Compress
        $result = Invoke-Topic07Process -Executable $OmpPath -WorkingDirectory $project `
            -Arguments $newSessionArguments -InputLine $frame -Environment $environment
        $observation = Get-Topic07PrefixedJson -Result $result -Prefix 'TOPIC07_SENTINEL_RESULT='
    }
    return [pscustomobject]@{
        Root = $root
        Project = $project
        Runtime = $runtime
        Counter = $counter
        SessionDir = $sessionDir
        Config = $config
        Environment = $environment
        Process = $result
        Observation = $observation
    }
}

function Test-Topic07SessionResume {
    param(
        [Parameter(Mandatory)][string]$OmpPath,
        [Parameter(Mandatory)][object]$Case
    )
    $sessionFile = [string]$Case.Observation.session_file
    $arguments = @(
        '--mode', 'rpc', '--no-skills', '--no-rules', '--no-tools', '--no-lsp', '--no-title',
        '--resume', $sessionFile,
        '--trusted-extension', $sentinel,
        '--trusted-extension', $runtimeProbe,
        '--trusted-extension', ([string]$Case.Runtime.paths.wrapper),
        '--trusted-extension', ([string]$Case.Runtime.paths.continuity_adapter),
        '--config', ([string]$Case.Config),
        '--config', ([string]$Case.Runtime.paths.overlay)
    )
    $environment = [ordered]@{}
    foreach ($entry in $Case.Environment.GetEnumerator()) { $environment[[string]$entry.Key] = [string]$entry.Value }
    $environment['OMP_TOPIC07_CREATE_TASK'] = '0'
    $result = Invoke-Topic07Process -Executable $OmpPath -WorkingDirectory $Case.Project `
        -Arguments $arguments -InputLine $null -Environment $environment -TimeoutMilliseconds 5000 `
        -AcceptTimeoutMarker 'TOPIC07_RUNTIME_PROBE='
    return [pscustomobject]@{
        Process = $result
        Observation = Get-Topic07PrefixedJson -Result $result -Prefix 'TOPIC07_RUNTIME_PROBE='
    }
}

try {
    $source = Test-Topic07SourceAttachments -RepositoryRoot $repositoryRoot
    Assert-Topic07Canary ($source.Status -ceq 'PASS') "OPEN-T07-RUNTIME-01: $($source.Message)"
    Assert-Topic07Canary (@($source.Attachments).Count -eq 15) 'The source-attachment set is incomplete.'

    $matrix = Resolve-Topic07RuntimeMatrix -RepositoryRoot $repositoryRoot
    $installed = @($matrix.Rows | Where-Object Version -ceq '17.2.12')
    Assert-Topic07Canary ($installed.Count -eq 1 -and $installed[0].Available) `
        'OMP 17.2.12 is not available through the installed managed runtime.'

    if ($SourceOnly) {
        Write-Host "PASS: Topic 07 source attachments ($script:Assertions assertions)." -ForegroundColor Green
        if ($matrix.Status -ceq 'IMPLEMENTED_NOT_PROMOTED') {
            Write-Host "BLOCKED: OPEN-T07-RUNTIME-02 - $($matrix.Message)" -ForegroundColor Yellow
        }
        exit 0
    }

    Assert-Topic07Canary (Test-Path -LiteralPath $sentinel -PathType Leaf) 'The provider sentinel fixture is missing.'
    $available = @($matrix.Rows | Where-Object Available)
    foreach ($runtimeRow in $available) {
        $blocked = Invoke-Topic07PressureCase -OmpPath ([string]$runtimeRow.Path) `
            -Version ([string]$runtimeRow.Version) -Case blocked
        Assert-Topic07Canary ($blocked.Process.ExitCode -eq 0) `
            "Blocked canary failed on OMP $($runtimeRow.Version): $($blocked.Process.Combined)"
        Assert-Topic07Canary (
            -not [string]$blocked.Observation.bootstrap.error -and
            [int]$blocked.Observation.sentinel_count -eq 0 -and
            [int]$blocked.Observation.pressure_observation_count -ge 1
        ) "The pressure case reached the provider or missed its abort observation on OMP $($runtimeRow.Version)."
        Assert-Topic07Canary ([int]$blocked.Observation.forbidden_entry_count -eq 0) `
            "The pressure case emitted an automatic compact/shake/handoff/retry/continuation entry on OMP $($runtimeRow.Version)."
        Assert-Topic07Canary (
            [string]$blocked.Observation.session_file -and
            (Test-Path -LiteralPath ([string]$blocked.Observation.session_file) -PathType Leaf)
        ) "The blocked session was not persisted on OMP $($runtimeRow.Version): $($blocked.Observation | ConvertTo-Json -Compress -Depth 16)"
        Assert-Topic07Canary (
            $blocked.Process.Combined.Contains('/safe-compact', [StringComparison]::Ordinal)
        ) "The blocked main session did not surface /safe-compact guidance on OMP $($runtimeRow.Version)."

        $resume = Test-Topic07SessionResume -OmpPath ([string]$runtimeRow.Path) -Case $blocked
        Assert-Topic07Canary ($resume.Process.ExitCode -eq 0 -and [bool]$resume.Observation.ok) `
            "The blocked session was not resumable on OMP $($runtimeRow.Version): $($resume.Process.Combined)"
        Assert-Topic07Canary (
            [bool]$resume.Observation.exact_profile_after_handlers -and
            [int](Get-Content -Raw -LiteralPath $blocked.Counter).Trim() -eq 0
        ) "Resuming the blocked session changed the provider count or managed profile on OMP $($runtimeRow.Version)."

        $control = Invoke-Topic07PressureCase -OmpPath ([string]$runtimeRow.Path) `
            -Version ([string]$runtimeRow.Version) -Case control
        Assert-Topic07Canary ($control.Process.ExitCode -eq 0) `
            "Control canary failed on OMP $($runtimeRow.Version): $($control.Process.Combined)"
        Assert-Topic07Canary (
            -not [string]$control.Observation.bootstrap.error -and
            [int]$control.Observation.sentinel_count -eq 1 -and
            [int]$control.Observation.pressure_observation_count -eq 0 -and
            [int]$control.Observation.forbidden_entry_count -eq 0
        ) "The below-threshold control did not reach the sentinel exactly once on OMP $($runtimeRow.Version)."
    }

    Write-Host "PASS: Topic 07 pressure canary ($script:Assertions assertions; $($available.Count) available runtime(s))." -ForegroundColor Green
    if ($matrix.Status -ceq 'IMPLEMENTED_NOT_PROMOTED') {
        Write-Host "BLOCKED: OPEN-T07-RUNTIME-02 - $($matrix.Message)" -ForegroundColor Yellow
    }
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in $roots) {
        $resolved = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 07 pressure cleanup target: $resolved"
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
