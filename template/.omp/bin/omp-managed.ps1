#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Stop-ManagedLaunch {
    param([Parameter(Mandatory)][string]$Reason)
    [Console]::Error.WriteLine("OMP managed launcher refused startup: $Reason")
    exit 2
}

function Test-ClosedMap {
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Value,
        [Parameter(Mandatory)][string[]]$Names
    )
    $actual = @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    $expected = @($Names | Sort-Object)
    return ($actual -join '|') -ceq ($expected -join '|')
}

function Get-NormalizedPath {
    param([Parameter(Mandatory)][string]$LiteralPath)
    return [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
}

function Test-SamePath {
    param([Parameter(Mandatory)][string]$Left, [Parameter(Mandatory)][string]$Right)
    $comparison = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [Runtime.InteropServices.OSPlatform]::Windows
        )) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    return (Get-NormalizedPath $Left).Equals((Get-NormalizedPath $Right), $comparison)
}

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { throw 'managed file is missing' }
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-ClosedJson {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { throw 'managed JSON is missing' }
    $bytes = [IO.File]::ReadAllBytes($LiteralPath)
    if ($bytes.Length -eq 0 -or $bytes.Length -gt 1MB) { throw 'managed JSON size is invalid' }
    try {
        return [Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json -AsHashtable
    } catch {
        throw 'managed JSON is invalid'
    }
}

function Test-SafeManifestPath {
    param([Parameter(Mandatory)][string]$Value)
    $normalized = $Value.Replace('\', '/')
    return $normalized.StartsWith('.omp/', [StringComparison]::Ordinal) -and
        -not [IO.Path]::IsPathRooted($normalized) -and
        -not (@($normalized.Split('/')) -contains '..') -and
        -not $normalized.Contains('//', [StringComparison]::Ordinal)
}

function Resolve-ManifestTarget {
    param([Parameter(Mandatory)][string]$TargetOmp, [Parameter(Mandatory)][string]$Relative)
    if (-not (Test-SafeManifestPath $Relative)) { throw 'manifest path is unsafe' }
    $suffix = $Relative.Replace('\', '/').Substring('.omp/'.Length).Replace('/', [IO.Path]::DirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $TargetOmp $suffix))
    $root = (Get-NormalizedPath $TargetOmp) + [IO.Path]::DirectorySeparatorChar
    $comparison = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [Runtime.InteropServices.OSPlatform]::Windows
        )) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not $candidate.StartsWith($root, $comparison)) { throw 'manifest path escapes the target' }
    return $candidate
}

function Assert-ManagedConfig {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { throw 'managed config dependency is missing' }
    $text = Get-Content -Raw -LiteralPath $LiteralPath -Encoding UTF8
    $patterns = @(
        '(?m)^\s{2}cheap-scout:\s+omniroute/ds/deepseek-v4-flash:xhigh\s*$',
        '(?m)^\s{2}worker:\s+omniroute/codex/gpt-5\.6-sol:high\s*$',
        '(?m)^\s{2}reviewer:\s+omniroute/codex/gpt-5\.6-sol:xhigh\s*$',
        '(?m)^\s{2}modelFallback:\s+true\s*$',
        '(?m)^\s{2}usageAwareFallback:\s+false\s*$',
        '(?m)^\s{6}-\s+omniroute/ds/deepseek-v4-pro:xhigh\s*$',
        '(?m)^\s{2}enableEffort:\s+true\s*$',
        '(?m)^\s{2}maxEffort:\s+xhigh\s*$'
    )
    foreach ($pattern in $patterns) {
        if ([regex]::Matches($text, $pattern).Count -ne 1) { throw 'managed config role policy is incompatible' }
    }
}

try {
    $targetOmp = Get-NormalizedPath (Join-Path $PSScriptRoot '..')
    $runtimePath = Join-Path $targetOmp 'contracts\runtime.json'
    $runtime = Read-ClosedJson $runtimePath
    if (-not (Test-ClosedMap $runtime @(
        'schema_version', 'record_type', 'component', 'component_version', 'created_at_utc',
        'target_omp', 'component_manifest_sha256', 'installed_omp_version',
        'supported_omp_versions', 'paths', 'capabilities', 'policy'
    )) -or [int]$runtime.schema_version -ne 2 -or
        [string]$runtime.record_type -cne 'agent_boundary_runtime' -or
        [string]$runtime.component -cne 'agent-boundary' -or
        [string]$runtime.component_version -cne '2.1.0' -or
        -not (Test-SamePath ([string]$runtime.target_omp) $targetOmp)) {
        throw 'runtime identity is invalid'
    }
    if (-not (Test-ClosedMap $runtime.paths @(
        'pwsh', 'omp', 'state_cli', 'wrapper', 'overlay', 'launcher', 'manifest', 'core',
        'schema', 'cli', 'config', 'state_manifest', 'state_client', 'continuity_schema',
        'continuity_core', 'continuity_adapter', 'agents'
    )) -or -not (Test-ClosedMap $runtime.paths.agents @('cheap-scout', 'worker', 'reviewer')) -or
        -not (Test-ClosedMap $runtime.capabilities @('batch', 'isolation', 'effort', 'max_effort', 'continuity')) -or
        -not (Test-ClosedMap $runtime.policy @(
            'soft_request_budget', 'forced_partial_requests', 'role_policy_sha256', 'continuity_policy_sha256'
        ))) {
        throw 'runtime shape is invalid'
    }
    if ([bool]$runtime.capabilities.batch -ne $true -or [bool]$runtime.capabilities.isolation -ne $true -or
        [bool]$runtime.capabilities.effort -ne $true -or [bool]$runtime.capabilities.continuity -ne $true -or
        [string]$runtime.capabilities.max_effort -cne 'xhigh' -or
        [int]$runtime.policy.soft_request_budget -ne 200 -or
        [int]$runtime.policy.forced_partial_requests -ne 300 -or
        [string]$runtime.policy.role_policy_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
        [string]$runtime.policy.continuity_policy_sha256 -cnotmatch '^[0-9a-f]{64}$') {
        throw 'runtime policy is invalid'
    }
    $installRecordPath = Join-Path $targetOmp 'contracts\install-record.json'
    $installRecord = Read-ClosedJson $installRecordPath
    if (-not (Test-ClosedMap $installRecord @(
        'schema_version', 'record_type', 'component', 'component_version', 'installed_at_utc',
        'target_omp', 'backup_dir', 'component_manifest_sha256', 'runtime_sha256', 'installed_paths',
        'installed_hashes', 'generated_paths', 'operational_state_policy'
    )) -or [int]$installRecord.schema_version -ne 2 -or
        [string]$installRecord.record_type -cne 'agent_boundary_install_record' -or
        [string]$installRecord.component -cne 'agent-boundary' -or
        [string]$installRecord.component_version -cne '2.1.0' -or
        [string]$installRecord.operational_state_policy -cne 'retain_outside_target_omp' -or
        -not (Test-SamePath ([string]$installRecord.target_omp) $targetOmp) -or
        [string]$installRecord.component_manifest_sha256 -cne [string]$runtime.component_manifest_sha256 -or
        [string]$installRecord.runtime_sha256 -cne (Get-Sha256 $runtimePath)) {
        throw 'install record or runtime hash is invalid'
    }

    $expectedPaths = [ordered]@{
        state_cli = Join-Path $targetOmp 'state\agent-tasks.ps1'
        wrapper = Join-Path $targetOmp 'extensions\agent-task-boundary.js'
        overlay = Join-Path $targetOmp 'contracts\managed-runtime.yml'
        launcher = Join-Path $targetOmp 'bin\omp-managed.ps1'
        manifest = Join-Path $targetOmp 'contracts\component-manifest.json'
        core = Join-Path $targetOmp 'contracts\agent-boundary-core.mjs'
        schema = Join-Path $targetOmp 'contracts\agent-boundary-schema.mjs'
        cli = Join-Path $targetOmp 'contracts\agent-boundary-cli.mjs'
        config = Join-Path $targetOmp 'config.yml'
        state_manifest = Join-Path $targetOmp 'state\manifest.json'
        state_client = Join-Path $targetOmp 'contracts\managed-state-client.mjs'
        continuity_schema = Join-Path $targetOmp 'contracts\context-continuity-schema.mjs'
        continuity_core = Join-Path $targetOmp 'contracts\context-continuity-core.mjs'
        continuity_adapter = Join-Path $targetOmp 'extensions\context-continuity.js'
    }
    foreach ($entry in $expectedPaths.GetEnumerator()) {
        if (-not (Test-SamePath ([string]$runtime.paths[$entry.Key]) ([string]$entry.Value))) {
            throw "runtime path is invalid: $($entry.Key)"
        }
    }
    foreach ($name in @('cheap-scout', 'worker', 'reviewer')) {
        if (-not (Test-SamePath ([string]$runtime.paths.agents[$name]) (Join-Path $targetOmp "agents\$name.md"))) {
            throw "runtime agent path is invalid: $name"
        }
    }
    if (-not (Test-SamePath ([string]$runtime.paths.pwsh) ([Environment]::ProcessPath)) -and
        -not (Test-Path -LiteralPath ([string]$runtime.paths.pwsh) -PathType Leaf)) {
        throw 'runtime pwsh path is invalid'
    }
    if (-not (Test-Path -LiteralPath ([string]$runtime.paths.omp) -PathType Leaf)) {
        throw 'runtime OMP path is missing'
    }

    $manifestPath = [string]$runtime.paths.manifest
    if ((Get-Sha256 $manifestPath) -cne [string]$runtime.component_manifest_sha256) {
        throw 'component manifest hash mismatch'
    }
    $manifest = Read-ClosedJson $manifestPath
    if (-not (Test-ClosedMap $manifest @(
        'schema_version', 'record_type', 'component', 'component_version', 'minimum_pwsh_version',
        'supported_omp_versions', 'role_policy', 'continuity_policy', 'dependencies', 'files', 'generated_target_files'
    )) -or [int]$manifest.schema_version -ne 2 -or
        [string]$manifest.record_type -cne 'agent_boundary_component_manifest' -or
        [string]$manifest.component -cne 'agent-boundary' -or [string]$manifest.component_version -cne '2.1.0') {
        throw 'component manifest identity is invalid'
    }
    $supported = @($manifest.supported_omp_versions | ForEach-Object { [string]$_ })
    if (($supported -join '|') -cne (@($runtime.supported_omp_versions) -join '|') -or
        $supported.Count -ne 2 -or $supported[0] -cne '17.2.10' -or $supported[1] -cne '17.2.12') {
        throw 'supported OMP version policy is invalid'
    }
    if ([string]$runtime.installed_omp_version -cnotin $supported) { throw 'installed OMP version is unsupported' }
    if ([string]$runtime.policy.role_policy_sha256 -cne
        ([BitConverter]::ToString([Security.Cryptography.SHA256]::HashData(
            [Text.Encoding]::UTF8.GetBytes(($manifest.role_policy | ConvertTo-Json -Depth 32 -Compress))
        )).Replace('-', '').ToLowerInvariant())) {
        throw 'role policy hash mismatch'
    }
    if ([string]$runtime.policy.continuity_policy_sha256 -cne
        ([BitConverter]::ToString([Security.Cryptography.SHA256]::HashData(
            [Text.Encoding]::UTF8.GetBytes(($manifest.continuity_policy | ConvertTo-Json -Depth 32 -Compress))
        )).Replace('-', '').ToLowerInvariant())) {
        throw 'continuity policy hash mismatch'
    }

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($row in @($manifest.files)) {
        if ($row -isnot [Collections.IDictionary] -or -not (Test-ClosedMap $row @('path', 'sha256', 'owned')) -or
            [string]$row.sha256 -cnotmatch '^[0-9a-f]{64}$' -or $row.owned -isnot [bool] -or
            -not $seen.Add([string]$row.path)) {
            throw 'component manifest file row is invalid'
        }
        $installed = Resolve-ManifestTarget -TargetOmp $targetOmp -Relative ([string]$row.path)
        if ((Get-Sha256 $installed) -cne [string]$row.sha256) {
            throw "managed file hash mismatch: $($row.path)"
        }
    }
    if ($seen.Count -ne 20) { throw 'component manifest file set is incomplete' }
    Assert-ManagedConfig ([string]$runtime.paths.config)
    $expectedOverlay = @(
        'task:', '  softRequestBudget: 200', 'contextPromotion:', '  enabled: false', 'compaction:',
        '  enabled: false', '  strategy: off', '  midTurnEnabled: false', '  thresholdPercent: -1',
        '  thresholdTokens: -1', '  keepRecentTokens: 20000', '  autoContinue: false',
        '  idleEnabled: false', '  remoteEnabled: false', '  remoteStreamingV2Enabled: false',
        '  supersedeReads: true', '  dropUseless: true', ''
    ) -join "`n"
    if ((Get-Content -Raw -LiteralPath ([string]$runtime.paths.overlay) -Encoding UTF8) -cne $expectedOverlay) {
        throw 'managed overlay bytes are invalid'
    }

    $versionOutput = @(& ([string]$runtime.paths.omp) --version 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'OMP version probe failed' }
    $versionText = ($versionOutput | ForEach-Object { [string]$_ }) -join "`n"
    $match = [regex]::Match($versionText, '(?m)^omp/([^\s]+)\s*$')
    if (-not $match.Success -or $match.Groups[1].Value -cnotin $supported) {
        throw 'OMP version is unsupported'
    }

    [string[]]$callerArgs = @($args | ForEach-Object { [string]$_ })
    $separator = [Array]::IndexOf($callerArgs, '--')
    $before = if ($separator -gt 0) { @($callerArgs[0..($separator - 1)]) } elseif ($separator -eq 0) { @() } else { @($callerArgs) }
    $after = if ($separator -ge 0) { @($callerArgs[$separator..($callerArgs.Count - 1)]) } else { @() }
    foreach ($argument in $before) {
        if ($argument -cin @('--trusted-extension', '--extension', '-e', '--hook') -or
            $argument.StartsWith('--trusted-extension=', [StringComparison]::Ordinal) -or
            $argument.StartsWith('--extension=', [StringComparison]::Ordinal) -or
            $argument.StartsWith('-e=', [StringComparison]::Ordinal) -or
            $argument.StartsWith('--hook=', [StringComparison]::Ordinal)) {
            throw 'caller extension controls are not permitted'
        }
        if ($argument -ceq '--no-session' -or $argument.StartsWith('--no-session=', [StringComparison]::Ordinal)) {
            throw 'caller no-session control is not permitted'
        }
    }
    [string[]]$launchArgs = @(
        $before
        '--trusted-extension'
        [string]$runtime.paths.wrapper
        '--trusted-extension'
        [string]$runtime.paths.continuity_adapter
        '--config'
        [string]$runtime.paths.overlay
        $after
    )
    & ([string]$runtime.paths.omp) @launchArgs
    exit $LASTEXITCODE
} catch {
    Stop-ManagedLaunch -Reason $_.Exception.Message
}
