---
name: spec-test-functional
description: Viết functional test của MỘT Story TRƯỚC khi có code, ở ③ Build trong một Slice của /build — lọc TC scope functional neo AC của story, quyết seam từ tech.md (KHÔNG đọc code, code chưa có), điền Layer + Test File vào test-exec-functional.md, khai chuỗi data-testid vào selector-contract.md cho TC tier fe:component, viết test rồi chạy để thấy nó ĐỎ, rồi ghi ngay row sanity-red red-first với Result — vào test-report-functional.md. Sau khi /build làm xanh thì --phase=record cập nhật Result — thành 🟢, merge theo TC ID, KHÔNG nâng pin. Đây là vòng NGOÀI của double TDD. Bản cho code đã có là /spec-test-retrofit-functional. Import references/test-core.md.
---

# Spec Test Functional — outer loop của một Story

## Overview

Viết **functional test neo `AC-F*`** của đúng **một** `US-F*`, **trước** khi có code. Đây là vòng **ngoài** của double TDD: test của AC mở và đóng một Story slice, còn vòng trong (unit test + `VR` TC) chạy bên trong nó ([`05-concepts.md §15`](../../05-concepts.md)).

**Cỗ máy lõi ở [`references/test-core.md`](../../references/test-core.md)** — 4 luật bất di (§0) · điền test-exec (§2) · tier vocabulary (§2a) · reconcile + anchor 2 chiều (§2b) · seam theo tầng (§3) · ghi `test-report-{scope}.md` (§7) · **lượt outer ở ③ Build (§7c)** · red flags của đường test-trước-code (§9). **Đọc file đó trước.**

**KHÔNG import [`retrofit-core.md`](../../references/retrofit-core.md).** Vòng lặp quét A/B, version-gate, refresh mode, mutate-revert ở đó đều giả định **code có trước** — không mục nào áp được cho lượt này.

```
/build vào một Slice
   └─ /spec-test-functional {F} --story={US} --phase=write   ← test đỏ
        vòng trong: /spec-test-validation + unit test của dev
   └─ /spec-test-functional {F} --story={US} --phase=record   ← ghi row
```

## When to Use

- `/build` đang mở một Slice và cần outer test của story đó — **đây là đường gọi chính**, không gõ tay.
- Gõ tay để thử một story trên bed, khi `test-exec-functional.md` đã có khung và feature **chưa có code**.

## When NOT to Use

- Feature **đã có code** và đang ở ④ Verify → `/spec-test-retrofit-functional`.
- Muốn test `VR-F*` → `/spec-test-validation`. Muốn test `FAC-F*` → `/spec-test-retrofit-e2e` ở ④ Verify (`FAC` neo tầng feature, không slice nào đóng được).
- Chưa có `test-exec-functional.md` → chạy `/spec-test {slug}` trước (nó gọi `/spec-test-exec` dựng khung ở ① Design).
- Muốn chạy trọn scope + nâng pin → đó là ④ Verify, không phải lượt này.

---

## Tham số

- **`{F-XXX}`** *(bắt buộc)* — feature id.
- **`--story={US-F*}`** *(bắt buộc)* — đúng **một** story. Lượt này **không** nhận nhiều story; slice là đơn vị.
- **`--phase=write`** — điền wiring, khai testid, viết test, chạy để thấy đỏ, rồi ghi **hai ô** vào report: row của TC + `sanity-red: red-first`, `Result` để `—`. **Không** ghi `Result` khác `—`, **không** đụng pin.
- **`--phase=record`** — chạy lại, ghi row vào `test-report-functional.md`. **Không** chạm `test-exec`.

---

## Process

> Không có "hai quét" như retrofit. Lượt này **không đọc code sản phẩm** — ở ③ Build code chưa tồn tại. Seam là thứ sắp được viết, lấy từ `tech.md`.

### Bước 1: Lọc TC của story *(cả hai phase)*

- Nguồn: bảng `Test Cases` của `test-exec-functional.md` — **không** phải `test-design.md`. TC có `Autoable = NO` (oracle thị giác) không render xuống đó, nên chúng tự động vắng mặt; đừng đi tìm.
- Giữ TC có `Covers` chứa **một trong hai**:
  - một `AC-F*` **thuộc story** được truyền vào — tập AC lấy từ `stories` của `spec-lite check-vr-refs {frd} --json`, **đọc field, không suy lại** quan hệ AC → US;
  - **hoặc chính `US-F*` đó**, kể cả khi không `AC-F*` nào đi kèm.

  Vế thứ hai không thừa: TC derive từ **nhánh Mermaid của Flow** mang oracle mà không AC nào nói (*"giữ nguyên nội dung đã nhập"*, *"bộ lọc trở về `Mọi nhãn`"*), nên `Covers` của chúng là `US-F* , Flow N` — không AC. Lọc bằng AC một mình là **rơi mất cả nhóm đó**, và rơi im lặng vì phép trừ cuối `/build` chỉ đối chiếu tập TC của slice với row đã điền, không biết TC nào lẽ ra phải thuộc slice nào.
- Tập rỗng ⇒ dừng, báo *"story này không có functional TC lái được"*. Đó là trạng thái hợp lệ (mọi AC của nó đều oracle thị giác), **không** phải lỗi.

### Bước 2: Quyết seam từ `tech.md` + điền wiring *(`--phase=write`)*

- Đọc `tech.md` của integration — mục nói **test viết ở đâu** cho từng nhóm TC. Không có mục đó ⇒ dừng, báo `tech.md` thiếu bảng seam, **không tự đoán**.
- Điền `Layer` (bộ vocabulary ở **core §2a**) và `Test File` (dạng `describe > it`) cho **mọi** TC của story, **một lần**, rồi ghi `test-exec-functional.md`.
- `version` của file **không bump** (core §7c.1).
- TC nào đã xét mà không viết được ⇒ ghi `⏭` + nhãn (`refactor` · `harness` · `need-clarify` · `no-seam`). Ô **rỗng** nghĩa là *slice chưa tới*, khác hẳn `⏭` — đừng lẫn.

### Bước 3: Khai `data-testid` trước component *(`--phase=write`, chỉ TC tier `fe:component`)*

- Outer test **đặt tên** chuỗi testid và ghi thành row trong `selector-contract.md`, cột `TC` **điền ngay** (TC là lý do row tồn tại).
- Quy ước tên giữ nguyên `{feature-slug}-{element}[-{qualifier}]` ([`references/testid-conventions.md`](../../references/testid-conventions.md)).
- Component do `/build` viết sau **phải gắn đúng chuỗi này**. Kiểm hai chiều `contract ⊆ code` + `code ⊆ contract` là việc của `/build` ở **cuối slice**, không phải ở đây — ngay sau bước này thì `contract ⊆ code` **phải sai**, đó chính là lý do test đỏ.

### Bước 4: Viết test *(`--phase=write`)*

- Giá trị đúng derive từ `test-design.md` + `frd.md` (**core §0** luật 1). Không có code để đọc, và cũng không được đọc.
- Một TC ⇒ một `it`, tên `it` chứa `TC-F*` để anchor hai chiều (**core §2b**).
- Đã có test ở seam đó ⇒ **neo TC ID vào nó**, không viết trùng (**core §2b**).

### Bước 5: Chạy → phải **ĐỎ** *(`--phase=write`)*

- Chạy hẹp đúng file vừa viết. **Phải đỏ.**
- Xanh ngay ⇒ **dừng, báo người**: hoặc code đã tồn tại (sai tiền đề của lượt này), hoặc test không assert gì.
- **Ngoại lệ — row đã mang `red-first`:** nhịp đỏ đã lập ở lượt trước, slice này đang **chạy lại sau khi bị ngắt**. Xanh ngay là đúng; đi tiếp, không báo động. Không có ngoại lệ này thì mọi lần resume một slice dở đều báo động oan.
- Đỏ vì **harness thiếu / seam gõ nhầm / thiếu dev dependency** ⇒ **test-error**, sửa test rồi chạy lại.
- **`module not found` của chính module slice này sắp viết LÀ nhịp RED hợp lệ** — file sản phẩm chưa tồn tại thì test import nó phải nổ. Phân biệt bằng đường dẫn: nằm trong tập file `tech.md` khai slice sẽ tạo ⇒ RED; nằm ngoài ⇒ test-error (core §9).
- **Ngay sau khi thấy đỏ, ghi row vào `test-report-functional.md`** với `sanity-red: red-first` và `Result` để `—` (core §7c.7). Bằng chứng *"đã thấy đỏ trước khi có code"* xuống đĩa **ngay lúc nó phát sinh**, không chờ cuối slice — slice bị ngắt giữa chừng thì nó vẫn còn. `Result` khác `—` là việc của `--phase=record`.
- Kết thúc `--phase=write` ở đây. **Không** đụng pin, **không** dựng roll-up, **không** commit — commit là việc của `/build` ở cuối slice.

### Bước 6: Ghi row *(`--phase=record`)*

- Chạy lại đúng các TC của story. Còn đỏ ⇒ **không ghi row**, trả về cho `/build` phân loại (core §5 giữ bảng phân loại chung).
- Cập nhật row đã có từ `--phase=write`: `Result` `—` → **`🟢`** (§4 `Results` không có cột `date`; `date` là field frontmatter, refresh ở cấp file). `sanity-red` **giữ nguyên** `red-first`, `mutation`/`reverted` giữ `—`. Row chưa tồn tại (lượt `write` chạy bản cũ) ⇒ ghi mới đủ bốn ô.
- **Chỉ row của story này.** Merge theo key `TC ID`, **không rewrite cả bảng** (core §7c.6).
- TC đã có row `red-first` từ slice trước mà lượt này chỉ chạy lại ⇒ refresh `Result`, **`sanity-red` giữ nguyên** (core §7c.2).
- `mode` để `cycle`. `test_exec_version` (pin) **không đổi** (core §7c.5).
- **Không** dựng lại roll-up — đó là việc của ④ Verify.

---

## Ràng buộc

- **Không đọc code sản phẩm.** Seam từ `tech.md`, oracle từ `test-design.md`/`frd.md`.
- **Không** mutate-revert. Bằng chứng test biết đỏ là `red-first` (core §0 luật 4).
- **Không** sửa `test-design.md` / `frd.md` (core §0 luật 2).
- **Không** nâng pin, **không** dựng roll-up, **không** đụng file scope khác (`test-report-validation.md`, `-e2e.md`… giữ nguyên byte).
- **Không** commit. `/build` commit cả slice một lần: code + test + row contract + row report + tick.
- Một lượt = **một story**. Nhiều story ⇒ nhiều lượt gọi.

## Red Flags

Ở **core §9** — red flags của đường test-trước-code. **Không** đọc `retrofit-core §8`: quá nửa mục ở đó nói về mutate-revert, `--mode`, version-gate và pin, những thứ lượt này không có.

## Verification

- [ ] Mọi TC của story có `Layer` + `Test File`, hoặc có `⏭` + nhãn; không TC nào để rỗng sau `--phase=write`
- [ ] Mọi TC tier `fe:component` có row ở `selector-contract.md` với cột `TC` đã điền
- [ ] `npm test` (hẹp) báo **đỏ** đúng các test vừa viết, và đỏ vì *chưa có code*
- [ ] `git diff` sau `--phase=write`: `test-report-functional.md` có row mới `sanity-red: red-first` + `Result: —`; **không** row nào mang `🟢`/`🔴`; `test_exec_version` không đổi; `test-report-validation.md` · `-e2e.md` không đổi dòng nào
- [ ] Sau `--phase=record`: `test-report-functional.md` có row `red-first` của story này; row của story khác **không đổi byte**; `test_exec_version` **không đổi**
- [ ] `git diff --stat` chứng minh `test-report-validation.md` · `-e2e.md` không đổi dòng nào
