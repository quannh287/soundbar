# Testid Conventions — quy ước testid/identifier đa platform

> Dùng cùng `selector-contract.md` (`templates/tests/selector-contract-template.md`, `02-artifacts.md` §2.3) và
> 3 skill retrofit (`references/test-core.md` §2b/§3b). File này là **nguồn DUY NHẤT** cho quy ước đặt tên +
> cách gắn/query testid theo từng platform — skill/template khác **link vào đây**, không lặp lại pattern.

## Mục lục

- [1. Quy ước đặt tên (chung mọi platform)](#1-quy-ước-đặt-tên-chung-mọi-platform)
- [2. Platform profile](#2-platform-profile)
  - [2a. web-react](#2a-web-react)
  - [2b. react-native](#2b-react-native)
  - [2c. flutter](#2c-flutter)
  - [2d. Mobile: MỘT handle, HAI tầng hiện thực](#2d-mobile-một-handle-hai-tầng-hiện-thực--không-phải-hai-registry)
- [3. Registry: per-feature vs global](#3-registry-per-feature-vs-global)
- [3b. Mục ngoài viewport KHÔNG có node semantics (flutter/Maestro)](#3b-mục-ngoài-viewport-không-có-node-semantics-flutterMaestro)
- [3d. Cột `Element`: mô tả thứ handle THẬT SỰ hiển thị](#3d-cột-element-mô-tả-thứ-handle-thật-sự-hiển-thị-không-phải-ý-định-thiết-kế)
- [3c. Hai hình dạng registry — phép kiểm hợp với mỗi hình dạng](#3c-hai-hình-dạng-registry--và-phép-kiểm-hợp-với-mỗi-hình-dạng)
- [4. Additive-only gate](#4-additive-only-gate)
- [4b. Element dùng bởi nhiều feature — một row ở feature SỞ HỮU](#4b-element-dùng-bởi-nhiều-feature--một-row-ở-feature-sở-hữu)
- [5. Bucket "Reserved" — gắn trước, flow dùng sau](#5-bucket-reserved--gắn-trước-flow-dùng-sau)

---

## 1. Quy ước đặt tên (chung mọi platform)

```
{scope}-{element}[-{qualifier}]
```

kebab-case, 3 phần:

- **`{scope}`** — namespace để không đụng feature/màn khác.
  - Registry **per-feature** (web-react, react-native — xem §3): `{feature-slug}` (khớp `.specs/tests/{F-XXX}-{slug}/`).
  - Registry **global** (flutter/Maestro — xem §3): `{screen-or-domain}` (tên route/domain, vd `login`, `nav`, `profile`) — feature-slug/`F-XXX` không có ý nghĩa ở một file dùng chung toàn app; đặt theo domain đọc rõ hơn khi liệt kê hàng trăm identifier cùng bảng.
- **`{element}`** — vai trò của element, không phải loại widget (`submit`, `password`, `count`, `logout`), KHÔNG dùng nhãn UI copy (đổi text không vỡ id).
- **`{qualifier}`** *(tuỳ chọn)* — phân biệt khi `{scope}-{element}` không đủ duy nhất: list động (`row-{id}`), biến thể (`snackbar-{variant}`), trùng nhãn (`confirm`).

Ví dụ: `order-submit`, `order-row-{id}`, `login-password`, `snackbar-error`.

**Handle ĐỘNG — cú pháp `{camelCase}` + khớp theo prefix.** Handle mà phần cuối chỉ biết lúc chạy thì khai trong contract bằng **một** placeholder `{camelCase}` ở cuối: `history-calendar-cell-{day}`, `quen-cham-cong-form-loai-{wireValue}`. Luật khớp của checker: **strip `{...}` về prefix rồi khớp prefix** — flow dùng `history-calendar-cell-${E2E_DAY}` hay `...-loai-QUEN_IN` đều tính là đã khai. Không có luật này thì checker so nguyên chuỗi và báo nhầm handle đã khai là chưa khai (đo thật: **5** handle ở GAL-Mobile).

> **Maestro nội suy được `${VAR}` do RUNNER truyền, không nội suy được giá trị runtime của app.** Đó là hai chuyện khác nhau: flow YAML tĩnh nên không đọc được id do app sinh ra lúc chạy, nhưng runner **truyền env var vào lúc launch** thì được (`E2E_DAY=17 maestro test ...`, xem `tool/e2e.sh` forward `${!E2E_*}`). Vậy handle động vẫn dùng được ở Maestro **miễn giá trị biết trước khi flow chạy** (seed cố định, ngày tính từ lịch, enum nghiệp vụ) — chỉ id do app sinh runtime là không.

⚠ **`{qualifier}` templated nội suy TRONG CODE TEST chỉ áp khi harness tính locator ở RUNTIME** — Testing Library/Playwright (web-react), RNTL (react-native, tầng component/unit) đều viết được `` `order-row-${orderId}` `` ngay trong code test. **Maestro thì KHÔNG** — flow e2e là YAML **tĩnh**, không nội suy runtime — và Maestro là e2e harness cho **cả react-native lẫn flutter** (không phải chỉ flutter). Feature nào e2e bằng Maestro (bất kể RN hay Flutter) → không target theo id list động được; thay vào đó target theo **dữ liệu seed cố định** (id/tên đã biết trước khi flow chạy) hoặc theo **text nội dung nghiệp vụ** đang assert (số liệu, tên user) — xem flow thật của GAL-Mobile (Flutter+Maestro): không flow nào target list item theo qualifier động, chỉ theo widget cố định (`login-username`, `nav-profile`...).
⚠ Ký tự hợp lệ cho registry **global** (Maestro — §3) thường bị regex của harness giới hạn chặt hơn `{scope}-{element}[-{qualifier}]` chung — vd `tool/e2e.sh` của GAL-Mobile chỉ nhận `[a-z0-9-]+` (không hoa, không `_`, không `{}`). Kiểm quy tắc thật của harness trước khi đặt tên.

**Bất biến chung:**
- ID là **giá trị handle ổn định**, KHÔNG đổi theo UI copy/i18n — không target bằng chuỗi qua `AppLocalizations`/`t()`/locale khác (đổi wording/thêm locale vỡ test).
- ID sống trong đúng MỘT registry (per-feature hoặc global, §3) — không tự đặt id rời rạc ngoài registry đó.
- Additive-only khi backfill vào code cũ (§4) — gắn thêm thuộc tính, KHÔNG đổi cấu trúc/hành vi.

---

## 2. Platform profile

Mỗi platform có **cách gắn** (annotate trong code) và **cách query** (test/harness đọc) khác nhau; quy ước đặt tên ở §1 giữ nguyên xuyên platform.

### 2a. web-react

| | |
|---|---|
| Gắn | thuộc tính `data-testid="{id}"` trên element JSX |
| Query | Testing Library `getByTestId(id)` · Playwright `page.getByTestId(id)` |
| Registry | **per-feature** (`.specs/tests/{F-XXX}-{slug}/selector-contract.md`) |
| Nhìn thấy bởi | DOM — mọi harness đọc DOM (RTL, Playwright, Cypress) đều query trực tiếp, không cần registry trung gian ngoài spec |

```tsx
<button data-testid="order-submit" onClick={handleSubmit}>Đặt hàng</button>
```

### 2b. react-native

| | |
|---|---|
| Gắn | prop `testID="{id}"` trên component RN (`View`/`Pressable`/`TextInput`…) |
| Query (component/unit test) | RNTL `getByTestId(id)` |
| Query (e2e) | **Maestro** `id: "{id}"` trong flow YAML — đọc qua accessibility tree native (Android `resource-id`/iOS `accessibilityIdentifier`, chính là giá trị `testID` compile xuống), y hệt cách Maestro đọc Flutter |
| Registry | **global** — cùng lý do + cùng ràng buộc như flutter §2c/§3/§5 (flow e2e tĩnh, không dynamic qualifier §1, cần bucket Reserved §5) |

```tsx
<Pressable testID="order-submit" onPress={handleSubmit}>
  <Text>Đặt hàng</Text>
</Pressable>
```

react-native + Maestro áp toàn bộ ràng buộc của §2c/§3/§5 dành cho "Maestro" — Maestro không phân biệt RN/Flutter, cùng đọc qua OS accessibility tree. Khác biệt DUY NHẤT giữa RN+Maestro và Flutter+Maestro là cú pháp gắn (`testID` prop vs bọc `Semantics(identifier:)`) — mọi thứ còn lại (flow e2e tĩnh, registry global, bucket Reserved) giống nhau.

### 2c. flutter

Flutter không có thuộc tính tương đương `data-testid` mà cả widget test lẫn black-box harness (Maestro) cùng đọc được — hai tầng test nhìn hai cây khác nhau, nên **hai cơ chế song song**:

| | |
|---|---|
| Gắn (widget test, trong-runtime) | `Key('{id}')` trên widget — `find.byKey(Key('{id}'))` |
| Gắn (black-box, ngoài-runtime) | `Semantics(identifier: '{id}', child: Widget(...))` — bọc thêm quanh widget cần Maestro thấy |
| Query (widget test) | `flutter_test` `find.byKey(...)` hoặc `find.bySemanticsIdentifier('{id}')` |
| Query (black-box) | Maestro đọc qua accessibility tree (Android `AccessibilityService`) → `id: "{id}"` trong flow YAML |
| Registry | **global**, một file dùng chung toàn app (vd `.maestro/selector-contract.md` ở repo root) — xem §3 vì sao khác web/RN |

```dart
Semantics(
  identifier: 'order-submit',
  child: FilledButton(onPressed: handleSubmit, child: Text('Đặt hàng')),
)
```

`Key` cũ (nếu có) **giữ nguyên** — `Key` và `Semantics(identifier:)` phục vụ hai tầng test khác nhau (widget test vs Maestro), không thay thế nhau, và **không cần mang cùng giá trị string** (vd `Key('register-link')` + `Semantics(identifier: 'login-register-link')` trên cùng widget là hợp lệ — hai namespace độc lập, mỗi bên đặt tên theo quy ước của tầng test dùng nó). Widget layout (`Scaffold`, `Row`...) không tự tạo semantics node cho annotation của chính nó → bọc `Semantics(..., container: true, child: ...)` khi cần mark cả một khối (vd screen marker).

**Chọn `Key` hay `Semantics`?** Cả hai nếu cả widget test và Maestro đều cần chạm element đó; chỉ `Key` nếu chỉ widget test cần; chỉ `Semantics` nếu chỉ Maestro cần (hiếm — thường widget test cũng muốn assert).

**Guard widget test (khuyến nghị bắt buộc — GUARD-014 style):** `Semantics(identifier:)` sống ngoài runtime Flutter — sai/thiếu chỉ vỡ **lặng lẽ** ở Maestro trên thiết bị thật, không có compiler nào bắt. Chống bằng một **widget test riêng** (vd `test/ui/selector_contract_test.dart`) render mỗi screen/component rồi `find.bySemanticsIdentifier('{id}')` phải tìm thấy — biến lỗi "Maestro không thấy identifier" thành unit test đỏ, rẻ hơn debug trên thiết bị nhiều. Gắn identifier mới **PHẢI** kèm thêm assertion mới vào test này trong cùng commit — chạy lại test cũ xanh (§4) là điều kiện *cần* nhưng **không đủ**: test cũ xanh không chứng minh identifier MỚI có mặt, phải có assertion mới cho chính nó.

---

### 2d. Mobile: MỘT handle, HAI tầng hiện thực — không phải hai registry

Cùng **một** chuỗi handle thường phải gắn ở **hai** chỗ khác nhau, cho **hai** loại test:

| Tầng | Gắn bằng | Ai đọc |
| --- | --- | --- |
| e2e (ngoài runtime app) | `Semantics(identifier: '<handle>')` (flutter) · `testID` (react-native) | Maestro — đọc OS accessibility tree, **không thấy `Key`** |
| widget/component test (trong runtime) | `Key('<handle>')` (flutter) · `testID` (react-native) | `find.byKey` · RNTL `getByTestId` |

**Một handle, hai tầng.** `Key` và `Semantics(identifier:)` **không thay nhau** — chúng phục vụ hai tầng test khác nhau, và Maestro chỉ thấy cái sau. Dùng **cùng một chuỗi** cho cả hai để `git grep <handle>` ra mọi chỗ liên quan.

⚠ **Đây là chỗ registry dễ trôi thành HAI sổ.** Đo thật ở GAL-Mobile trước khi gộp: 9 file per-feature ghi `Key`, 1 file `.maestro/` ghi `identifier`, **7 handle trùng nhau** mà không ai biết là một. Contract khai **một** row / handle, và nếu handle chỉ tồn tại ở một tầng thì nói rõ tầng nào (cột `Tầng` của bảng Identifiers) — chứ không tách thành hai file.

## 3. Registry: per-feature vs global

Hai model — chọn theo **harness e2e thật sự dùng**, KHÔNG theo tên platform (web-react/react-native/flutter). Trục quyết định là: harness có đứng **trong** runtime app (query trực tiếp mọi id, không cần bảng đối chiếu) hay đứng **ngoài** runtime qua OS accessibility tree với một script tự đối chiếu 2 chiều toàn app không:

| Model | Harness | Vì sao |
|---|---|---|
| **per-feature** — `.specs/tests/{F-XXX}-{slug}/selector-contract.md` là nguồn thật | web-react bất kỳ harness (RTL/Playwright/Cypress) | Harness chạy trong-runtime (DOM) → query trực tiếp theo id bất kỳ, không cần một bảng đối chiếu toàn app — mỗi feature tự quản danh sách id của mình, không đụng feature khác. |
| **global** — MỘT file ở repo root (vd `.maestro/selector-contract.md`) là nguồn thật; file per-feature (nếu giữ để mirror artifact layout) **chỉ REFERENCE** subset id feature đó dùng | **Maestro** (react-native HOẶC flutter — Maestro không phân biệt hai app-framework này, cùng đọc qua OS accessibility tree) | Maestro đứng ngoài runtime app, đối chiếu 2 chiều id-dùng-trong-flow ↔ id-khai-báo qua **một** script/harness (vd `tool/e2e.sh`) chạy trên toàn app; hai nguồn cạnh tranh (per-feature rời rạc) sẽ khiến harness không biết đối chiếu theo file nào. Identifier mới → ghi vào file global **trước** (nguồn đối chiếu thật), rồi đồng bộ row vào file per-feature (nếu có) **trong cùng commit**. |

> react-native e2e = **Maestro** (registry global, như flutter).

---

## 3b. Mục ngoài viewport KHÔNG có node semantics *(flutter/Maestro)*

Flutter **không phát** node semantics cho phần đã cuộn khỏi màn hình. Maestro báo `Element not found` — **triệu chứng giống hệt sai tên identifier**, nhưng cách xử **ngược nhau**: cuộn tới, chứ không sửa tên.

**Cách phân biệt, một phép kiểm:**

| Dấu hiệu | Kết luận | Xử |
| --- | --- | --- |
| id **có** trong `lib/` (grep ra) mà **vắng** trong dump `screen-hierarchy` | bị **cắt khỏi viewport** | `scrollUntilVisible` tới nó |
| id **không** có trong `lib/` | **sai tên** (hoặc chưa gắn) | sửa tên / gắn identifier |

⚠ **Dùng `scrollUntilVisible`, KHÔNG `extendedWaitUntil`.** Chờ thì nó **không tự hiện** — không có gì đang load, node đơn giản không tồn tại cho tới khi được cuộn vào. `extendedWaitUntil` ở đây chỉ đổi "thất bại nhanh" thành "thất bại sau timeout".

**Cùng chương "cây semantics của Flutter không giống DOM": Flutter GỘP label và value vào một `accessibilityText` bằng `\n`.** Widget có nhãn + giá trị ra cây thành `"Mã nhân viên\nGAL11-000001"`, trong khi `text:` của Maestro khớp **toàn chuỗi** ⇒ `text: "GAL11-000001"` **không khớp** dù giá trị hiện đúng.

- Regex bao cả chuỗi: `text: "(?s).*GAL11-000001.*"` — `(?s)` để `.` khớp cả `\n`.
- Tốt hơn: gắn identifier riêng cho **phần value** rồi assert theo identifier đó, đừng assert theo text gộp.

Đo thật (F-001 GAL-Mobile, tab Hồ sơ): cây chỉ lộ tới `profile-push-notifications-toggle` (`profile_settings_card.dart:50`); `profile-logout` (dòng 121) và mọi mục ở giữa **không có trong cây** — dù identifier gắn đúng.

## 3c. Hai hình dạng registry — và phép kiểm hợp với mỗi hình dạng

| Hình dạng | Bảng chính khai gì | Kiểm ĐÚNG | Kiểm SAI |
| --- | --- | --- | --- |
| **registry-of-all** | **mọi** handle có trong code | `flow ⊆ contract` · `contract ⊆ code` | ❌ `contract ⊆ flow` ("id chết") |
| **registry-of-used** | chỉ handle **flow đang dùng**; phần còn lại ở bucket `Reserved` (§5) | `flow ⊆ contract` · `contract ⊆ code` | ❌ `code ⊆ contract` |

**`flow ⊆ contract` là phép kiểm luôn đúng ở cả hai hình dạng** — mọi handle một flow dùng phải có row. Đây là cái bắt lỗi thật.

**`contract ⊆ code` cũng luôn đúng, và đáng giữ.** Nó bắt handle khai trong contract mà **không tồn tại trong code** — đo thật: `nav-profile` khai trong contract và dùng trong **3 flow**, còn code là `nav-profile-tab`; mọi `tapOn: {id: "nav-profile"}` sẽ chết trên thiết bị. Không phép kiểm nào khác bắt được ca này.

⚠ **`contract ⊆ flow` ("id chết") KHÔNG được suy ra từ tập flow khi contract là registry-of-all.** Phần lớn handle chỉ widget test dùng, không flow Maestro nào chạm — bật lên là **đỏ toàn bộ** (đo thật: 188 handle đã khai). Checker chỉ được kết luận "id chết" nếu contract tự khai mình là registry-of-used.

## 3d. Cột `Element`: mô tả thứ handle THẬT SỰ hiển thị, không phải ý định thiết kế

Mọi phép kiểm quanh contract (`flow ⊆ contract`, `contract ⊆ code`, `code ⊆ contract`, handle-lên-tới-cây-semantics…) chỉ kiểm **sự TỒN TẠI** của handle. **Không lưới nào kiểm cột `Element` mô tả đúng hay sai.** Nên mô tả sai là lỗi **im lặng vượt mọi cổng** — và nó dẫn thẳng tới **oracle sai** cho người viết test sau đó.

**Luật:** `Element` phải nói **giá trị thật sự render ra**, kèm **mọi nhánh fallback**. Không viết theo tên handle, không viết theo ý định thiết kế.

| | Mô tả |
| --- | --- |
| ❌ SAI | `Mã nhân viên ở header` |
| ✅ ĐÚNG | `Subtitle header: roleName nếu có, mã NV là fallback (profile_header.dart:46)` |

Ca thật: `profile-username` được mô tả là "mã nhân viên", nhưng code là `hoSo?.roleName ?? employeeCode`. Người viết test đọc contract rồi ra oracle *"assert `profile-username` == mã NV"* — sai.

⚠ **Hại nhất không phải "sai", mà là "sai KHÔNG ỔN ĐỊNH".** Tài khoản **có** `roleName` ⇒ oracle đỏ; tài khoản **không có** ⇒ fallback về mã NV ⇒ oracle **xanh**. Cùng một assertion, đúng/sai tuỳ **fixture** — flaky theo dữ liệu, tệ hơn flaky ngẫu nhiên vì nó trông tất định.

**Handle có oracle đọc NỘI DUNG** (`text:` / `contains` / so chuỗi) ⇒ row phải ghi thêm **nguồn dữ liệu** của giá trị đó (field nào, `file:dòng`). Không máy hoá được tính đúng của mô tả, nhưng ép người viết nhìn vào đúng chỗ trước khi tin nó.

## 4. Additive-only gate

Khi backfill testid/identifier vào code cũ (retrofit — `references/test-core.md` §3b, §7):

1. Chỉ **thêm thuộc tính** (`data-testid`/`testID`/`Semantics(identifier:)`), KHÔNG đổi cấu trúc/hành vi component.
2. Gắn xong → chạy lại test hành vi cũ (widget/component/unit nếu có) → **phải vẫn xanh**. Đỏ = đã lỡ đổi hành vi → revert, xem lại.
3. Ghi id mới vào đúng registry (§3) **trong cùng commit** với code gắn id đó — không để code và registry lệch nhịp.
4. KHÔNG tự đặt id mới trong test/POM/flow mà không có trong registry — mọi id test dùng phải trace được ngược về registry.

---

## 4b. Element dùng bởi nhiều feature — một row ở feature SỞ HỮU

Một element có thể bị nhiều feature chạm (`profile-delete-account-entry` ở cả F-003 và F-010). Luật: **một handle = một row, ở contract của feature sở hữu element đó** (feature mà element thuộc màn/luồng chính của nó). Feature khác **trỏ sang**, không copy row:

```
| `profile-delete-account-entry` | → xem F-010 (feature sở hữu) | — | `TC-F003-012` |
```

**Vì sao không copy row:** copy thì `git grep <handle>` ra **hai** định nghĩa, và sửa cột `Element`/`File code` ở một file là làm file kia trôi — im lặng, không ai báo. Một định nghĩa + con trỏ giữ được cả traceability (feature nào dùng) lẫn tính duy nhất của định nghĩa.

Đổi tên / gỡ element ⇒ sửa ở **feature sở hữu**, rồi grep con trỏ để cập nhật. Không chắc feature nào sở hữu ⇒ chọn feature có TC neo sâu nhất vào element đó, ghi một dòng `Notes`.

## 5. Bucket "Reserved" — gắn trước, flow dùng sau

Gắn testid ở **phase build** (code) và viết e2e test ở **phase retrofit-e2e** (`/spec-test-retrofit-e2e`) là hai bước tách nhau theo thời gian — build **không** viết/chạy e2e (xem `skills/build/SKILL.md` Bước 2c). Hệ quả: một id mới gắn lúc build **luôn có khoảng thời gian chưa flow nào dùng**.

Với registry **global** (Maestro — react-native hoặc flutter, §3), nhiều harness đối chiếu 2 chiều **strict**: id khai trong registry mà chưa flow nào dùng bị coi là "id chết" và fail check (vd `tool/e2e.sh` của GAL-Mobile: `comm -13` giữa id-dùng-trong-flow và id-khai-trong-bảng). Ghi thẳng id mới vào bảng **Identifiers** chính lúc build sẽ làm check đó đỏ oan.

Giải pháp — tách registry thành hai bucket:

| Bucket | Ý nghĩa | Harness đối chiếu? |
|---|---|---|
| **Identifiers** (bảng chính) | id đã gắn **VÀ** ít nhất một flow đang dùng | Có — 2 chiều |
| **Reserved** (list, KHÔNG phải bảng — để harness parse-theo-bảng không đọc nhầm) | id đã gắn trong code, **chưa** flow nào dùng | Không (cố ý loại khỏi check "id chết") |

Quy trình: build gắn identifier mới → ghi vào **Reserved** (kèm file code + lý do/story sẽ dùng nó) → khi `/spec-test-retrofit-e2e` (hoặc bất kỳ ai viết flow) thật sự dùng id đó trong một flow → **promote**: xoá khỏi Reserved, thêm row vào bảng Identifiers. Registry **per-feature** (web-react) không cần bucket này — harness của nó không đối chiếu "id chết" theo kiểu toàn-app, một `data-testid` gắn sẵn mà chưa test nào query không làm gì đỏ.
