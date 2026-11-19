---
name: fix-findings
description: Sửa code sản phẩm cho finding `bug-code` của MỘT feature — đọc §2 Findings của test-report-{scope}.md, sửa đúng thứ câu chữ VR/AC/FAC đòi, commit trên branch fix/verify-{F-XXX} không merge, ghi sổ .progress/fix.md. Ra ngoài câu chữ requirement — hoặc requirement đang có spec_drift mở chờ BA quyết — thì TỪ CHỐI có ghi lý do, không đoán. KHÔNG chạm test code, KHÔNG chạm test-report*, KHÔNG chạm frd/test-design. Chạy độc lập hoặc do /verify-v2 gọi trong vòng lặp.
---

# fix-findings

## Overview

Ba tầng retrofit **tìm và ghi** vấn đề, không sửa ([06-testing §12](../../06-testing.md)). Bản đồ `Loại → PIC` ([test-core §7.4](../../references/retrofit-core.md)) khoanh sẵn ba nhãn `🤖`, và chỉ **một** trong ba chạm **code sản phẩm**: `bug-code`. Skill này làm đúng nhãn đó. Hai nhãn còn lại (`test-error` · `flaky`) sửa **test code** — remit của skill tầng, gọi lại tầng đó `--mode full`.

Lý do `bug-code` thuộc `🤖`: *"oracle đúng đã có trong VR/AC/FAC; sửa code xong test xanh là bằng chứng đủ"*. Skill này sống hay chết theo vế đầu — **oracle là câu chữ requirement**, không phải cột `Action` của report, không phải suy đoán về ý đồ.

Thiết kế: [`.docs/032`](../../.docs/032-verify-fix-loop.md) `DS1`–`DS3`.

## When to Use

- Roll-up `test-report.md` §3 có dòng `PIC = 🤖` nhãn `bug-code` và muốn máy xử.
- `/verify-v2` gọi trong vòng lặp (bước giữa Bước 3 và Bước 4).
- Muốn xem trước máy sẽ đụng gì mà chưa cho ghi → `--dry-run`.

## When NOT to Use

- Finding là `test-error`/`flaky` → gọi lại **skill tầng** đó `--mode full`. Sửa test code ở đây là hai writer trên cùng file.
- Finding là `spec-drift` → `👤 BA`, quyết ở `/spec-new {F-XXX}` trên sổ `spec-debt.md` của feature. `need-clarify` → `👤 BA`, `/spec-new` cập nhật `frd` + cascade.
- Finding `bug-code` mà requirement của nó có mục `SD-*` **mở** trong sổ `spec-debt.md` của feature → skill vẫn chạy nhưng **từ chối** finding đó (Bước 2.2, `spec-debt-mở`). BA quyết trước ở `/spec-new {F-XXX}`.
- Finding là `harness`/`refactor` → `👤 DEV`. Vùng đóng băng: agent **không** tự nâng `👤` thành `🤖`.
- Chưa chạy tầng nào → không có §2 để đọc. Chạy `/verify-v1 {F-XXX}` trước.

## Cờ trong ARGUMENT

```
/fix-findings {F-XXX} [--scope=validation|functional|e2e] [--dry-run]
```

| Cờ / arg | Nghĩa | Vắng thì |
|---|---|---|
| `F-XXX` | feature cần sửa | bắt buộc |
| `--scope=` | chỉ đọc §2 của scope đó | mọi scope có `FIND-*` nhãn `bug-code` |
| `--dry-run` | in việc sẽ sửa + **nguyên văn** câu requirement tương ứng, rồi dừng. Không ghi gì — kể cả sổ, kể cả branch | ghi thật |

`--scope=nfr` / `--scope=dm` ⇒ **lỗi, dừng**: hai scope đó chưa có writer nào ghi result, nên không có §2 để đọc.

---

## Quy trình

### Bước 0 — tiền đề

1. Resolve `{F-XXX}` → `.specs/tests/{F-XXX}-{slug}/`. Không có thư mục ⇒ dừng, báo chạy `/verify-v1 {F-XXX}` trước.
2. Đọc `frd.md` — cần nó để lấy **câu chữ** requirement ở Bước 2. Không có ⇒ dừng.
3. **Chụp `git status --porcelain`.** Cây bẩn sẵn **không** làm dừng — nhưng nó quyết cách commit ở Bước 4: chỉ `git add` **đúng đường dẫn skill này sửa**, không bao giờ `git add -A` / `git commit -a`. WIP của người khác không được cuốn vào commit của máy.
4. Branch `fix/verify-{F-XXX}`: chưa có thì tạo từ HEAD hiện tại; đã có **và là hậu duệ của HEAD** (`git merge-base --is-ancestor HEAD {branch}`) thì checkout và commit tiếp lên nó — không xoá, không đặt tên mới. **Không phải hậu duệ** (lượt trước chạy trên trạng thái mà bed reset đã thay) ⇒ đổi tên branch cũ thành `{branch}-{n}` để giữ bằng chứng rồi tạo mới từ HEAD; checkout thẳng là cuốn ngược cả cây làm việc. Vạch xuất phát do bed script dựng; branch là nơi người review đọc. Tạo **lười**: chỉ khi Bước 1 tìm được ít nhất một `bug-code`. Không có gì để sửa ⇒ không đẻ branch. Lưu ý cho người gọi: từ lúc branch tồn tại, HEAD đứng ở đó — commit của bất cứ skill nào chạy sau cũng rơi vào branch ấy.

### Bước 1 — gom finding từ **hai** nguồn

1. Glob `test-report-*.md` **trừ** roll-up `test-report.md` (roll-up không có §2 chi tiết). Với mỗi file, đọc §2 `Findings`, giữ dòng `Verdict = bug-code`.
2. `git log --format='%s%n%b' fix/verify-{F-XXX} --not {branch gốc}` → mọi `FIND-*` từng xuất hiện trong commit message của branch này.

⚠ **Vừa đổi tên branch ở Bước 0.4 thì nguồn 2 đọc ở tên CŨ.** `git log fix/verify-{F-XXX}` trên một branch vừa tạo mới là rỗng — lịch sử nằm ở `fix/verify-{F-XXX}-{n}`. Đọc tên mới ⇒ mọi kết luận của lượt trước biến mất khỏi sổ. Nhưng chỉ chép sang những `FIND-*` mà §2 **không** bắt lại: sau một lượt bed reset, finding quay về 🔴 nên nguồn 1 đã đủ, và kết luận cũ mô tả code **trước** reset.

⚠ **Thiếu nguồn 2 thì sổ nói dối ở lượt sau.** §2 `Findings` chỉ chứa TC **đang 🔴** — finding nào đóng rồi thì **rời bảng** (đo được 2026-09-10 trên `F-004`: sửa `FIND-VAL-01` xong, tầng chạy lại, §2 của `validation` còn **0** dòng). Dựng sổ chỉ từ §2 ⇒ lượt sau ghi đè mất chính dòng `fixed` mình vừa ghi, và sổ trượt phép thử *"xoá file đi rồi chạy lại phải dựng lại y nguyên"* của template. Commit message là chỗ duy nhất giữ được — nên **Bước 4.4 bắt buộc ghi `FIND-*` vào message**, đó không phải trang trí.

**Sổ luôn phủ cả feature, `--scope=` chỉ giới hạn thứ lượt này *ra tay*.** Liệt kê hết finding của mọi scope; cái ngoài `--scope=` in nguyên trạng kết luận cũ đọc từ nguồn 2. Lọc cả danh sách theo `--scope=` là lượt `--scope=e2e` xoá kết luận của lượt `--scope=validation` trước đó.

**Gộp dòng `dup-of` về gốc.** `dup-of` trỏ về `FIND-*` của tầng trước, cùng nguyên nhân ⇒ **cùng một chỗ trong code**. Sửa một lần. Nhưng **ghi cả hai ID** vào sổ và vào commit message — người đọc phải thấy một chỗ sửa đóng hai finding, nếu không họ đi tìm chỗ sửa thứ hai.

Không dòng nào ⇒ in `không có bug-code nào để sửa`, **không** tạo branch, **không** tạo sổ, dừng sạch.

### Bước 2 — với mỗi finding: đọc oracle rồi mới quyết

Thứ tự này bắt buộc, không đảo:

1. Cột `Covers` → ID requirement. Mở `frd.md`, đọc **nguyên văn** câu của ID đó.
2. **ID đó có đang chờ BA không** ([`.docs/036`](../../.docs/036-spec-drift-vao-spec-debt.md) · [`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)). Sổ nợ của BA là **một sổ duy nhất của feature**, cạnh `frd.md`. Với **mỗi** ID trong `Covers`, tra cùng lệnh với tầng retrofit ([retrofit-core §5](../../references/retrofit-core.md)):

   ```bash
   grep -rhE --include=spec-debt.md "^- \[[ x]\] \*\*SD-[0-9]+\*\* · \`${ID}\`" .specs/main/feature .specs/removed 2>/dev/null
   ```

   **Gặp sổ kiểu cũ ⇒ dừng cả lượt, trước Bước 1.** `find .specs/integrations .specs/tests -name spec-debt.md 2>/dev/null` ra file nào ⇒ in `Sổ nợ spec kiểu cũ: {đường dẫn} — chạy: npx spec-lite migrate-spec-debt`, không sửa gì: một `SD` mở nằm ở sổ cũ là khoá mà skill này không thấy.

   Mục quyết là `- [ ] **SD-`, **có hay không có con trỏ `→`** ⇒ **từ chối ngay**, `refused=spec-debt-mở`, **không** đọc code, **không** sửa — ghi kèm `SD-n` + feature của sổ (`{F-XXX}-{slug}`). Lý do: đã có người ghi rằng code làm khác `{ID}` **có dấu vết**, một trong hai bên sai và BA chưa chọn. Sửa lúc này là viết lại code có thể đang đúng cho khớp requirement có thể đang sai — đúng ca *bằng chứng giả* ở dưới, chỉ khác là lần này kit **biết trước**.
   - Có `→` nghĩa là BA chọn sửa requirement theo code; sửa code lúc này là đi ngược quyết định đó.
   - Mục quyết là `- [x] … **giữ spec:**` ⇒ finding là `bug-code` thường, đi tiếp bước 3. Đó là đường mở khoá duy nhất.
   - Skill này **chỉ đọc** sổ — không thêm dòng phát hiện, không mở mục. Ghi sổ là việc của review và tầng retrofit.
   - Thường tầng retrofit đã xếp finding đó là `spec-drift` nên nó không tới đây; bước này là lớp chặn thứ hai cho ca tầng xếp nhầm.
3. Cột `Evidence` → chỗ trong code. Mở đọc.
4. Cột `Action` → **giả thuyết**, không phải lệnh. Tầng đã thử nó lúc sanity-red rồi revert, nên nó thường đúng — nhưng nó là phán đoán của tầng về **cách sửa**, còn thứ ràng buộc skill này là **câu chữ ở bước 1**. `Action` mâu thuẫn câu chữ ⇒ theo câu chữ, và ghi mâu thuẫn đó vào sổ.
5. Quyết: sửa được trong phạm vi câu chữ đó, hay từ chối.

### Bước 3 — phạm vi được sửa

| Ca | Được làm | Từ chối khi |
|---|---|---|
| hành vi **có** code, sai | đổi hành vi cho khớp **đúng câu chữ** requirement | phải suy diễn ngoài câu chữ — thêm rule, đổi hợp đồng, đoán giá trị biên ⇒ `ngoài-câu-chữ` |
| sửa trong seam TC đang bám | vá tại chỗ | phải tách/di chuyển seam ⇒ `cần-tách-seam` (đó là `refactor` → `👤 DEV`) |
| hành vi **chưa có** code | viết phần thiếu **khi** requirement đã định chỗ gắn và hợp đồng — tên hàm/route/field đã tồn tại, chỉ thiếu nhánh | phải thiết kế cấu trúc mới mà requirement không mô tả (component nào, tương tác gì, tham số hình gì) ⇒ `nhiều-cách-thoả` |

Bốn lý do từ chối là **tập đóng**: `ngoài-câu-chữ` · `cần-tách-seam` · `nhiều-cách-thoả` (ba cái của bảng trên) · `spec-debt-mở` (Bước 2.2 — quyết **trước** khi đọc code, không phải phán đoán về code). Không đẻ lý do thứ năm — gặp ca không xếp được vào ba cái này thì đó là tín hiệu phân loại của tầng sai, ghi ra và để `👤`.

⚠ **Ca hay gặp nhất của `nhiều-cách-thoả` không phải "câu chữ hai nghĩa".** Spec mơ hồ bị bắt từ bước design thành `need-clarify`, nó không tới được đây. Ca thật là **hành vi chưa có gì cả**: oracle rõ, nhưng code không có chỗ nào để sửa, nên "sửa" = quyết một hợp đồng mới.

**Vì sao phải khoá chặt thế:** `bug-code` vs `spec-drift` là **phán đoán** của tầng, không phải số đo. Tin sai mà sửa vượt phạm vi thì code đang đúng bị viết lại cho khớp một spec đang sai — và test xanh sau đó là **bằng chứng giả**, không ai bắt được nữa. Cùng luật với review ở ③ Build ([`/review-integration`](../review-integration/SKILL.md)): `spec_drift` ghi vào sổ nợ của BA, **không** đẻ task fix.

### Bước 4 — sửa, kiểm, commit

1. Sửa code sản phẩm. **Sửa nhỏ nhất đủ thoả câu chữ** — không dọn dẹp tiện tay, không đổi tên, không thêm test. Comment **mô tả chính dòng vừa sửa** thì thuộc chỗ sửa, không phải dọn tiện tay: để lại một comment nói sai về code ngay dưới nó là tệ hơn xoá. Comment ở chỗ khác thì đừng đụng.
2. Chạy **đúng test của TC đó** để tự kiểm. Xanh là tín hiệu tốt, **không** phải bản ghi: bản ghi chính thức là lượt chạy lại của skill tầng. Không sửa report, không sửa test cho xanh.
3. Đỏ sau khi sửa ⇒ **hoàn nguyên chỗ vừa sửa**, ghi finding đó thành `refused=ngoài-câu-chữ` với ghi chú *"sửa theo câu chữ mà TC vẫn đỏ"* — đó là dấu hiệu oracle và code lệch nhau ở chỗ khác, việc của người.
4. Commit: **một commit cho một chỗ sửa** (một chỗ đóng hai finding thì vẫn một commit, message ghi cả hai ID). `git add` **liệt kê đường dẫn**, không `-A`. Message **phải** chứa mọi `FIND-*` mà commit này đóng — Bước 1 nguồn 2 đọc lại từ đây.
5. Sổ đi **commit riêng**, sau commit code: dòng `fixed` mang `sha` của commit sửa nên nó không nằm trong chính commit đó được. Luật *"một commit cho một chỗ sửa"* nói về **code**, không cấm commit sổ.
6. Quy ước của **repo** (changelog, hook, CI) không phải việc của skill này — người gọi commit chúng ngoài các commit trên, để số đo *"skill chỉ chạm code sản phẩm + `fix.md`"* còn đọc được.

```
fix(F-004): validateTagName chặn đúng mốc 24 ký tự của VR-F004-001

FIND-VAL-01 — code nhận tên 25 ký tự, VR-F004-001 nói tối đa 24.
Đổi `>=` thành `>` ở chốt MAX_TEN.

Sửa bởi /fix-findings — chưa merge, chờ người review.
```

### Bước 5 — ghi sổ rồi trả về

Dựng lại **trọn** `.progress/fix.md` (xem *Đơn vị tiến độ*), rồi trả:

```
{ fixed: [FIND-…], refused: [{id, reason}], touched: [file:symbol], blocked: null | "lý do" }
```

`touched` là thứ `/verify-v2` dùng để chọn `--mode execute` hay `--mode full` — ghi **file : symbol**, đủ để so với cột wiring của `test-exec-{scope}`.

---

## Đơn vị tiến độ

Sổ của skill này: `.specs/tests/{F-XXX}-{slug}/.progress/fix.md` — **writer duy nhất là skill này**; KHÔNG đọc, KHÔNG ghi sổ của skill khác. Dựng lại **trọn** mỗi lượt rồi ghi đè. Hình dạng + frontmatter: [`templates/tests/verify-progress-template.md`](../../templates/tests/verify-progress-template.md); định nghĩa thư mục: [`02-artifacts.md §4.7`](../../02-artifacts.md).

**Hạt là một dòng / `FIND-*` nhãn `bug-code`** — gốc và dòng `dup-of` của nó gộp về **một** dòng.

**Việc lớn** — `- [ ] /fix-findings   fixed {a} · refused {b}` — tick khi **mọi** `FIND-*` `bug-code` đều đã có kết luận: một dòng việc nhỏ `[x] … → fixed {sha}`, hoặc một bullet `⚠ … refused`. **Lượt chỉ toàn `refused` vẫn tick `[x]`** — đã thử là đã trả tiền; để `- [ ]` là dựng đúng cái bẫy dispatch vô hạn mà [031](../../.docs/031-verify-workflow.md) `D19` chặn.

| Việc nhỏ | Đọc file / field | Xong khi |
|---|---|---|
| `FIND-…  {symbol}` — 1 dòng / finding `bug-code` | §2 `Findings` của mọi `test-report-{scope}.md` | có commit trên `fix/verify-{F-XXX}` chạm đúng `touched` của finding đó |
| *(không tick được)* `⚠ FIND-… refused ({lý do}): {câu}` | phán lại từ câu chữ requirement mỗi lượt | — bullet trần, **không** có ô tick |

```markdown
- [x] /fix-findings   fixed 3 · refused 1
  - [x] FIND-VAL-01  validateTagName        → fixed  b7c8d9e
  - [x] FIND-FUN-01  deleteTag              → fixed  b7c8d9e
  - [x] FIND-FUN-02  useTagFilter           → fixed  c1d2e3f
- ⚠ FIND-E2E-01 refused (nhiều-cách-thoả): FAC-F004-001 đòi user gắn nhãn vào việc,
    không component nào gọi useTags.attach và FAC không nói control hình gì → 👤 BA
- ⚠ FIND-FUN-02 refused (spec-debt-mở): AC-F008-001 đang chờ BA — SD-1 của
    008-todo-hoan-viec → 👤 BA /spec-new 008-todo-hoan-viec
```

**Vì sao refusal là bullet trần chứ không phải dòng `[ ]`:** một `- [ ]` không bao giờ tick được làm luật resume trỏ con trỏ vào đây mãi và orchestrator dispatch lại vô hạn — đúng bẫy [031](../../.docs/031-verify-workflow.md) `D19` chặn. Refusal vẫn **derive được** (cùng câu chữ ⇒ cùng kết quả) nên nó thuộc sổ, chỉ là ở hình dạng không tick.

**Cấm đưa vào sổ:** verdict của finding (§2 là của skill tầng — [030](../../.docs/030-test-report-per-scope.md) `D22`) · dòng `step=` (biên bản là của orchestrator) · số vòng lặp (của `/verify-v2`, ở `verify.run.log`).

## Hậu điều kiện

- Mọi `FIND-*` `bug-code` trong phạm vi `--scope=` đều có kết luận trong `.progress/fix.md`.
- Mọi dòng `fixed` có `sha` trỏ một commit **có thật** trên `fix/verify-{F-XXX}` (`git cat-file -e {sha}^{commit}`).
- `git status --porcelain` không có thay đổi **mới** chưa commit ở đường dẫn skill này chạm.
- Branch `fix/verify-{F-XXX}` **chưa** merge, **chưa** mở PR.
- Không file nào ngoài code sản phẩm + `.progress/fix.md` bị skill này ghi.

## Ràng buộc

- **KHÔNG ghi:** test code · `test-report*` (gồm roll-up) · `frd.md`/`test-design.md` · `test-exec-*` · `selector-contract.md` · `.progress/verify.md` và 5 sổ của skill khác.
- **KHÔNG ghi `spec-debt.md`** — chỉ đọc (Bước 2.2). Sổ đó của BA, một sổ mỗi feature cạnh `frd.md`: `/review-integration` và tầng retrofit mở mục hoặc thêm dòng phát hiện, `/spec-new` + `/archive` đóng.
- **KHÔNG nâng pin**, không dựng lại roll-up — đó là việc của skill tầng khi nó chạy lại.
- **KHÔNG merge, KHÔNG mở PR.** Human gate cuối phải còn: đây là code sản phẩm bị sửa tự động.
- **KHÔNG `git add -A` / `git commit -a`** — liệt kê đường dẫn.
- **KHÔNG dựng harness, KHÔNG refactor cấu trúc.** Cả hai là `👤 DEV`.
- **KHÔNG sửa test cho xanh**, không chỉnh verdict, không có cửa hậu green.
- **KHÔNG đoán khi câu chữ không nói** — từ chối rẻ hơn một bằng chứng giả.

## Checklist hoàn thành

- [ ] Bước 0: `frd.md` có · `git status` đã chụp · branch `fix/verify-{F-XXX}` đang đứng
- [ ] Bước 1: đã glob mọi `test-report-{scope}.md`, lọc `bug-code`, gộp `dup-of` về gốc
- [ ] Bước 2: **mọi** finding đã đọc câu chữ requirement **trước khi** quyết — không cái nào quyết từ cột `Action`
- [ ] Bước 2.2: không còn sổ kiểu cũ; mọi ID trong `Covers` đã tra `SD-*` mở trong sổ của feature (`.specs/main/feature` + `.specs/removed`) **trước** khi đọc code
- [ ] Bước 3: mỗi từ chối mang **đúng một** lý do thuộc tập đóng bốn cái
- [ ] Bước 4: mỗi commit chỉ chứa đường dẫn skill này sửa; message ghi đủ `FIND-*` mà nó đóng
- [ ] Bước 5: `.progress/fix.md` dựng lại trọn · mọi `sha` qua `git cat-file -e`
- [ ] Không file nào ngoài code sản phẩm + `.progress/fix.md` bị lượt này ghi (`git status` xác nhận)
