---
name: plan
description: Tạo plan.md và todo.md cho một integration — phân rã tasks từ spec.md và tech.md. SDD wrapper quanh planning-and-task-breakdown — chỉ làm context loading, delegate toàn bộ breakdown cho planning-and-task-breakdown.
---

# plan

## Overview

SDD wrapper quanh `planning-and-task-breakdown`. Nhiệm vụ duy nhất của skill này là:
1. Load và surface đúng context từ SDD artifacts
2. Handoff sang `planning-and-task-breakdown` để thực hiện breakdown

Mọi quyết định về sizing, slicing đều thuộc về `planning-and-task-breakdown`. Output format được định nghĩa trong SKILL này.

## When to Use

- Có `spec.md` và/hoặc `tech.md` cho integration cần plan

## When NOT to Use

- Hotfix nhỏ, single-file → implement trực tiếp không cần plan

---

## Process

### Cờ trong ARGUMENT

ARGUMENT có thể chứa cờ ngoài slug:

| Cờ | Nghĩa |
|---|---|
| `--auto` | Bật **non-interactive profile** — không hỏi câu nào; mỗi điểm hỏi rẽ theo nhánh **`[--auto]`** ghi ngay tại chỗ đó |

Bỏ cờ ra khỏi ARGUMENT **trước** khi khớp slug ở Bước 1.

Cờ có phạm vi **đúng một lần gọi** — không ghi trạng thái ra file, nên lần gõ tay sau vẫn hỏi đầy đủ. `/implement` là caller duy nhất truyền `--auto`.

---

### Bước 1: Xác định integration

**Nếu có ARGUMENT:**
- Parse argument: có thể là số thứ tự (`2`, `002`) hoặc slug (`002-implement-todo`)
- Quét `.specs/integrations/*/`, tìm integration khớp với argument
- Nếu không tìm thấy → báo lỗi:
  > Không tìm thấy integration khớp với "{argument}". Kiểm tra lại tên hoặc số thứ tự.
- Nếu tìm thấy → dùng integration đó, bắt đầu luôn

**Nếu không có ARGUMENT:**

Quét `.specs/integrations/`. Liệt kê tất cả integrations:

```
Integrations:

  [1] 001-implement-auth    — Implement Auth             spec✓ tech✓ plan✓
  [2] 002-implement-todo    — Implement Todo Management  spec✓ tech✓ plan—

Chọn số integration:
```

Legend: `✓` = có, `—` = chưa có

Nếu plan.md / todo.md đã tồn tại → hỏi trước khi ghi đè.

**`[--auto]`** Không hỏi, **không ghi đè** — resume. Giữ nguyên `plan.md`/`todo.md` đang có, bỏ qua Bước 2–3, báo:

```
plan.md đã tồn tại cho {slug} — resume, không ghi đè.
```

rồi kết thúc. Đây là thứ cho phép `/implement` chạy lại trên integration dở dang mà không mất tiến độ.

---

### Bước 1b: Gate check — spec.md và tech.md phải approved

Đọc frontmatter của `.specs/integrations/{slug}/spec.md` và `.specs/integrations/{slug}/tech.md`.

Nếu `tech.md` chưa tồn tại → coi như `status: missing`.

Kiểm tra từng file — nếu **bất kỳ file nào** chưa `approved`:

> ⛔ Không thể tạo plan.md — các artifact sau chưa được approve:
>
> - `spec.md` — status: `{status}` ← chỉ liệt kê nếu chưa approved
> - `tech.md` — status: `{status}` ← chỉ liệt kê nếu chưa approved hoặc chưa tồn tại
>
> Để tiếp tục:
> 1. Review từng file chưa approved (chạy `/spec-tech` trước nếu `tech.md` chưa có)
> 2. Apply Cascade Proposals (nếu có)
> 3. Đổi `status` thành `approved` trong frontmatter
>
> Sau khi approve xong, chạy lại `/plan`.

**Dừng hoàn toàn. Không tiếp tục.**

**`[--auto]`** Vẫn **dừng thật**. `spec.md`/`tech.md` có cascade lên `.specs/main/` nên human gate ở đây là precondition của cả `/implement`, không phải câu hỏi có sẵn đáp án.

Nếu cả hai đều `approved` → tiếp tục sang **Bước 1c**.

---

### Bước 1c: Gate test-side — `test.md` approved + `test-design` phủ delta (034 `D8` · `DS6`)

`/plan` chia việc theo **Story slice**, mà không có TC neo `AC-F*` thì không chia được. Sáu phép kiểm, chạy trước khi load context:

| Kiểm | Không đạt thì |
|---|---|
| `.specs/integrations/{slug}/test.md` tồn tại và `status: approved` | ⛔ dừng — *"chạy `/spec-test {slug}` trước"* |
| `.specs/tests/{F-XXX}-{slug}/test-exec-functional.md` tồn tại cho **mỗi** feature trong `features:` | ⛔ dừng — *"chạy `/spec-test-exec {F-XXX}` trước"* (`D9`) |
| Mọi `AC-F*` op `NEW`/`MODIFY` trong `spec.md § Changes` có **≥1 TC** ở `test-design.md` | ⛔ dừng, **liệt** AC không có TC nào |
| AC có TC nhưng **mọi** TC của nó vắng mặt ở `test-exec-functional.md` §3.1 | **KHÔNG dừng** — oracle thị giác (`Autoable = NO`). Ghi AC đó vào `## Definition of Done` kèm `👤 QC kiểm bằng mắt`, **không gán slice nào** |
| Mỗi AC **lái được** có mặt trong bản đồ `stories` của `check-vr-refs --json` | ⛔ dừng, liệt AC mồ côi — không gán được slice |
| Mỗi VR của tập nguồn có **≥1** US nguồn trong `vr[].us` | ⛔ dừng, liệt VR không gán được |

Hai dòng cuối đọc thẳng `npx spec-lite check-vr-refs {frd} --json` (`D12`) — `/plan` **không** parse `frd.md`. Chúng **không** kiểm `Refs` rỗng: [`.docs/035`](../../.docs/035-vr-neo-us.md) đã chặn ca đó ở `/spec-new` và `/spec-frd`, ② Plan không kiểm lại.

**`[--auto]`** Vẫn **dừng thật** ở mọi nhánh ⛔, như gate spec/tech. Thiếu TC là thiếu nguồn để chia việc, không phải câu hỏi có sẵn đáp án.

> **Gate này từng tồn tại** ở `/plan` Bước 1c rồi bị gỡ ở [`.docs/026`](../../.docs/026-selector-contract-supply-side.md) `D2`. Nay quay lại **cho TC nói chung**, không cho `selector-contract` — 026 `D2` gỡ nó vì nó đòi cả contract, và contract ở ② Plan đúng là phỏng đoán.

---

### Bước 2: Load và surface context

Load:

- `.specs/integrations/{slug}/spec.md` — Requirements, **Acceptance Criteria** và **Verification Rules** (ghi chú số + IDs của cả hai)
- `.specs/integrations/{slug}/tech.md` — Technical Design, Interface Changes, Data Model Changes, Implementation Notes
- `.specs/main/domain.md` — Entities và Business Rules liên quan

Cộng thêm, cho việc chia slice (034 `D2` — lật `D1` của [`.docs/026`](../../.docs/026-selector-contract-supply-side.md) **đúng phần đọc file**):

- `.specs/tests/{F-XXX}-{slug}/test-exec-functional.md` §3.1 — để biết **AC nào lái được bằng test**. TC `Autoable = NO` không render xuống file này, nên AC chỉ có oracle thị giác **tự động vắng mặt**; `/plan` không phải áp lại luật `Autoable` lần hai.
- `.specs/tests/{F-XXX}-{slug}/test-design.md` — danh sách `TC-F*` theo AC, để điền dòng `**Outer:**` của từng slice.

> **Phần cấm của 026 `D1` GIỮ NGUYÊN:** `/plan` vẫn **không** đọc `selector-contract.md`, **không** nêu giá trị `data-testid` nào, **không** lập task riêng cho contract. Ở ② Plan chưa có DOM — mọi phát biểu về *element* vẫn là phỏng đoán. Đọc **TC** để biết AC nào thuộc story nào thì không dính tới DOM; đó là ranh giới mà 034 `D2` lật, và chỉ lật đúng chỗ đó.

Surface tóm tắt để planning-and-task-breakdown có đủ context:

```
CONTEXT CHO PLANNING:
- Integration: {title}
- Features: {từ spec.md frontmatter}
- Components: {từ spec.md frontmatter}
- Yêu cầu chính: {tóm tắt từ spec.md — 2-4 bullet}
- Acceptance Criteria: {tổng số AC — list IDs theo nhóm Feature/Component như spec.md}
- Verification Rules: {tổng số VR — list IDs; "(không có)" nếu rỗng}
- Thay đổi kỹ thuật: {modules, data model, interfaces từ tech.md}
- Shared entities liên quan: {từ domain.md}

ASSUMPTIONS:
1. {assumption về ordering nếu có}
→ Sửa lại nếu sai trước khi tiếp tục.
```

**Nguồn tập VR — hai bước, đúng thứ tự (029 D4):**

1. Bảng **VR trong `## Changes` của `spec.md`**, lấy row có Op `NEW` hoặc `MODIFY`. Đây là ca integration có delta trên frd.
2. Chỉ khi (1) rỗng: VR của `frd.md` theo `features:` trong frontmatter, **lọc còn những VR neo vào tập nguồn** — `Refs` trỏ một `US-*` trong tập nguồn, **hoặc** một `AC-*` thuộc một US trong tập đó (035 D1). Không lọc thì mọi VR của feature đổ vào một integration chỉ chạm hai AC.

   **Đọc field, đừng suy lại quan hệ.** `npx spec-lite check-vr-refs .specs/main/feature/{F-XXX}-{slug}/frd.md --json` trả mỗi VR kèm `us` — tập US mà VR đó thuộc về, **AC đã được quy sẵn về US sở hữu nó**. Giao `us` với tập US nguồn là xong. Phép quy AC → US là cơ học (vùng của một US chạy từ heading của nó tới heading kế cùng cấp-hoặc-cao-hơn); suy lại bằng mắt thì mỗi lượt ra một kiểu.

   **Vì sao không chỉ nhận `AC-*`:** luật trước 035 chỉ nhận `AC-*`, mà ở pilot **15 trên 24 VR chỉ trỏ `US-*`** — đọc đúng chữ thì 15 VR đó rớt khỏi `Definition of Done`, và rớt **im lặng** (cái thiếu không có mặt trong diff). VR neo vào US hay neo vào AC của chính US đó là **cùng một quan hệ**.

Rỗng cả hai ⇒ ghi `Verification Rules: (không có)`. **Không suy diễn VR từ `tech.md`** — `tech.md` là HOW, VR là câu đã approve ở tầng WHAT.

**Vì sao VR phải đi cùng AC.** VR là trụ riêng trong frd và có TC riêng bên QC (`test-exec-validation`), nhưng phía build **không có đường nào bắt buộc** đi qua nó: trước đây VR chỉ lọt vào plan khi `tech.md` tình cờ nhắc — plan `002` của pilot có, `003`/`004` không. Một luật validation không vào DoD thì không ai bắt build làm, và cái thiếu **không có mặt trong diff** nên review cũng không thấy.

**`[--auto]`** Không chờ user confirm. Thay vào đó **ghi assumptions vào `plan.md`** thành section `## Assumptions (auto)` (đặt ngay sau frontmatter), mỗi assumption một dòng `- `. Không có assumption nào ⇒ vẫn tạo section với dòng `- (không có)`. Section này là chỗ người đọc lại sau biết plan đã đoán những gì mà không ai xác nhận.

> **Plan mode từ đây** — chỉ đọc, không viết code.

---

### Bước 3: Handoff sang planning-and-task-breakdown

Invoke `planning-and-task-breakdown` với context đã load. Skill đó sẽ thực hiện: dependency graph, slicing, write tasks. Output phải theo **Output Format** định nghĩa bên dưới — không dùng format mặc định của `planning-and-task-breakdown`.

> **FE task KHÔNG mang ràng buộc testid** (`.docs/026` D1). Không nêu giá trị testid, không nêu TC nào phải chạm được, không có `Verification` item nào về `data-testid` hay contract — và **không lập task riêng** cho việc *"ghi row vào `selector-contract.md`"*.
>
> Lý do task riêng bị cấm: `024` D5 đòi contract nằm **cùng commit** với component. Plan `004` từng đẻ `T005 ghi contract` → `T006 code UI`, tức hai commit, tức phá đúng luật đó. Plan mà nghĩ về testid thì nó sẽ lập task cho testid.

---

## Output Format

### plan.md

Dùng `.claude/templates/integrations/plan-template.md` làm skeleton, điền nội dung từ breakdown vào từng section. Frontmatter copy từ template (plan.md là integration artifact — **không** mang `template_version`; versioning chỉ áp dụng cho main artifacts, xem `01-architecture.md` §12).

**Frontmatter `status`:**

- Mặc định (gõ tay): giữ `status: draft`, `approved_by` để **rỗng** — người review rồi tự đổi sang `approved`.
- **`[--auto]`**: stamp `status: approved` **và** `approved_by: implement`.

`/build` gate cứng trên `status: approved` nên auto-mode buộc phải stamp. Nhưng `approved_by: implement` là dấu để về sau nhìn frontmatter biết plan này **chưa từng qua mắt người** — field rỗng nghĩa là người duyệt. Không được stamp `approved` mà bỏ trống `approved_by` trong auto-mode.

**`## Definition of Done` liệt kê cả AC và VR (029 D4)** — mỗi ID một dòng, không gộp:

```markdown
- [ ] AC-F002-016 — {điều kiện ngắn}
- [ ] VR-F002-006 — {luật ngắn}
```

DoD là chỗ `/implement` Bước 3 trừ tập (`(AC ∪ VR)(nguồn) \ DoD`), nên ID phải xuất hiện **nguyên văn** ở đây. Diễn đạt bằng văn xuôi mà không có ID là phép trừ báo thiếu dù việc đã có trong plan.

**Lưu ý format:**
- Task ID dùng `·` (middle dot), không dùng `—`
- `**Các bước:**` là numbered list, đủ cụ thể để agent implement không cần đoán
- `**Verification:**` là checklist `- [ ]` — test case hoặc observable result cụ thể
- `**depends:**` luôn có, dùng `—` nếu không có dependency

### todo.md

Dùng `.claude/templates/integrations/todo-template.md` làm skeleton, điền nội dung từ breakdown vào từng section. Frontmatter copy từ template (todo.md là integration artifact — không mang `template_version`).

---

## Cascade Proposals

Không có Cascade Proposals — plan.md là terminal artifact.

Nếu trong quá trình breakdown phát hiện delta cần cập nhật `sad.md`, `domain.md`, hay artifacts khác → **không tự cập nhật**. Thông báo user và đề xuất tạo integration riêng để xử lý.

---

## Verification

- [ ] Context đã được surface và user confirm trước khi breakdown *(`--auto`: surface xong ghi `## Assumptions (auto)` vào plan.md, không chờ confirm)*
- [ ] plan.md có section **Dependency Graph**
- [ ] `## Definition of Done` có **mọi** AC ID **và** VR ID của tập nguồn, mỗi ID một dòng nguyên văn
- [ ] Mỗi task có đủ: Mục tiêu / depends / Các bước / Verification
- [ ] Không viết code trong suốt quá trình
- [ ] Không đọc `selector-contract.md`; không task nào, không `Verification` item nào nhắc `data-testid` hoặc contract (`.docs/026` D1 — phần còn hiệu lực)
- [ ] Gate Bước 1c chạy đủ 6 dòng; `test.md` chưa `approved` ⇒ dừng thật kể cả `--auto` (034 `D8`)
- [ ] Mỗi `### Slice N` neo **đúng một** `US-F*`; dòng `**Outer:**` liệt TC có thật trong `test-design.md`
- [ ] Dòng `**VR:**` khớp `vr[].us` của `check-vr-refs --json` — so bằng `jq`, không đọc mắt (034 `D12`)
- [ ] AC có TC `Autoable = NO` **không** thuộc slice nào, và có mặt ở `## Definition of Done` kèm `👤 QC kiểm bằng mắt`
- [ ] plan.md + todo.md (integration) KHÔNG mang `template_version` (versioning chỉ cho main artifacts)
- [ ] `--auto`: `status: approved` + `approved_by: implement`; không `--auto`: `status: draft` + `approved_by` rỗng
- [ ] `--auto` chạy trọn không phát sinh câu hỏi nào (trừ gate spec/tech chưa approved — dừng thật)
