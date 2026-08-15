export const LIMITS = Object.freeze({
  maxInputBytes: 131072,
  maxPacketBytes: 12288,
  maxResultBytes: 32768,
  maxBatchItems: 8,
  maxDepth: 10,
  maxArrayItems: 128,
  maxStringBytes: 4096,
  forcedPartialRequests: 300,
});

export const MANAGED_ROLES = Object.freeze({
  "cheap-scout": Object.freeze({ role: "cheap_scout", effort: null, isolation: false }),
  worker: Object.freeze({ role: "worker", effort: Object.freeze(["high", "xhigh"]), isolation: true }),
  reviewer: Object.freeze({ role: "reviewer", effort: null, isolation: false }),
});

export const OUTPUT_CONTRACTS = Object.freeze({
  cheap_scout: "cheap_scout_v1",
  worker: "worker_v1",
  reviewer: "reviewer_v1",
});

export const REASON_CODES = Object.freeze(new Set([
  "ok",
  "managed_component_unavailable",
  "state_unavailable",
  "task_not_active",
  "work_unit_missing",
  "work_unit_incompatible",
  "packet_invalid",
  "packet_too_large",
  "forbidden_content",
  "plan_mode_incompatible",
  "unsupported_async",
  "unsupported_nested_spawn",
  "isolation_unavailable",
  "native_task_unavailable",
  "native_task_failed",
  "result_unsettled",
  "structured_output_invalid",
  "forced_partial",
  "context_pressure",
  "model_identity_mismatch",
  "effort_mismatch",
  "fallback_not_allowed",
  "artifact_stale",
  "candidate_drift",
  "outcome_record_failed",
  "cancelled",
  "internal_error",
]));

export const TASK_ID_PATTERN = /^T[0-9]{6}$/u;
export const WORK_UNIT_ID_PATTERN = /^WU-[A-Z0-9][A-Z0-9._-]{0,79}$/u;
export const ACCEPTANCE_ID_PATTERN = /^AC-[A-Z0-9][A-Z0-9._-]{0,79}$/u;
export const SHA256_PATTERN = /^[0-9a-f]{64}$/iu;

export const PROJECT_RELATIVE_PATH_PATTERN = "^(?!/)(?![A-Za-z]:)(?!.*(?:^|/)\\.\\.(?:/|$))[^\\\\\\r\\n]+$";
export const SOURCE_LOCATION_PATTERN = "^(?!/)(?![A-Za-z]:)(?!.*(?:^|/)\\.\\.(?:/|$))[^\\\\\\r\\n:]+(?::[1-9][0-9]*(?:-[1-9][0-9]*)?)$";

function deepFreeze(value) {
  if (value && typeof value === "object" && !Object.isFrozen(value)) {
    for (const child of Object.values(value)) deepFreeze(child);
    Object.freeze(value);
  }
  return value;
}

export const RUNTIME_IDENTITIES = deepFreeze({
  cheap_scout: {
    model_role: "cheap-scout",
    primary_model: "omniroute/ds/deepseek-v4-flash",
    fallback_model: "omniroute/ds/deepseek-v4-pro",
    effort: "xhigh",
  },
  worker: {
    model_role: "worker",
    primary_model: "omniroute/codex/gpt-5.6-sol",
    fallback_model: null,
    efforts: ["high", "xhigh"],
  },
  reviewer: {
    model_role: "reviewer",
    primary_model: "omniroute/codex/gpt-5.6-sol",
    fallback_model: null,
    effort: "xhigh",
  },
});

const boundedString = (maxLength = 1024) => ({ type: "string", maxLength });
const boundedStringArray = (maxItems, maxLength = 1024) => ({
  type: "array",
  maxItems,
  items: boundedString(maxLength),
});
const relativePath = () => ({ type: "string", maxLength: 1024, pattern: PROJECT_RELATIVE_PATH_PATTERN });
const relativePathArray = (maxItems) => ({
  type: "array",
  maxItems,
  uniqueItems: true,
  items: relativePath(),
});

export const ROLE_POLICIES = deepFreeze({
  cheap_scout: {
    constraints: [
      "Remain read-only and answer only the bounded retrieval question.",
      "Do not verify acceptance, review a candidate, mutate files, or choose a model route.",
    ],
    quality_gates: [
      "Cite current project-relative source locations for every material claim.",
      "Disclose gaps and any native/CodeGraph fallback path.",
    ],
    overlay: {
      source_fitness_guidance: "Prefer direct current source; use CodeGraph only when relationship discovery materially benefits.",
      allowed_capabilities: ["native", "codegraph"],
      evidence_requirements: [
        "Corroborate critical and absence claims against current native source.",
        "Report uncertainty instead of inventing completeness.",
      ],
      retrieval_contract: {
        search_before_broad_read: true,
        retry_empty_search_with_distinct_strategy: true,
        disclose_fallback: true,
        graph_only_absence_forbidden: true,
      },
      stop_condition: "Stop when the bounded question is cited, or return partial/blocked with the exact unresolved boundary.",
    },
  },
  worker: {
    constraints: [
      "Modify only the exact owned path set and preserve unrelated user changes.",
      "Do not spawn, integrate, independently review, or claim parent-task acceptance.",
    ],
    quality_gates: [
      "Run every required verification command and report its fresh observation.",
      "Return partial, blocked, or failed when mandatory evidence is absent.",
    ],
  },
  reviewer: {
    constraints: [
      "Review the frozen candidate independently and remain read-only.",
      "Use only frozen-candidate evidence; do not inherit another agent's narrative.",
    ],
    quality_gates: [
      "Trace each finding to a concrete trigger, impact, violated contract, and tight location.",
      "Any critical or important finding requires changes and blocking rework.",
    ],
    severity_boundary: "critical_or_important_blocks_acceptance",
    stop_condition: "Stop after the selected concerns are either evidenced as findings or explicitly cleared against the frozen candidate.",
  },
});

const semanticSchemas = {
  cheap_scout: {
    type: "object",
    additionalProperties: false,
    required: [
      "status",
      "summary",
      "capability",
      "source_fitness_reason",
      "fallback_path",
      "claims",
      "gaps",
      "searches_performed",
      "recommended_next_action",
    ],
    properties: {
      status: { enum: ["completed", "partial", "blocked", "failed"] },
      summary: boundedString(1200),
      capability: { enum: ["native", "codegraph", "mixed"] },
      source_fitness_reason: boundedString(1024),
      fallback_path: boundedStringArray(8),
      claims: {
        type: "array",
        maxItems: 32,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["claim", "sources"],
          properties: {
            claim: boundedString(600),
            sources: {
              type: "array",
              minItems: 1,
              maxItems: 8,
              items: {
                type: "object",
                additionalProperties: false,
                required: ["path", "line_start", "line_end"],
                properties: {
                  path: relativePath(),
                  line_start: { type: "integer", minimum: 1 },
                  line_end: { type: "integer", minimum: 1 },
                },
              },
            },
          },
        },
      },
      gaps: boundedStringArray(16, 400),
      searches_performed: {
        type: "array",
        maxItems: 32,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["method", "query", "outcome"],
          properties: {
            method: { enum: ["read", "grep", "glob", "web_search", "codegraph"] },
            query: boundedString(1024),
            outcome: boundedString(1024),
          },
        },
      },
      recommended_next_action: boundedString(1024),
    },
    allOf: [{
      if: { properties: { status: { const: "completed" } }, required: ["status"] },
      then: { properties: { claims: { minItems: 1 } } },
    }],
  },
  worker: {
    type: "object",
    additionalProperties: false,
    required: [
      "status",
      "summary",
      "artifact_refs",
      "verification_observations",
      "covered_ac_ids",
      "blockers",
      "remaining_risks",
    ],
    properties: {
      status: { enum: ["completed", "partial", "blocked", "failed"] },
      summary: boundedString(1200),
      artifact_refs: relativePathArray(64),
      verification_observations: {
        type: "array",
        maxItems: 32,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["command_id", "status", "observation"],
          properties: {
            command_id: boundedString(1024),
            status: { enum: ["passed", "failed", "not_run"] },
            observation: boundedString(1024),
          },
        },
      },
      covered_ac_ids: {
        type: "array",
        maxItems: 64,
        uniqueItems: true,
        items: { type: "string", pattern: "^AC-[A-Z0-9][A-Z0-9._-]{0,79}$" },
      },
      blockers: boundedStringArray(16),
      remaining_risks: boundedStringArray(16),
    },
    allOf: [
      {
        if: { properties: { status: { const: "completed" } }, required: ["status"] },
        then: {
          properties: {
            blockers: { maxItems: 0 },
            verification_observations: {
              items: {
                type: "object",
                properties: { status: { const: "passed" } },
                required: ["status"],
              },
            },
          },
        },
      },
      {
        if: { properties: { status: { const: "blocked" } }, required: ["status"] },
        then: { properties: { blockers: { minItems: 1 } } },
      },
    ],
  },
  reviewer: {
    type: "object",
    additionalProperties: false,
    required: ["decision", "summary", "findings", "cleared_concerns", "recommended_action"],
    properties: {
      decision: { enum: ["APPROVED", "APPROVED_WITH_NOTES", "CHANGES_REQUESTED"] },
      summary: boundedString(1200),
      findings: {
        type: "array",
        maxItems: 32,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["severity", "title", "location", "trigger", "impact", "violated_contract", "evidence"],
          properties: {
            severity: { enum: ["critical", "important", "minor"] },
            title: boundedString(1024),
            location: { type: "string", maxLength: 1024, pattern: SOURCE_LOCATION_PATTERN },
            trigger: boundedString(1024),
            impact: boundedString(1024),
            violated_contract: boundedString(1024),
            evidence: boundedString(1024),
          },
        },
      },
      cleared_concerns: {
        type: "array",
        maxItems: 32,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["concern", "evidence"],
          properties: {
            concern: boundedString(1024),
            evidence: boundedString(1024),
          },
        },
      },
      recommended_action: { enum: ["ACCEPT", "REWORK_BLOCKING", "ACCEPT_WITH_FOLLOWUP"] },
    },
    allOf: [
      {
        if: { properties: { decision: { const: "APPROVED" } }, required: ["decision"] },
        then: {
          properties: {
            findings: { maxItems: 0 },
            recommended_action: { const: "ACCEPT" },
          },
        },
      },
      {
        if: { properties: { decision: { const: "APPROVED_WITH_NOTES" } }, required: ["decision"] },
        then: {
          properties: {
            findings: { items: { properties: { severity: { const: "minor" } }, required: ["severity"] } },
            recommended_action: { const: "ACCEPT_WITH_FOLLOWUP" },
          },
        },
      },
      {
        if: { properties: { decision: { const: "CHANGES_REQUESTED" } }, required: ["decision"] },
        then: {
          properties: {
            findings: {
              minItems: 1,
              contains: { properties: { severity: { enum: ["critical", "important"] } }, required: ["severity"] },
            },
            recommended_action: { const: "REWORK_BLOCKING" },
          },
        },
      },
    ],
  },
};

export const SEMANTIC_OUTPUT_SCHEMAS = deepFreeze(semanticSchemas);
