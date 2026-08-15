# Codex peer-review packet — Topic 01 closure — Round 3

```yaml
topic: 01-optimization-metrics
review_round: 3
reviewer: fresh-codex-peer
reviewer_substitution: explicitly-authorized-by-user
review_mode: read-only
runtime_scope: none
historical_opus_status: PENDING_UNAVAILABLE
```

## 1. Authority and evidence chain

Claude Opus has no usable account/quota. The user authorized Codex temporarily. Reviewer
identity does not change the gate: accept only when no Critical or Important scoped defect
remains.

Read this packet first, then verify the correction ledger:

`codex-topic01-sequential-validity-correction-ledger.md`

Expected SHA-256:

`340F8EF551966B844C65A4145AE61538E00A70D5E9F46833CA23EF4C06C575BB`

The original Opus packet and ledger remain immutable historical evidence:

- `opus5-review-packet-codex-topic01-optimization-metrics.md`
  `3EB732F06859F854A85E9E2FF52742B53FA6E19F0AC0494754B8C1CCB0101F9A`
- `codex-topic01-optimization-metrics-changelog-for-opus5.md`
  `11491FC80CBB287462369E42CFB2A680DDAF0C2A12140E00B24FF1C6D0E4DA0C`

Their old load-bearing hash table describes the pre-correction snapshot and is superseded by
§5 below. Do not treat expected post-correction differences from that old table as an evidence
failure.

## 2. Approved contract that must remain intact

1. Hard deterministic quality gates run first.
2. Maximize validated accepted-outcome rate.
3. Minimize `core_workflow_tokens / validated_accepted_outcomes`.
4. Latency is telemetry and a final tie-breaker only.
5. Validated acceptance requires complete objective, PASS/no-skip mandatory criteria, clear
   required verification/review, no blocking scope/authority issue, and Tech Lead acceptance.
   Waiver/partial/blocked/cancelled/decision-needed states stay outside the denominator.
6. Full task cycles charge failures, retrieval, retries, rework, handoff/compaction, and
   fallbacks. Core, Cheap Scout, and raw-total tokens are separate unweighted ledgers.
7. Cheap Scout is optional, read-only, configurable, has no token gate/weight, fails soft to
   the Lead's needed path, and critical evidence is rechecked by the Lead.
8. Candidate decisions compare with the frozen last promoted template. Release/major
   architecture checkpoints additionally compare with pinned plain OMP using the same external
   objective/oracle, not impossible template-internal mechanisms.
9. A three-pair-per-arm pilot may reject but cannot promote. Final evidence is adaptive;
   inconclusive evidence defers/rejects; thresholds cannot be loosened post hoc.
10. Efficiency path: observed acceptance delta `>=0`, non-inferiority margin `-0.05`, observed
    core-token improvement `>=10%`, and credible paired token improvement. Quality path:
    credible positive acceptance delta and paired upper core-token bound `<=1.10x` baseline.

## 3. Round-2 finding and required correction

Round 2 correctly found that merely predeclaring repeated ordinary 95% intervals does not
retain 95% confidence under optional stopping. The correction must therefore:

- use an anytime-valid paired confidence sequence, a finite alpha-spending/look schedule with
  multiplicity adjustment, or an equivalent joint sequential construction;
- keep the probability of any false promotion at `<=0.05` across all interim looks, both win
  paths, and every promotion-bearing bound;
- prohibit nominal per-look intervals from authorizing adaptive promotion;
- prohibit retroactive pilot reuse unless the frozen procedure treats the pilot as look one;
- fail closed on missing sequential metadata, undeclared looks, or missing/exhausted alpha;
- preserve every approved numeric threshold and all non-statistical Topic 01 decisions.

Independently decide whether the corrected files satisfy this. Do not accept merely because
the correction ledger says they do.

## 4. Mandatory read order

1. `codex-topic01-sequential-validity-correction-ledger.md`
2. `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md`
3. `spec/key/03-token-quality-model.md §A`
4. `spec/key/04-decision-log.md` — KD-024 and KD-025
5. `spec/13-validation-and-evaluation.md §C` and AC-11 through AC-17
6. `spec/phases/phase-06-evaluation.md` — T-06.6 through T-06.8, verification, exit criteria
7. `spec/README.md` — PR-7; `spec/phases/phase-07-stabilization.md` — PR-7 projection
8. Pinned OMP source anchors in §6
9. Other current-hash files in §5 only as needed to test projection drift

Read `codex-peer-review-response-topic01-attempt-02.md` only to verify or challenge the prior
finding. Its SHA-256 before this packet was frozen is
`A5B8B8794DF5005B937803A2A18FE1A65A5C976B8F9565D5F0B4AA12ECB593F0`.

## 5. Corrected load-bearing SHA-256 table

| File | Expected SHA-256 |
|---|---|
| `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md` | `437CF16D1759357AE51DE347DDF13D8721F193DD0977A8CA3A9C77611A45BBC5` |
| `spec/key/03-token-quality-model.md` | `DF235DA4712B8B2144F87A1CD8BC004EEC4648629D39E15BFC3EFDDFBC7830EF` |
| `spec/key/04-decision-log.md` | `7F01A324E1FC35D811815DF40665E39B37A9C8F1F81CF3468274731E17447D8E` |
| `spec/13-validation-and-evaluation.md` | `78F1157C614CC27CCC2CF7053FADD8DC6CB142D0DEC56AA57BFD89A2B347D062` |
| `spec/key/01-dna.md` | `C41E82F8CEB5B6A7643C4702F227FE289A51CBBC98824259CF6F3F0F412B1AA1` |
| `spec/key/05-coverage-audit.md` | `99A181C9E984B06F5AD0DD85FA90AF752B340BD2CB7D12725EAEA2C5F10F15AA` |
| `spec/key/06-investment-thesis.md` | `54226AC403141CA98B553BA59C722E5E1560A5E825913474759FF4CF6D5C761C` |
| `spec/key/README.md` | `1E6CF1D9B76BA5A498ECEC8587ED6DF73F765CA066D239A849FD1B56640247D7` |
| `spec/05-context-and-token-model.md` | `D487EB1267749DF3E54BD6A18CCFC87F864569A76780810D2C4E334486755478` |
| `spec/07-retrieval-and-code-understanding.md` | `BF716322713AB83103F477DA97360FF0F14667F83B94A3B3664F70D23F6F9017` |
| `spec/README.md` | `5E003BC77BC178A78FA9FB4C106443AD2014EE66D7E50059DA1B46E85F357663` |
| `docs/token-strategy.md` | `68D2CE31E7C2F57CD2A7FDEC76A4994369CC4D6359A6F442FB7B77616D49EEEB` |
| `spec/phases/phase-03-context-efficiency.md` | `F8FD4988D9C13B690BEF38BE12E856D7AB2F485D3597153FF828338628D2BBB4` |
| `spec/phases/phase-06-evaluation.md` | `1301FB89CDF6225C6A644021093728DE2E0B37C782AB47B373E10290FCD8E153` |
| `spec/phases/phase-07-stabilization.md` | `D43A3858D638639EE2B332AF60BA4B0FCA70B4834AD411271ACD050AF8591E8C` |
| `CHANGELOG.md` | `C920B7E0B05B8EAD334AAE23AD64C623390A7E3831F94B3B1FE7226C26338B7C` |

Stop with `INSUFFICIENT_EVIDENCE` only if a byte-level command actually executes and produces a
mismatch, a required file/source is absent, or the evidence is contradictory. Include exact
command and output.

## 6. Pinned OMP source claims

Pinned repository: `_research/upstreams/oh-my-pi`

Expected clean commit: `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (OMP 17.2.10).

Verify independently:

1. `packages/coding-agent/src/task/types.ts:471-510` exposes per-spawn identity, role, usage,
   duration, and token fields.
2. `packages/coding-agent/src/task/executor.ts:759-782` intends input + output + cache-write,
   but fallback `totalTokens` may include cache-read.
3. `packages/coding-agent/src/session/session-stats.ts:52-110` aggregates main assistant and
   task-tool child usage; blindly adding child results double counts.
4. `packages/coding-agent/src/modes/print-mode.ts:47-83,191-194` preserves usage-bearing
   messages/events in JSON mode.

The Topic 01 fail-closed rule requires explicit usage breakdown, unique-child reconciliation,
and `not_measured` on unresolved attribution. Do not infer tokens from text length.

## 7. Ten mandatory questions

1. Can any waived, partial, skipped, blocked, cancelled, decision-needed, or self-reported
   result enter the validated denominator?
2. Are every failure, retrieval, retry, rework, handoff/compaction, Scout fallback, and terminal
   task cycle charged exactly once?
3. Does main/unique-child reconciliation avoid both omission and double counting, including
   nested work, and fail closed when it cannot?
4. Does fallback-only/missing usage become `not_measured` and block promotion?
5. Is Cheap Scout still a simple optional read-only helper with fail-soft fallback and no
   token quota/weighting?
6. Are stable-template and pinned-plain-OMP baselines distinct, frozen, and judged with
   baseline-compatible external objectives/oracles?
7. Are hard gates and the two numeric win paths internally coherent and unchanged?
8. Does the corrected final protocol keep false-promotion probability `<=0.05` across adaptive
   looks, both paths, and every bound; do pilot and missing-metadata cases fail closed?
9. Do PR-7 and Phase 07 reference the same canonical dual-baseline/final-evidence gate?
10. Are runtime, benchmark implementation, candidate promotion, Phase 00, and DAG changes still
    explicit non-claims?

## 8. Verdict policy

Return exactly one:

```text
ACCEPT_TOPIC_01
REOPEN_TOPIC_01
INSUFFICIENT_EVIDENCE
```

`ACCEPT_TOPIC_01` requires no Critical or Important scoped defect. Minor findings may coexist
only when they cannot change outcome classification, accounting, promotion, source meaning,
phase authority, or reproducibility. A preference for a different valid sequential method or
stricter threshold is a trade-off, not a finding. Topic 01 remains specification/phase planning;
do not require the deferred Phase 06 runtime harness to exist.
