# Repo Report — agents.md

> Authority boundary: This repository report is source/research evidence.
> Former role names, counts, verdicts, and ADOPT or ADAPT labels do not select current topology,
> dispatch, review mechanism, or capability behavior.
> Current design and execution authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.


> **Path:** `_research/upstreams/agents.md`
> **SHA:** `d1ac7f063d20e70015ed6732664049ae4ba9d74e` (`git -C agents.md rev-parse HEAD`)
> **License:** **MIT**, single grant. `LICENSE:1-3`: `MIT License` /
> `Copyright (c) 2025 OpenAI`. No in-file grants, no split content licence, no per-directory
> exceptions. The repo now describes itself as stewarded by the **Agentic AI Foundation under
> the Linux Foundation** (`components/AboutSection.tsx:20-32`) — governance changed, the
> licence file did not.
> **Size:** 61 tracked files (`git ls-files | wc -l`). Of those, **3 carry normative
> content** (`README.md`, `AGENTS.md`, and the FAQ/How-To components); 27 are vendor logos
> and the remainder is a Next.js marketing site.
> **Read this pass:** `README.md` in full, the repo's own `AGENTS.md` in full, `LICENSE` head,
> and every content-bearing component: `FAQSection.tsx`, `HowToUseSection.tsx`,
> `WhySection.tsx`, `AboutSection.tsx`, `Hero.tsx`, `CompatibilitySection.tsx` (agent list),
> and the two embedded examples in `CodeExample.tsx`. Then — because §5 required it — the
> **OMP implementation side**: `discovery/builtin.ts`, `discovery/agents-md.ts`,
> `capability/context-file.ts`, `discovery/helpers.ts`, `system-prompt.ts`,
> `prompts/system/project-prompt.md`, and two OMP test files. Prior coverage was tree +
> README size only.

## 1. What this repo is

A **convention plus its marketing site**. There is no spec document, no JSON schema, no
validator, and no parser — a fact that is itself the most important thing about it. The
normative content is a handful of sentences distributed across a README and some React
components. It claims adoption by *"over 60k open-source projects"* (`Hero.tsx:23-32`, via a
GitHub code-search link) and lists 27 consuming tools (`CompatibilitySection.tsx:14-…`).

Its positioning against README is the whole idea: README is *"for humans: quick starts,
project descriptions, and contribution guidelines"*; AGENTS.md carries *"the extra, sometimes
detailed context coding agents need: build steps, tests, and conventions that might clutter
a README"* (`components/WhySection.tsx:17-25`).

## 2. Mechanism inventory

The striking result of reading it all: **the convention has exactly one hard requirement,
and it is a filename.** Everything else is either optional or a behavioural expectation
placed on the *tool*, not the file.

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| C1 | **Filename + location** — `AGENTS.md` at repo root | The only actual requirement. *"Create an AGENTS.md file at the root of the repository"* | `components/HowToUseSection.tsx:7-13` | A |
| C2 | **No required fields, no schema** | *"No. AGENTS.md is just standard Markdown. Use any headings you like; the agent simply parses the text you provide."* | `components/FAQSection.tsx:13-16` | A |
| C3 | **Nearest-file-wins precedence** | *"The closest AGENTS.md to the edited file wins; explicit user chat prompts override everything."* | `components/FAQSection.tsx:17-21` | A |
| C4 | **Nested files for monorepos** | *"Place another AGENTS.md inside each package. Agents automatically read the nearest file in the directory tree, so the closest one takes precedence"*; cites the OpenAI repo as having **88** such files | `components/HowToUseSection.tsx:35-40` | A |
| C5 | **Commands in it are expected to be executed** | *"Yes—if you list them. The agent will attempt to execute relevant programmatic checks and fix failures before finishing the task."* | `components/FAQSection.tsx:22-26` | A |
| C6 | **Suggested (not required) sections** | Project overview, build/test commands, code style, testing instructions, security considerations | `components/HowToUseSection.tsx:19-27` | A |
| C7 | **Migration by rename + symlink** | `mv AGENT.md AGENTS.md && ln -s AGENTS.md AGENT.md` | `components/FAQSection.tsx:32-48` | A |
| C8 | **Adaptation via tool config for non-native tools** | Aider: `read: AGENTS.md` in `.aider.conf.yml`. Gemini CLI: `{"context":{"fileName":"AGENTS.md"}}` | `components/FAQSection.tsx:49-88` | A |
| C9 | **Living document** | *"Absolutely. Treat AGENTS.md as living documentation."* | `components/FAQSection.tsx:27-30` | A |
| C10 | **Reference examples** — two, both prose-and-bullets | `HERO_AGENTS_MD` (setup commands + code style) and `EXAMPLE_AGENTS_MD` (dev env tips, testing instructions, PR instructions) | `components/CodeExample.tsx:22-32`, `:34-61`; the second is duplicated in `README.md:12-33` | A |
| C11 | **The repo's own AGENTS.md as a worked example** | Notably *prohibitive*, not just descriptive: *"**Do _not_ run `npm run build` inside the agent session**"* with the reason (switches `.next` to production assets, disables hot reload) | `AGENTS.md:8-15` | A |

### 2b. Required vs optional, stated precisely

Because the task asked for this exactly:

**Required (1 item):** the file is named `AGENTS.md`. That is all.

**Optional (everything else):** all headings, all sections, all content, all structure. C2
is explicit that there is no schema. There is no version field, no frontmatter, no
machine-readable region, and nothing a linter could check beyond existence.

**Not requirements on the file at all — requirements on the *tool*:**
- C3/C4: discover by walking the tree and apply nearest-wins.
- C5: attempt to run programmatic checks listed in the file.
- C3's second clause: user chat prompts outrank the file.

This split matters for us. **The convention's discovery-and-merge semantics are entirely
delegated to implementations, and are stated in two sentences of FAQ prose with no
conformance test.** Any two tools can diverge while both claiming compliance, and nothing in
this repo could adjudicate.

### 2c. What the convention expects of discovery and merge

Two sentences carry it all:

> *"The closest AGENTS.md to the edited file wins; explicit user chat prompts override
> everything."* — `FAQSection.tsx:19-20`

> *"Agents automatically read the nearest file in the directory tree, so the closest one
> takes precedence and every subproject can ship tailored instructions."*
> — `HowToUseSection.tsx:38`

Read carefully, these say **precedence**, not **exclusivity**. "Wins" and "takes precedence"
describe conflict resolution between instructions, which is what you need when a package
file says "use 2-space indent" and the root says 4. Neither sentence says the root file is
*not loaded*. And the surrounding rationale points the other way: the point of nesting is
that *"every subproject can ship tailored instructions"* (`:38`) — tailoring implies a base
to tailor, and the OpenAI repo's cited **88 files** (`:38`) would be an odd design if only
one were ever read.

**The honest verdict: the convention is ambiguous between "nearest only" and "all levels,
nearest wins conflicts", and does not resolve it.** Our spec resolved it in the wrong
direction. See §5.

## 3. Transferable to omp-custom

The convention is already adopted, so this section is narrow by construction. What survives
rule 4 is authoring craft plus one correction that changes what a template author must do.

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| **C11 prohibitive instructions with stated reasons** | `template/.omp/AGENTS.md` (loaded into `contextFiles`, rendered by `prompts/system/project-prompt.md:9-18` under `<repo-rules>` with *"You MUST follow the context files below"*) | `persistent` — every turn, every subagent | **ADOPT** | Their own file spends its longest section on a **negative** instruction with the mechanism explained: don't run `npm run build`, because it *"switches the `.next` folder to production assets which disables hot reload and can leave the development server in an inconsistent state"* (`AGENTS.md:12-15`). A prohibition with a reason survives an agent that reasons about it; a bare "don't" invites working around it. This is the highest-value line-level craft in the repo |
| **C6 the five suggested sections as a completeness check** | Same | `persistent` | **ADAPT** | Project overview / build+test commands / code style / testing / security (`HowToUseSection.tsx:19-27`). Useful as an authoring *checklist*, not a template — each section is only worth its persistent cost if it changes a decision. A "Project overview" that restates the README is pure loss at the most expensive tier |
| **C5 commands-are-executed** | Same | `persistent` | **ADOPT as a discipline** | If listing a command means an agent will run it (`FAQSection.tsx:24-25`), then **every command in our template's AGENTS.md must be correct and non-destructive**, and any command that must *not* be run needs C11 treatment. This makes AGENTS.md content a safety surface, not just documentation |
| **C4/C3 monorepo layering** | `discovery/agents-md.ts:21-59` walks *every* ancestor and emits one `ContextFile` per level; `capability/context-file.ts:36` keys them `project:${depth}` so distinct depths **coexist** | `persistent`, and it **multiplies** | **ADAPT — with a correction to our spec** | Layering *works* in OMP for root-level `AGENTS.md`, contrary to what `spec/key` records. The template-author consequence is the opposite of what the spec says: not "you cannot layer", but "**if you layer, every level is paid on every turn**". See §5.1 and §6 |
| **C7 rename + symlink migration** | Installer docs | `zero` | **ADOPT** | One line (`FAQSection.tsx:40`). Relevant to any project migrating from `CLAUDE.md`/`AGENT.md`. Note OMP loads `CLAUDE.md` natively (`discovery/claude.ts:529`), so a symlink can cause the *same content twice* — mitigated by content-identity dedup (`system-prompt.ts:340-348`), which I verified by test (`test/system-prompt-dedup.test.ts:204-231`) |

**REJECT:** C1, C2, C9 — already true of us and not mechanisms. C8 (per-tool config
adapters) — OMP discovers `AGENTS.md` natively via two providers; nothing to configure. C10
(the reference examples) — both are generic pnpm/Vite boilerplate; adopting their *content*
would be folder-shape envy.

## 4. What this repo does that we deliberately will not

**We will not treat the convention as a schema, or build a validator for it.** C2 forecloses
it: *"AGENTS.md is just standard Markdown"* (`FAQSection.tsx:15`). A conformance checker for
a format with one requirement (a filename) would be nine YAML files with zero consumers,
again.

**We will not adopt the suggested section list as a template skeleton.** C6 is a *popular
choices* list (`HowToUseSection.tsx:19`), not a requirement — and AGENTS.md content is
`persistent`-tier, the most expensive tier we have. Shipping five headings because a
convention site lists them, then filling them to look complete, is how a persistent-cost
file becomes 300 lines that change no decision. Sections earn their place individually.

**We will not layer template AGENTS.md files across a monorepo by default.** Layering works
(§5.1) — that is precisely why the restraint is needed. Every level is paid on every turn *of
every subagent*. The convention's own showcase example is 88 files (`:38`); at our cost
structure that would be catastrophic. Ship one, at the root, and use `@import` (verified in
`spec/key/05 §G-7`) when composition is genuinely needed.

**We will not rely on C5's "the agent will run your commands" as a verification mechanism.**
It is a statement about *"the agent"* in the abstract (`FAQSection.tsx:24-25`), with no
guarantee from any implementation and no way to observe compliance. Our verification comes
from the verifier worker running a named command and reporting its output. Listing a command
in AGENTS.md is a hint, not a gate.

## 5. Contradictions with our current spec or registry

### 5.1 The recorded OMP discovery fact is **wrong**, and it is recorded as grade A in three places

This is the headline finding of the report.

**The claim.** `spec/key/02-repo-synthesis.md:573-577`:

> *"Worth noting that OMP's implementation is **stricter** than the convention: project
> `AGENTS.md` returns at the nearest match with no concatenation up the tree
> (`builtin.ts:921-936`, grade A), so a monorepo cannot layer a root and a package file.
> That is a runtime fact the convention does not imply, and it belongs in the installer
> docs."*

Restated in `spec/key/dossiers/oh-my-pi.md:165` (*"nearest wins, no concatenation up the
tree (`builtin.ts:921-936`)"*) and relied on in `spec/key/05-coverage-audit.md:329-331`
(*"a monorepo package file must import the root explicitly"*).

**The evidence.** The cited lines are real and say what the spec says — but they are **one of
two providers**, and they govern a different file.

`builtin.ts:921-935` is the `.omp/` provider. `PATHS = SOURCE_PATHS.native`
(`builtin.ts:44`) and `SOURCE_PATHS.native.projectDir = CONFIG_DIR_NAME`
(`discovery/helpers.ts:36`), i.e. `.omp`. So `findNearestProjectConfigDir`
(`builtin.ts:90-99`) finds the nearest ancestor **containing a `.omp/` directory**, and the
early `return` at `builtin.ts:933` stops the walk. That provider's subject is
**`.omp/AGENTS.md`**, not root-level `AGENTS.md`.

Root-level `AGENTS.md` is handled by a **separate provider** the spec's claim does not
mention. `discovery/agents-md.ts` — registered against the same capability
(`agents-md.ts:61-67`), whose stated purpose is *"AGENTS.md files that live in project root
(not in config directories like `.codex/` or `.gemini/`)"* (`:5-6`) — walks **every** ancestor
to `repoRoot`, and **pushes an item for each one it finds** (`:28-56`). There is no early
return.

Those items then **coexist**, by explicit design. `capability/context-file.ts:36` keys them:

```
key: file => (file.level === "user" ? "user" : `project:${Math.max(0, file.depth ?? 0)}`),
```

with the comment two lines above stating the intent outright: *"one user-level file, and one
project-level file per directory depth … **This supports monorepo hierarchies where
AGENTS.md exists at multiple ancestor levels**"* (`context-file.ts:31-33`). Different depths
produce different keys, so dedup does not collapse them.

They are then **all rendered**. `system-prompt.ts:383-387` sorts by depth descending *"so
files closer to cwd appear later and are more prominent"*, and
`prompts/system/project-prompt.md:12-16` loops:

```
{{#each contextFiles}}
<file path="{{path}}">
{{content}}
</file>
{{/each}}
```

OMP's own tests confirm both halves. Identical content at two levels collapses to the
nearest copy (`test/system-prompt-dedup.test.ts:227-242`, asserting exactly one file and
that it is the `appDir` one) — that is **content-identity** dedup, not depth exclusion. And
*"keeps distinct context entries when their contents differ"* (`:244-262`) asserts **both**
survive into the prompt. `test/discovery/context-file-dedup.test.ts:30-38` asserts directly
that *"project-level files at different depths have different keys"*.

**Verdict: OMP is compliant with the convention, and arguably more generous than a literal
reading of it.** It is **not stricter**. A monorepo *can* layer a root file and a package
file; both are injected, nearest last and most prominent.

**Three consequences, in order of cost:**

1. **A budget claim is wrong in the dangerous direction.** `spec/key/05 §G-7` already found
   that `@import` makes AGENTS.md cost unbounded by its own file size. This finding
   compounds it: cost is unbounded by the *root* file's size too, because ancestor files
   stack. `spec/05 §I`'s budget check must sum **all discovered levels, post-import**. A
   template author following the current spec would compute one file and be wrong by however
   many levels exist above cwd.
2. **`spec/key/05 §G-7`'s remedy is unnecessary.** *"a monorepo package file must import the
   root explicitly"* (`05-coverage-audit.md:330-331`) prescribes a workaround for a
   limitation that does not exist. Worse, following it **double-counts**: the root is
   discovered *and* imported. Content-identity dedup (`system-prompt.ts:340-348`) probably
   catches the exact-duplicate case, but only if the import expands to byte-identical text.
3. **The installer-docs guidance inverts.** The spec says "tell authors they cannot layer".
   The truth is "tell authors they *can* layer, and that each level is paid on every turn of
   every subagent — so don't."  Same practical advice, opposite reason, and the reason is
   what a maintainer reasons from. Someone who believes layering is *impossible* will not
   look for the cost when they later see two files in a prompt.

**Why the error happened, worth recording:** the claim cites a real `file:line` that really
says "nearest, no concatenation". The mistake was **scope** — one provider was read and
generalised to the capability. `spec/key/05 §G-8` even *lists* `agents-md.ts` among the
foreign providers. The two facts were never joined. Grade A means "the cited lines support
it exactly"; it does not mean "no other lines contradict it", and this is a clean example of
that gap.

### 5.2 A secondary overstatement

`spec/key/02:576-577` — *"That is a runtime fact the convention does not imply"*. Even
granting the (wrong) reading, the convention does not *contradict* nearest-only either: C3
and C4 say "wins" and "takes precedence" without stating whether ancestors load (§2c). The
convention is silent, not contrary. Minor, but the spec asserts more clarity than the source
has.

### 5.3 Not a contradiction — a coverage note

`spec/key/repos/README.md` scopes this report as *"the convention vs OMP's stricter
implementation"*. The premise of the assignment is the thing that turned out to be false.
Recorded so the scope line is not inherited as a conclusion.

## 6. Cost profile

| §3 row | Where paid | Estimate and basis |
|---|---|---|
| C11 prohibitive instructions | `persistent` — `contextFiles` renders into the system prompt every turn, **and** into every subagent (`task/executor.ts:3024` passes `contextFiles` into the spawn) | ~30–60 tokens per prohibition (**estimate**, prose at ~1.3 tokens/word). Their own worked example is ~90 words ≈ 120 tokens for one rule. Expensive per line — which is the argument for few rules, each with a reason |
| C6 five suggested sections | `persistent` | If filled to the depth of their `EXAMPLE_AGENTS_MD` (`CodeExample.tsx:34-61`, ~200 words ≈ 260 tokens for three sections), five sections ≈ **400–500 tokens on every turn of every agent**. At our multiplier this is the single most expensive "looks complete" decision available in the template |
| C5 commands-are-executed | `persistent` for the text; **`per-action`** for any command actually run | No marginal token cost beyond the listing. The real cost is risk: a wrong or destructive command in a `persistent` file is a standing hazard |
| C4 monorepo layering | `persistent`, **multiplied by the number of ancestor levels**, and again per subagent | This is the number the spec was wrong about. *n* levels ⇒ *n* files in `<repo-rules>` (`project-prompt.md:12-16`), on every turn, in the coordinator **and** every worker. A 3-level monorepo with 200-token files ≈ 600 persistent tokens × (1 + spawns). **Estimate**; basis is the render loop and the per-depth dedup key, both verified |
| C7 rename + symlink | `zero` | Installer docs only. Watch the CLAUDE.md double-load; content-identity dedup should absorb it |

**The one number a template author most needs, which the spec currently makes
uncomputable:** effective persistent cost of context files = (sum of all discovered
`AGENTS.md`/`CLAUDE.md` levels from cwd to repoRoot, **post-`@import`-expansion**, after
content-identity dedup) × (1 coordinator + N subagent spawns). Both multiplicands were
understated in `spec/key` — the level count by §5.1, the import expansion by `05 §G-7`.

## 7. Coverage and limits  (MANDATORY)

**Files read in full — this repo (10):**
`README.md`, `AGENTS.md`, `components/FAQSection.tsx`, `components/HowToUseSection.tsx`,
`components/WhySection.tsx`, `components/AboutSection.tsx`, `components/Hero.tsx`,
`components/CompatibilitySection.tsx` (through the agent-entry array),
`components/CodeExample.tsx` (both example constants, via targeted grep with 40 lines
context), `LICENSE` (head, license determination).

**Files read in full — OMP, to support §5 (7):**
`discovery/agents-md.ts` (all 67 lines), `capability/context-file.ts` (all 44 lines),
`prompts/system/project-prompt.md` (all 61 lines),
`test/discovery/context-file-dedup.test.ts` (all 65 lines), plus these regions:
`discovery/builtin.ts:85-99` and `:905-945`, `discovery/helpers.ts:25-74` and `:549-551`,
`system-prompt.ts:340-390` and `:675-691` and `:840-870`,
`test/system-prompt-dedup.test.ts:195-275`, `task/executor.ts:3020-3046`.

**Files sampled (head/grep only):**
- `git ls-files` for both repos
- `grep` for `contextFileCapability` across `discovery/*.ts` — established that **9
  providers** register against this capability (`builtin`, `agents-md`, `agents`, `claude`,
  `codex`, `gemini`, `github`, `opencode`, and the capability definition), with priorities
  100/10/70/80/70/60/30/55
- `grep` for the spec's own claims across `spec/`

**Not opened:**
- All 27 SVG logos, `public/og.png`, favicons.
- Next.js scaffolding: `next.config.ts`, `tsconfig.json`, `package.json`,
  `postcss.config.mjs`, `pnpm-lock.yaml`, `pages/_app.tsx`, `pages/_document.tsx`,
  `styles/globals.css`, `next-env.d.ts`.
- `components/Section.tsx`, `Footer.tsx`, `ExamplesSection.tsx`, `ExampleListSection.tsx`,
  and all five icon components. **`ExamplesSection`/`ExampleListSection` are a real gap** —
  they likely link to third-party exemplar AGENTS.md files. Those are *external* files, so
  reading them would take me outside the pinned clone, but I cannot rule out that a curated
  example list encodes convention guidance I have not seen.
- `pages/index.tsx` — the section ordering. Presentation only; I read every section it
  composes.
- **OMP-side, and this bounds §5.1:** I read 2 of the 9 context-file providers in full
  (`agents-md.ts`, and the relevant region of `builtin.ts`). I did **not** read `claude.ts`,
  `codex.ts`, `gemini.ts`, `github.ts`, `opencode.ts`, or `agents.ts`. So my statement that
  *root-level `AGENTS.md` layers across depths* is verified for the `agents-md` provider and
  the shared dedup key; whether some **higher-priority** provider (`builtin` at 100,
  `claude` at 80) shadows an `agents-md` item at the same depth via the
  *"higher-priority providers shadow lower-priority ones"* rule
  (`context-file.ts:32`) I did **not** exhaustively verify. It cannot change the
  cross-depth conclusion — different depths are different keys — but it could affect which
  *file* wins at a given depth.
- `capability/index.ts` dedup loop read by grep only (`:183-206`). I confirmed first-wins
  and key-claiming behaviour from the comments and matched lines, not by reading the
  function end to end.

**Claims that need a live run before use:**
- The §6 layered-monorepo cost figure. Verified as *mechanism* (per-depth keys, the render
  loop, `contextFiles` passed to spawns). Not verified as a *token count* — needs a real
  3-level monorepo and a rendered prompt inspected.
- Whether the `@import`-the-root workaround from `spec/key/05 §G-7` actually double-counts
  in practice, or whether content-identity dedup (`system-prompt.ts:340-348`) absorbs it.
  Depends on whether the expanded import is byte-identical to the discovered file. Needs a
  run.
- The *"60k open-source projects"* adoption figure (`Hero.tsx:23-32`) is **grade B** — a link
  to a GitHub code search, not a count I performed. Immaterial to every recommendation here
  (and star-count reasoning is an anti-pattern anyway); flagged for honesty.

**Anything I suspect but could not verify:**
- I suspect the convention's ambiguity (§2c) is **deliberate**, so that tools with different
  context budgets can comply differently. Nothing in the repo says so.
- I suspect the `.omp/AGENTS.md` nearest-only rule (`builtin.ts:921-935`) is intentional and
  *correct* — a config directory is a project marker, so "nearest project" is the right
  semantic there, and it should not be conflated with root-level layering. But no comment
  states the rationale, so this is inference.
- I suspect, but did not verify, that the depth values from the two providers are
  **computed differently** and could collide or misalign. `agents-md.ts:38` uses
  `calculateDepth(ctx.cwd, fileDir, path.sep)` — which is
  `cwd.split(sep).length - targetDir.split(sep).length` (`helpers.ts:549-551`), a *string
  segment* subtraction. `builtin.ts:930` instead uses
  `nearestProjectConfigDir.depth` from `getAncestorDirs`. If those disagree for the same
  directory, two providers could produce different keys for what is semantically one scope,
  and both would render. That would *increase* layered cost beyond my §6 estimate. Worth a
  targeted check before anyone relies on the cost number.
