# Topic 05 Progressive Retrieval, CodeGraph, and Cheap Scout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Execution selection:** Inline execution with checkpoints is recommended for this repository.
> The user does not prioritize subagent execution unless a spawn has a concrete benefit, and the
> runtime, installer, worktree binding, and benchmark tasks below share one sequential contract.

**Goal:** Add an optional, default-off CodeGraph retrieval capability that a Tech Lead, Cheap
Scout, or Reviewer can use without granting arbitrary execution or MCP authority; keep one lazy
index per Git worktree; bind graph evidence to current Topic 04 state; fall back cleanly to native
retrieval; and provide an uncontaminated four-arm benchmark without spending model quota unless
the user explicitly authorizes it.

**Architecture:** The `codegraph` installer component provisions one manifest-pinned upstream
bundle into a user-local managed cache and installs a capability-narrow OMP custom tool. The tool
accepts only a bounded question and `max_files`, then delegates one closed retrieval transaction
to a PowerShell 7.4 helper. That helper derives the canonical worktree, reconciles Topic 04 state,
performs a safe library-level lazy initialization, syncs and health-checks the per-worktree index,
runs one bounded `explore`, and rejects the result if source/candidate identity changes. Agent
prompts select actor and capability independently; native retrieval remains the universal
fallback and current source/runtime evidence remains authoritative.

**Tech Stack:** OMP custom tools (`.js`, closed JSON-Schema frontmatter, `loadMode: discoverable`, `approval:
exec`); PowerShell 7.4+ and .NET process/archive primitives; CodeGraph v1.5.0 self-contained
release bundles; Topic 04 deterministic state modules; Git plumbing; Node 24 native tests; JSON
records; PowerShell 5.1-compatible static validators and installer entry points.

**Spec:**
`docs/superpowers/specs/2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-design.md`

## Global Constraints

- CodeGraph is optional and absent from the installer default component list. Installing or
  opening the template never initializes an index.
- Pin upstream CodeGraph exactly to version `1.5.0`, tag `v1.5.0`, commit
  `ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6`, and the exact release artifact digest for the
  selected platform.
- Never run upstream `codegraph install`, `codegraph upgrade`, MCP `serve`, prompt hooks, Git-hook
  installation, or an auto-update path.
- The adapter is a retrieval capability, not a shell. Model input is only `question` and
  `max_files`; no path, executable, operation, environment variable, or command-line input is
  accepted from the model.
- Every CodeGraph subprocess receives telemetry/update opt-outs, a fixed working directory,
  bounded time/output, closed stdin, argument arrays rather than shell strings, and descendant
  process cleanup.
- Safe lazy initialization imports the pinned bundle's `lib/dist/index.js` and calls its library
  API. It does not call the interactive CLI `init` path, whose `offerWatchFallback()` branch can
  offer Git hooks.
- One canonical Git worktree owns one `.codegraph/` directory. Never share an index across linked
  worktrees, infer one from another checkout, or follow a symlinked `.codegraph` path.
- `.codegraph/` is cache, not source authority. The stable `.codegraph/.gitignore` marker is the
  only visible Git-status path and must be declared in Topic 04 `owned_ignored_outputs` when a
  supported task-bound path is selected. Database/log/runtime files remain ignored beneath it.
- If a frozen candidate exists but the worktree has no healthy pre-existing index, do not lazily
  initialize and thereby change candidate-visible bytes. Fall back to native retrieval.
- Graph results are hypotheses/evidence accelerators. Current source ranges, fitting runtime
  evidence, and official upstream sources remain authoritative.
- Cheap Scout is advisory and read-only with respect to project source. Its Flash `xhigh` route is
  primary and Pro `xhigh` is the only provider fallback; no Codex/premium substitution is made for
  unavailable DeepSeek. Topic 03's validated router maps OMP `xhigh` to DeepSeek thinking `max`;
  Topic 05 preserves that mapping rather than inferring model reasoning from a name.
- A weak but structurally valid Scout answer returns `partial` with named gaps. It does not trigger
  an opaque model retry. Provider/runtime unavailability and evidence quality are different cases.
- Reviewer independently retrieves against the frozen candidate and keeps exact `xhigh` review
  authority. Cheap Scout never becomes Reviewer or acceptance authority.
- Do not duplicate raw CodeGraph payload plus a summary across session boundaries. Scout and
  Reviewer return compact cited packets; direct Lead use consumes the one tool result in place.
- Native benchmark arms cannot see the adapter file, managed executable, CodeGraph instructions,
  or an existing `.codegraph` directory. Every arm record, including blocked/failed/timeout runs,
  is retained as a sanitized immutable run record.
- Provider-reported usage is required for token claims. Missing usage or residual-context data is
  `not_measured`; character estimates cannot support promotion.
- The benchmark adds no CodeGraph-specific percentage threshold. Correctness and contamination
  gates are hard; any recommendation is route- and task-class-specific.
- Deterministic tests, real local CodeGraph smoke tests, and token-free OMP discovery may run during
  implementation. A model pilot requires the user's new explicit authorization and an exact
  confirmation argument.
- Preserve all pre-existing dirty-worktree changes. Never reset, revert, delete, or overwrite
  unrelated work.
- Do not stage, commit, push, create a PR, or create a branch without a new explicit user
  instruction. Use path-scoped hashes, status, and test output for checkpoints.
- Do not spawn a subagent merely because this plan contains independent-looking tasks.

---

### Task 1: Lock the upstream release and executable component boundary

**Files:**
- Create: `template/.omp/codegraph/upstream-lock.json`
- Create: `scripts/tests/topic05-provisioning.Tests.ps1`

**Interfaces:**
- Consumes: official CodeGraph v1.5.0 GitHub release metadata and `SHA256SUMS`.
- Produces: one closed six-platform lock; no installation, download, target write, or index.

- [x] **Step 1: Write the failing closed-lock test**

Start `scripts/tests/topic05-provisioning.Tests.ps1` with a small self-contained runner matching
the existing Topic 03/04 convention. The first case must parse
`template/.omp/codegraph/upstream-lock.json` and assert:

~~~powershell
$expected = [ordered]@{
    'darwin-arm64' = 'cf5ee435a6e44d097b2f98f2b7b8b9422bb1094844404efed82519c5da1af2cf'
    'darwin-x64'   = '0a0ccc29bf7da9d10be1458d89d7e15c55927ae24cd95e9fa3de4bdfea059dde'
    'linux-arm64'  = '9f17750aedf45d51f68caae39ed21d6e2a7290b2326e5c53f95a165918ebd1d8'
    'linux-x64'    = '2ba65e87a1210b706bb1e67d5e48b5fc4a1935e43dbb3fb5f31c5597840d2e58'
    'win32-arm64'  = 'de125e792b5eed7dee8def2ab9bd7e762f372012f75f595e59d3b0c8714b0d55'
    'win32-x64'    = 'd6798622b4f44ee6757c94335f437ee27a9ff7d3537b554cb6a2b3baf11bc4a1'
}

Assert-Topic05Provision ($lock.schema_version -eq 1) 'lock schema must be 1'
Assert-Topic05Provision ($lock.version -ceq '1.5.0') 'version must be exact'
Assert-Topic05Provision ($lock.tag -ceq 'v1.5.0') 'tag must be exact'
Assert-Topic05Provision (
    $lock.commit -ceq 'ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6'
) 'commit must be exact'
Assert-Topic05Provision ($lock.license -ceq 'MIT') 'license must be MIT'
Assert-Topic05Provision (
    $lock.license_file.repository_path -ceq 'LICENSE' -and
    $lock.license_file.sha256 -ceq 'e6d98f98c666bebe065ac2492a0a19232cc318d4d67bac3ca42ffb77bacc8809'
) 'pinned license notice must match the upstream commit'
Assert-Topic05Provision (@($lock.artifacts).Count -eq 6) 'all six release platforms are required'
foreach ($platform in $expected.Keys) {
    $row = @($lock.artifacts | Where-Object platform -CEQ $platform)
    Assert-Topic05Provision ($row.Count -eq 1) "platform must occur exactly once: $platform"
    Assert-Topic05Provision ($row[0].sha256 -ceq $expected[$platform]) "digest mismatch: $platform"
}
~~~

Also reject unknown top-level/artifact fields, duplicate platform/name entries, non-lowercase
64-hex digests, non-positive sizes, non-v1.5.0 asset names, and any URL field in an artifact row.
URLs are derived by trusted code, not supplied per artifact.

- [x] **Step 2: Run the test and observe the intended failure**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-provisioning.Tests.ps1
~~~

Expected: nonzero with a single lock-missing/invalid failure. A missing file must not be treated as
an empty valid lock.

- [x] **Step 3: Add the exact upstream lock**

Create the JSON exactly from the `Closed Runtime Contracts / Upstream release lock` section. Add
these download-origin fields once at the top level:

~~~json
{
  "download_origin": "https://github.com/colbymchenry/codegraph/releases/download/v1.5.0/",
  "allowed_final_hosts": [
    "github.com",
    "release-assets.githubusercontent.com"
  ]
}
~~~

Merge them into the same closed document; do not create a second object or checksum source.

- [x] **Step 4: Re-run the closed-lock test**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-provisioning.Tests.ps1
~~~

Expected: the release-lock case passes. Provisioning cases added in Task 2 may not exist yet and
must not be represented as skipped PASS results.

- [x] **Step 5: Record a no-Git checkpoint**

~~~powershell
Get-FileHash template/.omp/codegraph/upstream-lock.json -Algorithm SHA256
git status --short -- template/.omp/codegraph/upstream-lock.json scripts/tests/topic05-provisioning.Tests.ps1
git diff --check -- template/.omp/codegraph/upstream-lock.json scripts/tests/topic05-provisioning.Tests.ps1
~~~

Expected: one lock hash, only the two intended paths, and no whitespace error. Do not stage or
commit.

---

### Task 2: Implement transactional, digest-verified bundle provisioning and explicit cleanup

**Files:**
- Modify: `scripts/tests/topic05-provisioning.Tests.ps1`
- Create: `scripts/lib/topic05-codegraph.ps1`
- Create: `scripts/provision-codegraph.ps1`
- Create: `scripts/cleanup-codegraph.ps1`

**Interfaces:**
- `Get-Topic05CodeGraphPlatform() -> darwin-arm64 | darwin-x64 | linux-arm64 | linux-x64 |
  win32-arm64 | win32-x64`.
- `Install-Topic05CodeGraphBundle -LockPath -CacheRoot [-ArtifactPath] [-AllowNetwork]` returns one
  JSON-serializable receipt and never changes the target project.
- Runtime-record construction is deliberately deferred to Task 6, where the component manifest
  and installed adapter paths exist and can be reconciled in the same failing-test cycle.
- Cleanup defaults to dry-run and accepts only an exact managed bundle or an explicitly confirmed
  `<worktree>/.codegraph` directory.

- [x] **Step 1: Add failing platform, archive, transaction, and cleanup cases**

Generate disposable fake bundles inside the test; do not check in a binary archive. Each fake
bundle has one exact top-level `codegraph-<platform>` directory and these files:

~~~text
bin/codegraph.cmd or bin/codegraph
node.exe or node
lib/package.json
lib/dist/index.js
lib/dist/bin/codegraph.js
~~~

For the current platform, create an archive, compute its real size/SHA-256, and write a disposable
lock that names those exact values. Add cases that prove:

1. exact platform selection;
2. offline `-ArtifactPath` success without network;
3. missing artifact failure leaves no final cache/receipt;
4. one-byte digest mismatch leaves no final cache/receipt;
5. size mismatch fails even when the test lock carries a different digest;
6. absolute, `..`, drive-qualified, and escaping link archive entries are rejected;
7. more than one top-level directory is rejected;
8. missing launcher, Node, package, library entry, or CLI entry is rejected;
9. a non-`1.5.0` version probe is rejected;
10. matching published cache is reused without rewriting its receipt timestamp;
11. same-version cache conflict is refused rather than overwritten;
12. dry-run provisioning and dry-run cleanup are byte-for-byte inert;
13. cleanup rejects user profile, cache parent, worktree root, symlink/reparse target, and a
    confirmation mismatch; and
14. exact confirmed cleanup removes only the named managed version or `.codegraph` directory.

Use a task-specific temporary prefix and verify the resolved parent before every recursive test
cleanup, following the existing Topic 03/04 safety pattern.

- [x] **Step 2: Run the expanded tests and observe the failure**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-provisioning.Tests.ps1
~~~

Expected: failures name missing `topic05-codegraph.ps1`, provision entry point, and cleanup entry
point. No test may access GitHub.

- [x] **Step 3: Implement closed parsing and platform selection**

In `scripts/lib/topic05-codegraph.ps1`, implement these public functions and keep helpers private
by `Topic05` prefix:

~~~powershell
function Read-Topic05CodeGraphLock {
    param([Parameter(Mandatory)][string]$LiteralPath)
}

function Get-Topic05CodeGraphPlatform {
    param()
}

function Get-Topic05CodeGraphManagedCacheRoot {
    param([string]$UserProfilePath = [Environment]::GetFolderPath('UserProfile'))
}

function Install-Topic05CodeGraphBundle {
    param(
        [Parameter(Mandatory)][string]$LockPath,
        [Parameter(Mandatory)][string]$CacheRoot,
        [string]$ArtifactPath,
        [switch]$AllowNetwork
    )
}

~~~

Use `RuntimeInformation.OSArchitecture` and `RuntimeInformation.IsOSPlatform`; never infer ARM64
as x64. Unknown OS/architecture returns `unsupported_platform`.

- [x] **Step 4: Implement safe acquisition and extraction**

The provisioner must:

1. derive the artifact URL from the locked origin and name;
2. require explicit `-AllowNetwork` when `-ArtifactPath` is absent;
3. download into a unique cache-root sibling staging directory;
4. enforce HTTPS and the allowed final-host set;
5. validate length and SHA-256 before extraction;
6. enumerate all ZIP/TAR entries before writing;
7. normalize `/`, reject rooted/drive/empty/`.`/`..` paths, and validate relative symlink targets
   remain inside the staging root;
8. extract with no overwrite into an empty staging directory;
9. strip exactly one expected top-level directory;
10. hash every extracted file in ordinal relative-path order and record a deterministic tree hash;
11. run the absolute vendored Node executable with the absolute
    `lib/dist/bin/codegraph.js --version` entry, telemetry/update disabled, and a 10-second limit;
12. write `receipt.json` last; and
13. publish by an atomic same-volume directory rename.

Never use `Invoke-Expression`, a shell command string, upstream install scripts, or `PATH`.

- [x] **Step 5: Implement the PowerShell 7.4 provision entry point**

`scripts/provision-codegraph.ps1` uses:

~~~powershell
#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$LockPath,
    [string]$CacheRoot,
    [string]$ArtifactPath,
    [switch]$AllowNetwork,
    [switch]$Apply
)
~~~

Without `-Apply`, emit a closed JSON plan and perform no download, extraction, cache creation, or
receipt write. Resolve default lock/cache paths only after validating they are non-empty. With
`-Apply`, emit one compact JSON receipt to stdout and one sanitized diagnostic line to stderr on
failure. Exit 0 on success, 2 on invalid input, 3 on integrity/conflict refusal, and 4 on
unavailable environment/network.

- [x] **Step 6: Implement dry-run-first cleanup**

`scripts/cleanup-codegraph.ps1` supports two mutually exclusive modes:

~~~powershell
param(
    [ValidateSet('bundle','index')][string]$Kind,
    [Parameter(Mandatory)][string]$LiteralPath,
    [Parameter(Mandatory)][string]$Confirmation,
    [switch]$Apply
)
~~~

For a bundle, `Confirmation` must equal `v1.5.0:<platform>:<artifact-sha256>` from its valid
receipt and the target must equal the selected version/platform directory beneath
`<user-profile>/.omp/cache/codegraph`. For an index, it must equal the canonical absolute
worktree root; the target must equal `<that-root>/.codegraph`, be a real directory rather than a
link, and the worktree itself is never removed. Preview enumerates exact files/bytes. Apply moves
the exact directory to a sibling recoverable trash name; it does not permanently purge.

- [x] **Step 7: Make all deterministic provisioning/cleanup tests pass**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-provisioning.Tests.ps1
~~~

Expected: all lock/platform/archive/transaction/reuse/conflict/cleanup cases pass, with zero
network calls and no leftover test roots.

- [x] **Step 8: Verify Windows PowerShell parses the installer-facing library contract**

~~~powershell
powershell -NoProfile -Command {
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'scripts/lib/topic05-codegraph.ps1'), [ref]$null, [ref]$null
    )
}
~~~

Expected: parse succeeds. Runtime provisioning still requires `pwsh` 7.4+; parse compatibility is
for the existing installer entry boundary only.

- [x] **Step 9: Record a no-Git checkpoint**

~~~powershell
git diff --check -- scripts/lib/topic05-codegraph.ps1 scripts/provision-codegraph.ps1 scripts/cleanup-codegraph.ps1 scripts/tests/topic05-provisioning.Tests.ps1
git status --short -- scripts/lib/topic05-codegraph.ps1 scripts/provision-codegraph.ps1 scripts/cleanup-codegraph.ps1 scripts/tests/topic05-provisioning.Tests.ps1
~~~

Expected: only intended paths and no whitespace error. Do not stage or commit.

---

### Task 3: Implement the safe lazy index and Topic 04-bound retrieval transaction

**Files:**
- Create: `template/.omp/codegraph/safe-init.mjs`
- Create: `template/.omp/codegraph/codegraph-process.ps1`
- Create: `scripts/tests/fixtures/topic05/fake-codegraph.mjs`
- Create: `scripts/tests/topic05-adapter.Tests.ps1`

**Interfaces:**
- `safe-init.mjs --bundle-root <absolute> --project-root <absolute>` outputs one JSON result and
  writes only `<project-root>/.codegraph/**`.
- `codegraph-process.ps1 -Operation retrieve -RuntimePath <absolute> -WorkingDirectory <pi.cwd>
  -QuestionBase64 <base64url> -MaxFiles <1..12>` outputs the closed adapter envelope.
- The wrapper reads Topic 04 authority; it never mutates task state, candidate state, Git hooks,
  source files, or `codegraph.json`.

- [x] **Step 1: Write a stateful fake CodeGraph executable**

`scripts/tests/fixtures/topic05/fake-codegraph.mjs` reads behavior only from a fixture file whose
absolute path the test places in a fixed test-only environment variable. It implements exactly:

~~~text
--version
sync <root> --quiet
status <root> --json
explore --path <root> --max-files <n> -- <question>
~~~

It records argv/cwd and the allowed environment flags to a test-owned log. Closed fixture modes
cover healthy, uninitialized, version mismatch, worktree mismatch, partial, indexing, failed,
reindex recommended, pending refs, pending changes, empty graph result, nonzero exit, timeout,
stdout overflow, stderr overflow, and source mutation during explore. The fake must not interpret
shell metacharacters in the question.

- [x] **Step 2: Add failing safe-init and retrieval-transaction tests**

Add cases for:

1. safe init imports only the bundle root passed by the wrapper;
2. fake `CodeGraph.init(..., {index:false})`, `indexAll()`, and `destroy()` are called in order;
3. safe init creates only `.codegraph/**`, never `.git/hooks`, `codegraph.json`, `.omp`, or source;
4. a failed/throwing `indexAll()` is nonzero and leaves no success result;
5. canonical main-worktree observation mode;
6. two linked worktrees resolve separate index paths and lock hashes; concurrent wait/success,
   bounded busy, exact stale-process recovery, PID reuse, malformed metadata, and replaced-lock
   ownership follow the closed lock contract;
7. one matching active Topic 04 task binds its task/candidate identity;
8. zero active matches uses observation mode;
9. two matching active tasks return `state_binding_ambiguous`;
10. task mode without `.codegraph/.gitignore` ownership returns `state_cache_not_owned`;
11. a frozen candidate without an existing index returns `candidate_index_missing` before write;
12. a frozen valid candidate with a healthy existing index may query;
13. candidate drift before or during retrieval returns `candidate_drift` and no graph text;
14. source mutation during retrieval returns `source_changed` and no graph text;
15. each unhealthy status maps to its exact closed reason;
16. version/artifact/runtime receipt mismatch refuses before CodeGraph query;
17. every timeout, stdout overflow, and stderr overflow kills descendants and maps to exact
    reasons; AbortSignal cancellation belongs to the model-facing process owner and is tested in
    Task 4 rather than simulated through a PowerShell-only parameter;
18. valid question metacharacters/leading dashes/quotes/newlines arrive after `--` as one literal
    `explore` argument, while noncanonical base64url, malformed UTF-8, U+0000, or more than 1,024
    code points is rejected before CodeGraph starts;
19. inherited `CODEGRAPH_*`, `NODE_OPTIONS`, and `NODE_PATH` do not reach the fake; and
20. no raw stderr, environment value, or full command appears in the returned envelope.

- [x] **Step 3: Run the adapter tests and observe the intended failure**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-adapter.Tests.ps1
~~~

Expected: nonzero because `safe-init.mjs` and `codegraph-process.ps1` do not exist.

- [x] **Step 4: Implement safe library-level initialization**

`safe-init.mjs` must use Node built-ins only for argument parsing/path confinement, then import the
bundle's exact `lib/dist/index.js` through `pathToFileURL`. Its core is:

~~~javascript
const moduleUrl = pathToFileURL(path.join(bundleRoot, "lib", "dist", "index.js")).href;
const { default: CodeGraph } = await import(moduleUrl);
const graph = await CodeGraph.init(projectRoot, { index: false });
try {
  const result = await graph.indexAll();
  if (!result?.success) throw new Error("index_result_failed");
  process.stdout.write(JSON.stringify({
    schema_version: 1,
    ok: true,
    files_indexed: result.filesIndexed,
    files_errored: result.filesErrored,
    nodes_created: result.nodesCreated,
    edges_created: result.edgesCreated,
    duration_ms: result.durationMs
  }) + "\n");
} finally {
  graph.destroy();
}
~~~

Before import, resolve real paths and require the library beneath the reconciled bundle root and
the project beneath the canonical worktree. Capture Git hooks, `codegraph.json`, and source
snapshot before/after; any non-cache change fails. Do not add a repair/delete branch.

- [x] **Step 5: Implement Topic 04 read-only binding**

In `codegraph-process.ps1`, dot-source the installed sibling state modules in this order:

~~~powershell
AgentTasks.Common.ps1
AgentTasks.Store.ps1
AgentTasks.Git.ps1
AgentTasks.Lifecycle.ps1
AgentTasks.Candidate.ps1
AgentTasks.Transfer.ps1
~~~

Use `Resolve-AgentTasksContext`, `Get-AgentTasksActiveTaskAuthorities`,
`Get-AgentTasksTaskAuthority`, `Get-AgentTasksWorkspaceSnapshot`,
`Get-AgentTasksTransferWorkspaceHash`, and `Test-AgentTasksCandidateCurrentUnlocked`. Do not call
the mutating public `check` operation. Build a normalized workspace hash by removing only
`.codegraph/.gitignore`, `captured_at`, and `record_hash` from the projection before canonical
hashing. Every other changed path participates.

- [x] **Step 6: Implement supervised fixed-operation execution**

Create one private function:

~~~powershell
function Invoke-Topic05CodeGraphProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][int]$TimeoutMs,
        [Parameter(Mandatory)][int]$StdoutLimitBytes,
        [Parameter(Mandatory)][int]$StderrLimitBytes
    )
}
~~~

Use `ProcessStartInfo.ArgumentList`, not `.Arguments`. Close stdin immediately. Read stdout/stderr
incrementally as UTF-8 bytes; on overflow, cancellation, or timeout call `Kill($true)`, wait for
exit, and discard the captured graph payload. Build the child environment from a filtered copy and
the exact fixed variables in the runtime contract.

- [x] **Step 7: Implement the single locked retrieval sequence and health predicate**

Keep the sequence in one exported operation so the cache lock spans init, sync, status, explore,
and post-check. Parse `status --json` as a closed projection and compare paths with OS-correct path
semantics. `index.state == null` is unhealthy, even if older CodeGraph versions once tolerated it.
`filesErrored` from initialization is recorded as `initial_files_errored` plus the
`initial_files_errored` gap signal. It does not make a structurally healthy query fail, because
useful graph evidence may remain, but the Scout/Lead must apply native reconciliation; the status
command cannot reconstruct historical parse-error counts for an existing index.

Return failure envelopes rather than throwing past the wrapper boundary. The custom tool needs a
stable reason to select native fallback.

- [x] **Step 8: Make the full fake-runtime/state/worktree matrix pass**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-adapter.Tests.ps1
~~~

Expected: all twenty behavior groups pass. Tests must confirm separate `.codegraph` paths for
linked worktrees and zero project/state mutation outside disposable cache bytes.

- [x] **Step 9: Re-run Topic 04 regressions**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-transfer.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
~~~

Expected: zero failures. Topic 05 consumes Topic 04 internals read-only and must not change its
public protocol or manifest.

- [x] **Step 10: Record a no-Git checkpoint**

~~~powershell
git diff --check -- template/.omp/codegraph scripts/tests/fixtures/topic05 scripts/tests/topic05-adapter.Tests.ps1
git status --short -- template/.omp/codegraph scripts/tests/fixtures/topic05 scripts/tests/topic05-adapter.Tests.ps1
~~~

Expected: only intended paths and no whitespace errors. Do not stage or commit.

---

## File Structure and Ownership

### Optional installed component

- Create: `template/.omp/tools/codegraph-retrieve.js` — the only model-callable adapter. The
  executable extension is `.js` because pinned OMP project discovery scans `.js`/`.ts` but not
  `.mjs`; the live RPC RED fixture caught this before closure.
- Create: `template/.omp/codegraph/codegraph-process.ps1` — closed retrieval transaction,
  worktree/state reconciliation, process supervision, status validation, and output envelope.
- Create: `template/.omp/codegraph/safe-init.mjs` — noninteractive library-level initialization;
  no installer, MCP, daemon, prompt, or hook path.
- Create: `template/.omp/codegraph/upstream-lock.json` — immutable upstream release/platform pin.
- Create: `template/.omp/codegraph/component-manifest.json` — exact installed source file hashes
  and compatibility requirements. The manifest does not hash itself.
- Create: `template/.omp/codegraph/COMPONENT.md` — installed operator contract and failure codes.
- Create: `template/.omp/codegraph/CODEGRAPH-LICENSE.txt` — byte-exact upstream MIT notice from
  the pinned commit.
- Generated only in an installed target: `.omp/codegraph/runtime.json` — reconciled absolute
  managed-bundle path and receipt identity. It is never checked into `template/`.
- Generated only in an installed target: `.omp/codegraph/install-record.json` — exact installed
  paths, backup reference, retained-cache policy, and rollback metadata.

The installer treats `codegraph` as one special multi-root component: its source spans
`template/.omp/tools/codegraph-retrieve.js` and `template/.omp/codegraph/**`. Selecting `agents`
or any default component must not copy the tool.

### Provisioning, cleanup, and installer integration

- Create: `scripts/lib/topic05-codegraph.ps1` — platform selection, closed manifest parsing,
  safe archive extraction, digest verification, managed-cache receipt, and target runtime record.
- Create: `scripts/provision-codegraph.ps1` — PowerShell 7.4 CLI wrapper for deterministic/offline
  provisioning and the explicit network-enabled path.
- Create: `scripts/cleanup-codegraph.ps1` — dry-run-first exact-target cleanup for a managed bundle
  or one explicitly named worktree index.
- Modify: `scripts/install-template.ps1` — optional component dependency, dry-run plan,
  transactional activation, generated records, and no default enablement.
- Modify: `scripts/uninstall-template.ps1` — preserve/report managed bundle and index paths while
  normal backup rollback removes installed adapter/config files.

### Tests and focused validation

- Create: `scripts/tests/fixtures/topic05/fake-codegraph.mjs` — stateful fake CLI for deterministic
  version/status/sync/explore failures and health states.
- Create: `scripts/tests/topic05-provisioning.Tests.ps1`.
- Create: `scripts/tests/topic05-adapter.Tests.ps1`.
- Create: `scripts/tests/topic05-tool.Tests.mjs`.
- Create: `scripts/tests/topic05-installer.Tests.ps1`.
- Create: `scripts/tests/topic05-routing.Tests.ps1`.
- Create: `scripts/tests/topic05-benchmark.Tests.ps1`.
- Create: `scripts/tests/topic05-progressive-retrieval.Tests.ps1` — mutation tests for the focused
  authority validator.
- Create: `scripts/lib/topic05-progressive-retrieval.ps1` — PowerShell 5.1-compatible focused
  validator helper.
- Create: `scripts/validate-topic05-progressive-retrieval.ps1`.
- Modify: `scripts/validate-template.ps1` — call the focused helper and require the new source
  files, while never requiring generated target-local runtime records.

### Agent and workflow projection

- Modify: `template/.omp/agents/cheap-scout.md` — compact retrieval packet, capability choice,
  raw-payload boundary, and native fallback.
- Modify: `template/.omp/agents/reviewer.md` — independent source fitness/retrieval and graph
  fallback without weakening review.
- Modify: `template/.omp/AGENTS.md` — short persistent actor/capability selection and critical
  corroboration rule.
- Modify: `template/.omp/commands/quick.md`.
- Modify: `template/.omp/commands/standard.md`.
- Modify: `template/.omp/commands/orchestrated.md`.

No `bash` is added to Cheap Scout, no CodeGraph MCP server is configured, and no new permanent
agent role is created.

### Benchmark and evidence

- Create: `scripts/lib/topic05-benchmark.ps1` — fixture materialization, arm planning,
  contamination checks, sanitized OMP event parsing, quality/usage accounting, and run-record
  validation.
- Create: `scripts/run-topic05-retrieval-benchmark.ps1` — dry plan, deterministic run, or explicitly
  authorized model pilot.
- Create: `evals/retrieval/topic05/fixtures.json` — nine closed fixture classes and deterministic
  oracles.
- Create: `evals/retrieval/topic05/README.md` — arm contract and manual/operator instructions.
- Create: `docs/evidence/current-product/topic-05/deterministic.json` — fresh local adapter/index
  results with no model call.
- Create: `docs/evidence/current-product/topic-05/model-campaign.json` — truthful `NOT_RUN`,
  `ENVIRONMENT_BLOCKED`, or completed pilot disposition; never an inferred PASS.
- Create: `docs/evidence/current-product/topic-05/manifest.json` — exact current Topic 05 file and
  evidence hashes.

### Canonical authority and human documentation

- Append: `spec/key/04-decision-log.md` as KD-029.
- Modify: `spec/key/01-dna.md`, `spec/key/03-token-quality-model.md`.
- Modify: `spec/03-agent-topology.md`, `spec/05-context-and-token-model.md`,
  `spec/07-retrieval-and-code-understanding.md`, `spec/12-installation-and-rollback.md`,
  `spec/13-validation-and-evaluation.md`, `spec/14-upgradeability-and-governance.md`,
  `spec/15-security-and-failure-recovery.md`, and `spec/README.md`.
- Modify: `spec/phases/phase-03-context-efficiency.md`,
  `spec/phases/phase-05-installation-hardening.md`, and `spec/phases/phase-06-evaluation.md`.
- Modify: `registry/upstreams.yml`, `registry/adoption-ledger.yml`, and
  `registry/rejected-mechanisms.yml`.
- Create: `docs/retrieval.md`.
- Modify: `README.md`, `CHANGELOG.md`, `docs/architecture.md`, `docs/installation.md`,
  `docs/customization.md`, `docs/token-strategy.md`, `docs/security.md`, `docs/rollback.md`,
  `docs/workflow-v0.md`, and `docs/policies/context-budget.md`.
- Modify after implementation evidence exists:
  `docs/superpowers/specs/2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-design.md`.
- Create: `codex-topic05-progressive-retrieval-codegraph-changelog.md`.

Historical research and Phase 00 evidence are not silently rewritten. If an active summary makes a
contradictory current claim, correct or fence that summary; otherwise leave historical bytes alone.

---

## Closed Runtime Contracts

### Upstream release lock

`template/.omp/codegraph/upstream-lock.json` is a closed JSON document with this identity:

~~~json
{
  "schema_version": 1,
  "upstream": "colbymchenry/codegraph",
  "release_url": "https://github.com/colbymchenry/codegraph/releases/tag/v1.5.0",
  "version": "1.5.0",
  "tag": "v1.5.0",
  "commit": "ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6",
  "license": "MIT",
  "license_file": {
    "repository_path": "LICENSE",
    "sha256": "e6d98f98c666bebe065ac2492a0a19232cc318d4d67bac3ca42ffb77bacc8809"
  },
  "download_origin": "https://github.com/colbymchenry/codegraph/releases/download/v1.5.0/",
  "allowed_final_hosts": [
    "github.com",
    "release-assets.githubusercontent.com"
  ],
  "checksum_asset": {
    "name": "SHA256SUMS",
    "sha256": "434166207a163b5fe40f0052df5ea20be1e4ba56d7b4eaa00795cc75c8c0f3ed"
  },
  "artifacts": [
    {
      "platform": "darwin-arm64",
      "name": "codegraph-darwin-arm64.tar.gz",
      "size": 56627196,
      "sha256": "cf5ee435a6e44d097b2f98f2b7b8b9422bb1094844404efed82519c5da1af2cf"
    },
    {
      "platform": "darwin-x64",
      "name": "codegraph-darwin-x64.tar.gz",
      "size": 57729407,
      "sha256": "0a0ccc29bf7da9d10be1458d89d7e15c55927ae24cd95e9fa3de4bdfea059dde"
    },
    {
      "platform": "linux-arm64",
      "name": "codegraph-linux-arm64.tar.gz",
      "size": 61327175,
      "sha256": "9f17750aedf45d51f68caae39ed21d6e2a7290b2326e5c53f95a165918ebd1d8"
    },
    {
      "platform": "linux-x64",
      "name": "codegraph-linux-x64.tar.gz",
      "size": 61744667,
      "sha256": "2ba65e87a1210b706bb1e67d5e48b5fc4a1935e43dbb3fb5f31c5597840d2e58"
    },
    {
      "platform": "win32-arm64",
      "name": "codegraph-win32-arm64.zip",
      "size": 48389210,
      "sha256": "de125e792b5eed7dee8def2ab9bd7e762f372012f75f595e59d3b0c8714b0d55"
    },
    {
      "platform": "win32-x64",
      "name": "codegraph-win32-x64.zip",
      "size": 52398062,
      "sha256": "d6798622b4f44ee6757c94335f437ee27a9ff7d3537b554cb6a2b3baf11bc4a1"
    }
  ]
}
~~~

Every download URL is derived as
`https://github.com/colbymchenry/codegraph/releases/download/v1.5.0/<artifact-name>` from the
closed lock. No redirect may change the final host away from `github.com` or
`release-assets.githubusercontent.com`.

### Managed bundle and target records

The managed cache root is
`<user-profile>/.omp/cache/codegraph/v1.5.0/<platform>/`. Provisioning first builds a sibling
staging directory, verifies the archive, validates every archive entry, extracts exactly one
top-level `codegraph-<platform>` directory, checks required bundle files, probes `--version`, then
publishes the final directory atomically. It writes `receipt.json` last.

`receipt.json` contains only closed fields: schema version, upstream/version/tag/commit/platform,
artifact name/size/SHA-256, required runtime-file hashes, deterministic bundle-tree hash,
provisioned timestamp, final canonical bundle/receipt paths, and executable/library relative paths.
Reuse requires every identity field, canonical path, and required runtime-file hash to match. A
conflicting same-version cache is not overwritten.

The exact receipt shape is:

~~~json
{
  "schema_version": 1,
  "record_type": "codegraph_bundle_receipt",
  "upstream": "colbymchenry/codegraph",
  "version": "1.5.0",
  "tag": "v1.5.0",
  "commit": "ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6",
  "platform": "win32-x64",
  "bundle_root": "canonical absolute managed version/platform directory",
  "receipt_path": "canonical absolute bundle_root/receipt.json",
  "artifact": {
    "name": "codegraph-win32-x64.zip",
    "size": 52398062,
    "sha256": "d6798622b4f44ee6757c94335f437ee27a9ff7d3537b554cb6a2b3baf11bc4a1"
  },
  "required_files": {
    "launcher": { "path": "bin/codegraph.cmd", "sha256": "64 lowercase hex" },
    "node": { "path": "node.exe", "sha256": "64 lowercase hex" },
    "package": { "path": "lib/package.json", "sha256": "64 lowercase hex" },
    "library_entry": { "path": "lib/dist/index.js", "sha256": "64 lowercase hex" },
    "cli_entry": { "path": "lib/dist/bin/codegraph.js", "sha256": "64 lowercase hex" }
  },
  "bundle_tree_sha256": "64 lowercase hex",
  "provisioned_at_utc": "RFC 3339 UTC"
}
~~~

The platform/artifact/path values vary only by the selected locked row. The tree hash covers every
extracted bundle file in ordinal project-relative-path order and excludes the subsequently written
`receipt.json`. The quoted hash/time strings above describe validated formats, not literal values
to copy into a receipt.

The installed target's `.omp/codegraph/runtime.json` contains the same immutable upstream and
artifact identity plus absolute, path-confined locations for:

- the managed bundle root;
- `receipt.json`;
- the launcher (`bin/codegraph.cmd` on Windows, `bin/codegraph` otherwise);
- the vendored Node runtime (`node.exe` or `node`);
- `lib/dist/index.js` and `lib/dist/bin/codegraph.js`;
- the installed `safe-init.mjs` and `codegraph-process.ps1`; and
- the selected PowerShell 7.4+ executable.

The launcher is retained and hashed as upstream bundle identity, but the adapter never executes a
`.cmd` or shell script. Every CodeGraph CLI operation uses the absolute vendored Node executable
with the absolute `lib/dist/bin/codegraph.js` entry. No `PATH` lookup is used after provisioning.

`component-manifest.json` has the closed fields `schema_version`, `record_type`, `component`,
`component_version`, `minimum_pwsh_version`, `requires`, `upstream_lock`, `files`, and
`generated_target_files`. `requires` contains exactly one `state` row pinned to state manifest
schema `1`, record type `agent_tasks_component_manifest`, and SHA-256
`9df1af64a18b3f9003c61112d8709b864a9bb249d88d27a72af7dab8d24bf7b3` for
`template/.omp/state/manifest.json`; any intervening state change must be reviewed and intentionally
re-pinned before Task 6. `upstream_lock`
contains its project-relative path, SHA-256, version, tag, and commit. `files` is the sorted six-row
path/hash list from Task 6. `generated_target_files` is exactly
`.omp/codegraph/runtime.json` and `.omp/codegraph/install-record.json`.

The installed target's `runtime.json` is closed to these fields:

~~~text
schema_version, record_type, component, component_version, created_at_utc,
target_omp, component_manifest_sha256, upstream_lock_sha256, receipt_sha256,
upstream, version, tag, commit, platform, artifact_sha256,
paths.bundle_root, paths.receipt, paths.launcher, paths.node,
paths.library_entry, paths.cli_entry, paths.safe_init,
paths.process_wrapper, paths.pwsh
~~~

`record_type` is `codegraph_target_runtime`. Every `paths.*` value is absolute and reconciled
against either the managed receipt root or the adapter's installed `.omp` root before use.

The installed target's `install-record.json` is closed to:

~~~text
schema_version, record_type, component, installed_at_utc, target_omp,
backup_dir, component_manifest_sha256, upstream_lock_sha256,
runtime_sha256, bundle_root, receipt_path, installed_paths,
known_index_paths, retained_cache_policy
~~~

`record_type` is `codegraph_install_record`; `installed_paths` is a sorted exact list of copied and
generated target-relative files; `known_index_paths` is empty for user installs and contains only
the canonical project `.codegraph` path when it can be derived safely. `retained_cache_policy` is
the literal `retain_and_report`; the uninstaller must match the record's canonical `target_omp` and
`backup_dir` to its actual arguments before trusting those paths.

### Model-facing tool input

~~~javascript
{
  question: string, // well-formed NFC, trimmed, no U+0000, 1..1024 Unicode code points
  max_files?: number // integer; default 6; clamped to 1..12
}
~~~

The tool is declared as:

~~~javascript
{
  name: "codegraph_retrieve",
  label: "CodeGraph Retrieve",
  loadMode: "discoverable",
  approval: "exec",
  strict: true
}
~~~

It exposes no operation/path/runtime/env fields. The default export is the OMP custom-tool factory;
named pure helpers may be exported only for deterministic tests.

### Retrieval transaction

One invocation of `codegraph-process.ps1 -Operation retrieve` owns the entire per-worktree lock and
performs this exact order:

1. Parse the installed runtime record as a closed object and reconcile it with the upstream lock,
   component manifest, managed receipt, required runtime file hashes, and `codegraph --version`.
2. Resolve `pi.cwd` through Topic 04's `Resolve-AgentTasksContext`; require a canonical Git
   worktree, real directories, and no symlink/reparse escape at `.codegraph`.
3. Enumerate active Topic 04 task authorities internally and bind only when exactly one task's
   observation/authoritative worktree equals the canonical root. Zero matches is observation
   mode; multiple matches returns `state_binding_ambiguous`.
4. For task mode, require `.codegraph/.gitignore` in `owned_ignored_outputs`. If a selected frozen
   candidate exists, validate it without mutating task state and refuse lazy initialization when
   the stable cache marker/index was not already present at candidate freeze.
5. Capture the normalized Topic 04 workspace snapshot and candidate identity. Normalization may
   remove only `.codegraph/.gitignore`; ignored database/runtime bytes are absent from Git status.
6. If the index is absent and initialization is permitted, call the installed `safe-init.mjs`
   with the vendored Node runtime. The helper imports the pinned `lib/dist/index.js`, calls
   `CodeGraph.init(root, { index: false })`, then `indexAll()`, checks its result, destroys the
   instance, and writes no path outside `.codegraph/`.
7. Run fixed CLI `sync <canonical-root> --quiet`.
8. Run fixed CLI `status <canonical-root> --json` and require exact version, initialized true,
   canonical `projectPath`, index path `<root>/.codegraph`, null `worktreeMismatch`, index state
   `complete`, `reindexRecommended == false`, `pendingRefs == 0`, and zero added/modified/removed
   pending changes.
9. Run fixed CLI
   `explore --path <canonical-root> --max-files <bounded-value> -- <question>`. The explicit
   end-of-options marker keeps a question beginning with `-` from becoming a CLI option.
10. Repeat status and Topic 04 workspace/candidate observation. Any mismatch rejects the payload as
    stale; no partial graph text survives as usable evidence.
11. Return one bounded JSON envelope. The custom tool renders one text payload plus machine-readable
    details; it never persists a duplicate raw artifact.

The per-worktree lock lives under the managed cache at `locks/<sha256(canonical-root)>.lock`, not
inside source or `.codegraph`. A second retrieval waits at most 15 seconds, then returns
`index_busy`. The model-facing tool's outer process timeout is 600 seconds, leaving time for that
lock wait, wrapper startup, cleanup, and its own final failure envelope beyond the sum of inner
operation limits.

Acquire the lock with an exclusive `FileMode.CreateNew` file containing schema version, canonical
root hash, PID, process start time, and creation time. Retry with bounded jitter while the recorded
PID/start-time pair is alive. Reclaim only when that exact process identity is absent; malformed
lock metadata is not deleted automatically and returns `index_busy`. Release the owned lock in
`finally` only after verifying its content still matches the current process identity. Tests cover
concurrent wait/success, bounded busy, crash-stale recovery, PID reuse, malformed metadata, and a
lock file replaced while the operation is running.

### Process limits and environment

The wrapper uses `System.Diagnostics.ProcessStartInfo` with `UseShellExecute = false`, closed stdin,
argument-list entries, streamed byte counting, and `Process.Kill(true)` on cancellation, timeout,
or output overflow. Exact limits are:

| Operation | Timeout | stdout | stderr |
|---|---:|---:|---:|
| version/status | 10 seconds | 64 KiB | 8 KiB |
| safe init | 300 seconds | 64 KiB | 8 KiB |
| sync | 120 seconds | 64 KiB | 8 KiB |
| explore | 60 seconds | 64 KiB | 8 KiB |

Any truncation makes that operation fail; truncated graph text is never returned as completed.
After JSON parsing, `data.text` must also be at most 32 KiB of UTF-8. A larger payload returns
`output_truncated` rather than clipping text into a plausible but incomplete answer.
The child environment removes inherited `CODEGRAPH_*`, `NODE_OPTIONS`, and `NODE_PATH`, then sets:

~~~text
CODEGRAPH_DIR=.codegraph
CODEGRAPH_TELEMETRY=0
CODEGRAPH_NO_UPDATE_CHECK=1
CODEGRAPH_NO_DAEMON=1
DO_NOT_TRACK=1
CI=1
NO_COLOR=1
~~~

`CODEGRAPH_NO_WATCH` is deliberately not set because upstream uses that condition to offer a Git
hook fallback in the interactive CLI path. Safe initialization bypasses that CLI path entirely.

### Adapter result and reason codes

The PowerShell helper returns one JSON document:

~~~json
{
  "schema_version": 1,
  "ok": true,
  "status": "completed",
  "reason_code": "ok",
  "fallback": null,
  "data": {
    "text": "bounded CodeGraph explore output",
    "binding": {
      "mode": "observation",
      "worktree_root": "D:/canonical/worktree",
      "workspace_snapshot_sha256": "sha256",
      "task_id": null,
      "candidate_id": null,
      "candidate_hash": null
    },
    "codegraph": {
      "version": "1.5.0",
      "index_path": "D:/canonical/worktree/.codegraph",
      "index_state": "complete",
      "synced": true,
      "lazy_initialized": true,
      "initial_files_errored": 0,
      "gap_signals": []
    },
    "metrics": {
      "init_ms": 0,
      "sync_ms": 0,
      "query_ms": 0,
      "output_bytes": 0
    }
  }
}
~~~

`status` is `completed | partial | blocked | failed`. `fallback` is `native` on every non-completed
capability result. The closed non-success reason set is:

~~~text
component_uninstalled
runtime_manifest_invalid
unsupported_platform
artifact_identity_mismatch
executable_missing
version_mismatch
state_component_missing
state_binding_ambiguous
state_cache_not_owned
candidate_index_missing
candidate_drift
worktree_mismatch
index_busy
index_missing
index_init_failed
index_sync_failed
index_unhealthy
index_partial
index_pending_refs
query_failed
graph_gap
output_truncated
timeout
cancelled
source_changed
internal_error
~~~

Map reasons deterministically:

- `partial`: `index_partial`, `index_pending_refs`, `graph_gap`;
- `blocked`: `component_uninstalled`, `unsupported_platform`, `state_component_missing`,
  `state_binding_ambiguous`, `state_cache_not_owned`, `candidate_index_missing`, `index_busy`,
  `index_missing`, `cancelled`; and
- `failed`: every remaining non-success reason.

Only `reason_code: ok` may set `ok: true`, `status: completed`, `fallback: null`, and non-null
`data`. Every other reason sets `ok: false`, `fallback: native`, and `data: null`; graph payload is
discarded even when the status is `partial`. Timestamps, local diagnostic hashes, and exception
messages are not part of this envelope.

Raw stderr, environment contents, credentials, and full process commands are never returned. A
sanitized diagnostic code and SHA-256 may be logged locally for debugging.

### Cheap Scout retrieval packet

Until Topic 06 wraps it in the common result envelope, `cheap-scout.md` returns the approved
retrieval overlay directly with one additional compact `summary` field. Required fields are:

~~~yaml
status: completed | partial | blocked | failed
summary: string
question: string
actor: cheap_scout
capability: native | codegraph | mixed
source_fitness_reason: string
fallback_path: [string]
binding:
  worktree_root: string
  task_id: string | null
  candidate_id: string | null
  candidate_hash: sha256 | null
codegraph:
  used: boolean
  version: string | null
  index_path: string | null
  index_state: string | null
  synced: boolean | null
  initial_files_errored: integer | null
  gap_signals: [string]
claims:
  - claim_id: string
    statement: string
    evidence_kind: direct_source | resolved_edge | heuristic_edge | inference
    sources: [project-relative-file:line]
    critical: boolean
    uncertainty: string | null
gaps: [string]
searches_performed: [string]
recommended_next_action: string
~~~

The closed output-schema frontmatter makes this shape exact. JSON Schema is used here because the
pinned OMP JTD converter does not preserve RFC 8927 `nullable`; required nullable binding/index
fields would otherwise become falsely non-nullable or unconstrained. A `completed` answer still
cannot make an uncorroborated absence claim or satisfy acceptance by itself.

---

### Task 4: Expose one capability-narrow OMP tool and prove token-free discovery

**Files:**
- Create: `template/.omp/tools/codegraph-retrieve.js`
- Create: `scripts/tests/topic05-tool.Tests.mjs`

**Interfaces:**
- OMP tool name: `codegraph_retrieve`.
- Model input: `{ question: string, max_files?: integer }`; no additional properties.
- Model output: one short text content item plus the closed adapter envelope in `details`.
- Process boundary: one absolute `pwsh` executable and one installed sibling
  `codegraph-process.ps1`; no shell interpolation and no model-selected path.

- [x] **Step 1: Write failing schema, normalization, invocation, cancellation, and redaction tests**

Use Node's native test runner and a fake `pi` object. Import the tool factory from a disposable
installed tree containing a valid fake `runtime.json`. Assert all of the following:

1. the factory exposes exactly `name: "codegraph_retrieve"`, `loadMode: "discoverable"`,
   `approval: "exec"`, and `strict: true`;
2. `question` is required, well-formed Unicode, normalized to NFC, trimmed, non-empty, contains no
   U+0000, and is at most 1,024 Unicode code points;
3. `max_files` defaults to `6`, clamps to `1..12`, and rejects non-integers;
4. unknown fields, paths, commands, operation names, and environment values are rejected;
5. leading dashes, quotes, newlines, semicolons, pipes, `$()`, backticks, and non-ASCII text survive
   one base64url argument without reinterpretation; the tool never invokes the CLI directly, and
   the wrapper alone places `--` before the decoded question;
6. the runtime and wrapper paths are derived from `import.meta.url`, not `pi.cwd` or model input;
7. `pi.exec` receives an argument array, `cwd: pi.cwd`, the supplied abort signal, and a
   `600000` millisecond outer timeout;
8. exactly one JSON line is accepted; empty, duplicate, trailing, malformed, or oversized output
   becomes `internal_error`;
9. completed output is `isError: false`; every other status is `isError: true` and recommends
   native retrieval in one bounded sentence; and
10. stdout/stderr/process arguments never leak into the model-facing fallback text.

- [x] **Step 2: Run the tool tests and observe the intended failure**

~~~powershell
node --test scripts/tests/topic05-tool.Tests.mjs
~~~

Expected: nonzero because `codegraph-retrieve.js` does not exist.

- [x] **Step 3: Implement the thin tool factory**

Keep validation in pure exported helpers so the tests do not require OMP. The execute path must be
equivalent to this fixed call shape:

~~~javascript
const result = await pi.exec(runtime.paths.pwsh, [
  "-NoProfile",
  "-NonInteractive",
  "-File", wrapperPath,
  "-Operation", "retrieve",
  "-RuntimePath", runtimePath,
  "-WorkingDirectory", pi.cwd,
  "-QuestionBase64", encodeBase64Url(question),
  "-MaxFiles", String(maxFiles)
], {
  cwd: pi.cwd,
  signal,
  timeout: 600000
});
~~~

Do not pass a mutable environment from the tool. `runtime.json` must pass the closed shape, target
path confinement, component-manifest digest, receipt digest, platform, and CodeGraph version checks
before `pi.exec` is called. The PowerShell wrapper owns the filtered child environment.

- [x] **Step 4: Return a compact, stable model boundary**

For `completed`, render at most the bounded graph summary and cited source list already present in
the envelope. For `partial`, `blocked`, or `failed`, discard graph text and return:

~~~text
CodeGraph retrieval unavailable (<reason>); continue with native read/grep/glob retrieval.
~~~

Replace `<reason>` in implementation with the validated closed reason value; never echo an
exception message. Preserve the full sanitized envelope only in `details` for orchestration and
tests.

- [x] **Step 5: Make the Node tool suite pass**

~~~powershell
node --test scripts/tests/topic05-tool.Tests.mjs
~~~

Expected: all schema/invocation/cancellation/redaction cases pass with no child shell.

- [x] **Step 6: Add a token-free OMP discovery fixture**

In the same test file, start `omp --mode rpc` from the template target with stdin/stdout pipes, send
`get_state`, and assert the tool is either direct in `dumpTools` or listed as
`xd://codegraph_retrieve` in the generated prompt. A standalone `omp read xd://...` process does
not own the RPC session's `xd` mount, so do not treat it as a valid inspection path. Prove the
restricted/plan-child exclusion against the pinned constructor source: exercising an actual child
would require a model prompt and violate the token-free gate. Do not send a prompt, select a
provider, or create a model session.

- [x] **Step 7: Reproduce the pinned OMP loading contract**

Add source assertions against `_research/upstreams/oh-my-pi` at the pinned clean commit for:

- filesystem `.omp/tools` discovery;
- `loadMode: discoverable` handling;
- custom-tool removal in restricted/plan child sessions; and
- custom-tool auto-inclusion in ordinary child sessions even when absent from fixed agent
  frontmatter; and
- `pi.exec` argument-array/cancellation support and its pinned `ptree` descendant termination on
  abort/timeout.

Fail if the checkout is dirty or not at `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.

- [x] **Step 8: Record a no-Git checkpoint**

~~~powershell
git diff --check -- template/.omp/tools/codegraph-retrieve.js scripts/tests/topic05-tool.Tests.mjs
git status --short -- template/.omp/tools/codegraph-retrieve.js scripts/tests/topic05-tool.Tests.mjs
~~~

Expected: only the two intended paths and no whitespace errors. Do not stage or commit.

---

### Task 5: Project actor/capability routing and the closed Cheap Scout packet

**Files:**
- Modify: `template/.omp/agents/cheap-scout.md`
- Modify: `template/.omp/agents/reviewer.md`
- Modify: `template/.omp/AGENTS.md`
- Modify: `template/.omp/commands/quick.md`
- Modify: `template/.omp/commands/standard.md`
- Modify: `template/.omp/commands/orchestrated.md`
- Modify: `docs/evidence/current-product/topic-03/manifest.yml` (refresh live current-product
  hashes; immutable Phase-00 evidence is untouched)
- Create: `scripts/tests/topic05-routing.Tests.ps1`

**Interfaces:**
- Actor selection and retrieval capability selection are independent Tech Lead decisions.
- Cheap Scout returns the closed retrieval packet from this plan; it never accepts a candidate.
- Reviewer retrieves independently at `xhigh`; it does not inherit Scout conclusions as evidence.
- CodeGraph failure always returns to an explicit native path, never to an opaque retry loop.

- [x] **Step 1: Add failing frontmatter and semantic routing tests**

Parse the three agent files and three command files as closed YAML/Markdown surfaces. Assert:

- Cheap Scout remains `omniroute/ds/deepseek-v4-flash:xhigh`, with only
  `omniroute/ds/deepseek-v4-pro:xhigh` as provider fallback;
- Cheap Scout's fixed `tools:` list remains exactly its native read-only set, with no `bash`,
  `write`, `edit`, task-spawn, or acceptance authority;
- Reviewer remains `xhigh` and independently checks critical claims against current source;
- CodeGraph is optional/default-off and selected only when source fitness warrants it;
- the four legal arms are Lead/native, Lead/CodeGraph, Scout/native then Lead, and
  Scout/CodeGraph then Lead;
- a missing/failed/unhealthy CodeGraph path names native retrieval and does not block the workflow;
- weak evidence returns `partial` plus gaps rather than a model retry;
- uncorroborated absence and graph-only critical claims cannot pass; and
- Quick/Standard/Orchestrated differ in workflow depth, not in truth authority.

Add a mutation matrix that removes each rule independently and proves the test fails for that
mutation. Do not use one giant required-phrase assertion as a substitute for frontmatter parsing.

- [x] **Step 2: Run the routing suite and observe the intended failure**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-routing.Tests.ps1
~~~

Expected: nonzero because the closed packet and capability-routing clauses are not yet present.

- [x] **Step 3: Extend Cheap Scout with the closed JSON-Schema result contract**

Describe `codegraph_retrieve` as a discoverable optional capability without adding its optional
name to Cheap Scout's fixed `tools:` frontmatter and without adding `bash`. Pinned OMP auto-includes
installed custom tools in ordinary children; keeping the absent-by-default name out of the fixed
list preserves native-only loading and OMP's read-only classification when the component is not
installed. Put the closed packet fields under `output:` and disallow additional properties at
every object level.
Limit `summary` to a concise answer, `claims` to bounded cited claims, and
`searches_performed`/`fallback_path` to short identifiers. Require project-relative `file:line`
citations and classify every edge as direct, resolved, heuristic, or inference.

The prompt must say:

1. use native retrieval when sufficient;
2. use CodeGraph only when it materially improves relationship/blast-radius discovery;
3. if the tool is absent or non-completed, record the reason and continue natively;
4. never duplicate the raw tool payload;
5. never claim completeness from a graph gap; and
6. return `partial` with named gaps when evidence is structurally valid but weak.

- [x] **Step 4: Project independent Reviewer and Tech Lead behavior**

Reviewer may choose native, CodeGraph, or mixed retrieval independently. It must corroborate every
critical graph-supported claim in current source and reject stale/candidate-mismatched evidence.
The Tech Lead chooses whether a Scout is useful and which capability is suitable; no permanent
Explorer/Verifier roster is introduced. If DeepSeek is unavailable, the Scout branch is
`ENVIRONMENT_BLOCKED` and the Tech Lead continues with the capability/actor it needs.

- [x] **Step 5: Keep persistent and command guidance compact**

`template/.omp/AGENTS.md` gets only stable cross-workflow rules: actor/capability independence,
graph-as-hypothesis, native fallback, critical corroboration, and no default-on indexing. Put
workflow-specific selection detail in the three command files. Do not copy the full output packet or
benchmark protocol into persistent context.

- [x] **Step 6: Make the focused routing and prior routing tests pass**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-deepseek-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-topology-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic02-workflow-lifecycle.Tests.ps1
~~~

Expected: zero failures. The Topic 03 primary/fallback identities and Reviewer/Worker effort
contracts remain unchanged.

- [x] **Step 7: Re-run token/context budget checks**

~~~powershell
pwsh -NoProfile -File scripts/validate-template.ps1
~~~

Expected at this intermediate point: no agent/command structure or token-budget failure. The
closed Scout schema may exceed its advisory 1,200-token target because Cheap Scout context is
explicitly cheap; it must remain below the hard warning and does not justify weakening the packet.
A later Topic 05 authority validation may still be missing and must not be called PASS early.

- [x] **Step 8: Record a no-Git checkpoint**

~~~powershell
git diff --check -- template/.omp/agents/cheap-scout.md template/.omp/agents/reviewer.md template/.omp/AGENTS.md template/.omp/commands docs/evidence/current-product/topic-03/manifest.yml scripts/tests/topic05-routing.Tests.ps1
git status --short -- template/.omp/agents/cheap-scout.md template/.omp/agents/reviewer.md template/.omp/AGENTS.md template/.omp/commands docs/evidence/current-product/topic-03/manifest.yml scripts/tests/topic05-routing.Tests.ps1
~~~

Expected: only the intended routing files and no whitespace errors. Do not stage or commit.

---

### Task 6: Integrate the optional multi-root component transactionally

**Files:**
- Create: `template/.omp/codegraph/component-manifest.json`
- Create: `template/.omp/codegraph/COMPONENT.md`
- Create: `template/.omp/codegraph/CODEGRAPH-LICENSE.txt`
- Modify: `scripts/install-template.ps1`
- Modify: `scripts/uninstall-template.ps1`
- Create: `scripts/tests/topic05-installer.Tests.ps1`
- Modify: `scripts/tests/topic05-provisioning.Tests.ps1`

**Interfaces:**
- New explicit component name: `codegraph`.
- `codegraph` is never included by omission or by the current default component set.
- `codegraph` requires `state` in the same operation or an already installed compatible Topic 04
  state manifest.
- Optional installer inputs: `-CodeGraphArtifactPath` for offline installation and
  `-AllowCodeGraphDownload` for the explicit network path. The two are mutually exclusive.
- Uninstall restores template-owned paths but retains/reports bundle and worktree caches.

- [x] **Step 1: Write failing installer dependency and transaction tests**

Build disposable source/target/user-profile roots. Extend the fake bundle from Task 2 and test:

1. no-argument/default installation does not mention, provision, copy, or discover CodeGraph;
2. dry-run `-Components codegraph` lists bundle receipt, state dependency, two target roots, and
   generated records but writes nothing and performs no network call;
3. selecting `codegraph` without compatible `state` fails before target mutation;
4. selecting `state,codegraph` succeeds with an offline valid fake artifact;
5. an existing compatible Topic 04 target state satisfies the dependency;
6. incompatible/missing state manifest, lock digest, artifact digest, bundle receipt, runtime
   record, or component manifest fails closed;
7. artifact path plus download switch is rejected;
8. missing artifact without explicit download permission is rejected before network access;
9. interruption at every activation boundary restores the exact pre-install target and preserves
   an already valid shared bundle;
10. protected pre-existing files obey existing conflict/backup policy; and
11. uninstall restores the backup, removes installed adapter/records, retains bundle/index bytes,
    and prints their exact canonical paths.

Run the installer in child PowerShell processes with a disposable `USERPROFILE` so tests never
touch the real managed cache.

- [x] **Step 2: Run the installer suite and observe the intended failure**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-installer.Tests.ps1
~~~

Expected: nonzero because `codegraph` is not a known component and no component manifest exists.

- [x] **Step 3: Create the closed component manifest and operator contract**

`component-manifest.json` has `schema_version: 1`, component name/version, Topic 04 compatibility,
upstream lock digest, and a sorted exact path/SHA-256 map for:

~~~text
.omp/tools/codegraph-retrieve.js
.omp/codegraph/CODEGRAPH-LICENSE.txt
.omp/codegraph/COMPONENT.md
.omp/codegraph/codegraph-process.ps1
.omp/codegraph/safe-init.mjs
.omp/codegraph/upstream-lock.json
~~~

The manifest does not hash itself and never lists generated `runtime.json` or
`install-record.json`. Copy `CODEGRAPH-LICENSE.txt` byte-for-byte from the clean pinned upstream
`LICENSE` and require SHA-256
`e6d98f98c666bebe065ac2492a0a19232cc318d4d67bac3ca42ffb77bacc8809`.
`COMPONENT.md` documents enablement, native fallback, retained-cache policy, cleanup confirmations,
reason codes, and the prohibition on MCP/hooks/auto-update.

- [x] **Step 4: Add `codegraph` as a special multi-root installer component**

Preserve the current single-root map for existing components. Add an explicit branch whose source
set is exactly the five manifest paths plus the manifest itself. Before target mutation:

1. validate the closed upstream/component manifests;
2. reconcile the state dependency;
3. provision or reuse the verified bundle;
4. derive the absolute PowerShell 7.4+ path;
5. create the closed runtime/install records in memory; and
6. include every target change in the existing backup/rollback journal.

During activation, write helper/lock/docs first, generated records next, and the model-discoverable
tool last. A failed last step must still roll back everything. Never add `codegraph` to the default
component string. Implement and test
`New-Topic05CodeGraphRuntimeRecord -Receipt -TargetOmp -PwshPath` in this step; it returns the
closed in-memory runtime record and performs no target write before activation.

- [x] **Step 5: Extend uninstall without deleting user cache**

Read and validate `install-record.json` before restoring the backup. Report retained bundle and
known index paths after rollback. If the record is missing or invalid, restore only paths proven by
the normal backup and print an unknown-cache warning; do not search broadly or delete `.codegraph`
directories. Direct users to `scripts/cleanup-codegraph.ps1` for explicit cleanup.

- [x] **Step 6: Make the installer suite pass**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-installer.Tests.ps1
~~~

Expected: all default-off/dependency/dry-run/rollback/protected-file/uninstall cases pass with zero
real network and zero writes outside disposable roots.

- [x] **Step 7: Re-run provisioning and predecessor installer regressions**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-provisioning.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-installer.Tests.ps1
~~~

Expected: zero failures. Existing default components, state installation, and uninstall behavior
are byte-compatible unless explicitly extended by the new optional branch.

- [x] **Step 8: Regenerate and validate exact component hashes**

Use `Get-FileHash -Algorithm SHA256` over the six sorted manifest paths, update only the hash map
through `apply_patch`, then rerun the installer suite. Do not create a self-updating manifest at
runtime and do not hash generated target records.

- [x] **Step 9: Record a no-Git checkpoint**

~~~powershell
git diff --check -- template/.omp/codegraph scripts/install-template.ps1 scripts/uninstall-template.ps1 scripts/tests/topic05-installer.Tests.ps1 scripts/tests/topic05-provisioning.Tests.ps1
git status --short -- template/.omp/codegraph scripts/install-template.ps1 scripts/uninstall-template.ps1 scripts/tests/topic05-installer.Tests.ps1 scripts/tests/topic05-provisioning.Tests.ps1
~~~

Expected: only intended component/installer paths and no whitespace errors. Do not stage or commit.

---

### Task 7: Build the uncontaminated four-arm benchmark harness without automatic model spend

**Files:**
- Create: `scripts/lib/topic05-benchmark.ps1`
- Create: `scripts/run-topic05-retrieval-benchmark.ps1`
- Create: `scripts/tests/topic05-benchmark.Tests.ps1`
- Create: `evals/retrieval/topic05/fixtures.json`
- Create: `evals/retrieval/topic05/README.md`

**Interfaces:**
- Modes: `plan` (default), `deterministic`, and `model-pilot`.
- Arms: `A_lead_native`, `B_lead_codegraph`, `C_scout_native_lead`, and
  `D_scout_codegraph_lead`.
- A model pilot additionally requires `-AllowModelSpend` and exact
  `-Confirmation RUN_TOPIC05_MODEL_PILOT`.
- Every planned/run arm gets one immutable sanitized record; blocked and failed runs are data.

- [x] **Step 1: Create the failing closed-fixture and mode tests**

The test suite must reject unknown fixture/run-record fields, duplicate IDs, invalid project-relative
paths, missing oracle facts, invalid arm names, unseeded ordering, missing contamination controls,
and token claims without provider usage. Define exactly these nine fixture classes, each with a
deterministic repository materializer, retrieval question, required facts, allowed citations, and
failure oracle:

~~~text
multi_file_call_path
blast_radius_affected_tests
unfamiliar_symbol_localization
exact_text_config_native_fit
dynamic_or_heuristic_graph_gap
deterministic_absence_claim
stale_partial_pending_index
linked_worktree_index_mismatch
source_or_candidate_mutation
~~~

Also test that `plan` and `deterministic` never start OMP/model processes, while `model-pilot`
refuses unless both spend controls are present and a non-empty Lead model identity is supplied.

- [x] **Step 2: Run the benchmark tests and observe the intended failure**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-benchmark.Tests.ps1
~~~

Expected: nonzero because the fixture registry and harness do not exist.

- [x] **Step 3: Implement closed fixture and run-record validation**

Each run record must include:

~~~yaml
schema_version: 1
campaign_id: string
fixture_id: string
fixture_class: string
arm: A_lead_native | B_lead_codegraph | C_scout_native_lead | D_scout_codegraph_lead
order: integer
seed: integer
snapshot_hash: sha256
candidate_hash: sha256 | null
cache_condition: absent | cold | warm
environment_identity: object
actor_identity: object
capability_identity: object
status: COMPLETED | FAILED | TIMEOUT | ENVIRONMENT_BLOCKED | NOT_RUN
reason: string | null
quality: object
usage: object
lead_reread: object
retrieval: object
contamination: object
timestamps: object
record_hash: sha256
~~~

Use canonical sorted-key JSON for `record_hash`. `quality` records required-fact recall, precision,
citation accuracy, false absence, and false completion. `usage` separates
`core_workflow_tokens`, `cheap_scout_tokens`, `raw_total_tokens`, cache-read tokens, and residual
context; unknown provider values are the string `not_measured`, never estimated integers.

- [x] **Step 4: Implement the default dry plan and deterministic mode**

`plan` materializes nothing and prints the seeded counterbalanced arm order, required identities,
cache conditions, and exact output paths. `deterministic` materializes disposable repositories,
runs only adapter/native oracle probes, validates contamination boundaries, and emits records with
model/token fields `not_measured`. Neither mode may resolve provider credentials or call `omp` with
a prompt.

Native A/C fixtures must be copied into a target that has no adapter, CodeGraph component,
CodeGraph instructions, executable reference, `.codegraph` path, or inherited `CODEGRAPH_*`
variable. CodeGraph B/D fixtures use a separately prepared target. Compare both source trees to the
same frozen fixture snapshot hash.

- [x] **Step 5: Implement the explicitly gated model-pilot planner/executor**

Require all of:

~~~powershell
-Mode model-pilot
-AllowModelSpend
-Confirmation RUN_TOPIC05_MODEL_PILOT
-LeadModel 'provider/model:effort'
~~~

Add optional `-Pairs` defaulting to `3`, a fixed integer `-Seed`, and an explicit output directory.
Resolve Cheap Scout from the installed agent contract: Flash `xhigh` primary and Pro `xhigh`
fallback only. If neither DeepSeek route is runnable, record C/D as `ENVIRONMENT_BLOCKED`; never
substitute Codex, Claude, Gemini, or the Lead model. Preserve all A-D crash/failure/timeout records.

- [x] **Step 6: Enforce comparison and promotion boundaries**

The reporter computes A-vs-B, C-vs-D, A-vs-C, and B-vs-D only for paired identical fixture
snapshots. Hard correctness/contamination gates precede efficiency. The reporter may recommend B,
D, both for named task classes, neither, or inconclusive. It must not emit a universal-default
recommendation or a CodeGraph-specific percentage threshold. A finite pilot can reject an obvious
regression but cannot promote the component.

- [x] **Step 7: Make the benchmark suite pass using fake event streams**

Feed sanitized fake provider/OMP event records to the parser so completed, unavailable, fallback,
missing-usage, timeout, and residual-context cases are deterministic. No test may need a provider
account.

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-benchmark.Tests.ps1
pwsh -NoProfile -File scripts/run-topic05-retrieval-benchmark.ps1 -Mode plan -Pairs 3 -Seed 20260813
~~~

Expected: all tests pass; the plan lists 162 ordered executions per three-pair campaign. Each
fixture/pair has native A/C once with `cache_condition: absent` and CodeGraph B/D once cold plus
once immediately warm (nine fixtures x six executions x three pairs). It makes zero repository
changes and starts no model process. Comparisons involving B/D are reported separately for cold
and warm conditions.

- [x] **Step 8: Document the operator boundary**

`evals/retrieval/topic05/README.md` explains the arms, contamination split, cold/warm accounting,
required provider telemetry, model-spend confirmation, DeepSeek block handling, finite pilot
limits, and route-specific recommendation vocabulary. It must say that deterministic PASS is not
model-campaign PASS.

- [x] **Step 9: Record a no-Git checkpoint**

~~~powershell
git diff --check -- scripts/lib/topic05-benchmark.ps1 scripts/run-topic05-retrieval-benchmark.ps1 scripts/tests/topic05-benchmark.Tests.ps1 evals/retrieval/topic05
git status --short -- scripts/lib/topic05-benchmark.ps1 scripts/run-topic05-retrieval-benchmark.ps1 scripts/tests/topic05-benchmark.Tests.ps1 evals/retrieval/topic05
~~~

Expected: only intended benchmark paths and no whitespace errors. Do not stage or commit.

---

### Task 8: Project one canonical decision and guard every active authority surface

**Files:**
- Create: `scripts/lib/topic05-progressive-retrieval.ps1`
- Create: `scripts/validate-topic05-progressive-retrieval.ps1`
- Create: `scripts/tests/topic05-progressive-retrieval.Tests.ps1`
- Modify: `scripts/validate-template.ps1`
- Append: `spec/key/04-decision-log.md` as KD-029
- Modify: `spec/key/01-dna.md`
- Modify: `spec/key/03-token-quality-model.md`
- Modify: `spec/03-agent-topology.md`
- Modify: `spec/05-context-and-token-model.md`
- Modify: `spec/07-retrieval-and-code-understanding.md`
- Modify: `spec/12-installation-and-rollback.md`
- Modify: `spec/13-validation-and-evaluation.md`
- Modify: `spec/14-upgradeability-and-governance.md`
- Modify: `spec/15-security-and-failure-recovery.md`
- Modify: `spec/README.md`
- Modify: `spec/phases/phase-03-context-efficiency.md`
- Modify: `spec/phases/phase-05-installation-hardening.md`
- Modify: `spec/phases/phase-06-evaluation.md`
- Modify: `registry/upstreams.yml`
- Modify: `registry/adoption-ledger.yml`
- Modify: `registry/rejected-mechanisms.yml`
- Create: `docs/retrieval.md`
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/installation.md`
- Modify: `docs/customization.md`
- Modify: `docs/token-strategy.md`
- Modify: `docs/security.md`
- Modify: `docs/rollback.md`
- Modify: `docs/workflow-v0.md`
- Modify: `docs/policies/context-budget.md`

**Interfaces:**
- KD-029 owns the decision: optional default-off CodeGraph, separate worktree cache, capability
  adapter, actor/capability independence, graph-as-hypothesis, native fallback, and four-arm
  evidence gate.
- Registry IDs: `adopt-017`, `reject-018`, and `reject-019`.
- The focused validator is PowerShell 5.1 compatible and mutation-tested.

- [x] **Step 1: Write the failing focused-validator and mutation suite**

Follow the Topic 02 focused-helper pattern: one reusable helper returns structured findings; the
entry script renders counts and exits nonzero; mutation tests copy only the governed files into a
disposable root. Add independent mutations for:

- CodeGraph becoming a default component;
- missing exact v1.5.0/tag/commit/artifact digest identity;
- replacing the adapter with MCP, CLI init, hooks, or auto-update;
- accepting model-selected path/command/environment input;
- shared or symlinked worktree index;
- frozen-candidate lazy initialization;
- missing Topic 04 cache ownership or candidate/source post-check;
- graph evidence treated as truth or allowed to prove absence alone;
- missing native fallback or opaque model retry;
- Cheap Scout gaining execution/review/acceptance authority;
- Reviewer inheriting Scout evidence or losing independent retrieval;
- native benchmark contamination;
- missing model-spend confirmation, telemetry truthfulness, or DeepSeek block disposition;
- universal/default promotion wording; and
- active docs/registry/spec claims that contradict KD-029.

Also assert that historical Phase 00 evidence and fenced research are not rewritten merely to
match current wording.

- [x] **Step 2: Run the focused suite and observe the intended failure**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-progressive-retrieval.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1
~~~

Expected: nonzero because KD-029 and its projections do not exist.

- [x] **Step 3: Append KD-029 and the load-bearing canonical clauses**

KD-029 records alternatives, chosen design, evidence limits, operational fallback, benchmark gate,
and reversibility. Project normative detail into the owning specs rather than duplicating the full
decision everywhere:

- topology owns Tech Lead/Scout/Reviewer authority;
- context/retrieval owns progressive retrieval, source fitness, and compact evidence;
- installation owns pin/provision/rollback/cache retention;
- validation owns deterministic/model gates and the four arms;
- governance owns update/re-pin procedure;
- security owns process/input/path/index boundaries; and
- phase files own implementation order and exit criteria.

Keep exact source-of-truth links between summary clauses and their owning section.

- [x] **Step 4: Update registries with closed dispositions**

Add CodeGraph v1.5.0 to `registry/upstreams.yml` with commit, license, release URL, six artifact
digests, and the exact adopted subset. Add `adopt-017` for the optional adapter/worktree-local
retrieval capability. Add `reject-018` for default-on/universal CodeGraph and `reject-019` for MCP,
interactive install, hooks, daemon, auto-update, or arbitrary shell exposure. Validate unique IDs,
reciprocal references, and no claim that upstream benchmark numbers prove this product.

- [x] **Step 5: Update operator documentation without persistent-context duplication**

Create `docs/retrieval.md` as the detailed operator guide. Keep README/architecture/workflow pages
short and link to it. Installation/customization cover explicit `codegraph` enablement and offline
artifact use. Security/rollback cover input, process, cache, retained-data, and explicit cleanup.
Token/context docs distinguish Cheap Scout token volume from premium Lead context and prohibit
promotion claims from estimates.

- [x] **Step 6: Fence stale active summaries; preserve actual history**

Search active specs, registries, docs, and unfenced research for fixed-roster, unconditional LSP or
CodeGraph, shared-index, graph-truth, default-on, MCP, silent fallback, and provider-substitution
claims. Correct current summaries or add an explicit non-authority/historical fence when that is
their real status. Do not edit immutable evidence or rewrite historical observations.

- [x] **Step 7: Integrate the helper into the full validator**

`scripts/validate-template.ps1` must invoke the helper in-process and require checked-in Topic 05
source/config/evidence files. It must not require target-generated `runtime.json` or
`install-record.json`, a managed binary, an index, DeepSeek availability, or a completed paid
campaign.

- [x] **Step 8: Make focused validation and all mutations pass**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-progressive-retrieval.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1
~~~

Expected: every registered mutation is killed and the live tree has zero findings.

- [x] **Step 9: Run predecessor authority and full validators**

~~~powershell
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
pwsh -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
~~~

Expected: zero failures. Preserve only already documented non-failing warnings; no new Topic 05
warning may be waved through.

- [x] **Step 10: Record a no-Git checkpoint**

~~~powershell
git diff --check -- spec registry docs README.md scripts/lib/topic05-progressive-retrieval.ps1 scripts/validate-topic05-progressive-retrieval.ps1 scripts/validate-template.ps1 scripts/tests/topic05-progressive-retrieval.Tests.ps1
git status --short -- spec registry docs README.md scripts/lib/topic05-progressive-retrieval.ps1 scripts/validate-topic05-progressive-retrieval.ps1 scripts/validate-template.ps1 scripts/tests/topic05-progressive-retrieval.Tests.ps1
~~~

Expected: intended authority/docs/validator paths only and no whitespace errors. Do not stage or
commit.

---

### Task 9: Run a bounded real local smoke and publish truthful current-product evidence

**Files:**
- Create: `docs/evidence/current-product/topic-05/deterministic.json`
- Create: `docs/evidence/current-product/topic-05/model-campaign.json`
- Create: `docs/evidence/current-product/topic-05/manifest.json`
- Modify: `docs/superpowers/specs/2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-design.md`

**Interfaces:**
- Deterministic evidence may use the real pinned upstream binary but no model/provider call.
- Model evidence is honest `NOT_RUN` unless a separately authorized campaign actually completes.
- Evidence captures environment and immutable hashes; it never embeds the binary, index, secrets,
  absolute user profile, or raw stderr.

- [x] **Step 1: Validate the live-smoke prerequisites before any download**

Require:

- PowerShell 7.4+ and Node 24+;
- the clean pinned OMP source checkout at
  `3a8591a8af5b6d200088d12ca75a5517cb064fa8`;
- a valid Topic 05 upstream lock/component manifest;
- Git linked-worktree support; and
- an empty disposable test root beneath the system temporary directory.

If network access is unavailable, retain deterministic fake-runtime PASS separately and record the
real-binary smoke as `ENVIRONMENT_BLOCKED`. Do not downgrade the check to an unverified local
binary and do not claim live PASS.

- [x] **Step 2: Provision the official current-platform artifact into a disposable cache**

Run the explicit network-enabled provisioner with `-Apply` against a temporary `USERPROFILE`, then independently
check the downloaded archive and extracted receipt against `upstream-lock.json`. Capture only
version, platform, artifact SHA-256, receipt SHA-256, final allowed host, and timestamps. Do not use
the user's normal managed cache and do not persist the release archive in the repository.

- [x] **Step 3: Exercise a tiny repository and one linked worktree**

Create a disposable Git repository with a known cross-file call path and tests, then a linked
worktree at a second commit. Using the real library/CLI through the adapter boundary, prove:

1. no index exists before first selected retrieval;
2. lazy init creates only the main worktree's `.codegraph/**`;
3. sync/status/explore produce cited expected facts;
4. the linked worktree creates and uses a distinct index path;
5. forcing the main-worktree index identity into the linked worktree yields `worktree_mismatch`;
6. a graph gap/absence question triggers native corroboration rather than graph-only completion;
7. source mutation during retrieval invalidates the result;
8. a frozen candidate without a pre-existing index returns `candidate_index_missing`; and
9. Git source/status outside the declared cache marker remains unchanged.

Use recoverable removal for the disposable roots only after canonical paths are checked to remain
under the test root.

- [x] **Step 4: Prove installed tool discovery without a model call**

Install `state,codegraph` into a disposable project using the already verified artifact. Use RPC
`get_state`/tool inspection to prove the adapter is discoverable and restricted sessions do not
gain it. Do not send a model prompt. Uninstall from the backup and prove installed files restore
while bundle/index paths are retained and reported.

- [x] **Step 5: Run the deterministic benchmark campaign**

~~~powershell
$topic05EvidenceRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'omp-topic05-evidence-' + [guid]::NewGuid().ToString('N')
)
[void](New-Item -ItemType Directory -Path $topic05EvidenceRoot)
pwsh -NoProfile -File scripts/run-topic05-retrieval-benchmark.ps1 `
    -Mode deterministic -Pairs 1 -Seed 20260813 -OutputDir $topic05EvidenceRoot
~~~

Expected: all nine fixture classes emit validated model-free records; hard contamination/candidate/
source gates pass; token fields are `not_measured`. Copy only the canonical summarized evidence into
`deterministic.json` through `apply_patch`.

- [x] **Step 6: Write truthful model-campaign disposition without invoking a provider**

Create `model-campaign.json` with `status: "NOT_RUN"`, `reason:
"explicit_model_spend_not_authorized_for_this_campaign"`, the four planned arms, DeepSeek route
identities, harness/fixture hashes, and no recommendation. If the environment itself was checked
and DeepSeek is unavailable, the affected C/D planned rows may be `ENVIRONMENT_BLOCKED`; do not
probe paid completion merely to decide this file.

- [x] **Step 7: Update the design status from approved to implemented evidence**

Change only the design's status/evidence section. State exactly what exists and passed, what remains
experimental/default-off, and that no model campaign/promotion has occurred. Do not rewrite the
approved design choices to fit implementation accidents.

- [x] **Step 8: Create and verify the current-product evidence manifest**

`manifest.json` is closed and hashes the exact Topic 05 source, tests, fixtures, approved design,
canonical decision, upstream lock/component manifest, deterministic evidence, and model-campaign
disposition after the Step 7 design update. It does not hash itself, generated target records,
archives, managed bundles, or indexes. Include repo HEAD, dirty-path list digest, OMP pin,
Node/PowerShell/Git versions, and each command/exit code used for the evidence.

- [x] **Step 9: Re-run focused validation against final evidence bytes**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-progressive-retrieval.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1
pwsh -NoProfile -File scripts/tests/topic05-benchmark.Tests.ps1
~~~

Expected: zero failures and exact evidence hashes. A live-smoke environment block is accepted only
when explicitly recorded; it is never rendered as PASS.

- [x] **Step 10: Record a no-Git checkpoint**

~~~powershell
git diff --check -- docs/evidence/current-product/topic-05 docs/superpowers/specs/2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-design.md
git status --short -- docs/evidence/current-product/topic-05 docs/superpowers/specs/2026-08-13-topic-05-progressive-retrieval-codegraph-cheap-scout-design.md
~~~

Expected: only the intended evidence/design paths and no whitespace errors. Do not stage or commit.

---

### Task 10: Run the complete regression gate and prepare an unstaged handoff

**Files:**
- Modify: `CHANGELOG.md`
- Create: `codex-topic05-progressive-retrieval-codegraph-changelog.md`
- Modify as hashes require: `template/.omp/codegraph/component-manifest.json`
- Modify as hashes require: `docs/evidence/current-product/topic-05/manifest.json`

**Interfaces:**
- Completion means deterministic implementation/evidence and all required regressions pass.
- It does not mean CodeGraph is default, a paid campaign passed, or a route was promoted.
- Handoff remains unstaged unless the user separately requests Git operations.

- [x] **Step 1: Write the human changelog entries**

Add a concise `CHANGELOG.md` item for the optional default-off component, safe per-worktree lazy
index, Cheap Scout/native fallback routing, benchmark harness, and evidence status. In
`codex-topic05-progressive-retrieval-codegraph-changelog.md`, list every changed path by subsystem,
operator enable/disable/cleanup commands, retained data, exact tests run, observed warnings/blocks,
and explicit non-goals. Do not claim model-pilot success.

- [x] **Step 2: Refresh manifests after all documentation bytes settle**

Recompute the component manifest's six source hashes and the evidence manifest's declared file
hashes. Apply exact values, then run their validators twice; the second run must produce no diff,
proving convergence rather than a moving self-hash.

- [x] **Step 3: Run every Topic 05 deterministic suite**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic05-provisioning.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic05-adapter.Tests.ps1
node --test scripts/tests/topic05-tool.Tests.mjs
pwsh -NoProfile -File scripts/tests/topic05-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic05-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic05-benchmark.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic05-progressive-retrieval.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1
~~~

Expected: zero failures, zero unexpected warnings, no provider/model call, and no writes outside
disposable roots or declared local evidence.

- [x] **Step 4: Run all predecessor focused suites affected by Topic 05**

~~~powershell
pwsh -NoProfile -File scripts/tests/topic02-workflow-lifecycle.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-deepseek-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-topology-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-candidate.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-transfer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic04-state-e2e.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoProfile -File scripts/validate-topic04-durable-state.ps1
~~~

Expected: zero failures. If a command name has changed in the live tree, use the exact existing
focused entry point documented by that topic and update this plan/changelog before claiming the
gate ran.

- [x] **Step 5: Run Phase 00 source contracts and the full validator**

~~~powershell
$phase00Tests = @(Get-ChildItem scripts/tests -Filter 'phase00-*.Tests.ps1' |
    Sort-Object Name | ForEach-Object FullName)
Invoke-Pester -Script $phase00Tests -EnableExit
pwsh -NoProfile -File scripts/validate-template.ps1
~~~

Expected: all Phase 00 tests pass; full validator has zero failures. Record any sole pre-existing
non-failing warning verbatim and prove Topic 05 did not introduce another.

Observed on the repository's installed Pester 3.4: 330 Phase 00 tests passed and 8 historical E1
snapshot tests failed because they still require nine protected product pins and the Topic
03-retired `template/.omp/agents/explorer.md`. Full validation passed 239/2/0; the two advisories
are the existing RULES lower-bound and Cheap Scout upper-bound token estimates. The predecessor
snapshot mismatch is retained as a separate reconciliation follow-up, not a Topic 05 failure.

- [x] **Step 6: Run static source and Git hygiene checks**

~~~powershell
node --check template/.omp/tools/codegraph-retrieve.js
node --check template/.omp/codegraph/safe-init.mjs
node --check scripts/tests/fixtures/topic05/fake-codegraph.mjs
git diff --check
git status --short
git diff --name-only
git diff --cached --name-only
~~~

Expected: JavaScript syntax is valid; no whitespace errors; the complete dirty-path set is reviewed;
and the staged path list is unchanged from the pre-Topic-05 baseline. Do not treat unrelated user
changes as Topic 05 output.

- [x] **Step 7: Perform a requirement-to-evidence audit**

For AC-1 through AC-12 in the approved design, record one owning implementation path, one test,
one current evidence field, and one canonical authority anchor. Any missing cell is incomplete work,
not a documentation exception. Verify especially:

- optional/default-off installation;
- no shell/MCP/hook/update authority;
- per-worktree lazy cache and frozen-candidate behavior;
- Topic 04 identity/source binding;
- native fallback and absence corroboration;
- actor/capability independence;
- Cheap Scout/Reviewer authority limits;
- contamination-free benchmark arms;
- honest usage/environment disposition; and
- reversible uninstall/explicit cleanup.

- [x] **Step 8: Deliver the unstaged implementation handoff**

Report the outcome first, then summarize implemented surfaces, exact verification evidence, retained
cache behavior, model-campaign status, and any genuine environment block suited for later Opus/user
review. Link the design, implementation plan, retrieval guide, deterministic evidence, and
changelog with absolute paths. Do not stage, commit, push, branch, open a PR, spawn a Reviewer, or
run a model pilot unless the user gives a new explicit instruction.

---

## Acceptance-Criteria Coverage

| Approved criterion | Owning tasks |
|---|---|
| AC-1 optional/default-off exact version, commit, and artifact pin | 1, 2, 6, 8, 10 |
| AC-2 no upstream installer, MCP config, or unrelated prompt mutation | 2, 4, 6, 8, 9 |
| AC-3 one narrow Lead/Scout/Reviewer adapter; no arbitrary shell | 3, 4, 5, 8 |
| AC-4 separate lazy worktree indexes with strict sync/health rejection | 3, 6, 9 |
| AC-5 Topic 04 drift invalidation and non-candidate cache | 3, 8, 9 |
| AC-6 compact Scout overlay without raw-plus-summary forwarding | 4, 5, 8 |
| AC-7 targeted native reconciliation for load-bearing/absence claims | 3, 5, 7, 8 |
| AC-8 named CodeGraph/Scout/provider fail-soft paths without lifecycle drift | 3, 4, 5, 7, 8 |
| AC-9 independent exact-xhigh Reviewer retrieval | 5, 8 |
| AC-10 uncontaminated four-arm quality/context/cold-warm measurement | 7, 9, 10 |
| AC-11 quality before efficiency; no arbitrary threshold or cheap-token suppression | 5, 7, 8, 10 |
| AC-12 route/task-class recommendation only; native stays default when inconclusive | 7, 8, 9, 10 |

Every criterion has both deterministic tests and a canonical authority owner. Model-campaign
evidence is deliberately not a completion prerequisite because the user has not authorized spend;
without it, CodeGraph remains experimental and default-off.

## Plan Self-Review Gate

Before implementation begins:

- [x] confirm every created/modified path appears in both `File Structure and Ownership` and one
  numbered task;
- [x] confirm every public parameter, JSON field, status, reason code, path boundary, timeout, and
  hash source is defined once and reused consistently;
- [x] scan this plan for unresolved drafting markers;
- [x] verify every task starts with a failing test or closed validation and ends with a concrete
  command/expected result;
- [x] verify no step requires a provider/model call, staging, commit, branch, PR, or subagent;
- [x] verify real-binary download is explicit, digest-pinned, disposable, and can be honestly
  recorded as `ENVIRONMENT_BLOCKED`; and
- [x] run `git diff --check` on this plan and inspect its final hash before handing it off.
