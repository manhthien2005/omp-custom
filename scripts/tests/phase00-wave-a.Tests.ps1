#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1'
$manifestPath = Join-Path $repositoryRoot 'docs\evidence\phase-00\manifest.yml'
$compatibilityPath = Join-Path $repositoryRoot 'registry\omp-compatibility.yml'
$script:helperLoaded = $false

if (Test-Path -LiteralPath $helperPath -PathType Leaf) {
    . $helperPath
    $script:helperLoaded = $true
}

$expectedIds = @(
    'T-00.1','T-00.2','T-00.3','T-00.4','T-00.5','T-00.6','T-00.7',
    'E1','E2','E3-A','E3-B','E3-C','E3-D','E3-E','E3-F','E3-G','E3-H',
    'E3-I','E3-J','E3-K','E3-L','E3-M','E4','E5-A','E5-B','E5-C','E5-D','E5-E','E5-F'
)

$allowedStates = @(
    'NOT_STARTED','READY','RUNNING','PASS','FAIL',
    'BLOCKED_ENVIRONMENT','DEFERRED_PARALLEL_DISABLED'
)

function Assert-HelperLoaded {
    $script:helperLoaded | Should Be $true
}

function New-Phase00Fixture {
    $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("omp-phase00-wave-a-{0}" -f [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'docs\evidence\phase-00') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'docs\evidence\phase-00\E3-J') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'registry') -Force | Out-Null

    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $fixtureRoot 'docs\evidence\phase-00\manifest.yml')
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'registry\upstreams.yml') -Destination (Join-Path $fixtureRoot 'registry\upstreams.yml')
    Copy-Item -LiteralPath $compatibilityPath -Destination (Join-Path $fixtureRoot 'registry\omp-compatibility.yml')
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-J\J1.yml') -Destination (Join-Path $fixtureRoot 'docs\evidence\phase-00\E3-J\J1.yml')
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'docs\evidence\phase-00\E3-J\conclusion.yml') -Destination (Join-Path $fixtureRoot 'docs\evidence\phase-00\E3-J\conclusion.yml')

    foreach ($rel in @('registry\upstreams.yml', 'registry\omp-compatibility.yml')) {
        if (-not (Test-Path -LiteralPath (Join-Path $fixtureRoot $rel))) {
            throw "Fixture artifact missing: $rel"
        }
    }

    return $fixtureRoot
}

function Remove-Phase00Fixture([string]$FixtureRoot) {
    if (-not $FixtureRoot) { return }
    $resolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $resolvedFixture = [System.IO.Path]::GetFullPath($FixtureRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedFixture.StartsWith($resolvedTemp, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to delete non-temp fixture: $resolvedFixture"
    }
    if (Test-Path -LiteralPath $FixtureRoot) {
        Remove-Item -LiteralPath $FixtureRoot -Recurse -Force
    }
}

function Set-FixtureText([string]$FixtureRoot, [string]$RelativePath, [scriptblock]$Mutate) {
    $path = Join-Path $FixtureRoot $RelativePath
    $content = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $updated = & $Mutate $content
    Set-Content -LiteralPath $path -Value $updated -Encoding UTF8 -NoNewline
}

function Get-FailureCodes($Results) {
    @($Results | Where-Object { $_.Status -eq 'FAIL' } | ForEach-Object { $_.Code })
}

Describe 'Phase 00 Wave A required surface' {
    It 'provides the focused validator helper' {
        Test-Path -LiteralPath $helperPath -PathType Leaf | Should Be $true
    }

    It 'provides the canonical manifest' {
        Test-Path -LiteralPath $manifestPath -PathType Leaf | Should Be $true
    }

    It 'provides the OMP compatibility ledger' {
        Test-Path -LiteralPath $compatibilityPath -PathType Leaf | Should Be $true
    }

    It 'exports all ten contract validators' {
        Assert-HelperLoaded
        (Get-Command Test-Phase00ManifestContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-Phase00E1ArtifactContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-Phase00E3IArtifactContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-Phase00E3LArtifactContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-Phase00P00CX028CorrectionContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-Phase00E4ArtifactContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-Phase00E5ArtifactContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-Phase00T003PolicyRehomingContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-OmpRegistryContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
        (Get-Command Test-OmpCompatibilityContract -ErrorAction SilentlyContinue) -ne $null | Should Be $true
    }
}

Describe 'Phase 00 manifest behavior' {
    It 'accepts the canonical 29-ID manifest' {
        Assert-HelperLoaded
        $results = Test-Phase00ManifestContract -RepositoryRoot $repositoryRoot
        @(Get-FailureCodes $results).Count | Should Be 0
        $manifest = Read-Phase00Manifest -Path $manifestPath
        @($manifest.Entries).Count | Should Be 29
        @($manifest.Entries.Id | Sort-Object -Unique).Count | Should Be 29
        @($manifest.Entries.Id | Where-Object { $_ -notin $expectedIds }).Count | Should Be 0
        @($manifest.Entries.State | Where-Object { $_ -notin $allowedStates }).Count | Should Be 0
    }

    It 'rejects an unknown state' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' { param($c) $c -replace 'state: READY', 'state: BROKEN_STATE' }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-STATE') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects incorrect manifest root identity' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' { param($c) $c -replace 'phase: "00"', 'phase: "99"' }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-ROOT') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a manifest with no entries container' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' { param($c) $c -replace '(?m)^entries:\r?\n', '' }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-ROOT') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects duplicate entries containers' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' { param($c) $c -replace '(?m)^entries:\r?\n', "entries:`nentries:`n" }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-PARSE') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a foundation kind on an experiment row' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' {
                param($c)
                $c -replace '(?ms)(id: E3-A\s+)kind: experiment', '${1}kind: foundation'
            }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-KIND') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects an unknown or duplicate ID' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' { param($c) $c -replace 'id: E5-F', 'id: E5-E' }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-IDSET') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a missing dependency ID' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' { param($c) $c -replace 'depends_on: \[E3-A, E3-H\]', 'depends_on: [E3-A, E3-UNKNOWN]' }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-DEPENDENCY') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects READY when a dependency has not passed' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' {
                param($c)
                $c -replace '(?ms)(id: E3-A\s+kind: experiment\s+)state: PASS', '${1}state: NOT_STARTED'
            }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-DEPENDENCY-STATE') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'permits deferred-parallel state only for E3-M' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' {
                param($c)
                $c -replace '(?ms)(id: E3-L\s+kind: experiment\s+)state: PASS', '${1}state: DEFERRED_PARALLEL_DISABLED'
            }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-DEFER') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'requires E3-M deferral to state that parallel mode is disabled' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' {
                param($c)
                $c -replace 'decision: "parallel_mode: DISABLED; experiment not attempted"', 'decision: "experiment not attempted"'
            }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-PARALLEL') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a missing artifact for a PASS row' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' {
                param($c)
                $c -replace 'artifacts: \[registry/upstreams.yml\]', 'artifacts: [missing/pass-artifact.yml]'
            }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-ARTIFACT') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a missing artifact for a BLOCKED_ENVIRONMENT row' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'docs\evidence\phase-00\manifest.yml' {
                param($c)
                $c -replace 'artifacts: \[docs/evidence/phase-00/E3-J/J1.yml, docs/evidence/phase-00/E3-J/conclusion.yml\]', 'artifacts: [missing/blocked-artifact.yml]'
            }
            $codes = Get-FailureCodes (Test-Phase00ManifestContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-MANIFEST-ARTIFACT') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }
}

Describe 'OMP registry and compatibility behavior' {
    It 'accepts the canonical pin and claim ledger' {
        Assert-HelperLoaded
        @(Get-FailureCodes (Test-OmpRegistryContract -RepositoryRoot $repositoryRoot)).Count | Should Be 0
        @(Get-FailureCodes (Test-OmpCompatibilityContract -RepositoryRoot $repositoryRoot)).Count | Should Be 0
    }

    It 'rejects a mismatched OMP pin' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'registry\upstreams.yml' {
                param($c)
                $c -replace '3a8591a8af5b6d200088d12ca75a5517cb064fa8', '0000000000000000000000000000000000000000'
            }
            $codes = Get-FailureCodes (Test-OmpRegistryContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-REG-PIN') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a missing discovery claim' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'registry\omp-compatibility.yml' {
                param($c)
                $c -replace 'id: DISC-015', 'id: DISC-999'
            }
            $codes = Get-FailureCodes (Test-OmpCompatibilityContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-COMPAT-DISCOVERY') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects stale compatibility metadata' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'registry\omp-compatibility.yml' {
                param($c)
                $c -replace 'verification_date: "2026-08-08"', 'verification_date: "2026-08-07"'
            }
            $codes = Get-FailureCodes (Test-OmpCompatibilityContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-COMPAT-METADATA') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a compatibility ledger with no verified-claims container' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'registry\omp-compatibility.yml' { param($c) $c -replace '(?m)^verified_claims:\r?\n', '' }
            $codes = Get-FailureCodes (Test-OmpCompatibilityContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-COMPAT-METADATA') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects duplicate verified-claims containers' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'registry\omp-compatibility.yml' { param($c) $c -replace '(?m)^verified_claims:\r?\n', "verified_claims:`nverified_claims:`n" }
            $codes = Get-FailureCodes (Test-OmpCompatibilityContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-COMPAT-PARSE') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a claim that is not source-verified' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'registry\omp-compatibility.yml' {
                param($c)
                $c -replace 'evidence_type: SOURCE_VERIFIED', 'evidence_type: INFERRED'
            }
            $codes = Get-FailureCodes (Test-OmpCompatibilityContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-COMPAT-EVIDENCE-TYPE') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }

    It 'rejects a watched path with no backing claim' {
        Assert-HelperLoaded
        $fixture = New-Phase00Fixture
        try {
            Set-FixtureText $fixture 'registry\omp-compatibility.yml' {
                param($c)
                $c -replace 'packages/coding-agent/src/task/agents.ts', 'packages/coding-agent/src/task/not-agents.ts'
            }
            $codes = Get-FailureCodes (Test-OmpCompatibilityContract -RepositoryRoot $fixture)
            ($codes -contains 'P00-COMPAT-WATCHED-COVERAGE') | Should Be $true
        } finally { Remove-Phase00Fixture $fixture }
    }
}

Describe 'Repository validator integration' {
    It 'runs all ten Phase 00 contracts through the existing entrypoint' {
        $validator = Join-Path $repositoryRoot 'scripts\validate-template.ps1'
        $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validator -Verbose 4>&1 | Out-String
        $exitCode = $LASTEXITCODE
        $exitCode | Should Be 0
        ($output -match 'P00-MANIFEST-IDSET') | Should Be $true
        ($output -match 'P00-E1-READY') | Should Be $true
        ($output -match 'P00-E3I-TERMINAL') | Should Be $true
        ($output -match 'P00-E3L-TERMINAL') | Should Be $true
        ($output -match 'P00-CX-028') | Should Be $true
        ($output -match 'P00-E4-TERMINAL') | Should Be $true
        ($output -match 'P00-E5-TERMINAL') | Should Be $true
        ($output -match 'P00-T003-MANIFEST') | Should Be $true
        ($output -match 'P00-REG-PIN') | Should Be $true
        ($output -match 'P00-COMPAT-DISCOVERY') | Should Be $true
    }

    It 'keeps a copied legacy helper loadable when the optional E1 helper is absent' {
        $fixture = Join-Path ([IO.Path]::GetTempPath()) `
            ("omp-phase00-legacy-helper-{0}" -f [guid]::NewGuid().ToString('N'))
        try {
            $lib = Join-Path $fixture 'scripts\lib'
            New-Item -ItemType Directory -Path $lib -Force | Out-Null
            $copiedHelper = Join-Path $lib 'phase00-evidence.ps1'
            Copy-Item -LiteralPath $helperPath -Destination $copiedHelper
            $quotedHelper = $copiedHelper.Replace("'", "''")
            $probe = "& { . '$quotedHelper'; if (`$null -eq (Get-Command Test-Phase00ManifestContract -ErrorAction SilentlyContinue)) { exit 41 }; if (`$null -ne (Get-Command Test-Phase00E1ArtifactContract -ErrorAction SilentlyContinue)) { exit 42 }; exit 0 }"
            $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $probe
            $LASTEXITCODE | Should Be 0
        } finally {
            Remove-Phase00Fixture $fixture
        }
    }
}
