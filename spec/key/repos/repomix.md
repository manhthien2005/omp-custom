# Repo Report — repomix

> **Path:** `_research/upstreams/repomix`
> **SHA:** `a27ecec777f2e2b22871f3b280767c1625e23c8b` (`git -C repomix rev-parse HEAD`)
> **License:** MIT in substance, but the `LICENSE` file **omits the "MIT License" title line** —
> it opens directly with `Copyright 2024 Kazuki Yamada` followed by the standard MIT permission
> grant and the as-is disclaimer (`LICENSE:1-3`). `package.json` declares `"license": "MIT"`.
> The two agree on effect; the LICENSE file is simply untitled. Treat as MIT.
> **Size:** 1,174 tracked files (`git ls-files | wc -l`)
> **Read this pass:** `src/core/packager.ts` (361 lines, full), `src/core/output/outputSort.ts` (full),
> `src/core/file/filePathSort.ts` (full), `src/core/treeSitter/parseFile.ts` (full),
> `src/config/configSchema.ts` (full), `src/config/defaultIgnore.ts` (full),
> `src/core/metrics/calculateMetrics.ts` (full), `src/cli/cliTokenBudget.ts` (full),
> `src/core/security/securityCheck.ts` (full), `src/mcp/tools/packCodebaseTool.ts` (full),
> `src/core/output/outputStyles/xmlStyle.ts` (full), `src/core/treeSitter/queries/queryPython.ts` (full),
> `mcpToolRuntime.ts:166-256`, `fileProcess.ts:1-60`, `repomix.config.json`, `.repomixignore`.
> **Plus two live measurements** (see §6): a real `o200k_base` tokenization of both upstream repos,
> and an AST-proxy test of the `--compress` reduction claim.

---

## 1. What this repo is

Repomix is a **CLI + MCP server that concatenates a repository into one file** for an LLM to read.
It is a packaging tool, not a retrieval tool: it decides *what to include* (gitignore + a 163-entry
default ignore list + user globs), *how to order it* (deterministic path sort, optionally reordered
by git churn), *how to render it* (xml / markdown / json / plain), and *how big the result is*
(worker-pool tokenization against `gpt-tokenizer`).

The engineering is genuinely good — worker pools, a content-addressed token cache, a fast-path
token accounting trick, secretlint scanning, graceful WASM-abort degradation. But its entire
value proposition is *completeness*, which is the exact opposite of the problem we have. It has
**no notion of relevance**, by design.

---

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 1 | Pack pipeline | search → dedupe+sort → collect → processors → (security ∥ process) → churn re-sort → render ∥ metrics → save token cache. Concurrency is deliberate: security check runs on workers while file processing runs on the main thread "so they don't compete for CPU". | `packager.ts:76-361`, concurrency note `:233-236` | **A** |
| 2 | File selection | globby include/ignore, with `useGitignore`, `useDotIgnore`, `useDefaultPatterns` all default `true`, plus `customPatterns`. | `configSchema.ts:159-164`, search `file/fileSearch.ts` (549 lines, sampled) | **B** |
| 3 | 163-entry default ignore list | VCS, `node_modules`, build outputs, caches, `.env`, and **every major lockfile** (`package-lock.json`, `uv.lock`, `poetry.lock`, `Cargo.lock`, `go.sum`, `pnpm-lock.yaml`, `bun.lock`, `composer.lock`, `Gemfile.lock`, `mix.lock`). | `defaultIgnore.ts:1-163`, lockfiles `:122-161` | **A** |
| 4 | **Deterministic path ordering** (directories before files, then `localeCompare`) | Decorate-sort-undecorate to pre-split paths once. Explicitly normalizes `\` → `/` first, because on Windows splitting on `path.sep` would "silently degrade to a flat whole-string comparison". | `filePathSort.ts:10-37`, Windows note `:6-9` | **A** |
| 5 | **Git-churn re-ordering** — `sortByChanges`, default **`true`** | Sorts by commit-touch count over the last 100 commits, **ascending — most-changed files go to the *bottom***. Falls through to the original order if git is missing or the command fails. | `outputSort.ts:94-139`, direction+comment `:133-138`, default `configSchema.ts:151-152`, fallback `:109-111` | **A** |
| 6 | Churn sort **never drops a file** | `sortFilesByChangeCounts` returns `[...files].sort(...)` — a permutation. Every input file is in the output. This is the single most important fact in this report. | `outputSort.ts:134` | **A** |
| 7 | Tree rendering | Separate `generateFileTree` builds a `TreeNode` structure from paths (with a `WeakMap` child index for O(1) lookup) rendered into `<directory_structure>`. Independent of the file-content section. | `fileTreeGenerate.ts:23-34`, template slot `xmlStyle.ts:37-42` | **A** |
| 8 | 4 output styles, xml default | `xml` (default) / `markdown` / `json` / `plain`. XML template wraps each file as `<file path="...">`, preceded by `<file_summary>`, `<directory_structure>`, and followed by optional `<git_diffs>`, `<git_logs>`, `<instruction>`. | `configSchema.ts:6`, default `:129`, template `xmlStyle.ts:1-89` | **A** |
| 9 | `--compress` — tree-sitter signature extraction | Per-language tree-sitter query captures definitions/imports/comments; chunks are deduped (keep longest per start row), merged when adjacent, and joined with the separator `⋮----`. Default **`false`**. | `parseFile.ts:44-127`, separator `:36`, dedupe `:157-178`, merge `:180-213`, default `configSchema.ts:139` | **A** |
| 10 | Compress covers **16 languages** | `LANGUAGE_CONFIGS` has 16 entries (js, ts, python, go, rust, java, c_sharp, ruby, php, swift, c, cpp, css, solidity, dart, vue) with 7 parse strategies. Unsupported language ⇒ `return undefined` ⇒ **full uncompressed content**, silently. | `languageConfig.ts:64+` (16 `name:` entries), fallback `parseFile.ts:56-60` | **A** |
| 11 | Compress keeps docstrings and comments | The Python query captures `(comment)`, `(expression_statement (string)) @docstring`, imports, class/function definitions, call references, and type aliases. So "signatures only" still carries all prose. | `queries/queryPython.ts:1-32`, strategy `PythonParseStrategy.ts:29-49` | **A** |
| 12 | WASM abort never kills the pack | `parseFile` is fully wrapped: any failure returns `undefined` → uncompressed fallback. The comment is candid that a hard WASM abort can leave that worker's tree-sitter runtime degraded so *later* files on the same worker also silently fall back. | `parseFile.ts:110-126`, degradation admission `:113-120` | **A** |
| 13 | `removeComments` / `removeEmptyLines` — separate, both default `false` | Per-language manipulator classes (`BaseManipulator`, `StripCommentsManipulator`, `CompositeManipulator`). Transform order is documented: `[removeComments → compress] (worker) → truncateBase64 → removeEmptyLines → trim → showLineNumbers`, with `removeEmptyLines` after `removeComments` deliberately. | `fileManipulate.ts:5-109`, order `fileProcess.ts:18-20`, defaults `configSchema.ts:137-138` | **A** |
| 14 | `output.patterns` — per-file inclusion level | Glob → `{compress?, directoryStructureOnly?}`, first match wins. `directoryStructureOnly` lists the file in the tree but **omits its content**. The closest thing to selection in the tool — and it is entirely **user-authored**. | `configSchema.ts:21-32`, precedence note `:26-30` | **A** |
| 15 | Token counting via `gpt-tokenizer` in a worker pool | Default encoding `o200k_base`. Pool sized `min(cpu, ceil(N/100))`; warm-up dispatches empty tasks to pre-pay the ~225 ms BPE table parse off the critical path. | `calculateMetrics.ts:79-99`, default `configSchema.ts:169`, BPE cost `:44-45` | **A** |
| 16 | Warm/cold prewarm heuristic | Two `existsSync` probes (global cache file + per-repo "seen" marker) decide whether to warm 1 worker or all of them, "saving up to (maxThreads − 1) wasted ~225ms BPE parses". Explicitly labelled "a best-effort warm/cold predictor, not a correctness signal". | `calculateMetrics.ts:48-92`, disclaimer `:74-77` | **A** |
| 17 | **Fast-path output tokenization** | Instead of re-tokenizing the whole ~4 MB output, it extracts the "wrapper" (output minus every file's content) via a single forward `indexOf` pass, tokenizes just that, and adds the already-known per-file counts. Returns `null` and falls back if any content is not found verbatim. | `extractOutputWrapper` `calculateMetrics.ts:120-140`, eligibility `:142-147`, use `:199-232` | **A** |
| 18 | Content-addressed persistent token cache | `token-counts.json` under the repomix tmp dir, keyed by `(encoding, content)` hash, capped at `MAX_CACHE_ENTRIES = 100_000` with FIFO eviction enforced in *both* `setCached` and the save path ("defence in depth"). Atomic save (tmp + rename), errors swallowed. | `tokenCountCache.ts:21`, `:26`, `:71`, eviction `:262-268`, `:342-343`, atomicity `packager.ts:349-352` | **A** |
| 19 | The wrapper is cached too | The wrapper string is "byte-stable across runs whenever the file set, headers, instructions, and template format are unchanged", so it reuses the same content-addressed cache. Any change misses automatically. | `calculateMetrics.ts:210-225` | **A** |
| 20 | `tokenBudget` is a **post-hoc failure**, not a constraint | `validateTokenBudget` runs *after* the output is fully produced and written, and throws. Its own message tells the human to fix it: "Reduce the output with --compress, narrow the scope with --include/--ignore, or raise --token-budget." | `cliTokenBudget.ts:13-22`, call sites `defaultAction.ts:197`, `remoteAction.ts:197`, timing note `cliTokenBudget.ts:7-12` | **A** |
| 21 | `topFilesLength` report — largest, not most relevant | CLI prints "📈 Top N Files by Token Count", sorted `b[1] - a[1]` descending. Default 5. Purely a size report to help a human shrink the pack. | `cliReport.ts:187-201`, header `:194`, default `configSchema.ts:140` | **A** |
| 22 | `tokenCountTree` | Optional per-directory token tree; can take a number as a threshold (repomix's own config uses `50000`). | `configSchema.ts:88`, `:147`, own use `repomix.config.json:22` | **B** |
| 23 | `splitOutput` | Split the output into N parts; disables the fast token path. | `configSchema.ts:87`, `:146`, exclusion `calculateMetrics.ts:143` | **A** |
| 24 | Secret scanning via **secretlint**, default **on** | `@secretlint/secretlint-rule-preset-recommend` run in worker threads, batched 50 files per task, workers capped at 2 "to reduce contention with the metrics worker pool". Scans **git diffs and git logs too**, not just files. | `securityCheck.ts:24-130`, batch `:22`, cap `:81-84`, diff/log items `:38-65`, config `.secretlintrc.json`, default `configSchema.ts:166` |**A** |
| 25 | Flagged files are **dropped from the output** | Suspicious paths are collected into a Set and filtered out of `processedFiles`. A leaked secret is excluded, not redacted. | `packager.ts:250-253` | **A** |
| 26 | `truncateBase64` | Truncates long base64 blobs (embedded images) to cut tokens. Default `false`, but repomix enables it in its own config. | `configSchema.ts:83`, `:142`, own use `repomix.config.json:21` | **A** |
| 27 | **The MCP path returns a handle, not the pack** | `pack_codebase` writes the output to a temp workspace and returns `{outputId, outputFilePath, totalFiles, totalTokens, topFiles, directoryStructure}` — **the packed content is never in the tool result**. The description tells the agent to "review the metrics below and consider adjusting compress/includePatterns/ignorePatterns if the token count is too high **before reading the file content**". | `packCodebaseTool.ts:77-85`, `:204-214`, response builder `mcpToolRuntime.ts:174-228`, advisory `:226` | **A** |
| 28 | `grep_repomix_output` — regex into the pack | Search the packed artifact by JS RegExp with `-A`/`-B`-style context lines, returning matches + line numbers. The pack becomes a *searchable index on disk*, read incrementally. | `grepRepomixOutputTool.ts:18-50` | **A** |
| 29 | `read_repomix_output` — line-ranged read | `startLine`/`endLine` (1-based, inclusive) with validation. Reads a slice, not the whole artifact. | `readRepomixOutputTool.ts:18-34` | **A** |
| 30 | Upstream advises **against** compress in MCP | The `compress` param description says: "**Generally not needed since grep_repomix_output allows incremental content retrieval.** Use only when you specifically need the entire codebase content for large repositories (default: false)." | `packCodebaseTool.ts:43-48` | **A** |
| 31 | MCP sandbox lockdown | With `--sandbox`: skip *both* local and global config files (either could set `instructionFilePath` to exfiltrate an out-of-workspace file, or `input.processors` to run commands), confine the search to root, and **disable git churn sort** because `git log` reads the untrusted workspace's `.git/config` (e.g. `gpg.program` via `log.showSignature`) — "a host command-execution vector". | `packCodebaseTool.ts:169-182` | **A** |
| 32 | Brace-aware pattern escape check | `patternsEscapeRoot` tokenizes then brace-expands each glob before checking, because `{/etc/**,x}` expands to an absolute path fast-glob would honor. Documented as "an early, human-readable rejection, **not the security boundary**"; the real backstop is `confineToBaseDir` in `searchFiles`. | `packCodebaseTool.ts:23-39` | **A** |
| 33 | `input.processors` — arbitrary command execution, gated | Glob → shell command with a `{file}` placeholder; replaces content with stdout. Off by default for library/MCP/website callers, injected only by the real CLI entry; remote runs need `--remote-trust-config`. | `configSchema.ts:40-55`, gate `:186-190` | **A** |
| 34 | **No ranking, no scoring, no relevance — anywhere** | Every sort in the codebase is by path, by git churn, by raw size, or by chunk length. There is no query input to the packer at all, so relevance is not merely unimplemented — it is not expressible. | `filePathSort.ts:16-34`, `outputSort.ts:132-139`, `cliReport.ts:200`, `parseFile.ts:172`; no query param in `packCodebaseTool.ts:41-75` | **A** |
| 35 | **`grep_repomix_output` is unbounded** | The match loop appends every hit with no cap, no `slice`, and no `maxResults` parameter; the response carries the full `matches` array plus `formattedOutput` with context lines. A common pattern over a 1.4 M-token artifact returns an arbitrarily large result. Qualifies #27: the incremental-access pattern is right, but the cap must come from us. | loop `grepRepomixOutputTool.ts:261-273`, unbounded response `:198-202`, no limit field in schema `:18-34` | **A** |

---

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| #27+#28+#29 **Pack-to-disk, then grep it — never read the artifact into context** | Any onboarding/audit command; OMP `grep` and `Read` with line ranges over a generated artifact | `lazy` — a handle + metrics (~200–400 tokens), then only the grep hits | **ADOPT (as the *pattern*, not the tool) — with a cap we add** | This is the finding of the pass and it inverts our recorded position. The expensive thing about repomix is reading its output, and **repomix's own MCP server never does that.** The generalizable craft: when a step produces a large artifact, return a *handle plus a size report*, and make retrieval incremental. Apply with OMP's existing `grep`/`Read` — no repomix needed. **Caveat (#35, verified): their grep is uncapped**, so the incremental step can itself flood. Adopt the shape, supply the bound. |
| #20 → inverted: **report size before content, and make the agent decide** | Any command that could produce a large result | `lazy` (~50 tokens for the metrics line) | **ADAPT** | Their `tokenBudget` throws *after* paying full cost (`cliTokenBudget.ts:7-12`) — that half is a defect for us. The good half is #27's advisory: surface `totalTokens` + `topFiles` *first* so the next action is informed. Cheap, and directly serves tokens-per-accepted-outcome. |
| #3 The 163-entry default ignore list | Any repo-wide sweep a worker agent performs | `zero` (a list we consult, not emit) | **ADAPT** | Free correctness. The lockfile block (`defaultIgnore.ts:122-161`) alone is worth taking: measured, lockfiles are **955 KB across 7 files** in repomix and **597 KB across 6** in serena — pure waste if swept. Not a mechanism to build, a list to copy. |
| #14 `directoryStructureOnly` — list the file, omit its content | Report format for worker agents summarizing a wide surface | `zero` | **ADAPT** | Useful three-state vocabulary for *our own reports*: full / signatures-only / named-in-tree-only. Lets a worker acknowledge a file exists without paying for it. |
| #24+#25 Secret scan before an artifact is emitted, and **drop rather than redact** | Any command that writes a bundled artifact or posts a diff outward | `per-action` (only findings) | **ADAPT** | We already flag secret-bearing files. The transferable decisions: scan **git diffs and logs too** (`securityCheck.ts:38-65`) — an easy miss — and prefer exclusion over redaction (`packager.ts:250-253`), since a partial redaction that fails is worse than an omission. |
| #31 Config files are an untrusted-input vector | Any command that reads a project-supplied config in an unfamiliar repo | `zero` | **ADOPT (as a caution)** | Concrete and non-obvious: `git log` in an untrusted repo is **host command execution** via `.git/config` `gpg.program` (`packCodebaseTool.ts:176-179`); and a config-declared instruction-file path can exfiltrate an out-of-workspace file into agent-visible output (`:171-175`). Both apply to us the moment a worker runs git in a repo we did not write. |
| #17 Fast-path token accounting (wrapper + per-file sums) | — | — | **REJECT** | Excellent engineering, no attachment point. We do not tokenize artifacts ourselves; there is nothing to make faster. Recording it would be documentation, which rule 4 forbids. |
| #9 `--compress` tree-sitter signature extraction | OMP `ast-grep` | `lazy` | **DEFER** | **Trigger:** if a command is ever specified that must summarize >20 files of one language in a single pass. Measured reduction is real (~63%, §6), but OMP's `ast-grep` already extracts structure per query, and 16 languages with silent full-content fallback (#10) is a sharp edge. Do not build until a command needs it. |
| #5 Git-churn ordering | — | — | **REJECT, and note the direction** | Churn is not relevance, and repomix's own default puts most-changed files **last** (`outputSort.ts:133-138`), i.e. it treats churn as *de*-prioritizing. Anyone reaching for "sort by recent activity" as a proxy for importance should know the one tool that ships it points the arrow the other way. |
| #34 Ranking | — | — | **REJECT (nothing exists)** | No query enters the packer. See the verdict below. |

---

## 4. What this repo does that we deliberately will not

**Use repomix as an exploration tool.** Confirmed with numbers, not intuition (§6): a default pack
of repomix itself is **~1.36 M tokens**; of serena, **~1.37 M**. Both are ~7× a 200 k context
window. As a default this is not merely expensive, it is impossible. Our rejection stands and is
now quantified.

**Read a packed artifact into context at all — including in the approved onboarding case.** This is
where our position needs to change, and repomix's own design is the argument. Its MCP server
deliberately does not do it (#27): the tool result is a handle plus metrics, and content arrives
only through `grep_repomix_output` (#28) or a line-ranged `read_repomix_output` (#29). The upstream
even discourages `--compress` on the grounds that grep makes it unnecessary (#30). If we ever
invoke repomix for onboarding, "read the output" is the wrong shape; "grep the output" is the
right one — and if we are only going to grep it, OMP's `grep` over the working tree already does
that without producing a 1.36 M-token file first.

**Adopt `tokenBudget` as our budget model.** It produces the whole output, writes it, tokenizes it,
*then* throws (`cliTokenBudget.ts:7-12`). The full cost is paid before the limit is enforced — the
only thing saved is the human's attention. A budget that engages after the spend is not a budget.
Ours must gate *before*.

**Treat "compression" as a bounded-output guarantee.** `--compress` has no ceiling: it is a
per-file ratio, so output still scales linearly with repo size. Worse, on any language outside the
16 it silently emits **full content** (`parseFile.ts:56-60`), and a WASM abort can degrade a whole
worker so later files silently fall back too (`parseFile.ts:113-120`). This directly answers the
open question at `dossiers/retrieval-cluster.md:348`: **there is no bounded ceiling.** A 63%
reduction on a 1.37 M-token repo is still ~500 k tokens.

**Confuse "top files" with "important files."** `topFilesLength` sorts by **token count descending**
(`cliReport.ts:200`). On serena the top hit is `resources/serena-block-diagram.svg` at 74,342
tokens — an SVG. This is a size report for a human trimming a pack, and the name invites exactly
the enumeration/ranking conflation we already made once.

---

## 5. Contradictions with our current spec or registry

**1. The "20k–200k tokens per invocation" figure is wrong by roughly an order of magnitude.**

> `registry/rejected-mechanisms.yml:81-82` (`reject-011`) — "Full repository dumps flood context
> (20,000–200,000 tokens)."
> Repeated at `spec/key/02-repo-synthesis.md:617` ("20k–200k tokens per invocation") and
> `dossiers/retrieval-cluster.md:344`.

Measured with `o200k_base` — repomix's own default encoding (`configSchema.ts:169`) — over all
tracked files minus the lockfiles repomix ignores by default:

| Repo | Files | Chars | **Tokens** |
|---|---|---|---|
| repomix @ `a27ecec` | 1,144 | 5,133,640 | **1,362,764** |
| serena @ `c7af2c0` | 985 | 5,982,510 | **1,368,434** |

Both are **~6.8× the top of the recorded range**. The 200 k ceiling corresponds roughly to a
`src/`-only pack (repomix `src/` = 152,601 tokens; serena `src/` = 645,111 — and even that
overshoots). The recorded range describes a *scoped* pack, not the "full repository dump" the entry
names.

The verdict is unaffected — a wrong number that is 7× too *low* makes the rejection stronger, not
weaker. But the number is inherited as a constraint, and someone will eventually reason "200 k is
survivable in a 1 M context window, let's allow it." It is not 200 k. Suggest correcting to
**~1.4 M tokens for a mid-size (~1,000-file) repository, measured**, with the note that it scales
with repo size and has no ceiling.

**2. The conditional approval for onboarding/audit/external-review is under-specified in the way
that matters most.**

> `reject-011` — "Repomix is allowed only for onboarding, architecture audits, and external
> reviews." Echoed at `registry/upstreams.yml:481-484` (`authority_for`) and
> `spec/key/02-repo-synthesis.md:617`.

The approval says *when* but not *how*, and "how" is the whole question. A full pack read into
context during onboarding costs ~1.4 M tokens and cannot execute. The approval is only coherent
under one of: (a) heavily scoped `--include`; or (b) repomix's own MCP shape — pack to disk, read
metrics, grep incrementally (#27–#29). Note that `registry/upstreams.yml:483` says "repository
**subset** snapshots", which is the right instinct; `rejected-mechanisms.yml` and the spec do not
carry that qualifier. Suggest the approval name the retrieval shape explicitly, or it will be read
as license to pack a whole repo.

**3. `dossiers/retrieval-cluster.md:357` poses a question that is now answered — the answer is the
pessimistic branch.**

> "if repomix's compressed mode has no hard token ceiling, then even in onboarding it is
> unbounded"

Confirmed: no ceiling. `--compress` is a per-file transform (`parseFile.ts:44-127`); nothing
aggregates or caps. Silent full-content fallback on unsupported languages (`:56-60`) makes the
worst case *worse* than the ratio suggests. The conditional-branch conclusion the dossier
anticipated now applies.

**4. `dossiers/retrieval-cluster.md:352` mischaracterizes the contrast.**

> "difference: repomix compresses, aider *budgets*"

Accurate as far as it goes, but it understates the gap. Compressing vs budgeting is a difference of
mechanism; the real difference is that **aider has a query and repomix does not**. repomix's packer
takes no query parameter at any layer (`packCodebaseTool.ts:41-75`; `pack()` signature
`packager.ts:76-83`), so it is not a weaker ranker than aider — it is not a ranker, and cannot
become one without a new input.

**5. `spec/README.md:225` groups repomix with Serena as "semantic retrieval".**

> "Repo-map / semantic retrieval (Serena, repomix) — deferred pending evidence"

Neither is semantic retrieval. repomix is deterministic concatenation with no query, no embedding,
and no relevance (#34). Also flagged in `serena.md` §5; the two are not the same kind of artifact
and grouping them obscures that repomix's transferable finding (#27's handle-plus-grep pattern) is
about *artifact access*, not retrieval at all.

**6. `spec/key/02-repo-synthesis.md:683` and `dossiers/retrieval-cluster.md:29`, `:338`, `:501` are
superseded.**

Those record repomix as "source never opened" / "NOT READ THIS PASS" / confidence "Low", with
`:501` marking the compression mode "Unverified; measure". This pass opened the source and measured
it (§6). Those markers should now point here.

---

## 6. Cost profile

**Live measurement 1 — full-pack token cost.** `o200k_base` via `tiktoken`, all tracked files minus
repomix's default-ignored lockfiles:

| Repo | Files | Chars | Tokens | chars/token |
|---|---|---|---|---|
| repomix | 1,144 | 5,133,640 | **1,362,764** | 3.77 |
| repomix `src/` only | 143 | — | 152,601 | — |
| serena | 985 | 5,982,510 | **1,368,434** | 4.37 |
| serena `src/` only | 199 | — | 645,111 | — |

Rendering overhead is on top of this: the XML wrapper adds `<file path="...">` per file plus
`<file_summary>`, `<directory_structure>`, and the optional git-diff/git-log sections
(`xmlStyle.ts:1-89`). ~1.4 M is a floor, not a total.

**Live measurement 2 — the "~70% reduction" compress claim.** The claim appears in
`packCodebaseTool.ts:47` and four places in `README.md` (`:1049`, `:1068`, `:1157`). I could not run
repomix (no `node_modules` in the clone), so I tested a Python-AST proxy replicating exactly what
`queryPython.ts` captures — class/function signature lines, docstrings, comments, imports — over
serena's 152 Python source files:

| | Tokens |
|---|---|
| Original | 552,379 |
| Compress-proxy | 202,139 |
| **Reduction** | **63.4%** |

So ~70% is roughly honest, slightly optimistic, and **grade B** (proxy, not the real tree-sitter
path). The operative point is unchanged: 63% off 1.37 M is still ~500 k tokens. Compression changes
the constant, not the conclusion.

**Cost of each §3 row:**

| Row | Where the token is paid | Amount |
|---|---|---|
| #27–#29 handle-plus-grep pattern | `lazy` — handle + metrics on invocation, then per-grep | ~200–400 tokens for the metrics response (`outputId`, `totalFiles`, `totalTokens`, `totalLines`, `topFiles`, tree — `mcpToolRuntime.ts:198-214`; the tree can be large on a big repo), then only matching lines. **Estimate**, basis: the JSON shape read at `:198-214`. |
| #20-inverted size-first reporting | `lazy` | ~50 tokens |
| #3 ignore list | `zero` | Consulted, never emitted. Saves 955 KB (repomix, 7 files) / 597 KB (serena, 6 files) of lockfile text if a sweep would otherwise include it |
| #14 three-state file vocabulary | `zero` | A convention |
| #24/#25 secret-scan decisions | `per-action` | Only findings |
| #31 untrusted-config caution | `zero` | 2–3 lines of prose |
| #9 compress (DEFER) | `lazy` | ~63% of whatever the uncompressed span would cost — measured above. Unbounded above. |

**What repomix's own artifact costs on disk, if we ever run it:** `token-counts.json` in the
repomix tmp dir, ≤100,000 entries with FIFO eviction (`tokenCountCache.ts:21`, `:262-268`) — a
latency cache, `zero` context cost, but it is a persistent artifact and worth naming as such.

---

## 7. Coverage and limits

**Files read in full:** `src/core/packager.ts`, `src/core/output/outputSort.ts`,
`src/core/file/filePathSort.ts`, `src/core/treeSitter/parseFile.ts`, `src/config/configSchema.ts`,
`src/config/defaultIgnore.ts`, `src/core/metrics/calculateMetrics.ts`, `src/cli/cliTokenBudget.ts`,
`src/core/security/securityCheck.ts`, `src/mcp/tools/packCodebaseTool.ts`,
`src/core/output/outputStyles/xmlStyle.ts`, `src/core/treeSitter/queries/queryPython.ts`,
`repomix.config.json`, `.repomixignore`, `.secretlintrc.json`, `LICENSE`.

**Files sampled (range/grep only):**
- `src/mcp/tools/mcpToolRuntime.ts` (371 lines) — read `:166-256` only
- `src/core/file/fileProcess.ts` — read `:1-60`
- `src/core/file/fileTreeGenerate.ts` — read `:1-40`
- `src/core/treeSitter/languageConfig.ts` — grepped the `LANGUAGE_CONFIGS` names; **language count
  of 16 is from `grep -c "^    name: '"`, not a full read**
- `src/core/treeSitter/parseStrategies/PythonParseStrategy.ts` — read `:1-50`
- `src/core/metrics/tokenCountCache.ts` (359 lines) — **grep only**
- `src/core/file/fileManipulate.ts` — grep of class/method names only
- `src/cli/cliReport.ts` — grepped `:187-201`
- `src/mcp/tools/grepRepomixOutputTool.ts` (335 lines) — schemas plus the match loop and response
  path (`:189-202`, `:261-301`) grepped to settle the result-cap question (#35); the sandbox
  secret-rescan path (`:143-178`) was not read. `readRepomixOutputTool.ts` — schema and validation
  only, not the read handler.
- `README.md` (86 KB) — grepped for compression claims only

**Not opened at all:**
- `src/core/file/fileSearch.ts` (549 lines) — **the largest gap.** Mechanism #2 (file selection) is
  grade **B** because of this; I read the config schema that drives it, not the globbing itself.
  `confineToBaseDir`, referenced as the real security boundary (`packCodebaseTool.ts:33-38`), lives
  here and is unverified.
- `src/cli/actions/defaultAction.ts` (474 lines), `cliRun.ts` (450), `remoteAction.ts`,
  `watchAction.ts`, `migrationAction.ts`, `initAction.ts`
- `src/core/output/outputGenerate.ts` (444 lines) — the actual rendering engine. I read the XML
  *template* but not the code that fills it.
- `src/core/skill/*` (skillTechStack.ts is the repo's largest file at 657 lines), `packSkill.ts`,
  `generateSkillTool.ts` — **an entire feature (skill generation) I did not investigate at all**
- `src/core/security/workers/securityCheckWorker.ts` — the actual secretlint invocation
- `src/core/git/*` (gitCommand, gitRemoteParse, gitHubArchive, gitDiffHandle, gitLogHandle)
- 6 of 7 parse strategies; 15 of 16 tree-sitter queries
- `src/core/output/outputSplit.ts`, `outputStyleDecorate.ts`, `outputStyleUtils.ts`, and the
  markdown/json/plain style templates
- `attachPackedOutputTool.ts`, `fileSystem*Tool.ts`, `mcpServer.ts`
- The entire `tests/` tree, `website/`, `browser/`, `skills/`, `.agents/`, `.claude/`

**Claims that need a live run before use:**
- **The 1.36 M / 1.37 M token figures are my own tokenization of the file set, not repomix output.**
  I could not run repomix (no `node_modules`). They exclude XML wrapper overhead (which makes the
  real number *higher*) and assume the default ignore set resolves to what I filtered (basename
  match on 9 lockfile names). A real `repomix --token-count-tree` would settle it. Grade **B**, and
  the direction of error is conservative.
- **The 63.4% compress figure is an AST proxy, not tree-sitter.** Grade **B**. My proxy keeps whole
  signature lines and whole docstrings; the real strategy merges adjacent chunks and inserts `⋮----`
  separators (`parseFile.ts:180-213`), and captures call references my proxy drops. Real output
  could differ meaningfully in either direction.
- ~~Whether `grep_repomix_output` returns bounded results~~ — **resolved during this pass, see #35.**
  It is unbounded. The handler's match loop `for (let i = 0; i < lines.length; i++) { ... matches.push(...) }`
  has no cap, no `slice`, and no `maxResults` option (`grepRepomixOutputTool.ts:261-273`); every match
  and its context lines are returned (`:198-202`). Grepping for a common token over a 1.4 M-token
  artifact can therefore return an arbitrarily large result. This qualifies the #27 ADOPT: the
  pattern is sound, but **we must supply the cap repomix does not.**
- The token-cache hit rate and on-disk size in practice.

**Suspected but could not verify:**
- I believe no query/relevance input exists anywhere, based on the `pack()` signature
  (`packager.ts:76-83`), the MCP input schema (`packCodebaseTool.ts:41-75`), and the full config
  schema. Since I did not read `fileSearch.ts` or the CLI actions, a query-ish option could
  theoretically exist there — but it could not affect ordering, because every sort I traced runs in
  `packager.ts`/`outputSort.ts`, which I read in full. Confidence very high.
- `skillTechStack.ts` (657 lines) and the skill-generation feature may contain a prioritization
  heuristic — it plausibly decides what about a codebase is worth describing. **This is the one
  place a ranking mechanism could be hiding, and I did not look.** If any part of this report should
  be revisited, it is this.
- `--compress` on a *comment-sparse* codebase likely reduces far more than 63% (serena's Python is
  heavily docstringed, and the query keeps every docstring — `queryPython.ts:4-5`). The 63% figure
  is probably a conservative case for compression, i.e. favourable to repomix.

---

## RANK vs ENUMERATE — verdict

**Repomix ENUMERATES. It is a concatenator, and ranking is not merely absent — it is
inexpressible.**

The decisive structural fact: **the packer takes no query.** `pack(rootDirs, config,
progressCallback, deps, explicitFiles, options)` (`packager.ts:76-83`) has no parameter that could
express "what am I looking for", and neither does the MCP tool schema
(`packCodebaseTool.ts:41-75`). Relevance is not a feature repomix declined to implement; it is a
concept with no input channel. Contrast aider, which personalizes PageRank toward the query — that
requires a query to exist.

Every sort in the codebase, traced to its comparator:

| Sort | Comparator | Kind |
|---|---|---|
| `sortPaths` | directory-before-file, then `localeCompare` | lexicographic |
| `sortFilesByChangeCounts` | `countA - countB`, git touches, **ascending** | churn, and *de*-prioritizing |
| `reportTopFiles` | `b[1] - a[1]` on token count | raw size |
| `filterDuplicatedChunks` | `b.content.length - a.content.length` | string length |
| tree-sitter captures | `a.node.startPosition.row - b.node.startPosition.row` | source order |

Evidence: `filePathSort.ts:16-34`, `outputSort.ts:132-139`, `cliReport.ts:200`,
`parseFile.ts:172`, `parseFile.ts:90`. Not one consults a relevance signal.

The two mechanisms that look like ranking, and are not:

- **`sortByChanges` (default on)** reorders by churn but **never drops a file** — it is
  `[...files].sort(...)`, a permutation (`outputSort.ts:134`). And the direction is *against* the
  intuitive reading: "files with more changes go to the bottom" (`:133`). A churn-based *ranker*
  would surface hot files; repomix buries them, likely so stable/foundational files land in the
  prompt's early, better-attended region. Anyone tempted to treat churn as an importance proxy
  should note that the one tool shipping it by default points the arrow the other way.
- **`topFilesLength`** is a **size** report for a human (`cliReport.ts:194` literally prints "Top N
  Files by Token Count"). On serena the #1 entry is a 74,342-token SVG. Nothing consumes this
  ordering; it is printed to a terminal.

The only selection anywhere is `output.patterns` with `directoryStructureOnly`
(`configSchema.ts:21-32`) — and it is **user-authored globs**. The human ranks; the tool executes.
`tokenBudget` reinforces this: over-budget is a `RepomixError` telling the *human* to narrow the
scope (`cliTokenBudget.ts:18-21`). At the exact moment a ranker would spend its relevance signal,
repomix hands the decision back.

**Direct answer on our gap (OQ-G): repomix contributes nothing toward closing it, and cannot.** It
is a different tool for a different job — high-recall completeness for a human-directed scope, not
precision under a budget. Filing it near aider in the retrieval cluster invites exactly the
enumeration/ranking conflation recorded in `omp-ranking-capability-gap`.

The genuinely valuable finding here is orthogonal to ranking, and it is the one thing that should
change our posture: **repomix's own MCP server never puts the pack in the context.** It returns a
handle and a token count, then serves content through grep and line-ranged reads (#27–#29), and its
own tool description argues `--compress` is usually unnecessary *because* grep exists
(`packCodebaseTool.ts:47`). The right lesson from repomix is not "packing is too expensive" — we
already knew that, and were off by 7× on how much. It is that **an artifact you grep is cheap and
an artifact you read is not**, which is a pattern we can apply with OMP's existing `grep` and
`Read` and without repomix at all.

One honest qualification, verified rather than assumed (#35): repomix does not finish the job it
starts. `grep_repomix_output` has no result cap — the match loop appends every hit and the response
carries all of them plus context lines (`grepRepomixOutputTool.ts:261-273`, `:198-202`). So the
incremental step can flood the context that packing-to-disk just protected. The pattern is right and
the implementation is half-done. We take the shape and supply the bound ourselves — which is
`_limit_length`-style progressive degradation, the ADOPT from `serena.md` §3. The two reports
converge there: **pack to disk, grep incrementally, and degrade the result in tiers rather than
truncating it.** Neither upstream does both.
