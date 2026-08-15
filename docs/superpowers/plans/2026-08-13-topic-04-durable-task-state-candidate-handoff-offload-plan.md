# Topic 04 Durable Task State, Candidate Lifecycle, Handoff, and Offload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.
>
> **Execution selection:** Inline execution with checkpoints is recommended for this repository.
> The user does not prioritize subagent execution unless a spawn has a concrete benefit, and the
> tasks below have a strong sequential dependency through one state-core contract.

**Goal:** Build one local, deterministic authority for project/phase/task/candidate/session state
that survives compaction and handoff, binds evidence to exact candidate bytes, coordinates
multiple worktrees safely, and can be called by either Claude or Codex/OMP without storing
operational state in Git.

**Architecture:** A PowerShell 7.4+ state CLI owns all mutations beneath the resolved Git common
directory at agent-tasks, or beneath .agent-tasks for a non-Git project. Focused modules provide
strict JSON parsing/canonicalization, immutable revision publication, scoped Git manifests,
lifecycle transitions, evidence, handoff, and retention. OMP and Claude use the same explicit
CLI protocol in Topic 04; automatic hook attachment remains gated for Topic 08.

**Tech Stack:** PowerShell 7.4+ deterministic state core using System.Text.Json and .NET
filesystem primitives; PowerShell 5.1-compatible installer/static validators; Git porcelain v2
and plumbing commands; JSON Schema 2020-12; SHA-256; Markdown/YAML canonical specifications.

## Global Constraints

- Operational authority is local-only. Never place project/phase/task state inside the
  worktree or Git history for a Git project.
- The Git state root is exactly the absolute git rev-parse --git-common-dir result joined with
  agent-tasks. Never derive it from a linked-worktree .git file.
- The non-Git fallback is exactly <project-root>/.agent-tasks and permits only one active
  mutating task.
- If Git is initialized later, freeze the fallback root until explicit validated migration.
  Never operate two roots as independent authorities.
- Operational records are closed JSON documents. No YAML parser or runtime database is added.
- Hashable JSON uses the versioned RFC 8785 profile. V1 rejects fractional numbers and integers
  outside the JavaScript safe-integer range so PowerShell editions cannot serialize the same
  authority differently.
- All published state revisions and supporting records are immutable. An unreferenced
  supporting record is an inert orphan, not a lifecycle transition.
- Every post-bootstrap mutation uses expected revision, expected revision SHA-256, expected
  lease generation where applicable, and session authority.
- One session owns task authority and the authoritative integration worktree at a time.
  Delegated Workers may only produce provisional changes in subordinate isolated worktrees.
- Every active mutating task has a distinct authoritative worktree. Cross-task worktree and
  write-scope reservations are serialized under the repository coordination lock.
- Writer leases have no heartbeat TTL. Takeover and stale-lock recovery require explicit user
  authorization.
- A candidate is a scoped identity manifest, not a backup. Git remains responsible for source
  restoration and history.
- Candidate output discovery compares the current repository with the captured baseline and
  refuses unexplained changes. Declared ignored outputs are hashed explicitly.
- Evidence is immutable, typed, candidate/contract-bound, and validity-triggered. No global TTL
  applies.
- Verification/review evidence becomes stale after candidate or declared-input drift.
- Handoff is a two-phase structured ownership transfer. Handoff prose and compaction summaries
  are never authority.
- Raw output remains transient. Only compact, sanitized, acceptance-relevant artifacts are
  promoted into the task bundle.
- State never contains secrets, raw .env data, full transcripts, terminal histories, hidden
  reasoning, or unbounded provider output.
- The state tool never executes commands read from state or evidence.
- Cleanup is dry-run by default. Apply moves an exact terminal task into recoverable trash;
  permanent purge is separate and never deletes a Git worktree.
- PowerShell 7.4+ is required only for the installed state component. Installer and static
  validation scripts remain parseable and runnable under Windows PowerShell 5.1.
- Preserve all pre-existing dirty-worktree changes. Do not reset, revert, or overwrite
  unrelated work.
- Topic 04 depends on the uncommitted Topic 02/03 authority currently present in this
  worktree. Do not create a linked worktree from stale HEAD unless the user first authorizes a
  safe transfer of that dependency state; with one active mutating task, this worktree remains
  the authoritative integration worktree.
- Do not stage, commit, push, or create a PR without a new explicit user instruction. Task
  checkpoints use path-scoped status, hashes, and fresh test output instead.
- Do not spawn a subagent merely because this plan contains multiple tasks.

---

## File Structure and Ownership

### Installed deterministic core

- Create: template/.omp/state/agent-tasks.ps1 — one CLI entry point.
- Create: template/.omp/state/lib/AgentTasks.Common.ps1 — strict JSON, canonical JSON, hashing,
  result envelopes, path confinement, and secret scanning.
- Create: template/.omp/state/lib/AgentTasks.Store.ps1 — authority roots, publication, revision
  chains, and lock domains.
- Create: template/.omp/state/lib/AgentTasks.Git.ps1 — worktree identity, baselines, scopes, and
  nested-repository checks.
- Create: template/.omp/state/lib/AgentTasks.Lifecycle.ps1 — project/phase/task/session/work-unit
  transitions, leases, reservations, and checkpoints.
- Create: template/.omp/state/lib/AgentTasks.Candidate.ps1 — freeze, manifest, drift, lineage.
- Create: template/.omp/state/lib/AgentTasks.Evidence.ps1 — typed evidence, artifacts, acceptance.
- Create: template/.omp/state/lib/AgentTasks.Transfer.ps1 — handoff, takeover, lock recovery.
- Create: template/.omp/state/lib/AgentTasks.Retention.ps1 — archive, restore, purge, migration.
- Create: template/.omp/state/schemas/agent-tasks-v1.schema.json — closed JSON Schema bundle.
- Create: template/.omp/state/PROTOCOL.md — compact black-box CLI documentation.

### Tests and focused validation

- Create: scripts/lib/topic04-test-fixtures.ps1
- Create: scripts/tests/topic04-state-foundation.Tests.ps1
- Create: scripts/tests/topic04-state-lifecycle.Tests.ps1
- Create: scripts/tests/topic04-state-candidate.Tests.ps1
- Create: scripts/tests/topic04-state-evidence.Tests.ps1
- Create: scripts/tests/topic04-state-transfer.Tests.ps1
- Create: scripts/tests/topic04-state-retention.Tests.ps1
- Create: scripts/tests/topic04-installer.Tests.ps1
- Create: scripts/tests/topic04-durable-state.Tests.ps1
- Create: scripts/lib/topic04-durable-state.ps1
- Create: scripts/validate-topic04-durable-state.ps1
- Modify: scripts/validate-template.ps1
- Modify: scripts/install-template.ps1
- Modify: scripts/uninstall-template.ps1

### Runtime-consumer projection

- Modify: template/.omp/AGENTS.md
- Modify: template/.omp/commands/quick.md
- Modify: template/.omp/commands/standard.md
- Modify: template/.omp/commands/orchestrated.md
- Create: docs/task-state.md
- Create: docs/evidence/current-product/topic-04/adapter-gate.json

Topic 04 installs no automatic extension, hook, new workflow command, or new skill. The selected
v1 adapter is explicit invocation of the same state CLI. Topic 08 may add automatic adapters only
after an installed-runtime lifecycle probe.

### Canonical authority and projections

- Append: spec/key/04-decision-log.md as KD-028.
- Modify: spec/key/01-dna.md and spec/key/03-token-quality-model.md.
- Modify: spec/01-target-architecture.md, spec/02-runtime-semantics.md,
  spec/04-workflow-sizing.md, spec/05-context-and-token-model.md,
  spec/08-isolation-and-concurrency.md, spec/10-verification-and-review.md,
  spec/12-installation-and-rollback.md, spec/13-validation-and-evaluation.md,
  spec/14-upgradeability-and-governance.md, spec/15-security-and-failure-recovery.md,
  spec/16-migration-plan.md, and spec/README.md.
- Modify: spec/phases/phase-02-core-orchestration.md,
  spec/phases/phase-03-context-efficiency.md,
  spec/phases/phase-05-installation-hardening.md,
  spec/phases/phase-06-evaluation.md, and spec/phases/phase-07-stabilization.md.

### Human documentation and handoff

- Modify: README.md, CHANGELOG.md, docs/architecture.md, docs/installation.md,
  docs/workflow-v0.md, docs/security.md, and docs/rollback.md.
- Create: codex-topic04-durable-task-state-changelog.md.

---

## Closed CLI Protocol

Every invocation uses:

~~~powershell
pwsh -NoProfile -File .omp/state/agent-tasks.ps1 -RequestPath request.json
~~~

RequestPath may be exactly - to read UTF-8 JSON from stdin. The closed envelope is:

~~~json
{
  "schema_version": 1,
  "operation": "create-task",
  "working_directory": "D:/absolute/project/worktree",
  "session_ref": "codex:opaque-session-id",
  "runtime": "codex",
  "request": {}
}
~~~

Success emits one JSON document and exits 0:

~~~json
{
  "ok": true,
  "code": "AT-OK",
  "operation": "create-task",
  "data": {}
}
~~~

Failure emits one sanitized JSON document. Exit 2 means malformed/invalid request, 3 means a
state/ownership/conflict refusal, 4 means unavailable/corrupt environment, and 5 means an
unexpected internal fault. stderr is reserved for a single non-secret diagnostic line.

The v1 operation set is closed:

~~~text
init-project
create-phase
transition-phase
create-task
bind-worktree
claim
create-work-unit
record-work-unit-outcome
status
checkpoint
freeze
check
promote-artifact
record-evidence
begin-handoff
accept-handoff
takeover
close
invalidate
cleanup
restore
purge
recover-lock
migrate
~~~

The schema bundle fixes these request payloads:

| Operation | Required request fields |
|---|---|
| init-project | display_name |
| create-phase | phase_id, objective, authority, dependencies, exit_obligations |
| transition-phase | phase_id, target_status, expected revision/hash |
| create-task | objective, authority, acceptance_criteria, obligations, execution_mode, write_scope; optional phase_id and owned_ignored_outputs |
| bind-worktree | task_id, worktree_root, expected revision/hash/generation |
| claim | task_id, expected revision/hash/generation; envelope session_ref must equal owner |
| create-work-unit | task_id, work_unit_id, inputs, outputs, ownership, dependencies, completion_conditions |
| record-work-unit-outcome | task_id, work_unit_id, status, artifact_refs, observed_summary |
| status | optional task_id or phase_id; no mutation fields |
| checkpoint | task_id, kind, next_action, blockers, open_risks; optional work_unit_id |
| freeze | task_id, acceptance_inputs, scope_dispositions |
| check | task_id, candidate_id |
| promote-artifact | task_id, source_path, media_type, candidate_id or handoff_id |
| record-evidence | task_id, evidence_type, covered_ac_ids, observation, validity_triggers; optional candidate_id/artifact hash |
| begin-handoff | task_id, successor session/runtime, next_action, blockers, open_risks |
| accept-handoff | task_id, handoff_id, predecessor revision/hash |
| takeover | task_id, successor session/runtime, user_authorization, reconciliation |
| close | task_id, terminal_status; candidate_id required for accepted, reason required for cancelled/terminally_blocked |
| invalidate | task_id, target_type, target_id, reason; optional remediation_task_id |
| cleanup | task_id, mode exactly dry-run or apply |
| restore | task_id |
| purge | task_id, confirmation exactly equal to task_id |
| recover-lock | lock_domain, lock_id, user_authorization |
| migrate | migration_kind; roots are derived from working_directory, optional target_schema_version |

Every mutating request after bootstrap carries expected_revision, expected_revision_sha256,
expected_lease_generation when task-bound, and the owning session_ref in the envelope.

---

### Task 1: Build the strict JSON, authority-root, immutable-store, and CLI foundation

**Files:**
- Create: template/.omp/state/schemas/agent-tasks-v1.schema.json
- Create: template/.omp/state/lib/AgentTasks.Common.ps1
- Create: template/.omp/state/lib/AgentTasks.Store.ps1
- Create: template/.omp/state/agent-tasks.ps1
- Create: scripts/lib/topic04-test-fixtures.ps1
- Create: scripts/tests/topic04-state-foundation.Tests.ps1

**Interfaces:**
- Produces: Read-AgentTasksEnvelope -Path <string> -> validated object graph.
- Produces: ConvertTo-AgentTasksCanonicalJson -Value <object> -> canonical UTF-8 string.
- Produces: Get-AgentTasksSha256 -Value or -LiteralPath -> uppercase 64-hex digest.
- Produces: Resolve-AgentTasksContext -WorkingDirectory <path> -> ProjectRoot, WorktreeRoot,
  GitDir, GitCommonDir, StateRoot, IsGit.
- Produces: Invoke-WithAgentTasksLock -Domain repository|phase|task -Id <string>
  -Action <scriptblock>.
- Produces: Publish-AgentTasksRecord and Get-AgentTasksRevisionChain.

- [ ] **Step 1: Write the failing foundation tests**

Assert these exact cases:

~~~text
duplicate JSON key -> AT-JSON-DUPLICATE-KEY
unknown envelope property -> AT-SCHEMA-UNKNOWN-PROPERTY
depth > 32 or request > 1 MiB -> AT-JSON-LIMIT
fraction or unsafe integer -> AT-JSON-NUMBER
equivalent object insertion orders -> identical canonical SHA-256
main and linked worktree -> same StateRoot, distinct GitDir/WorktreeRoot
non-Git root -> .agent-tasks
R000001 publishes once and cannot be overwritten
R000002 names R000001 and its SHA-256
revision gap/malformed/hash break -> reconcile_required
orphan supporting record -> reported but never selected
two contenders -> only one lock owner
stale lock -> never expires by time
init-project -> identity plus R000001
status -> read-only and one JSON document
unknown operation -> exit 2 / AT-OPERATION-UNKNOWN
internal error -> sanitized, no stack or secret
~~~

The fixture helper creates only GUID directories beneath the OS temp root, checks the exact
prefix before cleanup, and initializes disposable Git repositories with local test identity.

- [ ] **Step 2: Run the test to verify RED**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
~~~

Expected: nonzero exit with AT-TEST-CORE-MISSING.

- [ ] **Step 3: Add the closed schema bundle**

Use JSON Schema 2020-12, additionalProperties false on every object, with defs for:

~~~text
operationEnvelope, resultEnvelope, projectIdentity, phaseContract, phaseStateRevision,
taskContract, taskStateRevision, sessionIdentity, checkpoint, workUnitContract,
workUnitOutcome, candidate, evidence, handoff, artifactMetadata, lockOwner
~~~

All timestamps are RFC 3339 UTC. Reject fields named command_to_run, transcript, reasoning,
api_key, token, secret, credential, env_contents, or terminal_history.

- [ ] **Step 4: Implement strict parsing, canonical JSON, hashes, and result envelopes**

AgentTasks.Common.ps1 requires PowerShell 7.4 and uses System.Text.Json JsonDocument. It walks
the parsed tree to reject duplicate/unknown fields before projecting values. Implement:

~~~powershell
function Read-AgentTasksEnvelope { param([Parameter(Mandatory)][string]$Path) }
function ConvertTo-AgentTasksCanonicalJson { param([Parameter(Mandatory)][object]$Value) }
function Get-AgentTasksSha256 {
    [CmdletBinding(DefaultParameterSetName='Value')]
    param(
        [Parameter(Mandatory,ParameterSetName='Value')][object]$Value,
        [Parameter(Mandatory,ParameterSetName='File')][string]$LiteralPath
    )
}
function New-AgentTasksResult {
    param([bool]$Ok,[string]$Code,[string]$Operation,[object]$Data)
}
function Throw-AgentTasksError {
    param([string]$Code,[ValidateSet(2,3,4,5)][int]$ExitCode,[string]$SafeMessage)
}
~~~

Canonicalization sorts keys ordinally, preserves arrays, emits lowercase literals, supports
only safe integers, writes UTF-8 without BOM, and excludes record_hash while hashing a record.

- [ ] **Step 5: Implement root resolution, publication, revisions, and locks**

AgentTasks.Store.ps1 must execute Git with argument arrays, resolve all roots absolutely, reject
reparse escapes, and use <common-dir>/agent-tasks or <project-root>/.agent-tasks.

For non-Git, write this nested ignore file:

~~~text
*
!.gitignore
~~~

Publish files with FileStream CreateNew, Flush(true), close, and hash verification. Publish a
bundle via a GUID temporary sibling and Directory.Move. Acquire a lock through a GUID temporary
directory containing owner.json followed by Directory.Move to
locks/<domain>-<escaped-id>.lock. Lock order is repository, phase, task, then canonical ID.

- [ ] **Step 6: Implement init-project and status**

init-project creates project/identity.json, project/state/R000001.json, locks, phases, tasks,
and trash. status validates and scans project, phases, active tasks, and trash without writing.
A second init-project returns the same identity without byte changes.

- [ ] **Step 7: Run the focused test to verify GREEN**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
~~~

Expected: PASS, zero failed assertions, no fixture residue.

- [ ] **Step 8: Record a no-commit checkpoint**

~~~powershell
git diff --check -- template/.omp/state scripts/lib/topic04-test-fixtures.ps1 scripts/tests/topic04-state-foundation.Tests.ps1
git status --short -- template/.omp/state scripts/lib/topic04-test-fixtures.ps1 scripts/tests/topic04-state-foundation.Tests.ps1
~~~

Expected: no whitespace failures; only intended files. Do not stage or commit.

---

### Task 2: Implement project, phase, task, session, work-unit, lease, and reservation lifecycle

**Files:**
- Create: template/.omp/state/lib/AgentTasks.Git.ps1
- Create: template/.omp/state/lib/AgentTasks.Lifecycle.ps1
- Create: scripts/tests/topic04-state-lifecycle.Tests.ps1
- Modify: template/.omp/state/agent-tasks.ps1
- Modify: template/.omp/state/schemas/agent-tasks-v1.schema.json

**Interfaces:**
- Produces: Initialize-AgentTasksPhase and Set-AgentTasksPhaseStatus.
- Produces: New-AgentTasksTask, Bind-AgentTasksWorktree, Claim-AgentTasksTask.
- Produces: New-AgentTasksWorkUnit, Add-AgentTasksWorkUnitOutcome.
- Produces: Add-AgentTasksCheckpoint and Write-AgentTasksRevision.
- Produces: Get-AgentTasksGitIdentity and Get-AgentTasksWorkspaceSnapshot for bootstrap.

- [ ] **Step 1: Write the failing lifecycle tests**

Cover:

~~~text
phase contract plus R000001; duplicate ID refusal; dependency-gated phase exit
phase exit and concurrent phase-linked task creation cannot both pass from one stale scan
accepted task contract creates authority before source mutation
unique stable AC IDs and explicit mandatory flags
read-only task records observation worktree but reserves no writer worktree
mutating task captures authoritative worktree and baseline reference
baseline captures HEAD/worktree plus pre-existing global dirty/untracked identities
material contract change cannot rewrite contract.json
same authoritative worktree reservation -> refusal
exact/subtree overlap -> AT-SCOPE-CONFLICT
glob overlap -> AT-SCOPE-AMBIGUOUS until user override records paths/reason/order
disjoint scopes in separate worktrees -> success
non-Git -> one mutating task, several read-only tasks
wrong revision/hash/generation/session -> refusal
elapsed time never changes lease
claim resumes only the same owning session after reconciliation; it never transfers ownership
read-only owner can checkpoint but cannot freeze or mutate source
work-unit cannot accept parent; only owner records subordinate Worker outcome
mandatory checkpoint failure -> fail closed
best-effort checkpoint failure -> reconcile_required before consequential mutation
~~~

- [ ] **Step 2: Run the test to verify RED**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
~~~

Expected: nonzero exit with AT-TEST-LIFECYCLE-MISSING.

- [ ] **Step 3: Implement closed transition maps**

~~~powershell
$script:TaskTransitions = @{
    active             = @('waiting_for_user','blocked','partial','candidate_frozen','transferring','cancelled','terminally_blocked','reconcile_required')
    waiting_for_user   = @('active','cancelled','terminally_blocked','reconcile_required')
    blocked            = @('active','waiting_for_user','cancelled','terminally_blocked','reconcile_required')
    partial            = @('active','rework','candidate_frozen','cancelled','terminally_blocked','reconcile_required')
    candidate_frozen   = @('verifying','reviewing','rework','transferring','accepted','cancelled','reconcile_required')
    verifying          = @('reviewing','rework','candidate_frozen','transferring','reconcile_required')
    reviewing          = @('rework','candidate_frozen','transferring','accepted','reconcile_required')
    rework             = @('active','partial','candidate_frozen','transferring','cancelled','terminally_blocked','reconcile_required')
    transferring       = @('active','partial','candidate_frozen','verifying','reviewing','rework','waiting_for_user','blocked','reconcile_required')
    reconcile_required = @('active','partial','candidate_frozen','rework','waiting_for_user','blocked','cancelled','terminally_blocked')
    accepted           = @()
    cancelled          = @()
    terminally_blocked = @()
}
~~~

Historical acceptance validity is separate; invalidate never rewrites the accepted transition.
Phase statuses are planned, active, waiting, blocked, accepted, cancelled, terminally_blocked.

- [ ] **Step 4: Implement Git identity and bootstrap baseline capture**

AgentTasks.Git.ps1 executes Git directly with argument arrays and captures show-toplevel,
absolute GitDir/common-dir, HEAD, branch/detached status, porcelain-v2 global dirty/untracked
state, index modes, declared ignored outputs, and nested-repository presence. Store exact
byte/type/mode identity for each dirty or untracked baseline path so later comparison separates
pre-existing user work from task output. Do not publish the first task revision until baseline
capture succeeds.

- [ ] **Step 5: Implement scopes, reservation, bootstrap, and CAS**

Write scopes use exact, subtree, or glob:

~~~json
[
  { "kind": "exact", "path": "src/index.ts" },
  { "kind": "subtree", "path": "src/feature" },
  { "kind": "glob", "pattern": "tests/**/*.Tests.ps1" }
]
~~~

Normalize repository-relative paths to forward slashes and reject absolute paths, .., NUL,
reserved device names, and case-fold duplicates. exact/subtree overlap is mechanical; an
unresolved glob comparison is ambiguous.

create-task holds the repository lock across task-ID allocation, active-reservation rescan,
temporary bundle creation, first lease/revision, flush, and final rename. When phase_id is
present it also acquires that phase lock after the repository lock and revalidates phase status
before publishing. transition-phase acquires repository, phase, then all linked task locks in
canonical task-ID order, preventing a new link during the exit scan. Every later mutation calls
this exact interface:

~~~powershell
Write-AgentTasksRevision -TaskId $taskId -ExpectedRevision $expectedRevision -ExpectedRevisionSha256 $expectedHash -ExpectedLeaseGeneration $expectedGeneration -SessionRef $sessionRef -Mutator $mutator
~~~

Project/phase revisions use the same expected-revision/hash rule without pretending to share a
task lease.

If project authority is absent, create-task performs the same idempotent project initialization
inside its repository-lock transaction. Quick therefore needs no separate model turn or
mandatory preliminary init-project call.

- [ ] **Step 6: Implement session, work-unit, and checkpoint records**

Session identity is immutable. Latest checkpoint, ownership, and end status live in task
revisions. Checkpoints contain only next action, blockers, risks, work-unit ID, lineage,
worktree binding, and timestamps. Work-unit contracts contain inputs, outputs, ownership,
dependencies, and completion conditions; outcomes remain provisional until owner integration.

claim is the resume/continue operation for the same owning session_ref. It first reconciles the
worktree/candidate boundary, never changes owner or lease generation, and refuses a different
session. A new session must use normal handoff or user-authorized takeover.

- [ ] **Step 7: Wire lifecycle operations**

Add create-phase, transition-phase, create-task, bind-worktree, claim, create-work-unit,
record-work-unit-outcome, and checkpoint to the closed CLI switch.

- [ ] **Step 8: Run foundation and lifecycle tests**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
~~~

Expected: both PASS. Repeat the shared-worktree reservation fixture 20 times; never two winners.

- [ ] **Step 9: Record a no-commit checkpoint**

~~~powershell
git diff --check -- template/.omp/state scripts/tests/topic04-state-lifecycle.Tests.ps1
git status --short -- template/.omp/state scripts/tests/topic04-state-lifecycle.Tests.ps1
~~~

Expected: no whitespace failures. Do not stage or commit.

---

### Task 3: Implement exact Git baselines, candidate freeze, and drift invalidation

**Files:**
- Modify: template/.omp/state/lib/AgentTasks.Git.ps1
- Create: template/.omp/state/lib/AgentTasks.Candidate.ps1
- Create: scripts/tests/topic04-state-candidate.Tests.ps1
- Modify: template/.omp/state/agent-tasks.ps1
- Modify: template/.omp/state/lib/AgentTasks.Lifecycle.ps1
- Modify: template/.omp/state/schemas/agent-tasks-v1.schema.json

**Interfaces:**
- Consumes: Get-AgentTasksGitIdentity and bootstrap snapshot from Task 2.
- Extends: Get-AgentTasksWorkspaceSnapshot with candidate-time file/type/mode hashing.
- Produces: Compare-AgentTasksWorkspaceSnapshot -Baseline <record> -Current <record>.
- Produces: New-AgentTasksCandidate -TaskState <state> -AcceptanceInputs <entries>
  -ScopeDispositions <entries>.
- Produces: Test-AgentTasksCandidate -TaskId <id> -CandidateId <id>.

- [ ] **Step 1: Write the failing candidate tests**

Create disposable repositories for:

~~~text
clean tracked modification -> owned output
pre-existing dirty tracked file changed again -> owned output
pre-existing dirty tracked file unchanged -> not task output
new nonignored untracked file -> owned output
tracked deletion -> explicit absent marker
executable-mode change -> manifest change
symlink target change -> hash link target without following it
declared ignored output -> hashed even though Git omits it
undeclared ignored cache -> outside candidate identity
Gitlink -> index mode plus exact commit
dirty submodule/nested repository -> AT-NESTED-REPOSITORY-DIRTY
HEAD/branch/worktree change after baseline -> reconcile_required
changed path outside scope without disposition -> AT-SCOPE-UNEXPLAINED
explicit disposition -> recorded, never silently dropped
acceptance input mutation -> candidate drift
same bytes in different enumeration order -> same candidate hash
C1 mutation -> old records historical and current state rework
C2 refreeze -> new hash and next lineage sequence
~~~

- [ ] **Step 2: Run the candidate test to verify RED**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
~~~

Expected: nonzero exit with AT-TEST-CANDIDATE-MISSING.

- [ ] **Step 3: Implement candidate-time comparison and nested-repository validation**

Run Git directly with argument arrays:

~~~text
git rev-parse --show-toplevel
git rev-parse --path-format=absolute --git-dir
git rev-parse --path-format=absolute --git-common-dir
git rev-parse HEAD
git status --porcelain=v2 -z --untracked-files=all
git ls-files -z --stage
git submodule status --recursive
~~~

Compare the Task 2 baseline with current HEAD, worktree identity, porcelain-v2 global
dirty/untracked state, index modes, and declared ignored outputs. This detects out-of-scope
changes without hashing all clean files.

Hash regular files as bytes, symlink target text without following, and Gitlinks as mode 160000
plus commit. Reject path/reparse escapes. Mirror the pinned OMP nested-repository discovery
superset: tracked submodules recursively plus nested .git entries, excluding .git and
node_modules and stopping descent at a nested repository.

- [ ] **Step 4: Implement scoped candidate construction**

Candidate canonical input includes:

~~~json
{
  "schema_version": 1,
  "record_type": "candidate",
  "task_contract_hash": "SHA256",
  "candidate_id": "C1",
  "lineage": 1,
  "baseline": {},
  "entries": [
    {
      "path": "src/index.ts",
      "role": "owned_output",
      "presence": "present",
      "sha256": "SHA256",
      "file_type": "regular",
      "mode": "100644"
    }
  ],
  "integration_provenance": []
}
~~~

Sort entries by normalized path then role. An absent path has presence absent and no sha256.
Hash contract, baseline identity, manifest, work-unit integration provenance, and recorded
scope dispositions together.

The model declares acceptance inputs but never the final owned-output list. The tool derives
outputs and blocks every unexplained changed path. Ignored paths are not searched globally;
declared ignored outputs are exact-path checked and hashed.

- [ ] **Step 5: Implement freeze and check**

freeze validates owner/revision/lease, captures current workspace, rejects HEAD/worktree/nested
drift, derives outputs, validates scope, hashes acceptance inputs, publishes Cn.json, publishes
one referencing task revision, and enters candidate_frozen.

check rehashes at verification, review, acceptance, handoff, and resume/takeover boundaries.
Drift preserves C1 and evidence, marks C1 stale in a new revision, and enters rework or
reconcile_required. It never edits an old candidate.

Extend claim from Task 2 so a task with a selected candidate must pass this same rehash before
the owning session resumes consequential work.

- [ ] **Step 6: Wire freeze and check into the CLI**

Return only task ID, candidate ID/hash, state revision/hash, drift disposition, and status.
Never emit source contents.

- [ ] **Step 7: Run tests through candidate behavior**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
~~~

Expected: all PASS with fixture cleanup.

- [ ] **Step 8: Record a no-commit checkpoint**

~~~powershell
git diff --check -- template/.omp/state scripts/tests/topic04-state-candidate.Tests.ps1
git status --short -- template/.omp/state scripts/tests/topic04-state-candidate.Tests.ps1
~~~

Expected: no whitespace failures. Do not stage or commit.

---

### Task 4: Implement typed evidence, promoted artifacts, and candidate-bound acceptance

**Files:**
- Create: template/.omp/state/lib/AgentTasks.Evidence.ps1
- Create: scripts/tests/topic04-state-evidence.Tests.ps1
- Modify: template/.omp/state/agent-tasks.ps1
- Modify: template/.omp/state/lib/AgentTasks.Lifecycle.ps1
- Modify: template/.omp/state/schemas/agent-tasks-v1.schema.json

**Interfaces:**
- Produces: Add-AgentTasksEvidence -TaskState <state> -Request <payload>.
- Produces: Copy-AgentTasksPromotedArtifact -TaskState <state> -SourcePath <path>
  -MediaType <type>.
- Produces: Test-AgentTasksAcceptance -TaskState <state> -Candidate <candidate>.
- Produces: Set-AgentTasksTerminalState -Target accepted|cancelled|terminally_blocked.

- [ ] **Step 1: Write the failing evidence tests**

Assert:

~~~text
test evidence requires candidate/input binding
verification evidence requires candidate/input binding and may reference test evidence IDs
review evidence requires independent producer/session and candidate binding
user authority binds to contract hash and scope
provider/environment evidence accepts only allowlisted secret-free fields
external fact requires source identity plus expiry or fresh-at-acceptance rule
no arbitrary global TTL appears
unknown evidence type/producer is rejected
model-authored PASS cannot substitute for command/review/user evidence
unknown covered AC ID is rejected
C1 evidence cannot satisfy C2
candidate/input drift invalidates without deleting
promotion outside allowed roots is rejected
symlink/reparse escape is rejected
secret-shaped key/value or raw .env artifact is rejected
artifact destination is content-addressed and non-overwriting
same bytes deduplicate only after validation
missing/hash-mismatched artifact invalidates evidence
uncovered AC, missing obligations, conflict, partial, or drift blocks acceptance
later invalidation preserves historical acceptance
cancelled/terminally_blocked require compact reason but no candidate
~~~

- [ ] **Step 2: Run the evidence test to verify RED**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-evidence.Tests.ps1
~~~

Expected: nonzero exit with AT-TEST-EVIDENCE-MISSING.

- [ ] **Step 3: Implement the closed evidence registry**

~~~powershell
$script:EvidenceTypes = @{
    test = @{
        CandidateBound = $true
        Producers = @('tech_lead','deterministic_runner')
        Requires = @('observation','covered_ac_ids','validity_triggers','acceptance_input_hashes')
    }
    verification = @{
        CandidateBound = $true
        Producers = @('tech_lead','deterministic_runner')
        Requires = @('observation','covered_ac_ids','validity_triggers','acceptance_input_hashes')
        Optional = @('input_evidence_ids')
    }
    review = @{
        CandidateBound = $true
        Producers = @('independent_reviewer')
        Requires = @('observation','covered_ac_ids','validity_triggers','producer_session_ref')
    }
    user_authority = @{
        CandidateBound = $false
        Producers = @('user')
        Requires = @('authority_scope','contract_hash','observation')
    }
    provider_environment = @{
        CandidateBound = $false
        Producers = @('deterministic_probe','tech_lead')
        Requires = @('environment_fingerprint','validity_triggers','observation')
    }
    external_fact = @{
        CandidateBound = $false
        Producers = @('retrieval_source','tech_lead')
        Requires = @('source_identity','validity_triggers','observation')
    }
}
~~~

observation is structured and compact, never transcript. A test record is an atomic observation;
a verification record is the contract-level verification result and may reference the exact test
evidence IDs it adjudicates. command/source strings are inert provenance and are never executed.
Later supersession/invalidation is a new linked record or task revision, never an edit.

- [ ] **Step 4: Implement safe promoted artifacts**

Allow only task scratch at .task/<task-id> in the retained bound worktree or a session artifact
root registered by a verified adapter/user-authority record. Reject traversal/reparse escapes,
bound default promotion to 2 MiB, scan names and UTF-8 text for secret-shaped material, and
require caller sanitization for larger/raw output.

Publish:

~~~text
tasks/<task-id>/artifacts/<sha256>.<normalized-extension>
~~~

Use CreateNew, verify hash, publish artifact metadata, then reference it in a new revision.
Never copy a session directory or transcript.

- [ ] **Step 5: Implement acceptance and terminal transitions**

accepted, under one task lock, requires:

1. current candidate rehash passes;
2. every mandatory AC has valid evidence;
3. required verification/review classes exist;
4. promoted artifacts exist and match;
5. no blocking finding, scope/ownership conflict, authority gap, or partial state remains;
6. expected revision/hash/lease still match; and
7. the terminal revision names the exact candidate hash.

The task lock serializes authority but cannot freeze the worktree against an unrelated local
process. Rehash immediately before publishing acceptance and define the terminal decision as
acceptance of those frozen bytes. A later ordinary edit does not rewrite history; later
evidence that those original bytes violated the contract uses invalidate.

invalidate appends historical_acceptance_validity invalidated and optional remediation task ID.
It never rewrites accepted state or evidence.

- [ ] **Step 6: Wire promote-artifact, record-evidence, close, and invalidate**

Return only IDs, hashes, coverage, and next state. Sanitize all errors.

- [ ] **Step 7: Run tests through acceptance**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-evidence.Tests.ps1
~~~

Expected: all PASS.

- [ ] **Step 8: Record a no-commit checkpoint**

~~~powershell
git diff --check -- template/.omp/state scripts/tests/topic04-state-evidence.Tests.ps1
git status --short -- template/.omp/state scripts/tests/topic04-state-evidence.Tests.ps1
~~~

Expected: no whitespace failures. Do not stage or commit.

---

### Task 5: Implement checkpoints, two-phase handoff, takeover, and lock recovery

**Files:**
- Create: template/.omp/state/lib/AgentTasks.Transfer.ps1
- Create: scripts/tests/topic04-state-transfer.Tests.ps1
- Modify: template/.omp/state/agent-tasks.ps1
- Modify: template/.omp/state/lib/AgentTasks.Lifecycle.ps1
- Modify: template/.omp/state/schemas/agent-tasks-v1.schema.json

**Interfaces:**
- Produces: Start-AgentTasksHandoff.
- Produces: Complete-AgentTasksHandoff.
- Produces: Invoke-AgentTasksTakeover.
- Produces: Repair-AgentTasksLock.
- Consumes: candidate rehash and lifecycle CAS from Tasks 2–4.

- [ ] **Step 1: Write failing transfer tests**

Cover:

~~~text
normal handoff requires predecessor checkpoint and successor identity
begin-handoff publishes immutable record and moves lease to transferring
predecessor remains owner until successor accept
accept validates contract/worktree/revision and candidate hashes when candidate exists
pre-candidate handoff reconciles baseline/current scoped workspace
successful accept increments generation and makes predecessor read-only
stale/malformed handoff refuses transfer
handoff prose field is unknown/rejected
compaction does not alter task/candidate/session authority
no elapsed time triggers takeover
takeover without explicit user confirmation refuses
takeover validates actual workspace and invalidates uncertain evidence
lock recovery without explicit confirmation refuses
lock recovery validates owner record and no active operation
recovery never resets/deletes/reverts workspace
~~~

- [ ] **Step 2: Run the test to verify RED**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-transfer.Tests.ps1
~~~

Expected: nonzero exit with AT-TEST-TRANSFER-MISSING.

- [ ] **Step 3: Implement two-phase normal handoff**

begin-handoff:

1. requires current owner and mandatory checkpoint;
2. publishes immutable handoff with task/contract/revision/candidate/worktree identities,
   successor ref/runtime, last work unit, risks/blockers, and next action;
3. writes transferring state while predecessor remains owner; and
4. forbids unrelated mutation during transfer.

accept-handoff:

1. requires named successor;
2. reloads authority and actual workspace;
3. rehashes candidate/evidence or reconciles pre-candidate baseline;
4. publishes a successor session identity if absent;
5. increments lease generation and transfers owner; and
6. publishes the new active/prior-status revision.

- [ ] **Step 4: Implement user-authorized takeover and stale-lock recovery**

Both payloads use:

~~~json
{
  "confirmed": true,
  "authority": "user",
  "reason": "predecessor process is unavailable",
  "observed_at": "RFC3339-UTC"
}
~~~

The core validates structure and records the authorization; it does not infer approval from
model prose. A lock owner record includes local host identity, process ID, and process start
time. recover-lock refuses when the same process instance is alive or when liveness cannot be
established safely. takeover revalidates workspace, records recovery handoff, invalidates
uncertain evidence, and increments lease generation. recover-lock works on one exact lock
domain/ID and never touches a workspace.

- [ ] **Step 5: Wire begin-handoff, accept-handoff, takeover, and recover-lock**

Errors AT-HANDOFF-STALE, AT-TAKEOVER-AUTHORITY, and AT-LOCK-RECOVERY-AUTHORITY must be distinct
and sanitized.

- [ ] **Step 6: Run all transfer-enabled tests**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-evidence.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-transfer.Tests.ps1
~~~

Expected: all transfer assertions PASS with zero skipped/pending assertions.

- [ ] **Step 7: Record a no-commit checkpoint**

~~~powershell
git diff --check -- template/.omp/state scripts/tests/topic04-state-transfer.Tests.ps1
git status --short -- template/.omp/state scripts/tests/topic04-state-transfer.Tests.ps1
~~~

Expected: no whitespace failures. Do not stage or commit.

---

### Task 6: Implement archive, restore, purge, and root/schema migration

**Files:**
- Create: template/.omp/state/lib/AgentTasks.Retention.ps1
- Create: scripts/tests/topic04-state-retention.Tests.ps1
- Modify: template/.omp/state/agent-tasks.ps1
- Modify: template/.omp/state/schemas/agent-tasks-v1.schema.json

**Interfaces:**
- Produces: Get-AgentTasksCleanupPlan.
- Produces: Move-AgentTasksTaskToTrash and Restore-AgentTasksTask.
- Produces: Remove-AgentTasksPurgedTask.
- Produces: Move-AgentTasksLegacyRoot and Invoke-AgentTasksSchemaMigration.

- [ ] **Step 1: Write the failing retention tests**

Assert:

~~~text
cleanup defaults to dry-run and changes no bytes
active/transferring/reconcile_required task cannot archive
task required by nonterminal dependency cannot archive
apply moves exact terminal task to trash under repository lock
task ID remains resolvable in trash
restore reverses archive and rejects duplicate active ID
purge requires confirmation exactly equal to task ID
purge refuses live references by default
purge never invokes Git worktree delete/prune
non-Git state becomes read-only after Git initialization
migrate validates source/target, copy hashes, and publishes one target authority
legacy source is renamed to a read-only migrated backup marker
unknown newer schema -> status only; mutation refused
v1-to-v1 migration -> AT-MIGRATION-NOT-REQUIRED without byte changes
interrupted migration -> explicit recovery, never two writable roots
~~~

- [ ] **Step 2: Run the test to verify RED**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-retention.Tests.ps1
~~~

Expected: retention assertions fail with AT-TEST-RETENTION-MISSING.

- [ ] **Step 3: Implement recoverable archive and restore**

cleanup dry-run emits exact paths, dependency blockers, and estimated bytes. cleanup apply
rechecks terminal/dependency status under repository plus task locks, then Directory.Move from
tasks/<id> to trash/<id>. restore performs the inverse under the same invariant scan. status
scans both namespaces and rejects duplicate IDs.

- [ ] **Step 4: Implement exact-target purge**

purge requires terminal task in trash, confirmation byte-equal to task ID, and no references
from active/nonterminal phase or task records. Resolve and verify the absolute trash target is
inside StateRoot/trash before recursive deletion. Never run a Git worktree command.

- [ ] **Step 5: Implement migration gates**

When .agent-tasks exists and Git now resolves:

1. mark legacy root read-only through a migration lock;
2. validate every revision/supporting-record chain;
3. copy into a temporary sibling of <git-common-dir>/agent-tasks;
4. verify every file hash and reject an existing target authority;
5. atomically rename target bundle;
6. rename legacy root to .agent-tasks.migrated-<UTC>-<hash8>; and
7. emit the target identity and backup path.

Schema v1 has no content migration yet. Unknown newer schema is read-only. The migrate command
returns AT-MIGRATION-NOT-REQUIRED for valid v1.

- [ ] **Step 6: Wire cleanup, restore, purge, and migrate**

cleanup request mode is exactly dry-run or apply. There is no force flag. purge and migration
failure outputs contain no record contents.

- [ ] **Step 7: Run the complete deterministic-core suite**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-evidence.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-transfer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-retention.Tests.ps1
~~~

Expected: all PASS, zero skipped/pending assertions, zero fixture residue.

- [ ] **Step 8: Record a no-commit checkpoint**

~~~powershell
git diff --check -- template/.omp/state scripts/tests/topic04-state-retention.Tests.ps1
git status --short -- template/.omp/state scripts/tests/topic04-state-retention.Tests.ps1
~~~

Expected: no whitespace failures. Do not stage or commit.

---

### Task 7: Install the state component and project one explicit cross-runtime adapter

**Files:**
- Create: template/.omp/state/PROTOCOL.md
- Create: scripts/tests/topic04-installer.Tests.ps1
- Create: docs/task-state.md
- Create: docs/evidence/current-product/topic-04/adapter-gate.json
- Modify: scripts/install-template.ps1
- Modify: scripts/uninstall-template.ps1
- Modify: template/.omp/AGENTS.md
- Modify: template/.omp/commands/quick.md
- Modify: template/.omp/commands/standard.md
- Modify: template/.omp/commands/orchestrated.md
- Modify: docs/installation.md
- Modify: docs/rollback.md

**Interfaces:**
- Consumes: complete state CLI from Tasks 1–6.
- Produces: installer component name state mapped to template/.omp/state.
- Produces: one explicit adapter contract usable by either Claude or Codex/OMP.
- Produces: adapter-gate evidence that prevents an unprobed automatic hook from being claimed.

- [ ] **Step 1: Write failing installer and adapter tests**

Cover:

~~~text
default dry-run lists state component and changes no target bytes
state-only apply reproduces exact template/.omp/state tree
PowerShell 7.4+ absence/old version -> clear fail before copy
installer itself remains Windows PowerShell 5.1 parseable
install never reads/writes/deletes <git-common-dir>/agent-tasks
reinstall updates executable files but preserves existing operational state
rollback restores prior .omp/state bytes but preserves operational state
protected credential/session/model files remain unchanged
AGENTS and every workflow create state after accepted contract and before mutation
Quick uses the same minimal task authority; it is not exempt
missing core blocks mutation but permits read-only diagnosis
all workflow text points to one PROTOCOL.md rather than duplicating schemas
no hook/extension/new skill/new command is installed by Topic 04
Claude and Codex instructions invoke the same request/result envelope
adapter-gate says automatic adapter NOT_INSTALLED and Topic 08 probe REQUIRED
~~~

- [ ] **Step 2: Run the installer test to verify RED**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-installer.Tests.ps1
~~~

Expected: nonzero exit with AT-TEST-INSTALLER-STATE-COMPONENT-MISSING.

- [ ] **Step 3: Add the state installer component**

Add state to the default Components list and map it to the state directory. When selected:

1. locate pwsh;
2. require version at least 7.4.0;
3. validate the source module/schema manifest before planning copies;
4. preserve dry-run as the default;
5. include the state tree in the existing timestamped .omp backup; and
6. never touch a resolved agent-tasks or .agent-tasks authority root.

The uninstaller restores only installed .omp files from the selected backup. It must explicitly
report that operational state is retained and never offer to remove it.

- [ ] **Step 4: Write the compact black-box protocol**

PROTOCOL.md documents:

~~~text
how to locate project .omp/state before user .omp/agent/state
pwsh 7.4+ prerequisite
request file/stdin invocation
exit codes 0, 2, 3, 4, 5
status/init/create/checkpoint/freeze/check/evidence/handoff/close examples
never edit authority JSON directly
never copy authority into a prompt
read-only diagnosis behavior when core/root is unavailable
cleanup dry-run and exact-target confirmation
~~~

It does not repeat schemas or list internal module functions.

- [ ] **Step 5: Project explicit use into the selected workflow prompts**

Keep persistent text compact:

~~~text
After objective, authority, mandatory ACs, and required verification/review are accepted,
initialize or create the task through state/agent-tasks.ps1 before mutation. At lifecycle
boundaries call the same core described by state/PROTOCOL.md. Never edit authority files.
If the core/root is unavailable, mutating work fails closed; read-only diagnosis may continue.
~~~

Quick creates the minimal contract/state immediately and may still finish in one session. Standard
and Orchestrated use the same core; Orchestrated records work units, but only the integrated
candidate can close the task. No text mandates a subagent spawn.

- [ ] **Step 6: Record the automatic-adapter gate honestly**

adapter-gate.json contains:

~~~json
{
  "schema_version": 1,
  "record_type": "topic04_adapter_gate",
  "pinned_source_commit": "3a8591a8af5b6d200088d12ca75a5517cb064fa8",
  "pinned_source_version": "17.2.10",
  "observed_installed_omp_version": "17.2.12",
  "manual_core_adapter": "SELECTED",
  "automatic_lifecycle_adapter": "NOT_INSTALLED",
  "reason_code": "TOPIC08_INSTALLED_RUNTIME_PROBE_REQUIRED",
  "candidate_events": [
    "session_start",
    "session_before_switch",
    "session_switch",
    "session_before_compact",
    "session_stop"
  ]
}
~~~

Do not perform a provider/model call merely to turn this gate green. Topic 08 owns the minimum
installed-runtime probe and any automatic attachment.

- [ ] **Step 7: Run installer, adapter, and core regressions**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-foundation.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-evidence.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-transfer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-retention.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$errors=$null; [void][Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'scripts/install-template.ps1'),[ref]$null,[ref]$errors); if($errors.Count){$errors; exit 1}"
~~~

Expected: all tests PASS; Windows PowerShell reports zero installer parse errors.

- [ ] **Step 8: Record a no-commit checkpoint**

~~~powershell
git diff --check -- template/.omp/state template/.omp/AGENTS.md template/.omp/commands scripts/install-template.ps1 scripts/uninstall-template.ps1 scripts/tests/topic04-installer.Tests.ps1 docs/task-state.md docs/evidence/current-product/topic-04 docs/installation.md docs/rollback.md
git status --short -- template/.omp/state template/.omp/AGENTS.md template/.omp/commands scripts/install-template.ps1 scripts/uninstall-template.ps1 scripts/tests/topic04-installer.Tests.ps1 docs/task-state.md docs/evidence/current-product/topic-04 docs/installation.md docs/rollback.md
~~~

Expected: no whitespace failures. Do not stage or commit.

---

### Task 8: Reconcile canonical authority, phase ownership, documentation, and focused guards

**Files:**
- Create: scripts/lib/topic04-durable-state.ps1
- Create: scripts/tests/topic04-durable-state.Tests.ps1
- Create: scripts/validate-topic04-durable-state.ps1
- Modify: scripts/validate-template.ps1
- Modify: spec/key/04-decision-log.md
- Modify: spec/key/01-dna.md
- Modify: spec/key/03-token-quality-model.md
- Modify: spec/01-target-architecture.md
- Modify: spec/02-runtime-semantics.md
- Modify: spec/04-workflow-sizing.md
- Modify: spec/05-context-and-token-model.md
- Modify: spec/08-isolation-and-concurrency.md
- Modify: spec/10-verification-and-review.md
- Modify: spec/12-installation-and-rollback.md
- Modify: spec/13-validation-and-evaluation.md
- Modify: spec/14-upgradeability-and-governance.md
- Modify: spec/15-security-and-failure-recovery.md
- Modify: spec/16-migration-plan.md
- Modify: spec/README.md
- Modify: spec/phases/phase-02-core-orchestration.md
- Modify: spec/phases/phase-03-context-efficiency.md
- Modify: spec/phases/phase-05-installation-hardening.md
- Modify: spec/phases/phase-06-evaluation.md
- Modify: spec/phases/phase-07-stabilization.md
- Modify: README.md
- Modify: docs/architecture.md
- Modify: docs/workflow-v0.md
- Modify: docs/security.md

**Interfaces:**
- Produces: KD-028 as the authority decision.
- Produces: Test-Topic04DurableStateContract -RepositoryRoot <path>.
- Produces: a focused validator section in scripts/validate-template.ps1.
- Consumes: exact mechanism and limitations proven by Tasks 1–7.

- [ ] **Step 1: Write the failing contract/mutation tests**

The helper must return structured PASS/FAIL results with stable codes. The mutation suite copies
load-bearing files to a fixture and proves each mutation is caught:

~~~text
T04-ROOT-GIT-COMMON          replace common-dir agent-tasks with worktree .task
T04-ROOT-NAMESPACE           remove the final s from the approved authority namespace
T04-STATE-AUTHORITY          transcript/handoff/compaction becomes source of truth
T04-REVISION-IMMUTABLE       overwrite/current.json or last-write-wins appears
T04-WRITER-LEASE             heartbeat timeout/automatic takeover appears
T04-WORKTREE-RESERVATION     concurrent mutating tasks share authoritative worktree
T04-CANDIDATE-SCOPE          model supplies final owned-output list
T04-CANDIDATE-EVIDENCE       old candidate evidence accepted after mutation
T04-EVIDENCE-TTL             global evidence TTL appears
T04-HANDOFF-TRANSFER         prose alone transfers ownership
T04-OFFLOAD-AUTHORITY        artifact:// or .task becomes lifecycle authority
T04-SECRET-BOUNDARY          transcript/secret fields appear in state schema
T04-CLEANUP-SAFETY           automatic purge or worktree deletion appears
T04-ADAPTER-GATE             automatic hook claimed without installed-runtime probe
T04-INSTALL-COMPONENT        state tree omitted from installer/validator
T04-PHASE-OWNERSHIP          Topic 04 consumer requirements missing from phase projections
~~~

Also assert 25 approved design requirements against the implementation/spec projection, using
the same checklist recorded during design self-review.

- [ ] **Step 2: Run the focused test to verify RED**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-durable-state.Tests.ps1
~~~

Expected: failures because KD-028 and canonical projections are absent.

- [ ] **Step 3: Record KD-028 and the DNA gene**

KD-028 must state:

~~~yaml
decision: local immutable JSON bundle plus deterministic PowerShell state core
git_root: <absolute-git-common-dir>/agent-tasks
non_git_root: <project-root>/.agent-tasks
writer: one authority/integration lease per task
mutating_concurrency: distinct authoritative worktree plus scope reservation
candidate: scoped baseline-relative identity manifest, not backup
evidence: typed, immutable, candidate/contract-bound
handoff: two-phase structured transfer; user-authorized crash takeover
offload: transient raw tier plus compact promoted evidence
cleanup: dry-run, recoverable trash, separate exact-target purge
runtime: explicit shared core in Topic 04; automatic adapter gated to Topic 08
~~~

DNA projects only these invariants and cites KD-028 plus the direct specs; it does not duplicate
CLI payload details.

- [ ] **Step 4: Reconcile direct specifications**

Apply exact ownership:

| Spec | Required projection |
|---|---|
| 01 target architecture | local state-core component and authority hierarchy |
| 02 runtime semantics | lifecycle operations, CAS refusal, explicit manual adapter |
| 04 workflow sizing | accepted contract creates state; candidate/session/work-unit boundaries |
| 05 context/token | checkpoints, offload tiers, compact projections, no second compactor |
| 08 isolation | authoritative versus subordinate worktrees, reservations, integration owner |
| 10 verification/review | exact candidate/evidence binding and post-mutation invalidation |
| 12 installation | state component, pwsh floor, backup/rollback without state deletion |
| 13 validation | L0 schemas, L1 root/runtime, L2 deterministic core, L3/L4 behavior |
| 14 governance | schema/profile version and explicit migration |
| 15 security/recovery | paths, secrets, locks, takeover, archive/purge failure behavior |
| 16 migration | non-Git-to-Git migration and Topic 08 adapter lift path |
| README | concise authority/location/lifecycle summary |

Token-quality model records that raw offload is not acceptance evidence and that boundary
rehashing is the cost/quality trade. Remove or supersede active wording that still treats
durable state as deferred after Topic 04.

- [ ] **Step 5: Project phase ownership without moving the DAG**

Phase 02 consumes task/candidate/work-unit authority; Phase 03 consumes checkpoints, handoff,
and offload; Phase 05 installs/rolls back core files while retaining state; Phase 06 owns
deterministic and behavioral fixtures; Phase 07 reconciles release limitations and migration.

Do not add a new phase or dependency edge. Verify every existing Depends On/Blocks pair remains
reciprocal.

- [ ] **Step 6: Update concise human documentation**

README and docs explain:

~~~text
operational state is local and outside Git
agent-tasks plural is the Git namespace
multiple mutating tasks use separate worktrees
one task authority writer; subordinate Worker work is provisional
candidate manifest is not source backup
explicit CLI works for Claude and Codex/OMP
automatic hooks remain a Topic 08 gate
cleanup/rollback do not delete operational state
known limitations: same machine, repository metadata loss, boundary detection
acceptance-input completeness remains a Tech Lead semantic responsibility
writer leases provide consistency, not protection from a local process with filesystem access
~~~

- [ ] **Step 7: Implement the focused validator and full-validator section**

topic04-durable-state.ps1 must be PowerShell 5.1-compatible and expose:

~~~powershell
function Test-Topic04DurableStateContract {
    param([Parameter(Mandatory)][string]$RepositoryRoot)
}
~~~

The entry point prints counts and exits nonzero on FAIL. Add Section 7 to
validate-template.ps1, load the helper safely, and include every installed state-core file and
schema in the required-file/nonempty checks.

- [ ] **Step 8: Run focused tests and validators**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-durable-state.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/tests/topic04-durable-state.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate-topic04-durable-state.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
~~~

Expected: mutation suite catches every mutation; focused validators pass in both editions; full
validator has zero failures. Preserve only already-known unrelated warnings.

- [ ] **Step 9: Record a no-commit checkpoint**

~~~powershell
git diff --check -- spec scripts/lib/topic04-durable-state.ps1 scripts/tests/topic04-durable-state.Tests.ps1 scripts/validate-topic04-durable-state.ps1 scripts/validate-template.ps1 README.md docs/architecture.md docs/workflow-v0.md docs/security.md
git status --short -- spec scripts/lib/topic04-durable-state.ps1 scripts/tests/topic04-durable-state.Tests.ps1 scripts/validate-topic04-durable-state.ps1 scripts/validate-template.ps1 README.md docs/architecture.md docs/workflow-v0.md docs/security.md
~~~

Expected: no whitespace failures and only intended paths. Do not stage or commit.

---

### Task 9: Run the final regression matrix and write the Topic 04 handoff record

**Files:**
- Create: codex-topic04-durable-task-state-changelog.md
- Modify: CHANGELOG.md

**Interfaces:**
- Consumes: all implementation, focused tests, validators, and design success criteria.
- Produces: one evidence-backed status of IMPLEMENTED, IMPLEMENTED_WITH_ENVIRONMENT_BLOCK, or
  BLOCKED; no unsupported production-ready claim.

- [ ] **Step 1: Run the complete Topic 04 core matrix fresh**

~~~powershell
$tests = @(
  'scripts/tests/topic04-state-foundation.Tests.ps1',
  'scripts/tests/topic04-state-lifecycle.Tests.ps1',
  'scripts/tests/topic04-state-candidate.Tests.ps1',
  'scripts/tests/topic04-state-evidence.Tests.ps1',
  'scripts/tests/topic04-state-transfer.Tests.ps1',
  'scripts/tests/topic04-state-retention.Tests.ps1',
  'scripts/tests/topic04-installer.Tests.ps1',
  'scripts/tests/topic04-durable-state.Tests.ps1'
)
foreach ($test in $tests) {
    & pwsh -NoProfile -File $test
    if ($LASTEXITCODE -ne 0) { throw "Topic 04 test failed: $test" }
}
~~~

Expected: every runner exits 0 with no pending/skipped authority assertion.

- [ ] **Step 2: Run predecessor and repository regressions**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic02-workflow-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-topology-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-installer.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
~~~

Expected: zero failures. The known RULES token-budget warning may remain only if unchanged and
explicitly recorded.

- [ ] **Step 3: Prove one behavioral lifecycle without a model call**

In a disposable Git fixture:

1. init project;
2. create mutating task T1 and read-only task T2;
3. reject a second mutating task on T1 worktree;
4. modify one scoped file;
5. freeze C1;
6. record deterministic test evidence;
7. mutate the file and prove C1 check fails;
8. freeze C2 and prove C1 evidence cannot satisfy it;
9. record C2 evidence and close accepted;
10. begin/accept a separate task handoff;
11. dry-run then apply archive; and
12. restore it.

Capture only result envelopes and hashes in the test output. Expected: all lifecycle states and
refusals match the design, with no transcript or source contents in authority.

- [ ] **Step 4: Verify local runtime facts and the honest adapter boundary**

~~~powershell
omp --version
pwsh --version
git -C _research/upstreams/oh-my-pi rev-parse HEAD
git -C _research/upstreams/oh-my-pi status --short
Get-Content -Raw docs/evidence/current-product/topic-04/adapter-gate.json
~~~

Expected on the current machine: OMP 17.2.12, PowerShell 7.6.4, pinned clean source
3a8591a8af5b6d200088d12ca75a5517cb064fa8, manual adapter selected, automatic adapter not
installed. Do not turn absence of the Topic 08 probe into a Topic 04 core failure.

- [ ] **Step 5: Run integrity and dirty-worktree checks**

~~~powershell
git diff --check
git status --short
git diff --name-only
git diff --cached --name-only
~~~

Expected: diff check exits 0; staged set remains exactly as it was before Topic 04; unrelated
dirty files remain preserved. Inspect Topic 04 paths explicitly rather than claiming ownership
of the whole dirty tree.

- [ ] **Step 6: Write the Topic 04 changelog**

Record:

~~~yaml
topic: 04
decision: local-file-bundle-with-deterministic-state-tool
state_namespace: agent-tasks
core_runtime: PowerShell >= 7.4
operational_state_in_git: false
automatic_adapter: not_installed_topic08_probe_required
tests:
  foundation: <fresh count>
  lifecycle: <fresh count>
  candidate: <fresh count>
  evidence: <fresh count>
  transfer_retention: <fresh count>
  installer: <fresh count>
  focused_contract: <fresh count>
validators:
  topic02: <PASS/FAIL>
  topic03: <PASS/FAIL>
  topic04: <PASS/FAIL>
  full: <PASS/FAIL plus exact known warnings>
known_limitations:
  - local-only and lost with repository metadata
  - candidate manifest is identity, not backup
  - direct external edits detected at boundaries
  - automatic lifecycle attachment remains Topic 08
git:
  branch: <observed>
  staged_paths_changed_by_topic04: 0
  commit_created: false
status: <IMPLEMENTED|IMPLEMENTED_WITH_ENVIRONMENT_BLOCK|BLOCKED>
~~~

Use actual counts/output only. Do not write PASS from expectation.

- [ ] **Step 7: Update the concise product changelog**

Add one Topic 04 entry describing local durable authority, exact candidate/evidence binding,
explicit handoff, safe retention, the pwsh requirement, and the Topic 08 automatic-adapter gate.

- [ ] **Step 8: Run verification once more after documentation**

~~~powershell
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
git diff --check
~~~

Expected: zero failures and no whitespace errors.

- [ ] **Step 9: Hand off without staging or committing**

Report:

- what core behavior was implemented;
- exact fresh test/validator totals;
- whether any environment-only adapter probe remains;
- operational-state location and cleanup behavior;
- every known limitation;
- exact Topic 04 paths; and
- confirmation that no commit/stage/push/PR occurred.

Do not request Opus review automatically. If a genuinely hard unresolved issue remains, record
the exact issue and evidence for a later Opus review while continuing all unblocked work.

---

## Final Implementation Gate

Topic 04 is complete only when all twelve accepted design success criteria map to passing tests
or validators, the state core works without a model call, installation/rollback preserve
operational state, candidate/evidence drift is fail-closed, normal handoff and user-authorized
recovery are proven, and canonical specs/phases describe the same behavior.

The missing automatic OMP lifecycle adapter is not concealed: Topic 04 selects the explicit
shared-core adapter, while Topic 08 owns the installed-runtime probe and any automatic hook,
skill, extension, or command attachment.
