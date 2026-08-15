# Claude Repository Cleanup, Restructure, README, and Publish Prompt

You are Claude acting as the repository-polish implementer for omp-custom. Work directly in:

    D:\Dev\Projects\omp-template

Your mission is to produce a clean, understandable GitHub repository without losing product,
evidence, provenance, user work, or recoverability:

1. Remove proven junk, generated scratch, exact duplicates, and files no longer used.
2. Reorganize repository content into a coherent, maintainable folder structure.
3. Redesign README.md using the presentation style of the Meep README as inspiration, adapted
   truthfully to this project.
4. Create logical commits and push the resulting review candidate to the current feature branch.

This prompt authorizes bounded repository edits, proven cleanup, commits, and one non-force push to
the named feature branch. It does not authorize a merge, release, tag, pull request, provider/model
campaign, live installation, credential change, history rewrite, force push, or mutation outside
this repository.

## 1. Truthful starting state

Reproduce this baseline before changing anything. Do not copy it blindly into the final report.

- Repository: D:\Dev\Projects\omp-template
- Branch: codex/topic03-agent-topology
- Baseline HEAD: 509cc43b5cbe74ba0edd25a3ab09c696c5a7e247
- Remote: origin = https://github.com/manhthien2005/omp-custom.git
- Current branch has no configured upstream.
- Staged paths: 0
- Tracked changed paths: 110
- Untracked paths visible through the current ignore policy: 1054
- Treat every existing modification and untracked non-generated file as owner work until evidence
  proves otherwise.

Current focused validators have been freshly reproduced:

| Gate | Result |
|---|---:|
| Topic 02 | 649 passed, 0 warnings, 0 failed |
| Topic 03 | 22 PASS, 0 WARN, 0 FAIL |
| Topic 04 | 41 PASS, 0 WARN, 0 FAIL |
| Topic 05 | 25 PASS, 0 WARN, 0 FAIL |
| Topic 06 | 19 PASS, 0 WARN, 0 FAIL |
| Topic 07 | 22 PASS, 0 WARN, 0 FAIL |
| Topic 08 | 17 PASS, 0 WARN, 0 FAIL |
| Round 09-12 | 16 PASS, 0 WARN, 0 FAIL |
| Full validation | 356 passed, 1 known advisory warning, 0 failed |

The known warning is the existing approximate token-budget advisory for
template/.omp/AGENTS.md. It is not permission to introduce any new warning.

CLAUDE-F-001 has been reconciled as three subclaims:

- current-workspace scratch can be selected by git add .: CONFIRMED_BY_BOTH, Minor;
- git commit --all stages previously untracked scratch: REJECTED_WITH_EVIDENCE;
- this repository should ignore .agent-tasks/: REJECTED_WITH_EVIDENCE.

The accepted narrow ignore correction is:

~~~gitignore
/.claude/tmp/
/.claude/worktrees/
/.tmp-phase00-*/
~~~

Do not add .agent-tasks/. Git projects store task state under the Git common directory, while the
non-Git fallback creates its own nested ignore policy.

## 2. Critical linked-worktree warning

The directory .claude/worktrees/spec-key-dna is not ordinary trash. It is a registered linked Git
worktree:

- branch: worktree-spec-key-dna
- HEAD: d84efef7b6f4ee056907083b6e8dcaedf7d60470
- it has commits not reachable from codex/topic03-agent-topology;
- it currently has modified files:
  - spec/key/05-coverage-audit.md
  - spec/key/repos/oh-my-pi-settings.md
- it currently has an untracked file:
  - omp-custom-round7-final-static-review-to-opus5.md

Ignoring .claude/worktrees/ is allowed. Deleting or force-removing that worktree is not allowed
unless all of the following are proved:

1. every unique commit and dirty byte has an intentional destination;
2. the final candidate contains the accepted content or a documented rejection;
3. no uncommitted file is discarded;
4. git worktree remove succeeds without --force.

If those conditions cannot be proved, leave the worktree registered and local, keep it ignored
from the main worktree, and report it as retained local state. A clean GitHub repository does not
require destroying a safe local worktree.

## 3. Non-negotiable safety rules

- Never run git reset --hard, git checkout --, git restore on owner changes, git clean, or an
  equivalent bulk-discard command.
- Never use git worktree remove --force.
- Never amend, rebase, squash, rewrite published history, delete a remote branch, or force push.
- Never stage or commit .claude local data, .tmp-phase00-* content, credentials, sessions, secret
  values, generated telemetry, caches, build products, or nested repository internals.
- Never print or quote suspected secret values. Report only path, classification, and safe
  structural metadata.
- Never delete an untracked file merely because it is untracked or unreferenced. Unreferenced is
  not proof of unused.
- Preserve docs/evidence/phase-00 as immutable historical evidence.
- Preserve the original Claude preflight snapshot, report, reconciliation, and packet hashes as
  historical provenance. Do not overwrite them with post-cleanup values.
- Preserve the governed installable layout under template/.omp unless an executable contract and
  all consumers are deliberately migrated.
- Preserve exact validator sentinels and HTML projection markers in README.md unless the relevant
  validator and authority are intentionally updated together.
- Do not install into a live project or user OMP directory. Do not run a provider/model campaign.
- Do not change Git credentials or authentication configuration. If push authentication fails,
  stop and report the exact safe error without retry loops.
- For any recursive deletion on Windows, resolve the exact absolute target first, prove it is
  strictly inside D:\Dev\Projects\omp-template, and operate on explicit literal paths one at a
  time. Never pass a wildcard, unresolved variable, repository root, home directory, or computed
  broad path to a recursive delete.

## 4. Phase A — preflight and disposition inventory

Before editing, read:

- README.md, CHANGELOG.md, LICENSES.md, .gitignore;
- docs/architecture.md, docs/installation.md, docs/final-report.md;
- docs/task-state.md, docs/agent-boundaries.md, docs/behavior-core.md;
- spec/README.md and active phase/spec authority;
- registry manifests and every current-product evidence manifest;
- scripts/install-template.ps1, scripts/uninstall-template.ps1, and all validate-*.ps1 entry points;
- docs/audit/claude-preflight-2026-08-14/reports/claude-prepilot-audit-report.md;
- docs/audit/claude-preflight-2026-08-14/reports/codex-reconciliation.md;
- this prompt.

Reproduce:

~~~powershell
git status --short
git diff --name-status
git diff --cached --name-only
git branch -vv
git remote -v
git worktree list --porcelain
git -C .claude/worktrees/spec-key-dna status --short
~~~

Build a complete disposition table before deleting or moving anything. Each path or coherent path
family must have exactly one classification:

- KEEP_ROOT — belongs in the public repository root;
- KEEP_IN_PLACE — governed runtime/spec/test/evidence path whose current location is intentional;
- MOVE — active material with a clearly better canonical location;
- ARCHIVE — useful historical review/provenance material no longer active;
- DELETE_GENERATED — reproducible cache, scratch, empty junk, or exact duplicate with proof;
- IGNORE_LOCAL — machine-local material that must remain outside Git;
- OWNER_DECISION_REQUIRED — potentially valuable content whose authority cannot be resolved.

For every MOVE, ARCHIVE, or DELETE_GENERATED row record:

- old path;
- proposed destination, if any;
- tracked/untracked status;
- byte count and SHA-256;
- inbound references found with rg;
- manifest/validator/installer ownership;
- reason and recovery story.

Write the inventory and final mapping to:

    docs/audit/claude-preflight-2026-08-14/reports/claude-repo-polish-report.md

The report may evolve during execution, but it must retain the original before-state inventory and
the final disposition.

## 5. Phase B — bounded cleanup

### 5.1 Close the real ignore gap

Preserve existing .gitignore rules, including evals/results/, and add the three root-anchored rules:

~~~gitignore
/.claude/tmp/
/.claude/worktrees/
/.tmp-phase00-*/
~~~

Verify each rule with git check-ignore -v --no-index. Also prove that a hypothetical
.claude/settings.json remains visible to Git so future project-owned Claude configuration is not
silently hidden.

Search the entire repository for manifests that bind the prior .gitignore hash. Update every
current-product binding through the repository-owned deterministic capture mechanism. At the
current baseline, Round 09-12 is known to bind it; do not assume it is still the only consumer
after restructuring.

### 5.2 Local scratch

- .claude/tmp/: inspect structurally without printing values; delete only after confirming it is
  local tool scratch and not the registered worktree.
- .tmp-phase00-e2/, .tmp-phase00-e3bg/, and .tmp-phase00-e3g/: prove they are disposable experiment
  copies and that authoritative evidence exists elsewhere. Delete only these exact validated
  literal paths. Do not use a wildcard deletion command.
- .claude/worktrees/spec-key-dna: follow the linked-worktree warning above. Ignoring is sufficient
  if safe retirement is not proved.

### 5.3 Repository artifacts

Use hashes and reference searches to distinguish:

- active product/runtime/specification content;
- current evidence;
- immutable evidence;
- approved designs and implementation plans;
- audit/reconciliation history;
- superseded prompts/responses/changelogs;
- exact duplicates;
- generated or empty junk.

Prefer ARCHIVE over DELETE when a file preserves a unique decision, audit claim, correction,
provenance link, or acceptance consequence. Delete only when regeneration or duplication is
demonstrated. Never delete evidence to make the repository look smaller.

## 6. Phase C — GitHub-oriented folder structure

Aim for a root that explains the product at a glance. A reasonable root contains only canonical
project entry files and stable product directories, for example:

~~~text
README.md
CHANGELOG.md
LICENSES.md
.gitignore
template/
scripts/
spec/
docs/
registry/
evals/
~~~

This is a principle, not permission to move governed directories gratuitously.

Recommended organization:

- docs/audit/ — formal audit packets, reconciliations, and bounded verification reports;
- docs/archive/reviews/ — historical Codex/Claude/Opus prompts, responses, round ledgers, and
  superseded review material that still has provenance value;
- docs/research/ — research and source analysis;
- docs/evidence/ — current and immutable evidence, retaining its governed structure;
- docs/superpowers/specs/ and docs/superpowers/plans/ — approved design/plan history unless a
  validated migration proves a better path;
- docs/ — active operator guides and architecture documents, optionally grouped only when all
  references and validators are migrated safely.

Focus the restructure on root clutter and clearly historical material. Avoid renaming template/,
scripts/, spec/, registry/, evals/, docs/evidence/, or template/.omp solely for aesthetics.

Requirements:

1. Use git mv for tracked moves.
2. Preserve history and use deterministic destination names.
3. Create a concise docs index if navigation materially improves.
4. Update every relative link, path literal, manifest entry, validator fixture, installer reference,
   and documentation cross-reference affected by a move.
5. Detect case-only collisions and Windows-invalid names before moving.
6. Do not add symlinks as compatibility shims.
7. After each coherent move group, run the smallest relevant validator before continuing.

## 7. Phase D — redesign README.md using Meep as a style reference

Study the current develop-branch README at:

https://github.com/manhthien2005/Meep/blob/develop/README.md

If GitHub rendering is unavailable, read:

https://raw.githubusercontent.com/manhthien2005/Meep/develop/README.md

Learn the presentation system, not the application content. Relevant style traits include:

- a centered, concise hero;
- one strong product sentence and a short supporting explanation;
- restrained, truthful badges;
- an early table of contents;
- scannable overview and highlights;
- a clear quick-start path;
- compact technology/capability tables;
- a readable repository tree;
- a curated documentation index;
- explicit status, limitations, license/provenance, and acknowledgements;
- consistent spacing, separators, and visual rhythm.

Do not copy Meep wording, product claims, screenshots, team section, technology list, license claim,
or decorative elements that do not belong to omp-custom.

README requirements for this project:

1. Keep the primary language clear technical English.
2. Present the canonical product name and a one-sentence value proposition above the fold.
3. State the truthful status prominently:
   - OMP: IMPLEMENTED_NOT_PROMOTED;
   - Claude adapter: DESIGNED_NOT_VERIFIED and non-installable;
   - model-assisted promotion campaign: NOT_RUN;
   - live installation: not proved by this repository campaign.
4. Explain the three-agent topology, commands, skills, durable task state, managed boundary,
   continuity, portable behavior core, evaluation, and safe installation without overwhelming the
   first screen.
5. Provide a minimal safe quick start, installation preview, real installation command, uninstall,
   and validation command.
6. Include a concise architecture or execution-flow explanation and the final project structure.
7. Link to the most useful operator, architecture, evidence, and provenance documents.
8. Preserve the exact active projection markers and all validator-required semantics currently
   embedded in README.md. They may be repositioned only if their consumers still pass.
9. Use only badges whose target and claim are real and maintainable. Do not invent a passing CI
   badge when no corresponding workflow exists. Do not claim an undeclared project license.
10. Do not invent a logo, screenshots, download count, production status, compatibility promise,
    contributor list, or benchmark result.
11. Make every relative link resolve on GitHub after the restructure.
12. Prefer a polished 150-260 line landing page over copying the current long chronological
    projection text verbatim. Move deep detail into linked canonical docs only when validators and
    authority remain intact.

## 8. Phase E — verification and evidence reconciliation

Do not weaken or delete tests to make a reorganization pass.

Run every focused validator independently:

~~~powershell
pwsh -NoLogo -NoProfile -File scripts/validate-topic02-workflow-lifecycle.ps1
pwsh -NoLogo -NoProfile -File scripts/validate-topic03-topology-routing.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic04-durable-state.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic05-progressive-retrieval.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic06-agent-boundary.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic07-context-continuity.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-topic08-behavior-core.ps1 -RepositoryRoot .
pwsh -NoLogo -NoProfile -File scripts/validate-round09-12-release-readiness.ps1 -RepositoryRoot .
~~~

Then run:

~~~powershell
pwsh -NoLogo -NoProfile -File scripts/tests/round09-12-validator-mutations.Tests.ps1
pwsh -NoLogo -NoProfile -File scripts/tests/round09-12-installer.Tests.ps1
node --test scripts/tests/round09-12-evaluation-core.Tests.mjs scripts/tests/round09-12-review-security.Tests.mjs
pwsh -NoLogo -NoProfile -File scripts/validate-template.ps1
git diff --check
~~~

Also perform independent repository checks:

- all README and active-doc relative links resolve;
- no tracked manifest points to a missing/moved path;
- no exact governed file hash is stale;
- no local scratch path is tracked or staged;
- git check-ignore proves the three new patterns and does not hide .claude/settings.json;
- no suspected credential/session/secret value is present in the staged diff;
- git status and staged-path lists match the intended final disposition;
- the remote URL and current branch remain the expected values.

The original packet at docs/audit/claude-preflight-2026-08-14 is historical evidence. Do not replace
01-CANDIDATE-SNAPSHOT.jsonl, 01-SNAPSHOT-SUMMARY.md, PACKET-SHA256.txt, or the original Claude
report.

Before the first commit, capture the final uncommitted candidate into a new file within the same
excluded packet directory:

~~~powershell
pwsh -NoLogo -NoProfile -File docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.ps1 -Capture -OutputPath docs/audit/claude-preflight-2026-08-14/02-POST-CLEANUP-CANDIDATE-SNAPSHOT.jsonl
pwsh -NoLogo -NoProfile -File docs/audit/claude-preflight-2026-08-14/capture-candidate-snapshot.ps1 -Verify -InputPath docs/audit/claude-preflight-2026-08-14/02-POST-CLEANUP-CANDIDATE-SNAPSHOT.jsonl
~~~

Create separate post-cleanup summary/checksum material. Do not edit the original packet checksum
to pretend the old audit reviewed new bytes.

Because committing changes advances HEAD and changes working-tree status identity, record both:

- the verified pre-commit snapshot digest and baseline HEAD;
- each final commit SHA and the final commit tree SHA.

CLAUDE-F-001 becomes FIXED_PENDING_CODEX_REVERIFICATION after your implementation. Do not label it
FIXED_AND_REVERIFIED_BY_BOTH. Codex must independently inspect the final commit candidate and rerun
the applicable gates.

## 9. Phase F — commit and push

Commit only after all required checks pass.

Create a small number of logical commits whose boundaries are independently understandable. Do not
create dozens of mechanical commits, and do not collapse unrelated product, evidence, cleanup, and
README changes into a misleading message. Suitable categories may include:

- completed product/spec/test/evidence candidate;
- repository hygiene and historical-artifact organization;
- README and documentation navigation;
- post-cleanup evidence reconciliation.

Use conventional, factual commit messages. Before every commit:

1. inspect git diff and git diff --cached;
2. inspect staged name/status and statistics;
3. verify no forbidden path or suspected secret is staged;
4. run the smallest gate covering that commit;
5. confirm the commit does not discard owner work.

After the final commit:

1. require a clean working tree except deliberately retained ignored local state;
2. rerun the full validator and git diff --check 509cc43b5cbe74ba0edd25a3ab09c696c5a7e247..HEAD against committed bytes;
3. fetch origin without changing local files;
4. determine whether origin/codex/topic03-agent-topology already exists;
5. refuse a non-fast-forward update and report it rather than rewriting history;
6. push only this feature branch:

~~~powershell
git push --set-upstream origin codex/topic03-agent-topology
~~~

Do not push main, do not merge into main, do not create a tag/release, and do not force push.

## 10. Stop conditions

Stop before commit or push and report OWNER_DECISION_REQUIRED if:

- a potentially valuable file cannot be classified safely;
- a registered worktree contains unique work that cannot be reconciled;
- a suspected secret is found in content proposed for commit;
- any Critical or Important finding appears;
- any required validator or negative-control suite fails;
- immutable evidence would need rewriting;
- the remote URL differs from the expected repository;
- the remote branch requires a non-fast-forward update;
- cleanup would require discarding or overwriting owner work.

For a Minor uncertainty, preserve or archive the file, document the limitation, and continue when
that is safe.

## 11. Required final response

At completion, report:

1. before/after root structure;
2. exact deleted paths and proof they were generated/redundant;
3. exact moved paths and old-to-new mapping;
4. retained ambiguous/local paths and why;
5. README design decisions learned from Meep and how they were adapted;
6. every validator/test command with exit code and reproduced counts;
7. evidence/snapshot files regenerated and their hashes;
8. logical commit list with SHA and message;
9. final tree SHA;
10. pushed remote and branch, including the GitHub branch URL;
11. remaining limitations;
12. CLAUDE-F-001 status as FIXED_PENDING_CODEX_REVERIFICATION.

Do not claim the repository is merged, released, promoted, production-ready, or independently
reverified by Codex.
