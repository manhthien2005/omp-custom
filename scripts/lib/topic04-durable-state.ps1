#Requires -Version 5.1

Set-StrictMode -Version Latest

function New-Topic04DurableStateResult {
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

function New-Topic04BooleanResult {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$PassMessage,
        [Parameter(Mandatory)][string]$FailMessage
    )

    if ($Condition) {
        return New-Topic04DurableStateResult -Status 'PASS' -Code $Code -Message $PassMessage
    }
    return New-Topic04DurableStateResult -Status 'FAIL' -Code $Code -Message $FailMessage
}

function Get-Topic04Content {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $path = Join-Path $RepositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return '' }
    return Get-Content -Raw -LiteralPath $path -Encoding UTF8
}

function Get-Topic04Json {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $content = Get-Topic04Content -RepositoryRoot $RepositoryRoot -RelativePath $RelativePath
    if (-not $content) { return $null }
    try { return $content | ConvertFrom-Json } catch { return $null }
}

function Test-Topic04ContainsAll {
    param(
        [AllowEmptyString()][string]$Content,
        [Parameter(Mandatory)][string[]]$Needles
    )

    foreach ($needle in $Needles) {
        if ($Content.IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -lt 0) { return $false }
    }
    return $true
}

function Test-Topic04DurableStateContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $decision = Get-Topic04Content $RepositoryRoot 'spec/key/04-decision-log.md'
    $dna = Get-Topic04Content $RepositoryRoot 'spec/key/01-dna.md'
    $tokenModel = Get-Topic04Content $RepositoryRoot 'spec/key/03-token-quality-model.md'
    $target = Get-Topic04Content $RepositoryRoot 'spec/01-target-architecture.md'
    $runtime = Get-Topic04Content $RepositoryRoot 'spec/02-runtime-semantics.md'
    $workflow = Get-Topic04Content $RepositoryRoot 'spec/04-workflow-sizing.md'
    $context = Get-Topic04Content $RepositoryRoot 'spec/05-context-and-token-model.md'
    $isolation = Get-Topic04Content $RepositoryRoot 'spec/08-isolation-and-concurrency.md'
    $review = Get-Topic04Content $RepositoryRoot 'spec/10-verification-and-review.md'
    $installSpec = Get-Topic04Content $RepositoryRoot 'spec/12-installation-and-rollback.md'
    $validation = Get-Topic04Content $RepositoryRoot 'spec/13-validation-and-evaluation.md'
    $governance = Get-Topic04Content $RepositoryRoot 'spec/14-upgradeability-and-governance.md'
    $security = Get-Topic04Content $RepositoryRoot 'spec/15-security-and-failure-recovery.md'
    $migration = Get-Topic04Content $RepositoryRoot 'spec/16-migration-plan.md'
    $specReadme = Get-Topic04Content $RepositoryRoot 'spec/README.md'
    $phase02 = Get-Topic04Content $RepositoryRoot 'spec/phases/phase-02-core-orchestration.md'
    $phase03 = Get-Topic04Content $RepositoryRoot 'spec/phases/phase-03-context-efficiency.md'
    $phase05 = Get-Topic04Content $RepositoryRoot 'spec/phases/phase-05-installation-hardening.md'
    $phase06 = Get-Topic04Content $RepositoryRoot 'spec/phases/phase-06-evaluation.md'
    $phase07 = Get-Topic04Content $RepositoryRoot 'spec/phases/phase-07-stabilization.md'
    $installer = Get-Topic04Content $RepositoryRoot 'scripts/install-template.ps1'
    $protocol = Get-Topic04Content $RepositoryRoot 'template/.omp/state/PROTOCOL.md'
    $retention = Get-Topic04Content $RepositoryRoot 'template/.omp/state/lib/AgentTasks.Retention.ps1'
    $taskStateDoc = Get-Topic04Content $RepositoryRoot 'docs/task-state.md'
    $architectureDoc = Get-Topic04Content $RepositoryRoot 'docs/architecture.md'
    $securityDoc = Get-Topic04Content $RepositoryRoot 'docs/security.md'
    $rootReadme = Get-Topic04Content $RepositoryRoot 'README.md'
    $schema = Get-Topic04Json $RepositoryRoot 'template/.omp/state/schemas/agent-tasks-v1.schema.json'
    $manifest = Get-Topic04Json $RepositoryRoot 'template/.omp/state/manifest.json'
    $adapter = Get-Topic04Json $RepositoryRoot 'docs/evidence/current-product/topic-04/adapter-gate.json'

    # Prose contracts intentionally wrap lines. Collapse whitespace before phrase checks while
    # retaining installer source as raw text for exact line-shape validation.
    $decision = [regex]::Replace($decision, '\s+', ' ')
    $dna = [regex]::Replace($dna, '\s+', ' ')
    $tokenModel = [regex]::Replace($tokenModel, '\s+', ' ')
    $target = [regex]::Replace($target, '\s+', ' ')
    $runtime = [regex]::Replace($runtime, '\s+', ' ')
    $workflow = [regex]::Replace($workflow, '\s+', ' ')
    $context = [regex]::Replace($context, '\s+', ' ')
    $isolation = [regex]::Replace($isolation, '\s+', ' ')
    $review = [regex]::Replace($review, '\s+', ' ')
    $installSpec = [regex]::Replace($installSpec, '\s+', ' ')
    $validation = [regex]::Replace($validation, '\s+', ' ')
    $governance = [regex]::Replace($governance, '\s+', ' ')
    $security = [regex]::Replace($security, '\s+', ' ')
    $migration = [regex]::Replace($migration, '\s+', ' ')
    $specReadme = [regex]::Replace($specReadme, '\s+', ' ')
    $phase02 = [regex]::Replace($phase02, '\s+', ' ')
    $phase03 = [regex]::Replace($phase03, '\s+', ' ')
    $phase05 = [regex]::Replace($phase05, '\s+', ' ')
    $phase06 = [regex]::Replace($phase06, '\s+', ' ')
    $phase07 = [regex]::Replace($phase07, '\s+', ' ')
    $retention = [regex]::Replace($retention, '\s+', ' ')
    $taskStateDoc = [regex]::Replace($taskStateDoc, '\s+', ' ')
    $architectureDoc = [regex]::Replace($architectureDoc, '\s+', ' ')
    $securityDoc = [regex]::Replace($securityDoc, '\s+', ' ')
    $rootReadme = [regex]::Replace($rootReadme, '\s+', ' ')

    $results = @()

    $gitRootValid = $decision.Contains('git_root: <absolute-git-common-dir>/agent-tasks') -and
        $decision.Contains('non_git_root: <project-root>/.agent-tasks') -and
        $taskStateDoc.Contains('<git-common-dir>/agent-tasks')
    $results += New-Topic04BooleanResult $gitRootValid 'T04-ROOT-GIT-COMMON' `
        'Git and non-Git authority roots are explicit' 'KD-028 or task-state docs lost the selected authority roots'

    $namespaceValid = $decision.Contains('git_root: <absolute-git-common-dir>/agent-tasks') -and
        $decision -notmatch 'git_root: <absolute-git-common-dir>/agent-task(?:\s|$)' -and
        $specReadme.Contains('`<absolute-git-common-dir>/agent-tasks` (plural)')
    $results += New-Topic04BooleanResult $namespaceValid 'T04-ROOT-NAMESPACE' `
        'The selected Git namespace is agent-tasks plural' 'The selected Git authority namespace must be agent-tasks plural'

    $authorityForbidden = $dna -match '(?i)(?:^|\s)(?:a\s+)?transcript\s+becomes?\s+(?:the\s+)?(?:lifecycle\s+)?source of truth\.'
    $authorityValid = $false
    if ($dna.Contains('Keep durable authority outside runtime memory') -and $decision -match '(?i)is context.{0,3}not lifecycle authority') {
        $authorityValid = -not ([bool]$authorityForbidden)
    }
    $results += New-Topic04BooleanResult $authorityValid 'T04-STATE-AUTHORITY' `
        'Conversation and raw transport remain non-authoritative' 'Transcript, handoff, compaction, or raw transport was promoted to authority'

    $revisionValid = Test-Topic04ContainsAll $runtime @('immutable', 'expected revision', 'revision hash', 'mismatch refuses')
    $revisionValid = $revisionValid -and $runtime -notmatch '(?i)(?:^|\s)Use current\.json with last-write-wins'
    $results += New-Topic04BooleanResult $revisionValid 'T04-REVISION-IMMUTABLE' `
        'Immutable revisions and compare-and-swap refusal are projected' 'Mutable current.json or last-write-wins semantics appeared'

    $leaseValid = $runtime.Contains('There is no heartbeat TTL') -and
        $runtime.Contains('crash takeover needs explicit structured user authority') -and
        $runtime -notmatch '(?i)heartbeat timeout triggers automatic takeover'
    $results += New-Topic04BooleanResult $leaseValid 'T04-WRITER-LEASE' `
        'Writer leases do not expire by heartbeat and takeover is explicit' 'Writer lease semantics permit timeout or automatic takeover'

    $worktreeValid = $isolation.Contains('distinct authoritative worktree') -and
        $isolation.Contains('One task has one authority/integration writer') -and
        $isolation.Contains('never creates, deletes, merges, or prunes Git worktrees') -and
        $isolation -notmatch '(?i)concurrent mutating tasks share authoritative worktree'
    $results += New-Topic04BooleanResult $worktreeValid 'T04-WORKTREE-RESERVATION' `
        'Mutating tasks use distinct authoritative worktrees and reservations' 'Shared authoritative writer worktrees or state-owned worktree lifecycle appeared'

    $candidateScopeValid = $review.Contains('core derives candidate entries and scope dispositions') -and
        $review.Contains('model never supplies the final owned-output list') -and
        $review -notmatch '(?i)(?:^|\s)The model supplies the final owned-output list\.'
    $results += New-Topic04BooleanResult $candidateScopeValid 'T04-CANDIDATE-SCOPE' `
        'Candidate scope is deterministically derived' 'A model-authored final candidate scope was allowed'

    $candidateEvidenceValid = $review.Contains('old candidate evidence cannot be accepted after mutation') -and
        $review.Contains('a new C2 candidate needs new applicable evidence')
    $results += New-Topic04BooleanResult $candidateEvidenceValid 'T04-CANDIDATE-EVIDENCE' `
        'Evidence invalidates across candidate mutation' 'Old candidate evidence may satisfy a mutated candidate'

    $ttlValid = $tokenModel.Contains('there is no global evidence TTL because validity is trigger-based') -and
        $tokenModel -notmatch '(?i)(?:^|\s)(?:Use|Apply)\s+(?:a\s+)?global evidence TTL'
    $results += New-Topic04BooleanResult $ttlValid 'T04-EVIDENCE-TTL' `
        'Evidence validity is trigger-based without a global TTL' 'A global evidence TTL was introduced'

    $handoffValid = $runtime.Contains('Normal handoff is two-phase structured transfer') -and
        $runtime -notmatch '(?i)(?:^|\s)Handoff prose alone transfers ownership\.'
    $results += New-Topic04BooleanResult $handoffValid 'T04-HANDOFF-TRANSFER' `
        'Handoff uses checked two-phase transfer' 'Prose-only ownership transfer was allowed'

    $offloadValid = $context.Contains('transient raw offload, not lifecycle authority or acceptance evidence') -and
        $context.Contains('bounded sanitized artifacts') -and
        $context -notmatch '(?i)(?:^|\s)artifact:// and \.task become lifecycle authority\.'
    $results += New-Topic04BooleanResult $offloadValid 'T04-OFFLOAD-AUTHORITY' `
        'Raw offload remains transient and promoted proof is bounded' 'Raw offload or runtime artifacts became lifecycle authority'

    $forbiddenNames = @()
    if ($null -ne $schema) {
        try { $forbiddenNames = @($schema.'$defs'.requestPayload.propertyNames.not.enum) } catch { $forbiddenNames = @() }
    }
    $requiredForbidden = @('transcript', 'reasoning', 'api_key', 'token', 'secret', 'credential', 'env_contents', 'terminal_history')
    $secretValid = $forbiddenNames.Count -gt 0 -and @($requiredForbidden | Where-Object { $forbiddenNames -cnotcontains $_ }).Count -eq 0
    $results += New-Topic04BooleanResult $secretValid 'T04-SECRET-BOUNDARY' `
        'State request schema rejects transcript and secret-bearing fields' 'State schema secret/transcript denylist is incomplete'

    $cleanupValid = Test-Topic04ContainsAll $security @('dry-run first', 'recoverable trash', 'separate exact-ID confirmation', 'never deletes a Git worktree')
    $cleanupValid = $cleanupValid -and $retention -notmatch '(?i)git\s+worktree\s+(?:remove|prune)' -and
        $security -notmatch '(?i)(?:^|\s)Cleanup automatically purges and runs git worktree remove\.'
    $results += New-Topic04BooleanResult $cleanupValid 'T04-CLEANUP-SAFETY' `
        'Cleanup is previewed, recoverable, and never manages worktrees' 'Automatic purge or Git worktree deletion appeared'

    $adapterValid = $null -ne $adapter -and
        [string]$adapter.manual_core_adapter -ceq 'SELECTED' -and
        [string]$adapter.automatic_lifecycle_adapter -ceq 'NOT_INSTALLED' -and
        [string]$adapter.reason_code -ceq 'TOPIC08_INSTALLED_RUNTIME_PROBE_REQUIRED'
    $results += New-Topic04BooleanResult $adapterValid 'T04-ADAPTER-GATE' `
        'Manual core is selected and automatic attachment remains gated' 'Adapter evidence falsely claims an unprobed automatic lifecycle hook'

    $manifestValid = $null -ne $manifest -and [int]$manifest.schema_version -eq 1 -and
        [string]$manifest.minimum_pwsh_version -ceq '7.4.0' -and @($manifest.files).Count -ge 11
    $installValid = $installer -match '(?m)^\s*"state"\s+=\s+"state"\s*$' -and
        $installer -match '(?s)\$Components\s*=.*?"state"' -and $manifestValid -and $protocol.Length -gt 100
    $results += New-Topic04BooleanResult $installValid 'T04-INSTALL-COMPONENT' `
        'Installer owns the manifest-validated default state component' 'State is missing from installer defaults/map or its component contract is incomplete'

    $phaseValid = $phase02.Contains('Topic 04 consumes task, candidate, and work-unit authority.') -and
        $phase03.Contains('Topic 04 consumes checkpoints, handoff, and offload boundaries.') -and
        $phase05.Contains('Topic 04 consumes state-core installation and rollback retention.') -and
        $phase06.Contains('Topic 04 consumes deterministic and behavioral lifecycle fixtures.') -and
        $phase07.Contains('Topic 04 consumes release limitation and migration reconciliation.')
    $results += New-Topic04BooleanResult $phaseValid 'T04-PHASE-OWNERSHIP' `
        'Existing phases project all Topic 04 consumer responsibilities' 'One or more Topic 04 phase projections are missing'

    $requirements = @(
        @('T04-REQ-01', ($gitRootValid -and $target.Contains('Operational hierarchy is project')), 'local authority root is selected outside Git history'),
        @('T04-REQ-02', ($taskStateDoc.Contains('shared by linked worktrees')), 'linked worktrees share the Git common-dir authority'),
        @('T04-REQ-03', ($workflow.Contains('accepted, Quick, Standard, and Orchestrated create task state before mutation')), 'accepted contracts create state before mutation'),
        @('T04-REQ-04', $revisionValid, 'state revisions are immutable'),
        @('T04-REQ-05', ($runtime.Contains('expected revision, revision hash, and lease generation')), 'mutations use CAS revision/hash/lease checks'),
        @('T04-REQ-06', ($leaseValid -and $decision.Contains('one authority/integration lease per task')), 'one non-expiring writer lease owns each task'),
        @('T04-REQ-07', $worktreeValid, 'mutating tasks reserve distinct authoritative worktrees'),
        @('T04-REQ-08', ($review.Contains('baseline') -or $decision.Contains('baseline')), 'candidate identity is baseline-relative and scoped'),
        @('T04-REQ-09', ($decision.Contains('manifest, not backup') -and $rootReadme.Contains('not a source backup')), 'candidate manifest is identity rather than backup'),
        @('T04-REQ-10', ($review.Contains('Evidence types have closed producer/binding/validity rules')), 'evidence has typed closed producer and validity rules'),
        @('T04-REQ-11', $candidateEvidenceValid, 'evidence binds the exact candidate and inputs'),
        @('T04-REQ-12', $ttlValid, 'validity triggers replace a global evidence TTL'),
        @('T04-REQ-13', $handoffValid, 'normal handoff is two-phase'),
        @('T04-REQ-14', ($leaseValid -and $security.Contains('explicit user authority')), 'crash takeover is explicitly user-authorized'),
        @('T04-REQ-15', $offloadValid, 'raw offload remains transient'),
        @('T04-REQ-16', ($context.Contains('bounded sanitized artifacts are') -or $context.Contains('bounded sanitized artifacts')), 'only compact sanitized evidence is promoted'),
        @('T04-REQ-17', ($secretValid -and $securityDoc.Contains('rejects transcripts')), 'state excludes transcripts and secrets'),
        @('T04-REQ-18', ($cleanupValid -and $retention.Contains("[string]`$Mode = 'dry-run'")), 'cleanup defaults to dry-run'),
        @('T04-REQ-19', ($taskStateDoc.Contains('archive is recoverable from trash')), 'archive uses recoverable trash'),
        @('T04-REQ-20', ($retention.Contains('Purge confirmation must exactly equal the task identifier')), 'purge requires exact task confirmation'),
        @('T04-REQ-21', ($installValid -and $installSpec.Contains('`pwsh` 7.4+')), 'state is a default manifest-validated pwsh 7.4+ component'),
        @('T04-REQ-22', ($installSpec.Contains('never read, write, migrate, or delete operational') -and $taskStateDoc.Contains('never removes or rewrites')), 'installer and rollback preserve operational state'),
        @('T04-REQ-23', ($target.Contains('used explicitly by both Claude and Codex/OMP') -and $protocol.Length -gt 100), 'Claude and Codex/OMP share one explicit core'),
        @('T04-REQ-24', ($adapterValid -and $migration.Contains('Topic 08 may lift it to automatic lifecycle events')), 'automatic adapter remains behind the Topic 08 probe'),
        @('T04-REQ-25', ($governance.Contains('Unknown newer authority schemas are status-only') -and $migration.Contains('marked read-only backup') -and $architectureDoc.Contains('The plural namespace is fixed')), 'migration, newer-schema status, and local limitations are explicit')
    )

    foreach ($requirement in $requirements) {
        $condition = [bool]$requirement[1]
        $message = [string]$requirement[2]
        $results += New-Topic04BooleanResult $condition ([string]$requirement[0]) $message ("approved design requirement is missing: " + $message)
    }

    return $results
}
