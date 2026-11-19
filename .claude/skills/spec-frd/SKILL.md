---
name: spec-frd
description: Author MỚI frd.md (Feature Requirements Document) trực tiếp ở feature level qua interview. Role BA, chạy trước integration. CREATE-only, đúng một feature/lần: frd đã tồn tại → redirect /spec-new (delta cascade); nguồn nhiều feature → redirect /spec-prd. Nhận F-XXX từ argument (hoặc chọn từ prd Feature Index) + tùy chọn nguồn baseline (path/@file/paste). Chỉ author frd.md (+ register feature row vào prd nếu feature mới; cascade glossary term + định nghĩa shared entity lên domain, Owner TBD để /spec-sad gán) — reference component, KHÔNG tạo crd/cdd.
---

# spec-frd

## Overview

Author `.specs/main/feature/{F-XXX}-{feature-slug}/frd.md` trực tiếp qua interview — **spec-first ở feature level**, do **BA** chạy trước khi bất kỳ integration nào bắt đầu.

`frd.md` là **what to build** của một feature: Overview, User Flows, Feature AC (end-to-end), Non-Functional Requirements, Data & Migration, User Stories, Verification Rules, Scope, Dependencies. Đây là baseline ổn định, **author một lần** — mọi thay đổi sau đó đi qua `/spec-new` (delta cascade).

Skill này là cặp greenfield đối xứng với `/spec-brownfield-feature` (vốn reverse-engineer frd từ code). Khác biệt: `/spec-frd` author *forward* từ interview, không scan code.

**Hai ràng buộc input (làm chặt):**
1. **Đúng một feature mỗi lần chạy** — xác định > 1 feature → DỪNG, mô tả rõ lý do, redirect `/spec-prd` (Bước 1a).
2. **CREATE-only** — frd.md đã tồn tại → DỪNG, redirect `/spec-new` để phân tích delta + cascade + downstream (tech/test) (Bước 1c).

**Phạm vi hẹp — chủ yếu frd.md:**
- ✅ Author frd.md (7 core sections + `Open Questions` tùy chọn) cho **một** feature **chưa có frd**.
- ✅ *Reference* component frd phụ thuộc (Components Used) + ghi component cần-nhưng-chưa-có như **candidate**.
- ✅ Nếu feature mục tiêu là feature mới chưa có trong Index → **register một row vào `prd.md > Features`** (side-effect hợp lệ lên prd).
- ✅ **Cascade vocabulary lên `domain.md`** (Bước 4b — pha *mô tả hệ thống*/WHAT): glossary term + **định nghĩa entity đầy đủ** (attributes). `Owner` của entity để `TBD` cho `/spec-sad` điền ở pha *thiết kế hệ thống* (HOW). BA duyệt trước khi ghi. Đây là điểm khác với phiên bản trước (`/spec-frd` từng không đụng domain) — vocabulary sinh ra ở feature-authoring time nên seed luôn, thay vì để domain rỗng tới integration đầu tiên.
- ❌ KHÔNG tạo/sửa `crd.md`/`cdd.md` — component artifacts ra đời ở integration time qua `/spec-new` cascade.
- ❌ KHÔNG tạo `fdd.md` (inter-component design), `test-design.md` (test), hay `selector-contract.md` — để skill/role khác lo. Contract sinh ở **build-time** bởi `/build` (`.docs/024`): lúc author frd, UI chưa tồn tại nên mọi element decomposition đều là phỏng đoán.
- ❌ KHÔNG carve component / quyết `Owner` của shared entity (để `/spec-sad`/`/spec-new`); KHÔNG đổi status feature đã có; KHÔNG đụng sad.

## When to Use

- Greenfield: BA muốn đặc tả **một feature chưa có frd** *trước* khi DEV bắt đầu integration.
- `prd.md` đã tồn tại (feature có thể đã trong Index, hoặc là feature mới đơn lẻ → skill offer register vào Index).

## When NOT to Use

- `prd.md` chưa có → chạy `/spec-prd` trước.
- **frd.md đã tồn tại** (thay đổi feature đã spec) → dùng `/spec-new` (delta cascade + tech/test). `/spec-frd` không update frd.
- **Nguồn trải nhiều feature** → dùng `/spec-prd` để khai Feature Index trước.
- Brownfield onboarding (reverse-engineer từ code) → dùng `/spec-brownfield-feature`.
- Muốn thiết kế technical / inter-component → `/spec-tech` (integration) hoặc fdd qua cascade.

---

## Process

### Pre-flight: chuẩn bị nhánh Git (chạy TRƯỚC Bước 0)

Mục tiêu: không bao giờ author frd ngay trên nhánh hiện tại của user (có thể là một nhánh đang làm dở) — luôn bắt đầu từ **nhánh chính mới nhất** rồi tách một **nhánh làm việc riêng**.

**Trước tiên, thông báo cho user toàn bộ việc Git skill sẽ làm** (để user biết trước, đúng tinh thần "agent làm các việc này"):

> Trước khi author frd, mình sẽ:
> 1. Pull code mới nhất từ nhánh chính (`{main}`).
> 2. Tạo & checkout một nhánh mới tách từ `{main}` để làm việc.
>
> (Bạn đang ở nhánh `{current}`.)

**1. Xác định nhánh chính (`{main}`).**
- Không phải git repo → bỏ qua toàn bộ pre-flight, note cho user rồi tiếp Bước 0.
- Có nhánh `develop` → mặc định `{main}` = `develop`. Không có `develop` nhưng có `main`/`master` → dùng nó.
- Mơ hồ (tồn tại cả `develop` lẫn `main`, hoặc remote default khác) → **hỏi user** nhánh nào là nhánh chính. KHÔNG đoán.

**2. Kiểm tra working tree sạch.** `git status` còn thay đổi chưa commit → **DỪNG**, báo user commit/stash trước. KHÔNG tự ý stash/discard.

**3. Checkout + pull nhánh chính:** `git checkout {main}` rồi `git pull`. Pull fail (conflict, không có upstream…) → **DỪNG**, surface lỗi cụ thể, để user xử lý.

**4. Tạo nhánh làm việc mới off `{main}`.** Cần slug để đặt tên → thực hiện **ngay sau khi xác định feature mục tiêu ở Bước 1c** (xem nhắc ở đó): đề xuất `git checkout -b spec/{F-XXX}-{slug}`, cho user sửa tên rồi tạo. Mọi việc author/cascade từ Bước 2 trở đi diễn ra trên nhánh này.

---

### Bước 0: Nạp nguồn yêu cầu (tùy chọn)

Giống `/spec-prd` Bước 0. Xác định có nguồn baseline cho feature không (proposal, mô tả feature, ghi chú họp, wireframe note):

1. **ARGUMENT chứa path / `@file`** → đọc file đó (`.md`/`.txt`/PDF).
2. **ARGUMENT chứa text dài (paste)** → dùng làm nguồn.
3. **Không có** → hỏi một lần:
   > Bạn có tài liệu/nguồn cho feature này không? Nhập **đường dẫn file**, **paste nội dung**, hoặc `không` để interview từ đầu.

Lưu ý: ARGUMENT thường vừa chứa **F-XXX** (Bước 1) vừa có thể kèm path — tách hai phần. Nếu chỉ có F-XXX thì hỏi nguồn như trên.

Có nguồn → trích baseline cho từng section frd (overview, flows, stories, AC, rules, scope, dependencies). Đánh dấu cái nào trích được, cái nào nguồn không đề cập. Áp **quy tắc baseline** giống `/spec-prd`: reuse những gì có; validate; phần thiếu mới hỏi.

---

### Bước 1: Xác định feature

**Precondition:** đọc `.specs/main/prd.md`. Nếu không tồn tại / template rỗng → dừng:
> `prd.md` chưa có nội dung. Hãy chạy `/spec-prd` trước.

`/spec-frd` là skill **CREATE-only, đúng một feature mỗi lần chạy**. Xác định feature mục tiêu qua ba gate — phải pass cả ba mới vào interview.

#### 1a. Single-feature gate — chỉ liên quan đúng 1 feature

Đánh giá ARGUMENT + nguồn baseline mô tả **bao nhiêu feature riêng biệt** — mỗi feature = một outcome/luồng nghiệp vụ độc lập (dùng litmus test trong `/spec-prd`).

- **Xác định > 1 feature** → **DỪNG** và **mô tả rõ lý do** tại sao là nhiều feature, không chỉ báo chung chung:
  > Mình xác định nguồn này trải **{N} feature** riêng biệt:
  >   1. {tên feature A} — outcome: {…}; persona: {…}; luồng: {…}
  >   2. {tên feature B} — outcome: {…}; persona: {…}; luồng: {…}
  > Lý do tách: {mỗi cái có outcome/luồng độc lập, không phải biến thể của cùng một luồng — chiếu litmus test}.
  >
  > `/spec-frd` chỉ author một feature mỗi lần. Hãy chạy `/spec-prd` để khai {N} feature này vào Feature Index trước, rồi chạy `/spec-frd F-XXX` cho từng cái.

  (Nếu có F-XXX chỉ định nhưng nguồn vẫn trải nhiều feature → vẫn dừng và mô tả lý do; không tự ý cắt phần thuộc F-XXX, vì BA cần thấy bức tranh đầy đủ để khai Index.)
- **Đúng 1 feature** → tiếp 1b.

#### 1b. Resolve feature mục tiêu

- **F-XXX có trong Feature Index** → dùng.
- **Feature mới — KHÔNG có trong Index** (đúng một) → **offer register**:
  > Feature "{tên}" chưa có trong prd Feature Index. Mình sẽ thêm vào Index rồi author frd:
  >   F-{auto next} | {tên} | {mô tả 1 câu} | {priority?} | TODO
  > Đồng ý? [y / sửa / n]
  - `y` → auto-pick `F-XXX` = `id_counters.feature + 1` trong prd (bump counter khi ghi row); **giữ lại để Bước 7 ghi row `[NEW]` vào prd**.
  - `n` → dừng, gợi ý `/spec-prd` để khai feature trước.
- **Không có F-XXX và không có nguồn** → hiển thị Feature Index để chọn (chỉ feature **chưa có frd.md**):

```
Features chưa có frd.md:

  [1] F-001 — Authentication        (High)    [TODO]
  [3] F-003 — App Browsing & Opt-in (High)    [TODO]

(F-002 đã có frd.md → thay đổi đi qua /spec-new)

Chọn feature để author frd:
```

#### 1c. Create-only gate — frd.md CHƯA tồn tại

Kiểm tra `.specs/main/feature/{F-XXX}-*/frd.md`.

- **Chưa tồn tại** → **tạo nhánh làm việc** (Pre-flight bước 4): `git checkout -b spec/{F-XXX}-{slug}` off `{main}` (đề xuất tên, cho user sửa), rồi tiếp Bước 2 (author mới).
- **Đã tồn tại** → **DỪNG**, redirect `/spec-new`:
  > frd.md cho {F-XXX} đã tồn tại. Mọi thay đổi feature đã được spec phải đi qua `/spec-new` — skill đó phân tích delta, cascade lên frd/crd/prd/domain, và kéo theo việc kỹ thuật/test (`/spec-tech`, `/spec-test`).
  > Chạy: `/spec-new {F-XXX}` (hoặc `/spec-new <mô tả thay đổi>`).

  `/spec-frd` **không** update frd đã có — giữ một làn ghi delta duy nhất (`/spec-new`) để đảm bảo traceability và downstream không bị bỏ sót.

---

### Bước 2: Load context

Load:
- `.specs/main/prd.md` — Problem Statement, Target Users (personas), Scope, **row của feature này** trong Feature Index (tên, mô tả, priority), Component Index, **cột ADO** (nếu feature có ticket → lưu lại để spec.md sau này không tạo duplicate).
- `.specs/main/domain.md` — Glossary + Shared Entities liên quan.
- `.specs/main/sad.md` — bảng Components (góc nhìn kiến trúc, để biết C-XXX nào đã có boundary).
- `.specs/main/component/{C-XXX}-*/crd.md` — Public Interface của các component khả năng feature sẽ dùng (nếu đã tồn tại).

Tóm tắt context + surface assumptions:

```
TỪ PRD & DOMAIN TÔI HIỂU:
- Feature: {F-XXX — tên — mô tả ngắn từ prd} (priority: {...})
- Vấn đề tổng: {problem statement ngắn}
- Personas liên quan: {từ Target Users}
- Glossary/entities liên quan: {từ domain.md}
- Components có sẵn có thể dùng: {C-XXX — tên}

ASSUMPTIONS TÔI ĐANG ĐẶT RA:
1. {scope của feature}
2. {component feature có thể phụ thuộc}
→ Sửa lại nếu sai trước khi tiếp tục.
```

---

### Bước 3: Interview

Hỏi tuần tự, từng phần — không hỏi tất cả cùng lúc. Nếu Bước 0 có nguồn → trình bày baseline đã trích rồi xin confirm/sửa; phần nguồn không đề cập mới hỏi từ đầu.

**Phần 1 — Overview:**
> Feature này giải quyết vấn đề gì, cho persona nào? (2-3 câu, góc nhìn user/business)

**Phần 2 — User Flows:**
> User thao tác qua những bước nào để đạt mục tiêu? Có những nhánh edge case / thất bại nào quan trọng?
> (Mình sẽ vẽ mỗi luồng thành một Mermaid flowchart — happy case + edge cases.)

**Phần 3 — User Stories:**
> Liệt kê các stories ở cấp feature: "{Persona} muốn {hành động} để {mục tiêu}". Mỗi story có priority (Must/Should/Could) và acceptance criteria (Given/When/Then).

**Phần 4 — Feature Acceptance Criteria (end-to-end):**
> Có criteria **end-to-end** nào áp cho *toàn* feature mà story lẻ không cover? 3 shape: journey (tuần tự liên story) + consistency (đa màn) + integrity (bất biến liên story, không tuần tự — vd cascade delete, đối soát khớp). Mỗi cái Given/When/Then, **Then phải đo được**. (NFR và data/migration hỏi riêng ở Phần 4b / 4c.)

**Phần 4b — Non-Functional Requirements:**
> Feature có yêu cầu non-functional riêng không? (performance, accessibility, security, browser, i18n). Mỗi cái **tham chiếu `NFR-*` của PRD nếu có** (refine bar chung) hoặc đặc thù-feature. G/W/T, Then đo được. Không có → để section trống (required-emptyable, giữ heading).

**Phần 4c — Data & Migration:**
> Feature có đụng migration / backfill data cũ không? Nếu có: G/W/T, Then đo được (đếm bản ghi / so khớp). Không có → giữ heading, để section trống (required-emptyable).

**Phần 5 — Verification Rules:**
> Với mỗi input field trong các stories, mình sẽ suggest 2-4 phương án validation để BA chọn (xem "Verification Rules — quy ước sinh" bên dưới). BA là người quyết định.

**Phần 6 — Scope:**
> Feature này làm gì (In Scope)? Có gì liên quan nhưng KHÔNG làm (Out of Scope) + lý do?

**Phần 7 — Dependencies:**
> - **Feature dependencies:** feature này cần feature nào xong trước, hay chạy song song?
> - **Components Used:** feature này dùng component nào? (Mình sẽ map sang C-XXX có sẵn; component cần-nhưng-chưa-có sẽ ghi như candidate — xem Bước 4.)

Câu trả lời vague → hỏi lại để làm rõ (ngưỡng đo được, field cụ thể, nhánh xử lý).

**Open Questions — gom trong lúc interview.** Điểm nào BA chưa chốt được ngay (chờ stakeholder, phụ thuộc quyết định khác, ngưỡng/nhánh chưa rõ) → KHÔNG đoán bừa vào AC/VR. Ghi lại thành một mục trong `## Open Questions` của draft (kèm ai trả lời / khi nào), rồi tiếp tục các phần còn lại. Section này gom cả component candidate (Bước 4) lẫn câu hỏi clarify từ interview; rỗng thì xóa khi save.

---

### Bước 4: Xử lý component (mức reference + candidate)

`/spec-frd` **không carve component**. Chỉ làm hai việc:

1. **Component đã có C-XXX** (trong prd Component Index) → ghi vào `Dependencies > Components Used` với vai trò trong feature.

2. **Component feature cần nhưng chưa có** → KHÔNG tạo crd/cdd, KHÔNG tự thêm vào prd Component Index. Thay vào đó:
   - Ghi trong Components Used với **tên đề xuất** + flag `(candidate — chưa carve)`.
   - Thêm một mục vào draft **Open Questions** (hoặc note cuối draft) để `/spec-sad`/architect chốt boundary, hoặc `/spec-new` formal-register + tạo crd/cdd ở integration time.

Lý do: giữ **một authority duy nhất** cho việc carve component (architect qua `/spec-sad`, hoặc cascade qua `/spec-new`). BA chỉ khai báo *nhu cầu*, không quyết boundary. (Xem quy tắc Given/Derived trong `/spec-prd`.)

---

### Bước 4b: Trích domain vocabulary (glossary + định nghĩa entity)

Author frd là **điểm đầu tiên** business vocabulary xuất hiện cụ thể. Để `domain.md` không nằm rỗng tới integration đầu tiên (và để term không trôi/đụng nhau giữa các frd), skill seed vocabulary mới vào `domain.md` ngay tại BA-time. Giống VR và component candidate: **agent đề xuất, BA quyết** — không tự assert.

Đọc `domain.md` (đã load ở Bước 2) để biết Glossary/Shared Entities **đã có gì**, rồi rà draft frd tìm cái **mới**:

**1. Glossary term — ghi thẳng.** Thuật ngữ business xuất hiện trong frd mà chưa có trong domain Glossary. Glossary thuần vocabulary, không phụ thuộc component → cascade trực tiếp được. Với mỗi term đề xuất:
> Term mới phát hiện: **{term}** — đề xuất định nghĩa: "{định nghĩa}". Thêm vào domain Glossary? [y / sửa / bỏ]

Cấm: định nghĩa mơ hồ, hoặc nhét term thực ra là tên feature/component (không phải vocabulary nghiệp vụ).

**2. Entity — định nghĩa đầy đủ (WHAT), `Owner` để design-time điền.** Đây là điểm tách bạch quan trọng:

- **Define entity là *mô tả hệ thống* (WHAT)** → thuộc BA, làm ngay tại frd-time. BA định nghĩa entity đầy đủ: tên, mô tả, **attributes** (business type: text/number/money/date/email/phone), state machine nếu có lifecycle nghiệp vụ. Đây là vocabulary chung, không phải artifact hạng hai.
- **Entity *nằm ở component nào* (`Owner`) là *thiết kế hệ thống* (HOW)** → thuộc architect, điền ở `/spec-sad` (hoặc `/spec-new` khi carve). `/spec-frd` **không carve component** nên **không** quyết `Owner`.

Vì vậy khi seed entity vào domain Shared Entities:
- **Cấp Entity ID `E-XXX`** theo quy ước của `domain-template.md`: ID tiếp theo = `id_counters.entity + 1` trong `domain.md`, bump counter sau khi cấp (high-water-mark — ID của entity đã remove không tái sử dụng). Heading entity: `### E-XXX {Entity Name}`.
- Điền đầy đủ definition + attributes từ frd.
- Để **`Owner: TBD (điền ở /spec-sad — design time)`** và **`Used by: TBD`**. Không phải vì entity "chưa chắc có thật", mà vì ownership là quyết định thiết kế chưa tới lượt.
- Entity rõ ràng chỉ là cấu trúc dữ liệu kỹ thuật nội bộ (không phải vocabulary nghiệp vụ) → không thuộc domain; bỏ qua, để lộ ra ở `crd.md` lúc carve.

> Entity feature mô tả: **{Entity}** với attributes {…}. Đây là vocabulary nghiệp vụ chung → mình seed định nghĩa vào domain (Owner để architect điền ở /spec-sad). Đồng ý? [y / sửa / bỏ]

BA quyết **định nghĩa entity** (WHAT); `Owner` để `/spec-sad` cascade bổ sung (HOW). Xem two-phase cascade ở `01-architecture.md` §7.

### Bước 5: Write — sinh draft

Dùng `.claude/templates/main/feature/frd-template.md` làm skeleton, điền nội dung từ interview.

**ID assignment** (luôn là create — frd mới): US `US-F{NNN}-001+`, Story AC `AC-F{NNN}-001+`, Feature AC `FAC-F{NNN}-001+` (counter độc lập với Story AC), NFR `NFR-F{NNN}-001+` (counter độc lập), DM `DM-F{NNN}-001+` (counter độc lập, chỉ khi có Data & Migration), VR `VR-F{NNN}-001+`. `NNN` = số của F-XXX. Flow đánh số từ 1.

**Frontmatter** frd mới: theo template, `status: draft`, `owner: BA`, `feature_id: F-XXX`, `template_version` copy từ `frd-template.md` (xem `01-architecture.md` §12 — chỉ set lúc CREATE; thay đổi sau qua `/spec-new` không đụng version).

Hiển thị **toàn bộ draft** cho user — chưa ghi file. Kèm:
- danh sách component candidate (nếu có) và VR còn `TBD`;
- **Open Questions** còn mở (câu hỏi clarify + component candidate) để BA xác nhận hoặc giải quyết trước khi save;
- **danh sách domain vocabulary đề xuất** (Bước 4b): glossary term mới + định nghĩa shared entity (`Owner: TBD`), để BA duyệt trước khi cascade lên `domain.md`.

#### Verification Rules — quy ước sinh

Áp dụng khi sinh section Verification Rules. **Tái dùng nguyên quy ước của `/spec-new`** (xem [spec-new SKILL.md](../spec-new/SKILL.md) → "Verification Rules — quy ước sinh"). Tóm tắt:

- VR là **business decision — BA owns**. Agent đóng vai **option-suggester**, KHÔNG tự assert rule.
- Mỗi input field → suggest 2-4 phương án validation + luôn có `Custom` và `TBD`.
- BA chọn → auto-assign `VR-F{NNN}-{seq}`. `TBD` → vẫn assign ID, ghi `TBD` ở cột Rule, list ra cuối draft.
- **Cột `Refs` điền cùng lúc, bắt buộc non-empty** — story mà bước scan vừa lấy field đó ra (`US-F{NNN}-{seq}`), thêm `AC-*` khi có AC cụ thể đòi rule. Không neo được story nào ⇒ `NEEDS_CLARIFY`, **không** ghi row: `/plan` và `/implement` lọc VR theo `Refs`, dây đứt thì VR bị lọc ra mất mà không dòng báo nào (035 D0).
- **Cấm:** tự điền rule chưa hỏi BA; đưa regex/validator/error message vào bảng (đó là HOW/UI copy); dùng tech type (`varchar(255)`) thay vì semantic type.
- Heuristic suggest theo field name: xem bảng trong spec-new.

---

### Bước 6: Review — xác nhận với user

> Draft frd trên đã đúng chưa?
> - User Flows có cover đủ happy + edge case không?
> - User Stories + AC đo được chưa?
> - Verification Rules đã confirm với BA chưa (không còn TBD ngoài ý muốn)?
> - Components Used đúng chưa? Component candidate (nếu có) có hợp lý để chuyển cho /spec-sad không?
> - Glossary term / định nghĩa shared entity đề xuất cascade lên domain đã đúng chưa? (term có phải vocabulary nghiệp vụ thật, entity có đáng là shared không, attributes đủ chưa?)

Chỉ ghi file sau khi user confirm. Yêu cầu chỉnh → cập nhật draft → hỏi lại.

---

### Bước 7: Save

**7a. Ghi `.specs/main/feature/{F-XXX}-{slug}/frd.md`** — tạo thư mục nếu chưa có. Status `draft` (lifecycle riêng của artifact).

Slug feature lấy từ tên trong prd Feature Index, kebab-case (ví dụ F-001 "Authentication" → `F-001-authentication`).

**7b. Bump `id_counters`** trong frontmatter frd.md cho mọi ID vừa author (`flow`, `fac`, `nfr`, `dm`, `us`, `ac`, `vr`) → set mỗi counter = seq lớn nhất vừa cấp (high-water-mark). KHÔNG ghi Change History (đã bỏ — history = git, xem `01-architecture.md` §7). "Đổi gì · khi nào" = git commit của file.

**7b'. (Chỉ khi Bước 1b register feature mới)** Ghi row `[NEW]` vào `prd.md > Features`:

```
F-{XXX} | {tên} | {mô tả 1 câu} | {priority} | TODO
```

Và bump `id_counters.feature` trong prd.md = `F-XXX` seq vừa cấp (high-water-mark). KHÔNG ghi Change History.

Đây là side-effect hợp lệ của `/spec-frd` lên prd — thêm một feature row. Việc này atomic với 7a/7b: nếu fail thì rollback cả frd.

**7b''. (Chỉ khi Bước 4b/6 BA đã confirm vocabulary)** Cascade lên `.specs/main/domain.md`:

- **Glossary** → append row `[NEW]` cho mỗi term đã confirm: `| {term} | {định nghĩa} | {example/context} |`.
- **Shared Entities** → cho mỗi entity đã confirm, thêm một entry mới theo template với heading `### E-XXX {Entity Name}` (ID cấp ở Bước 4b — `id_counters.entity + 1`, không tái sử dụng), definition + attributes đầy đủ, để `**Owner:** TBD (điền ở /spec-sad — design time)` và `**Used by:** TBD`. Trong frd, reference entity theo dạng `E-XXX {Entity Name}` để trace về domain.md.

Bump `id_counters.entity` trong `domain.md` = seq E-XXX lớn nhất vừa cấp (high-water-mark). Glossary term không mang ID → không counter. KHÔNG ghi Change History (đã bỏ — history = git).

Atomic với 7a: domain cascade fail → rollback cả frd. `Owner` của entity do `/spec-sad`/`/spec-new` cascade bổ sung sau (HOW phase) qua `[MODIFY Owner]`.

**7c. KHÔNG đụng gì khác.** Không đổi status của các feature *đã có* (frd tồn tại ≠ integration bắt đầu; marker "→ frd.md tồn tại" derive từ file existence). Không thêm component vào Index (chỉ candidate). Không carve component / không tự quyết `Owner` của shared entity. Không tạo crd/cdd/fdd/test-design/selector-contract. Không đụng sad.

**7d. Thông báo kết quả:**

```
✓ .specs/main/feature/{F-XXX}-{slug}/frd.md đã được tạo (status: draft)

{nếu có} Domain cascade (pha mô tả hệ thống):
  - Glossary: +{N} term
  - Shared Entities: +{N} entity (định nghĩa đầy đủ; Owner TBD — chờ /spec-sad gán ở pha thiết kế)

{nếu có} Component candidate cần carve (chuyển cho architect / integration):
  - {tên đề xuất} — {vai trò}

{nếu có} Verification Rules còn TBD:
  - VR-F{NNN}-{seq} — {field}

Bước tiếp theo:
  - /spec-test-design F-XXX  → QC bootstrap test design từ frd này
  - /spec-new F-XXX  → DEV bắt đầu integration (frd sẽ được consume, crd/cdd sinh qua cascade)
  {nếu có candidate hoặc entity Owner TBD} - /spec-sad → architect chốt boundary component + gán Owner cho shared entity
```

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Để /spec-new tự đẻ frd cho nhanh" | frd là *feature requirements* — việc của BA. Để integration đẻ ra = DEV phải đoán yêu cầu. |
| "BA cứ tạo luôn crd cho component cần" | Carve component là quyết định kiến trúc. BA tạo crd sớm = boundary sai sớm. Chỉ reference. |
| "Verification rule mình tự điền cho nhanh" | VR là business decision. Agent tự assert = rule sai mà không ai review. |
| "User Flows vẽ sau cũng được" | Flow buộc phải nghĩ edge case. Không có flow = AC thiếu nhánh thất bại. |
| "BA gán luôn Owner component cho entity cho gọn" | Ownership là quyết định *thiết kế* (HOW). BA gán sớm = boundary sai sớm. Để `Owner: TBD`, `/spec-sad` điền. |
| "Entity chưa biết owner thì khoan ghi vào domain" | Define entity là *mô tả* (WHAT) — độc lập với việc nó nằm ở component nào. Ghi định nghĩa luôn, Owner điền sau. |

## Red Flags

- frd dùng từ không đo được trong AC ("hoạt động đúng", "nhanh", "đẹp")
- User Stories không có persona rõ hoặc không có AC
- Verification Rules tự điền mà chưa hỏi BA
- Đoán bừa vào AC/VR thay vì ghi điểm chưa chốt vào Open Questions
- Tạo crd.md/cdd.md (vượt phạm vi — đó là integration time)
- Component candidate không được surface cho architect
- **Update frd đã tồn tại** thay vì redirect `/spec-new` (vi phạm CREATE-only)
- Cắt phần thuộc một F-XXX từ nguồn nhiều feature thay vì dừng + mô tả lý do

## Verification

- [ ] **Pre-flight Git**: đã thông báo plan cho user; xác định đúng nhánh chính (hỏi nếu mơ hồ); working tree sạch; đã `checkout {main}` + `pull`; tạo nhánh làm việc mới off `{main}` trước khi author
- [ ] `prd.md` tồn tại
- [ ] **Single-feature gate**: nguồn liên quan đúng 1 feature; nếu >1 đã DỪNG và mô tả rõ lý do tách + redirect `/spec-prd`
- [ ] **Create-only gate**: frd.md của feature mục tiêu CHƯA tồn tại; nếu đã có đã redirect `/spec-new`
- [ ] Feature mục tiêu có trong Index, HOẶC feature mới đơn lẻ đã được user đồng ý register (Bước 1b)
- [ ] frd.md có đủ 7 core sections (luôn create mới); `Open Questions` chứa câu hỏi clarify + component candidate còn mở, hoặc đã xóa nếu rỗng
- [ ] Frontmatter có `template_version` copy từ `frd-template.md`
- [ ] Mỗi User Story có persona + priority + ít nhất 1 AC Given/When/Then
- [ ] Feature AC chỉ end-to-end (journey + consistency + integrity), ID `FAC-F{NNN}-{seq}` (counter độc lập với `AC-F{NNN}`), Then đo được; authz/access-control functional → AC/VR, không phải NFR
- [ ] Non-Functional Requirements: heading luôn có (required-emptyable); nếu có item → ID `NFR-F{NNN}-{seq}`, tham chiếu `NFR-*` PRD nếu có thể, Then đo được
- [ ] Data & Migration (required-emptyable): ID `DM-F{NNN}-{seq}`, Then đo được; không đụng migration → giữ heading, để trống
- [ ] Verification Rules đã confirm với BA (không tự assert); không chứa regex/code/error message; semantic type
- [ ] Mọi VR có `Refs` non-empty, ID tồn tại trong cùng file — `npx spec-lite check-vr-refs <frd.md>` in **`✓ VR REFS KHỚP`** (035 D0)
- [ ] ID bắt đầu từ 001 (create mới)
- [ ] Components Used reference C-XXX có sẵn; component mới ghi candidate + surface cho /spec-sad
- [ ] Nếu register feature mới: prd Features có row [NEW] + `id_counters.feature` đã bump; status feature đã có KHÔNG đổi
- [ ] Domain cascade (nếu có vocabulary mới, đã BA confirm): Glossary term ghi đủ định nghĩa; Shared Entity ghi đủ definition + attributes với `Owner: TBD` (KHÔNG tự gán C-XXX); `id_counters.entity` trong domain.md đã bump
- [ ] KHÔNG tạo crd/cdd/fdd/test-design/selector-contract; KHÔNG carve component / gán Owner entity; KHÔNG đụng sad
- [ ] `id_counters` (frd) đã bump cho mọi ID vừa author (flow/fac/nfr/dm/us/ac/vr); KHÔNG ghi Change History
- [ ] User đã confirm trước khi ghi file
