# Claude Pre-Pilot Audit Handoff

## Purpose

This packet gives an independent Claude auditor enough context to decide whether the current
`omp-template` candidate is safe to enter a real-project pilot. The audit is a read-only review of
the repository candidate. It is not permission to install into a live project, call a provider,
change credentials, stage or commit Git content, or edit product files.

The expected output is an evidence-bound report. A finding is not accepted merely because Claude
or Codex states it. Critical and Important findings enter the two-party reconciliation protocol in
`07-CONSENSUS-LEDGER-AND-REPORT-TEMPLATE.md`.

## Candidate identity

- Repository: `D:\Dev\Projects\omp-template`
- Branch observed before packet creation: `codex/topic03-agent-topology`
- Baseline `HEAD`: `509cc43b5cbe74ba0edd25a3ab09c696c5a7e247`
- Staged paths before packet creation: `0`
- Product disposition: `IMPLEMENTED_NOT_PROMOTED`
- Claude adapter disposition: `DESIGNED_NOT_VERIFIED`, `installable: false`
- Model-assisted promotion campaign: `NOT_RUN`
- Promotion verdict: `DEFER_INCONCLUSIVE`
- Live installation performed by Topics 01–12: `false`

The exact working-tree candidate is frozen in `01-CANDIDATE-SNAPSHOT.jsonl`. The audit packet
directory itself is orchestration material and is intentionally outside the product candidate.
Claude must run the freshness check in `05-SAFE-VERIFICATION-PLAYBOOK.md` before reviewing content.
If the candidate differs, return `STALE_PACKET` and stop making acceptance claims.

## Audit objective

Answer one question:

> Does the current implementation faithfully project the accepted owner decisions through active
> decisions/specs/phases, executable behavior, tests, evidence, installation safety, and truthful
> release status strongly enough to begin a bounded real-project pilot?

The audit must establish both:

1. **Breadth:** every changed path is classified, every load-bearing concern has an audit outcome,
   and excluded/historical/scratch paths are accounted for; and
2. **Depth:** each plausible defect is followed vertically through intent, active authority,
   implementation, negative behavior, tests, and evidence until it is confirmed or falsified.

Reading every line with equal weight is not the objective. A flat exhaustive scan wastes context
and can elevate historical text over live behavior. Use the coverage matrix to guarantee breadth,
then spend depth on authority boundaries, unsafe fallbacks, false acceptance, destructive actions,
model/provider boundaries, state ownership, and install/rollback behavior.

## Mandatory read order

### Tier A — establish the candidate and desired behavior

1. This file.
2. `01-SNAPSHOT-SUMMARY.md` and `01-CANDIDATE-SNAPSHOT.jsonl`.
3. `02-AUTHORITY-AND-OWNER-DECISIONS.md`.
4. `03-CHANGE-NARRATIVE-AND-TRACEABILITY.md`.
5. `04-AUDIT-COVERAGE-MATRIX.md`.
6. `06-KNOWN-LIMITATIONS.md`.

### Tier B — inspect active authority and executable surfaces

1. `spec/key/04-decision-log.md`, especially KD-024 through KD-032.
2. `spec/README.md` and the active `spec/01` through `spec/16` files selected by the issue.
3. The applicable `spec/phases/phase-00` through `phase-07` projections.
4. `template/.omp/`, installer/uninstaller, managed extensions/tools, state core, evaluation core,
   and the focused/full validators selected by the traceability map.
5. Current-product evidence manifests and the exact records they govern.

### Tier C — consult only when an issue needs provenance

- Approved designs and implementation plans under `docs/superpowers/`.
- Topic changelogs and correction ledgers.
- `spec/key/dossiers/`, `spec/key/repos/`, `docs/research/`, old peer-review prompts/responses,
  Phase 00 raw evidence, `.claude/`, and `.tmp-phase00-*`.

Tier C material is source evidence or history unless an active authority surface explicitly imports
it. It cannot silently override a later KD, active spec, current implementation, or fresh evidence.
It can still reveal a real defect when its claim is independently reproduced against the candidate.

## Packet contents

| File | Responsibility |
|---|---|
| `01-SNAPSHOT-SUMMARY.md` | Human-readable candidate counts, classification, and snapshot rules |
| `01-CANDIDATE-SNAPSHOT.jsonl` | Exact path/status/hash inventory for the product candidate |
| `02-AUTHORITY-AND-OWNER-DECISIONS.md` | Authority order and frozen owner decisions |
| `03-CHANGE-NARRATIVE-AND-TRACEABILITY.md` | Topic 01–12 intent-to-evidence routing map |
| `04-AUDIT-COVERAGE-MATRIX.md` | Breadth contract and required adversarial probes |
| `05-SAFE-VERIFICATION-PLAYBOOK.md` | Safe commands, independent-review method, and stop conditions |
| `06-KNOWN-LIMITATIONS.md` | Honest deferrals and non-claims that are not silently converted to PASS |
| `07-CONSENSUS-LEDGER-AND-REPORT-TEMPLATE.md` | Finding schema and Claude/Codex reconciliation protocol |
| `CLAUDE-AUDIT-PROMPT.md` | Self-contained prompt to start the independent audit |
| `capture-candidate-snapshot.ps1` | Packet-local capture/verify helper; excluded from product candidate |
| `capture-candidate-snapshot.Tests.ps1` | Disposable-Git behavioral tests for capture, exclusion, and drift detection |
| `PACKET-SHA256.txt` | Integrity hashes for the handoff files, excluding itself |

## Safety boundary

Claude may read repository files, inspect Git, run deterministic validators/tests, and create one
report beneath `docs/audit/claude-preflight-2026-08-14/reports/`. Claude must not:

- modify product, authority, test, evidence, registry, or operator files;
- perform a live install/uninstall or touch a user OMP/Claude configuration;
- call OmniRoute, DeepSeek, Codex, Claude, Opus, or any other model/provider;
- acquire a missing runtime, package, dependency, or credential from the network;
- create/delete/move Git worktrees or mutate `.agent-tasks` authority;
- stage, commit, push, open a PR, clean, reset, or delete existing workspace content; or
- treat a passing Codex-authored validator as sufficient proof without source/behavior review.

When a safe proof is impossible, record the exact environmental prerequisite and classify the
claim as unverified. Do not manufacture a PASS and do not redesign unrelated areas.

## Completion rule

Claude returns one preliminary verdict:

- `APPROVE_PILOT`: no unresolved Critical or Important finding and every coverage row is closed;
- `APPROVE_WITH_NOTES`: no unresolved Critical or Important finding, with explicit Minor or
  environmental notes that do not invalidate a bounded pilot; or
- `BLOCK_PILOT`: at least one reproducible Critical/Important finding or a stale/incomplete packet
  prevents a defensible pilot decision.

This is Claude's independent verdict, not final owner acceptance. Codex must reproduce every
Critical and Important finding. Only `CONFIRMED_BY_BOTH` issues become accepted defects under this
handoff; disagreement is preserved with evidence for the owner instead of hidden or looped forever.
