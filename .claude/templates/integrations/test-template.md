---
id: "{id}"
slug: "{slug}"
title: "{title}"
features: []
status: draft
created: {YYYY-MM-DD}
referenced_by:
  - 02-artifacts.md > 3. Integration Artifacts > 3.7 test.md > Cấu trúc
  - skills/spec-test/SKILL.md > Process > Bước 6: Ghi `test.md` — trước khi promote
---

## Context

<!-- Tóm tắt ngắn thông tin quan trọng từ context đã load (spec.md, tech.md optional, số TC test-design hiện tại của các feature touched), để file self-contained. -->

## Test Strategy

<!--
Strategy cho integration này — KHÔNG lặp lại Strategy chung của feature.
Chỉ ghi delta hoặc nhấn mạnh phần đặc thù integration:
- Loại test ưu tiên (functional / validation / FAC e2e: journey / consistency / integrity / NFR / data & migration).
- Yêu cầu data đặc thù integration (shape) — nguồn/refresh/env assignment thuộc execution layer, KHÔNG ở đây.
- Risk areas (vd: data migration cần backfill verify, integration đụng auth flow → security regression).
-->

### Approach

- {bullet ngắn}

## Delta

<!--
`Delta` là **bản ghi phép trừ**, KHÔNG phải patch (028 D3).

`/spec-test` gọi `/spec-test-design {F-XXX} --dry-run` → skill con derive lại toàn bộ từ `frd.md` ra
`test-design.md.next`, rồi `/spec-test` diff `test-design.md ↔ .next` theo field **`Key`**. Cái được áp
là **cả file mới** (`mv .next → test-design.md`), nên ở đây KHÔNG có `operation`, KHÔNG có nội dung TC,
KHÔNG có marker để ai đó đi apply. Đọc section này là để **review delta trước khi promote** — nó được
ghi TRƯỚC bước `mv`.

Một block per feature trong `features:` **có delta**. Feature no-delta → bỏ block, ghi `no-op` ở
`Reconcile Summary`. **Mọi** feature no-delta ⇒ lượt no-op toàn phần ⇒ `/spec-test` **không ghi lại
file này** (bản ghi delta của lượt trước được giữ; `git status` sạch).

Nhãn dòng (đúng năm nhánh join của `/spec-test-design` Bước 4.8):
- `[NEW]`    — `Key` chỉ có ở `.next`
- `[MODIFY]` — `Key` có ở cả hai, field derive đổi (ghi rõ `trước → sau`)
- `[KEEP?]`  — TC trong `.next` mang nhãn `chờ xác nhận` (mới xuất hiện ở lượt này) ⇒ không còn
               khớp luật derive nhưng **được GIỮ** nguyên. KHÔNG phải `[REMOVE]`: skill không xoá
               TC, QC quyết sau khi đọc. Nhận diện bằng **nhãn**, không bằng phép trừ tập `Key` —
               skill con không bao giờ bỏ một `Key` khỏi `.next`.
- `[manual]` — `Key: manual::*` (QC viết tay) ⇒ vùng cấm, không đụng
- dòng gộp   — `{N} TC không đổi`

Bảng scope: copy đúng bảng 7 cột `/spec-test-design` đã in ở lượt `--dry-run`. Cột `−chờ xác nhận` đếm
`[KEEP?]` — đừng đặt tên là `−removed`, không TC nào bị xoá.

`id_counters` + `versions.{scope}` do **`/spec-test-design` quản** (028 D8) — ghi lại ở đây là **báo cáo**,
không phải chỉ thị.
-->

### tests/{F-XXX}-{feature-slug}/test-design.md *(lặp block cho mỗi feature CÓ delta; no-delta thì bỏ block)*

| scope | trước | sau | +new | −chờ xác nhận | ~modified | manual giữ |
| --- | --- | --- | --- | --- | --- | --- |
| validation | 29 | 31 | +2 | −1 | ~2 | 0 |
| functional | 14 | 14 | 0 | 0 | ~1 | 1 |
| e2e | 2 | 2 | 0 | 0 | 0 | 0 |

**Dòng:**

- `[NEW]` `TC-F002-061` · `VR-F002-007::BVA::max+1` — VR mới trong frd
- `[NEW]` `TC-F002-062` · `VR-F002-007::BVA::max`
- `[MODIFY]` `TC-F002-017` · `Expected`: "255 ký tự" → "200 ký tự" (`Key` không đổi, ID giữ)
- `[KEEP?]` `TC-F002-018` · `VR-F002-001::BVA::max+1` — chờ xác nhận (VR-F002-001 đổi ngưỡng)
- `[manual]` `TC-F002-050` · `manual::race-double-submit` — không đụng
- 43 TC không đổi

**Bookkeeping** *(báo cáo từ `/spec-test-design`)*: `id_counters` tc 60 → 62 (chỉ tăng) · ts 3 → 3 · `versions` validation 1→2 · functional 1→2 · `check-ledger` ✓ SỔ KHỚP

<!--
TC cũ chưa có `Key` (file do `/spec-test` bản trước 028 ghi) → skill con xử ở nhánh bootstrap match lúc
dựng `.next`. Ghi thêm một dòng ở đây: `bootstrap: {k} TC stamp được Key · {j} TC để trống Key (xem Gaps)`.
-->

## Out of Scope

<!-- Những gì KHÔNG được test trong integration này và lý do (vd: thuộc layer khác như infra audit, NFR đã verify ở integration trước, ...) -->

## Open Questions

<!-- Các điểm còn mơ hồ cần clarify. Xóa section nếu không có. -->

## Reconcile Summary

<!-- Bảng để reviewer scan nhanh. Liệt kê **tất cả** feature trong `features:` — feature no-delta ghi `no-op`, feature mà lượt `--dry-run` fail ghi `⛔ derive fail` + lý do. -->

| Artifact | Kết quả | Summary |
| --- | --- | --- |
| `tests/F-XXX-{slug}/test-design.md` | reconciled | validation 29→31 (+2 −1 ~2) · functional ~1 · promote bằng `mv` |
| `tests/F-YYY-{slug}/test-design.md` | no-op | frd không đổi · `.next` đã xoá · `versions` không bump |
| `tests/F-ZZZ-{slug}/test-design.md` | ⛔ derive fail | `/spec-test-design --dry-run` không in dòng `DRY-RUN:` — {lý do skill con báo} |
