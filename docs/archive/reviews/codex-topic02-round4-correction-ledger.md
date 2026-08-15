# Codex — Topic 02 Round-4 Correction Ledger

```yaml
topic: 02-workflow-entry-task-lifecycle
correction_after_review_round: 4
round4_verdict: REOPEN_TOPIC_02
critical_findings: 0
important_findings: 1
important_findings_corrected: 1
active_authority_documents_corrected: 7
focused_mutation_assertions: 56
focused_validator_passes: 224
runtime_implemented: false
phase02_runtime_migration_pending: true
historical_phase00_evidence_preserved: true
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
staged_paths: 0
```

## 1. Immutable Round-4 evidence

| Artifact | SHA-256 | Meaning |
|---|---|---|
| `codex-peer-review-packet-topic02-round4.md` | `0EC39794C5E11C4B790DD937C59B02FB35AA11240DCBFB8C52995A9F79BAA63E` | Frozen Round-4 snapshot |
| `codex-peer-review-prompt-topic02-round4.md` | `111D33A676615F24181131F085D7BEFF8C22F3DF9613144376E4EA261A4BD8FB` | Round-4 reviewer instructions |
| `codex-peer-review-response-topic02-round4.md` | `7015D11AF9A8CA3880468D9EADFAE28C1BC1A8AEAEF792EF1AD77557465D2FE7` | Verbatim substantive `REOPEN_TOPIC_02` review |
| `codex-topic02-round3-correction-ledger.md` | `F0C61C044EB62C3151B2DD097E80E418FF4B5A77DF14798E10DB5E390169B305` | Round-3 correction record audited in Round 4 |

Round 4 reproduced every packet-listed hash, historical pin, validator, source anchor, Git
fact, and Phase-DAG edge. It independently confirmed the Round-3 corrections at KD-006,
spec 07, the token model, spec 08, the spec README, and Phase 05. It correctly reopened the
shared projection finding because later active DNA genes, KD-002/KD-004, Phase-01 deliverables,
and Phase-06/spec-13 validation clauses still restored fixed schema, roster, or skill-count
authority.

## 2. Finding adjudication

The Round-4 Important finding is `actionable`. The L2 DNA history fence did not govern later
active genes, and several active acceptance clauses still rejected a legitimate Topic-03
manifest with inline responsibilities, a merged or renamed role, responsibility-specific
schemas, or a selected skill set different from the former three-skill baseline.

### R4-F1 / reopened R1-F2, R1-F3, R2-F1, R3-F1 — Complete selected-contract projection

Corrections:

1. **DNA contract layer**
   - L3 now requires frontmatter only for each selected spawned worker with a structured result
     contract; inline and main-session producers use their equivalent enforced boundary.
   - Producer tables are responsibility-based and conditional rather than a permanent four-role
     roster.

2. **DNA retrieval, discipline, isolation, and judgement layers**
   - L4 assigns LSP and read behavior to selected consuming responsibilities.
   - L5 attaches autoloaded discipline only to selected consumers and removes the fixed
     Implementer/Verifier/Reviewer assignment and multiplier.
   - L6 isolates selected parallel writers only; observation and sole-writer rows are expressed
     by responsibility, and failed integration suppresses the selected verification mechanism.
   - L7 sends failure to the selected remediation owner and keeps review contract/risk-gated.

3. **Decision authority**
   - KD-002 requires `output:` frontmatter only for a selected spawned worker whose contract
     requires a structured result; inline/main-session producers use their selected boundary.
   - KD-004 lints every selected agent output block and the equivalent selected non-agent
     boundary, not an assumed roster.
   - Later active KD examples now use selected discovery, review, evidence, and remediation
     responsibilities. Cost tables are explicitly illustrative rather than topology authority.
   - KD-017 makes pressure/activation fixtures apply to every skill selected by the runtime
     manifest; the former three names are examples, not a required set or count.

4. **Phase and evaluation acceptance**
   - Phase 01 delivers selected worker adapters and selected command contracts; inline schemas
     are explicit overrides rather than a default deliverable.
   - Phase 06 now carries an explicit Topic-02 supersession boundary and derives structured
     producers, workers, skills, aliases, barriers, and capabilities from the selected manifest.
   - Spec 13 likewise derives discovery from the selected manifest and no longer requires all
     three former skills or a fixed completion-result schema name.

5. **Breadth corrections beyond the cited lines**
   - Spec 06 removes its remaining unconditional “each worker” language and assigns incremental
     output/evidence limits to selected result producers.
   - Spec 11 labels its three-item inventory as candidate input, requires autoload only when a
     selected contract consumes it, and derives trigger coverage from the selected skill set.

6. **False-negative guard**
   - The focused validator now rejects every exact active clause cited in Round 4 plus the two
     semantic equivalents found during the breadth audit in specs 06 and 11.
   - Fourteen new mutation scenarios since Round 3 cover fixed DNA schemas/skills/isolation/
     remediation, universal KD schemas and output lint, fixed Phase-01 deliverables, universal
     Phase-06 schemas/skill counts, fixed spec-13 skill discovery, unconditional spec-06 worker
     contracts, and unconditional/fixed-count spec-11 skill activation.

All selected-path safety remains fail-closed: any selected structured result must validate at
its enforced boundary; selected stage barriers block; selected LSP/bash consumers retain their
capability conjunctions; and selected parallel writers retain isolation preflight.

## 3. RED → GREEN evidence

The Round-4-specific guard was expanded before correcting the cited active documents:

```text
PASS Topic 02 validator self-test (53 assertions)
Topic 02 lifecycle: 198 passed, 0 warnings, 21 failed
```

After the cited corrections it reached:

```text
PASS Topic 02 validator self-test (53 assertions)
Topic 02 lifecycle: 219 passed, 0 warnings, 0 failed
```

A broader semantic search then found the same root cause in specs 06 and 11. Their regression
sentinels were added before prose correction:

```text
PASS Topic 02 validator self-test (56 assertions)
Topic 02 lifecycle: 219 passed, 0 warnings, 5 failed
```

Final focused evidence:

```text
PASS Topic 02 validator self-test (56 assertions)
Topic 02 lifecycle: 224 passed, 0 warnings, 0 failed
```

Full repository validation:

```text
Results: 102 passed, 1 warnings, 0 failed
VALIDATION PASSED WITH WARNINGS
```

The sole warning remains the pre-existing approximate `template/.omp/RULES.md` budget
(`226 < 300`). `git diff --check` exits `0` with only the unrelated pre-existing Phase-00
CRLF→LF advisory.

## 4. Corrected snapshot hashes

| File | Corrected SHA-256 |
|---|---|
| `spec/key/01-dna.md` | `10B842F711557FD67B9589CBAD7A97B93990730062E1D7A8339D59C81BE7D1CE` |
| `spec/key/04-decision-log.md` | `D7EF3026944F2380F8AFED74BCC0884688A8533DCE3F4A25B1B972F25F844C81` |
| `spec/06-structured-output.md` | `F1EB8F518EC52FCB1D07B811874912AC8311B330CDE4F77AA2BA3BF2D00F6087` |
| `spec/11-skills-rules-and-quality-gates.md` | `380BEC7B7D60CF3268C753B07F3FCFB35EA78564577D4058357C56C2F0F5D9CB` |
| `spec/13-validation-and-evaluation.md` | `B62B1F6C0F33E114953A86B5B3F66EA0D209E851E4328D96A0A1DB58E35E183A` |
| `spec/phases/phase-01-runtime-correctness.md` | `36EB4B9ADE7F04700E5AB1122148AF40E254D0AA437C3E56468986EB857E8C1E` |
| `spec/phases/phase-06-evaluation.md` | `7E863B37CEA7459883D1B4D193B3ED76629A63FA0FDAF4096E6B276BE588E4D4` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `E92E936340C3B12F4D056A576F45646B9C84D4A382FAC903CE486BE82E3B4503` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `7669907C7BFB9138635882AA2755D26F9578CD890D4F45E8D1A1EB3B35828B5D` |

## 5. Preserved boundaries and non-claims

- R1-F1 remains closed; its task-contract verification/review lock was not weakened.
- Topic 03 still owns roster, worker graph, role names, dispatch, capabilities, schemas, and
  selected skill set. Topic 02 supplies classification and lifecycle semantics only.
- Topic 04 still owns durable lifecycle state; Topic 08 still owns deeper triage.
- Phase 02 still owns future runtime projection and must create new current-product evidence.
- Phase-00 history and all seven historical pins remain unchanged.
- The pinned OMP checkout remains clean at its expected commit and version.
- No runtime prompt, product documentation, durable state, topology implementation, evaluation
  harness, candidate promotion, stage/index, commit, push, or PR was created.
- Round 5 must independently audit the full corrected snapshot. This ledger does not close
  Topic 02.
