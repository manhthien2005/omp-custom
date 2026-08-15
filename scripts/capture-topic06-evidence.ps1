#Requires -Version 7.4
[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$evidenceDir = Join-Path $RepositoryRoot 'docs\evidence\current-product\topic-06'
[void](New-Item -ItemType Directory -Path $evidenceDir -Force)
$deterministicPath = Join-Path $evidenceDir 'deterministic.json'
$manifestPath = Join-Path $evidenceDir 'manifest.json'

function Get-Topic06CaptureSha256Text {
    param([AllowEmptyString()][string]$Text)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($Text)
    )).ToLowerInvariant()
}

function Get-Topic06CaptureFileSha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Write-Topic06CaptureJson {
    param([Parameter(Mandatory)][string]$LiteralPath, [Parameter(Mandatory)][object]$Value)
    $json = ($Value | ConvertTo-Json -Depth 64) + "`n"
    [IO.File]::WriteAllText($LiteralPath, $json, [Text.UTF8Encoding]::new($false))
}

function Invoke-Topic06CaptureProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [hashtable]$Environment = @{}
    )
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FilePath
    $psi.WorkingDirectory = $RepositoryRoot
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($argument in $Arguments) { [void]$psi.ArgumentList.Add($argument) }
    foreach ($entry in $Environment.GetEnumerator()) { $psi.Environment[$entry.Key] = [string]$entry.Value }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    if (-not $process.Start()) { throw "Could not start evidence command: $FilePath" }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        Stdout = $stdout
        Stderr = $stderr
        StdoutSha256 = Get-Topic06CaptureSha256Text $stdout
        StderrSha256 = Get-Topic06CaptureSha256Text $stderr
    }
}

function New-Topic06CaptureCase {
    param([Parameter(Mandatory)][object]$Run, [Parameter(Mandatory)][string]$Scope)
    [ordered]@{
        status = if ([int]$Run.ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
        exit_code = [int]$Run.ExitCode
        scope = $Scope
        stdout_sha256 = [string]$Run.StdoutSha256
        stderr_sha256 = [string]$Run.StderrSha256
        provider_calls = 0
        model_processes_started = 0
    }
}

function Get-Topic06GitOutput {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& git @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{ ExitCode = $exitCode; Text = (($output | ForEach-Object { [string]$_ }) -join "`n") }
}

try {
    # Ensure both untracked evidence paths participate in the dirty-tree identity before contents
    # are generated. Content changes do not change porcelain-v1 path/status lines.
    if (-not (Test-Path -LiteralPath $deterministicPath -PathType Leaf)) {
        [IO.File]::WriteAllText($deterministicPath, "{}`n", [Text.UTF8Encoding]::new($false))
    }
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        [IO.File]::WriteAllText($manifestPath, "{}`n", [Text.UTF8Encoding]::new($false))
    }

    $pwsh = [Environment]::ProcessPath
    $nodeCommand = Get-Command node -ErrorAction Stop
    $node = if ($nodeCommand.Source) { $nodeCommand.Source } else { $nodeCommand.Path }
    $cases = [ordered]@{}

    $run = Invoke-Topic06CaptureProcess $node @(
        '--test',
        'scripts/tests/topic06-contract-core.Tests.mjs',
        'scripts/tests/topic06-agent-contracts.Tests.mjs',
        'scripts/tests/topic06-result-receipt.Tests.mjs',
        'scripts/tests/topic06-omp-wrapper.Tests.mjs'
    )
    $cases.contract_core_roles_receipts_wrapper = New-Topic06CaptureCase $run `
        'Closed portable core, role contracts, receipts, and native wrapper seams.'

    foreach ($entry in ([ordered]@{
        state_projection = 'scripts/tests/topic06-state-projection.Tests.ps1'
        installer_transaction = 'scripts/tests/topic06-installer.Tests.ps1'
        installed_managed_runtime = 'scripts/tests/topic06-managed-runtime.Tests.ps1'
        adversarial_lifecycle_e2e = 'scripts/tests/topic06-agent-boundary.Tests.ps1'
    }).GetEnumerator()) {
        $run = Invoke-Topic06CaptureProcess $pwsh @('-NoProfile', '-File', $entry.Value)
        $cases[$entry.Key] = New-Topic06CaptureCase $run "Model-free $($entry.Key.Replace('_', ' '))."
    }

    $helperPath = Join-Path $RepositoryRoot 'scripts\lib\topic06-agent-boundary.ps1'
    . $helperPath
    $focused = @(Test-Topic06AgentBoundaryContract -RepositoryRoot $RepositoryRoot -SkipEvidence)
    $focusedFailures = @($focused | Where-Object Status -eq FAIL)
    $focusedText = ($focused | ForEach-Object { "$($_.Status)|$($_.Code)|$($_.Message)" }) -join "`n"
    $focusedRun = [pscustomobject]@{
        ExitCode = if ($focusedFailures.Count -eq 0) { 0 } else { 1 }
        StdoutSha256 = Get-Topic06CaptureSha256Text $focusedText
        StderrSha256 = Get-Topic06CaptureSha256Text ''
    }
    $cases.focused_contract_bootstrap = New-Topic06CaptureCase $focusedRun `
        "Focused authority/implementation validation without its not-yet-written evidence pair ($($focused.Count) records)."

    $run = Invoke-Topic06CaptureProcess $pwsh @('-NoProfile', '-File', 'scripts/validate-template.ps1') `
        @{ OMP_TOPIC06_CAPTURE = '1'; OMP_TOPIC07_CAPTURE = '1' }
    $cases.full_validator_bootstrap = New-Topic06CaptureCase $run `
        'Full repository validator with Topic 06 self-evidence and the downstream Topic 07 evidence hash skipped during dependency-ordered recapture.'

    $pinnedRoot = Join-Path $RepositoryRoot '_research\upstreams\oh-my-pi'
    $pinnedHead = Get-Topic06GitOutput @('-C', $pinnedRoot, 'rev-parse', 'HEAD')
    $pinnedStatus = Get-Topic06GitOutput @('-C', $pinnedRoot, 'status', '--short')
    $pinnedOk = $pinnedHead.ExitCode -eq 0 -and
        $pinnedHead.Text.Trim() -ceq '3a8591a8af5b6d200088d12ca75a5517cb064fa8' -and
        $pinnedStatus.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($pinnedStatus.Text)
    $pinnedText = "$($pinnedHead.Text.Trim())|clean=$([string]::IsNullOrWhiteSpace($pinnedStatus.Text))"
    $pinnedRun = [pscustomobject]@{
        ExitCode = if ($pinnedOk) { 0 } else { 1 }
        StdoutSha256 = Get-Topic06CaptureSha256Text $pinnedText
        StderrSha256 = Get-Topic06CaptureSha256Text ''
    }
    $cases.pinned_omp_source = New-Topic06CaptureCase $pinnedRun `
        'Pinned OMP commit and clean-source check for same-name delegation/runtime claims.'

    $allPass = @($cases.Values | Where-Object status -ne PASS).Count -eq 0
    $repoHead = (Get-Topic06GitOutput @('-C', $RepositoryRoot, 'rev-parse', 'HEAD')).Text.Trim()
    $porcelain = (Get-Topic06GitOutput @('-C', $RepositoryRoot, 'status', '--porcelain=v1', '--untracked-files=all')).Text
    $porcelainLines = @($porcelain -split "`n" | Where-Object { $_ } | Sort-Object)
    $porcelainCanonical = if ($porcelainLines.Count -eq 0) { '' } else { ($porcelainLines -join "`n") + "`n" }
    $topic06HeadProbe = Get-Topic06GitOutput @(
        '-C', $RepositoryRoot, 'cat-file', '-e', 'HEAD:template/.omp/contracts/agent-boundary-core.mjs'
    )

    $ompVersionOutput = @(& omp --version 2>&1)
    $ompVersionExit = $LASTEXITCODE
    $ompVersion = (($ompVersionOutput | ForEach-Object { [string]$_ }) -join "`n").Trim()
    if ($ompVersionExit -ne 0) { $ompVersion = 'unavailable' }
    $gitVersion = ((& git --version 2>&1) | ForEach-Object { [string]$_ }) -join ' '
    $nodeVersion = (& $node --version 2>&1 | ForEach-Object { [string]$_ }) -join ' '

    $evidence = [ordered]@{
        schema_version = 1
        record_type = 'topic06_agent_boundary_evidence'
        status = if ($allPass) { 'PASS' } else { 'FAIL' }
        captured_at_utc = [DateTime]::UtcNow.ToString('o')
        provider_calls = 0
        model_processes_started = 0
        repository = [ordered]@{
            head = $repoHead
            topic06_present_in_head = ($topic06HeadProbe.ExitCode -eq 0)
            working_tree_clean = ($porcelainLines.Count -eq 0)
            dirty_paths_sha256 = Get-Topic06CaptureSha256Text $porcelainCanonical
            dirty_paths_algorithm = 'sha256(sorted_git_porcelain_v1_lines_utf8_lf)'
        }
        environment = [ordered]@{
            os = [Runtime.InteropServices.RuntimeInformation]::OSDescription
            architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
            pwsh_version = $PSVersionTable.PSVersion.ToString()
            node_version = $nodeVersion
            git_version = $gitVersion
            installed_omp_version = $ompVersion
        }
        pinned_omp = [ordered]@{
            commit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
            version = '17.2.10'
            clean = $pinnedOk
        }
        cases = $cases
        limitations = [ordered]@{
            universal_internal_agent_hook = 'OPEN-T06-RUNTIME-01_NONBLOCKING'
            unrelated_vibe_eval_internal_agents = 'UNMANAGED'
            provider_smoke = 'NOT_RUN_MODEL_FREE_CAMPAIGN'
            parent_acceptance = 'NOT_GRANTED_BY_RECEIPT'
            operational_state = 'LOCAL_OUTSIDE_GIT'
        }
    }
    Write-Topic06CaptureJson $deterministicPath $evidence

    $manifestFiles = [ordered]@{
        'docs/evidence/current-product/topic-06/deterministic.json' = 'evidence'
        'docs/agent-boundaries.md' = 'authority_or_guide'
        'docs/architecture.md' = 'authority_or_guide'
        'docs/superpowers/specs/2026-08-13-topic-06-agent-boundary-contracts-design.md' = 'authority_or_guide'
        'docs/superpowers/plans/2026-08-13-topic-06-agent-boundary-contracts-plan.md' = 'authority_or_guide'
        'spec/key/04-decision-log.md' = 'authority_or_guide'
        'spec/key/01-dna.md' = 'authority_or_guide'
        'spec/03-agent-topology.md' = 'authority_or_guide'
        'spec/06-structured-output.md' = 'authority_or_guide'
        'spec/13-validation-and-evaluation.md' = 'authority_or_guide'
        'template/.omp/contracts/agent-boundary-schema.mjs' = 'implementation'
        'template/.omp/contracts/agent-boundary-core.mjs' = 'implementation'
        'template/.omp/contracts/agent-boundary-cli.mjs' = 'implementation'
        'template/.omp/contracts/managed-runtime.yml' = 'implementation'
        'template/.omp/contracts/component-manifest.json' = 'implementation'
        'template/.omp/extensions/agent-task-boundary.js' = 'implementation'
        'template/.omp/bin/omp-managed.ps1' = 'implementation'
        'template/.omp/state/agent-tasks.ps1' = 'implementation'
        'template/.omp/state/lib/AgentTasks.Projection.ps1' = 'implementation'
        'template/.omp/agents/cheap-scout.md' = 'implementation'
        'template/.omp/agents/worker.md' = 'implementation'
        'template/.omp/agents/reviewer.md' = 'implementation'
        'scripts/install-template.ps1' = 'implementation'
        'scripts/uninstall-template.ps1' = 'implementation'
        'scripts/lib/topic06-agent-boundary.ps1' = 'implementation'
        'scripts/validate-topic06-agent-boundary.ps1' = 'implementation'
        'scripts/capture-topic06-evidence.ps1' = 'implementation'
        'scripts/validate-template.ps1' = 'implementation'
        'scripts/tests/topic06-contract-core.Tests.mjs' = 'test_or_fixture'
        'scripts/tests/topic06-agent-contracts.Tests.mjs' = 'test_or_fixture'
        'scripts/tests/topic06-result-receipt.Tests.mjs' = 'test_or_fixture'
        'scripts/tests/topic06-omp-wrapper.Tests.mjs' = 'test_or_fixture'
        'scripts/tests/topic06-state-projection.Tests.ps1' = 'test_or_fixture'
        'scripts/tests/topic06-installer.Tests.ps1' = 'test_or_fixture'
        'scripts/tests/topic06-managed-runtime.Tests.ps1' = 'test_or_fixture'
        'scripts/tests/topic06-agent-boundary.Tests.ps1' = 'test_or_fixture'
        'scripts/tests/topic06-validator-mutations.Tests.ps1' = 'test_or_fixture'
        'scripts/tests/fixtures/topic06-boundary-e2e.mjs' = 'test_or_fixture'
    }
    $fileRows = foreach ($entry in $manifestFiles.GetEnumerator()) {
        $path = Join-Path $RepositoryRoot ($entry.Key -replace '/', '\')
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Evidence manifest input is missing: $($entry.Key)" }
        [ordered]@{ path = $entry.Key; role = $entry.Value; sha256 = Get-Topic06CaptureFileSha256 $path }
    }
    $manifest = [ordered]@{
        schema_version = 1
        record_type = 'topic06_current_product_manifest'
        generated_at_utc = [DateTime]::UtcNow.ToString('o')
        repository = [ordered]@{
            head = $repoHead
            topic06_present_in_head = ($topic06HeadProbe.ExitCode -eq 0)
            working_tree_clean = ($porcelainLines.Count -eq 0)
            dirty_paths_sha256 = Get-Topic06CaptureSha256Text $porcelainCanonical
            dirty_paths_algorithm = 'sha256(sorted_git_porcelain_v1_lines_utf8_lf)'
        }
        pinned_omp = [ordered]@{ commit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'; version = '17.2.10'; clean = $pinnedOk }
        environment = $evidence.environment
        files = @($fileRows)
        commands = @($cases.GetEnumerator() | ForEach-Object {
            [ordered]@{ id = $_.Key; exit_code = [int]$_.Value.exit_code; status = [string]$_.Value.status }
        })
    }
    Write-Topic06CaptureJson $manifestPath $manifest

    $deterministicHash = Get-Topic06CaptureFileSha256 $deterministicPath
    $manifestHash = Get-Topic06CaptureFileSha256 $manifestPath
    Write-Host "Topic 06 evidence: $($evidence.status)"
    Write-Host "deterministic.json SHA256: $deterministicHash"
    Write-Host "manifest.json SHA256: $manifestHash"
    if (-not $allPass) { exit 1 }
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
