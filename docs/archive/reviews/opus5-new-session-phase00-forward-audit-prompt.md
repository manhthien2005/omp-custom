# Prompt for Claude Opus 5 — Independent Phase 00 Forward Audit

You are Claude Opus 5 starting a fresh session as Codex's equal technical peer on the
`omp-template` repository. Neither model is authoritative by reputation. Accept, reject, or
replace a position only from repository evidence.

## 1. Mission

Go first. Perform an independent, evidence-first audit of the current Phase 00 state and decide
what work should happen next. Codex will review your audit afterward and may agree, challenge it,
or request corrections. Do not optimize for agreement with Codex.

This is a review and design pass, not an implementation pass.

Your deliverables are:

1. Decide whether the P00-CX-028 evidence correction is a trustworthy foundation.
2. Reconstruct the current Phase 00 authority state from the manifest and linked artifacts.
3. Identify the highest-value dependency-safe next scope.
4. If T-00.3 is that scope, independently derive and pressure-test its policy re-homing design.
5. Give Codex a precise, bounded implementation recommendation with acceptance evidence.

## 2. Repository and mutation boundary

Repository root:

`D:\Dev\Projects\omp-template`

Review the repository in place. The worktree is intentionally dirty and contains user-owned and
prior Codex changes. Do not clean, reset, stage, commit, push, switch branches, or create a
worktree.

Do not:

- modify template, spec, registry, script, test, manifest, or evidence files;
- call any model provider or create another Phase 00 runtime attempt;
- install or modify live OMP configuration;
- reinterpret `BLOCKED_ENVIRONMENT` as semantic PASS or FAIL;
- enable parallel execution or advance E3-M authority;
- implement T-00.3 or any later task.

The only permitted filesystem write is your final audit response:

`D:\Dev\Projects\omp-template\opus5-phase00-forward-audit.md`

If you cannot safely create that file, return the same content in chat and make no filesystem
changes.

## 3. Frozen integrity anchors

Treat these files as immutable review inputs and verify their SHA-256 values before relying on
them:

| File | Expected SHA-256 |
| --- | --- |
| `codex-phase00-execution-changelog-for-opus5.md` | `476075901D51C66EB8341AC977A58C21E6B82D031E5C5EC52CF76D4F0798F63A` |
| `opus5-review-packet-codex-p00-cx-028.md` | `ACFF1179046B2F0971757182BE5ED39F9002D16BADEA7A20700928E404AC8CF4` |
| `opus5-review-prompt-codex-p00-cx-028.md` | `49DB7B55F30541393C68B78504D0B2A38E2CB6CFC5C330133ECC92570A828C8B` |

If the compact packet or full ledger hash differs, report `INTEGRITY_BLOCKED` and do not infer
their intended content from memory. A mismatch in the old review prompt is reportable but does
not by itself invalidate independently verifiable repository evidence.

At the handoff boundary, the claimed authority state is:

- E3-I: `BLOCKED_ENVIRONMENT`;
- E3-L: `BLOCKED_ENVIRONMENT`;
- E3-M: not completed and not authorized by this audit;
- `parallel_mode`: `DISABLED`;
- T-00.3: `READY` and not implemented;
- no T-00.3 design, plan, test, reference-policy directory, evidence conclusion, or continuation
  ledger has been written.

Verify rather than trust those claims.

## 4. Mandatory read order

Use progressive disclosure. Do not read the full 4,010-line ledger unless a compact claim needs
drill-down.

1. `opus5-review-packet-codex-p00-cx-028.md`
2. `docs/evidence/phase-00/manifest.yml`
3. The P00-CX-028 load-bearing artifacts named by the compact packet
4. `spec/phases/phase-00-foundation.md`, focusing on T-00.3, dependencies, deliverables, and exit
   criteria
5. `spec/key/04-decision-log.md`, focusing on KD-001
6. `spec/key/03-token-quality-model.md`, focusing on policy/schema placement and budget semantics
7. `spec/04-workflow-sizing.md`
8. `spec/07-retrieval-and-code-understanding.md`, focusing on progressive retrieval
9. `spec/11-skills-rules-and-quality-gates.md`, focusing on quality-gate delivery
10. `spec/13-validation-and-evaluation.md`, focusing on L0 dangling-reference and budget checks
11. `spec/16-migration-plan.md`, focusing on Phase 00 versus Phase 01 boundaries
12. Current consumers and operational surfaces, only as needed:
    - `template/.omp/AGENTS.md`
    - `template/.omp/RULES.md`
    - `template/.omp/agents/*.md`
    - `template/.omp/commands/*.md`
    - `template/.omp/config.yml`
    - `template/.omp/policies/*.yml`
    - `scripts/install-template.ps1`
    - `scripts/validate-template.ps1`
    - `registry/upstreams.yml`
    - `registry/adoption-ledger.yml`
    - `registry/licenses.yml`
    - current non-research product documentation
13. `codex-phase00-execution-changelog-for-opus5.md` only for unresolved P00-CX-028 drill-down:
    - P00-CX-027A: lines 3529-3754
    - P00-CX-028: lines 3755-4010

Historical research, prior model debate files, and `.claude/worktrees/**` are not current runtime
authority. Use them only when a live normative file explicitly depends on them.

## 5. Audit A — P00-CX-028 foundation gate

Independently falsify this chain:

```text
Attempt 5 raw events
  -> parent-terminal and nested-retry facts
  -> immutable raw joint record
  -> corrected adjudication sidecar
  -> independent E3-I and E3-L conclusions
  -> manifest authority states
```

Check at minimum:

- top-level and linked artifact hashes;
- terminal-overload precedence;
- whether the recovered nested retry was preserved without inventing an outer retry or Attempt 6;
- immutability of the original joint record;
- sidecar correction and hash invariants;
- independence of E3-I and E3-L conclusions;
- legality of both `BLOCKED_ENVIRONMENT` materializations;
- absence of selected I1-I4/L1-L3 semantic claims;
- continued E3-M deferral and parallel disablement.

Return one foundation-gate verdict:

```text
ACCEPT_P00_CX_028_FOUNDATION
REOPEN_P00_CX_028
INTEGRITY_BLOCKED
```

If this gate is `REOPEN` or `INTEGRITY_BLOCKED`, continue only with observations that do not rely
on the disputed authority. Mark the forward recommendation `HOLD`.

## 6. Audit B — Phase 00 state and dependency graph

Reconstruct the state from `manifest.yml`; do not repeat the phase document as narrative.

For every non-terminal row relevant to the next action, report:

- current state;
- direct dependencies and their states;
- whether the task is statically executable, provider-dependent, or authority-blocked;
- exact reason it is or is not safe to start;
- the smallest artifact that would prove completion.

Challenge the assumption that T-00.3 is necessarily next. Select it only if the manifest,
dependencies, scope boundaries, and current repository state support that conclusion. If another
task should precede it, name that exact task and provide evidence.

Do not recommend work merely because it is easy. Prefer the next scope that improves the
foundation without depending on blocked provider evidence or prematurely implementing a later
phase.

## 7. Audit C — Independent T-00.3 design, only if recommended

If T-00.3 is the correct next scope, derive the design from the repository before evaluating any
Codex position. Treat the five existing YAML files as potentially stale sources, not automatically
as current normative authority.

Resolve all of these questions:

1. Which current spec wins when a policy YAML conflicts with a later normative decision?
2. What exact runtime consumer receives each load-bearing rule?
3. Which content belongs in zero-runtime-cost documentation?
4. Are three reference documents sufficient, or is another reference artifact justified?
5. How must main-session escalation differ from worker-to-main escalation?
6. Which commands actually dispatch workers and therefore consume model-routing rules?
7. How does the installer stop advertising a removed component?
8. Which current product docs become false immediately after removal?
9. Which registry paths remain as historical `superseded_paths`, and which `local_components`
   must change?
10. What validator behavior proves the installed surface has no dangling policy reference without
    erasing historical evidence?
11. What RED-to-GREEN tests demonstrate the validator catches real regressions rather than merely
    grepping one preferred sentence?
12. What evidence artifact and hashes make deletion of the five sources auditable later?
13. What belongs to T-00.4, T-00.5, or Phase 01 and must remain out of scope?
14. Can T-00.3 honestly claim exact token-budget enforcement while the validator uses `chars / 4`?

Explicitly reconcile at least these known tension points:

- `workflow-sizing.yml` larger-workflow tie breaking versus the independence boundary in
  `spec/04-workflow-sizing.md`;
- quality-gate defaults versus Standard's risk-based Reviewer dispatch;
- the inactive custom `tech-lead` abstraction versus the main OMP session's Tech Lead role;
- provenance requirements versus the prohibition on a `policies/` path in runtime prompts;
- static token thresholds versus the later real-tokenizer requirement.

Do not silently choose between conflicting contracts. State the conflict, authority rule,
resolution, and consequence.

## 8. Finding quality bar

Order findings by `Critical`, `Important`, then `Minor`.

Every Critical or Important finding must include:

- rejected claim or unsafe assumption;
- exact repository evidence (`path:line`, YAML path, JSON path, or hash);
- observed fact;
- governing contract;
- impact on authority, safety, correctness, or reproducibility;
- smallest exact correction.

Do not report:

- style preferences;
- broad hypothetical risks with no reachable failure path;
- stale research text as though it were installed runtime behavior;
- test results as proof when the underlying artifact contradicts them;
- praise, deference, or model-ranking commentary.

Separate verified fact, inference, and recommendation explicitly.

## 9. Required response format

Write `opus5-phase00-forward-audit.md` with exactly these top-level sections:

```markdown
# Opus 5 — Independent Phase 00 Forward Audit

## 1. Executive verdict
- P00-CX-028 foundation gate: <ACCEPT_P00_CX_028_FOUNDATION | REOPEN_P00_CX_028 | INTEGRITY_BLOCKED>
- Forward work: <PROCEED | HOLD>
- Recommended next scope: <exact task ID or NONE>
<three to six decisive sentences>

## 2. Integrity and authority audit
| Check | Expected | Observed | Result | Evidence |
| --- | --- | --- | --- | --- |
<load-bearing checks only>

## 3. Current Phase 00 state
| Task/experiment | State | Dependencies | Executable now? | Evidence required |
| --- | --- | --- | --- | --- |
<only rows relevant to the next decision>

## 4. Findings
<None, or evidence-backed findings ordered Critical -> Important -> Minor>

## 5. Recommended next-scope design
### Scope
### Source-of-authority rules
### Source-to-consumer mapping
### Validator and RED-to-GREEN evidence
### Documentation, installer, and registry effects
### Explicit exclusions

## 6. Acceptance matrix
| Requirement | Planned evidence | Failure condition |
| --- | --- | --- |
<mechanically checkable rows>

## 7. Decisions Codex must challenge
| # | Provisional decision | Strongest evidence | Reversal condition |
| --- | --- | --- | --- |
<the smallest set of genuinely disputable decisions>

## 8. Recommended next action
<one concrete action only>
```

If T-00.3 is not recommended, Section 5 must describe the actual recommended task rather than
forcing a T-00.3 design.

## 10. Token discipline and collaboration rule

- Target 1,800-3,000 words.
- Do not summarize the whole project or reproduce long policy files.
- Quote no more than needed to establish a disputed fact.
- Prefer tables and exact anchors over narrative history.
- Do not write an implementation changelog because no implementation is authorized.
- Mark all design decisions `PROVISIONAL_PENDING_CODEX_REVIEW`.

Opus goes first in this round, but Opus does not close the issue unilaterally. Codex will perform a
fresh counter-audit of this output. Work proceeds only after the user approves the reconciled
position.
