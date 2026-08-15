# Topic 05 four-arm retrieval benchmark primitives.
# Plan and deterministic modes never resolve credentials or start OMP/model processes.

$script:Topic05BenchmarkArms = @(
    'A_lead_native',
    'B_lead_codegraph',
    'C_scout_native_lead',
    'D_scout_codegraph_lead'
)
$script:Topic05BenchmarkFixtureClasses = @(
    'multi_file_call_path',
    'blast_radius_affected_tests',
    'unfamiliar_symbol_localization',
    'exact_text_config_native_fit',
    'dynamic_or_heuristic_graph_gap',
    'deterministic_absence_claim',
    'stale_partial_pending_index',
    'linked_worktree_index_mismatch',
    'source_or_candidate_mutation'
)
$script:Topic05BenchmarkModelProcessStarts = 0
$script:Topic05BenchmarkRepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))

function Assert-Topic05BenchmarkPropertySet {
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string]$Context
    )
    if ($null -eq $Value) { throw "$Context is null" }
    $actual = if ($Value -is [Collections.IDictionary]) {
        @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    } else {
        @($Value.PSObject.Properties.Name | Sort-Object)
    }
    $wanted = @($Expected | Sort-Object)
    if (($actual -join '|') -cne ($wanted -join '|')) {
        throw "$Context has unknown or missing fields: $($actual -join ', ')"
    }
}

function Assert-Topic05BenchmarkSha256 {
    param([AllowNull()][object]$Value, [Parameter(Mandatory)][string]$Context, [switch]$AllowNull)
    if ($AllowNull -and $null -eq $Value) { return }
    if ([string]$Value -cnotmatch '^[0-9a-f]{64}$') { throw "$Context must be lowercase SHA-256" }
}

function Get-Topic05BenchmarkTextSha256 {
    param([Parameter(Mandatory)][string]$Value)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Value)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    } finally { $sha.Dispose() }
}

function ConvertTo-Topic05BenchmarkCanonicalNode {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value -is [bool] -or
        $Value -is [byte] -or $Value -is [sbyte] -or
        $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int32] -or $Value -is [uint32] -or
        $Value -is [int64] -or $Value -is [uint64] -or
        $Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return $Value
    }
    if ($Value -is [Collections.IDictionary]) {
        $result = [ordered]@{}
        [string[]]$keys = @($Value.Keys | ForEach-Object { [string]$_ })
        [Array]::Sort($keys, [StringComparer]::Ordinal)
        foreach ($key in $keys) {
            $result[$key] = ConvertTo-Topic05BenchmarkCanonicalNode -Value $Value[$key]
        }
        return $result
    }
    if ($Value -is [Collections.IEnumerable]) {
        return @($Value | ForEach-Object { ConvertTo-Topic05BenchmarkCanonicalNode -Value $_ })
    }
    $properties = @($Value.PSObject.Properties.Name)
    if ($properties.Count -gt 0) {
        $result = [ordered]@{}
        [string[]]$names = @($properties)
        [Array]::Sort($names, [StringComparer]::Ordinal)
        foreach ($name in $names) {
            $result[$name] = ConvertTo-Topic05BenchmarkCanonicalNode -Value $Value.$name
        }
        return $result
    }
    throw "Unsupported canonical JSON value type: $($Value.GetType().FullName)"
}

function ConvertTo-Topic05BenchmarkCanonicalJson {
    param([AllowNull()][object]$Value)
    $raw = $Value | ConvertTo-Json -Depth 30 -Compress
    $document = [Text.Json.JsonDocument]::Parse($raw)
    $memory = [IO.MemoryStream]::new()
    $writer = [Text.Json.Utf8JsonWriter]::new($memory, [Text.Json.JsonWriterOptions]@{
        Indented = $false
        SkipValidation = $false
    })
    try {
        Write-Topic05BenchmarkCanonicalElement -Element $document.RootElement -Writer $writer
        $writer.Flush()
        return [Text.Encoding]::UTF8.GetString($memory.ToArray())
    } finally {
        $writer.Dispose()
        $memory.Dispose()
        $document.Dispose()
    }
}

function Write-Topic05BenchmarkCanonicalElement {
    param(
        [Parameter(Mandatory)][Text.Json.JsonElement]$Element,
        [Parameter(Mandatory)][Text.Json.Utf8JsonWriter]$Writer
    )
    switch ($Element.ValueKind) {
        ([Text.Json.JsonValueKind]::Object) {
            $Writer.WriteStartObject()
            $properties = @($Element.EnumerateObject())
            foreach ($property in @($properties | Sort-Object Name)) {
                $Writer.WritePropertyName($property.Name)
                Write-Topic05BenchmarkCanonicalElement -Element $property.Value -Writer $Writer
            }
            $Writer.WriteEndObject()
            break
        }
        ([Text.Json.JsonValueKind]::Array) {
            $Writer.WriteStartArray()
            foreach ($item in $Element.EnumerateArray()) {
                Write-Topic05BenchmarkCanonicalElement -Element $item -Writer $Writer
            }
            $Writer.WriteEndArray()
            break
        }
        ([Text.Json.JsonValueKind]::String) { $Writer.WriteStringValue($Element.GetString()); break }
        ([Text.Json.JsonValueKind]::Number) { $Writer.WriteRawValue($Element.GetRawText(), $true); break }
        ([Text.Json.JsonValueKind]::True) { $Writer.WriteBooleanValue($true); break }
        ([Text.Json.JsonValueKind]::False) { $Writer.WriteBooleanValue($false); break }
        ([Text.Json.JsonValueKind]::Null) { $Writer.WriteNullValue(); break }
        default { throw "Unsupported JSON value kind: $($Element.ValueKind)" }
    }
}

function Test-Topic05BenchmarkProjectRelativePath {
    param([Parameter(Mandatory)][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.IndexOf([char]0) -ge 0 -or
        [IO.Path]::IsPathRooted($Value) -or $Value.Contains('\') -or $Value.Contains('//') -or
        $Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$') { return $false }
    $segments = @($Value.Split('/'))
    if (@($segments | Where-Object { $_ -ceq '' -or $_ -ceq '.' -or $_ -ceq '..' }).Count -gt 0) {
        return $false
    }
    if ($segments[0] -in @('.git', '.omp', '.codegraph')) { return $false }
    return $true
}

function Read-Topic05BenchmarkFixtures {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LiteralPath)

    $path = [IO.Path]::GetFullPath($LiteralPath)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'benchmark fixture registry is missing' }
    try { $registry = Get-Content -Raw -LiteralPath $path -Encoding UTF8 | ConvertFrom-Json }
    catch { throw 'benchmark fixture registry JSON is invalid' }
    Assert-Topic05BenchmarkPropertySet -Value $registry -Context 'fixture registry' -Expected @(
        'schema_version', 'record_type', 'contamination_controls', 'fixtures'
    )
    if ([int]$registry.schema_version -ne 1 -or
        [string]$registry.record_type -cne 'topic05_retrieval_fixture_registry') {
        throw 'benchmark fixture registry identity is unsupported'
    }
    Assert-Topic05BenchmarkPropertySet -Value $registry.contamination_controls `
        -Context 'contamination controls' -Expected @(
            'native_forbidden_paths', 'native_forbidden_content',
            'native_forbidden_environment_prefixes', 'separate_capability_targets',
            'identical_snapshot_required'
        )
    if ((@($registry.contamination_controls.native_forbidden_paths) -join '|') -cne
            '.omp/codegraph|.omp/tools/codegraph-retrieve.js|.codegraph' -or
        (@($registry.contamination_controls.native_forbidden_environment_prefixes) -join '|') -cne
            'CODEGRAPH_' -or
        $registry.contamination_controls.separate_capability_targets -ne $true -or
        $registry.contamination_controls.identical_snapshot_required -ne $true) {
        throw 'benchmark contamination controls are incomplete or reordered'
    }

    $fixtures = @($registry.fixtures)
    if ($fixtures.Count -ne $script:Topic05BenchmarkFixtureClasses.Count) {
        throw 'benchmark fixture registry must contain exactly nine classes'
    }
    $seenIds = @{}
    $seenClasses = @{}
    foreach ($fixture in $fixtures) {
        Assert-Topic05BenchmarkPropertySet -Value $fixture -Context 'fixture' -Expected @(
            'fixture_id', 'fixture_class', 'question', 'materializer', 'required_facts',
            'allowed_citations', 'failure_oracle'
        )
        $fixtureId = [string]$fixture.fixture_id
        $fixtureClass = [string]$fixture.fixture_class
        if ($fixtureId -cnotmatch '^t05-[a-z0-9-]{3,80}$' -or $seenIds.ContainsKey($fixtureId)) {
            throw "benchmark fixture ID is invalid or duplicate: $fixtureId"
        }
        if ($fixtureClass -cnotin $script:Topic05BenchmarkFixtureClasses -or
            $seenClasses.ContainsKey($fixtureClass)) {
            throw "benchmark fixture class is invalid or duplicate: $fixtureClass"
        }
        $seenIds[$fixtureId] = $true
        $seenClasses[$fixtureClass] = $true
        if ([string]::IsNullOrWhiteSpace([string]$fixture.question) -or
            ([string]$fixture.question).Length -gt 1024) { throw "fixture question is invalid: $fixtureId" }

        Assert-Topic05BenchmarkPropertySet -Value $fixture.materializer -Context 'fixture materializer' `
            -Expected @('graph_condition', 'candidate_present', 'files')
        if ([string]$fixture.materializer.graph_condition -cnotin @(
                'healthy', 'native_fit', 'graph_gap', 'stale_partial_pending',
                'worktree_mismatch', 'source_mutation'
            )) { throw "fixture graph condition is invalid: $fixtureId" }
        if ($fixture.materializer.candidate_present -isnot [bool]) {
            throw "fixture candidate_present is not boolean: $fixtureId"
        }
        $files = @($fixture.materializer.files)
        if ($files.Count -eq 0) { throw "fixture materializer has no files: $fixtureId" }
        $filePaths = @{}
        foreach ($file in $files) {
            Assert-Topic05BenchmarkPropertySet -Value $file -Context 'fixture materializer file' `
                -Expected @('path', 'content')
            $relative = [string]$file.path
            if (-not (Test-Topic05BenchmarkProjectRelativePath $relative) -or
                $filePaths.ContainsKey($relative)) {
                throw "fixture materializer path is invalid or duplicate: $relative"
            }
            if ($null -eq $file.content) { throw "fixture materializer content is null: $relative" }
            $filePaths[$relative] = $true
        }

        $allowed = @($fixture.allowed_citations)
        if ($allowed.Count -eq 0 -or (@($allowed | Sort-Object -Unique)).Count -ne $allowed.Count) {
            throw "fixture allowed citations are missing or duplicate: $fixtureId"
        }
        foreach ($citation in $allowed) {
            $match = [regex]::Match([string]$citation, '^(?<path>[^:]+):(?<line>[1-9][0-9]*(?:-[1-9][0-9]*)?)$')
            if (-not $match.Success -or -not (Test-Topic05BenchmarkProjectRelativePath $match.Groups['path'].Value) -or
                -not $filePaths.ContainsKey($match.Groups['path'].Value)) {
                throw "fixture citation is invalid: $citation"
            }
        }
        $facts = @($fixture.required_facts)
        if ($facts.Count -eq 0) { throw "fixture oracle facts are missing: $fixtureId" }
        $factIds = @{}
        foreach ($fact in $facts) {
            Assert-Topic05BenchmarkPropertySet -Value $fact -Context 'fixture fact' `
                -Expected @('fact_id', 'statement', 'required_terms', 'citations')
            $factId = [string]$fact.fact_id
            if ($factId -cnotmatch '^[a-z0-9-]{2,80}$' -or $factIds.ContainsKey($factId) -or
                [string]::IsNullOrWhiteSpace([string]$fact.statement)) {
                throw "fixture oracle fact is invalid or duplicate: $factId"
            }
            $factIds[$factId] = $true
            $terms = @($fact.required_terms)
            if ($terms.Count -eq 0 -or (@($terms | Sort-Object -Unique)).Count -ne $terms.Count -or
                @($terms | Where-Object {
                    [string]::IsNullOrWhiteSpace([string]$_) -or ([string]$_).Length -gt 120
                }).Count -gt 0) {
                throw "fixture oracle required terms are missing or invalid: $factId"
            }
            $factCitations = @($fact.citations)
            if ($factCitations.Count -eq 0 -or
                @($factCitations | Where-Object { $allowed -cnotcontains [string]$_ }).Count -gt 0) {
                throw "fixture oracle fact citations are missing or outside the allowlist: $factId"
            }
        }
        Assert-Topic05BenchmarkPropertySet -Value $fixture.failure_oracle -Context 'failure oracle' `
            -Expected @(
                'expected_graph_outcome', 'reason', 'native_corroboration_required',
                'false_absence_prohibited', 'false_completion_prohibited'
            )
        if ([string]$fixture.failure_oracle.expected_graph_outcome -cnotin @(
                'complete', 'native_preferred', 'graph_gap', 'native_absence_required',
                'stale_partial_pending', 'index_mismatch', 'source_mutation'
            ) -or $fixture.failure_oracle.false_absence_prohibited -ne $true -or
            $fixture.failure_oracle.false_completion_prohibited -ne $true) {
            throw "fixture failure oracle is invalid: $fixtureId"
        }
    }
    [string[]]$actualClasses = @($seenClasses.Keys)
    [string[]]$expectedClasses = @($script:Topic05BenchmarkFixtureClasses)
    [Array]::Sort($actualClasses, [StringComparer]::Ordinal)
    [Array]::Sort($expectedClasses, [StringComparer]::Ordinal)
    if (($actualClasses -join '|') -cne ($expectedClasses -join '|')) {
        throw 'benchmark fixture classes are not exact'
    }
    return $registry
}

function Get-Topic05BenchmarkFixtureSnapshotHash {
    param([Parameter(Mandatory)][object]$Fixture)
    $projection = [ordered]@{
        fixture_id = [string]$Fixture.fixture_id
        files = @($Fixture.materializer.files | ForEach-Object {
            [ordered]@{ path = [string]$_.path; content = [string]$_.content }
        })
    }
    return Get-Topic05BenchmarkTextSha256 (ConvertTo-Topic05BenchmarkCanonicalJson $projection)
}

function Get-Topic05BenchmarkFixtureRegistryHash {
    param([Parameter(Mandatory)][object]$Registry)
    return Get-Topic05BenchmarkTextSha256 (ConvertTo-Topic05BenchmarkCanonicalJson $Registry)
}

function New-Topic05BenchmarkPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Registry,
        [ValidateRange(1, 100)][int]$Pairs = 3,
        [ValidateRange(1, 2147483647)][int]$Seed = 20260813,
        [Parameter(Mandatory)][string]$OutputDirectory
    )
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { throw 'benchmark output directory is empty' }
    $outputFull = [IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\', '/')
    $registryHash = Get-Topic05BenchmarkFixtureRegistryHash $Registry
    $campaignId = "topic05-$Seed-p$Pairs-$($registryHash.Substring(0, 12))"
    $groups = @()
    for ($pair = 1; $pair -le $Pairs; $pair++) {
        foreach ($fixture in @($Registry.fixtures)) {
            $units = @(
                [pscustomobject]@{
                    sort_key = Get-Topic05BenchmarkTextSha256 "$Seed|unit|$pair|$($fixture.fixture_id)|A"
                    rows = @([ordered]@{ arm = 'A_lead_native'; cache = 'absent' })
                },
                [pscustomobject]@{
                    sort_key = Get-Topic05BenchmarkTextSha256 "$Seed|unit|$pair|$($fixture.fixture_id)|B"
                    rows = @(
                        [ordered]@{ arm = 'B_lead_codegraph'; cache = 'cold' },
                        [ordered]@{ arm = 'B_lead_codegraph'; cache = 'warm' }
                    )
                },
                [pscustomobject]@{
                    sort_key = Get-Topic05BenchmarkTextSha256 "$Seed|unit|$pair|$($fixture.fixture_id)|C"
                    rows = @([ordered]@{ arm = 'C_scout_native_lead'; cache = 'absent' })
                },
                [pscustomobject]@{
                    sort_key = Get-Topic05BenchmarkTextSha256 "$Seed|unit|$pair|$($fixture.fixture_id)|D"
                    rows = @(
                        [ordered]@{ arm = 'D_scout_codegraph_lead'; cache = 'cold' },
                        [ordered]@{ arm = 'D_scout_codegraph_lead'; cache = 'warm' }
                    )
                }
            )
            $groups += [pscustomobject]@{
                sort_key = Get-Topic05BenchmarkTextSha256 "$Seed|group|$pair|$($fixture.fixture_id)"
                pair = $pair
                fixture = $fixture
                units = @($units | Sort-Object sort_key)
            }
        }
    }
    $orderedPending = @(
        foreach ($group in @($groups | Sort-Object sort_key)) {
            foreach ($unit in @($group.units)) {
                foreach ($variant in @($unit.rows)) {
                    [pscustomobject]@{
                        pair = $group.pair
                        fixture = $group.fixture
                        arm = $variant.arm
                        cache_condition = $variant.cache
                    }
                }
            }
        }
    )
    $rows = @()
    for ($index = 0; $index -lt $orderedPending.Count; $index++) {
        $row = $orderedPending[$index]
        $order = $index + 1
        $name = '{0:D4}-{1}-{2}-{3}.json' -f $order, $row.fixture.fixture_id, $row.arm, $row.cache_condition
        $rows += [pscustomobject]@{
            campaign_id = $campaignId
            fixture_id = [string]$row.fixture.fixture_id
            fixture_class = [string]$row.fixture.fixture_class
            pair = [int]$row.pair
            arm = [string]$row.arm
            cache_condition = [string]$row.cache_condition
            order = $order
            seed = $Seed
            snapshot_hash = Get-Topic05BenchmarkFixtureSnapshotHash $row.fixture
            output_path = [IO.Path]::GetFullPath((Join-Path $outputFull (Join-Path $campaignId $name)))
        }
    }
    return [pscustomobject]@{
        schema_version = 1
        record_type = 'topic05_benchmark_plan'
        campaign_id = $campaignId
        pairs = $Pairs
        seed = $Seed
        fixture_registry_hash = $registryHash
        output_directory = $outputFull
        execution_count = $rows.Count
        executions = $rows
    }
}

function Assert-Topic05BenchmarkModelPilotGate {
    param(
        [switch]$AllowModelSpend,
        [string]$Confirmation,
        [string]$LeadModel
    )
    if (-not $AllowModelSpend) { throw 'model-pilot requires -AllowModelSpend' }
    if ($Confirmation -cne 'RUN_TOPIC05_MODEL_PILOT') {
        throw 'model-pilot requires exact confirmation RUN_TOPIC05_MODEL_PILOT'
    }
    if ([string]::IsNullOrWhiteSpace($LeadModel) -or
        $LeadModel -cnotmatch '^[^/\s]+/[^:\s]+:(?:off|minimal|low|medium|high|xhigh|max)$') {
        throw "model-pilot requires a non-empty LeadModel in provider/model:effort form"
    }
    return $true
}

function Get-Topic05BenchmarkRecordCanonicalPayload {
    param([Parameter(Mandatory)][object]$Record)
    $projection = [ordered]@{}
    foreach ($property in @($Record.PSObject.Properties)) {
        if ($property.Name -ceq 'record_hash') { continue }
        $projection[$property.Name] = $property.Value
    }
    return ConvertTo-Topic05BenchmarkCanonicalJson $projection
}

function Get-Topic05BenchmarkRecordHash {
    param([Parameter(Mandatory)][object]$Record)
    return Get-Topic05BenchmarkTextSha256 (Get-Topic05BenchmarkRecordCanonicalPayload $Record)
}

function New-Topic05BenchmarkRunRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Execution,
        [Parameter(Mandatory)][object]$Fixture,
        [ValidateSet('COMPLETED', 'FAILED', 'TIMEOUT', 'ENVIRONMENT_BLOCKED', 'NOT_RUN')]
        [string]$Status = 'COMPLETED',
        [AllowNull()][string]$Reason = $null,
        [object]$Usage,
        [object]$Quality,
        [object]$Retrieval,
        [object]$Contamination,
        [object]$LeadReread,
        [object]$ActorIdentity,
        [object]$CapabilityIdentity,
        [object]$EnvironmentIdentity,
        [datetime]$StartedAt = [DateTime]::UtcNow,
        [datetime]$CompletedAt = [DateTime]::UtcNow
    )
    $isScout = [string]$Execution.arm -in @('C_scout_native_lead', 'D_scout_codegraph_lead')
    $isCodeGraph = [string]$Execution.arm -in @('B_lead_codegraph', 'D_scout_codegraph_lead')
    if ($null -eq $Usage) {
        $Usage = [ordered]@{
            core_workflow_tokens = 'not_measured'
            cheap_scout_tokens = 'not_measured'
            raw_total_tokens = 'not_measured'
            cache_read_tokens = 'not_measured'
            residual_context_tokens = 'not_measured'
            provider_reported = $false
        }
    }
    if ($null -eq $Quality) {
        $factCount = @($Fixture.required_facts).Count
        $Quality = [ordered]@{
            required_fact_count = $factCount
            required_fact_recalled = $(if ($Status -ceq 'COMPLETED') { $factCount } else { 0 })
            precision = $(if ($Status -ceq 'COMPLETED') { 1.0 } else { 0.0 })
            citation_accuracy = $(if ($Status -ceq 'COMPLETED') { 1.0 } else { 0.0 })
            false_absence = $false
            false_completion = $false
            hard_gate_pass = ($Status -ceq 'COMPLETED')
        }
    }
    if ($null -eq $Retrieval) {
        $Retrieval = [ordered]@{
            capability = $(if ($isCodeGraph) { 'codegraph' } else { 'native' })
            result_status = $(if ($Status -ceq 'COMPLETED') { 'completed' } else {
                    $Status.ToLowerInvariant()
                })
            reason = $Reason
            tool_calls = 0
            fallbacks = 0
            retries = 0
            duration_ms = 0
            index_init_ms = $(if ($Execution.cache_condition -ceq 'cold') { 0 } else { 'not_measured' })
            index_sync_ms = $(if ($isCodeGraph) { 0 } else { 'not_measured' })
            index_size_bytes = $(if ($isCodeGraph) { 0 } else { 'not_measured' })
        }
    }
    if ($null -eq $Contamination) {
        $Contamination = [ordered]@{
            native_boundary_pass = $true
            adapter_visible = $isCodeGraph
            codegraph_environment_keys = @()
            separate_target = $true
            snapshot_match = $true
        }
    }
    if ($null -eq $LeadReread) {
        $LeadReread = [ordered]@{ source_ranges = 'not_measured'; source_bytes = 'not_measured'; measured = $false }
    }
    if ($null -eq $ActorIdentity) {
        $ActorIdentity = [ordered]@{
            lead_model = 'not_invoked'
            lead_resolved = 'not_invoked'
            scout_primary = $(if ($isScout) { 'omniroute/ds/deepseek-v4-flash:xhigh' } else { $null })
            scout_fallback = $(if ($isScout) { 'omniroute/ds/deepseek-v4-pro:xhigh' } else { $null })
            scout_resolved = $(if ($isScout) { 'not_invoked' } else { $null })
            scout_fallback_used = $false
            model_invoked = $false
        }
    }
    if ($null -eq $CapabilityIdentity) {
        $CapabilityIdentity = [ordered]@{
            requested = $(if ($isCodeGraph) { 'codegraph' } else { 'native' })
            effective = [string]$Retrieval.capability
            adapter_version = $(if ($isCodeGraph) { '1.0.0' } else { $null })
        }
    }
    if ($null -eq $EnvironmentIdentity) {
        $EnvironmentIdentity = [ordered]@{
            os = [Runtime.InteropServices.RuntimeInformation]::OSDescription
            architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
            pwsh_version = $PSVersionTable.PSVersion.ToString()
            omp_version = 'not_invoked'
            pair = [int]$Execution.pair
            mode = 'deterministic'
        }
    }
    $candidateHash = if ($Fixture.materializer.candidate_present -eq $true) {
        Get-Topic05BenchmarkTextSha256 "$($Execution.snapshot_hash)|candidate|$($Fixture.fixture_id)"
    } else { $null }
    $record = [ordered]@{
        schema_version = 1
        campaign_id = [string]$Execution.campaign_id
        fixture_id = [string]$Execution.fixture_id
        fixture_class = [string]$Execution.fixture_class
        arm = [string]$Execution.arm
        order = [int]$Execution.order
        seed = [int]$Execution.seed
        snapshot_hash = [string]$Execution.snapshot_hash
        candidate_hash = $candidateHash
        cache_condition = [string]$Execution.cache_condition
        environment_identity = $EnvironmentIdentity
        actor_identity = $ActorIdentity
        capability_identity = $CapabilityIdentity
        status = $Status
        reason = $Reason
        quality = $Quality
        usage = $Usage
        lead_reread = $LeadReread
        retrieval = $Retrieval
        contamination = $Contamination
        timestamps = [ordered]@{
            started_at_unix_ms = [DateTimeOffset]::new($StartedAt.ToUniversalTime()).ToUnixTimeMilliseconds()
            completed_at_unix_ms = [DateTimeOffset]::new($CompletedAt.ToUniversalTime()).ToUnixTimeMilliseconds()
        }
    }
    $record.record_hash = Get-Topic05BenchmarkRecordHash ([pscustomobject]$record)
    return [pscustomobject]$record
}

function Assert-Topic05BenchmarkMeasuredOrUnknown {
    param([AllowNull()][object]$Value, [Parameter(Mandatory)][string]$Context)
    if ([string]$Value -ceq 'not_measured') { return }
    if ($Value -isnot [byte] -and $Value -isnot [int16] -and $Value -isnot [int32] -and
        $Value -isnot [int64]) { throw "$Context must be a nonnegative integer or not_measured" }
    if ([long]$Value -lt 0) { throw "$Context cannot be negative" }
}

function Test-Topic05BenchmarkRunRecord {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Record)

    Assert-Topic05BenchmarkPropertySet -Value $Record -Context 'run record' -Expected @(
        'schema_version', 'campaign_id', 'fixture_id', 'fixture_class', 'arm', 'order', 'seed',
        'snapshot_hash', 'candidate_hash', 'cache_condition', 'environment_identity',
        'actor_identity', 'capability_identity', 'status', 'reason', 'quality', 'usage',
        'lead_reread', 'retrieval', 'contamination', 'timestamps', 'record_hash'
    )
    if ([int]$Record.schema_version -ne 1 -or [string]::IsNullOrWhiteSpace([string]$Record.campaign_id) -or
        [string]$Record.fixture_class -cnotin $script:Topic05BenchmarkFixtureClasses -or
        [string]$Record.arm -cnotin $script:Topic05BenchmarkArms -or
        [int]$Record.order -le 0 -or [int]$Record.seed -le 0 -or
        [string]$Record.status -cnotin @('COMPLETED', 'FAILED', 'TIMEOUT', 'ENVIRONMENT_BLOCKED', 'NOT_RUN')) {
        throw 'run record identity order seed arm or status is invalid'
    }
    if ([string]$Record.reason -and ([string]$Record.reason).Length -gt 240) {
        throw 'run record reason is too long'
    }
    if ([string]$Record.status -cne 'COMPLETED' -and
        [string]::IsNullOrWhiteSpace([string]$Record.reason)) {
        throw 'non-completed run record requires a reason'
    }
    Assert-Topic05BenchmarkSha256 -Value $Record.snapshot_hash -Context 'snapshot_hash'
    Assert-Topic05BenchmarkSha256 -Value $Record.candidate_hash -Context 'candidate_hash' -AllowNull
    Assert-Topic05BenchmarkSha256 -Value $Record.record_hash -Context 'record_hash'
    if ([string]$Record.cache_condition -cnotin @('absent', 'cold', 'warm')) {
        throw 'run record cache condition is invalid'
    }
    $nativeArm = [string]$Record.arm -in @('A_lead_native', 'C_scout_native_lead')
    if (($nativeArm -and [string]$Record.cache_condition -cne 'absent') -or
        (-not $nativeArm -and [string]$Record.cache_condition -cnotin @('cold', 'warm'))) {
        throw 'run record arm and cache condition do not reconcile'
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.environment_identity -Context 'environment_identity' `
        -Expected @('os', 'architecture', 'pwsh_version', 'omp_version', 'pair', 'mode')
    if ([int]$Record.environment_identity.pair -le 0 -or
        [string]$Record.environment_identity.mode -cnotin @('deterministic', 'model-pilot') -or
        [string]::IsNullOrWhiteSpace([string]$Record.environment_identity.os) -or
        [string]::IsNullOrWhiteSpace([string]$Record.environment_identity.architecture) -or
        [string]$Record.environment_identity.pwsh_version -cnotmatch '^[0-9]+\.[0-9]+') {
        throw 'run record environment identity is invalid'
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.actor_identity -Context 'actor_identity' `
        -Expected @(
            'lead_model', 'lead_resolved', 'scout_primary', 'scout_fallback', 'scout_resolved',
            'scout_fallback_used', 'model_invoked'
        )
    $scoutArm = [string]$Record.arm -in @('C_scout_native_lead', 'D_scout_codegraph_lead')
    if ($scoutArm) {
        if ([string]$Record.actor_identity.scout_primary -cne
                'omniroute/ds/deepseek-v4-flash:xhigh' -or
            [string]$Record.actor_identity.scout_fallback -cne
                'omniroute/ds/deepseek-v4-pro:xhigh' -or
            ($null -ne $Record.actor_identity.scout_resolved -and
                [string]$Record.actor_identity.scout_resolved -cnotin @(
                    'not_invoked', 'omniroute/ds/deepseek-v4-flash',
                    'omniroute/ds/deepseek-v4-pro'
                ))) {
            throw 'run record Cheap Scout identity violates the Flash-to-Pro-only contract'
        }
    } elseif ($null -ne $Record.actor_identity.scout_primary -or
        $null -ne $Record.actor_identity.scout_fallback -or
        $null -ne $Record.actor_identity.scout_resolved -or
        $Record.actor_identity.scout_fallback_used -ne $false) {
        throw 'non-Scout arm carries a Scout identity'
    }
    if ($Record.actor_identity.model_invoked -isnot [bool] -or
        $Record.actor_identity.scout_fallback_used -isnot [bool]) {
        throw 'run record actor booleans are invalid'
    }
    if ([string]$Record.environment_identity.mode -ceq 'deterministic' -and
        ($Record.actor_identity.model_invoked -ne $false -or
            [string]$Record.actor_identity.lead_model -cne 'not_invoked' -or
            [string]$Record.actor_identity.lead_resolved -cne 'not_invoked')) {
        throw 'deterministic run record claims a model invocation'
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.capability_identity -Context 'capability_identity' `
        -Expected @('requested', 'effective', 'adapter_version')
    $expectedRequested = if ([string]$Record.arm -in @(
            'B_lead_codegraph', 'D_scout_codegraph_lead'
        )) { 'codegraph' } else { 'native' }
    if ([string]$Record.capability_identity.requested -cne $expectedRequested -or
        [string]$Record.capability_identity.effective -cnotin @('native', 'codegraph', 'mixed') -or
        [string]$Record.capability_identity.effective -cne [string]$Record.retrieval.capability -or
        ($expectedRequested -ceq 'native' -and $null -ne $Record.capability_identity.adapter_version) -or
        ($expectedRequested -ceq 'codegraph' -and
            [string]$Record.capability_identity.adapter_version -cne '1.0.0')) {
        throw 'run record capability identity is invalid or unreconciled'
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.quality -Context 'quality' -Expected @(
        'required_fact_count', 'required_fact_recalled', 'precision', 'citation_accuracy',
        'false_absence', 'false_completion', 'hard_gate_pass'
    )
    if ([int]$Record.quality.required_fact_count -lt 0 -or
        [int]$Record.quality.required_fact_recalled -lt 0 -or
        [int]$Record.quality.required_fact_recalled -gt [int]$Record.quality.required_fact_count -or
        [double]$Record.quality.precision -lt 0 -or [double]$Record.quality.precision -gt 1 -or
        [double]$Record.quality.citation_accuracy -lt 0 -or
        [double]$Record.quality.citation_accuracy -gt 1 -or
        $Record.quality.false_absence -isnot [bool] -or
        $Record.quality.false_completion -isnot [bool] -or
        $Record.quality.hard_gate_pass -isnot [bool]) {
        throw 'run record quality metrics are invalid'
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.usage -Context 'usage' -Expected @(
        'core_workflow_tokens', 'cheap_scout_tokens', 'raw_total_tokens', 'cache_read_tokens',
        'residual_context_tokens', 'provider_reported'
    )
    $usageFields = @(
        'core_workflow_tokens', 'cheap_scout_tokens', 'raw_total_tokens', 'cache_read_tokens',
        'residual_context_tokens'
    )
    $measuredCount = 0
    $usageHasScout = [string]$Record.arm -in @('C_scout_native_lead', 'D_scout_codegraph_lead')
    foreach ($name in $usageFields) {
        Assert-Topic05BenchmarkMeasuredOrUnknown -Value $Record.usage.$name -Context "usage.$name"
        $structuralScoutZero = $name -ceq 'cheap_scout_tokens' -and -not $usageHasScout -and
            [string]$Record.usage.$name -cne 'not_measured' -and [long]$Record.usage.$name -eq 0
        if ([string]$Record.usage.$name -cne 'not_measured' -and -not $structuralScoutZero) {
            $measuredCount++
        }
    }
    if ($measuredCount -gt 0 -and $Record.usage.provider_reported -ne $true) {
        throw 'token claims require provider-reported usage'
    }
    if ([string]$Record.usage.raw_total_tokens -cne 'not_measured') {
        if ([string]$Record.usage.core_workflow_tokens -ceq 'not_measured' -or
            [string]$Record.usage.cheap_scout_tokens -ceq 'not_measured' -or
            [long]$Record.usage.raw_total_tokens -ne
                ([long]$Record.usage.core_workflow_tokens + [long]$Record.usage.cheap_scout_tokens)) {
            throw 'raw_total_tokens does not reconcile the two token ledgers'
        }
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.lead_reread -Context 'lead_reread' `
        -Expected @('source_ranges', 'source_bytes', 'measured')
    if ($Record.lead_reread.measured -isnot [bool]) { throw 'lead_reread measured flag is invalid' }
    if ($Record.lead_reread.measured -eq $true) {
        foreach ($name in @('source_ranges', 'source_bytes')) {
            Assert-Topic05BenchmarkMeasuredOrUnknown -Value $Record.lead_reread.$name `
                -Context "lead_reread.$name"
            if ([string]$Record.lead_reread.$name -ceq 'not_measured') {
                throw 'measured lead_reread cannot contain not_measured'
            }
        }
    } elseif ([string]$Record.lead_reread.source_ranges -cne 'not_measured' -or
        [string]$Record.lead_reread.source_bytes -cne 'not_measured') {
        throw 'unmeasured lead_reread contains estimated values'
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.retrieval -Context 'retrieval' -Expected @(
        'capability', 'result_status', 'reason', 'tool_calls', 'fallbacks', 'retries',
        'duration_ms', 'index_init_ms', 'index_sync_ms', 'index_size_bytes'
    )
    if ([string]$Record.retrieval.capability -cnotin @('native', 'codegraph', 'mixed') -or
        [string]$Record.retrieval.result_status -cnotin @(
            'completed', 'fallback_native', 'failed', 'timeout', 'environment_blocked', 'not_run'
        )) { throw 'run record retrieval status or capability is invalid' }
    foreach ($name in @('tool_calls', 'fallbacks', 'retries', 'duration_ms', 'index_init_ms',
            'index_sync_ms', 'index_size_bytes')) {
        Assert-Topic05BenchmarkMeasuredOrUnknown -Value $Record.retrieval.$name `
            -Context "retrieval.$name"
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.contamination -Context 'contamination' -Expected @(
        'native_boundary_pass', 'adapter_visible', 'codegraph_environment_keys',
        'separate_target', 'snapshot_match'
    )
    foreach ($name in @('native_boundary_pass', 'adapter_visible', 'separate_target', 'snapshot_match')) {
        if ($Record.contamination.$name -isnot [bool]) {
            throw "run record contamination.$name is not boolean"
        }
    }
    Assert-Topic05BenchmarkPropertySet -Value $Record.timestamps -Context 'timestamps' `
        -Expected @('started_at_unix_ms', 'completed_at_unix_ms')
    $started = [long]$Record.timestamps.started_at_unix_ms
    $completed = [long]$Record.timestamps.completed_at_unix_ms
    if ($started -le 0 -or $completed -lt $started) { throw 'run record timestamps are invalid or reversed' }
    if ((Get-Topic05BenchmarkRecordHash $Record) -cne [string]$Record.record_hash) {
        throw 'run record hash mismatch'
    }
    return $true
}

function Write-Topic05BenchmarkRunRecord {
    param([Parameter(Mandatory)][object]$Record, [Parameter(Mandatory)][string]$LiteralPath)
    [void](Test-Topic05BenchmarkRunRecord $Record)
    $path = [IO.Path]::GetFullPath($LiteralPath)
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    $json = (ConvertTo-Topic05BenchmarkCanonicalJson $Record) + "`n"
    $stream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
        $stream.Write($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }
}

function Assert-Topic05BenchmarkOutputPlan {
    param([Parameter(Mandatory)][object]$Plan)
    $campaignRoot = [IO.Path]::GetFullPath((Join-Path $Plan.output_directory $Plan.campaign_id)).TrimEnd('\', '/')
    $comparison = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [Runtime.InteropServices.OSPlatform]::Windows
        )) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $seen = [Collections.Generic.HashSet[string]]::new(
        $(if ($comparison -eq [StringComparison]::OrdinalIgnoreCase) {
            [StringComparer]::OrdinalIgnoreCase
        } else { [StringComparer]::Ordinal })
    )
    foreach ($execution in @($Plan.executions)) {
        $path = [IO.Path]::GetFullPath([string]$execution.output_path)
        if (-not $path.StartsWith($campaignRoot + [IO.Path]::DirectorySeparatorChar, $comparison) -or
            [IO.Path]::GetExtension($path) -cne '.json' -or -not $seen.Add($path)) {
            throw 'benchmark output plan contains an unsafe or duplicate path'
        }
        if (Test-Path -LiteralPath $path) {
            throw "benchmark immutable output already exists: $path"
        }
    }
    return $true
}

function New-Topic05BenchmarkMaterializedFixture {
    param(
        [Parameter(Mandatory)][object]$Fixture,
        [Parameter(Mandatory)][string]$LiteralPath,
        [ValidateSet('native', 'codegraph')][string]$Capability
    )
    $root = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    if (Test-Path -LiteralPath $root) { throw 'benchmark materialization root must be absent' }
    [void](New-Item -ItemType Directory -Path $root)
    foreach ($file in @($Fixture.materializer.files)) {
        if (-not (Test-Topic05BenchmarkProjectRelativePath ([string]$file.path))) {
            throw 'benchmark materializer path became unsafe'
        }
        $path = [IO.Path]::GetFullPath((Join-Path $root (([string]$file.path) -replace '/', '\')))
        if (-not $path.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'benchmark materializer path escaped root'
        }
        $parent = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            [void](New-Item -ItemType Directory -Path $parent -Force)
        }
        [IO.File]::WriteAllText($path, [string]$file.content, [Text.UTF8Encoding]::new($false))
    }
    $gitCommand = @(Get-Command git -CommandType Application -ErrorAction SilentlyContinue)[0]
    if ($null -eq $gitCommand) { throw 'benchmark fixture materialization requires Git' }
    foreach ($arguments in @(
            @('-C', $root, 'init', '--quiet'),
            @('-C', $root, 'config', 'user.name', 'Topic 05 Benchmark'),
            @('-C', $root, 'config', 'user.email', 'topic05-benchmark.invalid'),
            @('-C', $root, 'config', 'core.autocrlf', 'false'),
            @('-C', $root, 'add', '--all'),
            @('-C', $root, 'commit', '--quiet', '-m', 'frozen benchmark fixture')
        )) {
        $gitOutput = @(& $gitCommand.Source @arguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "benchmark fixture Git materialization failed: $($gitOutput -join ' ')"
        }
    }
    if ($Capability -ceq 'codegraph') {
        $graphRoot = Join-Path $root '.omp\codegraph'
        $toolRoot = Join-Path $root '.omp\tools'
        [void](New-Item -ItemType Directory -Path $graphRoot -Force)
        [void](New-Item -ItemType Directory -Path $toolRoot -Force)
        [IO.File]::WriteAllText(
            (Join-Path $graphRoot 'benchmark-capability.json'),
            '{"component":"codegraph","mode":"deterministic-probe"}',
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $toolRoot 'codegraph-retrieve.js'),
            '// deterministic benchmark capability marker',
            [Text.UTF8Encoding]::new($false)
        )
    }
    return $root
}

function Initialize-Topic05BenchmarkCodeGraphTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectDirectory,
        [string]$ArtifactPath,
        [switch]$AllowDownload
    )
    if ($ArtifactPath -and $AllowDownload) {
        throw 'benchmark CodeGraph artifact and download permission are mutually exclusive'
    }
    $projectFull = [IO.Path]::GetFullPath($ProjectDirectory).TrimEnd('\', '/')
    $installer = Join-Path $script:Topic05BenchmarkRepositoryRoot 'scripts\install-template.ps1'
    if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
        throw 'benchmark CodeGraph installer is unavailable'
    }
    $pwshPath = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $arguments = @(
        '-NoProfile', '-File', $installer, '-Target', 'project', '-ProjectDir', $projectFull,
        '-Components', 'state,codegraph', '-DryRun:$false', '-PwshPath', $pwshPath
    )
    if ($ArtifactPath) { $arguments += @('-CodeGraphArtifactPath', $ArtifactPath) }
    if ($AllowDownload) { $arguments += '-AllowCodeGraphDownload' }
    $output = @(& $pwshPath @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "benchmark CodeGraph target preparation failed: $($output -join [Environment]::NewLine)"
    }
    $targetOmp = Join-Path $projectFull '.omp'
    foreach ($relative in @(
            'state\manifest.json', 'codegraph\runtime.json', 'codegraph\install-record.json',
            'tools\codegraph-retrieve.js'
        )) {
        if (-not (Test-Path -LiteralPath (Join-Path $targetOmp $relative) -PathType Leaf)) {
            throw "benchmark CodeGraph target is incomplete: $relative"
        }
    }
    return $targetOmp
}

function Test-Topic05BenchmarkNativeBoundary {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][object]$Controls,
        [hashtable]$Environment = @{}
    )
    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
    foreach ($relative in @($Controls.native_forbidden_paths)) {
        $candidate = Join-Path $root (([string]$relative) -replace '/', '\')
        if (Test-Path -LiteralPath $candidate) { return $false }
    }
    foreach ($key in @($Environment.Keys)) {
        foreach ($prefix in @($Controls.native_forbidden_environment_prefixes)) {
            if ([string]$key -like "$prefix*") { return $false }
        }
    }
    foreach ($file in Get-ChildItem -LiteralPath $root -File -Recurse -Force) {
        $relative = [IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')
        if ($relative.StartsWith('.git/', [StringComparison]::Ordinal) -or
            $relative -ceq '.git') { continue }
        $text = Get-Content -Raw -LiteralPath $file.FullName -Encoding UTF8
        foreach ($needle in @($Controls.native_forbidden_content)) {
            if ($text.IndexOf([string]$needle, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                return $false
            }
        }
    }
    return $true
}

function Invoke-Topic05DeterministicBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Registry,
        [Parameter(Mandatory)][object]$Plan
    )
    [void](Assert-Topic05BenchmarkOutputPlan $Plan)
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
    $tempRoot = Join-Path $tempBase ('omp-topic05-benchmark-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $tempRoot)
    $records = [Collections.Generic.List[object]]::new()
    $preparedCodeGraphTargets = @{}
    try {
        foreach ($execution in @($Plan.executions)) {
            $fixtures = @($Registry.fixtures | Where-Object fixture_id -CEQ $execution.fixture_id)
            if ($fixtures.Count -ne 1) { throw 'benchmark execution fixture is not unique' }
            $fixture = $fixtures[0]
            $capability = if ($execution.arm -in @('B_lead_codegraph', 'D_scout_codegraph_lead')) {
                'codegraph'
            } else { 'native' }
            if ($capability -ceq 'codegraph') {
                $targetKey = "$($execution.pair)|$($execution.fixture_id)|$($execution.arm)"
                if ($execution.cache_condition -ceq 'cold') {
                    if ($preparedCodeGraphTargets.ContainsKey($targetKey)) {
                        throw 'deterministic CodeGraph cold target was already prepared'
                    }
                    $workRoot = Join-Path $tempRoot ('run-' + $execution.order)
                    [void](New-Topic05BenchmarkMaterializedFixture -Fixture $fixture `
                        -LiteralPath $workRoot -Capability $capability)
                    $preparedCodeGraphTargets[$targetKey] = $workRoot
                } else {
                    if (-not $preparedCodeGraphTargets.ContainsKey($targetKey)) {
                        throw 'deterministic CodeGraph warm run lacks the immediately preceding cold target'
                    }
                    $workRoot = [string]$preparedCodeGraphTargets[$targetKey]
                }
            } else {
                $workRoot = Join-Path $tempRoot ('run-' + $execution.order)
                [void](New-Topic05BenchmarkMaterializedFixture -Fixture $fixture `
                    -LiteralPath $workRoot -Capability $capability)
            }
            $actualProjection = [ordered]@{
                fixture_id = [string]$fixture.fixture_id
                files = @($fixture.materializer.files | ForEach-Object {
                    $path = Join-Path $workRoot (([string]$_.path) -replace '/', '\')
                    [ordered]@{ path = [string]$_.path; content = [IO.File]::ReadAllText($path) }
                })
            }
            $actualSnapshot = Get-Topic05BenchmarkTextSha256 (
                ConvertTo-Topic05BenchmarkCanonicalJson $actualProjection
            )
            $snapshotMatch = $actualSnapshot -ceq [string]$execution.snapshot_hash
            $nativeBoundary = if ($capability -ceq 'native') {
                Test-Topic05BenchmarkNativeBoundary -RepositoryRoot $workRoot `
                    -Controls $Registry.contamination_controls -Environment @{}
            } else { $true }
            $oracleOutcome = [string]$fixture.failure_oracle.expected_graph_outcome
            $fallback = $capability -ceq 'codegraph' -and $oracleOutcome -cne 'complete'
            $status = 'COMPLETED'
            $reason = if ($fallback) { [string]$fixture.failure_oracle.reason } else { $null }
            $retrieval = [ordered]@{
                capability = $(if ($fallback) { 'native' } else { $capability })
                result_status = $(if ($fallback) { 'fallback_native' } else { 'completed' })
                reason = $reason
                tool_calls = 0
                fallbacks = $(if ($fallback) { 1 } else { 0 })
                retries = 0
                duration_ms = 0
                index_init_ms = $(if ($execution.cache_condition -ceq 'cold') { 0 } else { 'not_measured' })
                index_sync_ms = $(if ($capability -ceq 'codegraph') { 0 } else { 'not_measured' })
                index_size_bytes = $(if ($capability -ceq 'codegraph') { 0 } else { 'not_measured' })
            }
            $contamination = [ordered]@{
                native_boundary_pass = $nativeBoundary
                adapter_visible = ($capability -ceq 'codegraph')
                codegraph_environment_keys = @()
                separate_target = $true
                snapshot_match = $snapshotMatch
            }
            $record = New-Topic05BenchmarkRunRecord -Execution $execution -Fixture $fixture `
                -Status $status -Reason $reason -Retrieval $retrieval -Contamination $contamination
            Write-Topic05BenchmarkRunRecord -Record $record -LiteralPath $execution.output_path
            [void]$records.Add($record)
        }
        return $records.ToArray()
    } finally {
        $resolved = [IO.Path]::GetFullPath($tempRoot).TrimEnd('\', '/')
        if ([IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/') -cne $tempBase -or
            -not [IO.Path]::GetFileName($resolved).StartsWith(
                'omp-topic05-benchmark-',
                [StringComparison]::Ordinal
            )) {
            throw "Refusing unsafe benchmark cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}

function ConvertFrom-Topic05BenchmarkEventStream {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Events)
    $usageEvents = @()
    $terminals = @()
    foreach ($event in @($Events)) {
        if ([string]$event.type -ceq 'usage') {
            Assert-Topic05BenchmarkPropertySet -Value $event -Context 'usage event' -Expected @(
                'type', 'scope', 'input_tokens', 'output_tokens', 'cache_read_tokens',
                'residual_context_tokens'
            )
            if ([string]$event.scope -cnotin @('core', 'scout')) { throw 'usage event scope is invalid' }
            foreach ($field in @('input_tokens', 'output_tokens', 'cache_read_tokens')) {
                Assert-Topic05BenchmarkMeasuredOrUnknown -Value $event.$field -Context "usage event $field"
                if ([string]$event.$field -ceq 'not_measured') { throw 'provider usage counts cannot be estimated' }
            }
            Assert-Topic05BenchmarkMeasuredOrUnknown -Value $event.residual_context_tokens `
                -Context 'usage event residual_context_tokens'
            $usageEvents += $event
        } elseif ([string]$event.type -ceq 'terminal') {
            Assert-Topic05BenchmarkPropertySet -Value $event -Context 'terminal event' -Expected @(
                'type', 'status', 'reason', 'resolved_model', 'is_fallback'
            )
            if ([string]$event.status -cnotin @('completed', 'failed', 'unavailable', 'timeout')) {
                throw 'terminal event status is invalid'
            }
            $terminals += $event
        } else { throw "unknown benchmark event type: $($event.type)" }
    }
    if ($terminals.Count -ne 1) { throw 'event stream requires exactly one terminal event' }
    $terminal = $terminals[0]
    if ($usageEvents.Count -eq 0) {
        $usage = [ordered]@{
            core_workflow_tokens = 'not_measured'; cheap_scout_tokens = 'not_measured';
            raw_total_tokens = 'not_measured'; cache_read_tokens = 'not_measured';
            residual_context_tokens = 'not_measured'; provider_reported = $false
        }
    } else {
        $core = 0L
        $scout = 0L
        $cache = 0L
        $residual = 0L
        $residualMeasured = $true
        foreach ($event in $usageEvents) {
            $tokens = [long]$event.input_tokens + [long]$event.output_tokens
            if ([string]$event.scope -ceq 'core') { $core += $tokens } else { $scout += $tokens }
            $cache += [long]$event.cache_read_tokens
            if ([string]$event.residual_context_tokens -ceq 'not_measured') { $residualMeasured = $false }
            else { $residual += [long]$event.residual_context_tokens }
        }
        $usage = [ordered]@{
            core_workflow_tokens = $core
            cheap_scout_tokens = $scout
            raw_total_tokens = $core + $scout
            cache_read_tokens = $cache
            residual_context_tokens = $(if ($residualMeasured) { $residual } else { 'not_measured' })
            provider_reported = $true
        }
    }
    $status = switch ([string]$terminal.status) {
        'completed' { 'COMPLETED' }
        'timeout' { 'TIMEOUT' }
        'unavailable' { 'ENVIRONMENT_BLOCKED' }
        default { 'FAILED' }
    }
    return [pscustomobject]@{
        status = $status
        reason = $terminal.reason
        resolved_model = $terminal.resolved_model
        is_fallback = [bool]$terminal.is_fallback
        usage = [pscustomobject]$usage
    }
}

function Split-Topic05BenchmarkModelIdentity {
    param([Parameter(Mandatory)][string]$Identity)
    $match = [regex]::Match(
        $Identity,
        '^(?<model>[^/\s]+/[^:\s]+):(?<effort>off|minimal|low|medium|high|xhigh|max)$'
    )
    if (-not $match.Success) { throw 'model identity must use provider/model:effort' }
    return [pscustomobject]@{
        selector = $match.Groups['model'].Value
        effort = $match.Groups['effort'].Value
    }
}

function Get-Topic05BenchmarkAssistantText {
    param([Parameter(Mandatory)][object]$Message)
    return (@(
        foreach ($part in @($Message.content)) {
            if ([string]$part.type -ceq 'text' -and $null -ne $part.text) { [string]$part.text }
        }
    ) -join "`n").Trim()
}

function ConvertFrom-Topic05BenchmarkOmpJsonLines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Stdout,
        [Parameter(Mandatory)][string]$RequestedModel,
        [ValidateSet('core', 'scout')][string]$Scope,
        [int]$ExitCode = 0,
        [switch]$TimedOut
    )
    if ($TimedOut) {
        return ConvertFrom-Topic05BenchmarkEventStream -Events @(
            [pscustomobject]@{
                type = 'terminal'; status = 'timeout'; reason = 'deadline';
                resolved_model = $null; is_fallback = $false
            }
        )
    }
    $assistantMessages = @()
    $errorSeen = $false
    $toolExecutions = [ordered]@{}
    foreach ($line in @($Stdout -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try { $event = $line | ConvertFrom-Json } catch { continue }
        if ([string]$event.type -ceq 'message_end' -and
            [string]$event.message.role -ceq 'assistant') {
            $assistantMessages += $event.message
        } elseif ([string]$event.type -ceq 'tool_execution_end') {
            $toolId = [string]$event.toolCallId
            if (-not [string]::IsNullOrWhiteSpace($toolId) -and
                -not $toolExecutions.Contains($toolId)) {
                $toolExecutions[$toolId] = $event
            }
        } elseif ([string]$event.type -in @('error', 'agent_error')) { $errorSeen = $true }
    }
    $usageInput = 0L
    $usageOutput = 0L
    $usageCache = 0L
    $usageSeen = $false
    $models = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $finalText = ''
    foreach ($message in $assistantMessages) {
        if ($message.provider -and $message.model) {
            [void]$models.Add("$($message.provider)/$($message.model)")
        }
        if ($null -ne $message.usage -and $null -ne $message.usage.input -and
            $null -ne $message.usage.output -and $null -ne $message.usage.cacheRead) {
            $usageSeen = $true
            $usageInput += [long]$message.usage.input
            $usageOutput += [long]$message.usage.output
            $usageCache += [long]$message.usage.cacheRead
        }
        $text = Get-Topic05BenchmarkAssistantText $message
        if ($text) { $finalText = $text }
    }
    $resolvedModel = if ($models.Count -eq 1) { @($models)[0] } else { $null }
    $fallback = $null -ne $resolvedModel -and $resolvedModel -cne $RequestedModel
    $terminalStatus = if ($ExitCode -eq 0 -and -not $errorSeen -and $assistantMessages.Count -gt 0) {
        'completed'
    } elseif ($Stdout -match '(?i)unavailable|not authenticated|credential|model.*not found') {
        'unavailable'
    } else { 'failed' }
    $events = @()
    if ($usageSeen) {
        $events += [pscustomobject]@{
            type = 'usage'
            scope = $Scope
            input_tokens = $usageInput
            output_tokens = $usageOutput
            cache_read_tokens = $usageCache
            residual_context_tokens = 'not_measured'
        }
    }
    $events += [pscustomobject]@{
        type = 'terminal'
        status = $terminalStatus
        reason = $(if ($fallback) { 'resolved_model_mismatch' } elseif ($terminalStatus -ne 'completed') {
                'provider_or_runtime_failure'
            } else { $null })
        resolved_model = $resolvedModel
        is_fallback = $fallback
    }
    $projection = ConvertFrom-Topic05BenchmarkEventStream -Events $events
    $toolNames = @($toolExecutions.Values | ForEach-Object { [string]$_.toolName })
    $codeGraphEvents = @($toolExecutions.Values | Where-Object {
        [string]$_.toolName -ceq 'codegraph_retrieve'
    })
    $codeGraphReasons = @(
        foreach ($toolEvent in $codeGraphEvents) {
            if ($null -ne $toolEvent.result.details -and $toolEvent.result.details.ok -ne $true) {
                [string]$toolEvent.result.details.reason_code
            }
        }
    )
    $readRanges = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $readBytes = 0L
    foreach ($toolEvent in @($toolExecutions.Values | Where-Object {
            [string]$_.toolName -ceq 'read'
        })) {
        $pathProperty = $toolEvent.args.PSObject.Properties['path']
        $fileProperty = $toolEvent.args.PSObject.Properties['file']
        $offsetProperty = $toolEvent.args.PSObject.Properties['offset']
        $limitProperty = $toolEvent.args.PSObject.Properties['limit']
        $path = if ($null -ne $pathProperty -and $pathProperty.Value) {
            [string]$pathProperty.Value
        } elseif ($null -ne $fileProperty -and $fileProperty.Value) {
            [string]$fileProperty.Value
        } else { '<unknown>' }
        $offset = if ($null -ne $offsetProperty -and $null -ne $offsetProperty.Value) {
            [string]$offsetProperty.Value
        } else { 'start' }
        $limit = if ($null -ne $limitProperty -and $null -ne $limitProperty.Value) {
            [string]$limitProperty.Value
        } else { 'default' }
        [void]$readRanges.Add("$path@$offset+$limit")
        foreach ($content in @($toolEvent.result.content)) {
            if ([string]$content.type -ceq 'text') {
                $readBytes += [Text.Encoding]::UTF8.GetByteCount([string]$content.text)
            }
        }
    }
    $projection | Add-Member -NotePropertyName tool_calls -NotePropertyValue $toolExecutions.Count
    $projection | Add-Member -NotePropertyName tool_names -NotePropertyValue $toolNames
    $projection | Add-Member -NotePropertyName codegraph_calls -NotePropertyValue $codeGraphEvents.Count
    $projection | Add-Member -NotePropertyName codegraph_completed -NotePropertyValue (
        @($codeGraphEvents | Where-Object { $_.result.details.ok -eq $true }).Count
    )
    $projection | Add-Member -NotePropertyName codegraph_fallback_reasons `
        -NotePropertyValue $codeGraphReasons
    $projection | Add-Member -NotePropertyName lead_reread -NotePropertyValue ([pscustomobject]@{
        source_ranges = $readRanges.Count
        source_bytes = $readBytes
        measured = $true
    })
    $projection | Add-Member -NotePropertyName final_text -NotePropertyValue $finalText
    return $projection
}

function Invoke-Topic05BenchmarkOmpProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OmpPath,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$ModelIdentity,
        [Parameter(Mandatory)][string]$Prompt,
        [ValidateSet('native', 'codegraph')][string]$Capability,
        [ValidateSet('core', 'scout')][string]$Scope,
        [switch]$AllowModelSpend,
        [Parameter(Mandatory)][string]$Confirmation,
        [Parameter(Mandatory)][string]$LeadModel,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 660
    )
    [void](Assert-Topic05BenchmarkModelPilotGate -AllowModelSpend:$AllowModelSpend `
        -Confirmation $Confirmation -LeadModel $LeadModel)
    $ompFull = [IO.Path]::GetFullPath($OmpPath)
    $workFull = [IO.Path]::GetFullPath($WorkingDirectory).TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $ompFull -PathType Leaf) -or
        -not (Test-Path -LiteralPath $workFull -PathType Container)) {
        throw 'model-pilot OMP path or working directory is unavailable'
    }
    $model = Split-Topic05BenchmarkModelIdentity $ModelIdentity
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $ompFull
    $start.WorkingDirectory = $workFull
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in @(
            '-p', '--mode=json', '--no-session', '--cwd', $workFull, '--model', $model.selector,
            '--thinking', $model.effort, '--max-time', "${TimeoutSeconds}s", '--no-skills',
            '--no-rules', '--no-lsp', '--no-pty', '--no-title', '--no-extensions',
            '--auto-approve', '--approval-mode=yolo',
            '--tools', $(if ($Capability -ceq 'codegraph') {
                    'read,grep,glob,codegraph_retrieve'
                } else { 'read,grep,glob' }),
            $Prompt
        )) { [void]$start.ArgumentList.Add([string]$argument) }
    if ($Capability -ceq 'native') {
        foreach ($key in @($start.Environment.Keys)) {
            if ($key.StartsWith('CODEGRAPH_', [StringComparison]::OrdinalIgnoreCase)) {
                [void]$start.Environment.Remove($key)
            }
        }
    } else {
        $explicitTool = Join-Path $workFull '.omp\tools\codegraph-retrieve.js'
        if (-not (Test-Path -LiteralPath $explicitTool -PathType Leaf)) {
            throw 'model-pilot CodeGraph tool is unavailable in the prepared target'
        }
        [void]$start.ArgumentList.Insert($start.ArgumentList.Count - 1, '-e')
        [void]$start.ArgumentList.Insert($start.ArgumentList.Count - 1, $explicitTool)
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $script:Topic05BenchmarkModelProcessStarts++
    try {
        if (-not $process.Start()) { throw 'OMP model process could not start' }
        $process.StandardInput.Close()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            try { $process.Kill($true) } catch { try { $process.Kill() } catch {} }
            [void]$process.WaitForExit(5000)
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        [void]$stderrTask.GetAwaiter().GetResult()
        if ([Text.Encoding]::UTF8.GetByteCount($stdout) -gt 20MB) {
            throw 'OMP model event stream exceeded the sanitized capture limit'
        }
        return ConvertFrom-Topic05BenchmarkOmpJsonLines -Stdout $stdout `
            -RequestedModel $model.selector -Scope $Scope -ExitCode $(if ($timedOut) { -1 } else {
                $process.ExitCode
            }) -TimedOut:$timedOut
    } finally { $process.Dispose() }
}

function Measure-Topic05BenchmarkAnswer {
    param([AllowNull()][string]$Text, [Parameter(Mandatory)][object]$Fixture)
    $expectedIds = @($Fixture.required_facts | ForEach-Object { [string]$_.fact_id })
    $allowed = @($Fixture.allowed_citations)
    $packet = $null
    $validFacts = @()
    $returnedCount = 0
    $validCitationCount = 0
    $citationCount = 0
    $completedClaim = $false
    $absenceClaims = @()
    try {
        $packet = $Text.Trim() | ConvertFrom-Json
        Assert-Topic05BenchmarkPropertySet -Value $packet -Context 'benchmark answer' `
            -Expected @('facts', 'completed', 'absence_claims')
        $completedClaim = $packet.completed -eq $true
        $absenceClaims = @($packet.absence_claims)
        $returned = @($packet.facts)
        $returnedCount = $returned.Count
        foreach ($fact in $returned) {
            Assert-Topic05BenchmarkPropertySet -Value $fact -Context 'benchmark answer fact' `
                -Expected @('fact_id', 'statement', 'citations')
            $factCitations = @($fact.citations)
            $citationCount += $factCitations.Count
            $validCitationCount += @($factCitations | Where-Object { $allowed -ccontains [string]$_ }).Count
            $expectedRows = @($Fixture.required_facts | Where-Object fact_id -CEQ ([string]$fact.fact_id))
            $requiredTermsPresent = $expectedRows.Count -eq 1 -and
                @($expectedRows[0].required_terms | Where-Object {
                    ([string]$fact.statement).IndexOf([string]$_, [StringComparison]::Ordinal) -lt 0
                }).Count -eq 0
            if ([string]$fact.fact_id -cin $expectedIds -and $requiredTermsPresent -and
                @($factCitations | Where-Object { $allowed -cnotcontains [string]$_ }).Count -eq 0 -and
                $factCitations.Count -gt 0) { $validFacts += [string]$fact.fact_id }
        }
    } catch { $packet = $null }
    $recalled = @($validFacts | Sort-Object -Unique).Count
    $precision = if ($returnedCount -eq 0) { 0.0 } else { [double]$recalled / $returnedCount }
    $citationAccuracy = if ($citationCount -eq 0) { 0.0 } else {
        [double]$validCitationCount / $citationCount
    }
    $falseAbsence = $absenceClaims.Count -gt 0 -and
        [string]$Fixture.fixture_class -cne 'deterministic_absence_claim'
    $falseCompletion = $completedClaim -and (
        $recalled -ne $expectedIds.Count -or $citationAccuracy -lt 1.0 -or $falseAbsence
    )
    $quality = [ordered]@{
        required_fact_count = $expectedIds.Count
        required_fact_recalled = $recalled
        precision = $precision
        citation_accuracy = $citationAccuracy
        false_absence = $falseAbsence
        false_completion = $falseCompletion
        hard_gate_pass = ($null -ne $packet -and $recalled -eq $expectedIds.Count -and
            $citationAccuracy -eq 1.0 -and -not $falseAbsence -and -not $falseCompletion)
    }
    $sanitized = if ($null -eq $packet) { $null } else {
        [ordered]@{
            facts = @($packet.facts | ForEach-Object {
                [ordered]@{
                    fact_id = [string]$_.fact_id
                    statement = ([string]$_.statement).Substring(0, [Math]::Min(480, ([string]$_.statement).Length))
                    citations = @($_.citations | Select-Object -First 12)
                }
            } | Select-Object -First 12)
            completed = [bool]$packet.completed
            absence_claims = @($packet.absence_claims | Select-Object -First 8)
        }
    }
    return [pscustomobject]@{ quality = $quality; packet = $sanitized }
}

function Merge-Topic05BenchmarkUsage {
    param([AllowNull()][object]$Core, [AllowNull()][object]$Scout)
    $coreTokens = if ($null -ne $Core -and [string]$Core.core_workflow_tokens -cne 'not_measured') {
        [long]$Core.core_workflow_tokens
    } else { 'not_measured' }
    $scoutTokens = if ($null -eq $Scout) { 0L } elseif (
        [string]$Scout.cheap_scout_tokens -cne 'not_measured'
    ) { [long]$Scout.cheap_scout_tokens } else { 'not_measured' }
    $cacheValues = @()
    foreach ($usage in @($Core, $Scout)) {
        if ($null -eq $usage) { continue }
        if ([string]$usage.cache_read_tokens -ceq 'not_measured') { $cacheValues = $null; break }
        $cacheValues += [long]$usage.cache_read_tokens
    }
    $raw = if ([string]$coreTokens -ne 'not_measured' -and
        [string]$scoutTokens -ne 'not_measured') { [long]$coreTokens + [long]$scoutTokens } else {
        'not_measured'
    }
    $sourceUsages = @(@($Core, $Scout) | Where-Object { $null -ne $_ })
    return [ordered]@{
        core_workflow_tokens = $coreTokens
        cheap_scout_tokens = $scoutTokens
        raw_total_tokens = $raw
        cache_read_tokens = $(if ($null -eq $cacheValues) { 'not_measured' } else {
                [long](($cacheValues | Measure-Object -Sum).Sum)
            })
        residual_context_tokens = 'not_measured'
        provider_reported = ($sourceUsages.Count -gt 0 -and
            @($sourceUsages | Where-Object { $_.provider_reported -ne $true }).Count -eq 0)
    }
}

function Merge-Topic05BenchmarkScoutAttemptUsage {
    param([AllowNull()][object[]]$Attempts)
    $attempts = @($Attempts | Where-Object { $null -ne $_ })
    if ($attempts.Count -eq 0) { return $null }
    $scout = 0L
    $cache = 0L
    $scoutMeasured = $true
    $cacheMeasured = $true
    $providerReported = $true
    foreach ($usage in $attempts) {
        if ([string]$usage.cheap_scout_tokens -ceq 'not_measured') { $scoutMeasured = $false }
        else { $scout += [long]$usage.cheap_scout_tokens }
        if ([string]$usage.cache_read_tokens -ceq 'not_measured') { $cacheMeasured = $false }
        else { $cache += [long]$usage.cache_read_tokens }
        if ($usage.provider_reported -ne $true) { $providerReported = $false }
    }
    return [pscustomobject]@{
        core_workflow_tokens = 'not_measured'
        cheap_scout_tokens = $(if ($scoutMeasured) { $scout } else { 'not_measured' })
        raw_total_tokens = 'not_measured'
        cache_read_tokens = $(if ($cacheMeasured) { $cache } else { 'not_measured' })
        residual_context_tokens = 'not_measured'
        provider_reported = $providerReported
    }
}

function New-Topic05BenchmarkPrompt {
    param(
        [Parameter(Mandatory)][object]$Fixture,
        [ValidateSet('lead', 'scout', 'lead-consume')][string]$Stage,
        [ValidateSet('native', 'codegraph')][string]$Capability,
        [AllowNull()][object]$ScoutPacket
    )
    $capabilityInstruction = if ($Capability -ceq 'codegraph') {
        'Use codegraph_retrieve for the bounded question, then open decisive current source. Treat graph output as a hypothesis and use native evidence for absence.'
    } else { 'Use only native read, grep, and glob retrieval.' }
    $packetText = if ($null -eq $ScoutPacket) { '' } else {
        "`nScout packet (advisory only): $(ConvertTo-Topic05BenchmarkCanonicalJson $ScoutPacket)"
    }
    $factIds = @($Fixture.required_facts | ForEach-Object { [string]$_.fact_id }) -join ', '
    return @"
This is a read-only retrieval benchmark. Do not edit, write, run commands, spawn agents, or claim verification.
$capabilityInstruction
Question: $($Fixture.question)$packetText
Permitted fact IDs for this fixture: $factIds
Return only one JSON object with exactly these fields:
{"facts":[{"fact_id":"one required fixture fact id","statement":"bounded answer","citations":["project/path:line-range"]}],"completed":true,"absence_claims":[]}
Use only fact IDs and citations supported by current files. No markdown fences or extra prose.
"@
}

function Invoke-Topic05ModelPilotBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Registry,
        [Parameter(Mandatory)][object]$Plan,
        [Parameter(Mandatory)][string]$LeadModel,
        [switch]$AllowModelSpend,
        [Parameter(Mandatory)][string]$Confirmation,
        [string]$OmpPath,
        [string]$CodeGraphArtifactPath,
        [switch]$AllowCodeGraphDownload
    )
    [void](Assert-Topic05BenchmarkModelPilotGate -AllowModelSpend:$AllowModelSpend `
        -Confirmation $Confirmation -LeadModel $LeadModel)
    if ($CodeGraphArtifactPath -and $AllowCodeGraphDownload) {
        throw 'model-pilot CodeGraph artifact and download permission are mutually exclusive'
    }
    [void](Assert-Topic05BenchmarkOutputPlan $Plan)
    if (-not $OmpPath) {
        $command = @(Get-Command omp -CommandType Application -ErrorAction SilentlyContinue)[0]
        if ($null -eq $command) { throw 'model-pilot OMP executable is unavailable' }
        $OmpPath = if ($command.Source) { $command.Source } else { $command.Path }
    }
    $ompVersionOutput = @(& $OmpPath --version 2>&1)
    $ompVersionMatch = if ($ompVersionOutput.Count -eq 1) {
        [regex]::Match(([string]$ompVersionOutput[0]).Trim(), '^omp v(?<version>[0-9]+\.[0-9]+\.[0-9]+)$')
    } else { $null }
    if ($LASTEXITCODE -ne 0 -or $null -eq $ompVersionMatch -or -not $ompVersionMatch.Success) {
        throw 'model-pilot OMP version preflight failed'
    }
    $ompVersion = $ompVersionMatch.Groups['version'].Value
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
    $tempRoot = Join-Path $tempBase ('omp-topic05-model-pilot-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $tempRoot)
    $records = [Collections.Generic.List[object]]::new()
    $preparedGraphTargets = @{}
    $preparedExecutionRoots = @{}
    $scoutPrimary = 'omniroute/ds/deepseek-v4-flash:xhigh'
    $scoutFallback = 'omniroute/ds/deepseek-v4-pro:xhigh'
    try {
        # Prepare every repository and every installed adapter before the first model process.
        # A missing bundle, invalid component, collision, or disk failure therefore burns no model tokens.
        $codeGraphAcquisitionPending = $true
        foreach ($execution in @($Plan.executions)) {
            $fixtures = @($Registry.fixtures | Where-Object fixture_id -CEQ $execution.fixture_id)
            if ($fixtures.Count -ne 1) { throw 'model-pilot preparation fixture identity is not unique' }
            $fixture = $fixtures[0]
            $capability = if ([string]$execution.arm -in @(
                    'B_lead_codegraph', 'D_scout_codegraph_lead'
                )) { 'codegraph' } else { 'native' }
            if ($capability -ceq 'codegraph') {
                $targetKey = "$($execution.pair)|$($execution.fixture_id)|$($execution.arm)"
                if ($execution.cache_condition -ceq 'cold') {
                    $workRoot = Join-Path $tempRoot ('run-' + $execution.order)
                    [void](New-Topic05BenchmarkMaterializedFixture -Fixture $fixture `
                        -LiteralPath $workRoot -Capability native)
                    [void](Initialize-Topic05BenchmarkCodeGraphTarget -ProjectDirectory $workRoot `
                        -ArtifactPath $(if ($codeGraphAcquisitionPending) {
                            $CodeGraphArtifactPath
                        } else { $null }) -AllowDownload:($codeGraphAcquisitionPending -and
                            $AllowCodeGraphDownload))
                    $codeGraphAcquisitionPending = $false
                    $preparedGraphTargets[$targetKey] = $workRoot
                } elseif ($preparedGraphTargets.ContainsKey($targetKey)) {
                    $workRoot = [string]$preparedGraphTargets[$targetKey]
                } else { throw 'model-pilot warm run lacks its preceding cold target' }
            } else {
                $workRoot = Join-Path $tempRoot ('run-' + $execution.order)
                [void](New-Topic05BenchmarkMaterializedFixture -Fixture $fixture `
                    -LiteralPath $workRoot -Capability native)
                if (-not (Test-Topic05BenchmarkNativeBoundary -RepositoryRoot $workRoot `
                        -Controls $Registry.contamination_controls -Environment @{})) {
                    throw 'model-pilot native target failed contamination preflight'
                }
            }
            $preparedExecutionRoots[[string]$execution.order] = $workRoot
        }

        foreach ($execution in @($Plan.executions)) {
            $fixtures = @($Registry.fixtures | Where-Object fixture_id -CEQ $execution.fixture_id)
            if ($fixtures.Count -ne 1) { throw 'model-pilot fixture identity is not unique' }
            $fixture = $fixtures[0]
            $isScout = [string]$execution.arm -in @('C_scout_native_lead', 'D_scout_codegraph_lead')
            $capability = if ([string]$execution.arm -in @(
                    'B_lead_codegraph', 'D_scout_codegraph_lead'
                )) { 'codegraph' } else { 'native' }
            $workRoot = [string]$preparedExecutionRoots[[string]$execution.order]
            if ([string]::IsNullOrWhiteSpace($workRoot)) {
                throw 'model-pilot prepared execution root is unavailable'
            }
            $started = [DateTime]::UtcNow
            $environmentIdentity = [ordered]@{
                os = [Runtime.InteropServices.RuntimeInformation]::OSDescription
                architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
                pwsh_version = $PSVersionTable.PSVersion.ToString()
                omp_version = $ompVersion
                pair = [int]$execution.pair
                mode = 'model-pilot'
            }
            $scoutResult = $null
            $scoutPacket = $null
            $scoutFallbackUsed = $false
            $scoutAttemptUsages = @()
            if ($isScout) {
                $scoutPrompt = New-Topic05BenchmarkPrompt -Fixture $fixture -Stage scout `
                    -Capability $capability -ScoutPacket $null
                $scoutResult = Invoke-Topic05BenchmarkOmpProcess -OmpPath $OmpPath `
                    -WorkingDirectory $workRoot -ModelIdentity $scoutPrimary -Prompt $scoutPrompt `
                    -Capability $capability -Scope scout -AllowModelSpend:$AllowModelSpend `
                    -Confirmation $Confirmation -LeadModel $LeadModel
                $scoutAttemptUsages += $scoutResult.usage
                if ($scoutResult.status -eq 'ENVIRONMENT_BLOCKED') {
                    $scoutFallbackUsed = $true
                    $scoutResult = Invoke-Topic05BenchmarkOmpProcess -OmpPath $OmpPath `
                        -WorkingDirectory $workRoot -ModelIdentity $scoutFallback -Prompt $scoutPrompt `
                        -Capability $capability -Scope scout -AllowModelSpend:$AllowModelSpend `
                        -Confirmation $Confirmation -LeadModel $LeadModel
                    $scoutAttemptUsages += $scoutResult.usage
                }
                if ($capability -ceq 'codegraph' -and $scoutResult.status -eq 'COMPLETED' -and
                    [int]$scoutResult.codegraph_calls -eq 0) {
                    $scoutResult.status = 'FAILED'
                    $scoutResult.reason = 'selected_codegraph_not_used'
                }
                $combinedScoutUsage = Merge-Topic05BenchmarkScoutAttemptUsage $scoutAttemptUsages
                if ($scoutResult.status -eq 'ENVIRONMENT_BLOCKED') {
                    $actor = [ordered]@{
                        lead_model = $LeadModel
                        lead_resolved = $null
                        scout_primary = $scoutPrimary
                        scout_fallback = $scoutFallback
                        scout_resolved = $scoutResult.resolved_model
                        scout_fallback_used = $scoutFallbackUsed
                        model_invoked = $true
                    }
                    $record = New-Topic05BenchmarkRunRecord -Execution $execution -Fixture $fixture `
                        -Status ENVIRONMENT_BLOCKED -Reason 'deepseek_routes_unavailable' `
                        -Usage (Merge-Topic05BenchmarkUsage -Core $null -Scout $combinedScoutUsage) `
                        -ActorIdentity $actor -EnvironmentIdentity $environmentIdentity `
                        -StartedAt $started -CompletedAt ([DateTime]::UtcNow)
                    Write-Topic05BenchmarkRunRecord -Record $record -LiteralPath $execution.output_path
                    [void]$records.Add($record)
                    continue
                }
                if ($scoutResult.status -ne 'COMPLETED' -or $scoutResult.is_fallback -eq $true) {
                    $actor = [ordered]@{
                        lead_model = $LeadModel
                        lead_resolved = $null
                        scout_primary = $scoutPrimary
                        scout_fallback = $scoutFallback
                        scout_resolved = $scoutResult.resolved_model
                        scout_fallback_used = $scoutFallbackUsed
                        model_invoked = $true
                    }
                    $record = New-Topic05BenchmarkRunRecord -Execution $execution -Fixture $fixture `
                        -Status $scoutResult.status -Reason $(if ($scoutResult.is_fallback) {
                            'scout_identity_mismatch'
                        } else { $scoutResult.reason }) `
                        -Usage (Merge-Topic05BenchmarkUsage -Core $null -Scout $combinedScoutUsage) `
                        -ActorIdentity $actor -EnvironmentIdentity $environmentIdentity `
                        -StartedAt $started -CompletedAt ([DateTime]::UtcNow)
                    Write-Topic05BenchmarkRunRecord -Record $record -LiteralPath $execution.output_path
                    [void]$records.Add($record)
                    continue
                }
                $scoutMeasured = Measure-Topic05BenchmarkAnswer -Text $scoutResult.final_text -Fixture $fixture
                $scoutPacket = $scoutMeasured.packet
            }

            $leadStage = if ($isScout) { 'lead-consume' } else { 'lead' }
            $leadCapability = if ($isScout) { 'native' } else { $capability }
            $leadPrompt = New-Topic05BenchmarkPrompt -Fixture $fixture -Stage $leadStage `
                -Capability $leadCapability -ScoutPacket $scoutPacket
            $leadResult = Invoke-Topic05BenchmarkOmpProcess -OmpPath $OmpPath `
                -WorkingDirectory $workRoot -ModelIdentity $LeadModel -Prompt $leadPrompt `
                -Capability $leadCapability -Scope core -AllowModelSpend:$AllowModelSpend `
                -Confirmation $Confirmation -LeadModel $LeadModel
            $status = if ($leadResult.is_fallback -eq $true) { 'FAILED' } else { $leadResult.status }
            $reason = if ($leadResult.is_fallback -eq $true) {
                'lead_identity_mismatch'
            } else { $leadResult.reason }
            $measured = Measure-Topic05BenchmarkAnswer -Text $leadResult.final_text -Fixture $fixture
            $graphResult = if ($capability -ceq 'codegraph') {
                if ($isScout) { $scoutResult } else { $leadResult }
            } else { $null }
            if ($capability -ceq 'codegraph' -and $status -eq 'COMPLETED' -and
                [int]$graphResult.codegraph_calls -eq 0) {
                $status = 'FAILED'
                $reason = 'selected_codegraph_not_used'
            }
            if ($leadResult.status -eq 'COMPLETED' -and -not $measured.quality.hard_gate_pass) {
                $status = 'FAILED'
                $reason = 'quality_hard_gate_failed'
            }
            if ($null -ne $graphResult -and @($graphResult.codegraph_fallback_reasons).Count -gt 0 -and
                [string]::IsNullOrWhiteSpace($reason)) {
                $reason = [string]@($graphResult.codegraph_fallback_reasons)[0]
            }
            if ($status -ne 'COMPLETED') { $measured.quality.hard_gate_pass = $false }
            $usage = Merge-Topic05BenchmarkUsage -Core $leadResult.usage `
                -Scout $(if ($null -eq $scoutResult) { $null } else { $combinedScoutUsage })
            $actor = [ordered]@{
                lead_model = $LeadModel
                lead_resolved = $leadResult.resolved_model
                scout_primary = $(if ($isScout) { $scoutPrimary } else { $null })
                scout_fallback = $(if ($isScout) { $scoutFallback } else { $null })
                scout_resolved = $(if ($isScout) { $scoutResult.resolved_model } else { $null })
                scout_fallback_used = $scoutFallbackUsed
                model_invoked = $true
            }
            $retrieval = [ordered]@{
                capability = $(if ($null -ne $graphResult -and
                    @($graphResult.codegraph_fallback_reasons).Count -gt 0) { 'native' } elseif (
                    $capability -ceq 'codegraph'
                ) { 'mixed' } else { 'native' })
                result_status = $(if ($null -ne $graphResult -and
                    @($graphResult.codegraph_fallback_reasons).Count -gt 0) {
                        'fallback_native'
                    } elseif ($status -eq 'COMPLETED') { 'completed' } else { 'failed' })
                reason = $(if ($null -ne $graphResult -and
                    @($graphResult.codegraph_fallback_reasons).Count -gt 0) {
                        [string]@($graphResult.codegraph_fallback_reasons)[0]
                    } else { $reason })
                tool_calls = [int]$leadResult.tool_calls + $(if ($null -eq $scoutResult) {
                        0
                    } else { [int]$scoutResult.tool_calls })
                fallbacks = [int]$(
                    @($(if ($scoutFallbackUsed) { 1 } else { 0 }),
                        $(if ($leadResult.is_fallback -or
                            ($null -ne $scoutResult -and $scoutResult.is_fallback)) { 1 } else { 0 }),
                        $(if ($null -ne $graphResult -and
                            @($graphResult.codegraph_fallback_reasons).Count -gt 0) { 1 } else { 0 })
                    ) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                )
                retries = 0
                duration_ms = [long]([DateTime]::UtcNow - $started).TotalMilliseconds
                index_init_ms = 'not_measured'
                index_sync_ms = 'not_measured'
                index_size_bytes = 'not_measured'
            }
            $contamination = [ordered]@{
                native_boundary_pass = $(if ($capability -ceq 'native') {
                        Test-Topic05BenchmarkNativeBoundary -RepositoryRoot $workRoot `
                            -Controls $Registry.contamination_controls -Environment @{}
                    } else { $true })
                adapter_visible = ($capability -ceq 'codegraph')
                codegraph_environment_keys = @()
                separate_target = $true
                snapshot_match = $true
            }
            $record = New-Topic05BenchmarkRunRecord -Execution $execution -Fixture $fixture `
                -Status $status -Reason $reason -Usage $usage -Quality $measured.quality `
                -Retrieval $retrieval -Contamination $contamination -ActorIdentity $actor `
                -LeadReread $leadResult.lead_reread `
                -EnvironmentIdentity $environmentIdentity -StartedAt $started `
                -CompletedAt ([DateTime]::UtcNow)
            Write-Topic05BenchmarkRunRecord -Record $record -LiteralPath $execution.output_path
            [void]$records.Add($record)
        }
        return $records.ToArray()
    } finally {
        $resolved = [IO.Path]::GetFullPath($tempRoot).TrimEnd('\', '/')
        if ([IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/') -cne $tempBase -or
            -not [IO.Path]::GetFileName($resolved).StartsWith(
                'omp-topic05-model-pilot-',
                [StringComparison]::Ordinal
            )) { throw "Refusing unsafe model-pilot cleanup target: $resolved" }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}

function Get-Topic05BenchmarkComparisonReport {
    param([Parameter(Mandatory)][object[]]$Records)
    foreach ($record in @($Records)) { [void](Test-Topic05BenchmarkRunRecord $record) }
    $seenOrders = @{}
    foreach ($record in @($Records)) {
        $orderKey = "$($record.campaign_id)|$($record.order)"
        if ($seenOrders.ContainsKey($orderKey)) { throw "duplicate benchmark run order: $orderKey" }
        $seenOrders[$orderKey] = $true
    }
    $pairedGroups = 0
    $excludedGroups = 0
    $expectedVariants = @(
        'A_lead_native|absent', 'B_lead_codegraph|cold', 'B_lead_codegraph|warm',
        'C_scout_native_lead|absent', 'D_scout_codegraph_lead|cold',
        'D_scout_codegraph_lead|warm'
    ) | Sort-Object
    $pairedGroupObjects = @($Records | Group-Object {
            "$($_.campaign_id)|$($_.environment_identity.pair)|$($_.fixture_id)"
        })
    foreach ($group in $pairedGroupObjects) {
        $hashes = @($group.Group.snapshot_hash | Sort-Object -Unique)
        if ($hashes.Count -ne 1) { throw "paired benchmark snapshot mismatch: $($group.Name)" }
        $variants = @($group.Group | ForEach-Object { "$($_.arm)|$($_.cache_condition)" })
        if (@($variants | Sort-Object -Unique).Count -ne $variants.Count) {
            throw "duplicate paired benchmark variant: $($group.Name)"
        }
        if ((@($variants | Sort-Object) -join '|') -ceq ($expectedVariants -join '|')) {
            $pairedGroups++
        } else { $excludedGroups++ }
    }
    $hardGatePass = @($Records | Where-Object {
        $_.contamination.snapshot_match -ne $true -or $_.contamination.separate_target -ne $true -or
        $_.quality.false_absence -eq $true -or $_.quality.false_completion -eq $true -or
        ($_.status -ceq 'COMPLETED' -and $_.quality.hard_gate_pass -ne $true)
    }).Count -eq 0
    $usageMeasured = @($Records | Where-Object {
        $_.status -ceq 'COMPLETED' -and [string]$_.usage.raw_total_tokens -ceq 'not_measured'
    }).Count -eq 0 -and @($Records | Where-Object status -CEQ 'COMPLETED').Count -gt 0
    $allRoutesObserved = @($Records | Where-Object {
        $_.status -cne 'COMPLETED' -or
        ([string]$_.arm -in @('B_lead_codegraph', 'D_scout_codegraph_lead') -and
            [string]$_.retrieval.capability -cnotin @('codegraph', 'mixed'))
    }).Count -eq 0
    $bTaskClasses = [Collections.Generic.List[string]]::new()
    $dTaskClasses = [Collections.Generic.List[string]]::new()
    foreach ($fixtureClass in $script:Topic05BenchmarkFixtureClasses) {
        $classGroups = @($pairedGroupObjects | Where-Object {
            @($_.Group | Where-Object fixture_class -CEQ $fixtureClass).Count -gt 0
        })
        if ($classGroups.Count -eq 0) { continue }
        $bWinsEveryPair = $true
        $dWinsEveryPair = $true
        foreach ($group in $classGroups) {
            $a = @($group.Group | Where-Object {
                $_.arm -ceq 'A_lead_native' -and $_.cache_condition -ceq 'absent'
            })
            $b = @($group.Group | Where-Object arm -CEQ 'B_lead_codegraph')
            $c = @($group.Group | Where-Object {
                $_.arm -ceq 'C_scout_native_lead' -and $_.cache_condition -ceq 'absent'
            })
            $d = @($group.Group | Where-Object arm -CEQ 'D_scout_codegraph_lead')
            $bEligible = $a.Count -eq 1 -and $b.Count -eq 2 -and
                @($a + $b | Where-Object {
                    $_.status -cne 'COMPLETED' -or $_.quality.hard_gate_pass -ne $true -or
                    [string]$_.usage.core_workflow_tokens -ceq 'not_measured'
                }).Count -eq 0 -and
                @($b | Where-Object { [string]$_.retrieval.capability -cnotin @('codegraph', 'mixed') }).Count -eq 0
            if (-not $bEligible -or @($b | Where-Object {
                    [long]$_.usage.core_workflow_tokens -ge [long]$a[0].usage.core_workflow_tokens
                }).Count -gt 0) { $bWinsEveryPair = $false }
            $dEligible = $c.Count -eq 1 -and $d.Count -eq 2 -and
                @($c + $d | Where-Object {
                    $_.status -cne 'COMPLETED' -or $_.quality.hard_gate_pass -ne $true -or
                    [string]$_.usage.core_workflow_tokens -ceq 'not_measured'
                }).Count -eq 0 -and
                @($d | Where-Object { [string]$_.retrieval.capability -cnotin @('codegraph', 'mixed') }).Count -eq 0
            if (-not $dEligible -or @($d | Where-Object {
                    [long]$_.usage.core_workflow_tokens -ge [long]$c[0].usage.core_workflow_tokens
                }).Count -gt 0) { $dWinsEveryPair = $false }
        }
        if ($bWinsEveryPair) { [void]$bTaskClasses.Add($fixtureClass) }
        if ($dWinsEveryPair) { [void]$dTaskClasses.Add($fixtureClass) }
    }
    $recommendation = if (-not $hardGatePass) { 'neither' } elseif (
        $bTaskClasses.Count -gt 0 -and $dTaskClasses.Count -gt 0
    ) { 'both_for_named_task_classes' } elseif ($bTaskClasses.Count -gt 0) {
        'B_for_named_task_classes'
    } elseif ($dTaskClasses.Count -gt 0) { 'D_for_named_task_classes' } else { 'inconclusive' }
    return [pscustomobject]@{
        schema_version = 1
        comparisons = @('A_vs_B', 'C_vs_D', 'A_vs_C', 'B_vs_D')
        cold_warm_separate = $true
        paired_snapshot_only = $true
        paired_group_count = $pairedGroups
        excluded_group_count = $excludedGroups
        hard_gates_pass = $hardGatePass
        efficiency_measured = $usageMeasured
        all_routes_observed = $allRoutesObserved
        route_task_classes = [pscustomobject]@{
            B = $bTaskClasses.ToArray()
            D = $dTaskClasses.ToArray()
        }
        recommendation = $recommendation
        scope = 'route_and_task_class_only'
        universal_default = $false
        codegraph_percentage_threshold = $null
        promotion = $false
    }
}

function Get-Topic05BenchmarkModelProcessStartCount {
    return [int]$script:Topic05BenchmarkModelProcessStarts
}
