# Topic 08 — Portable Behavior Core and Runtime Adapters Design

**Status:** approved by the user on 2026-08-14

**Selected approach:** a thin portable constitution, a three-skill roster, role-specific prompts,
fixed workflow commands, deterministic enforcement in the existing extensions, and one
machine-readable behavior manifest

**Storage policy:** local working-tree documentation and evidence only; no commit, push, branch,
worktree, PR, download, or live-runtime installation is authorized

## 1. Purpose

Topic 08 decides where agent behavior belongs and how that behavior is projected into a runtime
without duplicating policy across rules, prompts, commands, skills, hooks, scripts, and tools.

The selected v1 is deliberately small. It ships the current three skills, autoloads only the
evidence discipline required by Worker, and reuses the existing `agent-task-boundary` and
`context-continuity` extensions. It does not import the Superpowers router, impose a universal
brainstorming gate, require subagent-driven development, force parallel agents, add a duplicate
review skill, or choose a Git workflow for the user.

OMP is the implemented runtime. Claude receives an explicit adapter contract but remains
`DESIGNED_NOT_VERIFIED` until a real Claude runtime and quota are available. A missing runtime
capability never causes a safety requirement to disappear silently.

## 2. Approved Decisions

~~~yaml
topic: 08-portable-behavior-core-runtime-adapters
status: approved
approach: thin_layered_core
decisions:
  semantic_authority: tech_lead
  hook_semantic_inference: forbidden
  automatic_task_creation: forbidden
  safety_gate_failure: fail_closed
  observability_failure: fail_open_with_warning
  visible_skill_roster:
    - task-triage
    - systematic-debugging
    - evidence-before-completion
  worker_autoload:
    - evidence-before-completion
  cheap_scout_autoload: []
  reviewer_autoload: []
  skill_catalog_policy: small_shared_visible_catalog
  omp_adapter: implement_and_verify
  claude_adapter: design_only_not_verified
  git_policy: user_decides
  subagent_policy: no_subagent_required_for_topic_08_implementation
  validation_policy: focused_first_then_one_full_validator_pass
~~~

The roster is a selected v1 manifest, not a permanent skill count. New skills and new adapters may
be added through the manifest, trigger fixtures, provenance records, and validation without
redesigning the core.

## 3. Verified OMP Runtime Constraints

The following attachment points were checked against the clean pinned OMP source at
`3a8591a8af5b6d200088d12ca75a5517cb064fa8` and the currently supported source line:

| Runtime fact | Design consequence |
|---|---|
| OMP discovers project skills by walking ancestor `.omp/skills/` directories. | The installed project skill directory is the OMP adapter target. |
| A visible skill contributes its name and description to the rendered system prompt when the session has `read`. | The visible roster and descriptions consume tokens in main and child sessions and must remain bounded. |
| `hide` or `disableModelInvocation` removes a skill from the rendered catalog while preserving explicit `skill://` and `/skill:` access. | Hiding `task-triage` would also remove automatic discovery for unprefixed work, so v1 keeps the small roster visible. |
| `/skill:<name>` works as a leading command or an embedded token in ordinary input. | Explicit skill invocation remains available without creating wrapper commands. |
| Agent `autoloadSkills` entries are resolved before child execution and injected as hidden custom messages. | `evidence-before-completion` can be delivered exactly to Worker. |
| Unknown autoload names are filtered out silently by `resolveAutoloadSkills`. | The managed adapter must reconcile names, effective paths, hashes, and agent frontmatter before dispatch. |
| Parent rules are forwarded into task children. | `RULES.md` remains universal; autoload is still used for the small, prominent Worker completion gate. |
| OMP exposes `before_agent_start`, `before_provider_request`, `tool_call`, `tool_result`, and session lifecycle events. | Deterministic checks can attach to existing extensions without prompt inference. |
| A `tool_call` extension may block before execution, and OMP treats handler timeout/error as a block. | Mutation safety gates use this fail-closed attachment point. |
| Other extension observations may fail independently of tool authorization. | Logging and metrics are wrapped as best-effort and cannot become authorization inputs. |

Source anchors:

- `_research/upstreams/oh-my-pi/packages/coding-agent/src/discovery/builtin.ts`;
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/skills.ts`;
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/system-prompt.ts`;
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/structured-subagent.ts`;
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/task/executor.ts`;
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/extensions/wrapper.ts`; and
- `_research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/extensions/runner.ts`.

These sources are read-only runtime authorities, not implementation targets.

## 4. Scope

### In scope

- one portable behavior manifest and dependency-light validation core;
- an injection-ownership model for rules, prompts, commands, skills, task facts, hooks, scripts,
  and external tools;
- the selected three-skill roster and its loading policy;
- Worker-only autoload of `evidence-before-completion`;
- a compact rule constitution;
- one explicit main-session `agent_tasks` lifecycle tool that forwards validated structured
  requests to the existing Topic 04 reducer without exposing a generic shell bootstrap;
- deterministic pre-dispatch and pre-mutation gates in the existing boundary extension;
- OMP adapter validation and a real, local OMP smoke path when a compatible runtime is present;
- a non-installable Claude mapping contract marked unverified;
- trigger, negative-trigger, and pressure fixtures;
- token budgets, provenance, license, hash, update, deprecation, removal, and local rollback rules;
- installer, uninstaller, component-manifest, documentation, and validator projections needed for
  this component; and
- focused current-product evidence without model-heavy evaluation.

### Out of scope

- adding more than the selected three skills;
- importing `using-superpowers`, universal brainstorming, TDD, plan execution, SDD, parallel-agent,
  finishing-branch, or generic code-review skills;
- changing Topic 03 model routing, effort policy, or the Tech Lead's dispatch authority;
- changing Topic 06 agent result contracts or Topic 07 compaction semantics;
- implementing or simulating Claude hooks without a real runtime;
- automatic task creation or lifecycle transitions inferred from user prose;
- semantic trigger-quality promotion, comparative model evaluation, or broad adversarial campaigns,
  which belong to Topic 11;
- general MCP trust, credentials, destructive-operation policy, or unknown third-party mutating
  tools, which belong to Topic 10;
- phase remapping, cross-runtime installation, and product-wide rollback, which belong to Topic 12;
  and
- Git operations or writing to the live user OMP directory.

## 5. Authority, Placement, and Injection Ownership Matrix

Each behavior has one primary authority:

| Behavior kind | Primary authority | Adapter responsibility |
|---|---|---|
| Universal invariant | `RULES.md` / portable constitution | Discover and forward; never restate in every prompt. |
| Role identity and role limits | Agent prompt | Map the selected role into the runtime's agent format. |
| Fixed user-invoked sequence | Quick, Standard, or Orchestrated command | Register/discover the command unchanged. |
| Conditional procedure | Lazy skill | List a short trigger description and load the body only when applicable. |
| Mandatory role procedure | Small autoloaded skill or exact role prompt | Validate delivery before dispatch. |
| Task-specific facts | Topic 04 `agent-tasks` state and Topic 06 packet | Project facts; never turn transcript prose into authority. |
| Deterministic check | Script/validator or dependency-light core | Run without model judgment. |
| Lifecycle/enforcement | Hook/extension | Block only machine-decidable violations. |
| External capability | MCP/tool | Expose capability; never choose workflow or policy. |

`SYSTEM.md` is not selected because OMP treats it as a custom system-prompt replacement, not a
small portable rule layer. `AGENTS.md` remains explanatory operating guidance. It must not become a
second constitution.

Intentional duplication has one narrow exception: the main/parent invariant "verify before a
completion claim" remains in `RULES.md`, while Worker also receives the compact
`evidence-before-completion` skill. The two copies serve different delivery boundaries and the
manifest records that duplication explicitly.

## 6. Agent Behavior Model and Architecture

~~~text
Portable behavior manifest
  -> validates selected rules, roles, commands, skills, gates, budgets, and provenance
  -> OMP adapter
       -> RULES.md
       -> .omp/agents/{cheap-scout,worker,reviewer}.md
       -> .omp/commands/{quick,standard,orchestrated}.md
       -> .omp/skills/{three selected skills}/SKILL.md
       -> agent-task-boundary extension gates
       -> context-continuity extension reference
       -> scripts and deterministic fixtures
  -> Claude adapter contract
       -> mapping only
       -> installable: false
       -> status: DESIGNED_NOT_VERIFIED

User request
  -> explicit workflow prefix: execute that command after deterministic validation
  -> no prefix / materially ambiguous: Tech Lead may load task-triage
  -> accepted task contract: Tech Lead explicitly calls agent_tasks(create-task)
  -> actual failure / unclear root cause: selected consumer may load systematic-debugging
  -> Worker dispatch: reconcile exact evidence skill, then autoload it
  -> completion claim: require fresh evidence
~~~

The behavior core never classifies work, chooses an agent, chooses a model, changes effort, creates
a task, or accepts a candidate. Those remain Tech Lead and downstream topic decisions.

## 7. Portable Behavior Manifest

The implementation adds `.omp/contracts/behavior-manifest.json` with a closed schema. Its required
top-level keys are:

~~~json
{
  "schema_version": 1,
  "record_type": "portable_behavior_manifest",
  "component": "behavior-core",
  "component_version": "1.0.0",
  "reviewed_on": "2026-08-14",
  "constitution": {},
  "budgets": {},
  "skills": [],
  "roles": {},
  "commands": {},
  "hooks": [],
  "tools": {},
  "adapters": {},
  "provenance": []
}
~~~

Every selected skill row contains exactly:

- `name`, project-relative `path`, and lowercase SHA-256;
- `visibility`, `loading`, `intended_consumers`, and `autoload_roles`;
- positive- and negative-trigger fixture paths;
- description and body token ceilings;
- provenance/adoption ID and license ID; and
- lifecycle status: `active`, `deprecated`, or `removed` with an optional replacement.

Every role row contains its agent file, exact required autoload list, and forbidden semantic
responsibilities. Every constitution, role, command, skill, and hook row lists the `behavior_ids`
for which it is the primary injection owner. Every hook row also contains its existing extension
owner, event or tool boundary, machine-decidable predicate, failure policy, error code prefix, and
observation policy. A behavior ID has one primary owner; only the declared
`evidence-before-completion` cross-boundary duplication is valid.

The `tools.external_capabilities` row declares `policy_authority: false` and
`workflow_selection: false`. MCP/tool availability never grants semantic authority.

Adapter status transitions are closed. OMP begins as `SELECTED_FOR_IMPLEMENTATION` with
`installable: false`, then becomes `IMPLEMENTED_NOT_PROMOTED` with `installable: true` only after
the executable adapter and component preflight exist. Claude remains `DESIGNED_NOT_VERIFIED` with
`installable: false`.

The installed manifest is the selected-runtime authority. `registry/skill-lock.yml` and the skill
entries in `.omp/contracts/component-manifest.json` are generated release mirrors. Validators fail
if either mirror differs; maintainers never edit the same hash independently in three places.

The portable core validates and canonicalizes this data without importing OMP. Runtime adapters
translate their discovery results into the core's input shape.

## 8. Rule Constitution

The current ten `RULES.md` invariants remain the selected constitution. The invariant count is not
hard-coded; scope and budget are the controls.

Rules may cover only:

- evidence before completion;
- explicit user authority for Git and live installation;
- declared write scope;
- bounded context passed to subagents;
- secrets and private data;
- visible failure rather than silent retry;
- ambiguity before implementation;
- Topic 04 state authority; and
- the managed Topic 07 compaction boundary.

Role workflows, detailed debugging steps, gate definitions, model routes, task facts, and review
procedures do not belong in `RULES.md`.

The approximate budget remains target maximum 700 tokens and hard warning above 800. A lower-bound
warning is advisory; no file is padded merely to satisfy a minimum token target.

## 9. Selected Skill Roster

| Skill | Loading | Intended consumers | v1 rule |
|---|---|---|---|
| `task-triage` | visible, lazy | Main-session Tech Lead | Use only for missing prefix, material ambiguity, unclear scope/ACs, or uncertain workflow size. |
| `systematic-debugging` | visible, lazy | Tech Lead or Worker when an actual failure/root cause is unclear | Do not activate for normal feature work, clear mechanical edits, or review-only work. |
| `evidence-before-completion` | visible; autoloaded only for Worker | Worker; main may read it explicitly | Require fresh evidence before Worker reports completion. |

The three descriptions stay visible because OMP uses them for model discovery and forwards the
small catalog to task children. V1 does not add per-role catalog filtering. Seeing a skill name is
not permission to assume another role: Cheap Scout never triages, mutates, verifies acceptance, or
reviews; Worker never chooses workflow; Reviewer follows its exact prompt and receives no generic
review skill.

The Worker agent frontmatter contains exactly:

~~~yaml
autoloadSkills:
  - evidence-before-completion
~~~

Cheap Scout and Reviewer contain no `autoloadSkills` entry. Missing, shadowed, disabled, wrong-path,
wrong-hash, extra, or duplicated autoload bindings stop managed dispatch before model tokens are
spent.

## 10. Trigger and Negative-Trigger Matrix

| Skill | Positive fixtures | Negative fixtures |
|---|---|---|
| `task-triage` | Unprefixed ambiguous objective; missing acceptance criteria; unclear workflow size | Explicit `/quick`, `/standard`, or `/orchestrated`; clear bounded edit with test; already-resolved scope |
| `systematic-debugging` | Reproducible test failure; intermittent failure with unknown cause; second failed fix attempt | New feature without defect; planned refactor; typo/rename; review finding without a requested fix |
| `evidence-before-completion` | Worker is about to report done/fixed/passing; result claims acceptance | Mid-task progress; plan description; honest failed/blocked/partial result; Cheap Scout evidence return |

Each skill receives a machine-readable fixture file under `evals/triggers/topic08/` containing
`should_trigger` and `should_not_trigger` cases. Topic 08 validates fixture shape, uniqueness,
coverage, and manifest linkage deterministically. Model-assisted trigger quality remains advisory
until Topic 11; Topic 08 does not burn model quota to manufacture a promotion claim.

Explicit workflow commands bypass triage after their task-state and command contract validate.
Unprefixed input does not force a skill call when the objective, scope, acceptance criteria, and
risk are already clear.

## 11. Token Budget

| Surface | Budget | Enforcement |
|---|---|---|
| `RULES.md` | target maximum 700 approximate tokens; hard warning above 800 | Existing approximate token validator plus Topic 08 manifest check |
| One visible skill description | at most 80 approximate tokens | Fail closed in release validation |
| Total visible skill listing | at most 900 approximate tokens | Fail closed in release validation |
| Visible skill count | soft cap 10; hard cap 12 | Warning at soft cap; fail above hard cap |
| Autoloaded `evidence-before-completion` body | at most 500 approximate tokens | Fail before release and managed dispatch on mismatch |
| Each lazy skill body | at most 900 approximate tokens before references are required | Warning then refactor detail into on-demand references |
| Behavior manifest/core | zero prompt tokens | Never inject machine policy JSON into a model prompt |

The current roster remains three. The caps permit later extension; they are not a target to fill.
Approximate counts use the repository's documented character-based estimator and are labeled
approximate rather than provider-exact.

## 12. Hook and Extension Catalog

V1 adds no third extension.

### 12.1 `agent-task-boundary`

This extension owns the deterministic behavior gates:

1. At managed extension initialization, validate the behavior manifest and reconcile the selected
   agents, skills, paths, and hashes.
2. Register one main-session `agent_tasks` tool. It accepts only `operation` plus the operation's
   structured request, while the adapter supplies trusted schema version, working directory,
   runtime, and current session reference. It calls the existing Topic 04 core and never edits
   authority files itself. This is the explicit bootstrap path for `init-project` and `create-task`
   before ordinary mutation is allowed.
3. Immediately before each managed `task` dispatch, rediscover the effective agent and skill
   catalogs and require the exact Worker autoload binding. This closes OMP's silent missing-name
   filter and user-level skill shadowing.
4. Before ordinary `edit`, `write`, or `bash`, require one valid current managed task binding for
   the current session/work unit. The structured `agent_tasks` tool is not an ordinary mutation
   bypass: the Topic 04 reducer validates its operation, authority, ownership, and CAS. Read-only
   diagnosis remains allowed through declared non-mutating tools such as `read`, `grep`, `glob`,
   and permitted retrieval tools when the binding is absent or invalid. `bash` remains blocked
   because the adapter does not attempt unsafe semantic parsing of shell text.
5. Never parse prompt prose to create a task, choose a workflow, select a role, select a model, or
   change effort.
6. Return a bounded code, reason, and remediation for every refusal.

The managed `task` tool keeps its existing Topic 06 packet/result validation. Topic 08 adds a
behavior preflight; it does not replace or weaken that boundary.

### 12.2 `context-continuity`

This extension retains Topic 07 ownership of session arming, pressure, `/safe-compact`, and kernel
continuity. Topic 08 records it in the behavior manifest but does not move triage or skill routing
into it.

### 12.3 Observation policy

Logging, counters, and optional notifications are best-effort. Observation failure emits a bounded
warning and cannot change an allow/deny decision. A safety predicate that cannot be evaluated is a
refusal, not an observation warning.

## 13. Fail-Open and Fail-Closed Semantics

| Condition | Behavior |
|---|---|
| Invalid/missing behavior manifest | Fail closed for managed dispatch and mutation; reads remain available. |
| Missing, shadowed, disabled, duplicated, or hash-mismatched required skill | Fail closed before Worker dispatch. |
| Worker frontmatter missing or adding an unexpected autoload | Fail closed before dispatch. |
| Missing or ambiguous current task binding | Block managed dispatch and `edit`/`write`/`bash`; allow read-only diagnosis. |
| No task exists yet | Permit only the structured `agent_tasks` lifecycle call; the Tech Lead must explicitly submit the accepted contract to `create-task`. |
| `tool_call` safety handler error or timeout | Fail closed through OMP's pre-execution block result. |
| Logging/metric/notification failure | Fail open with one bounded warning. |
| Trigger fixture semantic uncertainty | Do not claim promotion; continue deterministic implementation and defer semantic scoring to Topic 11. |
| Claude lacks a verified hook/injection equivalent | Claude adapter remains non-installable and unpromoted; OMP work continues. |
| Optional MCP/tool unavailable | Follow the selected workflow's existing capability fallback; never weaken a mandatory safety predicate. |

Initial Topic 08 reason codes are:

- `BHV-MANIFEST-INVALID`;
- `BHV-SKILL-MISSING`;
- `BHV-SKILL-SHADOWED`;
- `BHV-SKILL-HASH-MISMATCH`;
- `BHV-AUTOLOAD-MISMATCH`;
- `BHV-STATE-MISSING`;
- `BHV-STATE-AMBIGUOUS`;
- `BHV-LIFECYCLE-FORBIDDEN`;
- `BHV-HOOK-UNAVAILABLE`;
- `BHV-BUDGET-EXCEEDED`; and
- `BHV-ADAPTER-UNSUPPORTED`.

Codes describe mechanism failure, not semantic task outcomes.

The main-session `agent_tasks` tool exposes exactly these routine operations in v1:

~~~text
init-project, status, create-phase, transition-phase, create-task,
set-continuity-contract, bind-worktree, checkpoint, claim, create-work-unit,
freeze, check, promote-artifact, record-evidence, begin-handoff,
accept-handoff, close, invalidate
~~~

Internal projections and outcome recording remain extension-owned. `takeover`, `cleanup`,
`restore`, `purge`, `recover-lock`, and `migrate` remain manual authority-sensitive operations for
Topics 10 and 12; the Topic 08 model-callable tool does not expose them.

## 14. OMP Adapter

The OMP adapter is the only executable Topic 08 adapter in v1. It maps:

- constitution → `.omp/RULES.md`;
- role identity → `.omp/agents/*.md`;
- fixed workflows → `.omp/commands/*.md`;
- conditional and mandatory procedures → `.omp/skills/*/SKILL.md` plus Worker frontmatter;
- task facts → existing Topic 04/06 state and packets;
- explicit lifecycle calls → main-session `agent_tasks` tool backed by the existing Topic 04
  reducer;
- lifecycle gates → existing `.omp/extensions/agent-task-boundary.js` and
  `.omp/extensions/context-continuity.js`;
- deterministic checks → Topic 08 core, validator, and tests; and
- external capability → existing OMP tools/MCP declarations.

The adapter validates the effective discovered skill path, not merely the name, so a user-level
skill with the same name cannot silently replace the reviewed project skill. It also verifies that
the installed component manifest hashes the behavior manifest, skill bodies, affected agent
prompts, and extension files.

The source-pinned 17.2.10 attachment remains source-verified. A local 17.2.12 runtime may provide a
no-network smoke canary. The absence of a local 17.2.10 executable is recorded honestly and does
not trigger a download or downgrade.

## 15. Claude Adapter

The manifest contains a Claude adapter record with:

~~~yaml
runtime: claude
status: DESIGNED_NOT_VERIFIED
installable: false
source_manifest: portable_behavior_manifest_v1
required_mappings:
  constitution: pending_runtime_mapping
  roles: pending_runtime_mapping
  commands: pending_runtime_mapping
  lazy_skills: pending_runtime_mapping
  mandatory_role_injection: pending_runtime_mapping
  pre_dispatch_gate: pending_runtime_mapping
  pre_mutation_gate: pending_runtime_mapping
~~~

Topic 08 validates that this contract is complete and explicitly unverified. It creates no fake
Claude files, does not infer hook equivalence from documentation alone, and does not block OMP
because Claude is unavailable. When Claude becomes available, each `pending_runtime_mapping` must
be replaced by a source-verified attachment and behavioral evidence before `installable` may be
true.

## 16. Commands, MCP, Tools, and Scripts

- `quick`, `standard`, and `orchestrated` remain the only selected fixed workflow commands.
- Explicit commands own their sequence and resolved quality-gate data. Skills do not wrap or
  silently replace them.
- An unprefixed request is handled by Tech Lead judgment with lazy `task-triage` only when needed.
- After accepting the contract, Tech Lead explicitly calls `agent_tasks` to create or transition
  durable state. The tool never infers fields from prompt prose and is not exposed to bounded
  child roles.
- Reviewer remains the specialized review authority; Topic 08 adds no generic code-review skill.
- MCP and external tools expose capabilities only. Their availability cannot create authority,
  accept work, or select a workflow.
- Scripts own hashing, manifest validation, fixture linting, installer checks, and evidence capture.
  Scripts do not make semantic trigger decisions.
- Git operations remain explicit user choices and are never embedded in a skill or hook.

## 17. Failure-Mode Catalog

| Failure mode | Control |
|---|---|
| Skill catalog grows until every prompt pays excessive tokens | Count and token ceilings; lazy bodies; soft-cap review. |
| Skill description activates too often | Negative fixtures and descriptions that state when to use, not a workflow summary. |
| Applicable skill is missed | Positive fixtures and explicit `/skill:` fallback. |
| Required Worker skill disappears silently | Effective discovery/path/hash/autoload reconciliation before dispatch. |
| Main-only triage leaks semantic authority to Worker | Role prompt prohibition plus negative fixture; no Worker autoload. |
| Reviewer procedure is duplicated into a generic skill | Reviewer prompt remains sole specialized review owner. |
| Same invariant drifts across rules/prompts/commands | Injection ownership manifest and duplicate-authority checks. |
| Hook blocks harmless diagnosis | Reads remain allowed when task state is invalid. |
| Mutation gate prevents creation of the first task | A schema-bound `agent_tasks` tool is the sole bootstrap path; generic shell/write bypasses remain blocked. |
| Hook infers the wrong workflow/task | Semantic inference and automatic task creation are forbidden. |
| Hook failure silently permits mutation | Safety uses pre-execution fail-closed gates. |
| Metrics outage stops work | Observation is fail-open with warning. |
| User skill shadows reviewed project skill | Exact effective path and hash reconciliation. |
| Adapter claims unsupported parity | Closed status vocabulary and non-installable unverified adapters. |
| Upstream content loses attribution | Manifest provenance plus registry license/adoption checks. |
| Skill removal leaves a dangling autoload | Deprecate, remove references, validate zero consumers, then delete. |

## 18. License and Provenance

The manifest links every adopted behavior to `registry/upstreams.yml`,
`registry/adoption-ledger.yml`, and `registry/licenses.yml`.

- `systematic-debugging` and `evidence-before-completion` remain paraphrased project-native
  implementations derived from `obra/superpowers` at the pinned MIT-licensed commit.
- `task-triage`, the behavior manifest, adapters, hooks, fixtures, and validators are marked
  project-owned unless an existing adoption record says otherwise.
- OMP is a runtime authority and external dependency; Topic 08 does not copy OMP source.
- Stale references to removed `verifier.md` ownership are corrected to the selected Worker-only
  autoload contract.
- Null hashes are forbidden for active selected skills.

An upstream update never overwrites a local skill automatically. It produces a review candidate,
and promotion requires updated provenance, hashes, fixtures, and focused validation.

## 19. Deterministic Validation and Fixtures

The focused Topic 08 suite contains:

1. **Manifest/schema tests** — closed keys, canonical ordering, path confinement, lowercase hashes,
   status vocabulary, unique ownership, budgets, and adapter completeness.
2. **Skill tests** — exact selected roster, frontmatter/name/description, effective discovery path,
   file hash, Worker-only autoload, no `alwaysApply`, and no null release hash.
3. **Trigger fixture lint** — positive/negative arrays exist, are non-empty, unique, linked, and
   cover each selected skill.
4. **Pressure tests** — missing skill, shadowed skill, altered hash, missing/extra Worker autoload,
   invalid manifest, explicit state bootstrap, rejected inferred/child lifecycle calls,
   missing/ambiguous state, mutation block, read-only allowance, and observation failure.
5. **Command tests** — explicit workflow prefixes do not invoke triage; no universal brainstorming,
   SDD, parallel-agent, generic-review, or Git-autonomy gate is introduced.
6. **Adapter tests** — OMP mappings resolve; Claude remains complete but non-installable and
   unverified.
7. **Installer tests** — install/update/uninstall own the Topic 08 files without touching retained
   `agent-tasks` operational state or unrelated user files.
8. **Source sentinels** — the selected OMP discovery, autoload, silent-filter, rule forwarding, and
   pre-execution block attachment points still exist on supported source snapshots.

Validation order is intentionally bounded:

1. run Topic 08 focused tests;
2. run the Topic 08 mutation suite;
3. run one no-network OMP smoke canary if a compatible runtime is already available;
4. run each affected prior-topic validator once;
5. run the full template validator once; and
6. run `git diff --check` as a read-only hygiene check.

Only a real failure justifies another cycle. No peer-review swarm, repeated corpus audit, or
model-assisted trigger campaign is part of Topic 08 implementation.

## 20. Update, Removal, and Local Rollback

### Add or update a skill

1. Add or edit the body and concise trigger description.
2. Record provenance/license and selected consumers.
3. Add positive and negative fixtures.
4. Regenerate the authoritative manifest hash and its generated lock mirrors.
5. Run the focused suite and one final full validator pass.
6. Activate only after all mandatory consumers resolve the exact reviewed file.

### Remove a skill

1. Mark it `deprecated` and name a replacement when one exists.
2. Remove all autoload, prompt, command, fixture, and documentation consumers.
3. Validate zero active consumers.
4. Mark it `removed`, then delete the body in the same bounded change.
5. Regenerate hashes and run focused validation.

### Local rollback

Evidence capture stores the last known-good behavior manifest and selected file hashes under the
local current-product Topic 08 evidence directory. Rollback restores only Topic 08-owned installed
files after verifying the target root and retained-state boundary. Git is not required. Product-wide
installer rollback remains Topic 12.

## 21. Implementation Impact Map

Expected implementation surfaces are:

- `template/.omp/contracts/behavior-manifest.json`;
- dependency-light behavior schema/core modules under `template/.omp/contracts/`;
- `template/.omp/agents/worker.md` for the single autoload entry;
- the three selected `template/.omp/skills/*/SKILL.md` files for concise descriptions/body budgets;
- `template/.omp/extensions/agent-task-boundary.js` for reconciliation and mutation gates;
- the same extension's main-session `agent_tasks` adapter tool, backed by the existing
  `managed-state-client.mjs` and Topic 04 reducer;
- `template/.omp/contracts/component-manifest.json` and managed runtime discovery data;
- Topic 08 trigger and pressure fixtures under `evals/`;
- `registry/skill-lock.yml`, `registry/adoption-ledger.yml`, `registry/licenses.yml`, and
  `registry/upstreams.yml` only where stale or generated Topic 08 data requires correction;
- focused Topic 08 validation, tests, and evidence-capture scripts;
- `scripts/update-skill-lock.ps1`, generated from the authoritative behavior manifest rather than
  hand-maintained hashes;
- installer, uninstaller, and full-validator integration;
- concise behavior/adapters/customization/installation/rollback documentation; and
- projections into load-bearing specs that currently describe the obsolete fixed roster or null
  skill locks.

Existing unrelated dirty working-tree changes remain user-owned and must not be reverted.

## 22. Acceptance Criteria

1. Every selected behavior has exactly one primary injection owner, with the one documented
   cross-boundary evidence duplication.
2. The selected roster is exactly the three approved skills without making three a permanent cap.
3. Only Worker autoloads `evidence-before-completion`; Cheap Scout and Reviewer autoload nothing.
4. Managed Worker dispatch refuses missing, shadowed, disabled, duplicated, wrong-path,
   wrong-hash, or mismatched-autoload evidence skill states before model work begins.
5. Invalid or ambiguous managed task state permits diagnosis reads but blocks managed dispatch and
   `edit`/`write`/`bash`.
6. Before the first task exists, only an explicit main-session `agent_tasks` call may initialize or
   create state; the adapter supplies trusted runtime/session fields and the reducer validates the
   accepted structured contract.
7. Hooks never infer task meaning, create tasks, select workflows, choose roles/models/effort, or
   accept candidates.
8. Observation failure warns without weakening or creating a safety decision.
9. RULES, descriptions, catalog, count, autoload body, and lazy bodies satisfy the selected token
   budgets without padding to a minimum.
10. Positive and negative fixture sets exist for every selected skill; semantic promotion is
   deferred honestly to Topic 11.
11. Provenance/license/hash records contain no null hash for an active selected skill and no stale
    removed-Verifier ownership.
12. OMP adapter mappings and deterministic attachment points pass focused validation; any local
    runtime claim names the exact version tested.
13. Claude remains complete as a mapping contract, `DESIGNED_NOT_VERIFIED`, and non-installable.
14. Update, deprecation, removal, and local rollback procedures leave no dangling consumer.
15. Installer/uninstaller ownership does not delete retained `agent-tasks` state or unrelated user
    data.
16. Focused tests, mutation tests, affected prior-topic validators, one full validator pass, and
    diff hygiene pass with no new failure before an implementation-complete claim.

## 23. Rejected Alternatives and Promotion Boundary

### Rejected

- **Prompt-first duplication:** cheap initially, but role and workflow rules drift across files.
- **Hook-heavy semantic automation:** auto-triage and auto-task creation move judgment into brittle
  string matching.
- **Shell-command whitelist for task bootstrap:** parsing a shell string creates quoting,
  redirection, and command-chaining bypasses; the structured lifecycle tool is smaller and safer.
- **Per-role skill catalog filtering in v1:** additional runtime plumbing for negligible savings
  with only three descriptions.
- **No autoload:** permits Worker false-completion discipline to depend on model choice.
- **Worker and Reviewer autoload:** duplicates the Reviewer's specialized prompt and spends tokens
  without adding a distinct guarantee.
- **Everything fail-closed:** lets logging or advisory trigger scoring halt useful work.
- **Everything fail-open:** permits safety checks to disappear under failure.
- **Large inherited skill catalog:** recreates obsolete topology and permanent prompt cost.
- **Fake Claude implementation:** creates unsupported parity claims without a runtime.

### Promotion boundary

Topic 08 may finish as `IMPLEMENTED_NOT_PROMOTED` after deterministic tests and available-runtime
evidence. Topic 11 owns model-assisted trigger quality, pressure comparisons, false-completion
rates, and promotion decisions. Topic 12 owns portable installation and product-wide rollback.

The implementation must reopen this design rather than improvise if OMP cannot expose the exact
effective skill catalog before Worker dispatch, if pre-mutation state cannot be proven without
semantic inference, or if any required safety path can only fail open.
