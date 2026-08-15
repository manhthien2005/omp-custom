# Topic 08 Portable Behavior Core and Runtime Adapters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this
> plan task-by-task. Execute inline in the main session. Do not dispatch subagents unless the user
> later explicitly requests delegation and it has a concrete benefit.

**Goal:** Build the approved three-skill portable behavior core, explicit Topic 04 lifecycle tool,
fail-closed OMP behavior gates, runtime-adapter contracts, deterministic validation, and local
evidence without adding semantic automation or a Claude runtime claim.

**Architecture:** A closed JSON behavior manifest is validated by a dependency-light JavaScript
core. The existing `agent-task-boundary` extension registers the explicit main-session
`agent_tasks` lifecycle tool, reconciles OMP's effective skill/agent catalogs before managed
dispatch, and blocks mutation-capable tools when no valid managed binding exists. OMP is the only
executable adapter; Claude remains a complete, non-installable `DESIGNED_NOT_VERIFIED` mapping.

**Tech Stack:** JavaScript ES modules with Node built-ins and `node:test`; OMP extension API;
PowerShell 7.4+ and Pester 5; JSON/YAML manifests and fixtures; existing Topic 04/06/07 cores.

**Spec:**
`docs/superpowers/specs/2026-08-14-topic-08-portable-behavior-core-runtime-adapters-design.md`

## Global Constraints

- Work only in `D:\Dev\Projects\omp-template`; preserve every unrelated dirty or untracked file.
- Do not create/switch a branch or worktree, stage, commit, push, open a PR, download a runtime, or
  install into the live user OMP directory.
- Do not dispatch a subagent. Implementation is inline and checkpointed after each task.
- OMP source authority remains clean SHA
  `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (17.2.10). Use an already-installed 17.2.12 only for
  a no-network canary; record 17.2.10 runtime absence instead of downloading it.
- Use Node built-ins only for the portable core. Do not add a package dependency.
- Keep exactly the selected v1 roster: `task-triage`, `systematic-debugging`, and
  `evidence-before-completion`. The manifest, not a fixed code constant, selects the roster.
- Only Worker autoloads `evidence-before-completion`; Cheap Scout and Reviewer autoload nothing.
- Keep the visible-skill soft cap at 10, hard cap at 12, one description at no more than 80
  approximate tokens, total listing at no more than 900, Worker autoload body at no more than 500,
  each lazy body at no more than 900, and `RULES.md` target maximum at 700 with warning above 800.
- A safety predicate that cannot be evaluated fails closed for managed dispatch and
  mutation-capable tools. Read/grep/glob and permitted retrieval remain available for diagnosis.
  Observation/logging failure warns and cannot change authorization.
- Hooks never infer task meaning, create a task, select workflow/role/model/effort, accept a
  candidate, or choose Git behavior.
- The manifest assigns each behavior to one injection owner. MCP and external tools declare
  capability only, with `policy_authority: false` and `workflow_selection: false`.
- The `agent_tasks` tool supplies trusted runtime/session/workspace fields and exposes only the
  routine operation allowlist from the spec. Authority-sensitive operations remain manual.
- Keep `context-continuity.js` semantically unchanged unless a manifest/path integration is
  mechanically required. Re-run Topic 07 tests after any byte change.
- Do not create Claude runtime files. Claude adapter status stays `DESIGNED_NOT_VERIFIED` and
  `installable: false`.
- Use `apply_patch` for source edits. Run focused RED/GREEN checks before the single final full
  validator pass.

---

## File Responsibility Map

### New runtime/core files

- `template/.omp/contracts/behavior-core-schema.mjs` — closed constants, limits, statuses, reason
  codes, operation allowlist, and mutation/read tool sets.
- `template/.omp/contracts/behavior-core.mjs` — pure manifest validation, token estimation, catalog
  reconciliation, and tool-boundary decisions; imports no OMP API.
- `template/.omp/contracts/behavior-manifest.json` — selected v1 behavior authority and adapter map.

### New fixtures, scripts, tests, and evidence

- `evals/triggers/topic08/{task-triage,systematic-debugging,evidence-before-completion}-{positive,negative}.yml`
  — bounded trigger corpus.
- `evals/pressure/topic08/behavior-gates.json` — deterministic gate scenarios.
- `scripts/update-skill-lock.ps1` — atomically refreshes manifest skill hashes and the generated
  registry lock, or checks them without writing.
- `scripts/lib/topic08-behavior-core.ps1` — focused source attachments and validation assertions.
- `scripts/validate-topic08-behavior-core.ps1` — human/JSON validator entry point.
- `scripts/capture-topic08-evidence.ps1` — local deterministic evidence and runtime matrix capture.
- `scripts/tests/topic08-behavior-core.Tests.mjs` — pure core tests.
- `scripts/tests/topic08-skill-contracts.Tests.mjs` — roster, budget, trigger, hash, and autoload tests.
- `scripts/tests/topic08-agent-tasks-tool.Tests.mjs` — explicit lifecycle-tool tests.
- `scripts/tests/topic08-behavior-gates.Tests.mjs` — discovery reconciliation and tool-call gate tests.
- `scripts/tests/topic08-installer.Tests.ps1` — install/update/uninstall ownership tests.
- `scripts/tests/topic08-validator-mutations.Tests.ps1` — one-defect-at-a-time validator mutations.
- `docs/behavior-core.md` — concise human operating and extension guide.
- `docs/evidence/current-product/topic-08/{deterministic.json,manifest.json,behavior-manifest.json}`
  — generated current-product evidence and last-known-good local snapshot.
- `codex-topic08-portable-behavior-core-runtime-adapters-changelog.md` — local implementation ledger.

### Existing files changed by bounded ownership

- `template/.omp/agents/worker.md` — the sole autoload binding.
- `template/.omp/agents/{cheap-scout,reviewer}.md` — asserted unchanged in autoload semantics.
- `template/.omp/skills/*/SKILL.md` — concise triggers and bodies; shorten the Worker autoload body.
- `template/.omp/extensions/agent-task-boundary.js` — lifecycle tool, catalog reconciliation, and
  deterministic tool-call gate.
- `template/.omp/contracts/component-manifest.json` — hashes and skill dependency coverage.
- `registry/{skill-lock,adoption-ledger,licenses,upstreams}.yml` — generated hashes and corrected
  provenance/removed-Verifier ownership.
- `scripts/{install-template,uninstall-template,validate-template}.ps1` — component dependency,
  ownership, and full-validator integration.
- `spec/11-skills-rules-and-quality-gates.md`, `spec/12-installation-and-rollback.md`,
  `spec/13-validation-and-evaluation.md`, `spec/README.md`, `spec/key/01-dna.md`,
  `spec/key/03-token-quality-model.md`, `spec/phases/phase-02-core-orchestration.md`, and
  `spec/phases/phase-06-evaluation.md` — narrow active projections or supersession fences.
- `README.md`, `docs/{architecture,customization,installation,rollback,workflow-v0,final-report}.md`,
  and `template/.omp/schemas/verification-result.schema.yml` — current-product wording only.

---

### Task 1: Portable Behavior Schema and Pure Core

**Files:**

- Create: `template/.omp/contracts/behavior-core-schema.mjs`
- Create: `template/.omp/contracts/behavior-core.mjs`
- Create: `scripts/tests/topic08-behavior-core.Tests.mjs`

**Interfaces:**

- Produces `BEHAVIOR_LIMITS`, `BEHAVIOR_REASON_CODES`, `ADAPTER_STATUSES`,
  `LIFECYCLE_OPERATIONS`, `MUTATION_CAPABLE_TOOLS`, and `DIAGNOSTIC_TOOLS`.
- Produces `estimateApproxTokens(text) -> number` using `Math.ceil(text.length / 4)`.
- Produces `validateBehaviorManifest(value) -> {ok:true,value}|{ok:false,reason_code,message}`.
- Produces `reconcileBehaviorCatalog(input) -> {ok:true,value}|failure`, where `input` contains
  `manifest`, `ompRoot`, `agents`, `skills`, and a project-relative `fileHashes` map.
- Produces `decideToolBoundary(input) -> {allow:true}|{allow:false,reason_code,message}`.
- Consumes `canonicalJson` from `agent-boundary-core.mjs`; imports no OMP runtime module.

- [ ] **Step 1: Write RED tests for constants, closed manifest validation, and budgets**

Create tests that construct a valid in-memory manifest and then mutate exactly one field:

```js
import assert from "node:assert/strict";
import test from "node:test";

import {
  BEHAVIOR_LIMITS,
  LIFECYCLE_OPERATIONS,
} from "../../template/.omp/contracts/behavior-core-schema.mjs";
import {
  estimateApproxTokens,
  validateBehaviorManifest,
} from "../../template/.omp/contracts/behavior-core.mjs";

test("exports the approved Topic 08 limits and routine lifecycle operations", () => {
  assert.deepEqual(BEHAVIOR_LIMITS, {
    rulesTargetMaxTokens: 700,
    rulesHardWarningTokens: 800,
    skillDescriptionMaxTokens: 80,
    visibleCatalogMaxTokens: 900,
    visibleSkillSoftCap: 10,
    visibleSkillHardCap: 12,
    workerAutoloadBodyMaxTokens: 500,
    lazySkillBodyMaxTokens: 900,
    maxManifestBytes: 65536,
  });
  assert.equal(LIFECYCLE_OPERATIONS.has("create-task"), true);
  assert.equal(LIFECYCLE_OPERATIONS.has("purge"), false);
  assert.equal(estimateApproxTokens("12345"), 2);
});

test("rejects unknown keys and a Claude adapter that can install", () => {
  const extra = validManifest();
  extra.unreviewed = true;
  assert.equal(validateBehaviorManifest(extra).reason_code, "BHV-MANIFEST-INVALID");

  const unsafeClaude = validManifest();
  unsafeClaude.adapters.claude.installable = true;
  assert.equal(validateBehaviorManifest(unsafeClaude).reason_code, "BHV-ADAPTER-UNSUPPORTED");
});

test("selects skills through data rather than a hard-coded count", () => {
  const expanded = validManifest();
  expanded.skills.push(activeFourthSkill());
  expanded.provenance.push(projectOwnedFourthSkillProvenance());
  assert.equal(validateBehaviorManifest(expanded).ok, true);

  const retiredConsumer = validManifest();
  retiredConsumer.skills[2].status = "deprecated";
  assert.equal(validateBehaviorManifest(retiredConsumer).reason_code, "BHV-AUTOLOAD-MISMATCH");
});

test("rejects duplicate injection authority and policy-bearing external tools", () => {
  const duplicateOwner = validManifest();
  duplicateOwner.hooks[0].behavior_ids.push("role.worker.identity");
  assert.equal(validateBehaviorManifest(duplicateOwner).reason_code, "BHV-MANIFEST-INVALID");

  const policyTool = validManifest();
  policyTool.tools.external_capabilities.policy_authority = true;
  assert.equal(validateBehaviorManifest(policyTool).reason_code, "BHV-MANIFEST-INVALID");
});
```

The `validManifest()` fixture must contain the exact top-level keys and selected three skill/role
rows from design sections 7, 9, 11, 12, 14, and 15. `activeFourthSkill()` returns an active lazy,
visible skill with unique path/hash/fixture/provenance references and no autoload role;
`projectOwnedFourthSkillProvenance()` supplies its matching project-owned license row. These helpers
prove later expansion changes manifest data rather than the core's selected-name logic.

- [ ] **Step 2: Run the focused core test and confirm RED**

Run:

```powershell
node --test scripts/tests/topic08-behavior-core.Tests.mjs
```

Expected: non-zero exit because both behavior-core modules do not exist.

- [ ] **Step 3: Implement the closed constants and result vocabulary**

Use these exact exported sets:

```js
export const BEHAVIOR_REASON_CODES = Object.freeze(new Set([
  "BHV-MANIFEST-INVALID",
  "BHV-SKILL-MISSING",
  "BHV-SKILL-SHADOWED",
  "BHV-SKILL-HASH-MISMATCH",
  "BHV-AUTOLOAD-MISMATCH",
  "BHV-STATE-MISSING",
  "BHV-STATE-AMBIGUOUS",
  "BHV-LIFECYCLE-FORBIDDEN",
  "BHV-HOOK-UNAVAILABLE",
  "BHV-BUDGET-EXCEEDED",
  "BHV-ADAPTER-UNSUPPORTED",
]));

export const ADAPTER_STATUSES = Object.freeze(new Set([
  "SELECTED_FOR_IMPLEMENTATION",
  "IMPLEMENTED_NOT_PROMOTED",
  "DESIGNED_NOT_VERIFIED",
]));

export const LIFECYCLE_OPERATIONS = Object.freeze(new Set([
  "init-project", "status", "create-phase", "transition-phase", "create-task",
  "set-continuity-contract", "bind-worktree", "checkpoint", "claim",
  "create-work-unit", "freeze", "check", "promote-artifact", "record-evidence",
  "begin-handoff", "accept-handoff", "close", "invalidate",
]));

export const MUTATION_CAPABLE_TOOLS = Object.freeze(new Set(["edit", "write", "bash"]));
export const DIAGNOSTIC_TOOLS = Object.freeze(new Set([
  "read", "grep", "glob", "web_search", "ast_grep", "lsp",
]));
```

- [ ] **Step 4: Implement closed manifest validation and pure decisions**

`validateBehaviorManifest` must perform these checks in this order and return the first bounded
failure:

```text
JSON-compatible closed object and <= 65536 canonical UTF-8 bytes
-> exact schema_version/record_type/component/component_version/reviewed_on
-> exact constitution/budgets/skills/roles/commands/hooks/tools/adapters/provenance keys
-> unique skill names and paths; active rows require lowercase 64-hex hashes and fixture/provenance
-> deprecated/removed rows cannot be visible, autoloaded, or required by a role
-> visible count <= 12 and declared budgets equal approved values
-> exact selected roles cheap-scout/worker/reviewer
-> worker required_autoload == [evidence-before-completion]
-> cheap-scout/reviewer required_autoload == []
-> exact quick/standard/orchestrated commands
-> every behavior_id has one primary owner; only the declared evidence duplication crosses owners
-> MCP/external capability rows set policy_authority false and workflow_selection false
-> OMP status SELECTED_FOR_IMPLEMENTATION with installable false, or
   IMPLEMENTED_NOT_PROMOTED with installable true
-> Claude status DESIGNED_NOT_VERIFIED and installable false
-> every active skill references one provenance row and two distinct trigger fixture paths
```

Implement the common result helpers exactly once:

```js
const success = value => ({ ok: true, value });
const failure = (reason_code, message) => ({
  ok: false,
  reason_code,
  message: String(message).slice(0, 240),
});

export function estimateApproxTokens(text) {
  if (typeof text !== "string") throw new TypeError("text must be a string");
  return Math.ceil(text.length / 4);
}
```

`reconcileBehaviorCatalog` must compare effective discovered skill name, normalized absolute path,
`hide !== true`, hash, and each agent's exact `autoloadSkills` list. `decideToolBoundary` must allow
diagnostic tools, require `stateKind: "one"` for main-session `edit`/`write`/`bash`, accept a
validated bounded packet for a managed child, and otherwise return a fail-closed reason.

- [ ] **Step 5: Run core tests to GREEN**

Run the same Node command. Expected: all Topic 08 core tests pass with exit 0.

- [ ] **Step 6: Record the Task 1 local checkpoint**

Run `git diff --check` limited to the three Task 1 paths. Expected: exit 0. Do not stage or commit.

---

### Task 2: Selected Skills, Trigger Fixtures, Behavior Manifest, and Lock Generation

**Files:**

- Modify: `template/.omp/agents/worker.md`
- Assert/no semantic autoload change: `template/.omp/agents/cheap-scout.md`
- Assert/no semantic autoload change: `template/.omp/agents/reviewer.md`
- Modify: `template/.omp/skills/task-triage/SKILL.md`
- Modify: `template/.omp/skills/systematic-debugging/SKILL.md`
- Modify: `template/.omp/skills/evidence-before-completion/SKILL.md`
- Create: six files under `evals/triggers/topic08/`
- Create: `template/.omp/contracts/behavior-manifest.json`
- Create: `scripts/update-skill-lock.ps1`
- Modify: `registry/skill-lock.yml`
- Modify: `registry/adoption-ledger.yml`
- Assert unchanged: `registry/licenses.yml`, `registry/upstreams.yml`
- Create: `scripts/tests/topic08-skill-contracts.Tests.mjs`

**Interfaces:**

- Consumes Task 1 limits and `validateBehaviorManifest`.
- Produces exact Worker `autoloadSkills: ["evidence-before-completion"]`.
- Produces active skill hashes consumed by Tasks 4–6.
- Produces `scripts/update-skill-lock.ps1 -Check`, which writes nothing and exits non-zero on drift.

- [ ] **Step 1: Write RED tests for roster, descriptions, bodies, fixtures, and autoload**

The tests must parse frontmatter, read the actual behavior manifest, and assert:

```js
assert.deepEqual(manifest.skills.map(skill => skill.name), [
  "task-triage",
  "systematic-debugging",
  "evidence-before-completion",
]);
assert.deepEqual(worker.autoloadSkills, ["evidence-before-completion"]);
assert.deepEqual(cheapScout.autoloadSkills ?? [], []);
assert.deepEqual(reviewer.autoloadSkills ?? [], []);
assert.ok(estimateApproxTokens(evidence.body) <= 500);
assert.ok(estimateApproxTokens(taskTriage.body) <= 900);
assert.ok(estimateApproxTokens(systematicDebugging.body) <= 900);
assert.ok(skills.every(skill => estimateApproxTokens(skill.description) <= 80));
assert.ok(skills.reduce((sum, skill) => sum + estimateApproxTokens(skill.description), 0) <= 900);
assert.ok(estimateApproxTokens(rulesText) <= 700);
assert.ok(manifest.skills.every(skill => /^[a-f0-9]{64}$/u.test(skill.sha256)));
```

Also assert that every positive/negative fixture is non-empty and unique, `task-triage` negatives
include all three explicit workflow commands, no selected skill sets `alwaysApply`, and every
active skill maps to a non-null provenance/license record. Assert that `.omp/SYSTEM.md` is absent;
the portable constitution must remain `RULES.md` rather than replace OMP's native system prompt.

- [ ] **Step 2: Run the skill-contract test and confirm RED**

Run:

```powershell
node --test scripts/tests/topic08-skill-contracts.Tests.mjs
```

Expected: non-zero because the behavior manifest/fixtures/generator do not exist and Worker lacks
the autoload entry.

- [ ] **Step 3: Tighten the three descriptions and replace the autoload body**

Use description-only trigger language. Keep the existing four-phase debugging body, but keep its
body within 900 approximate tokens. Replace `evidence-before-completion` body with this compact
contract after its frontmatter:

```markdown
# Evidence Before Completion

## Rule

NO COMPLETION CLAIM WITHOUT FRESH VERIFICATION EVIDENCE IN THIS WORKER SESSION.

Before returning `completed`:

1. Read the packet's required verification commands and mandatory acceptance criteria.
2. Run every required command now in this worker session.
3. Read complete output and exit status; do not infer success from silence.
4. Bind each passed observation to the acceptance criterion it supports.
5. Return `completed` only when all mandatory evidence exists. Otherwise return `partial`,
   `blocked`, or `failed` with the exact gap.

A prior run, another agent's report, code that merely looks correct, or a partial test set is not
fresh proof. Report observations through the Worker result schema. Never accept or close the parent
task; the Tech Lead owns integration and acceptance.
```

Set Worker frontmatter to the OMP-native JSON-array form:

```yaml
autoloadSkills: ["evidence-before-completion"]
```

- [ ] **Step 4: Create exact trigger fixtures**

Use this closed YAML shape for all six files:

```yaml
schema_version: 1
record_type: topic08_skill_trigger_fixture
skill: task-triage
expectation: should_trigger
cases:
  - "Improve the API; the desired behavior and success criteria are not specified."
  - "Handle this request; it has no prefix and the workflow size is unclear."
  - "Implement the change, but scope and mandatory acceptance criteria are missing."
```

The corresponding `task-triage-negative.yml` cases must include explicit `/quick`, `/standard`,
and `/orchestrated`. Debugging positives cover a reproducible failure, intermittent unknown cause,
and second failed fix; negatives cover a new feature, planned refactor, typo, and review-only
finding. Evidence positives cover done/fixed/passing claims; negatives cover progress, planning,
honest failed/blocked/partial status, and Cheap Scout evidence return.

- [ ] **Step 5: Create the selected behavior manifest and hash generator**

Create a closed manifest with:

```json
{
  "schema_version": 1,
  "record_type": "portable_behavior_manifest",
  "component": "behavior-core",
  "component_version": "1.0.0",
  "reviewed_on": "2026-08-14",
  "constitution": {
    "path": ".omp/RULES.md",
    "intentional_duplications": ["evidence-before-completion"]
  },
  "budgets": {
    "rules_target_max_tokens": 700,
    "rules_hard_warning_tokens": 800,
    "skill_description_max_tokens": 80,
    "visible_catalog_max_tokens": 900,
    "visible_skill_soft_cap": 10,
    "visible_skill_hard_cap": 12,
    "worker_autoload_body_max_tokens": 500,
    "lazy_skill_body_max_tokens": 900
  }
}
```

Add the exact closed `skills`, `roles`, `commands`, `hooks`, `tools`, `adapters`, and `provenance`
rows from the approved design. Use 64 zeroes only as the explicit pre-generation RED sentinel for
each initial skill hash. Set OMP to `SELECTED_FOR_IMPLEMENTATION` and `installable: false` until
Task 5 settles the executable adapter and component preflight.

`scripts/update-skill-lock.ps1` must:

```text
resolve RepositoryRoot and refuse paths outside it
-> parse and validate behavior-manifest.json
-> hash each active selected SKILL.md as UTF-8 bytes
-> replace each zero/stale manifest sha256 in stable skill order
-> generate registry/skill-lock.yml from the refreshed manifest
-> write both through same-directory temporary files and atomic Move-Item
-> -Check compares only and writes no bytes
```

For lifecycle transitions, the generator refuses a `deprecated` skill that is still visible,
autoloaded, or required by a role, and ignores a `removed` row when hashing installed files while
retaining its provenance/history row.

The generated lock has `version: "2.0"`, `source_manifest`, `component_version`, `reviewed_on`, and
the exact three name/path/hash rows. Remove the stale `post-v0`, null-hash, and removed-Verifier
claims from active registry records while preserving provenance history.

- [ ] **Step 6: Generate hashes, then run the skill tests to GREEN**

Run:

```powershell
pwsh -NoProfile -File scripts/update-skill-lock.ps1 -RepositoryRoot .
pwsh -NoProfile -File scripts/update-skill-lock.ps1 -RepositoryRoot . -Check
node --test scripts/tests/topic08-skill-contracts.Tests.mjs
```

Expected: generator exit 0, check mode exit 0 with no changed bytes, and all skill tests pass.

- [ ] **Step 7: Record the Task 2 local checkpoint**

Run `git diff --check` for Task 2 paths. Expected: exit 0. Do not stage or commit.

---

### Task 3: Explicit Main-Session `agent_tasks` Lifecycle Tool

**Files:**

- Modify: `template/.omp/extensions/agent-task-boundary.js`
- Create: `scripts/tests/topic08-agent-tasks-tool.Tests.mjs`
- Create: `evals/pressure/topic08/behavior-gates.json`

**Interfaces:**

- Consumes `LIFECYCLE_OPERATIONS` and existing `invokeManagedState`.
- Produces `createAgentTasksTool(pi, runtime, dependencies)` for direct unit tests.
- Keeps private helpers with exact signatures:
  `buildAgentTasksParameters(pi)`, `isMainSession(ctx) -> boolean`,
  `lifecycleToolResult(envelope) -> toolResult`, and
  `lifecycleToolFailure(operation,reasonCode) -> toolResult`.
- Tool input is exactly `{operation, request}`; adapter fills trusted schema/workspace/session/runtime.
- Tool output details are exactly
  `{schema_version,record_type,operation,ok,code,data}` with record type
  `agent_tasks_tool_details`.

- [ ] **Step 1: Write RED tests for lifecycle allowlist and trusted envelope ownership**

Test an injected `invokeState` spy:

```js
test("agent_tasks creates state only from the main session and trusted adapter fields", async () => {
  const calls = [];
  const tool = createAgentTasksTool(fakePi(), runtime(), {
    invokeState: async (operation, request, ctx) => {
      calls.push({ operation, request, cwd: ctx.cwd, session: ctx.sessionManager.getSessionId() });
      return { ok: true, code: "AT-OK", operation, data: { task_id: "T000001" } };
    },
  });
  const result = await tool.execute("call-1", {
    operation: "create-task",
    request: acceptedTaskContract(),
  }, undefined, undefined, mainContext());
  assert.equal(result.isError, false);
  assert.deepEqual(calls.map(call => call.operation), ["create-task"]);
  assert.equal(Object.hasOwn(calls[0].request, "session_ref"), false);
});
```

Add cases for `purge`, `takeover`, `cleanup`, unknown operation, bounded child invocation, invalid
session identity, state failure envelope, cancellation, and an observation callback that throws.
Define `fakePi()` with the same closed fake TypeBox builders used by
`topic06-omp-wrapper.Tests.mjs`; `runtime()` returns absolute `pwsh` and state-CLI paths;
`mainContext()` returns an absolute cwd, stable session ID, and a branch without `session_init`;
`acceptedTaskContract()` returns the complete Topic 04 `create-task` request including
`workflow_class` and `locked_decisions`.

- [ ] **Step 2: Run the tool test and confirm RED**

Run:

```powershell
node --test scripts/tests/topic08-agent-tasks-tool.Tests.mjs
```

Expected: non-zero because `createAgentTasksTool` is not exported.

- [ ] **Step 3: Implement the strict lifecycle tool in the existing extension**

Build TypeBox parameters from the allowlist and use the existing state client:

```js
export function createAgentTasksTool(pi, runtime, dependencies = {}) {
  const invokeState = dependencies.invokeState ?? ((operation, request, ctx, signal) =>
    invokeManagedState({
      pwshPath: runtime.paths.pwsh,
      stateCliPath: runtime.paths.state_cli,
      operation,
      request,
      ctx,
      signal,
      acceptNonzeroFailureEnvelope: true,
    }));

  return {
    name: "agent_tasks",
    label: "Managed Task Lifecycle",
    description: "Apply one explicit structured Topic 04 lifecycle operation after the task contract is accepted.",
    loadMode: "essential",
    approval: "exec",
    strict: true,
    parameters: buildAgentTasksParameters(pi),
    async execute(_id, params, signal, _onUpdate, ctx) {
      if (!isMainSession(ctx) || !LIFECYCLE_OPERATIONS.has(params.operation)) {
        return lifecycleToolFailure(params.operation, "BHV-LIFECYCLE-FORBIDDEN");
      }
      try {
        const envelope = await invokeState(params.operation, params.request, ctx, signal);
        return lifecycleToolResult(envelope);
      } catch (error) {
        return lifecycleToolFailure(params.operation,
          error?.message === "cancelled" ? "cancelled" : "BHV-HOOK-UNAVAILABLE");
      }
    },
  };
}
```

`isMainSession` requires a valid session ID and zero `session_init` entries. Multiple or malformed
entries are invalid. The tool must never parse user prose, shell text, or infer a missing request
field.

- [ ] **Step 4: Register both existing managed task dispatch and new lifecycle tool**

At factory settlement, register in deterministic order:

```js
const catalog = await pi.pi.discoverAgents(pi.cwd);
pi.registerTool(createAgentTasksTool(pi, runtime));
pi.registerTool(createManagedTaskTool(pi, runtime, catalog));
```

Do not add `agent_tasks` to Cheap Scout, Worker, or Reviewer tool allowlists.

- [ ] **Step 5: Create pressure fixture cases and run GREEN**

`behavior-gates.json` must include named cases for explicit bootstrap success, inferred bootstrap
refusal, authority-sensitive operation refusal, child lifecycle refusal, missing state mutation,
ambiguous state mutation, read-only diagnosis, valid main mutation, valid managed child binding,
missing skill, shadowed skill, hash drift, and logging failure.

Run the tool test again. Expected: all cases pass with exit 0.

- [ ] **Step 6: Re-run the existing Topic 06 extension tests**

Run:

```powershell
node --test scripts/tests/topic06-omp-wrapper.Tests.mjs
pwsh -NoProfile -Command "Invoke-Pester -Path 'scripts/tests/topic06-agent-boundary.Tests.ps1' -Output Detailed"
```

Expected: both pass; the existing managed `task` contract is unchanged.

---

### Task 4: Effective Catalog Reconciliation and Pre-Mutation Gates

**Files:**

- Modify: `template/.omp/extensions/agent-task-boundary.js`
- Modify: `template/.omp/contracts/behavior-core.mjs`
- Create: `scripts/tests/topic08-behavior-gates.Tests.mjs`

**Interfaces:**

- Consumes OMP `pi.pi.discoverAgents(pi.cwd)` and `pi.pi.discoverSkills(pi.cwd)`.
- Produces `loadBehaviorManifest(moduleUrl)` and
  `reconcileEffectiveBehavior({pi,runtime,manifest})` in the extension.
- Keeps private helpers with exact signatures:
  `buildCatalogSnapshot({runtime,manifest,agentCatalog,skillCatalog})`,
  `inspectBehaviorSession(ctx) -> {kind,agent,packet}`, and
  `behaviorBlock(reasonCode,message) -> {block:true,reason}`.
- Produces one `tool_call` handler. It returns `undefined` when allowed or
  `{block:true,reason}` when denied.
- Managed child proof is the single valid `session_init` plus a closed Topic 06 canonical packet;
  main proof is one successful `project-continuity` state envelope.

- [ ] **Step 1: Write RED catalog and gate tests**

Cover every pressure fixture and assert exact codes. The essential cases are:

```js
assert.equal(reconcile(validCatalog()).ok, true);
assert.equal(reconcile(withMissingEvidenceSkill()).reason_code, "BHV-SKILL-MISSING");
assert.equal(reconcile(withUserShadow()).reason_code, "BHV-SKILL-SHADOWED");
assert.equal(reconcile(withChangedEvidenceBytes()).reason_code, "BHV-SKILL-HASH-MISMATCH");
assert.equal(reconcile(withWorkerAutoload([])).reason_code, "BHV-AUTOLOAD-MISMATCH");

assert.deepEqual(await gate({ toolName: "read", state: "none" }), undefined);
assert.equal((await gate({ toolName: "bash", state: "none" })).block, true);
assert.deepEqual(await gate({ toolName: "bash", state: "one" }), undefined);
```

Add malformed/multiple child `session_init`, Cheap Scout mutation attempt, valid Worker packet,
valid Reviewer `bash` observation, invalid canonical packet, state CLI failure, and logger failure.
In the test harness, `reconcile(snapshot)` calls `reconcileBehaviorCatalog`; every `with*` helper
returns a fresh structured clone with exactly its named mutation; and `gate(input)` invokes the
registered `tool_call` handler with injected state/catalog dependencies.

- [ ] **Step 2: Run the behavior-gate test and confirm RED**

Run:

```powershell
node --test scripts/tests/topic08-behavior-gates.Tests.mjs
```

Expected: non-zero because discovery reconciliation and the hook are absent.

- [ ] **Step 3: Load and validate the installed behavior component**

`loadBehaviorManifest` must resolve the sibling contract path from `import.meta.url`, reject
symlinks or paths outside the installed `.omp`, parse with `parseJsonNoDuplicateKeys`, call
`validateBehaviorManifest`, and check the behavior files against the existing component manifest.
Return only a frozen validated value.

- [ ] **Step 4: Reconcile fresh effective catalogs before every managed dispatch**

Use the same OMP SDK functions native discovery uses:

```js
async function discoverAndReconcileBehavior(pi, runtime, manifest) {
  const [agentCatalog, skillCatalog] = await Promise.all([
    pi.pi.discoverAgents(pi.cwd),
    pi.pi.discoverSkills(pi.cwd),
  ]);
  const snapshot = buildCatalogSnapshot({ runtime, manifest, agentCatalog, skillCatalog });
  const result = behaviorCore.reconcileBehaviorCatalog(snapshot);
  if (!result.ok) throw new BehaviorUnavailableError(result.reason_code, result.message);
  return { agentCatalog, skillCatalog, behavior: result.value };
}
```

Call this once at extension initialization and again immediately before native `task` invocation.
Do not cache a success across dispatches. Compare the effective skill path and current file hash,
not only the skill name.

- [ ] **Step 5: Add the deterministic `tool_call` handler**

Implement this order:

```text
diagnostic tool -> allow
agent_tasks -> allow; its own strict tool gate decides
tool outside edit/write/bash -> allow
main session -> call project-continuity; exactly one valid projection allows
bounded child -> validate single session_init + exact selected role + closed Topic 06 packet
anything missing, ambiguous, malformed, or unavailable -> block with BHV reason
```

Do not parse `bash` command text. A read-only shell command is still blocked before task creation;
diagnosis uses declared non-mutating tools. Catch logger/notification errors after the decision so
observation cannot change it.

- [ ] **Step 6: Run Topic 08 gates and Topic 06/07 regression tests to GREEN**

Run:

```powershell
node --test scripts/tests/topic08-behavior-gates.Tests.mjs
node --test scripts/tests/topic06-omp-wrapper.Tests.mjs
node --test scripts/tests/topic06-result-receipt.Tests.mjs
node --test scripts/tests/topic07-omp-adapter.Tests.mjs
node --test scripts/tests/topic07-pressure-guard.Tests.mjs
```

Expected: every command exits 0.

---

### Task 5: Component Manifest, Installer, Uninstaller, and Runtime Ownership

**Files:**

- Modify: `template/.omp/contracts/component-manifest.json`
- Modify: `scripts/install-template.ps1`
- Modify: `scripts/uninstall-template.ps1`
- Modify: `scripts/validate-template.ps1`
- Create: `scripts/tests/topic08-installer.Tests.ps1`
- Modify: `scripts/tests/topic06-installer.Tests.ps1`
- Modify: `scripts/tests/topic07-managed-runtime.Tests.ps1`
- Modify: `scripts/lib/topic06-agent-boundary.ps1`
- Modify: `scripts/lib/topic07-context-continuity.ps1`

**Interfaces:**

- Agent-boundary component now depends on exact selected `skills` as well as agents, state, config.
- Three new behavior contract files are owned by agent-boundary; skill/agent files are dependencies
  and are not deleted by agent-boundary uninstall.
- Existing operational-state policy remains `retain_outside_target_omp`.
- Task 5 extends `update-skill-lock.ps1` so its final `-Check` also reconciles the behavior-contract,
  selected-skill, and selected-agent hashes mirrored by `component-manifest.json`.

- [ ] **Step 1: Write RED install/update/uninstall tests**

Create five explicit Pester cases. The first removes one selected skill from a temporary source and
asserts agent-boundary installation throws before the target changes. The second installs into an
empty temporary target and compares all three behavior-contract hashes to the component manifest.
The third changes one owned target byte, runs update, and proves exact source bytes replace it. The
fourth seeds selected skills plus an `agent-tasks` authority sentinel, uninstalls agent-boundary,
and proves only owned behavior files disappear. The fifth mutates the temporary Claude adapter to
`installable: true` and asserts preflight refuses with no target write. Use existing fixture helpers
and never touch the live user OMP directory.

- [ ] **Step 2: Run installer tests and confirm RED**

Run:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Path 'scripts/tests/topic08-installer.Tests.ps1' -Output Detailed"
```

Expected: failures for absent manifest ownership/dependency behavior.

- [ ] **Step 3: Extend component coverage without changing its schema version**

Keep `schema_version: 2` and bump `component_version` to `2.1.0`. Add owned hash rows for:

```text
.omp/contracts/behavior-core-schema.mjs
.omp/contracts/behavior-core.mjs
.omp/contracts/behavior-manifest.json
```

Add non-owned dependency/hash rows for the three selected skill files and update the changed Worker
hash. Add a `skills` dependency block naming the exact three installed paths. Recompute every
changed hash only after Tasks 1–4 settle.

After those files and preflights exist, change only the OMP adapter row from
`SELECTED_FOR_IMPLEMENTATION`/`false` to `IMPLEMENTED_NOT_PROMOTED`/`true`, regenerate the manifest
hash mirrors, and then run installer GREEN tests. No earlier task may make this status claim.

Extend `update-skill-lock.ps1` at this point to update, in one atomic settlement, the component
manifest rows for the three behavior contract files, three selected skill files, and three selected
agent files. In `-Check` mode it compares all three mirrors—behavior manifest, registry lock, and
component manifest—and writes nothing.

- [ ] **Step 4: Update installer and uninstaller ownership**

Installer preflight must require either component `skills` in the same operation or exact already
installed skill bytes. Run `update-skill-lock.ps1 -Check` before staging the agent-boundary bundle.
Stage the three behavior files with the existing same-volume atomic settlement. Uninstaller removes
only owned behavior contract files and generated records; it leaves skills, agents, and operational
`agent-tasks` data intact.

- [ ] **Step 5: Update affected exact-count/hash validators**

Replace hard-coded owned count 10 with 13 where it means component-owned files. Extend exact key/path
checks; do not weaken them to `>=`. Keep Topic 06/07 continuity policy and supported OMP versions
unchanged.

- [ ] **Step 6: Run installer and prior managed-runtime tests to GREEN**

Run:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Path 'scripts/tests/topic08-installer.Tests.ps1','scripts/tests/topic06-installer.Tests.ps1','scripts/tests/topic07-managed-runtime.Tests.ps1' -Output Detailed"
```

Expected: all tests pass, with no file created outside each temporary target.

---

### Task 6: Focused Validator, Source Sentinels, and Mutation Suite

**Files:**

- Create: `scripts/lib/topic08-behavior-core.ps1`
- Create: `scripts/validate-topic08-behavior-core.ps1`
- Create: `scripts/tests/topic08-validator-mutations.Tests.ps1`
- Modify: `scripts/validate-template.ps1`

**Interfaces:**

- `Test-Topic08BehaviorCore -RepositoryRoot 'D:\Dev\Projects\omp-template' -> validation rows`.
- `scripts/validate-topic08-behavior-core.ps1 -RepositoryRoot . [-Json]` exits 0 only with zero FAIL.
- Full validator invokes the focused validator once and preserves the known advisory-only token
  warnings.

- [ ] **Step 1: Write RED validator mutation tests**

Each test copies only the load-bearing file set to a temporary fixture, applies one mutation, and
requires one named Topic 08 failure. Mutations must cover manifest extra key, zero hash, missing
skill, user-shadow path, Worker autoload removed/extra, Reviewer autoload added, description/body
budget, fixture missing/duplicate, Claude installable, lifecycle allowlist adding `purge`, component
hash drift, installer dependency removal, source sentinel drift, and missing docs projection.

- [ ] **Step 2: Pin exact OMP source attachments**

Use these normalized LF-terminated ranges and SHA-256 values:

```text
skill-discovery|discovery/builtin.ts|281-305|6d2d6e57d647b9ce2a57efe190e037132463d5d191b4c0f6a5f2f618116e9a19
skill-render|system-prompt.ts|836-840|931beb5bd10be9ed21629b0f12693ba9c3faf2da32d3c5a4a088e3e141b3dfbc
discover-skills-sdk|sdk.ts|769-780|ab452ec11587f3ecb447a991722957f137940f5d4e1db8f5d30bfffd32f9cf39
autoload-resolve|task/structured-subagent.ts|365-370|5162dc0d31fa26435a9a54597c627d1b3050b54f2042593e901399dcc4ff80f6
autoload-inject|task/executor.ts|3233-3248|2f33f673faade6e8856bfa03cf8fcaf1b74de046e0c6362f7b8889842d2035d6
rules-forward|task/structured-subagent.ts|433-440|495547ae34a756840d3f0489160a416fbcf9da75c60159c86a7001752a4da4c9
skill-command|extensibility/skills.ts|399-449|64d07db9217a0bebc0de30a2710171077f059ed85590cfa9d10060f9b5260b22
tool-block-wrapper|extensibility/extensions/wrapper.ts|200-233|d4ccc00bc2154ad295277b178e89e62b2c4efe158838b3dcf7bade82db67c29c
tool-call-failclosed|extensibility/extensions/runner.ts|1072-1137|561b1d0e642262ee3438405ad117501ec1093cb2ef071853fbadd88067cdd05f
extension-api|extensibility/extensions/types.ts|1132-1153|da08b759af2230fec7609f9b6032a1173335112516bdd385093b58408ea3d9d5
extension-register-tool|extensibility/extensions/types.ts|1205-1233|977e390d6b53db72aa9dceaaec4d5d9f22561756f885bd0a48c3b3b097d55691
```

Require the clean pinned HEAD and ordered semantic needles as well as each range hash.

- [ ] **Step 3: Implement focused assertions**

Return stable rows for:

```text
T08-MANIFEST, T08-INJECTION-OWNERSHIP, T08-BUDGET, T08-ROSTER, T08-AUTOLOAD,
T08-TRIGGERS, T08-PROVENANCE, T08-LIFECYCLE, T08-MUTATION-GATE,
T08-OBSERVATION, T08-EXTERNAL-CAPABILITY,
T08-OMP-ADAPTER, T08-CLAUDE-FENCE, T08-COMPONENT, T08-INSTALLER,
T08-DOC-PROJECTION, T08-SOURCE-ATTACHED
```

The validator must call the JavaScript core for semantic manifest checks rather than reimplementing
the schema in PowerShell. PowerShell owns filesystem, YAML text, installer, source-hash, and
projection assertions.

- [ ] **Step 4: Run the focused validator and mutation suite to GREEN**

Run:

```powershell
pwsh -NoProfile -File scripts/validate-topic08-behavior-core.ps1 -RepositoryRoot .
pwsh -NoProfile -Command "Invoke-Pester -Path 'scripts/tests/topic08-validator-mutations.Tests.ps1' -Output Detailed"
```

Expected: focused validator exit 0; every mutation test passes by observing its expected failure.

- [ ] **Step 5: Integrate with the full validator without duplicating checks**

Add Topic 08 required files and one focused-validator invocation to `validate-template.ps1`. Preserve
the existing advisory status for the known lower-bound `AGENTS.md` token warning; do not pad the
prompt.

---

### Task 7: Active Specification, Documentation, and Provenance Projection

**Files:**

- Create: `docs/behavior-core.md`
- Modify only the exact active surfaces listed in the File Responsibility Map
- Create: `codex-topic08-portable-behavior-core-runtime-adapters-changelog.md`

**Interfaces:**

- Documentation names `behavior-manifest.json` as the selected authority and skill-lock as generated.
- Historical phase material is fenced/superseded, not rewritten as if it never existed.
- No document claims Claude runtime support or model-assisted trigger promotion.

- [ ] **Step 1: Add RED documentation assertions to the focused validator**

Require these exact current-product statements or equivalent stable markers:

```text
<!-- topic08-projection:behavior-core -->
selected roster: task-triage, systematic-debugging, evidence-before-completion
Worker-only autoload
missing autoload names fail before managed dispatch
agent_tasks is explicit and main-session only
Claude: DESIGNED_NOT_VERIFIED / installable false
trigger semantics remain unpromoted until Topic 11
agent-tasks operational state is retained on uninstall/rollback
```

Require the phase-02 fixed-role autoload subsection to carry a Topic 08 supersession fence rather
than remain active guidance.

- [ ] **Step 2: Write the concise behavior guide**

`docs/behavior-core.md` must contain:

```text
placement/injection-ownership table
three-skill roster and trigger/negative-trigger summary
Worker-only autoload and exact failure behavior
explicit agent_tasks lifecycle operation list
read-only diagnosis versus edit/write/bash gate
MCP/external tools provide capability only and never own policy/workflow selection
OMP adapter status and Claude fence
token budgets
exact add/update/deprecate/remove/check procedure and commands
local rollback snapshot and retained-state boundary
```

Link to the design, manifest, state protocol, and Topic 06/07 boundary docs rather than copying
their schemas.

- [ ] **Step 3: Correct active stale surfaces narrowly**

- In `spec/11`, replace the candidate/four-role assignment with the selected manifest and exact
  Worker-only autoload, while preserving research history under an explicit fence.
- In `spec/13` and phase 06, add deterministic Topic 08 checks and state that model trigger scoring
  is Topic 11 advisory/promotion work.
- In `spec/12`, installation docs, and rollback docs, add component ownership and retained-state
  behavior.
- In `spec/README.md`, correct DR-4 from lazy evidence delivery to Worker autoload.
- In DNA/token model, project the selected roster/budgets without turning three into a permanent cap.
- In phase 02, fence the old Implementer/Verifier/Reviewer autoload list as superseded history.
- In `workflow-v0` and `final-report`, remove null-hash/post-v0 claims and obsolete Verifier files.
- In the adoption ledger, remove `template/.omp/agents/verifier.md` from the active adoption target;
  keep the historical source record and point the selected consumer to Worker.
- In `verification-result.schema.yml`, replace the permanent-Verifier comment with selected
  verification producer wording.

- [ ] **Step 4: Write the local changelog**

Record approved decisions, exact files, verification commands, OMP source SHA, installed runtime
matrix, known Topic 07 17.2.10 executable blocker, local-only/no-Git policy, and Topic 11 promotion
boundary. Do not claim Topic 08 complete until Task 8 evidence exists.

- [ ] **Step 5: Run focused documentation validation**

Run the Topic 08 focused validator. Expected: all `T08-DOC-PROJECTION` assertions pass.

---

### Task 8: Evidence Capture and Final Verification

**Files:**

- Create: `scripts/capture-topic08-evidence.ps1`
- Generate: `docs/evidence/current-product/topic-08/deterministic.json`
- Generate: `docs/evidence/current-product/topic-08/manifest.json`
- Generate: `docs/evidence/current-product/topic-08/behavior-manifest.json`
- Finalize: `codex-topic08-portable-behavior-core-runtime-adapters-changelog.md`

**Interfaces:**

- `capture-topic08-evidence.ps1` writes only under the exact Topic 08 evidence directory after
  validating its resolved path is inside the repository.
- `deterministic.json` contains commands, exit codes, counts/status, OMP source SHA, runtime matrix,
  and no secrets/raw transcript.
- `manifest.json` hashes every Topic 08 evidence artifact and binds the behavior component version.
- `behavior-manifest.json` is an exact last-known-good snapshot of the installed-template manifest.

- [ ] **Step 1: Write the evidence capture script with fail-before-write behavior**

The script must run all required checks into memory/temp files first, reject any FAIL, then atomically
settle the three evidence files. If no compatible installed OMP exists, record the exact unavailable
row without a download. If 17.2.12 exists, run only the bounded no-network discovery/extension
canary; never invoke a paid model.

- [ ] **Step 2: Run all Topic 08 Node tests**

Run:

```powershell
node --test scripts/tests/topic08-behavior-core.Tests.mjs scripts/tests/topic08-skill-contracts.Tests.mjs scripts/tests/topic08-agent-tasks-tool.Tests.mjs scripts/tests/topic08-behavior-gates.Tests.mjs
```

Expected: exit 0 and zero failed tests.

- [ ] **Step 3: Run Topic 08 Pester and focused validator**

Run:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Path 'scripts/tests/topic08-installer.Tests.ps1','scripts/tests/topic08-validator-mutations.Tests.ps1' -Output Detailed"
pwsh -NoProfile -File scripts/validate-topic08-behavior-core.ps1 -RepositoryRoot .
pwsh -NoProfile -File scripts/update-skill-lock.ps1 -RepositoryRoot . -Check
```

Expected: zero failed Pester tests, focused validator exit 0, and lock check exit 0 without writes.

- [ ] **Step 4: Run affected prior-topic regressions once**

Run each existing wrapper once:

```powershell
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1 -RepositoryRoot .
pwsh -NoProfile -Command "Invoke-Pester -Path 'scripts/tests/topic03-topology-routing.Tests.ps1','scripts/tests/topic04-durable-state.Tests.ps1','scripts/tests/topic06-agent-boundary.Tests.ps1','scripts/tests/topic07-state-contract.Tests.ps1' -Output Detailed"
pwsh -NoProfile -File scripts/validate-topic06-agent-boundary.ps1 -RepositoryRoot .
pwsh -NoProfile -File scripts/validate-topic07-context-continuity.ps1 -RepositoryRoot .
```

Expected: every command exits 0; Topic 07 may retain only its already-known 17.2.10 executable
promotion blocker, not a new deterministic failure.

- [ ] **Step 5: Run exactly one full validator and diff hygiene pass**

Run:

```powershell
pwsh -NoProfile -File scripts/validate-template.ps1
git diff --check
```

Expected: full validator has zero failures; the known advisory `AGENTS.md` lower-bound warning may
remain. `git diff --check` exits 0 apart from any already-documented Phase 00 line-ending advisory.

- [ ] **Step 6: Capture final evidence and verify its hashes**

Run:

```powershell
pwsh -NoProfile -File scripts/capture-topic08-evidence.ps1 -RepositoryRoot .
pwsh -NoProfile -File scripts/validate-topic08-behavior-core.ps1 -RepositoryRoot .
```

Expected: evidence capture exit 0, then focused validation proves the evidence manifest and snapshot
match current bytes.

- [ ] **Step 7: Finalize status without overclaiming**

Set Topic 08 status to `IMPLEMENTED_NOT_PROMOTED`. State exact tested OMP runtime versions, preserve
`DESIGNED_NOT_VERIFIED` for Claude, preserve Topic 07's independent runtime blocker, and name Topic
11 as the owner of semantic trigger/pressure promotion. Do not stage or commit.

---

## Completion Boundary

The implementation is ready to hand off only when every Task 8 command has fresh exit/output
evidence, the last-known-good snapshot matches the selected manifest, no active skill hash is null,
Worker is the sole autoload consumer, mutation bootstrap is not deadlocked, and no new validator
failure exists. The result remains local and `IMPLEMENTED_NOT_PROMOTED`; Topic 11 performs semantic
evaluation and Topic 12 owns cross-runtime installation/promotion.
