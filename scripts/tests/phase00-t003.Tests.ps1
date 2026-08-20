#Requires -Version 5.1

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\phase00-evidence.ps1'
$script:t003HelperLoaded = $false
$script:t003MutationCodes = [ordered]@{
    RecreatedPolicyFile = 'P00-T003-SURFACE'
    DanglingPolicyRef = 'P00-T003-CONSUMERS'
    ChangedGateMatrix = 'P00-T003-CONSUMERS'
    MissingEscalation = 'P00-T003-CONSUMERS'
    AdvertisedInstaller = 'P00-T003-INSTALLER'
    ForgedSourceHash = 'P00-T003-EVIDENCE'
    ForgedDestHash = 'P00-T003-EVIDENCE'
    PassWithoutEvidence = 'P00-T003-MANIFEST'
}
if (Test-Path -LiteralPath $helperPath -PathType Leaf) {
    . $helperPath
    $script:t003HelperLoaded = $true
}

function Get-T003FailureCodes($Results) {
    @($Results | Where-Object { $_.Status -eq 'FAIL' } |
        ForEach-Object { $_.Code })
}

function Assert-T003HelperLoaded {
    $script:t003HelperLoaded | Should Be $true
    (Get-Command Test-Phase00T003PolicyRehomingContract -ErrorAction SilentlyContinue) `
        -ne $null | Should Be $true
}

function Assert-T003ParserLoaded {
    $script:t003HelperLoaded | Should Be $true
    (Get-Command Read-Phase00T003Conclusion -ErrorAction SilentlyContinue) `
        -ne $null | Should Be $true
}

function Get-T003ValidConclusionText {
    @'
schema_version: 1
phase: "00"
task: T-00.3
status: PASS
provider_calls: 0
parallel_mode: DISABLED
legacy_sources:
  - id: context-budget
    path: template/.omp/policies/context-budget.yml
    lines: 89
    sha256: A3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE
    git_blob: f5591a7b7cd3e06efbd5431536ebd2391bdedd6d
  - id: escalation
    path: template/.omp/policies/escalation.yml
    lines: 52
    sha256: 49CB215BEEC2424C9274BBA285E2AD28B651A124AF1BF07102A925FDAEA5FD1F
    git_blob: c8e51d31baed0b2ce7ee000bd0be5deb3858e691
  - id: model-routing
    path: template/.omp/policies/model-routing.yml
    lines: 61
    sha256: 67E7F80534AB66C57B13EF91AD88CABAE5518F8828E89C496B78AB9C4209F4A2
    git_blob: c73070c1e73737a6947b48eb84338b583e4aa663
  - id: quality-gates
    path: template/.omp/policies/quality-gates.yml
    lines: 105
    sha256: 69A8635F66C118D5BC12612E7D7B6F498E1886B7213F15613BE5A37B6370A1E2
    git_blob: 47f6d06191a9e7b68f07da1903d96b931024fa30
  - id: workflow-sizing
    path: template/.omp/policies/workflow-sizing.yml
    lines: 56
    sha256: 603112590C993F9DEC61D17C32387C040C775C384B1D8656756170971703671B
    git_blob: 195c1f836bfd62381099cd9633073db4a37c88bc
dispositions:
  - source_section: context.components
    status: REHOMED
    destinations: [docs/policies/context-budget.md]
    authority: spec/05-context-and-token-budget.md
destinations:
  - path: docs/policies/context-budget.md
    sha256: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
checks:
  staged_paths: 0
non_claims:
  - no-provider-call
'@
}

function Write-T003ConclusionFixture([string]$Text) {
    $path = Join-Path $TestDrive 'conclusion.yml'
    [IO.File]::WriteAllText($path, $Text, [Text.UTF8Encoding]::new($false))
    return $path
}

function Assert-T003Throws([scriptblock]$Action) {
    $threw = $false
    try {
        & $Action | Out-Null
    } catch {
        $threw = $true
    }
    $threw | Should Be $true
}

function Invoke-T003InstallerProbe {
    param([string[]]$Components)

    $installer = Join-Path $repositoryRoot 'scripts\install-template.ps1'
    $shellName = if ($PSVersionTable.PSEdition -eq 'Desktop') {
        'powershell.exe'
    } else {
        'pwsh.exe'
    }
    $shellPath = Join-Path $PSHOME $shellName
    $arguments = @('-NoProfile')
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        $arguments += @('-ExecutionPolicy','Bypass')
    }
    $arguments += @('-File',$installer,'-ProjectDir',$TestDrive)
    if ($null -ne $Components) {
        $arguments += '-Components'
        $arguments += @($Components)
    }
    $output = & $shellPath @arguments 2>&1 | Out-String
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
}

$script:t003FixturePaths = @(
    'docs/policies/README.md',
    'docs/policies/context-budget.md',
    'docs/policies/model-routing.md',
    'docs/policies/quality-gates.md',
    'template/.omp/AGENTS.md',
    'template/.omp/commands/quick.md',
    'template/.omp/commands/standard.md',
    'template/.omp/commands/orchestrated.md',
    'docs/roles/tech-lead.md',
    'template/.omp/agents/cheap-scout.md',
    'template/.omp/agents/worker.md',
    'template/.omp/agents/reviewer.md',
    'template/.omp/config.yml',
    'template/.omp/schemas/verification-result.schema.yml',
    'scripts/install-template.ps1',
    'scripts/validate-template.ps1',
    'scripts/lib/topic03-topology-routing.ps1',
    'scripts/validate-topic03-topology-routing.ps1',
    'registry/upstreams.yml',
    'registry/adoption-ledger.yml',
    'README.md',
    'CHANGELOG.md',
    'docs/architecture.md',
    'docs/customization.md',
    'docs/final-report.md',
    'docs/installation.md',
    'docs/report-design.md',
    'docs/security.md',
    'docs/token-strategy.md',
    'docs/workflow-v0.md',
    'docs/evidence/phase-00/T-00.3/conclusion.yml',
    'docs/evidence/phase-00/manifest.yml',
    'docs/evidence/current-product/topic-03/deepseek-smoke.yml',
    'docs/evidence/current-product/topic-03/e2e.yml',
    'docs/evidence/current-product/topic-03/manifest.yml'
)

function New-T003RepositoryFixture {
    $fixtureRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $fixtureRoot -Force)
    foreach ($relative in $script:t003FixturePaths) {
        $source = Join-Path $repositoryRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Canonical fixture source is missing: $relative"
        }
        $destination = Join-Path $fixtureRoot ($relative -replace '/', '\')
        [void](New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force)
        Copy-Item -LiteralPath $source -Destination $destination
    }
    return $fixtureRoot
}

function Assert-T003CategoryStatus {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][ValidateSet('PASS','FAIL')][string]$Status
    )

    $result = @(Test-Phase00T003PolicyRehomingContract -RepositoryRoot $FixtureRoot |
        Where-Object { $_.Code -eq $Code })
    $result.Count | Should Be 1
    $result[0].Status | Should Be $Status
}

function Set-T003FixtureReplacement {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$OldValue,
        [Parameter(Mandatory)][string]$NewValue
    )

    $path = Join-Path $FixtureRoot ($RelativePath -replace '/', '\')
    $text = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $changed = $text.Replace($OldValue, $NewValue)
    if ($changed -ceq $text) {
        throw "Mutation anchor not found in $RelativePath"
    }
    [IO.File]::WriteAllText($path, $changed, [Text.UTF8Encoding]::new($false))
}

function Set-T003LaterFixtureFile {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $path = Join-Path $Root ($RelativePath -replace '/', '\')
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}

function Get-T003FixtureSha256 {
    param([Parameter(Mandatory)][string]$Path)
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function New-T003LaterSupersessionFixture {
    $root = Join-Path $TestDrive ("later-{0}" -f [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root -Force)

    Set-T003LaterFixtureFile $root 'docs/evidence/phase-00/T-00.3/conclusion.yml' @'
schema_version: 1
phase: "00"
task: T-00.3
status: PASS
'@
    Set-T003LaterFixtureFile $root 'docs/roles/tech-lead.md' '# Main-session Tech Lead'
    Set-T003LaterFixtureFile $root 'template/.omp/agents/cheap-scout.md' 'name: cheap-scout'
    Set-T003LaterFixtureFile $root 'template/.omp/agents/worker.md' 'name: worker'
    Set-T003LaterFixtureFile $root 'template/.omp/agents/reviewer.md' 'name: reviewer'
    Set-T003LaterFixtureFile $root 'template/.omp/AGENTS.md' 'main-session Tech Lead'
    Set-T003LaterFixtureFile $root 'template/.omp/commands/quick.md' 'quick current adapter'
    Set-T003LaterFixtureFile $root 'template/.omp/commands/standard.md' 'standard current adapter'
    Set-T003LaterFixtureFile $root 'template/.omp/commands/orchestrated.md' 'orchestrated current adapter'
    Set-T003LaterFixtureFile $root 'template/.omp/config.yml' 'modelRoles: current'
    Set-T003LaterFixtureFile $root 'scripts/install-template.ps1' 'current installer'
    Set-T003LaterFixtureFile $root 'scripts/validate-template.ps1' 'current validator'

    $currentPaths = @(
        'docs/roles/tech-lead.md',
        'template/.omp/agents/cheap-scout.md',
        'template/.omp/agents/worker.md',
        'template/.omp/agents/reviewer.md',
        'template/.omp/AGENTS.md',
        'template/.omp/commands/quick.md',
        'template/.omp/commands/standard.md',
        'template/.omp/commands/orchestrated.md',
        'template/.omp/config.yml',
        'scripts/install-template.ps1',
        'scripts/validate-template.ps1'
    )
    $currentRows = @($currentPaths | ForEach-Object {
        $path = Join-Path $root ($_ -replace '/', '\')
        [ordered]@{ path = $_; sha256 = Get-T003FixtureSha256 $path }
    })
    $conclusionPath = Join-Path $root 'docs\evidence\phase-00\T-00.3\conclusion.yml'
    $manifest = [ordered]@{
        schema_version = 1
        topic = '03'
        candidate = 'C1'
        phase00_source = 'T-00.3'
        phase00_conclusion_sha256 = Get-T003FixtureSha256 $conclusionPath
        superseded_agents = @(
            [ordered]@{ historical_path = 'template/.omp/agents/tech-lead.md'; disposition = 'rehomed'; current_path = 'docs/roles/tech-lead.md' },
            [ordered]@{ historical_path = 'template/.omp/agents/explorer.md'; disposition = 'replaced'; current_path = 'template/.omp/agents/cheap-scout.md' },
            [ordered]@{ historical_path = 'template/.omp/agents/implementer.md'; disposition = 'renamed'; current_path = 'template/.omp/agents/worker.md' },
            [ordered]@{ historical_path = 'template/.omp/agents/verifier.md'; disposition = 'retired'; current_path = $null }
        )
        selected_agents = @('cheap-scout', 'worker', 'reviewer')
        current_files = $currentRows
        deepseek_environment = 'ENVIRONMENT_BLOCKED'
    }
    Set-T003LaterFixtureFile $root 'docs/evidence/current-product/topic-03/manifest.yml' `
        ($manifest | ConvertTo-Json -Depth 10)
    return $root
}

function Assert-T003LaterStatus {
    param(
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][ValidateSet('PASS', 'FAIL')][string]$Status
    )

    $results = @(Test-Phase00T003LaterProductSupersessionContract -RepositoryRoot $FixtureRoot)
    $result = @($results | Where-Object Code -eq $Code)
    $result.Count | Should Be 1
    if ($result.Count -eq 1 -and $result[0].Status -ne $Status) {
        throw "[$Code] expected $Status but got $($result[0].Status): $($result[0].Message)"
    }
    $result[0].Status | Should Be $Status
}

Describe 'T-00.3 desired installed surface' {
    It 'removes the inert runtime directory' {
        (Test-Path -LiteralPath (Join-Path $repositoryRoot `
            'template\.omp\policies')) | Should Be $false
    }

    It 'creates exactly four non-runtime policy reference files' {
        $referenceRoot = Join-Path $repositoryRoot 'docs\policies'
        $names = @()
        if (Test-Path -LiteralPath $referenceRoot -PathType Container) {
            $names = @(Get-ChildItem -LiteralPath $referenceRoot -File |
                Sort-Object Name | ForEach-Object { $_.Name })
        }
        ($names -join ',') |
            Should Be 'context-budget.md,model-routing.md,quality-gates.md,README.md'
    }

    It 'contains no dangling installed policy reference' {
        $files = @(Get-ChildItem -Recurse -File `
            (Join-Path $repositoryRoot 'template\.omp\agents'), `
            (Join-Path $repositoryRoot 'template\.omp\commands'))
        $bad = @($files |
            Select-String -Pattern '(?i)policy:|(?:^|[\/])policies[\/]')
        $bad.Count | Should Be 0
    }

    It 'exports the durable T-00.3 validator' {
        Assert-T003HelperLoaded
    }

    It 'accepts the canonical repository state' {
        Assert-T003HelperLoaded
        $codes = @(Get-T003FailureCodes `
            (Test-Phase00T003PolicyRehomingContract -RepositoryRoot $repositoryRoot))
        $codes.Count | Should Be 0
    }

    It 'emits one result for each durable category' {
        Assert-T003HelperLoaded
        $codes = @(Test-Phase00T003PolicyRehomingContract `
            -RepositoryRoot $repositoryRoot | ForEach-Object { $_.Code })
        $expected = @(
            'P00-T003-SURFACE','P00-T003-REFERENCES','P00-T003-CONSUMERS',
            'P00-T003-INSTALLER','P00-T003-VALIDATOR','P00-T003-REGISTRY',
            'P00-T003-PRODUCT-DOCS','P00-T003-EVIDENCE','P00-T003-MANIFEST',
            'P00-T003-LATER-SUPERSESSION'
        )
        $codes.Count | Should Be 10
        @($codes | Sort-Object -Unique).Count | Should Be 10
        (($codes | Sort-Object) -join ',') |
            Should Be (($expected | Sort-Object) -join ',')
    }

    It 'reports contract failures without leaking validator execution errors' {
        Assert-T003HelperLoaded
        $messages = @(Test-Phase00T003PolicyRehomingContract `
            -RepositoryRoot $repositoryRoot | ForEach-Object { $_.Message }) -join "`n"
        $messages | Should Not Match `
            '(?i)Missing an argument for parameter|Cannot bind argument|not recognized as the name'
    }

    It 'recognizes registry destinations in both local_components and adopted_to' {
        Assert-T003HelperLoaded
        $registry = @(Test-Phase00T003PolicyRehomingContract `
            -RepositoryRoot $repositoryRoot | Where-Object {
                $_.Code -eq 'P00-T003-REGISTRY'
            }) | Select-Object -First 1
        $registry.Message | Should Not Match `
            "does not declare 'docs/policies/model-routing.md'"
    }

    It 'accepts the canonical non-runtime reference category cross-shell' {
        Assert-T003HelperLoaded
        $reference = @(Test-Phase00T003PolicyRehomingContract `
            -RepositoryRoot $repositoryRoot | Where-Object {
                $_.Code -eq 'P00-T003-REFERENCES'
            }) | Select-Object -First 1
        $reference.Status | Should Be 'PASS'
    }
}

Describe 'T-00.3 conclusion parser' {
    It 'parses the complete constrained section shape' {
        Assert-T003ParserLoaded
        $parsed = Read-Phase00T003Conclusion `
            -Path (Write-T003ConclusionFixture (Get-T003ValidConclusionText))
        $parsed.schema_version | Should Be '1'
        @($parsed.LegacySources).Count | Should Be 5
        @($parsed.Dispositions).Count | Should Be 1
        @($parsed.Destinations).Count | Should Be 1
        $parsed.Checks.staged_paths | Should Be '0'
        @($parsed.NonClaims).Count | Should Be 1
    }

    It 'rejects a duplicate top-level key' {
        Assert-T003ParserLoaded
        $text = (Get-T003ValidConclusionText) -replace `
            "schema_version: 1", "schema_version: 1`nschema_version: 1"
        Assert-T003Throws {
            Read-Phase00T003Conclusion -Path (Write-T003ConclusionFixture $text)
        }
    }

    It 'rejects a duplicate legacy source ID' {
        Assert-T003ParserLoaded
        $text = (Get-T003ValidConclusionText) -replace `
            '  - id: escalation', '  - id: context-budget'
        Assert-T003Throws {
            Read-Phase00T003Conclusion -Path (Write-T003ConclusionFixture $text)
        }
    }

    It 'rejects a duplicate destination path' {
        Assert-T003ParserLoaded
        $duplicate = @'
  - path: docs/policies/context-budget.md
    sha256: BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
'@
        $text = (Get-T003ValidConclusionText) -replace `
            '(?m)^checks:$', ($duplicate + 'checks:')
        Assert-T003Throws {
            Read-Phase00T003Conclusion -Path (Write-T003ConclusionFixture $text)
        }
    }

    It 'rejects an unknown disposition status' {
        Assert-T003ParserLoaded
        $text = (Get-T003ValidConclusionText) -replace `
            'status: REHOMED', 'status: COPIED'
        Assert-T003Throws {
            Read-Phase00T003Conclusion -Path (Write-T003ConclusionFixture $text)
        }
    }

    It 'rejects a non-uppercase SHA-256 value' {
        Assert-T003ParserLoaded
        $text = (Get-T003ValidConclusionText) -replace `
            'A3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE', `
            'a3fe19a6c131f3a9f43ef2ac5156993437cdc07b0abe6af284fe6e966c2f03ee'
        Assert-T003Throws {
            Read-Phase00T003Conclusion -Path (Write-T003ConclusionFixture $text)
        }
    }

    It 'rejects an incomplete marker anywhere in the artifact' {
        Assert-T003ParserLoaded
        $text = (Get-T003ValidConclusionText) -replace `
            'no-provider-call', 'pending-provider-check'
        Assert-T003Throws {
            Read-Phase00T003Conclusion -Path (Write-T003ConclusionFixture $text)
        }
    }
}

Describe 'T-00.3 installer retirement behavior' {
    It 'rejects an explicit request for the retired component' {
        $probe = Invoke-T003InstallerProbe -Components @('policies')
        $probe.ExitCode | Should Not Be 0
        $probe.Output | Should Match `
            "Component 'policies' was retired by Phase 00 T-00.3"
    }

    It 'does not advertise the retired component in the default plan' {
        $probe = Invoke-T003InstallerProbe
        $probe.ExitCode | Should Be 0
        $probe.Output | Should Not Match '(?im)^Components:.*\bpolicies\b'
    }
}

Describe 'T-00.3 later-product agent supersession' {
    It 'accepts a coherent Topic 03 manifest without changing the Phase 00 conclusion' {
        $fixture = New-T003LaterSupersessionFixture
        Assert-T003LaterStatus $fixture 'P00-T003-LATER-SUPERSESSION' PASS
        Assert-T003LaterStatus $fixture 'P00-T003-CONSUMERS' PASS
    }

    It 'rejects a missing current-product manifest' {
        $fixture = New-T003LaterSupersessionFixture
        Remove-Item -LiteralPath (Join-Path $fixture 'docs\evidence\current-product\topic-03\manifest.yml')
        Assert-T003LaterStatus $fixture 'P00-T003-LATER-SUPERSESSION' FAIL
    }

    It 'rejects a changed Phase 00 conclusion hash' {
        $fixture = New-T003LaterSupersessionFixture
        Add-Content -LiteralPath (Join-Path $fixture 'docs\evidence\phase-00\T-00.3\conclusion.yml') -Value '# mutation'
        Assert-T003LaterStatus $fixture 'P00-T003-LATER-SUPERSESSION' FAIL
    }

    It 'rejects a changed current-file hash' {
        $fixture = New-T003LaterSupersessionFixture
        Add-Content -LiteralPath (Join-Path $fixture 'template\.omp\agents\worker.md') -Value '# mutation'
        Assert-T003LaterStatus $fixture 'P00-T003-LATER-SUPERSESSION' FAIL
    }

    It 'rejects a manifest that does not bind the current installer' {
        $fixture = New-T003LaterSupersessionFixture
        $path = Join-Path $fixture 'docs\evidence\current-product\topic-03\manifest.yml'
        $manifest = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        $manifest.current_files = @($manifest.current_files | Where-Object {
            $_.path -cne 'scripts/install-template.ps1'
        })
        Set-T003LaterFixtureFile $fixture 'docs/evidence/current-product/topic-03/manifest.yml' `
            ($manifest | ConvertTo-Json -Depth 10)
        Assert-T003LaterStatus $fixture 'P00-T003-LATER-SUPERSESSION' FAIL
    }

    It 'rejects a manifest that does not bind the current validator' {
        $fixture = New-T003LaterSupersessionFixture
        $path = Join-Path $fixture 'docs\evidence\current-product\topic-03\manifest.yml'
        $manifest = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        $manifest.current_files = @($manifest.current_files | Where-Object {
            $_.path -cne 'scripts/validate-template.ps1'
        })
        Set-T003LaterFixtureFile $fixture 'docs/evidence/current-product/topic-03/manifest.yml' `
            ($manifest | ConvertTo-Json -Depth 10)
        Assert-T003LaterStatus $fixture 'P00-T003-LATER-SUPERSESSION' FAIL
    }

    It 'rejects a retired agent that remains discoverable' {
        $fixture = New-T003LaterSupersessionFixture
        Set-T003LaterFixtureFile $fixture 'template/.omp/agents/verifier.md' 'name: verifier'
        Assert-T003LaterStatus $fixture 'P00-T003-CONSUMERS' FAIL
    }
}

Describe 'T-00.3 baseline-backed mutation controls' {
    It 'maps a recreated policy file to P00-T003-SURFACE' {
        $fixture = New-T003RepositoryFixture
        $code = $script:t003MutationCodes.RecreatedPolicyFile
        Assert-T003CategoryStatus $fixture $code PASS
        $path = Join-Path $fixture 'template\.omp\policies\context-budget.yml'
        [void](New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force)
        [IO.File]::WriteAllText($path, 'mutation fixture', [Text.UTF8Encoding]::new($false))
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'maps a dangling policy reference to P00-T003-CONSUMERS' {
        $fixture = New-T003RepositoryFixture
        $code = $script:t003MutationCodes.DanglingPolicyRef
        Assert-T003CategoryStatus $fixture $code PASS
        $path = Join-Path $fixture 'template\.omp\commands\quick.md'
        $text = (Get-Content -Raw -LiteralPath $path -Encoding UTF8) +
            "`r`npolicy:workflow-sizing`r`n"
        [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'maps a changed quality-gate matrix to P00-T003-CONSUMERS' {
        $fixture = New-T003RepositoryFixture
        $code = $script:t003MutationCodes.ChangedGateMatrix
        Assert-T003CategoryStatus $fixture $code PASS
        Set-T003FixtureReplacement $fixture 'template/.omp/agents/reviewer.md' `
            'Review is mandatory for security, authentication, durable data, database migration, concurrency,' `
            'Review is optional for security, authentication, durable data, database migration, concurrency,'
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'maps a missing escalation boundary to P00-T003-CONSUMERS' {
        $fixture = New-T003RepositoryFixture
        $code = $script:t003MutationCodes.MissingEscalation
        Assert-T003CategoryStatus $fixture $code PASS
        Set-T003FixtureReplacement $fixture 'template/.omp/agents/worker.md' `
            '## Escalation boundary' '## Removed boundary'
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'maps an advertised installer component to P00-T003-INSTALLER' {
        $fixture = New-T003RepositoryFixture
        $code = $script:t003MutationCodes.AdvertisedInstaller
        Assert-T003CategoryStatus $fixture $code PASS
        $path = Join-Path $fixture 'scripts\install-template.ps1'
        $text = (Get-Content -Raw -LiteralPath $path -Encoding UTF8) +
            "`r`n    `"policies`" = `"policies`"`r`n"
        [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'maps a forged legacy-source hash to P00-T003-EVIDENCE' {
        $fixture = New-T003RepositoryFixture
        $code = $script:t003MutationCodes.ForgedSourceHash
        Assert-T003CategoryStatus $fixture $code PASS
        Set-T003FixtureReplacement $fixture `
            'docs/evidence/phase-00/T-00.3/conclusion.yml' `
            'A3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE' `
            'B3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE'
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'maps a forged destination hash to P00-T003-EVIDENCE' {
        $fixture = New-T003RepositoryFixture
        $code = $script:t003MutationCodes.ForgedDestHash
        Assert-T003CategoryStatus $fixture $code PASS
        Set-T003FixtureReplacement $fixture `
            'docs/evidence/phase-00/T-00.3/conclusion.yml' `
            '14BF081DC148463C4D670DC53FAD70F33BAAD540C88411B191E4F1AC555894BB' `
            '04BF081DC148463C4D670DC53FAD70F33BAAD540C88411B191E4F1AC555894BB'
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'requires an explicit later-topic supersession for changed model-routing bytes' {
        $fixture = New-T003RepositoryFixture
        Assert-T003CategoryStatus $fixture 'P00-T003-REFERENCES' PASS
        Assert-T003CategoryStatus $fixture 'P00-T003-EVIDENCE' PASS
        Set-T003FixtureReplacement $fixture 'docs/policies/model-routing.md' `
            'Later-topic supersession: Topic 02 KD-026 and spec/09' `
            'Removed later-topic supersession declaration'
        Assert-T003CategoryStatus $fixture 'P00-T003-REFERENCES' FAIL
        Assert-T003CategoryStatus $fixture 'P00-T003-EVIDENCE' FAIL
    }

    It 'keeps the historical model-routing destination hash immutable after supersession' {
        $fixture = New-T003RepositoryFixture
        $code = 'P00-T003-EVIDENCE'
        Assert-T003CategoryStatus $fixture $code PASS
        Set-T003FixtureReplacement $fixture `
            'docs/evidence/phase-00/T-00.3/conclusion.yml' `
            '9E348E097D6CD65B102C97BDE160E30C4ECADCB7A74FB405FBC274B4E8ABD8A1' `
            '8E348E097D6CD65B102C97BDE160E30C4ECADCB7A74FB405FBC274B4E8ABD8A1'
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'requires an explicit later-topic supersession for changed quality-gates bytes' {
        $fixture = New-T003RepositoryFixture
        Assert-T003CategoryStatus $fixture 'P00-T003-REFERENCES' PASS
        Assert-T003CategoryStatus $fixture 'P00-T003-EVIDENCE' PASS
        Set-T003FixtureReplacement $fixture 'docs/policies/quality-gates.md' `
            'Later-topic supersession: Topic 02 KD-026 and spec/10' `
            'Removed later-topic supersession declaration'
        Assert-T003CategoryStatus $fixture 'P00-T003-REFERENCES' FAIL
        Assert-T003CategoryStatus $fixture 'P00-T003-EVIDENCE' FAIL
    }

    It 'keeps the historical quality-gates destination hash immutable after supersession' {
        $fixture = New-T003RepositoryFixture
        $code = 'P00-T003-EVIDENCE'
        Assert-T003CategoryStatus $fixture $code PASS
        Set-T003FixtureReplacement $fixture `
            'docs/evidence/phase-00/T-00.3/conclusion.yml' `
            '28E693652A34304DC85117C578F23017E2863E68F104AFF05849EA2A9D9F32B5' `
            '38E693652A34304DC85117C578F23017E2863E68F104AFF05849EA2A9D9F32B5'
        Assert-T003CategoryStatus $fixture $code FAIL
    }

    It 'maps manifest PASS without conclusion evidence to P00-T003-MANIFEST' {
        $fixture = New-T003RepositoryFixture
        $code = $script:t003MutationCodes.PassWithoutEvidence
        Assert-T003CategoryStatus $fixture $code PASS
        Remove-Item -LiteralPath (Join-Path $fixture `
            'docs\evidence\phase-00\T-00.3\conclusion.yml')
        Assert-T003CategoryStatus $fixture $code FAIL
    }
}
