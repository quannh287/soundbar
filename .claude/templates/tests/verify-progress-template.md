---
id: progress-{unit}-{F-XXX}-{slug}
type: verify-progress
unit: {unit}                           # design | exec | validation | functional | e2e | fix | verify (bản gộp)
feature_id: "{F-XXX}"
derived_from:                          # chép version/pin/date của artifact LÚC RENDER — bộ phát hiện sổ cũ
  test_exec: { file: test-exec-{scope}.md, version: {n} }
  test_report: { file: test-report-{scope}.md, pin: {n}, date: "{YYYY-MM-DD}" }
date: "{YYYY-MM-DD}"
referenced_by:
  - 02-artifacts.md > Test Execution Artifacts > .progress/
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/.progress/{unit}.md — MỘT template cho CẢ 7 SỔ
(6 sổ của skill con + `verify.md` bản gộp của orchestrator).

MỘT SỔ MỘT WRITER (033 D0):
  design.md      → /spec-test-design
  exec.md        → /spec-test-exec
  validation.md  → /spec-test-retrofit-validation
  functional.md  → /spec-test-retrofit-functional
  e2e.md         → /spec-test-retrofit-e2e
  fix.md         → /fix-findings
  verify.md      → /verify-v1 (hoặc /verify-v2) — BẢN GỘP, xem khối cuối file này
Sáu skill chạy độc lập được, nên sổ dùng chung sẽ là hai writer trên một file. Skill KHÔNG đọc,
KHÔNG ghi sổ của skill khác. Orchestrator (`/verify-v1` / `/verify-v2`) gộp 6 sổ thành `.progress/verify.md` bằng
cách CHÉP NGUYÊN VĂN — nó không derive lại per-TC.

SỔ LÀ BẢN DỰNG LẠI, KHÔNG PHẢI SỔ TICK TAY:
  Skill dựng lại TRỌN sổ của mình mỗi lượt chạy rồi ghi đè. Nhờ vậy nó không nói dối được — `[x]`
  chỉ xuất hiện khi field trên đĩa nói xong, và một ô sửa tay bị ghi đè ở lượt sau. Luật đọc
  ("đơn vị của tôi là gì · đọc file nào, field nào · thấy gì thì coi là xong") sống ở section
  `## Đơn vị tiến độ` của từng SKILL.md, cạnh bước sinh ra nó.

GHI ĐÈ, KHÔNG APPEND. Không có block `## Run {n}`: giữ block cũ là giữ dữ liệu derive đã cũ, người
đọc nhầm lượt trước với trạng thái hiện tại. Lịch sử = git (015 §3B). Đây là chỗ khác
`implement-log.md` — log đó append vì nó TOÀN là biên bản.

KHÔNG `template_version` / `migrations` — test-side ngoài /artifact-audit + /artifact-migrate (015 §3B).

Phép thử một thứ mới có thuộc sổ hay không — XOÁ FILE ĐI RỒI CHẠY LẠI:
  dựng lại y nguyên             ⇒ thuộc sổ (`.md`)
  mất mà lượt đang chạy cần     ⇒ nó là vết của một lượt gọi, không phải sổ
  mất mà không ai cần nữa       ⇒ đừng lưu
Phép thử thứ ba là lý do 6 sổ này KHÔNG sinh file log nào: lý do dừng của một skill tự phát hiện
lại được ở lượt sau (cây bẩn → `git status`; version-gate → frontmatter; thiếu harness → probe lại).

BỐN LOẠI DÒNG — phân biệt bằng hình dạng, không bằng nhãn:

  việc lớn        `- [ ] /spec-test-… {payload}`         một lần gọi skill này
  việc nhỏ        `  - [ ] {đơn vị} {payload}`           tiến độ bên trong, hạt do SKILL.md khai
  không tick được `- ⚠ {mô tả} → 👤 {role}`             bullet trần, KHÔNG checkbox
  bị chặn         `- ⛔ /spec-test-… {lệnh} ({lý do})`   tiền đề chưa đủ, KHÔNG có ô tick

Dòng `⛔` ĐỨNG TRÊN con trỏ `- [ ]`: thấy nó là dừng, KHÔNG đi tìm `- [ ]` tiếp theo. Nó không có
ô tick nên luật con trỏ sẽ NHẢY QUA tầng đang bị chặn và dispatch tầng sau — tức chạy tầng 3 trên
contract mà tầng 2 chưa backfill (retrofit-core §1b).

Dòng `step=` KHÔNG thuộc 6 sổ của skill con — biên bản là của orchestrator, và nó sống ở `.progress/verify.run.log`
(vết một lượt gọi `/verify-v2`, đuôi `.log` nên ngoài glob của bản gộp), KHÔNG ở đây.

BA LUẬT CỨNG:
  1. `[x]` = "đã có bản ghi", KHÔNG phải "xanh". `🔴` và `⏭` đều `[x]` — chúng là việc đã trả tiền.
     Nên mỗi dòng việc nhỏ PHẢI mang ký hiệu result + hậu tố (`⏭ harness → BLK-E2E-1`);
     `[x]` trơn đọc thành "xanh".
  2. Điều kiện tick không phải "có bản ghi" mà "BẢN GHI TỰ NHẤT QUÁN". Với ba tầng retrofit:
     row §4 tồn tại VÀ `sanity-red` ∈ {proven-red, red-first, inherited, n/a} VÀ
     (`sanity-red` = proven-red ⇒ `mutation` có nội dung VÀ `reverted` = ✅). Tick theo "có row" thì `[x]` che đúng ca report nói TC xanh trong khi code
     sản phẩm còn mang mutation.
  3. KHÔNG rẽ nhánh trên sổ. Refresh trước, rồi đọc pin / §4 Results để quyết làm gì.

THỨ KHÔNG DERIVE ĐƯỢC THÌ KHÔNG CÓ DÒNG — kể cả khi nó quan trọng. Một `- [ ]` vĩnh viễn không tick
được làm orchestrator dispatch lại vô hạn. Bốn thứ đã loại: gate additive "hành vi cũ vẫn xanh" ·
`dup-of` · 4 phép kiểm contract chỉ in ra · Prune. Chỗ của chúng: `Note` của dòng, hoặc một `BLK-*`
trong report.

MẪU SỐ của mọi khối tầng là bảng `Test Cases` của `test-exec-{scope}.md` (§4 ở validation/functional,
§5 ở e2e — gọi bằng TÊN bảng), KHÔNG phải `test-design.md` — test-design đếm
cả TC `Autoable = NO` (ca visual), nên so với nó thì feature có một TC visual báo "còn nợ" vĩnh viễn.

CHECKLIST NỞ RA GIỮA LƯỢT — bình thường. Một số việc nhỏ chỉ enumerate được SAU khi skill chạy
(khối backfill của tầng functional cần cột `testid` mà chính tầng đó điền). Refresh in THẤY GÌ CÓ NẤY,
không đoán trước.

BA LUẬT VẬN HÀNH:
  xung đột merge    → LUÔN xử bằng chạy lại render, KHÔNG merge tay (file derive được thì merge tay vô nghĩa)
  một lượt / một sổ → hai lượt cùng skill trên cùng feature giành cùng sổ; song song thật ⇒ mỗi lượt một worktree
  /archive          → `mv` CẢ thư mục feature; `mv {dir}/*` bỏ lại dotdir `.progress/`

Định nghĩa thư mục + bảng writer: `02-artifacts.md` §4.7.
Xoá mọi comment HTML khi ghi file thật.
-->

- [ ] {tên skill}   {payload việc lớn: pin {a}/{b} · ({k}/{n})}
  - [x] {đơn vị việc nhỏ}              {payload: ký hiệu result + hậu tố}
  - [ ] {đơn vị việc nhỏ}              {payload: trạng thái dở, nói rõ thiếu gì}
  - ⚠ {thứ không tick được} → 👤 {DEV|BA|QC}

<!--
VÍ DỤ — sổ của tầng functional, lượt bị ngắt ở TC thứ 12/14:

- [ ] /spec-test-retrofit-functional   pin 0/1   (12/14)
  - [x] contract shape                 v3/3 · header khớp
  - [x] testid: todo-tag-chip          row✓ code✓
  - [x] TC-F004-020  🟢                wired
  - [x] TC-F004-021  ⏭ harness → BLK-FUN-1
  - [ ] TC-F004-022                    wired · chưa có row §4
  - ⚠ 1 item blocked-by-spec → 👤 BA

Dòng `- [ ]` đầu tiên là chỗ làm tiếp. Không cần phân biệt "đứt giữa chừng" với "dừng hợp lệ":
gõ lại thì skill gặp lại đúng điều kiện dừng cũ và in lại đúng thông điệp cũ.
-->

<!--
KHỐI GỘP — chỉ cho `verify.md`, writer là `/verify-v1` / `/verify-v2`.

Đơn vị việc của orchestrator đúng là 5 lần gọi skill con, nên sổ của nó là PHẦN GỘP. Luật đầy đủ ở
`references/verify-core.md` §4; đây là hình dạng file.

CÁCH GỘP:
  glob                 `.progress/*.md` TRỪ `verify.md` (thiếu vế trừ là sổ đọc chính mình)
  thứ tự               design → exec → validation → functional → e2e → fix
  chép NGUYÊN VĂN      orchestrator KHÔNG derive lại per-TC — việc của skill sở hữu sổ (033 D0).
                       KHÔNG có renderer dùng chung dựng khối con: một hàm "đọc khai báo rồi dựng
                       khối" là WRITER THỨ HAI cho cùng nội dung, và hai bên lệch nhau là lệch im lặng
  sổ vắng mặt          in MỘT dòng việc lớn `- [ ] /spec-test-… (chưa chạy)`, không phải khối rỗng
  Bước 1/2 skip        dòng `- [x] /spec-test-… — skipped (…)` là VIỆC LỚN; khối việc nhỏ của sổ
                       nguồn vẫn chép nguyên văn bên dưới. Thay cả khối bằng một dòng `skipped` làm
                       hai lượt (skip vs chạy) khác nhau ở chỗ không liên quan tới thứ đang đo
  sổ cũ                sổ CÓ nhưng `derived_from` lệch pin/version thật ⇒ KHÔNG chép nguyên văn,
                       in `- [ ] … pin {p}/{v} ({k}/{n}) — sổ cũ` (số lấy từ đĩa). Orchestrator không
                       refresh hộ sổ của writer khác được; chép nguyên văn là bản gộp nói dối.
                       BỎ khối việc nhỏ (nói về pin cũ), GIỮ dòng `⚠` (việc 👤 không được mất)
  không đọc bản gộp cũ dựng lại trọn từ các sổ nguồn mỗi lần
  derived_from         chép `date` của TỪNG sổ đã gộp — lệch ⇒ bản gộp cũ hơn sổ nguồn

REFRESH hai thời điểm: đầu mỗi lượt, và sau MỖI lần dispatch trả về.
Dòng `⚠` thiếu harness là DERIVE (probe lại mỗi lần refresh), không phải biên bản.

VÍ DỤ — `verify.md` của một lượt đang dở ở tầng functional:

---
id: progress-verify-F-004-todo-tag
type: verify-progress
unit: verify
feature_id: "F-004"
derived_from:
  design:     { file: .progress/design.md,     date: "2026-09-09" }
  exec:       { file: .progress/exec.md,       date: "2026-09-09" }
  validation: { file: .progress/validation.md, date: "2026-09-09" }
  functional: { file: .progress/functional.md, date: "2026-09-09" }
date: "2026-09-09"
---

- ⚠ e2e sẽ tắc: thiếu Playwright + POM + seeded backend → 👤 DEV
- [x] /spec-test-design — skipped (đã có)
- [x] /spec-test-exec
  - [x] validation   td 1 → exec tdv 1 · rows 13/13
  - [x] functional   td 1 → exec tdv 1 · rows 11/11
- [x] /spec-test-retrofit-validation   pin 1/1   (13/13)
- [ ] /spec-test-retrofit-functional   pin 0/1   (8/11)
  - [x] TC-F004-020  🟢                wired
  - [ ] TC-F004-022                    wired · chưa có row §4
- [ ] /spec-test-retrofit-e2e          (chưa chạy)

Sổ `e2e` vắng mặt ⇒ đúng một dòng việc lớn `(chưa chạy)`, không khối rỗng.
-->
