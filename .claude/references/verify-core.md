# Verify core — chuỗi bước ④ (dùng chung cho `/verify-v1` và `/verify-v2`)

> **Import bởi:** [`skills/verify-v1/SKILL.md`](../skills/verify-v1/SKILL.md) (chuỗi + exit) · `skills/verify-v2/SKILL.md` (chuỗi + **vòng lặp** + exit — [`.docs/032`](../.docs/032-verify-fix-loop.md)).
> File này giữ **Bước 0–3** + gate cây sạch + cách đọc pin/version + cách đọc roll-up + luật gộp sổ. Bước 4 (exit summary) và **luật dừng** sống ở `SKILL.md` của từng version.
> Sửa file này là sửa **cả hai** version — số đo so sánh giữa v1 và v2 vì vậy phải neo `sha` + ngày.

## 0. Bốn luật bất di

1. **Zero state.** Không truyền output tầng trước sang tầng sau. Mỗi tầng đọc lại pin + version + roll-up **từ đĩa**. Nhờ vậy gõ lại là tiếp đúng chỗ, và một lượt bị compact hay Ctrl+C không mất gì ngoài thời gian.
2. **Orchestrator ghi đúng một file: `.progress/verify.md`.** KHÔNG ghi code sản phẩm · `test-report*` · `frd`/`test-design` · `test-exec-*`. Report chỉ do skill tầng ghi (030 D22) — sửa tay thì không ai nâng pin, và ô sửa tay bị ghi đè ở lượt sau.
3. **`blocked` của con là câu của con.** Skill con dừng thì in **nguyên văn** lý do nó trả về. Không diễn đạt lại, không suy diễn thành câu khác — diễn đạt lại là mất chẩn đoán.
4. **Kết thúc bình thường KHÔNG phải all-green.** Đỏ ở bước ④ là **finding giao người** ([test-core §7.4](retrofit-core.md)), không phải thứ orchestrator được sửa. Hoàn tất = "3 tầng đã chạy, pin đã lên, còn N việc chờ người".

## 1. Bộ ba số quyết định mọi thứ

Không có state trong đầu vì ba số trên đĩa đã nói hết:

```
test-design.md   versions.{scope}         ──①──▶  test-exec-{scope}.md   test_design_version
test-exec-{scope}.md   version            ──②──▶  test-report-{scope}.md   test_exec_version  (= "pin")
```

| Cổng | So gì | Lệch nghĩa là | Ai sửa được |
|---|---|---|---|
| ① version-gate | `test-design.versions.{scope}` vs `test-exec-{scope}.test_design_version` | test-design đã đổi, wiring test-exec chưa reconcile | **chỉ** `/spec-test-exec` (016 D9) |
| ② pin-gate | `test-report-{scope}.test_exec_version` vs `test-exec-{scope}.version` | scope stale, phải chạy lại **cả** scope | **chỉ** skill tầng của scope đó |

- `pin == version` ⇒ scope **current**, không dispatch gì.
- `pin < version` (gồm `pin = 0`) ⇒ dispatch tầng đó.
- Scope **không có TC** ⇒ không có `test-exec-{scope}.md`, **không có dòng nào** — không phải `0/0`.
- `nfr`/`dm` **chưa có skill nào ghi result** ⇒ pin của chúng ở lại `0` là **trạng thái đúng**, không phải việc còn nợ. In `v0 (chưa có writer)` và **không** đưa vào hậu điều kiện.

**Chết giữa scope hay chưa từng chạy** — hai ca này pin giống nhau. Phân biệt bằng **số row CÓ RESULT**, không phải số row: `pin < version` **và** số row §4 `Results` có `Result` **khác `—`** < số row bảng `Test Cases` của `test-exec-{scope}.md` (§4 ở `validation`/`functional`, **§5** ở `e2e` — gọi bằng tên bảng, không bằng số). Mẫu số là **test-exec**, KHÔNG phải `test-design.md` (nó đếm cả TC `Autoable = NO`, hai số lệch vĩnh viễn — [test-core §7.0](retrofit-core.md)).

**Vì sao đếm row là sai — đo được 2026-09-10 trên chính ca chết giữa scope.** `test-report-validation.md` của `F-005` có **4** row, mẫu số cũng **4**, nhưng chỉ **2** row có result ⇒ phép so `4 < 4` **sai** và bộ nhận biết kết luận "chưa từng chạy". Vế `sanity-red = ✅` mà `reverted ≠ ✅` cũng không nổ vì mutation đã revert sạch. Đối chứng cùng thư mục: scope **chưa từng chạy** có **0** row (`functional` của `F-005`), nên *"row tồn tại mà `Result = —`"* tự nó là dấu vết — thứ duy nhất phân biệt được ba ca.

## 2. Gate cây sạch — so với ảnh chụp đầu lượt

```bash
git status --porcelain -- {src} {test}      # KHÔNG phải `git status --porcelain` trần
```

`{src}`/`{test}` = cây code sản phẩm + cây test của project (đọc từ `package.json`/`vitest.config.*`/`playwright.config.*`). **Loại trừ `.specs/tests/**`**: sổ `.progress/` và artifact mà tầng vừa ghi đều là **output hợp lệ** của lượt chạy — đọc `git status` trần thì gate bắn ở mọi lượt.

**Bước 0 chụp ảnh, không dừng.** Cây bẩn ngay đầu lượt là chuyện của người: brownfield retrofit chạy trên code **as-is**, và [retrofit-core](retrofit-core.md) không đòi cây sạch ở đâu cả — dừng ở đây là chặn đúng ca thường gặp nhất (dev có WIP). In cảnh báo kèm tên file rồi **chạy tiếp**, và **giữ ảnh chụp** đó.

**Ngoại lệ — bẩn kèm dấu vết một tầng chết giữa scope ⇒ dừng ngay Bước 0.** Dấu vết đọc trên đĩa: `pin < version` mà §4 `Results` của scope đó **đã có row**, hoặc một row có `sanity-red = ✅` mà `reverted ≠ ✅`. Đó không phải WIP, đó là **mutation nằm lại** từ lượt bị kill — chạy tầng nào cũng là chạy trên code đã bị phá.

**Sau mỗi tầng: so lại với ảnh chụp.** Chỉ **thay đổi mới** là ca 4 ⇒ **dừng, KHÔNG spawn tầng sau**. Thay đổi đã có từ Bước 0 không tính lại — nếu tính, một dev có WIP sẽ bị dừng sau tầng đầu tiên mà không hiểu vì sao. Đây là lớp lỗi riêng của bước ④: sanity-red **mutate code sản phẩm rồi revert** theo từng TC ([retrofit-core §4](retrofit-core.md)); subagent bị kill giữa mutation thì mutation nằm lại và tầng sau chạy trên code đã bị phá — **đỏ giả, verdict giả**.

**Suite test là toàn cục, gate thì per-feature.** Lượt chốt full suite của một tầng thấy **cả** test đỏ của feature khác (đo được: hai tầng của `F-005` đều thấy 3 🔴 của `F-004`). Đỏ ngoài scope của mình **không** phải finding, **không** phải blocker, **không** chặn nâng pin — nhưng cũng **không** được im: ghi một dòng ở commit message. Ở nhánh slug rủi ro này cao hơn hẳn vì hai feature chắc chắn dùng chung một suite.

**Gate này dựa vào một luật của tầng: tầng commit output của chính nó** (`test-report-{scope}.md` + test code + `selector-contract.md` — [test-core §7](test-core.md), 015 §3B "git là history"). Nhờ đó tầng trả về là cây đã về lại ảnh chụp. Tầng **không** commit thì test file nó vừa viết đọc thành "thay đổi mới" và ca 4 bắn oan ngay sau tầng đầu — nên khi ca 4 nêu ra **file test mới của đúng tầng vừa chạy**, kết luận là *tầng chưa commit*, không phải *mutation chưa revert*; nói đúng câu đó ra thay vì đổ cho mutation.

**Thông điệp phải nêu tên file.** Ở tầng functional/e2e, `git diff` trộn hai loại thay đổi cùng nằm trong component, và tên file là chỗ duy nhất phân biệt được:

| Hình dạng diff | Kết luận | Làm gì |
|---|---|---|
| chỉ `selector-contract.md` + hunk **thêm** `data-testid=` | backfill dở — additive, an toàn | dispatch lại tầng đó được |
| có hunk khác trên file sản phẩm (logic, điều kiện, return) | nghi **mutation chưa revert** | dừng, người `git diff` trước khi chạy tiếp |

## 3. Bước 0–3

### Bước 0 — resolve arg, gate `frd`, probe harness, refresh sổ

**0a. Resolve arg** (chi tiết CLI ở `SKILL.md`):

| Arg | Làm gì |
|---|---|
| `F-XXX` | một feature |
| slug integration | đọc `features:` ở frontmatter `spec.md` của integration đó → chạy **tuần tự** từng `F-XXX`, mỗi feature một lượt trọn Bước 0–4. **Chụp lại ảnh cây ở Bước 0 của TỪNG feature**, không chụp một lần cho cả slug: tầng của feature trước commit output của nó xong thì feature sau đọc chính output đó thành "thay đổi mới" và ca 4 bắn oan |
| *(không có)* | liệt kê feature có `test-design.md` kèm pin từng scope, cho chọn |

Slug không tìm thấy, hoặc `features:` rỗng ⇒ dừng, nói rõ đọc file nào không thấy gì.

**0b. Gate `frd.md`** — `.specs/main/feature/{F-XXX}-{slug}/frd.md` không có ⇒ **dừng ngay**, trước cả probe harness. Retrofit không chạy trên code trần: giá trị đúng phải derive từ VR/AC/FAC, không có frd thì không có oracle nào ([test-core §0](retrofit-core.md) luật 1).

**0c. Probe harness — in trước, không tự dựng.** Đọc `package.json` (script test), `vitest.config.*`, `playwright.config.*`, thư mục test của project. Tier nào thiếu hạ tầng thì in **ngay bây giờ** kèm tên tầng sẽ tắc:

```
⚠ e2e sẽ tắc: thiếu Playwright + POM + seeded backend → 👤 DEV
```

`⏭ harness` là **kết thúc hợp lệ** ([06-testing.md §5](../06-testing.md)), không phải lỗi — nhưng biết ở phút 0 khác biết ở phút 40. **Luật không tự dựng harness giữ nguyên**: đó là quyết định kiến trúc, `👤 DEV` ([test-core §3](retrofit-core.md)).

**0d. Refresh `.progress/verify.md`** (§4). Refresh **trước** khi rẽ nhánh, và rẽ nhánh **không** đọc sổ.

⚠ **Bước 1 và Bước 2 cũng spawn subagent, cùng luật với Bước 3.** Trước 2026-09-11 chỉ Bước 3 nói ra điều đó, nên đọc theo chữ thì hai bước đầu chạy thẳng trong context orchestrator — mà `/spec-test-design` derive ra file 600+ dòng và `/spec-test-exec --auto` đọc cả chục file, nhồi vào orchestrator là nuốt hết chỗ dành cho vòng lặp. Prompt copy-paste nguyên văn, orchestrator chỉ đọc giá trị trả về.

### Bước 1 — `test-design.md`

| Điều kiện | Hành động |
|---|---|
| không có | `Skill(spec-test-design)` với `{F-XXX}` |
| đã có | **bỏ qua** — nó tự reconcile ở lượt riêng (`/spec-test-design` mode `reconcile`, 018 D11); chuỗi verify không gọi reconcile hộ |

⚠ **Hệ quả: chuỗi này KHÔNG thấy `frd.md` đổi.** Thêm/sửa một `VR`/`AC` trong `frd` là thứ `/verify-v1` và `/verify-v2` **hoàn toàn không nhận ra** — phải gõ `/spec-test-design {F-XXX}` bằng tay trước. Đo 2026-09-10: một bed chèn `VR-F006-003` vào `frd` rồi gọi thẳng `/verify-v2`; lượt đó chạy no-op và **không dòng nào nói vì sao**.

### Bước 2 — `/spec-test-exec {F-XXX} --auto` khi ① lệch hoặc thiếu file

Gọi khi **một trong hai** đúng: ① lệch ở scope nào đó, **hoặc** scope có TC mà thiếu `test-exec-{scope}.md`. Đây là chỗ **duy nhất** reconcile được wiring — tự chèn nó khi gate lệch là phần đáng tự động nhất của cả chuỗi.

**① khớp hết và không thiếu file ⇒ bỏ qua, in `exec current`.** Orchestrator vốn đã đọc ① ở §1 (nó cần cho ca 5) nên không phải đoán. Đo được ở lượt nghiệm thu 2026-09-10: gọi vô điều kiện lúc mọi scope current thì `/spec-test-exec` NO-OP đúng như hứa — 14/15 file y nguyên byte — nhưng vẫn **ghi lại `.progress/exec.md`** (luật sổ của nó là *dựng lại trọn mỗi lượt*, không có ngoại lệ cho NO-OP), tốn ~145s và ~10 lần đọc file. Nhánh NO-OP của nó **bỏ** 4 phép kiểm `selector-contract`, nên lượt gọi đó mua được đúng một thứ: refresh sổ của chính nó.

`--auto` trả `yes` cho **đúng một** ô: *"test-design chưa approved, tiếp tục?"* (`/spec-test-exec` Bước 2). Ba skill tầng và `/spec-test-design` không dùng `AskUserQuestion` chỗ nào ⇒ không có gì khác để trả lời.

Sau Bước 2, đọc lại ① cho từng scope. **Còn lệch ⇒ lỗi thật** — `/spec-test-exec` đã chạy mà không reconcile được, không phải ca thường (luật dừng ca 5 ở `SKILL.md`).

### Bước 3 — ba tầng, thứ tự cứng, mỗi tầng một subagent

Thứ tự **luôn** `validation → functional → e2e` bất kể thứ tự gõ ở `--scope=`: tầng 2 backfill `selector-contract` + `data-testid` mà tầng 3 tái dùng ([06-testing.md §2](../06-testing.md)); tầng 3 là cổng verification cuối.

Với **từng** scope theo thứ tự đó:

1. Scope không có TC ⇒ bỏ qua, không in dòng nào.
2. `pin == version` ⇒ in `current`, không dispatch.
3. `pin < version` ⇒ **spawn một subagent riêng**, prompt **copy-paste nguyên văn**, không diễn đạt lại:

   ```
   invoke /spec-test-retrofit-{scope} {F-XXX}
   ```

4. Subagent trả về ⇒ chạy gate cây sạch (§2) → refresh sổ (§4) → sang tầng sau. Trả `blocked` ⇒ dừng, in **nguyên văn** câu của nó.

**Vì sao mỗi tầng một subagent:** một tầng = đọc code tìm seam + viết test + chạy + mutate + chạy + revert + chạy, cho **từng** TC. `F-002` là 61 TC trên 3 scope. Nhồi một context là cạn giữa tầng 2 — và vì zero state, subagent nào cũng đọc lại từ đĩa được, không cần mang gì theo.

## 4. Sổ gộp `.progress/verify.md`

`.specs/tests/{F-XXX}-{slug}/.progress/verify.md` — orchestrator sở hữu **đúng một** file này. Đơn vị việc của nó đúng là 6 lần gọi skill con, nên sổ của nó là **phần gộp**. Template: [`templates/tests/verify-progress-template.md`](../templates/tests/verify-progress-template.md) (dùng chung với 6 sổ của skill con). Định nghĩa thư mục: [`02-artifacts.md §4.7`](../02-artifacts.md).

**Cách gộp** — đúng khuôn roll-up của [test-core §7b](retrofit-core.md):

| Luật | Nội dung |
|---|---|
| glob | `.progress/*.md` **trừ `verify.md`** (chính nó) — thiếu vế trừ là sổ đọc chính mình |
| thứ tự | `design → exec → validation → functional → e2e → fix` — khối `fix` là `.progress/fix.md`, writer `/fix-findings`; đặt cuối vì lượt sửa chạy **sau** ba tầng. Glob nhặt nó tự động, nên nó phải được khai ở đây và ở bảng writer [`02-artifacts.md §4.7`](../02-artifacts.md), không thì bản gộp in một khối không ai khai hình dạng |
| chép nguyên văn | orchestrator **KHÔNG** derive lại per-TC — đó là việc của skill sở hữu sổ (033 `D0`). Không có renderer dùng chung nào dựng khối con: một hàm "đọc khai báo rồi dựng khối" là **writer thứ hai** cho cùng nội dung, và hai bên lệch nhau là lệch im lặng |
| sổ vắng mặt **và** scope của nó chưa current | in **một dòng việc lớn** `- [ ] /spec-test-… (chưa chạy)`, không phải khối rỗng |
| sổ vắng mặt **nhưng** pin đã current | in `- [x] /spec-test-… pin {p}/{v}   current — không dispatch`. **Không** in `- [ ] (chưa chạy)`: feature verify xong trước khi kit có sổ (mọi feature xong trước 2026-09-09) thì không sổ nguồn nào tồn tại, mà một dòng `- [ ]` vĩnh viễn làm luật resume trỏ con trỏ vào `/spec-test-design` của một feature đã xong — dispatch lại vô hạn, đúng cái `D19` chặn |
| sổ vắng mặt, pin `0`, mà §4 `Results` **đã có row có result** | in `- [ ] /spec-test-retrofit-{scope}   pin 0/{v}   ({k}/{n})   — sổ vắng`. Ca thứ ba, đo được ở `F-005`: sổ chưa có nhưng scope đã chạy dở. Hai nhánh trên áp vào đây đều nói sai (`(chưa chạy)` sai sự thật · `current` sai pin) |
| sổ **có mặt** nhưng `derived_from` lệch số thật (pin hoặc version) | **KHÔNG** chép nguyên văn — in `- [ ] /spec-test-retrofit-{scope}   pin {p}/{v}   ({k}/{n})   — sổ cũ`, số lấy từ **đĩa** như nhánh trên. Ca thứ tư, đo được 2026-09-10 trên bed `verify-resume-functional.sh`: một tầng bị reset về `pin 0` để lại sổ vẫn ghi `- [x] pin 1/1 (11/11)`. Sổ là của writer khác nên orchestrator **không** refresh hộ được ([033](../.docs/033-verify-progress-units.md) `D0`); chép nguyên văn thì bản gộp nói dối và luật resume không thấy dòng `- [ ]` nào ⇒ kết luận không có gì để dispatch. **Dòng `⚠` của sổ cũ vẫn chép sang** — cùng lý do với nhánh `exec` skip: việc `👤` không được mất chỉ vì khối việc nhỏ hết tin được. Bỏ khối việc nhỏ vì chúng nói về pin cũ; giữ `⚠` vì nó nói về `frd`/`test-design`, thứ lượt này không đụng |
| khối `design` khi Bước 1 skip | in `- [x] /spec-test-design — skipped (đã có)` làm việc lớn, rồi chép nguyên văn khối việc nhỏ của `design.md` bên dưới. Cùng luật với `exec` skip — trước 2026-09-10 bảng này chỉ có **ví dụ**, không có dòng luật, nên hai lượt chép hai kiểu |
| khối `exec` khi Bước 2 skip | in `- [x] /spec-test-exec — skipped (exec current: ① khớp mọi scope, không thiếu file)` làm việc lớn. Dòng `{scope}  td {a} → exec tdv {b}` cho từng scope **chỉ in khi `exec.md` VẮNG** — sổ có mặt thì khối việc nhỏ của nó đã nói đúng thứ đó, in cả hai là hai dòng gần trùng cho một sự thật (đo 2026-09-10). Đây là **bản ghi quyết định của orchestrator**, không phải bản chép từ sổ nguồn — cùng vai với dòng `- [x] /spec-test-design — skipped (đã có)`. Bước 2 skip nghĩa là `.progress/exec.md` không có ai ghi ở lượt đó. **Nhưng khối việc nhỏ của sổ nguồn vẫn phải chép sang, không riêng dòng `⚠`**: lượt 2026-09-10 đo được 6 dòng `⚠` của `F-004` (2 item `blocked-by-spec` → 👤 BA · 3 dòng về TC `Autoable = NO` · 1 dòng `Layer = —`) **biến mất** khỏi bản gộp vì khối bị thay bằng một dòng `skipped`. Việc `👤` không được mất chỉ vì tầng không phải chạy lại. **Và không chỉ `⚠`**: đo 2026-09-10 trên `F-006`, dòng `skipped` nuốt luôn 2 việc nhỏ của `exec.md` (`scaffold report 2/2 scope` · `roll-up · derived_from khớp 2 scope`) — chúng vẫn đúng, chỉ là bị thay. Hệ quả tệ hơn mất dữ liệu: `verify.md` của một lượt **skip** và của một lượt **chạy** khác nhau ở chỗ không liên quan gì tới thứ đang đo, nên phép so hai lượt ([032](../.docs/032-verify-fix-loop.md) `DS8`) đọc ra chênh lệch giả. Hình dạng đúng: dòng `skipped` là **việc lớn** (bản ghi quyết định của orchestrator), khối việc nhỏ của sổ nguồn chép nguyên văn **bên dưới** nó |
| không đọc bản gộp cũ | dựng lại trọn từ các sổ nguồn mỗi lần |
| dòng `⚠` | `⚠` **của một sổ con** ở lại **trong khối** của sổ đó (chép nguyên văn). Chỉ `⚠` mà **orchestrator tự derive** lúc refresh (probe harness) mới đứng ở đầu file. Hoist `⚠` của sổ con lên đầu làm hai lượt khác hình dạng ở chỗ không liên quan tới thứ đang đo |
| sổ **không phải sổ retrofit** mà `derived_from` lệch (vd `fix.md`) | cùng nhánh `— sổ cũ`, nhưng **bỏ đoạn `pin {p}/{v}`** — sổ đó không có pin. In `- [ ] /fix-findings   — sổ cũ`. ⚠ **Bộ nhận biết đọc `pin`, KHÔNG đọc `date`** (như nhánh trên đã nói: *pin hoặc version*). Với `fix.md` chỗ này quyết định đúng/sai: đúng hình dạng vòng lặp thì tầng chạy lại **sau** `/fix-findings`, nên `date` ba report mà `fix.md` chép lại **luôn** cũ hơn ở cuối một lượt thành công. Tính cả `date` ⇒ mọi lượt `/verify-v2` xong việc đều in một dòng `- [ ]` mở, tức bản gộp báo còn việc trong khi không còn |
| `derived_from` | chép `date` của từng sổ đã gộp — lệch ⇒ bản gộp cũ hơn sổ nguồn |

**Bốn loại dòng, phân biệt bằng hình dạng:**

| Loại | Hình dạng | Vai |
|---|---|---|
| việc lớn | `- [ ] /spec-test-… {payload}` | một lần gọi skill con |
| việc nhỏ | `  - [ ] {đơn vị} {payload}` | tiến độ bên trong skill đó — hạt do `SKILL.md` của nó khai |
| không tick được | `- ⚠ {mô tả} → 👤 {role}` — **bullet trần, không checkbox** | thứ chỉ người đóng được, hoặc cảnh báo derive lúc refresh (thiếu harness · frd item `blocked-by-spec`) |
| bị chặn | `- ⛔ /spec-test-… {lệnh phải gõ} ({lý do})` — **không có ô tick** | tiền đề chưa đủ (version-gate lệch) — [retrofit-core §1b](retrofit-core.md) |

```markdown
- ⚠ e2e sẽ tắc: thiếu Playwright + POM + seeded backend → 👤 DEV
- [x] /spec-test-design — skipped (đã có)
- [x] /spec-test-exec
  - [x] validation   td 1 → exec tdv 1 · rows 31/31
  - [x] functional   td 1 → exec tdv 1 · rows 14/14
- [x] /spec-test-retrofit-validation   pin 1/1   (31/31)
- [ ] /spec-test-retrofit-functional   pin 0/1   (12/14)
  - [x] TC-F004-020  🟢                    wired
  - [ ] TC-F004-022                        wired · chưa có row §4
- [ ] /spec-test-retrofit-e2e           (chưa chạy)
```

**Luật refresh:** dựng lại trọn `verify.md` ở **hai** thời điểm — đầu mỗi lượt (Bước 0d), và sau **mỗi** lần dispatch trả về. Không đọc bản cũ. Dòng `⚠` thiếu harness là **derive** (probe lại mỗi lần refresh), không phải biên bản.

**Ba luật cứng:**

1. **`[x]` = "đã có bản ghi", KHÔNG phải "xanh".** `🔴` và `⏭` đều `[x]` — chúng là việc **đã trả tiền**. Nên mỗi dòng việc nhỏ phải mang ký hiệu result + hậu tố (`⏭ harness → BLK-E2E-1`); `[x]` trơn đọc thành "xanh".
2. **Không rẽ nhánh trên sổ.** Refresh trước, rồi đọc pin + §4 `Results` để quyết dispatch gì. Vì thế sổ **không thể** nói dối: nó là bản in của hai thứ đó.
3. **Checklist nở ra giữa lượt là bình thường** — việc nhỏ của một số khối chỉ enumerate được **sau** khi skill chạy. Refresh in thấy gì có nấy, không đoán trước.

**Resume:** refresh → dòng `- [ ]` **đầu tiên** là chỗ dispatch lại. Nhưng `⛔` **đứng trên** con trỏ đó: thấy `⛔` ở bất cứ việc lớn nào ⇒ dừng theo luật dừng, **không** đi tìm `- [ ]` tiếp theo — dòng `⛔` không có ô tick nên luật con trỏ sẽ **nhảy qua** tầng đang bị chặn và dispatch tầng sau, tức chạy tầng 3 trên contract mà tầng 2 chưa backfill.

**Không có file log cho v1.** Mọi điều kiện dừng **tự phát hiện lại được** ở lượt sau: cây bẩn thì `git status` bắn, version-gate lệch thì đọc frontmatter, thiếu harness thì probe lại. Nên chạy lại là **idempotent** — orchestrator không cần nhớ đã dừng vì gì, nó **gặp lại**. *(Vòng lặp thì khác: số vòng đã chạy và số 🔴 mở của vòng trước không tự phát hiện lại được. `/verify-v2` giữ đúng hai thứ đó trong `.progress/verify.run.log` — vết của **một lượt gọi**, xoá đầu lượt, ba `step=` là `begin`·`round`·`outcome`, đuôi `.log` nên nằm ngoài glob của bản gộp. Xem [`skills/verify-v2/SKILL.md`](../skills/verify-v2/SKILL.md).)*

**Quy ước của repo đi commit riêng.** Changelog · hook · CI là việc của **người gọi**, không của skill. Gộp chúng vào commit output của một skill làm số đo *"skill nào ghi file nào"* hết đọc được — đo được 2026-09-10: hai tầng của `F-006` tự gộp `changelogs.md` vào commit của mình, nên mệnh đề *"tầng chỉ ghi output của tầng"* không kiểm được ở lượt đó.

## 5. Đọc roll-up cho exit summary

Nguồn duy nhất: `test-report.md` (roll-up) — orchestrator **chỉ đọc**.

| Cần gì | Đọc ở đâu |
|---|---|
| pin từng scope | §1 `Trạng thái theo scope`, cột `Pin` |
| counts TC (🟢 · 🔴 · ⏭ · 🟡 · —) | §1, dòng `Tổng` |
| số 🔴 **mở** | §1 cột `🔴 finding mở` (đã **trừ** dòng `dup-of` — [test-core §7b](retrofit-core.md) bước 1) |
| danh sách việc | §3 `Action Items` — bảng **phẳng**, trích **nguyên văn**, đúng bộ cột của §5 file scope (030 D21) |

**Phân loại `🤖` / `👤` là derive, không phải lựa chọn** — map cứng ở [test-core §7.4](retrofit-core.md): `bug-code`/`test-error`/`flaky` → `🤖`; `spec-drift`/`need-clarify` → `👤 BA`; `refactor`/`harness` → `👤 DEV`; `coverage-gap` → `👤 QC`. Roll-up đã mang sẵn cột `PIC` ⇒ **đọc cột đó**, không tự suy lại.

`👤` là **vùng đóng băng**: v1 chỉ **in** việc, không sửa code, không nâng `👤` thành `🤖`, không tự chạy skill cascade.
