---
name: review-integration
description: Review code sau bước /build theo năm trục — correctness, readability, architecture, security, performance — cộng trục spec drift. Dùng sau khi hoàn thành một hoặc nhiều task trong todo.md. Đối chiếu implementation với spec.md và tech.md để xác nhận đúng yêu cầu.
---

# Review Integration

## Tổng quan

Invoke `code-review-and-quality` để review toàn bộ thay đổi sau `/build`.

Trước khi bắt đầu review, load context từ working integration:

1. `.specs/integrations/{slug}/spec.md` — yêu cầu nghiệp vụ, acceptance criteria
2. `.specs/integrations/{slug}/tech.md` — thiết kế kỹ thuật, API contract, data model
3. `.specs/integrations/{slug}/plan.md` — task breakdown và acceptance criteria chi tiết
4. `.specs/integrations/{slug}/todo.md` — task nào đã được implement (`[x]`)

Chạy lệnh sau để lấy thay đổi cần review — diff từ điểm branch tách ra, không phải từ tip của base branch:

```bash
BASE=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null | sed 's|origin/||' || echo main)
git diff $(git merge-base HEAD $BASE)...HEAD
```

## Cờ trong ARGUMENT

ARGUMENT có thể chứa cờ ngoài slug:

| Cờ | Nghĩa |
|---|---|
| `--auto` | Bật **non-interactive profile** — không hỏi câu nào; mỗi điểm hỏi rẽ theo nhánh **`[--auto]`** ghi ngay tại chỗ đó |
| `--prev-sha={sha}` | `reviewed_sha` của **vòng review trước**. Bật đọc tham chiếu (§Vòng k>1). **Không** thu hẹp diff |

Bỏ cờ ra khỏi ARGUMENT **trước** khi khớp slug.

Cờ có phạm vi **đúng một lần gọi** — không ghi trạng thái ra file, nên lần gõ tay sau vẫn hỏi đầy đủ. `/implement` là caller duy nhất truyền `--auto`.

**Phạm vi diff không đổi vì `--auto`:** vẫn là `git merge-base HEAD $BASE`...`HEAD` — **toàn bộ integration**, không có cờ nào thu hẹp nó về phase hay về một mốc `--since`. Review một khối là chủ ý: ba trong năm trục (architecture · security · performance) là thuộc tính của hệ, chấm theo phase chỉ ra nitpick, và đối chiếu một phase với `spec.md` của cả integration thì đẻ false positive về AC chưa tới lượt.

## Xác định integration

**Nếu có ARGUMENT:** Parse số thứ tự (`2`, `002`) hoặc slug (`002-implement-todo`). Quét `.specs/integrations/*/todo.md`, dùng integration khớp.

**Nếu không có ARGUMENT:** Liệt kê integrations có task đã done, cho user chọn.

## Trục thứ sáu: spec drift

Ngoài năm trục của `code-review-and-quality`, kiểm thêm một câu: **code làm khác requirement ở chỗ nào, và chỗ đó có lý do không?**

Mặc định của SDD: requirement là nguồn, code làm khác requirement là **code sai**. `spec_drift` là ngoại lệ hẹp — code làm khác một `AC-*`/`VR-*`/`FAC-*` đã duyệt **và có dấu vết** cho thấy code có thể đúng:

- dev **cố ý** chỉnh theo thực tế mà không đi qua requirement — comment ở chỗ code đó, hoặc commit message trong `git log $(git merge-base HEAD $BASE)..HEAD` nói vì sao;
- requirement **mâu thuẫn** một nguồn đã duyệt khác (`domain.md`, `tech.md` approved, Problem Statement của chính `spec.md`) và code khớp nguồn đó.

Lúc đó một trong hai bên sai và **chỉ BA biết bên nào**: sửa requirement theo code, hay giữ requirement và sửa code. Reviewer **không chọn thay** — không đẻ task fix (có thể đang sửa code đúng cho khớp requirement sai), không tự sửa `spec.md`.

Drift **không dừng** gì cả: ghi `SD-*` vào sổ `spec-debt.md` của feature, cạnh `frd.md` (§Có `spec_drift` dưới) rồi đi tiếp như một `spec_gap`. Những việc khác của integration vẫn làm xong được trước khi BA quyết.

**Không trỏ được dấu vết ⇒ không phải drift.** Code làm khác requirement mà không comment, không commit, không nguồn nào khớp code ⇒ **code sai**, xếp Critical/Important như mọi finding neo được. Đây là chỗ chặn trốn việc: drift không đẻ task, nên đẩy một lỗi thật sang drift là cách rẻ nhất để vòng lặp kết thúc sớm.

## Phân loại finding — làm TRƯỚC khi xếp severity

Mỗi finding hỏi đúng một câu: **trỏ được về câu nào đã approve không?** Trỏ được thì hỏi tiếp: **code làm khác câu đó có lý do ghi được không?**

`anchor` là ID/section mà finding trỏ về, thuộc **tập đóng**:

| Dạng anchor | Ví dụ |
|---|---|
| Acceptance Criterion | `AC-F002-017` |
| Verification Rule | `VR-F002-006` |
| Feature Acceptance Criterion | `FAC-F002-003` |
| Section của `tech.md` | `tech.md › Technical Design › archiveBulk` |
| Guardrail của `sad.md` | `GUARD-001` |
| Component requirement | `C-003-R02` |

Rồi rẽ ba đường:

| Kết quả | Loại | Đi vào |
|---|---|---|
| neo được vào tập trên, code làm khác **không có lý do** | **code sai** → xếp severity (Critical/Important/Suggestion) | `techdebt.md` + Phase Review |
| neo được vào `AC-*`/`VR-*`/`FAC-*`, code làm khác **có dấu vết** | **`spec_drift`** (trục thứ sáu ở trên) | sổ `spec-debt.md` của feature (`SD-*`) — không task, không chặn verdict |
| spec **im lặng** | **`spec_gap`** | sổ `spec-debt.md` của feature (`SG-*`) — không task, không chặn verdict |

**Hai chiều đều bị chặn:**

- Neo được ⇒ **phải** xếp severity. Không được đẩy một lỗi thật sang `spec_gap` để khỏi mở vòng build, và không được đẩy sang `spec_drift` khi không trỏ nổi dấu vết.
- Neo **không** được ⇒ **không được** là Critical/Important, và **không được bịa anchor** để giữ finding. Trỏ `AC-F002-017` cho thứ mà AC đó không nói là chuyển việc của BA thành việc của dev.

**Vì sao có ngăn thứ ba.** Không có nó, mọi thứ không phải drift đều rơi vào "code sai" và build phải **tự quyết hành vi sản phẩm** thay BA — mà hành vi tự quyết không neo được vào câu nào, nên chính nó là thứ vòng review sau chê. Đo ở pilot `004`: 4/5 Important thật là ca spec im lặng. Chi tiết: [`05-concepts.md §14`](../../05-concepts.md).

## Vòng `k>1` — đọc kết quả vòng trước làm tham chiếu

Có `--prev-sha={sha}` nghĩa là integration này **đã được review** ở một vòng trước. Đọc kết quả vòng đó **trước khi** chấm:

1. `.specs/integrations/{slug}/techdebt.md` — **mọi** section, gồm mục `### Đã cân nhắc, không nêu`.
2. Sổ `spec-debt.md` của mỗi feature trong `features:` (`.specs/main/feature/{F-XXX}-*/spec-debt.md`) — `SG-*` và `SD-*` đang mở.
3. `git diff --name-only {prev-sha}..HEAD` — code nào **đã đổi** kể từ vòng trước.

**Bốn luật đọc:**

| # | Tình huống | Phải làm |
|---|---|---|
| 1 | item `- [ ]` trong section vòng trước | kiểm đã fix chưa; fix rồi ⇒ tick `- [x]` kèm `*(resolved by T{XXX})*` |
| 2 | điểm đã có `SG-*` hoặc `SD-*` trong sổ của feature (Bước 0 của §Có `spec_gap` · §Có `spec_drift`) | **không** nêu lại — không thành Critical/Important, không mở mục thứ hai. Nó đang chờ BA, không chờ dev. Mục chưa có dòng phát hiện nào của đợt này thì Bước 0 thêm một dòng |
| 3 | điểm nằm ở `### Đã cân nhắc, không nêu` vòng trước | **nâng được**, nhưng dòng finding phải ghi `*(vòng {k-1} không nêu vì {…}; nâng vì {…})*` |
| 4 | finding mới trên file/dòng **không** nằm trong `git diff {prev-sha}..HEAD` | hợp lệ, nhưng dòng finding phải mang `*(trên code chưa đổi từ {prev-sha})*` |

**Tham chiếu KHÔNG phải bộ lọc.** Diff vẫn là `merge-base..HEAD` — **toàn integration**, kể cả code không đổi từ vòng trước. Kết luận vẫn là của reviewer này: được đổi ý, được nâng, được nêu thứ vòng trước bỏ qua. Cái bị chặn là **lặp lại trong im lặng** và **đổi ý không giải thích** — hai thứ khiến hai vòng review cùng một integration ra hai bộ finding khác nhau và nhìn từ ngoài giống build phá.

**Vẫn giữ:** không nhận transcript `/build` · không nhận output prose của vòng trước ngoài hai file trên · trục thứ sáu `spec_drift` chấm lại độc lập.

**Heading section vòng `k>1`** ghi thêm phần tham chiếu:

```markdown
## {YYYY-MM-DD} — {short-sha} (review vòng {k}, tham chiếu {prev-sha})
```

Không có `--prev-sha` ⇒ vòng 1 ⇒ heading trần `## {YYYY-MM-DD} — {short-sha}`, không đọc tham chiếu.

## Sau khi review

### Chỉ Nit/Optional/FYI hoặc không có finding

Approve và thông báo tiếp tục `/build` task tiếp theo.

**Luôn báo sha đã review** — cả ở nhánh sạch:

```
Đã review {short-sha} — không có Critical/Important.
ⓘ {SG|SD}-n của {F-XXX}-{slug} đã có — thêm dòng phát hiện của đợt này   ← chỉ khi Bước 0 gặp mục đã có
```

Nhánh sạch **không** ghi gì vào `techdebt.md` (sổ nợ chỉ ghi khi có nợ), nên nếu không in sha ở đây thì một lần review sạch **không để lại dấu vết nào** — và về sau không ai phân biệt được *"đã review và sạch"* với *"chưa từng review"*. Caller dùng sha này làm bằng chứng.

### Có Critical hoặc Important

**Bước 1 — Tổng hợp findings thành tasks:**

Nhóm các findings thành tasks cụ thể có thể implement được. Mỗi finding Critical/Important là ít nhất một task. Đặt tên task bắt đầu bằng động từ, mô tả rõ việc phải sửa.

**Bước 2 — Luôn ghi findings vào techdebt.md:**

Lấy short SHA hiện tại: `git rev-parse --short HEAD`.

Ghi findings vào `.specs/integrations/{slug}/techdebt.md`.

Nếu file chưa tồn tại, tạo mới từ `.claude/templates/integrations/techdebt-template.md`, điền `slug`, `title`, `created`.

Append section mới vào cuối file (không ghi đè section cũ). Chỉ ghi các axis có ít nhất một Critical/Important finding:

```markdown

## {YYYY-MM-DD} — {short-sha}                                  ← vòng 1
## {YYYY-MM-DD} — {short-sha} (review vòng {k}, tham chiếu {prev-sha})   ← vòng k>1

### Correctness
- [ ] **Critical** · anchor `{anchor}` — {tên ngắn gọn}

### Security
- [ ] **Important** · anchor `{anchor}` — {tên ngắn gọn}

### Performance
- [ ] **Important** · anchor `{anchor}` — {tên ngắn gọn}
```

**`anchor` bắt buộc trên mọi dòng Critical/Important**, lấy từ tập đóng ở section "Phân loại finding". Dòng không có anchor nghĩa là finding đó chưa được phân loại — và nếu thực sự không neo được thì nó **không thuộc file này**, nó là `spec_gap`. Kiểm: mọi hit của `grep -E '^\- \[.\] \*\*(Critical|Important)\*\*' techdebt.md` phải chứa `anchor`.

**Section có ≥1 Critical/Important ⇒ ghi thêm mục `### Đã cân nhắc, không nêu`** ở cuối section đó:

```markdown
### Đã cân nhắc, không nêu
- {điểm} — {vì sao không phải Important: anchor nào cho phép / là style / đã có test}
```

Một dòng cho mỗi điểm, **không checkbox** — đây là ghi chú, không phải nợ. Nó tồn tại vì reviewer là subagent mới mỗi vòng: quyết định *"đã nhìn và bỏ qua"* mất theo subagent thì vòng sau nêu lại thứ vòng trước đã cân nhắc, và nhìn từ ngoài giống như build vừa làm hỏng cái gì.

Chỉ ghi khi vòng đó **có** Critical/Important: chỉ vòng có nợ mới có vòng sau cần đọc, còn vòng sạch thì kết thúc loop. Nhờ vậy luật *"sổ nợ chỉ ghi khi có nợ"* còn nguyên — không có ca nào file được tạo ra chỉ để chứa ghi chú.

**Đừng để nó phình thành một bài review thứ hai.** Một dòng/điểm, và chỉ những điểm thật sự **cân nhắc rồi bỏ**, không phải mọi thứ đã đọc qua.

> Details đầy đủ nằm ở Phase Review trong `plan.md` (nếu user chọn thêm phase), hoặc trong output của `/review-integration` lúc đó.

**Bước 3 — Đề xuất thêm phase mới vào plan.md và todo.md:**

Hiển thị preview phase sẽ được thêm:

```
Phát hiện {N} Critical / {M} Important findings. Đã lưu vào techdebt.md.
Đề xuất thêm phase mới để fix ngay:

Phase Review: Fix review findings

  T0XX · Fix {mô tả finding 1}
  T0XY · Fix {mô tả finding 2}
  ...

Thêm phase này vào plan.md và todo.md, rồi chạy /build để fix?
```

Hỏi user bằng `AskUserQuestion`:

```
question: "Thêm phase Review vào plan.md/todo.md?"
options:
  - label: "Thêm phase và chạy /build"
    description: "Thêm các tasks fix findings vào plan.md và todo.md, rồi gọi /build để thực thi"
  - label: "Thêm phase nhưng không chạy /build"
    description: "Chỉ cập nhật plan.md và todo.md, tự chạy /build sau"
  - label: "Để sau"
    description: "Findings đã được lưu vào techdebt.md, xử lý sau"
```

**`[--auto]`** Không hỏi — mặc định **option 1** ("Thêm phase và chạy `/build`") *về phần thêm phase*, nhưng **KHÔNG tự invoke `/build`** (xem Bước 5). Nghĩa là: append Phase Review vào `plan.md` + `todo.md` rồi kết thúc, để caller quyết định có chạy vòng build tiếp hay không. `/review-integration` không cầm luật loop.

**Bước 4 — Nếu user chọn "Thêm phase" (cả hai option đầu):**

Xác định số phase tiếp theo từ plan.md (đếm số `### Phase` hiện có, cộng 1).

Xác định **số vòng review** `k`: đếm heading khớp `^### Phase [0-9]+: Review Findings` trong `plan.md`, cộng 1. Chỉ neo vào tiền tố đó — **không** neo vào phần `(lần …)`, để plan.md sinh trước quy ước này (heading trần, không có `(lần k)`) vẫn được đếm đúng.

Xác định task ID tiếp theo từ plan.md (lấy task ID lớn nhất hiện có, cộng 1).

Append vào `plan.md` (trước section `## Definition of Done`):

```markdown
### Phase {N}: Review Findings (lần {k})

#### T{XXX} · {task title — bắt đầu bằng động từ}

**Mục tiêu:** {mô tả finding cần fix}

**depends:** {task ID cuối cùng trước phase này}

**resolves-techdebt:** {YYYY-MM-DD} — {short-sha}

**Các bước:**
1. {bước fix cụ thể từ finding}

**Verification:**
- [ ] {điều kiện verify finding đã được fix}

---
```

Append vào `todo.md`:

```markdown
### Phase {N}: Review Findings (lần {k})
- [ ] T{XXX} — {mô tả task fix}
```

`(lần {k})` là **bộ đếm vòng review nằm trong file**, không nằm trong đầu ai. Nhờ vậy một caller chạy lại giữa chừng vẫn biết đã review mấy vòng — điều kiện để có luật dừng "tới vòng thứ 3 thì trả người".

**Bước 5 — Nếu user chọn "Thêm phase và chạy /build":**

Sau khi cập nhật xong plan.md và todo.md, invoke ngay `/build` để thực thi phase Review vừa thêm.

**`[--auto]`** **Không** invoke `/build`. Cập nhật `plan.md` + `todo.md` rồi return (xem dưới). Trong chế độ auto, ai gọi vòng build tiếp là việc của caller — `/review-integration` tự gọi `/build` thì có hai chỗ cùng cầm luật loop, và không chỗ nào đếm được số vòng.

**Bước 5 — Nếu user chọn "Để sau":**

Thông báo:

```
Findings đã được lưu vào .specs/integrations/{slug}/techdebt.md.
Chạy /review-integration lại hoặc /build khi sẵn sàng xử lý.
```

### Có `spec_gap`

**Độc lập với hai nhánh trên** — một lượt review có thể vừa có Critical/Important vừa có `spec_gap`, hoặc chỉ có `spec_gap` (khi đó verdict vẫn là **sạch**).

**Sổ nợ của BA là một sổ duy nhất của mỗi feature, cạnh `frd.md`** — `.specs/main/feature/{F-XXX}-{slug}/spec-debt.md` ([`02-artifacts.md §2.3`](../../02-artifacts.md), [`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)). Không có sổ của integration, không có bản sao. Hình dạng mục, dòng `**phát hiện:**` và luật viết nằm ở comment của `.claude/templates/main/feature/spec-debt-template.md` — đọc trước khi ghi.

**Sổ kiểu cũ còn sót ⇒ vẫn ghi sổ mới, và cảnh báo.** `find .specs/integrations .specs/tests -name spec-debt.md 2>/dev/null` ra file nào ⇒ in `⚠ Sổ nợ spec kiểu cũ: {đường dẫn} — chạy: npx spec-lite migrate-spec-debt` ở output, rồi ghi mục vào sổ cạnh `frd.md` như bình thường. **Không** dừng ghi: review chạy trong `/implement` không có ai trả lời, dừng là gap/drift vừa thấy không vào sổ nào — nợ chìm. Lệnh chuyển sổ gộp mục cũ vào mục mới cùng `{ID}`, nên ghi trước chuyển sau không đẻ mục trùng. Bước 0 chỉ dò sổ mới — mục chỉ nằm ở sổ cũ thì gộp lúc chuyển.

**Bước 0 — Chọn sổ, dò mục đã có.** `{F-XXX}` = feature mang ID **đầu tiên** bạn ghi ở `**gần nhất:**`; ID đó phải thuộc một feature trong `features:` của `spec.md`. Không ghi nổi ID nào như vậy ⇒ đó không phải gap của đợt này — xếp lại theo bảng phân loại. Đọc các mục `- [ ] **SG-` của sổ có cùng ID đầu ở `**gần nhất:**`: cùng hiện tượng ⇒ **không** mở mục mới, không tính vào `spec_gap`; mục đó chưa có dòng phát hiện nào chứa `` của `{slug}` `` ⇒ thêm **một** dòng vào cuối danh sách `**phát hiện:**` (dạng ở Bước 1), không sửa mô tả hay câu hỏi. Không có ⇒ Bước 1.

**Bước 1 — Mở mục.** Sổ chưa có ⇒ tạo từ `.claude/templates/main/feature/spec-debt-template.md`, điền `{F-XXX}-{slug}` = tên thư mục feature, `{title}` = tên feature ở H1 của `frd.md`, bỏ tiền tố `Feature:`, `{YYYY-MM-DD}`. Số `SG-{n}` = ID `SG` lớn nhất **đã từng** có trong sổ (kể cả `[x]`) + 1 — append-only, không tái dùng, không renumber.

```markdown
- [ ] **SG-{n}** — {hiện tượng: người dùng làm gì, hệ làm gì, spec không nói gì về chỗ đó}
  - **phát hiện:**
    - ③ Build — review vòng {k} của `{NNN}-{slug}` · `{short-sha}` · {YYYY-MM-DD}
  - **gần nhất:** `{AC/US/VR gần nhất}` · …
  - **câu hỏi cho BA:** {cần quyết điều gì — không liệt kê đáp án}
```

**Mục chỉ nêu hiện tượng — người quyết là BA.** Mô tả bằng chữ người dùng thấy: thao tác, thông báo, mã HTTP. **Không** dùng ký tự `→` trong mô tả — `→` ngay sau số mục là con trỏ `→ {slug}`, và phép đếm *chưa quyết / đang làm* dựa vào nó. **Không** tên hàm, biến, file — BA đọc sổ này, không đọc code; reviewer cần trỏ code thì trỏ ở output báo. Không chữ đánh giá (*nên* · *có vẻ* · *hợp lý hơn* · *đúng/sai*), không đề xuất giải pháp — viết "nên trả 400" là thiết kế sản phẩm thay BA. Câu hỏi nêu cần quyết điều gì, **không** liệt kê đáp án: "trả 400 hay bỏ qua?" là reviewer khoanh sẵn hai lựa chọn cho BA.

**Bước 2 — KHÔNG làm gì thêm:**

- **Không** tạo task, **không** append Phase Review — gap là nợ của BA, `/build` không trả được nó.
- **Không** chặn verdict. Code đã đúng với spec approved; chặn merge vì spec thiếu là giữ integration làm con tin.
- **Không** ghi vào `techdebt.md` — trộn hai sổ nợ là bắt dev nhìn việc nó không có quyền quyết (xem [`02-artifacts.md §3.8`](../../02-artifacts.md) và §2.3 `spec-debt.md`).
- Skill này **không** commit. Sổ nằm ngoài `.specs/integrations/{slug}/`; ai commit kết quả review (`/implement`, hoặc người gõ tay) thì commit sổ cùng các artifact review khác.

**Bước 3 — Báo:**

```
Spec gap: {g} — đã ghi .specs/main/feature/{F-XXX}-{slug}/spec-debt.md
  SG-{n} — {mô tả một dòng}
👤 /spec-new {F-XXX} để BA quyết gap nào lên spec.
```

`/spec-new {F-XXX}` là **cửa đóng duy nhất**: nó liệt kê `SG-*` còn `[ ]`, cho chọn/từ chối, rồi ghi ngược trạng thái. `/review-integration` chỉ **mở** mục hoặc thêm dòng phát hiện, không bao giờ đóng.

### Có `spec_drift`

**Độc lập với các nhánh trên**, cùng sổ và cùng luật viết với `spec_gap` — một lượt review có thể vừa có Critical/Important, vừa có gap, vừa có drift; chỉ có drift thì verdict vẫn là **sạch**. Sổ kiểu cũ còn sót ⇒ vẫn ghi sổ mới và cảnh báo, như ở §Có `spec_gap`.

**Bước 0 — Sổ của feature đã có chỗ lệch này chưa.** Feature của ID lấy từ tiền tố (`AC-F009-001` ⇒ `F-009`):

```bash
grep -rnE --include=spec-debt.md "^- \[ \] \*\*SD-[0-9]+\*\* · \`${ID}\`" .specs/main/feature 2>/dev/null
```

Dùng `grep -r --include`, **không** glob `*/spec-debt.md`: glob không khớp gì thì zsh dừng hẳn.

Có mục mở ⇒ **không** mở `SD` nào, không tính vào `spec_drift`. Mục chưa có dòng phát hiện nào chứa `` của `{slug}` `` ⇒ thêm **một** dòng `` ③ Build — review vòng {k} của `{slug}` · `{short-sha}` · {date} `` vào cuối danh sách `**phát hiện:**`; hiện tượng vòng này khác mô tả của mục ⇒ thêm một vế ngắn sau `·` ở chính dòng đó. Không sửa mô tả, dấu vết, câu hỏi. Nói ra bằng dòng `ⓘ` ở output; vòng có Critical/Important thì dòng đó vào thêm `### Đã cân nhắc, không nêu` của section vòng này. Không có mục mở ⇒ Bước 1.

**Bước 1 — Mở mục** ở sổ của feature mang tiền tố của `{ID}` (sổ chưa có ⇒ tạo như §Có `spec_gap` Bước 1). Số `SD-{n}` = ID `SD` lớn nhất **đã từng** có trong sổ + 1 — bộ đếm **riêng** với `SG`. Append-only.

```markdown
- [ ] **SD-{n}** · `{AC|VR|FAC-ID}` — {hiện tượng: người dùng làm gì, hệ làm gì} · {ID} nói {gì}
  - **phát hiện:**
    - ③ Build — review vòng {k} của `{NNN}-{slug}` · `{short-sha}` · {YYYY-MM-DD}
  - **dấu vết:** {comment ở `file:dòng` / commit `{short-sha}` / section của nguồn đã duyệt} — "{trích nguyên văn}"
  - **câu hỏi cho BA:** giữ {ID} hay đổi {ID} theo hành vi hiện tại?
```

- **Đúng một** ID trên dòng chính, trong backtick, ngay sau `·`. `/fix-findings` grep đúng dòng này để biết ID đó đang chờ BA — ID nằm ở sub-bullet là grep trượt, và ④ Verify sửa mất code trước khi BA quyết. Một chỗ lệch chạm hai AC ⇒ hai `SD`.
- `**dấu vết:**` **bắt buộc** và phải **trỏ được** — comment ở file nào, commit nào, section nào của nguồn nào — kèm **trích nguyên văn**. Không diễn giải thành lý lẽ: "dev muốn người dùng đỡ phiền" là diễn giải, câu commit trong ngoặc kép mới là dấu vết. Không trỏ được ⇒ quay lại xếp severity (trục thứ sáu).
- Mô tả theo luật viết của §Có `spec_gap`: hiện tượng, chữ người dùng thấy, không tên hàm; `file:dòng` chỉ được ở `**dấu vết:**`. **Không đề xuất** bên nào đúng.

**Bước 2 — KHÔNG làm gì thêm:** không task, không Phase Review, không ghi `techdebt.md` (trừ dòng `ⓘ` của Bước 0, và chỉ khi vòng đó đã có section vì Critical/Important), không chặn verdict, không sửa `spec.md`.

**Bước 3 — Báo:**

```
Spec drift: {d} — đã ghi .specs/main/feature/{F-XXX}-{slug}/spec-debt.md
  SD-{n} · {ID} — {mô tả một dòng}
👤 /spec-new {F-XXX} để BA chọn giữ requirement hay đổi requirement theo code.
Trong lúc chưa quyết, ④ Verify không sửa code của {ID}.
```

---

## Đánh dấu techdebt đã resolved

Khi `/build` hoàn thành **thành công** một Phase Review, nó phải tìm và mark các techdebt findings tương ứng là resolved.

**Cơ chế liên kết:** Khi append Phase Review vào `plan.md` (Bước 3 ở trên), thêm field `resolves-techdebt` vào task đầu tiên của phase, trỏ đến section date trong techdebt.md:

```markdown
#### T{XXX} · Fix {mô tả finding 1}

**Mục tiêu:** {mô tả finding cần fix}

**depends:** {task ID cuối cùng trước phase này}

**resolves-techdebt:** {YYYY-MM-DD} — {short-sha}

**Các bước:**
...
```

**Khi `/build` hoàn thành Phase Review:**

1. Đọc field `resolves-techdebt` từ task đầu tiên của Phase Review trong `plan.md`
2. Tìm section tương ứng trong `techdebt.md` (match theo `## {YYYY-MM-DD} — {short-sha}`)
3. Với mỗi dòng `- [ ]` trong section đó → đổi thành `- [x]` và append ` *(resolved by T{XXX})*`:

```markdown
## 2026-05-08 — abc1234

- [x] **Critical** — {mô tả finding 1} *(resolved by T005)*
- [x] **Important** — {mô tả finding 2} *(resolved by T005)*
```

4. Nếu không tìm được field `resolves-techdebt` hoặc không tìm được section trong techdebt.md → bỏ qua, không báo lỗi.

---

## `[--auto]` — return có cấu trúc

Kết thúc bằng **đúng năm field**, không kèm prose findings:

```
{ critical: 2, important: 1, spec_gap: 1, spec_drift: 0, reviewed_sha: "abc1234" }
```

- `critical` / `important` — **số lượng** finding mỗi mức. Nit/Optional/FYI **không** vào đây: chúng không được phép kéo dài vòng lặp.
- `spec_gap` — **số lượng** `SG-*` **mới mở** ở lượt này (thêm dòng phát hiện vào mục đã có **không** tính). Đây là **thông tin**, không phải tín hiệu rẽ nhánh: caller in nó ra và ghi vào log, nhưng nó không mở vòng build và không chặn `done`.
- `spec_drift` — **số lượng** `SD-*` **mới mở** ở lượt này, cùng luật đếm (trước [`.docs/036`](../../.docs/036-spec-drift-vao-spec-debt.md) là bool và làm caller dừng). Cùng vai với `spec_gap`: **thông tin**, không rẽ nhánh, không mở vòng build, không chặn `done`.
- `reviewed_sha` — `git rev-parse --short HEAD` **lúc review**. Bắt buộc ở **mọi** nhánh, kể cả sạch.

Chi tiết findings **không** nằm trong return — chúng ở `techdebt.md` (mức Critical/Important), sổ `spec-debt.md` của feature (`SG-*` · `SD-*`) và Phase Review của `plan.md`. Caller chỉ rẽ nhánh theo `critical` + `important`.

`reviewed_sha` là mắt xích để kiểm từ bên ngoài: `reviewed_sha != HEAD` nghĩa là code đã đổi **sau** lần review cuối, nên dù log có ghi gì thì workflow vẫn chưa hoàn tất.
