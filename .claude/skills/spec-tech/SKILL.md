---
name: spec-tech
description: Tạo tech.md cho một integration dựa trên spec.md đã được approve. Dùng sau khi BA đã hoàn thành spec.md. Nhận slug của integration từ argument hoặc cho phép chọn từ danh sách các spec.md chưa có tech.md.
---

# spec-tech

## Overview

Tạo `tech.md` cho một integration trong `.specs/integrations/{slug}/`.

`tech.md` là technical design — định nghĩa **how to build**: solution approach, data model changes, interfaces. Phải có `spec.md` đã approve trước khi chạy skill này.

## When to Use

- `spec.md` đã được BA approve và DEV cần thiết kế technical design
- Bắt đầu implement nhưng chưa có `tech.md`

## When NOT to Use

- `spec.md` chưa có hoặc chưa được approve → chạy `/spec-new` trước
- `sad.md` chưa có → chạy `/spec-sad` trước (cần tech stack để đưa ra design đúng hướng)
- Chỉ muốn cập nhật tech.md đã có → edit file trực tiếp

---

## Process

### Bước 1: Xác định integration

**Nếu có ARGUMENT:**
- Parse argument: có thể là số thứ tự (`2`, `002`) hoặc slug (`002-implement-todo`)
- Quét `.specs/integrations/*/spec.md`, tìm integration khớp với argument
- Nếu không tìm thấy → báo lỗi:
  > Không tìm thấy integration khớp với "{argument}". Kiểm tra lại tên hoặc số thứ tự.
- Nếu tìm thấy → dùng integration đó, bắt đầu luôn

**Nếu không có ARGUMENT:**

Quét `.specs/integrations/`. Liệt kê **tất cả** integrations có `spec.md`, đánh dấu những cái đã có `tech.md`:

```
Integrations:

  [1] 001-implement-auth    — Implement Auth             spec✓ tech✓
  [2] 002-implement-todo    — Implement Todo Management  spec✓ tech—

Chọn số integration:
```

Nếu không có integration nào → thông báo:
> Chưa có integration nào. Hãy chạy `/spec-new` trước.

Nếu integration đã có `tech.md` → hỏi trước khi tiếp tục:
> `tech.md` đã tồn tại cho integration này. Tiếp tục sẽ ghi đè. Tiếp tục không?

---

### Bước 1b: Gate check — spec.md phải approved

Đọc frontmatter của `.specs/integrations/{slug}/spec.md`.

Nếu `status` **không phải** `approved`:

> ⛔ `spec.md` của integration **{slug}** chưa được approve (status hiện tại: `{status}`).
>
> `/spec-new` luôn ghi `spec.md` với `status: approved` sau khi auto-cascade thành công. Nếu file đang ở `draft` → có thể `/spec-new` bị fail giữa chừng hoặc user đổi tay status. Chạy lại `/spec-new` cho integration này.

**Dừng hoàn toàn. Không tiếp tục.**

Nếu `status: approved` → tiếp tục sang Bước 2.

---

### Bước 2: Load context

Load các file sau:

- `.specs/integrations/{slug}/spec.md` — đọc toàn bộ + frontmatter (`features`, `components`)
- `.specs/main/sad.md` — đọc Tech Stack và Architectural Guardrails
- `.specs/main/domain.md` — đọc Glossary và Shared Entities
- `.specs/main/component/{C-XXX}-{slug}/cdd.md` — cho mỗi component trong frontmatter `components` (nếu cdd.md tồn tại)
- `.specs/main/feature/{F-XXX}-{slug}/frd.md` — cho mỗi feature trong frontmatter `features` (đọc `Verification Rules` để sinh `Verification Implementation` trong fdd.md)
- `.specs/main/feature/{F-XXX}-{slug}/fdd.md` — cho mỗi feature trong frontmatter `features` (nếu fdd.md tồn tại)

Tóm tắt context và surface assumptions:

```
TỪ SPEC & SAD TÔI HIỂU:
- Integration: {title}
- Features liên quan: {từ frontmatter — F-XXX, ...}
- Components bị touched: {từ frontmatter — C-XXX, ...}
- Yêu cầu chính: {tóm tắt requirements từ spec.md}
- Tech stack: {từ sad.md}
- Shared entities liên quan: {từ domain.md}
- Component design hiện tại: {tóm tắt từ cdd.md(s) — bỏ qua nếu chưa tồn tại}
- Inter-component flow hiện tại: {tóm tắt từ fdd.md(s) — bỏ qua nếu chưa tồn tại}
- Guardrails cần tuân theo: {list GUARD-XXX từ sad.md}

ASSUMPTIONS TÔI ĐANG ĐẶT RA:
1. {assumption về approach}
2. {assumption về dependencies}
→ Sửa lại nếu sai trước khi tiếp tục.
```

---

### Bước 3: Interview

Hỏi tuần tự, từng phần — không hỏi tất cả cùng lúc:

**Phần 1 — Solution Overview:**
> Approach kỹ thuật nào sẽ dùng? Tại sao chọn approach này (so với alternatives)?
> Nếu chưa rõ, tôi có thể đề xuất dựa trên sad.md và requirements — muốn không?

Nếu user muốn đề xuất → đề xuất 2-3 options với trade-offs rõ ràng, để user chọn. Không quyết định thay.

**Phần 2 — Data Model Changes:**
> Integration này có thêm/sửa/xóa entity hoặc field nào không?
> Nếu có, thay đổi gì và ảnh hưởng thế nào đến business rules hiện tại?

Bỏ qua nếu không có data model changes.

**Phần 3 — Interface Changes:**
> Có API endpoints mới hoặc thay đổi không? Events, queue messages?
> Với mỗi endpoint: method, path, request/response shape, auth requirement.

**Phần 4 — Implementation Notes:**
> Có điểm kỹ thuật đặc biệt nào cần lưu ý không? (edge cases, ordering constraints, known gotchas...)

Bỏ qua nếu không có.

Nếu câu trả lời vague → hỏi lại. Ví dụ:
- "dùng JWT" → "JWT lưu ở đâu? expiry bao lâu? refresh token có không?"
- "tạo bảng mới" → "fields gì? quan hệ với entity nào trong domain?"

---

### Bước 4: Write — sinh draft

Tổng hợp và viết draft `tech.md`:

**Cấu trúc file**: dùng `.claude/templates/integrations/tech-template.md` làm skeleton, điền nội dung từ interview vào.

**Changes blocks** — agent sinh delta cho main artifacts trong section `## Changes` của tech.md. Mỗi block tương ứng 1 artifact bị touched, declare `Operation: create | update`, content theo format template gốc với markers `[NEW] / [MODIFY {field}] / [REMOVE]` cho operation=update. Đây là phần draft sẽ auto-apply sau khi user confirm — không có "manual apply" bước riêng. Targets:

### sad.md

Đề xuất cập nhật nếu integration này:
- Thêm cross-cutting concern mới (logging strategy, caching, ...)
- Thay đổi tech stack
- Thêm guardrail mới

### domain.md

Đề xuất cập nhật nếu integration này:
- Thay đổi shared entity (entity được dùng bởi 2+ component) — giữ nguyên `E-XXX` đã cấp
- Thêm shared entity mới phát sinh từ thiết kế kỹ thuật — heading `### E-XXX {Entity Name}`, cấp ID theo quy ước `domain-template.md`: `id_counters.entity + 1` trong `domain.md`, bump counter sau khi cấp; ID không tái sử dụng

### component/{C-XXX}-{component-name}/cdd.md

Liệt kê **tất cả** components bị touched trong frontmatter và đánh giá từng cái:

| Component | cdd.md | Đề xuất |
| --- | --- | --- |
| C-001 — auth | tồn tại | **Cập nhật** — thêm module RateLimiter, đổi storage strategy cho session |
| C-003 — payment | chưa có | **Tạo mới** — full cdd skeleton |

Với từng component có đề xuất:

**Tạo mới** `.specs/main/component/{C-XXX}-{component-slug}/cdd.md`
- Dùng khi component này được giới thiệu lần đầu trong integration (cascade từ spec.md đã đề xuất tạo crd, giờ tech.md đề xuất tạo cdd)
- Nội dung: Module Structure, Internal Data Flow, Storage & Persistence, Internal Interfaces, Technical Decisions

**Cập nhật** `.specs/main/component/{C-XXX}-{component-slug}/cdd.md`
- Khi cdd.md đã tồn tại và integration thay đổi internal design

### feature/{F-XXX}-{feature-name}/fdd.md

Liệt kê **tất cả** features liên quan trong frontmatter và đánh giá:

| Feature | fdd.md | Đề xuất |
| --- | --- | --- |
| F-001 — Checkout | tồn tại | **Cập nhật** — thêm sequence khi payment fail |
| F-002 — Refund | chưa có | **Tạo mới** |

**Tạo mới** `.specs/main/feature/{F-XXX}-{feature-slug}/fdd.md`
- Khi feature gắn với integration nhưng chưa có fdd.md
- Nội dung: Inter-component data flow, Orchestration, Cross-component invariants, **Verification Implementation** — từ tech.md (chỉ phần inter-component, không lặp internal design của component)
- **Verification Implementation**: với mỗi rule trong `frd.md > Verification Rules` của feature này, sinh row trong bảng `Rule ID | Rule (short) | Layer | Owning component | Error propagation`. Reference rule bằng `VR-F{NNN}-{seq}` ID (lấy nguyên từ FRD, không tạo ID mới). Rule (short) copy ngắn gọn từ FRD để row tự đọc được. Layer = client/gateway/service (có thể combine). Owning component reference C-XXX. KHÔNG đưa regex/validator code/error message wording vào — đó thuộc `cdd.md` của owning component (cascade riêng) hoặc UI copy artifact. Bỏ qua nếu FRD không có Verification Rules.

**Cập nhật** `.specs/main/feature/{F-XXX}-{feature-slug}/fdd.md`
- Khi fdd.md đã tồn tại, ghi rõ thay đổi flow nào
- Nếu integration thêm/đổi rule trong FRD → cập nhật bảng Verification Implementation tương ứng

Bỏ block fdd.md nếu integration không gắn với feature nào (`features: []`).

**Cascade Summary** — sau các Changes blocks, sinh bảng tóm tắt liệt kê tất cả targets (kể cả targets không có block, ghi `no-op`) để reviewer scan nhanh.

Hiển thị draft cho user xem — **chưa ghi file**.

---

### Bước 5: Review — xác nhận với user

> Draft trên đã đúng chưa?
> - Technical Design có đủ để DEV implement không?
> - Changes blocks đã đúng chưa? Mỗi marker có khớp current state của main artifact không?
> - Guardrails Compliance đã pass?

> **Sau khi confirm, agent sẽ auto-apply tất cả Changes blocks lên main artifacts (sad → domain → cdd → fdd).** Không có bước manual apply.

Chỉ ghi file sau khi user confirm. Nếu user yêu cầu chỉnh sửa → cập nhật draft → hỏi lại.

---

### Bước 6: Save + Auto-cascade

**[6.1] Ghi `.specs/integrations/{slug}/tech.md`** với status `approved` (không phải `draft` — human đã confirm ở Bước 5 chính là approval). Frontmatter `features` và `components` mirror từ `spec.md`. (tech.md là integration artifact — **không** mang `template_version`; versioning chỉ áp dụng cho main artifacts, xem `01-architecture.md` §12.)

**[6.2] Auto-apply mỗi Changes block** vào main artifact tương ứng. Thứ tự apply (để tránh forward reference): `sad.md` → `domain.md` → `component/*/cdd.md` → `feature/*/fdd.md`.

Cho từng block:

- **Operation=create:**
  - Tạo file mới tại path tương ứng
  - Nội dung = nội dung của Changes block (theo format của template gốc — `cdd-template.md` hoặc `fdd-template.md`)
  - Frontmatter: lấy từ template, gồm `template_version` (status `draft` cho artifact mới — separate lifecycle với tech.md). `template_version` chỉ stamp ở operation=create; **operation=update KHÔNG đụng** `template_version` của artifact hiện có.

- **Operation=update:**
  - Đọc artifact hiện tại
  - Với mỗi item trong Changes block:
    - `[NEW]` → append/insert vào section tương ứng (giữ thứ tự numeric của ID)
    - `[MODIFY {field}]` → tìm item bằng ID, update field đã chỉ định, giữ nguyên các field khác
    - `[REMOVE]` → xóa item khỏi artifact (ID không tái sử dụng — không renumber các ID khác)
  - Ghi lại artifact

**[6.2.5] Bump `id_counters`** cho mọi ID vừa cấp `[NEW]` (chủ yếu `domain.entity`, `crd.rule` nếu tech phát sinh) — phần atomic của auto-apply (fail → rollback luôn). KHÔNG ghi Change History (đã bỏ — history = git, xem `01-architecture.md` §7).

Cho mỗi main artifact có ID mới: set `id_counters.<family>` = seq lớn nhất vừa cấp (high-water-mark, chỉ tăng), ghi lại frontmatter cùng transaction. "Đổi gì · khi nào" của cascade = git commit + integration `tech.md` (PR record bất biến).

**[6.3] Atomic rollback:** Nếu apply block nào fail (vd `[MODIFY {ID}]` nhưng ID không tồn tại):
1. Rollback các block đã apply trước đó (kể cả `id_counters` đã bump) về state ban đầu
2. **Không** ghi tech.md
3. Báo lỗi cụ thể cho user fix draft hoặc artifact hiện tại

**[6.4] Thông báo kết quả:**

```
✓ .specs/integrations/{slug}/tech.md đã được tạo (status: approved)

Auto-cascade applied:
  ✓ sad.md — {summary | no-op}
  ✓ domain.md — {summary | no-op}
  ✓ component/C-XXX-{slug}/cdd.md — {created | updated: summary}
  ✓ feature/F-XXX-{slug}/fdd.md — {created | updated: summary}

Bước tiếp theo — tuỳ `.specs/integrations/{slug}/test.md`:

  (a) test.md chưa có, hoặc chưa `status: approved`:
  - /spec-test {slug} → QC reconcile test-design; /plan chặn tới khi có test.md

  (b) test.md đã `status: approved` (chọn một):
  - /implement → chạy trọn combo /plan + vòng lặp /build ↔ /review-integration tới khi review sạch (chạy dài, không hỏi giữa chừng)
  - /plan → chỉ tạo plan.md và todo.md, tự kiểm soát từng bước /build sau đó
  - Sau khi tất cả tasks done: đổi status F-XXX trong prd.md thành DONE
```

Chỉ in **một** nhánh — nhánh khớp trạng thái `test.md` lúc in. Phép kiểm giống dòng đầu gate Bước 1c của `/plan`, nên gợi ý `/plan` ở đây không bao giờ dẫn vào một lượt bị chặn vì thiếu `test.md`.

**Nếu apply fail** → dừng, báo lỗi cụ thể, **không** ghi tech.md. Yêu cầu user fix draft hoặc check artifact hiện tại.

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Tech design thì code xong mới biết được" | Không cần design hoàn hảo, cần đủ để thống nhất approach trước khi viết code. |
| "Interface thì ghi sau khi implement xong" | Interface chưa được agree = BA không biết integration làm gì, không thể verify AC. |
| "Cascade Proposals thì sau cập nhật cũng được" | Cascade là auto-apply atomic với save. Không có "sau" — confirm draft = cascade chạy ngay. |

## Red Flags

- Solution Overview không có lý do chọn approach — chỉ mô tả "sẽ làm X" mà không giải thích tại sao
- Interface Changes trống trong khi spec.md có AC về API/response shape
- Data Model Changes bỏ qua nhưng spec.md có requirement về data mới
- Changes blocks không được review trước khi confirm (cascade auto-apply là irreversible — không có undo)
- Marker không khớp current state: `[NEW]` cho item đã tồn tại, hoặc `[MODIFY]/[REMOVE]` cho ID không có

## Verification

Trước khi user confirm (Bước 5), kiểm tra:

- [ ] Solution Overview có lý do chọn approach (không chỉ mô tả)
- [ ] Mỗi Acceptance Criterion trong spec.md đều được cover bởi design
- [ ] Interface Changes đầy đủ method, path, auth requirement (nếu có)
- [ ] Mỗi Changes block có Operation rõ ràng (create | update)
- [ ] Mỗi item trong update block có marker đúng ([NEW]/[MODIFY {field}]/[REMOVE])
- [ ] Guardrails Compliance đã pass cho từng GUARD-XXX
- [ ] Cascade Summary table khớp với các Changes blocks

Sau khi user confirm (Bước 6):

- [ ] Auto-apply chạy theo thứ tự sad → domain → cdd → fdd
- [ ] ID `[NEW]` nào cấp thì `id_counters` tương ứng đã bump (high-water-mark, §7); KHÔNG ghi Change History
- [ ] Fail-safe: nếu apply fail thì không ghi tech.md (rollback luôn id_counters đã bump)
- [ ] Main artifact create (cdd/fdd mới) có `template_version` copy từ template; artifact update giữ nguyên version cũ. tech.md (integration) KHÔNG mang `template_version`
