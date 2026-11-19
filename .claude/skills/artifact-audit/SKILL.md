---
name: artifact-audit
description: Audit MAIN artifacts trong .specs/main/ xem có lỗi thời so với template không (chỉ main artifacts — prd/domain/sad/frd/fdd/crd/cdd; integration artifacts + test-side artifacts dưới .specs/tests/ ngoài scope). So `template_version` của artifact với `template_version` hiện tại đọc thẳng từ template (.claude/templates/). Versioned khớp → up-to-date, lệch → out-dated (in vX → vY). Artifact thiếu version (sinh trước versioning) → đối chiếu structure với template: khớp thì stamp version, lệch thì flag out-dated. KHÔNG tự migrate — chỉ stamp khi chắc chắn khớp + báo cáo. Nhận tùy chọn 1 hay nhiều main type làm scope (vd `frd`, `frd,crd`); không có arg → audit mọi main type.
---

# artifact-audit

## Overview

Trả lời một câu hỏi: **main artifact nào trong `.specs/main/` đã lỗi thời so với template mới nhất?**

> **Scope = chỉ main artifacts** (`prd`, `domain`, `sad`, `frd`, `fdd`, `crd`, `cdd` — đều nằm dưới `.specs/main/`). **Ngoài scope:** (a) Integration artifacts (`spec`, `tech`, `test`, `plan`, `todo`, `techdebt` dưới `.specs/integrations/`) — ephemeral + immutable sau `done`; (b) **Test-side artifacts dưới `.specs/tests/`** (`test-design`, `selector-contract`, `test-exec-*`, `test-report`) — tạm thời **non-versioned** (015 §3B), change history = git. `test-design`/`selector-contract` từng là main artifact versioned nhưng đã dời sang `.specs/tests/` và ra khỏi vòng versioning trong cửa sổ này.

Cơ chế (xem `01-architecture.md` §12 Template Versioning):
- **Nguồn sự thật** = `template_version` trong frontmatter template đang cài (`.claude/templates/...`). Đọc thẳng lúc chạy — không manifest, không cache.
- Mỗi artifact mang `template_version` (copy lúc CREATE bởi skill sinh nó). Audit so số artifact với số template.

Skill này **chỉ phát hiện + stamp legacy**, **KHÔNG migrate**. Việc đưa structure artifact lên format mới là của `/artifact-migrate` (cho mọi main type).

## When to Use

- Sau khi `git pull` kit mới (template có thể đã bump version) → xem artifact nào cần migrate.
- Audit định kỳ một main type cụ thể (`/artifact-audit frd`) hoặc mọi main type (`/artifact-audit`).
- Sau khi bump `template_version` của một template → tìm mọi main artifact giờ thành `out-dated`.
- Onboarding repo cũ → stamp version cho main artifact legacy khớp structure, lọc ra cái cần migrate.

## When NOT to Use

- Muốn **migrate** artifact lên format mới → `/artifact-migrate` (skill này chỉ flag, không sửa structure).
- Muốn đổi **nội dung** artifact → integration changeset (`/spec-new`) hoặc edit tay.
- Chưa cài template vào `.claude/templates/` → skill không có nguồn version để so; dừng.

---

## Type → template map

Type của main artifact resolve theo **filename**. Mỗi type map tới đúng một template:

| Filename | type | Template (`.claude/templates/...`) |
| --- | --- | --- |
| `prd.md` | prd | `main/prd-template.md` |
| `domain.md` | domain | `main/domain-template.md` |
| `sad.md` | sad | `main/sad-template.md` |
| `frd.md` | frd | `main/feature/frd-template.md` |
| `fdd.md` | fdd | `main/feature/fdd-template.md` |
| `crd.md` | crd | `main/component/crd-template.md` |
| `cdd.md` | cdd | `main/component/cdd-template.md` |

**Chỉ main artifacts.** Integration artifacts (`spec`, `tech`, `test`, `plan`, `todo`, `techdebt`) **không** thuộc scope — gặp file integration thì bỏ qua. Test-side artifacts dưới `.specs/tests/` (`test-design`, `selector-contract`, `test-exec-*`, `test-report`) cũng **không** thuộc scope (non-versioned — 015 §3B). File không khớp bảng (vd `notes.md`, `*.bak`) → cũng bỏ qua.

---

## Process

### Bước 0: Resolve scope

- **ARGUMENT là 1 main type hoặc list** (vd `frd`, `frd,crd`) → chỉ audit các type đó. Type lạ hoặc type integration (`spec`/`tech`/`test`/`plan`/`todo`/`techdebt`, không có trong map) → cảnh báo và bỏ qua type đó.
- **Không có ARGUMENT** → audit **mọi** main type trong map.

### Bước 1: Đọc current version của template

Cho mỗi type trong scope, đọc frontmatter template tương ứng tại `.claude/templates/...` → lấy `template_version`.

- Template thiếu field `template_version` → không audit được type đó (chưa versioned ở phía template); cảnh báo, skip type.
- Template không tồn tại tại `.claude/templates/` → báo kit chưa cài đủ; dừng.

Lưu bảng `currentVersion[type]`.

### Bước 2: Discover artifacts

Quét **chỉ** main artifacts trong `.specs/main/**` (prd, domain, sad, và feature/component artifacts).

**Bỏ qua:**
- Toàn bộ `.specs/integrations/**` — integration artifacts ngoài scope skill này (ephemeral + immutable sau `done`; không audit/migrate theo version).
- Toàn bộ `.specs/tests/**` — test-side artifacts (test-design/selector-contract/test-exec-*/test-report) non-versioned (015 §3B), change history = git.
- `.specs/main/feature/*/spec-debt.md` — sổ nợ của BA nằm cạnh `frd.md`, nhật ký do pipeline ghi, không versioned ([`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)). Không khớp type map nên vốn đã bị bỏ — ghi rõ ở đây để không ai thêm nó vào map.
- `.specs/archive/**`, `.specs/removed/**`, file `*.bak.*`, file không khớp type map.

Với mỗi file khớp: resolve type theo filename, đọc frontmatter để lấy `template_version` (có thể thiếu).

### Bước 3: Classify

Cho mỗi artifact:

**3a. Có `template_version`** → so với `currentVersion[type]`:
- `==` → **up-to-date**.
- `!=` → **out-dated** → cần migrate. Ghi `(vX → vY)`.

Version compare bắt **mọi** loại delta của các bump ở giữa — `add` / `remove` / **`update` (format)** — kể cả thay đổi format mà presence-check không thấy được. Số version là tín hiệu tổng.

**3b. Thiếu `template_version`** (unversioned — sinh trước versioning) → chưa kết luận được bằng số. Áp **conformance check** (xem `01-architecture.md` §12 "Conformance model — required-emptyable").

> **Điểm mù:** presence-check chỉ thấy heading có/không → **KHÔNG phát hiện được format-update** (vd section vẫn đó nhưng dùng ASCII diagram thay vì Mermaid). Artifact unversioned đủ heading sẽ bị stamp thành conform dù format cũ. Đây là giới hạn cố hữu của nhánh unversioned (format-update chỉ bắt được qua version compare ở 3a). Chấp nhận vì là edge-case pre-versioning.

**Presence-check, quan hệ BAO HÀM (superset).** Conformance = artifact **chứa đủ mọi heading required** của template (body rỗng OK). Template là skeleton tối thiểu; artifact đã điền luôn chứa nhiều hơn. KHÔNG đòi giống hệt template.
- **Required heading** = các heading **`##`** của template body, TRỪ cái đánh dấu `*(nếu có)*` (conditional). Heading `###` là instance/sub (vd `### US-F{NNN}-001`, `### Flow 1`) → KHÔNG tính. Phân biệt bằng level nên deterministic.

**Hai dấu hiệu out-dated** (artifact tụt sau template) — đọc `remove` từ block `migrations` của template để biết tên section deprecated cần dò:
1. **Thiếu** một required heading mà template hiện tại có.
2. **Còn chứa** một section mà `migrations.remove` ghi đã bỏ (deprecated còn sót).

(Đổi tên section được biểu diễn bằng remove + add ở block `migrations`, nên rơi vào cả 2 dấu hiệu: tên cũ nằm trong `remove` → dấu hiệu 2; tên mới là required heading bị thiếu → dấu hiệu 1.)

**KHÔNG phải out-dated** (authoring bình thường, vẫn **stamp**):
- Artifact **thêm** sub-section / heading con không có trong template (vd dưới `### Feature Acceptance Criteria` có thêm `#### NFR AC`). Required heading vẫn có mặt → conform.
- Body rỗng của một required-emptyable section.
- Thêm nội dung/bảng/ghi chú riêng **không nằm trong `migrations.remove`**; khác thứ tự; số item nhiều/ít hơn ví dụ.

> **Quan trọng — phân biệt dấu hiệu 2 với superset:** section "thừa" (có trong artifact, không trong template) chỉ là out-dated khi tên nó **nằm trong `migrations.remove`** (đã khai báo deprecated). Section thừa **không** được khai báo remove → là content tác giả → **giữ, conform** (superset). Đây là cách removal vẫn detect được bằng presence-check mà không xóa nhầm content.

Kết luận:
- **Conform** (đủ required heading, không dính 1–2) → **stamp** `template_version: <currentVersion>`. Lần audit sau so bằng số.
- **Out-dated** (dính ≥1 trong 1–2) → KHÔNG stamp. Tóm tắt đúng dấu hiệu (thiếu required heading gì / section deprecated nào còn sót) để `/artifact-migrate` xử lý.

> Nguyên tắc thận trọng — chỉ về việc **có stamp hay không**: nếu nghi ngờ một required heading có thực sự thiếu hay không (diễn đạt khác) → flag out-dated thay vì stamp (thà flag thừa còn hơn giấu artifact lỗi thời). **Nội dung thừa không khai báo remove KHÔNG bao giờ là lý do nghi ngờ** — chỉ thiếu-required / deprecated-còn-sót mới tính.

### Bước 4: Confirm trước khi stamp

> **Chế độ classify-only** (khi `/artifact-migrate` gọi audit làm bước phát hiện): **bỏ qua Bước 4–5** — KHÔNG stamp, KHÔNG confirm, chỉ trả phân loại (up-to-date / legacy-conformant / out-dated) cho caller. Mọi ghi (stamp + migrate) do `/artifact-migrate` điều phối trong một luồng confirm duy nhất. Phần dưới chỉ áp dụng khi audit chạy **standalone**.

Nếu Bước 3b có artifact cần stamp → hiển thị danh sách **sẽ stamp** + danh sách **out-dated** trước, xin confirm:

> Sẽ ghi `template_version` vào {N} artifact legacy khớp structure (additive frontmatter change). {M} artifact out-dated sẽ KHÔNG bị đụng. Tiếp tục? [y/n]

`y` → ghi stamp (chỉ thêm field `template_version` vào frontmatter, không đụng nội dung khác). `n` → bỏ qua stamp, vẫn in báo cáo.

Stamp là thay đổi additive an toàn; khuyến nghị commit riêng để diff sạch.

### Bước 5: Report

In bảng phân nhóm (xem Output Format). Skill **không** migrate, **không** đổi nội dung artifact ngoài việc stamp ở Bước 4.

---

## Output Format

```
ARTIFACT AUDIT — scope: {all main | frd, crd}
Current template versions: prd v1 · domain v1 · sad v1 · frd v2 · crd v1 · ...

OUT-DATED ({n}) — cần migrate:
  feature/F-002-payment/frd.md       frd    v1 → v2   → /artifact-migrate
  feature/F-003-x/frd.md             frd    unversioned, lệch structure (thiếu: Verification Rules) → migrate

STAMPED ({n}) — legacy khớp structure, vừa ghi template_version:
  feature/F-001-auth/frd.md          frd    → v2
  component/C-001-core/crd.md        crd    → v1

UP-TO-DATE ({n}): {đếm, liệt kê path ngắn gọn hoặc gập lại nếu nhiều}

Bước tiếp theo (nếu có out-dated):
  - /artifact-migrate [path]
```

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Cứ stamp hết cho gọn rồi tính sau" | Stamp nhầm artifact lệch structure = giấu luôn nó khỏi audit lần sau. Chỉ stamp khi structure khớp chắc chắn. |
| "Audit luôn tiện migrate luôn" | Hai trách nhiệm khác nhau. Audit chỉ phát hiện; migrate (đổi structure) là `/artifact-migrate` với dry-run + confirm. |
| "Thiếu version thì coi như out-dated hết" | Sai — legacy khớp structure chỉ là chưa stamp, không phải lỗi thời. Phải đối chiếu structure trước khi kết luận. |
| "Artifact có thêm `#### NFR AC` mà template không có → lệch → out-dated" | Sai — template là skeleton tối thiểu; thừa sub-section/nội dung là authoring bình thường. Conformance là quan hệ bao hàm: section bắt buộc còn đó → conform. Chỉ thiếu/đổi-tên/đổi-format mới là out-dated. |

## Red Flags

- Stamp `template_version` cho artifact mà chưa đối chiếu structure với template.
- Tự sửa structure / nội dung artifact (vượt phạm vi — đó là migration skill).
- Flag out-dated chỉ vì artifact có thêm sub-section / nội dung ngoài template (thừa ≠ lỗi thời; chỉ thiếu/đổi-tên/đổi-format mới tính).
- Audit/stamp artifact ngoài scope: bất kỳ file nào trong `.specs/integrations/`, `.specs/tests/` (test-side non-versioned), `.specs/archive/`, `.specs/removed/` — bỏ qua hết.
- Đọc version từ một manifest/cache thay vì đọc thẳng frontmatter template.

## Verification

- [ ] Scope = **chỉ main artifacts** (`.specs/main/**`); resolve đúng từ argument (1 main type / list / mọi main type)
- [ ] Current version đọc thẳng từ frontmatter template tại `.claude/templates/...` (không manifest)
- [ ] Bỏ qua toàn bộ `.specs/integrations/`, `.specs/tests/`, `.specs/archive/`, `.specs/removed/`, `*.bak.*`, và file không khớp type map
- [ ] Versioned: `==` → up-to-date; `!=` → out-dated `(vX → vY)` → migrate
- [ ] Unversioned: conformance là quan hệ bao hàm (artifact chứa đủ structure bắt buộc; thừa sub-section/nội dung không khai báo remove KHÔNG phải lỗi thời); 2 dấu hiệu out-dated = thiếu required heading / section `migrations.remove` còn sót
- [ ] Conform → stamp; out-dated → tóm tắt đúng dấu hiệu (thiếu required heading gì / section deprecated nào còn sót). Lưu ý: presence-check KHÔNG bắt format-update (blind spot unversioned)
- [ ] Có confirm trước khi ghi stamp; stamp chỉ thêm field `template_version`, không đụng nội dung khác
- [ ] KHÔNG migrate / không sửa structure artifact
- [ ] Report phân nhóm out-dated / stamped / up-to-date + bước tiếp theo
