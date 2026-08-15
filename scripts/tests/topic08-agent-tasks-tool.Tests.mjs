import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";

import { createAgentTasksTool } from "../../template/.omp/extensions/agent-task-boundary.js";

function fakePi() {
  const Type = {
    String: (options = {}) => ({ type: "string", ...options }),
    Literal: (value) => ({ const: value }),
    Object: (properties, options = {}) => ({ type: "object", properties, ...options }),
    Union: (items) => ({ anyOf: items }),
    Record: (key, value) => ({ type: "object", key, value }),
    Unknown: () => ({}),
  };
  return { typebox: { Type } };
}

function runtime() {
  const targetOmp = path.resolve("template/.omp");
  return {
    schema_version: 2,
    record_type: "agent_boundary_runtime",
    target_omp: targetOmp,
    paths: {
      pwsh: path.resolve("fake/pwsh.exe"),
      state_cli: path.join(targetOmp, "state/agent-tasks.ps1"),
    },
    capabilities: {
      batch: true,
      isolation: true,
      effort: true,
      max_effort: "xhigh",
      continuity: true,
    },
  };
}

function acceptedTaskContract() {
  return {
    objective: "Implement the accepted Topic 08 contract.",
    authority: ["user"],
    acceptance_criteria: [
      { id: "AC-001", text: "The behavior gate is deterministic.", mandatory: true },
    ],
    obligations: ["verification"],
    execution_mode: "mutating",
    write_scope: [{ kind: "subtree", path: "template/.omp" }],
    owned_ignored_outputs: [],
    workflow_class: "standard",
    locked_decisions: [],
  };
}

function mainContext(overrides = {}) {
  const sessionManager = {
    getSessionId: () => "codex:topic08-main",
    getBranch: () => [],
    ...(overrides.sessionManager ?? {}),
  };
  return {
    cwd: path.resolve("."),
    sessionManager,
    ...overrides,
    sessionManager,
  };
}

function successEnvelope(operation, data = { task_id: "T000001" }) {
  return { ok: true, code: "AT-OK", operation, data };
}

test("agent_tasks creates state only from the main session and trusted adapter fields", async () => {
  const calls = [];
  const tool = createAgentTasksTool(fakePi(), runtime(), {
    invokeState: async (operation, request, ctx) => {
      calls.push({ operation, request, cwd: ctx.cwd, session: ctx.sessionManager.getSessionId() });
      return successEnvelope(operation);
    },
  });
  const request = acceptedTaskContract();
  const result = await tool.execute("call-1", {
    operation: "create-task",
    request,
  }, undefined, undefined, mainContext());

  assert.equal(tool.name, "agent_tasks");
  assert.equal(tool.strict, true);
  assert.equal(result.isError, false);
  assert.deepEqual(Object.keys(result.details), [
    "schema_version", "record_type", "operation", "ok", "code", "data",
  ]);
  assert.equal(result.details.record_type, "agent_tasks_tool_details");
  assert.deepEqual(calls.map((call) => call.operation), ["create-task"]);
  assert.deepEqual(calls[0].request, request);
  assert.equal(Object.hasOwn(calls[0].request, "session_ref"), false);
  assert.equal(Object.hasOwn(calls[0].request, "working_directory"), false);
  assert.equal(calls[0].cwd, path.resolve("."));
  assert.equal(calls[0].session, "codex:topic08-main");
});

test("agent_tasks refuses authority-sensitive and unknown operations before state invocation", async () => {
  let calls = 0;
  const tool = createAgentTasksTool(fakePi(), runtime(), {
    invokeState: async () => {
      calls += 1;
      return successEnvelope("status");
    },
  });
  for (const operation of ["purge", "takeover", "cleanup", "restore", "recover-lock", "migrate", "invented"]) {
    const result = await tool.execute("call-2", { operation, request: {} }, undefined, undefined, mainContext());
    assert.equal(result.isError, true);
    assert.equal(result.details.code, "BHV-LIFECYCLE-FORBIDDEN");
  }
  assert.equal(calls, 0);
});

test("agent_tasks refuses bounded-child and invalid main-session identities", async () => {
  const tool = createAgentTasksTool(fakePi(), runtime(), {
    invokeState: async (operation) => successEnvelope(operation),
  });
  const child = mainContext({
    sessionManager: {
      getSessionId: () => "codex:topic08-child",
      getBranch: () => [{ type: "session_init", task: "bounded packet" }],
    },
  });
  const malformed = mainContext({
    sessionManager: {
      getSessionId: () => " ",
      getBranch: () => [],
    },
  });
  const ambiguous = mainContext({
    sessionManager: {
      getSessionId: () => "codex:topic08-main",
      getBranch: () => [
        { type: "session_init", task: "one" },
        { type: "session_init", task: "two" },
      ],
    },
  });
  for (const ctx of [child, malformed, ambiguous]) {
    const result = await tool.execute("call-3", { operation: "status", request: {} }, undefined, undefined, ctx);
    assert.equal(result.isError, true);
    assert.equal(result.details.code, "BHV-LIFECYCLE-FORBIDDEN");
  }
});

test("agent_tasks preserves a closed state failure envelope", async () => {
  const tool = createAgentTasksTool(fakePi(), runtime(), {
    invokeState: async (operation) => ({
      ok: false,
      code: "AT-TASK-NOT-FOUND",
      operation,
      data: { message: "The task does not exist." },
    }),
  });
  const result = await tool.execute("call-4", {
    operation: "status",
    request: {},
  }, undefined, undefined, mainContext());
  assert.equal(result.isError, true);
  assert.deepEqual(result.details, {
    schema_version: 1,
    record_type: "agent_tasks_tool_details",
    operation: "status",
    ok: false,
    code: "AT-TASK-NOT-FOUND",
    data: { message: "The task does not exist." },
  });
});

test("agent_tasks maps cancellation and malformed direct input to bounded failures", async () => {
  const tool = createAgentTasksTool(fakePi(), runtime(), {
    invokeState: async () => {
      throw new Error("cancelled");
    },
  });
  const cancelled = await tool.execute("call-5", {
    operation: "status",
    request: {},
  }, undefined, undefined, mainContext());
  assert.equal(cancelled.details.code, "cancelled");
  const malformed = await tool.execute("call-6", {
    operation: "status",
    request: {},
    inferred: true,
  }, undefined, undefined, mainContext());
  assert.equal(malformed.details.code, "BHV-LIFECYCLE-FORBIDDEN");
});

test("agent_tasks observation failures cannot change a successful authorization result", async () => {
  const tool = createAgentTasksTool(fakePi(), runtime(), {
    invokeState: async (operation) => successEnvelope(operation, { mode: "ready" }),
    observe: () => {
      throw new Error("metric sink unavailable");
    },
  });
  const result = await tool.execute("call-7", {
    operation: "status",
    request: {},
  }, undefined, undefined, mainContext());
  assert.equal(result.isError, false);
  assert.equal(result.details.code, "AT-OK");
  assert.deepEqual(result.details.data, { mode: "ready" });
});
