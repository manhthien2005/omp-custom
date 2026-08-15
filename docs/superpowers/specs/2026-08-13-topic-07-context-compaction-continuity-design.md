# Topic 07 — Safe Context Compaction and Continuity Design

**Status:** approved by the user on 2026-08-13

**Decision:** disable automatic semantic compaction and expose one protected /safe-compact command
that invokes native context-full through OMP's soft path

**Storage policy:** local working-tree documentation; no commit, push, branch, worktree, or PR is
authorized

## 1. Purpose

Topic 07 defines how a long-running managed OMP task may reduce provider context without silently
losing the task identity, objective, mandatory acceptance criteria, authority boundaries, or
decisions that must survive the reduction.

The selected v1 path uses OMP's native context-full summarizer through an explicit command. It does
not build a second compaction engine. Automatic semantic compaction is disabled because the
currently supported OMP versions can enter a rescue-shake path before the cancellable compaction
hook. That rescue may rewrite content even when its recovery artifact cannot be saved.

Topic 07 therefore protects only an explicit, validated /safe-compact transaction. Compaction
remains a local session optimization. It does not replace Topic 04 task state, create a handoff,
accept a candidate, or authorize a new task.

OMP task subagents inherit the parent compaction settings through an isolated settings snapshot.
They therefore also run with automatic semantic compaction disabled. A bounded subagent does not
own the root task and cannot invoke /safe-compact; at context pressure it aborts into Topic 06's
failed/partial result path so the Tech Lead can narrow, re-dispatch, or work inline.

## 2. Approved Decision

~~~yaml
topic: 07-safe-context-compaction-continuity
decision: explicit_safe_compact_over_native_context_full
status: approved
rationale:
  - the manual native context-full path reaches a cancellable pre-compaction hook
  - the one-off soft mode disables remote-compaction endpoints for the selected transaction
  - durable Topic 04 state remains authoritative after transcript reduction
  - direct post-compaction kernel injection protects critical facts from summary variance
  - automatic context-full cannot be called lossless because its dead-end rescue may shake first
benefits:
  - failed task-state or recovery validation stops before semantic compaction
  - normal compact requests cannot bypass the managed transaction
  - no automatic retry or continuation can duplicate work
  - the portable validation core can later be reused by a Claude adapter
tradeoffs:
  - the user or Tech Lead explicitly invokes /safe-compact
  - the command consumes one native summarization transaction
  - automatic rescue is replaced by a stop-and-reconcile flow
failure_modes:
  - invalid or ambiguous task ownership refuses the command
  - missing critical kernel fields refuses every workflow class
  - invalid post-compaction identity blocks the next provider request
  - unsupported or non-persisted sessions refuse the managed path
fallback:
  - continue normally while below the pressure threshold
  - invoke /safe-compact when the guard reports context pressure
  - use an explicit Topic 04 handoff/new session if safe compaction cannot prepare
  - use bare OMP only with an explicit understanding that Topic 07 guarantees no longer apply
evaluation_only:
  - automatic context-full
  - shake
  - snapcompact
  - remote compaction
  - custom compaction engines
affected_topics:
  - Topic 02 workflow entry and workflow classification
  - Topic 04 durable task state and recovery
  - Topic 06 boundary packets, which remain separate from the continuity kernel
  - Topic 08 runtime adapter and command ownership
  - Topic 10 failure recovery and trust boundaries
  - Topic 11 compaction evaluation and promotion
  - Topic 12 installation and rollback
~~~

## 3. Verified Runtime Constraints

The attachment points below were checked against the clean pinned OMP source at
3a8591a8af5b6d200088d12ca75a5517cb064fa8 (17.2.10) and confirmed present on the supported
17.2.12 source line before this design was approved.

| Runtime fact | Design consequence |
|---|---|
| compaction.enabled and strategy=off prevent automatic threshold, overflow, incomplete, idle, and mid-turn semantic compaction | Managed v1 can keep automatic semantic compaction disabled. |
| An extension command can call ctx.compact with mode=soft | /safe-compact can force one local context-full transaction while the global automatic strategy remains off. |
| The soft one-off mode overrides strategy to context-full and remoteEnabled to false | The selected command cannot silently choose snapcompact or a remote-compaction endpoint. It may still call the configured model provider. |
| Manual compact prepares the cut point before session_before_compact and returns without mutation when preparation is unavailable | An uncompactable session fails before the protected transaction rewrites context. |
| session_before_compact may return cancel | Only a nonce opened by /safe-compact is allowed to enter native compaction. |
| session.compacting accepts added context, prompt text, and preserveData | The canonical kernel and epoch identity can accompany native summarization. |
| session_compact exposes the persisted compaction entry | The adapter can validate the completed transaction. |
| context runs before provider context is assembled | The first normal request after compaction can receive a fresh authoritative kernel. |
| before_agent_start, turn_end, and before_provider_request are available | The adapter can keep automatic maintenance disabled and stop model work at context pressure boundaries. |
| Extension handler exceptions and timeouts are reported but swallowed | Throwing is diagnostic only; unsafe paths must explicitly cancel or abort. |
| --no-session creates an in-memory session | The managed launcher must reject it because persisted recovery cannot be proven. |
| Native context-full appends a compaction entry; it does not destructively shake prior messages | The persisted session history remains the primary recovery surface. |
| Native shake catches artifact-write failure and still rewrites content to a bare placeholder | Shake cannot satisfy the managed lossless contract. |
| Automatic context-full may invoke rescue shake before session_before_compact when no normal preparation exists | Automatic context-full is also outside the v1 lossless contract. |

The runtime evidence is anchored in:

- _research/upstreams/oh-my-pi/packages/coding-agent/src/config/settings-schema.ts;
- _research/upstreams/oh-my-pi/packages/coding-agent/src/session/compact-modes.ts;
- _research/upstreams/oh-my-pi/packages/coding-agent/src/session/session-maintenance.ts;
- _research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/shared-events.ts;
- _research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/extensions/types.ts;
- _research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/extensions/runner.ts;
- _research/upstreams/oh-my-pi/packages/coding-agent/src/session/agent-session.ts;
- _research/upstreams/oh-my-pi/packages/coding-agent/src/session/session-manager.ts; and
- _research/upstreams/oh-my-pi/packages/agent/src/compaction/compaction.ts.

These are read-only runtime authorities, not Topic 07 implementation targets.

## 4. Authority and Invariants

| Object | Authority | Purpose |
|---|---|---|
| Topic 04 task contract and task-state revision | durable authority | Defines the task, workflow class, ownership, CAS lineage, and locked decisions. |
| Topic 04 checkpoint, candidate, and evidence records | durable authority | Defines current work, blockers, risks, candidate identity, and evidence identity. |
| Topic 07 continuity kernel | bounded projection | Carries only authoritative facts required after context reduction. |
| Native OMP compaction entry | session observation | Records the summary and Topic 07 epoch metadata; it never becomes task authority. |
| Topic 07 recovery artifact | local recovery observation | Binds one pre-compaction branch to one validated kernel and epoch. |
| Model-generated compaction summary | convenience context | Preserves useful narrative but cannot override Topic 04 or the kernel. |

The following invariants are mandatory:

1. Compaction never changes task identity, workflow class, acceptance criteria, authority,
   ownership, candidate status, or evidence validity.
2. A kernel is generated from validated Topic 04 records, never from transcript prose or a model
   summary.
3. The adapter never asks the model to reconstruct a missing critical field.
4. A summary cannot accept work, close an obligation, or resolve a blocker.
5. The first normal provider request after a successful compaction receives one fresh kernel even
   when the summary appears to contain the same facts.
6. No raw transcript, terminal history, repository dump, hidden reasoning, or chain-of-thought is
   copied into the kernel or recovery artifact.
7. Compaction and handoff remain separate operations. /safe-compact never starts a new session or
   transfers ownership.
8. Only the extension command may authorize one compaction transaction. Built-in /compact,
   programmatic compact calls from other extensions, and automatic compaction are refused.
9. A subagent pressure abort is never accepted as a successful Topic 06 result.

## 5. Scope

### In scope

- a portable canonical continuity-kernel schema, linter, serializer, and hash function;
- backward-compatible Topic 04 task-revision fields for workflow class and locked decisions;
- an exact-current-session, read-only Topic 04 kernel projection;
- one trusted OMP continuity adapter owning /safe-compact and the relevant lifecycle hooks;
- a managed settings overlay that disables automatic semantic compaction;
- a context-pressure guard that stops normal provider work before the usable window is exhausted;
- explicit bounded-subagent pressure behavior compatible with Topic 06 result validation;
- pre-compaction recovery metadata, summarizer context, post-compaction validation, and one-time
  kernel injection;
- managed-launcher persistence and unsupported-flag checks;
- local metrics needed by Topic 11; and
- focused, deterministic, model-free tests of the selected attachment points.

### Out of scope

- a custom summarizer or second compaction engine;
- automatic semantic compaction or automatic continuation;
- automatic shake, snapcompact, handoff, context promotion, or remote compaction;
- changing Topic 03 model routing;
- using compaction to create or classify a task;
- storing sessions or recovery artifacts in Git, cloud storage, or another machine;
- universal prevention of commands executed through bare or unsupported OMP entry points;
- semantic-quality benchmarking or promotion of another strategy before Topic 11; and
- restoring a full transcript from model-generated prose.

## 6. Architecture

~~~text
Normal managed provider cycle
  -> native per-turn superseded-read/useless-result pruning
  -> Topic 07 pressure check
       -> below threshold: continue
       -> at/above threshold: abort before provider dispatch
                            show /safe-compact or handoff instruction

/safe-compact
  -> require idle persisted managed session
  -> require no pending message/async delivery
  -> read exact current-session Topic 04 projection
  -> validate ownership, CAS, workflow class, and kernel
  -> save and verify local recovery artifact
  -> open single-use nonce/epoch
  -> ctx.compact({ mode: "soft" })
       -> native preparation
       -> session_before_compact validates nonce and re-reads Topic 04
       -> session.compacting supplies kernel plus preserveData
       -> native local context-full summary
       -> native persisted compaction entry
       -> session_compact validates epoch
  -> return control to the user without automatic continuation

Next normal prompt
  -> context re-reads Topic 04
  -> validate epoch and task revision
  -> inject exactly one fresh kernel
  -> before_provider_request final guard
  -> provider request

Bounded task subagent
  -> inherits automatic-compaction-off settings
  -> no root task ownership and no authorized /safe-compact transaction
  -> below pressure threshold: continue bounded work
  -> at/above threshold: abort to failed/partial Topic 06 result
                         parent narrows/re-dispatches or works inline
~~~

The implementation has four bounded units:

1. **Portable continuity core** — dependency-light JavaScript containing the closed schema,
   canonical serialization, hashing, field classification, pressure-threshold calculation, and
   workflow-specific validation.
2. **Topic 04 projection operation** — a read-only operation that finds the active task owned by
   the supplied session reference and returns exactly one closed projection.
3. **OMP continuity adapter** — owns /safe-compact, the authorization nonce, lifecycle hooks,
   recovery artifacts, kernel injection, explicit aborts, and metrics. It is the final trusted
   extension in load and handler order.
4. **Managed launch/install layer** — installs and hashes the trusted adapter, applies the final
   settings overlay, rejects unsupported persistence flags, and validates supported OMP versions.

The core must not import OMP. The OMP adapter translates runtime events into portable-core inputs.
A future Claude adapter may use the same core with different lifecycle hooks.

## 7. Managed Runtime Profile

The final managed overlay must produce this effective policy:

~~~yaml
contextPromotion:
  enabled: false

compaction:
  enabled: false
  strategy: off
  midTurnEnabled: false
  thresholdPercent: -1
  thresholdTokens: -1
  keepRecentTokens: 20000
  autoContinue: false
  idleEnabled: false
  remoteEnabled: false
  remoteStreamingV2Enabled: false
  supersedeReads: true
  dropUseless: true
~~~

compaction.reserveTokens remains unset. The portable pressure guard mirrors OMP's default
context-window-aware threshold:

1. proportional reserve = max(1, floor(contextWindow × 0.15));
2. default reserve = max(proportional reserve, 16384);
3. if the default reserve would leave no practical small-window budget, use the proportional
   reserve;
4. pressure threshold = contextWindow minus the resolved reserve, clamped below the full window.

The source-attachment test freezes this formula to the supported OMP versions. A source change
requires review rather than silently retaining a stale threshold.

The managed overlay is appended after caller-provided config overlays. At session start,
before_agent_start, turn_end, and before_provider_request, the trusted adapter must read and
reassert the load-bearing disabled settings. If the runtime does not expose the required settings
surface, managed startup fails.

All caller-selected extensions and the Topic 06 agent-boundary extension load before the Topic 07
continuity adapter. The launcher verifies Topic 07 is last. This makes its settings check and its
compaction-hook result the final trusted decision at each boundary. An unprovable or changed order
fails startup.

Topic 07 is the sole managed owner of session.compacting. An earlier extension may cancel a
transaction, which safely stops /safe-compact. Any earlier non-cancelling customization is
intentionally replaced by Topic 07's final kernel/preserveData result. No extension may load after
Topic 07 and override that result.

This repeated guard matters because OMP permits in-process settings mutation. before_agent_start
runs before native pre-prompt maintenance, and turn_end runs before mid-turn or agent-end
maintenance. These are the two boundaries at which an unsafe automatic path could otherwise be
re-enabled.

Native per-turn superseded-read and contextually-useless-result pruning remains enabled. This pass
runs before OMP's automatic-compaction enabled gate. Topic 07 does not claim the later threshold
prune pass runs while automatic compaction is disabled.

OMP createSubagentSettings copies all effective parent settings into an isolated child Settings
instance. The disabled profile therefore applies to Cheap Scout, Worker, and Reviewer sessions as
well as the main session. Topic 07 does not silently re-enable a risky compactor in those children.
Their work units are bounded by Topic 06; an overflow-pressure abort is returned as an invalid or
partial boundary result, never accepted as completion. Cheap Scout follows its existing Lead
fallback; Worker or Reviewer work is narrowed/re-dispatched or completed inline by the Tech Lead.

/safe-compact explicitly calls mode=soft. That one-off mode selects context-full and disables the
separate remote-compaction endpoint without changing the global disabled profile. The native
summarizer still uses OMP's configured model/provider and may try its existing bounded compaction
candidate chain within the same transaction. Topic 07 adds no retry loop. keepRecentTokens=20000
applies to this native semantic compaction. It is not an auto-shake protected region.

## 8. Durable State Additions

Topic 04 remains the reducer and storage authority. Topic 07 adds two backward-compatible fields to
task_state_revision:

~~~json
{
  "workflow_class": "standard",
  "locked_decisions": [
    {
      "decision_id": "D-001",
      "statement": "Use explicit safe context-full compaction for managed v1.",
      "authority_ref": "user:2026-08-13"
    }
  ]
}
~~~

workflow_class is exactly quick, standard, or orchestrated. Topic 02 selects it; Topic 07 only
reads it. It changes only through an explicit CAS reclassification operation carrying the expected
task revision plus a non-empty authority and reason reference. The compaction adapter never infers
it from prompt text, agent count, model, or command name.

locked_decisions is a bounded canonical array. Each row contains exactly decision_id, statement,
and authority_ref. It contains no transcript excerpts or hidden reasoning. Replacing it is an
explicit CAS operation, not a checkpoint side effect.

New task revisions require both fields; an empty locked_decisions array is valid. Existing v1 task
records remain readable. Before their first /safe-compact transaction, they require one explicit
CAS classification that also initializes locked_decisions. No migration guesses the workflow
class.

## 9. Continuity Kernel

The read-only Topic 04 operation returns exactly this closed semantic shape:

~~~json
{
  "schema_version": 1,
  "record_type": "context_continuity_kernel",
  "task": {
    "task_id": "T000001",
    "workflow_class": "standard",
    "objective": "...",
    "authority": [],
    "execution_mode": "mutating",
    "write_scope": [],
    "acceptance_criteria": [],
    "obligations": [],
    "locked_decisions": []
  },
  "lifecycle": {
    "status": "active",
    "owner_session_ref": "...",
    "owner_runtime": "omp",
    "revision": 4,
    "revision_id": "...",
    "revision_sha256": "...",
    "lease_generation": 1
  },
  "checkpoint": {
    "checkpoint_id": null,
    "checkpoint_sha256": null,
    "work_unit_id": null,
    "next_action": null,
    "blockers": [],
    "open_risks": []
  },
  "candidate": {
    "candidate_id": null,
    "candidate_hash": null,
    "candidate_sha256": null
  },
  "evidence_bindings": [],
  "degraded_fields": [],
  "kernel_sha256": "..."
}
~~~

kernel_sha256 is computed over canonical JSON with only kernel_sha256 omitted.

The operation accepts no caller-provided task ID. It receives the trusted current session reference
through the existing Topic 04 request envelope, filters active task revisions by
owner_session_ref, and returns exactly one result. Zero or multiple matches are errors once the
continuity gate is armed.

The serialized kernel has a hard 16 KiB limit. Every list and string also receives a fixed
implementation-time bound in the schema. A bound violation is a contract failure; content is never
silently truncated. Raw evidence is excluded. evidence_bindings contains stable evidence IDs and
record hashes only.

## 10. Workflow-Specific Validation

Critical fields required for every workflow class are:

- task ID and exact current-session ownership;
- workflow class;
- objective;
- mandatory acceptance criteria;
- authority, execution mode, and write scope;
- obligations;
- task revision and lease identity; and
- every locked decision.

Loss, ambiguity, invalid hashes, or truncation of a critical field refuses Quick, Standard, and
Orchestrated equally.

Secondary fields are:

- checkpoint ID and hash;
- current work-unit ID;
- next action;
- blockers and open risks;
- candidate identity and hash; and
- evidence bindings.

An explicit null or empty array from valid authoritative state is not loss.

- **Quick** may compact when a secondary field is unavailable only if degraded_fields names that
  exact field, the remaining kernel validates, and the adapter records the degradation. It never
  invents a substitute.
- **Standard and Orchestrated** require every applicable secondary field. Any named degradation
  refuses the command.

Quick never loses task purpose or acceptance conditions merely to save tokens.

## 11. Session Modes, Bootstrap, and Arming

The adapter determines its session mode lazily before the first provider request. OMP appends a
session_init entry carrying the agent/work-unit contract to task subagent sessions before their
first prompt.

- A session with a valid subagent session_init entry enters bounded_subagent mode.
- A main session without such an entry starts in bootstrap_unarmed.
- A malformed or ambiguous session identity fails closed before model dispatch.

Topic 02 may create the root task only after accepting the first workflow prompt, so a task is not
required at main-session process startup.

The continuity gate arms when exactly one active task owned by the current persisted session
becomes visible. Once armed, zero or multiple owned active tasks blocks normal provider work until
Topic 04 is reconciled.

/safe-compact always requires an armed gate. It never compacts an authority-free bootstrap
transcript. Its handler refuses bounded_subagent mode even if OMP exposes the registered command in
that headless session.

## 12. The /safe-compact Transaction

### 12.1 Command contract

/safe-compact accepts no arguments in v1. Arbitrary focus text is rejected so caller prose cannot
override the canonical kernel or summarizer contract.

The command refuses unless:

- the managed extension and effective disabled profile validate;
- the adapter is in armed main-session mode, not bounded_subagent mode;
- the session has a real session file and filesystem-backed artifact directory;
- the runtime is idle;
- no pending user messages, running async jobs, queued async deliveries, or other compaction exists;
- the continuity gate is armed;
- exactly one active task belongs to the current session; and
- no earlier Topic 07 epoch is pending, summarizing, invalid, or awaiting injection.

The command is single-flight.

### 12.2 Preflight and recovery artifact

The command:

1. reads and validates the exact-session Topic 04 projection;
2. creates and validates the canonical kernel;
3. captures stable session ID, session file, leaf entry ID, ordered branch entry IDs, task revision
   hash, and kernel hash;
4. writes a local recovery artifact containing those identities plus the canonical kernel;
5. verifies that saveArtifact returned an ID, getArtifactPath resolves to a real file under the
   session artifact directory, and the saved bytes hash correctly; and
6. opens a random single-use authorization nonce bound to the epoch, task revision, kernel,
   recovery artifact, branch identity, and expiration time.

The artifact does not copy transcript messages. Native context-full preserves prior session entries
and appends a compaction entry, so the persisted session remains the transcript recovery surface.

Any preflight failure leaves global compaction disabled and returns without calling ctx.compact.

### 12.3 Native invocation

After preflight, the command calls:

~~~javascript
await ctx.compact({
  mode: "soft",
  onComplete,
  onError
});
~~~

The adapter state changes from authorized to summarizing only through session_before_compact.

session_before_compact allows the call only when:

- one unexpired nonce exists;
- the current branch identity still matches preflight;
- Topic 04 still returns the same task ID, owner, lease generation, revision ID, revision hash, and
  kernel hash; and
- the native preparation describes a real context-full cut.

On the authorized path, the final Topic 07 handler returns an explicit empty allow result. This
overwrites any earlier extension-provided custom compaction result without replacing native
context-full behavior. On every unauthorized path it returns cancel=true.

Therefore built-in /compact and compact calls from another extension are cancelled unless they are
the exact in-flight /safe-compact transaction. Automatic compaction is prevented by the disabled
settings and boundary reassertion; this hook is not represented as protection against OMP's
pre-hook automatic rescue-shake branch.

### 12.4 Summarizer augmentation

session.compacting supplies:

- a concise instruction that the model must preserve useful work context without contradicting
  the authoritative kernel;
- the canonical kernel as additional summarization context; and
- namespaced preserveData with schema version, epoch ID, nonce hash, task ID, task revision hash,
  kernel hash, branch identity, and recovery artifact ID.

The raw nonce is never stored in preserveData or metrics. The full kernel is not duplicated inside
preserveData.

### 12.5 Completion

session_compact requires the persisted entry to carry the exact pending preserveData identity.
It then re-reads Topic 04:

- if task identity and revision are unchanged, the epoch becomes awaiting_injection;
- if the authoritative revision changed during summarization, the epoch becomes invalid and the
  next normal provider request is blocked pending reconciliation.

onError or any command exception clears the authorization nonce, marks the epoch failed, and
records a bounded reason. It does not retry.

The command returns control to the user after success. It sends no hidden continuation and starts
no agent turn.

## 13. First Request After Compaction

On the next normal context event, the adapter:

1. re-reads the exact-session Topic 04 projection;
2. validates the awaiting_injection epoch against the current task revision;
3. creates a fresh canonical kernel;
4. injects one clearly delimited hidden custom message containing that kernel; and
5. marks the epoch injected for this provider-request generation.

A request-local hash sentinel prevents duplicate injection. The persisted summary is not parsed to
decide whether injection is necessary.

before_provider_request requires a successful injection whenever an epoch awaits it. After that
guard passes, the epoch becomes consumed. If the request is aborted before dispatch, injection
remains pending for the next normal request.

There is no automatic continuation. The user's next prompt naturally consumes the epoch.

## 14. Context-Pressure Guard

Automatic compaction is replaced by a stop-before-dispatch guard.

At before_agent_start, turn_end, and before_provider_request, the adapter computes current usage
against the frozen threshold formula in Section 7.

- Below the threshold, normal work continues.
- At or above the threshold, a normal provider request is explicitly aborted and the user sees a
  short instruction to run /safe-compact or perform an explicit Topic 04 handoff.
- While one authorized /safe-compact summary request is in the summarizing state, the pressure
  guard allows the native compaction provider call. No ordinary agent request can run concurrently
  because the command is single-flight and requires an idle session.

The final provider-boundary abort is a promotion gate, not an assumption. Focused model-free
canaries must prove that ctx.abort prevents provider dispatch on both supported OMP versions.
Until those canaries pass, the adapter is not installable as the managed default.

For a bounded_subagent session, the same threshold aborts the child run. The Topic 06 wrapper must
classify the resulting aborted/partial native details as an unsuccessful receipt. The parent does
not receive a plausible success payload and does not automatically retry. Cheap Scout uses the
already-approved Lead fallback; Worker/Reviewer recovery is an explicit Tech Lead decision.

If one oversized recent turn leaves native preparation unavailable, /safe-compact fails without
mutation. The correct fallback is an explicit Topic 04 recovery/handoff or user-directed cleanup,
not rescue shake.

## 15. Failure Semantics

| Failure | Required behavior |
|---|---|
| Recovery artifact cannot be written or verified | Refuse before ctx.compact; preserve current context. |
| Session is in-memory | Refuse and explain that managed continuity requires persistence. |
| Runtime is busy or has pending async delivery | Refuse; retry only after it is idle. |
| No task during bootstrap | Refuse /safe-compact and require task initialization or explicit handoff. |
| Subagent reaches pressure threshold | Abort child run; Topic 06 returns failed/partial and refuses acceptance. |
| Zero or multiple owned tasks after arming | Abort normal work and require Topic 04 reconciliation. |
| Critical kernel field missing | Refuse every workflow class. |
| Secondary field missing in Quick | Proceed only with an explicit named degradation. |
| Secondary field missing in Standard/Orchestrated | Refuse. |
| Task revision changes before native compaction starts | Cancel in session_before_compact. |
| Task revision changes during summarization | Mark invalid and block the next normal request. |
| Native preparation is unavailable | Return without mutation; do not invoke rescue shake. |
| Native compaction transaction exhausts its configured candidate chain | Topic 07 adds no retry; clear nonce and leave the original branch authoritative. |
| preserveData or epoch identity mismatches | Mark invalid, abort, and require recovery. |
| Effective auto-maintenance settings drift | Reassert the disabled profile and record the drift; refuse startup if reassertion is unavailable. |
| Handler throws or times out | Treat as failure; never infer cancellation or success from the thrown error. |
| Pressure guard cannot prove provider dispatch was stopped | Do not promote/install the adapter. |
| Context remains too large after one safe compaction | Stop and require explicit handoff or user action. |

Topic 07 never rolls back task state, changes candidate status, repeats a side effect, or adds its
own model retry. OMP's bounded compaction-candidate attempts remain inside the single native
transaction and are recorded as runtime behavior.

## 16. Unsupported Compaction Paths

### Automatic context-full

Disabled. OMP can invoke aggressive rescue shake before the cancellable hook when no normal
compaction preparation exists.

### Shake

Disabled and unsupported for protected tasks. Current OMP may rewrite eligible content even when
its recovery artifact cannot be persisted.

The adapter consumes ordinary interactive /shake input where the input hook runs. Some direct
built-in routes can bypass that hook. Such deliberate or unsupported invocations are outside the
managed lossless guarantee. If a shake placeholder is detected afterward, the adapter blocks
further provider work but does not claim it can reverse the rewrite.

### Built-in /compact

session_before_compact cancels it because it lacks a /safe-compact nonce. Users must use
/safe-compact.

### Snapcompact

Evaluation-only. Topic 07 does not enable visual archive frames or inline tool-result imaging.

### Handoff

Automatic handoff is disabled. A handoff is an explicit Topic 04 ownership transition, not a
compaction fallback.

### Remote or custom compaction

Not selected. They require separate privacy, provenance, semantic-retention, and rollback evidence.

## 17. Managed Launcher and Installation

The supported path is the template-managed launcher. It must:

1. validate component manifests and hashes before starting OMP;
2. install the continuity core, adapter, and managed overlay from trusted template files;
3. append trusted extensions and the overlay after caller-provided extension/config flags, with
   the Topic 07 continuity adapter as the final extension;
4. reject attempts to replace or disable required trusted components;
5. reject --no-session only when it occurs in the OMP option region before the literal -- prompt
   separator;
6. validate the installed OMP version against the component manifest; and
7. record the resolved persisted session file and artifact directory in local runtime evidence.

Text containing --no-session after the prompt separator is prompt text and must not be rejected.

Running bare OMP remains possible because the user owns the machine. It is outside the managed
guarantee and must be disclosed rather than represented as prevented.

Sessions, recovery artifacts, and metrics stay local. No Git operation is required for continuity,
and no session content is added to the repository by default.

## 18. Metrics

Topic 07 emits bounded local observations without prompt or transcript bodies:

- runtime and component version;
- hashed session, task, and epoch identities;
- workflow class;
- context tokens, context window, and resolved pressure threshold;
- kernel byte size and hash;
- recovery artifact success or failure;
- native preparation and compaction status;
- observed compaction candidate/fallback outcome when exposed by OMP;
- pre/post validation result and named failure code;
- degraded-field names;
- one-time kernel-injection status;
- settings-drift observations; and
- whether a provider request was allowed or aborted.

These observations support Topic 11. They do not become task evidence automatically and cannot
accept a candidate.

## 19. Deterministic Verification

Implementation verification is focused and model-free:

1. **Portable core tests** — canonicalization, hash exclusion, closed fields, size/list bounds,
   threshold formula, critical-field rejection, and workflow degradation rules.
2. **Topic 04 projection tests** — exact-session filtering, zero/multiple-task refusal, ownership
   and revision validation, old-task classification, and absence of arbitrary task-ID reads.
3. **Command transaction tests** — idle/persistence gates, artifact verification, nonce
   single-use/expiry, branch and CAS races, main-session-only eligibility, exact mode=soft
   invocation, and no Topic 07 retry after terminal native failure.
4. **Lifecycle adapter tests** — unauthorized compact cancellation, earlier custom-result
   neutralization, preserveData binding, post-compaction mismatch, one-time kernel injection,
   settings drift, swallowed handler failures, and zero automatic continuations.
5. **Pressure-guard canaries** — normal request blocked at threshold, safe compaction summary
   allowed, subagent pressure becomes an unsuccessful Topic 06 receipt, no provider process
   started after abort, and both supported OMP versions covered.
6. **Launcher/install tests** — Topic 07-last trusted ordering, version support, overlay identity,
   --no-session parsing before --, uninstall/rollback, and bare-path disclosure.
7. **Source attachment gate** — static assertions for manual soft compact, cancellable hooks,
   per-turn pruning, automatic rescue shake, and artifact-failure behavior.

No live model call, agent spawn, semantic benchmark, or exhaustive repository audit is required for
these deterministic contracts. Topic 11 later compares retained quality and token cost on
representative long-context fixtures.

## 20. Implementation Impact Map

The implementation plan may change only these surfaces unless a newly discovered dependency is
documented before editing:

- Topic 04 state schema, reducer operations, protocol, manifest, and focused tests for
  workflow_class, locked_decisions, and the read-only continuity projection;
- a new portable Topic 07 core/schema under template/.omp/contracts/;
- a new trusted continuity extension under template/.omp/extensions/;
- the final managed runtime overlay and managed launcher;
- template component manifests and installer/uninstaller component maps;
- focused Topic 07 validators, fixtures, and local current-product evidence;
- user documentation for /safe-compact, pressure handling, unsupported commands, installation,
  recovery, and rollback; and
- the active authority/spec/phase/registry/changelog surfaces named by the implementation plan.

Topic 06's task wrapper is not the continuity adapter and must not absorb this lifecycle. Agent
packets never become continuity authority.

## 21. Migration and Rollback

Migration order:

1. add backward-compatible state fields and the read-only projection;
2. add and verify the portable continuity core;
3. add the command/adapter and deterministic lifecycle tests;
4. add the disabled overlay, launcher guards, component hashes, and installation tests;
5. explicitly classify any old active task before its first /safe-compact;
6. capture focused current-product evidence; and
7. reconcile active specs, phases, documentation, registry dispositions, and the Topic 07
   changelog.

Rollback removes the continuity adapter and its managed settings component through the installer
manifest, restores the prior launcher component set, and leaves durable state records readable.
Optional Topic 07 fields are preserved rather than destructively deleted. After rollback, no Topic
07 continuity guarantee may be claimed.

## 22. Acceptance Criteria

Topic 07 implementation is complete only when:

1. automatic semantic compaction, context promotion, idle compaction, automatic continuation, and
   remote compaction are effectively disabled;
2. native per-turn superseded-read and useless-result pruning remains enabled;
3. /safe-compact accepts no arguments and runs only in an idle persisted managed session;
4. a failed recovery-artifact write or verification returns before ctx.compact;
5. /safe-compact invokes exactly one native mode=soft transaction;
6. every compact call without the command's valid nonce is cancelled;
7. --no-session is rejected as an option but accepted as text after --;
8. exactly one current-session active task is required after the continuity gate arms;
9. new task revisions carry an explicit workflow class and bounded locked decisions;
10. old tasks remain readable but cannot compact until explicitly classified through CAS;
11. the kernel is closed, canonical, hashed, bounded, and excludes prohibited content;
12. every workflow rejects missing critical fields;
13. only Quick may explicitly tolerate missing secondary fields;
14. pre-compaction identity is bound into namespaced preserveData;
15. a branch or task-revision race cancels or invalidates the transaction;
16. the first valid normal post-compaction request receives exactly one fresh kernel;
17. Topic 07 schedules no continuation and adds no retry outside the single native compaction
    transaction;
18. pressure guard canaries prove no normal provider dispatch at or above the threshold;
19. a bounded subagent inherits the disabled profile, cannot invoke /safe-compact, and produces an
    unsuccessful Topic 06 receipt at context pressure;
20. automatic context-full, shake, snapcompact, and automatic handoff remain unselected;
21. installation proves the Topic 07 adapter is the final extension and validates all managed
    component identities;
22. rollback validates the restored component set; and
23. documentation discloses bare OMP and unsupported direct shake routes.

## 23. Known Limitations and Promotion Gates

- Native semantic summaries can be imperfect. Direct authoritative kernel injection, not summary
  prose, protects load-bearing continuity.
- OMP does not expose a universal cancellable pre-shake hook. Shake cannot be promoted until an
  atomic/cancellable seam exists or Topic 11 explicitly accepts a weaker risk contract.
- Local persistence protects this machine and retained workspace only. Cross-machine continuity
  requires a future storage decision.
- The installed runtime is newer than the pinned audit source. Both versions remain supported only
  while source sentinels and focused canaries pass.
- A single oversized recent turn may be uncompactable. The system stops rather than destructively
  rescuing it.
- A bounded subagent cannot compact in v1. Long work units must be narrowed or handled inline;
  Topic 11 may evaluate a safe child-session continuity contract later.
- No alternative compaction strategy is promoted by intuition. Topic 11 must compare quality,
  critical-field retention, total and premium tokens, rework, and accepted-outcome rate against
  this stable baseline.

The written design contains no open implementation choice. Any implementation discovery that
weakens a fail-closed guarantee reopens this design before code proceeds.
