# Repo Report — oh-my-pi (orchestration: `task` vs `eval`)

> Authority boundary: This repository report is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.


> **Path:** `_research/upstreams/oh-my-pi`
> **SHA:** `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (`git -C _research/upstreams/oh-my-pi rev-parse HEAD`)
> **License:** MIT. `LICENSE` reads `MIT License / Copyright (c) 2025 Mario Zechner / Copyright (c) 2025-2026 Can Bölük`. Two copyright holders, one MIT grant. No in-file grant headers found in the files read this pass.
> **Size:** 6323 tracked files (`git ls-files | wc -l`)
> **Read this pass:** Full: `eval/agent-bridge.ts`, `eval/concurrency-bridge.ts`, `eval/budget-bridge.ts`, `eval/bridge-timeout.ts`, `eval/js/tool-bridge.ts`, `eval/js/shared/prelude.txt`, `eval/session-id.ts`, `task/structured-subagent.ts`, `task/isolation-runner.ts`, `task/parallel.ts`, `task/spawn-policy.ts`, `task/provider-concurrency.ts`, `prompts/system/workflow-notice.md`, `prompts/tools/eval.md`, `prompts/tools/task.md`, `prompts/tools/task-summary.md`, `modes/workflow.ts`, `modes/magic-keywords.ts`, `modes/markdown-prose.ts`, `capability/slash-command.ts`. Substantial: `task/index.ts` (~700 of 1515 lines), `task/types.ts` (1-200, 460-555), `task/worktree.ts` (targeted), `tools/eval.ts` (240-360, 495-760), `session/agent-session.ts` (4855-5000), `session/session-manager.ts` (139-290, 1780-1835), `discovery/builtin.ts` + `discovery/agents.ts` (command loading), `extensibility/slash-commands.ts` (95-131).
> **Scope of this report:** narrower than the standard per-repo contract — it answers a single decision (`task` vs `eval` as the orchestration substrate) rather than inventorying the whole runtime. §2/§3 are scoped accordingly.

## 1. What this repo is

OMP is the runtime. This report covers exactly one question inside it: OMP ships **two** subagent-orchestration frontends over **one** shared engine. `task` is a declarative tool whose arguments the model writes as JSON; `eval` is a persistent code kernel whose `agent()` helper calls the same engine from inside Python/JS/Ruby/Julia. Both funnel into `runStructuredSubagent()` at `task/structured-subagent.ts:547`. Neither is a wrapper around the other.

The headline structural fact, which the spec's six rounds did not have: **`task` and `eval.agent()` are peers, not layers.** `task/index.ts:1403` and `eval/agent-bridge.ts:145` are two callers of the same function, and `task/isolation-runner.ts:5-8` says so explicitly — "the orchestration is identical for both callers; this module hosts the shared lifecycle so eval `agent()` does not need to round-trip through `TaskTool.#runSpawn`."

---

## 2. Capability comparison

Every row traced to both call sites. `SS` = `task/structured-subagent.ts`.

| Capability | `task` tool | `eval.agent()` | Verdict |
|---|---|---|---|
| **Engine** | `runStructuredSubagent` @ `task/index.ts:1403` | `runStructuredSubagent` @ `eval/agent-bridge.ts:145` | **Identical.** Same function. |
| **Per-call isolation** | `isolated?: boolean` in wire schema (`task/types.ts:156`, batch item `:128`); forwarded `task/index.ts:1418` | `isolated?: boolean` (`eval/agent-bridge.ts:29`); forwarded `:135` | **Equal.** Both gate on `task.isolation.mode !== "none"` (`SS:295-302`). |
| **Per-call apply / capture-only** | **NOT EXPOSED.** No `apply` field in any of the four task schemas (`task/types.ts:114-176`). Session-wide `task.isolation.apply` only (`SS:317`). | `apply?: boolean` (`eval/agent-bridge.ts:30`), forwarded `:137` | **`eval` only.** The single largest asymmetry. |
| **Per-call merge mode** | **NOT EXPOSED.** Session-wide `task.isolation.merge` only (`SS:314`). | `merge?: boolean` — `merge:false` ⇒ `"patch"` (`eval/agent-bridge.ts:136`). Note: **cannot select `"branch"`**; the boolean maps `false→patch`, absent→setting. | **`eval` partial only.** Neither surface can request `branch` per-call. |
| **apply default** | `task.isolation.apply` setting, default `true` (`settings-schema.ts:4497-4499`) | Hard-coded `true` when unset (`SS:317`: `invocationKind === "task" ? settings.get(...) : true`) — **`eval` ignores the user's `task.isolation.apply=false`** | **Divergence.** An `eval` caller must pass `apply:false` explicitly; the setting does not protect it. |
| **Artifact retention** | Session artifacts dir when a session file exists (`SS:351-355`); temp dir + auto-`rm` otherwise (`SS:356-362`, `:651-669`) | Same, plus `handle:true ⇒ retainArtifacts` (`eval/agent-bridge.ts:154`) which survives cleanup via `SS:653` | **`eval` only** for the retained-handle path. `retainArtifacts` has exactly one caller — the eval bridge. |
| **Structured output / schema** | `outputSchema` + `schemaMode` (`task/types.ts:118-119`, forwarded `task/index.ts:1409-1410`) | `schema` + `schemaMode` (`eval/agent-bridge.ts:27-28`, forwarded `:150-151`) | **Equal capability, opposite naming.** `task` *rejects* the field name `schema` (`task/index.ts:196-197`); `eval` requires it. |
| **Structured data delivery** | Validated data lives in `result.structuredOutput` on `details.results[0]` (`task/types.ts:489`). Model-visible text is a rendered `<task-result>` template (`prompts/tools/task-summary.md`); the model must read prose. `details` never reaches the provider — `buildToolResultBlock` sends `msg.content` only (`packages/ai/src/providers/anthropic.ts:3667-3694`). | `data` returned as a **live language value** to the kernel (`eval/agent-bridge.ts:204`), unwrapped by the prelude at `eval/js/shared/prelude.txt:113-121`. Code branches on the object. | **`eval` is categorically stronger.** This is the difference between "the model parses its own subagent's prose" and "code branches on a validated object." |
| **Ordered fan-out** | Batch `tasks[]` (`task/types.ts:167-171`, `task.batch` default `true`); merged in input order via `mergeSyncPayloads` (`task/index.ts:341-359`) | `parallel(thunks)` order-preserving (`prelude.txt:141-173`); `pipeline` with an inter-stage barrier (`:175-182`) | **`eval` stronger.** `task` gives one flat wave; `eval` gives waves, barriers, and per-item chains. |
| **Concurrency bound** | `Semaphore` per `TaskTool` instance (= per session), resized live from `task.maxConcurrency` before every acquire (`task/index.ts:613-621`), default 32 (`settings-schema.ts:4594-4596`) | `runEvalConcurrency` reads the **same setting** (`eval/concurrency-bridge.ts:31-33`) but returns it as a **number** the prelude uses to size its own local pool (`prelude.txt:131-146`) | **Not equivalent.** `task` shares one real semaphore across the session; `eval` pools are *independent per `parallel()` call*, and `prelude.txt:89` in the notice admits it: "Nested `parallel()` pools each cap independently." An eval fan-out can exceed `task.maxConcurrency` in aggregate. |
| **Token budget** | **None.** No `getTurnBudget` check anywhere on the task path (grep: only `eval/agent-bridge.ts:126`, `eval/budget-bridge.ts:34`, `sdk.ts:1766`, `session-manager.ts:1806`, `tools/index.ts:320`). | Hard pre-spawn refusal (`eval/agent-bridge.ts:126-131`) + readable `budget` object (`eval/budget-bridge.ts:33-47`) | **`eval` only.** But see §5 — the accounting is broken. |
| **Turn budget accounting** | Task usage rolls into session usage: `entryUsage` credits `toolName === "task"` details (`session-manager.ts:149`) | `recordEvalSubagentUsage` is **declared** (`tools/index.ts:322`), **wired** (`sdk.ts:1767`), and **never called** — no producer anywhere in the repo except tests | **Defect.** See §5.1. |
| **Recursion depth** | `canSpawnAtDepth(task.maxRecursionDepth, taskDepth)` (`SS:216-223`), default 2 | Same code path, same call | **Identical.** `eval` inherits it because it shares the preflight. |
| **Self-recursion block** | `blockedAgent` passed (`task/index.ts:1419`) | **Not passed** — falls through to `$env.PI_BLOCKED_AGENT` (`SS:224`) | **`task` stronger.** In-process guard is task-only; eval relies on the env var. |
| **Wall-clock timeout** | `task.maxRuntimeMs` explicitly (`task/index.ts:1422`), default 0 = unlimited | `maxRuntimeMs` deliberately omitted so the executor inherits the same setting (`eval/agent-bridge.ts:156-158`, resolved at `task/executor.ts:2657-2659`) | **Equal, by an explicit past bugfix.** The comment records that pinning it to 0 "silently overrode the user's wall-clock cap." |
| **Cell timeout interaction** | n/a | `withBridgeTimeoutPause` suspends the eval watchdog for the whole `agent()` call (`eval/bridge-timeout.ts:45-65`, consumed `tools/eval.ts:576-583`), with `deferExternalAbort:true` (`eval/agent-bridge.ts:165`) holding kernel teardown off until merge finishes | **`eval` handled correctly.** A long subagent does not trip the cell timeout. |
| **Failure surfacing** | Never throws. Returns a text payload — `Task execution failed: …` (`task/index.ts:1443-1453`) or a `status="failed (exit N)"` `<task-result>` (`:1464-1470`). The *model* must notice. | Throws `ToolError` into the kernel (`eval/agent-bridge.ts:168-190`), which the language raises as an exception — catchable, or it aborts the cell | **Categorically different, and this is the crux.** `task` failures are prose the model may skim past. `eval` failures are control flow. |
| **Fan-out failure semantics** | `mapWithConcurrencyLimitAllSettled` — every item settles, rejections captured positionally (`task/parallel.ts:100-127`) | `__pool` barrier: all settle, then the **lowest-index** error propagates (`prelude.txt:151-166`), explicitly to avoid orphaning live subagents | **Both correct, both all-settled.** `eval` surfaces one error; `task` surfaces all as text. |
| **Telemetry returned** | Rich `SingleResult` in `details` (`task/types.ts:472-540`): tokens, requests, contextTokens, contextWindow, usage, cost, resolvedModel, retryFailure, outputMeta — **for the UI only.** Model sees the rendered template. | Narrow `details` (`eval/agent-bridge.ts:58-72`): agent, id, model, schema*, isolated, patchPath, branchName, nestedPatches, changesApplied, isolationSummary — **as a program value.** No tokens, no cost, no requests. | **Different axes.** `task` has more fields for humans; `eval` has fewer fields but they are *actionable in code*. Neither gives the eval program a token count. |
| **Progress streaming** | `onProgress` → `onUpdate` → live TUI rows (`task/index.ts:1424-1435`) | `onProgress` → `emitProgressStatus` → `JsStatusEvent` (`eval/agent-bridge.ts:88-108`), upserted into cell status events (`tools/eval.ts:584-586`) | **Equal.** Both stream. |
| **State across calls** | **None.** Each `task` call is independent; the only cross-call carrier is the transcript, or `agent://<id>` / `history://<id>` reads. | Kernel state persists per `sessionId = session:<file>:cwd:<cwd>` (`eval/session-id.ts:5-7`), wiped only by `reset` (`tools/eval.ts:89`). Variables survive into the next cell (`prompts/tools/eval.md:44`). | **`eval` only.** This is what makes multi-turn `discover → fan out → gate` possible without re-deriving the work list. |
| **Child eval kernel** | Task children **share the parent's** eval session (`SS:446`, since `shareEvalSession` is unset) | Bridge children get `shareEvalSession:false` (`eval/agent-bridge.ts:159`) ⇒ `parentEvalSessionId: undefined` | **Divergence, correct in both.** An eval-spawned child must not mutate the orchestrating kernel. |
| **Registry liveness / resumability** | `keepAlive` defaults on (`task/executor.ts:3322,3330`); a soft-budget-stopped agent stays messageable and the template says so (`task/index.ts:1482-1485`, `task-summary.md:4`) | `keepAlive:false` (`eval/agent-bridge.ts:155`) ⇒ one-shot: dispose + unregister (`task/executor.ts:2440-2444`) | **`task` only.** No resuming an eval-spawned subagent. Its output survives at `agent://<id>` when `handle:true`; the *agent* does not. |
| **Async / background** | Real background jobs via `AsyncJobManager` (`task/index.ts:1074-1214`), `async.enabled` default `true` | **None.** `workflow-notice.md:23`: "Everything runs INLINE and synchronously inside the eval call — no background mode, no resume." | **`task` only.** |
| **Approval tier** | `approval = "exec"` (`task/index.ts:487`) | `approval = "exec"` (`tools/eval.ts:282`) | **Identical.** No approval advantage either way. |

### 2.1 The one-paragraph version

`eval` wins on everything that makes orchestration *deterministic*: per-call apply, structured data as a program value, staged fan-out, exceptions instead of prose, cross-call state, retained handles. `task` wins on everything that makes a subagent *durable*: background jobs, a live resumable registry, IRC follow-up, and per-call `blockedAgent`. They are not competing implementations of one idea — they are the synchronous-deterministic and the asynchronous-durable halves of the same engine.

---

## 3. Failure modes, traced

### 3.1 Your step-2 claim: **CONFIRMED.** Both throws are unreachable under `apply=false`.

I traced it independently and reached your conclusion by the same route, with one addition you did not state.

**The two throws.**
- `eval/agent-bridge.ts:175-181` — `if (policy.isIsolated && changesApplied === false)`.
- `eval/agent-bridge.ts:185-190` — `if (structured && mergeSummary.includes("<system-notification>"))`.

**Throw 1 requires `changesApplied === false`.** `changesApplied` is initialized `null` at `SS:550` and assigned in exactly one place: `SS:611`, `changesApplied = outcome.changesApplied`, inside the block guarded at `SS:597-604`, whose conditions include `policy.applyChanges`. With `apply:false`, `policy.applyChanges` is `false` (`SS:316`), the block is skipped, control lands in the `else if` at `SS:625`, and `changesApplied` is still `null`. `null === false` is `false`. **Unreachable.** Confirmed.

**Throw 2 requires `<system-notification>` in `mergeSummary`.** `mergeSummary` starts `""` (`SS:551`). Under `apply=false` the only writer is `SS:625-633`, four plain template strings — `` `Isolation: changes captured on branch \`…\` (apply=false). Not merged.` `` and siblings. No markup. I also confirmed by exhaustive grep that every `<system-notification>` producer in the repo lives in `task/isolation-runner.ts` — `:288`, `:323`, `:326`, `:388`, `:396` (all inside `mergeIsolatedChanges`) and `:439`, `:442` (inside `applyEligibleNestedPatches`). Both functions are called **only** from the `policy.applyChanges` branch at `SS:605` and `SS:613`. **Unreachable.** Confirmed.

**The addition.** Throw 2 has a *second* independent guard you did not mention: `structured`, defined at `eval/agent-bridge.ts:184` as `structuredOutput?.source !== undefined && source !== "none"`. So even with `apply=true`, a **nested-repo patch failure on an unstructured `agent()` call does not throw.** The summary is silently concatenated into the returned text at `:194` (`result.output + mergeSummary`) and handed to the calling program as an ordinary string. A program doing `const r = await agent(prompt, { isolated: true })` gets a string containing `<system-notification>Some nested repository patches failed to apply.</system-notification>` and no exception. Whether it notices depends on whether the program greps its own return value. That is a real silent-loss channel, distinct from the one in §3.2, and it is wider than the throw suggests. Grade **A** (`eval/agent-bridge.ts:184-194`, `isolation-runner.ts:439-443`).

**Net for the spec:** every `eval.agent()` throw that mentions isolation is dead code under `apply=false`. If our design uses `apply:false` — which per-call capture-only is the whole reason to prefer `eval` — then `eval`'s exception-based failure surfacing does **not** cover isolation. It covers subagent failure (`:168-174`, which fires on `exitCode !== 0 || error || aborted` regardless of apply) and budget exhaustion (`:126`). Isolation outcomes under `apply=false` arrive as **strings the program must inspect**: `details.patchPath`, `details.branchName`, `details.nestedPatches`, `details.isolationSummary`, all exposed via `handle:true` (`prelude.txt:122-124`). That is checkable in code, which is still far better than `task`, but it is *not* automatic.

### 3.2 `task` failure modes

- **Tool-level failure** (preflight, isolation setup): returns text `Task execution failed: <msg>` with `results: []` (`task/index.ts:1443-1453`). Not an error result — `isError` is not set. The model sees a sentence.
- **Child failure**: `status` string in the template — `"failed (exit N)"`, `"merge failed"`, `"cancelled"` (`:1464-1470`). Again prose.
- **Merge failure**: `mergeSummary` with `<system-notification>` markup lands inside `<merge-summary>` in the rendered template (`task-summary.md:15-19`). The markup is *not* stripped on the task path — it is a deliberate attention signal, and `task/render.ts:1661` keys the TUI off it.
- **Batch partial failure**: each item's text is concatenated (`task/index.ts:1283-1293`). A 12-item batch where item 7 failed produces one text block; nothing structurally distinguishes the failure.

The asymmetry is stark and it is the strongest argument for `eval`: on the `task` path *every* failure is a string the model may or may not read carefully. On the `eval` path, subagent failure and budget exhaustion are exceptions that stop the program.

### 3.3 Nested-repo silent loss — your step 3

**Confirmed, and it is worse than "one caller."**

`persistNestedPatches` (`SS:494-511`) has exactly one caller: `isolationRecoveryHint` (`SS:516`). `isolationRecoveryHint` has exactly one caller: the exported `buildStructuredSubagentRecoveryHint` (`SS:674-676`). That export has **three** call sites, and all three are in `eval/agent-bridge.ts` — `:172`, `:177`, `:186`. Verified by exhaustive grep across all of `src/`.

Therefore:

**On the `task` path, `persistNestedPatches` is never reached. At all.** `task/index.ts` does not import or call `buildStructuredSubagentRecoveryHint`. `nestedPatches` on the task path exists only in `SS` internals (`:595`, `:623`, `:630-631`) and in `isolation-runner.ts`. `task/render.ts` shows `patchPath` and `branchName` (`:1391-1394`) and **never** `nestedPatches`. So when an isolated `task` subagent modifies a nested repo and the nested apply fails, the patch text lives in `result.nestedPatches` in memory, is never written to disk, the worktree is torn down in the `finally` at `isolation-runner.ts:234-248`, and the only trace is a `<system-notification>` sentence in the merge summary. **The nested diff is destroyed.** Grade **A**.

On the `eval` path the same loss occurs whenever no throw fires — which, per §3.1, is *always* under `apply=false`, and also under `apply=true` for unstructured calls. `persistNestedPatches` only runs on the three throw paths.

**Decision for the spec:** the "any nested repo disables parallel isolation" rule **cannot be relaxed on either path.** It is not a `task`-specific limitation the spec could shed by moving to `eval`. `eval` narrows the loss window (structured + `apply=true` + nested failure ⇒ patches persisted with a recovery hint) but does not close it, and the configuration our design most wants — `apply=false` — is precisely the one with zero coverage. Keep the rule. Grade **A**.

---

## 4. Can a `.omp/commands/*.md` body drive `eval` reliably?

### 4.1 What has to be true

**(a) The command body is just prose prepended to the user's turn.** `expandSlashCommand` (`extensibility/slash-commands.ts:113-131`) substitutes args and returns the body as the new `text`. It is passed straight into the normal prompt path (`session/agent-session.ts:4964`). There is **no execution semantics** — a command body cannot *call* `eval`, it can only *instruct the model to*. Grade **A**.

**(b) `.omp/commands/` is a real load path.** `discovery/builtin.ts:340-361` loads `<configDir>/commands/*.md`, where config dirs are the project `.omp/` (`:61-64`) and the profile agent dir (`:67-70`). Non-recursive, `.md` only, filename minus extension becomes the name. Grade **A**.

**(c) `eval` must be an active tool with a working backend.** `loadMode = "essential"` (`tools/eval.ts:293`), so it is not lazily gated. But `agent()` is only *documented* in the tool description when `spawns` is truthy (`prompts/tools/eval.md:23-26`), and the helper exists unconditionally in the prelude (`prelude.txt:284`). The real gate is preflight: `resolveSpawnPolicy` (`SS:231-237`) throws for a disallowed agent. Language availability is separately gated (`tools/eval.ts:240-270`); JS is the fallback and needs no external interpreter.

**(d) The `workflowz` keyword is NOT required — and cannot be triggered from a command body anyway.** Two independent reasons:

1. **Prose-masking.** `containsWorkflow` runs `keywordInProse` (`modes/workflow.ts:41-43`), which masks fenced code blocks, inline code spans, **and every XML/HTML section including its enclosed content** (`modes/markdown-prose.ts:162-236`). Any command body that wraps its instructions in tags — which is the house style throughout OMP's own prompts — masks the keyword out. Grade **A**.
2. **Detection runs on the expanded text** (`agent-session.ts:4969` then `:4974`), so a body *could* in principle trigger it if the keyword sat in bare prose. But two more gates apply: `magicKeywords.enabled && magicKeywords.workflow` (`:4878-4879`, both default `true`, `settings-schema.ts:1904-1911`), **and** `options?.synthetic` must be falsy (`:4974`), **and** — the hard one — `activeToolNames` must include **both** `task` and `eval` (`:4909`). Disable either tool and the notice silently does not fire.

So `workflowz` is an availability-dependent nudge, not a mechanism. A command body should state its orchestration intent directly rather than depend on it. Grade **A**.

**(e) Cost of the notice, if you do use it.** `workflow-notice.md` is 112 lines, ~1,900 tokens by rough estimate (basis: 112 lines of dense prose with two full code examples per section, ~17 tokens/line), injected as a hidden `CustomMessage` per triggering turn (`agent-session.ts:4910-4921`). Cost tier: **per-turn, on trigger**. It is not persistent and never enters a subagent.

### 4.2 The review and debuggability cost of code-in-a-command-body

This is the part I would not soften.

**Against code-in-prose:**

- **The body is a *template*, not a program.** `prompt.render(substituted, { args, ARGUMENTS, arguments })` runs over the whole body (`slash-commands.ts:126`) — including any code you embed. A `{{...}}` sequence inside a JS template literal or a Python f-string is interpreted by the *renderer*, before the model ever sees it. There is no escape hatch documented and none in the code read. Any command body carrying real code carries a live footgun. Grade **A**.
- **Nothing validates it.** `slashCommandCapability.validate` checks `name`, `path`, and `content !== undefined` (`capability/slash-command.ts:31-39`). No syntax check, no lint, no test hook. A broken orchestration script fails at model-execution time, in a specific session, with a stack trace inside a tool result.
- **The model is a lossy channel.** The body instructs; the model *retypes* the code into an `eval` call. There is no guarantee of fidelity. You are not shipping a script — you are shipping a suggestion of a script. Two runs of the same command can produce different orchestration code. This is the single most important cost and it applies to `task` prose equally, but it hurts more here because code has exact semantics that prose does not.
- **Review is not code review.** A reviewer reading the markdown cannot tell whether the JS is correct without mentally running it against the prelude's exact API — including that `parallel()` takes *thunks not promises* (`prelude.txt:171`), that JS options are one trailing object never positional (`prompts/tools/eval.md:12`), and that closure capture in loops needs binding (`workflow-notice.md:17`).

**For code-in-prose:**

- **Failure becomes control flow.** The §3.2 vs §3.1 contrast is not cosmetic. A prose-directed `task` batch where item 7 failed yields text the model may skim. An `eval` program where `agent()` threw stops. For a gate ("only proceed if ≥2 of 3 verifiers survived"), that is the difference between a gate and a suggestion.
- **The gate is auditable after the fact.** The cell code is in the transcript verbatim. You can read exactly what ran. Prose-directed `task` calls leave you reconstructing intent from a sequence of tool calls.
- **`apply=false` is only reachable here.** Per §2, `task` has no per-call apply. If per-call capture-only matters to the design, `eval` is not a preference, it is the only option.

**My judgment (grade C):** a command body should carry **the contract, not the code** — the phases, the schemas, the gate thresholds, the fan-out shape, stated as requirements — and let the model author the cell. Embedding literal code buys apparent determinism you do not actually get (the model retypes it) while paying the `prompt.render` footgun and unreviewable-markdown costs in full. The one exception worth carving out: **JSON Schema literals**. Those are data, are the thing most worth pinning exactly, and are what both `outputSchema` and `schema` consume. Pin the schemas; describe the control flow.

---

## 5. Contradictions with the spec / defects found

### 5.1 `eval` budget enforcement is structurally incomplete — a defect in OMP, not in our spec

`eval/agent-bridge.ts:126-131` refuses to spawn when `turnBudget.spent >= turnBudget.total`. `spent` comes from `getTurnBudget()` = `mainOutput + #turnEvalOutput` (`session-manager.ts:1806-1809`). `#turnEvalOutput` is only ever incremented by `recordEvalSubagentOutput` (`:1802-1803`), reachable only through the `ToolSession.recordEvalSubagentUsage` hook (`tools/index.ts:322`), wired in `sdk.ts:1767`.

**That hook is never called.** Exhaustive grep across the whole repo returns exactly three non-test hits: the interface declaration, the `sdk.ts` wiring, and the `session-manager` implementation. The only callers of `recordEvalSubagentOutput` are `test/core/turn-budget.test.ts:39,40,44,45,52`. Grade **A**.

Consequence: `#turnEvalOutput` stays 0 in production. `spent` reflects only the **main loop's** output tokens. And `mainOutput` derives from `#index.usageSnapshot()`, which credits assistant messages and `toolName === "task"` results (`session-manager.ts:145-150`) — **`eval` is not in that list.** So tokens burned by `eval.agent()` subagents are invisible to the very budget check that is supposed to bound them.

Practical reading: a `+Nk!` hard budget bounds how much the *orchestrator* writes, not how much its fan-out spends. A 40-way `parallel()` of `agent()` calls can burn arbitrary output tokens and `budget.spent()` barely moves. **`budget` is not a spend cap on eval fan-outs.** Do not record it as one. Grade **A**.

### 5.2 `eval.agent()` ignores `task.isolation.apply`

`SS:315-317`: `applyChanges: request.isolation?.apply ?? (invocationKind === "task" ? settings.get("task.isolation.apply") : true)`. A user who sets `task.isolation.apply = false` to keep isolated changes out of their checkout is protected on the `task` path and **not** on the `eval` path. Every `eval.agent(…, {isolated: true})` that omits `apply` merges into the parent repo. Grade **A**. Any spec rule phrased as "the session setting governs apply" is false for `eval`.

### 5.3 `eval` pools do not honor the session concurrency ceiling in aggregate

`task` shares one live-resized `Semaphore` per session (`task/index.ts:613-621`). `eval` reads the *number* and each `parallel()` sizes its own pool from it (`prelude.txt:141-146`); `__pool` holds no shared permit. Nested pools multiply — acknowledged in OMP's own prose (`workflow-notice.md:89`). Aggregate eval fan-out width is bounded only by the model's discipline. The only true backstop is per-provider request concurrency (`task/provider-concurrency.ts:76-100`), which is `ollama-cloud` only (`:19-21`). Any spec claim that `task.maxConcurrency` bounds an `eval` fan-out is **false**. Grade **A**.

### 5.4 `task` has no token-budget gate at all

Symmetric to 5.1 but the other direction: the `task` path never consults `getTurnBudget`. A `+Nk!` hard budget does not stop `task` from spawning. If the spec assumed the `task` path was budget-bounded, it is not. Grade **A**.

### 5.5 Neither surface exposes `merge:"branch"` per call

`task` has no `merge` field; `eval`'s `merge` is a boolean where only `false` is meaningful, mapping to `"patch"` (`eval/agent-bridge.ts:136`). Branch mode is session-wide only (`task.isolation.merge`, default `"patch"`, `settings-schema.ts:4509-4512`). Grade **A**.

### 5.6 `task.isolation.mode` defaults to `"none"`

`settings-schema.ts:4463`. So `isolated: true` **throws by default** on both surfaces (`SS:296-302`) until the user opts in. Any spec design where isolation is load-bearing needs an explicit setup step. Grade **A**.

---

## 6. Recommendation

### 6.1 The verdict

**Neither path alone. Split by phase, and the split is not arbitrary — it follows the durability boundary the two frontends actually implement.**

| Phase | Surface | Why, in one line |
|---|---|---|
| **Gated fan-out** — N verifiers, keep on threshold; staged waves; anything where a wrong answer must *stop* the run | `eval` | Exceptions instead of prose (`agent-bridge.ts:168-174`), validated objects instead of parsed text (`:204`), barriers (`prelude.txt:175-182`). A gate expressed in prose is a suggestion. |
| **Capture-only isolated work** — review a change without applying it | `eval`, `apply:false` explicit | The only surface with per-call apply (§2). Never rely on the setting (§5.2). |
| **Long / durable / resumable work** — a migration you want to walk away from | `task` | Only path with background jobs and a live registry (`task/index.ts:1074-1214`, `executor.ts:3322`). |
| **Single delegation** | `task` | Cheaper. One tool call vs authoring a cell. |

**On the specific question — was choosing `task` an accident that should be reversed?** Partly. The six rounds of design on the `task` path are not wasted: the agent contracts, the schema thinking, the isolation rules, the nested-repo rule (§3.3, which holds on *both* paths) all transfer unchanged, because both frontends share `runStructuredSubagent`. What must change is narrower than "rewrite on eval": **any place the spec relies on a gate, a threshold, a conditional, or capture-only isolation must move to `eval`, because on `task` those are prose the model may ignore.** Everything else can stay.

### 6.2 Cost, per contract rule 5

| Item | Tier | Amount |
|---|---|---|
| `.omp/commands/<name>.md` body | **lazy** (on invocation) | Body size only. Zero when not invoked. |
| `eval` tool description | **persistent** | Already paid — `loadMode: "essential"` (`tools/eval.ts:293`). Adopting `eval` adds **nothing**; it is in every context already. |
| `task` tool description | **persistent** | Already paid, and it is the larger of the two (83 lines + the full agent roster, `prompts/tools/task.md:73-83`). |
| `workflowz` notice | **per-turn, on trigger** | ~1,900 tokens (estimate; basis in §4.1e). Avoidable — state intent directly. |
| Each `agent()` / `task` spawn | **per-spawn** | Identical. Same executor, same prompt assembly (`SS:373-449`). No cost difference between the two frontends. |
| Authoring the cell | **per-invocation** | The orchestrator writes ~30-60 lines of JS instead of a `tasks[]` array. Real, and the honest price of determinism. |

The load-bearing cost fact: **`eval` is not a new persistent cost.** Both tools are already `essential` and already in every context. The choice is about which one the command body *directs*, not about what we pay to keep available.

### 6.3 The named experiment: **`apply=false` capture-only round-trip**

One experiment settles it, because it exercises every asymmetry that matters at once.

**Name:** `CAPTURE-ROUNDTRIP`

**Setup:** `task.isolation.mode = "auto"` (default `"none"` will throw, §5.6). A repo with a known-good and a known-conflicting edit. **A nested git repo, dirty, for arm C.**

**Arms.** Same work, three ways:
- **A — `task`, `isolated: true`.** Session-wide `task.isolation.apply = false`.
- **B — `eval`, `agent(…, {isolated: true, apply: false, schema: S, handle: true})`.**
- **C — B, plus a nested repo whose patch will fail to apply.**

**Measure.** Six things, each already predicted above, so the experiment is falsifying rather than exploratory:
1. Does the orchestrator get `patchPath` as a **usable value**? (Predicted: B yes, `details.patchPath` via `prelude.txt:122-124`. A no — the model must read prose.)
2. Does `apply=false` actually hold? (Predicted: B yes. A depends on the setting only.)
3. Does any `eval` throw fire? (Predicted: **no**, per §3.1. If one fires, my §3.1 confirmation is wrong and I want to know.)
4. Does arm C's nested patch survive on disk? (Predicted: **no** — `persistNestedPatches` unreachable, §3.3. If it survives, the nested-repo rule can be relaxed and that is a meaningful win.)
5. Does the arm-C orchestrator receive *any* machine-checkable failure signal, or only `isolationSummary` prose? (Predicted: prose only, plus a `nestedPatches` array.)
6. Does `budget.spent()` move by the subagents' output tokens? (Predicted: **no**, per §5.1. This is the cheapest arm and the one with the largest consequence for any budget-based rule in the spec.)

**What each outcome decides.** (3) or (4) contradicting the prediction reverses a rule the spec would otherwise inherit as permanent. (1) confirming makes the `eval` gate case decisive. (6) confirming means every budget claim in the spec must be struck.

**Cost:** one session, six observations, ~8 subagent spawns. The cheapest way to convert an accident into a decision.

---

## 7. Coverage and limits (MANDATORY)

**Read in full:** `eval/agent-bridge.ts`, `eval/concurrency-bridge.ts`, `eval/budget-bridge.ts`, `eval/bridge-timeout.ts`, `eval/js/tool-bridge.ts`, `eval/js/shared/prelude.txt`, `eval/session-id.ts`, `task/structured-subagent.ts`, `task/isolation-runner.ts`, `task/parallel.ts`, `task/spawn-policy.ts`, `task/provider-concurrency.ts`, `prompts/system/workflow-notice.md`, `prompts/tools/eval.md`, `prompts/tools/task.md`, `prompts/tools/task-summary.md`, `modes/workflow.ts`, `modes/magic-keywords.ts`, `modes/markdown-prose.ts`, `capability/slash-command.ts`.

**Read substantially:** `task/index.ts` (120-360, 460-700, 1040-1515 — roughly 700 of 1515 lines), `task/types.ts` (1-200, 460-555), `tools/eval.ts` (240-360, 495-760), `session/agent-session.ts` (4855-5000), `session/session-manager.ts` (139-290, 1780-1835), `task/worktree.ts` (194-300, 760-790, `applyNestedPatches`), `task/executor.ts` (2400-2445, 3315-3345, `maxRuntimeMs` sites), `discovery/builtin.ts` (58-90, 336-370), `discovery/agents.ts` (116-250), `extensibility/slash-commands.ts` (95-131), `config/settings-schema.ts` (targeted setting blocks).

**Sampled (grep only):** `task/render.ts`, `packages/ai/src/providers/anthropic.ts` (`buildToolResultBlock` read in full, rest grepped), `packages/ai/src/types.ts` (`ToolResultMessage` only), `sdk.ts` (1755-1775), `tools/index.ts` (session-interface lines).

**Not opened:**
- `eval/py/prelude.py`, `eval/rb/prelude.rb`, `eval/jl/prelude.jl`. I read the **JS** prelude in full and verified the four `nestedPatches` key-mapping lines exist in the py/rb/jl preludes by grep. Every prelude-behavior claim in this report is JS-verified; Python/Ruby/Julia parity is **inferred from the shared bridge** (all four route through the same `callSessionTool`) and from OMP's own dual-language examples. Grade **B** for non-JS backends.
- `eval/executor-base.ts`, `eval/kernel-base.ts`, `eval/backend.ts`, `eval/js/worker-core.ts`, `eval/js/executor.ts`, `eval/idle-timeout.ts`. Kernel transport internals; the bridge boundary is what mattered.
- `eval/completion-bridge.ts` beyond its two-line registration — `completion()` is out of scope (no subagent, no isolation).
- `task/executor.ts` in bulk (3431 lines). I read the isolation, keepAlive, and timeout paths only. Prompt assembly and the subagent inner loop are unread; §2's "per-spawn cost is identical" rests on both frontends calling `buildExecutorOptions` (`SS:373-449`), which I did read, not on reading the executor.
- `task/name-generator.ts`, `task/worktree.ts` in bulk (967 lines), `task/render.ts` in bulk (1830 lines), `task/persisted-revive.ts`, `task/yield-assembly.ts`, `task/output-manager.ts`.
- `cleanse/agent.ts:116` — a **third** caller of `runStructuredSubagent`. Not read. It is a separate internal subsystem, not an orchestration surface, but I did not verify that.
- Any test file. Every claim here is from source, not from tests asserting behavior.

**Needs a live run before use (grade D):**
- That `eval.agent()` genuinely reaches OMP-default policy under a plain `.omp/commands/*.md` invocation, end to end. Every gate is traced statically; the composition is not run-verified.
- Every prediction in `CAPTURE-ROUNDTRIP` §6.3, specifically (3), (4), and (6).
- Whether the `prompt.render` footgun (§4.2) actually mangles a `{{`-containing code block in a command body. I read the render call site; I did not run it. This is the one §4 claim I would most want confirmed before writing a rule around it.

**Suspected but not verified:**
- That §5.1 is an OMP bug rather than deliberate. The `budget-bridge.ts:1-7` header and the `agent-bridge.ts:126-131` refusal both read as though eval subagent tokens *are* counted, and `test/core/turn-budget.test.ts` asserts the accumulator works. The producer call is simply absent. That reads as an unfinished wiring, but I did not check the issue tracker or git history to confirm intent. The *behavior* (§5.1) is grade A; the *characterization as a bug* is grade C.
- Whether any surface outside `src/` (ACP, SDK consumers, the collab host) calls `recordEvalSubagentUsage`. My grep covered the repo excluding `node_modules`, so I believe not, but a runtime injection through the `ToolSession` interface from an external embedder would not appear in this repo.
- Whether `mergeCallAndResult` / renderer behavior changes what the *model* sees versus the TUI on the task path. I verified `details` never reaches the provider (`anthropic.ts:3672`) for Anthropic specifically; I did not check the other ~10 providers in `packages/ai/src/providers/`.
