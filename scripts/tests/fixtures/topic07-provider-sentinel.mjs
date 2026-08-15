import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const PROVIDER = "topic07-sentinel";
const MODEL = "pressure-model";
const API = "topic07-sentinel-api";

function readCount() {
  const counterPath = process.env.OMP_TOPIC07_SENTINEL_COUNTER;
  if (!counterPath || !fs.existsSync(counterPath)) return 0;
  const value = Number.parseInt(fs.readFileSync(counterPath, "utf8").trim(), 10);
  return Number.isSafeInteger(value) && value >= 0 ? value : 0;
}

function incrementCount() {
  const counterPath = process.env.OMP_TOPIC07_SENTINEL_COUNTER;
  if (!counterPath || !path.isAbsolute(counterPath)) throw new Error("sentinel_counter_unavailable");
  const next = readCount() + 1;
  const temporary = `${counterPath}.tmp-${process.pid}-${Date.now()}`;
  fs.writeFileSync(temporary, `${next}\n`, { encoding: "utf8", flag: "wx" });
  fs.renameSync(temporary, counterPath);
  return next;
}

function assistantMessage(stopReason, text) {
  return {
    role: "assistant",
    content: text ? [{ type: "text", text }] : [],
    api: API,
    provider: PROVIDER,
    model: MODEL,
    usage: {
      input: 0,
      output: 0,
      cacheRead: 0,
      cacheWrite: 0,
      totalTokens: 0,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
    },
    stopReason,
    timestamp: Date.now(),
  };
}

function localStream(options, afterGate) {
  let settle;
  const resultPromise = new Promise((resolve) => { settle = resolve; });
  const iterator = (async function* sentinelEvents() {
    await options?.onPayload?.({ fixture: "topic07-provider-sentinel", model: MODEL });
    if (options?.signal?.aborted) {
      afterGate(true);
      const aborted = assistantMessage("aborted", "");
      settle(aborted);
      yield { type: "error", reason: "aborted", error: aborted };
      return;
    }
    incrementCount();
    afterGate(false);
    const completed = assistantMessage("stop", "TOPIC07_SENTINEL_DISPATCHED");
    settle(completed);
    yield { type: "done", reason: "stop", message: completed };
  })();
  return Object.assign(iterator, { result: () => resultPromise });
}

function createOwnedTask(ctx) {
  if (process.env.OMP_TOPIC07_CREATE_TASK !== "1") return { skipped: true, error: null };
  const runtimePath = process.env.OMP_TOPIC07_RUNTIME_JSON;
  const requestRoot = process.env.OMP_TOPIC07_REQUEST_ROOT;
  if (!runtimePath || !path.isAbsolute(runtimePath) || !requestRoot || !path.isAbsolute(requestRoot)) {
    throw new Error("task_bootstrap_environment_invalid");
  }
  const runtime = JSON.parse(fs.readFileSync(runtimePath, "utf8"));
  const sessionId = ctx?.sessionManager?.getSessionId?.();
  if (typeof sessionId !== "string" || sessionId.length === 0) throw new Error("session_identity_unavailable");
  const envelope = {
    schema_version: 1,
    operation: "create-task",
    working_directory: ctx.cwd,
    session_ref: sessionId,
    runtime: "omp",
    request: {
      objective: "Exercise the Topic 07 provider pressure boundary without external model work.",
      authority: ["topic07-runtime-canary"],
      acceptance_criteria: [{ id: "AC-001", text: "Provider dispatch obeys the managed pressure boundary.", mandatory: true }],
      obligations: ["Keep automatic compaction and continuation disabled."],
      execution_mode: "read_only",
      write_scope: [],
      owned_ignored_outputs: [],
      workflow_class: "standard",
      locked_decisions: [{
        decision_id: "D-001",
        statement: "Use the approved explicit managed continuity path.",
        authority_ref: "topic07-runtime-canary",
      }],
    },
  };
  fs.mkdirSync(requestRoot, { recursive: true });
  const requestPath = path.join(requestRoot, `task-${process.pid}-${Date.now()}.json`);
  fs.writeFileSync(requestPath, `${JSON.stringify(envelope)}\n`, { encoding: "utf8", flag: "wx" });
  try {
    const result = spawnSync(runtime.paths.pwsh, [
      "-NoProfile", "-NonInteractive", "-File", runtime.paths.state_cli,
      "-RequestPath", requestPath,
    ], {
      cwd: ctx.cwd,
      encoding: "utf8",
      windowsHide: true,
      maxBuffer: 256 * 1024,
    });
    const stdout = String(result.stdout ?? "").trim();
    const response = stdout ? JSON.parse(stdout) : null;
    if (result.status !== 0 || response?.ok !== true || response?.operation !== "create-task") {
      throw new Error(`task_bootstrap_failed:${response?.code ?? result.status ?? "unknown"}`);
    }
    return { skipped: false, task_id: response.data.task_id, session_id: sessionId, error: null };
  } finally {
    fs.rmSync(requestPath, { force: true });
  }
}

function summarizeBranch(ctx) {
  const branch = ctx?.sessionManager?.getBranch?.() ?? [];
  const custom = branch.filter((entry) => entry?.type === "custom");
  const observations = custom.filter((entry) => entry.customType === "topic07:observation");
  const forbidden = branch.filter((entry) => {
    const identity = `${entry?.type ?? ""}:${entry?.customType ?? ""}`.toLowerCase();
    return ["compaction", "shake", "handoff", "auto_retry", "continuation"].some((token) => identity.includes(token));
  });
  return {
    branch_entries: branch.length,
    observation_count: observations.length,
    pressure_observation_count: observations.filter((entry) =>
      entry?.data?.provider_action === "aborted" && String(entry?.data?.reason_code ?? "").endsWith(":context_pressure")).length,
    forbidden_entry_count: forbidden.length,
    entry_types: [...new Set(branch.map((entry) => String(entry?.type ?? "unknown")))].sort(),
    custom_types: [...new Set(custom.map((entry) => String(entry?.customType ?? "unknown")))].sort(),
  };
}

export default function topic07ProviderSentinel(api) {
  let bootstrap = { skipped: true, error: null };
  let reported = false;
  let reportRequested = false;
  let activeContext = null;

  const reportOnce = (ctx = activeContext) => {
    if (!reportRequested || reported || !ctx) return;
    reported = true;
    const result = {
      schema_version: 1,
      bootstrap,
      sentinel_count: readCount(),
      session_id: ctx?.sessionManager?.getSessionId?.() ?? null,
      session_file: ctx?.sessionManager?.getSessionFile?.() ?? null,
      ...summarizeBranch(ctx),
    };
    process.stdout.write(`TOPIC07_SENTINEL_RESULT=${JSON.stringify(result)}\n`);
    setTimeout(() => process.exit(process.exitCode ?? 0), 100);
  };

  const afterProviderGate = (aborted) => {
    if (aborted) reportRequested = true;
    reportOnce();
  };

  api.registerProvider(PROVIDER, {
    baseUrl: "http://127.0.0.1:9/topic07-no-network",
    apiKey: "topic07-local-fixture-not-a-secret",
    api: API,
    streamSimple: (_model, _context, options) => localStream(options, afterProviderGate),
    models: [{
      id: MODEL,
      name: "Topic 07 Pressure Sentinel",
      reasoning: false,
      input: ["text"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: 32768,
      maxTokens: 256,
    }],
  });

  api.on("session_start", (_event, ctx) => {
    activeContext = ctx;
    try {
      bootstrap = createOwnedTask(ctx);
    } catch (error) {
      bootstrap = { skipped: false, error: String(error?.message ?? error).slice(0, 200) };
      process.exitCode = 1;
      process.stdout.write(`TOPIC07_SENTINEL_BOOTSTRAP=${JSON.stringify(bootstrap)}\n`);
      ctx.shutdown();
    }
  });

  api.on("turn_end", (_event, ctx) => {
    reportRequested = true;
    reportOnce(ctx);
  });

  api.on("agent_end", (_event, ctx) => {
    reportRequested = true;
    reportOnce(ctx);
    ctx.shutdown();
  });
}
