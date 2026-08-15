# Phase 00 T-00.3 Authoritative Policy Re-homing Design

Date: 2026-08-09  
Status: **PROVISIONAL — approved in conversation; written-spec review pending**  
Implementation authority: none until the user approves this written spec  
Future peer review: Opus 5, equal authority with Codex

## 1. Objective

Replace the stale `.omp/policies/` implementation with one traceable implementation
derived from the current normative spec and Phase 00 contract.

This is an authoritative rebuild, not an additive patch:

- remove the five inert policy YAML files from the installed OMP surface;
- preserve each useful contract in the runtime consumer that can actually act on it;
- retain only the minimum human-reference material under `docs/policies/`;
- remove direct installer, validator, registry, and product-documentation claims that the
  retired runtime component still exists;
- prove the result with RED-to-GREEN tests, mutation controls, a hash-bearing evidence
  artifact, and a Phase 00 manifest transition;
- leave a complete English changelog for later independent Opus review.

The desired end state has one live implementation per contract. No `.old`, legacy copy,
parallel policy implementation, or undocumented fallback remains in the repository.

## 2. Why T-00.3 is the next slice

`docs/evidence/phase-00/manifest.yml` records T-00.3 as `READY` with no dependencies.
It is provider-free and independent of the still-provisional P00-CX-028 disposition.

The plausible alternatives are not equally executable:

- T-00.4 depends on E1, which is only `READY`.
- E3-I and E3-L require a separately authorized provider-backed retry to reach terminal
  evidence.
- E3-M is optional, deferred, and must remain disabled unless its full guarded-dispatch
  contract is attempted and passes.
- A repository-wide rewrite would cross unresolved Phase 00 dependencies and destroy the
  ability to attribute failures to one gate.

T-00.3 is therefore the smallest dependency-safe cleanup that removes a known false runtime
surface without pretending that Phase 00 or the product is complete.

## 3. Governing authority and conflict rule

The implementation must use this authority order:

1. `spec/key/04-decision-log.md`, KD-001;
2. `spec/phases/phase-00-foundation.md`, T-00.3;
3. the subsystem contracts in `spec/04`, `spec/05`, `spec/09`, `spec/11`, and `spec/15`;
4. verified OMP source/runtime facts already recorded by Phase 00;
5. the five existing policy YAML files as historical input only;
6. current template files and product documentation.

When an old YAML clause conflicts with a higher source, the implementation must not copy the
clause. The evidence record must mark it `SUPERSEDED`, name the higher authority, and state the
replacement. Useful old content that does not conflict is marked `REHOMED` and mapped to an
exact consumer.

Historical review packets, specs, raw runtime evidence, adjudication sidecars, and Git history
remain immutable audit material. “Clean up the old implementation” never means deleting the
record that proves why it was replaced.

## 4. Locked pre-state

OMP has no discovery hook or runtime consumer for `policies/`; the only executable touchpoint
is the repository validator, which checks existence and `Trim().Length > 10` without parsing
or consuming policy semantics.

The five tracked source files contain 363 physical lines:

| Source | Lines | SHA-256 | Git blob |
|---|---:|---|---|
| `template/.omp/policies/context-budget.yml` | 89 | `A3FE19A6C131F3A9F43EF2AC5156993437CDC07B0ABE6AF284FE6E966C2F03EE` | `f5591a7b7cd3e06efbd5431536ebd2391bdedd6d` |
| `template/.omp/policies/escalation.yml` | 52 | `49CB215BEEC2424C9274BBA285E2AD28B651A124AF1BF07102A925FDAEA5FD1F` | `c8e51d31baed0b2ce7ee000bd0be5deb3858e691` |
| `template/.omp/policies/model-routing.yml` | 61 | `67E7F80534AB66C57B13EF91AD88CABAE5518F8828E89C496B78AB9C4209F4A2` | `c73070c1e73737a6947b48eb84338b583e4aa663` |
| `template/.omp/policies/quality-gates.yml` | 105 | `69A8635F66C118D5BC12612E7D7B6F498E1886B7213F15613BE5A37B6370A1E2` | `47f6d06191a9e7b68f07da1903d96b931024fa30` |
| `template/.omp/policies/workflow-sizing.yml` | 56 | `603112590C993F9DEC61D17C32387C040C775C384B1D8656756170971703671B` | `195c1f836bfd62381099cd9633073db4a37c88bc` |

The registry already names future Markdown destinations for context budget, model routing,
and quality gates, but those files are absent. This is a predeclared target, not evidence that
re-homing has happened.

## 5. Source-to-consumer design

### 5.1 Context budget

Create `docs/policies/context-budget.md` as the non-runtime reference for:

- the seven provisional component budget ranges;
- packet/result content prohibitions;
- progressive retrieval guidance;
- filesystem-offload thresholds and their isolation limitation;
- explicit non-claim that these numbers are empirically optimal.

Runtime delivery is split by owner:

- packet construction rules live in the main-session command/AGENTS surface;
- compact-result and no-transcript rules live in worker prompts;
- static component thresholds live in `scripts/validate-template.ps1`.

The validator's current `chars / 4` calculation is an approximation. For the three categories
that `spec/05` assigns to static validation (`AGENTS.md`, `RULES.md`, and agent prompts),
T-00.3 must encode and name the documented target-minimum, target-maximum, and hard-warning
thresholds while describing every result as advisory. Skill description/body values remain
reference guidance because more-specific skill contracts can override the generic range;
task-packet and worker-result values remain runtime prompt contracts. Real tokenizer
enforcement remains outside this slice.

### 5.2 Model routing

Create `docs/policies/model-routing.md` as the non-runtime reference. It must distinguish:

- required worker aliases: `explorer`, `implementer`, `verifier`, `reviewer`;
- optional user-owned `tech-lead` alias;
- role selection from the environment-specific concrete model mapping;
- the verified custom-role mechanism from the unresolved E2 fallback behavior;
- OmniRoute-only and no-silent-fallback constraints from portable model identifiers.

`standard.md` and `orchestrated.md` receive compact dispatch rules: dispatch named workers,
let agent frontmatter plus `config.yml` resolve the role, do not hard-code a model in a command,
and do not change routing mid-session. The old five-required-role and concrete-model-as-design
claims are `SUPERSEDED`, not copied.

### 5.3 Workflow sizing

No new standalone workflow-sizing reference is needed because `spec/04-workflow-sizing.md`
already owns the reconciled decision.

The three commands retain their local “when to use / not use” contract and receive a concise
provenance marker naming `workflow-sizing.yml`. Their decisive rules are:

- Quick to Standard: the change target is not known before inspection, or scope expands;
- Standard to Orchestrated: at least two genuinely independent workstreams exist;
- size alone never authorizes Orchestrated;
- escalation restarts at the larger workflow; de-escalation is not allowed.

The old YAML rule “select the larger workflow when in doubt” is `SUPERSEDED` because it
contradicts the independence boundary in `spec/04`.

The `policy:workflow-sizing` reference in `tech-lead.md` must be removed. T-00.3 does not,
however, resolve the separately phased removal of the discoverable Tech Lead agent.

### 5.4 Quality gates

Create `docs/policies/quality-gates.md` containing the human-readable definitions, triggers,
checks, override rule, provenance, and non-runtime status.

Inline the load-bearing risk matrix into `standard.md` and `orchestrated.md`:

| Risk | Gates |
|---|---|
| LOW | none |
| MEDIUM | security |
| HIGH | api-compatibility, security, performance, release-readiness, rollback-readiness |
| CRITICAL | all HIGH gates plus adr-documentation |

The main session selects gates while constructing the task packet. The Reviewer applies the
selected gates; it does not invent new gates. Reviewer scheduling remains controlled by
`spec/04` and `spec/10`: risk-based in Standard and mandatory in Orchestrated. The matrix must
not be misread as “always dispatch a Reviewer for every MEDIUM task.”

### 5.5 Escalation

No standalone escalation reference is needed. Its two audiences receive different contracts:

- worker-to-main conditions go into the relevant worker `Must not`/stop-and-return sections;
- main-to-user conditions go into the persistent main-session instruction surface, not a
  spawned Tech Lead agent.

Role-specific outcomes remain structured:

- implementation verification failure -> `failed` with evidence;
- required scope expansion or unmet dependency -> `blocked`;
- root cause unresolved after the bounded investigations -> `partial`, never a guess;
- blocking review issue -> `CHANGES_REQUESTED`;
- credentials, destructive action, critical risk, or required architecture violation -> stop
  and request user authority.

Minor syntax choices with an existing convention are not escalation conditions.

## 6. Documentation layout

Create exactly four files under `docs/policies/`:

1. `README.md` — directory status and five-source disposition index;
2. `context-budget.md` — reference contract;
3. `model-routing.md` — reference contract;
4. `quality-gates.md` — reference contract.

The index maps workflow sizing to `spec/04` plus the three commands, and escalation to the
worker prompts plus main-session instructions. Separate Markdown copies for those two would
create a second human authority with no consumer and are intentionally omitted.

Every reference file must say that `docs/policies/` is human documentation and is not loaded
by OMP. Every inlined consumer carries a provenance comment naming the retired YAML basename,
without placing a `policies/` path in a runtime prompt.

## 7. Installed-surface cleanup

Delete the five tracked YAML files and the now-empty `template/.omp/policies/` directory.

Remove policy runtime claims from:

- required-file and non-empty-YAML validation;
- installer default components and component mapping;
- current product layout, installation, customization, architecture, workflow, security,
  report, and changelog documentation;
- runtime command and agent references.

An explicit legacy installer request for component `policies` must fail with a concise retired-
component explanation. Silently planning zero files would repeat the original false-success
failure mode.

Historical research and adversarial-review documents may retain old paths as historical facts.
They must not be rewritten to look current, and the runtime dangling-reference validator must
not scan them as though they were installed prompts.

## 8. Validator and test design

Add a focused Pester suite at `scripts/tests/phase00-t003.Tests.ps1` and a durable
`Test-Phase00T003PolicyRehomingContract` in `scripts/lib/phase00-evidence.ps1`. Register the
contract through `scripts/validate-template.ps1`.

The contract must verify:

1. `template/.omp/policies/` is absent.
2. Installed agent and command prompts contain neither `policy:` nor a `policies/` path.
3. All four `docs/policies/` files exist, declare non-runtime status, and carry provenance.
4. The three reference contracts contain their required canonical facts.
5. The three commands contain the corrected sizing boundaries; Standard and Orchestrated
   contain the exact quality-gate matrix and routing rule.
6. Worker/main-session escalation outcomes are mapped to the correct owner.
7. The installer neither advertises nor silently accepts the retired component.
8. The main validator no longer requires or performs non-empty checks on deleted policy YAML.
9. Registry `local_components` resolve and old YAML paths remain only under explicit
   `superseded_paths` or historical fields.
10. Direct product documentation does not advertise policies as an installed/runtime component.
11. The evidence artifact's source and destination hashes recompute.
12. Manifest T-00.3 authority is coherent with the evidence artifact.

RED must be demonstrated before production edits. At minimum, negative mutation controls must
prove rejection of:

- a recreated file under `template/.omp/policies/`;
- a reintroduced `policy:` prompt reference;
- a changed quality-gate matrix;
- missing worker escalation semantics;
- a re-advertised installer component;
- a forged source or destination hash;
- manifest `PASS` without the complete evidence record.

The full Phase 00 suite and repository validator must pass in PowerShell 7 and Windows
PowerShell 5.1 after implementation.

## 9. Evidence and manifest authority

Create `docs/evidence/phase-00/T-00.3/conclusion.yml` containing:

- repository identity and implementation timestamp;
- all five old source paths, line counts, SHA-256 values, and Git blob IDs;
- one disposition row for every substantive old section: `REHOMED` or `SUPERSEDED`;
- destination paths and post-write SHA-256 values;
- deletion, dangling-reference, installer, registry, and documentation scan results;
- exact cross-shell tests and validator summaries;
- non-claims and deferred adjacent defects.

`docs/evidence/phase-00/manifest.yml` may transition T-00.3 from `READY` to `PASS` only
after the evidence contract is GREEN. Its artifact list contains the conclusion record, and
its decision states that approximate token checks are not exact tokenizer enforcement.

No provider call, runtime experiment, or E3 authority transition is part of T-00.3.

## 10. Direct documentation boundary

Only documents that would make an immediately false current-product claim after deletion are
corrected in this slice. The initial direct-document scan identifies:

- `README.md` and `CHANGELOG.md`;
- `docs/architecture.md`, `docs/customization.md`, `docs/final-report.md`,
  `docs/installation.md`, `docs/report-design.md`, `docs/security.md`,
  `docs/token-strategy.md`, and `docs/workflow-v0.md`;
- the narrow T-00.3 consistency anchors in `spec/04`, `spec/09`, `spec/11`, and
  `spec/phases/phase-00-foundation.md`.

The implementation-time scan is authoritative for this boundary: any additional current-product
file matching an exact retired-surface claim is added to the write set and changelog; historical
research and review records are excluded. This rule prevents both a stale current claim and an
unbounded prose cleanup.

Broader documentation correction remains T-00.5. T-00.3 must not claim that every stale
product statement, installer defect, or historical research sentence has been repaired.

## 11. Explicit exclusions

This slice does not:

- move or implement schemas (T-00.4 / E1);
- remove `tech-lead.md` or complete the worker topology rewrite;
- rename `reviewer.md` to `diff-reviewer.md`;
- repair the installer `workflows` versus `commands` defect;
- implement exact BPE token counting;
- resolve E2 model-role fallback behavior;
- add `blocking: true`, output schemas, LSP, or Phase 01/02 workflow behavior;
- run E3-I, E3-L, E3-M, Session B, Attempt 6, or any provider-backed experiment;
- enable parallel mode;
- import the isolated `spec/key` numeric-audit edits;
- stage, commit, push, create a branch/worktree, or open a pull request.

Known adjacent defects remain visible in the evidence non-claims rather than being silently
fixed or accidentally implied closed.

## 12. Opus continuation changelog

Implementation must create
`codex-phase00-t003-authoritative-rebuild-changelog-for-opus5.md` in English.

It must contain, without requiring Opus to reconstruct this conversation:

- governing authority and approved scope;
- old source inventory and hashes;
- section-by-section disposition mapping;
- every created, modified, and deleted file;
- before/after SHA-256 values and exact line anchors;
- RED-to-GREEN chronology and mutation-control results;
- evidence and manifest transitions;
- cross-shell verification summaries;
- unchanged/frozen artifacts and Git state;
- explicit exclusions, unresolved adjacent defects, and non-claims;
- numbered questions requiring Opus to return acceptance or evidence-backed objections.

Codex working alone does not close the peer-review issue. T-00.3 may be locally evidenced as
`PASS`, while the changelog remains `PROVISIONAL_PENDING_OPUS_REVIEW` until Opus returns and
both peers agree on the correction.

## 13. Acceptance criteria

T-00.3 is complete only when all of the following are true:

- the retired installed directory is absent and recoverable through Git plus recorded hashes;
- every useful policy section has one explicit `REHOMED` destination or a justified
  `SUPERSEDED` disposition;
- no installed command or agent contains a dangling policy reference;
- no current product document or installer advertises a runtime policy component;
- reference docs and runtime consumers agree with the canonical subsystem specs;
- approximate token-budget validation is labeled honestly;
- all focused, mutation, full Phase 00, and direct-validator checks are GREEN in both shells;
- manifest `PASS` is backed by the durable conclusion artifact;
- parallel and all unrelated Phase 00 authority remain unchanged;
- the English Opus changelog is complete and self-checked against disk.
