#Requires -Version 5.1

Set-StrictMode -Version Latest

$script:Phase00ExpectedIds = @(
    'T-00.1','T-00.2','T-00.3','T-00.4','T-00.5','T-00.6','T-00.7',
    'E1','E2','E3-A','E3-B','E3-C','E3-D','E3-E','E3-F','E3-G','E3-H',
    'E3-I','E3-J','E3-K','E3-L','E3-M','E4','E5-A','E5-B','E5-C','E5-D','E5-E','E5-F'
)

$script:Phase00AllowedStates = @(
    'NOT_STARTED','READY','RUNNING','PASS','FAIL',
    'BLOCKED_ENVIRONMENT','DEFERRED_PARALLEL_DISABLED'
)

$script:OmpPinnedCommit = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'
$script:OmpWatchedPaths = @(
    'packages/coding-agent/src/discovery/helpers.ts',
    'packages/coding-agent/src/discovery/builtin.ts',
    'packages/coding-agent/src/task/discovery.ts',
    'packages/coding-agent/src/task/agents.ts',
    'packages/coding-agent/src/task/index.ts',
    'packages/coding-agent/src/task/executor.ts',
    'packages/coding-agent/src/task/structured-subagent.ts',
    'packages/coding-agent/src/task/isolation-runner.ts',
    'packages/coding-agent/src/tools/yield.ts',
    'packages/coding-agent/src/config/model-resolver.ts',
    'packages/coding-agent/src/config/model-roles.ts',
    'packages/coding-agent/src/config/settings-schema.ts',
    'packages/utils/src/frontmatter.ts'
)

$script:Phase00T003LegacySources = @(
    [pscustomobject]@{ Id='context-budget'; Path='template/.omp/policies/context-budget.yml'; Lines=89; Sha256='A3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE'; GitBlob='f5591a7b7cd3e06efbd5431536ebd2391bdedd6d' },
    [pscustomobject]@{ Id='escalation'; Path='template/.omp/policies/escalation.yml'; Lines=52; Sha256='49CB215BEEC2424C9274BBA285E2AD28B651A124AF1BF07102A925FDAEA5FD1F'; GitBlob='c8e51d31baed0b2ce7ee000bd0be5deb3858e691' },
    [pscustomobject]@{ Id='model-routing'; Path='template/.omp/policies/model-routing.yml'; Lines=61; Sha256='67E7F80534AB66C57B13EF91AD88CABAE5518F8828E89C496B78AB9C4209F4A2'; GitBlob='c73070c1e73737a6947b48eb84338b583e4aa663' },
    [pscustomobject]@{ Id='quality-gates'; Path='template/.omp/policies/quality-gates.yml'; Lines=105; Sha256='69A8635F66C118D5BC12612E7D7B6F498E1886B7213F15613BE5A37B6370A1E2'; GitBlob='47f6d06191a9e7b68f07da1903d96b931024fa30' },
    [pscustomobject]@{ Id='workflow-sizing'; Path='template/.omp/policies/workflow-sizing.yml'; Lines=56; Sha256='603112590C993F9DEC61D17C32387C040C775C384B1D8656756170971703671B'; GitBlob='195c1f836bfd62381099cd9633073db4a37c88bc' }
)

$script:Phase00T003ReferenceNames = @(
    'context-budget.md','model-routing.md','quality-gates.md','README.md'
)

$script:Phase00T003DestinationPaths = @(
    'docs/policies/README.md',
    'docs/policies/context-budget.md',
    'docs/policies/model-routing.md',
    'docs/policies/quality-gates.md',
    'template/.omp/AGENTS.md',
    'template/.omp/commands/quick.md',
    'template/.omp/commands/standard.md',
    'template/.omp/commands/orchestrated.md',
    'template/.omp/agents/tech-lead.md',
    'template/.omp/agents/explorer.md',
    'template/.omp/agents/implementer.md',
    'template/.omp/agents/verifier.md',
    'template/.omp/agents/reviewer.md',
    'scripts/install-template.ps1',
    'scripts/validate-template.ps1'
)

$script:Phase00T003LaterSupersessions = @{
    'docs/policies/context-budget.md' = [pscustomobject]@{
        HistoricalSha256 = 'B3FB28CFE1ABC3C7D8C0EBED874F079E9F4271E1D47F9AF1CD4372DCC5776400'
        RequiredMarkers = @(
            'topic05-doc:context-budget',
            'Progressive retrieval follows source fitness within a bounded budget',
            'Optional CodeGraph',
            'Cheap Scout volume stays separate from premium/core context'
        )
    }
    'docs/policies/model-routing.md' = [pscustomobject]@{
        HistoricalSha256 = '9E348E097D6CD65B102C97BDE160E30C4ECADCB7A74FB405FBC274B4E8ABD8A1'
        RequiredMarkers = @(
            'Later-topic supersession: Topic 02 KD-026 and spec/09',
            'Phase 00 destination hash remains historical evidence',
            'Topic 03-selected aliases are the only required routing set',
            'E2 is closed'
        )
    }
    'docs/policies/quality-gates.md' = [pscustomobject]@{
        HistoricalSha256 = '28E693652A34304DC85117C578F23017E2863E68F104AFF05849EA2A9D9F32B5'
        RequiredMarkers = @(
            'Later-topic supersession: Topic 02 KD-026 and spec/10',
            'Phase 00 destination hash remains historical evidence',
            'selected gate-applier applies only those names',
            'Orchestrated classification alone does not mandate a Reviewer or worker dispatch'
        )
    }
}

$script:Phase00T003DispositionContract = @(
    [pscustomobject]@{ Section='context.components'; Status='REHOMED' },
    [pscustomobject]@{ Section='context.retrieval-order'; Status='REHOMED' },
    [pscustomobject]@{ Section='context.degradation-prevention'; Status='REHOMED' },
    [pscustomobject]@{ Section='context.offload-candidates'; Status='REHOMED' },
    [pscustomobject]@{ Section='context.offload-universal'; Status='SUPERSEDED' },
    [pscustomobject]@{ Section='escalation.worker-to-main'; Status='REHOMED' },
    [pscustomobject]@{ Section='escalation.main-to-user'; Status='REHOMED' },
    [pscustomobject]@{ Section='escalation.do-not-escalate'; Status='REHOMED' },
    [pscustomobject]@{ Section='escalation.spawned-tech-lead-audience'; Status='SUPERSEDED' },
    [pscustomobject]@{ Section='model-routing.authority'; Status='REHOMED' },
    [pscustomobject]@{ Section='model-routing.five-required-roles'; Status='SUPERSEDED' },
    [pscustomobject]@{ Section='model-routing.portable-concrete-model'; Status='SUPERSEDED' },
    [pscustomobject]@{ Section='model-routing.constraints'; Status='REHOMED' },
    [pscustomobject]@{ Section='model-routing.effort-mapping'; Status='REHOMED' },
    [pscustomobject]@{ Section='model-routing.customization'; Status='REHOMED' },
    [pscustomobject]@{ Section='quality-gates.six-gates'; Status='REHOMED' },
    [pscustomobject]@{ Section='quality-gates.default-matrix'; Status='REHOMED' },
    [pscustomobject]@{ Section='quality-gates.override-rule'; Status='REHOMED' },
    [pscustomobject]@{ Section='quality-gates.selection-owner'; Status='REHOMED' },
    [pscustomobject]@{ Section='quality-gates.reviewer-self-selection'; Status='SUPERSEDED' },
    [pscustomobject]@{ Section='workflow-sizing.quick'; Status='REHOMED' },
    [pscustomobject]@{ Section='workflow-sizing.standard'; Status='REHOMED' },
    [pscustomobject]@{ Section='workflow-sizing.orchestrated'; Status='REHOMED' },
    [pscustomobject]@{ Section='workflow-sizing.larger-when-in-doubt'; Status='SUPERSEDED' },
    [pscustomobject]@{ Section='workflow-sizing.risk-levels'; Status='REHOMED' },
    [pscustomobject]@{ Section='workflow-sizing.overrides'; Status='REHOMED' }
)

$script:Phase00T003ProductDocs = @(
    'README.md','CHANGELOG.md','docs/architecture.md','docs/customization.md',
    'docs/final-report.md','docs/installation.md','docs/report-design.md',
    'docs/security.md','docs/token-strategy.md','docs/workflow-v0.md'
)

$script:Phase00T003ExpectedE3BlockSha256 =
    '2BD5B20D935BFA8073016D3D3E131CB5E98F8B9D60531D0E4EDD53C352FEC312'
$script:Phase00T003ExpectedTerminalE3BlockSha256 =
    'AF129FC6B7DA417A12AD9E61A642C965523A2DD29197EAAE44BF23CDB13D85F7'

function New-Phase00ValidationResult {
    param(
        [ValidateSet('PASS','FAIL','WARN')][string]$Status,
        [string]$Code,
        [string]$Message
    )

    [pscustomobject]@{
        Status = $Status
        Code = $Code
        Message = $Message
    }
}

function Get-Phase00FileSha256 {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
}

function Get-Phase00StringSha256 {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '').ToUpperInvariant()
    } finally {
        $sha.Dispose()
    }
}

function ConvertFrom-Phase00Scalar {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) { return $null }
    $trimmed = $Value.Trim()
    if ($trimmed -eq 'null') { return $null }
    if ($trimmed.Length -ge 2) {
        $first = $trimmed[0]
        $last = $trimmed[$trimmed.Length - 1]
        if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
            return $trimmed.Substring(1, $trimmed.Length - 2)
        }
    }
    return $trimmed
}

function ConvertFrom-Phase00InlineArray {
    param([AllowNull()][string]$Value)

    $trimmed = if ($null -eq $Value) { '' } else { $Value.Trim() }
    if (-not ($trimmed.StartsWith('[') -and $trimmed.EndsWith(']'))) {
        throw "Expected inline array, got: $Value"
    }
    $inner = $trimmed.Substring(1, $trimmed.Length - 2).Trim()
    if (-not $inner) { return @() }
    return @($inner.Split(',') | ForEach-Object { ConvertFrom-Phase00Scalar $_ })
}

function Complete-Phase00T003ConclusionRow {
    param(
        [Parameter(Mandatory)][string]$Section,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Row,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$LegacySources,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Dispositions,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Destinations
    )

    $requirements = @{
        legacy_sources = @('id','path','lines','sha256','git_blob')
        dispositions = @('source_section','status','destinations','authority')
        destinations = @('path','sha256')
    }
    if (-not $requirements.ContainsKey($Section)) {
        throw "Rows are not allowed in conclusion section '$Section'."
    }
    $missing = @($requirements[$Section] | Where-Object { -not $Row.Contains($_) })
    if ($missing.Count -gt 0) {
        throw "Incomplete $Section row; missing: $($missing -join ', ')."
    }
    if ($Row.Count -ne $requirements[$Section].Count) {
        throw "Unexpected keys in $Section row."
    }

    switch ($Section) {
        'legacy_sources' {
            if ([string]$Row.id -eq '' -or [string]$Row.path -eq '') {
                throw 'Legacy source id and path must be non-empty.'
            }
            $parsedLines = 0
            if (-not [int]::TryParse([string]$Row.lines, [ref]$parsedLines) -or $parsedLines -le 0) {
                throw "Legacy source '$($Row.id)' has an invalid line count."
            }
            if ([string]$Row.sha256 -cnotmatch '^[0-9A-F]{64}$') {
                throw "Legacy source '$($Row.id)' has an invalid SHA-256 value."
            }
            if ([string]$Row.git_blob -cnotmatch '^[0-9a-f]{40}$') {
                throw "Legacy source '$($Row.id)' has an invalid Git blob value."
            }
            [void]$LegacySources.Add([pscustomobject]@{
                id = [string]$Row.id
                path = [string]$Row.path
                lines = [string]$Row.lines
                sha256 = [string]$Row.sha256
                git_blob = [string]$Row.git_blob
            })
        }
        'dispositions' {
            if ([string]$Row.source_section -eq '' -or
                [string]$Row.authority -eq '') {
                throw 'Disposition source_section and authority must be non-empty.'
            }
            if ([string]$Row.status -notin @('REHOMED','SUPERSEDED')) {
                throw "Unknown disposition status '$($Row.status)'."
            }
            [void]$Dispositions.Add([pscustomobject]@{
                source_section = [string]$Row.source_section
                status = [string]$Row.status
                destinations = @($Row.destinations)
                authority = [string]$Row.authority
            })
        }
        'destinations' {
            if ([string]$Row.path -eq '') { throw 'Destination path must be non-empty.' }
            if ([string]$Row.sha256 -cnotmatch '^[0-9A-F]{64}$') {
                throw "Destination '$($Row.path)' has an invalid SHA-256 value."
            }
            [void]$Destinations.Add([pscustomobject]@{
                path = [string]$Row.path
                sha256 = [string]$Row.sha256
            })
        }
    }
}

function Read-Phase00T003Conclusion {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "T-00.3 conclusion not found: $Path"
    }

    $raw = Get-Content -Raw -LiteralPath $Path -Encoding UTF8
    if ($raw -match '(?i)\b(?:TODO|TBD|PENDING|INCOMPLETE|PLACEHOLDER)\b') {
        throw 'T-00.3 conclusion contains an incomplete marker.'
    }

    $scalarKeys = @(
        'schema_version','phase','task','status','provider_calls','parallel_mode'
    )
    $sectionKeys = @(
        'legacy_sources','dispositions','destinations','checks','non_claims'
    )
    $root = [ordered]@{}
    $declaredSections = @{}
    $legacySources = [System.Collections.Generic.List[object]]::new()
    $dispositions = [System.Collections.Generic.List[object]]::new()
    $destinations = [System.Collections.Generic.List[object]]::new()
    $checks = [ordered]@{}
    $nonClaims = [System.Collections.Generic.List[string]]::new()
    $section = $null
    $currentRow = $null

    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line.Contains("`t")) { throw 'Tabs are not allowed in the T-00.3 conclusion.' }
        if ($line -match '^\s*$' -or $line -match '^\s*#') { continue }

        if ($line -match '^([a-z_]+):\s*(.*)$') {
            if ($null -ne $currentRow) {
                Complete-Phase00T003ConclusionRow $section $currentRow `
                    $legacySources $dispositions $destinations
                $currentRow = $null
            }
            $key = $Matches[1]
            $value = $Matches[2]
            if ($key -in $scalarKeys) {
                if ($root.Contains($key)) { throw "Duplicate conclusion root key: $key" }
                if ($value.Trim() -eq '') { throw "Conclusion root key '$key' is empty." }
                $root[$key] = ConvertFrom-Phase00Scalar $value
                $section = $null
                continue
            }
            if ($key -in $sectionKeys) {
                if ($value.Trim() -ne '') { throw "Conclusion section '$key' must not have an inline value." }
                if ($declaredSections.ContainsKey($key)) {
                    throw "Duplicate conclusion root key: $key"
                }
                $declaredSections[$key] = $true
                $section = $key
                continue
            }
            throw "Unknown conclusion root key: $key"
        }

        if ($line -match '^  - ([a-z0-9_]+):\s*(.*)$') {
            if ($section -notin @('legacy_sources','dispositions','destinations')) {
                throw "Mapping row appears outside a mapping-list section: $line"
            }
            if ($null -ne $currentRow) {
                Complete-Phase00T003ConclusionRow $section $currentRow `
                    $legacySources $dispositions $destinations
            }
            $currentRow = [ordered]@{}
            $key = $Matches[1]
            $allowed = switch ($section) {
                'legacy_sources' { @('id','path','lines','sha256','git_blob') }
                'dispositions' { @('source_section','status','destinations','authority') }
                'destinations' { @('path','sha256') }
            }
            if ($key -notin $allowed) { throw "Unknown $section row key: $key" }
            $currentRow[$key] = ConvertFrom-Phase00Scalar $Matches[2]
            continue
        }

        if ($line -match '^    ([a-z0-9_]+):\s*(.*)$') {
            if ($null -eq $currentRow -or
                $section -notin @('legacy_sources','dispositions','destinations')) {
                throw "Nested row field appears without a row: $line"
            }
            $key = $Matches[1]
            $allowed = switch ($section) {
                'legacy_sources' { @('id','path','lines','sha256','git_blob') }
                'dispositions' { @('source_section','status','destinations','authority') }
                'destinations' { @('path','sha256') }
            }
            if ($key -notin $allowed) { throw "Unknown $section row key: $key" }
            if ($currentRow.Contains($key)) { throw "Duplicate '$key' in $section row." }
            if ($section -eq 'dispositions' -and $key -eq 'destinations') {
                $currentRow[$key] = @(ConvertFrom-Phase00InlineArray $Matches[2])
            } else {
                $currentRow[$key] = ConvertFrom-Phase00Scalar $Matches[2]
            }
            continue
        }

        if ($line -match '^  ([a-z0-9_]+):\s*(.*)$') {
            if ($section -ne 'checks') { throw "Scalar map entry appears outside checks: $line" }
            $key = $Matches[1]
            if ($checks.Contains($key)) { throw "Duplicate checks key: $key" }
            $value = ConvertFrom-Phase00Scalar $Matches[2]
            if ([string]$value -eq '') { throw "Checks key '$key' is empty." }
            $checks[$key] = $value
            continue
        }

        if ($line -match '^  -\s*(.+)$') {
            if ($section -ne 'non_claims') {
                throw "Scalar list entry appears outside non_claims: $line"
            }
            $value = ConvertFrom-Phase00Scalar $Matches[1]
            if ([string]$value -eq '') { throw 'non_claims entries must be non-empty.' }
            [void]$nonClaims.Add([string]$value)
            continue
        }

        throw "Unrecognized T-00.3 conclusion line: $line"
    }

    if ($null -ne $currentRow) {
        Complete-Phase00T003ConclusionRow $section $currentRow `
            $legacySources $dispositions $destinations
    }

    $missingScalars = @($scalarKeys | Where-Object { -not $root.Contains($_) })
    $missingSections = @($sectionKeys | Where-Object { -not $declaredSections.ContainsKey($_) })
    if ($missingScalars.Count -gt 0 -or $missingSections.Count -gt 0) {
        throw "Incomplete conclusion root; missing scalars=$($missingScalars -join ','); sections=$($missingSections -join ',')."
    }
    if ($legacySources.Count -eq 0 -or $dispositions.Count -eq 0 -or
        $destinations.Count -eq 0 -or $checks.Count -eq 0 -or
        $nonClaims.Count -eq 0) {
        throw 'T-00.3 conclusion sections must be non-empty.'
    }

    $sourceIds = @($legacySources | ForEach-Object { $_.id })
    if (@($sourceIds | Sort-Object -Unique).Count -ne $sourceIds.Count) {
        throw 'Duplicate legacy source ID.'
    }
    $sourcePaths = @($legacySources | ForEach-Object { $_.path })
    if (@($sourcePaths | Sort-Object -Unique).Count -ne $sourcePaths.Count) {
        throw 'Duplicate legacy source path.'
    }
    $dispositionIds = @($dispositions | ForEach-Object { $_.source_section })
    if (@($dispositionIds | Sort-Object -Unique).Count -ne $dispositionIds.Count) {
        throw 'Duplicate disposition source_section.'
    }
    $destinationPaths = @($destinations | ForEach-Object { $_.path })
    if (@($destinationPaths | Sort-Object -Unique).Count -ne $destinationPaths.Count) {
        throw 'Duplicate destination path.'
    }
    if (@($nonClaims | Sort-Object -Unique).Count -ne $nonClaims.Count) {
        throw 'Duplicate non_claims entry.'
    }

    $root['LegacySources'] = @($legacySources)
    $root['Dispositions'] = @($dispositions)
    $root['Destinations'] = @($destinations)
    $root['Checks'] = [pscustomobject]$checks
    $root['NonClaims'] = @($nonClaims)
    return [pscustomobject]$root
}

function Test-Phase00T003TextMarkers {
    param(
        [AllowNull()][string]$Text,
        [Parameter(Mandatory)][string[]]$Markers
    )

    if ($null -eq $Text) { return $false }
    foreach ($marker in $Markers) {
        if ($Text.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            return $false
        }
    }
    return $true
}

function Get-Phase00T003RepositoryText {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $path = Join-Path $RepositoryRoot ($RelativePath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    return Get-Content -Raw -LiteralPath $path -Encoding UTF8
}

function Add-Phase00T003ContractResult {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Results,
        [Parameter(Mandatory)][bool]$Passed,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$PassMessage,
        [Parameter(Mandatory)][AllowEmptyString()][string]$FailMessage
    )

    if ($Passed) {
        [void]$Results.Add((New-Phase00ValidationResult PASS $Code $PassMessage))
    } else {
        [void]$Results.Add((New-Phase00ValidationResult FAIL $Code $FailMessage))
    }
}

function Test-Phase00T003LaterProductSupersessionContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
    $results = [Collections.Generic.List[object]]::new()
    $manifestOk = $true
    $manifestProblems = [Collections.Generic.List[string]]::new()

    try {
        $manifestPath = Join-Path $root 'docs\evidence\current-product\topic-03\manifest.yml'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            throw 'Topic 03 current-product manifest is missing.'
        }
        $manifestRaw = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8
        $manifest = $manifestRaw | ConvertFrom-Json -ErrorAction Stop

        $expectedRootKeys = @(
            'schema_version', 'topic', 'candidate', 'phase00_source',
            'phase00_conclusion_sha256', 'superseded_agents', 'selected_agents',
            'current_files', 'deepseek_environment'
        )
        $actualRootKeys = @($manifest.PSObject.Properties.Name)
        $actualRootShape = (@($actualRootKeys | Sort-Object) -join ',')
        $expectedRootShape = (@($expectedRootKeys | Sort-Object) -join ',')
        if ($actualRootShape -cne $expectedRootShape) {
            $manifestOk = $false
            [void]$manifestProblems.Add('Current-product manifest root shape is not closed and exact.')
        }

        if ([string]$manifest.schema_version -cne '1' -or $manifest.topic -cne '03' -or
            $manifest.candidate -cne 'C1' -or $manifest.phase00_source -cne 'T-00.3') {
            $manifestOk = $false
            [void]$manifestProblems.Add('Current-product manifest identity is not Topic 03 C1 over T-00.3.')
        }
        if ($manifest.deepseek_environment -notin @('PASS', 'FAIL', 'ENVIRONMENT_BLOCKED')) {
            $manifestOk = $false
            [void]$manifestProblems.Add('deepseek_environment is outside the closed status set.')
        }

        $conclusionPath = Join-Path $root 'docs\evidence\phase-00\T-00.3\conclusion.yml'
        $liveConclusionSha = Get-Phase00FileSha256 -Path $conclusionPath
        if ($manifest.phase00_conclusion_sha256 -cne $liveConclusionSha) {
            $manifestOk = $false
            [void]$manifestProblems.Add('Phase 00 conclusion SHA does not match immutable live bytes.')
        }

        $expectedSupersessions = @(
            [pscustomobject]@{ HistoricalPath = 'template/.omp/agents/tech-lead.md'; Disposition = 'rehomed'; CurrentPath = 'docs/roles/tech-lead.md' },
            [pscustomobject]@{ HistoricalPath = 'template/.omp/agents/explorer.md'; Disposition = 'replaced'; CurrentPath = 'template/.omp/agents/cheap-scout.md' },
            [pscustomobject]@{ HistoricalPath = 'template/.omp/agents/implementer.md'; Disposition = 'renamed'; CurrentPath = 'template/.omp/agents/worker.md' },
            [pscustomobject]@{ HistoricalPath = 'template/.omp/agents/verifier.md'; Disposition = 'retired'; CurrentPath = $null }
        )
        $actualSupersessions = @($manifest.superseded_agents)
        if ($actualSupersessions.Count -ne $expectedSupersessions.Count) {
            $manifestOk = $false
            [void]$manifestProblems.Add('Agent supersession mapping does not contain exactly four rows.')
        } else {
            for ($index = 0; $index -lt $expectedSupersessions.Count; $index++) {
                $expected = $expectedSupersessions[$index]
                $actual = $actualSupersessions[$index]
                $actualKeys = @($actual.PSObject.Properties.Name)
                $actualRowShape = (@($actualKeys | Sort-Object) -join ',')
                $expectedRowShape = (@(@('historical_path', 'disposition', 'current_path') |
                    Sort-Object) -join ',')
                if ($actualRowShape -cne $expectedRowShape -or
                    $actual.historical_path -cne $expected.HistoricalPath -or
                    $actual.disposition -cne $expected.Disposition -or
                    $actual.current_path -cne $expected.CurrentPath) {
                    $manifestOk = $false
                    [void]$manifestProblems.Add("Agent supersession row $index is not exact.")
                }
            }
        }

        $selectedAgents = @($manifest.selected_agents)
        if (($selectedAgents -join ',') -cne 'cheap-scout,worker,reviewer') {
            $manifestOk = $false
            [void]$manifestProblems.Add('Selected agents are not exactly cheap-scout, worker, reviewer.')
        }

        $requiredCurrentPaths = @(
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
        $currentRows = @($manifest.current_files)
        $currentPaths = @($currentRows | ForEach-Object { $_.path })
        if (@($currentPaths | Sort-Object -Unique).Count -ne $currentPaths.Count) {
            $manifestOk = $false
            [void]$manifestProblems.Add('current_files contains a duplicate path.')
        }
        foreach ($requiredPath in $requiredCurrentPaths) {
            if ($requiredPath -cnotin $currentPaths) {
                $manifestOk = $false
                [void]$manifestProblems.Add("current_files does not bind '$requiredPath'.")
            }
        }
        foreach ($row in $currentRows) {
            $rowKeys = @($row.PSObject.Properties.Name)
            $relative = [string]$row.path
            $unsafe = [string]::IsNullOrWhiteSpace($relative) -or
                [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)'
            $actualCurrentRowShape = (@($rowKeys | Sort-Object) -join ',')
            $expectedCurrentRowShape = (@(@('path', 'sha256') | Sort-Object) -join ',')
            if ($actualCurrentRowShape -cne $expectedCurrentRowShape -or $unsafe) {
                $manifestOk = $false
                [void]$manifestProblems.Add('current_files contains an invalid row or unsafe path.')
                continue
            }
            $livePath = Join-Path $root ($relative -replace '/', '\')
            if (-not (Test-Path -LiteralPath $livePath -PathType Leaf)) {
                $manifestOk = $false
                [void]$manifestProblems.Add("Current file '$relative' does not resolve.")
                continue
            }
            $liveSha = Get-Phase00FileSha256 -Path $livePath
            if ($row.sha256 -cne $liveSha) {
                $manifestOk = $false
                [void]$manifestProblems.Add("Current file '$relative' SHA does not match live bytes.")
            }
        }
    } catch {
        $manifestOk = $false
        [void]$manifestProblems.Add($_.Exception.Message)
    }

    Add-Phase00T003ContractResult $results $manifestOk P00-T003-LATER-SUPERSESSION `
        'Topic 03 current-product evidence binds immutable Phase 00 evidence and every current runtime file.' `
        ($manifestProblems -join ' ')

    try {
        $agentsDirectory = Join-Path $root 'template\.omp\agents'
        $agentNames = @()
        if (Test-Path -LiteralPath $agentsDirectory -PathType Container) {
            $agentNames = @(Get-ChildItem -LiteralPath $agentsDirectory -File -Filter '*.md' |
                Sort-Object Name | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) })
        }
        $consumersOk = ($agentNames -join ',') -ceq 'cheap-scout,reviewer,worker'
        $consumerFailure = if ($consumersOk) { '' } else {
            "Discovered current-product agents are '$($agentNames -join ',')', expected cheap-scout,reviewer,worker."
        }
    } catch {
        $consumersOk = $false
        $consumerFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $consumersOk P00-T003-CONSUMERS `
        'Current-product agent discovery contains exactly Cheap Scout, Reviewer, and Worker.' `
        $consumerFailure

    return @($results)
}

function Test-Phase00T003PolicyRehomingContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $root = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/')
    $results = [System.Collections.Generic.List[object]]::new()
    $evidenceOk = $false
    $laterResults = @(Test-Phase00T003LaterProductSupersessionContract -RepositoryRoot $root)
    $laterSupersession = @($laterResults | Where-Object {
        $_.Code -eq 'P00-T003-LATER-SUPERSESSION'
    }) | Select-Object -First 1
    $laterConsumers = @($laterResults | Where-Object {
        $_.Code -eq 'P00-T003-CONSUMERS'
    }) | Select-Object -First 1
    [void]$results.Add($laterSupersession)
    $laterSupersessionOk = $null -ne $laterSupersession -and
        $laterSupersession.Status -eq 'PASS'
    $laterConsumersOk = $null -ne $laterConsumers -and
        $laterConsumers.Status -eq 'PASS'

    try {
        $legacyDirectory = Join-Path $root 'template\.omp\policies'
        $surfaceOk = -not (Test-Path -LiteralPath $legacyDirectory)
        $surfaceFailure = if ($surfaceOk) { '' } else {
            'The retired template/.omp/policies surface still exists.'
        }
    } catch {
        $surfaceOk = $false
        $surfaceFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $surfaceOk P00-T003-SURFACE `
        'The retired installed policy directory is absent.' $surfaceFailure

    try {
        $referenceRoot = Join-Path $root 'docs\policies'
        $referenceNames = @()
        if (Test-Path -LiteralPath $referenceRoot -PathType Container) {
            $referenceNames = @(Get-ChildItem -LiteralPath $referenceRoot -File |
                Sort-Object Name | ForEach-Object { $_.Name })
        }
        $referencesOk = (($referenceNames -join ',') -ceq
            (($script:Phase00T003ReferenceNames | Sort-Object) -join ','))
        $referenceProblems = [System.Collections.Generic.List[string]]::new()
        if (-not $referencesOk) {
            [void]$referenceProblems.Add(
                "Expected exactly four references; found '$($referenceNames -join ',')'.")
        }

        $referenceMarkers = @{
            'README.md' = @(
                'OMP runtime: not loaded','Retired source:','context-budget.yml',
                'model-routing.yml','workflow-sizing.yml','quality-gates.yml',
                'escalation.yml','REHOMED_WITH_SUPERSEDED_CLAUSES',
                'REHOMED_WITH_SUPERSEDED_TIE_BREAK','REHOMED_BY_OWNER'
            )
            'context-budget.md' = @(
                'OMP runtime: not loaded','Retired source: context-budget.yml',
                'provisional defaults','`AGENTS.md`','1,500',
                '`RULES.md`','800','Agent system prompt',
                'Skill description','120','Skill body','2,500',
                'Task packet','Worker result','1,000',
                'must not contain the parent transcript',
                'must not contain chain-of-thought or full transcripts',
                'local code','local documentation','versioned documentation',
                'chars / 4','reference only','prompt contract only',
                'not established until evaluation','artifact manager'
            )
            'model-routing.md' = @(
                'OMP runtime: not loaded','Retired source: model-routing.yml',
                'Later-topic supersession: Topic 02 KD-026 and spec/09',
                'Phase 00 destination hash remains historical evidence',
                'Topic 03-selected aliases are the only required routing set',
                '| Each Topic 03-selected spawned worker or command adapter |',
                '| Main-session Tech Lead |','OmniRoute',
                'silent model fallback is disabled','environment properties',
                'E2 is closed'
            )
            'quality-gates.md' = @(
                'OMP runtime: not loaded','Retired source: quality-gates.yml',
                'Later-topic supersession: Topic 02 KD-026 and spec/10',
                'Phase 00 destination hash remains historical evidence',
                'api-compatibility','security','performance','adr-documentation',
                'release-readiness','rollback-readiness',
                'main session selects gates','task packet carries names',
                'selected gate-applier applies only those names',
                '| LOW | none |','| MEDIUM | security |',
                '| HIGH | api-compatibility, security, performance, release-readiness, rollback-readiness |',
                '| CRITICAL | api-compatibility, security, performance, release-readiness, rollback-readiness, adr-documentation |',
                'does not decide whether independent review is selected',
                'Orchestrated classification alone does not mandate a Reviewer or worker dispatch'
            )
        }
        foreach ($name in $script:Phase00T003ReferenceNames) {
            $text = Get-Phase00T003RepositoryText $root "docs/policies/$name"
            if (-not (Test-Phase00T003TextMarkers $text $referenceMarkers[$name])) {
                $referencesOk = $false
                [void]$referenceProblems.Add("Reference '$name' is missing canonical markers.")
            }
        }
        $contextReference = Get-Phase00T003RepositoryText $root `
            'docs/policies/context-budget.md'
        foreach ($pattern in @(
            '\| `AGENTS\.md` \| 600\u20131,200 \| 1,500 \|',
            '\| `RULES\.md` \| 300\u2013700 \| 800 \|',
            '\| Agent system prompt \| 500\u20131,200 \| 1,500 \|',
            '\| Skill description \| 30\u201380 \| 120 \|',
            '\| Skill body \| 800\u20132,000 \| 2,500 \|',
            '\| Task packet \| 300\u2013800 \| 1,200 \|',
            '\| Worker result \| 200\u2013600 \| 1,000 \|'
        )) {
            if ($null -eq $contextReference -or $contextReference -notmatch $pattern) {
                $referencesOk = $false
                [void]$referenceProblems.Add(
                    "Context-budget reference is missing a canonical budget row matching '$pattern'.")
            }
        }
        $referenceFailure = if ($referenceProblems.Count -eq 0) {
            'The policy-reference surface is incomplete.'
        } else { $referenceProblems -join ' ' }
    } catch {
        $referencesOk = $false
        $referenceFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $referencesOk P00-T003-REFERENCES `
        'Exactly four non-runtime references carry the canonical re-homed contracts.' `
        $referenceFailure

    try {
        $promptFiles = @()
        foreach ($relativeDirectory in @('template\.omp\agents','template\.omp\commands')) {
            $directory = Join-Path $root $relativeDirectory
            if (Test-Path -LiteralPath $directory -PathType Container) {
                $promptFiles += @(Get-ChildItem -LiteralPath $directory -File)
            }
        }
        $dangling = @($promptFiles | Select-String -Pattern `
            '(?i)policy:|(?:^|[\/])policies[\/]')
        $consumersOk = $dangling.Count -eq 0
        $consumerProblems = [System.Collections.Generic.List[string]]::new()
        if ($dangling.Count -gt 0) {
            [void]$consumerProblems.Add("Found $($dangling.Count) dangling installed-policy references.")
        }

        $consumerMarkers = @{
            'template/.omp/commands/quick.md' = @(
                'Quick is the user''s explicit narrow-task choice',
                'Default to no subagent spawn','## Lifecycle boundary',
                'invalidates earlier evidence'
            )
            'template/.omp/commands/standard.md' = @(
                'one integrated implementation lane','## Benefit-gated agents',
                'Cheap Scout (optional)','Worker (optional)',
                'General Reviewer (risk-gated)','Tech Lead owns fresh verification',
                'Opus is a preference'
            )
            'template/.omp/commands/orchestrated.md' = @(
                'at least two independently verifiable','one integration contract',
                'One writer is the default','Tech Lead fresh verification runs only after',
                'does not block an approved fallback'
            )
            'docs/roles/tech-lead.md' = @(
                'main session, not a spawnable agent definition',
                'No benefit means no spawn','The Tech Lead owns fresh verification'
            )
            'template/.omp/agents/cheap-scout.md' = @(
                '## Escalation boundary','bounded read-only evidence producer',
                'Never edit, verify acceptance, review a candidate'
            )
            'template/.omp/agents/worker.md' = @(
                '## Escalation boundary','Implement exactly one bounded work unit',
                'Never claim a higher effort than the returned runtime identity'
            )
            'template/.omp/agents/reviewer.md' = @(
                '## Escalation boundary','Review is mandatory for security',
                'Opus is a preference, not a gate','Never self-merge'
            )
            'template/.omp/AGENTS.md' = @(
                '## Escalation boundary','credentials','destructive action',
                'critical risk','required architecture violation',
                'request user authority','no subagent spawn',
                'Cheap Scout cannot replace fresh verification'
            )
        }
        foreach ($relative in $consumerMarkers.Keys) {
            $text = Get-Phase00T003RepositoryText $root $relative
            if (-not (Test-Phase00T003TextMarkers $text $consumerMarkers[$relative])) {
                $consumersOk = $false
                [void]$consumerProblems.Add("Consumer '$relative' is missing canonical markers.")
            }
        }
        if (-not $laterConsumersOk) {
            $consumersOk = $false
            [void]$consumerProblems.Add('Current-product agent discovery is not the selected exact set.')
        }
        $consumerFailure = if ($consumerProblems.Count -eq 0) {
            'The policy-derived consumer contract is incomplete.'
        } else { $consumerProblems -join ' ' }
    } catch {
        $consumersOk = $false
        $consumerFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $consumersOk P00-T003-CONSUMERS `
        'Installed commands, agents, and main instructions contain the re-homed contracts without dangling references.' `
        $consumerFailure

    try {
        $installer = Get-Phase00T003RepositoryText $root 'scripts/install-template.ps1'
        $installerOk = $null -ne $installer -and
            $installer -notmatch '(?m)^\s*["'']policies["'']\s*(?:,|=)' -and
            $installer -match [regex]::Escape(
                "Component 'policies' was retired by Phase 00 T-00.3. Policy contracts are inlined into commands/agents; human references live under docs/policies/.")
        $installerFailure = if ($null -eq $installer) {
            'scripts/install-template.ps1 is missing.'
        } else {
            'The installer still advertises policies or lacks the explicit retired-component rejection.'
        }
    } catch {
        $installerOk = $false
        $installerFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $installerOk P00-T003-INSTALLER `
        'The installer omits and explicitly rejects the retired policies component.' `
        $installerFailure

    try {
        $validator = Get-Phase00T003RepositoryText $root 'scripts/validate-template.ps1'
        $validatorOk = $null -ne $validator
        $validatorProblems = [System.Collections.Generic.List[string]]::new()
        if ($null -eq $validator) {
            [void]$validatorProblems.Add('scripts/validate-template.ps1 is missing.')
        } else {
            foreach ($legacy in $script:Phase00T003LegacySources) {
                $basename = [System.IO.Path]::GetFileName($legacy.Path)
                if ($validator.IndexOf($basename,
                    [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $validatorOk = $false
                    [void]$validatorProblems.Add("Validator still names '$basename'.")
                }
            }
            $validatorMarkers = @(
                'function Test-ApproxTokenBudget',
                'target minimum','target maximum','hard warning','advisory',
                'Test-Phase00T003PolicyRehomingContract',
                'docs\policies\README.md','docs\policies\context-budget.md',
                'docs\policies\model-routing.md','docs\policies\quality-gates.md'
            )
            if (-not (Test-Phase00T003TextMarkers $validator $validatorMarkers)) {
                $validatorOk = $false
                [void]$validatorProblems.Add('Validator retirement/registration markers are incomplete.')
            }
            $budgetCalls = @(
                'Test-ApproxTokenBudget\s+["'']template\\\.omp\\AGENTS\.md["'']\s+600\s+1200\s+1500',
                'Test-ApproxTokenBudget\s+["'']template\\\.omp\\RULES\.md["'']\s+300\s+700\s+800'
            )
            foreach ($pattern in $budgetCalls) {
                if ($validator -notmatch $pattern) {
                    $validatorOk = $false
                    [void]$validatorProblems.Add("Missing advisory budget call matching '$pattern'.")
                }
            }
            $budgetAgents = if ($laterSupersessionOk) {
                @('cheap-scout', 'worker', 'reviewer')
            } else {
                @('tech-lead', 'explorer', 'implementer', 'verifier', 'reviewer')
            }
            foreach ($agent in $budgetAgents) {
                $pattern = 'Test-ApproxTokenBudget\s+"template\\\.omp\\agents\\' + `
                    [regex]::Escape($agent) + '\.md"\s+500\s+1200\s+1500'
                if ($validator -notmatch $pattern) {
                    $validatorOk = $false
                    [void]$validatorProblems.Add("Missing advisory agent budget call for '$agent'.")
                }
            }
        }
        $validatorFailure = if ($validatorProblems.Count -eq 0) {
            'The repository validator has not retired the old policy checks.'
        } else { $validatorProblems -join ' ' }
    } catch {
        $validatorOk = $false
        $validatorFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $validatorOk P00-T003-VALIDATOR `
        'The repository validator registers T-00.3 and applies explicit advisory budget thresholds without legacy YAML checks.' `
        $validatorFailure

    try {
        $registryFiles = @('registry/upstreams.yml','registry/adoption-ledger.yml')
        $registryOk = $true
        $registryProblems = [System.Collections.Generic.List[string]]::new()
        $declaredReferences = [System.Collections.Generic.List[string]]::new()
        foreach ($relative in $registryFiles) {
            $path = Join-Path $root ($relative -replace '/', '\')
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                $registryOk = $false
                [void]$registryProblems.Add("Missing registry file '$relative'.")
                continue
            }
            $currentKey = $null
            foreach ($line in Get-Content -LiteralPath $path -Encoding UTF8) {
                if ($line -match '^    ([a-z_]+):') { $currentKey = $Matches[1] }
                if ($line -match '^\s*-\s+(docs/policies/[^\s#]+)') {
                    if ($currentKey -in @('local_components','adopted_to')) {
                        $declared = $Matches[1]
                        [void]$declaredReferences.Add($declared)
                        $declaredPath = Join-Path $root ($declared -replace '/', '\')
                        if (-not (Test-Path -LiteralPath $declaredPath -PathType Leaf)) {
                            $registryOk = $false
                            [void]$registryProblems.Add("Registry destination '$declared' does not resolve.")
                        }
                    }
                }
                if ($line -match 'template/\.omp/policies/' -and
                    $line -notmatch '^\s*#' -and $currentKey -ne 'superseded_paths') {
                    $registryOk = $false
                    [void]$registryProblems.Add("Retired path outside superseded_paths in '$relative'.")
                }
            }
        }
        foreach ($required in @(
            'docs/policies/context-budget.md',
            'docs/policies/model-routing.md',
            'docs/policies/quality-gates.md'
        )) {
            if ($required -notin @($declaredReferences)) {
                $registryOk = $false
                [void]$registryProblems.Add("Registry does not declare '$required'.")
            }
        }
        $registryFailure = if ($registryProblems.Count -eq 0) {
            'Registry policy destinations or superseded-path placement are incomplete.'
        } else { $registryProblems -join ' ' }
    } catch {
        $registryOk = $false
        $registryFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $registryOk P00-T003-REGISTRY `
        'Registry policy destinations resolve and retired paths remain explicitly superseded.' `
        $registryFailure

    try {
        $productDocsOk = $true
        $docProblems = [System.Collections.Generic.List[string]]::new()
        $forbiddenClaim = '(?im)(?:\.omp[\\/]policies[\\/]|(?:^|[\s`])policies[\\/][^\s`]*\.ya?ml|^\s*policies[\\/]\s+|^\s*\|\s*\*\*Policies\*\*\s*\||Five policies:|Available components:.*\bpolicies\b|Policies\s*\(YAML\)|Policies\s*\(5 policies\)|workflows, skills, schemas, and policies|\|\s*(?:context-budget|model-routing|workflow-sizing|quality-gates|escalation) policy\s*\|)'
        foreach ($relative in $script:Phase00T003ProductDocs) {
            $text = Get-Phase00T003RepositoryText $root $relative
            if ($null -eq $text) {
                $productDocsOk = $false
                [void]$docProblems.Add("Product document '$relative' is missing.")
            } elseif ($text -match $forbiddenClaim) {
                $productDocsOk = $false
                [void]$docProblems.Add("Product document '$relative' advertises the retired surface.")
            }
        }
        $productDocsFailure = if ($docProblems.Count -eq 0) {
            'Direct product documentation still advertises the retired policy surface.'
        } else { $docProblems -join ' ' }
    } catch {
        $productDocsOk = $false
        $productDocsFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $productDocsOk P00-T003-PRODUCT-DOCS `
        'The bounded current-product documentation set does not advertise an installed policy component.' `
        $productDocsFailure

    try {
        $conclusionPath = Join-Path $root 'docs\evidence\phase-00\T-00.3\conclusion.yml'
        $evidence = Read-Phase00T003Conclusion -Path $conclusionPath
        $evidenceOk = $evidence.schema_version -eq '1' -and
            $evidence.phase -eq '00' -and $evidence.task -eq 'T-00.3' -and
            $evidence.status -eq 'PASS' -and $evidence.provider_calls -eq '0' -and
            $evidence.parallel_mode -eq 'DISABLED'
        $evidenceProblems = [System.Collections.Generic.List[string]]::new()
        if (-not $evidenceOk) {
            [void]$evidenceProblems.Add('Conclusion root identity is not the exact local PASS contract.')
        }
        $laterRetiredAgentPaths = @(
            'template/.omp/agents/tech-lead.md',
            'template/.omp/agents/explorer.md',
            'template/.omp/agents/implementer.md',
            'template/.omp/agents/verifier.md'
        )
        $laterSupersededDestinationPaths = @(
            'template/.omp/AGENTS.md',
            'template/.omp/commands/quick.md',
            'template/.omp/commands/standard.md',
            'template/.omp/commands/orchestrated.md',
            'template/.omp/agents/tech-lead.md',
            'template/.omp/agents/explorer.md',
            'template/.omp/agents/implementer.md',
            'template/.omp/agents/verifier.md',
            'template/.omp/agents/reviewer.md',
            'scripts/install-template.ps1',
            'scripts/validate-template.ps1'
        )

        if (@($evidence.LegacySources).Count -ne $script:Phase00T003LegacySources.Count) {
            $evidenceOk = $false
            [void]$evidenceProblems.Add('Conclusion does not contain exactly five legacy source rows.')
        } else {
            for ($i = 0; $i -lt $script:Phase00T003LegacySources.Count; $i++) {
                $expected = $script:Phase00T003LegacySources[$i]
                $actual = $evidence.LegacySources[$i]
                if ($actual.id -cne $expected.Id -or $actual.path -cne $expected.Path -or
                    [int]$actual.lines -ne $expected.Lines -or
                    $actual.sha256 -cne $expected.Sha256 -or
                    $actual.git_blob -cne $expected.GitBlob) {
                    $evidenceOk = $false
                    [void]$evidenceProblems.Add("Legacy source row $i does not match the locked identity.")
                }
            }
        }

        if (@($evidence.Dispositions).Count -ne $script:Phase00T003DispositionContract.Count) {
            $evidenceOk = $false
            [void]$evidenceProblems.Add('Conclusion disposition coverage is incomplete.')
        } else {
            for ($i = 0; $i -lt $script:Phase00T003DispositionContract.Count; $i++) {
                $expected = $script:Phase00T003DispositionContract[$i]
                $actual = $evidence.Dispositions[$i]
                if ($actual.source_section -cne $expected.Section -or
                    $actual.status -cne $expected.Status) {
                    $evidenceOk = $false
                    [void]$evidenceProblems.Add("Disposition row $i does not match the required section/status.")
                    continue
                }
                if ($actual.status -eq 'REHOMED' -and @($actual.destinations).Count -eq 0) {
                    $evidenceOk = $false
                    [void]$evidenceProblems.Add("REHOMED disposition '$($actual.source_section)' has no destination.")
                }
                foreach ($destination in @($actual.destinations)) {
                    $dispositionPath = Join-Path $root ($destination -replace '/', '\')
                    $resolvedByLaterSupersession = $laterSupersessionOk -and
                        $destination -cin $laterRetiredAgentPaths
                    if ([System.IO.Path]::IsPathRooted($destination) -or
                        (-not (Test-Path -LiteralPath $dispositionPath -PathType Leaf) -and
                            -not $resolvedByLaterSupersession)) {
                        $evidenceOk = $false
                        [void]$evidenceProblems.Add("Disposition destination '$destination' does not resolve.")
                    }
                }
            }
        }

        if (@($evidence.Destinations).Count -ne $script:Phase00T003DestinationPaths.Count) {
            $evidenceOk = $false
            [void]$evidenceProblems.Add('Conclusion does not bind exactly 15 destination files.')
        } else {
            for ($i = 0; $i -lt $script:Phase00T003DestinationPaths.Count; $i++) {
                $expectedPath = $script:Phase00T003DestinationPaths[$i]
                $actual = $evidence.Destinations[$i]
                $actualPath = Join-Path $root ($expectedPath -replace '/', '\')
                $liveSha256 = Get-Phase00FileSha256 $actualPath
                $destinationMatches = $actual.path -ceq $expectedPath -and
                    $liveSha256 -ceq $actual.sha256
                if (-not $destinationMatches -and
                    $actual.path -ceq $expectedPath -and
                    $script:Phase00T003LaterSupersessions.ContainsKey($expectedPath)) {
                    $supersession = $script:Phase00T003LaterSupersessions[$expectedPath]
                    $liveText = Get-Phase00T003RepositoryText $root $expectedPath
                    $destinationMatches =
                        $actual.sha256 -ceq $supersession.HistoricalSha256 -and
                        (Test-Phase00T003TextMarkers $liveText $supersession.RequiredMarkers)
                }
                if (-not $destinationMatches -and $laterSupersessionOk -and
                    $actual.path -ceq $expectedPath -and
                    $expectedPath -cin $laterSupersededDestinationPaths) {
                    $destinationMatches = $true
                }
                if (-not $destinationMatches) {
                    $evidenceOk = $false
                    [void]$evidenceProblems.Add("Destination row $i does not bind '$expectedPath'.")
                }
            }
        }

        $requiredChecks = [ordered]@{
            repository_branch = 'main'
            repository_head = '62fecf277dc9d5e47d06319387eac747462214c1'
            legacy_surface_deleted = 'PASS'
            dangling_runtime_references = '0'
            installer_retirement = 'PASS'
            registry_resolution = 'PASS'
            direct_product_doc_scan = 'PASS'
            focused_pwsh = 'PASS'
            focused_windows_powershell = 'PASS'
            validator_pwsh = 'PASS'
            validator_windows_powershell = 'PASS'
            staged_paths = '0'
        }
        foreach ($key in $requiredChecks.Keys) {
            if ($evidence.Checks.PSObject.Properties.Name -notcontains $key -or
                [string]$evidence.Checks.$key -cne $requiredChecks[$key]) {
                $evidenceOk = $false
                [void]$evidenceProblems.Add("Conclusion check '$key' is missing or not exact.")
            }
        }
        $timestamp = [DateTimeOffset]::MinValue
        if ($evidence.Checks.PSObject.Properties.Name -notcontains 'implementation_timestamp' -or
            -not [DateTimeOffset]::TryParse(
                [string]$evidence.Checks.implementation_timestamp, [ref]$timestamp)) {
            $evidenceOk = $false
            [void]$evidenceProblems.Add('Conclusion implementation_timestamp is missing or invalid.')
        }
        foreach ($nonClaim in @(
            'no-provider-call','no-attempt-6','no-session-b-replay',
            'no-e3-m-execution','parallel-mode-disabled',
            'approximate-token-counting-only','peer-review-not-closed'
        )) {
            if ($nonClaim -notin @($evidence.NonClaims)) {
                $evidenceOk = $false
                [void]$evidenceProblems.Add("Conclusion non-claim '$nonClaim' is missing.")
            }
        }
        $evidenceFailure = if ($evidenceProblems.Count -eq 0) {
            'The T-00.3 conclusion is incomplete or hash-incoherent.'
        } else { $evidenceProblems -join ' ' }
    } catch {
        $evidenceOk = $false
        $evidenceFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $evidenceOk P00-T003-EVIDENCE `
        'The strict conclusion binds all legacy sources, dispositions, destinations, checks, and non-claims.' `
        $evidenceFailure

    try {
        $manifestPath = Join-Path $root 'docs\evidence\phase-00\manifest.yml'
        $manifest = Read-Phase00Manifest -Path $manifestPath
        $t003 = @($manifest.Entries | Where-Object { $_.id -eq 'T-00.3' }) |
            Select-Object -First 1
        $expectedDecision = 'Five inert policy YAML sources removed from the installed surface; canonical content re-homed to real consumers and human references; chars/4 budget checks remain advisory, not exact token enforcement'
        $manifestOk = $evidenceOk -and $manifest.parallel_mode -eq 'DISABLED' -and
            $null -ne $t003 -and $t003.kind -eq 'foundation' -and
            $t003.state -eq 'PASS' -and @($t003.depends_on).Count -eq 0 -and
            @($t003.artifacts).Count -eq 1 -and
            $t003.artifacts[0] -eq 'docs/evidence/phase-00/T-00.3/conclusion.yml' -and
            $t003.decision -eq $expectedDecision
        $manifestRaw = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8
        $e3Match = [regex]::Match($manifestRaw,
            '(?ms)^  - id: E3-A\r?\n.*?(?=^  - id: E4\r?$)')
        $historicalE3Ok = $false
        $terminalE3Ok = $false
        if (-not $e3Match.Success) {
            $manifestOk = $false
            $e3Hash = $null
        } else {
            $normalizedE3 = $e3Match.Value -replace "`r`n", "`n"
            $e3Hash = Get-Phase00StringSha256 $normalizedE3
            $historicalE3Ok = $e3Hash -ceq `
                $script:Phase00T003ExpectedE3BlockSha256
            $terminalE3Ok = $e3Hash -ceq `
                $script:Phase00T003ExpectedTerminalE3BlockSha256
            if (-not $historicalE3Ok -and -not $terminalE3Ok) {
                $manifestOk = $false
            }
        }
        $manifestFailure = if (-not $evidenceOk) {
            'T-00.3 cannot be authoritative PASS without its complete conclusion evidence.'
        } elseif (-not $historicalE3Ok -and -not $terminalE3Ok) {
            'An E3 manifest row changed outside T-00.3 authority.'
        } else {
            'The T-00.3 manifest row is not the exact evidence-backed PASS transition.'
        }
    } catch {
        $manifestOk = $false
        $manifestFailure = $_.Exception.Message
    }
    Add-Phase00T003ContractResult $results $manifestOk P00-T003-MANIFEST `
        'T-00.3 remains evidence-backed PASS; E3 is either the preserved historical block or the separately validated terminal block, and parallel mode remains disabled.' `
        $manifestFailure

    return @($results)
}

function Read-Phase00Manifest {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Manifest not found: $Path"
    }

    $root = [ordered]@{}
    $entries = [System.Collections.Generic.List[object]]::new()
    $current = $null
    $entriesDeclared = $false
    $entryKeys = @('id','kind','state','depends_on','artifacts','decision')

    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line.Contains("`t")) { throw 'Tabs are not allowed in the Phase 00 manifest.' }
        if ($line -match '^\s*$' -or $line -match '^\s*#') { continue }

        if ($line -match '^  - id:\s*(.+)$') {
            if ($null -ne $current) { [void]$entries.Add([pscustomobject]$current) }
            $current = [ordered]@{ id = ConvertFrom-Phase00Scalar $Matches[1] }
            continue
        }

        if ($line -match '^    ([a-z_]+):\s*(.*)$') {
            if ($null -eq $current) { throw "Entry field appears before an entry: $line" }
            $key = $Matches[1]
            if ($key -notin $entryKeys) { throw "Unknown manifest entry key: $key" }
            if ($current.Contains($key)) { throw "Duplicate key '$key' in entry '$($current.id)'." }
            $raw = $Matches[2]
            if ($key -in @('depends_on','artifacts')) {
                $current[$key] = @(ConvertFrom-Phase00InlineArray $raw)
            } else {
                $current[$key] = ConvertFrom-Phase00Scalar $raw
            }
            continue
        }

        if ($line -match '^([a-z_]+):\s*(.*)$') {
            if ($null -ne $current) {
                [void]$entries.Add([pscustomobject]$current)
                $current = $null
            }
            $key = $Matches[1]
            if ($root.Contains($key)) { throw "Duplicate manifest root key: $key" }
            if ($key -notin @('schema_version','phase','normative_spec','parallel_mode','entries')) {
                throw "Unknown manifest root key: $key"
            }
            if ($key -eq 'entries') {
                if ($entriesDeclared) { throw 'Duplicate manifest root key: entries' }
                $entriesDeclared = $true
            } else {
                $root[$key] = ConvertFrom-Phase00Scalar $Matches[2]
            }
            continue
        }

        throw "Unrecognized manifest line: $line"
    }

    if ($null -ne $current) { [void]$entries.Add([pscustomobject]$current) }
    $root['EntriesDeclared'] = $entriesDeclared
    $root['Entries'] = @($entries)
    return [pscustomobject]$root
}

function Test-Phase00ManifestContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = [System.Collections.Generic.List[object]]::new()
    $rootPath = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/')
    $manifestPath = Join-Path $rootPath 'docs\evidence\phase-00\manifest.yml'

    try {
        $manifest = Read-Phase00Manifest -Path $manifestPath
    } catch {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-PARSE $_.Exception.Message))
        return @($results)
    }

    $entries = @($manifest.Entries)
    $rootIdentityOk = $manifest.EntriesDeclared -eq $true -and $manifest.schema_version -eq '1' -and $manifest.phase -eq '00' -and
        $manifest.normative_spec -eq 'spec/phases/phase-00-foundation.md'
    if (-not $rootIdentityOk) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-ROOT 'Manifest schema version, phase, or normative spec is incorrect.'))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-ROOT 'Manifest root identity matches Phase 00.'))
    }

    $requiredEntryKeys = @('id','kind','state','depends_on','artifacts','decision')
    $missingKeys = @()
    foreach ($entry in $entries) {
        foreach ($key in $requiredEntryKeys) {
            if ($entry.PSObject.Properties.Name -notcontains $key) { $missingKeys += "$($entry.id):$key" }
        }
    }
    if ($missingKeys.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-PARSE ("Missing entry keys: " + ($missingKeys -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-SHAPE 'All entries contain the constrained manifest fields.'))
    }

    $ids = @($entries | ForEach-Object { $_.id })
    $uniqueIds = @($ids | Sort-Object -Unique)
    $missingIds = @($script:Phase00ExpectedIds | Where-Object { $_ -notin $ids })
    $unknownIds = @($uniqueIds | Where-Object { $_ -notin $script:Phase00ExpectedIds })
    if ($ids.Count -ne 29 -or $uniqueIds.Count -ne 29 -or $missingIds.Count -gt 0 -or $unknownIds.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-IDSET "Expected 29 unique canonical IDs; missing=$($missingIds -join ','); unknown=$($unknownIds -join ',')."))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-IDSET 'All 29 canonical Phase 00 IDs appear exactly once.'))
    }

    $badStates = @($entries | Where-Object { $_.state -notin $script:Phase00AllowedStates } | ForEach-Object { "$($_.id)=$($_.state)" })
    if ($badStates.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-STATE ("Unknown states: " + ($badStates -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-STATE 'All manifest states are allowed.'))
    }

    $badKinds = @($entries | Where-Object {
        ($_.id -like 'T-00.*' -and $_.kind -ne 'foundation') -or
        ($_.id -like 'E*' -and $_.kind -ne 'experiment')
    } | ForEach-Object { "$($_.id)=$($_.kind)" })
    if ($badKinds.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-KIND ("Incorrect entry kinds: " + ($badKinds -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-KIND 'Foundation and experiment rows use the correct kind.'))
    }

    $entryById = @{}
    foreach ($entry in $entries) { if (-not $entryById.ContainsKey($entry.id)) { $entryById[$entry.id] = $entry } }
    $badDependencies = @()
    $badDependencyStates = @()
    foreach ($entry in $entries) {
        foreach ($dependency in @($entry.depends_on)) {
            if ($dependency -eq $entry.id -or -not $entryById.ContainsKey($dependency)) {
                $badDependencies += "$($entry.id)->$dependency"
            } elseif ($entry.state -in @('READY','RUNNING','PASS') -and $entryById[$dependency].state -ne 'PASS') {
                $badDependencyStates += "$($entry.id)->$dependency=$($entryById[$dependency].state)"
            }
        }
    }
    if ($badDependencies.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-DEPENDENCY ("Invalid dependencies: " + ($badDependencies -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-DEPENDENCY 'All dependency IDs exist and are non-self references.'))
    }
    if ($badDependencyStates.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-DEPENDENCY-STATE ("Unmet dependencies for active/completed rows: " + ($badDependencyStates -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-DEPENDENCY-STATE 'READY, RUNNING, and PASS rows have passed dependencies.'))
    }

    $deferredRows = @($entries | Where-Object { $_.state -eq 'DEFERRED_PARALLEL_DISABLED' })
    if (@($deferredRows | Where-Object { $_.id -ne 'E3-M' }).Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-DEFER 'DEFERRED_PARALLEL_DISABLED is legal only for E3-M.'))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-DEFER 'Only E3-M uses the parallel-disabled deferral.'))
    }

    $e3m = @($entries | Where-Object { $_.id -eq 'E3-M' }) | Select-Object -First 1
    if ($null -ne $e3m -and $e3m.state -eq 'DEFERRED_PARALLEL_DISABLED' -and
        ($manifest.parallel_mode -ne 'DISABLED' -or [string]$e3m.decision -notmatch 'DISABLED')) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-PARALLEL 'E3-M deferral must retain and state parallel mode DISABLED.'))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-PARALLEL 'Parallel mode remains disabled under E3-M deferral.'))
    }

    $artifactErrors = @()
    $rootPrefix = $rootPath + [System.IO.Path]::DirectorySeparatorChar
    foreach ($entry in @($entries | Where-Object { $_.state -in @('PASS','BLOCKED_ENVIRONMENT') })) {
        if (@($entry.artifacts).Count -eq 0) {
            $artifactErrors += "$($entry.id):no-artifact"
            continue
        }
        foreach ($artifact in @($entry.artifacts)) {
            if ([System.IO.Path]::IsPathRooted($artifact)) {
                $artifactErrors += "$($entry.id):rooted:$artifact"
                continue
            }
            $resolved = [System.IO.Path]::GetFullPath((Join-Path $rootPath $artifact))
            if (-not $resolved.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
                -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                $artifactErrors += "$($entry.id):missing-or-escaped:$artifact"
            }
        }
    }
    if ($artifactErrors.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-MANIFEST-ARTIFACT ("Invalid PASS/BLOCKED_ENVIRONMENT artifacts: " + ($artifactErrors -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-MANIFEST-ARTIFACT 'Every PASS/BLOCKED_ENVIRONMENT row links to an existing in-repository artifact.'))
    }

    return @($results)
}

function Get-Phase00E3LJsonProperty {
    param($Object, [Parameter(Mandatory)][string]$Name)

    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    $property.Value
}

function Get-Phase00E3LJsonPropertyNames {
    param([Parameter(Mandatory)]$Object)

    if ($Object -is [System.Collections.IDictionary]) {
        return @($Object.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    }
    @($Object.PSObject.Properties.Name | Sort-Object)
}

function Resolve-Phase00E3LRepositoryArtifact {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    if ([IO.Path]::IsPathRooted($RelativePath) -or
        [string]::IsNullOrWhiteSpace($RelativePath)) {
        throw "E3-L artifact path is not repository-relative: $RelativePath"
    }
    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\','/')
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    $resolved = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
    if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "E3-L artifact is missing or escapes the repository: $RelativePath"
    }
    $resolved
}

function Read-Phase00E3LJsonArtifact {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $path = Resolve-Phase00E3LRepositoryArtifact $RepositoryRoot $RelativePath
    try {
        $raw = Get-Content -Raw -LiteralPath $path -Encoding UTF8
        $value = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "E3-L JSON is invalid at ${RelativePath}: $($_.Exception.Message)"
    }
    [pscustomobject][ordered]@{ Path = $path; Raw = $raw; Value = $value }
}

function Test-Phase00E3LHashReference {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]$Reference,
        [string]$ExpectedPath
    )

    $path = [string](Get-Phase00E3LJsonProperty $Reference 'path')
    $sha256 = [string](Get-Phase00E3LJsonProperty $Reference 'sha256')
    if (-not [string]::IsNullOrWhiteSpace($ExpectedPath) -and $path -cne $ExpectedPath) {
        throw "E3-L reference path '$path' does not match '$ExpectedPath'."
    }
    $full = Resolve-Phase00E3LRepositoryArtifact $RepositoryRoot $path
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash
    if ($sha256 -cne $actual) {
        throw "E3-L reference hash mismatch for '$path'."
    }
    $full
}

function Test-Phase00E3LStaticSourceArtifact {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $relative = 'docs/evidence/phase-00/E3-L/source-identity.json'
    $source = Read-Phase00E3LJsonArtifact $RepositoryRoot $relative
    $value = $source.Value
    if ((Get-Phase00E3LJsonProperty $value 'status') -cne 'PASS' -or
        (Get-Phase00E3LJsonProperty $value 'runtime_version') -cne 'omp/17.2.10' -or
        (Get-Phase00E3LJsonProperty $value 'runtime_executable_sha256') -cne
            '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' -or
        (Get-Phase00E3LJsonProperty $value 'pinned_commit') -cne $script:OmpPinnedCommit -or
        (Get-Phase00E3LJsonProperty $value 'supported_host') -cne
            'OMP-owned default main-CLI root-session construction class' -or
        @(Get-Phase00E3LJsonProperty $value 'positive_links').Count -ne 7 -or
        @(Get-Phase00E3LJsonProperty $value 'exclusions').Count -ne 6) {
        throw 'E3-L source identity artifact is incomplete or identity-incoherent.'
    }
    $source
}

function Test-Phase00E3LNoIncompleteMarkers {
    param(
        [Parameter(Mandatory)][string]$Raw,
        [Parameter(Mandatory)]$Value
    )

    $markers = @(Get-Phase00E3LJsonProperty $Value 'incomplete_markers')
    if ($markers.Count -ne 0 -or $Raw -match
        '(?i)\b(?:TODO|TBD|INCOMPLETE|NOT_IMPLEMENTED)\b|<pending>') {
        throw 'E3-L artifact contains an unresolved incomplete-work marker.'
    }
}

function Get-Phase00E3IYamlReferences {
    param([Parameter(Mandatory)][string]$Raw)

    $pattern = '(?ms)path:\s*(?<path>docs/evidence/phase-00/[^,\r\n}]+)' +
        '(?:,\s*|\r?\n\s*)sha256:\s*(?<sha>[A-F0-9]{64})'
    @([regex]::Matches($Raw, $pattern) | ForEach-Object {
        [pscustomobject][ordered]@{
            path = $_.Groups['path'].Value.Trim()
            sha256 = $_.Groups['sha'].Value
        }
    })
}

function Test-Phase00E3IArtifactContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    try {
        $root = [IO.Path]::GetFullPath($RepositoryRoot)
        $manifest = Read-Phase00Manifest `
            (Join-Path $root 'docs\evidence\phase-00\manifest.yml')
        $entry = @($manifest.Entries | Where-Object id -eq 'E3-I') |
            Select-Object -First 1
        if ($null -eq $entry) { throw 'E3-I is absent from the Phase 00 manifest.' }
        if ($entry.state -eq 'READY') {
            if (@($entry.artifacts).Count -ne 0) {
                throw 'READY E3-I must not claim terminal artifacts.'
            }
            return @(New-Phase00ValidationResult PASS P00-E3I-READY `
                'E3-I is READY and carries no terminal authority.')
        }
        if ($entry.state -cne 'PASS') {
            throw "Unsupported E3-I durable state '$($entry.state)'."
        }

        $expectedArtifacts = @(
            'docs/evidence/phase-00/E3-I/I1.yml',
            'docs/evidence/phase-00/E3-I/I2.yml',
            'docs/evidence/phase-00/E3-I/I3.yml',
            'docs/evidence/phase-00/E3-I/I4.yml',
            'docs/evidence/phase-00/E3-I/conclusion.yml'
        )
        if ((@($entry.artifacts | Sort-Object) -join ',') -cne
            (@($expectedArtifacts | Sort-Object) -join ',')) {
            throw 'PASS E3-I manifest artifacts are not the exact terminal set.'
        }

        $reasonByCase = [ordered]@{
            I1 = 'E3I_PROJECT_CONTROL_CONFIRMED'
            I2 = 'E3I_RUNTIME_OVERRIDE_DIVERGENCE_CONFIRMED'
            I3 = 'E3I_CLI_OVERLAY_DIVERGENCE_CONFIRMED'
            I4 = 'E3I_CANARY_SAFETY_RELIABILITY_CONFIRMED'
        }
        $referenceCountByCase = @{ I1 = 5; I2 = 5; I3 = 5; I4 = 3 }
        $caseHashes = @{}
        foreach ($caseName in @('I1','I2','I3','I4')) {
            $relative = "docs/evidence/phase-00/E3-I/$caseName.yml"
            $path = Resolve-Phase00E3LRepositoryArtifact $root $relative
            $raw = [IO.File]::ReadAllText($path)
            foreach ($marker in @(
                '(?m)^schema_version: 1$',
                '(?m)^phase: "00"$',
                '(?m)^experiment: E3-I$',
                "(?m)^case: $caseName$",
                '(?m)^status: PASS$',
                '(?m)^selected_attempt: 7$',
                "(?m)^reason: $($reasonByCase[$caseName])$",
                '(?m)^  authority: CHARACTERIZATION_ONLY$',
                '(?m)^  parallel_authorized: false$'
            )) {
                if ($raw -notmatch $marker) {
                    throw "E3-I $caseName identity or authority marker is missing."
                }
            }
            if ($raw -match '(?i)\b(?:TODO|TBD|INCOMPLETE|NOT_IMPLEMENTED)\b|<pending>') {
                throw "E3-I $caseName contains an unresolved incomplete-work marker."
            }
            $references = @(Get-Phase00E3IYamlReferences $raw)
            if ($references.Count -ne $referenceCountByCase[$caseName] -or
                @($references.path | Sort-Object -Unique).Count -ne $references.Count) {
                throw "E3-I $caseName raw reference set is incomplete or duplicated."
            }
            foreach ($reference in $references) {
                Test-Phase00E3LHashReference $root $reference | Out-Null
            }
            $caseHashes[$caseName] =
                (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        }

        $specificChecks = [ordered]@{
            I1 = @(
                '(?m)^  project_config_apply: false$',
                '(?m)^  child_config_values: \[false\]$',
                '(?m)^  task_branches: \[APPLY_FALSE_CAPTURE_ONLY, APPLY_FALSE_CAPTURE_ONLY, APPLY_FALSE_CAPTURE_ONLY\]$',
                '(?m)^  terminal_yield_count: 3$',
                '(?m)^  forbidden_tool_call_count: 0$'
            )
            I2 = @(
                '(?m)^  override_operation: pi\.pi\.settings\.override$',
                '(?m)^  before: false$',
                '(?m)^  after: true$',
                '(?m)^  called_set: false$',
                '(?m)^  called_flush_or_save: false$',
                '(?m)^  persistence: none$',
                '(?m)^  task_branches: \[APPLY_TRUE_NO_DIFF, APPLY_TRUE_NO_DIFF, APPLY_TRUE_NO_DIFF\]$'
            )
            I3 = @(
                '(?m)^  project_config_apply: false$',
                '(?m)^  cli_overlay_apply: true$',
                '(?m)^  child_config_values: \[false\]$',
                '(?m)^  task_branches: \[APPLY_TRUE_NO_DIFF, APPLY_TRUE_NO_DIFF, APPLY_TRUE_NO_DIFF\]$'
            )
            I4 = @(
                '(?m)^  session_a_status: PASS$',
                '(?m)^  session_b_status: PASS$',
                '(?m)^  canary_count: 9$',
                '(?m)^  terminal_yield_count: 9$',
                '(?m)^  forbidden_tool_call_count: 0$',
                '(?m)^  positive_cost_sample_count: 9$',
                '(?m)^  total_child_duration_ms: 43664$',
                '(?m)^  total_child_tokens: 49271$'
            )
        }
        foreach ($caseName in @('I1','I2','I3','I4')) {
            $path = Resolve-Phase00E3LRepositoryArtifact $root `
                "docs/evidence/phase-00/E3-I/$caseName.yml"
            $raw = [IO.File]::ReadAllText($path)
            foreach ($marker in @($specificChecks[$caseName])) {
                if ($raw -notmatch $marker) {
                    throw "E3-I $caseName decisive observation is missing."
                }
            }
        }

        $conclusionRelative = 'docs/evidence/phase-00/E3-I/conclusion.yml'
        $conclusionPath = Resolve-Phase00E3LRepositoryArtifact $root $conclusionRelative
        $conclusion = [IO.File]::ReadAllText($conclusionPath)
        foreach ($marker in @(
            '(?m)^schema_version: 3$',
            '(?m)^phase: "00"$',
            '(?m)^experiment: E3-I$',
            '(?m)^status: PASS$',
            '(?m)^selected_attempt: 7$',
            '(?m)^runtime_version: "omp/17\.2\.10"$',
            '(?m)^session_a_status: PASS$',
            '(?m)^session_b_status: PASS$',
            '(?m)^authority: CHARACTERIZATION_ONLY$',
            '(?m)^parallel_authorized: false$',
            '(?m)^parallel_mode_after: DISABLED$',
            '(?m)^e3_l_conclusion_consumed: false$',
            '(?m)^e3_l_replaced: false$',
            '(?m)^e3_m_replaced: false$'
        )) {
            if ($conclusion -notmatch $marker) {
                throw 'E3-I terminal conclusion identity or authority is incomplete.'
            }
        }
        $conclusionReferences = @(Get-Phase00E3IYamlReferences $conclusion)
        $expectedConclusionPaths = @(
            'docs/evidence/phase-00/E3-I/I1.yml',
            'docs/evidence/phase-00/E3-I/I2.yml',
            'docs/evidence/phase-00/E3-I/I3.yml',
            'docs/evidence/phase-00/E3-I/I4.yml',
            'docs/evidence/phase-00/E3-L/raw/joint-attempt-007.json'
        )
        if ((@($conclusionReferences.path | Sort-Object) -join ',') -cne
            (@($expectedConclusionPaths | Sort-Object) -join ',')) {
            throw 'E3-I conclusion does not hash-link the selected joint raw input and I1-I4.'
        }
        foreach ($reference in $conclusionReferences) {
            Test-Phase00E3LHashReference $root $reference | Out-Null
            if ($reference.path -match '/E3-I/I([1-4])\.yml$') {
                $caseName = "I$($Matches[1])"
                if ($reference.sha256 -cne $caseHashes[$caseName]) {
                    throw "E3-I conclusion hash for $caseName diverges from the case artifact."
                }
            }
        }
        if ($conclusion -match [regex]::Escape($conclusionRelative) -or
            $conclusion -match '(?i)\b(?:TODO|TBD|INCOMPLETE|NOT_IMPLEMENTED)\b|<pending>') {
            throw 'E3-I conclusion is circular or contains an incomplete-work marker.'
        }
        @(New-Phase00ValidationResult PASS P00-E3I-TERMINAL `
            'E3-I PASS artifacts are selected, hash-coherent, characterization-only, and preserve parallel disabled.')
    } catch {
        @(New-Phase00ValidationResult FAIL P00-E3I-ARTIFACT $_.Exception.Message)
    }
}

function Test-Phase00E3LArtifactContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    try {
        $root = [IO.Path]::GetFullPath($RepositoryRoot)
        $manifest = Read-Phase00Manifest `
            (Join-Path $root 'docs\evidence\phase-00\manifest.yml')
        $e3l = @($manifest.Entries | Where-Object id -eq 'E3-L') | Select-Object -First 1
        $e3m = @($manifest.Entries | Where-Object id -eq 'E3-M') | Select-Object -First 1
        if ($null -eq $e3l -or $null -eq $e3m) {
            throw 'E3-L or E3-M is absent from the Phase 00 manifest.'
        }
        if ($manifest.parallel_mode -cne 'DISABLED' -or
            $e3m.state -cne 'DEFERRED_PARALLEL_DISABLED' -or
            [string]$e3m.decision -notmatch 'parallel_mode: DISABLED') {
            throw 'E3-M deferral or root parallel_mode drifted.'
        }
        $source = Test-Phase00E3LStaticSourceArtifact $root

        if ($e3l.state -eq 'READY') {
            if (@($e3l.artifacts).Count -ne 0) {
                throw 'READY E3-L must not claim terminal artifacts.'
            }
            return @(New-Phase00ValidationResult PASS P00-E3L-READY `
                'E3-L is READY; its valid unlisted source proof grants no runtime authority.')
        }
        if ($e3l.state -notin @('PASS','FAIL','BLOCKED_ENVIRONMENT')) {
            throw "Unsupported E3-L durable state '$($e3l.state)'."
        }

        $conclusionRelative = 'docs/evidence/phase-00/E3-L/conclusion.json'
        if ($e3l.state -eq 'BLOCKED_ENVIRONMENT') {
            $jointArtifacts = @($e3l.artifacts | Where-Object {
                $_ -match '^docs/evidence/phase-00/E3-L/raw/joint-attempt-[0-9]{3}(?:\.adjudication)?\.json$'
            })
            if (@($e3l.artifacts).Count -ne 2 -or $jointArtifacts.Count -ne 1 -or
                $conclusionRelative -notin @($e3l.artifacts)) {
                throw 'BLOCKED_ENVIRONMENT requires exactly joint adjudication and conclusion.'
            }
            $joint = Read-Phase00E3LJsonArtifact $root $jointArtifacts[0]
            $j = $joint.Value
            $attempt = [int](Get-Phase00E3LJsonProperty $j 'attempt')
            $runtime = Get-Phase00E3LJsonProperty $j 'runtime'
            if ((Get-Phase00E3LJsonProperty $j 'experiment') -cne 'E3-I+E3-L' -or
                (Get-Phase00E3LJsonProperty $j 'selected') -ne $false -or
                $attempt -lt 5 -or
                (Get-Phase00E3LJsonProperty $runtime 'version') -cne 'omp/17.2.10' -or
                (Get-Phase00E3LJsonProperty $runtime 'sha256') -cne
                    '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' -or
                (Get-Phase00E3LJsonProperty $j 'automatic_retry') -ne $false -or
                (Get-Phase00E3LJsonProperty $j 'e3_i_conclusion_consumed') -ne $false -or
                (Get-Phase00E3LJsonProperty $j 'e3_l_conclusion_consumed') -ne $false) {
                throw 'Blocked joint adjudication identity is incomplete.'
            }
            Test-Phase00E3LHashReference $root `
                (Get-Phase00E3LJsonProperty $j 'source_identity') `
                'docs/evidence/phase-00/E3-L/source-identity.json' | Out-Null
            $sessions = Get-Phase00E3LJsonProperty $j 'sessions'
            $blockedCount = 0
            foreach ($name in @('a','b')) {
                $session = Get-Phase00E3LJsonProperty $sessions $name
                if ((Get-Phase00E3LJsonProperty $session 'transport_status') -eq
                    'BLOCKED_ENVIRONMENT') { $blockedCount++ }
                if ((Get-Phase00E3LJsonProperty $session 'invoked') -eq $true) {
                    foreach ($field in @('run','parent_stdout','parent_stderr')) {
                        Test-Phase00E3LHashReference $root `
                            (Get-Phase00E3LJsonProperty $session $field) | Out-Null
                    }
                    foreach ($canary in @(Get-Phase00E3LJsonProperty $session 'canaries')) {
                        Test-Phase00E3LHashReference $root $canary | Out-Null
                    }
                }
            }
            if ($blockedCount -lt 1) { throw 'Joint adjudication has no terminal environment block.' }
            if ($jointArtifacts[0] -match '\.adjudication\.json$') {
                $rawJointRelative = $jointArtifacts[0] -replace `
                    '\.adjudication\.json$','.json'
                Test-Phase00E3LHashReference $root `
                    (Get-Phase00E3LJsonProperty $j 'correction_of') $rawJointRelative |
                    Out-Null
                if ((Get-Phase00E3LJsonProperty $j 'correction_reason') -cne
                        'E3IL_RETRY_FACT_UNDER_REPORTED' -or
                    (Get-Phase00E3LJsonProperty `
                        (Get-Phase00E3LJsonProperty $sessions 'a') `
                        'recovered_provider_retry') -ne $true) {
                    throw 'Corrected joint adjudication lacks the exact retry-fact correction.'
                }
            }

            $conclusion = Read-Phase00E3LJsonArtifact $root $conclusionRelative
            $c = $conclusion.Value
            if ((Get-Phase00E3LJsonProperty $c 'state') -cne 'BLOCKED_ENVIRONMENT' -or
                [int](Get-Phase00E3LJsonProperty $c 'attempt') -ne $attempt -or
                (Get-Phase00E3LJsonProperty $c 'parallel_authorized') -ne $false -or
                (Get-Phase00E3LJsonProperty $c 'parallel_mode_after') -cne 'DISABLED' -or
                (Get-Phase00E3LJsonProperty $c 'e3_m_replaced') -ne $false) {
                throw 'Blocked E3-L conclusion is incomplete.'
            }
            Test-Phase00E3LHashReference $root `
                (Get-Phase00E3LJsonProperty $c 'joint_adjudication') $jointArtifacts[0] |
                Out-Null
            if ($conclusion.Raw -match [regex]::Escape($conclusionRelative)) {
                throw 'E3-L conclusion circularly references itself.'
            }
            Test-Phase00E3LNoIncompleteMarkers $conclusion.Raw $c
            return @(New-Phase00ValidationResult PASS P00-E3L-BLOCKED `
                'E3-L BLOCKED_ENVIRONMENT artifacts are complete and hash-coherent.')
        }

        $expectedArtifacts = @(
            'docs/evidence/phase-00/E3-L/source-identity.json',
            'docs/evidence/phase-00/E3-L/selected-transaction.json',
            'docs/evidence/phase-00/E3-L/L1.json',
            'docs/evidence/phase-00/E3-L/L2.json',
            'docs/evidence/phase-00/E3-L/L3.json',
            $conclusionRelative
        )
        if ((@($e3l.artifacts | Sort-Object) -join ',') -cne
            (@($expectedArtifacts | Sort-Object) -join ',')) {
            throw 'PASS/FAIL E3-L manifest artifacts are not the exact terminal set.'
        }
        $projectionRelative = 'docs/evidence/phase-00/E3-L/selected-transaction.json'
        $projection = Read-Phase00E3LJsonArtifact $root $projectionRelative
        $p = $projection.Value
        $expectedProjectionProperties = @(
            'attempt','boundaries','cases','experiment','oracle_statuses','raw_inputs',
            'runtime','schema_version','selected','source_identity','status',
            'supported_host','transport'
        )
        if ((@(Get-Phase00E3LJsonPropertyNames $p) -join ',') -cne
            ($expectedProjectionProperties -join ',')) {
            throw 'Selected E3-L projection has an unexpected root shape.'
        }
        $attempt = [int](Get-Phase00E3LJsonProperty $p 'attempt')
        $runtime = Get-Phase00E3LJsonProperty $p 'runtime'
        if ((Get-Phase00E3LJsonProperty $p 'experiment') -cne 'E3-L' -or
            (Get-Phase00E3LJsonProperty $p 'status') -cne $e3l.state -or
            (Get-Phase00E3LJsonProperty $p 'selected') -ne $true -or $attempt -lt 5 -or
            (Get-Phase00E3LJsonProperty $runtime 'version') -cne 'omp/17.2.10' -or
            (Get-Phase00E3LJsonProperty $runtime 'sha256') -cne
                '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' -or
            (Get-Phase00E3LJsonProperty $p 'supported_host') -cne
                'OMP-owned default main-CLI root-session construction class') {
            throw 'Selected E3-L projection identity is invalid.'
        }
        Test-Phase00E3LHashReference $root `
            (Get-Phase00E3LJsonProperty $p 'source_identity') `
            'docs/evidence/phase-00/E3-L/source-identity.json' | Out-Null
        $rawInputs = @(Get-Phase00E3LJsonProperty $p 'raw_inputs')
        if ($rawInputs.Count -eq 0) { throw 'Selected E3-L projection has no raw inputs.' }
        foreach ($reference in $rawInputs) {
            Test-Phase00E3LHashReference $root $reference | Out-Null
        }
        $projectionCases = @(Get-Phase00E3LJsonProperty $p 'cases')
        if ((@($projectionCases.name | Sort-Object) -join ',') -cne 'L1,L2,L3') {
            throw 'Selected E3-L projection does not contain exactly L1-L3.'
        }
        $projectionHash = (Get-FileHash -Algorithm SHA256 $projection.Path).Hash
        $caseHashByName = @{}
        foreach ($caseName in @('L1','L2','L3')) {
            $caseRelative = "docs/evidence/phase-00/E3-L/$caseName.json"
            $caseArtifact = Read-Phase00E3LJsonArtifact $root $caseRelative
            $case = $caseArtifact.Value
            if ((Get-Phase00E3LJsonProperty $case 'case') -cne $caseName -or
                [int](Get-Phase00E3LJsonProperty $case 'attempt') -ne $attempt) {
                throw "E3-L $caseName identity or attempt mismatch."
            }
            Test-Phase00E3LHashReference $root `
                (Get-Phase00E3LJsonProperty $case 'selected_transaction') `
                $projectionRelative | Out-Null
            $projected = @($projectionCases | Where-Object name -eq $caseName)[0]
            $observation = Get-Phase00E3LJsonProperty $case 'observation'
            if ((Get-Phase00E3LJsonProperty $observation 'reader_value') -ne
                    (Get-Phase00E3LJsonProperty $projected 'reader_value') -or
                (Get-Phase00E3LJsonProperty $observation 'child_value') -ne
                    (Get-Phase00E3LJsonProperty $projected 'child_value') -or
                (@(Get-Phase00E3LJsonProperty $observation 'task_branches') -join ',') -cne
                    (@(Get-Phase00E3LJsonProperty $projected 'task_branches') -join ',')) {
                throw "E3-L $caseName observation diverges from the selected projection."
            }
            $caseHashByName[$caseName] = (Get-FileHash -Algorithm SHA256 $caseArtifact.Path).Hash
        }

        $conclusion = Read-Phase00E3LJsonArtifact $root $conclusionRelative
        $c = $conclusion.Value
        if ((Get-Phase00E3LJsonProperty $c 'state') -cne $e3l.state -or
            [int](Get-Phase00E3LJsonProperty $c 'attempt') -ne $attempt -or
            (Get-Phase00E3LJsonProperty $c 'supported_host') -cne
                'OMP-owned default main-CLI root-session construction class' -or
            (Get-Phase00E3LJsonProperty $c 'runtime_version') -cne 'omp/17.2.10' -or
            (Get-Phase00E3LJsonProperty $c 'parallel_authorized') -ne $false -or
            (Get-Phase00E3LJsonProperty $c 'parallel_mode_after') -cne 'DISABLED' -or
            (Get-Phase00E3LJsonProperty $c 'e3_m_replaced') -ne $false) {
            throw 'E3-L conclusion identity or parallel boundary is incomplete.'
        }
        Test-Phase00E3LHashReference $root `
            (Get-Phase00E3LJsonProperty $c 'source_identity') `
            'docs/evidence/phase-00/E3-L/source-identity.json' | Out-Null
        Test-Phase00E3LHashReference $root `
            (Get-Phase00E3LJsonProperty $c 'selected_transaction') `
            $projectionRelative | Out-Null
        $caseReferences = @(Get-Phase00E3LJsonProperty $c 'cases')
        if ((@($caseReferences.name | Sort-Object) -join ',') -cne 'L1,L2,L3') {
            throw 'E3-L conclusion does not hash-link exactly L1-L3.'
        }
        foreach ($reference in $caseReferences) {
            $name = [string](Get-Phase00E3LJsonProperty $reference 'name')
            Test-Phase00E3LHashReference $root $reference `
                "docs/evidence/phase-00/E3-L/$name.json" | Out-Null
        }
        $claim = Get-Phase00E3LJsonProperty $c 'claim'
        if ($e3l.state -eq 'PASS' -and $claim -cne
            'The approved proxy observes live effective task.isolation.apply for the OMP-owned default main-CLI root-session class on pinned 17.2.10.') {
            throw 'E3-L PASS conclusion lacks the exact bounded claim.'
        }
        if ($e3l.state -eq 'FAIL' -and -not [string]::IsNullOrWhiteSpace([string]$claim)) {
            throw 'E3-L FAIL conclusion must not carry the PASS claim.'
        }
        if ($conclusion.Raw -match [regex]::Escape($conclusionRelative)) {
            throw 'E3-L conclusion circularly references itself.'
        }
        Test-Phase00E3LNoIncompleteMarkers $conclusion.Raw $c
        return @(New-Phase00ValidationResult PASS P00-E3L-TERMINAL `
            "E3-L $($e3l.state) artifacts are selected, complete, and hash-coherent.")
    } catch {
        return @(New-Phase00ValidationResult FAIL P00-E3L-ARTIFACT $_.Exception.Message)
    }
}

function Test-Phase00P00CX028CorrectionContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    try {
        $root = [IO.Path]::GetFullPath($RepositoryRoot)
        $manifest = Read-Phase00Manifest `
            (Join-Path $root 'docs\evidence\phase-00\manifest.yml')
        $e3i = @($manifest.Entries | Where-Object id -eq 'E3-I') |
            Select-Object -First 1
        $e3l = @($manifest.Entries | Where-Object id -eq 'E3-L') |
            Select-Object -First 1
        $e3m = @($manifest.Entries | Where-Object id -eq 'E3-M') |
            Select-Object -First 1
        $readyAuthority = $null -ne $e3i -and $null -ne $e3l -and
            $e3i.state -ceq 'READY' -and @($e3i.artifacts).Count -eq 0 -and
            $e3l.state -ceq 'READY' -and @($e3l.artifacts).Count -eq 0
        $terminalAuthority = $null -ne $e3i -and $null -ne $e3l -and
            $e3i.state -ceq 'PASS' -and $e3l.state -ceq 'PASS'
        if ($null -eq $e3m -or (-not $readyAuthority -and -not $terminalAuthority) -or
            $e3m.state -cne 'DEFERRED_PARALLEL_DISABLED' -or
            $manifest.parallel_mode -cne 'DISABLED') {
            throw 'P00-CX-028 authority must be coherent READY/READY or PASS/PASS with E3-M deferred.'
        }

        $e3iCases = @(
            [pscustomobject]@{
                Attempt = 4
                Relative = 'docs/evidence/phase-00/E3-I/raw/session-a.attempt-004.adjudication-002.json'
                Previous = 'docs/evidence/phase-00/E3-I/raw/session-a.attempt-004.adjudication.json'
                Reason = 'E3I_PARENT_SEQUENCE_MISMATCH'
                OutcomeLine = 612
                ParentRetryCount = 1
                NestedRecovery = $false
            },
            [pscustomobject]@{
                Attempt = 5
                Relative = 'docs/evidence/phase-00/E3-I/raw/session-a.attempt-005.adjudication-002.json'
                Previous = 'docs/evidence/phase-00/E3-I/raw/session-a.attempt-005.adjudication.json'
                Reason = 'E3I_NESTED_PROVIDER_RECOVERY'
                OutcomeLine = 735
                ParentRetryCount = 8
                NestedRecovery = $true
            }
        )
        $e3iHashes = @{}
        foreach ($case in $e3iCases) {
            $artifact = Read-Phase00E3LJsonArtifact $root $case.Relative
            $value = $artifact.Value
            $corrected = Get-Phase00E3LJsonProperty $value 'corrected_adjudication'
            $outcome = Get-Phase00E3LJsonProperty $value 'authoritative_outcome'
            $parentRetry = Get-Phase00E3LJsonProperty $value 'parent_retry_recovery'
            $nestedRetry = Get-Phase00E3LJsonProperty $value 'nested_provider_recovery'
            $providerExecution = Get-Phase00E3LJsonProperty $value 'provider_execution'
            if ([int](Get-Phase00E3LJsonProperty $value 'schema_version') -ne 2 -or
                (Get-Phase00E3LJsonProperty $value 'experiment') -cne 'E3-I' -or
                [int](Get-Phase00E3LJsonProperty $value 'attempt') -ne $case.Attempt -or
                (Get-Phase00E3LJsonProperty $value 'selected') -ne $false -or
                (Get-Phase00E3LJsonProperty $value 'correction_reason') -cne
                    'E3I_PARENT_TERMINAL_PRECEDENCE_SUPERSESSION' -or
                (Get-Phase00E3LJsonProperty $corrected 'status') -cne 'INVALID_RUN' -or
                (@(Get-Phase00E3LJsonProperty $corrected 'reasons') -join ',') -cne
                    $case.Reason -or
                (Get-Phase00E3LJsonProperty $corrected 'selection_eligible') -ne $false -or
                [int](Get-Phase00E3LJsonProperty $outcome 'event_line') -ne
                    $case.OutcomeLine -or
                (Get-Phase00E3LJsonProperty $outcome 'stop_reason') -cne 'stop' -or
                [int](Get-Phase00E3LJsonProperty $parentRetry 'count') -ne
                    $case.ParentRetryCount -or
                (Get-Phase00E3LJsonProperty $nestedRetry 'observed') -ne
                    $case.NestedRecovery -or
                (Get-Phase00E3LJsonProperty $providerExecution 'new_provider_call') -ne
                    $false -or
                (Get-Phase00E3LJsonProperty $providerExecution 'session_b_launched') -ne
                    $false) {
                throw "E3-I Attempt $($case.Attempt) correction shape or verdict drifted."
            }
            Test-Phase00E3LHashReference $root `
                (Get-Phase00E3LJsonProperty $value 'correction_of') $case.Previous |
                Out-Null
            foreach ($rawReference in @(Get-Phase00E3LJsonProperty $value 'raw_artifacts')) {
                $file = [string](Get-Phase00E3LJsonProperty $rawReference 'file')
                $relative = "docs/evidence/phase-00/E3-I/raw/$file"
                $full = Resolve-Phase00E3LRepositoryArtifact $root $relative
                if ((Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash -cne
                    [string](Get-Phase00E3LJsonProperty $rawReference 'sha256')) {
                    throw "E3-I raw hash mismatch for '$relative'."
                }
            }
            $e3iHashes[$case.Attempt] = `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $artifact.Path).Hash
        }

        $jointRelative = `
            'docs/evidence/phase-00/E3-L/raw/joint-attempt-005.adjudication-002.json'
        $joint = Read-Phase00E3LJsonArtifact $root $jointRelative
        $j = $joint.Value
        $sessions = Get-Phase00E3LJsonProperty $j 'sessions'
        $sessionA = Get-Phase00E3LJsonProperty $sessions 'a'
        $sessionB = Get-Phase00E3LJsonProperty $sessions 'b'
        $adjudication = Get-Phase00E3LJsonProperty $j 'adjudication'
        if ([int](Get-Phase00E3LJsonProperty $j 'schema_version') -ne 2 -or
            (Get-Phase00E3LJsonProperty $j 'experiment') -cne 'E3-I+E3-L' -or
            [int](Get-Phase00E3LJsonProperty $j 'attempt') -ne 5 -or
            (Get-Phase00E3LJsonProperty $j 'selected') -ne $false -or
            (Get-Phase00E3LJsonProperty $j 'correction_reason') -cne
                'E3IL_PARENT_TERMINAL_PRECEDENCE_AND_SELECTION_CORRECTION' -or
            (Get-Phase00E3LJsonProperty $sessionA 'transport_status') -cne
                'INVALID_RUN' -or
            (@(Get-Phase00E3LJsonProperty $sessionA 'transport_reasons') -join ',') -cne
                'E3IL_NESTED_PROVIDER_RECOVERY' -or
            (Get-Phase00E3LJsonProperty $sessionA 'provider_terminal') -ne $false -or
            (Get-Phase00E3LJsonProperty $sessionA 'recovered_provider_retry') -ne $true -or
            (Get-Phase00E3LJsonProperty $sessionB 'invoked') -ne $false -or
            (Get-Phase00E3LJsonProperty $sessionB 'skip_reason') -cne 'A_INVALID_RUN' -or
            (Get-Phase00E3LJsonProperty $adjudication 'status') -cne 'INVALID_RUN' -or
            (Get-Phase00E3LJsonProperty $adjudication 'reason') -cne
                'E3IL_NESTED_PROVIDER_RECOVERY' -or
            (Get-Phase00E3LJsonProperty $j 'new_provider_call') -ne $false -or
            (Get-Phase00E3LJsonProperty $j 'parallel_authorized') -ne $false) {
            throw 'E3-I/E3-L joint correction shape or verdict drifted.'
        }
        Test-Phase00E3LHashReference $root `
            (Get-Phase00E3LJsonProperty $j 'correction_of') `
            'docs/evidence/phase-00/E3-L/raw/joint-attempt-005.adjudication.json' |
            Out-Null
        foreach ($reference in @(
            (Get-Phase00E3LJsonProperty $j 'source_identity'),
            (Get-Phase00E3LJsonProperty $sessionA 'run'),
            (Get-Phase00E3LJsonProperty $sessionA 'parent_stdout'),
            (Get-Phase00E3LJsonProperty $sessionA 'parent_stderr')
        ) + @(Get-Phase00E3LJsonProperty $sessionA 'canaries')) {
            Test-Phase00E3LHashReference $root $reference | Out-Null
        }

        if ($readyAuthority) {
            $e3iConclusionRelative = 'docs/evidence/phase-00/E3-I/conclusion.yml'
            $e3iConclusionPath = Resolve-Phase00E3LRepositoryArtifact $root `
                $e3iConclusionRelative
            $e3iConclusion = Get-Content -LiteralPath $e3iConclusionPath -Raw `
                -Encoding UTF8
            if ($e3iConclusion -notmatch '(?m)^schema_version: 2$' -or
                $e3iConclusion -notmatch '(?m)^status: READY$' -or
                $e3iConclusion -notmatch [regex]::Escape([string]$e3iHashes[4]) -or
                $e3iConclusion -notmatch [regex]::Escape([string]$e3iHashes[5])) {
                throw 'E3-I READY conclusion does not bind both correction sidecars.'
            }

            $e3lConclusionRelative = 'docs/evidence/phase-00/E3-L/conclusion.json'
            $e3lConclusion = Read-Phase00E3LJsonArtifact $root $e3lConclusionRelative
            if ([int](Get-Phase00E3LJsonProperty $e3lConclusion.Value `
                    'schema_version') -ne 2 -or
                (Get-Phase00E3LJsonProperty $e3lConclusion.Value 'state') -cne `
                    'READY' -or
                $null -ne (Get-Phase00E3LJsonProperty $e3lConclusion.Value `
                    'selected_transaction')) {
                throw 'E3-L READY conclusion shape drifted.'
            }
            Test-Phase00E3LHashReference $root `
                (Get-Phase00E3LJsonProperty $e3lConclusion.Value 'joint_adjudication') `
                $jointRelative | Out-Null

            foreach ($relative in @(
                'docs/evidence/phase-00/E3-I/I1.yml',
                'docs/evidence/phase-00/E3-I/I2.yml',
                'docs/evidence/phase-00/E3-I/I3.yml',
                'docs/evidence/phase-00/E3-I/I4.yml',
                'docs/evidence/phase-00/E3-L/selected-transaction.json',
                'docs/evidence/phase-00/E3-L/L1.json',
                'docs/evidence/phase-00/E3-L/L2.json',
                'docs/evidence/phase-00/E3-L/L3.json'
            )) {
                if (Test-Path -LiteralPath (Join-Path $root $relative)) {
                    throw "Unselected P00-CX-028 authority artifact exists: $relative"
                }
            }
            return @(New-Phase00ValidationResult PASS P00-CX-028 `
                'P00-CX-028 correction sidecars, raw hashes, and READY authority are coherent.')
        }

        $e3iTerminal = @(Test-Phase00E3IArtifactContract -RepositoryRoot $root)
        $e3lTerminal = @(Test-Phase00E3LArtifactContract -RepositoryRoot $root)
        if (@($e3iTerminal + $e3lTerminal | Where-Object Status -eq 'FAIL').Count -gt 0) {
            throw 'Terminal authority does not preserve valid selected E3-I/E3-L artifacts.'
        }
        @(New-Phase00ValidationResult PASS P00-CX-028 `
            'P00-CX-028 historical correction sidecars and raw hashes remain coherent after the later Attempt 7 PASS selection.')
    } catch {
        @(New-Phase00ValidationResult FAIL P00-CX-028 $_.Exception.Message)
    }
}

function Test-Phase00E4ArtifactContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    try {
        $root = [IO.Path]::GetFullPath($RepositoryRoot)
        $manifest = Read-Phase00Manifest `
            (Join-Path $root 'docs\evidence\phase-00\manifest.yml')
        $entry = @($manifest.Entries | Where-Object id -eq 'E4') |
            Select-Object -First 1
        $expectedArtifacts = @(
            'docs/evidence/phase-00/E4/selected-transaction.json',
            'docs/evidence/phase-00/E4/conclusion.yml'
        )
        if ($null -eq $entry -or $entry.state -cne 'PASS' -or
            (@($entry.artifacts) -join "`n") -cne ($expectedArtifacts -join "`n")) {
            throw 'E4 manifest row is not the exact terminal PASS transition.'
        }

        $selectedRelative = $expectedArtifacts[0]
        $selected = Read-Phase00E3LJsonArtifact $root $selectedRelative
        $value = $selected.Value
        $runtime = Get-Phase00E3LJsonProperty $value 'runtime'
        $rule = Get-Phase00E3LJsonProperty $value 'rule_arm'
        $autoload = Get-Phase00E3LJsonProperty $value 'autoload_arm'
        $comparison = Get-Phase00E3LJsonProperty $value 'token_comparison'
        if ((Get-Phase00E3LJsonProperty $value 'status') -cne 'PASS' -or
            (Get-Phase00E3LJsonProperty $value 'selected_attempt') -ne 4 -or
            (Get-Phase00E3LJsonProperty $runtime 'version') -cne 'omp/17.2.10' -or
            (Get-Phase00E3LJsonProperty $runtime 'executable_sha256') -cne
                '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' -or
            (Get-Phase00E3LJsonProperty $runtime 'source_commit') -cne
                $script:OmpPinnedCommit -or
            (Get-Phase00E3LJsonProperty $rule 'source_run_status') -cne 'FAIL' -or
            (Get-Phase00E3LJsonProperty $rule 'corrected_status') -cne 'PASS' -or
            (Get-Phase00E3LJsonProperty $rule 'propagation_class') -cne
                'A_PROMPT_VISIBLE' -or
            (Get-Phase00E3LJsonProperty $rule 'system_prompt_sentinel_count') -ne 1 -or
            (Get-Phase00E3LJsonProperty $rule 'yield_call_count') -ne 1 -or
            (Get-Phase00E3LJsonProperty $autoload 'source_run_status') -cne 'PASS' -or
            (Get-Phase00E3LJsonProperty $autoload 'propagation_class') -cne
                'AUTOLOAD_HIDDEN_MESSAGE' -or
            (Get-Phase00E3LJsonProperty $autoload 'autoload_message_count') -ne 1 -or
            (Get-Phase00E3LJsonProperty $autoload 'yield_call_count') -ne 1 -or
            (Get-Phase00E3LJsonProperty $comparison `
                'autoload_minus_rule_tokens') -ne 145 -or
            (Get-Phase00E3LJsonProperty $comparison 'benchmark_claimed') -ne $false) {
            throw 'E4 selected transaction identity or discriminator drifted.'
        }
        foreach ($reference in @(
            @(Get-Phase00E3LJsonProperty $rule 'evidence') +
            @(Get-Phase00E3LJsonProperty $autoload 'evidence')
        )) {
            Test-Phase00E3LHashReference $root $reference | Out-Null
        }

        $ruleRun = Read-Phase00E3LJsonArtifact $root `
            'docs/evidence/phase-00/E4/raw/rule-attempt-004.run.json'
        $autoloadRun = Read-Phase00E3LJsonArtifact $root `
            'docs/evidence/phase-00/E4/raw/autoload-attempt-004.run.json'
        if ((Get-Phase00E3LJsonProperty $ruleRun.Value 'status') -cne 'FAIL' -or
            (Get-Phase00E3LJsonProperty $autoloadRun.Value 'status') -cne 'PASS' -or
            (Get-Phase00E3LJsonProperty $autoloadRun.Value 'selected') -ne $true) {
            throw 'E4 immutable source-run history is not preserved.'
        }

        $conclusionPath = Join-Path $root $expectedArtifacts[1]
        $conclusion = Get-Content -Raw -LiteralPath $conclusionPath -Encoding UTF8
        $selectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath `
            $selected.Path).Hash
        if ($conclusion -notmatch '(?m)^status: PASS\s*$' -or
            $conclusion -notmatch '(?m)^classification: A_PROMPT_VISIBLE\s*$' -or
            $conclusion -notmatch [regex]::Escape("  sha256: $selectedHash")) {
            throw 'E4 conclusion does not bind the selected Outcome A transaction.'
        }
        @(New-Phase00ValidationResult PASS P00-E4-TERMINAL `
            'E4 Outcome A correction, autoload comparison, raw hashes, and manifest are coherent.')
    } catch {
        @(New-Phase00ValidationResult FAIL P00-E4-TERMINAL $_.Exception.Message)
    }
}

function Test-Phase00E5ArtifactContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    try {
        $root = [IO.Path]::GetFullPath($RepositoryRoot)
        $manifest = Read-Phase00Manifest `
            (Join-Path $root 'docs\evidence\phase-00\manifest.yml')
        $commonArtifacts = @(
            'docs/evidence/phase-00/E5/source-identity.json',
            'docs/evidence/phase-00/E5/selected-transaction.json',
            'docs/evidence/phase-00/E5/conclusion.yml'
        )
        foreach ($id in @('E5-A','E5-B','E5-C','E5-D','E5-E','E5-F')) {
            $entry = @($manifest.Entries | Where-Object id -eq $id) |
                Select-Object -First 1
            $expected = @("docs/evidence/phase-00/$id/conclusion.yml") +
                $commonArtifacts
            if ($null -eq $entry -or $entry.state -cne 'PASS' -or
                (@($entry.artifacts) -join "`n") -cne ($expected -join "`n")) {
                throw "$id manifest row is not the exact terminal PASS transition."
            }
        }

        $selectedRelative = 'docs/evidence/phase-00/E5/selected-transaction.json'
        $selected = Read-Phase00E3LJsonArtifact $root $selectedRelative
        $value = $selected.Value
        $runtime = Get-Phase00E3LJsonProperty $value 'runtime'
        if ((Get-Phase00E3LJsonProperty $value 'status') -cne 'PASS' -or
            (Get-Phase00E3LJsonProperty $value 'selected_runtime_rows') -ne 9 -or
            (Get-Phase00E3LJsonProperty $value 'selected_runtime_pass_rows') -ne 9 -or
            (Get-Phase00E3LJsonProperty $value 'terminal_yield_count') -ne 9 -or
            (Get-Phase00E3LJsonProperty $value 'hash_mismatch_count') -ne 0 -or
            (Get-Phase00E3LJsonProperty $value `
                'sensitive_field_violation_count') -ne 0 -or
            (Get-Phase00E3LJsonProperty $runtime 'version') -cne 'omp/17.2.10' -or
            (Get-Phase00E3LJsonProperty $runtime 'executable_sha256') -cne
                '1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6' -or
            (Get-Phase00E3LJsonProperty $runtime 'source_commit') -cne
                $script:OmpPinnedCommit -or
            @(Get-Phase00E3LJsonProperty $value 'cases').Count -ne 6) {
            throw 'E5 selected transaction identity or terminal counts drifted.'
        }

        Test-Phase00E3LHashReference $root `
            (Get-Phase00E3LJsonProperty $value 'source_identity') `
            $commonArtifacts[0] | Out-Null
        foreach ($case in @(Get-Phase00E3LJsonProperty $value 'cases')) {
            if ((Get-Phase00E3LJsonProperty $case 'status') -cne 'PASS') {
                throw 'E5 selected transaction contains a non-PASS case.'
            }
            Test-Phase00E3LHashReference $root `
                (Get-Phase00E3LJsonProperty $case 'artifact') | Out-Null
        }

        $source = Read-Phase00E3LJsonArtifact $root $commonArtifacts[0]
        $upstream = Get-Phase00E3LJsonProperty $source.Value 'upstream'
        if ((Get-Phase00E3LJsonProperty $upstream 'commit') -cne
                $script:OmpPinnedCommit -or
            @(Get-Phase00E3LJsonProperty $source.Value 'claims').Count -ne 4) {
            throw 'E5 source identity is incomplete.'
        }

        $matrix = @(
            [pscustomobject]@{ Stem='e5-a-attempt-001'; Tools='yield,hub'; Lsp=$false; Calls=0; Result=$null; Cause='TASK_ENABLE_LSP_FALSE'; Fix='MERGE_PROJECT_TASK_ENABLE_LSP_TRUE' },
            [pscustomobject]@{ Stem='e5-b-explorer-attempt-002'; Tools='lsp,yield,hub'; Lsp=$true; Calls=1; Result=$true; Cause='ALL_LSP_GATES_SATISFIED'; Fix='NONE' },
            [pscustomobject]@{ Stem='e5-b-implementer-attempt-001'; Tools='lsp,yield,hub'; Lsp=$true; Calls=1; Result=$true; Cause='ALL_LSP_GATES_SATISFIED'; Fix='NONE' },
            [pscustomobject]@{ Stem='e5-b-reviewer-attempt-001'; Tools='lsp,yield,hub'; Lsp=$true; Calls=1; Result=$true; Cause='ALL_LSP_GATES_SATISFIED'; Fix='NONE' },
            [pscustomobject]@{ Stem='e5-b-verifier-attempt-001'; Tools='read,yield,hub'; Lsp=$false; Calls=0; Result=$null; Cause='AGENT_ALLOWLIST_MISSING_CONTROL'; Fix='CONTROL_NO_REMEDIATION' },
            [pscustomobject]@{ Stem='e5-c-attempt-001'; Tools='yield,hub'; Lsp=$false; Calls=0; Result=$null; Cause='PARENT_SESSION_LSP_DISABLED'; Fix='RELAUNCH_PARENT_WITH_LSP' },
            [pscustomobject]@{ Stem='e5-d-attempt-001'; Tools='read,yield,hub'; Lsp=$false; Calls=0; Result=$null; Cause='AGENT_ALLOWLIST_MISSING'; Fix='ADD_LSP_TO_AGENT_ALLOWLIST' },
            [pscustomobject]@{ Stem='e5-e-attempt-001'; Tools='lsp,yield,hub'; Lsp=$true; Calls=1; Result=$false; Cause='LANGUAGE_SERVER_UNAVAILABLE'; Fix='INSTALL_OR_CONFIGURE_LANGUAGE_SERVER' },
            [pscustomobject]@{ Stem='e5-f-attempt-001'; Tools='yield,hub'; Lsp=$false; Calls=0; Result=$null; Cause='LSP_ENABLED_FALSE'; Fix='ENABLE_PROJECT_LSP_ENABLED' }
        )
        foreach ($row in $matrix) {
            $base = "docs/evidence/phase-00/E5/raw/$($row.Stem)"
            $run = Read-Phase00E3LJsonArtifact $root "$base.run.json"
            $projection = Read-Phase00E3LJsonArtifact $root `
                "$base.projection.json"
            $runValue = $run.Value
            $projectionValue = $projection.Value
            if ((Get-Phase00E3LJsonProperty $runValue 'status') -cne 'PASS' -or
                (Get-Phase00E3LJsonProperty $runValue 'selected') -ne $true -or
                (Get-Phase00E3LJsonProperty $runValue `
                    'repository_unchanged') -ne $true -or
                (Get-Phase00E3LJsonProperty $runValue `
                    'live_home_changed_count') -ne 0 -or
                (Get-Phase00E3LJsonProperty $runValue `
                    'cleanup_succeeded') -ne $true -or
                (Get-Phase00E3LJsonProperty $projectionValue 'status') -cne 'PASS' -or
                (@(Get-Phase00E3LJsonProperty $projectionValue 'tools') -join ',') -cne
                    $row.Tools -or
                (Get-Phase00E3LJsonProperty $projectionValue 'lsp_present') -ne
                    $row.Lsp -or
                (Get-Phase00E3LJsonProperty $projectionValue 'lsp_call_count') -ne
                    $row.Calls -or
                (Get-Phase00E3LJsonProperty $projectionValue 'cause') -cne
                    $row.Cause -or
                (Get-Phase00E3LJsonProperty $projectionValue 'remediation') -cne
                    $row.Fix -or
                (Get-Phase00E3LJsonProperty $projectionValue `
                    'yield_call_count') -ne 1) {
                throw "E5 selected runtime row drifted: $($row.Stem)."
            }
            if ($null -ne $row.Result -and
                (Get-Phase00E3LJsonProperty $projectionValue `
                    'lsp_result_success') -ne $row.Result) {
                throw "E5 LSP result polarity drifted: $($row.Stem)."
            }
            if ($row.Stem -eq 'e5-e-attempt-001' -and
                (Get-Phase00E3LJsonProperty $projectionValue `
                    'lsp_result_text') -cne
                    'No language server found for this action') {
                throw 'E5-E exact no-server error changed.'
            }

            $artifacts = Get-Phase00E3LJsonProperty $runValue 'artifacts'
            $artifactPaths = @{
                parent_stdout = "$base.parent.stdout.jsonl"
                parent_stderr = "$base.parent.stderr.txt"
                child = "$base.child.jsonl"
                projection = "$base.projection.json"
            }
            foreach ($name in @($artifactPaths.Keys)) {
                $full = Resolve-Phase00E3LRepositoryArtifact $root `
                    $artifactPaths[$name]
                $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash
                if ((Get-Phase00E3LJsonProperty $artifacts $name) -cne $actual) {
                    throw "E5 raw artifact hash drifted: $($artifactPaths[$name])."
                }
            }
        }

        foreach ($id in @('E5-A','E5-B','E5-C','E5-D','E5-E','E5-F')) {
            $casePath = Join-Path $root "docs\evidence\phase-00\$id\conclusion.yml"
            $caseRaw = Get-Content -Raw -LiteralPath $casePath -Encoding UTF8
            if ($caseRaw -notmatch '(?m)^status: PASS\s*$') {
                throw "$id conclusion is not PASS."
            }
            foreach ($reference in @(Get-Phase00E3IYamlReferences $caseRaw)) {
                Test-Phase00E3LHashReference $root $reference | Out-Null
            }
        }

        $conclusionPath = Join-Path $root $commonArtifacts[2]
        $conclusion = Get-Content -Raw -LiteralPath $conclusionPath -Encoding UTF8
        $selectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath `
            $selected.Path).Hash
        if ($conclusion -notmatch '(?m)^status: PASS\s*$' -or
            $conclusion -notmatch [regex]::Escape("  sha256: $selectedHash") -or
            $conclusion -notmatch [regex]::Escape(
                'exact_no_server_error: "No language server found for this action"')) {
            throw 'E5 aggregate conclusion is not bound to the selected matrix.'
        }

        $rawRoot = Join-Path $root 'docs\evidence\phase-00\E5\raw'
        $forbiddenRoots = @($root, [Environment]::GetFolderPath('UserProfile')) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        foreach ($file in @(Get-ChildItem -LiteralPath $rawRoot -File)) {
            $raw = [string](Get-Content -Raw -LiteralPath $file.FullName `
                -Encoding UTF8)
            if ($null -eq $raw) { $raw = '' }
            foreach ($forbidden in $forbiddenRoots) {
                if ($raw.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    throw "E5 raw artifact exposes an absolute private root: $($file.Name)."
                }
            }
            if ($raw -match '(?i)Bearer\s+[A-Za-z0-9._~+/=-]{8,}') {
                throw "E5 raw artifact exposes a bearer value: $($file.Name)."
            }
        }

        @(New-Phase00ValidationResult PASS P00-E5-TERMINAL `
            'E5-A through E5-F, exact remediation map, raw hashes, safety, and manifest are coherent.')
    } catch {
        @(New-Phase00ValidationResult FAIL P00-E5-TERMINAL `
            ("$($_.Exception.Message) [$($_.ScriptStackTrace)]"))
    }
}

function Get-OmpRegistryData {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Registry not found: $Path" }
    $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^  - id:\s*oh-my-pi\s*$') { $start = $i; break }
    }
    if ($start -lt 0) { throw 'oh-my-pi registry entry not found.' }
    $end = $lines.Count - 1
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^  - id:\s*') { $end = $i - 1; break }
    }

    $data = [ordered]@{ watched_paths = @() }
    $inWatchedPaths = $false
    for ($i = $start; $i -le $end; $i++) {
        $line = $lines[$i]
        if ($line -match '^    watched_paths:\s*$') { $inWatchedPaths = $true; continue }
        if ($inWatchedPaths -and $line -match '^      -\s*(.+)$') {
            $data.watched_paths += ConvertFrom-Phase00Scalar $Matches[1]
            continue
        }
        if ($inWatchedPaths -and $line -match '^    [a-z_]+:') { $inWatchedPaths = $false }
        if ($line -match '^    ([a-z_]+):\s*(.*)$') {
            $data[$Matches[1]] = ConvertFrom-Phase00Scalar $Matches[2]
        }
    }
    return [pscustomobject]$data
}

function Test-OmpRegistryContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = [System.Collections.Generic.List[object]]::new()
    $rootPath = [System.IO.Path]::GetFullPath($RepositoryRoot)
    try {
        $data = Get-OmpRegistryData -Path (Join-Path $rootPath 'registry\upstreams.yml')
    } catch {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-REG-PARSE $_.Exception.Message))
        return @($results)
    }

    if ($data.pinned_commit -ne $script:OmpPinnedCommit) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-REG-PIN "OMP pin is '$($data.pinned_commit)', expected '$script:OmpPinnedCommit'."))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-REG-PIN 'OMP registry pin matches the verified source SHA.'))
    }

    $metadataOk = $data.clone_date -eq '2026-08-07' -and $data.tier -eq 'runtime-authority' -and
        $data.update_policy -eq 'manual-review-only' -and $data.evaluation_suite -eq 'evals/'
    if (-not $metadataOk) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-REG-METADATA 'OMP clone date, tier, update policy, or evaluation suite is incorrect.'))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-REG-METADATA 'OMP registry metadata matches the Phase 00 contract.'))
    }

    $actual = @($data.watched_paths)
    $unique = @($actual | Sort-Object -Unique)
    $missing = @($script:OmpWatchedPaths | Where-Object { $_ -notin $actual })
    $unknown = @($unique | Where-Object { $_ -notin $script:OmpWatchedPaths })
    if ($actual.Count -ne 13 -or $unique.Count -ne 13 -or $missing.Count -gt 0 -or $unknown.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-REG-WATCHED-COUNT "Expected 13 exact unique watched paths; missing=$($missing -join ','); unknown=$($unknown -join ',')."))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-REG-WATCHED-COUNT 'OMP registry contains the thirteen exact watched paths.'))
    }

    $cloneRoot = Join-Path $rootPath '_research\upstreams\oh-my-pi'
    $missingFiles = @($actual | Where-Object { -not (Test-Path -LiteralPath (Join-Path $cloneRoot $_) -PathType Leaf) })
    if ($missingFiles.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-REG-WATCHED-MISSING ("Watched source files missing: " + ($missingFiles -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-REG-WATCHED-MISSING 'All watched paths resolve in the pinned clone.'))
    }

    return @($results)
}

function Read-OmpCompatibilityLedger {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Compatibility ledger not found: $Path" }
    $root = [ordered]@{}
    $claims = [System.Collections.Generic.List[object]]::new()
    $current = $null
    $verifiedClaimsDeclared = $false
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line.Contains("`t")) { throw 'Tabs are not allowed in the compatibility ledger.' }
        if ($line -match '^\s*$' -or $line -match '^\s*#') { continue }
        if ($line -match '^  - id:\s*(.+)$') {
            if ($null -ne $current) { [void]$claims.Add([pscustomobject]$current) }
            $current = [ordered]@{ id = ConvertFrom-Phase00Scalar $Matches[1] }
            continue
        }
        if ($line -match '^    ([a-z_]+):\s*(.*)$') {
            if ($null -eq $current) { throw "Claim field appears before a claim: $line" }
            $key = $Matches[1]
            if ($key -notin @('statement','source_path','source_anchor','spec_anchor','evidence_type')) { throw "Unknown compatibility claim key: $key" }
            if ($current.Contains($key)) { throw "Duplicate compatibility key '$key' in '$($current.id)'." }
            $current[$key] = ConvertFrom-Phase00Scalar $Matches[2]
            continue
        }
        if ($line -match '^([a-z_]+):\s*(.*)$') {
            if ($null -ne $current) {
                [void]$claims.Add([pscustomobject]$current)
                $current = $null
            }
            $key = $Matches[1]
            if ($key -eq 'verified_claims') {
                if ($verifiedClaimsDeclared) { throw 'Duplicate compatibility root key: verified_claims' }
                $verifiedClaimsDeclared = $true
                continue
            }
            if ($root.Contains($key)) { throw "Duplicate compatibility root key: $key" }
            $root[$key] = ConvertFrom-Phase00Scalar $Matches[2]
            continue
        }
        throw "Unrecognized compatibility line: $line"
    }
    if ($null -ne $current) { [void]$claims.Add([pscustomobject]$current) }
    $root['VerifiedClaimsDeclared'] = $verifiedClaimsDeclared
    $root['Claims'] = @($claims)
    return [pscustomobject]$root
}

function Test-OmpCompatibilityContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = [System.Collections.Generic.List[object]]::new()
    $rootPath = [System.IO.Path]::GetFullPath($RepositoryRoot)
    try {
        $ledger = Read-OmpCompatibilityLedger -Path (Join-Path $rootPath 'registry\omp-compatibility.yml')
        $registry = Get-OmpRegistryData -Path (Join-Path $rootPath 'registry\upstreams.yml')
    } catch {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-COMPAT-PARSE $_.Exception.Message))
        return @($results)
    }

    if ($ledger.omp_verified_version -ne '17.2.10' -or $ledger.omp_minimum_version -ne '17.2.0') {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-COMPAT-VERSION 'OMP verified/minimum versions do not match the Phase 00 contract.'))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-COMPAT-VERSION 'OMP verified/minimum versions match the contract.'))
    }
    if ($ledger.omp_verified_commit -ne $script:OmpPinnedCommit) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-COMPAT-COMMIT 'Compatibility commit does not match the pinned OMP SHA.'))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-COMPAT-COMMIT 'Compatibility commit matches the pinned OMP SHA.'))
    }

    $metadataOk = $ledger.VerifiedClaimsDeclared -eq $true -and $ledger.schema_version -eq '1' -and $ledger.verification_date -eq '2026-08-08' -and
        $ledger.normative_source -eq 'spec/02-runtime-semantics.md'
    if (-not $metadataOk) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-COMPAT-METADATA 'Compatibility schema version, verification date, or normative source is incorrect.'))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-COMPAT-METADATA 'Compatibility metadata matches the Phase 00 contract.'))
    }

    $claims = @($ledger.Claims)
    $claimIds = @($claims | ForEach-Object { $_.id })
    $requiredDiscovery = @(1..15 | ForEach-Object { 'DISC-{0:D3}' -f $_ })
    $missingDiscovery = @($requiredDiscovery | Where-Object { $_ -notin $claimIds })
    if ($missingDiscovery.Count -gt 0 -or @($claimIds | Sort-Object -Unique).Count -ne $claimIds.Count) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-COMPAT-DISCOVERY ("Missing or duplicate discovery claims: " + ($missingDiscovery -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-COMPAT-DISCOVERY 'DISC-001 through DISC-015 are present and claim IDs are unique.'))
    }

    $requiredFields = @('statement','source_path','source_anchor','spec_anchor','evidence_type')
    $badFields = @()
    foreach ($claim in $claims) {
        foreach ($field in $requiredFields) {
            if ($claim.PSObject.Properties.Name -notcontains $field -or -not [string]$claim.$field) { $badFields += "$($claim.id):$field" }
        }
    }
    if ($badFields.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-COMPAT-CLAIM-FIELDS ("Missing claim fields: " + ($badFields -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-COMPAT-CLAIM-FIELDS 'Every verified claim has statement, source, anchors, and evidence type.'))
    }

    $badEvidenceTypes = @($claims | Where-Object { $_.evidence_type -ne 'SOURCE_VERIFIED' } | ForEach-Object { "$($_.id)=$($_.evidence_type)" })
    if ($badEvidenceTypes.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-COMPAT-EVIDENCE-TYPE ("Non-source-verified claims: " + ($badEvidenceTypes -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-COMPAT-EVIDENCE-TYPE 'All compatibility claims are explicitly source-verified.'))
    }

    $covered = @($claims | ForEach-Object { $_.source_path } | Sort-Object -Unique)
    $uncovered = @($registry.watched_paths | Where-Object { $_ -notin $covered })
    if ($uncovered.Count -gt 0) {
        [void]$results.Add((New-Phase00ValidationResult FAIL P00-COMPAT-WATCHED-COVERAGE ("Watched paths without a claim: " + ($uncovered -join ', '))))
    } else {
        [void]$results.Add((New-Phase00ValidationResult PASS P00-COMPAT-WATCHED-COVERAGE 'Every watched path backs at least one verified claim.'))
    }

    return @($results)
}

$phase00E1HelperPath = Join-Path $PSScriptRoot 'phase00-e1-evidence.ps1'
if (Test-Path -LiteralPath $phase00E1HelperPath -PathType Leaf) {
    . $phase00E1HelperPath
}
Set-StrictMode -Version Latest
