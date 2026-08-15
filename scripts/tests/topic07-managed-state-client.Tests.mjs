import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test, { after } from "node:test";

import * as core from "../../template/.omp/contracts/agent-boundary-core.mjs";
import {
  getManagedSessionRef,
  invokeManagedState,
  parseManagedStateEnvelope,
} from "../../template/.omp/contracts/managed-state-client.mjs";

const fixtureRoot = fs.mkdtempSync(path.join(os.tmpdir(), "topic07-state-client-tests-"));
const fixturePath = path.join(fixtureRoot, "state-fixture.ps1");
const pwshLookup = spawnSync("pwsh", [
  "-NoProfile",
  "-NonInteractive",
  "-Command",
  "(Get-Command pwsh -ErrorAction Stop).Source",
], { encoding: "utf8", windowsHide: true });

assert.equal(pwshLookup.status, 0, "PowerShell 7 is required for the managed-state transport tests");
const pwshPath = pwshLookup.stdout.trim();
assert.equal(path.isAbsolute(pwshPath), true);

fs.writeFileSync(fixturePath, String.raw`
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string] $RequestPath)

$raw = [System.IO.File]::ReadAllText($RequestPath)
$document = $raw | ConvertFrom-Json -Depth 100

function Write-Envelope([bool] $Ok, [string] $Code, [hashtable] $Data, [string] $Operation) {
    $value = [ordered]@{
        code = $Code
        data = $Data
        ok = $Ok
        operation = $Operation
    }
    [Console]::Out.WriteLine(($value | ConvertTo-Json -Compress -Depth 100))
}

switch ($document.operation) {
    'echo' {
        Write-Envelope -Ok $true -Code 'AT-OK' -Operation 'echo' -Data ([ordered]@{
            cwd = (Get-Location).Path
            request_path = $RequestPath
            raw_base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($raw))
        })
    }
    'closed-failure' {
        Write-Envelope -Ok $false -Code 'AT-REFUSED' -Operation 'closed-failure' -Data @{ reason = 'bounded refusal' }
    }
    'closed-failure-nonzero' {
        Write-Envelope -Ok $false -Code 'AT-REFUSED' -Operation 'closed-failure-nonzero' -Data @{ reason = 'bounded refusal' }
        exit 3
    }
    'wrong-operation' {
        Write-Envelope -Ok $true -Code 'AT-OK' -Operation 'different-operation' -Data @{}
    }
    'valid-nonzero' {
        Write-Envelope -Ok $true -Code 'AT-OK' -Operation 'valid-nonzero' -Data @{}
        exit 7
    }
    'malformed' { [Console]::Out.WriteLine('{') }
    'duplicate-key' { [Console]::Out.WriteLine('{"code":"AT-OK","code":"AT-OTHER","data":{},"ok":true,"operation":"duplicate-key"}') }
    'extra-key' { [Console]::Out.WriteLine('{"code":"AT-OK","data":{},"extra":true,"ok":true,"operation":"extra-key"}') }
    'multiple-lines' {
        Write-Envelope -Ok $true -Code 'AT-OK' -Operation 'multiple-lines' -Data @{}
        Write-Envelope -Ok $true -Code 'AT-OK' -Operation 'multiple-lines' -Data @{}
    }
    'stdout-overflow' { [Console]::Out.WriteLine((('x' * 4096) -join '')) }
    'stderr-overflow' {
        [Console]::Error.Write((('e' * 4096) -join ''))
        Start-Sleep -Seconds 10
    }
    'sleep' { Start-Sleep -Seconds 10 }
    default { Write-Envelope -Ok $false -Code 'AT-UNKNOWN' -Operation ([string]$document.operation) -Data @{} }
}
`, "utf8");

after(() => {
  fs.rmSync(fixtureRoot, { recursive: true, force: true });
});

function context(sessionRef = "session-exact-01") {
  return {
    cwd: fixtureRoot,
    sessionManager: { getSessionId: () => sessionRef },
  };
}

function invocation(operation, overrides = {}) {
  return invokeManagedState({
    pwshPath,
    stateCliPath: fixturePath,
    operation,
    request: overrides.request ?? { z: 1, a: "two" },
    ctx: overrides.ctx ?? context(),
    signal: overrides.signal,
    timeoutMs: overrides.timeoutMs ?? 5_000,
    outputLimitBytes: overrides.outputLimitBytes ?? 16_384,
    acceptNonzeroFailureEnvelope: overrides.acceptNonzeroFailureEnvelope ?? false,
  });
}

test("getManagedSessionRef returns only the exact current non-empty session identifier", () => {
  assert.equal(getManagedSessionRef(context("session-case-sensitive-01")), "session-case-sensitive-01");
  for (const ctx of [
    undefined,
    {},
    { sessionManager: {} },
    { sessionManager: { getSessionId: () => "" } },
    { sessionManager: { getSessionId: () => "   " } },
    { sessionManager: { getSessionId: () => 7 } },
    { sessionManager: { getSessionId: () => { throw new Error("private-session-path"); } } },
  ]) assert.throws(() => getManagedSessionRef(ctx), /^Error: state_unavailable$/u);
});

test("invokeManagedState sends one canonical OMP envelope with exact session and absolute cwd", async () => {
  const request = { z: 1, a: "two" };
  const result = await invocation("echo", { request });
  const raw = Buffer.from(result.data.raw_base64, "base64").toString("utf8");
  const expected = core.canonicalJson({
    schema_version: 1,
    operation: "echo",
    working_directory: fixtureRoot,
    session_ref: "session-exact-01",
    runtime: "omp",
    request,
  });
  assert.equal(raw, expected);
  assert.equal(path.resolve(result.data.cwd).toLowerCase(), path.resolve(fixtureRoot).toLowerCase());
  assert.equal(path.isAbsolute(result.data.request_path), true);
  assert.equal(fs.existsSync(path.dirname(result.data.request_path)), false, "the unique request directory must be removed");
});

test("each invocation owns and cleans a different temporary directory", async () => {
  const [left, right] = await Promise.all([invocation("echo"), invocation("echo")]);
  const leftRoot = path.dirname(left.data.request_path);
  const rightRoot = path.dirname(right.data.request_path);
  assert.notEqual(leftRoot.toLowerCase(), rightRoot.toLowerCase());
  assert.equal(fs.existsSync(leftRoot), false);
  assert.equal(fs.existsSync(rightRoot), false);
});

test("parseManagedStateEnvelope accepts closed success and failure records", async () => {
  assert.deepEqual(
    parseManagedStateEnvelope('{"code":"AT-OK","data":{"value":1},"ok":true,"operation":"read"}\n'),
    { code: "AT-OK", data: { value: 1 }, ok: true, operation: "read" },
  );
  const failure = await invocation("closed-failure");
  assert.deepEqual(failure, {
    code: "AT-REFUSED",
    data: { reason: "bounded refusal" },
    ok: false,
    operation: "closed-failure",
  });
});

test("duplicate keys, extra keys, malformed text, extra records, and operation drift fail closed", async () => {
  for (const operation of ["duplicate-key", "extra-key", "malformed", "multiple-lines", "wrong-operation"]) {
    await assert.rejects(invocation(operation), /^Error: state_unavailable$/u);
  }
  for (const text of [
    '{"code":"A","code":"B","data":{},"ok":true,"operation":"x"}',
    '{"code":"A","data":{},"extra":true,"ok":true,"operation":"x"}',
    '{',
    '{"code":"A","data":{},"ok":true,"operation":"x"}\n{"code":"A","data":{},"ok":true,"operation":"x"}\n',
  ]) assert.throws(() => parseManagedStateEnvelope(text), /^Error: state_unavailable$/u);
});

test("nonzero exit and stdout or stderr overflow fail without exposing process output", async () => {
  for (const [operation, outputLimitBytes] of [
    ["valid-nonzero", 16_384],
    ["stdout-overflow", 128],
    ["stderr-overflow", 128],
  ]) {
    await assert.rejects(
      invocation(operation, { outputLimitBytes }),
      (error) => error?.message === "state_unavailable" && !/AT-OK|xxxx|eeee/u.test(error.message),
    );
  }
});

test("an explicit caller may consume only a closed failure envelope from a nonzero state exit", async () => {
  await assert.rejects(invocation("closed-failure-nonzero"), /^Error: state_unavailable$/u);
  assert.deepEqual(
    await invocation("closed-failure-nonzero", { acceptNonzeroFailureEnvelope: true }),
    {
      code: "AT-REFUSED",
      data: { reason: "bounded refusal" },
      ok: false,
      operation: "closed-failure-nonzero",
    },
  );
  await assert.rejects(
    invocation("valid-nonzero", { acceptNonzeroFailureEnvelope: true }),
    /^Error: state_unavailable$/u,
  );
});

test("timeout terminates the state process and returns one bounded diagnostic", async () => {
  const started = Date.now();
  await assert.rejects(invocation("sleep", { timeoutMs: 100 }), /^Error: state_unavailable$/u);
  assert.ok(Date.now() - started < 5_000);
});

test("abort terminates the state process and reports only cancellation", async () => {
  const controller = new AbortController();
  const pending = invocation("sleep", { signal: controller.signal, timeoutMs: 5_000 });
  setTimeout(() => controller.abort(), 50);
  await assert.rejects(pending, /^Error: cancelled$/u);
});

test("all validation and process failures redact request and state contents", async () => {
  const marker = "do-not-leak-request-8f96f6c2";
  const attempts = [
    () => invocation("malformed", { request: { payload: marker } }),
    () => invokeManagedState({
      pwshPath,
      stateCliPath: fixturePath,
      operation: "echo",
      request: { payload: marker },
      ctx: { cwd: "relative/path", sessionManager: { getSessionId: () => marker } },
    }),
  ];
  for (const attempt of attempts) {
    await assert.rejects(attempt(), (error) => error?.message === "state_unavailable" && !error.message.includes(marker));
  }
});
