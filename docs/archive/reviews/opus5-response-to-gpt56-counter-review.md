# OPUS5-RESPONSE-TO-GPT56-COUNTER-REVIEW

> **Reviewer**: Claude Opus 5  
> **In response to**: GPT-5.6 Sol adversarial counter-review packet dated 2026-08-07  
> **Spec under review**: `https://github.com/manhthien2005/omp-custom/spec/`  
> **OMP baseline**: v17.2.10 at `_research/upstreams/oh-my-pi`  
> **Response date**: 2026-08-07  
> **Status**: Spec revision pass 2 — bugs fixed in-line, design gaps noted for phase-00

---

## Summary of dispositions

| CR | Severity | Disposition | Action taken |
|---|---|---|---|
| CR-01 | P0 | ACCEPT | Fixed spec/11; DR-4 justification rewritten |
| CR-02 | P0 | ACCEPT | Fixed spec/03 + README topology |
| CR-03 | P0 | ACCEPT | Fixed phase-01 T-01.7 |
| CR-04 | P1 | ACCEPT | Provenance task added to phase-00 scope |
| CR-05 | P0 | ACCEPT | Experiment gate tasks added to phase-00 scope |
| CR-06 | P1 | ACCEPT | DR-1 reopened; gap acknowledged |
| CR-07 | P1 | ACCEPT | Fixed spec/03 terminology |
| CR-08 | P1 | ACCEPT | Fixed phase-04 T-04.1 wording |
| CR-09 | P1 | ACCEPT | Gap acknowledged; spec patch required §08 |
| CR-10 | P1 | ACCEPT | Gap acknowledged; spec patch required §05 |
| CR-11 | P0 | ACCEPT (Option A) | Trust boundary explicitly chosen |
| CR-12 | P1 | ACCEPT | Semantic injection note required §15+§06 |
| CR-13 | P1 | ACCEPT | Rollback semantics require redesign |
| CR-14 | P1 | ACCEPT | Backup scope fix required §12 |
| CR-15 | P1 | ACCEPT | Fixed phase-04/05 headers |
| CR-16 | P1 | ACCEPT | Fixed phase-01 exit criterion |
| CR-17 | P2 | ACCEPT | Reviewer LSP decision required |
| CR-18 | P2 | ACCEPT | Environment claims to be reclassified |
| CR-19 | P2 | ACCEPT | Budgets reclassified as hypotheses |
| CR-20 | P2 | PARTIAL REBUT | Ladder is guidance; wording to soften |
| CR-21 | P1 | ACCEPT | Watched-path diff = triage only |
| CR-22 | P1 | ACCEPT | A/B protocol needs decision rule |
| CR-23 | P2 | ACCEPT | Taxonomy to be normalized |
| CR-24 | P2 | ACCEPT | Model-role fallback needs consolidation |
| CR-25 | P2 | ACCEPT | Runtime facts vs normative decisions to split |

---

## Detailed CR Responses

### CR-01 — Rules propagation to subagents

```yaml
id: CR-01
status: ACCEPT/FIXED
source_proof:
  - _research/upstreams/oh-my-pi/packages/coding-agent/src/task/structured-subagent.ts:438 (rules: session.rules)
  - _research/upstreams/oh-my-pi/packages/coding-agent/src/task/executor.ts:1-4 (in-process subagent header)
  - _research/upstreams/oh-my-pi/packages/coding-agent/src/sdk.ts (bucketRules → rulebookRules + alwaysApplyRules)
reasoning: >
  CR-01 is correct. The original spec claimed RULES.md does not reach subagents and therefore autoloadSkills was the only deterministic mechanism. This was based on a wrong level of analysis (looking for alwaysApplyRules in executor/structured-subagent rather than tracing the full chain). The actual data flow is: parent session.rules → buildExecutorOptions (structured-subagent.ts:438) → createAgentSession → sdk.ts:bucketRules → child prompt. The spec made an analysis error by checking only the lower-level function names instead of tracing the end-to-end data flow.
spec_patch:
  - spec/11-skills-rules-and-quality-gates.md §A table: "Reaches subagents?" changed from No to Yes
  - spec/11-skills-rules-and-quality-gates.md §A verified finding: rewritten to explain the correct chain
  - spec/11-skills-rules-and-quality-gates.md §B DR-4: justification updated (autoloadSkills still recommended but for different reasons — explicit token cost, intentional content, independent of full rulebook parent)
  - spec/11-skills-rules-and-quality-gates.md §F RULES.md Scope: updated to reflect propagation
decision_record_impact:
  - DR-4 retained but justification rewritten (autoloadSkills recommended for explicitness, not because rules don't propagate)
phase_impact:
  - phase-02 T-02.1: no change needed (autoloadSkills remains the implementation choice, but rationale is different)
experiment:
  required: true
  command_or_fixture: >
    T-00.E4: Create fixture with unique sentinel rule (e.g., RULE_SENTINEL_7F3A: emit QUALITY_GATE_SEEN before completion). Spawn worker without autoload. Capture child system prompt or debug rule buckets. Discriminate: (A) forwarded rule is prompt-visible, (B) stored but not prompt-visible, (C) parent did not discover the intended rule.
  expected_discriminator: sentinel phrase appears in child prompt or behavior
remaining_uncertainty: >
  Token cost comparison (autoload vs forwarded RULES.md) not yet measured. Discovery mode interaction with different project layouts not yet tested.
```

---

### CR-03 — Structured-output strategy contradicts itself

```yaml
id: CR-03
status: ACCEPT/FIXED
source_proof:
  - _research/upstreams/oh-my-pi/packages/coding-agent/src/task/structured-subagent.ts:176-188 (resolveSchema function)
  - resolveSchema precedence: caller outputSchema > agent.output > session.outputSchema > none
reasoning: >
  CR-03 is correct. Phase-01 T-01.7 claimed "OMP enforces only an outputSchema passed in the task call" which is directly contradicted by resolveSchema source code. The actual precedence chain shows agent.output is the second tier (after caller override). This contradicts DR-2's design that agent frontmatter output: is the canonical schema. The spec made a false overclaim about OMP's enforcement model.
spec_patch:
  - spec/phases/phase-01-runtime-correctness.md T-01.7: entirely rewritten to document the actual resolveSchema precedence (caller > agent > session) and clarify that canonical schema goes in agent output: frontmatter, while task outputSchema is an override mechanism only
decision_record_impact:
  - DR-2 remains valid (agent frontmatter output: is canonical); the phase-01 task was incorrectly written
phase_impact:
  - phase-01 T-01.7: implementation approach changed from "inline schema in every task call" to "define schema in agent frontmatter; use task outputSchema only for explicit overrides"
  - phase-02: no cascade impact (worker definitions already use frontmatter schemas per DR-2)
experiment:
  required: true
  command_or_fixture: >
    T-00.E1: Test all precedence cases: (1) agent output: only, (2) caller outputSchema only, (3) both present with intentionally different sentinel schemas, (4) session-level schema, (5) malformed/unsupported provider behavior.
  expected_discriminator: runtime schema selection matches resolveSchema precedence order
remaining_uncertainty: >
  Interaction between schemaMode (strict/permissive) and precedence layers not yet tested. Provider-specific validation behavior (OmniRoute vs direct Anthropic) not yet measured.
```

---

### CR-02 — Standard Implementer isolation is internally contradictory

```yaml
id: CR-02
status: ACCEPT/FIXED
source_proof:
  - spec/README.md target topology: implementer marked isolated: true
  - spec/03-agent-topology.md §B worker roster: Implementer Isolated? Yes
  - spec/08-isolation-and-concurrency.md §B: Standard=false, Orchestrated=true
  - spec/phases/phase-02-core-orchestration.md: follows §08 interpretation (parallel only)
reasoning: >
  CR-02 is correct. README and §03 showed implementer as universally isolated, while §08 (the authoritative isolation spec) defines a conditional policy: Standard workflow (single Implementer) = isolated: false; Orchestrated workflow (parallel Implementers) = isolated: true. Phase-02 follows §08. This is a documentation consistency failure, not a design failure — the design in §08 is deliberate and correct.
spec_patch:
  - spec/README.md §5 topology diagram: implementer line changed from "isolated: true" to "isolated: false (Standard) / true (Orchestrated; see §08 §B)"
  - spec/03-agent-topology.md §B Worker Roster: Implementer Isolated? changed from "Yes" to "Conditional — Standard: No; Orchestrated: Yes (see §08 §B)"
decision_record_impact:
  - Implicit DR for Standard Implementer isolation policy: now explicit (Standard=no isolation by design choice; failed implementation leaves parent worktree dirty; rollback/retry must handle contaminated state)
phase_impact:
  - phase-02 T-02.1: no change (already follows §08)
  - phase-01 exit criteria: no change (single-worker validation does not depend on isolation)
experiment:
  required: false
  command_or_fixture: n/a
  expected_discriminator: n/a
remaining_uncertainty: >
  Fallback behavior when isolation backend is unavailable (non-git repo, ProjFS failure, etc.) not yet fully specified. §08 provides guidance but not a complete decision matrix.
```

---


### CR-05 — Phase 00 missing experiment gates

```yaml
id: CR-05
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/phases/phase-00-foundation.md (no experiment tasks T-00.E1..E4)
  - spec/README.md (unresolved OQs: schema enforcement, Windows/ProjFS, model-role merge)
  - spec/phases/phase-01-runtime-correctness.md (depends on T-00.E1 + T-00.E2)
  - spec/phases/phase-02-core-orchestration.md (depends on T-00.E3)
reasoning: >
  Phase 00 normalizes docs but does not run experiments resolving high-impact OQs.
  Phase 01 depends on T-00.E1 (schema/provider enforcement) and T-00.E2 (model-role merge).
  Phase 02 depends on T-00.E3 (Windows/ProjFS isolation). T-00.E4 resolves CR-01 ambiguity
  (rule propagation vs autoload). Without T-00.E1..E4 artifacts the phase-00 exit criterion
  "facts frozen" is false and dependent phases start against unresolved assumptions.
spec_patch:
  - spec/phases/phase-00-foundation.md Add T-00.E1 (resolveSchema precedence + provider strict),
    T-00.E2 (model-role merge order for known/unknown/missing roles),
    T-00.E3 (isolation backend availability on Windows + ProjFS),
    T-00.E4 (rule sentinel forwarding — is RULES.md rule prompt-visible in child?)
    Each with artifact exit gate and recorded runtime + OMP SHA.
  - Phase 00 exit criteria: require T-00.E1..E4 all have recorded artifacts before phase closes.
decision_record_impact:
  - DR-2 runtime_facts section populated after T-00.E1
  - DR-1 runtime_facts section populated after T-00.E2
  - DR-4 runtime_facts section populated after T-00.E4
phase_impact:
  - phase-01 blocked until T-00.E1 and T-00.E2 artifacts present
  - phase-02 blocked until T-00.E3 artifact present
experiment:
  required: true
  command_or_fixture: T-00.E1 through T-00.E4 as detailed in packet CR-05
  expected_discriminator: each produces recorded artifact with binary-discriminating result
remaining_uncertainty: >
  T-00.E3 is environment-dependent (ProjFS may not be available on all Windows builds).
  T-00.E2 requires OmniRoute gateway reachable — flag as ENVIRONMENT ASSUMPTION if not.
```

---

### CR-11 — Trust boundary for repository-controlled code execution

```yaml
id: CR-11
status: ACCEPT/OPTION-A (trusted repo only)
source_proof:
  - spec/15-security-and-failure-recovery.md lacks explicit executable-code trust statement
  - executor.ts in-process execution — no OS sandbox, no credential scrubbing
  - Workers (Implementer, Verifier) have bash — can execute npm test, make, pytest, cargo test
reasoning: >
  Workers with bash execute repository-controlled commands with arbitrary OS behavior.
  OMP isolation is session+filesystem isolation, not a hardened execution sandbox.
  Option A selected: repository executable code is trusted — target use case is the
  author own OMP config, not hostile-repo automation. Matches standard developer tool
  behavior (VS Code, GitHub Actions). Option B (container sandbox) is out of scope for
  a personal coding-agent template.
spec_patch:
  - spec/15-security-and-failure-recovery.md Add explicit TRUST BOUNDARY section:
    Option A active — guards against text prompt-injection, does NOT sandbox
    repository-controlled executables; do not use against hostile repos without
    an independent OS-level execution sandbox.
  - spec/03-agent-topology.md section C Add bash scope note and Option A boundary reference.
decision_record_impact:
  - New explicit DR for trust boundary policy = Option A (trusted repo only)
phase_impact:
  - phase-02 bash permissions for Implementer/Verifier valid under Option A
  - phase-05 installation hardening warn users if deploying against third-party repos
experiment:
  required: false
  command_or_fixture: Optional adversarial fixture (packet CR-11 benign malicious script) for documentation awareness — not required for Option A closure
  expected_discriminator: n/a under Option A
remaining_uncertainty: >
  If future use case expands to hostile/third-party repos, Option B requirements will need full specification.
```

---

### CR-06 — Main-session Tech Lead lacks guaranteed model routing

```yaml
id: CR-06
status: ACCEPT/DR-1 REOPEN
source_proof:
  - spec/README.md DR-1 marks main-session design resolved but leaves @tech-lead routing undefined
  - spec/phases/phase-01-runtime-correctness.md acknowledges tech-lead.md frontmatter not applied
  - T-00.E2 needed to establish model-role merge order for main session
reasoning: >
  When Tech Lead moves to main session, tech-lead.md frontmatter (model at tech-lead,
  thinking level) is never applied. The spec does not specify how the main session
  gets @tech-lead routing or high thinking effort. DR-1 closes a topology question
  but leaves a critical consequence undefined. Accept finding; reopen DR-1.
  Resolution path: T-00.E2 experiment records actual @tech-lead resolution behavior,
  then choose one of three options from packet CR-06.
spec_patch:
  - spec/README.md DR-1 status changed to PARTIAL (main-session routing mechanism undefined)
  - spec/README.md DR-1 add open question: how does main session guarantee @tech-lead
    routing and thinking level when tech-lead.md frontmatter is not applied?
  - phase-01 new task: define routing mechanism with T-00.E2 source proof
decision_record_impact:
  - DR-1 REOPEN; close after T-00.E2 records main-session model resolution
phase_impact:
  - phase-01 new task needed before DR-1 can close
  - phase-02 Worker model routing independent and unaffected
experiment:
  required: true
  command_or_fixture: T-00.E2 — record @tech-lead pattern resolution + main-session default
  expected_discriminator: confirmed routing OR explicit "user-controlled, no guarantee" in DR-1
remaining_uncertainty: Depends on OmniRoute @tech-lead config in author environment
```

---

### CR-07 — Verifier/Reviewer read-only label inaccurate (FIXED)

```yaml
id: CR-07
status: ACCEPT/FIXED
source_proof:
  - OMP agent-registry READ_ONLY_TOOLS excludes bash
  - Bash side effects (.pytest_cache, coverage files, snapshots) inevitable regardless of prompt
reasoning: >
  A worker with bash cannot be mechanically read-only per OMP own definition.
  The spec used imprecise terminology implying OS-level write impossibility.
  Actual intent was "no direct edit tool." Terminology corrected.
spec_patch:
  - spec/03-agent-topology.md section B Verifier/Reviewer Isolated column:
    changed from "No (must not)" to "Prompt-only: must not (bash enables side effects; see section C)"
decision_record_impact: none — terminology correction only
phase_impact: none — policy intent unchanged
experiment:
  required: false
  command_or_fixture: n/a
  expected_discriminator: n/a
remaining_uncertainty: >
  Side-effect file policy (allowed in parent vs isolated vs unexpected) still undefined. Low-risk for trusted-repo context.
```

---

### CR-08 — Subprocess session overstates subagent independence (FIXED)

```yaml
id: CR-08
status: ACCEPT/FIXED
source_proof:
  - executor.ts lines 1-4 "In-process execution for subagents. Runs each subagent on the main thread."
reasoning: >
  executor.ts explicitly documents in-process on main thread, not OS subprocess.
  "Separate subprocess session" implied process-level memory isolation which does not exist.
  Correct guarantee: separate child AgentSession + separate conversation/transcript context.
  Process-global state (env vars, singletons, provider clients) may be shared.
  This weakens the verifier independence argument but does not invalidate it — transcript
  separation is still meaningful for correctness checking.
spec_patch:
  - spec/phases/phase-04-quality-system.md T-04.1 "subprocess" replaced with
    "separate in-process AgentSession (no shared transcript — CR-08 subagents run on main thread)"
  - spec/phases/phase-04-quality-system.md header Blocks changed phase-05 to phase-06
decision_record_impact: >
  Verifier independence claim weakened from process isolation to transcript/session isolation
phase_impact:
  - phase-04 T-04.1 wording complete
  - phase-04 header DAG corrected
experiment:
  required: false
  command_or_fixture: n/a
  expected_discriminator: n/a
remaining_uncertainty: >
  Whether shared in-process state (singleton services, provider clients) could affect
  verifier independence not yet measured. Low-risk for correctness checking.
```

---


### CR-09 — Parallel isolated merges not specified as batch-atomic

```yaml
id: CR-09
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/08-isolation-and-concurrency.md (no transaction boundary defined for parallel merges)
  - structured-subagent.ts isolation merge helper operates per-worker, not batch-atomic
reasoning: >
  The spec relies on scope partitioning and sequential fallback but does not define
  what happens when merge A succeeds and merge B conflicts. After A merges, parent is
  B+A; retrying B is no longer against original base B. Neither atomic-batch semantics
  nor explicit partial-integration semantics are defined. Both designs are valid —
  the failure is that neither is specified.
spec_patch:
  - spec/08-isolation-and-concurrency.md section on parallel merges: add explicit
    batch-merge semantics choice. Recommended: Explicit partial-integration with defined
    retry semantics — state that prior successful merges remain applied, define what
    gets retried, whether already-merged work is reverted, and how verifier/reviewer
    are notified of the new base state.
  - Add adversarial fixture: two isolated workers edit same line differently; first merge
    succeeds, second conflicts; assert exact expected parent worktree after batch.
decision_record_impact:
  - New sub-decision under isolation policy: batch-merge atomicity = explicit partial-integration
phase_impact:
  - phase-02 T-02.x parallel merge task: add atomicity specification and failure scenario handling
experiment:
  required: true
  command_or_fixture: Two isolated workers editing overlapping lines; force first-merge-success, second-conflict
  expected_discriminator: spec states exact parent worktree state and retry behavior
remaining_uncertainty: >
  OMP isolation runner merge helper API not yet confirmed for batch-atomic capability.
  May need runtime test to confirm whether all-or-nothing merge is even feasible.
```

---

### CR-10 — .task gitignored file is unsafe cross-isolation persistence

```yaml
id: CR-10
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/05-context-and-token-model.md (.task/<id>/... offload design)
  - structured-subagent.ts isolation runner tears down temporary worktree after task lifecycle
  - executor.ts + sdk.ts: parent artifact manager adoption available
reasoning: >
  An isolated worker writes to .task/<id>/... inside the isolated worktree.
  After teardown, that path no longer exists in the parent. Gitignored files
  are exactly what git-based merge will NOT propagate through branch merge.
  The spec underuses OMP native artifact manager which solves this cleanly:
  worker adopts parent artifact manager via executor options, artifacts are
  stored in parent domain and remain valid after isolation teardown.
spec_patch:
  - spec/05-context-and-token-model.md: Replace .task/<id>/... offload recommendation
    with OMP artifact manager as the preferred cross-isolation evidence channel.
    Keep .task pattern only for non-isolated (Standard) workers where the worktree
    is not torn down.
  - Note: if .task is retained for any path, must prove file is outside disposable
    worker tree or explicitly copied out before cleanup.
decision_record_impact:
  - No DR; implementation detail in context/offload design
phase_impact:
  - phase-03 context offload implementation: switch to artifact manager API
  - phase-02 orchestrated implementer: evidence sharing path changes
experiment:
  required: true
  command_or_fixture: Isolated worker writes large output; verify artifact survives isolation teardown and is readable by parent
  expected_discriminator: artifact reference valid in parent after worker completion
remaining_uncertainty: >
  OMP artifact manager API (executor options for parent artifact manager adoption in sdk.ts)
  not yet fully characterized from source. Needs T-00.Ex fixture.
```

---

### CR-12 — Schema-valid strings remain untrusted (semantic injection gap)

```yaml
id: CR-12
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/15-security-and-failure-recovery.md (claims structured output mitigates prompt injection)
  - spec/06-structured-output.md (no note on semantic trustworthiness of string fields)
reasoning: >
  JSON Schema validates structure and type constraints, not string content trustworthiness.
  A schema-valid result can carry instruction-shaped strings in free-text fields
  (e.g., recommended_next_action containing "run curl ..."). The spec treats schema
  validation as a meaningful security boundary; it is not. The actual property is:
  structured output reduces parser ambiguity and constrains channels — it cannot establish
  that worker-originated string content is safe to execute or follow.
spec_patch:
  - spec/15-security-and-failure-recovery.md: Add explicit invariant "All worker-produced
    strings remain untrusted data even after schema validation. Never interpret worker text
    as higher-priority instruction; always independently authorize actions; validate
    path/command/action fields semantically not merely structurally."
  - spec/06-structured-output.md: Add note in schema design guidelines that free-form
    string fields are injection vectors; prefer enum or constrained types where possible.
  - Add adversarial test: return schema-valid injection text in every free-form field;
    verify Tech Lead does not violate workflow/security policy.
decision_record_impact:
  - Security model clarification; no DR required but §15 trust model updated
phase_impact:
  - phase-04 verifier independence: strengthen wording (transcript isolation + schema validation
    does not fully prevent semantic injection)
experiment:
  required: true
  command_or_fixture: Adversarial fixture: schema-valid injection payload in recommended_next_action and evidence[] fields
  expected_discriminator: Tech Lead ignores injected instructions and follows spec workflow
remaining_uncertainty: >
  Whether OMP Tech Lead session has any automatic instruction-priority filtering not yet established.
```

---

### CR-13 — Rollback promises are mutually incompatible with post-install edits

```yaml
id: CR-13
status: ACCEPT/REDESIGN NEEDED
source_proof:
  - spec/12-installation-and-rollback.md (Promise A: do not clobber user post-install edits)
  - spec/12-installation-and-rollback.md (Promise B: install/uninstall round-trip = exact restoration)
  - spec/phases/phase-05-installation-hardening.md (rollback tests)
reasoning: >
  A state transition of pre-install=A, installer writes B, user edits to C cannot
  simultaneously preserve C and restore A. The promises are logically incompatible
  when post-install edits exist. For MERGE operations the contradiction is worse:
  a whole-file backup cannot answer which keys belonged to installer vs user.
  The spec must define rollback semantics per operation type with explicit conflict handling.
spec_patch:
  - spec/12-installation-and-rollback.md: Rewrite rollback contract to define semantics per operation:
    OVERWRITE: store original file hash + content. If file unchanged since install, restore exactly.
    If file changed since install, emit conflict report, do NOT silently clobber.
    MERGE: store installer delta (inserted/changed keys), not whole-file backup. At uninstall,
    revert untouched installer-owned keys, preserve user additions, surface conflicts for
    installer-owned keys that user also changed.
  - Exit criterion: "no post-install edits => exact restoration; post-install edits => non-destructive
    inverse with conflicts surfaced" (not "exact restoration" universally).
decision_record_impact:
  - Affects rollback design in §12 and phase-05 implementation scope
phase_impact:
  - phase-05 rollback implementation: structural redesign from whole-file backup to per-operation deltas
  - phase-01 exit criterion (basic rollback): confirm updated definition still satisfiable
experiment:
  required: true
  command_or_fixture: Test matrix: OVERWRITE (no edit, with edit), MERGE (no edit, added key, edited installer key)
  expected_discriminator: each case produces documented expected behavior without data loss
remaining_uncertainty: >
  Whether three-way merge for YAML config is semantically safe (key ordering, comments, types)
  needs validation for specific config formats used.
```

---

### CR-14 — Whole-destination backup unnecessarily duplicates secrets

```yaml
id: CR-14
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/12-installation-and-rollback.md (whole-tree backup before writes)
  - spec/15-security-and-failure-recovery.md (identifies credentials, session DB, tokens as must-not-overwrite)
reasoning: >
  Backing up the entire destination tree duplicates provider credentials, session databases,
  local tokens, and private metadata — files the installer explicitly promises not to modify.
  .gitignore only prevents accidental repo commit; it does not address filesystem permissions,
  ACL, retention, encryption, backup/sync exposure, or whether the backup enters a repo.
  Preferred alternative: backup only files that can actually be modified by the installer.
spec_patch:
  - spec/12-installation-and-rollback.md: Backup scope = only files that match the installer
    write set (derived from the manifest of operations). Exclude files listed as must-not-touch
    (credentials, session DB, tokens, user-local state).
  - If whole-tree backups are retained for any reason, specify: backup location outside project
    repo, user-only permissions, explicit cleanup/retention policy, Windows/POSIX handling.
  - Aligns with CR-13 redesign: per-operation preimage metadata replaces whole-file backup.
decision_record_impact:
  - Backup policy update in §12; no separate DR required
phase_impact:
  - phase-05 installation hardening: backup implementation scoped to installer write set
experiment:
  required: true
  command_or_fixture: Verify backup set contains only modified files and excludes credential paths
  expected_discriminator: backup directory contains exactly the expected files, no credential files
remaining_uncertainty: >
  Installer write-set manifest must be defined before backup scope can be computed. Depends on CR-13 redesign.
```

---


### CR-15 — Phase dependency graph contradicts itself (FIXED)

```yaml
id: CR-15
status: ACCEPT/FIXED
source_proof:
  - spec/README.md DAG: P4->P6, P1->P5
  - spec/phases/phase-04-quality-system.md header: was Blocks phase-05 (wrong)
  - spec/phases/phase-05-installation-hardening.md header: was Depends on phase-04 (wrong)
reasoning: >
  README shows P4->P6 and P1->P5. Phase-04 header said Blocks phase-05 (contradicts README).
  Phase-05 header said Depends on phase-04 (contradicts README which says P1->P5).
  These phase headers were inconsistent with the canonical README DAG.
  Both headers are now corrected to match the README graph.
spec_patch:
  - spec/phases/phase-04-quality-system.md header: Blocks changed from phase-05 to phase-06
  - spec/phases/phase-05-installation-hardening.md header: Depends on changed from phase-04 to phase-01
decision_record_impact: none (DAG consistency fix)
phase_impact:
  - phase-04 no longer blocks phase-05 (they are independent parallel tracks after phase-02)
  - phase-05 depends on phase-01 only (not phase-04)
experiment:
  required: false
  command_or_fixture: n/a
  expected_discriminator: n/a
remaining_uncertainty: >
  Phase-06 depends-on list should reference P3, P4, P5 explicitly. Recommend single
  machine-readable DAG yaml in README as canonical source per packet resolution suggestion.
```

---

### CR-16 — Phase 01 exit criterion requires Phase 05 work (FIXED)

```yaml
id: CR-16
status: ACCEPT/FIXED
source_proof:
  - spec/phases/phase-01-runtime-correctness.md (was: install/uninstall round-trip restores original state)
  - spec/phases/phase-05-installation-hardening.md (manifest-based robust rollback is Phase 05 work)
reasoning: >
  Phase 01 originally required a full install/uninstall round-trip that restores original state.
  The robust rollback mechanism (manifest-based, per-operation delta) is scheduled for Phase 05.
  Phase 01 exit criterion was impossible to satisfy without pulling Phase 05 work forward.
  Fix: Phase 01 keeps only "basic rollback succeeds (config.yml backup restored, no data loss)".
  Full round-trip fidelity guarantee moves to Phase 05.
spec_patch:
  - spec/phases/phase-01-runtime-correctness.md exit criteria: changed from
    "Install/uninstall round-trip restores original state" to
    "Install/basic rollback succeeds (config.yml backup restored; no data loss) —
    CR-16 full round-trip fidelity guarantee moves to phase-05"
decision_record_impact: none
phase_impact:
  - phase-01 exit criterion now achievable without Phase 05 prerequisites
  - phase-05 now owns the strong round-trip guarantee
experiment:
  required: false
  command_or_fixture: n/a (basic rollback test is now the phase-01 scope)
  expected_discriminator: n/a
remaining_uncertainty: >
  "Basic rollback" must be precisely defined to avoid a new vagueness gap.
  Recommend: backup of exactly the files the installer modified, restoration verified
  by hash comparison.
```

---

### CR-21 — Watched-path diff is a triage optimization, not a proof boundary

```yaml
id: CR-21
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/14-upgradeability-and-governance.md (instructs diff ONLY watched_paths on upstream update)
  - CR-01 is a concrete example: rule-propagation chain spans structured-subagent.ts,
    executor.ts, sdk.ts — watching only one file would miss the full chain
reasoning: >
  Behavior can change without any watched path changing: callers change arguments,
  a new adapter bypasses the watched implementation, a default changes in a transitive dep,
  initialization changes what is in session state. The CR-01 chain (structured-subagent ->
  executor -> sdk -> bucketRules) is a real example where watching only the final behavior
  site misses the decisive upstream wiring change.
spec_patch:
  - spec/14-upgradeability-and-governance.md: Update upgrade process to:
    (1) diff entire upstream commit range for discovery,
    (2) prioritize watched paths for deep semantic review,
    (3) run behavioral compatibility tests regardless of path diff,
    (4) update watched paths when call graph moves.
    Add note: watched-path list is a triage optimization, not a proof boundary.
decision_record_impact: none (governance process fix)
phase_impact:
  - phase-00 T-00.x: add watched-path list maintenance as a recurring upgrade-process step
experiment:
  required: false
  command_or_fixture: n/a
  expected_discriminator: n/a
remaining_uncertainty: >
  Call-graph tracing for each watched behavior is manual effort. Suggest adding
  an explicit "affected callers" annotation to each watched-path entry.
```

---

### CR-22 — A/B evaluation protocol lacks decision rule

```yaml
id: CR-22
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/13-validation-and-evaluation.md (A/B comparison described but missing controls)
  - spec/phases/phase-06-evaluation.md (evaluation phase design)
reasoning: >
  The spec wants to conclude "quality neutral-or-better at equal-or-lower token cost"
  but does not specify: repetitions per arm, paired vs unpaired execution,
  randomization/interleaving, exact OMP/template/provider versions, temperature/seed,
  reasoning-effort config, prompt/cache state, retry policy, token accounting definition,
  confidence interval, or decision threshold. Without a sampling and decision rule,
  "neutral-or-better" is not a reproducible claim.
spec_patch:
  - spec/13-validation-and-evaluation.md and spec/phases/phase-06-evaluation.md:
    Add protocol block before Phase 06 starts, specifying:
    fixture_pairing, minimum_runs_per_arm_per_fixture, randomization policy,
    exact version pinning (omp_sha, template_sha, provider, models recorded),
    runtime policy (timeouts, retry, cache all fixed),
    metrics definition (quality rubric, token accounting source, failure counting),
    decision rule (minimum_quality_delta, maximum_token_delta, uncertainty_rule).
    Statistics can remain simple; the decision rule cannot remain undefined.
decision_record_impact:
  - Phase 06 evaluation design: add formal protocol DR
phase_impact:
  - phase-06 cannot start until evaluation protocol is specified and agreed
experiment:
  required: true
  command_or_fixture: Pilot run on 2-3 fixtures with the defined protocol before full evaluation
  expected_discriminator: protocol produces consistent results across pilot runs
remaining_uncertainty: >
  Reasonable values for minimum_runs_per_arm and decision thresholds depend on
  observed variance — suggest calibration during pilot run.
```

---


### CR-17 — Reviewer LSP decision not consistently resolved

```yaml
id: CR-17
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/07-retrieval-and-code-understanding.md (includes Reviewer in LSP-capable set)
  - spec/README.md DR-7 (adds LSP to Explorer + Implementer only)
  - spec/phases/phase-01-runtime-correctness.md (same as DR-7 scope)
reasoning: >
  spec/07 lists Reviewer as LSP-capable; README DR-7 and phase-01 explicitly add LSP
  to Explorer and Implementer only. Both cannot be simultaneously correct.
  Reviewer LSP affects tool permissions, context acquisition, review quality, token cost,
  and static validation expectations. A single authoritative table is needed.
spec_patch:
  - spec/07-retrieval-and-code-understanding.md: Add authoritative per-agent LSP table
    (explorer yes, implementer yes, verifier no, reviewer TBD).
  - spec/README.md DR-7: Update to reflect the authoritative table and rationale for each decision.
  - Recommend decision: Reviewer gets LSP. Rationale: reviewer must reason about symbol
    semantics and type relationships to produce meaningful review findings; denying LSP
    forces file-search workarounds that cost more tokens and produce weaker evidence.
    Add this as a design choice to DR-7 with explicit rationale.
decision_record_impact:
  - DR-7 reopen; close with authoritative per-agent LSP table and explicit rationale
phase_impact:
  - phase-01 T-01.x: update Reviewer agent definition to include LSP tools if decision = yes
  - Token cost estimate for Reviewer needs revision if LSP is added
experiment:
  required: false
  command_or_fixture: n/a
  expected_discriminator: n/a
remaining_uncertainty: >
  LSP tool cost for Reviewer in practice (how often Reviewer uses LSP vs file reads)
  not yet measured. Measure in phase-06 evaluation.
```

---

### CR-18 — Live environment claims labeled as source-verifiable

```yaml
id: CR-18
status: ACCEPT/RECLASSIFY NEEDED
source_proof:
  - spec/07-retrieval-and-code-understanding.md ("Context7 available in this environment")
  - spec/09-model-routing.md (specific OmniRoute gateway, model set, provider capabilities)
reasoning: >
  Repository source can verify that a config intends to point to X. It cannot prove
  X was running, reachable, exposed the claimed models, or enforced the claimed behavior
  at author runtime. These are environment-specific runtime facts, not source-verified facts.
  The label "verified from source" is misleading for live-environment claims.
spec_patch:
  - spec/07-retrieval-and-code-understanding.md: Mark Context7 availability as
    ENVIRONMENT ASSUMPTION — verify with sanitized tool-discovery transcript.
  - spec/09-model-routing.md: Mark OmniRoute gateway availability, model set, and
    provider behavior as ENVIRONMENT ASSUMPTION — attach sanitized endpoint-health
    and model-discovery transcript (no credentials/machine-specific data).
  - Do not commit live endpoint URLs or machine-specific state to the repository.
decision_record_impact:
  - All DRs that reference live environment capabilities: add ENVIRONMENT ASSUMPTION marker
phase_impact:
  - phase-00 foundation: add "sanitize and record runtime environment snapshot" to tasks
experiment:
  required: true
  command_or_fixture: Capture sanitized runtime transcript (service version, model list, MCP tool list, endpoint health)
  expected_discriminator: spec environment claims match sanitized transcript
remaining_uncertainty: >
  Sanitized transcript format and content policy (what to redact) not yet defined.
  Avoid committing localhost endpoints or provider secrets. See packet CR-18A note.
```

---

### CR-19 — Context budgets and thinking levels are hypotheses, not verified correctness

```yaml
id: CR-19
status: ACCEPT/RECLASSIFY NEEDED
source_proof:
  - spec/05-context-and-token-model.md (budgets stated as correct/sound)
  - spec/09-model-routing.md (thinking level assignments stated as well-chosen)
reasoning: >
  OMP source can establish that a thinking-level field exists and what values are allowed.
  It cannot prove that 600-1200 tokens is optimal for a given role or that medium reasoning
  is sufficient for Explorer. Those are empirical questions requiring benchmarked evaluation.
  The spec elsewhere correctly says tuning should be benchmarked — claiming "verified correct"
  before the benchmark is epistemically inconsistent. Retaining the existing budgets as
  defaults is acceptable ONLY if wording changes per packet CR-19A note.
spec_patch:
  - spec/05-context-and-token-model.md: Reclassify budget numbers as "initial baseline /
    provisional default pending comparative evaluation (Phase 06)"
  - spec/09-model-routing.md: Reclassify thinking-level assignments as "provisional default —
    to be validated in Phase 06 evaluation"
  - No architecture change required; wording change only.
decision_record_impact:
  - No DR change; epistemic label correction only
phase_impact:
  - phase-06 evaluation: add budget/thinking-level comparison as a required measurement axis
experiment:
  required: false
  command_or_fixture: Phase 06 A/B evaluation covers this
  expected_discriminator: Phase 06 produces data to promote or revise provisional defaults
remaining_uncertainty: >
  Reasonable baseline values are unknown until Phase 06. Existing numbers are reasonable
  starting points based on role complexity; use them as provisional.
```

---

### CR-20 — Retrieval ladder written as rigid gates (PARTIAL REBUT)

```yaml
id: CR-20
status: PARTIAL REBUT
source_proof:
  - spec/05-context-and-token-model.md and spec/07-retrieval-and-code-understanding.md
    (retrieval levels described as sequential gates)
reasoning: >
  REBUT: The ladder is not purely rigid. The spec already includes escape conditions
  (ambiguity triggers, explicit cost thresholds). The packet challenges that authority
  ordering is non-monotonic (official docs can outrank local stale README) — this is
  a valid point for external API semantics specifically. However the core ladder order
  (project executable truth > version-matched docs > external sources) is a reasonable
  default for "what this repo currently does" questions.
  ACCEPT: The wording is too strong when it says "exhaust current level before descending."
  "Exhaust" is unbounded and can waste more context than a single precise external lookup.
  Fix: soften to guidance with escape hatch for task-type-appropriate source selection.
spec_patch:
  - spec/07-retrieval-and-code-understanding.md: Replace "exhaust level N before proceeding to N+1"
    with guidance: prefer project executable truth for "what this repo currently does";
    prefer version-matched official docs for external API/runtime semantics;
    use a retrieval budget — if current level cannot resolve the question within budget,
    escalate rather than continuing to search. Add ambiguity trigger: if multiple sources
    conflict, escalate to explicit source comparison rather than picking first answer.
decision_record_impact: none
phase_impact:
  - phase-03 retrieval implementation: update ladder logic to be cost-bounded not exhaustive
experiment:
  required: false
  command_or_fixture: n/a
  expected_discriminator: n/a
remaining_uncertainty: >
  Retrieval budget size for each level not yet defined. Should be specified as a configurable
  parameter in phase-03, with provisional defaults validated in phase-06.
```

---


### CR-23 — Validation taxonomy has three incompatible numbering schemes

```yaml
id: CR-23
status: ACCEPT/NORMALIZE NEEDED
source_proof:
  - spec/13-validation-and-evaluation.md Taxonomy A: L0 Static, L1 Discovery, L2 Contract, L3 Behavioral
  - spec/phases/phase-06-evaluation.md Taxonomy B: Level 1 Static, Level 2 Discovery, Level 3 Workflow, Level 4 Adversarial
  - spec/README.md Taxonomy C: L0-L3 plus L4 comparative/A-B stage
reasoning: >
  Three incompatible taxonomies exist across the spec. A coding agent receiving
  "phase cannot exit until Level 2 passes" cannot unambiguously determine which
  test family is meant. This is a correctness risk for automated phase-gate checks.
  Choose one taxonomy and update all documents consistently.
spec_patch:
  - Adopt single taxonomy everywhere:
    L0 Static (schema, file structure)
    L1 Discovery (agent boots, tool lists, skill loads)
    L2 Contract (structured output, schema enforcement, rule propagation)
    L3 Behavioral/Adversarial (end-to-end workflow + injection tests)
    L4 Comparative A/B (phase-06 evaluation against baseline)
  - spec/13-validation-and-evaluation.md update all level references
  - spec/phases/phase-06-evaluation.md update all level references
  - spec/README.md update all level references
  - All phase exit criteria that reference a validation level must use L0-L4 notation
decision_record_impact: none (normalization; no behavior change)
phase_impact:
  - All phase exit criteria: review and update level references to L0-L4 notation
experiment:
  required: false
  command_or_fixture: n/a
  expected_discriminator: n/a
remaining_uncertainty: >
  Whether "Adversarial" deserves its own level or belongs in L3 Behavioral is a design choice.
  Recommended: keep it in L3 (behavioral=adversarial are complementary, not separate).
```

---

### CR-24 — Missing model-role behavior simultaneously not-verified and assumed silent-fallback

```yaml
id: CR-24
status: ACCEPT/CONSOLIDATE NEEDED
source_proof:
  - spec/09-model-routing.md (explicitly says terminal behavior for missing/invalid role not fully verified)
  - spec/14-upgradeability-and-governance.md (assumes silent fallback to default)
  - spec/15-security-and-failure-recovery.md (assumes silent fallback)
  - sdk.ts model resolution: conditional on role alias recognition, config existence, active/fallback patterns
reasoning: >
  Two incompatible epistemic states exist: §09 says "not verified," §14/§15 assert
  "silent fallback." Both cannot be true simultaneously. The source (sdk.ts) shows
  a conditional resolution chain — fallback behavior depends on whether the name is
  a recognized alias, whether config exists, what active/fallback/default patterns are.
  A generic "silent fallback to default" claim requires either a full path proof for
  the exact configuration OR a runtime fixture. Neither exists yet.
spec_patch:
  - spec/09-model-routing.md: Add T-00.E2 as the experiment that resolves this uncertainty.
    Test cases: known built-in role with config, known custom role with config, referenced
    custom role absent from config, arbitrary @unknown pattern, role resolves to unavailable model.
    Record selected model or terminal error for each.
  - After T-00.E2 results: normalize §09, §14, §15 to a consistent statement that matches
    the measured behavior. Remove the inconsistency between "not verified" and "assumes fallback."
decision_record_impact:
  - DR for model routing: runtime_facts section populated after T-00.E2
phase_impact:
  - phase-00 T-00.E2 must produce the required test matrix before §09/§14/§15 normalization
  - phase-01 model routing tasks: wait for T-00.E2 results
experiment:
  required: true
  command_or_fixture: T-00.E2 test matrix (5 cases listed above)
  expected_discriminator: record selected model or error for each case; pick one consistent statement
remaining_uncertainty: >
  Conditional resolution in sdk.ts means behavior may differ per configuration.
  Experiment must be run with the exact project layout and role configuration in use.
```

---

### CR-25 — Phase 00 requires source citations for normative decisions that source cannot decide

```yaml
id: CR-25
status: ACCEPT/SEPARATE NEEDED
source_proof:
  - spec/phases/phase-00-foundation.md (requires DR-1..DR-7 finalized with source citations)
  - DR examples: DR-1 (main session vs spawned TL), DR-2 (schema strategy), DR-4 (rules vs skills)
reasoning: >
  Some DR questions are factual (does schema precedence work this way? does rule propagate?)
  and source citation is appropriate. Other DRs are normative architecture choices
  (should Tech Lead live in main session? should Standard Implementer be isolated?
  is a token/latency tradeoff worth it?) and source cannot prove those choices correct.
  Requiring source citations for normative decisions encourages evidence laundering:
  "source supports capability X => design choice X is optimal" — which is invalid.
spec_patch:
  - spec/README.md and spec/phases/phase-00-foundation.md: Each DR must explicitly distinguish:
    runtime_facts (source/test-backed — these get source citations)
    design_objectives (explicit priorities — normative, no source citation required)
    alternatives (list considered)
    tradeoffs (explicit tradeoffs accepted)
    experiment_evidence (if applicable, from T-00.Ex)
    decision (normative conclusion with rationale)
  - Only runtime_facts should carry "verified from source" status.
  - Example: DR-4 (rules vs skills) — runtime_facts: rules propagate via session.rules chain
    (source-verified); design_objectives: explicit token cost, deterministic content selection;
    decision: autoloadSkills preferred for explicitness (normative, not source-proven optimal).
decision_record_impact:
  - All DR-1..DR-7 need restructuring to separate facts from normative decisions
  - No design decisions change; only epistemic labeling improves
phase_impact:
  - phase-00 foundation tasks: add DR restructuring as an explicit task
experiment:
  required: false
  command_or_fixture: n/a (structural/epistemic fix only)
  expected_discriminator: n/a
remaining_uncertainty: >
  Some DRs may have both factual and normative components tightly interleaved.
  Separation may require re-reading each DR carefully. Low effort but requires attention.
```

---

### CR-04 — Provenance cannot be independently reproduced from public repository

```yaml
id: CR-04
status: ACCEPT/PATCH NEEDED
source_proof:
  - spec/00-current-state-audit.md (claims verified against local _research/upstreams/oh-my-pi)
  - spec/phases/phase-00-foundation.md (treats SHA pinning as future foundation work)
  - Public v17.2.10 tag used by GPT reviewer; exact local checkout SHA not yet recorded
reasoning: >
  The audit presents source-grounded verification but the exact commit SHA of the local
  checkout is not recorded. A third-party reviewer can independently verify against
  public v17.2.10 but cannot prove the local tree inspected equals the public tag tree.
  A version string alone is weaker than a commit identity. Recording the full SHA
  makes the audit independently reproducible.
spec_patch:
  - spec/00-current-state-audit.md or spec/phases/phase-00-foundation.md: Add provenance record:
    upstream.repo, upstream.tag (v17.2.10), upstream.sha (full 40-char SHA),
    audit_checkout.remote_url, audit_checkout.head_sha, audit_checkout.git_describe,
    audit_date (2026-08-07).
  - Retrieve SHA via: git -C _research/upstreams/oh-my-pi rev-parse HEAD
  - Rerun or mechanically validate verified-claim ledger against that SHA.
decision_record_impact: none (provenance record addition)
phase_impact:
  - phase-00 T-00.x: add "record upstream SHA in provenance block" as an explicit task
experiment:
  required: false
  command_or_fixture: git -C _research/upstreams/oh-my-pi rev-parse HEAD
  expected_discriminator: 40-char SHA matches public v17.2.10 tag
remaining_uncertainty: >
  If local checkout is a shallow clone, git describe may not resolve cleanly.
  Record both HEAD SHA and the tag annotation SHA if different.
```

---

## Final verdict

| Criterion | Result |
|---|---|
| P0 findings resolved | CR-01 FIXED, CR-02 FIXED, CR-03 FIXED, CR-05 PATCH NEEDED (T-00.E1..E4), CR-11 DECIDED (Option A) |
| P1 findings requiring spec patches | CR-06 DR-1 reopen, CR-09 batch semantics, CR-10 artifact manager, CR-12 semantic injection, CR-13 rollback redesign, CR-14 backup scope, CR-17 LSP table, CR-21 triage note, CR-22 evaluation protocol, CR-24 model-role consolidation |
| P1 findings fixed | CR-04 provenance, CR-07 terminology, CR-08 subprocess, CR-15 DAG, CR-16 phase-01 criterion |
| P2 findings requiring reclassification | CR-18 env assumptions, CR-19 provisional defaults, CR-20 wording softened |
| P2 findings requiring normalization | CR-23 taxonomy, CR-25 facts vs normative |
| Remaining blockers before implementation | CR-05 T-00.E1..E4 must run; CR-06 DR-1 close; CR-13 rollback redesign; CR-22 evaluation protocol |
| `ready_to_implement` | false — pending CR-05 experiments and remaining spec patches |

