---
name: review-everything
description: Review toàn bộ codebase ở cấp project (không phải per-integration) theo năm trục của code-review-and-quality. Đối chiếu implementation với prd.md, domain.md, sad.md. Sau khi user chọn severity cần xử lý, gom findings thành raw requirement và invoke /spec-new để tạo integration fix.
---

# Review Everything

## Tổng quan

`/review-everything` review toàn bộ codebase ở **project level** — không bị giới hạn ở diff của một integration.

Khác với `/review-integration` (chạy sau `/build`, đối chiếu với spec.md / tech.md của integration hiện tại), `/review-everything` đứng cao hơn:

- **Context** = main artifacts: `prd.md` (NFRs, Constraints, Component Index, Feature Index), `domain.md` (Glossary, Shared Entities), `sad.md` (Tech Stack, Cross-Cutting, **Architectural Guardrails**).
- **Scope** = toàn bộ source code, không filter theo branch diff.
- **Output** = findings table phân loại theo severity của `code-review-and-quality`.
- **Hand-off** = nếu user chọn fix → gom selected findings thành raw requirement → invoke `/spec-new` để tạo integration mới và xử lý như integration bình thường.

## When to Use

- Health-check định kỳ codebase (sau cột mốc, trước release lớn).
- Audit khi onboard owner mới hoặc trước cross-team review.
- Phát hiện tech debt / vi phạm guardrails đã tích luỹ qua nhiều integration.

## When NOT to Use

- Vừa hoàn thành một integration cụ thể → dùng `/review-integration` (diff-based, đối chiếu spec.md/tech.md).
- `prd.md` / `domain.md` / `sad.md` chưa có nội dung → review sẽ thiếu chuẩn để đối chiếu. Chạy `/spec-prd` → `/spec-sad` (hoặc `/spec-brownfield-init`) trước.

---

## Process

### Bước 1: Validate prerequisites

Kiểm tra các file sau tồn tại và **có nội dung** (không phải template rỗng):

- `.specs/main/prd.md`
- `.specs/main/domain.md`
- `.specs/main/sad.md`

Nếu thiếu hoặc rỗng → dừng:

> Main artifacts chưa sẵn sàng. Hãy chạy `/spec-prd` và `/spec-sad` (greenfield) hoặc `/spec-brownfield-init` (brownfield) trước.

---

### Bước 2: Load context một lần

Đọc đầy đủ:

- `prd.md` — Problem, Target Users, Scope, **NFRs**, Business Constraints, **Component Index**, **Feature Index**
- `domain.md` — Glossary, Shared Entities (owner, fields)
- `sad.md` — Architectural Style, Tech Stack, Cross-Cutting Concerns, Inter-Service Communication, Infrastructure, **Architectural Guardrails**

Liệt kê source code roots cần review (mặc định cả repo, trừ thư mục node_modules / dist / build / .claude / specs / .git và các thư mục test fixtures).

Tóm tắt cho user trước khi spawn agents:

```
CONTEXT
- Components (từ prd.md): C-001 …, C-002 …
- Guardrails từ sad.md: {top 3-5 guardrail quan trọng}
- NFRs từ prd.md: {liệt kê}

SOURCE SCOPE
- Roots: src/, packages/api/, …
- Excluded: node_modules/, dist/, .claude/, .specs/

Tiếp tục review? (y/n)
```

Chỉ tiến hành Bước 3 sau khi user xác nhận.

---

### Bước 3: Spawn 5 review subagents — parallel theo axis

Cùng context, khác axis. Mỗi subagent (`subagent_type: Explore`) nhận:

- Cùng tóm tắt prd / domain / sad (đặc biệt Guardrails + NFRs liên quan).
- Source roots cần đọc.
- **Một** axis của `code-review-and-quality` cần focus.
- Yêu cầu output format chuẩn (xem dưới).

Spawn **trong cùng một message** (5 Agent tool calls song song):

| Axis | Tập trung vào |
| --- | --- |
| **Correctness** | Edge cases, error paths, off-by-one, race conditions, mismatch giữa code và acceptance/business rule trong frd/crd. |
| **Readability** | Naming, control flow, abstraction quá sớm, code chết, độ dài quá mức cần thiết. |
| **Architecture** | Tuân thủ guardrails trong sad.md, module boundaries, circular dependencies, vi phạm Component Index. |
| **Security** | Input validation, secrets in code, auth checks, injection, untrusted external data. Tham chiếu `security-and-hardening`. |
| **Performance** | N+1, unbounded loops, missing pagination, hot-path allocations. Tham chiếu `performance-optimization`. |

**Prompt template cho mỗi subagent:**

```
Review toàn bộ codebase tại {repo path} chỉ theo trục {AXIS}.

CONTEXT (đối chiếu code với những thứ sau):
- prd.md: {tóm tắt NFRs, Component Index, Feature Index}
- domain.md: {Glossary terms, Shared Entities}
- sad.md: {Architectural Guardrails, Tech Stack quan trọng}

YÊU CẦU:
1. Đọc các source root sau (đệ quy, bỏ excluded): {roots}
2. Chỉ tìm vấn đề thuộc trục {AXIS} — KHÔNG flag vấn đề thuộc trục khác.
3. Mỗi finding gán severity theo scale của code-review-and-quality:
   - Critical — blocks merge (security vuln, data loss, broken core function)
   - Required (no prefix) — must fix before merge
   - Optional / Consider — worth considering, not required
   - Nit — minor formatting/style
   - FYI — informational only
4. Trả output đúng format YAML dưới đây, không thêm narrative:

findings:
  - id: {AXIS}-001
    severity: Critical | Required | Optional | Nit | FYI
    title: {tên ngắn gọn, bắt đầu bằng động từ}
    file: {path:line hoặc path}
    detail: {2-3 dòng — vấn đề gì, đối chiếu với context nào}
    suggestion: {hướng fix ngắn gọn}
  - id: {AXIS}-002
    ...

Nếu không có finding nào ở trục này → trả `findings: []`.
```

Subagent chỉ đọc code, không sửa. Trả về YAML structured findings.

---

### Bước 4: Aggregate findings

Gom findings từ 5 subagent vào một bảng duy nhất, sắp theo severity giảm dần rồi theo axis:

```
FINDINGS — {N} total

| ID            | Severity | Axis         | File                    | Title                       |
|---------------|----------|--------------|-------------------------|-----------------------------|
| SEC-001       | Critical | Security     | src/auth/login.ts:42    | Fix SQL injection in …      |
| ARCH-001      | Critical | Architecture | src/modules/billing/…   | Remove circular dep with …  |
| CORR-001      | Required | Correctness  | src/orders/create.ts:88 | Handle empty cart case      |
| PERF-001      | Required | Performance  | src/api/users.ts:120    | Replace N+1 with batch fetch|
| READ-001      | Optional | Readability  | src/utils/parse.ts:15   | Rename `tmp` → `payload`    |
| READ-002      | Nit      | Readability  | …                       | …                           |
| SEC-003       | FYI      | Security     | …                       | …                           |

Tổng: {C} Critical · {R} Required · {O} Optional · {N} Nit · {F} FYI
```

Hiển thị toàn bộ bảng cho user. Mỗi finding giữ nguyên `id` do subagent gán (prefix theo axis: CORR, READ, ARCH, SEC, PERF) — đây là handle để reference trong spec.md sau này.

---

### Bước 5: Hỏi user severity tier muốn xử lý

Dùng `AskUserQuestion`:

```
question: "Xử lý findings ở mức nào?"
header: "Severity tier"
options:
  - label: "Chỉ Critical"
    description: "Chỉ fix {C} findings blocking. Bỏ qua phần còn lại."
  - label: "Critical + Required"
    description: "Fix tất cả {C+R} findings must-fix theo code-review-and-quality."
  - label: "Critical + Required + Optional"
    description: "Bao gồm cả Optional/Consider (worth-considering)."
  - label: "Tất cả (kèm Nit + FYI)"
    description: "Fix toàn bộ {N} findings — kể cả nit và FYI."
  - label: "Bỏ qua — chỉ xem findings"
    description: "Không tạo integration. Findings vẫn được lưu nếu cần tham chiếu sau."
```

Nếu user chọn "Bỏ qua" → ghi findings ra `.specs/main/review/{YYYY-MM-DD-HHmm}.md` (tạo thư mục nếu chưa có) rồi dừng.

Nếu user chọn một tier → tiếp Bước 6.

---

### Bước 6: Gom selected findings → raw requirement cho /spec-new

Filter findings theo tier đã chọn (tier cao hơn = tập con nhỏ hơn, ví dụ "Chỉ Critical" → chỉ giữ severity=Critical).

Sinh **raw requirement** (string đưa làm ARGUMENT cho `/spec-new`):

```
Fix project-level review findings — {YYYY-MM-DD} review.

Selected severity tier: {tier label} → {K} findings.

Findings to address:
- [SEC-001] Critical · Security · src/auth/login.ts:42 — Fix SQL injection in user lookup
- [ARCH-001] Critical · Architecture · src/modules/billing/* — Remove circular dependency with payments module
- [CORR-001] Required · Correctness · src/orders/create.ts:88 — Handle empty cart case
- …

Acceptance: mỗi finding ở trên có hành động fix tương ứng + verification (test hoặc manual check).
Đầy đủ detail/suggestion xem `review-findings.md` trong cùng thư mục integration.
```

---

### Bước 7: Invoke /spec-new với raw requirement

Gọi `Skill` tool: `skill=spec-new`, `args={raw requirement ở Bước 6}`.

`/spec-new` sẽ:
1. Nhận ARGUMENT làm raw requirement (bỏ qua nhánh "chọn từ prd.md").
2. Load context (prd / domain / frd / crd liên quan).
3. Interview 4 phần (Problem Statement, Requirements, Acceptance Criteria, Out of Scope) — agent **gợi ý sẵn** dựa trên findings, user chỉnh.
4. Sinh `.specs/integrations/{NNN}-{slug}/spec.md` + cascade lên main artifacts.

**Khi `/spec-new` đề xuất slug**, gợi ý mặc định:
- `review-{YYYY-MM-DD}` — ngắn, có ngày để truy ngược review nào.
- User có quyền sửa.

---

### Bước 8: Sau khi /spec-new tạo xong integration → lưu findings file

`/spec-new` ghi `.specs/integrations/{NNN}-{slug}/spec.md`. Đọc lại path đó để biết `{NNN}-{slug}`.

Ghi **toàn bộ findings** (không chỉ selected — giữ full để tham chiếu sau) vào:

```
.specs/integrations/{NNN}-{slug}/review-findings.md
```

Nội dung:

```markdown
---
slug: {NNN}-{slug}
created: {YYYY-MM-DD HH:mm}
total_findings: {N}
selected_tier: {tier label}
---

# Review Findings — {YYYY-MM-DD}

Project-level review chạy bởi `/review-everything`.

## Summary

| Severity | Count | Selected for fix |
|---|---|---|
| Critical | {c} | {✓ nếu tier bao gồm} |
| Required | {r} | … |
| Optional | {o} | … |
| Nit | {n} | … |
| FYI | {f} | … |

## Selected for fix in this integration

{Bảng findings được chọn, đầy đủ id / severity / axis / file / title / detail / suggestion}

## Deferred (not in this integration)

{Bảng findings KHÔNG được chọn — để tham chiếu cho lần review/integration sau}
```

Thông báo:

```
✓ /review-everything hoàn tất.

  Findings: {N} total ({C} Critical · {R} Required · {O} Optional · {Ni} Nit · {F} FYI)
  Selected: {tier} → {K} findings
  Integration: .specs/integrations/{NNN}-{slug}/
    ├── spec.md            (đã tạo bởi /spec-new + cascade)
    └── review-findings.md (full snapshot)

Bước tiếp theo:
  - /spec-tech {NNN} → thiết kế technical design cho phase fix
  - /plan → phân rã tasks
  - /build → implement
```

---

## Mối quan hệ với các skill khác

| Skill | Quan hệ |
| --- | --- |
| `code-review-and-quality` | **Delegated** — 5 subagent áp axis của skill này lên codebase. Severity scale dùng nguyên scheme của skill. |
| `security-and-hardening` | Subagent Security tham chiếu khi đánh giá. |
| `performance-optimization` | Subagent Performance tham chiếu khi đánh giá. |
| `spec-new` | **Auto-invoked ở Bước 7** với ARGUMENT là raw requirement gom từ findings. Toàn bộ flow sau đó giống integration bình thường. |
| `review-integration` | Khác scope — `/review-integration` chạy sau `/build` cho **một** integration, đối chiếu spec.md/tech.md. `/review-everything` chạy project-level, đối chiếu prd/domain/sad. |

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Code chạy ổn, không cần review project-level" | Drift tích luỹ qua nhiều integration không bị diff-based review bắt được (ví dụ vi phạm guardrail mới thêm vào sad.md sau khi code đã viết). |
| "Tier Critical-only là đủ rồi" | Required findings cũng phải fix trước merge theo định nghĩa của code-review-and-quality. Critical-only nên chỉ dùng khi có hạn về effort. |
| "Bỏ qua Optional/Nit cho nhanh" | Hợp lệ. Optional/Nit có thể defer — nhưng đừng để chúng biến mất khỏi history. Findings file vẫn ghi đầy đủ để lần sau pickup. |

## Red Flags

- Spawn 1 subagent cho cả 5 axis → context blowup, findings sót.
- Filter selected findings nhưng không lưu **full** snapshot vào `review-findings.md` → mất traceability.
- Skip Bước 1 (validate prerequisites) → review không có chuẩn để đối chiếu, findings sẽ thiên về subjective.
- Tạo spec.md trực tiếp thay vì invoke `/spec-new` → duplicate logic, không cascade lên main artifacts.

## Verification

Trước khi spawn subagents:
- [ ] `prd.md`, `domain.md`, `sad.md` đã có nội dung
- [ ] Đã tóm tắt context + source roots cho user và user xác nhận

Sau khi aggregate findings:
- [ ] Findings được phân loại đúng theo severity scale của `code-review-and-quality`
- [ ] Mỗi finding có `id` (prefix theo axis), `file`, `title`, `detail`, `suggestion`
- [ ] Bảng tổng đếm đúng từng severity

Sau khi user chọn tier:
- [ ] Raw requirement build từ chỉ selected findings
- [ ] `/spec-new` được invoke với ARGUMENT chứa raw requirement
- [ ] Sau khi `/spec-new` xong → `review-findings.md` ghi **full** findings (selected + deferred) vào integration directory
