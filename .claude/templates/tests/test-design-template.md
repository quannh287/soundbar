---
id: test-design-{feature}
type: test-design
status: draft
owner: "{QC}"
feature_id: "{Feature ID — match frd.md}"
frd_ref: "main/feature/{F-XXX}-{slug}/frd.md"
versions:            # 016: content-version RIÊNG mỗi scope (section TC); auto-bump bởi skill ghi test-design, CHỈ bump section thật sự đổi. Chỉ scope CÓ TC mới có entry. KHÁC template_version (structural).
  validation: 1
  functional: 1
  e2e: 1
  # nfr: 1           # thêm khi Non-Functional Test Cases có TC
  # dm: 1            # thêm khi Data & Migration Test Cases có TC
id_counters:          # 018 D13: high-water-mark cấp ID, CHỈ TĂNG — next = counter + 1. Cùng cơ chế main artifact (01-architecture §7).
  ts: 0               # TS đã cấp tới đâu; ID retire KHÔNG hạ counter, KHÔNG tái dụng
  tc: 0               # TC đã cấp tới đâu (chung sequence cho mọi bucket)
template_version: 5
migrations:
  - to: 1
    note: "baseline"
  - to: 2
    note: "Mirror frd v2 + trim execution-leakage (giữ vai WHAT). Tách 'Feature AC Test Cases' (v1) theo type/execution-mode: đổi tên → 'E2E Test Cases' (chỉ FAC end-to-end: journey/consistency/integrity), tách TC loại NFR → 'Non-Functional Test Cases' và loại data/migration → 'Data & Migration Test Cases', cả hai required-emptyable. TC giữ prefix TC-F* chung sequence."
    add: ["E2E Test Cases", "Non-Functional Test Cases", "Data & Migration Test Cases"]
    remove:
      - { section: "Feature AC Test Cases", reason: "đổi tên → 'E2E Test Cases' (chỉ cover FAC end-to-end) + tách TC Type=NFR → 'Non-Functional Test Cases' (required-emptyable), Type=data/migration → 'Data & Migration Test Cases' (required-emptyable); carry-over toàn bộ TC theo field Type, không mất nội dung" }
      - { section: "Test Strategy > Environments", reason: "env assignment/scheduling là execution concern — design chỉ cần env requirement ở per-TC Preconditions" }
    update:
      - { section: "Test Data", change: "đổi thành 'Test Data Requirements' — bỏ cột Nguồn (fixture/factory = provisioning) + Refresh (cadence = execution), thêm cột 'Yêu cầu data (shape)'" }
  - to: 3
    note: "Thêm field Autoable (YES/MAYBE/NO) cho TC — test-design là SOURCE OF TRUTH route TC vào func-auto (YES/MAYBE) vs func-manual (toàn bộ + NO); hai track chỉ đọc, không tự quyết. Phân loại theo oracle của Expected: lập trình được (giá trị/state/record/HTTP/message/route)=YES, lập trình được nhưng setup nặng=MAYBE, visual (màu/layout/icon/animation)=NO. Mọi Validation TC = YES theo định nghĩa (không cần cột riêng)."
    update:
      - { section: "Functional Test Cases", change: "thêm field 'Autoable' (YES/MAYBE/NO) vào mỗi TC block + rule phân loại theo oracle ở đầu section" }
      - { section: "Validation Test Cases", change: "ghi rõ mọi VR-derived TC = Autoable=YES (uniform, không thêm cột)" }
  - to: 4
    note: "018 — (A) derive 1:1 xuống thành SÀN, kỹ thuật ISTQB (EP/BVA/DT/ST/UC/EG/PW) là hệ số nhân theo cấu trúc frd item. Thêm field Technique để review được: VR có ngưỡng mà thiếu dòng BVA lộ ngay. Chỉ Validation (cột) + Functional (field) mang Technique — E2E luôn UC, NFR/DM ngoài phạm vi bảng trigger nên ghi prose, không thêm field (cột hằng số không mang thông tin). Luật derive đầy đủ ở references/test-design-techniques.md. (B) Thêm field Key = {frd-item-id}::{TECHNIQUE}::{case-slug} làm khoá ghép cho mode reconcile của /spec-test-design: chạy lại thì TC khớp Key giữ nguyên ID, Key mới cấp ID từ id_counters, Key cũ mất thì hỏi QC rồi retire. Key TẤT ĐỊNH (không phụ thuộc prose Title/Steps) nên QC sửa câu chữ không làm vỡ ID. Thêm frontmatter id_counters {ts, tc} high-water-mark chỉ tăng. TC có Key bắt đầu manual:: là do QC thêm tay — skill KHÔNG đụng."
    update:
      - { section: "Validation Test Cases", change: "thêm cột 'Technique' vào bảng TC + luật: TC từ ST dùng đúng bảng Validation (Field=field của VR, Input={state} + {event}); chỉ DT nhiều field mới viết dạng block, và block phải lộ đủ TC ID/Covers/Field/Input/Expected/Polarity để /spec-test-exec route được" }
      - { section: "Functional Test Cases", change: "thêm field 'Technique' vào bảng meta mỗi TC block, cạnh Type/Autoable" }
      - { section: "E2E Test Cases", change: "ghi rõ mọi E2E TC = Technique=UC (uniform, không thêm field)" }
      - { section: "Non-Functional Test Cases", change: "ghi rõ ngoài phạm vi bảng trigger — không có Technique" }
      - { section: "Data & Migration Test Cases", change: "ghi rõ ngoài phạm vi bảng trigger — không có Technique" }
      - { section: "Test Scenarios", change: "thêm field 'Key' cho mỗi TS ({Flow N}::UC::{case-slug}) — khoá ghép khi chạy lại" }
      - { section: "Functional Test Cases", change: "thêm field 'Key' vào bảng meta mỗi TC block" }
      - { section: "Validation Test Cases", change: "thêm cột 'Key' vào bảng TC (bảng lên 8 cột)" }
  - to: 5
    note: "Ba lỗ hổng lộ ra khi chạy thật F-001 GAL-Mobile. (A) Block mẫu E2E/NFR/DM thiếu row Key trong khi countOf() của bin/check-ledger.js và toàn bộ luật reconcile ghép theo Key — ba bucket đó không có join key, chỉ đếm được nhờ Covers. (B) Section E2E ghi Technique=UC, mâu thuẫn references/test-design-techniques.md §1 + bảng §5.1 (FAC · NFR · DM không áp kỹ thuật, Technique=NA, expr phải là 1); reference thắng vì FAC derive 1:1 không có hệ số nhân. (C) case-slug legend chỉ nêu NFR/DM, thiếu FAC."
    update:
      - { section: "E2E Test Cases", change: "thêm row 'Key' vào block mẫu TC-{F_ID}-040 ({FAC-id}::NA::{case-slug}); đổi 'mọi E2E TC ⇒ UC' thành 'mọi E2E TC ⇒ NA' cho khớp reference §1/§5.1" }
      - { section: "Non-Functional Test Cases", change: "thêm row 'Key' vào block mẫu TC-{F_ID}-050 ({NFR-id}::NA::{case-slug})" }
      - { section: "Data & Migration Test Cases", change: "thêm row 'Key' vào block mẫu TC-{F_ID}-060 ({DM-id}::NA::{case-slug})" }
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/test-design.md (test-side, bền; history nội dung = git — 015).
Sinh từ frd.md (ở .specs/main/feature/{F-XXX}-{slug}/) — mỗi AC / VR / Flow phải có ít nhất 1 test case cover.
Traceability Matrix ở cuối là view DERIVE tự động (không viết tay) để kiểm tra coverage trước khi đóng feature.

KEY (018): mỗi TS/TC mang field `Key` = {frd-item-id}::{TECHNIQUE}::{case-slug} — khoá để lần chạy
`/spec-test-design` sau ghép TC mới với TC cũ mà KHÔNG đụng ID. Key TẤT ĐỊNH: cùng frd + cùng luật derive ⇒
cùng chuỗi; không phụ thuộc prose (Title/Steps) nên QC sửa câu chữ không làm vỡ ID.
  case-slug theo kỹ thuật: EP → `accept` hoặc slug mệnh đề reject · BVA → `min-1`/`min`/`max`/`max+1` ·
  ST → `{state}--{event}` · DT → chuỗi truth-value theo thứ tự điều kiện (`T-F-T`) · UC → `main` hoặc slug nhánh ·
  FAC/NFR/DM (giữ 1:1, không có kỹ thuật) → `NA::main`, vd `FAC-{F_ID}-001::NA::main`, `NFR-{F_ID}-001::NA::main`.
  ⚠ TC do QC tự thêm tay mang `Key: manual::{slug}` (KHÔNG có item id) — skill **không đụng**, không tính
  vào diff +new/−removed. Đây là vùng cấm của agent.

VERSIONING (016): mỗi SCOPE (section TC: validation/functional/e2e/nfr/dm) có content-version RIÊNG ở frontmatter
`versions.{scope}` — skill ghi test-design auto-bump khi section đó thật sự đổi (per-scope, chống false-stale
fan-out). KHÁC `template_version` (structural, do /artifact-audit+/artifact-migrate — test-side vẫn ngoài scope
cái đó theo 015 §3B). Không sửa version bằng tay. History "đổi gì khi nào" = git log/diff (không còn section
Change History trong body — 016 D5).

Test Design chỉ tồn tại ở FEATURE level — không tách test-design riêng cho component.
Component là internal building block; contract của component được verify gián tiếp qua TC ở đây
và qua unit test trong code (không phải spec artifact).
-->

# Test Design: {Feature Name}

## Overview

{Phạm vi test-design này — feature gì, các luồng / AC / VR chính cần verify, trong 2-3 câu.}

## Test Strategy

### Approach

- **Functional**: verify từng US / Story AC theo happy + edge.
- **Validation**: derive 1:1 từ Verification Rules.
- **Flow-based (E2E)**: chạy theo Mermaid flows trong frd.
- **Feature AC (end-to-end)**: cover `FAC-*` — journey liên story + cross-story consistency (harness ví dụ: Playwright cho web, Maestro cho mobile — chọn theo platform của feature).
- **Non-functional**: cover `NFR-*` — performance / a11y / security (execution-mode riêng: load test, scanner...).
- **Data & migration** *(nếu có)*: cover `DM-*` — chạy migration trên dataset, verify data cũ không mất/hỏng.

> Yêu cầu env của mỗi test class ghi inline ở **Preconditions** từng TC (vd "env perf-test", "dataset prod-like đã load"). Gán env tier cụ thể + lịch chạy thuộc **execution layer** — không ở test-design.

## Test Scenarios

Mỗi scenario gắn với 1 flow trong `frd.md > User Flows`. Scenario mô tả end-to-end path; test case chi tiết liệt kê ở section bên dưới.

TS ID format: `TS-F{NNN}-{seq}` — đánh số tăng dần toàn feature. ID **stable** — đã assign rồi giữ nguyên kể cả khi xóa (không tái sử dụng seq, không renumber).

### TS-{F_ID}-001: {Tên — match Flow 1 trong frd}

- **Key:** `Flow 1::UC::main`
- **Flow ref:** `frd.md > Flow 1: {tên}`
- **Preconditions:** {state trước khi chạy}
- **Postconditions:** {state sau khi pass}
- **Paths:**
  - Happy: A → B → C(happy) → D → F
  - Edge: A → B → C(edge) → E → G
- **Test cases:** `TC-{F_ID}-001`, `TC-{F_ID}-002`, ...

---

### TS-{F_ID}-002: {Tên — match Flow 2 nếu có}

...

## Functional Test Cases

Cover User Stories và Acceptance Criteria trong frd.

TC ID format: `TC-F{NNN}-{seq}` — đánh số tăng dần toàn feature. ID **stable** (không tái sử dụng seq khi xóa, không renumber). Nếu xóa TC → ID đó retire, seq mới tiếp tục tăng từ max.

**Autoable** — test-design là **source of truth** cho field này; `/spec-test-exec` **chỉ đọc** để **lọc** Functional TC xuống `test-exec-functional`. test-exec 100% automation (một harness): `functional` chỉ nhận `YES/MAYBE`; TC `NO` (visual) **không render** vào test-exec — ở lại đây, team kiểm bằng mắt ad-hoc. (Validation TC gần như luôn `YES` → toàn bộ xuống `test-exec-validation`.) Phân loại theo **oracle của Expected** (cái mà outcome được verify):

- `YES` — oracle **lập trình được**: giá trị / state / record / HTTP status / error-message text / route / computed result. *(Mọi Validation TC ⇒ YES theo định nghĩa.)*
- `MAYBE` — oracle lập trình được **nhưng** chỉ tới được qua setup nặng: multi-entity seed, cross-service integration, prior state phức tạp.
- `NO` — oracle **visual**: màu / spacing / layout / icon-asset render / animation / "trông đúng". Hiếm có `TC-F*` — assertion visual thuần thường không thành AC nên thành exploratory (không ID). TC `NO` ở lại test-design (không xuống test-exec).

**Technique** — kỹ thuật ISTQB sinh ra TC này (`references/test-design-techniques.md`). Một giá trị **chính**; kỹ thuật phụ trong ngoặc (`BVA (EP)`). TC derive từ Flow ⇒ `UC`; từ AC nhiều điều kiện ⇒ `DT`; đoán lỗi ⇒ `EG` (**bắt buộc** kèm nguồn A/B/C). TC không gắn được kỹ thuật nào ⇒ thừa, hoặc đang trộn nhiều mục đích → tách.

**`Field` · `Input` · `Polarity` — CONDITIONAL** (027 D5): bắt buộc có khi `Technique ∈ {EP, BVA, ST}`, bỏ đi khi không. Một AC mang ràng buộc field (`Then dòng đó bị từ chối nếu so_lan_gia_han ngoài khoảng 0 < x ≤ 6`) sinh TC **hình dạng validation** nhưng **ở lại bucket functional** (bucket đi theo item neo, không theo kỹ thuật). Thiếu ba field đó thì `/spec-test-exec` route nó qua harness functional mà không có gì để điền — **lệch bucket** im lặng.

### TC-{F_ID}-001: {Title ngắn — verb-first}

| Field | Value |
| --- | --- |
| **Key** | `{frd-item-id}::{TECHNIQUE}::{case-slug}` — vd `AC-{F_ID}-001::EP::accept`; QC thêm tay ⇒ `manual::{slug}` |
| **Type** | Functional — positive / negative |
| **Technique** | UC / DT / EG / PW / EP / BVA / ST — kỹ thuật sinh ra TC này (rule ở đầu section) |
| **Field** | *(chỉ khi `Technique ∈ {EP, BVA, ST}`)* field bị ràng buộc — vd `so_lan_gia_han` |
| **Input** | *(chỉ khi `Technique ∈ {EP, BVA, ST}`)* giá trị vào — ST ghi `{state} + {event}` |
| **Polarity** | *(chỉ khi `Technique ∈ {EP, BVA, ST}`)* positive / negative |
| **Autoable** | YES / MAYBE / NO — phân loại theo oracle (rule ở đầu section) |
| **Priority** | P0 / P1 / P2 |
| **Covers** | `US-{F_ID}-001`, `AC-{F_ID}-001` |
| **Scenario** | `TS-{F_ID}-001` |
| **Preconditions** | ... |

**Steps:**

1. {action}
2. {action}
3. {action}

**Expected:**

- {observable outcome 1}
- {observable outcome 2}

**Test data:** {ref Test Data Requirements hoặc inline literal}

---

### TC-{F_ID}-002: ...

## Validation Test Cases

Derive từ Verification Rules trong frd. **1 positive + 1 negative mỗi VR là SÀN, không phải đủ** — số TC thật do cấu trúc VR quyết định, theo bảng trigger ở `references/test-design-techniques.md`:

- **EP** (mọi VR): `1 accept + 1 TC cho mỗi lý do reject không-ngưỡng` (thiếu giá trị, ngoài `enum`, sai format).
- **BVA** (`Rule` có ngưỡng `>` `<` `≥` `≤` `min` `max` `maxLength` · khoảng ngày): **2 TC / mỗi biên** — tại biên (**accept**) + vượt 1 đơn vị (reject) ⇒ biên đôi `4`, biên đơn `2`. Lý do reject **có ngưỡng** thuộc về BVA, không sinh TC EP trùng — ghi `BVA (EP)`.
- **ST** (`Type` = `enum<…>` **và** có event đổi giá trị): bảng `N state × M event`, TC cho mọi ô hợp lệ + mọi ô không hợp lệ **gọi được**; ô không có đường gọi ghi `unreachable`.
- **DT** (≥2 điều kiện cùng quyết 1 kết quả): `2ⁿ` tổ hợp rồi rút gọn — skill **dựng theo mặc định** (027 D6), prompt hỏi để *bỏ*; ghi `Gaps` là suy luận cần QC xác nhận.
- **Bề mặt quan sát** (`Then` liệt kê ≥2 chỗ đọc được kết quả: danh sách · export · dropdown · API · DB): **1 TC / mỗi bề mặt**, slug `::EP::surface-{tên}` (027 D7).

**Mọi Validation TC ⇒ `Autoable=YES`** (oracle input→accept/reject, logic thuần — không phụ thuộc visual); uniform nên không thêm cột.

Form bảng để dễ scan. **TC từ ST vẫn dùng đúng bảng này** — `Field` = field của VR, `Input` = `{state} + {event}`; bảng `N state × M event` (nếu có) chỉ là **bằng chứng phủ ô**, ghi `TC-F*` vào ô chứ không mint TC ở đó.

Chỉ TC không vừa cột (DT nhiều field cùng lúc) mới viết **dạng block** ngay trong section này, và block **phải lộ đủ** `TC ID` · `Covers` · `Field` · `Input` · `Expected` · `Polarity` — `/spec-test-exec` đọc đúng bộ field này để route; thiếu một cái là TC không xuống được test-exec. **KHÔNG đẻ bucket mới** — giữ map `VR → validation`.

| TC ID | Covers VR | Field | Input | Expected | Polarity | Technique | Key |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TC-{F_ID}-010` | `VR-{F_ID}-001` | `email` | `"user@example.com"` | accept | positive | EP | `VR-{F_ID}-001::EP::accept` |
| `TC-{F_ID}-011` | `VR-{F_ID}-001` | `email` | `""` | reject — required | negative | EP | `VR-{F_ID}-001::EP::required-missing` |
| `TC-{F_ID}-012` | `VR-{F_ID}-001` | `email` | `"abc"` | reject — invalid format | negative | EP | `VR-{F_ID}-001::EP::invalid-format` |
| `TC-{F_ID}-013` | `VR-{F_ID}-002` | `password` | `"abcdef"` (6 ký tự) | accept | positive | BVA | `VR-{F_ID}-002::BVA::min` |
| `TC-{F_ID}-014` | `VR-{F_ID}-002` | `password` | `"abcde"` (5 ký tự) | reject — quá ngắn | negative | BVA (EP) | `VR-{F_ID}-002::BVA::min-1` |

## E2E Test Cases

Cover Feature Acceptance Criteria (`FAC-*`) trong frd — **end-to-end** (journey + consistency + integrity). FAC ở frd đã ở format G/W/T → TC dịch 1:1: Given → Preconditions, When → Steps, Then → Expected. Phân biệt shape bằng field **Type**: `E2E — journey` = tuần tự liên story / `E2E — consistency` = so khớp đa màn / `E2E — integrity` = assert business invariant sau khi kết hợp nhiều story (không nhất thiết tuần tự) (không có TC riêng cho NFR / data ở đây — xem 2 section bên dưới).

**Technique:** mọi E2E TC ⇒ `NA` — FAC giữ **1:1**, không áp kỹ thuật nhân bản (`references/test-design-techniques.md` §1 + bảng §5.1: `NA` ⇒ `expr` phải là `1`). Uniform nên **không thêm field**; nhưng `Key` vẫn phải có (join key của reconcile + `countOf` trong `check-ledger`).

### TC-{F_ID}-040: {Title — e2e journey liên story}

| Field | Value |
| --- | --- |
| **Type** | E2E — journey |
| **Priority** | P0 / P1 / P2 |
| **Covers** | `FAC-{F_ID}-001` |
| **Key** | `FAC-{F_ID}-001::NA::main` — khoá ghép khi chạy lại (`{frd-item-id}::NA::{case-slug}`) |
| **Spans** | `US-{F_ID}-001`, `US-{F_ID}-002`, `US-{F_ID}-003` |
| **Preconditions** | account mới chưa onboard |

**Steps:**

1. Đăng ký account mới
2. Verify email qua link
3. Hoàn thành onboarding form
4. Thực hiện first transaction

**Expected:**

- Toàn bộ flow chạy trong 1 session, không cần support intervene
- State persist đúng giữa các step (refresh không mất tiến độ)

---

### TC-{F_ID}-041: {Title — consistency}

| Field | Value |
| --- | --- |
| **Type** | E2E — consistency |
| **Priority** | P1 |
| **Covers** | `FAC-{F_ID}-002` |
| **Preconditions** | feature đã deploy lên test env, 3 màn Register / Profile / Admin Create accessible |

**Steps:**

1. Trigger empty `email` validation ở Register
2. Trigger empty `email` validation ở Profile
3. Trigger empty `email` validation ở Admin Create
4. Trigger invalid format `"abc"` ở cả 3 màn

**Expected:**

- 3 message ở step 1-3 identical (cùng text, cùng style)
- 3 message ở step 4 identical

---

## Non-Functional Test Cases

<!-- Required-emptyable: GIỮ heading; để trống (không TC) nếu section Non-Functional Requirements ở frd rỗng. -->

Cover `NFR-*` trong frd — giữ **1:1**, **ngoài phạm vi bảng trigger** kỹ thuật (execution-mode, không phải input space) ⇒ không có field `Technique`. **Non-functional type** — execution-mode riêng (load test / scanner / a11y audit), không phải UI walk. Type = `performance` / `a11y` / `security` / ... TC giữ prefix `TC-F*` chung sequence.

### TC-{F_ID}-050: {Title — NFR perf}

| Field | Value |
| --- | --- |
| **Type** | Non-functional — performance |
| **Priority** | P0 |
| **Covers** | `NFR-{F_ID}-001` |
| **Key** | `NFR-{F_ID}-001::NA::main` — khoá ghép khi chạy lại (`{frd-item-id}::NA::{case-slug}`) |
| **Preconditions** | env perf-test, dataset baseline đã load |

**Steps:**

1. Chạy load test (k6 / JMeter) profile 100 RPS sustained 5 phút lên `/login`
2. Đọc p95 latency từ summary report

**Expected:**

- p95 ≤ 500ms
- Error rate ≤ 0.1%

## Data & Migration Test Cases

<!-- Required-emptyable: GIỮ heading; để trống (không TC) nếu section Data & Migration ở frd rỗng. -->

Cover `DM-*` trong frd — giữ **1:1**, **ngoài phạm vi bảng trigger** kỹ thuật ⇒ không có field `Technique`. Chạy migration trên dataset prod-like rồi assert data cũ nguyên vẹn. Type = `data migration`. TC giữ prefix `TC-F*` chung sequence.

### TC-{F_ID}-060: {Title — migrate data cũ}

| Field | Value |
| --- | --- |
| **Type** | Data migration |
| **Priority** | P0 |
| **Covers** | `DM-{F_ID}-001` |
| **Key** | `DM-{F_ID}-001::NA::main` — khoá ghép khi chạy lại (`{frd-item-id}::NA::{case-slug}`) |
| **Preconditions** | env có dataset cũ prod-like (vd: 10.000 bản ghi địa chỉ format cũ) đã load |

**Steps:**

1. Snapshot count + checksum dataset trước migration
2. Chạy migration script
3. Đọc lại toàn bộ bản ghi sau migration

**Expected:**

- Count sau = count trước (10.000/10.000), không bản ghi nào null
- Mọi địa chỉ cũ đọc được đúng format mới, 0 lỗi parse

## Test Data Requirements

Dữ liệu mỗi test **cần** (requirement — KHÔNG phải provisioning/refresh; cách lấy data + cadence thuộc execution layer).

| Data set | Mục đích | Yêu cầu data (shape / đặc điểm) |
| --- | --- | --- |
| `seed_users` | functional positive | user hợp lệ, đủ field bắt buộc |
| `boundary_inputs` | validation edges | giá trị biên cho mỗi VR (rỗng, sai format, quá dài...) |

## Sổ derive *(nếu có)*

<!--
CONDITIONAL (027 D10) — artifact chưa có section này vẫn conformant; `spec-lite check-ledger` SKIP
(exit 0) khi không thấy heading. Có sổ mà sổ lệch ⇒ exit 1.

Một dòng cho MỖI frd item: Flow · Story AC · VR · FAC · NFR · DM. `US-*` KHÔNG có dòng riêng —
nó được phủ qua các AC của nó. Sổ là artifact của CP-2 (đếm lại từ frd NGAY SAU bước nhân hệ số),
không phải bản tự khai viết lúc cuối.

Cột `công thức đòi` có CÚ PHÁP ĐÓNG để máy đọc:  {tổng} = {TECH}:{expr} [+ {TECH}:{expr} ...]
  · {tổng} == tổng giá trị mọi {expr}
  · tập {TECH} == tập ở cột `Technique` (ngăn bằng `+`, vd `BVA+EP`)
  · EP → `m+n` (m phân vùng accept, n lý do reject) · BVA → số nguyên (≥4 nếu ghi chú nói "đôi",
    ngược lại ≥2) · ST → `N×M` · DT → `2^n` (rút gọn: `2^n-k` + ghi chú có `impossible`/`don't-care`)
    · UC → `a+b` (a≥1) · EG/PW → số nguyên ≥1 · NA → `1` (FAC/NFR/DM giữ 1:1)
Cột `đã sinh` = số TS/TC THẬT neo vào item (Key mở đầu `{item}::`, hợp với `Covers`) — đếm lại,
không chép từ cột bên trái. `đã sinh` < `tổng` ⇒ PHẢI có `blocked-by-spec` + dòng `Gaps` cùng item.

Luật đầy đủ + 4 assert của checker: references/test-design-techniques.md §5.1.
-->

| frd item | Technique | công thức đòi | đã sinh | ghi chú |
| --- | --- | --- | --- | --- |
| `VR-{F_ID}-002` | `BVA+EP` | `5 = BVA:4 + EP:1+0` | 5 | biên đôi `0 < x ≤ 12` |
| `VR-{F_ID}-005` | `ST` | `12 = ST:4×4` | 12 | 4 state × 4 event |
| `AC-{F_ID}-010` | `DT` | `4 = DT:2^2` | 4 | 2 điều kiện độc lập |
| `AC-{F_ID}-011` | `EP` | `3 = EP:3+0` | 3 | 3 bề mặt quan sát |
| `Flow 1` | `UC` | `4 = UC:1+3` | 4 | main + 1 nhánh phụ + 2 ngoại lệ |
| `FAC-{F_ID}-001` | `NA` | `1 = NA:1` | 1 | 1:1 |

## Traceability Matrix

**View DERIVE tự động — KHÔNG viết tay, KHÔNG có version riêng (016 D12/D13).** Skill ghi test-design compute lại mỗi lần regenerate:
- **Cột trái (FRD Item)** = sync từ frd (source-of-truth: suite có thể thiếu nguyên một item → lộ ở đây).
- **Type** = loại frd item; quyết định scope quy về (D13): `VR→validation`, `US/AC→functional`, `FAC→e2e`, `NFR→nfr`, `DM→dm`, `Flow→functional`.
- **Covered by** + **Status** = compute bằng **nghịch đảo** field `Covers` của mọi TC. Item có ≥1 TC → ✅ + list TC; item không TC nào trỏ tới → ❌ (gap) + ghi ở "Gaps".

Vì là projection của (frd items × Covers) recompute mỗi lần → matrix **không** mang trục version riêng; thay đổi liên quan fold vào `versions.{scope}` tương ứng.

| FRD Item | Type | Covered by | Status |
| --- | --- | --- | --- |
| Flow 1 | Flow | `TS-{F_ID}-001` | ✅ |
| `US-{F_ID}-001` | US | `TC-{F_ID}-001`, `TC-{F_ID}-002` | ✅ |
| `AC-{F_ID}-001` | Story AC | `TC-{F_ID}-001` | ✅ |
| `VR-{F_ID}-001` | VR | `TC-{F_ID}-010`, `TC-{F_ID}-011`, `TC-{F_ID}-012` | ✅ |
| `FAC-{F_ID}-001` | Feature AC (e2e) | `TC-{F_ID}-040` | ✅ |
| `FAC-{F_ID}-002` | Feature AC (consistency) | `TC-{F_ID}-041` | ✅ |
| `NFR-{F_ID}-001` | NFR | `TC-{F_ID}-050` | ✅ |
| `DM-{F_ID}-001` | Data & Migration | `TC-{F_ID}-060` | ✅ |
| `AC-{F_ID}-00X` | Story AC | — | ❌ chưa có TC |

### Gaps

{Liệt kê item ❌ kèm lý do tạm hoãn / blocker — empty nếu coverage đầy đủ.}

## Out of Scope

- {những gì test-design này KHÔNG cover — lý do (vd: thuộc layer khác như infra/security audit, đã verify ở môi trường khác, ...)}

## Dependencies

### FRD reference

- `frd.md` của feature này — mọi ID (`US-`, `AC-`, `VR-`, `FAC-`, `NFR-`, `DM-`, Flow) phải match.

### Components Used (input only)

Tham chiếu `frd.md > Components Used` để hiểu contract của các component được feature này dùng. Behavior của component được verify **gián tiếp** qua các TC ở đây — không tách test-design riêng cho component.

<!-- 016 D5: section "Change History" đã bỏ. "Đổi gì khi nào" = git log/diff của file này; "đã đổi tới đâu" = frontmatter versions.{scope}. -->

