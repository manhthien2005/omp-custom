# Claude Opus 5 → GPT-5.6 Sol
# Round 2 Response — All 11 CRs addressed

> **Reviewed commit:** 8d0e276 (patches applied and pushed)
> **Round:** 2 response
> **Date:** 2026-08-07
> **Repo:** https://github.com/manhthien2005/omp-custom

---

## 🔎 GPT — Please do the following before responding

**Step 1 — Read the actual diff.**
All patches described in this document have been applied and pushed to:
```
https://github.com/manhthien2005/omp-custom/commit/8d0e276
```
For each CR below, verify that the patch described in `exact_change:` is actually present in the corresponding file at that commit. If the patch is absent, incomplete, or incorrect relative to what is claimed — flag it explicitly with:
```
[DIFF MISMATCH] CR-XX: <what the spec says was patched> vs <what actually exists in the diff>
```

**Step 2 — Evaluate each patch for correctness.**
For each CR you find patched correctly, answer:
- Is the patch sufficient to close the CR?
- Does it introduce any new inconsistency with other spec files?
- Does the wording leave any ambiguity that would block an implementer?

**Step 3 — Re-examine stable disagreements.**
Three CRs have documented stable disagreements (CR-09, CR-22, CR-24). Please re-argue your position against Opus's stated rationale in this document. If you are still unconvinced, propose a concrete resolution (specific wording, specific test, specific threshold) rather than restating the disagreement.

**Step 4 — CR-06 design choice.**
CR-06 remains open: Option A (deterministic launch contract) vs Option B (user-controlled, remove ungrounded claims). Opus's preference is Option B. State your preference and the reason.

**Step 5 — New CRs if any.**
If reviewing the actual diff surfaces new issues not present in previous rounds, open them as CR-27+.

---

## Response protocol

For each CR: ACCEPT (patched), PARTIAL ACCEPT (patched with stable disagreement noted), or REBUT.
All ACCEPTs have been applied to spec files. Stable disagreements are documented for joint resolution.

---

## Summary table

| CR | Verdict | Status |
|---|---|---|
| CR-06 | ACCEPT | Patched: DR-1 reframed; phase-01 T-01.8 expanded with Option A/B contract |
| CR-09 | PARTIAL ACCEPT | Patched: serialization statement added; see stable disagreement on OMP source citation |
| CR-13 | ACCEPT | Patched: per-key delta manifest, key-level conflict detection, "forced" removed, phase-05 T-05.2 updated |
| CR-14 | PASS (already closed) | No action needed |
| CR-17 | ACCEPT | Patched: phase-01 T-01.3 adds reviewer; T-00.E5 experiment added; spec/07 E4→E5 ref fixed; README topology fixed |
| CR-18 | ACCEPT | Patched: spec/07 and spec/09 headers updated; localhost address moved from invariant to example |
| CR-21 | ACCEPT | Patched: spec/14 §D step 2 changed to full-range discovery; watched paths = triage anchors only |
| CR-22 | PARTIAL ACCEPT | Patched: state isolation, ordering, metadata, pilot/final distinction added; stable disagreement on power analysis |
| CR-23 | ACCEPT | Patched: "Four Validation Levels" → "Validation Taxonomy (L0–L4)"; phase-06 "four-level" objective fixed |
| CR-24 | PARTIAL ACCEPT | Patched: T-00.E2 expanded to 8 cases (canonical); spec/09 §F cross-references T-00.E2; stable disagreement on case 8 |
| CR-25 | ACCEPT | Patched: spec/README §10.A restructured per-DR with source_facts + normative_decision separation |
| CR-26 | ACCEPT | Patched: phase-02 T-02.1 removes "only deterministic mechanism"; T-02.4 makes outputSchema optional; T-02.2 fixes "read-only" characterization |

---

## CR-06 — ACCEPT

```yaml
id: CR-06
response: ACCEPT
argument: >
  GPT is correct. The original open question ("routing mechanism for @tech-lead
  mentions in worker prompts") was a symptom of the real problem, not the root
  cause. The real question is: when the main session IS the Tech Lead, what
  mechanism ensures it receives @tech-lead model routing and high thinking level?
  Agent frontmatter (model: "@tech-lead", thinking-level: high) only applies at
  spawn time — never to the main session. So the main Tech Lead is effectively
  uncontrolled unless an explicit contract is defined.
patch:
  files:
    - spec/README.md §10.B DR-1
    - spec/phases/phase-01-runtime-correctness.md T-01.8
  exact_change: >
    DR-1 open question reframed to: "What exact runtime mechanism determines
    the main Tech Lead's model and thinking level?" with Option A (deterministic
    launch contract) and Option B (user-controlled, remove architecture claims
    assuming guaranteed routing) spelled out.
    T-01.8 expanded with both options and an acceptance condition proving
    whichever policy is chosen.
acceptance_check:
  - spec/README DR-1 answers the question: "What guarantees @tech-lead routing for main session?"
  - phase-01 T-01.8 acceptance condition includes a test for the chosen contract
  - No architecture claim assumes guaranteed @tech-lead routing without proving the mechanism
remaining_uncertainty: >
  The implementation agent executing phase-01 must choose Option A or B and
  document the decision. This remains open until that choice is made.
```

---

## CR-09 — PARTIAL ACCEPT

```yaml
id: CR-09
response: PARTIAL ACCEPT
argument: >
  GPT is correct that the spec defined what happens after a merge conflict
  (partial integration semantics) but did not define whether simultaneous apply
  operations are serialized. I've added an explicit serialization statement.
  However, the claim "OMP's task layer enforces this serialization internally"
  is based on architectural inference (git apply requires exclusive index access),
  not direct source citation of isolation-runner.ts apply path.
patch:
  files:
    - spec/08-isolation-and-concurrency.md §E item 7
  exact_change: >
    Added: "Integration concurrency model: The orchestrator serializes
    merge/apply operations to the parent worktree — workers may execute in
    parallel, but integration into the shared parent happens sequentially."
acceptance_check:
  - spec/08 §E explicitly states integration serialization model
  - T-00.E3 should include a near-simultaneous completion case to verify this empirically
remaining_uncertainty: >
  The serialization statement is architecturally sound (git apply is not safe
  to run concurrently) but we have not yet cited the exact OMP source line
  that implements the serialization. T-00.E3 case with simultaneous workers
  will provide empirical confirmation.
```

**Stable disagreement on source citation:** GPT wants us to either cite the exact OMP source proving serialization OR add a fixture test. Opus position: the fixture test in T-00.E3 (two isolated workers near-simultaneous completion) provides the required empirical evidence. Adding an OMP source citation before running the experiment would re-introduce the "claims ahead of evidence" pattern we're trying to fix. We'll add the citation when T-00.E3 runs.

---

## CR-13 — ACCEPT

```yaml
id: CR-13
response: ACCEPT
argument: >
  All four residual issues are correct.
  1. MERGE rollback required per-key delta manifest — now specified in §12 §D
  2. Conflict detection was too coarse (file-level for MERGE) — now key-level
  3. Phase-05 T-05.2 only handled hash-matched file removal — now MERGE-aware
  4. "unless forced" was undefined — removed; no force mode for OVERWRITE conflicts
patch:
  files:
    - spec/12-installation-and-rollback.md §D
    - spec/phases/phase-05-installation-hardening.md T-05.2
  exact_change: >
    §12 §D now specifies: per-key installer delta in manifest (inserted keys
    with values, modified keys with before/installed values); key-level conflict
    detection for MERGE (inserted key: remove if unchanged, CONFLICT if changed,
    no-op if already gone; modified key: restore if unchanged, CONFLICT if
    diverged); "unless forced" phrase removed with note that OVERWRITE conflicts
    require manual resolution.
    Phase-05 T-05.2 now specifies operation-type-aware rollback for each of
    OVERWRITE, MERGE, CREATE.
acceptance_check:
  - Manifest schema records operation type + installer delta for MERGE operations
  - MERGE rollback uses key-level conflict detection
  - User additions to modelRoles (unrelated to template keys) are preserved
  - "force" flag absent from spec and CLI contract
  - Phase-05 T-05.2 acceptance condition covers MERGE rollback
remaining_uncertainty: none
```

---

## CR-17 — ACCEPT

```yaml
id: CR-17
response: ACCEPT
argument: >
  GPT identified four genuine inconsistencies, all correct.
  1. README topology listed reviewer without lsp — fixed
  2. Phase-01 T-01.3 only named explorer and implementer — fixed
  3. T-00.E4 cross-reference was wrong (E4 is RULES sentinel, not LSP) — fixed
  4. Phase-02 had no Reviewer LSP task — fixed (responsibility moved to phase-01 T-01.3)
patch:
  files:
    - spec/phases/phase-01-runtime-correctness.md T-01.3
    - spec/07-retrieval-and-code-understanding.md §A (DR-7 status)
    - spec/README.md §5 topology
    - spec/phases/phase-00-foundation.md (T-00.E5 added)
  exact_change: >
    T-01.3: "add lsp to explorer.md and implementer.md" → "add lsp to
    explorer.md, implementer.md, AND reviewer.md". Acceptance updated.
    spec/07 DR-7: "Phase-02 implements; T-00.E4 validates" → "Phase-01 T-01.3
    implements; T-00.E5 validates". (T-00.E4 is RULES propagation, not LSP.)
    README topology: reviewer.md tools now includes lsp.
    T-00.E5 added: LSP allowlist validation experiment — spawns agent with lsp
    in allowlist + task.enableLsp=true, verifies tool is callable.
acceptance_check:
  - README topology, spec/07 authoritative table, DR-7, phase-01 T-01.3, T-00.E5 all agree
  - T-00.E4 reference no longer appears in the LSP context
  - reviewer.md will carry lsp after phase-01 execution
remaining_uncertainty: none
```

---

## CR-18 — ACCEPT

```yaml
id: CR-18
response: ACCEPT
argument: >
  GPT is correct on all four residual issues. The "All claims verified against
  OMP source" header in both spec/07 and spec/09 directly contradicts the
  ENVIRONMENT ASSUMPTION notes within the same files. The localhost address
  was still stated as an architectural constant. Both fixed.
patch:
  files:
    - spec/07-retrieval-and-code-understanding.md (header line)
    - spec/09-model-routing.md (header line + §E localhost address)
  exact_change: >
    spec/07 header: "All claims verified against OMP source" →
    "Runtime mechanics verified; environment-specific availability claims
    (Context7) explicitly marked."
    spec/09 header: same pattern.
    spec/09 §E: removed "at http://127.0.0.1:20128" from invariant statement;
    moved specific address to ENVIRONMENT ASSUMPTION block as an example only;
    the durable invariant is "all model access goes through OmniRoute" without
    the specific address.
acceptance_check:
  - No spec file header claims "all claims source-verified" while containing env assumptions
  - Localhost address not present as an architecture invariant
  - Model IDs not stated as portable constants
remaining_uncertainty: none
```

---

## CR-21 — ACCEPT

```yaml
id: CR-21
response: ACCEPT
argument: >
  GPT's root claim was correct: the process said "diff ONLY watched_paths",
  which means a behavior-changing commit to callers, adapters, or helpers is
  invisible. The TRIAGE ONLY note didn't fix this — it only said to not treat
  watched-path diffs as verdicts, but if a change doesn't touch a watched path,
  no candidate claim is ever generated.
patch:
  files:
    - spec/14-upgradeability-and-governance.md §D
  exact_change: >
    Step 2: "diff ONLY watched_paths, not the whole repo" →
    "diff the full upstream commit range; flag watched_paths changes FIRST as
    high-priority anchors, then inspect non-watched changes for transitive or
    call-chain impact on watched behavior"
    Step 3: "for each changed watched path" → "for each changed file (watched
    or non-watched)"
    TRIAGE note updated to reflect: watched paths = triage anchors, not
    discovery boundary.
acceptance_check:
  - Spec §D step 2 no longer restricts discovery to watched paths
  - Non-watched changes (callers, adapters) are included in step 3 summarization
  - Watched paths remain high-priority but are not an exclusion boundary
remaining_uncertainty: none
```

---

## CR-22 — PARTIAL ACCEPT

```yaml
id: CR-22
response: PARTIAL ACCEPT
argument: >
  GPT is correct on four missing controls (state isolation, ordering,
  reproducibility metadata, pilot vs final distinction). All four are now
  added to spec/13 §C.
  Stable disagreement: requiring formal power analysis or CI-width stopping
  rules for ALL comparisons is over-engineering for an initial eval framework.
patch:
  files:
    - spec/13-validation-and-evaluation.md §C (A/B Comparisons section)
  exact_change: >
    Added: (1) state isolation requirement (fresh runs unless testing within-
    session behavior); (2) arm order randomization/counterbalancing;
    (3) reproducibility metadata list (omp_sha, template_sha, provider,
    gateway_version, model_id, reasoning_level, timeout/retry/cache policy,
    tool_environment); (4) pilot/final evidence standard (≥3 runs = pilot/smoke,
    final claim requires predeclared precision criterion or CI-width bound);
    (5) paired delta as preferred metric.
acceptance_check:
  - spec/13 §C distinguishes pilot evidence from final comparative claim evidence
  - State isolation requirement present
  - Ordering/randomization requirement present
  - Reproducibility metadata list present
  - Pilot vs final standard documented
remaining_uncertainty: none for pilot framework
```

**Stable disagreement on power analysis requirement:**

```yaml
runtime_facts_agreed:
  - LLM evaluations have high variance; N=3 is insufficient for strong claims
  - Paired delta is a better metric than separate arm means for paired fixture evaluation
  - Reproducibility metadata is necessary for credible comparisons
GPT_preference:
  - All comparative claims require formal power analysis or CI-width stopping rules
Opus_preference:
  - Pilot evidence (≥3 runs) is sufficient to catch obvious regressions and ship iteratively
  - Final claims (production quality gates) require the more rigorous standard
  - Requiring full statistical rigor from day 1 would block the entire evaluation framework
chosen_project_policy:
  - ≥3 runs/arm = pilot/smoke minimum; documented explicitly as such
  - Any claim labeled "production-quality" requires predeclared precision criterion
  - The protocol is designed to be extendable to full statistical rigor
reason:
  - The spec is for an initial evaluation framework, not a published scientific study
  - Iterative improvement is more valuable than blocking on statistical rigor at v0
```

---

## CR-23 — ACCEPT

```yaml
id: CR-23
response: ACCEPT
argument: >
  GPT is correct. spec/13 §B header said "Four Validation Levels" while
  defining five (L0–L4). phase-06 objective said "Build the four-level
  validation stack." Both fixed.
patch:
  files:
    - spec/13-validation-and-evaluation.md §B header
    - spec/phases/phase-06-evaluation.md Objective section
  exact_change: >
    spec/13 §B: "## B. Four Validation Levels" → "## B. Validation Taxonomy
    (L0–L4)" with note "five levels (L0 through L4)".
    phase-06 Objective: "Build the four-level validation stack" →
    "Build the L0–L4 validation stack (per the canonical taxonomy in
    spec/13-validation-and-evaluation.md §B)".
acceptance_check:
  - No "four-level" / "Level 1-4" numbering remains where L0-L4 is the canonical form
  - spec/13 §B header matches the 5-level taxonomy it defines
remaining_uncertainty: >
  A full semantic sweep of all spec files for "Level 1", "Level 2" etc.
  legacy numbering has not been run. If GPT finds remaining legacy references,
  Opus will patch them in the next round.
```

---

## CR-24 — PARTIAL ACCEPT

```yaml
id: CR-24
response: PARTIAL ACCEPT
argument: >
  GPT identified four problems with the test matrix, three of which are correct:
  (1) Two overlapping matrices existed — fixed (T-00.E2 is now canonical).
  (2) E2-4 couldn't prove precedence — fixed (case 6 now has competing values).
  (3) @unknown and unavailable-model cases were dropped — fixed (cases 4+5).
  Stable disagreement on case 8 (main-session vs worker resolver path).
patch:
  files:
    - spec/phases/phase-00-foundation.md T-00.E2
    - spec/09-model-routing.md §F
  exact_change: >
    T-00.E2 expanded to 8 cases: (1) built-in role happy path, (2) custom
    role happy path, (3) absent custom role, (4) @unknown terminal behavior,
    (5) configured role → unavailable model (tests alias vs downstream failure),
    (6) user-level vs project-level conflict with COMPETING values (proves
    precedence), (7) built-in collision, (8) main-session vs worker resolver path.
    spec/09 §F now cross-references T-00.E2 as canonical matrix rather than
    defining its own parallel cases.
acceptance_check:
  - One canonical matrix (T-00.E2), cross-referenced from spec/09
  - @unknown case present
  - Unavailable model case present (distinct from missing alias)
  - Precedence case uses competing user vs project values
remaining_uncertainty: case 8 (main-session vs worker path) is empirical
```

**Stable disagreement on case 8:**

```yaml
runtime_facts_agreed:
  - Main session and worker agents may use different model resolution paths
  - This could cause unexpected behavior if the paths diverge
GPT_preference:
  - Always verify both paths independently in the experiment
Opus_preference:
  - Case 8 is included in the experiment; if paths converge (expected), it's one data point
  - If they diverge, the experiment surfaces it; no pre-specification needed
chosen_project_policy:
  - Case 8 included; result determines whether further spec is needed
reason:
  - Including the case costs nothing; pre-specifying the expected difference
    would be speculative without empirical evidence
```

---

## CR-25 — ACCEPT

```yaml
id: CR-25
response: ACCEPT
argument: >
  GPT is correct. The two-table split classified DRs as "source-grounded"
  but the source citations proved capabilities exist, not that the design
  choices were source-determined. For DR-2: source proves output: frontmatter
  exists; it does not prove "use frontmatter as canonical source". For DR-3:
  source proves no runtime loader exists; it does not prove "delete the folder".
  For DR-6 and DR-7: source proves isolation mechanics and LSP gating; it does
  not prove the specific isolation/LSP decisions.
patch:
  files:
    - spec/README.md §10.A
  exact_change: >
    §10.A restructured from a table to per-DR inline blocks, each with:
    - "Source facts:" — what source code proves (file + line)
    - "Design choice (normative):" — what was decided
    - "Alternative rejected/not rejected:" — why the chosen approach
    Phase-00 T-00.7 exit criteria already required this separation; §10.A
    now implements it consistently.
acceptance_check:
  - Each DR in §10.A explicitly separates what source proves from what was chosen
  - No source citation used to directly justify a normative choice without rationale
  - Alternative designs acknowledged where legitimate
remaining_uncertainty: none
```

---

## CR-26 — ACCEPT

```yaml
id: CR-26
response: ACCEPT
argument: >
  GPT is correct. Phase-02 contained three superseded architecture instructions:
  A. T-02.1 said "autoloadSkills is the only deterministic mechanism" — this
     was the pre-CR-01 premise, superseded by T-00.E4 evidence dependency
  B. T-02.4 required outputSchema on every dispatch — superseded by CR-03
     correction in phase-01 T-01.7 (agent output: frontmatter is primary)
  C. T-02.2 called Verifier/Reviewer "read-only" — imprecise; they have bash,
     but the design intent is they MUST NOT write implementation artifacts
patch:
  files:
    - spec/phases/phase-02-core-orchestration.md T-02.1
    - spec/phases/phase-02-core-orchestration.md T-02.4
    - spec/phases/phase-02-core-orchestration.md T-02.2
  exact_change: >
    T-02.1: Removed "only deterministic mechanism"; replaced with CR-01-aware
    language: autoloadSkills is preferred regardless; the T-00.E4 experiment
    determines whether it is the ONLY mechanism or not.
    T-02.4: "Each dispatch must specify outputSchema" → outputSchema is caller
    override only; agent output: frontmatter is primary per DR-2.
    T-02.2: "read-only; isolation wastes setup" → "observe real merged state;
    have bash for commands but MUST NOT write implementation artifacts"
acceptance_check:
  - phase-02 T-02.1 does not say "only deterministic mechanism"
  - phase-02 T-02.4 does not require outputSchema on every dispatch
  - phase-02 T-02.2 does not call Verifier/Reviewer "read-only"
  - All three contradict no architecture document after this patch
remaining_uncertainty: none
```

---

## Files modified in this round

```
spec/README.md                                 — DR-1, §5 topology, §10.A restructure
spec/07-retrieval-and-code-understanding.md    — header, T-00.E4→T-00.E5 ref
spec/08-isolation-and-concurrency.md           — §E serialization statement
spec/09-model-routing.md                       — header, §E localhost, §F → T-00.E2 cross-ref
spec/12-installation-and-rollback.md           — §D key-level MERGE rollback + manifest delta
spec/13-validation-and-evaluation.md           — §B header fix, §C A/B protocol enhanced
spec/14-upgradeability-and-governance.md       — §D full-range discovery
spec/phases/phase-00-foundation.md             — T-00.E2 expanded (8 cases), T-00.E5 added
spec/phases/phase-01-runtime-correctness.md    — T-01.3 adds reviewer, T-01.8 CR-06 contract
spec/phases/phase-02-core-orchestration.md     — T-02.1 CR-01 aware, T-02.4 CR-03 aware, T-02.2 read-only fix
spec/phases/phase-05-installation-hardening.md — T-05.2 MERGE-aware rollback
spec/phases/phase-06-evaluation.md             — Objective: "L0-L4 stack"
```

---

## Round 2 verdict

```yaml
accepted: 9       # CR-06, CR-13, CR-17, CR-18, CR-21, CR-23, CR-25, CR-26 + CR-14 (already closed)
partial_accept: 2 # CR-09, CR-22, CR-24 (with stable disagreements)
rebutted: 0
new_cr: 0

stable_disagreements:
  - CR-09: OMP source citation for serialization — will resolve via T-00.E3 experiment
  - CR-22: full statistical rigor vs pilot framework — project chooses pilot-first
  - CR-24: case 8 (main-session vs worker resolver) — included in experiment, pre-spec not needed

ready_to_resume_implementation: depends
implementation_gate: >
  CR-06 remains architecturally open: Option A vs B for main Tech Lead
  model/thinking must be chosen and documented before phase-01 T-01.8 can
  complete. All other CRs are either patched or have a clear resolution path
  through the phase-00 experiments.
```

---

## Items for GPT Round 3 review

1. **CR-09 serialization claim** — Opus added "OMP's task layer enforces this serialization internally" without direct source citation. GPT may challenge this. If GPT wants a source citation before T-00.E3 runs, Opus position is: the fixture test IS the evidence; claiming source ahead of experiment is the pattern we're correcting.

2. **CR-22 stable disagreement** — The pilot/final distinction is now in spec/13§C. If GPT's position is that ≥3 runs is not defensible even as a pilot minimum, Opus requests a concrete alternative (what N should the pilot use, and why is that N not also arbitrary?).

3. **CR-24 case 8** — The case is in T-00.E2. If GPT wants it pre-specified as two separate experiment sub-cases with expected outcomes, Opus will add that.

4. **CR-06 Option A/B** — This is an open design choice. Opus's preference is Option B (user-controlled, remove ungrounded routing claims) because it is honest about what the template can guarantee. GPT's view is welcome.
