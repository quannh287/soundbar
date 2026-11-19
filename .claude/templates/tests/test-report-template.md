---
id: test-report-{F-XXX}-{slug}
type: test-report
feature_id: "{F-XXX}"
# KHÔNG có `mode` — mode là chuyện của từng scope (file scope giữ); roll-up không derive được sạch khi các scope khác mode
test_design_ref: "tests/{F-XXX}-{slug}/test-design.md"
derived_from:                  # pin của TỪNG scope, chép lại từ file scope — lệch ⇒ roll-up cũ, sinh lại
  validation: { file: test-report-validation.md, test_exec_version: 0, date: "{YYYY-MM-DD}" }
  functional: { file: test-report-functional.md, test_exec_version: 0, date: "{YYYY-MM-DD}" }
  e2e:        { file: test-report-e2e.md,        test_exec_version: 0, date: "{YYYY-MM-DD}" }
  # nfr:      { file: test-report-nfr.md,        test_exec_version: 0, date: "{YYYY-MM-DD}" }   # thêm khi scope nfr có TC
  # dm:       { file: test-report-dm.md,         test_exec_version: 0, date: "{YYYY-MM-DD}" }   # thêm khi scope dm có TC
date: "{YYYY-MM-DD}"
status: draft
referenced_by:
  - 02-artifacts.md > Test Execution Artifacts > test-report.md
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/test-report.md — ROLL-UP (030 D0).

ROLL-UP KHÔNG GIỮ DỮ KIỆN RIÊNG NÀO. Mọi số ở đây derive từ các `test-report-{scope}.md` cùng thư mục
(format: `templates/tests/test-report-scope-template.md`) ⇒ luôn dựng lại được, không có gì để mất.
Ngoại lệ duy nhất: cột `Tổng TC` đọc từ bảng `Test Cases` của `test-exec-{scope}.md` (§4 ở validation/
functional, §5 ở e2e — gọi bằng TÊN bảng, không bằng số) — MẪU SỐ của scope, tức TC mà scope
đó thực thi (031 D15). KHÔNG lấy `Tổng TC` của `test-design.md`: nó đếm cả TC `Autoable = NO` (ca
visual) nên feature có một TC visual là hai số lệch vĩnh viễn ⇒ roll-up báo stale mãi mãi.

AI GHI: skill tầng vừa chạy (`/spec-test-retrofit-{scope}`) — **dựng lại trọn** file này từ mọi
`test-report-*.md` có mặt (trừ chính nó), KHÔNG đọc bản roll-up cũ, KHÔNG gộp thêm gì.
`/spec-test-exec` chỉ TẠO file lần đầu rồi thôi (030 D23). KHÔNG ai sửa tay (030 D22).
⚠ Glob `test-report*.md` khớp CẢ file này — mọi chỗ liệt kê/đếm file phải trừ roll-up ra.

CẤM Ở ROLL-UP: đoạn văn · bảng per-TC · evidence mutation · mô tả finding · cột `Xong`.
Có một câu chỉ sống ở đây là roll-up không dựng lại được ⇒ vỡ D0. Chi tiết finding/evidence: mở file scope.

CHỈ 3 section, đúng thứ tự: 1 Trạng thái theo scope · 2 Coverage · 3 Action Items.
KHÔNG `Results`/`Findings`/`Blockers`/`Pruned`/`Sanity-Red Ledger`/bảng tổng theo tier (030 D18),
KHÔNG `Change History`/timeline/run-log. Lịch sử = git log/diff + commit message (015 §3B).
KHÔNG có template_version / migrations — test-side ngoài /artifact-audit + /artifact-migrate.

"CHƯA CHẠY" = `pin v0`, KHÔNG phải "không có file": scope có TC luôn được `/spec-test-exec` scaffold sẵn
file scope ⇒ cột `Report` VẪN link, chỉ ghi `(chưa chạy)` cạnh pin. Scope KHÔNG có TC ⇒ không file, không dòng.
`nfr`/`dm` chưa có skill nào ghi result ⇒ toàn bộ not-run cho tới khi có writer; roll-up vẫn cộng chúng
vào §1 nên lỗ hiện ra thành SỐ, không im lặng (030 D22).

LUẬT TRÌNH BÀY (030 DS7) — thân roll-up chỉ được gồm 4 loại dòng:
  | heading `## N. Tên` | bảng (dòng bắt đầu `|`) | blockquote `>` ≤3 dòng/khối | dòng `**Nhãn:** …` |
CẤM: đoạn văn trần · bullet nhiều dòng · câu kể quá trình · blockquote narrative.
BUDGET + KHUÔN CÂU của §3 (giống hệt §5 của file scope — cùng vai thì cùng cột, 030 D21):
  Việc  ≤100  động từ + đối tượng cụ thể   ✅ `sửa createItem nhận ""`   ❌ "xem lại validator"
  Nguồn ≤40   CHỈ ID: `FIND-*` · `BLK-*` · req-ID (với `coverage-gap`)
  Loại  ≤16   MỘT nhãn từ tập đóng 8 nhãn (test-core §7)
  PIC   ≤12   `🤖` hoặc `👤 DEV`/`👤 BA`/`👤 QC` — DERIVE theo map ở test-core §7
(dòng `**Mục:**` miễn trần — nội dung là anchor link, không phải câu)

PHẦN BỊ CẮT ĐI ĐÂU (030 D10): luật chung → `references/retrofit-core.md` · diễn tiến "đã thử gì"
→ COMMIT MESSAGE · chi tiết per-TC + evidence → `test-report-{scope}.md`.
-->

# Test Report — {Feature Name}

**Feature**: {F-XXX} | **Date**: {YYYY-MM-DD}

**Mục:** [1 Trạng thái theo scope](#1-trạng-thái-theo-scope) · [2 Coverage](#2-coverage) · [3 Action Items](#3-action-items) `6`

> Roll-up **derive** từ các `test-report-{scope}.md` cùng thư mục — không giữ dữ kiện riêng nào.
> Cột `Tổng TC` là ngoại lệ: đọc từ bảng `Test Cases` của `test-exec-{scope}.md` — TC mà scope đó thực thi (TC `Autoable = NO` ở lại test-design).
> Chi tiết finding/evidence: mở file scope tương ứng.

## 1. Trạng thái theo scope

**Legend:** `🟢 pass` · `🔴 fail` · `⏭ skip` · `— not-run` · `🟡 flaky` · `Pin` = version test-exec mà result đang phản ánh (`v0` = chưa chạy).

| Scope | Report | Pin | Tổng TC | 🟢 | 🔴 | ⏭ | 🟡 | — | 🔴 finding mở | Action mở |
|---|---|---|---|---|---|---|---|---|---|---|
| validation | [→](./test-report-validation.md) | `v3` | 12 | 9 | 2 | 1 | 0 | 0 | 2 | 4 |
| functional | [→](./test-report-functional.md) | `v2` | 28 | 25 | 0 | 2 | 1 | 0 | 0 | 2 |
| e2e | [→](./test-report-e2e.md) | `v0` *(chưa chạy)* | 6 | 0 | 0 | 0 | 0 | 6 | 0 | 0 |
| **Tổng** | | | **46** | **34** | **2** | **3** | **1** | **6** | **2** | **6** |

> `🔴 finding mở` = số finding còn đỏ ở §2 của file scope, **trừ** dòng `dup-of` (cùng nguyên nhân với tầng trước).
> Feature có TC `nfr`/`dm` ⇒ thêm dòng cho chúng, pin đọc y như 3 scope trên.

## 2. Coverage

| Loại | Covered (pass) | Tổng | Đỏ | Nguồn |
|---|---|---|---|---|
| VR | 1 | 2 | 1 | validation |
| Story AC | 5 | 6 | 0 | functional |
| FAC | 0 | 2 | 0 | e2e *(chưa chạy)* |

## 3. Action Items

> Bảng **phẳng** — một dòng / việc, trích nguyên văn từ §5 Next Actions của các file scope, **đúng bộ
> cột đó**. Chỉ khác: gộp mọi scope và **sắp `🤖` trước `👤`**. Tiền tố `ID` cho biết mở file scope nào.
> KHÔNG cột `Xong` — "đã làm" thể hiện bằng action biến mất ở lượt chạy sau (nguồn hết đỏ ⇒ hết action).

**Loại:** `bug-code` · `spec-drift` · `flaky` · `test-error` (verdict finding) · `harness` · `refactor` · `need-clarify` (blocker) · `coverage-gap` (scope không phủ được: chưa có TC, **hoặc** mọi TC của trụ đó `Autoable = NO` ⇒ kiểm tay).
**PIC:** `🤖` = *agent tự xử* · `👤 DEV`/`👤 BA`/`👤 QC` = *chờ người chốt, agent KHÔNG đụng*. Suy ra từ cột `Loại` theo map ở `test-core §7`.

| ID | Việc | Nguồn | Loại | PIC |
|---|---|---|---|---|
| `A-VAL-1` | sửa `createItem` nhận `""` | `FIND-VAL-01` | `bug-code` | `🤖` |
| `A-FUN-2` | ổn định hoá chờ toast ở `todo.spec.ts` | `FIND-FUN-01` | `flaky` | `🤖` |
| `A-VAL-2` | quyết `SD-1` ở `/spec-new F-002`: sửa VR theo code, hay giữ VR (code sai) | `FIND-VAL-02` | `spec-drift` | `👤 BA` |
| `A-VAL-3` | dựng DB in-memory cho tier `be:persistence` | `BLK-VAL-1` | `harness` | `👤 DEV` |
| `A-VAL-4` | thêm TC accept sát biên cho `VR-F002-002` vào test-design | `VR-F002-002` | `coverage-gap` | `👤 QC` |
| `A-FUN-1` | tách seam gửi mail khỏi `RegisterHandler` | `BLK-FUN-1` | `refactor` | `👤 DEV` |
