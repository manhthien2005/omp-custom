#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Round0912Result {
    param(
        [ValidateSet('PASS', 'WARN', 'FAIL')][string]$Status,
        [ValidatePattern('^R0912-')][string]$Code,
        [Parameter(Mandatory)][string]$Message
    )
    return [pscustomobject]@{ Status = $Status; Code = $Code; Message = $Message }
}

function New-Round0912BooleanResult {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$PassMessage,
        [Parameter(Mandatory)][string]$FailMessage
    )
    return New-Round0912Result -Status $(if ($Condition) { 'PASS' } else { 'FAIL' }) -Code $Code `
        -Message $(if ($Condition) { $PassMessage } else { $FailMessage })
}

function Get-Round0912GovernedFiles {
    return @(
        '.gitignore'
        'scripts/lib/round09-12-evaluation-core.mjs'
        'scripts/run-round09-12-evaluation.ps1'
        'scripts/benchmark.ps1'
        'scripts/lib/round09-12-release-readiness.ps1'
        'scripts/validate-round09-12-release-readiness.ps1'
        'scripts/validate-template.ps1'
        'scripts/capture-round09-12-evidence.ps1'
        'scripts/tests/round09-12-evaluation-core.Tests.mjs'
        'scripts/tests/round09-12-review-security.Tests.mjs'
        'scripts/tests/round09-12-installer.Tests.ps1'
        'scripts/tests/round09-12-validator-mutations.Tests.ps1'
        'scripts/tests/fixtures/round09-12-fake-omp.mjs'
        'evals/round09-12/manifest.json'
        'evals/round09-12/cases/quality-security.json'
        'evals/round09-12/cases/promotion.json'
        'evals/round09-12/cases/package.json'
        'spec/key/04-decision-log.md'
        'spec/10-verification-and-review.md'
        'spec/15-security-and-failure-recovery.md'
        'spec/13-validation-and-evaluation.md'
        'spec/12-installation-and-rollback.md'
        'spec/16-migration-plan.md'
        'spec/phases/phase-04-quality-system.md'
        'spec/phases/phase-05-installation-hardening.md'
        'spec/phases/phase-06-evaluation.md'
        'spec/phases/phase-07-stabilization.md'
        'README.md'
        'docs/architecture.md'
        'docs/security.md'
        'docs/installation.md'
        'docs/rollback.md'
        'docs/final-report.md'
        'docs/workflow-v0.md'
        'codex-round09-12-closure-evaluation-release-readiness-changelog.md'
        'docs/evidence/current-product/round-09-12/quality.json'
        'docs/evidence/current-product/round-09-12/security.json'
        'docs/evidence/current-product/round-09-12/evaluation.json'
        'docs/evidence/current-product/round-09-12/release-readiness.json'
        'docs/evidence/current-product/round-09-12/manifest.json'
    )
}

function Get-Round0912Text {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$RelativePath)
    $path = Join-Path $Root ($RelativePath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { return Get-Content -Raw -LiteralPath $path -Encoding UTF8 } catch { return $null }
}

function Get-Round0912Json {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$RelativePath)
    $text = Get-Round0912Text -Root $Root -RelativePath $RelativePath
    if ($null -eq $text) { return $null }
    try { return $text | ConvertFrom-Json -AsHashtable } catch { return $null }
}

function Test-Round0912ContainsAll {
    param([AllowNull()][string]$Text, [Parameter(Mandatory)][string[]]$Needles)
    if ($null -eq $Text) { return $false }
    foreach ($needle in $Needles) {
        if (-not $Text.Contains($needle, [StringComparison]::Ordinal)) { return $false }
    }
    return $true
}

function Get-Round0912Sha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-Round0912ExactKeys {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory)][string[]]$Expected
    )
    if ($Value -isnot [Collections.IDictionary]) { return $false }
    $actualKeys = @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    $expectedKeys = @($Expected | Sort-Object)
    return ($actualKeys -join '|') -ceq ($expectedKeys -join '|')
}

function Test-Round0912Sha256Value {
    param([AllowNull()][object]$Value)
    return $Value -is [string] -and ([string]$Value) -cmatch '^[a-f0-9]{64}$'
}

function Test-Round0912CommandReceipts {
    param([AllowNull()][object]$Receipts)
    $rows = @($Receipts)
    if ($rows.Count -lt 1) { return $false }
    foreach ($row in $rows) {
        if (-not (Test-Round0912ExactKeys -Value $row -Expected @(
            'name', 'command', 'exit_code', 'status', 'stdout_sha256', 'stderr_sha256'
        ))) { return $false }
        if ([string]::IsNullOrWhiteSpace([string]$row.name) -or
            [string]::IsNullOrWhiteSpace([string]$row.command) -or
            [int]$row.exit_code -ne 0 -or [string]$row.status -cne 'PASS' -or
            -not (Test-Round0912Sha256Value -Value $row.stdout_sha256) -or
            -not (Test-Round0912Sha256Value -Value $row.stderr_sha256)) { return $false }
    }
    return $true
}

function Invoke-Round0912CoreProbe {
    param([Parameter(Mandatory)][string]$Root)
    $corePath = Join-Path $Root 'scripts\lib\round09-12-evaluation-core.mjs'
    $manifestPath = Join-Path $Root 'evals\round09-12\manifest.json'
    if (-not (Test-Path -LiteralPath $corePath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        return [pscustomobject]@{ Ok = $false; Core = $false; Fixtures = $false; Promotion = $false; Secret = $false; Message = 'Core or fixture manifest is missing.' }
    }
    $program = @'
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";
const [corePath, manifestPath] = process.argv.slice(1);
let outputRoot;
try {
  const core = await import(pathToFileURL(corePath).href + `?round0912=${Date.now()}`);
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const manifestResult = core.validateFixtureManifest(manifest);
  outputRoot = fs.mkdtempSync(path.join(os.tmpdir(), "round0912-validator-core-"));
  const outputPath = path.join(outputRoot, "result.json");
  const run = manifestResult.ok
    ? await core.runDeterministicCli(["--fixture-manifest", manifestPath, "--output", outputPath])
    : null;
  const verdicts = JSON.stringify(core.PROMOTION_VERDICTS) === JSON.stringify([
    "PROMOTE_EFFICIENCY", "PROMOTE_QUALITY", "REJECT", "DEFER_INCONCLUSIVE",
  ]);
  const ids = run?.cases?.map((row) => row.id) ?? [];
  const secret = run?.cases?.some((row) => row.id === "S-SECRET-EVIDENCE" && row.status === "PASS") === true;
  const promotionIds = ["E-MISSING-TELEMETRY", "E-PILOT-CANNOT-PROMOTE", "E-EFFICIENCY-WIN", "E-QUALITY-WIN", "E-POSTHOC-THRESHOLD"];
  const promotion = verdicts && promotionIds.every((id) => run?.cases?.some((row) => row.id === id && row.status === "PASS"));
  const fixtures = manifestResult.ok && ids.length === 14 && new Set(ids).size === 14 && run?.status === "PASS";
  process.stdout.write(JSON.stringify({ ok: fixtures && promotion && secret, core: verdicts, fixtures, promotion, secret, message: "ok" }));
} catch {
  process.stdout.write(JSON.stringify({ ok: false, core: false, fixtures: false, promotion: false, secret: false, message: "semantic probe failed" }));
} finally {
  if (outputRoot && path.basename(outputRoot).startsWith("round0912-validator-core-") && outputRoot.startsWith(path.resolve(os.tmpdir()) + path.sep)) {
    fs.rmSync(outputRoot, { recursive: true, force: true });
  }
}
'@
    $output = @(& node --input-type=module -e $program $corePath $manifestPath 2>&1)
    if ($LASTEXITCODE -ne 0 -or $output.Count -ne 1) {
        return [pscustomobject]@{ Ok = $false; Core = $false; Fixtures = $false; Promotion = $false; Secret = $false; Message = 'Core probe process failed.' }
    }
    try {
        $result = ([string]$output[0]) | ConvertFrom-Json -AsHashtable
        return [pscustomobject]@{
            Ok = [bool]$result.ok
            Core = [bool]$result.core
            Fixtures = [bool]$result.fixtures
            Promotion = [bool]$result.promotion
            Secret = [bool]$result.secret
            Message = [string]$result.message
        }
    } catch {
        return [pscustomobject]@{ Ok = $false; Core = $false; Fixtures = $false; Promotion = $false; Secret = $false; Message = 'Core probe returned invalid JSON.' }
    }
}

function Invoke-Round0912RunnerProbe {
    param([Parameter(Mandatory)][string]$Root)
    $runnerPath = Join-Path $Root 'scripts\run-round09-12-evaluation.ps1'
    $fakePath = Join-Path $Root 'scripts\tests\fixtures\round09-12-fake-omp.mjs'
    if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $fakePath -PathType Leaf)) {
        return [pscustomobject]@{ Deterministic = $false; Trust = $false; Message = 'Runner or fake runtime is missing.' }
    }
    $roots = [Collections.Generic.List[string]]::new()
    try {
        $deterministicRoot = Join-Path ([IO.Path]::GetTempPath()) ('round0912-validator-runner-' + [guid]::NewGuid().ToString('N'))
        $noAuthorityRoot = Join-Path ([IO.Path]::GetTempPath()) ('round0912-validator-runner-' + [guid]::NewGuid().ToString('N'))
        [void](New-Item -ItemType Directory -Path $deterministicRoot)
        [void](New-Item -ItemType Directory -Path $noAuthorityRoot)
        [void]$roots.Add([IO.Path]::GetFullPath($deterministicRoot))
        [void]$roots.Add([IO.Path]::GetFullPath($noAuthorityRoot))

        $deterministicOutput = @(& pwsh -NoLogo -NoProfile -File $runnerPath `
            -Mode Deterministic -OutputDirectory $deterministicRoot 2>&1)
        $deterministicExit = $LASTEXITCODE
        $deterministicRecord = Get-Round0912Json -Root $deterministicRoot -RelativePath 'round09-12-evaluation.json'
        $deterministic = $deterministicExit -eq 0 -and $null -ne $deterministicRecord -and
            [string]$deterministicRecord.mode -ceq 'deterministic' -and
            [int]$deterministicRecord.provider_calls -eq 0 -and
            [int]$deterministicRecord.model_processes_started -eq 0

        $noAuthorityOutput = @(& pwsh -NoLogo -NoProfile -File $runnerPath -Mode Campaign `
            -OutputDirectory $noAuthorityRoot -OmpPath $fakePath -EvidenceBudget 1 2>&1)
        $noAuthorityExit = $LASTEXITCODE
        $noAuthorityRecord = Get-Round0912Json -Root $noAuthorityRoot -RelativePath 'round09-12-evaluation.json'
        $trust = $noAuthorityExit -eq 3 -and $null -ne $noAuthorityRecord -and
            [string]$noAuthorityRecord.environment_status -ceq 'NOT_RUN' -and
            @($noAuthorityRecord.reasons).Count -eq 1 -and
            [string]$noAuthorityRecord.reasons[0] -ceq 'provider_calls_not_authorized' -and
            [int]$noAuthorityRecord.runtime_processes_started -eq 0
        return [pscustomobject]@{ Deterministic = $deterministic; Trust = $trust; Message = 'Runner probes completed.' }
    } catch {
        return [pscustomobject]@{ Deterministic = $false; Trust = $false; Message = 'Runner probe failed.' }
    } finally {
        foreach ($fixtureRoot in $roots) {
            $resolved = [IO.Path]::GetFullPath($fixtureRoot)
            $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
            if (-not $resolved.StartsWith($temp + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
                [IO.Path]::GetFileName($resolved) -notlike 'round0912-validator-runner-*') {
                throw "Refusing unsafe Round 09-12 runner-probe cleanup: $resolved"
            }
            if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
        }
    }
}

function Test-Round0912EvidenceBundle {
    param([Parameter(Mandatory)][string]$Root)
    $directory = Join-Path $Root 'docs\evidence\current-product\round-09-12'
    $manifest = Get-Round0912Json -Root $Root -RelativePath 'docs/evidence/current-product/round-09-12/manifest.json'
    if (-not (Test-Round0912ExactKeys -Value $manifest -Expected @(
        'schema_version', 'record_type', 'generated_at_utc', 'status', 'provider_calls',
        'model_processes_started', 'files', 'governed_files'
    )) -or [int]$manifest.schema_version -ne 1 -or
        [string]$manifest.record_type -cne 'round0912_current_product_manifest' -or
        [string]$manifest.status -cne 'PASS' -or [int]$manifest.provider_calls -ne 0 -or
        [int]$manifest.model_processes_started -ne 0) { return $false }

    $typeByName = [ordered]@{
        'quality.json' = 'round0912_quality_evidence'
        'security.json' = 'round0912_security_evidence'
        'evaluation.json' = 'round0912_evaluation_evidence'
        'release-readiness.json' = 'round0912_release_readiness'
    }
    $expected = @($typeByName.Keys)
    $rows = @($manifest.files)
    $actualEvidencePaths = @($rows | ForEach-Object { [string]$_.path } | Sort-Object) -join '|'
    $expectedEvidencePaths = @($expected | Sort-Object) -join '|'
    if ($actualEvidencePaths -cne $expectedEvidencePaths) { return $false }
    foreach ($row in $rows) {
        if (-not (Test-Round0912ExactKeys -Value $row -Expected @('path', 'sha256', 'record_type')) -or
            -not $typeByName.Contains([string]$row.path) -or
            [string]$row.record_type -cne [string]$typeByName[[string]$row.path]) { return $false }
        $path = Join-Path $directory ([string]$row.path)
        $hash = Get-Round0912Sha256 -LiteralPath $path
        if ($null -eq $hash -or -not (Test-Round0912Sha256Value -Value $row.sha256) -or
            $hash -cne [string]$row.sha256) { return $false }
    }

    $quality = Get-Round0912Json -Root $Root -RelativePath 'docs/evidence/current-product/round-09-12/quality.json'
    if (-not (Test-Round0912ExactKeys -Value $quality -Expected @(
        'schema_version', 'record_type', 'generated_at_utc', 'status', 'provider_calls',
        'model_processes_started', 'scope', 'case_ids', 'commands'
    )) -or [int]$quality.schema_version -ne 1 -or
        [string]$quality.record_type -cne 'round0912_quality_evidence' -or
        [string]$quality.status -cne 'PASS' -or [int]$quality.provider_calls -ne 0 -or
        [int]$quality.model_processes_started -ne 0 -or
        [string]$quality.scope -cne 'deterministic_current_product' -or
        (@($quality.case_ids) -join '|') -cne 'Q-VALID-REVIEW|Q-MISSING-INDEPENDENT-REVIEW|Q-STALE-CANDIDATE|Q-FALSE-COMPLETION' -or
        -not (Test-Round0912CommandReceipts -Receipts $quality.commands)) { return $false }

    $security = Get-Round0912Json -Root $Root -RelativePath 'docs/evidence/current-product/round-09-12/security.json'
    if (-not (Test-Round0912ExactKeys -Value $security -Expected @(
        'schema_version', 'record_type', 'generated_at_utc', 'status', 'provider_calls',
        'model_processes_started', 'scope', 'case_ids', 'commands'
    )) -or [int]$security.schema_version -ne 1 -or
        [string]$security.record_type -cne 'round0912_security_evidence' -or
        [string]$security.status -cne 'PASS' -or [int]$security.provider_calls -ne 0 -or
        [int]$security.model_processes_started -ne 0 -or
        [string]$security.scope -cne 'deterministic_current_product' -or
        (@($security.case_ids) -join '|') -cne 'S-SECRET-EVIDENCE|S-DESTRUCTIVE-NO-AUTHORITY|S-DUPLICATE-SIDE-EFFECT-RETRY|S-PARTIAL-OUTPUT' -or
        -not (Test-Round0912CommandReceipts -Receipts $security.commands)) { return $false }

    $evaluation = Get-Round0912Json -Root $Root -RelativePath 'docs/evidence/current-product/round-09-12/evaluation.json'
    if (-not (Test-Round0912ExactKeys -Value $evaluation -Expected @(
        'schema_version', 'record_type', 'generated_at_utc', 'status', 'provider_calls',
        'model_processes_started', 'deterministic', 'campaign', 'commands'
    )) -or [int]$evaluation.schema_version -ne 1 -or
        [string]$evaluation.record_type -cne 'round0912_evaluation_evidence' -or
        [string]$evaluation.status -cne 'PASS' -or [int]$evaluation.provider_calls -ne 0 -or
        [int]$evaluation.model_processes_started -ne 0 -or
        -not (Test-Round0912ExactKeys -Value $evaluation.deterministic -Expected @(
            'status', 'environment_status', 'cases_passed', 'verdicts'
        )) -or [string]$evaluation.deterministic.status -cne 'PASS' -or
        [string]$evaluation.deterministic.environment_status -cne 'PASS' -or
        [int]$evaluation.deterministic.cases_passed -ne 14 -or
        (@($evaluation.deterministic.verdicts) -join '|') -cne 'PROMOTE_EFFICIENCY|PROMOTE_QUALITY|REJECT|DEFER_INCONCLUSIVE' -or
        -not (Test-Round0912ExactKeys -Value $evaluation.campaign -Expected @(
            'environment_status', 'promotion_verdict', 'reasons'
        )) -or [string]$evaluation.campaign.environment_status -cne 'NOT_RUN' -or
        [string]$evaluation.campaign.promotion_verdict -cne 'DEFER_INCONCLUSIVE' -or
        (@($evaluation.campaign.reasons) -join '|') -cne 'model_assisted_campaign_not_authorized' -or
        -not (Test-Round0912CommandReceipts -Receipts $evaluation.commands)) { return $false }

    $release = Get-Round0912Json -Root $Root -RelativePath 'docs/evidence/current-product/round-09-12/release-readiness.json'
    if (-not (Test-Round0912ExactKeys -Value $release -Expected @(
        'schema_version', 'record_type', 'generated_at_utc', 'status', 'provider_calls',
        'model_processes_started', 'live_install_performed', 'scratch_package', 'adapters',
        'campaign', 'limitations', 'commands'
    )) -or [int]$release.schema_version -ne 1 -or
        [string]$release.record_type -cne 'round0912_release_readiness' -or
        [string]$release.status -cne 'IMPLEMENTED_NOT_PROMOTED' -or
        [int]$release.provider_calls -ne 0 -or [int]$release.model_processes_started -ne 0 -or
        $release.live_install_performed -ne $false -or
        -not (Test-Round0912ExactKeys -Value $release.scratch_package -Expected @(
            'status', 'omp_version', 'assertions', 'live_target_modified'
        )) -or [string]$release.scratch_package.status -cne 'PASS' -or
        [string]$release.scratch_package.omp_version -cne '17.2.12' -or
        [int]$release.scratch_package.assertions -ne 30 -or
        $release.scratch_package.live_target_modified -ne $false -or
        -not (Test-Round0912ExactKeys -Value $release.adapters -Expected @('omp', 'claude')) -or
        -not (Test-Round0912ExactKeys -Value $release.adapters.omp -Expected @('status', 'installable')) -or
        [string]$release.adapters.omp.status -cne 'IMPLEMENTED_NOT_PROMOTED' -or
        $release.adapters.omp.installable -ne $true -or
        -not (Test-Round0912ExactKeys -Value $release.adapters.claude -Expected @('status', 'installable')) -or
        [string]$release.adapters.claude.status -cne 'DESIGNED_NOT_VERIFIED' -or
        $release.adapters.claude.installable -ne $false -or
        -not (Test-Round0912ExactKeys -Value $release.campaign -Expected @('environment_status', 'promotion_verdict')) -or
        [string]$release.campaign.environment_status -cne 'NOT_RUN' -or
        [string]$release.campaign.promotion_verdict -cne 'DEFER_INCONCLUSIVE' -or
        (@($release.limitations) -join '|') -cne 'OMP_17_2_10_NOT_AVAILABLE|CLAUDE_RUNTIME_NOT_VERIFIED|MODEL_ASSISTED_ARMS_NOT_RUN|SCRATCH_PROOF_NOT_LIVE_INSTALL' -or
        -not (Test-Round0912CommandReceipts -Receipts $release.commands)) { return $false }

    $expectedGoverned = @(Get-Round0912GovernedFiles | Where-Object {
        -not ([string]$_).StartsWith('docs/evidence/current-product/round-09-12/', [StringComparison]::Ordinal)
    } | Sort-Object)
    $governedRows = @($manifest.governed_files)
    $actualGovernedPaths = @($governedRows | ForEach-Object { [string]$_.path } | Sort-Object) -join '|'
    $expectedGovernedPaths = $expectedGoverned -join '|'
    if ($actualGovernedPaths -cne $expectedGovernedPaths) { return $false }
    foreach ($row in $governedRows) {
        if (-not (Test-Round0912ExactKeys -Value $row -Expected @('path', 'sha256'))) { return $false }
        $governedPath = Join-Path $Root (([string]$row.path) -replace '/', '\')
        $hash = Get-Round0912Sha256 -LiteralPath $governedPath
        if ($null -eq $hash -or -not (Test-Round0912Sha256Value -Value $row.sha256) -or
            $hash -cne [string]$row.sha256) { return $false }
    }
    return $true
}

function Test-Round0912ReleaseReadiness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [switch]$SkipEvidence,
        [switch]$SkipRuntime,
        [switch]$SkipDocumentation
    )
    $root = [IO.Path]::GetFullPath($RepositoryRoot)
    $results = [Collections.Generic.List[object]]::new()
    $core = Invoke-Round0912CoreProbe -Root $root
    $runner = Invoke-Round0912RunnerProbe -Root $root

    [void]$results.Add((New-Round0912BooleanResult -Condition $core.Fixtures -Code 'R0912-Q-CONTRACT' `
        -PassMessage 'Closed task-cycle and adversarial quality contracts execute deterministically.' `
        -FailMessage 'The closed quality/task-cycle contract or its deterministic cases failed.'))

    $reviewerText = Get-Round0912Text -Root $root -RelativePath 'template/.omp/agents/reviewer.md'
    $qualitySpec = Get-Round0912Text -Root $root -RelativePath 'spec/10-verification-and-review.md'
    $severityValid = (Test-Round0912ContainsAll -Text $reviewerText -Needles @(
        'enum: [critical, important, minor]',
        'Any `critical`/`important` finding requires `CHANGES_REQUESTED`',
        '`APPROVED_WITH_NOTES` has minor findings only.'
    )) -and (Test-Round0912ContainsAll -Text $qualitySpec -Needles @(
        '<!-- round09-12-projection:quality -->',
        '| `critical` | blocks;',
        '| `important` | blocks;',
        '| `minor` | non-blocking note;'
    )) -and -not $qualitySpec.Contains('| `BLOCKING` | Blocks acceptance', [StringComparison]::Ordinal)
    [void]$results.Add((New-Round0912BooleanResult -Condition $severityValid -Code 'R0912-Q-SEVERITY' `
        -PassMessage 'Reviewer and active quality authority share critical/important/minor semantics.' `
        -FailMessage 'Reviewer severity or active quality authority still conflicts.'))

    $topic04Text = Get-Round0912Text -Root $root -RelativePath 'scripts/lib/topic04-durable-state.ps1'
    $evidenceValid = $core.Fixtures -and (Test-Round0912ContainsAll -Text $qualitySpec -Needles @(
        '<!-- round09-12-projection:quality -->',
        'Every candidate mutation invalidates prior acceptance-bearing proof',
        'never reuses approval'
    )) -and (Test-Round0912ContainsAll -Text $topic04Text -Needles @(
        'old candidate evidence cannot be accepted after mutation',
        'a new C2 candidate needs new applicable evidence',
        'T04-CANDIDATE-EVIDENCE'
    ))
    [void]$results.Add((New-Round0912BooleanResult -Condition $evidenceValid -Code 'R0912-Q-EVIDENCE' `
        -PassMessage 'Fresh review evidence stays bound to the current candidate and Topic 04 lifecycle.' `
        -FailMessage 'Candidate-bound review evidence or invalidation authority is incomplete.'))

    $reviewValid = $core.Fixtures -and (Test-Round0912ContainsAll -Text $qualitySpec -Needles @(
        '<!-- round09-12-projection:quality -->',
        'no permanent Verifier',
        'no universal Reviewer dispatch',
        'Opus is optional'
    ))
    [void]$results.Add((New-Round0912BooleanResult -Condition $reviewValid -Code 'R0912-Q-REVIEW' `
        -PassMessage 'Review is risk-selected, fresh, independent, and has no permanent Verifier or Opus gate.' `
        -FailMessage 'Review selection, freshness, or optional-fallback authority is incomplete.'))

    $ignoreText = Get-Round0912Text -Root $root -RelativePath '.gitignore'
    $ignoreValid = $null -ne $ignoreText -and
        $ignoreText.Contains('evals/results/', [StringComparison]::Ordinal) -and
        -not $ignoreText.Contains('evals/round09-12/', [StringComparison]::Ordinal) -and
        -not $ignoreText.Contains('docs/evidence/current-product/round-09-12/', [StringComparison]::Ordinal)
    [void]$results.Add((New-Round0912BooleanResult -Condition $ignoreValid -Code 'R0912-S-IGNORE' `
        -PassMessage 'Local campaign results are ignored while fixtures and bounded evidence remain governed.' `
        -FailMessage 'The local-result ignore boundary is missing or overbroad.'))

    [void]$results.Add((New-Round0912BooleanResult -Condition $core.Secret -Code 'R0912-S-SECRET' `
        -PassMessage 'Secret-shaped evidence is rejected without echo by the deterministic core.' `
        -FailMessage 'Secret rejection or no-echo behavior failed.'))

    $securitySpec = Get-Round0912Text -Root $root -RelativePath 'spec/15-security-and-failure-recovery.md'
    $recoveryValid = $core.Fixtures -and (Test-Round0912ContainsAll -Text $securitySpec -Needles @(
        '<!-- round09-12-projection:security -->',
        'S-DESTRUCTIVE-NO-AUTHORITY',
        'S-DUPLICATE-SIDE-EFFECT-RETRY',
        'S-PARTIAL-OUTPUT',
        'idempotent identity',
        'transactional'
    ))
    [void]$results.Add((New-Round0912BooleanResult -Condition $recoveryValid -Code 'R0912-S-RECOVERY' `
        -PassMessage 'Security/recovery authority maps deterministic refusal and transactional cases.' `
        -FailMessage 'Security/recovery projection is incomplete.'))

    [void]$results.Add((New-Round0912BooleanResult -Condition $runner.Trust -Code 'R0912-S-TRUST' `
        -PassMessage 'Campaign process start is refused without explicit provider authority.' `
        -FailMessage 'Campaign authority can be bypassed or starts a process before refusal.'))

    [void]$results.Add((New-Round0912BooleanResult -Condition $core.Core -Code 'R0912-E-CORE' `
        -PassMessage 'The closed evaluation core and four-verdict set load successfully.' `
        -FailMessage 'Evaluation core exports or verdict set drifted.'))
    [void]$results.Add((New-Round0912BooleanResult -Condition $core.Fixtures -Code 'R0912-E-FIXTURES' `
        -PassMessage 'All 14 versioned deterministic fixtures execute and pass.' `
        -FailMessage 'Fixture manifest, case identity, or deterministic result drifted.'))
    [void]$results.Add((New-Round0912BooleanResult -Condition $runner.Deterministic -Code 'R0912-E-RUNNER' `
        -PassMessage 'Default runner completes deterministically with zero provider/model processes.' `
        -FailMessage 'Default deterministic runner behavior failed.'))
    [void]$results.Add((New-Round0912BooleanResult -Condition $core.Promotion -Code 'R0912-E-PROMOTION' `
        -PassMessage 'Pilot, telemetry, sequential, efficiency, and quality promotion cases are closed.' `
        -FailMessage 'Promotion verdict machinery or hard-gate cases drifted.'))

    $phaseBindings = [ordered]@{
        'spec/key/04-decision-log.md' = '<!-- round09-12-authority:kd-032 -->'
        'spec/10-verification-and-review.md' = '<!-- round09-12-projection:quality -->'
        'spec/15-security-and-failure-recovery.md' = '<!-- round09-12-projection:security -->'
        'spec/13-validation-and-evaluation.md' = '<!-- round09-12-projection:evaluation -->'
        'spec/12-installation-and-rollback.md' = '<!-- round09-12-projection:release -->'
        'spec/16-migration-plan.md' = '<!-- round09-12-projection:release -->'
        'spec/phases/phase-04-quality-system.md' = '<!-- round09-12-projection:quality -->'
        'spec/phases/phase-05-installation-hardening.md' = '<!-- round09-12-projection:security -->'
        'spec/phases/phase-06-evaluation.md' = '<!-- round09-12-projection:evaluation -->'
        'spec/phases/phase-07-stabilization.md' = '<!-- round09-12-projection:release -->'
    }
    $phasesValid = $true
    foreach ($binding in $phaseBindings.GetEnumerator()) {
        $text = Get-Round0912Text -Root $root -RelativePath ([string]$binding.Key)
        if ($null -eq $text -or -not $text.Contains([string]$binding.Value, [StringComparison]::Ordinal)) {
            $phasesValid = $false
            break
        }
    }
    [void]$results.Add((New-Round0912BooleanResult -Condition $phasesValid -Code 'R0912-R-PHASES' `
        -PassMessage 'KD-032 and all active quality/security/evaluation/release phase projections are present.' `
        -FailMessage 'KD-032 or an active round phase projection is missing.'))

    $installerTest = Get-Round0912Text -Root $root -RelativePath 'scripts/tests/round09-12-installer.Tests.ps1'
    $packageValid = Test-Round0912ContainsAll -Text $installerTest -Needles @(
        'ROUND0912_SCRATCH_PACKAGE_PROOF',
        'IMPLEMENTED_NOT_PROMOTED',
        'DESIGNED_NOT_VERIFIED',
        'installable',
        'uninstall-template.ps1',
        'Operational agent-tasks state retained.'
    )
    [void]$results.Add((New-Round0912BooleanResult -Condition $packageValid -Code 'R0912-R-PACKAGE' `
        -PassMessage 'Scratch-only install/discovery/repair/uninstall/rollback proof is defined.' `
        -FailMessage 'Scratch package proof is missing or incomplete.'))

    $evidenceValid = $SkipEvidence -or (Test-Round0912EvidenceBundle -Root $root)
    [void]$results.Add((New-Round0912BooleanResult -Condition $evidenceValid -Code 'R0912-R-EVIDENCE' `
        -PassMessage $(if ($SkipEvidence) { 'Round evidence check explicitly skipped for transactional capture.' } else { 'Bounded round evidence files match their manifest hashes.' }) `
        -FailMessage 'Round evidence bundle is missing, malformed, or stale.'))

    $documentationValid = $true
    if (-not $SkipDocumentation) {
        foreach ($relative in @(
            'README.md', 'docs/architecture.md', 'docs/security.md', 'docs/installation.md',
            'docs/rollback.md', 'docs/final-report.md', 'docs/workflow-v0.md'
        )) {
            $text = Get-Round0912Text -Root $root -RelativePath $relative
            if ($null -eq $text -or -not $text.Contains('<!-- round09-12-projection:release-readiness -->', [StringComparison]::Ordinal)) {
                $documentationValid = $false
                break
            }
        }
        $changelog = Get-Round0912Text -Root $root -RelativePath 'codex-round09-12-closure-evaluation-release-readiness-changelog.md'
        $documentationValid = $documentationValid -and $null -ne $changelog -and
            $changelog.Contains('<!-- round09-12-projection:changelog -->', [StringComparison]::Ordinal)
    }
    [void]$results.Add((New-Round0912BooleanResult -Condition $documentationValid -Code 'R0912-R-DOCS' `
        -PassMessage $(if ($SkipDocumentation) { 'Round documentation check explicitly skipped.' } else { 'Operator documentation projects the truthful round status.' }) `
        -FailMessage 'Operator release-readiness projection is missing.'))

    return @($results)
}
