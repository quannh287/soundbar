---
id: prd
type: prd
status: draft
owner: "{PM/BA}"
project_name: "{tên dự án}"
template_version: 2
migrations:
  - to: 1
    note: "baseline"
  - to: 2
    remove: [Change History]
    note: "Bỏ section Change History — history = git. Thêm frontmatter id_counters (feature, component) làm high-water-mark cấp ID (thay việc quét Change History để giữ ID không tái dùng). Migrate: seed mỗi counter = max(ID trong doc, ID trong Change History cũ) TRƯỚC khi xoá section."
id_counters:
  feature: 0
  component: 0
referenced_by:
  - 02-artifacts.md > 3. Main Artifacts > 3.1 Product level > prd.md > Cấu trúc
  - skills/spec-prd/SKILL.md > Process > Bước 1: Kiểm tra preconditions
  - skills/spec-prd/SKILL.md > Process > Bước 3: Write — sinh nội dung
---

# Product Requirements Document

## Problem Statement

Vấn đề mà hệ thống giải quyết — viết từ góc nhìn business, 2-3 câu.
Tại sao cần giải quyết bây giờ.

## Target Users

| Persona | Mục tiêu | Pain Point hiện tại |
| --- | --- | --- |
| {tên persona} | {goal chính} | {khó khăn đang gặp} |

## Scope

### In Scope

- {những gì hệ thống sẽ làm}

### Out of Scope

- {item} — {lý do}

## Features

Đặt tên feature theo **outcome của một luồng hoàn chỉnh**, kebab-case, đủ khái quát mà vẫn là *một* luồng — không quá rộng (`user-management` là feature area), không quá hẹp (`register-with-google` chỉ là biến thể). ✅ `user-registration`, `password-reset`, `checkout`.

**Cấp ID (`F-XXX`):** ID kế tiếp = `id_counters.feature + 1`; cấp xong tăng `id_counters.feature` (frontmatter). ID **stable** — không tái sử dụng khi remove, không renumber. Counter là high-water-mark, không giảm khi remove → ID đã cấp không bao giờ cấp lại (history = git).

| ID | Feature | Mô tả | Priority | Status |
| --- | --- | --- | --- | --- |
| F-001 | {tên feature} | {mô tả ngắn — feature làm gì, cho ai} | High/Medium/Low | TODO/DONE |

## Components

Một component = một khối có **boundary rõ + interface tường minh** và **một lý do duy nhất để thay đổi**. Không phân loại component thành "domain" hay "kỹ thuật" — mỗi component đều có mặt domain (`crd.md`) lẫn mặt kỹ thuật (`cdd.md`).

Đặt tên component theo **năng lực bền vững**, không theo công nghệ hiện tại, kebab-case. ✅ `notification`, `auth`, `file-storage`. ❌ quá cụ thể (`email-sender`, `stripe-client`) hoặc quá mơ hồ (`core`, `utils`, `manager`).

Section này **chỉ liệt kê component có boundary _Given_** — tức boundary bị ép từ ngoài, chỉ có một cách vẽ hợp lý. Áp thủ tục:
- **Câu 1 (External):** bọc/adapt hệ thống ngoài ta buộc phải tích hợp? (vd `payment-gateway` tích hợp Stripe, `email-service` tích hợp SendGrid) → Given, khai ở đây.
- **Câu 2 (Mandated-substrate):** nền tảng kỹ thuật dùng chung mà yêu cầu bắt buộc, độc lập với cách carve lõi nghiệp vụ? (vd `auth`, `file-storage`, `notification`) → Given, khai ở đây.
- **Còn lại (Derived):** boundary phụ thuộc cách carve lõi nghiệp vụ hoặc đánh đổi NFR (vd `order`, `pricing`, `inventory`) → **KHÔNG** khai ở đây.

**Component Derived mọc dần qua:**
- `/spec-sad` — architect lock component boundaries dựa trên full feature index + NFRs
- `/spec-new F-XXX` cascade — khi analyze 1 feature, discover component mới nếu cần và register vào đây qua Changes block

Chi tiết về vai trò và thiết kế nằm trong `.specs/main/component/{C-XXX}-{component-name}/`.

**Cấp ID (`C-XXX`):** ID kế tiếp = `id_counters.component + 1`; cấp xong tăng `id_counters.component` (frontmatter). ID **stable** — không tái sử dụng khi remove, không renumber.

| ID | Component | Mô tả ngắn | Status |
| --- | --- | --- | --- |
| C-001 | {tên component} | {1 câu — component này chịu trách nhiệm gì} | TODO/DONE |

## Non-Functional Requirements

NFR **product-wide** (bar chung cho cả sản phẩm). Feature refine/siết bar này cho ngữ cảnh của nó trong `frd.md > Non-Functional Requirements` bằng `NFR-F{NNN}-{seq}` *(tham chiếu `NFR-*` ở đây)*; NFR đặc thù-feature mà chưa có ở đây → nếu lặp lại ở nhiều feature thì **promote** lên bảng này.

| ID | Category | Requirement | Target | Priority |
| --- | --- | --- | --- | --- |
| NFR-P01 | Performance | {requirement} | {target đo được} | High/Medium/Low |
| NFR-SE01 | Security | {requirement} | {target} | High/Medium/Low |
| NFR-A01 | Availability | {requirement} | {target} | High/Medium/Low |

## Business Constraints

- {ràng buộc kinh doanh} — constraint
- {giả định quan trọng} — assumption

