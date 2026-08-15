#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$libraryPath = Join-Path $repositoryRoot 'scripts\lib\topic05-benchmark.ps1'
$runnerPath = Join-Path $repositoryRoot 'scripts\run-topic05-retrieval-benchmark.ps1'
$fixturePath = Join-Path $repositoryRoot 'evals\retrieval\topic05\fixtures.json'
$readmePath = Join-Path $repositoryRoot 'evals\retrieval\topic05\README.md'
$required = @($libraryPath, $runnerPath, $fixturePath, $readmePath)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
    Write-Host "FAIL [T05-BENCHMARK] missing benchmark contract: $($missing[0])" -ForegroundColor Red
    exit 1
}

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic05-benchmark-test-'
$script:Roots = [Collections.Generic.List[string]]::new()
$script:Assertions = 0
. $libraryPath

function Assert-Topic05BenchmarkTest {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic05BenchmarkTestRoot {
    $root = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root)
    [void]$script:Roots.Add([IO.Path]::GetFullPath($root))
    return $root
}

function Copy-Topic05BenchmarkJson {
    param([Parameter(Mandatory)][object]$Value)
    return ($Value | ConvertTo-Json -Depth 30 | ConvertFrom-Json)
}

function Assert-Topic05BenchmarkThrows {
    param(
        [Parameter(Mandatory)][scriptblock]$Body,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Message
    )
    $caught = $null
    try { & $Body } catch { $caught = $_ }
    Assert-Topic05BenchmarkTest ($null -ne $caught -and $caught.Exception.Message -like $Pattern) `
        "$Message Actual: $($caught.Exception.Message)"
}

function Write-Topic05BenchmarkMutation {
    param([Parameter(Mandatory)][object]$Value, [Parameter(Mandatory)][string]$Root)
    $path = Join-Path $Root ('mutation-' + [guid]::NewGuid().ToString('N') + '.json')
    [IO.File]::WriteAllText(
        $path,
        (($Value | ConvertTo-Json -Depth 30) + "`n"),
        [Text.UTF8Encoding]::new($false)
    )
    return $path
}

try {
    $registry = Read-Topic05BenchmarkFixtures -LiteralPath $fixturePath
    Assert-Topic05BenchmarkTest (@($registry.fixtures).Count -eq 9) `
        'Fixture registry did not contain exactly nine fixtures.'
    Assert-Topic05BenchmarkTest ((@($registry.fixtures.fixture_class | Sort-Object -Unique)).Count -eq 9) `
        'Fixture registry classes were not unique.'
    foreach ($fixture in @($registry.fixtures)) {
        Assert-Topic05BenchmarkTest (@($fixture.required_facts).Count -gt 0 -and
            @($fixture.allowed_citations).Count -gt 0 -and @($fixture.materializer.files).Count -gt 0) `
            "Fixture lacks a materializer or oracle: $($fixture.fixture_id)"
    }

    $mutationRoot = New-Topic05BenchmarkTestRoot
    $unknown = Copy-Topic05BenchmarkJson $registry
    $unknown | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
    $unknownPath = Write-Topic05BenchmarkMutation -Value $unknown -Root $mutationRoot
    Assert-Topic05BenchmarkThrows -Pattern '*unknown*fields*' -Message 'Unknown fixture fields were accepted.' -Body {
        Read-Topic05BenchmarkFixtures -LiteralPath $unknownPath | Out-Null
    }

    $duplicate = Copy-Topic05BenchmarkJson $registry
    $duplicate.fixtures[1].fixture_id = $duplicate.fixtures[0].fixture_id
    $duplicatePath = Write-Topic05BenchmarkMutation -Value $duplicate -Root $mutationRoot
    Assert-Topic05BenchmarkThrows -Pattern '*duplicate*' -Message 'Duplicate fixture IDs were accepted.' -Body {
        Read-Topic05BenchmarkFixtures -LiteralPath $duplicatePath | Out-Null
    }

    $unsafe = Copy-Topic05BenchmarkJson $registry
    $unsafe.fixtures[0].materializer.files[0].path = '../escape.ts'
    $unsafePath = Write-Topic05BenchmarkMutation -Value $unsafe -Root $mutationRoot
    Assert-Topic05BenchmarkThrows -Pattern '*path*invalid*' -Message 'Unsafe fixture paths were accepted.' -Body {
        Read-Topic05BenchmarkFixtures -LiteralPath $unsafePath | Out-Null
    }

    $missingOracle = Copy-Topic05BenchmarkJson $registry
    $missingOracle.fixtures[0].required_facts = @()
    $missingOraclePath = Write-Topic05BenchmarkMutation -Value $missingOracle -Root $mutationRoot
    Assert-Topic05BenchmarkThrows -Pattern '*facts*missing*' -Message 'Missing oracle facts were accepted.' -Body {
        Read-Topic05BenchmarkFixtures -LiteralPath $missingOraclePath | Out-Null
    }

    $missingControl = Copy-Topic05BenchmarkJson $registry
    $missingControl.contamination_controls.separate_capability_targets = $false
    $missingControlPath = Write-Topic05BenchmarkMutation -Value $missingControl -Root $mutationRoot
    Assert-Topic05BenchmarkThrows -Pattern '*contamination controls*' `
        -Message 'Missing contamination controls were accepted.' -Body {
        Read-Topic05BenchmarkFixtures -LiteralPath $missingControlPath | Out-Null
    }

    $planRoot = New-Topic05BenchmarkTestRoot
    $plannedOutput = Join-Path $planRoot 'not-created-by-plan'
    $plan = New-Topic05BenchmarkPlan -Registry $registry -Pairs 3 -Seed 20260813 `
        -OutputDirectory $plannedOutput
    Assert-Topic05BenchmarkTest ($plan.execution_count -eq 162 -and @($plan.executions).Count -eq 162) `
        'Three-pair plan did not contain 162 executions.'
    Assert-Topic05BenchmarkTest (-not (Test-Path -LiteralPath $plannedOutput)) `
        'Plan mode materialized an output directory.'
    Assert-Topic05BenchmarkTest ((@($plan.executions.order | Sort-Object -Unique)).Count -eq 162 -and
        ($plan.executions | Measure-Object order -Minimum).Minimum -eq 1 -and
        ($plan.executions | Measure-Object order -Maximum).Maximum -eq 162) `
        'Plan ordering was not seeded and contiguous.'
    foreach ($fixture in @($registry.fixtures)) {
        foreach ($pair in 1..3) {
            $rows = @($plan.executions | Where-Object {
                $_.fixture_id -ceq $fixture.fixture_id -and $_.pair -eq $pair
            })
            Assert-Topic05BenchmarkTest ($rows.Count -eq 6 -and
                @($rows | Where-Object arm -CEQ 'A_lead_native').Count -eq 1 -and
                @($rows | Where-Object arm -CEQ 'C_scout_native_lead').Count -eq 1 -and
                @($rows | Where-Object arm -CEQ 'B_lead_codegraph').Count -eq 2 -and
                @($rows | Where-Object arm -CEQ 'D_scout_codegraph_lead').Count -eq 2) `
                "Fixture/pair arm balance is wrong: $($fixture.fixture_id)/$pair"
            Assert-Topic05BenchmarkTest (((@($rows | Where-Object arm -in @(
                            'A_lead_native', 'C_scout_native_lead'
                        )).cache_condition | Sort-Object -Unique) -join '|') -ceq 'absent') `
                "Native cache condition is contaminated: $($fixture.fixture_id)/$pair"
            foreach ($arm in @('B_lead_codegraph', 'D_scout_codegraph_lead')) {
                Assert-Topic05BenchmarkTest (((@($rows | Where-Object arm -CEQ $arm).cache_condition |
                        Sort-Object) -join '|') -ceq 'cold|warm') `
                    "CodeGraph cold/warm split is wrong: $($fixture.fixture_id)/$pair/$arm"
                $cold = @($rows | Where-Object {
                    $_.arm -ceq $arm -and $_.cache_condition -ceq 'cold'
                })[0]
                $warm = @($rows | Where-Object {
                    $_.arm -ceq $arm -and $_.cache_condition -ceq 'warm'
                })[0]
                Assert-Topic05BenchmarkTest ($warm.order -eq ($cold.order + 1)) `
                    "CodeGraph warm run is not immediately after cold: $($fixture.fixture_id)/$pair/$arm"
            }
        }
    }
    $samePlan = New-Topic05BenchmarkPlan -Registry $registry -Pairs 3 -Seed 20260813 `
        -OutputDirectory $plannedOutput
    $differentPlan = New-Topic05BenchmarkPlan -Registry $registry -Pairs 3 -Seed 20260814 `
        -OutputDirectory $plannedOutput
    Assert-Topic05BenchmarkTest ((@($plan.executions | ForEach-Object {
                "$($_.fixture_id)|$($_.arm)|$($_.cache_condition)|$($_.pair)"
            }) -join "`n") -ceq (@($samePlan.executions | ForEach-Object {
                "$($_.fixture_id)|$($_.arm)|$($_.cache_condition)|$($_.pair)"
            }) -join "`n")) 'Identical seeds did not reproduce ordering.'
    Assert-Topic05BenchmarkTest ((@($plan.executions.fixture_id) -join '|') -cne
        (@($differentPlan.executions.fixture_id) -join '|')) 'Different seeds did not alter ordering.'

    Assert-Topic05BenchmarkThrows -Pattern '*AllowModelSpend*' `
        -Message 'Model pilot accepted missing spend permission.' -Body {
        Assert-Topic05BenchmarkModelPilotGate -Confirmation RUN_TOPIC05_MODEL_PILOT `
            -LeadModel 'omniroute/codex:gpt-5.6-sol:xhigh' | Out-Null
    }
    Assert-Topic05BenchmarkThrows -Pattern '*exact confirmation*' `
        -Message 'Model pilot accepted a wrong confirmation.' -Body {
        Assert-Topic05BenchmarkModelPilotGate -AllowModelSpend -Confirmation WRONG `
            -LeadModel 'omniroute/codex-gpt-5.6-sol:xhigh' | Out-Null
    }
    Assert-Topic05BenchmarkThrows -Pattern '*LeadModel*' `
        -Message 'Model pilot accepted an empty Lead identity.' -Body {
        Assert-Topic05BenchmarkModelPilotGate -AllowModelSpend `
            -Confirmation RUN_TOPIC05_MODEL_PILOT -LeadModel '' | Out-Null
    }
    Assert-Topic05BenchmarkTest (Assert-Topic05BenchmarkModelPilotGate -AllowModelSpend `
        -Confirmation RUN_TOPIC05_MODEL_PILOT -LeadModel 'omniroute/codex-gpt-5.6-sol:xhigh') `
        'Exact model-pilot gate was rejected.'

    $execution = @($plan.executions | Where-Object arm -CEQ 'A_lead_native')[0]
    $fixtureForRecord = @($registry.fixtures | Where-Object fixture_id -CEQ $execution.fixture_id)[0]
    $record = New-Topic05BenchmarkRunRecord -Execution $execution -Fixture $fixtureForRecord
    Assert-Topic05BenchmarkTest (Test-Topic05BenchmarkRunRecord $record) `
        'Valid run record was rejected.'
    $missingCoreUsage = [pscustomobject]@{
        core_workflow_tokens = 'not_measured'; cheap_scout_tokens = 'not_measured';
        raw_total_tokens = 'not_measured'; cache_read_tokens = 'not_measured';
        residual_context_tokens = 'not_measured'; provider_reported = $false
    }
    $directMissingUsage = Merge-Topic05BenchmarkUsage -Core $missingCoreUsage -Scout $null
    $missingUsageRecord = New-Topic05BenchmarkRunRecord -Execution $execution `
        -Fixture $fixtureForRecord -Usage $directMissingUsage
    Assert-Topic05BenchmarkTest (Test-Topic05BenchmarkRunRecord $missingUsageRecord) `
        'A structural zero Scout ledger was mistaken for estimated provider usage.'

    $unknownRecord = Copy-Topic05BenchmarkJson $record
    $unknownRecord | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
    Assert-Topic05BenchmarkThrows -Pattern '*unknown*fields*' `
        -Message 'Unknown run-record fields were accepted.' -Body {
        Test-Topic05BenchmarkRunRecord $unknownRecord | Out-Null
    }
    $invalidArm = Copy-Topic05BenchmarkJson $record
    $invalidArm.arm = 'E_unknown'
    $invalidArm.record_hash = Get-Topic05BenchmarkRecordHash $invalidArm
    Assert-Topic05BenchmarkThrows -Pattern '*arm*invalid*' `
        -Message 'Invalid benchmark arm was accepted.' -Body {
        Test-Topic05BenchmarkRunRecord $invalidArm | Out-Null
    }
    $unseeded = Copy-Topic05BenchmarkJson $record
    $unseeded.seed = 0
    $unseeded.record_hash = Get-Topic05BenchmarkRecordHash $unseeded
    Assert-Topic05BenchmarkThrows -Pattern '*seed*invalid*' `
        -Message 'Unseeded run record was accepted.' -Body {
        Test-Topic05BenchmarkRunRecord $unseeded | Out-Null
    }
    $estimated = Copy-Topic05BenchmarkJson $record
    $estimated.usage.core_workflow_tokens = 10
    $estimated.usage.cheap_scout_tokens = 0
    $estimated.usage.raw_total_tokens = 10
    $estimated.usage.cache_read_tokens = 0
    $estimated.usage.residual_context_tokens = 3
    $estimated.usage.provider_reported = $false
    $estimated.record_hash = Get-Topic05BenchmarkRecordHash $estimated
    Assert-Topic05BenchmarkThrows -Pattern '*provider-reported*' `
        -Message 'Token claims without provider usage were accepted.' -Body {
        Test-Topic05BenchmarkRunRecord $estimated | Out-Null
    }

    $events = @(
        [pscustomobject]@{
            type = 'usage'; scope = 'core'; input_tokens = 10; output_tokens = 5;
            cache_read_tokens = 2; residual_context_tokens = 7
        },
        [pscustomobject]@{
            type = 'usage'; scope = 'scout'; input_tokens = 20; output_tokens = 4;
            cache_read_tokens = 3; residual_context_tokens = 'not_measured'
        },
        [pscustomobject]@{
            type = 'terminal'; status = 'completed'; reason = $null;
            resolved_model = 'omniroute/codex-gpt-5.6-sol:xhigh'; is_fallback = $false
        }
    )
    $parsed = ConvertFrom-Topic05BenchmarkEventStream -Events $events
    Assert-Topic05BenchmarkTest ($parsed.status -ceq 'COMPLETED' -and
        $parsed.usage.core_workflow_tokens -eq 15 -and $parsed.usage.cheap_scout_tokens -eq 24 -and
        $parsed.usage.raw_total_tokens -eq 39 -and $parsed.usage.cache_read_tokens -eq 5 -and
        $parsed.usage.residual_context_tokens -ceq 'not_measured') `
        'Provider usage event aggregation is incorrect.'
    $missingUsage = ConvertFrom-Topic05BenchmarkEventStream -Events @(
        [pscustomobject]@{
            type = 'terminal'; status = 'unavailable'; reason = 'provider_unavailable';
            resolved_model = $null; is_fallback = $false
        }
    )
    Assert-Topic05BenchmarkTest ($missingUsage.status -ceq 'ENVIRONMENT_BLOCKED' -and
        $missingUsage.usage.raw_total_tokens -ceq 'not_measured' -and
        $missingUsage.usage.provider_reported -eq $false) `
        'Unavailable/missing-usage event stream was not represented honestly.'
    $timeout = ConvertFrom-Topic05BenchmarkEventStream -Events @(
        [pscustomobject]@{
            type = 'terminal'; status = 'timeout'; reason = 'deadline';
            resolved_model = 'omniroute/ds/deepseek-v4-pro:xhigh'; is_fallback = $true
        }
    )
    Assert-Topic05BenchmarkTest ($timeout.status -ceq 'TIMEOUT' -and $timeout.is_fallback -eq $true) `
        'Timeout/fallback event stream was not retained.'
    $qualityFixture = @($registry.fixtures | Where-Object fixture_class -CEQ 'multi_file_call_path')[0]
    $validAnswer = '{"facts":[{"fact_id":"call-chain","statement":"postOrder reaches executeOrder and then saveOrder.","citations":["src/handler.ts:1-3","src/service.ts:1-3"]}],"completed":true,"absence_claims":[]}'
    $validQuality = Measure-Topic05BenchmarkAnswer -Text $validAnswer -Fixture $qualityFixture
    Assert-Topic05BenchmarkTest ($validQuality.quality.hard_gate_pass -eq $true -and
        $validQuality.quality.required_fact_recalled -eq 1) `
        'Deterministic required-term/citation oracle rejected a valid answer.'
    $plausibleButWrong = '{"facts":[{"fact_id":"call-chain","statement":"postOrder reaches executeOrder.","citations":["src/handler.ts:1-3"]}],"completed":true,"absence_claims":[]}'
    $wrongQuality = Measure-Topic05BenchmarkAnswer -Text $plausibleButWrong -Fixture $qualityFixture
    Assert-Topic05BenchmarkTest ($wrongQuality.quality.hard_gate_pass -eq $false -and
        $wrongQuality.quality.false_completion -eq $true) `
        'A plausible answer missing a required semantic term escaped the hard gate.'

    $ompLines = @(
        ([pscustomobject]@{
            type = 'tool_execution_end'; toolCallId = 'read-1'; toolName = 'read';
            args = [pscustomobject]@{ path = 'src/handler.ts'; offset = 1; limit = 20 };
            result = [pscustomobject]@{
                content = @([pscustomobject]@{ type = 'text'; text = 'source bytes' })
            }
        } | ConvertTo-Json -Depth 12 -Compress),
        ([pscustomobject]@{
            type = 'tool_execution_end'; toolCallId = 'graph-1'; toolName = 'codegraph_retrieve';
            args = [pscustomobject]@{ question = 'trace'; max_files = 6 };
            result = [pscustomobject]@{
                content = @([pscustomobject]@{ type = 'text'; text = 'native fallback' });
                details = [pscustomobject]@{
                    schema_version = 1; ok = $false; status = 'partial'; reason_code = 'graph_gap';
                    fallback = 'native'; data = $null
                };
                isError = $true
            }
        } | ConvertTo-Json -Depth 12 -Compress),
        ([pscustomobject]@{
            type = 'message_end'; message = [pscustomobject]@{
                role = 'assistant'; provider = 'omniroute'; model = 'codex/gpt-5.6-sol';
                content = @([pscustomobject]@{ type = 'text'; text = '{"facts":[],"completed":false,"absence_claims":[]}' });
                usage = [pscustomobject]@{ input = 12; output = 4; cacheRead = 2 }
            }
        } | ConvertTo-Json -Depth 12 -Compress)
    ) -join "`n"
    $ompProjection = ConvertFrom-Topic05BenchmarkOmpJsonLines -Stdout $ompLines `
        -RequestedModel 'omniroute/codex/gpt-5.6-sol' -Scope core
    Assert-Topic05BenchmarkTest ($ompProjection.status -ceq 'COMPLETED' -and
        $ompProjection.tool_calls -eq 2 -and $ompProjection.codegraph_calls -eq 1 -and
        $ompProjection.codegraph_completed -eq 0 -and
        (@($ompProjection.codegraph_fallback_reasons) -join '|') -ceq 'graph_gap' -and
        $ompProjection.lead_reread.source_ranges -eq 1 -and
        $ompProjection.lead_reread.source_bytes -gt 0 -and
        $ompProjection.usage.core_workflow_tokens -eq 16) `
        'OMP JSONL projection lost tool, graph-fallback, reread, or usage evidence.'

    $nativeRoot = Join-Path $planRoot 'native-boundary'
    [void](New-Topic05BenchmarkMaterializedFixture -Fixture $registry.fixtures[0] `
        -LiteralPath $nativeRoot -Capability native)
    Assert-Topic05BenchmarkTest (Test-Path -LiteralPath (Join-Path $nativeRoot '.git') -PathType Container) `
        'Deterministic fixture materializer did not create a real Git repository.'
    Assert-Topic05BenchmarkTest (Test-Topic05BenchmarkNativeBoundary -RepositoryRoot $nativeRoot `
        -Controls $registry.contamination_controls -Environment @{}) `
        'Clean native target failed contamination validation.'
    Assert-Topic05BenchmarkTest (-not (Test-Topic05BenchmarkNativeBoundary -RepositoryRoot $nativeRoot `
        -Controls $registry.contamination_controls -Environment @{ CODEGRAPH_DIR = '.codegraph' })) `
        'Inherited CODEGRAPH environment contamination was accepted.'

    $deterministicRoot = New-Topic05BenchmarkTestRoot
    $deterministicOutput = Join-Path $deterministicRoot 'records'
    $deterministicPlan = New-Topic05BenchmarkPlan -Registry $registry -Pairs 1 -Seed 20260813 `
        -OutputDirectory $deterministicOutput
    $startsBefore = Get-Topic05BenchmarkModelProcessStartCount
    $records = @(Invoke-Topic05DeterministicBenchmark -Registry $registry -Plan $deterministicPlan)
    Assert-Topic05BenchmarkTest ($records.Count -eq 54 -and
        @(Get-ChildItem -LiteralPath (Join-Path $deterministicOutput $deterministicPlan.campaign_id) `
            -Filter '*.json' -File).Count -eq 54) `
        'Deterministic campaign did not write 54 immutable records.'
    Assert-Topic05BenchmarkTest ((Get-Topic05BenchmarkModelProcessStartCount) -eq $startsBefore) `
        'Deterministic mode started a model process.'
    foreach ($deterministicRecord in $records) {
        Assert-Topic05BenchmarkTest (Test-Topic05BenchmarkRunRecord $deterministicRecord) `
            "Deterministic run record failed validation: $($deterministicRecord.order)"
        Assert-Topic05BenchmarkTest ($deterministicRecord.usage.raw_total_tokens -ceq 'not_measured') `
            'Deterministic record invented model token usage.'
    }
    foreach ($fixture in @($registry.fixtures)) {
        $hashes = @($records | Where-Object fixture_id -CEQ $fixture.fixture_id |
            Select-Object -ExpandProperty snapshot_hash -Unique)
        Assert-Topic05BenchmarkTest ($hashes.Count -eq 1) `
            "Capability targets did not share one frozen snapshot: $($fixture.fixture_id)"
    }
    $report = Get-Topic05BenchmarkComparisonReport -Records $records
    Assert-Topic05BenchmarkTest (($report.comparisons -join '|') -ceq
        'A_vs_B|C_vs_D|A_vs_C|B_vs_D' -and $report.cold_warm_separate -eq $true -and
        $report.recommendation -ceq 'inconclusive' -and $report.universal_default -eq $false -and
        $null -eq $report.codegraph_percentage_threshold) `
        'Comparison report crossed route-specific promotion boundaries.'
    Assert-Topic05BenchmarkTest ($report.paired_group_count -eq 9 -and
        $report.excluded_group_count -eq 0) 'Reporter did not form nine exact paired fixture groups.'
    $measuredRecommendation = @($records | ForEach-Object { Copy-Topic05BenchmarkJson $_ })
    foreach ($measuredRecord in @($measuredRecommendation | Where-Object {
            $_.fixture_class -ceq 'multi_file_call_path'
        })) {
        $coreTokens = switch ([string]$measuredRecord.arm) {
            'A_lead_native' { 100 }
            'B_lead_codegraph' { if ($measuredRecord.cache_condition -ceq 'cold') { 80 } else { 70 } }
            'C_scout_native_lead' { 100 }
            'D_scout_codegraph_lead' { if ($measuredRecord.cache_condition -ceq 'cold') { 70 } else { 60 } }
        }
        $scoutTokens = if ([string]$measuredRecord.arm -in @(
                'C_scout_native_lead', 'D_scout_codegraph_lead'
            )) { 200 } else { 0 }
        $measuredRecord.usage.core_workflow_tokens = $coreTokens
        $measuredRecord.usage.cheap_scout_tokens = $scoutTokens
        $measuredRecord.usage.raw_total_tokens = $coreTokens + $scoutTokens
        $measuredRecord.usage.cache_read_tokens = 0
        $measuredRecord.usage.residual_context_tokens = 40
        $measuredRecord.usage.provider_reported = $true
        $measuredRecord.record_hash = Get-Topic05BenchmarkRecordHash $measuredRecord
    }
    $measuredReport = Get-Topic05BenchmarkComparisonReport -Records $measuredRecommendation
    Assert-Topic05BenchmarkTest ($measuredReport.recommendation -ceq
        'both_for_named_task_classes' -and
        (@($measuredReport.route_task_classes.B) -join '|') -ceq 'multi_file_call_path' -and
        (@($measuredReport.route_task_classes.D) -join '|') -ceq 'multi_file_call_path' -and
        $measuredReport.scope -ceq 'route_and_task_class_only' -and
        $measuredReport.promotion -eq $false) `
        'Reporter did not keep a strict improvement route- and task-class-specific.'
    $snapshotMismatch = @($records | ForEach-Object { Copy-Topic05BenchmarkJson $_ })
    foreach ($roundTripRecord in $snapshotMismatch) {
        $roundTripHash = Get-Topic05BenchmarkRecordHash $roundTripRecord
        $originalForRoundTrip = @($records | Where-Object order -EQ $roundTripRecord.order)[0]
        $originalPayload = Get-Topic05BenchmarkRecordCanonicalPayload $originalForRoundTrip
        $roundTripPayload = Get-Topic05BenchmarkRecordCanonicalPayload $roundTripRecord
        $differenceIndex = 0
        while ($differenceIndex -lt [Math]::Min($originalPayload.Length, $roundTripPayload.Length) -and
            $originalPayload[$differenceIndex] -ceq $roundTripPayload[$differenceIndex]) {
            $differenceIndex++
        }
        $differenceContext = if ($differenceIndex -lt [Math]::Max(
                $originalPayload.Length,
                $roundTripPayload.Length
            )) {
            $start = [Math]::Max(0, $differenceIndex - 30)
            "orig=$($originalPayload.Substring($start, [Math]::Min(100, $originalPayload.Length - $start))) copy=$($roundTripPayload.Substring($start, [Math]::Min(100, $roundTripPayload.Length - $start)))"
        } else { 'no textual difference' }
        Assert-Topic05BenchmarkTest ($roundTripHash -ceq
            [string]$roundTripRecord.record_hash) `
            "Run-record JSON round trip changed hash input: $($roundTripRecord.order)/$($roundTripRecord.arm)/$($roundTripRecord.cache_condition) stored=$($roundTripRecord.record_hash) actual=$roundTripHash $differenceContext"
    }
    $snapshotMismatch[0].snapshot_hash = (('0' * 64) -join '')
    $snapshotMismatch[0].contamination.snapshot_match = $true
    $snapshotMismatch[0].record_hash = Get-Topic05BenchmarkRecordHash $snapshotMismatch[0]
    Assert-Topic05BenchmarkThrows -Pattern '*snapshot mismatch*' `
        -Message 'Reporter compared mismatched fixture snapshots.' -Body {
        Get-Topic05BenchmarkComparisonReport -Records $snapshotMismatch | Out-Null
    }

    $scoutExecution = @($plan.executions | Where-Object arm -CEQ 'C_scout_native_lead')[0]
    $scoutFixture = @($registry.fixtures | Where-Object fixture_id -CEQ $scoutExecution.fixture_id)[0]
    $invalidScoutIdentity = New-Topic05BenchmarkRunRecord -Execution $scoutExecution -Fixture $scoutFixture
    $invalidScoutIdentity.actor_identity.scout_resolved = 'omniroute/codex/gpt-5.6-sol'
    $invalidScoutIdentity.record_hash = Get-Topic05BenchmarkRecordHash $invalidScoutIdentity
    Assert-Topic05BenchmarkThrows -Pattern '*Flash-to-Pro-only*' `
        -Message 'A premium model was accepted as Cheap Scout.' -Body {
        Test-Topic05BenchmarkRunRecord $invalidScoutIdentity | Out-Null
    }
    $existingRecordPath = $deterministicPlan.executions[0].output_path
    Assert-Topic05BenchmarkThrows -Pattern '*already exists*' `
        -Message 'Immutable run record was overwritten.' -Body {
        Write-Topic05BenchmarkRunRecord -Record $records[0] -LiteralPath $existingRecordPath
    }
    Assert-Topic05BenchmarkThrows -Pattern '*immutable output already exists*' `
        -Message 'A colliding deterministic campaign was not rejected in preflight.' -Body {
        Invoke-Topic05DeterministicBenchmark -Registry $registry -Plan $deterministicPlan | Out-Null
    }

    $runnerOutput = Join-Path $planRoot 'runner-plan-output'
    $runnerText = @(& pwsh -NoProfile -File $runnerPath -Mode plan -Pairs 1 -Seed 20260813 `
        -OutputDirectory $runnerOutput 2>&1) -join [Environment]::NewLine
    Assert-Topic05BenchmarkTest ($LASTEXITCODE -eq 0 -and $runnerText -match 'executions: 54' -and
        $runnerText -match 'no repositories, credentials, or model processes') `
        "Runner plan mode failed: $runnerText"
    Assert-Topic05BenchmarkTest (-not (Test-Path -LiteralPath $runnerOutput)) `
        'Runner plan mode wrote output bytes.'
    $blockedOutput = Join-Path $planRoot 'blocked-model-output'
    $blockedText = @(& pwsh -NoProfile -File $runnerPath -Mode model-pilot -Pairs 1 `
        -Seed 20260813 -OutputDirectory $blockedOutput -Confirmation RUN_TOPIC05_MODEL_PILOT `
        -LeadModel 'omniroute/codex/gpt-5.6-sol:xhigh' 2>&1) -join [Environment]::NewLine
    Assert-Topic05BenchmarkTest ($LASTEXITCODE -ne 0 -and $blockedText -match 'AllowModelSpend') `
        'Runner model-pilot did not fail before spend without the explicit switch.'
    Assert-Topic05BenchmarkTest (-not (Test-Path -LiteralPath $blockedOutput)) `
        'Blocked runner model-pilot wrote campaign bytes.'

    Write-Host "PASS Topic 05 benchmark tests ($script:Assertions assertions)" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL [T05-BENCHMARK] line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" `
        -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in @($script:Roots)) {
        $resolved = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 05 benchmark test cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
