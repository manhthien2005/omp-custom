# Optional CodeGraph component

CodeGraph is an optional, default-off retrieval capability. Install it explicitly together with
the `state` component and either a verified offline artifact or explicit download permission.
The adapter never enables MCP, hooks, auto-update, telemetry, or background indexing.

Use native `read`/`grep`/`glob` retrieval when it is sufficient. A missing, busy, stale, partial,
unhealthy, timed-out, or failed CodeGraph result returns a closed reason code and a native
fallback; it never blocks the wider workflow or proves an absence/critical claim by itself.

The shared binary bundle lives under the user's managed `.omp/cache/codegraph` root. Per-worktree
indexes live only in that worktree's `.codegraph` directory. Uninstall restores template-owned
target files but retains and reports both cache classes. It never searches for or deletes unknown
indexes. To remove retained data, run `scripts/cleanup-codegraph.ps1` first as a dry run, inspect
the exact canonical targets and confirmation token, then repeat with `-Apply -Confirmation`.

Adapter reason codes are documented by `codegraph-process.ps1`; non-completed results include the
closed reason and `fallback: native`. Do not run the upstream launcher through a shell, edit
generated `runtime.json`/`install-record.json`, or bypass their hash and state-manifest checks.
