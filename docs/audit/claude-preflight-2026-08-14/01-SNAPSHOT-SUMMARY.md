# Candidate Snapshot Summary

## Frozen scope

The product candidate is the Git working-tree delta relative to
`509cc43b5cbe74ba0edd25a3ab09c696c5a7e247`, excluding only this audit packet directory:

`docs/audit/claude-preflight-2026-08-14/`

The pre-packet inventory contains:

| Measure | Count |
|---|---:|
| Git status entries with untracked files expanded | 1,148 |
| Tracked paths changed, including deletions | 110 |
| Untracked paths | 1,038 |
| Deleted tracked paths | 9 |
| Staged paths | 0 |

`01-CANDIDATE-SNAPSHOT.jsonl` is the exact inventory. Its first record is metadata; every later
record represents one changed path and includes current/baseline identity where applicable.

## Why the inventory is larger than the product

The workspace intentionally contains several kinds of material:

- active specs, phases, runtime template files, scripts, tests, registries, and operator docs;
- current-product and immutable Phase 00 evidence;
- approved designs, implementation plans, changelogs, correction ledgers, and peer-review history;
- local `.claude` scratch/worktree remnants; and
- `.tmp-phase00-*` experiment copies.

All are inventoried so nothing disappears from scope. They do not all carry the same authority or
require the same audit depth.

## Snapshot classification

| `scope_class` | Audit treatment |
|---|---|
| `active-authority` | Deep review; contradictions can block the pilot |
| `phase-authority` | Deep projection review; must agree with active decisions/specs |
| `product-runtime` | Deep execution-path and unsafe-fallback review |
| `implementation-tooling` | Deep when it installs, mutates, validates, captures, or routes behavior |
| `verification-test` | Check positive and adversarial adequacy; do not equate tests with truth |
| `current-evidence` | Verify provenance, hashes, capture boundary, and claim strength |
| `evaluation-fixture` | Verify deterministic semantics and campaign/provider separation |
| `governance-registry` | Verify machine facts, selected/rejected status, pins, and licenses |
| `operator-documentation` | Verify it does not overclaim or provide unsafe commands |
| `design-plan` | Intent/history; use to understand why, not to override current authority |
| `review-history` | Consult only to reproduce a live claim; old verdicts are not authority |
| `immutable-history` | Integrity/provenance check; do not rewrite it to match current product |
| `source-provenance` | Consult when an active claim imports the source; it is not current runtime authority by itself |
| `local-scratch` | Hygiene/security check only; must not ship or become authority |
| `repository-metadata` | Check ignore/safety behavior and accidental inclusion risk |

The frozen candidate has this exact classification:

| `scope_class` | Count |
|---|---:|
| `active-authority` | 24 |
| `current-evidence` | 18 |
| `design-plan` | 36 |
| `evaluation-fixture` | 13 |
| `governance-registry` | 5 |
| `immutable-history` | 552 |
| `implementation-tooling` | 49 |
| `local-scratch` | 186 |
| `operator-documentation` | 19 |
| `phase-authority` | 8 |
| `product-runtime` | 56 |
| `repository-metadata` | 3 |
| `review-history` | 82 |
| `source-provenance` | 34 |
| `verification-test` | 63 |
| **Total** | **1,148** |

## Hash semantics

- Existing files carry `current_sha256` over their current bytes.
- Modified tracked files also carry `baseline_sha256` over the `HEAD` blob.
- Deleted tracked files carry only `baseline_sha256` and `current_exists: false`.
- Each record includes byte size when current content exists.
- The metadata record contains `candidate_status_sha256`, calculated over a normalized, sorted
  status list excluding the packet directory.

The manifest does not claim that a hash proves correctness. It proves only which candidate Claude
was asked to inspect. Current-product evidence has its own narrower provenance and validity rules.

## Required auditor behavior

Claude must:

1. verify packet hashes;
2. recompute the candidate status digest and compare it to the metadata record;
3. confirm `HEAD`, branch, and staged-path count;
4. account for all manifest entries by `scope_class` in the report; and
5. stop with `STALE_PACKET` if any candidate path/status/hash differs before substantive audit.

The packet-local helper can reproduce this comparison without rewriting the manifest:

```powershell
pwsh -NoLogo -NoProfile -File `
  docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.ps1 `
  -RepositoryRoot . `
  -InputPath docs/audit/claude-preflight-2026-08-14/01-CANDIDATE-SNAPSHOT.jsonl `
  -Verify
```

Do not enter nested `.claude/worktrees` repositories or treat them as the candidate. Only paths
explicitly represented in this repository's manifest are in scope. `.tmp-phase00-*` content is
checked for accidental shipping, secrets, and authority confusion, not re-audited as product code.
