#Requires -Version 5.1

Set-StrictMode -Version Latest

function New-Topic03TopologyResult {
    param(
        [ValidateSet('PASS', 'FAIL', 'WARN')][string]$Status,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Message
    )

    [pscustomobject]@{
        Status = $Status
        Code = $Code
        Message = $Message
    }
}

function Get-Topic03NormalizedContent {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $path = Join-Path $RepositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $null
    }
    $content = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    return [regex]::Replace($content, '\s+', ' ').Trim()
}

function Get-Topic03FileContent {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $path = Join-Path $RepositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $null
    }
    return Get-Content -Raw -LiteralPath $path -Encoding UTF8
}

function New-Topic03BooleanResult {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$PassMessage,
        [Parameter(Mandatory)][string]$FailMessage
    )

    if ($Condition) {
        return New-Topic03TopologyResult -Status 'PASS' -Code $Code -Message $PassMessage
    }
    return New-Topic03TopologyResult -Status 'FAIL' -Code $Code -Message $FailMessage
}

function Get-Topic03FrontmatterField {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Name
    )

    $match = [regex]::Match($Content, "(?m)^\s*$([regex]::Escape($Name)):\s*(.*?)\s*$")
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups[1].Value.Trim().Trim('"').Trim("'")
}

function Test-Topic03DesignContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $content = Get-Topic03NormalizedContent -RepositoryRoot $RepositoryRoot -RelativePath 'docs/superpowers/specs/2026-08-12-topic-03-agent-topology-model-routing-design.md'
    if ($null -eq $content) {
        return New-Topic03TopologyResult -Status 'FAIL' -Code 'T03-DESIGN-MISSING' -Message 'approved Topic 03 design is missing'
    }

    $required = @(
        'selected runtime manifest has three logical agents: Cheap Scout, Worker, Reviewer',
        'Cheap Scout uses DeepSeek V4 Flash at `max`, then V4 Pro at `max`, then Tech Lead retrieval',
        'Worker uses `high` for moderate tasks and Tech Lead-selected `xhigh` for hard tasks',
        'Reviewer always uses `xhigh`',
        'Opus is never implicitly mandatory'
    )
    $missing = @($required | Where-Object { $content.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -lt 0 })
    return New-Topic03BooleanResult -Condition ($missing.Count -eq 0) -Code 'T03-DESIGN-CONTRACT' `
        -PassMessage 'approved Topic 03 decisions are present' `
        -FailMessage "approved Topic 03 design is missing: $($missing -join '; ')"
}

function Test-Topic03SpecContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $topology = Get-Topic03NormalizedContent -RepositoryRoot $RepositoryRoot -RelativePath 'spec/03-agent-topology.md'
    $routing = Get-Topic03NormalizedContent -RepositoryRoot $RepositoryRoot -RelativePath 'spec/09-model-routing.md'
    $decision = Get-Topic03NormalizedContent -RepositoryRoot $RepositoryRoot -RelativePath 'spec/key/04-decision-log.md'
    $phase02 = Get-Topic03NormalizedContent -RepositoryRoot $RepositoryRoot -RelativePath 'spec/phases/phase-02-core-orchestration.md'
    $phase06 = Get-Topic03NormalizedContent -RepositoryRoot $RepositoryRoot -RelativePath 'spec/phases/phase-06-evaluation.md'

    $benefitGate = $null -ne $topology -and
        $topology.IndexOf('Default to no subagent spawn', [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
        $topology.IndexOf('concrete benefit', [StringComparison]::OrdinalIgnoreCase) -ge 0
    $results += New-Topic03BooleanResult -Condition $benefitGate -Code 'T03-SPAWN-BENEFIT-GATE' `
        -PassMessage 'spec defaults to no spawn and requires a concrete benefit' `
        -FailMessage 'spec must default to no spawn and require a concrete benefit'

    $projectionValid =
        $null -ne $routing -and $routing -match '(?i)deepseek-v4-flash:xhigh' -and $routing -match '(?i)deepseek-v4-pro:xhigh' -and
        $null -ne $decision -and $decision -match '(?i)KD-027' -and
        $null -ne $phase02 -and $phase02 -match '(?i)cheap-scout.{0,80}worker.{0,80}reviewer' -and
        $null -ne $phase06 -and $phase06 -match '(?i)three-agent manifest'
    $results += New-Topic03BooleanResult -Condition $projectionValid -Code 'T03-SPEC-PROJECTION' `
        -PassMessage 'routing, decision, and phase projections are present' `
        -FailMessage 'routing, KD-027, or phase projection is incomplete'

    return $results
}

function Test-Topic03RuntimeManifestContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $agentsDirectory = Join-Path $RepositoryRoot 'template/.omp/agents'
    $agentNames = @()
    if (Test-Path -LiteralPath $agentsDirectory -PathType Container) {
        $agentNames = @(Get-ChildItem -LiteralPath $agentsDirectory -File -Filter '*.md' |
            ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) })
    }

    $oldAgents = @($agentNames | Where-Object { @('explorer', 'implementer', 'verifier') -ccontains $_ })
    $results += New-Topic03BooleanResult -Condition ($oldAgents.Count -eq 0) -Code 'T03-MANIFEST-OLD-AGENT' `
        -PassMessage 'retired agent definitions are absent' `
        -FailMessage "retired agent definitions remain: $($oldAgents -join ', ')"

    $results += New-Topic03BooleanResult -Condition (-not ($agentNames -ccontains 'tech-lead')) -Code 'T03-TECHLEAD-SPAWNABLE' `
        -PassMessage 'Tech Lead remains outside spawn discovery' `
        -FailMessage 'template/.omp/agents/tech-lead.md makes the main-session Tech Lead spawnable'

    $scoutPresent = $agentNames -ccontains 'cheap-scout'
    $results += New-Topic03BooleanResult -Condition $scoutPresent -Code 'T03-MANIFEST-SCOUT-MISSING' `
        -PassMessage 'Cheap Scout definition is present' `
        -FailMessage 'template/.omp/agents/cheap-scout.md is missing'

    $workerPresent = $agentNames -ccontains 'worker'
    $reviewerPresent = $agentNames -ccontains 'reviewer'
    $unexpected = @($agentNames | Where-Object { @('cheap-scout', 'worker', 'reviewer', 'tech-lead', 'explorer', 'implementer', 'verifier') -cnotcontains $_ })
    $selectedShapeValid = $workerPresent -and $reviewerPresent -and $unexpected.Count -eq 0
    $results += New-Topic03BooleanResult -Condition $selectedShapeValid -Code 'T03-MANIFEST-SELECTED-SET' `
        -PassMessage 'Worker and Reviewer complete the selected three-agent set' `
        -FailMessage "selected set is incomplete or unexpected: $($agentNames -join ', ')"

    if ($scoutPresent) {
        $scoutContent = Get-Topic03FileContent -RepositoryRoot $RepositoryRoot -RelativePath 'template/.omp/agents/cheap-scout.md'
        $scoutTools = Get-Topic03FrontmatterField -Content $scoutContent -Name 'tools'
        $mutatingTool = @($scoutTools -split '\s*,\s*' | Where-Object { @('edit', 'write', 'bash') -ccontains $_ }).Count -gt 0
        $results += New-Topic03BooleanResult -Condition (-not $mutatingTool) -Code 'T03-SCOUT-WRITE-TOOL' `
            -PassMessage 'Cheap Scout has no mutating tool' `
            -FailMessage 'Cheap Scout exposes edit, write, or bash'

        $scoutEffort = Get-Topic03FrontmatterField -Content $scoutContent -Name 'thinking-level'
        $results += New-Topic03BooleanResult -Condition ($scoutEffort -ceq 'xhigh') -Code 'T03-SCOUT-EFFORT' `
            -PassMessage 'Cheap Scout uses exact xhigh selector effort' `
            -FailMessage "Cheap Scout thinking-level must be xhigh, got '$scoutEffort'"
    }

    if ($workerPresent) {
        $workerContent = Get-Topic03FileContent -RepositoryRoot $RepositoryRoot -RelativePath 'template/.omp/agents/worker.md'
        $workerEffort = Get-Topic03FrontmatterField -Content $workerContent -Name 'thinking-level'
        $results += New-Topic03BooleanResult -Condition ($workerEffort -ceq 'high') -Code 'T03-WORKER-DEFAULT-EFFORT' `
            -PassMessage 'Worker defaults to high' `
            -FailMessage "Worker default thinking-level must be high, got '$workerEffort'"
    }

    if ($reviewerPresent) {
        $reviewerContent = Get-Topic03FileContent -RepositoryRoot $RepositoryRoot -RelativePath 'template/.omp/agents/reviewer.md'
        $reviewerEffort = Get-Topic03FrontmatterField -Content $reviewerContent -Name 'thinking-level'
        $results += New-Topic03BooleanResult -Condition ($reviewerEffort -ceq 'xhigh') -Code 'T03-REVIEWER-EFFORT' `
            -PassMessage 'Reviewer is fixed at xhigh' `
            -FailMessage "Reviewer thinking-level must be xhigh, got '$reviewerEffort'"

        $normalizedReviewer = [regex]::Replace($reviewerContent, '\s+', ' ')
        $riskGateValid = $normalizedReviewer.IndexOf('Review is mandatory for security, authentication, durable data, database migration, concurrency, public API, and destructive change concerns', [StringComparison]::OrdinalIgnoreCase) -ge 0
        $results += New-Topic03BooleanResult -Condition $riskGateValid -Code 'T03-REVIEW-RISK-GATE' `
            -PassMessage 'Reviewer carries the mandatory high-risk concern gate' `
            -FailMessage 'Reviewer is missing the mandatory high-risk concern gate'
    }

    $opusFiles = @(
        'spec/03-agent-topology.md',
        'spec/09-model-routing.md',
        'template/.omp/AGENTS.md',
        'template/.omp/commands/quick.md',
        'template/.omp/commands/standard.md',
        'template/.omp/commands/orchestrated.md'
    )
    $opusText = ($opusFiles | ForEach-Object { Get-Topic03FileContent -RepositoryRoot $RepositoryRoot -RelativePath $_ }) -join "`n"
    $opusMandatory = $opusText -match '(?i)(?:unavailable\s+Opus|Opus\s+unavailable).{0,60}(?:blocks?\s+all\s+review|blocks?\s+the\s+task|mandatory|required)'
    $results += New-Topic03BooleanResult -Condition (-not $opusMandatory) -Code 'T03-OPUS-MANDATORY' `
        -PassMessage 'Opus is not an implicit review gate' `
        -FailMessage 'active runtime makes unavailable Opus an implicit review blocker'

    return $results
}

function Test-Topic03RoutingContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $config = Get-Topic03FileContent -RepositoryRoot $RepositoryRoot -RelativePath 'template/.omp/config.yml'
    if ($null -eq $config) {
        return New-Topic03TopologyResult -Status 'FAIL' -Code 'T03-CONFIG-MISSING' -Message 'template/.omp/config.yml is missing'
    }

    $primaryValid = $config -match '(?m)^\s{2}cheap-scout:\s*omniroute/ds/deepseek-v4-flash:xhigh\s*$'
    $results += New-Topic03BooleanResult -Condition $primaryValid -Code 'T03-CONFIG-SCOUT-PRIMARY' `
        -PassMessage 'Cheap Scout primary is Flash xhigh' `
        -FailMessage 'modelRoles.cheap-scout must be Flash xhigh'

    $fallbackValid = $config -match '(?ms)^\s{4}cheap-scout:\s*\r?\n\s{6}-\s*omniroute/ds/deepseek-v4-pro:xhigh\s*$'
    $results += New-Topic03BooleanResult -Condition $fallbackValid -Code 'T03-CONFIG-SCOUT-FALLBACK' `
        -PassMessage 'Cheap Scout fallback contains only Pro xhigh' `
        -FailMessage 'retry.fallbackChains.cheap-scout must contain Pro xhigh'

    $workerIdentityValid = $config -match '(?m)^\s{2}worker:\s*omniroute/codex/gpt-5\.6-sol:high\s*$'
    $results += New-Topic03BooleanResult -Condition $workerIdentityValid -Code 'T03-CONFIG-WORKER-IDENTITY' `
        -PassMessage 'Worker default high effort is explicit in the resolved selector' `
        -FailMessage 'modelRoles.worker must carry an explicit :high suffix for observable identity'

    $reviewerIdentityValid = $config -match '(?m)^\s{2}reviewer:\s*omniroute/codex/gpt-5\.6-sol:xhigh\s*$'
    $results += New-Topic03BooleanResult -Condition $reviewerIdentityValid -Code 'T03-CONFIG-REVIEWER-IDENTITY' `
        -PassMessage 'Reviewer fixed xhigh effort is explicit in the resolved selector' `
        -FailMessage 'modelRoles.reviewer must carry an explicit :xhigh suffix for observable identity'

    $emptyDefault = $config -match '(?m)^\s{4}default:\s*\[\]\s*$'
    $emptyWorker = $config -match '(?m)^\s{4}worker:\s*\[\]\s*$'
    $emptyReviewer = $config -match '(?m)^\s{4}reviewer:\s*\[\]\s*$'
    $results += New-Topic03BooleanResult -Condition ($emptyDefault -and $emptyWorker -and $emptyReviewer) -Code 'T03-CONFIG-DEFAULT-FALLBACK' `
        -PassMessage 'default, Worker, and Reviewer fallback chains are empty' `
        -FailMessage 'default, Worker, and Reviewer fallback chains must remain empty'

    $effortValid = $config -match '(?m)^\s{2}enableEffort:\s*true\s*$' -and $config -match '(?m)^\s{2}maxEffort:\s*xhigh\s*$'
    $results += New-Topic03BooleanResult -Condition $effortValid -Code 'T03-CONFIG-EFFORT' `
        -PassMessage 'per-spawn effort is enabled and capped at xhigh' `
        -FailMessage 'task.enableEffort=true and task.maxEffort=xhigh are required'

    $commandsDirectory = Join-Path $RepositoryRoot 'template/.omp/commands'
    $commandText = ''
    if (Test-Path -LiteralPath $commandsDirectory -PathType Container) {
        $commandText = (Get-ChildItem -LiteralPath $commandsDirectory -File -Filter '*.md' |
            ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName -Encoding UTF8 }) -join "`n"
    }
    $fixedChain = $commandText -match '(?is)Explorer\s*(?:-|=)*>\s*Implementer\s*(?:-|=)*>\s*Verifier'
    $results += New-Topic03BooleanResult -Condition (-not $fixedChain) -Code 'T03-COMMAND-FIXED-CHAIN' `
        -PassMessage 'commands do not hard-code the retired role chain' `
        -FailMessage 'command hard-codes Explorer -> Implementer -> Verifier'

    return $results
}

function Test-Topic03InstallContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $results = @()
    $installer = Get-Topic03FileContent -RepositoryRoot $RepositoryRoot -RelativePath 'scripts/install-template.ps1'
    $retirementValid = $null -ne $installer -and $installer -match '(?i)Remove-Item\s+-LiteralPath' -and
        @('explorer.md', 'implementer.md', 'tech-lead.md', 'verifier.md').Count -eq @(
            @('explorer.md', 'implementer.md', 'tech-lead.md', 'verifier.md') | Where-Object { $installer.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -ge 0 }
        ).Count
    $results += New-Topic03BooleanResult -Condition $retirementValid -Code 'T03-INSTALL-STALE-AGENT' `
        -PassMessage 'installer explicitly retires every stale agent after backup' `
        -FailMessage 'installer does not explicitly retire explorer, implementer, tech-lead, and verifier'

    $evidence = Get-Topic03NormalizedContent -RepositoryRoot $RepositoryRoot -RelativePath 'docs/evidence/current-product/topic-03/manifest.yml'
    $supersessionValid = $false
    if ($null -ne $evidence) {
        try {
            $evidenceManifest = $evidence | ConvertFrom-Json -ErrorAction Stop
            $supersessionValid =
                [string]$evidenceManifest.schema_version -ceq '1' -and
                $evidenceManifest.topic -ceq '03' -and
                $evidenceManifest.candidate -ceq 'C1' -and
                $evidenceManifest.phase00_source -ceq 'T-00.3' -and
                $evidenceManifest.phase00_conclusion_sha256 -cmatch '^[A-F0-9]{64}$'
        } catch {
            $supersessionValid = $false
        }
    }
    $results += New-Topic03BooleanResult -Condition $supersessionValid -Code 'T03-EVIDENCE-SUPERSESSION' `
        -PassMessage 'current-product evidence explicitly supersedes the Phase 00 runtime snapshot' `
        -FailMessage 'current-product manifest lacks the Phase 00 supersession identity'

    return $results
}

function Test-Topic03TopologyRoutingContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $resolvedRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
    $results = @()
    $results += Test-Topic03DesignContract -RepositoryRoot $resolvedRoot
    $results += Test-Topic03SpecContract -RepositoryRoot $resolvedRoot
    $results += Test-Topic03RuntimeManifestContract -RepositoryRoot $resolvedRoot
    $results += Test-Topic03RoutingContract -RepositoryRoot $resolvedRoot
    $results += Test-Topic03InstallContract -RepositoryRoot $resolvedRoot
    return $results
}
