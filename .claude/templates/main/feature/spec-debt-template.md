---
slug: "{F-XXX}-{slug}"
created: {YYYY-MM-DD}
referenced_by:
  - 02-artifacts.md > 2. Main Artifacts > 2.3 Feature level > spec-debt.md
  - 01-architecture.md > 11. Quy ước & ràng buộc (hai nhánh cùng ghi một sổ)
  - skills/review-integration/SKILL.md > Có spec_gap · Có spec_drift
  - references/retrofit-core.md > 5. Phân loại test đỏ
  - skills/spec-new/SKILL.md > Cửa 3 — spec gap · spec drift
  - skills/fix-findings/SKILL.md > Bước 2 — drift mở
  - skills/archive/SKILL.md > Bước 3 · Bước 4b
---

# Spec Debt — {title}

<!--
Sổ nợ của BA cho MỘT feature — sổ DUY NHẤT, nằm cạnh frd.md (.docs/039). Không có sổ cấp integration,
không có bản sao. Chưa có nợ thì chưa có file. KHÔNG mang template_version: sổ là nhật ký do
pipeline ghi, không phải tài liệu được duyệt — /artifact-audit + /artifact-migrate bỏ qua nó.

Hai loại mục, hai bộ đếm riêng:

  SG-<n>  spec_gap   = hành vi hệ CẦN mà frd / spec.md / tech.md KHÔNG NÓI GÌ.
  SD-<n>  spec_drift = code làm KHÁC một AC/VR/FAC đã duyệt, và CÓ DẤU VẾT cho thấy code có thể đúng.
                       Chỉ BA biết bên nào đúng.

Lệch neo được mà KHÔNG có dấu vết ⇒ không thuộc file này: code sai → techdebt.md / bug-code.

FEATURE CỦA MỘT MỤC — mục nằm ở sổ của:
  SD  feature mang tiền tố của <ID> trên dòng chính      (AC-F008-001 ⇒ F-008)
  SG  feature mang ID ĐẦU TIÊN trong **gần nhất:**        (AC-F002-017 · US-F002-008 ⇒ F-002)

HÌNH DẠNG MỘT MỤC — thứ tự sub-bullet cố định:

  - [ ] **SG-<n>** — <hiện tượng>
    - **phát hiện:**
      - <một dòng mỗi lần thấy, dòng đầu là lần mở>
    - **gần nhất:** `<AC/US/VR gần nhất>` · …
    - **câu hỏi cho BA:** <cần quyết điều gì — không liệt kê đáp án>

  - [ ] **SD-<n>** · `<ID>` — <hiện tượng> · <ID> nói <gì>
    - **phát hiện:**
      - <một dòng mỗi lần thấy>
    - **dấu vết:** <file:dòng / commit <sha> / section nguồn đã duyệt> — "<trích nguyên văn>"
    - **câu hỏi cho BA:** giữ <ID> hay đổi <ID> theo hành vi hiện tại?

DÒNG **phát hiện:** — ba dạng, tập đóng:
  ③ Build — review vòng <k> của `<NNN>-<slug>` · `<sha>` · <YYYY-MM-DD>          (/review-integration)
  ④ Verify — retrofit <validation|functional|e2e> · `<TC>` đỏ · `<sha>` · <date>   (/spec-test-retrofit-*)
  tay: <ai> · <lý do> · <YYYY-MM-DD>                                              (người)
  ④ Verify ghi một SD mở mà không test nào đỏ ⇒ thay "`<TC>` đỏ" bằng "không TC đỏ".
  Lệnh chuyển sổ cũ thêm đuôi "· chuyển từ <SG|SD>-<m> của sổ <slug>".

THẤY LẠI MỘT MỤC ĐÃ CÓ ⇒ thêm MỘT dòng **phát hiện:**, KHÔNG mở mục mới.
  Khoá dò: SD theo <ID> (mục còn `- [ ]`); SG theo ID đầu ở **gần nhất:** VÀ cùng hiện tượng (đọc).
  Một đợt thay đổi hoặc một tầng retrofit có TỐI ĐA MỘT dòng — chạy lại cùng chỗ thì không thêm.
  Lần thấy lại KHÔNG sửa mô tả, dấu vết, câu hỏi. Hiện tượng của lần sau khác lần đầu ⇒ thêm một vế
  ngắn sau "·" ở chính dòng phát hiện đó.

LUẬT VIẾT — người quyết là BA, mục chỉ nêu hiện tượng:
  - dòng chính: người dùng làm gì, hệ làm gì, spec nói gì / không nói gì. Chữ của người dùng thấy
    (thao tác, thông báo, mã HTTP), KHÔNG tên hàm / biến / file — chỗ cho file:dòng là **dấu vết:**.
  - KHÔNG dùng ký tự `→` trong mô tả (viết "rồi", "thì", dấu phẩy): `→` ngay sau số mục hoặc sau <ID>
    là con trỏ `→ <slug>`, và mọi phép đếm *chưa quyết / đang làm* dựa vào nó.
  - KHÔNG chữ đánh giá ở mọi phần: nên · có vẻ · hợp lý hơn · lỗi thời · đúng/sai (về bên nào).
  - KHÔNG đề xuất giải pháp.
  - **dấu vết:** bắt buộc với SD — trỏ được, trích nguyên văn trong ngoặc kép, không diễn giải.
  - **câu hỏi cho BA:** SG nêu cần quyết điều gì; SD dùng đúng câu hai lựa chọn ở trên.
  - SD mang ĐÚNG MỘT ID trong backtick ngay sau "·" trên dòng chính — /fix-findings grep một dòng.

BỐN TRẠNG THÁI — `[x]` nghĩa là ĐÃ XONG hoặc ĐÃ QUYẾT DỨT, không phải "đã có người nhận":
  - [ ] **SG-n** — <mô tả>                                          chưa quyết, chờ BA
  - [ ] **SG-n** → <slug> — <mô tả> *(/spec-new · <date>)*           đã lên spec, chờ <slug> xong
  - [x] **SG-n** → <slug> — <mô tả> *(/archive · <date>)*            <slug> đã archive ⇒ xong
  - [x] **SG-n** — <mô tả> — **từ chối:** <lý do> *(/spec-new · <date>)*  quyết định KHÔNG làm

  - [ ] **SD-n** · `<ID>` — <mô tả>                                  chưa quyết, chờ BA
  - [ ] **SD-n** · `<ID>` → <slug> — <mô tả> *(/spec-new · <date>)*  sửa requirement, chờ <slug> xong
  - [x] **SD-n** · `<ID>` → <slug> — <mô tả> *(/archive · <date>)*   <slug> đã archive ⇒ xong
  - [x] **SD-n** · `<ID>` — <mô tả> — **giữ spec:** <lý do> *(/spec-new · <date>)*
                                         giữ requirement ⇒ code sai, ④ Verify được sửa code

DRIFT MỞ = mọi dòng `- [ ] **SD-` (có hay không có `→`). Drift mở thì /fix-findings TỪ CHỐI sửa
code của <ID> đó (lý do `spec-debt-mở`). `giữ spec` là đường mở khoá duy nhất.

SUFFIX NGUỒN `*(<nguồn> · <YYYY-MM-DD>)*` bắt buộc trên MỌI lần đổi trạng thái; nguồn thuộc tập đóng
/spec-new · /archive · `tay: <ai/lý do>`. Một dòng mang MỘT suffix (lần đổi gần nhất). Dòng chưa quyết
không có suffix — lần mở đã nằm ở **phát hiện:**. MỌI trạng thái giữ nguyên <mô tả> gốc và mọi sub-bullet.

AI GHI: /review-integration mở mục / thêm dòng phát hiện · tầng retrofit mở SD (lượt default/full) /
thêm dòng phát hiện · /spec-new <F-XXX> ghi → <slug>, từ chối, giữ spec · /archive <slug> tick [x]
dòng → <slug> · /fix-findings chỉ đọc · /build không đụng.

HAI NHÁNH CÙNG GHI MỘT SỔ (01 §11) — git luôn báo xung đột ở đây. Gỡ lúc gộp:
  - hai mục cùng khoá dò ⇒ gộp thành một: giữ mục của nhánh vào trước, nối vào cuối những dòng phát
    hiện của mục kia mà mục giữ lại chưa có dòng cùng chỗ (mỗi chỗ vẫn tối đa một dòng).
  - hai mục khác nhau, trùng số ⇒ mục của nhánh vào sau lấy số lớn nhất của sổ + 1; sửa mọi chỗ trên
    nhánh đó trỏ số cũ: grep -rn "S[GD]-<n> của <F-XXX>" .specs/
  /spec-new <F-XXX> dừng khi sổ có hai dòng chính trùng số.

  (Ví dụ trong comment này dùng <…> chứ không dùng {…}: skill tạo sổ điền mọi {…} của template, và
  một dòng ví dụ bị điền giá trị thật trông y hệt một mục thật.)
-->
