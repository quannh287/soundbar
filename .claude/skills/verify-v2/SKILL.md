---
name: verify-v2
description: Chạy trọn bước ④ Verify của một feature bằng một lệnh, CÓ vòng lặp tự xử việc 🤖 — test-design → test-exec → ba tầng retrofit → /fix-findings sửa bug-code → chạy lại đúng scope bị chạm, lặp tới khi mọi dòng 🤖 đều đã được thử. Có cap 3 vòng và luật "🔴 mở phải giảm thật". Kết thúc bằng bàn giao chỉ còn việc của người. Dùng khi feature đã có code + frd.md approved. Bản không vòng lặp là /verify-v1.
---

# Verify v2

## Tổng quan

Mọi thứ của [`/verify-v1`](../verify-v1/SKILL.md), cộng **một vòng lặp** chèn vào **giữa Bước 3 và Bước 4**: chỗ nào roll-up còn dòng `PIC = 🤖`, máy làm dòng đó rồi chạy lại đúng tầng vừa bị chạm — không chạy lại cả feature.

**Đọc [`references/verify-core.md`](../../references/verify-core.md) trước.** Nó giữ 4 luật bất di · bộ ba số pin/version · gate cây sạch · Bước 0–3 · sổ gộp `.progress/verify.md` · cách đọc roll-up. File này thêm: CLI surface · **Bước 3b (vòng lặp)** · **Bước 4** (hậu điều kiện + exit summary) · luật dừng. Thiết kế: [`.docs/032`](../../.docs/032-verify-fix-loop.md).

**`/verify-v1` vẫn tồn tại và không bị sửa.** Hai entry point cùng chạy trên cùng fixture là cách duy nhất đo được *"chạy tới bàn giao"* so với *"chạy tới chỉ-còn-việc-người"* — v1 là **mốc so**, không phải bản cũ chờ xoá (032 `D10` · `DS8`).

**Ba nhãn `🤖` chia theo ai sở hữu file bị sửa.** `bug-code` sửa **code sản phẩm** ⇒ [`/fix-findings`](../fix-findings/SKILL.md). `test-error`/`flaky` sửa **test code** ⇒ vốn là remit của skill tầng, chạy lại tầng `--mode full` là xong. Trộn hai thứ vào một skill là hai writer trên cùng file test.

## When to Use

- Feature đã có code + `frd.md` `approved`, và muốn máy xử luôn phần `🤖` chứ không chỉ liệt kê ra.
- Vừa chạy `/verify-v1` xong, đọc bàn giao thấy còn dòng `🤖`.
- Lượt trước bị ngắt giữa vòng — gõ lại chính lệnh này.

## When NOT to Use

- Muốn **đọc** trạng thái rồi tự quyết từng finding → `/verify-v1`.
- Muốn đo v1 ↔ v2 → chạy v1 trước trên bed sạch, reset, rồi mới chạy v2.
- Chỉ muốn sửa `bug-code`, không muốn chạy lại tầng → gõ thẳng `/fix-findings`.

## Cờ trong ARGUMENT

```
/verify-v2 {F-XXX | slug-integration} [--scope=validation,functional,e2e] [--auto] [--max-rounds=N]
```

Ba cờ đầu **giống hệt** `/verify-v1` (xem file đó). Thêm:

| Cờ | Nghĩa | Vắng thì |
|---|---|---|
| `--max-rounds=N` | trần số vòng của **lượt gọi này** | `3` |

---

## Quy trình

**Bước 0–3 ở [`references/verify-core.md §3`](../../references/verify-core.md)** — không khác v1 một chữ nào.

Thêm ở Bước 0: **xoá `.progress/verify.run.log`** rồi ghi dòng đầu.

```
- [x] step=begin  sha={HEAD} by=verify-v2 red={🔴 mở của roll-up}
```

### Bước 3b — vòng lặp

Sau khi ba tầng xong và roll-up đã dựng lại, lặp:

| Điều kiện (xét theo thứ tự) | Hành động |
|---|---|
| mọi dòng `🤖` của roll-up §3 có mặt trong `.progress/fix.md` (`fixed` hoặc `refused`) | thoát vòng → Bước 4. **§3 có 0 dòng `🤖` cũng thoả** — và đó là hai ca khác nhau đi chung một điều kiện: *chưa từng có gì để làm* (vào Bước 3b đã 0 dòng ⇒ 0 vòng) và *đã làm hết* (vòng cuối đóng dòng cuối). Dòng `Vòng:` của exit summary phân biệt chúng |
| `grep -c 'step=round' verify.run.log` ≥ `--max-rounds` | dừng `result=stopped reason=k3` |
| `red_before` không nhỏ hơn dòng `step=round` liền trước | dừng `result=stopped reason=no-progress` |
| `git status` có thay đổi **mới** so với ảnh chụp Bước 0 | dừng — **ca 4** luật dừng của v1, nguyên văn |
| còn `test-error`/`flaky` | chạy lại **tầng đó** `--mode full`, quay lại đầu vòng |
| còn `bug-code` chưa thử | spawn **subagent riêng**, prompt nguyên văn `invoke /fix-findings {F-XXX}` — cùng luật với tầng ([core §3](../../references/verify-core.md)): nó đọc `frd` + nhiều report + code rồi sửa và commit, nhồi vào context orchestrator là phí. Đọc `touched` từ giá trị nó trả về → chạy lại scope (dưới) |

**Chọn scope chạy lại: mọi scope mà §2 của nó còn `FIND-*` nhãn `bug-code`, kể cả dòng `dup-of`.**

⚠ **Trừ đi finding mà `fix.md` ghi `refused`.** Finding bị từ chối **ở lại §2 vĩnh viễn** — nó vẫn 🔴, `Loại` vẫn `bug-code`, và `/fix-findings` không được ghi report nên không đổi được gì. Không trừ thì scope đó bị dispatch lại ở **mọi** vòng và **mọi** lượt gõ sau, mua về đúng con số không: đo 2026-09-11 trên `F-004`, lượt `e2e --mode execute` chạy **0 lệnh test** (`FAC-F004-001` vốn `⏭ no-seam`) và chỉ để lại 5 ô `date` đổi. Vòng không lặp vô hạn — điều kiện thoát đọc `fix.md` chứ không đọc §2 — nhưng đó là trả tiền cho một lượt chạy không đổi được gì. Scope nào mà **mọi** `bug-code` còn lại đều đã `refused` thì **bỏ qua**, và nói ra trong exit summary.

Hai phép đếm dễ dùng hơn đều **sai**, và mỗi cái sai một kiểu:

- Đếm theo **dòng action** của roll-up §3: một bug đỏ ở `functional` rồi đỏ lại ở `e2e` chỉ sinh **một** dòng — dòng `dup-of` không sinh action riêng ([test-core §7.3](../../references/retrofit-core.md)) ⇒ scope kia ở lại 🔴 mãi.
- Đếm theo **cột `🔴` của roll-up**: một scope có thể **0 🔴** mà vẫn mang finding mở, vì TC của nó ở `⏭`. Đo được trên `F-004`: `e2e` 0 🔴, `FIND-E2E-01` vẫn mở.

Đọc thẳng §2 của từng file scope bắt được cả hai ca bằng một phép đọc.

**Chọn mode — ba nhánh, không hai:**

| Scope | Mode | Vì sao |
|---|---|---|
| có finding vừa `fixed` ở lượt này (đọc tiền tố `FIND-VAL-*`/`FIND-FUN-*`/`FIND-E2E-*` trong `fix.md`) | `sanity` | giá trị `sanity-red` cũ mô tả **code lúc còn hỏng** (`n/a` = *đỏ sẵn nên không cần mutate*). Sửa xong mà giữ nguyên là TC được đếm pass **chưa từng có bằng chứng nó biết đỏ** — đúng thứ `sanity-red` sinh ra để chặn. `execute ⊂ sanity` nên nó chạy test luôn |
| chạy lại vì còn `bug-code` (thường là dòng `dup-of`) nhưng lượt sửa không đóng finding nào của nó | `execute` | rẻ nhất, chỉ ghi lại cột `Result` |
| chỗ sửa làm **cột wiring trỏ sai** — symbol bị đổi tên, tách ra, dời file, hoặc TC phải bám sang seam khác | `full` | wiring cũ trỏ vào chỗ không còn, cần re-wire + re-prove |

⚠ **Sửa *bên trong* đúng symbol mà wiring đang trỏ tới KHÔNG phải nhánh `full`** — wiring vẫn trỏ đúng chỗ, chỉ thân hàm đổi. Trước 2026-09-11 điều kiện viết là *"`touched` **giao** cột wiring"*, mà giao thì sửa bên trong cũng giao: đo trên `F-004`, cả ba chỗ sửa (`validateTagName` · `deleteTag` · `TodoPage`) đều nằm đúng symbol wiring trỏ tới ⇒ đọc theo chữ thì cả ba scope phải `full`, nuốt sạch hai nhánh rẻ hơn. Phép thử: **mở `test-exec-{scope}` ra, cột wiring của TC còn trỏ tới thứ có thật không?** Còn ⇒ `sanity`/`execute`; không còn ⇒ `full`.

⚠ **Một chỗ cả ba mode đều không dọn được:** cột `Note` của một TC có thể trỏ tới `FIND-*` vừa đóng và rời khỏi §2 — tham chiếu chết ngay trong file. Chỉ `full` ghi cột `Note` (guardrail 4), nên `sanity` để nguyên. Đo được trên `TC-F004-023` (Gate Phase 2). Đây là hình dạng của **report**, không phải của vòng lặp — ghi ra để người đọc report biết, đừng chữa bằng cách nâng mọi lượt lên `full`.

⚠ **Luôn dùng `--mode`, không bao giờ gọi tầng ở dạng no-arg trong vòng lặp.** Sau Bước 3 mọi scope đã current, nên no-arg sẽ bị pin-gate chặn (*"scope current, không có gì cần retrofit"*). `--mode` là **pin-neutral** và đòi scope current — đúng điều kiện đang có ([retrofit-core §1c](../../references/retrofit-core.md) guardrail 1–2).

**Branch `fix/verify-{F-XXX}` tạo *lười*, và cả phần còn lại của lượt sống trên nó.** ⚠ Branch cũ **chỉ** dùng lại được khi nó là **hậu duệ của HEAD hiện tại** (`git merge-base --is-ancestor HEAD {branch}`) — sau một lượt bed reset nó trỏ về trạng thái **trước** reset, checkout là cuốn ngược cả cây và xoá đúng thứ đang đo; lúc đó đổi tên branch cũ rồi tạo mới, và **nói ra** trong exit summary. `/fix-findings` tạo branch ở lần sửa đầu tiên — lượt nào không có `bug-code` thì **không** đẻ branch nào. Nhưng từ lúc nó tồn tại, HEAD đứng ở đó, nên commit của **tầng** chạy lại (report + sổ) cũng rơi vào branch ấy. Đó là hình dạng đúng: branch là *kết quả của một lượt `/verify-v2`*, người review đọc code sửa và bằng chứng test xanh **cùng một chỗ**. Exit summary phải in tên branch để người biết mình đang đứng ở đâu.

Kết mỗi vòng, append:

```
- [x] step=round  sha={HEAD} k={n} red_before={m} fixed={a} refused={b}
```

`fixed={a}` / `refused={b}` đếm **số `FIND-*`**, không phải số chỗ sửa — một commit đóng hai finding thì `a=2`. `fix.md` phải đếm cùng cách, nếu không log và sổ lệch nhau ngay trong một lượt (đo 2026-09-10: log `fixed=2`, sổ `fixed 1`).

`red_before` đo ở **đầu vòng, TRƯỚC khi gọi `/fix-findings`** — tên field nói vậy, và luật `no-progress` so hai dòng `step=round` liền nhau nên hai dòng phải đo cùng thời điểm. Đo cuối vòng thì nó luôn bằng 0 ở vòng thành công và phép so mất nghĩa. Giá trị = số 🔴 mở **trừ** những finding đã có bullet `refused` trong `fix.md`; không trừ thì một ca `refused` làm mọi vòng đều "không giảm" và vòng 2 chết oan.

### Bước 4 — hậu điều kiện rồi exit summary

**4a. Assert bốn mệnh đề.** Ba mệnh đề đầu **giống hệt** `/verify-v1`. Thêm:

4. Mọi ID `🤖` ở §3 `Action Items` của roll-up có mặt trong `.progress/fix.md` — `fixed` hoặc `refused`.

⚠ **Mệnh đề 4 KHÔNG phát biểu được là "0 dòng `🤖`".** Từ chối **không** xoá dòng `🤖` khỏi roll-up: `PIC` derive từ `Loại`, mà `/fix-findings` không được ghi report ([030](../../.docs/030-test-report-per-scope.md) `D22`). Phát biểu "0 dòng" làm vòng chạy tới cap rồi báo thất bại cho một lượt đã làm đúng. Nên mệnh đề này đọc **hai** file, và `.progress/fix.md` là chỗ **duy nhất** phân biệt *"chưa ai thử"* với *"đã thử, không được"*.

Đóng log:

```
- [x] step=outcome result={done|stopped} reason={…} fixed={a} refused={b}
```

`reason=` là **tập đóng**, năm giá trị — không đúc chuỗi mới, nếu không hai lượt cùng nghĩa ra hai chuỗi khác nhau và `grep` theo nó vô dụng:

| `result` | `reason` | Nghĩa |
|---|---|---|
| `done` | `khong-co-viec` | vào Bước 3b đã 0 dòng `🤖` — chưa từng có gì để làm, 0 vòng |
| `done` | `da-lam-het` | vòng cuối đóng dòng `🤖` cuối cùng |
| `stopped` | `no-progress` | `red_before` không giảm so với vòng trước |
| `stopped` | `k3` | chạm `--max-rounds` |
| `stopped` | `cay-ban` | thay đổi mới so với ảnh chụp Bước 0 |

**4b. Exit summary** — khối của v1, cộng một khối `Đã thử, không sửa được…` **chỉ khi** `fix.md` có bullet `refused`:

```
✅ F-004 — verify xong, mọi việc 🤖 đã được thử.

  Scope:   validation v1 · functional v1 · e2e v1
  Vòng:    2 — vòng cuối 0 🔴 mới
  Đã sửa:  3 bug-code — FIND-VAL-01 (validateTagName) · FIND-FUN-01 (deleteTag)
                      · FIND-FUN-02 (bộ lọc giữ id đã xoá)
  Branch:  fix/verify-F-004  (chưa merge)
  Log:     .specs/tests/F-004-todo-tag/.progress/

  Đã thử, không sửa được trong phạm vi requirement — cần 👤 BA
    FIND-E2E-01  nhiều-cách-thoả — FAC-F004-001 đòi user gắn nhãn vào việc; hook
                 useTags.attach đã có nhưng FAC không nói control hình gì

Việc còn lại — 1 🤖 đã thử · 4 👤
  👤 BA    A-E2E-1  chốt hình dạng control gắn nhãn (xem dòng refused ở trên)
  👤 DEV   A-E2E-2  mở đường cho e2e đọc bảng liên kết việc–nhãn
  …
```

Lý do `spec-debt-mở` ([`.docs/036`](../../.docs/036-spec-drift-vao-spec-debt.md)) in cùng khối, kèm `SD-n` + chủ sổ để người biết gõ `/spec-new` cho sổ nào: `FIND-FUN-02  spec-debt-mở — AC-F008-001 đang chờ BA (SD-2 của F-008-todo-hoan-viec)` ⇒ `/spec-new F-008`. Từ [`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md) chủ sổ luôn là feature — sổ nằm cạnh `frd.md`. Dòng việc `spec-drift` · `👤 BA` của roll-up — kể cả dòng *`SD` mở mà không test nào đỏ* — cũng gợi `/spec-new {F-XXX}`. Nó cũng là `refused` nên `red_before` trừ nó ra như mọi refusal khác — vòng lặp không chết oan ở luật `no-progress`.

Một ID `refused` in **hai lần** có chủ ý: khối trên nói **máy đã làm gì**, danh sách dưới nói **người phải làm gì**. Cột `Việc` vẫn trích **nguyên văn** §3 roll-up.

## `verify.run.log`

`.specs/tests/{F-XXX}-{slug}/.progress/verify.run.log` — vết của **một lượt gọi**, writer là skill này. Ba `step=`: `begin` · `round` · `outcome`. Tập này **khác** tập của `implement-log.md` ([02-artifacts §3.9](../../02-artifacts.md)) — đừng đọc lẫn.

**Đuôi `.log` nên nó nằm ngoài glob `.progress/*.md` của sổ gộp** — có chủ ý: nó là biên bản, không phải sổ derive.

**Xoá đầu mỗi lượt gọi, append trong lượt.** Cap là *"3 vòng mỗi lượt gọi"*: append qua nhiều lượt thì lần gõ thứ hai đọc thấy đã 3 vòng rồi **từ chối làm gì cả** — người dùng không retry được nữa. Mà việc người quyết chạy lại **chính là** tín hiệu đã có gì đổi (vừa duyệt một refactor, vừa chốt một spec). Hệ quả có chủ ý: lý do dừng của lượt trước mất khi lượt mới bắt đầu, đúng lúc nó hết liên quan. Lịch sử xa hơn = `git log -p .progress/`.

Nó giữ đúng **hai** thứ không tự phát hiện lại được: **số vòng đã chạy** và **🔴 mở của vòng trước**. Mọi thứ khác trong lượt này đều derive lại được từ đĩa, nên không có dòng nào cho chúng. Mọi dòng neo `sha=` thật — kiểm bằng `git cat-file -e {sha}^{commit}`.

**Không có `step=refuse`.** Refusal derive được (cùng câu chữ ⇒ cùng kết quả) nên nó sống ở `.progress/fix.md` dạng bullet trần; một `- [ ] step=refuse` còn là dòng không bao giờ tick được, đúng bẫy [031](../../.docs/031-verify-workflow.md) `D19` chặn.

## Luật dừng

Sáu ca của `/verify-v1`, **nguyên văn**, cộng hai ca của vòng lặp:

| # | Điều kiện | Thông điệp phải nói gì |
|---|---|---|
| 7 | `red_before` không giảm so với vòng trước | vòng thứ mấy, finding nào vẫn đỏ, và rằng sửa **đã** xảy ra mà không đổi kết quả ⇒ remedy đúng nằm ngoài tầm `/fix-findings` (schema? hạ tầng?) → `👤 DEV` |
| 8 | chạm `--max-rounds` | số vòng đã chạy, `🔴` mở còn lại, và danh sách `🤖` chưa có kết luận trong `fix.md` |

Cả hai in `⏸ dừng hợp lệ — {lý do}` và nói bước tiếp theo của người. Không ca nào dừng im.

## Hậu điều kiện

- Bốn mệnh đề 4a.
- `.progress/verify.md` refresh ở trạng thái cuối lượt.
- `.progress/verify.run.log` đóng bằng đúng một dòng `step=outcome`.
- Branch `fix/verify-{F-XXX}` **chưa** merge, **chưa** mở PR.
- Skill này chỉ ghi `.progress/verify.md` + `.progress/verify.run.log`. Code sản phẩm do `/fix-findings` ghi, report do skill tầng ghi.

## Ràng buộc

- **KHÔNG ghi:** code sản phẩm · `test-report*` · `frd.md`/`test-design.md` · `test-exec-*` · `.progress/fix.md` và 5 sổ của skill con.
- **KHÔNG tự dựng harness**, không tự merge, không mở PR.
- **KHÔNG nâng `👤` thành `🤖`** — vùng đóng băng.
- **KHÔNG gọi tầng no-arg trong vòng lặp** — luôn `--mode`.
- **KHÔNG đọc sổ để rẽ nhánh** — pin và §4 `Results` mới được (core §4 luật 2). Số vòng đọc từ `verify.run.log`, **không** nhớ trong đầu: compaction không reset nó.
- **Quy ước của repo** (changelog, hook, CI) là việc của **người gọi**, đi commit riêng — gộp vào commit của skill thì số đo *"skill nào ghi file nào"* hết đọc được. Áp cho cả tầng con.

## Checklist hoàn thành

- [ ] Bước 0: như v1, cộng `verify.run.log` đã xoá và có dòng `step=begin`
- [ ] Bước 1–3: như v1
- [ ] Bước 3b: mỗi vòng có đúng một dòng `step=round` với `sha`/`k`/`red_before` thật
- [ ] Bước 3b: mọi lần gọi lại tầng đều qua `--mode`, và pin **không** đổi sau `execute`
- [ ] Bước 4: bốn mệnh đề đã assert · `step=outcome` đã đóng · exit summary có khối `refused` nếu `fix.md` có bullet đó
- [ ] `git status --porcelain -- {src} {test}` sạch so với ảnh chụp Bước 0 (code đã commit trên branch fix)
- [ ] Không file nào ngoài `.progress/verify.md` + `.progress/verify.run.log` bị **skill này** ghi
