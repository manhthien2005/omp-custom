# Codex — Topic 02 Round-1 Correction Ledger

```yaml
topic: 02-workflow-entry-task-lifecycle
correction_after_review_round: 1
round1_verdict: REOPEN_TOPIC_02
critical_findings: 0
important_findings: 3
important_findings_corrected: 3
runtime_implemented: false
phase02_runtime_migration_pending: true
historical_phase00_evidence_preserved: true
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
staged_paths: 0
```

## 1. Immutable Round-1 evidence

| Artifact | SHA-256 | Meaning |
|---|---|---|
| `codex-peer-review-packet-topic02-round1.md` | `B26118D339C644B75035CA0EFA8B1C443AE0CE7086B31877AEFD0A912EF7D20E` | Frozen Round-1 snapshot |
| `codex-peer-review-prompt-topic02-round1.md` | `470B915043336395E61C633DCA1FDB1837EA2ED9964ABAF6767CAD1B85122CE6` | Round-1 reviewer instructions |
| `codex-peer-review-response-topic02-round1.md` | `4821FC972FD2828BFDDC3C4167BF2A3AB39C7BB99ABA09B32FA5E12C3B9D06B9` | Verbatim substantive `REOPEN_TOPIC_02` review |
| `codex-peer-review-response-topic02-round1-attempt-01-blocked-input.json` | `01FB30C8687C268F9634D1E891C690604B0895F3D53CA78A86168DEE1B64EC7C` | Verbatim invalid Zeus input-format attempt; no content audit occurred |
| `codex-topic02-workflow-entry-task-lifecycle-changelog.md` | `B966276CE8C92CC78108921119415163B35D9CAE7EDBAA52C1C7B34FCD18C97B` | Pre-correction change ledger reviewed in Round 1 |

Round 1 is not overwritten or reinterpreted as acceptance. The first specialized Zeus attempt
stopped before substantive review because it required a different role-specific packet schema.
The subsequent independent Codex peer verified every supplied hash/source/check and returned
`REOPEN_TOPIC_02` with three Important findings.

## 2. Finding adjudication

All three findings are `actionable`. None is a contract misread, trade-off, or noise.

### F1 — Verification obligations outside task-contract lock

**Round-1 evidence:** the packet required objective, scope/authority, mandatory criteria, and
verification obligations, while the canonical spec, approved design, and KD-026 named only the
first three groups.

**Correction:** the design, canonical `spec/04`, KD-026, DNA projection, and active Phase 02
migration now make required verification and review obligations part of the accepted task
contract. A material change to those locked gates opens a linked task just like a material
objective/scope/authority/criteria change. Ambiguity in required gates remains in clarification.

**Regression guard:** `T02-CANONICAL-REQ-11`, `T02-DESIGN-REQ-1`,
`T02-DECISION-REQ-1`, and `T02-DNA-REQ-8`; the mutation self-test removes the canonical gate
phrase and requires `T02-CANONICAL-REQ-11` to fail.

### F2 — DNA mandated fixed topology and unconditional Orchestrated review

**Round-1 evidence:** `spec/key/01-dna.md` called the former four-role roster the topology
“gene,” made Verifier separation permanent, and required review in every Orchestrated task.

**Correction:** DNA's invariant is now main-session Tech Lead ownership. Topic 03 owns the final
worker graph, roster, depth policy, and dispatch conditions. The former roster is explicitly a
non-authoritative pre-Topic-03 hypothesis retained as migration/source history. Independent
evidence is contract-gated rather than tied to a named permanent Verifier. Review is
contract/risk-gated; Orchestrated classification alone does not force it.

**Regression guard:** `T02-DNA-REQ-6/7` and `T02-DNA-BAN-4/5/6`; the mutation self-test adds the
old fixed-depth wording and requires `T02-DNA-BAN-4` to fail.

### F3 — Phase 06 and `spec/13` hard-coded the topology they disclaimed

**Round-1 evidence:** both surfaces required an exact four-agent/four-role set while the Phase
06 exit criterion and Topic 02 authority assigned topology to Topic 03.

**Correction:** L0/L1 consume the Topic 03-selected topology manifest. They derive the selected
worker set, actually referenced model roles, required stage barriers, and capabilities from
that manifest. Batch, isolation, LSP, and writer-concurrency assertions activate only for the
selected path that consumes them. Effective command execution remains mandatory for a selected
verification role whose contract requires it. The independent invariant that `tech-lead` must
not be discovered as a second spawnable project worker remains intact.

**Regression guard:** `T02-EVAL-REQ-5/6/7`, `T02-EVAL-BAN-1/2`,
`T02-PHASE06-REQ-5/6/7`, and `T02-PHASE06-BAN-1/2/3/4`; mutation self-tests reintroduce exact
four-worker prose in each surface and require failure.

## 3. Corrected snapshot hashes

| File | Round 1 | Corrected current |
|---|---|---|
| `docs/superpowers/specs/2026-08-12-topic-02-workflow-entry-task-lifecycle-design.md` | `DADD361135629B210AFF0F581E3B27FDFD2AB869D04E18476B59691106CF0AFE` | `1A9F0DD9449B18FF56F870EA0F0B57739E2F7D494429269C6BAAFF1F22A9204A` |
| `spec/04-workflow-sizing.md` | `3B5EE8686C5B6FF96E0D573D2C357F7F1922B70D40CE4CBE61C01AABEAF47481` | `DBD99DCD3871142B8C22EE6EEBF51AC833097CB8841C8E9E65DA6F8A5FF273CF` |
| `spec/13-validation-and-evaluation.md` | `E51C32802664040F84144A5A95887E22468234BEDFD16F0A27A4D8F08DF38F57` | `CFE96317B33ACDEAB81D3E853DDDE3B72955EAC91E5849E23112C2F46655A23D` |
| `spec/key/01-dna.md` | `745DFEFBFDDDB638F503CA108DA80A3CFDF27F92620213FD315D0F152D19D73E` | `81FDC69E8A1563EC17C9215537AA92F61AC91BFC8FCBE17FA96F1F61C319E544` |
| `spec/key/04-decision-log.md` | `4F4C6A103BB2815C5CA2335A460C42754946BF2623869E9B09A7C83B284AE29D` | `64FD57060E38249A241D657C3E6520023B876985E7D858106BD801687FBE9760` |
| `spec/phases/phase-02-core-orchestration.md` | `CA0E002E66D33B9F7F3AAE681D272D8C053BC6AAEA3282DE336D58E6FE670E05` | `0F98830CF5E3E47892FD9B00B1309F31CF321FD7E8C550DB86AF0E863AD3F0BC` |
| `spec/phases/phase-06-evaluation.md` | `D276240CE344816B4243EF5C186CE67A641D83D6E5F2E87B14EFF30DC29CFEAA` | `0CA71FD4CDA5708B48E13C7EC4BA99202CD2027A722D71E056E0A96375AE4ABD` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `C44300F726522874B2EFE88AD2E266470C75F063B6740192C5ACA989A8882DB9` | `FFEFDD3F98002E8F1F23D9955FAE2F67BE79805991F706B69B26D567340940FE` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `743B699780B45BB835011D0D14B9C6605B59E3BAAA665962880D8A6317448AC7` | `38848B5F70CF4860CC5ED3EE567F1CB1803E198A492D4CA3F541485FF0A59814` |

All other Round-1 load-bearing files remain byte-identical. The active Phase 02 migration is
above `## Appendix A — Superseded Pre-Topic-02 Plan (Reference Only)`; old fixed-roster text in
that explicitly superseded appendix remains historical evidence and is not active authority.

## 4. RED → GREEN evidence

After the new guards were installed but before authority correction:

```text
PASS Topic 02 validator self-test (12 assertions)
Topic 02 lifecycle: 61 passed, 0 warnings, 20 failed
```

The failures covered the missing contract-gate lock, fixed DNA topology/review, and exact-count
Phase 06/`spec/13` rules.

After correction:

```text
PASS Topic 02 validator self-test (12 assertions)
Topic 02 lifecycle: 81 passed, 0 warnings, 0 failed
```

Full repository validation:

```text
Results: 102 passed, 1 warnings, 0 failed
VALIDATION PASSED WITH WARNINGS
```

The sole warning remains the pre-existing approximate `template/.omp/RULES.md` budget
(`226 < 300`). `git diff --check` exits `0` with only the unrelated pre-existing
`spec/phases/phase-00-foundation.md` CRLF→LF advisory. The active-authority contradiction scan
returns no match after excluding the Phase 02 appendix by its explicit supersession heading.

## 5. Preserved source and historical boundaries

- Pinned OMP remains clean at `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.
- Slash expansion and handoff source claims from Round 1 are unchanged.
- All seven Phase 00 runtime/evidence pins remain byte-identical to the Round-1 packet.
- No runtime prompt, product documentation, durable state, topology implementation, evaluation
  harness, candidate promotion, phase dependency, stage/index, commit, push, or PR was created.
- Round 2 must independently verify these claims and the corrected hashes; this ledger does not
  close Topic 02.
