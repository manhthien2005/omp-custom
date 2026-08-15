# 01 — The DNA

<!-- topic08-projection:behavior-core -->
> **Topic 08 behavior gene:** the manifest currently selects three skills and may be extended by
> reviewed evidence rather than a fixed-count rule. Worker alone autoloads the ≤500-token
> completion-evidence body. Exact project discovery/path/hash reconciliation happens before
> managed dispatch; explicit main-session `agent_tasks` is the only lifecycle bootstrap, and
> read-only diagnosis remains available while generic mutation fails closed.

<!-- topic05-projection:dna -->
> **KD-029 retrieval invariant:** native retrieval is always available as the baseline; optional
> CodeGraph is default-off, worktree-local, and produces hypotheses. Actor selection is independent
> of capability selection, and neither Cheap Scout nor graph output gains acceptance authority.

> **What this file is.** A per-layer structural blueprint. The workflow is decomposed into
> eleven layers. For each layer: the *shape* that applies (the gene), the OMP primitive it
> attaches to, where the shape came from, what it costs, and what breaks if it is wrong.
>
> **Reading rule.** A layer is only real if its `Attaches to` cell names a source-verified
> OMP primitive. A layer whose attachment point is "documentation" is documentation — that
> is a legitimate outcome, but it must be labelled, because the `.omp/policies/` failure
> was exactly a documentation layer wearing a runtime costume.
>
> Grades (`A`/`B`/`C`/`D`) are defined in `00-method.md §3`. `A` = source-verified in OMP.
> Upstream attributions marked *(provisional)* await the corresponding file in `dossiers/`.
>
> **KD-027 topology gene:** the main-session Tech Lead defaults to inline ownership. The only
> spawnable agents are read-only Cheap Scout, bounded-writing Worker, and risk-gated General
> Reviewer. Spawn requires a concrete benefit; verification remains a Tech Lead contract
> obligation. Worker defaults `high`, hard Worker and Reviewer use `xhigh`, and only Scout may
> use the explicit Flash→Pro availability chain.

---

## 0. The genome at a glance

```
                        ┌─────────────────────────────────────────────┐
 ALWAYS PAID            │ L0  IDENTITY      AGENTS.md · RULES.md      │  persistent + sticky
                        ├─────────────────────────────────────────────┤
 PAID ON INVOCATION     │ L1  ENTRY         commands/*.md             │  lazy per invocation
                        ├─────────────────────────────────────────────┤
                        │ L2  TOPOLOGY      agents/*.md + spawn graph │  per spawn
 PAID PER SPAWN         │ L3  CONTRACT      output: frontmatter       │  per spawn
                        │ L5  DISCIPLINE    autoloadSkills            │  per spawn
                        ├─────────────────────────────────────────────┤
 PAID PER ACTION        │ L4  RETRIEVAL     lsp · grep · read ranges  │  per query
                        │ L6  ISOLATION     isolated: true + capture  │  per write fan-out
                        │ L7  JUDGEMENT     verification · review     │  per gate
                        ├─────────────────────────────────────────────┤
 STRUCTURAL             │ L8  GOVERNOR      compaction · spill        │  continuous
                        │ L9  EVIDENCE      result telemetry · evals  │  per run
                        │ L10 PROVENANCE    registry/ · watched paths │  per upgrade
                        └─────────────────────────────────────────────┘
```

The vertical axis **is** the cost model. A mechanism placed one band too high is paid orders
of magnitude more often than it needs to be. Most token waste in agent templates is a
placement error, not a verbosity error — and placement is what this file fixes.

---

## L0 — Identity

**The gene.** Two files, disjoint by lifetime, never overlapping in content.

| Slot | File | Attaches to | Lifetime | Budget | Grade |
|---|---|---|---|---|---|
| Constitution | `.omp/AGENTS.md` | ContextFile — `builtin.ts:910`, `:923` | persistent, every turn | 600–1,200 tok | A |
| Invariants | `.omp/RULES.md` | Rule, `alwaysApply` **forced** — `builtin.ts:392-418` | sticky, survives compaction | ≤ 700 tok | A |
| *(not used)* | `.omp/SYSTEM.md` | replaces system prompt wholesale — `builtin.ts:242-271` | — | — | A |

**Shape rules.**

1. **`RULES.md` holds only what must be true mid-turn.** It is re-attached near every turn,
   so a sentence here is the most expensive sentence in the system. The test for admission:
   *would a model that forgot this act destructively or claim false completion?* If not, it
   belongs in `AGENTS.md`.
2. **`AGENTS.md` holds what must be true across the task.** Constitution, role map, project
   build/test commands. Read once per turn, not re-attached per message.
3. **Zero duplication between them, and zero duplication into agent prompts.** A rule stated
   in `AGENTS.md` and repeated in four agent files is paid five times. The validator's
   constitutional-phrase scan (`validate-template.ps1` §3) enforces this and must be
   extended to skill bodies.
4. **`SYSTEM.md` is deliberately unused.** It replaces OMP's entire system prompt, discarding
   every built-in tool instruction. Reviewed and rejected — see `04-decision-log.md` KD-021.

**Upstream shape sources.** Constitution pattern from spec-kit's project constitution (MIT);
four coding principles independently rewritten from karpathy-skills, which declares **MIT
in-file** (`skills/karpathy-guidelines/SKILL.md:4`, `README.md:169-171`) — the ledger's
"no license" claim is wrong, corrected in KD-023, though our text is an independent rewrite
either way. Sticky-invariant discipline is OMP-native.

**Discovery hazard, layer-specific.** `AGENTS.md` and `RULES.md` are among the only four
surfaces that walk ancestor directories (`builtin.ts:90-99`). `commands/`, `agents/`,
`config.yml` do **not**. Running `omp` from a subdirectory keeps the constitution and drops
the workflow. See L10 for the validation consequence.

**Fails as.** Constitution too long → paid every turn forever. Invariants in `AGENTS.md`
instead of `RULES.md` → dropped at compaction exactly when the session is long enough to
need them.

---

## L1 — Entry and sizing

**The gene.** One normal plain-language entry, one explicit Quick choice, and
Tech-Lead-selected Standard versus Orchestrated. Workflow classification is independent of
agent count and may change internally without restarting a slash command.

| Entry | Authority | Effect |
|---|---|---|
| Plain request | main-session Tech Lead | normal entry; clarify the task contract, then select Standard or Orchestrated |
| `/quick` | explicit user choice, validated by Tech Lead | reduced ceremony for a clear bounded task; may escalate when unsuitable |
| `/standard`, `/orchestrated` | compatibility/advanced hint | validate against actual structure before mutation |
| `quick`, `standard`, `orchestrated` without `/` | natural-language hint | interpret in context; a missing slash is not an error |

**Shape rules.**

1. **A plain request enters the main-session Tech Lead.** No classification turn or prefix is
   required from the user; clarification is paid only when the task contract actually needs it.
2. **Quick is explicit.** The user's explicit Quick choice receives a short preflight. If the
   task is unsuitable, the Tech Lead reclassifies it and reports why.
3. **Standard is one integrated implementation lane.** It may be large or high-risk and may
   use optional specialists without changing classification.
4. **Orchestrated is structural.** It requires at least two independently verifiable work
   units, explicit unit contracts, one integration contract, and cross-boundary verification.
   Parallel execution and multiple writers are optional.
5. **Reclassification preserves valid work.** It neither reinvokes a slash command nor
   automatically resets, discards, or reverts discovery and workspace changes.
6. **Lifecycle identity is explicit.** A task begins when objective, scope/authority, mandatory
   acceptance criteria, and required verification and review obligations are locked in its
   accepted contract. Acceptance evidence binds to a frozen candidate snapshot. A session
   serves one task and one non-competing candidate lineage; safe compaction preserves that identity,
   while handoff creates a reconciled successor session.

**⚠ Wire-format correction — `task.batch` defaults to `true`** (`settings-schema.ts:4570`,
independently confirmed). The model-facing shape is **not** `{agent, task}`. It is:

```
{ context: string,          // REQUIRED — shared preamble, prepended to every item
  tasks: [ { name?, agent?, task, effort?, outputSchema?, schemaMode?, isolated? } ] }
```

If Topic 03 later selects a batch dispatch path, every model-facing batch example must use
this shape. The flat form still works for internal callers but is **rejected model-side** when
batch is on (`task/index.ts:192-202`). KD-006 records the runtime fact; it does not require a
particular topology.

**`context` is a genuine token lever, not overhead.** It is stated once and prepended to
every item, so shared scope, conventions, and acceptance criteria belong there rather than
copy-pasted into N packets. For a 4-way fan-out this is a ~3× reduction on the shared
portion of the packet.

**Fails as.** Prefix-required entry → needless user friction. Size/risk/agent-count routing →
false Orchestrated classification. Restart/discard escalation → lost evidence or user work.
Batch commands documenting the flat wire → dispatch rejected at runtime.

---

## L2 — Topology

**The gene.** The main-session Tech Lead owns classification, integration, acceptance, and the
final answer. Worker dispatch is optional. Topic 03 owns the final worker graph, specialist
roster, depth policy, and dispatch conditions; a workflow stage name never forces a spawn.

**Pre-Topic-03 roster hypothesis — non-authoritative.** The former candidate below is retained
as migration input and source-analysis history only. Topic 03 may keep, merge, rename, or remove
these roles. The diagram does not define Standard or Orchestrated, require a worker count, or
make review/parallelism mandatory.

```
depth 0   main session ── IS the Tech Lead (no agent file)
             │
depth 1      ├── explorer          read-only, parallel-safe
             ├── implementer       writes; isolated only when parallel
             ├── verifier          runs commands, observes real tree
             └── diff-reviewer     judges the diff
depth 2   available headroom — deliberately unused
```

| Worker | `tools:` | Isolated | Attaches to |
|---|---|---|---|
| `explorer` | `read, grep, glob, lsp` | never | AgentDefinition — `task/discovery.ts:42-58` |
| `implementer` | `read, grep, glob, edit, write, bash, lsp` | only when parallel | AgentDefinition |
| `verifier` | `read, grep, glob, bash` | never | AgentDefinition |
| `diff-reviewer` | `read, grep, glob, bash, lsp` | never | AgentDefinition |

**Shape rules.**

1. **The coordinator is the main session, not an agent.** A spawned coordinator duplicates
   context, adds a recursion level, and moves ownership of the final answer into a child
   whose result the parent must re-summarize.
2. **`tech-lead.md` must not live under `agents/`.** `loadAgentsFromDir()` parses *every*
   `.md` in that directory into a live spawnable `AgentDefinition` — there is no
   documentation-only category (`task/discovery.ts:42-58`, re-confirmed). A file there is a
   second, mechanically spawnable Tech Lead. Re-homed to `docs/roles/tech-lead.md`.
3. **Independent evidence is contract-gated, not roster-gated.** When the accepted task
   contract requires independent verification, the selected Topic 03 mechanism must obtain it
   from a non-author of the candidate; an author's self-report alone is insufficient. Topic 03
   decides whether that mechanism is a separate worker, the main-session Tech Lead, or another
   independently justified path.
4. **A selected observation role sees the acceptance target.** When verification or review
   judges the integrated tree, that role must observe the real integrated candidate rather than
   an isolated copy nobody ships. This constraint applies only when such a role/path is selected.
5. **Any selected project adapter avoids accidental bundled-name collision.** OMP bundles an
   agent named `reviewer`; project agents win by first-name-wins precedence
   (`task/discovery.ts:87-133`), so the former candidate name silently shadows a built-in.
   Shadowing may be intended, but it must be *chosen*.

**⚠ Two allowlist corrections — allowlists are floors, not ceilings.**

- **`hub` is force-appended to every subagent** unless the session is restricted
  (`executor.ts:2690-2691`, independently confirmed). Every worker has agent-to-agent
  messaging whether the roster wants it or not. The `spawns: ""` isolation story is weaker
  than `spec/03 §B` claims.
- **`task` is auto-*added*** when `spawns` is set and depth allows (`executor.ts:2676-2681`).
  Declaring `spawns:` on a worker to document "spawns nothing" can *grant* the tool.
  Correct enforcement: omit `spawns:` entirely and omit `task` from `tools:`.

**⚠ Recursion-depth correction — the DR-1 premise was too pessimistic.**
`childDepth = parentDepth + 1`, refused when `childDepth >= max`
(`executor.ts:2670-2672`, independently confirmed). Default `2` therefore permits **two**
subagent levels below the main session, not one. The original argument for a flat topology
("a spawned coordinator leaves zero headroom") is **false**. The decision stands on its
other three grounds — context duplication, answer ownership, spawn cost — and the record is
corrected rather than the outcome. See `04-decision-log.md` KD-005.

**`spawns:` list order is semantically load-bearing** — `allowedAgents[0]` becomes the
default agent for calls that omit `agent` (`task/spawn-policy.ts:52-59`). Undocumented in
the spec; matters if a coordinator agent is ever reintroduced.

**Fails as.** Coordinator as agent → context duplication, split answer ownership.
`tech-lead.md` left in `agents/` → two topologies, divergent routing. A contract requiring
independent evidence satisfied only by the candidate author → self-confirmation returns.

---

## L3 — Contract

**The gene.** Each selected spawned worker with a structured result contract declares its
canonical result schema in its own frontmatter. An inline or main-session responsibility uses
an equivalent contract at the boundary Topic 03 selects. The call site overrides only for
one-off narrowing.

| Selected responsibility | Contract when consumed | Attaches to | Grade |
|---|---|---|---|
| discovery-result producer | ranked evidence, no change claim | selected worker `output:` or equivalent selected boundary | A |
| change-result producer | change result plus required evidence | selected worker `output:` or equivalent selected boundary | A |
| verification-result producer | exact verification result | selected worker `output:` or equivalent selected boundary | A |
| review-result producer | review decision and findings | selected worker `output:` or equivalent selected boundary | A |
| main session → worker | task packet | **plain string** — no input schema exists | A |

**Shape rules.**

1. **For a selected spawned worker, schema travels with the worker contract, not the call
   site.** Frontmatter cannot be forgotten at a dispatch; an inline `outputSchema` repeated at
   every dispatch can, and drifts. Inline schemas remain valid explicit overrides or the
   enforcement boundary for a selected non-worker producer.
2. **The task packet is a string.** OMP offers no input-schema enforcement. `task-packet.yml`
   is a *composition checklist* for the session, not a validated contract. Say so.
3. **Flat, closed objects. No `$ref`.** The validator dereferences and throws if a `$ref`
   survives, degrading to an unconstrained object. Flat closed shapes also enable
   incremental section yields (`withSectionVariants`), which suit any selected
   finding-at-a-time review producer.
4. **Minimal required fields.** Each required field the model struggles with burns retry
   budget. Require only what the coordinator cannot proceed without.
5. **`maxLength` on evidence strings.** The only structural lever against a selected
   exact-output verification responsibility that pastes an entire test log into `evidence`.
6. **No chain-of-thought fields.** A schema field that invites narration works against the
   packet/result prohibitions in L8.

**⚠ Enforcement is stronger than the superseded pre-KD-003 draft claimed.** The current
`spec/01 §4` and `spec/06 §B` now carry this correction. The actual rule in
`finalizeSubprocessOutput` (`executor.ts:598-700`):

```
mustReject = failure !== undefined
             && (mode === "strict"
                 || (!assembled.schemaOverridden && !schemaError))
```

In **permissive** mode an invalid payload still becomes a `schema_violation` with
`exitCode 1` — *unless* the in-tool retry budget was exhausted or the schema itself was
malformed. Permissive is "accept only the retry-exhausted override", not "accept after 3
tries". Strict rejects even that.

**The real hazard is the opposite of the documented one: a malformed `outputSchema`
degrades silently to unvalidated output** and sets `structuredOutput.status: "unavailable"`.
It does not fail the spawn. So schema *lint* is a required validation check, not a nicety —
a typo in a schema silently removes all enforcement. `04-decision-log.md` KD-003 and KD-004.
Acceptance requires structuredOutput.status valid; unavailable, invalid, and overridden results
are unvalidated.

**⚠ But enforcement is of *shape*, not *provenance* (CR-35).** `buildOutputValidator()` is
pure JSON Schema validation with no correlation to the session's tool events. A worker that
ran zero commands and fabricated a plausible `verification_results` array produces a payload
that validates and returns `PASS`. Required fields therefore guarantee a claim is *present
and complete*; they prove nothing about whether the claimed commands ran. Three separable
layers, and only the first is mechanical:

| Layer | What it gives | Mechanical? |
|---|---|---|
| Schema | the claim is present, typed, complete | **yes** — `buildOutputValidator()` |
| Independence | the claimant did not write the code (L2 rule 3) | structural, not attested |
| Provenance | the commands actually ran | **no v0 mechanism** |

So L3 must never be described as making false completion *impossible*. v0 resistance is
behavioral and independence-based. `history://<id>` transcripts are the candidate provenance
channel; what they can actually prove is unmeasured (`spec/10 §A-1`, phase-04 T-04.8) and no
stronger claim is permitted until it is. An earlier draft asserting that required fields
"cannot be satisfied without real command output" was wrong and is withdrawn.

**Resolve the `status: completed` contradiction by making `verification_results` required
unconditionally with an empty array permitted**, and enforce "completed implies non-empty"
in the coordinator's acceptance check. A JSON-Schema conditional would likely fail
strict-representability and silently drop the whole agent to non-strict — trading real
enforcement for schema elegance.

**Fails as.** A selected spawned worker's schema at call site only → forgotten on one
dispatch, that worker unvalidated.
`$ref` present → silent unconstrained object. Malformed schema → silent total loss of
enforcement with a clean-looking result. Schema mistaken for attestation → a fabricated
`PASS` is read as verified, and the layer built to prevent false completion certifies one.

---

## L4 — Retrieval

**The gene.** Symbol-first, ranged reads, no persistent map. Ordering over tools, not a
preference.

| Question | Tool | Not |
|---|---|---|
| Where is this defined? | `lsp` definition | whole-file `read` |
| Who calls this? | `lsp references` | `grep` for the name |
| What does this export? | `lsp symbols` | whole-file `read` |
| Does this literal string exist? | `grep` | `lsp` |
| What files match this shape? | `glob` | `bash ls` |
| What is this function's body? | `read` with a range | whole-file `read` |

**Shape rules.**

1. **`grep` is not a fallback for `lsp` — it answers a different question.** `grep` finds
   text; `lsp` finds meaning. `grep getProfile` returns comments, strings, and unrelated
   same-named methods; `lsp references` returns actual call sites. When both work, prefer
   `lsp`, because its result needs no filtering.
2. **Effective LSP requires all four independent gates.** The conjunction is: `lsp` in the
   selected worker allowlist; `task.enableLsp == true`; parent session LSP not disabled and not
   plan mode; and `lsp.enabled == true` (`task/structured-subagent.ts:318-320`,
   `tools/index.ts:593`, `task/executor.ts:2675-2678`). A selected LSP-consuming path fails
   closed when any gate is unmet; `grep` cannot satisfy that same semantic contract.
   Continuation requires remediation or an explicit non-LSP replacement contract,
   reconciliation against the locked criteria, and validation of the replacement path.
   The four registration gates do not prove that an applicable language server exists or that an
   LSP call succeeded. Every required call must return `details.success: true`; no matching or
   configured server and any `details.success: false` outcome fail the selected contract before
   acceptance (`lsp/index.ts:2145-2160`).
3. **No persistent repository map.** Aider's repo-map is adopted as a *principle*: a selected
   transient discovery responsibility builds the map for the task at hand and discards it. A materialized map goes
   stale on the next commit, costs tokens whether or not the task needs it, and duplicates
   what `lsp symbols` computes lazily and accurately. *(provisional — aider dossier pending)*
4. **Retrieval order is guidance with a bounded budget, not exhaustion gates.** Local code
   and types → local docs → official versioned docs → Context7 → web. The real failure is
   the level-1-to-level-5 jump: a web search for what the type definition next to the call
   site already answered. But "exhaust level N first" is wrong too — use the most
   authoritative source for the question type, within a budget, then escalate.
5. **Context7 is optional, never assumed.** It requires an MCP server wired into the session.
   When Context7 is unavailable, record `context7_unavailable` and disclose the skipped level
   and reason. Continue with the next fitting accessible source under the bounded-escalation
   rule; never skip or backtrack silently.

**⚠ Read-summarization has a floor the spec does not record.**
`read.summarize.minTotalLines` is **100** (`settings-schema.ts:3331`) — files shorter than
that are read verbatim regardless. So `read-summarize: false` on a selected read-heavy
responsibility costs nothing on small files and everything on large ones, which is precisely
backwards from its intent. `unfoldUntil: 50` / `unfoldLimit: 100` govern BFS unfolding of
elided spans, giving the model a cheap way to expand exactly the region it needs. Remove the
role-specific override.

**Fails as.** `lsp` instructed but not allowlisted → burnt turn or silent grep fallback.
Summarization disabled on read-heavy roles → the largest single token regression available.
Persistent repo map → stale context paid on every load.

---

## L5 — Discipline injection

**The gene.** Three delivery mechanisms with different reach. Choosing wrong means the rule
silently does not apply.

| Mechanism | Reaches | Cost | Attaches to |
|---|---|---|---|
| `RULES.md` | main session, sticky; forwarded to children via `rules: session.rules` | per turn | `builtin.ts:392-418` + `structured-subagent.ts:438` |
| Skill listing (name + description) | whichever session lists skills | per turn, tiny | `capability/skill.ts` |
| Skill body via `skill://` | only when the model asks | on use only | read-tool scheme |
| `autoloadSkills:` | that agent, deterministically at spawn | per spawn | `task/executor.ts:3235-3248` |

**Shape rules.**

1. **Skill `description` is load-bearing.** It is the only part most sessions ever pay for,
   and it is what the model uses to decide whether to pay for the body. A missing
   `description` **silently drops the skill entirely** — every native scan passes
   `requireDescription: true` (`helpers.ts:390-392`). That is a validation FAIL, not a warning.
2. **`autoloadSkills` for invariants that govern selected completion-claiming responsibilities.**
   The current manifest assigns completion evidence only to Worker. Cheap Scout and Reviewer do
   not pay this body; future consumers require an explicit reviewed manifest change.
3. **Parent rules *do* propagate to subagents.** `structured-subagent.ts:438` passes
   `rules: session.rules` to the child. The earlier claim that `RULES.md` never reaches
   workers was wrong. `autoloadSkills` is still preferred, on different grounds: forwarding
   carries the *entire* parent rulebook with opaque cost, whereas autoload delivers exactly
   one intended body at a known price — and a buried rule in a large forwarded rulebook is
   deprioritized in practice.
4. **Autoloaded bodies must stay small.** `evidence-before-completion` ≤ 500 tokens, because
   it is paid for every selected consumer spawn. Overflow goes into a reference file read on
   demand.
5. **The one correct duplication.** "Never claim complete without verification" lives in both
   `RULES.md` (for the main session) and the autoloaded skill (for workers). Disjoint
   audiences, so document it as intentional or a future dedup pass deletes the worker copy.
6. **Quality gates are selected by the session at packet-build time and passed as data.** A
   selected gate-applier or review responsibility that invents its own gates produces
   unbounded scope — the false-positive failure mode its contract guards against.

**⚠ Rules are a far richer surface than the spec uses.** `buildRuleFromMarkdown`
(`helpers.ts:182-221`) parses `globs` (path-scoped activation), `condition`, `astCondition`
(AST-conditional activation), `scope`, and `interruptMode`
(`never|prose-only|tool-only|always`). `.mdc` is accepted alongside `.md`. `instructions/`
carries `applyTo` as a second path-scoped channel. **A path-scoped rule costs nothing on
files it does not match** — this is the cheapest per-token quality mechanism in OMP, and the
template currently uses none of it. Flagged as the highest-value unexplored lever;
`04-decision-log.md` KD-022 holds it for post-v0 pending an evaluated baseline.

**Fails as.** `alwaysApply` on a skill expecting subagent reach → inert, looks configured.
Native OMP filters a dangling `autoloadSkills` name silently, so the managed Topic 08 adapter
reconciles the effective catalog and refuses dispatch instead. Missing skill `description` also
removes it from native discovery and therefore fails the same preflight.

---

## L6 — Isolation and integration

**The gene.** Isolation is requested per call, only for selected parallel writers. Parallel results
are captured, then integrated serially by the coordinator in a fixed order.

| Selected responsibility | `isolated` | Why |
|---|---|---|
| read-only discovery | `false` | isolation buys nothing, costs a materialization |
| integrated-tree verification | `false` | must observe the real merged tree |
| real-diff review | `false` | must review the real diff |
| sole writer | `false` | no competing writer; change lands where acceptance observes it |
| parallel writer | **`true`** | concurrent writers corrupt each other |

**Shape rules.**

1. **`mode: auto` selects a *backend*, never *whether* to isolate.** It answers "which
   filesystem mechanism", not "which responsibilities". A selected parallel writer spawned
   without `isolated: true` writes directly to the shared tree regardless of `mode`. This
   misreading is the single most consequential one available in this layer.
2. **Isolation requires git.** `prepareIsolationContext` throws outside a repository — a hard
   precondition, not a degradation. Preflight `git rev-parse --show-toplevel`; on failure
   fall back to sequential non-isolated and **say so in the report**.
3. **`apply: false` is a correctness precondition, not tuning.** OMP defaults to `true`, so
   absent an explicit setting every successful isolated worker auto-applies concurrently with
   no serialization guarantee. It is a **session/project settings key**, not a per-task-item
   field — there is no per-item `apply` in the v17.2.10 wire.
4. **Runtime preflight is mandatory, because install is not sufficient.** A
   higher-precedence overlay can re-enable apply after install. Before any parallel fan-out:
   assert effective `mode != "none"` **and** effective `apply == false`. On failure: do not
   fan out. Sequential fallback or explicit refusal, disclosed either way.
5. **Integration order is the original task-list index.** Not completion order, not
   alphabetical, not file order. OMP returns results in input order
   (`task/parallel.ts` — `results[index]`), so the anchor already exists in the payload and
   is independent of scheduling jitter. Completion order would make conflict behavior
   irreproducible between identical runs.
6. **Conflict semantics: stop, preserve, report.** On conflict at artifact *i*, do not
   attempt *i+1…n*; every unapplied artifact stays on disk and is reported by path; the
   selected verification mechanism does **not** run on a partially integrated tree. There is no atomic batch-merge
   primitive, so automatic rollback of already-applied artifacts is not available.
7. **No topological ordering.** If two units have a real dependency they were not
   independent and must not have been parallelized. Dependency ordering at integration time
   papers over a partitioning error.
8. **Any nested repository disables parallel isolated implementation, repository-wide.**
   On the *successful* `apply=false` path OMP never materializes nested-repo patches to disk
   (`persistNestedPatches()` is reachable only from the failure/recovery path), and the
   summary reports only the root patch when the root also changed — so a nested change is
   lost *silently*.

   An earlier revision of this rule said "exclude nested repos from parallel *scope*":
   enumerate them, name them in `out_of_scope`, keep parallelism for the rest. **That is
   withdrawn (CR-32, round 6).** Scope exclusion is an instruction to the worker, not a
   constraint on it, and there is no post-hoc detector: because the nested patch is never
   written and the worktree is torn down, the parent tree is *identical* whether the worker
   complied or silently lost work. A guard with zero discriminating power is not
   enforcement.

   The guarantee therefore has to come from never entering the path. Orchestrator preflight
   enumerates nested repos and tracked submodules **before** fan-out (a superset of
   `discoverNestedRepos()`); a non-empty result routes the whole run to sequential
   non-isolated implementation and discloses why. Coarser than the old rule, and correct —
   `spec/08 §D-1.2`, Option A1.

   A mechanical *path-level* boundary is reachable (a `tool_call` hook blocks
   pre-execution and fails closed; isolated spawns re-discover extensions in-worktree via
   `preloadedExtensionPaths: undefined`), so "OMP cannot enforce this" is too strong. It is
   recorded as the A2 lift path and **not** adopted for v0 — it would introduce hooks as a
   new installed component class. See `04-decision-log.md` KD-018.

**⚠ Two capacity corrections.** `task.maxConcurrency` defaults to **32**, not 4
(`settings-schema.ts:4594-4613`) — the baseline's 4 is a deliberate narrowing that must be
deployed, not assumed. `task.softRequestBudget` defaults to **200 requests with a hard stop
at 1.5×** (`:4676-4692`), so a runaway worker is bounded by OMP but will return a *partial
yield* — which the coordinator must treat as incomplete, not as a result.

**Fails as.** Missing `isolated: true` on parallel writers → interleaved edits, corruption.
`apply` left at default → concurrent auto-apply, unserialized. Nested repo present and
parallel isolation still enabled → work silently vanishes, report reads clean, and nothing
after the fact can tell you it happened. Completion-order integration → irreproducible
conflicts.

---

## L7 — Judgement

**The gene.** Cheap deterministic filter first, expensive judgement second, and the decision
is a function of the findings.

```
produce candidate → verify → [review, risk-gated] → report
                       ↑
          FAIL short-circuits back to the selected remediation owner; review is skipped
```

**Shape rules.**

1. **Verification precedes review, and a `FAIL` skips review entirely.** Reviewing code that
   fails its own tests spends judgement on defects the suite already found.
2. **Failure classification is mandatory: `impl | env | flaky | preexisting`.** Nothing else
   in the system captures it, and it determines the next action. Conflating `env` with `impl`
   sends the selected remediation owner to "fix" working code, which usually means changing
   things until the symptom moves.

   `preexisting` is a required fourth category, not a variant (CR-36). A deterministic
   failure that was already failing on the baseline is none of the other three — it is not
   `flaky` (it reproduces), not `env` (the environment is fine), and not `impl` (this change
   did not cause it). A three-way enum forces it to `impl`, which dispatches the selected
   remediation owner at code outside the change's scope. Route instead: record baseline evidence, exclude from
   this change's attribution, surface as a project risk. The label carries a **mandatory
   baseline-evidence obligation** — an unsubstantiated `preexisting` is the label's own abuse
   case and is treated as `impl`.
3. **`PASS` requires every criterion `PASS`.** Any `SKIP` caps the result at `PARTIAL`, and
   the reason goes in `coverage_gaps`. An uncovered criterion is not a failed criterion — but
   it is also not a passed one, and `PASS` with silent gaps is false completion wearing a
   schema.
4. **False-positive control is structural and required.** Each finding must name a concern
   and state why it was cleared: already handled elsewhere? excluded by the packet?
   theoretical or actually present? lint already failing before this change? The last is the
   most frequently violated in practice. This inverts the usual dynamic — instead of
   rewarding volume of findings, it requires showing work on findings *rejected*.
5. **Review is diff-first with question-driven expansion.** Read the diff; expand only to
   answer a specific question the diff raised; never read a file "for context" without a
   question it answers. Expansion should almost always be a range read or a symbol query.
6. **Decision follows findings mechanically.** `APPROVED` ⇒ `blocking_findings` empty;
   `CHANGES_REQUESTED` ⇒ at least one. This prevents the two standard pathologies: approving
   while listing blockers, and requesting changes without naming one.
7. **Review is contract/risk-gated.** Quick does not add a separate reviewer. Standard and
   Orchestrated require independent review only when the accepted task contract, selected
   quality gates, integration risk, or cross-boundary evidence demands it. Orchestrated
   classification alone does not force review. The signal is not diff size — it is *whether
   the change creates a contract someone else depends on*, which is what review catches and
   tests do not.
8. **The coordinator does not re-derive verification from prose.** "All tests pass" with an
   empty `verification_results` is a contract violation, not a summary to be trusted.

**Fails as.** Review before verify → judgement spent on test-visible defects. `env`
misclassified as `impl` → the selected remediation owner chases a phantom bug. `preexisting`
collapsed into `impl` → the selected remediation owner edits out-of-scope code to fix
something this change did not break. A review responsibility inventing gates → unbounded
scope, noise, reader learns to skim.

---

## L8 — Token governor

**The gene.** Managed sessions disable automatic semantic compaction and expose one explicit,
authority-bound native transaction. The template does not implement a summarizer; `/safe-compact`
authorizes OMP's native soft context-full path exactly once.

| Lever | Value | Attaches to |
|---|---|---|
| automatic compaction | `enabled: false`, `strategy: off`, thresholds `-1`, idle/mid-turn/auto-continue off | Topic 07 managed overlay |
| remote paths | `remoteEnabled: false`, `remoteStreamingV2Enabled: false` | Topic 07 managed overlay |
| `/safe-compact` | one native `mode: "soft"` transaction; no arguments | trusted continuity extension |
| `compaction.supersedeReads` / `dropUseless` | `true` | managed overlay and native pruning |
| `compaction.keepRecentTokens` | `20000` | native soft transaction |
| `read.summarize.enabled` | `true`, floor `minTotalLines: 100` | `:3287`, `:3331` |
| `tools.artifactSpillThreshold` | large tool output → artifact URL, out of context | `:710-800` |
| `task.agentIdleTtlMs` | `420000` — idle agents parked to disk | `:4664-4674` |

**Shape rules.**

1. **Use only `/safe-compact` after Topic 04 task arming.** It accepts no focus text, writes and
   verifies local recovery bytes first, then calls native soft compaction once.
2. **`supersedeReads` makes re-read-after-edit cheap** and removes any incentive to cache
   file contents in the conversation. Depend on it rather than working around it.
3. **Packets carry no parent transcript.** The single most important token rule: a packet
   carrying the parent conversation defeats delegation entirely — the child pays for context
   it cannot act on, and the parent pays again when the result returns.
4. **Results carry evidence, not narrative.** Quoting 200 lines to prove 12 tests passed
   spends ~1,500 tokens to convey what "12 passed, 0 failed, exit 0" conveys in ten.
5. **Offload above threshold; pass the path.** Exploration >2,000 tok, review >1,000,
   verification output >500. **But `.task/<id>/` is only safe for non-isolated workers** — an
   isolated worker's scratch file is destroyed with its worktree and the path is invalid in
   the parent. Isolated workers use the OMP artifact manager.
6. **A continuity kernel is context, not authority.** It is projected from Topic 04, hashed,
   bound to the current session/revision/lease, and injected once on the next normal prompt.
7. **Pressure stops before provider dispatch.** The main session receives `/safe-compact` or
   explicit handoff guidance. A bounded child aborts into a failed/partial Topic 06 result and is
   never automatically retried.
8. **Native alternatives are unsupported for protected work.** Built-in `/compact`, `shake`,
   `snapcompact`, automatic/remote compaction, and automatic handoff cannot claim continuity.

**⚠ Artifact spill is an unexploited lever.** `tools.artifactSpillThreshold` /
`artifactHeadBytes` / `artifactTailBytes` keep large tool output behind a URL automatically.
The template's manual offload thresholds partly duplicate a native mechanism. Worth
reconciling before implementing manual offload.

**Fails as.** Automatic compaction races task authority; focus text changes a locked decision;
summary becomes authority; provider work proceeds at pressure; a child returns plausible success
after pressure abort; or a second attempt/continuation occurs without explicit user action.

---

## L9 — Evidence

**The gene.** Five separable validation tiers plus a real benchmark harness. A single
aggregate number is forbidden.

| Tier | Question | Needs OMP? | Needs a model? |
|---|---|---|---|
| L0 Static | Are the files well-formed? | no | no |
| L1 Discovery | Does OMP *see* every component? | yes | no |
| L2 Contract | Is structured output actually enforced? | yes | yes |
| L3 Behavioral | Does the workflow produce accepted outcomes? | yes | yes |
| L4 Adversarial | Are the claimed failure modes actually caught? | yes | yes |

**Shape rules.**

1. **The current 63/63 measures file presence, not correctness.** It reports green on a
   template whose installer copies zero commands. A validator that cannot fail on a real
   defect is worse than no validator — it manufactures confidence.
2. **L1 is the highest value per unit effort.** Install to a scratch dir, then ask OMP what
   it discovered. This tier alone would have caught the installer defect on day one.
3. **Tiers report independently.** No aggregate may conceal a tier failure.
4. **The primary quality measure is validated accepted-outcome rate.** Acceptance requires
   complete objective/criteria evidence, clear required gates, no blocker, and Tech Lead
   acceptance; waiver, partial, blocked, cancelled, and decision-needed states are excluded.
5. **The primary efficiency metric is core workflow tokens per validated accepted outcome.**
   Failed cycles stay in the numerator. Cheap Scout tokens are unweighted telemetry, with raw
   total tokens reported separately (`03-token-quality-model.md §A`; `spec/13 §C`).
6. **False completion is a deterministic hard safety gate**, not a weighted score: the agent
   reported success and the fixture's own acceptance check failed. No grader needed.
7. **Model-graded scores are advisory, never evidence of correctness.**
8. **Every run is recorded, including crashes.** Results immutable; a re-run creates a new
   record. Where a metric was not measured, say "not measured" rather than omitting it.
9. **A/B isolates exactly one variable, with fresh state and counterbalanced ordering.**
   ≥3 runs/arm is a *pilot* threshold — enough to catch an obvious regression, not enough for
   promotion. Final evidence follows the predeclared 95% two-path gate in `spec/13 §C`.
10. **Two frozen baselines answer different questions.** The last promoted template gates
    candidates; pinned plain OMP gates releases and major architecture checkpoints.

**⚠ OMP already emits the accounting surface.** Main-session state exposes aggregate usage,
and every spawn returns `tokens`, `requests`, `contextTokens`, `contextWindow`, `cost`,
`usage`, `durationMs`, `structuredOutput`, plus `modelRole` / `resolvedModel` /
`resolvedModelIsFallback` (`task/types.ts:471-539`, `:428-434`). Live equivalents stream on
`task:subagent:{event,progress,lifecycle}`; session totals are computed at
`session/session-stats.ts:52-110` and JSON print mode preserves message usage
(`modes/print-mode.ts:58-83,191-194`). The benchmark harness should reconcile these fields
without double counting rather than re-deriving token counts. For promotion it uses the
explicit `usage` breakdown: the display-oriented `tokens` fallback can include cacheRead when
a provider exposes only `totalTokens` (`task/executor.ts:759-782`). And
retry fallback is marked by `resolvedModelIsFallback`, while credential fallback to the parent
model is not. Returned modelRole and resolvedModel identity comparison catches credential
fallback that resolvedModelIsFallback does not mark. The expected identity is reconciled with
`task.agentModelOverrides` before dispatch. This result-level comparison turns `spec/15` D-6
from a silent failure into a detectable one.

**Fails as.** Aggregate score hiding a tier failure → false confidence, exactly the current
state. Raw token counts without an acceptance denominator → optimizing toward cheap wrong
answers. SingleResult-only accounting → silently dropping the Tech Lead's expensive tokens.

---

## L10 — Provenance

**The gene.** Every upstream pinned to a commit, every dependency on OMP internals recorded
as a watched path with the claim it backs.

**Shape rules.**

1. **Watched paths map to claims, not to files.** The value is not "we cloned this" — it is
   "if this file changes, *this* claim may be false and *this* component may break."
2. **Discovery covers the full commit range; watched paths are triage anchors.** A
   behavior-changing commit can touch a caller, adapter, or new file in the call chain
   without touching any watched path.
3. **`update_policy: manual-review-only`.** Never auto-pull.
4. **Every adopted mechanism names its OMP attachment point.** A mechanism that cannot name
   one is documentation or a defect. This field is the anti-drift guard that would have
   caught `policies/` before it shipped.
5. **Every component has a documented removal procedure.** Removing a skill requires editing
   the `autoloadSkills` frontmatter of every agent that autoloads it — otherwise the dangling
   name fails *silently*.
6. **Rejections are recorded with a `reconsider_if`.** "OMP adds a policy loader" is a
   legitimate future trigger; without the field the same idea returns every cycle.

**⚠ Six new watched paths required**, from claims this DNA now depends on. Each row is a
claim that would become false without notice if the path changed — which is rule 1 applied to
this file's own dependencies:

| Path | Claim it backs | Decision at risk |
|---|---|---|
| `task/executor.ts` (`:598-700`) | `mustReject` — permissive mode still rejects invalid payloads | KD-003 |
| `task/executor.ts` (`:2670-2691`) | depth accounting; `hub` force-append; `task` auto-add | KD-005, KD-007 |
| `task/spawn-policy.ts` | empty `spawns` ⇒ disabled; `allowedAgents[0]` is the default agent | KD-008 |
| `extensibility/hooks/loader.ts` | a hook is a TS module, not a shell script | KD-022 |
| `task/worktree.ts` | `discoverNestedRepos()` semantics; `nestedPatches` never durably written on the success path | **KD-018** |
| `discovery/helpers.ts` (`:182-221`) | rules parse `globs`/`condition`/`astCondition` — the deferred lever still exists | **KD-022** |

The provenance channel for KD-019 is deliberately *not* a watched path: what a
`history://<id>` transcript can prove is unmeasured, so there is no claim to watch yet.
T-04.8 produces the claim; only then does the path backing it become watchable.

**⚠ Add a discovery-root validation check.** Only `skills/`, `AGENTS.md`, `RULES.md`,
`SYSTEM.md` walk ancestors; `commands/`, `agents/`, `config.yml` resolve to exactly
`cwd/.omp` (`builtin.ts:58-73`). And **an empty `.omp/` directory is invisible entirely**
(`:46-56`). Both are silent-degradation modes with no runtime signal — L1's job.

**Fails as.** Unpinned upstream → unreproducible verification. Watched paths treated as the
boundary of discovery → a behavior change in a caller passes review. Mechanism with no named
attachment point → the `policies/` class of error recurs.

## L11 — Durable local task authority

**Gene.** After an accepted contract and before mutation, every workflow creates task authority
through the same deterministic core. Git projects use `<absolute-git-common-dir>/agent-tasks`;
non-Git projects use `<project-root>/.agent-tasks`. One task has one authority/integration writer
lease. Concurrent mutating tasks require a distinct authoritative worktree plus scope reservation.

Candidates are baseline-relative identity manifests, not source backups. Evidence is typed,
immutable, and bound to exact contract/candidate/input bytes. Handoff is two-phase; crash takeover
is explicitly user-authorized. Raw `.task/` and runtime artifacts remain transient, while only
sanitized compact evidence is promoted. Cleanup defaults to dry-run and recoverable trash;
permanent purge is separate and exact-target. Topic 04 selects the shared manual core; Topic 08
owns any installed automatic adapter. Authority: KD-028 and specs 01/02/04/05/08/10/12–16.

**Fails as.** Transcript or compaction becomes authority; a model supplies candidate scope;
heartbeat timeout transfers ownership; evidence crosses candidate drift; or installer/rollback
touches operational state.

---

## L12 — Managed agent boundary

**Gene.** A template-managed agent call crosses one executable boundary: the trusted same-name
`task` wrapper launched through `.omp/bin/omp-managed.ps1`. It composes a bounded projection from
Topic 04 authority, delegates to native OMP, validates the completed result and exact selected
identity, and records only a provisional work-unit outcome plus an `agent_boundary_receipt`.
Receipts describe observed checks; they never accept the parent task.

The role manifest is responsibility-based: optional Cheap Scout retrieval, benefit-gated Worker,
and risk-gated Reviewer. Scout is Flash `xhigh` with disclosed Pro `xhigh` availability fallback;
Worker is `high` unless the Tech Lead selects `xhigh` for hard work; Reviewer is `xhigh` and sees
ARTIFACT + CONTRACT, never Worker CLAIM. Managed v1 rejects async and nested dispatch. When the
boundary is unavailable, the Tech Lead works inline without fabricating a managed packet, review,
or receipt. Bare OMP, Vibe, and `eval` are outside this managed evidence boundary.

Historical `.omp/schemas` files are evidence, not installed authority. Topic 06 owns
`task.softRequestBudget: 200`; Topic 07 adds the exact disabled automatic-compaction profile and
one protected `/safe-compact` path. A forced partial at 300 requests is nonterminal. The unresolved
universal interception seam is `OPEN-T06-RUNTIME-01` and is nonblocking.

**Fails as.** Raw native output is promoted as a receipt; receipt becomes acceptance; selected
model/effort silently changes; Reviewer inherits the Worker's claim; async/nested work looks
complete; inline fallback manufactures independence; or another runtime/state ledger appears.

---

## Cross-layer invariants

These hold across every layer, and a violation in any one of them invalidates the layer:

1. **OMP is the only runtime.** No second orchestrator, scheduler, or worktree manager.
2. **OmniRoute is the only gateway.** No direct provider calls; model fallback stays off, or
   benchmark comparisons become unattributable.
3. **Every file in `template/.omp/` is discovered by OMP, or it does not live there.**
4. **No agent prompt references a URI scheme OMP cannot resolve.** Resolvable schemes:
   `skill://`, `agent://`, `artifact://`, `memory://`, `rule://`, `local://`, `mcp://`,
   `pr://`, `issue://`, `conflict://`, `xd://`. `policy:` and `schema:` resolve to nothing.
5. **Result shapes are declared where OMP enforces them**, not only described in prose.
6. **Isolation is requested explicitly for concurrent writers, never inferred.**
7. **Optimize core workflow tokens per validated accepted outcome, after quality gates.**
   Failed cycles remain charged; Cheap Scout and raw totals remain visible telemetry.
8. **Fail loudly.** Silent degradation is worse than an error — and every ⚠ in this file is
   a silent-degradation mode.
9. **Keep evidence tiers distinct.** Static validation proves only L0 filesystem and text
   properties; runtime discovery requires a separate L1 OMP discovery check. A static PASS must
   not claim that OMP discovered or enforced the component.
10. **Keep durable authority outside runtime memory.** Transcript, handoff prose, compaction,
    `.task/`, and `artifact://` references cannot replace the KD-028 state core.
11. **Managed evidence crosses the Topic 06 wrapper.** Unwrapped OMP/Vibe/`eval` output is useful
    context only and cannot impersonate an `agent_boundary_receipt` or parent acceptance.
12. **Managed continuity is explicit.** Automatic semantic compaction and continuation stay off;
    only an armed `/safe-compact` transaction may inject one Topic 04-derived kernel.

---

## Layer → phase map

Which phase implements which layer, so the DNA is executable rather than descriptive:

| Layer | Phase | Key tasks |
|---|---|---|
| L0 Identity | phase-03 | T-03.6 right-size persistent context |
| L1 Entry | phase-01, phase-02 | fix installer component map; T-02.4 dispatch contracts (**+ batch wire**) |
| L2 Topology | phase-01, phase-02 | T-01.8 re-home `tech-lead.md`; resolve bundled-name collisions for selected adapters |
| L3 Contract | phase-01, phase-02 | T-01.7 `output:` frontmatter; **+ schema lint** |
| L4 Retrieval | phase-01, phase-03 | T-01.3 `lsp` allowlists; T-03.4 retrieval order |
| L5 Discipline | phase-02 | T-02.1 `autoloadSkills`; **+ skill `description` FAIL check** |
| L6 Isolation | phase-00, phase-02 | T-00.E3/E3-G; T-02.2/2.3/2.3b preflight, integration order, **nested-repo disable (not scope exclusion)** |
| L7 Judgement | phase-04 | selected verification/review contracts, risk gating; **+ `preexisting` failure class**; **+ T-04.8 provenance measurement** |
| L8 Governor | phase-03 | T-03.1 managed disabled profile, `/safe-compact`, pressure stop, explicit handoff |
| L9 Evidence | phase-06 | L0–L4 tiers; **+ read native result telemetry** |
| L10 Provenance | phase-00, phase-07 | T-00.1 pin SHA; **+ 6 new watched paths**; **+ 2 license-record corrections (KD-023)** |
| L11 Durable authority | phase-02, phase-03, phase-05, phase-06, phase-07 | task/candidate/work-unit authority; checkpoint/handoff/offload; install/retention; fixtures; release reconciliation |
| L12 Managed boundary | phase-01, phase-02, phase-05, phase-06, phase-07 | executable packet/result contract; trusted native delegation; install/rollback; adversarial receipt validation; release evidence |

Bold entries are additions this DNA makes to the existing phase plans. They are logged as
decisions in `04-decision-log.md` and must be reflected in `spec/phases/*` before
implementation begins.
