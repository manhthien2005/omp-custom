# Dossier — Retrieval Cluster (aider, serena, repomix, context7)

> commits (read from each `_research/upstreams/<repo>/.git`):
> - `aider` — `5dc9490bb35f9729ef2c95d00a19ccd30c26339c` (Apache-2.0)
> - `serena` — `c7af2c09ef45faa4367c0e2a9f770fb73a62a612`
> - `repomix` — `a27ecec777f2e2b22871f3b280767c1625e23c8b`
> - `context7` — `8d52608e4e27557e6c1e807c8241cffb5544a9a3`

> **COMPLETENESS DISCLOSURE.** This pass was cut short by the coordinator. Depth achieved
> is uneven and is stated per section. Verified-by-reading: aider `repomap.py` (all 867
> lines), `aider/coders/base_coder.py:660-761`, `aider/models.py:782-789`,
> `aider/special.py:150-202`, `aider/website/docs/repomap.md`, OMP
> `src/prompts/tools/lsp.md`, serena `src/serena/tools/symbol_tools.py` (class/method index
> only, via grep). **NOT READ THIS PASS:** repomix source, context7 source, serena
> `tools_base.py` / `file_tools.py` bodies, OMP `src/tools/ast-grep.ts`,
> `src/tools/grep.ts`, `src/tools/read.ts` bodies, OMP lsp tool schema. Sections 5 and 6
> are therefore reasoned from the registry entries plus general knowledge of those tools
> and are explicitly flagged as unverified. Every unverified claim is marked
> **[NOT READ THIS PASS]**.

---

## 1. Per-repo thesis

| Repo | Thesis in one sentence | Confidence |
|---|---|---|
| aider | The repo-map is not a symbol list, it is a **budgeted ranking**: a PageRank over a symbol-reference multigraph, personalized toward the files and identifiers the user just mentioned, binary-searched down to a token ceiling. The ranking is the product; the signature rendering is just the presentation layer. | High — full source read |
| serena | A curated **LSP-over-MCP façade**: it wraps language-server primitives into task-shaped operations (`find_symbol` with name-path matching, `find_referencing_symbols`, `get_symbols_overview`) plus symbol-level *editing* (`replace_symbol_body`, `insert_after_symbol`, `rename_symbol`). Its differentiator vs raw LSP is ergonomics and symbol-level edits, not new information. | Medium — tool index read, bodies not read |
| repomix | Whole-repo packing with optional tree-sitter signature compression. Interesting mode is compression, not the default dump. | **Low — [NOT READ THIS PASS]** |
| context7 | Version-pinned library documentation retrieval over MCP; value is *version correctness* on fast-moving external APIs, which no local tool can supply if the dependency is not vendored. | **Low — [NOT READ THIS PASS]** |

---

## 2. Aider repo-map — mechanism in detail

### 2.1 Tag extraction (tree-sitter, not LSP)

`aider/repomap.py:279-363` — `get_tags_raw`. Language is inferred from filename
(`filename_to_lang`, `repomap.py:280`), a tree-sitter parser is obtained
(`repomap.py:285-286`), and a per-language tags query is loaded from a `.scm` file
(`repomap.py:291-294`, resolved by `get_scm_fname`, `repomap.py:805-829`). Captures whose
tag name starts with `name.definition.` become `kind="def"`; `name.reference.` become
`kind="ref"` (`repomap.py:319-324`). The emitted record is
`Tag = namedtuple("Tag", "rel_fname fname line name kind")` (`repomap.py:29`).

Critical fallback: some languages' tag queries only provide definitions (C++ is the cited
example). When defs were seen but no refs, aider **backfills references with a Pygments
lexer**, treating every `Token.Name` in the file as a reference with `line=-1`
(`repomap.py:338-363`). This is a deliberately sloppy, high-recall reference source — it
matters for section 3, because it means aider's graph does not require semantic resolution
to work.

### 2.2 The ranking function — exact, from source

`get_ranked_tags` (`repomap.py:365-574`).

**Graph shape.** `G = nx.MultiDiGraph()` (`repomap.py:470`). **Nodes are files**
(`rel_fname`), not symbols. Edges are `referencer_file → definer_file`, one edge per
`(referencer, definer, ident)` triple (`repomap.py:514`).

**Which identifiers become edges.** Only the intersection of defined and referenced names:
`idents = set(defines.keys()).intersection(set(references.keys()))` (`repomap.py:468`).
Names defined but never referenced get a **self-loop with weight 0.1**
(`repomap.py:475-479`) so the file still exists in the graph. If there are no references at
all anywhere, references are aliased to defines (`repomap.py:465-466`).

**Edge weight multipliers** (`repomap.py:487-514`) — this is the actual heuristic core:

| Condition | Multiplier | Line |
|---|---|---|
| identifier appears in the user's current message (`mentioned_idents`) | `×10` | `repomap.py:492-493` |
| identifier is snake_case / kebab-case / camelCase **and** `len ≥ 8` | `×10` | `repomap.py:494-495` |
| identifier starts with `_` (private) | `×0.1` | `repomap.py:496-497` |
| identifier is defined in **more than 5 files** (i.e. it is a generic name like `run`, `get`) | `×0.1` | `repomap.py:498-499` |
| the *referencing* file is currently in the chat | `×50` | `repomap.py:507-509` |
| reference count from that file | `× sqrt(num_refs)` | `repomap.py:512` |

The `sqrt` is explicitly to stop high-frequency low-value mentions dominating
(comment at `repomap.py:511`). The "defined in >5 files ⇒ ×0.1" rule is a **cheap
inverse-document-frequency**: it demotes names that are too common to be discriminative.
That single line is most of why the map does not fill up with `__init__`, `run`, `name`.

**Personalization** (`repomap.py:374`, `383`, `422-445`). `personalize = 100 / len(fnames)`
(`repomap.py:383`). A file gets `+personalize` if it is in the chat (`repomap.py:424-426`),
`max(current, personalize)` if it was named in the message (`repomap.py:428-430`), and a
further `+personalize` if any path component or basename (with or without extension)
matches a mentioned identifier (`repomap.py:433-442`). Personalization is passed to PageRank
as **both** `personalization=` and `dangling=` (`repomap.py:519-522`) — so rank leaked by
dead-end nodes also flows back to the user's focus, not uniformly.

**PageRank call.** `ranked = nx.pagerank(G, weight="weight", **pers_args)`
(`repomap.py:525`). On `ZeroDivisionError` it retries without personalization, then gives up
and returns `[]` (`repomap.py:526-531`) — a known issue (#1536 cited inline).

**From file rank to symbol rank — the step people miss.** PageRank ranks *files*. Aider then
**redistributes each file's rank across its outgoing edges in proportion to edge weight**
(`repomap.py:533-545`):

```
data["rank"] = src_rank * data["weight"] / total_weight
ranked_definitions[(dst, ident)] += data["rank"]
```

So the final ranked unit is a `(defining_file, identifier)` pair, scored by how much
importance flows into that definition from its referencers. That is the real output:
**a ranked list of definitions**, sorted at `repomap.py:548-550`. Files already in the chat
are skipped (`repomap.py:556-557`) — the map is explicitly the *complement* of what the
model already has verbatim. Files with no tags are appended at the tail in plain rank order
(`repomap.py:560-572`).

### 2.3 Token budget enforcement — binary search over list prefix

`get_ranked_tags_map_uncached` (`repomap.py:629-706`). Aider does not estimate and truncate;
it **binary-searches the prefix length** of the ranked-tag list against a rendered token
count:

- initial probe `middle = min(int(max_map_tokens // 25), num_tags)` (`repomap.py:676`) —
  the `// 25` is an implicit "≈25 tokens per rendered tag" prior;
- each iteration renders `to_tree(ranked_tags[:middle], ...)` and counts tokens
  (`repomap.py:686-687`);
- accept if under budget and better than the best so far, **or** if within 15% relative
  error (`ok_err = 0.15`, `repomap.py:689-696`) — it stops early on "close enough";
- standard bisection on `lower_bound`/`upper_bound` (`repomap.py:698-703`).

Token counting is itself sampled for speed: for text ≥200 chars it tokenizes every
`num_lines // 100`-th line and scales linearly (`repomap.py:89-101`). So the budget is
approximate by construction, twice over.

**Budget default and scaling.** `map_tokens=1024` default (`repomap.py:48`). Model-derived:
`get_repo_map_tokens` = `clamp(max_input_tokens / 8, 1024, 4096)` (`aider/models.py:782-789`).
When **no files are in the chat**, the budget is multiplied by `map_mul_no_files=8`
(`repomap.py:56`, applied `repomap.py:124-133`), capped at
`max_context_window - 4096`. So first-contact on an unfamiliar repo deliberately gets a
**~8k–32k token map**, and focused work gets ~1k–4k. This is a directly transferable
insight: *the map budget should be inversely proportional to how much verbatim code is
already in context.*

### 2.4 Caching and invalidation

Two layers, both keyed on mtime:

- **Tags cache** — `diskcache.Cache` at `.aider.tags.cache.v{CACHE_VERSION}`
  (`repomap.py:43`, `CACHE_VERSION=3`/`4` at `repomap.py:35-37`). Key is the absolute
  filename; value is `{"mtime": ..., "data": [Tag,...]}` (`repomap.py:258`). A hit requires
  `val.get("mtime") == file_mtime` (`repomap.py:246`), so **any file edit invalidates only
  that file's tags**. SQLite failures degrade to an in-memory dict rather than erroring
  (`repomap.py:177-215`) — the cache is treated as optional.
- **Map cache** — in-memory `self.map_cache` keyed on
  `(chat_fnames, other_fnames, max_map_tokens)` plus, in `refresh="auto"` mode,
  `(mentioned_fnames, mentioned_idents)` (`repomap.py:586-597`). Refresh policy
  (`repomap.py:599-613`): `manual` returns `last_map` forever; `always` never caches;
  `files` always caches; `auto` caches **only if the last computation took >1.0 s**
  (`repomap.py:609`) — a self-tuning "cache only when it hurt".
- Rendered-tree caches keyed by `(rel_fname, lois, mtime)` (`repomap.py:710-746`).

Note `save_tags_cache` is a no-op (`repomap.py:224-225`) — diskcache persists on write.

**The important invalidation fact for section 3:** aider's map is *never* a materialized
artifact on the model's side. It is recomputed per request and injected as a synthetic
user/assistant message pair (`base_coder.py:750-761`). Staleness is bounded by mtime, and
the map is regenerated when the *question* changes, not just when the code changes.

### 2.5 What the output actually looks like

Rendering is `to_tree` (`repomap.py:748-784`) over `grep_ast.TreeContext` configured with
`line_number=False, child_context=False, last_line=False, margin=0, mark_lois=False,
loi_pad=0, show_top_of_file_parent_scope=False` (`repomap.py:725-737`). It prints the
file path, then the **lines of interest** (the definition lines) with `⋮...` elisions
between them, and truncates every line to 100 chars to survive minified files
(`repomap.py:782`). Verified sample, `aider/website/docs/repomap.md:37-69`:

```
aider/coders/base_coder.py:
⋮...
│class Coder:
│    abs_fnames = None
⋮...
│    def run(self, with_message=None):
⋮...
```

Also injected: "important" root files (README, CI config, manifests) are prepended
unconditionally via `filter_important_files` (`repomap.py:657-662`, list at
`aider/special.py:150-193`), so the map always carries project-shape signals even at low
budget.

### 2.6 How the question enters the ranking

`base_coder.py:709-748`. `mentioned_idents` is just `re.split(r"\W+", text)` over the
current message — **every word the user typed** (`base_coder.py:678-682`). `mentioned_fnames`
comes from file-mention detection plus identifier↔filename stem matching for stems of length
≥5 (`base_coder.py:684-707`). Three-stage fallback if the map comes back empty: scoped →
whole-repo-with-hints → whole-repo-unhinted (`base_coder.py:724-746`).

This is worth stating plainly: **aider's ranking is query-conditioned**. It is not a static
"importance" view of the repo. That is exactly the property a persistent artifact cannot
have.

---

## 3. Does OMP subsume the repo-map? — honest verdict

### 3.1 Where the spec is right

`spec/07-retrieval-and-code-understanding.md:111-124` rejects a *persistent artifact* on
three grounds: it goes stale, it costs tokens whether needed or not, and it duplicates
`lsp symbols`. Two of those three are correct and are in fact **confirmed by aider's own
design**:

- Aider itself does not persist a map artifact — it recomputes per request, keyed partly on
  the current message (`repomap.py:586-597`). The spec's anti-staleness instinct matches
  upstream behaviour.
- Aider's budget is *query-conditioned and context-conditioned* (`repomap.py:124-133`), i.e.
  it also refuses to pay a fixed cost. Same instinct.

So: **rejecting a checked-in `REPO-MAP.md` is correct, and I would not overturn it.**

### 3.2 Where the spec is too glib

The spec says `lsp symbols` and `ast_grep` "produce structural summaries on demand for
exactly the scope in question" and therefore "duplicate what `lsp symbols` computes"
(`spec/07-retrieval-and-code-understanding.md:115-119`). This conflates **enumeration** with
**ranking**, and the conflation is not harmless.

What OMP's `lsp` provides, per its own tool prompt (`src/prompts/tools/lsp.md:9`):
`symbols` — `file` lists file symbols; `file: "*"` + `query` searches workspace. That is
enumeration and name search. `references` (`lsp.md:15-16`) gives you the callers of one
symbol you already named.

Neither answers aider's actual question, which is: **"of the ~40,000 symbols in this repo
that I have not read, which 30 definitions matter most for this task?"** Answering that
requires (a) a global reference graph, (b) centrality over it, (c) query personalization,
(d) IDF-style demotion of ubiquitous names, (e) a budgeted cut. OMP has none of these as a
primitive:

- `lsp symbols file:"*" query:X` requires you to **already know X**. Aider's map is what you
  use when you don't.
- `lsp references` is per-symbol and single-hop. Computing centrality with it would require
  O(symbols) tool calls — a token catastrophe, and each result enters context.
- `ast_grep` matches syntactic patterns; it does not rank. **[NOT READ THIS PASS: I did not
  read `src/tools/ast-grep.ts`, so I cannot rule out an undocumented ranking/summary mode.
  This should be checked before the spec text is finalized.]**
- The Explorer's "ranked evidence" (`spec/07:121`) is ranked by an **LLM's judgement after
  reading things**, which is precisely the expensive path the ranking is supposed to avoid.
  Calling that "the repository map" is a rhetorical move, not an equivalence.

**Honest verdict:** the spec's *conclusion* (no persistent artifact) is right; its *argument*
(`lsp symbols` computes the same thing) is wrong and should be rewritten. The capability gap
is real and specific: **OMP has no graph-centrality ranking over the symbol-reference graph,
and no cheap way to synthesize one from `lsp`/`ast_grep` calls.**

### 3.3 Cheapest OMP-native path to the ranking benefit

A `.omp/tools/*` custom tool is permitted, and OMP's custom-tool API supports exactly this
shape: `exec` for subprocesses, arktype/zod schemas, and a deterministic `execute` returning
an `AgentToolResult` (`_research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/custom-tools/types.ts`,
`CustomToolAPI` with `exec`/`logger`, and `CustomToolContext`).

Proposal — **`repo_rank`**, a deterministic, ephemeral, in-process ranking tool:

- **Input:** `query` (free text — the task statement), `focus` (optional file list already in
  context), `budget_tokens` (default 1200).
- **Algorithm:** port aider's `get_ranked_tags` faithfully — file-node multigraph, the six
  weight multipliers (`repomap.py:487-514`), personalization from `query` tokens
  (`repomap.py:422-445`), PageRank, then rank redistribution to `(file, ident)` pairs
  (`repomap.py:533-545`), then a prefix cut to `budget_tokens`.
- **Tag source:** `ast_grep`-equivalent tree-sitter parsing in-process, or shell out to
  `ast-grep`. Aider's own Pygments fallback (`repomap.py:338-363`) proves reference
  extraction does **not** need semantic accuracy for centrality to be useful — a crucial
  cost result. Do **not** call LSP per symbol.
- **Cache:** mtime-keyed under `.omp/cache/` (aider's exact scheme, `repomap.py:246`), never
  committed, never auto-injected.
- **Critical constraints that keep the spec's rejection intact:** (1) the output is a tool
  *result*, so OMP compaction owns it (`supersedeReads`/`shake` apply); (2) it is **pull, not
  push** — nothing is injected into any system prompt; (3) no artifact is written that an
  agent must keep synchronized; (4) it is available to the Explorer only, at first contact.

This satisfies the spec's three objections (not stale — recomputed; not always-paid —
explicitly invoked; not duplicative — it computes something `lsp symbols` provably does not)
while capturing the ranking benefit. **Estimated cost: ~1,200 tokens per invocation**
(basis: aider's default `map_tokens=1024` at `repomap.py:48`, plus framing overhead; the
tool's own compute is out-of-context CPU, not tokens).

Recommended spec edit: keep contract item 5 ("no persistent repository-map artifact") but
replace section D's reasoning, and add: *"a deterministic, non-persistent ranking tool is
permitted, because ranking is a capability OMP lacks; enumeration is not ranking."*

---

## 4. Serena — operations vs raw LSP; verdict on reject-010

**Depth disclosure:** I indexed `src/serena/tools/symbol_tools.py` by class and method line
but did not read the bodies. Setup-cost quantification below is **[NOT READ THIS PASS]** and
must be measured before reject-010 is revisited.

Verified tool surface (`_research/upstreams/serena/src/serena/tools/symbol_tools.py`):

| Serena tool | line | OMP equivalent | Genuinely new? |
|---|---|---|---|
| `GetSymbolsOverviewTool` (`relative_path`, `depth`, `max_answer_chars`) | `symbol_tools.py:36,43` | `lsp symbols file:<path>` (`lsp.md:9`) | No — but `depth` + `max_answer_chars` are budget controls OMP's prompt does not document |
| `FindSymbolTool` | `symbol_tools.py:134,144` | `lsp symbols file:"*" query:` (`lsp.md:9`) | No |
| `FindReferencingSymbolsTool` | `symbol_tools.py:252,260` | `lsp references` (`lsp.md:15`) | No |
| `FindImplementationsTool` | `symbol_tools.py:342,348` | `lsp request` raw (`lsp.md:11`) | Marginal — OMP can do it via raw request |
| `FindDeclarationTool` | `symbol_tools.py:399,404` | `lsp definition` (`lsp.md:15`) | No |
| `GetDiagnosticsForFileTool` | `symbol_tools.py:482,489` | `lsp diagnostics` (`lsp.md:8`) | No |
| `GetDiagnosticsForSymbolTool` | `symbol_tools.py:536,541` | — | Minor: symbol-scoped diagnostics |
| `ReplaceSymbolBodyTool` | `symbol_tools.py:585,590` | `ast_edit` / `edit` | Different mechanism, same outcome |
| `InsertAfterSymbolTool` / `InsertBeforeSymbolTool` | `symbol_tools.py:618,644` | `ast_edit` | No |
| `RenameSymbolTool` | `symbol_tools.py:670,676` | `lsp rename` (`lsp.md:5`) — OMP also has `rename_file` with import rewriting (`lsp.md:7`), which serena lacks | **OMP is ahead here** |
| `SafeDeleteSymbol` | `symbol_tools.py:698` | — | Genuinely absent from OMP |
| `RestartLanguageServerTool` | `symbol_tools.py:25,28` | `lsp reload` (`lsp.md:10`) | No |

There is also a `memory_tools.py` (`122` lines) — memory is rejected independently
(reject-005, reject-015), so that half of serena's value proposition is unavailable to this
project by prior decision.

**Two honest observations.** (1) Serena's real differentiator is *ergonomic framing* —
name-path symbol addressing and explicit answer-size caps (`max_answer_chars`) — plus
symbol-level editing. Almost nothing in the retrieval column is information OMP's `lsp`
cannot obtain. (2) OMP's `rename_file` (moves a file *and* rewrites all imports,
`lsp.md:7`) has no serena counterpart, so adopting serena would be a net *loss* on refactor
capability.

**Verdict on reject-010: UPHELD, and the reasoning strengthens.** Serena is a second MCP
retrieval engine whose retrieval operations are a near-subset of OMP's `lsp`. The
`condition_to_revisit` ("post-v0 when a specific retrieval failure case is documented") is
the right gate. The one credibly missing primitive is `SafeDeleteSymbol`
(`symbol_tools.py:698`) — if that becomes a real need, it is a `.omp/tools/*` script over
`lsp references`, not a reason to adopt serena.

*Note:* serena does **not** provide aider-style graph ranking either. Adopting serena would
not close the gap identified in section 3.

---

## 5. Repomix — bounded modes; verdict on reject-011

**[NOT READ THIS PASS — repomix source was not opened. This section is reasoning from the
registry entry and prior knowledge only, and must be verified before it is cited as fact.]**

What I can state as verified: nothing from the repomix source.

What the registry asserts (`registry/rejected-mechanisms.yml:77-82`): full dumps cost
20,000–200,000 tokens, violate the context-budget policy, and repomix is permitted only for
onboarding, architecture audits, and external reviews.

What remains to be verified (the actual open question):
- whether repomix's `--compress` / tree-sitter signature-extraction mode produces a bounded
  output, and whether the bound is *configurable* or merely *smaller*;
- whether it has any token-budget enforcement comparable to aider's binary search
  (`repomap.py:677-703`) — my strong prior is **no**, and if so that is the decisive
  difference: repomix compresses, aider *budgets*;
- measured compressed size on a mid-size repo.

**Provisional verdict on reject-011: UPHELD as written, with one refinement to test.** The
registry already permits onboarding/audit use, which is the correct scope. The refinement:
if repomix's compressed mode has no hard token ceiling, then even in onboarding it is
strictly worse than the section-3 `repo_rank` proposal, which does have one. Onboarding is
exactly the case where aider *raises* its budget 8× (`repomap.py:56,124-133`) rather than
abandoning the budget concept — so "unbounded is fine for onboarding" is not a conclusion
aider supports. **Measurement required.**

---

## 6. Context7 — token profile and placement; verdict on reject-012

**[NOT READ THIS PASS — context7 source was not opened. No file:line citations available.
Treat this section as unverified reasoning.]**

Verified only: the spec's placement and its environment caveat.
`spec/07-retrieval-and-code-understanding.md:69-82` puts Context7 at retrieval level 4 of 5,
and records CR-18: Context7 availability depends on an MCP server being wired in, is not
guaranteed for every OMP session, and agents MUST NOT assume it is available.

**Stale citation corrected (round 6).** This dossier was written against a revision that
said levels are **gates, not preferences** and cited `spec/07:79` for it. That line is
**withdrawn** (CR-20, now `spec/07 §B-1`): it contradicted `spec/05 §D`, and "exhausted local
sources" has no falsifiable definition, so it was a gate satisfiable by asserting a sentence —
untestable by L2/L3. The operative rule is **default priority + bounded escalation + named
permitted skips, with the skip disclosed in the result**. This *strengthens* the Context7
argument below rather than weakening it: under exhaustion gates Context7 was reachable only
after ritual local search; under source fitness it is reachable directly when the question is
a version-or-docs-only question, which is exactly the gap §6 argues it fills.

Where it earns its cost (argued, not verified): the failure mode Context7 addresses is not
"I don't know this API" but "**I know a plausible-looking older version of this API**". Local
`node_modules` types answer the version question authoritatively *when the dependency is
vendored and typed*. Context7 earns its place precisely in the gap: dependency not vendored
locally, or docs-only behaviour (config keys, migration steps, deprecations) that types do
not encode. That is a narrow but real slot, and level 4 is the right slot.

**Verdict on reject-012: UPHELD.** Rejecting Context7 as *first-pass* is correct — local
types dominate on both cost and authority. The registry's `condition_to_revisit` already
notes it is placed at position 4. One addition I would make to the spec: because CR-18 makes
availability conditional, the doctrine table (section 7) must give every Context7 row a
**defined fallback**, not just an ordering. Token profile: **[UNMEASURED]**.

---

## 7. RETRIEVAL DOCTRINE

**Token estimates are estimates.** Basis for each is stated in the last column group.
Anchored where possible on read source: aider's default map budget of 1024 tokens
(`repomap.py:48`), its model-scaled ceiling of 4096 (`models.py:787`), its ~25-tokens-per-
rendered-tag prior (`repomap.py:676`), and its 8× no-files multiplier (`repomap.py:56`).
Everything else is an order-of-magnitude engineering estimate, **not measured in this
project**. All rows assume `read.summarize.enabled = true` (`spec/07:103`).

| # | Question type | Cheapest correct tool | Est. tokens | Failure mode if you use the cheaper tool | Escalate to |
|---|---|---|---|---|---|
| 1 | Where is symbol `X` defined? | `lsp definition` | 50–150 | `grep` returns comments, strings, same-named methods in unrelated classes; agent edits the wrong one | `lsp definition`, then ranged `read` |
| 2 | Who calls `X`? (blast radius before an edit) | `lsp references` | 200–800 | **`grep` misses dynamic/re-exported/shadowed callsites** (`lsp.md:16`); a "safe" rename silently breaks callers | `lsp references`; never trust grep here |
| 3 | Does this literal string / config key exist anywhere? | `grep` | 100–500 | `lsp` cannot answer — wrong tool entirely; returns nothing and the agent concludes "absent" | broaden `grep`; then `glob` for untracked/generated files |
| 4 | What does module `M` export? | `lsp symbols file:M` | 150–600 | whole-file `read` costs 5–20× and buries the answer | ranged `read` of the export block |
| 5 | **Which 30 definitions in this unfamiliar repo matter for task T?** | **no OMP primitive — see §3.3 `repo_rank`** | ~1,200 | `glob`+`read` sampling produces a **confidently wrong architectural model**; the agent picks the file with the most familiar *name*, not the most central one | `repo_rank`, else Explorer subagent with an explicit read budget |
| 6 | What files match this shape/layout? | `glob` | 50–200 | `bash ls` recursion is unbounded and unfiltered | `glob` with narrower pattern |
| 7 | What is this function's body? | `read` with line range | 200–800 | whole-file read; on a 2k-line file that is 15k+ tokens for 30 lines | full `read` only if short / being rewritten (`spec/07:105`) |
| 8 | All places matching a syntactic pattern (e.g. every `useEffect` with no deps array) | `ast_grep` | 300–1,500 | `grep` regex over syntax produces false positives and misses multi-line forms | `ast_grep`; then `lsp` per hit |
| 9 | Does the code currently compile / what is broken? | `lsp diagnostics` | 200–1,000 | reasoning-from-reading claims correctness without evidence | full build/test via `bash` (Verifier) |
| 10 | How do I call external library `L` at the pinned version? | local `node_modules` types via `lsp`/`read` (level 1) | 300–1,500 | **model recalls a plausible older API**; code looks right, fails at runtime | local docs (2) → bundled versioned docs (3) → Context7 (4) → web (5), per `spec/07:69-76`; **Context7 needs a fallback, CR-18** |
| 11 | Library not vendored, or behaviour is docs-only (config keys, migration) | Context7 (level 4) | **[UNMEASURED]** | levels 1–3 return nothing and the agent invents an answer | web (5) with mandatory source disclosure (`spec/07:80`) |
| 12 | First-contact orientation on a repo nobody has read | project `AGENTS.md` prose, then `repo_rank` / bounded repomix | 500 (AGENTS.md) → ~1,200–10,000 | reading 5 random files yields a wrong mental model that persists for the whole session | raise the map budget deliberately (aider's 8× rule, `repomap.py:56`) — **not** an unbounded dump |
| 13 | Is this behaviour actually reachable / who constructs this object? | `lsp references` + ranged `read` | 500–2,000 | grep-for-classname finds the type annotation, not the construction site | `lsp references` on the constructor |
| 14 | Cross-file rename | `lsp rename` / `rename_file` | 300–1,500 | `ast_edit`/`sed` **silently drops callsites** (`lsp.md:17`) | `lsp rename` only — this is stated as a prohibition upstream |

**Ordering rule that survives all rows:** *enumeration is cheap, ranking is not, and
semantics is not free.* Rows 2, 10, and 14 are the ones where the cheap tool returns
something that *looks like an answer*.

---

## 8. Where token optimization becomes a quality risk

Five specific places where the cheapest correct tool is not the cheapest tool, and the
failure is silent:

1. **`grep` substituting for `lsp references` (row 2).** The most dangerous substitution in
   the doctrine, because grep *returns results* — just the wrong set. OMP's own tool prompt
   states text renames "silently drop callsites" (`lsp.md:17`). Any token budget that pushes
   an agent from `lsp` to `grep` on a blast-radius question is buying tokens with
   correctness. **Mitigation:** this must be a rule, not a preference — which is why the
   LSP allowlist defect (`spec/07:17-49`) is a correctness bug, not an efficiency bug. An
   Explorer instructed to be "symbol first" (`spec/07:33`) but denied `lsp` will
   *substitute grep and not report the substitution*.
2. **Ranking absence masquerading as ranking presence (row 5, §3.2).** When no ranking tool
   exists, an agent asked "what matters here" will answer from filename plausibility and
   its own priors. The output is fluent and wrong. There is no error signal. This is the
   single strongest argument for §3.3, and the reason the spec's "the Explorer's ranked
   evidence *is* the repository map" (`spec/07:121`) is a risk: it relabels the failure mode
   as the solution.
3. **`read.summarize` on evidence-bearing reads.** Summarization is a real saving
   (`spec/07:103`) but it paraphrases. The Verifier's `read-summarize: false` is correct
   because "verification evidence must be exact output lines, not a paraphrase"
   (`spec/07:107`). The generalization: **any read whose output will be quoted as evidence
   must not be summarized.** A token-optimizer that turns summarization on globally
   converts verification into vibes.
4. **Version-plausible external API recall (rows 10–11).** Levels 1–3 being "cheap" makes
   skipping level 4 attractive. But an outdated-API answer is indistinguishable from a
   correct one until runtime. The gate framing (`spec/07:79`) handles the *downward*
   direction (don't skip to Context7); it does not handle the *upward* one (don't stop at
   level 1 when level 1 was silent rather than affirmative). **Proposed rule: a level may
   only terminate the search if it returned an affirmative answer, not merely no
   contradiction.**
5. **Compaction interacting with retrieval order.** `supersedeReads=true` means a re-read
   drops the earlier read. An agent that reads file A, reads file B, then re-reads A has
   lost nothing — but an agent whose *reasoning* referenced the first read of A now has a
   citation to content no longer in context. This is OMP's job and must not be
   reimplemented, but retrieval doctrine should prefer **one ranged read of the right lines**
   over **two reads of the same file**, for coherence reasons rather than token reasons.

---

## 9. Mechanism inventory

| Mechanism | Repo | file:line | OMP mapping | Verdict |
|---|---|---|---|---|
| tree-sitter tag extraction (def/ref) | aider | `repomap.py:279-336` | `ast_grep` (approx) | Adopt as input to `repo_rank` |
| Pygments reference backfill when query has defs only | aider | `repomap.py:338-363` | none | **Adopt the insight** — refs need not be semantically exact for ranking |
| File-node reference multigraph | aider | `repomap.py:470-514` | none | Adopt (§3.3) |
| Weight multipliers (mentioned ×10, long-identifier ×10, private ×0.1, >5-definers ×0.1, in-chat referencer ×50, `sqrt(refs)`) | aider | `repomap.py:487-514` | none | Adopt verbatim — this is the tuned core |
| PageRank with personalization **and** dangling=personalization | aider | `repomap.py:519-525` | none | Adopt |
| Rank redistribution file→`(file, ident)` | aider | `repomap.py:533-545` | none | Adopt — this is what makes output symbol-level |
| Exclude chat files from the map | aider | `repomap.py:556-557` | analogous to `supersedeReads` intent | Adopt as principle |
| Binary search prefix to token budget, 15% tolerance | aider | `repomap.py:677-703` | none | Adopt |
| Sampled token counting (every `n/100`-th line) | aider | `repomap.py:89-101` | none | Optional perf trick |
| Budget = clamp(ctx/8, 1024, 4096) | aider | `models.py:782-789` | — | Adopt as sizing rule |
| 8× budget when no files in chat | aider | `repomap.py:56,124-133` | — | **Adopt** — first-contact gets a bigger map, still bounded |
| mtime-keyed tags cache, dict fallback | aider | `repomap.py:233-264,177-215` | `.omp/cache/` | Adopt |
| Cache-only-if-slow (`>1.0s`) refresh policy | aider | `repomap.py:609` | — | Adopt |
| Always-include important root files | aider | `repomap.py:657-662`; `special.py:184-193` | `glob` | Adopt as principle |
| Query-conditioned personalization from message tokens | aider | `base_coder.py:678-682,709-748` | tool `query` arg | Adopt |
| `⋮...`-elided signature rendering | aider | `repomap.py:748-784`; sample `docs/repomap.md:37-69` | — | Adopt as output format |
| `get_symbols_overview` with `depth`/`max_answer_chars` | serena | `symbol_tools.py:36,43` | `lsp symbols` | Reject tool; **adopt the answer-size cap idea** |
| `find_symbol` name-path matching | serena | `symbol_tools.py:134,144` | `lsp symbols file:"*"` | Reject — subsumed |
| `find_referencing_symbols` | serena | `symbol_tools.py:252,260` | `lsp references` | Reject — subsumed |
| `find_implementations` | serena | `symbol_tools.py:342,348` | `lsp request` (raw) | Reject — reachable |
| symbol-level edits (`replace_symbol_body`, `insert_after/before`) | serena | `symbol_tools.py:585,618,644` | `ast_edit` | Reject — subsumed |
| `rename_symbol` | serena | `symbol_tools.py:670,676` | `lsp rename` (+ `rename_file`, which serena lacks) | Reject — OMP ahead |
| `SafeDeleteSymbol` | serena | `symbol_tools.py:698` | none | **Genuine gap** — `.omp/tools/*` if ever needed |
| serena memory tools | serena | `memory_tools.py` (122 lines) | — | Reject (reject-005/015) |
| repomix compression mode | repomix | **[NOT READ THIS PASS]** | — | Unverified; measure |
| Context7 versioned doc lookup | context7 | **[NOT READ THIS PASS]** | MCP, level 4 | Uphold reject-012 |

---

## 10. Open questions requiring measurement

1. **Does `ast_grep` in OMP have any ranking or summary mode?** I did not read
   `src/tools/ast-grep.ts` (526 lines). If it does, §3 needs revision. **Highest-priority
   gap.**
2. **Cost of `repo_rank` on a real repo.** Wall-clock for tag extraction + PageRank on a
   ~50k-file repo, and actual rendered token count at `budget=1200`. Aider warns its own
   initial scan is slow and can hit `RecursionError` on large repos
   (`repomap.py:143-146`, `391-395`).
3. **Does the ranking actually change outcomes?** The measurable claim: on N unfamiliar-repo
   tasks, compare tokens-per-accepted-outcome for Explorer-with-`repo_rank` vs
   Explorer-with-`glob`+`read`. If ranking does not reduce tokens per *accepted* outcome, §3.3
   should be dropped and the spec's rejection stands unamended.
4. **Repomix compressed-mode token profile**, and whether it has any hard ceiling
   (see §5).
5. **Context7 token profile per lookup**, and its availability rate in real sessions (CR-18,
   `spec/07:82`). Without this, level 4 is unbudgeted.
6. **How often does `grep` silently disagree with `lsp references`?** Sample real symbols;
   measure precision/recall of grep against LSP ground truth. This quantifies risk #1 in §8
   and tells us how hard the prohibition must be.
7. **Is the "affirmative answer required to terminate" rule (§8.4) enforceable?** It needs
   an observable signal distinguishing "level 1 said no" from "level 1 said nothing".
8. **Does aider's Pygments-grade reference extraction (`repomap.py:338-363`) rank well enough
   in practice?** If yes, `repo_rank` never needs LSP and stays cheap. This is the load-
   bearing assumption of the whole §3.3 proposal.
