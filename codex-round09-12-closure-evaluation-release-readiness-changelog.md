# Round 09–12 — Closure, Evaluation, and Release Readiness

<!-- round09-12-projection:changelog -->

## Approved decision

Topics 09–12 are one bounded implementation round. Topics 09/10 close quality and security deltas
against the Topic 03–08 baseline; Topic 11 supplies deterministic evaluation and an explicitly
authorized optional campaign boundary; Topic 12 proves package readiness in disposable projects.
No provider/model call, live installation, Git staging, commit, push, or pull request is authorized
by this round.

## Semantics changed

- Review uses `critical`, `important`, and `minor`; the first two block acceptance.
- Review evidence must bind to the current Topic 04 candidate/source identity and come from a
  separately selected independent review session when the risk gate requires it.
- There is no permanent Verifier, unconditional Reviewer, or required Opus gate. Opus is optional;
  an available suitable reviewer is the fallback.
- Secret-shaped evidence is rejected without echo. Destructive actions require explicit
  authority. Retried side effects require stable identity. Partial output cannot masquerade as
  completion.
- Promotion is exactly `PROMOTE_EFFICIENCY`, `PROMOTE_QUALITY`, `REJECT`, or
  `DEFER_INCONCLUSIVE`. Pilot/synthetic/incomplete evidence cannot promote.
- The evaluator defaults to deterministic fixtures and zero provider/model processes. Campaigns
  require explicit mode, provider authority, positive evidence budget, concrete runtime, and
  bounded local output.

## Implemented surfaces

- `scripts/lib/round09-12-evaluation-core.mjs` and its deterministic tests.
- Versioned fixtures under `evals/round09-12/` plus the safe runner and benchmark forwarder.
- Focused `R0912-*` release-readiness validation and adversarial mutation controls.
- Active quality/security/evaluation/release projections in KD-032, specs, phases, and operator
  documentation.
- Scratch-only install/discovery/repair/uninstall/rollback characterization for OMP 17.2.12.
- Transactional, bounded, hash-only current-product evidence under
  `docs/evidence/current-product/round-09-12/`.

## Current status and limitations

- OMP: `IMPLEMENTED_NOT_PROMOTED`; local 17.2.12 scratch package proof passes.
- OMP 17.2.10: not locally available; runtime arm not run.
- Claude: non-installable `DESIGNED_NOT_VERIFIED`; runtime/quota arm not run.
- Model-assisted evaluation: `NOT_RUN`; promotion remains `DEFER_INCONCLUSIVE` until separately
  authorized evidence is complete and reconciled.
- Scratch package proof is not a live install. User-owned models, sessions, credentials, and
  `.agent-tasks` remain outside evaluation ownership.
- Difficult residual questions may be handed to Opus later, but Opus review is not a completion
  dependency and no finding is hidden behind a `ready for Opus` status.

## Evidence and verification

Transactional capture settled 12 command groups with `provider_calls: 0` and
`model_processes_started: 0`. The four bounded current records are:

| Record | SHA-256 |
|---|---|
| `quality.json` | `945067857b9206e466c1f646013279a47f1d7963aaf571c5cc2e01ce3679d6c2` |
| `security.json` | `0a8103b191ab69105ca412b4afd6e1602e5ddbe8da104cf4762efaeb846b09ff` |
| `evaluation.json` | `c84d8ee833d362e70b3261357e1b96abce86d548a092c2250ca9c9dd07f1a500` |
| `release-readiness.json` | `2935a843fdd5770bf7a3b7cf018b3c3a62be19e9a2d299d01e50f7a131f79e76` |

The manifest excludes itself, hashes these four records, and hashes 35 governed implementation,
fixture, authority, phase, and operator files. Important final checkpoints:

| Command group | Result |
|---|---|
| Evaluation core tests | PASS — 15 tests |
| Review/security tests | PASS — 14 tests |
| Scratch install/discovery/repair/uninstall/rollback | PASS — 30 assertions |
| Focused-validator mutation controls | PASS — 32 assertions, 9 mutations |
| Focused Round 09–12 validator | PASS — 16/16 |
| Topic 03/04/05/06/07/08 focused validators | PASS — 22/41/25/19/22/17 |
| Full repository validator with round evidence capture skip | PASS — 356, 1 known budget warning, 0 FAIL |
| Transactional Round 09–12 capture | PASS — 12 checks, 0 provider/model processes |

No command in this round staged, committed, pushed, or opened a pull request. No live project or
user OMP target was installed; all package mutations occurred under verified system-temp roots and
were removed after the tests.
