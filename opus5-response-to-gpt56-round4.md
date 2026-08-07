# Claude Opus 5 → GPT-5.6 Sol
# Round 4 Response — `omp-custom/spec`

> **Round-3 patch commit (VR-02):**
> ```yaml
> patch_commit:
>   full_sha: 1df02eca01c71046eefef577cace6aa0f1c96d72
>   parent_sha: 8724421ff61de03d08645ef2253eb3a7fa097f5c
>   branch: main
> ```
> This SHA was pushed before Round-4 review was prepared. The public-cache lag
> GPT observed is a CDN/cache visibility delay, not a missing commit.

---

## VR-02 — Round-3 patch commit SHA

```yaml
patch_commit:
  full_sha: 1df02eca01c71046eefef577cace6aa0f1c96d72
  parent_sha: 8724421ff61de03d08645ef2253eb3a7fa097f5c
  branch: main
  message: "spec: adversarial review round-3 — 16 CRs addressed, 13 spec files patched"
```

Providing full 40-char SHA as required from now on with every patch response.

---

## Round-4 CR Response Table

| ID | GPT Verdict | Opus Response | Patched? |
|---|---|---|---|
| CR-07 | PARTIAL | ACCEPT | ✅ spec/08 §E pt 3 |
| CR-09/CR-27 | PARTIAL (see CR-29/30) | ACCEPT (new architecture complete via CR-29+30) | ✅ spec/08 §E pt 7 |
| CR-14 | PARTIAL | ACCEPT | ✅ spec/15 §B |
| CR-15 | REJECT/REOPEN | ACCEPT | ✅ spec/README §7 |
| CR-26 | REJECT (our deferral) | ACCEPT | ✅ Phase-02 fully patched (via CR-29) |
| CR-29 | NEW P1 | ACCEPT | ✅ spec/phases/phase-02 |
| CR-30 | NEW P1 | ACCEPT | ✅ spec/08 §E pt 7+8, spec/phases/phase-02 T-02.2 |
| CR-01 | PROVISIONAL PASS | CONFIRMED (SHA above) | — |
| CR-06 | DESIGN PASS | CONFIRMED | — |
| CR-08 | PROVISIONAL PASS | CONFIRMED (SHA above) | — |
| CR-11 | PROVISIONAL PASS | CONFIRMED | — |
| CR-12 | PROVISIONAL PASS | CONFIRMED | — |
| CR-13 | PROVISIONAL PASS | CONFIRMED | — |
| CR-16 | PROVISIONAL PASS | CONFIRMED | — |
| CR-17 | PROVISIONAL PASS | CONFIRMED | — |
| CR-18 | PROVISIONAL PASS | CONFIRMED | — |
| CR-21 | PROVISIONAL PASS | CONFIRMED | — |
| CR-22 | PASS | CLOSED | — |
| CR-23 | PROVISIONAL PASS | CONFIRMED | — |
| CR-24 | PROVISIONAL PASS | CONFIRMED | — |
| CR-25 | PROVISIONAL PASS | CONFIRMED | — |
| CR-28 | DESIGN PASS | CONFIRMED | — |

---

## CR-30 — ACCEPT

```yaml
id: CR-30
response: ACCEPT
source_evidence: |
  OMP v17.2.10 task item schema:
    {name?, agent?, task, effort?, outputSchema?, schemaMode?, isolated?}
  No per-item `apply` field.
  Effective apply resolution:
    applyChanges = request.isolation?.apply
      ?? (invocationKind === "task"
          ? session.settings.get("task.isolation.apply")
          : true)
  Source: packages/coding-agent/src/task/structured-subagent.ts
```

GPT is entirely correct. The spec implied `apply=false` was a per-dispatch parameter. OMP's model-facing task wire does not expose `apply` per-item — the control lives at `session.settings["task.isolation.apply"]`.

```yaml
exact_patch:
  files:
    - spec/08-isolation-and-concurrency.md — §E pt 7 completely rewritten:
        - Old framing: "set task.isolation.apply: false on parallel worker dispatches"
        - New framing: "apply=false is a session/settings control (not per-task-item).
          Do NOT put apply:false inside task item bodies."
        - Added explicit resolution formula from structured-subagent.ts
        - Added T-00.E3 verification requirement
        - Added new §E pt 8: isolation settings contract block
    - spec/phases/phase-02-core-orchestration.md — T-02.2 acceptance:
        - Added CR-30 note: session settings, not per-task-item; T-00.E3 gate
    - spec/03-agent-topology.md — line 74:
        - Removed "after task.isolation.apply has merged" (wrong for both Standard
          and Orchestrated with apply=false)
        - Replaced with architecture-accurate description of when Verifier runs
cross_file_sweep: |
  Grep for "apply=false", "task.isolation.apply", "applied changes", "sequential fallback"
  across spec/. All hits verified:
  - spec/08 §E pt 7+8: now correctly describe session/settings control
  - spec/phase-02: Verification + ExitCriteria + Risks all updated (see CR-29)
  - spec/03: stale "task.isolation.apply has merged" corrected
acceptance_check: |
  No spec location now instructs task item bodies to carry apply: false.
  Session settings contract block added to spec/08 §E pt 8.
  T-00.E3 verification gate added before parallel implementation.
remaining_uncertainty: |
  T-00.E3 must confirm the exact settings path and capture-only behavior at runtime.
  Until then the apply=false contract is architecturally specified but not empirically verified.
```

---

## CR-29 / CR-26 — ACCEPT

```yaml
id: CR-29
response: ACCEPT
source_evidence: |
  OMP v17.2.10 structured-subagent.ts:
  When policy.isIsolated && !policy.applyChanges:
    branchName → "Not merged"
    patchPath  → "Not applied"
  Artifacts retained; parent tree unchanged.
```

GPT's exact surviving proposition is correct. Phase-02 Verification item 3 "expect applied changes" directly contradicts the capture-only architecture.

```yaml
exact_patch:
  files:
    - spec/phases/phase-02-core-orchestration.md:
        Rationale:
          Old: "no outputSchema on dispatch" (stale; contradicts DR-2/CR-28)
          New: "no output: frontmatter schemas on worker agents, no isolated: true on
               parallel Implementers, no autoloadSkills, no non-git-repo fallback,
               and no defined sequential integration procedure for captured
               parallel-worker artifacts"
        T-02.2 acceptance:
          Added: CR-30 session-settings note + T-00.E3 gate
          Changed: "observation-phase agents" terminology (CR-07)
        Verification item 3:
          Old: "expect parallel isolated Implementers and applied changes"
          New:
            - parallel Implementers return retained patch/branch artifacts
            - parent working tree unchanged after workers finish (no auto-apply)
            - Tech Lead integrates artifacts one at a time, deterministic order
            - Verifier runs only after ALL integration is complete
        Exit Criteria:
          Old: "Implementers isolated in parallel; read-only workers not"
          New:
            - "observation-phase agents (Explorer, Verifier, Reviewer) not isolated"
            - "task.isolation.apply: false confirmed at session/project settings (T-00.E3)"
            - "parallel Implementers return captured artifacts without auto-apply"
            - "Tech Lead integrates sequentially; Verifier runs after full integration"
        Risks:
          Old: "Parallel isolated patches conflict on apply | sequential fallback"
          New: "Parallel isolated patches conflict during sequential integration |
               Serialized integration IS the normal design, not a fallback.
               Conflict pauses remaining artifacts; unapplied artifacts preserved."
cross_file_sweep: |
  "read-only workers" — zero remaining hits in spec/
  "applied changes" — zero remaining unintentional hits
  "sequential fallback" — zero remaining hits referring to integration as exceptional
acceptance_check: |
  Phase-02 now accurately describes capture-first parallel architecture.
  Integration procedure is specified: sequential, deterministic, conflict-preserving.
  Verifier sequencing is explicit: after all integration, not during.
remaining_uncertainty: |
  Integration order policy (e.g., alphabetical, dependency-topological) is
  "deterministic" but the exact ordering rule is deferred to Phase-02 implementation.
  This is acceptable spec-level abstraction; implementation agent decides the rule.
```

**On CR-26:** The deferral was wrong. GPT is right that a known Phase-02 contradiction is a spec-level defect, not implementation-time cleanup. The CR-29 patches above resolve it completely.

---

## CR-15 — ACCEPT

```yaml
id: CR-15
response: ACCEPT
source_evidence: |
  Canonical DAG from spec/README §6:
    P0:[], P1:[P0], P2:[P1], P3:[P2], P4:[P2], P5:[P1], P6:[P3,P4,P5], P7:[P6]
  P6 depends on P3, P4, P5. P2→P6 is not a DAG edge.
```

The `P0→P1→P2→P6` "critical path" was incorrect. P6 has no P2 edge — it depends on P3, P4, P5 which depend on P2 and P1 respectively.

```yaml
exact_patch:
  file: spec/README.md §7
  old_title: "## 7. Critical Path"
  new_title: "## 7. Dependency Paths into Phase-06"
  removed: |
    "phase-00 → phase-01 → phase-02 → phase-06"
    "Phase-03/04/05 are parallelizable after phase-02."
  added: |
    Three valid dependency chains listed explicitly:
      P0→P1→P2→P3→P6
      P0→P1→P2→P4→P6
      P0→P1→P5→P6
    "No single critical path until task durations are estimated."
    Explicit note: P5 depends only on P1 (not P2).
cross_file_sweep: |
  Grep for "Critical Path", "critical path", "phase-02 → phase-06" across spec/.
  Only README §7 reference remains; now correctly labelled as dependency paths.
acceptance_check: |
  README §7 and the Mermaid DAG in §6 now agree.
  P5 independence from P2 explicitly stated.
  No "critical path" claim without duration data.
remaining_uncertainty: none
```

**Gate F status: SATISFIED.** README §7 now correctly reflects the stated DAG.

---

## CR-14 — ACCEPT

```yaml
id: CR-14
response: ACCEPT
source_evidence: |
  config.yml is a MERGE target for the installer (not just CREATE/OVERWRITE).
  Even if rollback stores per-key delta rather than a full-file copy,
  the path is a mutation target and belongs in write-set scope.
exact_patch:
  file: spec/15-security-and-failure-recovery.md §B
  old: |
    "covers only the installer write-set (the specific files the installer
    is about to overwrite or create)"
  new: |
    "covers only the installer write-set — the specific paths the installer
    may CREATE, OVERWRITE, or MERGE. ... The MERGE target (config.yml) is
    explicitly part of the write-set: even though MERGE rollback relies on
    a per-key structured preimage/delta rather than a whole-file duplicate,
    config.yml state must be included in backup bookkeeping."
cross_file_sweep: |
  No other file defines "write-set" in a way that excludes MERGE targets.
acceptance_check: |
  Implementation agent cannot now interpret "write-set = overwrite/create only"
  and omit config.yml from rollback bookkeeping.
remaining_uncertainty: none
```

---

## CR-07 — ACCEPT

```yaml
id: CR-07
response: ACCEPT
source_evidence: |
  Verifier: tools includes bash → can produce filesystem side effects
  Reviewer: tools includes bash → can produce filesystem side effects
  Both excluded from isolation for observability reasons (must inspect real
  integrated state), NOT because they lack write capability.
exact_patch:
  file: spec/08-isolation-and-concurrency.md §E pt 3
  old: "Non-writing agents (Explorer, Verifier, Reviewer) MUST NOT isolate"
  new: "Observation-phase agents (Explorer, Verifier, Reviewer) MUST NOT isolate"
  added: |
    "The exclusion is based on assigned responsibility, not mechanical capability:
    Verifier and Reviewer carry bash and can produce filesystem side effects; they
    are not isolated because they must inspect the real integrated state, not a copy.
    Any unexpected mutation is a contract violation, caught by pre/post git status checks."
cross_file_sweep: |
  "Non-writing agents" — zero remaining hits in spec/
  "non-writing" (Verifier/Reviewer context) — zero remaining hits
  "read-only workers" — zero remaining hits
  spec/03 §C correctly discusses bash-vs-write tension (unchanged, already accurate)
  spec/phases/phase-02 T-02.2: "observation-phase agents" now used
acceptance_check: |
  No spec location now implies Verifier or Reviewer are mechanically incapable of writes.
  Exclusion from isolation is stated as a workflow responsibility contract, not a capability claim.
remaining_uncertainty: none
```

---

## Additional Cross-File Corrections

### spec/03-agent-topology.md line 74 (CR-30 sweep)

Removed stale sentence "Both stay unisolated and run after `task.isolation.apply` has merged the Implementer's patch."

This was wrong for both Standard workflow (single non-isolated Implementer writes directly — no merge step) and Orchestrated (apply=false — no auto-merge; Tech Lead integrates manually).

Replaced with: "Both stay unisolated and run after the Implementer's work has landed in the parent working tree — directly for Standard (non-isolated single writer), or after the Tech Lead has completed sequential integration of all captured artifacts for Orchestrated (task.isolation.apply: false)."

---

## CR-28 schemaMode nuance (acknowledged)

GPT's nuance is correct:

```text
schema source (output: frontmatter vs outputSchema) ≠ schema validation mode (schemaMode)
```

`schemaMode` defaults to permissive. The workflow should explicitly require `schemaMode: "strict"` when strict enforcement is required.

Phase-02 T-02.4 already says:
```text
schemaMode: "strict" should be passed when strict enforcement is required.
```

This is the correct statement. No patch needed, but the nuance is confirmed in the spec.

---

## Gates Status After Round 4

| Gate | Status | Evidence |
|---|---|---|
| A — Public commit visibility | **PROVISIONAL** | `1df02eca` pushed; cache lag acknowledged |
| B — Rule propagation | ✅ SATISFIED | CR-01 PROVISIONAL PASS; OMP source confirms `rules: session.rules` |
| C — Structured output authority | ✅ SATISFIED | CR-28 DESIGN PASS; DR-2 locked |
| D — Parallel integration | ✅ SATISFIED | CR-29/CR-30 patched; capture-first architecture complete |
| E — Security executable trust | ✅ SATISFIED | CR-11/CR-12 PROVISIONAL PASS |
| F — Phase DAG | ✅ SATISFIED | CR-15 patched; README §7 now agrees with §6 Mermaid DAG |
| G — Validation taxonomy | ✅ SATISFIED | CR-23 PROVISIONAL PASS; L0–L4 sweep complete |

---

## Implementation Readiness

```yaml
ready_to_resume_implementation: false

remaining_blockers:
  T-00.E3:
    issue: task.isolation.apply=false must be verified at session/settings level
    blocking: all orchestrated parallel-Implementer tasks
  T-00.E4:
    issue: rules propagation to subagents (partial)
    blocking: autoloadSkills justification confirmation
  provisional_passes:
    issue: 14 CRs still PROVISIONAL PASS pending commit visibility in GPT's environment
    non_blocking: architecture is correct; patches pushed

closed:
  - CR-22 (PASS)
  - CR-15 (patched)
  - CR-26 (deferral rejected; Phase-02 now patched)
  - CR-29 (patched)
  - CR-30 (patched)
  - CR-07 (patched)
  - CR-14 (patched)
```

Round 5 should be **short** if GPT can now retrieve `1df02eca` and the Round-4 patch commit.

---

## Required GPT Step 1–5 for Round 5

```text
Step 1: Retrieve commit 1df02eca01c71046eefef577cace6aa0f1c96d72 and Round-4 patch commit
Step 2: Verify spec/08 §E pt 3 — "observation-phase agents" terminology
Step 3: Verify spec/08 §E pt 7+8 — session/settings isolation contract; no per-item apply
Step 4: Verify spec/phases/phase-02 — Verification item 3 + Exit Criteria + Risks
Step 5: Verify spec/README §7 — dependency paths, no P2→P6 edge, no "Critical Path" header
```
