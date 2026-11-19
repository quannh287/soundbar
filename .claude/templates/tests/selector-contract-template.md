---
id: selector-contract-{feature}
type: selector-contract
status: draft
owner: "{DEV / QC}"
feature_id: "{Feature ID}"
template_version: 5
migrations:
  - to: 1
    note: "baseline"
  - to: 2
    note: "024: anchor đổi Flow → TC; contract sinh ở build-time bởi /build (+2 skill retrofit), không còn derive từ `frd > User Flows` lúc /spec-frd. Field version thôi INERT — nó là DETECTOR để writer biết artifact đang ở hình dạng nào (xem 024 D18); transformer nằm ở writer, KHÔNG ở /artifact-migrate (migrate không đọc được test-design để suy cột TC)."
    update:
      - section: "Testid Contract"
        change: "cột `Flow › Step` → `TC` — TC ID phân tách bằng ` · `, là BẰNG CHỨNG (≥1 TC) chứ không phải danh sách đầy đủ. Giá trị `Flow › Step` cũ KHÔNG giữ lại (trace tới flow bỏ có chủ ý — D2). TRANSFORM = đổi header + stamp version, mọi row mang sang đặt `TC` = `— (legacy)`; KHÔNG derive lại cột TC hàng loạt (cột TC không tất định nên diff sau nâng cấp không kiểm được — D18 lazy fill). Row legacy điền dần khi writer chạm element đó."
  - to: 3
    note: "026: contract thành SỔ ĐĂNG KÝ PHÍA CUNG. /build không đọc test-design nữa — luật gắn testid hai khoản (tương tác | hiển thị thứ spec.md nói người dùng thấy), nguồn là DOM vừa viết + AC/VR trong spec.md. Bỏ gate test-design ở /plan + /build. Bỏ tách 'gắn testid ⊋ ghi contract': testid nào vào code thì vào contract. Kiểm thành HAI chiều."
    update:
      - section: "Testid Contract"
        change: "cột `TC` đổi NGỮ NGHĨA: từ điều kiện tồn tại của row (≥1 TC bắt buộc, rỗng = row thừa) → ANNOTATION do phía ĐỌC điền (/spec-test-exec lúc viết POM, retrofit lúc backfill). Rỗng là HỢP LỆ, không phải nợ. TRANSFORM = stamp version + giữ nguyên MỌI giá trị TC đang có; `— (legacy)` và `—` đều thành `` (rỗng) vì không còn cần phân biệt ba trạng thái. KHÔNG derive lại cột TC hàng loạt (D18 lazy fill)."
      - section: "Notes"
        change: "bỏ mục 'element giữ row dù TC hiện chưa phủ → ghi rõ lý do' — row không TC là bình thường, không cần lý do."
  - to: 4
    note: "Thêm nhánh MOBILE song song web: § Maestro (global registry) cho platform=react-native | flutter. Registry per-feature hay global KHÔNG cố định theo tên platform mà theo HARNESS e2e — Maestro đứng ngoài runtime app (đọc OS accessibility tree, không phân biệt RN/Flutter) nên đối chiếu 2 chiều qua MỘT file GLOBAL ở repo root (vd .maestro/selector-contract.md); file per-feature khi đó CHỈ REFERENCE. Thêm bucket Reserved cho identifier /build gắn trước khi flow nào dùng (e2e viết sau ở /spec-test-retrofit-e2e) — cần chỗ đứng KHÔNG bị harness tính là id chết. Cú pháp gắn + quy ước tên mỗi platform gom về references/testid-conventions.md (nguồn duy nhất, không lặp ở đây). Bảng Maestro dùng cột TC như bảng web (không dùng Flow › Step — trace tới flow đã bỏ có chủ ý ở v2/D2)."
    add: ["Maestro (global registry)", "Maestro (global registry) > Reserved"]
    update:
      - section: "Testid Contract"
        change: "đổi tiêu đề thành 'Testid Contract *(platform=web-react)*' — bảng per-feature giờ chỉ áp cho web-react; react-native/flutter đọc § Maestro. Thêm field `Platform` vào dòng meta đầu body ({web-react | react-native | flutter}) để writer biết route nhánh nào. Nội dung/cột của bảng KHÔNG đổi."
  - to: 5
    note: "Mobile cần MỘT handle ở HAI tầng hiện thực (Semantics(identifier:) cho Maestro — nó không thấy Key; Key cho widget test) nhưng template chỉ có một khái niệm handle, nên registry trôi thành hai sổ: đo thật ở GAL-Mobile trước khi gộp là 9 file per-feature ghi Key + 1 file .maestro ghi identifier, 7 handle trùng mà không ai biết là một. Thêm cột Tầng vào bảng Identifiers của nhánh Maestro để nói rõ handle nào sống ở tầng nào, cộng luật sở hữu cho element dùng bởi nhiều feature (một row ở feature sở hữu + con trỏ, không copy row — copy làm git grep ra hai định nghĩa và sửa một bên là trôi bên kia)."
    update:
      - { section: "Maestro (global registry)", change: "thêm cột 'Tầng' vào bảng Identifiers (identifier | Key | testID | tổ hợp) + luật một-row-ở-feature-sở-hữu cho element nhiều feature dùng; bảng web-react KHÔNG đổi" }
referenced_by:
  - 02-artifacts.md > 2.3 Feature level (test-side) + 4. Test-side plane > selector-contract.md
  - references/testid-conventions.md > quy ước đặt tên + platform profile (nguồn chi tiết cú pháp gắn/query)
  - skills/build/SKILL.md > Process > task UI (gắn testid + merge row)
  - skills/spec-test-retrofit-functional/SKILL.md > Process > Bước 3b (backfill + gắn testid)
  - skills/spec-test-retrofit-e2e/SKILL.md > Process > Bước 3b (tái dùng + bổ sung row)
  - skills/spec-test-exec/SKILL.md > Process > Bước 5 (testid cho POM automation)
  - templates/tests/test-exec-e2e-template.md > §1 Context (Testid source) + §7.1 Page Object Index
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/selector-contract.md.

SELECTOR CONTRACT — hợp đồng `data-testid` giữa CODE (FE gắn) và AUTOMATION TEST (QC/SE dùng).
Đây là MỘT loại trong họ "*-contract.md". Sau này có thể thêm api-contract.md, seed-contract.md…
Mỗi loại = file riêng (một nguồn, một consumer rõ ràng) — KHÔNG gộp chung một contract.md.

SINH Ở BUILD-TIME — SỔ ĐĂNG KÝ PHÍA CUNG (.docs/026):
  Đây là danh sách MỌI data-testid mà /build gắn vào code. Nguồn = DOM vừa viết + AC/VR trong spec.md.
  KHÔNG đọc test-design.md — phase Build (/plan · /build · /review-integration) chỉ ăn spec.md + tech.md.
  Writer: /build. Brownfield/retrofit: /spec-test-retrofit-functional + -e2e (cũng là lúc chạm code).
  KHÔNG sinh ở /spec-frd hay /spec-brownfield-feature — lúc đó UI chưa tồn tại, mọi element decomposition
  đều là phỏng đoán.

ĐIỀU KIỆN GẮN TESTID — HAI KHOẢN, cả hai từ input của /build:
  (1) element TƯƠNG TÁC được — button, input, select, checkbox, link điều hướng.
  (2) element HIỂN THỊ THỨ spec.md NÓI NGƯỜI DÙNG THẤY — thông báo lỗi, bộ đếm, nhãn trạng thái, badge,
      toast, dòng danh sách, trạng thái rỗng, vỏ render theo điều kiện.
  Khoản 2 là NỬA ORACLE — chỗ test đọc để biết đúng/sai. Bỏ nó thì contract chỉ có nửa `action`, và ④
  phải quay lại sửa code sản phẩm để bù. Mỗi row khoản 2 phải trỏ được về MỘT CÂU AC/VR cụ thể; không
  trỏ được ⇒ KHÔNG gắn. Đó là cách chặn contract trôi thành ảnh chụp DOM.
  PHẢN VÍ DỤ (không gắn): <div> layout, wrapper flex/grid, element thuần trang trí.

KHÔNG derive từ frd > User Flows (flow mô tả HÀNH TRÌNH, không mô tả MÀN HÌNH), cũng KHÔNG từ
test-design.md (artifact của QC ở ①, sinh song song — buộc ③ đọc nó là biến hai nhánh song song thành
tuần tự).

LUẬT GHI:
  - MERGE, key = `testid`. Chỉ thêm/sửa row của element vừa chạm; KHÔNG rewrite cả file (feature build
    qua nhiều integration → contract tích luỹ). Row bị xoá CHỈ KHI element bị gỡ khỏi code.
  - TESTID NÀO VÀO CODE THÌ VÀO CONTRACT — một luật, không tách. /build ghi row cho MỌI testid nó gắn.
  - Cột TC để RỖNG khi /build tự đặt tên. /build không biết TC nào tồn tại; phía ĐỌC điền (xem dưới).

HAI LOẠI ROW SỐNG CHUNG (.docs/034 D10) — khác nhau ở AI ĐẶT TÊN và cột TC có sẵn hay không:

  (a) OUTER TEST ĐẶT HÀNG — writer /spec-test-functional --phase=write, ở bước 2 của một Slice,
      TRƯỚC khi component tồn tại. Cột TC ĐIỀN NGAY: TC chính là lý do row tồn tại.
      Chỉ áp cho TC tier fe:component.
  (b) LUẬT GẮN TESTID SẴN CÓ — writer /build bước 2c, khoản 1 + khoản 2 dưới. Cột TC RỖNG.

  /build bước 2c phải TRA CONTRACT TRƯỚC khi tự đặt tên: chuỗi nào loại (a) đã khai thì component
  gắn ĐÚNG chuỗi đó; chỉ tự đặt tên cho element còn lại. Nghĩ tên mới cho element đã có row là
  làm hai bên lệch, và outer test sẽ đỏ vì testid chứ không vì hành vi.

  TRẠNG THÁI "ĐÃ KHAI, CHƯA CÓ CODE" KHÔNG SỐNG QUA MỘT COMMIT: kiểm hai chiều ở cuối slice gác,
  slice tắc thì /build không tick không commit. Đừng thêm bucket riêng cho nó ở nhánh web.
  (Nhánh Maestro có bucket Reserved cho ca NGƯỢC LẠI — id có trong code mà chưa flow nào dùng.)
  - Contract commit CÙNG COMMIT với component.

CỘT TC LÀ ANNOTATION:
  - Ai ĐỌC contract thì điền: /spec-test-exec lúc viết POM, /spec-test-retrofit-* lúc backfill — điền TC
    ID của TC vừa dùng testid đó (merge, không clobber).
  - RỖNG LÀ BÌNH THƯỜNG: nghĩa là "chưa ai test element này". Không phải row thừa, không phải nợ, không
    cần lý do, không cần whitelist.
  - Giữ cột vì nó trả lời được "testid này có ai dùng chưa" — đầu vào để dọn testid chết, và để QC thấy
    chỗ nào chưa phủ.

KIỂM HAI CHIỀU (cả hai đều là bất biến thật):
  (1) contract ⊆ code — mọi testid khai ở đây phải grep được trong code (không row ma).
  (2) code ⊆ contract — mọi data-testid trong source phải có row ở đây (không testid vô danh).
  Chiều (2) thay chỗ luật cũ "row phải trỏ ≥1 TC": nó CƠ HỌC, không phụ thuộc artifact do người khác
  giữ, và làm testid chết HIỆN RA thành row TC rỗng thay vì vô hình.
  Kit KHÔNG ship script (stack-agnostic). Hai chỗ grep: /build cuối task (phạm vi file vừa chạm),
  /spec-test-exec trước khi điền POM (cả file; thiếu → BÁO, không tự đặt testid mới).

ELEMENT DÙNG CHUNG NHIỀU FEATURE: xuất hiện ở CẢ HAI contract, GIỮ NGUYÊN tên gốc (không đổi prefix theo
feature đang dùng). Contract là hợp đồng của MỘT BỘ TEST, không phải sổ đăng ký testid toàn hệ.

Phục vụ test automation (harness duy nhất của test-exec). TC visual (Autoable=NO) kiểm bằng mắt,
không thuộc test-exec — KHÔNG cần testid, bỏ qua file này.

THUẦN MÔ TẢ (main spec): file này khai báo testid CẦN CÓ, KHÔNG track trạng thái implementation
("FE gắn chưa" thuộc tầng code/execution — plan/todo + test-exec, không phải ở đây).
LOCATOR THÔ cũng KHÔNG ở đây: file chứa GIÁ TRỊ testid (cái handle ổn định), KHÔNG chứa biểu thức
`page.getByTestId(...)` — biểu thức locator sống trong POM `.ts` ở repo code thật.

NGOÀI scope /artifact-audit + /artifact-migrate (015 §3B) nhưng `template_version` KHÔNG còn inert
(024 D9/D18): nó là DETECTOR hình dạng. Writer (/build 2c · retrofit-functional 3b · retrofit-e2e 3b)
so version artifact vs template rồi:
  - khớp                        -> merge row như bình thường
  - lệch + shape ĐÃ khớp        -> CHỈ stamp version, không đụng dòng nào trong bảng
  - lệch + shape cũ             -> nâng cấp cả file (đổi header, đổi cột, stamp version) — GIỮ mọi giá
                                   trị TC đang có, lazy fill phần trống
Bump `template_version` + ghi `migrations` khi đổi structural template này (như template main).
KHÔNG bump khi chỉ thêm/sửa row trong artifact — đó là content. Change history = git.

PLATFORM: registry per-feature hay global KHÔNG cố định theo tên platform — phụ thuộc HARNESS e2e thật sự
dùng (references/testid-conventions.md §3). web-react (mọi harness) dùng registry PER-FEATURE (file này tự
trị): harness chạy trong-runtime (DOM), query trực tiếp data-testid, không cần file trung gian. flutter VÀ
react-native khi e2e bằng MAESTRO (§2b) thì khác — Maestro đứng ngoài runtime app (đọc qua OS accessibility
tree, không phân biệt RN/Flutter) nên đối chiếu 2 chiều qua MỘT file GLOBAL ở repo root (vd
.maestro/selector-contract.md), dùng chung mọi feature: harness (vd tool/e2e.sh) cần đúng MỘT nguồn để check
id-dùng-trong-flow ↔ id-khai-trong-bảng. Khi đó file per-feature này CHỈ REFERENCE — trỏ tới file global +
liệt kê đúng identifier feature này dùng — và identifier mới PHẢI ghi vào file global TRƯỚC (nguồn đối chiếu
thật), rồi đồng bộ row vào đây trong CÙNG commit. Giữ per-feature reference để không mất traceability
(feature X dùng identifier nào) mà cũng không tạo hai nguồn cạnh tranh.
-->

# Selector Contract: {Feature Name}

**Feature**: {F-XXX} | **Platform**: {web-react | react-native | flutter} | **Nguồn**: DOM `/build` vừa viết + AC/VR trong `spec.md` (phía cung) | **Status**: {status}

> **Sổ đăng ký** mọi `data-testid` trong code của feature này — hợp đồng giữa FE (gắn lúc code) và POM (dùng lúc viết test), nguồn DUY NHẤT nên hai bên không thể lệch.
> **Ghi ở build-time** bởi `/build` (hoặc skill retrofit), **merge** theo key `testid` — không rewrite cả file. **Không** đọc `test-design.md` (`.docs/026`).
> **Gắn khi:** (1) element **tương tác** được, hoặc (2) element **hiển thị thứ `spec.md` nói người dùng thấy** — lỗi, bộ đếm, nhãn trạng thái, badge, toast, dòng danh sách, trạng thái rỗng, vỏ điều kiện. Khoản 2 phải trỏ được về một câu AC/VR cụ thể.
> **Quy ước tên** (02-artifacts.md §2.3): `{feature-slug}-{element}[-{qualifier}]` — vd `order-customer`, `order-submit`, `order-row-{id}`.

> **Route theo platform:** `web-react` → § Testid Contract dưới (registry per-feature, file này tự trị). `react-native` / `flutter` → § Maestro (registry global, file này chỉ REFERENCE) — cả hai e2e bằng Maestro, chỉ khác cú pháp gắn (`testID` vs `Semantics(identifier:)`); xem `references/testid-conventions.md` §2-3.

## Testid Contract *(platform=web-react)*

> Mỗi row = một element mà `/build` đã gắn `data-testid`. **Kiểm hai chiều:** mọi row phải grep được trong code, **và** mọi `data-testid` trong code phải có row ở đây.

| **testid** | **Element** | **TC** | **Interaction** |
|---|---|---|---|
| `{slug}-{element}` | {mô tả element, vd: input tên khách} | `TC-F{NNN}-001` | action |
| `{slug}-{element}` | {vd: badge đếm đơn} | | assert |

> **TC**: **annotation** do phía **đọc** điền — `/spec-test-exec` lúc viết POM, retrofit lúc backfill. `/build` để **rỗng** vì nó không biết TC nào tồn tại. **Rỗng là bình thường** (chưa ai test element này) — không phải row thừa, không phải nợ, không cần lý do.
> **Interaction**: `action` (click/fill/select — test tương tác) · `assert` (đọc/verify — test khẳng định) · `nav` (điều hướng).
> **Element**: mô tả thứ handle **THẬT SỰ hiển thị**, kèm **nhánh fallback** nếu có — không phải ý định thiết kế, không suy từ tên handle. ❌ `Mã nhân viên ở header` · ✅ `Subtitle header: roleName nếu có, mã NV là fallback (profile_header.dart:46)`. **Không lưới nào kiểm cột này** (mọi gate chỉ kiểm handle tồn tại), nên mô tả sai là lỗi im lặng dẫn thẳng tới **oracle sai** — và sai *không ổn định*, vì nhánh fallback làm nó xanh với fixture này, đỏ với fixture khác. Row có oracle đọc **nội dung** (`text:`/`contains`) ⇒ ghi thêm **nguồn dữ liệu** (field + `file:dòng`). Chi tiết: `references/testid-conventions.md` §3d.

## Maestro (global registry) *(platform=react-native | flutter)*

> **File GLOBAL là nguồn thật**: `{mobile-global-contract-path}` (vd `.maestro/selector-contract.md` ở repo root) — harness (vd `tool/e2e.sh`) đối chiếu 2 chiều đúng file đó. File per-feature này **KHÔNG tự trị** — chỉ liệt kê lại đúng subset identifier feature này dùng, để traceability (feature ↔ identifier) mà không tạo nguồn thứ hai.
>
> Cú pháp gắn: platform=react-native → prop `testID="<id>"`; platform=flutter → bọc `Semantics(identifier: '<id>', child: ...)` (giữ `Key` cũ nếu có, không cần cùng giá trị) — chi tiết + quy tắc screen marker/input/button/nav/toast → `references/testid-conventions.md` §2b-2c. KHÔNG target bằng chuỗi qua i18n/localization (đổi wording vỡ flow) — GUARD tương đương GUARD-014.
>
> **Identifier gắn ở `/build` nhưng chưa flow nào dùng** (bình thường — e2e viết sau ở `/spec-test-retrofit-e2e`) → liệt ở bucket **Reserved** dưới, KHÔNG vào bảng Identifiers (harness đối chiếu 2 chiều sẽ coi id trong bảng mà không flow nào dùng là "id chết" — `references/testid-conventions.md` §5). Khi một flow bắt đầu dùng id đó → **promote**: xoá khỏi Reserved, thêm row vào bảng.

| **Identifier dùng bởi feature này** | **Widget/Element** | **File code** | **Tầng** | **TC** |
|---|---|---|---|---|
| `{screen-or-domain}-{element}` | {mô tả} | `{path/to/widget.dart}` | `identifier` + `Key` | `TC-F{NNN}-001` |
| `{screen-or-domain}-{element}` | {chỉ widget test dùng} | `{path/to/widget.dart}` | `Key` | `TC-F{NNN}-002` |

> **Tầng** — MỘT handle, HAI tầng hiện thực (`references/testid-conventions.md` §2d): `identifier` = `Semantics(identifier:)`, thứ Maestro đọc (nó **không thấy `Key`**) · `Key` = `Key('<handle>')`, thứ widget test query bằng `find.byKey` · `testID` (react-native, cả hai tầng). Handle gắn ở cả hai tầng ⇒ `identifier` + `Key`. **Không** tách thành hai file registry — đó là cách 7 handle ở GAL-Mobile trùng nhau mà không ai biết là một.
>
> **Element dùng bởi nhiều feature** ⇒ một row ở feature **sở hữu**, feature khác **trỏ sang** (`→ xem F-0XX`), không copy row (§4b).

### Reserved *(nếu có)*

> Gắn trong code, **chưa** flow nào dùng — bullet list (KHÔNG phải table row, để harness parse-theo-bảng của file GLOBAL không đọc nhầm thành id chết).

- `{screen-or-domain}-{element}` — `{path/to/widget.dart}`, dự kiến dùng ở {story/task nào}

> Thêm/đổi identifier mới cho feature này → ghi vào **file global trước** (nguồn đối chiếu thật của harness), rồi đồng bộ row vào bảng trên **trong cùng commit**. Đừng để hai file lệch nhau.

## Notes *(nếu có)*

> Ghi chú để DEV + QC thống nhất các trường hợp quy ước chưa phủ:
> - Element mơ hồ (vd hai nút cùng nhãn "Lưu") → cần qualifier phân biệt.
> - List động → testid kèm id: `{slug}-row-{id}`.
> - Element dùng chung với feature khác → ghi nguồn gốc (`auth-logout` thuộc `F-001`, row này là bản sao cho bộ test của feature hiện tại).

<!-- KHÔNG có section Change History: selector-contract là test-side non-versioned (015 §3B) — "đổi gì khi nào" = git log/diff (commit sau khi re-derive/backfill). Thống nhất với 01-architecture.md §7. -->
