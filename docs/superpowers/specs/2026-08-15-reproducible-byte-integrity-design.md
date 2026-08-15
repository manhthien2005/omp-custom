# Reproducible Byte Integrity for Historical Evidence — Design

Status: approved design written for user review
Date: 2026-08-15
Repository: `omp-template`
Baseline: `main` and `codex/topic03-agent-topology` at `339db166ec61c8c3ab97a64ef0851b6f54999f7b`
Execution boundary: local repository only; no push, PR, provider call, manifest re-pin, or live install

## 1. Approved decision

The repository will preserve historical evidence as raw bytes instead of treating CRLF and LF as
interchangeable. Immutable-history directories will opt out of Git text normalization. Files whose
pre-commit bytes can be recovered uniquely from the post-cleanup audit snapshot will be restored to
their recorded SHA-256 values.

The implementation must not update pinned hashes to make validation pass. Five snapshot entries
whose exact mixed-EOL pattern is no longer recoverable will remain at their Git-reproducible LF
bytes and will be recorded as a provenance limitation.

## 2. Problem statement

The feature branch originally reported:

```text
356 passed, 1 warning, 0 failed
```

After a clean branch checkout and fast-forward merge to `main`, the same commit reported:

```text
343 passed, 1 warning, 12 failed
```

The working tree remained clean. The failure is reproducible and is not caused by branch-specific
validator logic.

The machine has `core.autocrlf=input`, while the repository has no `.gitattributes`. Many evidence
files were generated with CRLF or mixed EOLs and hashed before they were tracked. `git add`
normalized those bytes to LF in the stored blob but left the original working-tree bytes in place,
so validation passed until checkout reconstructed the files from Git.

Examples:

| Path | Snapshot/pinned SHA-256 | Git-checkout SHA-256 | Finding |
|---|---|---|---|
| `docs/evidence/phase-00/E3-I/raw/session-a-attempt-007.run.json` | `9c89c85a...` | `87b3cb72...` | Pinned hash equals the CRLF reconstruction exactly |
| `docs/evidence/phase-00/E3-L/source-identity.json` | `ce7b3df1...` | `5e4a0f04...` | Pinned hash equals CRLF with a final LF exactly |
| `docs/evidence/phase-00/E5/raw/e5-a-attempt-001.projection.json` | `cd374750...` | `686a42ea...` | Pinned hash equals CRLF with a final LF exactly |
| `docs/evidence/current-product/topic-03/deepseek-smoke.yml` | `112f4ccc...` | `f0060ee0...` | Pinned hash equals the CRLF reconstruction exactly |

The initial hash mismatches also make the Topic 03 supersession contract fail. That causes legacy
agent and evidence checks to run against retired paths, accounting for several of the remaining
failures. Topic 06 and Topic 07 evidence reconciliation failures have the same raw-byte cause.

## 3. Measured scope

`02-POST-CLEANUP-CANDIDATE-SNAPSHOT.jsonl` contains 975 entries for files that existed when the
snapshot was captured. Comparing those recorded hashes with the clean checkout gives:

| Classification | Count | Treatment |
|---|---:|---|
| Raw bytes already match | 838 | Leave untouched |
| Unique all-CRLF reconstruction matches | 74 | Restore recorded bytes |
| Unique CRLF-with-final-LF reconstruction matches | 58 | Restore recorded bytes |
| Complex mixed-EOL pattern not recoverable | 5 | Preserve Git LF bytes and record limitation |
| Missing files | 0 | None |

The 132 recoverable files are distributed as follows:

- 127 under `docs/evidence/phase-00/`;
- 4 under `docs/evidence/current-product/`; and
- 1 under `docs/archive/reviews/`.

The five unrecoverable raw-byte entries are:

- `docs/archive/reviews/opus5-response-to-gpt56-counter-review.md`;
- `docs/evidence/phase-00/E3-J/raw/J1-attempt-002.run.json`;
- `docs/evidence/phase-00/E3-J/raw/J1-attempt-003.run.json`;
- `docs/evidence/phase-00/E3-J/raw/J1.run.json`; and
- `spec/phases/phase-00-foundation.md`.

These files are text-equivalent after EOL normalization, but their exact positions of CR bytes
cannot be derived from a one-way SHA-256 digest. The original bytes are absent from reachable Git
history, the linked worktree, and all 351 unreachable Git blobs inspected during diagnosis.

## 4. Goals and non-goals

### Goals

1. Restore every snapshot byte sequence that is uniquely recoverable without guessing.
2. Preserve raw bytes across Windows, Linux, and clean Git checkouts.
3. Keep historical and current-product hash references unchanged.
4. Make the full validator reproducible from a fresh local clone.
5. Keep Git text diffs available for preserved files.
6. Record the five unrecoverable entries honestly instead of fabricating a reconstruction.

### Non-goals

- no global repository EOL normalization;
- no update to evidence manifests, packet hashes, or snapshot hashes;
- no semantic edit to historical evidence;
- no recovery attempt based on brute-forcing SHA-256;
- no change to provider, runtime, model, or installation behavior;
- no push or PR as part of this repair;
- no cleanup or deletion of the source branch until fresh-clone verification is green.

## 5. Byte-preservation contract

The repository root will add `.gitattributes` rules equivalent to:

```gitattributes
docs/evidence/** -text
docs/audit/** -text
docs/archive/reviews/** -text
```

`-text` disables Git EOL conversion while retaining normal text diff behavior. It is preferred over
the `binary` macro because these artifacts should remain reviewable as text.

The directory-level rule is intentional. These directories contain evidence, audit packets, and
historical review records whose bytes may be hash-bound. Per-file rules for the current 132 paths
would be brittle and would leave future evidence exposed to the same failure.

The rule does not apply to active source, specifications outside the historical directories, or
the whole repository. Their existing EOL behavior remains unchanged.

## 6. Restoration algorithm

Restoration is a two-phase, fail-closed operation.

### Phase A — preflight only

For every snapshot entry with `current_exists: true` and `current_sha256`:

1. read current bytes without text decoding side effects;
2. compute the raw SHA-256;
3. if raw bytes match, classify the path as `exact`;
4. otherwise normalize only physical CRLF line endings to LF;
5. build the approved candidate encodings:
   - all LF separators converted to CRLF; and
   - all non-terminal LF separators converted to CRLF while preserving the final LF;
6. select a restoration only when exactly one candidate equals the recorded SHA-256;
7. classify the five known complex patterns as `unrecoverable` only when normalized text still
   matches the Git version and the path is in the closed limitation list; and
8. abort before any write for every missing file, unexpected content difference, ambiguous match,
   extra unrecoverable path, or changed limitation-list path.

On the initial broken checkout, the complete plan and counts must equal 838 exact, 132 recoverable,
5 unrecoverable, and 0 missing before Phase B may start.

### Phase B — write and prove

1. write only the 132 precomputed byte arrays;
2. verify each written file immediately against its snapshot SHA-256;
3. verify that the 838 exact files and five limitation files were not changed;
4. add the byte-preservation attributes;
5. inspect the resulting Git diff and reject semantic content changes after EOL normalization; and
6. stop without re-pinning any failed reference.

The implementation will add `scripts/repair-evidence-byte-integrity.ps1` as the single durable
entrypoint. It must default to read-only preflight and require an explicit `-Apply` switch for
writes. After restoration, both the current repository and a fresh clone must report 970 exact,
0 recoverable, 5 unrecoverable, and 0 missing.

## 7. Provenance limitation

The snapshot continues to record the five original SHA-256 values. The repository must not claim
that those exact five byte sequences are present after checkout. Documentation added by this repair
will state:

- normalized text content is preserved;
- exact pre-commit mixed-EOL bytes are unavailable;
- the loss occurred before the files became reproducible Git blobs; and
- no load-bearing manifest hash will be changed to conceal the loss.

If an external backup later supplies a candidate original, it may be accepted only after its raw
SHA-256 equals the existing snapshot value. No new hash may replace that proof.

## 8. Verification design

The existing full validator is the primary failing regression test. Implementation starts from the
fresh, repeatable RED result of 343 passed, one warning, and 12 failed.

After restoration, run in the current repository:

1. restoration preflight and post-write hash reconciliation;
2. `pwsh -NoLogo -NoProfile -File scripts/validate-template.ps1`;
3. `pwsh -NoLogo -NoProfile -File docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.Tests.ps1`;
4. packet hash verification, retaining the already documented changed hash for
   `capture-candidate-snapshot.ps1`;
5. `git diff --check`; and
6. a clean status and diff review.

After committing the repair, create a disposable local clone from the current repository. The
clone must use the machine's normal Git configuration and must not reuse working-tree bytes. Run
the same full validator and snapshot test inside that clone. This is the acceptance proof for the
checkout-reproducibility claim.

If any current-tree or clone check fails, keep `codex/topic03-agent-topology`, do not push, and do
not delete or force-clean any worktree.

## 9. Expected repository changes

The implementation is expected to touch only:

- `.gitattributes`;
- `scripts/repair-evidence-byte-integrity.ps1` and its focused test;
- the 132 byte-restored historical files;
- one concise provenance-limitation record; and
- the implementation plan and changelog required by the repository workflow.

No content manifest, pinned SHA, selected runtime file, agent definition, or product behavior is
expected to change.

## 10. Acceptance criteria

1. The initial restoration preflight produces `838 exact / 132 recoverable / 5 unrecoverable /
   0 missing`; post-restoration and fresh-clone preflight produce
   `970 exact / 0 recoverable / 5 unrecoverable / 0 missing`.
2. All 132 recoverable paths equal their existing snapshot SHA-256 values.
3. All 838 exact paths remain byte-identical.
4. The five unrecoverable paths remain content-identical after EOL normalization and are explicitly
   documented.
5. Git reports `text: unset` for every tracked path under the three preservation directories.
6. No pinned hash or manifest value is changed.
7. The full validator exits zero in both the current repository and a fresh local clone.
8. The snapshot test reports all 22 assertions passing in both locations.
9. `git diff --check` exits zero.
10. The source branch remains present until all acceptance evidence is green.
