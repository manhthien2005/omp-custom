import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { pathToFileURL } from "node:url";
import { execFileSync, spawnSync } from "node:child_process";

const repositoryRoot = path.resolve(import.meta.dirname, "..", "..");
const sourceTool = path.join(repositoryRoot, "template", ".omp", "tools", "codegraph-retrieve.js");
const sourceExists = fs.existsSync(sourceTool);
const temporaryRoots = [];

function sha256(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function bundleTreeHash(bundle) {
  const rows = [];
  function visit(directory) {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const full = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(full);
      else if (entry.isFile()) {
        const relative = path.relative(bundle, full).split(path.sep).join("/");
        if (relative !== "receipt.json") rows.push(`${relative}|${fs.statSync(full).size}|${sha256(full)}`);
      }
    }
  }
  visit(bundle);
  rows.sort((left, right) => Buffer.from(left).compare(Buffer.from(right)));
  return crypto.createHash("sha256").update(rows.join("\n"), "utf8").digest("hex");
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function platformName() {
  const osName = { win32: "win32", linux: "linux", darwin: "darwin" }[process.platform];
  const architecture = { x64: "x64", arm64: "arm64" }[process.arch];
  if (!osName || !architecture) throw new Error("unsupported test platform");
  return `${osName}-${architecture}`;
}

function successEnvelope(text = "graph fixture result") {
  return {
    schema_version: 1,
    ok: true,
    status: "completed",
    reason_code: "ok",
    fallback: null,
    data: {
      text,
      binding: {
        mode: "observation",
        worktree_root: "C:/fixture",
        workspace_snapshot_sha256: "a".repeat(64),
        task_id: null,
        candidate_id: null,
        candidate_hash: null,
      },
      codegraph: {
        version: "1.5.0",
        index_path: "C:/fixture/.codegraph",
        index_state: "complete",
        synced: true,
        lazy_initialized: false,
        initial_files_errored: 0,
        gap_signals: [],
      },
      metrics: { init_ms: 0, sync_ms: 1, query_ms: 2, output_bytes: Buffer.byteLength(text) },
    },
  };
}

function failureEnvelope(reason = "index_unhealthy", status = "failed") {
  return {
    schema_version: 1,
    ok: false,
    status,
    reason_code: reason,
    fallback: "native",
    data: null,
  };
}

function typeboxFixture() {
  const Type = {
    Object(properties, options = {}) { return { type: "object", properties, ...options }; },
    String(options = {}) { return { type: "string", ...options }; },
    Integer(options = {}) { return { type: "integer", ...options }; },
    Optional(schema) { return { ...schema, optional: true }; },
  };
  return { Type };
}

function resolveOmpExecutable() {
  const locator = process.platform === "win32" ? "where.exe" : "which";
  const output = execFileSync(locator, ["omp"], { encoding: "utf8" }).trim();
  const executable = output.split(/\r?\n/u).find(Boolean);
  assert.ok(executable, "omp executable is unavailable");
  return executable;
}

function readRpcState(root, extraArgs = []) {
  const helper = String.raw`
    const { spawnSync } = require("node:child_process");
    const [omp, cwd, encodedArgs] = process.argv.slice(1);
    const result = spawnSync(omp, JSON.parse(encodedArgs), {
      cwd,
      encoding: "utf8",
      input: JSON.stringify({ id: "topic05-state", type: "get_state" }) + "\n",
      maxBuffer: 4 * 1024 * 1024,
      timeout: 20000,
      windowsHide: true,
    });
    process.stdout.write(JSON.stringify({
      error: result.error?.message,
      signal: result.signal,
      status: result.status,
      stdout: result.stdout,
      stderr: result.stderr,
    }));
  `;
  const args = ["--mode", "rpc", "--no-session", "--no-skills", "--no-rules", ...extraArgs];
  const helperResult = spawnSync(process.execPath, [
    "-e", helper, resolveOmpExecutable(), root, JSON.stringify(args),
  ], { encoding: "utf8", maxBuffer: 5 * 1024 * 1024, timeout: 25_000, windowsHide: true });
  assert.equal(helperResult.error, undefined, helperResult.error?.message);
  assert.equal(helperResult.signal, null, `RPC helper terminated by ${helperResult.signal}`);
  assert.equal(helperResult.status, 0, helperResult.stderr);
  const result = JSON.parse(helperResult.stdout);
  assert.equal(result.error, undefined, result.error);
  assert.equal(result.signal, null, `omp RPC terminated by ${result.signal}`);
  assert.equal(result.status, 0, result.stderr);
  const frames = result.stdout
    .split(/\r?\n/u)
    .filter(Boolean)
    .map((line) => JSON.parse(line));
  assert.ok(frames.some((frame) => frame.type === "ready"), "omp RPC did not emit ready");
  const response = frames.find((frame) =>
    frame.type === "response" && frame.id === "topic05-state" && frame.command === "get_state"
  );
  assert.equal(response?.success, true, response?.error);
  return response.data;
}

async function newInstalledFixture(execImplementation) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "omp-topic05-tool-"));
  temporaryRoots.push(root);
  const target = path.join(root, "target");
  const targetOmp = path.join(target, ".omp");
  const tools = path.join(targetOmp, "tools");
  const component = path.join(targetOmp, "codegraph");
  const project = path.join(root, "project");
  const bundle = path.join(root, "cache", "v1.5.0", platformName());
  fs.mkdirSync(tools, { recursive: true });
  fs.mkdirSync(component, { recursive: true });
  fs.mkdirSync(project, { recursive: true });
  fs.mkdirSync(bundle, { recursive: true });
  const installedTool = path.join(tools, "codegraph-retrieve.js");
  writeJson(path.join(target, "package.json"), { type: "module" });
  fs.copyFileSync(sourceTool, installedTool);
  const wrapper = path.join(component, "codegraph-process.ps1");
  fs.writeFileSync(wrapper, "# fixture wrapper\n", "utf8");
  const safeInit = path.join(component, "safe-init.mjs");
  fs.writeFileSync(safeInit, "// fixture safe init\n", "utf8");
  const componentManifest = path.join(component, "component-manifest.json");
  writeJson(componentManifest, {
    schema_version: 1,
    record_type: "codegraph_component_manifest",
    component: "codegraph",
    component_version: "1.0.0",
  });
  const upstreamLock = path.join(component, "upstream-lock.json");
  fs.copyFileSync(
    path.join(repositoryRoot, "template", ".omp", "codegraph", "upstream-lock.json"),
    upstreamLock,
  );
  const lock = JSON.parse(fs.readFileSync(upstreamLock, "utf8"));
  const artifact = lock.artifacts.find((row) => row.platform === platformName());
  const requiredPaths = {
    launcher: path.join("bin", process.platform === "win32" ? "codegraph.cmd" : "codegraph"),
    node: process.platform === "win32" ? "node.exe" : "node",
    package: path.join("lib", "package.json"),
    library_entry: path.join("lib", "dist", "index.js"),
    cli_entry: path.join("lib", "dist", "bin", "codegraph.js"),
  };
  for (const relative of Object.values(requiredPaths)) {
    const full = path.join(bundle, relative);
    fs.mkdirSync(path.dirname(full), { recursive: true });
    if (relative === requiredPaths.node) {
      try { fs.linkSync(process.execPath, full); } catch { fs.copyFileSync(process.execPath, full); }
    } else if (relative === requiredPaths.package) {
      fs.writeFileSync(full, '{"name":"codegraph","version":"1.5.0","type":"module"}', "utf8");
    } else {
      fs.writeFileSync(full, `fixture:${relative}`, "utf8");
    }
  }
  const requiredFiles = Object.fromEntries(Object.entries(requiredPaths).map(([name, relative]) => [
    name,
    { path: relative.split(path.sep).join("/"), sha256: sha256(path.join(bundle, relative)) },
  ]));
  const receipt = path.join(bundle, "receipt.json");
  writeJson(receipt, {
    schema_version: 1,
    record_type: "codegraph_bundle_receipt",
    upstream: "colbymchenry/codegraph",
    version: "1.5.0",
    tag: "v1.5.0",
    commit: "ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6",
    platform: platformName(),
    bundle_root: path.resolve(bundle),
    receipt_path: path.resolve(receipt),
    artifact,
    required_files: requiredFiles,
    bundle_tree_sha256: bundleTreeHash(bundle),
    provisioned_at_utc: "2026-08-13T00:00:00.000Z",
  });
  const runtimePath = path.join(component, "runtime.json");
  writeJson(runtimePath, {
    schema_version: 1,
    record_type: "codegraph_target_runtime",
    component: "codegraph",
    component_version: "1.0.0",
    created_at_utc: "2026-08-13T00:00:00.000Z",
    target_omp: path.resolve(targetOmp),
    component_manifest_sha256: sha256(componentManifest),
    upstream_lock_sha256: sha256(upstreamLock),
    receipt_sha256: sha256(receipt),
    upstream: "colbymchenry/codegraph",
    version: "1.5.0",
    tag: "v1.5.0",
    commit: "ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6",
    platform: platformName(),
    artifact_sha256: artifact.sha256,
    paths: {
      bundle_root: path.resolve(bundle),
      receipt: path.resolve(receipt),
      launcher: path.join(bundle, requiredPaths.launcher),
      node: path.join(bundle, requiredPaths.node),
      library_entry: path.join(bundle, requiredPaths.library_entry),
      cli_entry: path.join(bundle, requiredPaths.cli_entry),
      safe_init: path.resolve(safeInit),
      process_wrapper: path.resolve(wrapper),
      pwsh: process.execPath,
    },
  });

  const calls = [];
  const pi = {
    cwd: project,
    typebox: typeboxFixture(),
    async exec(command, args, options) {
      calls.push({ command, args, options });
      return execImplementation
        ? execImplementation(command, args, options)
        : { stdout: `${JSON.stringify(successEnvelope())}\n`, stderr: "", code: 0, killed: false };
    },
  };
  const module = await import(`${pathToFileURL(installedTool).href}?fixture=${crypto.randomUUID()}`);
  return {
    root,
    targetOmp,
    component,
    project,
    bundle,
    installedTool,
    runtimePath,
    wrapper,
    calls,
    pi,
    module,
    tool: module.default(pi),
  };
}

test.after(async () => {
  // Windows can retain the just-exited RPC process' cwd handle for a short interval.
  await new Promise((resolve) => setTimeout(resolve, 500));
  for (const root of temporaryRoots) {
    const resolved = path.resolve(root);
    if (path.dirname(resolved) !== path.resolve(os.tmpdir()) || !path.basename(resolved).startsWith("omp-topic05-tool-")) {
      throw new Error(`unsafe Topic 05 tool cleanup target: ${resolved}`);
    }
    fs.rmSync(resolved, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });
  }
});

test("model-facing CodeGraph tool exists", () => {
  assert.equal(sourceExists, true, "template/.omp/tools/codegraph-retrieve.js is missing");
});

if (sourceExists) {
  test("factory exposes one strict discoverable exec-approved tool", async () => {
    const fixture = await newInstalledFixture();
    assert.equal(fixture.tool.name, "codegraph_retrieve");
    assert.equal(fixture.tool.label, "CodeGraph Retrieve");
    assert.equal(fixture.tool.loadMode, "discoverable");
    assert.equal(fixture.tool.approval, "exec");
    assert.equal(fixture.tool.strict, true);
    assert.deepEqual(Object.keys(fixture.tool.parameters.properties).sort(), ["max_files", "question"]);
    assert.equal(fixture.tool.parameters.properties.question.maxLength, 1024);
    assert.equal(fixture.tool.parameters.additionalProperties, false);
  });

  test("normalization and fixed argument array preserve literal question bytes", async () => {
    const fixture = await newInstalledFixture();
    const signal = new AbortController().signal;
    const raw = "  -trace 'cafe\u0301'\n; | $() ` 中文  ";
    const result = await fixture.tool.execute("call-1", { question: raw, max_files: 99 }, undefined, {}, signal);
    assert.equal(result.isError, false);
    assert.equal(fixture.calls.length, 1);
    const call = fixture.calls[0];
    assert.equal(call.command, process.execPath);
    assert.deepEqual(call.options, { cwd: fixture.project, signal, timeout: 600000 });
    assert.equal(call.args[0], "-NoProfile");
    assert.equal(call.args[1], "-NonInteractive");
    assert.equal(call.args[2], "-File");
    assert.equal(call.args[3], fixture.wrapper);
    assert.equal(call.args[4], "-Operation");
    assert.equal(call.args[5], "retrieve");
    assert.equal(call.args[6], "-RuntimePath");
    assert.equal(call.args[7], fixture.runtimePath);
    assert.equal(call.args[8], "-WorkingDirectory");
    assert.equal(call.args[9], fixture.project);
    assert.equal(call.args[10], "-QuestionBase64");
    assert.equal(Buffer.from(call.args[11], "base64url").toString("utf8"), raw.trim().normalize("NFC"));
    assert.equal(call.args[12], "-MaxFiles");
    assert.equal(call.args[13], "12");
    assert.equal(call.args.includes("--"), false, "the tool must not expose a direct CLI operation");
  });

  test("input validation defaults clamps and rejects unsafe surface", async () => {
    const fixture = await newInstalledFixture();
    const valid = await fixture.tool.execute("call", { question: "valid" }, undefined, {}, undefined);
    assert.equal(valid.isError, false);
    assert.equal(fixture.calls[0].args.at(-1), "6");
    for (const params of [
      {},
      { question: "" },
      { question: "\0" },
      { question: "x", max_files: 1.5 },
      { question: "x", path: "C:/secret" },
      { question: "x", command: "status" },
      { question: "x", environment: { SECRET: "value" } },
      { question: "x".repeat(1025) },
      { question: "\ud800" },
    ]) {
      const before = fixture.calls.length;
      const result = await fixture.tool.execute("invalid", params, undefined, {}, undefined);
      assert.equal(result.isError, true);
      assert.equal(result.details.reason_code, "query_failed");
      assert.equal(fixture.calls.length, before, "invalid input reached pi.exec");
    }
  });

  test("runtime and wrapper derive from import.meta.url and tamper blocks execution", async () => {
    const fixture = await newInstalledFixture();
    fs.mkdirSync(path.join(fixture.project, ".omp", "codegraph"), { recursive: true });
    fs.writeFileSync(path.join(fixture.project, ".omp", "codegraph", "runtime.json"), "{}", "utf8");
    const result = await fixture.tool.execute("call", { question: "valid" }, undefined, {}, undefined);
    assert.equal(result.isError, false);
    assert.equal(fixture.calls[0].args[7], fixture.runtimePath);

    const runtime = JSON.parse(fs.readFileSync(fixture.runtimePath, "utf8"));
    runtime.receipt_sha256 = "0".repeat(64);
    writeJson(fixture.runtimePath, runtime);
    const before = fixture.calls.length;
    const refused = await fixture.tool.execute("call", { question: "valid" }, undefined, {}, undefined);
    assert.equal(refused.isError, true);
    assert.equal(refused.details.reason_code, "runtime_manifest_invalid");
    assert.equal(fixture.calls.length, before);
  });

  test("one JSON line is required and model text never leaks process diagnostics", async () => {
    const outputs = [
      "",
      `${JSON.stringify(successEnvelope())}\n${JSON.stringify(successEnvelope())}\n`,
      `${JSON.stringify(successEnvelope())}\ntrailing`,
      "{malformed}\n",
      "x".repeat(140_000),
    ];
    for (const stdout of outputs) {
      const fixture = await newInstalledFixture(() => ({
        stdout,
        stderr: "TOP_SECRET_STDERR",
        code: 0,
        killed: false,
      }));
      const result = await fixture.tool.execute("call", { question: "valid" }, undefined, {}, undefined);
      assert.equal(result.isError, true);
      assert.equal(result.details.reason_code, "internal_error");
      assert.equal(result.content.length, 1);
      assert.doesNotMatch(result.content[0].text, /TOP_SECRET_STDERR|malformed|trailing/);
    }
  });

  test("completed and fallback rendering preserve only the closed envelope", async () => {
    const completed = await newInstalledFixture(() => ({
      stdout: `${JSON.stringify(successEnvelope("bounded graph"))}\n`, stderr: "", code: 0, killed: false,
    }));
    const success = await completed.tool.execute("call", { question: "valid" }, undefined, {}, undefined);
    assert.equal(success.isError, false);
    assert.deepEqual(success.content, [{ type: "text", text: "bounded graph" }]);
    assert.equal(success.details.reason_code, "ok");

    const blocked = await newInstalledFixture(() => ({
      stdout: `${JSON.stringify(failureEnvelope("index_busy", "blocked"))}\n`,
      stderr: "secret child stderr",
      code: 0,
      killed: false,
    }));
    const fallback = await blocked.tool.execute("call", { question: "valid" }, undefined, {}, undefined);
    assert.equal(fallback.isError, true);
    assert.equal(
      fallback.content[0].text,
      "CodeGraph retrieval unavailable (index_busy); continue with native read/grep/glob retrieval.",
    );
    assert.equal(fallback.details.reason_code, "index_busy");
    assert.doesNotMatch(fallback.content[0].text, /secret/);
  });

  test("AbortSignal cancellation kills through pi.exec and returns a closed native fallback", async () => {
    const controller = new AbortController();
    const fixture = await newInstalledFixture((_command, _args, options) => {
      assert.equal(options.signal, controller.signal);
      return { stdout: "", stderr: "cancel secret", code: 1, killed: true };
    });
    const result = await fixture.tool.execute(
      "call",
      { question: "valid" },
      undefined,
      {},
      controller.signal,
    );
    assert.equal(result.isError, true);
    assert.equal(result.details.reason_code, "cancelled");
    assert.equal(
      result.content[0].text,
      "CodeGraph retrieval unavailable (cancelled); continue with native read/grep/glob retrieval.",
    );
    assert.doesNotMatch(result.content[0].text, /cancel secret/);
  });

  test("installed tool is discoverable through token-free OMP RPC state", () => {
    const state = readRpcState(path.join(repositoryRoot, "template"));
    const toolNames = state.dumpTools.map((tool) => tool.name);
    const prompt = state.systemPrompt.join("\n");
    assert.ok(
      toolNames.includes("codegraph_retrieve") || prompt.includes("xd://codegraph_retrieve"),
      "ordinary OMP session did not discover codegraph_retrieve",
    );
  });

  test("pinned OMP source preserves discovery restricted-session and descendant-cancellation contracts", () => {
    const upstream = path.join(repositoryRoot, "_research", "upstreams", "oh-my-pi");
    assert.equal(
      execFileSync("git", ["-C", upstream, "rev-parse", "HEAD"], { encoding: "utf8" }).trim(),
      "3a8591a8af5b6d200088d12ca75a5517cb064fa8",
    );
    assert.equal(execFileSync("git", ["-C", upstream, "status", "--short"], { encoding: "utf8" }), "");
    const loader = fs.readFileSync(path.join(
      upstream,
      "packages", "coding-agent", "src", "extensibility", "custom-tools", "loader.ts",
    ), "utf8");
    assert.match(loader, /\.omp\/tools\//);
    const builtinDiscovery = fs.readFileSync(path.join(
      upstream,
      "packages", "coding-agent", "src", "discovery", "builtin.ts",
    ), "utf8");
    assert.match(builtinDiscovery, /extensions: \["json", "md", "ts", "js", "sh", "bash", "py"\]/);
    assert.doesNotMatch(builtinDiscovery, /extensions: \[[^\]]*"mjs"/);
    const sdk = fs.readFileSync(path.join(upstream, "packages", "coding-agent", "src", "sdk.ts"), "utf8");
    assert.match(sdk, /if \(!restrictToolNames\)/);
    assert.match(sdk, /loadCustomTools\(customToolPaths/);
    assert.match(sdk, /restrictToolNames && options\.allowRestrictedCustomTools !== true/);
    assert.match(sdk, /customToolToDefinition/);
    const toolsIndex = fs.readFileSync(path.join(
      upstream,
      "packages", "coding-agent", "src", "tools", "index.ts",
    ), "utf8");
    assert.match(toolsIndex, /isMountableUnderXdev\(tool\)/);
    assert.match(toolsIndex, /!restrictToolNames/);
    const xdev = fs.readFileSync(path.join(
      upstream,
      "packages", "coding-agent", "src", "tools", "xdev.ts",
    ), "utf8");
    assert.match(xdev, /return tool\.loadMode === "discoverable"/);
    const executor = fs.readFileSync(path.join(
      upstream,
      "packages", "coding-agent", "src", "task", "executor.ts",
    ), "utf8");
    assert.match(executor, /preloadedCustomToolPaths: restrictToolNames \? \[\] : options\.preloadedCustomToolPaths/);
    const execSource = fs.readFileSync(path.join(
      upstream,
      "packages", "coding-agent", "src", "exec", "exec.ts",
    ), "utf8");
    assert.match(execSource, /ptree\.exec\(\[command, \.\.\.args\]/);
    assert.match(execSource, /signal: options\?\.signal/);
    assert.match(execSource, /timeout: options\?\.timeout/);
  });
}
