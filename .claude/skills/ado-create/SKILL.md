---
name: ado-create
description: Tạo Feature và User Story tickets trên ADO từ spec.md của một integration. Set parent là Epic từ ado.yaml, assign cho current user, cập nhật ticket references vào spec.md và frd.md tương ứng.
---

# ado-create

## Overview

Đọc `spec.md` của một integration, tạo Feature và User Story tickets trên ADO, rồi ghi ticket ID/title/URL trở lại vào `spec.md` và `frd.md` tương ứng.

## Prerequisites

- `.claude/ado.yaml` phải tồn tại và có `epic.id` (chạy `/ado-config` nếu chưa có)
- `frd.md` tương ứng phải tồn tại trong `.specs/main/features/` cho mỗi feature

**Area / Iteration (tùy chọn):** Nếu `.claude/ado.yaml` có `area_path` và/hoặc `iteration_path`, mọi ticket (Feature + User Story) tạo ở Bước 5 và Bước 6 phải set `areaPath` / `iterationPath` tương ứng. Nếu không khai báo → để ADO dùng giá trị mặc định của team.

---

## Process

### Bước 1: Load config và xác định current user

Đọc `.claude/ado.yaml`. Nếu không tồn tại → dừng và báo lỗi:

```
Chưa có .claude/ado.yaml. Hãy chạy /ado-config trước.
```

**Xác định current user:** Gọi `mcp__azure-devops__core_get_identity_ids` với descriptor `me` hoặc `[me]` để lấy identity của user đang authenticated với ADO. Từ kết quả trả về, lấy `providerDisplayName` hoặc `subjectDescriptor` rồi tìm email tương ứng trong toàn bộ `team.PE + team.SE + team.DE` của ado.yaml.

**Nếu tìm thấy** → dùng email đó làm assignee, dùng identity ID từ kết quả MCP (không cần gọi lại).

**Nếu không resolve được (tool lỗi hoặc không match được email)** → hỏi bằng `AskUserQuestion`:

```
question: "Bạn là ai trong team? (dùng để assign ticket)"
options: [mỗi email trong team.PE + team.SE + team.DE thành 1 option]
```

Sau khi user chọn email, resolve thành ADO identity ID bằng `mcp__azure-devops__core_get_identity_ids`.

Nếu resolve thất bại → **dừng và báo lỗi**. Không tạo ticket nếu không xác định được assignee:

```
Không resolve được ADO identity ID cho <email>. Kiểm tra lại PAT token hoặc quyền truy cập ADO rồi thử lại.
```

---

### Bước 2: Chọn integration

List tất cả thư mục trong `.specs/integrations/` trừ `000-scaffold`. Với mỗi thư mục, đọc frontmatter của `spec.md` để lấy `title` và `status`.

Hỏi user bằng `AskUserQuestion`:

```
question: "Chọn integration để tạo ADO tickets:"
options:
  - label: "001-implement-auth — Implement Authentication"
    description: "status: draft | features: F-001"
  - label: "002-implement-todo — Implement Todo Management"
    description: "status: draft | features: F-002, F-003"
  - ...
```

Sau khi user chọn → đọc toàn bộ `spec.md` của integration đó.

---

### Bước 3: Parse spec.md

Extract từ spec.md:

**Features:** Tìm các heading theo pattern `### Feature: <name> (<ID>)`.
Ví dụ: `### Feature: Đăng ký / Đăng nhập (F-001)` → `{id: "F-001", name: "Đăng ký / Đăng nhập"}`

**User Stories:** Tìm các heading theo pattern `#### US-FXXX-YYY — <title>`.
Ví dụ: `#### US-F001-001 — Đăng ký` → `{code: "US-F001-001", title: "Đăng ký", feature_id: "F-001"}`

Với mỗi User Story, thu thập thêm:
- Câu story: dòng `**<role>** muốn **<want>** để **<goal>**.`
- `Priority`
- Tất cả ACs bên dưới (từ `**Acceptance Criteria:**` đến heading tiếp theo)

**Kiểm tra đã có ADO ticket chưa:** Ngay sau heading của mỗi Feature / User Story, tìm dòng có format `**ADO:**`. Nếu có → đánh dấu `already_created: true`, lưu lại ID/URL hiện có.

---

### Bước 4: Preview và xác nhận

Hiển thị kế hoạch trước khi tạo — **chưa tạo gì**:

```
Integration: 001-implement-auth — Implement Authentication
Assignee:    anh.le@torus.vn

Sẽ tạo các tickets sau:

  Feature Tickets (parent: Epic #24241 — [SDLC-TEST] Spec Lite Kit):
  ✦ F-001 — Đăng ký / Đăng nhập         [NEW]

  User Story Tickets:
  ✦ US-F001-001 — Đăng ký               [NEW] → parent: F-001
  ✦ US-F001-002 — Đăng nhập             [NEW] → parent: F-001
  ✦ US-F001-003 — Đăng xuất             [NEW] → parent: F-001

  Skip (đã có ADO ticket):
  ✓ F-002 — ...  #12345 (đã tạo trước)

Tiếp tục tạo? (yes/no)
```

Nếu user từ chối → dừng không tạo gì.

---

### Bước 5: Tạo Feature Tickets

Thực hiện tuần tự với từng Feature chưa có ADO ticket:

**5.1 Tìm frd.md:**

Map `F-NNN` → tìm thư mục `.specs/main/features/` bắt đầu bằng `NNN-`. Đọc `frd.md` trong thư mục đó.

Nếu không tìm thấy `frd.md` → cảnh báo, dùng phần mô tả Feature từ `spec.md` làm description thay thế.

**5.2 Tạo ticket:**

Gọi `mcp__azure-devops__wit_create_work_item` với:
- `type`: `Feature`
- `title`: `[{project_code}] [{feature_id}] {feature_name}` — ví dụ: `[SDLC-TEST] [F-001] Đăng ký / Đăng nhập`
- `description`: toàn bộ nội dung `frd.md` (giữ nguyên format Markdown)
- `assignedTo`: ADO identity ID của current user (nếu resolve thành công)
- `areaPath`: giá trị `area_path` từ ado.yaml (nếu có)
- `iterationPath`: giá trị `iteration_path` từ ado.yaml (nếu có)

Sau khi tạo thành công → **ngay lập tức** link parent. Ưu tiên dùng `mcp__azure-devops__wit_add_child_work_items` (parent = Epic ID, child = Feature ticket ID). Nếu tool này không khả dụng, fallback sang `mcp__azure-devops__wit_work_items_link` với:
- `sourceId`: Feature ticket ID vừa tạo
- `targetId`: Epic ID từ ado.yaml
- `relationType`: `System.LinkTypes.Hierarchy-Reverse`

**Nếu link parent thất bại:**
1. Retry một lần
2. Nếu vẫn fail → đánh dấu Feature này là `orphan` (KHÔNG xóa ticket), ghi vào danh sách cần xử lý thủ công, tiếp tục với Feature tiếp theo. Ticket orphan sẽ được báo cáo nổi bật ở Bước 10.

Lưu lại `{id, title, url}`. URL format:
```
https://dev.azure.com/{organization}/{project_name}/_workitems/edit/{id}
```

Nếu tạo ticket thất bại → log lỗi, đánh dấu Feature này là `failed`, skip toàn bộ User Stories thuộc Feature đó, tiếp tục với Feature tiếp theo.

---

### Bước 6: Tạo User Story Tickets

Thực hiện tuần tự với từng User Story chưa có ADO ticket:

**6.1 Xác định parent Feature ticket ID:**

Lấy Feature ticket ID theo thứ tự ưu tiên:
1. Feature vừa tạo ở Bước 5 → dùng ID từ kết quả MCP
2. Feature đã `already_created` → parse ID từ dòng `**ADO:** [#<ID> — ...](url)` trong `spec.md`

Nếu Feature đó là `failed` → skip toàn bộ User Stories thuộc Feature đó, báo cáo ở Bước 10.
Nếu Feature là `orphan` (tạo thành công nhưng link Epic thất bại) → vẫn dùng Feature ID đó làm parent cho User Stories, nhưng đánh dấu chuỗi này cần review thủ công.
Nếu không đọc được Feature ticket ID từ bất kỳ nguồn nào → skip User Story này với cảnh báo.

**6.2 Build description:**

```markdown
**{role}** muốn **{want}** để **{goal}**.

**Priority:** {priority}

**Acceptance Criteria:**

- AC-code
  - **Given** ...
  - **When** ...
  - **Then** ...
```

**6.3 Tạo ticket:**

Gọi `mcp__azure-devops__wit_create_work_item` với:
- `type`: `User Story`
- `title`: `[{project_code}] [{feature_name}] - {US-code} — {story_title}` — ví dụ: `[SDLC-TEST] [Đăng ký / Đăng nhập] - US-F001-001 — Đăng ký`
- `description`: description đã build ở 6.2
- `assignedTo`: ADO identity ID của current user
- `areaPath`: giá trị `area_path` từ ado.yaml (nếu có)
- `iterationPath`: giá trị `iteration_path` từ ado.yaml (nếu có)

Sau khi tạo thành công → **ngay lập tức** link parent. Ưu tiên dùng `mcp__azure-devops__wit_add_child_work_items` (parent = Feature ticket ID, child = User Story ticket ID). Nếu không khả dụng, fallback sang `mcp__azure-devops__wit_work_items_link` với:
- `sourceId`: User Story ticket ID vừa tạo
- `targetId`: Feature ticket ID
- `relationType`: `System.LinkTypes.Hierarchy-Reverse`

**Nếu link parent thất bại:**
1. Retry một lần
2. Nếu vẫn fail → đánh dấu User Story này là `orphan` (KHÔNG xóa ticket), ghi vào danh sách cần xử lý thủ công, tiếp tục với User Story tiếp theo.

Lưu lại `{id, title, url}`.

---

### Bước 7: Cập nhật spec.md

Sau khi tất cả tickets đã được tạo, cập nhật `spec.md`:

**Với Feature ticket thành công:** Thêm dòng `**ADO:**` ngay sau heading feature, trên dòng trống đầu tiên:

```markdown
### Feature: Đăng ký / Đăng nhập (F-001)
**ADO:** [#12345 — [SDLC-TEST] Đăng ký / Đăng nhập](https://dev.azure.com/...)

**Feature Acceptance Criteria:**
```

**Với User Story ticket thành công:** Thêm dòng `**ADO:**` ngay sau heading user story:

```markdown
#### US-F001-001 — Đăng ký
**ADO:** [#12346 — US-F001-001 — Đăng ký](https://dev.azure.com/...)

**Nhân viên mới** muốn ...
```

---

### Bước 8: Cập nhật prd.md

Mở `.specs/main/prd.md`. Tìm bảng `## Features`.

**Nếu bảng chưa có cột `ADO`:** Thêm cột vào header và separator row:

```markdown
| ID | Feature | Mô tả | Priority | Status | ADO |
| --- | --- | --- | --- | --- | --- |
```

Với mỗi Feature ticket vừa tạo thành công, tìm row tương ứng theo `ID` (ví dụ `F-001`) và thêm link vào cột `ADO`:

```markdown
| F-001 | Đăng ký / Đăng nhập | ... | Must | In Progress | [#12345](url) |
```

Nếu cột `ADO` đã tồn tại và row đã có giá trị → **không ghi đè**, bỏ qua.

---

### Bước 9: Cập nhật frd.md

Với mỗi `frd.md` thuộc integration này:

Tìm section `## ADO Tickets` trong file.

**Nếu chưa có:** Append vào cuối file:

```markdown

## ADO Tickets

| Type | Code | Ticket |
|------|------|--------|
| Feature | F-001 | [#12345 — [SDLC-TEST] Đăng ký / Đăng nhập](url) |
| User Story | US-F001-001 | [#12346 — US-F001-001 — Đăng ký](url) |
| User Story | US-F001-002 | [#12347 — US-F001-002 — Đăng nhập](url) |
| User Story | US-F001-003 | [#12348 — US-F001-003 — Đăng xuất](url) |
```

**Nếu đã có:** Append các row mới (tickets vừa tạo) vào cuối bảng. Không xóa row cũ.

---

### Bước 10: Tóm tắt kết quả

```
✓ ADO tickets đã tạo — integration: 001-implement-auth

  Feature Tickets:
  ✓ #12345 — [SDLC-TEST] [F-001] Đăng ký / Đăng nhập
    https://dev.azure.com/torus-engineering/Common/_workitems/edit/12345

  User Story Tickets:
  ✓ #12346 — [SDLC-TEST] [Đăng ký / Đăng nhập] - US-F001-001 — Đăng ký    → F-001 #12345
  ✓ #12347 — [SDLC-TEST] [Đăng ký / Đăng nhập] - US-F001-002 — Đăng nhập  → F-001 #12345
  ✓ #12348 — [SDLC-TEST] [Đăng ký / Đăng nhập] - US-F001-003 — Đăng xuất  → F-001 #12345

  Files đã cập nhật:
  ✓ .specs/integrations/001-implement-auth/spec.md
  ✓ .specs/main/features/001-auth/frd.md
  ✓ .specs/main/prd.md

  {nếu có lỗi tạo ticket}
  ✗ US-F001-004 — ... → tạo thất bại: <lý do>

  {nếu có orphan — cần xử lý thủ công NGAY}
  ⚠ ORPHAN — ticket tồn tại nhưng CHƯA có parent:
    #12349 — US-F001-005 — ...
    → Cần link thủ công: parent = Feature #12345
    → https://dev.azure.com/torus-engineering/Common/_workitems/edit/12349
```

---

## Verification Checklist

Trước khi tạo ticket:
- [ ] `.claude/ado.yaml` tồn tại và `epic.id` là số nguyên hợp lệ
- [ ] Current ADO user đã được xác định và resolve thành identity ID — **nếu không xác định được thì dừng, không tạo ticket không có assignee**
- [ ] Integration được chọn có `spec.md` chứa ít nhất 1 Feature
- [ ] `frd.md` tìm được cho mỗi Feature (cảnh báo nếu thiếu, không dừng)

Khi tạo ticket:
- [ ] Feature type là `Feature` — không phải `Epic` hay `User Story`
- [ ] User Story type là `User Story`
- [ ] Parent link được thực hiện **ngay sau khi tạo ticket** — không để cuối batch
- [ ] Nếu parent link fail: retry 1 lần, nếu vẫn fail → đánh dấu `orphan`, báo cáo ở Bước 10, KHÔNG im lặng bỏ qua
- [ ] `already_created` Feature: lấy ticket ID từ `**ADO:**` trong spec.md để dùng làm parent cho User Stories
- [ ] Title Feature theo format `[{project_code}] [{feature_id}] {feature_name}`
- [ ] Title User Story theo format `[{project_code}] [{feature_name}] - {US-code} — {story_title}`

Khi cập nhật file:
- [ ] `**ADO:**` được thêm vào đúng vị trí trong `spec.md` (ngay sau heading, trước nội dung)
- [ ] Chỉ ghi khi ticket tạo **thành công** — không ghi nếu failed
- [ ] `frd.md` section `## ADO Tickets` không duplicate row đã tồn tại
- [ ] `prd.md` cột `ADO` chỉ thêm vào feature row tương ứng — không ghi đè nếu đã có giá trị