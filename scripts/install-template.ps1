# Install Template — copy template files to OMP project or user directory
# Run from project root: .\scripts\install-template.ps1
#
# SAFETY RULES:
#   - Always dry-run first (default)
#   - Never overwrites models.yml or credential files
#   - Creates a timestamped backup before applying
#   - Validates OMP config after applying
#   - Use .\scripts\uninstall-template.ps1 to revert

param(
    [Parameter(Mandatory=$false)]
    [string]$Target = "project",          # "project" | "user"

    [Parameter(Mandatory=$false)]
    [string]$ProjectDir = $PWD,           # Target project directory for project install

    [string[]]$Components = @(            # Subset to install; defaults to all
        "agents", "workflows", "skills", "state", "agents-md", "rules-md", "config", "agent-boundary"
    ),

    [switch]$DryRun = $true,             # DEFAULT: dry-run. Pass -DryRun:$false to apply.
    [switch]$Force,                       # Overwrite existing files without prompting
    [switch]$EnablePerSpawnEffort,        # Required before user installs receive task effort settings
    [string]$PwshPath,                    # Optional explicit pwsh path; state/CodeGraph require 7.4+
    [string]$OmpPath,                     # Optional explicit OMP path; managed boundary supports pinned versions only
    [string]$CodeGraphArtifactPath,       # Optional pinned offline CodeGraph bundle
    [switch]$AllowCodeGraphDownload       # Explicitly allow the pinned CodeGraph network path
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$template_omp = Join-Path $root "template\.omp"

# PowerShell -File callers commonly pass comma-separated array values as one token. Normalize the
# public component list once so dependency and activation logic see one canonical closed set.
$normalizedComponents = [Collections.Generic.List[string]]::new()
foreach ($rawComponent in @($Components)) {
    foreach ($part in @(([string]$rawComponent) -split ',')) {
        $componentName = $part.Trim().ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($componentName)) {
            throw 'Component names cannot be empty.'
        }
        if ($normalizedComponents.Contains($componentName)) {
            throw "Duplicate component: $componentName"
        }
        [void]$normalizedComponents.Add($componentName)
    }
}
$Components = [string[]]$normalizedComponents.ToArray()

$stateSelected = $Components -ccontains 'state'
$codeGraphSelected = $Components -ccontains 'codegraph'
$agentBoundarySelected = $Components -ccontains 'agent-boundary'
if ($CodeGraphArtifactPath -and $AllowCodeGraphDownload) {
    throw 'CodeGraph artifact path and download permission are mutually exclusive.'
}
if (-not $codeGraphSelected -and ($CodeGraphArtifactPath -or $AllowCodeGraphDownload)) {
    throw 'CodeGraph acquisition inputs require the explicit codegraph component.'
}

if (@($Components | Where-Object { $_ -ieq 'policies' }).Count -gt 0) {
    throw "Component 'policies' was retired by Phase 00 T-00.3. Policy contracts are inlined into commands/agents; human references live under docs/policies/."
}
if (@($Components | Where-Object { $_ -ieq 'schemas' }).Count -gt 0) {
    throw "Component 'schemas' was retired. Its historical files remain in the source tree but are non-authoritative and are not installed."
}

# Resolve destination
if ($Target -eq "user") {
    $dest_omp = Join-Path $env:USERPROFILE ".omp\agent"
} else {
    $dest_omp = Join-Path $ProjectDir ".omp"
}
$dest_omp = [IO.Path]::GetFullPath($dest_omp).TrimEnd('\', '/')

Write-Host ""
Write-Host "OMP Workflow Template Installer" -ForegroundColor Cyan
Write-Host "Target:     $Target → $dest_omp" -ForegroundColor Cyan
Write-Host "Components: $($Components -join ', ')" -ForegroundColor Cyan
Write-Host "Mode:       $(if ($DryRun) { 'DRY-RUN (no changes)' } else { 'APPLY' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Red" })
Write-Host ""

# Protected files — never overwrite
$protected = @(
    "models.yml", "agent.db", "agent.db-shm", "agent.db-wal", "sessions",
    "credentials.json", "credentials.yml", "auth.json"
)

# Closed stale-agent set. Never replace this with a wildcard.
$retiredAgents = @('tech-lead.md', 'explorer.md', 'implementer.md', 'verifier.md')

# Component → source path mapping
$component_map = @{
    "agents"    = "agents"
    "workflows" = "commands"   # Product name → OMP runtime directory
    "skills"    = "skills"
    "state"     = "state"
    "agents-md" = $null        # Special: AGENTS.md root file
    "rules-md"  = $null        # Special: RULES.md root file
    "config"    = $null        # Special: config.yml
}

if ($stateSelected -or $codeGraphSelected -or $agentBoundarySelected) {
    if ($PwshPath) {
        if (-not (Test-Path -LiteralPath $PwshPath -PathType Leaf)) {
            throw "The selected managed component requires pwsh 7.4.0 or newer; the explicit pwsh path does not exist."
        }
        $resolvedPwsh = [IO.Path]::GetFullPath($PwshPath)
    } else {
        $pwshCommand = Get-Command pwsh.exe -ErrorAction SilentlyContinue
        if ($null -eq $pwshCommand) { $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue }
        if ($null -eq $pwshCommand) {
            throw "The selected managed component requires pwsh 7.4.0 or newer, but pwsh was not found."
        }
        $resolvedPwsh = if ($pwshCommand.Source) { $pwshCommand.Source } else { $pwshCommand.Path }
    }

    $versionOutput = @(& $resolvedPwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>&1)
    $versionExit = $LASTEXITCODE
    $versionLines = @($versionOutput | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ })
    if ($versionExit -ne 0 -or $versionLines.Count -eq 0) {
        throw "The selected managed component requires pwsh 7.4.0 or newer; the selected pwsh could not report a version."
    }
    try { $detectedPwshVersion = [version]$versionLines[-1] } catch {
        throw "The selected managed component requires pwsh 7.4.0 or newer; the selected pwsh reported an invalid version."
    }
    if ($detectedPwshVersion -lt [version]'7.4.0') {
        throw "The selected managed component requires pwsh 7.4.0 or newer; detected $detectedPwshVersion."
    }

    $stateSource = Join-Path $template_omp 'state'
    $stateManifestPath = Join-Path $stateSource 'manifest.json'
    if (-not (Test-Path -LiteralPath $stateManifestPath -PathType Leaf)) {
        throw "The state component source manifest is missing."
    }
    try { $stateManifest = Get-Content -Raw -LiteralPath $stateManifestPath -Encoding UTF8 | ConvertFrom-Json } catch {
        throw "The state component source manifest is invalid."
    }
    if ([int]$stateManifest.schema_version -ne 1 -or [version]$stateManifest.minimum_pwsh_version -lt [version]'7.4.0') {
        throw "The state component source manifest has an unsupported contract."
    }
    $stateRootFull = [IO.Path]::GetFullPath($stateSource).TrimEnd('\', '/')
    $manifestPaths = @()
    foreach ($entry in @($stateManifest.files)) {
        $relative = ([string]$entry.path -replace '\\', '/').Trim('/')
        if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or @($relative -split '/') -contains '..') {
            throw "The state component source manifest contains an unsafe path."
        }
        if ($manifestPaths -contains $relative) {
            throw "The state component source manifest contains a duplicate path."
        }
        $manifestPaths += $relative
        $sourceFile = [IO.Path]::GetFullPath((Join-Path $stateSource ($relative -replace '/', [IO.Path]::DirectorySeparatorChar)))
        if (-not $sourceFile.StartsWith($stateRootFull + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
            throw "The state component source manifest references a missing or unsafe file."
        }
        $actualHash = (Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash
        if ($actualHash -cne [string]$entry.sha256) {
            throw "The state component source manifest hash check failed for $relative."
        }
    }
    $actualStatePaths = @(
        Get-ChildItem -LiteralPath $stateSource -File -Recurse |
            Where-Object { $_.FullName -cne $stateManifestPath } |
            ForEach-Object { $_.FullName.Substring($stateRootFull.Length + 1).Replace('\', '/') } |
            Sort-Object
    )
    $expectedStatePaths = @($manifestPaths | Sort-Object)
    if (($actualStatePaths -join '|') -cne ($expectedStatePaths -join '|')) {
        throw "The state component source manifest does not cover the exact source tree."
    }
}

$codeGraphManifest = $null
$codeGraphCacheRoot = $null
$codeGraphPlannedReceipt = $null
if ($codeGraphSelected) {
    $codeGraphLibrary = Join-Path $root 'scripts\lib\topic05-codegraph.ps1'
    if (-not (Test-Path -LiteralPath $codeGraphLibrary -PathType Leaf)) {
        throw 'The CodeGraph installer library is missing.'
    }
    . $codeGraphLibrary

    $codeGraphManifestPath = Join-Path $template_omp 'codegraph\component-manifest.json'
    $codeGraphManifest = Read-Topic05CodeGraphComponentManifest `
        -LiteralPath $codeGraphManifestPath -TemplateRoot (Join-Path $root 'template')

    if (-not $stateSelected) {
        $requiredState = @($codeGraphManifest.requires)[0]
        $installedStateManifestPath = Join-Path $dest_omp 'state\manifest.json'
        if (-not (Test-Path -LiteralPath $installedStateManifestPath -PathType Leaf) -or
            (Get-Topic05CodeGraphSha256 -LiteralPath $installedStateManifestPath) -cne
                [string]$requiredState.sha256) {
            throw 'CodeGraph requires state in the same operation or an already installed compatible state manifest.'
        }
        try {
            $installedState = Get-Content -Raw -LiteralPath $installedStateManifestPath -Encoding UTF8 |
                ConvertFrom-Json
        } catch {
            throw 'CodeGraph installed state dependency manifest is invalid.'
        }
        if ([int]$installedState.schema_version -ne [int]$requiredState.schema_version -or
            [string]$installedState.record_type -cne [string]$requiredState.record_type) {
            throw 'CodeGraph installed state dependency contract is incompatible.'
        }
        $installedStateRoot = [IO.Path]::GetFullPath((Split-Path $installedStateManifestPath -Parent)).TrimEnd('\', '/')
        foreach ($entry in @($installedState.files)) {
            $relative = ([string]$entry.path -replace '\\', '/').Trim('/')
            if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or @($relative -split '/') -contains '..') {
                throw 'CodeGraph installed state dependency contains an unsafe path.'
            }
            $stateFile = [IO.Path]::GetFullPath((Join-Path $installedStateRoot ($relative -replace '/', '\')))
            if (-not $stateFile.StartsWith(
                    $installedStateRoot + [IO.Path]::DirectorySeparatorChar,
                    [StringComparison]::OrdinalIgnoreCase
                ) -or -not (Test-Path -LiteralPath $stateFile -PathType Leaf) -or
                (Get-Topic05CodeGraphSha256 -LiteralPath $stateFile).ToUpperInvariant() -cne
                    ([string]$entry.sha256).ToUpperInvariant()) {
                throw "CodeGraph installed state dependency hash check failed: $relative"
            }
        }
    }

    $codeGraphCacheRoot = Get-Topic05CodeGraphManagedCacheRoot -UserProfilePath $env:USERPROFILE
    $codeGraphPlatform = Get-Topic05CodeGraphPlatform
    $codeGraphPlannedReceipt = Join-Path $codeGraphCacheRoot "v1.5.0\$codeGraphPlatform\receipt.json"
}

$agentBoundaryManifest = $null
$agentBoundaryOwnedRows = @()
$agentBoundaryOmp = $null
if ($agentBoundarySelected) {
    $boundaryLibrary = Join-Path $root 'scripts\lib\topic06-agent-boundary.ps1'
    if (-not (Test-Path -LiteralPath $boundaryLibrary -PathType Leaf)) {
        throw 'The agent-boundary installer library is missing.'
    }
    . $boundaryLibrary
    $templateRoot = Join-Path $root 'template'
    $boundaryManifestPath = Join-Path $template_omp 'contracts\component-manifest.json'
    $boundaryRead = Read-Topic06BoundaryManifest -LiteralPath $boundaryManifestPath -TemplateRoot $templateRoot
    $agentBoundaryManifest = $boundaryRead.Manifest
    $agentBoundaryOwnedRows = @($boundaryRead.OwnedRows)

    $skillLockScript = Join-Path $root 'scripts\update-skill-lock.ps1'
    if (-not (Test-Path -LiteralPath $skillLockScript -PathType Leaf)) {
        throw 'Agent-boundary skill lock checker is missing.'
    }
    $skillLockOutput = @(& $resolvedPwsh -NoProfile -File $skillLockScript -RepositoryRoot $root -Check 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Agent-boundary behavior lock preflight failed: $($skillLockOutput -join ' ')"
    }

    if ($Target -ceq 'user' -and $Components -ccontains 'config' -and -not $EnablePerSpawnEffort) {
        throw 'Agent-boundary user installation requires -EnablePerSpawnEffort so the selected Worker effort contract remains effective.'
    }

    $manifestRowsByPath = @{}
    foreach ($row in @($boundaryRead.Rows)) { $manifestRowsByPath[[string]$row.path] = $row }
    if (-not ($Components -ccontains 'agents')) {
        foreach ($relative in @(
            '.omp/agents/cheap-scout.md', '.omp/agents/worker.md', '.omp/agents/reviewer.md'
        )) {
            $targetPath = Resolve-Topic06BoundaryTargetPath -TargetOmp $dest_omp -Relative $relative
            if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf) -or
                (Get-Topic06BoundarySha256 $targetPath) -cne [string]$manifestRowsByPath[$relative].sha256) {
                throw 'Agent-boundary requires compatible agents in the same operation or already installed.'
            }
        }
    }
    if (-not ($Components -ccontains 'skills')) {
        foreach ($relative in @(
            '.omp/skills/task-triage/SKILL.md',
            '.omp/skills/systematic-debugging/SKILL.md',
            '.omp/skills/evidence-before-completion/SKILL.md'
        )) {
            $targetPath = Resolve-Topic06BoundaryTargetPath -TargetOmp $dest_omp -Relative $relative
            if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf) -or
                (Get-Topic06BoundarySha256 $targetPath) -cne [string]$manifestRowsByPath[$relative].sha256) {
                throw 'Agent-boundary requires compatible skills in the same operation or already installed.'
            }
        }
    }
    if (-not $stateSelected) {
        $relative = '.omp/state/manifest.json'
        $targetPath = Resolve-Topic06BoundaryTargetPath -TargetOmp $dest_omp -Relative $relative
        if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf) -or
            (Get-Topic06BoundarySha256 $targetPath) -cne [string]$manifestRowsByPath[$relative].sha256) {
            throw 'Agent-boundary requires compatible state in the same operation or already installed.'
        }
    }
    $configDependency = if ($Components -ccontains 'config') {
        Join-Path $template_omp 'config.yml'
    } else {
        Join-Path $dest_omp 'config.yml'
    }
    Assert-Topic06BoundaryConfig -LiteralPath $configDependency
    $agentBoundaryOmp = Resolve-Topic06BoundaryOmp -OmpPath $OmpPath `
        -SupportedVersions @($agentBoundaryManifest.supported_omp_versions)
}

$plan = @()

foreach ($comp in $Components) {
    if ($comp -cin @('codegraph', 'agent-boundary')) { continue }
    switch ($comp) {
        "agents-md" {
            $plan += @{ src = Join-Path $template_omp "AGENTS.md"; dst = Join-Path $dest_omp "AGENTS.md" }
        }
        "rules-md" {
            $plan += @{ src = Join-Path $template_omp "RULES.md"; dst = Join-Path $dest_omp "RULES.md" }
        }
        "config" {
            $plan += @{ src = Join-Path $template_omp "config.yml"; dst = Join-Path $dest_omp "config.yml" }
        }
        default {
            if (-not $component_map.ContainsKey($comp)) {
                throw "Unknown component: $comp"
            }
            $sourceComponent = $component_map[$comp]
            $src_dir = Join-Path $template_omp $sourceComponent
            if (Test-Path $src_dir) {
                Get-ChildItem $src_dir -Recurse -File | ForEach-Object {
                    $rel = $_.FullName.Substring($template_omp.Length + 1)
                    $plan += @{ src = $_.FullName; dst = Join-Path $dest_omp $rel }
                }
            }
        }
    }
}

if ($codeGraphSelected) {
    $templateRoot = Join-Path $root 'template'
    $codeGraphToolRow = $null
    foreach ($row in @($codeGraphManifest.files)) {
        if ([string]$row.path -ceq '.omp/tools/codegraph-retrieve.js') {
            $codeGraphToolRow = $row
            continue
        }
        $sourcePath = Join-Path $templateRoot (([string]$row.path) -replace '/', '\')
        $targetRelative = ([string]$row.path).Substring('.omp/'.Length) -replace '/', '\'
        $targetPath = Join-Path $dest_omp $targetRelative
        $plan += @{ src = $sourcePath; dst = $targetPath; codegraph = $true }
    }
    $plan += @{
        src = Join-Path $template_omp 'codegraph\component-manifest.json'
        dst = Join-Path $dest_omp 'codegraph\component-manifest.json'
        codegraph = $true
    }
    $plan += @{
        content = $null
        dst = Join-Path $dest_omp 'codegraph\runtime.json'
        codegraph = $true
        generated = $true
    }
    $plan += @{
        content = $null
        dst = Join-Path $dest_omp 'codegraph\install-record.json'
        codegraph = $true
        generated = $true
    }
    if ($null -eq $codeGraphToolRow) { throw 'CodeGraph component tool row is missing.' }
    $plan += @{
        src = Join-Path $templateRoot (([string]$codeGraphToolRow.path) -replace '/', '\')
        dst = Join-Path $dest_omp (([string]$codeGraphToolRow.path).Substring('.omp/'.Length) -replace '/', '\')
        codegraph = $true
        discoverable = $true
    }
}

if ($agentBoundarySelected) {
    $templateRoot = Join-Path $root 'template'
    foreach ($row in $agentBoundaryOwnedRows) {
        $plan += @{
            src = Resolve-Topic06BoundarySourcePath -TemplateRoot $templateRoot -Relative ([string]$row.path)
            dst = Resolve-Topic06BoundaryTargetPath -TargetOmp $dest_omp -Relative ([string]$row.path)
            agent_boundary = $true
            boundary_relative = [string]$row.path
        }
    }
    $plan += @{
        src = Join-Path $template_omp 'contracts\component-manifest.json'
        dst = Join-Path $dest_omp 'contracts\component-manifest.json'
        agent_boundary = $true
        boundary_relative = '.omp/contracts/component-manifest.json'
    }
    foreach ($relative in @($agentBoundaryManifest.generated_target_files)) {
        $plan += @{
            content = $null
            dst = Resolve-Topic06BoundaryTargetPath -TargetOmp $dest_omp -Relative ([string]$relative)
            agent_boundary = $true
            boundary_relative = [string]$relative
            generated = $true
        }
    }
}

$retirementPlan = @()
if (@($Components | Where-Object { $_ -ceq 'agents' }).Count -gt 0) {
    $agentsDestination = Join-Path $dest_omp 'agents'
    foreach ($retiredAgent in $retiredAgents) {
        $candidate = Join-Path $agentsDestination $retiredAgent
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $retirementPlan += $candidate
        }
    }
}

# Display plan
Write-Host "Planned changes ($($plan.Count) files):" -ForegroundColor White
foreach ($item in $plan) {
    $dst_rel = $item.dst.Replace($dest_omp, "").TrimStart("\")
    $exists = Test-Path $item.dst
    $protected_flag = $protected | Where-Object { $dst_rel -like "*$_*" }
    if ($protected_flag) {
        Write-Host "  SKIP     $dst_rel (protected)" -ForegroundColor DarkGray
    } elseif ($exists) {
        Write-Host "  OVERWRITE $dst_rel" -ForegroundColor Yellow
    } else {
        Write-Host "  CREATE   $dst_rel" -ForegroundColor Green
    }
}
foreach ($retiredPath in $retirementPlan) {
    $dst_rel = $retiredPath.Replace($dest_omp, "").TrimStart("\")
    Write-Host "  RETIRE  $dst_rel" -ForegroundColor Yellow
}

if ($codeGraphSelected) {
    Write-Host "  STATE DEPENDENCY: compatible Topic 04 state selected or installed" -ForegroundColor Cyan
    Write-Host "  BUNDLE RECEIPT: $codeGraphPlannedReceipt" -ForegroundColor Cyan
    Write-Host "  TARGET ROOT: $(Join-Path $dest_omp 'codegraph')" -ForegroundColor Cyan
    Write-Host "  TARGET ROOT: $(Join-Path $dest_omp 'tools\codegraph-retrieve.js')" -ForegroundColor Cyan
}
if ($agentBoundarySelected) {
    Write-Host "  MANAGED LAUNCHER: $(Join-Path $dest_omp 'bin\omp-managed.ps1')" -ForegroundColor Cyan
    Write-Host "  OMP VERSION: $($agentBoundaryOmp.Version)" -ForegroundColor Cyan
    Write-Host "  DEPENDENCIES: compatible agents, state, and config selected or installed" -ForegroundColor Cyan
}

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY-RUN complete. No changes made." -ForegroundColor Yellow
    Write-Host "To apply: .\scripts\install-template.ps1 -DryRun:`$false [options]"
    exit 0
}

# Resolve every CodeGraph cache/runtime byte before the first target mutation. A verified shared
# bundle is intentionally retained even if a later target activation rolls back.
$timestamp = Get-Date -Format "yyyyMMdd-HHmmssfff"
$backup_dir = [IO.Path]::GetFullPath("$dest_omp.backup-$timestamp")
$destinationExisted = Test-Path -LiteralPath $dest_omp -PathType Container
$agentBoundaryStagingRoot = $null
if ($codeGraphSelected) {
    $codeGraphLockPath = Join-Path $template_omp 'codegraph\upstream-lock.json'
    $codeGraphReceipt = Install-Topic05CodeGraphBundle `
        -LockPath $codeGraphLockPath `
        -CacheRoot $codeGraphCacheRoot `
        -ArtifactPath $CodeGraphArtifactPath `
        -AllowNetwork:$AllowCodeGraphDownload
    $codeGraphRuntime = New-Topic05CodeGraphRuntimeRecord `
        -Receipt $codeGraphReceipt -TargetOmp $dest_omp -PwshPath $resolvedPwsh
    $runtimeText = ConvertTo-Topic05CodeGraphJsonText -Value $codeGraphRuntime
    $runtimeSha256 = Get-Topic05CodeGraphTextSha256 -Value $runtimeText

    [string[]]$installedPaths = @(
        @($codeGraphManifest.files | ForEach-Object { [string]$_.path })
        '.omp/codegraph/component-manifest.json'
        '.omp/codegraph/runtime.json'
        '.omp/codegraph/install-record.json'
    )
    [Array]::Sort($installedPaths, [StringComparer]::Ordinal)
    [string[]]$knownIndexPaths = @()
    if ($Target -ceq 'project') {
        $projectFull = [IO.Path]::GetFullPath($ProjectDir).TrimEnd('\', '/')
        $knownIndexPaths = @([IO.Path]::GetFullPath((Join-Path $projectFull '.codegraph')))
    }
    $codeGraphInstallRecord = [ordered]@{
        schema_version = 1
        record_type = 'codegraph_install_record'
        component = 'codegraph'
        installed_at_utc = [DateTime]::UtcNow.ToString('o')
        target_omp = $dest_omp
        backup_dir = $backup_dir
        component_manifest_sha256 = Get-Topic05CodeGraphSha256 `
            -LiteralPath (Join-Path $template_omp 'codegraph\component-manifest.json')
        upstream_lock_sha256 = Get-Topic05CodeGraphSha256 -LiteralPath $codeGraphLockPath
        runtime_sha256 = $runtimeSha256
        bundle_root = [IO.Path]::GetFullPath([string]$codeGraphReceipt.bundle_root).TrimEnd('\', '/')
        receipt_path = [IO.Path]::GetFullPath([string]$codeGraphReceipt.receipt_path)
        installed_paths = $installedPaths
        known_index_paths = $knownIndexPaths
        retained_cache_policy = 'retain_and_report'
    }
    $installRecordText = ConvertTo-Topic05CodeGraphJsonText -Value $codeGraphInstallRecord
    foreach ($item in $plan) {
        if (-not $item.generated) { continue }
        if ([IO.Path]::GetFileName([string]$item.dst) -ceq 'runtime.json') {
            $item.content = $runtimeText
        } elseif ([IO.Path]::GetFileName([string]$item.dst) -ceq 'install-record.json') {
            $item.content = $installRecordText
        }
    }
}

if ($agentBoundarySelected) {
    $boundaryManifestSource = Join-Path $template_omp 'contracts\component-manifest.json'
    $boundaryManifestSha256 = Get-Topic06BoundarySha256 $boundaryManifestSource
    $boundaryRuntime = New-Topic06BoundaryRuntime `
        -Manifest $agentBoundaryManifest `
        -ManifestSha256 $boundaryManifestSha256 `
        -TargetOmp $dest_omp `
        -PwshPath $resolvedPwsh `
        -Omp $agentBoundaryOmp
    $boundaryRuntimeText = ConvertTo-Topic06BoundaryJsonText -Value $boundaryRuntime
    $boundaryRuntimeSha256 = [BitConverter]::ToString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($boundaryRuntimeText)
    )).Replace('-', '').ToLowerInvariant()

    [string[]]$boundaryInstalledPaths = @(
        @($agentBoundaryOwnedRows | ForEach-Object { [string]$_.path })
        '.omp/contracts/component-manifest.json'
        @($agentBoundaryManifest.generated_target_files | ForEach-Object { [string]$_ })
    )
    [Array]::Sort($boundaryInstalledPaths, [StringComparer]::Ordinal)
    $boundaryInstalledHashes = [Collections.Generic.List[object]]::new()
    foreach ($row in $agentBoundaryOwnedRows) {
        [void]$boundaryInstalledHashes.Add([ordered]@{ path = [string]$row.path; sha256 = [string]$row.sha256 })
    }
    [void]$boundaryInstalledHashes.Add([ordered]@{
        path = '.omp/contracts/component-manifest.json'; sha256 = $boundaryManifestSha256
    })
    [void]$boundaryInstalledHashes.Add([ordered]@{
        path = '.omp/contracts/runtime.json'; sha256 = $boundaryRuntimeSha256
    })
    $sortedBoundaryHashes = @($boundaryInstalledHashes | Sort-Object { [string]$_.path })
    $boundaryInstallRecord = New-Topic06BoundaryInstallRecord `
        -TargetOmp $dest_omp `
        -BackupDir $backup_dir `
        -ManifestSha256 $boundaryManifestSha256 `
        -RuntimeSha256 $boundaryRuntimeSha256 `
        -InstalledHashes $sortedBoundaryHashes `
        -InstalledPaths $boundaryInstalledPaths
    $boundaryInstallRecordText = ConvertTo-Topic06BoundaryJsonText -Value $boundaryInstallRecord

    $agentBoundaryStagingRoot = Join-Path ([IO.Path]::GetTempPath()) `
        ('omp-agent-boundary-stage-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $agentBoundaryStagingRoot)
    try {
        foreach ($item in @($plan | Where-Object {
            $_.ContainsKey('agent_boundary') -and [bool]$_['agent_boundary']
        })) {
            $stagePath = Join-Path $agentBoundaryStagingRoot `
                (([string]$item.boundary_relative).Replace('/', '\'))
            $stageParent = Split-Path $stagePath -Parent
            if (-not (Test-Path -LiteralPath $stageParent)) {
                [void](New-Item -ItemType Directory -Path $stageParent -Force)
            }
            if ([string]$item.boundary_relative -ceq '.omp/contracts/runtime.json') {
                [IO.File]::WriteAllText($stagePath, $boundaryRuntimeText, [Text.UTF8Encoding]::new($false))
            } elseif ([string]$item.boundary_relative -ceq '.omp/contracts/install-record.json') {
                [IO.File]::WriteAllText($stagePath, $boundaryInstallRecordText, [Text.UTF8Encoding]::new($false))
            } else {
                Copy-Item -LiteralPath $item.src -Destination $stagePath -Force
            }
            $item.src = $stagePath
            $item.generated = $false
            $item.content = $null
        }
        foreach ($row in $sortedBoundaryHashes) {
            $stagePath = Join-Path $agentBoundaryStagingRoot (([string]$row.path).Replace('/', '\'))
            if ((Get-Topic06BoundarySha256 $stagePath) -cne [string]$row.sha256) {
                throw "Agent-boundary staging hash check failed: $($row.path)"
            }
        }
        $stagedRecord = Get-Content -Raw -LiteralPath `
            (Join-Path $agentBoundaryStagingRoot '.omp\contracts\install-record.json') -Encoding UTF8 |
            ConvertFrom-Json
        if ([string]$stagedRecord.record_type -cne 'agent_boundary_install_record' -or
            (@($stagedRecord.installed_paths) -join '|') -cne ($boundaryInstalledPaths -join '|')) {
            throw 'Agent-boundary staged install record is invalid.'
        }
    } catch {
        if (Test-Path -LiteralPath $agentBoundaryStagingRoot) {
            Remove-Item -LiteralPath $agentBoundaryStagingRoot -Recurse -Force
        }
        throw
    }
}

# Backup
if ($destinationExisted) {
    Write-Host ""
    Write-Host "Creating backup: $backup_dir" -ForegroundColor Cyan
    Copy-Item -LiteralPath $dest_omp -Destination $backup_dir -Recurse
    Write-Host "Backup created." -ForegroundColor Green
} elseif ($agentBoundarySelected) {
    [void](New-Item -ItemType Directory -Path $backup_dir)
}

# Apply all target changes as one transaction. The discoverable tool is the final plan item.
$applied = 0
$retired = 0
try {
    foreach ($item in $plan) {
        $dst_rel = $item.dst.Replace($dest_omp, "").TrimStart("\")
        $protected_flag = $protected | Where-Object { $dst_rel -like "*$_*" }
        if ($protected_flag) { continue }

        $dst_dir = Split-Path $item.dst -Parent
        if (-not (Test-Path $dst_dir)) {
            New-Item -ItemType Directory -Path $dst_dir -Force | Out-Null
        }
        $isUserConfigWithoutEffort =
            $Target -ceq 'user' -and
            -not $EnablePerSpawnEffort -and
            [IO.Path]::GetFullPath($item.dst) -ceq [IO.Path]::GetFullPath((Join-Path $dest_omp 'config.yml'))
        if ($item.generated) {
            if ($null -eq $item.content) { throw "Generated installer content is unavailable: $dst_rel" }
            [IO.File]::WriteAllText(
                [IO.Path]::GetFullPath([string]$item.dst),
                [string]$item.content,
                [Text.UTF8Encoding]::new($false)
            )
        } elseif ($isUserConfigWithoutEffort) {
            $configContent = Get-Content -Raw -LiteralPath $item.src -Encoding UTF8
            $configContent = [regex]::Replace(
                $configContent,
                '(?ms)\r?\ntask:\r?\n\s{2}enableEffort:\s*true\r?\n\s{2}maxEffort:\s*xhigh\s*(?:\r?\n)?$',
                "`n"
            )
            Set-Content -LiteralPath $item.dst -Value $configContent -Encoding UTF8 -NoNewline
        } else {
            Copy-Item -LiteralPath $item.src -Destination $item.dst -Force
        }
        $applied++
    }

    if ($retirementPlan.Count -gt 0) {
        $resolvedAgentsDestination = [IO.Path]::GetFullPath((Join-Path $dest_omp 'agents')).TrimEnd('\', '/')
        foreach ($retiredPath in $retirementPlan) {
            $resolvedRetiredPath = [IO.Path]::GetFullPath($retiredPath)
            $resolvedParent = [IO.Path]::GetDirectoryName($resolvedRetiredPath).TrimEnd('\', '/')
            $leaf = [IO.Path]::GetFileName($resolvedRetiredPath)
            if ($resolvedParent -cne $resolvedAgentsDestination -or $leaf -cnotin $retiredAgents) {
                throw "Refusing unsafe stale-agent retirement target: $resolvedRetiredPath"
            }
            if (Test-Path -LiteralPath $resolvedRetiredPath -PathType Leaf) {
                Remove-Item -LiteralPath $resolvedRetiredPath -Force
                $retired++
            }
        }
    }
} catch {
    $activationError = $_
    try {
        if (Test-Path -LiteralPath $dest_omp) {
            Remove-Item -LiteralPath $dest_omp -Recurse -Force
        }
        if ($destinationExisted) {
            if (-not (Test-Path -LiteralPath $backup_dir -PathType Container)) {
                throw 'transaction backup is unavailable'
            }
            Copy-Item -LiteralPath $backup_dir -Destination $dest_omp -Recurse
        }
    } catch {
        throw "Installation failed and rollback also failed: $($activationError.Exception.Message); $($_.Exception.Message)"
    }
    if ($agentBoundaryStagingRoot -and (Test-Path -LiteralPath $agentBoundaryStagingRoot)) {
        Remove-Item -LiteralPath $agentBoundaryStagingRoot -Recurse -Force
    }
    throw "Installation failed; target restored exactly. Verified CodeGraph cache retained. $($activationError.Exception.Message)"
}

if ($agentBoundaryStagingRoot -and (Test-Path -LiteralPath $agentBoundaryStagingRoot)) {
    Remove-Item -LiteralPath $agentBoundaryStagingRoot -Recurse -Force
}

Write-Host ""
Write-Host "$applied files installed to $dest_omp" -ForegroundColor Green
Write-Host "$retired stale agent files retired" -ForegroundColor Green
Write-Host "Backup at: $backup_dir" -ForegroundColor Green
if ($codeGraphSelected) {
    Write-Host "CodeGraph bundle retained at: $($codeGraphReceipt.bundle_root)" -ForegroundColor Cyan
    foreach ($indexPath in @($codeGraphInstallRecord.known_index_paths)) {
        Write-Host "CodeGraph index retained at: $indexPath" -ForegroundColor Cyan
    }
}
Write-Host ""
Write-Host "To roll back: .\scripts\uninstall-template.ps1 -BackupDir `"$backup_dir`""
