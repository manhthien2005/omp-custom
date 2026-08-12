#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Flash', 'Pro')]
    [string]$Model
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic03-deepseek-routing.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    throw 'Topic 03 DeepSeek routing helper is missing.'
}
. $helperPath

$modelKey = $Model.ToLowerInvariant()
$modelId = if ($Model -eq 'Flash') { 'ds/deepseek-v4-flash' } else { 'ds/deepseek-v4-pro' }
$selector = "omniroute/${modelId}:xhigh"
$sentinel = "TOPIC03_DEEPSEEK_$($Model.ToUpperInvariant())_OK"
$prompt = "Use the read tool exactly once to read README.md. Then answer with the exact sentinel $sentinel and no other prose."

$ompCommand = Get-Command omp -ErrorAction Stop
$arguments = @(
    '-p',
    $prompt,
    '--model',
    $selector,
    '--thinking',
    'xhigh',
    '--tools',
    'read',
    '--mode',
    'json',
    '--no-session',
    '--no-extensions',
    '--no-skills',
    '--no-rules',
    '--max-time',
    '2m'
)

$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $ompCommand.Source
$startInfo.WorkingDirectory = $repositoryRoot
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.CreateNoWindow = $true
foreach ($argument in $arguments) {
    [void]$startInfo.ArgumentList.Add($argument)
}

$process = [Diagnostics.Process]::new()
$process.StartInfo = $startInfo
[void]$process.Start()
$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()
$process.WaitForExit()
$stdout = $stdoutTask.GetAwaiter().GetResult()
$stderr = $stderrTask.GetAwaiter().GetResult()
$exitCode = $process.ExitCode
$process.Dispose()

$jsonLines = @($stdout -split "\r?\n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$state = Get-Topic03DeepSeekSmokeState -ExitCode $exitCode -JsonLines $jsonLines -ExpectedSentinel $sentinel

$sha = [Security.Cryptography.SHA256]::Create()
try {
    $outputHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stdout)))).Replace('-', '')
} finally {
    $sha.Dispose()
}

$run = [ordered]@{
    model = $Model
    selector = $selector
    status = $state.Status
    reason_code = $state.ReasonCode
    read_tool_seen = [bool]$state.ReadToolSeen
    sentinel_seen = [bool]$state.SentinelSeen
    process_exit_code = $exitCode
    stderr_seen = -not [string]::IsNullOrWhiteSpace($stderr)
    output_sha256 = $outputHash
    observed_at_utc = [DateTime]::UtcNow.ToString('o')
}

$evidenceDirectory = Join-Path $repositoryRoot 'docs\evidence\current-product\topic-03'
$evidencePath = Join-Path $evidenceDirectory 'deepseek-smoke.yml'
$runs = [ordered]@{}
if (Test-Path -LiteralPath $evidencePath -PathType Leaf) {
    try {
        $existing = Get-Content -Raw -LiteralPath $evidencePath -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($null -ne $existing.runs) {
            foreach ($property in $existing.runs.PSObject.Properties) {
                $runs[$property.Name] = $property.Value
            }
        }
    } catch {
        throw 'Existing DeepSeek smoke evidence is not valid JSON-compatible YAML; refusing to overwrite it.'
    }
}
$runs[$modelKey] = [pscustomobject]$run

$runStatuses = @($runs.Values | ForEach-Object status)
$overallStatus = if ($runStatuses -contains 'FAIL') {
    'FAIL'
} elseif ($runStatuses -contains 'ENVIRONMENT_BLOCKED') {
    'ENVIRONMENT_BLOCKED'
} elseif ($runs.Contains('flash') -and $runs.Contains('pro')) {
    'PASS'
} else {
    'ENVIRONMENT_BLOCKED'
}
$overallReason = if ($runStatuses -contains 'ENVIRONMENT_BLOCKED') {
    'DEEPSEEK_CREDENTIAL_MISSING'
} elseif (-not ($runs.Contains('flash') -and $runs.Contains('pro'))) {
    'SMOKE_MATRIX_INCOMPLETE'
} elseif ($runStatuses -contains 'FAIL') {
    'SMOKE_FAILED'
} else {
    'NONE'
}

$evidence = [ordered]@{
    schema_version = 1
    status = $overallStatus
    reason_code = $overallReason
    updated_at_utc = [DateTime]::UtcNow.ToString('o')
    runs = [pscustomobject]$runs
}

$evidenceChecks = @(Test-Topic03DeepSeekSmokeEvidence -Evidence ([pscustomobject]$evidence))
$evidenceFailures = @($evidenceChecks | Where-Object Status -eq 'FAIL')
if ($evidenceFailures.Count -gt 0) {
    throw "Refusing to write invalid smoke evidence: $($evidenceFailures.Code -join ', ')"
}

if (-not (Test-Path -LiteralPath $evidenceDirectory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $evidenceDirectory -Force)
}
# JSON is a valid YAML 1.2 document and keeps this evidence parser-free on PowerShell 5.1.
$evidence | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $evidencePath -Encoding UTF8

[pscustomobject]@{
    model = $Model
    selector = $selector
    status = $state.Status
    reason_code = $state.ReasonCode
    evidence = 'docs/evidence/current-product/topic-03/deepseek-smoke.yml'
} | ConvertTo-Json -Compress | Write-Output

if ($state.Status -eq 'FAIL') {
    exit 1
}
exit 0
