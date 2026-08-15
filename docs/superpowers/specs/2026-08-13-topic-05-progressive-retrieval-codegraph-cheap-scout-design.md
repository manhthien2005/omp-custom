# Topic 05 Progressive Retrieval, CodeGraph, and Cheap Scout Design

> **Status:** Implemented on 2026-08-13 with deterministic current-product evidence. The optional,
> default-off CodeGraph component passed a disposable real-binary smoke; the model-free four-arm
> harness produced 54 validated records across all nine fixture classes. The paid/provider model
> campaign remains `NOT_RUN`, so no route was promoted and native retrieval remains the default.
> Evidence: `docs/evidence/current-product/topic-05/deterministic.json` and
> `docs/evidence/current-product/topic-05/model-campaign.json`.
>
> **Scope:** Progressive retrieval, source fitness, CodeGraph conditional adoption, per-worktree
> index lifecycle, actor/capability routing, Cheap Scout evidence, independent Reviewer retrieval,
> fallback, and the four-arm benchmark.
>
> **Dependencies:** Topic 01 owns the quality-first optimization objective and promotion
> accounting. Topic 02 owns workflow/task lifecycle. Topic 03 owns agent topology and model
> routing. Topic 04 owns worktree, candidate, and durable-state identity. Topic 06 will own the
> common packet/result envelope; this design defines only its retrieval-specific overlay.

## 1. Goal

Add CodeGraph as a conditional local-retrieval capability without making it a source of truth,
making Cheap Scout mandatory, exposing unrelated MCP tools to a child agent, or weakening native
retrieval. The design must:

- preserve source-fit progressive retrieval with bounded escalation rather than exhaustion gates;
- choose the retrieval actor and retrieval capability independently;
- keep inline Tech Lead work as the default and spawn Cheap Scout only when it has positive value;
- give the Tech Lead, Cheap Scout, and Reviewer a safe CodeGraph retrieval surface;
- bind every graph query to the correct worktree and current source/candidate state;
- keep graph/index/provider failures fail-soft and explicit;
- pass compact, cited evidence across the Scout boundary rather than raw graph payloads;
- make load-bearing claims traceable to current source; and
- measure whether CodeGraph helps this product instead of inheriting an upstream benchmark claim.

## 2. Non-goals

Topic 05 does not:

- enable CodeGraph by default;
- install or configure the upstream CodeGraph MCP server;
- run the upstream interactive `codegraph install` command;
- modify global Codex, Claude, Gemini, or other agent configuration;
- make a graph edge authoritative over current source;
- make Cheap Scout a reviewer, verifier, writer, integrator, or acceptance authority;
- spawn a Scout for every structural question;
- treat abundant Cheap Scout tokens as a reason to suppress useful retrieval;
- implement a second durable task/candidate store;
- define Topic 06's common task-packet/result envelope; or
- promote CodeGraph from pilot evidence or from compliance with an arbitrary token limit.

## 3. Upstream Basis and Pin

The adopted evaluation target is:

```yaml
upstream: https://github.com/colbymchenry/codegraph
release: v1.5.0
commit: ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6
license: MIT
adoption: conditional_optional
```

The release and package both identify version `1.5.0`; the tag resolves to the commit above. The
implementation must record the exact release artifact and SHA-256 selected for each supported
platform from the upstream release checksums. A tag or version string without an artifact digest
is not a complete runtime pin.

Relevant upstream facts verified for this design:

- indexes are project-local under `.codegraph/`, backed by SQLite;
- `status --json` reports the project/index paths, build version, index state, pending changes,
  pending unresolved references, and a worktree mismatch signal;
- `sync` performs an incremental reconciliation;
- `explore` accepts a bounded `--max-files` option and returns dense source plus relationship
  context;
- graph edges may be synthesized heuristically and carry provenance;
- CodeGraph creates `.codegraph/.gitignore` so index data remains local;
- anonymous telemetry is supported and can be disabled; and
- the upstream benchmark reports fewer calls/tokens in its setup but also materially higher
  residual context occupancy. Both claims are upstream evidence, not proof for this template.

No automatic upgrade is allowed. An upgrade requires a new registry pin, license/provenance
check, release-artifact digests, compatibility tests, index migration/rebuild disposition, and a
new benchmark comparison.

## 4. Selected Architecture

Actor selection and capability selection are separate decisions:

| Actor | Native retrieval | CodeGraph retrieval |
|---|---|---|
| Main-session Tech Lead | Small/local/exact questions; current edited source | Bounded multi-file structure that is cheaper to consume inline |
| Cheap Scout | Broad mapping when graph is unavailable or not source-fit | Broad repository mapping, call paths, blast radius, unfamiliar areas |
| General Reviewer | Independent exact/current checks | Independent structural/blast-radius investigation when healthy |

The default remains **Tech Lead inline with native retrieval**. A stage name, workflow size, or
availability of CodeGraph does not itself justify a Scout spawn.

Before a Scout spawn, the Tech Lead must be able to state:

1. the bounded retrieval question;
2. why moving the retrieval out of premium context is useful for this task;
3. the required evidence shape and stop condition; and
4. the native/Lead fallback if the Scout or CodeGraph path fails.

If those are not concrete, the Tech Lead performs the retrieval inline.

## 5. Progressive Retrieval and Source Fitness

The existing default priority remains:

1. local code and types;
2. local documentation and comments;
3. official versioned documentation bundled with the dependency;
4. approved current/version-specific documentation transport such as Context7; and
5. broader authoritative web sources when freshness is the subject.

This is guidance with bounded escalation, not a requirement to exhaust each level. A fitting
source may be selected immediately for a named reason, and the skip is disclosed. CodeGraph is a
capability inside level 1; it does not create a new authority tier.

Within local retrieval:

| Question | Preferred starting capability |
|---|---|
| Exact literal, config key, current line, or just-edited body | native grep/ranged read |
| Definition/reference supported by a healthy language server | LSP |
| Multi-file flow, dependency route, or candidate blast-radius hypothesis | CodeGraph when healthy |
| Unsupported/excluded language, generated file, dynamic runtime behavior, or known graph gap | native source/runtime evidence |
| Public guarantee or current upstream behavior | fitting official source, not the local graph |

Symbol-first and ranged-read discipline remains. CodeGraph does not justify whole-file duplication
after it already returned the required source range.

## 6. Why the Design Uses a Dedicated Adapter, Not MCP

Pinned OMP source shows that unrestricted task children borrow the parent's MCP manager and proxy
its MCP tools into the child. Custom/MCP tools are not reliably narrowed by an agent's built-in
`tools:` frontmatter allowlist. Wiring CodeGraph as a normal MCP server would therefore risk giving
Cheap Scout unrelated MCP capabilities, including tools with write authority.

Topic 05 instead installs one dedicated custom tool:

```text
codegraph_retrieve
```

The adapter exposes retrieval only. It:

- accepts a bounded question and a clamped `max_files`, not a command line;
- derives the project/worktree root from the active session and Topic 04 binding rather than a
  model-supplied arbitrary path;
- invokes a manifest-pinned CodeGraph executable with an argument array, never a shell string;
- permits only fixed `version`, `status --json`, `init`, `sync --quiet`, and `explore` operations
  selected by adapter code;
- sets `CODEGRAPH_TELEMETRY=0` and `DO_NOT_TRACK=1` for every subprocess;
- applies cancellation, startup/index/query timeouts, stdout/stderr limits, and process cleanup;
- uses a source-verified non-interactive initialization path that may write only inside the
  selected `.codegraph/` cache; it never installs Git hooks, starts a persistent daemon, or
  prompts for upstream agent integration;
- emits structured health/provenance details and one bounded text payload;
- never exposes edit, write, delete, arbitrary shell, MCP, or nested-spawn capability; and
- fails closed as a CodeGraph capability while allowing orchestration to fall back to native
  retrieval.

Because the adapter executes a local process and mutates only its cache, its OMP approval tier is
declared honestly as `exec`, even though its model-facing contract is read-only with respect to
project source and candidate state. `.codegraph/` is an explicitly declared cache output, not a
source write.

The adapter declares `loadMode: discoverable`, not essential. Current OMP may mount a discoverable
custom tool under `xd://` in sessions with the write transport and expose it top-level in a
read-only child. The implementation must source-test both presentations. Its idle schema/catalog
footprint in sessions that do not call CodeGraph is measured rather than assumed to be free.

The tool may be discoverable by other unrestricted roles in the current OMP runtime. That is safe
because the tool itself is capability-narrowed. Role prompts and routing permit intended use by the
Tech Lead, Cheap Scout, and Reviewer; the Worker does not gain a new source mutation path.

OMP plan/restricted child sessions remove custom tools, so a selected Scout/Reviewer CodeGraph
path must preflight the adapter's effective presence. If it is absent in that execution mode, the
child uses a separately valid native retrieval contract or the Tech Lead performs the graph query
directly; a prompt must not claim the child consumed CodeGraph when the runtime stripped it.

Adding a true per-agent MCP server/tool allowlist to OMP remains a separate upstream improvement.
If that feature is later source-verified, the adapter may be reevaluated; it is not assumed here.

## 7. Optional Installation and Provisioning

`codegraph` is a new **optional** installer component and is absent from the default component
list. Selecting it explicitly installs:

- the `codegraph_retrieve` adapter;
- the release/version/digest manifest;
- retrieval-specific configuration and human documentation;
- validator and benchmark fixtures; and
- the CodeGraph component's rollback record.

The supported product component depends on Topic 04's `state` component. The installer accepts
`codegraph` only when `state` is selected in the same operation or its compatible manifest is
already present in the target. A manually copied adapter without state may perform non-authoritative
worktree-local experimentation, but it cannot produce candidate-bound or acceptance-bearing
evidence and is outside the supported install contract.

The pinned CLI is provisioned once into an installer-managed user-local dependency cache outside
Git. The exact path is recorded in the install manifest and is never inferred from an arbitrary
`PATH` winner. Provisioning must verify the release digest before activation. Existing matching
user installations may be used only after exact version and artifact-identity reconciliation;
otherwise the managed pin wins or the component reports a conflict.

The template never runs upstream `codegraph install`, because that command can rewrite agent MCP
and instruction configuration. It also never runs `codegraph upgrade` automatically.

Provisioning is transactional. A missing platform artifact, digest mismatch, network failure, or
incompatible existing binary leaves the CodeGraph component inactive and preserves the native
retrieval product. It must not leave an adapter that claims a capability whose pinned executable
is absent.

Uninstall removes project adapter/config files through the normal manifest-aware rollback. It
leaves the shared CLI cache and per-worktree indexes by default, reports their paths, and removes
them only through an explicit confirmed cleanup operation. A cache cleanup must validate exact
targets and never delete a worktree.

### Required projection surfaces

Implementation projects the approved decision coherently into:

- `registry/upstreams.yml`, `registry/adoption-ledger.yml`, and the rejected-mechanism registry
  for pin, license, conditional adoption, rejected MCP/default-on alternatives, source anchors,
  upgrade, and removal policy;
- the DNA/decision log and canonical retrieval, context, installation, evaluation, governance,
  and failure-recovery specs;
- Phase 03 retrieval/context work, Phase 05 installer hardening, and Phase 06 evaluation;
- the Cheap Scout/Reviewer/Tech Lead behavioral prompts and human retrieval policy;
- the optional installer component, custom adapter, version/digest manifest, rollback records,
  and user documentation; and
- focused deterministic tests, the Topic 05 validator, and four-arm benchmark fixtures/results.

Historical research/evidence remains historical and is not silently rewritten into current
authority. Any stale active summary is either updated or explicitly fenced.

## 8. Per-worktree Lazy Index Lifecycle

Each Git worktree owns a separate `.codegraph/` index. Indexes are never shared across sibling
worktrees, task candidates, or a main checkout and a linked worktree.

Lazy creation means the index is initialized only after the Tech Lead selects CodeGraph for a
specific retrieval path. Merely installing the component or opening a repository does not index
the project. Initialization is a deterministic adapter/helper operation authorized by that
selection; a child model does not receive arbitrary setup commands.

Before every query, the adapter/orchestrator performs this sequence:

1. Resolve the canonical session worktree and compare it with Topic 04's observation or
   authoritative worktree binding.
2. Verify the pinned executable version and manifest digest.
3. If the index is absent and the selected path permits lazy initialization, initialize it in
   that exact worktree. Otherwise return `index_missing` for native fallback.
4. Run an incremental sync.
5. Read `status --json` and require:
   - `initialized == true`;
   - the reported project path equals the canonical worktree;
   - `worktreeMismatch == null`;
   - the index was built by the compatible pinned version/extraction contract;
   - index state is `complete`;
   - `reindexRecommended == false`;
   - pending added/modified/removed counts are zero; and
   - `pendingRefs == 0`.
6. Capture the Topic 04 workspace/candidate identity immediately before the query.
7. Run the bounded query.
8. Recheck the workspace/candidate identity. Any source drift makes the result stale and
   unusable for a load-bearing decision.

Before an active task/candidate exists, the same mechanism runs in observation mode: it binds to
the canonical session worktree and records pre/post workspace snapshots, but emits no candidate
identity or acceptance-bearing claim. Once Topic 04 state exists, caller-supplied task/candidate
identifiers are reconciled against durable authority rather than trusted as input.

`.codegraph/` is recorded as an owned ignored cache output so cache mutation does not change the
candidate identity. Source, configuration, generated files in candidate scope, and nested
repositories remain governed by Topic 04.

An optional root `codegraph.json` is **not** cache. The installer does not create it by default;
when a project owner adds one for extensions/include/exclude rules, it remains ordinary
candidate-visible project configuration and follows normal review/acceptance rules.

The retrieval adapter does not automatically delete or destructively rebuild an unhealthy index.
`partial`, `failed`, `indexing`, version-incompatible, mismatched, or unresolved-reference states
return a named failure and use native fallback. Repair/rebuild is a separate explicit maintenance
action.

## 9. Graph Trust and Gaps

CodeGraph is a retrieval accelerator and hypothesis generator. It is not authority over current
source, runtime behavior, public contracts, or task acceptance.

Every graph-derived claim is classified as one of:

- `direct_source`: current source excerpt/location returned by the index;
- `resolved_edge`: statically resolved relationship;
- `heuristic_edge`: synthesized relationship with explicit provenance; or
- `inference`: actor reasoning that requires corroboration.

Known gap classes include unsupported or partially supported language constructs, excluded or
gitignored source, generated code, parse errors, unresolved references, reflection, dynamic
dispatch, runtime configuration, external services, and changes concurrent with a query.

Rules:

- a graph edge may guide the next source read but cannot alone satisfy critical acceptance;
- a claim that a symbol/caller/path does **not** exist always requires fitting native
  corroboration;
- heuristic edges are never silently presented as direct calls;
- a healthy status cannot prove semantic completeness for every language construct; and
- graph/source disagreement is resolved in favor of current source/runtime evidence and recorded
  as a graph gap.

## 10. Retrieval Evidence Packet

Topic 06 will place the following overlay into its common result envelope. Topic 05 requires these
retrieval fields:

```yaml
retrieval:
  question: string
  actor: tech_lead | cheap_scout | reviewer
  capability: native | codegraph | mixed
  source_fitness_reason: string
  status: completed | partial | blocked | failed
  fallback_path: []
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
  claims:
    - claim_id: string
      statement: string
      evidence_kind: direct_source | resolved_edge | heuristic_edge | inference
      sources: [file:line]
      critical: boolean
      uncertainty: string | null
  gaps: []
  searches_performed: []
  recommended_next_action: string
```

The packet contains evidence, not a long narrative or chain of thought. File references are
project-relative and line-bounded. It discloses skipped retrieval levels/reasons and every
fallback. An unanswered question is represented by `partial` or `blocked` plus a named gap; it
does not require a competing `unresolved` status enum.

### Raw payload boundary

- **Scout uses CodeGraph:** the raw CodeGraph payload remains in the Scout session. The Tech Lead
  receives only the compact evidence packet.
- **Tech Lead uses CodeGraph directly:** the existing tool result is consumed in the same session;
  no duplicate raw artifact plus summary is inserted into context.
- **Reviewer uses CodeGraph:** raw retrieval remains in the independent review session; the review
  result carries only decisive cited findings.

Large raw output may be retained as a transient task artifact only for debugging a failed
retrieval contract. It is referenced, not forwarded, cannot become acceptance evidence by
existence alone, and follows Topic 04 retention/privacy rules.

## 11. Critical-evidence Reconciliation

The Tech Lead validates graph/Scout evidence used for a load-bearing decision. Critical evidence
includes claims that determine:

- which files or public symbols are edited;
- security, authorization, privacy, payment, migration, concurrency, or durable-data behavior;
- blast radius or affected tests;
- satisfaction of an acceptance criterion; or
- an assertion of absence.

Validation is targeted, not ritual re-reading. The Tech Lead reads the decisive current source
ranges and validates the load-bearing endpoints/edges with a fitting native capability. It does
not re-run every Scout search or duplicate every CodeGraph payload. Reconciliation records which
claim IDs were checked and which source evidence superseded any graph discrepancy.

## 12. Failure and Fallback

| Failure | Required behavior |
|---|---|
| Lead's CodeGraph adapter unavailable/unhealthy | Lead continues with native retrieval |
| Scout's CodeGraph adapter unavailable/unhealthy | Scout continues with native retrieval when the same bounded question remains valid |
| Scout Flash retryable provider/runtime failure | Retry only the configured Pro `xhigh` route |
| Both Scout routes unavailable | Tech Lead resumes the retrieval using healthy CodeGraph or native retrieval |
| Scout returns structurally valid but weak/uncertain evidence | Return `partial` with named gaps; no opaque automatic Pro retry for quality |
| Reviewer CodeGraph path fails | Reviewer retrieves independently with native tools; review authority is unchanged |
| Index missing and lazy initialization fails/times out | Report `index_init_failed`, then native fallback |
| Plan/restricted child strips the custom adapter | Select a valid child-native contract or let the Tech Lead query CodeGraph directly |
| Sync/status/query failure or output truncation | Reject the graph result and disclose the named reason |
| Candidate/worktree changes during retrieval | Mark evidence stale and repeat against the reconciled state or fall back |
| No fitting authoritative evidence after fallbacks | Remain nonterminal/`unresolved`; do not guess |

Scout failure never changes task classification, candidate identity, or workflow by itself.
Fallback is retrieval ownership transfer, not a new task.

## 13. Independent Reviewer Retrieval

Reviewer remains exact `xhigh` under Topic 03 and independently retrieves against the same
immutable candidate. A Scout packet or Tech Lead summary may identify areas to inspect but is not
the review's evidence of correctness.

Reviewer may choose native or healthy CodeGraph based on source fitness. It must independently
open decisive current source and may disagree with graph/Scout claims. CodeGraph failure degrades
only the retrieval capability, not review quality or authority. Cheap Scout may gather evidence
for review preparation but never issues a finding disposition or verdict.

## 14. Four-arm Benchmark

The benchmark is a controlled 2x2 actor/capability design:

| Arm | Actor and capability |
|---|---|
| A | Tech Lead + native retrieval |
| B | Tech Lead + CodeGraph |
| C | Cheap Scout + native retrieval -> Tech Lead |
| D | Cheap Scout + CodeGraph -> Tech Lead |

This supports the isolated comparisons:

- A vs B: CodeGraph effect in premium Lead context;
- C vs D: CodeGraph effect in cheap Scout context;
- A vs C: Scout-boundary effect with native retrieval; and
- B vs D: Scout-boundary effect with CodeGraph.

### Controls

- Native arms cannot see the CodeGraph tool, CLI, instruction text, or an existing index path.
- All arms use the same frozen repository/candidate snapshot, retrieval question, oracle, timeout,
  cache policy, and environment identity.
- Lead model/effort is identical across A/B and across the Lead-consumption portion of C/D.
- Scout model/effort and Flash -> Pro availability policy are identical across C/D.
- Arm order is randomized or counterbalanced.
- Every run, including provider blocks, failures, crashes, and timeouts, is retained.
- Cold lazy-index cost and warm synced retrieval are measured separately; initialization cost is
  never hidden inside a prebuilt fixture.

### Fixture classes

At minimum the benchmark includes:

1. a known multi-file call path;
2. a known blast-radius/affected-test question;
3. symbol/file localization in an unfamiliar area;
4. an exact-text/config question where native retrieval should be favored;
5. a known dynamic/heuristic graph gap;
6. an absence claim with a deterministic oracle;
7. stale/partial/pending-reference index failure;
8. linked-worktree index mismatch; and
9. source/candidate mutation during retrieval.

The retrieval microbench uses deterministic expected facts and citations. Representative
end-to-end task fixtures additionally verify that retrieval changes do not create false completion,
scope errors, unnecessary edits, or acceptance regressions.

### Measurements

Each run records:

- validated outcome and deterministic quality gates;
- evidence recall, precision, required-fact coverage, and citation accuracy;
- false absence and false completion;
- unique source ranges/bytes the Tech Lead re-reads before a load-bearing decision;
- `core_workflow_tokens` (the premium-token ledger);
- `cheap_scout_tokens`, `raw_total_tokens`, and cache-read tokens as separate telemetry;
- residual retrieval context occupancy by actor/session;
- the installed-but-unused adapter schema/catalog footprint in Lead, Scout, Worker, and Reviewer
  sessions;
- tool calls, retries, fallbacks, rework, timeouts, and wall time;
- index initialization/sync time and index disk size; and
- graph gaps, stale-evidence detections, and native-regression cases.

Provider-reported token usage is required for promotion-bearing token claims. Character estimates
are not substituted. If residual context occupancy or a ledger cannot be measured, it is
`not_measured`; the result cannot support a claim about that metric.

### Bounded procedure

Deterministic adapter/lifecycle/adversarial tests run before any model benchmark. A finite pilot
then uses the minimum paired evidence required by `spec/13`; it may reject an obvious regression
but cannot promote. Final promotion evidence follows the predeclared sequential procedure and
budget already owned by Topic 01/spec 13. The campaign does not continue indefinitely merely to
force a favorable answer.

If DeepSeek is unavailable, C/D are `ENVIRONMENT_BLOCKED`. The harness does not spend Codex tokens
pretending to be Cheap Scout. A/B and deterministic coverage may still proceed, while CodeGraph
remains optional/default-off.

## 15. Recommendation and Promotion Gate

Hard gates precede efficiency:

- no new false completion or critical/blocking correctness/security regression;
- no worktree/candidate cross-contamination;
- required-fact recall, citation accuracy, and validated accepted-outcome rate do not regress;
- graph gaps and absence claims follow the native-corroboration rules; and
- all promotion-bearing ledgers and identities are coherent.

Topic 05 adds no arbitrary CodeGraph-specific percentage. After the hard gates, it asks whether a
route consistently reduces Tech Lead re-reading, core/premium tokens, residual premium context,
or latency for a source-fit task class without worsening another load-bearing measure. Cheap Scout
and raw token volume stay visible but do not disqualify a useful route.

Recommendations are route-specific:

- recommend B only;
- recommend D only;
- recommend both for their demonstrated task classes; or
- recommend neither.

Mixed or inconclusive evidence keeps the component experimental and default-off. A route-specific
recommendation never changes CodeGraph into a universal default. Advancing an implementation into
the stable product baseline still obeys Topic 01/spec 13's predeclared product-wide promotion
procedure; pilot or upstream claims cannot advance it.

## 16. Security, Privacy, and Resource Boundaries

- The adapter accepts no arbitrary executable, argument list, environment map, or project path.
- Query text is passed as one process argument and never interpolated into a shell.
- Canonical-path and symlink checks keep the index/cache inside the selected worktree.
- The pinned executable digest and version are checked before use.
- Telemetry is disabled regardless of upstream consent state.
- Raw graph payloads may contain source and therefore remain within the task/session privacy
  boundary; they are not placed in durable authority or provider fallback prompts unnecessarily.
- Index files are local cache, ignored by Git, excluded from candidate identity, bounded by
  documented cleanup, and never treated as trusted serialized instructions.
- Time, output, and process limits prevent a hung index/query from blocking the workflow.
- Repository text and graph output are untrusted evidence, not instructions to the agent/tool.

## 17. Validation Strategy

### L0 — Static

- exact upstream pin, MIT license, release digest slots, and no floating install;
- `codegraph` absent from default components;
- no CodeGraph MCP config or upstream interactive installer invocation;
- no persistent daemon or Git-hook installation from lazy initialization;
- adapter has no arbitrary shell/path/environment surface;
- telemetry-off environment and bounded output/time controls;
- Cheap Scout remains source-read-only and cannot review/accept; and
- progressive retrieval remains bounded guidance, not exhaustion gates.

### L1 — Discovery and preflight

- optional adapter is discovered only when the component is installed;
- the `state` component dependency is selected or reconciled before activation;
- exact CLI identity is reconciled;
- correct main and linked-worktree roots are derived;
- missing/unhealthy component returns a machine-readable fallback reason; and
- Topic 04 binding/candidate checks activate in every supported install; observation mode handles
  the period before a task/candidate record exists.

### L2 — Contract

- retrieval overlay/schema accepts compact cited evidence and rejects narrative/raw duplication;
- fallback/status enums are closed and distinguish provider, adapter, index, graph-gap, and stale
  candidate causes;
- role boundaries and independent Reviewer retrieval are explicit; and
- absence/critical-evidence rules require native corroboration.

### L3 — Behavioral

- explicit lazy selection initializes only the selected worktree;
- two linked worktrees receive separate indexes and results;
- sync + healthy status permits a bounded query;
- raw Scout payload does not enter the Lead result;
- direct Lead retrieval does not duplicate raw output into a second artifact;
- CodeGraph/Scout failures take the exact native/Lead fallback paths; and
- no source/candidate file is changed by the adapter.

### L4 — Adversarial

- malicious query text cannot inject a command or change project root;
- version/digest mismatch, symlink escape, index mismatch, partial/interrupted index, pending refs,
  and concurrent source change all reject graph evidence;
- a plausible Scout schema cannot mask a failed CodeGraph call;
- a false graph absence is caught by the native oracle;
- truncation cannot be reported as complete evidence;
- native benchmark arms cannot reach CodeGraph by CLI, tool, or inherited instruction; and
- unavailable DeepSeek records environment blockage without routing Scout work to a premium
  impersonation.

## 18. Acceptance Criteria

- **AC-1:** CodeGraph is optional/default-off and pinned by version, commit, and release artifact
  digest.
- **AC-2:** Installation does not run upstream `codegraph install`, create MCP config, or modify
  unrelated agent instructions.
- **AC-3:** One capability-narrowed adapter serves Lead/Scout/Reviewer without exposing arbitrary
  shell or unrelated MCP tools.
- **AC-4:** Every selected index is separate per worktree, lazy, sync-checked, and rejected on any
  mismatch/incomplete/pending-reference state.
- **AC-5:** Topic 04 worktree/candidate drift invalidates retrieval evidence; `.codegraph/` remains
  a non-candidate cache.
- **AC-6:** Scout returns the compact retrieval evidence overlay, and raw CodeGraph plus summary are
  never forwarded together.
- **AC-7:** Load-bearing and absence claims receive targeted native reconciliation.
- **AC-8:** CodeGraph, Scout, and provider failures follow the named fail-soft paths without
  changing task/candidate lifecycle.
- **AC-9:** Reviewer retrieval is independent and Reviewer remains exact `xhigh`.
- **AC-10:** The uncontaminated four-arm benchmark records quality, recall, Lead re-read, core and
  Scout tokens, residual context, cold/warm index cost, latency, and regressions.
- **AC-11:** Quality gates run before efficiency; no mechanism-specific arbitrary percentage or
  cheap-token quota suppresses useful Scout retrieval.
- **AC-12:** Promotion/recommendation is route- and task-class-specific; inconclusive evidence
  leaves native retrieval as the default.

## 19. Alternatives Considered

### Enable CodeGraph by default

Rejected. Upstream evidence is not product evidence, dense payloads can increase resident context,
and index/tool lifecycle introduces real failure and disk/time costs.

### Experiment only, with no installer path

Rejected as the final design. It could measure the upstream tool but would not validate the
actual product attachment, rollback, worktree binding, or Scout boundary.

### Scout-first routing

Rejected. It spends spawn/coordination cost on small questions and conflicts with Topic 03's
benefit gate.

### Lead-first routing for every graph question

Rejected. It puts dense payloads directly into premium context even when a cheap retrieval
boundary would be better.

### Share one index across worktrees

Rejected. It risks candidate/worktree cross-contamination and makes status/repair ownership
ambiguous.

### Give Cheap Scout CodeGraph through MCP

Rejected for the pinned OMP runtime because child MCP inheritance is broader than the intended
single server/tool capability.

### Make CodeGraph graph results authoritative

Rejected. Static/heuristic graphs have gaps and can become stale; source/runtime evidence remains
authoritative.

## 20. Approved Design Summary

- Conditional optional CodeGraph adoption; default-off.
- Separate lazy index per worktree.
- Quality-first recommendation with no arbitrary CodeGraph-specific percentage.
- Independent selection of actor (Lead/Scout/Reviewer) and capability (native/CodeGraph).
- Dedicated pinned retrieval adapter instead of MCP inheritance.
- Compact Scout evidence packet; no raw-payload duplication.
- Targeted Tech Lead reconciliation of critical evidence and native corroboration of absence.
- Independent Reviewer retrieval at exact `xhigh`.
- Four uncontaminated benchmark arms with cold/warm and residual-context measurements.
- Every failure returns to valid native/Lead retrieval or remains honestly unresolved.
