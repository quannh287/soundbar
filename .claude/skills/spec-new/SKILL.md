---
name: spec-new
description: Tạo spec.md cho một integration mới thông qua interview có cấu trúc. Dùng khi bắt đầu implement một feature hoặc requirement mới. Nhận raw requirement từ argument hoặc chọn feature TODO từ prd.md.
---

# spec-new

## Overview

Tạo `spec.md` cho một integration mới trong `.specs/integrations/{NNN}-{slug}/`.

`spec.md` là functional spec — định nghĩa **what to build**: vấn đề, requirements, acceptance criteria, out of scope. Không chứa technical design.

## When to Use

- Bắt đầu implement một feature mới
- Có raw requirement chưa được spec hóa
- Muốn chọn một feature TODO từ prd.md để bắt đầu

## When NOT to Use

- `prd.md` chưa có → chạy `/spec-prd` trước (skill đó scaffold cả `domain.md` skeleton)
- Muốn thiết kế technical design → dùng `/spec-tech` (cần `spec.md` đã approve trước)
- Chỉ muốn cập nhật spec đã có → edit file trực tiếp

---

## Process

### Bước 0 · Pre-flight: chuẩn bị nhánh Git (chạy TRƯỚC Bước 1)

Mục tiêu: không bao giờ tạo spec/cascade ngay trên nhánh hiện tại của user (có thể là một nhánh đang làm dở) — luôn bắt đầu từ **nhánh chính mới nhất** rồi tách một **nhánh làm việc riêng** cho integration.

**Trước tiên, thông báo cho user toàn bộ việc Git skill sẽ làm** (để user biết trước, đúng tinh thần "agent làm các việc này"):

> Trước khi tạo spec, mình sẽ:
> 1. Pull code mới nhất từ nhánh chính (`{main}`).
> 2. Tạo & checkout một nhánh mới tách từ `{main}` để làm integration này.
>
> (Bạn đang ở nhánh `{current}`.)

**1. Xác định nhánh chính (`{main}`).**
- Không phải git repo → bỏ qua toàn bộ pre-flight, note cho user rồi tiếp Bước 1.
- Có nhánh `develop` → mặc định `{main}` = `develop`. Không có `develop` nhưng có `main`/`master` → dùng nó.
- Mơ hồ (tồn tại cả `develop` lẫn `main`, hoặc remote default khác) → **hỏi user** nhánh nào là nhánh chính. KHÔNG đoán.

**2. Kiểm tra working tree sạch.** `git status` còn thay đổi chưa commit → **DỪNG**, báo user commit/stash trước. KHÔNG tự ý stash/discard.

**3. Checkout + pull nhánh chính:** `git checkout {main}` rồi `git pull`. Pull fail (conflict, không có upstream…) → **DỪNG**, surface lỗi cụ thể, để user xử lý.

**4. Tạo nhánh làm việc mới off `{main}`.** Cần `{NNN}-{slug}` để đặt tên → thực hiện **ngay sau khi xác định slug + số thứ tự ở Bước 4** (xem nhắc ở đó): đề xuất `git checkout -b feat/{NNN}-{slug}`, cho user sửa tên rồi tạo. Mọi việc ghi spec + auto-cascade từ Bước 5/7 diễn ra trên nhánh này.

---

### Bước 1: Xác định input

**Nhận diện ARGUMENT theo thứ tự này** — integration trước raw requirement:

| ARGUMENT | Nhánh |
|---|---|
| khớp số/slug một integration | **dừng**, chỉ sang mã feature — thông điệp ở Cửa 3 ([`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)) |
| khớp mã feature (`F-009`, `F-009-todo-nhac-viec`) **có** `.specs/main/feature/{F-XXX}-*/spec-debt.md` | **Cửa 3 — spec gap · spec drift** (dưới) |
| còn lại | raw requirement → Bước 2 |
| rỗng | chọn feature từ `prd.md` (dưới) |

Khớp integration = `ARGUMENT` là số (`4`, `004`) hoặc slug (`004-todo-bulk-archive`) của một thư mục dưới `.specs/integrations/`. Khớp feature = `ARGUMENT` là `F-XXX` hoặc `F-XXX-{slug}` của một thư mục dưới `.specs/main/feature/`; feature **không** có sổ thì đi tiếp các hàng dưới như trước.

**Vì sao integration được nhận trước:** `/plan`, `/build`, `/review-integration` đều đã coi một argument dạng số/slug là integration. Nếu `/spec-new 004` lại hiểu `"004"` là *yêu cầu nghiệp vụ* thì nó mở interview về chuỗi ba chữ số. Từ 039 nó không mở Cửa 3 nữa — nợ của BA nằm ở sổ của feature — nhưng vẫn phải được nhận ra để chỉ người gõ sang đúng lệnh.

#### Cửa 3 — đóng `spec_gap` · `spec_drift` (029 D3 · 036 D4 · 039)

`spec-debt.md` là sổ nợ của **BA**, **một sổ duy nhất của mỗi feature**, nằm cạnh `frd.md` — `.specs/main/feature/{F-XXX}-{slug}/spec-debt.md` ([`02-artifacts.md §2.3`](../../02-artifacts.md)). Không có sổ của integration, không có bản sao. Hai loại mục: `SG-*` — hành vi hệ cần mà `frd`/`spec.md`/`tech.md` không nói gì; `SD-*` — code làm khác một AC/VR/FAC **có dấu vết**, chỉ BA biết bên nào đúng. Mỗi mục mang `**phát hiện:**` — danh sách các lần thấy (review ở ③ Build, tầng retrofit ở ④ Verify, hoặc ghi tay). `/spec-new {F-XXX}` là **cửa đóng duy nhất** — không đóng ở đây thì `- [ ]` mọc mãi.

Vào bằng số/slug integration ⇒ dừng, **không** interview:

```
Nợ spec nằm ở sổ của feature, cạnh frd — gõ: /spec-new F-002 · /spec-new F-005
```

(mỗi feature trong `features:` của integration đó mà có sổ; không feature nào có sổ ⇒ `{slug}: các feature của nó không có nợ spec nào.`)

**Trước khi liệt kê, hai lần dừng:**

- **Sổ kiểu cũ còn sót** — `find .specs/integrations .specs/tests -name spec-debt.md 2>/dev/null` ra file nào ⇒ dừng, in `Sổ nợ spec kiểu cũ: {đường dẫn} — chạy: npx spec-lite migrate-spec-debt`. BA quyết trên một sổ thiếu mục là quyết thiếu.
- **Hai dòng chính trùng số** — hai mục cùng `SG-n` hoặc cùng `SD-n` trong sổ ⇒ dừng, in cả hai mục kèm luật gộp nhánh ([`01-architecture.md §11`](../../01-architecture.md)): hai mục cùng khoá dò ⇒ gộp, nối những dòng phát hiện chưa có dòng cùng chỗ; khác nhau ⇒ mục của nhánh vào sau lấy số lớn nhất + 1, sửa chỗ trỏ số cũ trên nhánh đó. Chọn mục theo số khi số không còn là định danh là ghi quyết định vào nhầm mục.

Không dừng ⇒ đọc mọi `SG-*` và `SD-*` **chưa quyết** — dòng `- [ ]` **không** có con trỏ `→ {slug}` ngay sau số mục / sau `` `{ID}` `` (đếm theo vị trí, không theo "dòng có chứa `→`") — rồi liệt kê **một danh sách, đánh số liên tục**, gap trước drift. Mục có con trỏ là việc đã lên spec, đang chờ integration đó xong: in ở cuối cho biết, **không** đưa vào danh sách chọn (029 D9).

```
Spec debt của F-002-todo-management (2 gap · 1 drift chưa quyết):

  [1] SG-1 — gửi lệnh lưu trữ hàng loạt với một id không đúng định dạng: hệ báo lỗi máy chủ (500); spec không nói
             phát hiện: ③ Build — review vòng 1 của 004-todo-bulk-archive
             gần nhất: AC-F002-017 · hỏi BA: hệ cần phản hồi thế nào khi id không đúng định dạng?
  [2] SG-2 — …
  [3] SD-1 · AC-F002-016 — lưu trữ hàng loạt có lẫn việc đã lưu trữ: hệ bỏ qua việc đó; AC nói báo lỗi cả lô
             phát hiện: ③ Build — review vòng 1 của 004-todo-bulk-archive · ④ Verify — retrofit functional · TC-F002-031 đỏ
             dấu vết: commit a1b2c3d — "archive lại việc đã archive là no-op, user không cần biết"
             ⚠ trong lúc chưa quyết, ④ Verify không sửa code của AC-F002-016

Đang chờ (đã lên spec, không cần quyết lại):
  SG-3 → 006-todo-error-surface

Gap:   chọn số để đưa vào integration mới, `r {n}: {lý do}` để từ chối.
Drift: chọn số = SỬA REQUIREMENT theo code (integration mới) · `k {n}: {lý do}` = GIỮ requirement, code sai.
```

Không còn mục **chưa quyết** nào ⇒ báo `{F-XXX}-{slug}: mọi spec gap/drift đã được quyết` (kèm danh sách đang chờ, nếu có) rồi dừng.

Xử lý lựa chọn:

| Lựa chọn | Với | Làm gì |
|---|---|---|
| chọn (vd `1 3`) | `SG` | ghép mô tả + câu hỏi của gap thành **requirement text** → Bước 2, interview **bình thường** (ra AC/VR trong `## Changes` như mọi delta khác) |
| chọn | `SD` | **sửa requirement theo code**: requirement text = *"đổi `{ID}` cho khớp hành vi hiện tại: {mô tả} — dấu vết: {dấu vết}"* → Bước 2. Delta là `modify {ID}` trên `frd.md`; code đã làm đúng hành vi mới nên integration mới thường **chỉ đổi spec** |
| `r {n}: {lý do}` | `SG` | ghi ngay `- [x] **SG-n** — {mô tả gốc} — **từ chối:** {lý do} *(/spec-new · {YYYY-MM-DD})*` vào sổ. **Giữ `{mô tả}`** và giữ mọi sub-bullet — sổ mất mô tả là mất chính thứ nó ghi |
| `k {n}: {lý do}` | `SD` | **giữ requirement, code sai**: ghi ngay `` - [x] **SD-n** · `{ID}` — {mô tả gốc} — **giữ spec:** {lý do} *(/spec-new · {YYYY-MM-DD})* `` vào sổ, giữ `{ID}` + `{mô tả}` + mọi sub-bullet. **Không** tạo integration: dòng `[x]` mở khoá cho ④ Verify — từ giờ tầng retrofit xếp finding của `{ID}` là `bug-code` (retrofit-core §5 tra sổ). Finding đã nằm sẵn trong report với nhãn `spec-drift` thì phải chạy lại tầng đó để nhãn đổi: in `/spec-test-retrofit-{scope} {F-XXX} --mode execute` (scope = file `test-report-{scope}.md` có `FIND-*` **hoặc** dòng việc `A-*` neo `{ID}` — dòng việc có ở ca `SD` mở mà không test nào đỏ; không file nào có thì scope theo tiền tố ID: `VR` → validation · `AC` → functional · `FAC` → e2e) rồi `/verify-v2 {F-XXX}` |
| `r` trên `SD` · `k` trên `SG` | — | báo sai lệnh, hỏi lại. Drift không "từ chối" được: một trong hai bên sai, BA phải chọn bên nào |
| không chọn gì | — | kết thúc, **không** tạo integration |

**Mỗi lựa chọn đổi đúng một dòng chính** trong sổ — mỗi khoản nợ chỉ có một mục.

**Ghi ngược sau khi `spec.md` mới được ghi** (Bước 7.3), hai thứ:

1. Trong sổ: dòng đã chọn thành `- [ ] **SG-n** → {NNN}-{slug mới} — {mô tả cũ} *(/spec-new · {YYYY-MM-DD})*` — với drift `` - [ ] **SD-n** · `{ID}` → {NNN}-{slug mới} — {mô tả cũ} *(/spec-new · {YYYY-MM-DD})* `` (giữ ID trước `→`). **Vẫn `- [ ]`, KHÔNG tick** — drift có `→` vẫn là drift **mở**, ④ Verify vẫn không sửa code của `{ID}` cho tới khi `/archive {slug mới}` tick: lúc đó requirement đã đổi theo code, finding tự hết.
2. Trong `## Context` của `spec.md` **mới**: một dòng provenance — `**Nguồn:** spec gap SG-n của {F-XXX}-{slug}` / `**Nguồn:** spec drift SD-n của {F-XXX}-{slug}`.

Cả hai ghi trên **nhánh của integration mới**, cùng commit với `spec.md` — một PR mang cả yêu cầu mới lẫn dấu đã nhận việc.

**Vì sao KHÔNG tick ở đây (029 D9).** `[x]` trong một sổ nợ thì ai đọc cũng hiểu là **đã xong**. Lúc này gap chỉ *đã có người nhận*: `spec.md` mới còn phải qua `/spec-tech`, `/implement`, review, merge. Nếu integration đó bị bỏ dở mà sổ đã `[x]` thì bản ghi **sai vĩnh viễn** — tệ hơn một ô còn mở. `[x]` do **`/archive {slug mới}`** đặt, nghĩa là việc đã xong và được dọn.

Gap từ chối và drift `giữ spec` thì `[x]` ngay: không có integration nào phải chờ. **Mọi trạng thái giữ nguyên `{mô tả}` gốc** — kể cả từ chối; một dòng chỉ còn lý do thì sáu tháng sau không ai biết đã từ chối **cái gì**.

**Suffix nguồn `*({nguồn} · {date})*` bắt buộc trên mọi lần đổi trạng thái** (tập đóng `/spec-new` · `/archive` · `tay: {ai/lý do}`). Sổ này thường được đọc **sau khi** integration nguồn đã archive, lúc `git log --follow` một file dưới `.specs/archive/` đã đắt và khó; dòng phải tự nói ai đổi nó và khi nào. Dòng **chưa quyết** không mang suffix — provenance của lần mở nằm ở heading section.

Gap **không** đi tắt: nó vào interview như một raw requirement, ra AC/VR qua `## Changes` và cascade lên `frd.md` như mọi delta khác. `/review-integration` chỉ **mở** gap; nó không được viết AC thay BA.

**Nếu không có ARGUMENT:**

Đọc `.specs/main/prd.md`. Nếu file không tồn tại hoặc là template rỗng → dừng:
> `prd.md` chưa có nội dung. Hãy chạy `/spec-prd` trước.

Đọc toàn bộ bảng Features. Hiển thị **tất cả** features kèm trạng thái — không lọc — để thấy rõ feature nào có FRD cần update:

```
Features trong PRD:

  [1] F-001 — Authentication        (High)    [TODO]
  [2] F-002 — User Profile          (Medium)  [In Progress]  → frd.md tồn tại
  [3] F-003 — App Browsing & Opt-in (High)    [TODO]
  [4] F-004 — Credit System         (High)    [Done]         → frd.md tồn tại
  [5] F-006 — Admin Panel           (Medium)  [TODO]

Chọn số feature để bắt đầu spec:
```

Ghi chú `→ frd.md tồn tại` nếu file `.specs/main/feature/{F-XXX}-*/frd.md` đã có.

Nếu tất cả features đều Done → thông báo:
> Tất cả features trong prd.md đã được implement. Nếu có yêu cầu mới, hãy truyền nó trực tiếp: `/spec-new <yêu cầu>`.

Sau khi user chọn feature:

- Nếu feature **chưa có frd.md** → lấy feature đó làm requirement, chuyển sang Bước 2.
- Nếu feature **đã có frd.md** → đọc file frd.md, liệt kê các sections và hỏi ngay:

```
frd.md — F-001 Authentication đã tồn tại.
Sections hiện có:

  [1] Overview
  [2] User Flows
  [3] Feature Acceptance Criteria (end-to-end)
  [4] Non-Functional Requirements
  [5] Data & Migration (required-emptyable)
  [6] User Stories
  [7] Verification Rules
  [8] Scope (In Scope / Out of Scope)
  [9] Dependencies (Feature Dependencies + Components Used)
  [A] All — viết lại toàn bộ từ đầu
  [S] Lên spec từ frd.md hiện tại — frd.md đã đầy đủ, không cần chỉnh

Chọn (có thể chọn nhiều section, ví dụ: 2 3):
```

Lưu lại lựa chọn section.
- Nếu chọn `A` → xử lý như tạo mới toàn bộ. Sau đó chuyển sang Bước 2.
- Nếu chọn `S` → **bỏ qua Bước 3 (Interview)**. Dùng nội dung frd.md hiện tại làm input để sinh spec.md. Chuyển thẳng sang Bước 4.
- Nếu chọn số section → cập nhật section đó. Sau đó chuyển sang Bước 2.

---

### Bước 2: Load context

Từ raw requirement, agent xác định features và components liên quan, rồi load các file sau:

- `.specs/main/prd.md` — đọc Problem Statement, Target Users, Scope, Feature Index, Component Index; **đặc biệt ghi nhận cột `ADO` trong bảng Features** — nếu feature đã có ticket ID thì lưu lại `{feature_id → ado_ticket_id, ado_ticket_title, ado_ticket_url}`
- `.specs/main/domain.md` — đọc Glossary và Shared Entities
- `.specs/main/feature/{F-XXX}-{slug}/frd.md` — cho mỗi feature liên quan (nếu file đã tồn tại)
- `.specs/main/component/{C-XXX}-{slug}/crd.md` — cho mỗi component bị touched (nếu file đã tồn tại)

Tóm tắt context và surface assumptions:

```
TỪ PRD & DOMAIN TÔI HIỂU:
- Vấn đề đang giải quyết: {problem statement ngắn từ prd}
- Personas liên quan: {từ prd Target Users}
- Glossary terms liên quan: {từ domain.md}
- Shared entities liên quan: {từ domain.md}
{nếu có feature liên quan} - Features: {F-XXX — tên — mô tả ngắn}
{nếu có component liên quan} - Components: {C-XXX — tên — mô tả ngắn}

ASSUMPTIONS TÔI ĐANG ĐẶT RA:
1. {assumption về scope}
2. {assumption về features/components bị touched}
→ Sửa lại nếu sai trước khi tiếp tục.
```

Nếu integration giới thiệu feature mới hoặc component mới chưa có trong PRD Index → ghi nhận để cascade ở Bước 5.

---

### Bước 3: Interview

Hỏi tuần tự, từng phần — không hỏi tất cả cùng lúc:

**Phần 1 — Problem Statement:**
> Vấn đề cụ thể cần giải quyết trong integration này là gì? Tại sao cần làm ngay bây giờ?
> (Đây là scope của integration này — không phải toàn bộ feature)

**Phần 2 — Requirements:**
> Requirements cụ thể là gì? Ghi theo dạng user stories: "As a {persona}, I want to {action} so that {value}"
> Hoặc liệt kê functional requirements nếu không theo user story format.

**Phần 3 — Acceptance Criteria:**
> Điều kiện nào để biết integration này là done? Format Given/When/Then.
> Agent tự nhóm AC theo cách phù hợp với bản chất integration:
> - Có user-facing flow → group theo Feature → User Story → AC, dùng ID `AC-{F_ID}-{seq}`
> - Thuần technical (refactor / capability nội tại) → group theo Component, dùng ID `AC-{C_ID}-{seq}`, không cần user story
> - Mixed (vừa thêm feature, vừa thay đổi component) → có thể có cả 2 nhóm

**Phần 4 — Out of Scope:**
> Có gì liên quan nhưng sẽ KHÔNG làm trong integration này không? Ghi rõ lý do.

Nếu câu trả lời vague → hỏi lại để làm rõ. Ví dụ:
- "user phải login được" → "login bằng gì? email/password, OAuth, hay cả hai? Response là gì?"
- "hiển thị danh sách" → "hiển thị những field nào? có filter/sort/pagination không?"

---

### Bước 4: Xác định slug và output path

Từ title của integration, sinh slug:
- Lowercase, dùng dấu gạch ngang, không có ký tự đặc biệt
- Ví dụ: "User Authentication" → `user-authentication`
- Nếu từ prd.md: dùng `{feature-id}-{feature-slug}`, ví dụ: `f001-authentication`

Xác định số thứ tự (`NNN`):
- Liệt kê các thư mục hiện có trong `.specs/integrations/` theo pattern `{NNN}-*`
- Lấy số lớn nhất hiện có và cộng thêm 1, format 3 chữ số (ví dụ: `001`, `002`, `012`)
- Nếu chưa có thư mục nào → bắt đầu từ `001`

Output path: `.specs/integrations/{NNN}-{slug}/spec.md`

**Tạo nhánh làm việc** (Pre-flight bước 4) — giờ đã có `{NNN}-{slug}`: `git checkout -b feat/{NNN}-{slug}` off `{main}` (đề xuất tên, cho user sửa). Bỏ qua nếu không phải git repo (pre-flight đã note).

---

### Bước 5: Write — sinh draft

Tổng hợp và viết draft `spec.md`. **spec.md = changeset patch** áp lên main artifacts. Cấu trúc theo `templates/integrations/spec-template.md`: Context, Problem Statement, **Changes** (per-artifact blocks), Out of Scope, Open Questions, Cascade Summary.

**ADO references từ prd.md:** Với mỗi Feature heading (`### Feature: <name> (<ID>)`) trong spec.md, nếu feature đó đã có ADO ticket trong `prd.md` → thêm ngay dòng `**ADO:**` bên dưới heading:

```markdown
### Feature: Đăng ký / Đăng nhập (F-001)
**ADO:** [#12345 — [SDLC-TEST] Đăng ký / Đăng nhập](https://dev.azure.com/...)
```

Điều này đảm bảo `/ado-create` nhận biết feature đã có ticket và không tạo duplicate.

#### Sinh `## Changes` section

Với mỗi main artifact bị touched (frd, crd, prd, domain, sad), tạo 1 block. Bỏ block nếu artifact không bị thay đổi.

**Xác định operation:**
- `create` — artifact chưa tồn tại
- `update` — artifact đã tồn tại

**Diff against current state:**

Context đã load artifact hiện tại ở Bước 2. Agent so sánh nội dung mới với current state để gán marker per item:

| Marker | Khi nào dùng |
| --- | --- |
| `[NEW]` | Item chưa có trong artifact hiện tại |
| `[MODIFY {field}]` | Item đã có, đang đổi field cụ thể. Ghi rõ field nào: `[MODIFY priority]`, `[MODIFY rule]`, `[MODIFY status]` |
| `[REMOVE]` | Item đã có, sẽ bị xóa khỏi artifact |

Operation=create → không cần marker, mọi item implicit là [NEW].

**Một luật một item.** Câu mới nói về **cùng một luật** với một câu đang có (cùng field, cùng tình huống — vd "tối đa 5 lần" với `VR-F008-001` "tối đa 3 lần") ⇒ viết `[MODIFY {field}]` câu cũ, **không** viết `[NEW]` song song, kể cả khi requirement không nhắc câu cũ. Hai VR cho cùng một field là hai luật cho cùng một việc. Requirement không nhắc đích danh câu cũ thì `[MODIFY]` đó **là** một mâu thuẫn — Bước 5b đưa nó ra cho BA quyết; viết `[NEW]` để né không làm mâu thuẫn biến mất, chỉ làm nó khó thấy hơn.

**ID assignment:**

Đọc `id_counters` trong frontmatter của main artifact đích để cấp ID (nguồn sự thật, high-water-mark — `01-architecture.md` §7):
- `frd.md` → `id_counters.us`/`.ac`/`.vr`/… cho `US-F{NNN}-{seq}`/`AC-F{NNN}-{seq}`/`VR-F{NNN}-{seq}`
- `crd.md` → `id_counters.rule` cho `C-XXX-R{seq}`

ID mới = `id_counters.<family> + 1`, format 3 chữ số (rule: 2 chữ số theo template); cấp xong **bump** counter. ID **stable** — không tái sử dụng khi [REMOVE] (counter không giảm), không renumber khi [MODIFY]. Artifact tạo mới → counter khởi từ 0, ID đầu = `001`.

**Format reference:** Mỗi Changes block dùng đúng format của template gốc:
- `feature/{F-XXX}/frd.md` → [frd-template.md](../../templates/main/feature/frd-template.md)
- `component/{C-XXX}/crd.md` → [crd-template.md](../../templates/main/component/crd-template.md)
- `prd.md` → [prd-template.md](../../templates/main/prd-template.md)
- `domain.md` → [domain-template.md](../../templates/main/domain-template.md)
- `sad.md` → [sad-template.md](../../templates/main/sad-template.md)

Template gốc là single source of truth cho format. KHÔNG duplicate skeleton vào spec.md.

#### Per-artifact guidance

**`feature/{F-XXX}-{feature-slug}/frd.md`**

Liệt kê **tất cả** features liên quan đến integration và đánh giá từng cái. Không được bỏ qua feature nào — kể cả feature `Done` vẫn phải đánh giá xem spec mới có làm thay đổi scope không.

- Operation=create khi frd.md chưa tồn tại → nội dung đầy đủ các section: Overview, User Flows, Feature Acceptance Criteria (end-to-end), Non-Functional Requirements (required-emptyable), Data & Migration (required-emptyable), User Stories, Verification Rules, Scope, Dependencies.
- Operation=update khi frd.md đã tồn tại → hỏi user chọn section cần update:

```
frd.md — F-001 Authentication đã tồn tại.
Sections hiện có:

  [1] Overview
  [2] User Flows
  [3] Feature Acceptance Criteria (end-to-end)
  [4] Non-Functional Requirements
  [5] Data & Migration (required-emptyable)
  [6] User Stories
  [7] Verification Rules
  [8] Scope (In Scope / Out of Scope)
  [9] Dependencies (Feature Dependencies + Components Used)
  [A] All — viết lại toàn bộ từ đầu

Chọn section cần cập nhật (có thể chọn nhiều, ví dụ: 2 3):
```

Chỉ sinh nội dung cho section đã chọn. Nếu chọn `A` → operation=update với toàn bộ 7 sections.

**Verification Rules** trong frd.md changes block: xem mục "Verification Rules — quy ước sinh" bên dưới.

**`component/{C-XXX}-{component-slug}/crd.md`**

Liệt kê **tất cả** components bị touched.

- Operation=create khi crd.md chưa tồn tại → auto-pick `C-XXX` next available + slug kebab-case, nội dung đầy đủ: Role, Responsibilities, Owned Entities, Public Interface, Business Rules, Dependencies.
- Operation=update khi crd.md đã tồn tại → chỉ section bị ảnh hưởng, có markers.

Component-level AC dùng ID `AC-C{NNN}-{seq}`, gắn vào responsibility/interface/rule liên quan.

**`prd.md`**

Tạo block nếu integration:
- Giới thiệu feature mới chưa có trong Feature Index → row [NEW] (auto-pick `F-XXX` next available)
- Giới thiệu component mới chưa có trong Component Index → row [NEW] (auto-pick `C-XXX` next available)
- Đổi status feature → row [MODIFY status]: `TODO → In Progress`
- Có scope hoặc NFR thay đổi

**`domain.md`**

Tạo block nếu integration:
- Giới thiệu glossary term mới → row [NEW] trong Glossary
- Giới thiệu shared entity mới (entity sẽ được dùng bởi 2+ component) → entity [NEW] với heading `### E-XXX {Entity Name}` (auto-pick `E-XXX` = `id_counters.entity + 1` trong `domain.md`, bump counter sau khi cấp — quy ước `domain-template.md`; ID không tái sử dụng) và `Owner: C-XXX` (component đã carve trong integration này); component chưa carve → `Owner: TBD`, `/spec-sad` gán sau (xem two-phase cascade `01-architecture.md` §7)
- Gán owner cho entity còn `Owner: TBD` (do pha mô tả seed) → entity [MODIFY Owner] `TBD → C-XXX` (giữ nguyên `E-XXX`)
- Sửa định nghĩa entity hiện có → entity [MODIFY ...] (giữ nguyên `E-XXX`)
- Remove entity → [REMOVE] kèm lý do — ID của entity đã remove vẫn giữ chỗ, không cấp lại

**`sad.md`**

Hiếm khi thay đổi per integration. Tạo block chỉ khi:
- Có cross-cutting concern mới
- Có guardrail mới
- Có thay đổi tech stack

#### Verification Rules — quy ước sinh

Áp dụng khi sinh hoặc cập nhật section `Verification Rules` trong `frd.md`.

**Nguyên tắc:**
- Verification Rules là **business decision** — BA owns. Agent **KHÔNG** được tự assert rule.
- Agent đóng vai **option-suggester**, không phải decision-maker.

**Quy trình:**

1. Scan các User Stories vừa confirm. Detect mọi input field user nhập (form field, query param, request body...).

2. Với mỗi field, **suggest 2-4 phương án validation** dựa trên field name + semantic type + common patterns. Luôn kèm option `Custom` và `TBD`.

   Ví dụ với field `password`:
   ```
   Verification rules cho `password` (type: string)?
     [A] ≥ 8 ký tự, có chữ hoa + số                   (baseline common)
     [B] ≥ 12 ký tự, có chữ hoa + số + ký tự đặc biệt (strict)
     [C] ≥ 6 ký tự, không yêu cầu thêm                (loose, internal tool)
     [D] Custom — BA mô tả tay
     [E] TBD — quyết định sau
   ```

3. BA chọn → agent **auto-assign Rule ID** `VR-F{NNN}-{seq}` và ghi vào bảng `Verification Rules` của frd.md. Chọn `Custom` → hỏi tiếp. Chọn `TBD` → ghi `TBD` ở cột Rule (vẫn assign ID để referencable) và list ra ở cuối draft để BA follow-up.

4. **Ghi cột `Refs` cùng lúc — không để sau.** `Refs` = story mà bước 1 vừa scan ra field đó (`US-F{NNN}-{seq}`), thêm `AC-*` khi có một AC cụ thể đòi rule này. `Refs` **bắt buộc non-empty** (035 D0 · `frd-template` § Verification Rules > Quy ước > `Refs`).

   **Không neo được vào story nào ⇒ `NEEDS_CLARIFY`, KHÔNG ghi row.** Ca này nghĩa là rule đến từ đâu đó ngoài các story vừa confirm — hỏi BA rule ấy phục vụ story nào, hoặc story nào còn thiếu. Ghi row với `Refs` rỗng thì `/plan` và `/implement` **lọc nó ra mất** (cả hai lọc VR theo `Refs`) mà không dòng báo nào, trong khi row vẫn trông như đã xử lý.

   Điền `Refs` là việc **cơ học** ở đây — bước 1 vừa scan field ra từ một story cụ thể, nên câu trả lời có sẵn. Để sang lượt sau là mất thông tin đó.

**Quy ước Rule ID (`VR-F{NNN}-{seq}`):**
- `NNN` = feature ID, `seq` = số thứ tự 3 chữ số tăng dần toàn feature, **không reset** theo field.
- Khi **tạo mới frd.md**: `id_counters.vr` khởi từ 0 → `VR-F{NNN}-001`, tăng tuần tự theo thứ tự rule được BA confirm, bump counter mỗi lần cấp.
- Khi **update frd.md hiện có**: seq tiếp theo = `id_counters.vr + 1`, bump sau khi cấp. **Không tái sử dụng** ID đã từng tồn tại (counter không giảm khi rule bị xóa). **Không renumber** rule cũ.
- Sub-rule phức tạp (ví dụ password complexity 4 điều kiện) → **tách flat** thành nhiều rules riêng, mỗi cái 1 ID (`VR-F001-005`, `VR-F001-006`...). Không dùng hierarchy (`-005a`, `-005b`).

**Heuristic suggest theo field name (gợi ý, không bắt buộc):**

| Field name pattern | Categories cần hỏi |
|---|---|
| `email`, `*_email` | format, required, unique (nếu là identifier) |
| `password`, `pwd` | min length, complexity, max length |
| `username`, `login` | length range, allowed chars, unique |
| `*_at`, `*_date`, `birthday` | format, range (past/future), timezone |
| `age`, `quantity`, `*_count` | type (integer), range (min/max), positive |
| `phone`, `mobile` | format (E.164 / local), length |
| `url`, `link` | format, allowed protocols |
| `*_id`, `id` | type (UUID/integer), exists in domain |

**Cấm:**
- ❌ Tự điền rule vào bảng mà chưa hỏi BA.
- ❌ Suggest chỉ 1 option và mặc định chấp nhận.
- ❌ Đưa regex, validator code, hoặc error message vào bảng (regex/validator là HOW thuộc `fdd.md`; error/hint message là UI copy ở artifact khác).
- ❌ Dùng tech type (`varchar(255)`, `int32`...) — phải dùng semantic type (`string`, `integer`, `email`, `enum<...>`...).

Cuối Bước 5: tổng hợp **Cascade Summary** table — mỗi row 1 artifact với operation + summary ngắn (vd `+1 US, +2 VR, modify VR-F001-003`). Chạy **Bước 5b** trên bản nháp này, rồi mới hiển thị **toàn bộ draft** (Context, Problem, Changes, Conflicts nếu có, Out of Scope, Open Questions, Cascade Summary) cho user xem — **chưa ghi file, chưa cascade**.

---

### Bước 5b: Kiểm mâu thuẫn với requirement đang có ([`.docs/038`](../../.docs/038-spec-new-bat-mau-thuan.md))

Bản nháp nói cái **mới**; `.specs/main/` nói cái **đang có**. Bước 5 đã gắn `[NEW]`/`[MODIFY]`/`[REMOVE]` — nó trả lời *"item này có chưa"*. Bước này trả lời câu Bước 5 không hỏi: *"cái mới và cái cũ có cùng đúng được không"*. Chạy trên **mọi** bản nháp — raw requirement, đường `S`, hay vào từ Cửa 3.

Không có bước này thì hai câu trái nhau bị xử lặng lẽ: hoặc câu cũ thành `[MODIFY]` như thể BA đã muốn sửa, hoặc câu mới nằm cạnh câu cũ trong cùng `frd`. Chỗ trái nhau thường nằm ở feature mà requirement **không nhắc** — Bước 2 không mở nó ra — và chỉ lộ khi đã có code.

#### [5b.1] Dựng tập so

| Nguồn | Đọc phần nào | Vào tập so khi |
| --- | --- | --- |
| `frd.md` của feature Bước 2 nhận ra | Overview · User Flows · Feature Acceptance Criteria · User Stories (AC) · Verification Rules · Scope (In / Out) | luôn luôn |
| `frd.md` của feature khác | như trên | grep ra ít nhất một khoá (dưới) |
| `crd.md` | Business Rules (`C-XXX-RXX`) | component có block trong `## Changes`, Bước 2 đã nhận ra nó, **hoặc** grep ra ít nhất một khoá |
| `prd.md` | `### Out of Scope` | luôn luôn |
| `prd.md` | cột `Mô tả` ở bảng Features, đúng row của từng feature đã vào tập so | feature đó vào tập so — row mô tả cũng là một câu requirement (vd "hoãn … tối đa 3 lần") |

**Khoá grep** — lấy từ mọi item `[NEW]`/`[MODIFY]`/`[REMOVE]` của bản nháp, và chỉ từ **phần câu mới khác câu cũ** — riêng **field của item bị đổi luôn là khoá** (`VR-F008-001` đổi "3 lần" → "5 lần" thì `so_lan_hoan` vẫn là khoá dù tên field không đổi). Chữ chép nguyên từ câu cũ ("một việc chưa `Done`", "hạn hoàn thành giữ nguyên") không phải khoá — nó có sẵn ở câu cũ nên không đụng được gì mới, và gần như AC nào cũng có:

| Khoá | Ví dụ | Không dùng |
| --- | --- | --- |
| tên field ở cột `Field` của VR, hoặc field mà Given/Then nói tới — Given/Then viết bằng chữ ("hạn hoàn thành") thì lấy **cả** tên field (`han_hoan_thanh`) lẫn thuật ngữ | `han_hoan_thanh`, `so_lan_hoan` | — |
| giá trị trạng thái mà câu mới **đổi hành vi** ở trạng thái đó | `Done` khi câu mới nói việc `Done` được/không được làm gì | trạng thái chỉ xuất hiện như điều kiện chép lại từ câu cũ ("một việc chưa `Done`") — gần như AC nào cũng có |
| thuật ngữ trong Glossary của `domain.md` mà bản nháp dùng | `hạn hoàn thành`, `Overdue` | **tên entity** (`todo`, `User`) — gần như `frd` nào cũng có, lọc theo nó là đọc hết |

```bash
grep -l -F -e '{field}' -e '{trạng thái}' .specs/main/feature/*/frd.md     # phân biệt hoa thường: `Done` ≠ "done"
grep -l -i -F -e '{thuật ngữ}' .specs/main/feature/*/frd.md
# cùng hai lệnh trên cho .specs/main/component/*/crd.md
```

Ghi lại feature nào vào tập so **vì khoá nào** — dòng đầu khối in (5b.3) cần nó.

#### [5b.2] So từng item — ba loại mâu thuẫn

Đây là **nơi định nghĩa duy nhất** của ba nhãn dưới; doc khác trỏ về đây.

| Nhãn | Khi nào | Ví dụ |
| --- | --- | --- |
| `trái nhau` | trên **cùng một tình huống**, câu mới và câu cũ đòi hai kết quả khác nhau | "hoãn tối đa 5 lần" ↔ `VR-F008-001` "tối đa 3 lần" |
| `cái cũ hết đúng` | câu mới không nhắc câu cũ, nhưng làm Given của câu cũ **không còn xảy ra** (hoặc chỉ còn xảy ra với dữ liệu cũ), hoặc làm gãy một bước của User Flow / FAC | "việc không nhập hạn tự nhận hạn +7 ngày" ↔ `AC-F009-003` "việc không có hạn ⇒ không có lịch nhắc" |
| `ngoài phạm vi` | câu mới làm điều mà `Out of Scope` của `frd` hoặc `prd` đã loại | "chọn nhắc trước 1/2/3 ngày" ↔ Out of Scope `F-009` "Chọn số ngày nhắc trước hạn — v1 luôn là 1 ngày" |

**Không phải mâu thuẫn:** item cũ mà raw requirement, hoặc câu trả lời phỏng vấn, **nhắc đích danh** (bằng ID, hoặc trích đúng câu) để đổi. Ý định đã rõ ⇒ đi thẳng `[MODIFY]`/`[REMOVE]` như Bước 5, không in dòng.

**Một luật viết lại ở nhiều chỗ** (VR + dòng Scope + nhánh User Flow + Overview + mô tả ở `prd` cùng nói "tối đa 3 lần") ⇒ **một dòng**, neo vào chỗ có ID theo thứ tự `VR` → `AC` → `FAC` → `C-XXX-RXX`, các chỗ kia liệt kê ở `cũ:` của dòng đó. Phía mới cũng vậy: VR + các AC cùng nói "tối đa 5 lần" gộp vào `mới:` của cùng dòng. In ba dòng cho một luật là bắt BA quyết ba lần một việc.

Câu cũ không có ID thì ghi bằng vị trí: `Scope (F-008): "Từ chối hoãn việc … chưa có hạn hoàn thành"`.

**Dòng dựa vào một điều spec không nói** (vd "việc không có hạn chỉ còn là việc tạo trước" đúng chỉ khi sửa việc không xoá được hạn, mà `frd` không nói) ⇒ vẫn in, thêm dưới dòng đó một dòng `ⓘ` nêu giả định. Bỏ dòng vì không chắc là giấu đúng thứ bước này phải đưa ra.

#### [5b.3] In cho BA

```
Mâu thuẫn với requirement hiện có (3) — đã so: F-002 (Bước 2) · F-005, F-008, F-009 (khoá `han_hoan_thanh`) · prd Out of Scope

  [1] cái cũ hết đúng · AC-F009-003 (F-009)
        cũ:  việc chưa Done, không có hạn ⇒ không có lịch nhắc   (+ Flow 1 nhánh "Việc có hạn? Không")
        mới: AC-F002-0xx — việc tạo không nhập hạn tự nhận hạn = ngày tạo + 7 ngày
        vì:  từ nay chỉ việc tạo trước thay đổi này mới có thể không có hạn
  [2] cái cũ hết đúng · AC-F005-001 (F-005)
        cũ:  …
        mới: …
        vì:  …
  [3] cái cũ hết đúng · Scope (F-008): "Từ chối hoãn việc … chưa có hạn hoàn thành"
        …

Mỗi dòng chọn một:  m {n} = giữ cái mới · c {n} = giữ cái cũ · q {n} = chưa quyết   (vd: m 1 q 2 c 3)
```

Không có dòng nào ⇒ in **một dòng** rồi sang Bước 6 — vẫn in tập so, để BA thấy feature nào **chưa** được so:

```
Không thấy mâu thuẫn — đã so: F-008 (khoá `so_lan_hoan`) · prd Out of Scope
```

#### [5b.4] Áp lựa chọn

| Lệnh | Bản nháp đổi gì | Cột `Chọn` ở `## Conflicts` |
| --- | --- | --- |
| `m {n}` | **mọi** chỗ liệt kê ở `cũ:` của dòng có marker ở `## Changes` của artifact chứa nó: giữ `[MODIFY {field}]` Bước 5 đã viết, hoặc thêm `[MODIFY {field}]` / `[REMOVE]` cho chỗ chưa có (Out of Scope ⇒ `[REMOVE]` dòng đó; mô tả ở `prd` ⇒ `[MODIFY Mô tả]`). Dòng loại `cái cũ hết đúng` ⇒ câu cũ không sai, chỉ hẹp đi: agent **đề xuất** bản thu hẹp (vd thêm vào Given *"— chỉ còn gặp ở việc tạo trước `AC-F002-020`"*) hoặc `[REMOVE]` nếu phần còn lại không còn xảy ra, BA chốt câu chữ ở Bước 6. Chỗ **không có ID** (dòng Scope, nút User Flow) ⇒ thêm section đó vào block như thể BA đã chọn nó ở Bước 5, viết lại đúng dòng/nút đó, phần còn lại của section giữ nguyên — `m` đã là lựa chọn sửa câu cũ, không hỏi lại section. Artifact chưa có block ⇒ thêm block `update`, và feature/component đó vào `features:`/`components:` của spec | `giữ mới` |
| `c {n}` | `trái nhau` · `ngoài phạm vi`: câu mới bị sửa hoặc bỏ khỏi bản nháp — `[MODIFY]` câu cũ mà Bước 5 đã viết thì bỏ marker đó; bỏ mà làm hụt requirement thì hỏi BA câu thay thế. `cái cũ hết đúng`: câu cũ giữ nguyên, câu mới **vẫn vào** — BA xác nhận câu cũ còn có nghĩa (vd với dữ liệu tạo trước thay đổi) | `giữ cũ` |
| `q {n}` | `trái nhau` · `ngoài phạm vi`: câu mới **rút khỏi** `## Changes`, thành một dòng ở `## Open Questions` (ghi cả câu cũ lẫn câu mới). Mọi dòng khác dùng **chung** câu mới đó hết hiệu lực — không còn câu mới để đụng — in ra cho BA biết, cột `Chọn` của chúng ghi `chưa quyết (theo dòng {n})`. `cái cũ hết đúng`: câu mới **vẫn vào**, câu cũ giữ nguyên, `## Open Questions` ghi một dòng *"{câu cũ} còn giữ không?"* | `chưa quyết` |
| thiếu dòng · lệnh sai · `m`+`c` cùng một số | hỏi lại, nhắc lại đúng các dòng còn thiếu. **Không** áp lựa chọn nào — kể cả các dòng đã chọn hợp lệ — và **không** sang Bước 6 | — |

**Hai câu trái nhau không bao giờ cùng vào main artifact.** Đó là lý do `q` trên dòng `trái nhau` · `ngoài phạm vi` rút câu mới ra chứ không để nó nằm chờ trong `## Changes`: `## Changes` là thứ Bước 7 cascade, `## Open Questions` thì không. Dòng `cái cũ hết đúng` thì khác: hai câu không đòi hai kết quả trên cùng một tình huống (câu cũ vẫn đúng với dữ liệu cũ), nên cùng vào main không phá luật này — rút câu mới ra lại làm hỏng các dòng khác dùng chung nó.

Áp xong mà bản nháp có đổi (`m` thêm block, `c` sửa câu) ⇒ chạy lại 5b.1–5b.3 **một lần** trên bản nháp mới, chỉ in dòng chưa có ở lượt trước — lựa chọn có thể đẻ chỗ đụng mới (block vừa thêm chạm thêm một feature). Không có dòng mới ⇒ in `Không thấy mâu thuẫn mới — đã so: {tập so}`. Lượt chạy lại tìm thêm một chỗ cũ **cùng luật** với một dòng đã quyết (vd Overview nhắc lại luật đó) ⇒ không thành dòng mới: áp cùng lựa chọn của dòng đó, in một dòng `ⓘ {chỗ} — cùng luật với dòng [n], áp theo {lựa chọn}` để BA thấy ở Bước 6, và thêm chỗ đó vào cột `Cũ` ở `## Conflicts`.

**Marker cho chỗ không có ID** (dòng Scope, nút User Flow, mô tả ở `prd`): `[MODIFY]` kèm cặp câu nguyên văn — `` [MODIFY] `"chặn ở 3 lần"` → `"chặn ở 5 lần"` `` (nút Flow ghi kèm id nút: `` [MODIFY nút E] ``). Chuỗi cũ là đoạn **ngắn nhất** khớp đúng một chỗ trong section — đổi một vế của dòng thì trích vế đó, không trích cả dòng. Bước 7.2 áp bằng **khớp đúng chuỗi cũ**; chuỗi cũ không có hoặc có hơn một chỗ ⇒ apply fail như marker trỏ ID không tồn tại.

Áp xong mà `## Changes` **rỗng** (BA giữ cũ, hoặc `q` rút câu mới, trên mọi câu mới) ⇒ **dừng**, không sang Bước 6, không ghi `spec.md`, không cascade. Câu hỏi mở của các dòng `q` in ra luôn — không có `spec.md` để giữ nó:

```
Không còn thay đổi nào để lên spec — {k} mâu thuẫn: {c} giữ cũ · {q} chưa quyết.
  [1] c · Out of Scope (F-009) …
  [2] c · AC-F009-001 …
Câu hỏi chưa quyết (mang sang lượt /spec-new sau khi đã có câu trả lời):
  - {câu cũ} ↔ {câu mới} — {câu hỏi}
Nhánh feat/{NNN}-{slug} (Bước 0) chưa có commit — xoá nếu không dùng: git checkout {main} && git branch -D feat/{NNN}-{slug}
```

Không tự xoá nhánh — Bước 0 là của user.

#### [5b.5] Ghi `## Conflicts` vào bản nháp

Có ít nhất một dòng ⇒ thêm section `## Conflicts` (giữa `## Changes` và `## Out of Scope`, format ở `spec-template.md`), một row mỗi dòng đã in, **kể cả `giữ cũ`** — `c` không để lại dấu vết nào khác trong spec, và người đọc PR cần biết BA đã thấy chỗ đó. Không có dòng nào ⇒ không có section.

---

### Bước 6: Review — xác nhận với user

> Draft trên đã đúng chưa?
> - Mỗi Changes block (frd / crd / prd / domain / sad) có đúng operation và markers chưa?
> - Acceptance Criteria có đủ và đo được không?
> - Verification Rules đã confirm với BA chưa?
> - Cascade Summary có khớp với Changes blocks không?
> - `## Conflicts` (nếu có) có khớp với `## Changes` và `## Open Questions` không — dòng `giữ mới` thấy marker, dòng `chưa quyết` thấy câu hỏi?
>
> **Sau khi confirm, agent sẽ auto-apply tất cả Changes blocks lên main artifacts.**

Chỉ tiến hành Bước 7 sau khi user confirm. Nếu user yêu cầu chỉnh sửa → cập nhật draft → **chạy lại Bước 5b** (sửa tay cũng có thể đụng requirement đang có) → hỏi lại.

---

### Bước 7: Save + Auto-cascade

**Điều kiện vào:** Bước 5b không còn dòng nào chưa chọn. Còn ⇒ quay lại 5b.3, **không** ghi gì.

Tạo thư mục `.specs/integrations/{NNN}-{slug}/` nếu chưa có.

**[7.1] Ghi spec.md** với status `approved` (không phải `draft` — human đã confirm ở Bước 6 chính là approval). Frontmatter `features` và `components` phải được điền theo những gì đã nhận diện ở Bước 2, **cộng** feature/component mà lựa chọn `m` ở Bước 5b kéo vào. (spec.md là integration artifact — **không** mang `template_version`; versioning chỉ áp dụng cho main artifacts, xem `01-architecture.md` §12.)

**[7.2] Auto-apply mỗi Changes block** vào main artifact tương ứng. Thứ tự apply (để tránh forward reference): `prd.md` → `domain.md` → `sad.md` → `component/*/crd.md` → `feature/*/frd.md`.

Cho từng block:

- **Operation=create:**
  - Tạo file mới tại path tương ứng
  - Nội dung = nội dung của Changes block (theo format của template gốc)
  - Frontmatter của artifact mới: lấy từ template, gồm `template_version` (status `draft` cho artifact mới — separate lifecycle với spec.md). `template_version` chỉ stamp ở operation=create; **operation=update KHÔNG đụng** version của artifact hiện có.

- **Operation=update:**
  - Đọc artifact hiện tại
  - Với mỗi item trong Changes block:
    - `[NEW]` → append/insert vào section tương ứng (giữ thứ tự numeric của ID)
    - `[MODIFY {field}]` → tìm item bằng ID, update field đã chỉ định, giữ nguyên các field khác. Item không có ID (marker kèm cặp `"cũ"` → `"mới"`, Bước 5b.4) ⇒ tìm bằng chuỗi cũ nguyên văn trong section đó, phải khớp **đúng một** chỗ
    - `[REMOVE]` → xóa item khỏi artifact (ID không tái sử dụng — không renumber các ID khác)
  - Ghi lại artifact

**[7.2.5] Bump `id_counters`** cho mọi ID vừa cấp `[NEW]` trong Changes block — phần atomic của auto-apply (fail → rollback luôn). KHÔNG ghi Change History (đã bỏ — history = git, xem `01-architecture.md` §7).

Cho mỗi main artifact có ID mới:
1. Với mỗi family cấp ID `[NEW]` (vd `domain.entity`, `prd.feature`/`prd.component`, `crd.rule`, `frd.us`/`ac`/`fac`/`vr`…), set `id_counters.<family>` = seq lớn nhất vừa cấp (counter chỉ tăng — high-water-mark).
2. Ghi lại artifact (frontmatter + body cùng transaction).

"Đổi gì · khi nào" của cascade này = git commit + integration `spec.md` (PR record bất biến) — không cần section log trong artifact.

**[7.2.6] Kiểm `Refs` của VR — trên `spec.md` VÀ trên mọi `frd.md` vừa cascade** (035 D0):

```bash
npx spec-lite check-vr-refs .specs/integrations/{NNN}-{slug}/spec.md
npx spec-lite check-vr-refs .specs/main/feature/{F-XXX}-{slug}/frd.md   # mỗi feature vừa chạm
```

**Kiểm spec thôi là chưa đủ** — bảng VR của spec là *delta*, còn thứ hạ nguồn đọc (`/plan` dựng `Definition of Done`, `/implement` trừ tập coverage) là bảng VR trong **frd sau khi cascade**. Hai chỗ có thể lệch nhau: `Refs` trỏ một `US-*` mà block Changes khai `[NEW]` nhưng bước apply không tạo ra, hoặc row VR ghép vào bảng frd sai cột. Chỉ chạy lại trên frd mới thấy.

Exit 1 ⇒ **dừng, không in "Bước tiếp theo"**, báo đúng dòng vi phạm và yêu cầu sửa. Cascade đã ghi rồi nên đây không phải rollback: nó là lời khai rằng artifact vừa sinh có VR không đường nào vào build.

**[7.3] Side-effects bổ sung:**

- Nếu integration gắn với feature từ prd.md và prd.md Changes block không tự đổi status → tự động đổi `TODO` → `In Progress` cho feature đó trong prd.md.
- **Vào từ Cửa 3 ⇒ ghi ngược hai chỗ**: (a) sổ `spec-debt.md` của feature — mỗi gap/drift đã chọn thành `- [ ] **SG-n** → {NNN}-{slug mới} …` / `` - [ ] **SD-n** · `{ID}` → {NNN}-{slug mới} … `` kèm `*(/spec-new · {date})*`, **chưa tick** (029 D9: `[x]` là việc của `/archive`); (b) `## Context` của spec mới — dòng `**Nguồn:** spec gap SG-n của {F-XXX}-{slug}` / `**Nguồn:** spec drift SD-n của {F-XXX}-{slug}`. Cùng commit với `spec.md`, nên không có khe nào để gap đã lên spec mà sổ không có con trỏ.

**[7.4] Thông báo kết quả:**

```
✓ .specs/integrations/{NNN}-{slug}/spec.md đã được tạo (status: approved)

Auto-cascade applied:
  ✓ prd.md — {summary}
  ✓ domain.md — {summary}
  ✓ component/C-XXX-{slug}/crd.md — {created | updated: summary}
  ✓ feature/F-XXX-{slug}/frd.md — {created | updated: summary}

Mâu thuẫn đã quyết: {m} giữ mới · {c} giữ cũ · {q} chưa quyết → ## Conflicts   ← chỉ khi Bước 5b có dòng

Spec debt đã quyết:                                ← chỉ khi vào từ Cửa 3
  → F-002-todo-management/spec-debt.md — SG-1 nhận bởi {NNN}-{slug}  (đóng khi /archive {NNN}-{slug})
  ✓ F-002-todo-management/spec-debt.md — SG-2 từ chối: {lý do}
  → F-002-todo-management/spec-debt.md — SD-1 · AC-… sửa requirement bởi {NNN}-{slug}
  ✓ F-002-todo-management/spec-debt.md — SD-2 · AC-… giữ spec ⇒ /spec-test-retrofit-{scope} {F-XXX} --mode execute rồi /verify-v2 {F-XXX}

Bước tiếp theo (chạy song song được, thứ tự nào cũng được):
  - /spec-tech {NNN}-{slug} → DEV thiết kế technical design (tech.md)
  - /spec-test {NNN}-{slug} → QC reconcile test-design (test.md + khung test-exec-*)
  Cần có cả hai thì mới chạy được /plan hoặc /implement.
```

**Nếu apply fail** (ví dụ markers reference ID không tồn tại trong artifact hiện tại) → dừng, báo lỗi cụ thể, **không** ghi spec.md. Yêu cầu user fix draft hoặc check artifact hiện tại.

---

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Requirement rõ rồi, bỏ qua spec.md" | Acceptance Criteria chưa viết = không biết khi nào là done. Code xong vẫn có thể sai. |
| "Out of scope thì ai cũng hiểu rồi" | Không ghi = scope creep không kiểm soát được. DEV sẽ tự quyết định implement hay không. |
| "Skip Changes blocks, sửa main artifacts tay sau" | Mất single source of truth. spec.md là PR record — phải reflect đúng patch đã apply. |

## Red Flags

- Acceptance Criteria dùng từ không đo được: "hoạt động đúng", "hiển thị đẹp", "nhanh"
- Out of Scope trống — mọi integration đều có thứ liên quan nhưng không làm
- Open Questions để trống nhưng vẫn còn điểm mơ hồ trong requirements
- Changes blocks không được review trước khi confirm (cascade là irreversible — không có undo)
- Marker không khớp current state: `[NEW]` cho item đã tồn tại, hoặc `[MODIFY]/[REMOVE]` cho ID không có
- `[MODIFY]`/`[REMOVE]` trên item cũ mà requirement không nhắc đích danh, và `## Conflicts` không có dòng nào cho nó — mâu thuẫn bị xử lặng lẽ
- `[NEW]` nằm song song với một item cũ cùng field, cùng tình huống (hai VR cho một field) — đáng ra là `[MODIFY]` câu cũ, và là một dòng ở Bước 5b
- Tập so chỉ có feature Bước 2 nhận ra, trong khi bản nháp chạm field / trạng thái mà grep ra ở `frd` khác

## Verification

Trước khi user confirm (Bước 6), kiểm tra:

- [ ] **Pre-flight Git**: đã thông báo plan cho user; xác định đúng nhánh chính (hỏi nếu mơ hồ); working tree sạch; đã `checkout {main}` + `pull`; tạo nhánh làm việc mới off `{main}` trước khi cascade
- [ ] Problem Statement từ góc nhìn user/business, không mention tech
- [ ] Mỗi Acceptance Criterion dùng cú pháp GIVEN / WHEN / THEN, có thể test được
- [ ] Out of Scope có ít nhất 1 item
- [ ] Mỗi Changes block có Operation rõ ràng (create | update)
- [ ] Mỗi item trong update block có marker đúng ([NEW]/[MODIFY {field}]/[REMOVE])
- [ ] ID assignment dựa trên `id_counters.<family> + 1` (frontmatter, high-water-mark), bump sau khi cấp, không tái sử dụng
- [ ] Verification Rules đã confirm với BA (không tự assert)
- [ ] Vào từ Cửa 3: mọi gap đã chọn ⇒ `- [ ] **SG-n** → {NNN}-{slug mới} … *(/spec-new · {date})*` (**chưa** tick — `[x]` là việc của `/archive`) + dòng `**Nguồn:**` trong `## Context` của spec mới; gap từ chối ⇒ `- [x] **SG-n** — {mô tả} — **từ chối:** {lý do} *(…)*`; **mọi** dòng giữ nguyên `{mô tả}` gốc; drift đã chọn ⇒ `` - [ ] **SD-n** · `{ID}` → {NNN}-{slug mới} … `` (chưa tick), drift `k` ⇒ `` - [x] **SD-n** · `{ID}` — {mô tả} — **giữ spec:** {lý do} *(…)* ``, dòng drift **giữ `{ID}`**; mỗi lựa chọn đổi **đúng một** dòng chính trong sổ của feature; sổ kiểu cũ còn sót hoặc hai dòng chính trùng số ⇒ đã dừng trước khi liệt kê
- [ ] Cascade Summary table khớp với các Changes blocks
- [ ] Bước 5b đã chạy: khối in có dòng tập so (kể cả khi không thấy mâu thuẫn); mọi dòng đã có lựa chọn
- [ ] Mọi dòng `giữ mới` ở `## Conflicts`: **mỗi** chỗ liệt kê ở cột `Cũ` có một marker ở `## Changes`; mọi dòng `chưa quyết` có **đúng một** dòng ở `## Open Questions` và câu mới của nó **không** còn trong `## Changes`

Sau khi user confirm (Bước 7):

- [ ] Auto-apply chạy theo thứ tự prd → domain → sad → crd → frd
- [ ] ID `[NEW]` nào cấp thì `id_counters` tương ứng đã bump (high-water-mark, §7); KHÔNG ghi Change History
- [ ] Fail-safe: nếu apply fail thì không ghi spec.md (rollback luôn id_counters đã bump)
- [ ] Main artifact create (frd/crd mới) có `template_version` copy từ template; artifact update giữ nguyên version cũ. spec.md (integration) KHÔNG mang `template_version`
- [ ] `npx spec-lite check-vr-refs` in **`✓ VR REFS KHỚP`** trên `spec.md` **và** trên từng `frd.md` vừa cascade — mỗi VR neo vào một `US-*`/`AC-*` có thật (035 D0)
