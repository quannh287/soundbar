---
id: "{id}"
slug: "{slug}"
title: "{title}"
features: []
components: []
status: draft
created: {YYYY-MM-DD}
referenced_by:
  - 02-artifacts.md > 4. Integration Artifacts > 4.3 spec.md > Cấu trúc
  - skills/spec-new/SKILL.md > Process > Bước 5: Write — sinh draft
---

## Context

<!-- Tóm tắt thông tin quan trọng từ context đã load (prd.md, domain.md, frd.md, crd.md), để file self-contained.

     Integration sinh từ một spec gap hoặc spec drift (/spec-new {F-XXX} — Cửa 3) thì thêm một dòng
     provenance:
         **Nguồn:** spec gap SG-1 của F-002-todo-management
         **Nguồn:** spec drift SD-1 của F-008-todo-hoan-viec   ← BA chọn sửa requirement theo code
     Người mở file hỏi "vì sao có yêu cầu này" thì câu trả lời nằm ngay đây — và đây là thứ
     dẫn ngược về mục trong sổ spec-debt.md cạnh frd của feature đó. -->

## Problem Statement

<!-- Vấn đề cần giải quyết là gì, tại sao cần giải quyết -->

## Changes

<!--
spec.md = changeset patch áp lên main artifacts. Mỗi block dưới đây tương ứng 1 main artifact bị thay đổi.
Bỏ block nếu artifact không bị thay đổi. Lặp block cho mỗi feature/component bị touched.

**Operation:**
- `create` — artifact chưa tồn tại. Liệt kê đầy đủ tất cả sections theo template gốc, mọi item implicit [NEW] (không cần marker).
- `update` — artifact đã tồn tại. Chỉ liệt kê sections bị ảnh hưởng. Mỗi item có marker:
  - `[NEW]` — item chưa có trong artifact hiện tại
  - `[MODIFY {field}]` — item đã có, đang đổi field cụ thể (ví dụ `[MODIFY priority]`, `[MODIFY rule]`)
  - `[REMOVE]` — item đã có, sẽ bị xóa khỏi artifact

**Format reference:** dùng đúng format của template gốc — KHÔNG duplicate skeleton ở đây. Template gốc là single source of truth cho format.

**ID assignment:** agent đọc artifact hiện tại để xác định next ID:
- `US-F{NNN}-{seq}`, `AC-F{NNN}-{seq}`, `VR-F{NNN}-{seq}` cho frd.md
- `AC-C{NNN}-{seq}` cho crd.md
- ID stable — không tái sử dụng khi xóa, không renumber.

**Auto-cascade:** sau khi human approve spec.md, agent tự apply tất cả Changes blocks vào main artifacts. spec.md được archive như PR record.
-->

### feature/{F-XXX}-{feature-slug}/frd.md *(lặp block cho mỗi feature; bỏ nếu không touch feature)*

**Operation:** create | update
**Format reference:** [frd-template.md](../../templates/main/feature/frd-template.md)

<!--
operation=create → nội dung đầy đủ theo frd-template.md (Overview, User Flows, Feature-level AC, User Stories, Verification Rules, Scope, Dependencies).
operation=update → chỉ liệt kê section bị ảnh hưởng, mỗi item có marker.

Ví dụ operation=update:

#### User Stories

##### US-F001-005 [NEW]: {Story title}
**{Persona}** muốn **{action}** để **{goal}**.
**Priority:** Must
**Acceptance Criteria:**
- `AC-F001-012` [NEW]
  - **Given** ...
  - **When** ...
  - **Then** ...

##### US-F001-002 [MODIFY priority]
- Priority: Should → Must

##### US-F001-004 [REMOVE]
- Lý do: superseded by US-F001-005

#### Verification Rules

| ID | Field | Type | Required | Rule | Refs | Op |
| --- | --- | --- | --- | --- | --- | --- |
| `VR-F001-008` | email | email | yes | must be unique | US-F001-005 | NEW |
| `VR-F001-003` | password | string | yes | min length 12 (was 8) | US-F001-001 | MODIFY rule |
-->

### component/{C-XXX}-{component-slug}/crd.md *(lặp block cho mỗi component; bỏ nếu không touch component)*

**Operation:** create | update
**Format reference:** [crd-template.md](../../templates/main/component/crd-template.md)

<!--
operation=create → nội dung đầy đủ theo crd-template.md (Role, Responsibilities, Owned Entities, Public Interface, Business Rules, Dependencies).
operation=update → chỉ liệt kê section bị ảnh hưởng, mỗi item có marker (xem ví dụ ở block frd.md).

Component-level AC dùng ID `AC-C{NNN}-{seq}`, gắn vào responsibility/interface/rule liên quan.
-->

### prd.md *(bỏ nếu không có thay đổi)*

**Operation:** update
**Format reference:** [prd-template.md](../../templates/main/prd-template.md)

<!--
Thường là update — thêm row vào Feature Index / Component Index, đổi status feature, thêm NFR, thêm business constraint, thêm glossary reference.
Mỗi delta dùng marker, ví dụ:

#### Features (Feature Index)
- Row [NEW]: `F-007 — Refund | Cho phép user refund order | Medium | TODO`
- Row [MODIFY status]: `F-001` TODO → In Progress

#### Components (Component Index)
- Row [NEW]: `C-005 — refund-processor | Xử lý refund workflow | TODO`
-->

### domain.md *(bỏ nếu không có thay đổi)*

**Operation:** update
**Format reference:** [domain-template.md](../../templates/main/domain-template.md)

<!--
Thường là update — thêm glossary term, thêm shared entity, sửa entity definition.

#### Glossary
- Row [NEW]: `Refund — số tiền hoàn lại cho user sau khi order bị hủy`

#### Shared Entities
- Entity [NEW]: `E-XXX Refund (Owner: C-005-refund-processor)` — { fields, relationships } — E-XXX = next available trong domain.md (tuần tự theo thứ tự seed, không tái sử dụng — xem domain-template.md)
-->

### sad.md *(bỏ nếu không có thay đổi)*

**Operation:** update
**Format reference:** [sad-template.md](../../templates/main/sad-template.md)

<!--
Thường là update — thêm tech stack item, thêm cross-cutting concern, thêm guardrail. Hiếm khi thay đổi per integration.
-->

## Conflicts *(nếu có)*

<!-- Mỗi chỗ requirement mới đụng requirement đang có mà /spec-new Bước 5b tìm ra, và BA đã chọn gì.
     Bước 5b không in dòng nào ⇒ XOÁ section này.

     Loại (định nghĩa: skills/spec-new/SKILL.md Bước 5b): trái nhau · cái cũ hết đúng · ngoài phạm vi
     Chọn: giữ mới (câu cũ có marker ở ## Changes) · giữ cũ (câu mới đã sửa, hoặc vẫn vào khi loại là
     "cái cũ hết đúng") · chưa quyết (có dòng ở ## Open Questions; loại trái nhau / ngoài phạm vi thì câu mới
     KHÔNG ở ## Changes, loại cái cũ hết đúng thì câu mới vẫn ở ## Changes và câu cũ giữ nguyên)
     Ghi cả dòng "giữ cũ": nó không để lại dấu vết nào khác trong spec.
     Một luật viết ở nhiều chỗ (VR + Scope + Flow + mô tả ở prd) ⇒ một row, cột Cũ liệt kê mọi chỗ,
     cột Đi đâu liệt kê mọi marker. -->

| # | Cũ | Mới | Loại | Chọn | Đi đâu |
| --- | --- | --- | --- | --- | --- |
| 1 | `AC-F009-003` (F-009) | `AC-F002-0xx` | cái cũ hết đúng | giữ mới | `[MODIFY then]` `AC-F009-003` ở block `F-009` |
| 2 | `AC-F005-001` (F-005) | `AC-F002-0xx` | cái cũ hết đúng | chưa quyết | Open Questions #1 — câu cũ giữ nguyên, câu mới vẫn vào |
| 3 | Scope (F-008): "Từ chối hoãn việc … chưa có hạn" | `AC-F002-0xx` | cái cũ hết đúng | giữ cũ | — câu cũ giữ nguyên, câu mới vẫn vào |

## Out of Scope

<!-- Những gì KHÔNG thuộc phạm vi của integration này -->

## Open Questions

<!-- Các điểm còn mơ hồ cần clarify trước khi proceed. Xóa section nếu không có. -->

## Cascade Summary

<!-- Bảng tóm tắt để reviewer scan nhanh trước khi approve. Auto-generated từ các Changes blocks ở trên. -->

| Artifact | Operation | Summary |
| --- | --- | --- |
| `feature/F-XXX-{slug}/frd.md` | create / update | {ngắn: +N US, +M VR, modify AC-X} |
| `component/C-XXX-{slug}/crd.md` | create / update | {ngắn} |
| `prd.md` | update | {ngắn} |
| `domain.md` | update | {ngắn} |
| `sad.md` | update / no-op | {ngắn} |
