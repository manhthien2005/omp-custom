# Repo Report — mini-swe-agent

> **Path:** `_research/upstreams/mini-swe-agent`
> **SHA:** `a83fcae82d2a08f0ee0c688f9d137b3566c097f8` (`git -C mini-swe-agent rev-parse HEAD`)
> **License:** **MIT**, single grant, no split. `LICENSE.md:1-3`: `MIT License` /
> `Copyright (c) 2025 Kilian A. Lieret and Carlos E. Jimenez`. No per-file grants or
> alternate content license anywhere. Cleanest license situation of the four repos in this
> batch — prompts and code alike are MIT, so their prompt text is reusable with attribution.
> **Size:** 221 tracked files (`git ls-files | wc -l`). ~30 are the actual agent; the rest
> are docs, tests, and model adapters.
> **Read this pass:** the whole loop and everything that terminates it. `agents/default.py`,
> `exceptions.py`, `environments/local.py`, `agents/interactive.py`,
> `models/litellm_model.py`, `models/utils/actions_toolcall.py`,
> `models/utils/actions_text.py`, `models/utils/retry.py`, `models/utils/cache_control.py`,
> `config/default.yaml`, `config/mini.yaml`, `config/benchmarks/swebench.yaml`,
> `run/benchmarks/swebench.py`, `run/benchmarks/utils/common.py`,
> `docs/advanced/control_flow.md`, `README.md`, plus `docs/faq.md` head. Prior coverage was
> 2 files (`agents/default.py`, `config/default.yaml`).

## 1. What this repo is

A **runtime** — and the smallest credible one in this batch. `DefaultAgent` is 191 lines
(`agents/default.py`). The agent has exactly one tool, `bash`
(`models/utils/actions_toolcall.py:11-27`), a strictly linear message list, and no
subagents, no planner, no reviewer, no retrieval index, and no memory layer. Every action
runs in a fresh subshell via `subprocess.Popen(..., shell=True)`
(`environments/local.py:74-85`), so the agent cannot even `cd` persistently. It claims
**>74% on SWE-bench Verified** (`README.md:28`) and is credited as the harness behind Ramp's
SWE-bench work and a DeepSWE evaluation (`README.md:7-8`).

The project's own thesis is the question we have to answer:
> *"What if our agent was 100x simpler, and still worked nearly as well?"* — `README.md:21`

## 2. Mechanism inventory

| # | Mechanism | What it does | Evidence `file:line` | Grade |
|---|---|---|---|---|
| M1 | One-tool surface | Only `bash` is registered. Unknown tool name ⇒ `FormatError`, not a crash | `models/utils/actions_toolcall.py:11-27`, `:61-62` | A |
| M2 | The entire loop | `while True: step()`; `step` = `execute_actions(query())`. Terminates only when `messages[-1]["role"] == "exit"` | `agents/default.py:96-124`, `:126-128` | A |
| M3 | Typed termination via exceptions | `InterruptAgentFlow` base; `Submitted`, `LimitsExceeded`, `TimeExceeded`, `UserInterruption`, `FormatError` all carry the messages they append | `exceptions.py:1-27` | A |
| M4 | Four independent limits | `step_limit`, `cost_limit` (default 3.0), `wall_time_limit_seconds`, `max_consecutive_format_errors` (default 3) | `agents/default.py:26-33` | A |
| M5 | Limits checked *before* the call, not after | `query()` raises `LimitsExceeded` / `TimeExceeded` *before* incrementing `n_calls` and issuing the request | `agents/default.py:132-148` | A |
| M6 | Consecutive-error reset on any clean step | `self.n_consecutive_format_errors = 0` runs after every successful `step()` | `agents/default.py:99` | A |
| M7 | Billed-but-unparsed cost is still charged | On `FormatError`, the cost of the failed call is added back: *"The call was billed before parsing failed, so query() never got to charge it."* | `agents/default.py:100-102`, `models/litellm_model.py:87-98` | A |
| M8 | Submission is an **environment**-detected magic string | `env.execute` inspects stdout; first line `== COMPLETE_TASK_AND_SUBMIT_FINAL_OUTPUT` **and** `returncode == 0` ⇒ raise `Submitted` | `environments/local.py:45-56` | A |
| M9 | Failed command is *not* an error — it is an observation | Nonzero exit and even Python exceptions become `{output, returncode, exception_info}` and are rendered into a normal user/tool message | `environments/local.py:28-43`, `models/utils/actions_toolcall.py:79-113` | A |
| M10 | Output elision with head+tail+count | `<10000` chars ⇒ verbatim. Otherwise first 5000, `elided_chars` count, last 5000, plus explicit remediation advice | `config/default.yaml:114-141` | A |
| M11 | Format-error template distinguishes truncation from malformation | If `finish_reason in ["length","tool_calls"]`, tell the model it was *cut off*; else give format guidance | `config/default.yaml:144-171`, `config/benchmarks/swebench.yaml:159-179` | A |
| M12 | Timeout kills the process **group** | `os.killpg(..., SIGKILL)` on POSIX so no orphaned children; partial stdout is preserved and re-raised | `environments/local.py:86-91` | A |
| M13 | Per-action env hardening against interactive output | `PAGER=cat`, `MANPAGER=cat`, `LESS=-R`, `PIP_PROGRESS_BAR=off`, `TQDM_DISABLE=1` | `config/default.yaml:106-112` | A |
| M14 | Transport retry separated from agent retry | `tenacity`, 10 attempts, exponential 4–60s, with an **abort list** (auth, not-found, context-window-exceeded, unsupported-params) that must not be retried | `models/utils/retry.py:19-25`, `models/litellm_model.py:50-57` | A |
| M15 | Trajectory == messages, serialized every iteration | `save()` in the loop's `finally`, so a crash still leaves a complete trajectory | `agents/default.py:120-121`, `:159-190` | A |
| M16 | Cache control set at the **tail** only | Clears all markers, sets one `ephemeral` marker on the last message | `models/utils/cache_control.py:60-67` | A |
| M17 | Cost-tracking failure is fatal by default | `cost <= 0.0` raises unless explicitly opted out via `cost_tracking: ignore_errors` | `models/litellm_model.py:108-126` | A |
| M18 | Interactive mode = three modes on one loop | `human` / `confirm` / `yolo`, with a regex `whitelist_actions` bypass; rejection becomes a *message*, not an abort | `agents/interactive.py:24-31`, `:162-182` | A |
| M19 | Wall-clock limit is deliberately non-negotiable | `TimeExceeded` re-raised even in interactive mode, because *"the next query re-checks the clock and raises again, so prompting would loop forever"* | `agents/interactive.py:75-79` | A |
| M20 | Unattended runs must not hang on `input()` | `_stdin_is_interactive()` gate so CI/`--yolo` stops cleanly instead of `EOFError` | `agents/interactive.py:80-107` | A |
| M21 | Parallelism lives in the *runner*, not the agent | `ThreadPoolExecutor(max_workers=workers)`, one independent agent per instance, file-locked preds writes | `run/benchmarks/swebench.py:256-263`, `:97-108` | A |
| M22 | Prompt states the loop contract to the model | *"You are operating in an environment where 1. You issue at least one command 2. The system executes… 3. You see the result(s) 4. You write your next command(s)"* | `config/mini.yaml:21-28` | A |
| M23 | Submission is a **three-step, separated** protocol | Create patch → *inspect it* → submit with an exact command; explicitly forbids combining with `&&` | `config/benchmarks/swebench.yaml:77-110` | A |

## 2b. KD-011 verification — asked for explicitly, so stated precisely

`spec/key/02-repo-synthesis.md:459-463` claims their four limits map onto OMP, three
directly. **Verified. The mapping holds, with two corrections and one addition.**

| Their limit | Their default | Claimed OMP equivalent | Verified? |
|---|---|---|---|
| `step_limit` | `0` in `default.yaml:104`; **`250` in `benchmarks/swebench.yaml:112`** | `task.softRequestBudget` = 200, force-stop at 1.5× | **A, and the numbers nearly coincide.** `settings-schema.ts:4676-4691` confirms default 200 and the 1.5× force-stop. Their benchmark-tuned value is 250. Two independent projects landed within 25% on "how many turns before a worker is lost" |
| `cost_limit` | `3.0` in `AgentConfig` (`agents/default.py:28`); `0.` in `default.yaml:105`; **`3.` in `swebench.yaml:113`** | *none verified* | **Still grade D — and I did not close it.** See §5.2 |
| `wall_time_limit_seconds` | `0` = unlimited (`agents/default.py:30`) | `task.maxRuntimeMs` | **A.** `settings-schema.ts:4644-4661`, default `0` = unlimited. **Both default to off.** Same default, same reasoning ("defense-in-depth against stream hangs") |
| `max_consecutive_format_errors` | `3` (`agents/default.py:32`) | `MAX_SCHEMA_RETRIES = 3` | **A.** `tools/yield.ts:202` and `:388-399`. The number matches exactly |

**Correction 1 — the spec cites the wrong file for `agentIdleTtlMs`.** `spec/key/02:461`
lists `task.agentIdleTtlMs` (420 s) among the "three of four" mappings. It is not an
equivalent of anything here. `settings-schema.ts:4664-4674` describes parking an *idle* agent
to disk with automatic revival — a memory-management feature, not a termination condition.
Nothing in mini-swe-agent parks or revives. The genuine three-of-four are `step_limit`,
`wall_time_limit_seconds`, and `max_consecutive_format_errors`.

**Correction 2 — a divergence the spec does not record, and it favors them.**
`MAX_SCHEMA_RETRIES` **does not terminate**. After 3 failures OMP *drops the schema
constraint and accepts the data* (`tools/yield.ts:388-399`: `schemaValidationOverridden =
true`, with the model told *"this is the final retry before the schema constraint is
dropped"*). mini-swe-agent does the opposite — it **exits** with
`exit_status: "RepeatedFormatError"` (`agents/default.py:104-112`).

The numbers match; the semantics are opposite. Ours degrades to unvalidated-but-accepted;
theirs degrades to failed-and-labelled. For a template whose headline metric is
**false-completion rate, this is the more dangerous of the two behaviours** and it is not
recorded anywhere in `spec/key`. A worker that cannot produce a valid result three times
running does not yield a *failure* — it yields **unvalidated output that our §6 structured
output contract will treat as conforming**. That is a false-completion channel created by
the runtime, sitting directly underneath the mechanism we chose to prevent false
completions.

**Addition — what we are missing (5 items, ordered by how much they bear on our metric):**

1. **Limits are checked before the call, not after** (M5). `query()` raises *before*
   `n_calls += 1` and before `model.query()` (`agents/default.py:132-148`). A worker at its
   budget therefore never issues the request that would exceed it. Our coordinator-side
   equivalent: check the packet's plausibility against the budget *before* spawning, not
   after reading a partial result.
2. **The consecutive counter resets on any clean step** (M6, `agents/default.py:99`). It
   counts *runs*, not totals. Without the reset, a long worker accumulates unrelated
   failures into a spurious stop. If we adopt F9-style capping (see the 12-factor report),
   we must adopt the reset with it or we build a worse version.
3. **Cost that was billed but not parsed is still charged** (M7,
   `agents/default.py:100-102`). A malformed response is not free. Our accounting reads
   per-spawn `cost` from the result, so a worker that dies *before* returning a result may
   contribute an unrecorded charge. We would systematically under-count exactly the failures
   we most want to measure.
4. **The wall-clock limit is the one limit that may not be raised interactively** (M19,
   `agents/interactive.py:75-79`), because a clock cannot be un-exceeded. A step or cost
   limit can be lifted; time cannot. A principled distinction we do not make.
5. **Cost-tracking failure is fatal unless explicitly waived** (M17,
   `models/litellm_model.py:108-126`). Silent `cost = 0.0` would corrupt the cost ceiling, so
   they refuse to run rather than measure wrongly. For a template whose metric is *tokens per
   accepted outcome*, "refuse to report a number you cannot compute" is the right default and
   the opposite of what unmeasured systems do.

## 3. Transferable to omp-custom

| Mechanism | OMP attachment point | Cost tier | Verdict | Why |
|---|---|---|---|---|
| **M10 head+tail+`elided_chars` elision with remediation advice** | Worker result contract; also mirrors `MAX_OUTPUT_BYTES` 500 000 / `MAX_OUTPUT_LINES` 5 000 (`task/types.ts:53-56`) | `per-action`; **reduces** tokens | **ADOPT** | Three details make theirs better than plain truncation: the elided *count* is stated (`config/default.yaml:131-137`), both ends are kept, and the model is told *what to do differently* — *"you can try use head, tail or sed to view a smaller number of lines"* (`:126-129`). A middle-elided observation with a byte count and a next-action hint is strictly more useful than a tail cut, at no extra cost |
| **M11 truncation vs. malformation are different errors** | Worker result contract + coordinator's read of a failed spawn | `zero` | **ADOPT** | `finish_reason == "length"` means *the model ran out of room*, which is a sizing failure. Any other parse failure is a *format* failure. Same symptom, opposite remedy: re-partition vs. re-instruct. Merging them guarantees the coordinator picks the wrong fix ~50% of the time |
| **M9 a failed command is an observation, not an error** | Worker agent bodies (all four) | `zero` | **ADAPT** | `environments/local.py:28-43` turns every failure — nonzero exit *and* Python exception — into structured data with `returncode` and `exception_info`. Nothing aborts. Only *format* failures and *limits* abort. The transferable rule: **a worker aborts on limits and contract violations, never on a red test.** A red test is the finding |
| **M23 submission as a separated three-step protocol** | Verifier / diff-reviewer bodies | `zero` | **ADOPT** | `swebench.yaml:77-110` requires create-patch → *inspect the patch* → submit, and explicitly forbids `&&`-combining: *"Creating/viewing the patch and submitting it MUST be separate commands"* (`:107`). This is a **forced-read-before-claim** step, which is precisely the anti-false-completion move: the agent must observe its own artifact before asserting it. Our diff-reviewer should require the diff be read as a separate observation from the verdict |
| **M6 counter resets on a clean step** | Coordinator's failure counting | `zero` | **ADOPT** | Companion to the F9 cap. Without it, the cap becomes a total budget and fires wrongly on long tasks |
| **M5 limits checked pre-call** | Coordinator pre-spawn sizing check | `zero` | **ADAPT** | We cannot intercept OMP's per-request accounting. The available form: refuse to spawn a packet whose scope plainly exceeds a worker's budget, rather than discovering it in a partial yield |
| **M13 non-interactive env hardening** | `/quick`/`/standard` worker guidance, or shell env if the template ships one | `zero`; **reduces** per-action tokens | **ADOPT** | `PAGER=cat`, `TQDM_DISABLE=1`, `PIP_PROGRESS_BAR=off` (`config/default.yaml:106-112`). Progress bars and pager escapes are pure token waste in captured output, and every one of our workers runs commands. Cheapest row in this report |
| **M14 abort-list separating transport retry from agent retry** | Coordinator's read of spawn failure | `zero` | **ADAPT** | `models/litellm_model.py:50-57` never retries auth, not-found, or **context-window-exceeded**. That last one matters: a context overflow is a *sizing* failure and retrying it burns the same tokens to fail identically. Our equivalent: never re-spawn an identical packet after a context-limit failure — re-partition |
| **M15 trajectory saved in `finally`** | Existing OMP transcript; **DEFER as a mechanism** | — | **DEFER** | `agents/default.py:120-121` saves every iteration so a crash still yields a complete trajectory. OMP persists sessions already. *Trigger:* if we ever observe a crashed worker whose partial work is unrecoverable from the session transcript, revisit. Do **not** build a trajectory writer now — that is a second runtime, and the `.omp/policies/` failure mode |

**Explicitly rejected, with reasons:** M1 (one-tool surface — our tools are OMP's), M2/M3
(their loop and exception hierarchy — a second loop controller, forbidden by constraint),
M16 (cache control — OMP owns the wire), M18 (their interactive modes — OMP owns
permissions), M21 (`ThreadPoolExecutor` — a scheduler, forbidden by constraint; the *craft*
inside it, one independent agent per unit with no shared state, is what our `/orchestrated`
already does).

## 4. What this repo does that we deliberately will not

**We will not adopt the single-tool bash surface.** It is genuinely tempting given the
results, and the argument is real: it removes tool-schema tokens, works with any model,
needs nothing installed (`README.md:42-50`). But it is not available to us — our tools are
OMP's, and reducing to `bash` would mean *paying for* the read/edit/grep schemas while
declining to use them. Strictly worse than either endpoint.

**We will not adopt stateless subshell-per-action.** `README.md:48-50` calls this *"a big
deal"* and the FAQ makes it a headline (`docs/faq.md`). It buys trivially sandboxable,
independently-retryable actions. But it costs the agent `cd` and exported env vars, mitigated
only by an instruction to prefix every command (`config/default.yaml:39-40`). OMP's bash
tool has its own session semantics; re-imposing statelessness would add prompt tokens to
*remove* a capability.

**We will not build their loop, their exception hierarchy, or their runner.** M2, M3, and
M21 are the parts a naive reading would want to port. All three are runtime, and OMP is the
only runtime. What transfers is the *craft* inside them — typed termination as a *shape*
(§2b), and per-unit independence — not the classes.

## 5. The uncomfortable question, at full strength

The instruction was to state the case against our architecture without reverence. Here it is.

### 5.0 The argument

A 191-line agent with one tool, no subagents, no reviewer, no retrieval layer, no memory,
and a linear message list scores **>74% on SWE-bench Verified** (`README.md:28`) and is
claimed to **beat Claude Code and Codex on DeepSWE** (`README.md:8`). It is used by *"Meta,
NVIDIA, Essential AI, IBM, Nebius, Anyscale, Princeton University, Stanford University"*
(`README.md:25`).

Now count what we have added on top of a runtime that is already more capable than theirs:
a coordinator, four worker agents, three workflow commands, a structured-output contract, a
skill library, a task-packet convention, and a spec that has been through six adversarial
review rounds. **What is the measured delta?** There is none. Not one number in
`spec/00-16` or `spec/key/*` is a measurement of our architecture against a simpler
baseline. The entire justification is architectural reasoning plus citations to upstreams —
including, circularly, this one.

Worse, the specific thing we are most proud of is the thing they most conspicuously do not
have. Our headline metric is false-completion rate, and our answer is a separate
diff-reviewer worker. Their answer is **two lines of prompt text**: make the agent create
the patch, then read the patch, then submit with an exact command
(`config/benchmarks/swebench.yaml:94-102`). Their anti-false-completion mechanism costs
zero spawns. Ours costs an entire agent invocation with a full system prompt, its own skill
listing, and its own context re-establishment. If forced-self-inspection captures most of
the benefit, the diff-reviewer is a very expensive way to buy the remainder — and we have
never measured the remainder.

And the direction of travel is against us. SWE-agent — by the *same team*, with per-tool
interfaces, history processors, and configurable scaffolding — is now positioned as the
specialist fallback: *"You should consider `mini-swe-agent` your default choice"*
(`README.md:85`). Their stated reason is that scaffolding earns its keep less as models
improve: *"as LMs have become more capable, a lot of this is not needed at all to build a
useful agent"* (`README.md:39`). They built the elaborate thing, measured, and walked it
back. **We have built an elaborate thing and not measured.** On the evidence available in
this repository, our multi-agent apparatus is a hypothesis wearing the clothes of a
conclusion.

### 5.1 The honest rebuttal — smaller than it feels

Three real disanalogies, and one concession:

1. **Different task shape.** SWE-bench instances arrive with a problem statement, a prepared
   `/testbed` (`swebench.yaml:116`), and an oracle test suite that adjudicates success. A
   human working in a live repo has none of that. Their submission is *"a git patch"*
   (`:77`) graded externally. Our workflows must produce the judgment too. That is a
   genuinely harder problem — but it argues for a *verifier*, not for four workers and three
   workflows.
2. **They do not solve false completion; they outsource it.** `Submitted` fires on a magic
   string in stdout (`environments/local.py:45-56`). Whether the patch is *correct* is
   decided by the benchmark harness. Nothing in the agent checks. So the >74% is not
   evidence that a minimal agent avoids false completion — it is a number produced by a
   system that has an external oracle. **We do not have one.** This is the strongest point
   in our favour and it is narrow: it justifies verification, not multi-agent topology.
3. **Their limits do the work our topology claims to do.** `step_limit: 250`,
   `cost_limit: 3.0` (`swebench.yaml:112-113`). Bounded scope is enforced by *numbers*, not
   by decomposition. And 12-factor's F10 (3–20 steps) argues bounded scope is where the
   quality comes from. If limits alone capture that, decomposition is buying something
   smaller than we assume.
4. **Concession we should stop resisting:** cost-per-outcome is *known* on their side
   (`cost_limit: 3.0` means ≤ $3 per instance, enforced) and *unknown* on ours. Our metric
   is tokens per accepted outcome. They can state theirs. We cannot state ours. On our own
   chosen metric, the minimal agent is the better-instrumented system.

### 5.2 What this should change

Not "abandon the architecture" — that is not what the evidence supports either. Three
concrete consequences:

- **A minimal-baseline arm belongs in `spec/13`'s evaluation plan.** One worker, one prompt,
  no decomposition, run against the same acceptance criteria as `/standard`. Right now
  `/quick` is the closest thing we have and it is not framed as a baseline. Any workflow
  that cannot beat a single well-prompted agent on tokens-per-accepted-outcome is
  ceremony, and we currently have no way to find out which ones those are.
- **A cost ceiling should stop being grade D by inspection and become grade A by
  measurement.** `spec/key/02:475` says *"Whether OMP has a settings-level cost cap is grade
  D — I did not grep for one"*. I also did not close it: I verified `task.maxRuntimeMs`,
  `task.softRequestBudget`, and `task.agentIdleTtlMs` in
  `config/settings-schema.ts:4644-4692` and found no cost key among them, but I did not
  enumerate all ~607 settings, so **the D stands and I am not upgrading it.** What this repo
  contributes is that a cost ceiling is *worth having* — it is one of only four limits a
  system this minimal chose to keep.
- **Price the diff-reviewer against forced self-inspection before defending it.** The cheap
  arm is M23: require the implementer to read its own diff as a separate step before
  yielding. If that closes most of the false-completion gap, the diff-reviewer spawn is
  optional rather than core. This is the single highest-value experiment this repo suggests,
  and it is cheap to run.

## 6. Cost profile

| §3 row | Where paid | Estimate and basis |
|---|---|---|
| M10 elision | `per-action`, and net-negative | Caps a single observation at ~10 000 chars ≈ 2 500–2 800 tokens (**estimate**, chars/4 for mixed output; their own thresholds at `config/default.yaml:119-140`). Against `MAX_OUTPUT_BYTES` 500 000 (`task/types.ts:53`), worst case improves ~50× |
| M11 truncation-vs-malformation | `zero` | ~40 tokens of contract text. Saves a whole mis-targeted re-spawn on each hit |
| M9 failure-is-observation | `zero` | Prompt wording, no size change. Prevents aborts that cost a full re-spawn |
| M23 separated submission | `zero` marginal in the agent body; **`per-action`** for the extra read | One extra diff read per implementer run (~500–2 000 tokens, **estimate**, scales with diff size). Compare against a diff-reviewer spawn: full system prompt + skill listing + context re-establishment. Roughly an order of magnitude cheaper, and that ratio is the experiment in §5.2 |
| M6 counter reset | `zero` | One clause |
| M5 pre-spawn sizing | `zero` | Coordinator reasoning already in context |
| M13 env hardening | `zero` to state; **reduces** `per-action` | ~30 tokens of env config. Removes progress-bar and pager noise from every captured command. Best ratio in the report |
| M14 abort list | `zero` | One clause. Prevents identical-failure re-spawns, each of which is a full worker's spend |
| M15 trajectory | — | DEFER; no cost until triggered |

Every adopted row is `zero` or negative except the one extra diff read in M23. This upstream
is unusually cheap to learn from precisely *because* it is minimal — there is no
infrastructure to port, only decisions to copy.

## 7. Coverage and limits  (MANDATORY)

**Files read in full (16):**
`src/minisweagent/agents/default.py`, `src/minisweagent/agents/interactive.py`,
`src/minisweagent/exceptions.py`, `src/minisweagent/environments/local.py`,
`src/minisweagent/models/litellm_model.py`,
`src/minisweagent/models/utils/actions_toolcall.py`,
`src/minisweagent/models/utils/actions_text.py`, `src/minisweagent/models/utils/retry.py`,
`src/minisweagent/models/utils/cache_control.py`, `src/minisweagent/config/default.yaml`,
`src/minisweagent/config/mini.yaml`, `src/minisweagent/config/benchmarks/swebench.yaml`,
`src/minisweagent/run/benchmarks/swebench.py`,
`src/minisweagent/run/benchmarks/utils/common.py`, `docs/advanced/control_flow.md`,
`README.md`. Plus `LICENSE.md` head (license determination).

**Files sampled (head/grep only):**
- `docs/faq.md` — first ~80 lines (limitations, why-no-shell-session framing)
- `git ls-files` for the full tree; `wc -l` on the source set
- OMP cross-checks for §2b, opened only to verify the specific lines cited:
  `config/settings-schema.ts:4644-4700`, `tools/yield.ts:380-400` and `:202`,
  `task/types.ts:53-56`

**Not opened:**
- `environments/docker.py`, `singularity.py`, and all of `environments/extra/` (bubblewrap,
  contree, swerex_docker, swerex_modal). I read `local.py` and assumed the others follow the
  same `execute → dict` + `_check_finished` contract. **The `Submitted` detection lives in
  the environment**, so if docker.py detects submission differently, M8's shape may vary by
  environment. Unverified.
- All model adapters other than litellm: `openrouter_*`, `portkey_*`, `requesty_*`,
  `litellm_response_model.py`, `litellm_textbased_model.py`, `models/extra/roulette.py`.
  M14's abort list is litellm-specific and I do not know whether the others match.
- `run/mini.py`, `run/hello_world.py`, `run/utilities/*` (config, inspector,
  mini_extra), `run/benchmarks/programbench.py`, `run/benchmarks/swebench_single.py`,
  `run/benchmarks/utils/batch_progress.py`.
- **`utils/serialize.py` — a real gap.** `recursive_merge` is load-bearing in
  `get_template_vars` (`agents/default.py:53-64`) and in config layering
  (`run/benchmarks/swebench.py:241`). I did not read its precedence rules, so I cannot say
  exactly how conflicting config keys resolve.
- The entire test suite (`test_models.py` and everything under `tests/`). **No claim here is
  corroborated by a test I read.**
- All 4 alternate benchmark configs (`swebench_backticks`, `swebench_modal`, `swebench_xml`,
  `programbench.yaml`), `config/inspector.tcss`, `.github/*`, and most of `docs/`.

**Claims that need a live run before use:**
- The **>74% SWE-bench Verified** figure (`README.md:28`) and the **beats Claude Code and
  Codex on DeepSWE** claim (`README.md:8`) are **grade B — read, not reproduced.** They are
  the empirical foundation of the entire §5 argument. I verified the mechanism that
  *permits* the claim (the loop is real and this small); I did not verify the number. A
  reader should treat §5 as "the strongest available argument", not as a proven refutation.
- The §5.2 M23-vs-diff-reviewer comparison is the experiment, not a result. My "order of
  magnitude cheaper" is arithmetic on spawn overhead, not a measurement.

**Anything I suspect but could not verify:**
- I suspect their >74% depends materially on `/testbed` being pre-built and on the oracle
  test suite, i.e. that the same agent on a cold repo with no oracle would score far lower.
  `swebench.yaml:116` and the docker image wiring (`run/benchmarks/swebench.py:68-94`)
  support the pre-built part; the counterfactual is untestable from source. This is the
  weakest joint in §5's argument **in our favour**, and I want it on record as a suspicion
  rather than smuggled in as a rebuttal.
- I suspect `max_consecutive_format_errors = 3` and `cost_limit = 3.0` are tuned constants
  with no published derivation — no comment or doc explains either. Same folklore-constant
  risk as 12-factor's "~3". That OMP independently uses 3 for `MAX_SCHEMA_RETRIES` is
  convergence, not corroboration.
- I suspect but did not verify that a forced-partial-yield in OMP produces a result which
  *passes* our output schema (the KD-011 danger). What I did verify is adjacent and worse:
  after 3 schema failures OMP **drops the schema and accepts the data**
  (`tools/yield.ts:388-399`). Whether the *budget* force-stop path also bypasses validation
  needs a live run.

