# 00 — Current State Audit

> **OPUS PROPOSED SPEC v1** — Independent verification of every ChatGPT hypothesis, plus new findings.
> Every row below was verified against OMP source at `_research/upstreams/oh-my-pi` (shallow clone, `packages/coding-agent/src`) and against the raw bytes of `template/` in this repo. Claims I could not verify from source are labelled NEEDS EXPERIMENT and carry no severity.

## Verification method

Three classes of evidence were used, and they are not interchangeable:

1. **Source-verified** — a named file and symbol in the OMP implementation decides the question. Cited as `path:symbol`.
2. **Byte-verified** — the actual file content in `template/`, read with `cat -A` where delimiters mattered. Used because GitHub's HTML view silently swallowed the YAML `---` fences and produced a false P0 in my own first pass (see F-20).
3. **NEEDS EXPERIMENT** — requires a live OMP session; no source read can settle it.

## Correction to my own first pass

Before the table: two findings I initially recorded were wrong, and the reason matters for how this spec should be reviewed.

I initially recorded that `tech-lead.md` and `verifier.md` were missing YAML frontmatter delimiters — a P0 that would break agent discovery entirely. That was an artifact of reading files through GitHub's rendered HTML via WebFetch. Reading the raw bytes (`cat -A`) shows `---$` as line 1 in all five agent files. **The finding is retracted.** I have re-derived every frontmatter claim below from raw bytes plus `discovery/helpers.ts:parseAgentFields`.

I also initially marked the LSP findings (F-11, F-12) NOT CONFIRMED on the reasoning that the agents don't ask for LSP. They do — `explorer.md` line 22 instructs "Use LSP hover, references, and grep before reading full files" while its `tools:` allowlist omits `lsp`. **Both are now CONFIRMED.** ChatGPT was right and my first pass was wrong.

---

## Audit table — ChatGPT's hypotheses

| # | Finding | ChatGPT | Opus verification | Severity | Evidence | Recommended direction |
|---|---|---|---|---|---|---|
| F-01 | Installer uses `workflows`, runtime uses `.omp/commands` | P0 | **CONFIRMED** | **P0** | `install-template.ps1:50` maps `"workflows" = "workflows"`; `$Components` default (line 19) includes `"workflows"`; no `template/.omp/workflows` dir exists (byte-verified); the `default` switch branch guards on `Test-Path` and silently skips. `commands/` is never in the component list. | Rename alias to `commands`; make an unresolvable component a hard error, not a silent skip |
| F-02 | README/report install args don't match script params | P0 | **CONFIRMED** | **P1** | `README.md:30` and `docs/report-design.md:186-192` pass `-TargetDir`; the script declares `-Target` and `-ProjectDir` (no `-TargetDir`). PowerShell rejects the unknown param, so the documented command fails outright. `docs/installation.md` uses the correct params — so docs disagree with each other. | Single documented invocation, generated from the param block |
| F-03 | Installer defaults to DryRun while docs imply real install | P0 | **PARTIALLY CONFIRMED** | **P2** | `[switch]$DryRun = $true` (verified) is correct and safe. The doc problem is real but narrow: `README.md:27` shows `-DryRun` as if opt-in, implying the bare form installs. | Document that apply requires `-DryRun:$false` |
| F-04 | Installer overwrites despite a Force control | P0 | **CONFIRMED** | **P1** | `[switch]$Force` is declared but never read. The apply loop calls `Copy-Item -Force` unconditionally. Protection is only the `$protected` name list. | Make `$Force` gate overwrites; fail closed on collision without it |
| F-05 | Project/global config copied rather than merged | P0 | **CONFIRMED** | **P0** | `config` component maps `template/.omp/config.yml` → `<dest>/config.yml` via `Copy-Item -Force`. For `-Target user` the destination is `~/.omp/agent/config.yml` — **the entire live global baseline in §3 is replaced by a 5-line `modelRoles:` file.** All of `task.*`, `edit.*`, `lsp.*`, `compaction.*` are silently lost. | NEVER auto-install config; merge or emit a diff for manual application |
| F-06 | Rollback docs/params don't match uninstall behavior | P0 | **NOT CONFIRMED** | — | `uninstall-template.ps1` declares `-BackupDir` (mandatory), `-Target`, `-ProjectDir`, `-DryRun`. The installer prints exactly `uninstall-template.ps1 -BackupDir "<backup>"`. These agree. `docs/installation.md:64` also agrees. | No change (but see F-21 for a real rollback defect) |
| F-07 | YAML "schemas" are docs, not enforced structured output | P1 | **CONFIRMED** | **P1** | OMP's real mechanism is `outputSchema` + `schemaMode` passed **per task call** (`task/types.ts:118,126,154`; enforced in `tools/yield.ts:buildOutputValidator`). `.omp/schemas/*.yml` are custom keys (`required_fields:`, `field_rules:`) with **no discovery hook and no consumer**. They are prose. | Keep as authoring source; generate real JSON Schema; pass via `outputSchema` |
| F-08 | `.omp/policies/` is not an OMP-native discovered concept | P1 | **CONFIRMED** | **P1** | `discovery/builtin.ts` enumerates the discovered subdirs of `.omp`: `commands`, `rules`, `prompts`, `extensions`, `instructions`, `hooks`, `tools`, `skills`, plus `settings.json`/`config.yml`. **Neither `policies` nor `schemas` appears anywhere in discovery.** | Reclassify as build-time source; inline the decisions the agents actually need |
| F-09 | `policy:*` references have no native resolver | P1 | **CONFIRMED** | **P1** | `tech-lead.md:19` says select size "based on `policy:workflow-sizing`"; `orchestrated.md:36` references `policy:quality-gates`. Grep for a `policy:` URI resolver returns nothing; the read tool's scheme list is `memory://, skill://, agent://, artifact://, rule://, local://, mcp://` (`tools/read.ts:3270`). The reference is a dangling pointer the model will either ignore or hallucinate. | Delete the pseudo-URI; inline the rule or move it into a skill |
| F-10 | `isolation.mode=auto` alone doesn't isolate child tasks | P1 | **CONFIRMED** | **P1** | `task.isolation.mode` selects the **backend**, not whether a given task isolates (`settings-schema.ts:4449-4469` — values are `apfs`/`btrfs`/`projfs`/`rcopy`/…). Per-task isolation is the **`isolated?: boolean`** field in the task schema (`task/types.ts:createTaskSchema`), only present when isolation is enabled. Nothing in the template ever sets `isolated`. | Set `isolated` explicitly per role; document that `auto` ≠ "on" |
| F-11 | Explorer asks for LSP without LSP in its allowlist | P1 | **CONFIRMED** | **P1** | `explorer.md` frontmatter: `tools: read, grep, glob`. Body line 22: "Use LSP hover, references, and grep…". An explicit `tools:` list is the allowlist (`parseAgentFields`, which only appends `yield`). The instruction is unsatisfiable. | Add `lsp` to the allowlist or remove the instruction — see 07 |
| F-12 | Implementer similarly missing LSP | P1 | **CONFIRMED** | **P2** | `tools: read, grep, glob, edit, write, bash` — no `lsp`. Lower severity than F-11: the Implementer's body doesn't demand LSP, and `lsp.diagnosticsOnWrite=true` still fires on the edit path (`edit/index.ts:124`) independent of the tool. | Add `lsp`; it is the highest-value tool for a code-editing role |
| F-13 | Tech Lead topology conflicts with Quick workflow | P1 | **CONFIRMED, root cause differs** | **P1** | Not a conflict — an orphan. No command file spawns `tech-lead`; `quick.md` says the Tech Lead "handles this workflow inline". So the main session is already the Tech Lead and `tech-lead.md` has no caller. Worse, spawning it would consume 1 of only 2 recursion levels (`task.maxRecursionDepth=2`), leaving workers at the ceiling. | Adopt Option A explicitly (main session = Tech Lead); delete the agent — see 03 |
| F-14 | Some roles disable read summarization unnecessarily | P1 | **CONFIRMED** | **P1** | `read-summarize: false` on `explorer.md`, `verifier.md`, `reviewer.md`. The field is real: `parseAgentFields` reads `frontmatter.readSummarize`, and `parseFrontmatter` kebab→camel normalizes it (`utils/src/frontmatter.ts:normalizeKeys`). So this **actively disables** the baseline `read.summarize.enabled=true` on the three read-heaviest roles. | Remove from Explorer and Reviewer; keep only where exact bytes are required |
| F-15 | Verifier floods context with successful output | P1 | **PARTIALLY CONFIRMED** | **P2** | The schema is already evidence-shaped (`evidence: key output lines`). But nothing caps it, and `verifier.md` says "Read the full output" without a "quote only failures" rule. Risk is real, magnitude unproven. | Add explicit rule: full output for failures, one summary line for passes |
| F-16 | Reviewer reads too much source instead of diff-first | P1 | **PARTIALLY CONFIRMED** | **P2** | `reviewer.md` does say "review the actual diff", which is right. But "read the actual changed files and their diff context" invites whole-file reads, and `read-summarize: false` (F-14) removes the safety net. | Mandate diff-first with named expansion triggers |
| F-17 | RULES.md over-restricts ambiguity/scope/retry | P1 | **NOT CONFIRMED** | — | The 8 invariants constrain objective risk (verification, secrets, scope, transcript forwarding, live-dir writes), not autonomy. Item 8 ("state the ambiguity and ask") is the only autonomy-adjacent one and is scoped to genuine ambiguity. | Keep. One narrowing proposed in 11 |
| F-18 | Static validation passes while runtime is broken | P1 | **CONFIRMED** | **P1** | `validate-template.ps1` checks file existence, `length/4` token estimates, three literal phrase greps, and `Trim().Length > 10` for YAML. It never parses YAML, never validates frontmatter against `parseAgentFields`, never checks that referenced dirs exist. **It reports 63/63 on a template whose installer cannot install its own commands.** | Tiered validation — see 13 |
| F-19 | Benchmark measures metadata, not execution | P1 | **CONFIRMED** | **P1** | `benchmark.ps1` globs fixtures, prints a format description, tells the user to hand-write result YAML. It never invokes `omp`. `-DryRun` only changes a printed line. There are 3 fixtures total for 10 planned task classes. | Rebuild on `omp -p` + session stats — see 13 |

---

## New findings

| # | Finding | Severity | Evidence | Recommended direction |
|---|---|---|---|---|
| F-20 | GitHub HTML view drops YAML frontmatter fences, producing false P0s | **INFO** | My own first pass. `cat -A` shows `---$` on line 1 of all five agent files. | Process note: audit raw bytes, never rendered HTML |
| F-21 | Rollback restores from backup but never deletes newly-created files | **P1** | `uninstall-template.ps1` copies backup → dest. Files the installer *created* (which by definition are absent from the backup) survive the "rollback". A fresh `.omp` install is therefore unrollbackable. | Roll back from the install manifest, not the backup alone |
| F-22 | Installer writes no manifest | **P1** | No manifest is produced. Without the created-file list, F-21 is unfixable and idempotency is unverifiable. | Emit a manifest; make it the rollback authority |
| F-23 | `-Target user` writes into the live OMP dir, contradicting RULES.md #5 | **P1** | `$dest_omp = ~/.omp/agent` when `-Target user`. `RULES.md` #5 forbids modifying `~/.omp/agent/` without explicit approval. The installer has no approval gate beyond the dry-run default. | Require an explicit confirmation token for `-Target user` |
| F-24 | Custom model roles work, but only if config is installed — which F-05 makes unsafe | **P1** | Verified supported: `getModelRoleAlias` accepts a candidate when `isModelRole(candidate) \|\| settings?.getModelRole(candidate) !== undefined` (`config/model-resolver.ts:925`). Built-ins are the 10 in `model-roles.ts:MODEL_ROLE_IDS` — `tech-lead` is not among them, so `@tech-lead` resolves **only** via `modelRoles:` in config. That config is exactly what F-05 says must not be auto-installed. | Ship roles as a documented merge fragment; add a preflight that verifies each `@role` resolves |
| F-25 | Five roles all point at one model — the abstraction is untested | **P2** | `config.yml` maps all five roles to `omniroute/codex/gpt-5.6-sol-high`. Correct for today's single-model reality, but no role has ever resolved to anything distinct, so the indirection is unexercised. | Keep the indirection; add a fixture that proves two roles can differ |
| F-26 | `spawns: ""` is a no-op, and `tools: task` already implies `spawns: "*"` | **P2** | `parseArrayOrCSV("")` yields no entries → `spawns` undefined. Then `if (spawns === undefined && tools?.includes("task")) spawns = "*"`. Workers don't include `task`, so they can't spawn regardless — the empty string does nothing. Harmless today; a trap if `task` is ever added to a worker. | Drop `spawns: ""`; rely on the absence of `task` |
| F-27 | `task.enableLsp` default is `false` upstream; baseline sets `true` | **INFO** | `settings-schema.ts:4615` — default `false`, described as "Off by default to keep subagents cheap". The §3 baseline enables it. That is a deliberate, correct choice for this workflow, but it means LSP-in-subagents is a **local** deviation from upstream and must be stated as such. | Record as an intentional deviation in 09 |
| F-28 | `evidence-before-completion` is the one rule that must not be optional, yet is lazy-loaded | **P1** | It encodes RULES.md #1. Skills are advertised by description and pulled on the model's judgment; `alwaysApply`/`hide` exist in `SkillFrontmatter` (`capability/skill.ts`). A no-false-completion rule that loads only when the model decides it needs it inverts the guarantee. | Its content belongs in RULES.md; keep the skill only for the detailed procedure |
| F-29 | `escalation.yml` has zero references anywhere | **P1** | Grep: the only hit is its own `policy: escalation` header. No agent, command, or skill mentions it. | Delete, or fold into RULES.md. Do not keep an unreferenced policy file |
| F-30 | `agent-result` schema self-contradicts on `verification_results` | **P2** | `verification_results` is listed under `optional_fields`, while `field_rules` says `status: completed` requires ≥1 entry. A generated JSON Schema cannot express both. | Conditional requirement, or split into two result shapes |
| F-31 | Workers are told to "return schema: X" with no mechanism to do so | **P1** | Every worker body says e.g. "Return schema: `agent-result`". No task call sets `outputSchema`, and there is no `schema:` frontmatter key (`parseAgentFields` reads `output`, not `schema`). Workers will emit **prose shaped like** a schema, which the parent must then parse — the exact failure mode `yield` exists to prevent. | Wire `output`/`outputSchema` for real — see 06 |
| F-32 | `read.summarize` is a global setting; per-agent override is the only lever | **INFO** | Confirms `readSummarize` frontmatter is the right mechanism — the finding is that F-14 uses it backwards (disabling on cheap-scan roles). | See F-14 |

---

## Classification

**Architectural flaws** — F-07, F-08, F-09, F-13, F-31 (abstractions with no runtime consumer; the workflow's structured-output story is prose)

**Runtime bugs** — F-01, F-05, F-10, F-11 (each causes silent wrong behavior, not an error)

**Installer bugs** — F-01, F-04, F-05, F-21, F-22, F-23

**Documentation bugs** — F-02, F-03

**Token/performance** — F-14, F-15, F-16 (F-14 is the clearest single regression: summarization disabled on the three read-heaviest roles)

**Maintainability** — F-26, F-29, F-30, F-24, F-25

**Missing validation** — F-18, F-19 (the 63/63 green build on a non-installable template is the most misleading artifact in the repo)

**Needs experiment** — none of the frontmatter questions remain open; all were settled from source. What genuinely needs a live session: whether `auto` isolation picks ProjFS on this Windows host, and the real token delta from F-14.

## Severity discipline

No P0 was assigned for aesthetics. The four P0-class items are F-01 (commands never install), F-05 (global baseline destroyed by `-Target user`), and their doc counterpart F-02. Everything that merely wastes tokens or duplicates prose is P1 or lower, even where it is architecturally ugly. Two of ChatGPT's six P0 candidates (F-03, F-06) do not survive as P0: one is correct-but-underdocumented behavior, the other is simply not true.
