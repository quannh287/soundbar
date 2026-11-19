---
id: cdd-{component}
type: cdd
status: draft
owner: "{Tech Lead / Senior Dev}"
component_id: "{Component ID, ví dụ C-001}"
template_version: 2
migrations:
  - to: 1
    note: "baseline"
  - to: 2
    remove: [Change History]
    note: "Bỏ section Change History — history = git. cdd không mint stable-ID tuần tự nên không cần id_counters."
referenced_by:
  - 02-artifacts.md > 3. Main Artifacts > 3.2 Component level > cdd.md > Cấu trúc
  - skills/spec-tech/SKILL.md > Process > Cascade Proposals > component cdd.md
---

# Component Design: {Component Name}

> File này mô tả **internal design** của component — cách nó được tổ chức bên trong.
>
> Vai trò, public interface, business rules nằm trong `crd.md`. Cross-cutting concerns (auth, logging, ...) nằm trong `sad.md`.

## Module Structure

Các module/sub-component bên trong component và responsibility của từng module.

| Module | Responsibility |
| --- | --- |
| {module} | {mô tả} |

## Internal Data Flow

Luồng dữ liệu nội bộ component — từ input đến output, qua những module nào.

```mermaid
sequenceDiagram
    ...
```

## Storage & Persistence

Cách component lưu trữ data. Bỏ section nếu component stateless.

### Tables / Collections

| Name | Mục đích | Key columns / Indexes |
| --- | --- | --- |
| {table_name} | {mục đích} | PK: {cols}, Index: {cols} |

### Cache Strategy *(bỏ nếu dùng global strategy từ SAD)*

{Mô tả cache strategy nội bộ component nếu khác SAD.}

## Internal Interfaces

Contract giữa các module bên trong component. Public interface (ra ngoài) đã được mô tả trong `crd.md`.

| Caller | Callee | Purpose |
| --- | --- | --- |
| {module A} | {module B} | {gọi để làm gì} |

## Technical Decisions

Các quyết định kỹ thuật đặc thù của component và lý do.

| Quyết định | Lý do | Alternatives đã cân nhắc |
| --- | --- | --- |
| {decision} | {lý do cụ thể} | {option A vs B} |

