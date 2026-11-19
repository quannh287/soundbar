---
name: spec-brownfield-init
description: Khởi tạo main artifacts (prd.md, domain.md, sad.md) cho brownfield project bằng cách scan codebase và interview với pre-filled options. Dùng khi onboarding một project đã chạy vào SDD workflow.
---

# spec-brownfield-init

## Overview

Tạo `.specs/main/prd.md`, `.specs/main/domain.md`, và `.specs/main/sad.md` cho một project đã tồn tại.

Skill này chỉ tập trung vào **product và architecture level** — những gì có thể extract từ README, docs, config, và kiến trúc tổng thể. Component Index và Feature Index trong prd.md sẽ **để trống** — chúng sẽ được điền bởi `/spec-brownfield-component` và `/spec-brownfield-feature` sau khi scan code chuyên sâu.

## Templates

Mỗi file output được sinh ra từ template tương ứng — đọc template trước khi điền nội dung:

| Output file | Template |
| --- | --- |
| `.specs/main/prd.md` | `templates/main/prd-template.md` |
| `.specs/main/domain.md` | `templates/main/domain-template.md` |
| `.specs/main/sad.md` | `templates/main/sad-template.md` |

Giữ nguyên cấu trúc section và frontmatter từ template. Điền nội dung thu thập được từ scan và interview vào đúng vị trí.

Thông tin không thể detect từ code được đánh dấu nhất quán:

```
**[NEEDS_CLARIFY]** <mô tả điều chưa rõ và câu hỏi cần trả lời>
```

## When to Use

- Onboarding một brownfield project vào SDD workflow
- `.specs/main/prd.md` chưa có hoặc còn trống

## When NOT to Use

- Greenfield project chưa có code → dùng `/spec-prd` + `/spec-sad`
- `prd.md` đã có nội dung đầy đủ → dùng `/spec-prd` hoặc `/spec-sad` để update từng phần

---

## Process

### Bước 1: Xác định target path và load attachments

**Path:**
- Nếu có ARGUMENT là path → đây là root của project cần scan.
- Nếu không có → mặc định dùng current working directory.

Thông báo: `Sẽ scan: {path}`

**Attachments:**
Hỏi ngay đầu — không hỏi lại sau:

> Bạn có tài liệu bổ sung nào không? (README, API spec, wiki, ADR, existing docs)
> Paste nội dung hoặc cung cấp file path. Nhập `không` để bỏ qua.

Load tất cả attachments trước khi scan. Dùng làm context bổ sung trong mọi bước tiếp theo.

---

### Bước 2: Kiểm tra existing specs

Kiểm tra `.specs/main/prd.md`, `.specs/main/domain.md`, `.specs/main/sad.md`:

Nếu một trong ba đã có nội dung thực → cảnh báo:

```
⚠ File đã có nội dung:
  - .specs/main/prd.md
  - .specs/main/sad.md

Skill này sẽ overwrite các file trên. Tiếp tục? [y/n]
```

Nếu user chọn `n` → dừng.

---

### Bước 3: Scan codebase

Scan tuần tự. **Không hỏi user trong bước này** — chỉ thu thập thông tin.

**3a. Package & tech stack:**
Đọc (nếu tồn tại): `package.json`, `yarn.lock`, `pnpm-lock.yaml`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `composer.json`, `Gemfile`, `pubspec.yaml`

Extract: ngôn ngữ, framework chính, major dependencies, build/test scripts.

**3b. README và existing docs:**
Đọc (nếu tồn tại): `README.md`, `README.*`, `docs/`, `ARCHITECTURE.md`, `DESIGN.md`

Extract: mô tả project, target users được nhắc đến, business context.

**3c. Directory structure — top level:**
List 1-2 levels từ root — không đọc nội dung file source.

Detect: architecture pattern (monolith / microservices / monorepo). Không cần lấy tên từng module — đó là việc của `/spec-brownfield-component`.

**3d. Auth & middleware:**
Tìm files liên quan: auth, middleware, interceptor, guard, rate-limit, logging config.

Infer: auth strategy, cross-cutting patterns đang dùng.

**3e. Infrastructure:**
Đọc (nếu tồn tại): `docker-compose.yml`, `Dockerfile`, `.github/workflows/`, `k8s/`, `terraform/`, `serverless.yml`, `.env.example`

Extract: deployment target, số services (để confirm architecture pattern), số môi trường.

---

### Bước 4: Tóm tắt scan và xác nhận tiếp tục

```
SCAN RESULTS — {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tech stack:    {e.g. TypeScript / NestJS / PostgreSQL / Redis}
Architecture:  {e.g. Modular Monolith}
Auth pattern:  {e.g. JWT Bearer / Session / không detect được}
Docs loaded:   {list files đọc được}

Tiếp tục với brownfield init? [y/n]
```

Nếu `n` → dừng.

---

### Bước 5: Interview — prd.md

Hỏi tuần tự từng phần. Mỗi câu hỏi có options pre-filled từ scan. Luôn có `[0] Chưa rõ → NEEDS_CLARIFY`. Khi user chọn `[0]` → đánh dấu và tiếp tục, không dừng lại.

**Phần 1 — Problem Statement:**

```
❓ Hệ thống này giải quyết vấn đề gì?
  [1] {Trích từ README: "..."}
  [2] Nhập mô tả khác
  [0] Chưa rõ → NEEDS_CLARIFY
```

**Phần 2 — Target Users:**

```
❓ Ai là người dùng chính?
  [1] {Detected từ auth guards / README: e.g. "admin, user, guest"}
  [2] Nhập personas khác
  [0] Chưa rõ → NEEDS_CLARIFY
```

Nếu user chọn [1] → hỏi thêm một câu: "Bạn muốn mô tả thêm mục tiêu / pain point cho từng role không? [y/n]"

**Phần 3 — Scope:**

```
❓ In scope — những gì hệ thống có:
  [1] {Infer từ README/docs: "..."}
  [2] Nhập danh sách khác
  [0] Chưa rõ → NEEDS_CLARIFY

❓ Out of scope — những gì hệ thống KHÔNG làm:
  [1] Nhập nội dung
  [0] Chưa rõ → NEEDS_CLARIFY
```

**Phần 4 — NFRs:**

```
❓ Non-Functional Requirements:
  Detected từ config / code:
    {e.g. Rate limit: 100 req/min (từ rate-limit config)}
    {e.g. DB pool: max 10 connections (từ DB config)}

  Có thêm NFR nào không? (performance targets, availability SLA, security compliance, scalability)
  [1] Dùng detected + nhập thêm nếu có
  [2] Nhập lại từ đầu
  [0] Chưa rõ → NEEDS_CLARIFY tất cả
```

**Phần 5 — Business Constraints:**

```
❓ Business constraints và assumptions:
  (deadline, budget, compliance, vendor lock-in, team constraints)
  [1] Nhập nội dung
  [0] Chưa rõ → NEEDS_CLARIFY
```

**Lưu ý:** prd.md sẽ có Component Index và Feature Index **để trống** với placeholder. Chúng sẽ được điền bởi `/spec-brownfield-component` và `/spec-brownfield-feature`.

---

### Bước 6: Tạo domain.md — Glossary

domain.md ở bước này chỉ có **Glossary** — Shared Entities để trống, sẽ được mọc qua cascade proposals từ `/spec-brownfield-component` khi nó phát hiện cross-component entities.

Extract glossary terms từ: README/docs (business terms được nhắc đến), tên các key concepts trong problem statement vừa thu thập.

Hỏi:
```
❓ Glossary terms cần define:
  Tôi nhận diện được các terms sau từ docs:
    - {term 1}: {định nghĩa inferred hoặc NEEDS_CLARIFY}
    - {term 2}: {định nghĩa inferred hoặc NEEDS_CLARIFY}

  [1] Dùng list này — có thể thêm/sửa/xóa
  [2] Nhập danh sách mới
  [0] Chưa rõ / bỏ qua → để trống, điền sau
```

---

### Bước 7: Auto-generate — sad.md

Phần lớn auto từ scan. Chỉ hỏi 2 câu.

**7a. Auto-fill từ scan:**
- Tech stack: từ package files
- Architecture style: infer từ directory structure top-level + docker-compose
- Cross-cutting concerns: infer từ middleware / interceptors / guards detected
- Inter-service communication: infer từ message queue / HTTP client usage
- Infrastructure: infer từ docker-compose, cloud configs

**7b. Hỏi Guardrails:**

```
❓ Architectural Guardrails:
  Dựa trên {stack}, tôi đề xuất:
    GUARD-001: {rule cụ thể}
    GUARD-002: {rule cụ thể}
    ...

  [1] Dùng set này — có thể thêm/bớt
  [2] Nhập guardrails khác
  [0] Chưa rõ → NEEDS_CLARIFY tất cả
```

**7c. Hỏi architectural decisions (→ ADR Log):**

```
❓ Có architectural decision nào quan trọng chưa detect được không?
  (patterns bắt buộc dùng, patterns bị cấm, third-party services phải dùng)
  [1] Nhập thêm
  [0] Không có thêm
```

Điền **ADR Log**: tạo ADR entry (status `accepted`) cho mỗi quyết định lớn — gồm cả các quyết định infer được ở 7a (architecture style, tech stack chính, communication) lẫn câu trả lời 7c. Mỗi entry ghi context/rationale + consequences ở mức suy luận được từ code; chỗ không chắc → NEEDS_CLARIFY.

---

### Bước 8: Review drafts

Hiển thị draft từng file lần lượt. Với mỗi file:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DRAFT: .specs/main/{file}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{nội dung draft}

[NEEDS_CLARIFY trong file này: {count} items]

Confirm? [y] Bỏ qua [n] Chỉnh sửa [e]:
```

- `y` → ghi file, chuyển sang file tiếp theo
- `n` → bỏ qua file này
- `e` → hỏi chỉnh sửa cụ thể, show lại draft, hỏi confirm lần nữa

---

### Bước 9: Save

Tạo `.specs/main/` nếu chưa có. Ghi các files đã được confirm. Frontmatter mỗi file (`prd.md`/`domain.md`/`sad.md`) lấy `template_version` từ template tương ứng (xem `01-architecture.md` §12).

**Bump `id_counters`:** trong frontmatter mỗi file vừa ghi, set counter cho ID đã cấp: `prd` → `feature`/`component` (theo Index đã điền), `domain` → `entity`, `sad` → `adr`. High-water-mark = seq lớn nhất vừa cấp. KHÔNG ghi Change History (đã bỏ — history = git, `01-architecture.md` §7). Bản ghi scaffold = git commit.

```
✓ .specs/main/prd.md        (Component Index và Feature Index: placeholder — chưa có)
✓ .specs/main/domain.md     (Glossary: {n} terms | Shared Entities: trống — sẽ mọc qua cascade)
✓ .specs/main/sad.md

NEEDS_CLARIFY summary — {total} items cần làm rõ:
  prd.md:    {n} — [Problem Statement, Business Constraints, ...]
  domain.md: {n} — [glossary terms, ...]
  sad.md:    {n} — [guardrails, ...]

Bước tiếp theo:
  /spec-brownfield-component → scan code, generate crd.md + cdd.md, điền Component Index
  /spec-brownfield-feature   → scan code, generate frd.md + fdd.md, điền Feature Index
  (chạy component trước — feature phụ thuộc vào component)
```

---

## NEEDS_CLARIFY Convention

Format chuẩn — dùng nhất quán trong tất cả artifacts:

```markdown
**[NEEDS_CLARIFY]** Mô tả ngắn điều chưa rõ. Câu hỏi cần trả lời để fill in.
```

---

## Verification

- [ ] Scan results đã được hiển thị và user confirm trước khi interview
- [ ] Mọi section có ít nhất một trong ba: nội dung thực / pre-filled option / NEEDS_CLARIFY
- [ ] prd.md có Component Index placeholder (chưa có entries — sẽ điền sau)
- [ ] prd.md có Feature Index placeholder (chưa có entries — sẽ điền sau)
- [ ] domain.md có Glossary (ít nhất skeleton) và Shared Entities trống
- [ ] sad.md có Architectural Guardrails section
- [ ] NEEDS_CLARIFY items được list đầy đủ trong summary cuối
- [ ] User đã confirm từng file trước khi ghi
- [ ] Mỗi file (prd/domain/sad) có `template_version` copy từ template tương ứng
