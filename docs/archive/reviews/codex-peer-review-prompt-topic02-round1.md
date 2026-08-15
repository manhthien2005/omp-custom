# Prompt for Codex peer review — Topic 02 closure — Round 1

You are a fresh Codex session acting as an independent technical peer, not the author. The user
explicitly authorized Codex as temporary reviewer because Claude Opus has no usable
account/quota. Reviewer substitution does not weaken the gate.

This is a read-only audit of an uncommitted hash-pinned snapshot in a dirty shared repository.
You may execute hashing, search, file-reading, validator, and Git-inspection commands. Do not
edit, create, delete, format, stage, commit, switch branches, reset, restore, clean, or otherwise
mutate the repository, the upstream checkout, or any worktree. Do not implement the deferred
Phase 02 runtime migration.

## Entry gate

1. Read `codex-peer-review-packet-topic02-round1.md` first.
2. Execute a byte-level SHA-256 command for it. Expected:
   `B26118D339C644B75035CA0EFA8B1C443AE0CE7086B31877AEFD0A912EF7D20E`.
3. Follow its scope boundary, mandatory read order, load-bearing hashes, preserved runtime
   pins, pinned OMP source checks, ten questions, and verdict policy exactly.
4. Execute every supplied hash; do not invent values from normalized text. Because unrelated
   work is present, do not use the repository-wide diff as the Topic 02 scope oracle.
5. Re-run the focused self-test, focused validator, full repository validator, contradiction
   searches, and `git diff --check`. The documented pre-existing RULES budget warning and an
   unrelated line-ending warning do not reopen Topic 02 by themselves.
6. Use `INSUFFICIENT_EVIDENCE` only under the packet's stated evidence rule and include the
   exact failed command/output.

## Adversarial focus

- Falsify no-prefix and missing-slash behavior against the pinned OMP source rather than
  assuming prompts can execute model-authored slash text.
- Search the frozen specification and phase authority for any second workflow selector,
  restart/discard rule, forced spawn, fixed topology, mandatory parallelism, or unconditional
  Orchestrated reviewer rule.
- Attack the boundary between pre-contract clarification, accepted task contract, internal
  work units, task cycle, candidate sequence, and phase.
- Attempt to reuse verification/review evidence after candidate mutation or across C1/C2, and
  attempt to accept a parent task from work-unit evidence alone.
- Attempt to turn compaction, generated handoff text, `.task/` scratch, fork prose, or resumed
  history into lifecycle authority. Check handoff's successor-session claim against OMP.
- Attempt to put partial, recoverable blocked, waiting-for-user, cancelled, terminally blocked,
  or `accepted_with_waiver` outcomes into the wrong lifecycle/evaluation category or validated
  denominator.
- Verify safe reclassification preserves useful work without silently enlarging scope or
  authority.
- Verify Orchestrated remains structural and implementable sequentially; optional worker,
  parallel-writer, isolation, and reviewer paths must retain their applicable safety gates
  without becoming classification requirements.
- Verify Cheap Scout remains optional, configurable, read-only, and fail-soft, with a simple
  Tech-Lead-needed fallback and no token gating/weighting.
- Verify Topic 03/04/08 and Phase 02/03/06 ownership is coherent, dependencies are not silently
  changed, and the preserved Phase 00 runtime snapshot is neither rewritten nor falsely
  described as current Topic 02 implementation.
- Separate source fact, approved design choice, implementation feasibility, and recommendation.
  Different preferences are not defects unless the written contract is contradictory,
  unimplementable, unsafe, or silently weaker.

## Required response

```markdown
# Codex Peer Review — Topic 02 — Round 1

## 1. Verdict
<ACCEPT_TOPIC_02 | REOPEN_TOPIC_02 | INSUFFICIENT_EVIDENCE>
<two to five decisive sentences>

## 2. Hash, validator, and source audit
| Check | Expected | Observed | Result |
|---|---|---|---|
<packet, ledger, every load-bearing file, every historical runtime pin, pinned commit, three source claims, focused/full validation>

## 3. Findings
<None, or Critical → Important → Minor>

For every finding:
### <severity> — <short title>
- Classification: contract-misread | actionable | trade-off | noise
- Claim rejected: <exact claim>
- Evidence: `<path:line-or-symbol>`
- Observed: <what evidence proves>
- Expected: <approved contract>
- Impact: <why verdict changes or why bounded>
- Minimal correction: <smallest exact correction>

## 4. Mandatory-question answers
| # | Decision | Decisive evidence |
|---|---|---|
| 1-10 | ACCEPT / REJECT / INSUFFICIENT | exact path and location |

## 5. Boundary and non-claim check
- plain/no-prefix source feasibility: <state>
- task/candidate/session boundaries: <state>
- lifecycle/evaluation reconciliation: <state>
- structural Orchestrated and optional topology: <state>
- Cheap Scout fallback: <state>
- historical Phase 00 evidence preserved: <state>
- runtime implemented by Topic 02: NO
- durable Topic 04 state implemented: NO
- candidate promoted by Topic 02: NO
- Phase DAG changed by Topic 02: NO
- Opus verdict claimed: NO

## 6. Next action
<one concrete action only>
```

Return one self-contained review. Target 1,200–2,000 words; exceed only for an evidence-backed
reopening finding. Do not praise either author and do not rewrite the packet.
