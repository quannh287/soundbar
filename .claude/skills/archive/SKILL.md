---
name: archive
description: Archive một integration hoặc bộ test của một feature sang .specs/archive/ — namespaced theo loại (.specs/archive/integrations/ và .specs/archive/tests/). Dùng khi integration đã hoàn thành hoặc một feature retire và cần dọn ra khỏi thư mục làm việc chính.
---

# archive

## Overview

Di chuyển một artifact ra khỏi thư mục làm việc sang `.specs/archive/`, giữ nguyên nội dung. Hỗ trợ **hai plane**:

- **Integration**: `.specs/integrations/{id}-{slug}/` → `.specs/archive/integrations/{id}-{slug}/`
- **Test (bộ test của feature)**: `.specs/tests/{F-XXX}-{slug}/` → `.specs/archive/tests/{F-XXX}-{slug}/`
  - Đơn vị archive = **cả bộ test của feature** (`{F-XXX}-{slug}/` — test-design + selector-contract + test-exec-* + test-report-{scope} + roll-up test-report.md). Test-side đã là artifact **bền, một bộ/feature** (015): không còn tầng cycle bundle để archive lẻ; chỉ archive trọn bộ khi feature retire.

`.specs/archive/` được **namespace theo loại** (`integrations/` + `tests/`) để không trộn lẫn hai plane. Cấu trúc nguồn giữ nguyên dưới subfolder loại (test-side single-tier `{F-XXX}-{slug}/`).

## When to Use

- Integration đã hoàn thành (Done) / cancel / deferred vô thời hạn.
- **Feature retire** → archive cả bộ test của nó ra khỏi working set.
- Dọn dẹp `.specs/integrations/` hoặc `.specs/tests/` khỏi artifact không còn active.

## When NOT to Use

- Integration đang In Progress → chưa nên archive.
- Feature còn active → giữ bộ test ở `.specs/tests/` (nó là artifact bền, không phải cycle tạm).
- Muốn xóa hoàn toàn → đừng archive, thao tác thủ công sau khi confirm với team.

---

## Process

### Bước 1: Chuẩn bị thư mục archive

`.specs/archive/` chứa subfolder theo loại. **Tạo lazy** — chỉ tạo subfolder loại nào khi thực sự archive item thuộc loại đó:

- Archive integration → đảm bảo `.specs/archive/integrations/` tồn tại (tạo nếu chưa).
- Archive bộ test → đảm bảo `.specs/archive/tests/` tồn tại (tạo nếu chưa).

---

### Bước 2: Liệt kê archivable từ cả hai plane

Quét `.specs/integrations/` và `.specs/tests/`. Hiển thị danh sách **chia section theo plane, đánh số liên tục**:

```
Archivable:

Integrations (.specs/integrations/):
  [1]  001-user-authentication      (approved)
  [2]  003-notification-service     (done)

Tests (.specs/tests/):
  [3]  F-012-bulk-import            (test-design + 4 test-exec + 4 report + roll-up)
  [4]  F-031-checkout               (test-design + roll-up)

Chọn số để archive (nhiều số cách nhau bởi dấu cách, ví dụ: 1 3):
```

- **Integration**: mỗi `{id}-{slug}/` là 1 dòng. Cố đọc `spec.md` frontmatter `status` để hiển thị (bỏ qua nếu không đọc được).
- **Test**: mỗi bộ test của feature `{F-XXX}-{slug}/` là 1 dòng (liệt kê nhanh các file test-side có trong đó). Single-tier — không còn cycle con.
- ⚠ **Đếm report bằng tên chính xác, đừng dùng glob `test-report*.md`** — glob đó khớp **cả** roll-up `test-report.md`, làm số report scope lệch lên 1. Đếm `test-report-{validation,functional,e2e,nfr,dm}.md` rồi ghi roll-up riêng.
- Cả hai plane rỗng → `Không có gì để archive trong .specs/integrations/ và .specs/tests/.` → dừng.

---

### Bước 3: Xác nhận

Hiển thị source → **namespaced dest** trước khi di chuyển:

```
Sẽ archive:

  .specs/integrations/001-user-authentication/
    →  .specs/archive/integrations/001-user-authentication/

  .specs/tests/F-012-bulk-import/
    →  .specs/archive/tests/F-012-bulk-import/

Xác nhận? (yes/no)
```

#### Nợ của BA mà integration bị archive còn để lại — cảnh báo, không chặn

Sổ nợ của BA là **một sổ của mỗi feature, cạnh `frd.md`** — `.specs/main/feature/{F-XXX}-{slug}/spec-debt.md` ([`02-artifacts.md §2.3`](../../02-artifacts.md), [`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)). Sổ **không** đi theo integration vào archive, nên archive không làm mục nào đóng băng: mục chưa quyết vẫn mở ở sổ feature, BA vẫn quyết được bằng `/spec-new {F-XXX}`.

Với mỗi feature trong `features:` của `spec.md`, đọc sổ của nó (không có ⇒ im lặng) và chỉ đếm mục **thuộc đợt đang archive** — mục có một dòng `**phát hiện:**` chứa `` của `{slug}` ``. Bốn con số riêng — hai cho gap (`SG-*`), hai cho drift (`SD-*`):

| Số | Đếm dòng chính | Nghĩa |
|---|---|---|
| **chưa quyết** | `- [ ] **SG-n**` / `- [ ] **SD-n**` **không** có con trỏ `→ {slug}` ngay sau số mục / `` `{ID}` `` | chờ BA trả lời |
| **đang làm** | có con trỏ đó | đã lên spec, chờ `{slug}` xong |

```bash
# mục thuộc đợt: dòng chính của mỗi mục có dòng phát hiện chứa `của `{slug}``
muc=$(awk -v s="của \`$SLUG\`" '
  /^- \[[ x]\] \*\*S[GD]-/ { if (hit) print head; head=$0; hit=0; next }
  index($0, s)            { hit=1 }
  END                     { if (hit) print head }' "$BOOK")
CON_TRO='^- \[ \] \*\*S[GD]-[0-9]+\*\*( · `[^`]+`)? →'
open=$(printf '%s\n' "$muc" | grep -E '^- \[ \] \*\*SG-' | grep -vcE "$CON_TRO")
wip=$(printf '%s\n' "$muc" | grep -E '^- \[ \] \*\*SG-' | grep -cE "$CON_TRO")
d_open=$(printf '%s\n' "$muc" | grep -E '^- \[ \] \*\*SD-' | grep -vcE "$CON_TRO")
d_wip=$(printf '%s\n' "$muc" | grep -E '^- \[ \] \*\*SD-' | grep -cE "$CON_TRO")
```

Đếm theo **vị trí** con trỏ, không theo "dòng có chứa `→`": mô tả của sổ đã chuyển từ dạng cũ có thể chứa `→`. Mục của đợt khác hay của ④ Verify nằm cùng sổ nhưng **không** tính — archive đợt này không phải lúc báo nợ của người khác.

In TRƯỚC dòng confirm:

```
⚠ 004-todo-bulk-archive: 2 spec gap CHƯA QUYẾT ở F-002 (.specs/main/feature/F-002-todo-management/spec-debt.md)
  Archive vẫn được — mục vẫn mở ở sổ của feature. Quyết ở: /spec-new F-002

ⓘ 004-todo-bulk-archive: 1 spec gap đang làm — SG-3 → 006-todo-error-surface

⚠ 004-todo-bulk-archive: 1 spec drift CHƯA QUYẾT ở F-002 — SD-1 · AC-F002-016
  Trong lúc chưa quyết, ④ Verify không sửa code của AC-F002-016. Quyết ở: /spec-new F-002
```

**Cảnh báo, KHÔNG chặn (029 D7).** Archive là dọn thư mục làm việc; quyết định gap nào lên spec là của **BA**. Chặn ở đây là trộn hai gate, và một integration đã xong lại không dọn được vì đang chờ người khác quyết. Khác trước 039: bấm `yes` **không** còn là bỏ nợ — sổ ở lại với feature, khoá của drift mở vẫn còn.

Gặp sổ kiểu cũ (`.specs/integrations/{slug}/spec-debt.md` của chính integration đang archive) ⇒ in `⚠ Sổ nợ spec kiểu cũ: {đường dẫn} — chạy: npx spec-lite migrate-spec-debt trước khi archive`, rồi hỏi confirm như thường; archive xong thì sổ đó vào kho lưu trữ, và lệnh chuyển vẫn chép được mục từ kho lưu trữ sang sổ feature.

**Gap đang làm không cảnh báo, chỉ in cho biết** — đã có người nhận, BA không phải quyết lại. Gộp hai số vào một cảnh báo là kêu về thứ BA đã trả lời rồi, và người đọc học cách bỏ qua cả khối.

- Không confirm → hủy, không làm gì.

---

### Bước 4: Di chuyển

Với mỗi item đã confirm, di chuyển **giữ nguyên cấu trúc nguồn** dưới subfolder loại:

- Integration: `.specs/integrations/{id}-{slug}/` → `.specs/archive/integrations/{id}-{slug}/`
- Bộ test: `.specs/tests/{F-XXX}-{slug}/` → `.specs/archive/tests/{F-XXX}-{slug}/` (tạo `.specs/archive/tests/` nếu chưa có).

⚠ **`mv` cả thư mục feature, KHÔNG `mv` nội dung của nó.** Bộ test có thư mục `.progress/` (sổ tiến độ của 5 skill verify — `02-artifacts.md` §4.7), và `mv .specs/tests/{F-XXX}-{slug}/* {dest}/` **bỏ nó lại** vì glob `*` không khớp tên bắt đầu bằng dấu chấm. Bản archive thiếu sổ, còn thư mục nguồn thì còn một dotdir mồ côi. Cần liệt kê nội dung thì thêm `.[!.]*`.

**No-overwrite guard:** nếu dest đã tồn tại → cảnh báo và **bỏ qua** item đó (không ghi đè frozen record):

```
⚠ .specs/archive/tests/F-012-bulk-import/ đã tồn tại. Bỏ qua để tránh ghi đè.
```

Tiếp tục với các item còn lại.

---

### Bước 4b: Đóng `spec_gap` · `spec_drift` mà integration vừa archive đã giải quyết

**Đây là chỗ DUY NHẤT đặt `- [x]` cho một `SG-*`/`SD-*` đã lên spec (029 D9 · 036 D4).** Phép quét `→ {id}-{slug}` dưới đây khớp cả hai loại dòng — dòng `SD` giữ `` · `{ID}` `` trước `→`, không đổi gì. `/spec-new` chỉ ghi con trỏ `→ {slug}`; nó không biết integration đó có xong hay không. `/implement` cũng không: nó dừng **trước** merge và trước ④ Verify, nên "xong" ở đó là tự phong. `/archive {slug}` là thao tác duy nhất trong kit có nghĩa *"việc này xong rồi, dọn đi"*.

Với **mỗi integration** `{id}-{slug}` vừa archive ở Bước 4:

```bash
grep -rlF --include=spec-debt.md "→ ${id}-${slug}" .specs/main/feature 2>/dev/null
```

**Chỉ quét sổ của feature** — `.specs/main/feature/` ([`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)): mỗi khoản nợ chỉ có một dòng, ở đó. Dùng `grep -r --include`, không glob `*/spec-debt.md` — glob không khớp gì thì zsh dừng hẳn. Với mỗi dòng khớp:

```
- [ ] **SG-1** → 005-todo-archive-error — {mô tả} *(/spec-new · 2026-09-07)*
⇒  - [x] **SG-1** → 005-todo-archive-error — {mô tả} *(/archive · 2026-09-14)*
```

**Suffix nguồn thay chỗ suffix cũ, không cộng dồn** — dòng mang **một** suffix: nguồn của lần đổi **gần nhất**. Lịch sử đầy đủ ở `git`; sổ giữ trạng thái hiện tại cùng người đổi nó. Nguồn thuộc tập đóng `/spec-new` · `/archive` · `tay: {ai/lý do}`, nên đọc `grep` là biết ô nào do pipeline đặt, ô nào do người gõ.

Khớp **`→ {id}-{slug}` đầy đủ**, không khớp tiền tố số: `→ 5-…` và `→ 005-…` là hai thứ khác nhau, và khớp lỏng thì đóng nhầm gap của integration trùng số.

**Quét chứ không tra backlink.** `spec.md` của integration giải quyết có dòng `**Nguồn:** spec gap SG-1 của 004-…` — nhưng đó là provenance cho **người** đọc. Quét thì gap được lên spec bằng tay (không qua Cửa 3 của `/spec-new`) vẫn đóng được.

**Không còn luật thứ tự archive.** Trước 039, sổ của integration nguồn đi vào kho lưu trữ cùng nó, nên phải dọn integration giải quyết trước, nguồn sau. Sổ giờ ở cạnh `frd.md` và không vào kho lưu trữ theo integration nào, nên thứ tự archive không đổi kết quả.

Không tìm thấy dòng nào ⇒ im lặng. Đa số integration không giải quyết gap của ai.

---

### Bước 5: Kết quả

```
✓ Đã archive:
  .specs/archive/integrations/001-user-authentication/
  .specs/archive/tests/F-012-bulk-import/

{nếu có}
✓ Spec gap / drift đã đóng:
  main/feature/F-002-todo-management/spec-debt.md — SG-1 *(/archive · 2026-09-14)*
  main/feature/F-002-todo-management/spec-debt.md — SD-1 · AC-F002-016 *(/archive · 2026-09-14)*

{nếu có}
⚠ Bỏ qua (đã tồn tại):
  .specs/archive/tests/F-031-checkout/

Còn lại: {N} integration(s), {M} feature test set(s).
```

---

## Verification

Trước khi di chuyển:

- [ ] Subfolder loại tương ứng (`.specs/archive/integrations/` hoặc `.specs/archive/tests/`) đã tồn tại (tạo lazy nếu chưa).
- [ ] User đã chọn ít nhất 1 item.
- [ ] User đã confirm.
- [ ] Cấu trúc nguồn giữ nguyên dưới subfolder loại (test-side single-tier `{F-XXX}-{slug}/`).
- [ ] Bộ test: `mv` **cả thư mục**, không `mv {dir}/*` — dotdir `.progress/` phải đi theo; sau khi di chuyển, `ls -a` ở nguồn không còn gì và `ls -a` ở dest có `.progress/`.
- [ ] Không ghi đè nếu dest đã tồn tại.
- [ ] Cảnh báo đếm **hai số riêng** trên sổ của các feature trong `features:`, **chỉ mục có dòng phát hiện của đợt này**: chưa quyết (cảnh báo) vs đang làm (chỉ in); con trỏ đếm theo vị trí.
- [ ] Bước 4b quét **chỉ** `.specs/main/feature/` (`grep -r --include=spec-debt.md`), khớp `→ {id}-{slug}` đầy đủ.
- [ ] Archive bộ test **không** đụng sổ nợ — sổ ở cạnh `frd.md`, đi theo feature khi `/spec-remove` chuyển thư mục feature sang `.specs/removed/`.
- [ ] Dòng flip ở Bước 4b mang suffix nguồn `*(/archive · {date})*`, **thay** suffix cũ chứ không cộng dồn.
