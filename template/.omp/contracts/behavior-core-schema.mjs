export const BEHAVIOR_LIMITS = Object.freeze({
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
  "init-project",
  "status",
  "create-phase",
  "transition-phase",
  "create-task",
  "set-continuity-contract",
  "bind-worktree",
  "checkpoint",
  "claim",
  "create-work-unit",
  "freeze",
  "check",
  "promote-artifact",
  "record-evidence",
  "begin-handoff",
  "accept-handoff",
  "close",
  "invalidate",
]));

export const MUTATION_CAPABLE_TOOLS = Object.freeze(new Set(["edit", "write", "bash"]));

export const DIAGNOSTIC_TOOLS = Object.freeze(new Set([
  "read",
  "grep",
  "glob",
  "web_search",
  "ast_grep",
  "lsp",
]));
