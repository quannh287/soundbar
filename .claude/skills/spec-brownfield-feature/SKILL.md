---
name: spec-brownfield-feature
description: Discover features từ code, generate frd.md + fdd.md cho từng feature, điền Feature Index vào prd.md. Phải chạy /spec-brownfield-component trước vì fdd.md tham chiếu C-XXX từ Component Index.
---

# spec-brownfield-feature

## Overview

Tạo `.specs/main/feature/{F-XXX}-{feature-name}/frd.md` và `fdd.md` cho các features trong brownfield project.

Skill này **tự discover** features từ routes, use cases, và test files, sau đó scan sâu để extract user stories, AC, và inter-component flows. Khi hoàn thành, **điền Feature Index vào prd.md**.

**Phải chạy sau `/spec-brownfield-component`** vì fdd.md mô tả inter-component interaction và cần tham chiếu C-XXX IDs từ Component Index đã được điền.

## When to Use

- Sau khi `/spec-brownfield-component` đã chạy xong
- prd.md có Component Index (C-XXX IDs đã có)
- Cần generate feature artifacts cho brownfield project

## When NOT to Use

- `/spec-brownfield-component` chưa chạy → chạy component skill trước
- Greenfield project → feature artifacts mọc dần qua cascade từ integrations (`/spec-new`)

---

## Process

### Bước 1: Load context và xác định path

**Path:** Nếu có ARGUMENT là path → dùng làm root. Nếu không → CWD.

**Load:**
- `.specs/main/prd.md` — kiểm tra Component Index đã được điền
- `.specs/main/domain.md` — đọc Glossary và Shared Entities
- `.specs/main/component/*/crd.md` — đọc Public Interface của từng component (để cross-reference trong fdd.md)

**Kiểm tra preconditions:**

Nếu `prd.md` không tồn tại → dừng:
> `prd.md` chưa có nội dung. Hãy chạy `/spec-brownfield-init` trước.

Nếu `prd.md` Component Index còn trống (không có C-XXX entries) → dừng:
> Component Index chưa có entries. Hãy chạy `/spec-brownfield-component` trước.
> fdd.md cần tham chiếu C-XXX để mô tả inter-component flows.

Nếu `.specs/main/component/` không có crd.md nào → cảnh báo tương tự và dừng.

**Attachments:**
> Bạn có tài liệu bổ sung nào không? (user stories, test plans, wireframes, existing specs)
> Nhập `không` để bỏ qua.

---

### Bước 2: Discover feature boundaries

Scan codebase để tìm feature candidates. Tìm theo thứ tự ưu tiên:

1. **Use case / interactor files**: `*UseCase.{ts,js}`, `*Interactor.{ts,js}`, `*Handler.{ts,js}`, thư mục `application/*/`
2. **Route groups**: controller files grouped by path prefix (`/auth/*`, `/payment/*`, `/orders/*`)
3. **Test describe blocks**: `describe('User Registration', ...)`, `describe('Checkout Flow', ...)`
4. **Page / screen directories**: `pages/{feature}/`, `screens/{feature}/`, `views/{feature}/`

Với mỗi candidate, ghi lại:
- Entry point file(s)
- Route paths liên quan
- Test files có hay không
- Components được call (từ import statements) → map sang C-XXX IDs

---

### Bước 3: Confirm feature list

```
Tôi phát hiện {N} features từ codebase:
  [F-001] user-registration  → RegisterUseCase + POST /auth/register   (5 tests)
  [F-002] authentication     → POST /auth/login, /auth/refresh          (3 tests)
  [F-003] checkout-flow      → CheckoutUseCase + /checkout/*            (8 tests)
  [F-004] order-history      → GET /orders/*                            (no tests)

Điều chỉnh nếu cần:
  - Đổi tên: "F-003 → place-order"
  - Bỏ feature: "bỏ F-004"
  - Thêm feature: "thêm password-reset"
  - Merge: "merge F-001 và F-002 thành auth-flow"

Confirm danh sách? [y] hoặc nhập điều chỉnh:
```

Sau khi confirm, assign F-XXX IDs theo thứ tự tăng dần.

---

### Bước 4: Scan sâu từng feature

**4a. User flows — infer từ:**
- Test file chains nhiều request liên tiếp → detect luồng thao tác có thứ tự
- Navigation / router config trong UI code (`steps`, `wizard`, `onNext`) → detect bước chuyển màn
- State machine hoặc status enum (`pending → processing → done`) → detect nhánh edge case
- Error handling branches trong use case → detect luồng thất bại

Đánh dấu source: `(inferred from tests)` hoặc `(inferred from UI navigation)`.
Nếu không detect được → User Flows section sẽ là NEEDS_CLARIFY.

**4b. User stories — infer từ:**
- Use case class names và public methods → action descriptions
- Route names + HTTP methods → "As a user, I want to POST /auth/register..."
- Test `describe` / `it` blocks → `it('should register a new user', ...)` → user story

Đánh dấu source: `(inferred from routes)` hoặc `(from tests)`.

**4b. Acceptance criteria — extract từ:**
- Test assertions: `expect(response.status).toBe(201)`, `expect(user.email).toBe(...)`
- Input validation rules từ DTO / request validators
- Expected error codes / messages từ error handling code

Nếu không có tests → AC section sẽ là NEEDS_CLARIFY.

**4c. Components consumed — extract từ:**
- Import statements trong feature's controllers / use cases → map sang C-XXX IDs (đã có từ Component Index)
- Cross-reference với crd.md Public Interface để confirm

**4d. Inter-component flow cho fdd.md — extract từ:**
- Call chain trong use case file: `authService → userRepo → notificationService`
- Event publications và subscriptions trong flow
- Transaction boundaries nếu explicit (`@Transaction`, `queryRunner`)
- Retry / timeout config nếu detect được

**4e. Verification Rules — reverse-engineer từ code:**

Áp dụng cho mọi input field user nhập trong feature (request body, query param, form field).

Scan và extract rule từ các nguồn sau, ưu tiên từ trên xuống:
- **Schema declarations**: Zod, Joi, Yup, Pydantic, class-validator decorators (`@IsEmail()`, `@MinLength(8)`...), Mongoose/TypeORM column constraints
- **Validator middleware / guard**: custom validation function trong middleware, NestJS pipes, FastAPI dependencies
- **Inline check trong handler/use case**: `if (!email.includes('@')) throw ...`
- **DB constraint**: migration files với `UNIQUE`, `NOT NULL`, `CHECK`, length limits
- **Test assertion**: `expect(() => validate(input)).toThrow(...)` → reverse-engineer rule từ test

Convert mỗi rule sang **human-readable diễn đạt** (không copy regex hoặc code nguyên):
- `@IsEmail()` → "email format hợp lệ"
- `@MinLength(8)` → "≥ 8 ký tự"
- `regex: /^[a-zA-Z0-9_]{3,20}$/` → "3-20 ký tự, alphanumeric + `_`"
- `UNIQUE` constraint → "unique"
- `@IsOptional()` → đánh `Required: no`

**Type**: derive semantic type (string/integer/email/date/...) từ field type, KHÔNG copy tech type (`varchar(255)`).

**Đánh dấu source** trong note hoặc inline comment: `(extracted from Zod schema)`, `(from DB constraint)`, `(from test assertion)`.

**Auto-assign Rule ID** `VR-F{NNN}-{seq}` cho mỗi rule extract được — tăng dần toàn feature, không reset theo field. Sub-rule phức tạp → tách flat thành nhiều rule riêng, mỗi cái 1 ID.

**Quan trọng — flag cho BA review:**
- Rule trong code có thể **thiếu** (validation chỉ chạy ở 1 layer, không cover hết) → list những field xuất hiện trong US nhưng không có validation → mark `NEEDS_CLARIFY`.
- Rule trong code có thể **lệch business intent** → toàn bộ Verification Rules section nên có header note: *"Rules dưới đây reverse-engineer từ code hiện tại. BA cần review và confirm có match business intent không."*
- Nếu field nào không có validation → fallback sang flow suggest options (xem `spec-new` SKILL.md → "Verification Rules — quy ước sinh") để BA quyết định khi review.
- **Cột `Refs` bắt buộc non-empty (035 D0).** Neo rule vừa extract vào story nói tới field đó — story nào mô tả input action chạm field này. **VR reverse-engineer từ code mà không story nào nhắc tới ⇒ `NEEDS_CLARIFY`, KHÔNG ghi row vào bảng.**

  Ca này **rất hay gặp ở brownfield** và là ca *bình thường*, không phải lỗi: rule đến từ DB constraint hoặc decorator mà spec chưa bao giờ nói. Nhưng bỏ row đi thì mất một ràng buộc đang chạy thật trong production, nên `NEEDS_CLARIFY` phải **giữ lại nội dung**: ghi vào `## Open Questions` của `frd.md` một dòng gồm *rule diễn đạt human-readable* + *chỗ tìm thấy trong code* + câu hỏi *"rule này phục vụ story nào, hay còn thiếu một story?"*. Row câm trong bảng VR còn tệ hơn: `/plan` và `/implement` lọc VR theo `Refs` nên nó bị lọc ra mất mà không dòng báo nào, trong khi vẫn trông như đã xử lý.

**Cấm:**
- ❌ Đưa regex / validator code nguyên xi vào bảng (đó là HOW, thuộc `fdd.md`).
- ❌ Đưa error message / user-facing copy vào bảng (UI copy, không thuộc FRD).
- ❌ Bỏ qua field có validation chỉ vì rule "có vẻ tầm thường" — vẫn phải ghi để BA confirm.

---

### Bước 5: Hỏi clarification — batch

Sau khi scan xong tất cả, hỏi một lần — tối đa **5 câu tổng cộng**:

```
Cần làm rõ {N} điểm:

[F-001 user-registration]
  Q1. Flow này chỉ register bằng email/password, hay còn OAuth nữa?
      (Tôi detect email/password flow nhưng thấy OAuth client được import)
      [email/password only / cả hai / skip]

[F-003 checkout-flow]
  Q2. Sau khi place order, payment được xử lý sync hay async?
      (Tôi thấy PaymentService được call nhưng không rõ transaction boundary)
      [sync / async / skip]

Trả lời hoặc "skip all":
```

---

### Bước 6: Generate artifacts

Với mỗi feature, generate 2 files dùng templates tương ứng. **KHÔNG** sinh `selector-contract.md` — contract cần cả `test-design.md` (cầu) lẫn DOM thật (cung), mà lúc này chưa có test-design; nó sẽ được backfill bởi `/spec-test-retrofit-functional` (`.docs/024`).

**`frd.md`** — WHAT (dùng `.claude/templates/main/feature/frd-template.md`):
- Description và business goal (infer từ feature name + use case, NEEDS_CLARIFY nếu không rõ)
- User flows: Mermaid flowchart cho happy case và edge cases (infer từ test chains / UI navigation, NEEDS_CLARIFY nếu không detect được)
- User stories (đánh dấu source)
- Acceptance criteria (extract từ tests nếu có, NEEDS_CLARIFY nếu không)
- **Verification Rules**: bảng `Field | Type | Required | Rule | Refs` từ Bước 4e. Thêm header note nhắc BA review match business intent. Field thiếu validation → NEEDS_CLARIFY. Cột `Refs` non-empty với **mọi** row; rule không neo được story nào thì sang `## Open Questions` kèm chỗ tìm thấy trong code, **không** ghi row (035 D0).
- Scope: In scope từ detected routes/actions; Out of scope → NEEDS_CLARIFY
- Dependencies:
  - Feature Dependencies: feature-to-feature dependencies nếu detect được
  - Components Used: list C-XXX từ Component Index (infer từ import statements)

**`fdd.md`** — HOW / inter-component (dùng `.claude/templates/main/feature/fdd-template.md`):
- Inter-component data flow: sequence diagram từ detected call chain (Mermaid hoặc ASCII)
- Orchestration: retry / timeout / fallback nếu detect được
- Cross-component invariants: transaction boundaries nếu detect được

**Nguyên tắc:**
- fdd.md là **file mỏng** — chỉ mô tả tương tác giữa components, không lặp nội dung từ crd.md / cdd.md
- Mọi phần không detect được → NEEDS_CLARIFY, không bịa

---

### Bước 7: Review và save artifacts

```
Sẽ tạo {N} features ({2N} files):
  ✓ .specs/main/feature/F-001-user-registration/frd.md  (4 NEEDS_CLARIFY)
  ✓ .specs/main/feature/F-001-user-registration/fdd.md  (2 NEEDS_CLARIFY)
  ✓ .specs/main/feature/F-002-authentication/frd.md     (1 NEEDS_CLARIFY)
  ✓ .specs/main/feature/F-002-authentication/fdd.md     (0 NEEDS_CLARIFY)
  ...

Ghi tất cả? [y] hoặc review từng file trước [r]:
```

**Stamp `template_version`:** `frd.md`/`fdd.md` (main, ở `.specs/main/feature/{F}/`) lấy `template_version` từ template (versioned — `01-architecture.md` §12). (Không sinh artifact test-side ở bước này.)

**Bump `id_counters`:** trong frontmatter mỗi `frd.md`, set counter cho ID đã derive từ code (`flow`, `fac`, `nfr`, `dm`, `us`, `ac`, `vr`) = seq lớn nhất vừa cấp (high-water-mark). `fdd.md` không mint ID tuần tự → không counter. KHÔNG ghi Change History (đã bỏ — history = git, `01-architecture.md` §7). Bản ghi scaffold = git commit.

---

### Bước 8: Điền Feature Index vào prd.md

Sau khi artifacts đã được ghi, update `.specs/main/prd.md` Feature Index:

```
Sẽ điền Feature Index vào prd.md:
  F-001 | user-registration | Đăng ký tài khoản mới qua email/password | Must | TODO
  F-002 | authentication    | Đăng nhập và refresh token               | Must | TODO
  F-003 | checkout-flow     | Đặt hàng và thanh toán                   | Must | TODO
  F-004 | order-history     | Xem lịch sử đơn hàng                     | Should | TODO

Apply? [y/n]
```

Khi apply → bump `id_counters.feature` trong prd.md = seq F-XXX lớn nhất vừa điền (high-water-mark). KHÔNG ghi Change History (đã bỏ — history = git, `01-architecture.md` §7). Bản ghi = git commit.

---

### Bước 9: Summary

```
✓ Generated {N} features:
  .specs/main/feature/F-001-user-registration/  (frd.md + fdd.md)
  .specs/main/feature/F-002-authentication/     (frd.md + fdd.md)
  ...

✓ prd.md Feature Index: {N} entries đã được điền

NEEDS_CLARIFY summary — {total} items:
  F-001: {n} — [business goal, out of scope, AC, ...]
  F-002: {n} — [...]
  ...

Brownfield init hoàn tất! Main artifacts:
  .specs/main/
  ├── prd.md           (Component Index: {N} | Feature Index: {N})
  ├── domain.md        (Glossary: {N} terms | Shared Entities: {N})
  ├── sad.md
  ├── component/       ({N} components, mỗi cái có crd.md + cdd.md)
  └── feature/         ({N} features, mỗi cái có frd.md + fdd.md)

Bước tiếp theo (tùy chọn):
  /spec-test-design [F-XXX]  → bootstrap test-design.md (Test Design Document) cho từng feature
                       — derive 1:1 từ frd.md, có test coverage tracking từ ngày 1.

Để bắt đầu implement, dùng /spec-new để tạo integration đầu tiên.
grep "NEEDS_CLARIFY" để tìm và fill in khi có thêm context.
```

---

## Verification

- [ ] Chạy sau `/spec-brownfield-component` — Component Index đã có entries
- [ ] Mỗi feature có đủ frd.md + fdd.md
- [ ] frd.md có ít nhất 1 user story hoặc NEEDS_CLARIFY rõ ràng
- [ ] fdd.md chỉ mô tả inter-component interaction — không lặp nội dung từ crd.md / cdd.md
- [ ] Components consumed list reference đúng C-XXX IDs từ Component Index
- [ ] User stories và AC detect được đánh dấu source `(inferred)` hoặc `(from tests)`
- [ ] Feature không có tests → AC section có NEEDS_CLARIFY rõ ràng
- [ ] Verification Rules: rule reverse-engineer từ code đã đánh dấu source; field thiếu validation đã NEEDS_CLARIFY; không chứa regex/code/error message
- [ ] Mọi VR có `Refs` non-empty — `npx spec-lite check-vr-refs <frd.md>` in **`✓ VR REFS KHỚP`**; rule không neo được story nào đã sang `## Open Questions` kèm chỗ tìm thấy trong code (035 D0)
- [ ] prd.md Feature Index đã được update
- [ ] KHÔNG sinh `selector-contract.md` (backfill sau bởi `/spec-test-retrofit-functional` — `.docs/024`)
- [ ] Mỗi frd.md/fdd.md có `template_version` copy từ template tương ứng
- [ ] NEEDS_CLARIFY items được list đầy đủ trong summary
