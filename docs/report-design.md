# Báo cáo Thiết kế: OMP Custom Workflow Template

> Historical Workflow v0 snapshot only; no current topology, dispatch, review, routing, or
> lifecycle authority. Current authority lives in the accepted design, key decisions, active
> specs, phase plans, and Topic 03-selected manifest.
> See `docs/architecture.md` and `docs/policies/model-routing.md` for current behavior.

**Dự án:** omp-custom  
**Phiên bản:** Workflow v0  
**Ngày hoàn thành:** 2026-08-07  
**Tác giả:** manhthien2005  
**Runtime mục tiêu:** OMP (Oh My Pi) 17.2.10  
**Model gateway:** OmniRoute → `omniroute/codex/gpt-5.6-sol-high`

---

## 1. Tóm tắt

Dự án này xây dựng một bộ cấu hình OMP chuẩn production để nâng cấp bất kỳ dự án nào từ "một agent đơn lẻ" thành "hệ thống multi-agent có phân vai và quality gate". Toàn bộ chạy natively trong OMP — không thêm runtime nào, không thay đổi model gateway.

**Kết quả validation:** 63/63 checks passed · 0 warnings · 0 failures.

---

## 2. Vấn đề cần giải quyết

OMP mặc định không có:
- Cơ chế phân vai rõ ràng (ai investigate, ai implement, ai verify?)
- Quality gate để đảm bảo output được kiểm tra trước khi trả lời
- Chính sách token để tránh context bloat
- Structured output cho agent-to-agent communication
- Triage để tự chọn workflow phù hợp với độ phức tạp của task

Kết quả: agent hay "làm luôn" mà không investigate kỹ, hoặc "nghĩ xong" mà không verify thực sự.

---

## 3. Giải pháp — Kiến trúc tổng thể

```
Người dùng
    │
    ▼
[task-triage skill]  ← chọn command phù hợp
    │
    ├─ /quick        (task nhỏ, rõ ràng)
    ├─ /standard     (task bình thường)
    └─ /orchestrated (task phức tạp, multi-file)
           │
           ▼
      [tech-lead]          ← coordinator, không code trực tiếp
      ┌────┴────┐
      ▼         ▼
 [explorer]  [implementer]  ← investigate rồi mới implement
      └────┬────┘
           ▼
      [verifier]            ← kiểm tra độc lập
           ▼
      [reviewer]            ← review evidence-backed
```

Mọi kết quả trả về theo schema YAML định nghĩa sẵn — không có "text tuỳ tiện".

---

## 4. Các thành phần đã xây dựng

### 4.1 Agents (5 files)

| Agent | Vai trò | Token budget | Spawns |
|---|---|---|---|
| `tech-lead` | Coordinator — nhận task, phân công, tổng hợp | ~478 | explorer, implementer, verifier, reviewer |
| `explorer` | Investigation — đọc code trước khi đề xuất | ~440 | — |
| `implementer` | Implement — vòng lặp inspect→edit→verify | ~623 | — |
| `verifier` | Kiểm tra độc lập — chạy lại từ đầu, không tin kết quả implementer | ~481 | — |
| `reviewer` | Code review — mọi nhận xét phải có evidence (file:line) | ~659 | — |

**Nguyên tắc thiết kế:** Mỗi agent chỉ làm một việc. Explorer không implement. Implementer không review. Verifier không phụ thuộc vào output của implementer.

### 4.2 Commands (3 slash commands)

| Command | Số bước | Khi dùng |
|---|---|---|
| `/quick` | 5 bước | Bug nhỏ, refactor đơn giản, task rõ requirement |
| `/standard` | 8 bước | Feature mới, bug cần investigate, thay đổi multi-file |
| `/orchestrated` | Full | Task phức tạp cần delegate toàn bộ cho multi-agent |

### 4.3 Skills (3 skills)

- **task-triage** — Clarification gate: nếu requirement mơ hồ thì hỏi trước, không đoán. Tự chọn command phù hợp.
- **systematic-debugging** — 4 phase: reproduce → isolate → fix → verify. Không fix mà chưa reproduce được.
- **evidence-before-completion** — Iron law: task chưa xong cho đến khi có evidence cụ thể (output thực tế, không phải "đã làm rồi").

### 4.4 Schemas (4 schemas)

Tất cả agent output đều có kiểu rõ ràng:

| Schema | Dùng bởi |
|---|---|
| `task-packet` | Input chuẩn hoá từ tech-lead xuống agent |
| `agent-result` | Output của mọi agent leaf (explorer, implementer) |
| `verification-result` | Output của verifier |
| `review-result` | Output của reviewer |

### 4.5 Policy-derived contracts

Không có policy runtime riêng. Điều khoản thực thi được đặt ngay tại consumer có thể áp dụng;
`docs/policies/` chỉ là tài liệu tham chiếu cho con người.

| Contract | Nơi thực thi | Tài liệu tham chiếu |
|---|---|---|
| Context budget | `AGENTS.md`, agent prompts, advisory validator | `docs/policies/context-budget.md` |
| Model routing | agent frontmatter, `config.yml`, Standard/Orchestrated | `docs/policies/model-routing.md` |
| Workflow sizing | Quick/Standard/Orchestrated commands | `spec/04-workflow-sizing.md` |
| Quality gates | task packet construction + Reviewer | `docs/policies/quality-gates.md` |
| Escalation | agent stop clauses + main-session instructions | `spec/04`, `spec/15` |

---

## 5. Nghiên cứu nguồn gốc

Trước khi thiết kế, đã clone shallow 17 repositories để nghiên cứu:

| Nguồn | Lấy gì | Không lấy gì |
|---|---|---|
| `kilocode` | Multi-agent role separation | Specific UI/API integrations |
| `aider` | Diff-only output discipline | Git workflow (OMP handles this) |
| `claude-code` | Compact error formats | Tool registry (dùng OMP tools) |
| `cursor-rules` | Context scoping patterns | IDE-specific rules |
| `gpt-engineer` | Task decomposition structure | Python runtime dependency |
| ... (17 repos tổng) | ... | ... |

**16 cơ chế được adopt** (ghi trong `registry/adoption-ledger.yml`)  
**17 cơ chế bị reject** (ghi trong `registry/rejected-mechanisms.yml`) — lý do chính: tạo dependency ngoài OMP, duplicate với OMP built-in, hoặc quá phức tạp so với lợi ích.

---

## 6. Quyết định thiết kế quan trọng

### 6.1 Không dùng workflows/, dùng commands/

OMP 17.2.10 discover slash commands từ `.omp/commands/`, không phải `.omp/workflows/`. Đây là lý do các slash command nằm ở `commands/`.

### 6.2 Model role thay vì model name

```yaml
# config.yml
modelRoles:
  coordinator: fast
  implementer: balanced
  verifier: thorough
```

Agent không hard-code tên model. Khi OmniRoute thay đổi model, chỉ cần sửa config.yml — không đụng vào agent files.

### 6.3 AGENTS.md là constitution, không phải instruction

AGENTS.md chứa các nguyên tắc chung (Karpathy principles, 12-Factor Agents). Agent files chỉ chứa role-specific instructions. Không duplicate nguyên tắc từ AGENTS.md vào agent files.

### 6.4 Token budget enforcement

Mỗi file có mục tiêu token rõ ràng và được kiểm tra bằng `validate-template.ps1`:

- AGENTS.md: 600–1200 tokens (hiện tại: ~922) ✅
- RULES.md: 150–700 tokens (hiện tại: ~226) ✅
- Mỗi agent: 400–1200 tokens ✅

### 6.5 Verifier hoạt động độc lập

Verifier không đọc output của implementer trước khi tự verify. Nó tự chạy lại kiểm tra từ đầu. Điều này phát hiện được "false positive" — implementer báo xong nhưng thực ra chưa xong.

---

## 7. Kết quả validation

```
=== Section 1: Required Files ===      32/32 PASS
=== Section 2: Token Budgets ===        7/7  PASS
=== Section 3: Constitutional Phrases  15/15 PASS
=== Section 4: YAML Non-Empty ===       9/9  PASS
─────────────────────────────────────────────────
TOTAL: 63 passed · 0 warnings · 0 failures
```

---

## 8. Cách cài đặt vào dự án

```powershell
# 1. Clone template
git clone https://github.com/manhthien2005/omp-custom.git

# 2. Preview (dry-run, an toàn)
.\scripts\install-template.ps1 -DryRun -TargetDir "D:\MyProject"

# 3. Cài thật (tự backup .omp/ hiện tại)
.\scripts\install-template.ps1 -TargetDir "D:\MyProject"

# 4. Nếu muốn rollback
.\scripts\uninstall-template.ps1 -TargetDir "D:\MyProject"
```

---

## 9. Cách dùng sau khi cài

```
# Không biết dùng command nào:
/quick task-triage

# Task nhỏ, rõ ràng:
/quick fix the null check in auth.ts

# Task bình thường:
/standard add pagination to the user list API

# Task phức tạp:
/orchestrated refactor the entire payment module to use the new SDK
```

---

## 10. Giới hạn hiện tại (Workflow v0)

| Giới hạn | Kế hoạch |
|---|---|
| Benchmark script là stub | v0.1: thêm eval runner |
| Skill hashes trong skill-lock.yml là null | v0.1: thêm hash thực sau khi skills ổn định |
| Chưa có CI/CD pipeline | v0.2: GitHub Actions validate on PR |
| Chưa test trên Windows ARM | Cần test thực tế |

---

## 11. Files quan trọng để tham khảo

| File | Nội dung |
|---|---|
| `template/.omp/AGENTS.md` | Constitution — đọc đầu tiên |
| `template/.omp/RULES.md` | 8 invariants không được vi phạm |
| `registry/adoption-ledger.yml` | 16 cơ chế được adopt với lý do |
| `registry/rejected-mechanisms.yml` | 17 cơ chế bị reject với lý do |
| `docs/architecture.md` | Kiến trúc chi tiết |
| `docs/token-strategy.md` | Chiến lược token và explicit safe context continuity |
| `docs/security.md` | Security constraints |

---

*Báo cáo này được tạo tự động bởi Claude Code (Opus 5) trong quá trình xây dựng template.*
