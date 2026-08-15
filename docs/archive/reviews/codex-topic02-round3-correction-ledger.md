# Codex — Topic 02 Round-3 Correction Ledger

```yaml
topic: 02-workflow-entry-task-lifecycle
correction_after_review_round: 3
round3_verdict: REOPEN_TOPIC_02
critical_findings: 0
important_findings: 1
important_findings_corrected: 1
active_authority_documents_corrected: 7
focused_mutation_assertions: 42
focused_validator_passes: 197
runtime_implemented: false
phase02_runtime_migration_pending: true
historical_phase00_evidence_preserved: true
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
staged_paths: 0
```

## 1. Immutable Round-3 evidence

| Artifact | SHA-256 | Meaning |
|---|---|---|
| `codex-peer-review-packet-topic02-round3.md` | `2D809ED7ED1776CB3E5A7FCEE7C6D28D33D72942E628DD770CC670995DAE6295` | Frozen Round-3 snapshot |
| `codex-peer-review-prompt-topic02-round3.md` | `B0A538E2ECFC4213E8FDE79FACD169047273A6C6E8428074FEF6598369B671C5` | Round-3 reviewer instructions |
| `codex-peer-review-response-topic02-round3.md` | `EAA5737DD5663A6B354BA13E821D0A7BEB8F308DE6D0A07DC809D22E25536D58` | Verbatim substantive `REOPEN_TOPIC_02` review |
| `codex-topic02-round2-correction-ledger.md` | `1A053EEDB6987AC6E61898DB63E63E8998A39E28B7EB4CCC28C50EB43FB3D348` | Round-2 correction record audited in Round 3 |

Round 3 reproduced every frozen hash, validator, source anchor, Git fact, historical pin, and
Phase-DAG edge. It kept R1-F1, R1-F2, and R1-F3 closed, but correctly kept R2-F1 open because
seven active clauses still contradicted their own Topic-03 supersession boundaries.

## 2. Finding adjudication

The Round-3 Important finding is `actionable`. A topology selected by Topic 03 could satisfy
the approved Topic-02 contract yet fail active Decision, Contract Summary, Acceptance, or
Expected Final Architecture clauses merely because it used renamed or merged roles, no worker
dispatch, flat dispatch, no LSP, no isolation, or responsibility-specific schemas/settings.

### R3-F1 / R2-F1 — Remaining active fixed-topology and unconditional-capability clauses

Corrections:

1. **Batch decision**
   - `spec/key/04-decision-log.md` now preserves KD-006 as a historical decision while
     explicitly superseding it as a global rule.
   - Dispatch syntax follows the effective task-tool schema selected by Topic 03. Batch and flat
     forms are both legitimate when selected; neither form selects a workflow class.

2. **LSP ownership**
   - `spec/07-retrieval-and-code-understanding.md` makes its Contract Summary responsibility-
     based: only selected contracts consuming symbol-aware retrieval require LSP.
   - Its repository-map behavior now belongs to a selected discovery responsibility, not a
     permanent Explorer.
   - `spec/key/03-token-quality-model.md` assigns LSP to selected LSP-consuming
     responsibilities rather than Explorer/Implementer/Reviewer names.

3. **Isolation and worker-set comparison**
   - `spec/08-isolation-and-concurrency.md` removes the active “four-worker constraint.”
     Topic 03 supplies worker names/count; optional preflight support agents are excluded from
     the selected worker-set comparison.
   - Active parallel-writer and partial-integration mechanics now use responsibility names
     rather than permanent Implementer/Verifier roles.
   - `spec/README.md` makes isolation conditional on selected concurrent writers and the
     observation responsibility.

4. **Structured-result acceptance**
   - Phase 01 now requires schemas only for selected spawned workers whose contracts require
     structured results, with no fixed name or count.

5. **Installer ownership and prerequisites**
   - Phase 05 acceptance now installs only selected aliases and optional settings consumed by
     the manifest.
   - LSP, isolation, concurrency, and provider prerequisites are conditional on the selected
     runtime path; L0/L1 checks only what that path consumes.

6. **False-negative guard**
   - The focused validator now rejects every exact active clause cited in Round 3 and requires
     the responsibility-based replacement semantics.
   - Eight new mutation scenarios cover global batch dispatch, fixed LSP role assignment,
     four-worker canary accounting, fixed final isolation, the LSP Contract Summary, Phase-01
     fixed schema roster, and both Phase-05 unconditional settings/prerequisite forms.

The corrections preserve fail-closed safety. A selected batch path must use its effective batch
schema; a selected LSP consumer must have the full capability conjunction; selected concurrent
writers must pass isolation preflight; selected stage barriers remain blocking; and every
selected structured-result producer keeps schema enforcement.

## 3. RED → GREEN evidence

The mutation suite was expanded before correcting the active documents:

```text
PASS Topic 02 validator self-test (42 assertions)
Topic 02 lifecycle: 177 passed, 0 warnings, 20 failed
```

The 20 failures covered missing replacement semantics and every retained active clause cited by
Round 3.

After correction:

```text
PASS Topic 02 validator self-test (42 assertions)
Topic 02 lifecycle: 197 passed, 0 warnings, 0 failed
```

Full repository validation:

```text
Results: 102 passed, 1 warnings, 0 failed
VALIDATION PASSED WITH WARNINGS
```

The sole warning remains the pre-existing approximate `template/.omp/RULES.md` budget
(`226 < 300`). `git diff --check` exits `0` with only the unrelated pre-existing
Phase-00 CRLF→LF advisory. Exact Round-3 contradiction strings now appear only as focused
validator sentinels, not in active specification authority.

## 4. Corrected snapshot hashes

| File | Corrected SHA-256 |
|---|---|
| `spec/key/04-decision-log.md` | `C0ADCF98E585B7551A877CBD2E123C1E8731804D18E8E518169B456A3A8440CF` |
| `spec/key/03-token-quality-model.md` | `3DCA01D082EB7D2FC5AAE70DE4178E8B820BB966B880F7A33E01B667DCD4D711` |
| `spec/07-retrieval-and-code-understanding.md` | `6EB18F308CFD3980C7847949DFEA88EF04D0E43A54638E94F7D0FE433C12C7F9` |
| `spec/08-isolation-and-concurrency.md` | `D6FFC77B35A8CF7846376AA263BC0DDAEE1560E3562567D4E1E0A2AFBB3F2A2C` |
| `spec/README.md` | `7203A7D3CC9D961A337A1FACB739B7D0520083736D39B07BEF5C80E1E74CD2C6` |
| `spec/phases/phase-01-runtime-correctness.md` | `CCC8F721706974C5668DE8E873DF836935696542410EBBF179566CA03112BC29` |
| `spec/phases/phase-05-installation-hardening.md` | `23AA93FA6ECF5132B6ACB9B0B2EE5290CB13CBA892488776C94D6EDAC9272413` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `574070DB43F6299CA83AFD96D51E3C2F902DACFE181CC720F84B3E6573BFD1AF` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `23A8FB352A716EE3D3BB8A17F155428E4DFEB2642125B2E09098BF72C7E2226C` |

## 5. Preserved boundaries and non-claims

- R1-F1, R1-F2, and R1-F3 remain closed.
- Topic 03 still owns roster, worker graph, role names, dispatch, capabilities, and review shape.
- Topic 04 still owns durable lifecycle state; Topic 08 still owns deeper triage.
- Phase 02 still owns future runtime projection and must create new current-product evidence.
- Phase-00 history and all seven historical pins remain unchanged.
- The pinned OMP checkout remains clean at its expected commit and version.
- No runtime prompt, product documentation, durable state, topology implementation, evaluation
  harness, candidate promotion, stage/index, commit, push, or PR was created.
- Round 4 must independently audit the full corrected snapshot. This ledger does not close
  Topic 02.
