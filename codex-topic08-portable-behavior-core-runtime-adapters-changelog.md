# Topic 08 — Portable Behavior Core and Runtime Adapters

<!-- topic08-projection:behavior-core -->

Date: 2026-08-14  
Workspace policy: local-only; no branch creation, staging, commit, push, PR, or live OMP install.  
Status: `IMPLEMENTED_NOT_PROMOTED`

## Approved decisions

- `template/.omp/contracts/behavior-manifest.json` is the selected behavior authority;
  `registry/skill-lock.yml` is generated from it.
- The current selected skills are `task-triage`, `systematic-debugging`, and
  `evidence-before-completion`. This is an extensible reviewed roster, not a permanent cap.
- Worker alone autoloads `evidence-before-completion`; Cheap Scout and Reviewer autoload none.
- Main-session `agent_tasks` explicitly submits routine Topic 04 lifecycle operations. It is not
  available in child sessions and does not expose purge/restore/takeover/migration authority.
- Read-only diagnosis remains usable without task state. Generic `edit`, `write`, and `bash`
  require one valid main-session task binding or a canonical managed child packet.
- OMP is installable with status `IMPLEMENTED_NOT_PROMOTED`. Claude has a complete mapping but
  remains `DESIGNED_NOT_VERIFIED` and non-installable. Missing Opus is not a blocker.
- External tools and MCP integrations supply capability only; they do not select policy,
  workflow, lifecycle, or acceptance.
- Semantic trigger and pressure promotion belongs to Topic 11. Broader cross-runtime install and
  promotion belongs to Topic 12.

## Implementation surfaces

- Portable schema/core/manifest under `template/.omp/contracts/`.
- Three selected skills, six trigger fixtures, and one deterministic pressure suite.
- Worker-only agent frontmatter autoload.
- `agent_tasks`, catalog reconciliation, and mutation gate in
  `template/.omp/extensions/agent-task-boundary.js`.
- Component 2.1 install/update/rollback ownership and generated lock checking.
- Focused validator, source attachments, mutation suite, and full-validator integration.
- Current-product guide and narrow active spec/document projections.

## Source and runtime matrix

- Pinned clean OMP source: `3a8591a8af5b6d200088d12ca75a5517cb064fa8`.
- Eleven LF-normalized source ranges are bound in `scripts/lib/topic08-behavior-core.ps1`.
- Installed OMP 17.2.12: available at `C:\Users\MrThien\AppData\Local\omp\omp.exe`.
- OMP 17.2.10 executable: unavailable locally; no download or downgrade attempted.
- Topic 07 therefore independently retains `OPEN-T07-RUNTIME-02`; Topic 08 does not relabel or
  resolve that promotion blocker.

## Verification record

Completed focused checkpoints before final evidence capture:

- behavior core: 7/7 Node tests;
- skill contract: 4/4 Node tests;
- `agent_tasks`: 6/6 Node tests;
- behavior/catalog/mutation gate: 7/7 Node tests;
- Topic 08 installer/update/rollback: 19 assertions;
- affected Topic 06 installer: 45 assertions;
- affected Topic 07 managed runtime: 55 assertions;
- affected Topic 06 managed boundary: 17 assertions;
- generated manifest/component locks: current;
- focused Topic 08 contract without not-yet-generated evidence: 17 PASS, 0 WARN, 0 FAIL;
- all eleven pinned OMP source attachments: PASS.

Final evidence is written only after all remaining regression and full-validator commands pass.
The evidence capture script records command outcomes and hashes without raw provider transcripts or
secrets. This changelog must not be read as runtime promotion evidence by itself.
