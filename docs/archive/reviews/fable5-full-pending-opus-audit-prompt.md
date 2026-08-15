# Prompt for Fable 5 — Consolidated Audit of All Outstanding Opus Review Debt

You are Fable 5 acting as an independent, adversarial technical reviewer of the
`omp-template` repository. Several changes were deliberately recorded for later Claude Opus
review while Opus quota or credentials were unavailable. Your job is to audit the complete
remaining review debt now. Do not defer to Codex, prior Opus prose, passing tests, or status
labels by reputation. Accept or reject each claim only from repository evidence.

This is a review-only task. It is not an implementation pass and it does not authorize any
runtime/provider experiment.

## 1. Mission

Produce one consolidated audit that:

1. identifies every project-authored item that still explicitly records pending/deferred Opus
   review or an unfulfilled Opus response;
2. distinguishes a historically valid frozen checkpoint from the current working-tree state;
3. adjudicates every still-relevant pending packet listed below;
4. determines whether later work superseded, preserved, or invalidated each old claim;
5. audits the current Phase 00 authority graph, not merely the oldest packet headers;
6. performs a retrospective cross-family audit of Topic 01, which was closed by an explicitly
   authorized Codex substitute reviewer but never received an Opus verdict;
7. reports all Critical and Important defects with exact evidence and the smallest safe
   correction; and
8. returns one global disposition without editing the implementation.

Do not optimize for agreement with Codex. A correct `REOPEN` or `INSUFFICIENT_EVIDENCE` result is
more valuable than a polite acceptance.

## 2. Repository and mutation boundary

Repository root:

`D:\Dev\Projects\omp-template`

Review the repository in place. The working tree is intentionally dirty and contains
user-owned, Codex-owned, historical, and later-topic changes.

You MUST NOT:

- clean, reset, restore, checkout, switch branches, create a branch, or create a worktree;
- stage, commit, push, pull, merge, rebase, or create a pull request;
- modify any source, spec, template, registry, test, evidence, manifest, audit packet, or
  historical response;
- modify `.claude/worktrees/**` or import any diff from it;
- call a model provider, create a Phase 00 attempt, run E3-M, run an E1 provider case, or enable
  parallel mode;
- install or modify live OMP configuration, credentials, catalogs, or external databases;
- rewrite a historical status as though Fable had participated in that earlier review; or
- treat a passing test as proof when raw evidence or authority contradicts it.

The only permitted repository write is the final report:

`D:\Dev\Projects\omp-template\fable5-full-pending-opus-audit-report.md`

If you cannot safely write that file, return the identical report in chat and make no filesystem
changes. Prefer read/search/hash/parse operations. Do not run a command that may mutate the
repository or live environment. If executable verification is necessary, use a disposable copy
outside the repository and disclose it; otherwise inspect the test and evidence logic directly.

## 3. Snapshot discipline — mandatory

The old packets were written across different snapshots. Many current files were legitimately
changed by later Topic 01–03 work. Therefore every workstream has two separate questions:

1. **Historical checkpoint:** Was the claim correct against the exact frozen inputs, hashes,
   and repository state declared by its packet?
2. **Current applicability:** Is that claim still current, preserved but re-bound, superseded,
   or invalidated by later changes?

Never compare a historical expected hash to today's working bytes and call it a defect without
first reconstructing the intended snapshot. Conversely, never use historical acceptance to
approve later working-tree bytes that were not reviewed.

Use these dispositions for each workstream:

- `ACCEPT_CURRENT` — supported both at the declared checkpoint and in the current applicable
  authority;
- `ACCEPT_HISTORICAL_ONLY` — the frozen checkpoint was valid, but later work superseded or
  invalidated its current hash/authority binding;
- `SUPERSEDED` — the old requested action or verdict is no longer executable as written and
  must be replaced by a current-snapshot audit;
- `REOPEN` — at least one evidence-backed Critical or Important defect exists;
- `INSUFFICIENT_EVIDENCE` — required evidence is absent, contradictory, or cannot be tied to the
  claimed snapshot.

Record repository identity before reading conclusions:

- branch;
- `HEAD`;
- staged-path count;
- full dirty-status row count;
- current SHA-256 of every primary packet in Section 5; and
- current SHA-256 of `docs/evidence/phase-00/manifest.yml` and
  `spec/phases/phase-00-foundation.md`.

Orientation only, captured when this prompt was prepared on 2026-08-13:

```yaml
branch: codex/topic03-agent-topology
HEAD: 509cc43b5cbe74ba0edd25a3ab09c696c5a7e247
status_rows: 250
staged_paths: 0
```

Recompute these values. Drift is not automatically a defect, but it must be disclosed and all
verdicts must name the observed snapshot.

## 4. Current-state warnings you must verify, not trust

The following observations explain why a literal replay of the old prompts would be unsafe:

1. `docs/evidence/phase-00/manifest.yml` currently claims T-00.3 `PASS`, E1 `READY`, E3-I
   `PASS`, E3-L `PASS`, E3-M `DEFERRED_PARALLEL_DISABLED`, and root `parallel_mode: DISABLED`.
   Older P00-CX-028 packets describe E3-I/E3-L as `READY` after Attempts 4/5; later Attempt 7
   evidence now exists. Audit both layers separately.
2. `codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md` has a stale
   opening “Current checkpoint” section. Its chronological tail reaches Checkpoint 47, where
   `ProviderStrictOffControl` Attempt 3 is `INVALID_RUN / E1_STRICT_CONTROL_NOT_EXERCISED`.
   Derive present status from the latest evidence, not the line-8 header.
3. The F7/F8 frozen hashes of `spec/phases/phase-00-foundation.md` no longer match current bytes,
   but their stable semantic anchors still appear in the current file. Audit the frozen diff and
   current semantics separately.
4. The T-00.3 ledger states that later edits to any of its 15 hash-bound destinations invalidate
   its conclusion binding until deliberately re-derived. Topic 03 later changed several of
   those destinations and retired the old five-agent topology. Determine whether T-00.3 is
   historically valid, currently re-bound by later evidence, or presently unsupported.
5. The original Phase 00 forward-audit prompt assumed T-00.3 was unimplemented and
   P00-CX-028 was the immediate gate. Those premises are no longer current.
6. Prior `opus5-response-to-codex-p00-cx-028-round2.md` accepted the diagnosis and proposed
   correction. It did not review the later implemented correction ledger. Do not count it as a
   post-implementation acceptance.

If any observation above is wrong, report the correction with exact evidence.

## 5. Primary outstanding audit inventory

The following six files explicitly remain pending/deferred Opus review. Verify their current
hashes before relying on them. The hashes below are orientation anchors captured when this
prompt was written, not permission to ignore later drift.

| ID | Primary pending file | Orientation SHA-256 | Required audit subject |
| --- | --- | --- | --- |
| A | `codex-response-F7-01-F7-04-changelog-for-opus5.md` | `48C29808D1FC5C54EB0B775CB820D1684856C7F0DB8778E5742D905DF0AEEABF` | F7 E3-M contract reconciliation |
| B | `codex-response-F8-01-F8-04-changelog-for-opus5.md` | `CADAA17A878162E0FA161602B541C910E73A43C1A7FCDDECBF85E61920DAC388` | F8 trace/evidence coherence |
| C | `codex-phase00-execution-changelog-for-opus5.md` | `476075901D51C66EB8341AC977A58C21E6B82D031E5C5EC52CF76D4F0798F63A` | Umbrella Phase 00 execution/evidence ledger through its recorded boundary |
| D | `codex-phase00-p00-cx-028-correction-changelog-for-opus5.md` | `56EC0B6C19802775DF9D9D89337F9ECB64DDE3F1CFF47D339B757412E84454E3` | Implemented Attempt-4/5 terminal-precedence correction |
| E | `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md` | `8E96CF394841A5D11BAC03AE72FBDDDFBD0AEB0DF6934AD1FAA621E4F349782B` | T-00.3 policy re-homing and evidence binding |
| F | `codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md` | `1FBCBF8299F63DC63840FA80783D5E869BC60495B69BB784C859432C2C44656F` | E1 design, harness, attempts, case records, and current READY state |

There are also three unresolved or historical audit obligations:

| ID | Entry file(s) | Why it is included |
| --- | --- | --- |
| G | `codex-response-to-opus5-spec-key-numeric-verification.md`; `opus5-spec-key-numeric-verification-to-codex.md` | The numeric audit was reopened and the required round-2 response file does not exist. |
| H | `opus5-new-session-phase00-forward-audit-prompt.md` | The required `opus5-phase00-forward-audit.md` was never delivered. Its old premises are now stale, so adjudicate and replace rather than execute blindly. |
| I | `opus5-audit-status-codex-topic01-optimization-metrics.md`; `codex-topic01-closure-status.md`; `codex-topic01-sequential-validity-correction-ledger.md` | Topic 01 was accepted by a user-authorized Codex substitute reviewer, but no Opus/cross-family verdict was ever claimed. Perform a retrospective independent audit without rewriting that history. |

Before concluding that this inventory is complete, scan project-authored root Markdown and
`docs/superpowers/**` for at least:

```text
PENDING_OPUS
PENDING_QUOTA
PENDING_UNAVAILABLE
awaiting Opus
deferred audit pending
Opus review remains pending
Opus audit remains pending
Opus audit remains deferred
Required independent Opus
Requested Opus review
```

Exclude `.git/**`, `.tmp-*/**`, `.claude/tmp/**`, vendored `_research/upstreams/**`, and ordinary
mentions that merely say Opus is preferred but not required. Report every extra genuine pending
item, or state that none exists.

## 6. Mandatory companions and progressive read order

Start compactly, then drill down only where a claim needs proof.

### 6.1 Repository-wide authority first

1. `docs/evidence/phase-00/manifest.yml`
2. `spec/phases/phase-00-foundation.md`
3. `spec/key/04-decision-log.md`
4. `spec/README.md`
5. `CHANGELOG.md`

### 6.2 F7/F8 static E3-M contract

Read:

- `codex-response-F7-01-F7-04-changelog-for-opus5.md`
- `codex-response-F8-01-F8-04-changelog-for-opus5.md`
- `omp-custom-F7-post-F6-closure-audit-to-opus5.md`
- `opus5-response-to-gpt56-F6-01-F6-03.md`
- `docs/superpowers/specs/2026-08-08-f7-contract-reconciliation-design.md`
- `docs/superpowers/plans/2026-08-08-f7-contract-correction-plan.md`
- the current and reconstructable frozen versions of
  `spec/phases/phase-00-foundation.md`
- only the cited pinned OMP source under
  `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/`, especially `index.ts` and
  `structured-subagent.ts`

Use stable symbols such as `pass_equivalence_rule`, `native_entry_status_meanings`,
`runtime_unobservable_is_not_a_waiver`, `trace_status_time_coherence`,
`trace_cross_field_consistency`, `trace_evidence_coherence`, and
`proved_order_relations`; historical line numbers may have drifted.

### 6.3 Umbrella Phase 00 and P00-CX-028

Read:

- `codex-phase00-execution-changelog-for-opus5.md`
- `opus5-review-packet-codex-p00-cx-028.md`
- `opus5-review-prompt-codex-p00-cx-028.md`
- `opus5-response-to-codex-p00-cx-028.md`
- `codex-response-to-opus5-p00-cx-028-reopen.md`
- `opus5-response-to-codex-p00-cx-028-round2.md`
- `codex-phase00-p00-cx-028-correction-changelog-for-opus5.md`
- `scripts/lib/phase00-runtime-evidence.ps1`
- `scripts/lib/phase00-e3il-transport.ps1`
- `scripts/lib/phase00-e3i-evidence.ps1`
- `scripts/lib/phase00-evidence.ps1`
- `scripts/run-phase00-e3l-joint.ps1`
- `scripts/tests/phase00-e3i.Tests.ps1`
- `scripts/tests/phase00-e3l.Tests.ps1`
- `scripts/tests/phase00-e3a-e3h.Tests.ps1`
- `scripts/tests/phase00-wave-a.Tests.ps1`
- `docs/evidence/phase-00/E3-I/**`
- `docs/evidence/phase-00/E3-L/**`
- `docs/evidence/phase-00/manifest.yml`

Use the compact packet and correction ledger to select raw artifacts. Do not read every JSONL
file indiscriminately. Verify the exact raw events and hash chains needed for each disputed
classification. Then separately audit later Attempt 7 authority and explain whether the
umbrella ledger has a coverage gap relative to the current manifest.

### 6.4 T-00.3 policy re-homing

Read:

- `codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md`
- `docs/superpowers/specs/2026-08-09-phase-00-t003-authoritative-policy-rehoming-design.md`
- `docs/superpowers/plans/2026-08-09-phase-00-t003-authoritative-policy-rehoming-plan.md`
- `docs/evidence/phase-00/T-00.3/conclusion.yml`
- `docs/evidence/phase-00/manifest.yml`
- `scripts/lib/phase00-evidence.ps1`
- `scripts/tests/phase00-t003.Tests.ps1`
- `scripts/tests/phase00-wave-a.Tests.ps1`
- `scripts/install-template.ps1`
- `scripts/validate-template.ps1`
- `docs/policies/**`
- current installed-surface inputs under `template/.omp/**`
- the current-product Topic 03 manifest and changelog when needed to determine supersession:
  `docs/evidence/current-product/topic-03/manifest.yml` and
  `codex-topic03-agent-topology-model-routing-changelog.md`

Reconstruct the five deleted legacy policy YAML identities from the ledger or Git history; do
not restore them. Distinguish “T-00.3 was correct at completion” from “its old 15-destination
hash binding still proves today's product.”

### 6.5 E1 schema precedence/provider enforcement

Read the E1 ledger progressively:

1. sections 1–13 for the design contract, while treating the opening status as historical;
2. sections 24–31 for the offline gate and first authoritative cases;
3. sections 34, 40, and 41 for later PASS case records;
4. sections 42–47 for strict-control failures, remediation, and the latest boundary;
5. earlier sections only when a predecessor hash or behavior cannot otherwise be verified.

Then inspect:

- `docs/superpowers/specs/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-design.md`
- `docs/superpowers/plans/2026-08-09-phase-00-e1-schema-precedence-provider-enforcement-plan.md`
- `docs/superpowers/specs/2026-08-10-phase-00-e1-forwarder-abort-lifecycle-remediation-design.md`
- `docs/superpowers/plans/2026-08-10-phase-00-e1-forwarder-abort-lifecycle-remediation-plan.md`
- `scripts/lib/phase00-e1-evidence.ps1`
- `scripts/lib/phase00-e1-forwarder.mjs`
- `scripts/run-phase00-e1.ps1`
- `scripts/tests/phase00-e1.Tests.ps1`
- `scripts/lib/phase00-evidence.ps1`
- `docs/evidence/phase-00/E1/fixture/**`
- `docs/evidence/phase-00/E1/raw/**`, selected progressively
- every canonical E1 case record currently present
- `docs/evidence/phase-00/manifest.yml`
- only the exact pinned OMP source anchors cited by the ledger

Do not expose credentials, raw secrets, or full transcripts in the report. Report hashes,
redacted facts, event types, and tight paths only.

### 6.6 Numeric audit and missed forward audit

Read:

- `opus5-spec-key-numeric-verification-to-codex.md`
- `codex-response-to-opus5-spec-key-numeric-verification.md`
- `opus5-new-session-phase00-forward-audit-prompt.md`
- current `spec/key/05-coverage-audit.md`
- current `spec/key/repos/oh-my-pi-settings.md`
- the isolated `.claude/worktrees/spec-key-dna` files only if required to reconstruct the
  historical numeric claim; never treat them as current main authority and never modify them

The expected historical outputs are absent:

- `opus5-response-to-codex-spec-key-numeric-round2.md`
- `opus5-phase00-forward-audit.md`

Answer whether each old obligation should now be completed literally, replaced with a
current-snapshot equivalent, or marked superseded. Reproduce load-bearing numeric claims only
with an explicit corpus, snapshot, matcher, expansion rule, and unit. Do not import the old
worktree edits.

### 6.7 Topic 01 retrospective independent audit

Read:

- `opus5-audit-status-codex-topic01-optimization-metrics.md`
- `codex-topic01-optimization-metrics-changelog-for-opus5.md`
- `codex-topic01-sequential-validity-correction-ledger.md`
- `codex-topic01-closure-status.md`
- `codex-peer-review-packet-topic01-round3.md`
- `codex-peer-review-prompt-topic01-round3.md`
- `codex-peer-review-response-topic01-round3.md`
- current versions of the authority files named in those ledgers, especially:
  `spec/key/03-token-quality-model.md`, `spec/key/04-decision-log.md`,
  `spec/13-validation-and-evaluation.md`, `spec/phases/phase-06-evaluation.md`, and
  `docs/superpowers/specs/2026-08-12-topic-01-optimization-metrics-design.md`
- cited pinned OMP telemetry source only as needed

Determine whether the Codex Round-3 acceptance was evidence-supported at its frozen snapshot
and whether later Topic 02/03 edits preserved the Topic 01 sequential-valid promotion contract.
Do not relabel the historical reviewer as Opus or Fable.

## 7. Mandatory audit questions

### A. F7/F8

1. Are F7-01 through F7-04 and F8-01 through F8-04 internally coherent and source-anchored?
2. Does the trace model admit every intended valid branch and reject impossible cross-products?
3. Are branch-A `NOT_APPLICABLE`, branch-B `RUNTIME_UNOBSERVABLE`, allocation, mutation,
   causal-order, and nonnegative-count rules mutually consistent?
4. Does `pass_equivalence_rule` preserve a genuinely open mechanism class without weakening
   fail-closed semantics?
5. Did later edits preserve these contracts, or is any item historical only?
6. Is any static result falsely presented as E3-M runtime evidence or parallel authorization?

### B. Phase 00 umbrella and P00-CX-028

1. Was the Attempt-4/5 terminal-outcome classifier defect correctly diagnosed?
2. Does the implemented correction prefer the authoritative final outcome before filtering on
   `error|aborted`?
3. Are parent, nested, harness, and attempt retry facts separated without conflation?
4. Are all correction sidecars hash-linked to immutable predecessors and scoped honestly?
5. Was returning E3-I/E3-L to `READY` correct at that historical checkpoint?
6. Do later Attempt 7 PASS artifacts form an independent, complete, internally consistent
   authority chain, or do they bypass an unresolved gate?
7. Does the current manifest overclaim any state relative to available conclusions/raw evidence?
8. Which current Phase 00 PASS claims are absent from the umbrella Opus ledger, and is that an
   auditability defect?
9. Does `parallel_mode: DISABLED` remain enforced everywhere that matters?

### C. T-00.3

1. Did the historical implementation faithfully execute KD-001 without importing T-00.4,
   T-00.5, E2, E3-M, or topology work?
2. Were all 26 legacy sections honestly re-homed or superseded into real consumers/reference
   docs?
3. Was the original conclusion non-circular and backed by source/destination identities?
4. Did the validator and negative mutations fail closed?
5. Are `docs/policies/**` still clearly non-runtime?
6. Did later Topic 03 changes supersede the old consumer topology and old hash binding cleanly?
7. Does a current evidence artifact now bind the changed product, or is the manifest's T-00.3
   `PASS` no longer reproducible against current bytes?

### D. E1

1. What is the exact current E1 state after the latest chronological checkpoint?
2. Are all present canonical case records derivable from immutable raw attempts through the
   current projector/oracle without hidden manual judgment?
3. Are `INVALID_RUN`, `PASS`, `FAIL`, capture integrity, projection status, and analysis status
   kept distinct?
4. Did every provider attempt respect its explicit authorization, one-process boundary, stop
   gate, cleanup, and no-automatic-retry rule?
5. Does the forwarder abort-lifecycle remediation fix the source defect without broadening the
   experiment contract?
6. Is Attempt 3 correctly `E1_STRICT_CONTROL_NOT_EXERCISED`, and does that keep
   `ProviderStrictOn`, the conclusion, T-00.4, and E1 PASS ineligible?
7. Are the five current authoritative case records complete, correctly named, and hash-bound?
8. Is E1 `READY` in the manifest the honest current authority?
9. Does the stale opening checkpoint materially mislead reviewers and require a documentation
   correction?
10. Is any sensitive provider data insufficiently sanitized or overexposed?

### E. Numeric/forward audit debt

1. Adjudicate all seven questions in
   `codex-response-to-opus5-spec-key-numeric-verification.md` against the correct historical
   snapshots.
2. If current counts are reported, rederive them from current bytes and label them current; do
   not recycle `24/59/120`, `27/71/122`, or any other old triple without reproduction.
3. Determine whether the old numeric response is still actionable or only historical.
4. Explain why the original forward-audit output was not delivered.
5. Because T-00.3 and later experiments now exist, replace the old forward-audit recommendation
   with a current dependency-safe recommendation instead of pretending the old pre-state remains.

### F. Topic 01

1. Was the adaptive-stopping defect real and correctly fixed with joint sequential
   false-promotion control `<= 0.05` across all looks, both promotion paths, and every
   promotion-bearing bound?
2. Were the approved 5%/10% numeric thresholds preserved rather than silently changed?
3. Are pilot reuse, undeclared looks, missing/exhausted alpha allocation, fallback-only token
   telemetry, and `accepted_with_waiver` all fail-closed for promotion?
4. Is main-message plus unique-child usage reconciliation sufficient to avoid double counting?
5. Did the final Codex reviewer actually verify the frozen 19-file snapshot it accepted?
6. Did later Topic 02/03 changes introduce any active contradiction or regression?

## 8. Explicit exclusions

Do not open a mandatory review finding merely because these topics lack Opus:

- Topic 02 explicitly records independent review as deferred and non-blocking; Opus is preferred
  but not mandatory.
- Topic 03 explicitly records Opus as not configured and not required.
- Topic 04's plan explicitly says not to request Opus automatically unless a genuinely hard
  unresolved issue remains.

However, if Topic 02–04 changed a file that is load-bearing for one of Sections 5–7, that change
is in scope for current-applicability and regression analysis.

## 9. Evidence and finding quality bar

Order findings by `Critical`, `Important`, then `Minor`.

Every Critical or Important finding must include:

- workstream ID;
- rejected claim or unsafe assumption;
- exact evidence (`path:line`, symbol, YAML path, JSON path, or SHA-256);
- observed fact;
- governing contract or authority;
- whether the defect is historical, current, or both;
- concrete impact on correctness, safety, authority, reproducibility, or forward eligibility;
- smallest exact correction; and
- which verdict changes because of the finding.

Do not report:

- style preferences;
- generic risks without a reachable failure path;
- stale research prose as current product behavior;
- hash drift caused by disclosed later edits as though it were automatically tampering;
- long summaries of packets instead of independent checks;
- praise, deference, model-ranking commentary, or “looks good” assertions;
- full secrets, credentials, provider bodies, or unnecessary transcript content.

Separate verified fact, inference, and recommendation explicitly. A test is supporting evidence;
inspect the predicate and the artifact it claims to validate.

## 10. Required global verdict

Return exactly one global verdict:

```text
NO_BLOCKING_FINDINGS
REOPEN_REQUIRED
INSUFFICIENT_EVIDENCE
```

- `NO_BLOCKING_FINDINGS` requires zero open Critical or Important finding across every included
  workstream. Historical-only or superseded items must still be labeled precisely.
- `REOPEN_REQUIRED` requires at least one evidence-backed Critical or Important defect and an
  exact affected workstream.
- `INSUFFICIENT_EVIDENCE` means the available repository evidence cannot safely support a global
  decision. It must not be used merely to avoid a difficult audit.

## 11. Required response format

Write `fable5-full-pending-opus-audit-report.md` with exactly these top-level sections:

```markdown
# Fable 5 — Consolidated Outstanding Opus-Debt Audit

## 1. Executive verdict
- Global verdict: <NO_BLOCKING_FINDINGS | REOPEN_REQUIRED | INSUFFICIENT_EVIDENCE>
- Reviewed snapshot: <branch, HEAD, dirty/staged counts, timestamp>
- Critical findings: <count>
- Important findings: <count>
- Minor findings: <count>
<four to eight decisive sentences>

## 2. Snapshot and integrity matrix
| Item | Declared/frozen identity | Observed identity | Snapshot meaning | Result |
| --- | --- | --- | --- | --- |
<all primary packets and load-bearing current authority>

## 3. Pending-marker reconciliation
| Marker source | Recorded status | Actual later disposition | Still requires review? | Evidence |
| --- | --- | --- | --- | --- |
<all explicit pending/deferred markers, including any newly discovered item>

## 4. Workstream verdicts
| ID | Workstream | Historical verdict | Current verdict | Disposition | Decisive evidence |
| --- | --- | --- | --- | --- | --- |
| A-I | ... | ... | ... | ACCEPT_CURRENT / ACCEPT_HISTORICAL_ONLY / SUPERSEDED / REOPEN / INSUFFICIENT_EVIDENCE | ... |

## 5. Findings
<None, or evidence-backed findings ordered Critical -> Important -> Minor using the required fields>

## 6. Current Phase 00 authority audit
| Task/experiment | Manifest state | Evidence-supported state | Result | Decisive artifact |
| --- | --- | --- | --- | --- |
<T-00.3, T-00.4, E1, E3-I, E3-L, E3-M, parallel_mode, and any other state needed to explain a finding>

## 7. File-by-file audit disposition
| File or bounded file set | Role | Reviewed snapshot | Result | Finding IDs / notes |
| --- | --- | --- | --- | --- |
<every primary file plus each load-bearing supporting file/set actually used>

## 8. Unfulfilled-output adjudication
### spec/key numeric round 2
### original Phase 00 forward audit
### Topic 01 cross-family review debt
<state whether each is now completed by this report, superseded, still missing, or requires a separate bounded follow-up>

## 9. Closure and non-claims
- Which historical pending markers can now be retired
- Which markers must remain open
- Which current PASS/READY states are supported
- Which runtime/provider actions remain unauthorized
- Whether parallel mode remains disabled

## 10. Required next action
<one concrete next action only; if findings exist, name the smallest correction packet; otherwise name the exact ledger/status updates that may be made in a separately authorized mutation pass>
```

## 12. Completion rules

- Do not stop after the first defect; complete all workstreams A–I.
- Do not silently omit a workstream because its packet is long. Use progressive disclosure and
  report `INSUFFICIENT_EVIDENCE` only for the specific missing dependency.
- Do not mutate implementation or status files to “fix” the audit while reviewing.
- Do not claim that this report retroactively makes Fable or Opus the historical reviewer.
- Do not claim joint closure. This report is an independent review input; Codex and the user will
  adjudicate it afterward.
- Target 4,000–8,000 words. Exceed that only when exact evidence-backed findings require it.
- Prefer compact matrices, exact paths, stable symbols, hashes, and JSON/YAML paths over project
  history narration.

Your final action is to write the report file and return its path plus the single global verdict.
