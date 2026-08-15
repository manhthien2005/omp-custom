# Codex Phase 00 Execution Changelog for Opus 5

## Review Entry Point

This file is the compact audit index for all Codex-authored Phase 00 execution
changes made while Opus 5 quota is unavailable. It is written for later equal-peer
review. A recorded Codex decision is not joint closure; Opus may challenge any
entry with counter-evidence.

```yaml
log_schema_version: 1
phase: "00"
author: Codex GPT-5.6
peer_reviewer: Opus 5
peer_review_status: PENDING_QUOTA
joint_closure_status: NOT_CLAIMED
base_repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
branch: main
staging_policy: NO_STAGE_OR_COMMIT_WITHOUT_USER_DIRECTION
normative_spec: spec/phases/phase-00-foundation.md
evidence_root: docs/evidence/phase-00
```

## Pre-Execution Context

- The tracked working tree already contained Codex F7/F8 corrections in
  `spec/phases/phase-00-foundation.md` before Phase 00 execution began.
- Those corrections are independently documented in:
  - `codex-response-F7-01-F7-04-changelog-for-opus5.md`
  - `codex-response-F8-01-F8-04-changelog-for-opus5.md`
- Historical Opus/Codex review packets and `.claude/` are pre-existing untracked
  user/project context. They are preserved and are not attributed to this execution.
- At baseline, both `template/.omp/policies/` and `template/.omp/schemas/` exist.
  Therefore Phase 00 tasks have not yet been executed even though the phase spec has
  undergone static reconciliation.

## Change Ledger

### P00-CX-001 — Approve durable evidence architecture

```yaml
timestamp: 2026-08-08T22:02:25+07:00
authorization: User approved recommended in-repository evidence design
scope: DESIGN_ONLY
requirements:
  - Phase 00 objective and experiment artifact requirements
  - User requirement for a complete English Opus-facing changelog
files_created:
  - docs/superpowers/specs/2026-08-08-phase-00-execution-evidence-design.md
files_modified: []
files_removed: []
design_sha256: 8928076C933AD91556D493015D67087712BF75570A76BE900ECEF29269640BCA
behavior_change: NONE
runtime_experiment_run: false
```

**Decision.** Use a versioned `docs/evidence/phase-00/` hierarchy with a compact
manifest, per-case sanitized artifacts, and this root changelog. Extend the existing
repository validator rather than create a second execution or validation framework.

**Why.** A single Markdown transcript is compact but cannot reliably separate raw
observation, provenance, and interpretation. `_research/` is clone/research-oriented
and can be mistaken for disposable input. Durable phase-gate evidence belongs beside
the documentation and remains independently reviewable.

**Verification recorded for this entry.** The design document must pass incomplete-marker,
scope, contradiction, and path-consistency review before planning begins.

## Verification Ledger

No Phase 00 runtime experiment has been run at this point. No exit criterion is marked
PASS by this design-only entry.

### P00-CX-002 — Approve and self-review Wave A implementation plan

```yaml
timestamp: 2026-08-08T22:17:38+07:00
authorization: User approved the written evidence design and directed inline execution
scope: PLAN_AND_BASELINE_ONLY
plan:
  path: docs/superpowers/plans/2026-08-08-phase-00-wave-a-foundation-plan.md
  sha256: BBE37AAE6EE7930304A0582B5C76B4D70EF8DC7964CA9762A89E0D29D41F7B74
worktree_decision:
  repository_kind: normal checkout
  branch: main
  execution: in-place
  rationale: >
    The approved plan explicitly preserves the uncommitted F7/F8 normative diff,
    forbids creating a branch without separate direction, and directs inline execution.
    A new linked worktree would omit that uncommitted authority unless it were first
    staged, committed, or copied, all of which would violate the approved constraints.
baseline_validator:
  command: ./scripts/validate-template.ps1 -Verbose
  result: PASS
  passed: 63
  warnings: 0
  failed: 0
  exit_code: 0
behavior_change: NONE
runtime_experiment_run: false
```

**Plan self-review corrections.** The first draft said the manifest contained 30 IDs.
The enumerated set contains 29: seven foundation tasks, E1/E2, thirteen E3 cases,
E4, and six E5 cases. The plan was corrected to 29 everywhere. T-00.7 was also
corrected to depend on every required E3-A through E3-L case, not only the cases
called out as blocking for parallel implementation.

**Execution scope.** Wave A closes at most T-00.1 and T-00.2. It does not run a
runtime experiment, migrate policies or schemas, enable parallel mode, install into
the live OMP home, or claim Phase 00 closure.

### P00-CX-003 — Wave A RED contract checkpoint

```yaml
timestamp: 2026-08-08T22:21:03+07:00
scope: TEST_FIRST
files_created:
  - path: scripts/tests/phase00-wave-a.Tests.ps1
    sha256: C81CB9FB1ACFFA9F9E2000664F9485DDC2AC56AB2A5A0A164E1E24E5EA80F6E1
files_modified:
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-a-foundation-plan.md
    before_sha256: BBE37AAE6EE7930304A0582B5C76B4D70EF8DC7964CA9762A89E0D29D41F7B74
    after_sha256: 1957CD0F86E6C1E5975FAC44E580C1E25978DBD76168359BFD6596AA849A6C53
prechange_hashes:
  registry/upstreams.yml: 6E9F27282FE043771248704CF232FB21563FE6D43C43D84D34AC268DE4DBE67D
  scripts/validate-template.ps1: 081B1420D4AE85B886C8AE3454E0B88AAF76CEB74953CB304105FD71948E9F92
  spec/phases/phase-00-foundation.md: 212F5C6C055AF3BDF3CA21BEABB1F5CDFC6BAB25DCC74F6955BC4262E673E830
verification:
  command: Invoke-Pester -Script scripts/tests/phase00-wave-a.Tests.ps1 -PassThru
  total: 16
  passed: 0
  failed: 16
  skipped: 0
  expected_red: true
  failure_reason: Focused helper, canonical manifest, and compatibility ledger do not yet exist.
runtime_experiment_run: false
```

**Mutation coverage designed before implementation.** The suite contains positive and
negative controls for the 29-ID manifest, unknown states/IDs/dependencies, dependency
state, guarded E3-M deferral, PASS artifact existence, pin mismatch, discovery-claim
completeness, and watched-path claim coverage. Temporary fixture cleanup is restricted
to a resolved child of the operating-system temp directory.

### P00-CX-004 — Persist Wave A baseline and manifest

```yaml
timestamp: 2026-08-08T22:22:57+07:00
scope: EVIDENCE_FOUNDATION
files_created:
  - path: docs/evidence/phase-00/environment/repository-status-before.txt
    sha256: 2B32CF8332EE7FF2CA0B94C0B9B1F7842D7B7A63A42B00D95D9BFECE83729355
  - path: docs/evidence/phase-00/environment/baseline.yml
    sha256: 2B4177A60C2BDEA13A467A6FC593B7FDA5FA2624B4B8892004AFC7E72F16F0D3
  - path: docs/evidence/phase-00/manifest.yml
    sha256: 8A2CFD599983A3282CA1007A897E9FFF178B4A52DE544D2EC217738221F1934F
files_modified:
  - path: scripts/tests/phase00-wave-a.Tests.ps1
    before_sha256: C81CB9FB1ACFFA9F9E2000664F9485DDC2AC56AB2A5A0A164E1E24E5EA80F6E1
    after_sha256: 8FC77EFA8082088FB828F5F4A4490C40BAB1F3B7FBE04E6664892A281729DE20
    reason: Match the valid quoted YAML scalar used by the canonical E3-M decision.
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-a-foundation-plan.md
    before_sha256: 1957CD0F86E6C1E5975FAC44E580C1E25978DBD76168359BFD6596AA849A6C53
    after_sha256: 5C96F10B1BDB73B3FF38BD1E2319B7B762090623FD346C52FC91873E6E9D691D
manifest:
  entry_count: 29
  unique_entry_count: 29
  parallel_mode: DISABLED
  e3_m_state: DEFERRED_PARALLEL_DISABLED
  runtime_pass_entries: 0
sanity_verification:
  constrained_id_count: PASS
  uniqueness: PASS
  yaml_parse_secondary_check: PASS
  canonical_parser_dependency: NONE
runtime_experiment_run: false
```

**Interpretation.** READY means that the row has no unmet declared dependency; it does
not mean the work ran. `PASS` remains absent from all experiment rows. The PyYAML parse
was a secondary authoring sanity check only; the repository validator will not depend on
Python or PyYAML.

### P00-CX-005 — Execute T-00.1 and T-00.2

```yaml
timestamp: 2026-08-08T22:25:35+07:00
scope: FOUNDATION_TASKS_T_00_1_AND_T_00_2
files_modified:
  - path: registry/upstreams.yml
    before_sha256: 6E9F27282FE043771248704CF232FB21563FE6D43C43D84D34AC268DE4DBE67D
    after_sha256: 258671A0AA224A26170054D725CDACBB986E8315FDEF68A1DE9E4C49A3AC220C
    anchors: lines 7-55, oh-my-pi entry only
  - path: docs/evidence/phase-00/manifest.yml
    before_sha256: 8A2CFD599983A3282CA1007A897E9FFF178B4A52DE544D2EC217738221F1934F
    after_sha256: AB990DF2D00F278C37AD17FA067EFDC0FD79CD4817A4942E3813E32F879F6D2B
    state_transitions:
      - T-00.1: READY -> PASS
      - T-00.2: NOT_STARTED -> READY -> PASS
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-a-foundation-plan.md
    before_sha256: 5C96F10B1BDB73B3FF38BD1E2319B7B762090623FD346C52FC91873E6E9D691D
    after_sha256: 54EDFEEEF4020D259BBA4DB54C815BED21F7EDA619C9FFD69B4D5AA4AC4798C6
files_created:
  - path: registry/omp-compatibility.yml
    sha256: AD63E887F655760E844CCB5C2552396DE2150EB7F82DE6B2B410EEF43D1CDC54
source_verification:
  pinned_clone_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  pinned_clone_dirty_entries: 0
  watched_paths: 13
  watched_paths_missing: 0
  verified_claims: 26
  unique_claims: 26
  required_discovery_claims: 15
  required_discovery_claims_present: 15
  watched_paths_without_claim: 0
manifest_after:
  pass_rows: [T-00.1, T-00.2]
  experiment_pass_rows: []
  parallel_mode: DISABLED
runtime_experiment_run: false
```

**Registry correction.** The OMP entry now uses the phase contract's
`runtime-authority` tier, clone date, exact source watched paths, manual-review-only
update policy, and evaluation-suite field. No other upstream entry changed.

**Claim ledger boundary.** `SOURCE_VERIFIED` proves source facts at the pinned SHA; it
does not replace E1-E5 runtime evidence. In particular, the two negative discovery
claims record the absence of registered `policies/` and `schemas/` consumers, while
their later re-homing remains Wave C work.

### P00-CX-006 — Implement and harden the Wave A validator helper

```yaml
timestamp: 2026-08-08T22:30:39+07:00
scope: VALIDATOR_TDD
files_created:
  - path: scripts/lib/phase00-evidence.ps1
    sha256: 813DAF3A34A82A9A45DE4830D121BD8F29CE32E8DD79E6A7A0501210EEC0CF59
files_modified:
  - path: scripts/tests/phase00-wave-a.Tests.ps1
    before_sha256: 8FC77EFA8082088FB828F5F4A4490C40BAB1F3B7FBE04E6664892A281729DE20
    after_sha256: 648519B14351C888AAC4FAE27265252F431542FE93E0EE486436E1AC42BAEB45
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-a-foundation-plan.md
    before_sha256: 54EDFEEEF4020D259BBA4DB54C815BED21F7EDA619C9FFD69B4D5AA4AC4798C6
    after_sha256: DFD041D44BCCAB5906295A614610EB4E8743A5B8DFB056CD807EAD60FAB71A1D
tdd:
  initial_red: {total: 16, passed: 0, failed: 16}
  first_green_attempt: {total: 16, passed: 6, failed: 10}
  first_green_attempt_classification: TEST_ASSERTION_API_ERROR
  root_cause: >
    Pester 3.4 Should Contain treats the left operand as a file path. Array membership
    must be expressed as boolean -contains followed by Should Be true.
  second_red: {total: 20, passed: 16, failed: 4}
  second_red_requirements:
    - exact manifest root identity
    - correct foundation/experiment row kind
    - exact compatibility metadata
    - SOURCE_VERIFIED evidence discriminator
  final_green_pwsh_7_6_4: {total: 20, passed: 20, failed: 0, skipped: 0}
  final_green_windows_powershell_5_1: {total: 20, passed: 20, failed: 0, skipped: 0}
helper_boundaries:
  general_yaml_parser: false
  accepted_input: constrained Phase 00 manifest and compatibility grammar only
  external_parser_dependency: none
  repository_escape_check_for_pass_artifacts: enabled
runtime_experiment_run: false
```

**Why the failed GREEN attempt is retained.** It is material debugging evidence. The
production validator already emitted the expected failure codes; the Pester assertion
adapter incorrectly opened those codes as filenames. The test-only correction changed
no production rule. The subsequent second RED/GREEN cycle added four independently
falsifiable requirements before their production checks were written.

### P00-CX-007 — Integrate Phase 00 contracts into the repository validator

```yaml
timestamp: 2026-08-08T22:32:44+07:00
scope: VALIDATOR_ENTRYPOINT_INTEGRATION
files_modified:
  - path: scripts/validate-template.ps1
    before_sha256: 081B1420D4AE85B886C8AE3454E0B88AAF76CEB74953CB304105FD71948E9F92
    after_sha256: E31DCAC593E6759A513EBABC744482227B0D206B64E5657DE1253A519E1D1FCA
    anchors:
      - required-files list
      - Section 4 heading correction from parseable to non-empty
      - new Section 5 Phase 00 Contracts
  - path: scripts/tests/phase00-wave-a.Tests.ps1
    before_sha256: 648519B14351C888AAC4FAE27265252F431542FE93E0EE486436E1AC42BAEB45
    after_sha256: 1054F22AF880EF6FF8AED6540F413CB3D914715334C1BC05EDA415A048DB384A
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-a-foundation-plan.md
    before_sha256: DFD041D44BCCAB5906295A614610EB4E8743A5B8DFB056CD807EAD60FAB71A1D
    after_sha256: 73B1EC955B5A03D517F03EB8A6719A5992A0CDB2C1DE850C4C6662F944A62E92
tdd:
  integration_red: {total: 21, passed: 20, failed: 1}
  red_reason: Existing validator output contained no Phase 00 stable result codes.
  integration_green: {total: 21, passed: 21, failed: 0}
full_validator:
  command: ./scripts/validate-template.ps1 -Verbose
  passed: 89
  warnings: 0
  failed: 0
  exit_code: 0
fail_closed_behavior:
  helper_missing: P00-HELPER-MISSING
  helper_load_error: P00-HELPER-LOAD
  helper_throw: P00-VALIDATOR-ERROR
  unknown_result_status: P00-RESULT-STATUS
negative_control:
  invalid_manifest_state: P00-MANIFEST-STATE
runtime_experiment_run: false
```

**Single-entrypoint result.** `scripts/validate-template.ps1` remains the repository
validator. The helper is a focused library loaded fail-closed; it is not a second CLI or
execution engine. Existing policy/schema required-file checks remain intact until Wave C.

### P00-CX-008 — Focused post-implementation parser audit

```yaml
timestamp: 2026-08-08T22:37:00+07:00
scope: FOCUSED_REVIEW_HARDENING
reviewer: Codex self-review
independent_peer_review: PENDING_OPUS_QUOTA
constraint: Subagent dispatch unavailable under current session instructions.
files_modified:
  - path: scripts/lib/phase00-evidence.ps1
    before_sha256: 813DAF3A34A82A9A45DE4830D121BD8F29CE32E8DD79E6A7A0501210EEC0CF59
    after_sha256: B0198FEA554D9E977B50C448EA3E5DC55F64216242CBF2ED422D9C31AF279AB3
  - path: scripts/tests/phase00-wave-a.Tests.ps1
    before_sha256: 1054F22AF880EF6FF8AED6540F413CB3D914715334C1BC05EDA415A048DB384A
    after_sha256: 257DE17097DD4769DC88427455D8E090037B63C6DCBD3D3ED52F93038C1CD080
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-a-foundation-plan.md
    before_sha256: 73B1EC955B5A03D517F03EB8A6719A5992A0CDB2C1DE850C4C6662F944A62E92
    after_sha256: 242823FD0444D3D3E511437C0F7AC41B02743F025939169204B8249DEF86C43E
findings:
  - id: P00-AUDIT-001
    severity: IMPORTANT
    issue: Manifest rows could parse when the required entries container marker was absent.
    resolution: Track and require one entries declaration.
    red: {total: 23, passed: 21, failed: 2}
    green: {total: 23, passed: 23, failed: 0}
  - id: P00-AUDIT-002
    severity: IMPORTANT
    issue: Compatibility claims could parse when the required verified_claims container was absent.
    resolution: Track and require one verified_claims declaration.
    red: shared with P00-AUDIT-001
    green: shared with P00-AUDIT-001
  - id: P00-AUDIT-003
    severity: IMPORTANT
    issue: Duplicate entries or verified_claims container declarations were not rejected.
    resolution: Reject the second declaration at parse time with the stable parse code.
    red: {total: 25, passed: 23, failed: 2}
    green: {total: 25, passed: 25, failed: 0}
runtime_experiment_run: false
```

**Review boundary.** This self-review is a quality gate, not equal-peer closure. Opus
must later review the design, dependency map, ledger claims, helper, negative controls,
and this changelog before joint closure can be claimed.

### P00-CX-009 — Wave A closure checkpoint

```yaml
timestamp: 2026-08-08T22:39:55+07:00
wave: A
wave_status: COMPLETE
phase_00_status: IN_PROGRESS
joint_peer_closure: PENDING_OPUS_QUOTA
final_file_hashes:
  docs/superpowers/specs/2026-08-08-phase-00-execution-evidence-design.md: 40D8F330E7E2B881CC3A1320A4CDA12FED104B663F41859051B21403B3E03F7B
  docs/superpowers/plans/2026-08-08-phase-00-wave-a-foundation-plan.md: 6116A18478C5BDC6C59D04986AB76AE2B774249CA53D6EB891A2681A7C102E05
  docs/evidence/phase-00/environment/repository-status-before.txt: 2B32CF8332EE7FF2CA0B94C0B9B1F7842D7B7A63A42B00D95D9BFECE83729355
  docs/evidence/phase-00/environment/baseline.yml: 2B4177A60C2BDEA13A467A6FC593B7FDA5FA2624B4B8892004AFC7E72F16F0D3
  docs/evidence/phase-00/manifest.yml: AB990DF2D00F278C37AD17FA067EFDC0FD79CD4817A4942E3813E32F879F6D2B
  registry/upstreams.yml: 258671A0AA224A26170054D725CDACBB986E8315FDEF68A1DE9E4C49A3AC220C
  registry/omp-compatibility.yml: AD63E887F655760E844CCB5C2552396DE2150EB7F82DE6B2B410EEF43D1CDC54
  scripts/lib/phase00-evidence.ps1: B0198FEA554D9E977B50C448EA3E5DC55F64216242CBF2ED422D9C31AF279AB3
  scripts/tests/phase00-wave-a.Tests.ps1: 257DE17097DD4769DC88427455D8E090037B63C6DCBD3D3ED52F93038C1CD080
  scripts/validate-template.ps1: E31DCAC593E6759A513EBABC744482227B0D206B64E5657DE1253A519E1D1FCA
preexisting_normative_diff:
  path: spec/phases/phase-00-foundation.md
  sha256: 212F5C6C055AF3BDF3CA21BEABB1F5CDFC6BAB25DCC74F6955BC4262E673E830
  changed_by_wave_a: false
fresh_verification:
  pwsh_pester: {total: 25, passed: 25, failed: 0, skipped: 0}
  windows_powershell_5_1_pester: {total: 25, passed: 25, failed: 0, skipped: 0}
  pwsh_repository_validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
  windows_powershell_5_1_repository_validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
  powershell_ast_parse_errors: 0
  yaml_secondary_parse_errors: 0
  incomplete_markers: 0
  trailing_whitespace_hits: 0
  production_write_commands: 0
  git_diff_check: PASS
  staged_files: 0
  pinned_clone_dirty_entries: 0
  watched_paths_missing: 0
manifest_status:
  pass_rows: [T-00.1, T-00.2]
  experiment_pass_count: 0
  e3_m: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
runtime_experiment_run: false
```

**Final hygiene correction.** Static review removed three intentional Markdown hard-break
spaces from the design header because untracked-file whitespace scanning correctly treated
them as trailing whitespace. Design hash changed from
`8928076C933AD91556D493015D67087712BF75570A76BE900ECEF29269640BCA`
to the value in `final_file_hashes`; no design semantics changed.

**Wave A conclusion.** The OMP source pin, watched paths, compatibility ledger, durable
manifest, baseline provenance, negative controls, and fail-closed validator integration
are present. This closes only T-00.1 and T-00.2 under Codex execution. It does not close
Phase 00, any runtime experiment, or Opus/Codex peer review.

### P00-CX-010 — Wave B E3-J/E3-K harness, fixtures, and pre-runtime gate

```yaml
timestamp: 2026-08-08T22:59:51+07:00
scope: WAVE_B_E3J_E3K_PRE_RUNTIME
previous_log_hash: 26B6FB4BA0C7198D546A2E00682266A61BEEBF3AB4AE73D4E9C642D89113629A
phase_00_status: IN_PROGRESS
joint_peer_closure: PENDING_OPUS_QUOTA
manifest_changed: false
runtime_provider_calls: 0
files_created:
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-b-e3j-e3k-plan.md
    sha256: ABD64A906270485CF5B604D08E961388C4A9E71D317990363EDD342FE8D0A7C8
  - path: scripts/tests/phase00-e3j-e3k.Tests.ps1
    sha256: 130B0C645802E1ADBB3EC7F47D140417DE241030B2E702F22D366972FA67D0C4
  - path: scripts/lib/phase00-runtime-evidence.ps1
    sha256: 89975C8F2EFB9C1A411A309327D0C2C991877B6E1B06B42B50D92CC8A01E40A8
  - path: scripts/run-phase00-e3j-e3k.ps1
    sha256: 3AC20B9EF0E66F877C8069C1FA0E2ACB80595E6495C46A84963016E80A4C0D97
  - path: docs/evidence/phase-00/E3-J/fixture/.omp/agents/phase00-blocking-probe.md
    sha256: 62B68CE937E2457FAEB0C724EF9205FA5E0F76B8BB9D43909E89EE2A7F3FB5E6
  - path: docs/evidence/phase-00/E3-J/fixture/.omp/agents/phase00-background-probe.md
    sha256: 972F4C5FB596E12B4B83F76CE6DA9DF4C947D42700854514667CC6E213CA1815
  - path: docs/evidence/phase-00/E3-J/fixture/config.yml
    sha256: 216C8464DA45E73DBB50A512921D2BC411BE2EDB06FD0232E45C2824BA7A956C
  - path: docs/evidence/phase-00/E3-J/fixture/prompts/J1-blocking-batch.md
    sha256: 582AB8B2A792B39AA79FAFC8A04FD14E42D76CF71AAA3667F75E539C2E5CB4B7
  - path: docs/evidence/phase-00/E3-J/fixture/prompts/J2-missing-blocking-control.md
    sha256: 1B53F31D4C9344E21B07FDC2FC3F55CCBB5124C32E478F858399135F29832669
  - path: docs/evidence/phase-00/E3-J/fixture/prompts/J3-stage-barriers.md
    sha256: 2CD0773C76FAB5FAE0D2CB6D14491068CBB8AE8B5B657D60C77274A3DFFDD82A
  - path: docs/evidence/phase-00/E3-K/fixture/.omp/agents/phase00-blocking-probe.md
    sha256: 62B68CE937E2457FAEB0C724EF9205FA5E0F76B8BB9D43909E89EE2A7F3FB5E6
  - path: docs/evidence/phase-00/E3-K/fixture/config.yml
    sha256: E21F9086AFC84046BA8FCB9605C8FED3024990F9F7716D2B097FC0EE5776E167
  - path: docs/evidence/phase-00/E3-K/fixture/prompts/K1-flat-wire-fallback.md
    sha256: 86996FE1437FC865A900A084262EB31752DC5377DC5E3106577E303712D595A4
tdd:
  initial_red: {total: 24, passed: 0, failed: 24}
  intermediate_1: {total: 24, passed: 8, failed: 16}
  intermediate_2: {total: 24, passed: 12, failed: 12}
  intermediate_3: {total: 24, passed: 19, failed: 5}
  final_green_pwsh_7_6_4: {total: 26, passed: 26, failed: 0, skipped: 0}
  final_green_windows_powershell_5_1: {total: 26, passed: 26, failed: 0, skipped: 0}
debugging:
  - issue: Synthetic task arguments were empty.
    root_cause: The helper parameter name Args collided with PowerShell's automatic Args variable.
    correction: Renamed the parameter to InputArgs.
  - issue: Pester 3 reported that exception controls did not throw.
    root_cause: Should Throw was not reliably observing these function invocations under the installed Pester 3.4 surface.
    correction: Added an explicit try/catch boolean assertion helper.
  - issue: A session directory inside the disposable Git fixture would make the isolation baseline dirty before OMP dispatch.
    root_cause: The first runner draft placed session storage below the fixture root after the fixture baseline commit.
    correction: Moved the forced session directory to a sibling disposable temp root and verify/delete both exact roots.
  - issue: Plain path redaction did not cover JSON-escaped Windows paths.
    correction: Added an escaped-path variant and a dedicated negative control.
evidence_contract:
  j1:
    - exactly one three-item isolated blocking batch
    - result indexes 0,1,2
    - completion order 2,0,1 from child timestamps
    - at least one strict interval overlap
    - no failed spawn
  j2:
    - third item uses the identical no-blocking control agent
    - inline result indexes only 0,1
    - index 2 remains observable through progress/async state
    - spawned-background response is present
  j3:
    - Verifier end precedes Reviewer start
    - Reviewer end precedes parent final-message boundary
    - both child delays are non-zero
  k1:
    - model-visible schema attestation occurs before dispatch
    - task is present while tasks and context are absent
    - both observed task arguments are flat
    - two logical work items execute as sequential calls
safety:
  live_omp_home_write_target: false
  profile_flag: false
  session_storage: disposable_sibling_temp_root
  fixture_git_repository: disposable_only
  credential_markers_rejected: true
  repository_and_disposable_paths_redacted: true
  discovery_reductions: [no-extensions, no-skills, no-rules, no-lsp, no-title]
static_verification:
  ast_parse_errors_pwsh: 0
  ast_parse_errors_windows_powershell: 0
  placeholders: 0
  trailing_whitespace: 0
  git_diff_check: PASS
  pinned_clone_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  pinned_clone_dirty_entries: 0
manifest_status:
  e3_j: READY
  e3_k: NOT_STARTED
  e3_m: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
```

**Interpretation boundary.** The source review explains why these predicates are
expected, and the synthetic suite proves that the adjudicator discriminates them. It
does not close E3-J or E3-K. The next legal action is `E3-J READY -> RUNNING` followed
by the real J1/J2/J3 OMP calls. E3-K remains dependency-blocked until E3-J has a valid
PASS conclusion.

## Open Peer-Review Questions

1. Does Opus accept the durable evidence root and common artifact envelope?
2. Does Opus find any Phase 00 dependency that the wave decomposition violates?
3. Does Opus require an additional provenance field before accepting experiment cases?

### P00-CX-011 — Wave B runtime attempts, safety correction, and environment block

```yaml
timestamp: 2026-08-08T23:25:37+07:00
scope: WAVE_B_E3J_RUNTIME
previous_log_hash: 823122D226DDCE4DD35C9D804E9A928B427724096D64A9EAF3E9DE682752513D
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
user_authorization: inline Phase 00 execution; no stage, commit, branch, push, or PR
phase_00_status: IN_PROGRESS
joint_peer_closure: PENDING_OPUS_QUOTA
manifest_transition:
  E3-J: READY -> RUNNING -> BLOCKED_ENVIRONMENT
  E3-K: NOT_STARTED
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
runtime_semantics_conclusions_authorized: 0
```

#### Runtime attempt ledger

| Attempt | Direct result | Safety result | Adjudication |
| --- | --- | --- | --- |
| J1/1 | OMP `17.2.10`; exit `0`; four parent-model connection failures; zero task events | The inherited live agent home changed metadata for `agent.db-shm`, `agent.db-wal`, and `models.db` (14 files before/after; 3 changed) | `BLOCKED_ENVIRONMENT`; **no contract power** because the read-only boundary failed |
| J1/2 | Exit `1`; isolated agent home stopped before provider dispatch because it had no model catalog; zero task events | Disposable agent/session/fixture roots; live-home before/after pair unchanged; cleanup succeeded | `BLOCKED_ENVIRONMENT`; harness prerequisite finding only |
| J1/3 | Exit `0`; safe catalog reached OmniRoute; terminal response was `404 No active credentials for provider: codex`; zero task events | Disposable agent/session/fixture roots; live-home before/after pair unchanged; cleanup succeeded | `BLOCKED_ENVIRONMENT`, reason `P00-RUNTIME-PROVIDER-AUTH` |

Recorded metadata pairs for the historical attempts:

```yaml
attempt_1_live_home:
  before_file_count: 14
  after_file_count: 14
  before_sha256: 6ae0a29e8f0d0b65a9091f44c7c0a98f54cbebdb8f457d70d51dfd79f4f1a239
  after_sha256: 055baaeec30560a5cb006fd2bff6eb80989006c20d14af53aadb7b0935211ec3
  changed_count: 3
attempt_2_live_home:
  before_file_count: 14
  after_file_count: 14
  before_sha256: 2903b21818511ed056940ae6c177ae1ea83103c83cee8e14abe9e757d909a1c2
  after_sha256: 2903b21818511ed056940ae6c177ae1ea83103c83cee8e14abe9e757d909a1c2
  changed_count: 0
attempt_3_live_home:
  before_file_count: 14
  after_file_count: 14
  before_sha256: 2903b21818511ed056940ae6c177ae1ea83103c83cee8e14abe9e757d909a1c2
  after_sha256: 2903b21818511ed056940ae6c177ae1ea83103c83cee8e14abe9e757d909a1c2
  changed_count: 0
```

These historical fingerprints hash only file metadata, not file contents. They are
valid for equality within each before/after pair. The post-audit runner now produces
its own deterministic metadata-only snapshot automatically; hashes from the new
implementation must not be compared across the historical implementation boundary.

#### Findings and corrections

1. `--session-dir` isolates session storage but does not isolate the OMP agent home.
   The runner now forces `PI_CODING_AGENT_DIR` to a separate disposable directory.
2. A blank isolated agent home cannot resolve the selected custom model. A reviewed
   non-secret `runtime-models.yml` is copied to the disposable agent home. It contains
   the loopback URL, the environment-variable name `OMNIROUTE_API_KEY`, and the model
   ID; it contains no credential value.
3. OMP can exit `0` while its JSON event stream contains a terminal provider error.
   The analyzer now classifies terminal model failures before attempting a case PASS.
4. JSON-escaped Windows paths bypassed the first sanitizer form. The sanitizer now
   redacts both literal and JSON-escaped repository/disposable paths.
5. Cleanup can race released process handles on Windows. Cleanup now retries with a
   bounded delay and accepts only exact roots proven below the system temp directory.
6. Standalone credential-variable names are metadata, not credential values. They are
   redacted, while assignments, bearer tokens, and credential-shaped values remain
   rejected.
7. The first post-run audit found that live-home fingerprints in historical evidence
   were not yet emitted by the reusable runner. A new RED test proved the gap
   (`33 total, 32 passed, 1 failed`). The runner now snapshots only relative path,
   file length, and UTC write ticks before/after every runtime call; it retains no file
   content and forces `INVALID_RUN/P00-RUNTIME-LIVE-HOME-WRITE` if metadata changes.
8. Manifest validation originally required artifacts only for `PASS`. A negative
   integration test showed `BLOCKED_ENVIRONMENT` could reference no durable evidence
   (`26 total, 25 passed, 1 failed`). The shared validator now requires existing
   artifacts for both states.

#### TDD and debugging sequence

```yaml
pre_runtime:
  initial_red: {total: 24, passed: 0, failed: 24}
  intermediate: [{passed: 8, failed: 16}, {passed: 12, failed: 12}, {passed: 19, failed: 5}]
  first_green_both_shells: {total: 26, passed: 26, failed: 0}
post_runtime_hardening:
  classifier_and_agent_home_red: {total: 28, passed: 25, failed: 3}
  classifier_and_agent_home_green_both_shells: {total: 28, passed: 28, failed: 0}
  cleanup_and_sanitizer_red: {total: 30, passed: 28, failed: 2}
  cleanup_and_sanitizer_green_both_shells: {total: 30, passed: 30, failed: 0}
  catalog_red: {total: 31, passed: 30, failed: 1}
  catalog_green_both_shells: {total: 31, passed: 31, failed: 0}
  blocked_artifact_red: {total: 26, passed: 25, failed: 1}
  blocked_artifact_green_both_shells: {total: 26, passed: 26, failed: 0}
  automatic_metadata_red: {total: 33, passed: 32, failed: 1}
  automatic_metadata_green_pwsh: {total: 33, passed: 33, failed: 0}
```

#### Exact durable mutations after P00-CX-010

```yaml
modified:
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-b-e3j-e3k-plan.md
    before_sha256: ABD64A906270485CF5B604D08E961388C4A9E71D317990363EDD342FE8D0A7C8
    after_sha256: 63344C144D8E3266953777DD600179F26B7A84E9A255FA9C72FCF4E80B222158
  - path: docs/evidence/phase-00/manifest.yml
    before_sha256: AB990DF2D00F278C37AD17FA067EFDC0FD79CD4817A4942E3813E32F879F6D2B
    after_sha256: 32F4288768BDA3698FA062BE4766AD36B0142CC1754FAA9831AD07F08D7F1759
  - path: scripts/lib/phase00-evidence.ps1
    before_sha256: B0198FEA554D9E977B50C448EA3E5DC55F64216242CBF2ED422D9C31AF279AB3
    after_sha256: D10193FE57C20A2A50142952572CDD29F24B63464B78FEBEE15F7D6CAD6AEEBB
  - path: scripts/tests/phase00-wave-a.Tests.ps1
    before_sha256: 257DE17097DD4769DC88427455D8E090037B63C6DCBD3D3ED52F93038C1CD080
    after_sha256: A2A610E68BB6DE5C831E46AFD0B3A557EC8B453EDEBA06AA66F03BF8256DF422
  - path: scripts/lib/phase00-runtime-evidence.ps1
    before_sha256: 89975C8F2EFB9C1A411A309327D0C2C991877B6E1B06B42B50D92CC8A01E40A8
    after_sha256: 4B11C00B37C037566B79E65CC8CA46A917FC9892D616087F1E5D99D50FAF01C1
  - path: scripts/run-phase00-e3j-e3k.ps1
    before_sha256: 3AC20B9EF0E66F877C8069C1FA0E2ACB80595E6495C46A84963016E80A4C0D97
    after_sha256: 6C944441DA653BFED50AEF7FABF50B1266447AC908A6AF35441233E9C7AE0225
  - path: scripts/tests/phase00-e3j-e3k.Tests.ps1
    before_sha256: 130B0C645802E1ADBB3EC7F47D140417DE241030B2E702F22D366972FA67D0C4
    after_sha256: 893FCF7F46FC092FB6053EF256CA9FCF94BEB8E5DA432D0FBCB605E1BBADFAF7
created:
  docs/evidence/phase-00/environment/runtime-models.yml: 56782B3FE9F3555C863062F5C92F398A3D147E3D6D4F39408BADD99751A5F779
  docs/evidence/phase-00/E3-J/J1.yml: DE831773BB256BFD44A3DC1B4DA6118B16C72602D65AD5E1D7C427208E10648F
  docs/evidence/phase-00/E3-J/conclusion.yml: 53921DDCD070908116B82C457E6D4338C611A0A3602189E3F2D790A7DC66B4E7
  docs/evidence/phase-00/E3-J/repository-status-after.txt: 700ADA19FABD2063B4C8DD0DF95135FDA6BDB30D43DFE0C1819F48FE03F86DF4
raw_artifacts:
  J1.run.json: A03278919E74C79D5D943EB8EB5BC9523778A91082D84B9EFCC3804CF462BB04
  J1.stdout.jsonl: D97F26A6AE2F30F694EF06C22000EA6C3D3DD3AB06F9EFC7899B2D91249D219C
  J1.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  J1-attempt-002.run.json: 4DC2F9F3F0254A9232ADCEA59D9E35EDDE6BFB2105CB71F324D8E1C52F1A1FEA
  J1-attempt-002.stdout.jsonl: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  J1-attempt-002.stderr.txt: 07735C851FDD95986D3409036D6F613CD6529202C50B6C5FC5B94C892147FF73
  J1-attempt-003.run.json: D0D0FB30383B348A09B6A6E7957DB95C54FBEB2CE899DB13FDD38B6102F4AAFD
  J1-attempt-003.stdout.jsonl: 8C39B02AB6ADF72CD813C7B3A8FDBFBC97313C9E62DE267A9CCCD06E499E81BE
  J1-attempt-003.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
unchanged_fixture_hashes: P00-CX-010 remains authoritative; every fixture hash rechecked equal
```

### P00-CX-012 — Wave B blocked checkpoint and fresh verification

```yaml
timestamp: 2026-08-08T23:25:37+07:00
checkpoint: BLOCKED_ENVIRONMENT_WAITING_FOR_OMNIROUTE_CODEX_CREDENTIAL
required_user_action: Restore an active codex credential inside the configured OmniRoute gateway; do not provide the credential in chat or repository files.
legal_resume_sequence: J1 -> J2 -> J3 -> E3-J adjudication; E3-K only after E3-J PASS
fresh_verification:
  pwsh_7_6_4:
    wave_a_pester: {total: 26, passed: 26, failed: 0, skipped: 0}
    runtime_pester: {total: 33, passed: 33, failed: 0, skipped: 0}
    repository_validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
  windows_powershell_5_1:
    wave_a_pester: {total: 26, passed: 26, failed: 0, skipped: 0}
    runtime_pester: {total: 33, passed: 33, failed: 0, skipped: 0}
    repository_validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
  ast_parse_errors_pwsh: 0
  ast_parse_errors_windows_powershell: 0
  yaml_documents_parsed: 6
  yaml_secondary_parse_errors: 0
  run_json_documents_parsed: 3
  nonempty_jsonl_files_parsed: 2
  jsonl_objects_parsed: 54
  json_parse_errors: 0
  live_home_read_only_probe: {file_count: 14, changed_count: 0, boundary: PASS_LIVE_HOME_READ_ONLY}
  trailing_whitespace_hits: 0
  incomplete_marker_hits: 0
  suspicious_secret_value_hits: 0
  git_diff_check: PASS
  staged_files: 0
  pinned_clone_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  pinned_clone_dirty_entries: 0
  remaining_disposable_roots: 0
manifest:
  pass_rows: [T-00.1, T-00.2]
  E3-J: BLOCKED_ENVIRONMENT
  E3-K: NOT_STARTED
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
preexisting_normative_diff:
  path: spec/phases/phase-00-foundation.md
  sha256: 212F5C6C055AF3BDF3CA21BEABB1F5CDFC6BAB25DCC74F6955BC4262E673E830
  changed_by_wave_b: false
```

**Blocked-slice boundary.** The repository harness and evidence contract are ready to
resume, but E3-J is not closed and Phase 00 is not closed. J2/J3 were deliberately not
executed after the shared provider prerequisite failed, and E3-K was not started because
its manifest dependency did not PASS. Opus should review this entry, the three raw run
records, the blocked artifacts, the runner safety correction, and the manifest transition
when quota is available.

### P00-CX-013 — OmniRoute recovery, E3-J PASS, and E3-K PASS

```yaml
timestamp: 2026-08-09T00:24:00+07:00
scope: WAVE_B_E3J_E3K_RUNTIME_CLOSURE
previous_log_hash: C32EF23F1ED591F82E083940AD0BF7F80EEE285244DF4CB8819B1250E8E7CA51
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
user_authorization: in-place Phase 00 execution; no stage, commit, branch, push, or PR
phase_00_status: IN_PROGRESS
joint_peer_closure: PENDING_OPUS_QUOTA
manifest_transition:
  E3-J: BLOCKED_ENVIRONMENT -> RUNNING -> PASS
  E3-K: NOT_STARTED -> READY -> RUNNING -> PASS
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
slice_claim: E3-J_AND_E3-K_EVIDENCE_COMPLETE_PENDING_OPUS_REVIEW
```

#### Environment recovery and credential handling

The user reported re-authenticating the Codex account in OmniRoute. Codex verified
the recovery without bypassing authentication or changing OmniRoute state:

```yaml
pre_recovery_attempt_004:
  parent_task_batch_started: true
  child_exit_codes: [1, 1, 1]
  child_provider_result: 404 No active credentials for provider codex
  gateway_projection:
    connection_count: 1
    is_active: true
    test_status: expired
    error_code: "401.0"
    last_error_type: unauthorized
    access_token_present: true
    refresh_token_present: true
  credential_contents_read: false
post_user_reauthentication:
  verified_at: 2026-08-08T23:53:21+07:00
  direct_responses_preflight: {http_status: 200, response_status: completed}
  final_connection_test_status: active
  final_error_fields: null
  runtime_resume_authorized: true
repository_credential_scan:
  scanned_files: 65
  suspicious_secret_value_hits: 0
```

**Security incident for mandatory Opus/user review.** During the pre-recovery
diagnostic, a PowerShell string-formatting mistake printed the value of the
process-local `OMNIROUTE_API_KEY` into assistant tool output. The value is deliberately
not repeated here. It was not written to any repository artifact; the final scoped
secret scan found zero credential-shaped values. Subsequent diagnostics emitted only
presence/length or non-secret status fields. Codex recommends rotating the local
gateway API key after this work. No browser-auth bypass, database credential edit,
token-content query, or external credential mutation occurred.

The durable recovery record is
`docs/evidence/phase-00/E3-J/environment-resume-diagnostic.yml`. It preserves the
historical expired/401 projection, the successful direct inference, the final active
status, and an explicit `credential_values_persisted_to_repository: false` assertion.

#### Runtime attempt ledger

| Case/attempt | Original analyzer result | Direct observation and final adjudication |
| --- | --- | --- |
| J1/4 | `BLOCKED_ENVIRONMENT` | The parent reached a three-item batch, but all child calls returned provider-auth 404. Retained with no contract power. |
| J1/5 | `INVALID_RUN` | Authentication worked and all children exited zero, but PowerShell `$s/$e` variables did not survive the OMP bash-tool boundary, so discriminator timing evidence was absent. Retained with no gate power. |
| J1/6 | `PASS` | Selected evidence: stable result order `[0,1,2]`, completion order `[2,0,1]`, all three strict overlap pairs, and task return after every worker settled. |
| J2/1 | `PASS` | Inline indexes `[0,1]`; missing-blocking control index `2` remained observable as a running background job. |
| J3/1 | `INVALID_RUN` | Runtime ordering was valid, but the analyzer expected a flat task name rather than the actual `args.tasks[0].name` batch wire. After the TDD fix, the preserved raw stream re-adjudicated PASS. |
| J3/2 | `PASS` | Selected independent reproduction: event order `verifier_end(165) < reviewer_start(294) < reviewer_end(326) < final_message(331)`. |
| K1/1 | `INVALID_RUN` | Runtime behavior was valid, but the bash result contained a one-line JSON attestation followed by `Wall time`; the analyzer incorrectly parsed the whole text as one JSON document. After the TDD fix, the preserved raw stream re-adjudicated PASS. |
| K1/2 | `INVALID_RUN` | Provider returned `server_is_overloaded`; cleanup and live-home boundary passed. Retained with no gate power. |
| K1/3 | `PASS` | Selected independent reproduction: preflight event `177`; task calls `[294,328]` then `[441,465]`; flat `task` present; `tasks` and `context` absent; call 2 starts after call 1 ends. |

Selected execution records:

```yaml
J1_attempt_006:
  started_at: 2026-08-08T23:58:37.6014808+07:00
  completed_at: 2026-08-08T23:59:33.2383019+07:00
  duration_ms: 55637
  result_order: [0, 1, 2]
  completion_order: [2, 0, 1]
  overlap_pairs: [0-1, 0-2, 1-2]
  child_timings_ms:
    - {index: 0, start: 1786208335685, end: 1786208353685, duration: 18000}
    - {index: 1, start: 1786208335870, end: 1786208365871, duration: 30001}
    - {index: 2, start: 1786208335997, end: 1786208341998, duration: 6001}
  cleanup_succeeded: true
  live_home_changed_count: 0
J2_attempt_001:
  started_at: 2026-08-08T23:59:51.7455499+07:00
  completed_at: 2026-08-09T00:00:26.6509586+07:00
  duration_ms: 34905
  inline_result_indexes: [0, 1]
  detached_index: 2
  detached_async_state: running
  cleanup_succeeded: true
  live_home_changed_count: 0
J3_attempt_002:
  started_at: 2026-08-09T00:03:10.2574677+07:00
  completed_at: 2026-08-09T00:03:59.7543892+07:00
  duration_ms: 49497
  event_order: [165, 294, 326, 331]
  cleanup_succeeded: true
  live_home_changed_count: 0
K1_attempt_003:
  started_at: 2026-08-09T00:12:18.5451638+07:00
  completed_at: 2026-08-09T00:15:28.3469428+07:00
  duration_ms: 189802
  attestation_event_index: 177
  task_call_boundaries: [[294, 328], [441, 465]]
  attested_top_level_keys: [agent, i, name, outputSchema, schemaMode, task]
  preflight_before_dispatch: true
  sequential_fallback: true
  cleanup_succeeded: true
  live_home_changed_count: 0
```

#### TDD repairs and fail-closed behavior

1. **Portable timing boundary.** J1/5 proved that fixture commands containing
   PowerShell variables were transformed across OMP's bash-tool boundary. A new
   behavioral test extracted and executed all ten timing assignments, rejected shell
   variables, and initially produced RED `33/34`. All four prompts now use a portable
   one-process Python timing command; both probe-agent descriptions were corrected.
   GREEN was `34/34`.
2. **J3 real batch wire.** The synthetic fixture was changed to the actual batch shape.
   RED was `32/34`. `Get-Phase00TaskInvocationName` now reads
   `args.tasks[0].name`, with the previous flat form retained only as a compatible
   fallback. GREEN was `34/34`, and J3/1 re-adjudicated PASS before J3/2 reproduced it.
3. **E3-J durable-artifact gate.** The test was strengthened to require J1/J2/J3 and
   conclusion PASS before E3-K eligibility. RED was `33/34`; after creating the
   records and manifest transition, GREEN was `34/34`.
4. **K1 line-bounded attestation.** The synthetic bash result gained the real wall-time
   suffix. RED was `31/34`. The parser now attempts JSON decoding only on complete
   individual output lines and accepts only the exact `phase00-task-wire-v1`
   discriminator; it does not parse embedded prose. GREEN was `34/34`, and K1/1
   re-adjudicated PASS.
5. **E3-K durable-artifact gate.** A new final contract required K1/conclusion PASS,
   selected attempt 3, the flat-call predicates, E3-K manifest PASS, and root
   `parallel_mode: DISABLED`. RED was `34/35`; artifact creation produced GREEN
   `35/35`.

No invalid or environment-blocked attempt was overwritten. Original `.run.json`
analyzer results remain historical facts; later re-adjudication is explicitly recorded
in the case history rather than retroactively editing raw run records.

#### Exact durable mutation ledger

Modified files (hashes are before this resume slice and after P00-CX-013 content was
prepared; the plan receives one final closure update in P00-CX-014):

```yaml
modified:
  - path: docs/superpowers/plans/2026-08-08-phase-00-wave-b-e3j-e3k-plan.md
    before_sha256: 63344C144D8E3266953777DD600179F26B7A84E9A255FA9C72FCF4E80B222158
    current_sha256: EFB853BEB0A9C0AC4C17E0F7CBB5B39EDC1BC420188FBEA841453121B4AC473F
  - path: docs/evidence/phase-00/manifest.yml
    before_sha256: 32F4288768BDA3698FA062BE4766AD36B0142CC1754FAA9831AD07F08D7F1759
    after_sha256: C4A9B466186903F91C695E4ADB0A1CBFE76668214012D8383E4AD270BDBA2D28
    transient_hashes:
      e3_j_running_attempt_004: 11E1FA2A3FBA969E65C6DB6E383724A6D560E3754A7F17EB689D31A7C5A102CD
      e3_j_blocked_attempt_004: 746A714575185A0213212F610FD8BDF6B6C58F02E1D1C8ED52BF7810C4F7E2B7
  - path: scripts/lib/phase00-runtime-evidence.ps1
    before_sha256: 4B11C00B37C037566B79E65CC8CA46A917FC9892D616087F1E5D99D50FAF01C1
    after_sha256: 83803D9EA7F94B57317674ECDD4153787E2642CCD1D0E65223181DEDD1573E36
  - path: scripts/tests/phase00-e3j-e3k.Tests.ps1
    before_sha256: 893FCF7F46FC092FB6053EF256CA9FCF94BEB8E5DA432D0FBCB605E1BBADFAF7
    after_sha256: 300BF41FAC630E193EAB158E11E9498A43E6BA383A99CB98554C9E847DBA768A
  - path: docs/evidence/phase-00/E3-J/fixture/.omp/agents/phase00-blocking-probe.md
    before_sha256: 62B68CE937E2457FAEB0C724EF9205FA5E0F76B8BB9D43909E89EE2A7F3FB5E6
    after_sha256: 9ABB03B8935E6C9A6E65B266AAF2177BCF4161FB6964C15E36DABA3CC31D3869
  - path: docs/evidence/phase-00/E3-J/fixture/.omp/agents/phase00-background-probe.md
    before_sha256: 972F4C5FB596E12B4B83F76CE6DA9DF4C947D42700854514667CC6E213CA1815
    after_sha256: 670640CDBA6084EBD1EC95040FAA0EEF4345ED671C7C268C72A9CB61B8031C22
  - path: docs/evidence/phase-00/E3-J/fixture/prompts/J1-blocking-batch.md
    before_sha256: 582AB8B2A792B39AA79FAFC8A04FD14E42D76CF71AAA3667F75E539C2E5CB4B7
    after_sha256: FC3A62563CB9CFF0D01A12904CE7888A92D0E0A776F375A48BD3E89FAF675A1F
  - path: docs/evidence/phase-00/E3-J/fixture/prompts/J2-missing-blocking-control.md
    before_sha256: 1B53F31D4C9344E21B07FDC2FC3F55CCBB5124C32E478F858399135F29832669
    after_sha256: 410F1B794360749B5407E0584ED9B38EC1F37AAEECCD6EB1655D982270276955
  - path: docs/evidence/phase-00/E3-J/fixture/prompts/J3-stage-barriers.md
    before_sha256: 2CD0773C76FAB5FAE0D2CB6D14491068CBB8AE8B5B657D60C77274A3DFFDD82A
    after_sha256: FD317D800EB72C8168B2921134D2E0BC86C2030E2783F9D5234C688E9479254E
  - path: docs/evidence/phase-00/E3-K/fixture/.omp/agents/phase00-blocking-probe.md
    before_sha256: 62B68CE937E2457FAEB0C724EF9205FA5E0F76B8BB9D43909E89EE2A7F3FB5E6
    after_sha256: 9ABB03B8935E6C9A6E65B266AAF2177BCF4161FB6964C15E36DABA3CC31D3869
  - path: docs/evidence/phase-00/E3-K/fixture/prompts/K1-flat-wire-fallback.md
    before_sha256: 86996FE1437FC865A900A084262EB31752DC5377DC5E3106577E303712D595A4
    after_sha256: 4B125D85154505287B9B08DDC6FD27D413858ECAB460E1787DDCA76EF86F95CD
  - path: docs/evidence/phase-00/E3-J/J1.yml
    before_sha256: DE831773BB256BFD44A3DC1B4DA6118B16C72602D65AD5E1D7C427208E10648F
    after_sha256: 37E97079429E84470AFBC9E79F10B03785F9A85738F90BCE8281D08CBEE93512
  - path: docs/evidence/phase-00/E3-J/conclusion.yml
    before_sha256: 53921DDCD070908116B82C457E6D4338C611A0A3602189E3F2D790A7DC66B4E7
    after_sha256: 18B25BAAD95361EAB688591442048F4D1CA890E2CF647CBAB9F76A1659CD3456
created:
  docs/evidence/phase-00/E3-J/environment-resume-diagnostic.yml: DF1381A770D3D1B579E6672C2DB0A2DA5075FFFE664D8B448C2800FB532CC384
  docs/evidence/phase-00/E3-J/J2.yml: ADB9E645FE5AC6325C91DD1EE3E72B8C73F6037FF25337EA36BE9AA1EE0E1B4B
  docs/evidence/phase-00/E3-J/J3.yml: 5566A57875CD8D01A8D650A5EA7358A6E0C33A914C0D03DD05CAE5029E373E96
  docs/evidence/phase-00/E3-K/K1.yml: 2DE5E8B592E5946C822AF4D1B88850CBD0768331BE95614BB1303D2F85E7100E
  docs/evidence/phase-00/E3-K/conclusion.yml: 5340A45C78DE8363FE6AFCA908939CDA661B5F7E034C848C5CDB33EBF4F0D7B4
```

New raw artifacts (all original attempts retained):

```yaml
raw_sha256:
  E3-J/J1-attempt-004.run.json: 441C0FB03B77C87501E77DF3FA95079BA17CFB369D82EE1999B8F3E54F0DDFD3
  E3-J/J1-attempt-004.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-J/J1-attempt-004.stdout.jsonl: 22902D9073E04A84AC3E27AE325D3A8DF14698AF754B405AEF08BC118D94E02B
  E3-J/J1-attempt-005.run.json: EBE5E3D2A99EB39BA9A11AC1E6DF950102730EA15CDB57187E78BFFF0EA86F81
  E3-J/J1-attempt-005.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-J/J1-attempt-005.stdout.jsonl: 4FC730AD579C242A54A3DEF3A01DCCE4EF155E421794E8091B3BA3DBEFBA150A
  E3-J/J1-attempt-006.run.json: 2A9B25708BED06F7EA60D70AC8327C5CCB108D49B10F831095EAA3EA39FD63ED
  E3-J/J1-attempt-006.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-J/J1-attempt-006.stdout.jsonl: AA915E1D584DF6E0AD1D67072D421AB9583219EE60B5B71FC890E6BF485B8E96
  E3-J/J2.run.json: 82B6B00EE422BFE7DE8F0DC94484F7ED3A322AF50E0B0713BCC45D5D00D92AF4
  E3-J/J2.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-J/J2.stdout.jsonl: 8704534F7B6FB08FE48911F4477E6012AA4C88525BB3B7906D71B479C6829D4A
  E3-J/J3.run.json: 641A5213DCE9E3D3D0C393BB59AD75F2285CDB386D8DC553BD28F7697EB2C201
  E3-J/J3.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-J/J3.stdout.jsonl: 99A248862F9F98B4673FCF3B1CD6FAA35CB768394FB5F2C827B3259C60CCBFCE
  E3-J/J3-attempt-002.run.json: 8EC378D6780D275C6F95A9F70122AB0B5B5568F980124A9D22BDAD9347FB8023
  E3-J/J3-attempt-002.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-J/J3-attempt-002.stdout.jsonl: 983F7C06D0AAD989EC11BECC51736B67778080A291795305FCE4D7CFBDC4B5B7
  E3-K/K1.run.json: 67A8C88B1F9707FF77BAA953975CDDA43EF4EB58AB5079C65D5A40A3EA40248F
  E3-K/K1.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-K/K1.stdout.jsonl: 928376956B1F4E58F9D6C724B0DC224C5981AE1A8312E1798CCEC6C6B984F289
  E3-K/K1-attempt-002.run.json: 5D6E92CE9196E514C4EC7A525DA8035922A93D681AC381DCEB2FC054DDAD7622
  E3-K/K1-attempt-002.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-K/K1-attempt-002.stdout.jsonl: 914BBA221292CED68D87A8E0C4287EA3A44C3A5B0A89526EE686242FCA7208FD
  E3-K/K1-attempt-003.run.json: 3CFE45D23B433D0935D66D687E58789C9FD368A0BF565E79C43914B50D771FCD
  E3-K/K1-attempt-003.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-K/K1-attempt-003.stdout.jsonl: 07EC847AA353448AAB01E4ADA56BC4DC669F1F92957E125A7E6F8F9517E276A1
```

#### Fresh verification

```yaml
pwsh_7_6_4:
  wave_a_pester: {total: 26, passed: 26, failed: 0, skipped: 0}
  runtime_pester: {total: 35, passed: 35, failed: 0, skipped: 0}
  repository_validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
windows_powershell_5_1_26100_8875:
  wave_a_pester: {total: 26, passed: 26, failed: 0, skipped: 0}
  runtime_pester: {total: 35, passed: 35, failed: 0, skipped: 0}
  repository_validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
  phase00_parsefile_files: 6
  phase00_parsefile_errors: 0
  utf8_decoded_repository_script_files: 10
  utf8_parse_errors: 0
structure:
  yaml_documents_parsed: 12
  run_json_documents_parsed: 12
  nonempty_jsonl_files_parsed: 11
  jsonl_objects_parsed: 4289
  parse_errors: 0
safety_and_repository:
  scoped_files_scanned: 65
  trailing_whitespace_hits: 0
  incomplete_marker_hits: 0
  suspicious_secret_value_hits: 0
  git_diff_check: PASS
  staged_files: 0
  pinned_clone_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  pinned_clone_dirty_entries: 0
  remaining_disposable_roots: 0
  live_home_read_only_probe: {file_count: 14, changed_count: 0, boundary: PASS_LIVE_HOME_READ_ONLY}
  normative_spec_sha256: 212F5C6C055AF3BDF3CA21BEABB1F5CDFC6BAB25DCC74F6955BC4262E673E830
  normative_spec_changed_by_this_slice: false
manifest:
  pass_rows: [T-00.1, T-00.2, E3-J, E3-K]
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
```

One expanded Windows PowerShell `Parser.ParseFile` scan initially reported two
terminator errors in unrelated pre-existing UTF-8-without-BOM files
`scripts/benchmark.ps1` and `scripts/uninstall-template.ps1`. The lines are valid when
decoded as repository UTF-8. A deliberate UTF-8 `ParseInput` pass over all ten scripts
reported zero errors, and direct `ParseFile` over all six Phase 00 executable/test
surfaces reported zero errors. Those unrelated files were not edited.

#### Review boundary and requests to Opus

This entry closes only Codex's evidence adjudication for E3-J and E3-K. It does not
close Phase 00, enable parallel v0, or substitute for Opus peer review. Opus should:

1. independently inspect the selected raw streams and confirm every event index and
   flat/batch argument interpretation;
2. challenge the line-bounded K1 JSON parser for false-positive paths;
3. verify that the J3 batch-name compatibility fallback cannot accept an unrelated
   task call;
4. confirm that attempt-selection history is transparent and that invalid runs have
   no gate power;
5. review the API-key exposure incident and the recommendation to rotate the local
   gateway key; and
6. accept or reject E3-J/E3-K PASS explicitly before any joint closure statement.

### P00-CX-014 — Final plan checkpoint after P00-CX-013

```yaml
timestamp: 2026-08-09T00:25:00+07:00
previous_log_hash: 7C16351B5FAEEC50187A6AE673B32FAC758C504C59473187195370E8A3320029
plan_finalization:
  path: docs/superpowers/plans/2026-08-08-phase-00-wave-b-e3j-e3k-plan.md
  before_sha256: EFB853BEB0A9C0AC4C17E0F7CBB5B39EDC1BC420188FBEA841453121B4AC473F
  after_sha256: D12141D51A56CA2CCB57110BAF042A8D93C114555D2B2B88B2BD63DF512F7E0A
  changes:
    - recorded the fresh dual-shell verification totals
    - marked every Task 8 item complete only after hashing, scanning, and P00-CX-013 append
    - retained phase_00_status IN_PROGRESS and peer_review PENDING_OPUS_QUOTA
git_mutation_policy:
  staged: false
  committed: false
  branch_created: false
  pushed: false
  pull_request_created: false
next_legal_scope: select and plan the next dependency-valid Phase 00 experiment; do not run E3-M while parallel_mode is DISABLED
```

### P00-CX-015 — Approved focused E3-A/E3-H design

```yaml
timestamp: 2026-08-09T00:39:27+07:00
previous_log_hash: E7D3335C0EE85D88FCE08056B124E141FEE031A7636858E5A870318808F825F5
user_decision: approved focused option 1 (E3-A plus E3-H only)
scope: DESIGN_ONLY_NO_RUNTIME_OR_HARNESS_EXECUTION
created:
  path: docs/superpowers/specs/2026-08-09-phase-00-e3a-e3h-design.md
  sha256: F16B241E3CC1109D78ADC6125488E01F1DEA7883E5E556F120BC2D62ED227C31
normative_anchors:
  - spec/phases/phase-00-foundation.md:226-253
  - spec/phases/phase-00-foundation.md:333-367
  - spec/08-isolation-and-concurrency.md:321-361
pinned_source_anchors:
  - docs/settings.md:15-26,91-107,788-817
  - packages/coding-agent/src/cli/config-cli.ts:338-360
  - packages/coding-agent/src/config/settings-schema.ts:4463,4497-4506
  - packages/coding-agent/src/task/types.ts:114-175,195-256
  - packages/coding-agent/src/task/index.ts:568-599
design_decisions:
  - share one disposable settings harness while retaining independent E3-A/E3-H records
  - run A1-A4 and H1-H6; no aggregate row may replace a case record
  - treat config-get success as DIAGNOSTIC_OK_NOT_AUTHORIZATION, never ALLOW_PARALLEL
  - prove per-item apply non-authority with supported-wire attestation plus a forced-raw runtime control
  - distinguish project/global/overlay/cwd/command-unavailable/unparseable cases
  - unlock E3-B/E3-C/E3-I/E3-L only after both experiment conclusions are durable PASS
  - keep E3-M deferred and parallel_mode DISABLED
self_review:
  placeholder_hits: 0
  trailing_whitespace_hits: 0
  required_sections_present: true
  ambiguity_correction: expanded every case artifact path explicitly
git_mutation_policy:
  staged: false
  committed: false
  branch_created: false
  pushed: false
  pull_request_created: false
next_gate: user review of the written design before implementation-plan creation
```

### P00-CX-016 — Approved E3-A/E3-H execution plan and H3 control-surface correction

```yaml
timestamp: 2026-08-09T00:48:27+07:00
previous_log_hash: 1104B275012E543D656B9BF7D074CF473E9B51114A850557C0026B8B24A4C8D1
user_decision: approved execution of the focused E3-A/E3-H design
execution_mode: INLINE_CODEX_NO_SUBAGENT
created:
  path: docs/superpowers/plans/2026-08-09-phase-00-e3a-e3h-plan.md
  sha256: B68F73E2C45D67E7F7D1062E8F40CD4B94D42CB55210974B8ACD77E288FE20BA
  lines: 750
modified:
  path: docs/superpowers/specs/2026-08-09-phase-00-e3a-e3h-design.md
  before_sha256: F16B241E3CC1109D78ADC6125488E01F1DEA7883E5E556F120BC2D62ED227C31
  after_sha256: C36BEBD1DF2D2FC9D4BA0A59DDDCF4404093D042515B93A34B3EA902435184C3
  lines: 337
empirical_correction:
  case: H3
  disposable_probe:
    executable: C:/Users/MrThien/AppData/Local/omp/omp.exe
    sanitized_command: omp --config <TEMP_ROOT>/overlay.yml config get task.isolation.apply --json
    exit_code: 1
    sanitized_stderr: "error: Unknown option '--config'."
    repository_write: false
    live_home_write: false
    durable_gate_power: false
  pinned_source_support:
    - packages/coding-agent/src/commands/config.ts:24-26 exposes only the json flag
    - packages/coding-agent/src/cli/config-cli.ts:243-244 initializes settings without configFiles
    - packages/coding-agent/src/main.ts:1283 applies parsed --config only to launch settings
  consequence:
    - H3 cannot claim that config get read a CLI overlay
    - durable H3 must reproduce the unsupported surface and return fail-closed refusal
    - stable reasons are CONFIG_CLI_OVERLAY_UNSUPPORTED and CLI_OVERLAY_UNOBSERVABLE
    - actual launch-session overlay precedence remains assigned to E3-I
    - the normative E3-H paragraph will be corrected only after durable runner evidence exists
plan_contract:
  tasks: 8
  tdd_order: parser -> decisions -> fixture/runner -> analyzers -> direct runtime -> provider runtime -> conclusions/manifest -> closure verification
  cases: [A1, A2, A3, A4, H1, H2, H3, H4, H5, H6]
  manifest_boundary: unlock only E3-B/E3-C/E3-I/E3-L after dual durable PASS
  parallel_mode: DISABLED
  E3-M: DEFERRED_PARALLEL_DISABLED
self_review:
  design_and_plan_placeholder_hits: 0
  design_and_plan_trailing_whitespace_hits: 0
  plan_task_headings: 8
  plan_self_review_items: 12
  git_diff_check: PASS
  staged_files: 0
  normative_spec_sha256_unchanged: 212F5C6C055AF3BDF3CA21BEABB1F5CDFC6BAB25DCC74F6955BC4262E673E830
git_mutation_policy:
  staged: false
  committed: false
  branch_created: false
  pushed: false
  pull_request_created: false
next_gate: execute the approved plan beginning with RED tests and the durable H3 correction proof
```

### P00-CX-017 — Execute and adjudicate focused E3-A/E3-H runtime slice

```yaml
timestamp: 2026-08-09T01:30:52+07:00
previous_log_hash: C22EF73BDD9FA42B9869D8E135449D5A8B3AFD51B8663A580D3C6ADFBCA51EF9
authorization: User approved in-place execution of focused option 1
execution_mode: INLINE_CODEX_NO_SUBAGENT
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
pinned_omp: {version: 17.2.10, commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8}
outcome:
  E3-A: PASS
  E3-H: PASS
  dependent_rows_now_ready: [E3-B, E3-C, E3-I, E3-L]
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
phase_00: IN_PROGRESS
opus_peer_review: PENDING_QUOTA
joint_closure: NOT_CLAIMED
```

#### Implemented evidence boundary

- `scripts/lib/phase00-config-evidence.ps1:23-383` implements exact single-key
  JSON parsing, process/read classification, fail-closed diagnostic results, and
  direct A1-A3/H1-H4/H6 adjudicators. No return path contains `ALLOW_PARALLEL`.
- `scripts/lib/phase00-config-evidence.ps1:385-584` pairs structured tool calls/results
  and adjudicates A4/H5. A4 rejects extra attestation retries, unpaired eval calls,
  child aborts, a supported `apply` item field, or missing merge proof. H5 requires
  the exact bash command to fail structurally before any task dispatch; prose cannot
  satisfy the gate.
- `scripts/run-phase00-e3a-e3h.ps1:24-187` pins case definitions, installed OMP
  discovery, exact arguments, a filtered H5 child PATH, and disposable fixture
  materialization. `scripts/run-phase00-e3a-e3h.ps1:188-274` uses
  `System.Diagnostics.Process` so PowerShell 5.1 cannot rewrite native non-zero
  stderr into a `NativeCommandError`; stdout/stderr, exit code, start/completion
  timestamps, and timeout are captured separately. Lines `276-348` implement
  live-home metadata comparison and bounded cleanup. Lines `391-662` run one case,
  sanitize before persistence, preserve attempt numbering, and write provenance.
- `scripts/lib/phase00-runtime-evidence.ps1:456-486` was strengthened to redact
  disposable/repository paths through slash-normalized and zero-to-six nested JSON
  escape layers while still refusing credential-shaped output.
- `scripts/tests/phase00-e3a-e3h.Tests.ps1:45-779` contains 44 tests across the H3
  surface, strict parser, fail-closed diagnostics, fixture/runner safety, direct and
  provider adjudication, provenance, durable cases, conclusions, and dependency-safe
  manifest transitions.
- `scripts/tests/phase00-wave-a.Tests.ps1:179-202` now mutates the current canonical
  states rather than obsolete `NOT_STARTED` values. This is test-fixture maintenance:
  production manifest validation was not relaxed.

#### Case verdict matrix and epistemic limits

| Case | Verdict | Selected evidence | What it proves | What it does not prove |
| --- | --- | --- | --- | --- |
| A1 | PASS | direct attempt 1 | Project-root reads are exactly `mode=rcopy`, `apply=false`. | A diagnostic read is not parallel authorization. |
| A2 | PASS | direct attempt 1 | Unknown schema key exits non-zero and yields `CONFIG_KEY_UNKNOWN`. | No setting value was observed. |
| A3 | PASS | direct attempt 1 | Root reads project values; `packages/foo` falls back to `mode=none`, `apply=true`; cwd refusal is required. | OMP does not search ancestor `.omp/` directories in this case. |
| A4 | PASS | provider attempt 4 | Model-visible item keys are `[agent, isolated, name, outputSchema, schemaMode, task]`; supported wire has no `apply`; forced raw `apply:false` cannot override session `apply:true`; sentinel is applied. | The eval bridge does not locate normal ArkType field deletion. Source plus visible wire establish supported-field exclusion. |
| H1 | PASS | shares A1 raw | Project `apply=false` overrides disposable global `apply=true`. | Still diagnostic only. |
| H2 | PASS | direct attempt 1 | With no project config, `mode=none` and `apply=true` refuse with disclosed sequential non-isolated fallback. | No parallel path is authorized. |
| H3 | PASS (characterization) | direct attempt 1 | Both plausible `--config` placements exit 1; preflight returns `REFUSE` with `CONFIG_CLI_OVERLAY_UNSUPPORTED` and `CLI_OVERLAY_UNOBSERVABLE`. | This is not an overlay-precedence read and does not attest the parent launch session. |
| H4 | PASS | shares A3 raw | Nested-cwd refusal explicitly diagnoses cwd scoping. | It does not claim a generic settings mismatch. |
| H5 | PASS | provider attempt 2 | Exact `omp config get task.isolation.mode --json` fails as structured bash command-not-found code 127 after removing the OMP directory from child PATH; task dispatch count is zero. | Model prose has no gate power. |
| H6 | PASS | synthetic parser control | Non-zero process failure and zero-exit malformed JSON remain distinct refusal reasons. | No runtime call is claimed. |

The durable verdict files are `docs/evidence/phase-00/E3-A/A1.yml` through `A4.yml`,
`docs/evidence/phase-00/E3-H/H1.yml` through `H6.yml`, and each experiment's
`conclusion.yml`. H1/H4 explicitly reference shared raw cases; H6 explicitly records
`runtime_call: false`. No aggregate verdict invents a separate observation.

#### H3 contract correction, with direct and source evidence

The pre-execution normative text required `omp config get` to read a CLI `--config`
overlay. Durable H3 proved that instruction impossible on the pinned runtime:

```text
omp --config <DISPOSABLE_OVERLAY> config get task.isolation.apply --json
  -> exit 1; Unknown option '--config'
omp config get task.isolation.apply --json --config <DISPOSABLE_OVERLAY>
  -> exit 1; Unknown option '--config'
```

Pinned source independently explains the observation:

- `packages/coding-agent/src/commands/config.ts:31-33` exposes only the `json` flag;
- `packages/coding-agent/src/cli/config-cli.ts:243-244` calls `Settings.init()` without
  `configFiles`;
- `packages/coding-agent/src/config/settings.ts:86,381-383,1254-1260` supports config
  overlays when they are supplied to settings initialization;
- `packages/coding-agent/src/main.ts:1282-1283` passes parsed launch `--config` files
  into the normal session settings initialization.

Accordingly, `spec/phases/phase-00-foundation.md:335-362` now limits concrete
`config get` reads to project/default/cwd cases and defines H3 as a fail-closed
observability characterization. Actual launch-overlay precedence remains E3-I. This
is a narrow empirical correction, not an implementation-phase expansion.
`docs/superpowers/specs/2026-08-09-phase-00-e3a-e3h-design.md:3,159-178,323-326`
records the implemented status, selected H3 hashes, and corrected acceptance wording.

#### Provider attempts and selection discipline

**A4 selected attempt 4.** Parent exit 0; start
`2026-08-09T01:17:13.6557215+07:00`; completion
`2026-08-09T01:17:40.6242536+07:00`; duration 26969 ms; fixture commit
`b2f644e68cfe6a42d341c0fe2624ce03ee2f645b`; exactly one bash attestation,
one eval bridge, zero direct task calls; cleanup succeeded; live-home changed count 0.

- Attempt 1: `INVALID_RUN_POST_AUDIT`; worker used a .NET expression unsupported by
  the brush shell and aborted before merge observation. Its deeply JSON-escaped
  disposable path exposed a sanitizer depth gap. The stdout artifact was repaired
  deterministically from SHA-256
  `D942F955FEAA3D9C57CCA873E584AF9D65B123B905D97FE81F585F1F693A07C7`
  to `5D0F48C8C722E34EAAD56786FEFC902F4CC6B87DD0119C417D2DD67B87547B18`;
  semantic payload changed: false. Gate power: none.
- Attempt 2: `INVALID_RUN_POST_AUDIT`; semantics passed, but the parent made an extra
  failed bash call and retried, violating the one-attestation-call fixture. Gate power: none.
- Attempt 3: `INVALID_RUN_PROVENANCE_INCOMPLETE`; runtime predicates passed, but the
  run record lacked process exit and start/completion provenance. Gate power: none.
- Attempt 4: selected only after the fixture, single-call analyzer, and provider run
  provenance were all complete.

**H5 selected attempt 2.** Parent exit 0; start
`2026-08-09T01:17:41.3677207+07:00`; completion
`2026-08-09T01:17:49.0229094+07:00`; duration 7655 ms; exactly one bash call,
zero task calls; cleanup succeeded; live-home changed count 0.

- Attempt 1: runtime predicates passed but the run record lacked process exit and
  start/completion provenance; `INVALID_RUN_PROVENANCE_INCOMPLETE`, gate power none.
- Attempt 2: selected only after provenance was complete.

The process-local provider command used the reviewed non-secret model catalog at
SHA-256 `56782B3FE9F3555C863062F5C92F398A3D147E3D6D4F39408BADD99751A5F779`,
relocated `PI_CODING_AGENT_DIR`, disposable cwd/session/config/prompt paths, and the
existing gateway credential. The credential was never printed or persisted by these
runs.

#### Manifest transition

| Row | Before | After | Reason |
| --- | --- | --- | --- |
| E3-A | READY | PASS | A1-A4 durable PASS |
| E3-H | READY | PASS | H1-H6 durable PASS |
| E3-B | NOT_STARTED | READY | Dependencies E3-A and E3-H passed |
| E3-C | NOT_STARTED | READY | Dependencies E3-A and E3-H passed |
| E3-I | NOT_STARTED | READY | Dependencies E3-A and E3-H passed |
| E3-L | NOT_STARTED | READY | Dependencies E3-A and E3-H passed |
| E3-M | DEFERRED_PARALLEL_DISABLED | unchanged | E3-L not executed; parallel mode remains disabled |
| manifest root | `parallel_mode: DISABLED` | unchanged | This slice cannot enable parallel execution |

An in-progress manifest state existed during runtime execution but was not retained as
a gate artifact or hash-pinned. It had no terminal gate power. The pinned before/final
manifest hashes below are the reviewable state transition.

#### Exact non-raw mutation ledger

```yaml
created:
  scripts/lib/phase00-config-evidence.ps1: 7B2ECD9DBF4E56BEA8C6E86B5B2141F0AD6BA725E363BD1A08FBFB00ADAE575A
  scripts/run-phase00-e3a-e3h.ps1: 6C700C99B15DB95CB0E33A4B8992FC21E04E9EA7DED62AA75916CE819ED487BC
  scripts/tests/phase00-e3a-e3h.Tests.ps1: A32A505A60C97E8827BBA5530ABA3C9E84E84456EF3FDA604EB727B8B5ADF395
  docs/evidence/phase-00/E3-A/fixture/global-config.yml: E5D0733326788E991883EDFFDCEB1D20197C0241092D096A8B9B0F8FE96C4509
  docs/evidence/phase-00/E3-A/fixture/project-config.yml: 479A6945FCE2E4DE8FE40C33C2672B622DA3B22B87CD88AB519ED1260B17353F
  docs/evidence/phase-00/E3-A/fixture/overlay-config.yml: 6475F550E883AEE481483826672AC85813BEE94113B47FAAC264A5E9E37AE393
  docs/evidence/phase-00/E3-A/fixture/.omp/agents/phase00-apply-probe.md: 4F51548EA1F6DC0648474E007FFDBB3E165F48629E224CC8DA78E94F6903DC40
  docs/evidence/phase-00/E3-A/fixture/prompts/A4-apply-non-authority.md: B32436CFFD7578FE726EBD7FA9BB5DC2F16F2F65FEDD2FB40C106794EEC00FF6
  docs/evidence/phase-00/E3-H/fixture/prompts/H5-config-command-unavailable.md: ADF68A2E396CD3901B2B72AC91507AA7936F089E3FD23192F0700ACC11E5FB01
  docs/evidence/phase-00/E3-A/A1.yml: 54884087A75A371DEA0CECFAC9D7A17C36F3A6820BC4DD1AF139AAD38647B06C
  docs/evidence/phase-00/E3-A/A2.yml: 4D4C7958CFDABFB0ED29E41A70FB5977CFE2B632E9B261C4F85152F5A5DAA6D0
  docs/evidence/phase-00/E3-A/A3.yml: 5E6565BA9954320C9D330CDBF38E606A92FEAD70BB5CFA7A0D9414D7833181D2
  docs/evidence/phase-00/E3-A/A4.yml: 15B63BDC291E91EC28EA5F0A1FE0F1A908EBB54C020DEAE7B437B423AA8222DF
  docs/evidence/phase-00/E3-A/conclusion.yml: A47948784FF2E1A2E9B657ECC949556D87D641C6E6DAF5C5F66BB59C74C6B11E
  docs/evidence/phase-00/E3-H/H1.yml: EF386DB61A982B49009784F37EBFB94653876BF05AEBD85B8E5D2C935FE4896E
  docs/evidence/phase-00/E3-H/H2.yml: 31D738F61E9350FC0B1BE3940362350C5BF285C09BC7F29EC123388CEB1164E0
  docs/evidence/phase-00/E3-H/H3.yml: 8EDC14A04B412E5B311D6542A1A46D50840C5462ABEF8AAFE137E27CD9A2D08A
  docs/evidence/phase-00/E3-H/H4.yml: 4CFD6D3D242218A714DF7A7CF130F8603AD33FEE16F8D75FA816BD9848839A4F
  docs/evidence/phase-00/E3-H/H5.yml: FC59C187FBDBEC4521E1A61A17129F0032768783E876B0B12EBC2F966ADEC674
  docs/evidence/phase-00/E3-H/H6.yml: 99887A82D0CC977D9FBAC6860FEEDAC16B9DA867907CB9B675715FA380FA0BF1
  docs/evidence/phase-00/E3-H/conclusion.yml: 0E8CA521A322C76119BE6F732B7B117320D8C19C5448013B473EF7943983F270
modified:
  scripts/lib/phase00-runtime-evidence.ps1:
    before_sha256: 83803D9EA7F94B57317674ECDD4153787E2642CCD1D0E65223181DEDD1573E36
    after_sha256: 219B017B073F9EE0ED6756D86A914E72D2DAB281108B7B49FD0C32865B49B839
  scripts/tests/phase00-wave-a.Tests.ps1:
    before_sha256: A2A610E68BB6DE5C831E46AFD0B3A557EC8B453EDEBA06AA66F03BF8256DF422
    after_sha256: C9CE99B9FF47ECE40208EBFAB03899AEEB84E09984303A26953FCED2A5F62A0E
  docs/evidence/phase-00/manifest.yml:
    before_sha256: C4A9B466186903F91C695E4ADB0A1CBFE76668214012D8383E4AD270BDBA2D28
    after_sha256: 00C84F3457CC17974251471F5B88DEFE86AE938E594B79B29B1112BABB4A9BD1
  spec/phases/phase-00-foundation.md:
    before_sha256: 212F5C6C055AF3BDF3CA21BEABB1F5CDFC6BAB25DCC74F6955BC4262E673E830
    after_sha256: B35CDB32EE1639401E61EE3F0AFC6542EA98131DBEE223FC554F134AA87E1DBC
  docs/superpowers/specs/2026-08-09-phase-00-e3a-e3h-design.md:
    before_sha256: C36BEBD1DF2D2FC9D4BA0A59DDDCF4404093D042515B93A34B3EA902435184C3
    after_sha256: 365D90D8BA1548BF2631A5017F6559DC2CAFC6CD62611731974B2868ED375194
governing_plan_before_final_checkpoint:
  docs/superpowers/plans/2026-08-09-phase-00-e3a-e3h-plan.md: B68F73E2C45D67E7F7D1062E8F40CD4B94D42CB55210974B8ACD77E288FE20BA
files_removed: []
```

#### Exact raw artifact SHA-256 ledger

```yaml
selected_direct:
  E3-A/A1.stdout.json: 034CD81D381D84BF6393A21E522E69DF036DCF61612470716FEB61BD69D43993
  E3-A/A1.stderr.txt: 2B88F4A5639A1744335AD586C144A2B1E10E7FA467C1B427319E6E7D5F5643E1
  E3-A/A1.run.json: 26161599995467193F365D71DE0C5D445025285AEB9842C05A948208C0551B68
  E3-A/A2.stdout.json: 31308AE4FD5D9A6DF8604FA8FC02BB195590E6BEA1414BFB07155B7A84F6955F
  E3-A/A2.stderr.txt: 028E308DD189E84308C711687947BD8410FFE76BD3BC929C2EABC7B927F4BEFC
  E3-A/A2.run.json: B29C1790EC71F116F313C843F07373A59230C2390A6009EB64923E788D228642
  E3-A/A3.stdout.json: 5E3ADA9A5AD04266AAF7ADEDE7C1D032ED8933E5BE0EF3FF15E21EEF5C29A881
  E3-A/A3.stderr.txt: 96E07D08B645A8217F38241F8AE053A6D56DBC1DD62B1BF4F9E22311E7F1DF4D
  E3-A/A3.run.json: 84E39DE7FEFA94BAD62AD04C51F4E9FE18D4C935CEFD9F2FDDBD7C0E76498953
  E3-H/H2.stdout.json: 9E6DF19A62DD8352FAE141AFC445206378B34A19EE7FAFF08C779D9227B882BA
  E3-H/H2.stderr.txt: B1F8F1CE02BC315FA4299739C962788AE06D81DFD8A1FDFD42A0E35B262BE7FD
  E3-H/H2.run.json: 7FD6A6EB61AEE11BD691C70DE600B461CB196576D4D0B65F0A930833C438A588
  E3-H/H3.stdout.json: 73CDD144895AF8ABFB41EA42BEFA5A4744B9E786F0C8EB98335A5AC108C9E55D
  E3-H/H3.stderr.txt: 6BDAC0AC268EB0F152267385F49878F40FFC228F7FB89EC86150DD26A10147EA
  E3-H/H3.run.json: 8641A2A59CE6764200D20EBD393273C92AD7B6881DF46AA9CCCDADC7CF8A7A1B
selected_provider:
  E3-A/A4-attempt-004.stdout.jsonl: 91095C2217137A8DA726E45000EAA6B4087C49A1909E8AA28420CB5608708DD1
  E3-A/A4-attempt-004.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-A/A4-attempt-004.run.json: 11E4D0C81407C76267D464182B8A823376642D8A3920F4735768F364076AE711
  E3-H/H5-attempt-002.stdout.jsonl: BBA95B952F863399C3C51919C62D8F37A14991BA7CA4D2EE5E4BC182601D0CE8
  E3-H/H5-attempt-002.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-H/H5-attempt-002.run.json: 37E2DD64FE7E77089E6081AFB342E9A6D09E543DE8DC24ECCE501D6156BB17EE
retained_non_gating:
  E3-A/A4.stdout.jsonl: 5D0F48C8C722E34EAAD56786FEFC902F4CC6B87DD0119C417D2DD67B87547B18
  E3-A/A4.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-A/A4.run.json: D7E1FBE040583ADACC68954BBF5CC8EAB39FCD24EE71D5CED6F5EC22E2AF62F0
  E3-A/A4-attempt-002.stdout.jsonl: 3BE7D701A20CF11B64CD83F103A8B97D33B415A521D4ED372AF4096ECB33B1AB
  E3-A/A4-attempt-002.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-A/A4-attempt-002.run.json: 202F972CA9C6199D23A2A59233CE1CEF8D129C1E0DBADB0582893F50DBF8450A
  E3-A/A4-attempt-003.stdout.jsonl: 1C115917EAE9F28DE4C72E129A257FE57808472824FB138DAD4C34B7C97A0E22
  E3-A/A4-attempt-003.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-A/A4-attempt-003.run.json: 5FEA649ACE5B4BAAA42A4C2CF002F1F8C431F6AC21A4C80767A6246CDE25864A
  E3-H/H5.stdout.jsonl: 8C46F758FA42BCDF910C136D5AD674F58BEA10A9D99C50D360BD409487E35029
  E3-H/H5.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  E3-H/H5.run.json: 09F77B3DA8B7F662A29FF4FD22F7ED5A28E6E14F5EB7E3C5BFCEDDF77AF1E6AF
```

#### Test-first and debugging record

The implementation followed the approved parser -> decisions -> fixture/runner ->
analyzers -> direct runtime -> provider runtime -> conclusions sequence. Tests were
written before each production surface. Transient RED console logs were not persisted
as artifacts, so this entry does not invent exact RED totals; the durable test names,
source, and final totals are pinned. Two defects were found by verification and fixed:

1. Windows PowerShell 5.1 changed the non-zero native stderr shape under direct
   invocation. Replacing shell-mediated capture with `ProcessStartInfo` made exit,
   stdout, and stderr evidence identical in meaning across shells.
2. After E3-A/E3-H transitioned to PASS, two Wave A negative fixtures no longer
   performed their intended mutations. The tests were updated to make E3-A non-PASS
   under a READY dependent and to put the forbidden deferred state on current E3-L.
   The validator implementation was unchanged.

Pre-changelog closure evidence at this entry: focused PowerShell 5.1 `44/44`; full
PowerShell 7 `105/105`; full PowerShell 5.1 `105/105`; repository validator
`89 passed, 0 warnings, 0 failed`; 12 case/conclusion YAML documents parsed; 21
selected raw hash references matched their files; seven selected runtime records had
zero live-home boundary failures; current live-home metadata matched the final H5
snapshot; zero `omp-phase00-*` temp roots remained. P00-CX-018 records the final fresh
post-documentation verification.

#### Security, repository, and review boundary

- No live OMP configuration, authentication record, or secret file was modified.
- No Git stage, commit, branch, push, pull request, reset, or checkout occurred.
- The repository remained on `main` at the original HEAD. Pre-existing user changes
  and untracked review packets were preserved.
- During an earlier diagnostic command outside these persisted artifacts, a local
  gateway credential value appeared in assistant-only tool output because of a
  PowerShell formatting mistake. It was not copied into any repository file or
  response. Rotate that local gateway key as a precaution.
- E3-A/E3-H PASS is Codex adjudication only. It does not close Phase 00, enable
  parallel work, approve E3-M, or represent Opus agreement.

Opus should independently challenge: (1) strict JSON shape rejection; (2) A4's event
pairing and one-bash/one-eval requirement; (3) whether the eval bridge supports only
the stated non-authority claim; (4) H5's PATH isolation and zero-task evidence; (5)
H3's move from impossible precedence-read language to fail-closed characterization;
(6) every selected/non-selected hash and history record; and (7) the manifest's exact
dependency transitions. Any disagreement reopens the affected case; Codex's PASS is
not privileged over Opus counter-evidence.

### P00-CX-018 — Final post-documentation closure verification checkpoint

```yaml
timestamp: 2026-08-09T01:35:56+07:00
previous_log_hash: 18F436740B812C55B934865424A1AC62D3BDBE0C4CF8366770F9A8F1EC915014
verification_scope: fresh after spec, design, evidence, manifest, changelog entry P00-CX-017, and plan checkpoint
powerShell_7_6_4:
  pester:
    wave_a: {total: 26, passed: 26, failed: 0}
    E3-J_E3-K: {total: 35, passed: 35, failed: 0}
    E3-A_E3-H: {total: 44, passed: 44, failed: 0}
    aggregate: {total: 105, passed: 105, failed: 0, exit_code: 0}
  repository_validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
windows_powerShell_5_1_26100_8875:
  pester:
    wave_a: {total: 26, passed: 26, failed: 0}
    E3-J_E3-K: {total: 35, passed: 35, failed: 0}
    E3-A_E3-H: {total: 44, passed: 44, failed: 0}
    aggregate: {total: 105, passed: 105, failed: 0, exit_code: 0}
  repository_validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
parse_and_integrity:
  yaml_documents: {parsed: 13, errors: 0}
  selected_raw_hash_references: {checked: 21, mismatches: 0}
  json_documents: {parsed: 12, errors: 0}
  jsonl_files: 2
  jsonl_objects: {parsed: 334, errors: 0}
  powershell_ast_pwsh: {files: 5, errors: 0}
  powershell_ast_ps5: {files: 5, errors: 0}
safety:
  scoped_files: 61
  suspicious_secret_value_hits: 0
  incomplete_marker_hits: 0
  trailing_whitespace_hits: 0
  raw_files_scanned: 33
  raw_real_path_leak_hits: 0
  raw_credential_name_hits: 0
  selected_live_home_boundary_failures: 0
  current_live_home_file_count: 14
  current_live_home_matches_final_selected_snapshot: true
repository:
  git_diff_check: PASS
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  worktree_status_entries: 32
  staged_files: 0
  pinned_clone_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  pinned_clone_dirty_entries: 0
  remaining_omp_phase00_temp_roots: 0
  git_stage_commit_branch_push_pr_performed: false
final_non_log_hashes:
  scripts/lib/phase00-config-evidence.ps1: 7B2ECD9DBF4E56BEA8C6E86B5B2141F0AD6BA725E363BD1A08FBFB00ADAE575A
  scripts/lib/phase00-runtime-evidence.ps1: 219B017B073F9EE0ED6756D86A914E72D2DAB281108B7B49FD0C32865B49B839
  scripts/run-phase00-e3a-e3h.ps1: 6C700C99B15DB95CB0E33A4B8992FC21E04E9EA7DED62AA75916CE819ED487BC
  scripts/tests/phase00-e3a-e3h.Tests.ps1: A32A505A60C97E8827BBA5530ABA3C9E84E84456EF3FDA604EB727B8B5ADF395
  scripts/tests/phase00-wave-a.Tests.ps1: C9CE99B9FF47ECE40208EBFAB03899AEEB84E09984303A26953FCED2A5F62A0E
  docs/evidence/phase-00/manifest.yml: 00C84F3457CC17974251471F5B88DEFE86AE938E594B79B29B1112BABB4A9BD1
  spec/phases/phase-00-foundation.md: B35CDB32EE1639401E61EE3F0AFC6542EA98131DBEE223FC554F134AA87E1DBC
  docs/superpowers/specs/2026-08-09-phase-00-e3a-e3h-design.md: 365D90D8BA1548BF2631A5017F6559DC2CAFC6CD62611731974B2868ED375194
  docs/superpowers/plans/2026-08-09-phase-00-e3a-e3h-plan.md:
    before_sha256: B68F73E2C45D67E7F7D1062E8F40CD4B94D42CB55210974B8ACD77E288FE20BA
    after_sha256: 6779CF1D431FA99CC0FBE3C9D68AB04DF764FBC4742FB6BD74A446C6723401EC
phase_00_status: IN_PROGRESS
next_dependency_safe_scope: design exactly one new slice selected from E3-B, E3-C, E3-I, or E3-L
parallel_mode: DISABLED
opus_peer_review: PENDING_QUOTA
```

The worktree was already dirty and contains the complete user/Codex Phase 00 history;
the 32 status entries are disclosed, not treated as newly clean. Zero files are staged.
The final SHA-256 of this self-referential changelog is intentionally reported in the
handoff response after this entry is appended; P00-CX-018 pins its immediate predecessor
so Opus can verify append-only continuity.

### P00-CX-019 — E3-I approved-design checkpoint (no implementation)

```yaml
timestamp: 2026-08-09T08:39:00+07:00
previous_log_hash: A79058B49FB17C4297055615E56E95A1E03DCFD4F3EC61BE966D37BCB8ED1642
scope: E3-I parent-overlay canary design only
user_approvals:
  normative_correction: approved
  selected_approach: two parent sessions / three runtime states
  architecture_and_oracles: approved
  data_flow_and_safety: approved
  test_strategy_manifest_acceptance_and_non_goals: approved
created:
  docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md:
    sha256: 83C0774F4F77F920F5CEE7BB8D8C5E79F5D365F3CF11B0E735A37FB5D8E9B275
    lines: 516
    bytes: 23509
unchanged_authority_files:
  spec/phases/phase-00-foundation.md: B35CDB32EE1639401E61EE3F0AFC6542EA98131DBEE223FC554F134AA87E1DBC
  docs/evidence/phase-00/manifest.yml: 00C84F3457CC17974251471F5B88DEFE86AE938E594B79B29B1112BABB4A9BD1
repository:
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  staged_files: 0
  pre_existing_plus_current_status_entries: 32
  git_stage_commit_branch_push_pr_performed: false
phase_00_status: IN_PROGRESS
e3_i_manifest_state: READY
parallel_mode: DISABLED
provider_execution_performed: false
implementation_performed: false
opus_peer_review: PENDING_QUOTA
next_gate: user review of the written E3-I design before implementation planning
```

#### Source reconciliation recorded by the design

The normative E3-I wording at `spec/phases/phase-00-foundation.md:424-427` currently
misidentifies `/settings` plus `Settings.set()` as an in-memory-only `#overrides` mutation.
Pinned OMP source instead shows:

- `config/settings.ts:498-505`: `Settings.set()` updates global settings, marks the
  settings modified, rebuilds them, and queues persistence on the normal writable path.
- `config/settings.ts:518-526`: `Settings.override()` updates the in-memory `#overrides`
  layer and rebuilds without queueing persistence.
- `config/settings.ts:2143-2147`: runtime overrides merge after global, project, and CLI
  config-overlay layers.
- `modes/components/settings-selector.ts:1272-1282`: the settings selector calls the
  persistent `settings.set` path.
- `extensibility/custom-tools/types.ts:85-106`: project custom tools receive optional
  parent `ctx.settings`, which is the correct host-scoped surface for this fixture.

The user approved replacing only the incorrect E3-I `/settings` variant with a disposable
project custom tool that calls exactly
`ctx.settings.override("task.isolation.apply", true)`, records `false -> true`, and calls
neither `Settings.set()` nor any flush/save path. The design explicitly says `/settings`
is not the runtime-only primitive. This checkpoint deliberately does **not** apply that
normative correction yet; it belongs to the implementation plan after written-design
review.

#### Approved evidence shape

The design fixes two parent sessions and nine sequential blocking canary calls:

1. Session A starts with project `apply:false`, performs a child config diagnostic,
   dispatches three control canaries, calls the runtime-override tool once, repeats the
   child diagnostic, and dispatches three post-override canaries.
2. Session B starts from project `apply:false` with a parent CLI overlay `apply:true`,
   performs one child diagnostic, and dispatches three canaries without the override tool.

Both post-overlay child diagnostics must still report project `false`. The three project
control summaries must start `Isolation:`; the three runtime-override and three CLI-overlay
summaries must normalize to `No changes to apply.`. The two disagreements are the decisive
characterization findings.

I1-I4 also require exact call/result pairing, no retries/extras/reordering, nine duration
and token observations, zero canary tool calls (including zero hub calls), unchanged
parent content/Git state, unchanged fixture settings, unchanged live-home metadata, safe
cleanup, sanitized raw history, and explicit separation of `PASS`, `FAIL`, `INVALID_RUN`,
and `BLOCKED_ENVIRONMENT`.

The canary declares `[read]`, while `[read, hub]` is recorded only as a pinned-source fact
from `task/executor.ts:2675-2692`. Zero hub use is a finite runtime observation, not a
sandbox guarantee. Summary discrimination proves the observed behavioral apply branch,
not an atomic or mechanical gate. E3-I cannot replace E3-L or E3-M and cannot enable
parallel mode.

#### Design self-audit and review boundary

The 516-line English design contains 17 numbered sections, no TODO/TBD/FIXME/placeholder
markers, explicit source-versus-runtime authority labels, exact session sequences, strict
oracles, error classifications, safety limitations, planned artifacts, test-first groups,
legal manifest transitions, acceptance criteria, and non-goals. The audit found no
internal contradiction between the two-session topology, three-state matrix, nine-canary
count, or disabled-parallel authority boundary.

No implementation script, test, fixture, raw evidence, interpreted evidence, normative
spec, or manifest row changed in this checkpoint. No provider call was made. No live OMP
configuration, authentication record, or credential was read into an artifact or modified.
No Git integration action occurred. The dirty worktree and all prior user/Codex changes
were preserved.

Opus should independently challenge: (1) the `set` versus `override` correction and line
anchors; (2) whether the custom tool is the narrowest host-scoped runtime mutation surface;
(3) the exact parent/canary event-pairing rules; (4) summary text as behavioral evidence;
(5) the distinction between source-proven `[read, hub]` and zero observed calls; (6) the
snapshot/non-sandbox limitations; (7) classification boundaries; and (8) the continued
non-authority of E3-I. Codex's approved design is not peer closure.

The final SHA-256 of this self-referential changelog is intentionally reported in the
handoff response after this entry is appended. P00-CX-019 pins its predecessor and the
new design artifact so Opus can verify append-only continuity.

### P00-CX-020 — E3-I implementation-plan checkpoint and custom-tool surface correction

```yaml
timestamp: 2026-08-09T09:06:12+07:00
previous_log_hash: 8BC2F52D2E1754CC36B386C3C960B4F726B7CD9D1AFBEEE7DDB9A97612064EA6
scope: E3-I amended design plus implementation plan only
modified:
  docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md:
    before_sha256: 83C0774F4F77F920F5CEE7BB8D8C5E79F5D365F3CF11B0E735A37FB5D8E9B275
    after_sha256: 824DEA5FCE70A7B628D9A6A151FD83A74D2CEF5EC1C5F6D063C6DC2CA36D229F
    after_lines: 556
    after_bytes: 26348
created:
  docs/superpowers/plans/2026-08-09-phase-00-e3i-parent-overlay-canary-plan.md:
    sha256: B226E2094C9420818429B1752C1FB0EAA59D184F035A1A0D3FA6F245B0B85DC2
    lines: 1634
    bytes: 65672
    tasks: 9
    checkbox_steps: 65
unchanged_authority_files:
  spec/phases/phase-00-foundation.md: B35CDB32EE1639401E61EE3F0AFC6542EA98131DBEE223FC554F134AA87E1DBC
  docs/evidence/phase-00/manifest.yml: 00C84F3457CC17974251471F5B88DEFE86AE938E594B79B29B1112BABB4A9BD1
repository:
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  staged_files: 0
  pre_existing_plus_current_status_entries: 32
  git_stage_commit_branch_push_pr_performed: false
phase_00_status: IN_PROGRESS
e3_i_manifest_state: READY
parallel_mode: DISABLED
provider_execution_performed: false
implementation_performed: false
next_gate: user review of the source-audit amendment and written implementation plan
opus_peer_review: PENDING_QUOTA
```

#### Planning audit found and corrected a defect in Codex's approved design

P00-CX-019's original design said the project runtime-override custom tool would be
essential while the canary's effective surface remained exactly `[read, hub]`. A fresh
pinned-source audit during `writing-plans` proved those two statements were not jointly
safe without an additional scope gate:

- `task/structured-subagent.ts:439-440` forwards the parent's preloaded custom-tool paths
  to ordinary subagents.
- `sdk.ts:1980-1990` reloads those custom-tool factories for each child session.
- `sdk.ts:3025-3036` force-includes registered custom and extension tools regardless of a
  normal `toolNames` filter.
- `task/executor.ts:2910-2916` sets an isolated subagent's effective cwd to its worktree.
- `docs/custom-tools.md:114-118` permits a factory to return `CustomTool[]`, including an
  empty list.

Therefore an ungated essential override tool could have appeared in every canary session,
contaminating the very surface E3-I is meant to characterize. This was a Codex design
defect, not an Opus error and not an empirical OMP failure. The two-session architecture,
nine-canary matrix, I1-I4 oracles, summary discrimination, and E3-I non-authority boundary
remain valid; the fixture scope needed correction.

The amended design and plan now require the runner to supply a non-secret
`OMP_PHASE00_E3I_PARENT_CWD` value only in the disposable child-process environment. The
custom-tool factory compares normalized `pi.cwd` to that parent root. It returns the one
essential override tool only for the parent and returns `[]` for the isolated worktree cwd.
The tool's execute path repeats the same equality check and fails closed before touching
settings if scope changed. All nine nested `session_init.tools` records must equal
`[read, hub]`; the override tool's presence in any child is an explicit FAIL. All nine
canary transcripts must still contain zero tool calls.

This correction is materially safer than changing the tool to discoverable. Pinned source
shows discoverability controls presentation, while registered tools remain included; it
would not prove absence from the child registry. The cwd-gated empty factory result prevents
child registration and is runtime-corroborated by the persisted child session-init records.

#### Written plan contents and ordering

The English plan follows `superpowers:writing-plans` and is locked to inline/solo
execution with TDD and verification sub-skills. It contains nine reviewable tasks:

1. Correct only the E3-I `/settings`/`Settings.set` normative error and establish RED/GREEN.
2. Implement strict parent/canary transcript, child-diagnostic, summary, and cost parsing.
3. Implement exact Session A/B sequences plus I1-I4 and outcome classification.
4. Build the cwd-gated fixture and disposable runner test-first.
5. Close cross-shell static/direct-runtime readiness before any provider call.
6. Execute and adjudicate Session A without automatic retry or overwrite.
7. Execute and adjudicate Session B only after selected Session A PASS.
8. Materialize I1-I4/conclusion and make only the legal E3-I terminal manifest transition.
9. Run post-documentation cross-shell closure verification and append the Opus audit ledger.

The plan specifies exact paths, function names/signatures, source anchors, TypeScript
factory code, parent prompts, tool-call sequences, reason codes, process/snapshot/cleanup
boundaries, raw artifact names, YAML mappings, manifest states, test commands, stop
conditions, and changelog requirements. Official-repository commits remain forbidden;
only a local baseline commit inside the verified disposable Git fixture is allowed because
OMP isolation requires a Git parent.

Outcome priority is explicit. Parent or nested-canary auth/quota/connection/overload/model
unavailability is `BLOCKED_ENVIRONMENT`. Wrong/missing/extra/reordered calls, malformed or
missing provenance, timeout, or cleanup uncertainty is `INVALID_RUN`. A complete wrong
summary or divergence, override persistence, contaminated canary surface, any canary tool
call, or measured parent/live mutation is `FAIL`. No FAIL can be retried into PASS; no
INVALID_RUN can be retried without a preserved attempt and regression-backed correction.

#### Plan self-review evidence

The required fresh-eyes review passed:

```yaml
spec_coverage_groups_checked: 15
uncovered_groups: 0
tasks: 9
checkbox_steps: 65
task_step_sequences_contiguous: true
declared_cross_task_interfaces_checked: 25
missing_interfaces: 0
markdown_code_fences: 102
code_fences_balanced: true
forbidden_incomplete_markers: 0
trailing_whitespace_hits: 0
git_diff_check: PASS
staged_files: 0
```

The review also corrected three plan-level issues before this hash was pinned: the known
bash `Wall time:` wrapper is now parsed exactly rather than ambiguously stripped; nested
provider failure is classified before missing-canary provenance; and durable-evidence
tests are ordered RED before I1-I4/conclusion materialization. Task argument shape,
canary acknowledgement, read-only session-init flag, exact bash command/timeout, and empty
override parameters are all validated rather than trusted from parent prose.

#### Mutation and review boundary

No normative spec, manifest row, implementation helper, runner, test, fixture, raw or
interpreted evidence file changed in this checkpoint. No OMP/provider process was launched.
No live configuration, auth record, or credential was read into an artifact or modified.
No Git integration action occurred, and every prior dirty-worktree entry was preserved.

The user approved the original written design before this planning audit. Because the
factory-scope correction is a material safety amendment, both the amended design and the
implementation plan are returned for explicit user review before execution. Opus should
later challenge: (1) whether child custom-tool propagation is read correctly; (2) whether
cwd-gated empty factory return actually prevents registration; (3) whether child
`session_init.tools` is sufficient runtime corroboration; (4) all strict pairing and
classification boundaries; (5) the no-persistence and snapshot claims; and (6) continued
E3-I non-authority. Codex's plan is not peer closure.

The final SHA-256 of this self-referential changelog is intentionally reported in the
handoff response after this entry is appended. P00-CX-020 pins P00-CX-019, the amended
design, and the complete implementation plan.

### P00-CX-021 — E3-I pre-runtime implementation and provider-safe readiness gate

```yaml
timestamp: 2026-08-09T11:33:19+07:00
previous_log_hash: 5879E3C8CA87321848903443033545CE3F9F37519A836FC6DCC7D85D01AF573A
scope: E3-I normative correction, executable evidence surface, disposable fixture/runner, and pre-provider readiness
modified:
  spec/phases/phase-00-foundation.md:
    before_sha256: B35CDB32EE1639401E61EE3F0AFC6542EA98131DBEE223FC554F134AA87E1DBC
    after_sha256: 4E24271942CB3BE2EB60117D1882D818285138465DBFF54DBAF7BD58987FCD75
    after_lines: 1738
    after_bytes: 104813
  docs/superpowers/plans/2026-08-09-phase-00-e3i-parent-overlay-canary-plan.md:
    p00_cx_020_sha256: B226E2094C9420818429B1752C1FB0EAA59D184F035A1A0D3FA6F245B0B85DC2
    post_writing_good_tests_sha256: 6859C31F736DF18758AC24B3BD3DF7DD1F92E8BC2C18570F7E55C78098EF95D4
    after_sha256: 205A9E1F21A2800801A5AD023716FC47129D4AB453BAB3C103317A9F99F7201F
    after_lines: 1631
    after_bytes: 65786
created:
  scripts/lib/phase00-e3i-evidence.ps1:
    sha256: CA0E7ECCFD8DE3C2B511D6E1D596D400A46E4ABE35515EEE4D304A2EF3067247
    lines: 855
    bytes: 31266
  scripts/run-phase00-e3i.ps1:
    sha256: 00B02CF22290FD3BBDE5D1C4652EFC3B38DA6EF617E4BC99882314C82A579F90
    lines: 713
    bytes: 29590
  scripts/tests/phase00-e3i.Tests.ps1:
    sha256: BD70CEEF4B1E4F38DF36013862FC3411AD9E3AADDEE625BB0BC21459425E7D5A
    lines: 1127
    bytes: 48563
  docs/evidence/phase-00/E3-I/fixture/.omp/config.yml:
    sha256: D4E7D8B27E063591CEF8F755F6376354F862792432F01BEAC9CE3ED013A08C5C
  docs/evidence/phase-00/E3-I/fixture/overlay.yml:
    sha256: 5CD533575FEF3D53099B7821DE5524531AC9C34E4B7EB1AE317B7AC89C596176
  docs/evidence/phase-00/E3-I/fixture/.omp/agents/phase00-e3i-canary.md:
    sha256: 6546CF5F6BDCC802B36E42F5C5A29F3E441D0E28C95C70D80A7EC9096BA41012
  docs/evidence/phase-00/E3-I/fixture/.omp/tools/phase00-e3i-runtime-override.ts:
    sha256: C8B95B86AC6585CBB07C0E2BFC81D03F3AC2142BBF1CD9E8332D4CD9F0573234
  docs/evidence/phase-00/E3-I/fixture/prompts/session-a.md:
    sha256: 22F1DFE3E051C42EB9996B58708A361BCC0175C4EF2F03A3570BAE1F5AEEE3C5
  docs/evidence/phase-00/E3-I/fixture/prompts/session-b.md:
    sha256: 913624E1C382F61D85437BE3046FA1F5C748195F2E44AFA085C5D52134BA17A9
unchanged:
  docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md: 824DEA5FCE70A7B628D9A6A151FD83A74D2CEF5EC1C5F6D063C6DC2CA36D229F
  docs/evidence/phase-00/manifest.yml: 00C84F3457CC17974251471F5B88DEFE86AE938E594B79B29B1112BABB4A9BD1
repository:
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  staged_files: 0
  pre_existing_plus_current_status_entries: 33
  git_stage_commit_branch_push_pr_performed: false
runtime_boundary:
  omp_version: omp/17.2.10
  provider_execution_performed: false
  live_home_file_count: 14
  live_home_metadata_sha256: 3F0007BA98DC404BDEE73478746AB5DA2E03C79195C789E84C0177A4F10CA5D3
  remaining_omp_phase00_e3i_temp_roots: 0
  windows_powershell_execution_policy_after_tests: Restricted
phase_00_status: IN_PROGRESS
e3_i_manifest_state: READY
parallel_mode: DISABLED
opus_peer_review: PENDING_QUOTA
next_gate: move only E3-I to RUNNING, then execute Session A attempt 1
```

#### Normative correction and pinned-source evidence

Only the E3-I runtime-override paragraph at the current
`spec/phases/phase-00-foundation.md:421-439` was intentionally changed in this entry. It
now requires a disposable, parent-cwd-scoped custom tool to call
`ctx.settings.override("task.isolation.apply", true)` exactly once, record the immediate
before/after values, call no `Settings.set` or flush/save path, and return no tools for an
isolated child cwd. It explicitly removes the incorrect claim that normal `/settings` plus
`Settings.set()` is an in-memory-only override.

The read-only audit used upstream HEAD
`3a8591a8af5b6d200088d12ca75a5517cb064fa8` and verified:

| Pinned source | SHA-256 | Verified contract |
| --- | --- | --- |
| `config/settings.ts:498-505,518-526,2143-2147` | `B2CD4FB72159A200FB32ECB0F7ED5983573C16942425D5929034872631524F49` | `set` writes global and queues save; `override` writes `#overrides` without queue-save; override merges last |
| `task/structured-subagent.ts:315-317,439-440` | `7404F4619262706E75ACB8B5F06F96B089A409F6CB5B58DE2F700D5645CC9AB7` | task dispatch reads live apply; custom-tool paths are forwarded |
| `task/executor.ts:2675-2692,2910-2916` | `8DC3C9BD3593BAA54FEA4D4966808815598AB613A46D8D2FA541116FEA09248E` | ordinary read agents gain `hub`; isolated worktree is the child cwd |
| `sdk.ts:1980-1990,3025-3036` | `EEE5412D1847E6BC274DF4E29A25188C8831A27957BFCFCC93EBBD0DFD94D3F4` | child sessions reload factories; registered custom tools are force-included for ordinary sessions |

The fixture custom-tool audit found exactly one `.override(` and zero `.set(`, `.flush`,
`.save`, `pi.exec`, or filesystem-write call. Its parameter schema is exactly
`pi.zod.object({})`; the `setting` and `value` words in its fixed result attestation are not
general input parameters.

#### Executable contracts implemented

The evidence helper now fails closed on duplicate/unpaired/reversed tool events, ambiguous
or duplicate merge-summary envelopes, malformed child diagnostic wrappers, non-unit task
results, missing cost observations, contaminated child tool registries, parent sequence
deviation, malformed override evidence, and missing nested provenance. It separates
`PASS`, semantic `FAIL`, `INVALID_RUN`, and attributable `BLOCKED_ENVIRONMENT`; provider
overload received an E3-I-specific extension because the shared closed-slice classifier
did not recognize `overloaded/temporarily unavailable`. I1-I4 are conjunctions, and no
production helper object or code path contains `ALLOW_PARALLEL`.

The runner creates one verified root beneath the OS temp directory, with sibling agent,
project, and session directories; copies the reviewed fixture and non-secret model catalog;
creates only a local disposable Git baseline commit; takes content/Git/fixture/live-home
snapshots; captures stdout/stderr asynchronously; kills only the known child process tree
on timeout; sanitizes before persistence; strictly copies one JSONL per expected canary;
and rechecks the resolved path immediately before recursive cleanup. No process-global
environment value is modified. Session A receives the parent-cwd scope value. Session B
actively shadows any inherited `OMP_PHASE00_E3I_PARENT_CWD` with an empty value, so the
factory returns `[]` even if the caller happened to define that variable. This closes a
leak risk not explicit in P00-CX-020.

One plan-interface clarification was necessary: repository snapshot comparison accepts
the already-observed live-home and cleanup booleans so it can return the exact six-field I4
boundary object. A thirteenth public runner helper,
`Get-Phase00E3IProcessEnvironment`, was added to make the Session A/B environment
difference directly testable rather than hidden inside the provider lifecycle.

#### TDD evidence actually observed

No transient total below is reconstructed; each was captured from Pester output:

| RED/checkpoint | Passed | Failed | Expected failure evidence |
| --- | ---: | ---: | --- |
| Initial summary helper | 0 | 1 | E3-I helper absent |
| Strict pairing/diagnostic RED | 1 | 5 | duplicate summary accepted; transcript functions absent |
| First primitive implementation check | 5 | 1 | Pester 3.4 `Should Throw` pipeline anomaly; direct six-case probe proved all six production throws; assertion was rewritten as explicit try/catch |
| Task/canary extractor RED | 7 | 3 | task sample and canary session functions absent |
| Session/I1-I4 RED | 10 | 9 | session, override, and case adjudicators absent |
| Overload-classifier RED | 19 | 1 | provider overload incorrectly classified `INVALID_RUN` |
| Fixture/runner RED | 20 | 5 | six fixture files and runner absent |
| Session B inherited-environment RED | 26 | 2 | explicit environment builder absent |

The installed Pester is 3.4.0 in both shells, so `-Output Detailed` was rejected before
test execution and all real runs used compatible `-Script ... -PassThru`. Windows
PowerShell 5.1 has machine-effective `Restricted`; tests used only the child-process-local
`-ExecutionPolicy Bypass` launch flag. The machine policy remained `Restricted` afterward.

Final focused E3-I readiness is 30 passed, 0 failed in both PowerShell 7 and Windows
PowerShell 5.1. Direct behavior tests loaded the actual TypeScript file with Node 24 type
stripping and observed: parent tool `phase00_e3i_override_apply_true`, child tool count 0,
and override call count 1 with `false -> true`, `calledSet:false`,
`calledFlushOrSave:false`. A real installed-OMP command against a fresh relocated fixture
classified `task.isolation.apply` as observed boolean `false`. Neither test contacted a
model provider.

The complete pre-runtime gate passed identically in both shells:

```yaml
phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
phase00_e3i: {passed: 30, failed: 0, skipped: 0}
validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
git_diff_check: PASS
staged_files: 0
```

#### Review and authority boundary

P00-CX-021 is pre-runtime only. No provider/model call, Session A/B evidence call, manifest
transition, selected attempt, interpreted I1-I4 artifact, phase closure, Git integration,
live-home write, or parallel authorization occurred. The manifest remains byte-identical
with E3-I `READY`; the approved design remains byte-identical; Phase 00 remains
`IN_PROGRESS`; parallel mode remains `DISABLED`. All pre-existing dirty-worktree entries
were preserved.

Opus should later challenge: the normative set/override correction; child custom-tool
propagation and factory gating; Session B empty-variable shadow; strict pairing and outcome
precedence; summary discrimination; snapshot coverage; process-tree cleanup; raw
sanitization; direct TypeScript/config controls; and the fact that E3-I still grants no
authority. Codex alone has not peer-closed this entry.

The final SHA-256 of this self-referential changelog is intentionally reported after the
append. P00-CX-021 pins the exact pre-runtime state; later provider attempts must be
recorded only in append-only P00-CX-022 and must never rewrite this checkpoint.

### P00-CX-022 — E3-I Attempts 1-2 preservation, methodology correction, and Attempt 3 gate

```yaml
timestamp: 2026-08-09T12:45:15+07:00
previous_log_hash: 02E1D84341BF4EDE13BA3F5CAAD5581F44CBB110A975B9E4E822941529FD0C75
scope: E3-I manifest start, two non-selected Session A attempts, complete adjudication, canary-contract correction, and clean pre-Attempt-3 gate
authority:
  codex_solo_implementation_approved_by_user: true
  opus_peer_review: PENDING_QUOTA
  joint_closure_claimed: false
  parallel_mode: DISABLED
  git_stage_commit_branch_push_pr_performed: false
manifest_transition:
  file: docs/evidence/phase-00/manifest.yml
  before_state: READY
  after_state: RUNNING
  after_sha256: E31F0CCB5EBCA7929A0341FC38B4EC4F5477AC2638764107323601AB440CAFE6
provider_execution:
  session_a_attempt_1_launches: 1
  session_a_attempt_2_launches: 1
  session_a_attempt_3_launches: 0
  session_b_launches: 0
  codex_automatic_experiment_retries: 0
  note: Attempt 2 contains one nested runtime auto-retry recovery; that contaminates the sample and is not counted as a Codex-authorized experiment retry.
selected_attempt: null
phase_00_status: IN_PROGRESS
```

#### Attempt 1 — preserved, not selected

Attempt 1 executed the nine expected parent tool names and completed six task calls, but it
did not execute the reviewed diagnostic or runtime-override primitives correctly. The nested
PowerShell diagnostic was corrupted by outer-shell variable expansion, the custom tool used
an unavailable `ctx.settings` bridge, and live-home metadata changed concurrently without a
disposable-root identity. The immutable run record originally reported semantic `FAIL /
E3I_LIVE_HOME_MUTATION`; post-audit adjudication is `INVALID_RUN` with:

1. `E3I_EVENT_PAIRING_INVALID`
2. `E3I_OVERRIDE_EXECUTION_ERROR`
3. `E3I_LIVE_HOME_CONCURRENT_ACTIVITY`

The complete English record, including all nine raw artifact hashes, source hashes, changed
live-home paths, runtime drift, regression sequence, and non-claims, is:

```yaml
adjudication: docs/evidence/phase-00/E3-I/raw/session-a.attempt-001.adjudication.json
sha256: B8685E9B052B6B4895E83D523BC6A8BDAE44AE2ED959790A28630DEE3D0375B1
selected: false
session_b_launched: false
```

The correction replaced the nested shell expression with the direct command
`omp config get task.isolation.apply --json`, moved the runtime mutation to the package
namespace bridge `pi.pi.settings.override`, added typed precedence for harness/provenance
failures, and explicitly selected and copy-hashed the preserved 17.2.10 runtime for every
later run. Attempt 1 raw bytes were not rewritten.

#### Attempt 2 — preserved, not selected

Attempt 2 ran once with the preserved OMP 17.2.10 executable, whose source and disposable
copy both hashed to
`1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`.
The parent exited zero in 200,987 ms. It produced the exact Session A tool sequence,
observed both direct config diagnostics as boolean `false`, and attested the parent-only
runtime override as `false -> true` through `pi.pi.settings.override`, with no `set`, flush,
or save path. All six boundary predicates were true: parent content, HEAD, status, fixture
hashes, live home, and cleanup remained clean.

The original run analysis incorrectly returned `BLOCKED_ENVIRONMENT /
P00-RUNTIME-PROVIDER-ENVIRONMENT` after the real empty override argument `{}` decoded to an
empty `PSCustomObject`; StrictMode then made `$Object.PSObject.Properties.Name` throw. The
runner compounded that local parser defect by scanning the entire transcript, finding an
unrelated historical `server_is_overloaded` string inside a nested canary, and promoting the
exception to an environment block.

The deeper audit found three additional sample-integrity defects:

- TaskTool always creates the child with `requireYieldTool:true`; the pinned source adds
  `hub` to an ordinary explicit child list and force-includes `yield`. Therefore the reviewed
  `[read, hub]`/zero-call canary contract was impossible. The controlled minimum is
  `[read, yield, hub]`, and completion requires one terminal `yield`.
- Relocating only `PI_CODING_AGENT_DIR` left external user-profile discovery active. Every
  child also received `mcp__context_query_docs` and `mcp__context_resolve_library_id`.
- `e3i-project-3` encountered `server_is_overloaded` and recovered through a nested
  auto-retry. A recovered sample is not clean or retry-free.

Corrected Attempt 2 adjudication is `INVALID_RUN`, non-selectable, for:

1. `E3I_NESTED_PROVIDER_RECOVERY`
2. `E3I_CANARY_PROTOCOL_CONTRACT_INVALID`
3. `E3I_AMBIENT_CAPABILITY_DISCOVERY`
4. `E3I_CAPTURE_CLASSIFIER_INVALID`

The machine helper, after all corrections, independently returns `INVALID_RUN /
E3I_NESTED_PROVIDER_RECOVERY` and identifies `e3i-project-3`. The broader four-reason list
also records defects in the reviewed methodology that existed when the bytes were produced.
The complete compact review packet includes the exact task rows, protocol sequence, override
attestation, five harness defects, six pinned-source hash records, every regression, all TDD
checkpoints, all nine raw hashes, and explicit non-claims:

```yaml
adjudication: docs/evidence/phase-00/E3-I/raw/session-a.attempt-002.adjudication.json
sha256: DF8F3EFD53836B2AB0AD363B2E0C68E02B9BFD779297F548CC10A170AB0CA902
selected: false
session_b_launched: false
raw_artifacts:
  session-a-attempt-002.stdout.jsonl: ABA4E5BA691A5FA872674E427813B01212533138CF507DB5FDB80EBA4049674A
  session-a-attempt-002.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  session-a-attempt-002.run.json: A4290981871FF00DE7C3FFDAB043D6A768EA702B6DA4F62FE2B037F4912007A2
  session-a-attempt-002.canary.e3i-project-1.jsonl: 205C374B3D9C75E831EA95AA9CB0850FF665F026F2EF9C402203BA4588137D92
  session-a-attempt-002.canary.e3i-project-2.jsonl: C0CB53998F4C8172CE62DC32D8735F1305D2340B66654459F62F27B912E10707
  session-a-attempt-002.canary.e3i-project-3.jsonl: AD4545FFD79AB50FBB463218F91FB4637C1A7B94494A5F8F1B1516D6DCE2A341
  session-a-attempt-002.canary.e3i-runtime-1.jsonl: 3B9006339F0BCB96A113E1A122335C1F8CDE019181AFC7ED38776BDF260A8E24
  session-a-attempt-002.canary.e3i-runtime-2.jsonl: D651EDE773277BE326EC0C7BB8F73CF148B830B890119175C7E88436C64A9A29
  session-a-attempt-002.canary.e3i-runtime-3.jsonl: 2CB7A176651B594F2C3323EF31258CE7FAE552718A64EFE6F07614B7EB80DC26
```

Attempt 2 raw bytes and its original mistaken run analysis were preserved exactly. The
sidecar is additive and the Attempt 2 tests re-hash every referenced artifact.

#### Executable corrections after Attempt 2

`scripts/lib/phase00-e3i-evidence.ps1` now:

- enumerates empty `PSCustomObject` properties safely under StrictMode;
- parses only the exact acknowledgement object, never prose or widened output;
- requires the exact `[read, yield, hub]` surface;
- requires exactly one terminal `yield` with
  `result.data.acknowledgement: PHASE00_E3I_CANARY_OK`;
- counts every other child call as forbidden;
- unions message and execution-start call records and deduplicates only a shared non-empty
  tool-call ID, preventing mixed-schema events from hiding an extra call;
- invalidates terminal and recovered nested provider failures before semantic analysis.

`scripts/run-phase00-e3i.ps1` now:

- classifies every local capture/provenance exception as `INVALID_RUN` from typed local
  evidence and never scans unrelated transcript text for environment words;
- creates a disposable sibling user-profile directory;
- injects `USERPROFILE` only into the captured child process alongside the relocated agent
  directory and parent-cwd scope;
- persists only `<DISPOSABLE_USER_PROFILE>` in the run record.

The fixture agent and both parent prompts now require the exact terminal-yield acknowledgement
and prohibit every other tool. The source-proven controlled surface and user-profile discovery
boundary were reconciled across the Phase 00 contract, the cross-cutting isolation contract,
the approved design, and every executable plan step. No remaining live E3-I text expects
`[read, hub]`, zero calls, or a text-only acknowledgement.

One existing E3-A/E3-H durable-manifest test was corrected after it legitimately failed when
E3-I advanced from `READY` to `RUNNING`. It still requires E3-B/E3-C/E3-L `READY`, E3-A/E3-H
`PASS`, and parallel disabled, but permits E3-I's dependency-safe post-eligibility states:
`READY`, `RUNNING`, `PASS`, `FAIL`, or `BLOCKED_ENVIRONMENT`. This is a test-lifetime fix;
no E3-A/E3-H production evidence was changed.

#### Exact corrected file state before Attempt 3

```yaml
modified_or_extended:
  scripts/lib/phase00-e3i-evidence.ps1:
    sha256: F74F0F8348931704D74244B6639C312DBA2D079106945ED4C051FC40CB31ED33
    lines: 984
    bytes: 36472
  scripts/run-phase00-e3i.ps1:
    sha256: 465EC54EBBCB5FFBCE911009D7094C4BB02B7F2FD2C1FB6BBF2248D20D848D0C
    lines: 851
    bytes: 34837
  scripts/tests/phase00-e3i.Tests.ps1:
    sha256: 9F786B002FEE4FB6AE2FFA0661C2D383ED951B1577314EE27A4DEA3A7E14ADEC
    lines: 1486
    bytes: 64753
  scripts/tests/phase00-e3a-e3h.Tests.ps1:
    sha256: 9702B3D7E9CD322F0487AEAFAAFAE48EC8009A3FE1F92B5934ADFE5A8650117D
    lines: 782
    bytes: 42742
  docs/evidence/phase-00/E3-I/fixture/.omp/agents/phase00-e3i-canary.md:
    sha256: 227B885E6EE7B676571C4AF122170BFA9D6B979A77C30D45881F05F3337C6659
  docs/evidence/phase-00/E3-I/fixture/.omp/tools/phase00-e3i-runtime-override.ts:
    sha256: C538B7C2E43450C170D566793582CB6E9C322C134DC3AEA2CE9C01B1524445C2
  docs/evidence/phase-00/E3-I/fixture/prompts/session-a.md:
    sha256: F464AC463A2C17B8FF7C0C8E229CFE73E5CED886617397D244FCD15110F86ABE
  docs/evidence/phase-00/E3-I/fixture/prompts/session-b.md:
    sha256: 881A27340B4958D089D1C868B9741408B110BA4C558E8BA6232B7280397FA97E
  spec/phases/phase-00-foundation.md:
    sha256: 9F7B7230C9A01754093BE71C51E047FC25D7EFEC3895A25D2712B3E5A97CD35A
  spec/08-isolation-and-concurrency.md:
    sha256: 5F55E1CFD554F13098355BCF2CCBC31F6B75390F129C7E01AB7696B46B541FCF
  docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md:
    sha256: 8DAD5B3AB4841F21ECBB996C1496A8C75FA0D4F755A2C7A6607D272791C4F1F1
  docs/superpowers/plans/2026-08-09-phase-00-e3i-parent-overlay-canary-plan.md:
    sha256: 3A84AF304778967408967CA19EDF7E631E412B64F1BEF1075275B435D578C914
```

#### TDD and full pre-Attempt-3 verification

Observed E3-I correction cycles, never reconstructed:

| Cycle | Passed | Failed | Expected evidence |
| --- | ---: | ---: | --- |
| Empty-object + capture classifier RED | 33 | 2 | empty PSCustomObject and transcript-wide promotion failed |
| Empty-object + capture classifier GREEN | 35 | 0 | both minimal corrections held |
| Corrected canary protocol RED | 24 | 12 | old parser/fixture contradicted terminal yield and profile isolation |
| Protocol intermediate 1 | 33 | 3 | three remaining strict failures |
| Protocol intermediate 2 | 35 | 1 | final protocol mismatch isolated |
| Corrected canary protocol GREEN | 36 | 0 | exact surface/yield contract held |
| Recovered provider error RED | 36 | 1 | recovered nested overload was accepted |
| Recovered provider error GREEN | 37 | 0 | recovered overload invalidated |
| Mixed event parser RED | 37 | 1 | execution-start-only `hub` was hidden |
| Mixed event parser + user-home behavior GREEN | 38 | 0 | dedup and `os.homedir()` proof held |
| Attempt 2 durable sidecar RED | 38 | 1 | adjudication file absent |
| Attempt 2 durable sidecar GREEN | 39 | 0 | all nine raw hashes verified |

The first full gate correctly failed for two environmental/lifecycle assumptions: the live
installed OMP had advanced to 17.2.12, while an older E3-A direct test expected 17.2.10; and
the E3-A durable test still expected E3-I `READY`. No provider was called. The manifest test
was corrected as described above. Both final gates prepended an ephemeral, hash-verified copy
of the preserved 17.2.10 executable, then removed the verified temporary root.

Final clean results were identical in PowerShell 7 and Windows PowerShell 5.1:

```yaml
phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
phase00_e3i: {passed: 39, failed: 0, skipped: 0}
validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
pinned_omp_source_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
attempt_3_artifacts_present: 0
session_b_artifacts_present: 0
remaining_omp_phase00_e3i_temp_roots: 0
staged_files: 0
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
upstream_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
upstream_status_entries: 0
parallel_mode: DISABLED
```

The process-local model catalog still names
`omniroute/codex/gpt-5.6-sol-high`. Attempt 3 is authorized only as one new Session A launch
with explicit OMP 17.2.10 selection. Session B remains forbidden until a complete, clean,
retry-free Session A PASS is independently re-adjudicated.

Security note for later human review: a configured local gateway credential value appeared
transiently in non-durable diagnostic tool output during environment investigation. It was
not copied into repository evidence or this changelog. Rotation is recommended after Phase 00
without interrupting the approved controlled run.

P00-CX-022 is a pre-Attempt-3 checkpoint. It does not select Attempt 1 or 2, does not produce
I1-I4 evidence, does not close E3-I or Phase 00, and grants no parallel authority. Opus should
challenge the four-part Attempt 2 invalidation, terminal-yield source anchors, profile-isolation
boundary, recovered-error precedence, sidecar accuracy, the E3-A test-lifetime correction, and
both-shell gate evidence when quota returns.

### P00-CX-023 — E3-I Session A Attempt 3 provider-recovery stop

```yaml
timestamp: 2026-08-09T12:56:46+07:00
previous_log_hash: 11F7D732737CF158E546EFAF2C57731698683A61853BDD815EB34030BBCD94B1
scope: exactly one post-gate Session A Attempt 3 launch, fail-closed provider-recovery adjudication, durable preservation, and execution-batch stop
provider_execution:
  session_a_attempt_3_launches: 1
  total_session_a_launches_across_attempts_1_to_3: 3
  session_a_attempt_4_launches: 0
  session_b_launches: 0
  codex_automatic_experiment_retries: 0
selected_attempt: null
e3_i_manifest_state: RUNNING
parallel_mode: DISABLED
opus_peer_review: PENDING_QUOTA
```

Attempt 3 was launched once with the explicitly selected preserved OMP 17.2.10 source and
`omniroute/codex/gpt-5.6-sol-high`. The runner copied the executable under the disposable root,
verified source/copy hash equality at
`1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`,
relocated both `PI_CODING_AGENT_DIR` and `USERPROFILE`, and preserved only redacted process
environment paths. The parent exited zero without timeout after 194,469 ms.

The corrected experiment contract behaved as designed:

- exact parent sequence:
  `bash, task, task, task, phase00_e3i_override_apply_true, bash, task, task, task`;
- project and post-override direct diagnostics both observed boolean `false` from project
  config, proving the runtime override did not rewrite the file-backed observation;
- the parent-only override attested `false -> true` through `pi.pi.settings.override`, with
  `calledSet:false`, `calledFlushOrSave:false`, and `scope:parent-only`;
- project samples 1-3 all took `APPLY_FALSE_CAPTURE_ONLY` and retained disposable patch
  artifacts without applying them;
- runtime samples 1-3 all took `APPLY_TRUE_NO_DIFF` with `No changes to apply.`;
- all six task rows exited zero, were not aborted, had positive duration/tokens, resolved the
  expected model, and returned the exact acknowledgement object;
- all six child `session_init.tools` arrays were exactly `[read, yield, hub]`;
- every child called exactly one conforming terminal `yield`, zero forbidden tools, and never
  exposed the override tool;
- no ambient MCP/custom tool survived the disposable user-profile boundary;
- parent content, HEAD, status, fixture hashes, live home, and cleanup all remained unchanged
  or successful.

Despite those conforming observations, `e3i-project-2` emitted a non-terminal
`server_is_overloaded` provider error and OMP marked its internal auto-retry as recovered on
attempt 1. The pre-existing regression correctly classified the complete experiment as:

```yaml
status: INVALID_RUN
reasons: [E3I_NESTED_PROVIDER_RECOVERY]
canary_id: e3i-project-2
selection_eligible: false
semantic_fail: false
```

The clean-looking branch split is explicitly non-reusable: no Attempt 3 observation may be
combined with another attempt, no I1-I4 PASS artifact may be materialized, and Session B may
not start. No new harness defect was found and no implementation correction was justified.
The execution batch stopped without Attempt 4.

The complete compact English adjudication records every sample, controlled surface, provider
failure, boundary, run decision, and non-claim:

```yaml
adjudication: docs/evidence/phase-00/E3-I/raw/session-a.attempt-003.adjudication.json
sha256: 56F339736EFA5F257837475C2F7267632D8F792B2B526EE5645B2919409F2C5F
raw_artifacts:
  session-a-attempt-003.stdout.jsonl: 013AF2B02992AD693648AEF3989005BFFFB7A8DA946F3A15F93EF2E8ED1B194B
  session-a-attempt-003.stderr.txt: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  session-a-attempt-003.run.json: 3C96C4D73A542FDF84C1E2A0D47B529DD2F013B9857DF389457641868325B3E4
  session-a-attempt-003.canary.e3i-project-1.jsonl: 1F3562F2FE46F210C688BA901C4CB131461F920B9507BF358DB492EEF77D65F3
  session-a-attempt-003.canary.e3i-project-2.jsonl: 9FBDB9744B51A35AFAD045C0825019EA171A79F7C7207322736AD5B5991C1DC2
  session-a-attempt-003.canary.e3i-project-3.jsonl: 7165DFF06584EF036D50B9B314499BF01B88DBB2CED2A53493800770E47A0C57
  session-a-attempt-003.canary.e3i-runtime-1.jsonl: 2D17291659D378360E67C8886D75281C662905F5D5DAC0A8FD809A7465B00C1B
  session-a-attempt-003.canary.e3i-runtime-2.jsonl: 69AEAC25C55D297BBA064CBE966B168525AC156F74A5D4D92A461977653BE959
  session-a-attempt-003.canary.e3i-runtime-3.jsonl: 5A16E8FB40464CC43571086DB32B296683C145C92ACCBF29711A42746A1F7F62
```

A durable-evidence test was added before the sidecar:

```yaml
attempt_3_sidecar_red: {passed: 39, failed: 1, expected_failure: sidecar absent}
attempt_3_sidecar_green_pwsh: {passed: 40, failed: 0}
attempt_3_sidecar_green_windows_powershell_5_1: {passed: 40, failed: 0}
validator_after_preservation: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
scripts/tests/phase00-e3i.Tests.ps1_sha256: F20C847F74178C190C23D42B4160FFDA53BFE6C446074C84A544F832A0D097CB
fixture_agent_sha256: 227B885E6EE7B676571C4AF122170BFA9D6B979A77C30D45881F05F3337C6659
session_b_artifacts_present: 0
remaining_omp_phase00_e3i_temp_roots: 0
staged_files: 0
git_integration_performed: false
```

The design status and execution-plan amendment were updated after preservation so the next
reader cannot mistake Attempt 3 for pending work:

```yaml
docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md_sha256: 6E7826CE586317D51994D8691F524FD10B0284047B3B44DEE548773EF511E3D2
docs/superpowers/plans/2026-08-09-phase-00-e3i-parent-overlay-canary-plan.md_sha256: 4E448F46785CD0F662E525EDC2D0BD0DA1D87C187289F2CE39758AD640667219
recorded_status: Attempts 1-3 INVALID_RUN; Session B and Attempt 4 not launched; execution batch stopped
```

P00-CX-023 is a terminal checkpoint for this execution batch, not E3-I closure. A numbered
Attempt 4 would require a fresh external-state check, a fresh provider-safe gate, and renewed
user authorization. Opus should later test whether rejecting a recovered provider error is
too strict; Codex's current position is that it is necessary because E3-I explicitly requires
one complete retry-free sample and forbids cross-attempt evidence composition.

### P00-CX-024 — E3-I Attempt 4 terminal environment block and fail-closed materialization

```yaml
timestamp: 2026-08-09T13:13:37+07:00
previous_log_hash: 738A91B718EB12AE6F4163DAA80A9BE92A4E648A89195BE4135760A2BBCDF1CD
scope: renewed Attempt 4 gate, exactly one Session A launch, terminal provider-overload adjudication, blocked evidence materialization, and full closure verification
authority:
  codex_solo_implementation_approved_by_user: true
  renewed_attempt_4_authorization: true
  opus_peer_review: PENDING_QUOTA
  joint_codex_opus_closure_claimed: false
  git_stage_commit_branch_push_pr_performed: false
provider_execution:
  session_a_attempt_4_launches: 1
  total_session_a_launches_across_attempts_1_to_4: 4
  codex_automatic_experiment_retries: 0
  session_b_launches: 0
  attempt_5_launches: 0
selected_attempt: null
terminal_status: BLOCKED_ENVIRONMENT
terminal_reason: P00-RUNTIME-PROVIDER-OVERLOAD
semantic_fail: false
phase_00_status: IN_PROGRESS
parallel_mode: DISABLED
```

#### Renewed external-state and launch gate

The user explicitly authorized one new Attempt 4 after P00-CX-023. Before launch, Codex
rechecked the local OmniRoute gateway, confirmed that its current model catalog was reachable
and still listed `omniroute/codex/gpt-5.6-sol-high` among 183 entries, and observed more than
seven minutes since Attempt 3. No credential value was copied into durable evidence.

The repository and runtime prerequisites were exact:

```yaml
repository_branch: main
repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
staged_files: 0
upstream_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
upstream_status_entries: 0
pinned_omp_source: C:/Users/MrThien/AppData/Local/omp/omp.exe.1786250147823.24932.bak
pinned_omp_source_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
attempt_4_artifacts_present_before_launch: 0
session_b_artifacts_present_before_launch: 0
remaining_omp_phase00_e3i_temp_roots_before_launch: 0
parallel_mode: DISABLED
```

The complete provider-safe gate passed identically in PowerShell 7 and Windows PowerShell
5.1 before any provider experiment call:

```yaml
phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
phase00_e3i: {passed: 40, failed: 0, skipped: 0}
validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
```

Exactly one provider experiment was then launched with the reviewed runner, Session A,
attempt number, model, and explicit preserved OMP source:

```powershell
pwsh -NoProfile -File .\scripts\run-phase00-e3i.ps1 -Session A -Model omniroute/codex/gpt-5.6-sol-high -Attempt 4 -OmpExecutable 'C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak'
```

The runner copied and re-hashed the executable under its verified disposable root, prepended
that copy for nested `omp` resolution, relocated `PI_CODING_AGENT_DIR` and `USERPROFILE`, and
persisted only redacted process-environment placeholders. The copied executable hash exactly
equaled the source hash above. The parent process exited zero without runner timeout after
177,102 ms; that process exit does not override the terminal model-error evidence.

#### Attempt 4 observations and terminal classification

The parent completed the full reviewed nine-call Session A protocol in exact order:

```text
bash, task, task, task, phase00_e3i_override_apply_true, bash, task, task, task
```

Both direct project-config diagnostics parsed the exact key as boolean `false`. Between them,
the parent-only tool attested:

```yaml
probe: phase00-e3i-runtime-override-v1
setting: task.isolation.apply
before: false
operation: pi.pi.settings.override
requested: true
after: true
calledSet: false
calledFlushOrSave: false
scope: parent-only
```

All six TaskTool samples exited zero, were not aborted, made one request, returned the exact
`PHASE00_E3I_CANARY_OK` acknowledgement, and retained positive duration/token observations:

| Sample | Exact branch | Duration ms | Tokens | Requests |
| --- | --- | ---: | ---: | ---: |
| `e3i-project-1` | `APPLY_FALSE_CAPTURE_ONLY` | 5,797 | 6,130 | 1 |
| `e3i-project-2` | `APPLY_FALSE_CAPTURE_ONLY` | 13,629 | 6,178 | 1 |
| `e3i-project-3` | `APPLY_FALSE_CAPTURE_ONLY` | 5,448 | 6,191 | 1 |
| `e3i-runtime-1` | `APPLY_TRUE_NO_DIFF` | 10,073 | 3,672 | 1 |
| `e3i-runtime-2` | `APPLY_TRUE_NO_DIFF` | 6,027 | 6,239 | 1 |
| `e3i-runtime-3` | `APPLY_TRUE_NO_DIFF` | 6,307 | 6,264 | 1 |

Each of the six isolated canaries exposed exactly `[read, yield, hub]`, called exactly one
conforming terminal `yield`, called zero forbidden tools, never exposed the parent override
tool, and contained no ambient MCP/custom capability. There was no nested provider failure.
All six boundary predicates were true: parent content, HEAD, and status were unchanged;
fixture hashes were unchanged; live-home metadata was unchanged; cleanup succeeded.

After the ninth tool result, the parent emitted terminal model-error events for provider
`omniroute`, model `codex/gpt-5.6-sol-high`, error code `server_is_overloaded`, and message
`Our servers are currently overloaded. Please try again later.` Raw lines 591-594 contain the
error completion and an `auto_retry_start` marker for attempt 1, but no recovery, superseding
parent message, or required final assistant completion follows. The unchanged provider-first
decision table therefore classifies the whole attempt:

```yaml
status: BLOCKED_ENVIRONMENT
reason: P00-RUNTIME-PROVIDER-OVERLOAD
failure_scope: parent-terminal
selection_eligible: false
semantic_fail: false
```

The auto-retry marker is provider/runtime telemetry, not a Codex-authorized experiment retry.
It did not recover and does not create another numbered run. Otherwise conforming partial
observations have no contract power, cannot be combined across attempts, and cannot authorize
Session B or I1-I4 PASS materialization.

#### Immutable Attempt 4 raw ledger

All nine newly created runner artifacts remain byte-preserved and are hash-linked by the
adjudication sidecar:

```yaml
session-a-attempt-004.stdout.jsonl:
  sha256: 52FE23F8217A15FE97120AEF5B8EC3D1C57539912A8AFFB932731BA8E668CF58
  lines: 612
  bytes: 219966
session-a-attempt-004.stderr.txt:
  sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
  lines: 0
  bytes: 0
session-a-attempt-004.run.json:
  sha256: 311324F650C20F0B2511FDC6E11F8EA6FB98200DFF6CE7C2DE70A8413FCAD78C
  lines: 118
  bytes: 3911
session-a-attempt-004.canary.e3i-project-1.jsonl:
  sha256: 8CBA907D49983A132CF896AA81CD63428D8F11AD620816EF4FCF606C1D729377
  lines: 10
  bytes: 18017
session-a-attempt-004.canary.e3i-project-2.jsonl:
  sha256: 915E4B624C9D7E6AC8DB9164076CAAF62EC265CA8D6A2FAEE12178C51C80BF16
  lines: 10
  bytes: 18204
session-a-attempt-004.canary.e3i-project-3.jsonl:
  sha256: 109AA93BD753565B0432AB27C4F6BC900C6B78F50E146FD7168103E372F59362
  lines: 10
  bytes: 18202
session-a-attempt-004.canary.e3i-runtime-1.jsonl:
  sha256: 1F53ADE4CEBB96DA9B9E3AFC1EC1065AA58F3C3CD4B43B5015936618303658C8
  lines: 10
  bytes: 18439
session-a-attempt-004.canary.e3i-runtime-2.jsonl:
  sha256: 415FD739379473A2D5E6A117B4DF6F38D6F2F7BB040C1C7CEA5D6A77B608FC1F
  lines: 10
  bytes: 18333
session-a-attempt-004.canary.e3i-runtime-3.jsonl:
  sha256: D04FF975AB28E7CA961AD58BF336C23849592E1CDE3C41A9173F0071C728FC4E
  lines: 10
  bytes: 18410
```

#### Test-first terminal materialization and exact mutations

Before writing terminal interpretation, two focused tests were added: one requires the
Attempt 4 sidecar to re-hash all nine raw files and preserve the exact blocked state; the
other requires terminal E3-I `BLOCKED_ENVIRONMENT`, no I1-I4 files, exact manifest artifacts
and decision, and disabled parallel mode. The deliberate RED result was 40 passed / 2 failed
because the sidecar and conclusion did not yet exist. No harness correction was required.

The following complete terminal artifacts were then created:

```yaml
docs/evidence/phase-00/E3-I/raw/session-a.attempt-004.adjudication.json:
  before: ABSENT
  after_sha256: 5B0C4B594C406A5B030013AA9E9EEA2C24F347D6D68BA3D90D9241F0919D84B9
  lines: 245
  bytes: 8018
  purpose: complete English attempt adjudication, raw hashes, observations, boundary results, and non-claims
docs/evidence/phase-00/E3-I/conclusion.yml:
  before: ABSENT
  after_sha256: 4CBBDCFDDBC4991D5D4BDA0E76F44FBC2557FB3C96E7A4DB7732B866482C82E5
  lines: 42
  bytes: 1901
  purpose: terminal blocked conclusion and Attempts 1-4 history without partial case claims
```

Existing files changed only to require or record the terminal state:

```yaml
scripts/tests/phase00-e3i.Tests.ps1:
  before_sha256: F20C847F74178C190C23D42B4160FFDA53BFE6C446074C84A544F832A0D097CB
  after_sha256: A41BED36E627D5F5BAA04608CBD0E94ACD919C4B12718597DDE33A51BBF4223F
  after_lines: 1591
  after_bytes: 70745
docs/evidence/phase-00/manifest.yml:
  before_sha256: E31F0CCB5EBCA7929A0341FC38B4EC4F5477AC2638764107323601AB440CAFE6
  before_e3_i_state: RUNNING
  after_sha256: 89823F3E29C9689A90331A1994AB11D10F7CD2A122B051E0845173BD4A0EEDCA
  after_e3_i_state: BLOCKED_ENVIRONMENT
  after_artifacts: [docs/evidence/phase-00/E3-I/raw/session-a.attempt-004.adjudication.json, docs/evidence/phase-00/E3-I/conclusion.yml]
  after_decision: Session A terminal parent provider overload; no selected attempt or Session B
  after_lines: 179
  after_bytes: 5055
docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md:
  before_sha256: 6E7826CE586317D51994D8691F524FD10B0284047B3B44DEE548773EF511E3D2
  after_sha256: 36E43AEAFA53C099A1D93F053F0EBB358C81505E147FA886F4B0AC410C8719F2
  changed_locations: status lines 3-5 and terminal runtime update lines 21-29
  after_lines: 610
  after_bytes: 30616
docs/superpowers/plans/2026-08-09-phase-00-e3i-parent-overlay-canary-plan.md:
  before_sha256: 4E448F46785CD0F662E525EDC2D0BD0DA1D87C187289F2CE39758AD640667219
  after_sha256: 04319CDFCC80B96D38E166F877F15184741CC5367984C20CB21295993102E033
  changed_location: Attempt 4 terminal amendment lines 106-114
  after_lines: 1713
  after_bytes: 70968
```

No source contract, helper, runner, fixture, prompt, live OMP configuration, other manifest
row, or prior raw/adjudication artifact was rewritten in this slice. No I1.yml, I2.yml,
I3.yml, or I4.yml was created. No file was removed. No Git integration was performed.

#### Verification checkpoint before this changelog entry

After materialization, the focused suite was GREEN at 42 passed / 0 failed and the validator
was 89 passed / 0 warnings / 0 failed. The subsequent complete closure gate was identical in
PowerShell 7 and Windows PowerShell 5.1:

```yaml
phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
phase00_e3i: {passed: 42, failed: 0, skipped: 0}
validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
```

At this checkpoint, Attempt 5 artifact count, Session B artifact count, I1-I4 file count,
remaining `omp-phase00-e3i-*` temp-root count, and staged-file count were all zero. Branch
remained `main`, repository HEAD remained
`62fecf277dc9d5e47d06319387eac747462214c1`, and the user-owned dirty worktree contained 36
status entries. `git diff --check` exited zero with only the pre-existing line-ending warning
for `spec/phases/phase-00-foundation.md`.

#### Explicit non-claims and Opus review targets

E3-I is terminally represented for this execution round but is not jointly closed: Opus has
not reviewed P00-CX-024 due quota. `BLOCKED_ENVIRONMENT` is not a semantic `FAIL` and does not
establish I1, I2, I3, or I4. Attempt 4 is not selected, its clean-looking partial observations
cannot be reused, Session B remains unlaunched, E3-L/E3-M are not replaced, Phase 00 remains
in progress, and parallel mode remains disabled. A future retry requires changed external
provider state and new user authorization; an unchanged-state Attempt 5 is forbidden.

When quota returns, Opus should independently challenge at least:

1. terminal parent-provider precedence over otherwise conforming partial observations;
2. whether the unrecovered `auto_retry_start` event is correctly distinguished from a
   completed or superseding recovery;
3. exact nine-call ordering, call/result pairing, and the absence of a final completion;
4. all six `[read, yield, hub]` surfaces, exact yields, forbidden-call counts, and absence of
   ambient/override tools;
5. both boolean-false diagnostics and the parent-only override attestation;
6. all task summary branches, positive cost rows, and mutation/live-home/cleanup boundaries;
7. all nine raw hashes, the additive adjudication, and Attempts 1-4 history;
8. the manifest's `RUNNING -> BLOCKED_ENVIRONMENT` transition and omission of I1-I4;
9. the two-shell test/validator totals, redaction checks, zero-temp/staged/session-B state,
   and the continuing non-authority of E3-I over parallel execution.

The previously documented recommendation to rotate the local gateway credential remains in
force. Its value is not present in this entry or any created terminal interpretation artifact.
The final post-entry verification and the self-referential final changelog hash are recorded
outside this entry after the append, as required to avoid claiming verification of bytes that
did not yet exist.

#### P00-CX-024 post-entry verification addendum

```yaml
timestamp: 2026-08-09T13:30:00+07:00
pre_addendum_changelog_sha256: 9FE8D072D6FCA55DBB0962BEF863C4B4A18C4F3EB9746A49C495074181F87661
pinned_omp_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
powerShell_7:
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
windows_powerShell_5_1:
  process_execution_policy: Bypass
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
temporary_pinned_runtime_removed: true
provider_calls_during_verification: 0
```

The first compact-output invocation used shell-specific Pester display parameters and was
rejected before any test ran. A subsequent unpinned PowerShell 7 diagnostic intentionally
reproduced the known lifecycle guard at E3-A: 43 passed / 1 failed because live OMP was
`17.2.12`, not the required `17.2.10`. The first Windows PowerShell 5.1 invocation was likewise
rejected before test execution by machine script policy. These were invocation/precondition
failures, not repository verdicts. The authoritative gates above used an exact hash-verified
temporary `omp.exe` copy, process-local PATH precedence, and process-only execution-policy
relaxation for Windows PowerShell. The temporary copy was verified as the sole child of its
explicit workspace directory and removed after both gates.

Because this addendum changes the file it describes, one final complete two-shell gate and
all integrity scans must run after it. Their results and the final changelog hash are reported
in the user handoff; no provider experiment is permitted during that final check.

### P00-CX-025 — OMP 17.2.12 compatibility audit and approved E3-L design checkpoint

```yaml
timestamp: 2026-08-09T13:42:39+07:00
actor: Codex GPT-5.6
authorization:
  source: explicit user approval of the recommended option and permission to proceed
  selected_version_policy: keep OMP 17.2.10 normative; treat installed 17.2.12 as non-authoritative delta only
  selected_e3_l_design: host-scoped main-CLI live reader; fail closed outside declared scope
scope: compatibility audit plus design documentation only
implementation_started: false
provider_calls: 0
git_integration: none
pre_entry_changelog_sha256: 4C5957BEF64DBF20F06C6A96405F12D9CBC46EA41C8E76706A39C1CBBB6E7403
repository:
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  staged_entries_before: 0
  dirty_entries_before: 36
  ownership: user-owned dirty worktree preserved
peer_review:
  codex_status: design approved by user; self-review pending at append time
  opus_status: pending quota
  joint_closure: false
parallel_mode: DISABLED
```

#### Why this entry exists

The user updated the installed OMP runtime while Phase 00 remained pinned to `17.2.10` and
asked Codex to continue without losing earlier work. Codex first isolated whether the update
caused a repository regression or only an environment-identity drift. After the user selected
the recommended version policy, Codex completed E3-L source tracing, presented three reader
approaches, and received approval for the host-scoped design. This entry records every
repository mutation and all evidence needed for later equal Opus review.

#### Installed-runtime compatibility audit

```yaml
live_omp:
  resolved_path: C:\Users\MrThien\AppData\Local\omp\omp.exe
  version: omp/17.2.12
  sha256: C21A8921CA26C6C6341A067F0F384184D92AC3CF221A26A90CFDD60CEB71F03C
preserved_pinned_backup:
  path: C:\Users\MrThien\AppData\Local\omp\omp.exe.1786250147823.24932.bak
  verified_version_when_copied_as_omp.exe: omp/17.2.10
  sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
normative_registry:
  version: 17.2.10
  commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  changed: false
pinned_source_clone:
  path: _research/upstreams/oh-my-pi
  head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  worktree: clean
  official_remote: https://github.com/can1357/oh-my-pi.git
```

A fresh unpinned PowerShell 7 gate using installed `17.2.12` produced exactly one failure:
the intentional E3-A/E3-H runtime pin assertion at
`scripts/run-phase00-e3a-e3h.ps1:415`. Its focused Pester assertion is at
`scripts/tests/phase00-e3a-e3h.Tests.ps1:417`. No contract or parser test regressed:

```yaml
unpinned_live_17_2_12:
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 43, failed: 1, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
  exact_failure: "Installed OMP is not the required 17.2.10: omp/17.2.12"
  interpretation: expected environment/version drift guard; not a semantic contract regression
```

Codex then copied the exact preserved `17.2.10` binary into a new temporary directory,
prepended only that directory to the process-local PATH, verified the copied version and hash,
and ran the complete gate in PowerShell 7 and Windows PowerShell 5.1. Both were green:

```yaml
pinned_17_2_10_powerShell_7:
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
pinned_17_2_10_windows_powerShell_5_1:
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
temporary_runtime:
  sole_child_verified: true
  removed: true
live_home_write: false
provider_call: false
```

Conclusion: the update did not damage the reviewed repository contracts. Accepting
`17.2.12`, removing the version assertion, changing the compatibility registry, or moving
source anchors would conceal evidence drift. None of those mutations was made.

#### E3-L source findings

The approved reader is the public `pi.pi.settings` proxy, restricted to the OMP-owned default
main-CLI root-session construction class. The positive same-instance chain at pinned
`3a8591a` is:

1. `packages/coding-agent/src/index.ts:17` exports `Settings` and `settings`;
2. `config/settings.ts:404-416` assigns and returns the same `globalInstance`;
3. `main.ts:1282-1283` creates the default CLI `settingsInstance` through `Settings.init()`;
4. `main.ts:1533-1545` supplies that instance as `sessionOptions.settings`;
5. `sdk.ts:1271-1274` consumes the supplied object;
6. `task/structured-subagent.ts:315-317` reads the session settings for actual
   `applyChanges`; and
7. `config/settings.ts:2371-2388` binds proxy methods to `globalInstance`.

The same source also prevents a universal claim:

- ACP creates a distinct `cloneForCwd()` settings object (`main.ts:397-424` and
  `config/settings.ts:603-620`);
- SDK callers may inject `settings` or `settingsManager` (`sdk.ts:1271-1273`);
- `runRootCommand` may receive injected dependency settings (`main.ts:1282-1283`);
- RPC/RPC-UI lifecycle is outside the declared E3-L v0 host scope.

The nominal project custom-tool `ctx.settings` path remains retired:
`custom-tools/types.ts:85-105` advertises it, while
`sdk.ts:885-894,938-955` omits it from the actual project-tool bridge. E3-I Attempt 1's
`P00_E3I_SETTINGS_UNAVAILABLE` remains the runtime corroboration. The MCP context at
`session/session-tools.ts:1295-1314` is a different in-process adapter and does not transmit a
live JavaScript Settings object to an external MCP server. Hook, custom-command, and extension
contexts expose no broader session-scoped reader.

#### Newly identified E3-L case-3 contract contradiction

The current E3-L case 3 cannot produce its stated result on pinned `17.2.10`. It combines:
project `apply:false`, a `/settings` change through `Settings.set()` to `true`, expected live
value `true`, and no file write. Pinned source establishes the opposite mechanics:

- `config/settings.ts:498-505`: `set()` updates global settings and queues persistence;
- `modes/components/settings-selector.ts:1272-1282`: `/settings` calls `set()`;
- `config/settings.ts:2143-2147`: project settings merge after global settings, so project
  `false` still wins over a global `true`;
- `config/settings.ts:518-526`: `override()` is the in-memory, non-persistent, highest
  precedence transition the case intended to exercise.

The approved design therefore requires the later implementation round to replace case 3's
`/settings`/`Settings.set()` procedure with
`Settings.override("task.isolation.apply", true)` in every normative mirror. This design
checkpoint does not mutate those normative files.

#### Selected design and alternatives

```yaml
selected:
  host_scope: OMP-owned default main-CLI root-session construction class
  runtime_presentation: deterministic non-interactive print mode
  reader: pi.pi.settings
  case_1: project false -> reader false, child false, capture-only branch
  case_2: project false plus CLI overlay true -> reader true, child false, apply-enabled branch
  case_3: project false plus Settings.override true -> reader true, child false, apply-enabled branch
  reader_calls: one parent-only fixed pi.pi.settings.get call before each case's task samples
  evidence_strategy: one augmented joint E3-I/E3-L raw transaction; independent adjudicators consume raw events
  parallel_consequence: none; remains disabled pending E3-M
rejected:
  universal_reader_fail_now: discards a valid CLI candidate by conflating unsupported hosts with no supported host
  universal_global_proxy: contradicted by ACP clone and SDK injection paths
  patched_or_newer_omp: outside template ownership and invalidates the pinned evidence identity
```

Evidence reuse is attempt-atomic. Self-review found that the existing E3-I transaction does
not directly read the proxy in Session B; native task behavior is not a substitute for E3-L's
required reader value. The approved design therefore augments a future joint transaction with
a parent-only fixed `pi.pi.settings.get("task.isolation.apply")` call before every case's task
samples. One selected joint attempt must supply Session A, Session B, all three reader calls,
subprocess diagnostics, task branches, provider accounting, and mutation boundaries. E3-I and
E3-L apply independent oracles directly to the same raw events; neither conclusion depends on
the other. No cross-attempt combination is permitted. Attempts 1-3 remain `INVALID_RUN`;
Attempt 4 remains `BLOCKED_ENVIRONMENT / P00-RUNTIME-PROVIDER-OVERLOAD`. This design does not
authorize Attempt 5 or any provider call.

#### Exact repository mutations

One file was created and self-reviewed in this design checkpoint:

```yaml
docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md:
  before: ABSENT
  after_sha256: CA867DF98DBDD62E43561B98778D60FB588C781F6B64E028A926D2C9341632B6
  after_lines: 385
  after_bytes: 21379
  purpose: complete English E3-L host scope, source proof, case correction, runtime design, taxonomy, safety, and peer-review targets
```

This changelog file is the second and final repository mutation in the checkpoint. No
runner, helper, test, fixture, manifest, normative spec, registry, evidence conclusion,
prior design, plan, live OMP configuration, or source clone was changed. No file was removed.

#### Explicit non-claims and Opus review targets

This checkpoint does not implement E3-L, run a provider experiment, select an E3-I attempt,
resolve the provider block, change E3-L manifest state, pass or fail E3-L, attempt E3-M,
support ACP/SDK/RPC hosts, or enable parallel execution. The user approved the design; Opus
has not reviewed it, so joint closure remains pending.

When quota returns, Opus should independently challenge at least:

1. legitimacy and precision of the main-CLI root-session support boundary;
2. the seven-link proxy-to-native-dispatch identity proof;
3. completeness of ACP, SDK, dependency-injection, RPC, and MCP exclusions;
4. the `Settings.set()` precedence/persistence contradiction and the exact
   `Settings.override()` correction;
5. whether E3-I evidence reuse creates any verdict cycle or cross-attempt contamination;
6. falsifiability of all three reader/child/task-branch correlations;
7. PASS/FAIL/BLOCKED_ENVIRONMENT/INVALID_RUN separation;
8. continued E3-M ownership of parallel enablement;
9. installed `17.2.12` delta treatment and exact `17.2.10` pin preservation; and
10. the two-file-only mutation claim, hashes, final static gates, zero staging, and no live
    home or provider activity.

Post-entry self-review, verification totals, final file hashes, and final repository state
are recorded in the user handoff after the bytes in this entry exist. This avoids a
self-referential hash claim inside the file being hashed.

#### P00-CX-025 post-entry self-review and verification addendum

```yaml
timestamp: 2026-08-09T13:49:00+07:00
pre_addendum_changelog_sha256: 9CEF95084EC61DFAD42CD47A892EE509EE2A58F70D8DF1B441573BEE6A13149F
design:
  sha256: CA867DF98DBDD62E43561B98778D60FB588C781F6B64E028A926D2C9341632B6
  lines: 385
  bytes: 21379
  markdown_fences: 2
  markdown_fences_balanced: true
self_review_result: PASS after one material design correction
provider_calls: 0
parallel_mode: DISABLED
```

The first full read-through identified one material insufficiency in the approved draft.
Existing E3-I Session B records the subprocess diagnostic and native task behavior but does
not directly call the approved live reader. Inferring reader `true` from apply-enabled task
behavior would fail E3-L's requirement to record the reader itself. Codex corrected the
design before implementation:

- one parent-only fixed `pi.pi.settings.get("task.isolation.apply")` reader is called before
  each of L1, L2, and L3's task samples;
- the future raw transaction is explicitly augmented and jointly shared, not treated as the
  unchanged current E3-I protocol;
- E3-I and E3-L apply independent oracles directly to the same raw events; neither experiment
  consumes the other's conclusion; and
- the override tool's before/after attestation remains independently required but does not
  replace the L3 reader call.

The initial draft hash was
`DEEDCD8AC21D48DDB547E48B5493A24D679B363DAFE2518AFFB3DF2A70DBCB53`
at 372 lines / 20,176 bytes. The corrected design hash and dimensions are recorded above and
replace that draft completely. No runner, test, fixture, manifest, normative spec, or runtime
artifact was changed during the correction.

Fresh complete static gates used a hash-verified process-local copy of exact OMP `17.2.10`.
The authoritative results were:

```yaml
powerShell_7:
  version: 7.6.4
  runtime: omp/17.2.10
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
windows_powerShell_5_1:
  version: 5.1.26100.8875
  process_execution_policy: Bypass
  runtime: omp/17.2.10
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
temporary_pinned_runtime:
  exact_root: C:\Users\MrThien\AppData\Local\Temp\omp-codex-e3l-verify-20260809-1347-6f2d
  sole_child_name: omp.exe
  sole_child_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
  sole_child_verified_before_cleanup: true
  removed_non_recursively: true
```

Invocation notes retained for audit completeness:

1. An initial combined gate-and-recursive-cleanup command was rejected by command policy
   before process creation; no test ran and no path was created.
2. Supplying `shell: powershell.exe` to one tool invocation still resolved the desktop's
   PowerShell 7 host. That redundant green run was not counted as Windows PowerShell 5.1.
3. The authoritative 5.1 gate explicitly invoked
   `%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe` with an encoded in-memory command
   and reported version `5.1.26100.8875`.
4. Two `Remove-Item` cleanup forms were rejected by command policy before execution. Cleanup
   then used exact-path, non-recursive `.NET` file and empty-directory deletion only after
   re-verifying the sole child name and hash. The explicit root is absent afterward.

One final post-addendum integrity scan and complete two-shell gate remain required because
this addendum changes the changelog bytes. Their results, the final changelog hash, zero-stage
state, and exact user handoff are reported after that final run. No provider execution is
authorized or needed.

---

### P00-CX-026 — User-approved E3-L implementation plan (no implementation or provider call)

```yaml
timestamp: 2026-08-09T14:11:36+07:00
predecessor_changelog_sha256: A2CCA4093B004E3A49C0A3C368E0AC29DFBD0CBC1D741906B0E72CE298CC4F30
approved_design:
  path: docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md
  sha256: CA867DF98DBDD62E43561B98778D60FB588C781F6B64E028A926D2C9341632B6
new_plan:
  path: docs/superpowers/plans/2026-08-09-phase-00-e3l-live-session-reader-plan.md
  sha256: D8E8AE68829263FC225631E7A4E3401CF65630F9D2616D40E4E8ACA98663BBF6
  lines: 895
  bytes: 43648
repository:
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
  staged_entries: 0
  dirty_entries: 36
  ownership: user-owned dirty worktree preserved
runtime_and_source:
  normative_omp: 17.2.10
  normative_executable_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
  normative_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  pinned_source_head: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  pinned_source_worktree_entries: 0
  pinned_source_origin: https://github.com/can1357/oh-my-pi.git
  installed_17_2_12_treated_as_authority: false
manifest_during_planning:
  E3-I: BLOCKED_ENVIRONMENT
  E3-L: READY
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
provider_calls: 0
git_integration: none
opus_peer_review: PENDING_QUOTA
joint_closure: false
```

#### Scope and planning decision

The user approved the written E3-L design and authorized the implementation-planning step.
Codex used the `superpowers:writing-plans` contract to create an executable TDD plan, then
used `superpowers:verification-before-completion` before reporting the plan ready. This
checkpoint creates the plan only. No normative spec, runner, helper, test, fixture, source
artifact, manifest row, runtime artifact, live OMP configuration, or provider state was
modified.

The plan locks the following architecture:

1. The supported reader remains the public `pi.pi.settings` proxy, restricted to the
   OMP-owned default main-CLI root-session construction class on pinned 17.2.10.
2. A fixed parent-only `phase00_e3l_read_apply` tool returns exactly probe, setting,
   operation, Boolean value, and parent-only scope. It accepts no path or value and owns no
   mutation, subprocess, or persistence surface.
3. Session A records reader false, diagnostic false, three capture-only controls, the
   existing exact `Settings.override(..., true)` attestation, reader true, diagnostic false,
   and three apply-enabled controls. Session B records reader true, diagnostic false, and
   three apply-enabled controls under the CLI overlay.
4. The future parent sequences are locked to 11 calls in Session A and five calls in
   Session B. L1 uses A indexes 0/1/2-4, L3 uses A indexes 5/6/7/8-10, and L2 uses B indexes
   0/1/2-4.
5. Shared transport code may decide only `ELIGIBLE`, `INVALID_RUN`, or
   `BLOCKED_ENVIRONMENT`. E3-I and E3-L apply separate semantic oracles directly to the same
   raw events; neither opens or trusts the other's conclusion.
6. Static source identity is captured before provider execution from the clean pinned clone
   and contains all seven positive identity links plus ACP/clone/SDK/dependency-injection/
   RPC/RPC-UI exclusions.
7. One additive joint attempt groups Session A and Session B under the same attempt/runtime
   identity. It contains no overwrite or automatic retry path. Attempts 1-4 retain their
   existing classifications.
8. Deterministic JSON projection and L1-L3/conclusion artifacts are materialized only from a
   complete selection-eligible transaction and re-hash every raw input.
9. E3-L `INVALID_RUN` leaves the manifest at READY with no claimed artifact; PASS, FAIL, and
   BLOCKED_ENVIRONMENT require outcome-appropriate complete artifacts. E3-I transitions
   independently. E3-M and parallel mode never change.
10. Tasks 1-8 are static and explicitly make zero provider calls. Task 9 is a hard stop that
    requires a new, separate user authorization for exactly one provider-backed Attempt 5.

#### Plan structure and self-review evidence

```yaml
tasks: 10
checkbox_steps: 61
reviewer_gates: 10
file_responsibility_map_present: true
interfaces_and_locked_schemas_present: true
red_green_steps_present: true
static_provider_stop_present: true
runtime_stop_conditions_present: true
markdown_fences: 30
markdown_fences_balanced: true
trailing_whitespace_lines: 0
incomplete_markers: 0
```

The first mechanical self-review found two plan-quality defects before this entry:

- interface examples used angle-bracket type metavariables that could be mistaken for
  unresolved placeholders; they were replaced with an exact function/typed-parameter table;
- only five tasks had an explicitly named reviewer gate; the plan now contains one reviewer
  gate for every task.

The semantic read-through then corrected two additional defects:

- Task 4 incorrectly labeled the new E3-L helper as `Modify`; it now correctly owns
  `Create`;
- an INVALID_RUN future E3-I attempt cannot become a manifest state. The plan now preserves
  Attempt 4's existing BLOCKED_ENVIRONMENT terminal state/artifacts and records the new
  attempt only as invalid history unless a later complete PASS/FAIL/BLOCKED outcome exists.

The source-outcome precedence was also made explicit: inaccessible or ambiguous source
evidence is INVALID_RUN, while a complete attributable pinned-source contradiction is FAIL.

#### Fresh verification before this entry

A hash-verified copy of the preserved 17.2.10 executable was placed in a verified temporary
directory and prepended only to child-process PATH. No model/provider prompt was issued.
Fresh results were identical in PowerShell 7 and Windows PowerShell 5.1:

```yaml
powerShell_7:
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
windows_powerShell_5_1:
  phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
  phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
  phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
  phase00_e3i: {passed: 42, failed: 0, skipped: 0}
  validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
temporary_runtime_roots_remaining: 0
```

One compact-output verification command used unsupported `Invoke-Pester -Show None` and
stopped before tests; its verified temporary runtime was still removed in `finally`. Codex
re-ran the complete compact gate without that parameter and obtained the green totals above.
This was a verification-command compatibility issue, not a repository or plan defect.

#### Exact repository mutation

This checkpoint has exactly two repository mutations:

```yaml
created:
  docs/superpowers/plans/2026-08-09-phase-00-e3l-live-session-reader-plan.md:
    before: ABSENT
    after_sha256: D8E8AE68829263FC225631E7A4E3401CF65630F9D2616D40E4E8ACA98663BBF6
    lines: 895
    bytes: 43648
modified:
  codex-phase00-execution-changelog-for-opus5.md:
    before_sha256: A2CCA4093B004E3A49C0A3C368E0AC29DFBD0CBC1D741906B0E72CE298CC4F30
    after_sha256: self_referential_reported_in_handoff
removed: []
```

#### Explicit non-claims and Opus review targets

This checkpoint does not implement E3-L, mutate the normative case 3 yet, add a reader,
change E3-I protocol, launch Attempt 5, resolve the provider block, select a transaction,
create source/runtime conclusion evidence, change any manifest row, attempt E3-M, or enable
parallel work.

When quota returns, Opus should challenge:

1. whether shared transport plus separate semantic oracles genuinely prevents verdict cycles;
2. whether the exact fixed reader schema and cwd/Session-A override gates prevent child
   contamination and arbitrary settings access;
3. whether every seven-link source check and every excluded host is mechanically falsifiable;
4. whether L1-L3 indexes and value/diagnostic/branch conjunctions are exact and sufficient;
5. whether Attempt 5 grouping, continuation, preservation, and no-retry rules are atomic;
6. whether source/runtime INVALID_RUN, BLOCKED_ENVIRONMENT, FAIL, and PASS precedence is
   technically correct;
7. whether deterministic projections and manifest validation prevent partial/cross-attempt
   evidence promotion;
8. whether the static/provider authorization split is enforced at every runner entry point;
9. whether E3-I INVALID_RUN correctly preserves its prior terminal manifest state; and
10. whether every planned file, hash, verification claim, non-claim, and unchanged E3-M/
    parallel boundary is complete.

Post-entry verification and the final changelog SHA-256 are reported in the user handoff
after these bytes exist. No provider call is authorized by this entry.

---

### P00-CX-027 — E3-L static implementation, independent oracle, and provider-stop gate

```yaml
timestamp: 2026-08-09T15:10:59+07:00
predecessor_changelog_sha256: 698E6EEC1A24F51B194044E77548D0B86025180A593E9D9ACFBD9132B9E077D7
authority:
  user_approved_solo_codex_implementation: true
  approved_option: 2
  approved_design: docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md
  approved_plan: docs/superpowers/plans/2026-08-09-phase-00-e3l-live-session-reader-plan.md
  implemented_plan_tasks: [1, 2, 3, 4, 5, 6, 7, 8]
  task_9_provider_execution_authorized: false
  opus_peer_review: PENDING_QUOTA
  joint_closure_claimed: false
runtime_authority:
  normative_version: omp/17.2.10
  normative_executable_sha256: 1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6
  normative_commit: 3a8591a8af5b6d200088d12ca75a5517cb064fa8
  source_origin: https://github.com/can1357/oh-my-pi.git
  source_worktree_entries: 0
  installed_version_observed_but_not_used_as_authority: omp/17.2.12
execution_boundary:
  provider_calls: 0
  attempt_5_launches: 0
  session_a_launches: 0
  session_b_launches: 0
  automatic_retries: 0
  repository_joint_raw_artifacts: 0
  git_stage_commit_branch_push_pr_performed: false
  branch: main
  head: 62fecf277dc9d5e47d06319387eac747462214c1
manifest_non_transition:
  sha256: 89823F3E29C9689A90331A1994AB11D10F7CD2A122B051E0845173BD4A0EEDCA
  E3-I: BLOCKED_ENVIRONMENT
  E3-L: READY
  E3-L_artifacts: []
  E3-M: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
phase_00_status: IN_PROGRESS
```

#### Implemented contract and responsibility boundaries

Tasks 1-8 implement the complete provider-free half of the approved E3-L plan. The
normative mirrors now identify exactly one supported host class: the **OMP-owned default
main-CLI root-session construction class**. The approved reader is exactly
`pi.pi.settings.get("task.isolation.apply")`; it proves no ACP, cloned-settings,
dependency-injected, SDK, RPC, or RPC-UI host. L3 now uses the synchronous, non-persistent
`Settings.override("task.isolation.apply", true)` layer rather than `/settings` or
`Settings.set()`. E3-L remains observational and cannot enable parallel fan-out; E3-M remains
the guarded-dispatch gate.

The fixed parent-only custom-tool surface is:

```yaml
reader:
  name: phase00_e3l_read_apply
  load_mode: essential
  arguments: {}
  availability: exact disposable parent cwd in Session A and Session B
  operation: pi.pi.settings.get("task.isolation.apply")
  value_type: boolean_only
  details_exact_fields: [probe, setting, operation, value, scope]
  details_constants:
    probe: phase00-e3l-live-reader-v1
    setting: task.isolation.apply
    operation: pi.pi.settings.get
    scope: parent-only
  forbidden_in_reader: [override, set, flush, save, bash, spawn, write, caller_parameters]
override:
  name: phase00_e3i_override_apply_true
  load_mode: essential
  arguments: {}
  availability: exact disposable parent cwd and OMP_PHASE00_E3IL_ENABLE_OVERRIDE exactly "1"
  operation: pi.pi.settings.override
  requested: true
  details_exact_fields: [probe, setting, before, operation, requested, after, calledSet, calledFlushOrSave, scope]
  non_persistence_attestation: {calledSet: false, calledFlushOrSave: false}
```

The parent protocols are exact and sequential:

```yaml
session_a_tool_sequence:
  [phase00_e3l_read_apply, bash, task, task, task,
   phase00_e3i_override_apply_true, phase00_e3l_read_apply,
   bash, task, task, task]
session_a_call_count: 11
session_b_tool_sequence:
  [phase00_e3l_read_apply, bash, task, task, task]
session_b_call_count: 5
shared_transport_statuses: [ELIGIBLE, INVALID_RUN, BLOCKED_ENVIRONMENT]
semantic_statuses_excluded_from_shared_transport: [PASS, FAIL]
selection_rule: Session B is eligible only after Session A transport/selection is ELIGIBLE; an attributable E3-I semantic FAIL does not suppress Session B
```

The E3-L oracle separately parses the two raw sessions and applies:

```yaml
L1: {parent_setup: project false, reader: false, child_diagnostic: false, task_branch: capture_only}
L2: {parent_setup: CLI overlay true, reader: true, child_diagnostic: false, task_branch: isolated_apply}
L3: {parent_setup: project false plus Settings.override true, reader_before: false, reader_after: true, child_diagnostic_after: false, task_branch_after: isolated_apply}
outcome_precedence:
  - source_or_raw_ambiguity: INVALID_RUN
  - external_terminal_failure: BLOCKED_ENVIRONMENT
  - runtime_selection_or_boundary_identity_failure: INVALID_RUN
  - attributable_source_reader_override_diagnostic_or_branch_contradiction: FAIL
  - exact_source_and_complete_L1_L2_L3_conjunction: PASS
independence:
  E3-L_never_reads_E3-I_conclusion: true
  E3-I_never_reads_E3-L_conclusion: true
  common_input: one complete selected raw transaction only
```

`New-Phase00E3LTransactionProjection` accepts only exact raw paths, re-hashes and sorts every
input, and copies parsed observations rather than caller observations or whole transcripts.
`Test-Phase00E3LArtifactContract` keeps READY non-authoritative; requires joint adjudication
plus conclusion for BLOCKED_ENVIRONMENT; and requires source identity, selected projection,
L1-L3, and conclusion for PASS/FAIL. It re-hashes references and rejects identity drift,
partial evidence, circularity, unresolved markers, E3-M drift, and parallel-mode drift.

#### Pinned seven-link source proof

The mechanically generated artifact is
`docs/evidence/phase-00/E3-L/source-identity.json`, SHA-256
`CE7B3DF1446788C2996521172FD2BB7B124E1DBBDB854F2E0FBD990FF5EA32FD`. It records
seven positive links, six host exclusions, five complete source-file hashes, only
repository-relative paths, and `runtime_observation_substitutes_source: false`.

```yaml
source_files:
  packages/coding-agent/src/config/settings.ts: B2CD4FB72159A200FB32ECB0F7ED5983573C16942425D5929034872631524F49
  packages/coding-agent/src/index.ts: 3EFC237498D428C3D9C8C3523ACB3CD7090DCCCF4369E433792912471E389377
  packages/coding-agent/src/main.ts: 87BBB6985089C9BC1CFD9D5B71EAF102760BCFC0E6607E7BA51FFB980C790AB5
  packages/coding-agent/src/sdk.ts: EEE5412D1847E6BC274DF4E29A25188C8831A27957BFCFCC93EBBD0DFD94D3F4
  packages/coding-agent/src/task/structured-subagent.ts: 7404F4619262706E75ACB8B5F06F96B089A409F6CB5B58DE2F700D5645CC9AB7
positive_links:
  EXPORT: index.ts:17
  GLOBAL_INIT: settings.ts:404,407,409,413,415,416
  MAIN_INIT: main.ts:1282,1283
  SESSION_OPTIONS: main.ts:1533,1540,1545
  SDK_EXPLICIT_SETTINGS: sdk.ts:1271,1272,1273,1274
  TASK_DISPATCH: structured-subagent.ts:315,316,317
  GLOBAL_PROXY: settings.ts:2371,2373,2378,2380,2384,2388
excluded_hosts:
  ACP_SESSION_NEW: main.ts:397,399,423
  CLONE_FOR_CWD: settings.ts:603,604,611,620
  SDK_SETTINGS_INJECTION: sdk.ts:1271,1272
  MAIN_DEPENDENCY_INJECTION: main.ts:1283
  RPC_PROTOCOL: main.ts:1269
  RPC_UI_PROTOCOL: main.ts:1269
```

#### TDD, debugging, and correction ledger

Every production surface was preceded by a focused RED assertion. The material cycles were:

```yaml
task_1_normative:
  red: {passed: 1, failed: 3}
  green_contract: {passed: 3, failed: 1}
  residual_failure: expected missing Task-2 helper
task_2_shared_transport:
  red: {passed: 3, failed: 4}
  green_e3l_surface: {passed: 6, failed: 1}
  green_e3i_regression: {passed: 42, failed: 0}
  residual_failure: expected missing Task-4 helper
task_3_fixture_protocol:
  red: {passed: 40, failed: 3}
  intermediate: {passed: 42, failed: 1}
  green_e3i: {passed: 43, failed: 0}
  e3l_at_boundary: {passed: 6, failed: 1}
task_4_source_identity:
  red: {passed: 6, failed: 7}
  green: {passed: 13, failed: 0}
task_5_reader_and_oracle:
  red: {passed: 13, failed: 10}
  green: {passed: 23, failed: 0}
  cross_shell_e3i: {passed: 43, failed: 0}
  cross_shell_e3l: {passed: 23, failed: 0}
task_6_mocked_joint_runner:
  red: {passed: 23, failed: 4}
  loader_parameter_debug: {passed: 0, failed: 1}
  green: {passed: 27, failed: 0}
task_7_projection_and_durable_contract:
  red: {passed: 27, failed: 6}
  green: {passed: 33, failed: 0}
```

The implementation/debugging corrections are evidence, not omitted noise:

1. PowerShell's automatic case-insensitive `$Matches` variable collided with a local
   `$matches` accumulator, producing hash-table addition errors. The local source-window
   accumulator was renamed to `$matchedLines`.
2. StrictMode rejected `.Reason` access on an empty array. Failure-reason extraction now
   guards cardinality before property access.
3. Pester 3 interprets `Should Contain` as a file-content assertion. Collection membership
   assertions were replaced by explicit `-contains | Should Be` checks.
4. The source-root escape control initially did not fail in the full test even though a
   direct probe threw correctly. The guard was made explicit and the complete 13-test source
   suite was rerun green.
5. A newly transcribed runtime constant was wrong
   (`1525122F0042309FEE8270D53494C07BFD1350CD28B467FB980F6B8C323BC8A6`). Static audit caught
   it before runner use or any provider call. All new code/tests were corrected to
   `1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`; the source artifact
   was regenerated from transient SHA
   `C7B8DF86917F9CAE55977118D5C04C3C3BDC0978FF3563144A2DB845FDAFC7F6` to final SHA
   `CE7B3DF1446788C2996521172FD2BB7B124E1DBBDB854F2E0FBD990FF5EA32FD`.
6. The mocked joint runner first loaded through the test helper without its mandatory
   `OmpExecutable`; the test loader was corrected so direct execution remains parameterized
   while dot-source mocking remains provider-free.
7. The mocked joint path fixture initially doubled the `docs/evidence/phase-00` prefix. Its
   root was corrected to the Phase-00 evidence root; production paths remain repository
   relative.
8. A regex-based terminal-manifest mutation duplicated a YAML key. The mutation matrix now
   replaces the exact indexed line and continues to reject every malformed terminal state.
9. The first combined full-gate command was rejected before process creation because its
   inline recursive cleanup pattern triggered the command safety policy. No tests, provider,
   or repository mutation occurred. The gates were rerun with the tested disposable cleanup
   guard and completed green.
10. The first post-entry Task-8.1 trailing-whitespace scan found nine intentional Markdown
    hard-break spaces in the design header. The header was normalized to explicit `<br>`
    breaks, leaving semantics unchanged and reducing the design from 407 to 404 lines. The
    ledger below records the corrected final hash, and all gates/scans were restarted after
    this correction.

#### Exact repository mutation and anchors

```yaml
modified:
  spec/08-isolation-and-concurrency.md:
    before_sha256: 5F55E1CFD554F13098355BCF2CCBC31F6B75390F129C7E01AB7696B46B541FCF
    after_sha256: 08EACD97A86B91B3DA1D2D77B7630EC61979370FCF53DCB9B3493F58168DD978
    after: {lines: 810, bytes: 61110, anchors: "570-775"}
  spec/13-validation-and-evaluation.md:
    before_sha256: EE2471392B8AC2C22B606DE02ED08407735000F43E8E8D3E6D5CCC5C3DDF8CB5
    after_sha256: 43A66F3BB9826B7AD62ACA820BF45761825B4D10840A9FFED72C4851B4F81864
    after: {lines: 268, bytes: 22782, anchor: 156}
  spec/phases/phase-00-foundation.md:
    before_sha256: 9F7B7230C9A01754093BE71C51E047FC25D7EFEC3895A25D2712B3E5A97CD35A
    after_sha256: 9E2E3532B307EA1166B9F5B754FD1D5C515BB02AA246C9BDAA2194A8C0CF476D
    after: {lines: 1782, bytes: 108543, anchors: "522-639,1770"}
  spec/phases/phase-02-core-orchestration.md:
    before_sha256: 5D0F3B78CD638F8C1F01D1F7837A819A25DAC4379B9C2035DC7D649538A2D3BB
    after_sha256: 770C7ADCE306B8C205695974686151DBA3172FC0AA3ED66251233FD2F6DFF39F
    after: {lines: 326, bytes: 25261, anchors: "131-147,300"}
  docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md:
    before_sha256: CA867DF98DBDD62E43561B98778D60FB588C781F6B64E028A926D2C9341632B6
    after_sha256: F0E2573C27E18D3EE74E055BAEDE1910CD79CE297A68F0DC4C0475A8950595A3
    after: {lines: 404, bytes: 22512, anchors: "3-12,351-381"}
  scripts/lib/phase00-e3i-evidence.ps1:
    before_sha256: F74F0F8348931704D74244B6639C312DBA2D079106945ED4C051FC40CB31ED33
    after_sha256: ACDD5A8C8BFF6C32224268B5675947AAE971079C58D36B8D1253F6ED2DA570F3
    after: {lines: 1019, bytes: 37848, anchors: "382-418,689-813"}
  scripts/lib/phase00-evidence.ps1:
    before_sha256: D10193FE57C20A2A50142952572CDD29F24B63464B78FEBEE15F7D6CAD6AEEBB
    after_sha256: 7A0F4325BCCDE50B5818490CF23BC7AB56CBF82AFF9E110614714B4478CF2D38
    after: {lines: 793, bytes: 39531, anchors: "270-590"}
  scripts/run-phase00-e3i.ps1:
    before_sha256: 465EC54EBBCB5FFBCE911009D7094C4BB02B7F2FD2C1FB6BBF2248D20D848D0C
    after_sha256: C53F13158CAD54F7BCC918C95D38EE342CF6FE3DA82368A586920B9598608BBD
    after: {lines: 855, bytes: 35266, anchors: "57-58,191-192,721-725,779-780,844-845"}
  scripts/tests/phase00-e3i.Tests.ps1:
    before_sha256: A41BED36E627D5F5BAA04608CBD0E94ACD919C4B12718597DDE33A51BBF4223F
    after_sha256: 9D7843AE18CD5E12BE19095C8211DF35671B90896299DC2004F94B0091ADA22C
    after: {lines: 1691, bytes: 75075, anchors: "144-301,644-1052,1097-1450"}
  scripts/tests/phase00-e3a-e3h.Tests.ps1:
    before_sha256: 9702B3D7E9CD322F0487AEAFAAFAE48EC8009A3FE1F92B5934ADFE5A8650117D
    after_sha256: 953E28FFC4D61CB62D00ADBCEBFA873AB282E7850A18DD100FC4B590CFE816FB
    after: {lines: 784, bytes: 42855, anchor: 778}
  scripts/validate-template.ps1:
    before_sha256: E31DCAC593E6759A513EBABC744482227B0D206B64E5657DE1253A519E1D1FCA
    after_sha256: 937481E2AD186BB23A3A3AF7C4E0081C401122753D4E602D981868DBEE3A62BD
    after: {lines: 275, bytes: 9930, anchor: 235}
  docs/evidence/phase-00/E3-I/fixture/.omp/tools/phase00-e3i-runtime-override.ts:
    before_sha256: C538B7C2E43450C170D566793582CB6E9C322C134DC3AEA2CE9C01B1524445C2
    after_sha256: 364F5063FB6DD3D906E3A05016494148D87D9A7DB1261651850DB4FC31DC3AA3
    after: {lines: 79, bytes: 2552, anchors: "7-79"}
  docs/evidence/phase-00/E3-I/fixture/prompts/session-a.md:
    before_sha256: F464AC463A2C17B8FF7C0C8E229CFE73E5CED886617397D244FCD15110F86ABE
    after_sha256: 5A0C1427063CABF3CC26EF358ABE0A4B59B1512FA341CB825CDAD9F8CC183740
    after: {lines: 42, bytes: 1431, anchors: "5,35"}
  docs/evidence/phase-00/E3-I/fixture/prompts/session-b.md:
    before_sha256: 881A27340B4958D089D1C868B9741408B110BA4C558E8BA6232B7280397FA97E
    after_sha256: 52AE9C1D9DCDDD9BF7B480FC819537BC1A2C22EFE62327ECFA090C1A71E51631
    after: {lines: 36, bytes: 1158, anchor: 6}
created:
  scripts/lib/phase00-e3il-transport.ps1:
    before: ABSENT
    after_sha256: 24DA590F5C86563F9F50941D396C3B937559A0F0FC337CC0CC88B57F311AF8D4
    after: {lines: 587, bytes: 23145, anchors: "10-587"}
  scripts/lib/phase00-e3l-evidence.ps1:
    before: ABSENT
    after_sha256: F181D2F035D63092F54A643D2D4F623973A8951FE40C38CC0039EB6BDCF23DDB
    after: {lines: 850, bytes: 38194, anchors: "19-849"}
  scripts/run-phase00-e3l-joint.ps1:
    before: ABSENT
    after_sha256: 7BB02A324E1D0013B5E8F7621A47578A8470A9B874506B09E1E8E44FFE59167F
    after: {lines: 290, bytes: 11617, anchors: "16-290"}
  scripts/tests/phase00-e3l.Tests.ps1:
    before: ABSENT
    after_sha256: E260F904CE970BA105982F20B09E2AC2FE81D056F4725CF5A4FEA0A2EF5FE939
    after: {lines: 1429, bytes: 64940, anchors: "1-1429"}
  docs/evidence/phase-00/E3-L/source-identity.json:
    before: ABSENT
    after_sha256: CE7B3DF1446788C2996521172FD2BB7B124E1DBBDB854F2E0FBD990FF5EA32FD
    after: {lines: 225, bytes: 6119}
unchanged_authority:
  docs/superpowers/plans/2026-08-09-phase-00-e3l-live-session-reader-plan.md: D8E8AE68829263FC225631E7A4E3401CF65630F9D2616D40E4E8ACA98663BBF6
  docs/evidence/phase-00/manifest.yml: 89823F3E29C9689A90331A1994AB11D10F7CD2A122B051E0845173BD4A0EEDCA
  registry/upstreams.yml: user_owned_preexisting_change_not_touched_by_P00-CX-027
changelog:
  before_sha256: 698E6EEC1A24F51B194044E77548D0B86025180A593E9D9ACFBD9132B9E077D7
  after_sha256: self_referential_reported_in_handoff
removed: []
```

#### Pre-entry verification and static audit

All complete gates used a process-local copy of the exact normative executable and verified
both `omp/17.2.10` and its SHA-256 before testing. Results were identical in PowerShell 7 and
Windows PowerShell 5.1:

```yaml
per_shell:
  phase00-e3l.Tests.ps1: {passed: 33, failed: 0, total: 33}
  phase00-e3i.Tests.ps1: {passed: 43, failed: 0, total: 43}
  phase00-e3a-e3h.Tests.ps1: {passed: 44, failed: 0, total: 44}
  phase00-wave-a.Tests.ps1: {passed: 26, failed: 0, total: 26}
  phase00-e3j-e3k.Tests.ps1: {passed: 35, failed: 0, total: 35}
  aggregate: {passed: 181, failed: 0, total: 181}
repository_validator: {passed: 90, warnings: 0, failed: 0, exit_code: 0}
static_audit:
  powershell_7_parse: {files: 10, failed: 0}
  windows_powershell_5_1_parse: {files: 10, failed: 0, version: 5.1.26100.8875}
  typescript_factory_loader: covered_by_phase00-e3i.Tests.ps1_without_model_prompt
  json_parse: {files: 1, failed: 0}
  source_reference_rehash: {files: 5, mismatches: 0}
  positive_source_links: 7
  source_host_exclusions: 6
  markdown_fences: {files: 7, unbalanced: 0}
  trailing_whitespace: 0
  absolute_disposable_paths: 0
  credential_values: 0
  unresolved_work_markers: 0
  git_diff_check_exit: 0
  staged_entries: 0
  remaining_e3i_e3l_temp_roots: 0
  E3-L_runtime_or_joint_artifacts: 0
```

The static marker scan intentionally recognizes the fail-closed validator regex and nine
error/policy messages containing the word `incomplete`; these are rejection logic, not
unfinished implementation markers. `git diff --check` emitted only the existing line-ending
notice for `spec/phases/phase-00-foundation.md` and exited zero.

#### Explicit non-claims and mandatory stop

This entry does **not** claim E3-L runtime PASS, FAIL, or BLOCKED_ENVIRONMENT. Static source
identity PASS is not runtime authority. It does not reuse E3-I Attempts 1-4, clear E3-I's
provider block, select a transaction, write L1-L3/conclusion artifacts, transition the
manifest, attempt E3-M, enable parallel execution, or claim Opus agreement. Task 9 and
provider-backed Attempt 5 require one new explicit user authorization after this entry and
its post-entry gates are green.

When quota returns, Opus should challenge at least:

1. every bounded-host source link and exclusion, including whether the seven-link proof is
   sufficient and whether any supported construction path is missing;
2. exact reader/override schemas, parent-cwd revalidation, boolean-only semantics, and the
   claim that reader execute is mutation-free;
3. 11-call A / 5-call B pairing, retry/timeout/provider precedence, and whether semantic FAIL
   correctly remains eligible for the other session;
4. L1-L3 conjunction and source/environment/identity/semantic precedence;
5. proof that E3-I and E3-L consume common raw bytes without importing each other's verdict,
   observation, or conclusion;
6. runner collision checks, no-retry shape, fixed runtime identity, and exactly-one A then
   at-most-one B control flow;
7. deterministic projection's no-transcript/no-caller-observation boundary;
8. READY/BLOCKED/PASS/FAIL validator completeness, hash coherence, circularity, manifest,
   E3-M, and parallel safeguards;
9. every RED/GREEN/debugging claim and every before/after hash in this ledger; and
10. the continued rule that E3-L is observational, E3-M is the enforcement gate, parallel
    remains disabled, and Codex's solo result is provisional pending equal peer review.

Post-entry Task-7.6/Task-8.1 reruns and the final self-referential changelog SHA-256 are
reported outside this entry. No sentence in P00-CX-027 authorizes Task 9.

### P00-CX-027A — Task 9 pre-materialization correction and Attempt 5 raw audit (2026-08-09)

#### Scope, authorization, and predecessor

This append-only addendum records every repository mutation and material execution fact after
P00-CX-027 and before any Task 10 terminal materialization. Its predecessor changelog identity
was:

```yaml
predecessor:
  sha256: 07EC62C42856CFA0EB9878A00A11C4AB340F0E85B1DB752D2F7CA5C48693D5B8
  lines: 3527
  bytes: 185097
authorization:
  user_response: "ok"
  authorized_scope: exactly_one_provider_backed_joint_Attempt_5
  authorized_model_selector: omniroute/codex/gpt-5.6-sol-high
  retry_authorized: false
```

The authorization was not interpreted as permission for Attempt 6, Task 10 materialization,
parallel execution, E3-M, Git staging, a commit, a push, or a manifest transition.

#### Pre-provider direct-entry defect, TDD correction, and exact mutations

The first direct command returned in approximately 0.5 seconds at
`scripts/run-phase00-e3l-joint.ps1:281` with
`Direct joint execution requires -OmpExecutable.` It did so before OMP process creation,
before any provider call, and before any Attempt 5 destination was created. Therefore this
local entry-point failure did not consume the one authorized provider attempt.

Root cause was reproduced without a provider: dot-sourcing `run-phase00-e3i.ps1` executed its
own parameter block in caller scope and reset the joint runner's `Attempt`, `Model`, and
`OmpExecutable` variables to dependency defaults. A behavior-level regression invoked the
real joint entry point with a guaranteed-missing runtime path and proved the broken version
lost the supplied runtime before it reached the existing-runtime check.

```yaml
tdd:
  red:
    suite: scripts/tests/phase00-e3l.Tests.ps1
    passed: 33
    failed: 1
    total: 34
    expected_failure: direct_entry_reported_missing_parameter_instead_of_missing_supplied_path
  correction:
    mechanism: snapshot_joint_CLI_values_before_dependency_dot_source
    behavior: direct_entry_uses_snapshots_only
    function_bodies_changed: false
    retry_logic_changed: false
    provider_logic_changed: false
  focused_green:
    phase00-e3l.Tests.ps1: {passed: 34, failed: 0, total: 34}
  e3i_regression:
    phase00-e3i.Tests.ps1: {passed: 43, failed: 0, total: 43}
mutations:
  scripts/run-phase00-e3l-joint.ps1:
    before_sha256: 7BB02A324E1D0013B5E8F7621A47578A8470A9B874506B09E1E8E44FFE59167F
    before: {lines: 290, bytes: 11617}
    after_sha256: 79229428998D237DE337EF692A06F379A64D36B7613AECB250BED4D300914A97
    after: {lines: 296, bytes: 11853, anchors: "12-14,283-295"}
  scripts/tests/phase00-e3l.Tests.ps1:
    before_sha256: E260F904CE970BA105982F20B09E2AC2FE81D056F4725CF5A4FEA0A2EF5FE939
    before: {lines: 1429, bytes: 64940}
    after_sha256: 34A0BA86BD3807BDBF98AC25C8F72D46A9CD60A3C3B3575CDBB69DD52B4D244D
    after: {lines: 1460, bytes: 66337, anchor: 1200}
```

No other production or test file was changed by this correction.

#### Corrected complete prelaunch gates

All complete suites used a process-local copy whose version and hash were rechecked as
`omp/17.2.10` and
`1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`.

```yaml
per_shell:
  powershell_7_6_4:
    phase00-e3l.Tests.ps1: {passed: 34, failed: 0}
    phase00-e3i.Tests.ps1: {passed: 43, failed: 0}
    phase00-e3a-e3h.Tests.ps1: {passed: 44, failed: 0}
    phase00-wave-a.Tests.ps1: {passed: 26, failed: 0}
    phase00-e3j-e3k.Tests.ps1: {passed: 35, failed: 0}
    aggregate: {passed: 182, failed: 0, total: 182}
    validator: {passed: 90, warnings: 0, failed: 0, exit_code: 0}
  windows_powershell_5_1_26100_8875:
    phase00-e3l.Tests.ps1: {passed: 34, failed: 0}
    phase00-e3i.Tests.ps1: {passed: 43, failed: 0}
    phase00-e3a-e3h.Tests.ps1: {passed: 44, failed: 0}
    phase00-wave-a.Tests.ps1: {passed: 26, failed: 0}
    phase00-e3j-e3k.Tests.ps1: {passed: 35, failed: 0}
    aggregate: {passed: 182, failed: 0, total: 182}
    validator: {passed: 90, warnings: 0, failed: 0, exit_code: 0}
```

Audit noise was preserved rather than silently discarded:

1. One combined PowerShell 7 wrapper was rejected by command safety policy before process
   creation because its inline cleanup contained a recursive removal. No test or provider ran.
   The verified cleanup function already covered by E3-I tests was used instead.
2. The first Windows PowerShell 5.1 wrapper inherited restrictive execution policy, so five
   scripts failed to load and no product assertion ran. Its one verified temporary descendant
   was resolved inside the system temp root and removed with the tested cleanup function. The
   gate was rerun with process-only execution-policy bypass and passed 182/182.
3. One Windows PowerShell validator reporting wrapper let the validator itself pass 90/90 but
   then dereferenced a null captured summary line. The validator was rerun directly and ended
   90/90 with exit code zero. This was wrapper noise, not repository behavior.
4. An initial model-presence expression incorrectly searched the gateway's bare model list for
   the provider-qualified OMP selector. The gateway correctly advertises
   `codex/gpt-5.6-sol-high`; OMP composes that with provider `omniroute` into
   `omniroute/codex/gpt-5.6-sol-high`. The corrected preflight passed without a prompt.

Immediately before the real provider launch, all sixteen expected Attempt 5 destinations were
absent; the gateway returned 183 models and advertised `codex/gpt-5.6-sol-high`; the pinned
source was clean at `3a8591a8af5b6d200088d12ca75a5517cb064fa8` with the official origin,
seven positive links, and six exclusions; live-home metadata was 14 files at SHA-256
`A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4`;
the repository was `main` at `62fecf277dc9d5e47d06319387eac747462214c1`; staged count and disposable-root count were zero.

#### Exactly one real Attempt 5 and preserved raw evidence

The corrected runner made one real provider-backed joint invocation. Session A started at
`2026-08-09T15:51:00.0397509+07:00`, completed at
`2026-08-09T15:57:51.0295426+07:00`, and recorded duration `410990` milliseconds. It did not
time out. Shared selection returned `BLOCKED_ENVIRONMENT` with reason
`P00-RUNTIME-PROVIDER-OVERLOAD`, so Session B was not invoked and the skip reason was
`A_BLOCKED_ENVIRONMENT`. No Attempt 6 was launched.

```yaml
joint:
  status_returned_by_runner: CAPTURED_UNSELECTED
  selected: false
  attempt: 5
  session_a_invoked: true
  session_b_invoked: false
  automatic_retry: false
  e3_i_conclusion_consumed: false
  e3_l_conclusion_consumed: false
  path: docs/evidence/phase-00/E3-L/raw/joint-attempt-005.json
  sha256: BDC3A720531310C7F097A094542597FBCCF6ABAA5E05DA148A7594933B51948C
raw_files:
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.stdout.jsonl:
    sha256: 5F8DF445A52D54E6C48D11D35D75706E435D67B51D2CEB518B4C89F1804F44F0
    bytes: 277075
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.stderr.txt:
    sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
    bytes: 0
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.run.json:
    sha256: 8A2EAFC45F771268FCB872F7ED0D6A278AD1F4217CDC625F0F431FF55CF3230B
    bytes: 3958
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.canary.e3i-project-1.jsonl:
    sha256: 97B8B7C06A57159C9865A06D179C2CE77B7EBA01869C10E4ABD13B328C2B3325
    bytes: 18081
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.canary.e3i-project-2.jsonl:
    sha256: 6A96C0C1A6DCBE0CA37F4A7C6EEBDF0FFE2DC7E786D9BC1F2A1BAC56D2BCE65A
    bytes: 18146
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.canary.e3i-project-3.jsonl:
    sha256: 0CDCAC4964F479BDEC49179A9EB6BEE045208C08FDCD5D0194E22BB7D4E47D16
    bytes: 18202
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.canary.e3i-runtime-1.jsonl:
    sha256: D80867A0744FF62B846170D9CD9E3A28B23F5A2C73BA1B719BE3311A575EE4A1
    bytes: 18277
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.canary.e3i-runtime-2.jsonl:
    sha256: 5940D7F9C9AF277439F5D3F9D213FC7F06115117BBFB32137DF08E5F2268AB21
    bytes: 16974
  docs/evidence/phase-00/E3-I/raw/session-a-attempt-005.canary.e3i-runtime-3.jsonl:
    sha256: 76CD96E3D797C290A2B92358F8800605BF609024E7F6B89C6BF8A13C9D08432B
    bytes: 19443
```

The mechanically preserved set contains ten Attempt 5 files: nine Session A files and one
joint record. All six possible Session B files are absent. Re-audit parsed 796 non-empty JSONL
events with zero parse failures, re-hashed all ten joint references with zero mismatch, found
zero current credential-value matches, and found zero unsanitized disposable-root matches.

#### Raw classification, boundary proof, and unresolved retry-fact defect

The raw outcome is **BLOCKED_ENVIRONMENT before terminal materialization**, not PASS, FAIL, or
selection-eligible. This conclusion comes from structured provider events and the shared
classifier, not from model prose. Parent evidence contains terminal OmniRoute
`server_is_overloaded` failures for `codex/gpt-5.6-sol-high`; terminal capacity failure has
precedence and prevents Session B.

All post-run safety boundaries passed:

```yaml
boundary:
  parent_content_unchanged: true
  parent_head_unchanged: true
  parent_status_unchanged: true
  fixture_hashes_unchanged: true
  live_home_unchanged: true
  live_home_before_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
  live_home_after_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
  cleanup_succeeded: true
  remaining_disposable_roots: 0
  repository_branch: main
  repository_head: 62fecf277dc9d5e47d06319387eac747462214c1
  repository_status_rows_after: 37
  staged_rows_after: 0
  source_status_after: PASS
```

One raw fact remains intentionally open for correction and Opus challenge. Canary
`e3i-runtime-3` contains an assistant error event with `retryRecovery.kind:auto-retry`,
`status:recovered`, `attempt:1`, and a superseding response. Because the transport classifier
returns on the parent terminal overload before it inspects nested canary recovery, the joint
record writes `recovered_provider_retry:false`. Terminal overload precedence still makes the
raw attempt `BLOCKED_ENVIRONMENT`, but the joint field is not a complete statement of the raw
retry facts promised by the plan. Therefore this joint summary must not be treated as a fully
faithful Task 10 terminal adjudication until that projection defect is resolved and covered by
a regression. The preserved raw bytes must not be rewritten, and this addendum does not
authorize a retry.

#### Explicit stop and non-claims

The manifest remains byte-identical at
`89823F3E29C9689A90331A1994AB11D10F7CD2A122B051E0845173BD4A0EEDCA`: E3-I remains its prior
`BLOCKED_ENVIRONMENT`, E3-L remains `READY` with no terminal artifacts, E3-M remains deferred,
and parallel mode remains disabled. No selected transaction, I1-I4/L1-L3 result, conclusion,
Task 10 projection, stage, commit, push, PR, or Opus agreement is claimed. Opus should
independently verify every hash above, the terminal-overload precedence, the recovered nested
retry, and whether a corrected joint fact projection can consume Attempt 5 without changing
raw history.

### P00-CX-028 — Attempt 5 retry-fact correction and terminal blocked materialization

```yaml
timestamp: 2026-08-09T16:32:04+07:00
previous_log:
  sha256: 23AA3622634B2944ADC24BF06B16316C63B48803CFD3E77BC52AA933755430A1
  lines: 3753
  bytes: 196395
authorization:
  user_approved_recommended_task_10_correction: true
  provider_call_performed_in_this_checkpoint: false
  attempt_006_created: false
  raw_attempt_005_rewritten: false
  git_integration_performed: false
scope:
  - fix the joint runner's under-reported recovered-retry projection
  - define a fail-closed corrected-adjudication sidecar contract
  - materialize terminal E3-I and E3-L BLOCKED_ENVIRONMENT evidence from immutable Attempt 5
  - preserve E3-M DEFERRED_PARALLEL_DISABLED and parallel mode DISABLED
terminal_result:
  e3_i: BLOCKED_ENVIRONMENT
  e3_l: BLOCKED_ENVIRONMENT
  e3_m: DEFERRED_PARALLEL_DISABLED
  parallel_mode: DISABLED
  semantic_cases_materialized: 0
  peer_closure: PENDING_OPUS_QUOTA
```

#### Root cause and correction boundary

Attempt 5's raw joint record is immutable at SHA-256
`BDC3A720531310C7F097A094542597FBCCF6ABAA5E05DA148A7594933B51948C`.
Its Session A parent has a terminal OmniRoute `server_is_overloaded` event, while nested
canary `e3i-runtime-3` independently contains one recovered automatic provider retry. The
runner previously derived `recovered_provider_retry` only from the terminal selection reasons.
Because parent-terminal overload wins classification precedence and returns before nested
recovery becomes a selection reason, the raw joint summary under-reported that retry as
`false`. The terminal `BLOCKED_ENVIRONMENT / P00-RUNTIME-PROVIDER-OVERLOAD` classification
was correct; only the orthogonal retry-fact projection was incomplete.

The correction therefore has two deliberately separate parts:

1. Future joint records inspect `Invocation.CanaryEvents` with the existing recovered-provider
   helper before falling back to selection reasons. This changes neither terminal precedence,
   retry policy, selection eligibility, nor provider execution.
2. Historical Attempt 5 is not rewritten. A `.adjudication.json` sidecar hash-links the raw
   joint record and states exactly `E3IL_RETRY_FACT_UNDER_REPORTED`. The validator accepts this
   form only when the immutable predecessor exists, its hash matches, the reason is exact, and
   Session A records `recovered_provider_retry: true`.

#### Test-first evidence

```yaml
tdd_cycles:
  future_runner_projection:
    red: {suite: phase00-e3l.Tests.ps1, passed: 34, failed: 1, total: 35, observation: expected_true_got_false}
    green: {passed: 35, failed: 0, total: 35}
  corrected_sidecar_positive_contract:
    red: {suite: phase00-e3l.Tests.ps1, passed: 34, failed: 1, total: 35, observation: validator_rejected_corrected_filename}
    green: {passed: 35, failed: 0, total: 35}
  corrected_sidecar_negative_controls:
    controls: [missing_immutable_predecessor, bad_predecessor_hash, wrong_correction_reason, recovered_retry_false]
    red: {suite: phase00-e3l.Tests.ps1, passed: 35, failed: 1, total: 36, observation: rejected_0_of_expected_4}
    green: {passed: 36, failed: 0, total: 36}
  attempt_005_e3_i_artifacts:
    red: {suite: phase00-e3i.Tests.ps1, passed: 43, failed: 2, total: 45, observation: missing_attempt_005_adjudication_and_stale_conclusion}
    green: {passed: 45, failed: 0, total: 45}
  real_e3_l_terminal_artifacts:
    green: {suite: phase00-e3l.Tests.ps1, passed: 37, failed: 0, total: 37}
  wave_a_fixture_regression:
    first_complete_gate: {passed: 186, failed: 1, total: 187}
    focused_red: {suite: phase00-wave-a.Tests.ps1, passed: 25, failed: 1, total: 26}
    root_cause: test mutation still anchored E3-L READY after the legitimate terminal transition
    correction: anchor the DEFERRED-negative fixture on E3-L BLOCKED_ENVIRONMENT
    production_validator_changed_for_this_failure: false
    focused_green: {passed: 26, failed: 0, total: 26}
```

#### Exact mutations

```yaml
modified:
  scripts/run-phase00-e3l-joint.ps1:
    before: {sha256: 79229428998D237DE337EF692A06F379A64D36B7613AECB250BED4D300914A97, lines: 296, bytes: 11853}
    after: {sha256: E14C3444583518491E209F6B8901F9BE1815EBC1D49A078B3F6E14F35C7ADCE7, lines: 310, bytes: 12469, anchors: "165-176,196"}
    reason: project nested recovered-provider facts independently of terminal selection precedence
  scripts/lib/phase00-evidence.ps1:
    before: {sha256: 7A0F4325BCCDE50B5818490CF23BC7AB56CBF82AFF9E110614714B4478CF2D38, lines: 793, bytes: 39531}
    after: {sha256: EFCCD7C2848A55852A8701F0622864FF3DF9BDBD9194AF33BF3035F98A294C5D, lines: 807, bytes: 40357, anchors: "414-466"}
    reason: accept and fail-closed validate the corrected blocked-adjudication sidecar
  scripts/tests/phase00-e3l.Tests.ps1:
    before: {sha256: 34A0BA86BD3807BDBF98AC25C8F72D46A9CD60A3C3B3575CDBB69DD52B4D244D, lines: 1460, bytes: 66337}
    after: {sha256: D207A59FD9A5C228EC3AB190C18C4E21A4CD4DA67C00811E3BC8F25EE4BF020A, lines: 1563, bytes: 71708, anchors: "438-450,1141-1184,1385-1407"}
    reason: regression, positive-sidecar, four negative-control, and real-artifact coverage
  scripts/tests/phase00-e3i.Tests.ps1:
    before: {sha256: 9D7843AE18CD5E12BE19095C8211DF35671B90896299DC2004F94B0091ADA22C, lines: 1691, bytes: 75075}
    after: {sha256: B086C8E3CD54056106A6E466E60CD1A72715269476DE5C78762B4E0C5641D950, lines: 1734, bytes: 77579, anchors: "1625-1666,1668-1733"}
    reason: preserve Attempt 4 and require hash-coherent terminal Attempt 5 without partial I1-I4 claims
  scripts/tests/phase00-wave-a.Tests.ps1:
    before: {sha256: C9CE99B9FF47ECE40208EBFAB03899AEEB84E09984303A26953FCED2A5F62A0E, lines: 348, bytes: 16342}
    after: {sha256: 6E947B4D7540D6839028CD12A07B51ED8528717A3610CCA6658BED005D053F51, lines: 348, bytes: 16356, anchor: 198}
    reason: fixture-only anchor maintenance after E3-L terminal transition
  docs/evidence/phase-00/manifest.yml:
    before: {sha256: 89823F3E29C9689A90331A1994AB11D10F7CD2A122B051E0845173BD4A0EEDCA, lines: 179, bytes: 5055}
    after: {sha256: 611A95BD00DA30CD99DDF64BC9B545BAFEA0593A1E4F2B0A52A920C1B29E5F36, lines: 179, bytes: 5254, anchors: "110-113,128-131"}
    transitions:
      e3_i: BLOCKED_ENVIRONMENT -> BLOCKED_ENVIRONMENT
      e3_l: READY -> BLOCKED_ENVIRONMENT
      e3_m: DEFERRED_PARALLEL_DISABLED -> DEFERRED_PARALLEL_DISABLED
  docs/evidence/phase-00/E3-I/conclusion.yml:
    before: {sha256: 4CBBDCFDDBC4991D5D4BDA0E76F44FBC2557FB3C96E7A4DB7732B866482C82E5, lines: 42, bytes: 1901}
    after: {sha256: E8D3016DD4A6665E194CA822481296E9648C111FC0536B73FE2F008F6E73D546, lines: 49, bytes: 2268}
    reason: add Attempt 5 terminal history and nested-retry/parent-precedence distinction
  docs/superpowers/specs/2026-08-09-phase-00-e3l-live-session-reader-design.md:
    before: {sha256: F0E2573C27E18D3EE74E055BAEDE1910CD79CE297A68F0DC4C0475A8950595A3, lines: 404, bytes: 22512}
    after: {sha256: 274FBA02956F64FFBE34534C53CA6B56BEAAAEDE10C0C7C188D42F8F38650B8F, lines: 422, bytes: 23532, anchors: "3,356-377"}
    reason: record terminal Attempt 5 status, immutable raw correction, and non-claims
  docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md:
    before: {sha256: 36E43AEAFA53C099A1D93F053F0EBB358C81505E147FA886F4B0AC410C8719F2, lines: 610, bytes: 30616}
    after: {sha256: 57091C7D149B3154B39CED82E7348FD02EEC898BA61E7E7ECBF0861BEA0C7E2E, lines: 620, bytes: 31313, anchors: "31-39"}
    reason: append the joint Attempt 5 runtime update while preserving prior attempts
created:
  docs/evidence/phase-00/E3-L/raw/joint-attempt-005.adjudication.json:
    sha256: C1D2307FDC3237477D50CA3C309A17E6A42EC9E2539A0D41D822180737BF0B5D
    lines: 108
    bytes: 4115
    purpose: immutable-joint correction sidecar and terminal joint adjudication
  docs/evidence/phase-00/E3-L/conclusion.json:
    sha256: 0BC95B726B10EDCC79BFB44247F4C02C585939A72E3B0D279071851C20AB28E6
    lines: 41
    bytes: 1505
    purpose: E3-L terminal blocked conclusion with zero L1-L3 materialization
  docs/evidence/phase-00/E3-I/raw/session-a.attempt-005.adjudication.json:
    sha256: BB7F7395441B1ED7C6E4DF3B56433BD9C50A633F4CE943005D8B8E814239626C
    lines: 120
    bytes: 4130
    purpose: E3-I terminal blocked interpretation of the joint Session A raw set
```

E3-I manifest artifacts are now exactly
`session-a.attempt-005.adjudication.json` plus `conclusion.yml`, with decision
`Attempt 5 joint Session A terminal provider overload; no selected transaction or Session B`.
E3-L artifacts are exactly `joint-attempt-005.adjudication.json` plus `conclusion.json`, with
decision `Attempt 5 parent-terminal provider overload; no selected transaction or L1-L3
materialization`. No I1-I4 or L1-L3 file exists.

#### Immutable raw hashes and independent replay

The terminal records re-hash the same raw set already pinned in P00-CX-027A. For direct review:

```yaml
joint_attempt_005: BDC3A720531310C7F097A094542597FBCCF6ABAA5E05DA148A7594933B51948C
session_a_run: 8A2EAFC45F771268FCB872F7ED0D6A278AD1F4217CDC625F0F431FF55CF3230B
session_a_stdout: 5F8DF445A52D54E6C48D11D35D75706E435D67B51D2CEB518B4C89F1804F44F0
session_a_stderr: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
canaries:
  e3i-project-1: 97B8B7C06A57159C9865A06D179C2CE77B7EBA01869C10E4ABD13B328C2B3325
  e3i-project-2: 6A96C0C1A6DCBE0CA37F4A7C6EEBDF0FFE2DC7E786D9BC1F2A1BAC56D2BCE65A
  e3i-project-3: 0CDCAC4964F479BDEC49179A9EB6BEE045208C08FDCD5D0194E22BB7D4E47D16
  e3i-runtime-1: D80867A0744FF62B846170D9CD9E3A28B23F5A2C73BA1B719BE3311A575EE4A1
  e3i-runtime-2: 5940D7F9C9AF277439F5D3F9D213FC7F06115117BBFB32137DF08E5F2268AB21
  e3i-runtime-3: 76CD96E3D797C290A2B92358F8800605BF609024E7F6B89C6BF8A13C9D08432B
classifier_replay:
  parent_events: 735
  canary_events: 6
  e3_i: {status: BLOCKED_ENVIRONMENT, reason: P00-RUNTIME-PROVIDER-OVERLOAD}
  shared_transport: {status: BLOCKED_ENVIRONMENT, reason: P00-RUNTIME-PROVIDER-OVERLOAD}
  selection: {status: BLOCKED_ENVIRONMENT, reason: P00-RUNTIME-PROVIDER-OVERLOAD}
  recovered_retry_canaries: [e3i-runtime-3]
```

Thus two independent classifiers agree on the terminal block, and independent raw inspection
finds the nested recovered retry. These facts coexist; neither overrides the other.

#### Verification and integrity

After all production, artifact, documentation, manifest, and fixture changes—and before this
append-only ledger entry—the complete cross-shell result was:

```yaml
per_shell:
  powershell_7_6_4:
    phase00-e3l.Tests.ps1: {passed: 37, failed: 0}
    phase00-e3i.Tests.ps1: {passed: 45, failed: 0}
    phase00-e3a-e3h.Tests.ps1: {passed: 44, failed: 0}
    phase00-wave-a.Tests.ps1: {passed: 26, failed: 0}
    phase00-e3j-e3k.Tests.ps1: {passed: 35, failed: 0}
    aggregate: {passed: 187, failed: 0, total: 187}
    validator: {passed: 90, warnings: 0, failed: 0, exit_code: 0}
  windows_powershell_5_1_26100_8875:
    phase00-e3l.Tests.ps1: {passed: 37, failed: 0}
    phase00-e3i.Tests.ps1: {passed: 45, failed: 0}
    phase00-e3a-e3h.Tests.ps1: {passed: 44, failed: 0}
    phase00-wave-a.Tests.ps1: {passed: 26, failed: 0}
    phase00-e3j-e3k.Tests.ps1: {passed: 35, failed: 0}
    aggregate: {passed: 187, failed: 0, total: 187}
    validator: {passed: 90, warnings: 0, failed: 0, exit_code: 0}
integrity:
  json: {files: 6, parse_failures: 0}
  jsonl: {files: 7, events: 796, parse_failures: 0}
  e3_l_reference_hash_mismatches: 0
  e3_i_raw_hash_mismatches: 0
  original_joint_hash_unchanged: true
  forbidden_selected_artifacts: 0
  yaml_documents_parsed: 2
  scoped_modified_powershell_files: 11
  scoped_parse_failures_pwsh7: 0
  scoped_parse_failures_windows_ps51: 0
  trailing_whitespace_findings: 0
  credential_value_matches: 0
  unsanitized_disposable_root_matches: 0
  live_home_sha256: A2CDAAE6F4C503143E09E826A0B6C44704386A7781E6D12660188407FE526DB4
  live_home_unchanged: true
  pinned_source: PASS_CLEAN
  remaining_disposable_roots: 0
  staged_files: 0
  git_diff_check_exit_code: 0
```

Two audit-harness facts are disclosed. A repository-wide Windows PowerShell parser sweep found
pre-existing syntax incompatibilities in `scripts/benchmark.ps1` and
`scripts/uninstall-template.ps1`; neither file belongs to this Phase 00 mutation set, and both
were left unchanged. The scoped eleven-file parse gate is clean in both shells. Also, the first
integrity wrapper omitted the evidence-helper dot-source and stopped before running its audit;
it mutated nothing and was rerun with the helper loaded to produce the integrity result above.

The first fresh post-ledger gate exposed the user's previously disclosed installed-OMP update:
the default command now resolves `omp/17.2.12`, so the A1 end-to-end pin check correctly failed
and the aggregate was 186/187; all other tests passed and the validator remained 90/90. The
contract was not relaxed and the installed runtime was not modified. The gate was rerun through
a process-local copy of the preserved executable whose SHA-256 is
`1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6` and whose version is
exactly `omp/17.2.10`; both PowerShell 7 and Windows PowerShell 5.1 then passed 187/187 plus
validator 90/90. Two combined wrappers containing cleanup were rejected by command policy
before process creation. The accepted wrapper performed no inline deletion; afterward its
verified single-file system-temp directory was removed non-recursively through .NET file and
directory APIs because the shell deletion command remained policy-blocked. No repository or
runtime-installation file was changed by this harness handling.

#### Non-claims and equal-peer challenge targets

This checkpoint terminally represents the current execution round; it does not claim semantic
E3-I/E3-L PASS, joint Codex/Opus closure, Phase 00 completion, or permission to enable parallel
mode. No provider invocation, automatic outer retry, Attempt 6, raw rewrite, stage, commit,
branch, push, or PR occurred. Repository remains `main` at
`62fecf277dc9d5e47d06319387eac747462214c1`, with 37 disclosed dirty status rows and zero staged
files.

Opus should independently challenge: (1) whether parent-terminal overload must retain
precedence over the nested recovered retry; (2) whether the sidecar's immutable-predecessor
hash, exact correction reason, and `true` retry fact are sufficient and no broader correction
form should be accepted; (3) whether E3-I and E3-L may legally consume the same joint transport
while keeping separate conclusions; (4) every raw and derived hash above; (5) the absence of
I1-I4/L1-L3 claims; (6) the E3-L `READY -> BLOCKED_ENVIRONMENT` manifest transition; and (7)
continued E3-M/parallel disablement. Codex's adjudication remains provisional until equal Opus
review is available.
