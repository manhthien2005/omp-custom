# Claude Follow-Up Reconciliation Prompt

You are the independent Claude auditor performing a focused reconciliation of your pre-pilot
report for `omp-template`. This is not a new full audit and not permission to modify the product.

## Required inputs

Read these files completely before reaching a conclusion:

1. `docs/audit/claude-preflight-2026-08-14/reports/claude-prepilot-audit-report.md`
2. `docs/audit/claude-preflight-2026-08-14/reports/codex-reconciliation.md`
3. `docs/audit/claude-preflight-2026-08-14/00-START-HERE.md`
4. `docs/audit/claude-preflight-2026-08-14/05-SAFE-VERIFICATION-PLAYBOOK.md`
5. `docs/audit/claude-preflight-2026-08-14/07-CONSENSUS-LEDGER-AND-REPORT-TEMPLATE.md`
6. `template/.omp/state/lib/AgentTasks.Store.ps1`
7. `scripts/tests/topic04-state-foundation.Tests.ps1`
8. `docs/superpowers/specs/2026-08-13-topic-04-durable-task-state-candidate-handoff-offload-design.md`
9. `docs/installation.md`
10. `scripts/install-template.ps1`

Treat source code and fresh command output as stronger evidence than either auditor's prose.

## Safety and mutation boundary

- Remain read-only with respect to all product, specification, test, evidence, and packet files.
- Do not stage, commit, install into a live project, invoke a provider/model subprocess, change
  credentials, or delete scratch data.
- You may write exactly one output file:
  `docs/audit/claude-preflight-2026-08-14/reports/claude-reconciliation-response.md`.
- Use only read-only Git inspection and `--dry-run` staging/commit probes. Record staged-path count
  before and after every Git probe and stop if it changes.
- Never print, quote, or copy any suspected secret value. If inspecting `.claude/tmp/keys.txt`,
  report only a structural classification (names only, values present, or inconclusive).

## Claims that require independent adjudication

Reproduce or falsify each claim separately. Do not preserve the original combined finding merely
for agreement's sake.

### A. Existing scratch roots and `git add .`

Determine whether the current `.claude/` and `.tmp-phase00-*` trees are untracked, unignored, local
scratch and selectable by `git add .`. A safe path-scoped dry run is acceptable. Do not stage them.

### B. `git commit --all`

Determine whether `git commit --all` stages previously untracked files. Reconcile the statement in
the finding with the later report statement that the Phase 00 scratch trees "will not be included
in `git commit -a`." State the exact Git behavior and correct the report if needed.

### C. `.agent-tasks` ownership and lifecycle

Trace the executable path rather than inferring from the directory name:

1. Where does operational state live in a Git project?
2. Where does it live in a non-Git project?
3. What exact nested ignore file is created for the non-Git fallback?
4. What happens if Git is initialized later?
5. Does `scripts/install-template.ps1` create operational `.agent-tasks`, or only install the
   `.omp/state` executable component?
6. Is this repository's root `.gitignore` installed into target pilot projects?
7. Can adding `.agent-tasks/` to this repository's root `.gitignore` protect target projects?

If you still recommend `.agent-tasks/`, provide a concrete reachable failure path that is not
already protected by Git-common-dir routing, the nested ignore contract, or migration behavior.

### D. Exact `.claude` ignore scope

Compare these candidate policies:

- `.claude/`
- `.claude/tmp/` plus `.claude/worktrees/`

Recommend the narrowest rule that covers currently generated local-only material without silently
blocking plausible future project-owned Claude configuration. If the entire `.claude/` root is
contractually local-only in this repository, cite the governing evidence. Otherwise prefer and
justify scoped subdirectory rules.

### E. Post-fix evidence lifecycle

Determine whether changing `.gitignore` leaves the frozen candidate snapshot valid. Reconcile the
report's instruction to update only the Round 09-12 manifest with the packet rule that any candidate
byte change makes the packet stale. Enumerate every artifact/gate that must be regenerated or
rerun before both auditors may close the correction.

## Required output

Write `reports/claude-reconciliation-response.md` with this structure:

1. **Reconciliation verdict** — one of `AGREE_WITH_CODEX`, `DISAGREE_WITH_EVIDENCE`, or
   `INSUFFICIENT_EVIDENCE`.
2. **Claim-by-claim matrix** — A through E, each marked `CONFIRMED`, `FALSIFIED`, or
   `ENVIRONMENT_UNVERIFIED`, with command/file/line evidence.
3. **Corrected finding ledger** — split `CLAUDE-F-001` as needed; preserve severity only where the
   execution consequence remains reproduced.
4. **Exact proposed patch** — show the minimal `.gitignore` lines as a proposed diff, but do not
   apply it. Do not include `.agent-tasks/` without the concrete unprotected failure path requested
   above.
5. **Candidate/evidence invalidation plan** — identify snapshot, evidence-manifest, validation,
   and two-party re-verification steps required after a patch.
6. **Pilot verdict impact** — state explicitly whether the original `APPROVE_WITH_NOTES` changes.
7. **Consensus status** — `CONFIRMED_BY_BOTH`, `REJECTED_WITH_EVIDENCE`, or
   `OWNER_DECISION_REQUIRED` for every resulting subfinding.

Stop after writing the response. Do not apply the proposed patch. Codex and the owner will review
your evidence, agree the exact correction, and only then create and verify a new candidate.
