---
name: scaffold
description: Khởi tạo project scaffold dựa trên sad.md — tạo plan.md và todo.md rồi thực thi theo plan. Chạy một lần duy nhất trước khi implement integration đầu tiên.
---

# scaffold

## Overview

Đọc `.specs/main/sad.md`, phân rã thành plan.md và todo.md cho bước khởi tạo project, sau đó thực thi từng task theo thứ tự.

Khác với `/plan` — skill này không dừng lại sau khi sinh plan. Sau khi user confirm, nó execute luôn.

## When to Use

- Project chưa được khởi tạo
- Muốn có một record rõ ràng về cách project được setup

## When NOT to Use

- `.specs/main/sad.md` chưa có → chạy `/spec-sad` trước
- Project đã được khởi tạo rồi → implement trực tiếp

---

## Process

### Bước 1: Kiểm tra preconditions

Đọc `.specs/main/sad.md`:

- **Không tồn tại hoặc là template** → dừng ngay:
  > `sad.md` chưa có nội dung. Hãy chạy `/spec-sad` trước.

- **Đã có nội dung** → tiếp tục.

Kiểm tra `.specs/integrations/000-scaffold/`:

- **Không có plan.md và todo.md** → tiếp tục Bước 2 (sinh mới).

- **Có plan.md nhưng không có todo.md** → hỏi:
  > `plan.md` đã tồn tại nhưng thiếu `todo.md`. Ghi đè và chạy lại từ đầu?

- **Có cả plan.md và todo.md** → đọc todo.md, đếm tasks:
  - Nếu **tất cả tasks đã `[x]`** → thông báo:
    > Scaffold đã hoàn thành ({N}/{N} tasks). Muốn chạy lại từ đầu?
    - Nếu user muốn chạy lại → tiếp tục Bước 2.
    - Nếu không → dừng.
  - Nếu **có tasks chưa done** → hiển thị tiến độ:
    ```
    Scaffold đang ở giữa chừng ({done}/{total} tasks done):
      ✓ T001 · {task title}
      ✓ T002 · {task title}
      ○ T003 · {task title}   ← chưa làm
      ○ T004 · {task title}
    
    Tiếp tục từ T003?
    ```
    - Nếu user confirm → **nhảy thẳng đến Bước 6**, bắt đầu từ task đầu tiên chưa `[x]`.
    - Nếu user muốn chạy lại → tiếp tục Bước 2.

---

### Bước 2: Load context từ sad.md

Extract các thông tin cần thiết để sinh plan:

- **Tech Stack** — từng layer và technology
- **Infrastructure Overview** — môi trường, provider, deployment strategy
- **Architectural Guardrails** — các constraints ảnh hưởng đến project setup

Surface context và hỏi những gì sad.md không có:

```
TỪ SAD.MD TÔI HIỂU:
- Framework: {tech stack}
- Database: {tech stack}
- Deploy: {infrastructure}
- Guardrails liên quan đến scaffold: {list GUARD IDs}

CẦN THÊM:
1. Project name là gì?
2. Package manager? (npm / pnpm / yarn) [default: npm]
→ Sửa lại nếu sai trước khi tiếp tục.
```

Chỉ hỏi những gì thực sự không thể suy ra từ sad.md.

---

### Bước 3: Sinh plan.md và todo.md

Phân rã scaffold thành tasks có thứ tự. Mỗi task phải:
- Thực thi được bởi agent (chạy command hoặc tạo file)
- Có verification rõ ràng trước khi mark done
- Phụ thuộc đúng thứ tự

**Dependency graph điển hình cho scaffold:**

```
    Verify (project chạy được)
           │
    Directory structure
           │
    Config & env vars ──── ORM init
           │
    Install dependencies
           │
    Initialize framework
```

**Phases điển hình** (điều chỉnh theo tech stack thực tế):

- **Phase 1: Initialize** — khởi tạo project framework (create-next-app, create-vite, django-admin startproject, v.v.)
- **Phase 2: Dependencies** — cài packages theo tech stack và guardrails
- **Phase 3: Configuration** — init ORM, setup env file template, config files
- **Phase 4: Directory Structure** — tạo thư mục theo layer architecture trong sad.md
- **Phase 5: Verify** — project chạy được, kết nối DB thành công

**Output format** (theo plan convention):

```markdown
---
id: "000-scaffold"
slug: "000-scaffold"
title: "Project Scaffold — Setup Plan"
status: draft
created: {YYYY-MM-DD}
---

## Summary

{2-3 câu mô tả những gì sẽ được khởi tạo, dựa trên tech stack từ sad.md}

## Dependency Graph

{ASCII diagram — bottom = foundations, top = verify}

## Tasks

### Phase 1: Initialize

#### T001 · {task title — starts with a verb}

**Mục tiêu:** {One sentence: task này deliver gì}

**depends:** —

**Các bước:**
1. {Command hoặc action cụ thể}
2. {Command hoặc action cụ thể}

**Verification:**
- [ ] {Kết quả quan sát được sau khi task hoàn thành}

---

...

### Phase N: Verify

#### T00N · Verify scaffold hoạt động

**Mục tiêu:** Xác nhận project chạy được và mọi connections hoạt động.

**depends:** T001, T002, ...

**Các bước:**
1. Chạy dev server
2. Verify kết nối database (nếu có)

**Verification:**
- [ ] Dev server start không lỗi
- [ ] {DB connection verify nếu applicable}

---

## Definition of Done

- [ ] Project khởi chạy thành công ở local
- [ ] Tất cả dependencies đã được install
- [ ] Directory structure khớp với architecture trong sad.md
- [ ] Env template có đủ variables cần thiết
```

**todo.md format:**

```markdown
# Project Scaffold — Todo

### Phase 1: Initialize
- [ ] T001 · {task title}

### Phase 2: Dependencies
- [ ] T002 · {task title}

...

### Phase N: Verify
- [ ] T00N · Verify scaffold hoạt động
```

Hiển thị draft cho user — **chưa ghi file**.

---

### Bước 4: Review — xác nhận với user

> Draft trên đúng chưa? Confirm để ghi file và bắt đầu thực thi.

Chỉ tiếp tục sau khi user confirm. Nếu cần chỉnh → cập nhật draft → hỏi lại.

---

### Bước 5: Ghi file

Tạo thư mục `.specs/integrations/000-scaffold/` nếu chưa có.

Ghi:
- `.specs/integrations/000-scaffold/plan.md`
- `.specs/integrations/000-scaffold/todo.md`

---

### Bước 6: Thực thi plan

Thực thi từng task theo thứ tự trong plan.md:

```
Bắt đầu thực thi scaffold...

[T001] {task title}
  → {action}
  ✓ Verification passed
  ✓ todo.md updated

[T002] {task title}
  → {action}
  ✓ Verification passed
  ✓ todo.md updated

...
```

**Rules:**

1. Thực thi đúng thứ tự — không skip task, không parallelize trừ khi `depends` cho phép
2. Sau mỗi task: chạy verification steps trong `**Verification:**`
3. Nếu verification pass → mark `[x]` trong todo.md → tiếp tục task tiếp theo
4. Nếu verification fail → dừng ngay, báo lỗi cụ thể, không tiếp tục:

```
✗ T002 · {task title} — FAILED

Lỗi: {error message}
Bước đã thực thi: {bước số mấy}

Cần xử lý thủ công trước khi tiếp tục.
```

5. Không tự ý bỏ qua lỗi hoặc retry quá 1 lần

---

### Bước 7: Hoàn thành

Sau khi tất cả tasks pass:

```
✓ Scaffold hoàn thành

  .specs/integrations/000-scaffold/plan.md
  .specs/integrations/000-scaffold/todo.md

Tất cả tasks: {N}/{N} ✓

Bước tiếp theo:
  - Điền các giá trị thực vào .env.local
  {nếu có manual steps} - {manual step cần làm}
  - /spec-new → bắt đầu integration đầu tiên
```

---

## Verification

Trước khi kết thúc, kiểm tra:

- [ ] sad.md đã được đọc và tech stack được extract đúng
- [ ] plan.md có Dependency Graph
- [ ] Mỗi task có: Mục tiêu / depends / Các bước / Verification
- [ ] todo.md đồng bộ với plan.md
- [ ] User đã confirm plan trước khi execute
- [ ] Mọi task verification pass trước khi mark done
