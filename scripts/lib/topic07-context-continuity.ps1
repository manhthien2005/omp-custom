#Requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Topic07PinnedOmpSha = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'

function Get-Topic07NormalizedRangeHash {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][int]$StartLine,
        [Parameter(Mandatory)][int]$EndLine
    )
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { throw "Source file is missing: $LiteralPath" }
    $lines = [IO.File]::ReadAllLines([IO.Path]::GetFullPath($LiteralPath))
    if ($StartLine -lt 1 -or $EndLine -lt $StartLine -or $EndLine -gt $lines.Count) {
        throw "Source range is invalid: $LiteralPath`:$StartLine-$EndLine"
    }
    $text = (($lines[($StartLine - 1)..($EndLine - 1)] -join "`n") + "`n")
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($text)
    )).ToLowerInvariant()
}

function Get-Topic07SourceAttachmentManifest {
    return @(
        [pscustomobject]@{ Name = 'compact-soft'; Path = 'packages/coding-agent/src/session/compact-modes.ts'; Start = 41; End = 55; Sha256 = 'a19bc111d1db23bc81d764b65cc7334d4ad53285fa592f3178c55ee037f1f3c1'; Needles = @('name: "soft"', 'overrides: { strategy: "context-full", remoteEnabled: false }') }
        [pscustomobject]@{ Name = 'manual-preparation-hook'; Path = 'packages/coding-agent/src/session/session-maintenance.ts'; Start = 620; End = 665; Sha256 = '9a6330c14b11b0fff4ea1dced48486eed1c98fabc965c86683d376180dc212fc'; Needles = @('const preparation = prepareCompaction', 'hasHandlers("session_before_compact")', 'if (result?.cancel)', 'throw new CompactionCancelledError()') }
        [pscustomobject]@{ Name = 'compacting-last-result'; Path = 'packages/coding-agent/src/extensibility/extensions/runner.ts'; Start = 985; End = 1020; Sha256 = 'a6090a8bb479ed48d316892417dcf7056f904c59f8018435142aa59794caf49b'; Needles = @('for (const ext of this.extensions)', 'event.type === "session.compacting"', 'result = handlerResult') }
        [pscustomobject]@{ Name = 'saved-compaction-entry'; Path = 'packages/coding-agent/src/session/session-maintenance.ts'; Start = 866; End = 905; Sha256 = 'f68bb0650d632eb808d2f4116177a43ceb8e9490f8579f98bebdc52a612b39d4'; Needles = @('const savedCompactionEntry', 'type: "session_compact"', 'compactionEntry: savedCompactionEntry') }
        [pscustomobject]@{ Name = 'request-hooks'; Path = 'packages/coding-agent/src/sdk.ts'; Start = 3108; End = 3160; Sha256 = 'f2feca31e9575538841309f261d9a92573627dceff132829ee1a5c060d6342e6'; Needles = @('const transformContext', 'extensionRunner.emitContext', 'const onPayload', 'extensionRunner.emitBeforeProviderRequest') }
        [pscustomobject]@{ Name = 'before-agent-start'; Path = 'packages/coding-agent/src/session/agent-session.ts'; Start = 5230; End = 5335; Sha256 = 'ab4cd6ce390cb3edffed8f27f197ea85208738046ce6e3da099299c5149eb630'; Needles = @('emitBeforeAgentStart', 'if (this.#promptGeneration !== generation)', 'runPrePromptCompactionIfNeeded', 'this.#stats.setPendingSnapshot') }
        [pscustomobject]@{ Name = 'agent-loop-order'; Path = 'packages/agent/src/agent-loop.ts'; Start = 1090; End = 1185; Sha256 = '07cf31dbcc51aa96d13e15fd2a094e2941868b8777a91f644a3f2b8e02903790'; Needles = @('prepareProviderCall', 'config.beforeModelCall', 'if (gateResult?.stop)', 'streamAssistantResponse') }
        [pscustomobject]@{ Name = 'turn-end'; Path = 'packages/coding-agent/src/session/agent-session.ts'; Start = 3345; End = 3368; Sha256 = '9892d0fde46b4a89dd6c5810f06754875b60435a561debc8f6e2b329389bbff2'; Needles = @('event.type === "turn_end"', 'this.#extensionRunner.emit(hookEvent)') }
        [pscustomobject]@{ Name = 'abort-generation'; Path = 'packages/coding-agent/src/session/agent-session.ts'; Start = 6180; End = 6212; Sha256 = 'd16de3d903a7ca23262397508549a7d87e51637d5f7f3a1ea33c5654b8425e6c'; Needles = @('async abort(options?', 'const strandedAdvisorCards', 'this.#promptGeneration++;', 'this.#maintenance.abortAutomaticCompaction()') }
        [pscustomobject]@{ Name = 'prune-before-auto'; Path = 'packages/coding-agent/src/session/session-maintenance.ts'; Start = 1325; End = 1420; Sha256 = 'ecb65c2a9d17129d8f58216fb1a0953720e3d8ccab46f1ee33be06d7a1a7a7fd'; Needles = @('this.#pruneStaleToolResults()', 'if (!compactionSettings.enabled || compactionSettings.strategy === "off")', 'this.#pruneToolOutputs()', 'if (shouldThresholdCompact)') }
        [pscustomobject]@{ Name = 'rescue-before-hook'; Path = 'packages/coding-agent/src/session/session-maintenance.ts'; Start = 2290; End = 2452; Sha256 = '5f3be2e05f72b061c6ba4e0ed93d2a34879735c9e84c4cb4895219147fb49127'; Needles = @('prepareCompaction(pathEntriesForCompaction', 'this.#rescueCompactionDeadEnd', 'hasHandlers("session_before_compact")') }
        [pscustomobject]@{ Name = 'shake-artifact-fallback'; Path = 'packages/coding-agent/src/session/session-maintenance.ts'; Start = 460; End = 568; Sha256 = '2acfe573fcfbfdf61048d46fc9540dbf46627d905164a98d973edb5448795899'; Needles = @('this.#saveShakeArtifact(regions)', 'applyShakeRegions(items)', 'if (artifactId)', 'return `[shaken ~${region.tokens} tokens]`', 'async #saveShakeArtifact', 'catch {', 'return undefined') }
        [pscustomobject]@{ Name = 'readonly-session-api'; Path = 'packages/coding-agent/src/session/session-manager.ts'; Start = 327; End = 348; Sha256 = '63184da566c237d8e0fe77f9cf91eb5648e8a9a192b8f460c54f6323d9094fb1'; Needles = @('export type ReadonlySessionManager', '| "getSessionFile"', '| "getArtifactsDir"', '| "saveArtifact"', '| "getBranch"', '| "getEntries"') }
        [pscustomobject]@{ Name = 'subagent-settings'; Path = 'packages/coding-agent/src/task/executor.ts'; Start = 854; End = 906; Sha256 = '2668ca62f6e9d65907cd5879562160fd8019cacede7a8d15815b1d752732cdee'; Needles = @('for (const key of Object.keys(SETTINGS_SCHEMA)', 'snapshot[key] = baseSettings.get(key)', 'return Settings.isolated') }
        [pscustomobject]@{ Name = 'subagent-init-before-prompt'; Path = 'packages/coding-agent/src/task/executor.ts'; Start = 3128; End = 3260; Sha256 = '9530bc58880638839e77a34fe6fad31b9ebd0b720575b704697173e5ec879a1d'; Needles = @('appendSessionInit', 'emit({ type: "session_start" })', 'driveSessionToYield') }
    )
}

function Test-Topic07OrderedNeedles {
    param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string[]]$Needles)
    $offset = 0
    foreach ($needle in $Needles) {
        $index = $Text.IndexOf($needle, $offset, [StringComparison]::Ordinal)
        if ($index -lt 0) { return $false }
        $offset = $index + $needle.Length
    }
    return $true
}

function Test-Topic07SourceAttachments {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    $upstream = Join-Path ([IO.Path]::GetFullPath($RepositoryRoot)) '_research\upstreams\oh-my-pi'
    try {
        if (-not (Test-Path -LiteralPath (Join-Path $upstream '.git') -PathType Container)) {
            throw 'The pinned OMP checkout is missing.'
        }
        $head = (@(& git -C $upstream rev-parse HEAD 2>&1) -join '').Trim()
        if ($LASTEXITCODE -ne 0 -or $head -cne $script:Topic07PinnedOmpSha) {
            throw "Pinned OMP HEAD mismatch: expected $script:Topic07PinnedOmpSha, got $head."
        }
        $status = @(& git -C $upstream status --porcelain --untracked-files=no 2>&1)
        if ($LASTEXITCODE -ne 0 -or @($status | Where-Object { [string]$_ }).Count -ne 0) {
            throw 'The pinned OMP checkout is not clean.'
        }

        $verified = [Collections.Generic.List[object]]::new()
        foreach ($attachment in Get-Topic07SourceAttachmentManifest) {
            $path = Join-Path $upstream ([string]$attachment.Path).Replace('/', '\')
            $lines = [IO.File]::ReadAllLines($path)
            $text = (($lines[([int]$attachment.Start - 1)..([int]$attachment.End - 1)] -join "`n") + "`n")
            $hash = Get-Topic07NormalizedRangeHash -LiteralPath $path -StartLine $attachment.Start -EndLine $attachment.End
            if ($hash -cne [string]$attachment.Sha256) {
                throw "Bounded source hash mismatch for $($attachment.Name)."
            }
            if (-not (Test-Topic07OrderedNeedles -Text $text -Needles @($attachment.Needles))) {
                throw "Structural source order mismatch for $($attachment.Name)."
            }
            [void]$verified.Add([pscustomobject]@{
                Name = [string]$attachment.Name
                Path = [string]$attachment.Path
                Range = "$($attachment.Start)-$($attachment.End)"
                Sha256 = $hash
            })
        }
        return [pscustomobject]@{
            Status = 'PASS'
            Code = 'T07-SOURCE-ATTACHED'
            Message = 'Pinned OMP source seams match the approved bounded attachments.'
            OmpSha = $head
            Attachments = @($verified)
        }
    } catch {
        return [pscustomobject]@{
            Status = 'FAIL'
            Code = 'OPEN-T07-RUNTIME-01'
            Message = $_.Exception.Message
            OmpSha = $null
            Attachments = @()
        }
    }
}

function Get-Topic07OmpIdentity {
    param([Parameter(Mandatory)][string]$LiteralPath)
    try {
        if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { return $null }
        $resolved = [IO.Path]::GetFullPath($LiteralPath)
        $output = @(& $resolved --version 2>&1)
        if ($LASTEXITCODE -ne 0) { return $null }
        $match = [regex]::Match(($output -join "`n"), '(?m)^omp/([^\s]+)\s*$')
        if (-not $match.Success) { return $null }
        return [pscustomobject]@{ Path = $resolved; Version = $match.Groups[1].Value }
    } catch { return $null }
}

function Resolve-Topic07RuntimeMatrix {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    $rows = [Collections.Generic.List[object]]::new()
    $installedCommand = Get-Command omp.exe -ErrorAction SilentlyContinue
    if ($null -eq $installedCommand) { $installedCommand = Get-Command omp -ErrorAction SilentlyContinue }
    $installed = if ($null -ne $installedCommand) {
        Get-Topic07OmpIdentity -LiteralPath $(if ($installedCommand.Source) { $installedCommand.Source } else { $installedCommand.Path })
    } else { $null }
    [void]$rows.Add([pscustomobject]@{
        Version = '17.2.12'
        Available = $null -ne $installed -and [string]$installed.Version -ceq '17.2.12'
        Path = if ($null -ne $installed -and [string]$installed.Version -ceq '17.2.12') { [string]$installed.Path } else { $null }
        Source = 'installed'
    })

    $legacyCandidates = [Collections.Generic.List[object]]::new()
    if ($env:OMP_TOPIC07_17_2_10_PATH) {
        [void]$legacyCandidates.Add([pscustomobject]@{ Path = $env:OMP_TOPIC07_17_2_10_PATH; Source = 'environment' })
    }
    [void]$legacyCandidates.Add([pscustomobject]@{
        Path = Join-Path ([IO.Path]::GetFullPath($RepositoryRoot)) 'tools\runtime-cache\omp\17.2.10\omp.exe'
        Source = 'local-cache'
    })
    $legacy = $null
    $legacySource = $null
    foreach ($candidate in $legacyCandidates) {
        $identity = Get-Topic07OmpIdentity -LiteralPath ([string]$candidate.Path)
        if ($null -ne $identity -and [string]$identity.Version -ceq '17.2.10') {
            $legacy = $identity
            $legacySource = [string]$candidate.Source
            break
        }
    }
    [void]$rows.Add([pscustomobject]@{
        Version = '17.2.10'
        Available = $null -ne $legacy
        Path = if ($null -ne $legacy) { [string]$legacy.Path } else { $null }
        Source = if ($legacySource) { $legacySource } else { 'not-found' }
    })

    $ready = @($rows | Where-Object { -not $_.Available }).Count -eq 0
    return [pscustomobject]@{
        Status = if ($ready) { 'READY_FOR_PROMOTION_CANARY' } else { 'IMPLEMENTED_NOT_PROMOTED' }
        Code = if ($ready) { 'T07-RUNTIME-MATRIX-READY' } else { 'OPEN-T07-RUNTIME-02' }
        Message = if ($ready) {
            'OMP 17.2.12 and 17.2.10 are available for local canaries.'
        } else {
            'A verified local OMP 17.2.10 executable is unavailable; no download or downgrade was attempted.'
        }
        Rows = @($rows)
    }
}

function New-Topic07ContextContinuityValidationResult {
    param(
        [ValidateSet('PASS', 'WARN', 'FAIL')][string]$Status,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Message
    )
    return [pscustomobject]@{ Status = $Status; Code = $Code; Message = $Message }
}

function New-Topic07ContextContinuityBooleanResult {
    param(
        [bool]$Condition,
        [string]$Code,
        [string]$PassMessage,
        [string]$FailMessage
    )
    if ($Condition) {
        return New-Topic07ContextContinuityValidationResult -Status PASS -Code $Code -Message $PassMessage
    }
    return New-Topic07ContextContinuityValidationResult -Status FAIL -Code $Code -Message $FailMessage
}

function Get-Topic07ContextContinuityContent {
    param([string]$Root, [string]$RelativePath)
    $path = Join-Path $Root ($RelativePath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return '' }
    return Get-Content -Raw -LiteralPath $path -Encoding UTF8
}

function Get-Topic07ContextContinuityJson {
    param([string]$Root, [string]$RelativePath)
    try {
        $content = Get-Topic07ContextContinuityContent -Root $Root -RelativePath $RelativePath
        if (-not $content) { return $null }
        return $content | ConvertFrom-Json
    } catch { return $null }
}

function Test-Topic07ContextContinuityContainsAll {
    param([AllowEmptyString()][string]$Content, [Parameter(Mandatory)][string[]]$Needles)
    foreach ($needle in $Needles) {
        if ($Content.IndexOf($needle, [StringComparison]::Ordinal) -lt 0) { return $false }
    }
    return $true
}

function ConvertTo-Topic07ContextContinuityFlatText {
    param([AllowEmptyString()][string]$Content)
    $withoutBlockquotePrefixes = [regex]::Replace($Content, '(?m)^\s*>\s?', '')
    return [regex]::Replace($withoutBlockquotePrefixes, '\s+', ' ').Trim()
}

function Test-Topic07ContextContinuityClosedObject {
    param([object]$Value, [string[]]$ExpectedKeys)
    if ($null -eq $Value) { return $false }
    $actual = @($Value.PSObject.Properties.Name | Sort-Object)
    $expected = @($ExpectedKeys | Sort-Object)
    return ($actual -join '|') -ceq ($expected -join '|')
}

function Get-Topic07ContextContinuityBlock {
    param([string]$Content, [string]$StartNeedle, [string]$EndNeedle)
    $start = $Content.IndexOf($StartNeedle, [StringComparison]::Ordinal)
    if ($start -lt 0) { return '' }
    $end = $Content.IndexOf($EndNeedle, $start + $StartNeedle.Length, [StringComparison]::Ordinal)
    if ($end -lt 0) { return $Content.Substring($start) }
    return $Content.Substring($start, $end - $start)
}

function Get-Topic07ContextContinuityGovernedFiles {
    return @(
        'README.md', 'CHANGELOG.md', 'docs/architecture.md', 'docs/agent-boundaries.md',
        'docs/context-continuity.md', 'docs/workflow-v0.md', 'docs/task-state.md',
        'docs/token-strategy.md', 'docs/security.md', 'docs/installation.md', 'docs/customization.md',
        'docs/rollback.md', 'docs/final-report.md', 'docs/policies/context-budget.md',
        'docs/superpowers/specs/2026-08-13-topic-07-context-compaction-continuity-design.md',
        'docs/superpowers/plans/2026-08-13-topic-07-safe-context-compaction-continuity-plan.md',
        'spec/key/01-dna.md', 'spec/key/03-token-quality-model.md',
        'spec/key/04-decision-log.md', 'spec/key/05-coverage-audit.md',
        'spec/key/06-investment-thesis.md', 'spec/01-target-architecture.md',
        'spec/02-runtime-semantics.md', 'spec/04-workflow-sizing.md',
        'spec/05-context-and-token-model.md', 'spec/12-installation-and-rollback.md',
        'spec/13-validation-and-evaluation.md', 'spec/15-security-and-failure-recovery.md',
        'spec/README.md', 'spec/phases/phase-01-runtime-correctness.md',
        'spec/phases/phase-03-context-efficiency.md',
        'spec/phases/phase-05-installation-hardening.md',
        'spec/phases/phase-06-evaluation.md', 'registry/omp-compatibility.yml',
        'template/.omp/AGENTS.md', 'template/.omp/RULES.md',
        'template/.omp/commands/quick.md', 'template/.omp/commands/standard.md',
        'template/.omp/commands/orchestrated.md',
        'template/.omp/contracts/managed-state-client.mjs',
        'template/.omp/contracts/context-continuity-schema.mjs',
        'template/.omp/contracts/context-continuity-core.mjs',
        'template/.omp/contracts/managed-runtime.yml',
        'template/.omp/contracts/component-manifest.json',
        'template/.omp/extensions/context-continuity.js',
        'template/.omp/extensions/agent-task-boundary.js',
        'template/.omp/contracts/agent-boundary-core.mjs',
        'template/.omp/bin/omp-managed.ps1', 'template/.omp/state/agent-tasks.ps1',
        'template/.omp/state/manifest.json', 'template/.omp/state/PROTOCOL.md',
        'template/.omp/state/schemas/agent-tasks-v1.schema.json',
        'template/.omp/state/lib/AgentTasks.Common.ps1',
        'template/.omp/state/lib/AgentTasks.Lifecycle.ps1',
        'template/.omp/state/lib/AgentTasks.Projection.ps1',
        'scripts/install-template.ps1', 'scripts/uninstall-template.ps1',
        'scripts/validate-template.ps1', 'scripts/validate-topic07-context-continuity.ps1',
        'scripts/capture-topic07-evidence.ps1', 'scripts/lib/topic07-context-continuity.ps1',
        'scripts/tests/topic07-managed-state-client.Tests.mjs',
        'scripts/tests/topic07-continuity-core.Tests.mjs',
        'scripts/tests/topic07-omp-adapter.Tests.mjs',
        'scripts/tests/topic07-safe-compact.Tests.mjs',
        'scripts/tests/topic07-pressure-guard.Tests.mjs',
        'scripts/tests/topic07-state-contract.Tests.ps1',
        'scripts/tests/topic07-state-projection.Tests.ps1',
        'scripts/tests/topic07-managed-runtime.Tests.ps1',
        'scripts/tests/topic07-pressure-canary.Tests.ps1',
        'scripts/tests/topic07-validator-mutations.Tests.ps1',
        'scripts/tests/fixtures/topic07-provider-sentinel.mjs',
        'docs/evidence/current-product/topic-07/deterministic.json',
        'docs/evidence/current-product/topic-07/manifest.json',
        'codex-topic07-context-compaction-continuity-changelog.md'
    )
}

function Test-Topic07ContextContinuityContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [switch]$SkipEvidence,
        [switch]$SkipRuntime
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot)
    $results = [Collections.Generic.List[object]]::new()
    $governed = @(Get-Topic07ContextContinuityGovernedFiles)
    $required = if ($SkipEvidence) {
        @($governed | Where-Object { $_ -notlike 'docs/evidence/current-product/topic-07/*' })
    } else { $governed }
    $missing = @($required | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $root ($_ -replace '/', '\')) -PathType Leaf)
    })
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult ($missing.Count -eq 0) `
        'T07-REQUIRED-FILES' 'All Topic 07 governed files exist' `
        ("Missing Topic 07 governed files: {0}" -f ($missing -join ', '))))

    $decision = Get-Topic07ContextContinuityContent $root 'spec/key/04-decision-log.md'
    $markerCount = [regex]::Matches($decision, 'topic07-authority:kd-031').Count
    $authorityValid = $markerCount -eq 1 -and
        (Test-Topic07ContextContinuityContainsAll $decision @(
            '## KD-031 — Explicit safe context-full compaction with authoritative continuity kernel',
            'Managed sessions disable automatic semantic compaction and context promotion',
            'complete initial `locked_decisions` in `create-task`',
            'there is no hidden auto-continue', 'Bounded subagents cannot invoke the',
            '`IMPLEMENTED_NOT_PROMOTED`', '`OPEN-T07-RUNTIME-02`',
            'Opus is not a continuity dependency'
        ))
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $authorityValid `
        'T07-AUTHORITY-KD031' 'KD-031 is the single complete Topic 07 authority' `
        'KD-031 marker or load-bearing decision clauses are missing'))

    $operator = Get-Topic07ContextContinuityContent $root 'docs/context-continuity.md'
    $readme = Get-Topic07ContextContinuityContent $root 'README.md'
    $agents = Get-Topic07ContextContinuityContent $root 'template/.omp/AGENTS.md'
    $rules = Get-Topic07ContextContinuityContent $root 'template/.omp/RULES.md'
    $projectionText = ConvertTo-Topic07ContextContinuityFlatText ($operator + $readme + $agents + $rules)
    $projectionValid = (Test-Topic07ContextContinuityContainsAll $projectionText @(
        'The command accepts no focus text', 'Operational authority remains in the local Topic 04',
        'No prompt is sent and no continuation, retry, or handoff is scheduled',
        'Quick may continue when authoritative state explicitly reports',
        'Bare `omp` remains usable', 'OmniRoute, DeepSeek Scout routing',
        'only argument-free `/safe-compact` after task arming'
    ))
    foreach ($entry in @(
        @{ Path = 'template/.omp/commands/quick.md'; Class = 'quick' },
        @{ Path = 'template/.omp/commands/standard.md'; Class = 'standard' },
        @{ Path = 'template/.omp/commands/orchestrated.md'; Class = 'orchestrated' }
    )) {
        $commandDoc = Get-Topic07ContextContinuityContent $root $entry.Path
        $commandDoc = ConvertTo-Topic07ContextContinuityFlatText $commandDoc
        $projectionValid = $projectionValid -and
            (Test-Topic07ContextContinuityContainsAll $commandDoc @(
                "workflow_class: $($entry.Class)", 'complete initial `locked_decisions`',
                '`set-continuity-contract`', 'argument-free `/safe-compact`',
                '`begin-handoff`/`accept-handoff`', 'without hidden continuation'
            ))
    }
    foreach ($entry in @(
        @{ Path = 'spec/01-target-architecture.md'; Needle = 'Selected Topic 07 continuity boundary' },
        @{ Path = 'spec/02-runtime-semantics.md'; Needle = 'Selected Topic 07 runtime semantics' },
        @{ Path = 'spec/13-validation-and-evaluation.md'; Needle = 'Topic 07 continuity validation slice' },
        @{ Path = 'spec/15-security-and-failure-recovery.md'; Needle = 'Topic 07 continuity threat boundary' },
        @{ Path = 'spec/phases/phase-01-runtime-correctness.md'; Needle = 'topic07-projection:phase-01' },
        @{ Path = 'spec/phases/phase-03-context-efficiency.md'; Needle = 'topic07-projection:phase-03' },
        @{ Path = 'spec/phases/phase-05-installation-hardening.md'; Needle = 'topic07-projection:phase-05' },
        @{ Path = 'spec/phases/phase-06-evaluation.md'; Needle = 'topic07-projection:phase-06' }
    )) {
        $projectionValid = $projectionValid -and
            ((Get-Topic07ContextContinuityContent $root $entry.Path).Contains([string]$entry.Needle))
    }
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $projectionValid `
        'T07-AUTHORITY-PROJECTIONS' 'Workflow, operator, and phase projections agree with KD-031' `
        'A Topic 07 outward authority projection is missing or contradictory'))

    $stateSchema = Get-Topic07ContextContinuityJson $root 'template/.omp/state/schemas/agent-tasks-v1.schema.json'
    $stateCli = Get-Topic07ContextContinuityContent $root 'template/.omp/state/agent-tasks.ps1'
    $stateCommon = Get-Topic07ContextContinuityContent $root 'template/.omp/state/lib/AgentTasks.Common.ps1'
    $stateLifecycle = Get-Topic07ContextContinuityContent $root 'template/.omp/state/lib/AgentTasks.Lifecycle.ps1'
    $stateProjection = Get-Topic07ContextContinuityContent $root 'template/.omp/state/lib/AgentTasks.Projection.ps1'
    $stateProtocol = Get-Topic07ContextContinuityContent $root 'template/.omp/state/PROTOCOL.md'
    $stateText = ConvertTo-Topic07ContextContinuityFlatText ($stateCli + $stateCommon + $stateLifecycle + $stateProjection + $stateProtocol)
    $stateValid = $null -ne $stateSchema -and
        @($stateSchema.'$defs'.taskStateRevisionCurrent.allOf[1].required) -contains 'workflow_class' -and
        @($stateSchema.'$defs'.taskStateRevisionCurrent.allOf[1].required) -contains 'locked_decisions' -and
        @($stateSchema.'$defs'.continuityContractRequest.required) -contains 'expected_revision_sha256' -and
        @($stateSchema.'$defs'.continuityContractRequest.required) -contains 'expected_lease_generation' -and
        (Test-Topic07ContextContinuityContainsAll $stateText @(
            "'set-continuity-contract'", "'project-continuity'", 'AT-CONTINUITY-CLASSIFICATION-REQUIRED',
            'Get-AgentTasksContinuityProjection', 'exact `session_ref` and `runtime`',
            'never returns authority paths, raw evidence observations, messages, transcripts, terminal output, prompts, or hidden reasoning'
        ))
    $stateManifest = Get-Topic07ContextContinuityJson $root 'template/.omp/state/manifest.json'
    if ($stateValid -and $null -ne $stateManifest) {
        foreach ($row in @($stateManifest.files)) {
            $path = Join-Path $root ('template\.omp\state\' + ([string]$row.path -replace '/', '\'))
            if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
                (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne [string]$row.sha256) {
                $stateValid = $false
                break
            }
        }
    } else { $stateValid = $false }
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $stateValid `
        'T07-STATE-CONTRACT' 'Topic 04 continuity fields, CAS operation, projection privacy, and state hashes are exact' `
        'Topic 04 continuity state/schema/projection contract is incomplete or drifted'))

    $schema = Get-Topic07ContextContinuityContent $root 'template/.omp/contracts/context-continuity-schema.mjs'
    $core = Get-Topic07ContextContinuityContent $root 'template/.omp/contracts/context-continuity-core.mjs'
    $coreValid = (Test-Topic07ContextContinuityContainsAll $schema @(
        'maxKernelBytes: 16_384', 'maxRecoveryArtifactBytes: 262_144', 'maxLockedDecisions: 64',
        '"continuity_forbidden"', '"continuity_degraded"', '"pressure_invalid"',
        '"compaction.strategy": "off"', '"compaction.autoContinue": false',
        '"compaction.remoteEnabled": false', '"compaction.remoteStreamingV2Enabled": false'
    )) -and (Test-Topic07ContextContinuityContainsAll $core @(
        '"task_id", "workflow_class", "objective"', 'normalizeLockedDecisions',
        'kernel.task.workflow_class !== "quick" && fields.length > 0',
        'record_type: "context_continuity_kernel"', 'resolvePressureBoundary',
        'record_type: "context_continuity_recovery"', 'customType: "topic07-continuity-kernel"'
    ))
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $coreValid `
        'T07-CONTINUITY-CORE' 'Portable continuity limits, closed kernel, degradation, pressure, and recovery structures are present' `
        'Portable continuity core/profile structures are incomplete or weakened'))

    $expectedProfile = @(
        'task:', '  softRequestBudget: 200', 'contextPromotion:', '  enabled: false',
        'compaction:', '  enabled: false', '  strategy: off', '  midTurnEnabled: false',
        '  thresholdPercent: -1', '  thresholdTokens: -1', '  keepRecentTokens: 20000',
        '  autoContinue: false', '  idleEnabled: false', '  remoteEnabled: false',
        '  remoteStreamingV2Enabled: false', '  supersedeReads: true', '  dropUseless: true'
    ) -join "`n"
    $profile = (Get-Topic07ContextContinuityContent $root 'template/.omp/contracts/managed-runtime.yml') -replace "`r`n", "`n"
    $profileValid = $profile.Trim() -ceq $expectedProfile
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $profileValid `
        'T07-PROFILE' 'Managed runtime profile exactly disables automatic continuity paths' `
        'Managed runtime continuity profile contains missing, extra, or changed settings'))

    $component = Get-Topic07ContextContinuityJson $root 'template/.omp/contracts/component-manifest.json'
    $componentValid = $null -ne $component -and
        (Test-Topic07ContextContinuityClosedObject $component @(
            'schema_version', 'record_type', 'component', 'component_version', 'minimum_pwsh_version',
            'supported_omp_versions', 'role_policy', 'continuity_policy', 'dependencies', 'files',
            'generated_target_files'
        )) -and [int]$component.schema_version -eq 2 -and
        [string]$component.component -ceq 'agent-boundary' -and
        [string]$component.component_version -ceq '2.1.0' -and
        (@($component.supported_omp_versions) -join '|') -ceq '17.2.10|17.2.12' -and
        (Test-Topic07ContextContinuityClosedObject $component.continuity_policy @(
            'command', 'automatic_semantic_compaction', 'context_promotion', 'keep_recent_tokens',
            'nonce_ttl_ms', 'max_kernel_bytes', 'max_recovery_artifact_bytes',
            'pressure_default_reserve_tokens'
        )) -and [string]$component.continuity_policy.command -ceq 'safe-compact' -and
        [bool]$component.continuity_policy.automatic_semantic_compaction -eq $false -and
        [bool]$component.continuity_policy.context_promotion -eq $false -and
        [int]$component.continuity_policy.keep_recent_tokens -eq 20000 -and
        [int]$component.continuity_policy.pressure_default_reserve_tokens -eq 16384
    if ($componentValid) {
        $requiredComponentPaths = @(
            '.omp/contracts/managed-state-client.mjs', '.omp/contracts/context-continuity-schema.mjs',
            '.omp/contracts/context-continuity-core.mjs', '.omp/contracts/managed-runtime.yml',
            '.omp/extensions/context-continuity.js', '.omp/bin/omp-managed.ps1'
        )
        $manifestPaths = @($component.files | ForEach-Object { [string]$_.path })
        $componentValid = @($requiredComponentPaths | Where-Object { $_ -notin $manifestPaths }).Count -eq 0
        foreach ($row in @($component.files)) {
            $path = Join-Path $root ('template\' + ([string]$row.path -replace '/', '\'))
            if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
                (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne [string]$row.sha256) {
                $componentValid = $false
                break
            }
        }
    }
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $componentValid `
        'T07-COMPONENT-MANIFEST' 'Agent-boundary v2 manifest, versions, policy, paths, and file hashes are exact' `
        'Agent-boundary v2 continuity manifest or governed file hashes are invalid'))

    $adapter = Get-Topic07ContextContinuityContent $root 'template/.omp/extensions/context-continuity.js'
    $commandBlock = Get-Topic07ContextContinuityBlock $adapter 'api.registerCommand("safe-compact"' 'api.on("session_before_compact"'
    $commandValid = (Test-Topic07ContextContinuityContainsAll $commandBlock @(
        'args.trim().length > 0', 'state.mode !== SESSION_MODES.ARMED_MAIN',
        'ctx?.isIdle?.() !== true', 'ctx?.hasPendingMessages?.() !== false',
        'jobs.running.length > 0', 'projection.kernel.task.task_id !== state.armedTaskId',
        'await ctx.compact({ mode: "soft", onComplete, onError });'
    )) -and [regex]::Matches($adapter, [regex]::Escape('ctx.compact({ mode: "soft"')).Count -eq 1
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $commandValid `
        'T07-COMMAND-TRANSACTION' 'Argument-free armed idle command makes exactly one native soft call' `
        'Safe-compact arguments, preflight, single-flight, or native-call count drifted'))

    $sessionFlat = ConvertTo-Topic07ContextContinuityFlatText $adapter
    $sessionValid = (Test-Topic07ContextContinuityContainsAll $sessionFlat @(
        'function capturePersistedSession(ctx)', 'getSessionId?.()', 'getSessionFile?.()',
        'getArtifactsDir?.()',
        'if (typeof sessionId !== "string" || sessionId.trim().length === 0 || typeof sessionFile !== "string" || !path.isAbsolute(sessionFile) || typeof artifactsDir !== "string" || !path.isAbsolute(artifactsDir))',
        'if (!sessionStat.isFile() || !artifactStat.isDirectory())',
        'validated.value.lifecycle.owner_session_ref !== state.sessionId',
        'validated.value.lifecycle.owner_runtime !== "omp"',
        'state.mode = SESSION_MODES.ARMED_MAIN'
    ))
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $sessionValid `
        'T07-SESSION-OWNERSHIP' 'Persisted exact-session task ownership is checked before arming and compaction' `
        'Persisted session or exact owner/runtime binding was weakened'))

    $artifactBlock = Get-Topic07ContextContinuityBlock $adapter 'const verifyAndSaveRecoveryArtifact' 'api.registerCommand("safe-compact"'
    $artifactValid = Test-Topic07ContextContinuityContainsAll $artifactBlock @(
        'buildRecoveryArtifact', 'saveArtifact(bytes, "context-continuity-recovery")',
        'getArtifactPath(artifactId)', 'fs.realpathSync(session.artifactsDir)',
        'isPathInside(realArtifactDirectory, realArtifactPath)',
        'fs.readFileSync(realArtifactPath, "utf8")',
        'savedBytes !== bytes || sha256Text(savedBytes.slice(0, -1)) !== sha256Text(recovery.canonical)'
    )
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $artifactValid `
        'T07-ARTIFACT-FIRST' 'Recovery artifact is written, contained, re-read, and hash-verified before compaction' `
        'Artifact-first persistence or byte/hash verification is missing'))

    $epochBlock = Get-Topic07ContextContinuityBlock $adapter 'function epochStateEntry' 'function initialState'
    $nonceValid = (Test-Topic07ContextContinuityContainsAll $adapter @(
        'rawNonce = randomBytes(32)', 'const nonceSha256 = sha256Bytes(rawNonce)',
        '!Buffer.isBuffer(epoch.rawNonce)) return { cancel: true };',
        'epoch.rawNonce.fill(0);', 'epoch.rawNonce = null;',
        'return { cancel: true };'
    )) -and $epochBlock.IndexOf('rawNonce', [StringComparison]::Ordinal) -lt 0 -and
        $epochBlock.IndexOf('raw_nonce', [StringComparison]::Ordinal) -lt 0
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $nonceValid `
        'T07-NONCE-GATE' 'Raw nonce remains memory-only and every unauthorized compact is cancelled' `
        'Raw nonce persistence or compact authorization gate was weakened'))

    $noContinuation = $adapter.IndexOf('sendUserMessage(', [StringComparison]::Ordinal) -lt 0 -and
        $adapter.IndexOf('sendCustomMessage(', [StringComparison]::Ordinal) -lt 0 -and
        $adapter.IndexOf('scheduleContinuation', [StringComparison]::Ordinal) -lt 0 -and
        (Test-Topic07ContextContinuityContainsAll $adapter @(
            'setEpochState(EPOCH_STATES.AWAITING_INJECTION)',
            'api.on("context", async (event, ctx)',
            'api.appendEntry("topic07:epoch-state", epochStateEntry(state.epoch, EPOCH_STATES.CONSUMED))'
        ))
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $noContinuation `
        'T07-NO-CONTINUATION' 'The next normal prompt consumes one kernel without hidden continuation or retry' `
        'A continuation/retry path or one-shot kernel settlement rule drifted'))

    $pressureBlock = Get-Topic07ContextContinuityBlock $adapter 'const pressureGuard = (ctx, boundary)' 'const currentProjectionMatchesEpoch'
    $pressureValid = (Test-Topic07ContextContinuityContainsAll $pressureBlock @(
        'resolvePressureBoundary(usage)', 'if (pressure && !pressure.atOrAbove) return true;',
        'if (!state.requestAborted) {', 'abortSafely(ctx);',
        'reasonCode: "context_pressure"', 'providerAction: "aborted"', 'return false;'
    )) -and (Test-Topic07ContextContinuityContainsAll $adapter @(
        'api.on("before_agent_start"', 'pressureGuard(ctx, "before_agent_start")',
        'api.on("turn_end"', 'pressureGuard(ctx, "turn_end")',
        'api.on("before_provider_request"', 'pressureGuard(ctx, "before_provider_request")'
    ))
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $pressureValid `
        'T07-PRESSURE-GUARD' 'Pressure is checked at all boundaries and aborts before provider dispatch' `
        'Pressure calculation, abort, observation, or final provider boundary was weakened'))

    $wrapper = Get-Topic07ContextContinuityContent $root 'template/.omp/extensions/agent-task-boundary.js'
    $boundaryCore = Get-Topic07ContextContinuityContent $root 'template/.omp/contracts/agent-boundary-core.mjs'
    $childValid = (Test-Topic07ContextContinuityContainsAll $wrapper @(
        'consumePressureAbort({ agent: result.agent, task: result.task })',
        'if (marker === CONTEXT_PRESSURE_ABORT_MARKER &&',
        'result.topic07AbortMarker = marker;'
    )) -and (Test-Topic07ContextContinuityContainsAll $boundaryCore @(
        'if (result.topic07AbortMarker === "T07_CONTEXT_PRESSURE_ABORT")',
        'return resultFailure(role, "context_pressure"',
        'The bounded child stopped at the managed context-pressure boundary.'
    ))
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $childValid `
        'T07-CHILD-SETTLEMENT' 'Bounded-child pressure marker settles only as failed/partial context pressure' `
        'Topic 06 no longer rejects a bounded child pressure/partial result'))

    $launcher = Get-Topic07ContextContinuityContent $root 'template/.omp/bin/omp-managed.ps1'
    $launcherOrder = [regex]::IsMatch($launcher,
        "(?s)'--trusted-extension'\s*\[string\]\`$runtime\.paths\.wrapper\s*'--trusted-extension'\s*\[string\]\`$runtime\.paths\.continuity_adapter\s*'--config'\s*\[string\]\`$runtime\.paths\.overlay") -and
        $launcher.Contains("if (`$argument -ceq '--no-session'")
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $launcherOrder `
        'T07-LAUNCHER-ORDER' 'Managed launcher loads wrapper, final continuity adapter, then overlay and rejects no-session' `
        'Managed launcher extension/profile order or no-session refusal drifted'))

    $installer = Get-Topic07ContextContinuityContent $root 'scripts/install-template.ps1'
    $uninstaller = Get-Topic07ContextContinuityContent $root 'scripts/uninstall-template.ps1'
    $rollbackDoc = ConvertTo-Topic07ContextContinuityFlatText (Get-Topic07ContextContinuityContent $root 'docs/rollback.md')
    $installRollbackValid = (Test-Topic07ContextContinuityContainsAll $installer @(
        'agent-boundary', 'Read-Topic06BoundaryManifest', 'New-Topic06BoundaryRuntime',
        'Agent-boundary staging hash check failed'
    )) -and (Test-Topic07ContextContinuityContainsAll $uninstaller @(
        "'component_version'", "'2.1.0'", "'.omp/contracts/context-continuity-core.mjs'",
        "'.omp/contracts/context-continuity-schema.mjs'", "'.omp/contracts/managed-state-client.mjs'",
        "'.omp/extensions/context-continuity.js'", "'retain_outside_target_omp'"
    )) -and (Test-Topic07ContextContinuityContainsAll $rollbackDoc @(
        'does not delete Topic 04 authority, OMP session files, or already written recovery artifacts'
    ))
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $installRollbackValid `
        'T07-INSTALL-ROLLBACK' 'Continuity component installs and rolls back transactionally while retaining authority/session data' `
        'Continuity install attribution, rollback paths, or retained-data contract drifted'))

    $helper = Get-Topic07ContextContinuityContent $root 'scripts/lib/topic07-context-continuity.ps1'
    $sourcePolicyValid = $helper.Contains("`$script:Topic07PinnedOmpSha = '3a8591a8af5b6d200088d12ca75a5517cb064fa8'") -and
        [regex]::Matches($helper, "\[pscustomobject\]@\{ Name = '").Count -eq 15 -and
        [regex]::Matches($helper, "Sha256 = '[0-9a-f]{64}'").Count -eq 15 -and
        $helper.Contains("status --porcelain --untracked-files=no")
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $sourcePolicyValid `
        'T07-SOURCE-POLICY' 'Pinned OMP SHA, clean-source rule, and 15 bounded source hashes are fixed' `
        'Pinned OMP/source-attachment policy was weakened'))

    if (-not $SkipRuntime) {
        $sourceResult = Test-Topic07SourceAttachments -RepositoryRoot $root
        [void]$results.Add((New-Topic07ContextContinuityBooleanResult ($sourceResult.Status -ceq 'PASS') `
            'T07-SOURCE-ATTACHMENTS' 'Pinned OMP source seams match all 15 bounded attachments' `
            ("Pinned OMP source attachment failed: {0}" -f $sourceResult.Message)))
        $runtimeMatrix = Resolve-Topic07RuntimeMatrix -RepositoryRoot $root
        $matrixTruthful = $runtimeMatrix.Status -in @('READY_FOR_PROMOTION_CANARY', 'IMPLEMENTED_NOT_PROMOTED') -and
            @($runtimeMatrix.Rows).Count -eq 2 -and
            (@($runtimeMatrix.Rows | ForEach-Object Version) -join '|') -ceq '17.2.12|17.2.10'
        [void]$results.Add((New-Topic07ContextContinuityBooleanResult $matrixTruthful `
            'T07-RUNTIME-MATRIX' ("Runtime matrix is truthful: {0} ({1})" -f $runtimeMatrix.Status, $runtimeMatrix.Code) `
            'Runtime matrix does not preserve the exact two-version promotion gate'))
    }

    $changelog = Get-Topic07ContextContinuityContent $root 'codex-topic07-context-compaction-continuity-changelog.md'
    $registry = Get-Topic07ContextContinuityContent $root 'registry/omp-compatibility.yml'
    $truthful = (Test-Topic07ContextContinuityContainsAll ($changelog + $registry) @(
        'Promotion: `IMPLEMENTED_NOT_PROMOTED`', '`OPEN-T07-RUNTIME-02`',
        'External provider calls: `0`', 'No download or downgrade was attempted',
        'continuity_selected_status: IMPLEMENTED_NOT_PROMOTED',
        'continuity_supported_versions: "17.2.10,17.2.12"',
        'continuity_runtime_canary_gate:'
    )) -and $changelog.IndexOf('Promotion: `PROMOTED`', [StringComparison]::Ordinal) -lt 0
    [void]$results.Add((New-Topic07ContextContinuityBooleanResult $truthful `
        'T07-TRUTHFULNESS' 'Status, blocker, zero-provider, local/no-Git, and two-version claims are truthful' `
        'Topic 07 status or blocker claims overstate promotion'))

    if (-not $SkipEvidence) {
        $evidence = Get-Topic07ContextContinuityJson $root 'docs/evidence/current-product/topic-07/deterministic.json'
        $evidenceValid = $null -ne $evidence -and [int]$evidence.schema_version -eq 1 -and
            [string]$evidence.record_type -ceq 'topic07_context_continuity_evidence' -and
            [string]$evidence.status -ceq 'IMPLEMENTED_NOT_PROMOTED' -and
            [int]$evidence.provider_calls -eq 0 -and [int]$evidence.model_processes_started -eq 0 -and
            [string]$evidence.runtime_matrix.status -ceq 'IMPLEMENTED_NOT_PROMOTED' -and
            [string]$evidence.runtime_matrix.code -ceq 'OPEN-T07-RUNTIME-02' -and
            [int]$evidence.source_attachment_count -eq 15 -and
            @($evidence.cases.PSObject.Properties).Count -ge 8 -and
            @($evidence.cases.PSObject.Properties.Value | Where-Object status -ne PASS).Count -eq 0
        if ($evidenceValid) {
            $serializedEvidence = $evidence | ConvertTo-Json -Depth 64 -Compress
            $evidenceValid = $serializedEvidence -notmatch '(?i)transcript|raw_nonce|api[_-]?key|credential|terminal_history|[A-Z]:\\'
        }
        [void]$results.Add((New-Topic07ContextContinuityBooleanResult $evidenceValid `
            'T07-EVIDENCE' 'Deterministic evidence records the blocker and zero external provider/model processes without sensitive paths' `
            'Topic 07 deterministic evidence is missing, unsafe, or overstates promotion'))

        $manifest = Get-Topic07ContextContinuityJson $root 'docs/evidence/current-product/topic-07/manifest.json'
        $manifestValid = $null -ne $manifest -and [int]$manifest.schema_version -eq 1 -and
            [string]$manifest.record_type -ceq 'topic07_current_product_manifest' -and
            [string]$manifest.repository.dirty_paths_algorithm -ceq 'sha256(sorted_git_porcelain_v1_lines_utf8_lf)' -and
            [string]$manifest.pinned_omp.commit -ceq $script:Topic07PinnedOmpSha -and
            @($manifest.files).Count -ge 45
        if ($manifestValid) {
            $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            foreach ($row in @($manifest.files)) {
                $relative = [string]$row.path
                $path = Join-Path $root ($relative -replace '/', '\')
                if (-not $seen.Add($relative) -or [string]$row.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
                    -not (Test-Path -LiteralPath $path -PathType Leaf) -or
                    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne [string]$row.sha256) {
                    $manifestValid = $false
                    break
                }
            }
        }
        [void]$results.Add((New-Topic07ContextContinuityBooleanResult $manifestValid `
            'T07-EVIDENCE-HASHES' 'Evidence manifest hashes current authority, implementation, tests, and deterministic evidence' `
            'Topic 07 evidence manifest identity or file hashes do not reconcile'))
    }

    return @($results)
}
