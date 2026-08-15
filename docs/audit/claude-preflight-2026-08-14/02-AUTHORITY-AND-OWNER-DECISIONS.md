# Authority and Owner Decisions

## How to adjudicate disagreements

Use this order to decide what a file can prove. If two active surfaces conflict, report the
conflict; do not silently choose the convenient one.

1. **Explicit owner decisions and current numbered decisions define intended behavior.** The owner
   decisions below are the audit acceptance target. KD-024 through KD-032 in
   `spec/key/04-decision-log.md` record their repository projection.
2. **Active specs define the product contract.** `spec/README.md` and applicable `spec/01` through
   `spec/16` clauses must be internally coherent with current KDs.
3. **Phase files define execution/projection order.** They cannot resurrect superseded behavior or
   convert unverified work into PASS.
4. **Runtime/config/scripts implement the contract.** Their actual execution wins over comments
   describing behavior they do not perform.
5. **Registry is authoritative for machine facts; `spec/key` is authoritative for reasoning.** This
   distinction is declared by `spec/key/README.md`.
6. **Tests and evidence prove bounded observations only.** A passing test cannot override source or
   hide an untested path. Generated evidence must match its manifest and capture boundary.
7. **Designs, plans, changelogs, research, dossiers, and old review packets are provenance.** They
   explain intent and may reveal a reproducible defect, but unchecked boxes, old role names, old
   verdicts, or superseded proposals do not independently govern the current product.
8. **Pinned upstream source governs OMP runtime facts.** The clean reference is
   `_research/upstreams/oh-my-pi` at
   `3a8591a8af5b6d200088d12ca75a5517cb064fa8` when locally available. Do not fetch it if absent.

Source evidence constrains what is technically true; it does not choose product policy. Product
policy cannot claim runtime behavior contradicted by source or a valid local reproduction.

## Frozen owner decisions

### Workflow entry and lifecycle

- A plain natural-language request is normal. The user does not need to remember a prefix.
- `/quick` is an explicit light-task choice that the main-session Tech Lead validates and may
  escalate when unsafe or structurally unsuitable.
- Standard and Orchestrated selection belongs to the Tech Lead. Text without `/` is a hint, not a
  required resend.
- Reclassification is internal and preserves valid discovery/work. It does not restart the task or
  discard valid changes by default.
- Standard is one integrated implementation lane. Orchestrated requires at least two independently
  verifiable work units, an integration contract, and cross-boundary verification; parallelism,
  multiple agents, and multiple writers are optional.
- A task is one accepted objective/scope/authority/criteria/verification contract. A candidate is a
  frozen acceptance-bearing snapshot. Mutation invalidates candidate-bound evidence.

### Topology and delegation

- The main session is the Tech Lead and remains final integration/acceptance owner.
- Default is inline/no spawn. Spawn only when concrete benefit exceeds coordination cost.
- The selected spawnable manifest is exactly `cheap-scout`, `worker`, and `reviewer`.
- There is no permanent Explorer, Implementer, Verifier, or unconditional Reviewer chain.
- A failed or unavailable optional specialist falls back to the valid Tech Lead path needed by the
  task; it must not block merely because a named premium model or agent is unavailable.
- Opus is optional. Absence, quota exhaustion, or non-use of Opus is not a completion blocker and
  must have a valid fallback selected by the Tech Lead.

### Model and effort routing

- Cheap Scout is bounded, read-only, advisory retrieval.
- Primary Cheap Scout selector: `omniroute/ds/deepseek-v4-flash:xhigh`, with provider thinking
  `max` when the gateway supports that control.
- Only model fallback for Cheap Scout: `omniroute/ds/deepseek-v4-pro:xhigh`, also provider `max`.
- If both DeepSeek routes are unavailable, continue with the Tech Lead's valid retrieval contract;
  do not invent another implicit model chain.
- Worker uses `high` for moderate work and Tech-Lead-selected `xhigh` for difficult work.
- Reviewer, when selected by risk, uses exact `xhigh` and never silently downgrades.
- Tech Lead owns whether a Worker or Reviewer is useful for the task. The config supplies available
  roles; it does not force dispatch.
- Omni Router is transport/model resolution. It does not own workflow sizing, task authority,
  acceptance, review selection, or fallback policy beyond the explicit selected chain.

### Durable local state and worktrees

- The namespace is `agent-tasks` (plural).
- Git projects use `<absolute-git-common-dir>/agent-tasks`; non-Git projects use
  `<project-root>/.agent-tasks` until explicit migration.
- Operational task state remains local and outside Git history. It is not intended for machine or
  collaborator portability in this project.
- One mutating task has one authoritative integration worktree and writer lease. Different active
  mutating tasks require distinct authoritative worktrees.
- Read-only tasks may share a worktree. A subordinate isolated Worker output is provisional until
  reconciled into the authoritative worktree and candidate.
- The state core never creates, deletes, merges, or prunes Git worktrees.
- Transcripts, summaries, `.task/`, model output, and external artifact stores are not lifecycle
  authority.

### Retrieval and optional capabilities

- Native bounded retrieval is the default.
- Cheap Scout is optional and fail-soft; its failure has no lifecycle side effect.
- CodeGraph is optional, explicit, default-off, and pinned when installed. It cannot become policy,
  task authority, or an implicit network dependency.
- Selected capability contracts fail closed when a prerequisite is required for that same
  contract. Continuing requires an explicitly valid different contract, not silent degradation
  while pretending the original semantic guarantee passed.

### Managed boundary, continuity, and acceptance

- OMP remains the runtime. The managed boundary validates dispatch before native `task`, then
  validates a result receipt before lifecycle/acceptance use.
- Structured shape does not prove provenance, completeness, correct model identity, correct
  candidate, or successful tool execution.
- Partial/forced output cannot masquerade as completion.
- Compaction is an explicit safe operation over an authoritative continuity kernel; summaries do
  not replace Topic 04 state.
- A child cannot mutate parent lifecycle authority or accept the parent task.
- Review is risk-selected, fresh, candidate-bound, and independent when required. Same-model or
  non-independent review is disclosed rather than mislabeled.

### Safety, installation, and promotion

- Dry-run is the default for installation, uninstallation, cleanup, and destructive-looking
  operations. Apply requires exact target and explicit authority.
- User-owned files, credentials, sessions, model catalogs, and `.agent-tasks` state are preserved.
- No direct provider calls: OmniRoute is the only selected gateway, and provider/model campaigns
  need explicit mode, authority, positive budget, and a concrete available runtime.
- Deterministic or pilot evidence cannot promote by itself. Incomplete or unavailable campaign
  evidence yields `DEFER_INCONCLUSIVE`.
- Current OMP status is `IMPLEMENTED_NOT_PROMOTED`. Claude is
  `DESIGNED_NOT_VERIFIED/installable:false` until real runtime evidence changes it.
- No Git stage, commit, push, PR, live install, provider spend, or mandatory Opus gate is implied by
  implementation completion.

## Audit discipline

These decisions are not a request for agreement. Claude must verify that active authority and
implementation actually satisfy them. If an owner decision is technically impossible or unsafe,
report the contradiction with source/runtime evidence. Do not silently rewrite the decision, and
do not report a historical proposal as a current defect without reproducing its effect.
