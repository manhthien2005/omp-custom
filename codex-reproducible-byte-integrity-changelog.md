# Reproducible Evidence Byte Integrity — Implementation Changelog

## Baseline

- Branch: `main` (17 commits ahead of `origin/main`, no force operations used).
- Baseline commit before this work: `5397f5c` (`chore: restore governed ignore policy`).
- Full validator on committed bytes at that point: `343 passed, 1 warnings, 12 failed`.
- `git config core.autocrlf` = `input`; no `.gitattributes` existed at the repository root.
- Plan: `docs/superpowers/plans/2026-08-15-reproducible-byte-integrity.md`.
- Design: `docs/superpowers/specs/2026-08-15-reproducible-byte-integrity-design.md`.

## Root cause

Evidence and archived-review files were generated with CRLF or mixed EOLs and were hashed into
snapshots and manifests while still untracked. With `core.autocrlf=input` and no repository
attributes, `git add` stored LF blobs while the working tree kept the original bytes, so every
pinned SHA-256 kept matching locally. A later checkout reconstructed the files from those LF blobs
and the pinned hashes stopped matching. The failure is a Git EOL-normalization artifact, not a
content change and not a validator-logic regression: `git diff --name-status 339db16 HEAD` shows
only two added documentation files across the four intervening commits.

## Files changed

| Path | Change |
|---|---|
| `scripts/repair-evidence-byte-integrity.ps1` | Fail-closed planner and guarded apply transaction; two classification defects fixed (below) |
| `scripts/tests/evidence-byte-integrity.Tests.ps1` | 18 → 21 assertions covering the two fixed defects |
| `.gitattributes` | New: `-text` for `/docs/evidence/**`, `/docs/audit/**`, `/docs/archive/reviews/**` |
| 132 snapshot paths under `docs/evidence/` and `docs/archive/reviews/` | Historical bytes restored |
| `docs/evidence/current-product/topic-03/deepseek-smoke.yml` | Historical bytes restored against its pre-existing manifest pin (absent from the snapshot) |
| `docs/audit/claude-preflight-2026-08-14/reports/byte-integrity-recovery.md` | New provenance and limitation report |
| `codex-reproducible-byte-integrity-changelog.md` | This file |

Two planner defects were found and fixed before any repair could run, because
`Invoke-EvidenceByteIntegrityRepair` refuses any plan with `Missing > 0`:

1. PowerShell unrolls a zero-length array on `return`, so all 64 zero-byte evidence artifacts
   surfaced as `$null` and were classified `missing`. All four byte-returning paths now comma-wrap
   (`return , $bytes`) so `byte[0]` survives the call boundary.
2. The snapshot also records 31 entries with `current_exists: false` (statuses `D ` and ` D`,
   `current_sha256: null`) for paths deleted or renamed away at capture time. Those were being
   treated as in-scope and classified `missing`. A StrictMode-safe guard now skips them, matching
   the design's "for every snapshot entry with `current_exists: true`" contract.

Fixed in `e3c3743` (`fix: classify zero-byte and retired snapshot entries correctly`).

## RED evidence

Before the fixes, with the real snapshot:

```text
FAIL: Exact=838 Recoverable=132 Unrecoverable=5 Missing=95 Invalid=0 Ambiguous=0 Written=0
```

`Missing=95` = 64 zero-byte artifacts + 31 `current_exists: false` entries. Apply was refused, as
designed. The zero-length-array behaviour was confirmed directly: returning
`[IO.File]::ReadAllBytes($path)` from a function yields `is null: True` for an empty file, while
`return , [IO.File]::ReadAllBytes($path)` yields `type: Byte[]; length: 0`.

## GREEN evidence

`.gitattributes` scope check — the three protected roots report `text: unset`; controls
(`README.md`, `scripts/validate-template.ps1`, `spec/phases/phase-00-foundation.md`,
`template/.omp/AGENTS.md`) report `text: unspecified`, proving the policy is narrow.

```text
pwsh -File scripts/tests/evidence-byte-integrity.Tests.ps1
  PASS: evidence byte integrity (21 assertions).                                    exit 0

pwsh -File scripts/repair-evidence-byte-integrity.ps1
  REPAIR_REQUIRED: Exact=838 Recoverable=132 Unrecoverable=5 Missing=0 Invalid=0
                   Ambiguous=0 Written=0                                            exit 2

pwsh -File scripts/repair-evidence-byte-integrity.ps1 -Apply
  PASS: Exact=970 Recoverable=0 Unrecoverable=5 Missing=0 Invalid=0
        Ambiguous=0 Written=132                                                     exit 0

pwsh -File scripts/repair-evidence-byte-integrity.ps1
  PASS: Exact=970 Recoverable=0 Unrecoverable=5 Missing=0 Invalid=0
        Ambiguous=0 Written=0                                                       exit 0

git diff --ignore-space-at-eol --exit-code -- docs/evidence docs/archive/reviews    exit 0
```

The `--ignore-space-at-eol` exit `0` proves the 132 restored files changed only in line endings.

`docs/evidence/current-product/topic-03/deepseek-smoke.yml` was repaired in a second, separate
transaction because it does not appear in the snapshot (`grep -c` = 0) and so was invisible to the
first pass. Its authority is the pre-existing pin in
`docs/evidence/current-product/topic-03/manifest.yml`, which was read and never written. A
single-entry snapshot derived from that pin was written to a guarded system-temp directory
(prefix `omp-byte-integrity-derived-`), fed to the same CLI, then removed:

```text
pwsh -File scripts/repair-evidence-byte-integrity.ps1 -SnapshotPath <derived>
  REPAIR_REQUIRED: Exact=0 Recoverable=1 Unrecoverable=0 Missing=0 Invalid=0
                   Ambiguous=0 Written=0                                            exit 2

pwsh -File scripts/repair-evidence-byte-integrity.ps1 -SnapshotPath <derived> -Apply
  PASS: Exact=1 Recoverable=0 Unrecoverable=0 Missing=0 Invalid=0
        Ambiguous=0 Written=1                                                       exit 0

sha256sum docs/evidence/current-product/topic-03/deepseek-smoke.yml
  112f4ccc147f51ca88c42ac9e30011588002f8876111a37231cae1b4cd994ba1   (matches the pin)
```

Full-tree verification after both repairs:

```text
pwsh -File scripts/validate-template.ps1
  Results: 356 passed, 1 warnings, 0 failed                                         (was 343/1/12)

pwsh -File docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.Tests.ps1
  Audit snapshot tests: 22 PASS                                                     exit 0

git diff --check                                                                    exit 2
git -c core.whitespace=cr-at-eol diff --check                                       exit 0
```

The five validator failures that survived the first repair (`P00-E1-PROTECTED-SURFACE`,
`P00-T003-LATER-SUPERSESSION`, `P00-T003-VALIDATOR`, `P00-T003-EVIDENCE`, `P00-T003-MANIFEST`) all
cleared with the `deepseek-smoke.yml` repair. Only `P00-T003-LATER-SUPERSESSION` named the file
directly; the other four cascade from it, as the design document predicted.

`git diff --check` exits `2` reporting 133 "trailing whitespace" hits across the restored files.
This is the expected consequence of the repair: Git's default whitespace rules treat a CR before
LF as trailing whitespace, so restoring CRLF bytes necessarily trips the plain check. The same
command with `core.whitespace=cr-at-eol` exits `0`, confirming CR-at-EOL is the only finding and
no genuine trailing space or tab was introduced. The plan's expectation of exit `0` was written
before the CRLF restoration existed and cannot hold simultaneously with it.

A repository-wide sweep of 256 machine-readable manifests under `docs/evidence`, `docs/audit`,
`registry`, `spec`, `evals`, and `template` found 334 `path` + `sha256` pairs. Every pair that
resolves to a file in this repository now matches its pinned value exactly.

## Fresh-clone evidence

Status: PASS. Verified commit `4eb379f2c288bc04d7bc10665f9c19849ca39e53`
(`fix: preserve historical evidence bytes`), which is the `main` HEAD the clone was taken from.

Before cloning, `main` reported:

```text
pwsh -File scripts/repair-evidence-byte-integrity.ps1 -Source Head
  PASS: Exact=970 Recoverable=0 Unrecoverable=5 Missing=0 Invalid=0
        Ambiguous=0 Written=0                                                       exit 0
git status --short --branch
  ## main...origin/main [ahead 18]                                                  (clean)
```

A disposable clone was created under the guarded system-temp prefix
`omp-byte-integrity-clone-` with `git clone --no-hardlinks --local . <cloneRoot>`. Its HEAD matched
`main` exactly. Results inside the clone:

```text
pwsh -File scripts/repair-evidence-byte-integrity.ps1
  PASS: Exact=970 Recoverable=0 Unrecoverable=5 Missing=0 Invalid=0
        Ambiguous=0 Written=0                                                       exit 0

pwsh -File scripts/repair-evidence-byte-integrity.ps1 -Source Head
  PASS: Exact=970 Recoverable=0 Unrecoverable=5 Missing=0 Invalid=0
        Ambiguous=0 Written=0                                                       exit 0

pwsh -File scripts/tests/evidence-byte-integrity.Tests.ps1
  PASS: evidence byte integrity (21 assertions).                                    exit 0

pwsh -File docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.Tests.ps1
  Audit snapshot tests: 22 PASS                                                     exit 0

git diff --check                                                                    exit 0
git status --porcelain=v1 -uall                                                     (empty)
```

Both working-tree and HEAD sources reporting `970 / 0 / 5` in a clone that never held the original
CRLF working-tree bytes is the proof that the committed blobs themselves now reproduce the accepted
byte sequences. `git diff --check` exits `0` inside the clone — unlike on the repair worktree,
where the CR-at-EOL restoration was still an unstaged diff — because in the clone the restored
bytes are the committed baseline and there is nothing to diff.

The first clone validator run reported `353 passed, 1 warnings, 3 failed`
(`P00-REG-WATCHED-MISSING`, `T07-SOURCE-ATTACHMENTS`, `T08-SOURCE-ATTACHED`). All three are
environment provisioning, not byte integrity: they require the pinned upstream OMP checkout at
`_research/upstreams/oh-my-pi` (commit `3a8591a8af5b6d200088d12ca75a5517cb064fa8`), which
`.gitignore:2` deliberately excludes from source control, so a clone never carries it. After
copying the existing local pinned checkout into the clone — HEAD `3a8591a`, origin
`https://github.com/can1357/oh-my-pi.git`, zero dirty entries, no network fetch — the clone
reported:

```text
pwsh -File scripts/validate-template.ps1
  Results: 356 passed, 1 warnings, 0 failed
```

Audit-packet gate: 11 of 12 `PACKET-SHA256.txt` rows matched, with the single mismatch being
`capture-candidate-snapshot.ps1` — exactly the documented minimal fix from `63b578d`. No other row
drifted, so the packet's historical provenance hashes are intact.

Cleanup: the clone directory was removed after its parent was proved to be the system temp base and
its leaf proved to start with `omp-byte-integrity-clone-` and be longer than that prefix. Removal
confirmed; the source repository's own `_research/upstreams/oh-my-pi` checkout was verified intact
afterward.

## Post-snapshot authorized revisions

`02-POST-CLEANUP-CANDIDATE-SNAPSHOT.jsonl` is a frozen record of the working tree at capture time.
It is produced from `git status --porcelain`, so it cannot be re-captured against a clean tree
without emptying it, and it is preserved here byte-identical. Any file the owner intentionally
revises after that capture therefore shows up in the preflight as `invalid` — the detector is
reporting a real content difference, not EOL damage.

Three rounds of such revisions have occurred. The first was the owner-authorized `README.md` redesign
(Oh My Pi link corrected to `https://github.com/can1357/oh-my-pi`, plus a visual restructure), which
forced its two governed hash pins to be regenerated through the sanctioned capture scripts. The
second was the owner-authorized defect-repair round. The third was the owner-authorized live-run
round: a real DeepSeek Flash/Pro provider smoke and a durable local 17.2.10 runtime for the Topic 07
two-version canary. All three are recorded below.

```text
pwsh -File scripts/repair-evidence-byte-integrity.ps1
  FAIL: Exact=943 Recoverable=0 Unrecoverable=5 Missing=0 Invalid=27
        Ambiguous=0 Written=0                                                       exit 1
```

The twenty-seven `invalid` paths are exactly the authorized change set, and `943 + 27 = 970` — the
original `Exact` count — so no other snapshot row drifted:

| Path | Why it differs from the snapshot |
|---|---|
| `README.md` | Owner-authorized content redesign |
| `CHANGELOG.md` | `### Fixed` section added for the defect-repair round |
| `template/.omp/extensions/agent-task-boundary.js` | Root-union → closed-root-object schema fix for OpenAI-responses strict-function validation |
| `template/.omp/contracts/component-manifest.json` | Owned-file pin regenerated for the boundary fix |
| `template/.omp/codegraph/component-manifest.json` | State-component digest re-pinned |
| `scripts/lib/topic05-benchmark.ps1` | Token basis corrected to `input + output + cacheWrite` |
| `scripts/lib/topic07-context-continuity.ps1` | `T07-EVIDENCE` now asserts per-case `PASS` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | Stale Quick-command fixture replaced with the real continuity contract |
| `scripts/tests/topic05-benchmark.Tests.ps1` | Coverage for the corrected token basis |
| `scripts/tests/topic06-omp-wrapper.Tests.mjs` | Coverage for the closed schema root |
| `scripts/tests/topic06-validator-mutations.Tests.ps1` | Version-agnostic `component_version` mutation |
| `scripts/tests/phase00-t003.Tests.ps1` | Missing `current_files` path added to the fixture |
| `scripts/tests/phase00-wave-a.Tests.ps1` | Native `PSModulePath` pinned; expected version-gate failure set asserted |
| `scripts/tests/phase00-e1.Tests.ps1` | Main Phase 00 helper loaded so the supersession branch resolves; fixture and pin assertions aligned with the Topic 03 supersession |
| `docs/evidence/current-product/round-09-12/manifest.json` | Regenerated by `scripts/capture-round09-12-evidence.ps1` |
| `docs/evidence/current-product/topic-05/manifest.json` | Regenerated by `scripts/capture-topic05-evidence.ps1` |
| `docs/evidence/current-product/topic-06/manifest.json` | Regenerated by `scripts/capture-topic06-evidence.ps1` |
| `docs/evidence/current-product/topic-06/deterministic.json` | Regenerated by `scripts/capture-topic06-evidence.ps1` |
| `docs/evidence/current-product/topic-07/manifest.json` | Regenerated by `scripts/capture-topic07-evidence.ps1` |
| `docs/evidence/current-product/topic-07/deterministic.json` | Regenerated by `scripts/capture-topic07-evidence.ps1` |
| `.gitignore` | Excludes the untracked local OMP runtime cache used by the two-version canary |
| `codex-topic07-context-compaction-continuity-changelog.md` | Records the 17.2.10 provisioning and the resulting two-runtime canary pass |
| `scripts/capture-topic07-evidence.ps1` | Records the reached promotion state instead of hardcoding the blocked one |
| `docs/evidence/current-product/topic-03/manifest.yml` | DeepSeek smoke re-pinned to the live-run bytes; `deepseek_environment` is now `PASS` |
| `docs/evidence/current-product/round-09-12/release-readiness.json` | Regenerated by `scripts/capture-round09-12-evidence.ps1` |
| `docs/evidence/current-product/topic-08/manifest.json` | Regenerated by `scripts/capture-topic08-evidence.ps1` |
| `docs/evidence/current-product/topic-08/deterministic.json` | Regenerated by `scripts/capture-topic08-evidence.ps1` |

`docs/evidence/current-product/topic-03/deepseek-smoke.yml` also changed, from
`ENVIRONMENT_BLOCKED` to a real two-model `PASS`. It is absent from the candidate snapshot, so it
does not appear in the count above; its authority is the `topic-03/manifest.yml` pin, regenerated in
the same round.

The five closed limitations still classify as `unrecoverable` with their pinned Git-LF hashes, and
`Recoverable`, `Missing`, and `Ambiguous` all remain `0`. No snapshot hash was edited to absorb the
revision, and `scripts/validate-template.ps1` reports `356 passed, 1 warnings, 0 failed` against the
regenerated pins.

## Limitations

- The byte-integrity preflight is not a live gate over regenerated current-product evidence. Those
  files are governed by `R0912-R-EVIDENCE` and `T07-EVIDENCE-HASHES` instead, which hash the live
  bytes on every run.
- Five paths remain normalized-text-equivalent but not raw-byte-reproducible; their accepted
  Git-LF hashes are recorded in
  `docs/audit/claude-preflight-2026-08-14/reports/byte-integrity-recovery.md` and pinned in the
  CLI's closed limitation set. They were not reconstructed or replaced.
- Passing a normalized-text comparison is not raw-byte identity and is not claimed as such.
- `docs/evidence/current-product/topic-03/deepseek-smoke.yml` is not covered by the candidate
  snapshot; its repair rests on the manifest pin instead. That pin predates this work
  (`647dbb7`), so it is prior evidence, not a value produced to make validation pass.
- No snapshot, manifest, packet hash, selected runtime file, or product behaviour was edited.
- No provider call, live install, remote push, or external backup was involved in this task.
- A fresh clone alone is not sufficient to reach a green validator: the pinned upstream OMP
  checkout at `_research/upstreams/oh-my-pi` is intentionally untracked, so three source-attachment
  checks fail until it is provisioned. That is a documented environment prerequisite, not a
  regression, and it is unrelated to evidence byte integrity.
- `CLAUDE-F-001` remains `FIXED_PENDING_CODEX_REVERIFICATION`. Nothing here is independently
  reverified by Codex, merged, released, promoted, or production-ready.

## Git integration

- `ad9a957` `test: add fail-closed evidence byte repair` (planner and focused test, fast-forwarded
  onto `main`).
- `e3c3743` `fix: classify zero-byte and retired snapshot entries correctly`.
- `fix: preserve historical evidence bytes` — this commit: `.gitattributes`, 133 restored paths,
  the recovery report, and this changelog.
- `codex/topic03-agent-topology` is retained. Task 3 owns its deletion gate; no branch was deleted
  and no history was amended, rebased, squashed, or force-pushed.
