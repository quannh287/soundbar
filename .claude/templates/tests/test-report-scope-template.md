---
id: test-report-{scope}-{F-XXX}-{slug}
type: test-report-{scope}              # test-report-validation | -functional | -e2e | -nfr | -dm
feature_id: "{F-XXX}"
scope: {scope}                         # validation | functional | e2e | nfr | dm
mode: {cycle|retrofit}                 # scaffold ghi `cycle`; skill tầng đổi thành `retrofit` khi ghi file này
test_design_ref: "tests/{F-XXX}-{slug}/test-design.md"
test_exec_ref: "tests/{F-XXX}-{slug}/test-exec-{scope}.md"
test_exec_version: 0                   # 016 pin — MỘT SỐ (không phải map). 0 = scaffold chưa chạy; == test-exec.version ⇒ scope current
date: "{YYYY-MM-DD}"
status: draft
referenced_by:
  - 02-artifacts.md > Test Execution Artifacts > test-report-{scope}.md
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/test-report-{scope}.md — MỘT template dùng cho
CẢ 5 SCOPE (030 D6). Scope-specific chỉ 2 chỗ thay chữ: `scope` và trụ neo (VR / Story AC / FAC / NFR / DM).
Ví dụ trong file này điền theo scope `validation`; đổi 2 chỗ đó là ra 4 scope còn lại.

MỖI SCOPE MỘT FILE, ĐÚNG MỘT SKILL ĐƯỢC GHI (030 D0/D22):
  validation | functional | e2e  → `/spec-test-retrofit-{scope}` là writer duy nhất.
  nfr | dm                       → CHƯA có writer: `/spec-test-exec` tạo file lần đầu rồi thôi;
                                   Results giữ `—` (not-run), pin `0`. KHÔNG sửa tay.
`/spec-test-exec` chỉ TẠO file lần đầu (kèm legend), sau đó KHÔNG đụng nữa (030 D23).
Skill tầng **dựng lại trọn file** rồi ghi đè một lần — không mổ từng bảng; nó vẫn đọc bản trước
CỦA CHÍNH FILE NÀY để kế thừa ô đắt (`sanity-red`/`mutation`/`reverted`/`Tier`), không đọc file scope khác (030 D1).
Kết quả chạy KHÔNG sống trong test-exec (013 §4) — test-exec là spec của test code.

BỀN, ghi đè tại chỗ, phản ánh TRẠNG THÁI MỚI NHẤT. Không NNN/cycle-slug, không cột run/date tích luỹ.
Lịch sử "đã chạy gì qua thời gian" = git log/diff (015 §3B). KHÔNG có template_version / migrations —
test-side ngoài /artifact-audit + /artifact-migrate.

mode:
  - cycle    — lượt OUTER ở ③ Build (/spec-test-functional · /spec-test-validation) hoặc chu kỳ test thường.
               `sanity-red` = `red-first`; `mutation`/`reverted` = `—`; §2 Findings tối giản.
               Lượt scaffold của /spec-test-exec KHÔNG tính là lượt ghi — nó vẫn đặt `cycle`.
  - retrofit — viết test SAU code (/spec-test-retrofit-*) ở ④ Verify. 3 cột sanity-red BẮT BUỘC + §2 Findings
               phân loại mỗi đỏ (bug-code | spec-drift | flaky | test-error).

FORMAT FIDELITY — CHỈ 5 section, đúng thứ tự: 1 Summary · 2 Findings · 3 Blockers · 4 Results · 5 Next Actions.
KHÔNG `Pruned` (030 D11), KHÔNG `Observations` (đổi tên thành `Blockers`, ID `BLK-*` — D3), KHÔNG
`Change History`/timeline/run-log, KHÔNG blockquote kể-chuyện. Cần cột/section mới → sửa TEMPLATE này trước.

PHẦN BỊ CẮT ĐI ĐÂU (030 D10) — cắt chữ mà không nói chỗ chứa thì chữ mọc lại:
  - luật chung, suy luận dùng được cho mọi feature  → `references/retrofit-core.md`
  - diễn tiến "đã thử gì, rồi đổi sang gì" của lượt này → COMMIT MESSAGE
  - report chỉ giữ: verdict + evidence + việc kế.

BA CÂU HỎI REPORT PHẢI TỰ TRẢ LỜI (030 DS9) — người đọc chưa từng dự lượt chạy, không mở code:
  1. Đủ hay chưa?                    → §1 Summary
  2. Sai gì?                         → §2 Findings (nói được CÁI GÌ lệch CÁI GÌ, không chỉ nhãn verdict)
  3. Chưa kiểm được gì, ai làm gì tiếp? → §3 Blockers + §5 Next Actions
NGÔN NGỮ: phần diễn giải (`Vấn đề` · `Cần gì để mở khoá` · `Việc` · phần mô tả của `Evidence`) viết
TIẾNG VIỆT; định danh giữ nguyên (`TC-F002-010`, `VR-F002-001`, `be:unit`, tên file/hàm, `harness`).
LEGEND BẮT BUỘC: nhãn nào xuất hiện trong bảng thì section đó phải có dòng `**Nhãn:** …` giải nghĩa.
Khi "ngắn" (dưới) xung đột với "dễ hiểu" → DỄ HIỂU THẮNG, nhưng nới bằng legend, không viết dài từng dòng.

LUẬT TRÌNH BÀY — thân report chỉ được gồm 4 loại dòng (030 DS7):
  | heading `## N. Tên`  | bảng (dòng bắt đầu `|`)  | blockquote `>` ≤3 dòng/khối  | dòng `**Nhãn:** …` (đúng 1 dòng) |
CẤM: đoạn văn trần · bullet nhiều dòng · câu kể quá trình ("đầu tiên… sau đó…") · blockquote narrative
· section ngoài 5 section trên.

BUDGET + KHUÔN CÂU MỖI CỘT — trần ký tự / ô (dòng `**Mục:**` miễn trần vì nội dung là anchor link):
  Evidence            ≤120  `<file>:<sym> — <thực tế> ≠ <spec đòi>`
                            ✅ `validators/item.ts:createItem — nhận "" ≠ VR đòi reject`
                            ❌ "code trả về null khi điều kiện X, trong khi AC yêu cầu…"
  mutation            ≤120  `<file>:<sym> — <thay đổi>` → `<TC>` 🔴
                            ✅ `domain/user.ts: bỏ EMAIL_RE.test` → `TC-F002-011` 🔴
                            ❌ "đã thử bỏ regex và thấy test đỏ như mong đợi"
  Vấn đề (BLK)        ≤160  `<cái chặn>; <vì sao chặn>` — HAI mệnh đề, không rút thành nhãn
                            ✅ `FK membership chưa có fixture; assert cần row cha ở DB thật`
                            ❌ `harness`  (nhãn cụt)
  Cần gì để mở khoá   ≤120  danh từ: hạ tầng / quyết định cần
  Việc (Next Action)  ≤100  động từ + đối tượng cụ thể
  Nguồn               ≤40   CHỈ ID: `FIND-*` · `BLK-*` · req-ID (với `coverage-gap`)
  Loại                ≤16   MỘT nhãn từ tập đóng 8 nhãn (test-core §7)
  PIC                 ≤12   `🤖` hoặc `👤 DEV`/`👤 BA`/`👤 QC` — DERIVE theo map ở test-core §7
  Note (Results)      ≤60   ID BLK · file test · lý do `no-seam`
-->

# Test Report · Validation — {Feature Name}

**Feature**: {F-XXX} | **Scope**: validation | **Mode**: {cycle|retrofit} | **Pin**: test-exec `v{n}` | **Date**: {YYYY-MM-DD}

**Mục:** [1 Summary](#1-summary) · [2 Findings](#2-findings) `2` · [3 Blockers](#3-blockers) `1` · [4 Results](#4-results) `4` · [5 Next Actions](#5-next-actions) `4`

> Nguồn TC: [test-design.md](./test-design.md) · spec test code: [test-exec-validation.md](./test-exec-validation.md).
> Roll-up: [test-report.md](./test-report.md). File này = trạng thái mới nhất của **scope validation**; lịch sử = git.

## 1. Summary

**Legend:** `🟢 pass` · `🔴 fail` · `⏭ skip` · `— not-run` · `🟡 flaky`

| Tổng TC | 🟢 | 🔴 | ⏭ | 🟡 | — |
|---|---|---|---|---|---|
| **{N}** | **{n}** | **{n}** | **{n}** | **{n}** | **{n}** |

> **Derive từ §4** — skill **tính lại** mỗi lần ghi, KHÔNG sửa tay. **Không** vỡ theo tier.
> Mỗi TC rơi vào **đúng một** ô ⇒ 5 ô cộng lại = `Tổng TC`. Xanh mà cột `sanity-red` để `—` ở `retrofit` (tức chưa có bằng chứng nào) đếm vào `—`, KHÔNG vào 🟢.
>
> Khi `mode: cycle`: row `red-first` **đếm vào 🟢**. Scope chưa chạy trọn (lượt outer mới đi qua vài slice) ⇒ ghi rõ `n/N TC` thay vì để người đọc tưởng đã đủ (034 DS4).

**Coverage** — trụ neo của scope này, đối chiếu Traceability Matrix của [test-design.md](./test-design.md):

| Loại | Covered (pass) | Tổng | Đỏ |
|---|---|---|---|
| VR | {x} | {y} | {n} |

> Tổng `{y}` đến từ test-design — thứ **duy nhất** ở file này không derive được từ §4.

## 2. Findings

> Chỉ điền khi có `🔴 fail`. **KHÔNG sửa test cho xanh.** ID `FIND-VAL-NN`, cấp số tiếp (append-only).

**Verdict:** `bug-code` = code lệch spec, không lý do nào để code có thể đúng (hoặc BA đã `giữ spec`) · `spec-drift` = code lệch spec **có dấu vết**, chưa biết bên nào sai, BA quyết — kèm mục `SD-n` ở sổ `spec-debt.md` của feature, cạnh `frd.md` (`05 §14`, `retrofit-core §5`) · `flaky` = không tất định · `test-error` = sai ở test.
**`dup-of`:** cùng nguyên nhân với finding tầng trước → ghi ID đó (vd `FIND-FUN-01`); roll-up không đếm lại. Không có thì `—`.

| ID | TC | Covers | Verdict | Evidence | Action | dup-of |
|---|---|---|---|---|---|---|
| `FIND-VAL-01` | `TC-F002-011` | `VR-F002-001` | bug-code | `validators/item.ts:createItem — nhận "" ≠ VR đòi reject` | sửa code | — |
| `FIND-VAL-02` | `TC-F002-013` | `VR-F002-004` | spec-drift | `SD-1 của F-002-todo-management` · `rules/password.ts:minLen — chặn ở 8 ≠ VR ghi 6`; lý do: commit `a1b2c3d` "chính sách bảo mật mới đòi 8" | chốt spec | — |

## 3. Blockers

> Thứ chặn TC không chạy được (`⏭`). ID `BLK-VAL-N`. **Quy tắc 2 chiều:** mọi TC `⏭` mang Action
> `harness`/`refactor`/`need-clarify` trỏ đúng 1 `BLK-VAL-N` ở cột `Note` của §4; mọi BLK có ≥1 TC.
> `no-seam` KHÔNG tạo BLK (ghi thẳng `Note`).

**Hai cột diễn giải:** `Vấn đề` = *cái chặn + vì sao chặn* (hai mệnh đề, không rút thành nhãn) · `Cần gì để mở khoá` = *hạ tầng hoặc quyết định còn thiếu*.

| BLK | TC bị chặn | Vấn đề (dễ hiểu cho người) | Cần gì để mở khoá |
|---|---|---|---|
| `BLK-VAL-1` | `TC-F002-006` | `FK membership chưa có fixture; assert cần row cha ở DB thật` | `DB in-memory dùng chung cho tier be:persistence` |

## 4. Results

> Một dòng / TC của **scope này**, danh sách lấy từ [test-exec-validation.md](./test-exec-validation.md).
> Ba cột sanity-red **tách đôi** theo `mode` (034 DS4, test-core §7c.3): `sanity-red` có nghĩa ở **mọi** mode —
> `retrofit` ⇒ `proven-red`/`inherited`/`n/a` (hoặc giữ `red-first` nếu ③ Build đã lập), `cycle` ⇒ **`red-first`**; còn `mutation`/`reverted` chỉ có nghĩa khi thật sự
> mutate-revert, tức `cycle` → `—`. Xanh mà `sanity-red = —` ở retrofit
> → KHÔNG tính pass. §1 đếm lại từ bảng này.

**Sanity-red:** `sanity-red` = **lấy gì làm bằng chứng test này biết đỏ** — **`red-first`** đã thấy đỏ **trước khi có dòng code nào** (③ Build; ④ Verify **giữ nguyên**, không hạ) · **`proven-red`** phá code → thấy đỏ → hoàn nguyên, ở lượt này (④ Verify) · **`inherited`** test có sẵn từ trước pipeline, lượt này không mutate nên mượn bằng chứng lượt trước · `n/a` không mutate trực tiếp được (TC positive, hoặc proven qua revert-verify của cụm) · `—` **chỉ** khi TC không chạy · `mutation` = đã phá gì để nó đỏ · `reverted` = đã hoàn nguyên.
**Action tag:** `harness` = cần dựng hạ tầng test mới · `refactor` = cần tách seam trong code · `need-clarify` = spec mâu thuẫn với chính nó, với `tech.md` hoặc UI, hay thiếu thông tin — chưa viết nổi assert, cần người quyết (spec lệch với **code** là finding `spec-drift`, không phải tag này) · `no-seam` = tầng này không có nhánh để test.
**Tier:** `be:unit` = hàm thuần · `be:handler` = logic C# với fake repo · `be:persistence` = chạm DB thật · `be:api` = qua HTTP · `fe:unit` = hàm thuần FE · `fe:component` = render DOM · `fe:api` = FE↔API mock · `e2e` = trình duyệt thật *(chỉ giữ tier đang xuất hiện)*.

| TC ID | Covers | Tier | Result | sanity-red | mutation | reverted | Action | Note |
|---|---|---|---|---|---|---|---|---|
| `TC-F002-010` | `VR-F002-001` | `be:unit` | 🟢 | proven-red | `validators/item.ts: bỏ .NotEmpty()` → `TC-F002-011` 🔴 | ✅ | — | |
| `TC-F002-011` | `VR-F002-001` | `be:unit` | 🔴 | proven-red | `validators/item.ts: bỏ .NotEmpty()` → `TC-F002-011` 🔴 | ✅ | — | `FIND-VAL-01` |
| `TC-F002-013` | `VR-F002-004` | `be:unit` | 🔴 | proven-red | `rules/password.ts: nới min 8→4` → `TC-F002-013` 🔴 | ✅ | — | `FIND-VAL-02` |
| `TC-F002-006` | `VR-F002-006` | `be:persistence` | ⏭ | — | — | — | `harness` | `BLK-VAL-1` |

## 5. Next Actions

> Việc phải làm **của scope này** — câu `Việc` phải đọc một mình vẫn hiểu (roll-up trích nguyên văn).
> **Ba nguồn:** §2 `FIND-*` (còn 🔴; `dup-of` không tính) · §3 `BLK-*` (luôn có) ·
> §1 `Coverage` thiếu phủ (không đỏ, không hoãn, vẫn là việc).

**Loại:** verdict của §2 (`bug-code`/`spec-drift`/`flaky`/`test-error`) · tag của §3 (`harness`/`refactor`/`need-clarify`) · `coverage-gap` = *scope này không phủ được trụ đó*: chưa có TC, **hoặc** có TC mà mọi TC `Autoable = NO` (oracle thị giác) ⇒ kiểm bằng mắt, KHÔNG thêm TC.
**PIC:** `🤖` = *agent tự xử* · `👤 DEV`/`👤 BA`/`👤 QC` = *chờ người chốt, agent KHÔNG đụng*. Suy ra **từ cột `Loại`** theo map ở `test-core §7` — không phán tự do.

| ID | Việc | Nguồn | Loại | PIC |
|---|---|---|---|---|
| `A-VAL-1` | sửa `createItem` nhận `""` | `FIND-VAL-01` | `bug-code` | `🤖` |
| `A-VAL-2` | quyết `SD-1` ở `/spec-new F-002`: sửa VR theo code, hay giữ VR (code sai) | `FIND-VAL-02` | `spec-drift` | `👤 BA` |
| `A-VAL-3` | dựng DB in-memory cho tier `be:persistence` | `BLK-VAL-1` | `harness` | `👤 DEV` |
| `A-VAL-4` | thêm TC accept sát biên cho `VR-F002-002` vào test-design | `VR-F002-002` | `coverage-gap` | `👤 QC` |
