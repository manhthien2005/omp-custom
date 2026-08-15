# Phase 00 E1 Forwarder Abort-Lifecycle Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the E1 loopback forwarder persist one request projection and exit cleanly when a downstream client disconnects before the upstream HTTP response ends.

**Architecture:** `runLive` will own a set of active relay objects. Each relay records its projection synchronously when upstream headers arrive, owns the associated upstream request/response handles, and exposes idempotent finish/dispose operations used by normal completion, downstream abort, upstream error, and controller shutdown. The existing fail-closed runner lifecycle oracle remains unchanged.

**Tech Stack:** Dependency-free Node.js ESM (`node:http`, `node:https`), PowerShell 5.1-compatible Pester 3.4 tests, SHA-256 source pins, existing Phase 00 validator and evidence inventory helpers.

## Global Constraints

- Work sequentially in the current session; do not spawn subagents.
- Do not create or switch branches/worktrees, stage files, commit, reset, or clean user work.
- Make zero provider calls. Do not run `scripts/run-phase00-e1.ps1` and do not create attempt 3.
- Preserve all immutable raw attempts byte-for-byte, including `docs/evidence/phase-00/E1/raw/provider-strict-off-control/attempt-002.*`.
- Do not alter prompts, fixtures, assignment text, schemas, the configured model, the pinned OMP runtime, the pinned upstream source, provider adjudication rules, the manifest, or product/template content.
- Preserve normal relay request/response byte parity and every existing fail-closed lifecycle check.
- Use test-first chronology: focused RED, minimal implementation, focused GREEN, related/full offline verification, then changelog.
- The approved design is `docs/superpowers/specs/2026-08-10-phase-00-e1-forwarder-abort-lifecycle-remediation-design.md`.

---

## File Structure

| Path | Responsibility | Change |
|---|---|---|
| `scripts/tests/phase00-e1.Tests.ps1` | Reproduce downstream abort against a disposable loopback gateway and prove lifecycle closure | Add one focused regression describe block |
| `scripts/lib/phase00-e1-forwarder.mjs` | Own active relay handles, persist header-time projections, and dispose unfinished relays | Modify narrowly |
| `scripts/lib/phase00-e1-evidence.ps1` | Fail closed unless the approved forwarder source is present | Replace exactly two forwarder hash pins after GREEN |
| `codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md` | Preserve English design, RED/GREEN, verification, hash, and boundary chronology | Append only |

## Task 1: Add the downstream-abort regression and prove RED

**Files:**

- Modify: `scripts/tests/phase00-e1.Tests.ps1` after `Describe 'Phase 00 E1 forwarder local relay'`
- Test: `scripts/tests/phase00-e1.Tests.ps1`

**Interfaces:**

- Consumes: `Start-Phase00E1NodeProcess`, `Read-Phase00E1ProcessLine`, `Stop-Phase00E1TestProcess`, `New-Phase00E1TestDirectory`, and `Remove-Phase00E1TestDirectory` from the same test file.
- Produces: Pester test name `disposes an unfinished upstream relay after downstream abort and exits cleanly` and a deterministic observation string covering exit, status, projection count, record order, and stderr.

- [x] **Step 1: Add a disposable hold-open loopback gateway**

Add `Describe 'Phase 00 E1 forwarder downstream abort lifecycle'` with one `It` block. Its temporary Node gateway must accept one request, send status `209` and the ASCII prefix `E1_ABORT_PREFIX`, deliberately omit `response.end()`, retain sockets in a `Set`, and destroy those sockets before closing when stdin receives `close`:

```javascript
import { createServer } from "node:http";

const sockets = new Set();
const server = createServer((request, response) => {
  request.resume();
  request.on("end", () => {
    response.writeHead(209, { "content-type": "text/plain" });
    response.write("E1_ABORT_PREFIX");
  });
});
server.on("connection", (socket) => {
  sockets.add(socket);
  socket.on("close", () => sockets.delete(socket));
});
server.listen(0, "127.0.0.1", () => {
  const address = server.address();
  process.stdout.write(JSON.stringify({ host: address.address, port: address.port }) + "\n");
});
process.stdin.setEncoding("utf8");
process.stdin.on("data", (text) => {
  if (text.split(/\r?\n/).some((line) => line.trim() === "close")) {
    for (const socket of sockets) socket.destroy();
    server.close(() => process.exit(0));
  }
});
```

- [x] **Step 2: Send one raw HTTP request and abort after the prefix**

Start the gateway and forwarder with existing process helpers. Use `Net.Sockets.TcpClient` so the test controls the downstream disconnect precisely. Send one valid `POST /v1/responses` JSON body with a `yield` tool, read until `E1_ABORT_PREFIX` is observed, and dispose the client without reading an HTTP end marker.

```powershell
$client = [Net.Sockets.TcpClient]::new('127.0.0.1',[int]$ready.listen_port)
$stream = $client.GetStream()
$stream.ReadTimeout = 5000
$wire = "POST /v1/responses HTTP/1.1`r`nHost: 127.0.0.1`r`nContent-Type: application/json`r`nContent-Length: $($requestBytes.Length)`r`nConnection: close`r`n`r`n"
$headerBytes = [Text.Encoding]::ASCII.GetBytes($wire)
$stream.Write($headerBytes,0,$headerBytes.Length)
$stream.Write($requestBytes,0,$requestBytes.Length)
$stream.Flush()
$received = [Text.StringBuilder]::new()
$buffer = New-Object byte[] 1024
while ($received.ToString() -notmatch 'E1_ABORT_PREFIX') {
    $count = $stream.Read($buffer,0,$buffer.Length)
    if ($count -le 0) { throw 'Gateway prefix was not relayed before downstream close.' }
    $null = $received.Append([Text.Encoding]::ASCII.GetString($buffer,0,$count))
}
$client.Dispose()
```

- [x] **Step 3: Assert one bounded clean lifecycle**

Send one `close` control line to the forwarder, wait at most five seconds, kill it only as test cleanup if it fails to exit, and then read the exclusive NDJSON file. The primary assertion must make the RED state self-describing:

```powershell
$exited = $forwarderProcess.WaitForExit(5000)
if (-not $exited) {
    try { $forwarderProcess.Kill() } catch {}
    $null = $forwarderProcess.WaitForExit(5000)
}
$stderr = $forwarderProcess.StandardError.ReadToEnd()
$records = @(Get-Content -LiteralPath $forwarderOutputPath | ForEach-Object { $_ | ConvertFrom-Json })
$projections = @($records | Where-Object record_type -eq 'phase00_e1_request_projection')
$summary = 'exited={0};exit={1};projections={2};records={3};stderr_empty={4}' -f `
    $exited,$forwarderProcess.ExitCode,$projections.Count,(@($records.record_type) -join ','),($stderr -eq '')
$summary | Should Be 'exited=True;exit=0;projections=1;records=phase00_e1_forwarder_ready,phase00_e1_request_projection,phase00_e1_forwarder_closed;stderr_empty=True'
$projections[0].request_index | Should Be 1
$projections[0].request_path | Should Be '/v1/responses'
$projections[0].forwarded | Should Be $true
$projections[0].gateway_http_status | Should Be 209
```

Also use a new `TcpClient` to prove the forwarder port is closed. In `finally`, stop both processes and call only `Remove-Phase00E1TestDirectory` for the validated `phase00-e1-test-*` directory.

- [x] **Step 4: Run only the new test and capture RED**

Run:

```powershell
pwsh.exe -NoProfile -Command '$r=Invoke-Pester -Script scripts/tests/phase00-e1.Tests.ps1 -TestName "Phase 00 E1 forwarder downstream abort lifecycle" -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -eq 0){exit 2}'
```

Expected before implementation: exactly one selected test fails; its observation contains `exited=False`, `projections=0`, and record order `phase00_e1_forwarder_ready,phase00_e1_forwarder_closed`. Confirm no provider process or raw evidence delta.

## Task 2: Make relay ownership explicit and prove focused GREEN

**Files:**

- Modify: `scripts/lib/phase00-e1-forwarder.mjs:247-390`
- Test: `scripts/tests/phase00-e1.Tests.ps1`

**Interfaces:**

- Consumes: existing `createProjectionRecord`, `stripHopByHopHeaders`, `sendLocalError`, and exclusive writer behavior.
- Produces: internal relay object `{ upstream, upstreamResponse, outgoing, finished, finish(), dispose() }`; `relayRequest` accepts `activeRelays`; `runLive` owns `Set<relay>`.

- [x] **Step 1: Register each upstream request in `activeRelays`**

Add an internal helper whose finish/dispose paths are idempotent:

```javascript
function registerRelay(activeRelays, upstream, outgoing) {
  const relay = {
    upstream,
    upstreamResponse: null,
    outgoing,
    finished: false,
    finish() {
      if (relay.finished) return;
      relay.finished = true;
      activeRelays.delete(relay);
    },
    dispose({ destroyDownstream = false } = {}) {
      if (relay.finished) return;
      if (relay.upstreamResponse && !relay.upstreamResponse.destroyed) {
        relay.upstreamResponse.destroy();
      }
      if (!relay.upstream.destroyed) relay.upstream.destroy();
      if (destroyDownstream && !relay.outgoing.destroyed) relay.outgoing.destroy();
      relay.finish();
    },
  };
  activeRelays.add(relay);
  return relay;
}
```

Create the `ClientRequest`, immediately register it, and assign its response to `relay.upstreamResponse` in the response callback. Pass `activeRelays` from `runLive` into `relayRequest`.

- [x] **Step 2: Persist the projection once at upstream response headers**

Move the existing `writer.write(createProjectionRecord(...))` call from the upstream `end` handler to the first synchronous statements in the upstream response callback, before `outgoing.writeHead` and before any body piping. Guard it with a relay-local boolean so no second event can write a duplicate:

```javascript
let projectionWritten = false;
const persistProjection = (upstreamResponse) => {
  if (projectionWritten) return;
  projectionWritten = true;
  writer.write(createProjectionRecord(body, piNoStrictEffective, {
    requestIndex,
    requestPath: incomingUrl.pathname,
    forwarded: true,
    gatewayHttpStatus: upstreamResponse.statusCode ?? null,
  }));
};
```

The response callback calls `persistProjection(upstreamResponse)`, relays the original headers/body, calls `outgoing.end()` and `relay.finish()` on normal `end`, and uses `relay.dispose()` plus `outgoing.destroy()` on upstream error or premature close.

- [x] **Step 3: Dispose on downstream close and controller shutdown**

Register an `outgoing.on('close', ...)` handler that disposes the relay only while its upstream response is absent or incomplete. In `runLive`, initialize `const activeRelays = new Set()`. The idempotent `shutdown` must call `server.close(...)` to stop accepting connections, dispose a snapshot of every active relay with `{ destroyDownstream: true }`, and write exactly one `phase00_e1_forwarder_closed` record only inside the server-close callback before closing the writer and resolving `closed`.

```javascript
outgoing.on("close", () => {
  if (!relay.finished && (!relay.upstreamResponse || !relay.upstreamResponse.complete)) {
    relay.dispose();
  }
});

server.close((error) => {
  // existing single closed-record/write-close/resolve logic
});
for (const relay of [...activeRelays]) {
  relay.dispose({ destroyDownstream: true });
}
```

Keep local 400/404/413 behavior unchanged and do not weaken any PowerShell lifecycle validity condition.

- [x] **Step 4: Run syntax and focused GREEN**

Run:

```powershell
node --check scripts/lib/phase00-e1-forwarder.mjs
pwsh.exe -NoProfile -Command '$r=Invoke-Pester -Script scripts/tests/phase00-e1.Tests.ps1 -TestName "Phase 00 E1 forwarder downstream abort lifecycle" -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
pwsh.exe -NoProfile -Command '$r=Invoke-Pester -Script scripts/tests/phase00-e1.Tests.ps1 -TestName "Phase 00 E1 forwarder local relay" -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
```

Expected before updating the source pin: syntax exit `0`; new regression `1/1`; normal byte-parity `1/1`; no stderr, leaked process, test temp residue, raw evidence delta, or provider delta. Run the zero-request helper lifecycle after Task 3 updates the fail-closed source pin.

## Task 3: Update source pins without changing immutable evidence

**Files:**

- Modify: `scripts/lib/phase00-e1-evidence.ps1:2394`
- Modify: `scripts/lib/phase00-e1-evidence.ps1:6554`
- Preserve: `docs/evidence/phase-00/E1/raw/provider-strict-off-control/attempt-002.run.json`

**Interfaces:**

- Consumes: final GREEN SHA-256 of `scripts/lib/phase00-e1-forwarder.mjs`.
- Produces: identical uppercase hash literals in `Get-Phase00E1ForwarderPrerequisite` and `Test-Phase00E1ArtifactContract`.

- [x] **Step 1: Compute the final source hash after behavior is GREEN**

Run:

```powershell
(Get-FileHash -Algorithm SHA256 -LiteralPath scripts/lib/phase00-e1-forwarder.mjs).Hash
```

- [x] **Step 2: Replace exactly the two executable hash pins**

Replace `9E646CE0453AC08A77CFE59E774B44C31679E1BBC0AF181EBAAF482FB6804B25` at the two `scripts/lib/phase00-e1-evidence.ps1` locations with the computed uppercase hash. Do not replace the same historical value inside immutable `attempt-002.run.json`.

- [x] **Step 3: Prove pin agreement and the zero-request helper lifecycle**

Run `rg` for the old and new hashes. Expected: the old value remains only in immutable attempt-2 evidence and historical documentation where applicable; both executable pins equal the new source hash. Then run `Describe 'Phase 00 E1 runner strict forwarder lifecycle'` and the artifact-contract tests in both shells.

## Task 4: Run complete offline verification in both shells

**Files:**

- Test: all `scripts/tests/phase00*.Tests.ps1`
- Validate: `scripts/validate-template.ps1`
- Audit: protected surfaces and `docs/evidence/phase-00/E1/raw/**`

**Interfaces:**

- Consumes: GREEN forwarder, regression test, and matching hash pins.
- Produces: exact cross-shell totals, validator summaries, inventory hashes, process counts, and provider delta for the changelog.

- [x] **Step 1: Run the complete focused E1 suite in PowerShell 7 and Windows PowerShell 5.1**

```powershell
pwsh.exe -NoProfile -Command '$r=Invoke-Pester -Script scripts/tests/phase00-e1.Tests.ps1 -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '$r=Invoke-Pester -Script scripts/tests/phase00-e1.Tests.ps1 -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
```

Expected delta from the locked checkpoint: `77/77` in each shell if exactly one new `It` block was added.

- [x] **Step 2: Run all Phase 00 tests in both shells**

```powershell
pwsh.exe -NoProfile -Command '$files=Get-ChildItem -LiteralPath scripts/tests -Filter "phase00*.Tests.ps1" | Sort-Object Name | Select-Object -ExpandProperty FullName; $r=Invoke-Pester -Script $files -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '$files=Get-ChildItem -LiteralPath scripts/tests -Filter "phase00*.Tests.ps1" | Sort-Object Name | Select-Object -ExpandProperty FullName; $r=Invoke-Pester -Script $files -PassThru; "TOTAL=$($r.TotalCount) PASSED=$($r.PassedCount) FAILED=$($r.FailedCount)"; if($r.FailedCount -ne 0){exit 1}'
```

Expected delta from the locked checkpoint: `305/305` in each shell.

- [x] **Step 3: Run the repository validator in both shells**

```powershell
pwsh.exe -NoProfile -File scripts/validate-template.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate-template.ps1
```

Expected: exit `0`, `99 passed / 1 warning / 0 failed` in each shell unless the validator truthfully reports a changed total; record the exact emitted totals rather than forcing the expectation.

- [x] **Step 4: Re-audit protected and immutable boundaries**

Record and compare:

- artifact contract `6/6` and protected surface `9/9`;
- immutable raw inventory remains `48 files / 846797 bytes / 82C100EA27151EA2B4EC79C8A9B4CD982D6B13484749C5B4527F934B2A6850F2`;
- attempt-002 forwarder/run/session/stdout/stderr hashes remain the six values in changelog section 44.3;
- provider inventory remains `9 attempts / 39 requests`, delta zero during remediation;
- manifest remains `E1: READY`, `T-00.4: NOT_STARTED`;
- strict-on destination, case 5, and conclusion remain absent;
- protected product/template and live-home inventories remain unchanged;
- targeted OMP/forwarder/gateway/Pester processes are zero;
- the disclosed historical temp residue remains `129` bytes with SHA-256 `C8F4C9188AA490EE2897F9CBF8E4F863CF35DDA7C022A376D9365EF3E89B8817`;
- branch/HEAD are still `main` / `62fecf277dc9d5e47d06319387eac747462214c1`, with zero staged paths.

If any invariant differs, stop and diagnose before claiming completion.

## Task 5: Append the authoritative remediation checkpoint

**Files:**

- Modify: `codex-phase00-e1-schema-precedence-provider-enforcement-changelog-for-opus5.md`

**Interfaces:**

- Consumes: approved design, this plan, RED/GREEN outputs, final source/pin hashes, exact two-shell totals, validator totals, and boundary audit.
- Produces: an English append-only checkpoint that leaves attempt 2 immutable and makes no provider verdict.

- [x] **Step 1: Append design and test-first chronology**

Record the design and plan paths/hashes, the exact RED observation, the minimal relay-ownership change, rejected alternatives (destroy-only and lifecycle-oracle relaxation), and the exact GREEN observation.

- [x] **Step 2: Append final verification and boundary evidence**

Record every command family, exit code, Pester total, validator summary, final forwarder SHA-256, both updated pin locations, artifact/protected/raw/provider inventories, zero provider delta, zero targeted processes, and zero staged paths.

- [x] **Step 3: State the next gate precisely**

State that attempt 2 remains immutable `INVALID_RUN`; no E1 PASS, strict-on eligibility, case 5, conclusion, manifest transition, retry, or joint closure is claimed. The only possible next provider action is `ProviderStrictOffControl` attempt 3 after a newly locked complete offline preflight, a new no-overwrite destination, and separate explicit user authorization.

## Design-to-Plan Coverage

| Approved requirement | Task | Falsification |
|---|---|---|
| Normal request/response byte parity | 2, 4 | Existing loopback byte-parity test |
| One projection after upstream headers even on downstream abort | 1, 2 | Hold-open gateway regression |
| Monotonic request indexes | 1, 2, 4 | Projection index assertion plus full suite |
| Explicit upstream request/response ownership | 2 | Active relay set and idempotent relay API |
| Dispose on downstream close | 1, 2 | Client closes after prefix while upstream stays open |
| Dispose on controller shutdown | 2, 4 | Active-relay shutdown plus bounded exit |
| Exactly one closed record after listener/relay disposal | 1, 2 | Exact record-order/count assertion |
| Exit zero, no timeout/stderr/process/port leak | 1, 2, 4 | Observation summary, port probe, process audit |
| Retain fail-closed lifecycle oracle | 2, 4 | No runner-oracle edit; full suites and validators |
| Update all executable source pins | 3, 4 | Hash search and artifact contract |
| Zero provider calls | Global, 1-5 | Provider inventory delta audit |
| Preserve immutable attempts and protected surfaces | Global, 3-5 | Raw/protected hashes and zero staged paths |

## Self-Review Result

- Spec coverage: every requirement in design sections 2, 4, 5, 6, and 7 maps to a task above; no uncovered requirement remains.
- Placeholder scan: no placeholder marker, deferred implementation, implicit error handling, or unspecified test step remains.
- Interface consistency: `activeRelays`, relay `finish()`/`dispose()`, `upstreamResponse`, projection fields, test name, and both hash-pin consumers use the same names throughout.
- Scope: one evidence-forwarder subsystem only; no product, provider, schema, manifest, or immutable-evidence work is included.
- Execution selection: the user already selected inline, sequential execution in this session and prohibited subagents; no additional handoff choice is required.
