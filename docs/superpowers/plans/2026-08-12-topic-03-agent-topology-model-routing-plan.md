# Topic 03 Agent Topology and Model/Provider Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Execution selection:** Inline execution with checkpoints. The user explicitly does not
> prioritize subagent execution unless a spawn has a concrete benefit; this plan itself has no
> such independent work unit.

**Goal:** Replace the fixed five-agent runtime with a benefit-gated Tech Lead plus Cheap Scout,
Worker, and Reviewer topology, configure DeepSeek V4 Flash `max` with V4 Pro `max` fallback, and
prove routing, effort, installation, and fallback behavior without making Opus mandatory.

**Architecture:** The main session remains the Tech Lead and default writer. Project configuration
owns logical role aliases and the Scout-only fallback chain; three agent files own their bounded
contracts. A focused Topic 03 validator enforces the selected manifest and active spec projection,
while a new current-product evidence record supersedes—but never rewrites—the Phase 00 prompt
snapshot. DeepSeek environment setup is attempted first and may be recorded as
`ENVIRONMENT_BLOCKED` without blocking topology/spec/runtime work.

**Tech Stack:** Markdown specs/prompts, YAML OMP configuration, PowerShell 5.1 validators and
installer tests, OMP 17.2.x CLI, local OmniRoute Docker gateway at `127.0.0.1:20128`, DeepSeek V4,
Git path-scoped inspection.

## Global Constraints

- The main-session Tech Lead is the default writer and final owner; it is never a spawned agent.
- Default to no subagent spawn. Every spawn must have a stated benefit, bounded contract, output,
  stop condition, and fallback.
- The selected spawnable manifest is exactly `cheap-scout`, `worker`, and `reviewer`.
- Cheap Scout is read-only and advisory. It cannot edit, verify acceptance, review, integrate, or
  issue a final verdict.
- Cheap Scout routing is gateway model ID `ds/deepseek-v4-flash` at provider `max`, then
  `ds/deepseek-v4-pro` at provider `max`, then Tech Lead retrieval.
- In OMP, use the full selectors `omniroute/ds/deepseek-v4-flash:xhigh` and
  `omniroute/ds/deepseek-v4-pro:xhigh`; the `xhigh` compatibility mapping emits DeepSeek `max`.
- Worker defaults to exact `high`; the Tech Lead selects the model-relative highest permitted
  effort (`effort: hi`, capped at `xhigh`) only for difficult tasks.
- Reviewer is fixed at exact `xhigh`; the Tech Lead may not lower it for convenience.
- One General Reviewer is risk-gated. Specialist concerns are packet profiles, not permanent
  agent files.
- Opus is preferred when suitable and available, never implicitly mandatory. Same-model review
  in a separate session is valid with disclosure.
- One writer is the default. Parallel writers require disjoint scopes, proven isolation/capture,
  and sequential integration; otherwise use one sequential writer.
- Availability fallback is disclosed. Quality failure never silently changes a candidate model.
- Preserve every pre-existing dirty-worktree change. Do not reset, revert, or overwrite unrelated
  work. Treat `_research/upstreams/oh-my-pi` and `.claude/worktrees/*` as read-only.
- Do not expose, copy into the repository, log, or commit API keys, cookies, access tokens, or
  OmniRoute authentication material.
- `C:/Users/MrThien/.omp/agent/models.yml` is user-owned and installer-protected. Back it up before
  a scoped edit; never replace the whole file.
- Historical `docs/evidence/phase-00/**` conclusions are immutable. Later product state receives a
  new evidence identity and validator-recognized supersession mapping.
- Files already dirty before Topic 03 are not staged or committed as Topic 03-only work. New
  Topic 03 files may be committed path-by-path; existing-file consolidation requires a separate
  explicit user decision.

## File Structure and Ownership

### Environment and focused validation

- Create: `scripts/lib/topic03-deepseek-routing.ps1` — catalog/evidence validation functions.
- Create: `scripts/tests/topic03-deepseek-routing.Tests.ps1` — pure fixture/mutation tests; no
  provider calls.
- Create: `scripts/run-topic03-deepseek-smoke.ps1` — explicit provider-call smoke runner.
- Create: `scripts/lib/topic03-topology-routing.ps1` — focused static contract functions.
- Create: `scripts/tests/topic03-topology-routing.Tests.ps1` — mutation tests for every
  load-bearing topology/routing rule.
- Create: `scripts/validate-topic03-topology-routing.ps1` — focused validator entry point.
- Create: `docs/evidence/current-product/topic-03/manifest.yml` — post-Phase-00 evidence identity.
- Create on successful smoke: `docs/evidence/current-product/topic-03/deepseek-smoke.yml`.

### Canonical authority and projections

- Rewrite active authority: `spec/03-agent-topology.md`, `spec/09-model-routing.md`.
- Append decision: `spec/key/04-decision-log.md` as KD-027.
- Project: `spec/key/01-dna.md`, `spec/01-target-architecture.md`,
  `spec/02-runtime-semantics.md`, `spec/05-context-and-token-model.md`,
  `spec/06-structured-output.md`, `spec/08-isolation-and-concurrency.md`,
  `spec/10-verification-and-review.md`, `spec/12-installation-and-rollback.md`,
  `spec/13-validation-and-evaluation.md`, `spec/14-upgradeability-and-governance.md`,
  `spec/15-security-and-failure-recovery.md`, `spec/16-migration-plan.md`, `spec/README.md`.
- Project phase ownership: `spec/phases/phase-01-runtime-correctness.md`,
  `phase-02-core-orchestration.md`, `phase-03-context-efficiency.md`,
  `phase-04-quality-system.md`, `phase-05-installation-hardening.md`,
  `phase-06-evaluation.md`, `phase-07-stabilization.md`.

### Runtime and installation

- Create: `template/.omp/agents/cheap-scout.md`.
- Create: `template/.omp/agents/worker.md`.
- Modify: `template/.omp/agents/reviewer.md`, `template/.omp/AGENTS.md`,
  `template/.omp/commands/quick.md`, `standard.md`, `orchestrated.md`,
  `template/.omp/config.yml`.
- Create: `docs/roles/tech-lead.md`.
- Retire from agent discovery: `template/.omp/agents/tech-lead.md`, `explorer.md`,
  `implementer.md`, `verifier.md`.
- Modify: `scripts/install-template.ps1`, `scripts/validate-template.ps1`,
  `scripts/lib/phase00-evidence.ps1`, `scripts/tests/phase00-t003.Tests.ps1`.
- Create: `scripts/tests/topic03-installer.Tests.ps1`.

### Human documentation and handoff

- Modify: `README.md`, `CHANGELOG.md`, `docs/architecture.md`, `docs/customization.md`,
  `docs/installation.md`, `docs/workflow-v0.md`, `docs/policies/model-routing.md`,
  `docs/policies/quality-gates.md`, `docs/security.md`, `docs/token-strategy.md`,
  `docs/report-design.md`, `docs/final-report.md`.
- Modify authority fences/registries only where they still present the old roster as current:
  `docs/research/conflict-matrix.md`, `docs/research/final-adoption-plan.md`,
  `registry/adoption-ledger.yml`.
- Create: `codex-topic03-agent-topology-model-routing-changelog.md`.

---

### Task 1: Configure and prove the DeepSeek Scout route first

**Files:**
- Create: `scripts/lib/topic03-deepseek-routing.ps1`
- Create: `scripts/tests/topic03-deepseek-routing.Tests.ps1`
- Create: `scripts/run-topic03-deepseek-smoke.ps1`
- Create/update: `docs/evidence/current-product/topic-03/deepseek-smoke.yml`
- Modify outside repository: `C:/Users/MrThien/.omp/agent/models.yml`
- Configure through local OmniRoute UI/API: model IDs `ds/deepseek-v4-flash` and
  `ds/deepseek-v4-pro`

**Interfaces:**
- Consumes: OmniRoute `GET /v1/models`, OMP `models --json`, OMP print-mode JSON events.
- Produces: `Test-Topic03DeepSeekCatalog`, `Test-Topic03DeepSeekSmokeEvidence`, and a runner whose
  terminal state is exactly `PASS`, `FAIL`, or `ENVIRONMENT_BLOCKED`.
- Produces for later tasks: full OMP selectors
  `omniroute/ds/deepseek-v4-flash:xhigh` and
  `omniroute/ds/deepseek-v4-pro:xhigh`.

- [ ] **Step 1: Record the non-secret environment baseline**

Run:

```powershell
omp --version
docker inspect omniroute --format '{{.Config.Image}}'
$gatewayModels = (Invoke-RestMethod 'http://127.0.0.1:20128/v1/models').data.id
$gatewayModels | Where-Object { $_ -match 'deepseek|^ds/' } | Sort-Object
omp models --json | Select-String -Pattern 'deepseek-v4|ds/'
Get-FileHash -Algorithm SHA256 'C:\Users\MrThien\.omp\agent\models.yml'
```

Expected baseline on 2026-08-12: OMP `17.2.12`, OmniRoute image
`diegosouzapw/omniroute:3.8.49`; the exact `ds/deepseek-v4-flash` and
`ds/deepseek-v4-pro` routes are not yet advertised. Do not print API-key values.

- [ ] **Step 2: Write the failing pure validator tests**

The test script must assert these exact cases against in-memory arrays/objects:

```powershell
$requiredGateway = @('ds/deepseek-v4-flash','ds/deepseek-v4-pro')
$requiredOmp = @(
  'omniroute/ds/deepseek-v4-flash',
  'omniroute/ds/deepseek-v4-pro'
)

# Complete fixture -> zero FAIL.
# Missing Flash gateway ID -> T03-DS-GATEWAY-FLASH-MISSING.
# Missing Pro OMP entry -> T03-DS-OMP-PRO-MISSING.
# Flash without reasoning=true -> T03-DS-FLASH-REASONING.
# Missing xhigh:max map -> T03-DS-EFFORT-MAP.
# Evidence state outside PASS|FAIL|ENVIRONMENT_BLOCKED -> T03-DS-EVIDENCE-STATE.
# Evidence containing api_key/token/secret material -> T03-DS-EVIDENCE-SECRET.
```

Run:

```powershell
pwsh -NoProfile -File scripts/tests/topic03-deepseek-routing.Tests.ps1
```

Expected: FAIL because `scripts/lib/topic03-deepseek-routing.ps1` does not exist.

- [ ] **Step 3: Implement the minimal pure helper**

Use `{ Status, Code, Message }` records. `Test-Topic03DeepSeekCatalog` takes explicit
`-GatewayModelIds` and `-OmpModels` inputs so tests never call a provider. Model checks require:

```powershell
Gateway IDs: ds/deepseek-v4-flash, ds/deepseek-v4-pro
OMP provider/id: omniroute + ds/deepseek-v4-flash, omniroute + ds/deepseek-v4-pro
reasoning: true
thinking range: high..xhigh
reasoningEffortMap.high: high
reasoningEffortMap.xhigh: max
```

`Test-Topic03DeepSeekSmokeEvidence` rejects keys or values matching
`(?i)(api[_-]?key|access[_-]?token|authorization|bearer\s+|secret)` and validates the closed
status enum.

Run the tests again. Expected: all assertions pass with zero provider calls.

- [ ] **Step 4: Back up the two external state owners before mutation**

Run:

```powershell
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Copy-Item -LiteralPath 'C:\Users\MrThien\.omp\agent\models.yml' `
  -Destination "C:\Users\MrThien\.omp\agent\models.yml.topic03-$stamp.bak"
docker exec omniroute sh -lc "cp /app/data/storage.sqlite /app/data/db_backups/topic03-$stamp-before-deepseek.sqlite"
```

Expected: both backup paths exist. If either backup fails, stop external mutation but continue
Tasks 2–7; record Task 1 as `ENVIRONMENT_BLOCKED`.

- [ ] **Step 5: Configure the two OmniRoute gateway model IDs**

Use the authenticated local OmniRoute UI/API. Reuse an existing DeepSeek provider credential if
one is already configured. Add only these gateway-visible IDs:

```text
ds/deepseek-v4-flash
ds/deepseek-v4-pro
```

Do not invent or request a credential from another provider. If no DeepSeek credential exists,
record `reason_code: DEEPSEEK_CREDENTIAL_MISSING` and continue to Task 2 without changing quality
gates.

Re-run `GET /v1/models`. Expected: both exact IDs are present before OMP configuration changes.

- [ ] **Step 6: Add scoped OMP catalog entries without replacing user configuration**

Patch only the `providers.omniroute.models` list in
`C:/Users/MrThien/.omp/agent/models.yml`. Preserve the existing Codex entry and add:

```yaml
      - id: ds/deepseek-v4-flash
        name: DeepSeek V4 Flash Max via OmniRoute
        reasoning: true
        thinking:
          minLevel: high
          maxLevel: xhigh
          mode: effort
        input: [text]
        contextWindow: 1000000
        maxTokens: 384000
        compat:
          supportsReasoningEffort: true
          reasoningEffortMap:
            high: high
            xhigh: max
      - id: ds/deepseek-v4-pro
        name: DeepSeek V4 Pro Max via OmniRoute
        reasoning: true
        thinking:
          minLevel: high
          maxLevel: xhigh
          mode: effort
        input: [text]
        contextWindow: 1000000
        maxTokens: 384000
        compat:
          supportsReasoningEffort: true
          reasoningEffortMap:
            high: high
            xhigh: max
```

Run:

```powershell
omp models refresh
omp models find deepseek-v4-flash
omp models find deepseek-v4-pro
```

Expected: both selectors resolve under provider `omniroute`. If OMP rejects a compatibility field,
restore the timestamped backup, record the exact parser error, and mark the environment step
`FAIL`; do not guess an alternative schema.

- [ ] **Step 7: Implement and run the explicit smoke runner**

`scripts/run-topic03-deepseek-smoke.ps1` accepts `-Model Flash|Pro`, runs an ephemeral OMP session
with `--thinking xhigh --tools read --mode json --no-session`, asks the model to read the first H1
of `README.md`, and requires both a `read` tool event and sentinel
`TOPIC03_DEEPSEEK_<MODEL>_OK`. It writes only redacted outcome metadata and hashes to
`deepseek-smoke.yml`; raw provider payloads and credentials are excluded.

Run:

```powershell
pwsh -NoProfile -File scripts/run-topic03-deepseek-smoke.ps1 -Model Flash
pwsh -NoProfile -File scripts/run-topic03-deepseek-smoke.ps1 -Model Pro
pwsh -NoProfile -File scripts/tests/topic03-deepseek-routing.Tests.ps1
```

Expected: both runs exit 0, include a real read-tool event, and record the expected full selector.
If either route is unavailable, record `ENVIRONMENT_BLOCKED` or `FAIL` accurately and continue.

- [ ] **Step 8: Commit only new repository-owned Task 1 artifacts**

```powershell
git add -- scripts/lib/topic03-deepseek-routing.ps1 `
  scripts/tests/topic03-deepseek-routing.Tests.ps1 `
  scripts/run-topic03-deepseek-smoke.ps1 `
  docs/evidence/current-product/topic-03/deepseek-smoke.yml
git diff --cached --check
git commit -m "test: add topic 03 DeepSeek routing probe"
```

Do not stage the user-level `models.yml` backup or any pre-existing dirty path.

---

### Task 2: Add the focused Topic 03 contract validator test-first

**Files:**
- Create: `scripts/lib/topic03-topology-routing.ps1`
- Create: `scripts/tests/topic03-topology-routing.Tests.ps1`
- Create: `scripts/validate-topic03-topology-routing.ps1`
- Modify later in Task 7: `scripts/validate-template.ps1`

**Interfaces:**
- Consumes: approved design
  `docs/superpowers/specs/2026-08-12-topic-03-agent-topology-model-routing-design.md`.
- Produces: `Test-Topic03DesignContract`, `Test-Topic03SpecContract`,
  `Test-Topic03RuntimeManifestContract`, `Test-Topic03RoutingContract`,
  `Test-Topic03InstallContract`, and `Test-Topic03TopologyRoutingContract`.
- Result type remains `{ Status, Code, Message }`, compatible with existing validators.

- [ ] **Step 1: Build a complete good fixture and mutation matrix**

The good fixture contains the design, minimal spec/decision/phase projections, exactly three agent
files, main-session instructions, commands, config, installer, and current-product manifest.
Assert one exact failure code for each mutation:

```text
T03-MANIFEST-OLD-AGENT          add agents/explorer.md
T03-MANIFEST-SCOUT-MISSING      delete agents/cheap-scout.md
T03-SCOUT-WRITE-TOOL            add edit, write, or bash to Scout tools
T03-SCOUT-EFFORT                remove xhigh from Scout
T03-WORKER-DEFAULT-EFFORT       replace Worker high with medium
T03-REVIEWER-EFFORT             replace Reviewer xhigh with high
T03-TECHLEAD-SPAWNABLE          add agents/tech-lead.md
T03-SPAWN-BENEFIT-GATE          remove the default-no-spawn rule
T03-REVIEW-RISK-GATE            remove mandatory high-risk concerns
T03-OPUS-MANDATORY              add wording that unavailable Opus blocks all review
T03-CONFIG-SCOUT-PRIMARY        remove Flash primary alias
T03-CONFIG-SCOUT-FALLBACK       remove Pro fallback chain
T03-CONFIG-DEFAULT-FALLBACK     make default/worker/reviewer chain non-empty
T03-CONFIG-EFFORT               remove task.enableEffort or xhigh ceiling
T03-COMMAND-FIXED-CHAIN         add Explorer->Implementer->Verifier sequencing
T03-INSTALL-STALE-AGENT         omit exact stale-agent retirement
T03-EVIDENCE-SUPERSESSION       remove Phase 00 supersession identity
```

- [ ] **Step 2: Run the tests before the helper exists**

```powershell
pwsh -NoProfile -File scripts/tests/topic03-topology-routing.Tests.ps1
```

Expected: exit 1 with `[T03-TEST-HELPER]`.

- [ ] **Step 3: Implement the minimal validator and focused runner**

Use literal/regex checks only for closed, load-bearing semantics. Normalize CRLF/LF and collapse
wrapped Markdown whitespace before matching. Enumerate `template/.omp/agents/*.md` and compare the
case-sensitive stem set against `cheap-scout,reviewer,worker`; do not merely search prose.

The focused runner prints every result and exits 1 only when one or more results are `FAIL`.

- [ ] **Step 4: Prove the mutation suite is red/green**

```powershell
pwsh -NoProfile -File scripts/tests/topic03-topology-routing.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic03-topology-routing.ps1
```

Expected now: mutation self-test passes; focused real-repository validation fails on the old
five-agent/runtime/spec state. Record the failure codes as the implementation checklist.

- [ ] **Step 5: Commit only the three new validator files**

```powershell
git add -- scripts/lib/topic03-topology-routing.ps1 `
  scripts/tests/topic03-topology-routing.Tests.ps1 `
  scripts/validate-topic03-topology-routing.ps1
git diff --cached --check
git commit -m "test: define topic 03 topology contract"
```

---

### Task 3: Project the approved topology into canonical specs and phases

**Files:** authority/projection files listed under “Canonical authority and projections.”

**Interfaces:**
- Consumes: approved Topic 03 design and focused validator failure codes.
- Produces: KD-027 and one selected manifest contract consumed by runtime, installer, and L0–L4
  validation.

- [ ] **Step 1: Rewrite `spec/03-agent-topology.md` as the canonical topology authority**

The active section must state, without historical-role ambiguity:

```text
main-session Tech Lead -> optional cheap-scout | optional worker | risk-gated reviewer
default: inline/no spawn
selected manifest: [cheap-scout, worker, reviewer]
verification owner: Tech Lead
reviewer shape: one General Reviewer + dynamic concern profiles
parallel writers: conditional; sequential fallback
```

Move verified frontmatter/source facts that remain useful into a clearly labeled evidence appendix.
Fence the Explorer/Implementer/Verifier/five-role graph as superseded history.

- [ ] **Step 2: Rewrite `spec/09-model-routing.md` around selected aliases**

Specify:

```yaml
modelRoles:
  cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh
  worker: omniroute/codex/gpt-5.6-sol
  reviewer: omniroute/codex/gpt-5.6-sol
retry:
  modelFallback: true
  usageAwareFallback: false
  fallbackChains:
    default: []
    cheap-scout: [omniroute/ds/deepseek-v4-pro:xhigh]
    worker: []
    reviewer: []
task:
  enableEffort: true
  maxEffort: xhigh
```

Explain that `ds/...` is the OmniRoute gateway model ID and `omniroute/ds/...` is the OMP
selector. Record the credential-fallback caveat and exact returned-identity check for Worker and
Reviewer. Treat Scout quality insufficiency as Tech Lead judgment, not automatic provider
fallback.

- [ ] **Step 3: Append KD-027**

KD-027 must record alternatives rejected and the selected outcome:

- reject fixed five-role chain;
- reject mandatory worker/reviewer spawn by workflow stage;
- reject permanent specialist roster;
- reject Opus as a universal gate;
- select three logical agents, benefit gating, DeepSeek Flash→Pro Scout fallback, dynamic Worker
  effort, fixed Reviewer `xhigh`, and one-writer default.

It must name Topic 02 as lifecycle authority and Phase 02 as runtime migration owner.

- [ ] **Step 4: Project the contract across active specs and phases**

For every listed projection file, remove active claims that require Explorer, Implementer,
Verifier, a fixed count, unconditional review, or all-model fallback-off. Preserve source facts in
explicit historical/evidence fences. Add exact ownership for:

- selected structured output contracts for Scout, Worker, Reviewer;
- Tech Lead fresh verification;
- selected command/tool fail-closed behavior;
- Worker high/xhigh effort and Reviewer exact xhigh;
- Scout-only fallback and returned model disclosure;
- current-product evidence in Phase 02;
- installer stale-agent retirement in Phase 05;
- L0/L1/behavioral fixtures in Phase 06.

- [ ] **Step 5: Run focused and Topic 02 regression validation**

```powershell
pwsh -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
git diff --check -- spec docs/superpowers/specs
```

Expected: Topic 03 spec checks pass while runtime/install checks remain red; Topic 02 stays green.

- [ ] **Step 6: Checkpoint without staging pre-dirty spec files**

Record the paths and focused totals in the Topic 03 changelog draft. Do not commit these existing
dirty files as Topic 03-only work.

---

### Task 4: Migrate the installed runtime to the three-agent manifest

**Files:**
- Create: `template/.omp/agents/cheap-scout.md`
- Create: `template/.omp/agents/worker.md`
- Modify: `template/.omp/agents/reviewer.md`, `template/.omp/AGENTS.md`, three command files
- Create: `docs/roles/tech-lead.md`
- Retire: four historical agent files
- Modify: `scripts/lib/phase00-evidence.ps1`, `scripts/tests/phase00-t003.Tests.ps1`
- Create: `docs/evidence/current-product/topic-03/manifest.yml`

**Interfaces:**
- Consumes: selected manifest/KD-027 and existing Topic 02 entry/lifecycle contract.
- Produces: exactly three discoverable OMP agents and a current-product evidence boundary that
  leaves Phase 00 conclusions byte-unchanged.

- [ ] **Step 1: Add failing Phase 00 supersession tests**

Extend `phase00-t003.Tests.ps1` with a fixture where the old four agent destination paths are
absent, a Topic 03 current-product manifest binds their historical Phase 00 identities, and the
three current agents resolve. Assert:

```text
PASS: immutable Phase 00 conclusion SHA/rows remain exact and Topic 03 manifest is coherent
FAIL P00-T003-LATER-SUPERSESSION: current manifest missing
FAIL P00-T003-LATER-SUPERSESSION: one historical SHA changed
FAIL P00-T003-LATER-SUPERSESSION: one current file hash does not match
FAIL P00-T003-CONSUMERS: retired agent remains discoverable
```

Run only the focused Pester test. Expected: new tests fail before helper changes.

- [ ] **Step 2: Implement the later-product supersession contract**

Extend the validator helper; do not edit `docs/evidence/phase-00/T-00.3/conclusion.yml`. The new
manifest has this closed shape:

```yaml
schema_version: 1
topic: "03"
candidate: "C1"
phase00_source: "T-00.3"
phase00_conclusion_sha256: "<computed exact SHA256>"
superseded_agents:
  - historical_path: template/.omp/agents/tech-lead.md
    disposition: rehomed
    current_path: docs/roles/tech-lead.md
  - historical_path: template/.omp/agents/explorer.md
    disposition: replaced
    current_path: template/.omp/agents/cheap-scout.md
  - historical_path: template/.omp/agents/implementer.md
    disposition: renamed
    current_path: template/.omp/agents/worker.md
  - historical_path: template/.omp/agents/verifier.md
    disposition: retired
    current_path: null
selected_agents: [cheap-scout, worker, reviewer]
current_files: []
deepseek_environment: PASS | FAIL | ENVIRONMENT_BLOCKED
```

At implementation time replace `<computed exact SHA256>` and populate `current_files` with actual
path/SHA rows; those are generated values, not hand-written placeholders in the finished artifact.

- [ ] **Step 3: Create the three agent contracts**

Frontmatter requirements:

```yaml
# cheap-scout.md
name: cheap-scout
model: "@cheap-scout"
tools: read, grep, glob, web_search
spawns: ""
thinking-level: xhigh
read-summarize: false
blocking: true

# worker.md
name: worker
model: "@worker"
tools: read, grep, glob, edit, write, bash
spawns: ""
thinking-level: high
blocking: true

# reviewer.md
name: reviewer
model: "@reviewer"
tools: read, grep, glob, bash
spawns: ""
thinking-level: xhigh
read-summarize: false
blocking: true
```

Each file carries a flat, closed, `$ref`-free `output:` schema matching its prompt. Scout returns
ranked evidence/uncertainty; Worker returns changed files and verification; Reviewer returns
decision/findings/false-positive checks. The coordinator accepts only
`structuredOutput.status == valid` and no override.

- [ ] **Step 4: Rehome Tech Lead behavior and retire old agents**

Move useful main-session behavior into `template/.omp/AGENTS.md` and human explanation into
`docs/roles/tech-lead.md`. Delete only these exact runtime files:

```text
template/.omp/agents/tech-lead.md
template/.omp/agents/explorer.md
template/.omp/agents/implementer.md
template/.omp/agents/verifier.md
```

Do not delete the agents directory or use a wildcard.

- [ ] **Step 5: Rewrite command adapters around benefit gates**

- Quick remains inline unless a bounded Scout query creates clear value.
- Standard remains one integrated lane; Scout, Worker, and Reviewer are optional/risk-gated.
- Orchestrated requires Topic 02 work-unit/integration structure, not a fixed agent chain.
- Every Worker dispatch states scope ownership and effort: omit `effort` for normal `high`, use
  `effort: hi` only for difficult `xhigh` work.
- Reviewer dispatch is selected by the risk gate and never lowers `xhigh`.
- Tech Lead runs fresh verification after integration.
- No command names a concrete model ID.

- [ ] **Step 6: Populate and verify the current-product manifest**

Calculate hashes after runtime files settle, write them into `current_files`, and run:

```powershell
Invoke-Pester -Path scripts/tests/phase00-t003.Tests.ps1 -Output Detailed
pwsh -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
```

Expected: Phase 00 historical evidence remains green through explicit later supersession; Topic 03
runtime-manifest checks pass.

---

### Task 5: Make routing and installation enforce the selected manifest

**Files:**
- Modify: `template/.omp/config.yml`
- Modify: `scripts/install-template.ps1`
- Create: `scripts/tests/topic03-installer.Tests.ps1`
- Modify: `scripts/validate-template.ps1`

**Interfaces:**
- Consumes: three-agent runtime and exact role selectors.
- Produces: project installation that copies commands correctly, retires only exact stale agents,
  preserves protected model/credential files, and restores through the existing backup path.

- [ ] **Step 1: Write failing installer tests in disposable directories**

Tests must create paths beneath `[IO.Path]::GetTempPath()` with prefix
`omp-topic03-installer-`, validate the resolved absolute cleanup target before deletion, and cover:

```text
dry-run changes nothing
workflows component maps to template/.omp/commands
apply installs exactly cheap-scout.md, worker.md, reviewer.md
apply retires exact old agent filenames after backup
unrelated custom-agent.md survives
models.yml and credential/database files survive
config contains selected aliases, Scout-only fallback, enableEffort, maxEffort xhigh
rollback restores the pre-install agent set
user target does not enable global effort without explicit opt-in
```

Run: `pwsh -NoProfile -File scripts/tests/topic03-installer.Tests.ps1`.
Expected: fail against the current copy-only installer.

- [ ] **Step 2: Replace the template role map and settings**

Use this project-level contract:

```yaml
modelRoles:
  cheap-scout: omniroute/ds/deepseek-v4-flash:xhigh
  worker: omniroute/codex/gpt-5.6-sol
  reviewer: omniroute/codex/gpt-5.6-sol
retry:
  modelFallback: true
  usageAwareFallback: false
  fallbackChains:
    default: []
    cheap-scout:
      - omniroute/ds/deepseek-v4-pro:xhigh
    worker: []
    reviewer: []
task:
  enableEffort: true
  maxEffort: xhigh
```

No `tech-lead`, `explorer`, `implementer`, or `verifier` alias remains required.

- [ ] **Step 3: Fix component mapping and exact stale-agent retirement**

Use `$component_map[$comp]` so `workflows` copies `commands`. Add a closed retirement list:

```powershell
$retiredAgents = @('tech-lead.md','explorer.md','implementer.md','verifier.md')
```

Dry-run prints `RETIRE` without mutation. Apply creates the existing full `.omp` backup first,
then removes only resolved files whose parent equals the resolved destination `agents` directory
and whose leaf is in the closed list. Never build a recursive delete target from a glob.

For `-Target user`, require explicit `-EnablePerSpawnEffort` before applying
`task.enableEffort/maxEffort`; project target uses the selected project config normally.

- [ ] **Step 4: Integrate focused Topic 03 validation into the full validator**

Update required files/token budgets/agent scans to the selected three-agent set. Dot-source
`scripts/lib/topic03-topology-routing.ps1`, invoke its aggregate contract, and translate results
through existing `Write-Pass/Write-Warn/Write-Fail` helpers.

- [ ] **Step 5: Run installation and full static validation**

```powershell
pwsh -NoProfile -File scripts/tests/topic03-installer.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-topology-routing.Tests.ps1
pwsh -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
git diff --check -- scripts template/.omp
```

Expected: all focused tests pass; full validator has zero failures. The known approximate
`RULES.md` lower-budget warning may remain.

---

### Task 6: Reconcile product documentation, research authority, and registries

**Files:** human-documentation files listed under “Human documentation and handoff.”

**Interfaces:**
- Consumes: implemented three-agent runtime and observed DeepSeek environment state.
- Produces: user-facing setup/behavior text with no false claim that DeepSeek, Opus, review, or
  parallel execution is universally available or mandatory.

- [ ] **Step 1: Update concise product docs**

Every current-product description must say:

- plain requests enter the main Tech Lead;
- inline/no-spawn is the default;
- Cheap Scout is read-only and fail-soft;
- Worker is benefit-gated and high/xhigh by task difficulty;
- General Reviewer is risk-gated and xhigh;
- Opus is preferred, not required;
- same-model independent-session review is disclosed;
- parallel writers are conditional and degrade to sequential.

Installation docs must distinguish OmniRoute gateway IDs (`ds/...`) from OMP selectors
(`omniroute/ds/...`) and point to the external `models.yml` prerequisite without embedding a key.

- [ ] **Step 2: Reconcile policy references and historical research**

Make `docs/policies/model-routing.md` the concise human routing reference. Update quality-gate
text so risk selects review but workflow class does not. In research/registry files, either update
current adoption rows or fence the old fixed roster as historical; do not silently delete research
evidence.

- [ ] **Step 3: Add the Topic 03 changelog**

Record:

- approved decisions and migration mapping;
- exact repository files changed;
- external OmniRoute/OMP configuration changes and backup paths, excluding secrets;
- DeepSeek smoke state and evidence path;
- validator/test totals;
- pre-existing dirty paths not claimed as Topic 03 work;
- remaining environment or independent-review limitations.

- [ ] **Step 4: Run contradiction scans**

```powershell
rg -n -i 'always.*Explorer|always.*Implementer|always.*Verifier|all four workers|five agents|Opus.*required|must wait for Opus' `
  spec docs README.md CHANGELOG.md registry template/.omp
rg -n 'ds/deepseek-v4|codex/gpt-5.6' template/.omp/commands template/.omp/AGENTS.md
```

Expected: remaining fixed-roster hits are explicitly historical/evidence-only; commands and main
instructions contain no concrete model IDs.

---

### Task 7: Run lean behavioral verification and close the implementation handoff

**Files:**
- Update: `docs/evidence/current-product/topic-03/manifest.yml`
- Update: `codex-topic03-agent-topology-model-routing-changelog.md`
- No new audit packet unless a genuinely unresolved difficult finding needs later review.

**Interfaces:**
- Consumes: installed runtime, focused/full validators, provider smoke evidence.
- Produces: evidence-backed status `IMPLEMENTED`, `IMPLEMENTED_WITH_ENVIRONMENT_BLOCK`, or
  `REWORK_REQUIRED`.

- [ ] **Step 1: Install into a disposable project and verify discovery**

Create a temp project under the validated prefix `omp-topic03-e2e-`, run installer dry-run then
apply, and assert the installed `agents` set is exactly:

```text
cheap-scout.md
reviewer.md
worker.md
```

Run OMP discovery against that project and confirm no `tech-lead`, `explorer`, `implementer`, or
`verifier` definition appears.

- [ ] **Step 2: Run the minimum behavioral matrix**

Use ephemeral sessions and retain redacted JSON evidence for:

1. low-risk bounded task: main session completes with zero `task` calls;
2. retrieval fixture: Scout reads evidence and cannot mutate files;
3. moderate delegation: Worker resolves at `high`;
4. difficult delegation: Worker dispatched with `effort: hi` resolves at `xhigh`;
5. high-risk review fixture: Reviewer resolves at `xhigh` with the named concern profile;
6. same-model review fallback: separate session plus disclosure;
7. parallel preflight failure: sequential writer fallback, no task block.

Compare repository hashes before/after the Scout fixture to prove read-only behavior. Reject any
result whose structured status is not valid or whose returned model identity does not match the
selected Worker/Reviewer identity.

If DeepSeek remains environment-blocked, case 2 must instead prove the Tech Lead fallback and
record the missing capability; do not fabricate a DeepSeek PASS.

- [ ] **Step 3: Run the final lean verification set**

```powershell
pwsh -NoProfile -File scripts/tests/topic03-deepseek-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-topology-routing.Tests.ps1
pwsh -NoProfile -File scripts/tests/topic03-installer.Tests.ps1
Invoke-Pester -Path scripts/tests/phase00-t003.Tests.ps1 -Output Detailed
pwsh -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoProfile -File scripts/validate-topic03-topology-routing.ps1
pwsh -NoProfile -File scripts/validate-template.ps1
git diff --check
```

Expected: zero failures. Report exact totals and the known warning separately.

- [ ] **Step 4: Self-review only the Topic 03 diff**

Check for secrets, stale agents, accidental hardcoded models in workflow prose, broad deletes,
unowned user-level settings, missing fallback disclosure, and claims unsupported by smoke evidence.
Do not launch repeated general-purpose peer audits. Note a difficult unresolved item for a future
strong-model review only when it cannot be resolved from source/tests.

- [ ] **Step 5: Set the final status and stop at the integration boundary**

- `IMPLEMENTED`: all repository gates plus DeepSeek environment smoke pass.
- `IMPLEMENTED_WITH_ENVIRONMENT_BLOCK`: repository gates pass, but a named credential/gateway
  prerequisite prevented DeepSeek smoke; Tech Lead fallback remains valid.
- `REWORK_REQUIRED`: a repository contract or required test fails.

Do not label Opus absence as a blocker. Do not stage existing dirty files or create a final commit
without showing the user the exact path set that would be included.
