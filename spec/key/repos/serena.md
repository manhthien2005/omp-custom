# Repo Report — serena

> **Path:** `_research/upstreams/serena`
> **SHA:** `c7af2c09ef45faa4367c0e2a9f770fb73a62a612` (`git -C serena rev-parse HEAD`)
> **License:** MIT. `LICENSE:1-5` — "MIT License / Copyright (c) 2025 Oraios AI". Confirmed a
> second time by an in-file grant: `pyproject.toml:69-70` declares `[project.license] text = "MIT"`.
> Both agree; no dual-license or ambiguity.
> **Size:** 1,017 tracked files (`git ls-files | wc -l`)
> **Read this pass:** `src/serena/tools/symbol_tools.py` (739 lines, full), `memory_tools.py` (full),
> `workflow_tools.py` (full), `tools_base.py:278-340`, `src/solidlsp/util/cache.py` (full),
> `src/solidlsp/ls.py:2925-3114` and the cache-constant block `:342-372`, `src/serena/cli.py:800-844`,
> `src/serena/symbol.py:380-480`, `resources/config/contexts/claude-code.yml` (full),
> `resources/config/modes/no-memories.yml` (full),
> `resources/config/prompt_templates/simple_tool_outputs.yml:1-42`, the on-disk `.serena/memories/*`.
> Class-level enumeration of all tool classes across all 9 tool modules via grep.

---

## 1. What this repo is

Serena is a **whole MCP server plus a vendored LSP client library** (`solidlsp`, ~70 language-server
adapters) that gives an agent symbol-level read and edit tools over a codebase. Its thesis is that
an agent should navigate code by *symbol name path* (`MyClass/my_method`), not by line offsets or
regex, and that this is more token-efficient than reading whole files.

Two separable artifacts live here: (a) `solidlsp`, a synchronous facade over async LSP with a
persistent symbol cache; (b) the Serena tool layer — a deliberately designed symbol-aware toolset
plus a memory/onboarding system. As a runtime it is out of scope for us by constraint. The tool
*surface design* is the thing worth reading, and it is the best-designed one in the retrieval
cluster.

---

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| 1 | **Name-path symbol addressing** | Symbols addressed as a path *within a file*: `MyClass/my_method`. Supports suffix match (`class/method`), absolute (`/class/method`), and overload index (`MyClass/my_method[1]`). This is the keystone: every symbolic read and edit tool takes a `name_path`. | `symbol_tools.py:162-172` | **A** |
| 2 | `get_symbols_overview` | Top-level symbols of one file, grouped by kind. Explicitly documented as "the first tool to call when you want to understand a new file". Default depth is language-specific: 1 for `.java`/`.kt`, 0 otherwise. | `symbol_tools.py:36-91`, depth logic `:59-63` | **A** |
| 3 | `find_symbol` | Global or path-scoped symbol search by name-path pattern. Flags: `depth`, `include_body`, `include_info` (hover/docstring), `include_kinds`/`exclude_kinds` (LSP `SymbolKind` ints), `substring_matching`, `max_matches`. | `symbol_tools.py:134-249` | **A** |
| 4 | `find_referencing_symbols` | Reverse references to a symbol, each annotated with the *containing symbol* and ±1 line of surrounding code. Deliberately never includes referencing bodies: "It is probably never a good idea to include the body of the referencing symbols". | `symbol_tools.py:252-339`, body decision `:283` | **A** |
| 5 | `find_implementations` | Implementations of an interface/abstract symbol. | `symbol_tools.py:342-396` | **A** |
| 6 | `find_declaration` | Go-to-definition addressed by a **regex with one capture group** rather than line:col — the agent describes the call site textually and Serena resolves coordinates. `find_text_coordinates(..., require_unique=True)`. | `symbol_tools.py:399-465`, regex contract `:416-419` | **A** |
| 7 | `replace_symbol_body` / `insert_after_symbol` / `insert_before_symbol` | Symbol-scoped edits with no line arithmetic. Each carries a usage guard: replace warns "Only replace symbol bodies if you have previously made a retrieval with `include_body=True`"; insert-after warns "Don't use to insert after assignments". | `symbol_tools.py:585-667`, guards `:599`, `:631` | **A** |
| 8 | `rename_symbol` / `safe_delete_symbol` | LSP-backed rename across the codebase. Safe-delete **refuses and returns the reference list** rather than deleting when references exist. | `symbol_tools.py:670-738`, refusal `:734-735` | **A** |
| 9 | **Post-edit diagnostics as a return value** | Every editing tool subclasses `EditingToolWithDiagnostics` and wraps the edit in a `DiagnosticsContext`, so the tool's return string carries the LSP diagnostics the edit caused. The agent learns it broke the build from the edit's own result — no separate check turn. | `symbol_tools.py:608-615` (pattern), base `tools_base.py` class `EditingToolWithDiagnostics` | **A** |
| 10 | `get_diagnostics_for_file` / `..._for_symbol` | Diagnostics grouped `path → severity → name_path → diagnostics`; unmappable ones bucketed under the literal `<file>`. Symbol variant can optionally follow references (`check_symbol_references`). | `symbol_tools.py:482-582`, bucket `:487` | **A** |
| 11 | **Progressive-degradation answer shortening** | `_limit_length` takes a list of `shortened_result_factories` closures tried in order until one fits the char cap. `find_referencing_symbols` ships three tiers: refs-without-context → per-file counts → bare count. Cap default 150,000 chars. | `tools_base.py:281-311`, tiers `symbol_tools.py:324-336`, cap `config/serena_config.py:903` | **A** |
| 12 | **Two-layer persistent symbol cache** | Pickled to `<project>/.serena/cache/<language_id>/`: `raw_document_symbols.pkl` (LS response) + `document_symbols.pkl` (parsed). Per-file key, value `(content_hash, symbols)`. | `ls.py:348-366`, dirs `:550-562`, save/load `:2970-3101`, pickle helper `solidlsp/util/cache.py:9-23` | **A** |
| 13 | **Content-hash invalidation, not mtime** | Cache entry is stale when the file's `content_hash` differs, so a touch-without-change is a hit. Plus a *global* version tuple `(class constant, LS-specific version, fingerprint)`; a mismatch discards the whole file. Corrupt pickle → warn and ignore, never crash. | hash check `ls.py:1864-1878`, version tuple `:2955-2968`, `:3011-3016`, corruption `:3055-3061` | **A** |
| 14 | **Cache-version fingerprint hooks** | Two overridable hooks — `_raw_document_symbols_cache_fingerprint` (LS config/build flags changed) and `_document_symbols_cache_fingerprint` (our parsing changed) — so a language adapter can invalidate its own slice without bumping a global constant. Explicit maintainer instructions in the docstrings. | `ls.py:2932-2953`, `:2988-3009` | **A** |
| 15 | Offline `serena project index` | Walks `gather_source_files()` and calls `request_document_symbols` per file with a per-file timeout (CLI default 10s), saving caches every 30s, logging failures to `.serena/logs/indexing.txt` and **continuing**. | `cli.py:802-843`, periodic save `:827-830`, continue-on-fail `:823-826` | **A** |
| 16 | ~70 language-server adapters | `src/solidlsp/language_servers/` holds 70 `.py` adapters; `LanguageServerId` enum has ~69 members. | `ls -1 src/solidlsp/language_servers/*.py \| wc -l` = 70; `ls_config.py:90` | **A** |
| 17 | Multi-LS composition by repo makeup | Detects language composition of the repo and sorts candidate language servers by `(percentage, configured priority)` descending. Per-file routing then picks the right LS. | `config/serena_config.py:364-387`, per-file routing `cli.py:820` | **A** |
| 18 | LSP-unavailable degradation is **refusal, not fallback** | `get_symbol_overview` raises if `can_analyze_file` is false, naming the active language servers. There is no regex fallback inside the symbolic tools. The regex path is a *separate* tool (`search_for_pattern`). | raise `symbol_tools.py:108-111`, predicate `symbol.py:728`, separate tool `file_tools.py:544-571` | **A** |
| 19 | Memory tools (6) | `write/read/list/delete/rename/edit_memory`. Markdown files under `.serena/memories/`, `/`-separated topics, `global/` prefix for cross-project. Cross-references written as `` `mem:auth` ``. | `memory_tools.py:9-123`, ref syntax `:20-21` | **A** |
| 20 | `rename_memory` propagates references | Renaming rewrites `mem:`-prefixed references in other memories and reports the count. Not a bare file rename. | `memory_tools.py:74-91` | **A** |
| 21 | Memory-reference integrity analysis | A 38 KB module detects dangling `mem:` references and proposes the likely intended target via a name-similarity score with a threshold and a `MAX_STALE_REFERENCE_CANDIDATES` cap. Surfaced as a CLI check (`serena memories check`). | `memories/memory_reference_analysis.py:5`, `:105-193`, `:288`; CLI hint `simple_tool_outputs.yml:37-38` | **A** |
| 22 | Onboarding = a **prescribed memory schema** | `onboarding` returns a prompt naming five memories to write: `core`, `tech_stack`, `suggested_commands`, `conventions`, `task_completion`, plus `mem:<module>/core` for distinct modules. Not "write what you learned". | `workflow_tools.py:10-29`, schema `simple_tool_outputs.yml:15-32` | **A** |
| 23 | Onboarding self-checks and bounds itself | Returns "Memory writing tool not activated, skipping onboarding" if `write_memory` is not exposed; instructs "Read only the files needed; do not load entire directory trees"; and refuses to count chat summaries as done. | guard `workflow_tools.py:22-24`, bound `simple_tool_outputs.yml:34-35`, `:40-41` | **A** |
| 24 | Memory size cap enforced at write | `write_memory` raises if content exceeds `max_chars` (default = `default_max_tool_answer_chars` = 150,000) rather than truncating. | `memory_tools.py:28-33`, default `serena_config.py:903` | **A** |
| 25 | Memories are **pull-only** | No tool injects memories into context. `list_memories` returns names; `read_memory`'s docstring tells the agent to infer relevance "e.g. from the name". Cost is opt-in per read. | `memory_tools.py:43-47`, `:50-59` | **A** |
| 26 | `no-memories` / `no-onboarding` modes | First-class configs that exclude the entire memory toolset by name. Serena itself treats memory as optional. | `modes/no-memories.yml:1-11` | **A** |
| 27 | Per-host context configs (16) | `contexts/*.yml` tailor the exposed toolset per host. `claude-code.yml` excludes 6 tools that the host already provides (`read_file`, `execute_shell_command`, `find_file`, `list_dir`, `search_for_pattern`, `create_text_file`) and sets `single_project: true` to further trim. | `contexts/claude-code.yml:36-52`, `ls contexts/` = 16 files | **A** |
| 28 | Anti-preference prompting | `claude-code.yml` contains an explicit *disallowed-reasoning* list — the agent may not justify a `Read` with "I already know the path", "one Read call is faster than three Serena calls", or "the built-in tool description says to use Read". | `contexts/claude-code.yml:30-34` | **A** |
| 29 | Tool markers as a capability type system | `ToolMarkerSymbolicRead`, `ToolMarkerSymbolicEdit`, `ToolMarkerCanEdit`, `ToolMarkerOptional`, `ToolMarkerBeta`, `ToolMarkerDoesNotRequireActiveProject`. Toolsets are computed from marker membership. | class list across `tools/*.py`; `is_symbolic()` `tools_base.py:319-320` | **A** |
| 30 | Parameter aliasing for schema drift | `get_param_aliases()` maps an old param name to the new one (`name_path` → `name_path_pattern`) so a renamed parameter does not break agents that learned the old schema. | `tools_base.py:322-328`, use `symbol_tools.py:247-249` | **A** |
| 31 | JetBrains IDE tool track (13 tools) | A parallel toolset backed by an IDE rather than LSP: adds `move`, `safe_delete`, `inline_symbol`, `type_hierarchy`, `run_inspections`, `debug`. All `ToolMarkerOptional`; refactorings `ToolMarkerBeta`. | `jetbrains_tools.py` class list | **A** |
| 32 | **No ranking anywhere** | `grep -niE "\brank\|\bscore\|centrality\|pagerank\|importance\|prioriti"` over `src/serena/` + `src/solidlsp/` returns only: LS *priority* config, memory-name *similarity* scoring, and a comment in `eclipse_jdtls.py` saying completion ranking is deliberately unused. Zero hits on the symbol graph. | grep result; LS priority `serena_config.py:364-387`; name similarity `memory_reference_analysis.py:105-193`; declined ranking `eclipse_jdtls.py:1331` | **A** |
| 33 | Call hierarchy is wired but **not exposed** | `callHierarchy/incomingCalls` and `outgoingCalls` exist in the protocol layer and are advertised in ~7 adapters' client capabilities, but no `Tool` class calls them. The call graph is reachable and unused. | protocol `lsp_protocol_handler/lsp_requests.py:104-128`; capabilities e.g. `rust_analyzer.py:355`; no tool consumer (grep of `tools/`) | **A** |

---

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| #11 Progressive-degradation shortening (tiered fallbacks, not truncation) | Worker-agent output contract in the 4 worker agents; any command that returns a large tool result | `zero` (prose in an agent file we already pay for) | **ADOPT** | The strongest craft finding here. An over-budget result today either truncates (agent loses the tail silently) or floods. Serena's answer — try refs-without-context, then per-file counts, then a bare count — keeps the result *actionable* at every tier. Directly reduces tokens per accepted outcome because the agent can refine instead of re-querying blind. |
| #1 Name-path symbol addressing as the citation format | The `file:line` convention already used across spec and worker reports; OMP `lsp` symbol output | `zero` | **ADAPT** | Adopt the *notation* (`MyClass/my_method`, `[i]` for overloads), not the resolver. Stable under edits above the symbol, where `file:line` is not. Cheap because it is a writing convention. |
| #7/#8 Usage guards and refusal-with-evidence on edit tools | Worker-agent instructions for the editing worker | `zero` | **ADOPT** | Two concrete rules: (a) never replace a symbol body you have not read with bodies included; (b) on a delete, return the reference list instead of deleting. Both are prose, both prevent a class of retry loop. |
| #9 Diagnostics returned by the edit itself | Post-edit step in the editing worker's loop, using OMP's existing `lsp` diagnostics | `per-action` (only the diagnostics text, only on edits) | **ADAPT** | We already verify after changes. The craft is *co-locating* the check with the edit so a broken edit costs one turn, not two. Attaches to a verification step we already pay for. |
| #6 Regex-with-capture-group as a location argument | Any command that needs a call site located without stable line numbers | `zero` | **ADAPT** | Sidesteps stale-line-number failure. Requires `require_unique=True` semantics — ambiguous match must be an error, not a guess. Adopt as an argument convention where we hand-write locations. |
| #23 Onboarding that **bounds its own reads** and self-skips | Any onboarding/orientation command | `zero` | **ADAPT** | The transferable parts are the bound ("read only the files needed; do not load entire directory trees") and the precondition check. Not the memory writing. |
| #22 Prescribed memory *schema* if memory is ever revisited | `reject-015` revisit trigger | `lazy` (per read) | **DEFER** | **Trigger:** only if `reject-015` is reopened. Then the finding is that a fixed 5-slot schema with a size cap and pull-only access is a materially different proposition from open-ended autolearn — and it is what a deliberate designer chose. Not a proposal to adopt now. |
| #27 Host-aware tool exclusion | Not applicable — we do not own a tool surface | — | **REJECT** | We are the host's guest, not a tool provider. The *idea* (do not expose a tool the host already has) has no attachment point because we expose no tools. |
| #12–#15 Persistent pickled symbol cache | — | `persistent` (disk) + first-run wall-clock | **REJECT** | See §4. This is the priced alternative to our standing rule against persistent repo-map artifacts, and the price is high. |
| #32/#33 Ranking | — | — | **REJECT (nothing to adopt)** | Serena has no ranking to take. Recorded because its *absence* in the most deliberately designed symbol toolset available is evidence about OQ-G. |

---

## 4. What this repo does that we deliberately will not

**Adopt Serena itself.** It is an MCP server with 55+ tool classes, a vendored 70-adapter LSP
client, a web dashboard (`src/serena/resources/dashboard/`, including a bundled jQuery), an
analytics module, and a task executor. OMP is our only runtime. Not a close call.

**Persist a symbol index to disk.** Serena writes two pickles per language into
`.serena/cache/<language_id>/` (`ls.py:550-562`). Now that we have read the implementation, we can
state the *real* price of the artifact our rule forbids, and it is more than one file:

- **Format-version debt.** Two independent global version constants
  (`RAW_DOCUMENT_SYMBOLS_CACHE_VERSION = 1`, `DOCUMENT_SYMBOL_CACHE_VERSION = 4`, `ls.py:349`/`:359`)
  plus *two* per-adapter fingerprint hooks (`ls.py:2932`, `:2988`) exist solely to answer "is this
  pickle still meaningful?". `DOCUMENT_SYMBOL_CACHE_VERSION` has already reached 4.
- **A migration path in the load path.** `_load_raw_document_symbols_cache` still carries a legacy
  reader for `document_symbols_cache_v23-06-25.pkl` that rewrites and unlinks the old file
  (`ls.py:3022-3045`). A persistent artifact acquires migration code.
- **Corruption is a real, handled case.** Both loaders catch and warn: "cache can become corrupt,
  so just skip loading it" (`ls.py:3055-3061`, `:3090-3096`). The save path warns it "may have
  resulted in a corrupted cache file" (`ls.py:2982-2986`).
- **Pickle is the format.** `dump_pickle`/`load_pickle` (`solidlsp/util/cache.py:4`). Loading a
  pickle executes code in it, and the objects persisted are live class instances — `ls.py:304`
  notes "Instances of this class are persisted in the high-level document symbol cache", which
  couples the on-disk format to class layout.
- **First run is a bounded-failure batch job, not a lookup.** `serena project index` needs a
  per-file timeout (default 10s, `cli.py:753`), saves every 30s so a crash does not lose the run
  (`cli.py:827-830`), and expects failures — it collects them and writes
  `.serena/logs/indexing.txt` (`cli.py:835-841`). Serena's own repo has 199 tracked files under
  `src/`; a repo where a meaningful fraction of files each cost up to 10s of language-server work
  is a minutes-scale first run.

Two credits where they are due, because they are the parts we would need if we ever reversed the
rule: invalidation is by **content hash, not mtime** (`ls.py:1864-1878`), which is the correct
choice; and no token is ever paid for the cache — it is a latency artifact whose contents enter a
context only through a tool result. Our rule is about *context* cost, and this cache does not
violate that. It fails on maintenance surface and first-run cost instead. That is a different
argument than the one we have been making, and it is the honest one.

**Refuse rather than degrade when LSP is unavailable.** `get_symbol_overview` raises and names the
active language servers (`symbol_tools.py:108-111`). Coherent for Serena — the symbolic tools are
the product, and silently returning regex results would be a lie about precision. Wrong for us:
our worker agents must finish the task on whatever the repo is, so a degraded path has to exist.
Serena keeps the regex path as a *separate* tool (`search_for_pattern`, `file_tools.py:544`) and
`claude-code.yml` excludes it. We take the opposite branch deliberately.

**Prompt against the host's own tools.** `claude-code.yml:22-34` marks `Read` "FORBIDDEN for
discovery", `Edit` "FORBIDDEN", and enumerates three arguments the agent may not use to justify
them — including "one Read call is faster than three Serena calls". That argument is often *true*
on token count for a small file; Serena forbids it because its business is Serena usage. We will
not adopt an instruction whose effect is to increase tool calls for a known-path read. Worth
recording as an anti-pattern: an upstream's prompt can encode the upstream's interest.

---

## 5. Contradictions with our current spec or registry

**1. `reject-010`'s stated reason is not the strongest one available, and one clause is now wrong.**

> `registry/rejected-mechanisms.yml:73-76` — "OMP LSP + native search is sufficient for v0. Serena
> adds MCP dependency and setup complexity."

"MCP dependency and setup complexity" is true but weak — it would be answered by "then vendor the
algorithm". The verified reasons are stronger and different: Serena has **no ranking at all**
(mechanism #32), so it cannot close the gap `reject-010` is implicitly about; and its symbol layer
is inseparable from a 70-adapter vendored LSP client plus a two-pickle persistent cache with four
format-version knobs (§4). The verdict is right; the recorded reason under-argues it. Suggest the
reason be restated on those grounds — the current wording invites a future maintainer to "just
vendor the symbol tools", which the source shows is not a small action.

**2. `spec/README.md:225` groups Serena with repomix as "semantic retrieval".**

> "Repo-map / semantic retrieval (Serena, repomix) — deferred pending evidence"

Neither is semantic retrieval, and they are not the same kind of thing. Serena is **exact**
symbol lookup via LSP — name-path matching (`symbol.py:402-417`) and LSP reference requests, with
no embedding, no similarity, and no ranking over code (#32). repomix is deterministic
concatenation. Calling either "semantic" imports an expectation of relevance ordering that neither
delivers, and grouping them hides that Serena has a genuinely transferable *interface* while
repomix has a packing pipeline. This is the same enumeration/ranking conflation flagged in
`omp-ranking-capability-gap`, one level up: retrieval ≠ semantic retrieval.

**3. `dossiers/retrieval-cluster.md:14` and `29` are now superseded for serena.**

The dossier records serena as read "via grep" of `symbol_tools.py` only, with confidence "Low".
This report opens the tool layer, the cache implementation, the CLI index path, and the
context/mode configs. The dossier's *verdict* is unchanged; its confidence marker and the
"NOT READ THIS PASS" note should now point here.

**4. No recorded claim contradicts the memory findings, but the file count in the header does.**

`git ls-files | wc -l` returns **1,017**, matching the task brief. Recorded for the SHA pin. No
correction needed — noted only because §7 of the contract asks for it.

---

## 6. Cost profile

| §3 row | Where the token is paid | Amount | Basis |
|---|---|---|---|
| #11 Progressive shortening | `zero` marginal | ~10–15 lines in an agent file already loaded per-spawn | Serena's own instance is 3 closures (`symbol_tools.py:324-336`); ours is a rule, not code |
| #1 Name-path notation | `zero` | one sentence of convention | Notation only; no resolver |
| #7/#8 Edit guards | `zero` | 2–3 lines in the editing worker | Their versions are one-line docstring warnings (`symbol_tools.py:599`, `:631`) |
| #9 Diagnostics with the edit | `per-action` | Only the diagnostics text, only on edits that produce diagnostics. Grouped `path → severity → name_path` (`symbol_tools.py:498`) so a clean edit costs ~0 | **estimate.** Basis: OMP's `lsp` diagnostics output size, which we already pay for in verification today — this moves the cost, not adds it |
| #6 Regex-as-location | `zero` | argument convention | — |
| #23 Bounded onboarding | `zero` | 2 lines | — |
| #22 Memory schema (DEFER) | `lazy` per read, `zero` when unread | Serena's own memories total **26,308 bytes ≈ 6.5k tokens** across 9 files (`wc -c .serena/memories/*.md`, /4 chars-per-token); largest single file 11,948 B ≈ 3k tokens. Per-write cap is 150,000 chars ≈ 37k tokens (`memory_tools.py:28-33`) | Measured on disk. The cap is the number to be alarmed by: a single memory may legally reach ~37k tokens |
| Persistent cache (REJECTED) | `zero` context, non-zero everything else | Disk artifact; first run is minutes-scale with a 10s/file timeout; 2 version constants + 2 fingerprint hooks + a legacy migration path + corruption handling to maintain | `cli.py:753`, `:802-843`; `ls.py:349`, `:359`, `:2932`, `:2988`, `:3022-3045`, `:3055-3061` |

Note on the framing: the cache's cost is **not** a context cost. If we keep the standing rule
against persistent repository-map artifacts, this evidence supports it on maintenance-surface and
first-run grounds, not on token grounds. Stating it as a token argument would be false.

---

## 7. Coverage and limits

**Files read in full:**
- `src/serena/tools/symbol_tools.py` (739 lines)
- `src/serena/tools/memory_tools.py` (123 lines)
- `src/serena/tools/workflow_tools.py` (64 lines)
- `src/solidlsp/util/cache.py` (23 lines)
- `src/serena/resources/config/contexts/claude-code.yml` (56 lines)
- `src/serena/resources/config/modes/no-memories.yml` (11 lines)
- `src/serena/resources/config/prompt_templates/simple_tool_outputs.yml:1-42` (onboarding prompt)
- `LICENSE`, `repomix.config.json`-equivalent config surface for cache constants

**Files sampled (head/grep/range only):**
- `src/solidlsp/ls.py` (3,114 lines) — read `:342-372`, `:2925-3114`; grepped for cache/hierarchy.
  **The LSP request layer and the symbol-tree walk (`request_full_symbol_tree` `:2058`,
  `request_dir_overview` `:2210`, `request_overview` `:2263`) were located but not read.**
- `src/serena/symbol.py` (1,381 lines) — read `:380-480`; `LanguageServerSymbolRetriever` (`:579`)
  and its `find`/`find_referencing_symbols` (`:735`, `:810`) located but **not read**
- `src/serena/tools/tools_base.py` (28.7 KB) — read `:278-340` only
- `src/serena/cli.py` — read `:800-844` only
- `src/serena/config/serena_config.py` — grepped `:364-387`, `:903`
- `src/serena/memories/memory_reference_analysis.py` (38.8 KB) — **grep only**; the similarity
  algorithm's exact formula was not read, only its shape (threshold + cap + sort)
- All tool classes enumerated by grep of `^class .*Tool` — **the bodies of `file_tools.py` (32 KB),
  `jetbrains_tools.py` (33.7 KB), `config_tools.py`, `cmd_tools.py`, `query_project_tools.py`
  were not read.** Mechanism #31's tool list is from class names and marker mixins only.

**Not opened at all:**
- `src/serena/agent.py`, `project.py`, `code_editor.py`, `ls_manager.py`, `task_executor.py`,
  `dashboard.py`, `analytics.py`, `hooks.py`, `prompt_factory.py`, `mcp.py`
- All 70 files in `src/solidlsp/language_servers/` (grepped for capabilities only)
- `src/interprompt/`, `src/serena/jetbrains/`, `src/serena/generated/`
- The entire `test/` tree, `docs/`, `CHANGELOG.md` (62 KB), `README.md`
- 15 of 16 `contexts/*.yml`; 7 of 8 `modes/*.yml`; `system_prompt.yml`, `info_prompts.yml`

**Claims that need a live run before use:**
- **First-run index cost.** I read the loop and its timeout but never ran `serena project index`.
  "Minutes-scale" in §4 is an inference from `timeout=10` per file × file count, not a measurement.
  Grade **C** on the number; **A** on the mechanism (timeout, periodic save, failure log all exist).
- **Cache hit rate and on-disk size.** No `.serena/cache/` exists in the clone (gitignored). I
  never observed a populated pickle, its size, or a hit-rate log line.
- **Whether symbol tools actually cost fewer tokens than `Read`.** `claude-code.yml:6-7` asserts
  "much more efficient than your own tools"; that is the upstream's claim, unmeasured here. For a
  small file, three symbolic calls plausibly cost *more* than one `Read`. Grade **D** on the claim.
- Mechanism #9's cost estimate (diagnostics volume per edit) is an estimate, not measured.

**Suspected but not verified:**
- I believe no tool exposes `callHierarchy`, based on grepping `src/serena/tools/` for consumers
  and finding the calls only in `lsp_protocol_handler/`. I did not read all 9 tool modules in full,
  so a call routed through a helper in an unread file (`code_editor.py`, `ls_manager.py`) would not
  have shown up. Confidence high, not certain. This matters: if serena *did* expose call hierarchy
  it would be one step from a call-graph ranking, and #32/#33 would read differently.
- `JetBrainsTypeHierarchyTool` exposes *type* hierarchy (class names confirm), which is inheritance,
  not the call/reference graph — so it is not ranking material either. Verified by class name only.
- The `LanguageServerSymbolDictGrouper` compaction (`symbol_tools.py:41`, `:141`, `:257`) looks like
  a meaningful token-saving output format (group by kind, collapse singletons), but I did not read
  its implementation and cannot state what it saves. Possible missed ADOPT candidate.

---

## RANK vs ENUMERATE — verdict

**Serena ENUMERATES. It does not rank, anywhere, at all.**

Three independent lines of evidence:

1. **The grep is clean.** `rank|score|centrality|pagerank|importance|prioriti` over `src/serena/`
   and `src/solidlsp/` yields exactly three things, none of them about code: language-server
   selection *priority* (`serena_config.py:364-387`), memory-*name* string similarity
   (`memory_reference_analysis.py:105-193`), and a comment in `eclipse_jdtls.py:1331` saying
   completion ranking is deliberately *not* used ("so the bundle would be inert dead weight").

2. **Result order is traversal order.** `LanguageServerSymbol.find` is a plain recursive
   pre-order walk that appends every match (`symbol.py:401-418`) — no sort, no weight, no score.
   `find_referencing_symbols` returns references grouped by `(relative_path, kind)`
   (`symbol_tools.py:257`), which is *bucketing for compactness*, not ordering by importance.

3. **Over-budget is handled by summarizing, never by selecting.** This is the sharpest evidence.
   When `find_referencing_symbols` blows the char cap, the fallbacks are: strip context lines →
   per-file counts → a bare total (`symbol_tools.py:324-336`). At no point does it return *the most
   important N references*. A system with a relevance signal would spend it exactly here, and
   Serena has none to spend. `find_symbol`'s over-limit path does the same: `max_matches` exceeded
   returns a path→name-path map for the agent to refine against (`symbol_tools.py:217-218`) —
   pushing the ranking decision to the model.

The pointed detail for **OQ-G**: Serena has the reference graph *in hand* and does not rank over
it. `callHierarchy/incomingCalls` and `outgoingCalls` are implemented in the protocol layer
(`lsp_protocol_handler/lsp_requests.py:104-128`) and advertised by ~7 adapters, yet **no tool calls
them**. The most deliberately designed symbol toolset in this cluster had the raw material for a
centrality score, built the plumbing, and shipped precision-plus-progressive-degradation instead.

That is evidence, though not proof, on the OQ-G question. Read one way it is a negative datum: a
serious team with the graph available did not find ranking worth exposing. Read another way it is
scope, not judgment — Serena's bet is that a *precise* answer to a *specific* question beats a
ranked answer to a vague one, so it never needs to guess what matters. Both readings support the
same next action: OQ-G still needs the aider-style measurement (tokens per accepted outcome on
unfamiliar-repo tasks), and serena supplies no data point on it either way. What serena does
settle is narrower and useful: **it cannot be the source of a ranking mechanism, because it has
none.** Any spec text implying otherwise is wrong.
