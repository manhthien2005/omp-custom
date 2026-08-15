# Architecture — Current Topic 03 Runtime

<!-- round09-12-projection:release-readiness -->
## Round 09–12 control plane

The quality, security, evaluation, and release-readiness round adds no agent and no second
orchestrator. Versioned fixtures feed a closed deterministic evaluator. Any future campaign is a
separate, explicitly authorized process boundary whose task-cycle evidence must reconcile with
Topic 04 candidate, source, review, and acceptance identity before it can affect promotion.

The deterministic path starts zero provider/model processes and returns exactly one of
`PROMOTE_EFFICIENCY`, `PROMOTE_QUALITY`, `REJECT`, or `DEFER_INCONCLUSIVE`. Critical or important
findings block acceptance; minor findings remain notes. Independent review is selected by risk,
not represented by a permanent Verifier or an unconditional Reviewer spawn.

Packaging remains outside the installed runtime: evaluation fixtures, runner, results, and
evidence are repository/operator surfaces and never enter installed `.omp`. The current adapter
states are OMP `IMPLEMENTED_NOT_PROMOTED` and Claude `DESIGNED_NOT_VERIFIED`.

<!-- topic08-projection:behavior-core -->
Topic 08 adds no second orchestrator. `behavior-manifest.json` selects portable behavior and the
OMP extension maps it to native discovery, tools, and hooks. Worker alone autoloads completion
evidence; lifecycle bootstrap is explicit and mutation requires managed state. External tools
provide capability only. Claude remains a non-installable design mapping.

<!-- topic05-doc:architecture -->
Topic 05 adds a capability, not another role or runtime: actor selection (Lead/Scout/Reviewer) and
retrieval selection (native/CodeGraph) are independent. The optional adapter is default-off,
worktree-local, bound to Topic 04 candidate/source identity, and always falls back explicitly to
native evidence. Details: [`retrieval.md`](retrieval.md).

## Design constraints

1. OMP is the sole coding-agent runtime and orchestration engine.
2. OmniRoute is the sole model gateway for configured model roles.
3. Plain requests enter the main-session Tech Lead; the default is inline work with no spawn.
4. A spawn requires a named benefit, bounded contract, result consumer, stop condition, fallback,
   and effective capability preflight.
5. Fresh verification and final acceptance stay with the Tech Lead.
6. No provider credential or user-owned model catalog is stored in this repository.
7. Durable lifecycle authority is local, immutable, and outside both Git history and model
   conversation memory.

## Installed surface

```text
template/.omp/
├── config.yml                 selected role aliases, Scout-only fallback, effort gate
├── AGENTS.md                  main-session constitution and orchestration boundary
├── RULES.md                   sticky critical invariants
├── agents/
│   ├── cheap-scout.md         bounded read-only retrieval
│   ├── worker.md              one owned implementation work unit
│   └── reviewer.md            independent risk-selected review
├── commands/
│   ├── quick.md               explicit narrow inline-first adapter
│   ├── standard.md            one integrated implementation lane
│   └── orchestrated.md        structural work-unit and integration adapter
├── skills/                    lazy-loaded project skills
├── contracts/                 portable Topic 06 schema/core/CLI and managed overlay
├── extensions/               trusted same-name task wrapper plus final continuity adapter
├── bin/omp-managed.ps1        supported managed OMP launcher
└── state/                     deterministic lifecycle core, schemas, protocol

docs/roles/tech-lead.md        main-session role reference; not OMP agent discovery input
docs/policies/                 human-only routing, quality, and context references
```

OMP discovers exactly three custom agents. The Tech Lead is intentionally absent from
`template/.omp/agents/`: it is the active main session, not another child session.

Historical `.omp/schemas` files are not installed or runtime authority. Selected agent `output:`
contracts plus the Topic 06 executable schema/core enforce boundary shapes.

## Managed agent boundary

The launcher loads the trusted wrapper last, with the closed overlay last. The wrapper composes a
role-minimal Topic 04 work-unit projection, delegates to native OMP `task`, validates the settled
result and exact model/effort identity, and records a provisional outcome. It does not own
worktrees, integration, verification, or acceptance. Bare OMP/Vibe/`eval` output is unmanaged.

See [`agent-boundaries.md`](agent-boundaries.md) for the operator contract.

## Managed context continuity

The final trusted extension reasserts an exact disabled automatic-compaction profile. Once the
persisted main session owns exactly one Topic 04 task, argument-free `/safe-compact` verifies the
current task revision/lease, branch, local session file, and a newly written recovery artifact,
then authorizes one native soft context-full transaction. The next normal prompt receives one
canonical kernel exactly once; the summary and kernel never replace Topic 04 authority.

The provider boundary aborts normal work at context pressure. Main-session recovery is one
`/safe-compact` attempt or explicit Topic 04 handoff. A bounded child cannot compact and settles as
failed/partial without automatic retry. Built-in `/compact`, direct `shake`, snapcompact,
automatic/remote compaction, automatic handoff, and bare OMP are unmanaged. OmniRoute/model routing
is a separate layer and is unchanged. See [`context-continuity.md`](context-continuity.md).

## Durable authority boundary

The installed state core is shared explicitly by Claude and Codex/OMP. Its operational records
are never stored under the installed `.omp/state` tree: Git repositories resolve
`<absolute-git-common-dir>/agent-tasks`, while non-Git projects resolve
`<project-root>/.agent-tasks`. The plural namespace is fixed.

One task has one authority/integration writer lease. Different mutating tasks need distinct
authoritative worktrees and non-overlapping scope reservations. A subordinate Worker worktree is
provisional and cannot accept the task. The state core derives a baseline-relative candidate
manifest from workspace bytes; that manifest is identity, not backup. Typed evidence is immutable
and bound to its exact contract, candidate, inputs, and relevant environment.

Conversation text, compaction summaries, `.task/`, and runtime artifacts remain context or raw
transport. They do not transfer ownership or become lifecycle authority. Handoff is a checked
two-phase operation, and crash takeover requires explicit user authorization. Automatic runtime
attachment remains gated on Topic 08; Topic 04 provides the deterministic manual adapter only.

## Responsibilities

| Owner | Selected when | Owns | Never substitutes for |
|---|---|---|---|
| Main-session Tech Lead | Always | Classification, inline work, dispatch decisions, integration, fresh verification, acceptance | User authority for credentials, destructive action, critical-risk acceptance, or architecture violation |
| `cheap-scout` | Bounded retrieval has clear value | Read-only search, repository mapping, compact evidence | Editing, acceptance verification, review verdicts |
| `worker` | Delegation has clear implementation value | One explicitly owned work unit; `high` normally, `xhigh` when the Tech Lead marks it hard | Final integration or acceptance |
| `reviewer` | Risk gate selects independent review | Dynamic concern profile, evidence-backed findings, fixed `xhigh` | Editing, self-merge, Tech Lead verification |

Review is mandatory for security, authentication, durable data, database migration, concurrency,
public API, and destructive-change concerns. Workflow class alone does not force review. Opus is
preferred when suitable and available, but never blocks progress. The fallback is another strong
review model or the same model in a separate session with that limitation disclosed.

## Entry and dispatch flow

```text
Plain request or command hint
            |
            v
Main-session Tech Lead validates scope, risk, and workflow shape
            |
            +--> inline execution (default)
            |
            +--> optional Cheap Scout --> Flash:max --> Pro:max --> Lead retrieval
            |
            +--> optional Worker --> high or Tech-Lead-selected xhigh
            |
            +--> risk-gated Reviewer --> xhigh
            |
            v
Tech Lead integrates, runs fresh verification, and accepts or rejects
```

`/quick` is the user's explicit light path. `/standard` and `/orchestrated` are compatibility and
advanced hints; they do not override the Tech Lead's validation. Orchestrated work requires at
least two independently verifiable work units plus one integration contract. It does not require
parallel execution or a fixed agent count.

One writer is the default. Parallel Workers are allowed only with disjoint ownership, proven
isolation/capture, and sequential integration. If those prerequisites are unavailable, the same
valid work plan runs sequentially and the Tech Lead discloses the downgrade.

## Context and result boundary

Task packets carry only objective, scope, acceptance criteria, constraints, relevant file
references, and verification commands. They do not forward the parent transcript, raw terminal
history, full repository dumps, or unrelated documentation.

Spawned results must satisfy their closed structured-output contract. The Tech Lead rejects an
invalid/overridden schema, forced partial result presented as complete, unexpected model or effort
identity, unresolved capability failure, or unverified acceptance claim.

Cheap Scout failure is fail-soft because retrieval ownership returns to the Tech Lead. This does
not turn missing semantic capability into a successful Scout result, and it never waives fresh
verification or selected review.

## Model routing

Project configuration maps:

- `cheap-scout` to `omniroute/ds/deepseek-v4-flash:xhigh`;
- Scout fallback only to `omniroute/ds/deepseek-v4-pro:xhigh`;
- `worker` and `reviewer` to the selected Codex role, with no fallback chain;
- `task.enableEffort: true` and `task.maxEffort: xhigh` for per-spawn selection.

Gateway IDs (`ds/deepseek-v4-flash`, `ds/deepseek-v4-pro`) and OMP selectors
(`omniroute/ds/...`) are different namespaces. The external `~/.omp/agent/models.yml` catalog and
OmniRoute credentials are user-owned prerequisites. The current evidence records
`ENVIRONMENT_BLOCKED` when DeepSeek credentials are absent; this invokes the Tech Lead retrieval
fallback rather than making a false provider-success claim.

## Installation and rollback

The installer is dry-run by default. Apply mode creates a timestamped full `.omp` backup, maps the
product `workflows` component to OMP's `commands` directory, installs the three selected agents,
and retires only the closed stale list (`tech-lead.md`, `explorer.md`, `implementer.md`,
`verifier.md`). Custom agents and protected model/database/credential/session files survive.

User-level installation omits global per-spawn effort settings unless
`-EnablePerSpawnEffort` is explicitly supplied. Rollback restores the pre-install tree from the
printed backup path.

## Optional specification system

Projects may use plain Markdown change folders without adding another runtime or CLI:

```text
openspec/changes/<name>/
├── proposal.md
├── design.md
├── tasks.md
└── specs/<domain>/spec.md
```

The active repository specs and key decisions remain the authority for this template itself.
