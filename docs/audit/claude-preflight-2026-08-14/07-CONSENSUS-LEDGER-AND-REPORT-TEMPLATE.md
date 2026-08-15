# Consensus Ledger and Claude Report Template

## Two-party rule

Claude is the independent auditor. Codex is the implementer/reconciler. Neither agent unilaterally
closes a Critical or Important finding.

Finding lifecycle:

```text
PROPOSED_BY_CLAUDE
  -> CONFIRMED_BY_BOTH
  -> FIX_PLANNED
  -> FIXED_AND_REVERIFIED_BY_BOTH

PROPOSED_BY_CLAUDE
  -> REJECTED_WITH_EVIDENCE

PROPOSED_BY_CLAUDE
  -> OWNER_DECISION_REQUIRED
```

- `CONFIRMED_BY_BOTH` requires Claude's evidence and an independent Codex reproduction reaching the
  same root cause and acceptance consequence.
- `REJECTED_WITH_EVIDENCE` preserves both Claude's claim and Codex's falsification. It is not silent
  deletion.
- `OWNER_DECISION_REQUIRED` is used for a real policy/authority disagreement or a proof that needs
  new external authority. It is not a generic uncertainty bucket.
- A fix does not close a finding until both the original reproduction and relevant regression gates
  are rerun against the new candidate snapshot.
- Minor findings may be accepted as notes when both parties agree they cannot invalidate the
  bounded pilot. Critical/Important findings block pilot while unresolved.

## Severity

- **Critical:** credible secret exposure, destructive loss, authority takeover, external mutation,
  or acceptance/promotion of an invalid candidate with severe impact.
- **Important:** selected contract can fail open, wrong model/role/candidate can be accepted, state
  or evidence integrity can drift, installation/rollback can damage user content, or active
  authority materially contradicts implementation.
- **Minor:** bounded clarity, maintainability, citation, advisory budget, or low-impact coverage
  weakness without a current unsafe acceptance path.

Severity follows demonstrated consequence, not file count or rhetorical strength.

## Required Claude report

Claude writes exactly one initial report to:

`docs/audit/claude-preflight-2026-08-14/reports/claude-prepilot-audit-report.md`

Only this report path may be created or changed by Claude during the audit.

Use this structure:

```markdown
# Claude Independent Pre-Pilot Audit Report

## Audit identity

- Auditor model/runtime:
- Repository root:
- Branch:
- HEAD:
- Candidate status SHA-256:
- Packet integrity: PASS | FAIL
- Started/completed UTC:
- Source edits performed: 0
- Provider/model calls performed: 0
- Live installs performed: 0
- Git mutations performed: 0

## Preliminary verdict

APPROVE_PILOT | APPROVE_WITH_NOTES | BLOCK_PILOT | STALE_PACKET

One paragraph explaining the decisive evidence.

## Verification results

| Check | Command or method | Result | Evidence |
|---|---|---|---|

## Coverage matrix

| ID | Outcome | Evidence/finding IDs | Notes |
|---|---|---|---|
| C-01 | | | |
...
| C-24 | | | |

## Inventory accounting

| Scope class | Manifest count | Audited treatment | Findings |
|---|---:|---|---|

Sum of scope-class counts:
Manifest entry count:
Unaccounted entries: 0

## Findings

### CLAUDE-F-001 — Short factual title

- Severity: Critical | Important | Minor
- Confidence: High | Medium | Low
- Consensus status: PROPOSED_BY_CLAUDE
- Coverage IDs:
- Claim:
- Required invariant/authority:
- Affected execution path:
- Exact evidence with file and line/function anchors:
- Safe reproduction and observed result:
- Negative/control result:
- Impact and reachable preconditions:
- Root cause:
- Existing tests/evidence affected:
- Active projection surfaces affected:
- Minimal correction direction, without editing:
- What would falsify this finding:

## Environment-unverified claims

| Claim | Missing prerequisite | Safe evidence completed | Why it does/does not block pilot |
|---|---|---|---|

## Known limitations retained

State which packet limitations were confirmed without converting them to PASS.

## Historical/scratch hygiene

State whether historical, nested-worktree, raw evidence, or temp material can ship, leak secrets,
or become active authority.

## Recommended next action

One bounded recommendation. Do not modify source or start another reviewer round.
```

Replace the `...` coverage placeholder with all rows C-02 through C-23 in the actual report. A
submitted report with missing coverage rows, missing inventory accounting, or unverifiable
Critical/Important evidence is incomplete and cannot approve the pilot.

## Codex reconciliation addendum

Codex appends reconciliation in a separate file rather than rewriting Claude's report:

`docs/audit/claude-preflight-2026-08-14/reports/codex-reconciliation.md`

For each Claude finding:

```markdown
### CLAUDE-F-001

- Codex reproduction: CONFIRMED | FALSIFIED | ENVIRONMENT_UNVERIFIED
- Independent evidence:
- Root-cause agreement: YES | NO
- Severity agreement: YES | NO
- Consensus status: CONFIRMED_BY_BOTH | REJECTED_WITH_EVIDENCE | OWNER_DECISION_REQUIRED
- Candidate/evidence invalidation:
- Proposed next action:
```

The owner reviews disagreements. No agent labels an issue approved merely to avoid discussion.
