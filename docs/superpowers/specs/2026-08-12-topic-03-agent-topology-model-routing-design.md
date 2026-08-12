# Topic 03 Agent Topology and Model/Provider Routing Design

> **Status:** Conversation design approved by the user on 2026-08-12; written-spec review
> pending. No runtime migration has been performed from this document.
>
> **Scope:** The main-session Tech Lead, optional spawnable roles, spawn and review gates,
> writer/integration ownership, model-role routing, reasoning effort, and model fallback.
>
> **Boundary:** Topic 02 continues to own workflow entry and task/candidate/session lifecycle.
> Topic 03 does not redefine Quick, Standard, Orchestrated, or candidate acceptance semantics.

## Goal

Replace the historical fixed five-role chain with a small, benefit-gated topology. Keep the
main session responsible for the answer and make every subagent earn its quota and coordination
cost. Route cheap retrieval to DeepSeek first, retain strong implementation and review paths,
and never stop merely because one preferred provider or model is unavailable.

The design must:

- make the main-session Tech Lead the default and final owner;
- default to no subagent spawn;
- let a read-only Cheap Scout absorb retrieval work it performs well;
- delegate implementation only when delegation has a concrete benefit;
- preserve independent, risk-gated review without requiring Opus;
- support a single sequential writer by default and safe parallel writers only when justified;
- keep concrete model identifiers in configuration rather than workflow prose;
- distinguish availability fallback from quality rework;
- disclose the actual model and any material independence limitation.

## Non-goals

Topic 03 does not:

- make multi-agent execution mandatory for Standard or Orchestrated;
- preserve Explorer, Implementer, Verifier, or a spawnable Tech Lead for compatibility;
- make Cheap Scout a verifier, reviewer, writer, or acceptance authority;
- create a permanent roster of security/database/performance specialists;
- require Claude, Opus, Gemini, or any other single provider;
- implement Topic 04 durable task state;
- finish the Phase 02 runtime migration before this written design and its implementation plan
  are approved;
- claim that an OmniRoute model path works before catalog and tool-call smoke tests pass.

## Selected Topology

The main session is the Tech Lead. It is not a spawned agent and has no installer-owned
`@tech-lead` alias. Exactly three logical agent types remain spawnable:

| Agent | Purpose | Writes | Default use |
|---|---|---:|---|
| `cheap-scout` | Retrieval, repository mapping, and evidence gathering | No | Optional and benefit-gated |
| `worker` | A bounded implementation work unit | Yes | Optional and benefit-gated |
| `reviewer` | Independent candidate review and risk-focused challenge | No | Risk-gated |

Historical runtime names migrate as follows:

- `explorer` is replaced by `cheap-scout`;
- `implementer` is renamed and narrowed to `worker`;
- `verifier` is removed as a permanent role;
- `tech-lead.md` moves outside agent discovery as main-session role documentation;
- `reviewer` remains, but becomes one General Reviewer with dynamic concern profiles.

## Main-Session Tech Lead

The Tech Lead is the default writer and always owns:

- interpreting and locking the task contract;
- deciding whether any spawn has positive expected value;
- selecting Worker effort from task difficulty;
- integrating delegated work;
- running or obtaining the task's required fresh verification;
- deciding whether the risk gate requires review;
- adjudicating Scout evidence, Worker results, and Reviewer findings;
- reporting the actual model/fallback path and final outcome.

Verification is not delegated by topology. A Worker may self-test and a Reviewer may rerun
important checks, but the Tech Lead remains responsible for complete acceptance evidence.

## Spawn Benefit Gate

The default is **do not spawn**. A subagent is allowed only when its expected improvement in
quality, wall-clock time, context relief, specialist independence, or evidence quality is larger
than its quota, context-transfer, coordination, and integration cost.

Stage names do not justify agents. Standard and Orchestrated do not imply a worker count. A large
task may remain inline; a small task may use one Scout when focused retrieval is genuinely useful.

Before each spawn, the Tech Lead must be able to state:

1. the bounded work unit or question;
2. why doing it inline is worse for this task;
3. the exact expected output/evidence;
4. the stop condition and fallback;
5. for writers, the owned file/symbol scope and integration method.

If those answers are not concrete, the work remains inline.

## Cheap Scout Contract

Cheap Scout is a read-only evidence producer. It may:

- map files, symbols, call relationships, and module boundaries;
- search repository text and inspect relevant source ranges;
- retrieve official documentation or web evidence when freshness is required;
- compare bounded alternatives;
- inspect existing logs and summarize failure evidence;
- return a ranked evidence map with uncertainty and source locations.

Cheap Scout may not:

- edit files or integrate changes;
- issue the final acceptance or review verdict;
- replace mandatory fresh verification;
- claim that a candidate is correct;
- silently broaden the task.

Independent Scout questions may run in parallel only when parallel retrieval materially helps.
Cheap Scout output is advisory evidence. The Tech Lead validates any evidence used for a
load-bearing decision.

### DeepSeek route

The selected initial environment route is:

1. primary: `ds/deepseek-v4-flash`, thinking `max`;
2. availability/retry fallback: `ds/deepseek-v4-pro`, thinking `max`;
3. if the route chain fails, or if a completed Scout result is still insufficient: the Tech Lead
   resumes the same retrieval work.

OMP represents DeepSeek `max` through an `xhigh` selector mapped to provider `max`. The agent
therefore uses an exact `xhigh` configuration, not `low` or `medium`. Concrete `ds/...` values
belong in project model configuration. Agent/workflow text refers only to configured aliases.

The selected OMP representation keeps one logical agent and one primary alias:

- `modelRoles.cheap-scout` resolves to the Flash `xhigh` selector;
- `retry.fallbackChains.cheap-scout` contains only the Pro `xhigh` selector;
- `retry.modelFallback` is enabled for that explicit chain and
  `retry.usageAwareFallback` remains disabled;
- `retry.fallbackChains.default`, `.worker`, and `.reviewer` are explicitly empty;
- Worker/Reviewer acceptance rejects any returned identity mismatch, including credential
  fallback to the parent model.

This representation must be proven against the pinned OMP runtime before projection. It prevents
the Scout fallback policy from silently changing Worker or Reviewer identity.

The Pro route is a fallback for retryable availability/runtime failure. A structurally completed
but weak Flash answer does not trigger an opaque automatic model switch; the Tech Lead evaluates
it and either supplies a sharper Scout question or resumes retrieval inline.

This is fail-soft retrieval. Scout failure does not restart the task, change the workflow, discard
valid discovery, or create a new candidate. A fallback model and the final Tech Lead takeover are
recorded in the task report.

### Environment precondition

Official DeepSeek documentation states that V4 Flash and V4 Pro support thinking mode and that
OMP maps `high` directly and `xhigh` to provider `max`. It also warns that compatibility fields
for thinking-mode tool calls are load-bearing.

The local OmniRoute catalog inspected during design did not yet advertise the exact
`ds/deepseek-v4-flash` and `ds/deepseek-v4-pro` identifiers. Runtime setup must therefore add or
refresh those routes and pass a thinking-plus-tool-call smoke test. Until that succeeds, the
configured Scout path is unavailable and the Tech Lead fallback remains valid; the system must
not claim DeepSeek execution.

## Worker Contract

Worker implements one bounded, explicitly owned work unit. Main-session inline implementation
remains the default.

Spawn a Worker only when delegation produces a real benefit, such as an independently bounded
change, context isolation for a difficult implementation, or safe parallel progress on disjoint
work. Do not spawn a Worker merely because a workflow description contains an implementation
stage.

Worker effort is selected by the Tech Lead per dispatch:

- ordinary/moderately difficult implementation: exact `high`;
- difficult, high-risk, cross-boundary, concurrency-sensitive, migration-sensitive, or uncertain
  root-cause implementation: exact `xhigh`.

The planned OMP projection uses `thinking-level: high` as the Worker default. It enables
per-spawn effort and caps `task.maxEffort` at `xhigh`; a hard-task `effort: hi` request therefore
selects the highest allowed supported level, `xhigh`. L1 validation must confirm the returned
resolved-model effort suffix rather than trusting prose or frontmatter alone.

## Writer Ownership and Parallelism

For one sequential Worker with no competing writer:

- the Worker may edit the retained workspace within its assigned scope;
- the Tech Lead does not concurrently edit that scope;
- the Tech Lead inspects the resulting diff before accepting or continuing.

Multiple writing Workers may run in parallel only when:

- their scopes are genuinely independent and non-overlapping;
- the isolation/capture mechanism is available and preflighted;
- no hidden nested-repository or shared-generated-file boundary invalidates isolation;
- the Tech Lead can integrate captured artifacts sequentially and verify the integrated tree.

If any prerequisite fails, the parallel path is abandoned in favor of one sequential writer.
That degradation is disclosed and does not block the task. The Main Agent never races a Worker
on overlapping files.

## Reviewer Contract

There is one General Reviewer by default. Security, authentication, data, database, migration,
performance, concurrency, payment, public-API, and similar specialties are dynamic concern
profiles supplied in the review packet, not permanent agents.

Use more than one Reviewer only when at least two independent high-risk concerns justify the
extra cost and can be reviewed without duplicating the same work.

Reviewer runs at exact `xhigh`. Its effort is a role invariant and is not lowered for convenience.
Reviewer is mandatory when the candidate touches security, authentication, durable data,
migrations, concurrency, payments, public APIs, or credible data-loss risk. It is also appropriate
for broad diffs, difficult logic, or unresolved Tech Lead uncertainty. It is skipped for a small,
low-risk, fully verified change when an independent review adds little value.

Cheap Scout may gather evidence for a review, but cannot issue the verdict.

### Reviewer independence and fallback

Reviewer preference order is:

1. a suitable strong model from a different family than the Writer;
2. another suitable strong model;
3. the same model family in a separate session, explicitly disclosed as same-model review.

Opus is a preference, not a gate. When Claude quota is unavailable, Codex or another suitable
strong model is a valid fallback. Work stops for unavailable Opus only when the task contract
explicitly requires Opus or an unresolved finding genuinely cannot be adjudicated with the
available models. Difficult deferred findings are noted for later review without blocking
unrelated progress.

## Model and Effort Routing

Concrete provider/model identifiers live in project configuration. Agent files name logical
aliases; commands and workflow prose never embed deployment-specific identifiers.

| Consumer | Model owner | Effort |
|---|---|---|
| Main-session Tech Lead | User/session selection | User/session selection |
| Cheap Scout | Configured DeepSeek Flash, then Pro fallback | exact `xhigh` selector mapped to DeepSeek `max` |
| Worker | Configured strong implementation model | Tech Lead selects `high` or `xhigh` |
| Reviewer | Configured strong review model, preferably cross-family | fixed `xhigh` |

The main session needs no installer-owned `@tech-lead` alias. Only aliases consumed by the
selected three-agent manifest and its explicit Scout fallback are installer-owned.

Model identity remains sticky within a candidate-producing attempt. Availability failure before
material output may select a configured fallback and must report the actual model. A quality
failure after a Worker has produced a candidate does not silently change models: rework stays on
the current model, or a Tech Lead decision to change model opens a new candidate attempt and
reruns the required evidence.

Cheap Scout is exempt from candidate identity because it cannot create or accept a candidate.
Its Flash-to-Pro transition is evidence-path fallback, not candidate mutation.

## End-to-End Flow

1. The main-session Tech Lead locks the task contract and stays inline by default.
2. It optionally sends bounded retrieval questions to Cheap Scout when the benefit gate passes.
3. It validates the returned evidence and plans the work.
4. It implements inline or delegates a bounded work unit to Worker when delegation is beneficial.
5. It integrates the result, freezes the candidate, and obtains fresh verification evidence.
6. It applies the review risk gate and, when selected, dispatches General Reviewer at `xhigh` with
   the relevant dynamic concern profile.
7. It adjudicates findings, opens rework when necessary, and reports actual model/fallback paths.
8. It accepts the candidate only under Topic 02 lifecycle and acceptance rules.

## Failure Handling

- **Scout retryable availability/runtime failure:** Flash → Pro → Tech Lead retrieval; preserve
  valid evidence.
- **Scout completes with insufficient evidence:** Tech Lead sharpens the bounded question or
  resumes retrieval inline; do not disguise a quality judgment as provider fallback.
- **Worker model unavailable before output:** use only an approved, disclosed availability
  fallback; otherwise implement inline or select another suitable Worker model.
- **Worker quality failure:** rework without silent model switching; model change creates a new
  candidate attempt.
- **Reviewer preferred model unavailable:** follow the reviewer fallback ladder; same-model
  independent-session review is valid with disclosure.
- **Parallel writer preflight fails:** run one writer sequentially.
- **Isolation/integration fails after work exists:** preserve artifacts, stop further integration,
  and recover sequentially; do not discard valid work.
- **Effort control unavailable or clamped below a selected exact level:** the selected Worker or
  Reviewer path fails preflight rather than pretending it ran at the requested effort.

## Validation Strategy

### L0 — static

- exactly `cheap-scout.md`, `worker.md`, and `reviewer.md` are selected agent definitions;
- no discoverable `tech-lead.md`, `explorer.md`, `implementer.md`, or `verifier.md` remains;
- Cheap Scout has no edit/write/command capability that can mutate the workspace;
- Worker defaults to `high`; Reviewer and DeepSeek Scout request exact `xhigh`;
- every selected alias and Scout fallback target exists in configuration;
- commands contain no concrete model identifier and no fixed spawn chain;
- installer manifest and selected aliases are coupled.

### L1 — runtime discovery and routing

- OMP discovers exactly the selected three agent definitions;
- effective settings expose per-spawn effort and cap Worker escalation at `xhigh`;
- a normal Worker resolves at `high`, a hard Worker at `xhigh`, and Reviewer at `xhigh`;
- the returned `modelRole`/`resolvedModel` matches the expected effective identity;
- DeepSeek Flash and Pro resolve through OmniRoute with thinking and tool calls functioning;
- Flash availability failure reaches Pro at provider `max`, and both failing return control to the
  Tech Lead without changing task/candidate identity;
- Worker/Reviewer do not inherit the Scout fallback chain;
- same-model Reviewer fallback is a separate session and produces the required disclosure.

### Behavioral

- a bounded low-risk task completes inline with zero subagent spawns;
- a retrieval-heavy task uses Scout evidence and the Tech Lead validates it;
- a moderate delegated task runs Worker at `high`;
- a hard delegated task runs Worker at `xhigh`;
- a high-risk candidate invokes Reviewer at `xhigh` with the correct concern profile;
- a non-overlapping parallel-writer fixture integrates safely, while a failing preflight routes to
  sequential execution;
- unavailable Opus does not stop a task that has an approved review fallback.

## Migration and Ownership

Topic 03 will update the canonical topology and routing specifications, decision records, phase
projections, validators, and human routing reference. Phase 02 owns the later installable runtime
migration of agent files and command behavior. Phase 05 owns installation/config coupling and
effective-setting preflight. Phase 06 owns behavioral evaluation.

Implementation must preserve unrelated user changes in the currently dirty worktree and must not
claim the pre-existing runtime diffs as Topic 03 work.

## Approved Decisions Summary

- Main Agent/Tech Lead is the default single writer and final owner.
- Subagents are spawned only when they create concrete value.
- Explorer is absorbed by read-only Cheap Scout; permanent Verifier is removed.
- One General Reviewer is risk-gated; specialist concerns are dynamic.
- The selected runtime manifest has three logical agents: Cheap Scout, Worker, Reviewer.
- Cheap Scout uses DeepSeek V4 Flash at `max`, then V4 Pro at `max`, then Tech Lead retrieval.
- Worker uses `high` for moderate tasks and Tech Lead-selected `xhigh` for hard tasks.
- Reviewer always uses `xhigh`.
- A different-family reviewer is preferred; same-model independent review with disclosure is a
  valid fallback.
- Opus is never implicitly mandatory.
- One writer is the default; parallel writers require independence, isolation, and safe
  sequential integration, otherwise execution falls back to sequential.
