---
id: crd-{component}
type: crd
status: draft
owner: "{BA / Tech Lead}"
component_id: "{Component ID từ PRD Component Index, ví dụ C-001}"
template_version: 2
migrations:
  - to: 1
    note: "baseline"
  - to: 2
    remove: [Change History]
    note: "Bỏ section Change History — history = git. Thêm frontmatter id_counters (rule) làm high-water-mark cấp business-rule ID (C-XXX-Rnn). Migrate: seed id_counters.rule = max(Rnn trong doc, Rnn trong Change History cũ) TRƯỚC khi xoá section."
id_counters:
  rule: 0
referenced_by:
  - 02-artifacts.md > 3. Main Artifacts > 3.2 Component level > crd.md > Cấu trúc
  - skills/spec-new/SKILL.md > Process > Bước 5: Write — sinh draft > component/{C-XXX}/crd.md
  - templates/integrations/spec-template.md > Changes > component/{C-XXX}/crd.md
---

<!--
Canonical format cho component/{C-XXX}-{slug}/crd.md.
spec.md và tech.md REFERENCE template này khi sinh Changes block — KHÔNG duplicate skeleton.
Mọi thay đổi structure ở file này tự động propagate qua Changes blocks vì chúng dùng đây làm format gốc.
-->

# Component: {Component Name}

## Role

{1-2 câu mô tả vai trò của component trong hệ thống. Component này là "nơi chịu trách nhiệm" cho cái gì?}

## Responsibilities

Trách nhiệm cụ thể của component — phải làm gì, **không** làm gì.

### Does

- {responsibility 1}
- {responsibility 2}

### Does NOT

- {responsibility thuộc component khác — ghi rõ component nào sở hữu}
- {responsibility nằm ngoài scope}

## Owned Entities

Entities mà component này sở hữu canonical definition. Nếu entity được dùng bởi 2+ component, định nghĩa chính sẽ ở `domain.md` (Shared Entities) thay vì ở đây — chỉ ghi reference.

### {Entity Name}

{Mô tả entity này đại diện cho cái gì.}

**Attributes:**

| Attribute | Type | Required | Validation |
| --- | --- | --- | --- |
| {tên} | {business type} | Yes/No | {rule} |

**State Machine:** *(bỏ nếu entity không có lifecycle)*

| From | To | Trigger | Guard |
| --- | --- | --- | --- |
| {state} | {state} | {sự kiện} | {điều kiện} |

## Public Interface

Các interface mà component expose ra ngoài — signature level, không bao gồm implementation.

### API Endpoints *(bỏ nếu component không expose HTTP API)*

| Method | Path | Purpose | Auth |
| --- | --- | --- | --- |
| {GET/POST/...} | {/path} | {mục đích} | required/public |

### Events Published *(bỏ nếu không emit event)*

| Event | Trigger | Payload chính |
| --- | --- | --- |
| {EventName} | {khi nào emit} | {fields chính} |

### Events Consumed *(bỏ nếu không consume event)*

| Event | Source Component | Action |
| --- | --- | --- |
| {EventName} | {C-XXX} | {component này làm gì khi nhận event} |

## Business Rules

Các quy tắc nghiệp vụ thuộc về component này. Rule cross-component thuộc về `fdd.md` của feature liên quan.

**Cấp ID (`C-XXX-Rnn`):** seq kế = `id_counters.rule + 1` (frontmatter), cấp xong tăng `id_counters.rule`. ID **stable** — không tái sử dụng seq khi remove, không renumber (high-water-mark, không giảm khi remove).

| ID | Rule | Condition | Exception |
| --- | --- | --- | --- |
| {C-XXX-R01} | {mô tả rule} | {khi nào apply} | {ngoại lệ nếu có} |

## Dependencies

Các component khác mà component này phụ thuộc.

| Component | Loại dependency | Cách dùng |
| --- | --- | --- |
| `{C-XXX}-{name}` | sync call / event subscription / shared entity | {cụ thể: gọi API nào, subscribe event nào} |

