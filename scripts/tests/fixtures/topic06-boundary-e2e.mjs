import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

function fail(message) {
  process.stdout.write(`${JSON.stringify({ ok: false, error: String(message).slice(0, 240) })}\n`);
  process.exitCode = 1;
}

function fakeTypebox() {
  const Type = {
    String: (options = {}) => ({ type: "string", ...options }),
    Boolean: () => ({ type: "boolean" }),
    Literal: (value) => ({ const: value }),
    Optional: (value) => ({ ...value, optional: true }),
    Object: (properties, options = {}) => ({ type: "object", properties, ...options }),
    Array: (items, options = {}) => ({ type: "array", items, ...options }),
    Union: (anyOf) => ({ anyOf }),
  };
  return { Type };
}

function selectedCatalog(schemas) {
  return {
    projectAgentsDir: null,
    agents: [
      {
        name: "cheap-scout",
        source: "project",
        model: ["@cheap-scout"],
        thinkingLevel: "xhigh",
        blocking: true,
        spawns: [],
        tools: ["read", "grep", "glob", "web_search", "yield"],
        output: schemas.cheap_scout,
      },
      {
        name: "worker",
        source: "project",
        model: ["@worker"],
        thinkingLevel: "high",
        blocking: true,
        spawns: [],
        tools: ["read", "grep", "glob", "edit", "write", "bash", "yield"],
        output: schemas.worker,
      },
      {
        name: "reviewer",
        source: "project",
        model: ["@reviewer"],
        thinkingLevel: "xhigh",
        blocking: true,
        spawns: [],
        tools: ["read", "grep", "glob", "bash", "yield"],
        output: schemas.reviewer,
      },
    ],
  };
}

function routeFor(request) {
  if (request.role === "cheap_scout") {
    return {
      modelRole: "cheap-scout",
      resolvedModel: "omniroute/ds/deepseek-v4-flash:xhigh",
      resolvedModelIsFallback: false,
    };
  }
  if (request.role === "reviewer") {
    return {
      modelRole: "reviewer",
      resolvedModel: "omniroute/codex/gpt-5.6-sol:xhigh",
      resolvedModelIsFallback: false,
    };
  }
  return {
    modelRole: "worker",
    resolvedModel: `omniroute/codex/gpt-5.6-sol:${request.effort ?? "high"}`,
    resolvedModelIsFallback: false,
  };
}

try {
  const inputPath = process.argv[2];
  if (!inputPath || !path.isAbsolute(inputPath) || !fs.statSync(inputPath).isFile()) {
    throw new Error("input_invalid");
  }
  const rawInput = fs.readFileSync(inputPath, "utf8");
  const bootstrap = JSON.parse(rawInput);
  if (!bootstrap || bootstrap.schema_version !== 1 || typeof bootstrap.wrapper_path !== "string" ||
      typeof bootstrap.project_directory !== "string" || typeof bootstrap.session_ref !== "string") {
    throw new Error("input_invalid");
  }

  const wrapperUrl = pathToFileURL(path.resolve(bootstrap.wrapper_path));
  const targetOmp = path.resolve(path.dirname(bootstrap.wrapper_path), "..");
  const schemaUrl = pathToFileURL(path.join(targetOmp, "contracts", "agent-boundary-schema.mjs"));
  const coreUrl = pathToFileURL(path.join(targetOmp, "contracts", "agent-boundary-core.mjs"));
  const [wrapper, schema, core] = await Promise.all([
    import(wrapperUrl.href),
    import(schemaUrl.href),
    import(coreUrl.href),
  ]);
  const input = core.parseJsonNoDuplicateKeys(rawInput);
  const runtime = await wrapper.loadManagedRuntime(wrapperUrl.href);
  const rawRequests = Array.isArray(input.request?.tasks) ? input.request.tasks : [input.request];
  if (rawRequests.length === 0 || !input.semantics || typeof input.semantics !== "object") {
    throw new Error("input_invalid");
  }

  const artifactRoot = path.join(targetOmp, "agent-tasks-test");
  fs.mkdirSync(artifactRoot, { recursive: true });
  const nativeCalls = [];
  const context = {
    cwd: path.resolve(input.project_directory),
    sessionManager: {
      getBranch: () => [],
      getSessionId: () => input.session_ref,
    },
    invokeTool: async (params) => {
      const nativeItems = Array.isArray(params.tasks) ? params.tasks : [params];
      nativeCalls.push(structuredClone(params));
      const results = nativeItems.map((item, index) => {
        const request = rawRequests[index];
        if (!request || item.agent !== request.agent) throw new Error("native_request_mismatch");
        const semantic = input.semantics[request.work_unit_id];
        if (!semantic) throw new Error("semantic_missing");
        const outputPath = path.join(artifactRoot, `Agent-${index + 1}.md`);
        fs.writeFileSync(outputPath, `managed fixture artifact ${index + 1}\n`, "utf8");
        const isolation = request.isolated === true ? {
          patchPath: path.join(artifactRoot, `Agent-${index + 1}.patch`),
        } : {};
        if (isolation.patchPath) fs.writeFileSync(isolation.patchPath, "fixture patch\n", "utf8");
        return {
          index,
          id: `Agent-${index + 1}`,
          agent: request.agent,
          agentSource: "project",
          task: item.task,
          exitCode: 0,
          output: "native prose must stay private",
          stderr: "",
          truncated: false,
          structuredOutput: { source: "agent", mode: "permissive", status: "valid", data: semantic },
          durationMs: 1,
          tokens: 1,
          requests: 1,
          outputPath,
          ...isolation,
          ...routeFor(request),
        };
      });
      return {
        content: [{ type: "text", text: "native prose must stay private" }],
        details: { projectAgentsDir: artifactRoot, results, totalDurationMs: 1 },
        isError: false,
      };
    },
  };
  const pi = { typebox: fakeTypebox(), cwd: context.cwd };
  const tool = wrapper.createManagedTaskTool(
    pi,
    runtime,
    selectedCatalog(schema.SEMANTIC_OUTPUT_SCHEMAS),
  );
  const result = await tool.execute("topic06-e2e", input.request, undefined, undefined, context);
  const dispatched = nativeCalls.flatMap((call) => Array.isArray(call.tasks) ? call.tasks : [call]);
  process.stdout.write(`${core.canonicalJson({
    ok: true,
    result,
    native_call_count: nativeCalls.length,
    dispatched: dispatched.map((item) => ({
      agent: item.agent,
      task: item.task,
      packet_sha256: core.sha256Canonical(core.parseJsonNoDuplicateKeys(item.task)),
      isolated: item.isolated === true,
      effort: item.effort ?? null,
    })),
  })}\n`);
} catch (error) {
  fail(error?.message ?? error);
}
