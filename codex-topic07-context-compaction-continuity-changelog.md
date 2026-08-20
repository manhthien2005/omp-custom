# Topic 07 — Safe Context Compaction and Continuity Changelog

## Status

- Decision authority: KD-031 accepted.
- Implementation: complete in the local workspace.
- Promotion: `IMPLEMENTED_NOT_PROMOTED`.
- Open item: `OPEN-T07-RUNTIME-02` — recorded because no verified local OMP 17.2.10 executable was
  available for the second required stop-before-provider canary.
  No download or downgrade was attempted.
  **2026-08-20 update:** the owner provisioned their own already-installed 17.2.10
  binary into the untracked local cache `tools/runtime-cache/omp/17.2.10/omp.exe` (SHA-256
  `1525122bc49a6e5f79fb1c58b6b1916cecfcffaf2e82080769f7f0fa296bc8a6`, `omp --version` reports
  `omp/17.2.10`). Both canaries now pass from a durable path and the runtime matrix reports
  `READY_FOR_PROMOTION_CANARY` / `T07-RUNTIME-MATRIX-READY`. The canary prerequisite is therefore
  satisfied; promotion itself remains ungranted, so the status above is unchanged and this open item
  stays recorded rather than closed. Nothing was downloaded and the installed OMP was not modified.
- External provider calls: `0`. The pressure canary uses a local in-process sentinel; its control
  counter is not a network/model-provider call.
- Git policy: local workspace only. No branch, worktree, stage, commit, push, or pull request was
  created for Topic 07.

## Implemented contract

- Automatic semantic/context-promotion, idle, mid-turn, threshold, auto-continue, remote, and
  remote-streaming compaction paths are disabled in managed sessions.
- Argument-free `/safe-compact` is available only after exact Topic 04 task arming in a persisted,
  idle main OMP session.
- Every new task stores exact `workflow_class` and complete initial `locked_decisions`; legacy
  active tasks use explicit `set-continuity-contract` compare-and-swap.
- The command verifies local recovery bytes before one native
  `ctx.compact({ mode: "soft" })` transaction.
- One canonical, hash-bound Topic 04 continuity kernel is injected on the next normal prompt and
  consumed once. No hidden continuation, retry, or handoff is scheduled.
- Pressure aborts before ordinary provider entry. Bounded children fail/partial and cannot compact
  or return a plausible managed success.
- Built-in `/compact`, direct `shake`, snapcompact, automatic handoff, remote compaction, and bare
  OMP are outside the managed guarantee.
- OmniRoute/model routing and optional Opus review are separate; Opus is not required.

## Implementation surfaces

- Topic 04 state schema/reducer/projection/protocol additions for workflow class, locked decisions,
  explicit continuity classification, and read-only continuity projection.
- Portable continuity schema/core and the shared managed-state client under
  `template/.omp/contracts/`.
- Final trusted adapter at `template/.omp/extensions/context-continuity.js`.
- Manifest-coupled `agent-boundary` v2 packaging, generated runtime record, managed launcher,
  transactional installer, and rollback attribution.
- Deterministic Node/PowerShell suites under `scripts/tests/topic07-*` plus the local provider
  sentinel fixture.
- Pinned source attachment and runtime-matrix helper at
  `scripts/lib/topic07-context-continuity.ps1`.
- Operator, command, architecture, security, installation, rollback, authority, phase, and
  compatibility projections.

## Source attachment

- Pinned OMP commit: `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.
- Bounded source attachments: 15, each with normalized-LF SHA-256 and ordered structural needles.
- Supported runtime matrix: OMP 17.2.10 and 17.2.12.
- Available local canary runtime: 17.2.12 (installed).
- Available local canary runtime: 17.2.10 (untracked local cache, provisioned by the owner on
  2026-08-20). `OPEN-T07-RUNTIME-02` remains recorded above because promotion was never granted;
  the runtime availability that originally blocked the canary is resolved.

## Verification record

Task 11 captured the final local current-product evidence record. These passing checks establish
the implemented boundary; they do not override the two-version promotion blocker.

| Gate | Current result |
|---|---|
| Pinned source attachment | PASS — 15 bounded attachments; helper source-only report emitted 3 assertions |
| Installed 17.2.12 pressure/control canary | PASS — 15 assertions; pressure provider counter 0, below-threshold control counter 1 |
| External provider/network use | PASS — 0 |
| Local 17.2.10 canary | PASS (2026-08-20) — 26 assertions across 2 available runtimes from the durable local cache; was BLOCKED `OPEN-T07-RUNTIME-02` at capture time |
| Portable Node contract/adapter suite | PASS — 56 tests, 0 failed |
| State contract/projection suites | PASS — 30 + 37 assertions |
| Managed runtime suite | PASS — 49 assertions |
| Final focused validator aggregate | PASS — 22 PASS, 0 WARN, 0 FAIL |
| Final mutation suite aggregate | PASS — 22 assertions |
| Predecessor regressions | PASS — Topic 02: 649/0/0; Topic 04: 41/0/0; Topic 06: 19/0/0 |
| Final full-template regression | PASS WITH KNOWN WARNING — 308 passed, 1 existing AGENTS token-budget warning, 0 failed |
| Evidence capture | PASS — 73 hashed files, 8 command groups |
| `deterministic.json` SHA-256 | `24be311f699f8b736b46c292bc96953c529df5f4f77af173267dbf3d5c45a0bd` |
| `manifest.json` SHA-256 | `7520ba6a9ccd6ed4952f743157d80a87c8ccb4f1c24f12701be13ba203f6bd77` |

## Non-claims

- This does not claim automatic continuity on bare OMP, Vibe, `eval`, or unrelated internal-agent
  paths.
- This does not claim that direct shake can always be intercepted or reversed.
- This does not promote Topic 07 while the two-version runtime gate is incomplete.
- This does not make a summary, kernel, recovery artifact, or session transcript task authority.
- This does not require Opus, a subagent, a remote service, Git, or provider spend.
