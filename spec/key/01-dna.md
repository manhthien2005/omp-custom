# 01 — The DNA

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
                        │ L7  JUDGEMENT     verifier · diff-reviewer  │  per gate
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

**The gene.** Three fixed sizes, user-selected, with one-way escalation.

| Size | Subagents | Attaches to | When |
|---|---|---|---|
| `/quick` | 0 — inline | SlashCommand — `builtin.ts:345` | 1 file, root cause known |
| `/standard` | 2–4 sequential | SlashCommand | 2+ files, or root cause unknown |
| `/orchestrated` | 4+, some parallel | SlashCommand | ≥2 genuinely independent workstreams |

**Shape rules.**

1. **The user picks the size; the command validates the pick.** A router that triages every
   task pays a classification turn on "fix the typo on line 12". Rejected — `spec/04 §B`.
2. **The Standard→Orchestrated boundary is independence, not size.** A large sequential task
   is Standard with more steps. Four agents doing four dependent things in sequence is
   strictly worse than one agent doing them: every handoff loses context and costs a spawn.
   This is the single most-violated sizing rule in multi-agent templates.
3. **Escalation restarts; it does not continue.** A `/quick` that escalates discards its
   partial transcript and re-enters Standard with what it learned as input. Continuing in
   place keeps the accumulated context the size change existed to shed.
4. **De-escalation is forbidden.** An over-sized run finishes over-sized. The tokens are
   already spent; abandoning mid-flight risks unmerged isolated worktrees.

**⚠ Wire-format correction — `task.batch` defaults to `true`** (`settings-schema.ts:4570`,
independently confirmed). The model-facing shape is **not** `{agent, task}`. It is:

```
{ context: string,          // REQUIRED — shared preamble, prepended to every item
  tasks: [ { name?, agent?, task, effort?, outputSchema?, schemaMode?, isolated? } ] }
```

Every dispatch example in `commands/*.md` must use this shape. The flat form still works for
internal callers but is **rejected model-side** when batch is on (`task/index.ts:192-202`).
This is a live defect in the current command files — `04-decision-log.md` KD-006.

**`context` is a genuine token lever, not overhead.** It is stated once and prepended to
every item, so shared scope, conventions, and acceptance criteria belong there rather than
copy-pasted into N packets. For a 4-way fan-out this is a ~3× reduction on the shared
portion of the packet.

**Fails as.** Commands documenting the flat wire → dispatch rejected at runtime, workflow
silently degrades to inline. Router-based sizing → triage tax on every trivial task.

---

## L2 — Topology

**The gene.** Flat. One coordinator that is the main session, four workers at depth 1, no
worker spawns anything.

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
3. **Verifier is separate from Implementer, permanently.** An agent that just wrote code
   reads its own output charitably. The Verifier's value is not that it runs commands — it is
   that it runs them *without having written the code*, so it has no intention to protect.
   Collapsing the two saves ~1 spawn and removes the entire defense.
4. **Observation-phase agents are never isolated.** Explorer, Verifier, and Reviewer must see
   the real merged tree. An isolated Verifier verifies a copy nobody ships.
5. **`reviewer` is renamed `diff-reviewer`.** OMP bundles an agent named `reviewer`; project
   agents win by first-name-wins precedence (`task/discovery.ts:87-133`), so the current
   name silently shadows a built-in. Shadowing may be intended, but it must be *chosen*.

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
`tech-lead.md` left in `agents/` → two topologies, divergent routing. Verifier merged into
Implementer → self-verification, the primary failure mode returns.

---

## L3 — Contract

**The gene.** Each worker declares its own result schema in its own frontmatter. The call
site overrides only for one-off narrowing.

| Producer | Contract | Attaches to | Grade |
|---|---|---|---|
| `explorer` | ranked evidence, no `files_changed` | `output:` — `helpers.ts:289` | A |
| `implementer` | `agent-result` | `output:` | A |
| `verifier` | `verification-result` | `output:` | A |
| `diff-reviewer` | `review-result` | `output:` | A |
| main session → worker | task packet | **plain string** — no input schema exists | A |

**Shape rules.**

1. **Schema travels with the agent, not the call site.** Frontmatter cannot be forgotten at
   a dispatch; an inline `outputSchema` repeated at every dispatch can, and drifts.
2. **The task packet is a string.** OMP offers no input-schema enforcement. `task-packet.yml`
   is a *composition checklist* for the session, not a validated contract. Say so.
3. **Flat, closed objects. No `$ref`.** The validator dereferences and throws if a `$ref`
   survives, degrading to an unconstrained object. Flat closed shapes also enable
   incremental section yields (`withSectionVariants`), which suit the Reviewer's
   finding-at-a-time output.
4. **Minimal required fields.** Each required field the model struggles with burns retry
   budget. Require only what the coordinator cannot proceed without.
5. **`maxLength` on evidence strings.** The only structural lever against a Verifier that
   pastes an entire test log into `evidence`.
6. **No chain-of-thought fields.** A schema field that invites narration works against the
   packet/result prohibitions in L8.

**⚠ Enforcement is stronger than the spec claims.** `spec/01 §4` and `spec/06 §B` state
that after 3 retries OMP "accepts the payload anyway — a strong nudge, not a hard gate."
The actual rule in `finalizeSubprocessOutput` (`executor.ts:598-700`):

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

**Fails as.** Schema at call site only → forgotten on one dispatch, that worker unvalidated.
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
2. **`lsp` must be in the allowlist or `task.enableLsp: true` is inert.** Both gates apply
   (`lsp/index.ts:1639` + allowlist). The current Explorer is instructed to use LSP and
   cannot call it — the one place the template pays for a baseline deviation and receives
   nothing.
3. **No persistent repository map.** Aider's repo-map is adopted as a *principle*: the
   Explorer builds the map for the task at hand and discards it. A materialized map goes
   stale on the next commit, costs tokens whether or not the task needs it, and duplicates
   what `lsp symbols` computes lazily and accurately. *(provisional — aider dossier pending)*
4. **Retrieval order is guidance with a bounded budget, not exhaustion gates.** Local code
   and types → local docs → official versioned docs → Context7 → web. The real failure is
   the level-1-to-level-5 jump: a web search for what the type definition next to the call
   site already answered. But "exhaust level N first" is wrong too — use the most
   authoritative source for the question type, within a budget, then escalate.
5. **Context7 is optional, never assumed.** It requires an MCP server wired into the session.
   Agents must fall back to level 3 silently when it is absent.

**⚠ Read-summarization has a floor the spec does not record.**
`read.summarize.minTotalLines` is **100** (`settings-schema.ts:3331`) — files shorter than
that are read verbatim regardless. So `read-summarize: false` on the Explorer costs nothing
on small files and everything on large ones, which is precisely backwards from its intent.
`unfoldUntil: 50` / `unfoldLimit: 100` govern BFS unfolding of elided spans, giving the
model a cheap way to expand exactly the region it needs. Remove the Explorer override.

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
2. **`autoloadSkills` for invariants that govern a specific role.** Assigned to
   `implementer`, `verifier`, `diff-reviewer` — the three that make completion claims.
   Explorer never claims completion and does not pay.
3. **Parent rules *do* propagate to subagents.** `structured-subagent.ts:438` passes
   `rules: session.rules` to the child. The earlier claim that `RULES.md` never reaches
   workers was wrong. `autoloadSkills` is still preferred, on different grounds: forwarding
   carries the *entire* parent rulebook with opaque cost, whereas autoload delivers exactly
   one intended body at a known price — and a buried rule in a large forwarded rulebook is
   deprioritized in practice.
4. **Autoloaded bodies must stay small.** `evidence-before-completion` ≤ 500 tokens, because
   it is now paid per Implementer *and* per Verifier spawn. Overflow goes into a reference
   file read on demand.
5. **The one correct duplication.** "Never claim complete without verification" lives in both
   `RULES.md` (for the main session) and the autoloaded skill (for workers). Disjoint
   audiences, so document it as intentional or a future dedup pass deletes the worker copy.
6. **Quality gates are selected by the session at packet-build time and passed as data.** A
   Reviewer that invents its own gates produces unbounded scope — the false-positive failure
   mode its own contract guards against.

**⚠ Rules are a far richer surface than the spec uses.** `buildRuleFromMarkdown`
(`helpers.ts:182-221`) parses `globs` (path-scoped activation), `condition`, `astCondition`
(AST-conditional activation), `scope`, and `interruptMode`
(`never|prose-only|tool-only|always`). `.mdc` is accepted alongside `.md`. `instructions/`
carries `applyTo` as a second path-scoped channel. **A path-scoped rule costs nothing on
files it does not match** — this is the cheapest per-token quality mechanism in OMP, and the
template currently uses none of it. Flagged as the highest-value unexplored lever;
`04-decision-log.md` KD-022 holds it for post-v0 pending an evaluated baseline.

**Fails as.** `alwaysApply` on a skill expecting subagent reach → inert, looks configured.
Dangling `autoloadSkills` name → `resolveAutoloadSkills` filters it silently, discipline
just stops. Missing skill `description` → skill vanishes with no error.

---

## L6 — Isolation and integration

**The gene.** Isolation is requested per call, only for concurrent writers. Parallel results
are captured, then integrated serially by the coordinator in a fixed order.

| Agent | `isolated` | Why |
|---|---|---|
| `explorer` | `false` | read-only; isolation buys nothing, costs a materialization |
| `verifier` | `false` | must observe the real merged tree |
| `diff-reviewer` | `false` | must review the real diff |
| `implementer` (single, Standard) | `false` | sole writer; change lands where Verifier and user can see it |
| `implementer` (parallel, Orchestrated) | **`true`** | concurrent writers corrupt each other |

**Shape rules.**

1. **`mode: auto` selects a *backend*, never *whether* to isolate.** It answers "which
   filesystem mechanism", not "which agents". An Implementer spawned without `isolated: true`
   writes directly to the shared tree regardless of `mode`. This misreading is the single
   most consequential one available in this layer.
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
   Verifier does **not** run on a partially integrated tree. There is no atomic batch-merge
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
implement → verify → [review, risk-gated] → report
                ↑
          FAIL short-circuits back to Implementer; review is skipped
```

**Shape rules.**

1. **Verification precedes review, and a `FAIL` skips review entirely.** Reviewing code that
   fails its own tests spends judgement on defects the suite already found.
2. **Failure classification is mandatory: `impl | env | flaky | preexisting`.** Nothing else
   in the system captures it, and it determines the next action. Conflating `env` with `impl`
   sends an Implementer to "fix" working code, which usually means changing things until the
   symptom moves.

   `preexisting` is a required fourth category, not a variant (CR-36). A deterministic
   failure that was already failing on the baseline is none of the other three — it is not
   `flaky` (it reproduces), not `env` (the environment is fine), and not `impl` (this change
   did not cause it). A three-way enum forces it to `impl`, which dispatches the Implementer
   at code outside the change's scope. Route instead: record baseline evidence, exclude from
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
7. **Review is risk-gated.** Never in Quick. In Standard: public API change, security-touching
   code, new interface, or a diff whose scope discipline is in question. Always in
   Orchestrated. The signal is not diff size — it is *whether the change creates a contract
   someone else depends on*, which is what review catches and tests do not.
8. **The coordinator does not re-derive verification from prose.** "All tests pass" with an
   empty `verification_results` is a contract violation, not a summary to be trusted.

**Fails as.** Review before verify → judgement spent on test-visible defects. `env`
misclassified as `impl` → Implementer chases a phantom bug. `preexisting` collapsed into
`impl` → Implementer edits out-of-scope code to fix something this change did not break.
Reviewer inventing gates → unbounded scope, noise, reader learns to skim.

---

## L8 — Token governor

**The gene.** OMP owns compaction. The template configures it and never implements its own.

| Lever | Value | Attaches to |
|---|---|---|
| `compaction.strategy` | **`snapcompact` by default**; `shake` must be chosen | `settings-schema.ts:2164-2198` |
| `compaction.supersedeReads` | `true` — older reads of the same file pruned | `:2346-2355` |
| `compaction.dropUseless` | `true` — no-match/timeout results pruned once consumed | `:2357-2367` |
| `compaction.keepRecentTokens` | `20000` | `:2285` |
| `read.summarize.enabled` | `true`, floor `minTotalLines: 100` | `:3287`, `:3331` |
| `tools.artifactSpillThreshold` | large tool output → artifact URL, out of context | `:710-800` |
| `task.agentIdleTtlMs` | `420000` — idle agents parked to disk | `:4664-4674` |

**Shape rules.**

1. **Never implement template-side compaction.** No summarize-the-conversation step in any
   command. OMP owns this; a second compactor produces conflicting decisions.
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
6. **`snapcompact` vs `shake` is a real choice.** `snapcompact` archives history as dense
   images with **no LLM call**; `shake` drops heavy content in place and recovers via
   artifact. `spec/05` assumes `shake` throughout while OMP defaults to `snapcompact` —
   so the assumed strategy must be deployed explicitly. Which is *better* for this workflow
   is unmeasured; `04-decision-log.md` KD-009 routes it to evaluation rather than asserting.

**⚠ Artifact spill is an unexploited lever.** `tools.artifactSpillThreshold` /
`artifactHeadBytes` / `artifactTailBytes` keep large tool output behind a URL automatically.
The template's manual offload thresholds partly duplicate a native mechanism. Worth
reconciling before implementing manual offload.

**Fails as.** Assuming `shake` while `snapcompact` runs → measured behavior does not match
the documented model. `.task/` inside an isolated worktree → result carries a dead path.
Template-side compaction → conflicting decisions with OMP's.

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
4. **The primary metric is tokens per accepted outcome.** A cheap wrong run costs more than
   an expensive right one, because the retry is real cost moved to an unmeasured column.
5. **False-completion rate is the headline quality metric**, and it is fully deterministic:
   the agent reported success and the fixture's own acceptance check failed. No grader needed.
6. **Model-graded scores are advisory, never evidence of correctness.**
7. **Every run is recorded, including crashes.** Results immutable; a re-run creates a new
   record. Where a metric was not measured, say "not measured" rather than omitting it.
8. **A/B isolates exactly one variable, with fresh state and counterbalanced ordering.**
   ≥3 runs/arm is a *pilot* threshold — enough to catch an obvious regression, not enough for
   a "quality neutral-or-better" claim. Report per-fixture paired deltas, not arm means.

**⚠ OMP already emits the accounting surface.** Every spawn returns `tokens`
(input+output+cacheWrite, excluding cacheRead), `requests`, `contextTokens`, `contextWindow`,
`cost`, `usage`, `durationMs`, `structuredOutput`, plus `modelRole` / `resolvedModel` /
`resolvedModelIsFallback` (`task/types.ts:471-539`, `:428-434`). Live equivalents stream on
`task:subagent:{event,progress,lifecycle}`. The benchmark harness should read these rather
than re-deriving token counts — and `resolvedModelIsFallback` makes model misrouting
**observable at the result**, turning `spec/15` D-6 from a silent failure into a detectable
one. This is the single most useful unexploited finding in the runtime dossier.

**Fails as.** Aggregate score hiding a tier failure → false confidence, exactly the current
state. Raw token counts without an acceptance denominator → optimizing toward cheap wrong
answers.

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
7. **Optimize tokens per accepted outcome.** Never trade correctness for token count.
8. **Fail loudly.** Silent degradation is worse than an error — and every ⚠ in this file is
   a silent-degradation mode.
9. **Static validation passing must imply runtime discovery succeeded**, or the number is a
   lie.

---

## Layer → phase map

Which phase implements which layer, so the DNA is executable rather than descriptive:

| Layer | Phase | Key tasks |
|---|---|---|
| L0 Identity | phase-03 | T-03.6 right-size persistent context |
| L1 Entry | phase-01, phase-02 | fix installer component map; T-02.4 dispatch contracts (**+ batch wire**) |
| L2 Topology | phase-01, phase-02 | T-01.8 re-home `tech-lead.md`; rename `diff-reviewer` |
| L3 Contract | phase-01, phase-02 | T-01.7 `output:` frontmatter; **+ schema lint** |
| L4 Retrieval | phase-01, phase-03 | T-01.3 `lsp` allowlists; T-03.4 retrieval order |
| L5 Discipline | phase-02 | T-02.1 `autoloadSkills`; **+ skill `description` FAIL check** |
| L6 Isolation | phase-00, phase-02 | T-00.E3/E3-G; T-02.2/2.3/2.3b preflight, integration order, **nested-repo disable (not scope exclusion)** |
| L7 Judgement | phase-04 | verifier/reviewer contracts, risk gating; **+ `preexisting` failure class**; **+ T-04.8 provenance measurement** |
| L8 Governor | phase-03 | T-03.1 compaction (**+ deploy `shake` explicitly**) |
| L9 Evidence | phase-06 | L0–L4 tiers; **+ read native result telemetry** |
| L10 Provenance | phase-00, phase-07 | T-00.1 pin SHA; **+ 6 new watched paths**; **+ 2 license-record corrections (KD-023)** |

Bold entries are additions this DNA makes to the existing phase plans. They are logged as
decisions in `04-decision-log.md` and must be reflected in `spec/phases/*` before
implementation begins.
