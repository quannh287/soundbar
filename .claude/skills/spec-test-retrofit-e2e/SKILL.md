---
name: spec-test-retrofit-e2e
description: Retrofit acceptance test tầng E2E (FAC) cho MỘT feature đã có code nhưng thiếu test — viết e2e test SAU code, giá trị đúng derive từ FAC (không đọc code), neo chặt FAC-F*, dựng journey full-browser cross-story (tier luôn e2e — đỉnh chung core §2a), assert business outcome qua integration boundary (UI→API→DB) bằng [verify-db]/[verify-api], tái dùng selector-contract Phase 3, sanity-red = phá 1 story member để cả journey đỏ, phân loại đỏ thành finding (bug-code/spec-drift), dựng lại test-report-e2e.md rồi sinh lại roll-up. Tầng thứ ba (FAC). Import references/test-core.md + references/retrofit-core.md.
---

# spec-test-retrofit-e2e

## Overview

Retrofit **E2E Test Cases** (neo `FAC-F*`) cho một feature đã implement nhưng chưa có test e2e. Đây là **tầng thứ ba / cuối** trong bộ 3 skill retrofit (`validation` → `functional` → `e2e`). Đặc thù nhất: không drive từng test theo story mà dựng **journey full-browser cross-story** như cổng verification cuối — 1 journey có thể phủ nhiều story — và assert **business outcome qua integration boundary** (UI→API→DB), không chỉ UI state.

**Cỗ máy lõi ở hai file, đọc cả hai trước:**

| File | Giữ gì |
|---|---|
| [`references/test-core.md`](../../references/test-core.md) | phần dùng chung với họ skill outer — 4 luật bất di (§0) · điền test-exec (§2) · tier vocabulary (§2a) · reconcile + anchor 2 chiều (§2b) · seam theo tầng (§3) · prune (§6) · **ghi `test-report-{scope}.md` (§7) + dựng lại roll-up (§7b)** |
| [`references/retrofit-core.md`](../../references/retrofit-core.md) | phần chỉ đúng cho đường **code trước, test sau** — vòng lặp lõi quét A/B (§1) · version-gate + pin-gate (§1b) · refresh mode (§1c) · **guided sanity-red mutate-revert (§4)** · phân loại đỏ thành finding (§5) · red flags (§8) |

Skill này chỉ định nghĩa lớp đặc thù FAC: *dựng journey cross-story + assert integration boundary + tái dùng selector-contract*.

**Vai trò trong bức tranh retrofit** (`.docs/013` §2):
```
references/test-core.md      ← luật dùng chung (cả outer lẫn retrofit)
references/retrofit-core.md  ← thêm phần code-trước-test (3 tầng retrofit dùng)
        ▲
  spec-test-retrofit-e2e   ← skill này: core + journey cross-story + verify-db
```

Chạy **sau** `/spec-test-retrofit-validation` (VR) và `/spec-test-retrofit-functional` (AC) — là cổng verification cuối, chạy khi các story thành viên đã có test AC. Ba tầng ghi **ba file khác nhau** (`test-report-{validation,functional,e2e}.md`) rồi cùng dựng lại roll-up `test-report.md` (core §7b) — không tầng nào phải giữ hộ kết quả tầng nào.

## When to Use

- Feature đã có code + `test-design.md` (có E2E Test Cases neo FAC), story thành viên đã retrofit AC, nhưng **chưa có / thiếu test e2e** → retrofit để có regression net cross-story neo chặt FAC + verify business outcome qua integration boundary. Test e2e cũ chưa neo FAC **không** bị bỏ qua — reconcile qua core §2b.

## When NOT to Use

- Feature **chưa có** `test-design.md` → chạy `/spec-test-design` trước.
- Muốn test **rule validation** (VR) → `/spec-test-retrofit-validation`. Muốn test **Story AC đơn** (data/state/render 1 story) → `/spec-test-retrofit-functional`.
- Project **chưa có e2e harness hợp lệ cho platform của feature** — web: Playwright + POM + seeded backend; mobile: **Maestro** (flow YAML, black-box qua Semantics/accessibility tree) + selector-contract global + build thật trên thiết bị/emulator; **KHÔNG** thay Maestro bằng `integration_test`/`flutter_test`/widget test dù chạy được trên thiết bị thật (white-box, cùng process với app — xem Red Flags) → **KHÔNG** tự dựng harness ở đây. E2E là tầng dễ thiếu harness nhất; skill **vẫn chạy** và kết thúc bằng **dừng có biên bản** (Bước 3): §4 đủ row `⏭ harness`, `BLK-E2E-N`, dòng §5 `👤 DEV`, nâng pin, dựng lại roll-up — rồi escalate kiến trúc (core §3). Dừng im để lại `pin 0` + §4 rỗng thì không phân biệt được với "chưa chạy".
- ⚠ **Mobile — hành động không hoàn tác được:** journey thực thi thao tác phá dữ liệu thật không có API khôi phục (vd soft-delete tài khoản, restore chỉ qua Admin thủ công) → **dừng, hỏi user xác nhận trước khi thực sự chạy** harness (vd `tool/e2e.sh`). Đánh dấu flow đó bằng tag loại khỏi default run (vd `dirty-data`) nếu harness hỗ trợ tagging.
- ⚠ **Mobile — round-trip build+install+run cao hơn nhiều Playwright** (không headless, thường chưa vào CI — chạy tay). **Batch theo journey**: gom nhiều TC/scenario cùng một build; chỉ rebuild khi đổi code UI, dùng `--no-build` (hoặc tương đương) khi chỉ sửa flow.
- Feature không có `FAC-F*` automatable nào ở test-design → không có gì để retrofit ở tầng này (FAC thường có ở feature multi-story; feature 1-story thuần có thể không có).
- Viết test **trước** code (double-loop, test-first) → luồng khác (ngoài scope retrofit).

---

## Tham số

- **No-arg (default)** — đường tự động: gated version/pin + phân loại NEW/MODIFIED/UNCHANGED + nâng pin (core §1b). Đây là đường **hấp thụ TC mới/đổi** (version-transition).
- **`--mode execute|sanity|full`** — refresh report **chủ động, all-TC-in-scope, pin-neutral** (core §1c). `execute` = chạy lại journey (cột `Result`); `sanity` = mutate lại **1 story member** journey đã ghi → chứng minh journey bám code (cột `sanity-red`/`mutation`/`reverted`); `full` = re-wire (shape journey/POM) + re-prove + re-run (mọi cột). **Chỉ chạy khi scope current (`pin == version`)** — stale thì từ chối, báo chạy default trước. Ràng buộc đầy đủ: **core §1c**.

---

## Process

> **Bước 1-2, 6-7 thuộc `references/test-core.md` + `references/retrofit-core.md`** (cỗ máy lõi) — đọc file đó. Bước 3-5 dưới đây là **đặc thù FAC**.
>
> **Hai quét (core §1).** Bước 3 + 3b + 3c là **quét A**: đọc code một lượt cho **hết** E2E TC của scope, dựng shape journey + điền `test-exec-e2e.md`, TC nào không viết được thì phân loại + ghi row `⏭` **ngay** (+ `BLK-E2E-*` ở §3, trừ `no-seam`), rồi ghi test-exec **một lần**. Bước 4 + 5 là **quét B**: theo từng journey — viết/neo test → chạy → mutate một story member → journey đỏ → revert → verify-green → ghi row §4. Quét A **không** mutate gì.
>
> ⚠ **Reset seed trước khi re-execute một scope e2e** (core §8): một lượt bị ngắt giữa journey để `afterEach` teardown không chạy, record của lượt dở nằm lại trong seeded DB, và lượt sau đỏ **vì rác** chứ không vì code.

### Bước 1: Xác định feature + dựng/merge bộ test-exec (core)

- **VIỆC ĐẦU TIÊN — kiểm cây làm việc sạch:** `git diff -- {src}/` (vd `lib/`). Bẩn ⇒ **lượt trước chết giữa chu kỳ sanity-red** và mutation còn treo. **Revert trước khi làm bất cứ gì khác**; đừng đọc nó như "code sản phẩm hiện tại".
  - ⚠ **Cái nguy hiểm không phải mutation bị commit — mà là SOURCE LỆCH BINARY.** Revert `lib/` xong nhưng APK/IPA trên thiết bị **vẫn là bản mutate**. Lượt "verify xanh" kế tiếp chạy binary hỏng → đỏ → và người ta đi tìm bug trong code đã sạch. Đã xảy ra thật 2 lần trong một ngày ở F-001 GAL-Mobile, mất một vòng điều tra.
  - Sau mọi revert ⇒ **BẮT BUỘC rebuild + cài lại** trước lượt verify-xanh. Đây là **bước tường minh**, không để ngầm. Suy "source sạch nên binary sạch" là sai ở mọi harness cần build artifact (mobile, desktop, WASM).
- Xác định feature có `test-design.md` (cảnh báo nếu `draft`, **không** block).
- Dựng/dùng bộ test-exec qua `/spec-test-exec` → có `test-exec-e2e.md` (khung: journey/consistency/integrity/guard, POM index — ô wiring trống) + `test-report-e2e.md` (khung + legend, `Results` rỗng, pin `0`) + roll-up trong `.specs/tests/{F-XXX}-{slug}/`. Đặt `mode: retrofit` ở file scope của mình.
- **Ghi đúng một file report: `test-report-e2e.md`** (writer duy nhất của nó). Hai tầng chạy trước nằm ở **file khác** ⇒ không có gì phải giữ hộ, và **KHÔNG** đọc/ghi `test-report-{validation,functional,nfr,dm}.md`. Kế thừa ô đắt (`sanity-red`/`mutation`/`reverted`/`Tier`) chỉ lấy từ **bản trước của chính file này** (core §7).
- **Ghi thêm sổ `spec-debt.md` của feature, cạnh `frd.md`** (`.specs/main/feature/{F-XXX}-{slug}/`, [`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)) — chỉ theo core §5: thêm **một** dòng `**phát hiện:**` vào mục `SD` đã có cho ID đó nếu mục chưa có dòng của tầng này (mọi mode), hoặc mở `SD` mới cho drift chưa có mục (chỉ default/`full`). Commit cùng `test-report-e2e.md`. Gặp sổ kiểu cũ (`.specs/integrations/*/` · `.specs/tests/*/`) ⇒ **dừng trước khi chạy test**, in `npx spec-lite migrate-spec-debt`. Phép đối chiếu ngược chỉ xét `SD` neo `FAC-*` (trụ của tầng này) → dòng `A-E2E-n` ở §5.
- **GATE version + pin (core §1b, 016) — cấp-scope `e2e`:** version-gate `test-design.versions.e2e` > `test-exec-e2e.test_design_version` → **STOP** báo chạy `/spec-test-exec` trước (D9). pin-gate `test-report-e2e.test_exec_version` (**một số**) == `test-exec-e2e.version` → scope current, dừng; tụt → re-run cả scope. Phân loại NEW/MODIFIED/UNCHANGED (NEW/MODIFIED full-loop; UNCHANGED chỉ re-execute, inherit sanity-red/Finding; MODIFIED-Finding → re-evaluate verdict).
- **Nếu chạy với `--mode` (core §1c):** bỏ qua nhánh phân loại NEW/MODIFIED/UNCHANGED — áp mode cho **hết TC** của scope theo cột mà mode sở hữu, **pin-neutral**. Chỉ hợp lệ khi `pin == version`; stale → STOP báo chạy no-arg (default) trước. Version-gate vẫn enforce như trên.

### Bước 2: Lọc E2E TC (core)

- Nguồn: `test-design.md > ## E2E Test Cases`. Mỗi TC neo đúng 1 `FAC-F*`. Inherit `TC-F*` nguyên văn — KHÔNG đẻ ID mới; tiêu đề test trong code mở đầu bằng chính TC ID để runner filter được (core §2b), không đặt hệ tên riêng cho code.
- Không có E2E TC nào → dừng, báo "feature không có FAC automatable để retrofit ở tầng này" (feature 1-story thuần thường không có FAC — đúng, không phải lỗi).

### Bước 3: Dựng journey + điền test-exec-e2e *(đặc thù FAC)*

Với mỗi E2E TC — tier **luôn `e2e`** (đỉnh chung core §2a: full-stack, browser/app thật + server thật, **không** prefix `be:`/`fe:`). E2E **không** phân bậc rẻ/đắt như AC; điểm quyết định là **shape** của FAC.

**Mobile: viết flow bằng Maestro YAML — bắt buộc, không phải lựa chọn.** `flutter test integration_test/*.dart`/`flutter_test` chạy **trong cùng process** với app (white-box, gọi thẳng `WidgetTester`) — dù build+install lên thiết bị/simulator thật, nó **không phải** e2e: không black-box qua accessibility tree, không tách khỏi Dart VM của app, không đối chiếu qua registry global (`tool/e2e.sh`). Đây là `fe:component`/`fe:api` cao cấp, không phải `e2e`. Project mobile retrofit tầng này **phải** viết `.maestro/flows/{flow}.yaml` (subflow tái dùng khi hợp lý) — chưa có `.maestro/` → escalate kiến trúc (dòng "When NOT to Use" ở trên), không hạ chuẩn xuống `integration_test`.

| FAC khẳng định về… | Shape (template §5) | Đặc thù |
|---|---|---|
| Hoàn tất **business flow** đến outcome cuối, xuyên nhiều màn/story | `journey` / Happy Path | ≥1 `[verify-db]`/`[verify-api]` mỗi scenario |
| Cùng behavior/text/rule **đồng nhất qua N màn** (không cần tuần tự) | `consistency` | trigger ở màn A/B/C → so khớp |
| **Bất biến liên story** sau khi kết hợp nhiều story | `integrity` | assert invariant + no side effect |
| Guard tại integration boundary (auth/scope/validation ở tầng API) | `negative` / guard | baseline → trigger → assert error **VÀ** no DB write |

- **Assert business outcome qua integration boundary, KHÔNG chỉ UI state** (core luật 1 vẫn áp: "cái gì đúng" từ FAC text). Toast/success message **không đủ** (hiện trước khi async job xong).
  - **web:** `[verify-db]` (navigate ra trang khác → confirm data tồn tại/count đúng) hoặc `[verify-api]` (`page.request` để kế thừa auth cookie từ `storageState`).
  - **mobile:** không có DOM/HTTP client trong tay (Maestro black-box qua Semantics Tree) → `[verify-api]` chứng minh bằng (a) **bước kế tiếp của chính flow** quan sát UI phản ứng đúng sau khi app gọi API thật (vd điều hướng, badge cập nhật), hoặc (b) **một flow riêng** gọi lại backend thật qua UI để quan sát effect (vd dùng lại subflow login để verify tài khoản vừa bị vô hiệu không đăng nhập được — như `TC-F003-041`).
- **FAC không drive per-story:** 1 journey e2e phủ **nhiều** story. Không tách e2e TC theo từng story member; dựng cảnh cross-story theo FAC.
- Điền vào `test-exec-e2e.md`: §3 Coverage (FAC → TC, business outcome cần verify) · §4 Integration Points (boundary journey chạm: request accepted / async job / data persisted / scope guard) · §5 Test Cases (persona/pre-conditions/steps Playwright hoặc Maestro/business outcome) · §7.1 POM index (web) / §7.1m Flow Index (mobile — không có POM). Giá trị đúng (outcome mong đợi) lấy từ **FAC text**, không từ code.
- ⚠ **Harness project CHƯA có** (web: chưa có Playwright + POM + seeded backend · mobile: chưa có `.maestro/` — flows + selector-contract global) → **KHÔNG tự dựng e2e harness trong skill** (core §3). Đây là tầng dễ vướng nhất — một project layer-isolated test có thể hoàn toàn thiếu e2e stack. Nhưng **dừng có biên bản, không dừng im**:

```
a. Vẫn dựng/dùng `test-exec-e2e.md` như thường (shape journey, Coverage, POM index — quét A).
b. Ghi TRỌN §4 Results của `test-report-e2e.md`: mỗi E2E TC một row với `Action = harness`,
     `Result` = `⏭`, ba cột sanity-red = `—` (TC không chạy), `Note` trỏ BLK.
c. Mở `BLK-E2E-N` ở §3 — `Vấn đề` hai mệnh đề, `Cần gì để mở khoá` nêu đúng hạ tầng cần dựng
     (web: Playwright + POM + seeded backend · mobile: `.maestro/` + build thật trên thiết bị/emulator).
d. Một dòng §5 Next Actions: `Loại` = `harness` → `PIC` = `👤 DEV` (map core §7.4, vùng đóng băng).
e. NÂNG PIN `test_exec_version` = `test-exec-e2e.version` — cả scope đã có bản ghi, chạy lại
     không đổi được gì (`Action`/`Note` là cột kế thừa, chỉ `--mode full` ghi lại).
f. DỰNG LẠI roll-up `test-report.md` (core §7b).
g. RỒI MỚI escalate kiến trúc cho user.
```

⚠ **Vì sao không dừng im:** dừng trước khi ghi để lại `pin 0` + §4 rỗng, **không phân biệt được với "chưa chạy"** — người đọc report không biết là tắc harness hay chưa ai chạy tầng này, và orchestrator dispatch lại vô ích. Đây cũng là chỗ hai câu trong skill này từng đá nhau: Bước 3 nói *"dừng, escalate"* trong khi Bước 7 + Verification nói *"TC không viết được đã điền `Action = harness`"*. Luật *"không tự dựng harness"* giữ nguyên — chỉ đổi **cách kết thúc**.

### Bước 3b: Tái dùng selector-contract *(đặc thù FAC — chỉ khi journey chạm element chưa có testid)*

E2E POM query bằng `getByTestId` → cần `data-testid` ổn định. `/build` (hoặc Phase 3 functional) đã ghi `selector-contract.md` → tầng này **tái dùng**, chỉ bổ sung khi journey chạm element mà contract chưa phủ. Row bổ sung lấy cầu từ **E2E TC** (`Steps`/`Expected` của TC neo `FAC-F*`), cột `TC` điền TC ID đó. **Merge** theo key `testid` — không rewrite. An toàn: **additive-only, non-behavioral**.

Quy ước đặt tên + cách gắn/query mỗi platform: `references/testid-conventions.md`. **Registry per-feature hay global phụ thuộc harness e2e**, không cố định theo platform (§3): web-react → per-feature (`selector-contract.md` của feature là nguồn thật). **flutter, hoặc react-native khi e2e là Maestro** → nguồn thật là file **GLOBAL** (vd `.maestro/selector-contract.md`), file per-feature chỉ reference — Maestro đọc OS accessibility tree nên không phân biệt RN/Flutter. Identifier `/build` đã gắn nhưng chưa flow nào dùng nằm ở bucket **Reserved** (§5) → tầng này **promote** sang bảng Identifiers khi journey thật sự dùng đến. Pattern gắn cụ thể xem file đó, không lặp lại ở đây.

```
a. Contract: feature ĐÃ có .specs/tests/{F}/selector-contract.md (/build hoặc Phase 3 backfill)?
     → so `template_version` artifact vs template. KHỚP → dùng luôn. LỆCH → kiểm SHAPE thật
       (header bảng) TRƯỚC khi đổi gì (D18): shape đã khớp template ⇒ CHỈ stamp version, KHÔNG đụng
       dòng nào trong bảng; shape cũ ⇒ nâng cấp = đổi header + stamp version, GIỮ mọi giá trị `TC`
       đang có, ô `— (legacy)` / `—` đổi thành RỖNG (v3: rỗng là hợp lệ). KHÔNG derive lại cột TC
       hàng loạt (không tất định — kit D18). Suy "version lệch ⇒ shape cũ" rồi đổi cả bảng là ăn dữ liệu.
     → dùng lại. Journey chạm element chưa có row trong contract?
        → bổ sung row theo quy ước {feature-slug}-{element}[-{qualifier}] (02-artifacts.md §2.3),
          cột `TC` = TC ID của E2E TC đang dựng. MERGE theo key `testid`, không rewrite.
     → feature CHƯA có contract (chưa qua Phase 3 / feature thuần e2e) → tạo từ template, ghi row cho
        element mà E2E TC chạm (đọc Steps/Expected). KHÔNG derive từ frd User Flows (flow không mô tả
        màn hình), KHÔNG harvest testid rời rạc từ code. Xem .docs/024.
b. Gắn testid theo cú pháp platform — `data-testid` (web-react) / `testID` (react-native) /
     `Semantics(identifier:)` (flutter) — vào component cũ cho KHỚP contract (thêm thuộc tính, KHÔNG đổi cấu trúc/hành vi).
     GHI ROW CHO MỌI TESTID GẮN THÊM (.docs/026 D4), cả element chưa TC nào phủ — row đó `TC` rỗng.
c. GATE additive: chạy test hành vi cũ (component/functional nếu có) → phải vẫn xanh. Non-behavioral;
     đỏ = đã lỡ đổi hành vi → revert, xem lại.
d. POM §7.1 dùng testid handle LẤY TỪ contract. KHÔNG tự đặt testid mới trong POM/test.
e. KIỂM HAI CHIỀU (.docs/026 D6) trong phạm vi component vừa chạm: mọi row grep được trong code,
     VÀ mọi data-testid trong component đó có row. Thiếu chiều nào ⇒ bổ sung, không bỏ qua.
```

- selector-contract ở `.specs/tests/{F}/` **ngoài** scope `/artifact-audit` + `/artifact-migrate` (015 §3B) — nhưng `template_version` **có act**: nó là detector hình dạng (024 D18), và skill này là một trong 3 writer nâng cấp được. Thêm row thì **không** đụng version; **nâng cấp hình dạng** thì stamp version mới. Change history = git → **commit** contract nếu có bổ sung.

**Maestro (flutter, hoặc react-native khi e2e chạy bằng Maestro)** — Maestro đọc semantics/accessibility tree, KHÔNG có `getByTestId`/`data-testid`. Identifier convention sống trong **MỘT file GLOBAL ở repo root** (vd `.maestro/selector-contract.md`), dùng chung mọi feature — registry **global**, KHÁC quy ước per-feature ở nhánh trên (lý do: `references/testid-conventions.md` §3). `.specs/tests/{F}/selector-contract.md` (nếu dùng cho nhánh này) chỉ **REFERENCE** subset identifier feature này chạm, KHÔNG phải nguồn thật.

```
a. Contract: đọc file GLOBAL (vd .maestro/selector-contract.md) trước — đây là nơi harness (vd
     tool/e2e.sh) đối chiếu 2 chiều (id dùng trong flow ↔ id khai trong bảng).
     - Element đã có id trong bucket Reserved (gắn từ /build, chưa flow nào dùng — testid-conventions.md
       §5)? → PROMOTE: xoá khỏi Reserved, thêm row vào bảng Identifiers. KHÔNG gắn lại/đặt id mới.
     - Journey chạm element chưa có id ở đâu cả (không Reserved, không Identifiers)?
        → gắn Semantics(identifier: '<id>', ...) vào widget (pattern: testid-conventions.md §2c —
          react-native: testID="<id>"), thêm row vào bảng Identifiers **của file global**, đồng bộ row
          tương ứng vào file per-feature (nếu project giữ per-feature làm reference layer).
b. GATE additive: chạy widget/component test hiện có (vd test xác nhận identifier có mặt trong semantics/
     accessibility tree, tương tự test/ui/selector_contract_test.dart) → phải vẫn xanh trước khi tin
     Maestro nhìn thấy trên thiết bị thật.
c. Flow §7.1 (Flow index, không có POM) dùng id LẤY TỪ file global. KHÔNG tự đặt id mới trong flow
     YAML. KHÔNG target bằng chuỗi qua i18n/localization (đổi wording vỡ flow).
```

- File global selector-contract của nhánh Maestro **giữ nguyên convention non-versioned** như nhánh per-feature (015 §3B) — commit sau khi bổ sung, không bump version nào.

### Bước 3c: Reconcile với test e2e có sẵn *(core §2b)*

- Quét test e2e hiện có cho FAC đó (web: spec Playwright · mobile: flow Maestro) **TRƯỚC khi viết mới**.
- Test cũ assert **đúng FAC** (business outcome, cross-story) → **inherit**: anchor TC ID (title `test.describe`/`test("TC-F… — …")`) + trỏ `spec_path` vào nó, ghi `sanity-red = inherited` ở Results. KHÔNG viết trùng.
- Test cũ assert **theo code lệch FAC** (vd single-story không phủ đúng journey) → **finding**, KHÔNG tính đã cover: giữ test cũ nguyên, viết test mới neo FAC → để đỏ → classify. **KHÔNG** sửa test cũ cho khớp.
- Test cũ **đi đúng journey nhưng oracle chỉ là UI state** (không `[verify-db]`/`[verify-api]`) → **inherit rồi siết oracle** (core §2b): neo TC ID + **thêm** bước verify vào chính test đó, ghi lý do ở `Note`. Đây là ca hay gặp nhất ở e2e brownfield — journey do `/build` viết thường dừng ở DOM. KHÔNG dựng journey thứ hai cạnh nó: e2e trùng là chi phí đắt nhất trong suite.

### Bước 3d: Preflight — kiểm môi trường TRƯỚC khi chạy lượt đầu *(mobile)*

Một lượt e2e mobile tốn ≥2 lần build APK. Chết vì thứ kiểm được trong 5 giây là
mất trọn chu kỳ đó. Đo ở F-001 GAL-Mobile: hai lượt chết vì **màn hình khoá**,
một lượt đẻ ra finding giả vì **credential lệch backend đã compile**.

Chạy hết bảng này **trước** lượt đầu, và lại sau mỗi lần nghỉ dài:

| Kiểm | Lệnh | Hỏng thì |
| --- | --- | --- |
| Thiết bị còn kết nối | `adb devices` | không có gì để chạy |
| **Không khoá màn hình** | `adb shell dumpsys window \| grep isKeyguardShowing` | flow chết ở `launchApp`; `adb` **không** bypass được PIN/pattern — phải mở tay |
| Giữ màn sáng suốt lượt | `adb shell svc power stayon usb` | khoá lại giữa journey dài, hỏng ở chỗ khó chẩn đoán |
| Backend sống | `curl -o /dev/null -w '%{http_code}' <base>/…` | mọi assert nghiệp vụ vô nghĩa |
| **Endpoint khớp binary** | so `backend_url` ở frontmatter với dart-define/env đã build | đẻ finding giả (xem luật "khoá môi trường") |
| **Tài khoản đăng nhập được** | `curl` login từng tài khoản trong `.env.e2e` | đỏ ở bước login, không bao giờ tới phần muốn đo |
| Tài khoản không-idempotent về đúng trạng thái | login bằng mật khẩu "trước" phải `200` | teardown lượt trước hụt, TC đỏ vì lý do sai |

**Không tự chế dữ liệu để lấp.** Thiếu tài khoản ⇒ `⏭` + `BLK-E2E-N` nêu đúng
thứ thiếu; thiếu thiết bị mở khoá ⇒ **hỏi user**, đó là việc của người.

### Bước 4: Viết test — journey cross-story *(đặc thù FAC)*

**web — Playwright + POM:**
- Dựng **journey** theo §5 template: `[goto]` → `[action]` → `[wait]` async → `[assert]` UI → `[verify-db]`/`[verify-api]` business outcome. Persona + pre-conditions + seed data (§2.4, §6) từ FAC.
- Test bám **POM** (`pom_path`) — locators `getByTestId` từ contract, không selector CSS/text mong manh. Auth qua `storageState` reuse; cross-scope guard dùng storage state thứ hai (out-of-scope user).
- **≥1 `[verify-db]` step mỗi journey scenario** — navigate RA KHỎI trang hiện tại → assert data thật (count/status), KHÔNG dựa toast.
- Kết quả mong đợi từ FAC text (không từ code).

**mobile — Maestro flow YAML (không có POM):**
- Dựng **journey** theo §5 template mobile: `[action]` (`tapOn`/`inputText`) → `[wait]` (`extendedWaitUntil`) → `[assert]` (`assertVisible`/`assertNotVisible`) → `[verify-api]` business outcome. Persona + pre-conditions từ FAC; flow phải **tự chứa** (`launchApp: {clearState: true}` ở đầu — không phụ thuộc flow khác chạy trước, tránh state rò khi chạy cả bộ).
- Target bằng `id:` lấy từ selector-contract (Bước 3b) — KHÔNG target bằng chuỗi i18n, KHÔNG dùng `Key` (Maestro đứng ngoài runtime, không thấy).
- Tái dùng subflow đã có (vd login) thay vì lặp lại step — subflow là đơn vị "reuse" tương đương POM method của mobile.
- **≥1 `[verify-api]` step mỗi journey scenario** — bước kế tiếp của flow quan sát effect thật, hoặc `runFlow` một flow riêng (vd login lại) — KHÔNG dựa toast/snackbar đơn thuần (toast tự tắt sau vài giây, assert phải đứng ngay sau hành động submit).
- Kết quả mong đợi từ FAC text (không từ code).

### Bước 5: Sanity-red + chạy + classify *(theo core, sắc thái FAC)*

- **Sanity-red (core §4):** với FAC, mutation tự nhiên = **phá 1 story member trong journey** (vd mutate handler của 1 bước cho trả sai / bỏ persist) → cả journey phải flip 🔴 (thường ở `[verify-db]`/`[verify-api]` step) → revert → verify green → ghi sanity-red/mutation/reverted ở Results.
- **Batch theo journey (core §4):** 1 journey phủ nhiều story → mutate 1 member đủ chứng minh proven-red cho cả journey TC đó; 1 chu kỳ mutate-revert. Chi phí thật = round-trip sửa/revert code, KHÔNG phải tốc độ test.
  - **Mutation journey THAY THẾ mutation-per-TC ở tầng này** (không phải làm thêm): journey đi qua nhiều story nên phá 1 member là cả journey đỏ — đó đã là bằng chứng "test biết đỏ" cho TC đó. Nhiều TC **dùng chung một seam** ⇒ gom vào **một** chu kỳ mutate/build, ghi cùng một `mutation` cho các TC đó.
  - **Vì sao cần luật riêng:** chi phí sanity-red **không đồng nhất giữa ba tầng**. validation/functional = `flutter test`, vài giây. e2e mobile = 2 lần build APK (~2 phút/lần) + cài + chạy ⇒ ~6 phút **mỗi TC** chỉ để chứng minh biết đỏ; 5 TC là nửa tiếng thuần chờ build. Áp mutation-per-TC ở đây là biến cổng chất lượng thành thuế thời gian mà không thêm thông tin nào.
- Chạy test thật lên code cũ → record result vào **§4 Results của `test-report-e2e.md`**. E2E chậm + có thể flaky (async timing) → nếu đỏ do timing chứ không do assert, classify **flaky** (core §5), ổn định hoá bằng `waitFor`/`extendedWaitUntil` (không `sleep`) trước khi tin kết quả.
  - **mobile:** chi phí round-trip cao hơn hẳn web — không headless, thường chưa vào CI (chạy tay). Chạy lại bằng harness `--no-build` (hoặc tương đương) khi mutation chỉ đổi logic phía server/ViewModel; rebuild APK/IPA đầy đủ khi mutation đổi cả UI. Batch theo journey **quan trọng hơn ở mobile** vì mỗi vòng build+install+run tốn nhiều phút, không phải giây như Playwright.
- Đỏ → classify (core §5): **bug-code** (code không thoả FAC — vd data không persist, invariant vỡ) | **spec-drift** (code lệch FAC **có dấu vết**, BA quyết — tra/ghi sổ `spec-debt.md` cạnh `frd` theo core §5) | flaky | test-error. Ghi Findings. **KHÔNG sửa test cho xanh.**

### Bước 6: Prune (core)

- E2E TC / journey pin mà không neo `FAC-F*` nào → bỏ. KHÔNG có section `Pruned` (core §6): phần đáng nâng thành FAC thật trong frd là **việc** ⇒ một dòng §5 Next Actions (`Loại` = `coverage-gap`, `PIC` = `👤 QC`); phần "đã bỏ, xong" → commit message.

### Bước 7: Dựng lại report + nâng pin + roll-up + report (core §7 + §7b)

- **Dựng lại trọn `test-report-e2e.md`** rồi ghi đè một lần (core §7): 5 section `1 Summary · 2 Findings · 3 Blockers · 4 Results · 5 Next Actions`; ID `FIND-E2E-NN` · `BLK-E2E-N` · `A-E2E-N`, cấp số tiếp. `Covers`/`Summary`/`Coverage`(FAC X/Y kèm đỏ)/dòng `**Mục:**` **tính lại**; ô đắt **kế thừa** cho TC `UNCHANGED`.
- **`dup-of` (core §7.3):** e2e đỏ vì cùng nguyên nhân với một `FIND-VAL-*`/`FIND-FUN-*` → ghi ID đó vào cột `dup-of`. Đây là ca hay gặp nhất: một `bug-code` đã đỏ ở functional thì journey e2e cũng đỏ theo.
- §5 Next Actions từ **ba nguồn**: §2 `FIND-E2E-*` còn đỏ · §3 `BLK-E2E-*` · §1 `Coverage` thiếu phủ. `PIC` **derive** từ `Loại` (core §7.4); `👤` là vùng đóng băng.
- **TC không viết được (⏭ deferred)** → điền cột `Action` ở §4 Results + trỏ 1 `BLK-E2E-N` ở `Note` (trừ `no-seam`) (core §7.5): `harness` (assert rõ, chỉ thiếu e2e harness chưa dựng — đi kèm escalate kiến trúc §3; **thường gặp nhất ở e2e** vì e2e vốn là biên integration) · `refactor` (hiếm ở e2e — chỉ khi một phần journey thực ra là logic thuần tách ra unit được, core §3b) · `need-clarify` (spec mâu thuẫn với chính nó, với `tech.md` hoặc UI, hay thiếu thông tin — nối Action Items; spec lệch với code là finding `spec-drift`, không phải tag này) · `no-seam` (không có journey để test ở tầng này). KHÔNG để trống trơn.
  - **mobile:** TC cần tài khoản/dữ liệu dùng-một-lần mà project **chưa có quy trình seed/teardown/owner rõ ràng** (vd tài khoản test bị soft-delete không có API khôi phục, không rõ ai reset theo chu kỳ) → hợp lệ để đánh `⏭ deferred`, `Action: harness`, OBS ghi rõ **thiếu tài khoản test disposable** — đây là gap hạ tầng test, **KHÔNG** coi là lỗi code.
- **Nâng pin (core §1b③, 016):** set `test_exec_version` = `test-exec-e2e.version` ở frontmatter `test-report-e2e.md` (file scope khác giữ pin riêng của nó — không đụng). UNCHANGED TC inherit sanity-red/Finding; NEW/MODIFIED có mới (MODIFIED-Finding đã re-evaluate).
- **Dựng lại roll-up `test-report.md`** (core §7b, 4 bước): glob `test-report-*.md` **trừ roll-up** → đọc pin + §1 + §5 + số finding đỏ mở (trừ `dup-of`) của từng file → dựng lại trọn 3 bảng. Là tầng chạy sau cùng nên đây thường là roll-up đầy đủ nhất — vẫn dựng lại từ đầu, KHÔNG đọc bản cũ.
- **Commit** `test-report-e2e.md` + `test-report.md` + `selector-contract.md` (nếu bổ sung) + test code (spec/POM/fixtures) + `test-exec-e2e.md` (git = history duy nhất, 015 §3B).
- Report cho user: số FAC covered, journey/consistency/integrity/guard đã dựng, số đỏ + verdict, action items (tách `🤖` và `👤` theo `PIC`), pin e2e đã tiến tới v{N}, roll-up đã sinh lại.

---

## Đơn vị tiến độ

Sổ của skill này: `.specs/tests/{F-XXX}-{slug}/.progress/e2e.md` — **writer duy nhất là skill này**; KHÔNG đọc, KHÔNG ghi sổ của skill khác. Dựng lại **trọn** sổ mỗi lượt rồi ghi đè: nội dung derive từ artifact nên một ô sửa tay bị ghi đè ở lượt sau. Hình dạng + frontmatter: `templates/tests/verify-progress-template.md`; định nghĩa thư mục: `02-artifacts.md` §4.7.

**Hạt là một dòng / TC** — **không** theo journey, **không** theo shape. `[x]` nghĩa là *"đã có bản ghi"*, không phải *"xanh"*.

**Việc lớn** — `- [ ] /spec-test-retrofit-e2e   pin {p}/{v}   ({k}/{n})` — tick khi `test-report-e2e.test_exec_version` == `test-exec-e2e.version`. Version-gate lệch ⇒ in `⛔ chạy /spec-test-exec` thay vì `[ ]` (core §1b).

| Việc nhỏ | Đọc file / field | Xong khi |
|---|---|---|
| `TC-…  {shape}  {FAC}  {result}  ⟨mut: …⟩` — 1 dòng / TC | danh sách + thứ tự: `test-exec-e2e.md` §3 Coverage cột `E2E TC`. Trạng thái: `test-report-e2e.md` §4 Results, gồm ô **`reverted`** | bản ghi **tự nhất quán** **và** `reverted` = `✅` |
| *(TC hoãn)* `⏭ {Action} → {BLK}` | cùng row: `Action` · `Note` | `Action` ∈ 4 tag **và** (`Action` ≠ `no-seam` ⇒ `Note` trỏ đúng một `BLK-E2E-N` có mặt ở §3) |
| *(nhãn shape)* | `test-exec-e2e.md` §3 cột `Shape`; `negative` suy từ TC ở §5.4 | — |
| *(nhóm hiển thị)* | ô `mutation` **giống nhau** giữa các row §4 | — |

**Bản ghi tự nhất quán** = row §4 tồn tại **và** `sanity-red` ∈ {`proven-red`, `red-first`, `inherited`, `n/a`} **và** (`sanity-red` = `proven-red` ⇒ `mutation` có nội dung **và** `reverted` = `✅`).

**Vì sao tầng này đọc thêm `reverted`:** đây là tầng có cửa sổ giữa "áp mutation" và "revert" **dài nhất trong kit** — bước mutate là một lượt chạy journey full-browser, vài phút. Đọc thêm một ô không tốn gì, và nó chặn đúng ca report nói TC xanh trong khi code còn mang mutation.

**Vì sao không theo journey, không theo shape:** journey **không có ID** ở đâu trên đĩa (nó là một `test.describe` trong `{spec_path}`) ⇒ không đếm được, tick thành tay. Shape là **phân loại**, một shape có 0–3 TC. Và §3 Coverage là **một hàng / `FAC ID` ứng đúng một `E2E TC`** ⇒ FAC ↔ TC là **1:1**; cái phủ nhiều thứ là journey ↔ **story**, mà story không xuất hiện ở §4 (cột `Covers` chỉ ghi `FAC-F*`).

**Ca thiếu harness** (Bước 3) hiện đúng như sau, và `[x]` là **đúng** — sản phẩm của một `⏭` là một quyết định phân loại + một `BLK-*` + một dòng §5 `👤 DEV`, không phải việc còn nợ:

```markdown
- [x] /spec-test-retrofit-e2e   pin 1/1   (3/3 · tất cả ⏭ harness → BLK-E2E-1)
  - [x] TC-F004-050  journey    `FAC-F004-001`  ⏭ harness → BLK-E2E-1
  - [x] TC-F004-051  integrity  `FAC-F004-002`  ⏭ harness → BLK-E2E-1
```

**Hậu tố `· tất cả ⏭ {tag} → {BLK}` ở việc lớn có điều kiện:** in **chỉ khi** mọi TC của scope đều `⏭`
**cùng một** tag **và** tag đó tạo `BLK` (`harness`/`refactor`/`need-clarify`). Cả scope `⏭` bằng
`no-seam` thì **không** in hậu tố — `no-seam` không tạo `BLK` (core §7.5) nên nửa `→ {BLK}` không có gì
để trỏ tới, và in một `BLK` không tồn tại là đúng cái quy tắc 2 chiều của §3 cấm. Trộn tag (một TC
`harness`, một TC `no-seam`) cũng không in — hậu tố nói *một* lý do cho cả scope, trộn thì lý do nằm ở
từng dòng TC.

**Tiền đề tầng 2** in kèm việc lớn: `⟨functional pin {p}/{v} — contract chưa backfill⟩` (core §1b). `selector-contract.md` **không** mang dấu vết "đã backfill hay chưa" — `template_version` chỉ là detector hình dạng (024 D18) — nên pin của tầng functional là chỗ duy nhất đo được. Contract lệch lộ ra ở e2e dưới dạng POM trỏ testid không tồn tại → đỏ vì wiring → dễ phân loại nhầm `bug-code`; thấy trước rẻ hơn nhiều một lượt browser. **Nhưng quyết định chạy vẫn đọc pin**, không đọc dòng in kèm.

**Cấm đưa vào sổ:**

- Từng step của journey (`[goto]` / `[verify-db]` …) · từng story member (không có ánh xạ nào trong report).
- `mutate` / `revert` / `verify-green` tách 3 dòng — cùng một chu kỳ, cùng một bộ ô.
- Merge contract / gắn `data-testid` — 024 D18 **cấm** derive lại cột `TC` hàng loạt, và ô `TC` rỗng là hợp lệ.
- "Dựng e2e harness" — `👤 DEV`, ngoài remit của skill (core §3).
- `FIND-E2E-*` · `dup-of` (không ai derive được — core §8).
- Dòng `step=` — biên bản là của orchestrator.

---

## Ràng buộc (nhắc lại từ core — áp cho FAC)

- Đọc-xuống: **KHÔNG** sửa test-design, **KHÔNG** sửa frd (spec-drift → finding + mục `SD` ở sổ cạnh `frd` → BA quyết ở `/spec-new {F-XXX}`).
- Nhìn code chỉ để biết *móc vào đâu* (handler/endpoint/component/testid/POM), **KHÔNG** để lấy *giá trị đúng* (từ FAC text).
- Test xanh mà **không** có `sanity-red` proven-red (cột §4 Results) = KHÔNG tính pass.
- Guided mutation phải **revert sạch + verify green** trước khi sang TC kế; verify-green fail → **STOP** (repo bẩn).
- Bổ sung testid **additive-only, non-behavioral**; gate: hành vi cũ vẫn xanh.
- Result + Findings ghi ở **`test-report-e2e.md`**, KHÔNG ghi vào `test-exec-e2e.md`, KHÔNG ghi vào file scope khác.
- **Một file một writer (core §7):** chỉ ghi `test-report-e2e.md` + roll-up; không mở file scope của tầng khác.
- **Mobile — hành động không hoàn tác được PHẢI hỏi trước khi chạy thật:** nếu chạy journey nghĩa là thực thi một thao tác phá dữ liệu thật mà project không có cách khôi phục tự động (vd soft-delete tài khoản, restore chỉ qua Admin thủ công) → **dừng, hỏi user xác nhận** trước khi gọi harness (vd `tool/e2e.sh`) chạy flow đó.
- **KHÔNG delegate phần chạy THIẾT BỊ cho fork/subagent — chạy trong session chính.** Thiết bị/emulator là **tài nguyên độc quyền, CÓ TRẠNG THÁI** (app đã cài, phiên đăng nhập, mật khẩu đã đổi ở backend). Fork chết giữa chừng để lại trạng thái bẩn ở chỗ **`git` không thấy**. Đo thật ở F-001 GAL-Mobile: fork **không** chết — nó chạy suốt và tự hoàn thành. Hỏng là do **hai đường điều khiển cùng chạm thiết bị**: session cha tưởng fork đã chết nên chạy tay song song, sinh lỗi adb/gRPC và một process trông như mồ côi; cả hai bên đều mất khả năng biết chuyện gì đang xảy ra. Lần sau đó, một lệnh `curl` tay để debug song song đã **đổi mật khẩu tài khoản test thật**. ⇒ luật đúng không phải "fork kém tin cậy" mà là **một đường điều khiển duy nhất tại một thời điểm**: bên giao việc đứng ngoài hoàn toàn (không chạy tay, không curl debug) cho tới khi bên nhận báo cáo xong. Khác hẳn test in-process: chậm hơn nhưng mọi thứ nhìn thấy được.
- **`COMPLETED` / exit 0 KHÔNG phải bằng chứng đã chạy — assert vào GIÁ TRỊ.** Một bước chỉ được tính là đã thực thi khi có assert vào **kết quả nó sinh ra**; "không exception" chỉ chứng minh không lỗi. Đo thật: Maestro `evalScript` **chỉ thực thi khi bọc `${...}`** — dạng khối YAML (`evalScript: |`) được nhận, báo `COMPLETED`, và **không chạy gì cả**. Một agent grep thấy `COMPLETED` rồi tuyên bố cơ chế hoạt động, gửi recipe cho agent khác; agent kia debug đúng hiện tượng (`output.*` ra `undefined`) nhưng quy sai nguyên nhân sang "khác version/khác máy" — cùng máy, cùng binary. Tốn một vòng debug + một lần đổi mật khẩu tài khoản thật. Chứng minh:
  ```
  - evalScript: ${output.x = 42}   →  assertTrue ${output.x == 42}       COMPLETED  ✓ chạy
  - evalScript: |                  →  assertTrue ${output.blocky == 42}  FAILED     ✗ no-op
      output.blocky = 42;
  ```
  ⇒ **mọi `runScript`/`evalScript`/bước dựng dữ liệu phải kèm `assertTrue` vào `output.*` ngay sau.** Đây là **sanity-red áp cho chính công cụ đo** — kit đã đòi chứng minh "test biết đỏ", chưa đòi chứng minh "bước dựng dữ liệu biết chạy".
  Ba chi tiết Maestro trả giá mới biết: `JSON.stringify` (**không** phải `json2str`) · `json(res.body)` để parse · inline `${...}` **vỡ parse** khi JS chứa `{}` nên logic nhiều dòng phải dùng `- runScript: {file: x.js, env: {...}}` · `runScript`/`http` chạy trên **host** nên `localhost` tới thẳng backend máy dev, không cần `adb reverse` cho lệnh đó.
- **Khoá môi trường trong suốt một lượt.** `backend_url` (frontmatter `test-exec-e2e.md`) phải khớp endpoint đã compile vào binary, và credential phải cùng **một** nguồn với endpoint đó. **Đổi môi trường giữa lượt đang chạy là nguyên nhân gốc của finding GIẢ**: đã sinh ra một `BLK-E2E-*` giả vì `.env.e2e` trỏ backend local trong khi APK còn trỏ remote — cùng tài khoản `200` ở local, `401` ở remote, và lượt chạy kết luận "tài khoản bị khoá" (hợp lý với dữ kiện nó thấy, sai hoàn toàn). Nghi ngờ `401`/`403` ⇒ kiểm endpoint khớp trước khi classify.
- **Escalate, KHÔNG tự dựng harness:** project chưa có e2e stack → **dừng có biên bản** rồi báo user (Bước 3 + core §3): §4 đủ row `⏭ harness`, `BLK-E2E-N`, dòng §5 `👤 DEV`, pin đã nâng, roll-up đã dựng lại. Không đẻ harness ad-hoc, cũng không dừng im để lại `pin 0` + §4 rỗng.
- **Format (core §7.1):** đúng **5** section, **toàn bảng** — 0 đoạn văn trần, ô không vượt trần ký tự, `Vấn đề` hai mệnh đề chứ không phải nhãn cụt. KHÔNG `Pruned`/`Observations`/`Sanity-Red Ledger`/`Change History`/timeline/run-log.
- **Đọc-hiểu (core §7.2):** mọi nhãn dùng trong bảng phải có **legend** ở section định nghĩa nó; ba câu hỏi *sai gì · chưa kiểm được gì · ai làm gì tiếp* trả lời được mà không cần mở code.
- Report **chỉ do skill ghi** — không có lối người sửa tay (030 D22).

## Red Flags

- Assert **chỉ UI state** (toast "Success") thay vì business outcome qua integration boundary → journey không bắt được data-loss / async-fail (thiếu `[verify-db]`/`[verify-api]`).
- Tách e2e TC theo từng story member thay vì dựng journey cross-story → nhầm scope, trùng tầng functional.
- Đưa AC data/computation 1-story lên e2e trong khi kiểm được ở `be:handler`/`fe:component` → sai tầng (chậm + giòn); e2e chỉ cho journey/consistency/integrity/guard cross-story.
- Tự dựng e2e harness (Playwright/POM/seed cho web; Maestro/flow-runner cho mobile) ad-hoc trong skill khi project chưa có → mỗi feature đẻ một kiểu harness (phải escalate kiến trúc, core §3).
- **Mobile:** viết `integration_test/*.dart` (hoặc `flutter_test` widget test) rồi ghi vào `test-exec-e2e.md`/`test-report.md` như thể đã cover tầng `e2e` → sai tier — white-box cùng process, không phải Maestro black-box; project chưa có `.maestro/` = escalate kiến trúc, không hạ chuẩn xuống harness widget-test sẵn có rồi coi là "deviation chấp nhận được".
- Harvest testid/identifier rời rạc từ code thay vì tái dùng/mở rộng selector-contract (web: per-feature; mobile: file global) → đóng băng đúng cái thiếu.
- Tự đặt testid/identifier mới trong POM/flow không khớp contract → hai bên (code/test) lệch nhau.
- **Mobile:** tự ý chạy harness (`tool/e2e.sh` hoặc tương đương) thực thi một journey phá dữ liệu thật không hoàn tác được mà **không hỏi user trước** → dữ liệu mất không khôi phục được (khác hẳn web nơi seed/teardown DB thường tự động).
- **Mobile:** gán `Action: bug-code`/bỏ qua TC cần tài khoản disposable mà project chưa có quy trình seed/teardown, thay vì đánh dấu `⏭ deferred, Action: harness` với OBS giải thích rõ.
- Bump `template_version` selector-contract khi bổ sung row → sai (test-side non-versioned, 015 §3B).
- Bổ sung testid làm đổi hành vi (không chỉ thêm thuộc tính) → gate đỏ mà vẫn tiếp.
- Mở/ghi `test-report-{validation,functional,nfr,dm}.md` → mỗi report một writer (core §7); tầng khác nằm ở file khác.
- Ghi xong file scope mà **không dựng lại roll-up**, hoặc dựng roll-up bằng cách đọc bản cũ rồi gộp thêm → vỡ core §7b.
- Journey đỏ vì cùng nguyên nhân với finding tầng dưới mà không ghi `dup-of` → một bug thành ba finding (core §7.3).
- Gán `PIC` theo cảm tính, hoặc tự nâng `👤` thành `🤖` rồi tự dựng harness e2e → vỡ core §7.4 + luật escalate (§3).
- `sanity-red` phá cái không thuộc journey (mutate chỗ journey không đi qua) → journey vẫn xanh, không chứng minh được proven-red; phải mutate đúng story member journey chạm.
- Coi đỏ do async timing là bug-code → sai; đó là **flaky**, ổn định hoá bằng `waitFor` trước khi tin.
- Lấy giá trị đúng từ code thay vì FAC text → test soi gương code.
- Sửa test cho xanh khi gặp đỏ thay vì phân loại finding.

## Verification

- [ ] Mỗi E2E TC neo đúng 1 `FAC-F*`; inherit `TC-F*` nguyên văn (không đẻ ID mới); suite 100% traceable tới FAC ID.
- [ ] Journey full-browser (web) / **Maestro flow YAML trên build thật** (mobile — **không** `integration_test`/`flutter_test`) cross-story (1 journey phủ nhiều story); shape đúng FAC (journey/consistency/integrity/guard); **không** tách per-story.
- [ ] Assert **business outcome qua integration boundary** — web: ≥1 `[verify-db]`/`[verify-api]` mỗi journey scenario · mobile: ≥1 `[verify-api]` (bước kế tiếp của flow hoặc `runFlow` flow riêng, KHÔNG `page.request`) hoặc `[verify-persist]` (kill + relaunch); toast/UI-state đơn thuần **không** tính đủ.
- [ ] Project chưa có e2e harness **hợp lệ cho platform của feature** (web: Playwright+POM+seed · mobile: `.maestro/` — flow YAML + selector-contract global + build thật; **không** thay bằng `integration_test`/widget test) → đã **dừng có biên bản** (Bước 3): §4 có row cho **mọi** E2E TC với `Action = harness`, một `BLK-E2E-N` ở §3, một dòng §5 `Loại = harness` / `PIC = 👤 DEV`, pin đã nâng = `test-exec-e2e.version`, roll-up đã dựng lại — rồi mới escalate. **Không** tự dựng harness, **không** dừng im với `pin 0` + §4 rỗng.
- [ ] selector-contract tái dùng (`/build` hoặc Phase 3); row bổ sung (nếu cần) có cột `TC` = `TC-F*` của E2E TC, **merge** không overwrite, additive verify-green; web: POM `getByTestId` từ contract per-feature · mobile: identifier từ file global (per-feature chỉ reference), id ở bucket **Reserved** đã promote khi journey dùng đến (không tự đặt testid/identifier mới); `template_version` **inert** (không bump).
- [ ] **Mobile:** journey phá dữ liệu thật không hoàn tác được → đã hỏi user xác nhận trước khi chạy harness thật; TC cần tài khoản disposable chưa có quy trình seed/teardown → đã đánh `⏭ deferred, Action: harness` (không phải bug-code).
- [ ] Oracle nào đọc **nội dung** handle (`text:`/`contains`) → đã mở code render handle đó xác nhận giá trị thật (kể cả nhánh fallback), không tin cột `Element` của contract; mô tả lệch ⇒ đã sửa contract cùng commit (core §3, `testid-conventions.md` §3d).
- [ ] **Source khớp binary:** `git diff -- {src}/` sạch **và** binary trên thiết bị là bản build TỪ source đó (sau mọi revert đã rebuild + cài lại). Không suy "source sạch ⇒ binary sạch".
- [ ] Phần chạy thiết bị chạy ở **session chính**, không fork/subagent; không còn process harness mồ côi (`pgrep -f e2e.sh`).
- [ ] `backend_url` khớp endpoint trong binary + credential cùng nguồn; môi trường **không đổi** giữa lượt.
- [ ] TC `Idempotent: no` đều có `Teardown` + **cách kiểm teardown đã chạy**; thiếu ⇒ không được đánh 🟢.
- [ ] Mỗi FAC có `sanity-red`/`mutation`/`reverted` ở Results — mutation = **phá 1 story member** journey chạm → cả journey đỏ (proven-red).
- [ ] Test e2e cũ đã reconcile (inherit-anchor / finding), không viết trùng, không nuốt bug (core §2b).
- [ ] Mỗi test (mới/inherited) nhúng TC ID máy-đọc-được (title `test.describe`/`test`), 2 chiều với test-exec.
- [ ] `test-exec-e2e.md` điền đủ Coverage/Integration Points/Test Cases/POM index; **không** có ô result.
- [ ] Result + Findings **chỉ** ở `test-report-e2e.md` (`mode: retrofit`); `git diff --stat` chứng minh `test-report-{validation,functional}.md` **không đổi dòng nào**.
- [ ] File scope đúng 5 section, toàn bảng, 0 ô vượt trần; §1 `Summary` + số đếm ở dòng `**Mục:**` khớp đếm lại từ §4.
- [ ] Report đạt tiêu chí đọc-hiểu (core §7.2) — mọi nhãn có legend, ba câu hỏi trả lời được.
- [ ] Mọi dòng §5: `Nguồn` trỏ `FIND-E2E-*`/`BLK-E2E-*`/req-ID (không mồ côi), `Loại` thuộc 8 nhãn, `PIC` khớp map core §7.4.
- [ ] Đã **dựng lại roll-up** `test-report.md` từ mọi `test-report-*.md` (trừ chính nó); `derived_from.e2e.test_exec_version` = pin vừa nâng.
- [ ] TC không viết được (⏭ deferred) đã điền cột `Action` = `harness` / `refactor` / `need-clarify` / `no-seam` (core §7), không để trống trơn (ở e2e thường là `harness`; core §3b).
- [ ] GATE version+pin đã chạy (core §1b): version lệch → STOP báo `/spec-test-exec`; pin bằng → skip; pin tụt → re-run cả scope e2e (NEW/MODIFIED full-loop, UNCHANGED re-execute inherit).
- [ ] Cuối: đã **nâng pin** `test_exec_version` = `test-exec-e2e.version` ở `test-report-e2e.md` (không đụng file scope khác — core §1b③).
- [ ] Findings phân loại đúng bug-code vs spec-drift vs flaky; spec-drift có action nối `/spec-new {F-XXX}` và có mục `SD` ở sổ cạnh `frd` (core §5); flaky đã ổn định hoá (waitFor, không sleep).
- [ ] Mọi mutation đã revert sạch (verify green); repo không còn code bị phá.
- [ ] `test-report-e2e.md` + roll-up + selector-contract + test code (spec/POM/fixtures) đã **commit** (git = history, 015 §3B).
- [ ] TC bị bỏ: phần đáng nâng thành FAC đã thành một dòng §5 (`coverage-gap`), phần còn lại ghi ở commit message — KHÔNG có section `Pruned`.
- [ ] Hai quét đúng thứ tự (core §1): hết quét A thì **mọi** TC có shape + wiring, mọi TC `⏭` đã có row + `BLK`, mà **chưa** chu kỳ mutate nào chạy.
- [ ] Row §4 của một journey ghi **ngay sau** revert + verify-green của journey đó (core §7.0), không dồn tới cuối scope — bị kill giữa scope thì bằng chứng `sanity-red` đã trả tiền còn lại để lượt sau kế thừa.
- [ ] Re-execute một scope e2e: **đã reset seed trước** — không tin kết quả đỏ trên seeded DB còn rác của lượt bị ngắt (core §8).
- [ ] Đã ghi lại `.progress/e2e.md` theo section `## Đơn vị tiến độ`: một dòng / TC (không theo journey, không theo shape), tick đọc thêm `reverted`; ca thiếu harness in `pin {v}/{v}` + mọi dòng `[x] ⏭ harness → BLK-E2E-N`.
