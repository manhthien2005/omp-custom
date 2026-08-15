[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),

    [Parameter()]
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepositoryPath {
    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    if ([System.IO.Path]::IsPathRooted($RelativePath) -or $RelativePath -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "Path escapes the repository: $RelativePath"
    }

    $candidate = [System.IO.Path]::GetFullPath((Join-Path $Root $RelativePath))
    $prefix = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the repository: $RelativePath"
    }
    return $candidate
}

function ConvertTo-NormalizedJson {
    param([Parameter(Mandatory)]$Value)
    return (($Value | ConvertTo-Json -Depth 100) -replace "`r`n", "`n") + "`n"
}

function Write-AtomicUtf8 {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )
    $temporary = Join-Path (Split-Path -Parent $Path) ('.' + [System.IO.Path]::GetFileName($Path) + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllText($temporary, $Content, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }
}

$root = [System.IO.Path]::GetFullPath($RepositoryRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Repository root does not exist: $root"
}

$manifestPath = Resolve-RepositoryPath -Root $root -RelativePath 'template/.omp/contracts/behavior-manifest.json'
$lockPath = Resolve-RepositoryPath -Root $root -RelativePath 'registry/skill-lock.yml'
$componentPath = Resolve-RepositoryPath -Root $root -RelativePath 'template/.omp/contracts/component-manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json -Depth 100
$component = Get-Content -Raw -LiteralPath $componentPath | ConvertFrom-Json -Depth 100

if ($manifest.schema_version -ne 1 -or $manifest.record_type -ne 'portable_behavior_manifest') {
    throw 'Behavior manifest identity is invalid.'
}
if ($component.schema_version -ne 2 -or $component.record_type -ne 'agent_boundary_component_manifest' -or
    $component.component_version -ne '2.1.0' -or @($component.files).Count -ne 20) {
    throw 'Agent-boundary component manifest identity is invalid.'
}

$names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$paths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$lockRows = [System.Collections.Generic.List[object]]::new()
foreach ($skill in @($manifest.skills)) {
    if (-not $names.Add([string]$skill.name) -or -not $paths.Add([string]$skill.path)) {
        throw "Duplicate skill identity: $($skill.name)"
    }
    if ($skill.status -ne 'active') {
        if ($skill.visibility -eq 'visible' -or @($skill.autoload_roles).Count -gt 0) {
            throw "Inactive skill still has an active consumer: $($skill.name)"
        }
        continue
    }
    if ($skill.path -ne ".omp/skills/$($skill.name)/SKILL.md") {
        throw "Skill path does not match its name: $($skill.name)"
    }
    $sourceRelative = 'template/' + ([string]$skill.path).Replace('\', '/')
    $sourcePath = Resolve-RepositoryPath -Root $root -RelativePath $sourceRelative
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Selected skill is missing: $sourceRelative"
    }
    $hash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $skill.sha256 = $hash
    $lockRows.Add([pscustomobject]@{
        name = [string]$skill.name
        path = $sourceRelative
        hash = $hash
    })
}

$expectedManifest = ConvertTo-NormalizedJson -Value $manifest
$yaml = [System.Collections.Generic.List[string]]::new()
$yaml.Add('# Generated from template/.omp/contracts/behavior-manifest.json; do not edit hashes by hand.')
$yaml.Add('version: "2.0"')
$yaml.Add('source_manifest: template/.omp/contracts/behavior-manifest.json')
$yaml.Add("component_version: `"$($manifest.component_version)`"")
$yaml.Add("reviewed_on: `"$($manifest.reviewed_on)`"")
$yaml.Add('skills:')
foreach ($row in $lockRows) {
    $yaml.Add("  - name: $($row.name)")
    $yaml.Add("    path: $($row.path)")
    $yaml.Add("    hash: $($row.hash)")
}
$expectedLock = ($yaml -join "`n") + "`n"

$componentRows = @{}
foreach ($row in @($component.files)) {
    $relative = [string]$row.path
    if ($componentRows.ContainsKey($relative)) { throw "Duplicate component row: $relative" }
    $componentRows[$relative] = $row
}
$managedComponentPaths = @(
    '.omp/bin/omp-managed.ps1',
    '.omp/contracts/behavior-core-schema.mjs',
    '.omp/contracts/behavior-core.mjs',
    '.omp/contracts/behavior-manifest.json',
    '.omp/extensions/agent-task-boundary.js',
    '.omp/agents/cheap-scout.md',
    '.omp/agents/worker.md',
    '.omp/agents/reviewer.md',
    '.omp/skills/task-triage/SKILL.md',
    '.omp/skills/systematic-debugging/SKILL.md',
    '.omp/skills/evidence-before-completion/SKILL.md'
)
foreach ($relative in $managedComponentPaths) {
    if (-not $componentRows.ContainsKey($relative)) { throw "Component mirror is missing: $relative" }
    $hash = if ($relative -ceq '.omp/contracts/behavior-manifest.json') {
        [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
            [Text.Encoding]::UTF8.GetBytes($expectedManifest)
        )).ToLowerInvariant()
    }
    else {
        $source = Resolve-RepositoryPath -Root $root -RelativePath ('template/' + $relative)
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Component source is missing: $relative" }
        (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $componentRows[$relative].sha256 = $hash
}

foreach ($row in @($component.files)) {
    $relative = [string]$row.path
    $source = Resolve-RepositoryPath -Root $root -RelativePath ('template/' + $relative)
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Component source is missing: $relative" }
    $actual = if ($relative -ceq '.omp/contracts/behavior-manifest.json') {
        [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
            [Text.Encoding]::UTF8.GetBytes($expectedManifest)
        )).ToLowerInvariant()
    }
    else { (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() }
    if ([string]$row.sha256 -cne $actual) { throw "Unreviewed component hash drift: $relative" }
}
$expectedComponent = ConvertTo-NormalizedJson -Value $component

if ($Check) {
    $currentManifest = (Get-Content -Raw -LiteralPath $manifestPath) -replace "`r`n", "`n"
    $currentLock = if (Test-Path -LiteralPath $lockPath) {
        (Get-Content -Raw -LiteralPath $lockPath) -replace "`r`n", "`n"
    }
    else { '' }
    $currentComponent = (Get-Content -Raw -LiteralPath $componentPath) -replace "`r`n", "`n"
    if ($currentManifest -cne $expectedManifest -or $currentLock -cne $expectedLock -or
        $currentComponent -cne $expectedComponent) {
        throw 'Behavior manifest, generated lock, or component mirror is stale.'
    }
    Write-Output "Behavior and component locks are current ($($lockRows.Count) active skills)."
    exit 0
}

Write-AtomicUtf8 -Path $manifestPath -Content $expectedManifest
Write-AtomicUtf8 -Path $lockPath -Content $expectedLock
Write-AtomicUtf8 -Path $componentPath -Content $expectedComponent
Write-Output "Updated behavior and component locks ($($lockRows.Count) active skills)."
