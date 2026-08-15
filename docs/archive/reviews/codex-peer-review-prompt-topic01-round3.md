# Prompt for Codex peer review — Topic 01 closure — Round 3

You are a fresh Codex session acting as an independent technical peer, not the author. The user
explicitly authorized Codex as temporary reviewer because Claude Opus has no usable
account/quota. Reviewer substitution does not weaken the gate.

This session runs inside a disposable exact copy. You may execute read-only hashing, search,
file-reading, and Git-inspection commands. Do not edit, create, delete, format, stage, commit, or
otherwise mutate anything. Do not run provider-backed benchmarks or implement Phase 06.

## Entry gate

1. Read `codex-peer-review-packet-topic01-round3.md` first.
2. Execute a byte-level SHA-256 command for it. Expected:
   `7589329EB747FEBACBCF883BF1B62EF8EE639BC9A3766F459FFFA191E7AD5651`.
3. Follow its evidence chain, current hash table, mandatory read order, source checks, ten
   questions, and verdict policy exactly.
4. Execute the hashes; do not invent a value from normalized text. If a command is rejected,
   try an equivalent byte-level command. Use `INSUFFICIENT_EVIDENCE` only under the packet's
   stated rule.

## Adversarial focus

- Independently verify the Round-2 adaptive-stopping finding and the Round-3 correction.
- Falsify whether the joint sequential rule really covers all looks, both alternative win
  paths, and all promotion-bearing bounds at false-promotion probability `<=0.05`.
- Check that ordinary per-look intervals, undeclared looks, missing/exhausted alpha metadata,
  and invalid pilot reuse cannot promote.
- Check that the correction did not silently change the approved `-0.05`, `10%`, or `1.10x`
  thresholds or any outcome/accounting/Scout/baseline/non-claim decision.
- Recheck the other nine mandatory questions and four pinned-source claims; do not limit the
  review to the correction.
- Separate source fact, logic, user-approved design choice, and recommendation. Different
  preferences are not defects unless the written contract is contradictory, unimplementable,
  unsafe, or silently weaker.

## Required response

```markdown
# Codex Peer Review — Topic 01 — Round 3

## 1. Verdict
<ACCEPT_TOPIC_01 | REOPEN_TOPIC_01 | INSUFFICIENT_EVIDENCE>
<two to five decisive sentences>

## 2. Hash and source audit
| Check | Expected | Observed | Result |
|---|---|---|---|
<packet, correction ledger, all load-bearing files, pinned commit, four source claims>

## 3. Findings
<None, or Critical → Important → Minor>

For every finding:
### <severity> — <short title>
- Classification: contract-misread | actionable | trade-off | noise
- Claim rejected: <exact claim>
- Evidence: `<path:line-or-symbol>`
- Observed: <what evidence proves>
- Expected: <contract>
- Impact: <why verdict changes or why bounded>
- Minimal correction: <smallest exact correction>

## 4. Mandatory-question answers
| # | Decision | Decisive evidence |
|---|---|---|
| 1-10 | ACCEPT / REJECT / INSUFFICIENT | exact path and location |

## 5. Correction and non-claim check
- Round-2 adaptive finding: <state>
- sequential overall error control: <state>
- numeric thresholds unchanged: <state>
- outcome/accounting/Scout/baselines: <state>
- runtime implemented by Topic 01: NO
- candidate promoted by Topic 01: NO
- Phase 00 / DAG changed by Topic 01: NO
- Opus verdict claimed: NO

## 6. Next action
<one concrete action only>
```

Return one self-contained review. Target 1,000–1,800 words; exceed only for an evidence-backed
reopening finding. Do not praise either author and do not rewrite the packet.
