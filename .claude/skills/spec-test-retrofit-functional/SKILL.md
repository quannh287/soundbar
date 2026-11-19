---
name: spec-test-retrofit-functional
description: Retrofit acceptance test tầng FUNCTIONAL (Story AC) cho MỘT feature đã có code nhưng thiếu test — viết functional test SAU code, giá trị đúng derive từ AC (không đọc code), neo chặt AC-F*, phân tầng seam theo chân be:*/fe:* (core §2a) theo chỗ assertion rơi vào, backfill selector-contract + gắn testid (data-testid/testID/Semantics tuỳ platform, references/testid-conventions.md) cho fe:component test, sanity-red chứng minh test biết đỏ, phân loại đỏ thành finding (bug-code/spec-drift), dựng lại test-report-functional.md rồi sinh lại roll-up. Tầng thứ hai (AC). Import references/test-core.md + references/retrofit-core.md.
---

# spec-test-retrofit-functional

## Overview

Retrofit **Functional Test Cases** (neo `AC-F*`) cho một feature đã implement nhưng chưa có test. Đây là **tầng thứ hai** trong bộ 3 skill retrofit (`validation` → `functional` → `e2e`). Phức tạp hơn validation: phải **phân tầng seam** (chân BE `be:*` vs chân FE `fe:*`, core §2a) theo *chỗ assertion rơi vào*, và với `fe:component` test phải **backfill selector-contract + gắn testid** (`data-testid`/`testID`/`Semantics(identifier:)` tuỳ platform — `references/testid-conventions.md`) vào code cũ trước khi viết test.

**Cỗ máy lõi ở hai file, đọc cả hai trước:**

| File | Giữ gì |
|---|---|
| [`references/test-core.md`](../../references/test-core.md) | phần dùng chung với họ skill outer — 4 luật bất di (§0) · điền test-exec (§2) · tier vocabulary (§2a) · reconcile + anchor 2 chiều (§2b) · seam theo tầng (§3) · prune (§6) · **ghi `test-report-{scope}.md` (§7) + dựng lại roll-up (§7b)** |
| [`references/retrofit-core.md`](../../references/retrofit-core.md) | phần chỉ đúng cho đường **code trước, test sau** — vòng lặp lõi quét A/B (§1) · version-gate + pin-gate (§1b) · refresh mode (§1c) · **guided sanity-red mutate-revert (§4)** · phân loại đỏ thành finding (§5) · red flags (§8) |

Skill này chỉ định nghĩa lớp đặc thù AC: *phân tầng seam + sub-flow instrument testid + viết Given-When-Then*.

**Vai trò trong bức tranh retrofit** (`.docs/013` §2):
```
references/test-core.md      ← luật dùng chung (cả outer lẫn retrofit)
references/retrofit-core.md  ← thêm phần code-trước-test (3 tầng retrofit dùng)
        ▲
  spec-test-retrofit-functional   ← skill này: core + seam theo tầng + testid + GWT
```

Chạy **sau** `/spec-test-retrofit-validation` (VR) và **trước** `/spec-test-retrofit-e2e` (FAC). Ba tầng ghi **ba file khác nhau** (`test-report-{validation,functional,e2e}.md`) rồi cùng dựng lại roll-up `test-report.md` (core §7b) — không tầng nào phải giữ hộ kết quả tầng nào.

## When to Use

- Feature đã có code + `test-design.md` (có Functional Test Cases neo AC), nhưng **chưa có / thiếu / chỉ có test cũ không neo AC** → retrofit để có regression net neo chặt AC + verify code đúng AC. Test cũ chưa neo AC **không** bị bỏ qua — reconcile qua core §2b.

## When NOT to Use

- Feature **chưa có** `test-design.md` → chạy `/spec-test-design` trước.
- Muốn test **rule validation** (VR, 1 pos + ≥1 neg) → `/spec-test-retrofit-validation`. Muốn test **FAC** (e2e cross-story journey) → `/spec-test-retrofit-e2e`.
- AC khẳng định một **journey xuyên màn hình / cross-story** → KHÔNG xử ở đây, đẩy sang FAC/`/spec-test-retrofit-e2e` (core §3, 013 §3).
- Viết test **trước** code (double-loop, test-first) → luồng khác (ngoài scope retrofit).
- Feature không có `AC-F*` automatable nào ở test-design → không có gì để retrofit ở tầng này.

---

## Tham số

- **No-arg (default)** — đường tự động: gated version/pin + phân loại NEW/MODIFIED/UNCHANGED + nâng pin (core §1b). Đây là đường **hấp thụ TC mới/đổi** (version-transition).
- **`--mode execute|sanity|full`** — refresh report **chủ động, all-TC-in-scope, pin-neutral** (core §1c). `execute` = chạy lại test (cột `Result`); `sanity` = mutate lại seam đã ghi → chứng minh test bám code (cột `sanity-red`/`mutation`/`reverted` + verify `Tier`); `full` = re-wire + re-prove + re-run (mọi cột; nguồn-ghi duy nhất của `Tier`). **Chỉ chạy khi scope current (`pin == version`)** — stale thì từ chối, báo chạy default trước. Ràng buộc đầy đủ: **core §1c**.

---

## Process

> **Bước 1-2, 6-7 thuộc `references/test-core.md` + `references/retrofit-core.md`** (cỗ máy lõi) — đọc file đó. Bước 3-5 dưới đây là **đặc thù AC**.
>
> **Hai quét (core §1).** Bước 3 + 3b + 3c là **quét A**: đọc code một lượt cho **hết** AC TC automatable của scope, điền wiring + backfill contract/testid, TC nào không viết được thì phân loại + ghi row `⏭` **ngay** (+ `BLK-FUN-*` ở §3, trừ `no-seam`), rồi ghi `test-exec-functional.md` **một lần**. Bước 4 + 5 là **quét B**: theo từng cụm bám cùng handler/component — viết/neo test cả cụm → chạy → mutate một lần → cụm đỏ → revert → verify-green → ghi row §4 của cả cụm. Quét A **không** mutate gì.
>
> **Thứ tự bên trong quét A:** dòng handle của Bước 3b phải xong **trước** TC tier `fe:component` tương ứng, nhưng **không** trước TC `be:*` — TC ở chân BE chạy được khi contract chưa chạm.

### Bước 1: Xác định feature + dựng/merge bộ test-exec (core)

- Xác định feature có `test-design.md` (cảnh báo nếu `draft`, **không** block).
- Dựng/dùng bộ test-exec qua `/spec-test-exec` → có `test-exec-functional.md` (khung, ô wiring trống) + `test-report-functional.md` (khung + legend, `Results` rỗng, pin `0`) + roll-up trong `.specs/tests/{F-XXX}-{slug}/`. Đặt `mode: retrofit` ở file scope của mình.
- **Ghi đúng một file report: `test-report-functional.md`** (writer duy nhất của nó). Tầng validation chạy trước nằm ở **file khác** ⇒ không có gì phải giữ hộ, và **KHÔNG** đọc/ghi `test-report-{validation,e2e,nfr,dm}.md`. Kế thừa ô đắt (`sanity-red`/`mutation`/`reverted`/`Tier`) chỉ lấy từ **bản trước của chính file này** (core §7).
- **Ghi thêm sổ `spec-debt.md` của feature, cạnh `frd.md`** (`.specs/main/feature/{F-XXX}-{slug}/`, [`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)) — chỉ theo core §5: thêm **một** dòng `**phát hiện:**` vào mục `SD` đã có cho ID đó nếu mục chưa có dòng của tầng này (mọi mode), hoặc mở `SD` mới cho drift chưa có mục (chỉ default/`full`). Commit cùng `test-report-functional.md`. Gặp sổ kiểu cũ (`.specs/integrations/*/` · `.specs/tests/*/`) ⇒ **dừng trước khi chạy test**, in `npx spec-lite migrate-spec-debt`. Phép đối chiếu ngược chỉ xét `SD` neo `AC-*` (trụ của tầng này) → dòng `A-FUN-n` ở §5.
- **GATE version + pin (core §1b, 016) — cấp-scope `functional`:** version-gate `test-design.versions.functional` > `test-exec-functional.test_design_version` → **STOP** báo chạy `/spec-test-exec` trước (D9). pin-gate `test-report-functional.test_exec_version` (**một số**) == `test-exec-functional.version` → scope current, dừng; tụt → re-run cả scope. Phân loại NEW/MODIFIED/UNCHANGED (NEW/MODIFIED full-loop; UNCHANGED chỉ re-execute, inherit sanity-red/Finding; MODIFIED-Finding → re-evaluate verdict).
- **Nếu chạy với `--mode` (core §1c):** bỏ qua nhánh phân loại NEW/MODIFIED/UNCHANGED — áp mode cho **hết TC** của scope theo cột mà mode sở hữu, **pin-neutral**. Chỉ hợp lệ khi `pin == version`; stale → STOP báo chạy no-arg (default) trước. Version-gate vẫn enforce như trên.

### Bước 2: Lọc Functional TC (core)

- Nguồn: `test-design.md > ## Functional Test Cases`. Mỗi TC neo đúng 1 `AC-F*`. Chỉ lấy TC **automatable** (`Autoable=YES/MAYBE`); TC visual (`Autoable=NO`, oracle màu/layout/icon) ở lại test-design, kiểm ad-hoc — **không** render.
- Không có Functional TC automatable → dừng, báo "feature không có AC automatable để retrofit ở tầng này".

### Bước 3: Phân tầng seam + điền test-exec *(đặc thù AC)*

Với mỗi AC TC — chọn seam **theo chỗ assertion rơi vào, KHÔNG theo chỗ user bấm** (core §3, 013 §3). Tier dùng **bộ vocabulary 2-chân ở core §2a** (prefix stack `be:`/`fe:`), ưu tiên bậc rẻ nhất:

| AC khẳng định về… | Tier (core §2a) | testid? |
|---|---|---|
| computed thuần / entity invariant / projection tính bằng hàm thuần | `be:unit` (hoặc `fe:unit` nếu tính client-side) | không |
| data / state / side-effect do **logic C# tự enforce** (record tạo, status đổi, notification, audit, maker-checker, computed-C#) — test bằng **fake repo + UoW** | `be:handler` | không |
| rule **chỉ DB enforce được** (FK/membership, unique index, org-scope global filter/interceptor, phép suy diễn trong EF query) | `be:persistence` | không |
| rule nằm ở **chính tầng HTTP** (auth/permission gate 401/403, model-binding, routing) | `be:api` | không |
| render một giá trị/projection ra **DOM** (cột, empty-state, layout, message, ẩn/hiện theo permission) | `fe:component` | **có** |
| FE **gọi API + xử lý response** (loading/error/mapping) với backend mock | `fe:api` | tùy |
| tính toán / format **client-side thuần** | `fe:unit` | không |
| chuỗi tương tác **xuyên màn hình / cross-story**, hoặc AC **buộc browser thật** (focus/keyboard/paint/navigation thật) | `e2e` — **KHÔNG ở đây** → đẩy sang FAC/`/spec-test-retrofit-e2e` | — |

- Chọn tier **rẻ nhất** khả thi theo core §2a (BE: `be:unit`→`be:handler`→`be:persistence`→`be:api`; FE: `fe:unit`→`fe:component`→`fe:api`). **TUYỆT ĐỐI KHÔNG mặc định "server-side ⇒ `be:api`":** data/state của AC phần lớn enforce ở `be:handler` và test được bằng fake repo — không cần full-HTTP. Điền vào `test-exec-functional.md`: `layer(=tier) · Test File (nơi test) · Given-When-Then · testid · priority`.
- **Không tồn tại tier `narrow-UI` / `fe:e2e`.** Chân FE cap ở `fe:component` (+ `fe:api`). Khoảnh khắc AC buộc browser thật là đã ở **cost của `e2e`** (đỉnh chung, không prefix — core §2a) → đẩy sang tầng e2e; "single-screen" chỉ là **scope**, không phải bậc mới. Functional bình thường **không** sinh row `e2e`.
- ⚠ **Seam xác định từ CODE, KHÔNG từ cột layer của test-design** (core §3, luật 1) — test-design gợi ý "api" có thể sai (vd rule thật enforce ở `be:handler`); theo code chọn bậc thấp nhất khả thi, lệch thì ghi Note ở test-exec (đọc-xuống, không sửa test-design).
- ⚠ **Seam cần harness project CHƯA có** (vd full-HTTP integration khi repo chỉ có test layer-isolated) → **KHÔNG tự dựng harness trong skill** (core §3). Ở quét A: TC đó nhận `Action = harness` + một `BLK-{SCOPE}-N`, **vẫn chạy tiếp** các TC test được ở harness đã có. **Cả scope** thiếu harness ⇒ **dừng có biên bản** (core §3): ghi trọn §4 với `⏭ harness`, `BLK`, dòng §5 `👤 DEV`, nâng pin, dựng lại roll-up, rồi mới escalate — không dừng im để lại `pin 0` + §4 rỗng.
- ⚠ **Phân biệt harness vs refactor (core §3b).** AC hay có hành vi **chôn** trong component lớn / thân resolver. Ranh giới = **"tách seam ra rồi test bằng infra sẵn có được không?"** — KHÔNG phải "logic vs render". Hai đường refactor: (a) **extract pure fn** (clamp/format/derive/predicate) → `fe:unit`/`be:unit`; (b) **hành vi render/tương tác chôn inline trong page lớn** → tách thành **component props-driven** → render độc lập bằng render-harness đã có (`fe:component`, không mock cả graph tRPC/router) → vẫn là `refactor`. Chỉ tag `harness` khi **kể cả sau khi tách vẫn buộc dựng infra chung mới** (DB in-memory / full-HTTP / Proxy-mock graph tRPC không tách khỏi được). Backfill `data-testid` là thao tác nhẹ skill tự làm; **extract logic/tách component khỏi page** là refactor → defer `refactor`. ⚠ Bẫy: "là render" hoặc "page 3800 dòng phải Proxy-mock" → chớ vội gán harness; hỏi "tách component ra là hết cần Proxy chưa?".
- **"Cái gì đúng" (kết quả mong đợi) lấy từ AC text** (test-design), KHÔNG từ code (core luật 1). Cụm "display AC" thường **tách đôi**: giá trị tính ra = seam BE (`be:handler`/`be:unit`); việc render giá trị đó ra DOM = `fe:component`.

### Bước 3b: Sub-flow instrument testid *(đặc thù AC — chỉ khi có TC tier `fe:component`)*

`fe:component` test cần testid/identifier ổn định để query — cú pháp gắn/query khác theo platform (`data-testid` web-react · `testID` react-native · `Key`+`Semantics(identifier:)` flutter, xem `references/testid-conventions.md` §2). Retrofit code cũ thường **thiếu / gắn không nhất quán** → phải backfill contract + gắn testid **TRƯỚC** khi viết test. An toàn: **additive-only, non-behavioral** (§4 của reference đó).

```
a. Danh sách CẦU: từ các Functional TC automatable tầng này đang phủ, đọc Steps + Expected →
     element nào test chạm (action/assert/nav). Ở brownfield, CẦU là căn cứ biết GẮN TESTID VÀO ĐÂU
     (code đã tồn tại, không có lượt /build nào để áp luật hai khoản của .docs/026 D3). KHÔNG phải
     frd User Flows (flow mô tả hành trình, không mô tả màn hình), KHÔNG phải harvest testid rời rạc
     từ code (harvest = đóng băng đúng cái thiếu). Xem .docs/024 + .docs/026.
b. Contract: feature CHƯA có .specs/tests/{F}/selector-contract.md?
     → tạo từ .claude/templates/tests/selector-contract-template.md, ghi row cho các element ở (a).
     → ĐÃ có (từ /build hoặc tầng trước) → so `template_version` artifact vs template:
        · KHỚP → merge luôn, không nâng cấp.
        · LỆCH → kiểm SHAPE thật (header bảng) TRƯỚC khi đổi gì (D18):
            - shape đã khớp template ⇒ CHỈ stamp version. KHÔNG đụng dòng nào trong bảng, KHÔNG
              derive lại cột nào, KHÔNG sửa Notes (ca file sửa tay mà chưa ai stamp version).
            - shape cũ ⇒ nâng cấp: đổi header + stamp version, GIỮ mọi giá trị `TC` đang có;
              ô `— (legacy)` / `—` đổi thành RỖNG (v3: rỗng là hợp lệ). KHÔNG derive lại cột
              TC hàng loạt (không tất định — derive lại tạo diff không kiểm được; kit D18).
          Suy "version lệch ⇒ shape cũ" rồi đổi cả bảng là ăn dữ liệu — không hoàn tác được.
     → REGISTRY: platform=flutter, hoặc react-native khi e2e của project là Maestro → registry
        GLOBAL (đọc + ghi file global TRƯỚC, vd .maestro/selector-contract.md; file per-feature chỉ
        reference, đồng bộ trong cùng commit — references/testid-conventions.md §2b/§3; Maestro không
        phân biệt RN/Flutter). web-react → registry per-feature (file này tự trị).
     → rồi MERGE theo key `testid`: chỉ thêm/sửa row của element tầng này chạm. KHÔNG rewrite cả file.
   Cột `TC`: thêm TC ID của TC tầng này đang xử vào row — không xoá TC lượt trước đã điền.
   Element dùng chung feature khác → giữ nguyên tên gốc.
c. Gắn testid vào component cũ cho KHỚP contract theo cú pháp platform — `data-testid` (web-react) /
     `testID` (react-native) / `Semantics(identifier:)` (flutter; giữ `Key` cũ nếu có — `Key` và `Semantics`
     phục vụ hai tầng test khác nhau, §2c) — thêm thuộc tính, KHÔNG đổi cấu trúc/hành vi.
     GHI ROW CHO MỌI TESTID GẮN THÊM (.docs/026 D4) — kể cả element chưa TC nào phủ; row đó để
     cột `TC` rỗng. Không còn "báo cáo element chưa TC nào phủ" riêng: nó CHÍNH LÀ row `TC` rỗng.
d. GATE additive: chạy test hành vi cũ (nếu có) → phải vẫn xanh. Đây là thay đổi non-behavioral;
     đỏ = đã lỡ đổi hành vi → revert, xem lại. (Feature chưa có test cũ → skip gate, dựa build/render.)
e. test-exec-functional cột testid: handle LẤY TỪ contract. KHÔNG tự đặt testid mới trong test.
f. KIỂM HAI CHIỀU (.docs/026 D6) trong phạm vi component vừa chạm: mọi row grep được trong code,
     VÀ mọi data-testid trong component đó có row. Thiếu chiều nào ⇒ bổ sung, không bỏ qua.
```

- selector-contract ở `.specs/tests/{F}/` **ngoài** scope `/artifact-audit` + `/artifact-migrate` (015 §3B) — nhưng `template_version` **có act**: nó là detector hình dạng (024 D18). Thêm row thì **không** đụng version; **nâng cấp hình dạng** thì stamp version mới. Change history = git → **commit** contract sau khi backfill.
- platform=flutter, hoặc react-native khi e2e là Maestro: ghi identifier mới vào file **global** trước (nguồn đối chiếu thật của harness), rồi đồng bộ vào file per-feature trong cùng commit (`references/testid-conventions.md` §3).
- Feature thuần data (mọi AC TC ở chân BE `be:*`, không có `fe:component`) → **bỏ qua toàn bộ Bước 3b**.

### Bước 3c: Reconcile với test có sẵn *(core §2b)*

- Quét test component/API hiện có cho AC đó **TRƯỚC khi viết mới**.
- Test cũ assert **đúng AC** → **inherit**: anchor TC ID (Category/tên method/`it("TC-F… — …")`) + trỏ `Test File` vào nó, ghi `sanity-red = inherited` ở Results. KHÔNG viết trùng.
- Test cũ assert **theo code lệch AC** → **finding**, KHÔNG tính đã cover: giữ test cũ nguyên, viết test mới neo AC → để đỏ → classify. **KHÔNG** sửa test cũ cho khớp.
- Test cũ assert **đúng AC nhưng thiếu một nửa** (vd kiểm giá trị hiện ra mà không kiểm nó được lưu) → **inherit rồi siết oracle** (core §2b): neo TC ID + thêm assert còn thiếu vào chính test đó. Siết là kéo test về phía AC, khác hẳn nới cho khớp code.

### Bước 4: Viết test — Given-When-Then, 1 scenario/AC *(đặc thù AC)*

- Shape **Given → When → Then** (điều kiện đầu → hành động → kết quả quan sát), 1 scenario chính/AC. Đây là **shape cứng của tầng functional** — KHÔNG dùng pos/neg (đó là validation).
- Test implement đúng test-exec vừa điền, ở đúng tier (`be:*` / `fe:*`). `fe:component` **bám `getByTestId` từ contract**, không selector CSS/text mong manh.
- Kết quả mong đợi từ AC text (không từ code).

### Bước 5: Sanity-red + chạy + classify *(theo core, sắc thái AC)*

- **Sanity-red (core §4):** với AC, mutation tự nhiên = **mutate handler / projection** sinh ra giá trị AC bảo vệ (cho trả cứng giá trị sai, bỏ nhánh tính) → test tầng này phải flip 🔴 → revert → verify green → ghi sanity-red/mutation/reverted ở Results. `fe:component` test: mutate projection/prop-mapping làm DOM sai → assert fail.
- **Batch theo seam (core §4):** một mutation ở 1 handler/projection thường làm đỏ **cả cụm AC test bám cùng handler/component đó** → 1 chu kỳ mutate-revert chứng minh proven-red cho cả cụm; ghi cột mutation từng dòng TC (cùng thay-đổi cho cả cụm) nhưng share một lần mutate. Chi phí thật = round-trip sửa/revert code, KHÔNG phải tốc độ test.
- Chạy test thật lên code cũ → record result vào **§4 Results của `test-report-functional.md`**.
- Đỏ → classify (core §5): **bug-code** (code không thoả AC) | **spec-drift** (code lệch AC **có dấu vết**, BA quyết — tra/ghi sổ `spec-debt.md` cạnh `frd` theo core §5) | flaky | test-error. Ghi Findings. **KHÔNG sửa test cho xanh.**

### Bước 6: Prune (core)

- Functional TC / hành vi pin mà không neo `AC-F*` nào → bỏ. KHÔNG có section `Pruned` (core §6): phần đáng nâng thành AC thật trong frd là **việc** ⇒ một dòng §5 Next Actions (`Loại` = `coverage-gap`, `PIC` = `👤 QC`); phần "đã bỏ, xong" → commit message.

### Bước 7: Dựng lại report + nâng pin + roll-up + report (core §7 + §7b)

- **Dựng lại trọn `test-report-functional.md`** rồi ghi đè một lần (core §7): 5 section `1 Summary · 2 Findings · 3 Blockers · 4 Results · 5 Next Actions`; ID `FIND-FUN-NN` · `BLK-FUN-N` · `A-FUN-N`, cấp số tiếp. `Covers`/`Summary`/`Coverage`(AC X/Y kèm đỏ)/dòng `**Mục:**` **tính lại**; ô đắt **kế thừa** cho TC `UNCHANGED`.
- **`dup-of` (core §7.3):** finding tầng này cùng nguyên nhân với một `FIND-VAL-*` → ghi ID đó vào cột `dup-of`; roll-up không đếm lại và dòng đó không sinh action riêng.
- §5 Next Actions từ **ba nguồn**: §2 `FIND-FUN-*` còn đỏ · §3 `BLK-FUN-*` · §1 `Coverage` thiếu phủ. `PIC` **derive** từ `Loại` (core §7.4); `👤` là vùng đóng băng.
- **TC không viết được (⏭ deferred)** → điền cột `Action` ở §4 Results + trỏ 1 `BLK-FUN-N` ở `Note` (trừ `no-seam`) (core §7.5): `refactor` (seam chôn trong component/resolver — tách hàm thuần HOẶC component props-driven là test được bằng infra sẵn có, defer cho owner; ưu tiên hơn harness) · `harness` (kể cả sau khi tách seam vẫn buộc dựng infra chung mới — escalate kiến trúc §3) · `need-clarify` (chưa viết nổi assert vì spec mâu thuẫn với chính nó, với `tech.md` hoặc UI, hay thiếu thông tin — nối Action Items; spec lệch với code là finding `spec-drift`, không phải tag này) · `no-seam` (không có nhánh để test ở tier này). KHÔNG để trống trơn.
- **Nâng pin (core §1b③, 016):** set `test_exec_version` = `test-exec-functional.version` ở frontmatter `test-report-functional.md` (file scope khác giữ pin riêng của nó — không đụng). UNCHANGED TC inherit sanity-red/Finding; NEW/MODIFIED có mới (MODIFIED-Finding đã re-evaluate).
- **Dựng lại roll-up `test-report.md`** (core §7b, 4 bước): glob `test-report-*.md` **trừ roll-up** → đọc pin + §1 + §5 + số finding đỏ mở (trừ `dup-of`) của từng file → dựng lại trọn 3 bảng. KHÔNG đọc bản roll-up cũ.
- **Commit** `test-report-functional.md` + `test-report.md` + `selector-contract.md` (nếu backfill) + test code + `test-exec-functional.md` (git = history duy nhất, 015 §3B).
- Report cho user: số AC covered, phân tầng seam (`be:*` / `fe:component`), số đỏ + verdict, action items (tách `🤖` và `👤` theo `PIC`), pin functional đã tiến tới v{N}, roll-up đã sinh lại.

---

## Đơn vị tiến độ

Sổ của skill này: `.specs/tests/{F-XXX}-{slug}/.progress/functional.md` — **writer duy nhất là skill này**; KHÔNG đọc, KHÔNG ghi sổ của skill khác. Dựng lại **trọn** sổ mỗi lượt rồi ghi đè: nội dung derive từ artifact nên một ô sửa tay bị ghi đè ở lượt sau. Hình dạng + frontmatter: `templates/tests/verify-progress-template.md`; định nghĩa thư mục: `02-artifacts.md` §4.7.

**Hai khối:** một dòng / TC (y tầng validation, đổi `VAL` → `FUN`) **+ khối backfill `selector-contract` riêng**. `[x]` nghĩa là *"đã có bản ghi"*, không phải *"xanh"*.

**Việc lớn** — `- [ ] /spec-test-retrofit-functional   pin {p}/{v}   ({k}/{n})` — tick khi `test-report-functional.test_exec_version` == `test-exec-functional.version`. Version-gate lệch ⇒ in `⛔ chạy /spec-test-exec` thay vì `[ ]` (core §1b).

### Khối TC

| Việc nhỏ | Đọc file / field | Xong khi |
|---|---|---|
| `TC-…  {result}` — 1 dòng / TC của `test-exec-functional.md` §4 | `test-report-functional.md` §4: `Result` · `sanity-red` · `mutation` · `reverted` | `Result` ∈ {🟢, 🔴, 🟡} **và** bản ghi **tự nhất quán** |
| *(TC hoãn)* `⏭ {Action} → {BLK}` | cùng row: `Action` · `Note` | `Action` ∈ 4 tag **và** (`Action` ≠ `no-seam` ⇒ `Note` trỏ đúng một `BLK-FUN-N` có mặt ở §3) |
| *(annotation)* `wired` | `test-exec-functional.md` §4 cột **`Test File`** khác placeholder | — |
| *(nhóm hiển thị)* AC | `test-exec-functional.md` §3.1 AC Coverage | mọi TC dưới nó đã xong |

**Bản ghi tự nhất quán** = row §4 tồn tại **và** `sanity-red` ∈ {`proven-red`, `red-first`, `inherited`, `n/a`} **và** (`sanity-red` = `proven-red` ⇒ `mutation` có nội dung **và** `reverted` = `✅`). `Result` = `—` ⇒ **không tick**. `⏭` là **xong**, cả bốn tag, kèm hậu tố `⏭ {Action} → {BLK}` **bắt buộc** — `[x]` trơn đọc thành "xanh".

⚠ **Bit "đã wiring" đọc cột `Test File`, KHÔNG đọc `Layer`** — `Layer` luôn có giá trị từ lượt scaffold.

### Khối backfill `selector-contract`

**Chỉ xuất hiện khi có ≥1 TC tier `fe:component`.** Feature thuần data (mọi TC ở chân `be:*`) → khối này **vắng mặt**, KHÔNG in `0/0` — `0/0` đọc thành "còn nợ".

| Việc nhỏ | Đọc file / field | Xong khi |
|---|---|---|
| `contract shape  v{a}/{b} · header {…}` — 1 dòng | `selector-contract.md` `template_version` vs `templates/tests/selector-contract-template.md` (= 3); **và** dòng header bảng `## Testid Contract` | **cả hai** khớp. Lệch một trong hai ⇒ chưa xong — đúng ca 024 D18 cảnh báo: suy "version lệch ⇒ shape cũ" rồi đổi cả bảng là ăn dữ liệu |
| `testid: {handle}  row{✓✗} code{✓✗}` — 1 dòng / handle | danh sách handle: cột `testid` của row §4 **của `test-exec-functional.md`** có `Layer = fe:component`, tách theo ` · `. **Không** đọc cột `Tier` của report §4: cột đó chỉ có giá trị sau khi tầng này ghi row, nên feature chưa chạy tầng nào cũng ra 0 dòng `fe:component` và khối backfill vắng mặt vì lý do sai. **Bit 1** (`row`): `selector-contract.md` có row key `testid` đó **và** cột `TC` chứa TC đang xử. **Bit 2** (`code`): `grep -rF 'data-testid="{handle}"' {src}` có hit | **cả hai bit** — `row✓ code✓`. Handle động (`todo-row-{id}-xoa`) grep phần tĩnh trước `{` |
| `component: {file}  {…}` — 1 dòng / file component chạm | mọi `data-testid=` trong file đó, đối chiếu cột `testid` của contract | mọi `data-testid` trong file đều có row (chiều `code ⊆ contract`) |

Hai chiều của kiểm hai chiều (026 D6) rơi vào hai loại dòng **cố ý**: `contract ⊆ code` là bit 2 của dòng handle; `code ⊆ contract` là dòng component — chiều duy nhất phải quét theo file.

**Ba trạng thái dở của dòng handle**, và đây là chỗ một lượt bị ngắt tự nhận ra được:

| Annotation | Nghĩa |
|---|---|
| `row✗ code✗` | chưa chạm |
| `row✓ code✗` | row đã merge, testid chưa vào code — vi phạm `contract ⊆ code`, cơ học |
| `row✗ code✓` | testid đã vào code, chưa có row — **tín hiệu yếu**: ở brownfield đây là trạng thái xuất phát bình thường. Chỉ sắc khi giao với `git diff`: dòng `data-testid=` **vừa thêm, chưa commit** ⇒ đứt giữa Bước 3b; đã nằm trong `HEAD` ⇒ nợ cũ |

**Vì sao backfill là khối riêng, không nhét vào dòng TC:** ba lý do đều cứng. Nguồn derive ở **file khác** (§4 `Results` không có cột nào nói về contract/testid) ⇒ nhét vào thì dòng TC tick được khi contract còn dở. Nó là **điều kiện trước** khi viết test `fe:component` (Bước 3b) ⇒ nhét vào là mất thứ tự. Và nó **batched theo component**, không theo TC — gate additive 3b.d và kiểm hai chiều 3b.f chạy một lần cho cả component.

**Sổ nở ra giữa lượt — bình thường.** Khối backfill chỉ enumerate được **sau** wiring: `/spec-test-exec` mù code nên để cột `testid` rỗng, chính tầng này điền. Refresh ở đầu lượt thấy 0 dòng backfill, refresh sau quét A mới thấy đủ.

**Cấm đưa vào sổ** — ngoài danh sách của tầng validation:

- Gate additive 3b.d (*"hành vi cũ vẫn xanh"*) — **không để lại vết trên đĩa**, và ca thất bại nhìn giống "chưa làm" (gate đỏ ⇒ skill revert ⇒ giống chưa gắn testid). Chỗ của nó: `Note`, hoặc một `BLK-FUN-*`.
- `dup-of` — không ai derive được nó (core §8).
- 4 phép kiểm contract chỉ in ra · Prune.
- Ô tick thứ hai cho wiring — dùng annotation `wired` trên chính dòng TC.
- Dòng `step=` — biên bản là của orchestrator.

---

## Ràng buộc (nhắc lại từ core — áp cho AC)

- Đọc-xuống: **KHÔNG** sửa test-design, **KHÔNG** sửa frd (spec-drift → finding + mục `SD` ở sổ cạnh `frd` → BA quyết ở `/spec-new {F-XXX}`).
- Nhìn code chỉ để biết *móc vào đâu* (handler/component/testid nào), **KHÔNG** để lấy *giá trị đúng*.
- Test xanh mà **không** có `sanity-red` proven-red (cột Results) = KHÔNG tính pass.
- Guided mutation phải **revert sạch + verify green** trước khi sang TC kế; verify-green fail → **STOP** (repo bẩn).
- Instrument testid **additive-only, non-behavioral**; gate: hành vi cũ vẫn xanh.
- Result + Findings ghi ở **`test-report-functional.md`**, KHÔNG ghi vào `test-exec-functional.md`, KHÔNG ghi vào file scope khác.
- **Một file một writer (core §7):** chỉ ghi `test-report-functional.md` + roll-up; không mở file scope của tầng khác.
- **Format (core §7.1):** đúng **5** section, **toàn bảng** — 0 đoạn văn trần, ô không vượt trần ký tự, `Vấn đề` hai mệnh đề chứ không phải nhãn cụt. KHÔNG `Pruned`/`Observations`/`Sanity-Red Ledger`/`Change History`/timeline/run-log.
- **Đọc-hiểu (core §7.2):** mọi nhãn dùng trong bảng phải có **legend** ở section định nghĩa nó; ba câu hỏi *sai gì · chưa kiểm được gì · ai làm gì tiếp* trả lời được mà không cần mở code.
- Report **chỉ do skill ghi** — không có lối người sửa tay (030 D22).

## Red Flags

- Chọn seam theo *chỗ user bấm* thay vì *chỗ assertion rơi vào* → đẩy nhầm AC data lên `fe:component`/`e2e`.
- Đưa AC data/computation lên `fe:component` trong khi kiểm được ở `be:handler`/`be:unit` → sai tầng (chậm + giòn).
- Mặc định "server-side ⇒ `be:api`": nhét AC data lên full-HTTP trong khi handler enforce bằng C# (fake repo test được) → sai bậc, đắt vô ích.
- Gộp `be:persistence` vào `be:handler`: AC dựa FK/membership/EF-query cần DB thật mà đi dùng fake repo → test không bao giờ bắt được (xem core §2a ranh giới handler↔persistence).
- Đẻ tier `narrow-UI` / `fe:e2e` cho AC 1-màn: single-screen browser = cost `e2e`, "hẹp" chỉ là scope; JSDOM-testable thì là `fe:component`. Không có bậc thứ tư.
- Journey cross-story xử ở đây thay vì đẩy sang FAC → lẫn scope e2e.
- Harvest testid rời rạc từ code thay vì define contract đầy đủ từ flows → đóng băng đúng cái thiếu.
- Tự đặt testid mới trong test không khớp contract → hai bên (code/test) lệch nhau.
- Bump `template_version` selector-contract khi backfill → sai (test-side non-versioned, 015 §3B).
- Instrument testid làm đổi hành vi (không chỉ thêm thuộc tính) → gate đỏ mà vẫn tiếp.
- Mở/ghi `test-report-{validation,e2e,nfr,dm}.md` → mỗi report một writer (core §7); tầng khác nằm ở file khác.
- Ghi xong file scope mà **không dựng lại roll-up**, hoặc dựng roll-up bằng cách đọc bản cũ rồi gộp thêm → vỡ core §7b.
- Finding trùng nguyên nhân với `FIND-VAL-*` mà không ghi `dup-of` → một bug thành hai finding (core §7.3).
- Gán `PIC` theo cảm tính, hoặc tự nâng `👤` thành `🤖` rồi tự sửa spec/hạ tầng → vỡ core §7.4.
- Dùng pos/neg cho AC → nhầm shape tầng validation.
- Lấy giá trị đúng từ code thay vì AC text → test soi gương code.
- Sửa test cho xanh khi gặp đỏ thay vì phân loại finding.

## Verification

- [ ] Mỗi Functional TC neo đúng 1 `AC-F*`; suite 100% traceable tới AC ID; chỉ TC automatable.
- [ ] Seam chọn theo *chỗ assertion rơi vào* (core §3) + tier từ vocab §2a: data/state → `be:handler` (fake repo) · DB-only → `be:persistence` · HTTP-gate → `be:api` · render → `fe:component`; **không** default server-side⇒`be:api`; journey/browser-thật đẩy sang FAC (`e2e`); không đẻ `narrow-UI`/`fe:e2e`.
- [ ] Feature có `fe:component` test: `selector-contract.md` ở `.specs/tests/{F}/` có row cho mọi element mà TC tầng này chạm, cột `TC` không rỗng, **merge** không overwrite row của `/build`/tầng trước; component bám `getByTestId` từ contract (không tự đặt testid mới); `template_version` **inert** (không bump).
- [ ] Instrument testid additive verify-green (không đổi hành vi cũ).
- [ ] Mỗi AC có test Given-When-Then, có `sanity-red`/`mutation`/`reverted` ở Results (proven-red).
- [ ] Test cũ ở mỗi seam đã reconcile (inherit-anchor / finding), không viết trùng, không nuốt bug (core §2b).
- [ ] Mỗi test (mới/inherited) nhúng TC ID máy-đọc-được (Category/tên), 2 chiều với test-exec.
- [ ] `test-exec-functional.md` điền đủ `layer/file/Given-When-Then/testid` cho mỗi TC; **không** có ô result.
- [ ] Result + Findings **chỉ** ở `test-report-functional.md` (`mode: retrofit`); `git diff --stat` chứng minh `test-report-validation.md` **không đổi dòng nào**.
- [ ] File scope đúng 5 section, toàn bảng, 0 ô vượt trần; §1 `Summary` + số đếm ở dòng `**Mục:**` khớp đếm lại từ §4.
- [ ] Report đạt tiêu chí đọc-hiểu (core §7.2) — mọi nhãn có legend, ba câu hỏi trả lời được.
- [ ] Mọi dòng §5: `Nguồn` trỏ `FIND-FUN-*`/`BLK-FUN-*`/req-ID (không mồ côi), `Loại` thuộc 8 nhãn, `PIC` khớp map core §7.4.
- [ ] Đã **dựng lại roll-up** `test-report.md` từ mọi `test-report-*.md` (trừ chính nó); `derived_from.functional.test_exec_version` = pin vừa nâng.
- [ ] TC không viết được (⏭ deferred) đã điền cột `Action` = `refactor` / `harness` / `need-clarify` / `no-seam` (core §7), không để trống trơn; `harness` vs `refactor` phân đúng (core §3b — có đường extract pure fn ⇒ `refactor`).
- [ ] GATE version+pin đã chạy (core §1b): version lệch → STOP báo `/spec-test-exec`; pin bằng → skip; pin tụt → re-run cả scope functional (NEW/MODIFIED full-loop, UNCHANGED re-execute inherit).
- [ ] Cuối: đã **nâng pin** `test_exec_version` = `test-exec-functional.version` ở `test-report-functional.md` (không đụng file scope khác — core §1b③).
- [ ] Findings phân loại đúng bug-code vs spec-drift; spec-drift có action nối `/spec-new {F-XXX}` và có mục `SD` ở sổ cạnh `frd` (core §5).
- [ ] Mọi mutation đã revert sạch (verify green); repo không còn code bị phá.
- [ ] `test-report-functional.md` + roll-up + selector-contract + test code đã **commit** (git = history, 015 §3B).
- [ ] TC bị bỏ: phần đáng nâng thành AC đã thành một dòng §5 (`coverage-gap`), phần còn lại ghi ở commit message — KHÔNG có section `Pruned`.
- [ ] Hai quét đúng thứ tự (core §1): hết quét A thì **mọi** TC có wiring, mọi TC `⏭` đã có row + `BLK`, contract đã backfill, mà **chưa** chu kỳ mutate nào chạy.
- [ ] Row §4 của một cụm ghi **ngay sau** revert + verify-green của cụm đó (core §7.0), không dồn tới cuối scope.
- [ ] Đã ghi lại `.progress/functional.md` theo section `## Đơn vị tiến độ`: khối TC + khối backfill; feature thuần data (không TC `fe:component`) thì khối backfill **vắng mặt**, KHÔNG in `0/0`.
