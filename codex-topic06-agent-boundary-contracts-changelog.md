# Topic 06 — Agent Boundary Contracts Changelog

## Scope

Topic 06 implements a portable closed packet/result core and a trusted same-name OMP `task`
wrapper. The supported entry point is `.omp/bin/omp-managed.ps1`. Topic 04 remains durable
authority; receipts and work-unit outcomes are provisional. All work is local and unstaged. No
provider/model call is part of the deterministic evidence campaign.

## Implemented

- Topic 04 `project-work-unit` projection and provisional outcome compare-and-swap.
- Closed agent packet, handoff, semantic-result, receipt, and failure-code contracts.
- Cheap Scout Flash `xhigh` → Pro `xhigh` availability fallback; Worker `high`/hard `xhigh`;
  Reviewer fixed `xhigh`.
- Reviewer ARTIFACT + CONTRACT input with Worker CLAIM excluded.
- Trusted native `task` delegation, blocking single/batch support, plan-mode checks, and managed
  v1 async/nested refusal.
- Manifest-verified launcher, `task.softRequestBudget: 200` overlay, transactional installer, and
  attributable rollback that preserves Topic 04 operational state.
- Current authority/docs projections, focused validator, mutation suite, current-product evidence,
  and full-validator integration.

## Verification record

- Node contract/wrapper suites: 42 passed, 0 failed.
- State projection: 25 assertions passed.
- Installer/rollback: 40 assertions passed.
- Installed managed runtime: 14 assertions passed.
- End-to-end boundary campaign: 17 assertions passed; packet set
  `A634BDE3AA5EAAE062C665CEDBBBC59460876B4DA93A6CECF244F5E95E2A523F`.
- Validator mutation suite: 20 assertions passed.
- Focused compatibility validators: Topic 02 `604/0/0`, Topic 03 `22/0/0`, Topic 04
  `41/0/0`, Topic 05 `25/0/0`, and Topic 06 `19/0/0` (pass/warn/fail).
- Full repository validator: 284 passed, 1 known warning, 0 failed. The warning is the retained
  advisory that `.omp/RULES.md` is below its suggested token target; it is not a contract failure.
- Current-product evidence: `deterministic.json`
  `046630A3C4F5D1570FC09C02F526A359C5CB40B0AEEFF141F14822F3334DCFE7`; `manifest.json`
  `332CA409AC1924994ADB48966139516F94E7F91F8B7A0D43395ACF556FA439C3`.
- Pinned OMP source: `3a8591a8af5b6d200088d12ca75a5517cb064fa8`, clean. `git diff --check`
  passed; the root staging area is empty. Provider/model calls: 0.

## Known limitation

`OPEN-T06-RUNTIME-01` remains nonblocking: unrelated OMP Vibe/`eval`/internal-agent facilities do
not share one universal public interception hook. Their output is unmanaged and cannot claim a
Topic 06 receipt. Opus is not required; unavailable managed dispatch falls back to inline Tech
Lead work without a fabricated packet, self-review, or receipt.
