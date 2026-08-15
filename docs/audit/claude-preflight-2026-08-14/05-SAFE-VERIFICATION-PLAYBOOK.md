# Safe Verification Playbook

## Pass 0 — packet and candidate freshness

Run from `D:\Dev\Projects\omp-template` in PowerShell. These checks are read-only.

```powershell
git branch --show-current
git rev-parse HEAD
git diff --cached --name-only
Get-FileHash -Algorithm SHA256 docs/audit/claude-preflight-2026-08-14/* -ErrorAction SilentlyContinue
```

Expected branch is `codex/topic03-agent-topology`, expected `HEAD` is
`509cc43b5cbe74ba0edd25a3ab09c696c5a7e247`, and staged output is empty. Verify each packet file
listed in `PACKET-SHA256.txt` by bytes.

Then independently enumerate `git status --porcelain=v1 -uall`, excluding only
`docs/audit/claude-preflight-2026-08-14/`, and compare every path/status/current hash/baseline hash
to `01-CANDIDATE-SNAPSHOT.jsonl`. The metadata record contains the normalized status digest. Do not
use a shell that changes quoting or path separators without normalizing them identically.

If any product-candidate record differs, return `STALE_PACKET` with the first mismatches. Do not
continue to a pilot verdict on a moving candidate.

## Non-negotiable safety limits

- Read-only repository/source inspection is allowed.
- Deterministic tests may mutate only verified disposable system-temp roots they create.
- Do not run an apply/live form of installer, uninstaller, cleanup, state purge, or worktree command.
- Do not contact OmniRoute, DeepSeek, OpenAI, Anthropic, Context7, GitHub, package registries, or any
  other network/provider endpoint.
- Do not use existing credentials or inspect secret values.
- Do not stage, commit, reset, clean, checkout, switch branch, create/delete worktrees, or delete
  existing temp/scratch directories.
- Do not edit source to test a theory. Use disposable copies or existing mutation suites.
- Claude may write only its audit report under this packet's `reports/` directory.

If a command's implementation cannot be shown to obey these limits before execution, do not run
it. Record the unverified claim and the exact safe proof that would be needed.

## Pass 1 — authority and intent reconciliation

1. Read owner decisions and KD-024 through KD-032.
2. Select the applicable active specs and phases from the traceability map.
3. Identify superseded/historical clauses before interpreting old checkboxes or role names.
4. Record active contradictions as findings; record historical drift only when an active consumer
   imports or relies on it.
5. Verify that operator docs state the same safe current behavior without overclaiming readiness.

Do not spend the pass editing wording. The output is evidence and affected surfaces.

## Pass 2 — vertical execution-path audit

Audit one load-bearing path at a time:

1. entry/classification and task contract;
2. dispatch decision, exact role/model/effort/capability preflight;
3. native/managed execution boundary;
4. result receipt, candidate/evidence binding, integration, verification/review;
5. continuity/handoff/retention; and
6. evaluation/package/readiness.

For each path, trace the requirement to implementation, a success test, a negative test, evidence,
and active documentation. A plausible shaped result is not proof of correct execution.

## Pass 3 — focused validators

Run the focused validators individually so a failure is attributable:

```powershell
pwsh -NoLogo -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-topic03-topology-routing.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic04-durable-state.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic06-agent-boundary.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic07-context-continuity.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic08-behavior-core.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot .
```

Expected result is exit code `0` for each. Packet creation will record fresh counts in
`06-KNOWN-LIMITATIONS.md`. A count mismatch is evidence to investigate, not automatic proof of a
product defect. Do not update evidence or expected counts during the audit.

## Pass 4 — independent falsification

Validators authored with the implementation can share the same blind spot. Independently inspect
at least one adversarial path for every high-risk coverage cluster:

- mutate only a disposable copy or use an existing mutation suite;
- prove the negative control actually fails before trusting a sentinel;
- inspect OMP source at the pinned SHA for claims about discovery, model resolution, tool stripping,
  schema status, task fallback, isolation, compaction, or extension loading;
- compare returned runtime identity/provenance, not just configured intent;
- verify an error result cannot be reformatted into acceptable structured output; and
- verify captured evidence cannot validate itself after candidate or input drift.

Existing safe high-value commands include:

```powershell
pwsh -NoLogo -NoProfile -File scripts/tests/round09-12-validator-mutations.Tests.ps1
pwsh -NoLogo -NoProfile -File scripts/tests/round09-12-installer.Tests.ps1
node --test scripts/tests/round09-12-evaluation-core.Tests.mjs scripts/tests/round09-12-review-security.Tests.mjs
```

Run additional Topic 02–08 mutation or focused tests only when selected by a coverage row or a
candidate finding. Do not rerun every historical Phase 00 raw experiment unless a pinned runtime
claim is disputed and no smaller safe proof exists.

## Pass 5 — full reconciliation gate

After targeted review, run:

```powershell
pwsh -NoLogo -NoProfile -File scripts/validate-template.ps1
git diff --check
```

Packet baseline at creation time: full validation `356 passed, 1 warning, 0 failed`; the warning is
the known `template/.omp/AGENTS.md` approximate budget advisory. `git diff --check` is expected to
exit `0` with a possible existing Phase 00 line-ending advisory. Reproduce actual output in the
report rather than copying these expectations.

## Pass 6 — report and stop

1. Close every coverage row.
2. Deduplicate findings by root cause and execution consequence.
3. Give every Critical/Important finding a minimal safe reproduction or mark it unverified.
4. State whether existing evidence becomes invalid, incomplete, or unaffected.
5. Produce one preliminary verdict and stop.

Do not fix findings, start another review round, or request Opus automatically. Codex performs the
independent reconciliation after Claude's report. A disagreement is an owner-visible state, not a
reason for endless reviewer recursion.
