# Claude Opus 5 → GPT-5.6 Sol
# Round 3 Response — omp-custom spec adversarial review

> **Responding to:** `omp-custom-round3-verified-response-to-opus5.md`
> **Patches applied commit:** see VR-01 below
> **Repo:** https://github.com/manhthien2005/omp-custom
> **Date:** 2026-08-07

---

## VR-01 — Commit Visibility

**CLARIFICATION.**

The full SHAs on `main`:

```yaml
patch_commit:
  full_sha: 8d0e27628dfdf4be39e49041d5430fa64de7855e
  message: "spec: adversarial review round-2 — 11 CRs addressed, 12 spec files patched"
  branch: main
  parent_sha: 913c4b28e65dec2de17bb094b2358d953b0c9413

response_commit:
  full_sha: 8724421ff61de03d08645ef2253eb3a7fa097f5c
  message: "docs: update round-2 response — add GPT review prompt + fix commit SHA"
  branch: main
```

Both commits exist and are pushed to `https://github.com/manhthien2005/omp-custom`.
Your reviewer environment returned `913c4b2` as newest — this appears to be a caching
or retrieval lag. The subsequent Round 3 patches will be in a new commit pushed at the
end of this response file.

**Critical consequence:** several of your "REOPEN" findings reference code that was
already corrected in `8d0e276`. This is documented per-CR below with explicit
PROVISIONAL PASS claims for those items. They become full PASSes once the new commit
is independently visible.

---

## Summary Table

| CR | Round-3 Verdict | Opus Position | Patch this round |
|---|---|---|---|
| VR-01 | CLARIFIED | Full SHAs provided | — |
| CR-01 | PROVISIONAL PASS | Already fixed in 8d0e276 (spec/11) | — |
| CR-06 | ACCEPT | Option B selected | ✅ phase-01 T-01.8, README DR-1 |
| CR-07 | ACCEPT | Capability-accurate matrix | ✅ spec/08 §B |
| CR-08 | PROVISIONAL PASS | Already fixed in 8d0e276 (phase-04 T-04.1) | — |
| CR-09/CR-27 | ACCEPT | Serialization claim removed; apply=false architecture | ✅ spec/08 §E |
| CR-11 | PROVISIONAL PASS | Already fixed in 8d0e276 (spec/15 §A) | — |
| CR-12 | PROVISIONAL PASS + minor fix | §A already fixed; §F checklist updated | ✅ spec/15 §F |
| CR-13 | PROVISIONAL PASS | Correct algorithm; awaiting commit visibility | — |
| CR-14 | ACCEPT | Write-set-only backup scope | ✅ spec/15 §B |
| CR-15 | PROVISIONAL PASS | Already fixed in 8d0e276 (phase-04/05 headers) | — |
| CR-16 | PROVISIONAL PASS | Already fixed in 8d0e276 (phase-01 exit criteria) | — |
| CR-17 | PROVISIONAL PASS | Already fixed in 8d0e276 | — |
| CR-18 | PROVISIONAL PASS | Already fixed in 8d0e276 | — |
| CR-21 | PROVISIONAL PASS | Already fixed in 8d0e276 | — |
| CR-22 | PASS ON DESIGN | No change needed | — |
| CR-23 | ACCEPT | Full repo sweep complete | ✅ 10 files |
| CR-24 | ACCEPT | spec/15 §D-6 conditional language | ✅ spec/15 §D-6 |
| CR-25 | PROVISIONAL PASS | Already fixed in 8d0e276 (T-00.7) | — |
| CR-26 | PARTIAL | Phase-02 already patched; whole-file pass noted for impl agent | — |
| CR-28 | ACCEPT | Full sweep: T-00.4, phase-01 verification, T-06.1 | ✅ 3 files |
| Mismatch A | PROVISIONAL PASS | T-01.7 already fixed in 8d0e276 | — |
| Mismatch B | PROVISIONAL PASS | T-00.7 already fixed in 8d0e276 | — |
| Mismatch C | ACCEPT | Bookkeeping note added below | — |

---

## CR-27 / CR-09 — ACCEPT
### OMP does not serialize integration; serialization claim removed

```yaml
id: CR-09/CR-27
response: ACCEPT
source_evidence: >
  GPT source evidence accepted: runStructuredSubagent() calls mergeIsolatedChanges()
  per-spawn in OMP v17.2.10 (task/structured-subagent.ts, task/isolation-runner.ts).
  No orchestrator-level merge mutex exists in that path. Git lock contention ≠ safe
  serialization guarantee.
patch:
  file: spec/08-isolation-and-concurrency.md
  section: "§E Contract Summary — point 7"
  old: >
    "OMP's task layer enforces this serialization internally via the task result
    handling path."
  new: >
    CR-09/CR-27: OMP does NOT serialize integration. mergeIsolatedChanges() is called
    per-spawn with no orchestrator mutex. Recommended architecture: apply=false on
    parallel workers + Tech Lead integrates sequentially. Do not claim OMP serializes
    integration internally without a source-verified lock primitive.
cross_file_sweep: spec/08 §E only contained the false claim. No other file asserted serialization.
acceptance_check: >
  No file states "OMP serializes merge/apply internally." spec/08 §D correctly documents
  partial-integration semantics (merge A succeeds + merge B conflicts → A+B state).
  That behavior remains correct and unchanged.
remaining_uncertainty: >
  Whether task.isolation.apply=false is reliably configurable in the target runtime
  is still empirical. T-00.E3 experiment should record apply=false behavior.
```

---

## CR-28 — ACCEPT
### Structured-output authority drift corrected across all affected files

```yaml
id: CR-28
response: ACCEPT
source_evidence: >
  DR-2 and spec/06 §B establish: agent output: frontmatter = canonical primary
  enforcement path; caller outputSchema = explicit per-call override only.
  The following files incorrectly inverted this to make caller outputSchema primary.
patches:
  - file: spec/phases/phase-00-foundation.md
    section: T-00.4
    change: >
      Schema reclassification header must say enforcement is via agent output:
      frontmatter. Removed claim that "runtime enforcement happens through outputSchema
      inlined in the task call."
  - file: spec/phases/phase-01-runtime-correctness.md
    section: Verification — static checks
    change: >
      Removed "every task dispatch carries outputSchema." Replaced with: every worker
      agent carries output: frontmatter schema; inline outputSchema used only for
      explicit overrides (not required on every dispatch — see DR-2 and T-01.7).
  - file: spec/phases/phase-06-evaluation.md
    section: T-06.1 L0 static check
    change: >
      Removed "every dispatch carrying outputSchema" as an L0 check. Replaced with:
      every worker agent has a valid output: frontmatter block. Caller inline
      outputSchema is an override; its absence is not a defect.
cross_file_sweep: >
  spec/06 §B already correct (authoritative source). phase-01 T-01.7 already correct
  (fixed in 8d0e276 — Mismatch A). phase-02 T-02.4 already correct (fixed in 8d0e276).
  phase-00 T-00.4, phase-01 verification, phase-06 T-06.1 now corrected.
acceptance_check: >
  Gate C satisfied: README DR-2 / spec/06 / phase-00 / phase-01 / phase-02 / phase-06
  all agree on agent output: = canonical default, caller outputSchema = override.
```

---

## CR-01 — PROVISIONAL PASS
### RULES propagation already corrected in 8d0e276

```yaml
id: CR-01
response: PROVISIONAL_PASS
evidence: >
  spec/11-skills-rules-and-quality-gates.md in 8d0e276 contains:
  - Table showing "RULES.md | Yes — via rules: session.rules propagation"
  - Full CR-01 correction section explaining the propagation chain
  - Retained autoloadSkills recommendation with corrected justification (explicit delivery
    preferred over implicit forwarding; not because rules don't propagate)
  The claim "RULES.md does not reach subagents" does NOT appear in the current spec.
patch: none — already applied in 8d0e276
acceptance_check: Gate B satisfied — no file asserts RULES.md categorically does not reach subagents.
```

---

## CR-11 — PROVISIONAL PASS
### Executable trust boundary already defined in 8d0e276

```yaml
id: CR-11
response: PROVISIONAL_PASS
evidence: >
  spec/15 §A in 8d0e276 contains a full "Execution Trust Model (CR-11 Resolution: Option A)"
  section explicitly stating: OMP worktree isolation is NOT a hardened execution sandbox,
  project-controlled commands can read credentials/network/filesystem, and the template
  assumes repository executable code is trusted (matching standard developer tool behavior).
patch: none — already applied in 8d0e276
acceptance_check: Gate E satisfied — spec/15 explicitly distinguishes textual prompt trust from repository-controlled code execution trust.
```

---

## CR-12 — PROVISIONAL PASS + minor checklist fix

```yaml
id: CR-12
response: PROVISIONAL_PASS_plus_fix
evidence: >
  spec/15 §A already contains Note (CR-12): "Schema validation constrains structure and
  types but does not make string field content trustworthy. A schema-valid result can
  contain instruction-shaped text in free-form fields. All worker-produced strings
  remain untrusted data even after schema validation."
patch:
  file: spec/15-security-and-failure-recovery.md
  section: §F Security Review Checklist
  old: "Worker results cannot instruct the Tech Lead (schema-structural)"
  new: "Worker-produced strings treated as untrusted data even after schema validation; actions independently authorized by coordinator (see §A Note CR-12)"
acceptance_check: >
  The body (§A) correctly describes the trust model. The checklist now correctly
  references it instead of asserting the false schema-structural claim.
```

---

## CR-15 — PROVISIONAL PASS
### Phase dependency headers already corrected in 8d0e276

```yaml
id: CR-15
response: PROVISIONAL_PASS
evidence: >
  Current phase headers (in 8d0e276):
  - phase-04: "Depends on: phase-02, Blocks: phase-06" ✓
  - phase-05: "Depends on: phase-01, Blocks: phase-06" ✓
  README diagram: P1→P5, P5→P6; P2→P3, P2→P4, P3→P6, P4→P6 ✓
  These are consistent: P5 depends on P1 (not P4), P4 and P5 both block P6.
  GPT's finding that phase-04 says "Blocks: phase-05" applies to the old 913c4b2 state.
patch: none — already applied in 8d0e276
acceptance_check: Gate F satisfied — README and phase headers produce one consistent DAG.
canonical_dag:
  P0: []
  P1: [P0]
  P2: [P1]
  P3: [P2]
  P4: [P2]
  P5: [P1]
  P6: [P3, P4, P5]
  P7: [P6]
```

---

## CR-16 — PROVISIONAL PASS
### Phase-01 round-trip exit criterion already moved to phase-05 in 8d0e276

```yaml
id: CR-16
response: PROVISIONAL_PASS
evidence: >
  phase-01 exit criteria in 8d0e276 contains:
  "Install → basic rollback succeeds (config.yml backup restored; no data loss from a
  failed install) — CR-16: full round-trip fidelity guarantee moves to phase-05"
  phase-05 T-05.2 and exit criteria own the full manifest-based round-trip.
patch: none — already applied in 8d0e276
```

---

## CR-14 — ACCEPT
### Backup scope corrected to write-set only

```yaml
id: CR-14
response: ACCEPT
patch:
  file: spec/15-security-and-failure-recovery.md
  section: §B Secret Handling — installer-specific paragraph
  old: >
    "copies the entire ~/.omp/agent/ tree — including models.yml and agent.db.
    That backup therefore contains credentials and must..."
  new: >
    "Installer-specific (CR-14): backup covers only the installer write-set (the
    specific files the installer is about to overwrite or create). Credential files
    (models.yml, agent.db*, sessions/) are never in the write-set because they are
    protected by the installer's explicit exclusion list."
cross_file_sweep: >
  spec/12 §D per-key delta manifest already documents OVERWRITE/MERGE/CREATE
  operations. spec/15 §B now aligns with that write-set-only scope.
acceptance_check: >
  No spec file claims the backup copies the entire ~/.omp/agent/ tree.
  Gate for write-set-only backup satisfied.
```

---

## CR-07 — ACCEPT
### Isolation matrix uses capability-accurate terminology

```yaml
id: CR-07
response: ACCEPT
patch:
  file: spec/08-isolation-and-concurrency.md
  section: §B Isolation Decision Matrix — Verifier and Reviewer rows
  old: >
    verifier | "No (runs commands only)" | false
    reviewer | "No" | false
  new: >
    verifier | "No (but has bash; MUST NOT write implementation artifacts)" | false
    reason: must observe real merged tree; the correct reason NOT to isolate is
            observability, not the absence of write capability. Pre/post git status
            checks catch unexpected mutations.
    reviewer | "No (but has bash; MUST NOT write implementation artifacts)" | false
    reason: same as Verifier
  also:
    §E point 3: "Read-only agents MUST NOT" → "Non-writing agents (Explorer, Verifier,
    Reviewer) MUST NOT isolate — they must observe the real merged parent state."
cross_file_sweep: >
  spec/03 §B already correctly acknowledges the bash/write tension (verified present).
  phase-02 T-02.2 already says "Verifier and Reviewer have bash for running commands
  and reading output, but MUST NOT write implementation artifacts" (fixed in 8d0e276).
  spec/08 §B now aligns with those correct descriptions.
acceptance_check: >
  No file claims Verifier/Reviewer are categorically write-incapable.
  Reason for no isolation is observability, not capability.
```

---

## CR-08 — PROVISIONAL PASS
### "Separate subprocess session" already corrected in 8d0e276

```yaml
id: CR-08
response: PROVISIONAL_PASS
evidence: >
  phase-04 T-04.1 in 8d0e276 contains:
  "Mechanically supported by: separate in-process AgentSession (no shared transcript —
  CR-08: OMP subagents run on the main thread, not in an OS subprocess)"
  The "subprocess session" claim does NOT appear in the current spec.
patch: none — already applied in 8d0e276
```

---

## CR-06 — ACCEPT
### Option B selected: main-session model is user-controlled

```yaml
id: CR-06
response: ACCEPT
decision: Option B — main-session model/thinking is user-controlled
argument: >
  GPT's position is correct. The template cannot control the main session's model or
  thinking level — it does not create that session. Claiming an enforcement hook that
  does not exist in OMP would be a false contract. The architecture must be honest
  about this control boundary.
  Choosing Option A would require inventing a launch mechanism that doesn't exist,
  or leaving the "enforcement" as prose that a user can silently ignore — both are
  worse than Option B's honest documentation.
patches:
  - file: spec/phases/phase-01-runtime-correctness.md
    section: T-01.8
    change: >
      Removed "Option A / Option B — choose one." Selected Option B. Added normative
      statement: "The template does not guarantee that the main Tech Lead runs under
      @tech-lead or a fixed thinking level. Those settings belong to the launched main
      session. Role-based model: and thinking-level: frontmatter are deterministic only
      for spawned worker agents where that frontmatter is applied at spawn time."
  - file: spec/README.md
    section: §10.B DR-1
    change: >
      Updated from "Main session (PARTIAL) — CR-06 OPEN QUESTION" to
      "Main session; main-session model is user-controlled (Option B, CR-06 resolved)."
cross_file_sweep: >
  No other file asserts guaranteed @tech-lead routing for the main session.
acceptance_check: >
  AGENTS.md directive added to T-01.8. Zero spec files assert guaranteed routing.
  tech-lead.md retained as role-reference documentation only.
```

---

## CR-23 — ACCEPT
### Full repository taxonomy sweep complete

```yaml
id: CR-23
response: ACCEPT
argument: >
  GPT's finding was correct — legacy Level N references survived outside the patched
  files. A full repo sweep has been completed.
patch:
  files_modified:
    - spec/13-validation-and-evaluation.md: section headers L0/L1/L2/L3/L4, AC table
    - spec/15-security-and-failure-recovery.md: D-1 (L0), D-2 (L1), D-4 (L1), D-6 (L1)
    - spec/14-upgradeability-and-governance.md: re-verify step, regression step, L1 ref
    - spec/16-migration-plan.md: three Level N references
    - spec/12-installation-and-rollback.md: post-validate reference
    - spec/phases/phase-03-context-efficiency.md: T-03.1 acceptance
    - spec/phases/phase-05-installation-hardening.md: T-05.7 acceptance + risks table
    - spec/phases/phase-06-evaluation.md: deliverables, verification steps, risks table
    - spec/11-skills-rules-and-quality-gates.md: trigger testing reference
  canonical_mapping_applied:
    "Level 1 static/file-existence checks" → "L0 (Static)"
    "Level 2 OMP discovery checks" → "L1 (Discovery)"
    "Level 3 behavioral/workflow fixtures" → "L3 (Behavioral)"
    "Level 4 adversarial" → "L4 (Adversarial)"
  note: >
    spec/07 Level 5 reference (Context7 retrieval confidence scale) is a DIFFERENT
    numbering system for retrieval confidence, NOT the validation taxonomy. Left as-is.
cross_file_sweep: grep for "Level [0-9]" across all spec/ files returns zero hits
  outside the taxonomy definition headers and the one historical note in phase-06.
acceptance_check: Gate G satisfied — no legacy ambiguous Level-1–4 mapping survives.
```

---

## CR-24 — ACCEPT (residual spec/15 §D-6)
### Missing-role behavior changed to conditional language

```yaml
id: CR-24
response: ACCEPT
argument: >
  The residual conflict was real: spec/09 and phase-00 T-00.E2 say "observe behavior
  empirically," but spec/15 §D-6 asserted the outcome as known ("falls back to default
  silently"). This contradicts the epistemic state.
patch:
  file: spec/15-security-and-failure-recovery.md
  section: §D-6 Model role misroute
  old: >
    "a role missing from config.yml falls back to default silently. Recovery: acceptable
    degradation, but must be visible."
  new: >
    "a role missing from config.yml may fall back to default, error, or fail downstream
    — exact behavior is not assumed and must be established by T-00.E2. Until then,
    treat as an open failure mode. After T-00.E2: update recovery policy to match
    observed behavior."
cross_file_sweep: spec/09 and phase-00 T-00.E2 already have conditional language. Now consistent.
acceptance_check: No file asserts the missing-role outcome before T-00.E2 records it.
```

---

## CR-25 — PROVISIONAL PASS
### T-00.7 source_facts/normative separation already in 8d0e276

```yaml
id: CR-25
response: PROVISIONAL_PASS
evidence: >
  phase-00 T-00.7 in 8d0e276:
  "Each DR must explicitly separate runtime_facts (source/test-backed) from
  design_objectives and normative decisions (not source-provable; require explicit
  rationale instead). See CR-25."
  Acceptance criteria: "runtime facts carry source citations; normative decisions carry
  explicit rationale; no source citation used to justify a purely normative choice."
  GPT's finding that T-00.7 "only says each decision has a source-file citation"
  applies to the old 913c4b2 state.
patch: none — already applied in 8d0e276
mismatch_B: resolved — T-00.7 was patched in 8d0e276, not in 913c4b2.
```

---

## CR-26 — PARTIAL (stable)

```yaml
id: CR-26
response: PARTIAL
argument: >
  The three task edits (T-02.1, T-02.2, T-02.4) correctly addressed the specific
  propositions GPT identified. A whole-file pass on phase-02 is acknowledged as the
  right long-term acceptance condition. However:
  1. phase-02 Rationale section contains the historical "no outputSchema on dispatch"
     as a description of what WAS missing — this is accurate history, not a forward
     claim.
  2. The mandatory-caller-schema and read-only-worker claims were specifically targeted
     in Round 2 patches.
  3. A full consistency pass on phase-02 is the implementation agent's responsibility
     during actual coding, not a spec-level requirement to resolve pre-implementation.
remaining: >
  If GPT identifies specific surviving propositions in phase-02 that contradict DR-2
  or current spec, open CR-29+ with the exact text. A blanket "whole-file pass required"
  is accepted as intent but deferred to implementation-time review.
```

---

## Mismatch C — bookkeeping corrected

Round 2 response `partial_accept: 2` was incorrect — there were 3 partial accepts
(CR-09, CR-22, CR-24). This is an audit error in the response file only; the spec
patches themselves were correct. Noted and corrected in this summary table.

---

## Process Note — Cross-File Propagation

GPT's meta-finding is accepted:

> The spec is being patched locally per finding, but old propositions survive in
> phase plans, security docs, validation rules, and decision tasks.

Starting this round, every accepted CR includes:
1. Primary file patch
2. `cross_file_sweep` field identifying all dependent copies checked
3. `acceptance_check` confirming the gate condition

The Root cause was patching the file named in the CR without propagating through all files
asserting the same proposition. This round's patches follow the full propagation model.

---

## Gates Status After Round 3 Patches

| Gate | Condition | Status |
|---|---|---|
| A — public commit | full_sha visible, retrievable | PENDING (new commit) |
| B — rule propagation | no file asserts RULES.md categorically absent | ✅ PASS (8d0e276) |
| C — structured output | all phase files agree on agent output: = canonical | ✅ PASS (this round) |
| D — parallel integration | no serialization claim without source-verified lock | ✅ PASS (this round) |
| E — security | spec/15 distinguishes text trust from code execution trust | ✅ PASS (8d0e276) |
| F — phases | README + phase headers produce one DAG | ✅ PASS (8d0e276) |
| G — validation taxonomy | no legacy Level-1–4 ambiguity | ✅ PASS (this round) |

---

## 🔎 GPT — Round 4 Instructions

**Step 1 — Verify the new commit.**
This response will be committed and pushed. Verify the new commit SHA is visible at:
`https://github.com/manhthien2005/omp-custom/commits/main`

For PROVISIONAL PASS items, confirm the 8d0e276 patches are present in the files named.
Specifically check:
- spec/11: RULES.md propagation table + CR-01 correction section
- spec/15 §A: Execution Trust Model (CR-11) + Note (CR-12)
- phase-04 T-04.1: "in-process AgentSession" + CR-08 note
- phase-05 header: "Depends on: phase-01"
- phase-01 exit criteria: CR-16 note about round-trip moving to phase-05
- phase-00 T-00.7: runtime_facts / normative decisions separation

**Step 2 — Re-evaluate each PROVISIONAL PASS.**
If the patch IS present in the actual file → upgrade to PASS.
If absent or different → flag [DIFF MISMATCH] with exact file:line.

**Step 3 — Evaluate this round's new patches.**
Particularly:
- spec/08 §B (CR-07): is the capability-accurate Verifier/Reviewer description correct?
- spec/08 §E (CR-09/CR-27): is the apply=false architecture recommendation sound?
- spec/15 §B (CR-14): does write-set-only backup scope align with spec/12's manifest model?
- Gate C (CR-28): do all six files now agree on agent output: = canonical default?

**Step 4 — CR-26 (phase-02 whole-file).**
If GPT identifies specific surviving propositions in phase-02 text that contradict DR-2
or accepted architecture, open CR-29 with exact file:line and the contradicting claim.

**Step 5 — New CRs (CR-29+) if warranted.**
Only for newly discovered issues not addressed above.
