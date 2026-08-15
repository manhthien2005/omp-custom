#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('retrieve')]
    [string]$Operation,

    [Parameter(Mandatory)][string]$RuntimePath,
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)][string]$QuestionBase64,
    [Parameter(Mandatory)][int]$MaxFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Topic05Stage = 'startup'

function Throw-Topic05CodeGraphReason {
    param([Parameter(Mandatory)][string]$Reason)
    $exception = [InvalidOperationException]::new('Topic 05 capability refusal.')
    $exception.Data['Topic05Reason'] = $Reason
    throw $exception
}

function Get-Topic05CodeGraphFailureEnvelope {
    param([Parameter(Mandatory)][string]$Reason)
    $partial = @('index_partial', 'index_pending_refs', 'graph_gap')
    $blocked = @(
        'component_uninstalled', 'unsupported_platform', 'state_component_missing',
        'state_binding_ambiguous', 'state_cache_not_owned', 'candidate_index_missing',
        'index_busy', 'index_missing', 'cancelled'
    )
    $status = if ($partial -ccontains $Reason) { 'partial' } elseif ($blocked -ccontains $Reason) {
        'blocked'
    } else { 'failed' }
    return [ordered]@{
        schema_version = 1
        ok = $false
        status = $status
        reason_code = $Reason
        fallback = 'native'
        data = $null
    }
}

function Write-Topic05CodeGraphEnvelope {
    param([Parameter(Mandatory)][object]$Envelope)
    [Console]::Out.WriteLine(($Envelope | ConvertTo-Json -Depth 24 -Compress))
}

function Assert-Topic05CodeGraphPropertySet {
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string]$Reason
    )
    if ($null -eq $Value) { Throw-Topic05CodeGraphReason -Reason $Reason }
    $actual = @($Value.PSObject.Properties.Name | Sort-Object)
    $wanted = @($Expected | Sort-Object)
    if (($actual -join '|') -cne ($wanted -join '|')) {
        Throw-Topic05CodeGraphReason -Reason $Reason
    }
}

function Get-Topic05CodeGraphSha256File {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        Throw-Topic05CodeGraphReason -Reason 'executable_missing'
    }
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-Topic05CodeGraphSha256Text {
    param([Parameter(Mandatory)][string]$Value)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Value)
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    } finally { $algorithm.Dispose() }
}

function Get-Topic05CodeGraphBundleTreeHash {
    param([Parameter(Mandatory)][string]$BundleRoot)
    $root = [IO.Path]::GetFullPath($BundleRoot).TrimEnd('\', '/')
    [string[]]$rows = foreach ($file in Get-ChildItem -LiteralPath $root -File -Recurse -Force) {
        $relative = $file.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
        if ($relative -ceq 'receipt.json') { continue }
        if ([bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            Throw-Topic05CodeGraphReason -Reason 'artifact_identity_mismatch'
        }
        "$relative|$($file.Length)|$((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant())"
    }
    [Array]::Sort($rows, [StringComparer]::Ordinal)
    return Get-Topic05CodeGraphSha256Text -Value ($rows -join "`n")
}

function Get-Topic05CodeGraphPathComparison {
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::Windows
    )) { return [StringComparison]::OrdinalIgnoreCase }
    return [StringComparison]::Ordinal
}

function Test-Topic05CodeGraphPathEqual {
    param([Parameter(Mandatory)][string]$Left, [Parameter(Mandatory)][string]$Right)
    return [IO.Path]::GetFullPath($Left).TrimEnd('\', '/').Equals(
        [IO.Path]::GetFullPath($Right).TrimEnd('\', '/'),
        (Get-Topic05CodeGraphPathComparison)
    )
}

function Test-Topic05CodeGraphPathInside {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Candidate)
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $candidateFull = [IO.Path]::GetFullPath($Candidate)
    return $candidateFull.StartsWith(
        $rootFull + [IO.Path]::DirectorySeparatorChar,
        (Get-Topic05CodeGraphPathComparison)
    )
}

function Test-Topic05CodeGraphReparsePoint {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $false }
    return [bool]((Get-Item -LiteralPath $LiteralPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Read-Topic05CodeGraphJson {
    param([Parameter(Mandatory)][string]$LiteralPath, [Parameter(Mandatory)][string]$Reason)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf) -or
        (Test-Topic05CodeGraphReparsePoint -LiteralPath $LiteralPath)) {
        Throw-Topic05CodeGraphReason -Reason $Reason
    }
    try { return Get-Content -Raw -LiteralPath $LiteralPath -Encoding UTF8 | ConvertFrom-Json }
    catch { Throw-Topic05CodeGraphReason -Reason $Reason }
}

function Get-Topic05CodeGraphPlatform {
    $architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    if ($architecture -eq [Runtime.InteropServices.Architecture]::X64) { $suffix = 'x64' }
    elseif ($architecture -eq [Runtime.InteropServices.Architecture]::Arm64) { $suffix = 'arm64' }
    else { Throw-Topic05CodeGraphReason -Reason 'unsupported_platform' }
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::Windows
    )) { return "win32-$suffix" }
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::OSX
    )) { return "darwin-$suffix" }
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::Linux
    )) { return "linux-$suffix" }
    Throw-Topic05CodeGraphReason -Reason 'unsupported_platform'
}

function ConvertFrom-Topic05CodeGraphQuestion {
    param([Parameter(Mandatory)][string]$Encoded)
    if ([string]::IsNullOrWhiteSpace($Encoded) -or $Encoded -cnotmatch '^[A-Za-z0-9_-]+$' -or
        ($Encoded.Length % 4) -eq 1) {
        Throw-Topic05CodeGraphReason -Reason 'query_failed'
    }
    $base64 = $Encoded.Replace('-', '+').Replace('_', '/')
    $base64 += '=' * ((4 - ($base64.Length % 4)) % 4)
    try {
        $bytes = [Convert]::FromBase64String($base64)
        $decoder = [Text.UTF8Encoding]::new($false, $true)
        $value = $decoder.GetString($bytes)
    } catch { Throw-Topic05CodeGraphReason -Reason 'query_failed' }
    $canonical = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    if ($canonical -cne $Encoded -or [string]::IsNullOrWhiteSpace($value) -or
        $value -cne $value.Trim() -or $value.IndexOf([char]0) -ge 0 -or
        $value -cne $value.Normalize([Text.NormalizationForm]::FormC)) {
        Throw-Topic05CodeGraphReason -Reason 'query_failed'
    }
    if (@($value.EnumerateRunes()).Count -gt 1024) {
        Throw-Topic05CodeGraphReason -Reason 'query_failed'
    }
    return $value
}

function Assert-Topic05CodeGraphRuntime {
    param([Parameter(Mandatory)][string]$LiteralPath)

    $script:Topic05Stage = 'runtime_read'
    $runtimeFull = [IO.Path]::GetFullPath($LiteralPath)
    $runtime = Read-Topic05CodeGraphJson -LiteralPath $runtimeFull -Reason 'component_uninstalled'
    $script:Topic05Stage = 'runtime_shape'
    Assert-Topic05CodeGraphPropertySet -Value $runtime -Reason 'runtime_manifest_invalid' -Expected @(
        'schema_version', 'record_type', 'component', 'component_version', 'created_at_utc',
        'target_omp', 'component_manifest_sha256', 'upstream_lock_sha256', 'receipt_sha256',
        'upstream', 'version', 'tag', 'commit', 'platform', 'artifact_sha256', 'paths'
    )
    Assert-Topic05CodeGraphPropertySet -Value $runtime.paths -Reason 'runtime_manifest_invalid' -Expected @(
        'bundle_root', 'receipt', 'launcher', 'node', 'library_entry', 'cli_entry', 'safe_init',
        'process_wrapper', 'pwsh'
    )
    if ([int]$runtime.schema_version -ne 1 -or $runtime.record_type -cne 'codegraph_target_runtime' -or
        $runtime.component -cne 'codegraph' -or $runtime.component_version -cne '1.0.0') {
        Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
    }
    foreach ($digestName in @(
        'component_manifest_sha256', 'upstream_lock_sha256', 'receipt_sha256', 'artifact_sha256'
    )) {
        if ([string]$runtime.$digestName -cnotmatch '^[0-9a-f]{64}$') {
            Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
        }
    }
    $script:Topic05Stage = 'runtime_platform'
    if ($runtime.platform -cne (Get-Topic05CodeGraphPlatform)) {
        Throw-Topic05CodeGraphReason -Reason 'unsupported_platform'
    }

    $targetOmp = [IO.Path]::GetFullPath([string]$runtime.target_omp).TrimEnd('\', '/')
    $bundleRoot = [IO.Path]::GetFullPath([string]$runtime.paths.bundle_root).TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $targetOmp -PathType Container) -or
        -not (Test-Path -LiteralPath $bundleRoot -PathType Container) -or
        (Test-Topic05CodeGraphReparsePoint $targetOmp) -or
        (Test-Topic05CodeGraphReparsePoint $bundleRoot)) {
        Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
    }
    $script:Topic05Stage = 'runtime_hashes'
    $componentManifestPath = Join-Path $targetOmp 'codegraph\component-manifest.json'
    $upstreamLockPath = Join-Path $targetOmp 'codegraph\upstream-lock.json'
    $stateManifestPath = Join-Path $targetOmp 'state\manifest.json'
    if (-not (Test-Path -LiteralPath $componentManifestPath -PathType Leaf)) {
        Throw-Topic05CodeGraphReason -Reason 'component_uninstalled'
    }
    if (-not (Test-Path -LiteralPath $upstreamLockPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath ([string]$runtime.paths.receipt) -PathType Leaf)) {
        Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
    }
    if ((Get-Topic05CodeGraphSha256File $componentManifestPath) -cne
        [string]$runtime.component_manifest_sha256 -or
        (Get-Topic05CodeGraphSha256File $upstreamLockPath) -cne
        [string]$runtime.upstream_lock_sha256 -or
        (Get-Topic05CodeGraphSha256File ([string]$runtime.paths.receipt)) -cne
        [string]$runtime.receipt_sha256) {
        Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
    }

    $script:Topic05Stage = 'component_manifest'
    $manifest = Read-Topic05CodeGraphJson $componentManifestPath 'runtime_manifest_invalid'
    Assert-Topic05CodeGraphPropertySet -Value $manifest -Reason 'runtime_manifest_invalid' -Expected @(
        'schema_version', 'record_type', 'component', 'component_version', 'minimum_pwsh_version',
        'requires', 'upstream_lock', 'files', 'generated_target_files'
    )
    $script:Topic05Stage = 'state_manifest'
    $stateRows = @($manifest.requires | Where-Object component -CEQ 'state')
    if ($stateRows.Count -ne 1 -or -not (Test-Path -LiteralPath $stateManifestPath -PathType Leaf) -or
        [string]$stateRows[0].sha256 -cne (Get-Topic05CodeGraphSha256File $stateManifestPath)) {
        Throw-Topic05CodeGraphReason -Reason 'state_component_missing'
    }

    $script:Topic05Stage = 'receipt_shape'
    $lock = Read-Topic05CodeGraphJson $upstreamLockPath 'runtime_manifest_invalid'
    $receipt = Read-Topic05CodeGraphJson ([string]$runtime.paths.receipt) 'runtime_manifest_invalid'
    Assert-Topic05CodeGraphPropertySet -Value $receipt -Reason 'runtime_manifest_invalid' -Expected @(
        'schema_version', 'record_type', 'upstream', 'version', 'tag', 'commit', 'platform',
        'bundle_root', 'receipt_path', 'artifact', 'required_files', 'bundle_tree_sha256',
        'provisioned_at_utc'
    )
    Assert-Topic05CodeGraphPropertySet -Value $receipt.artifact -Reason 'runtime_manifest_invalid' `
        -Expected @('name', 'size', 'sha256')
    Assert-Topic05CodeGraphPropertySet -Value $receipt.required_files -Reason 'runtime_manifest_invalid' `
        -Expected @('launcher', 'node', 'package', 'library_entry', 'cli_entry')

    $script:Topic05Stage = 'artifact_identity'
    foreach ($name in @('upstream', 'version', 'tag', 'commit', 'platform')) {
        if ([string]$runtime.$name -cne [string]$receipt.$name) {
            Throw-Topic05CodeGraphReason -Reason 'artifact_identity_mismatch'
        }
    }
    if ($runtime.upstream -cne $lock.upstream -or $runtime.version -cne $lock.version -or
        $runtime.tag -cne $lock.tag -or $runtime.commit -cne $lock.commit -or
        $runtime.artifact_sha256 -cne $receipt.artifact.sha256) {
        Throw-Topic05CodeGraphReason -Reason 'artifact_identity_mismatch'
    }
    $artifactRows = @($lock.artifacts | Where-Object platform -CEQ ([string]$runtime.platform))
    if ($artifactRows.Count -ne 1 -or $artifactRows[0].name -cne $receipt.artifact.name -or
        [long]$artifactRows[0].size -ne [long]$receipt.artifact.size -or
        $artifactRows[0].sha256 -cne $receipt.artifact.sha256) {
        Throw-Topic05CodeGraphReason -Reason 'artifact_identity_mismatch'
    }
    if (-not (Test-Topic05CodeGraphPathEqual $bundleRoot ([string]$receipt.bundle_root)) -or
        -not (Test-Topic05CodeGraphPathEqual ([string]$runtime.paths.receipt) ([string]$receipt.receipt_path))) {
        Throw-Topic05CodeGraphReason -Reason 'artifact_identity_mismatch'
    }

    $script:Topic05Stage = 'required_files'
    $runtimePathMap = [ordered]@{
        launcher = 'launcher'
        node = 'node'
        library_entry = 'library_entry'
        cli_entry = 'cli_entry'
    }
    foreach ($entry in $runtimePathMap.GetEnumerator()) {
        $record = $receipt.required_files.($entry.Key)
        Assert-Topic05CodeGraphPropertySet -Value $record -Reason 'runtime_manifest_invalid' `
            -Expected @('path', 'sha256')
        $expectedPath = [IO.Path]::GetFullPath((Join-Path $bundleRoot (
            [string]$record.path
        ).Replace('/', [IO.Path]::DirectorySeparatorChar)))
        if (-not (Test-Topic05CodeGraphPathInside $bundleRoot $expectedPath) -or
            -not (Test-Topic05CodeGraphPathEqual $expectedPath ([string]$runtime.paths.($entry.Value))) -or
            (Get-Topic05CodeGraphSha256File $expectedPath) -cne [string]$record.sha256) {
            Throw-Topic05CodeGraphReason -Reason 'artifact_identity_mismatch'
        }
    }
    $packageRecord = $receipt.required_files.package
    Assert-Topic05CodeGraphPropertySet -Value $packageRecord -Reason 'runtime_manifest_invalid' `
        -Expected @('path', 'sha256')
    $packagePath = [IO.Path]::GetFullPath((Join-Path $bundleRoot (
        [string]$packageRecord.path
    ).Replace('/', [IO.Path]::DirectorySeparatorChar)))
    if (-not (Test-Topic05CodeGraphPathInside $bundleRoot $packagePath) -or
        (Get-Topic05CodeGraphSha256File $packagePath) -cne [string]$packageRecord.sha256 -or
        (Get-Topic05CodeGraphBundleTreeHash $bundleRoot) -cne [string]$receipt.bundle_tree_sha256) {
        Throw-Topic05CodeGraphReason -Reason 'artifact_identity_mismatch'
    }
    $script:Topic05Stage = 'installed_paths'
    foreach ($name in @('safe_init', 'process_wrapper')) {
        $script:Topic05Stage = "installed_path_$name"
        $pathValue = [IO.Path]::GetFullPath([string]$runtime.paths.$name)
        if (-not (Test-Topic05CodeGraphPathInside $targetOmp $pathValue) -or
            -not (Test-Path -LiteralPath $pathValue -PathType Leaf) -or
            (Test-Topic05CodeGraphReparsePoint $pathValue)) {
            Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
        }
    }
    $script:Topic05Stage = 'installed_wrapper_identity'
    if (-not (Test-Topic05CodeGraphPathEqual ([string]$runtime.paths.process_wrapper) $PSCommandPath)) {
        Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
    }
    $currentPwsh = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $script:Topic05Stage = 'installed_pwsh_identity'
    if (-not (Test-Topic05CodeGraphPathEqual ([string]$runtime.paths.pwsh) $currentPwsh) -or
        $PSVersionTable.PSVersion -lt [Version]'7.4') {
        Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
    }

    return [pscustomobject]@{
        Runtime = $runtime
        Receipt = $receipt
        TargetOmp = $targetOmp
        BundleRoot = $bundleRoot
    }
}

function Invoke-Topic05CodeGraphProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][int]$TimeoutMs,
        [Parameter(Mandatory)][int]$StdoutLimitBytes,
        [Parameter(Mandatory)][int]$StderrLimitBytes
    )

    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $FilePath
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $ArgumentList) { [void]$start.ArgumentList.Add($argument) }
    foreach ($key in @($start.Environment.Keys)) {
        if ($key.StartsWith('CODEGRAPH_', [StringComparison]::OrdinalIgnoreCase) -or
            $key -ceq 'NODE_OPTIONS' -or $key -ceq 'NODE_PATH') {
            [void]$start.Environment.Remove($key)
        }
    }
    $start.Environment['CODEGRAPH_DIR'] = '.codegraph'
    $start.Environment['CODEGRAPH_TELEMETRY'] = '0'
    $start.Environment['CODEGRAPH_NO_UPDATE_CHECK'] = '1'
    $start.Environment['CODEGRAPH_NO_DAEMON'] = '1'
    $start.Environment['DO_NOT_TRACK'] = '1'
    $start.Environment['CI'] = '1'
    $start.Environment['NO_COLOR'] = '1'

    $watch = [Diagnostics.Stopwatch]::StartNew()
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $started = $false
    $finished = $false
    try {
        if (-not $process.Start()) {
            return [pscustomobject]@{ Ok = $false; Kind = 'nonzero'; ExitCode = -1; Stdout = ''; DurationMs = 0 }
        }
        $started = $true
        $process.StandardInput.Close()
        $stdoutStream = $process.StandardOutput.BaseStream
        $stderrStream = $process.StandardError.BaseStream
        $stdoutBuffer = [byte[]]::new(8192)
        $stderrBuffer = [byte[]]::new(8192)
        $stdoutMemory = [IO.MemoryStream]::new()
        $stderrMemory = [IO.MemoryStream]::new()
        $stdoutTask = $stdoutStream.ReadAsync($stdoutBuffer, 0, $stdoutBuffer.Length)
        $stderrTask = $stderrStream.ReadAsync($stderrBuffer, 0, $stderrBuffer.Length)
        $stdoutDone = $false
        $stderrDone = $false
        try {
            while (-not ($stdoutDone -and $stderrDone -and $process.HasExited)) {
                if ($watch.ElapsedMilliseconds -ge $TimeoutMs) {
                    try { $process.Kill($true) } catch { try { $process.Kill() } catch {} }
                    [void]$process.WaitForExit(5000)
                    $finished = $true
                    return [pscustomobject]@{
                        Ok = $false; Kind = 'timeout'; ExitCode = -1; Stdout = '';
                        DurationMs = $watch.ElapsedMilliseconds
                    }
                }
                if (-not $stdoutDone -and $stdoutTask.IsCompleted) {
                    $count = $stdoutTask.GetAwaiter().GetResult()
                    if ($count -eq 0) { $stdoutDone = $true } else {
                        if ($stdoutMemory.Length + $count -gt $StdoutLimitBytes) {
                            try { $process.Kill($true) } catch { try { $process.Kill() } catch {} }
                            [void]$process.WaitForExit(5000)
                            $finished = $true
                            return [pscustomobject]@{
                                Ok = $false; Kind = 'overflow'; ExitCode = -1; Stdout = '';
                                DurationMs = $watch.ElapsedMilliseconds
                            }
                        }
                        $stdoutMemory.Write($stdoutBuffer, 0, $count)
                        $stdoutTask = $stdoutStream.ReadAsync($stdoutBuffer, 0, $stdoutBuffer.Length)
                    }
                }
                if (-not $stderrDone -and $stderrTask.IsCompleted) {
                    $count = $stderrTask.GetAwaiter().GetResult()
                    if ($count -eq 0) { $stderrDone = $true } else {
                        if ($stderrMemory.Length + $count -gt $StderrLimitBytes) {
                            try { $process.Kill($true) } catch { try { $process.Kill() } catch {} }
                            [void]$process.WaitForExit(5000)
                            $finished = $true
                            return [pscustomobject]@{
                                Ok = $false; Kind = 'overflow'; ExitCode = -1; Stdout = '';
                                DurationMs = $watch.ElapsedMilliseconds
                            }
                        }
                        $stderrMemory.Write($stderrBuffer, 0, $count)
                        $stderrTask = $stderrStream.ReadAsync($stderrBuffer, 0, $stderrBuffer.Length)
                    }
                }
                if (-not ($stdoutDone -and $stderrDone -and $process.HasExited)) {
                    Start-Sleep -Milliseconds 5
                }
            }
            $finished = $true
            try { $stdout = [Text.UTF8Encoding]::new($false, $true).GetString($stdoutMemory.ToArray()) }
            catch {
                return [pscustomobject]@{
                    Ok = $false; Kind = 'invalid_utf8'; ExitCode = $process.ExitCode; Stdout = '';
                    DurationMs = $watch.ElapsedMilliseconds
                }
            }
        } finally {
            $stdoutMemory.Dispose()
            $stderrMemory.Dispose()
        }
        return [pscustomobject]@{
            Ok = ($process.ExitCode -eq 0)
            Kind = $(if ($process.ExitCode -eq 0) { 'ok' } else { 'nonzero' })
            ExitCode = $process.ExitCode
            Stdout = $stdout
            DurationMs = $watch.ElapsedMilliseconds
        }
    } finally {
        if ($started -and -not $finished) {
            try {
                if (-not $process.HasExited) { $process.Kill($true) }
                [void]$process.WaitForExit(5000)
            } catch {}
        }
        $watch.Stop()
        $process.Dispose()
    }
}

function Get-Topic05CodeGraphNormalizedSnapshot {
    param([Parameter(Mandatory)][string]$WorktreeRoot, [string[]]$OwnedIgnoredOutputs)
    $snapshot = Get-AgentTasksWorkspaceSnapshot -WorkingDirectory $WorktreeRoot `
        -OwnedIgnoredOutputs @($OwnedIgnoredOutputs)
    $projection = [ordered]@{}
    foreach ($key in $snapshot.Keys) {
        if ([string]$key -in @('captured_at', 'record_hash')) { continue }
        if ([string]$key -ceq 'entries') {
            $projection.entries = @($snapshot.entries | Where-Object {
                ([string]$_.path).Replace('\', '/') -cne '.codegraph/.gitignore'
            })
        } else { $projection[[string]$key] = $snapshot[$key] }
    }
    return [pscustomobject]@{
        Snapshot = $projection
        Sha256 = Get-AgentTasksTransferWorkspaceHash -Snapshot $projection
    }
}

function Get-Topic05CodeGraphBinding {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][bool]$IndexExists
    )
    $root = [IO.Path]::GetFullPath($Context.WorktreeRoot).TrimEnd('\', '/')
    $matches = @(
        foreach ($authority in @(Get-AgentTasksActiveTaskAuthorities -StateRoot $Context.StateRoot)) {
            $paths = @(
                [string]$authority.Revision.authoritative_worktree,
                [string]$authority.Revision.observation_worktree
            ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            if (@($paths | Where-Object { Test-Topic05CodeGraphPathEqual $_ $root }).Count -gt 0) {
                $authority
            }
        }
    )
    if ($matches.Count -gt 1) { Throw-Topic05CodeGraphReason -Reason 'state_binding_ambiguous' }
    if ($matches.Count -eq 0) {
        return [pscustomobject]@{
            Mode = 'observation'; Authority = $null; TaskId = $null; CandidateId = $null;
            CandidateHash = $null; OwnedIgnoredOutputs = @('.codegraph/.gitignore')
        }
    }
    $authority = $matches[0]
    $owned = @($authority.Contract.owned_ignored_outputs | ForEach-Object {
        ([string]$_).Replace('\', '/')
    })
    if ($owned -cnotcontains '.codegraph/.gitignore') {
        Throw-Topic05CodeGraphReason -Reason 'state_cache_not_owned'
    }
    $candidateId = if ($authority.Revision.Contains('selected_candidate_id')) {
        [string]$authority.Revision.selected_candidate_id
    } else { $null }
    $candidateHash = $null
    if (-not [string]::IsNullOrWhiteSpace($candidateId)) {
        if (-not $IndexExists) { Throw-Topic05CodeGraphReason -Reason 'candidate_index_missing' }
        $candidateResult = Test-AgentTasksCandidateCurrentUnlocked -Authority $authority `
            -CandidateId $candidateId
        if (-not $candidateResult.Valid) { Throw-Topic05CodeGraphReason -Reason 'candidate_drift' }
        $candidateHash = [string]$candidateResult.Candidate.record_hash
    }
    return [pscustomobject]@{
        Mode = 'task'
        Authority = $authority
        TaskId = [string]$authority.Contract.task_id
        CandidateId = $candidateId
        CandidateHash = $candidateHash
        OwnedIgnoredOutputs = $owned
    }
}

function Get-Topic05CodeGraphLock {
    param([Parameter(Mandatory)][string]$BundleRoot, [Parameter(Mandatory)][string]$WorktreeRoot)
    $versionRoot = Split-Path -Parent $BundleRoot
    $cacheRoot = Split-Path -Parent $versionRoot
    if ([IO.Path]::GetFileName($versionRoot) -cne 'v1.5.0') {
        Throw-Topic05CodeGraphReason -Reason 'runtime_manifest_invalid'
    }
    $locksRoot = Join-Path $cacheRoot 'locks'
    if (-not (Test-Path -LiteralPath $locksRoot -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $locksRoot -Force)
    }
    if (Test-Topic05CodeGraphReparsePoint $locksRoot) {
        Throw-Topic05CodeGraphReason -Reason 'index_busy'
    }
    $rootHash = Get-Topic05CodeGraphSha256Text -Value (
        [IO.Path]::GetFullPath($WorktreeRoot).TrimEnd('\', '/')
    )
    $lockPath = Join-Path $locksRoot ($rootHash + '.lock')
    $current = [Diagnostics.Process]::GetCurrentProcess()
    $metadata = [ordered]@{
        schema_version = 1
        worktree_sha256 = $rootHash
        pid = $PID
        process_start_utc = $current.StartTime.ToUniversalTime().ToString('o')
        created_at_utc = [DateTime]::UtcNow.ToString('o')
    }
    $ownedBytes = ($metadata | ConvertTo-Json -Compress) + "`n"
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while ($true) {
        try {
            $stream = [IO.File]::Open($lockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try {
                $bytes = [Text.UTF8Encoding]::new($false).GetBytes($ownedBytes)
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush($true)
            } finally { $stream.Dispose() }
            return [pscustomobject]@{ Path = $lockPath; OwnedBytes = $ownedBytes }
        } catch [IO.IOException] {
            if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) { continue }
            try {
                $observedBytes = [IO.File]::ReadAllText($lockPath, [Text.UTF8Encoding]::new($false))
                $observed = $observedBytes | ConvertFrom-Json
                Assert-Topic05CodeGraphPropertySet -Value $observed -Reason 'index_busy' -Expected @(
                    'schema_version', 'worktree_sha256', 'pid', 'process_start_utc', 'created_at_utc'
                )
                if ([int]$observed.schema_version -ne 1 -or $observed.worktree_sha256 -cne $rootHash -or
                    [int]$observed.pid -le 0) { Throw-Topic05CodeGraphReason -Reason 'index_busy' }
                $observedStart = if ($observed.process_start_utc -is [DateTime]) {
                    ([DateTime]$observed.process_start_utc).ToUniversalTime().ToString('o')
                } else { [string]$observed.process_start_utc }
                $alive = $false
                try {
                    $process = [Diagnostics.Process]::GetProcessById([int]$observed.pid)
                    try {
                        $alive = $process.StartTime.ToUniversalTime().ToString('o') -ceq
                            $observedStart
                    } finally { $process.Dispose() }
                } catch { $alive = $false }
                if (-not $alive) {
                    if ([IO.File]::ReadAllText($lockPath, [Text.UTF8Encoding]::new($false)) -ceq $observedBytes) {
                        [IO.File]::Delete($lockPath)
                        continue
                    }
                }
            } catch {
                $reason = [string]$_.Exception.Data['Topic05Reason']
                if ($reason) { throw }
                Throw-Topic05CodeGraphReason -Reason 'index_busy'
            }
            if ([DateTime]::UtcNow -ge $deadline) {
                Throw-Topic05CodeGraphReason -Reason 'index_busy'
            }
            Start-Sleep -Milliseconds 125
        }
    }
}

function Remove-Topic05CodeGraphOwnedLock {
    param([Parameter(Mandatory)][object]$Lock)
    try {
        if (Test-Path -LiteralPath $Lock.Path -PathType Leaf) {
            $current = [IO.File]::ReadAllText($Lock.Path, [Text.UTF8Encoding]::new($false))
            if ($current -ceq $Lock.OwnedBytes) { [IO.File]::Delete($Lock.Path) }
        }
    } catch {}
}

function Get-Topic05CodeGraphStatus {
    param(
        [Parameter(Mandatory)][object]$ResolvedRuntime,
        [Parameter(Mandatory)][string]$WorktreeRoot
    )
    $result = Invoke-Topic05CodeGraphProcess -FilePath ([string]$ResolvedRuntime.Runtime.paths.node) `
        -ArgumentList @(
            [string]$ResolvedRuntime.Runtime.paths.cli_entry, 'status', $WorktreeRoot, '--json'
        ) -WorkingDirectory $WorktreeRoot -TimeoutMs 10000 -StdoutLimitBytes 65536 `
        -StderrLimitBytes 8192
    if (-not $result.Ok) {
        if ($result.Kind -ceq 'timeout') { Throw-Topic05CodeGraphReason -Reason 'timeout' }
        if ($result.Kind -ceq 'overflow') { Throw-Topic05CodeGraphReason -Reason 'output_truncated' }
        Throw-Topic05CodeGraphReason -Reason 'index_unhealthy'
    }
    try { $status = $result.Stdout | ConvertFrom-Json }
    catch { Throw-Topic05CodeGraphReason -Reason 'index_unhealthy' }
    Assert-Topic05CodeGraphPropertySet -Value $status -Reason 'index_unhealthy' -Expected @(
        'initialized', 'version', 'projectPath', 'indexPath', 'lastIndexed', 'fileCount',
        'nodeCount', 'edgeCount', 'dbSizeBytes', 'backend', 'journalMode', 'nodesByKind',
        'languages', 'pendingChanges', 'worktreeMismatch', 'index'
    )
    Assert-Topic05CodeGraphPropertySet -Value $status.pendingChanges -Reason 'index_unhealthy' `
        -Expected @('added', 'modified', 'removed')
    Assert-Topic05CodeGraphPropertySet -Value $status.index -Reason 'index_unhealthy' -Expected @(
        'builtWithVersion', 'builtWithExtractionVersion', 'currentExtractionVersion',
        'reindexRecommended', 'state', 'pendingRefs'
    )
    if (-not $status.initialized) { Throw-Topic05CodeGraphReason -Reason 'index_missing' }
    if ($status.version -cne '1.5.0') { Throw-Topic05CodeGraphReason -Reason 'version_mismatch' }
    if (-not (Test-Topic05CodeGraphPathEqual ([string]$status.projectPath) $WorktreeRoot) -or
        -not (Test-Topic05CodeGraphPathEqual ([string]$status.indexPath) (Join-Path $WorktreeRoot '.codegraph')) -or
        $null -ne $status.worktreeMismatch) {
        Throw-Topic05CodeGraphReason -Reason 'worktree_mismatch'
    }
    if ([string]$status.index.state -ceq 'partial') {
        Throw-Topic05CodeGraphReason -Reason 'index_partial'
    }
    if ([long]$status.index.pendingRefs -gt 0) {
        Throw-Topic05CodeGraphReason -Reason 'index_pending_refs'
    }
    $pending = [long]$status.pendingChanges.added + [long]$status.pendingChanges.modified +
        [long]$status.pendingChanges.removed
    if ([string]$status.index.state -cne 'complete' -or $status.index.reindexRecommended -or
        $pending -ne 0) {
        Throw-Topic05CodeGraphReason -Reason 'index_unhealthy'
    }
    return $status
}

try {
    if ($Operation -cne 'retrieve' -or $MaxFiles -lt 1 -or $MaxFiles -gt 12) {
        Throw-Topic05CodeGraphReason -Reason 'query_failed'
    }
    $question = ConvertFrom-Topic05CodeGraphQuestion -Encoded $QuestionBase64
    $resolvedRuntime = Assert-Topic05CodeGraphRuntime -LiteralPath $RuntimePath

    $moduleNames = @(
        'AgentTasks.Common.ps1', 'AgentTasks.Store.ps1', 'AgentTasks.Git.ps1',
        'AgentTasks.Lifecycle.ps1', 'AgentTasks.Candidate.ps1', 'AgentTasks.Transfer.ps1'
    )
    foreach ($moduleName in $moduleNames) {
        $modulePath = Join-Path $resolvedRuntime.TargetOmp (Join-Path 'state\lib' $moduleName)
        if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
            Throw-Topic05CodeGraphReason -Reason 'state_component_missing'
        }
        . $modulePath
    }

    try { $context = Resolve-AgentTasksContext -WorkingDirectory $WorkingDirectory }
    catch { Throw-Topic05CodeGraphReason -Reason 'worktree_mismatch' }
    if (-not $context.IsGit) { Throw-Topic05CodeGraphReason -Reason 'worktree_mismatch' }
    $worktreeRoot = [IO.Path]::GetFullPath($context.WorktreeRoot).TrimEnd('\', '/')
    $indexPath = Join-Path $worktreeRoot '.codegraph'
    if (Test-Topic05CodeGraphReparsePoint $indexPath) {
        Throw-Topic05CodeGraphReason -Reason 'worktree_mismatch'
    }
    $indexExists = Test-Path -LiteralPath (Join-Path $indexPath 'codegraph.db') -PathType Leaf
    $binding = Get-Topic05CodeGraphBinding -Context $context -IndexExists $indexExists
    $snapshotBefore = Get-Topic05CodeGraphNormalizedSnapshot -WorktreeRoot $worktreeRoot `
        -OwnedIgnoredOutputs @($binding.OwnedIgnoredOutputs)
    $lock = Get-Topic05CodeGraphLock -BundleRoot $resolvedRuntime.BundleRoot `
        -WorktreeRoot $worktreeRoot
    try {
        $versionResult = Invoke-Topic05CodeGraphProcess `
            -FilePath ([string]$resolvedRuntime.Runtime.paths.node) `
            -ArgumentList @([string]$resolvedRuntime.Runtime.paths.cli_entry, '--version') `
            -WorkingDirectory $worktreeRoot -TimeoutMs 10000 -StdoutLimitBytes 65536 `
            -StderrLimitBytes 8192
        if (-not $versionResult.Ok) {
            if ($versionResult.Kind -ceq 'timeout') { Throw-Topic05CodeGraphReason -Reason 'timeout' }
            if ($versionResult.Kind -ceq 'overflow') { Throw-Topic05CodeGraphReason -Reason 'output_truncated' }
            Throw-Topic05CodeGraphReason -Reason 'version_mismatch'
        }
        if ($versionResult.Stdout.Trim() -cne '1.5.0') {
            Throw-Topic05CodeGraphReason -Reason 'version_mismatch'
        }

        $lazyInitialized = $false
        $initialFilesErrored = 0
        $initMs = 0
        if (-not $indexExists) {
            $initResult = Invoke-Topic05CodeGraphProcess `
                -FilePath ([string]$resolvedRuntime.Runtime.paths.node) `
                -ArgumentList @(
                    [string]$resolvedRuntime.Runtime.paths.safe_init,
                    '--bundle-root', $resolvedRuntime.BundleRoot,
                    '--project-root', $worktreeRoot
                ) -WorkingDirectory $worktreeRoot -TimeoutMs 300000 -StdoutLimitBytes 65536 `
                -StderrLimitBytes 8192
            $initMs = $initResult.DurationMs
            if (-not $initResult.Ok) {
                if ($initResult.Kind -ceq 'timeout') { Throw-Topic05CodeGraphReason -Reason 'timeout' }
                if ($initResult.Kind -ceq 'overflow') { Throw-Topic05CodeGraphReason -Reason 'output_truncated' }
                Throw-Topic05CodeGraphReason -Reason 'index_init_failed'
            }
            try { $init = $initResult.Stdout | ConvertFrom-Json }
            catch { Throw-Topic05CodeGraphReason -Reason 'index_init_failed' }
            Assert-Topic05CodeGraphPropertySet -Value $init -Reason 'index_init_failed' -Expected @(
                'schema_version', 'ok', 'files_indexed', 'files_errored', 'nodes_created',
                'edges_created', 'duration_ms'
            )
            if ([int]$init.schema_version -ne 1 -or -not $init.ok -or
                -not (Test-Path -LiteralPath (Join-Path $indexPath 'codegraph.db') -PathType Leaf)) {
                Throw-Topic05CodeGraphReason -Reason 'index_init_failed'
            }
            $initialFilesErrored = [long]$init.files_errored
            $lazyInitialized = $true
        }

        $syncResult = Invoke-Topic05CodeGraphProcess `
            -FilePath ([string]$resolvedRuntime.Runtime.paths.node) `
            -ArgumentList @(
                [string]$resolvedRuntime.Runtime.paths.cli_entry, 'sync', $worktreeRoot, '--quiet'
            ) -WorkingDirectory $worktreeRoot -TimeoutMs 120000 -StdoutLimitBytes 65536 `
            -StderrLimitBytes 8192
        if (-not $syncResult.Ok) {
            if ($syncResult.Kind -ceq 'timeout') { Throw-Topic05CodeGraphReason -Reason 'timeout' }
            if ($syncResult.Kind -ceq 'overflow') { Throw-Topic05CodeGraphReason -Reason 'output_truncated' }
            Throw-Topic05CodeGraphReason -Reason 'index_sync_failed'
        }
        $statusBefore = Get-Topic05CodeGraphStatus -ResolvedRuntime $resolvedRuntime `
            -WorktreeRoot $worktreeRoot

        $queryResult = Invoke-Topic05CodeGraphProcess `
            -FilePath ([string]$resolvedRuntime.Runtime.paths.node) `
            -ArgumentList @(
                [string]$resolvedRuntime.Runtime.paths.cli_entry, 'explore', '--path', $worktreeRoot,
                '--max-files', [string]$MaxFiles, '--', $question
            ) -WorkingDirectory $worktreeRoot -TimeoutMs 60000 -StdoutLimitBytes 65536 `
            -StderrLimitBytes 8192
        if (-not $queryResult.Ok) {
            if ($queryResult.Kind -ceq 'timeout') { Throw-Topic05CodeGraphReason -Reason 'timeout' }
            if ($queryResult.Kind -ceq 'overflow') { Throw-Topic05CodeGraphReason -Reason 'output_truncated' }
            Throw-Topic05CodeGraphReason -Reason 'query_failed'
        }
        $graphText = $queryResult.Stdout.TrimEnd("`r", "`n")
        $graphBytes = [Text.Encoding]::UTF8.GetByteCount($graphText)
        if ($graphBytes -gt 32768) { Throw-Topic05CodeGraphReason -Reason 'output_truncated' }
        if ([string]::IsNullOrWhiteSpace($graphText)) {
            Throw-Topic05CodeGraphReason -Reason 'graph_gap'
        }

        [void](Get-Topic05CodeGraphStatus -ResolvedRuntime $resolvedRuntime -WorktreeRoot $worktreeRoot)
        $bindingAfter = Get-Topic05CodeGraphBinding -Context $context -IndexExists $true
        if ($bindingAfter.Mode -cne $binding.Mode -or $bindingAfter.TaskId -cne $binding.TaskId -or
            $bindingAfter.CandidateId -cne $binding.CandidateId -or
            $bindingAfter.CandidateHash -cne $binding.CandidateHash) {
            Throw-Topic05CodeGraphReason -Reason 'candidate_drift'
        }
        $snapshotAfter = Get-Topic05CodeGraphNormalizedSnapshot -WorktreeRoot $worktreeRoot `
            -OwnedIgnoredOutputs @($bindingAfter.OwnedIgnoredOutputs)
        if ($snapshotAfter.Sha256 -cne $snapshotBefore.Sha256) {
            Throw-Topic05CodeGraphReason -Reason 'source_changed'
        }

        $gapSignals = @()
        if ($initialFilesErrored -gt 0) { $gapSignals = @('initial_files_errored') }
        $success = [ordered]@{
            schema_version = 1
            ok = $true
            status = 'completed'
            reason_code = 'ok'
            fallback = $null
            data = [ordered]@{
                text = $graphText
                binding = [ordered]@{
                    mode = $binding.Mode
                    worktree_root = $worktreeRoot
                    workspace_snapshot_sha256 = $snapshotBefore.Sha256
                    task_id = $binding.TaskId
                    candidate_id = $binding.CandidateId
                    candidate_hash = $binding.CandidateHash
                }
                codegraph = [ordered]@{
                    version = '1.5.0'
                    index_path = [IO.Path]::GetFullPath([string]$statusBefore.indexPath)
                    index_state = [string]$statusBefore.index.state
                    synced = $true
                    lazy_initialized = $lazyInitialized
                    initial_files_errored = $initialFilesErrored
                    gap_signals = $gapSignals
                }
                metrics = [ordered]@{
                    init_ms = $initMs
                    sync_ms = $syncResult.DurationMs
                    query_ms = $queryResult.DurationMs
                    output_bytes = $graphBytes
                }
            }
        }
        Write-Topic05CodeGraphEnvelope -Envelope $success
    } finally {
        Remove-Topic05CodeGraphOwnedLock -Lock $lock
    }
} catch {
    $reason = [string]$_.Exception.Data['Topic05Reason']
    if ([string]::IsNullOrWhiteSpace($reason)) { $reason = 'internal_error' }
    Write-Topic05CodeGraphEnvelope -Envelope (Get-Topic05CodeGraphFailureEnvelope -Reason $reason)
}
