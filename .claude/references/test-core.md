# Test Core — luật dùng chung cho mọi skill ghi test-side

> Shared core cho **hai họ skill**, khác nhau ở thứ tự code/test nhưng dùng chung hình dạng artifact:
>
> | Họ | Skill | Chạy ở | Test viết |
> |---|---|---|---|
> | **outer** | `/spec-test-functional` · `/spec-test-validation` | ③ Build, trong một Story slice | **trước** code |
> | **retrofit** | `/spec-test-retrofit-validation` · `-functional` · `-e2e` | ④ Verify, trọn scope của feature | **sau** code |
>
> File này giữ phần **không phụ thuộc thứ tự**: điền test-exec · tier vocabulary · reconcile + anchor 2 chiều · seam theo tầng · prune · ghi report + roll-up. Phần chỉ đúng cho đường code-trước-test — vòng lặp quét A/B, version-gate, refresh mode, mutate-revert, phân loại đỏ thành finding — ở lại [`retrofit-core.md`](retrofit-core.md).
>
> **Số section giữ nguyên số cũ của `retrofit-core.md`** (nên có chỗ nhảy số: không có §1, §4, §5, §8). Cố ý — mọi trích chéo `§2a`, `§2b`, `§7`, `§7b` rải khắp repo vẫn trỏ đúng chỗ sau khi tách.
>
> Thiết kế: [`.docs/034`](../.docs/034-double-tdd.md) `DS11`.

---

## 0. Bốn luật bất di (đọc trước mọi thứ)

1. **Giá trị đúng derive từ spec** (`frd.md` → `test-design.md`), **KHÔNG** từ code. Code chỉ cho biết *gọi ở đâu*, không cho biết *đúng là gì*.
2. **KHÔNG sửa `test-design.md` / `frd.md`** trong lúc chạy skill. Thấy sai ⇒ ghi finding, để người quyết.
3. **Result + Finding chỉ sống ở `test-report-{scope}.md`.** `test-exec-{scope}.md` là *spec của test code* — không chứa kết quả chạy.
4. **Test xanh phải có bằng chứng nó biết đỏ.** Hai đường, tuỳ test được viết trước hay sau code:
   - **Code có trước, test viết sau** (`/spec-test-retrofit-*` ở ④ Verify) ⇒ bằng chứng là **mutate code sản phẩm rồi revert** ([`retrofit-core.md`](retrofit-core.md) §4), ghi `sanity-red: proven-red`.
   - **Test có trước, code viết sau** (`/spec-test-functional` · `/spec-test-validation` ở ③ Build) ⇒ bằng chứng là **đã thấy nó đỏ trước khi có code**, ghi `sanity-red: red-first`. Mạnh hơn mutate-revert và không tốn chu kỳ nào.

   Xanh mà không có bằng chứng nào ⇒ **không được tính pass**.

---

## 2. Điền test-exec (spec của test code)

Ghi ở **mức spec/bản đồ**, KHÔNG chép boilerplate test code (013 §4.3). Cột trong test-exec:

```
TC → layer · Test File (nơi test) · assert-gì (một dòng) · giá trị đúng · testid
```

- **layer / Test File / testid** = "móc vào đâu" → **đọc code** mới biết. `Test File` = *nơi test sẽ nằm* (`describe > it` / method), KHÔNG phải file sản phẩm.
- **Seam** (file sản phẩm enforce rule) KHÔNG có cột riêng — nó đã encode qua `layer` (= giá trị Tier, xem §2a). Chỉ note seam vào cột assert/Note khi seam **mơ hồ** cần review trước khi viết; feature thường thì thừa.
- **giá trị đúng / assert-gì** = "cái gì đúng" → **từ spec** (luật 1), chốt ngay khi điền khung, không nắn theo code.
- Đủ chặt để review chỗ đặt test trước khi tốn công viết + tra ngược `TC ↔ Test File ↔ VR/AC`. Không hơn.

---


---

## 2a. Tier vocabulary — 2 chân BE/FE, xếp theo chi phí

**Tier = "phải dựng bao nhiêu thứ mới test được rule ở seam đó"** (test-pyramid cost), KHÔNG phải thứ tự runtime. Tier là **theo stack**: BE và FE có khúc giữa khác nhau, chỉ gặp nhau ở `e2e`. Ghi tier bằng **prefix stack** trong cột Tier (`be:`/`fe:`, riêng `e2e` không prefix vì là điểm gặp). Nguyên tắc bất di: **enforce được ở tier rẻ nhất thì test ở đó**; chỉ leo lên khi rule *chỉ* sống ở tầng cao hơn.

**Chân BE** (Clean Architecture, rẻ → đắt):

| Tier | Layer | Rule kiểu | Harness |
|---|---|---|---|
| `be:unit` | Domain + Contract | format/length/range/required, formula thuần, entity invariant | `new` object — **không I/O** |
| `be:handler` | Application (business logic) | orchestration: unique-check, mutual-exclusion, immutable, computed **bằng C#** | **fake repo + fake UoW** — không DB |
| `be:persistence` | Persistence.EF (storage) | schema enforce: **FK/membership**, unique index, EF query translation, global filter/interceptor | **DB thật in-memory** (vd SQLite) + DbContext |
| `be:api` | Presentation/API | HTTP pipeline: model-binding 400, auth 401/403, routing | full-HTTP integration (vd WebApplicationFactory) |

**Chân FE** (rẻ → đắt):

| Tier | Layer | Rule kiểu | Harness |
|---|---|---|---|
| `fe:unit` | pure fn / schema / formatter / hook logic | format/validate client-side, tính toán thuần | test runner (vd vitest, hoặc tương đương mobile: `dart test`) — **không DOM/widget tree** |
| `fe:component` | UI component | hành vi render/tương tác: hiện lỗi, disable, đổi state | render + DOM (vd Testing Library, hoặc tương đương mobile: `flutter_test` + `WidgetTester` — gọi là "widget test") |
| `fe:api` | FE↔API boundary | gọi API + xử lý response, với backend mock | mock transport (vd MSW) |

**Đỉnh chung:** `e2e` — full-stack, browser/app thật + server thật (web: Playwright; mobile: **Maestro**, bắt buộc — flow YAML, black-box qua Semantics/accessibility tree, không có DOM/HTTP client trong tay). Cả hai chân gặp nhau ở đây. Mobile: `flutter test integration_test/*.dart`/`flutter_test` (kể cả chạy trên thiết bị/simulator thật) **không** phải `e2e` — cùng process với app (white-box), không qua Maestro; xếp cao nhất là `fe:component`/`fe:api`. Chưa có Maestro trong project = chưa có tier `e2e` cho mobile, không phải "coi tạm `integration_test` là e2e".

- ⚠ `be:handler` vs `be:persistence` = ranh giới **"logic C# chạy được bằng fake repo"** vs **"phải có DB thật vì rule sống trong schema/FK/SQL query"**. FK membership, unique index, phép suy diễn nằm trong EF query → `be:persistence` (fake repo không mô phỏng nổi).
- ⚠ Tier là **thuộc tính của SEAM trong code**, không phải của test-design (§3). Skill tầng chọn tier từ code, ghi vào cột `Tier` của §4 Results. **KHÔNG** có bảng tổng theo tier ở report nào (030 D18) — ai cần phân bố pyramid thì đếm từ cột đó.

---


---

## 2b. Reconcile với test có sẵn + anchor 2 chiều (TC ID)

Brownfield thường **đã có test cũ** (không neo requirement). Trước khi viết mới ở mỗi seam:

0. **Với harness black-box tách khỏi source (Maestro, Playwright ID-based, …): kiểm identifier/locator test cũ dùng còn khớp code thật không TRƯỚC khi tin nó "pass" hay "sẵn sàng dùng lại"** — một identifier đổi tên trong code (refactor bình thường, không ai nhớ cập nhật flow) để lại test cũ đỏ-ngầm mà không compiler nào bắt được, chỉ lộ ra khi thật sự chạy trên thiết bị/browser. `grep` nhanh danh sách identifier trong contract/flow vs identifier thật trong code (`grep -rn "identifier: '"`, `data-testid=`, …) rẻ hơn nhiều so với phát hiện giữa chừng lượt chạy thật. Lệch → tự sửa (additive, cùng dạng đổi tên) rồi mới tiếp tục — đây là test-error, không phải finding cần user quyết.
1. **Quét test hiện có** ở seam đó (validator/handler/component tương ứng).
2. **Anchor 2 chiều qua TC ID** — bắt buộc để tra ngược `test-exec ↔ code`:
   - Forward: cột `Test File` trong test-exec trỏ tới `describe > it` / method.
   - Backward: TC ID **nhúng máy-đọc-được + runner lọc được** trong test. Đây là **bất biến**; *cách* nhúng **tùy framework** — chọn construct idiomatic mà test runner có thể `filter` theo:
     - NUnit/xUnit (.NET): `[Category("TC-F003-040")]` (hoặc TC ID trong tên method) → `--filter "TestCategory~TC-..."`
     - vitest/jest (FE): TC ID trong tên — `it("TC-F003-040 — ...")` → `-t "TC-..."`
     - pytest: marker `@pytest.mark.tc_f003_040` → `-m`; JUnit5: `@Tag(...)`; Go: tên `TestTC_...` → `-run`
     - Framework KHÔNG có cơ chế tag → nhúng TC ID vào **tên test** (runner nào cũng filter theo tên được).
     - Tiêu chí chọn duy nhất: *runner có filter theo nó được không?* KHÔNG dùng comment lỏng (`// TC-...`) — không tra ngược/lọc tự động được.
3. **Đối chiếu test cũ với spec (luật 1)** — quyết định theo *spec text*, KHÔNG theo sự tồn tại của test:
   - Test cũ assert **đúng VR/AC text** → **inherit**: stamp TC ID + trỏ `Test File` vào nó, ghi `sanity-red = inherited` ở §4 Results. KHÔNG viết trùng.
   - Test cũ assert **theo behavior code mà lệch spec** (test soi gương code) → đây là **finding**, KHÔNG tính "đã cover": giữ test cũ nguyên (đọc-xuống), viết test mới neo đúng spec → để đỏ → classify (§5). Test cũ mâu thuẫn = tín hiệu bug-code/spec-drift.
   - Test cũ assert **đúng spec nhưng oracle yếu hơn tầng này đòi** (vd journey e2e assert đủ hành vi mà không có bước `[verify-db]`/`[verify-api]`; negative TC thiếu kiểm *lý do* reject) → **inherit rồi siết oracle**: neo TC ID + **thêm** bước/assert còn thiếu vào chính test đó, ghi lý do ở cột `Note`. KHÔNG viết test trùng cạnh nó (journey e2e trùng là chi phí đắt nhất trong suite), cũng KHÔNG coi là đã cover khi oracle chưa đủ.
   - Chưa có test ở seam → viết mới.

> **"Siết oracle" khác "sửa test cho khớp code" ở chiều đi.** Siết = thêm điều kiện, kéo test **về phía spec** (bỏ mutation vào là nó đỏ). Sửa-cho-khớp-code = bỏ/nới điều kiện, kéo test **về phía code đang chạy** — cấm. Dấu hiệu phân biệt: sau khi sửa, test có bắt được nhiều lỗi hơn hay ít hơn?

> Cạm bẫy: "tái dùng test cũ" mù quáng nuốt mất bug (test cũ đóng băng behavior code, không phải requirement). Reconcile luôn theo **spec text**.

---


---

## 3. (giữ chỗ) — lớp seam đặc thù tầng

Cách **chọn seam** khác nhau theo tầng → định nghĩa trong từng skill tầng, KHÔNG ở core. Tier dùng bộ vocabulary §2a (prefix stack), ưu tiên bậc rẻ nhất:
- VR → BE: `be:unit` (validator) → `be:handler` (unique/immutable/mutual-exclusion/computed-C#, fake repo) → `be:persistence` (FK/membership/unique-index/EF-query, DB in-memory) → `be:api` (CHỈ khi rule ở tầng HTTP: model-binding/auth). FE: `fe:unit` (schema client-side). Ưu tiên bậc thấp nhất.
- AC → BE `be:api`/`be:handler` vs FE `fe:component`/`fe:api` (013 §3).
- FAC → `e2e` full-browser (web) / full-app trên build thật (mobile) cross-story.

> **Seam xác định từ CODE, KHÔNG từ cột layer của test-design** (áp cho cả 3 tầng) — hệ quả trực tiếp của luật 1 (§0). test-design gợi ý layer có thể sai (vd ghi "api" nhưng rule thật enforce ở handler) → theo code, chọn bậc thấp nhất khả thi; lệch test-design thì ghi Note ở test-exec (đọc-xuống, không sửa test-design).
>
> **Oracle đọc NỘI DUNG của một handle ⇒ PHẢI đọc code render handle đó trước khi viết assert.** Luật 1 (§0) nói giá trị đúng lấy từ VR/AC/FAC, không từ code — vẫn giữ. Nhưng *"handle nào chở giá trị đó"* là câu hỏi về **code**, không phải về spec, và cột `Element` của contract **không có lưới nào kiểm** (`references/testid-conventions.md` §3d): mọi gate quanh contract chỉ kiểm handle **tồn tại**, không kiểm mô tả **đúng**. Tin mô tả sai ⇒ oracle sai mà mọi cổng vẫn xanh.
>
> Ca thật: contract ghi `profile-username` = "mã nhân viên", code là `hoSo?.roleName ?? employeeCode` ⇒ oracle "assert == mã NV" **đỏ** với tài khoản có `roleName`, **xanh** với tài khoản không có. Sai **không ổn định**, theo fixture — trông tất định nên không ai nghi.
>
> Vậy: assert theo **sự tồn tại/hiển thị** của handle thì đọc contract là đủ; assert theo **nội dung** thì mở file render ra xem. Mô tả contract lệch code ⇒ **sửa contract trong CÙNG commit** — ngoại lệ hẹp của đọc-xuống, cùng hạng với việc điền cột `TC` (`.docs/026` D5): sửa **mô tả cho khớp code đang chạy**, KHÔNG sửa giá trị mong đợi của test.

> **Seam cần harness project CHƯA có = escalate kiến trúc, KHÔNG tự dựng trong skill.** Retrofit skill chỉ *viết test* trên harness project đã định nghĩa (scaffold/architecture). Nếu seam thật sự nằm ở tầng chưa có harness (vd full-HTTP integration khi project chỉ có test layer-isolated) → báo user như một quyết định kiến trúc (thêm fixture/project + cập nhật doc test-strategy), rồi mới retrofit tiếp. Đừng để mỗi feature đẻ một kiểu harness.
>
> **Escalate là "dừng CÓ BIÊN BẢN", không phải "dừng im".** Trước khi báo user, tầng vẫn ghi trọn bản ghi của những gì nó biết: row `⏭ {tag}` ở §4 cho mọi TC bị chặn, một `BLK-*` ở §3 nêu hạ tầng cần dựng, một dòng §5 với `PIC` = `👤 DEV`, **nâng pin**, dựng lại roll-up. Dừng trước khi ghi để lại `pin 0` + §4 rỗng — **không phân biệt được với "chưa ai chạy tầng này"**, và lượt sau dispatch lại vô ích. Ca kinh điển là tầng e2e thiếu Playwright/POM/seed.
>
> **⚠ Verify "chưa có harness" bằng filesystem, không bằng ghi chú trong test-exec.** Frontmatter/note cũ (vd "repo KHÔNG có `.maestro/`") có thể **lỗi thời** — harness được dựng sau ở một PR/feature khác mà doc test-exec của feature đang retrofit chưa cập nhật theo. Trước khi kết luận thiếu harness và escalate (hoặc trước khi chấp nhận một harness thay thế yếu hơn), chạy lệnh liệt kê thật (`ls .maestro/`, `find . -maxdepth 2 -iname "playwright.config.*"`, …) — đừng suy ra "chưa có" chỉ từ việc một doc nói vậy.

> **⚠ Phân biệt "harness" với "refactor-để-test" (KHÔNG gộp — §3b).** Khi một TC "không test rẻ được ngay", có HAI nguyên nhân khác bản chất; phải chẩn đoán đúng vì cách mở khoá + chủ sở hữu + chi phí khác hẳn:
>
> Ranh giới **KHÔNG phải** "logic thuần vs render". Nhiều rule render/tương tác vẫn là `refactor` (xem dưới). Ranh giới đúng = **"mở khoá cần DỰNG hạ tầng test chung MỚI, hay chỉ cần TÁCH một mảnh code ra rồi test bằng đồ nghề đã có?"**
>
> - **refactor** — mở khoá bằng **tách/expose một seam trong code sản phẩm** rồi test bằng **hạ tầng test SẴN CÓ**, KHÔNG dựng infra mới. Seam có thể là:
>   - **hàm/const thuần bị chôn** trong resolver/handler/component non-export → extract ra hàm thuần / export → `be:unit`/`fe:unit`.
>   - **hành vi render/tương tác bị chôn inline trong một component/page lớn** → tách thành **component props-driven** (`<X count onConfirm/>`) → render **độc lập** bằng render-harness đã có (vd Testing Library đã cấu hình), truyền prop + spy, **KHÔNG** phải mock cả graph tRPC/router của page. Vẫn là `fe:component` nhưng rẻ + không cần infra mới.
>   - Mở khoá = **refactor code sản phẩm nhỏ** (owner duyệt).
> - **harness** — kể cả **sau khi đã tách seam hợp lý**, để chạy test **vẫn buộc dựng/mở rộng hạ tầng test dùng chung MỚI**: DB thật in-memory (shape query/FK/unique-index), full-HTTP factory (rule ở tầng HTTP/middleware), Proxy-mock cả graph tRPC/provider mà component không thể tách khỏi. Mở khoá = **đầu tư hạ tầng test chung** (quyết định kiến trúc).
>
> **Test chẩn đoán (2 nấc):** ① *"Viết assert được ngay không?"* — không (mơ hồ) → `need-clarify`; không có nhánh nào → `no-seam`. ② được → *"Có đường **tách/expose seam** (hàm thuần HOẶC component props-driven) để test bằng **infra sẵn có** KHÔNG?"* → **Có** = `refactor` (ưu tiên — rẻ, không tốn infra). → **Không** (kể cả sau tách vẫn buộc dựng infra chung mới) = `harness`.
>
> ⚠ **Bẫy thường gặp:** thấy rule "là render" hoặc "nằm trong page 3800 dòng phải Proxy-mock" → vội tag `harness`. Hỏi lại: nhu cầu Proxy/infra đến từ **bản chất rule**, hay chỉ vì code đang **bị chôn ở vị trí** khó chạm? Nếu tách một component/hàm ra là hết cần Proxy → đó là `refactor`, không phải `harness`.
>
> **Ranh giới với việc skill tự làm:** một **export behavior-preserving cực nhẹ** (thêm `export` cho const/hàm đã tách sẵn) skill CÓ THỂ tự làm inline để chạm seam (giống thêm `data-testid` ở tầng functional) — ghi rõ trong report. Nhưng **extract logic ra khỏi thân resolver/component** (đổi cấu trúc code) = refactor thật → **KHÔNG tự làm**, defer `refactor` + Action Item cho owner duyệt.

---


---

## 6. Prune

TC / hành vi trong bộ test-exec **không neo được VR/AC/FAC ID nào** → **bỏ**. Không có section riêng cho việc bỏ: phần cần người xử (đề xuất nâng thành requirement thật trong frd qua `/spec-new`) là **việc** ⇒ vào §5 `Next Actions` của report scope; phần "đã bỏ, xong" thuộc **commit message**. KHÔNG giữ TC mồ côi. Suite phải **100% traceable** tới ID.

---


---

## 7. Ghi report của scope

Output chính của skill tầng là **`test-report-{scope}.md`** trong `.specs/tests/{F-XXX}-{slug}/` — **một file / scope, đúng một skill được ghi** (030 D0). Skill tầng **không đọc, không ghi** file scope khác. Sau khi ghi xong file của mình thì **dựng lại roll-up** `test-report.md` (§7b).

**Mỗi lần ghi là dựng lại trọn file rồi ghi đè** — không mổ từng bảng con. Trong một lượt chạy scope thì ghi **nhiều lần**, §4 lớn dần theo từng TC đã xong (§7.0). Đầu vào gồm **lượt chạy này** *và* **bản trước của chính file đó** (file scope là chỗ lưu duy nhất của `sanity-red`/`mutation` và seam chỉ đọc code mới có). Ô nào tính lại, ô nào kế thừa:

| Ô | Dựng lại bằng | Mỗi lượt |
|---|---|---|
| `Covers` · §1 Summary · Coverage · dòng `**Mục:**` | đọc `test-design.md` + đếm lại §4 | **tính lại**, CẤM chép bản cũ |
| `Result` 🟢/🔴 | chạy test | **chạy lại** — nó là sự thật của lúc này |
| `Tier` · `Action` · `Note` (wiring) | đọc code | **kế thừa**; nguồn ghi duy nhất là `--mode full` (§1c) |
| `sanity-red` · `mutation` · `reverted` | mutate → chạy → revert | **kế thừa**, có kiểm (xem dưới) |
| §2 verdict | phân loại lại test đỏ | **kế thừa** cho TC `UNCHANGED`; TC `MODIFIED` chấm lại (§1b) |
| số đếm ID đã cấp (`FIND-VAL-03`) | — | **mang sang**, cấp số tiếp |

**Đọc được tên cũ của `sanity-red` (034 `D16`).** Report sinh trước 2026-09-18 ghi `✅` thay `proven-red` và `inh` thay `inherited`. Writer **đọc cả hai**, **ghi tên mới**:

| Bản trước ghi | Kế thừa thành |
|---|---|
| `✅` | `proven-red` |
| `inh` | `inherited` |

Không có bước migrate riêng: writer nào dựng lại file cũng tự đổi, và file scope không mang `template_version` nên không có gate nào để lệch. Đổi tên vì `✅` **trùng glyph** với cột `reverted` trong cùng một row (hai nghĩa khác nhau, cách nhau ba cột) và tạo **thứ bậc giả** — nó trông như "cái tốt" trong khi `red-first` mới là bằng chứng mạnh hơn.

**Kế thừa không phải chép mù:** chỉ TC `UNCHANGED` mới kế thừa (`NEW`/`MODIFIED` chạy full-loop — §1b); `mutation` cũ dùng như **công thức** — mutate lại đúng chỗ đó, test đỏ ⇒ còn bám code, giữ; không đỏ ⇒ code đã trôi, đọc code tìm seam mới (§1c); `sanity` thấy `Tier` nghi sai thì **flag**, không tự sửa.

### 7.0 Thời điểm ghi — §4 `Results` ghi tăng dần

Không dồn mọi thứ vào một lần ghi ở cuối scope. Bị kill giữa scope là mất sạch bằng chứng đã trả tiền — mà `sanity-red` là thứ đắt nhất trong lượt retrofit.

| Việc | Khi nào |
|---|---|
| ghi wiring của **mọi** TC vào `test-exec-{scope}.md` | một lần, **trước** chu kỳ mutate đầu tiên |
| ghi row của một TC vào §4 `Results` | **ngay sau** khi revert + verify-green của TC đó xong |
| tính lại §1 `Summary` + dòng `**Mục:**` | mỗi lần ghi (vốn đã derive từ §4) |
| nâng pin `test_exec_version` | **chỉ** khi cả scope xong |
| dựng lại roll-up `test-report.md` | **chỉ** khi cả scope xong |

**Lượt sau kế thừa được** vì §4 đã có row của những TC đã xong: đọc bản trước **của chính file mình** rồi kế thừa `sanity-red`/`mutation`/`reverted`/`Tier` cho chúng, chỉ re-execute. Đường kế thừa này §7 đã mở — trước đây không có gì để kế thừa vì file chỉ được ghi một lần ở cuối.

**Phân biệt "chạy xong" với "chết giữa scope":** `pin < version` **và** số row §4 `Results` **có `Result` khác `—`** **<** số row bảng **`Test Cases`** của `test-exec-{scope}.md`. **Đếm row có result, KHÔNG đếm row** — scope chạy dở có thể có đủ row mà một phần còn `—`, lúc đó so số row ra `n < n` (sai) và bộ nhận biết kết luận "chưa từng chạy"; scope chưa từng chạy có **0** row (đo được 2026-09-10 trên `F-005`). Gọi bảng bằng **tên**, không bằng số section: nó ở §4 với `validation`/`functional` nhưng **§5** với `e2e` (file e2e có thêm `Integration Points`). Mẫu số là **test-exec**, KHÔNG phải `test-design.md` — test-design đếm cả TC `Autoable = NO` (ca visual), nên so với nó thì feature có một TC visual báo "chết giữa scope" dương giả vĩnh viễn.

**CẤM ghi row trước khi revert + verify-green xong** — row đó nói TC xanh trong khi code sản phẩm vẫn đang mang mutation.

### 7.1 Format — 5 section, đúng thứ tự

`1 Summary` → `2 Findings` → `3 Blockers` → `4 Results` → `5 Next Actions`. Đọc theo dòng chảy *tổng quan → sai gì → chưa kiểm được gì → chi tiết → chốt việc*. Template: `templates/tests/test-report-scope-template.md` (một bản dùng chung cho cả 5 scope).

> **Format fidelity — BẮT BUỘC.** CHỈ 5 section trên. KHÔNG `Pruned`, KHÔNG `Observations` (đã đổi tên thành `Blockers`), KHÔNG `Sanity-Red Ledger`, KHÔNG `Change History`/timeline/run-log, KHÔNG blockquote kể-chuyện. Report = **trạng thái mới nhất**; lịch sử "đã làm gì qua thời gian" = **git log/diff + commit message** (015 §3B). Cần cột/section mới → sửa **template trước**, không tự chế lẻ trong một report.

**Report toàn bảng.** Thân file chỉ được gồm 4 loại dòng: heading `## N. Tên` · bảng (dòng bắt đầu `|`) · blockquote `>` (≤3 dòng mỗi khối, nói nguồn/luật của section) · dòng chú giải `**Nhãn:** …` (đúng 1 dòng). **Cấm** đoạn văn trần, bullet nhiều dòng, câu kể quá trình (*"đầu tiên… sau đó…"*), blockquote narrative.

**Trần ký tự + khuôn câu mỗi cột** *(dòng `**Mục:**` miễn trần — nội dung là anchor link)*:

| Cột | ≤ | Khuôn | ✅ | ❌ |
|---|---|---|---|---|
| `Evidence` | 120 | `<file>:<sym> — <thực tế> ≠ <spec đòi>` | `usecase/auth.ts:register — trả null ≠ AC đòi session` | "code trả về null khi điều kiện X, trong khi AC yêu cầu…" |
| `mutation` | 120 | `<file>:<sym> — <thay đổi>` → `<TC>` 🔴 | `domain/user.ts: bỏ EMAIL_RE.test` → `TC-F002-011` 🔴 | "đã thử bỏ regex và thấy test đỏ như mong đợi" |
| `Vấn đề` (BLK) | 160 | `<cái chặn>; <vì sao chặn>` — **hai mệnh đề** | `FK membership chưa có fixture; assert cần row cha ở DB thật` | `harness` *(nhãn cụt)* |
| `Cần gì để mở khoá` | 120 | danh từ: hạ tầng / quyết định cần | `DB in-memory dùng chung cho tier be:persistence` | "cần bàn thêm với team" |
| `Việc` | 100 | động từ + đối tượng cụ thể | `sửa createItem nhận ""` | "xem lại validator" |
| `Nguồn` | 40 | **chỉ ID** — `FIND-*` · `BLK-*` · req-ID | `FIND-VAL-01` · `VR-F002-002` | `FIND-VAL-01 vì code sai` |
| `Loại` | 16 | **một** nhãn từ tập đóng 8 nhãn (§7.4) | `bug-code` · `coverage-gap` | `bug + drift` · `cần xem lại` |
| `PIC` | 12 | `🤖` / `👤 DEV`/`👤 BA`/`👤 QC` — **derive** (§7.4) | `🤖` · `👤 BA` | `DEV` *(thiếu nhãn)* |
| `Note` (Results) | 60 | ID BLK · file test · lý do `no-seam` | `BLK-VAL-1` | câu giải thích |

**Lý luận dài đi đâu** — cắt chữ mà không nói chỗ chứa thì chữ mọc lại: luật chung, suy luận dùng được cho mọi feature → **file này** (`retrofit-core`); diễn tiến "đã thử gì rồi đổi sang gì" của lượt này → **commit message**. Report chỉ giữ **verdict + evidence + việc kế**.

### 7.2 Đọc-hiểu — report viết cho người ngoài lượt chạy

Report dùng mã của người trong nghề (`harness`, `no-seam`, `be:persistence`, `sanity-red`, `dup-of`). Viết dài ra từng dòng thì vỡ trần ký tự; bỏ nhãn thì vỡ logic đã định nghĩa. Đường thứ ba: **giữ nhãn, giải nghĩa một lần** ở dòng legend của section.

**Ba câu hỏi report phải tự trả lời** — người đọc chưa từng dự lượt chạy, không mở code / test-design / hỏi lại:

| Câu hỏi | Trả bằng | Đạt khi |
|---|---|---|
| Đủ hay chưa? | §1 Summary | thấy ngay bao nhiêu TC, xanh/đỏ/hoãn bao nhiêu, trụ nào chưa phủ |
| Sai gì? | §2 Findings | mỗi dòng nói được **cái gì lệch cái gì** — không phải chỉ nhãn verdict |
| Chưa kiểm được gì, ai làm gì tiếp? | §3 Blockers · §5 Next Actions | mỗi dòng nói **cái chặn + cần gì để mở**, và ai chốt |

**Legend bắt buộc** — nhãn nào xuất hiện trong bảng thì section định nghĩa nó phải có dòng giải nghĩa (một dòng): §1 ký hiệu result · §2 4 verdict + `dup-of` · §3 nghĩa hai cột `Vấn đề`/`Cần gì để mở khoá` · §4 3 cột sanity-red + 4 tag `Action` + nghĩa các `tier` đang xuất hiện · §5 `🤖` / `👤 <role>`. `/spec-test-exec` scaffold **sinh sẵn** legend — skill tầng giữ lại, không phải tự nhớ.

**Ngôn ngữ:** phần **diễn giải** (`Vấn đề` · `Cần gì để mở khoá` · `Việc` · phần mô tả của `Evidence`) viết **tiếng Việt**; **định danh** giữ nguyên (`TC-F002-010`, `VR-F002-001`, `be:unit`, tên file/hàm, `harness`).

**Khi "ngắn" xung đột với "dễ hiểu": dễ hiểu thắng** — nhưng nới bằng **legend**, không bằng viết dài từng dòng. Trần ký tự giữ nguyên; legend không tính vào trần.

### 7.3 ID namespace + trỏ chéo

| Loại | ID | Phạm vi duy nhất |
|---|---|---|
| Finding | `FIND-VAL-NN` · `FIND-FUN-NN` · `FIND-E2E-NN` *(có skill ghi)* — `FIND-NFR-NN` · `FIND-DM-NN` *(namespace dành sẵn, chưa có writer)* | trong file scope |
| Blocker | `BLK-VAL-N` · `BLK-FUN-N` · `BLK-E2E-N` · … | trong file scope |
| Next Action | `A-VAL-N` · `A-FUN-N` · `A-E2E-N` · … | trong file scope |

- **Tiền tố scope là bắt buộc** — số trơn (`Finding-01`, `OBS-1`, `A1`) đụng nhau khi ba tầng ba file, và roll-up cần trích nguyên văn ID để người đọc biết mở file nào.
- **Append-only trong file scope** — chạy lại scope thì **cấp số tiếp**, không đánh số lại (finding cũ còn được trích trong commit / ADO).
- **Quy tắc 2 chiều:** mọi TC `⏭` mang Action `harness`/`refactor`/`need-clarify` → trỏ đúng **1** `BLK-{SCOPE}-N` ở cột `Note` của §4; mọi `BLK` có ≥1 TC. `no-seam` **KHÔNG** tạo BLK (kết luận tự-chứa → ghi thẳng `Note`). Thứ **không chặn TC nào** (red có sẵn ngoài feature, việc dọn dẹp) không phải Blocker → nó là **việc** ⇒ §5.
- **`dup-of`:** tầng sau thấy verdict cùng nguyên nhân với finding tầng trước (vd một `bug-code` đỏ ở `functional` rồi đỏ lại ở `e2e`) → cột `dup-of` ghi ID tầng trước (`FIND-FUN-01`). Ba file thì không thấy nhau ⇒ đây là **luật**, không phải phát hiện tự động. Roll-up **không** đếm dòng `dup-of` vào `🔴 finding mở`, và dòng `dup-of` **không** sinh action riêng.

### 7.4 Từ `Loại` suy ra `PIC` — map cứng

`PIC` là **derive, không phải lựa chọn**: `Loại` đã chốt ở §2/§3 thì `PIC` suy ra từ bảng này. Muốn khác bảng ⇒ **sửa bảng này**, không lệch lẻ trong một report.

| Đến từ | `Loại` | `PIC` | Vì sao |
|---|---|---|---|
| §2 Findings | `bug-code` | `🤖` | oracle đúng đã có trong VR/AC/FAC; sửa code xong test xanh là bằng chứng đủ |
| §2 Findings | `test-error` | `🤖` | sai ở test/fixture của chính agent, không đụng code sản phẩm |
| §2 Findings | `flaky` | `🤖` | ổn định hoá bằng `waitFor` / cô lập fixture — không đổi hành vi |
| §2 Findings | `spec-drift` | `👤 BA` | code lệch requirement **có dấu vết**, chưa biết bên nào sai ([`05 §14`](../05-concepts.md)); BA quyết ở `/spec-new {F-XXX}` trên sổ `spec-debt.md` của feature, cạnh `frd.md`. Cùng `Loại` cho dòng việc của phép đối chiếu ngược ([retrofit-core §5](retrofit-core.md)): `SD` mở mà không test nào đỏ |
| §3 Blockers | `refactor` | `👤 DEV` | đổi cấu trúc code sản phẩm — owner duyệt (§3b). Nhánh hẹp "extract hàm thuần cùng file" **chưa** nới |
| §3 Blockers | `harness` | `👤 DEV` | dựng hạ tầng test dùng chung = quyết định kiến trúc, phải đưa lên chứ không chắp vá từng feature |
| §3 Blockers | `need-clarify` | `👤 BA` | spec mâu thuẫn với chính nó, với `tech.md` hoặc UI, hoặc thiếu thông tin ⇒ chưa viết nổi assert, quyết định thuộc spec. Spec lệch với **code** thì không phải ca này — đó là finding `spec-drift` |
| §1 Coverage | `coverage-gap` | `👤 QC` | requirement **scope này không phủ được**, hai ca: (a) chưa TC nào phủ ⇒ thêm TC vào `test-design.md`, bump `versions.{scope}`, reconcile xuống test-exec · (b) **có TC nhưng mọi TC đều `Autoable = NO`** (oracle thị giác) ⇒ TC ở lại `test-design.md`, việc là **kiểm bằng mắt**, **KHÔNG** thêm TC và **KHÔNG** bump `versions` |
| §4 Results | `no-seam` | — | không sinh action, không tạo BLK — ghi thẳng cột `Note` |

- **`🤖` nói *máy làm được*, chưa nói *ai làm*.** Ba nhãn `🤖` chia theo **file bị sửa thuộc về ai**: `bug-code` sửa **code sản phẩm** ⇒ [`/fix-findings`](../skills/fix-findings/SKILL.md), phạm vi khoá trong câu chữ requirement mà finding neo vào; `test-error`/`flaky` sửa **test code** ⇒ vốn là remit của chính skill tầng, chạy lại tầng đó `--mode full`. Cho một skill chạm cả hai là hai writer trên cùng file test. `/verify-v2` gọi chúng trong vòng lặp; gõ tay từng cái cũng được.
- **`/fix-findings` từ chối thì dòng vẫn `🤖`.** `PIC` derive từ `Loại`, mà nó không được ghi report (030 `D22`) — nên một `bug-code` đã thử-và-không-sửa-được vẫn in `🤖` ở lượt sau. Phân biệt *chưa ai thử* với *đã thử, không được* bằng `.progress/fix.md`, không bằng bảng này.
- **Role đóng: `DEV` · `BA` · `QC`** — ba giá trị này là tất cả, không đặt tên vai khác. `PIC` chỉ có nghĩa khi tập giá trị đóng.
- **`👤` là vùng đóng băng:** agent **không** sửa, **không** nâng `👤` thành `🤖`, **không** tự chạy skill cascade. Chỉ được **mô tả** việc cần làm.
- **Tập đóng của `Loại` = 8 nhãn:** 4 verdict (§2) + 3 tag sinh action (§3) + `coverage-gap`. `no-seam` không vào bảng vì không sinh action. `Loại` và `PIC` là hai cột riêng, giá trị thuộc tập đóng ⇒ đối chiếu bảng này bằng máy được.

### 7.5 Nội dung từng section

- **§1 Summary** — counts của scope này (`Tổng TC` · 🟢 · 🔴 · ⏭ · 🟡 · —; mỗi TC rơi vào **đúng một** ô ⇒ 5 ô cộng lại = `Tổng TC`) + bảng `Coverage` trụ neo của scope (`VR` / `Story AC` / `FAC` / `NFR` / `DM`) đối chiếu Traceability Matrix của test-design. **Derive từ §4 — tính lại mỗi lần ghi, KHÔNG sửa tay.** **KHÔNG** vỡ theo tier (mỗi bảng tổng là một chỗ nữa lệch được; ai cần phân bố pyramid thì đếm cột `Tier` ở §4). Xanh mà `sanity-red = —` ở `retrofit` đếm vào `—`, KHÔNG vào 🟢.
- **§2 Findings** — mỗi 🔴: `ID` · `TC` · `Covers` · `Verdict` (§5) · `Evidence` · `Action` · `dup-of`. **KHÔNG sửa test cho xanh.**
- **§3 Blockers** — thứ chặn TC không chạy được (`⏭`): `BLK` · `TC bị chặn` · `Vấn đề` (hai mệnh đề, dễ hiểu cho người) · `Cần gì để mở khoá`. Blocker gốc `refactor` → nêu rõ **hàm/seam cần extract**; gốc `harness` → nêu **hạ tầng cần dựng**. Hai vai: tham chiếu dùng-chung (nhiều TC cùng gốc → 1 BLK) + diễn giải cho người.
- **§4 Results** — một dòng / TC của **scope này**, danh sách lấy thẳng từ `test-exec-{scope}.md` (không ai chèn trước — 030 D23): `TC ID` · `Covers` · `Tier` · `Result` · **`sanity-red` · `mutation` · `reverted`** (bắt buộc khi `mode: retrofit`; `cycle` → `—`) · `Action` · `Note`. Giá trị `sanity-red`: `proven-red` mutate code → thấy đỏ → hoàn nguyên, ở **lượt này** · `inherited` kế thừa anchor test cũ **và lượt này không mutate** · `n/a` không mutate trực tiếp (TC positive, hoặc proven qua revert-verify của cụm — §4) · `—` **chỉ** khi TC không chạy. Hai nhãn đầu **không** cùng lúc: test kế thừa mà lượt này vẫn mutate-và-thấy-đỏ thì ghi `proven-red` (bằng chứng mạnh hơn thắng), việc nó là test cũ ghi ở `Note`. Xanh mà `sanity-red = —` ⇒ đếm vào `—` ở §1, không vào 🟢. TC `⏭` → điền `Action` + (nếu `harness`/`refactor`/`need-clarify`) trỏ 1 `BLK` ở `Note`:
  - **`refactor`** — assert đã rõ, mở khoá bằng **tách/expose một seam trong code sản phẩm** rồi test bằng **infra SẴN CÓ**. Seam = hàm/const thuần bị chôn (→ `be:unit`/`fe:unit`) **HOẶC** hành vi render/tương tác chôn inline trong page/component lớn → tách thành **component props-driven** → render độc lập bằng render-harness đã có (`fe:component`, không mock cả graph tRPC). Là **refactor code sản phẩm** → defer cho owner duyệt (§3b). Ưu tiên tag này hơn `harness` khi có đường tách seam.
  - **`harness`** — **kể cả sau khi tách seam hợp lý vẫn buộc dựng/mở rộng hạ tầng test chung MỚI**: DB in-memory (query/FK/unique-index), full-HTTP factory (HTTP/middleware), Proxy-mock cả graph tRPC/provider mà component không tách khỏi được. Đi kèm escalate kiến trúc (§3). ⚠ "render/tương tác" **không** tự động = harness.
  - **`need-clarify`** — chưa viết nổi assert vì spec mâu thuẫn với chính nó, với `tech.md` hoặc UI, hoặc thiếu thông tin → cần người quyết trước. Định nghĩa: [`05-concepts.md §7`](../05-concepts.md). Spec lệch với code không phải `need-clarify` mà là finding `spec-drift`.
  - **`no-seam`** — không có nhánh nào để test ở tầng này (field non-nullable không có case "để trống") → đóng. **KHÔNG** tạo BLK → lý do ghi thẳng `Note`.
  - Cây phân loại: *"viết được assert ngay không?"* — **không** (mơ hồ) → `need-clarify`; **không có nhánh** → `no-seam`. *"được — test bằng infra sẵn có ngay không?"* — **không, nhưng tách một seam là được** → `refactor`; **không, kể cả sau tách vẫn buộc dựng infra chung mới** → `harness`.
- **§5 Next Actions** — `ID` · `Việc` · `Nguồn` · `Loại` · `PIC`. **Ca (b) — đo được 2026-09-10, và nó là bẫy:** `AC-F004-006` (chip nhãn hai màu) có 3 TC, cả 3 `Autoable = NO` ⇒ không TC nào xuống `test-exec-functional.md` ⇒ `Coverage` của scope đó **không bao giờ** đạt `6/6` và sinh một dòng `coverage-gap` ở **mọi** lượt. Đọc theo remedy (a) là mint TC trùng cho một AC đã đủ TC, và bump `versions.{scope}` sẽ làm version-gate chặn **chính tầng đó** ở lượt sau. Nên `Việc` phải viết theo sự thật (*"kiểm bằng mắt N TC của {req-ID}"*), và §1 `Coverage` phải có một dòng nói rõ trụ đó không đếm được vào `Covered`. Đây là cùng hình dạng bệnh mà `.docs/031` `D15` đã chữa cho `Tổng TC` — mẫu số của `Coverage` vẫn là Traceability Matrix của test-design, **có chủ ý**: bỏ trụ đó ra khỏi `Tổng` là làm nó biến mất khỏi mọi bản ghi.

**Ba nguồn:** §2 `FIND-*` (còn 🔴; `dup-of` không tính) · §3 `BLK-*` (luôn có) · §1 `Coverage` **thiếu phủ** (`coverage-gap` — không đỏ, không hoãn, vẫn là việc: vd test-design thiếu TC accept sát biên ⇒ lộ ra khi đối chiếu Traceability Matrix). Đây cũng là nơi phần "đáng nâng thành requirement" của TC bị bỏ (§6) đổ về. Câu `Việc` phải **đọc một mình vẫn hiểu** — roll-up trích nguyên văn.
- **Nâng pin (§1b③, 016)** — sau khi cả scope chạy xong: set `test_exec_version` (frontmatter của **file scope này**, **một số**) = `test-exec-{scope}.version`. Đây là bước đóng vòng (pin == version ⇒ scope current).

---

## 7b. Dựng lại roll-up

`test-report.md` là **roll-up**: mọi số derive từ các `test-report-{scope}.md` cùng thư mục, **không giữ dữ kiện riêng nào** ⇒ luôn dựng lại được, không có gì để mất. Skill tầng vừa ghi file scope của mình thì dựng lại nó:

1. **Tính lại §1 Summary + dòng `**Mục:**` của file scope vừa ghi** từ §4 Results (chỉ counts — không vỡ theo tier; derive, không sửa tay). Rồi **glob `test-report-*.md`** — **trừ `test-report.md`** — và đọc của từng file: frontmatter (pin, date) + §1 (counts + Coverage) + §5 Next Actions + §2 Findings (đếm 🔴 mở, **trừ** dòng `dup-of`).
2. **Dựng lại `test-report.md` trọn** từ dữ liệu đó (3 bảng: `Trạng thái theo scope` · `Coverage` · `Action Items` phẳng, **đúng bộ cột của §5 file scope**, gộp mọi scope, sắp `🤖` trước `👤`, **không** cột `Xong`). **KHÔNG** đọc bản roll-up cũ, **KHÔNG** gộp thêm gì.
3. `derived_from.{scope}.test_exec_version` = pin đọc được ở file scope. Pin `0` ⇒ **vẫn có dòng, vẫn link file**, ghi `(chưa chạy)` cạnh pin. Scope **không có TC** ⇒ không file, không dòng. Cột `Tổng TC` đọc từ bảng **`Test Cases`** của `test-exec-{scope}.md` (mẫu số của scope — nơi liệt kê TC scope này thực thi; §4 ở `validation`/`functional`, **§5** ở `e2e`), phần counts còn lại đọc từ §1 của file scope — lệch nhau ⇒ scope đó stale, khớp với `pin < version`. **KHÔNG** lấy `Tổng TC` của `test-design.md`: nó đếm **cả** TC `Autoable = NO` (ca visual) mà scope không thực thi, nên feature có một TC visual là hai số lệch **vĩnh viễn** ⇒ roll-up báo stale mãi mãi (.docs/031 `D15`). Bước này **không phân biệt scope có writer hay không**: `nfr`/`dm` vẫn được đọc và cộng như 3 scope kia (toàn bộ not-run cho tới khi có skill ghi).
4. **Commit sau mỗi tầng** — git là history duy nhất của `.specs/tests/*` (015 §3B).

**Cấm ở roll-up:** đoạn văn · bảng per-TC · evidence mutation · mô tả finding · bảng tổng theo tier. Có một câu chỉ sống ở roll-up là roll-up không dựng lại được.

Không còn chuyện ghi đè mất dữ liệu: tầng sau ghi **file khác**, còn roll-up thì dựng lại được từ các file scope. Vì vậy **không** có luật nào buộc tầng sau giữ lại bảng của tầng trước — thứ trước đây phải canh khi ba skill dùng chung một file.

---

---

## 7c. Lượt outer ở ③ Build — khác gì lượt retrofit

Phần này **chỉ** áp cho `/spec-test-functional` và `/spec-test-validation`. Skill retrofit bỏ qua.

### 7c.1 Ô wiring rỗng nghĩa là "slice chưa tới"

Khung `test-exec-{scope}.md` được `/spec-test-exec` dựng ở **① Design**, đủ row TC nhưng ô `Layer`/`Test File` **rỗng**. Ô rỗng ở đây nghĩa là **slice chưa chạy tới TC này** — KHÔNG phải *"không viết được"*.

*"Đã xét và không viết được"* có nhãn riêng: `⏭` kèm một trong `refactor` · `harness` · `need-clarify` · `no-seam` (§2). Lẫn hai cái là report đẻ blocker giả cho những TC mà đơn giản là chưa tới lượt.

`version` của `test-exec-{scope}.md` **không bump** khi skill outer điền `Layer` + `Test File`. Bump chỉ dành cho `/spec-test-exec` khi nó áp delta wiring vì `test-design.md` đổi. Bump mỗi slice thì pin-gate ở ④ Verify thấy stale liên tục và chạy lại vô nghĩa.

### 7c.2 `sanity-red: red-first`

Giá trị thứ năm của cột `sanity-red`, cạnh `proven-red` · `inherited` · `n/a` · `—`. Nghĩa: **đã thấy test này đỏ trước khi có dòng code nào làm nó xanh**.

- Lượt outer **không** mutate-revert (§4 của `retrofit-core` không áp) ⇒ cột `mutation` và `reverted` để `—`.
- `red-first` và `inherited` **không** cùng lúc trên một row.
- **Ở ④ Verify, skill retrofit gặp row `red-first`: GIỮ NGUYÊN `red-first`** (034 `D16`) — không viết trùng, không mutate lại, **không** hạ xuống `inherited`. `inherited` nghĩa *"mượn bằng chứng của lượt trước"*, mà bằng chứng lượt trước chính là `red-first`; ghi `inherited` là xoá mất chính cái vừa mượn. Lượt đó có mutate-và-thấy-đỏ thật thì ghi `proven-red` (bằng chứng lượt này thắng).
- `inherited` dành cho test **đã tồn tại trước khi pipeline này chạm vào** — ca brownfield, `test-core` §1b — không phải test do ③ Build viết ra.

**Slice sau chỉ chạy lại một TC đã xanh ⇒ `sanity-red` KHÔNG đổi.** Chỉ cột `Result` được refresh, cộng `date` ở **frontmatter** — §4 `Results` không có cột `date` nào. `sanity-red` trả lời *"lấy gì làm bằng chứng test này biết đỏ"* — bằng chứng lập một lần rồi đúng mãi, không lập lại mỗi lượt chạy. Không có giá trị thứ sáu cho ca này, và cũng **không** được ghi `—` (`—` dành cho TC không chạy).

### 7c.3 Ba cột sanity-red tách đôi theo `mode`

Luật cũ cho ba cột đi liền nhau: bắt buộc khi `mode: retrofit`, để `—` khi `mode: cycle`. Nay tách:

| Cột | `mode: retrofit` | `mode: cycle` |
|---|---|---|
| `sanity-red` | `proven-red` · `inherited` · `n/a` · `—` · **`red-first`** (giữ từ ③ Build) | **`red-first`** (hoặc `—` nếu TC không chạy) |
| `mutation` · `reverted` | bắt buộc | `—` |

`sanity-red` có nghĩa ở **mọi** `mode`; `mutation`/`reverted` chỉ có nghĩa khi thật sự có mutate-revert.

### 7c.4 `mode` theo skill nào ghi lượt gần nhất

`mode` trong frontmatter `test-report-{scope}.md` mô tả **kiểu cập nhật gần nhất**: skill outer ⇒ `cycle`, skill retrofit ⇒ `retrofit`.

Lượt **scaffold** của `/spec-test-exec` **không** tính là một lượt ghi — nó vẫn đặt `cycle` như hôm nay, và giá trị đó chỉ mang nghĩa khi §4 `Results` có row đầu tiên.

Khi `mode: cycle`: §1 Summary đếm theo cột **`Result`**, không theo `sanity-red`. Row `red-first` mà `Result: —` (lượt `write` đã ghi, `record` chưa chạy — §7c.7) đếm vào ô `—`, **không** vào 🟢; nó chỉ sang 🟢 khi `record` cập nhật cột `Result`. Scope chưa chạy trọn thì ghi rõ `n/N TC` thay vì để người đọc tưởng đã đủ.

### 7c.5 Pin không nâng ở ③ Build

Lượt outer **chỉ** ghi row vào §4 `Results`. `test_exec_version` (pin) **không đổi** — nó vẫn do ④ Verify nâng khi chạy trọn scope. `current` phải giữ đúng một nghĩa *"đã chạy trọn scope"*; cho ③ Build nâng pin là đẻ trạng thái thứ ba mà mọi gate của 016 phải học lại.

### 7c.6 Một file report, một writer **mỗi lượt**

`test-report-functional.md` và `test-report-validation.md` giờ mỗi file có **hai** writer theo hai lượt khác nhau: skill outer ở ③ Build, skill retrofit ở ④ Verify. Luật giữ nguyên tinh thần cũ:

- **Không** hai writer cùng lúc.
- **Không ai rewrite cả bảng** — merge theo key `TC ID`, y như kỷ luật đã có ở `selector-contract.md` (*"merge theo key `testid`, KHÔNG rewrite cả file"*).
- Writer chỉ chạm row của **story mình đang làm**; row của story khác giữ nguyên byte.
- Vẫn **không** đọc/ghi file scope khác (§7).

### 7c.7 Bằng chứng ghi ngay lúc thấy đỏ, không chờ cuối slice

`--phase=write` **được** ghi vào `test-report-{scope}.md`, đúng hai thứ: **row của TC** và ô **`sanity-red: red-first`**. `Result` để `—`, `mutation`/`reverted` để `—`. `--phase=record` sau đó cập nhật cột `Result` `—` → `🟢` trên chính row ấy (§4 `Results` không có cột `date`; `date` là field frontmatter).

**Vì sao không chờ tới `record`.** Bằng chứng phát sinh ở lượt `write` (thấy đỏ khi chưa có code) nhưng trước đây chỉ xuống đĩa ở lượt `record`, tức cuối slice. Slice dừng giữa chừng — hết ngân sách, `need-clarify`, người ngắt — thì `record` không chạy, và cái đã thật sự xảy ra không để lại dấu nào. Sang ④ Verify, retrofit gặp một test xanh không row, phải mutate-revert kiếm lại rồi ghi `proven-red`: tốn công, mà lại **ghi yếu hơn sự thật** (`proven-red` chứng minh đỏ ở chỗ *ta chọn phá*; `red-first` chứng minh đỏ khi *chưa có gì cả*).

**Vì sao `Result: —` chứ không `🔴`.** Trong file này `🔴` nghĩa là **defect** — nó kéo theo một row ở §5 `Findings` và được `/verify-v1` đếm vào dòng `🔴 mở`. Đỏ giữa slice là **nhịp đúng của hệ**, không phải defect. `—` là trạng thái khởi tạo mà `/spec-test-exec` vốn đã dùng (*"`Results` giữ `—` (not-run)"*), và §1 Summary đã có ô cho nó — ghi vậy không thổi phồng con số nào.

**Row là trí nhớ của slice.** Gặp row đã mang `red-first` mà test xanh ngay ở lượt `write` ⇒ slice này đang **chạy lại sau khi bị ngắt**, không phải sai tiền đề. Luật *"xanh ngay ⇒ dừng, báo người"* chỉ áp khi row **chưa tồn tại** — đúng ca nó sinh ra để bắt (test không assert gì, hoặc code có sẵn từ trước mà ta tưởng chưa).

**Điền trước một ô rồi writer khác điền nốt là kỷ luật sẵn có**, không phải ngoại lệ đẻ riêng cho ca này: `selector-contract.md` để cột `TC` rỗng cho phía đọc điền; `test-exec-{scope}.md` để `Layer`/`Test File` rỗng cho slice điền; và §7c.2 vốn đã cho lượt sau refresh `Result` mà giữ nguyên `sanity-red`.

---

## 9. Red flags của đường test-trước-code

Chỉ áp cho họ skill **outer**. Bẫy của đường code-trước-test ở [`retrofit-core.md`](retrofit-core.md) §8 — **không** đọc chéo: quá nửa mục ở đó nói về mutate-revert, `--mode`, version-gate và pin, những thứ lượt outer không có.

- Đọc code sản phẩm để biết *giá trị đúng* → vỡ luật 1. Ở ③ Build code còn **chưa tồn tại**; seam lấy từ `tech.md`, oracle lấy từ `test-design.md`.
- Viết test rồi **không chạy** để xem nó đỏ → mất luôn bằng chứng duy nhất của lượt outer. `red-first` chỉ được ghi khi đã thật sự thấy đỏ.
- Đỏ vì **harness thiếu / seam gõ nhầm / thiếu dev dependency** mà ghi `red-first` → đó là test-error, sửa test. `red-first` nghĩa là đỏ vì *chưa có code*, không phải đỏ vì bất cứ lý do gì.

  **Ngoại lệ quan trọng: `module not found` của chính module slice này sắp viết LÀ nhịp RED hợp lệ.** Ở ③ Build file sản phẩm chưa tồn tại, nên test import nó **phải** nổ — đó đúng là *chưa có code*. Phân biệt bằng **đường dẫn**: module thiếu nằm trong tập file mà `tech.md` khai slice này sẽ tạo ⇒ RED hợp lệ; nằm ngoài (gõ nhầm tên, quên cài `@testing-library/...`) ⇒ test-error. Không có phép phân biệt này thì mọi outer test đầu tiên của mọi slice đều bị xếp nhầm là test-error.
- Sửa `test-design.md` cho khớp test vừa viết → vỡ luật 2. Test-design là nguồn, test là dẫn xuất.
- Gom TC của **cả feature** rồi mới viết code → test-first waterfall. Lượt outer nhận **một story**; TC của `VR` viết ngay trước đoạn code làm nó xanh, không batch lên đầu.
- Chạm row của story khác trong `test-report-{scope}.md` → vỡ §7c.6. Lượt outer merge theo `TC ID`, chỉ row của story mình.
- Nâng `test_exec_version` sau khi ghi row → vỡ §7c.5; pin là việc của ④ Verify.
- Ghi `⏭` cho TC mà slice **chưa chạy tới** → vỡ §7c.1; ô rỗng mới là *chưa tới*, `⏭` là *đã xét và không viết được*.
- Tự đặt tên `data-testid` khác chuỗi đã khai ở `selector-contract.md` → component phải gắn **đúng** chuỗi outer test đã đặt, không phải chuỗi nào cũng được.
- Coi test đỏ giữa slice là **finding** → ở ③ Build đỏ là trạng thái mong đợi của nhịp RED. Code đã làm **đúng câu chữ AC** mà test vẫn đỏ ⇒ AC tự mâu thuẫn ⇒ dừng slice với `need-clarify` ([`05-concepts.md §7`](../05-concepts.md)) — vẫn không phải finding, và không phải `spec-drift` (spec không lệch với code).
