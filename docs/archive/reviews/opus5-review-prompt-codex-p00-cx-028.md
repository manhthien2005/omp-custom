# Prompt for Claude Opus 5 — Adversarial Review of Codex P00-CX-028

You are Claude Opus 5 returning as Codex's equal technical peer on `omp-template` Phase 00.
Neither model has authority by reputation. Accept or reject claims only from repository evidence.

## Scope and mutation boundary

Review Codex's Attempt 5 retry-fact correction and terminal blocked materialization. This is a
review-only pass: do not edit files, call the provider, create Attempt 6, or perform Git
integration. If you find a defect, specify the minimal exact correction for the next authorized
round.

The decision is **not** whether E3-I or E3-L semantically passes. The decision is whether
P00-CX-028 faithfully and fail-closedly represents a provider-blocked Attempt 5 while preserving
an independently observed recovered nested retry.

## Mandatory read order

1. Read `opus5-review-packet-codex-p00-cx-028.md` first.
2. Verify its SHA-256 is
   `ACFF1179046B2F0971757182BE5ED39F9002D16BADEA7A20700928E404AC8CF4`.
3. Follow only the packet's load-bearing paths, hashes, anchors, and JSON links.
4. Read `codex-phase00-execution-changelog-for-opus5.md` only when a packet claim needs
   drill-down. Its expected SHA-256 is
   `476075901D51C66EB8341AC977A58C21E6B82D031E5C5EC52CF76D4F0798F63A`.
5. Use P00-CX-027A lines 3529-3754 for raw-launch history and P00-CX-028 lines 3755-4010 for
   the scoped mutation ledger. Do not reread older rounds unless a predecessor cannot otherwise
   be verified.

If either top-level hash differs, return `INSUFFICIENT_EVIDENCE` and report the observed hash.

## Review method

Independently verify, rather than paraphrase, this chain:

```text
Attempt 5 raw events
  → parent-terminal and nested-retry facts
  → immutable raw joint record
  → corrected adjudication sidecar
  → independent E3-I and E3-L conclusions
  → manifest authority states
```

Challenge all seven questions in Section 7 of the packet. In particular, attempt to falsify:

- terminal-overload precedence;
- the decision not to rewrite the original joint record;
- sidecar hash and correction invariants;
- independence of E3-I and E3-L semantic authority;
- legality of `E3-L: READY → BLOCKED_ENVIRONMENT`;
- absence of I1-I4/L1-L3 or selected-transaction claims;
- continued E3-M and parallel disablement.

Tests are supporting evidence, not proof by themselves. Inspect raw JSON/JSONL facts and the
validator logic. Do not infer facts from model prose. Do not treat an internal recovered retry as
an outer retry or Attempt 6. Do not treat `BLOCKED_ENVIRONMENT` as semantic `FAIL` or `PASS`.

## Required verdict

Return exactly one top-level verdict:

```text
ACCEPT_P00_CX_028
REOPEN_P00_CX_028
INSUFFICIENT_EVIDENCE
```

Use `ACCEPT_P00_CX_028` only when no Critical or Important scoped defect remains. Minor findings
may coexist with acceptance only when they cannot change evidence meaning, authority state, or
reproducibility.

Use `REOPEN_P00_CX_028` when at least one evidence-backed defect invalidates the correction,
artifact chain, state transition, or non-claim boundary.

Use `INSUFFICIENT_EVIDENCE` when a required file/hash/event is unavailable or contradictory and
the verdict cannot be derived safely.

## Required response format

Keep the response compact and use exactly these sections:

```markdown
# Opus 5 Review — P00-CX-028

## 1. Verdict
<ACCEPT_P00_CX_028 | REOPEN_P00_CX_028 | INSUFFICIENT_EVIDENCE>
<two to five sentences explaining the decisive reason>

## 2. Hash and artifact-chain audit
| Check | Expected | Observed | Result |
| --- | --- | --- | --- |
<only load-bearing checks>

## 3. Findings
<"None" or findings ordered Critical → Important → Minor>

For every finding:
### <severity> — <short title>
- Claim rejected: <exact claim>
- Evidence: `<path:line-or-JSON-path>`
- Observed: <fact>
- Expected: <contract>
- Impact: <why verdict changes or why finding is minor>
- Minimal correction: <exact fix/evidence needed>

## 4. Mandatory-question answers
| # | Decision | Decisive evidence |
| --- | --- | --- |
| 1-7 | ACCEPT / REJECT / INSUFFICIENT | exact path and location |

## 5. Authority and non-claim check
- E3-I: <state>
- E3-L: <state>
- E3-M: <state>
- parallel_mode: <state>
- selected I1-I4/L1-L3 artifacts: <count>
- Attempt 6/provider call authorized by this review: NO

## 6. Next action
<one concrete action only>
```

## Token discipline

- Do not restate the packet or project history.
- Do not praise Codex or defer to Codex's conclusion.
- Do not list passing tests unless they decide a disputed claim.
- Cite repository-relative paths and tight line/JSON locations.
- Separate fact, inference, and recommendation explicitly.
- Target 800-1,500 words; exceed this only for evidence-backed reopening findings.

The collaboration closes this scoped issue only if Opus accepts it and Codex subsequently reviews
Opus's evidence without a remaining objection. Opus acceptance alone is not unilateral closure;
Codex's current packet is likewise not unilateral closure.
