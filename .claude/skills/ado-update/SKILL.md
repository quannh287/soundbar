---
name: ado-update
description: Cập nhật trạng thái (state) cho tất cả User Story và Feature tickets trên ADO theo tiến trình deploy/verify qua từng môi trường được cấu hình trong ado.yaml.
---

# ado-update

## Overview

Đọc `spec.md` của một integration, kiểm tra ADO tickets đã tồn tại chưa, sau đó cho phép user chọn trạng thái mới để cập nhật đồng loạt toàn bộ User Story tickets — và tuỳ chọn cả Feature tickets.

---

## Prerequisites

- `.claude/ado.yaml` phải tồn tại và có `environments` (chạy `/ado-config` nếu chưa có)
- Tất cả Feature và User Story trong integration phải đã có ADO ticket (chạy `/ado-create` nếu chưa có)

---

## State Source

State names **không được generate từ `environments`** — chúng được lấy trực tiếp từ ADO bằng `mcp__azure-devops__wit_get_work_item_type`. Mỗi project có thể đặt tên state khác nhau (ví dụ: `dev` có thể là `Deploy Test` thay vì `Deploy Dev`).

- **User Story states**: fetch từ ADO work item type `User Story`
- **Feature states**: fetch từ ADO work item type `Feature`

State list hiển thị cho user là danh sách `states` thực tế từ ADO response, **đã qua bước filter theo environments được cấu hình**.

---

## Environment-State Filtering

ADO thường định nghĩa state cho mọi environment có thể có (dev, stag, prod). Sau khi fetch, **filter bớt các state không tương ứng với environments trong `.claude/ado.yaml`** trước khi hiển thị cho user.

### Quy tắc filter

**Bước 1 — Tách state thành 2 nhóm:**

- **Nhóm environment-specific**: state khớp pattern `Deploy *` hoặc `Verify *` (ví dụ: Deploy Test, Verify Test, Deploy Stag, Verify Stag, Deploy Prod, Verify Prod)
- **Nhóm general**: tất cả state còn lại (New, Pending, In Progress, Done, Removed, v.v.) — giữ nguyên, không filter

**Bước 2 — Group environment-specific states thành pairs:**

Sắp xếp theo thứ tự xuất hiện trong ADO response, group thành cặp `(Deploy X, Verify X)` theo thứ tự:
- Pair 0 → tương ứng `environments[0]`
- Pair 1 → tương ứng `environments[1]`
- Pair N → tương ứng `environments[N]`

**Bước 3 — Giữ chỉ các pairs có index nằm trong danh sách environments:**

Environments trong config có bao nhiêu phần tử → giữ bấy nhiêu pairs (theo đúng thứ tự). Pairs thừa (tương ứng env không có trong config) → loại bỏ.

### Ví dụ

Config: `environments: [dev, prod]` → 2 environments

ADO trả về states (theo thứ tự): New, Pending, In Progress, Deploy Test, Verify Test, Deploy Stag, Verify Stag, Deploy Prod, Verify Prod, Done, Removed

Environment-specific pairs (theo thứ tự ADO):
- Pair 0: (Deploy Test, Verify Test) → `environments[0]` = dev ✓ giữ
- Pair 1: (Deploy Stag, Verify Stag) → `environments[1]` = prod ✗ nhưng config[1] = prod, không phải stag → loại
- Pair 2: (Deploy Prod, Verify Prod) → `environments[2]` = không có (chỉ có 2 env) → loại

Vì config có 2 environments → giữ 2 pairs đầu tiên: Pair 0 (dev) và Pair 2 (prod):
- Pair 0: (Deploy Test, Verify Test) → env[0] = dev ✓
- Pair 2: (Deploy Prod, Verify Prod) → env[1] = prod ✓

State list sau filter: New, Pending, In Progress, Deploy Test, Verify Test, Deploy Prod, Verify Prod, Done, Removed

> **Lưu ý về mapping positional:** Tổng số pairs ADO trả về có thể nhiều hơn số environments trong config. Map theo vị trí index trong danh sách pairs: pair thứ 0 → env thứ 0, pair thứ 1 → env thứ 1. Pairs có index ≥ số environments trong config → loại bỏ.

---

## Process

### Bước 1: Load config

Đọc `.claude/ado.yaml`. Nếu không tồn tại → dừng:

```
Chưa có .claude/ado.yaml. Hãy chạy /ado-config trước.
```

Nếu `environments` trống hoặc không tồn tại trong file → dừng:

```
.claude/ado.yaml chưa có danh sách environments. Hãy chạy /ado-config để cập nhật.
```

---

### Bước 2: Chọn integration

List tất cả thư mục trong `.specs/integrations/` trừ `000-scaffold`. Với mỗi thư mục, đọc frontmatter của `spec.md` để lấy `title` và `status`.

Hỏi user bằng `AskUserQuestion`:

```
question: "Chọn integration để cập nhật ADO ticket status:"
options:
  - label: "001-implement-auth — Implement Authentication"
    description: "status: draft | features: F-001"
  - label: "002-implement-todo — Implement Todo Management"
    description: "status: draft | features: F-002, F-003"
  ...
```

Sau khi user chọn → đọc toàn bộ `spec.md` của integration đó.

---

### Bước 3: Parse và kiểm tra ADO tickets

**Parse spec.md** để extract:

**Features:** Tìm heading `### Feature: <name> (<ID>)` hoặc heading Feature tương đương. Sau mỗi heading, tìm dòng `**ADO F-XXX:**` hoặc `**ADO:**` để lấy ticket ID.

**User Stories:** Tìm heading `#### US-FXXX-YYY — <title>`. Sau mỗi heading, tìm dòng `**ADO:**` để lấy ticket ID.

**Quy tắc parse ADO ticket ID:** Tìm pattern `[#(\d+)` trong dòng `**ADO**` và extract số đó làm ticket ID.

**Kiểm tra đầy đủ tickets:**

- Nếu **bất kỳ** Feature hoặc User Story nào **chưa có** dòng `**ADO:**` → dừng và báo:

```
Integration "002-implement-todo" chưa có đầy đủ ADO tickets.

  Thiếu tickets:
  ✗ F-002 — Quản lý todo (chưa có Feature ticket)
  ✗ US-F002-003 — Xóa task (chưa có User Story ticket)

Hãy chạy /ado-create trước để tạo đầy đủ tickets.
```

- Nếu **tất cả** đều có → tiếp tục Bước 4.

---

### Bước 4: Fetch states từ ADO và hiển thị tickets hiện tại

Thực hiện **song song**:

1. Gọi `mcp__azure-devops__wit_get_work_items_batch_by_ids` với tất cả ticket IDs (Feature + User Story) để lấy state hiện tại.
2. Gọi `mcp__azure-devops__wit_get_work_item_type` với `workItemType: "User Story"` để lấy danh sách states thực tế.
3. Gọi `mcp__azure-devops__wit_get_work_item_type` với `workItemType: "Feature"` để lấy danh sách Feature states thực tế.

Extract `states[].name` từ response của mỗi work item type — đây là danh sách state hợp lệ sẽ dùng ở Bước 5 và 7.

Hiển thị tóm tắt trạng thái hiện tại:

```
Integration: 002-implement-todo — Implement Todo Management

  User Story Tickets:
  • #24255 — US-F003-001 — Xem Shared Kanban Board       [New]
  • #24256 — US-F002-001 — Tạo task mới                  [New]
  • #24257 — US-F002-002 — Sửa task                      [Deploy Test]
  • #24258 — US-F002-003 — Xóa task                      [Verify Test]

  Feature Tickets:
  • #24253 — F-002 — Quản lý todo                        [In Development]
  • #24254 — F-003 — Shared dashboard                    [In Design]
```

---

### Bước 5: Chọn state mới cho User Story tickets

Dùng danh sách `states[].name` đã fetch từ ADO ở Bước 4, **áp dụng Environment-State Filtering** (xem phần trên) để loại bỏ các state không tương ứng với environments được cấu hình.

In ra danh sách đánh số dạng plain text — **không dùng `AskUserQuestion`** vì số state có thể vượt quá 4 options.

Ví dụ output với `environments: [dev, prod]` (đã filter bỏ Deploy Stag, Verify Stag):

```
Chọn state mới cho tất cả User Story tickets:

  1. New
  2. Pending
  3. Committed
  4. In Progress
  5. Deploy Test
  6. Verify Test
  7. Deploy Prod
  8. Verify Prod
  9. Done
  10. Removed

Nhập số (1–10):
```

Chờ user nhập số. Nếu input không hợp lệ → in lại danh sách và nhắc nhập lại.

---

### Bước 6: Xác nhận và cập nhật User Story tickets

Hiển thị preview trước khi cập nhật:

```
Sẽ cập nhật 4 User Story tickets → "Verify Dev":

  • #24255 — US-F003-001 — Xem Shared Kanban Board       [New] → [Verify Dev]
  • #24256 — US-F002-001 — Tạo task mới                  [New] → [Verify Dev]
  • #24257 — US-F002-002 — Sửa task                      [Deploy Dev] → [Verify Dev]
  • #24258 — US-F002-003 — Xóa task                      [Verify Dev] → (không đổi)

Tiếp tục? (yes/no)
```

Các ticket đã ở đúng state rồi → hiển thị "(không đổi)", không gọi API update.

Nếu user xác nhận → gọi `mcp__azure-devops__wit_update_work_item` tuần tự cho từng ticket cần cập nhật:
- `id`: ticket ID
- `state`: state mới đã chọn

Nếu update thất bại → log lỗi, tiếp tục với ticket tiếp theo, báo cáo ở Bước 8.

---

### Bước 7: Hỏi về Feature tickets

Sau khi hoàn tất User Story, hỏi user bằng `AskUserQuestion`:

```
question: "Bạn có muốn cập nhật state cho Feature tickets không?"
options:
  - label: "Có, cập nhật Feature tickets"
    description: "Chọn state mới và cập nhật tất cả Feature tickets của integration này"
  - label: "Không, bỏ qua"
    description: "Giữ nguyên state hiện tại của Feature tickets"
```

**Nếu user chọn "Không"** → nhảy thẳng đến Bước 8.

**Nếu user chọn "Có":**

In danh sách đánh số dạng plain text — **không dùng `AskUserQuestion`** — dùng Feature states đã fetch từ ADO ở Bước 4:

```
Chọn state mới cho tất cả Feature tickets:

  1. New
  2. In Design
  3. In Development
  4. Done
  5. Removed

Nhập số (1–5):
```

Chờ user nhập số. Nếu input không hợp lệ → in lại danh sách và nhắc nhập lại.

Hiển thị preview giống Bước 6 cho Feature tickets, xác nhận rồi gọi `mcp__azure-devops__wit_update_work_item` cho từng ticket cần cập nhật.

---

### Bước 8: Tóm tắt kết quả

```
✓ Cập nhật ADO ticket status — integration: 002-implement-todo

  User Story Tickets → "Verify Dev":
  ✓ #24255 — US-F003-001 — Xem Shared Kanban Board
  ✓ #24256 — US-F002-001 — Tạo task mới
  ✓ #24257 — US-F002-002 — Sửa task
  — #24258 — US-F002-003 — Xóa task  (không đổi — đã là Verify Dev)

  Feature Tickets → "In Development":
  ✓ #24253 — F-002 — Quản lý todo
  — #24254 — F-003 — Shared dashboard  (không đổi — đã là In Development)

  {nếu có lỗi}
  ✗ #24260 — US-F002-004 — ... → cập nhật thất bại: <lý do>
```

---

## Verification Checklist

Trước khi cập nhật:
- [ ] `.claude/ado.yaml` tồn tại và có `environments` là array không rỗng
- [ ] Tất cả Features và User Stories trong `spec.md` đều có dòng `**ADO:**` với ticket ID hợp lệ
- [ ] State list lấy từ ADO qua `wit_get_work_item_type` — **không generate từ `environments`**, không hardcode
- [ ] State list đã qua **Environment-State Filtering**: chỉ hiển thị Deploy/Verify pairs tương ứng với environments trong config; general states giữ nguyên
- [ ] State selection dùng numbered list plain text — **không dùng `AskUserQuestion`** (số options vượt giới hạn 4)
- [ ] User đã xem preview và xác nhận trước khi gọi API

Khi cập nhật:
- [ ] Chỉ gọi API update cho ticket **chưa ở đúng state** — không update nếu state không đổi
- [ ] Gọi tuần tự, không batch update (để xử lý lỗi từng ticket riêng lẻ)
- [ ] Nếu 1 ticket fail → tiếp tục với ticket tiếp theo, không dừng toàn bộ
- [ ] Feature tickets chỉ update khi user **chủ động chọn "Có"** ở Bước 7
