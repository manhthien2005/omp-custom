import fs from "node:fs";
import path from "node:path";

const fixturePath = process.env.OMP_TOPIC05_CODEGRAPH_FIXTURE;
if (!fixturePath || !path.isAbsolute(fixturePath)) {
  process.stderr.write("fixture_unavailable\n");
  process.exit(91);
}

const fixture = JSON.parse(fs.readFileSync(fixturePath, "utf8"));
const mode = typeof fixture.mode === "string" ? fixture.mode : "healthy";
const argv = process.argv.slice(2);
const command = argv[0] ?? "";

function appendLog(extra = {}) {
  if (!fixture.log_path || !path.isAbsolute(fixture.log_path)) return;
  const record = {
    argv,
    cwd: process.cwd(),
    environment: {
      CODEGRAPH_DIR: process.env.CODEGRAPH_DIR ?? null,
      CODEGRAPH_TELEMETRY: process.env.CODEGRAPH_TELEMETRY ?? null,
      CODEGRAPH_NO_UPDATE_CHECK: process.env.CODEGRAPH_NO_UPDATE_CHECK ?? null,
      CODEGRAPH_NO_DAEMON: process.env.CODEGRAPH_NO_DAEMON ?? null,
      DO_NOT_TRACK: process.env.DO_NOT_TRACK ?? null,
      CI: process.env.CI ?? null,
      NO_COLOR: process.env.NO_COLOR ?? null,
      NODE_OPTIONS: process.env.NODE_OPTIONS ?? null,
      NODE_PATH: process.env.NODE_PATH ?? null,
      leaked_codegraph_key: Object.keys(process.env).find(
        (key) => key.startsWith("CODEGRAPH_") && ![
          "CODEGRAPH_DIR",
          "CODEGRAPH_TELEMETRY",
          "CODEGRAPH_NO_UPDATE_CHECK",
          "CODEGRAPH_NO_DAEMON",
        ].includes(key),
      ) ?? null,
    },
    ...extra,
  };
  fs.appendFileSync(fixture.log_path, `${JSON.stringify(record)}\n`, "utf8");
}

async function pause() {
  if (mode === "timeout" && (!fixture.target_command || fixture.target_command === command)) {
    await new Promise((resolve) => setTimeout(resolve, fixture.delay_ms ?? 60_000));
  }
}

function failIfRequested() {
  const targeted = !fixture.target_command || fixture.target_command === command;
  if (mode === "nonzero" && targeted) {
    process.stderr.write("fixture failure with secret details\n");
    process.exit(17);
  }
  if (mode === "stderr_overflow" && targeted) {
    process.stderr.write("e".repeat(fixture.overflow_bytes ?? 131_072));
  }
  if (mode === "stdout_overflow" && targeted) {
    process.stdout.write("o".repeat(fixture.overflow_bytes ?? 1_048_576));
  }
}

await pause();
if (mode === "infinite_stdout" && (!fixture.target_command || fixture.target_command === command)) {
  setInterval(() => process.stdout.write("o".repeat(16_384)), 1);
  await new Promise(() => {});
}
failIfRequested();

if (command === "--version") {
  appendLog();
  process.stdout.write(`${fixture.version ?? (mode === "version_mismatch" ? "1.4.9" : "1.5.0")}\n`);
  process.exit(0);
}

if (command === "sync") {
  const root = path.resolve(argv[1] ?? "");
  appendLog({ root });
  if (mode === "uninitialized") {
    process.stderr.write("not initialized\n");
    process.exit(2);
  }
  process.stdout.write("synced\n");
  process.exit(0);
}

if (command === "status") {
  const root = path.resolve(argv[1] ?? "");
  const indexPath = path.join(root, ".codegraph");
  const stateByMode = {
    partial: "partial",
    indexing: "indexing",
    failed: "failed",
    null_state: null,
  };
  const status = {
    initialized: mode !== "uninitialized",
    version: fixture.version ?? "1.5.0",
    projectPath: mode === "project_mismatch" ? path.join(root, "other") : root,
    indexPath: mode === "index_path_mismatch" ? path.join(root, "other-index") : indexPath,
    lastIndexed: "2026-08-13T00:00:00.000Z",
    fileCount: 4,
    nodeCount: 12,
    edgeCount: 11,
    dbSizeBytes: 1024,
    backend: "node:sqlite",
    journalMode: "wal",
    nodesByKind: { function: 4 },
    languages: ["javascript"],
    pendingChanges: {
      added: mode === "pending_changes" ? 1 : 0,
      modified: 0,
      removed: 0,
    },
    worktreeMismatch: mode === "worktree_mismatch"
      ? { worktreeRoot: root, indexRoot: path.join(root, "other") }
      : null,
    index: {
      builtWithVersion: "1.5.0",
      builtWithExtractionVersion: 1,
      currentExtractionVersion: 1,
      reindexRecommended: mode === "reindex_recommended",
      state: Object.hasOwn(stateByMode, mode) ? stateByMode[mode] : "complete",
      pendingRefs: mode === "pending_refs" ? 1 : 0,
    },
  };
  appendLog({ root });
  process.stdout.write(`${JSON.stringify(status)}\n`);
  process.exit(0);
}

if (command === "explore") {
  const separator = argv.indexOf("--");
  const rootIndex = argv.indexOf("--path");
  const maxFilesIndex = argv.indexOf("--max-files");
  if (separator < 0 || rootIndex < 0 || maxFilesIndex < 0 || separator !== argv.length - 2) {
    process.stderr.write("invalid explore argv\n");
    process.exit(64);
  }
  const root = path.resolve(argv[rootIndex + 1]);
  const question = argv[separator + 1];
  appendLog({ root, question, max_files: Number(argv[maxFilesIndex + 1]) });
  if (mode === "source_mutation" && fixture.mutate_path) {
    fs.writeFileSync(fixture.mutate_path, fixture.mutate_content ?? "mutated\n", "utf8");
  }
  if (fixture.replace_lock_path && path.isAbsolute(fixture.replace_lock_path)) {
    fs.writeFileSync(fixture.replace_lock_path, '{"replacement":true}', "utf8");
  }
  const graph = mode === "empty_graph" ? "" : (fixture.graph_text ?? "graph fixture result");
  process.stdout.write(graph);
  if (graph && !graph.endsWith("\n")) process.stdout.write("\n");
  process.exit(0);
}

process.stderr.write("unsupported fixture command\n");
process.exit(64);
