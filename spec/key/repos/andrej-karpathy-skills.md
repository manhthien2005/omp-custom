# Repo Report — andrej-karpathy-skills

> **Path:** `_research/upstreams/andrej-karpathy-skills`
> **SHA:** `2c606141936f1eeef17fa3043a72095b4765b9c2` (`git -C andrej-karpathy-skills rev-parse HEAD`)
> **Remote:** `https://github.com/multica-ai/andrej-karpathy-skills.git`
> **License:** **MIT.** Declared in three places: `skills/karpathy-guidelines/SKILL.md:4`
> (`license: MIT` in frontmatter), `.claude-plugin/plugin.json:8` (`"license": "MIT"`), and
> `README.md:169-171` (`## License` / `MIT`). Also `README.zh.md` (`## 许可` / `MIT`).
> **There is no `LICENSE` file at the repo root** — and that absence is what the registry
> currently records as the license fact. See §5; this is the SD-12 / KD-023 correction.
> **Size:** 9 tracked files (`git ls-files | wc -l`)
> **Read this pass:** **all 9 files, in full.** `CLAUDE.md` (65L), `CURSOR.md` (28L),
> `EXAMPLES.md` (522L), `README.md` (171L), `README.zh.md` (171L),
> `skills/karpathy-guidelines/SKILL.md` (67L), `.cursor/rules/karpathy-guidelines.mdc` (70L),
> `.claude-plugin/plugin.json` (11L), `.claude-plugin/marketplace.json` (29L). Nothing skipped.

---

## 1. What this repo is

A **methodology artifact**, not a runtime and not a library: one set of four behavioral
guidelines, shipped in three interchangeable delivery formats (root instruction file, Claude
Code plugin skill, Cursor project rule) plus a worked-examples companion. It is the smallest
repo in the corpus by an order of magnitude — 9 files, ~1,134 lines, of which the actual
payload is **303 words**.

Its thesis is narrow and specific: LLM coding failures cluster into four named modes
(unstated assumptions, overengineering, collateral edits, unverifiable goals), and a short
always-on instruction block addressed at those four modes is worth more than a large
methodology. The four principles are derived from a single Karpathy post, cited at
`README.md:7` and `SKILL.md:9`.

For our purposes it is the corpus's **cleanest natural experiment in the persistent tier**:
the same content, deliberately sized to be paid on every turn. It sits at the exact opposite
end of the axis from `ECC` (282 skills), and both are about L0/L5 placement.

---

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| K1 | **Failure-mode-first constitution** | Each principle names the LLM failure it counters, rather than stating a virtue. `README.md:25-30` is an explicit principle→failure table | `README.md:25-30`; `CLAUDE.md:9,19,31,47` (bold one-line thesis per section) | **A** |
| K2 | **Senior-engineer overcomplication test** | Converts "keep it simple" into a callable check: *"Would a senior engineer say this is overcomplicated? If yes, simplify."* Plus a numeric trigger: 200 lines that could be 50 ⇒ rewrite | `CLAUDE.md:25,27`; `SKILL.md:31,33` | **A** |
| K3 | **Every-changed-line-traces test** | Converts "surgical" into a diff-level predicate: *"Every changed line should trace directly to the user's request."* | `CLAUDE.md:43`; `SKILL.md:49` | **A** |
| K4 | **Own-orphans-only cleanup rule** | Asymmetric and unusually precise: remove imports/vars/functions *your* change orphaned; do **not** remove pre-existing dead code — mention it instead | `CLAUDE.md:37,39-41`; `SKILL.md:43,45-47` | **A** |
| K5 | **Imperative→verifiable goal transform** | Three worked rewrites ("Add validation" → "Write tests for invalid inputs, then make them pass") plus a `step → verify:` plan skeleton | `CLAUDE.md:49-59`; `SKILL.md:55-65`; `README.md:83-95` | **A** |
| K6 | **Success-criteria-as-leverage claim** | The rationale for K5: strong criteria let the model loop unattended; weak criteria ("make it work") force round-trips | `CLAUDE.md:61`; `README.md:97,136-138` | **A** (claim is verbatim; its *truth* is C) |
| K7 | **Self-limiting scope clause** | The instruction block states its own tradeoff and tells the reader to bypass it for trivial work — a rule that declares when not to apply | `CLAUDE.md:5`; `SKILL.md:11`; `README.md:163-167` | **A** |
| K8 | **Behavioral outcome indicators** | Four observable diff-level signals the guidelines are working (fewer unnecessary diff lines, fewer overcomplication rewrites, questions before rather than after) | `CLAUDE.md:65`; `README.md:140-147` | **A** |
| K9 | **Tri-format sync with named obligation** | Same body in `CLAUDE.md` + `.cursor/rules/*.mdc` + `SKILL.md`; `CURSOR.md:26-28` names the contributor duty to keep all three in sync | `CURSOR.md:26-28`; verified identical, see §2a | **A** |
| K10 | **`alwaysApply: true` on the Cursor rule** | The Cursor delivery is unconditional, not description-matched — the persistent-tier choice made explicit in frontmatter | `.cursor/rules/karpathy-guidelines.mdc:3` | **A** |
| K11 | **Routing-shaped skill description** | `SKILL.md:3` description names both the trigger context ("when writing, reviewing, or refactoring code") and the four outcomes — matches the description craft `agent-skills`/`Agent-Skills-for-Context-Engineering` argue for | `SKILL.md:3` | **A** |
| K12 | **Wrong-but-plausible example pairs** | `EXAMPLES.md` ❌/✅ pairs where the ❌ side is idiomatic best practice (ABC + Strategy + dataclass for one discount calc), so the lesson is *timing*, not correctness | `EXAMPLES.md:105-158,509-522` | **A** |
| K13 | **Style-drift as a named defect class** | Quote style, added type hints, added docstrings, reflowed whitespace during an unrelated fix, itemized as violations | `EXAMPLES.md:293-366` (esp. `:332-337,366`) | **A** |
| K14 | **Plugin/marketplace packaging** | `.claude-plugin/` pair exposing one skill via marketplace install | `plugin.json:10`; `marketplace.json:11-27` | **A** |

### 2a. Sync verification (K9)

Checked rather than assumed, because K9's value depends on it. Extracting the principles body
(`## 1. Think Before Coding` through `require constant clarification.`) from all three copies:

```
CLAUDE.md  vs  .cursor/rules/karpathy-guidelines.mdc   → IDENTICAL
CLAUDE.md  vs  skills/karpathy-guidelines/SKILL.md     → IDENTICAL
```

The three differ **only** in wrapper: the Cursor rule adds frontmatter
(`description` + `alwaysApply: true`) and a `# Karpathy behavioral guidelines` heading;
`SKILL.md` adds frontmatter (`name`/`description`/`license`) and the Karpathy attribution
link at `:9`; `SKILL.md` omits the K8 outcome-indicators footer that `CLAUDE.md:63-65` and
the Cursor rule `:68-70` both carry. The stated sync obligation is currently **honored** at
this SHA. Grade **A**.

### 2b. The one structural absence worth naming

`EXAMPLES.md` is 522 lines — 4.6× the payload — and **nothing references it.** Grepping the
whole repo for `EXAMPLES`: zero hits outside the file itself. `SKILL.md` contains no relative
path reference of any kind. So the examples are *human* documentation, never loaded into a
model context by any of the three delivery paths.

That is the correct call, and it is the progressive-disclosure boundary drawn by omission
rather than by mechanism: the repo could have made `EXAMPLES.md` a `SKILL.md` reference file
(the `skills`/`superpowers` pattern) and chose not to. Whether deliberate or accidental, the
effect is that the always-paid surface stays at 303 words while the teaching material costs
zero. Grade **A** for the fact; **C** for reading intent into it.

---

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| K2 K3 K4 | `.omp/AGENTS.md` constitution section (ContextFile — `builtin.ts:910,923`) | **persistent** | **ADOPT** (already adopted as inspiration; see §5 for the shape correction) | These three are the only principles that reduce to a *callable test*. K3 in particular is checkable against a diff, which makes it the one line here that a reviewer or verifier can apply mechanically |
| K7 | same `AGENTS.md` section | persistent (≈15 tok) | **ADOPT** | A persistent instruction that never says when to stand down gets applied to typo fixes. Cheapest correctness-per-token item in this report |
| K8 | `spec/13` eval assertions, **not** a context file | **zero** | **ADAPT** | Four diff-observable indicators. "Fewer unnecessary changes in diffs" is measurable against a fixture as *changed lines not traceable to the packet*; it belongs in an eval, where it costs nothing per turn |
| K11 | `SKILL.md` `description` field for our ≤10 skills | zero (frontmatter already paid via listing) | **ADOPT as exemplar** | Independent corroboration, from the smallest repo in the corpus, of the trigger-context + outcome description shape. Useful as a one-line model for KD-014's capped library |
| K5 | `task-triage` / mini-spec step in `standard.md`, `orchestrated.md` | lazy | **ADAPT — subordinate to SD-8** | The `step → verify:` skeleton is good; but `OpenSpec`'s criterion rule (one `SHALL`, observable, named case, no mechanism inside) is strictly sharper. Take K5's *transform table* as authoring illustration, keep SD-8 as the rule |
| K1 | `AGENTS.md` authoring convention | zero (a writing rule, not text) | **ADOPT as convention** | "Name the failure mode, not the virtue" is a test for admitting any future line to the persistent tier. Pairs with L0's admission test in `01-dna.md` |
| K12 K13 | `evidence-before-completion` / discipline-skill *pressure fixtures* (`spec/11 §D`) | zero | **ADAPT** | K12's insight — the wrong answer must be *idiomatic*, not obviously bad — is a fixture-design rule. A pressure fixture whose wrong branch looks wrong tests nothing. K13 gives a concrete negative fixture: does the worker reflow quotes while fixing a bug? |
| K6 | — | — | **DEFER** | Trigger: an eval arm comparing strong vs weak success criteria on turns-to-accepted-outcome. It is the repo's central claim and the one thing here we have no evidence for |
| K9 K10 K14 | — | — | **REJECT** (out of scope by constraint) | Multi-tool distribution and plugin packaging. We ship one runtime. K10 is informative only as corroboration that others also place this content in the always-on tier |

**Net new mechanisms for the spec: 0.** Consistent with the `02-repo-synthesis.md` verdict of
`Principle only`, which this full read **confirms** — the four principles were already adopted
into `AGENTS.md` as inspiration (`adopt-016`).

**Net new for authoring and fixture craft: 4** (K1 admission test, K8 as eval assertions,
K12 fixture-plausibility rule, K13 style-drift negative fixture). These are not new runtime
behaviors, which is why they do not raise the SD count — but K12 is a genuine improvement to
how `spec/11 §D` fixtures should be written, and it did not come from anywhere else in the
corpus.

---

## 4. What this repo does that we deliberately will not

- **Ship the same content three times.** `CLAUDE.md` + Cursor rule + `SKILL.md` is correct for
  a distributable plugin and wrong for us: in OMP, content in `AGENTS.md` *and* in an
  autoloaded skill is paid twice. Our L0/L5 split (`01-dna.md`) exists precisely to prevent
  this. Note this is also G-8's shape — foreign discovery providers mean a `.cursor/rules/`
  file in a project **is** a live input to OMP, so a repo like this dropped into a workspace
  contributes to our context whether we adopt it or not.
- **Put the constitution in `alwaysApply: true` wholesale.** K10 makes all four principles
  unconditional. Our `RULES.md` admission test is stricter: only what causes destructive
  action or false completion if forgotten. Of the four, that is K3/K4 at most; K2 and K5 are
  `AGENTS.md`-tier. Splitting them by lifetime is a real difference from this repo, not a
  stylistic one.
- **Leave the payload unversioned.** No semver on the guidelines themselves (`plugin.json`
  has `"version": "1.0.0"`, which versions the *package*). `spec-kit`'s constitution semver
  + Sync Impact Report is the better mechanism, and `CURSOR.md:26-28` shows the gap: a named
  human obligation to keep three files in sync, with no check that enforces it. We watch
  `CLAUDE.md` in `registry/upstreams.yml:354` — one of three files that must agree.
- **Rely on prose to define "simple."** K2's senior-engineer test is a good heuristic and an
  unmeasurable gate. `spec/10`'s reviewer contract needs SD-6's harder rule (blocks only if
  the change is worse than not merging) to avoid "this is overcomplicated" becoming a
  blocking preference.

---

## 5. Contradictions with our current spec or registry

**This is the section that matters in this report.** Three registry records state a license
fact that is false, and one watched path is incomplete.

### 5-1. `reject-014` — "No LICENSE file" is used to conclude the wrong thing

> `registry/rejected-mechanisms.yml:98-103`
> ```yaml
> - id: reject-014
>   mechanism: "Verbatim copy of andrej-karpathy-skills CLAUDE.md"
>   reason: "No LICENSE file. Copyright all rights reserved by default. The four coding
>            principles are general software engineering concepts, not copyrightable
>            expression — they are independently rewritten."
> ```

The premise "No LICENSE file" is **true**. The inference "Copyright all rights reserved by
default" is **false for this repo**, because MIT is granted in-file three times:

| Location | Text |
|---|---|
| `skills/karpathy-guidelines/SKILL.md:4` | `license: MIT` (frontmatter) |
| `.claude-plugin/plugin.json:8` | `"license": "MIT"` |
| `README.md:169-171` | `## License` → `MIT` |

A license grant does not require a file named `LICENSE`. Checking only for that filename is
the defect — the same class of error as `reject-013` (per-skill licenses inside
`anthropics/skills`). Both are SD-12; both are decided in **KD-023**.

**Consequence:** the rejection is over-restrictive but its *outcome* is harmless — we
rewrote the principles independently, and nothing needs re-doing. What must change is the
recorded reason, because a future maintainer inherits "this upstream is UNLICENSED" as a
constraint and will decline a use that is in fact permitted.

### 5-2. `licenses.yml:101-112` — `spdx: UNLICENSED` is wrong

> ```yaml
> - id: andrej-karpathy-skills
>   license: no-license-file
>   spdx: UNLICENSED
>   notes: >
>     No LICENSE file present. CLAUDE.md content is copyright the repository owner.
>     ... Flag: do not reproduce original wording.
> ```

Correct values: `license: MIT`, `spdx: MIT`, with a note that the grant is in-file
(`SKILL.md:4`, `plugin.json:8`, `README.md:169-171`) rather than in a root `LICENSE`, and
that no `LICENSE` file exists. The `Flag: do not reproduce original wording` line should be
**dropped** — MIT permits reproduction with attribution and license text. Keeping the flag is
not merely stale, it forbids something we are allowed to do.

### 5-3. `upstreams.yml:349` and `adoption-ledger.yml:186`

- `upstreams.yml:349`: `license: no-license-file  # Copyright all rights reserved; treated as
  conceptual inspiration` → `license: MIT  # granted in-file: SKILL.md:4, plugin.json:8,
  README.md:169-171; no root LICENSE file`.
- `adoption-ledger.yml:186`: `license_check: no-license` → `license_check: mit-in-file`.
  The `adoption_type: conceptual-inspiration` classification stays accurate and needs no change.

### 5-4. `upstreams.yml:353-354` — watched path is one of three

```yaml
watched_paths:
  - CLAUDE.md
```

`CURSOR.md:26-28` establishes that the payload lives in **three** files kept in sync by hand.
Watching one means an upstream change landing in `SKILL.md` or the Cursor rule first — or a
sync obligation being *broken* — is invisible to us. Add
`skills/karpathy-guidelines/SKILL.md` and `.cursor/rules/karpathy-guidelines.mdc`. Cost: zero
(watched paths never enter a context). This is the same class as SD-1/SD-10 and should join
them.

### 5-5. No contradiction with `01-dna.md` or the phase plans

Checked: nothing in this repo makes an L0 claim in `01-dna.md` false. K10 (`alwaysApply:
true` on all four principles) is a *different choice* from our L0/RULES split, not evidence
against it — and `01-dna.md`'s admission test is the stricter of the two. `02-repo-synthesis.md`'s
`Principle only` / `Net new: 0` row is confirmed by this full read.

---

## 6. Cost profile

Measured, since the whole repo is small enough to count. Word counts via `wc -w`; token
figures are estimates at ~1.35 tok/word for English prose — flagged as **estimate**.

| Item | Words | Est. tokens | Tier | Where paid |
|---|---|---|---|---|
| Principles body only (§1–§4, no wrapper) | 303 | **~410** | persistent | every turn, if placed in `AGENTS.md` |
| Full `CLAUDE.md` | 358 | ~485 | persistent | every turn |
| `SKILL.md` (frontmatter + body) | 371 | ~500 | per-spawn if autoloaded | each subagent's first turn |
| Cursor rule (`alwaysApply: true`) | 393 | ~530 | persistent | n/a for us — but **live via G-8** if present in a workspace |
| `EXAMPLES.md` | 1,859 | ~2,510 | **zero** | never loaded — nothing references it (§2b) |

Adoption cost for the §3 ADOPT rows, as they should land:

- **K2 + K3 + K4 + K7 in `AGENTS.md`:** ~410 tok estimate if taken at upstream length. Our
  `AGENTS.md` budget is 600–1,200 tok total (`01-dna.md` L0), so the four principles at full
  upstream length would consume **34–68% of the entire constitution budget**. They are already
  in `AGENTS.md` as condensed inspiration (`adopt-016`), which is the right call — this
  number is the argument for keeping them condensed, and is the concrete reason not to paste
  the upstream text now that MIT permits it.
- **K1 (admission convention), K8 (eval assertions), K11 (description exemplar), K12/K13
  (fixture rules):** **zero** persistent cost. K8 moves an outcome claim out of the persistent
  tier and into `evals/`, which is a strict improvement — an assertion is paid once per run,
  an instruction is paid every turn.
- **Registry corrections §5-1…5-4:** zero. Governance records never enter a context.

The placement lesson, in one line: this repo's total context contribution can be **~410
tokens or ~2,900**, depending only on whether `EXAMPLES.md` is referenced. It is not, and that
single decision is worth more than any of the four principles individually.

---

## 7. Coverage and limits  (MANDATORY)

**Files read in full: 9 of 9 — the entire repository.**

- `CLAUDE.md` (65L) · `CURSOR.md` (28L) · `EXAMPLES.md` (522L) · `README.md` (171L) ·
  `README.zh.md` (171L) · `skills/karpathy-guidelines/SKILL.md` (67L) ·
  `.cursor/rules/karpathy-guidelines.mdc` (70L) · `.claude-plugin/plugin.json` (11L) ·
  `.claude-plugin/marketplace.json` (29L)

**Files sampled (head/grep only):** none.

**Not opened:** nothing tracked. Only `.git/` internals, which are not content.

**Verified mechanically rather than by eye:**
- Three-way sync of the principles body (§2a) — extracted and `diff`ed, identical.
- Absence of any `EXAMPLES.md` reference (§2b) — repo-wide grep, zero hits.
- MIT grant in three locations (§5) — read directly at each cited line.
- Registry contradictions (§5) — quoted from `registry/*.yml` at the current `main`
  (`dfae7bd`), not from memory.

**Claims that need a live run before use:**
- **K6** (strong success criteria reduce round-trips) is the repo's central claim and is
  **unmeasured here and everywhere else in our corpus**. Graded C. It is the DEFER in §3.
- The ~1.35 tok/word ratio in §6. Directionally safe, but every token figure in §6 is an
  **estimate**, not a tokenizer count. The 34–68%-of-budget conclusion holds under any
  plausible ratio; the specific percentages do not.
- Whether K2's "senior engineer" heuristic changes model behavior at all, versus reading as
  filler. Untested.

**Anything suspected but not verified:**
- `README.md:3` promotes `multica-ai/multica`, and the remote is `multica-ai/…` while
  `README.md:105` still says `/plugin marketplace add forrestchang/andrej-karpathy-skills`.
  Likely an ownership transfer with a stale install line. **I did not check whether
  `forrestchang/andrej-karpathy-skills` still resolves**, and did not check upstream history
  for when MIT was added. If the MIT grant post-dates our `2026-08-07` license review, then
  `reject-014` was *correct when written* and merely stale — which changes the §5 framing from
  "defective check" to "stale record". I cannot distinguish these two without reading upstream
  git history, which I did not do. **The correction in §5 is required either way**; only the
  blame attribution differs, and KD-023 should not assert the "defective check" reading
  without that check. (Note: `reject-013`'s `anthropics/skills` per-skill-license finding is
  independent evidence that the root-`LICENSE`-only check was in fact the method used, which
  makes the defective-check reading more likely — but that is inference, not verification.)
- Whether the `.cursor/rules/` copy being live under OMP's foreign discovery providers (G-8)
  means a developer with this repo cloned into a workspace silently pays ~530 tok/turn. The
  provider list is grade-A from `oh-my-pi-prompt-discovery.md`; **that this specific file
  would be picked up is inference**, not a traced path, and needs the G-8 live check.
