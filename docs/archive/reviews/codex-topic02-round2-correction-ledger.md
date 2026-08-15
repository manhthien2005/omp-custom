# Codex — Topic 02 Round-2 Correction Ledger

```yaml
topic: 02-workflow-entry-task-lifecycle
correction_after_review_round: 2
round2_verdict: REOPEN_TOPIC_02
critical_findings: 0
important_findings: 1
important_findings_corrected: 1
active_authority_projection_files_corrected: 19
focused_mutation_assertions: 34
focused_validator_passes: 177
runtime_implemented: false
phase02_runtime_migration_pending: true
historical_phase00_evidence_preserved: true
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
staged_paths: 0
```

## 1. Immutable Round-2 evidence

| Artifact | SHA-256 | Meaning |
|---|---|---|
| `codex-peer-review-packet-topic02-round2.md` | `7823E99DB0E917C267FF8BD0C87F53B463056A50A842BB1434E69A56D732008A` | Frozen Round-2 snapshot |
| `codex-peer-review-prompt-topic02-round2.md` | `7BA1D68228F1D0E9A148A6F24FFDCF75BFB4F6A91B6FCCC4A5154C0E62282FE1` | Round-2 reviewer instructions |
| `codex-peer-review-response-topic02-round2.md` | `A3719F5823E933FA4BDEC0E7BA9D3E686C279A57E5091BF36D421E2F6CE8AB32` | Verbatim substantive `REOPEN_TOPIC_02` review |
| `codex-topic02-round1-correction-ledger.md` | `BE9CE1AAA904D2D03E06973364FA7294690DEA5B59B63FAD026F59F8E7B4FAC9` | Round-1 correction record audited in Round 2 |
| `codex-peer-review-response-topic02-round1.md` | `4821FC972FD2828BFDDC3C4167BF2A3AB39C7BB99ABA09B32FA5E12C3B9D06B9` | Immutable Round-1 substantive review |

Round 2 is not overwritten or reinterpreted as acceptance. The independent Codex peer
reproduced the frozen hashes, OMP source anchors, validators, Git identity, historical pins, and
all three Round-1 corrections. It closed R1-F1 through R1-F3, then returned
`REOPEN_TOPIC_02` for one new Important defect across active authority.

## 2. Finding adjudication

The Round-2 finding is `actionable`. It is not a preference for a particular roster or review
style.

### R2-F1 — Active specs retained permanent named-role and fixed-topology authority

**Round-2 evidence:** although the Topic-02 DNA, `spec/03`, `spec/13`, and Phase 06 had
become topology-neutral at their reviewed anchors, other active prose still said verification
was a separate agent, made a named Verifier hard-required, mandated a flat four-worker
topology or batch precondition, and preserved DR-8 “Keep separate.” The focused validator
passed because it did not scan those equivalent semantics.

**Root cause:** the initial correction changed the directly reviewed contract surfaces but did
not project the same ownership boundary through every active architecture, capability,
installation, migration, and phase document. The invariant and one possible implementation
mechanism were still conflated.

**Correction:**

- Topic 03 is now the sole authority for worker names, roster size, worker graph, verification
  mechanism, review shape, aliases, and topology-specific capability assignment.
- Independent verification remains mandatory whenever the accepted task contract requires it,
  and required evidence must come from a non-author. A permanent role named Verifier or a
  separate child session is one possible Topic-03 mechanism, not a Topic-02 mandate.
- `task.batch`, parallel isolation, `blocking: true`, effective command execution, LSP
  access, recursion depth, autoloaded skills, schemas, model aliases, and owned settings apply
  only when selected contracts consume those capabilities.
- Sequential Orchestrated execution remains valid. Orchestrated means structural decomposition
  into at least two independently verifiable work units plus an integration contract and
  cross-boundary verification; it does not mean parallel or fixed-roster execution.
- Former four-role tables outside the Topic-02 contract are explicitly fenced as historical,
  baseline, or pre-Topic-03 candidate mappings and cannot act as current execution authority.
- DR-8 is reopened under KD-026 and Topic 03 instead of preserving “Keep separate” as a
  permanent named-role decision.

The correction does not weaken evidence discipline. It separates the invariant—independent
non-author evidence when required—from one possible mechanism—a separate named worker.

### Corrected active-authority surfaces

| Concern | Files corrected |
|---|---|
| Architecture and ownership | `spec/01-target-architecture.md`, `spec/README.md` |
| Context, token, and output contracts | `spec/05-context-and-token-model.md`, `spec/06-structured-output.md`, `spec/key/03-token-quality-model.md` |
| Retrieval, isolation, and routing | `spec/07-retrieval-and-code-understanding.md`, `spec/08-isolation-and-concurrency.md`, `spec/09-model-routing.md` |
| Verification, skills, installation, and security | `spec/10-verification-and-review.md`, `spec/11-skills-rules-and-quality-gates.md`, `spec/12-installation-and-rollback.md`, `spec/15-security-and-failure-recovery.md` |
| Evaluation and migration | `spec/13-validation-and-evaluation.md`, `spec/16-migration-plan.md` |
| Phase projections | `spec/phases/phase-01-runtime-correctness.md`, `phase-03-context-efficiency.md`, `phase-04-quality-system.md`, `phase-05-installation-hardening.md`, `phase-06-evaluation.md` |

`spec/03-agent-topology.md` is intentionally not rewritten again: its top-level authority
fence already says its former roster sections are pre-Topic-03 hypotheses and are not execution
authority until Topic 03 adjudicates them. Phase 00 remains historical evidence; Phase 02
Appendix A remains an explicitly historical baseline. Neither is current Topic-02 authority.

## 3. Corrected snapshot hashes

| File | Corrected SHA-256 |
|---|---|
| `spec/01-target-architecture.md` | `71E48A4320F21A784E87F82EBC56727C6976C14085C5A1DE14C787E8A5BD5A92` |
| `spec/05-context-and-token-model.md` | `A341A741908892572DF815EF5150D4DCFD539B27C4A9B9959C51B7B7DBCA1FE1` |
| `spec/06-structured-output.md` | `7259C01CF0BA908017F7B7B3560116B903FFE91B715F1C47C0D981B42A806D8C` |
| `spec/07-retrieval-and-code-understanding.md` | `5E2D09DFDF2B5DC388D02B975FC588704BCCD1641D457607599EA55AEA14E0AD` |
| `spec/08-isolation-and-concurrency.md` | `3F085C04D261B68F3CD5E064CC78282CC3F16C7F3717F959A10B6CD09424C50C` |
| `spec/09-model-routing.md` | `BA9E643BB2A10682B11EE4BF4C6868A5C4F05FD6126CC48BDDF2313EBEFFAA71` |
| `spec/10-verification-and-review.md` | `C47CA16A22907EA2C953E4E63C5405D5B6EF925A6E0207544FB6760E0814B9FB` |
| `spec/11-skills-rules-and-quality-gates.md` | `8651DADDC8AD852B7C8BC141DF0BD8897CC498EE5AE9448A167C757964826A89` |
| `spec/12-installation-and-rollback.md` | `0C98FC3A49DF2E2FC5801706C1646C44B8B91E23DDB59B2B9BAD172E0D60DD1E` |
| `spec/13-validation-and-evaluation.md` | `0888C0E5A50C3E3928B50EE5E1FF830CA48B890CFDBA838AE13CA1BB4CFA0C14` |
| `spec/15-security-and-failure-recovery.md` | `BAE8C825C1BB6D87717F6B2D0B9D7EBAF97DE2C04BDD08768E5DE248062EE250` |
| `spec/16-migration-plan.md` | `C02CD27D1C294744CAB8C2DFEB638F1A91AF723416E5BDB72BAF9A34F2FD027D` |
| `spec/README.md` | `B0F4759562580700DBD82D01CFA1DB21D19CC9B3C82808C157DC6A1353CB5283` |
| `spec/key/03-token-quality-model.md` | `339D6B99C0E252E2328F9B7F7A7D38DA9E58FDDB76C7AF3B1B76E79EE6CA1E2F` |
| `spec/phases/phase-01-runtime-correctness.md` | `39E57565B5315530CDB74120E182BBCF24EC32DEA9C705B831DD15971CBE73F5` |
| `spec/phases/phase-03-context-efficiency.md` | `20C763027F3A53F2F3F5CD2A5CEDC00FB5F90C68DB2D8B89D6B3D35FF78F85CA` |
| `spec/phases/phase-04-quality-system.md` | `932F648757B2B2860EBB3CECC92C53BA789570F8ACBB1535CB2B6CA6B21F75A5` |
| `spec/phases/phase-05-installation-hardening.md` | `E586E22B800DE1A75D7397B0ACB9EBEF16CD220E8E05A623F74E1FDD123A525F` |
| `spec/phases/phase-06-evaluation.md` | `973FB9A69C411A9DB1E750FEB592F2C5F9B81F84282FB6FF44153EF17B815B27` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `D75F94A7CBBF58613891C714289666A7585B890FCDFE3CBCB0C05CAD52B99CAC` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `31B1AE751FE7EEE1C38281AA612B56FE086C1403AD18DA2B8143F165660EDC03` |

## 4. RED → GREEN evidence

The guard was expanded in stages so every newly discovered equivalence first failed against the
then-current prose:

```text
Initial Round-2 guard:
PASS Topic 02 validator self-test (17 assertions)
Topic 02 lifecycle: 82 passed, 0 warnings, 22 failed

Direct reviewer citations corrected:
PASS Topic 02 validator self-test (17 assertions)
Topic 02 lifecycle: 104 passed, 0 warnings, 0 failed

Expanded active-authority audit, before corresponding prose corrections:
PASS Topic 02 validator self-test (28 assertions)
Topic 02 lifecycle: 104 passed, 0 warnings, 46 failed

Second expansion, before corresponding prose corrections:
PASS Topic 02 validator self-test (31 assertions)
Topic 02 lifecycle: 150 passed, 0 warnings, 19 failed

Final expansion, before last prose corrections:
PASS Topic 02 validator self-test (34 assertions)
Topic 02 lifecycle: 171 passed, 0 warnings, 6 failed

Corrected final focused snapshot:
PASS Topic 02 validator self-test (34 assertions)
Topic 02 lifecycle: 177 passed, 0 warnings, 0 failed
```

The 34 mutations cover the canonical Topic-02 contract, DNA projection, and every active surface
where a permanent named role, exact roster, unconditional parallel batch, or topology-owned
capability could regain authority.

Full repository validation on the corrected snapshot:

```text
Results: 102 passed, 1 warnings, 0 failed
VALIDATION PASSED WITH WARNINGS
```

The sole warning remains the pre-existing approximate `template/.omp/RULES.md` budget
(`226 < 300`). `git diff --check` exits `0` with only the unrelated pre-existing
`spec/phases/phase-00-foundation.md` CRLF→LF advisory. A final exact-phrase contradiction scan
over active authority returns no matches.

## 5. Preserved boundaries and non-claims

- Repository identity remains `main` at
  `62fecf277dc9d5e47d06319387eac747462214c1`, with zero staged paths.
- Pinned OMP remains clean at `3a8591a8af5b6d200088d12ca75a5517cb064fa8`
  (coding-agent version 17.2.10).
- Slash expansion and handoff source claims from prior rounds are unchanged.
- All seven Phase-00 runtime/evidence pins remain byte-identical.
- No runtime prompt, product documentation, durable state, topology implementation, evaluation
  harness, candidate promotion, phase dependency, stage/index, commit, push, or PR was created.
- Round 3 must independently verify the complete contract and corrected snapshot. This ledger
  does not close Topic 02.
