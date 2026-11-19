---
name: spec-test
description: Điều phối reconcile test-design cho một integration. Gọi /spec-test-design --dry-run cho từng feature trong features:, diff test-design.md ↔ .next theo Key, ghi bảng delta vào test.md, rồi promote bằng mv, rồi gọi /spec-test-exec dựng khung test-exec-* cho từng feature (034 D9). KHÔNG tự derive TC. Role QC, song song với /spec-tech (DEV) — cả hai chỉ phụ thuộc spec.md approved.
---

# spec-test

## Overview

Tạo `.specs/integrations/{slug}/test.md` — **bản ghi delta** của lượt reconcile test-design theo integration này, rồi dựng khung `test-exec-*` cho từng feature. Sáu việc, không có việc thứ bảy:

```
gate → /spec-test-design --dry-run → diff current ↔ .next → ghi test.md → promote (mv) → /spec-test-exec
```

**Skill này KHÔNG derive TC (028 D0).** Cỗ máy derive duy nhất của kit là [`/spec-test-design`](../spec-test-design/SKILL.md) — 7 kỹ thuật ISTQB, hệ số nhân, `Key`, `id_counters`, sổ derive, `check-ledger`. `test-design.md` là artifact **được derive** (TC là hàm của `frd.md`), nên không tồn tại patch nào để áp: cái được áp là **cả file mới** `.next`. `test.md` là *kết quả của phép trừ*, không phải *nguyên nhân* của thay đổi ⇒ **reconcile, không phải cascade** ([`05-concepts.md`](../../05-concepts.md)).

**Hai artifact tách bạch:** `.specs/integrations/{slug}/test.md` — integration-level, ephemeral, PR record bất biến sau approve. `.specs/tests/{F-XXX}-{slug}/test-design.md` — feature-level, persistent, **TC content cuối cùng nằm ở đây** (test-side, thư mục `tests/` riêng — 015).

**Role:** QC. Song song / độc lập với `/spec-tech` (DEV) — cả hai chỉ phụ thuộc `spec.md` approved.

## When to Use

- `spec.md` đã approve → reconcile test-design của các feature bị touched
- Integration đã có spec.md/tech.md nhưng chưa có test.md

## When NOT to Use

- `spec.md` chưa approve → `/spec-new` trước
- `features: []` (integration thuần component) → không áp dụng; đặt verification vào `tech.md > Implementation Notes` hoặc `plan.md > Verification phase`
- Chỉ reconcile **một** feature, không theo integration → gõ thẳng `/spec-test-design {F-XXX}`
- QC muốn **thêm TC tay** → thêm thẳng vào `test-design.md` với `Key: manual::{slug}` (028 D7); `manual::*` là vùng cấm của reconcile, không đi qua `test.md`

## Nhánh mặc định — skill KHÔNG BAO GIỜ dừng chờ người (027 D12)

| # | Điểm rẽ | Nhánh mặc định |
| --- | --- | --- |
| 1 | Không argument, chọn integration nào | đúng **1** integration `spec.md` approved mà chưa có `test.md` ⇒ lấy. Nhiều hơn ⇒ **dừng có lỗi**, in danh sách |
| 2 | `test.md` đã tồn tại — ghi đè? | **ghi đè** khi lượt này **có** delta; bản cũ nằm trong git. Lượt no-op toàn phần ⇒ **không** ghi (Bước 5) |
| 3 | Đã ghi `test.md` — promote `.next`? | **promote** (D5). Undo = `git checkout`, `test-design.md` vốn ở `status: draft` |
| 4 | Feature no-delta | **xoá `.next`**, ghi `no-op`, **không** đụng `test-design.md` (D6) |

---

## Process

### Bước 1: Xác định integration

Có ARGUMENT → parse số thứ tự (`2`, `002`) hoặc slug (`002-implement-todo`), quét `.specs/integrations/*/spec.md`; không khớp thì báo lỗi và dừng. Không có ARGUMENT → liệt kê mọi integration có `spec.md` (đánh dấu cái đã có `test.md`) rồi đi theo **điểm rẽ 1**.

### Bước 2: Gate check

Đọc frontmatter `.specs/integrations/{slug}/spec.md`. Mỗi check fail ⇒ **dừng hoàn toàn**, in đúng lý do:

| Check | Fail ⇒ nói gì |
| --- | --- |
| `status: approved` | ⛔ `spec.md` của **{slug}** đang `{status}`. Delta của spec chỉ được `/spec-new` ghi vào `frd.md` **lúc approve** — chạy sớm là reconcile theo frd cũ. Approve rồi chạy lại. |
| `features:` non-empty | ⛔ **{slug}** không touch feature nào. Component contract verify gián tiếp qua feature TC + unit test; đặt verification vào `tech.md` / `plan.md`. |
| `frd.md` tồn tại cho **mọi** feature | ⛔ `main/feature/{F-XXX}-{slug}/frd.md` thiếu nhưng feature có trong `features:` — cascade `spec.md → frd.md` của `/spec-new` có thể đã fail. |

### Bước 3: Load context — **chỉ scope + hint** (028 D2)

Đúng hai file, **không** load `frd.md`:

- `.specs/integrations/{slug}/spec.md` — `features:` (chạy feature nào) + Test Strategy delta + Out of Scope
- `.specs/integrations/{slug}/tech.md` — optional, hint environment / data set / NFR threshold

**Nguồn derive là `frd.md`, và chỉ skill con đọc nó.** "frd + spec = frd mới" đúng ở chỗ `/spec-new` đã cascade delta của spec vào frd lúc approve ⇒ `frd.md` *chính là* frd mới. Derive từ hai nguồn cùng nói một sự thật thì lệch là chắc chắn; `check-ledger` cũng chỉ đối chiếu `frd.md`.

In `TÔI HIỂU`: integration · features touched · số TC test-design hiện tại per feature · tech.md có/không · danh sách lệnh sẽ gọi ở Bước 4.

### Bước 4: Gọi `/spec-test-design --dry-run` cho từng feature (D1)

Theo **thứ tự trong `features:`** (deterministic, không forward reference giữa các test-design):

```
/spec-test-design {F-XXX} --dry-run
```

Skill con derive lại **toàn bộ** từ `frd.md` rồi ghi `test-design.md.next` — file cũ không đụng một byte, không commit. `.next` **hoàn chỉnh**: frontmatter, `id_counters` mới, `versions` đã bump, sổ derive, Traceability Matrix. Lấy path từ dòng contract cuối output:

```
DRY-RUN: .specs/tests/{F-XXX}-{slug}/test-design.md.next
```

Thiếu dòng đó ⇒ derive **thất bại** ⇒ bỏ feature khỏi promote, ghi `⛔ derive fail` + lý do vào `Reconcile Summary`. **Không** tự derive thay.

`id_counters` + `versions` có **một** chủ: skill con (D8). `/spec-test` không đọc, không ghi hai field này — chỉ hiển thị lại dòng skill con báo. Hai chỗ bump = bump hai lần, và `versions` phải monotonic để gate `/spec-test-exec` không rơi vào ô không định nghĩa (018 D14/D17).

### Bước 5: Diff `test-design.md ↔ .next` — join theo `Key`

Khoá ghép là **`Key`** (`{frd-item-id}::{TECHNIQUE}::{case-slug}`, tất định — 018), hiển thị theo ID. Năm nhánh y hệt Bước 4.8 của skill con, ở đây chỉ để **kể lại**, không quyết định gì:

| Nhánh | Dòng trong `test.md > Delta` |
| --- | --- |
| `Key` chỉ ở `.next` | `[NEW] TC-F002-061 · VR-F002-007::BVA::max+1` |
| `Key` ở cả hai, field derive đổi | `[MODIFY] TC-F002-017 · Expected: "255 ký tự" → "200 ký tự"` |
| `Key` ở cả hai, `.next` gắn nhãn `chờ xác nhận` | `[KEEP?] TC-F002-018 · chờ xác nhận (VR-F002-001 đổi ngưỡng)` |
| `Key` bắt đầu `manual::` | `[manual] TC-F002-050 · không đụng` |
| còn lại | gộp một dòng `{N} TC không đổi` |

`[KEEP?]` **nhận diện bằng nhãn, không bằng phép trừ tập `Key`.** Skill con **không bao giờ bỏ** một `Key` khỏi `.next`: TC không còn khớp luật derive vẫn được GIỮ nguyên, chỉ gắn nhãn `chờ xác nhận` (027 điểm rẽ 3). Nên nhánh *"`Key` chỉ có ở file cũ"* trên thực tế **không xảy ra** — tìm `[KEEP?]` bằng cách đọc nhãn trong `.next`, đối chiếu với file cũ xem nhãn đó **mới xuất hiện** ở lượt này. Đừng viết `[REMOVE]`. *(Đo ở bed `004` ngày 2026-09-07: phép trừ tập `Key` ra 0 dòng `[KEEP?]`, trong khi `.next` có 4 TC mang nhãn.)*

TC cũ **không có `Key`** (file do `/spec-test` bản trước 028 ghi): skill con đã xử ở nhánh **bootstrap match** lúc dựng `.next`; `/spec-test` chỉ in lại số ca stamp được `Key` và số ca để trống `Key` + `Gaps`.

**Feature no-delta** (không `[NEW]`/`[MODIFY]`/`[KEEP?]` nào): xoá `.next`, ghi `no-op`, **không** đụng `test-design.md` — ghi lại y nội dung cũ là commit rác + `versions` bump giả (D6).

**MỌI feature no-delta ⇒ lượt no-op toàn phần: KHÔNG ghi lại `test.md`** (D6, mở rộng sau bed 004). In báo cáo `no-op` rồi dừng — `test.md` hiện tại là **bản ghi delta của lượt reconcile gần nhất**, ghi đè nó bằng một bảng rỗng là **xoá bằng chứng** của lượt trước để lấy một file không nói gì. Đây cũng là điều kiện để `git status` **sạch** sau lượt hai trên frd không đổi — gate idempotence của skill này.

### Bước 6: Ghi `test.md` — **trước** khi promote (D5)

Chỉ ghi khi **có ≥1 feature có delta** (lượt no-op toàn phần đã dừng ở Bước 5). Ghi `.specs/integrations/{slug}/test.md` theo [`templates/integrations/test-template.md`](../../templates/integrations/test-template.md) (SSOT của hình dạng), status `approved`, `features` mirror từ `spec.md`, **không** `template_version` (integration artifact ngoài versioning — `01-architecture.md` §12). `Delta` per feature = **bảng scope 7 cột** (copy đúng bảng skill con in) + list dòng theo Bước 5. `Reconcile Summary` liệt kê **mọi** feature trong `features:`, kể cả `no-op`.

Thứ tự bắt buộc: **diff → ghi `test.md` → in ra → promote**. Thuộc tính *"delta đọc được trước khi apply"* đạt bằng **thứ tự vật chất hoá**, không bằng cổng chặn — cổng chặn giết lượt headless (027 đo: 2/9 lượt chết ở prompt).

### Bước 7: Promote — `mv`, không có code apply (D4)

Cho mỗi feature có delta, theo thứ tự `features:`, rồi **commit** (git = content history):

```bash
mv .specs/tests/{F-XXX}-{slug}/test-design.md.next \
   .specs/tests/{F-XXX}-{slug}/test-design.md
```

**Fail-safe là thứ tự, không phải cơ chế** — hỏng ở đâu thì `.next` còn nguyên và file cũ chưa bị đụng. Undo sau promote = `git checkout`. `.next` **không** vào `.gitignore`: nó luôn bị `mv` hoặc xoá trước khi lượt kết thúc, nên thấy `.next` trong `git status` = một lượt đã chết giữa đường.

### Bước 7b: Dựng khung `test-exec-*` cho từng feature (034 D9)

Ngay sau promote, gọi cho **mỗi** `F-XXX` trong `features:`:

```
/spec-test-exec {F-XXX}
```

Ra khung `test-exec-{scope}.md` (đủ row TC, ô `Layer`/`Test File` **rỗng**) + `test-report-{scope}.md` (`Results` rỗng, pin `0`, `mode: cycle`) + roll-up. File đã tồn tại thì `/spec-test-exec` **không đụng** — bước này an toàn khi chạy lại.

**Vì sao ở ① Design chứ không đầu ③ Build.** `/spec-test-exec` là chỗ **duy nhất** cầm luật lọc `Autoable` — TC oracle thị giác không render xuống `test-exec`. Dựng muộn hơn thì `/plan` phải áp lại luật đó lần hai để biết AC nào **lái được**, và hai chỗ cùng implement một luật là chỗ trôi. Dựng ở đây thì `/plan` chỉ cần đọc `test-exec-functional.md` §3.1 ([`.docs/034`](../../.docs/034-double-tdd.md) `D9` · `DS9`).

**Lượt no-op toàn phần vẫn chạy bước này** — feature mới chưa từng có bộ test-exec thì delta rỗng nhưng khung vẫn phải có.

### Bước 8: Thông báo kết quả

```
✓ .specs/integrations/{slug}/test.md đã được tạo (status: approved)

Reconcile:
  ✓ tests/F-XXX-{slug}/test-design.md — validation 29→31 (+2 −1 ~2) · functional 14→14 (~1, manual giữ 1)
      id_counters: tc 47 → 49 (chỉ tăng) · versions: validation 1→2 · functional 1→2
      check-ledger: ✓ SỔ KHỚP
  ✓ tests/F-YYY-{slug}/test-design.md — no-op (frd không đổi, .next đã xoá, versions không bump)

Bước tiếp theo:
  - QC: đọc `test.md > Delta`; xử danh sách `chờ xác nhận` (TC vẫn còn trong test-design, có nhãn)
  - QC: fill placeholders còn lại trong test-design.md (Test Data Requirements / Out of Scope / Strategy)
  - QC: thêm TC tay ⇒ thêm thẳng vào test-design.md với `Key: manual::{slug}`, không qua test.md

  DEV — tuỳ `.specs/integrations/{slug}/tech.md`:
  (a) tech.md chưa có, hoặc chưa `status: approved`:
  - /spec-tech {slug} → thiết kế technical design; /plan cần tech.md
  (b) tech.md đã `status: approved` (chọn một):
  - /implement → chạy trọn combo /plan + vòng lặp /build ↔ /review-integration tới khi review sạch (chạy dài, không hỏi giữa chừng)
  - /plan → chỉ tạo plan.md và todo.md, tự kiểm soát từng bước /build sau đó
```

Phần DEV chỉ in **một** nhánh — nhánh khớp trạng thái `tech.md` lúc in. Ba dòng QC luôn in.

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Thêm luật derive nhỏ vào `/spec-test` cho nhanh" | Đúng cái đã hỏng: hai bộ luật cho một artifact, bản ở đây từng lệch hai thế hệ (018, 027). Sửa ở `/spec-test-design`. |
| "Đọc `frd.md` kiểm lại xem skill con derive đủ chưa" | Việc của `check-ledger` (4 assert, đọc cả `frd.md`). Đọc frd ở đây là mở lại đường derive thứ hai. |
| "`test.md` là patch, phải apply lên test-design" | `test.md` là **bản ghi delta** — phép trừ hai file. Cái được áp là `.next`, bằng `mv`. |
| "Chờ QC confirm rồi mới promote" | Nhánh mặc định là promote (D5); `test.md` đã ghi **trước** đó nên delta đọc được, undo = `git checkout`. |
| "`[KEEP?]` là TC rác, xoá đi" | `[KEEP?]` = **giữ** + nhãn `chờ xác nhận`. Xoá là việc của QC sau khi đọc. |
| "Bump `versions` cho chắc" | Một chủ: skill con (D8). Bump hai lần đẩy `/spec-test-exec` vào reconcile giả. |

## Red Flags

- Skill này có bất kỳ dòng nào nói **cách sinh TC** — kỹ thuật, hệ số nhân, priority default, ID assignment: luật derive đã rời sang `/spec-test-design`
- `/spec-test` tự ghi `versions.{scope}` hoặc `id_counters` (D8)
- Promote mà **chưa** ghi `test.md` — mất thuộc tính "delta đọc được trước khi apply" (D5)
- `.next` còn trong `git status` sau khi lượt kết thúc
- Feature no-delta mà vẫn ghi lại `test-design.md`, hoặc lượt no-op toàn phần mà vẫn ghi lại `test.md` (D6)
- Tìm `[KEEP?]` bằng phép trừ tập `Key` — nhánh đó không bao giờ khớp; nhãn `chờ xác nhận` mới là dấu
- `Reconcile Summary` thiếu row cho feature trong `features:` (kể cả `no-op`)
- TC `manual::*` biến mất sau promote — `.next` của skill con đã ăn mất vùng cấm
- Dòng `[REMOVE]` trong `test.md`, hoặc section `Changes` / `Cascade Summary` với `operation: create|update` — hình dạng trước 028

## Verification

Trước khi ghi `test.md`:

- [ ] Mọi feature trong `features:` đã có một lượt `--dry-run`, hoặc một dòng `⛔ derive fail` kèm lý do
- [ ] Mỗi `.next` được báo bằng dòng `DRY-RUN: {path}` và **tồn tại** trên đĩa
- [ ] `git diff --stat` trên các `test-design.md` **rỗng** — dry-run chưa đụng file nào
- [ ] Diff join theo `Key`, không join theo Title/Steps; `[KEEP?]` đọc từ **nhãn** `chờ xác nhận` trong `.next`
- [ ] `Delta` có bảng 7 cột per feature + list dòng; `Reconcile Summary` đủ feature kể cả `no-op`

Sau khi promote:

- [ ] `npx spec-lite check-ledger .specs/tests/{F-XXX}-{slug}/test-design.md` in **`✓ SỔ KHỚP`** — `⊘ SKIP` cũng exit 0, **không nhận**
- [ ] Mọi TS/TC có `Key` (số dòng `Key:` == số TS+TC)
- [ ] Không còn file `*.next`; `git status` sạch sau commit
- [ ] `id_counters` chỉ tăng · `versions.{scope}` monotonic · TC `Key: manual::*` nguyên vẹn
- [ ] Chạy lại `/spec-test {slug}` lượt hai trên frd không đổi ⇒ **mọi scope `no-op`**, `git status` sạch
