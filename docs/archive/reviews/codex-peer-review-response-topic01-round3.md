# Codex Peer Review — Topic 01 — Round 3

```yaml
reviewer: codex-cli
requested_model: gpt-5.6-sol
reasoning_effort: xhigh
thread_id: 019ff4a0-1bc2-7f70-b7cb-1e9572da74e3
prompt_sha256: 2C4C7BDD1CAE35D5299DE469ADB86B85C1305B6EFBD484816B2172EF1EF8AAE0
packet_sha256: 7589329EB747FEBACBCF883BF1B62EF8EE639BC9A3766F459FFFA191E7AD5651
correction_ledger_sha256: 340F8EF551966B844C65A4145AE61538E00A70D5E9F46833CA23EF4C06C575BB
environment: disposable-exact-copy
session: ephemeral
input_tokens: 1261728
cached_input_tokens: 1168128
output_tokens: 18296
verdict: ACCEPT_TOPIC_01
```

The controlling process verified after review that all 19 official/copy evidence files still
matched byte-for-byte and that the copied OMP source remained clean at the pinned commit. The
review response follows.

---

## 1. Verdict

ACCEPT_TOPIC_01

Every executed byte-level hash matches, and the pinned OMP repository is clean at the required
commit. The Round-2 adaptive-stopping finding was valid; Round 3 corrects it with joint
sequential error control covering every look, both promotion paths, and all promotion-bearing
bounds. Nominal per-look intervals, invalid pilot reuse, undeclared looks, missing/exhausted
alpha, missing telemetry, and inconclusive exhaustion cannot promote. No Critical or Important
scoped defect remains.

## 2. Hash and source audit

Hashes were executed with PowerShell `Get-FileHash -Algorithm SHA256`.

| Check | Expected | Observed | Result |
|---|---|---|---|
| Round-3 packet | `7589329EB747FEBACBCF883BF1B62EF8EE639BC9A3766F459FFFA191E7AD5651` | Same | PASS |
| Correction ledger | `340F8EF551966B844C65A4145AE61538E00A70D5E9F46833CA23EF4C06C575BB` | Same | PASS |
| Historical Opus packet | `3EB732F06859F854A85E9E2FF52742B53FA6E19F0AC0494754B8C1CCB0101F9A` | Same | PASS |
| Historical Topic-01 ledger | `11491FC80CBB287462369E42CFB2A680DDAF0C2A12140E00B24FF1C6D0E4DA0C` | Same | PASS |
| Round-2 response | `A5B8B8794DF5005B937803A2A18FE1A65A5C976B8F9565D5F0B4AA12ECB593F0` | Same | PASS |
| Topic-01 design | `437CF16D1759357AE51DE347DDF13D8721F193DD0977A8CA3A9C77611A45BBC5` | Same | PASS |
| `spec/key/03-token-quality-model.md` | `DF235DA4712B8B2144F87A1CD8BC004EEC4648629D39E15BFC3EFDDFBC7830EF` | Same | PASS |
| `spec/key/04-decision-log.md` | `7F01A324E1FC35D811815DF40665E39B37A9C8F1F81CF3468274731E17447D8E` | Same | PASS |
| `spec/13-validation-and-evaluation.md` | `78F1157C614CC27CCC2CF7053FADD8DC6CB142D0DEC56AA57BFD89A2B347D062` | Same | PASS |
| `spec/key/01-dna.md` | `C41E82F8CEB5B6A7643C4702F227FE289A51CBBC98824259CF6F3F0F412B1AA1` | Same | PASS |
| `spec/key/05-coverage-audit.md` | `99A181C9E984B06F5AD0DD85FA90AF752B340BD2CB7D12725EAEA2C5F10F15AA` | Same | PASS |
| `spec/key/06-investment-thesis.md` | `54226AC403141CA98B553BA59C722E5E1560A5E825913474759FF4CF6D5C761C` | Same | PASS |
| `spec/key/README.md` | `1E6CF1D9B76BA5A498ECEC8587ED6DF73F765CA066D239A849FD1B56640247D7` | Same | PASS |
| `spec/05-context-and-token-model.md` | `D487EB1267749DF3E54BD6A18CCFC87F864569A76780810D2C4E334486755478` | Same | PASS |
| `spec/07-retrieval-and-code-understanding.md` | `BF716322713AB83103F477DA97360FF0F14667F83B94A3B3664F70D23F6F9017` | Same | PASS |
| `spec/README.md` | `5E003BC77BC178A78FA9FB4C106443AD2014EE66D7E50059DA1B46E85F357663` | Same | PASS |
| `docs/token-strategy.md` | `68D2CE31E7C2F57CD2A7FDEC76A4994369CC4D6359A6F442FB7B77616D49EEEB` | Same | PASS |
| Phase 03 | `F8FD4988D9C13B690BEF38BE12E856D7AB2F485D3597153FF828338628D2BBB4` | Same | PASS |
| Phase 06 | `1301FB89CDF6225C6A644021093728DE2E0B37C782AB47B373E10290FCD8E153` | Same | PASS |
| Phase 07 | `D43A3858D638639EE2B332AF60BA4B0FCA70B4834AD411271ACD050AF8591E8C` | Same | PASS |
| `CHANGELOG.md` | `C920B7E0B05B8EAD334AAE23AD64C623390A7E3831F94B3B1FE7226C26338B7C` | Same | PASS |
| Pinned OMP repository | Clean `3a8591a8af5b6d200088d12ca75a5517cb064fa8` | Exact commit; `git status --short` emitted no entries | PASS |
| Spawn telemetry claim | Identity, role, usage, duration, token fields | `id`, `agent`, `durationMs`, `tokens`, `modelRole`, and `usage` at `task/types.ts:471-510` | PASS |
| Token-fallback claim | Input + output + cache-write; fallback may include cache-read | Computation at `executor.ts:774-778`; fallback warning and `totalTokens` at `:779-782` | PASS |
| Session aggregation claim | Main assistant and task-child usage both aggregated | Assistant usage at `session-stats.ts:67-79`; task-tool usage at `:80-91` | PASS |
| JSON preservation claim | Usage-bearing messages/events survive JSON mode | `message_end`/`agent_end` preserved at `print-mode.ts:71-81`; emitted at `:191-194` | PASS |

## 3. Findings

None. No Critical, Important, or Minor scoped defect was established.

## 4. Mandatory-question answers

| # | Decision | Decisive evidence |
|---|---|---|
| 1 | ACCEPT | The five conjunctive acceptance conditions and exclusive terminal vocabulary are at `spec/13-validation-and-evaluation.md:187-215`; SKIP or coverage gaps fail conditions 2–3. Phase 06 excludes waiver, partial, blocked, cancelled, and decision-needed cycles at `phase-06-evaluation.md:159-164`. |
| 2 | ACCEPT | Full-cycle charging includes retrieval, rejected candidates, retries, rework, handoff/compaction, Scout fallback, and failed cycles at `spec/13-validation-and-evaluation.md:217-223`. Aggregated task usage cannot be added after individual children at `:178-180`. |
| 3 | ACCEPT | Main assistant usage, unique child usage, and role attribution are reconciled at `spec/13-validation-and-evaluation.md:251-268` and `phase-06-evaluation.md:126-130`. Nested finalized task data remain available through `extractedToolData.task` at `task/types.ts:462-466,509-526`; unresolved identity or attribution becomes `not_measured`. |
| 4 | ACCEPT | The fallback caveat is confirmed at `executor.ts:759-782`. Explicit usage is required, and missing main-session, role, or token-basis data block promotion at `spec/13-validation-and-evaluation.md:251-268,351-358`. |
| 5 | ACCEPT | Tech Lead discretion, configurable model, read-only work, fail-soft fallback, evidence recheck, and absence of a quota are preserved at `spec/key/03-token-quality-model.md:74-81`. |
| 6 | ACCEPT | Baseline purposes and frozen identities are distinct at `spec/13-validation-and-evaluation.md:293-311`. Plain OMP is judged by external objectives/oracles rather than impossible template mechanisms at `:313-316`. |
| 7 | ACCEPT | Hard gates run first at `spec/13-validation-and-evaluation.md:351-358`. The efficiency path retains observed delta `>=0`, lower bound `>=-0.05`, and observed improvement `>=10%`; the quality path retains lower bound `>0` and upper token bound `<=1.10x` at `:366-378`. |
| 8 | ACCEPT | The inference method, stopping rule, familywise allocation, look schedule, and budget must be frozen at `spec/13-validation-and-evaluation.md:320-332`. The joint rule covers all looks, both paths, and every bound at `:339-347,362-378`. Thus a false promotion implies failure of at least one member of the simultaneously controlled family; its union probability is bounded by `0.05`. AC-17 and Phase 06 reject nominal intervals, undeclared looks, missing/exhausted alpha, and invalid pilot reuse at `:449-452` and `phase-06-evaluation.md:191-204,231-235`. |
| 9 | ACCEPT | Canonical PR-7 requires candidate/stable promotion and the additional release/plain-OMP comparison while excluding pilots and waivers at `spec/README.md:426-447`. Phase 07 references that authority without restating thresholds at `phase-07-stabilization.md:104-130`. |
| 10 | ACCEPT | The design excludes runtime/template behavior, Phase DAG, Phase 00, and historical-evidence changes at `2026-08-12-topic-01-optimization-metrics-design.md:175-181`. The correction ledger records no runtime, harness, candidate, Phase 00/DAG, or historical-verdict claim at `codex-topic01-sequential-validity-correction-ledger.md:103-111`. |

## 5. Correction and non-claim check

- Round-2 adaptive finding: CONFIRMED. Repeated ordinary 95% intervals under optional stopping
  did not preserve the promised overall confidence.
- sequential overall error control: CORRECTED. The canonical contract now requires a joint
  sequential construction with false-promotion probability `<=0.05` across every look, both
  win paths, and every promotion-bearing bound.
- numeric thresholds unchanged: YES — non-inferiority remains `-0.05`, efficiency improvement
  remains observed `>=10%`, and the quality-path token ceiling remains `1.10x`.
- outcome/accounting/Scout/baselines: UNCHANGED and internally consistent.
- runtime implemented by Topic 01: NO
- candidate promoted by Topic 01: NO
- Phase 00 / DAG changed by Topic 01: NO
- Opus verdict claimed: NO
- Evidence classification: OMP telemetry statements are source facts; sequential familywise
  sufficiency is logic; the numeric thresholds are user-approved design choices; Phase 06
  method selection remains deferred implementation work.

## 6. Next action

Record `ACCEPT_TOPIC_01` as the Topic 01 Round-3 closure decision.
