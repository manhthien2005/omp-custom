# Defect Repair, OMP 17.2.10 ↔ 17.2.12 Parity, and Unfixable-Without-Live-Run Ledger

Date: 2026-08-20. Author: Claude (Opus 5). Repository: `omp-custom` @ `main`.
Nothing in this report is independently re-verified by Codex, merged, released, promoted, or
production-ready. No provider call, model process, credential read, or live install was involved.

---

## 1. Version parity — is 17.2.12 different from 17.2.10?

**Verdict: no contract-relevant difference. Stay on the current pin. Do not downgrade.**

The repository pins OMP source at commit `3a8591a8af5b6d200088d12ca75a5517cb064fa8` (= 17.2.10) in
`registry/upstreams.yml` and `registry/omp-compatibility.yml`, and declares
`continuity_supported_versions: "17.2.10,17.2.12"`. The installed binary is 17.2.12. The question is
whether that pairing is safe.

Method: a shallow 17.2.12 source tree (`45e12e5`, `@oh-my-pi/*` package version `17.2.12`) was
compared file-by-file against the pinned 17.2.10 tree, then narrowed to the exact surfaces this
template contracts against.

### 1.1 Whole-tree scope

845 files differ between the two trees. That number is not the risk measure — most of it is code this
template never reads. The risk measure is the 13 `watched_paths` in `registry/upstreams.yml`, which
are the only source seams any contract depends on.

| Watched path | 17.2.10 vs 17.2.12 |
|---|---|
| `packages/coding-agent/src/discovery/builtin.ts` | byte-identical |
| `packages/coding-agent/src/task/discovery.ts` | byte-identical |
| `packages/coding-agent/src/task/agents.ts` | byte-identical |
| `packages/coding-agent/src/task/structured-subagent.ts` | byte-identical |
| `packages/coding-agent/src/task/isolation-runner.ts` | byte-identical |
| `packages/coding-agent/src/tools/yield.ts` | byte-identical |
| `packages/coding-agent/src/config/model-resolver.ts` | byte-identical |
| `packages/coding-agent/src/config/model-roles.ts` | byte-identical |
| `packages/coding-agent/src/discovery/helpers.ts` | differs (32 lines) |
| `packages/coding-agent/src/task/index.ts` | differs (27 lines) |
| `packages/coding-agent/src/task/executor.ts` | differs (29 lines) |
| `packages/coding-agent/src/config/settings-schema.ts` | differs (35 lines) |
| `packages/utils/src/frontmatter.ts` | differs (58 lines) |

Eight of thirteen are byte-identical. The five that differ were read line by line.

### 1.2 Settings surface — the one that governs installed behaviour

Full key-set extraction from `settings-schema.ts`: **414 keys in 17.2.10, 411 in 17.2.12.** The
delta is three removals and zero additions:

```
removed in 17.2.12: exa.enableResearcher, exa.enableSearch, exa.enableWebsets
added in 17.2.12:   (none)
```

None of the three is referenced anywhere in this repository. Every default the template pins is
identical across both versions:

| Setting | 17.2.10 | 17.2.12 |
|---|---|---|
| `lsp.enabled` | `true` | `true` |
| `task.isolation.mode` | enum, `none` first | enum, `none` first (same line 4449) |
| `task.isolation.apply` | `true` | `true` |
| `task.batch` | `true` | `true` |
| `task.enableLsp` | `false` | `false` |
| `task.softRequestBudget` | `200` | `200` |
| `tools.intentTracing` | `true` | `true` |

`SETTINGS-001` in `registry/omp-compatibility.yml` therefore holds on both versions.

### 1.3 The four remaining drifted files, claim by claim

Six verified claims name a drifted file. Each was re-checked semantically, not by hash:

| Claim | File | 17.2.12 change | Claim still true? |
|---|---|---|---|
| `FM-001` | `discovery/helpers.ts` | plugin-manifest read is now symlink-contained and also accepts a root `plugin.json` | Yes — `parseAgentFields` present once, `yield` append intact in both |
| `FM-002` | `utils/frontmatter.ts` | `normalizeKeys` renamed/exported as `normalizeFrontmatterKeys`; new `repair` and `rawKeys` opt-ins | Yes — recursive kebab→camel normalization is still the default path |
| `TASK-001` | `task/index.ts` | adds `refreshAgentDiscovery` plus a published discovery snapshot for plugin reloads | Yes — `task.batch` shape control and per-spawn `isolated` normalization unchanged (6 and 10 sites in both) |
| `SKILL-001` | `task/executor.ts` | none in this region | Yes — `autoloadSkills` × 3, `sendCustomMessage` × 4 in both |
| `BOUNDARY-004` | `task/executor.ts` | none in this region | Yes — `softRequestBudget` × 22, `stopThreshold` × 3, `× 1.5` × 2 in both |
| `CONT-008` | `task/executor.ts` | `Settings.isolated` gains a second `{ storage }` argument so subagents share the parent storage handle | Yes in substance — isolated effective settings are still constructed per bounded subagent |

`CONT-008` is the only claim whose *pinned line-range hashes* move: `854-906` →
`2668ca62…` (17.2.10) vs `91e1c6a4…` (17.2.12), and `3128-3260` → `9530bc58…` vs `f2d0c67e…`. Two
causes, both benign: a three-line file growth (3431 → 3434) shifts the second window, and
`Settings.isolated` genuinely gained an argument. The substance — isolated settings per bounded
subagent, init before first prompt — is unchanged. Those hashes are pinned against the *pinned
17.2.10 source*, which is what `T07-SOURCE-ATTACHMENTS` hashes, so no contract is currently reading
17.2.12 bytes and no gate is affected.

### 1.4 Conclusion

Mark it OK. Downgrading the declared pin to make 17.2.10 the only supported runtime would (a) delete
the working 17.2.12 canary arm, (b) rewrite `continuity_supported_versions`, three source files, and
several spec anchors, and (c) buy nothing, because every surface the template contracts against is
already equivalent. The honest two-version claim is the accurate one.

Caveat stated plainly: this is a **source-level** parity proof over the contracted seams plus the
complete settings key set. It is not a behavioural equivalence proof of the two compiled binaries.
Full behavioural parity needs the second runtime canary, which is section 3's `OPEN-T07-RUNTIME-02`.

---

## 2. What was fixed, and what the fix bought

Nine defects were found and repaired. Seven were invisible to every validator — the Pester-hosted
suites exit `0` even when individual `It` blocks fail, so the failures only ever appeared as `[-]`
lines that nothing counted.

| # | Defect | Root cause | Fix | Before → after |
|---|---|---|---|---|
| 1 | `task` tool rejected by OpenAI-responses strict-function validation | root `Type.Union` serializes to a bare `{ anyOf: [...] }` with no root `type`; `enforceStrictSchemaBody` treats `anyOf` as a satisfied combinator and never adds one | closed root object, all seven properties optional; `core.validateManagedRequest` stays the sole shape authority | hard 400 on every managed dispatch → dispatch accepted |
| 2 | CodeGraph state digest mismatch | `.omp/state/manifest.json` pin was stale in `codegraph/component-manifest.json` | re-pinned to `b70bc7b4…` | install-time manifest verification failed → passes |
| 3 | Token ledger double-counted cached context | basis was `input + output` with `cacheRead` summed separately, so a re-read context inflated the ledger every turn | basis is `input + output + cacheWrite`; a provider omitting any of the four leaves the ledger `not_measured` rather than estimated | measured 15/24/39 → correct 21/25/46 on the reference stream |
| 4 | `T07-EVIDENCE` accepted a manifest with failing cases | it checked status/blocker/counts but never the per-case verdicts | added `cases ≥ 8` and `no case with status ≠ PASS` | a partially-failing capture could pass → cannot |
| 5 | `topic06-validator-mutations` mutation was version-coupled | literal `"component_version": "1.0.0"` → `"2.0.0"` string replace | regex over `\d+\.\d+\.\d+` → `"0.0.0"` | silently stops mutating after any version bump → version-agnostic |
| 6 | `topic02-workflow-lifecycle` fixture contradicted the contract | fixture wrote `template/.omp/commands/quick.md` = `'restart as Standard'`, which the Topic 07 continuity contract rejects | fixture now carries the real continuity text for all three commands, plus KD-031 authority rows | stale fixture → 142 assertions green |
| 7 | `phase00-t003` fixture was incomplete | `$t003FixturePaths` omitted `template/.omp/schemas/verification-result.schema.yml`, which `topic-03/manifest.yml` requires; `P00-T003-LATER-SUPERSESSION` then failed and cascaded through `$laterSupersessionOk` into 11 destination rows | added the one path | 30 passed / **7 failed** → **37 passed / 0 failed** |
| 8 | `phase00-wave-a` integration test asserted the wrong exit code | two layered causes: an inherited `PSModulePath` let pwsh 7's `Microsoft.PowerShell.Utility` shadow the native 3.1.0.0 copy inside `powershell.exe` 5.1, so `Get-FileHash` vanished and 11 hash contracts threw; and the surviving four failures are the *intentional* pwsh-7.4 gates, so exit `1` is correct | pin the native module path inside the test; assert the exact failure set `R0912-PWSH,T06-PWSH,T07-PWSH,T08-PWSH` and `exit 1` | 25 passed / **1 failed** → all green |
| 9 | `phase00-e1` hid the supersession branch and then demanded nine matching pins | the suite dot-sources only `phase00-e1-evidence.ps1`, but `P00-E1-PROTECTED-SURFACE` resolves superseded drift by calling `Test-Phase00T003LaterProductSupersessionContract`, which lives in the *main* `phase00-evidence.ps1`. Unhosted, that branch could never fire, the fixture builder hard-failed copying four agent files Topic 03 retired, and one assertion still demanded `MatchedCount = 9` — which would require rewriting frozen Phase 00 evidence to absorb a later product decision | load the main helper first (re-loading the E1 helper restores its StrictMode 2.0); the fixture copies the Topic 03 manifest, the T-00.3 conclusion it binds, and every `current_files` row, and skips pins the repository no longer carries; the pin assertion now states the exact six-path superseded drift set and requires `P00-E1-PROTECTED-SURFACE` to be `PASS` | 69 passed / **8 failed** → **77 passed / 0 failed** |

Defect 9's fix was checked against false-PASS: with the supersession branch live, mutating
`agent-result.schema.yml`, tampering with any `sha256` in the Topic 03 manifest, deleting that
manifest, mutating a selected agent (`worker.md`), or mutating the immutable T-00.3 conclusion each
still drives `P00-E1-PROTECTED-SURFACE` to `FAIL`. The branch narrows the allowed drift; it does not
weaken the gate.

### 2.1 Verification after the repairs

| Surface | Result |
|---|---|
| `scripts/validate-template.ps1` | `356 passed, 1 warnings, 0 failed` |
| 8 focused validators | 649 / 22 / 41 / 25 / 19 / 22 / 17 / 16 PASS, 0 WARN, 0 FAIL each |
| 43 pwsh test suites | 0 failures; `[-]` count 0 in every Pester-hosted suite |
| 16 node suites | 164 tests, `fail 0` |
| `topic07-pressure-canary` (17.2.10 provisioned) | `PASS … 26 assertions; 2 available runtime(s)` |
| `evidence-byte-integrity.Tests.ps1` | 21 assertions PASS |
| `capture-candidate-snapshot.Tests.ps1` | 22 PASS |
| `repair-evidence-byte-integrity.ps1` | `Exact=950 Recoverable=0 Unrecoverable=5 Missing=0 Invalid=20 Ambiguous=0` |

`Recoverable = 0`, `Missing = 0`, `Ambiguous = 0` means no EOL damage and no lost file. The 20
`invalid` rows are exactly this change set plus the earlier README redesign — `950 + 20 = 970`, the
original `Exact` count, so no unrelated snapshot row drifted. See the "Post-snapshot authorized
revisions" section of `codex-reproducible-byte-integrity-changelog.md`.

### 2.2 One deliberate non-change

`template/.omp/AGENTS.md` trips an advisory `approx-token-budget above target (1365 > 1200)` warning.
It is left byte-identical at 5465 bytes. Two audit artifacts record that warning as the sanctioned
baseline — `06-KNOWN-LIMITATIONS.md:42-50` and `05-SAFE-VERIFICATION-PLAYBOOK.md:120-123` — and
`CLAUDE-REPO-CLEANUP-RESTRUCTURE-README-PUBLISH-PROMPT.md:50-51` states it explicitly: *"The known
warning is the existing approximate token-budget advisory for template/.omp/AGENTS.md."* The file is
hash-pinned in four places (`topic-07/manifest.json`, `topic-03/manifest.yml`, and both frozen audit
snapshots), and its lines 45-47 are pinned verbatim by `topic05-routing.Tests.ps1`. Trimming it would
break governed pins to clear a warning the governance documents deliberately keep. That is a bad
trade; the correct action is no action.

---

## 3. Cannot be fixed by static work — needs a real run

Each row below is blocked on something outside a deterministic, zero-provider, local-only session.
None is a code defect I declined to fix.

| Blocker | What it needs | Why static work cannot close it |
|---|---|---|
| `OPEN-T07-RUNTIME-02` — second runtime canary | An owner decision on how 17.2.10 is provisioned, then a promotion flip | The canary now **passes** on both versions with `OMP_TOPIC07_17_2_10_PATH` set (26 assertions, 2 runtimes). But `Resolve-Topic07RuntimeMatrix` only reports `READY_FOR_PROMOTION_CANARY` when a *durable* path resolves — the env var or `tools/runtime-cache/omp/17.2.10/omp.exe`. My binary sits outside the repo, so an ad-hoc env var is not durable evidence. Flipping the status also rewrites `T07-EVIDENCE`, `T07-TRUTHFULNESS`, `registry/omp-compatibility.yml`, the Topic 07 changelog, ~9 lib sites, and dozens of spec/docs anchors. **Recommendation: keep `IMPLEMENTED_NOT_PROMOTED` and record the canary pass as new evidence.** |
| DeepSeek provider smoke | Real OmniRoute credentials + `~/.omp/agent/models.yml` | Credentials are forbidden in this repository (`README.md:125`, `.gitignore`). The fallback contract is verified deterministically; the live route is not. |
| Model-assisted promotion campaign (`provider_smoke = NOT_RUN_MODEL_FREE_CAMPAIGN`) | Separately authorized spend | The evaluator starts zero provider/model processes by design. Deterministic fixtures cannot substitute for provider quality or economics. |
| CodeGraph model/provider campaign | Authorized paid campaign | Recorded inconclusive; native retrieval stays the default and CodeGraph stays default-off. |
| `CLAUDE_RUNTIME_NOT_VERIFIED` (Claude adapter) | A live Claude runtime | The adapter is `DESIGNED_NOT_VERIFIED` and non-installable. Only the static mapping can be reviewed. |
| `SCRATCH_PROOF_NOT_LIVE_INSTALL` | An owner-selected real project + approved apply | Topic 12 proved the package only in disposable Git projects. A scratch proof is not a live-safety proof. |
| `OPEN-T06-RUNTIME-01_NONBLOCKING` / `unrelated_vibe_eval_internal_agents = UNMANAGED` | A live OMP session exercising Vibe / `eval` / internal agents | Those paths are outside the managed boundary by construction; nothing static can produce a managed receipt for them. |
| `parent_acceptance = NOT_GRANTED_BY_RECEIPT` | A human Tech Lead accepting real work | Deliberate: a receipt is provisional evidence, never acceptance authority. |
| `T07-EVIDENCE` / `T07-EVIDENCE-HASHES` mutation coverage | A mutation harness that can run with evidence enabled | `topic07-validator-mutations.Tests.ps1` runs everything with `-SkipEvidence -SkipRuntime`, so those two codes have no mutation coverage. Enabling them means regenerating live evidence per mutation. Known gap, not a false PASS. |
| 5 permanent `unrecoverable` byte-integrity paths | Nothing — closed by decision | Normalized-text-equivalent but not raw-byte reproducible; accepted Git-LF hashes are pinned in the CLI's closed-limitation set (`byte-integrity-recovery.md`). Not reconstructed, not replaced. |
| Fresh-clone green validator | Provisioning `_research/upstreams/oh-my-pi` at `3a8591a` | `.gitignore:2` deliberately excludes it, so a clone fails `P00-REG-WATCHED-MISSING`, `T07-SOURCE-ATTACHMENTS`, `T08-SOURCE-ATTACHED` until provisioned. Documented environment prerequisite, not a regression. |
| `CLAUDE-F-001 = FIXED_PENDING_CODEX_REVERIFICATION` | An independent Codex pass | Self-review cannot satisfy an independent-reverification gate. |
| `AGENTS.md` token advisory | An owner decision to re-pin four hashes | See §2.2. Fixable in principle, wrong to fix in practice. |
| `git diff --check` reporting CR-at-EOL | Nothing — inherent | Restoring historical CRLF bytes necessarily trips Git's default whitespace rule. `core.whitespace=cr-at-eol` exits `0`, proving CR-at-EOL is the only finding. |

---

## 4. Standing non-claims

- Deterministic, zero-provider verification only. No live install, no promotion, no release.
- Promotion verdict remains `DEFER_INCONCLUSIVE`; the OMP adapter remains `IMPLEMENTED_NOT_PROMOTED`.
- No credential was read, written, or requested. No snapshot hash, packet hash, or frozen audit
  artifact was edited to absorb any change in this round.
- Source-level parity across contracted seams is not behavioural equivalence of two binaries.
