# Audit Coverage Matrix

## Closure semantics

Every row must end as one of:

- `PASS_EVIDENCED` — independently checked and no material contradiction found;
- `FINDING` — linked to one or more report finding IDs;
- `ENVIRONMENT_UNVERIFIED` — exact unavailable prerequisite named, with static/scratch checks
  completed as far as safe;
- `NOT_APPLICABLE` — reason proves the path cannot affect this candidate; or
- `STALE_PACKET` — candidate identity changed and substantive audit stopped.

`READ` or `VALIDATOR_PASS` alone is not a closure state.

| ID | Concern | Required invariant | Primary surfaces | Minimum adversarial probe |
|---|---|---|---|---|
| C-01 | Prefix-free entry and sizing | Plain requests route normally; Quick is validated; Tech Lead selects Standard/Orchestrated by task structure | Commands, task triage, Tech Lead docs, KD-026, spec/04 | Ambiguous request, mislabeled Quick, and Orchestrated request with only one inseparable unit |
| C-02 | Reclassification/lifecycle | Escalation or reduction preserves valid work and identity; material contract change opens a linked task | Topic 02 lifecycle core, commands, Topic 04 state | Reclassify after discovery and after candidate freeze; verify no stale evidence survives mutation |
| C-03 | Topology/dispatch benefit | Inline is default; only cheap-scout/worker/reviewer are spawnable; no fixed or unconditional chain | Behavior manifest, agents, commands, installer retirement, KD-027 | No-benefit task, unavailable optional agent, and stale retired-agent file in target |
| C-04 | Exact model/effort/fallback | Cheap Scout Flash xhigh→Pro xhigh only; Worker high/xhigh by decision; selected Reviewer exact xhigh; no implicit downgrade | Config, model routing spec, managed request/receipt, OMP source | Role override, auth fallback, retry fallback, maxEffort cap, wrong returned model/role/effort |
| C-05 | Provider/gateway authority | OmniRoute is the only gateway; no model call starts without explicit authority/budget/mode | Config, runner, evaluator, security policy | Missing credentials, zero budget, default runner, malicious fixture requesting provider execution |
| C-06 | Structured result and false completion | Schema validity is necessary but never proves provenance, completeness, tool success, or acceptance | Agent output blocks, managed boundary, schemas/contracts, KD-002–004/019 | Malformed schema, schema unavailable, valid-shaped false yield, forced partial, tool `success:false` |
| C-07 | Capability gates and plan mode | Same selected contract fails closed when required tools/settings/runtime are unavailable; only an explicit different contract may continue | OMP source pins, preflight, request envelope, receipt | LSP registered but no applicable server; disabled grep/glob/web/bash; plan-mode tool stripping |
| C-08 | Durable authority/CAS | Only lease owner mutates authority; revision/hash/generation and worktree/scope reservations prevent stale or competing writers | Topic 04 core and schemas | Concurrent writer, stale revision, direct edit, wrong worktree, lease takeover without owner authority |
| C-09 | Candidate/evidence identity | Acceptance evidence binds exact candidate, contract, inputs, producer, environment, and validity triggers | Topic 04 candidate/evidence core; review/eval consumers | Byte drift, added untracked file, replay across C1/C2, partial artifact, changed acceptance input |
| C-10 | Handoff/recovery/retention | Handoff is two-phase; crash recovery is explicit; cleanup is dry-run/recoverable and never manages Git worktrees | Topic 04 transfer/retention, installer/uninstaller | Interrupted handoff, stale lock, archive live task, path/symlink escape, wrong confirmation/root |
| C-11 | Worktree boundaries | One mutating task per authoritative worktree; subordinate output remains provisional; shared Git-common state resolves correctly | State discovery/binding; managed dispatch | Main vs linked worktree, nested repo/submodule, detached head, subordinate patch not integrated |
| C-12 | Progressive retrieval | Native default; bounded escalation/skips disclosed; Cheap Scout fail-soft; freshness failure does not become confident answer | Retrieval docs, Cheap Scout, Topic 05 core | Missing Context7/web/tool, oversized result, invalid skip reason, scout failure after partial retrieval |
| C-13 | CodeGraph optionality/supply chain | Default-off, explicit pinned install, verified artifact, worktree-local index, no policy/authority role | CodeGraph component, provisioning, retrieval tool, registry | Wrong version/hash/platform, corrupt archive, path escape, worktree mismatch, unavailable binary |
| C-14 | Managed agent boundary | Request validated before native task; receipt validated before lifecycle use; child cannot accept/mutate parent authority | Topic 06 extension/contracts/core | Replay, wrong task/candidate/model, forged producer, untrusted external capability, child state mutation |
| C-15 | Context pressure/continuity | Pressure aborts before provider; explicit compaction uses valid kernel; summary never replaces authority | Topic 07 extension/core/state | Threshold boundary, provider sentinel, stale/tampered kernel, compact failure, child pressure result |
| C-16 | Portable behavior/adapters | Selected behavior injected exactly once; external adapters/tools have no policy/workflow authority; Claude stays non-installable | Behavior manifest, Topic 08 gates/tool, installer | Duplicate injection, unknown adapter, policy-bearing external tool, Claude install attempt |
| C-17 | Skills/rules/autoload | Only selected resolvable skills/rules load; trigger semantics and caps are enforced; missing selected capability fails correctly | Skill lock, installed skills, agents, behavior gates | Missing skill, hash drift, duplicate trigger, cap overflow, unselected skill treated as mandatory |
| C-18 | Verification/review quality | Verification is fresh and candidate-bound; Reviewer is risk-selected and exact xhigh; severity and re-review rules are coherent | Spec/10, Phase 04, reviewer, Round Q fixtures | Mutation after review, same-session/non-independent review, Important finding falsely waived |
| C-19 | Security/trust/secrets | Untrusted content cannot gain instruction/authority; secrets are neither captured nor echoed; retries/side effects are bounded | Spec/15, state/evidence sanitation, Round S fixtures | Secret-shaped output, malicious repository text, repeated side effect, symlink/path traversal |
| C-20 | Install/repair/uninstall/rollback | Dry-run default; exact target; backup before mutation; custom/user state preserved; stale selected-owned files retired safely | Installer, uninstaller, manifests, Topic 03/04/05/08/Round tests | Existing custom file, partial failure, repair, unknown component, wrong backup, retained `.agent-tasks` |
| C-21 | Evaluation/promotion validity | Deterministic default starts zero model processes; only closed verdicts; incomplete/pilot/environment-blocked evidence cannot promote | Topic 01 model, Round evaluator/runner/fixtures | Missing usage, small pilot, optional stopping, budget exhaustion, unavailable runtime, default invocation |
| C-22 | Evidence/capture integrity | Capture is bounded, transactional, hash-verified, candidate-aware, and does not self-validate stale output | Evidence manifests/capture scripts | Interrupted capture, tampered record/hash, manifest mismatch, random/temp path nondeterminism |
| C-23 | Phase/spec/implementation coherence | Active KD/spec/phase/runtime/docs describe one current contract; history is fenced and status is truthful | KD-024–032, spec/README, phases, operator docs | Search semantic equivalents of a confirmed contradiction, then trace only active consumers |
| C-24 | Workspace/package hygiene | Scratch, nested worktrees, raw transcripts, credentials, and local telemetry cannot ship or become authority | `.gitignore`, inventory, installer manifests, `.tmp-*`, `.claude`, eval results | Secret scan, governed-file inventory comparison, accidental recursive packaging of scratch roots |

## Depth policy

For C-01 through C-24, inspect at least one success path and the named negative path or an equally
stronger existing negative proof. Spend additional depth when:

- the path can mutate user data, state authority, credentials, Git, or external systems;
- a failure can look like successful completion;
- runtime settings/model fallback can silently change the selected contract;
- evidence is used for acceptance/promotion; or
- two active authority surfaces disagree.

Stop broadening a finding when all active consumers of the same contract are mapped. Do not launch
another repository-wide synonym hunt unless the first confirmed defect demonstrates that the
existing guard systematically misses semantic equivalents.

## Coverage accounting

The report must include:

- one row for every C-01 through C-24 ID;
- manifest entry counts by `scope_class` and confirmation that their sum equals the snapshot count;
- every `FINDING` linked to a unique finding ID;
- every `ENVIRONMENT_UNVERIFIED` linked to an exact missing prerequisite and safe evidence already
  collected; and
- an explicit statement that no live install, provider call, credential mutation, Git mutation, or
  source edit occurred.
