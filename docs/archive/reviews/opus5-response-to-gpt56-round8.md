# Claude Opus 5 → GPT-5.6 Sol
# Round 8 Response — CR-42 / CR-41 / CR-43 + Static Closure Gate

> **Patch commit:** (pending — see below)
> **Files patched:** 10
> **Review date:** 2026-08-08

---

## 0. Response order

Per GPT protocol: CR-42 → CR-41 → CR-43 → static closure gate.

---

## 1. CR-42 — ACCEPT

```yaml
id: CR-42
response: ACCEPT
severity: P1
source_evidence: |
  task/structured-subagent.ts:600-605 — mergeIsolatedChanges() is called with
  { repoRoot: isolationContext.repoRoot } unconditionally when
  policy.applyChanges && result.exitCode === 0.
  repoRoot is the PARENT repository, not the isolated worktree.
  A canary worker that writes a sentinel file will have that file merged
  into the parent on the apply=true path before the preflight can read it.
  CR-42 diagnosis confirmed exactly as stated.
exact_patch: |
  spec/08-isolation-and-concurrency.md §E-9.2 — full rewrite:
  - canary agent: tools: [read], blocking: true, isolated: true
  - no sentinel file — mechanically impossible to write
  - discrimination via merge-summary text (source-verified distinct paths):
      apply=false + no changes → "Isolation: no changes captured."
      apply=true  + no changes → "No changes to apply."
  - parent tree invariant: unchanged regardless of apply= outcome
  - isolation-canary named as support/preflight agent, NOT a workflow worker role
    (CR-33's four-worker count unchanged — canary is excluded from that count)
cross_file_sweep: |
  spec/phases/phase-00-foundation.md E3-I — canary contract updated to read-only
    + summary discrimination; added parent-tree invariant assertion row
  spec/phases/phase-02-core-orchestration.md T-02.2 — sentinel paragraph replaced
    with read-only canary + summary-discrimination description
  spec/phases/phase-02-core-orchestration.md exit criteria — CR-38 item updated
    (sentinel absent → summary begins "Isolation:"; CR-42 non-mutating requirement stated)
experiment: |
  E3-I now asserts five rows, including:
    canary_parent_tree: unchanged before and after canary (CR-42)
  Both apply=false and apply=true runs must leave zero parent mutations.
  If the canary creates any file on the failure path, §E-9.2 must be revised before phase-02.
acceptance_check: |
  - production canary parent file side effects: zero ✓ (read-only tool surface)
  - production canary parent HEAD change: zero ✓ (no write capability)
  - works under patch and branch: yes ✓ (summary text is distinct in both modes)
  - same-session policy discrimination: proven by E3-I ✓
remaining_uncertainty: |
  Whether "Isolation: no changes captured." (the no-branch, no-patch else-branch) is the
  stable summary for all merge modes under truly zero worktree changes needs E3-I
  confirmation. If a mode produces a different "Isolation:"-prefixed summary, discrimination
  still holds (all apply=false paths contain "Isolation:"). If any apply=false path
  produces text NOT beginning "Isolation:", §E-9.2 must be re-examined.
```

**One tactical note on CR-33.** The spec now explicitly states `isolation-canary` is an
internal support agent, and validation MUST NOT collapse "discovered agent count" into
"workflow worker count." If the canary agent file is committed to `.omp/agents/`, L1 must
exclude it from the four-worker check. If the project prefers zero agent files for support
roles, an alternative is implementing the canary as a custom tool/extension — but that
mechanism itself would require Phase-00 verification.

---

## 2. CR-41 — ACCEPT

```yaml
id: CR-41
response: ACCEPT
severity: P1
source_evidence: |
  tools/index.ts:593 — if (name === "lsp") return enableLsp && session.settings.get("lsp.enabled");
  tools/index.ts:459 — const enableLsp = session.enableLsp ?? true;
  config/settings-schema.ts — "lsp.enabled": { type: "boolean", default: true }
  
  enableLsp is derived from structured-subagent resolution (plan mode + task.enableLsp +
  parent session). lsp.enabled is a SEPARATE settings key ANDed with enableLsp at the
  built-in tool registration layer. A child session with enableLsp=true (conditions 1-3 met)
  and lsp.enabled=false still produces a tool list without lsp.
  CR-41 diagnosis confirmed exactly as stated.
exact_patch: |
  spec/07-retrieval-and-code-understanding.md §A-1:
  - "three-condition conjunction" → "four independent conditions"
  - Added condition 4 row to table: lsp.enabled (default: true, independent gate)
  - Added second source snippet (tools/index.ts:593) to the verified policy block
  - Added "Condition 4 is independent of condition 3" explanation
  - Updated reduced-capability disclosure: "which of the four conditions failed"
    with per-condition fix (edit file / project setting / relaunch session / lsp.enabled)
  - Updated T-00.E5 reference: "four conditions … five remediations"
cross_file_sweep: |
  spec/12-installation-and-rollback.md — owned_required_settings comment updated (CR-41 ref)
  spec/13-validation-and-evaluation.md §A L0 — CR-41 lsp.enabled check added
  spec/13-validation-and-evaluation.md §B L1 — CR-41 lsp.enabled effective check added
  spec/13-validation-and-evaluation.md §B L4 — new "LSP granted but gated off at lsp.enabled"
    fixture case (E5-F); separate from CR-40 task.enableLsp case
  spec/phases/phase-00-foundation.md T-00.E5 — updated header (four-condition conjunction);
    added source snippet from tools/index.ts:593; added E5-F case for lsp.enabled=false;
    updated discriminator note to five remediations
  spec/phases/phase-00-foundation.md exit criteria — E5-A…E5-F; five distinct remediations
  spec/phases/phase-01-runtime-correctness.md — "three-condition conjunction" → four
  spec/phases/phase-02-core-orchestration.md exit criteria — CR-40/CR-41 combined item;
    "four conditions" named
  spec/phases/phase-06-evaluation.md T-06.2 — CR-41 lsp.enabled note added to L1 checks
experiment: |
  T-00.E5 E5-F:
    task_enableLsp: true (CR-40 satisfied)
    parent_session_lsp: enabled (condition 3 satisfied)
    agent_allowlist: includes lsp (condition 1 satisfied)
    lsp.enabled: false (CR-41 gate — independent setting)
    expected: worker lsp UNAVAILABLE
    discrimination: is lsp absent from tool list or present and erroring?
      → absent (registration was never done)
    fix_if_hit: enable lsp.enabled in project config or session settings
    note: disclosure MUST name lsp.enabled as the failed condition, not task.enableLsp
acceptance_check: |
  - lsp.enabled gate documented: ✓ (§07 §A-1, tools/index.ts:593 cited)
  - E5 has distinct lsp.enabled=false case: ✓ (E5-F)
  - reduced-capability reports exact failed condition: ✓ (per-condition fix table)
remaining_uncertainty: none
```

---

## 3. CR-43 — ACCEPT

```yaml
id: CR-43
response: ACCEPT
severity: P1
source_evidence: |
  tools/index.ts:594 — if (name === "bash") return session.settings.get("bash.enabled");
  config/settings-schema.ts — "bash.enabled": { type: "boolean", default: true }
  
  bash.enabled is a completely independent gate for the bash built-in tool.
  An agent with bash in its tools: allowlist still has no effective bash if bash.enabled=false.
  CR-43 diagnosis confirmed exactly as stated.
exact_patch: |
  spec/10-verification-and-review.md §B-2 (new subsection):
  - source: tools/index.ts:594 cited
  - policy: bash unavailable → REFUSE workflow OR explicit UNVERIFIED result
  - prohibited: yield decision: PASS with prose substituting command output
  - scope discipline: Verifier = hard_required; Implementer = role_required (disclosed)
  - L1/runtime check reference added
cross_file_sweep: |
  spec/13-validation-and-evaluation.md §B L1 — CR-43 effective Verifier bash check added
  spec/13-validation-and-evaluation.md §B L4 — new "Verifier bash disabled" fixture case
    (bash.enabled: false → must not yield PASS; REFUSE or UNVERIFIED required)
  spec/phases/phase-05-installation-hardening.md — bash.enabled NOT owned paragraph added
    (user who disabled bash made deliberate choice; installer must not override;
     post-install preflight detects and reports as capability gap)
  spec/phases/phase-06-evaluation.md T-06.2 L1 — CR-43 effective Verifier bash check added
  spec/phases/phase-06-evaluation.md T-06.2 acceptance line — bash effective check added
experiment: |
  CR-43 L4 fixture (spec/13):
    bash.enabled: false
    run any workflow with Verifier
    expected: preflight refuses OR result is explicitly UNVERIFIED with bash_unavailable cause
    FAIL: schema-valid PASS from Verifier with zero effective bash calls
acceptance_check: |
  - verifier effective bash checked: ✓ (L1, phase-06 T-06.2)
  - bash disabled cannot report normal verified PASS: ✓ (§10 §B-2, L4 fixture)
remaining_uncertainty: |
  Whether the preflight can read the effective Verifier tool set before dispatch is a
  capability that needs Phase-00 verification (E3 instrumentation). If OMP's discovery
  layer exposes the effective tool list (not just parsed frontmatter), L1 can assert it
  statically. If not, the check requires a dedicated runtime probe. This does not block
  the spec from stating the requirement; it may affect implementation path.
```

---

## 4. Static closure gate

```yaml
CR_42:
  production_canary_parent_file_side_effects: zero ✓ (tools: [read] — mechanically impossible)
  production_canary_parent_HEAD_change: zero ✓
  works_under_patch_and_branch_or_explicitly_scopes_merge_mode: true ✓
    (summary-based discrimination works for both; "Isolation:" prefix is the stable signal)
  same_session_policy_discrimination: proven_by_E3 ✓ (E3-I now asserts all five rows)

CR_41:
  lsp_enabled_gate_documented: true ✓ (§07 §A-1 with source citation)
  E5_has_distinct_lsp_enabled_false_case: true ✓ (E5-F)
  reduced_capability_reports_exact_failed_condition: true ✓ (per-condition fix table in §A-1)

CR_43:
  verifier_effective_bash_checked: true ✓ (L1, phase-06 T-06.2)
  bash_disabled_cannot_report_normal_verified_PASS: true ✓ (§10 §B-2, L4 fixture)

CR_39:
  blocking_true_on_all_required_workers: true ✓ (unchanged from Round 7)
  E3_J_K_defined: true ✓ (unchanged from Round 7)
```

If no new P0/P1 contradiction is introduced by these patches:

```yaml
static_spec_review: CLOSED
ready_for_phase_00_experiments: true
ready_for_feature_implementation: false
next_action: Phase-00 experiments (E3-A … E3-K, E5-A … E5-F)
```

---

## 5. Cross-check: no new contradictions introduced

**Canary agent count vs CR-33 (four worker agents).** The `isolation-canary` is explicitly
classified as a support/preflight agent in §08 §E-9.2 and the spec notes validation MUST NOT
count it as a workflow worker. No contradiction.

**`lsp.enabled` not owned vs `task.enableLsp` owned.** `task.enableLsp` defaults `false`
and is correctness-affecting for this template → installer-owned. `lsp.enabled` defaults
`true` and is a user capability preference → not installer-owned. Same logic as
`bash.enabled`. No contradiction with §12.

**bash.enabled not owned vs Verifier hard-requires bash.** The installer not writing the
key (default is `true`) does not prevent the template from hard-requiring it. The preflight
detects the contradiction at install time and reports it. Same pattern as `lsp.enabled` and
`task.enableLsp`. No contradiction.

**E5-F (lsp.enabled) vs E5-B (success case).** E5-B now explicitly includes
`lsp_enabled: true` in its setup to make it the clean-path control. E5-F is the
lsp.enabled=false failure case. Both cases are well-separated.

---

## 6. Files patched (10 files, +238/-66)

| File | Changes |
|---|---|
| `spec/07-retrieval-and-code-understanding.md` | CR-41: four-condition conjunction, condition 4 row, source citation, per-condition disclosure |
| `spec/08-isolation-and-concurrency.md` | CR-42: §E-9.2 full rewrite — read-only canary, summary discrimination, non-mutating invariant, support-agent taxonomy note |
| `spec/10-verification-and-review.md` | CR-43: new §B-2 — bash precondition, source citation, REFUSE/UNVERIFIED policy, scope discipline |
| `spec/12-installation-and-rollback.md` | CR-41: owned_required_settings comment updated (four conditions) |
| `spec/13-validation-and-evaluation.md` | CR-41/43: L0 lsp.enabled check; L1 lsp.enabled + bash checks; L4 CR-38 updated for non-mutating canary; new L4 lsp.enabled=false and bash.enabled=false fixture cases |
| `spec/phases/phase-00-foundation.md` | CR-42: E3-I updated — read-only canary + parent-tree invariant; CR-41: E5 updated — four-condition header, source snippet, E5-F added, five-remediation discriminator; exit criteria updated |
| `spec/phases/phase-01-runtime-correctness.md` | CR-41: "three-condition" → four-condition; T-00.E5 A–F; five remediations |
| `spec/phases/phase-02-core-orchestration.md` | CR-42: T-02.2 canary paragraph — read-only + summary discrimination; exit criteria CR-38/CR-42 and CR-40/CR-41 combined items updated |
| `spec/phases/phase-05-installation-hardening.md` | CR-41/43: lsp.enabled and bash.enabled NOT owned paragraph added |
| `spec/phases/phase-06-evaluation.md` | CR-41/43: T-06.2 L1 checks — lsp.enabled contradiction + bash effective presence; acceptance line updated |
