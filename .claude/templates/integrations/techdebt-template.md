---
slug: "{slug}"
created: {YYYY-MM-DD}
referenced_by:
  - 02-artifacts.md > 3. Integration Artifacts > 3.8 techdebt.md
  - skills/review-integration/SKILL.md > Bước 2 — Luôn ghi findings vào techdebt.md
---

# Tech Debt — {title}

<!--
Sổ nợ của DEV — finding /build trả được. Nợ của BA (spec im lặng · code lệch có dấu vết) ở sổ spec-debt.md cạnh frd, đừng trộn.

ANCHOR bắt buộc trên mọi dòng Critical/Important — câu đã approve mà finding trỏ về,
thuộc tập ĐÓNG: AC-* · VR-* · FAC-* · `tech.md › {section}` · GUARD-* · C-XXX-RXX.
Không neo được ⇒ KHÔNG phải Critical/Important; nó là spec_gap → sổ spec-debt.md của feature.

HEADING: vòng 1 để trần; vòng k>1 ghi thêm `(review vòng {k}, tham chiếu {prev-sha})`.

HAI DẤU NGOẶC (chỉ vòng k>1):
  *(trên code chưa đổi từ {prev-sha})*        — file/dòng không nằm trong git diff {prev-sha}..HEAD
  *(vòng {k-1} không nêu vì …; nâng vì …)*    — finding trùng một dòng "Đã cân nhắc" vòng trước

MỤC "Đã cân nhắc, không nêu": ghi khi section có ≥1 Critical/Important. Một dòng/điểm,
KHÔNG checkbox (ghi chú, không phải nợ). Nó giữ lại quyết định "đã nhìn và bỏ qua" cho
vòng review sau đọc — reviewer là subagent mới mỗi vòng. Đừng để phình thành review thứ hai.
-->

## {YYYY-MM-DD} — {short-sha}

### Correctness
- [ ] **Critical** · anchor `{anchor}` — {tên ngắn gọn}

### Security
- [ ] **Important** · anchor `{anchor}` — {tên ngắn gọn}

### Đã cân nhắc, không nêu
- {điểm} — {vì sao không phải Important: anchor nào cho phép / là style / đã có test}
