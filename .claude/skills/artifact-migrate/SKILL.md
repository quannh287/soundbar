---
name: artifact-migrate
description: Migrate MAIN artifact trong .specs/main/ lên structure template mới nhất (chỉ main artifacts — prd/domain/sad/frd/fdd/crd/cdd; integration artifacts + test-side artifacts dưới .specs/tests/ ngoài scope). Tự chạy /artifact-audit (classify-only, scoped) để phát hiện out-dated, rồi áp delta từ block `migrations` của template — add section thiếu, remove section deprecated, update format section (vd ASCII→Mermaid) — set template_version = current. Tương tác: confirm add/remove/update, hỏi carry-over khi rename, section nội dung mới thì interview hoặc NEEDS_CLARIFY (không bịa). Single-artifact, KHÔNG cascade. Nhận tùy chọn 1 main artifact (path); không có arg → quét mọi main artifact, migrate từng cái có confirm + skip.
---

# artifact-migrate

## Overview

Đưa một main artifact (hoặc toàn bộ main artifacts) **lỗi thời** lên đúng structure của template mới nhất, rồi cập nhật `template_version`. Đây là vế **fix** đối xứng với `/artifact-audit` (vế **detect**).

> **Scope = chỉ main artifacts** (`prd`, `domain`, `sad`, `frd`, `fdd`, `crd`, `cdd` — đều dưới `.specs/main/`). **Ngoài scope:** integration artifacts (`spec`/`tech`/`test`/`plan`/`todo`/`techdebt`, ephemeral + immutable sau `done`) **và** test-side artifacts dưới `.specs/tests/` (`test-design`/`selector-contract`/`test-exec-*`/`test-report` — tạm thời non-versioned, 015 §3B; change history = git). `test-design`/`selector-contract` đã dời sang `.specs/tests/` và ra khỏi versioning trong cửa sổ này.

Cơ chế (xem `01-architecture.md` §12 Template Versioning):
- **Required section hiện tại** = body `##` headings của template (deterministic theo level; `###` = instance).
- **Delta giữa các version** = đọc từ block `migrations` của template: mỗi entry `to: N` ghi `add` (section thêm) + `remove` (section bỏ) + `update` (section giữ nhưng đổi format/cách thể hiện, vd ASCII → Mermaid). `remove` và `update` không suy lại được từ body → block `migrations` là nguồn duy nhất.
- Migrate **single-artifact, KHÔNG cascade**. ID format đổi (hiếm, cross-artifact) → xử lý tay theo `note`.

## When to Use

- Sau `git pull` kit mới, `/artifact-audit` báo có artifact out-dated → migrate chúng lên template mới.
- Onboarding repo cũ: artifact legacy thiếu version / lệch structure.
- Sau khi bump `template_version` một template → migrate các artifact cùng type.

## When NOT to Use

- Chỉ muốn **biết** artifact nào lỗi thời (không sửa) → `/artifact-audit`.
- Muốn đổi **nội dung** artifact (thêm US, đổi AC) → integration changeset (`/spec-new`) hoặc edit tay.
- Working tree đang dirty → commit/stash trước (skill rollback dựa git, không tạo `.bak`).

---

## Type → template map

Resolve type của main artifact theo **filename** (giống `/artifact-audit`). Mỗi type map tới đúng một template tại `.claude/templates/...`:

`prd.md`→`main/prd-template.md` · `domain.md`→`main/domain-template.md` · `sad.md`→`main/sad-template.md` · `frd.md`→`main/feature/frd-template.md` · `fdd.md`→`main/feature/fdd-template.md` · `crd.md`→`main/component/crd-template.md` · `cdd.md`→`main/component/cdd-template.md`

**Chỉ main artifacts.** Integration artifacts (`spec`/`tech`/`test`/`plan`/`todo`/`techdebt`) ngoài scope → bỏ qua. File không khớp map → cũng bỏ qua.

---

## Process

### Bước 0: Resolve scope

- **ARGUMENT là path tới 1 main artifact** → migrate riêng nó. Nếu path là integration artifact (`.specs/integrations/...`) hoặc test-side artifact (`.specs/tests/...`) → **DỪNG**, báo "ngoài scope — chỉ migrate main artifacts (`.specs/main/`)". Nếu nằm trong `.specs/archive`/`.specs/removed` → **DỪNG**, báo "artifact đóng băng (immutable record) — không migrate".
- **Không có ARGUMENT** → quét **chỉ** `.specs/main/**`, áp **đúng skip list của `/artifact-audit`** (bỏ toàn bộ `.specs/integrations/`, `.specs/tests/`, archive/removed, `*.bak.*`, và `spec-debt.md` cạnh `frd.md` — đổi hình dạng sổ là việc của `npx spec-lite migrate-spec-debt`, [`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)).

### Bước 1: Pre-flight — working tree clean

Chạy `git status --porcelain`. Output không rỗng → **DỪNG**:
> ⛔ Working tree không clean. Skill không tạo `.bak` — rollback dựa git. Hãy commit/stash trước rồi chạy lại.

Không phải git repo → cảnh báo, yêu cầu confirm (default no) vì không rollback được.

### Bước 2: Detect — tự chạy `/artifact-audit` (classify-only, scoped)

Dùng **chính conformance check của `/artifact-audit`** (presence-check, 01-architecture.md §12) làm bước phát hiện — một nguồn phán đoán duy nhất, không tự cài lại logic. Scoped theo Bước 0:
- Có arg → audit đúng artifact/type đó.
- Không arg → audit toàn bộ scope.

Audit chạy **classify-only** ở đây: chỉ phân loại, **không tự stamp/confirm** (migrate sẽ điều phối mọi ghi vào một luồng confirm). Kết quả mỗi artifact:
- **up-to-date** (versioned, version `==` template) → bỏ qua. Target đơn lẻ → **no-op sớm**, thoát.
- **legacy-conformant** (thiếu version nhưng đủ required `##`, không dính `migrations.remove`) → chỉ cần **stamp** version (không đổi structure).
- **out-dated** (versioned `!=` template, HOẶC unversioned thiếu required `##`, HOẶC còn section trong `migrations.remove`) → cần migrate structure.

Không arg → in danh sách phân nhóm trước, rồi xử lý **từng artifact một, có confirm + cho skip** (không bulk-auto).

### Bước 3: Lập transform plan cho từng artifact

Resolve type→template, đọc template: `template_version` hiện tại + block `migrations` + body `##` headings.

Gộp delta các entry `to:` > version artifact (hoặc tất cả nếu artifact unversioned):

1. **Sections cần ADD** = required `##` của template mà artifact **thiếu**. (Phát hiện bằng so `##` body, deterministic; `migrations.add` để tham khảo delta.)
2. **Sections cần REMOVE** = section trong **`migrations.remove`** mà artifact **còn chứa**.
3. **Sections cần UPDATE format** = section trong **`migrations.update`** (giữ section, đổi cách thể hiện — vd ASCII → Mermaid). Section vẫn còn → không add/remove; chỉ transform format theo mô tả `change`. (Không suy được từ presence-check → bắt buộc dựa `migrations.update`.)
4. **Rename phát hiện được** khi một `remove` (tên cũ) đi kèm một `add` (tên mới) trong cùng entry — đánh dấu để hỏi carry-over content.
5. **ID format** (nếu `note` đề cập, cross-artifact) → liệt kê để người dùng sửa tay; skill không tự remap.

### Bước 4: Dry-run + confirm (một luồng)

Trình bày cho user **trước khi ghi**:
- sections sẽ ADD (kèm skeleton lấy từ body template) + sections sẽ REMOVE (kèm reason).
- sections sẽ UPDATE format → show **nội dung hiện tại** + **đề xuất bản chuyển format** (vd ASCII diagram → Mermaid tương ứng), giữ nguyên ngữ nghĩa.
- cặp rename phát hiện được → hỏi: "carry-over nội dung từ {cũ} sang {mới}?".
- artifact legacy-conformant trong scope → sẽ stamp version (gộp vào cùng confirm).

User confirm (toàn bộ / từng item / skip artifact). **Section nội dung mới** (vd Verification Rules) → **interview user điền** hoặc chèn `**[NEEDS_CLARIFY]**` — **KHÔNG tự bịa nội dung**. Với UPDATE format: chuyển *cách thể hiện*, **không bịa thêm/bớt thông tin** so với bản cũ; phần không chắc → giữ + `[NEEDS_CLARIFY]`.

### Bước 5: Apply (atomic mỗi artifact)

- Chèn section ADD theo đúng thứ tự body template; nếu là rename + user đồng ý carry-over → move nội dung từ section cũ sang.
- Xóa section REMOVE (đã confirm).
- Áp UPDATE format: thay nội dung section bằng bản chuyển format đã confirm (giữ section + ngữ nghĩa).
- **Giữ nguyên** mọi sub-section / content tác giả **không nằm trong `remove`/`update`** (superset rule).
- Set frontmatter `template_version` = current.
- **Migration bỏ `Change History` (template có `id_counters` mà artifact chưa có):** TRƯỚC khi xoá section, **seed `id_counters`** vào frontmatter — mỗi family = `max(seq đang có trong body, seq xuất hiện trong Change History cũ)` (quét cả entry `[REMOVE]` để giữ dấu ID đã retire). Xong mới xoá section `## Change History`. Đây là bước duy nhất phải đọc Change History cũ — sau migrate, "lịch sử" = git.
- **KHÔNG append Change History** (section đã bỏ — history = git). Bản ghi lần migrate = git commit (`git checkout -- {file}` để rollback).
- **Single-artifact, KHÔNG cascade.** Apply fail → rollback bằng git; báo user.

### Bước 6: Report

```
ARTIFACT MIGRATE — scope: {file | all}

MIGRATED ({n}):
  feature/F-002-payment/frd.md    v0 → v1   +User Flows, −Components Consumed, ~System Overview (ASCII→Mermaid)
STAMPED ({n}) — legacy conform, chỉ set version:
  feature/F-001-auth/frd.md       → v1
SKIPPED / up-to-date ({n})

{nếu có} NEEDS_CLARIFY còn lại:
  feature/F-002-payment/frd.md → Verification Rules (chờ điền)
{nếu có} Cần sửa tay (ID remap theo note):
  ...
```

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Tự đoán nội dung cho section mới cho nhanh" | Section nội dung mới = quyết định của BA/owner. Bịa = sai mà không ai review. Interview hoặc NEEDS_CLARIFY. |
| "Section thừa chắc là rác, xóa luôn" | Chỉ xóa section nằm trong `migrations.remove`. Thừa khác là content tác giả → giữ (superset). |
| "Format đổi thì xóa section rồi thêm lại" | remove+add làm **mất nội dung**. Format-update giữ section + ngữ nghĩa, chỉ chuyển cách thể hiện (dùng op `update`). |
| "Chuyển format thì tiện viết lại nội dung cho đẹp" | UPDATE chỉ đổi *cách thể hiện*, KHÔNG thêm/bớt thông tin. Phần không chắc → giữ + NEEDS_CLARIFY. |
| "Migrate tiện remap ID luôn" | Không có op remap; cascade đã bỏ. ID đổi (hiếm) ghi ở `note`, người dùng sửa tay. |
| "Khỏi chạy audit, tự check structure cho nhanh" | Phải dùng audit classify-only → một nguồn phán đoán duy nhất, không lệch giữa hai skill. |

## Red Flags

- Bịa nội dung cho section ADD thay vì interview / NEEDS_CLARIFY.
- Xóa section không nằm trong `migrations.remove` (vi phạm superset).
- Tự remap ID / đụng tới artifact khác (migrate là single-artifact, không cascade).
- Chạy khi working tree dirty (mất đường rollback).
- Migrate artifact ngoài scope: bất kỳ file nào trong `.specs/integrations/`, `.specs/tests/` (test-side non-versioned), `.specs/archive`, `.specs/removed` (phải skip / DỪNG).
- Migrate artifact đã up-to-date (phải no-op sớm).
- Tự cài lại logic detect thay vì dùng audit classify-only.

## Verification

- [ ] Scope = **chỉ main artifacts** (`.specs/main/**`); arg là integration artifact → DỪNG, no-arg chỉ quét `.specs/main/**`
- [ ] Pre-flight: working tree clean (hoặc user confirm khi không phải git repo)
- [ ] Detect bằng `/artifact-audit` classify-only, scoped theo target; version `==` → up-to-date → no-op sớm; `!=` → migrate
- [ ] Required `##` thiếu → ADD (skeleton từ body template); section `migrations.remove` còn sót → REMOVE (confirm)
- [ ] Section `migrations.update` → chuyển format (giữ section + ngữ nghĩa); show cũ + đề xuất mới, confirm; KHÔNG thêm/bớt thông tin
- [ ] Rename (remove+add) → hỏi carry-over content; section nội dung mới → interview / NEEDS_CLARIFY (KHÔNG bịa)
- [ ] Giữ content tác giả không nằm trong `remove`/`update` (superset)
- [ ] Set `template_version` = current; nếu migration bỏ Change History → seed `id_counters` = max(doc, CH cũ) TRƯỚC khi xoá section; KHÔNG append Change History
- [ ] Single-artifact, KHÔNG cascade; ID remap (nếu có) chỉ báo để sửa tay
- [ ] Không arg → liệt kê trước, migrate từng cái có confirm + skip
- [ ] Apply fail → rollback git; user được thông báo
