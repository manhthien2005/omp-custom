# Claude Repository Polish Report

## Audit identity

- Executor model/runtime: Claude Opus 5 (1M context) via Claude Code
- Repository root: `D:\Dev\Projects\omp-template`
- Branch: `codex/topic03-agent-topology`
- Baseline HEAD: `509cc43b5cbe74ba0edd25a3ab09c696c5a7e247`
- Prompt: `CLAUDE-REPO-CLEANUP-RESTRUCTURE-README-PUBLISH-PROMPT.md`

---

## Before-state inventory

### Tracked files at baseline

- Total tracked modified paths: 110
- Staged paths: 0
- Untracked non-hidden paths visible through current ignore policy: ~869

### Root directory structure (before)

```
.claude/                    ← local tool data
.tmp-phase00-e2/            ← untracked experiment copy (296 MB)
.tmp-phase00-e3bg/          ← untracked experiment copy (148 MB)
.tmp-phase00-e3g/           ← untracked experiment copy (865 KB)
_research/                  ← ignored upstream clones
.gitignore                  ← tracked, modified
CHANGELOG.md                ← tracked, modified
LICENSES.md                 ← tracked
README.md                   ← tracked, modified
codex-*                     ← 24 tracked + 31 untracked review/changelog/prompt/response files
docs/                       ← tracked operator/spec/evidence content
evals/                      ← tracked evaluation fixtures
fable5-full-pending-opus-audit-prompt.md  ← untracked
omp-custom-*                ← 1 tracked + 17 untracked review/response files
opus5-*                     ← 18 tracked + 9 untracked response/packet/prompt files
plan.md                     ← tracked original design prompt
registry/                   ← tracked governance manifests
scripts/                    ← tracked installers/validators/tests
spec/                       ← tracked specification
template/                   ← tracked installable OMP config
```

### Linked worktree state

- Path: `.claude/worktrees/spec-key-dna`
- Branch: `worktree-spec-key-dna`
- HEAD: `d84efef7b6f4ee056907083b6e8dcaedf7d60470`
- Modified: `spec/key/05-coverage-audit.md`, `spec/key/repos/oh-my-pi-settings.md`
- Untracked: `omp-custom-round7-final-static-review-to-opus5.md`
- Disposition: IGNORE_LOCAL (registered linked worktree with unique commits; cannot safely retire)

---

## Disposition table

| Old path | Classification | Destination | Status | Reason |
|---|---|---|---|---|
| `README.md` | KEEP_ROOT | stays (redesigned) | tracked, modified | Canonical project entry file |
| `CHANGELOG.md` | KEEP_ROOT | stays | tracked, modified | Canonical project entry file |
| `LICENSES.md` | KEEP_ROOT | stays | tracked | Canonical project entry file |
| `.gitignore` | KEEP_ROOT | stays (rules added) | tracked, modified | Repository metadata |
| `codex-round09-12-closure-evaluation-release-readiness-changelog.md` | KEEP_ROOT | stays | untracked | Hash+path bound by Round 09-12 validator |
| `codex-topic03-agent-topology-model-routing-changelog.md` | KEEP_ROOT | stays | tracked, modified | Validator-bound changelog |
| `codex-topic04-durable-task-state-changelog.md` | KEEP_ROOT | stays | untracked | Validator-governed file (existence check) |
| `codex-topic05-progressive-retrieval-codegraph-changelog.md` | KEEP_ROOT | stays | untracked | Current-product artifact |
| `codex-topic06-agent-boundary-contracts-changelog.md` | KEEP_ROOT | stays | untracked | Topic 06 governed file (existence check) |
| `codex-topic07-context-compaction-continuity-changelog.md` | KEEP_ROOT | stays | untracked | Topic 07 reads by root path |
| `codex-topic08-portable-behavior-core-runtime-adapters-changelog.md` | KEEP_ROOT | stays | untracked | Topic 08 governed file + projection marker |
| `template/` | KEEP_IN_PLACE | stays | tracked | Governed installable layout |
| `scripts/` | KEEP_IN_PLACE | stays | tracked | Governed validators/installers |
| `spec/` | KEEP_IN_PLACE | stays | tracked | Governed specification |
| `docs/` | KEEP_IN_PLACE | stays | tracked | Governed documentation/evidence |
| `registry/` | KEEP_IN_PLACE | stays | tracked | Governed governance manifests |
| `evals/` | KEEP_IN_PLACE | stays | tracked | Governed evaluation fixtures |
| `_research/` | IGNORE_LOCAL | stays (ignored) | ignored | Upstream clones per .gitignore |
| `.claude/worktrees/spec-key-dna/` | IGNORE_LOCAL | stays (ignored) | registered worktree | Unique commits; cannot safely retire |
| `.tmp-phase00-e2/` | DELETE_GENERATED | delete | untracked (~296 MB) | Disposable experiment copy; authoritative evidence in docs/evidence/phase-00/ |
| `.tmp-phase00-e3bg/` | DELETE_GENERATED | delete | untracked (~148 MB) | Disposable experiment copy; authoritative evidence in docs/evidence/phase-00/ |
| `.tmp-phase00-e3g/` | DELETE_GENERATED | delete | untracked (~865 KB) | Disposable experiment copy; authoritative evidence in docs/evidence/phase-00/ |
| `.claude/tmp/*` | DELETE_GENERATED or IGNORE_LOCAL | delete or retain+ignore | untracked | Local tool scratch; inspected structurally before deletion |
| `codex-peer-review-packet-topic01-round3.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical peer review packet |
| `codex-peer-review-packet-topic02-round{1-7}.md` (7) | ARCHIVE | docs/archive/reviews/ | untracked | Historical peer review packets |
| `codex-peer-review-prompt-topic01-attempt-02.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical review prompt |
| `codex-peer-review-prompt-topic01-optimization-metrics.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical review prompt |
| `codex-peer-review-prompt-topic01-round3.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical review prompt |
| `codex-peer-review-prompt-topic02-round{1-7}.md` (7) | ARCHIVE | docs/archive/reviews/ | untracked | Historical review prompts |
| `codex-peer-review-response-topic01-attempt-0{1,2}.md` (2) | ARCHIVE | docs/archive/reviews/ | untracked | Historical review responses |
| `codex-peer-review-response-topic01-round3.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical review response |
| `codex-peer-review-response-topic02-round{1-7}.md` (7) | ARCHIVE | docs/archive/reviews/ | untracked | Historical review responses |
| `codex-peer-review-response-topic02-round1-attempt-01-blocked-input.json` | ARCHIVE | docs/archive/reviews/ | untracked | Historical blocked input |
| `codex-phase00-*-changelog-for-opus5.md` (4) | ARCHIVE | docs/archive/reviews/ | untracked | Historical Phase 00 changelogs |
| `codex-response-F{7,8}-*-changelog-for-opus5.md` (2) | ARCHIVE | docs/archive/reviews/ | untracked | Historical correction changelogs |
| `codex-response-to-opus5-*.md` (2) | ARCHIVE | docs/archive/reviews/ | untracked | Historical Codex→Opus responses |
| `codex-topic01-{closure-status,optimization-metrics-changelog,sequential-validity-correction-ledger}.md` (3) | ARCHIVE | docs/archive/reviews/ | untracked | Historical Topic 01 artifacts |
| `codex-topic02-round{1-6}-correction-ledger.md` (6) | ARCHIVE | docs/archive/reviews/ | untracked | Historical Topic 02 ledgers |
| `codex-topic02-workflow-entry-task-lifecycle-changelog.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical Topic 02 changelog |
| `opus5-response-to-gpt56-*.md` (16) | ARCHIVE | docs/archive/reviews/ | tracked | Historical Opus5 responses (git mv) |
| `opus5-response.md` | ARCHIVE | docs/archive/reviews/ | tracked | Historical empty response (git mv) |
| `omp-custom-counter-review-agent-packet.md` | ARCHIVE | docs/archive/reviews/ | tracked | Historical counter-review (git mv) |
| `omp-custom-round{1-11,*-closure,*-handoff}*.md` (various) | ARCHIVE | docs/archive/reviews/ | untracked | Historical round artifacts |
| `omp-custom-F{3-7}*-to-opus5.md` (5) | ARCHIVE | docs/archive/reviews/ | untracked | Historical F-series audits |
| `omp-custom-focused-reconciliation-cr45-e3m-to-opus5.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical reconciliation |
| `omp-custom-PA01-PA04-followup-counter-to-opus5.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical follow-up |
| `omp-custom-static-review-closure-phase00-handoff.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical handoff |
| `opus5-audit-status-codex-topic01-optimization-metrics.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical audit status |
| `opus5-new-session-phase00-forward-audit-prompt.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical forward prompt |
| `opus5-response-to-codex-*.md` (2) | ARCHIVE | docs/archive/reviews/ | untracked | Historical Opus→Codex responses |
| `opus5-review-packet-codex-*.md` (2) | ARCHIVE | docs/archive/reviews/ | untracked | Historical review packets |
| `opus5-review-prompt-codex-*.md` (2) | ARCHIVE | docs/archive/reviews/ | untracked | Historical review prompts |
| `opus5-spec-key-numeric-verification-to-codex.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical verification |
| `fable5-full-pending-opus-audit-prompt.md` | ARCHIVE | docs/archive/reviews/ | untracked | Historical audit prompt |
| `plan.md` | ARCHIVE | docs/archive/reviews/ | tracked | Original design prompt (git mv) |

---

## Final disposition summary

*(To be updated after execution)*
