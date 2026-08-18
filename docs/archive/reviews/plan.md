You are the principal engineer responsible for designing and implementing a deeply customized, production-grade workflow template for OMP (Oh My Pi).

You are not merely installing plugins or copying prompts.

Your job is to:

1. Research a selected set of high-quality AI coding-agent repositories.
2. Extract only their strongest mechanisms.
3. Resolve overlap and conflicts between them.
4. Reimplement the selected mechanisms as a coherent OMP-native system.
5. Optimize for:
   - coding quality,
   - correctness,
   - context efficiency,
   - token efficiency,
   - reliable orchestration,
   - maintainability,
   - deep project customization,
   - measurable improvement through evaluation.

The final product must remain:

- OMP-native,
- modular,
- testable,
- explainable,
- versioned,
- reversible,
- easy to customize per project,
- free from duplicated orchestration engines.

Do not install entire external frameworks into OMP.

Do not turn this project into a second runtime layered on top of OMP.

OMP must remain the only coding-agent runtime and orchestration engine.

OmniRoute must remain the only model gateway.

────────────────────────────────────────────────────────────
0. WORKING MODE
────────────────────────────────────────────────────────────

Operate as a senior principal engineer.

Use this process:

Research
→ Evidence collection
→ Conflict analysis
→ Architecture specification
→ Minimal vertical implementation
→ Validation
→ Benchmark
→ Controlled expansion

Do not jump directly from cloning repositories to writing prompts.

Do not copy mechanisms blindly.

Do not assume a popular repository is automatically appropriate.

Challenge every mechanism with these questions:

1. What exact problem does it solve?
2. Does OMP already solve that problem?
3. Would adopting it duplicate orchestration, isolation, memory, review, or context management?
4. Does it improve accepted coding outcomes?
5. Does it reduce or increase token cost?
6. Can it be implemented natively through OMP?
7. Is the mechanism simple enough to maintain?
8. What are its failure modes?
9. How will it be evaluated?
10. How can it be removed safely if it underperforms?

Prefer evidence over intuition.

Prefer minimal mechanisms over large frameworks.

Prefer explicit artifacts over hidden memory.

Prefer deterministic verification over agent confidence.

────────────────────────────────────────────────────────────
1. ENVIRONMENT AND SAFETY CONSTRAINTS
────────────────────────────────────────────────────────────

The host environment is Windows with PowerShell.

Current runtime:

- OMP 17.2.10
- OMP home:
  C:\Users\MrThien\.omp\agent
- OmniRoute:
  http://127.0.0.1:20128
- Git and Git Bash are installed.
- OMP is connected to OmniRoute through the OpenAI Responses API.
- The current available model is exposed through:
  omniroute/codex/gpt-5.6-sol-high

The current global OMP baseline is frozen:

tools.approvalMode          = yolo
defaultThinkingLevel        = high
textVerbosity               = medium

retry.enabled               = true
retry.maxRetries            = 3
retry.baseDelayMs           = 500
retry.maxDelayMs            = 60000
retry.modelFallback         = false
retry.usageAwareFallback    = false

task.batch                  = true
task.maxConcurrency         = 4
task.isolation.mode         = auto
task.isolation.apply        = true
task.isolation.merge        = patch
task.enableEffort           = true
task.maxEffort              = max
task.enableLsp              = true
task.maxRecursionDepth      = 2
task.maxRuntimeMs           = 0
task.softRequestBudget      = 120
task.agentIdleTtlMs         = 420000
task.showResolvedModelBadge = true

edit.mode                   = hashline
edit.fuzzyMatch             = true
edit.fuzzyThreshold         = 0.95

read.summarize.enabled      = true

lsp.enabled                 = true
lsp.lazy                    = true
lsp.shared                  = true
lsp.diagnosticsOnWrite      = true
lsp.diagnosticsOnEdit       = false

compaction.enabled          = true
compaction.strategy         = shake
compaction.keepRecentTokens = 20000
compaction.supersedeReads   = true
compaction.dropUseless      = true

advisor.enabled             = false
advisor.subagents           = false
advisor.syncBacklog         = 1

memory.backend              = off
autolearn.enabled           = false

Do not change this baseline during the initial implementation.

A setting may only be changed later when:

- a reproducible problem has been observed,
- the root cause points to that setting,
- a before/after benchmark exists,
- the change is documented and reversible.

Do not modify files under:

C:\Users\MrThien\.omp\agent

during research and initial construction.

Build everything in an isolated project repository first.

Before any eventual installation:

1. Back up the existing OMP directory.
2. Show the exact installation diff.
3. Validate the generated template.
4. Require explicit approval before syncing it to the live OMP directory.

Do not expose or commit:

- API keys,
- OAuth tokens,
- OmniRoute database content,
- private prompts,
- call logs,
- environment secrets.

────────────────────────────────────────────────────────────
2. PROJECT LOCATION
────────────────────────────────────────────────────────────

Use the current repository as the template project.

Recommended layout:

C:\AI\omp-workflow-template

Initialize it as a Git repository if it is not already one.

Create external research clones under:

_research/upstreams/

External source repositories must not be mixed directly into the template source tree.

Do not use Git submodules for the first version.

Use shallow or partial clones where practical.

For every upstream repository, record:

- repository URL,
- default branch,
- current commit hash,
- clone date,
- license,
- paths reviewed,
- mechanisms adopted,
- mechanisms rejected,
- local implementation files influenced by it.

────────────────────────────────────────────────────────────
3. UPSTREAM REPOSITORIES
────────────────────────────────────────────────────────────

Clone and inspect the following repositories.

A. Runtime authority and native target

1. https://github.com/can1357/oh-my-pi

Purpose:

- Understand the exact OMP-native configuration model.
- Custom agents.
- Skills.
- Model roles.
- Task orchestration.
- Isolation.
- Advisor.
- Context files.
- Structured results.
- Project/global overrides.
- Compaction.
- LSP.
- Editing model.
- Review capabilities.

OMP documentation and source code are authoritative whenever an external workflow conflicts with OMP.

B. Core methodology authorities

2. https://github.com/obra/superpowers

Study selectively:

- requirement clarification,
- brainstorming,
- planning checkpoints,
- systematic debugging,
- TDD principles,
- verification before completion,
- requesting and receiving code review.

Reject or rewrite:

- worktree management,
- subagent dispatch,
- parallel-agent orchestration,
- bootstrap enforcement,
- execution engine,
- branch-finishing workflow.

3. https://github.com/anthropics/skills

Study:

- SKILL.md structure,
- progressive disclosure,
- metadata,
- skill triggering,
- references,
- scripts,
- resources,
- positive trigger tests,
- negative trigger tests,
- skill evaluation.

Use this as the primary authority for skill packaging, but create OMP-compatible validation and evaluation.

4. https://github.com/github/spec-kit

Study:

- project constitution,
- clarification gate,
- specification,
- acceptance scenarios,
- planning,
- task decomposition,
- artifact consistency,
- traceability,
- large-feature slicing.

Do not copy the full CLI workflow.

5. https://github.com/Fission-AI/OpenSpec

Study:

- current truth,
- proposed change delta,
- ADDED / MODIFIED / REMOVED requirements,
- optional design artifacts,
- task lifecycle,
- archival,
- custom schemas,
- brownfield evolution.

Spec Kit and OpenSpec must be synthesized into one internal specification system.

Do not create two competing specification trees.

6. https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering

Study selectively:

- context fundamentals,
- context degradation,
- context compression,
- context optimization,
- filesystem context,
- multi-agent context,
- tool-output design,
- evaluation,
- harness engineering.

Do not adopt:

- hidden autonomous memory,
- uncontrolled self-improvement,
- runtime-specific KV-cache mechanisms,
- unnecessary cognitive architecture.

7. https://github.com/addyosmani/agent-skills

Study only production-quality mechanisms:

- API and interface compatibility,
- architecture review,
- security and hardening,
- performance,
- migration and deprecation,
- ADR and documentation,
- observability,
- release readiness,
- rollback readiness,
- code simplification,
- anti-rationalization.

Do not adopt its full personas, routing, orchestration, specification workflow, or duplicated TDD workflow.

8. https://github.com/promptfoo/promptfoo

Study:

- prompt and agent evaluation,
- deterministic assertions,
- custom assertions,
- model-graded assertions,
- A/B comparison,
- regression testing,
- CI integration,
- red teaming,
- output metrics.

Promptfoo is external evaluation infrastructure, not part of OMP runtime.

C. Pattern and constraint sources

9. https://github.com/affaan-m/ECC

Treat ECC as a pattern mine only.

Study selectively:

- model routing,
- token/context profiles,
- progressive retrieval,
- selective installation,
- project/language rule layering,
- security hardening,
- harness auditing,
- verification loops.

Do not install ECC.

Do not import:

- hooks,
- memory systems,
- instinct systems,
- full agents,
- full skill catalog,
- MCP bundle,
- orchestration runtime,
- continuous learning.

10. https://github.com/SWE-agent/mini-swe-agent

Study:

- minimal worker loop,
- linear and auditable execution,
- small tool surface,
- explicit termination,
- cost limits,
- reproducible evaluation,
- minimal abstraction.

Use it as a complexity governor.

Do not install it as a second coding runtime.

11. https://github.com/multica-ai/andrej-karpathy-skills

Extract the durable coding principles:

- think before coding,
- simplicity first,
- surgical changes,
- goal-driven verification,
- assumption visibility,
- no drive-by refactoring,
- no speculative abstractions.

Rewrite these principles concisely.

Do not copy a large persistent prompt.

12. https://github.com/humanlayer/12-factor-agents

Study:

- prompt ownership,
- context ownership,
- control-flow ownership,
- structured tool outputs,
- explicit execution state,
- pause/resume concepts,
- compact errors,
- small focused agents.

Use these as architecture principles, not as a runtime dependency.

13. https://github.com/Aider-AI/aider

Study selectively:

- repository map,
- symbol/signature summaries,
- token-budgeted repository context,
- architect/editor separation,
- lint/test feedback loops,
- edit reliability.

Do not run Aider as a second coding agent.

14. https://github.com/agentsmd/agents.md

Study:

- repository-local agent instructions,
- inheritance and scope,
- practical project commands,
- architecture rules,
- testing instructions,
- concise persistent context.

D. Conditional tool references

Clone and analyze, but do not integrate by default:

15. https://github.com/oraios/serena

Evaluate only as an optional semantic retrieval layer when OMP LSP and native search are insufficient.

16. https://github.com/yamadashy/repomix

Evaluate only for:

- project onboarding,
- repository subset snapshots,
- architecture audits,
- external reviews,
- token counting.

Do not use full-repository dumps by default.

17. https://github.com/upstash/context7

Evaluate only for current, version-specific library documentation.

The preferred retrieval order remains:

local code and types
→ local documentation
→ official versioned documentation
→ Context7
→ broader web research

────────────────────────────────────────────────────────────
4. LICENSE AND ATTRIBUTION POLICY
────────────────────────────────────────────────────────────

Inspect the license of every upstream repository.

Create:

registry/licenses.yml

For every adopted mechanism, record whether it is:

- conceptual inspiration,
- paraphrased implementation,
- adapted content,
- copied content,
- linked external dependency.

Do not copy substantial prompt or code content unless the license permits it.

Preserve required attribution.

Prefer rewriting mechanisms in project-native language instead of copying large instruction files.

Do not mix incompatible licenses into the distributable template.

Flag any licensing uncertainty before implementation.

────────────────────────────────────────────────────────────
5. REQUIRED RESEARCH OUTPUTS
────────────────────────────────────────────────────────────

Before implementing the workflow, produce:

docs/research/source-inventory.md
docs/research/mechanism-matrix.md
docs/research/conflict-matrix.md
docs/research/authority-map.md
docs/research/token-impact-analysis.md
docs/research/security-analysis.md
docs/research/final-adoption-plan.md

The mechanism matrix must contain:

- source repository,
- mechanism,
- problem solved,
- evidence or rationale,
- overlap with OMP,
- overlap with other upstreams,
- token impact,
- quality impact,
- operational complexity,
- security implications,
- proposed OMP mapping,
- adopt / adapt / reject decision,
- reason.

The conflict matrix must explicitly examine:

- duplicate subagent orchestration,
- duplicate planning engines,
- duplicate worktree/isolation systems,
- duplicate review flows,
- duplicate specification systems,
- duplicate context management,
- duplicate memory systems,
- duplicated tool descriptions,
- duplicated persistent instructions,
- conflicting definitions of completion,
- conflicting Git workflows,
- conflicting model-routing policies.

The authority map must assign exactly one primary authority to each concern.

Target authority map:

Runtime and orchestration
→ OMP

Gateway and account routing
→ OmniRoute

Coding constitution
→ Karpathy principles, implemented locally

Control-flow and context ownership
→ 12-Factor Agents principles

Specification constitution, clarification and traceability
→ Spec Kit

Brownfield change lifecycle
→ OpenSpec

Implementation discipline
→ selected Superpowers mechanisms

Production quality gates
→ selected Addy Agent Skills mechanisms

Context and token policy
→ Context Engineering Skills

Skill packaging and triggers
→ Anthropic Skills

Model-routing and harness research
→ selected ECC patterns

Minimal worker-loop constraint
→ mini-SWE-agent principles

Repository-map design
→ Aider principles

Evaluation
→ Promptfoo and local deterministic tests

Do not begin full implementation until these research artifacts are internally consistent.

────────────────────────────────────────────────────────────
6. TARGET DNA
────────────────────────────────────────────────────────────

Implement the following DNA as an OMP-native system:

OMP CUSTOM WORKFLOW DNA
│
├── 0. Runtime Ownership
│   ├── OMP
│   ├── OmniRoute
│   ├── OMP model roles
│   ├── OMP task/batch/isolation
│   ├── OMP LSP/Hashline
│   └── OMP shake compaction
│
├── 1. Coding Constitution
│   ├── think before coding
│   ├── simplicity first
│   ├── surgical changes
│   ├── goal-driven verification
│   ├── project invariants
│   └── no false completion
│
├── 2. Workflow Architecture
│   ├── own prompts
│   ├── own context
│   ├── own control flow
│   ├── structured outputs
│   ├── explicit durable artifacts
│   └── compact errors
│
├── 3. Specification
│   ├── constitution
│   ├── clarification gate
│   ├── acceptance scenarios
│   ├── artifact consistency analysis
│   ├── current truth
│   ├── change delta
│   ├── optional design
│   └── archive lifecycle
│
├── 4. Planning
│   ├── requirement clarification
│   ├── critical plan review
│   ├── dependency graph
│   ├── scoped task packets
│   ├── verification plan
│   └── risk-based workflow sizing
│
├── 5. Context and Token
│   ├── context budget
│   ├── context degradation prevention
│   ├── progressive retrieval
│   ├── filesystem offloading
│   ├── compact worker handoff
│   ├── structured tool results
│   ├── no transcript forwarding
│   └── artifact-based recovery
│
├── 6. Code Understanding
│   ├── OMP LSP
│   ├── OMP search and read summaries
│   ├── repository-map principles
│   ├── symbol-first exploration
│   ├── references and callers before full-file reads
│   └── optional semantic/documentation tools
│
├── 7. Orchestration
│   ├── Tech Lead
│   ├── Explorer
│   ├── Implementer
│   ├── Verifier
│   ├── Reviewer
│   ├── later optional specialist roles
│   ├── minimal worker loop
│   └── explicit task/result contracts
│
├── 8. Implementation Discipline
│   ├── root-cause fixes
│   ├── scope control
│   ├── no speculative abstractions
│   ├── risk-based TDD
│   ├── incremental implementation
│   ├── source-driven decisions
│   └── deterministic project tools
│
├── 9. Production Quality Gates
│   ├── API compatibility
│   ├── security
│   ├── performance
│   ├── migration/deprecation
│   ├── ADR/documentation
│   ├── observability
│   └── release/rollback readiness
│
├── 10. Verification and Review
│   ├── evidence before completion
│   ├── fresh test/build output
│   ├── specification compliance
│   ├── code-quality review
│   ├── risk-specific review
│   ├── false-positive control
│   └── integration validation
│
├── 11. Skill Engineering
│   ├── SKILL.md format
│   ├── progressive disclosure
│   ├── positive triggers
│   ├── negative triggers
│   ├── references/scripts separation
│   ├── token budget
│   ├── compatibility metadata
│   └── evaluation suite
│
├── 12. Evaluation
│   ├── deterministic assertions
│   ├── model-graded checks only where needed
│   ├── workflow A/B tests
│   ├── routing tests
│   ├── regression tasks
│   ├── token/outcome metrics
│   └── variance tracking
│
└── 13. Governance
    ├── upstream registry
    ├── pinned commits
    ├── watched paths
    ├── adoption ledger
    ├── rejected mechanisms
    ├── local modifications
    ├── regression gates
    └── controlled promotion

────────────────────────────────────────────────────────────
7. IMPLEMENTATION STRATEGY
────────────────────────────────────────────────────────────

Do not implement the entire DNA at once.

Build a vertical Workflow v0 first.

Workflow v0 must contain only:

1. A concise global AGENTS.md
2. A concise RULES.md only if truly needed
3. Model-role configuration abstraction
4. Five agents:
   - tech-lead
   - explorer
   - implementer
   - verifier
   - reviewer
5. Three workflows:
   - quick
   - standard
   - orchestrated
6. Three core skills:
   - task-triage
   - systematic-debugging
   - evidence-before-completion
7. Four schemas:
   - task-packet
   - agent-result
   - verification-result
   - review-result
8. Context-budget policy
9. Model-routing policy
10. A validation script
11. An initial evaluation suite

Do not initially implement:

- persistent memory,
- autolearn,
- automatic skill creation,
- swarm scheduling,
- second runtime,
- full OpenSpec or Spec Kit CLI,
- all production specialist skills,
- always-on advisor,
- always-on multi-reviewer workflow,
- automatic external services,
- external MCP tools,
- automatic installation into live OMP.

These may be proposed after Workflow v0 passes evaluation.

────────────────────────────────────────────────────────────
8. TARGET TEMPLATE STRUCTURE
────────────────────────────────────────────────────────────

Build toward:

.
├── README.md
├── CHANGELOG.md
├── LICENSES.md
├── AGENTS.md
├── RULES.md
│
├── template/
│   └── .omp/
│       ├── config.yml
│       ├── AGENTS.md
│       ├── RULES.md
│       │
│       ├── agents/
│       │   ├── tech-lead.md
│       │   ├── explorer.md
│       │   ├── implementer.md
│       │   ├── verifier.md
│       │   └── reviewer.md
│       │
│       ├── workflows/
│       │   ├── quick.md
│       │   ├── standard.md
│       │   └── orchestrated.md
│       │
│       ├── skills/
│       │   ├── task-triage/
│       │   │   └── SKILL.md
│       │   ├── systematic-debugging/
│       │   │   └── SKILL.md
│       │   └── evidence-before-completion/
│       │       └── SKILL.md
│       │
│       ├── schemas/
│       │   ├── task-packet.schema.yml
│       │   ├── agent-result.schema.yml
│       │   ├── verification-result.schema.yml
│       │   └── review-result.schema.yml
│       │
│       └── policies/
│           ├── context-budget.yml
│           ├── model-routing.yml
│           ├── workflow-sizing.yml
│           ├── quality-gates.yml
│           └── escalation.yml
│
├── docs/
│   ├── architecture.md
│   ├── workflow-v0.md
│   ├── customization.md
│   ├── installation.md
│   ├── rollback.md
│   ├── security.md
│   ├── token-strategy.md
│   └── research/
│       ├── source-inventory.md
│       ├── mechanism-matrix.md
│       ├── conflict-matrix.md
│       ├── authority-map.md
│       ├── token-impact-analysis.md
│       ├── security-analysis.md
│       └── final-adoption-plan.md
│
├── registry/
│   ├── upstreams.yml
│   ├── adoption-ledger.yml
│   ├── licenses.yml
│   ├── skill-lock.yml
│   └── rejected-mechanisms.yml
│
├── evals/
│   ├── fixtures/
│   ├── triage/
│   ├── retrieval/
│   ├── implementation/
│   ├── debugging/
│   ├── verification/
│   ├── review/
│   └── token-efficiency/
│
├── scripts/
│   ├── bootstrap.ps1
│   ├── clone-upstreams.ps1
│   ├── inventory-upstreams.ps1
│   ├── validate-template.ps1
│   ├── benchmark.ps1
│   ├── install-template.ps1
│   ├── uninstall-template.ps1
│   └── update-upstreams.ps1
│
└── _research/
    └── upstreams/

Do not create empty files merely to satisfy the tree.

Every file must have a clear purpose.

────────────────────────────────────────────────────────────
9. TOKEN-EFFICIENCY CONSTRAINTS
────────────────────────────────────────────────────────────

Persistent context must remain small.

Initial target budgets:

Global AGENTS.md:
- target: 600–1,200 tokens
- hard warning above 1,500 tokens

RULES.md:
- target: 300–700 tokens
- include only critical invariants that must stay sticky

Individual agent definition:
- target: 500–1,200 tokens
- larger only with a documented reason

Skill description metadata:
- concise enough for accurate triggering
- include both activation and non-activation boundaries

Core skill body:
- target: 800–2,000 tokens
- place details in references when possible

Default task packet:
- only task-relevant context
- no parent transcript
- no raw terminal history
- no full repository dump
- no unrelated architecture documentation

Worker result:
- structured and compact
- no chain-of-thought
- no complete terminal transcript
- include evidence and unresolved risks

Prefer:

- file references,
- symbol references,
- artifact references,
- concise failure summaries,
- deterministic scripts,
- narrow file ranges,
- cached project maps.

Avoid:

- repeated project descriptions,
- duplicated rules across agents,
- the same checklist in multiple skills,
- permanent loading of specialist knowledge,
- multiple agents reading the same files without reason,
- full-context handoff,
- redundant review layers.

Token efficiency must never be achieved by:

- using weaker verification,
- skipping tests,
- removing necessary review,
- reducing reasoning for high-risk tasks,
- hiding uncertainty,
- declaring success without evidence.

The primary optimization metric is:

tokens per accepted outcome

not merely lowest token count.

────────────────────────────────────────────────────────────
10. WORKFLOW SIZING
────────────────────────────────────────────────────────────

Implement three workflow levels.

A. Quick

Use when:

- scope is narrow,
- risk is low,
- affected code is obvious,
- architecture is unchanged.

Flow:

triage
→ inspect
→ implement
→ verify
→ report

Use zero or one worker unless there is a clear reason otherwise.

B. Standard

Use when:

- multiple files may be involved,
- behavior changes,
- root cause is not immediately clear,
- tests or compatibility need attention.

Flow:

triage
→ exploration
→ mini-spec
→ plan
→ implementation
→ deterministic verification
→ focused review
→ final summary

C. Orchestrated

Use when:

- task crosses modules,
- architecture changes,
- multiple independent workstreams exist,
- API/security/migration risk is high.

Flow:

parallel scoped exploration
→ architecture/specification review
→ dependency-aware task graph
→ isolated implementation
→ verification
→ independent review
→ integration validation
→ final evidence report

Parallelism is allowed only for genuinely independent work.

Do not create multiple agents merely to repeat the same analysis.

────────────────────────────────────────────────────────────
11. AGENT CONTRACTS
────────────────────────────────────────────────────────────

A. Tech Lead

Responsibilities:

- classify task complexity,
- resolve ambiguity,
- select workflow size,
- decide whether specialists are necessary,
- create task packets,
- coordinate workers,
- evaluate evidence,
- resolve conflicting findings,
- own final result.

The Tech Lead must not:

- delegate trivial tasks unnecessarily,
- trust worker summaries without evidence,
- forward full conversation history,
- enable every quality gate for every task,
- create speculative requirements.

B. Explorer

Responsibilities:

- identify relevant files and symbols,
- map call/reference relationships,
- identify architecture boundaries,
- find existing tests and conventions,
- return ranked evidence.

Explorer must not:

- implement unless explicitly instructed,
- dump full files,
- propose broad refactors,
- spawn unrelated agents.

C. Implementer

Loop:

inspect
→ edit
→ verify
→ compact result

Responsibilities:

- implement within scope,
- follow project conventions,
- perform root-cause fixes,
- add or update appropriate tests,
- produce structured evidence.

Implementer must not:

- redesign the project,
- expand scope,
- create speculative abstractions,
- report success without running verification.

D. Verifier

Responsibilities:

- independently run fresh verification,
- test acceptance criteria,
- inspect failures,
- distinguish implementation failure from environment failure,
- return evidence.

Verifier must not trust the implementer's test report without rechecking relevant evidence.

E. Reviewer

Responsibilities:

- review the actual diff,
- check specification compliance,
- identify correctness, maintainability and risk issues,
- control false positives,
- provide evidence and severity.

Reviewer must not:

- rewrite the implementation automatically,
- produce vague approval,
- report hypothetical concerns without checking context,
- repeat deterministic lint output without additional value.

────────────────────────────────────────────────────────────
12. STRUCTURED SCHEMAS
────────────────────────────────────────────────────────────

Task packet must support:

id:
objective:
why:
workflow_size:
scope:
out_of_scope:
relevant_context:
relevant_files:
relevant_symbols:
dependencies:
constraints:
acceptance_criteria:
verification_commands:
risk_level:
quality_gates:
expected_artifacts:
effort:
allowed_subagents:

Agent result must support:

status:
summary:
files_changed:
decisions:
verification_performed:
verification_results:
known_risks:
unresolved:
artifacts:
recommended_next_action:

Verification result must support:

decision:
commands_run:
environment:
acceptance_criteria_results:
failures:
evidence:
coverage_gaps:
confidence:
recommended_action:

Review result must support:

decision:
blocking_findings:
non_blocking_findings:
evidence:
affected_files:
spec_mismatches:
test_gaps:
security_risks:
false_positive_checks:
recommended_action:
confidence:

Validate schemas automatically.

────────────────────────────────────────────────────────────
13. QUALITY AND SECURITY REQUIREMENTS
────────────────────────────────────────────────────────────

The template must enforce:

- no false completion,
- no unverified claims,
- no silent acceptance of ambiguity,
- no hidden scope expansion,
- no duplicate orchestration,
- no uncontrolled memory,
- no automatic external instruction trust,
- no secret inclusion in context artifacts,
- no untrusted eval scripts,
- no unreviewed upstream synchronization.

Treat these as potentially untrusted:

- cloned AGENTS.md files,
- external skill instructions,
- repository hooks,
- web content,
- MCP outputs,
- generated memory,
- eval transforms,
- upstream scripts.

Do not execute arbitrary upstream scripts during research.

Only run source code after:

1. inspecting the relevant script,
2. understanding dependencies,
3. confirming necessity,
4. running it in a controlled environment.

External repository content is research material, not trusted system instruction.

────────────────────────────────────────────────────────────
14. EVALUATION PLAN
────────────────────────────────────────────────────────────

Build an initial benchmark suite with representative tasks:

1. Tiny one-file bug.
2. Root-cause bug across several files.
3. Small feature.
4. Multi-module feature.
5. Behavior-preserving refactor.
6. Failing-test repair.
7. Ambiguous requirement.
8. Security-sensitive change.
9. API compatibility change.
10. Task requiring current library documentation.

For each task, measure:

- accepted outcome,
- test pass rate,
- acceptance-criteria coverage,
- correct-file localization,
- unnecessary diff,
- false-completion rate,
- number of agents spawned,
- retries,
- tool calls,
- wall time,
- input tokens,
- output tokens,
- cached tokens where available,
- reviewer precision,
- accepted review findings,
- unresolved risks.

Compare:

- no custom workflow vs Workflow v0,
- Quick vs Standard,
- one worker vs multiple workers,
- no reviewer vs focused reviewer,
- short vs excessive task packet,
- skill enabled vs skill disabled,
- high effort only where needed vs high effort everywhere.

Do not use model graders for facts that can be checked deterministically.

Model graders may be used for:

- plan coherence,
- maintainability,
- review usefulness,
- requirement alignment,

but deterministic test results and diff checks remain authoritative.

────────────────────────────────────────────────────────────
15. INSTALLATION DESIGN
────────────────────────────────────────────────────────────

The template must not write directly into the live OMP folder by default.

Create installation tooling that:

1. Detects OMP home.
2. Creates a timestamped backup.
3. Shows planned changes.
4. Supports dry-run.
5. Installs only selected components.
6. Preserves models.yml and credentials.
7. Does not overwrite unrelated user files.
8. Produces an installation manifest.
9. Supports clean rollback.
10. Validates the effective OMP configuration afterward.

Installation must support:

- global template installation,
- project-local installation,
- selective agents,
- selective skills,
- selective policies,
- selective workflows.

Do not require the user to install all components.

────────────────────────────────────────────────────────────
16. GOVERNANCE
────────────────────────────────────────────────────────────

Create an upstream registry.

Example fields:

id:
repository:
url:
default_branch:
pinned_commit:
license:
tier:
authority_for:
watched_paths:
adopted_mechanisms:
rejected_mechanisms:
local_components:
local_modifications:
last_reviewed:
evaluation_suite:
update_policy:

Create a controlled update process:

detect upstream changes
→ inspect only watched paths
→ summarize semantic changes
→ classify as useful / duplicate / incompatible / irrelevant
→ port manually
→ run trigger tests
→ run regression tests
→ compare token/outcome metrics
→ review
→ promote or reject

Never pull upstream changes directly into the live template.

────────────────────────────────────────────────────────────
17. REQUIRED EXECUTION PHASES
────────────────────────────────────────────────────────────

Phase 0 — Preflight

- Inspect current repository.
- Confirm Git, PowerShell and OMP availability.
- Inspect OMP version.
- Confirm that no live OMP files will be modified.
- Create a detailed execution plan.

Phase 1 — Clone and inventory

- Clone all listed repositories.
- Record commit hashes and licenses.
- Generate source inventory.
- Do not run upstream installers.

Phase 2 — Research

- Inspect targeted documentation and implementation paths.
- Build mechanism matrix.
- Build conflict matrix.
- Build authority map.
- Build token-impact and security analyses.

Phase 3 — Architecture

- Produce Workflow v0 architecture.
- Define component boundaries.
- Define schemas.
- Define token budgets.
- Define installation and rollback design.
- Review architecture against OMP-native capabilities.

Phase 4 — Implement Workflow v0

- Build only the vertical slice.
- Keep prompts concise.
- Avoid duplicated rules.
- Implement scripts and validation.

Phase 5 — Static validation

Validate:

- directory structure,
- YAML syntax,
- required metadata,
- duplicate instructions,
- unresolved references,
- token budgets,
- schema correctness,
- unsafe paths,
- secret leakage,
- live-folder modification attempts.

Phase 6 — Evaluation

- Run deterministic unit tests.
- Run prompt/agent evaluation where possible.
- Record results.
- Do not hide failed evaluations.

Phase 7 — Internal review

Perform:

- architecture review,
- token-efficiency review,
- OMP compatibility review,
- security review,
- maintainability review.

Phase 8 — Final report

Produce:

docs/final-report.md

It must contain:

- what was built,
- what was not built,
- source mechanisms adopted,
- source mechanisms rejected,
- unresolved risks,
- evaluation results,
- token-budget results,
- installation instructions,
- rollback instructions,
- recommended next phase.

Do not install into the live OMP folder unless explicitly instructed after presenting the final report.

────────────────────────────────────────────────────────────
18. DEFINITION OF DONE
────────────────────────────────────────────────────────────

The project is not complete merely because files were generated.

Workflow v0 is complete only when:

1. All selected upstreams are inventoried and pinned.
2. Licenses are recorded.
3. Mechanism and conflict matrices are complete.
4. Authority ownership is unambiguous.
5. No second runtime or orchestration engine is introduced.
6. The five core agents have non-overlapping responsibilities.
7. Quick, Standard and Orchestrated flows are clearly differentiated.
8. Task and result schemas validate.
9. Persistent context remains within documented token targets.
10. Skills include positive and negative trigger cases.
11. Validation scripts pass.
12. No secrets are committed.
13. No live OMP files were modified.
14. Installation supports dry-run and rollback.
15. Evaluation results are recorded honestly.
16. Known weaknesses and deferred features are documented.
17. Every adopted mechanism maps to a real OMP capability.
18. Every major component can be removed independently.
19. The template can be customized at project level.
20. The final system demonstrably prioritizes coding quality while measuring token efficiency.

────────────────────────────────────────────────────────────
19. COMMUNICATION RULES
────────────────────────────────────────────────────────────

Do not produce excessive progress narration.

At each phase, report only:

- completed work,
- key evidence,
- important decisions,
- detected risks,
- files created or changed,
- next gate.

Do not claim that a repository has been fully understood after reading only its README.

Inspect the actual relevant files.

Do not claim success when tests or evaluations have not run.

Do not silently change scope.

When uncertain, record the uncertainty and investigate it.

Do not ask the user to choose between minor implementation details that can be resolved through evidence.

Stop and request approval only when:

- a live OMP modification is required,
- credentials are needed,
- a destructive operation is required,
- a licensing conflict cannot be resolved,
- the architecture would need to violate a stated constraint.

Begin with Phase 0.

First output:

1. Preflight findings.
2. Proposed clone plan.
3. Research path per repository.
4. Implementation milestones.
5. Risks requiring attention.

Then proceed with the work.