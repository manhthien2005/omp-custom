import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";

import {
  ADAPTER_STATUSES,
  BEHAVIOR_LIMITS,
  LIFECYCLE_OPERATIONS,
} from "../../template/.omp/contracts/behavior-core-schema.mjs";
import {
  decideToolBoundary,
  estimateApproxTokens,
  reconcileBehaviorCatalog,
  validateBehaviorManifest,
} from "../../template/.omp/contracts/behavior-core.mjs";

const HASH_A = "a".repeat(64);
const HASH_B = "b".repeat(64);
const HASH_C = "c".repeat(64);
const HASH_D = "d".repeat(64);

function skill({
  name,
  hash,
  loading = "lazy",
  consumers = ["tech-lead"],
  autoloadRoles = [],
  behaviorId = `skill.${name}`,
}) {
  return {
    name,
    path: `.omp/skills/${name}/SKILL.md`,
    sha256: hash,
    visibility: "visible",
    loading,
    intended_consumers: consumers,
    autoload_roles: autoloadRoles,
    positive_trigger_fixture: `evals/triggers/topic08/${name}-positive.yml`,
    negative_trigger_fixture: `evals/triggers/topic08/${name}-negative.yml`,
    description_max_tokens: 80,
    body_max_tokens: loading === "autoload" ? 500 : 900,
    provenance_id: `prov-${name}`,
    license_id: "project-native",
    status: "active",
    replacement: null,
    behavior_ids: [behaviorId],
  };
}

function provenance(name) {
  return {
    id: `prov-${name}`,
    license_id: "project-native",
    kind: "project-owned",
    source: "omp-template",
    commit: null,
  };
}

function validManifest() {
  return {
    schema_version: 1,
    record_type: "portable_behavior_manifest",
    component: "behavior-core",
    component_version: "1.0.0",
    reviewed_on: "2026-08-14",
    constitution: {
      path: ".omp/RULES.md",
      behavior_ids: ["evidence-before-completion", "constitution.user-authority"],
      intentional_duplications: ["evidence-before-completion"],
    },
    budgets: {
      rules_target_max_tokens: 700,
      rules_hard_warning_tokens: 800,
      skill_description_max_tokens: 80,
      visible_catalog_max_tokens: 900,
      visible_skill_soft_cap: 10,
      visible_skill_hard_cap: 12,
      worker_autoload_body_max_tokens: 500,
      lazy_skill_body_max_tokens: 900,
    },
    skills: [
      skill({ name: "task-triage", hash: HASH_A }),
      skill({ name: "systematic-debugging", hash: HASH_B }),
      skill({
        name: "evidence-before-completion",
        hash: HASH_C,
        loading: "autoload",
        consumers: ["worker"],
        autoloadRoles: ["worker"],
        behaviorId: "evidence-before-completion",
      }),
    ],
    roles: {
      "cheap-scout": {
        agent_path: ".omp/agents/cheap-scout.md",
        required_autoload: [],
        forbidden_responsibilities: ["write", "accept"],
        behavior_ids: ["role.cheap-scout.identity"],
      },
      worker: {
        agent_path: ".omp/agents/worker.md",
        required_autoload: ["evidence-before-completion"],
        forbidden_responsibilities: ["accept"],
        behavior_ids: ["role.worker.identity"],
      },
      reviewer: {
        agent_path: ".omp/agents/reviewer.md",
        required_autoload: [],
        forbidden_responsibilities: ["write", "accept"],
        behavior_ids: ["role.reviewer.identity"],
      },
    },
    commands: {
      quick: {
        path: ".omp/commands/quick.md",
        behavior_ids: ["command.quick.sequence"],
      },
      standard: {
        path: ".omp/commands/standard.md",
        behavior_ids: ["command.standard.sequence"],
      },
      orchestrated: {
        path: ".omp/commands/orchestrated.md",
        behavior_ids: ["command.orchestrated.sequence"],
      },
    },
    hooks: [
      {
        name: "agent-task-boundary",
        extension: ".omp/extensions/agent-task-boundary.js",
        boundary: "tool_call",
        predicate: "managed task and behavior preflight",
        failure_policy: "fail_closed",
        error_prefix: "BHV-",
        observation_policy: "warn_only",
        behavior_ids: ["hook.agent-task-boundary"],
      },
      {
        name: "context-continuity",
        extension: ".omp/extensions/context-continuity.js",
        boundary: "session",
        predicate: "managed context continuity",
        failure_policy: "fail_closed",
        error_prefix: "T07_",
        observation_policy: "warn_only",
        behavior_ids: ["hook.context-continuity"],
      },
    ],
    tools: {
      external_capabilities: {
        policy_authority: false,
        workflow_selection: false,
      },
    },
    adapters: {
      omp: {
        status: "SELECTED_FOR_IMPLEMENTATION",
        installable: false,
        mappings: {
          constitution: ".omp/RULES.md",
          agents: ".omp/agents",
          commands: ".omp/commands",
          skills: ".omp/skills",
          hooks: ".omp/extensions",
        },
      },
      claude: {
        status: "DESIGNED_NOT_VERIFIED",
        installable: false,
        mappings: {
          constitution: "CLAUDE.md",
          agents: ".claude/agents",
          commands: ".claude/commands",
          skills: ".claude/skills",
          hooks: ".claude/settings.json",
        },
      },
    },
    provenance: [
      provenance("task-triage"),
      provenance("systematic-debugging"),
      provenance("evidence-before-completion"),
    ],
  };
}

test("exports the approved limits, statuses, and routine lifecycle operations", () => {
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
  assert.deepEqual([...ADAPTER_STATUSES], [
    "SELECTED_FOR_IMPLEMENTATION",
    "IMPLEMENTED_NOT_PROMOTED",
    "DESIGNED_NOT_VERIFIED",
  ]);
  assert.equal(LIFECYCLE_OPERATIONS.has("create-task"), true);
  assert.equal(LIFECYCLE_OPERATIONS.has("purge"), false);
  assert.equal(estimateApproxTokens("12345"), 2);
});

test("accepts the approved closed manifest", () => {
  const result = validateBehaviorManifest(validManifest());
  assert.equal(result.ok, true, result.message);
});

test("rejects unknown keys and an installable Claude adapter", () => {
  const extra = validManifest();
  extra.unreviewed = true;
  assert.equal(validateBehaviorManifest(extra).reason_code, "BHV-MANIFEST-INVALID");

  const unsafeClaude = validManifest();
  unsafeClaude.adapters.claude.installable = true;
  assert.equal(validateBehaviorManifest(unsafeClaude).reason_code, "BHV-ADAPTER-UNSUPPORTED");
});

test("selects skills through data rather than a hard-coded count", () => {
  const expanded = validManifest();
  expanded.skills.push(skill({ name: "fourth-skill", hash: HASH_D }));
  expanded.provenance.push(provenance("fourth-skill"));
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

test("reconciles effective skills and exact role autoload bindings", () => {
  const manifest = validManifest();
  const ompRoot = path.resolve("template/.omp");
  const result = reconcileBehaviorCatalog({
    manifest,
    ompRoot,
    skills: manifest.skills.map((row) => ({
      name: row.name,
      filePath: path.join(ompRoot, row.path.slice(".omp/".length)),
      hide: false,
    })),
    agents: Object.fromEntries(Object.entries(manifest.roles).map(([name, row]) => [name, {
      autoloadSkills: [...row.required_autoload],
    }])),
    fileHashes: Object.fromEntries(manifest.skills.map((row) => [row.path, row.sha256])),
  });
  assert.equal(result.ok, true, result.message);

  const shadowed = structuredClone(result.value);
  shadowed.skills[0].filePath = path.resolve("user/.omp/skills/task-triage/SKILL.md");
  assert.equal(reconcileBehaviorCatalog(shadowed).reason_code, "BHV-SKILL-SHADOWED");
});

test("keeps diagnosis available while mutation fails closed without one state binding", () => {
  assert.deepEqual(decideToolBoundary({
    toolName: "read",
    sessionKind: "main",
    stateKind: "missing",
  }), { allow: true });

  assert.equal(decideToolBoundary({
    toolName: "write",
    sessionKind: "main",
    stateKind: "missing",
  }).reason_code, "BHV-STATE-MISSING");

  assert.deepEqual(decideToolBoundary({
    toolName: "bash",
    sessionKind: "main",
    stateKind: "one",
  }), { allow: true });
});
