# Prompt for Claude — Independent Pre-Pilot Audit

You are the independent senior auditor for the local repository:

`D:\Dev\Projects\omp-template`

The Codex implementation claims that the accepted Topics 01–12 design/spec/phase scope is complete
at repository level and is ready for a bounded real-project pilot, while remaining truthfully
`IMPLEMENTED_NOT_PROMOTED`. Your task is to challenge that claim deeply and efficiently.

## Authority and write boundary

Operate read-only except for one permitted output file:

`docs/audit/claude-preflight-2026-08-14/reports/claude-prepilot-audit-report.md`

Do not edit implementation, specs, phases, tests, fixtures, evidence, registries, documentation,
configuration, Git state, worktrees, task state, credentials, or user/runtime installations. Do
not stage, commit, push, clean, reset, download, install live, or call any model/provider/network
service. Do not spawn an expensive or premium reviewer automatically. If a proof needs unavailable
runtime, credentials, provider authority, network, or destructive action, record the exact blocker
and continue with safe independent checks.

## Mandatory packet

Read in order:

1. `docs/audit/claude-preflight-2026-08-14/00-START-HERE.md`
2. `01-SNAPSHOT-SUMMARY.md`
3. `01-CANDIDATE-SNAPSHOT.jsonl`
4. `02-AUTHORITY-AND-OWNER-DECISIONS.md`
5. `03-CHANGE-NARRATIVE-AND-TRACEABILITY.md`
6. `04-AUDIT-COVERAGE-MATRIX.md`
7. `05-SAFE-VERIFICATION-PLAYBOOK.md`
8. `06-KNOWN-LIMITATIONS.md`
9. `07-CONSENSUS-LEDGER-AND-REPORT-TEMPLATE.md`
10. `PACKET-SHA256.txt`

First verify packet hashes and the frozen candidate. Expected branch is
`codex/topic03-agent-topology`, expected `HEAD` is
`509cc43b5cbe74ba0edd25a3ab09c696c5a7e247`, expected staged count is zero, and the candidate
excludes only this audit packet directory. If path/status/hash identity differs, write a concise
`STALE_PACKET` report listing mismatches and stop substantive acceptance claims.

## Audit method

Do not perform an equal-depth exhaustive read of all 1,148 changed entries. Use this disciplined
method so nothing is omitted while depth goes to the risky paths:

1. **Account for breadth.** Classify every manifest entry and close all C-01 through C-24 coverage
   rows. Scratch/history still need hygiene treatment but are not duplicate product authority.
2. **Establish current authority.** Start with frozen owner decisions, KD-024 through KD-032,
   active specs/phases, runtime source facts, and current-product evidence. Treat designs/plans,
   old review packets, research, and immutable Phase 00 material as provenance unless active
   authority imports them.
3. **Trace vertical execution paths.** Follow one issue at a time from request entry and task
   contract through dispatch/model/capability preflight, native/managed execution, receipt,
   candidate/evidence binding, integration, verification/review, continuity, evaluation, and
   package/readiness.
4. **Falsify independently.** Do not trust Codex-authored validators alone. Inspect implementation
   and pinned OMP source, exercise safe negative controls in disposable copies, and verify mutation
   sentinels genuinely fail when their protected condition is removed.
5. **Follow consequences, not keywords.** Expand a finding to all active consumers of the same
   contract. Do not reopen historical wording that has no live consumer, and do not launch endless
   synonym searches after the execution/authority boundary is fully mapped.
6. **Reconcile evidence strength.** Distinguish configured intent from returned runtime identity,
   schema shape from truth/provenance, deterministic fixtures from provider quality, scratch
   installation from live operation, and implementation from promotion.

## High-risk hypotheses to challenge

At minimum, try to falsify these claims:

- A user who omits Quick/Standard/Orchestrated syntax still reaches a valid Tech-Lead-selected
  workflow without restarting or losing valid work.
- Inline is the default; only `cheap-scout`, `worker`, and `reviewer` are selected spawnables; no
  permanent Explorer/Verifier/Reviewer/Opus gate survives in an active execution path.
- Cheap Scout uses Flash xhigh/provider-max, then Pro xhigh/provider-max, then a valid Tech Lead
  retrieval path; failure does not mutate lifecycle state.
- Worker high/xhigh and Reviewer exact xhigh cannot be silently changed by role overrides, auth
  fallback, retry fallback, effort ceilings, plan-mode stripping, or returned identity mismatch.
- A selected semantic/tool contract cannot quietly degrade and then return plausible structured
  completion when LSP/server, bash, grep/glob/AST/web, schema validation, skill, or runtime
  prerequisites are unavailable.
- Wrong candidate, wrong contract, wrong producer/model, forced partial, replayed, stale, child,
  untrusted, or tool-error results cannot gain integration/acceptance authority.
- Local `agent-tasks` CAS, writer/worktree reservations, handoff, candidate freeze, evidence
  invalidation, archive/restore/purge, and retained-state boundaries fail closed safely.
- CodeGraph stays optional/default-off/pinned/worktree-local and cannot become a second authority,
  policy layer, implicit network dependency, or unsafe cleanup target.
- The managed `task` wrapper and continuity/compaction layer remain adapters over OMP, not a second
  orchestrator; pressure stops before provider entry and summaries never replace authority.
- Installation/repair/uninstall/rollback are dry-run-first, exact-target, backup-safe, transactional,
  and preserve user files, credentials, sessions, catalogs, custom components, and task state.
- Evaluation starts zero provider/model processes by default and cannot promote incomplete,
  synthetic, pilot, biased, environment-blocked, budget-exhausted, or missing-usage evidence.
- Evidence manifests/capture cannot validate stale/tampered output or overclaim Claude/live/runtime
  readiness.
- Historical, `.tmp-phase00-*`, `.claude`, raw evidence, and ignored evaluation output cannot ship,
  leak secrets, or re-enter active authority.

Also search for new root causes not listed here. The hypotheses are a floor, not a request to
confirm Codex's framing.

## Finding quality gate

For each Critical or Important finding, provide:

- one precise claim and reachable preconditions;
- current authority/invariant with file anchors;
- exact implementation/source evidence;
- a safe reproduction and negative/control result, or an explicit reason it remains unverified;
- actual acceptance/security/install/promotion impact;
- affected tests/evidence and active projection surfaces;
- minimal correction direction without editing; and
- what evidence would falsify the finding.

Deduplicate by root cause. Do not inflate severity from file count. Do not report preferences,
historical language, or missing optional environment as product defects unless they create an
active unsafe/false-acceptance path.

## Required output

Use the exact report structure in
`07-CONSENSUS-LEDGER-AND-REPORT-TEMPLATE.md`. Include every C-01 through C-24 row, inventory counts
whose sum matches the manifest, actual command results, environment-unverified claims, retained
limitations, and one preliminary verdict:

- `APPROVE_PILOT`
- `APPROVE_WITH_NOTES`
- `BLOCK_PILOT`
- `STALE_PACKET`

End after writing the report. Do not fix source and do not start another audit/reviewer round.
Codex will independently reproduce every Critical and Important finding. Only issues confirmed by
both become accepted defects; disagreements remain evidence-bound for the owner to decide.
