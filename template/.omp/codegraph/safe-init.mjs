import { spawnSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

function fail(reason) {
  process.stderr.write(`${JSON.stringify({ schema_version: 1, ok: false, reason })}\n`);
  process.exit(1);
}

function parseArgs(argv) {
  if (argv.length !== 4 || argv[0] !== "--bundle-root" || argv[2] !== "--project-root") {
    fail("invalid_arguments");
  }
  const bundleRoot = argv[1];
  const projectRoot = argv[3];
  if (!path.isAbsolute(bundleRoot) || !path.isAbsolute(projectRoot)) fail("path_not_absolute");
  return { bundleRoot, projectRoot };
}

function comparable(value) {
  const normalized = path.resolve(value).replace(/[\\/]+$/, "");
  return process.platform === "win32" ? normalized.toLowerCase() : normalized;
}

function requireCanonicalDirectory(value, reason) {
  let resolved;
  try {
    resolved = fs.realpathSync.native(value);
    if (!fs.statSync(resolved).isDirectory()) fail(reason);
  } catch {
    fail(reason);
  }
  if (comparable(value) !== comparable(resolved)) fail(reason);
  return resolved;
}

function isInside(root, candidate) {
  const relative = path.relative(root, candidate);
  return relative !== "" && relative !== ".." && !relative.startsWith(`..${path.sep}`) &&
    !path.isAbsolute(relative);
}

function requireGitWorktreeRoot(projectRoot) {
  const result = spawnSync(
    "git",
    ["-C", projectRoot, "rev-parse", "--show-toplevel"],
    { encoding: "utf8", shell: false, windowsHide: true, timeout: 10_000 },
  );
  if (result.status !== 0 || typeof result.stdout !== "string" || !result.stdout.trim()) {
    fail("project_not_git_worktree");
  }
  const reported = fs.realpathSync.native(result.stdout.trim());
  if (comparable(reported) !== comparable(projectRoot)) fail("project_not_worktree_root");
}

function fileIdentity(fullPath, relativePath) {
  const stat = fs.lstatSync(fullPath);
  if (stat.isSymbolicLink()) return `L|${relativePath}|${fs.readlinkSync(fullPath)}`;
  if (stat.isDirectory()) return `D|${relativePath}`;
  if (!stat.isFile()) return `O|${relativePath}|${stat.mode}`;
  const digest = crypto.createHash("sha256").update(fs.readFileSync(fullPath)).digest("hex");
  return `F|${relativePath}|${stat.size}|${digest}`;
}

function appendTree(rows, root, current, prefix, topLevel) {
  for (const name of fs.readdirSync(current).sort()) {
    if (topLevel && (name === ".codegraph" || name === ".git")) continue;
    const fullPath = path.join(current, name);
    const relativePath = path.posix.join(prefix, name);
    const identity = fileIdentity(fullPath, relativePath);
    rows.push(identity);
    if (identity.startsWith("D|")) appendTree(rows, root, fullPath, relativePath, false);
  }
}

function snapshotProtectedBytes(projectRoot) {
  const rows = [];
  appendTree(rows, projectRoot, projectRoot, "", true);
  const hooks = path.join(projectRoot, ".git", "hooks");
  if (fs.existsSync(hooks)) appendTree(rows, hooks, hooks, ".git/hooks", false);
  return crypto.createHash("sha256").update(rows.join("\n"), "utf8").digest("hex");
}

function nonnegativeInteger(value, reason) {
  if (!Number.isSafeInteger(value) || value < 0) fail(reason);
  return value;
}

const args = parseArgs(process.argv.slice(2));
const bundleRoot = requireCanonicalDirectory(args.bundleRoot, "bundle_root_invalid");
const projectRoot = requireCanonicalDirectory(args.projectRoot, "project_root_invalid");
requireGitWorktreeRoot(projectRoot);

let libraryPath;
try {
  libraryPath = fs.realpathSync.native(path.join(bundleRoot, "lib", "dist", "index.js"));
} catch {
  fail("library_entry_missing");
}
if (!isInside(bundleRoot, libraryPath) || !fs.statSync(libraryPath).isFile()) {
  fail("library_entry_outside_bundle");
}

const protectedBefore = snapshotProtectedBytes(projectRoot);
let graph;
let indexResult;
let operationFailed = false;
try {
  const imported = await import(pathToFileURL(libraryPath).href);
  const CodeGraph = imported.CodeGraph ?? imported.default?.CodeGraph ??
    imported.default?.default ?? imported.default;
  if (typeof CodeGraph?.init !== "function") throw new Error("invalid_module");
  graph = await CodeGraph.init(projectRoot, { index: false });
  if (!graph || typeof graph.indexAll !== "function" || typeof graph.destroy !== "function") {
    throw new Error("invalid_graph");
  }
  indexResult = await graph.indexAll();
  if (!indexResult?.success) operationFailed = true;
} catch {
  operationFailed = true;
} finally {
  if (graph && typeof graph.destroy === "function") {
    try {
      await graph.destroy();
    } catch {
      operationFailed = true;
    }
  }
}

if (snapshotProtectedBytes(projectRoot) !== protectedBefore) fail("protected_bytes_changed");
if (operationFailed) fail("initialization_failed");

process.stdout.write(`${JSON.stringify({
  schema_version: 1,
  ok: true,
  files_indexed: nonnegativeInteger(indexResult.filesIndexed, "invalid_index_result"),
  files_errored: nonnegativeInteger(indexResult.filesErrored, "invalid_index_result"),
  nodes_created: nonnegativeInteger(indexResult.nodesCreated, "invalid_index_result"),
  edges_created: nonnegativeInteger(indexResult.edgesCreated, "invalid_index_result"),
  duration_ms: nonnegativeInteger(indexResult.durationMs, "invalid_index_result"),
})}\n`);
