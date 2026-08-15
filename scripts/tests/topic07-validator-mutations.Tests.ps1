#Requires -Version 7.4
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repositoryRoot 'scripts\lib\topic07-context-continuity.ps1'
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) { throw 'Topic 07 validator helper is missing.' }
. $helperPath

$script:Assertions = 0
$script:FixtureRoots = [Collections.Generic.List[string]]::new()

function Assert-Topic07ValidatorMutation {
    param([bool]$Condition, [string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function New-Topic07ValidatorFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('omp-topic07-validator-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $root)
    [void]$script:FixtureRoots.Add([IO.Path]::GetFullPath($root))
    foreach ($relative in Get-Topic07ContextContinuityGovernedFiles) {
        if ($relative -like 'docs/evidence/current-product/topic-07/*') { continue }
        $source = Join-Path $repositoryRoot ($relative -replace '/', '\')
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Governed source is missing: $relative" }
        $destination = Join-Path $root ($relative -replace '/', '\')
        [void](New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force)
        Copy-Item -LiteralPath $source -Destination $destination
    }
    return $root
}

function Update-Topic07ValidatorFixture {
    param([string]$Root, [string]$RelativePath, [scriptblock]$Mutation)
    $path = Join-Path $Root ($RelativePath -replace '/', '\')
    $before = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $after = & $Mutation $before
    if ($after -ceq $before) { throw "Mutation did not change $RelativePath" }
    Set-Content -LiteralPath $path -Value $after -Encoding UTF8 -NoNewline
}

function Assert-Topic07MutationCaught {
    param([string]$Name, [string]$ExpectedCode, [string]$RelativePath, [scriptblock]$Mutation)
    $root = New-Topic07ValidatorFixture
    Update-Topic07ValidatorFixture -Root $root -RelativePath $RelativePath -Mutation $Mutation
    $failCodes = @(Test-Topic07ContextContinuityContract -RepositoryRoot $root -SkipEvidence -SkipRuntime |
        Where-Object Status -eq FAIL | ForEach-Object Code)
    Assert-Topic07ValidatorMutation ($failCodes -ccontains $ExpectedCode) `
        "[$Name] expected $ExpectedCode, got: $($failCodes -join ', ')"
}

try {
    $live = @(Test-Topic07ContextContinuityContract -RepositoryRoot $repositoryRoot -SkipEvidence -SkipRuntime)
    $liveFailures = @($live | Where-Object Status -eq FAIL)
    Assert-Topic07ValidatorMutation ($liveFailures.Count -eq 0) `
        "Live contract failures: $(($liveFailures | ForEach-Object Code) -join ', ')"

    $missingRoot = New-Topic07ValidatorFixture
    Remove-Item -LiteralPath (Join-Path $missingRoot 'docs\context-continuity.md') -Force
    $missingCodes = @(Test-Topic07ContextContinuityContract -RepositoryRoot $missingRoot -SkipEvidence -SkipRuntime |
        Where-Object Status -eq FAIL | ForEach-Object Code)
    Assert-Topic07ValidatorMutation ($missingCodes -ccontains 'T07-REQUIRED-FILES') `
        'A missing required operator surface was not rejected.'

    Assert-Topic07MutationCaught 'decision' 'T07-AUTHORITY-KD031' 'spec/key/04-decision-log.md' {
        param($t) $t.Replace('<!-- topic07-authority:kd-031 -->', '<!-- topic07-authority:missing -->')
    }
    Assert-Topic07MutationCaught 'automatic-path' 'T07-PROFILE' 'template/.omp/contracts/managed-runtime.yml' {
        param($t) $t.Replace('  enabled: false', '  enabled: true')
    }
    Assert-Topic07MutationCaught 'reserve-setting' 'T07-COMPONENT-MANIFEST' 'template/.omp/contracts/component-manifest.json' {
        param($t) $t.Replace('"pressure_default_reserve_tokens": 16384', '"pressure_default_reserve_tokens": 16384, "reserveTokens": 8192')
    }
    Assert-Topic07MutationCaught 'keep-recent' 'T07-PROFILE' 'template/.omp/contracts/managed-runtime.yml' {
        param($t) $t.Replace('keepRecentTokens: 20000', 'keepRecentTokens: 19000')
    }
    Assert-Topic07MutationCaught 'extension-order' 'T07-LAUNCHER-ORDER' 'template/.omp/bin/omp-managed.ps1' {
        param($t) $t.Replace("        [string]`$runtime.paths.continuity_adapter", "        [string]`$runtime.paths.wrapper")
    }
    Assert-Topic07MutationCaught 'no-session' 'T07-SESSION-OWNERSHIP' 'template/.omp/extensions/context-continuity.js' {
        param($t) $t.Replace('typeof sessionFile !== "string" || !path.isAbsolute(sessionFile)', 'false && typeof sessionFile !== "string" || !path.isAbsolute(sessionFile)')
    }
    Assert-Topic07MutationCaught 'command-arguments' 'T07-COMMAND-TRANSACTION' 'template/.omp/extensions/context-continuity.js' {
        param($t) $t.Replace('args.trim().length > 0', 'args.trim().length < 0')
    }
    Assert-Topic07MutationCaught 'exact-owner' 'T07-SESSION-OWNERSHIP' 'template/.omp/extensions/context-continuity.js' {
        param($t) $t.Replace('validated.value.lifecycle.owner_session_ref !== state.sessionId', 'false')
    }
    Assert-Topic07MutationCaught 'critical-field' 'T07-CONTINUITY-CORE' 'template/.omp/contracts/context-continuity-core.mjs' {
        param($t) $t.Replace('"task_id", "workflow_class", "objective"', '"workflow_class", "objective"')
    }
    Assert-Topic07MutationCaught 'standard-degradation' 'T07-CONTINUITY-CORE' 'template/.omp/contracts/context-continuity-core.mjs' {
        param($t) $t.Replace('kernel.task.workflow_class !== "quick" && fields.length > 0', 'kernel.task.workflow_class === "disabled" && fields.length > 0')
    }
    Assert-Topic07MutationCaught 'artifact-verification' 'T07-ARTIFACT-FIRST' 'template/.omp/extensions/context-continuity.js' {
        param($t) $t.Replace('savedBytes !== bytes || sha256Text(savedBytes.slice(0, -1)) !== sha256Text(recovery.canonical)', 'false')
    }
    Assert-Topic07MutationCaught 'raw-nonce-persistence' 'T07-NONCE-GATE' 'template/.omp/extensions/context-continuity.js' {
        param($t) $t.Replace(
            'recovery_artifact_sha256: epoch.recoveryArtifactSha256,',
            "recovery_artifact_sha256: epoch.recoveryArtifactSha256,`n    raw_nonce: epoch.rawNonce,"
        )
    }
    Assert-Topic07MutationCaught 'compact-without-nonce' 'T07-NONCE-GATE' 'template/.omp/extensions/context-continuity.js' {
        param($t) $t.Replace('!Buffer.isBuffer(epoch.rawNonce)) return { cancel: true };', 'false) return { cancel: true };')
    }
    Assert-Topic07MutationCaught 'hidden-continuation' 'T07-NO-CONTINUATION' 'template/.omp/extensions/context-continuity.js' {
        param($t) $t.Replace('await ctx.compact({ mode: "soft", onComplete, onError });', 'await ctx.compact({ mode: "soft", onComplete, onError }); await ctx.sendUserMessage("continue");')
    }
    Assert-Topic07MutationCaught 'pressure-abort' 'T07-PRESSURE-GUARD' 'template/.omp/extensions/context-continuity.js' {
        param($t) $t.Replace('if (!state.requestAborted) {', 'if (false && !state.requestAborted) {')
    }
    Assert-Topic07MutationCaught 'child-partial' 'T07-CHILD-SETTLEMENT' 'template/.omp/extensions/agent-task-boundary.js' {
        param($t) $t.Replace('if (marker === CONTEXT_PRESSURE_ABORT_MARKER &&', 'if (false && marker === CONTEXT_PRESSURE_ABORT_MARKER &&')
    }
    Assert-Topic07MutationCaught 'supported-versions' 'T07-COMPONENT-MANIFEST' 'template/.omp/contracts/component-manifest.json' {
        param($t) $t.Replace('"17.2.12"', '"17.2.13"')
    }
    Assert-Topic07MutationCaught 'source-pin' 'T07-SOURCE-POLICY' 'scripts/lib/topic07-context-continuity.ps1' {
        param($t) $t.Replace('3a8591a8af5b6d200088d12ca75a5517cb064fa8', '0000000000000000000000000000000000000000')
    }
    Assert-Topic07MutationCaught 'rollback-retention' 'T07-INSTALL-ROLLBACK' 'scripts/uninstall-template.ps1' {
        param($t) $t.Replace("            '.omp/extensions/context-continuity.js'", "            '.omp/extensions/context-continuity-disabled.js'")
    }
    Assert-Topic07MutationCaught 'false-promotion' 'T07-TRUTHFULNESS' 'codex-topic07-context-compaction-continuity-changelog.md' {
        param($t) $t.Replace('- Promotion: `IMPLEMENTED_NOT_PROMOTED`.', '- Promotion: `PROMOTED`.')
    }

    Write-Host "PASS: Topic 07 validator mutations ($script:Assertions assertions)." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    foreach ($root in $script:FixtureRoots) {
        $resolved = [IO.Path]::GetFullPath($root)
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
        if (-not $resolved.StartsWith($temp + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
            [IO.Path]::GetFileName($resolved) -notlike 'omp-topic07-validator-*') {
            throw "Refusing unsafe Topic 07 validator cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
