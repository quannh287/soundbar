---
name: spec-test-exec
description: Sinh bộ test-exec cho MỘT feature vào .specs/tests/{feature}/ — render Test Cases trong test-design.md thành 5 doc thực thi theo scope (validation, functional, e2e, nfr, dm) + tạo lần đầu bộ `test-report-{scope}.md` (nơi giữ result của từng scope) + roll-up `test-report.md`. 100% automation (một harness duy nhất — không còn phân biệt manual/auto). Đọc-xuống từ test-design (source of truth), inherit TC-F* nguyên văn, KHÔNG đẻ ID mới. Artifact BỀN — 1 bộ/feature, ghi đè tại chỗ mỗi lần chạy, lịch sử qua git.
---

# spec-test-exec

## Overview

Sinh **bộ test-exec** cho một feature vào `.specs/tests/{F-XXX}-{slug}/` — render các Test Case đã thiết kế ở `test-design.md` thành **doc thực thi** theo từng **scope** (validation / functional / e2e / nfr / dm). **Một nhà bền / feature** (cùng slug với feature), sống chung thư mục với `test-design.md` + `selector-contract.md` (015). **KHÔNG** còn tầng cycle bundle `{NNN}-{cycle-slug}` — artifact test-side bền, ghi đè tại chỗ; lịch sử "đã chạy gì qua thời gian" = git.

**Bộ file khớp 1:1 với loại TC của test-design:** `test-exec-validation` (Validation TC ← VR) · `test-exec-functional` (Functional TC ← Story AC, gồm `fe:component`) · `test-exec-e2e` (FAC) · `test-exec-nfr` · `test-exec-dm`. Validation và Functional trước đây gộp chung `test-exec-func` — nay tách để mỗi loại TC có đúng một file, hai hình dạng (validation: 1 pos + ≥1 neg vs functional: Given-When-Then) không lẫn nhau (014 Phase 0).

**100% automation — một harness duy nhất:** đã **bỏ phân biệt manual/auto**. Mỗi scope render **đúng một doc** (không còn `-manual`/`-auto`). functional & e2e chạy bằng automation. `test-exec-functional` **chỉ chứa TC automatable** (Autoable=YES/MAYBE ở test-design); TC visual không script được (Autoable=NO) **không render** vào test-exec — ở lại test-design. → tối đa **5 doc test-exec**.

**Report: một file / scope + một roll-up (030).** Doc test-exec là **spec của test code** (layer/file/assert/testid) — **KHÔNG chứa kết quả**. Result sống ở `test-report-{scope}.md`, **đúng một skill được ghi** vào mỗi file; `test-report.md` là **roll-up** derive từ chúng (xem `02-artifacts.md` §4.4 + `.docs/013` §4).

`/spec-test-exec` **chỉ TẠO** các file report lần đầu (khung + legend, `Results` rỗng, pin `0`) rồi **KHÔNG đụng nữa** — kể cả nhánh RECONCILE (030 D23). Writer của report là 3 skill retrofit (`validation`/`functional`/`e2e`); `nfr`/`dm` **chưa có writer** nên file chỉ được tạo rồi để not-run (030 D22). Lý do không chèn sẵn dòng TC: retrofit **dựng lại trọn** file mỗi lượt và lấy danh sách TC thẳng từ `test-exec-{scope}.md` ⇒ rows tự khớp, và mỗi report giữ đúng **một** writer.

**Vị trí trong 3 layer** (xem `02-artifacts.md` §4):

```
frd.md ──(/spec-test | /spec-test-design)──▶ test-design.md ──(/spec-test-exec)──▶ tests/{F-XXX}-{slug}/ (5 test-exec + report per-scope + roll-up)
         [DESIGN — TC là gì]                 [SOURCE OF TRUTH]  [EXECUTION — chạy bằng harness gì]
```

**Cốt lõi — đọc xuống, KHÔNG sáng tạo:**
- test-design.md là **source of truth** của bộ Test Case. Skill này **chỉ đọc** test-design → route TC vào doc theo section nguồn (scope).
- **Inherit `TC-F*` nguyên văn** — KHÔNG đẻ ID mới, KHÔNG renumber. Tiêu đề test trong code mở đầu bằng chính TC ID để runner filter được (`test-core` §2b) — **không** có hệ tên riêng cho code.
- **Một bộ bền / feature** — chạy lại **reconcile tại chỗ** cùng thư mục `tests/{F-XXX}-{slug}/` (git giữ bản trước). **chạy lại KHÔNG xoá gì** (016): khi test-exec đã tồn tại, skill **so version** rồi áp **delta wiring** (thêm/xoá/sửa dòng TC) — và **không đụng file report nào** (030 D23). Đây là NƠI DUY NHẤT reconcile test-design→test-exec (016 D9).

**Versioning (016):** doc test-exec KHÔNG mang `template_version`/`migrations` (structural — derived, ngoài `/artifact-audit`+`/artifact-migrate`). NHƯNG có **content-version** ở frontmatter: `version` (của doc, bump khi áp delta) + `test_design_version` (= `test-design.versions.{scope}` lúc reconcile). So `test-design.versions.{scope}` vs `test-exec.test_design_version` = GATE quyết định có reconcile scope đó không (D1/D2/D8).

## When to Use

- Một feature đã có `test-design.md` và cần sinh doc thực thi để bắt đầu một **chu kỳ test** (regression release, sprint test, UAT...).
- test-design.md vừa cập nhật (qua `/spec-test`) → cần một bundle thực thi mới phản ánh TC hiện tại.

## When NOT to Use

- Feature **chưa có** `test-design.md` → chạy `/spec-test` (qua integration) hoặc `/spec-test-design` (bootstrap) trước.
- Muốn **thêm/đổi TC** → KHÔNG sửa ở đây (test-exec chỉ đọc). Sửa test-design qua `/spec-test`, rồi sinh lại bundle.
- Chỉ muốn cập nhật **kết quả thực thi** (result / findings) → chạy skill tầng tương ứng (`/spec-test-retrofit-{validation,functional,e2e}`), **không** chạy lại skill này và **không** sửa tay file report: report chỉ do skill ghi (030 D22 — `Summary`, dòng `**Mục:**`, roll-up đều bị tính lại mỗi lượt, và người sửa tay không nâng pin). Result KHÔNG ghi vào doc test-exec.

---

## Process

### Bước 1: Xác định feature

`/spec-test-exec` thao tác trên **đúng một feature**.

**Nếu có ARGUMENT:**
- Parse: feature ID (`F-012`, `012`) hoặc slug (`F-012-bulk-import`, `bulk-import`).
- Quét `.specs/tests/*/test-design.md`, tìm feature khớp.
- Không khớp → báo lỗi:
  > Không tìm thấy feature có test-design.md khớp với "{argument}". Kiểm tra `.specs/tests/`.

**Nếu không có ARGUMENT:**

Quét `.specs/tests/`. Liệt kê features **có `test-design.md`**, đánh dấu bộ test-exec + bộ report đã có chưa:

```
Features có test-design.md:

  [1] F-012 — bulk-import   test-design: approved   test-exec: có (5 doc + 4 report + roll-up)
  [2] F-031 — checkout      test-design: draft       test-exec: chưa

Chọn số feature:
```

Không feature nào có test-design.md → dừng:
> Chưa có feature nào có test-design.md. Chạy `/spec-test` hoặc `/spec-test-design` trước.

---

### Bước 2: Gate check + phát hiện section điều kiện

Đọc `.specs/tests/{F-XXX}-{slug}/test-design.md`.

**Check 1 — test-design.md tồn tại:** nếu không → dừng (đã xử lý ở Bước 1).

**Check 2 — status (cảnh báo, KHÔNG block):**

Nếu `status` **không phải** `approved`:
> ⚠ `test-design.md` của **{F-XXX}** đang ở `status: {status}` (chưa approved — có thể còn placeholder TBD ở Test Data / Strategy / Out of Scope).
>
> Bundle sinh ra sẽ kế thừa các placeholder đó. Tiếp tục? (yes / no — default yes)

`no` → dừng, gợi ý approve test-design trước.

**Check 3 — đếm TC của cả 5 section: scope nào có TC thì sinh doc:**

Đọc **cả 5** section TC của test-design và đếm TC block (`### TC-F…`) / row bảng:
`## Validation Test Cases` · `## Functional Test Cases` · `## E2E Test Cases` · `## Non-Functional Test Cases` · `## Data & Migration Test Cases`.

**Một quy tắc cho cả 5 scope** (xem `02-artifacts.md` §4.2):
- Section có ≥1 TC → **sẽ sinh** `test-exec-{scope}.md`.
- Section **rỗng** (chỉ heading, không TC) → **BỎ QUA** doc đó.

⚠ **Không có scope nào "luôn sinh".** `e2e` cũng theo luật này: feature một story thường có **0 `FAC-*`** ⇒ 0 E2E TC ⇒ **không** sinh `test-exec-e2e.md`. Sinh file cho scope không có TC thì `[5b]` không tạo `test-report-e2e.md` cho nó (report chỉ cho scope **có** TC) ⇒ để lại một test-exec **mồ côi** không có nơi ghi result, và tầng retrofit tương ứng chạy vào một file rỗng. Cùng lý do cho `validation` (feature 0 `VR-*`) và `functional` (0 AC automatable).

Báo lại cho user:
```
test-design F-012:
  Validation TC: 12   Functional TC: 8   E2E TC: 3   NFR TC: 2   DM TC: 0
→ Sẽ sinh: validation, functional, e2e, nfr   (BỎ dm — section rỗng)
```

**Check 4 — đọc version + quyết định action per-scope (016 D8):**

Đọc `test-design.versions.{scope}` (frontmatter). Với mỗi scope sẽ sinh, kiểm tra `test-exec-{scope}.md` đã tồn tại chưa + đọc `test_design_version` của nó:

| Tình trạng scope | Action |
|---|---|
| `test-exec-{scope}.md` **chưa có** | **CREATE** — sinh fresh (Bước 5), `version=1`, `test_design_version = versions.{scope}` |
| Đã có, `test_design_version` **==** `versions.{scope}` | **NO-OP** — scope không đổi, bỏ qua (không đụng file) |
| Đã có, `test_design_version` **<** `versions.{scope}` | **RECONCILE** — áp delta wiring (Bước 4/5), bump `version`, cập nhật `test_design_version` |

Bootstrap: file cũ chưa có `test_design_version` → coi absent, ép RECONCILE (stamp lần đầu). test-design chưa có `versions` (chưa qua Phase A skill) → coi mọi scope = 1.

Báo action per-scope:
```
Scope action (F-012): validation RECONCILE (td v3 > exec v2) · functional NO-OP (v2==v2) · e2e CREATE · nfr CREATE
```

---

### Bước 3: Đảm bảo thư mục tests + reconcile (KHÔNG clobber)

**Thư mục test-side** `.specs/tests/{F-XXX}-{slug}/` — mirror tên `main/feature/{F-XXX}-{slug}/`, đã tồn tại sẵn (chứa `test-design.md` vừa đọc). **KHÔNG** còn tầng cycle bundle `{NNN}-{cycle}` — test-exec + report ghi **thẳng** vào thư mục này, mỗi loại **một file bền**.

**Reconcile, KHÔNG clobber (016):** scope action đã xác định ở Bước 2 Check 4.
- Scope **CREATE** → sinh fresh (Bước 5) như thường.
- Scope **NO-OP** → bỏ qua hoàn toàn (không đụng file, giữ nguyên result).
- Scope **RECONCILE** → áp **delta wiring** (Bước 4 §4b + Bước 5): chỉ thêm/xoá/sửa **dòng TC** trong `test-exec-{scope}.md`. **KHÔNG regenerate cả file**, và **KHÔNG đụng `test-report-*` / roll-up** (030 D23) — file report đã tồn tại thì để nguyên; pin đang tụt (`pin < version`) chính là tín hiệu scope stale.

> Không còn hỏi "ghi đè yes/no" — reconcile chỉ đụng wiring, không chạm result. Vẫn nên **commit** trước khi chạy (git là lưới an toàn chuẩn cho mọi thao tác `.specs/tests/`).

Nếu **toàn bộ** scope = NO-OP → báo "test-exec đã current với test-design" rồi **bỏ qua phần ghi test-exec**, nhưng **`[5b]` vẫn chạy**: scaffold file report còn thiếu + bù key `derived_from` thiếu ở roll-up.

⚠ **KHÔNG return sớm ở đây.** Bỏ qua `[5b]` sinh ra một trạng thái **không lệnh nào chữa được**: test-exec đủ nhưng thiếu một `test-report-{scope}.md` (bị xoá tay, hoặc scope đó vừa có TC ở lượt trước mà roll-up chưa biết) ⇒ gõ lại lệnh này lại rơi vào NO-OP rồi dừng, còn skill retrofit thì không tạo file report. Nó cũng va thẳng vào Red Flag của chính skill này: *"thư mục thiếu `test-report-{scope}.md` cho một scope có TC sau khi chạy → sai"*.

---

### Bước 4: Route TC → bucket + completeness check

**Đọc toàn bộ TC từ test-design**, gom theo section nguồn:

| Section test-design | Bucket scope | TC fields đọc được |
| --- | --- | --- |
| `## Validation Test Cases` | validation | TC ID, Covers VR, Field, Input, Expected, Polarity (**Autoable=YES** uniform) |
| `## Functional Test Cases` | functional | Type, **Autoable**, Priority, Covers AC, Scenario, Preconditions, Steps, Expected, Test data |
| `## E2E Test Cases` | e2e | Type (journey/consistency/integrity), Priority, Covers FAC, Spans, Preconditions, Steps, Expected |
| `## Non-Functional Test Cases` | nfr | Type, Priority, Covers NFR, Preconditions, Steps, Expected |
| `## Data & Migration Test Cases` | dm | Type, Priority, Covers DM, Preconditions, Steps, Expected |

**Route vào doc (1 scope → 1 doc):**

| Doc | Lấy TC nào |
| --- | --- |
| `test-exec-validation` | **TOÀN BỘ** Validation TC (neo VR; Autoable=YES uniform) |
| `test-exec-functional` | Functional TC (neo AC) có **`Autoable ∈ {YES, MAYBE}`** (automatable), gồm `fe:component`. TC `Autoable=NO` (visual) KHÔNG render — ở lại test-design |
| `test-exec-e2e` | **TOÀN BỘ** E2E TC |
| `test-exec-nfr` | Non-Functional TC *(bỏ doc nếu rỗng)* |
| `test-exec-dm` | Data & Migration TC *(bỏ doc nếu rỗng)* |

**Completeness check (BẮT BUỘC trước khi ghi):**
- Mỗi `TC-F*` **automatable** rơi **đúng 1 scope bucket** (validation/functional/e2e/nfr/dm) → **đúng 1 doc** — không lọt, không trùng.
- `test-exec-functional` chỉ nhận TC `Autoable=YES/MAYBE`. TC `Autoable=NO` là visual → **không** vào test-exec (không lọt, đó là đúng — chúng ở lại test-design). Validation/E2E/NFR/DM không lọc Autoable (đều render toàn bộ — Validation TC gần như luôn Autoable=YES).
- Lỗi (TC automatable không route được / TC thừa không có trong Matrix / section nguồn không parse được) → **dừng, báo cụ thể**, KHÔNG ghi bundle nửa vời.

**[4b] Delta cho scope RECONCILE (016 §5):** với scope action=RECONCILE, đọc `test-exec-{scope}.md` hiện có + so **từng TC** (theo TC ID) giữa test-design (section nguồn) và bảng Test Cases của test-exec:

| Delta | test-exec (wiring) | test-report-{scope} |
|---|---|---|
| **Added** — TC mới ở test-design | thêm dòng wiring (Test File placeholder `_Pending_`) | **không đụng** |
| **Removed** — TC biến mất khỏi test-design | xoá dòng wiring | **không đụng** |
| **Modified** — TC đổi nội dung (ID giữ) | cập nhật dòng wiring (Covers/assert/Steps…) | **không đụng** |
| **Unchanged** | giữ nguyên | **không đụng** |

- Chỉ đụng **wiring** của **test-exec** scope đó (định nghĩa dưới); **KHÔNG** regenerate phần khác của file, **KHÔNG** mở file report nào (030 D23 — retrofit dựng lại trọn report từ test-exec mỗi lượt, nên rows tự khớp; giữa hai lượt thì `pin < version` đã đánh dấu scope stale).
- Delta tính **live** (đọc 2 file so trực tiếp) — không cần hash.
**"Wiring" gồm những gì** — hẹp hơn "cả file", rộng hơn "chỉ dòng TC". TC mới thường kéo theo bề mặt mới (màn hình, fixture, lệnh chạy); bó đúng dòng TC thì phần còn lại của doc **mâu thuẫn với chính bảng TC vừa cập nhật**:

| Trong wiring (ĐƯỢC sửa) | Ngoài wiring (KHÔNG đụng) |
| --- | --- |
| dòng TC trong bảng Test Cases (thêm/xoá/sửa) | `Results` hay bất kỳ file report nào |
| Coverage table của scope đó | Traceability Matrix (master ở test-design) |
| **Layer / Environment** — giá trị mới mà TC mới cần | placeholder owner đã điền (Test File, POM path, locator) |
| **Fixtures / Test Data** — mục mới mà TC mới tham chiếu | `status`, `owner`, `method` |
| **`Out of Scope` + con trỏ cross-scope** — scope khác vừa ra đời thì câu "không có scope X" đã sai | prose thiết kế không liên quan tới TC vừa đổi |
| **lệnh chạy ở §Run** khi TC mới cần runner/tag khác | |

Nguyên tắc: sửa thứ **TC vừa đổi làm cho sai**, không sửa thứ chỉ vì "tiện tay". Mỗi mục ngoài dòng TC mà bạn chạm ⇒ ghi một dòng trong báo cáo cuối.

- Matrix: **KHÔNG** recompute ở đây (spec-test-exec đọc-xuống từ test-design, không chạm frd — chỉ tiêu thụ matrix có sẵn; 016 §5).

---

### Bước 5: Sinh doc (CREATE) hoặc áp delta (RECONCILE) + stamp version

Với mỗi doc cần sinh, copy từ `templates/tests/test-exec-{...}-template.md` rồi điền:

**Frontmatter (`02-artifacts.md` §4.5):**
- `id: test-exec-{scope}-{F-XXX}-{slug}` · `type: test-exec-{scope}` (`scope ∈ {validation, functional, e2e, nfr, dm}`) · `feature_id: {F-XXX}` · `status: draft`
- `test_design_ref: tests/{F-XXX}-{slug}/test-design.md` (từ `.specs/` root).
- Markdown link tới test-design trong body: cùng thư mục → `./test-design.md`.
- **KHÔNG** `alt_harness_*` (một doc/scope — không còn harness thay thế). **KHÔNG** `template_version`/`migrations`.
- **Version (016 D1):**
  - CREATE → `version: 1`, `test_design_version: {test-design.versions.{scope}}`.
  - RECONCILE → **bump `version` +1**, set `test_design_version = {test-design.versions.{scope}}` hiện tại (đóng gate cho lần sau).
  - NO-OP scope → không đụng (đã bỏ qua ở Bước 3).

**Inherit (đọc xuống — KHÔNG suy diễn lại):**
- `TC-F*` ID, `Covers`, `Type`, `Priority`, `Preconditions`, `Steps`, `Expected` → copy **nguyên văn** từ test-design vào bảng Coverage + Test Cases của doc.
- `Autoable` (functional) chỉ dùng làm **bộ lọc** khi đọc test-design (lấy YES/MAYBE) — **KHÔNG** ghi cột Autoable vào `test-exec-functional` (mọi TC ở đó đều automatable nên thừa). Validation TC không lọc Autoable (render toàn bộ).

**Testid cho doc automation (e2e + functional có UI):** quy ước tên + cách gắn/query theo platform, và **registry nào là nguồn thật**, ở [`references/testid-conventions.md`](../../references/testid-conventions.md) — đọc file đó trước, **KHÔNG** suy từ tên platform (§3: registry phụ thuộc harness e2e):

- **per-feature** (web-react): nguồn thật là `.specs/tests/{F-XXX}-{slug}/selector-contract.md` — **sổ đăng ký** mọi `data-testid` mà code đang có (`.docs/026`).

**Đường dẫn contract lấy từ `selector_contract_path` trong frontmatter `test-exec-e2e.md`** (mặc định per-feature như trên) — **KHÔNG hard-code**. Project mobile thường để contract ở repo root (`.maestro/selector-contract.md`) vì harness đọc đúng đường dẫn đó; "một contract / repo" là hình dạng **hợp lệ**, không phải sai lệch cần sửa.
- **global** (Maestro — flutter HOẶC react-native): nguồn thật là **một** file ở repo root (vd `.maestro/selector-contract.md`); file per-feature nếu có **chỉ reference subset**, không phải nguồn (§3). Identifier ở bucket **Reserved** (§5) là id đã gắn nhưng chưa flow nào dùng — không kéo vào POM/Flow Index ở đây.
- Cách query khác nhau theo platform: `getByTestId` (web-react / react-native) · **flutter: `find.bySemanticsIdentifier('<id>')` cho widget test, còn `Semantics(identifier:)` là thứ Maestro đọc — `Key` là namespace riêng của widget test, hai bên không thay nhau** (§2c).

Đọc contract ở **đúng** registry trên. Khi điền **POM index §7.1 của e2e** (và cột testid của `test-exec-functional` cho `fe:component` test): dùng **đúng** testid handle trong contract. **KHÔNG tự đặt testid mới** ở đây (lệch nguồn → vỡ "một-nguồn-hai-bên-đọc"). Biểu thức locator `getByTestId(...)` + file POM `.ts` vẫn do owner viết ở source tree. Feature không có selector-contract → để placeholder + note "feature chưa có selector-contract" (contract ra đời ở `/build` hoặc skill retrofit).

**Điền cột `TC` — việc của skill này (`.docs/026` D5).** Cột `TC` là **annotation**: `/build` để rỗng vì nó không biết TC nào tồn tại; skill này thì biết. Mỗi testid được một TC dùng ⇒ **thêm TC ID đó vào row** của testid ấy, **merge** (không clobber giá trị đã có, không xoá TC của lượt trước). Đây là **ngoại lệ có chủ ý** của luật read-down: skill này ghi vào contract **đúng một cột annotation**, không đụng row/testid/Element/Interaction, không thêm hay xoá row.

Row còn `TC` rỗng sau khi điền = **chưa TC nào dùng testid đó** → gom vào **báo cáo** cuối (không phải lỗi, không block): đầu vào để QC bổ sung TC, hoặc để DEV dọn testid chết.

**Bốn phép kiểm trước khi điền POM:**
- **Hình dạng contract** — `template_version` của contract lệch với `.claude/templates/tests/selector-contract-template.md` ⇒ file đang ở hình dạng cũ → **báo** (nêu version cũ/mới + việc cần làm), KHÔNG tự nâng cấp: transformer nằm ở 3 writer (`/build` + 2 retrofit), là những skill chạm code (`.docs/024` D18). POM vẫn điền được từ cột testid — cột này không đổi qua các version.
- `contract ⊆ code` — mỗi testid trong contract phải grep được trong source (`data-testid="{id}"`; testid động thì kiểm token). Thiếu → **báo**, KHÔNG tự đặt testid thay thế.
- `code ⊆ contract` — **chỉ áp khi contract là registry-of-all**, tức bảng chính khai mọi identifier có trong code. Thiếu → **báo** (nêu testid + file:line), KHÔNG tự thêm row: row là việc của writer chạm code. Chiều này trước bị cấm áp (024 D14), nay là luật — nó bắt được testid `/build` gắn mà quên đăng ký.

  ⚠ **KHÔNG áp chiều này cho contract registry-of-used.** Nhánh global (Maestro) có bucket **`Reserved`**: identifier đã gắn trong code nhưng **chưa flow nào dùng** nằm ở bullet list, **cố ý không** ở bảng chính, để harness đối chiếu hai chiều không tính chúng là "id chết" (`references/testid-conventions.md` §5). Với hình dạng đó, "identifier trong code mà không có row" là **đúng thiết kế**, không phải thiếu sót — áp `code ⊆ contract` sẽ đẻ ra hàng trăm cảnh báo giả (đo thật ở F-001 GAL-Mobile: **130** identifier). Nhận biết: contract có mục `Reserved`, hoặc tự khai bảng chính = "những gì flow đang dùng". Khi đó kiểm chiều **`flow ⊆ contract`** thay thế — mọi identifier một flow dùng phải có row — đúng chiều mà harness của project đang gác.

  Bảng đầy đủ hai hình dạng + phép kiểm hợp với mỗi hình dạng: `references/testid-conventions.md` §3c. Hai luật cần nhớ: **`flow ⊆ contract` đúng ở cả hai hình dạng** (đây là cái bắt lỗi thật), và **`contract ⊆ flow` ("id chết") KHÔNG được suy ra từ tập flow khi contract là registry-of-all** — phần lớn handle chỉ widget test dùng, bật lên là đỏ toàn bộ (đo thật: 188 handle đã khai).
- **TC dangling** — row có cột `TC` trỏ TC không còn trong `test-design.md` (BA gỡ AC/VR khỏi frd → `/spec-test` `[REMOVE]`) → **báo**, KHÔNG tự xoá row: element có thể vẫn đúng, chỉ TC đổi.

> ⚠ **Cột `TC` là TUỲ CHỌN — không có thì thôi, KHÔNG thêm cột.** Contract của project có thể chỉ mang 3 cột (`Identifier | Widget | File`) và harness của họ **regex-check đúng hình dạng đó** (vd `tool/e2e.sh` khớp `^| \`id\``); thêm cột là **làm vỡ check của project**. Luật: skill **không bao giờ đổi số cột** của contract. Contract không có cột `TC` ⇒ bỏ qua bước điền `TC` và **báo một dòng** ("contract không có cột TC — bỏ qua annotation"), không coi là lỗi, không tự thêm.

**Placeholder cho owner điền khi chạy** (KHÔNG tự bịa):
- **Test File / POM file path + biểu thức locator** → `_Pending — {owner}_` (sống ở source tree). *(Testid handle thì đã có từ selector-contract — xem trên, không để trống.)*
- **Tool / Command / Layer** (nfr/auto) → gợi ý theo Type nếu suy được (vd NFR performance → `k6`), còn lại để placeholder.
- Account/Role matrix, Env tiers, Seed, Fixtures → giữ skeleton template để owner điền theo môi trường.
- **KHÔNG có cột result trong test-exec** — kết quả chạy sống ở `test-report-{scope}.md` (xem [5b]).

**TC không runner nào chạy được → Layer `out-of-runner`.** TC automatable (`Autoable=YES/MAYBE`) mà mọi runner của scope đều bất lực — cần build release trên thiết bị thật, trace cold-start, đo p90 ngoài process test. Vẫn **render dòng TC** (bỏ đi là lọt completeness), `Layer: out-of-runner`, Test File `_Pending_`, và **mở sẵn một `BLK-{SCOPE}-N`** trong `test-report-{scope}.md` lúc scaffold nêu hạ tầng còn thiếu. Phân biệt: `Autoable=NO` = oracle **không** lập trình được (visual) — ở lại test-design, không xuống đây; `out-of-runner` = oracle lập trình được nhưng **chưa có chỗ chạy**.

**Coverage tables:** điền từ Traceability Matrix (AC/VR/FAC/NFR/DM → TC IDs) — KHÔNG dựng matrix cạnh tranh; coverage master vẫn ở test-design.

**[5b] Bộ report** — `test-report-{scope}.md` (một file / scope có TC) + `test-report.md` (roll-up). Skill này **chỉ TẠO file lần đầu**, sau đó **không đụng nữa** (030 D23): mỗi report có đúng **một** writer, và writer đó là skill tầng retrofit.

**Với mỗi scope CÓ TC, nếu `test-report-{scope}.md` CHƯA có** — copy `templates/tests/test-report-scope-template.md` (một template dùng chung cho cả 5 scope):
- Frontmatter: `id: test-report-{scope}-{F-XXX}-{slug}` · `type: test-report-{scope}` · `feature_id` · `scope` · `mode: cycle` (skill tầng đổi thành `retrofit` khi ghi) · `test_design_ref` · `test_exec_ref: tests/{F-XXX}-{slug}/test-exec-{scope}.md` · `date` = hôm nay · `status: draft`. **KHÔNG** `template_version`.
- **Pin `test_exec_version: 0`** — **một số**, không phải map (030 D2). `0` = chưa chạy; retrofit nâng lên `= test-exec.version` sau khi chạy xong cả scope.
- Thay 2 chỗ scope-specific của template: `scope` và **trụ neo** ở bảng `Coverage` (`VR` / `Story AC` / `FAC` / `NFR` / `DM`). Tiền tố ID theo scope: `FIND-{VAL│FUN│E2E│NFR│DM}-NN` · `BLK-{SCOPE}-N` · `A-{SCOPE}-N`.
- **Giữ nguyên legend của cả 5 section** (`Summary` ký hiệu result · `Findings` 4 verdict + `dup-of` · `Blockers` hai cột diễn giải · `Results` 3 cột sanity-red + 4 action tag + tier · `Next Actions` `🤖`/`👤`) — scaffold sinh **sẵn legend** để skill tầng không phải tự nhớ (030 DS9).
- **`Results` để RỖNG** (chỉ header bảng): **không** pre-fill dòng TC. Skill tầng lấy danh sách TC thẳng từ `test-exec-{scope}.md` và dựng lại trọn bảng mỗi lượt (030 D23) ⇒ chèn trước là tạo writer thứ hai cho cùng một file.
- `Summary`: `Tổng TC` = **số row bảng `Test Cases` của `test-exec-{scope}.md`** (mẫu số của scope) và cột `—` *(not-run)* = **cùng số đó**, 4 ô còn lại `0` — invariant *"5 ô cộng lại = `Tổng TC`"* vẫn đúng, và roll-up đọc ra **cùng một số** cho cùng một tên cột. **KHÔNG** ghi `Tổng TC = 0` vì §4 `Results` đang rỗng: lúc đó roll-up nói scope có 11 TC chờ chạy mà file scope nói 0. `Coverage` `Tổng` = `Y` từ Traceability Matrix và `Covered` = 0; `Findings`/`Blockers`/`Next Actions` rỗng; dòng `**Mục:**` đếm `0`.
- **`nfr`/`dm`:** tạo y như 3 scope kia — nhưng **chưa có skill nào ghi result**, nên file cứ ở trạng thái not-run + pin `0` (030 D22). KHÔNG mở lối sửa tay để lấp tạm.

**Roll-up cũ sinh từ kit trước 030** — `test-report.md` đã tồn tại nhưng **thiếu `derived_from`** ⇒ đó là hình dạng cũ, không phải roll-up derive. D23 ("file đã có thì không đụng") mà áp cứng ở đây thì file stale nằm lại **vĩnh viễn**, không skill nào được sửa. Ngoại lệ hẹp: roll-up **không giữ dữ kiện riêng nào** (mọi số derive từ `test-report-{scope}.md`) nên dựng lại **không mất gì**. Luật: `test-report.md` tồn tại mà **không có `derived_from`** ⇒ **dựng lại trọn như trường hợp CHƯA có**, và báo một dòng `roll-up hình dạng trước-030 → đã dựng lại`. Roll-up **có** `derived_from` ⇒ giữ nguyên D23, không đụng.

**Nếu `test-report.md` (roll-up) CHƯA có** — copy `templates/tests/test-report-template.md`:
- Frontmatter: `id: test-report-{F-XXX}-{slug}` · `type: test-report` · `feature_id` · `test_design_ref` · `date` · `status: draft`. **KHÔNG** `mode`, **KHÔNG** `template_version`.
- `derived_from.{scope}` = `{file, test_exec_version: 0, date}` cho **mọi scope có TC**.
- §1 một dòng / scope có TC: link file · pin `v0` + `(chưa chạy)` · `Tổng TC` **đọc từ bảng `Test Cases` của `test-exec-{scope}.md`** (§4 ở validation/functional, **§5** ở e2e) — mẫu số của scope, tức bảng TC mà skill này vừa ghi (031 D15; KHÔNG lấy của `test-design.md`: nó đếm cả TC `Autoable = NO`) · counts còn lại `0` trừ cột `—` = `Tổng TC`. §2 `Coverage` `Tổng` từ Matrix, `Covered` = 0. §3 rỗng.

**Nếu `test-report-{scope}.md` ĐÃ có** → **bỏ qua hoàn toàn**, kể cả khi scope đang RECONCILE (030 D23). Không mở, không áp delta, không nâng/hạ pin. Pin đang tụt sau khi `test-exec.version` bump chính là tín hiệu scope stale cho retrofit (016 D7/D8).

**Nếu `test-report.md` (roll-up) ĐÃ có** → **bù key `derived_from` thiếu**, không bỏ qua hoàn toàn:

- Với mỗi scope **có TC** mà `derived_from.{scope}` **chưa có mặt**: thêm key `{file, test_exec_version: 0, date}` + một dòng §1 tương ứng (link file · pin `v0` + `(chưa chạy)` · `Tổng TC` đọc từ bảng `Test Cases` của `test-exec-{scope}.md`, counts còn lại `0` trừ cột `—` = `Tổng TC`) + cộng `Tổng` của scope đó vào §2 `Coverage`.
- Key đã có mặt → **không đụng**: pin/counts của nó là của writer tầng, không phải của skill này.
- Không scope nào thiếu key → không đụng file.

⚠ **Vì sao không "bỏ qua hoàn toàn" như file scope:** feature về sau mới có TC `nfr` đầu tiên thì roll-up **vĩnh viễn** thiếu key `derived_from.nfr` — mà `nfr` **không có writer nào** dựng lại roll-up (030 D22), nên không lượt chạy nào bù được. `F-002` che lỗ này vì nó đủ 5 key sẵn từ lượt tạo đầu.

Hiển thị **tóm tắt bundle** (không dump toàn bộ) cho user xem trước khi ghi:
```
tests/F-012-bulk-import/ — sẽ ghi 4 doc test-exec:
  validation : 12 TC
  functional : 6 TC automatable (2 TC Autoable=NO ở lại test-design, không render)
  e2e        : 3 TC
  nfr        : 2 TC
  (dm: bỏ — rỗng)
  report: tạo mới 4 file test-report-{validation,functional,e2e,nfr}.md (pin 0, Results rỗng)
          + test-report.md roll-up (4 dòng, đều "chưa chạy", Tổng TC = 23 từ bảng Test Cases của test-exec)
Completeness: 23/23 TC automatable ở Traceability Matrix đều routed ✓ (2 visual TC không thuộc test-exec)
```

---

### Bước 6: Ghi bundle + báo cáo

**[6.1]** Ghi vào `.specs/tests/{F-XXX}-{slug}/` (thư mục đã có, chứa test-design) từng doc test-exec **+ các file report còn thiếu** (tất cả status `draft`). test-exec: CREATE → ghi file mới; RECONCILE → ghi lại file đã áp delta wiring; NO-OP → không đụng. Report: chỉ ghi file **chưa tồn tại**; file đã có → không đụng (030 D23).

**[6.2]** KHÔNG cascade, KHÔNG đụng test-design (đọc-xuống one-way). KHÔNG ghi Change History vào test-design (test-exec không phải nguồn cascade).

**[6.3] Báo cáo:**
```
✓ .specs/tests/F-012-bulk-import/ (từ test-design.md)
  ✓ test-exec-validation.md — 12 TC (VR, pos + neg)
  ✓ test-exec-functional.md — 6 TC automatable (2 visual TC ở lại test-design)
  ✓ test-exec-e2e.md        — 3 TC
  ✓ test-exec-nfr.md        — 2 TC
  ✓ test-report-validation.md · -functional.md · -e2e.md · -nfr.md — tạo mới, pin v0, Results rỗng
  ✓ test-report.md          — roll-up, 4 dòng scope đều "chưa chạy", Tổng TC 23 (từ bảng Test Cases của test-exec)
  (dm bỏ qua — test-design Data & Migration rỗng)

Bước tiếp theo (100% automation):
  - validation: DEV viết test cho VR (unit/api, mỗi VR ≥1 pos + ≥1 neg).
  - functional: DEV viết test cho Story AC ở tier rẻ nhất (`be:*` / `fe:unit` / `fe:component`).
  - e2e:  DEV viết Playwright (web) hoặc Maestro flow (mobile) cho toàn bộ E2E TC.
  - nfr:  DEV chạy bằng tool tương ứng.
  - Điền Test File / POM trong test-exec khi implement.
  - Ghi result: chạy `/spec-test-retrofit-{validation,functional,e2e}` — mỗi skill dựng lại `test-report-{scope}.md` của nó rồi sinh lại roll-up, KHÔNG ghi vào test-exec, KHÔNG sửa tay report. Xong mỗi tầng thì **commit** (git = change history của tests/*).
  - nfr/dm: chưa có skill ghi result — file report của hai scope này ở lại trạng thái not-run.
```

---

## Đơn vị tiến độ

Sổ của skill này: `.specs/tests/{F-XXX}-{slug}/.progress/exec.md` — **writer duy nhất là skill này**; KHÔNG đọc, KHÔNG ghi sổ của skill khác. Dựng lại **trọn** sổ mỗi lượt rồi ghi đè: nội dung derive từ artifact nên một ô sửa tay bị ghi đè ở lượt sau, và không bao giờ nói dối được. Hình dạng + frontmatter: `templates/tests/verify-progress-template.md`; định nghĩa thư mục: `02-artifacts.md` §4.7.

**Hạt là scope**, cộng 2 dòng cuối lượt. `[x]` nghĩa là *"đã có bản ghi"*, không phải *"xanh"*.

**Việc lớn** — `- [ ] /spec-test-exec` — tick khi **mọi** dòng việc nhỏ tick.

| Việc nhỏ | Đọc file / field | Xong khi |
|---|---|---|
| `{scope}  td {a} → exec tdv {b} · rows {k}/{N}` — 1 dòng / scope **có TC** | `test-design.md` `versions.{scope}` vs `test-exec-{scope}.md` `test_design_version`; `k` = số row bảng `Test Cases` của test-exec (§4 ở validation/functional, §5 ở e2e), `N` = số TC của section nguồn (`functional` lọc `Autoable ∈ {YES,MAYBE}`) | `a == b` **và** `k == N` |
| `scaffold report {m}/{M} scope có TC` — 1 dòng | với mỗi scope có TC: `test-report-{scope}.md` tồn tại, có 5 section, `test_exec_version` là **một số** | đủ file cho **mọi** scope có TC |
| `roll-up · derived_from khớp {M} scope` — 1 dòng | `test-report.md` tồn tại **và** tập key `derived_from.*` == tập scope có TC | hai tập bằng nhau |

**Payload của một dòng là ĐÚNG nhãn ở cột "Việc nhỏ", không thêm chữ tự do.** Chữ kèm thêm không derive từ field nào là chỗ sổ nói dối được: lượt nghiệm thu 2026-09-10 đo được một dòng `scaffold report` mang hậu tố `pin 0 · Results rỗng` — đúng lúc ghi thì đúng, nhưng sau ba tầng retrofit thì pin đã `1` và `Results` đã đầy, mà chữ đó không có nguồn nào để derive lại. Hai lượt cùng input mà ra hai byte khác nhau cũng từ đây.

**Vì sao 2 dòng cuối tách riêng:** chúng ghi ở **một lượt khác** (Bước `[5b]`, sau khi mọi scope xong), nguồn derive khác (sự tồn tại của file, không phải cặp version), và mỗi cái bắt đúng một trạng thái nửa vời riêng.

**Phép đếm `rows` là thứ bắt được file ghi dở:** cặp version nói "xong" trong khi delta wiring áp dở — `version` đã bump nhưng thiếu/thừa row.

**`nfr` / `dm`:** có TC ⇒ **có dòng bình thường** ở hai đơn vị đầu, kèm hậu tố `(chưa có writer)`. Section rỗng ⇒ **không có dòng nào** (không phải `0/0`). **Cấm tuyệt đối đọc pin của `nfr`/`dm`** ở bất cứ dòng nào — pin `0` là trạng thái đúng cho tới khi có writer (030 D22), lấy nó làm điều kiện tick thì không lượt nào hoàn tất.

**Cấm đưa vào sổ:**

- Nhãn `CREATE` / `NO-OP` / `RECONCILE` làm nguồn tick — nó **tự sửa lịch sử**: CREATE xong, refresh derive lại ra `NO-OP`. Ba số `td` / `tdv` / `rows` thì đúng ở mọi thời điểm.
- `test-exec-{scope}.version` (số đó là của skill retrofit, không phải của skill này) · một dòng / TC · 4 phép kiểm contract · điền cột `TC` của `selector-contract.md` (row `TC` rỗng là **output hợp lệ**, 026 D4) · placeholder `_Pending — {owner}_`.
- Dòng `step=` — biên bản là của orchestrator, không của skill này.

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Thêm TC ngay trong bundle cho nhanh" | test-exec chỉ đọc xuống. TC mới phải vào test-design trước (qua `/spec-test`) rồi sinh lại — nếu không sẽ vỡ traceability + ID authority. |
| "Đổi TC ID cho gọn lại" | ID `TC-F*` do test-design làm chủ, stable. Renumber ở đây phá liên kết với test code + Traceability Matrix. |
| "Auto chạy pass hết là xong" | TC visual (Autoable=NO) không thuộc test-exec — chúng ở lại test-design, team kiểm ad-hoc. "Auto pass" chỉ nói về phần automatable. |
| "Cho TC visual vào functional luôn cho đủ" | KHÔNG. test-exec-functional CHỈ chứa automatable (Autoable=YES/MAYBE). TC visual ở lại test-design — không render xuống. |
| "Gộp Validation với Functional vào một doc cho gọn" | KHÔNG. Validation (pos/neg trên VR) và Functional (Given-When-Then trên AC) là hai loại TC + hai hình dạng — mỗi loại một doc để skill tầng retrofit sở hữu đúng một file. |
| "Sinh thiếu vài doc cho nhanh" | Sinh hết (tối đa 5 test-exec: validation/functional/e2e/nfr/dm; bỏ nfr/dm nếu rỗng) + một `test-report-{scope}.md` cho **mỗi scope có TC** + roll-up. Thiếu = lọt scope. |
| "Ghi result / status vào doc test-exec cho gần" | KHÔNG. test-exec = spec của test code, không chứa result. Pass/fail + Findings ghi ở `test-report-{scope}.md`, do skill tầng ghi. Hai nơi giữ result = drift. |
| "Bỏ qua test-report cho nhanh" | Mỗi scope có TC **luôn** có file report + feature luôn có roll-up. Không có chúng thì không có nơi hợp lệ để ghi kết quả chạy. |
| "Pre-fill sẵn dòng TC vào Results cho retrofit đỡ việc" | KHÔNG (030 D23). Retrofit dựng lại trọn bảng từ test-exec mỗi lượt ⇒ rows tự khớp; chèn trước là biến report thành file hai writer — đúng thứ 030 xoá bỏ. |
| "Chạy lại là mất result cũ, thôi đừng chạy" | KHÔNG còn đúng (016 + 030): chạy lại = **reconcile wiring của test-exec**, và skill này **không mở file report** nào. Result không thể mất ở đây. Cứ chạy lại an toàn. |
| "Reconcile xong nâng luôn pin cho gọn" | KHÔNG. spec-test-exec chỉ bump `test-exec.version` (báo scope đổi); **retrofit** mới nâng `test_exec_version` pin sau khi chạy lại cả scope. spec-test-exec nâng pin = che mất tín hiệu stale. |

## Red Flags

- Có `TC-F*` **automatable** ở test-design Traceability Matrix nhưng không xuất hiện ở doc nào → completeness fail (lọt).
- Một `TC-F*` rơi vào >1 scope bucket (vd vừa functional vừa e2e) → routing bug.
- Validation TC lọt vào `test-exec-functional` (hoặc ngược lại) → routing bug: Validation TC neo VR → `test-exec-validation`; Functional TC neo AC → `test-exec-functional`.
- `test-exec-functional` chứa TC `Autoable=NO` hoặc có cột Autoable/manual-verify → sai: functional chỉ nhận automatable, TC visual ở lại test-design.
- Sinh doc `-manual`/`-auto` hoặc frontmatter còn `alt_harness_*` → sai (đã bỏ phân biệt harness, 1 scope = 1 doc).
- Doc test-exec mang `template_version`/`migrations` → sai (structural non-versioned). NHƯNG **phải** có `version` + `test_design_version` (content-version 016) — thiếu = sai.
- RECONCILE mà mở/ghi **bất kỳ** file `test-report*` → sai (030 D23): reconcile chỉ đụng wiring của test-exec.
- spec-test-exec **nâng pin** `test_exec_version` → sai: chỉ bump `test-exec.version`; pin do retrofit nâng.
- RECONCILE mà quên bump `test-exec.version` hoặc quên cập nhật `test_design_version` → gate lần sau sai.
- Doc test-exec có cột result/status (Test Result / Status (CI)) → sai: result chỉ ở test-report.
- Thư mục `tests/{F}/` thiếu `test-report-{scope}.md` cho một scope **có TC**, hoặc thiếu roll-up `test-report.md`, sau khi chạy → sai.
- **Toàn bộ scope NO-OP rồi return sớm, bỏ qua `[5b]`** → sai (Bước 3): trạng thái "test-exec đủ, report thiếu" thành **không lệnh nào chữa được** — gõ lại lệnh này lại rơi vào NO-OP rồi dừng, còn retrofit thì không tạo file report.
- **Roll-up đã tồn tại thì "bỏ qua hoàn toàn"** → sai (`[5b]`): scope mới có TC lần đầu (điển hình `nfr`) sẽ **vĩnh viễn** thiếu key `derived_from.{scope}`, mà `nfr`/`dm` không có writer nào dựng lại roll-up. Phải **bù key thiếu**; key đã có thì không đụng.
- Ghi đè file report **đã tồn tại** (kể cả "cho khớp TC mới") → sai: file đã có thì bỏ qua (030 D23); writer của nó là skill tầng.
- Pre-fill dòng TC vào `Results` của report → sai: `Results` scaffold để **rỗng**; retrofit dựng lại trọn bảng từ test-exec.
- Pin `test_exec_version` ghi thành một map gom cả 5 scope → sai: pin là **một số**, sống trong từng file scope (030 D2).
- Scaffold report thêm section/nội dung ngoài template (Change History/timeline/run-log, blockquote narrative, đoạn văn trần) → sai: file scope dựng **đúng** 5 section (`Summary · Findings · Blockers · Results · Next Actions`), roll-up đúng 3 bảng (`Trạng thái theo scope · Coverage · Action Items`), không hơn. Lịch sử = git.
- Scaffold report mà **bỏ legend** của section → sai: legend sinh sẵn từ scaffold để skill tầng không phải tự nhớ (030 DS9).
- Sinh tầng con `{NNN}-{cycle}/` hoặc gắn `{NNN}`/cycle-slug vào id → sai: đã bỏ chiều per-cycle, ghi thẳng vào `tests/{F}/`, 1 file bền/loại.
- Bịa result / Locators / Tool thay vì để placeholder (result mặc định not-run `—`).
- Sửa test-design trong lúc chạy skill (skill này read-only với test-design).

## Verification

Trước khi ghi bundle:

- [ ] Đúng một feature; test-design.md tồn tại (cảnh báo nếu draft, không block).
- [ ] **Mọi** scope: chỉ sinh `test-exec-{scope}.md` khi section nguồn **có TC**; rỗng → bỏ doc. Không scope nào "luôn sinh" — `e2e` của feature 0 FAC cũng bị bỏ (Bước 2 Check 3).
- [ ] Ghi thẳng vào `.specs/tests/{F-XXX}-{slug}/` (mirror main/feature); KHÔNG tầng `{NNN}-{cycle}`; bộ cũ tồn tại → reconcile (không clobber).
- [ ] Route đúng: validation ← Validation (toàn bộ); functional ← Functional (chỉ Autoable=YES/MAYBE); e2e ← E2E (toàn bộ); nfr ← Non-Functional; dm ← Data & Migration. Mỗi scope = **1 doc** (không manual/auto).
- [ ] **Completeness**: mọi `TC-F*` **automatable** ở Traceability Matrix routed đúng 1 scope bucket — không lọt/trùng. TC visual (Autoable=NO) không thuộc test-exec (đúng, ở lại test-design).
- [ ] `test-exec-functional` KHÔNG có cột Autoable, KHÔNG chứa TC Autoable=NO; Validation TC nằm ở `test-exec-validation` (không lẫn vào functional).
- [ ] Inherit `TC-F*` + fields nguyên văn; KHÔNG ID mới, KHÔNG renumber.
- [ ] Frontmatter: `id/type/feature_id/test_design_ref` đúng; KHÔNG `alt_harness_*`, KHÔNG `template_version`; **CÓ `version` + `test_design_version`** (CREATE=1/versions.{scope}; RECONCILE=bump/cập nhật).
- [ ] Per-scope action đúng (Bước 2 Check 4): CREATE fresh / NO-OP skip / RECONCILE áp delta wiring — không xoá gì, và không mở file report nào.
- [ ] Toàn bộ scope NO-OP: `[5b]` **vẫn chạy** — file report thiếu được sinh lại, key `derived_from` thiếu ở roll-up được bù; không return sớm ở Bước 3.
- [ ] Roll-up: mỗi scope **có TC** đều có key `derived_from.{scope}` + một dòng §1; key đã tồn tại **không đổi một byte** (pin/counts của nó là của writer tầng).
- [ ] Đã ghi lại `.progress/exec.md` theo section `## Đơn vị tiến độ`: một dòng / scope có TC + 2 dòng cuối lượt; `nfr`/`dm` có TC mang hậu tố `(chưa có writer)`; **không** đọc pin của chúng; scope không có TC → không có dòng nào.
- [ ] RECONCILE: delta wiring theo [4b] (Added/Removed/Modified/Unchanged) **chỉ trong test-exec**; `git diff` sau lượt chạy không có dòng nào ở `test-report*`.
- [ ] Biểu thức locator + file POM = placeholder, không bịa. Doc test-exec KHÔNG có cột result/status.
- [ ] Doc automation (e2e, functional có UI): testid trong POM §7.1 / cột testid lấy từ **đúng registry** theo `references/testid-conventions.md` §3 (per-feature với web-react · **global** với Maestro/flutter/RN; không kéo id `Reserved` vào), KHÔNG tự đặt testid mới; feature thiếu contract → placeholder + note.
- [ ] Đã **điền cột `TC`** vào contract cho mọi testid mà TC của lượt này dùng (merge, không clobber); row còn rỗng đã vào báo cáo cuối (`.docs/026` D5).
- [ ] Đã chạy bốn phép kiểm contract: hình dạng (`template_version` khớp template), `contract ⊆ code`, `code ⊆ contract` (`.docs/026` D6), TC dangling (cột `TC` trỏ TC còn tồn tại trong test-design). Lệch → **báo**, KHÔNG tự sửa contract (trừ cột `TC` — xem trên).
- [ ] Report: mỗi scope **có TC** đã có `test-report-{scope}.md` (5 section + legend đủ, `Results` **rỗng**, pin `test_exec_version: 0` dạng **một số**, `mode: cycle`) + roll-up `test-report.md` (3 bảng, `derived_from` đủ scope, `Tổng TC` từ bảng `Test Cases` của `test-exec-{scope}.md`). File đã tồn tại → **không đụng**. KHÔNG `template_version`.

Sau khi ghi:

- [ ] Bộ tại `.specs/tests/{F-XXX}-{slug}/` với tối đa 5 doc test-exec + 1 report / scope có TC + 1 roll-up, status `draft`.
- [ ] Result chỉ nằm ở `test-report-{scope}.md`; doc test-exec không có ô result; roll-up không giữ dữ kiện riêng.
- [ ] KHÔNG đụng test-design (one-way đọc xuống, không cascade, không Change History).
