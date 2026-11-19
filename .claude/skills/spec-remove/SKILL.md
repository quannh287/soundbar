---
name: spec-remove
description: Remove một feature toàn diện — tạo removal integration với Code Inventory, Reverse Dependency Audit, reverse-TDD test strategy, và Finalize Plan (move feature artifacts sang .specs/removed/ + đóng ADO tickets) như task cuối trong todo.md. Nhận F-XXX làm argument.
---

# spec-remove

## Overview

Tạo removal integration cho 1 feature đã tồn tại. Output là `spec.md` với đầy đủ:

- **Code Inventory** — code, route, DB, feature flag, config liên quan
- **Reverse Dependency Audit** — ai còn reference, an toàn xoá hay không
- **Test Strategy** — reverse-TDD (regression test "thing is gone")
- **Finalize Plan** — move feature artifacts sang `.specs/removed/` + đóng ADO tickets, được DEV chạy như task cuối trong `todo.md`
- **Changes blocks** — `[REMOVE]` markers cho mọi artifact bị touched

Skill **không** sinh `tech.md` / `plan.md` / `todo.md`. Sau khi `spec.md` được approve, chạy `/spec-tech` → `/plan` → `/build` như flow thường. `spec.md` đủ giàu để 3 skill đó hoạt động không cần modification.

## When to Use

- Một feature đã ship và cần decommission (deprecated, business pivot, replaced by feature khác)
- Cần xoá toàn bộ code + spec + ADO state một cách an toàn, có audit trail
- Có nhiều reverse-dep cần được liệt kê và quyết định rõ ràng trước khi xoá

## When NOT to Use

- Chỉ muốn xoá 1 US / 1 AC / 1 VR khỏi feature → dùng `/spec-new` với marker `[REMOVE]` cho item đó. Feature vẫn sống.
- Feature chưa từng được implement (chỉ có frd.md, chưa có code) → dùng `/spec-new` với block `[REMOVE]` cho frd.md, không cần workflow này.
- Muốn pause / disable tạm thời mà giữ code → đây không phải removal, dùng feature flag thay vì skill này.

---

## Prerequisites

- `.specs/main/feature/{F-XXX}-*/frd.md` tồn tại
- `.specs/main/prd.md` có row của feature trong Feature Index
- (Optional) `.claude/ado.yaml` cấu hình nếu muốn đóng ADO tickets ở finalize step

---

## Process

### Bước 1: Validate argument

Argument BẮT BUỘC là Feature ID dạng `F-XXX` (3 chữ số). Nếu argument thiếu hoặc sai format → dừng:

```
spec-remove cần Feature ID. Ví dụ: /spec-remove F-001
```

Tìm thư mục `.specs/main/feature/F-XXX-*/`:
- 0 matches → báo lỗi feature không tồn tại, dừng.
- ≥ 2 matches → báo lỗi data inconsistency (nhiều thư mục cùng prefix), dừng.
- 1 match → tiếp.

Đọc `frd.md` frontmatter:
- Nếu `status: removed` → hỏi:

```
F-XXX đã có status `removed`. Bạn muốn:
  [1] Re-finalize (move artifacts + close ADO lại, idempotent)
  [2] Tạo removal integration mới (có thể bạn chưa cleanup code lần trước)
  [3] Hủy
```

---

### Bước 2: Load context

Đọc các file sau:

**Bắt buộc:**
- `.specs/main/feature/{F-XXX}-*/frd.md` — full content
- `.specs/main/feature/{F-XXX}-*/fdd.md` — nếu tồn tại
- `.specs/main/prd.md` — Feature Index (capture ADO ticket ID cho F-XXX), Component Index, NFR
- `.specs/main/domain.md` — Glossary + Shared Entities (xác định entity nào owned bởi component thuộc F-XXX)

**Components used by F-XXX:**

Trích từ `frd.md` section `Components Used` + `fdd.md` section `Components Touched`. Với mỗi C-YYY:
- `.specs/main/component/{C-YYY}-*/crd.md`
- `.specs/main/component/{C-YYY}-*/cdd.md` — nếu tồn tại

**Reverse dependency scan:**

Với mỗi C-YYY mà F-XXX sử dụng, grep `.specs/main/feature/F-*/frd.md` (trừ F-XXX) tìm references tới C-YYY. Mọi feature khác có reference → load `frd.md` của feature đó để hiểu nó dùng C-YYY làm gì.

Output context summary cho user:

```
F-XXX — {feature title}
  Status: {Done/In Progress/...}
  ADO: #{ticket_id} ({current state}) {nếu prd.md có cột ADO}

  Components dùng bởi F-XXX:
    - C-YYY-{slug} — {role} ({exclusive | shared with F-AAA, F-BBB})
    - ...

  Reverse-dep features (dùng chung component với F-XXX):
    ⚠ F-AAA {title} — dùng C-YYY {interface_name}
    ⚠ F-BBB {title} — dùng C-ZZZ {interface_name}
    {hoặc} ✓ Không có reverse-dep — F-XXX hoàn toàn cô lập

  Glossary terms từ domain.md tham chiếu trong F-XXX:
    - {term} {(unique to F-XXX | shared)}
    - ...

  Shared entities owned bởi components của F-XXX:
    - {Entity} (Owner: C-YYY) — {used by F-XXX only | also F-AAA}
    - ...
```

---

### Bước 3: Interview ngắn

Hỏi 2 câu, tuần tự:

**3.1 — Lý do remove:**

```
Lý do remove F-XXX? (sẽ ghi vào git commit message của lần remove + ADO closure comment)
> ___
```

**3.2 — Removal strategy:**

Dùng `AskUserQuestion`:

```
Removal strategy:
  [1] Single-shot — xoá hết trong 1 deploy. Phù hợp khi feature off-traffic, internal-only, không có DB schema lớn.
  [2] Phased — disable trước (feature flag off + deprecation banner), soak period, sau đó xoá code. Phù hợp khi có DB / external API / traffic gradual.
  [3] Phased + drop schema riêng — như Phased nhưng tách thêm 1 integration cho DROP TABLE/COLUMN sau khi code đã xoá và observed.
```

Nếu chọn `[2]` hoặc `[3]` → hỏi soak period (1-2 tuần là baseline):

```
Soak period giữa các phase (ngày)?
> ___
```

Phased và Phased+drop schema → ghi nhận để Bước 6 (sinh draft) có Removal Phases section.

---

### Bước 4: Code Discovery

Mục tiêu: build **Code Inventory** — danh sách code cụ thể sẽ bị xoá.

**Nguồn discovery (kết hợp):**

1. **fdd.md / cdd.md** — nếu artifact có ghi file path / module path cụ thể trong section như "Implementation Notes" → dùng làm seed trực tiếp.
2. **Component slug** — search filesystem cho directory matching `{C-YYY}-{slug}` (kebab) hoặc camelCase variant.
3. **Public Interface signatures** — từ `crd.md` Public Interface, lấy function/class/endpoint name → grep codebase.
4. **Route paths** — từ `frd.md` User Flows / `fdd.md` sequence diagrams, extract API path patterns (`/api/...`) → grep route registrations.
5. **Owned Entities** — từ `domain.md` Shared Entities (owned bởi component của F-XXX), table name → grep migrations + queries.
6. **Feature flag names** — nếu được nhắc trong artifact → grep config files.
7. **Test files** — sau khi xác định module paths, grep `tests/` cho cùng prefix / cùng tên.

**Tools:** `Grep`, `Glob`, `Bash` (`rg`, `find`). Khi không chắc filesystem layout, hỏi user 1 câu: "Codebase root ở `src/` hay project có monorepo structure khác?"

**Output Code Inventory** dạng table, group theo category:

```
Code Inventory for F-XXX:

  ROUTES / API ENDPOINTS:
    [1] POST /api/auth/login        → src/routes/auth.ts:12-50
    [2] POST /api/auth/logout       → src/routes/auth.ts:52-80
    [3] POST /api/auth/refresh      → src/routes/auth.ts:82-115

  SOURCE MODULES:
    [4] src/services/auth/          → entire directory (8 files)
    [5] src/middleware/auth-token.ts
    [6] src/utils/jwt.ts            → ⚠ also used by F-007 (reverse-dep)

  TESTS:
    [7] tests/auth/                 → 12 files
    [8] tests/integration/auth-flow.test.ts

  DATABASE:
    [9] table `sessions`            → migration drop_sessions.sql cần tạo
    [10] table `refresh_tokens`     → migration cần tạo
    [11] users.last_login_at column → ⚠ used by F-007 analytics

  FEATURE FLAGS:
    [12] ff_new_auth                → src/config/flags.ts:12

  CONFIG / ENV:
    [13] AUTH_SECRET, AUTH_TTL      → .env.example, src/config/index.ts

  OTHER (best-effort, manual verify):
    - Grafana dashboard "Auth metrics" — không scan được tự động, BA verify tay
    - Docs site có section /docs/auth/ — verify tay
```

Mỗi item có thể là `safe` (xanh) hoặc `⚠ has external ref` (cần quyết định ở Bước 5).

---

### Bước 5: Reverse Dependency Audit

Với mỗi item trong Code Inventory, grep external references (ngoài thư mục chính của F-XXX). Mọi reference `⚠` cần user quyết định.

```
Reverse-dep audit:

  [6] src/utils/jwt.ts
      External refs found:
        - src/services/admin/sessions.ts:34 — imports `verifyJWT`
        - src/services/api-gateway/auth-check.ts:12 — imports `signJWT`

      Quyết định:
        [a] Keep file — không xoá src/utils/jwt.ts (chỉ xoá phần exclusive của F-XXX bên trong nếu có)
        [b] Migrate consumer first — abort removal, tạo integration migration F-007 + api-gateway sang alternative trước
        [c] Remove anyway — xoá luôn, downstream tự fix (rủi ro cao, cần justify)
      Chọn: ___

  [11] users.last_login_at column
      External refs found:
        - src/analytics/login-tracking.ts:88 — SELECT this column
      Quyết định: ___
```

Mọi item `⚠` đều phải có quyết định trước khi sang Bước 6. Nếu user chọn `[b]` cho bất kỳ item nào → dừng skill, instruct:

```
F-XXX chưa thể remove vì có reverse-dep chưa migrate:
  - {item} blocked by {consumer}

Tạo integration migration trước:
  /spec-new "Migrate {consumer} away from {item}"

Sau khi migration deploy xong, chạy lại /spec-remove F-XXX.
```

---

### Bước 6: Sinh draft spec.md

Xác định slug và NNN giống `/spec-new`:
- Slug: `remove-{f-xxx-slug}` (ví dụ `remove-f001-authentication`)
- NNN: max của thư mục hiện có trong `.specs/integrations/` + 1, format 3 chữ số.

Output path: `.specs/integrations/{NNN}-remove-{f-xxx-slug}/spec.md`

Cấu trúc spec.md:

```markdown
---
id: "{NNN}"
slug: "remove-{f-xxx-slug}"
title: "Remove {F-XXX} {feature title}"
features: [{F-XXX}]
components: [{C-YYY list những component bị touched}]
status: approved
removal: true
created: {YYYY-MM-DD}
---

## Context
{tóm tắt frd/fdd/components/reverse-deps đã load ở Bước 2}

## Problem Statement
{lý do remove từ Bước 3.1 — ghi từ góc nhìn business/product, không phải tech}

## Removal Strategy
{Single-shot | Phased | Phased + schema drop} — chi tiết theo lựa chọn:

### Phase 1: Disable (chỉ khi Phased)
- Tắt feature flag `ff_xxx`
- Deprecation banner trên UI (nếu user-facing)
- Telemetry warning log mỗi lần feature được hit
- Soak: {N} ngày, monitor traffic = 0

### Phase 2: Remove code
- Xoá code per Code Inventory dưới
- Regression tests (xem Test Strategy)

### Phase 3: Drop schema (chỉ khi Phased + schema drop)
- Tạo integration riêng sau {N} ngày Phase 2 deployed
- Migration DROP TABLE / DROP COLUMN

## Code Inventory
{copy table từ Bước 4, đã loại bỏ các item user quyết định `[a] Keep`}

## Reverse Dependency Audit
{liệt kê mỗi item ⚠ + quyết định user đã chọn, kèm lý do/justify}

## Test Strategy (Reverse-TDD)

Pattern cho mỗi target:

1. **Baseline check (trước khi xoá):** ghi nhận test hiện có hoặc viết quick smoke test xác nhận thing exists và functional. Mục đích: confirm mental model trước khi xoá.

2. **Delete trong 1 commit:**
   - Xoá source code
   - Xoá test files cũ tương ứng
   - Update import statements

3. **Regression assertion (sau khi xoá):** thêm test khẳng định thing is gone:
   - Route → assert GET/POST trả 404 (hoặc proper error code)
   - Exported function/class → assert import fails (compile-time check, không cần runtime test)
   - DB table/column → migration test confirm DROP applied, query trả error
   - Feature flag → assert flag key không tồn tại trong config

4. **Full suite run:** mọi test khác phải pass. Nếu có test fail → reverse-dep chưa detect đủ, rollback commit, audit lại.

Regression tests **được giữ lại** trong codebase như guardrail — future-self không vô tình re-add feature đã removed.

## Finalize Plan

Đây là **task cuối** trong todo.md (sẽ được /plan tự nhặt). DEV thực thi sau khi mọi removal task khác xong và đã deploy verify.

### Actions:

1. **Move feature artifacts:**
   ```bash
   mkdir -p .specs/removed
   mv .specs/main/feature/{F-XXX}-{slug}/ .specs/removed/{F-XXX}-{slug}/
   ```

2. **Update prd.md Feature Index:**
   - Row F-XXX: status → `Removed`
   - Add note column hoặc inline: `(see .specs/removed/{F-XXX}-{slug}/)`

3. **Close ADO tickets** (nếu prd.md có ADO ticket ID cho F-XXX):
   - Feature ticket → state `Removed`
   - Tất cả User Story tickets thuộc F-XXX → state `Removed`
   - Comment trên mỗi ticket: "Decommissioned per integration {NNN}-remove-{slug}. Reason: {lý do}"
   - Dùng `mcp__azure-devops__wit_update_work_item` (state) + `mcp__azure-devops__wit_add_work_item_comment` (comment)
   - Nếu ADO state name khác (vd "Closed") → xem `.claude/ado.yaml` hoặc fetch từ `wit_get_work_item_type`

4. **Commit** lần remove với message ghi rõ lý do decommission (git = bản ghi lịch sử remove — không còn section Change History). ID của F-XXX/entity đã remove **không cấp lại** nhờ `id_counters` high-water-mark (§7) — không cần bản ghi trong doc.

5. **Verify finalize:**
   - `ls .specs/main/feature/ | grep {F-XXX}` → không còn match
   - `ls .specs/removed/{F-XXX}-{slug}/` → tồn tại
   - prd.md grep `F-XXX` → status `Removed`
   - ADO ticket fetch → state khớp

## Changes
<!-- Changes blocks theo format chuẩn của spec-template.md, áp dụng cho mọi artifact bị touched. Xem markers [NEW]/[MODIFY {field}]/[REMOVE] theo 01-architecture.md §6. -->

### prd.md
**Operation:** update
**Format reference:** [prd-template.md](../../templates/main/prd-template.md)

#### Features (Feature Index)
- Row [MODIFY status]: `F-XXX` {current status} → `Removed`
- {nếu có note column} Row [MODIFY note]: `F-XXX` add note "see .specs/removed/"

#### Components (Component Index) — chỉ component exclusive với F-XXX
- Row [MODIFY status]: `C-YYY` {current status} → `Removed`
- ... (component shared thì KHÔNG đổi status)

### feature/{F-XXX}-{slug}/frd.md
**Operation:** update
**Format reference:** [frd-template.md](../../templates/main/feature/frd-template.md)

<!--
Đánh dấu mọi item bằng [REMOVE]. File sẽ bị move sang .specs/removed/ ở Finalize step
nhưng cascade content vẫn ghi vào file gốc trước (apply [REMOVE] rồi mới move; git commit là bản ghi).
-->

#### User Stories
- US-FXXX-001 [REMOVE] — feature decommissioned
- US-FXXX-002 [REMOVE] — feature decommissioned
- ... (mọi US)

#### Acceptance Criteria
- AC-FXXX-* [REMOVE] — feature decommissioned

#### Verification Rules
- VR-FXXX-* [REMOVE] — feature decommissioned

#### Frontmatter
- [MODIFY status]: `draft|approved|...` → `removed`

### feature/{F-XXX}-{slug}/fdd.md *(nếu tồn tại)*
**Operation:** update
**Format reference:** [fdd-template.md](../../templates/main/feature/fdd-template.md)

#### Flow Sequences
- [REMOVE] FS-FXXX-* — feature decommissioned

#### Data Models
- [REMOVE] {model} — feature decommissioned

#### Frontmatter
- [MODIFY status]: → `removed`

### component/{C-YYY}-{slug}/crd.md *(lặp cho mỗi component bị touched)*
**Operation:** update
**Format reference:** [crd-template.md](../../templates/main/component/crd-template.md)

<!--
Component exclusive với F-XXX:
- Toàn bộ sections [REMOVE]
- Frontmatter status → removed

Component shared (vẫn còn feature khác dùng):
- Chỉ [REMOVE] những Public Interface / Responsibility / Owned Entity
  chỉ phục vụ F-XXX (đã audit ở Bước 5)
- Giữ nguyên phần còn lại
- Frontmatter status KHÔNG đổi
-->

#### Public Interface
- {interface} [REMOVE] — only used by F-XXX, no other consumer

#### Owned Entities
- {Entity} [REMOVE] — exclusive to F-XXX

### domain.md
**Operation:** update
**Format reference:** [domain-template.md](../../templates/main/domain-template.md)

#### Glossary
- {term} [REMOVE] — unique to F-XXX, no other reference

#### Shared Entities
- E-XXX {Entity} [REMOVE] — orphan after F-XXX removal, no other component owns. ID `E-XXX` của entity đã remove **vẫn giữ chỗ** (`id_counters.entity` high-water-mark không giảm) — không bao giờ cấp lại cho entity mới (quy ước `domain-template.md`)

## Out of Scope
- {Migration của reverse-dep features tới alternative — separate integration nếu có}
- {Documentation site cleanup — manual task ngoài integration}
- {Grafana dashboard cleanup — manual task}

## Cascade Summary

| Artifact | Operation | Summary |
| --- | --- | --- |
| `prd.md` | update | F-XXX status → Removed; {N} components status → Removed |
| `feature/F-XXX-*/frd.md` | update | All items [REMOVE]; status → removed; folder move tại Finalize |
| `feature/F-XXX-*/fdd.md` | update | All items [REMOVE]; status → removed |
| `component/C-YYY-*/crd.md` | update | All [REMOVE] (exclusive) / {N} items [REMOVE] (shared) |
| `domain.md` | update | {N} glossary [REMOVE], {N} entity [REMOVE] |
```

---

### Bước 7: Review — xác nhận với user

Hiển thị toàn bộ draft. Hỏi:

```
Draft trên đã đúng chưa?
  - Code Inventory đầy đủ và chính xác?
  - Reverse-dep audit đã quyết định hết các ⚠?
  - Removal Strategy phù hợp (single-shot vs phased)?
  - Finalize Plan đủ steps?
  - Changes blocks dùng [REMOVE] đúng chỗ (exclusive vs shared)?

Sau khi confirm, agent sẽ auto-apply Changes blocks lên main artifacts.
File feature artifacts (frd/fdd) KHÔNG bị move ngay — chỉ apply [REMOVE] markers
(git commit là bản ghi). Move sang .specs/removed/ là task cuối trong todo.md,
do /build chạy sau khi mọi deletion task khác xong.
```

Chỉ tiến hành Bước 8 sau khi user confirm.

---

### Bước 8: Save + Auto-cascade

Giống `/spec-new` Bước 7, nhưng với removal-specific extensions.

**[8.1] Ghi spec.md** với status `approved`, `removal: true` trong frontmatter. Frontmatter `features` chứa F-XXX, `components` chứa list components touched.

**[8.2] Auto-apply Changes blocks** vào main artifacts. Thứ tự: `prd.md` → `domain.md` → `sad.md` → `component/*/crd.md` → `component/*/cdd.md` → `feature/F-XXX-*/frd.md` → `feature/F-XXX-*/fdd.md`.

Áp dụng marker [REMOVE] theo 01-architecture.md §7:
- Xoá item khỏi artifact, ID không tái sử dụng, không renumber.
- Khi toàn bộ items trong frd/fdd của F-XXX bị [REMOVE] → đổi frontmatter `status: removed`.

**[8.3] KHÔNG ghi Change History** (đã bỏ — history = git, `01-architecture.md` §7). Sau khi apply [REMOVE] lên mọi artifact bị touched, **commit** với message ghi rõ feature decommissioned + lý do — đây là bản ghi lịch sử. ID đã remove không cấp lại nhờ `id_counters` high-water-mark (không giảm).

**[8.4] Side-effects:**

- Trong prd.md: row F-XXX status đổi `Removed` ngay (không chờ finalize). Lý do: spec.md đã approved tức là quyết định removal đã được ký, status reflect quyết định ngay.
- ADO tickets KHÔNG transition ngay. Chỉ transition khi DEV chạy task Finalize ở `/build`. Lý do: tránh case rollback removal sau khi spec approve nhưng chưa deploy.
- File feature/F-XXX-*/ KHÔNG move ngay. Lý do giống ADO — chỉ move sau khi code thật đã xoá và verified.

**[8.5] Thông báo kết quả:**

```
✓ .specs/integrations/{NNN}-remove-{f-xxx-slug}/spec.md đã được tạo (status: approved, removal: true)

Auto-cascade applied:
  ✓ prd.md — F-XXX status → Removed; {N} components status → Removed
  ✓ domain.md — {N} glossary/entity [REMOVE]
  ✓ component/C-YYY-*/crd.md — {summary}
  ✓ feature/F-XXX-*/frd.md — all items [REMOVE], status → removed
  ✓ feature/F-XXX-*/fdd.md — all items [REMOVE], status → removed

⚠ File feature/F-XXX-*/ vẫn ở .specs/main/feature/. Sẽ được move sang .specs/removed/ ở task cuối todo.md.
⚠ ADO tickets giữ nguyên state. Sẽ được close ở task cuối todo.md (cần .claude/ado.yaml).

Bước tiếp theo:
  /spec-tech     → thiết kế delete order, migration SQL, regression test cases
  /plan          → break down deletion tasks + finalize task cuối
  /build         → execute deletion + finalize
```

**Nếu apply fail** (markers reference ID không tồn tại, reverse-dep audit chưa hoàn tất, file không ghi được) → dừng, báo lỗi cụ thể, **không** ghi spec.md. Yêu cầu user fix draft.

---

## Downstream Integration (informational)

Skill này chỉ sinh `spec.md`. Để biết các skill sau xử lý removal flavor như nào:

- **`/spec-tech`** đọc `spec.md`, thấy `removal: true` + Code Inventory + Test Strategy + Finalize Plan → sinh `tech.md` với:
  - Section "Delete Order" liệt kê file paths theo Code Inventory
  - Section "Migration SQL" nếu có DB target (DROP + rollback)
  - Section "Regression Tests" theo Test Strategy pattern
  - Section "Finalize Task" passthrough nguyên xi từ spec.md Finalize Plan

- **`/plan`** đọc cả spec.md + tech.md → sinh `plan.md` + `todo.md`. Task cuối todo.md = Finalize task với 5 sub-actions như Finalize Plan của spec.md.

- **`/build`** chạy tuần tự todo.md. Khi tới Finalize task:
  - Move folder bằng shell mv
  - Edit prd.md
  - Gọi ADO API để transition tickets (cần `.claude/ado.yaml` configured)
  - Commit với message ghi lý do decommission (git = bản ghi lịch sử)
  - Verify outputs

Nếu `/spec-tech` hoặc `/plan` hiện tại chưa nhặt được removal flavor → có thể cần update sau (separate work). Trong v1, spec.md đủ rõ ràng để 2 skill đó produce reasonable output kể cả không có removal-awareness explicit.

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Grep nhanh, không cần Code Inventory chi tiết" | Inventory sót item = code chết nằm trong repo vô thời hạn. Audit trail mất. |
| "Reverse-dep nhỏ thôi, xoá luôn rồi fix sau" | Một import dangling phá CI cả team. Audit trước rẻ hơn rollback. |
| "Feature flag off là xong, không cần xoá code" | Code dead vẫn phải maintain (security patch, dependency upgrade). Xoá hẳn mới sạch. |
| "Single-shot cho nhanh, soak period làm gì" | Có DB / external traffic mà single-shot = rollback đắt khi phát hiện consumer chưa migrate. |
| "Skip Finalize, để folder ở main feature là được" | Active dir bị noise. Sau 5 features removed, không phân biệt được active vs dead. |

## Red Flags

- Code Inventory empty hoặc chỉ có 1-2 file cho 1 feature đã ship → discovery chưa đủ rộng, xem lại sources
- Reverse-dep audit không có ⚠ nào cho component shared → grep chưa đủ kỹ
- Removal Strategy single-shot nhưng có DB schema lớn hoặc external traffic > 0 → cân nhắc Phased
- Test Strategy chỉ có "delete code" mà không có regression test → future re-add risk
- Finalize Plan thiếu ADO closure mà prd.md có ticket ID → audit trail không đầy đủ
- Changes block frd.md mark [REMOVE] nhưng không đổi `status: removed` trong frontmatter → inconsistent state

## Verification

Trước khi user confirm (Bước 7):

- [ ] Code Inventory liệt kê đủ 7 category (route / module / test / DB / flag / config / other)
- [ ] Mỗi item ⚠ trong Reverse-dep audit đã có quyết định rõ ràng (a/b/c)
- [ ] Nếu có item chọn `[b] Migrate first` → skill đã dừng, không tạo spec
- [ ] Removal Strategy match scale: single-shot cho nhỏ, phased cho lớn
- [ ] Test Strategy có 4 sub-step: baseline / delete / regression / full-suite
- [ ] Finalize Plan có 5 actions: move folder / prd update / ADO close / commit (git=history) / verify
- [ ] Changes blocks: exclusive component → all [REMOVE]; shared component → chỉ items của F-XXX [REMOVE]
- [ ] frd.md / fdd.md frontmatter có [MODIFY status] → removed

Sau khi user confirm (Bước 8):

- [ ] spec.md frontmatter `removal: true`
- [ ] Auto-cascade chạy đúng thứ tự prd → domain → sad → crd → cdd → frd → fdd
- [ ] Sau khi apply [REMOVE], commit ghi lý do decommission (KHÔNG Change History — git = history); ID đã remove không cấp lại (id_counters không giảm)
- [ ] prd.md row F-XXX status = Removed (đổi ngay sau approve)
- [ ] File feature/F-XXX-*/ VẪN ở .specs/main/feature/ (chưa move — chỉ move ở Finalize task)
- [ ] ADO tickets KHÔNG bị transition (chưa close — chỉ close ở Finalize task)
- [ ] Notification cuối ghi rõ 2 ⚠ về việc folder + ADO chưa được động vào
