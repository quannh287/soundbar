---
name: ado-config
description: Tạo hoặc cập nhật .claude/ado.yaml — lưu thông tin Azure DevOps project (org, project, team members, epic ticket). Dùng khi bắt đầu làm việc với một ADO project hoặc khi cần cập nhật thông tin team.
---

# ado-config

## Overview

Tạo hoặc cập nhật `.claude/ado.yaml` — file config ADO project dùng chung cho tất cả các skill `/ado-*`.

## When to Use

- Lần đầu setup ADO cho project
- Cần cập nhật thông tin project, thành viên team, hoặc Epic ticket

## When NOT to Use

- Đã có `.claude/ado.yaml` và không cần thay đổi gì → dùng trực tiếp các skill `/ado-*` khác

---

## Process

### Bước 1: Kiểm tra file hiện tại

Kiểm tra xem `.claude/ado.yaml` đã tồn tại chưa.

**Nếu chưa tồn tại** → tiến hành collect toàn bộ từ Bước 2.

**Nếu đã tồn tại** → đọc file, hiển thị tóm tắt nội dung hiện tại:

```
.claude/ado.yaml đã tồn tại:

  organization: torus-engineering
  project_name: Galaxy GCC  (project_code: GAL-GCC)
  team:    PE: 1 người  |  SE: 2 người  |  DE: 1 người
  epic:    [42] [GAL-GCC] Spec Lite Kit
           https://dev.azure.com/torus-engineering/Galaxy GCC/_workitems/edit/42
```

Sau đó **bắt buộc** gọi `AskUserQuestion`:

```
question: "Bạn muốn cập nhật phần nào?"
options:
  - label: "Toàn bộ từ đầu"
    description: "Chạy lại tất cả các bước — project, team, epic, environments"
  - label: "Thông tin project"
    description: "Cập nhật organization, project, project_id, project_code"
  - label: "Team members"
    description: "Cập nhật danh sách PE / SE / DE"
  - label: "Epic ticket"
    description: "Tạo mới hoặc thay Epic ticket đang được lưu"
  - label: "Area / Iteration path"
    description: "Cập nhật area_path và iteration_path mặc định cho ticket"
  - label: "Môi trường"
    description: "Cập nhật danh sách environments (dev / stag / prod)"
```

Tuỳ theo lựa chọn:
- **"Toàn bộ từ đầu"** → chạy Bước 2 → 3 → 4 → 5 → 6 → 7 → 8
- **"Thông tin project"** → chỉ chạy Bước 2, bỏ qua Bước 3, 4, 5, 6, nhảy thẳng đến Bước 7 → 8 (giữ nguyên `team`, `epic`, `area_path/iteration_path`, `environments` từ file cũ)
- **"Team members"** → chỉ chạy Bước 3, bỏ qua Bước 2, 4, 5, 6, nhảy thẳng đến Bước 7 → 8 (giữ nguyên `organization/project`, `epic`, `area_path/iteration_path`, `environments` từ file cũ)
- **"Epic ticket"** → chỉ chạy Bước 4, bỏ qua Bước 2, 3, 5, 6, nhảy thẳng đến Bước 7 → 8 (giữ nguyên `organization/project`, `team`, `area_path/iteration_path`, `environments` từ file cũ)
- **"Area / Iteration path"** → chỉ chạy Bước 5, bỏ qua Bước 2, 3, 4, 6, nhảy thẳng đến Bước 7 → 8 (giữ nguyên tất cả còn lại từ file cũ)
- **"Môi trường"** → chỉ chạy Bước 6, bỏ qua Bước 2, 3, 4, 5, nhảy thẳng đến Bước 7 → 8 (giữ nguyên tất cả từ file cũ)

---

### Bước 2: Connect ADO và chọn project

**Organization:**

**Bắt buộc** gọi tool `AskUserQuestion` — không hỏi bằng plain text. Cấu hình:
- question: `"Azure DevOps organization name?"`
- options:
  - label `torus-engineering`, description `Org mặc định — nhấn Enter để chọn`
  - label `ats-technology`
- System tự thêm option "Type something" cho phép nhập tên org khác hoặc paste full URL

Kết quả:
- User nhấn Enter → chọn `torus-engineering`
- User dùng ↓ → chọn "Type something" → nhập tên org hoặc paste URL

Nếu user nhập full URL (ví dụ `https://dev.azure.com/my-org/...`) → tự extract phần org sau `dev.azure.com/`, bỏ mọi path phía sau.

**List projects qua MCP:**

Sau khi có organization, gọi MCP tool `mcp__azure-devops__core_list_projects` để lấy danh sách projects trong org đó.

Hiển thị numbered list và chờ user nhập số:

```
Các project trong org "torus-engineering":

  1. T-Lead    (ID: f95c3b00-b3a8-4405-b062-8471a57cabd6)
  2. C-Blok    (ID: 5d57bc02-c656-4be7-981f-4ee5ecf4ba0a)
  3. C-GAL     (ID: be587215-de0a-4ea2-952a-d5b635b5d748)
  4. C-GTEL    (ID: 06e852f7-83f5-48b6-a83f-81bd665e0187)
  ...

Nhập số thứ tự project:
```

Sau khi user nhập số → tự điền `project_name` và `project_id` từ kết quả MCP. Không hỏi user nhập tay.

Nếu MCP call thất bại → thông báo lỗi rõ ràng và hỏi user nhập `project_name` và `project_id` thủ công.

**Project Code:**
> Project code là gì? Đây sẽ là prefix cho mọi ticket trong project.
> (Ví dụ: `GAL-GCC`, `TORUS-BE`, `VNG-APP` — thường là 2–3 từ viết tắt, ngăn cách bởi dấu gạch ngang)

Gợi ý: đề xuất project code dựa trên tên project đã chọn (ví dụ "Galaxy GCC" → `GAL-GCC`). User có thể chấp nhận hoặc nhập lại.

---

### Bước 3: Nhập team members

Hỏi lần lượt từng role. Với mỗi role, nhập email hợp lệ, mỗi người một dòng, Enter trống khi xong:

```
PE (Product Engineer) [bắt buộc]:
> anh.le@atstechnology.vn
> minh.ngo@atstechnology.vn
>

SE (Software Engineer):
> b@atstechnology.vn
>

DE (Data Engineer):
>
```

Một người có thể đóng nhiều role — nhập lại ở role tương ứng.

**PE là bắt buộc** — nếu user để trống, nhắc lại và yêu cầu nhập ít nhất 1 email hợp lệ trước khi tiếp tục.

SE và DE không có ai → để trống (ghi array rỗng `[]`).

---

### Bước 4: Cấu hình Epic Ticket

Epic Ticket là ticket đại diện cho toàn bộ project/product đang được code. Mọi Feature/Story sẽ được link vào Epic này.

Hỏi user bằng `AskUserQuestion`:

```
question: "Epic Ticket cho project {project_name} ({project_code})?"
options:
  - label: "Tạo Epic mới"
    description: "Nhập title và mô tả — Claude sẽ tạo Epic trên ADO với prefix [{project_code}]"
  - label: "Nhập ID ticket có sẵn"
    description: "Nhập ID của Epic đã tồn tại trên ADO để validate và lưu vào config"
```

---

#### Option A: Tạo Epic mới

**1. Nhập title:**
> Epic title? (sẽ được prefix thành `[{project_code}] <title>`)

Ví dụ user nhập `Spec Lite Kit` → title cuối là `[SDLC-TEST] Spec Lite Kit`.

**2. Nhập mô tả:**

Hỏi bằng `AskUserQuestion`:
```
question: "Mô tả Epic?"
options:
  - label: "Tự nhập mô tả"
    description: "Nhập nội dung mô tả thủ công"
  - label: "Dùng nội dung từ spec artifact"
    description: "Chỉ định đường dẫn file spec.md / prd.md — Claude sẽ đọc và dùng làm mô tả"
```

Nếu user chọn **"Dùng nội dung từ spec artifact"**:
- Hỏi đường dẫn file (ví dụ `.specs/integrations/001-implement-auth/spec.md`)
- Đọc file → dùng toàn bộ nội dung làm description của Epic (format Markdown)

Nếu user chọn **"Tự nhập mô tả"**:
- Hỏi plain text mô tả, có thể để trống

**3. Tạo Epic qua MCP:**

Trước khi tạo, resolve email của PE đầu tiên thành ADO identity ID bằng `mcp__azure-devops__core_get_identity_ids` (dùng email từ `team.PE[0]`).

Gọi `mcp__azure-devops__wit_create_work_item` với:
- `type`: `Epic`
- `title`: `[{project_code}] <user_title>`
- `description`: nội dung đã nhập/đọc
- `assignedTo`: identity ID của PE đầu tiên trong danh sách

Sau khi tạo thành công → lưu `id`, `title`, và `url` vào config. URL được tạo theo format:

```
https://dev.azure.com/{organization}/{project_name}/_workitems/edit/{id}
```

Nếu resolve identity thất bại → tạo Epic không có assignee, thông báo để user tự assign thủ công trên ADO.

Nếu MCP call tạo Epic thất bại → thông báo lỗi và cho phép retry hoặc bỏ qua bước này.

---

#### Option B: Nhập ID ticket có sẵn

Hỏi user:
> Nhập ID của Epic ticket (chỉ số, ví dụ: `42`):

Sau khi user nhập → **bắt buộc validate qua MCP** bằng `mcp__azure-devops__wit_get_work_item`:

**Kiểm tra các điều kiện sau:**
1. Work item tồn tại trong ADO project đã chọn
2. `workItemType` phải là `Epic`
3. Title phải có prefix `[{project_code}]` — nếu không có thì cảnh báo nhưng vẫn cho phép user xác nhận tiếp tục

Nếu validation fail (không tồn tại hoặc không phải Epic) → thông báo lỗi cụ thể và cho phép nhập lại.

Nếu validation thành công → hiển thị thông tin ticket để user xác nhận:

```
Tìm thấy Epic:
  ID:    42
  Title: [SDLC-TEST] Spec Lite Kit
  State: New
  URL:   https://dev.azure.com/torus-engineering/Common/_workitems/edit/42

Dùng Epic này? (yes/no)
```

Sau khi user confirm → lưu `id`, `title`, và `url` vào config. URL được tạo theo format:

```
https://dev.azure.com/{organization}/{project_name}/_workitems/edit/{id}
```

---

### Bước 5: Cấu hình Area & Iteration Path

Area Path và Iteration Path mặc định sẽ được gán cho mọi Feature/User Story khi `/ado-create` tạo ticket. Cả hai đều **tùy chọn** — nếu bỏ trống, ADO dùng giá trị mặc định của team.

Hỏi user bằng `AskUserQuestion`:

```
question: "Cấu hình Area / Iteration path mặc định cho ticket?"
options:
  - label: "Nhập area & iteration path"
    description: "Gán area_path và iteration_path mặc định cho mọi ticket tạo qua /ado-create"
  - label: "Bỏ qua"
    description: "Không set — ADO dùng giá trị mặc định của team"
```

Nếu user chọn **"Nhập area & iteration path"** → hỏi lần lượt (cho phép Enter trống để bỏ từng field):

```
Area Path (ví dụ: Tickets\Clients\C-GAL\P-GCC):
> Tickets\Clients\C-GAL\P-GCC

Iteration Path (ví dụ: Tickets\Weekly Sprint):
> Tickets\Weekly Sprint
```

Lưu ý khi thu thập:
- Path dùng dấu backslash `\` phân cách như trên ADO. Chấp nhận cả khi user paste có khoảng trắng ở đầu/cuối → trim.
- Nếu user nhập area path nhưng không chắc đúng → vẫn lưu nguyên văn, không tự validate qua MCP (tránh fail khi node chưa tồn tại). Validation thực tế sẽ xảy ra lúc `/ado-create` tạo ticket.
- Field nào để trống → bỏ key tương ứng trong YAML, không ghi `area_path: null`.

Nếu user chọn **"Bỏ qua"** → không thêm `area_path`/`iteration_path` vào config.

---

### Bước 6: Cấu hình môi trường

**Bắt buộc** hỏi user bằng `AskUserQuestion` — không cho phép bỏ qua:

```
question: "Project này có bao nhiêu môi trường deploy?"
options:
  - label: "Production only"
    description: "1 môi trường: prod"
  - label: "Development + Production"
    description: "2 môi trường: dev + prod"
  - label: "Development + Staging + Production"
    description: "3 môi trường: dev + stag + prod"
```

Lưu kết quả dưới dạng array theo thứ tự từ thấp đến cao:

| Lựa chọn | Giá trị lưu |
|---|---|
| Production only | `["prod"]` |
| Development + Production | `["dev", "prod"]` |
| Development + Staging + Production | `["dev", "stag", "prod"]` |

Nếu user chọn "Other" (nhập tay) → parse chuỗi nhập vào (phân cách bởi dấu phẩy, space, hoặc `+`) → normalize thành lowercase array. Ví dụ: `"dev, staging, prod"` → `["dev", "staging", "prod"]`.

---

### Bước 7: Preview và xác nhận

Hiển thị preview YAML sẽ được ghi — **chưa ghi file**:

```
Sẽ ghi vào .claude/ado.yaml:

organization: torus-engineering
project_name: Galaxy GCC
project_code: GAL-GCC
project_id: "2074c422-31ea-4b9c-9b61-fe0f749fa28d"

team:
  PE:
    - anh.le@atstechnology.vn
    - minh.ngo@atstechnology.vn
  SE:
    - b@atstechnology.vn
    - c@atstechnology.vn
  DE:
    - d@atstechnology.vn

area_path: 'Tickets\Clients\C-GAL\P-GCC'
iteration_path: 'Tickets\Weekly Sprint'

epic:
  id: 42
  title: "[GAL-GCC] Spec Lite Kit"
  url: "https://dev.azure.com/torus-engineering/Galaxy GCC/_workitems/edit/42"

environments:
  - dev
  - stag
  - prod

Xác nhận ghi file? (yes/no)
```

Nếu user yêu cầu chỉnh sửa → cập nhật preview → hỏi lại.

Nếu user bỏ qua bước Epic (không muốn cấu hình ngay) → bỏ qua key `epic` trong YAML, không ghi `epic: null`.

Nếu user bỏ qua Area/Iteration (Bước 5) → bỏ qua key `area_path`/`iteration_path` tương ứng, không ghi giá trị `null`.

**Bước 6 (môi trường) là bắt buộc** — không cho phép bỏ qua. Nếu user chưa chọn, nhắc lại trước khi tiếp tục.

---

### Bước 8: Ghi file

Ghi nội dung đã confirm vào `.claude/ado.yaml`.

**Kiểm tra .gitignore:**

Đọc `.gitignore` ở root project (nếu tồn tại). Nếu có pattern nào match `.claude/ado.yaml` hoặc `.claude/` → **xóa hoặc thêm exception** để đảm bảo file được track bởi git:

- Nếu `.gitignore` có dòng `.claude/` → thêm dòng `!.claude/ado.yaml` ngay bên dưới
- Nếu `.gitignore` có dòng `.claude/ado.yaml` → xóa dòng đó

Thông báo kết quả:

```
✓ .claude/ado.yaml đã được tạo/cập nhật

{nếu có thay đổi .gitignore}
✓ .gitignore — đã đảm bảo .claude/ado.yaml được track bởi git

Bước tiếp theo:
  - Commit .claude/ado.yaml để share config với team
  - /ado-init → khởi tạo ADO project (tạo boards, iteration, areas...)
```

---

## Verification

Trước khi ghi file, kiểm tra:

- [ ] `organization` đã được extract — chỉ là tên org, không phải full URL
- [ ] `project_name` đã được lưu từ kết quả MCP (tên project gốc từ ADO)
- [ ] `project_id` có dạng GUID (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
- [ ] Mỗi email hợp lệ (có dấu `@`)
- [ ] `team.PE` có ít nhất 1 email — không được để trống
- [ ] SE và DE có thể là array rỗng `[]`
- [ ] Nếu có Epic: `epic.id` là số nguyên, `epic.title` có prefix `[{project_code}]`, `epic.url` là full URL dạng `https://dev.azure.com/{org}/{project_name}/_workitems/edit/{id}`
- [ ] Nếu có `area_path` / `iteration_path`: là chuỗi đã trim, giữ nguyên dấu `\` (dùng YAML single-quote để tránh escape); bỏ qua key nếu user không nhập — không ghi `null`
- [ ] `environments` là array ít nhất 1 phần tử (bắt buộc), mỗi phần tử là lowercase string không có khoảng trắng, luôn có `prod` ở cuối
- [ ] User đã confirm preview trước khi ghi file
