# Topic 04 — Durable Task State, Candidate Lifecycle, Handoff, and Offload

> USER-CONFIRMED DESIGN; IMPLEMENTATION PLAN WRITTEN
>
> Approved decisions were made interactively on 2026-08-13. This document records the
> adjudicated design after a focused failure-mode review. It does not implement the runtime,
> patch canonical specs or phases, install an adapter, or authorize a commit.

## 1. Purpose

Topic 02 defined the conceptual hierarchy and lifecycle:

~~~text
Project
└── Phase
    └── Task
        └── Candidate
            └── Session
~~~

It deliberately deferred durable identifiers, persistence, ownership leases, recovery, and
state reconciliation to Topic 04. Today, OMP conversation history, compaction summaries,
session persistence, handoff prose, task results, and artifact URLs carry context, but none is
authoritative project lifecycle state.

Topic 04 adds a small local source of truth that survives compaction, handoff, process exit,
runtime changes between Claude and Codex/OMP, and multiple linked worktrees on one machine.

## 2. Goals

The design must:

1. create durable state as soon as a task contract is accepted;
2. support multiple active tasks in one repository;
3. permit only one authoritative writer session per task;
4. bind every mutating task to a distinct authoritative worktree;
5. bind acceptance evidence to an exact scoped candidate identity;
6. detect workspace, revision, ownership, and evidence drift before consequential actions;
7. make handoff a checked ownership transition rather than trusted prose;
8. keep raw output transient and promote only acceptance-relevant, sanitized evidence;
9. work through one deterministic core used by both Claude and Codex/OMP adapters;
10. remain local and untracked by Git; and
11. fail closed at authority and acceptance boundaries without blocking harmless read-only
    recovery.

## 3. Non-goals

Topic 04 does not:

- store or forward a conversation transcript;
- store chain-of-thought or hidden reasoning;
- replace Git or retain restorable copies of candidate source code;
- define task-packet/result overlays, which belong to Topic 06;
- replace OMP compaction, which belongs to Topic 07;
- choose the final hook, skill, or command roster, which belongs to Topic 08;
- redefine review concerns or severity, which belong to Topic 09;
- finish the broader security/failure matrix, which belongs to Topic 10;
- decide promotion statistics, which belong to Topic 11;
- implement cross-machine or multi-user synchronization;
- create, delete, merge, or prune Git worktrees; or
- execute verification commands found in state.

## 4. Grounded Runtime Facts

The design consumes these source-backed facts:

- OMP handoff generates model-authored text, creates a successor session, and injects the text
  into that session. The text is not structurally validated lifecycle state.
- OMP artifacts are session-scoped. Subagents may adopt the parent artifact manager, but the
  artifact directory follows the owning session rather than the project lifecycle.
- Native artifact references can therefore carry bulky output within a runtime session tree,
  but cannot serve as portable task authority.
- The pinned source checkout is oh-my-pi 17.2.10 at
  3a8591a8af5b6d200088d12ca75a5517cb064fa8, while the currently installed CLI reports
  17.2.12. Every selected adapter attachment point must be reprobed on the installed version
  before implementation.
- A linked worktree in this repository and the main worktree both resolve to the same absolute
  Git common directory. This validates the proposed local sharing point for the current
  environment, but adapter sandbox access still requires an explicit capability test.

## 5. Approved Decision

~~~yaml
topic: durable-task-state-candidate-handoff-offload
decision: local-file-bundle-with-deterministic-state-tool
status: approved
rationale:
  - one user works on one machine
  - Git history must not be polluted by operational task state
  - multiple active tasks still need shared local coordination across linked worktrees
  - Claude and Codex/OMP must consume one authority rather than runtime-specific memory
benefits:
  - inspectable and recoverable local records
  - candidate-bound evidence
  - explicit writer ownership and handoff
  - no model call for state transitions
tradeoffs:
  - local state disappears when the repository metadata is deleted
  - file locking and schema migration must be implemented correctly
  - no cross-machine synchronization
failure_modes:
  - stale lock
  - inaccessible Git common directory
  - workspace drift
  - incomplete candidate manifest
  - missing or stale evidence artifact
  - direct filesystem mutation outside the state tool
fallback:
  - read-only inspection and explicit reconciliation
  - no transcript-as-authority fallback
~~~

## 6. Authority Location

### 6.1 Git repository

Resolve the absolute path returned by:

~~~text
git rev-parse --git-common-dir
~~~

The state root is:

~~~text
<absolute-git-common-dir>/agent-tasks/
~~~

This location is:

- shared by the main worktree and linked worktrees;
- local to the repository;
- absent from commits and normal Git status; and
- removed if the repository metadata itself is deleted.

The state tool must never infer this path by appending to a worktree-local .git path. In a
linked worktree, .git is commonly a file. The resolved common directory is authoritative.

### 6.2 Non-Git project

The fallback root is:

~~~text
<project-root>/.agent-tasks/
~~~

The tool creates a nested .gitignore that ignores every other entry in the fallback root. A
non-Git project may have several read-only task records but only one active mutating task.

If Git is later initialized, the fallback root becomes legacy state. No further mutation is
allowed until an explicit migration validates and moves it to the resolved Git common
directory. The tool must never operate both roots as independent authorities.

### 6.3 No silent relocation

If a selected runtime cannot read and write the resolved state root, mutating task creation
fails closed. The adapter must report the capability failure. It must not silently create a
second state store in the current worktree, session directory, user home, or artifact manager.

## 7. Storage Layout

Operational records use JSON, not YAML. JSON avoids runtime-specific YAML parsers, supports
deterministic schema validation, and provides a canonical representation for hashing. Human
summaries are rendered views, not authority.

Hash inputs use one versioned canonicalization profile: UTF-8 RFC 8785 JSON Canonicalization
Scheme, with the record's own hash field excluded. A profile change requires schema migration
and new fixtures; adapters never implement a competing serializer.

~~~text
agent-tasks/
├── project/
│   ├── identity.json
│   └── state/
│       └── R000001.json
├── phases/
│   └── <phase-id>/
│       ├── contract.json
│       └── state/
│           └── R000001.json
├── tasks/
│   └── <task-id>/
│       ├── contract.json
│       ├── state/
│       │   ├── R000001.json
│       │   └── R000002.json
│       ├── sessions/
│       │   └── <session-ref>/
│       │       ├── identity.json
│       │       └── checkpoints/
│       │           └── K000001.json
│       ├── work-units/
│       │   └── <work-unit-id>/
│       │       ├── contract.json
│       │       └── outcomes/
│       │           └── O000001.json
│       ├── candidates/
│       │   └── C1.json
│       ├── evidence/
│       │   ├── task/
│       │   │   └── <evidence-id>.json
│       │   └── candidates/
│       │       └── C1/
│       │           └── <evidence-id>.json
│       ├── handoffs/
│       │   └── <handoff-id>.json
│       └── artifacts/
│           └── <sha256>.<extension>
├── locks/
└── trash/
~~~

There is no global task index. Listing and identity resolution scan validated task directories
and the recoverable trash namespace, rejecting duplicate IDs. This avoids a second mutable
summary that can drift from task authority.

### 7.1 Immutable materialized revisions

Current project, phase, and task state is the highest contiguous valid revision in its state
directory. Every revision:

- is a full materialized state document, not an event needing a reducer;
- has a monotonically increasing revision number;
- names the previous revision and SHA-256;
- is written to a temporary file, flushed, and atomically renamed to a previously nonexistent
  final revision path; and
- is never modified after publication.

This avoids relying on overwrite semantics and retains enough history to recover from an
interrupted write. Temporary files are ignored during recovery. A gap, malformed revision, or
broken hash chain produces reconcile_required rather than selecting a lower-confidence state.

Timestamps are diagnostic only. Revision and hash order are authoritative.

### 7.2 Immutability of supporting records

Identity files, contracts, checkpoints, work-unit contracts/outcomes, candidates, evidence,
handoffs, and content-addressed artifacts are immutable after publication. Lifecycle changes
are expressed by a new project/phase/task state revision or a new linked record; they never
rewrite an earlier record in place. Temporary unpublished files are not authority.

A supporting record becomes lifecycle-effective only when a valid state revision references
its exact hash. If a crash leaves a published but unreferenced record, it is an inert orphan:
status reports it for reconciliation, and its mere presence never implies a transition.

## 8. Identity Model

Identifiers are opaque, filesystem-safe, and unique within their parent:

- project_id: generated once for the state root;
- phase_id: stable and optional for ordinary standalone tasks;
- task_id: T-<date>-<short-slug>-<random-suffix>;
- candidate_id: C1, C2, and so on within a lineage;
- session_ref: adapter-provided opaque reference or core-generated local reference;
- work_unit_id, evidence_id, and handoff_id: opaque local identifiers.

Branch names, session filenames, conversation titles, and timestamps are provenance, never
identity.

## 9. Project and Phase State

project/identity.json records:

- schema version;
- project ID;
- canonical repository/common-directory identity;
- created time; and
- state-tool version that initialized the root.

Project state must not duplicate an active-task list. That list is derived by scanning task
records.

A phase is optional. Its immutable contract records the program objective, authority, required
task relationships, and phase-level exit obligations. Phase state records its current status
and accepted dependency graph. Task completion does not silently close a phase. An explicit
phase transition scans linked task authority under a phase lock.

V1 is single-repository. Cross-repository work uses linked tasks, one authority root per
repository. A multi-repository transaction is deferred until a real requirement exists.

## 10. Task Contract and Lifecycle

Clarification happens before a task cycle and does not create state.

When the objective, scope/authority, mandatory acceptance criteria, and required
verification/review obligations are accepted, the tool holds the repository coordination lock
and:

1. allocates the task ID and prepares an unpublished temporary task bundle;
2. writes immutable contract.json with stable AC IDs;
3. binds the task to a read-only or mutating execution mode;
4. binds a mutating task to its authoritative worktree, or records the observation worktree for
   a read-only task when one is used;
5. captures the applicable authoritative or observation baseline;
6. writes the session identity and first state revision with authority-state ownership; and
7. flushes the bundle and atomically renames it to the previously nonexistent final task path.

For a mutating task, that owner also holds the authoritative integration writer lease. For a
read-only task, ownership permits lifecycle recording but never grants source-write permission
or reserves a worktree for mutation.

No task mutation may begin before these steps succeed.

Task terminals remain:

- accepted;
- cancelled; and
- terminally_blocked.

waiting_for_user, recoverable blocked, partial, rework, candidate_frozen, verifying,
reviewing, transferring, and reconcile_required are nonterminal.

A material contract change never edits contract.json. It opens a linked task with a new
contract hash. Clarification within the locked meaning may be recorded without changing the
contract.

If later evidence proves that an accepted candidate violated its original contract, the
accepted history remains. A new state revision marks its current validity invalidated and
links a remediation task.

## 11. Worktree and Write Ownership

### 11.1 Authoritative integration worktree

Each active mutating task has exactly one authoritative integration worktree. Its binding
records:

- canonical worktree root;
- worktree-specific Git directory identity;
- Git common directory identity;
- branch or detached-HEAD provenance;
- baseline HEAD and baseline workspace manifest; and
- declared write scope.

The baseline manifest captures exact pre-task state for the declared scope, including
pre-existing tracked changes and relevant untracked paths. This lets candidate discovery
distinguish task output from an already-dirty worktree instead of pretending baseline HEAD is
the whole baseline.

Two active mutating tasks may not bind the same authoritative worktree.

Read-only tasks may share a worktree. Before a read-only task becomes mutating, it must acquire
an unclaimed authoritative worktree and capture a fresh baseline.

### 11.2 Subordinate isolated worktrees

Temporary worktrees created for an isolated Worker or competing exploration are subordinate
execution surfaces. They do not own task state and cannot accept the parent task. Their result
must be integrated into the authoritative worktree before candidate freeze.

One writer per task refers to authority-state and authoritative integration ownership. A
delegated Worker may receive a scoped permit to produce provisional changes only in its
subordinate worktree, but it cannot claim the task lease, edit task authority, mutate the
authoritative integration worktree, or accept the task. Only the lease owner may reconcile and
integrate that provisional output. Scouts and Reviewers remain read-only.

### 11.3 Overlapping task scopes

At create/bind time, the tool compares canonical declared write scopes across active mutating
tasks. A definite overlap is rejected. An ambiguous glob/prefix overlap requires explicit user
resolution. An override must record:

- the conflicting task IDs;
- the overlapping paths;
- why concurrency is still authorized; and
- the integration order.

Separate worktrees prevent immediate filesystem collision but do not eliminate later merge or
integration conflict, so an overlap cannot be silently accepted.

## 12. Writer Lease and Concurrency Control

Writer ownership is a consistency lease, not a security boundary. Direct filesystem access can
bypass it; adapters and later hooks may enforce more, while candidate re-hashing detects drift.

The lease records:

- owner session_ref and runtime;
- execution mode and worktree binding, authoritative only for a mutating task;
- lease generation;
- acquired time;
- status: active, transferring, released, or recovery_required; and
- optional predecessor/handoff reference.

There is no heartbeat TTL. Long model calls must not look like dead sessions.

Task bootstrap runs under the repository coordination lock and publishes its initial revision
and lease together via the atomically renamed task directory. After bootstrap, every task
mutation supplies:

- expected task revision;
- expected revision SHA-256;
- expected lease generation; and
- owner session_ref.

Project and phase mutations use the same expected-revision and expected-hash discipline with
their applicable authority; they do not pretend to share a task's writer lease.

Locks have explicit domains:

- a repository coordination lock protects task creation, authoritative-worktree reservation,
  cross-task scope checks/overrides, archive/restore, and other cross-task invariants;
- a phase lock protects a phase transition and its dependency scan; and
- a task lock protects one task's revision chain and supporting-record publication.

An operation that needs more than one domain acquires locks only in the fixed order repository,
phase, task and releases them in reverse order. Multiple locks in one domain are acquired by
canonical ID order. It must never acquire a broader lock while holding a narrower one.
Worktree/scope availability is rescanned while the repository lock is held, preventing two
concurrent task creations from both accepting the same apparently-free resource. A phase exit
holds its phase lock plus the sorted linked-task locks while validating exit obligations, so a
task cannot change underneath the decision.

Within the required lock scope, the operation rechecks all expectations, publishes supporting
records, writes one new revision, and releases the lock. Last-write-wins and automatic field
merge are forbidden.

A lock left after process death never expires automatically. Explicit recovery validates the
record, confirms no operation is active, records user-authorized takeover, and removes or
supersedes the stale lock.

## 13. Session State and Checkpoints

A session has an immutable identity record and immutable checkpoint records. Dynamic ownership
and the reference to the latest successful checkpoint live in task-state revisions rather than
an overwritten session file. Together they contain only:

- session_ref and runtime;
- task ID and candidate lineage;
- worktree binding;
- predecessor/successor references;
- ownership status;
- last successful checkpoint reference;
- current work-unit ID, if any;
- compact next action, blockers, and open risks; and
- start/end timestamps.

It contains no transcript or reasoning.

Mandatory checkpoints occur at:

- task creation;
- worktree bind/rebind;
- candidate freeze or invalidation;
- accepted evidence recording;
- ownership transfer;
- terminal transition; and
- acceptance invalidation.

Selective recovery checkpoints occur:

- after a complete work unit;
- before compaction;
- before handoff or session switch;
- before session stop; and
- before waiting for the user.

Do not checkpoint after every tool call.

Failure at an authority checkpoint fails closed. Failure at a best-effort context checkpoint
does not replace compaction with a second compactor; the next consequential action must first
reconcile workspace and authority state.

## 14. Candidate Snapshot

### 14.1 Candidate meaning

A candidate is a scoped immutable identity manifest, not a source-code backup. Git remains
responsible for code restoration and history.

Each candidate record contains:

- task contract hash;
- candidate lineage and sequence;
- authoritative worktree/baseline identity;
- owned_outputs;
- acceptance_inputs;
- canonical manifest hash;
- freeze time and state revision; and
- integration/work-unit provenance.

### 14.2 Output completeness

The model does not supply the final owned_outputs list.

At freeze, the state tool compares the authoritative worktree with the captured baseline and
automatically enumerates:

- modified tracked files;
- added and untracked nonignored files;
- every declared owned output, even when ignored or currently absent;
- deleted files;
- file-type and executable-mode changes;
- symlink targets without following an escape outside the worktree; and
- Gitlink/submodule identity when applicable.

Every discovered change must be inside declared scope or have an explicit scope disposition.
An unexplained change blocks freeze.

Ignored paths are not searched globally. Any ignored output that matters to acceptance must be
declared, after which it is hashed regardless of ignore status. A dirty nested repository or
submodule blocks freeze by default. V1 may consume a submodule only at an explicit Gitlink
commit identity; changing its contents requires a separately bound task in that repository and
integration of the resulting Gitlink change.

### 14.3 Acceptance inputs

The Tech Lead declares unchanged inputs whose bytes or identity affect acceptance, such as:

- schema or API contracts;
- relevant config;
- lockfiles;
- integration boundaries;
- dependency/version manifests; and
- generated interface baselines.

The tool can validate and hash declared inputs, but it cannot prove that the declaration is
semantically complete. Verification and review must treat missing dependency coverage as a
possible contract defect rather than claiming a whole-world snapshot.

### 14.4 Canonical hash

Candidate identity hashes canonical JSON containing:

- contract hash;
- baseline identity;
- sorted normalized paths;
- path role: owned_output or acceptance_input;
- exact-byte SHA-256 or explicit absent marker;
- file type/mode metadata; and
- integration lineage.

Paths use repository-relative forward-slash notation in records. Comparison follows the
filesystem's case rules while preserving display case.

No candidate source blobs are copied into agent-tasks automatically. This avoids creating a
second VCS and retaining secrets that were later removed from the worktree.

## 15. Candidate Drift and Evidence Isolation

The state tool re-hashes the selected manifest:

- before and after verification;
- before and after review;
- immediately before acceptance;
- before ownership handoff is accepted; and
- before resume or takeover permits mutation.

If the hash differs:

1. preserve the old candidate and evidence as history;
2. mark the candidate stale in a new task-state revision;
3. enter rework or reconcile_required;
4. forbid old evidence from acceptance; and
5. create C2 only when the changed workspace is frozen again.

Quality operations that themselves mutate a candidate invalidate their own evidence. Ignored
cache/output files outside the manifest do not matter unless the contract makes them
acceptance inputs.

The design cannot make hashing the mutable workspace and recording acceptance one filesystem
transaction. Acceptance therefore names the frozen byte identity. Later ordinary development
does not rewrite historical acceptance; only evidence that the original candidate violated its
contract invalidates that historical decision.

## 16. Evidence Records

Evidence is immutable after publication and records:

- evidence ID and type;
- task contract hash;
- candidate hash when candidate-bound;
- covered AC IDs;
- producer/session/runtime;
- command or source reference as data;
- observed status and decisive output;
- observation time;
- validity triggers;
- environment fingerprint fields, if applicable;
- promoted artifact path and SHA-256, if any; and
- lineage/predecessor references known at publication.

Later supersession or invalidation is recorded in a new task-state revision or linked immutable
record, never by editing old evidence. The core tool records evidence but does not execute
task-provided commands.

Each evidence type defines its allowed producer class and observation method. The core can
validate provenance, bindings, and hashes, but cannot make an arbitrary model assertion true.
A model-authored status alone cannot substitute for required command, review, external-source,
or user-authority evidence.

Validity is typed:

- test and review evidence bind to candidate and declared inputs;
- user authority binds to contract hash and authority scope;
- provider/environment evidence binds to an allowlisted, secret-free environment fingerprint;
- current external facts require a source identity and explicit expiry or fresh-at-acceptance
  rule; and
- no arbitrary global TTL applies to all evidence.

Evidence stays as history after invalidation. It simply stops satisfying acceptance.

Acceptance requires:

- current candidate hash still matches;
- every mandatory AC has valid evidence;
- required verification and review obligations are satisfied;
- promoted artifacts referenced by acceptance exist and match their hashes;
- no blocking finding, scope conflict, ownership conflict, or authority gap remains; and
- the state revision and lease still match.

## 17. Handoff and Takeover

### 17.1 Normal handoff

Handoff is a two-phase ownership transition:

1. predecessor writes a mandatory checkpoint;
2. predecessor creates an immutable handoff record and changes the lease to transferring;
3. successor reads authority state and actual workspace;
4. successor validates contract, worktree, state revision, and candidate/evidence hashes when
   a candidate exists; otherwise it reconciles the baseline and current scoped workspace;
5. successor accepts the transfer in a new state revision; and
6. predecessor becomes read-only.

The handoff projection contains:

- task ID and authority path;
- state revision/hash;
- contract hash;
- candidate/lineage identity;
- worktree binding;
- ownership transfer ID;
- last completed work unit;
- compact open risks/blockers; and
- next action.

It contains no transcript. Generated handoff prose may accompany the projection but cannot
alter it or satisfy acceptance.

### 17.2 Crash recovery

There is no automatic takeover. A successor:

1. observes an active/transferring owner that cannot complete handoff;
2. reports the exact state and workspace boundary;
3. receives explicit user authorization;
4. records a recovery/takeover handoff;
5. revalidates workspace and candidate/evidence;
6. invalidates any unbound or uncertain evidence; and
7. receives a new lease generation.

Recovery never resets, deletes, reverts, or discards work automatically.

## 18. Offload and Artifact Lifecycle

### 18.1 Transient tier

Raw bulky output remains in:

- the OMP artifact manager when available;
- runtime-owned temporary artifacts; or
- an explicitly task-scoped scratch path such as .task/<task-id>/ for a retained,
  non-isolated worktree.

These are context/offload mechanisms only. artifact://, a session file, or .task/ is never
durable lifecycle authority.

### 18.2 Promoted tier

Only material needed for acceptance or handoff is promoted into:

~~~text
tasks/<task-id>/artifacts/<sha256>.<extension>
~~~

Promotion:

- requires the owning session and expected revision;
- confines source and destination paths;
- copies compact, selected evidence rather than an entire raw transcript;
- applies the defined redaction/secret checks;
- records exact content hash and metadata; and
- fails evidence recording if the artifact cannot be validated.

Schema validation does not make free-form content trusted. Promoted text remains untrusted
data.

### 18.3 Cleanup

At task terminal:

- task-owned scratch may be marked eligible for cleanup;
- OMP/runtime artifacts remain runtime-owned;
- promoted evidence and terminal state remain local unless an explicit cleanup action is
  approved.

cleanup is dry-run by default. Applying cleanup to an exact terminal task moves its bundle to
agent-tasks/trash rather than deleting it. Trash is a recoverable archive: task IDs and
historical references remain resolvable there. Active, transferring, reconcile_required, or
tasks required by a nonterminal dependency cannot be archived. restore reverses the move under
the repository coordination lock. Permanent purge is a separate, exact-target, explicitly
confirmed operation, refuses live references by default, and never deletes a Git worktree.

## 19. Deterministic Core Tool

The core owns all state mutations. Models and adapters never edit authority JSON directly.

Its conceptual operations are:

~~~text
init-project
create-phase
transition-phase
create-task
bind-worktree
claim
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
cleanup --dry-run
cleanup --apply
restore
purge --confirm <exact-task-id>
recover-lock
migrate
~~~

The final CLI spelling is an implementation detail. Every operation accepts structured input
and emits machine-readable JSON plus a compact human summary.

The core:

- reads Git metadata and hashes files;
- validates schemas, ownership, revisions, locks, paths, and artifacts;
- never creates/deletes/merges worktrees;
- never executes a command stored in task state;
- never calls a model;
- never stores credentials; and
- never silently changes storage root or capability contract.

## 20. Runtime Adapters

Claude and Codex/OMP adapters are thin:

- establish an opaque session_ref;
- call the core at lifecycle boundaries;
- inject a compact state projection when needed;
- surface fail-closed errors;
- never implement a second state reducer; and
- never turn a model summary into authority.

The OMP adapter may later use verified session_start, session_before_switch, session_switch,
session_before_compact, session_stop, and related events. Those attachment points must be
probed on installed OMP 17.2.12 first.

If an adapter is unavailable, the Tech Lead may call the same core explicitly. If the core or
authority root is unavailable, a mutating task cannot proceed. Read-only diagnosis may
continue.

Detailed hook/skill/command ownership remains Topic 08.

## 21. Security and Privacy Boundaries

State must never contain:

- secret values, API keys, credentials, or credential-store contents;
- raw .env content;
- full transcripts or terminal histories;
- hidden reasoning;
- unbounded provider output; or
- executable instructions treated as trusted authority.

All paths are canonicalized. Path traversal, unsafe symlink/reparse resolution, duplicate
case-folded paths, and writes outside the selected state root are rejected.

Environment fingerprints use allowlisted names and safe version/availability facts, never
secret values.

The state tool provides consistency and validation, not protection against a local user or
process with direct filesystem permissions. Runtime tool permissions and broader trust policy
remain Topic 10.

## 22. Failure Matrix

| Failure | Required behavior |
|---|---|
| State root unavailable | Mutating task creation/transition fails closed |
| Installed adapter cannot reach Git common dir | Report capability failure; no second store |
| State schema newer than tool | Read-only status; require explicit migration/tool update |
| Interrupted write | Ignore temp; select highest contiguous valid immutable revision |
| Broken revision chain | reconcile_required |
| Operation lock already held | Stop; no timeout takeover |
| Stale lock after crash | Explicit user-authorized recovery |
| Expected revision/lease mismatch | Reject write; reload and reconcile |
| Worktree missing or rebound | recovery_required; explicit rebind |
| Active task write scopes overlap | Refuse unless explicit recorded override |
| Concurrent task reservations race | Serialize and rescan under repository lock |
| Undeclared worktree change at freeze | Refuse freeze |
| Dirty nested repository/submodule | Refuse freeze until separately reconciled |
| Candidate drift | Preserve history; invalidate acceptance-bearing evidence |
| Quality command mutates candidate | Evidence invalid; freeze next candidate |
| Promoted artifact missing/hash mismatch | Evidence invalid |
| Handoff state mismatch | Do not transfer ownership |
| Material contract change | Linked new task |
| Optional checkpoint failure | Reconcile before next consequential action |
| State command text contains an instruction | Treat as data; never auto-execute |
| Repository metadata deleted | Local state is lost; documented limitation |

## 23. Verification Strategy

### L0 — Static and schema

- every record type has a closed schema;
- canonical JSON and hash fixtures;
- invalid status transitions;
- missing/duplicate IDs;
- path traversal and case-collision fixtures;
- secret-shaped-value rejection fixtures;
- immutable-record mutation controls; and
- no transcript or raw-history fields.

### L1 — Repository and worktree discovery

- main and linked worktrees resolve one common state root;
- worktree-specific and common Git identities are distinguished;
- detached HEAD, branch switch, missing worktree, submodule, and non-Git fallback;
- adapter read/write capability from the actual sandbox; and
- installed OMP 17.2.12 lifecycle-event probe.

### L2 — Deterministic core behavior

- create multiple independent tasks;
- reject shared authoritative worktree ownership;
- detect overlapping write scopes;
- revision race and stale operation lock;
- concurrent authoritative-worktree and write-scope reservation;
- interrupted write and corrupted revision chain;
- tracked, untracked, deleted, mode-changed, symlink, and Gitlink manifest entries;
- declared ignored outputs and dirty nested-repository rejection;
- unexplained diff rejection;
- typed evidence validity;
- missing/mismatched promoted artifact;
- handoff and user-authorized takeover;
- task terminal and acceptance invalidation;
- safe archive, restore, and exact-target purge behavior; and
- schema migration with backup.

### L3/L4 — Behavioral adapters

- Quick task creates minimal state without a model-only classification turn;
- Standard and Orchestrated consume the same state core;
- Worker/Reviewer cannot write task authority;
- compaction preserves lifecycle identity;
- handoff successor must reconcile before mutation;
- candidate C1 evidence fails after mutation and C2 succeeds after refreeze;
- two concurrent tasks in separate worktrees do not invalidate one another;
- a direct out-of-band edit is caught at the next quality boundary; and
- adapter/core failure prevents false acceptance.

The core test suite requires no model calls. Behavioral runtime coverage uses the smallest
matrix needed to prove attachment and lifecycle behavior.

## 24. Success Criteria

Topic 04 is implemented only when:

1. local authority is shared across linked worktrees without entering Git history;
2. every accepted task contract creates state before mutation;
3. multiple active tasks are supported with one authority/integration writer lease and one
   authoritative worktree each;
4. state writes are revision-checked, lock-protected, immutable, and recoverable;
5. candidate manifests cannot omit unexplained worktree changes;
6. evidence cannot transfer across candidate or validity-trigger drift;
7. handoff/takeover cannot silently transfer stale ownership;
8. raw artifacts never become implicit authority;
9. cleanup is explicit and recoverable by default;
10. Claude and Codex/OMP consume one deterministic core contract;
11. failure at an authority boundary cannot produce acceptance; and
12. canonical specs, phases, template artifacts, docs, and validators project one meaning.

## 25. Impact Map for the Later Implementation Plan

### Authority

- Add the accepted Topic 04 decision to spec/key/04-decision-log.md.
- Project the durable-state gene into spec/key/01-dna.md.
- Reconcile task-cycle/candidate accounting in spec/key/03-token-quality-model.md.

### Direct specs

- spec/04-workflow-sizing.md
- spec/05-context-and-token-model.md
- spec/08-isolation-and-concurrency.md
- spec/13-validation-and-evaluation.md
- spec/15-security-and-failure-recovery.md
- spec/16-migration-plan.md
- spec/README.md

Topic 06, 07, 08, 09, 10, 11, and 12 retain their named ownership boundaries. Topic 04 may add
consumer requirements but must not pre-decide their detailed designs.

### Phase projections

- Phase 02 consumes task/candidate/work-unit authority.
- Phase 03 consumes checkpoint, handoff, and offload boundaries.
- Phase 05 later owns installation/rollback of core files and adapters.
- Phase 06 owns deterministic and behavioral lifecycle fixtures.
- Phase 07 owns release reconciliation and known limitations.

### Runtime/template candidates

- versioned JSON schemas for project, phase, task revision, session, work unit, candidate,
  evidence, and handoff;
- one deterministic state core;
- focused validator/mutation suite;
- thin runtime adapters only after their capability probes; and
- local state documentation and cleanup guidance.

## 26. Supersession and Reconciliation

This design:

- implements the durable mechanism deferred by Topic 02 without changing Topic 02 lifecycle
  meanings;
- retains .task/ as transient scratch rather than lifecycle authority;
- retains OMP artifacts as session/runtime offload rather than project authority;
- rejects the old research inference that no separate state store may exist, because Topic 04
  now gives the store an explicit deterministic consumer and attachment contract;
- does not make OpenSpec change folders or a session transcript the task source of truth; and
- does not require Git commits for candidate freeze or state retention.

## 27. Known Limitations and Implementation Gates

- Local state is not synchronized or backed up across machines.
- Deleting repository metadata deletes the state root.
- Manifest completeness for acceptance_inputs remains a semantic responsibility; deterministic
  tooling can prove declared bytes, not discover every hidden dependency.
- Writer leases are consistency guards, not filesystem security.
- Direct external edits are detected at boundaries rather than prevented continuously.
- Candidate manifests identify exact bytes but do not reconstruct old source.
- Installed OMP 17.2.12 and the selected Claude environment must pass capability probes before
  adapter implementation.
- Exact implementation language is plan-level, provided it supports canonical JSON, safe
  cross-process locking, atomic non-overwriting writes, path confinement, and both runtime
  adapters without duplicated state logic.
