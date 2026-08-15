# Codex — Topic 02 Round-6 Correction Ledger

```yaml
topic: 02-workflow-entry-task-lifecycle
correction_after_review_round: 6
round6_verdict: REOPEN_TOPIC_02
critical_findings: 0
important_findings_in_recorded_response: 2
recorded_findings_corrected_pending_review: 2
semantic_equivalent_breadth_clusters_corrected_pending_review: 14
focused_mutation_assertions: 107
focused_validator_passes: 449
phase00_tests: 329
full_validator_passes: 102
full_validator_warnings: 1
runtime_implemented: false
phase02_runtime_migration_pending: true
historical_phase00_evidence_preserved: true
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
repository_branch: main
staged_paths: 0
```

## 1. Immutable Round-6 evidence

| Artifact | SHA-256 | Meaning |
|---|---|---|
| `codex-peer-review-packet-topic02-round6.md` | `05C8FE205D8714FE421EDB98DC1FFFFB306317E9D529E02BC4FF1F138DA21291` | Frozen Round-6 snapshot |
| `codex-peer-review-prompt-topic02-round6.md` | `86138C60EADA88DEC773CDEB4E8E019E2D4EBDF5369A19BF486BECFD83FD1FA4` | Round-6 reviewer instructions |
| `codex-peer-review-response-topic02-round6.md` | `4052DD966D5A3FC57B1833ABA3C4FFC3C36D5D121E354508B7A20667ED4252C9` | Verbatim substantive `REOPEN_TOPIC_02` review |
| `codex-topic02-round5-correction-ledger.md` | `9693849ECF51FD300904438D90824690A0B5E18C0EF9D5251A5011F92964A1FD` | Round-5 correction record audited in Round 6 |

The recorded Round-6 response reproduced every frozen hash, source pin, validator, Git fact,
history fence, and reciprocal Phase-DAG edge. It found two Important defects: active summaries
projected only part of the four independent LSP registration gates, and the Context7-unavailable
branch contradicted the named/disclosed skip contract.

After correcting those two findings, the authoring pass continued the required semantic-
equivalent breadth audit against pinned OMP source. That pass found additional selected-path
false-acceptance shapes outside the original focused guard. They are listed below so Round 7 can
falsify them independently. None of these corrections is treated as acceptance evidence.

## 2. Recorded Round-6 findings

### R6-F1 — Complete four-gate LSP projection

The correction now names the complete registration conjunction everywhere it carries authority:

1. the selected tool allowlist contains `lsp`;
2. effective `task.enableLsp == true`;
3. the parent session has not disabled LSP and is not in plan mode; and
4. effective `lsp.enabled == true`.

DNA, target architecture, runtime semantics, spec 07 summaries, governance, install ownership,
Phase 01, and Phase 06 now project all four conditions. A selected LSP-consuming contract stops
before dispatch or acceptance if any condition is unmet. A topology that does not select LSP is
not forced to enable it.

### R6-F2 — Named and disclosed Context7/Web skips

`context7_unavailable` is now a permitted, disclosed level-4 skip. It selects the next fitting
accessible source rather than silently looping to an earlier level. `web_unavailable` is the
corresponding disclosed level-5 reason; it does not satisfy a freshness contract without an
authoritative source. DNA, specs 05/07/13, Phase 06, and the retrieval dossier agree.

## 3. Semantic-equivalent selected-path corrections

### 3.1 Selected manifest, topology, schemas, and skills

- Active Phase/KD/DNA clauses no longer require a permanent five-file/four-worker roster, one
  output schema per worker, or all three historical skills.
- Topic 03 supplies the selected producers, aliases, capabilities, schemas, and autoload skills.
  Validation checks exactly that selected manifest.
- A selected structured producer requires full schema lint before dispatch and
  `structuredOutput.status: valid` at acceptance. `unavailable`, `invalid`, and overridden
  results remain unvalidated; malformed schemas cannot continue as plausible success.

### 3.2 Effective model and effort identity

- E2 is closed and source-authoritative: missing/unknown aliases and unavailable models hard-fail
  with no fallback; project values win over global values.
- Selected per-spawn effort requires effective `task.enableEffort: true`. If exact effort is a
  contract element, `task.maxEffort` must admit it and the returned `resolvedModel` effort suffix
  must match.
- Preflight reconciles `task.agentModelOverrides`. Acceptance rejects
  `resolvedModelIsFallback: true` and compares returned `modelRole` plus `resolvedModel` with the
  reconciled expected identity.
- That exact comparison is necessary because credential fallback to the parent model is not
  marked by `resolvedModelIsFallback`; the flag detects retry fallback only. The investment
  thesis priority table now states both gates rather than implying that reading one flag closes
  every misroute.

### 3.3 Partial yields and runtime transformations

- The 1.5× `task.softRequestBudget` force-stop returns a partial yield. It is nonterminal and
  cannot satisfy completion or acceptance; recovery or redispatch is required.
- Plan mode rewrites workers to a planning/read-only tool set and removes isolation controls.
  It therefore selects a distinct planning-only contract and cannot satisfy selected mutation
  or fresh-command work.
- Selected nested delegation preflights remaining `task.maxRecursionDepth`; a result from a
  child whose `task` tool was stripped cannot satisfy that contract. Pinned source closes the
  old OQ-3: depth 1 retains `task`; depth 2 reaches the default ceiling and loses it.

### 3.4 Retrieval capability settings and LSP outcomes

- Selected `glob`, `grep`, `ast_grep`, and `web_search` consumers require their corresponding
  effective settings. The guard includes `astGrep.enabled`, whose default is false.
- Passing all four LSP registration gates establishes tool presence only. It does not establish
  an applicable/configured language server or a successful semantic call.
- Pinned `lsp/index.ts:2145-2160` returns ordinary tool content with
  `details.success: false` when no matching/configured server applies. Every selected LSP
  contract now rejects that result and every failed required LSP call. Only remediation or an
  explicit, reconciled, revalidated non-LSP contract may continue.

## 4. Authority and source-summary corrections

- `docs/research/authority-map.md`, `docs/research/mechanism-matrix.md`,
  `docs/research/final-adoption-plan.md`, and `docs/final-report.md` now state their historical or
  non-authority status explicitly. Earlier ADOPT/final wording cannot select current topology,
  fallback, or capability behavior.
- The Serena research report now treats its former degraded LSP branch as research evidence and
  points current behavior to an explicitly different reconciled/validated non-LSP contract.
- The rejected-mechanism and upstream registries describe Serena as a capability-level rejection
  only; they no longer claim that OMP LSP is unconditionally sufficient.
- The Context7 and retrieval dossiers use current section anchors and the named/disclosed skip
  rules. The OMP dossier records the four LSP registration gates plus applicable-server/result
  success as separate conditions.
- Source summaries now distinguish runtime facts from current decision authority rather than
  relying on an inferred research fence.

## 5. Phase-00 historical evidence versus later-topic authority

Topic 02 legitimately superseded the current bytes of `docs/policies/model-routing.md`, while
Phase-00 T-00.3 still binds the original destination hash in its immutable conclusion. Restoring
the old fixed-role document would reintroduce a current Topic-02 contradiction; rewriting the
conclusion would corrupt historical evidence.

The Phase-00 helper therefore permits exactly one declared later-topic supersession:

- path: `docs/policies/model-routing.md`;
- immutable historical hash:
  `9E348E097D6CD65B102C97BDE160E30C4ECADCB7A74FB405FBC274B4E8ABD8A1`;
- required current declaration and Topic-02/E2 markers.

Any undeclared destination mutation still fails. Any mutation of the recorded historical hash
still fails. `docs/evidence/phase-00/T-00.3/conclusion.yml` remains byte-identical at
`B0792E6109C9FB767F4B821EF6F56B2BE655B52C9C244865033C2F25E842834F`.

## 6. RED → GREEN evidence

The supersession tests were added before the helper correction. The focused Phase-00 suite was
red because the canonical repository could not yet distinguish a declared later-topic
supersession from arbitrary drift. After the narrow helper and reference correction:

```text
T-00.3: 28 passed, 0 failed
Phase 00: 329 passed, 0 failed
```

The final breadth scan found the stale investment-thesis shorthand. Its mutation was written
before its guard and failed as intended:

```text
FAIL [T02-TEST] [incomplete-investment-model-identity-check]
expected exactly one FAIL 'T02-INVESTMENT-REQ-5'
```

After correcting the guard and table:

```text
PASS Topic 02 validator self-test (107 assertions)
Topic 02 lifecycle: 449 passed, 0 warnings, 0 failed
```

Full repository validation:

```text
Results: 102 passed, 1 warnings, 0 failed
VALIDATION PASSED WITH WARNINGS
```

The sole warning remains the pre-existing approximate `template/.omp/RULES.md` budget
(`226 < 300`). `git diff --check` exits `0` with only the pre-existing Phase-00 CRLF advisory.
The Phase DAG has nine expected reciprocal edges and zero failures.

## 7. Selected corrected hashes before Round-7 freeze

| File | SHA-256 |
|---|---|
| `spec/01-target-architecture.md` | `C4B18601B774CF107C3FFF5911A90B24E0C6F73F21858A82F9B4D0E06B6CF490` |
| `spec/02-runtime-semantics.md` | `A9E8CA2535341B5B62AC888890D7CC11590B4AFBE279B6C4F58D658BF8D6B168` |
| `spec/05-context-and-token-model.md` | `755C148BD99854BF89F6C25B8044DE2E00F57C4496F517A6081C2A02929E8F3C` |
| `spec/06-structured-output.md` | `4929147AD7A282FCCD2A548E1D35F234E78F25795AE8AE25AE3FEA7BE2CFCE39` |
| `spec/07-retrieval-and-code-understanding.md` | `8B056577F445BDA410EC6AEF8F5340E82BB804ED39F127C8AC2EAC14A029BCE3` |
| `spec/08-isolation-and-concurrency.md` | `5B5FFDDBEA310A3C61CF4DAE6B0027E5243E5A05155944E87AF22373948786C4` |
| `spec/09-model-routing.md` | `50B5C7EA917B99C134C08E3B3C172741642652C3A5FBBC1970864B09B6C0EC1D` |
| `spec/12-installation-and-rollback.md` | `7C0645D4BC87A578F4E090DD72B64B7BA73F947AB12E14D0C7E53133B29A13DF` |
| `spec/13-validation-and-evaluation.md` | `F2CCF96A11FE4F20CAA40F05B061D4892057895F9533A61DBEE5D8EA448E8404` |
| `spec/14-upgradeability-and-governance.md` | `61FECDF3BC151CD42DC9BA2F20B614063155DA96359ABBD37C482A8817E1C410` |
| `spec/15-security-and-failure-recovery.md` | `0577E40062DF1B9D632A8254B0C8C1239219C202F791AF751CC1108A27C0792A` |
| `spec/README.md` | `CE066FD639AB5EB69325465200586FE15E1330082E295CAD59C1FB7B5162F1C1` |
| `spec/key/01-dna.md` | `6260DF35AC7EB87EE05A5FCAF0233ABF5A3A037A1A93199EDDC9AE27D26FF28D` |
| `spec/key/03-token-quality-model.md` | `482BC92D8CD96C77C0C264E78E5BF99C952E121C2C76A8E68F8C4A8F4B54F431` |
| `spec/key/04-decision-log.md` | `C2BB5616EA1134984EB7966443B183023D0F6C14430E621DEAECDFFF3B0503B6` |
| `spec/key/05-coverage-audit.md` | `289321D6B440E9E3C1FC552929D3882A7E53CF4F54EC47CB6688A50F2CD4E01C` |
| `spec/key/06-investment-thesis.md` | `9750EA7E974FD07784F59341CE1BA42D2A52DE0174B136FCB4CD7B3A374C6610` |
| `spec/phases/phase-01-runtime-correctness.md` | `228CE3BB548A6B2FC506F53F2320DF473F4533DE861B9C3CDDE940B85743707E` |
| `spec/phases/phase-02-core-orchestration.md` | `BF78F2580E965CD7331550D120A5F94F3FED16394174D768910A403A1FA8B758` |
| `spec/phases/phase-04-quality-system.md` | `A290EBC6816EF4902D4EC3CE1B06F7EA4972686BAA0D693C0AD648D15951BA6E` |
| `spec/phases/phase-05-installation-hardening.md` | `B3B0BAC403355B2BBC29C81EA46D64DADC36AB9ED621732D12BC1C170D94E850` |
| `spec/phases/phase-06-evaluation.md` | `D53558E2046CC9EB0A279C2363119D5587C548B3833191EE14F0EEBAFF5F24DA` |
| `docs/policies/model-routing.md` | `9D81CD2D22EEDAD57B9DBF236B1E224DD2A977EDB6CE39967687C891973BED50` |
| `scripts/lib/topic02-workflow-lifecycle.ps1` | `3814C35D07800FC86A60D0C92A5CA22541F7C62572971D3318923B1B94DB51E9` |
| `scripts/tests/topic02-workflow-lifecycle.Tests.ps1` | `23DAC47D70727A3A1EFE398D57D91F332AB39DAF1F070953742A473D0A379538` |
| `scripts/lib/phase00-evidence.ps1` | `EF6DB7A01FE044A5C3BCAEF84951250B4ECD4F3DAF642B8C67F584ABF1BF1CCD` |
| `scripts/tests/phase00-t003.Tests.ps1` | `A67B70390BD979EBBA69035F22BDFEAF9B519CC29AEC630233A36223DB85BB45` |

## 8. Preserved boundaries and non-claims

- R1-F1 and R1-F2 remain closed: task-start lock/material-change semantics and topology-neutral
  main-session ownership were not weakened.
- Topic 03 still owns the selected roster, role names, worker graph, producers, schemas, skills,
  aliases, and runtime capabilities. Topic 02 validates the selected contract; it does not choose
  the final topology.
- Topic 04 owns durable lifecycle state, Topic 08 deeper triage, and Phase 06 the future
  evaluation harness.
- Phase 02 still owns future runtime projection and must create new current-product evidence.
- Phase-02 Appendix A and Phase 00 remain historical. All seven runtime pins remain byte-exact.
- The pinned OMP checkout remains clean at
  `3a8591a8af5b6d200088d12ca75a5517cb064fa8`, coding-agent `17.2.10`.
- No runtime prompt, durable state, topology implementation, evaluation harness, candidate
  promotion, stage/index, commit, push, or PR was created.
- Round 7 must independently audit the complete corrected snapshot. This ledger does not close
  Topic 02.
