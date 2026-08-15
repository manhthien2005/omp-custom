REOPEN_TOPIC_02

Không có Critical. Có một Important làm Topic 02 chưa thể đóng: contract đã chọn LSP vẫn được phép chạy với năng lực suy giảm thay vì fail closed. Ngoài ra có hai Minor drift.

## Bằng chứng tái lập

- Packet SHA-256: `CE94F2F14B6C6C4E64DD71F11A56C709E01FC431445EF975D096BF618B270B5B`.
- Toàn bộ `54/54` hash trong packet khớp byte-for-byte, `0` mismatch:
  - prior immutable evidence: `16/16`;
  - Round-5 load-bearing table: `31/31`;
  - historical Phase-00 pins: `7/7`.
- Round-4 correction ledger: `0EFC0F62F60373E34A1699FF243B62BA83DD917ADA1E0E4C7263F0E548C0A40F`.
- Round-4 substantive response: `7015D11AF9A8CA3880468D9EADFAE28C1BC1A8AEAEF792EF1AD77557465D2FE7`.
- Git: branch `main`; HEAD `62fecf277dc9d5e47d06319387eac747462214c1`; staged paths `0`. Worktree có sẵn `139` dirty entries thuộc người dùng.
- Pinned OMP: HEAD `3a8591a8af5b6d200088d12ca75a5517cb064fa8`; dirty `0`; coding-agent `17.2.10`.
- Validators:
  - `PASS Topic 02 validator self-test (56 assertions)`;
  - focused: `224 passed, 0 warnings, 0 failed`;
  - full: `102 passed, 1 warnings, 0 failed`;
  - warning duy nhất: `template\.omp\RULES.md` có approximate budget `226 < 300`.
- `git diff --check`: exit `0`; chỉ advisory CRLF→LF tại `spec/phases/phase-00-foundation.md`.
- Phase DAG: `EXPECTED_EDGES=9`, `RECIPROCAL_FAILURES=0`.

Historical pins đều khớp:

- `template/.omp/AGENTS.md`: `3F194D81208872B6CDE4A51265156D06A8016810CAA9D24BF37B545E60848BBC`
- `template/.omp/agents/tech-lead.md`: `47B3060A725F9C41EA832E2CE8E7CBAEFCAFACB4137A9B4153C2819732016AD2`
- `quick.md`: `F4E9081846368DA140923C8D51C7BAB079DA4B75577019A412735DBAC4A21731`
- `standard.md`: `F849485369F0E8EE6D7D816752D7CAD263DA5381EF8216C319B19091FCBB626B`
- `orchestrated.md`: `D88179FA0C27B9EEDF9EE59B5CD6A59B75FC426BCDAD18061209942C36012D12`
- `task-triage/SKILL.md`: `D398AFAE80D199F6951C988A4D13C90FD4EFDE4E2B1290CF8A9AB642977430BC`
- `scripts/validate-template.ps1`: `D78594BA7DD28C843BDCCEC6F532FBBB491C9E380FD91B686B2AA70850D61701`

Pinned-source anchors xác nhận:

- `slash-commands.ts:110-129`, đặc biệt `:114`, trả nguyên văn input không bắt đầu bằng `/`.
- `agent-session.ts:4942-4966`, đặc biệt `:4946,4961-4964`, chỉ xử lý command khi input có `/`.
- `session-handoff.ts:239-241` tạo session mới; `:252-271` reset state theo session; `:273-275` inject handoff text như custom context.

History fences hợp lệ:

- `spec/03-agent-topology.md:7-15` fence sections B–I.
- `phase-02-core-orchestration.md:112-116` fence toàn bộ Appendix A.
- Phase 00 được giữ làm historical evidence.
- `spec/key/02-repo-synthesis.md:11-12` tự định danh là evidence layer, không phải decision authority.

## Findings

### Important — Selected LSP path degrades instead of failing closed

Approved contract yêu cầu mọi capability mà selected contract tiêu thụ phải fail closed. Active authority lại cho phép cùng selected LSP-consuming contract tiếp tục với semantics yếu hơn:

- `spec/key/01-dna.md:324-330` nói rõ `grep` không phải fallback cho `lsp`.
- `spec/13-validation-and-evaluation.md:94-96` yêu cầu effective LSP conjunction phải pass khi selected.
- Nhưng `spec/13-validation-and-evaluation.md:173-174` vẫn cho runtime tiếp tục dưới reduced-capability mode khi conjunction fail.
- `spec/07-retrieval-and-code-understanding.md:122-138` yêu cầu selected LSP-consuming role chuyển sang `grep` + ranged read; `:127-128` thừa nhận đây là “real degradation” và blast-radius review yếu đi; `:135-138` vẫn coi đó là một reduced-capability run hợp lệ.
- `spec/12-installation-and-rollback.md:225-230` nói thẳng conflict “degrades rather than refuses”.
- `phase-01-runtime-correctness.md:70-76,104-108,291` yêu cầu fallback giảm xuống grep/glob.
- `phase-05-installation-hardening.md:79-83,90-97` tiếp tục cùng chính sách.
- Round-4 ledger `:94-96` lại tuyên bố selected LSP consumers vẫn giữ capability conjunction fail-closed. Tuyên bố này không đúng với active specs trên.

Disclosure không biến một đường dẫn yếu hơn thành fail-closed. Nếu selected contract cần symbol-aware retrieval, preflight phải từ chối đường dẫn đó khi conjunction không đủ. Muốn tiếp tục thì phải chọn một fallback contract/path khác không tiêu thụ LSP, reconcile contract/manifest tương ứng, rồi validate đường dẫn mới.

Focused guard bỏ sót semantic này: `scripts/lib/topic02-workflow-lifecycle.ps1:247-258` và mutation tests `:359-364` chỉ bắt fixed-role LSP wording, không bắt “selected consumer may run degraded”. Vì vậy `224/0/0` là false green đối với invariant này.

Các semantic-equivalent khác đã được kiểm tra và không có cùng loophole:

- Bash: `spec/10:200-223` cấm verified PASS và không dispatch khi capability thiếu; `spec/13:175` chỉ cho REFUSE hoặc explicit `UNVERIFIED`.
- Schema: `spec/06:183-204`, KD-003 `:90-102`, Phase 04 `:155-160` buộc reject/recheck unvalidated output.
- Skills: Phase 06 `:50-56,81-117` buộc selected autoload names resolvable và exact selected skill discovery.
- Aliases: `spec/09:50-55,165-172` và Phase 06 `:97-100` fail khi selected alias không resolve.
- Batch/isolation fallback dừng đường parallel/batch không an toàn rồi chuyển sang một đường sequential hợp lệ; chúng không tiếp tục giả vờ thực hiện chính selected capability bị thiếu.

### Minor — Phase 03 vẫn bắt exhaustion theo tầng

- `phase-03-context-efficiency.md:76-83` nói mỗi retrieval level phải được thử trước khi escalation.
- `spec/07-retrieval-and-code-understanding.md:177-185` rút lại chính quy tắc exhaustion đó.
- `spec/07:202-228` thay bằng bounded escalation và permitted skips có lý do.

Phase 03 cần dùng canonical bounded-escalation rule, không dùng “each level must be tried”.

### Minor — `.task/` vẫn bị gắn sai với Standard

- `spec/05-context-and-token-model.md:197-222` nói `.task/` offload an toàn cho “Standard workflow only” và chỉ cho non-isolated “(Standard)” workers.
- `spec/04-workflow-sizing.md:163-171` và Phase 06 `:92-95` cho phép sequential, non-isolated Orchestrated.

Quy tắc đúng phải dựa trên isolation/retention responsibility, không dựa vào workflow name. Đây là drift bảo thủ, không làm classification hoặc selected-path safety mất hiệu lực.

## Disposition

- `R1-F1`: **CLOSED** — verification/review được khóa trước task start và nằm trong material-change rule tại design `:67-75`, canonical spec `:50-60`, KD-026 `:960-963`, active Phase 02 `:54-59`.
- `R1-F2`: **CLOSED** — DNA L2 fence hợp lệ; L3–L7 dùng selected responsibilities; review contract/risk-gated tại DNA `:534-539`.
- `R1-F3`: **REOPENED** — manifest derivation đã topology-neutral, nhưng selected LSP capability không fail closed.
- `R2-F1`: **OPEN**.
- `R3-F1`: **OPEN**.
- `R4-F1`: **REOPENED/OPEN**. Các exact fixed-roster/schema/skill clauses của Round 4 đã được sửa, nhưng umbrella “complete selected-contract projection” vẫn sai vì LSP fail-open và guard false-negative.

## Trả lời 12 câu

1. **Có.** Verification/review obligations được khóa trước task start và material change bao phủ chúng.
2. **Có.** DNA L2–L7 topology-neutral; review contract/risk-gated.
3. **Không.** Count/name/schema/skill assumptions đã được loại bỏ, nhưng selected LSP capability không fail closed.
4. **Không.** Complete active-authority projection vẫn còn Important nêu trên.
5. **Có.** No-prefix, `/quick`, compatibility, missing slash và internal reclassification khớp pinned OMP.
6. **Có.** Task/work-unit/candidate/session và evidence invalidation đủ rõ để triển khai.
7. **Có.** Compaction, handoff, fork và resume giữ đúng ownership distinctions.
8. **Có.** Task terminals và Topic-01 evaluation categories được tách rõ tại `spec/04:218-229`.
9. **Có.** Orchestrated là structural và có thể chạy sequential, không ép dispatch/agent/batch/parallel/isolation/review.
10. **Không.** Schema/skill/alias/barrier/bash/isolation đều conditional và fail closed; LSP là ngoại lệ active.
11. **Có.** Cheap Scout đơn giản, optional, configurable, read-only, fail-soft; token chỉ là telemetry, không routing/lifecycle gate.
12. **Có đối với các hạng mục được hỏi.** Phase ownership, history, runtime non-claims, hashes, source anchors, Git identity và dependencies đều trung thực và tái lập. Điều này không khắc phục defect semantic ở câu 3/10.

Tôi không sửa, format, stage, commit, reset, clean, move hoặc xóa file nào; không sửa pinned OMP. Packet hashes, staged count, dirty-count quan sát và OMP cleanliness vẫn không đổi sau audit.
