# Known Limitations and Non-Claims

## Current truthful status

These are retained limitations, not silent PASS claims:

| Item | Current disposition | Audit treatment |
|---|---|---|
| OMP adapter | `IMPLEMENTED_NOT_PROMOTED`, installable | Audit implementation and scratch proof; do not call it live-proven |
| Claude adapter | `DESIGNED_NOT_VERIFIED`, non-installable | Review mapping/static contract only; a missing runtime proof is expected |
| Model-assisted campaign | `NOT_RUN` | Verify it cannot start implicitly and cannot be replaced by deterministic evidence |
| Promotion | `DEFER_INCONCLUSIVE` | Any current promotion claim is a defect unless new separately authorized evidence exists |
| Live project install | Not performed | Scratch proof must not be described as live safety proof |
| OMP 17.2.12 scratch package | PASS, 30 assertions | Bounded package/install characterization only |
| OMP 17.2.10 runtime arm | Not locally available | Static pinned source/evidence remains; no network acquisition is allowed |
| DeepSeek provider smoke | Environment blocked by missing credential | Fallback contract must remain valid; do not use or request credentials during audit |
| CodeGraph model/provider campaign | Inconclusive/not authorized | Native retrieval remains default; CodeGraph stays optional/default-off |
| Git integration | Local dirty workspace, no stage/commit/push/PR | Audit the candidate in place; do not infer release integration |
| Operational task state | Local outside Git | Expected owner choice; audit safety and retention, not portability to another machine |

## Known current validation advisory

Fresh focused validators during packet construction reported:

| Validator | Result |
|---|---|
| Topic 02 lifecycle | 649 PASS, 0 WARN, 0 FAIL |
| Topic 03 topology/routing | 22 PASS, 0 WARN, 0 FAIL |
| Topic 04 durable state | 41 PASS, 0 WARN, 0 FAIL |
| Topic 05 retrieval | 25 PASS, 0 WARN, 0 FAIL |
| Topic 06 managed boundary | 19 PASS, 0 WARN, 0 FAIL |
| Topic 07 continuity | 22 PASS, 0 WARN, 0 FAIL |
| Topic 08 behavior core | 17 PASS, 0 WARN, 0 FAIL |
| Round 09–12 readiness | 16 PASS, 0 WARN, 0 FAIL |

Fresh full validation before packet construction reported:

```text
356 passed, 1 warning, 0 failed
```

The warning is:

```text
approx-token-budget above target (1365 > 1200): template\.omp\AGENTS.md
```

This is non-blocking in the current validator, but Claude should assess whether the extra context
creates a material quality/cost risk. Report it as a finding only with a concrete impact or a
violated active mandatory limit; otherwise retain it as an advisory.

## Workspace material that is not product authority

- `.tmp-phase00-e2/`, `.tmp-phase00-e3bg/`, and `.tmp-phase00-e3g/` are local experiment copies.
- `.claude/tmp/` and the nested `.claude/worktrees/` area are local auditor/tool remnants.
- Root `codex-*`, `opus5-*`, `omp-custom-*`, and peer-review packet/response files are historical
  review/reconciliation material unless an active decision explicitly cites a still-live claim.
- `docs/evidence/phase-00/` is immutable historical evidence for pinned runtime facts, not the
  current product manifest.
- `docs/superpowers/specs/` and `docs/superpowers/plans/` preserve approved intent and execution
  history. Unchecked design checkboxes do not by themselves reopen a completed implementation.
- `evals/results/` is ignored local campaign output and is not promotion evidence.

Claude must still check that these paths cannot be packaged, installed, committed unintentionally,
treated as authority, or used to leak secrets. It should not semantically re-audit copied trees as
if they were additional product implementations.

## Deliberate non-goals of the implemented candidate

- No second orchestrator, scheduler, model router, or worktree manager.
- No automatic use of Opus, Reviewer, Worker, Cheap Scout, or CodeGraph on every task.
- No direct provider access bypassing OmniRoute.
- No persistent repository-map artifact as a default behavior.
- No cross-repository or cross-machine task-state portability guarantee.
- No claim that schema-valid output is true, complete, verified, or accepted.
- No claim that deterministic fixtures prove real provider quality or economics.
- No automatic promotion based on a pilot, synthetic run, incomplete pair set, missing usage, or
  environment-blocked campaign.
- No live installation, Git integration, or destructive cleanup as part of this audit.

## What remains after a successful audit

An `APPROVE_PILOT` verdict authorizes no mutation by itself. The owner still selects an exact pilot
project, reviews a dry-run, explicitly approves apply, and separately authorizes any provider/model
smoke or spend. Pilot results remain non-promoting evidence until the evaluation contract's final
campaign requirements are met.
