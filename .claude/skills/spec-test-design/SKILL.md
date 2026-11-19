---
name: spec-test-design
description: Tạo test-design.md (Test Design Document) trực tiếp tại feature level từ frd.md — mechanical derive Test Scenarios + Test Cases. KHÔNG cần integration. Là cỗ máy derive duy nhất của kit; `/spec-test` gọi lại skill này ở mode --dry-run. Dùng cho brownfield onboarding (sau /spec-brownfield-feature) hoặc greenfield bootstrap khi feature đã có frd.md nhưng chưa có test-design.md. Import references/test-design-techniques.md.
---

# spec-test-design

## Overview

Tạo `.specs/tests/{F-XXX}-{slug}/test-design.md` trực tiếp từ frd.md của feature đó — **không qua integration**. Đây là **cỗ máy derive duy nhất** của kit.

> **Vị trí (015):** test-design sống ở `.specs/tests/{F-XXX}-{slug}/` (cùng slug với feature), **KHÔNG** còn ở `.specs/main/feature/{F-XXX}-{slug}/` cùng frd. Input frd/fdd vẫn đọc từ `.specs/main/feature/{F-XXX}-{slug}/`. Artifact test-side **non-versioned** — change history = git.

Skill này song hành với `/spec-prd` và `/spec-sad`: skill có acronym suffix (`prd`/`sad`/`test-design`) → tạo artifact trực tiếp. **`/spec-test` KHÔNG phải skill derive thứ hai** — nó gọi lại chính skill này ở mode `--dry-run` cho từng feature của một integration, rồi diff `.next` lấy delta cho `test.md` (028). Luật derive chỉ ở đây.

## When to Use

- **Brownfield onboarding** — sau `/spec-brownfield-feature` đã sinh frd.md, cần bootstrap test-design.md để có test coverage tracking ngay từ đầu.
- **Greenfield deferred** — feature có frd.md từ lâu nhưng test-design.md chưa được tạo (vd: test design bị defer).
- **Ad-hoc rebuild** — test-design.md drift quá xa khỏi frd.md, muốn regenerate fresh.

## When NOT to Use

- Muốn reconcile test-design của **mọi** feature mà một integration chạm, **và** cần bản ghi delta đọc được cho PR → dùng `/spec-test` (nó gọi lại skill này ở mode `--dry-run`)
- Chỉ muốn sửa vài TC → edit `test-design.md` trực tiếp
- Feature chưa có frd.md → chạy `/spec-brownfield-feature` (brownfield) hoặc `/spec-new` (greenfield) trước

## Hai mode — `create` và `reconcile` (018 D11)

Bước **derive** (Bước 4) chạy như nhau ở cả hai mode; khác nhau ở **bước ghi**:

| Tình trạng | Mode | ID |
| --- | --- | --- |
| `test-design.md` **chưa có** | `create` | cấp từ `001`, ghi `id_counters` = số vừa cấp |
| `test-design.md` **đã có** | **`reconcile`** *(mặc định)* | ghép theo `Key`; TC khớp **giữ nguyên ID**, TC mới cấp từ `id_counters.tc + 1` |
| `--rebuild` (explicit) | `rebuild` | đánh lại từ `001` — **phá reference**; backup + cảnh báo trước |
| `--dry-run` (explicit) | mode nền **y nguyên** theo hai hàng trên | y nguyên — nhưng ghi ra `test-design.md.next`, không đụng file cũ |

**`--dry-run` không phải mode thứ tư (028 D1)** — nó chỉ đổi **đường ghi**. Derive (Bước 4) + mọi checkpoint chạy y hệt; khác đúng bốn chỗ ở [Bước 6](#bước-6-save): ghi `test-design.md.next` · **không** commit · `check-ledger` chạy trên `.next` · in path `.next` cho caller. `.next` là file **hoàn chỉnh** (đủ frontmatter, `id_counters` mới, `versions` đã bump, sổ derive) — caller promote bằng `mv`, không cần đường ghi thứ hai.

Caller là `/spec-test`: nó diff `test-design.md ↔ .next` theo `Key` để dựng bảng delta cho `test.md`, rồi promote. `--dry-run` **không** vào được `rebuild` trừ khi có thêm argument `--rebuild`.

**Chạy lại là đường chính, không phải ngoại lệ** — brownfield/bootstrap luôn chạy nhiều lần khi frd còn động. State duy nhất mang qua các lần chạy là cặp **`Key` → ID** nằm ngay trong artifact; derive vẫn stateless.

`Key` = `{frd-item-id}::{TECHNIQUE}::{case-slug}`, **tất định** — cùng frd + cùng luật derive ⇒ cùng chuỗi. Không phụ thuộc prose (Title/Steps), nên QC sửa câu chữ **không** làm vỡ ID.

TC mang `Key: manual::{slug}` là do QC thêm tay ⇒ **vùng cấm**: skill không đụng, không tính vào diff.

---

## Nhánh mặc định — skill KHÔNG BAO GIỜ dừng chờ người (027 D12)

Skill là **văn bản hướng dẫn**, không phải chương trình. Chỗ nào hướng dẫn rẽ nhánh mà không định nghĩa nhánh *"không ai trả lời"*, agent tự quyết — và quyết khác nhau mỗi lượt. Đo trên bed `F-900`: **2/9 lượt chết hẳn** ở đúng prompt DT, không ghi được file nào.

**Luật:** mọi prompt dưới đây là **thông báo có thể phủ quyết**, không phải cổng chặn. Hỏi xong thì **làm tiếp theo nhánh mặc định**; không ai đáp ⇒ nhánh mặc định là kết quả.

| # | Điểm rẽ | Nhánh mặc định |
| --- | --- | --- |
| 1 | Tập giá trị đóng: tĩnh hay có vòng đời? | frd **không mô tả event** nào làm giá trị đổi ⇒ **EP** (không dựng ST), ghi một dòng `Gaps` là đã xét |
| 2 | DT — có đúng ≥2 điều kiện độc lập không? | **DỰNG bảng quyết định** (4.3). Prompt hỏi để **BỎ**, không phải để làm. Ghi `Gaps`: *suy luận cần QC xác nhận* |
| 3 | `[REMOVE]` — TC cũ không còn khớp frd | **KHÔNG xoá**. Giữ nguyên TC, gắn nhãn `chờ xác nhận`, in danh sách ở Bước 5 |
| 4 | Bootstrap match — TC cũ chưa có `Key` | ghép theo `Covers` + `Polarity` + thứ tự; ca **không chắc** để **trống `Key`** + ghi `Gaps` — **không đoán** |
| 5 | Bước 6 ghi file với status nào | `create`/`rebuild` ⇒ luôn `draft`. `reconcile` trên artifact đang `approved`: **delta ≠ 0 ⇒ hạ về `draft`** (nội dung QC duyệt đã đổi) · **delta = 0 ⇒ giữ `approved`**. **KHÔNG** tự chuyển `draft → approved` — kể cả khi mọi cổng chốt đạt |
| 6 | Không có argument, chọn feature nào | đúng **1** feature có `frd.md` ⇒ lấy feature đó. Nhiều hơn ⇒ **dừng có lỗi**, in danh sách — không đoán |
| 7 | Chọn mode `create` / `reconcile` / `rebuild` | artifact chưa có ⇒ `create` · đã có ⇒ **`reconcile`** · `rebuild` **chỉ khi** có argument `--rebuild` |
| 8 | Có `--dry-run` — hỏi gì thêm không? | **không hỏi gì**. Mode nền vẫn theo điểm rẽ 7; chỉ đường ghi đổi sang `.next` (028 D1) |

Nhánh 2 là cái đắt nhất đã đo được — `::DT::` = 8 ⇒ recall 100%, `::DT::` = 0 ⇒ 85.9–91.5%, không ngoại lệ. Bất đối xứng chi phí: **3 TC thừa xoá trong một phút; ma trận quyền thiếu thì không ai biết mà xoá.**

## Process

### Bước 1: Xác định feature

**Nếu có ARGUMENT:**
- Tách **flag** ra trước: `--rebuild`, `--dry-run` là flag, **không** phải feature ID. `F-002 --dry-run` ⇒ feature = `F-002`, flag = `--dry-run`
- Parse phần còn lại: có thể là feature ID (`F-001`, `001`) hoặc slug (`F-001-auth`, `auth`)
- Quét `.specs/main/feature/*/frd.md`, tìm feature khớp
- Nếu không tìm thấy → báo lỗi:
  > Không tìm thấy feature khớp với "{argument}". Kiểm tra `.specs/main/feature/`.

**Nếu không có ARGUMENT:**

Quét `.specs/main/feature/`. Liệt kê **tất cả** features có `frd.md`, đánh dấu trạng thái test-design:

```
Features có frd.md:

  [1] F-001 — auth                spec✓ test-design✓
  [2] F-002 — checkout             spec✓ test-design—
  [3] F-003 — refund               spec✓ test-design— (frd có 5 Flow, 12 US, 8 VR, 3 FAC)

Chọn số feature:
```

**Nhánh mặc định (điểm rẽ 6)** — lượt không tương tác không ai gõ được số:
- đúng **1** feature có `frd.md` ⇒ **lấy feature đó**, in một dòng nói đã tự chọn.
- **nhiều hơn 1** ⇒ **dừng có lỗi**, in danh sách trên. Đoán feature là ghi đè nhầm artifact của feature khác — hỏng nặng hơn dừng.

Nếu không có feature nào có frd → thông báo:
> Chưa có feature nào có frd.md. Hãy chạy `/spec-brownfield-feature` hoặc `/spec-new` trước.

---

### Bước 2: Gate check — frd.md tồn tại + warn nếu test-design.md đã có

**Check 1 — frd.md tồn tại:**

Nếu `.specs/main/feature/{F-XXX}-{slug}/frd.md` không tồn tại → dừng:
> ⛔ `feature/{F-XXX}-{slug}/frd.md` không tồn tại. `/spec-test-design` cần frd làm input.

**Check 2 — test-design.md đã tồn tại:**

Nếu `.specs/tests/{F-XXX}-{slug}/test-design.md` đã tồn tại:

> `test-design.md` đã tồn tại cho feature **{F-XXX} — {slug}** ({n} TC · {m} TS).
>
> 1. **reconcile** *(mặc định)* — derive lại từ frd rồi ghép theo `Key`: TC khớp **giữ nguyên ID**, TC mới nối tiếp số, TC biến mất được **GIỮ** + gắn nhãn `chờ xác nhận` (không tự xoá). TC `manual::*` không đụng.
> 2. `--rebuild` — đánh lại ID từ `001`. ⚠ **phá mọi reference** dạng `// covers TC-{F_ID}-005` trong test code. Có backup.
> 3. huỷ
>
> Chọn (1 / 2 / 3 — default 1):

- **1** → mode `reconcile`, sang Bước 3.
- **2** → backup `test-design.md.bak.{timestamp}`, mode `rebuild`. `versions` vẫn **bump**, KHÔNG reset về `1` (D14).
- **3** → dừng.

**Nhánh mặc định (điểm rẽ 7)** — prompt trên là **thông báo**, không phải cổng chặn:

| Tình trạng | Mode chạy tiếp |
| --- | --- |
| chưa có `test-design.md` | `create` — không hỏi |
| đã có `test-design.md` | **`reconcile`** — hỏi rồi **chạy tiếp**, không chờ trả lời |
| có argument `--rebuild` | `rebuild` — backup trước |
| có argument `--dry-run` | mode nền y trên, **không hỏi gì** — đường ghi thành `.next` (Bước 6) |

`rebuild` **chỉ** vào được bằng argument explicit. Không ai trả lời mà rơi vào `rebuild` là phá mọi reference `// covers TC-*` trong test code — không được để một nhánh im lặng làm việc đó.

---

### Bước 3: Load context

Load các file sau:

- `.specs/main/feature/{F-XXX}-{slug}/frd.md` — **bắt buộc**, source của TC
- `.specs/main/feature/{F-XXX}-{slug}/fdd.md` — optional, đọc nếu tồn tại để hint Components Used (cho Dependencies section của test-design)
- `.specs/tests/{F-XXX}-{slug}/test-design.md` — **chỉ mode `reconcile`**: dựng map `Key → {ID, Notes, các field QC sửa}` + đọc `id_counters`. TC **không có `Key`** (file sinh trước 018, hoặc do `/spec-test` bản trước 028 ghi) gom riêng cho nhánh **bootstrap match** ở Bước 4.8.
- `references/test-design-techniques.md` — **bắt buộc**, luật derive đầy đủ (7 kỹ thuật ISTQB + công thức đủ + cổng chốt). Bước 4.3 chỉ là bảng tra; công thức và cách kiểm nằm ở file này.

Tóm tắt context:

```
TÔI HIỂU:
- Feature: {F-XXX} — {slug}
- Trong frd.md:
  - {N} Flows
  - {M} User Stories ({K} Acceptance Criteria)
  - {P} Verification Rules
  - {Q} Feature Acceptance Criteria
- Mode: {create — chưa có file / **reconcile** — file cũ có {n} TC ({a} validation · {b} functional · {c} e2e · {d} nfr · {e} dm), {k} TC chưa có `Key`, {j} TC `manual::` / rebuild — backup tại test-design.md.bak.{timestamp}}
- id_counters cũ: {ts: N, tc: M / absent — seed = max seq đang có trong doc}
- fdd.md: {tồn tại — Components Used: C-XXX, C-YYY / chưa có}
```

---

### Bước 4: Auto-derive draft

**Nguyên tắc:** mechanical derive 1:1 từ frd.md — same algorithm như `/spec-test` (xem [skills/spec-test/SKILL.md](../spec-test/SKILL.md) Bước 3.1-3.3). Tóm lại:

#### 4.1 ID assignment — cấp từ `id_counters` (D13)

- **Nguồn cấp ID là `id_counters` ở frontmatter**, high-water-mark **chỉ tăng**: `next = id_counters.tc + 1` (TS: `id_counters.ts + 1`). Cùng cơ chế main artifact — [01-architecture §7](../../01-architecture.md). **KHÔNG** dùng `max(seq trong doc) + 1`: TC có seq lớn nhất bị remove thì công thức đó **tái dụng ID**.
- Mode `create` / `rebuild`: bắt đầu từ `001`, ghi `id_counters` = số cuối vừa cấp.
- Mode `reconcile`: **KHÔNG** đánh lại từ `001` — TC khớp `Key` giữ ID cũ, chỉ TC mới mới cấp số, cấp xong bump `id_counters`.
- `id_counters` **absent** (file bootstrap sinh trước 018): seed = `max(seq)` đang có trong doc. ID retire **không** hạ counter, **không** tái dụng — khoảng trống trong dãy số là bình thường.
- TS và TC cùng feature ID `F{NNN}`; TC dùng chung sequence cho Functional / Validation / E2E / Non-functional / Data & Migration — không đẻ prefix riêng.

Mỗi TS/TC sinh ra mang field **`Key`** = `{frd-item-id}::{TECHNIQUE}::{case-slug}`:

| Kỹ thuật | `case-slug` | Ví dụ |
| --- | --- | --- |
| EP (`m = 1`) | `accept` · slug của mệnh đề reject | `VR-F002-001::EP::required-missing` |
| EP (`m > 1`) | **`accept-{slug mệnh đề}`** — một slug mỗi phân vùng accept | `VR-F002-002::EP::accept-bo-hoa-thuong` |
| EP (bề mặt quan sát) | `surface-{tên bề mặt}` | `AC-F002-011::EP::surface-export` |
| BVA | `min-1` · `min` · `max` · `max+1` | `VR-F002-001::BVA::max+1` |
| ST | `{state}--{event}` | `VR-F002-004::ST::Archived--luu-tru` |
| DT | chuỗi truth-value theo thứ tự điều kiện | `AC-F002-006::DT::T-F` |
| UC | `main` · slug nhánh frd đã ghi | `Flow 1::UC::roi-form-giua-chung` |
| — (`NFR`/`DM`, giữ 1:1 nên không có kỹ thuật) | `NA` + `main` | `NFR-F002-001::NA::main` |
| — (QC thêm tay) | `manual::{slug}` — **không** có item id | `manual::race-double-submit` |

**Slug phía accept phải đối xứng với slug phía reject (027 D3).** `m = 1` ⇒ `accept`; `m > 1` ⇒ `accept-{slug mệnh đề}`, lấy slug từ **chính mệnh đề trong frd** (`bo-hoa-thuong` · `cat-khoang-trang` · `nguyen-van`), không tự chế. `Key` được tuyên bố tất định — slug tự chế ⇒ lượt sau `reconcile` mất join key ⇒ TC ID nhảy. D1/D2 làm **số TC** đúng; D3 làm **`Key`** đúng.

`Key` chỉ được ghép từ **item id + kỹ thuật + ngữ nghĩa ca** — **không** nhét giá trị dữ liệu cụ thể vào (`max+1`, không phải `256`): QC chỉnh `256` → `999` vẫn là ca `max+1`, khoá không được vỡ vì sửa dữ liệu.

#### 4.2 Derivation rules — **sàn 1:1**

Bảng dưới là **sàn**, không phải đủ. Mỗi frd item phải có **ít nhất** ngần này TC; số TC thật do cấu trúc item quyết định — xem 4.3.

| frd item | test-design output (sàn) |
| --- | --- |
| Mỗi `Flow {N}` trong User Flows | 1 Test Scenario `TS-F{NNN}-{seq}` |
| Mỗi `AC-F{NNN}-{seq}` trong US | 1 Functional TC `TC-F{NNN}-{seq}` |
| Mỗi `VR-F{NNN}-{seq}` | 1 positive + 1+ negative Validation TC |
| Mỗi `FAC-F{NNN}-{seq}` (end-to-end) | 1 E2E TC (Type `E2E — journey`/`consistency`/`integrity`) |
| Mỗi `NFR-F{NNN}-{seq}` | 1 Non-functional TC (Type `performance`/`a11y`/`security`...) |
| Mỗi `DM-F{NNN}-{seq}` (section required-emptyable) | 1 Data & Migration TC (Type `data migration`) |

Detail dịch G/W/T → Preconditions/Steps/Expected, infer negative VR branches từ rule text — xem `/spec-test` Bước 3.2.

> **Sàn 1:1 xanh ≠ đủ.** `VR "> 0 và ≤ 12"` là 1 item nhưng input space cần 6 TC; `VR trang_thai enum<…>` sinh 0 TC riêng nếu coi enum là type. Traceability Matrix xanh vẫn để lọt code gõ `<` thay `<=`. Bắt buộc chạy tiếp 4.3.

##### ⛳ CP-1 — mọi frd item đã được neo

**Đếm ngay tại đây, chưa được sang 4.3:** liệt kê mọi item trong frd (`Flow N` · `US-*` · `AC-*` · `VR-*` · `FAC-*` · `NFR-*` · `DM-*`), đối chiếu với bảng neo vừa dựng. Item nào **không có dòng nào** ⇒ quay lại 4.2, không đi tiếp.

Đây là cổng chống **bỏ sót** — rẻ nhất và duy nhất bắt được lỗi "quên hẳn một item". Bốn bước sau chỉ nhân số TC lên; item không có mặt ở đây thì không bao giờ xuất hiện nữa.

#### 4.3 Hệ số nhân theo kỹ thuật (018)

**Luật bất di:** kỹ thuật quyết **ĐỦ** (sinh cột input), frd quyết **ĐÚNG** (cột `Expected`). Ô/cột/nhánh mà frd **không định nghĩa expected** ⇒ **KHÔNG tự chế oracle** — ghi vào `Gaps` (tầng B) + đánh TC `blocked-by-spec`.

Trigger đọc **thuần frd** (`Type` + `Rule` của VR · G/W/T của AC · Mermaid của Flow) — không đọc code, không đoán:

**Trigger đọc MỆNH ĐỀ, không đọc VỊ TRÍ (027 D4).** Cùng một luật viết ở `Rule` của VR, ở `Then`/`When` của AC, hay ở nhãn nhánh Mermaid của Flow ⇒ **cùng kỹ thuật, cùng công thức**. Chỉ **item neo** và **bucket** đổi theo chỗ mệnh đề được viết — frd thật viết luật ở đâu là quyền người viết frd.

| Đọc thấy trong frd (mệnh đề) | Kỹ thuật | Sinh gì | Bucket |
| --- | --- | --- | --- |
| Mọi ràng buộc trên một field | **EP** | **`m + n`**: `m` phân vùng **accept** (mặc định 1; bảng ba hình dạng ở reference §3.1) + 1 TC / mỗi lý do reject **không ngưỡng** | theo item |
| Có ngưỡng (`>` `<` `≥` `≤` `min` `max` `maxLength`, khoảng ngày) | **BVA** | **2 TC / mỗi biên**: tại biên (**accept**) + vượt 1 đơn vị (reject) ⇒ biên đôi `4`, biên đơn `2` | theo item |
| Tập giá trị đóng **và** có event đổi giá trị | **ST** | bảng `N state × M event` | theo item — dạng **block** nếu không vừa cột |
| ≥2 điều kiện độc lập cùng quyết 1 kết quả | **DT** | `2ⁿ` tổ hợp rồi rút gọn — **DỰNG THEO MẶC ĐỊNH** | theo item được `Covers` |
| `Then` liệt kê ≥2 **bề mặt quan sát** | **EP** | 1 TC / mỗi bề mặt, slug `surface-{tên}` | theo item |
| Mỗi Flow | **UC** | 1 main + **mọi** nhánh phụ/ngoại lệ frd đã ghi | Functional (qua TS) |

**Neo TC nhánh vào Flow — nếu không, `UC:a+b` không bao giờ đếm đủ.** `countOf()` của `check-ledger` đếm một TS/TC vào `Flow N` khi **một trong hai** điều đúng: `Key` mở đầu bằng `Flow N::`, **hoặc** `Covers` có chứa `` `Flow N` ``. TS main mang sẵn `Key: Flow N::UC::main` nên luôn đếm được; **TC nhánh thì không tự động**. Vậy mỗi TC phủ một nhánh của Flow N **phải** làm một trong hai:

- neo được vào một `AC` ⇒ giữ `Key: AC-…::{TECH}::{slug}` và **thêm `` `Flow N` `` vào `Covers`** (Covers là danh sách — `` `AC-{F_ID}-003`, `Flow 2` ``);
- không neo được vào `AC` nào (nhánh chỉ tồn tại trong prose của Flow) ⇒ mang `Key: Flow N::UC::{slug-nhánh}`.

Bỏ cả hai thì sổ chỉ đếm được TS main: hoặc bạn ghi `UC:1+0` và **mất** mọi nhánh (C5 không còn ai gác), hoặc ghi `UC:1+b` đúng theo frd rồi **fail assert ②** vì đếm thật ra 1. Đây là lỗi im lặng — cả hai cách đều "chạy được".
| ≥3 biến cấu hình, tích tổ hợp > 20 | **PW** | phủ 100% cặp (2-wise) | Functional |
| Có nguồn đoán lỗi (A/B/C) | **EG** | TC kèm **field nguồn** | theo item |
| AC thuần hành vi — **không** ràng buộc field, **không** mệnh đề reject/ngưỡng | **NA** | giữ **1:1**, `1 = NA:1`; không đòi `Field`/`Input`/`Polarity` | theo item |

**Bucket đi theo item neo, không theo kỹ thuật** — `VR → validation` · `AC`/`US`/`Flow → functional` · `FAC → e2e` · `NFR → nfr` · `DM → dm`. Một AC mang ràng buộc field vẫn ở bucket **functional**; KHÔNG chuyển sang validation vì "trông giống VR", KHÔNG đẻ bucket mới.

**Luật thay cột (D4):** AC prose không có cột `Required` / `Type`. Cần chúng (đơn vị bước BVA, có bắt buộc hay không) ⇒ đọc từ **VR cùng field**; không có VR nào cùng field ⇒ `blocked-by-spec` + `Gaps`, **không giả định**. Còn `m` · `n` · số điều kiện DT · số bề mặt quan sát thì đọc thẳng từ prose, không cần cột nào.

**EP đếm CẢ HAI PHÍA — `m + n`, không phải `1 + n` (027 D1/D2).** `m` = số phân vùng **accept**, mặc định `1`; `m > 1` chỉ ở **bốn hình dạng đóng** (chuẩn hoá trước khi so · bí danh · thu hẹp phạm vi ràng buộc · **`Required: no`**) — bảng đầy đủ ở `references/test-design-techniques.md` §3.1. Không khớp dòng nào ⇒ `m = 1`, không tự chế thêm hình dạng.

**`Required` rơi vào phía nào là theo giá trị của nó:** `Required: yes` ⇒ ca bỏ trống thuộc **`n`** (reject) · `Required: no` ⇒ ca bỏ trống thuộc **`m`** (accept — bỏ trống *được chấp nhận*, và đó là nhánh code hay quên `null`-check). Đọc `Required: no` thành *"không có ca thiếu giá trị"* là mất đúng 1 TC, và **không cổng nào bắt được** — `check-ledger` chỉ kiểm hình dạng `m+n`, C1–C8 không đụng tới `m`.

**Phân hoạch phía KẾT QUẢ (027 D7).** `Then` liệt kê ≥2 **bề mặt quan sát** (danh sách · export · dropdown · API · thông báo · bản ghi DB · webhook) ⇒ **mỗi bề mặt một TC**, slug `::EP::surface-{tên}`. Ba bề mặt là ba đường code; gộp một TC thì hỏng một bề mặt cũng chỉ ra một tín hiệu đỏ. Bề mặt frd **không nói** kết quả thế nào ⇒ không sinh TC cho nó.

Bước nhảy biên đọc từ `Type`: `integer`/`number` → 1 · `decimal(18,2)` → 0.01 · `date`/`datetime` → 1 ngày · `string` (maxLength) → 1 ký tự.

**BVA nuốt EP khi trùng ca — CẢ HAI PHÍA.** *Reject:* lý do **có ngưỡng** không sinh TC EP riêng — ca đó là `max+1` / `min-1`, ghi `Technique = BVA (EP)`. *Accept:* cùng field đã có BVA thì phân vùng accept của EP **đã nằm trong** ca tại-biên (`1` và `12` cùng lớp tương đương với `3`) ⇒ term viết **`EP:0+n`**. `m = 0` **chỉ hợp lệ khi có term BVA** cùng dòng; không có BVA mà `m = 0` là bỏ sót phía accept. Luật này vốn chỉ viết cho phía reject, và chỗ hở đó làm **hai lượt chạy bất đồng** (đo 2026-09-04).

**ST — chi tiết:**
- Dựng bảng `N state × M event` từ `Rule` của VR + event lấy ở AC/Flow. Ô hợp lệ → TC assert state đích. Ô **không được phép mà vẫn gọi được** qua API/UI → TC chứng minh bị từ chối. Ô **không có đường gọi** ⇒ ghi `unreachable`, **không** sinh TC.
- **Ba ca luôn phải có:** ① lặp lại hành động đã làm ② hành động trên state **terminal** ③ **nhảy cóc** bỏ bước giữa.
- TC `Covers` một `VR` ⇒ **ở lại bucket Validation** và dùng **đúng bảng Validation**, không đẻ shape mới: `Field` = field của VR, `Input` = `{state} + {event}`. Bảng `N state × M event` giữ vai **bằng chứng phủ ô** — ghi `TC-F*` vào từng ô, không mint TC ở đó.
- Chỉ TC thật sự không vừa cột (DT nhiều field cùng lúc) mới viết **dạng block**, và block **phải lộ đủ** `TC ID` · `Covers` · `Field` · `Input` · `Expected` · `Polarity` — `/spec-test-exec` đọc đúng bộ field này để route ([SKILL.md](../spec-test-exec/SKILL.md)); thiếu một cái là TC **không xuống được** test-exec mà không ai báo. **KHÔNG đẻ bucket mới** — giữ map `VR → validation`.
- `enum` **không** tự động là ST: `enum<VN|EN>` (lựa chọn tĩnh) → chỉ EP. Câu hỏi phân biệt: *có event nào làm giá trị đổi sau khi record đã tạo?* — **nhánh mặc định (điểm rẽ 1): frd không mô tả event nào ⇒ EP**, ghi một dòng `Gaps` là đã xét. Không dựng state machine từ một danh sách giá trị.

**DT — DỰNG THEO MẶC ĐỊNH (027 D6, đảo chiều so với 018).** Phát hiện ≥2 điều kiện độc lập cùng quyết một kết quả ⇒ **dựng bảng `2ⁿ` ngay**, không chờ ai đồng ý. Prompt là **thông báo để phủ quyết**, không phải cổng chặn:

```
AC-F002-006 có 2 điều kiện độc lập: (1) han_hoan_thanh < hôm nay  (2) trang_thai ≠ Done
→ Đã dựng bảng quyết định 4 tổ hợp. Bỏ đi? [y/N]
```

**Không ai trả lời ⇒ giữ bảng**, chạy tiếp. Ghi một dòng `Gaps`: *"DT dựng theo suy luận từ prose — cần QC xác nhận"*.

**Vì sao đảo:** bất đối xứng chi phí. 3 TC thừa xoá trong một phút; ma trận quyền thiếu thì không ai biết mà xoá. Đo trên bed: lượt có `::DT::` ⇒ recall 100%, lượt không ⇒ 85.9–91.5% — và 2/9 lượt **chết hẳn** ở đúng prompt cũ.

Bắt buộc có tổ hợp *"cả hai đều không"* và *"cả hai đều có"*. Rút gọn được, nhưng mỗi cột bỏ phải ghi lý do `impossible` / `don't-care`. Cột nào frd không định nghĩa expected ⇒ `blocked-by-spec`, không đoán.

**UC — 5 nhánh bắt buộc rà** (① huỷ giữa chừng ② dữ liệu rỗng ③ double-submit ④ đồng thời ⑤ quá khổ/timeout). "Rà" = **phải xét**, không phải phải có TC: mỗi Flow ghi đúng 5 dòng, mỗi dòng một dạng — `áp dụng → TC-F*` · `không áp dụng → {lý do}` · `frd chưa nói → blocked-by-spec`. ②③④ không đến từ frd ⇒ **chỉ được sinh câu hỏi, không được sinh oracle**.

**EG — mỗi TC phải có field nguồn**, một trong ba: **A** finding trong `test-report.md` của feature này / feature dùng chung component · **B** cạm bẫy kỹ thuật ghi trong `CLAUDE.md` của repo sản phẩm · **C** đặc thù dữ liệu bản địa (Unicode có dấu, khoảng trắng copy-paste, dấu phân cách thập phân). Neo không được vào nguồn nào ⇒ **không sinh TC**.

**PW — chỉ khi tích tổ hợp > 20.** Ghi **hai con số**: tổ hợp đầy đủ / TC sau rút gọn.

**FAC · NFR · DM: không áp kỹ thuật**, giữ 1:1. FAC thêm một check: `len(Spans) ≥ 2`. FAC chỉ đi **1 story** ⇒ trùng Functional ⇒ **cảnh báo QC**, đề xuất gộp về Functional hoặc trả ngược frd:

```
⚠ FAC-F002-002 spans 1 story (US-F002-004) — E2E TC sẽ trùng Functional TC.
  Đề xuất: gộp về Functional, hoặc trả ngược frd để mở rộng scope FAC.
```

**AC một điều kiện ⇒ `Technique = EP`** (một ca đại diện cho phân vùng mà AC mô tả) — để C1 tất định, không có TC nào Functional bỏ trống `Technique`.

**Ô ST đã có TC Functional cover ⇒ trỏ tới TC đó, KHÔNG mint TC mới.** Nhiều ô transition đã được một `AC` mô tả sẵn (vd `AC "Done + hoàn thành lần nữa → giữ Done"` = ô `Done--hoàn thành`). Bảng ST ghi `TC-F*` sẵn có ở ô đó; chỉ ô **chưa ai cover** mới sinh TC mới. Trùng lặp không phải độ phủ.

**Functional TC lộ thêm `Field` · `Input` · `Polarity` khi `Technique ∈ {EP, BVA, ST}` (027 D5) — `Technique = NA` thì KHÔNG đòi ba field đó.** Field **conditional** — chỉ có khi kỹ thuật là một trong ba, nên artifact cũ vẫn conformant và **không bump `template_version`**. Lý do: một AC mang ràng buộc field sinh TC **hình dạng validation** nhưng ở lại bucket **functional**; thiếu ba field đó thì `/spec-test-exec` route nó qua harness functional mà không có gì để điền — **lệch bucket** im lặng, không ai báo.

**Ghi `Technique` vào đâu:** Validation → **cột** trong bảng · Functional → **field** trong bảng meta, cạnh `Type`/`Autoable` · E2E → không thêm field (luôn `NA` — FAC giữ 1:1, xem reference §1) · NFR/DM → không thêm field (ngoài phạm vi bảng trigger). Một giá trị **chính**, kỹ thuật phụ trong ngoặc (`BVA (EP)`).

##### ⛳ CP-2 — tính lại từ frd, ghi thành SỔ DERIVE

Đây là checkpoint đắt nhất và là lý do tồn tại của cả 4.3. **Đặt ngay đây, không dồn xuống Bước 5** — lỗi sinh ở 4.3 mà bị hỏi tới ở Bước 5 thì cách năm bước, context đã loãng.

**Luật CP-2 — câu hỏi phải neo vào frd, không neo vào output vừa viết:**

| Hỏi thế này | KHÔNG hỏi thế này |
| --- | --- |
| *"`AC-F900-010` có mấy điều kiện độc lập ⇒ công thức ra mấy TC?"* | *"phần Functional vừa rồi ổn chứ?"* |
| *"`VR-F900-002` khớp hình dạng nào ở §3.1 ⇒ `m` bằng mấy?"* | *"đã áp EP chưa?"* |

Agent vừa viết xong thì cái nó viết **luôn "trông đúng"**. Reviewer chính mình không bắt được lỗi bỏ sót — chỉ có phép tính lại từ nguồn mới bắt được.

**Sản phẩm của CP-2 là section `## Sổ derive` trong artifact** (027 D10) — một dòng cho **mỗi** frd item (Flow · Story AC · VR · FAC · NFR · DM; `US-*` không có dòng riêng, nó được phủ qua các AC của nó):

| frd item | Technique | công thức đòi | đã sinh | ghi chú |
| --- | --- | --- | --- | --- |
| `VR-F900-005` | `ST` | `12 = ST:4×4` | 12 | 4 state × 4 event |
| `VR-F900-004` | `BVA+EP` | `5 = BVA:4 + EP:1+0` | 5 | biên đôi `0 < x ≤ 12` |
| `AC-F900-010` | `DT` | `4 = DT:2^2` | 4 | 2 điều kiện độc lập |
| `AC-F900-011` | `EP` | `3 = EP:3+0` | 3 | 3 bề mặt quan sát |
| `Flow 1` | `UC` | `4 = UC:1+3` | 4 | main + 1 nhánh phụ + 2 ngoại lệ |

**Cú pháp cột `công thức đòi` là ĐÓNG** — `{tổng} = {TECH}:{expr} [+ {TECH}:{expr} …]`, mỗi kỹ thuật một hình dạng bắt buộc (`EP → m+n` · `BVA → số nguyên` · `ST → N×M` · `DT → 2^n` · `UC → a+b` · `NA → 1` (FAC/NFR/DM **và** Story AC thuần hành vi)). Bảng đầy đủ + 4 assert của checker: [`references/test-design-techniques.md §5.1`](../../references/test-design-techniques.md).

**Vì sao sổ chứ không phải checklist:** checklist tự khai bắt được lỗi **làm sai**, không bắt được lỗi **bỏ sót** — không có mục nào cho item mà agent đã quên. Sổ ép liệt kê **từng item**, và cột `Technique` khoá lại cột "công thức đòi" nên hai số tự khai không khớp nhau một cách gian được.

Cột `đã sinh` **đếm lại từ artifact**, không chép từ cột bên trái. `đã sinh` < tổng ⇒ **phải** có `blocked-by-spec` + dòng `Gaps` neo cùng item.

#### 4.4 Priority defaults

> **Validation TC không có Priority** (027 D9) — bảng Validation trong `templates/tests/test-design-template.md` không có cột đó. Bảng dưới chỉ áp cho TC **dạng block** (Functional · E2E · NFR · DM).

| Source | Priority |
| --- | --- |
| TC cover US Must | P0 |
| TC cover US Should | P1 |
| TC cover US Could | P2 |
| TC cover FAC e2e (journey) | P0 |
| TC cover FAC integrity | P0 |
| TC cover FAC consistency | P1 |
| TC cover NFR security | P0 |
| TC cover NFR perf/a11y/i18n/browser | P1 |
| TC cover DM (data & migration) | P0 |

#### 4.5 Traceability Matrix — **derive tự động** (016 D12/D13)

Matrix KHÔNG viết tay. Compute:
- **Cột trái** = mọi frd item (Flow / US / Story AC / VR / FAC / NFR / DM).
- **Type** → quyết scope (D13): `VR→validation`, `US/AC→functional`, `Flow→functional`, `FAC→e2e`, `NFR→nfr`, `DM→dm`.
- **Covered by** + **Status** = nghịch đảo field `Covers` của mọi TC. Item có ≥1 TC → ✅ + list; không TC nào trỏ tới → ❌ (gap) + ghi lý do ở Gaps.

Matrix là projection recompute mỗi lần → **không** mang version riêng.

#### 4.6 Placeholders cần QC fill

Agent **không suy đoán**:

| Field | Placeholder |
| --- | --- |
| Test Data Requirements | Row `{TBD — shape}` cho mỗi dataset test cần (yêu cầu data, không phải nguồn/refresh) |
| Out of Scope | Để trống với note `<!-- QC fill -->` |
| Test Strategy > Approach | Bullet generic theo template gốc |
| Overview | 2-3 câu mô tả feature scope từ frd Overview |

#### 4.7 Dependencies section

- **FRD reference**: path tới `frd.md` của feature này
- **Components Used**: copy từ `frd.md > Components Used`. Nếu fdd.md tồn tại → cross-reference C-XXX để đảm bảo đúng.

##### ⛳ CP-3 — đếm TC thật trong từng section, so với sổ

Sau khi render **mỗi** section TC (Validation · Functional · E2E · NFR · DM) và bảng Test Scenarios: **đếm số TS/TC thật có mặt trong section đó**, cộng lại theo item, so với cột `đã sinh` ở sổ (CP-2). Lệch ⇒ sửa **ngay tại section vừa render**, không ghi chú "sẽ sửa sau".

Kèm hai cổng chất lượng — chúng chặn cái mà đếm số không chặn được (027 D8):

| # | Kiểm gì | Không đạt thì |
| --- | --- | --- |
| **C7** | mọi `Expected` **chạy tới được** từ `Preconditions` + `Steps` của chính TC đó — không bước ẩn, không dựa state mà không TC nào dựng | sửa `Steps`/`Preconditions`, hoặc tách TC |
| **C8** | `Expected` là **một** oracle tất định | nhiều kết quả cùng hợp lệ ("400 hoặc 404", "báo lỗi **hoặc** bỏ qua dòng") ⇒ frd chưa quyết ⇒ `blocked-by-spec` + `Gaps`, **KHÔNG** viết oracle rời rạc |

Oracle rời rạc là lỗi nguy hiểm nhất ở đây: test **xanh cả khi code sai**, tức đủ TC mà vẫn không phát hiện được lỗi. Đếm số không nhìn thấy nó.

#### 4.8 Ghép với test-design cũ — chỉ mode `reconcile` (D12)

Derive xong (4.1–4.7) ra một tập TC **mới**. Ghép với tập **cũ** bằng `Key`, năm nhánh:

| Tình huống | Xử lý | ID |
| --- | --- | --- |
| `Key` có ở **cả cũ + mới** | **ghi đè mọi field derive được** (Title · Steps · Expected · Priority · Technique · Autoable · Covers · Field/Input/Polarity ở bảng Validation), in `~modified` kèm **tên field bị ghi đè**; **giữ nguyên** field QC-only | **giữ ID cũ** |
| `Key` **chỉ có ở mới** | `[NEW]` | `id_counters.tc + 1`, bump counter |
| `Key` **chỉ có ở cũ** | `[REMOVE]` — **KHÔNG tự xoá**; mặc định **giữ nguyên** + nhãn `chờ xác nhận` | giữ ID; `id_counters` **không giảm** |
| `Key` bắt đầu `manual::` | **không đụng** — không update, không xoá, không tính vào diff | giữ |
| TC cũ **không có `Key`** | **bootstrap match** (dưới) | giữ ID cũ sau khi QC confirm |

**Ranh giới sở hữu field — thứ bền là `Key` + ID, không phải câu chữ.** Mọi field derive được từ frd sẽ bị **ghi đè** ở mỗi lần reconcile; QC sửa câu chữ ở đó thì lần chạy sau mất. Chỉ hai thứ QC giữ được: field **`Notes`** và **TC `manual::*`** (nguyên khối). QC muốn giữ một cách diễn đạt riêng ⇒ chuyển TC đó thành `manual::{slug}`, hoặc sửa **frd** để derive ra đúng câu đó. Skill in rõ field nào bị ghi đè để QC không mất chữ trong im lặng:

```
[MODIFY]  TC-F002-017  VR-F002-001::BVA::max
          Input:    "tiêu đề dài đúng 255 ký tự (QC sửa)"  →  "chuỗi 255 ký tự"   ← ghi đè
          Expected: không đổi
```

**`[REMOVE]` — nhánh mặc định là GIỮ (điểm rẽ 3):**

```
⚠ 2 TC không còn khớp frd hiện tại — đã GIỮ NGUYÊN, gắn nhãn `chờ xác nhận`:
  TC-F002-018  VR-F002-001::BVA::max+1   (VR-F002-001 đổi ngưỡng 255 → 200)
  TC-F002-031  VR-F002-005::EP::not-in-enum   (VR-F002-005 bị xoá khỏi frd)
QC xoá tay khi đã xem, hoặc chạy lại sau khi sửa frd.
```

Không ai trả lời ⇒ **không TC nào bị xoá**. TC thừa QC xoá được trong một phút; TC bị agent xoá im lặng thì không ai biết mà khôi phục.

**Bootstrap match — chạy đúng một lần cho file cũ chưa có `Key`:** ghép theo `Covers` + `Polarity` + **thứ tự trong nhóm**, in bảng mapping cho QC confirm rồi mới stamp `Key`:

```
Bootstrap 11 TC chưa có Key — mapping đề xuất:
  TC-F001-010  VR-F001-001 positive #1  →  VR-F001-001::EP::accept
  TC-F001-011  VR-F001-001 negative #1  →  VR-F001-001::EP::required-missing
  ...
Đúng chưa? (y = stamp Key, giữ nguyên ID · n = sửa tay từng dòng)
```

**Nhánh mặc định (điểm rẽ 4)** — không ai xác nhận thì:
- ca ghép được **chắc chắn** (đúng 1 ứng viên theo `Covers` + `Polarity`) ⇒ **stamp `Key`**, giữ ID.
- ca **không chắc** (nhiều ứng viên, hoặc `Covers` không khớp item nào) ⇒ **để trống `Key`** + ghi `Gaps` — **không đoán**. TC vẫn còn nguyên, lần sau QC stamp tay.

Thứ tự chỉ dùng **ở lần bootstrap này** — sau khi stamp, mọi lần ghép sau là so chuỗi `Key`, không còn phụ thuộc thứ tự. TC cũ không map được vào `Key` nào ⇒ đề xuất `manual::{slug}` (coi là TC QC tự viết) thay vì xoá.

---

### Bước 5: Báo cáo cho QC + CP-4

**Báo cáo, không phải xin phép** (điểm rẽ 5) — Bước 6 ghi file ở `status: draft` bất kể có ai đọc hay không.

Mode `create` / `rebuild`: hiển thị **draft đầy đủ**.

Mode `reconcile`: hiển thị **diff**, không phải draft trắng — QC cần thấy *cái gì đổi*, không phải đọc lại 47 TC:

```
reconcile F-002 — 47 TC cũ → 49 TC mới
  [NEW]      TC-F002-048  VR-F002-006::EP::accept        (VR mới trong frd)
  [NEW]      TC-F002-049  VR-F002-006::EP::required-missing
  [MODIFY]   TC-F002-017  Expected: "255 ký tự" → "200 ký tự"   (Key không đổi, ID giữ)
  [KEEP?]    TC-F002-018  VR-F002-001::BVA::max+1               ← GIỮ, nhãn `chờ xác nhận`
  [manual]   TC-F002-050  manual::race-double-submit            (không đụng)
  45 TC còn lại: không đổi
```

##### ⛳ CP-4 — bookkeeping, cái duy nhất còn lại ở cuối

Chất lượng derive **đã được chốt ở CP-1…CP-3**, ngay tại chỗ sinh (027 D11). Cổng cuối chỉ còn giữ phần **sổ sách** — thứ chỉ biết được sau khi biết toàn bộ delta:

- [ ] `reconcile`: 100% TC khớp `Key` **giữ nguyên ID**; TC mới cấp từ `id_counters.tc + 1`, không lấp khoảng trống
- [ ] `id_counters` **chỉ tăng** — TC retire không hạ counter, ID retire không tái dụng
- [ ] TC `Key: manual::*` còn **nguyên vẹn**, không nằm trong `+new` / `−removed`
- [ ] `versions.{scope}` **monotonic** — bump scope thật đổi, `rebuild` cũng bump, không scope nào giảm
- [ ] `template_version` copy từ template
- [ ] Traceability Matrix là projection recompute, KHÔNG viết tay
- [ ] KHÔNG có section Change History (016 D5)

> Draft đã ghi ở `status: draft`. QC còn cần: fill placeholders (Test Data Requirements / Out of Scope / Strategy Approach) · xem danh sách `chờ xác nhận` (nếu có) · xem dòng `Gaps` mà DT/bootstrap để lại.

**Nhánh mặc định (điểm rẽ 5): không chờ confirm để ghi file.** Skill ghi thẳng `status: draft` rồi in kết quả — `draft` chính là trạng thái "chưa ai duyệt". Chờ confirm để **ghi** là biến một lượt headless thành một lượt mất trắng: đo trên bed, 2/9 lượt dừng ở prompt và **không sinh artifact nào**. Chuyển `draft → approved` vẫn là việc của người, không bao giờ tự động.

---

### Bước 6: Save

Ghi `.specs/tests/{F-XXX}-{slug}/test-design.md` với status `draft` (feature-level artifact có lifecycle riêng, không phải `approved` — QC còn fill placeholders nên status `draft` cho đến khi đầy đủ); ngoại lệ duy nhất là `reconcile` **không có delta** trên artifact đã `approved` — xem bảng dưới. Ghi xong **commit** (git = content history).

**Status khi reconcile chạy trên artifact đang `approved` (điểm rẽ 5):** `approved` nghĩa là QC đã duyệt **nội dung đó**; reconcile sửa nội dung thì con dấu không còn ứng với thứ đang nằm trong file.

| Tình huống | Status sau khi ghi |
| --- | --- |
| `create` / `rebuild` | `draft` (như cũ) |
| `reconcile`, delta ≠ 0 (có `[NEW]`/`[MODIFIED]`/`[REMOVE]` bất kỳ) | **hạ `approved` → `draft`**, in một dòng lý do ở Bước 5: `status: approved → draft — reconcile đổi {n} TC` |
| `reconcile`, delta = 0 | **giữ nguyên** `approved` — không đụng frontmatter |

Chiều ngược lại vẫn cấm: skill **không bao giờ** tự đặt `draft → approved`.

#### 6.0 `--dry-run` — đổi đường ghi, không đổi nội dung (028 D1)

Có flag `--dry-run` thì **bốn** việc dưới đây khác, mọi thứ còn lại y nguyên:

| Việc | Lượt thường | `--dry-run` |
| --- | --- | --- |
| Đường ghi | `test-design.md` | **`test-design.md.next`** — file cũ không đụng một byte |
| `git commit` | có | **không** — caller quyết định promote hay bỏ |
| `check-ledger` | trên file vừa ghi | trên **`.next`** |
| Kết thúc | in báo cáo | in báo cáo + **path `.next`** cho caller |

`.next` là file **hoàn chỉnh**, không phải patch: đủ frontmatter, `id_counters` mới, `versions` đã bump theo bảng dưới, sổ derive, Traceability Matrix. Caller promote bằng `mv test-design.md.next test-design.md` — không có bước apply nào.

Mode `rebuild` + `--dry-run`: backup ở Bước 2 **không** tạo (file cũ chưa bị đụng, `.next` chưa được promote); caller tự chịu trách nhiệm backup trước khi `mv`.

`.next` **không** vào `.gitignore` — nó luôn bị `mv` hoặc xoá trước khi lượt kết thúc. Thấy `.next` nằm lại trong `git status` = một lượt đã chết giữa đường.

**Version stamp (016 D1/D2 + 018 D14/D17) — `versions.{scope}` MONOTONIC, không bao giờ reset:**

| Tình huống | Xử lý |
| --- | --- |
| Mode `create` | set `versions.{scope} = 1` cho **mọi scope CÓ TC**. Scope không có TC (nfr/dm rỗng) → **không** thêm entry |
| Mode `reconcile`, scope thật đổi (`+new`/`−removed`/`~modified` ≠ 0) | **bump +1** |
| Bootstrap **chỉ stamp `Key`** (tập TC không đổi nội dung) | **KHÔNG bump** — `Key` là metadata ghép ID, `/spec-test-exec` không đọc; bump ở đây tạo reconcile giả xuống test-exec |
| Mode `reconcile`, scope không đổi | giữ nguyên — không đụng file |
| Mode `rebuild` | **vẫn bump +1**, KHÔNG reset về `1` |
| `versions` **absent** (file bootstrap) | seed `= 1` mọi scope có TC, **rồi áp bump** cho scope lần chạy này đổi ⇒ scope đổi kết thúc ở `2` |

> **Vì sao không bao giờ reset:** gate của `/spec-test-exec` chỉ định nghĩa ba ô — `test-exec chưa có` (CREATE), `test_design_version == versions` (NO-OP), `<` (RECONCILE). Reset `versions` về `1` đẩy nó vào ô `test_design_version > versions` — ô **không định nghĩa** ⇒ downstream im lặng không reconcile. Monotonic khiến ô đó không bao giờ xảy ra. Seed thẳng `1` cho scope vừa đổi cũng sai cùng kiểu: `test-exec` đang giữ `test_design_version: 1` sẽ ra NO-OP và nuốt mất delta.

**`id_counters`:** ghi lại `{ts, tc}` = số cuối vừa cấp. **Chỉ tăng** — TC bị remove không hạ counter. `template_version` copy từ template (structural, inert cho test-side — 015 §3B, ngoài `/artifact-audit`+`/artifact-migrate`); KHÁC `versions` (content, do skill này quản).

**Không có Change History (016 D5):** KHÔNG append section Change History — đã bỏ khỏi template. "Đổi gì khi nào" tra git log/diff; "đã đổi tới đâu" là `versions.{scope}`.

Mode `rebuild` — file backup `test-design.md.bak.{timestamp}` đã tạo ở Bước 2.

Thông báo kết quả:

**Đếm thật, không ước lượng (018 D15):** sau khi dựng draft, **đếm số TC/TS có mặt trong từng section** rồi in — KHÔNG suy từ số item frd (một VR có thể ra 6 TC, công thức `~2P` sai).

**Chạy checker ngay sau khi ghi file** (027 D10):

```bash
npx spec-lite check-ledger .specs/tests/{F-XXX}-{slug}/test-design.md
# --dry-run: chạy trên .../test-design.md.next
```

Checker **phải in `✓ SỔ KHỚP`**. Output `⊘ ... SKIP` cũng `exit 0` nhưng có nghĩa artifact **thiếu section `## Sổ derive`** ⇒ CP-2 đã bị bỏ qua ⇒ sửa rồi ghi lại. Đừng lấy exit code làm bằng chứng.

Exit 1 ⇒ sổ lệch ⇒ **sửa rồi ghi lại**, không in "✓". Bốn assert: ① bỏ sót item · ② sổ khai khống · ③ sinh hụt không giải thích · ④ công thức đòi sai hình dạng. Checker đọc **cả `frd.md`** nên nó chạy được ở dự án thật, **không cần golden**.

```
✓ .specs/tests/{F-XXX}-{slug}/test-design.md đã được tạo (status: draft)
  TS {n} · Validation {n} · Functional {n} · E2E {n} · NFR {n} · DM {n}   ({tổng} TC)
  Technique: EP {n} · BVA {n} · ST {n} · DT {n} · UC {n} · EG {n} · PW {n}
  Sổ derive: {n}/{n} frd item có dòng · check-ledger ✓
  {nếu có: ⚠ {n} TC blocked-by-spec — xem Gaps}
  {nếu có: ⚠ {n} TC `chờ xác nhận` — không còn khớp frd, đã GIỮ nguyên}
  {nếu rebuild: backup tại test-design.md.bak.{timestamp}}

Bước tiếp theo:
  - QC: fill remaining placeholders (Test Data Requirements, Out of Scope, Strategy)
  - QC: xem dòng Gaps (DT dựng theo suy luận · Key để trống ở bootstrap) + danh sách `chờ xác nhận`
  - Đổi status: draft → approved khi sẵn sàng — chạy `spec-lite check-ledger` phải exit 0 trước
  - frd đổi về sau → chạy lại /spec-test-design (mode reconcile, ID giữ nguyên)
```

`--dry-run` — in đúng bảng trên nhưng đổi dòng đầu + dòng cuối, để caller đọc được path:

```
✓ .specs/tests/{F-XXX}-{slug}/test-design.md.next đã được dựng (dry-run — file cũ không đổi)
  ...  (y hệt phần thân ở trên)
  check-ledger trên .next: ✓ SỔ KHỚP

DRY-RUN: .specs/tests/{F-XXX}-{slug}/test-design.md.next
```

Dòng `DRY-RUN:` là **contract với caller** — `/spec-test` grep dòng này để biết path promote. Không in dòng đó = caller coi lượt derive thất bại.

Mode `reconcile` — in **bảng delta per scope** thay vì chỉ tổng số:

```
✓ .specs/tests/{F-XXX}-{slug}/test-design.md reconcile

  scope        trước  sau   +new  −removed  ~modified  manual giữ
  validation      29    31     +2        −1         ~2          0
  functional      14    14      0         0         ~1          1
  e2e              2     2      0         0          0          0
  nfr              1     1      0         0          0          0
  dm               1     1      0         0          0          0

  ID: 100% TC khớp Key giữ nguyên ID · cấp mới TC-F002-048..049 · retire TC-F002-018
  id_counters: tc 47 → 49 (chỉ tăng) · ts 2 → 2
  versions: validation 1→2 · functional 1→2 · (e2e/nfr/dm no-op)
```

---

## Đơn vị tiến độ

Sổ của skill này: `.specs/tests/{F-XXX}-{slug}/.progress/design.md` — **writer duy nhất là skill này**; KHÔNG đọc, KHÔNG ghi sổ của skill khác. Dựng lại **trọn** sổ mỗi lượt rồi ghi đè: nội dung derive từ artifact nên một ô sửa tay bị ghi đè ở lượt sau. Hình dạng + frontmatter: `templates/tests/verify-progress-template.md`; định nghĩa thư mục: `02-artifacts.md` §4.7.

**Hạt không phải tiến độ mà là chất lượng artifact** — 4 dòng, không chia theo bước. `[x]` nghĩa là *"đã có bản ghi"*, không phải *"xanh"*.

**Việc lớn** — `- [ ] /spec-test-design` — tick khi `test-design.md` tồn tại **và** không có `test-design.md.next` nằm lại (`.next` còn đó = một lượt derive đã chết giữa đường, xem [Bước 6](#65---dry-run--đổi-đường-ghi-không-đổi-nội-dung-028-d1)).

| Việc nhỏ | Đọc file / field | Xong khi |
|---|---|---|
| `test-design.md · {status} · template_version {v}` | frontmatter `status` · `template_version` vs `templates/tests/test-design-template.md` | `status` ∈ {`draft`, `approved`} **và** `template_version` khớp template |
| `sổ derive {k}/{n} frd item` | section `## Sổ derive`; `n` = số item của `frd.md` (`Flow N` · `AC-*` · `VR-*` · `FAC-*` · `NFR-*` · `DM-*`; `US-*` **không** có dòng riêng — nó phủ qua các AC của nó) | `k == n`. Section vắng mặt ⇒ ghi `n/a (sinh trước 027)`, **không** để `[ ]` |
| `check-ledger` | chạy `npx spec-lite check-ledger .specs/tests/{F-XXX}-{slug}/test-design.md`, đọc **stdout** | in `✓ SỔ KHỚP`. `⊘ … SKIP` cũng exit 0 nhưng nghĩa là **không có sổ** ⇒ **không** nhận |
| `scope có TC: … (versions …)` | frontmatter `versions:` — tập key = scope có TC; đếm chéo block `### TC-F*` / row bảng của từng section | mỗi key có ≥1 TC thật **và** ngược lại |

**Vì sao không chia theo bước:** mọi checkpoint (`CP-1`…`CP-4`) sống trong **context**, không để lại byte nào trên đĩa ⇒ chia theo bước thì mọi dòng bật `[x]` cùng lúc, sổ không nói được gì. Bằng chứng duy nhất còn lại của `CP-2` là section `## Sổ derive`, của `CP-1`/`CP-3` là `check-ledger ✓` — đã gói vào hai dòng trên.

**Bullet trần** cho thứ không tick được: `### Gaps` + TC mang nhãn `blocked-by-spec` / `chờ xác nhận` → `- ⚠ {n} item blocked-by-spec → 👤 BA`. Chúng chỉ người đóng được, nên không cho checkbox.

**Cấm đưa vào sổ:**

- `CP-1`…`CP-4` thành 4 dòng (xem trên).
- Một dòng / frd item — item `blocked-by-spec` sẽ đứng `[ ]` **mãi mãi**.
- Một dòng / TC — tập TC là **sản phẩm** của skill này, và tập dùng cho retrofit là của `test-exec`.
- `status: approved` làm điều kiện tick — `draft` là kết thúc **bình thường** (skill không tự approve).
- `versions.{scope}` bump làm điều kiện tick — mode `reconcile` không đổi scope nào thì `versions` **giữ nguyên** mà file vẫn đúng.
- Dòng `step=` — biên bản là của orchestrator.

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Có frd rồi, viết test-design sau cũng được" | Test coverage không tracked = không biết feature đóng được chưa. test-design làm song song với frd, không sau. |
| "Rebuild test-design nhanh hơn cập nhật manual" | Sai kể từ 018 — mode `reconcile` (mặc định) đã derive lại **toàn bộ** từ frd mà vẫn giữ ID. `--rebuild` chỉ còn dùng khi muốn cố ý vứt ID cũ. |
| "TC này không khớp Key nào, chắc rác, xoá đi" | `[REMOVE]` **mặc định GIỮ**. TC không map được có thể là TC QC tự viết → đề xuất `manual::{slug}`, không xoá. |
| "Không chắc có phải 2 điều kiện không, thôi bỏ bảng quyết định" | Ngược lại (D6): **dựng**, rồi ghi `Gaps` là suy luận cần QC xác nhận. Thừa thì xoá được; thiếu thì không ai biết mà xoá. |
| "Chờ QC confirm rồi mới ghi file" | Ghi thẳng `status: draft` — `draft` chính là "chưa ai duyệt". Chờ confirm để **ghi** làm hỏng trọn lượt headless (đo: 2/9). |
| "Brownfield không cần test-design, đã có test code" | Test code là HOW. test-design là WHAT — declarative TC list để track coverage vs frd. Hai layer khác nhau. |

## Red Flags

- Traceability Matrix có ❌ mà không có Gaps section giải thích
- Priority hàng loạt P1 — chưa override theo defaults
- Test Strategy / Test Data Requirements toàn `TBD` sau khi QC review xong
- Overwrite test-design.md hiện có mà không cảnh báo về ID break
- **VR có ngưỡng mà không có TC accept sát biên** — chỉ test phía reject thì code gõ `<` thay `<=` vẫn xanh
- TC ở Validation/Functional để trống `Technique`
- TC Validation viết dạng block mà **thiếu** một trong `TC ID`/`Covers`/`Field`/`Input`/`Expected`/`Polarity` — `/spec-test-exec` sẽ bỏ qua nó im lặng
- **Thấy ≥2 điều kiện độc lập mà KHÔNG dựng bảng quyết định** — 027 D6 đã đảo mặc định: dựng trước, hỏi để bỏ
- Lượt chạy **kết thúc bằng một câu hỏi** và không ghi được file nào — mọi điểm rẽ phải có nhánh mặc định (D12)
- `Expected` dạng **"400 hoặc 404"** / "báo lỗi hoặc bỏ qua" — oracle rời rạc, test xanh cả khi code sai (C8)
- `Expected` dựa vào state mà **không `Step`/`Precondition` nào dựng** (C7)
- Artifact **không có section `## Sổ derive`** sau khi chạy skill này — CP-2 đã bị bỏ qua
- Cột `đã sinh` của sổ **chép y hệt** cột "công thức đòi" — sổ thành nghi lễ, không ai đếm lại
- `Then` liệt kê nhiều **bề mặt quan sát** mà chỉ ra 1 TC (D7)
- Mệnh đề có nhiều phân vùng **accept** mà chỉ ra 1 TC accept — công thức `1 + n` cũ (D1)
- Sinh TC cho ô transition / cột bảng mà frd chưa định nghĩa expected (**bịa oracle**) thay vì ghi `Gaps` + `blocked-by-spec`
- `enum` tĩnh (`enum<VN|EN>`) bị dựng state machine
- **TC khớp `Key` mà ID đổi** — dấu hiệu đang regenerate thay vì reconcile
- `id_counters` **giảm** sau một lần chạy, hoặc ID vừa retire được cấp lại cho TC mới
- TC `manual::*` biến mất / bị sửa sau reconcile
- `versions.{scope}` **giảm** hoặc bị set về `1` — làm `/spec-test-exec` im lặng không reconcile
- `Key` chứa **giá trị dữ liệu** (`::256`) thay vì ngữ nghĩa ca (`::max+1`) — QC sửa dữ liệu là khoá vỡ

## Verification

**Bốn checkpoint đã chạy TẠI CHỖ, không dồn về đây (027 D11).** Cổng cuối chỉ còn ba việc: chạy checker, xác nhận CP đã qua, và **không** tự đổi status.

| CP | sau bước | kiểm gì | máy kiểm? |
| --- | --- | --- | --- |
| **CP-1** | 4.2 sàn 1:1 | mọi frd item đã được neo | ✅ |
| **CP-2** | 4.3 hệ số nhân | mỗi item có `Technique` + số TC công thức đòi → điền **sổ derive** | ⚠ agent suy, phải ghi ra số |
| **CP-3** | sau mỗi section TC | số TC thật == số ghi ở CP-2; + C7 (`Expected` chạy tới được) + C8 (oracle tất định) | ✅ |
| **CP-4** | Bước 5 | reconcile · `id_counters` · `versions` · `template_version` | ✅ |

**Trước khi in kết quả:**

- [ ] **CP-1…CP-4 đã chạy ngay tại bước của nó** — không có CP nào bị dời xuống đây
- [ ] `npx spec-lite check-ledger .specs/tests/{F-XXX}-{slug}/test-design.md` in **`✓ SỔ KHỚP`** (`⊘ SKIP` cũng exit 0 — không nhận)
- [ ] Đã ghi lại `.progress/design.md` theo section `## Đơn vị tiến độ`: 4 dòng kiểm chất lượng artifact + bullet trần `- ⚠ {n} item blocked-by-spec → 👤 BA` nếu có; **không** chia theo `CP-1`…`CP-4`, **không** một dòng / TC
- [ ] Cổng chốt của reference đạt: **C1** (100% TC Validation+Functional có `Technique`) · **C2** (ngưỡng có TC accept sát biên) · **C3** (vòng đời có bảng ST) · **C4** (≥2 điều kiện có bảng DT) · **C5** (Flow có nhánh phụ + ngoại lệ nếu frd ghi) · **C6** (TC `EG` có trích nguồn) · **C7** · **C8**
- [ ] Ô/cột/nhánh thiếu oracle → `Gaps` tầng B + `blocked-by-spec`, KHÔNG có TC nào tự chế expected
- [ ] Mỗi TS/TC có `Key`; `Key` **tất định** — chạy 2 lần liên tiếp trên frd không đổi ⇒ `diff -q` giữa hai bản **im lặng**
- [ ] Nếu overwrite: `test-design.md.bak.{timestamp}` đã được tạo
- [ ] File ghi ở `status: draft` — **KHÔNG** tự chuyển `draft → approved` (điểm rẽ 5). `reconcile` có delta trên artifact `approved` ⇒ đã **hạ về `draft`** + in lý do; delta = 0 ⇒ giữ `approved`
- [ ] **8/8 điểm rẽ** đi đúng nhánh mặc định — không lượt nào dừng chờ người trả lời

**Chuyển `draft → approved`** (việc của QC, không phải của skill): `check-ledger` in `SỔ KHỚP` · C1–C8 đạt · placeholders đã fill · danh sách `chờ xác nhận` đã xử.
