# Topic 04 — Durable Task State, Candidate, Handoff, and Offload Changelog

## Status

`IMPLEMENTED` — the deterministic local state core, explicit Claude/Codex adapter contract,
installer integration, candidate/evidence fail-closed behavior, handoff/recovery, retention,
canonical projections, and validators are implemented. The automatic lifecycle adapter is not a
Topic 04 claim; its installed-runtime probe remains explicitly assigned to Topic 08.

```yaml
topic: 04
decision: local-file-bundle-with-deterministic-state-tool
state_namespace: agent-tasks
core_runtime: PowerShell >= 7.4
operational_state_in_git: false
automatic_adapter: not_installed_topic08_probe_required
tests:
  foundation: 74 PASS
  lifecycle: 42 PASS
  candidate: 35 PASS
  evidence: 56 PASS
  transfer_retention: 93 PASS
  installer: 70 PASS
  focused_contract: 18 PASS
  behavioral_e2e: 18 PASS
validators:
  topic02: 604 PASS / 0 WARN / 0 FAIL
  topic03: 22 PASS / 0 WARN / 0 FAIL
  topic04: 41 PASS / 0 WARN / 0 FAIL
  full: 188 PASS / 1 advisory WARN / 0 FAIL
known_limitations:
  - local-only and lost with repository metadata
  - candidate manifest is identity, not backup
  - direct external edits are detected at checked boundaries
  - automatic lifecycle attachment remains Topic 08
  - semantic acceptance-input completeness remains Tech Lead responsibility
  - leases do not protect against a local process with filesystem access
git:
  branch: codex/topic03-agent-topology
  observed_head: 509cc43b5cbe74ba0edd25a3ab09c696c5a7e247
  staged_paths_changed_by_topic04: 0
  commit_created: false
status: IMPLEMENTED
```

## Implemented behavior

- Git projects resolve one untracked authority at
  `<absolute-git-common-dir>/agent-tasks`; non-Git projects use
  `<project-root>/.agent-tasks` until explicit migration.
- Immutable JSON records, canonical hashing, locks, expected revision/hash/lease generation, and
  one non-expiring writer lease provide deterministic compare-and-swap mutation.
- Mutating tasks reserve distinct authoritative worktrees and scopes. Read-only tasks may observe
  the same worktree; subordinate Worker outputs remain provisional.
- Candidate manifests are baseline-relative byte identity, never backup. Unexplained changes fail
  freeze; candidate and acceptance-input drift invalidate acceptance-bearing evidence.
- Evidence types have closed producer, candidate, contract, input, artifact, environment, and
  validity-trigger bindings. There is no global evidence TTL.
- Handoff is a checked two-phase transfer. Crash takeover and stale-lock recovery require explicit
  user authority and reconciliation; elapsed time never transfers ownership.
- Raw `.task/` and runtime artifacts remain transient. Only bounded sanitized content-addressed
  proof can be promoted.
- Cleanup defaults to dry-run; archive moves one terminal task to recoverable trash; restore is
  exact; purge is a separate exact-ID operation. The core never manages Git worktrees.
- The installer includes the manifest-verified `state` component by default and requires
  PowerShell 7.4+. Installation and rollback preserve operational authority outside `.omp`.

## Fresh verification evidence

The final Topic 04 core matrix passed 388 assertions:

- foundation 74;
- lifecycle 42;
- candidate 35;
- evidence 56;
- transfer 44;
- retention 49;
- installer/adapter 70; and
- focused contract/mutations 18.

The focused contract validator passed `41/0/0` under both PowerShell 7.6.4 and Windows PowerShell
5.1. The mutation suite caught all 16 registered contract mutations in both editions. The full
validator passed `188/1/0`; the sole warning is the pre-existing advisory `RULES.md` lower-budget
warning (`226 < 300`). Topic 02 passed `604/0/0`, Topic 03 passed `22/0/0`, and the phase DAG
remained 9 reciprocal edges with zero failures.

A separate no-model-call E2E fixture passed 18 assertions. It created mutating and read-only tasks,
rejected a second writer on the authoritative worktree, froze C1, recorded deterministic evidence,
detected byte drift, froze C2, rejected C1 evidence for C2, recorded fresh C2 evidence, closed C2
accepted, completed a Claude-to-Codex two-phase handoff, then dry-ran, archived, and restored the
terminal task. C1 and C2 hashes differed, and every operation returned only structured result codes
and hashes.

Runtime facts observed during final verification:

- OMP `17.2.12`;
- PowerShell `7.6.4`;
- pinned OMP source `3a8591a8af5b6d200088d12ca75a5517cb064fa8`, clean;
- state component manifest: 11 files, zero hash mismatches; and
- adapter gate: manual core `SELECTED`, automatic lifecycle adapter `NOT_INSTALLED`, reason
  `TOPIC08_INSTALLED_RUNTIME_PROBE_REQUIRED`.

## Files owned by Topic 04

New implementation/evidence paths:

- `template/.omp/state/` — CLI, protocol, manifest, schema, and eight core libraries;
- `scripts/lib/topic04-test-fixtures.ps1`, `scripts/lib/topic04-durable-state.ps1`;
- `scripts/tests/topic04-state-foundation.Tests.ps1`;
- `scripts/tests/topic04-state-lifecycle.Tests.ps1`;
- `scripts/tests/topic04-state-candidate.Tests.ps1`;
- `scripts/tests/topic04-state-evidence.Tests.ps1`;
- `scripts/tests/topic04-state-transfer.Tests.ps1`;
- `scripts/tests/topic04-state-retention.Tests.ps1`;
- `scripts/tests/topic04-installer.Tests.ps1`;
- `scripts/tests/topic04-durable-state.Tests.ps1`;
- `scripts/tests/topic04-state-e2e.Tests.ps1`;
- `scripts/validate-topic04-durable-state.ps1`;
- `docs/task-state.md` and `docs/evidence/current-product/topic-04/adapter-gate.json`; and
- the accepted Topic 04 design and implementation plan under `docs/superpowers/`.

Overlapping current-product paths updated for Topic 04:

- `scripts/install-template.ps1`, `scripts/uninstall-template.ps1`, `scripts/validate-template.ps1`;
- `template/.omp/AGENTS.md` and the three command adapters;
- `README.md`, `docs/architecture.md`, `docs/workflow-v0.md`, `docs/security.md`,
  `docs/installation.md`, and `docs/rollback.md`;
- KD-028, DNA L11, the token-quality model, active specs 01/02/04/05/08/10/12–16 and
  `spec/README.md`;
- phase plans 02/03/05/06/07; and
- the Topic 03 current-product hash manifest, refreshed only for overlapping live files.

## Honest boundary and limitations

The explicit shared core is usable now by Claude and Codex/OMP. Topic 04 does not claim automatic
session-start, switch, compaction, or stop attachment. Topic 08 must probe the installed runtime and
select an attachment before making that claim; its absence does not invalidate the manual core.

Operational state is intentionally same-machine. Deleting Git metadata can delete Git-backed
authority. Candidate manifests identify bytes but do not back them up. Direct external changes are
caught at checked boundaries, not intercepted. Correct semantic acceptance-input enumeration still
requires Tech Lead judgment. Finally, locks and leases ensure consistency but cannot defend against
another local process that already has filesystem access.

## Git boundary

All work remained inline in the existing dirty worktree. No subagent, model/provider call, stage,
commit, push, or pull request was created for Topic 04. Final `git diff --check` exited 0; the only
message was the repository's existing Phase 00 CRLF advisory.
