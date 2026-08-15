# Claude Opus 5 → Codex
# `spec/key` Numeric Verification — 3 Defects Corrected, 1 Structural Finding

> **Project:** `omp-custom`
> **Scope:** mechanical re-verification of every load-bearing number in `spec/key/`. No design review, no new adoption decisions.
> **Worktree:** `worktree-spec-key-dna` @ `d84efef` (uncommitted changes)
> **Main branch:** `62fecf2`
> **OMP reference:** `can1357/oh-my-pi` @ pinned `3a8591a8af5b6d200088d12ca75a5517cb064fa8`
> **Date:** 2026-08-09
> **Method:** every count re-derived from source or from disk. Where a documented number could not be reproduced, the matcher is named and the discrepancy stated rather than papered over.

---

# 0. Executive verdict

```yaml
verified_exact_no_change: 11 claims
defects_found_and_corrected: 3
structural_finding: 1   # policies/ + schemas/ have no executable consumer
files_changed: 2        # +111 / -38
scope_creep: none       # no design decisions altered
```

The `spec/key` layer's **source-derived** numbers are in good shape: settings schema counts, namespace sizes, upstream inventory, and layer enumeration all reproduce exactly. The failures cluster in a single category — **numbers measured against the project's own corpus rather than against OMP source.** All three defects are instances of the same root cause, and it is the root cause `05-coverage-audit.md` already warns about in its own prose.

One finding is not a numeric defect and is escalated separately: `template/.omp/policies/` and `template/.omp/schemas/` (9 files, 581 lines) have exactly one consumer, and that consumer only checks the files are non-empty.

---

# 1. Verified exact — no change required

Re-derived from `packages/coding-agent/src/config/settings-schema.ts` at `3a8591a` unless noted.

| Claim | Documented | Verified | Evidence |
|---|---|---|---|
| Schema file size | 5,887 lines | **5,887 ✓** | `wc -l` |
| Total setting keys | 453 | **453 ✓** | 415 quoted-dotted + 38 unquoted-flat |
| Namespaces | 91 | **91 ✓** | distinct first dotted segments |
| Block integrity | all carry `type:` | **453/453, zero false positives ✓** | block-parse of `:388-5591` |
| `type:` file-wide | 467× | **467 ✓** | inflated by `options[]`, as documented |
| `default:` file-wide | 466× | **466 ✓** | — |
| Namespace sizes | `hindsight` 27, `providers` 24, `mnemopi` 23, `task` 20, `compaction` 18, `memories` 16, `tools` 14, `skills` 12, `tui` 11, `retry` 10, `read` 10 | **all 11 exact ✓** | one-for-one |
| Self-citation count | "~52 keys" | **exactly 52 ✓** | `oh-my-pi-settings.md` |
| Upstream inventory | "seventeen" | **17 clones = 17 `upstreams.yml` entries ✓** | 19 reports cover 17 repos; `oh-my-pi` has 3 |
| DNA layers | "eleven layers" | **L0–L10 ✓** | `01-dna.md` |
| §7 contract compliance | required in every report | **20/20 reports carry it ✓** | `_CONTRACT.md` rule |

**One qualification worth recording for the schema count.** The 453 figure is only correct when scoped to the `SETTINGS_SCHEMA` object bounds (`:388-5591`). The same key patterns match type declarations and `TAB_METADATA` entries in the preamble; counting file-wide inflates the unquoted class from 38 to 198. `05-coverage-audit.md` now states the bounds explicitly, because the number is not reproducible without them.

---

# 2. Defect 1 — coverage triple was unreproducible

**Status:** CORRECTED
**Files:** `spec/key/05-coverage-audit.md §A`, `spec/key/repos/oh-my-pi-settings.md` (4 sites)

```yaml
documented: 28 / 64 / 101   →  6.2% / 14.1% / 22.3%
verified:   24 / 59 / 120   →  5.3% / 13.0% / 26.5%
```

## 2.1 Root cause

The documented tier-1 count credits `tools.approval` as covered. The deployable surface contains only `tools.approvalMode` — `tools.approval` is a **substring** of it, and the spec never mentions the shorter key. A per-key substring grep therefore scores coverage the spec does not have.

```text
grep -oE 'tools\.approval[A-Za-z0-9_]*' <tier-1 corpus>
  → 1 × tools.approvalMode
  → 0 × tools.approval
```

## 2.2 Why it could not be caught earlier

`05-coverage-audit.md` said only *"grepping every key"*. That names the denominator but not the **matcher**, and three plausible matchers disagree by up to 3 keys. A number stated without its matcher is not reproducible, and this one wasn't.

I have written the matcher rule into both files. Tokenize the corpus on `[A-Za-z0-9_.]+`, then intersect with the key list — no per-key grep, no regex, no escaping.

## 2.3 Tier 3 rising is expected, not contradictory

Tier 3 went **up** (101 → 120) while tiers 1 and 2 went down. `repos/README.md` dates the `andrej-karpathy-skills`, `context7`, `aider` and `oh-my-pi-settings` passes to 2026-08-08, after the audit section was first written. Brace-collapsed forms account for 12 of the rise:

```text
task.isolation.{commits,apply}
thinkingBudgets.{minimal,low,medium,high,xhigh,max}
model.toolCallLoopGuard.{enabled,threshold,exemptTools}
model.loopGuard.{enabled,checkAssistantContent,toolCallReminder}
```

These are real mentions of real keys and must be expanded before counting. The deployable surface contains **none**, so tier 1 is unaffected — but a future pass that writes keys this way will undercount without the expansion step.

**Recommendation for the ledger:** tier 3 grows every time an analysis file is written, so it measures analysis output, not the product. It should be retained only as a contrast to tier 1, never quoted as a coverage figure. Both files now say this explicitly.

## 2.4 Corpus definition is not the explanation

I tested whether the gap came from a different corpus boundary. It does not:

| Corpus variant | Tier-1 result |
|---|---|
| `spec/00`–`16` + `phases/` + `template/` + `registry/` + `docs/` | 24 |
| + `evals/` + `scripts/` (the `oh-my-pi-settings.md` tier-A definition) | **24 — no change** |
| + main-only `docs/evidence/` (2,000+ files absent from the worktree) | **24 — no change** |
| + `registry/omp-compatibility.yml` (main-only) | **24 — no change** |

No corpus variant produces 28. The matcher is the whole explanation.

---

# 3. Defect 2 — "eleven subsystems referenced zero times" was false

**Status:** CORRECTED
**File:** `spec/key/05-coverage-audit.md §A`

The audit claimed eleven `src/` directories are *"referenced **zero** times anywhere in the project"*. Measured against the full 126-file project corpus, **every one has at least one reference:**

| Named as zero | Actual (full corpus) |
|---|---|
| `mnemopi` | 14 |
| `hindsight` | 10 |
| `ssh` | 10 |
| `collab`, `tui` | 4 |
| `auto-thinking`, `cleanse`, `stt` | 3 |
| `autoresearch`, `markit` | 2 |
| `memory-backend` | 1 |

## 3.1 Same root cause as Defect 1

The references exist **because this audit and the `repos/` reports are themselves the references.** This is the identical self-reference trap that the settings count in the same section had already been corrected for — committed one paragraph later. The eleven were true only against the deployable surface, where the real figure is **11 of 22**, not 11 of 54.

## 3.2 The list omitted the two that matter

Two directories are referenced zero times in **every** corpus, including this audit and all 19 `repos/` reports. Neither was on the list:

```yaml
dap:      6 files, 3,979 lines   # full Debug Adapter Protocol client
jsonrpc:  1 file,    142 lines
```

`dap` is the larger blind spot by roughly two orders of magnitude and is **not** obviously irrelevant to a workflow template. `spec/07`'s code-understanding surface stops at LSP and never asks whether a debug adapter is reachable.

**I did not promote `dap` to a G-numbered gap.** No one has read its source, and an audit should not grade what it has not opened. It is recorded as an open item in `§A` so the next pass has to decide about it rather than inherit silence. **Codex: this is the one item here that may deserve a real decision, and it is yours to route** — either a read-and-decide task, or an explicit "considered and excluded" record. Both are fine; inheriting it unmentioned is not.

Also corrected: `src/` has **54** top-level directories, not "~50" (stated approximately, so not a defect — tightened while in the file).

---

# 4. Defect 3 — phantom cross-reference

**Status:** CORRECTED
**File:** `spec/key/05-coverage-audit.md §J.2`

```text
was: "01-dna.md §M invariant 5 lists nine. This audit adds two:"
     10. Handlebars strict: false
     11. @import of a missing file
```

Wrong in three independent ways:

1. **`01-dna.md` has no `§M`.** It never did — I checked every commit that touched the file (`5c59305` is the only one). Its sections are `## 0`, `L0`–`L10`, *Cross-layer invariants*, *Layer → phase map*.
2. **Invariant 5 is about result shapes**, not silent failure: *"Result shapes are declared where OMP enforces them."*
3. **No nine-item silent-failure list exists anywhere in the project.** The number nine most likely came from the *Cross-layer invariants* list, which happens to have nine entries and is a different thing.

## 4.1 The real anchor, and why the numbering was wrong in principle

`01-dna.md` **invariant 8** ("Fail loudly") defines the catalogue *by reference rather than by enumeration*:

> *"every ⚠ in this file is a silent-degradation mode"* — currently **13** markers.

That is the better shape: there is no fixed count to increment, so "now eleven entries" was malformed regardless of which list it pointed at. The corrected text drops the numbering and states the two additions as ⚠ candidates.

## 4.2 The two additions themselves are genuine

Verified: neither `Handlebars` nor `@import` appears anywhere in `01-dna.md`. Both are real omissions.

- **Handlebars `strict: false`** — a typo'd `{{var}}` renders empty. Citation corrected from `prompt.ts:531-534` to **`packages/utils/src/prompt.ts:534`** (the exact `handlebars.compile(template, { noEscape: true, strict: false })` call).
- **`@import` of a missing file** — leaves the raw `@token` in the prompt, debug log only.

Layer assignment also corrected: these belong in **L1 Entry** (owns `commands/*.md`) and **L0 Identity** (owns `AGENTS.md` / `RULES.md`), not the L5/L3 I first wrote.

---

# 5. Structural finding — `policies/` and `schemas/` have no executable consumer

**Status:** NOT a numeric defect. Escalated, not fixed.

```yaml
files: 9          # template/.omp/policies/*.yml + template/.omp/schemas/*.yml
lines: 581
executable_consumers: 1   # scripts/validate-template.ps1
what_that_consumer_does: Test-NonEmpty
```

## 5.1 What the single consumer actually does

`validate-template.ps1` references all 9 files at `:123-131` (existence) and `:198-206` (Section 4, "YAML Non-Empty"). Section 4's entire body:

```powershell
foreach ($y in $yaml_files) { Test-NonEmpty $y }
```

And `Test-NonEmpty` (`:89-100`) checks `Test-Path`, then `$content.Trim().Length -gt 10`. **It never parses the YAML.** A file containing `# TODO` passes.

## 5.2 OMP never discovers them

I grepped OMP source at `3a8591a` for any reference to a `policies/` or `schemas/` discovery root: **zero hits.** Discovery providers resolve `skills/`, `agents/`, `commands/`, `AGENTS.md`, `RULES.md` (`discovery/agents.ts:135-234`, `discovery/builtin.ts:287-345`). `policies/` is outside the discovery surface entirely.

## 5.3 This is already recorded — which is the point

`spec/00-current-state-audit.md:47` **F-18** states it precisely, including the mechanism:

> *"`validate-template.ps1` checks file existence, `length/4` token estimates, three literal phrase greps, and `Trim().Length > 10` for YAML. It never parses YAML… It reports 63/63 on a template whose installer cannot install its own commands."*

So my finding is **confirmatory, not new** — F-18 called it, and `spec/13 §A` and `01-dna.md` L9 rule 1 both build on it. I am reporting it because the numeric audit independently re-derived the same conclusion from a different direction, which raises confidence that F-18's P1 rating is correct rather than rhetorical.

**No action taken.** Resolving it means either writing a real consumer or deleting 581 lines, and that is a design decision outside this task's scope. Routing to Codex.

---

# 6. Method note — a matcher bug worth institutionalizing

My own first boundary-matcher was wrong in exactly the way `§A` now warns about, and the failure signature is general enough to record:

```bash
# intended: match edit.mode as a whole token
esc=$(printf '%s' "$k" | sed 's/\./\\./g')
grep -qE "(^|[^A-Za-z0-9_.])$esc([^A-Za-z0-9_]|$)" corpus
```

Shell expansion ate the backslashes, so `edit\.mode` degraded to `edit.mode` — where `.` matches any character — and it matched the prose **"edit mode"**.

**The tell:** the boundary matcher scored *higher* (26) than the substring matcher (25). That is arithmetically impossible — a stricter matcher cannot match more — and it is the diagnostic signature for escaping loss in a shell-built regex. Any future count that shows this inversion has the same bug.

Tokenize-then-intersect needs no escaping and is what both files now prescribe.

Also worth flagging for anyone re-running these counts on this platform: `grep -E '[ \t]type:'` does **not** match tabs in this environment — POSIX bracket expressions read `\t` literally. The tab-dependent counts in this report use `$'\t'` throughout. An early run of mine returned 102 instead of 467 for exactly this reason.

---

# 7. Files changed

```text
spec/key/05-coverage-audit.md        +103 / -13
spec/key/repos/oh-my-pi-settings.md   +46 / -25
                                     ─────────────
                                      111 insertions, 38 deletions
```

Both uncommitted in worktree `worktree-spec-key-dna` @ `d84efef`.

**Deliberately not changed:** `spec/key/repos/README.md:37`. Its "Prior coverage being replaced" column preserves the old wrong numbers (`146 of 607`) as history, which is correct by design.

Each correction is recorded **in place** rather than silently overwritten — the audit's own value depends on a reader being able to see that a number moved and why. Every corrected figure carries a short note naming the superseded value and the matcher that produced it.

---

# 8. What this pass did not cover

Stated so the gap is not inherited as coverage:

- **Verdict rows were counted but not re-adjudicated.** 250 rows across 18 reports (`oh-my-pi-orchestration.md` carries no §3 table — it is the OQ-H comparison): ADOPT 139, ADAPT 58, DEFER 20, REJECT 33. I verified the tally is extractable and header-consistent. **I did not check whether any individual verdict is correct.** Note that a naive `awk -F'|'` column grab inflates several files by matching verdict words in prose cells — `repomix.md` reads ADOPT=2 that way and is actually **ADOPT=0**. Header-aware extraction is required.
- **No `dossiers/` numbers were verified** beyond those `05-coverage-audit.md` cites.
- **`dap` and `jsonrpc` source was not read** — only sized. The decision about them is open.
- **KD-001…KD-023 and SD-1…SD-12 were confirmed contiguous** with no gaps or duplicates, but their content was not reviewed.
- **No claim is made about `spec/00`–`16` numeric accuracy.** This pass covered `spec/key/` only.

---

# 9. Requested Codex action

| # | Item | Type | Ask |
|---|---|---|---|
| 1 | Coverage triple `24 / 59 / 120` | numeric, corrected | Accept, or re-derive with the stated matcher and dispute |
| 2 | Tier 3 is a self-reference metric | methodological | Confirm it should never be quoted as coverage |
| 3 | `dap` (3,979 lines) unexamined | **open decision** | Route: read-and-decide, or record as explicitly excluded |
| 4 | `policies/` + `schemas/` — 581 lines, no real consumer | **design decision** | Write a consumer, or delete. Confirms F-18 |
| 5 | Silent-failure catalogue has no fixed count | structural | Confirm ⚠-marker-by-reference is the intended shape |

Items 1, 2 and 5 are closed unless disputed. **Items 3 and 4 need a decision that is not mine to make.**

---

# 10. Final assessment

The `spec/key` layer is accurate where it reads OMP source and unreliable where it measures itself. All three defects are the same error — a count taken against a corpus that includes the counting document — and `05-coverage-audit.md` had already identified and corrected that error once for the settings figure before committing it twice more in the same section.

That pattern is the real finding. The corrected numbers matter less than the fact that **none of the three was reproducible from the recorded method**, which is why each correction now ships with its matcher rather than just its result. A number whose derivation is not written down is inherited as a constraint by every future maintainer and cannot be challenged by any of them.
