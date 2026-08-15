#Requires -Version 7.4

$ErrorActionPreference = 'Stop'

function Get-Topic06BoundarySha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw "Agent-boundary file is missing: $LiteralPath"
    }
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function ConvertTo-Topic06BoundaryJsonText {
    param([Parameter(Mandatory)][object]$Value)
    return ($Value | ConvertTo-Json -Depth 64 -Compress) + "`n"
}

function Test-Topic06BoundaryClosedObject {
    param([Parameter(Mandatory)][object]$Value, [Parameter(Mandatory)][string[]]$Names)
    if ($null -eq $Value -or $Value -is [string] -or $Value -isnot [object]) { return $false }
    $actual = @($Value.PSObject.Properties.Name | Sort-Object)
    $expected = @($Names | Sort-Object)
    return ($actual -join '|') -ceq ($expected -join '|')
}

function Test-Topic06BoundarySafePath {
    param([Parameter(Mandatory)][string]$Value)
    $normalized = $Value.Replace('\', '/')
    return $normalized.StartsWith('.omp/', [StringComparison]::Ordinal) -and
        -not [IO.Path]::IsPathRooted($normalized) -and
        -not (@($normalized.Split('/')) -contains '..') -and
        -not $normalized.Contains('//', [StringComparison]::Ordinal)
}

function Resolve-Topic06BoundarySourcePath {
    param([Parameter(Mandatory)][string]$TemplateRoot, [Parameter(Mandatory)][string]$Relative)
    if (-not (Test-Topic06BoundarySafePath $Relative)) { throw 'Agent-boundary manifest contains an unsafe path.' }
    $root = [IO.Path]::GetFullPath($TemplateRoot).TrimEnd('\', '/')
    $candidate = [IO.Path]::GetFullPath((Join-Path $root ($Relative.Replace('/', '\'))))
    $comparison = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [Runtime.InteropServices.OSPlatform]::Windows
        )) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not $candidate.StartsWith($root + [IO.Path]::DirectorySeparatorChar, $comparison)) {
        throw 'Agent-boundary manifest path escapes the template root.'
    }
    return $candidate
}

function Resolve-Topic06BoundaryTargetPath {
    param([Parameter(Mandatory)][string]$TargetOmp, [Parameter(Mandatory)][string]$Relative)
    if (-not (Test-Topic06BoundarySafePath $Relative)) { throw 'Agent-boundary manifest contains an unsafe path.' }
    $suffix = $Relative.Replace('\', '/').Substring('.omp/'.Length).Replace('/', '\')
    $root = [IO.Path]::GetFullPath($TargetOmp).TrimEnd('\', '/')
    $candidate = [IO.Path]::GetFullPath((Join-Path $root $suffix))
    $comparison = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [Runtime.InteropServices.OSPlatform]::Windows
        )) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not $candidate.StartsWith($root + [IO.Path]::DirectorySeparatorChar, $comparison)) {
        throw 'Agent-boundary target path escapes the target root.'
    }
    return $candidate
}

function Assert-Topic06BoundaryConfig {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw 'Agent-boundary requires config in the same operation or an already installed compatible config.'
    }
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
        if ([regex]::Matches($text, $pattern).Count -ne 1) {
            throw 'Agent-boundary config dependency has incompatible role, fallback, or effort policy.'
        }
    }
}

function Read-Topic06BoundaryManifest {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$TemplateRoot
    )
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw 'Agent-boundary component manifest is missing.'
    }
    try { $manifest = Get-Content -Raw -LiteralPath $LiteralPath -Encoding UTF8 | ConvertFrom-Json }
    catch { throw 'Agent-boundary component manifest is invalid.' }
    if (-not (Test-Topic06BoundaryClosedObject $manifest @(
        'schema_version', 'record_type', 'component', 'component_version', 'minimum_pwsh_version',
        'supported_omp_versions', 'role_policy', 'continuity_policy', 'dependencies', 'files', 'generated_target_files'
    )) -or [int]$manifest.schema_version -ne 2 -or
        [string]$manifest.record_type -cne 'agent_boundary_component_manifest' -or
        [string]$manifest.component -cne 'agent-boundary' -or
        [string]$manifest.component_version -cne '2.1.0' -or
        [version]$manifest.minimum_pwsh_version -ne [version]'7.4.0') {
        throw 'Agent-boundary component manifest has an unsupported contract.'
    }
    [string[]]$supported = @($manifest.supported_omp_versions | ForEach-Object { [string]$_ })
    if (($supported -join '|') -cne '17.2.10|17.2.12') {
        throw 'Agent-boundary supported OMP version set is invalid.'
    }
    if (-not (Test-Topic06BoundaryClosedObject $manifest.role_policy @(
        'soft_request_budget', 'forced_partial_requests', 'agents'
    )) -or [int]$manifest.role_policy.soft_request_budget -ne 200 -or
        [int]$manifest.role_policy.forced_partial_requests -ne 300 -or
        (@($manifest.role_policy.agents.PSObject.Properties.Name | Sort-Object) -join '|') -cne
            'cheap-scout|reviewer|worker') {
        throw 'Agent-boundary role policy is invalid.'
    }
    $roleChecks = [ordered]@{
        'cheap-scout' = [ordered]@{ role = 'cheap_scout'; model_role = 'cheap-scout'; effort = 'xhigh' }
        'worker' = [ordered]@{ role = 'worker'; model_role = 'worker'; default_effort = 'high' }
        'reviewer' = [ordered]@{ role = 'reviewer'; model_role = 'reviewer'; effort = 'xhigh' }
    }
    foreach ($name in $roleChecks.Keys) {
        $agent = $manifest.role_policy.agents.$name
        foreach ($entry in $roleChecks[$name].GetEnumerator()) {
            if ([string]$agent.($entry.Key) -cne [string]$entry.Value) { throw 'Agent-boundary role policy identity is invalid.' }
        }
        if ($agent.blocking -ne $true -or @($agent.spawns).Count -ne 0) {
            throw 'Agent-boundary agents must be blocking and non-spawning.'
        }
    }
    if (-not (Test-Topic06BoundaryClosedObject $manifest.continuity_policy @(
        'command', 'automatic_semantic_compaction', 'context_promotion', 'keep_recent_tokens',
        'nonce_ttl_ms', 'max_kernel_bytes', 'max_recovery_artifact_bytes',
        'pressure_default_reserve_tokens'
    )) -or [string]$manifest.continuity_policy.command -cne 'safe-compact' -or
        [bool]$manifest.continuity_policy.automatic_semantic_compaction -ne $false -or
        [bool]$manifest.continuity_policy.context_promotion -ne $false -or
        [int]$manifest.continuity_policy.keep_recent_tokens -ne 20000 -or
        [int]$manifest.continuity_policy.nonce_ttl_ms -ne 120000 -or
        [int]$manifest.continuity_policy.max_kernel_bytes -ne 16384 -or
        [int]$manifest.continuity_policy.max_recovery_artifact_bytes -ne 262144 -or
        [int]$manifest.continuity_policy.pressure_default_reserve_tokens -ne 16384) {
        throw 'Agent-boundary continuity policy is invalid.'
    }

    $dependencies = @($manifest.dependencies)
    if ($dependencies.Count -ne 4 -or
        (@($dependencies | ForEach-Object { [string]$_.component } | Sort-Object) -join '|') -cne
            'agents|config|skills|state') {
        throw 'Agent-boundary dependency set is invalid.'
    }
    $skillsDependency = @($dependencies | Where-Object { [string]$_.component -ceq 'skills' })
    if ($skillsDependency.Count -ne 1 -or
        (@($skillsDependency[0].paths | ForEach-Object { [string]$_ }) -join '|') -cne
            '.omp/skills/task-triage/SKILL.md|.omp/skills/systematic-debugging/SKILL.md|.omp/skills/evidence-before-completion/SKILL.md') {
        throw 'Agent-boundary selected skill dependency set is invalid.'
    }
    $generated = @($manifest.generated_target_files | ForEach-Object { [string]$_ })
    if (($generated -join '|') -cne '.omp/contracts/runtime.json|.omp/contracts/install-record.json') {
        throw 'Agent-boundary generated target set is invalid.'
    }

    $rows = @($manifest.files)
    if ($rows.Count -ne 20) { throw 'Agent-boundary manifest file set is incomplete.' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $owned = [Collections.Generic.List[object]]::new()
    foreach ($row in $rows) {
        if (-not (Test-Topic06BoundaryClosedObject $row @('path', 'sha256', 'owned')) -or
            -not (Test-Topic06BoundarySafePath ([string]$row.path)) -or
            [string]$row.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
            $row.owned -isnot [bool] -or -not $seen.Add([string]$row.path)) {
            throw 'Agent-boundary manifest contains an invalid or duplicate file row.'
        }
        $source = Resolve-Topic06BoundarySourcePath -TemplateRoot $TemplateRoot -Relative ([string]$row.path)
        if ((Get-Topic06BoundarySha256 $source) -cne [string]$row.sha256) {
            throw "Agent-boundary source hash check failed: $($row.path)"
        }
        if ([bool]$row.owned) { [void]$owned.Add($row) }
    }
    if ($owned.Count -ne 13) { throw 'Agent-boundary owned file set is invalid.' }

    $behaviorPath = Resolve-Topic06BoundarySourcePath -TemplateRoot $TemplateRoot `
        -Relative '.omp/contracts/behavior-manifest.json'
    try { $behavior = Get-Content -Raw -LiteralPath $behaviorPath -Encoding UTF8 | ConvertFrom-Json }
    catch { throw 'Portable behavior manifest is invalid.' }
    if ([int]$behavior.schema_version -ne 1 -or
        [string]$behavior.record_type -cne 'portable_behavior_manifest' -or
        [string]$behavior.adapters.omp.status -cne 'IMPLEMENTED_NOT_PROMOTED' -or
        [bool]$behavior.adapters.omp.installable -ne $true -or
        [string]$behavior.adapters.claude.status -cne 'DESIGNED_NOT_VERIFIED' -or
        [bool]$behavior.adapters.claude.installable -ne $false -or
        (@($behavior.skills | Where-Object { [string]$_.status -ceq 'active' } |
            ForEach-Object { [string]$_.name }) -join '|') -cne
            'task-triage|systematic-debugging|evidence-before-completion') {
        throw 'Portable behavior adapter or selected roster is not installable.'
    }
    return [pscustomobject]@{ Manifest = $manifest; Rows = $rows; OwnedRows = @($owned) }
}

function Resolve-Topic06BoundaryOmp {
    param([string]$OmpPath, [Parameter(Mandatory)][string[]]$SupportedVersions)
    if ($OmpPath) {
        if (-not (Test-Path -LiteralPath $OmpPath -PathType Leaf)) { throw 'Agent-boundary explicit OMP path does not exist.' }
        $resolved = [IO.Path]::GetFullPath($OmpPath)
    } else {
        $command = Get-Command omp.exe -ErrorAction SilentlyContinue
        if ($null -eq $command) { $command = Get-Command omp -ErrorAction SilentlyContinue }
        if ($null -eq $command) { throw 'Agent-boundary requires an installed supported OMP executable.' }
        $resolved = [IO.Path]::GetFullPath($(if ($command.Source) { $command.Source } else { $command.Path }))
    }
    $output = @(& $resolved --version 2>&1)
    $succeeded = $?
    if (-not $succeeded) { throw 'Agent-boundary could not query the installed OMP version.' }
    $text = ($output | ForEach-Object { [string]$_ }) -join "`n"
    $match = [regex]::Match($text, '(?m)^omp/([^\s]+)\s*$')
    if (-not $match.Success -or $match.Groups[1].Value -cnotin $SupportedVersions) {
        throw 'Agent-boundary requires OMP 17.2.10 or 17.2.12.'
    }
    return [pscustomobject]@{ Path = $resolved; Version = $match.Groups[1].Value }
}

function New-Topic06BoundaryRuntime {
    param(
        [Parameter(Mandatory)][object]$Manifest,
        [Parameter(Mandatory)][string]$ManifestSha256,
        [Parameter(Mandatory)][string]$TargetOmp,
        [Parameter(Mandatory)][string]$PwshPath,
        [Parameter(Mandatory)][object]$Omp
    )
    $target = [IO.Path]::GetFullPath($TargetOmp).TrimEnd('\', '/')
    $rolePolicyText = $Manifest.role_policy | ConvertTo-Json -Depth 32 -Compress
    $rolePolicyHash = [BitConverter]::ToString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($rolePolicyText)
    )).Replace('-', '').ToLowerInvariant()
    $continuityPolicyText = $Manifest.continuity_policy | ConvertTo-Json -Depth 32 -Compress
    $continuityPolicyHash = [BitConverter]::ToString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($continuityPolicyText)
    )).Replace('-', '').ToLowerInvariant()
    return [ordered]@{
        schema_version = 2
        record_type = 'agent_boundary_runtime'
        component = 'agent-boundary'
        component_version = '2.1.0'
        created_at_utc = [DateTime]::UtcNow.ToString('o')
        target_omp = $target
        component_manifest_sha256 = $ManifestSha256
        installed_omp_version = [string]$Omp.Version
        supported_omp_versions = @($Manifest.supported_omp_versions)
        paths = [ordered]@{
            pwsh = [IO.Path]::GetFullPath($PwshPath)
            omp = [IO.Path]::GetFullPath([string]$Omp.Path)
            state_cli = [IO.Path]::GetFullPath((Join-Path $target 'state\agent-tasks.ps1'))
            wrapper = [IO.Path]::GetFullPath((Join-Path $target 'extensions\agent-task-boundary.js'))
            overlay = [IO.Path]::GetFullPath((Join-Path $target 'contracts\managed-runtime.yml'))
            launcher = [IO.Path]::GetFullPath((Join-Path $target 'bin\omp-managed.ps1'))
            manifest = [IO.Path]::GetFullPath((Join-Path $target 'contracts\component-manifest.json'))
            core = [IO.Path]::GetFullPath((Join-Path $target 'contracts\agent-boundary-core.mjs'))
            schema = [IO.Path]::GetFullPath((Join-Path $target 'contracts\agent-boundary-schema.mjs'))
            cli = [IO.Path]::GetFullPath((Join-Path $target 'contracts\agent-boundary-cli.mjs'))
            config = [IO.Path]::GetFullPath((Join-Path $target 'config.yml'))
            state_manifest = [IO.Path]::GetFullPath((Join-Path $target 'state\manifest.json'))
            state_client = [IO.Path]::GetFullPath((Join-Path $target 'contracts\managed-state-client.mjs'))
            continuity_schema = [IO.Path]::GetFullPath((Join-Path $target 'contracts\context-continuity-schema.mjs'))
            continuity_core = [IO.Path]::GetFullPath((Join-Path $target 'contracts\context-continuity-core.mjs'))
            continuity_adapter = [IO.Path]::GetFullPath((Join-Path $target 'extensions\context-continuity.js'))
            agents = [ordered]@{
                'cheap-scout' = [IO.Path]::GetFullPath((Join-Path $target 'agents\cheap-scout.md'))
                worker = [IO.Path]::GetFullPath((Join-Path $target 'agents\worker.md'))
                reviewer = [IO.Path]::GetFullPath((Join-Path $target 'agents\reviewer.md'))
            }
        }
        capabilities = [ordered]@{
            batch = $true; isolation = $true; effort = $true; max_effort = 'xhigh'; continuity = $true
        }
        policy = [ordered]@{
            soft_request_budget = 200
            forced_partial_requests = 300
            role_policy_sha256 = $rolePolicyHash
            continuity_policy_sha256 = $continuityPolicyHash
        }
    }
}

function New-Topic06BoundaryInstallRecord {
    param(
        [Parameter(Mandatory)][string]$TargetOmp,
        [Parameter(Mandatory)][string]$BackupDir,
        [Parameter(Mandatory)][string]$ManifestSha256,
        [Parameter(Mandatory)][string]$RuntimeSha256,
        [Parameter(Mandatory)][object[]]$InstalledHashes,
        [Parameter(Mandatory)][string[]]$InstalledPaths
    )
    return [ordered]@{
        schema_version = 2
        record_type = 'agent_boundary_install_record'
        component = 'agent-boundary'
        component_version = '2.1.0'
        installed_at_utc = [DateTime]::UtcNow.ToString('o')
        target_omp = [IO.Path]::GetFullPath($TargetOmp).TrimEnd('\', '/')
        backup_dir = [IO.Path]::GetFullPath($BackupDir).TrimEnd('\', '/')
        component_manifest_sha256 = $ManifestSha256
        runtime_sha256 = $RuntimeSha256
        installed_paths = @($InstalledPaths)
        installed_hashes = @($InstalledHashes)
        generated_paths = @('.omp/contracts/runtime.json', '.omp/contracts/install-record.json')
        operational_state_policy = 'retain_outside_target_omp'
    }
}

function New-Topic06AgentBoundaryValidationResult {
    param(
        [ValidateSet('PASS', 'WARN', 'FAIL')][string]$Status,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Message
    )
    [pscustomobject]@{ Status = $Status; Code = $Code; Message = $Message }
}

function New-Topic06AgentBoundaryBooleanResult {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$PassMessage,
        [Parameter(Mandatory)][string]$FailMessage
    )
    if ($Condition) {
        return New-Topic06AgentBoundaryValidationResult -Status PASS -Code $Code -Message $PassMessage
    }
    return New-Topic06AgentBoundaryValidationResult -Status FAIL -Code $Code -Message $FailMessage
}

function Get-Topic06AgentBoundaryContent {
    param([Parameter(Mandatory)][string]$RepositoryRoot, [Parameter(Mandatory)][string]$RelativePath)
    $path = Join-Path $RepositoryRoot ($RelativePath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return '' }
    return Get-Content -Raw -LiteralPath $path -Encoding UTF8
}

function Get-Topic06AgentBoundaryJson {
    param([Parameter(Mandatory)][string]$RepositoryRoot, [Parameter(Mandatory)][string]$RelativePath)
    $text = Get-Topic06AgentBoundaryContent -RepositoryRoot $RepositoryRoot -RelativePath $RelativePath
    if (-not $text) { return $null }
    try { return $text | ConvertFrom-Json } catch { return $null }
}

function Test-Topic06AgentBoundaryContainsAll {
    param([AllowEmptyString()][string]$Content, [Parameter(Mandatory)][string[]]$Needles)
    foreach ($needle in $Needles) {
        if ($Content.IndexOf($needle, [StringComparison]::Ordinal) -lt 0) { return $false }
    }
    return $true
}

function Get-Topic06AgentBoundaryGovernedFiles {
    return @(
        'README.md', 'CHANGELOG.md', 'docs/agent-boundaries.md', 'docs/architecture.md',
        'docs/workflow-v0.md', 'docs/task-state.md', 'docs/security.md', 'docs/installation.md',
        'docs/customization.md', 'docs/rollback.md', 'docs/token-strategy.md', 'docs/final-report.md',
        'docs/superpowers/specs/2026-08-13-topic-06-agent-boundary-contracts-design.md',
        'docs/superpowers/plans/2026-08-13-topic-06-agent-boundary-contracts-plan.md',
        'spec/key/01-dna.md', 'spec/key/02-repo-synthesis.md',
        'spec/key/03-token-quality-model.md', 'spec/key/04-decision-log.md',
        'spec/key/05-coverage-audit.md', 'spec/03-agent-topology.md',
        'spec/05-context-and-token-model.md', 'spec/06-structured-output.md',
        'spec/08-isolation-and-concurrency.md', 'spec/09-model-routing.md',
        'spec/10-verification-and-review.md', 'spec/12-installation-and-rollback.md',
        'spec/13-validation-and-evaluation.md', 'spec/15-security-and-failure-recovery.md',
        'spec/README.md', 'spec/phases/phase-01-runtime-correctness.md',
        'spec/phases/phase-02-core-orchestration.md', 'spec/phases/phase-03-context-efficiency.md',
        'spec/phases/phase-04-quality-system.md', 'spec/phases/phase-05-installation-hardening.md',
        'spec/phases/phase-06-evaluation.md', 'spec/phases/phase-07-stabilization.md',
        'registry/omp-compatibility.yml', 'scripts/install-template.ps1',
        'scripts/uninstall-template.ps1', 'scripts/validate-template.ps1',
        'scripts/validate-topic06-agent-boundary.ps1', 'scripts/capture-topic06-evidence.ps1',
        'scripts/lib/topic06-agent-boundary.ps1',
        'scripts/tests/topic06-contract-core.Tests.mjs',
        'scripts/tests/topic06-agent-contracts.Tests.mjs',
        'scripts/tests/topic06-result-receipt.Tests.mjs',
        'scripts/tests/topic06-omp-wrapper.Tests.mjs',
        'scripts/tests/topic06-state-projection.Tests.ps1',
        'scripts/tests/topic06-installer.Tests.ps1',
        'scripts/tests/topic06-managed-runtime.Tests.ps1',
        'scripts/tests/topic06-agent-boundary.Tests.ps1',
        'scripts/tests/topic06-validator-mutations.Tests.ps1',
        'scripts/tests/fixtures/topic06-boundary-e2e.mjs',
        'template/.omp/contracts/agent-boundary-schema.mjs',
        'template/.omp/contracts/agent-boundary-core.mjs',
        'template/.omp/contracts/agent-boundary-cli.mjs',
        'template/.omp/contracts/managed-state-client.mjs',
        'template/.omp/contracts/managed-runtime.yml',
        'template/.omp/contracts/component-manifest.json',
        'template/.omp/extensions/agent-task-boundary.js',
        'template/.omp/bin/omp-managed.ps1',
        'template/.omp/agents/cheap-scout.md', 'template/.omp/agents/worker.md',
        'template/.omp/agents/reviewer.md', 'template/.omp/config.yml',
        'template/.omp/state/agent-tasks.ps1', 'template/.omp/state/manifest.json',
        'template/.omp/state/PROTOCOL.md', 'template/.omp/state/schemas/agent-tasks-v1.schema.json',
        'docs/evidence/current-product/topic-06/deterministic.json',
        'docs/evidence/current-product/topic-06/manifest.json',
        'codex-topic06-agent-boundary-contracts-changelog.md'
    )
}

function Test-Topic06AgentBoundaryContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [switch]$SkipEvidence
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot)
    $results = [Collections.Generic.List[object]]::new()
    $governed = @(Get-Topic06AgentBoundaryGovernedFiles)
    $required = if ($SkipEvidence) {
        @($governed | Where-Object { $_ -notlike 'docs/evidence/current-product/topic-06/*' })
    } else { $governed }
    $missing = @($required | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $root ($_ -replace '/', '\')) -PathType Leaf)
    })
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult ($missing.Count -eq 0) `
        'T06-REQUIRED-FILES' 'All Topic 06 governed files exist' `
        ("Missing Topic 06 governed files: {0}" -f ($missing -join ', '))))

    $decision = Get-Topic06AgentBoundaryContent $root 'spec/key/04-decision-log.md'
    $decisionValid = Test-Topic06AgentBoundaryContainsAll $decision @(
        '<!-- topic06-authority:kd-030 -->', '## KD-030', 'trusted, same-name `task` extension',
        'Topic 04 remains the sole durable', 'Flash `xhigh`', 'Pro `xhigh`',
        'ARTIFACT + CONTRACT', 'Managed v1 is blocking', 'task.softRequestBudget: 200',
        'OPEN-T06-RUNTIME-01'
    )
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $decisionValid 'T06-DECISION-KD030' `
        'KD-030 owns the managed boundary decision' 'KD-030 is missing or incomplete'))

    $component = Get-Topic06AgentBoundaryJson $root 'template/.omp/contracts/component-manifest.json'
    $manifestValid = $null -ne $component -and [int]$component.schema_version -eq 2 -and
        [string]$component.record_type -ceq 'agent_boundary_component_manifest' -and
        [string]$component.component -ceq 'agent-boundary' -and
        [string]$component.component_version -ceq '2.1.0' -and
        [version]$component.minimum_pwsh_version -eq [version]'7.4.0' -and
        (@($component.supported_omp_versions) -join '|') -ceq '17.2.10|17.2.12' -and
        [int]$component.role_policy.soft_request_budget -eq 200 -and
        [int]$component.role_policy.forced_partial_requests -eq 300 -and
        [string]$component.continuity_policy.command -ceq 'safe-compact' -and
        @($component.files).Count -eq 20
    if ($manifestValid) {
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($row in @($component.files)) {
            $relative = [string]$row.path
            $source = Join-Path (Join-Path $root 'template') ($relative -replace '/', '\')
            if (-not $seen.Add($relative) -or -not (Test-Path -LiteralPath $source -PathType Leaf) -or
                [string]$row.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
                (Get-Topic06BoundarySha256 $source) -cne [string]$row.sha256) {
                $manifestValid = $false
                break
            }
        }
    }
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $manifestValid 'T06-COMPONENT-MANIFEST' `
        'Agent-boundary component manifest and owned hashes reconcile' `
        'Agent-boundary component manifest or owned hashes are invalid'))

    $schema = Get-Topic06AgentBoundaryContent $root 'template/.omp/contracts/agent-boundary-schema.mjs'
    $core = Get-Topic06AgentBoundaryContent $root 'template/.omp/contracts/agent-boundary-core.mjs'
    $cli = Get-Topic06AgentBoundaryContent $root 'template/.omp/contracts/agent-boundary-cli.mjs'
    $coreValid = (Test-Topic06AgentBoundaryContainsAll $schema @(
        'export const LIMITS', 'export const REASON_CODES', 'export const RUNTIME_IDENTITIES',
        'omniroute/ds/deepseek-v4-flash', 'omniroute/ds/deepseek-v4-pro',
        'export const SEMANTIC_OUTPUT_SCHEMAS'
    )) -and (Test-Topic06AgentBoundaryContainsAll $core @(
        'export function canonicalJson', 'export function validateManagedRequest',
        'export function composeAgentPacket', 'export function composeHandoffPacket',
        'export function validateSemanticResult', 'record_type: "agent_boundary_receipt"',
        'export function toProvisionalOutcome', 'forced_partial', 'model_identity_mismatch',
        'prior_agent_narrative'
    )) -and (Test-Topic06AgentBoundaryContainsAll $cli @(
        'case "compose"', 'case "compose-handoff"', 'case "validate-semantic"',
        'case "normalize-receipt"', 'parseJsonNoDuplicateKeys'
    ))
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $coreValid 'T06-BOUNDARY-CORE' `
        'Portable closed schema/core/CLI boundary is present' `
        'Portable schema/core/CLI boundary is incomplete or fail-open'))

    $stateCli = Get-Topic06AgentBoundaryContent $root 'template/.omp/state/agent-tasks.ps1'
    $stateProtocol = Get-Topic06AgentBoundaryContent $root 'template/.omp/state/PROTOCOL.md'
    $stateSchema = Get-Topic06AgentBoundaryContent $root 'template/.omp/state/schemas/agent-tasks-v1.schema.json'
    $projectionValid = (Test-Topic06AgentBoundaryContainsAll $stateCli @(
        "'project-work-unit'", 'Get-AgentTasksWorkUnitProjection', "'record-work-unit-outcome'",
        'Add-AgentTasksWorkUnitOutcome'
    )) -and (Test-Topic06AgentBoundaryContainsAll $stateProtocol @(
        '`project-work-unit`', 'closed,', '`work_unit_projection`', 'must not reconstruct'
    )) -and (Test-Topic06AgentBoundaryContainsAll $stateSchema @(
        '"work_unit_projection"', '"projection_sha256"', '"work_unit_id"'
    ))
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $projectionValid 'T06-STATE-PROJECTION' `
        'Topic 04 exposes the closed work-unit projection and outcome CAS' `
        'Topic 04 projection/outcome integration is incomplete'))

    $agentChecks = [ordered]@{
        'cheap-scout' = @('name: cheap-scout', 'model: "@cheap-scout"', 'thinking-level: xhigh', 'blocking: true', 'spawns: ""', 'output:', 'additionalProperties: false')
        worker = @('name: worker', 'model: "@worker"', 'thinking-level: high', 'blocking: true', 'spawns: ""', 'output:', 'verification_observations')
        reviewer = @('name: reviewer', 'model: "@reviewer"', 'thinking-level: xhigh', 'blocking: true', 'spawns: ""', 'output:', 'CHANGES_REQUESTED')
    }
    $agentsValid = $true
    foreach ($name in $agentChecks.Keys) {
        $content = Get-Topic06AgentBoundaryContent $root "template/.omp/agents/$name.md"
        if (-not (Test-Topic06AgentBoundaryContainsAll $content $agentChecks[$name])) { $agentsValid = $false }
    }
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $agentsValid 'T06-AGENT-CONTRACTS' `
        'Selected role frontmatter and closed outputs reconcile' `
        'A selected role frontmatter/output contract drifted'))

    $wrapper = Get-Topic06AgentBoundaryContent $root 'template/.omp/extensions/agent-task-boundary.js'
    $wrapperValid = Test-Topic06AgentBoundaryContainsAll $wrapper @(
        'pi.registerTool(createManagedTaskTool', 'ctx.invokeTool(buildNativeTaskParams(prepared)',
        'project-work-unit', 'record-work-unit-outcome', 'deriveActiveMode',
        'plan_mode_incompatible', 'outcome_record_failed',
        '[...policy.tools, "yield"]'
    )
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $wrapperValid 'T06-WRAPPER' `
        'Trusted wrapper registers task, delegates natively, and validates settlement' `
        'Trusted wrapper registration/delegation/result validation is incomplete'))

    $launcher = Get-Topic06AgentBoundaryContent $root 'template/.omp/bin/omp-managed.ps1'
    $launcherValid = (Test-Topic06AgentBoundaryContainsAll $launcher @(
        "'--trusted-extension'", "'--config'", 'managed overlay bytes are invalid',
        'caller extension controls are not permitted', 'caller no-session control is not permitted',
        'supported OMP version policy is invalid',
        "& ([string]`$runtime.paths.omp) @launchArgs"
    )) -and $launcher.IndexOf('[string]$runtime.paths.wrapper', [StringComparison]::Ordinal) -lt
        $launcher.IndexOf('[string]$runtime.paths.continuity_adapter', [StringComparison]::Ordinal) -and
        $launcher.IndexOf('[string]$runtime.paths.continuity_adapter', [StringComparison]::Ordinal) -lt
        $launcher.LastIndexOf("'--config'", [StringComparison]::Ordinal)
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $launcherValid 'T06-LAUNCHER' `
        'Managed launcher validates bytes and fixes trusted wrapper/overlay order' `
        'Managed launcher trust or overlay order is invalid'))

    $config = Get-Topic06AgentBoundaryContent $root 'template/.omp/config.yml'
    $routingValid = Test-Topic06AgentBoundaryContainsAll ($schema + "`n" + $config) @(
        'cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh',
        'worker: omniroute/codex/gpt-5.6-sol:high',
        'reviewer: omniroute/codex/gpt-5.6-sol:xhigh',
        'omniroute/ds/deepseek-v4-pro:xhigh', 'usageAwareFallback: false',
        'enableEffort: true', 'maxEffort: xhigh', 'efforts: ["high", "xhigh"]'
    )
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $routingValid 'T06-ROUTING' `
        'Scout/Worker/Reviewer exact routes and effort policy reconcile' `
        'Managed route or effort policy drifted'))

    $overlay = Get-Topic06AgentBoundaryContent $root 'template/.omp/contracts/managed-runtime.yml'
    $expectedOverlay = @(
        'task:', '  softRequestBudget: 200', 'contextPromotion:', '  enabled: false', 'compaction:',
        '  enabled: false', '  strategy: off', '  midTurnEnabled: false', '  thresholdPercent: -1',
        '  thresholdTokens: -1', '  keepRecentTokens: 20000', '  autoContinue: false',
        '  idleEnabled: false', '  remoteEnabled: false', '  remoteStreamingV2Enabled: false',
        '  supersedeReads: true', '  dropUseless: true', ''
    ) -join "`n"
    $softBudgetValid = $overlay -ceq $expectedOverlay -and
        $core.Contains('The native task reached the managed forced-partial threshold.') -and
        $wrapper.Contains('runtime.policy.forced_partial_requests !== 300')
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $softBudgetValid 'T06-SOFT-BUDGET' `
        'Managed 200/300 request boundary rejects forced partial completion' `
        'Managed soft-budget overlay or forced-partial handling drifted'))

    $guide = Get-Topic06AgentBoundaryContent $root 'docs/agent-boundaries.md'
    $modesValid = Test-Topic06AgentBoundaryContainsAll ($guide + "`n" + $wrapper) @(
        '**Plan mode:**', '**Batch:**', '**Async:** rejected in managed v1.',
        '**Nested agents:** rejected in managed v1.', 'plan_mode_incompatible',
        'spawns.length !== 0'
    )
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $modesValid 'T06-EXECUTION-MODES' `
        'Managed plan/batch/async/nested rules are explicit and enforced' `
        'Managed execution-mode rules are incomplete'))

    $reviewerValid = Test-Topic06AgentBoundaryContainsAll ($guide + "`n" + $core + "`n" + $schema) @(
        'ARTIFACT + CONTRACT', 'Worker CLAIM + Worker narrative', 'prior_agent_narrative',
        'do not inherit another agent''s narrative', 'Opus may be preferred', 'is not required'
    )
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $reviewerValid 'T06-REVIEWER-INDEPENDENCE' `
        'Reviewer construction excludes Worker claim and keeps Opus optional' `
        'Reviewer independence or fallback policy drifted'))

    $installer = Get-Topic06AgentBoundaryContent $root 'scripts/install-template.ps1'
    $fullValidator = Get-Topic06AgentBoundaryContent $root 'scripts/validate-template.ps1'
    $schemaRetired = $installer.Contains("`$_ -ieq 'schemas'") -and
        $installer.Contains("Component 'schemas' was retired. Its historical files remain in the source tree but are non-authoritative and are not installed") -and
        -not $fullValidator.Contains('template\.omp\schemas\task-packet.schema.yml') -and
        -not $fullValidator.Contains('template\.omp\schemas\agent-result.schema.yml') -and
        -not $fullValidator.Contains('template\.omp\schemas\verification-result.schema.yml') -and
        -not $fullValidator.Contains('template\.omp\schemas\review-result.schema.yml')
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $schemaRetired 'T06-SCHEMA-RETIREMENT' `
        'Historical .omp/schemas are rejected and absent from current validator requirements' `
        'Retired .omp/schemas regained installed/runtime authority'))

    $uninstaller = Get-Topic06AgentBoundaryContent $root 'scripts/uninstall-template.ps1'
    $installRollbackValid = (Test-Topic06AgentBoundaryContainsAll $installer @(
        'agent-boundary', 'Read-Topic06BoundaryManifest', 'New-Topic06BoundaryRuntime',
        'New-Topic06BoundaryInstallRecord', 'Agent-boundary staging hash check failed'
    )) -and (Test-Topic06AgentBoundaryContainsAll $uninstaller @(
        "record.record_type -cne 'agent_boundary_install_record'", 'Get-AgentBoundaryRollbackStatus',
        '.omp/bin/omp-managed.ps1', 'Operational agent-tasks state retained.'
    ))
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $installRollbackValid 'T06-INSTALL-ROLLBACK' `
        'Agent-boundary install and rollback are manifest-driven and state-retaining' `
        'Agent-boundary install/rollback transaction is incomplete'))

    $projectionFiles = [ordered]@{
        'spec/phases/phase-01-runtime-correctness.md' = '<!-- topic06-projection:phase-01 -->'
        'spec/phases/phase-02-core-orchestration.md' = '<!-- topic06-projection:phase-02 -->'
        'spec/phases/phase-03-context-efficiency.md' = '<!-- topic06-projection:phase-03 -->'
        'spec/phases/phase-04-quality-system.md' = '<!-- topic06-projection:phase-04 -->'
        'spec/phases/phase-05-installation-hardening.md' = '<!-- topic06-projection:phase-05 -->'
        'spec/phases/phase-06-evaluation.md' = '<!-- topic06-projection:phase-06 -->'
        'spec/phases/phase-07-stabilization.md' = '<!-- topic06-projection:phase-07 -->'
    }
    $projectionsValid = $true
    foreach ($entry in $projectionFiles.GetEnumerator()) {
        if (-not (Get-Topic06AgentBoundaryContent $root $entry.Key).Contains($entry.Value)) {
            $projectionsValid = $false
        }
    }
    foreach ($relative in @(
        'spec/key/01-dna.md', 'spec/03-agent-topology.md', 'spec/05-context-and-token-model.md',
        'spec/06-structured-output.md', 'spec/08-isolation-and-concurrency.md',
        'spec/09-model-routing.md', 'spec/10-verification-and-review.md',
        'spec/12-installation-and-rollback.md', 'spec/13-validation-and-evaluation.md',
        'spec/15-security-and-failure-recovery.md', 'spec/README.md', 'README.md',
        'docs/architecture.md', 'docs/task-state.md', 'docs/security.md', 'docs/installation.md'
    )) {
        if (-not (Get-Topic06AgentBoundaryContent $root $relative).Contains('Topic 06')) {
            $projectionsValid = $false
        }
    }
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $projectionsValid 'T06-AUTHORITY-PROJECTIONS' `
        'Topic 06 decision is projected across active authority and phases' `
        'A required Topic 06 authority/phase projection is missing'))

    $openScopeValid = (Test-Topic06AgentBoundaryContainsAll $guide @(
        'OPEN-T06-RUNTIME-01', 'It is not a requirement', 'does not require Opus'
    )) -and $decision.Contains('**Open, nonblocking.** `OPEN-T06-RUNTIME-01`')
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $openScopeValid 'T06-OPEN-SCOPE' `
        'Universal OMP interception remains an explicit nonblocking upstream item' `
        'OPEN-T06-RUNTIME-01 scope became missing, blocking, or ambiguous'))

    $activeText = @(
        $guide, $decision,
        (Get-Topic06AgentBoundaryContent $root 'README.md'),
        (Get-Topic06AgentBoundaryContent $root 'docs/architecture.md'),
        (Get-Topic06AgentBoundaryContent $root 'spec/03-agent-topology.md'),
        (Get-Topic06AgentBoundaryContent $root 'spec/10-verification-and-review.md')
    ) -join "`n"
    $failOpenPhrases = @(
        'Bare OMP output may be accepted as a managed receipt',
        'inline fallback creates a managed receipt',
        'Worker claim is reviewer evidence',
        'Opus is required for review',
        'receipt accepts the parent task'
    )
    $noFailOpen = $true
    foreach ($phrase in $failOpenPhrases) {
        if ($activeText.IndexOf($phrase, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $noFailOpen = $false }
    }
    [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $noFailOpen 'T06-NO-FAIL-OPEN' `
        'No active semantic fail-open boundary wording was found' `
        'Active authority contains a semantic fail-open boundary rule'))

    if (-not $SkipEvidence) {
        $evidence = Get-Topic06AgentBoundaryJson $root 'docs/evidence/current-product/topic-06/deterministic.json'
        $evidenceValid = $null -ne $evidence -and [int]$evidence.schema_version -eq 1 -and
            [string]$evidence.record_type -ceq 'topic06_agent_boundary_evidence' -and
            [string]$evidence.status -ceq 'PASS' -and [int]$evidence.provider_calls -eq 0 -and
            [int]$evidence.model_processes_started -eq 0 -and
            [string]$evidence.pinned_omp.commit -ceq '3a8591a8af5b6d200088d12ca75a5517cb064fa8' -and
            [string]$evidence.limitations.universal_internal_agent_hook -ceq 'OPEN-T06-RUNTIME-01_NONBLOCKING' -and
            @($evidence.cases.PSObject.Properties).Count -ge 8 -and
            @($evidence.cases.PSObject.Properties.Value | Where-Object status -ne PASS).Count -eq 0
        [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $evidenceValid 'T06-EVIDENCE' `
            'Current-product evidence is PASS, model-free, and honestly scoped' `
            'Current-product evidence is missing, failed, provider-backed, or overclaimed'))

        $evidenceManifest = Get-Topic06AgentBoundaryJson $root 'docs/evidence/current-product/topic-06/manifest.json'
        $evidenceHashesValid = $null -ne $evidenceManifest -and
            [int]$evidenceManifest.schema_version -eq 1 -and
            [string]$evidenceManifest.record_type -ceq 'topic06_current_product_manifest' -and
            [string]$evidenceManifest.repository.dirty_paths_algorithm -ceq
                'sha256(sorted_git_porcelain_v1_lines_utf8_lf)' -and
            [string]$evidenceManifest.pinned_omp.commit -ceq '3a8591a8af5b6d200088d12ca75a5517cb064fa8' -and
            @($evidenceManifest.files).Count -ge 20
        if ($evidenceHashesValid) {
            $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            foreach ($row in @($evidenceManifest.files)) {
                $path = [string]$row.path
                $literal = Join-Path $root ($path -replace '/', '\')
                if (-not $paths.Add($path) -or [string]$row.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
                    -not (Test-Path -LiteralPath $literal -PathType Leaf) -or
                    (Get-Topic06BoundarySha256 $literal) -cne [string]$row.sha256) {
                    $evidenceHashesValid = $false
                    break
                }
            }
            if (-not $paths.Contains('docs/evidence/current-product/topic-06/deterministic.json')) {
                $evidenceHashesValid = $false
            }
        }
        [void]$results.Add((New-Topic06AgentBoundaryBooleanResult $evidenceHashesValid 'T06-EVIDENCE-HASHES' `
            'Evidence manifest hashes current implementation/tests/authority bytes' `
            'Evidence manifest identity or file hashes do not reconcile'))
    }

    return @($results)
}
