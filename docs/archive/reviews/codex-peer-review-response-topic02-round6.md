REOPEN_TOPIC_02

Không có Critical. Có **2 Important**, không có Minor.

## Findings

### Important R6-F1 — Hợp đồng LSP bốn gate vẫn bị chiếu thành mô hình hai/ba gate

Pinned OMP xác nhận bốn điều kiện độc lập: allowlist, `task.enableLsp`, parent-session/plan-mode, và `lsp.enabled` tại [structured-subagent.ts:318](</D:/Dev/Projects/omp-template/_research/upstreams/oh-my-pi/packages/coding-agent/src/task/structured-subagent.ts:318>), [tools/index.ts:593](</D:/Dev/Projects/omp-template/_research/upstreams/oh-my-pi/packages/coding-agent/src/tools/index.ts:593>) và [executor.ts:2676](</D:/Dev/Projects/omp-template/_research/upstreams/oh-my-pi/packages/coding-agent/src/task/executor.ts:2676>).

Chi tiết canonical trong [spec/07:69](</D:/Dev/Projects/omp-template/spec/07-retrieval-and-code-understanding.md:69>) đúng, nhưng các active projection vẫn mâu thuẫn:

- Contract Summary của chính spec 07 chỉ liệt kê allowlist + `task.enableLsp` + parent session, bỏ `lsp.enabled`: [spec/07:296](</D:/Dev/Projects/omp-template/spec/07-retrieval-and-code-understanding.md:296>).
- DNA nói “Both gates apply” cho allowlist + `task.enableLsp`, rồi chỉ dùng câu chung “any required gate”: [DNA:324](</D:/Dev/Projects/omp-template/spec/key/01-dna.md:324>).
- Target architecture cũng chỉ quy định hai mục này: [spec/01:133](</D:/Dev/Projects/omp-template/spec/01-target-architecture.md:133>).
- Active source-evidence README tuyên bố tool bị gate bởi “BOTH” `session.enableLsp` và allowlist, vẫn bỏ `lsp.enabled`: [spec/README:336](</D:/Dev/Projects/omp-template/spec/README.md:336>). Fence tại `:353-355` chỉ làm role choices không-authoritative; source facts vẫn là evidence.
- `spec/02` tự tuyên bố mọi claim đã source-verified nhưng cũng trình bày mô hình thiếu `lsp.enabled`: [spec/02:168](</D:/Dev/Projects/omp-template/spec/02-runtime-semantics.md:168>).
- Canonical spec 13 yêu cầu CR-41 là L0 check riêng tại [spec/13:69](</D:/Dev/Projects/omp-template/spec/13-validation-and-evaluation.md:69>), trong khi Phase 06 T-06.1 chỉ chiếu CR-39/CR-40 và phép kiểm allowlist↔`task.enableLsp`: [Phase 06:50](</D:/Dev/Projects/omp-template/spec/phases/phase-06-evaluation.md:50>). L1 có generic “effective conjunction”, nhưng L0 projection vẫn thiếu CR-41.

Do đó một triển khai theo Summary/DNA/Phase-06 L0 có thể coi `lsp.enabled=false` là hợp lệ rồi dispatch selected LSP contract không có tool thực tế. Đây là selected-path safety defect.

Focused guard false-green vì chỉ tìm generic “fails closed”/“different contract”, không kiểm đủ bốn gate: [helper:261](</D:/Dev/Projects/omp-template/scripts/lib/topic02-workflow-lifecycle.ps1:261>), [helper:417](</D:/Dev/Projects/omp-template/scripts/lib/topic02-workflow-lifecycle.ps1:417>), [good fixture:164](</D:/Dev/Projects/omp-template/scripts/tests/topic02-workflow-lifecycle.Tests.ps1:164>). Snapshot sai trên vẫn đạt `262/0/0`.

### Important R6-F2 — Context7 fallback “silently” trái hợp đồng disclosed named skips

Canonical retrieval rule yêu cầu mọi skipped level dùng một reason trong `permitted_skips` và phải disclose: [spec/07:201](</D:/Dev/Projects/omp-template/spec/07-retrieval-and-code-understanding.md:201>), [spec/07:225](</D:/Dev/Projects/omp-template/spec/07-retrieval-and-code-understanding.md:225>), [Contract Summary:304](</D:/Dev/Projects/omp-template/spec/07-retrieval-and-code-understanding.md:304>). Phase 03 chiếu đúng tại [Phase 03:76](</D:/Dev/Projects/omp-template/spec/phases/phase-03-context-efficiency.md:76>).

Nhưng:

- `permitted_skips` không có reason “Context7 unavailable”.
- Cùng spec 07 yêu cầu fallback về level 3 khi Context7 vắng mà không reconcile disclosure rule: [spec/07:243](</D:/Dev/Projects/omp-template/spec/07-retrieval-and-code-understanding.md:243>).
- DNA quy định rõ fallback đó diễn ra **silently**: [DNA:343](</D:/Dev/Projects/omp-template/spec/key/01-dna.md:343>).

Khi retrieval đã cần level 4 nhưng MCP không tồn tại, contract hiện tại buộc vừa skip/fallback vừa cấm undisclosed skip, nhưng không cung cấp named reason hợp lệ. Đây là mâu thuẫn ảnh hưởng fallback behavior và evidence validity, nên không đủ nhẹ để xếp Minor theo verdict policy.

Guard chỉ kiểm exact Phase-03 exhaustion phrase tại [helper:355](</D:/Dev/Projects/omp-template/scripts/lib/topic02-workflow-lifecycle.ps1:355>) và mutation [tests:536](</D:/Dev/Projects/omp-template/scripts/tests/topic02-workflow-lifecycle.Tests.ps1:536>); không kiểm DNA/spec-07 silent fallback.

Whitespace normalization tự nó hoạt động đúng: cả wrapped-required và wrapped-forbidden đều match sau khi `\s+` được collapse ở [helper:33](</D:/Dev/Projects/omp-template/scripts/lib/topic02-workflow-lifecycle.ps1:33>). False green đến từ needle coverage/context-insensitive matching, không phải Markdown wrapping.

## Bằng chứng tái lập

- Packet SHA-256: `05C8FE205D8714FE421EDB98DC1FFFFB306317E9D529E02BC4FF1F138DA21291`.
- Immutable prior evidence: `20/20` hash khớp.
- Round-6 load-bearing table: `31/31` khớp, `0` missing/mismatch.
- Historical Phase-00 pins: `7/7` khớp.
- Round-5 ledger: `9693849ECF51FD300904438D90824690A0B5E18C0EF9D5251A5011F92964A1FD`.
- Round-5 response: `EB7DAAAF7C59A96625F380CF043AF0D05A926636DD6433F183649A4A00DD7CDF`.
- Repository: branch `main`; HEAD `62fecf277dc9d5e47d06319387eac747462214c1`; staged paths `0`. Final observed dirty count `143`, thuộc worktree có sẵn.
- Pinned OMP: `3a8591a8af5b6d200088d12ca75a5517cb064fa8`, clean, version `17.2.10`.
- Mutation suite: exit `0`, `PASS Topic 02 validator self-test (78 assertions)`. Các Round-5 sentinels đều phát đúng asserted `T02-*` failure khi được đưa vào fixture.
- Focused validator: exit `0`, `262 passed, 0 warnings, 0 failed`.
- Full validator: exit `0`, `102 passed, 1 warnings, 0 failed`; warning duy nhất là RULES budget `226 < 300`.
- `git diff --check`: exit `0`; chỉ Phase-00 CRLF advisory.
- Phase DAG: đủ 9 canonical edges, cả hai chiều `Blocks`/`Depends on`, `0` reciprocal failures.
- Source anchors tái lập:
  - Slash expansion chỉ bắt đầu với `/`; unknown file command giữ nguyên text: [slash-commands.ts:113](</D:/Dev/Projects/omp-template/_research/upstreams/oh-my-pi/packages/coding-agent/src/extensibility/slash-commands.ts:113>).
  - Agent session chỉ thử command expansion cho slash-prefixed input: [agent-session.ts:4942](</D:/Dev/Projects/omp-template/_research/upstreams/oh-my-pi/packages/coding-agent/src/session/agent-session.ts:4942>).
  - Handoff mở session mới, reset session-scoped state và inject handoff context: [session-handoff.ts:217](</D:/Dev/Projects/omp-template/_research/upstreams/oh-my-pi/packages/coding-agent/src/session/session-handoff.ts:217>).
- History fences hợp lệ: [spec/03:7](</D:/Dev/Projects/omp-template/spec/03-agent-topology.md:7>) và [Phase 02:112](</D:/Dev/Projects/omp-template/spec/phases/phase-02-core-orchestration.md:112>). Runtime migration vẫn được tuyên bố deferred.

## Disposition findings cũ

| Finding | Disposition |
|---|---|
| R1-F1 | **CLOSED** — verification/review được khóa trước task start và nằm trong material-change rule. |
| R1-F2 | **CLOSED** — DNA L2 fence hợp lệ; L3–L7 responsibility-based; review contract/risk-gated. |
| R1-F3 | **OPEN** — complete selected-path projection vẫn sai ở LSP. |
| R2-F1 / R3-F1 / R4-F1 / R5-F1 | **OPEN** — direct degraded-run prose đã được sửa, nhưng four-gate projection và guard vẫn chưa đóng. |
| R5-F2 | **CLOSED trong finding gốc** — Phase 03 không còn exhaustion gate. R6-F2 là drift mới ở DNA/spec 07. |
| R5-F3 | **CLOSED** — spec 05 gắn `.task/` với non-isolated retained workspace, không gắn workflow name; isolated dùng parent artifact domain. |

## Trả lời 12 câu

| # | Trả lời |
|---|---|
| 1 | **Có.** Verification/review khóa trước task start và material change bao phủ chúng. |
| 2 | **Có.** DNA topology-neutral trong phạm vi được hỏi; review contract/risk-gated. |
| 3 | **Không hoàn toàn.** Manifest derivation không hard-code count/name/schema/skill, nhưng Phase-06 L0 không chiếu CR-41 đầy đủ. |
| 4 | **Không.** Complete selected-path projection vẫn còn R6-F1. |
| 5 | **Có.** No-prefix, `/quick`, compatibility hints, missing slash và internal reclassification phù hợp pinned OMP. |
| 6 | **Có.** Task/work-unit/candidate/session và evidence invalidation đủ rõ để triển khai. |
| 7 | **Có.** Compaction, handoff, fork và resume giữ đúng ownership distinctions. |
| 8 | **Có.** Task terminals tách khỏi Topic-01 evaluation categories, không thấy loophole. |
| 9 | **Có.** Orchestrated là structural và chạy sequential được; không bắt buộc dispatch/agents/batch/parallel/isolation/review. |
| 10 | **Không.** Bash/schema/skill/alias/barrier/batch/isolation có conditional safe shapes; LSP projection vẫn thiếu gate. |
| 11 | **Có.** Cheap Scout optional, configurable, read-only, fail-soft và không có token/lifecycle gate. |
| 12 | **Không hoàn toàn.** Hashes, Git, OMP, DAG, fences và runtime non-claims đều tái lập; nhưng active LSP source-evidence surfaces vẫn trình bày incomplete gate model. |

Tôi không edit, format, stage, commit, reset, clean, move hay xóa repository file nào và không sửa pinned OMP. Chỉ mutation suite bắt buộc tạo rồi dọn fixture trong system temp; final repo staged count vẫn `0`, load-bearing hashes vẫn `31/31`, OMP vẫn clean.
