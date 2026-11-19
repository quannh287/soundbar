---
name: spec-brownfield-component
description: Discover components từ code, generate crd.md + cdd.md cho từng component, điền Component Index vào prd.md. Phải chạy /spec-brownfield-init trước.
---

# spec-brownfield-component

## Overview

Tạo `.specs/main/component/{C-XXX}-{component-name}/crd.md` và `cdd.md` cho các components trong brownfield project.

Skill này **tự discover** component boundaries từ code (không dựa vào init), sau đó scan sâu từng component để extract responsibilities, entities, public interface, business rules. Khi hoàn thành, **điền Component Index vào prd.md** và **đề xuất Shared Entities cascade vào domain.md**.

## When to Use

- Sau khi `/spec-brownfield-init` đã chạy và `prd.md` tồn tại
- Cần generate component artifacts cho brownfield project

## When NOT to Use

- `prd.md` chưa có → chạy `/spec-brownfield-init` trước
- Greenfield project → component artifacts mọc dần qua cascade từ integrations (`/spec-new`)

---

## Process

### Bước 1: Load context và xác định path

**Path:** Nếu có ARGUMENT là path → dùng làm root. Nếu không → CWD.

**Load:**
- `.specs/main/prd.md` — kiểm tra tồn tại; đọc problem statement và NFRs để hiểu business context
- `.specs/main/domain.md` — đọc Glossary để reuse business terms

Nếu `prd.md` không tồn tại → dừng:
> `prd.md` chưa có nội dung. Hãy chạy `/spec-brownfield-init` trước.

**Attachments:**
> Bạn có tài liệu bổ sung nào không? (API docs, architecture diagrams, design docs)
> Nhập `không` để bỏ qua.

---

### Bước 2: Discover component boundaries

Scan directory structure để tìm component candidates. Thử các patterns sau theo thứ tự:

1. `src/modules/*/` — modular structure (NestJS, v.v.)
2. `src/*/` — flat module structure (nếu có `service` hoặc `controller` bên trong)
3. `services/*/` — microservices
4. `packages/*/` — monorepo packages
5. `apps/*/` — monorepo apps

Với mỗi candidate directory, xác nhận đây là component bằng cách kiểm tra có ít nhất một trong: `*controller*`, `*service*`, `*repository*`, `*handler*`, `*module*` file bên trong.

Ghi lại cho mỗi component candidate:
- Directory path
- File count
- Patterns detected: controller / service / repository / event publisher / consumer

---

### Bước 3: Confirm component list

Trình bày kết quả discovery cho user confirm:

```
Tôi phát hiện {N} components từ codebase:
  [C-001] auth      → src/modules/auth/     (15 files: controller+service+repo)
  [C-002] user      → src/modules/user/     (12 files: controller+service+repo)
  [C-003] payment   → src/modules/payment/  (8 files: service+repo)
  [C-004] notification → src/modules/notification/ (6 files: service+event)

Điều chỉnh nếu cần:
  - Đổi tên: "C-002 → profile" hoặc nhập tên khác
  - Bỏ component: "bỏ C-004"
  - Thêm component: "thêm reporting tại src/reporting/"
  - Merge: "merge C-001 và C-002 thành auth-user"

Confirm danh sách? [y] hoặc nhập điều chỉnh:
```

Sau khi confirm, assign C-XXX IDs theo thứ tự tăng dần.

---

### Bước 4: Scan sâu từng component

Với mỗi component, đọc code files bên trong để extract:

**4a. Responsibilities:**
- Public method names trong service files
- Class-level comments / JSDoc nếu có
- Export declarations

**4b. Owned Entities:**
- Entity / model files trong component directory
- Decorators: `@Entity()` (TypeORM), Prisma model blocks, `@Schema()` (Mongoose), SQLAlchemy models
- Migration files gắn với component

**4c. Public Interface:**
- Controller files: HTTP method + path mỗi endpoint
- Event publisher: `@EventPattern`, `eventEmitter.emit()`, message queue producers
- Exported service methods nếu là shared library

**4d. Dependencies:**
- Import statements referencing other component directories
- Injectable services từ other modules
- HTTP client calls đến other services

**4e. Business Rules:**
- Validation decorators (`@Min`, `@Max`, `@IsEmail`, custom validators)
- Guard conditions trong service (`if (!user.isActive) throw ...`)
- Domain events và điều kiện trigger
- Comments có từ khóa: "must", "should", "only", "never", "không được"

**4f. Internal design (cho cdd.md):**
- Module structure: list sub-modules / file groups
- ORM/storage usage: repository pattern, raw queries, cache decorators
- Internal service/repository interface contracts

---

### Bước 5: Identify cross-component entities

Trong quá trình scan, ghi nhận các entities được **import hoặc reference từ nhiều hơn 1 component** → đây là candidate Shared Entities cho `domain.md`.

Ví dụ: `Order` được dùng trong `payment/` và `inventory/` → candidate Shared Entity, cần xác định owner.

---

### Bước 6: Hỏi clarification — batch

Sau khi scan xong tất cả components, hỏi một lần — tối đa **5 câu tổng cộng**. Ưu tiên những điểm ảnh hưởng đến component boundaries hoặc entity ownership.

```
Cần làm rõ {N} điểm:

[C-001 auth]
  Q1. Method `validateToken` được call từ cả auth/ và user/ —
      đây là public interface hay internal helper?
      [public / internal / skip]

[cross-component]
  Q2. Entity `Order` được dùng trong payment/ và inventory/ —
      component nào sở hữu?
      [payment / inventory / skip]

Trả lời hoặc "skip all" để đánh dấu NEEDS_CLARIFY hết:
```

---

### Bước 7: Generate artifacts

Với mỗi component, generate 2 files dùng templates tương ứng:

**`crd.md`** — WHAT (dùng `.claude/templates/main/component/crd-template.md`):
- Role, Responsibilities, Owned Entities, Public Interface, Business Rules, Domain Events, Dependencies

**`cdd.md`** — HOW (dùng `.claude/templates/main/component/cdd-template.md`):
- Module structure, Internal data flow, Storage & persistence, Internal interfaces, Technical decisions

**Nguyên tắc:**
- Mọi phần không detect được → NEEDS_CLARIFY, không bịa
- Business rules detect được từ code → đánh dấu `(detected from code)`
- crd.md không chứa internal design; cdd.md không chứa public interface

---

### Bước 8: Cascade Proposals — domain.md

Nếu có Shared Entities được phát hiện ở Bước 5:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHARED ENTITIES DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Các entities sau được dùng bởi nhiều components.
Đề xuất thêm vào .specs/main/domain.md (Shared Entities):

  Entity: Order (Owner: C-003-payment)
    Dùng bởi: C-003-payment, C-005-inventory
    Fields detected: id, userId, items[], status, totalAmount

  Entity: User (Owner: C-001-auth)
    Dùng bởi: C-001-auth, C-002-user, C-004-notification
    Fields detected: id, email, role, isActive

Apply cascade proposals vào domain.md? [y/n/edit]
```

Nếu `y` → update `.specs/main/domain.md` Shared Entities section — mỗi entity [NEW] dùng heading `### E-XXX {Entity Name}`, cấp ID tuần tự theo quy ước `domain-template.md` (`id_counters.entity + 1`, bump counter sau khi cấp; high-water-mark, ID không tái sử dụng). KHÔNG ghi Change History (đã bỏ — history = git, `01-architecture.md` §7).

Nếu `edit` → hỏi chỉnh sửa từng entity trước khi apply.

---

### Bước 9: Review và save artifacts

```
Sẽ tạo {N} components ({2N} files):
  ✓ .specs/main/component/C-001-auth/crd.md     (3 NEEDS_CLARIFY)
  ✓ .specs/main/component/C-001-auth/cdd.md     (1 NEEDS_CLARIFY)
  ✓ .specs/main/component/C-002-user/crd.md     (0 NEEDS_CLARIFY)
  ✓ .specs/main/component/C-002-user/cdd.md     (2 NEEDS_CLARIFY)
  ...

Ghi tất cả? [y] hoặc review từng file trước [r]:
```

- `y` → ghi tất cả
- `r` → hiển thị lần lượt từng file, user confirm / skip / edit từng cái

**Stamp `template_version`:** frontmatter mỗi `crd.md`/`cdd.md` lấy `template_version` từ template tương ứng (xem `01-architecture.md` §12).

**Bump `id_counters`:** mỗi `crd.md` có business rule → set `id_counters.rule` = seq Rnn lớn nhất vừa cấp (high-water-mark). `cdd.md` không mint ID tuần tự → không counter. KHÔNG ghi Change History (đã bỏ — history = git, `01-architecture.md` §7). Bản ghi scaffold = git commit.

---

### Bước 10: Điền Component Index vào prd.md + sad.md Components table

Sau khi artifacts đã được ghi, update song song hai bảng — `prd.md > Components` (vai trò business) và `sad.md > System Overview > Components` (góc nhìn architectural). Danh sách C-XXX phải khớp giữa hai bảng.

```
Sẽ điền:

prd.md Component Index (business view):
  C-001 | auth         | Xác thực và phân quyền người dùng       | active
  C-002 | user         | Quản lý thông tin người dùng             | active
  C-003 | payment      | Xử lý thanh toán và giao dịch            | active
  C-004 | notification | Gửi thông báo qua email/push             | active

sad.md Components table (architectural view):
  C-001 | auth         | Stateless service, JWT issuer, in-mem session cache
  C-002 | user         | Stateful service, owns user DB, exposes REST
  C-003 | payment      | Stateful service, integrates Stripe, idempotent writes
  C-004 | notification | Worker, consumes events from message bus

Apply? [y/n]
```

Cột architectural notes trong sad.md nên ngắn gọn — tập trung vào boundary/deployment/key tech concern, không lặp lại business role từ prd.md.

Khi apply → bump `id_counters.component` trong prd.md = seq C-XXX lớn nhất vừa điền (high-water-mark). sad.md Components table mirror prd (không mint ID riêng). KHÔNG ghi Change History (đã bỏ — history = git, `01-architecture.md` §7). Bản ghi = git commit.

---

### Bước 11: Summary

```
✓ Generated {N} components:
  .specs/main/component/C-001-auth/    (crd.md + cdd.md)
  .specs/main/component/C-002-user/    (crd.md + cdd.md)
  ...

✓ prd.md Component Index: {N} entries đã được điền
✓ sad.md Components table: {N} entries đã được điền (architectural view)

{nếu có} ✓ domain.md Shared Entities: {N} entities đã được cascade

NEEDS_CLARIFY summary — {total} items:
  C-001-auth:  {n} — [business rules, domain events, ...]
  C-002-user:  {n} — [entity ownership, ...]
  ...

Bước tiếp theo:
  /spec-brownfield-feature → discover features, generate frd.md + fdd.md, điền Feature Index
```

---

## Verification

- [ ] Mỗi component có đủ crd.md + cdd.md
- [ ] crd.md không chứa internal design (đã ở cdd.md)
- [ ] cdd.md không chứa public interface (đã ở crd.md)
- [ ] Mọi entity trong crd.md có đúng 1 owner component (hoặc NEEDS_CLARIFY)
- [ ] Dependencies chỉ reference C-XXX IDs, không reference file paths
- [ ] Business rules detect được đánh dấu `(detected from code)`
- [ ] prd.md Component Index đã được update
- [ ] sad.md Components table đã được update — danh sách C-XXX khớp với prd.md
- [ ] Shared Entities đã được cascade vào domain.md (nếu có)
- [ ] Mỗi crd.md/cdd.md có `template_version` copy từ template tương ứng
- [ ] NEEDS_CLARIFY items được list đầy đủ trong summary
