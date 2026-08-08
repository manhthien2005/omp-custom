# Repo Report — aider

> **Path:** `_research/upstreams/aider`
> **SHA:** `5dc9490bb35f9729ef2c95d00a19ccd30c26339c` (`git -C aider rev-parse HEAD`)
> **License:** **Apache-2.0.** `LICENSE.txt` at root is the full Apache 2.0 text. Matches
> `registry/upstreams.yml:409`. No correction needed — unlike `andrej-karpathy-skills`.
> **Size:** 691 tracked files (`git ls-files | wc -l`)
> **Read this pass:** `aider/repomap.py` **in full** (867L) · `aider/special.py` **in full**
> (203L) · `aider/coders/context_coder.py` **in full** (53L) ·
> `aider/coders/context_prompts.py` **in full** (75L) ·
> `aider/coders/architect_coder.py` **in full** (48L) ·
> `aider/coders/architect_prompts.py` **in full** (40L) · `aider/coders/__init__.py` (34L) ·
> `aider/coders/editblock_coder.py` §`apply_edits` + `find_similar_lines` (`:38-124`,
> `:602-630`) · `aider/coders/base_coder.py` targeted regions (`:660-810`, `:925-945`,
> `:1585-1626`, `:1700-1760`) · `aider/models.py` `get_repo_map_tokens` (`:782-789`).

---

## 1. What this repo is

A **CLI coding agent** — its own runtime, its own loop, its own git integration. By our
standing constraint it is out of scope as a runtime and interesting only for the craft inside
it. Two pieces of that craft are unmatched anywhere else in the corpus: a **PageRank-based
symbol ranking algorithm** that fits a token budget by binary search, and a **failure-feedback
format** for edits that fail to apply.

This is the report `KD-015` ("ranking is a real capability gap; enumeration is not ranking")
has been resting on with only a partial read. It now has the algorithm traced end to end.

---

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| A1 | **PageRank over a def→ref graph** | Builds `nx.MultiDiGraph` where an edge `referencer → definer` carries `weight = mul × √num_refs`; ranks nodes with `nx.pagerank(G, weight="weight")` | `repomap.py:470-531` (graph `:470`, edge `:514`, pagerank `:525`) | **A** |
| A2 | **Rank distribution back onto symbols** | PageRank ranks *files*; aider then redistributes each file's rank across its out-edges proportional to edge weight, giving a rank per **(file, identifier)** pair — a symbol-level ranking, not a file-level one | `repomap.py:533-550` (`:543` is the distribution line) | **A** |
| A3 | **Mention-driven personalization** | Files named in the current message, and files whose path components match mentioned identifiers, get `personalize = 100/len(fnames)` in the PageRank `personalization` **and** `dangling` vectors | `repomap.py:383,424-445,519-522` | **A** |
| A4 | **Identifier weight multipliers** | `mul ×= 10` if the ident was mentioned; `×= 10` if snake/kebab/camel **and** `len ≥ 8`; `×= 0.1` if it starts with `_`; `×= 0.1` if defined in > 5 files; `×= 50` if the referencing file is in the chat | `repomap.py:487-509` | **A** |
| A5 | **`√num_refs` damping** | Reference counts are square-rooted so a symbol referenced 400× does not dominate one referenced 4× — high-frequency mentions are low-information | `repomap.py:511-512` | **A** |
| A6 | **Binary search to a token budget** | Searches prefix length of the ranked list, rendering a tree each iteration and counting tokens, until within 15% of `max_map_tokens`. Accepts on `pct_err < ok_err` (0.15) | `repomap.py:666-706` (`:690` `ok_err = 0.15`, `:691` accept, `:698-703` bisect) | **A** |
| A7 | **Sampled token counting** | For text ≥ 200 chars, counts tokens on every ~100th line and extrapolates by character ratio, rather than tokenizing the whole tree each of ~log₂(n) iterations | `repomap.py:89-101` | **A** |
| A8 | **mtime-keyed tag cache** | Per-file tags cached in a `diskcache.Cache` keyed by absolute path, invalidated by `mtime` comparison; corrupt cache → rmtree + recreate → fall back to plain `dict` | `repomap.py:233-264` (mtime check `:246`), `:177-215` (fallback) | **A** |
| A9 | **Budget scales with context window** | `map_tokens = clamp(max_input_tokens / 8, 1024, 4096)`; with no files in chat, budget is multiplied by `map_mul_no_files = 8`, capped at `context_window − 4096` padding | `models.py:782-789`; `repomap.py:56,122-132` | **A** |
| A10 | **`refresh` policy as a cost dial** | `always` / `files` / `manual` / `auto`; `auto` caches only once map construction exceeded **1.0 s** — a self-tuning cost/freshness tradeoff | `repomap.py:592-613` (`:609` is the 1.0 s rule) | **A** |
| A11 | **Important-files floor** | ~150 well-known root filenames (`pyproject.toml`, `Dockerfile`, `tsconfig.json`, …) plus `.github/workflows/*.yml` are prepended to the ranked list, ahead of everything PageRank chose | `special.py:3-193`; `repomap.py:657-662` | **A** |
| A12 | **Tree-sitter tag queries as the def/ref source** | `*-tags.scm` queries classify captures by prefix: `name.definition.*` → `def`, `name.reference.*` → `ref`. 31 language-pack + 27 legacy query files | `repomap.py:291-336` (`:319-322` the classification); `aider/queries/**` | **A** |
| A13 | **Pygments ref backfill** | If a language's query yields defs but no refs (e.g. C++), lex the file and emit every `Token.Name` as a `ref` with `line=-1` — degraded but non-empty | `repomap.py:338-363` | **A** |
| A14 | **Self-edge for unreferenced defs** | Every ident defined but never referenced gets a `weight=0.1` self-edge, so it stays in the graph instead of vanishing | `repomap.py:472-479` | **A** |
| A15 | **`ContextCoder` — a dedicated file-identification agent** | A coder whose only job is to name the files a request will touch. `NEVER RETURN CODE!`; forced output format of *files + their symbols*, plus a second list of relevant symbols **outside** those files | `context_coder.py:1-53`; `context_prompts.py:7-43,66-68` | **A** |
| A16 | **Fixed-point convergence loop** | `ContextCoder` re-runs with its own answer as the new file set until the mentioned set **equals** the current set, bounded by `max_reflections - 1` | `context_coder.py:34-45`; bound at `base_coder.py:101,939-943` | **A** |
| A17 | **"The user will use every file you mention"** | A prompt constraint that makes commentary costly: mentioning a file *is* selecting it, so hedging is not free | `context_prompts.py:13-15` | **A** |
| A18 | **Boosted budget for the identification pass** | `ContextCoder` sets `refresh="always"`, multiplies `max_map_tokens` by 8, then sets `map_mul_no_files = 1.0` — the exploration pass gets a deliberately larger map than the edit pass | `context_coder.py:14-19` | **A** |
| A19 | **Architect/editor split** | Architect (strong model) describes changes in prose; a fresh editor coder applies them with `map_tokens=0`, empty message history, `suggest_shell_commands=False` | `architect_coder.py:11-48` (`:28` `map_tokens=0`, `:38-39` cleared history) | **A** |
| A20 | **`DO NOT show the entire updated function/file`** | The architect prompt forbids full-file output, so the expensive model spends tokens on direction, not transcription | `architect_prompts.py:12-14` | **A** |
| A21 | **Structured edit-failure feedback** | On a failed SEARCH/REPLACE: name the class (`SearchReplaceNoExactMatch`), echo the block, offer nearest actual lines via `SequenceMatcher` at threshold 0.6, and detect the already-applied case | `editblock_coder.py:79-124`; `find_similar_lines` `:602-630` | **A** |
| A22 | **"The other N blocks were applied. Don't re-send them."** | Partial success is stated explicitly so the retry is scoped to what failed | `editblock_coder.py:118-124` | **A** |
| A23 | **Cross-file edit rescue** | A block that fails to match its stated path is retried against every other file in the chat before being declared failed | `editblock_coder.py:58-65` | **A** |
| A24 | **Bounded reflection loop** | `max_reflections = 3`; lint and test failures each feed back as a reflected message, once, gated on confirmation | `base_coder.py:100-101,932-944,1599-1623` | **A** |
| A25 | **Edit format as a per-model property** | 14 coder classes; `edit_format` chosen per model, with a separate `editor_edit_format` for the editor role | `coders/__init__.py:18-34`; `models.py:131,146,439-501` | **A** |

---

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| **A15 A17** | `explorer.md` agent prompt + its `output:` frontmatter | per-spawn | **ADOPT** | This is SD-11's missing half. Our Explorer contract says "rank by identifiers named in the packet, fit the budget, name what you excluded". A17 supplies the mechanism that makes it bite: *mentioning a file selects it.* A15's two-list output (files-to-modify + symbols-needed-from-elsewhere) is a better result shape than a flat file list, and it is expressible in `output:` |
| **A20** | `explorer.md`, and the Tech Lead → Implementer packet | per-spawn | **ADOPT** | One line, forbids the most expensive failure mode in a hand-off (re-emitting whole files as "direction"). Near-zero cost |
| **A21 A22** | `verifier` / `implementer` retry path; the `preexisting` failure class in KD-020 | per-action | **ADOPT** | The strongest transferable item after ranking. A failure report that names the class, shows nearest-actual-lines, and scopes the retry to only the failed part is exactly what KD-020's four-way classification needs at the *message* level. A22 in particular prevents a retry from redoing successful work |
| **A5 A4 A11** | `explorer.md` ranking heuristics (prompt-level, no index) | per-spawn (zero infra) | **ADOPT as heuristics** | These survive *without* building a ranking engine: prefer long snake/camel identifiers, discount `_private`, discount symbols defined in many places, damp high-frequency references, and always include the important-files floor. Prompt text, not code — the cheapest fraction of A1's value |
| **A16** | `explorer.md` + Tech Lead re-dispatch | per-spawn ×2 | **ADAPT** | Fixed-point convergence ("re-ask until the set stops changing") is a real quality mechanism and a real cost multiplier. Bound it at **one** re-ask, not aider's 2. Needs measurement before adoption — folds into OQ-G |
| **A6 A7 A9** | Explorer result budget; `spec/05` token model | per-action | **ADAPT (principle only)** | The *principle* — search for the prefix that fits the budget rather than truncating — transfers to "Explorer fits its result to a stated budget". The binary-search implementation does not; we have no tree renderer to iterate on. A9's `context/8` clamp is a good default shape for sizing a retrieval budget against a model's window |
| **A19** | `/orchestrated` topology: Tech Lead (strong) → Implementer (cheaper) | per-spawn | **ADOPT — already our shape, now corroborated** | `architect_coder.py:38-39` clearing `cur_messages`/`done_messages` and `:28` setting `map_tokens=0` is independent confirmation of our clean-packet hand-off. Grade A corroboration for `spec/09` model routing and L2 topology |
| **A1 A2 A3** | — (**no OMP primitive**) | would be per-action + persistent index | **REJECT for v0, DEFER the capability** | Requires tree-sitter, `networkx`, a `diskcache` store, and 58 `.scm` query files. OMP has no ranking primitive (this is the `omp-ranking-capability-gap` finding) and no place to host an index. **A2 is the sharpest thing in this repo** — ranking *symbols* rather than files — and it is precisely what we cannot cheaply have. Trigger to revisit: OQ-G shows `glob`+`read` loses on unfamiliar-repo tasks |
| A8 A10 | — | — | **REJECT** | Cache infrastructure for an index we are not building. A10's "cache only if it took > 1 s" is a nice self-tuning idea with nowhere to attach |
| A12 A13 A14 A23 | — | — | **REJECT** | Implementation detail of the index (A12–A14) or of aider's own edit applier (A23). A13 is worth remembering as a *design principle* — degrade to a weaker signal rather than returning nothing — but it has no attachment point |
| A24 | — | — | **REJECT (confirms KD-011)** | `max_reflections = 3` is a bounded-loop constant in aider's own runtime. OMP owns the loop. Corroborates `mini-swe-agent`'s termination-set finding; adds nothing new |
| A25 | — | — | **REJECT** | 14 edit formats exist because aider supports many models across many capability levels. We route through OmniRoute and do not own an edit applier |
| A18 | Explorer's retrieval budget vs Implementer's | per-spawn | **ADAPT** | The asymmetry is the insight: the *identification* pass deserves a **larger** map than the *editing* pass. Our `spec/05` budget table does not currently distinguish them. Cheap to reflect: one row |

**Net new mechanisms for the spec: 1 (SD-11's completion).** Consistent with
`02-repo-synthesis.md`'s `Net new this pass: 1` for aider. This full read does not raise the
count — it **grounds** it, and upgrades SD-11 from grade B+C to a mechanism with an A-graded
source (`context_prompts.py:13-15`, `context_coder.py:14-19`).

**Net new for the retry path: A21/A22.** These are not in SD-11 and not in any current SD.
They attach to KD-020's failure classification and belong in `spec/10`. **This is the one
finding in this report that should become a new delta** — proposed as **SD-13** in §5-3.

---

## 4. What this repo does that we deliberately will not

- **Build and maintain a symbol index.** A1–A3 need tree-sitter parsers, 58 `.scm` query
  files, `networkx`, and a `diskcache` store keyed by mtime. Our constraint is that every
  installed file is discovered by OMP; an index is none of those things, and OMP offers no
  primitive to host it. The honest statement of KD-015 is: *we know what the good answer looks
  like, and we are choosing a worse one for structural reasons* — not *we think ranking is
  unnecessary*. This report is the evidence for the first framing.
- **Own the edit applier.** A21–A23 are wrapped around aider's own SEARCH/REPLACE engine. We
  take the **feedback shape**, not the engine; OMP's `edit` tool applies changes.
- **Run a second agent loop.** A24, `preproc_user_input`, the reflection loop, auto-lint and
  auto-test gating on `io.confirm_ask` — all of it is a runtime we are not adding.
- **Interactive confirmation as a quality gate.** `architect_coder.py:17` asks "Edit the
  files?" before applying. Our workflow is non-interactive at the worker boundary; the
  equivalent must be a *contract check* (SD-2: `completed` with no patch is not completed),
  not a prompt.
- **Trust basename mentions.** `base_coder.py:1743-1757` will pull a file into context from a
  bare basename if it is unique and contains `.`/`_`/`-`/`/`. That is an implicit-context
  mechanism; our packet is explicit by design, and `01-dna.md` L3 requires it.

---

## 5. Contradictions with our current spec or registry

### 5-1. `registry/upstreams.yml:416-418` — a watched path that does not exist

```yaml
watched_paths:
  - aider/repomap.py
  - docs/repomap.md      # ← does not exist at this SHA
```

`git ls-files | grep -i repomap` at `5dc9490`:

```
aider/repomap.py
aider/website/_posts/2023-10-22-repomap.md
aider/website/docs/repomap.md
tests/basic/test_repomap.py
tests/fixtures/sample-code-base-repo-map.txt
```

There is no `docs/repomap.md`. The correct path is **`aider/website/docs/repomap.md`**. A
watched path that cannot resolve never fires, so this is a governance check that silently
passes — the same failure shape as SD-1 (`packages/**` vs `docs/**`) and SD-10 (`anthropics/skills`
`spec/`). It should be corrected **and** counted in whatever check `spec/14` uses to validate
watched paths, because three of these have now been found by hand.

Recommended: correct the path, and add `aider/coders/context_coder.py` +
`aider/coders/context_prompts.py` — those are the files SD-11 now derives from, and a change
there would matter more to us than a change in `repomap.py` we have already decided not to
implement.

### 5-2. `registry/upstreams.yml:411-415` — `authority_for` overstates one claim

```yaml
authority_for:
  - repository-map design principles
  - symbol-first exploration
  - token-budgeted context
  - architect/editor separation
```

All four are supportable, but **`symbol-first exploration`** needs a qualifier now that A2 is
traced. Aider's ranking is symbol-level (rank per `(file, ident)` pair,
`repomap.py:543-545`); our Explorer's is **file-level with symbol hints in the prompt**.
Recording aider as our authority for "symbol-first exploration" without noting that we adopt
only the heuristics and not the ranking invites a future maintainer to believe we implemented
the mechanism. Suggested: `symbol-first exploration (heuristics adopted; ranking engine
rejected — see KD-015)`.

### 5-3. New delta — **SD-13** (proposed): structured edit-failure feedback

No current SD covers A21/A22, and `spec/10 §C` + KD-020 have the gap. Proposed shape:

> **SD-13.** When a verification or apply step fails, the message returned to the retrying
> agent must (a) name the failure class, (b) quote the exact failing input, (c) where a
> near-match exists, show it, and (d) state explicitly which parts **succeeded** and must not
> be redone.
> **Attaches to:** `verifier.md` / `implementer.md` retry contract; KD-020's failure classes.
> **Tier:** per-action. **Target:** `spec/10 §C`, `template/.omp/agents/verifier.md`.
> **Grade:** A for the upstream mechanism (`editblock_coder.py:79-124`), C for our adoption.

Point (d) is the non-obvious one and the reason this is worth a delta: without it, a retry
re-emits work that already landed, which is both a token cost and a correctness risk when the
first application was partial.

### 5-4. `01-dna.md` L4 — one addition, no contradiction

L4 Retrieval attaches to `lsp · grep · read ranges` and is correct. What this read adds is
A18's asymmetry: the identification pass should get a **larger** retrieval budget than the
editing pass (`context_coder.py:14-19` multiplies by 8 and forces `refresh="always"`). Our
`spec/05` budget table treats retrieval as one tier. Not a contradiction — an unmodeled
distinction, cheap to add.

### 5-5. KD-015 is confirmed, and its reasoning improves

KD-015 ("ranking is a real capability gap; enumeration is not ranking") stands. This read
strengthens it in one specific way: the gap is not merely *ranked files vs listed files*, it
is **ranked symbols** (A2). `nx.pagerank` returns file ranks; the redistribution at
`repomap.py:543` is what produces a per-symbol ordering, and that step is the part with no
cheap substitute. `lsp`-based enumeration cannot approximate it, because the missing
ingredient is the *reference graph weighting*, not the symbol list. KD-015's reversal
condition (OQ-G) is unchanged and correctly stated.

---

## 6. Cost profile

| §3 row | Cost tier | What is actually paid |
|---|---|---|
| A15 A17 A20 (Explorer prompt + result shape) | **per-spawn** | Est. **+120–200 tok** on `explorer.md`. A17 is one sentence; A15's two-list format is ~8 lines of format spec. **Estimate**, basis: `context_prompts.py:7-43` is 37 lines / ~330 words, and we would adopt roughly half |
| A21 A22 (SD-13 failure feedback) | **per-action, on failure only** | Zero on the success path. On failure: the failing block + up to ~10 near-match lines + one "N others succeeded" line. Est. **+150–400 tok per failed action**, and it *replaces* a blind retry that would re-send everything — likely net negative cost |
| A4 A5 A11 (ranking heuristics as prompt text) | per-spawn | Est. **+60–100 tok** in `explorer.md`. A11's 150-name list is **not** adopted verbatim — the rule is "always include build/config/CI manifests", ~1 line |
| A16 (convergence re-ask, bounded at 1) | **per-spawn ×2** | **Doubles Explorer cost** when it triggers. This is the expensive one and the reason it is ADAPT-pending-measurement, not ADOPT |
| A18 (asymmetric budgets) | zero | A row in a table. Reallocates budget; does not add it |
| A19 (architect/editor) | — | Already our topology. Zero delta |
| A1 A2 A3 (the ranking engine) | **rejected** | For the record: `networkx` + `tree-sitter` + `diskcache` + 58 `.scm` files, an on-disk index per repo, and a first-run scan aider itself warns is slow (`repomap.py:391-394`). Plus the map itself, 1,024–4,096 tok **per turn** at `models.py:782-789`, ×8 with no files in chat (`repomap.py:126`) — up to `context − 4096`. That per-turn figure is the real reason this is not a v0 item: it is a **persistent-tier** cost, the most expensive band in `01-dna.md` |

The comparison worth recording: aider spends **1–4 k tokens every turn** to keep a ranked map
resident. Our `AGENTS.md` + `RULES.md` persistent budget is **600–1,200 + ≤700 tok**
(`01-dna.md` L0). Adopting aider's map wholesale would be a 2–5× increase in the always-paid
band to buy retrieval quality — which is exactly the trade `spec/05` exists to refuse without
measurement. OQ-G is the right gate.

---

## 7. Coverage and limits  (MANDATORY)

**Files read in full (6):** `aider/repomap.py` (867L) · `aider/special.py` (203L) ·
`aider/coders/context_coder.py` (53L) · `aider/coders/context_prompts.py` (75L) ·
`aider/coders/architect_coder.py` (48L) · `aider/coders/architect_prompts.py` (40L).
Plus `aider/coders/__init__.py` (34L).

**Files read in part:**
- `aider/coders/editblock_coder.py` (657L) — read `apply_edits`/`apply_edits_dry_run`
  (`:38-124`) and `find_similar_lines` (`:602-630`). **The matching engine itself
  (`do_replace`, `perfect_or_whitespace`, the fuzzy fallbacks, `:135-600`) is unread.** A21's
  *feedback format* is grade A; how aider decides a match failed is grade B.
- `aider/coders/base_coder.py` (2,485L) — read `:660-810` (repo-map wiring, mention
  extraction), `:925-945` (reflection loop), `:1585-1626` (lint/test feedback),
  `:1700-1760` (`get_file_mentions`). **~2,200 lines unread**, including `send_message`,
  `format_messages`, prompt assembly, and all cache-warming logic.
- `aider/models.py` (1,338L) — read `get_repo_map_tokens` (`:782-789`) and grepped
  `edit_format` assignments. The 1,300 lines of model metadata and routing are unread.

**Not opened at all:**
- All 60 files under `aider/queries/` (the `.scm` tag queries). I counted them (31 + 27
  `*-tags.scm`) and read the *classification convention* from `repomap.py:319-322`, not from
  any query file. **What a `name.definition.*` capture matches in a given language is
  unverified.**
- 12 of the 14 coders: `editblock_fenced`, `udiff`, `udiff_simple`, `wholefile`, `patch`,
  `ask`, `help`, `editor_*` (3), and both `*_func_coder` variants. A25's claim that edit
  format is a per-model property rests on `coders/__init__.py` + `models.py` greps, not on
  reading the coders.
- `aider/commands.py` (1,712L), `aider/main.py` (1,274L), `aider/io.py` (1,191L),
  `aider/args.py` (945L), `aider/repo.py` (622L), `aider/gui.py`, `aider/linter.py`,
  `aider/watch.py`, `aider/onboarding.py`, `aider/analytics.py`, and everything else in
  `aider/*.py` beyond the two files read in full.
- **The entire `tests/` tree** — including `tests/basic/test_repomap.py` and
  `tests/fixtures/sample-code-base-repo-map.txt`. **No claim here is backed by a test I ran
  or read.** The fixture in particular would show what a real repo map *looks like*, which
  would sharpen §6's token estimates; I did not open it.
- All of `aider/website/` (the bulk of the 691 files), including
  `aider/website/docs/repomap.md` — the doc our registry means to watch — and
  `aider/website/docs/more/edit-formats.md`. So my account of edit formats is source-derived,
  not doc-corroborated, and I did not read aider's own explanation of its repo map.
- `aider/coders/search_replace.py`, `chat_chunks.py`, `shell.py`, `base_prompts.py`.

**Claims that need a live run before use:**
- Every §6 token figure is an **estimate**, not a measured count. The 1–4 k/turn map cost is
  read from `models.py:782-789` and is aider's *budget*, not an observed spend.
- A16's cost (doubling Explorer spend) and its benefit are both unmeasured. This is OQ-G
  territory and the reason it is ADAPT, not ADOPT.
- Whether A17's "the user will use every file you mention" actually reduces over-mentioning,
  versus merely reading as emphasis. Untested; it is a prompt-behavior claim (grade A that
  the text exists, C that it works).
- SD-13's net token effect. I argue it is negative (a scoped retry beats a blind one), but
  that is reasoning, not measurement.

**Anything suspected but not verified:**
- `repomap.py:306-310` looks wrong: inside `for tag, nodes in captures.items()`, the loop
  appends `node` to `captures_by_tag[tag]` for each node **and then appends `node` again**
  after the inner loop (`:309`), plus `matches.append((node, tag))` with the loop variable
  leaked from the inner loop. Under `USING_TSL_PACK` the duplicate lands in `all_nodes`
  (`:313`) and yields a duplicate `Tag`. **I did not verify the consequence** — `saw` is a
  set and duplicate refs would inflate `Counter(references[ident])`, hence edge weight, but
  `√num_refs` damps it. Possibly a real (small) bug, possibly dead under the non-pack path.
  Flagged, not claimed. Nothing in §3 depends on it.
- `repomap.py:516-517` (`if not references: pass`) is a no-op, and `:465-466` already
  reassigned `references` above it. Looks vestigial. Harmless either way.
- Whether `find_similar_lines`' 0.6 `SequenceMatcher` threshold is well-chosen. It is a
  magic constant with no comment and no test I read.
- Whether A2's redistribution is *the* reason aider's map outperforms flat enumeration, or
  whether A3/A4's mention-boosting carries most of the benefit. This distinction matters for
  KD-015 — if mention-boosting is most of the value, a prompt-level Explorer heuristic
  captures more of aider's advantage than I credit in §3. **Ablation would settle it; I
  cannot from source alone.**
