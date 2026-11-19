---
name: spec-sad
description: Điền hoặc cập nhật sad.md — System Architecture Document (kiến trúc, tech stack, cross-cutting concerns, guardrails). Dùng sau khi prd.md và domain.md đã có nội dung.
---

# spec-sad

## Overview

Tạo nội dung cho `.specs/main/sad.md` thông qua interview có cấu trúc. SAD là bản đồ kỹ thuật của hệ thống — nó định nghĩa các quyết định kiến trúc, tech stack, và đặc biệt là **Architectural Guardrails**: các nguyên tắc bất biến mà mọi agent phải tuân theo khi sinh `tech.md`.

SAD không chứa: feature-level design, business rules, entity details — những thứ đó thuộc về `domain.md` và `fdd.md`.

**Một side-effect cascade lên `domain.md`:** carve component là việc *thiết kế hệ thống* (HOW), nên `/spec-sad` là nơi gán **`Owner`** cho các shared entity mà pha *mô tả hệ thống* (WHAT — qua `/spec-prd`/`/spec-frd`/`/spec-new`) đã định nghĩa nhưng để `Owner: TBD`. SAD không chứa entity content; nó chỉ điền cột ownership còn trống. Xem two-phase cascade ở `01-architecture.md` §7.

**Guardrails là phần quan trọng nhất của SAD.** Thiếu guardrails = agent tự quyết định tech pattern mà không có constraint.

## When to Use

- `sad.md` chưa có hoặc còn rỗng
- Tech stack thay đổi đáng kể và cần cập nhật architectural decisions
- Cần thêm guardrail mới sau khi phát hiện vấn đề trong quá trình implement

## When NOT to Use

- `prd.md` chưa có nội dung → chạy `/spec-prd` trước
- Đang muốn thiết kế một feature cụ thể → dùng `/spec-tech`

---

## Process

### Bước 1: Kiểm tra preconditions

**Đọc `.specs/main/prd.md`:**

- **Chưa tồn tại hoặc là template** → dừng ngay:
  > `prd.md` chưa có nội dung. Hãy chạy `/spec-prd` trước.

- **Đã có nội dung** → đọc để lấy: NFRs (performance, security, availability targets), business constraints, scope.

**Đọc `.specs/main/domain.md`:**

- **Chưa tồn tại** → dừng ngay:
  > `domain.md` chưa được scaffold. Hãy chạy `/spec-prd` trước (skill này scaffold cả `prd.md` và `domain.md` skeleton).

- **Đã tồn tại** → đọc để hiểu: glossary và shared entities (nếu có). Lưu ý `domain.md` có thể chỉ mới là skeleton vì nội dung chi tiết mọc dần qua cascade từ integrations — không cần dừng nếu file mỏng. **Ghi nhận các shared entity có `Owner: TBD`** (do pha mô tả seed) → đây là danh sách cần gán owner ở Bước 2 (Phần 1.6).

**Đọc `.specs/main/sad.md`:**

- **Chưa tồn tại** → tiến hành Bước 2 (full interview).

- **Đã có nội dung thực** → quét toàn bộ sections, hiển thị trạng thái từng section, rồi hỏi user muốn làm gì.

  **Các sections cần quét** (theo thứ tự):

  | # | Section | Có nội dung thực? |
  | --- | --- | --- |
  | 1 | Architectural Style | ✓ đã có / ✗ trống/thiếu |
  | 2 | System Overview | ✓ đã có / ✗ trống/thiếu |
  | 3 | Tech Stack | ✓ đã có / ✗ trống/thiếu |
  | 4 | Cross-Cutting Concerns | ✓ đã có / ✗ trống/thiếu |
  | 5 | Inter-Service Communication | ✓ đã có / ✗ trống/thiếu |
  | 6 | Infrastructure Overview | ✓ đã có / ✗ trống/thiếu |
  | 7 | Architectural Guardrails | ✓ đã có / ✗ trống/thiếu |
  | 8 | ADR Log | ✓ đã có / ✗ trống/thiếu |

  Một section được coi là **trống/thiếu** nếu: không tồn tại trong file, hoặc chỉ chứa placeholder template (dấu `{}`), hoặc không có dòng nội dung thực. Ngoài các sections trên, **ghi nhận các sections thừa** — những `##` heading có trong file nhưng không có trong template.

  Sau khi quét, liệt kê tất cả sections **theo đúng thứ tự xuất hiện trong file**, đánh số liên tục:

  ```
  sad.md hiện tại:
    [1] Architectural Style          ✓ đã có
    [2] System Overview              ✓ đã có
    [3] Tech Stack                   ✓ đã có
    [4] Cross-Cutting Concerns       ✗ chưa có — cần bổ sung
    [5] Inter-Service Communication  ✓ đã có
    [6] Infrastructure Overview      ✓ đã có
    [7] Architectural Guardrails     ✓ đã có
    [8] ADR Log                      ✗ chưa có — cần bổ sung
    [9] Deployment Diagram           ⚠ không có trong template
    [A] Interview tất cả sections

  Chọn số hoặc A:
  ```

  - User chọn số section thuộc template → interview section đó rồi merge vào file.
  - User chọn số section thừa (⚠) → xoá section đó khỏi file ngay, không hỏi thêm.
  - User chọn A → interview tuần tự tất cả sections thuộc template (sections thừa không bị đụng tới).

---

### Bước 2: Gather — interview có cấu trúc

Tóm tắt context đọc được và surface assumptions:

```
TỪ PRD & DOMAIN TÔI HIỂU:
- NFRs: {list NFRs từ prd — performance targets, availability, security}
- Entities chính: {list từ domain}
- Constraints: {business constraints từ prd}

ASSUMPTIONS TÔI ĐANG ĐẶT RA:
1. {assumption về scale, team size, v.v.}
2. {assumption về existing infrastructure nếu có}
→ Sửa lại nếu sai trước khi tiếp tục.
```

Hỏi tuần tự từng phần:

**Phần 1 — Architectural Style:**
> Hệ thống sẽ theo kiến trúc nào? (Monolith / Modular Monolith / Microservices / Event-driven / ...)
> Nếu chưa quyết định, tôi có thể đề xuất dựa trên NFRs và team size — muốn không?

Nếu user muốn đề xuất → đề xuất 2-3 option với trade-offs rõ ràng, để user chọn. Không quyết định thay.

**Phần 1.5 — System Overview (diagram + Components table):**
> Vẽ sơ đồ tổng thể (Mermaid): các component và quan hệ chính.
> Components table (projection từ `prd.md > Components`): với mỗi `C-XXX`, ghi 1 dòng architectural note — boundary/deployment unit/key tech concern. **Không lặp lại role/responsibility từ `crd.md`** — chỉ góc nhìn architectural.

Nếu `prd.md > Components` còn rỗng (brownfield init chưa scan code, hoặc greenfield chưa biết component) → để placeholder và note rằng bảng này sẽ được điền khi Component Index có nội dung (qua `/spec-brownfield-component` hoặc cascade từ integration).

**Phần 1.6 — Gán Owner cho shared entity (cascade lên domain):**

Sau khi component boundaries đã rõ (từ Components table), với mỗi shared entity có `Owner: TBD` (ghi nhận ở Bước 1):
> Entity **{Entity}** (định nghĩa ở domain) nên được component nào sở hữu canonical definition?
>   - {C-XXX} — {tên}
>   - {C-YYY} — {tên}
> Và những component nào reference nó (Used by)?

- Gán `Owner: C-XXX` (component giữ canonical definition) + `Used by: C-XXX, C-YYY`.
- Nếu hoá ra entity chỉ một component dùng → vẫn ghi `Owner`, `Used by` chỉ component đó; cân nhắc note rằng nó có thể chuyển về `crd.md` nội bộ (không bắt buộc xử lý ở đây).
- Component Index còn rỗng → để nguyên `Owner: TBD`, gán sau khi component được carve.

Đây là nửa **thiết kế hệ thống (HOW)** của domain cascade — bổ sung ownership cho định nghĩa entity mà pha mô tả đã tạo. Ghi xuống ở Bước 5.

**Phần 2 — Tech Stack:**
> Tech stack cho từng layer: Frontend, Backend, Database, Infrastructure?
> Với mỗi lựa chọn: lý do chọn là gì? (performance, team familiarity, ecosystem...)

Nếu user chưa quyết định layer nào → đề xuất options dựa trên NFRs và architectural style đã chọn.

**Phần 3 — Cross-Cutting Concerns:**
> Authentication & Authorization: strategy nào? (JWT, session, OAuth, API key...)
> Error Handling: pattern nào? (global handler, error codes, retry policy...)
> Logging & Monitoring: approach nào? (structured logging, tracing, alerting...)
> Caching: có dùng cache không? Ở layer nào? Strategy gì?

**Phần 4 — Inter-Service Communication:** *(chỉ hỏi nếu không phải monolith)*
> Các service communicate với nhau thế nào? (REST, gRPC, message queue, events...)
> Có service nào cần sync call vs async không?

**Phần 5 — Infrastructure:**
> Deploy ở đâu? (cloud provider, on-premise, hybrid)
> Có bao nhiêu môi trường? (dev, staging, prod)
> Deployment strategy: (containerized, serverless, VM...)

**Phần 6 — Architectural Guardrails:** *(quan trọng nhất)*
> Dựa trên tech stack và concerns vừa thảo luận, tôi sẽ đề xuất một bộ guardrails. Bạn review và thêm/bớt nhé.

Đề xuất guardrails cụ thể dựa trên những gì đã thu thập. Ví dụ:
- Nếu dùng ORM → `GUARD-XXX: Không dùng raw SQL, phải qua ORM`
- Nếu có external API → `GUARD-XXX: Mọi external API call phải có retry + timeout`
- Nếu layered architecture → `GUARD-XXX: Không để business logic trong API/controller layer`

**Phần 7 — ADR Log:**
> Trong quá trình thảo luận vừa rồi, những quyết định nào là *quan trọng và có đánh đổi*? (chọn architectural style, tech chính, sync vs async...)
> Với mỗi cái, tôi sẽ ghi một ADR entry: quyết định + bối cảnh/lý do + hệ quả.

Tự đề xuất ADR-001+ từ chính các lựa chọn user đã chốt ở Phần 1–6 (style, tech stack, communication) — không bắt user nhập lại từ đầu. Status mặc định `accepted`. Nếu chưa có quyết định nào đáng ghi → để placeholder.

---

### Bước 3: Write — sinh draft

Dùng `.claude/templates/main/sad-template.md` làm skeleton, điền nội dung từ interview vào từng section.

Hiển thị draft cho user xem — **chưa ghi file**.

---

### Bước 4: Review — xác nhận với user

Trình bày draft và chú ý hỏi riêng về Guardrails:
> Phần Architectural Guardrails có đủ và đúng không? Đây là phần agent sẽ dùng để validate mọi technical design sau này.

Chỉ ghi file sau khi user confirm. Nếu user yêu cầu chỉnh sửa → cập nhật draft → hỏi lại.

---

### Bước 5: Save

Ghi nội dung đã được confirm vào `.specs/main/sad.md`. Frontmatter lấy `template_version` từ `sad-template.md` lúc create (xem `01-architecture.md` §12); lần chạy update sau giữ nguyên, không đụng.

**Bump `id_counters`:** mỗi `ADR-nnn` `[NEW]` trong ADR Log → set `id_counters.adr` = seq lớn nhất vừa cấp (high-water-mark). KHÔNG ghi Change History (đã bỏ — history = git, xem `01-architecture.md` §7).

**Cascade Owner lên `domain.md` (nếu Phần 1.6 gán owner cho entity TBD):** apply `[MODIFY Owner]` + `[MODIFY Used by]` vào các entity tương ứng trong `domain.md > Shared Entities`. Đây là `[MODIFY]` (không cấp ID mới) nên KHÔNG đụng `id_counters.entity`; commit lại là bản ghi thay đổi.

Atomic với việc ghi sad.md. Không tạo entity mới ở đây (đó là pha mô tả); chỉ điền `Owner`/`Used by` còn `TBD`.

Thông báo kết quả:
```
✓ .specs/main/sad.md đã được cập nhật (status: draft)
{nếu có} ✓ domain.md — gán Owner cho {N} shared entity (TBD → C-XXX)

Bước tiếp theo:
  - /spec-new {feature-name} → định nghĩa requirements của từng feature
```

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Tech stack thì sau quyết định cũng được" | Tech stack ảnh hưởng đến guardrails. Không có guardrails = agent tự ý chọn pattern khi sinh tech.md. |
| "Guardrails thì ghi ít thôi, ghi nhiều phức tạp" | Mỗi guardrail thiếu là một loại technical debt có thể xảy ra. Ghi đủ ngay từ đầu. |
| "System diagram thì vẽ sau" | Diagram buộc phải nghĩ về component boundaries. Không có diagram = chưa rõ architecture. |
| "Cross-cutting concerns thì ai cũng biết rồi" | "Auth strategy" chưa được ghi = mỗi feature tự implement theo cách riêng. |

## Red Flags

- Guardrails section rỗng hoặc chỉ có 1-2 item chung chung
- Tech stack chọn mà không có lý do
- Lý do chọn tech là "quen dùng" mà không đối chiếu với NFRs
- System Overview không có diagram hoặc mô tả component boundaries
- Cross-cutting concerns bỏ trống

## Verification

Trước khi kết thúc, kiểm tra:

- [ ] Frontmatter đầy đủ và đúng schema (gồm `template_version` copy từ template lúc create; update không đụng)
- [ ] Architectural Style có lý do gắn với NFRs hoặc constraints
- [ ] System Overview có diagram + Components table; danh sách C-XXX khớp với `prd.md > Components` (hoặc cả hai cùng rỗng nếu Component Index chưa được điền)
- [ ] Mỗi tech stack item có lý do chọn rõ ràng
- [ ] Tất cả 4 cross-cutting concerns đã được điền (auth, error, logging, caching)
- [ ] Guardrails có ít nhất 3 item, mỗi item cụ thể và actionable
- [ ] Shared entity có `Owner: TBD` đã được gán `Owner: C-XXX` + `Used by` (nếu Component Index đã có nội dung); cascade `[MODIFY Owner]` lên domain.md (commit là bản ghi; KHÔNG Change History)
- [ ] ADR mới cấp thì `id_counters.adr` đã bump (high-water-mark, §7)
- [ ] User đã confirm — đặc biệt phần Guardrails — trước khi ghi file
