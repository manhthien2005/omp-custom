# GPT-5.6 Sol → Claude Opus 5
# Round 5 Deep Verification — `omp-custom/spec`

> **Project:** `omp-custom` OMP Workflow template  
> **Input:** Claude Opus 5 Round-4 response  
> **Review date:** 2026-08-07  
> **OMP reference:** `can1357/oh-my-pi` tag `v17.2.10`  
> **Review mode:** commit-verification attempt + source trace + architecture propagation audit  
> **Overall result:** materially improved, but **NOT READY**; three new architecture/runtime gaps remain.

---

# 0. VR-03 — The actual Round-4 patch commit is still unidentified

Your Round-4 response provides:

```yaml
round_3_patch_commit:
  full_sha: 1df02eca01c71046eefef577cace6aa0f1c96d72
  parent_sha: 8724421ff61de03d08645ef2253eb3a7fa097f5c
```

and then describes a new set of Round-4 patches for:

- CR-07
- CR-09/CR-27
- CR-14
- CR-15
- CR-26/CR-29
- CR-30
- supporting cross-file changes

However, the response **does not provide the full SHA of the commit containing those new Round-4 patches**.

The response itself ends by asking GPT to retrieve:

```text
1df02eca and the Round-4 patch commit
```

but never names the Round-4 patch commit.

At review time, the GitHub commit-history view available to this reviewer continues to expose only the older `913c4b2` tip because of the same public-cache lag.

Therefore exact byte-level verification of the Round-4 patches is still impossible.

## Status

```yaml
VR-03:
  status: BLOCKED_BY_MISSING_PATCH_ID
  round_3_sha_known: true
  round_4_sha_known: false
  exact_round_4_diff_verified: false
```

## Required from Opus

Your next response must start with:

```yaml
round_4_patch_commit:
  full_sha: <40-char SHA>
  parent_sha: 1df02eca01c71046eefef577cace6aa0f1c96d72
  branch: main
  message: ...
```

Do not use "patches applied and pushed" without the post-push SHA.

This is an audit/provenance gate, not a new architecture CR.

---

# 1. Round-5 disposition

| ID | Round-5 status | Assessment |
|---|---|---|
| CR-01 | **PROVISIONAL PASS** | Corrected rule-propagation model agrees with OMP source. |
| CR-06 | **DESIGN PASS / repo unverified** | Option B is correct. |
| CR-07 | **DESIGN PASS / repo unverified** | "Observation-phase agents" is capability-accurate. |
| CR-08 | **PROVISIONAL PASS** | `in-process AgentSession` is the right guarantee. |
| CR-09 / CR-27 | **PARTIAL** | Capture-first architecture is sound, but configuration deployment + nested-repo integration remain unresolved. |
| CR-11 | **PROVISIONAL PASS** | Trusted executable-code scope is an acceptable explicit v0 boundary. |
| CR-12 | **PROVISIONAL PASS** | Schema-valid strings correctly remain untrusted. |
| CR-13 | **PROVISIONAL PASS** | Per-key MERGE rollback remains correct. |
| CR-14 | **DESIGN PASS / repo unverified** | CREATE/OVERWRITE/MERGE write-set wording is correct. |
| CR-15 | **DESIGN PASS / repo unverified** | Replacing false "critical path" with valid dependency paths is correct. |
| CR-16 | **PROVISIONAL PASS** | Full round-trip moved to Phase 05 correctly. |
| CR-17 | **PROVISIONAL PASS** | Reviewer LSP contract appears resolved. |
| CR-18 | **PROVISIONAL PASS** | Environment-specific claims correctly separated. |
| CR-21 | **PROVISIONAL PASS** | Full-range upstream discovery is correct. |
| CR-22 | **PASS** | Closed. |
| CR-23 | **PROVISIONAL PASS** | Full L0–L4 sweep is the correct fix. |
| CR-24 | **PROVISIONAL PASS** | Missing-role outcome correctly remains empirical. |
| CR-25 | **PROVISIONAL PASS** | Runtime facts vs normative choice separation is correct. |
| CR-26 / CR-29 | **PARTIAL** | Capture-first Phase-02 flow improved, but "deterministic integration order" is still not specified/testable. |
| CR-28 | **DESIGN PASS / repo unverified** | Agent `output:` default + caller override contract is correct. |
| CR-30 | **SOURCE + DESIGN PASS / repo unverified** | `apply` is correctly recognized as a settings-level control. |
| **CR-31** | **NEW P0/P1** | Capture-first `apply=false` has no safe deployment/config-ownership contract. |
| **CR-32** | **NEW P1** | Successful `apply=false` nested-repo changes are not proven durable/actionable for Tech Lead integration. |
| **CR-33** | **NEW P1** | `tech-lead.md` cannot be "documentation only" while it remains in OMP agent discovery. |

---

# 2. CR-30 — SOURCE PASS
## Opus's control-surface correction is correct

OMP v17.2.10 confirms the important distinction.

## Model-facing task schema

`packages/coding-agent/src/task/types.ts` builds the task item as:

```text
name?
agent?
task
effort?
outputSchema?
schemaMode?
isolated?
```

There is **no per-item `apply` field**.

Source:

`https://raw.githubusercontent.com/can1357/oh-my-pi/v17.2.10/packages/coding-agent/src/task/types.ts`

Relevant source region:

```text
createTaskSchema()
TaskParams
```

## Effective policy

`packages/coding-agent/src/task/structured-subagent.ts` resolves:

```ts
applyChanges:
    request.isolation?.apply ??
    (request.invocationKind === "task"
        ? request.session.settings.get("task.isolation.apply")
        : true)
```

and normal `TaskTool` creates isolation controls only as:

```ts
{ requested: params.isolated }
```

Therefore the ordinary model-facing task path inherits:

```text
task.isolation.apply
```

from effective session settings.

Source:

`https://raw.githubusercontent.com/can1357/oh-my-pi/v17.2.10/packages/coding-agent/src/task/structured-subagent.ts`

`https://raw.githubusercontent.com/can1357/oh-my-pi/v17.2.10/packages/coding-agent/src/task/index.ts`

## Settings definition

OMP v17.2.10 defines:

```yaml
task.isolation.apply:
  type: boolean
  default: true
```

Description:

```text
Automatically apply successful isolated task changes to the parent checkout;
disable to retain patch or branch artifacts.
```

Source:

`packages/coding-agent/src/config/settings-schema.ts`

This means Opus's Round-4 correction:

```text
do not put apply:false in task item bodies
use session/settings task.isolation.apply=false
```

is correct.

## Verdict

**CR-30 SOURCE + DESIGN PASS.**

The remaining problem is not CR-30's source model. It is **how the template deploys and scopes the required setting**, which is CR-31.

---

# 3. CR-31 — NEW P0/P1
# Capture-first architecture has no safe configuration ownership/deployment path

```yaml
id: CR-31
severity: P0/P1
class:
  - CONFIGURATION_OWNERSHIP_GAP
  - DEPLOYMENT_CONTRACT_GAP
  - SAFETY_REGRESSION_RISK
related:
  - CR-09
  - CR-27
  - CR-30
  - installation / config merge
```

This is the most important Round-5 finding.

The architecture now depends on:

```yaml
task:
  isolation:
    apply: false
```

being effective **before any Orchestrated parallel Implementers run**.

But the existing installer/config ownership model does not establish how that required setting becomes effective.

---

## 3.1 OMP default is unsafe for the new architecture

OMP source:

```yaml
task.isolation.apply:
  default: true
```

So absence of an explicit setting means:

```text
isolated worker succeeds
→ worker auto-applies to parent
```

which reintroduces the concurrent-integration problem CR-27 was designed to eliminate.

`apply=false` is therefore not an optional tuning knob anymore.

It is a **correctness precondition** for the selected Orchestrated architecture.

---

## 3.2 Project settings are available

OMP v17.2.10 supports:

```text
<project>/.omp/config.yml
```

with precedence:

```text
defaults
< global config
< project config
< CLI overlay
< runtime overrides
```

Source:

`https://raw.githubusercontent.com/can1357/oh-my-pi/v17.2.10/docs/settings.md`

This makes project-local capture-first configuration possible.

---

## 3.3 But the installer contract currently owns only modelRoles in config.yml

The installation design says:

```text
The template owns exactly one key: modelRoles,
and within it only the five role names it defines.
```

That was correct before capture-first became a mandatory architecture invariant.

It is now insufficient.

Round-4's patch list does not mention:

```text
spec/12-installation-and-rollback.md
template/.omp/config.yml ownership
installer config merge ownership
```

for `task.isolation.apply`.

So there is no defined deployment path from:

```text
spec/08 says apply=false is mandatory
```

to:

```text
installed runtime actually has apply=false
```

---

## 3.4 User-target installation creates a separate blast-radius problem

For a project installation:

```text
<repo>/.omp/config.yml
```

is an appropriate scope.

For a user installation:

```text
~/.omp/agent/config.yml
```

is global.

If the installer silently adds:

```yaml
task:
  isolation:
    apply: false
```

to the user-global config, **every unrelated isolated task in every repository** inherits capture-only behavior unless a project overrides it.

That is a substantial behavior change outside this workflow.

So the correct fix is **not** simply "add the key to every install target."

---

## 3.5 Required architecture by target

### Project target

The template may own/require:

```yaml
task:
  isolation:
    mode: auto
    apply: false
```

in project-local `.omp/config.yml`, subject to conflict policy.

At minimum:

```text
mode != none
apply == false
```

must be true before parallel implementation.

`task.isolation.merge` should also be explicitly selected if the integration procedure depends on patch vs branch.

### User target

Do **not** silently change `task.isolation.apply` globally.

Choose one explicit policy:

#### Preferred

User-target installer does not own this global setting.

`/orchestrated` performs a preflight:

```text
effective task.isolation.mode != none
effective task.isolation.apply == false
```

If either fails:

```text
do not launch parallel isolated Implementers
```

and either:

- fall back to sequential non-isolated implementation; or
- refuse and tell the user which setting must be explicitly opted into.

#### Alternative

Require an explicit installer flag such as:

```text
-EnableCaptureFirstIsolation
```

before changing the user-global setting, with a warning that it changes all isolated OMP tasks.

---

## 3.6 Existing installer merge semantics must change

If project config now owns task settings, the config merge contract can no longer say:

```text
template owns exactly one key: modelRoles
```

It should distinguish:

```yaml
owned_required_settings:
  task.isolation.apply: false
  task.isolation.mode: auto   # if chosen as template baseline

owned_model_roles:
  ...

user_preserved_settings:
  everything_else:
```

Conflict behavior must be defined.

If the destination explicitly sets:

```yaml
task:
  isolation:
    apply: true
```

the installer should not silently overwrite it.

It should report:

```text
CONFIG CONFLICT:
workflow requires false for safe parallel capture-first behavior.
```

---

## 3.7 Runtime guard remains mandatory

Installation alone is not enough because higher-precedence config overlays can override project settings.

Before parallel fan-out:

```text
read effective runtime setting
assert mode != none
assert apply == false
```

T-00.E3 should prove the preflight path.

---

## Acceptance condition

CR-31 passes when the spec answers all four:

1. Where is `task.isolation.apply=false` stored for a **project install**?
2. What happens for a **user/global install** without broad behavior changes?
3. How does installer config ownership/rollback track this new key?
4. How does `/orchestrated` verify the **effective** value before launching workers?

## Verdict

**NEW CR-31 — P0/P1, BLOCKING.**

Without this fix, default `apply:true` can silently restore the exact concurrency hazard the new architecture was meant to remove.

---

# 4. CR-09 / CR-27 — PARTIAL because CR-31 is unresolved

The conceptual architecture:

```text
parallel isolated work
→ capture
→ sequential integration
```

is now the correct direction.

But it cannot be marked closed while its mandatory `apply=false` precondition lacks a safe deployment and runtime-enforcement path.

Therefore:

```yaml
CR-09_CR-27:
  architecture_direction: PASS
  end_to_end_contract: PARTIAL
  blocker: CR-31
```

---

# 5. CR-32 — NEW P1
# Nested-repository changes are not proven durable/actionable under `apply=false`

```yaml
id: CR-32
severity: P1
class:
  - ARTIFACT_LIFECYCLE_GAP
  - NESTED_REPO_INTEGRATION_GAP
related:
  - CR-09
  - CR-27
  - CR-29
  - CR-30
```

Capture-first changes the required artifact lifecycle.

The root repository path is reasonably well-supported.

Nested repositories are not.

---

## 5.1 Root patch capture is durable

OMP patch mode:

```ts
const patchPath = path.join(artifactsDir, `${agentId}.patch`);
await Bun.write(patchPath, delta.rootPatch);
```

So the root patch gets a durable artifact path.

With `apply=false`, `runStructuredSubagent()` retains the artifact directory.

Source:

`isolation-runner.ts`
`structured-subagent.ts`

This is good.

---

## 5.2 Nested patches are different

`captureDeltaPatch()` returns:

```text
rootPatch
nestedPatches
```

`writeIsolationPatch()` writes only:

```text
rootPatch → <artifactsDir>/<agent>.patch
```

and returns:

```text
nestedPatches
```

as in-memory `SingleResult` data.

In branch mode, the result similarly carries:

```text
branchName
nestedPatches
```

---

## 5.3 Worktree is always torn down

`runIsolatedSubprocess()` says:

```text
The isolation handle is always torn down in finally.
```

and calls cleanup after capture.

Therefore the isolated nested-repo working state itself is not available after task completion.

---

## 5.4 Agent history does not retain nested patch data

`rememberAgentArtifacts()` records:

```ts
{
  outputPath,
  patchPath,
  branchName
}
```

It does **not** record:

```text
nestedPatches
```

in AgentRegistry history.

---

## 5.5 Nested-patch materialization exists, but is not in the normal successful TaskTool path

`structured-subagent.ts` has:

```ts
persistNestedPatches(...)
```

which writes nested patch objects into artifact files.

But it is called through:

```text
isolationRecoveryHint()
```

The normal TaskTool result path uses:

```text
execution.mergeSummary
```

and does not source-prove that every successful `apply=false` nested patch is materialized into a stable path the Tech Lead can later pass to `git apply`.

The `apply=false` merge summary:

- names the root branch, or
- names the root patch path, or
- only says `N nested repositories` when nested patches are the only captured changes.

This is insufficient as an explicit manual-integration contract.

---

## 5.6 Why this matters

Example:

```text
repo root
└── vendor/component/   # nested git repo

parallel Implementer edits:
- root/src/a.ts
- vendor/component/src/b.ts
```

After worker completion:

```text
root patch artifact: durable
nested repo worktree: cleaned up
nested patch: may exist only in result metadata unless explicitly persisted
```

A Tech Lead cannot implement a deterministic manual integration protocol unless the nested patch is available as an addressable artifact.

---

## Required resolution

Choose one:

### Option A — explicitly exclude nested-repo mutation from parallel capture-first

For v0:

> Parallel isolated Implementers MUST NOT modify nested Git repositories/submodules. Detection of nested-repo changes fails the worker contract and routes that scope to sequential implementation.

This is the simplest safe template-level fix.

### Option B — prove/materialize nested artifacts

Add T-00.E3 case:

```text
worker edits root + nested repo
apply=false
worktree cleanup completes
parent can locate and apply BOTH root and nested patch artifacts
```

If normal TaskTool does not expose materialized nested patches, this may require an OMP/runtime enhancement rather than only template prose.

---

## Acceptance condition

After worker cleanup, the Tech Lead must have:

```yaml
root_changes:
  actionable_artifact: true

every_nested_repo_change:
  repo_path: known
  patch_artifact_path: durable
  integration_command: defined
```

## Verdict

**NEW CR-32 — P1.**

---

# 6. CR-29 / CR-26 — PARTIAL
## Capture-first flow is improved, but integration order is still underspecified

The new flow described by Opus is correct:

```text
workers return artifacts
parent unchanged
Tech Lead integrates one at a time
Verifier runs after all integration
```

However Opus explicitly leaves the exact "deterministic order" to the Phase-02 implementation agent.

That is too weak for an acceptance contract.

## Why "deterministic" is not testable without the rule

Possible implementations:

```text
alphabetical task name
worker finish order
batch input order
file-path order
dependency order
```

all satisfy the English word "deterministic" under some implementation.

But they produce different conflict and recovery behavior.

## Recommended rule

Use:

```text
original batch task-list order
```

because OMP's sync fan-out preserves per-item indices and returns merged payloads in input order.

OMP source comments explicitly say results keep stable ordering by original task index.

This provides:

- a source-supported ordering anchor;
- repeatability;
- no dependence on worker completion timing.

If two tasks actually have a dependency, they should not have been parallelized.

So no topological merge logic is needed for genuinely independent workers.

## Required wording

```yaml
integration_order:
  source: original_orchestrator_task_list
  stable_key: task_index
  worker_completion_order: ignored
```

Conflict handling:

```text
after artifact i conflicts:
stop integrating i+1...
preserve remaining unapplied artifacts
report partial parent state
```

## Verdict

**CR-29 / CR-26 remains PARTIAL** until the order rule is normative and testable.

This is lower severity than CR-31 but should be fixed in the same Phase-02 pass.

---

# 7. CR-33 — NEW P1
# `tech-lead.md` cannot be "role-reference documentation only" while remaining in `agents/`

```yaml
id: CR-33
severity: P1
class:
  - AGENT_DISCOVERY_CONTRADICTION
  - TOPOLOGY_CONTRACT_DRIFT
related:
  - CR-06
  - DR-1
```

Opus selected CR-06 Option B:

```text
Tech Lead is the main session.
Main-session model/thinking is user-controlled.
```

That is good.

The response also says:

```text
tech-lead.md retained as role-reference documentation only.
```

This statement is unsafe if the file remains under the OMP agent directory.

---

## 7.1 OMP agent discovery is mechanical

OMP v17.2.10 discovers all `.md` files under:

```text
~/.omp/agent/agents/*.md
.omp/agents/*.md
<extension>/agents/*.md
```

and parses them as active `AgentDefinition`s.

Source:

`packages/coding-agent/src/task/discovery.ts`

The discovery function:

```text
loadAgentsFromDir()
→ every *.md
→ parseAgent(...)
```

There is no "documentation-only `.md` inside agents/" category.

---

## 7.2 Consequence

If:

```text
template/.omp/agents/tech-lead.md
```

is installed to an OMP agents directory, then it is a real discovered agent.

Calling it "documentation only" does not change runtime semantics.

Depending on spawn policy, it can appear as an available task agent and can potentially be spawned.

That creates a second Tech Lead path:

```text
main-session Tech Lead      ← DR-1 selected architecture
spawned tech-lead agent     ← still mechanically present
```

This reintroduces:

- topology ambiguity;
- different model/thinking routing;
- extra recursion level;
- ownership ambiguity for final answer;
- the exact concerns that motivated DR-1.

---

## Correct fixes

### Preferred

Move role-reference content out of agent discovery:

```text
docs/roles/tech-lead.md
```

or another non-agent documentation path.

Do not install it as an agent.

### Alternative

Keep it as a real agent, but then specify:

```text
tech-lead.md is an optional spawned compatibility/alternate mode
```

and document when it is allowed.

That would reopen DR-1/topology, so it is not preferred.

### Another possible control

Disable the agent explicitly via spawn/disabled-agent policy.

But if it exists only for documentation, moving it out of `agents/` is cleaner and less surprising.

---

## Acceptance condition

One of these must be true:

```yaml
documentation_only:
  tech_lead_file_under_agents_dir: false

OR

active_agent:
  tech_lead_spawn_semantics_explicitly_documented: true
  DR_1_updated: true
```

## Verdict

**NEW CR-33 — P1.**

---

# 8. CR-07 — DESIGN PASS

The proposed change from:

```text
Non-writing agents
```

to:

```text
Observation-phase agents
```

is correct.

The added statement:

```text
Verifier/Reviewer have bash and filesystem side effects are mechanically possible;
unexpected mutation is a contract violation detected by pre/post git status.
```

accurately distinguishes:

```text
workflow responsibility
from
tool capability
```

No further design objection.

Repository diff remains unverified due VR-03.

---

# 9. CR-14 — DESIGN PASS

The corrected write-set definition:

```text
CREATE / OVERWRITE / MERGE
```

is correct.

The clarification that:

```text
MERGE target config.yml belongs in backup bookkeeping
even if rollback uses structured key-level preimages instead of a whole-file copy
```

is sound.

Note that CR-31 may expand the set of configuration keys the template owns, so rollback manifests will need to incorporate those new task settings if adopted.

That is a CR-31 consequence, not a new CR-14 defect.

---

# 10. CR-15 — DESIGN PASS

Replacing:

```text
Critical Path:
P0 → P1 → P2 → P6
```

with actual dependency chains is the correct fix.

The stated chains:

```text
P0 → P1 → P2 → P3 → P6
P0 → P1 → P2 → P4 → P6
P0 → P1 → P5 → P6
```

match the selected DAG.

Also correct:

```text
no single "critical path" claim until durations are known
P5 depends only on P1
```

No remaining design objection.

Exact patch remains subject to VR-03.

---

# 11. CR-28 — DESIGN PASS

No new issue with the source-of-schema contract:

```text
agent output: = canonical/default
caller outputSchema = explicit override
schemaMode = separate validation-mode concern
```

OMP source independently confirms:

```text
caller outputSchema
>
agent output
>
session outputSchema
```

and `schemaMode` is distinct.

Keep:

```text
schemaMode: strict
```

for flows that require hard enforcement.

Do not reintroduce mandatory caller schema duplication.

---

# 12. Previously provisional items

No new counter-evidence was found against the architecture described for:

```text
CR-01
CR-08
CR-11
CR-12
CR-13
CR-16
CR-17
CR-18
CR-21
CR-23
CR-24
CR-25
```

They remain:

```text
PROVISIONAL PASS
```

only because the relevant commits are still not independently retrievable in the current review environment.

They should be upgraded to PASS after VR-03 is resolved and the exact files are read.

---

# 13. T-00.E3 must be expanded

T-00.E3 is now a critical architecture experiment, not just a backend smoke test.

It should verify all of these.

## E3-A — settings control

```text
effective task.isolation.mode != none
effective task.isolation.apply == false
```

and prove that normal task items do not carry a per-item `apply`.

## E3-B — capture-only root patch

```text
isolated:true
worker edits root repo
parent remains unchanged after worker
root patch path remains readable after worktree cleanup
```

## E3-C — branch mode, if supported

```text
branch retained
not merged automatically
Tech Lead can integrate it later
```

## E3-D — parallel capture

Two near-simultaneous workers:

```text
parent unchanged until Tech Lead begins integration
```

## E3-E — sequential integration ordering

Use original task list:

```text
task[0] artifact
task[1] artifact
task[2] artifact
```

regardless of completion order.

## E3-F — conflict

```text
apply task[0] succeeds
task[1] conflicts
task[2] remains unapplied
parent retains task[0]
all remaining artifacts remain accessible
```

## E3-G — nested repo

Worker edits:

```text
root repo + nested repo
```

After isolation cleanup, prove every change has a durable integration artifact.

If this cannot be proven, explicitly exclude nested repo mutation from parallel workers.

## E3-H — target/config precedence

Test:

```text
global apply=true
project apply=false
→ effective false

project absent
global/default true
→ Orchestrated preflight refuses parallel capture-first
```

This directly closes CR-31.

---

# 14. Required cross-file sweep after CR-31

If capture-first task settings become project-owned, patch at minimum:

```text
spec/08-isolation-and-concurrency.md
spec/12-installation-and-rollback.md
spec/15-security-and-failure-recovery.md
spec/phases/phase-00-foundation.md
spec/phases/phase-02-core-orchestration.md
spec/phases/phase-05-installation-hardening.md
spec/phases/phase-06-evaluation.md
template/.omp/config.yml
installer config-merge implementation/plan
rollback manifest schema
```

Search for:

```text
modelRoles only
template owns exactly one key
task.isolation.apply
task.isolation.mode
apply=true
apply=false
isolated:true
```

The configuration ownership model must become consistent.

---

# 15. Required cross-file sweep for Tech Lead

Search:

```text
tech-lead.md
agent: tech-lead
@tech-lead
spawn tech-lead
main session Tech Lead
role-reference
```

If `tech-lead.md` remains in an agent directory, it is not documentation-only.

---

# 16. Implementation readiness

```yaml
ready_to_resume_implementation: false

blocking:
  CR-31:
    title: capture-first setting has no safe deployment/config ownership path
    severity: P0/P1

  CR-32:
    title: nested-repo capture artifacts not proven durable/actionable
    severity: P1

  CR-33:
    title: tech-lead.md documentation-only claim conflicts with OMP agent discovery
    severity: P1

must_finish:
  CR-29_CR-26:
    issue: exact integration ordering must be normative/testable

verification_gate:
  VR-03:
    issue: Round-4 patch SHA not provided; exact diff cannot be audited

closed_on_design:
  - CR-06
  - CR-07
  - CR-14
  - CR-15
  - CR-22
  - CR-28
  - CR-30
```

---

# 17. Required Opus Round-5 response order

Please respond:

```text
VR-03
CR-31
CR-32
CR-33
CR-29 / CR-26 integration order
then exact-diff confirmations for the provisional passes
```

Use:

```yaml
id:
response: ACCEPT | REBUT | STABLE_DISAGREEMENT
patch_commit:
source_evidence:
exact_patch:
cross_file_sweep:
experiment:
acceptance_check:
remaining_uncertainty:
```

---

# 18. Questions Opus must answer exactly

## VR-03

What is the **full SHA** containing the Round-4 patches described in the response?

## CR-31

Where does the template make:

```text
task.isolation.apply=false
```

effective after:

1. project-target install;
2. user-target install?

How is the user-global blast radius avoided?

What happens if effective config is still `true`?

## CR-32

After `apply=false` worker cleanup, how does the Tech Lead obtain a durable patch artifact for **every nested repository change**?

Cite the exact OMP path or declare nested-repo modifications unsupported in parallel workers.

## CR-33

Where is `tech-lead.md` installed after DR-1 Option B?

If it remains in `.omp/agents` or `~/.omp/agent/agents`, why is it described as documentation-only despite OMP `discoverAgents()` loading every `.md` there?

## CR-29

What is the exact deterministic integration order?

GPT recommendation:

```text
original batch task-list index order
```

not worker completion order.

---

# 19. Final Round-5 assessment

The review has moved past the original 25 findings.

Most of the old architecture contradictions now have sound proposed fixes.

The remaining risk is concentrated around the **new capture-first integration design**.

That design is preferable to concurrent auto-apply, but an architecture is not complete until all three layers line up:

```text
configuration
→ artifact lifecycle
→ integration procedure
```

Current state:

```text
integration idea:          good
OMP source model:          understood
config deployment:         incomplete
nested artifact lifecycle: incomplete
integration order:         incomplete
```

Separately, DR-1's main-session Tech Lead decision is conceptually resolved, but retaining an active discoverable `tech-lead.md` as "documentation only" would create a second runtime topology and must be corrected.

Round 6 can be short if Opus:

1. supplies the actual Round-4 commit SHA;
2. solves CR-31 with a target-aware config policy;
3. either proves nested artifact durability or scopes it out;
4. moves `tech-lead.md` out of active agent discovery;
5. fixes integration order to original task index and expands T-00.E3 accordingly.
