REOPEN_TOPIC_02

## Kết luận

Round 3 còn **một finding Important**: R2-F1 chưa được đóng. Nhiều điều khoản active vẫn ép roster bốn role và batch/LSP/isolation/schema/settings vô điều kiện, trái với contract đã duyệt rằng Topic 03 mới chọn topology và capabilities.

Không có Critical hoặc Minor finding.

## Bằng chứng tái lập

```text
Get-FileHash codex-peer-review-packet-topic02-round3.md -Algorithm SHA256
2D809ED7ED1776CB3E5A7FCEE7C6D28D33D72942E628DD770CC670995DAE6295
```

- Load-bearing table: `31/31` exact, `0` mismatch.
- Immutable earlier evidence: `8/8` exact, `0` mismatch.
- Historical Phase-00 pins: `7/7` exact, `0` mismatch.
- History fences đã xác minh trực tiếp:
  - `spec/03-agent-topology.md:9-10`: B–I là hypothesis pre-Topic-03, không có execution authority.
  - `spec/phases/phase-02-core-orchestration.md:112,115`: nội dung dưới Appendix A là lịch sử, không có execution authority.

Trạng thái cuối, dùng lại cùng cách đếm ban đầu:

```text
FINAL_REPO=main 62fecf277dc9d5e47d06319387eac747462214c1 staged=0 dirty_entries=131
FINAL_OMP=3a8591a8af5b6d200088d12ca75a5517cb064fa8 clean=True dirty_entries=0 coding-agent=17.2.10
```

Các kiểm tra:

```text
pwsh -NoProfile -File .\scripts\tests\topic02-workflow-lifecycle.Tests.ps1
PASS Topic 02 validator self-test (34 assertions)

pwsh -NoProfile -File .\scripts\validate-topic02-workflow-lifecycle.ps1
Topic 02 lifecycle: 177 passed, 0 warnings, 0 failed

pwsh -NoProfile -File .\scripts\validate-template.ps1
Results: 102 passed, 1 warnings, 0 failed
```

Warning duy nhất là warning đã biết:

```text
approx-token-budget below target (226 < 300): template\.omp\RULES.md
```

```text
git diff --check
warning: Phase-00 CRLF/LF advisory
exit=0
```

Phase DAG:

```text
P0→P1  P1→P2  P2→P3  P2→P4  P3→P6
P4→P6  P1→P5  P5→P6  P6→P7
EXPECTED_EDGES=9
RECIPROCAL_FAILURES=0
```

Pinned OMP source anchors đều khớp:

- `slash-commands.ts:110-129`, đặc biệt `113-114`: non-slash text được trả nguyên dạng.
- `agent-session.ts:4942-4966`, đặc biệt `4945-4964`: command handling chỉ chạy khi input bắt đầu bằng slash.
- `session-handoff.ts:97-103,217-275`: tạo session mới tại `239`, xóa/reset state session-scoped tại `252-270`, rồi inject generated handoff context tại `273-275`; không phải durable lifecycle authority.

## Disposition bốn finding

- **R1-F1 — CLOSED.** Task start khóa cả verification/review obligations và material-change rule tại:
  - design `:67-74`
  - `spec/04-workflow-sizing.md:50-60`
  - DNA `:113-117`
  - KD-026 `spec/key/04-decision-log.md:947-955`
  - active Phase 02 `:56`.

- **R1-F2 — CLOSED.** DNA nói rõ worker dispatch optional, Topic 03 sở hữu worker graph/roster/dispatch, roster cũ non-authoritative tại `spec/key/01-dna.md:145-152`; independent review là contract/risk-gated, không do Orchestrated tự động ép, tại `:528-533`.

- **R1-F3 — CLOSED.** `spec/13-validation-and-evaluation.md:53-88,164-168` và `phase-06-evaluation.md:51-76,255-256` tiêu thụ Topic-03-selected manifest, kiểm tra mọi selected barrier/capability fail-closed, không giả định count/name cố định.

- **R2-F1 — OPEN.** Active authority ngoài hai vùng historical vẫn chứa exact roster và unconditional capability/topology requirements; chi tiết trong finding dưới đây.

## Finding theo severity

### Critical

Không có.

### Important — Active authority vẫn ép fixed topology/capabilities

Các câu sau nằm trong section active có nhãn `Decision`, `Contract Summary`, `Acceptance`, hoặc `Expected Final Architecture`, không nằm trong hai history fence được packet cho phép:

1. **Batch bị ép toàn cục**

   `spec/key/04-decision-log.md:179-200`:

   - `:181-183`: “Every dispatch in every command file uses the batch wire form”.
   - `:198-200`: bác bỏ việc disable `task.batch`.

   Điều này trực tiếp trái với contract cho phép Topic 03 chọn sequential/non-batch path; chính DNA `:127-130` chỉ yêu cầu batch shape nếu Topic 03 chọn batch dispatch.

2. **LSP gắn bắt buộc vào exact named roles**

   `spec/07-retrieval-and-code-understanding.md:289-295`:

   - `:291`: ``lsp` MUST be added to `explorer`, `implementer`, and `reviewer` allowlists`.

   `spec/key/03-token-quality-model.md:404-413`:

   - `:410-413`: “ADOPT for explorer, implementer, reviewer. Not verifier”.

   Hai câu này mâu thuẫn ngay với supersession headers của chính các file tại `spec/07:5-7` và token model `:9-10`.

3. **Exact four-worker roster vẫn được gọi là constraint**

   `spec/08-isolation-and-concurrency.md:773-777`:

   - `:774-776`: “The four-worker constraint (CR-33: explorer, implementer, verifier, reviewer)”.

   `spec/README.md:415-424`:

   - `:420`: “Explicit per-task isolation; implementers isolated, readers not”.

   Đây là exact roster và unconditional isolation trong active final architecture, trái với boundary tại `spec/08:5-9`.

4. **Phase acceptance vẫn yêu cầu exact four agents và schemas**

   `spec/phases/phase-01-runtime-correctness.md:168-171` yêu cầu mọi `explorer`, `implementer`, `verifier`, `reviewer` có schema, dù header `:5-8` nói roster/capabilities phải đến từ selected manifest.

5. **Installer vẫn bắt buộc bốn role keys, isolation và LSP**

   `spec/phases/phase-05-installation-hardening.md:102-107` yêu cầu installer thêm:

   - bốn worker role keys;
   - hai isolation keys;
   - `task.enableLsp: true`.

   `:134-140` còn gọi LSP, isolation, concurrency và các settings khác là prerequisites chung của template. Điều này trái với header `:5-7`, vốn nói aliases/settings phải được derive từ Topic-03 manifest.

6. **Focused validator false-negative**

   - `scripts/lib/topic02-workflow-lifecycle.ps1:221-228` chỉ cấm hai literal LSP cũ, không cấm câu `MUST` hiện tại.
   - `:329-333` chỉ cấm một literal `owned_model_roles` cũ, không cấm acceptance “adds the four worker role keys”.
   - KD-006 chỉ được kiểm tra có phrase contract-gate tại `:105-107`; batch decision mâu thuẫn không bị audit.

Vì vậy validator vẫn báo `177/0/0` trong khi active clauses trên tồn tại.

Đây không phải preference về roster. Một Topic-03 manifest hợp lệ chọn role đổi tên/gộp, flat dispatch, không LSP, không isolation hoặc không schema worker sẽ đồng thời:

- hợp lệ theo approved Topic-02 contract; và
- thất bại theo các active Decision/Acceptance trên.

Contract vì thế vẫn contradictory và preempts Topic 03.

### Minor

Không có.

## Trả lời 12 câu bắt buộc

1. **Có.** Verification/review obligations được khóa trước task start và nằm trong material-contract-change rule ở mọi authority cốt lõi; R1-F1 đóng.

2. **Có.** Bản thân DNA topology-neutral; roster cũ rõ ràng non-authoritative và review contract/risk-gated; R1-F2 đóng.

3. **Có.** `spec/13` và Phase 06 dùng selected manifest, không hard-code count/name, đồng thời kiểm tra selected barriers/capabilities fail-closed; R1-F3 đóng.

4. **Không.** R2-F1 chưa chạm hết active authority surfaces. Independent-evidence và selected-path safety không bị làm yếu, nhưng fixed roster/unconditional capabilities vẫn còn.

5. **Có.** No-prefix, `/quick`, compatibility hints, missing-slash và internal reclassification nhất quán với ba pinned OMP source anchors.

6. **Có.** Task, work unit, candidate và session được phân biệt; candidate freeze và evidence invalidation đủ rõ để triển khai. Durable representation được hoãn đúng cho Topic 04.

7. **Có.** Compaction giữ session identity; handoff tạo reconciled successor; fork là deliberate alternative/work-unit; resume bắt buộc reconciliation.

8. **Có.** Task terminals tách khỏi Topic-01 evaluation classifications; waiver là contract change, không phải loophole, và không thấy denominator loophole.

9. **Không, xét toàn bộ active corpus.** Canonical definition là structural và sequentially implementable, nhưng KD-006, spec08, README và các phase acceptance vẫn ép batch/agents/isolation.

10. **Không, xét toàn bộ active corpus.** `spec/13`/Phase 06 xử lý selected capabilities đúng fail-closed, nhưng spec07/token model/Phase05 vẫn khiến capability vắng mặt chọn hoặc làm invalid topology.

11. **Có.** Cheap Scout vẫn optional, configurable, read-only, fail-soft; failure chỉ fallback và token telemetry không trở thành lifecycle gate.

12. **Không.** Hashes, runtime non-claims, pins, Phase DAG và history fences riêng lẻ đều trung thực; nhưng tuyên bố Round 3 đã loại hết active fixed-topology authority mâu thuẫn với các clauses nêu trên.

## Xác nhận read-only

Tôi không sửa, format, stage, commit, reset, clean, move hoặc xóa bất kỳ file repository nào; không sửa pinned OMP. Không dùng công cụ chỉnh file. Mandatory self-test chỉ dùng fixture tạm do chính test quản lý ngoài repository rồi dọn sạch; trạng thái repository cuối vẫn `main`, đúng HEAD, `0` staged, cùng `131` dirty entries như ban đầu, và OMP vẫn sạch đúng commit.
