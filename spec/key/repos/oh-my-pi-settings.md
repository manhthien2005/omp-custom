# Repo Report — oh-my-pi (settings surface)

> Authority boundary: This repository report is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.


> **Path:** `_research/upstreams/oh-my-pi`
> **SHA:** `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (`git -C oh-my-pi rev-parse HEAD`)
> **License:** see `oh-my-pi-orchestration.md` — unchanged by this pass.
> **Size:** 6,323 tracked files. **This report covers one file:**
> `packages/coding-agent/src/config/settings-schema.ts` (5,887 lines).
> **Read this pass:** the schema's structure in full (imports, type defs, `SETTINGS_SCHEMA`
> body `:388-5590`, accessor helpers `:5591-5670`); **all 453 keys enumerated mechanically**;
> ~52 key definitions read in full with their `description` text.
> **Scope note:** this is the report `repos/README.md` lists as missing. It replaces
> "146 of 607 keys referenced anywhere; **461 never examined**" — a line that is **wrong in
> both numbers**. See §5-1.

---

## 1. What this file is

The single source of truth for every OMP setting. Each entry declares `type`, `default`, and
optional `ui` metadata (tab, group, label, description). `Settings` exposes typed path access
(`settings.get("compaction.enabled")`), and `Object.keys(SETTINGS_SCHEMA)` at
`cli/config-cli.ts:51` is the canonical key list — which makes the count in this file
mechanically checkable rather than a matter of opinion.

It matters to us for one reason: **it is the complete list of levers we can pull without
editing a file.** `01-dna.md` requires every mechanism to name an OMP attachment point; a
setting is the cheapest possible attachment point, because deploying one costs zero tokens and
no discovered file.

---

## 2. Mechanism inventory

Rather than 453 rows, this section reports the measurement and then the keys that change a
recorded decision. Namespace-level coverage is in §3; the full uncovered list is the basis for
§5.

### 2a. The measurement (mechanical, reproducible)

Keys are declared in **two syntactic forms**, and this matters — see the caveat below.

| Quantity | Value | How |
|---|---|---|
| Dotted keys, quoted — `"task.batch": {` | 415 | `^\t"<key>": {` in the schema body |
| Flat keys, **unquoted** — `temperature: {` | **38** | `^\t<ident>: {` in the schema body |
| **Total setting keys** | **453** | all 453 blocks carry a `type:` field — verified by block-parsing, zero exceptions |
| **Namespaces** (first dotted segment, dotted keys only) | **91** | matches the audit's "~90" |
| Keys with `ui:` metadata (surfaced in the settings panel) | 336 | `ui: {` occurrences |
| Keys **without** `ui:` (settable, not shown in the panel) | 117 | 453 − 336 |

**The 38 unquoted keys are a trap I fell into first.** A regex requiring quotes returns 415
and looks authoritative. The unquoted block includes `temperature`, `topP`, `topK`, `minP`,
`defaultThinkingLevel`, `readLineNumbers`, `inlineToolDescriptors`, `includeWorkspaceTree`,
`personality`, `steeringMode`, `modelRoles`, `enabledModels` — i.e. **sampling, thinking, and
prompt-assembly controls**, not leftovers. Any future count must match both forms.

**Coverage depends on what you count as "our project", and the spread is large:**

| Corpus | Covered | Coverage |
|---|---|---|
| A. `spec/ template/ registry/ docs/ evals/ scripts/` — **the deployable surface** | **28** | **6.2%** |
| B. A + `spec/key/` decision docs (excluding `repos/`) | 64 | 14.1% |
| C. B + all `repos/` reports, including this one | 101 | 22.3% |

Bare keys are counted only on a backtick- or quote-delimited match, to avoid prose collisions
(`temperature` appears as an English word; excluded on that basis).

**A is the number that matters: 6.2%.** C is inflated by self-reference — this report cites
~52 keys, so measuring coverage against a corpus containing it counts my own citations as
coverage. The audit's 24% was closest to C-style counting on a wrong denominator. The honest
statement is: **of 453 settings, 28 appear anywhere in what we would actually ship.**

Largest namespaces: `hindsight` 27, `providers` 24, `mnemopi` 23, **`task` 20**,
`compaction` 18, `memories` 16, `tools` 14, `skills` 12, `tui` 11, `retry` 10, `read` 10.

The three largest (`hindsight`, `mnemopi`, `memories` — 66 keys, 15% of the schema) are
memory/recall subsystems already rejected by `reject-005`/`reject-015`. That is a legitimate
non-decision, and it means raw coverage understates *considered* coverage. It does not rescue
the namespaces in §2b.

### 2b. Keys that change or challenge a recorded decision

| # | Key (`:line`) | Default | Why it matters | Grade |
|---|---|---|---|---|
| **S1** | `edit.enforceSeenLines` (`:3237`) | **`false`** | "Reject edits anchored on lines a prior read/search never displayed in full." A **runtime guard against edits to unread code** — the fabrication failure mode KD-019 says is "behavioral in v0". It is a boolean, and it is off | **A** |
| **S2** | `tools.abortOnFabricatedResult` (`:4192`) | `true` | "Stop the model immediately when it starts hallucinating a tool result mid-turn." A native false-completion defense, already on. KD-019 does not mention it | **A** |
| **S3** | `tools.intentTracing` (`:4182`) | `true` | "Ask the agent to describe the intent of each tool call before executing it." Already-on, unpriced: an extra generation before *every* tool call | **A** |
| **S4** | `task.softRequestBudget` (`:4677`) + `.softRequestBudgetNotice` (`:4695`) | `200` / `true` | Per-subagent request budget. Crossing injects a wrap-up steer; **at 1.5× the run is force-stopped and the agent must yield partial findings.** This is a real enforcement boundary, and `spec/05`/KD-011 discuss budgets without it | **A** |
| **S5** | `tools.approvalMode` (`:3676`) | **`"yolo"`** | Auto-approves **every** tier including `bash`, `eval`, `task`. `always-ask` and `write` exist. `spec/15` treats risk gating as prompt-level; this is the runtime's own gate, defaulted open | **A** |
| **S6** | `tools.approval` (`:3660`) | `{}` | Per-tool `allow`/`prompt`/`deny`, and the comment states overrides "are honored in **every** approval mode" (`:3667`) — i.e. a `deny` here survives `yolo`. A precise, unused enforcement lever | **A** |
| **S7** | `skills.enable{Codex,Claude,Pi,Agents}{User,Project}` (`:4790-4802`) | **all `true`** | Six foreign skill-discovery roots, all on. This is **G-8 with an exact fix**: six booleans | **A** |
| **S8** | `commands.enable{Claude,Opencode}{User,Project}` (`:4811-4850`) | **all `true`** | Four foreign *command* roots, incl. `~/.claude/commands/` and `.claude/commands/`. Same class as S7 | **A** |
| **S9** | `skills.ignoredSkills` / `includeSkills` / `customDirectories` (`:4804-4808`) | `[]` | Allowlist/denylist for the skill listing. **KD-014 caps the library at 10 because every subagent pays for the full listing — `includeSkills` is the enforcement mechanism**, and it is unmentioned | **A** |
| **S10** | `task.disabledAgents` (`:4721`), `task.agentModelOverrides` (`:4726`), `task.agentPrewalk` (`:4730`) | `[]` / `{}` / `{}` | G-9's levers: routing and model control per agent, no file edits. Records confirm they exist | **A** |
| **S11** | `prewalk.enabled` (`:458`) + `task.prewalk` (`:4734`) | both `false` | Start on the strong model, hand off to a cheap model **at the first edit/write after the todo list exists**. A native strong-plans/cheap-executes split — i.e. aider's architect/editor (A19) as a *setting* | **A** |
| **S12** | `tier.subagent` (`:1466`) | `"inherit"` | Service tier for spawned task/eval subagents. `spec/09` routes models but never mentions service tier | **A** |
| **S13** | `model.toolCallLoopGuard.{enabled,threshold,exemptTools}` (`:1176-1198`) | `true` / `5` / — | Detects 5 consecutive identical tool calls and injects a corrective steer. A native anti-loop mechanism absent from `spec/02` | **A** |
| **S14** | `model.loopGuard.{enabled,checkAssistantContent,toolCallReminder}` | — | A second, distinct loop guard. Two guards, neither in our spec | **A** |
| **S15** | `features.unexpectedStopDetection` (`:5190`) | `false` | "Use a small model to detect when the assistant says it will continue but stops without tool calls; automatically prompt it to continue." Directly relevant to SD-2 (`completed` with no patch) | **A** |
| **S16** | `task.isolation.commits` (`:4526`) | `"generic"` | `generic` \| `ai` commit messages for nested-repo changes. Touches KD-018 (nested repo disables parallel isolation) | **A** |
| **S17** | `task.isolation.apply` (`:4498`) | **`true`** | Confirms the CR-45 / E3-M premise from the schema side: apply defaults **on** | **A** |
| **S18** | `task.eager` (`:4554`) | `"default"` | `default` \| `preferred` \| `always` — how hard the system prompt pushes delegation. `always` adds a first-turn delegation reminder. A topology lever `spec/03` does not use | **A** |
| **S19** | `grep.enabled` / `contextBefore` / `contextAfter` (`:3780-3792`) | `true` / — | L4 retrieval is `lsp · grep · read ranges`; grep's context window is tunable and unexamined | **A** |
| **S20** | `read.summarize.*` (6 keys) + `read.toolResultPreview` | — | Read-tool summarization thresholds (`minBodyLines`, `minCommentLines`, `prose`, `unfoldLimit`, `unfoldUntil`). Direct L4/L8 token levers, none referenced | **A** |
| **S21** | `edit.mode` (`:3175`) `"hashline"`, `edit.fuzzyMatch` `true`, `edit.fuzzyThreshold` `0.95` | | OMP's edit applier has a fuzzy threshold. Compare aider's `find_similar_lines` 0.6 — ours is far stricter, which is the right default and worth recording | **A** |
| **S22** | `compaction.idleThresholdTokens` (`:2305`) `200000`, `.idleTimeoutSeconds`, `.handoffSaveToDisk`, `.remote*` | | Six compaction keys uncovered, including **idle compaction** — a trigger KD-009 (`shake` vs `snapcompact`) does not model | **A** |
| **S23** | `eval.js` / `eval.rb` / `eval.jl` (`:3575-3586`) | all `true` | Per-language eval backends. **OQ-H (task vs eval) is gated on settings that are already on**, and `oh-my-pi-orchestration.md` verified JS in full and py/rb/jl by grep — these three keys are the toggles for exactly that untested surface | **A** |
| **S24** | `security.enabled` (`:4077`) | `false` | "OMP-native security scan planning, execution, and the read-only `security://` resource namespace." An entire native security surface, off, and absent from `spec/15` | **A** |
| **S25** | `task.maxConcurrency` (`:4595`) `32`, `maxRecursionDepth` `2`, `agentIdleTtlMs` `420_000`, `maxRuntimeMs` `0`, `maxEffort` `"max"` | | Concurrency and recursion limits. `maxRecursionDepth: 2` is a hard structural bound on our topology depth | **A** |
| **S26** | `thinkingBudgets.{minimal,low,medium,high,xhigh,max}` (6 keys) | — | Token budgets per effort level. `spec/09` routes effort (KD-010) with none of these examined | **A** |
| **S27** | `lsp.diagnosticsOnEdit`, `.diagnosticsDeduplicate`, `.formatOnWrite` | — | Verification-adjacent: diagnostics on edit is a free correctness signal for L7 | **A** |
| **S28** | `advisor.immuneTurns`, `ttsr.repeatGap`, `ttsr.repeatMode` | — | Advisor/TTSR tuning. `oh-my-pi-prompt-discovery.md` flagged `TtsrManager.addRule` as unread; these are its knobs | **A** |
| **S29** | `magicKeywords.ultrathink` (`:—`) | — | G-5 lists three magic keywords; the fourth namespace member confirms each is individually toggleable — the fix for G-5's uncontrolled injection | **A** |
| **S30** | `gc.*` (6 keys), `checkpoint.enabled`, `worktree.*` | — | Session GC/retention and checkpointing. Relevant to `spec/12` rollback, unexamined | **A** |

### 2c. From the 38 unquoted keys — four that matter

These were missed on the first pass (see §2a) and are reported separately because their
omission is the most likely place a *future* count goes wrong too.

| # | Key (`:line`) | Default | Why it matters | Grade |
|---|---|---|---|---|
| **S31** | `includeWorkspaceTree` (`:1242`) | `false` | Renders the workspace directory tree into the system prompt, and the description carries its own warning: *"**WARNING: This can bust prompt caching across sessions when files are modified.**"* A persistent-tier item that also breaks cache — the worst combination in `01-dna.md`'s cost model. Correctly off; **must stay off**, and `spec/05` should say so | **A** |
| **S32** | `inlineToolDescriptors` (`:1209`) | `"auto"` | Renders full tool descriptors in the system prompt **and strips descriptions from provider tool schemas so descriptor text is sent once.** `auto` = on for Gemini, off otherwise. This is a direct lever on the persistent-tier cost that `context7.md §6` measures for MCP tools — the deduplication mechanism our MCP cost analysis assumed did not exist | **A** |
| **S33** | `defaultThinkingLevel` (`:1093`) | **`"high"`** | Reasoning depth for thinking-capable models, defaulting to `high`. KD-010 deploys `task.enableEffort` for *per-spawn* effort; this is the baseline every turn inherits, and `spec/09` never states it. Pairs with `thinkingBudgets.*` (S26) to give the actual token figure | **A** |
| **S34** | `readLineNumbers` (`:3247`) | `false` | Prepends line numbers to `read` output. Our entire evidence convention is `file:line` citation (`_CONTRACT.md` rule 2, and every grade-A claim in this corpus). With this off, a worker citing line numbers is counting them itself — a plausible source of citation drift in the results L9 collects | **A** |

`personality` (`:1266`, default `"default"`) and `includeModelInPrompt` (`:1231`, default
`true`) also render into the system prompt; both are small and neither changes a decision, but
they confirm the pattern: **the unquoted block is where prompt assembly is configured.**

---

## 3. Transferable to omp-custom

Every row is a **setting**, so the attachment point is always `.omp/settings.json` (or the
documented baseline) and the cost tier is always **zero tokens** — settings never enter a
context. What varies is behavioral risk. That makes this the cheapest inventory in the corpus.

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| **S9** `skills.includeSkills` | settings baseline | **zero** | **ADOPT — highest value in this report** | KD-014 caps the library at 10 *by policy*. This makes it **enforced**: an explicit allowlist means a stray skill in a foreign root cannot inflate every subagent's listing. Turns a documented cap into a runtime one |
| **S7 S8** foreign discovery toggles (10 booleans) | settings baseline | **zero** | **ADOPT** | G-8's fix, exactly. Ten booleans close every foreign skill/command root. Without this, a developer's `~/.claude/commands/` silently enters our workflow and our token measurements are not reproducible — which breaks `spec/13`'s ratchet before it starts |
| **S4** `task.softRequestBudget` | settings baseline | zero | **ADOPT** | A real enforcement boundary with a documented force-stop at 1.5×. `spec/05` wants exactly this (G-6 is the turn-budget cousin). Also **must be documented**, because a force-stopped subagent yielding partial findings is a failure mode our result contracts have to handle — see §5-3 |
| **S1** `edit.enforceSeenLines` | settings baseline | zero | **ADOPT (candidate) — needs one experiment** | The single most interesting key in the schema. It is a *runtime* guard against editing unread lines; KD-019 concluded false-completion resistance is behavioral in v0 because schemas cannot prove provenance. This does not prove provenance either, but it **blocks the specific act** of anchoring an edit on unseen lines. Default `false`. Risk: false rejections on legitimate edits. Cheap to test |
| **S6** `tools.approval` per-tool `deny` | settings baseline | zero | **ADOPT** | Per-tool deny that the comment says is honored in **every** approval mode (`:3667`), including `yolo`. This is the enforcement primitive OQ-E asks about, from the settings side rather than the `tools:` allowlist side. It should be part of how OQ-E is answered |
| **S5** `tools.approvalMode` | settings baseline | zero | **ADAPT — document, do not blindly change** | Default `yolo` auto-approves `bash`/`eval`/`task`. For an automated workflow that is arguably correct; the defect is that our spec never states it. `spec/15` must record the chosen mode and why. Changing it to `write` would make our own workflow prompt for exec and hang |
| **S15** `features.unexpectedStopDetection` | settings baseline | zero (+ small-model calls) | **ADAPT** | Detects "I'll continue" followed by silence — a sibling of SD-2's false completion. Costs small-model calls; unmeasured. Trigger: SD-2's fixtures show stop-without-completion is a real failure in our runs |
| **S13 S14** loop guards | settings baseline | zero | **ADOPT (verify on)** | Two native anti-loop mechanisms, `toolCallLoopGuard` on by default at threshold 5. Our spec has no loop-termination story of its own beyond `mini-swe-agent`'s termination-set discussion. Confirm both are on and record them |
| **S11** `prewalk.enabled` / `task.prewalk` | settings baseline | zero | **DEFER — strong candidate** | A native strong-plans/cheap-executes handoff at the first edit/write. This is aider's A19 as a setting, and it interacts with our Tech Lead → Implementer split. Trigger: after `spec/09` routing is measured, test prewalk against the two-agent split — it may make one of our agents unnecessary. **Do not adopt before OQ-H**, since it changes who does the editing |
| **S23** `eval.{js,rb,jl}` | settings baseline | zero | **ADOPT as OQ-H prerequisite** | OQ-H's experiment needs these on (they are, by default). Record them so the experiment is reproducible |
| **S20 S19** `read.summarize.*`, `grep.context*` | settings baseline | zero | **ADAPT** | Direct L4/L8 token levers. `spec/05` sets budgets it cannot currently enforce; these enforce at the tool boundary. Needs measurement to pick values — belongs with OQ-C |
| **S26** `thinkingBudgets.*` | settings baseline | zero | **ADAPT** | KD-010 deploys `task.enableEffort`; these six keys are what effort levels *mean* in tokens. Required to price `spec/09`'s routing rather than assert it |
| **S27** `lsp.diagnosticsOnEdit` | settings baseline | zero | **ADOPT (candidate)** | A free correctness signal at edit time feeding L7 judgement. Verify it does not flood context on large edits |
| **S12** `tier.subagent` | settings baseline | zero | **ADOPT as documentation** | `inherit` tracks the main agent's tier. Must be recorded because OmniRoute is our only gateway and an unexpected tier change makes benchmark comparisons unattributable (cross-layer invariant #2) |
| **S25** `task.maxRecursionDepth` = 2 | — | zero | **ADOPT as a constraint** | A hard bound on topology depth. `spec/03` should state it: Tech Lead → worker → sub-worker is the limit at default |
| **S22** `compaction.idle*` | settings baseline | zero | **ADAPT** | Idle compaction at 200 k tokens is a trigger KD-009 does not model. Folds into OQ-C |
| **S16 S17** `task.isolation.{commits,apply}` | settings baseline | zero | **ADOPT as documentation** | S17 confirms `apply` defaults `true` from the schema side, independent of the dispatch-time resolution in CR-45. S16 matters for KD-018's nested-repo case |
| **S24** `security.enabled` + `security://` | — | zero | **DEFER** | An entire native security surface we have never looked at. Trigger: before `spec/15` is called complete, someone must read `src/security/` and decide. Cannot be decided from a settings key alone |
| **S18** `task.eager` | settings baseline | zero | **DEFER** | `preferred`/`always` inject delegation guidance into the system prompt — i.e. persistent-tier text we do not control. Interesting and slightly dangerous; do not touch before measuring |
| **S3** `tools.intentTracing` | settings baseline | zero (but per-tool-call generation) | **ADAPT — measure, consider off** | On by default, and it makes the model narrate intent **before every tool call**. That is output tokens on every action across every subagent. Plausibly the largest unexamined cost in our workflow. Might be worth keeping for auditability — but it must be a decision, not a default |
| **S21** `edit.fuzzyThreshold` 0.95 | — | zero | **ADOPT as documentation** | Worth recording against aider's 0.6 (`aider.md` A21). Ours is far stricter; a stricter threshold means more explicit failures and fewer silent wrong-place edits, which suits fail-loudly |
| **S28 S29 S30** | settings baseline | zero | **ADAPT** | S29 is G-5's fix (per-keyword toggles). S30 touches `spec/12` rollback. S28 tunes the advisor path flagged unread |
| `hindsight.*` `mnemopi.*` `memories.*` `autolearn.*` (66+ keys) | — | — | **REJECT (confirms `reject-005`/`reject-015`)** | Memory/recall subsystems. Rejected by constraint, and this pass confirms the *size* of what is being declined: 16% of the schema |
| `tui.*` `stt.*` `tts.*` `speech.*` `live.*` `irc.*` `collab.*` `browser.*` `searxng.*` `exa.*` `providers.*` (~100 keys) | — | — | **REJECT** | Terminal UI, voice, chat, browser automation, search vendors, provider credentials. Genuinely irrelevant to a workflow template, as `05-coverage-audit.md §A` says |

**Net new mechanisms for the spec: 0** — settings are not mechanisms.
**Net new deployable levers: 11** (S1, S4, S6, S7, S8, S9, S13, S23, S27, plus documenting
S5/S12/S17/S25). All zero-token. This is the highest ratio of decision-value to token-cost in
the entire corpus, and it is the reason the missing report mattered.

---

## 4. What this file shows that we deliberately will not do

- **Adopt the memory stack.** 66 keys across `hindsight`/`mnemopi`/`memories`, plus
  `autolearn`. Rejected by `reject-005`/`reject-015`; this pass prices the refusal at 16% of
  the schema rather than leaving it a vague "we don't use memory".
- **Change `tools.approvalMode` to be safer.** Tempting and wrong: `write`/`always-ask` prompt
  for exec tools, and an automated workflow has nobody to answer the prompt. The correct move
  is per-tool `deny` (S6) plus documenting `yolo` as a deliberate choice — not a stricter mode
  that deadlocks.
- **Turn on everything that looks like a safety feature.** S1 (`enforceSeenLines`) and S15
  (`unexpectedStopDetection`) both default off, and both plausibly cause false rejections or
  extra model calls. Each needs one experiment. Flipping unmeasured booleans because they
  sound protective is the settings-layer version of the `.omp/policies/` error.
- **Treat `ui:`-less keys as private.** 117 keys have no UI metadata but are fully settable —
  including `skills.includeSkills`, our best KD-014 enforcement lever. Absence from the
  settings panel is not absence from the API.
- **Build anything the settings already do.** S13/S14 (loop guards), S4 (request budget),
  S1 (seen-line guard), S15 (stop detection) are native. Any spec section proposing a
  prompt-level version of one of these is proposing to reimplement the runtime — the exact
  error `01-dna.md`'s attachment-point rule exists to catch.

---

## 5. Contradictions with our current spec or registry

### 5-1. `05-coverage-audit.md §A` — both key counts are wrong, and so is the file path

The audit states:

> `config/settings-schema.ts` is 5,887 lines and defines **607 dotted setting keys** across
> ~90 namespaces. […] **146 appear anywhere, 461 do not.** Coverage is **24%**.

Corrections:

| Claim | Audit | Actual | Evidence |
|---|---|---|---|
| Path | `config/settings-schema.ts` | **not a defect — withdrawn** | The audit's own header declares its convention: "OMP citations are `packages/coding-agent/src/<path>:<line>`". The path is correct under that convention |
| Line count | 5,887 | **5,887 ✓** | `wc -l` — correct |
| Namespaces | ~90 | **91 ✓** | distinct first dotted segments |
| **Total keys** | **607** | **453** | 415 quoted-dotted + 38 unquoted-flat; all 453 blocks carry `type:` |
| Referenced | 146 | **28** in the deployable surface | see the three-corpus table in §2a |
| **Coverage** | **24%** | **6.2%** deployable / 22.3% counting all decision docs | 28 or 101 of 453 |

The 453 figure is confirmed by block-parsing: iterating the schema body and opening a new block
at each `^\t"<key>": {` **or** `^\t<ident>: {` yields exactly 453 blocks, and **every one
contains a `type:` field** — no false positives. `Object.keys(SETTINGS_SCHEMA)`
(`cli/config-cli.ts:51`) is the runtime's own answer to the same question and would return the
same set.

**How I got 415 first, and why it is worth recording:** the obvious regex requires quoted keys.
It is clean, it returns a confident-looking number, and it silently drops 38 settings including
`temperature`, `topP`, `defaultThinkingLevel`, and `includeWorkspaceTree` — four of which turn
out to matter (§2c). The lesson generalizes past this file: **a mechanical count is only as
good as its assumption about syntax**, and the audit's 607 is very likely a different instance
of the same class of error rather than carelessness.

Where 607 might have come from: `type:` appears **467** times file-wide and `default:` **466**,
both inflated by nested `options[]` entries and the preamble (`:1-387`). `docs/settings.md`
contains only ~169 dotted tokens (112 in table rows), so it is not the source either. **I could
not reproduce 607 with any pattern tried, and I state the mechanism as unknown, not merely
probable.** It may have come from a different artifact or SHA.

**Consequence.** The audit's *direction* is not merely preserved, it is understated: the
deployable surface references **6.2%** of settings, not 24%. But the wrong numbers appear in
`05-coverage-audit.md §A`, `repos/README.md`, and the `oh-my-pi-settings` status row, and a
wrong recorded number is inherited as a constraint by every future maintainer. All three need
patching. **This is the correction with the widest blast radius in this report.**

A note on honest measurement, since the coverage number is now three numbers: counting the
`repos/` reports as "coverage" is self-referential — this report alone cites ~52 keys, and
citing a key in a report is not the same as deciding about it. **Corpus A (6.2%) is the figure
to quote**; B and C are recorded so nobody has to guess which corpus produced the number.

### 5-2. `repos/README.md` — the row this report replaces

> `oh-my-pi-settings.md` | 607 setting keys, ~90 namespaces | 146 of 607 keys referenced
> anywhere; **461 never examined**

Should read: **453 setting keys (415 dotted + 38 flat), 91 namespaces; 28 referenced in the
deployable surface, 425 never examined.**

### 5-3. `spec/05` / KD-011 — a native enforcement boundary is missing

KD-011 records that subagent budgets are "acknowledged, not discovered at runtime". S4 shows
OMP enforces one already: at 1.5× `task.softRequestBudget` (default 200) **the run is
force-stopped and the agent must yield its partial findings** (`:4685`).

That is not a budget we acknowledge — it is a **truncation mode our result contracts must
handle**. A force-stopped Explorer yields partial findings; if the Tech Lead treats that
result as complete, we get exactly the false-completion class SD-2 addresses, arriving through
a path SD-2 does not cover. This needs a line in `spec/05` and a case in KD-020's failure
classification.

### 5-4. KD-019 — `edit.enforceSeenLines` is a counter-example worth naming

KD-019 concludes false-completion resistance is behavioral in v0 because "schemas prove shape,
never provenance". True of schemas. S1 is not a schema — it is a runtime guard that rejects an
edit anchored on lines no prior read displayed. It does not prove provenance either, but it
**blocks the act** rather than describing the rule.

KD-019 should acknowledge it and either adopt it behind an experiment or record why not.
Leaving a native, zero-token, directly-on-point guard unmentioned in the decision that says
"we cannot do this at the runtime level" is the kind of gap this whole layer exists to close.

### 5-5. `spec/15` — two contradictions

1. **`tools.approvalMode` defaults to `yolo`** (`:3678`), auto-approving `bash`, `eval`, and
   `task`. `spec/15` discusses risk gating at the prompt and reviewer level and never states
   the runtime's own gate or which mode we run in. Whatever we choose, it must be recorded —
   an unrecorded `yolo` is an undocumented security posture.
2. **`security.enabled` (`:4077`) is an unexamined native surface** — scan planning, execution,
   and a `security://` resource namespace, defaulted off. `spec/15` cannot be called complete
   while an OMP-native security subsystem has never been opened.

### 5-6. `spec/03` — `task.maxRecursionDepth: 2` is an unstated structural bound

Default 2. Our topology (Tech Lead in the main session → workers) fits, but the bound is not
recorded anywhere, and any future proposal for a worker that spawns its own sub-workers hits it
silently.

### 5-7. `01-dna.md` L5 — KD-014's cap has an enforcement mechanism it does not name

L5 attaches discipline to `autoloadSkills`, and KD-014 caps the library at 10 because every
subagent pays for the full listing. `skills.includeSkills` (`:4808`) is an explicit allowlist
for that listing, and `skills.ignoredSkills` its complement. The cap is currently policy; these
keys make it enforced. Combined with S7's six foreign roots (all `true`), the current state is:
**our cap is unenforced and the listing is open to any skill in a foreign discovery root.**
That is a live hole in KD-014, not a future improvement.

### 5-8. No contradiction with CR-45 / E3-M

`task.isolation.apply` defaults `true` (`:4499`), consistent with the round-11 finding that
policy resolves at dispatch time from the live session. The schema default and the dispatch-time
resolution agree; nothing here reopens it.

---

## 6. Cost profile

Settings cost **zero tokens**: they are runtime state, never a context file. That makes the
cost question unusual — the cost of a setting is *behavioral*, not textual.

| Item | Token cost | Behavioral cost |
|---|---|---|
| S9 `includeSkills`, S7/S8 foreign toggles (11 keys) | **zero** | **Negative** — closing foreign roots *reduces* every subagent's skill listing. Direct saving on the per-spawn tier |
| S4 `softRequestBudget` | zero | Already active. Documenting it costs nothing; ignoring it costs a mishandled truncation |
| S1 `enforceSeenLines` | zero | Possible false rejections → retries. Unmeasured |
| S6 `tools.approval` deny-list | zero | None, if the denied tools are ones we never legitimately call |
| S13/S14 loop guards | zero | Already on. Each injected steer is a small context addition on a path that would otherwise loop |
| **S3 `tools.intentTracing`** | zero to configure | **Potentially large and currently unmeasured** — an intent statement generated before *every* tool call, in every subagent. Output tokens on every action. This is the one row where the default may be costing us significantly |
| S26 `thinkingBudgets.*` | zero | These *are* the token budgets. Setting them is how `spec/09`'s routing becomes priced rather than asserted |
| S15 `unexpectedStopDetection` | zero | Small-model call per suspected stop |
| S11 prewalk | zero | Changes which model edits — the point is that it *lowers* cost |

The structural observation: **the highest-leverage items in this report are all zero-token.**
Eleven deployable levers, no context cost, several of them (S9, S7, S8) net-negative. Compare
`aider`'s ranking engine — 1–4 k tokens per turn, persistent tier, rejected. The settings
surface is where cheap wins live, and it is the surface we had examined least.

---

## 7. Coverage and limits  (MANDATORY)

**Read in full:** `packages/coding-agent/src/config/settings-schema.ts` structurally —
imports (`:1-55`), type definitions and `TAB_GROUPS` (`:56-387`), and the accessor helpers
(`:5591-5670`). **All 453 keys enumerated mechanically** with line numbers.

**Read in full at the definition level (~52 keys):** every key cited in §2b and §2c, including its
`description` text — S1–S30's evidence is read, not inferred.

**Sampled:** `cli/config-cli.ts:51-58` (to confirm `Object.keys(SETTINGS_SCHEMA)` is the
canonical key list).

**Not opened:**
- **The consuming code for every setting.** This report says what each key *declares*; it does
  not trace what reads it. `edit.enforceSeenLines` (S1) is the clearest case: I read its
  description and default, **not its implementation**, so I cannot say what "a prior
  read/search never displayed in full" means operationally — whether a `grep` hit counts as
  displayed, how it interacts with `read` ranges, or what the rejection looks like. **S1 is the
  most consequential row in §3 and its semantics are grade B.**
- `config/settings.ts`, `capability/settings.ts`, `session/settings-stream-fn.ts`,
  `modes/components/settings-defs.ts` — the manager, capability gate, and UI layers.
- **`docs/settings.md`** — OMP's own settings documentation. Would likely corroborate or
  correct several §2b readings, and would probably explain the 607 discrepancy. Unopened.
- **All ~400 keys not individually read.** The uncovered keys were enumerated and grouped
  by namespace; I read definitions for those in §2b and judged the rest by name and namespace.
  **"Looks irrelevant from its name" is exactly the reasoning `00-method.md §A` warns
  against**, and it is what I did for `hindsight` (27), `mnemopi` (23), `memories` (16),
  `providers` (24), `tui` (11), and the voice/chat/browser namespaces (~60). A full pass could
  surface another S1-class finding in there.
- `src/security/` — S24 names a whole subsystem I did not open. §3 defers it for that reason.
- Everything else in the 6,323-file repo; see `oh-my-pi-orchestration.md` and
  `oh-my-pi-prompt-discovery.md` for their own limits.

**Claims that need a live run before use:**
- **S1** — does `enforceSeenLines` reject legitimate edits? Cheapest test: enable it, run one
  implementation fixture, count rejections. Blocks the §3 ADOPT-candidate.
- **S3** — the actual token cost of `intentTracing` across a full orchestrated run. This is a
  measurement, and §6 flags it as possibly the largest unexamined cost in the workflow.
- **S4** — is 200 requests reachable by our Explorer/Implementer in practice? If not, the
  force-stop is theoretical and §5-3's urgency drops.
- **S7/S8** — that closing the ten foreign toggles actually shrinks the skill listing. Should
  be visible in `contextTokens` telemetry (KD-012's surface).
- **S27** — does `lsp.diagnosticsOnEdit` flood context on large edits?
- Every "default" in this report is the **schema** default. Whether OMP's shipped config,
  a user's global settings, or a project file overrides any of them is **unverified** — and
  that matters, because our measurements are only reproducible if the effective values are
  pinned. This is arguably a prerequisite for `spec/13`'s ratchet and I did not check it.

**Anything suspected but not verified:**
- The **607** figure's origin. `type:` appears 467× and `default:` 466× file-wide; neither is
  607, and I could not reproduce it with any pattern tried. I checked `docs/settings.md`
  (825 lines, ~169 dotted tokens, 112 in table rows) — **not the source.** The count stands at
  453 by block-parsing with zero `type:`-less false positives; the origin of 607 is **unknown**,
  and it may be a different artifact or a different SHA.
- **My own first count was wrong (415), for a reason worth keeping:** the quoted-key regex
  missed 38 unquoted declarations. I caught it by cross-checking `type:` field counts against
  block counts and finding a 56-key discrepancy. Had I not run that cross-check, this report
  would have shipped a confident wrong number while *correcting* someone else's — which is the
  failure mode `_CONTRACT.md`'s anti-pattern list calls "confident summary of an unread file",
  in numeric form.
- Whether `skills.includeSkills` is an allowlist that *replaces* discovery or a filter applied
  *after* it. §3/§5-7's KD-014 enforcement claim depends on this and rests on the key name plus
  the adjacent `ignoredSkills`/`customDirectories` triple. **Grade B.** If it only filters
  post-discovery, it still caps the listing, so the conclusion likely survives — but the
  mechanism differs and it should be checked before being written into KD-014.
- Whether `tools.approval` `deny` truly overrides `yolo`. The claim rests on a **code comment**
  (`:3667`, "Overrides are honored in every approval mode") and the `ui.description` (`:3684`,
  "user policy may still prompt or block"), not on the approval implementation. This is a
  security-relevant claim on comment authority — grade **B**, and it should be A before OQ-E is
  answered with it.
- 117 keys have no `ui:` block. I read this as "settable but not surfaced in the panel". It is
  possible some are internal/deprecated and unsupported. Unverified, and it matters because
  `skills.includeSkills` — the S9 lever — is one of the 79.
