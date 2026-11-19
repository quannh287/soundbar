---
name: spec-prd
description: Điền hoặc cập nhật prd.md — Product Requirements Document ở product level. Nhận tùy chọn một nguồn yêu cầu (đường dẫn file/@file hoặc paste proposal/BRD/ghi chú) làm baseline để pre-fill interview. Cũng scaffold domain.md skeleton (glossary placeholder + Shared Entities rỗng). Dùng khi prd.md còn là template rỗng hoặc cần review/cập nhật.
---

# spec-prd

## Overview

Tạo nội dung cho `.specs/main/prd.md` thông qua interview có cấu trúc. PRD là nguồn sự thật ở product level — nó định nghĩa vấn đề, users, scope, features, components, và NFRs trước khi bất kỳ technical decision nào được đưa ra.

Skill này cũng scaffold `.specs/main/domain.md` skeleton nếu chưa tồn tại — domain.md mọc dần qua cascade ở hai pha: mô tả (`/spec-frd`, `/spec-new` seed glossary + định nghĩa entity, `Owner: TBD`) và thiết kế (`/spec-sad` gán `Owner`). Xem two-phase cascade `01-architecture.md` §7.

PRD không chứa: tech stack, implementation details, entity schema, glossary, business rules — những thứ đó thuộc về `sad.md` hoặc `domain.md`.

## When to Use

- `.specs/main/prd.md` chưa có nội dung hoặc vẫn còn là template
- Cần bổ sung hoặc cập nhật một phần của PRD hiện tại
- Requirements thay đổi và PRD cần được đồng bộ lại

## When NOT to Use

- Đang muốn thiết kế kiến trúc kỹ thuật → dùng `/spec-sad`
- Cập nhật domain entities cụ thể → đi qua integration (`/spec-new`) và để cascade mechanism handle

---

## Khái niệm: Feature vs Component

Section này là nền tảng để điền **Phần 4 (Features)** và **Phần 5 (Components)**. Đọc trước khi interview.

### Nguyên tắc gốc

**Component là đơn vị ownership; Feature là đơn vị delivery.** Component bền vững theo thời gian; Feature là một luồng nghiệp vụ consume một hoặc nhiều component. Quan hệ giữa hai khái niệm là **N–N** — không mechanical-derive cái này từ cái kia.

### Litmus test — phân loại một mục là Feature hay Component

Chạy qua các phép thử; đa số phiếu nghiêng đâu thì xếp vào đó:

| Phép thử | → Component | → Feature |
| --- | --- | --- |
| **Ownership** (quan trọng nhất) | Sở hữu entity + rule + interface | Điều phối/tiêu thụ dữ liệu & rule của thứ khác |
| **Lifetime** | Xóa hết luồng nghiệp vụ vẫn còn tồn tại | Bỏ đi, không component nào mất gì |
| **Hướng cắt** | Ngang — một năng lực dùng lại bởi N luồng | Dọc — UI→logic→data cho một luồng |
| **Đặt tên** | Danh từ hệ thống (`auth`, `payment`) | Luồng nghiệp vụ (`checkout-flow`, `password-reset`) |
| **Trả lời** | "Phần nào của hệ thống chịu trách nhiệm X?" | "User làm được gì, nhận giá trị gì?" |

### Mục có tính chất kép — vừa Feature vừa Component

Litmus test ở trên giả định mỗi mục rơi vào **một** bucket. Nhưng một số mục có **hai mặt** và xứng đáng đăng ký ở **cả hai** index — kinh điển là `auth`:

- **Mặt trải nghiệm người dùng** (đăng nhập SSO/OTP, có Flows + User Stories + Acceptance Criteria) → **Feature**.
- **Mặt năng lực cross-cutting** (RBAC enforce mọi endpoint, session) mà mọi feature khác tham chiếu → **Component**.

**Phép thử tính kép** — một mục là *cả hai* khi thỏa CẢ hai điều kiện:

1. Nó là component **Given** (xem Given/Derived bên dưới — thường trúng câu 2 Mandated-substrate), VÀ
2. Nó có một **trải nghiệm người dùng** (Flows/US/AC) mà (a) **không** biểu diễn được trong `crd.md` (CRD chỉ có Role/Responsibilities/Interface/Business Rules — KHÔNG có Flows/User Stories/Acceptance Criteria), và (b) **không** thuộc sở hữu của feature nào khác.

Nếu kép → đăng ký **một Feature (F-XXX)** cho mặt UX + **một Component (C-XXX)** cho mặt năng lực, và chia trách nhiệm dứt khoát:
- Flows / User Stories / Acceptance Criteria / rule của luồng → **Feature** (`frd.md`), trỏ tới component qua mục "Components Used".
- Năng lực dùng chung + interface + rule nội bộ → **Component** (`crd.md`/`cdd.md`). Mô tả component **thu hẹp** về mặt năng lực, ghi rõ "UX thuộc F-XXX".

| Ứng viên | Mặt Feature (UX) | Mặt Component (năng lực) | Kết luận |
| --- | --- | --- | --- |
| auth | login SSO/OTP, lockout | RBAC enforce, session/token | **kép** |
| notification | notification center (chuông/panel, mark-read) | kênh gửi email + push dùng chung | **kép** |
| file-storage | document repository (upload/preview/download) | blob storage + access control | **kép** |
| payment-gateway / e-signature / erp-adapter | — (UX nằm trong feature tiêu thụ) | adapter tích hợp ngoài | **component-only** |
| checkout, password-reset | luồng nghiệp vụ | — (không năng lực cross-cutting) | **feature-only** |

**Cảnh báo:** đa số component **External** (câu 1 — adapter Stripe/DocuSign/BC) là **component-only** — trải nghiệm dùng chúng (thanh toán, ký, xem dữ liệu BC) thuộc về các feature tiêu thụ, bản thân adapter không có UX riêng. Tính kép chủ yếu xuất hiện ở component **Mandated-substrate** (câu 2: auth, notification, file-storage).

### Quy tắc đặt tên (cho cả Feature và Component)

**Goldilocks:** đặt tên ở mức trừu tượng **cao nhất mà vẫn truyền đạt đúng MỘT trách nhiệm/luồng rõ ràng**. Cao hơn → mất boundary; thấp hơn → rò rỉ chi tiết. Tên dùng kebab-case.

**Component — theo năng lực bền vững, không theo công nghệ hiện tại:**
- ✅ `notification`, `auth`, `file-storage`, `payment-gateway`
- ❌ Quá cụ thể (rò rỉ impl): `email-sender` (mai thêm SMS/push?), `stripe-client`, `s3-uploader`
- ❌ Quá mơ hồ (mất boundary): `core`, `utils`, `manager`, `engine`, `service`, `data`
- Phép thử: *"Mai đổi nhà cung cấp / thêm kênh, tên còn đúng không?"* Không → quá cụ thể.

**Feature — theo outcome của một luồng hoàn chỉnh:**
- ✅ `user-registration`, `password-reset`, `checkout`
- ❌ Quá rộng (thành feature area, ôm nhiều luồng): `user-management`, `account`, `admin`
- ❌ Quá hẹp (chỉ một biến thể của luồng): `register-with-google`, `reset-password-via-sms-otp`
- Phép thử: *"Đây là MỘT luồng, hay cái ô chứa nhiều luồng?"* Cái ô → quá rộng.

### Định nghĩa một Component

**Một component = một khối có (1) boundary rõ + interface tường minh, và (2) một lý do duy nhất để thay đổi.**

- Tính chất (1) là điều kiện *cần*; (2) là guardrail chống "tầng kỹ thuật" lọt vào. "Tầng controller" có boundary rõ nhưng đổi vì N lý do (auth đổi, payment đổi...) → cohesion bằng 0 → **không** phải component.
- Áp đúng tiêu chí "một lý do thay đổi" thì ranh giới theo capability/domain sẽ **tự hiện ra** — không cần áp luật "phải chia theo domain" từ ngoài vào.
- Mỗi component đồng thời có **mặt domain** (`crd.md` — WHAT/contract) và **mặt kỹ thuật** (`cdd.md` — HOW/internal design). Đừng phân loại component thành "domain component" hay "kỹ thuật component" — đó chỉ là mô tả *nguồn* cohesion, không phải luật cấu trúc.

### Component nào khai ở PRD? — Logic Given vs Derived

Feature Index điền **đầy đủ** ở PRD. Component thì **không** — chỉ khai những component có boundary đã *chín*. Độ chín xác định bằng thủ tục quyết định, không cảm tính.

**Litmus gốc:** *"Cùng bộ yêu cầu này, một architect giỏi khác có thể vẽ boundary này khác đi một cách hợp lý không?"* — KHÔNG (bị ép, một cách vẽ) → **Given, khai ở PRD**. CÓ (một lựa chọn đánh đổi) → **Derived, để `/spec-sad`**.

**Thủ tục 3 câu** (YES đầu tiên thắng):

| # | Câu hỏi | Nếu YES |
| --- | --- | --- |
| 1. External | Nó bọc/adapt một hệ thống hay bên thứ ba **ngoài codebase** mà ta buộc phải tích hợp? | **Given** → khai PRD (vd `payment-gateway` tích hợp Stripe, `email-service` tích hợp SendGrid) |
| 2. Mandated-substrate | Nó là nền tảng kỹ thuật dùng chung mà yêu cầu nói rõ phải có, **độc lập với cách carve lõi nghiệp vụ**? | **Given** → khai PRD (vd `auth`, `file-storage`, `notification`) |
| 3. Còn lại | Boundary phụ thuộc cách carve lõi nghiệp vụ, hoặc phụ thuộc đánh đổi NFR (scale, isolation, consistency, team topology)? | **Derived** → KHÔNG khai, để `/spec-sad` (vd `order`, `pricing`, `inventory`) |

Ranh giới câu 2 vs câu 3 = **"boundary có độc lập với quyết định chia lõi nghiệp vụ không?"** Độc lập → Given; phụ thuộc → Derived.

### Khi input context đã có sẵn feature/component

Input là **baseline, không phải chân lý tuyệt đối**:

- Reuse tên/ID/boundary nếu input đã có → không tự đẻ cấu trúc song song.
- Vẫn chạy litmus test (phân loại) + Given/Derived để **validate**. Nếu input gọi X là "component" mà nó fail ownership test → flag, đề xuất reclassify thành feature (không im lặng bê nguyên).
- Chạy **Phép thử tính kép** cho mọi component Given. Nếu input gọi X là "component" (vd `auth`) nhưng X cũng có trải nghiệm người dùng riêng (SSO/OTP flow, có Flows/US/AC) không thuộc feature khác → flag, đề xuất đăng ký **thêm** một Feature cho mặt UX và thu hẹp component về mặt năng lực — đừng để mặt UX không có nhà.
- Component **Derived** do input cung cấp → ghi nhận như *candidate*, chuyển sang `/spec-sad`, **không** nhồi vào Component Index của PRD.
- Phần input thiếu → mới interview để bù.

---

## Process

### Bước 0: Nạp nguồn yêu cầu (tùy chọn)

Trước khi interview, xác định có **nguồn yêu cầu** (proposal, BRD, ghi chú họp, draft cũ) để dùng làm baseline không. Thứ tự ưu tiên:

1. **ARGUMENT là path / `@file`** → đọc file đó. Hỗ trợ `.md`, `.txt`, PDF.
2. **ARGUMENT là text dài (paste trực tiếp)** → dùng luôn làm nguồn.
3. **Không có ARGUMENT** → hỏi một lần:
   > Bạn có tài liệu/nguồn yêu cầu nào để mình tham khảo không? Nhập **đường dẫn file**, **paste nội dung**, hoặc `không` để interview từ đầu.

Nếu có nguồn → đọc và **trích baseline** cho từng section PRD (problem, users, scope, features, components, NFR, constraints). Đánh dấu cái nào trích được, cái nào nguồn không đề cập.

Áp **quy tắc baseline** (xem section "Khi input context đã có sẵn feature/component"): reuse tên/ID/boundary; validate feature/component qua litmus + Given/Derived; flag mục phân loại sai; component Derived → candidate cho `/spec-sad`, không nhồi vào Component Index.

Nếu không có nguồn → bỏ qua, interview từ đầu như bình thường.

---

### Bước 1: Kiểm tra preconditions

Đọc `.specs/main/prd.md`:

- **File không tồn tại** → tạo thư mục `.specs/main/` (nếu chưa có) rồi tiến hành Bước 2 (full interview).

- **File là template rỗng** → tiến hành Bước 2 (full interview).

- **File có nội dung thực** → quét toàn bộ sections, hiển thị trạng thái từng section, rồi hỏi user muốn làm gì.

  **Các sections cần quét** (theo thứ tự):

  | # | Section | Có nội dung thực? |
  | --- | --- | --- |
  | 1 | Problem Statement | ✓ đã có / ✗ trống/thiếu |
  | 2 | Target Users | ✓ đã có / ✗ trống/thiếu |
  | 3 | Scope | ✓ đã có / ✗ trống/thiếu |
  | 4 | Features | ✓ đã có / ✗ trống/thiếu |
  | 5 | Components | ✓ đã có / ✗ trống/thiếu |
  | 6 | Non-Functional Requirements | ✓ đã có / ✗ trống/thiếu |
  | 7 | Business Constraints | ✓ đã có / ✗ trống/thiếu |

  Một section được coi là **trống/thiếu** nếu: không tồn tại trong file, hoặc chỉ chứa placeholder template (dấu `{}`), hoặc không có dòng nội dung thực.

  Ngoài các sections thuộc template, **ghi nhận các sections thừa** — những `##` heading có trong file nhưng không có trong template.

  Sau khi quét, liệt kê tất cả sections **theo đúng thứ tự xuất hiện trong file** (không tách nhóm), đánh số liên tục:

  ```
  PRD hiện tại:
    [1] Problem Statement       ✓ đã có
    [2] Target Users            ✓ đã có
    [3] Scope                   ✓ đã có
    [4] Risks                   ⚠ không có trong template
    [5] Features                ✗ chưa có — cần bổ sung
    [6] Components              ✗ chưa có — cần bổ sung
    [7] Non-Functional Req.     ✓ đã có
    [8] Business Constraints    ✓ đã có
    [A] Interview tất cả sections

  Chọn số hoặc A:
  ```

  - User chọn số section thuộc template → interview section đó rồi merge vào file.
  - User chọn số section thừa (⚠) → xoá section đó khỏi file ngay, không hỏi thêm.
  - User chọn A → interview tuần tự tất cả sections thuộc template (sections thừa không bị đụng tới).

---

### Bước 2: Gather — interview requirements

**Nếu Bước 0 đã nạp được nguồn:** interview chuyển từ "hỏi trắng" thành **xác nhận + bù chỗ thiếu**. Với mỗi phần, trình bày baseline đã trích rồi hỏi user confirm/sửa; chỉ những phần nguồn không đề cập mới hỏi từ đầu. Bỏ qua phần nào nguồn đã đủ rõ và user xác nhận.

**Nếu không có nguồn:** interview từ đầu như mô tả bên dưới.

Trước khi hỏi, list ra các assumptions đang tạm thời:

```
ASSUMPTIONS TÔI ĐANG ĐẶT RA:
1. Đây là dự án phần mềm (không phải hardware hay process)
2. Target users là end users (không phải internal tools)
→ Sửa lại nếu sai, tôi sẽ tiếp tục với các assumptions đúng.
```

Sau đó hỏi tuần tự, từng phần một — không hỏi tất cả cùng lúc:

**Phần 1 — Problem Statement:**
> Vấn đề gì đang được giải quyết? Tại sao cần giải quyết bây giờ? (2-3 câu từ góc nhìn business)

**Phần 2 — Target Users:**
> Ai là người dùng chính? Mô tả theo persona: tên vai trò, mục tiêu chính, pain point hiện tại.
> (Có thể có nhiều persona)

**Phần 3 — Scope:**
> Hệ thống sẽ làm gì? Và quan trọng hơn — hệ thống sẽ KHÔNG làm gì (out of scope)?
> Ghi rõ lý do cho mỗi item out of scope.

**Phần 4 — Features:**
> Hệ thống cần implement những features gì? Mỗi feature gồm: tên ngắn, mô tả 1 câu (làm gì, cho ai), priority (Must/Should/Could).
> (Đây sẽ là Feature Index mà các FRD sau này sẽ tham chiếu.)

**Phần 5 — Components (chỉ component có boundary Given):**
> Hệ thống chắc chắn phải tích hợp hệ thống ngoài nào (vd `payment-gateway`, `email-service`), hoặc cần nền tảng kỹ thuật dùng chung nào độc lập với cách carve lõi nghiệp vụ (vd `auth`, `file-storage`, `notification`)?
> Mỗi component gồm: tên kebab-case + 1 câu mô tả responsibility.
>
> Áp **thủ tục Given vs Derived** (xem section "Khái niệm: Feature vs Component" ở trên) cho mỗi ứng viên:
> - **Given** (trúng câu 1 External hoặc câu 2 Mandated-substrate) → khai vào Component Index.
> - **Derived** (câu 3 — boundary phụ thuộc cách carve lõi nghiệp vụ hoặc đánh đổi NFR, vd `order`, `pricing`) → **KHÔNG** khai. Để `/spec-sad` chốt, hoặc mọc qua `/spec-new F-XXX` cascade.
>
> Với mỗi component **Given** (nhất là Mandated-substrate), chạy thêm **Phép thử tính kép** (xem section "Mục có tính chất kép"): nếu nó cũng có trải nghiệm người dùng riêng (Flows/US/AC) không thuộc feature khác → đăng ký **thêm** một Feature cho mặt UX vào Phần 4, và thu hẹp mô tả component về mặt năng lực. Vd `auth` → Feature `authentication` (login UX) + Component `auth` (RBAC enforce).
>
> **KHÔNG** mechanical-derive components từ feature areas (vd: thấy "Pricing" trong yêu cầu → tạo ngay `C-pricing`; đó là Derived). Section này có thể chỉ có 3-6 entries, hoặc thậm chí trống. Đừng cố fill cho đủ.

**Phần 6 — Non-Functional Requirements:**
> Có yêu cầu về performance, security, availability, scalability không?
> Mỗi NFR cần: category, mô tả cụ thể, target đo được, priority (Must/Should/Could).

**Phần 7 — Business Constraints:**
> Có ràng buộc kinh doanh nào không? (deadline, budget, compliance, vendor lock-in, v.v.)
> Có giả định nào quan trọng cần ghi lại không?

Nếu câu trả lời vague → hỏi lại để làm rõ. Ví dụ:
- "hệ thống phải nhanh" → "nhanh nghĩa là response time < bao nhiêu ms ở percentile nào?"
- "bảo mật cao" → "có yêu cầu compliance cụ thể không? (PCI-DSS, HIPAA, ISO27001...)"

---

### Bước 3: Write — sinh nội dung

Sau khi thu thập đủ thông tin, dùng `.claude/templates/main/prd-template.md` làm skeleton, điền nội dung từ interview vào từng section.

Hiển thị draft cho user trước khi ghi file.

---

### Bước 4: Review — xác nhận với user

Trình bày draft và hỏi:
> Draft PRD trên đã đúng chưa? Có phần nào cần chỉnh không trước khi lưu?

Chỉ ghi file sau khi user confirm. Nếu user yêu cầu chỉnh sửa → cập nhật draft → hỏi lại.

---

### Bước 5: Save

**5a. Ghi `.specs/main/prd.md`** — nội dung đã được confirm, thay thế toàn bộ nội dung cũ.

**5b. Scaffold `.specs/main/domain.md`** *(chỉ khi file này chưa tồn tại)*:

- Copy `.claude/templates/main/domain-template.md` thành `.specs/main/domain.md`.
- Section **Glossary** giữ format bảng rỗng — terms sẽ được thêm dần qua cascade từ integrations.
- Section **Shared Entities** giữ block placeholder — entities sẽ mọc dần qua cascade khi integration giới thiệu shared entity.

Nếu `domain.md` đã tồn tại với nội dung thực → không đụng tới.

**5b'. Stamp `template_version`:** frontmatter `prd.md` (lúc create) và `domain.md` (lúc scaffold) lấy `template_version` từ template tương ứng (xem `01-architecture.md` §12 Template Versioning). Lần chạy sau update `prd.md` → giữ nguyên `template_version` hiện có, KHÔNG đụng.

**5c. Bump `id_counters`** cho ID vừa cấp (KHÔNG ghi Change History — đã bỏ, history = git; xem `01-architecture.md` §7):

- `prd.md`: mỗi feature/component `[NEW]` trong Feature/Component Index → set `id_counters.feature`/`id_counters.component` = seq lớn nhất vừa cấp (high-water-mark).
- `domain.md`: khi scaffold skeleton, `id_counters.entity` = 0 (chưa có entity nào).
- Ghi frontmatter cùng transaction với body. "Đổi gì · khi nào" = git log của file.

Thông báo kết quả:
```
✓ .specs/main/prd.md đã được cập nhật (status: draft)
{nếu vừa scaffold} ✓ .specs/main/domain.md đã được scaffold (skeleton — sẽ mọc dần qua cascade)

Bước tiếp theo:
  - /spec-sad → thiết kế kiến trúc kỹ thuật
  - (sau sad) /spec-new → bắt đầu integration đầu tiên
```

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Requirements rõ rồi, không cần hỏi nhiều" | Vague requirements tạo ra PRD vague. PRD vague tạo ra implementation sai. |
| "NFR có thể thêm sau" | NFR ảnh hưởng đến architecture decisions. Thêm sau là refactor kiến trúc. |
| "Out of scope thì không cần ghi" | Không ghi out of scope = scope creep không kiểm soát được. |
| "Target users ai cũng biết rồi" | Persona chưa được viết ra là persona chưa được đồng thuận. |

## Red Flags

- PRD dùng từ ngữ không đo đếm được: "nhanh", "bảo mật", "dễ dùng"
- NFRs bỏ trống hoàn toàn
- Scope chỉ có In Scope, không có Out of Scope
- Problem Statement viết theo góc nhìn kỹ thuật thay vì business

## Verification

Trước khi kết thúc, kiểm tra:

- [ ] Frontmatter đầy đủ và đúng schema (id, type, status, owner, project_name, `template_version`) — `template_version` copy từ template lúc create, update không đụng
- [ ] Problem Statement từ góc nhìn business, không mention tech stack
- [ ] Mỗi persona có: tên vai trò, mục tiêu, pain point
- [ ] Out of Scope có ít nhất 1 item với lý do
- [ ] Features có ít nhất 1 item, mỗi item có ID (F-XXX), tên, mô tả, priority. Mỗi item pass litmus test (đơn vị delivery, không phải ownership)
- [ ] Components: mọi entry là **Given** (trúng câu 1 External hoặc câu 2 Mandated-substrate). Không có component **Derived** (boundary phụ thuộc carve lõi nghiệp vụ — thuộc `/spec-sad`). Có thể trống. Mỗi item có ID (C-XXX), tên kebab-case, mô tả 1 câu
- [ ] Đã chạy **Phép thử tính kép** cho mọi component Given: mục có cả mặt UX riêng (vd auth/notification/file-storage) được đăng ký ở **CẢ** Feature Index lẫn Component Index, mô tả mỗi mặt thu hẹp đúng phạm vi (UX→feature, năng lực→component)
- [ ] Nếu input context có sẵn feature/component: đã reuse làm baseline, đã validate qua litmus + Given/Derived + Phép thử tính kép, đã flag mục phân loại sai (nếu có)
- [ ] Mỗi NFR có target đo được (không phải "nhanh", "bảo mật chung chung")
- [ ] domain.md tồn tại (đã scaffold skeleton hoặc có nội dung sẵn)
- [ ] User đã confirm trước khi file được ghi
