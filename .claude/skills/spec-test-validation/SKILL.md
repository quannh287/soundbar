---
name: spec-test-validation
description: Viết validation test của các VR thuộc MỘT Story TRƯỚC khi có code, ở ③ Build bên trong vòng lặp inner của /build — lọc TC scope validation theo vr[].us của spec-lite check-vr-refs --json (KHÔNG suy lại quan hệ AC → US), quyết seam từ tech.md, điền Layer + Test File vào test-exec-validation.md, viết test rồi chạy để thấy nó ĐỎ rồi ghi ngay row sanity-red red-first với Result — vào test-report-validation.md, xen kẽ với code làm nó xanh. --phase=record cập nhật Result — thành 🟢, merge theo TC ID, KHÔNG nâng pin. VR đã có test từ slice trước thì CHỈ chạy lại, không viết trùng. Bản cho code đã có là /spec-test-retrofit-validation. Import references/test-core.md.
---

# Spec Test Validation — sàn VR của một Story

## Overview

Viết **validation test neo `VR-F*`** của các VR **thuộc** một `US-F*`, **trước** khi có code. Khác `/spec-test-functional` ở **vai**, không ở cơ chế: TC của `AC` **mở và đóng** slice, còn TC của `VR` là **sàn bên trong** — nó không mở slice, nhưng slice **không được commit** nếu nó còn đỏ ([`05-concepts.md §15`](../../05-concepts.md)).

**Cỗ máy lõi ở [`references/test-core.md`](../../references/test-core.md)** — 4 luật bất di (§0) · điền test-exec (§2) · tier vocabulary (§2a) · reconcile + anchor 2 chiều (§2b) · seam theo tầng (§3) · ghi `test-report-{scope}.md` (§7) · **lượt outer ở ③ Build (§7c)** · red flags của đường test-trước-code (§9). **Đọc file đó trước.**

**KHÔNG import [`retrofit-core.md`](../../references/retrofit-core.md)** — cùng lý do như skill functional.

**Nhịp:** TC của `VR` **không gom lên đầu** cùng TC của `AC`. Mỗi cái viết **ngay trước** đoạn code làm nó xanh. Gom cả ba tầng rồi mới gõ code là test-first waterfall.

## When to Use

- `/build` đang ở vòng trong của một Slice và cần sàn VR của story đó — **đường gọi chính**, không gõ tay.
- Gõ tay để thử một story trên bed, khi `test-exec-validation.md` đã có khung và feature **chưa có code**.

## When NOT to Use

- Feature **đã có code** và đang ở ④ Verify → `/spec-test-retrofit-validation`.
- Muốn test `AC-F*` → `/spec-test-functional`.
- Story không có `VR` nào neo vào → không có gì để làm ở lượt này; đó là trạng thái hợp lệ.
- Chưa có `test-exec-validation.md` → chạy `/spec-test {slug}` trước.

---

## Tham số

- **`{F-XXX}`** *(bắt buộc)* — feature id.
- **`--story={US-F*}`** *(bắt buộc)* — đúng **một** story.
- **`--phase=write`** — điền wiring, viết test, chạy để thấy đỏ, rồi ghi **hai ô** vào report: row của TC + `sanity-red: red-first`, `Result` để `—`. **Không** ghi `Result` khác `—`, **không** đụng pin.
- **`--phase=record`** — chạy lại, ghi row vào `test-report-validation.md`. **Không** chạm `test-exec`.

---

## Process

### Bước 1: Lọc TC theo `vr[].us` *(cả hai phase)*

Chạy `spec-lite check-vr-refs {đường-dẫn-frd} --json` rồi giữ VR có story được truyền vào nằm trong `vr[].us`.

```
VR có `Refs` trỏ thẳng US       ⇒ vr[].us chứa US đó
VR có `Refs` chỉ trỏ một AC     ⇒ vr[].us đã quy về US sở hữu AC đó
```

- **Đọc field, KHÔNG suy lại.** Phép *"AC này thuộc US nào"* đã được làm cơ học ở `check-vr-refs`; suy lại ở đây là chỗ thứ ba cùng làm một việc, và mỗi lượt LLM suy ra một kiểu.
- Lệnh trả `exit != 0` ⇒ **dừng**, báo chạy `check-vr-refs` và sửa `frd.md` trước. VR mồ côi là lỗi đã bị chặn từ `/spec-new`/`/spec-frd`, gặp ở đây nghĩa là có gì đó đi vòng.
- Từ tập VR đó, lấy TC ở bảng `Test Cases` của `test-exec-validation.md` có `Covers` chứa VR tương ứng.
- Tập rỗng ⇒ dừng, báo *"story này không có VR neo vào"*. Hợp lệ, không phải lỗi.

### Bước 2: Chưa có test thì viết, có rồi thì chạy lại *(`--phase=write`)*

Một `VR` neo vào **nhiều** story là chuyện bình thường. Với mỗi TC:

| Trạng thái | Làm gì |
|---|---|
| Ô `Test File` **rỗng** | slice chưa tới ⇒ điền wiring + viết test (Bước 3–5) |
| Ô `Test File` **đã có** | slice trước đã viết ⇒ **chỉ chạy lại**, không viết trùng (core §2b) |

Cả hai trường hợp, TC đó **phải xanh** trước khi slice được commit. Một TC đã từng xanh mà lượt này đỏ là **regression — defect thật**, không phải "chưa code tới": dừng, trả người.

### Bước 3: Quyết seam từ `tech.md` + điền wiring *(`--phase=write`, chỉ TC chưa có test)*

- Seam lấy từ bảng seam của `tech.md`. **Không đọc code** — ở ③ Build code chưa tồn tại.
- `VR` chủ yếu rơi vào **chân BE**, rẻ nhất là `be:unit` (hàm thuần). Bộ vocabulary ở **core §2a**.
- Điền `Layer` + `Test File`, ghi `test-exec-validation.md` **một lần** cho cả story. `version` **không bump** (core §7c.1).
- Đã xét mà không viết được ⇒ `⏭` + nhãn. Ô rỗng là *slice chưa tới*, khác `⏭`.

### Bước 4: Viết test — 1 positive + ≥1 negative *(`--phase=write`)*

- Giá trị hợp lệ/vi phạm lấy từ **câu chữ VR** trong `test-design.md`, không từ code (core §0 luật 1).
- Mỗi TC một `it`, tên chứa `TC-F*` (core §2b).
- TC mang `blocked-by-spec` (không có oracle vì frd im lặng) ⇒ **không viết test**, ghi `⏭ need-clarify`. Không tự chế `Expected`.

### Bước 5: Chạy → phải **ĐỎ**, rồi để `/build` làm xanh *(`--phase=write`)*

- Chạy hẹp. **Phải đỏ**, và đỏ vì *chưa có validator*.
- Xanh ngay ⇒ dừng, báo người — hoặc code đã có, hoặc test không assert gì.
- **Ngoại lệ — row đã mang `red-first`:** nhịp đỏ đã lập ở lượt trước, slice này đang **chạy lại sau khi bị ngắt**. Xanh ngay là đúng; đi tiếp, không báo động.
- Đỏ vì **harness thiếu / seam gõ nhầm / thiếu dev dependency** ⇒ **test-error**, sửa test rồi chạy lại.
- **`module not found` của chính module slice này sắp viết LÀ nhịp RED hợp lệ** — file sản phẩm chưa tồn tại thì test import nó phải nổ. Phân biệt bằng đường dẫn: nằm trong tập file `tech.md` khai slice sẽ tạo ⇒ RED; nằm ngoài ⇒ test-error (core §9).
- **Ngay sau khi thấy đỏ, ghi row vào `test-report-validation.md`** với `sanity-red: red-first` và `Result` để `—` (core §7c.7). Bằng chứng *"đã thấy đỏ trước khi có code"* xuống đĩa **ngay lúc nó phát sinh**, không chờ cuối slice — slice bị ngắt giữa chừng thì nó vẫn còn. `Result` khác `—` là việc của `--phase=record`.
- `/build` viết validator rồi chạy lại. **Không** đụng pin, **không** commit ở lượt này.

### Bước 6: Ghi row *(`--phase=record`)*

- Chạy lại **mọi** TC của bước 1 — gồm cả TC chỉ-chạy-lại của slice trước.
- Cập nhật row đã có từ `--phase=write`: `Result` `—` → **`🟢`** (§4 `Results` không có cột `date`; `date` là field frontmatter, refresh ở cấp file). `sanity-red` **giữ nguyên** `red-first`, `mutation`/`reverted` giữ `—`. Row chưa tồn tại ⇒ ghi mới đủ bốn ô.
- TC đã có row `red-first` từ slice trước ⇒ refresh `Result`, **`sanity-red` giữ nguyên** (core §7c.2). Không có giá trị riêng cho lượt chạy lại, và **không** ghi `—`.
- **Chỉ row của các VR thuộc story này.** Merge theo `TC ID` (core §7c.6).
- `mode` để `cycle`. Pin **không đổi** (core §7c.5). **Không** dựng roll-up.

---

## Ràng buộc

- **Không đọc code sản phẩm**; seam từ `tech.md`, oracle từ `test-design.md`.
- **Không** suy lại quan hệ `AC → US` — đọc `vr[].us`.
- **Không** mutate-revert; bằng chứng là `red-first` (core §0 luật 4).
- **Không** sửa `test-design.md` / `frd.md`.
- **Không** nâng pin, **không** dựng roll-up, **không** đụng `test-report-functional.md` / `-e2e.md`.
- **Không** commit — `/build` commit cả slice một lần.
- Một lượt = **một story**.

## Red Flags

Ở **core §9**. Thêm một cái chỉ có ở tầng này: **viết lại test cho một `VR` mà slice trước đã viết** — VR dùng chung hai story thì slice thứ hai chỉ chạy lại. Viết trùng là đẻ hai test cùng một luật, và lần sau sửa một bên là lệch bên kia.

## Verification

- [ ] Tập VR lấy từ `vr[].us` của `check-vr-refs --json`, không parse tay `frd.md`
- [ ] Mọi TC của story có `Layer` + `Test File`, hoặc `⏭` + nhãn
- [ ] TC của VR đã có test ở slice trước: **không** file test mới nào được tạo cho nó
- [ ] `npm test` (hẹp) báo **đỏ** đúng các test vừa viết, đỏ vì *chưa có validator*
- [ ] `git diff` sau `--phase=write`: `test-report-validation.md` có row mới `sanity-red: red-first` + `Result: —`; **không** row nào mang `🟢`/`🔴`; pin không đổi; `test-report-functional.md` · `-e2e.md` không đổi dòng nào
- [ ] Sau `--phase=record`: `test-report-validation.md` có row `red-first`; `test-report-functional.md` **không** đổi dòng nào; `test_exec_version` **không đổi**
