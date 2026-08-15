export const CONTINUITY_LIMITS = Object.freeze({
  maxKernelBytes: 16_384,
  maxRecoveryArtifactBytes: 262_144,
  maxMetricBytes: 4_096,
  maxDepth: 12,
  maxArrayItems: 128,
  maxStringBytes: 4_096,
  maxLockedDecisions: 64,
  maxBranchEntries: 4_096,
  maxDegradedFields: 8,
  nonceTtlMs: 120_000,
});

export const CONTINUITY_WORKFLOW_CLASSES = Object.freeze(["quick", "standard", "orchestrated"]);
export const CONTINUITY_ACTIVE_STATUSES = Object.freeze(["active", "candidate_frozen", "rework"]);
export const CONTINUITY_DEGRADED_FIELDS = Object.freeze([
  "blockers",
  "candidate",
  "checkpoint",
  "evidence_bindings",
  "next_action",
  "open_risks",
  "work_unit_id",
]);

export const CONTINUITY_REASON_CODES = Object.freeze(new Set([
  "ok",
  "continuity_invalid",
  "continuity_too_large",
  "continuity_forbidden",
  "continuity_degraded",
  "pressure_invalid",
]));

export const CONTINUITY_PATTERNS = Object.freeze({
  taskId: /^T[0-9]{6}$/u,
  revisionId: /^R[0-9]{6}$/u,
  checkpointId: /^CP[0-9]{6}$/u,
  workUnitId: /^WU-[A-Z0-9][A-Z0-9._-]{0,79}$/u,
  candidateId: /^C[A-Z0-9][A-Z0-9._-]{0,79}$/u,
  evidenceId: /^E[0-9]{6}$/u,
  acceptanceId: /^AC-[A-Z0-9][A-Z0-9._-]{0,79}$/u,
  decisionId: /^D-[A-Z0-9][A-Z0-9._-]{0,63}$/u,
  epochId: /^E-[A-Z0-9][A-Z0-9._-]{0,79}$/u,
  sha256: /^[0-9a-f]{64}$/u,
  utcTimestamp: /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{3})?Z$/u,
});

export const MANAGED_COMPACTION_PROFILE = Object.freeze({
  "contextPromotion.enabled": false,
  "compaction.enabled": false,
  "compaction.strategy": "off",
  "compaction.midTurnEnabled": false,
  "compaction.thresholdPercent": -1,
  "compaction.thresholdTokens": -1,
  "compaction.keepRecentTokens": 20_000,
  "compaction.autoContinue": false,
  "compaction.idleEnabled": false,
  "compaction.remoteEnabled": false,
  "compaction.remoteStreamingV2Enabled": false,
  "compaction.supersedeReads": true,
  "compaction.dropUseless": true,
});

export const CONTINUITY_OBSERVATION_ENUMS = Object.freeze({
  artifactStatus: Object.freeze(["not_attempted", "saved", "failed"]),
  preparationStatus: Object.freeze(["not_attempted", "ready", "unavailable", "invalid"]),
  compactionStatus: Object.freeze(["not_started", "summarizing", "completed", "failed", "invalid"]),
  validationStatus: Object.freeze(["not_run", "passed", "failed"]),
  injectionStatus: Object.freeze(["not_pending", "awaiting", "injected", "consumed", "failed"]),
  providerAction: Object.freeze(["allowed", "aborted", "not_applicable"]),
});
