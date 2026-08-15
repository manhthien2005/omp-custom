# Topic 02 Workflow Entry and Task Lifecycle Architecture Projection Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Execution correction (2026-08-12):** The attachment authorizes architecture analysis to
> patch specs/phases after user approval. Installable prompt files are also hash-locked
> destinations of the immutable Phase 00 T-00.3 evidence snapshot. The initial draft below
> incorrectly scheduled direct runtime/product-doc mutation. Those edits were fully withdrawn;
> their exact pre-Topic-02 hashes are restored. Runtime projection is now an explicit Phase 02
> migration with a new evidence identity.

**Goal:** Project the approved contract-first workflow entry and lifecycle design into the
canonical specifications and phase plans, with focused static validation, without implementing
Topic 03 topology, Topic 04 durable state, Topic 08 triage, or Phase 02 runtime behavior.

**Architecture:** `spec/04-workflow-sizing.md` becomes the single authority for workflow entry,
classification, and the conceptual phase/task/candidate/session lifecycle. Supporting specs
project that authority. Phase 02 owns the later runtime adapter migration and must preserve the
historical Phase 00 evidence while creating a new current-product evidence chain. A focused
PowerShell validator checks the spec/phase contract only.

**Tech Stack:** Markdown specifications and prompt files, PowerShell 5.1 static validation,
pinned OMP TypeScript source for read-only runtime grounding, Git read-only inspection.

## Global Constraints

- A plain natural-language request is a valid normal entry; it does not require a command
  prefix.
- The user explicitly selects Quick with `/quick`; the main-session Tech Lead selects Standard
  or Orchestrated.
- `/standard` and `/orchestrated`, and the same words without `/`, are compatibility or
  natural-language routing hints. They do not bypass Tech Lead validation.
- Workflow reclassification is internal state, never model-authored reinvocation of a slash
  command.
- A phase is a program of tasks; a task begins only after its objective, scope, authority, and
  mandatory acceptance criteria are accepted as one contract.
- Candidate evidence is snapshot-bound. Any acceptance-bearing mutation after freeze
  invalidates that evidence and requires the next candidate snapshot.
- A session serves one task and one non-competing candidate lineage. Bounded C1-to-C2 rework may
  stay in that session.
- Compaction remains within one session/work unit. Handoff creates a successor session for the
  same task/candidate lineage and is never authoritative state by itself.
- Orchestrated requires at least two independently verifiable work units plus an integration
  contract and cross-boundary verification. It does not require parallel execution, multiple
  agents, or multiple writers.
- Cheap Scout remains optional, configurable, read-only, and fail-soft. It does not own routing
  or lifecycle state.
- Topic 03 owns detailed agent/model topology. Topic 04 owns durable IDs, persistence, ownership
  leases, and recovery. Topic 08 owns deeper task-triage behavior.
- Preserve every pre-existing dirty-worktree change. Patch only the named sections and never
  reset, revert, overwrite, or delete unrelated user work.
- Treat the DNA worktree and `_research/upstreams` as read-only.
- Do not modify historical evidence or earlier review responses. Design records remain history;
  active specs and the decision log record supersession.
- Do not stage, commit, branch, push, or create a pull request without new user authorization.
- The main agent is the only writer. The user-authorized Codex audit is read-only and occurs
  only after focused and full validation are green.

## Impact Map

### Authority and decision layer

- Rewrite: `spec/04-workflow-sizing.md`
- Append: `spec/key/04-decision-log.md`
- Modify: `spec/key/01-dna.md`
- Modify: `spec/key/03-token-quality-model.md`
- Modify: `spec/05-context-and-token-model.md`
- Modify: `spec/13-validation-and-evaluation.md`

### Topic-boundary notices and phase projections

- Modify: `spec/03-agent-topology.md`
- Modify: `spec/08-isolation-and-concurrency.md`
- Modify: `spec/README.md`
- Modify: `spec/phases/phase-02-core-orchestration.md`
- Modify: `spec/phases/phase-03-context-efficiency.md`
- Modify: `spec/phases/phase-06-evaluation.md`

### Deferred Phase 02 runtime surfaces — verify unchanged in Topic 02

- Preserve: `template/.omp/AGENTS.md`
- Preserve: `template/.omp/commands/quick.md`
- Preserve: `template/.omp/commands/standard.md`
- Preserve: `template/.omp/commands/orchestrated.md`
- Preserve: `template/.omp/agents/tech-lead.md`
- Preserve: `template/.omp/skills/task-triage/SKILL.md`

### Product documentation

- Preserve until the corresponding runtime migration: `README.md`, `docs/architecture.md`,
  `docs/workflow-v0.md`
- Modify: `CHANGELOG.md`

### Validation and audit artifacts

- Create: `scripts/tests/topic02-workflow-lifecycle.Tests.ps1`
- Create: `scripts/lib/topic02-workflow-lifecycle.ps1`
- Create: `scripts/validate-topic02-workflow-lifecycle.ps1`
- Test unchanged: `scripts/validate-template.ps1` (Phase 00 hash-protected)
- Create: `codex-topic02-workflow-entry-task-lifecycle-changelog.md`
- Create: `codex-peer-review-packet-topic02-round1.md`
- Create: `codex-peer-review-prompt-topic02-round1.md`
- Create: `codex-peer-review-response-topic02-round1.md`
- Create: `codex-topic02-closure-status.md`

No registry, license, installer, runtime prompt, product documentation, Phase 00 evidence,
DNA-worktree, upstream, or benchmark-harness file changes are authorized by this Topic 02
projection. The phase dependency DAG remains unchanged.

---

## Executed Architecture Projection

- [x] Focused validator written test-first and scoped to canonical/supporting specs and phases.
- [x] `spec/04` rewritten and KD-026 appended.
- [x] DNA, token-quality, context, evaluation, topology, isolation, and spec overview reconciled.
- [x] Phases 02, 03, and 06 remapped for runtime migration, lifecycle preservation, and evals.
- [x] Runtime/template and product-doc surfaces restored/preserved at their pre-Topic-02 bytes.
- [x] Phase 00 evidence and validator remain green and unchanged.
- [ ] Change ledger, read-only Codex audit, adjudication, and closure record.

## Superseded Initial Execution Draft — Historical Reference Only

Tasks 1–7 below describe the initially attempted direct runtime projection. They are retained
as process history but are not executable authority. The correction and executed checklist
above supersede their file targets, validator scope, and completion claims.

### Task 1: Freeze the edit boundary and add a failing lifecycle contract validator

**Files:**
- Create: `scripts/tests/topic02-workflow-lifecycle.Tests.ps1`
- Create: `scripts/lib/topic02-workflow-lifecycle.ps1`
- Create: `scripts/validate-topic02-workflow-lifecycle.ps1`
- Test unchanged: `scripts/validate-template.ps1`
- Test: the current active specs, template surfaces, and concise documentation named below

**Interfaces:**
- Consumes: the approved design at
  `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md`.
- Produces: `Test-Topic02CanonicalContract`, `Test-Topic02TemplateContract`,
  `Test-Topic02ProjectionContract`, and `Test-Topic02WorkflowLifecycleContract`, each returning
  `{ Status, Code, Message }` records compatible with `validate-template.ps1`.

- [ ] **Step 1: Capture the dirty-state boundary for every target**

Run:

```powershell
git status --short
git status --short -- spec/04-workflow-sizing.md spec/key/01-dna.md `
  spec/key/03-token-quality-model.md spec/key/04-decision-log.md `
  spec/03-agent-topology.md spec/05-context-and-token-model.md `
  spec/08-isolation-and-concurrency.md spec/13-validation-and-evaluation.md `
  spec/README.md spec/phases/phase-02-core-orchestration.md `
  spec/phases/phase-03-context-efficiency.md spec/phases/phase-06-evaluation.md `
  template/.omp/AGENTS.md template/.omp/commands template/.omp/agents/tech-lead.md `
  template/.omp/skills/task-triage/SKILL.md README.md docs/architecture.md `
  docs/workflow-v0.md CHANGELOG.md scripts/validate-template.ps1

$targets = @(
  'spec/04-workflow-sizing.md','spec/key/01-dna.md','spec/key/03-token-quality-model.md',
  'spec/key/04-decision-log.md','spec/03-agent-topology.md',
  'spec/05-context-and-token-model.md','spec/08-isolation-and-concurrency.md',
  'spec/13-validation-and-evaluation.md','spec/README.md',
  'spec/phases/phase-02-core-orchestration.md',
  'spec/phases/phase-03-context-efficiency.md','spec/phases/phase-06-evaluation.md',
  'template/.omp/AGENTS.md','template/.omp/commands/quick.md',
  'template/.omp/commands/standard.md','template/.omp/commands/orchestrated.md',
  'template/.omp/agents/tech-lead.md','template/.omp/skills/task-triage/SKILL.md',
  'README.md','docs/architecture.md','docs/workflow-v0.md','CHANGELOG.md',
  'scripts/validate-template.ps1'
)
$targets | ForEach-Object {
  if (Test-Path -LiteralPath $_ -PathType Leaf) {
    Get-FileHash -Algorithm SHA256 -LiteralPath $_ |
      Select-Object @{n='Path';e={$_.Path}},Hash
  }
}
```

Expected: the command records current status and hashes without changing the workspace. Any
pre-existing change in a named target must be inspected and preserved during patching.

- [ ] **Step 2: Reconfirm the runtime facts used by the design**

Run:

```powershell
git -C _research/upstreams/oh-my-pi rev-parse HEAD
rg -n "text\.startsWith\(\"/\"\)|expandSlashCommand" `
  _research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/slash-commands.ts `
  _research/upstreams/oh-my-pi/packages/coding-agent/src/session/agent-session.ts
rg -n "Generate a handoff document|Start a new session|appendCustomMessageEntry\(\"handoff\"" `
  _research/upstreams/oh-my-pi/packages/coding-agent/src/session/session-handoff.ts
```

Expected: pinned commit
`3a8591a8af5b6d200088d12ca75a5517cb064fa8`; file slash-command expansion is gated by a
leading `/`; handoff generates text, creates a new session, and injects that text into it.

- [ ] **Step 3: Write and run the validator self-test before the helper exists**

Create `scripts/tests/topic02-workflow-lifecycle.Tests.ps1`. It must build a disposable fixture
repository beneath the OS temp directory, populate every path consumed by the validator, and
exercise the real public functions without mocks. Assert these hand-derived outcomes:

- missing helper/function exits 1 with `[T02-TEST-HELPER]`;
- a complete compliant fixture returns zero FAIL results;
- replacing Quick content with `restart as Standard` returns `T02-QUICK-BAN-1`;
- deleting the canonical candidate-lineage semantic returns its `T02-CANONICAL-REQ-*` code;
- deleting a required fixture file returns the corresponding `*-MISSING` code.

The script must validate that its cleanup target is a child of `[IO.Path]::GetTempPath()` and
has the `omp-topic02-validator-` prefix before recursively removing it in `finally`.

Run:

```powershell
pwsh -NoProfile -File scripts/tests/topic02-workflow-lifecycle.Tests.ps1
```

Expected RED: exit 1 with `[T02-TEST-HELPER]` because the production helper has not been
created. This is the intentional missing-behavior failure, not a syntax or fixture error.

- [ ] **Step 4: Create the focused validator helper**

Create `scripts/lib/topic02-workflow-lifecycle.ps1` with PowerShell 5.1-compatible functions.
Use this exact public shape and semantic anchors:

```powershell
#Requires -Version 5.1
Set-StrictMode -Version Latest

function New-Topic02ValidationResult {
    param(
        [ValidateSet('PASS','FAIL','WARN')][string]$Status,
        [string]$Code,
        [string]$Message
    )
    [pscustomobject]@{ Status = $Status; Code = $Code; Message = $Message }
}

function Test-Topic02FileContract {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$CodePrefix,
        [string[]]$Required = @(),
        [string[]]$Forbidden = @()
    )

    $path = Join-Path $RepositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return (New-Topic02ValidationResult -Status 'FAIL' -Code "$CodePrefix-MISSING" -Message "missing: $RelativePath")
    }

    $content = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    $results = @()
    for ($i = 0; $i -lt $Required.Count; $i++) {
        $needle = $Required[$i]
        if ($content.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $results += New-Topic02ValidationResult -Status 'PASS' -Code "$CodePrefix-REQ-$($i + 1)" -Message "required semantic present in $RelativePath"
        } else {
            $results += New-Topic02ValidationResult -Status 'FAIL' -Code "$CodePrefix-REQ-$($i + 1)" -Message "missing required semantic in ${RelativePath}: $needle"
        }
    }
    for ($i = 0; $i -lt $Forbidden.Count; $i++) {
        $needle = $Forbidden[$i]
        if ($content.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $results += New-Topic02ValidationResult -Status 'FAIL' -Code "$CodePrefix-BAN-$($i + 1)" -Message "superseded semantic remains in ${RelativePath}: $needle"
        } else {
            $results += New-Topic02ValidationResult -Status 'PASS' -Code "$CodePrefix-BAN-$($i + 1)" -Message "superseded semantic absent from $RelativePath"
        }
    }
    return $results
}

function Test-Topic02CanonicalContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    Test-Topic02FileContract -RepositoryRoot $RepositoryRoot `
      -RelativePath 'spec/04-workflow-sizing.md' -CodePrefix 'T02-CANONICAL' `
      -Required @(
        'Plain natural-language requests are the normal default entry.',
        'explicit Quick choice',
        'compatibility hints',
        'A task begins when its contract is accepted.',
        'one task and one active candidate lineage',
        'acceptance-bearing mutation invalidates',
        'at least two independently verifiable work units',
        'Parallel writers are optional',
        'Compaction does not change',
        'Handoff creates a successor session'
      ) -Forbidden @(
        'The user picks the size',
        'restart as Standard',
        'restart as Orchestrated',
        'discards its partial work',
        'De-escalation is not permitted'
      )
}

function Test-Topic02TemplateContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    $results = @()
    $results += Test-Topic02FileContract $RepositoryRoot 'template/.omp/AGENTS.md' 'T02-AGENTS' `
      @('Plain requests enter the main-session Tech Lead',
        'The user explicitly chooses Quick',
        'Standard and Orchestrated are selected') `
      @('The user selects a workflow command','restarts at a larger size')
    $results += Test-Topic02FileContract $RepositoryRoot 'template/.omp/commands/quick.md' 'T02-QUICK' `
      @('internal workflow reclassification','Preserve valid discovery and workspace changes') `
      @('restart as Standard','Do not continue a partially executed Quick flow')
    $results += Test-Topic02FileContract $RepositoryRoot 'template/.omp/commands/standard.md' 'T02-STANDARD' `
      @('one integrated implementation lane','Specialists are optional') `
      @('restart as Orchestrated','Explorer | Yes','Implementer | Yes','Verifier | Yes')
    $results += Test-Topic02FileContract $RepositoryRoot 'template/.omp/commands/orchestrated.md' 'T02-ORCHESTRATED' `
      @('at least two independently verifiable work units',
        'Parallel execution and parallel writers are optional') `
      @('must not de-escalate','Multiple Explorers | Yes','Multiple Implementers | Yes')
    $results += Test-Topic02FileContract $RepositoryRoot 'template/.omp/skills/task-triage/SKILL.md' 'T02-TRIAGE' `
      @('Ask one decision question at a time',
        'Quick is available only when the user explicitly selected') `
      @('Group all questions in one message','If in doubt between two sizes, select the larger one')
    return $results
}

function Test-Topic02ProjectionContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    $results = @()
    $results += Test-Topic02FileContract $RepositoryRoot 'README.md' 'T02-README' `
      @('No workflow prefix is required','Tech Lead chooses Standard or Orchestrated') `
      @('/quick task-triage','Complex, multi-file, needs full review')
    $results += Test-Topic02FileContract $RepositoryRoot 'docs/architecture.md' 'T02-ARCH' `
      @('candidate snapshot','successor session','integration contract') `
      @('Orchestrated → cross-module, high risk, architecture change')
    $results += Test-Topic02FileContract $RepositoryRoot 'spec/README.md' 'T02-SPEC-README' `
      @('plain request','compatibility hints','Topic 03 owns') `
      @('task: explorer → implementer → verifier')
    return $results
}

function Test-Topic02WorkflowLifecycleContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
    @(
        Test-Topic02CanonicalContract -RepositoryRoot $RepositoryRoot
        Test-Topic02TemplateContract -RepositoryRoot $RepositoryRoot
        Test-Topic02ProjectionContract -RepositoryRoot $RepositoryRoot
    )
}
```

PowerShell permits positional arguments used above because the helper's parameters are ordered.
If implementation chooses named arguments throughout for readability, preserve the same public
function names, required strings, forbidden strings, and result shape.

- [ ] **Step 5: Run the self-test GREEN, then add the focused validator entry point**

First run:

```powershell
pwsh -NoProfile -File scripts/tests/topic02-workflow-lifecycle.Tests.ps1
```

Expected GREEN: every compliant and mutated fixture assertion passes and the script exits 0.
Only after this result, create `scripts/validate-topic02-workflow-lifecycle.ps1`. It dot-sources
the helper, prints every result, reports totals, and exits 1 when any result is `FAIL`; otherwise
it exits 0. Use this structure:

```powershell
$helper = Join-Path $PSScriptRoot 'lib\topic02-workflow-lifecycle.ps1'
if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
    Write-Host 'FAIL [T02-HELPER-MISSING] focused Topic 02 validator helper is missing'
    exit 1
}
. $helper
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$results = @(Test-Topic02WorkflowLifecycleContract -RepositoryRoot $repositoryRoot)
$results | ForEach-Object { Write-Host ("{0} [{1}] {2}" -f $_.Status,$_.Code,$_.Message) }
$failed = @($results | Where-Object Status -eq 'FAIL').Count
Write-Host ("Topic 02 lifecycle: {0} passed, {1} failed" -f (@($results | Where-Object Status -eq 'PASS').Count),$failed)
if ($failed -gt 0) { exit 1 }
exit 0
```

- [ ] **Step 6: Run the focused validator RED and keep the Phase 00 validator unchanged**

Run:

```powershell
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
```

Expected: the focused validator exits 1 with Topic 02 failures naming missing approved semantics
and stale phrases. The existing validator remains byte-identical to its Task 1 baseline hash and
exits 0 with its existing warning only. Do not update Phase 00 evidence or weaken a Topic 02
assertion merely to make old content pass.

---

### Task 2: Replace the workflow-sizing authority and record KD-026

**Files:**
- Rewrite: `spec/04-workflow-sizing.md:1-end`
- Modify: `spec/key/04-decision-log.md:end, before Open questions`
- Test: `Test-Topic02CanonicalContract`

**Interfaces:**
- Consumes: the approved design and the pinned OMP facts reconfirmed in Task 1.
- Produces: the canonical entry/classification/lifecycle vocabulary and immutable decision
  `KD-026`, used by every later task in this plan.

- [ ] **Step 1: Record the superseded authority text before rewriting**

Run:

```powershell
rg -n "user chooses|user picks|restart|discards its partial|De-escalation|Worker agents|Implement in parallel" `
  spec/04-workflow-sizing.md spec/key/01-dna.md spec/key/04-decision-log.md
```

Expected: the old user-selects-all, restart/discard, one-way-only, fixed-worker prose is visible
and can be named explicitly in KD-026.

- [ ] **Step 2: Rewrite `spec/04-workflow-sizing.md` as the canonical contract**

Use these sections and no topology-specific mandatory dispatch graph:

```text
A. Authority, scope, and runtime facts
B. Vocabulary: phase, contract/task, candidate, session, work unit
C. Workflow entry: no prefix, /quick, compatibility commands, missing-slash hints
D. Classification: Quick, Standard, Orchestrated structural test
E. Lifecycle states and candidate evidence binding
F. Internal reclassification and escalation
G. Session operations: continue, new, compaction, handoff, fork, resume
H. Topology-neutral execution and Cheap Scout fallback
I. Failure/recovery rules
J. Static and behavioral verification matrix
K. Deferred ownership: Topic 03, Topic 04, Topic 08
```

Include this normative entry table:

```markdown
| User input | Runtime interpretation | Decision owner |
|---|---|---|
| Plain natural-language request | Normal entry; no command expansion required | Tech Lead chooses Standard or Orchestrated |
| `/quick ...` | Explicit Quick request; preflight may reclassify | User initiates, Tech Lead validates |
| `/standard ...` or `/orchestrated ...` | Compatibility/advanced routing hint | Tech Lead validates before mutation |
| `quick`, `standard`, or `orchestrated` without `/` | Natural-language hint, not a runtime slash command | Tech Lead interprets in context |
```

Include this conceptual lifecycle and evidence rule:

```text
Clarifying (outside the task cycle)
  -> Active
  -> Candidate frozen
  -> Verifying
  -> Accepted

Verification failure -> Active/Rework -> next frozen candidate
Other task terminals -> Cancelled | Terminally blocked
```

State verbatim or equivalently that a task begins when its contract is accepted, a session
serves one task and one active candidate lineage, and any acceptance-bearing mutation after
freeze invalidates evidence for that snapshot.

Define Orchestrated with all four approved conditions: at least two independently verifiable
work units; explicit inputs/outputs/ownership/dependencies/completion; one integration contract;
and cross-boundary verification. State that parallel writers are optional and that size, file
count, risk, agent count, and read-only fan-out are not decisive.

Ground slash-command and handoff claims in pinned OMP source paths and lines from Task 1. State
that OMP conversation/session/handoff text is a context carrier rather than durable project
task authority.

- [ ] **Step 3: Append KD-026 without rewriting prior decisions**

Add `KD-026 — Workflow entry and lifecycle are contract-first and Tech-Lead-routed` before the
decision log's open-question section. It must contain:

- **Decision:** the approved no-prefix, `/quick`, compatibility-hint, task/candidate/session,
  escalation, Orchestrated, and session-operation rules;
- **Grounds:** current-session user authority plus pinned OMP command/handoff mechanics;
- **Because:** no-prefix routing matches runtime reality, prevents user burden, preserves work,
  and binds verification to an immutable candidate;
- **Supersedes:** the unnumbered user-selects-all choice in old `spec/04`, `01-dna.md §L1`,
  restart/discard prose, de-escalation prohibition, and size/risk/fixed-agent definitions of
  Orchestrated;
- **Rejected:** remove compatibility commands now, keep all three user-selected, or implement a
  durable state engine inside Topic 02;
- **Reverse if:** a later explicit user decision or a verified runtime entry mechanism changes
  the contract without weakening evidence binding;
- **Touches:** every file in this plan and the Topic 03/04/08 ownership boundary;
- **No claim:** no durable state store, runtime session validator, or final agent topology is
  implemented here.

- [ ] **Step 4: Run the canonical contract check**

Run:

```powershell
. ./scripts/lib/topic02-workflow-lifecycle.ps1
$results = @(Test-Topic02CanonicalContract -RepositoryRoot (Get-Location).Path)
$results | Format-Table Status,Code,Message -AutoSize
if (@($results | Where-Object Status -eq 'FAIL').Count -gt 0) { exit 1 }
rg -n "KD-026|Plain natural-language|candidate lineage|Parallel writers are optional|Handoff creates" `
  spec/04-workflow-sizing.md spec/key/04-decision-log.md
```

Expected: exit 0; every canonical required marker is present; every forbidden semantic is
absent; `KD-026` appears once.

---

### Task 3: Make installable entry adapters lifecycle-correct and topology-neutral

**Files:**
- Modify: `template/.omp/AGENTS.md:Workflow Architecture and role summary`
- Rewrite: `template/.omp/commands/quick.md`
- Rewrite: `template/.omp/commands/standard.md`
- Rewrite: `template/.omp/commands/orchestrated.md`
- Modify: `template/.omp/agents/tech-lead.md:description and operating contract`
- Modify: `template/.omp/skills/task-triage/SKILL.md:Clarify, Select, Confirm sections`
- Test: `Test-Topic02TemplateContract`

**Interfaces:**
- Consumes: `spec/04-workflow-sizing.md` and KD-026 from Task 2.
- Produces: installed prompt surfaces that route into one lifecycle without imposing Topic 03's
  still-undecided worker graph.

- [ ] **Step 1: Replace the main-session workflow overview in `AGENTS.md`**

Keep the coding constitution unchanged. Replace only the workflow section with concise prose
that includes these exact meanings:

```markdown
- Plain requests enter the main-session Tech Lead; no workflow prefix is required.
- The user explicitly chooses Quick with `/quick`; the Tech Lead validates and may reclassify it.
- Standard and Orchestrated are selected by the Tech Lead. Their commands remain compatibility hints.
- Standard is one integrated implementation lane. Orchestrated requires multiple independently verifiable work units plus explicit integration.
- A workflow change is internal reclassification. Preserve valid evidence and workspace changes; never restart by emitting another slash command.
```

Add one short lifecycle paragraph: lock the task contract before the cycle; freeze a candidate
before verification; invalidate evidence after mutation; do not mix tasks or competing
candidate alternatives in one session. Keep the file within its existing 600–1,200 advisory
token target if possible and below the 1,500 hard warning.

- [ ] **Step 2: Rewrite `quick.md` as explicit-user entry plus safe reclassification**

Retain its compact inspect/implement/verify/report shape, but change its boundaries to:

- `/quick` is explicit user intent, not an irreversible classification;
- preflight checks a clear bounded contract before mutation;
- mismatch triggers internal workflow reclassification, not `restart as Standard`;
- valid discovery and workspace changes are preserved;
- reclassification alone creates neither a task nor a candidate;
- material contract change requires a linked task;
- implementation remains inline by default, while optional read-only Cheap Scout retrieval does
  not change Quick by itself;
- candidate freeze precedes verification, and post-freeze mutation invalidates evidence.

Use the literal phrases required by `T02-QUICK` and remove both forbidden phrases.

- [ ] **Step 3: Rewrite `standard.md` around one integrated lane**

Replace mandatory Explorer/Implementer/Verifier dispatch with this topology-neutral sequence:

```text
validate or clarify contract
  -> bounded discovery
  -> plan one integrated implementation lane
  -> implement under the active Topic 03 ownership policy
  -> freeze candidate
  -> verify against the frozen snapshot
  -> risk-gated independent review when required
  -> accept, rework, cancel, or close terminally blocked
```

State `Specialists are optional`: Scout, reviewer, or verifier may be used when they produce a
clear quality benefit, but a stage name never forces a spawn. If discovery proves the
Orchestrated structural test, reclassify internally, preserve work, define the work-unit and
integration contracts, and continue. Remove the fixed required-agent table.

- [ ] **Step 4: Rewrite `orchestrated.md` around the integration graph**

Require every work unit to record:

```yaml
work_unit:
  objective: string
  inputs: [reference]
  outputs: [verifiable artifact]
  ownership: bounded scope
  dependencies: [work_unit_id]
  completion_conditions: [criterion]
integration:
  contract: task-level behavior
  cross_boundary_checks: [verification]
```

Make sequential execution valid. State verbatim that parallel execution and parallel writers
are optional. Parallel read-only retrieval is an optimization, not the workflow definition.
When a later Topic 03 policy chooses parallel writers, keep the existing `spec/08` isolation,
capture, guarded-dispatch, deterministic-integration, and conflict-stop gates as mandatory
conditional safety rules; do not imply that those gates force parallelism.

Only the fully integrated frozen task candidate may enter acceptance verification. A work unit
or isolated worker must not accept the parent task.

- [ ] **Step 5: Align the legacy Tech Lead agent surface without claiming it is the entry**

Change `template/.omp/agents/tech-lead.md` so it states that the main session owns Tech Lead
authority and this file is a temporary/legacy role surface pending Topic 03 disposition. Remove
“Use for all tasks as the primary entry point” and any mandatory worker sequence. Mirror the
contract lock, internal reclassification, candidate freeze, session-boundary, and final
acceptance rules. Do not move or delete the file in Topic 02; Phase 01/Topic 03 owns its
discovery disposition.

- [ ] **Step 6: Apply only the minimal Topic 02 correction to task triage**

Keep detailed triage redesign deferred to Topic 08. Change current behavior so it:

- asks one decision question at a time when evidence cannot resolve ambiguity;
- does not group all questions;
- treats clarification before contract acceptance as outside the task cycle;
- validates Quick only when the user explicitly selected it;
- selects between Standard and Orchestrated using independently verifiable work units plus an
  integration boundary, not file count or risk alone;
- uses bounded Standard-style discovery when that boundary is uncertain;
- outputs a routing recommendation to the Tech Lead, not a runtime command to reinvoke.

- [ ] **Step 7: Run focused template and budget validation**

Run:

```powershell
. ./scripts/lib/topic02-workflow-lifecycle.ps1
$results = @(Test-Topic02TemplateContract -RepositoryRoot (Get-Location).Path)
$results | Format-Table Status,Code,Message -AutoSize
if (@($results | Where-Object Status -eq 'FAIL').Count -gt 0) { exit 1 }
pwsh -NoProfile -File scripts/validate-template.ps1 -Verbose
```

Expected: the focused template contract is green. The full validator may still be red only on
human/spec projections reserved for Tasks 4–5. Existing token-budget warnings must not become
new hard failures.

---

### Task 4: Reconcile lifecycle semantics across DNA, context, evaluation, and topology scopes

**Files:**
- Modify: `spec/key/01-dna.md:L1 and L8`
- Modify: `spec/key/03-token-quality-model.md:A-1 and A-2`
- Modify: `spec/05-context-and-token-model.md:G-H`
- Modify: `spec/13-validation-and-evaluation.md:C-1, C-2, F`
- Modify: `spec/03-agent-topology.md:top authority notice`
- Modify: `spec/08-isolation-and-concurrency.md:top scope notice and conditional wording`
- Test: cross-spec lifecycle and contradiction scans

**Interfaces:**
- Consumes: the canonical meanings from Task 2.
- Produces: one consistent distinction among lifecycle state, evaluation classification,
  candidate evidence, and conditional execution topology.

- [ ] **Step 1: Replace the stale DNA entry gene**

Rewrite `spec/key/01-dna.md §L1` so it projects no-prefix entry, explicit `/quick`, Tech Lead
selection of Standard/Orchestrated, compatibility hints, internal reclassification, and the
Orchestrated integration-graph test. Remove user-picks-all, fixed subagent counts,
restart/discard, and forbidden-de-escalation claims.

In §L8 add only the lifecycle boundary: compaction preserves session/task/candidate/work-unit
identity; it does not perform handoff or create durable state. Keep all existing source-backed
compaction mechanics and token analysis unchanged.

- [ ] **Step 2: Separate task terminal state from evaluation classification**

Update `spec/key/03-token-quality-model.md §A-1/A-2` and
`spec/13-validation-and-evaluation.md §C-1/C-2` to use this two-axis contract:

```yaml
lifecycle:
  task_terminal_state: accepted | cancelled | terminally_blocked
evaluation:
  acceptance_classification: validated_accepted | accepted_with_waiver | non_accepted
```

State explicitly:

- `clarifying`, `active`, `candidate_frozen`, `verifying`, `rework`, `waiting_for_user`,
  `partial`, and a recoverable `blocked` condition are nonterminal progress/disposition labels;
- only the three lifecycle terminal states end the task cycle;
- `validated_accepted` requires `task_terminal_state: accepted` and all five Topic 01 evidence
  conditions;
- `accepted_with_waiver` remains an evaluation/reporting classification excluded from the
  validated denominator and promotion;
- waiving a mandatory criterion is a material contract change: close the original boundary
  honestly and open a linked contract rather than relabeling the old candidate as validated;
- failed/rejected candidate snapshots remain charged to the original task cycle;
- a genuinely new objective, mandatory criterion, authority, or material scope starts a new
  task cycle.

Do not change Topic 01's metric priority, ledgers, baselines, thresholds, or sequential-validity
contract.

- [ ] **Step 3: Bind evaluation evidence to the candidate snapshot without preempting Topic 04**

In `spec/13 §C`, require every acceptance-bearing verification/review record to identify the
exact frozen candidate snapshot. State that Topic 04 owns the durable identifier and schema.
Until Topic 04 implements that identity, the evaluation harness cannot claim lifecycle-aware
acceptance from conversational labels alone. Add acceptance criteria that:

- mutation after freeze invalidates prior evidence;
- a later candidate cannot inherit C1 evidence;
- work-unit evidence is insufficient until the integrated task candidate passes cross-boundary
  checks;
- task-cycle accounting continues across C1, C2, and subsequent snapshots of the same contract.

Do not invent a persistent project-state file or final ID format in Topic 02.

- [ ] **Step 4: Add the session/compaction projection to `spec/05`**

Preserve the existing context budgets and native compaction settings. Add concise rules that:

- `.task/` is scratch/context offload and not lifecycle authority;
- compaction is within the same session and one long work unit;
- handoff starts a successor session for the same task/candidate lineage;
- generated handoff text must be reconciled with the contract and workspace;
- new task/new contract means a new session;
- resume is allowed only after contract/candidate/workspace reconciliation.

- [ ] **Step 5: Mark topology and isolation mechanisms as conditional pending Topic 03**

At the top of `spec/03-agent-topology.md`, add a narrow supersession notice: KD-026 governs
entry and forbids any workflow stage from forcing a spawn by itself; Topic 03 must re-evaluate
the remaining topology before it is treated as final.

At the top of `spec/08-isolation-and-concurrency.md`, state that its parallel-writer safety
mechanics are conditional: if parallel writers are selected later, every isolation/capture/
guarded-dispatch/integration gate remains mandatory; those mechanics do not define
Orchestrated or require parallelism.

Do not rewrite the source-backed isolation analysis in Topic 02.

- [ ] **Step 6: Run cross-spec consistency checks**

Run:

```powershell
rg -n -i "user picks the size|user chooses.*standard|restart as standard|restart as orchestrated|discards its partial|de-escalation is (not permitted|forbidden)" `
  spec/04-workflow-sizing.md spec/key/01-dna.md spec/key/03-token-quality-model.md `
  spec/05-context-and-token-model.md spec/13-validation-and-evaluation.md
rg -n "task_terminal_state|acceptance_classification|candidate snapshot|successor session|Topic 04 owns" `
  spec/04-workflow-sizing.md spec/key/03-token-quality-model.md `
  spec/05-context-and-token-model.md spec/13-validation-and-evaluation.md
```

Expected: the stale scan returns no matches; the required scan shows consistent lifecycle and
evidence semantics. `accepted_with_waiver` remains present only as a non-promoting evaluation
classification.

---

### Task 5: Remap phase work and synchronize concise documentation

**Files:**
- Modify: `spec/phases/phase-02-core-orchestration.md:Objective, tasks, deliverables, verification, exit criteria, risks`
- Modify: `spec/phases/phase-03-context-efficiency.md:T-03.1, verification, exit criteria`
- Modify: `spec/phases/phase-06-evaluation.md:task-cycle instrumentation and acceptance`
- Modify: `spec/README.md:architecture principles, topology diagram, PR-3 context`
- Modify: `README.md:What it does and Choosing a command`
- Modify: `docs/architecture.md:component descriptions, workflow selection, context flow`
- Modify: `docs/workflow-v0.md:status, architecture decisions, known limitations`
- Test: `Test-Topic02ProjectionContract` and phase acceptance scan

**Interfaces:**
- Consumes: Tasks 2–4.
- Produces: an implementation roadmap and user documentation that do not reintroduce old
  routing or topology semantics.

- [ ] **Step 1: Rebase Phase 02 on lifecycle correctness**

Keep the Phase 02 dependency edges unchanged. Change the objective from “three commands with
real agent dispatch” to “all supported entries produce one correctly classified task/candidate
cycle, with optional dispatch governed by Topic 03.”

Add `T-02.0 — Project the workflow entry and lifecycle contract` with acceptance for:

- plain no-prefix entry;
- explicit `/quick`;
- compatibility `/standard` and `/orchestrated` hints;
- missing-slash natural-language hints;
- internal reclassification without reset/discard;
- task/candidate/session boundaries;
- structural Orchestrated classification.

Update existing tasks as follows:

- T-02.1 through T-02.3b and T-02.8 become conditional execution-mechanism work used only when
  Topic 03 selects the relevant worker or parallel-writer path;
- T-02.4 validates every dispatch that actually occurs but does not require a dispatch merely
  because a workflow stage exists;
- T-02.5 makes Quick an inline-writing path by default while permitting optional read-only
  Cheap Scout retrieval;
- T-02.6 becomes the candidate-freeze/rework loop: FAIL returns to Active/Rework, mutation
  invalidates evidence, and the next frozen snapshot is C2 or later;
- add `T-02.9 — Enforce session-operation semantics` for new, compaction, handoff, fork, and
  resume behavior.

Split exit criteria into unconditional lifecycle criteria and conditional worker/parallel
criteria. A sequential Orchestrated task must not fail merely because no parallel writer path
was used. Retain all CR-29/31/32/38/39/45 safety requirements when that conditional path is
actually selected.

- [ ] **Step 2: Add lifecycle-safe compaction acceptance to Phase 03**

In T-03.1 and its verification/exit criteria, require that compaction preserves the same
session, task, candidate lineage, work-unit ownership, and state. State that compaction cannot
replace handoff or durable Topic 04 state. Do not change compaction strategy settings or phase
dependencies.

- [ ] **Step 3: Add candidate-bound evidence acceptance to Phase 06**

Update Phase 06 task-cycle instrumentation and verification so the future harness consumes the
Topic 04 candidate identity, rejects evidence from a mutated snapshot, accounts for every
candidate in the same task cycle, and distinguishes lifecycle terminal state from evaluation
classification. Do not implement the harness or alter Topic 01 promotion thresholds.

- [ ] **Step 4: Replace user-facing command-selection instructions**

In `README.md`, replace the command-choice table and `/quick task-triage` advice with:

```markdown
## Starting work

No workflow prefix is required. Describe the task normally and the main-session Tech Lead
chooses Standard or Orchestrated.

Use `/quick` when you intentionally want the light path for a small, clear task. The Tech Lead
still validates the boundary and may reclassify it safely.

`/standard` and `/orchestrated` remain compatibility hints for advanced use; the Tech Lead
validates them before changing the workspace.
```

Do not present size, multi-file scope, or risk alone as the Orchestrated selector.

- [ ] **Step 5: Synchronize architecture and implementation-record documentation**

Update `docs/architecture.md`, `docs/workflow-v0.md`, and `spec/README.md` so each shows:

```text
plain request -> main-session Tech Lead -> Standard or Orchestrated
/quick        -> Quick preflight -> Quick or internal reclassification
compatibility hints -> Tech Lead validation
```

Add the task/candidate/session boundary and describe Orchestrated as an integration contract
over independently verifiable work units. Replace fixed Explorer/Implementer/Verifier command
arrows with optional-role wording and state that Topic 03 owns the final topology. Preserve
historical counts only where explicitly labeled as the current scaffold inventory, never as a
mandatory workflow graph.

In `docs/workflow-v0.md`, change any “complete” statement that would falsely claim the new
lifecycle is runtime-enforced. Record Topic 04 durable state and lifecycle-aware resume checks
as not yet built.

- [ ] **Step 6: Run projection and phase checks**

Run:

```powershell
. ./scripts/lib/topic02-workflow-lifecycle.ps1
$results = @(Test-Topic02ProjectionContract -RepositoryRoot (Get-Location).Path)
$results | Format-Table Status,Code,Message -AutoSize
if (@($results | Where-Object Status -eq 'FAIL').Count -gt 0) { exit 1 }

rg -n "T-02.0|T-02.9|plain|candidate|conditional|Topic 03|Topic 04" `
  spec/phases/phase-02-core-orchestration.md `
  spec/phases/phase-03-context-efficiency.md `
  spec/phases/phase-06-evaluation.md
rg -n -i "Not sure\? Run /quick|Complex, multi-file, needs full review|Explorer → Implementer → Verifier|Multiple Explorers.*Yes|Multiple Implementers.*Yes" `
  README.md docs/architecture.md docs/workflow-v0.md spec/README.md
```

Expected: focused projection check exits 0; phase terms appear; stale human-facing routing and
mandatory topology phrases do not.

---

### Task 6: Run full static verification and prepare the change record

**Files:**
- Test: every file modified by Tasks 1–5
- Modify: `CHANGELOG.md:Unreleased/Changed`
- Create: `codex-topic02-workflow-entry-task-lifecycle-changelog.md`

**Interfaces:**
- Consumes: the complete Topic 02 patch.
- Produces: exact validation evidence and a detailed reviewer handoff ledger. It does not close
  Topic 02 before independent review.

- [ ] **Step 1: Run the focused lifecycle validator**

Run:

```powershell
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
```

Expected: exit 0 and no Topic 02 FAIL result.

- [ ] **Step 2: Run the active-surface contradiction scan**

Run:

```powershell
rg -n -i "the user selects a workflow command|the user picks the size|restart as standard|restart as orchestrated|discards its partial work|de-escalation is not permitted|must not de-escalate|group all questions in one message|if in doubt between two sizes, select the larger" `
  spec/04-workflow-sizing.md spec/key/01-dna.md spec/key/03-token-quality-model.md `
  spec/05-context-and-token-model.md spec/13-validation-and-evaluation.md `
  spec/README.md spec/phases/phase-02-core-orchestration.md `
  template/.omp/AGENTS.md template/.omp/commands template/.omp/agents/tech-lead.md `
  template/.omp/skills/task-triage/SKILL.md README.md docs/architecture.md docs/workflow-v0.md
```

Expected: no match. Historical design, research, evidence, and review artifacts are excluded
and remain unchanged.

- [ ] **Step 3: Run the required-semantics scan**

Run:

```powershell
rg -n -i "plain natural-language|no workflow prefix|/quick|compatibility hint|task contract|candidate snapshot|candidate lineage|terminally.blocked|successor session|independently verifiable work units|integration contract|parallel writers are optional|Cheap Scout" `
  spec/04-workflow-sizing.md spec/key/01-dna.md spec/key/03-token-quality-model.md `
  spec/05-context-and-token-model.md spec/13-validation-and-evaluation.md `
  template/.omp/AGENTS.md template/.omp/commands README.md docs/architecture.md spec/README.md
```

Expected: every approved concept has an authority occurrence and the appropriate concise
projection. No concise projection introduces a competing local definition.

- [ ] **Step 4: Run the full repository validator**

Run:

```powershell
pwsh -NoProfile -File scripts/validate-template.ps1 -Verbose
```

Expected: exit 0 with zero failures. Record the exact pass/warning/failure totals. The known
pre-existing advisory warning for `template/.omp/RULES.md` being below its target budget may
remain; do not describe it as introduced or resolved by Topic 02.

- [ ] **Step 5: Review whitespace, scope, and target diffs**

Run:

```powershell
git diff --check
git diff --stat
git diff -- spec/04-workflow-sizing.md spec/key/01-dna.md `
  spec/key/03-token-quality-model.md spec/key/04-decision-log.md `
  spec/03-agent-topology.md spec/05-context-and-token-model.md `
  spec/08-isolation-and-concurrency.md spec/13-validation-and-evaluation.md `
  spec/README.md spec/phases/phase-02-core-orchestration.md `
  spec/phases/phase-03-context-efficiency.md spec/phases/phase-06-evaluation.md `
  template/.omp/AGENTS.md template/.omp/commands/quick.md `
  template/.omp/commands/standard.md template/.omp/commands/orchestrated.md `
  template/.omp/agents/tech-lead.md template/.omp/skills/task-triage/SKILL.md `
  README.md docs/architecture.md docs/workflow-v0.md `
  scripts/validate-topic02-workflow-lifecycle.ps1 `
  scripts/tests/topic02-workflow-lifecycle.Tests.ps1 `
  scripts/lib/topic02-workflow-lifecycle.ps1 CHANGELOG.md
```

Expected: no whitespace error, no unrelated rewrite, and every changed hunk traces to the
approved impact map. Reconcile against the Task 1 hashes/status so pre-existing target edits are
not attributed to Topic 02.

- [ ] **Step 6: Update the short changelog entry**

Under `CHANGELOG.md` Unreleased/Changed, record that Topic 02 adds no-prefix entry,
user-selected Quick, Tech-Lead-selected Standard/Orchestrated, internal safe reclassification,
candidate-bound evidence, session-operation semantics, and structural Orchestrated
classification. Explicitly state that durable state and final topology remain Topic 04 and
Topic 03 work.

- [ ] **Step 7: Create the detailed Codex change ledger**

Create `codex-topic02-workflow-entry-task-lifecycle-changelog.md` containing:

- user-approved decisions and design-spec path;
- old versus new semantics;
- KD-026 and every superseded statement;
- files changed with before/after SHA-256 hashes;
- pinned OMP source evidence and exact commit;
- Topic 01 lifecycle/evaluation reconciliation;
- Topic 03/04/08 and phase impact;
- exact validation commands, exit codes, and key output;
- known limitation that static prompt validation is not runtime lifecycle enforcement;
- exclusions and non-claims;
- questions the independent reviewer must attack.

Do not claim Topic 02 is closed in this ledger.

---

### Task 7: Run the user-authorized Codex audit, adjudicate, and close Topic 02

**Files:**
- Create: `codex-peer-review-packet-topic02-round1.md`
- Create: `codex-peer-review-prompt-topic02-round1.md`
- Create: `codex-peer-review-response-topic02-round1.md`
- Create: `codex-topic02-closure-status.md`
- Modify if required: only files in the approved impact map plus fresh round-N audit artifacts

**Interfaces:**
- Consumes: the verified Topic 02 snapshot, hashes, design, decision record, source evidence,
  and detailed ledger from Task 6.
- Produces: an independent read-only Codex verdict, adjudicated findings, final validation
  evidence, and an honest closure record.

- [ ] **Step 1: Freeze the review packet and one-way hash chain**

Create a compact packet that identifies the exact files and SHA-256 hashes to review. Create a
prompt that hashes the packet and target files but does not embed its own hash recursively.
Include the pinned OMP commit and the exact source anchors for slash-command expansion and
handoff transition.

- [ ] **Step 2: Require an adversarial read-only review**

The prompt must instruct a fresh Codex `gpt-5.6-sol` high-reasoning reviewer in a disposable
exact copy to:

- independently verify every supplied hash;
- verify the copy uses the clean pinned OMP upstream source;
- audit source claims and runtime feasibility;
- search all active specs/template/docs for entry or lifecycle contradictions;
- test no-prefix and missing-slash semantics against actual slash expansion behavior;
- attack task/candidate/session boundaries and evidence invalidation;
- attack the `accepted_with_waiver` reconciliation for denominator or lifecycle loopholes;
- verify Orchestrated is structural and not secretly dependent on mandatory parallel writers;
- verify escalation preserves work without silently extending the contract;
- verify compaction/handoff/fork/resume do not become false state authority;
- verify Cheap Scout remains optional and fail-soft;
- verify Topic 03/04/08 boundaries and phase dependencies;
- return either `ACCEPT_TOPIC_02` or evidence-backed findings categorized as
  `contract-misread`, `actionable`, `trade-off`, or `noise`.

The reviewer is read-only. It must not edit the official workspace or the disposable copy.

- [ ] **Step 3: Preserve the response and adjudicate every finding**

Write the verbatim reviewer result to
`codex-peer-review-response-topic02-round1.md`. For each finding:

- reproduce the cited text/source;
- determine whether it violates the approved contract;
- reject contract misreads and noise with evidence;
- present unresolved trade-offs to the user rather than choosing silently;
- patch actionable defects only within the approved impact map;
- if patched, invalidate the old review snapshot, rerun Tasks 6.1–6.5, and create a new
  round-numbered packet/prompt/response rather than overwriting Round 1.

- [ ] **Step 4: Run final verification on the accepted snapshot**

Run:

```powershell
pwsh -NoProfile -File scripts/validate-template.ps1 -Verbose
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
git diff --check
git status --short
```

Expected: validator exit 0 with zero failures; no whitespace errors; dirty state contains only
pre-existing work plus named Topic 02 files and audit artifacts. Record exact results and final
hashes.

- [ ] **Step 5: Create the closure record**

Create `codex-topic02-closure-status.md` with:

- `topic: 02`;
- `status: CLOSED` only if the final independent verdict is `ACCEPT_TOPIC_02` and all required
  validation is green;
- approved decision and KD-026 reference;
- final reviewed hashes;
- validation and review evidence;
- known limitations/non-claims;
- explicit handoff to Topic 03;
- repository state: uncommitted, unstaged, no branch/push/PR action.

If any actionable finding remains unresolved, set `status: OPEN` and state the exact blocker;
do not claim closure.

---

## Execution Notes

- Apply edits with `apply_patch`; use formatting tools only for mechanical formatting.
- Re-read each target immediately before patching because the workspace is dirty.
- Run focused checks after every task; do not wait until the final validator to discover drift.
- Static green proves prompt/spec consistency only. Runtime task-state enforcement remains
  explicitly deferred to Topic 04.
- Do not mark checkboxes complete until the corresponding command has run and its output has
  been read.
