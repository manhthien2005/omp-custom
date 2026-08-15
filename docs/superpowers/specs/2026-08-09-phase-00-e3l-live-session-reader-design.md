# Phase 00 E3-L Live-Session Reader Design

> **P00-CX-028 correction notice (2026-08-09):** The terminal outcome statements retained
> below are historical. They are superseded by
> `2026-08-09-phase-00-e3il-terminal-precedence-correction-design.md`: joint Attempt 5 is
> `INVALID_RUN / E3IL_NESTED_PROVIDER_RECOVERY`, current E3-L authority is `READY`, and no
> provider retry or parallel execution is authorized.

**Status:** `READY` after P00-CX-028 additive correction; no selected transaction or L1-L3 materialization<br>
**Scope:** Phase 00 experiment E3-L only<br>
**Normative authority:** `spec/phases/phase-00-foundation.md:530-621` and `spec/08-isolation-and-concurrency.md:570-609`<br>
**Parent design:** `docs/superpowers/specs/2026-08-08-phase-00-execution-evidence-design.md`<br>
**Related evidence design:** `docs/superpowers/specs/2026-08-09-phase-00-e3i-parent-overlay-canary-design.md`<br>
**Repository HEAD:** `62fecf277dc9d5e47d06319387eac747462214c1`<br>
**Normative OMP:** `17.2.10` at `3a8591a8af5b6d200088d12ca75a5517cb064fa8`<br>
**Observed non-authoritative runtime delta:** installed `omp/17.2.12`; compatibility-only<br>
**Parallel authority:** `DISABLED`; only E3-M or an equivalent guarded-dispatch mechanism may enable it<br>
**Peer-review state:** Codex design judgment only; Opus review remains pending quota

## 1. Decision

E3-L will evaluate the publicly exported `pi.pi.settings` proxy as a live-settings reader
for one explicitly bounded v0 host class: an OMP-owned default main-CLI root session. The
experiment will exercise that construction class through non-interactive print mode because
it is deterministic and uses the same root settings instance that the interactive text
presentation uses. The supported class excludes ACP-created sessions, arbitrary SDK hosts,
injected `CreateAgentSessionOptions.settings` or `settingsManager`, injected
`runRootCommand` dependencies, and cloned settings instances.

The reader is host-scoped by design. It is not a universal replacement for the missing
`CustomToolContext.settings` bridge. It may produce an E3-L PASS only for the declared main-CLI
root-session class after all three required runtime states and the complete pinned-source
identity chain pass. No result may be generalized to excluded hosts.

E3-L remains observational. Even a scoped PASS proves only that the parent can observe its
live effective value at a point in time. It does not couple the observation to native task
dispatch and therefore grants no parallel authority. E3-M retains sole ownership of the
atomic check-and-dispatch question.

## 2. Why This Is the Narrowest Defensible v0 Scope

The repository defines `/orchestrated` as an OMP command/workflow and tests workflows through
the installed OMP CLI. It does not currently define ACP or arbitrary SDK embedding as a v0
deployment target. The public proxy has a complete same-instance chain on the default
main-CLI path, while pinned source proves non-universality on other paths.

Treating every possible OMP embedder as supported would make E3-L fail before the runtime
experiment because no reviewed public surface joins all of those settings identities.
Conversely, presenting the proxy as universal would contradict explicit clone and injection
paths. The selected boundary preserves the viable CLI path without weakening the evidence or
claiming unsupported host coverage.

The host boundary is a session-construction boundary, not a UI assertion. Interactive text
and print presentations share the same `runRootCommand` settings construction and
`sessionOptions.settings` assignment before the presentation-specific loop runs. ACP instead
constructs a new session around `cloneForCwd()`, and arbitrary SDK callers may inject any
`Settings` instance. RPC and RPC-UI are not included in the v0 support declaration because
their protocol-owned lifecycle and tool surfaces are not part of this experiment.

## 3. Pinned-Source Identity Proof

The default main-CLI candidate must be accepted only if all links below remain true at the
pinned source identity:

1. `packages/coding-agent/src/index.ts:17` publicly exports both `Settings` and `settings`.
2. `config/settings.ts:404-416` shows `Settings.init()` creating one instance, assigning
   that exact object to `globalInstance`, and returning it.
3. `main.ts:1282-1283` initializes `settingsInstance` through `Settings.init(...)` when no
   dependency-injected settings object is present.
4. `main.ts:1533-1545` passes that exact `settingsInstance` as
   `sessionOptions.settings`.
5. `sdk.ts:1271-1274` consumes an explicitly supplied `options.settings` instead of creating
   a second settings object.
6. `task/structured-subagent.ts:315-317` resolves `applyChanges` from
   `request.session.settings.get("task.isolation.apply")` when no private isolation-apply
   value is supplied.
7. `config/settings.ts:2371-2388` delegates exported proxy access to `globalInstance` and
   binds methods to that same object.

For the declared host class, those links join the public proxy reader to the settings object
used by native task dispatch. The empirical cases below must corroborate that source proof;
neither source nor runtime observation is sufficient alone.

### 3.1 Proven exclusions

The following paths are outside the supported v0 host class:

- `main.ts:397-424`: ACP `session/new` uses `args.settings.cloneForCwd(cwd)` and supplies the
  resulting distinct instance to the new session.
- `config/settings.ts:603-620`: `cloneForCwd()` constructs a new `Settings` object and clones
  layers into it.
- `sdk.ts:1271-1273`: SDK callers may inject `options.settings` or
  `options.settingsManager`; neither is required to be the global singleton.
- `main.ts:1282-1283`: dependency-injected `deps.settings` bypasses `Settings.init()`.

The experiment must not infer proxy/session identity on any of those paths. A future host
expansion requires a new source proof, runtime cases, and fail-closed integration design.

## 4. Retired and Rejected Reader Surfaces

### 4.1 Project custom-tool `ctx.settings`

This path is retired. `extensibility/custom-tools/types.ts:85-105` nominally advertises
`settings?: Settings`, but `sdk.ts:885-894,938-955` creates the project custom-tool context
without `settings`. E3-I Attempt 1 reached the real project tool and failed with
`P00_E3I_SETTINGS_UNAVAILABLE`, corroborating the source mismatch.

### 4.2 Connected MCP tool context

`session/session-tools.ts:1295-1314` includes `this.#host.settings` while adapting connected
MCP tools. That is a different adapter. The in-process OMP wrapper receives the context, but
the external MCP server receives an MCP request rather than the live JavaScript `Settings`
object. This path does not provide a project-owned reader and must not be joined to the
project custom-tool bridge.

### 4.3 Custom commands and extension contexts

`HookContext` and `HookCommandContext` at `extensibility/hooks/types.ts:178-253` expose no
settings member. `CustomCommandAPI` at `extensibility/custom-commands/types.ts:21-34`
provides the same injected package namespace and therefore only leads back to the host-scoped
global proxy. `ExtensionContext` likewise has no settings member. These surfaces do not
create a broader identity guarantee.

### 4.4 Runtime patch or upstream OMP change

Adding session settings to the actual project-tool or extension bridge would be the clean
long-term lift. It changes the runtime contract and is outside this template-only Phase 00
slice. The pinned runtime must not be patched locally and the version gate must not be widened
to make E3-L pass.

## 5. Required Normative Correction to Case 3

The current E3-L text describes project `apply:false`, a `/settings` change through
`Settings.set()` to `true`, an expected live result of `true`, and no file change. Those
conditions cannot all hold on pinned `17.2.10`:

- `config/settings.ts:498-505`: `Settings.set()` writes the global settings layer, marks the
  path modified, rebuilds, and queues persistence.
- `modes/components/settings-selector.ts:1272-1282`: the `/settings` selector calls
  `settings.set(...)`.
- `config/settings.ts:2143-2147`: project settings merge after global settings, so a project
  `false` still overrides a global `true`; runtime overrides merge last.
- `config/settings.ts:518-526`: `Settings.override()` changes the in-memory override layer,
  rebuilds synchronously, and does not queue persistence.

Therefore case 3 must use `Settings.override("task.isolation.apply", true)`, not
`/settings`/`Settings.set()`. This is not a relaxation. It is the actual higher-precedence,
non-persistent state transition the case intended to test. The implementation phase must
correct every normative mirror before claiming runtime evidence.

## 6. Runtime Experiment Shape

E3-L and E3-I will share one augmented two-parent-session raw evidence transaction rather
than spend provider quota on a second semantically duplicate experiment. The existing E3-I
transaction does not directly read the live proxy in Session B, so native task behavior alone
cannot supply E3-L's required reader value. The joint transaction must therefore add one
parent-only, read-only `pi.pi.settings.get("task.isolation.apply")` tool call before each
case's task samples. Reuse means both adjudicators consume the same raw attempt independently;
neither conclusion consumes or trusts the other conclusion.

### 6.1 Session A: project state then runtime override

1. Start a disposable main-CLI print session with project
   `task.isolation.apply: false`.
2. Call the parent-only read tool and record the approved reader value: `false`.
3. Run exact child diagnostic
   `omp config get task.isolation.apply --json`; require boolean `false`.
4. Dispatch the sequential control canaries and observe capture-only task summaries.
5. Call the narrowly scoped parent-only override tool, which uses
   `pi.pi.settings.override("task.isolation.apply", true)` and returns fixed before/after
   attestation.
6. Call the read tool again and record the approved reader value: `true` in the same parent
   session. The override tool's before/after attestation is separately required but does not
   replace this reader call.
7. Repeat the child diagnostic; require boolean `false`.
8. Dispatch the post-override canaries and observe the apply-enabled task-summary branch.

The fixture may expose exactly two parent-only tools: one fixed read of
`task.isolation.apply`, and the fixed false-to-true override needed by Session A. Neither tool
may offer an arbitrary setting path or value, call `Settings.set()`, persist settings, run
subprocesses, or write files. The read tool has no mutation method and returns a strict fixed
shape containing the probe identity, setting name, boolean value, operation identity, and
parent-only scope.

### 6.2 Session B: CLI overlay

1. Start a fresh disposable main-CLI print session with the same project
   `apply:false` and a launch `--config` overlay setting `apply:true`.
2. Call the same parent-only read tool and record the approved reader value: `true`.
3. Run the same child diagnostic; require boolean `false` because the child process does not
   inherit the parent's parsed config-file argument.
4. Dispatch sequential canaries and observe the apply-enabled task-summary branch.

### 6.3 Exact case matrix

| Case | Parent setup | Approved reader | Child `omp config get` | Actual task branch |
|---|---|---:|---:|---|
| L1 | project `false` | `false` | `false` | capture-only; summary starts `Isolation:` |
| L2 | project `false`, CLI overlay `true` | `true` | `false` | apply-enabled; summary normalizes to `No changes to apply.` |
| L3 | project `false`, runtime override `true` | `true` | `false` | apply-enabled; summary normalizes to `No changes to apply.` |

L2 and L3 are decisive. They must show the live reader disagreeing with the subprocess
diagnostic and agreeing with the native task behavior in the same selected attempt.

## 7. Evidence Reuse and Attempt Atomicity

E3-L and E3-I may consume the same joint raw attempt only when that complete attempt satisfies
the shared transport, identity, ordering, retry, and mutation-boundary rules. Each experiment
then applies its own case oracle directly to raw events. The following rules are mandatory:

- One selected attempt supplies Session A, Session B, three reader calls, diagnostics, canary
  summaries, mutation boundaries, source/runtime identities, and provider accounting.
- E3-L does not depend on an E3-I PASS conclusion, and E3-I does not depend on an E3-L PASS
  conclusion. Either experiment may fail its own oracle while the other reports its own
  independently justified result.
- No observation may be combined across attempts.
- An attempt containing a terminal provider failure, recovered internal provider retry,
  missing tool result, reordered or extra call, invalid child tool surface, mutation-boundary
  breach, or incomplete Session B is non-selectable.
- E3-L does not reinterpret E3-I Attempts 1-4. Attempts 1-3 remain `INVALID_RUN`; Attempt 4
  remains terminal `BLOCKED_ENVIRONMENT / P00-RUNTIME-PROVIDER-OVERLOAD`.
- A future attempt is permitted only after changed external provider state and explicit user
  authorization, under the existing E3-I retry policy.

The E3-L artifact should be a deterministic projection over a selected raw transaction. It
must re-hash the raw inputs it cites and must fail closed if any referenced identity, event,
or expected branch is absent. It may not duplicate or hand-edit provider transcript content.

## 8. Outcome Taxonomy

### 8.1 PASS

E3-L may record PASS only when:

1. the exact pinned source identity and all seven positive chain links pass;
2. the runtime is exact OMP `17.2.10`, not the installed delta version;
3. the selected attempt satisfies all atomicity and retry-free conditions;
4. L1, L2, and L3 match the matrix exactly;
5. live-home, repository, fixture, and temporary-root boundaries pass;
6. the declared supported host class is recorded with all exclusions; and
7. parallel mode remains disabled with E3-M named as the unresolved enablement gate.

The PASS claim must read: "The approved proxy observes live effective
`task.isolation.apply` for the OMP-owned default main-CLI root-session class on pinned
17.2.10." It must not read "OMP hosts" or "all sessions."

### 8.2 FAIL

A complete valid experiment that contradicts the source identity or any L1-L3 expectation is
a semantic FAIL. Examples include a reader value that follows the child subprocess rather
than parent behavior, an apply branch inconsistent with the reader, or evidence that the
main CLI used a different settings instance.

### 8.3 BLOCKED_ENVIRONMENT

Provider overload, authentication failure, unavailable gateway, or another external failure
that prevents a complete valid attempt is `BLOCKED_ENVIRONMENT`, not semantic FAIL. Partial
observations have no PASS power. The current E3-I terminal state therefore leaves E3-L
runtime adjudication pending; this design document alone cannot change the manifest to PASS.

### 8.4 INVALID_RUN

Harness, protocol, artifact, retry, ordering, or mutation-boundary violations invalidate the
attempt. They require correction and a newly authorized fresh attempt; they cannot be
reported as product behavior.

## 9. Safety and Mutation Boundaries

- Use exact pinned `omp.exe` identity through process-local PATH precedence. Do not replace
  the live installed `17.2.12` binary.
- Use disposable `HOME`, agent directory, project, sessions directory, config overlay, and
  evidence staging root.
- Make no write to the user's live OMP home and never copy credentials into evidence.
- Keep canaries sequential and blocking. E3-L is not a parallel experiment.
- The override tool is parent-only and must not be available in canary child sessions.
- Require pre/post repository state, live-home inventory, fixture inventory, and temporary
  root checks.
- Preserve every invalid or blocked raw attempt additively. Do not overwrite or delete prior
  evidence.
- Make no Git branch, worktree, stage, commit, push, or pull-request mutation.

## 10. Installed 17.2.12 Compatibility Finding

The user's OMP update changed only the active runtime precondition for the reviewed Phase 00
gates. The live executable identifies as `omp/17.2.12` with SHA-256
`C21A8921CA26C6C6341A067F0F384184D92AC3CF221A26A90CFDD60CEB71F03C`.
The preserved `17.2.10` executable has SHA-256
`1525122BC49A6E5F79FB1C58B6B1916CECFCFFAF2E82080769F7F0FA296BC8A6`.

A fresh unpinned PowerShell 7 gate produced the expected single version-identity failure in
E3-A/E3-H: 43 passed / 1 failed. All other suites remained green. A process-local temporary
copy of the exact `17.2.10` binary restored complete green gates in both PowerShell 7 and
Windows PowerShell 5.1:

```yaml
phase00_wave_a: {passed: 26, failed: 0, skipped: 0}
phase00_e3j_e3k: {passed: 35, failed: 0, skipped: 0}
phase00_e3a_e3h: {passed: 44, failed: 0, skipped: 0}
phase00_e3i: {passed: 42, failed: 0, skipped: 0}
validator: {passed: 89, warnings: 0, failed: 0, exit_code: 0}
```

Accordingly, `17.2.12` is a non-authoritative compatibility delta only. The design must not
change the Phase 00 pin, registry commit, version assertion, or source anchors.

## 11. Planned Artifacts and Contract Mutations

After this design passes user review, the implementation plan may propose:

1. focused E3-L tests written RED before any runner/adjudicator mutation;
2. a parent-only fixed reader fixture plus deterministic E3-L adjudication over the joint raw
   evidence transaction;
3. an E3-L conclusion artifact containing source identity, host scope, L1-L3 rows, hashes,
   and explicit non-claims;
4. manifest wiring that cannot record PASS without the complete selected attempt;
5. normative corrections replacing `/settings`/`Settings.set()` with
   `Settings.override()` and declaring the v0 host boundary; and
6. validator wiring that keeps one repository validation entrypoint.

Exact file ownership, RED/GREEN commands, mutation sequence, and rollback points belong in
the implementation plan, not this design. No item above is implemented by this document.

## 12. Verification Strategy

The future implementation must verify, in order:

1. focused source-audit and adjudicator unit tests;
2. malformed, missing, cross-attempt, provider-failure, retry, wrong-host, wrong-version, and
   partial-Session-B negative controls;
3. complete E3-L focused suite under pinned `17.2.10`;
4. existing E3-I suite to prove evidence reuse did not weaken its terminal state;
5. Phase 00 Wave A, E3-J/K, E3-A/H, E3-I, and repository validator in PowerShell 7;
6. the same complete gate in Windows PowerShell 5.1; and
7. final hashes, `git diff --check`, zero staged files, zero leaked temporary roots, no
   provider call during static closure verification, and unchanged parallel mode.

Provider-backed runtime execution is a separately authorized checkpoint. Static design,
tests, parser work, and source audit do not authorize a new provider attempt.

## 13. Alternatives Considered

### Alternative A: Require a universal reader and record E3-L FAIL now

This is maximally conservative but collapses "unsupported host" into "no viable host." It
would ignore the complete default-main-CLI identity chain and permanently block useful
characterization without additional safety, because parallel is already disabled by E3-M.

### Alternative B: Treat `pi.pi.settings` as universal

Rejected. ACP clone and SDK injection paths directly disprove universal identity. A broad
PASS would be false.

### Alternative C: Patch OMP or depend on a newer runtime

Rejected for Phase 00. It changes the runtime contract, invalidates the pinned evidence
identity, and moves outside template ownership. It remains the clean long-term lift if OMP
officially exposes the live session settings object on the project tool or extension context.

The selected host-scoped design is the only option that preserves both the positive CLI
evidence and the negative cross-host evidence without granting unsafe authority.

## 14. Runtime Implementation Status

The reviewed static implementation remains complete. After separate user authorization,
joint runtime Attempt 5 launched Session A once under the exact pinned runtime. The parent
ended on terminal OmniRoute `server_is_overloaded`; provider-capacity precedence classified
the transaction `BLOCKED_ENVIRONMENT / P00-RUNTIME-PROVIDER-OVERLOAD` and prevented Session B.
No retry or Attempt 6 was launched.

The original joint envelope is preserved at
`docs/evidence/phase-00/E3-L/raw/joint-attempt-005.json`. Its retry summary under-reported one
recovered nested provider retry in `e3i-runtime-3`, so it was not rewritten. A corrected,
hash-linked adjudication sidecar records that raw fact while retaining parent-terminal block
precedence:

- `docs/evidence/phase-00/E3-L/raw/joint-attempt-005.adjudication.json` at SHA-256
  `C1D2307FDC3237477D50CA3C309A17E6A42EC9E2539A0D41D822180737BF0B5D`;
- `docs/evidence/phase-00/E3-L/conclusion.json` at SHA-256
  `0BC95B726B10EDCC79BFB44247F4C02C585939A72E3B0D279071851C20AB28E6`.

The manifest records E3-L `BLOCKED_ENVIRONMENT` with only those terminal adjudication and
conclusion artifacts. It does not list the static source identity as runtime authority.

The deterministic source proof is
`docs/evidence/phase-00/E3-L/source-identity.json` at SHA-256
`CE7B3DF1446788C2996521172FD2BB7B124E1DBBDB854F2E0FBD990FF5EA32FD`.
Implemented surfaces are:

- `scripts/lib/phase00-e3il-transport.ps1`;
- `scripts/lib/phase00-e3l-evidence.ps1`;
- `scripts/run-phase00-e3l-joint.ps1` and the augmented `scripts/run-phase00-e3i.ps1`;
- the parent-only tool factory and exact Session A/B prompts under
  `docs/evidence/phase-00/E3-I/fixture/`;
- `scripts/tests/phase00-e3l.Tests.ps1` and the augmented E3-I/E3-A-H tests; and
- `scripts/lib/phase00-evidence.ps1` plus `scripts/validate-template.ps1` durable wiring.

No selected transaction or L1-L3 artifact exists. E3-M remains
`DEFERRED_PARALLEL_DISABLED`, root parallel mode remains `DISABLED`, and Opus peer review
remains pending quota.

## 15. Explicit Non-Claims and Opus Review Targets

This terminal block does not select an E3-I or E3-L attempt, establish any L1-L3 semantic
observation, resolve the provider block, pass or fail E3-L, attempt E3-M, or enable parallel
execution. It does not claim interactive UI behavior was separately sampled; it defines and
source-proves a shared main-CLI root-session construction class and used print mode as the
deterministic runtime presentation for that class. Codex's blocked adjudication is provisional
pending equal Opus review.

When Opus quota returns, peer review should independently challenge at least:

1. whether the main-CLI root-session class is a legitimate and sufficiently explicit v0 host
   boundary;
2. whether interactive text and print presentations truly share every identity-relevant
   construction link;
3. whether RPC/RPC-UI, ACP, injected SDK, and injected dependency exclusions are complete;
4. whether the seven-link proxy-to-dispatch source proof has any hidden instance swap;
5. whether the MCP adapter analysis accidentally omits a public live-object escape;
6. whether replacing `/settings` with `Settings.override()` is the exact intended contract
   correction rather than a weakened test;
7. whether the joint raw transaction and independent adjudicators eliminate circular verdict
   ownership and cross-attempt contamination;
8. whether L1-L3 reader, child diagnostic, and task-branch correlations are independently
   falsifiable;
9. whether the outcome taxonomy correctly separates semantic failure, invalid harness, and
   external provider block; and
10. whether every PASS statement remains observation-only and leaves E3-M and parallel mode
    untouched.
