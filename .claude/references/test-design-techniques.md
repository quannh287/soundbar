# Test Design Techniques — sinh đủ TC cho mỗi frd item

> Chỉ dẫn cho **`/spec-test-design`** (Bước 4 — derive). Derive 1:1 (`VR → 1 pos + 1 neg`) là **sàn**; file này cho **hệ số nhân** theo cấu trúc của từng item.
>
> Trigger đọc **thuần `frd.md`** và đọc **MỆNH ĐỀ, không đọc VỊ TRÍ** (027 D4): cùng một luật viết ở `Rule` của VR, ở `Then`/`When` của AC, hay ở nhãn nhánh Mermaid của Flow đều phải ra **cùng số TC**. frd thật viết luật ở đâu là quyền người viết frd.

## 0. Ba luật

1. **Kỹ thuật quyết "đủ", frd quyết "đúng".** Kỹ thuật sinh **cột input**; cột `Expected` luôn đọc từ `Rule`/`AC`/`FAC` text.
2. **Mọi TC phải `Covers` một frd item.** Neo không được ⇒ **không sinh**.
3. **Không có oracle thì không có TC.** Kỹ thuật lộ ra ô mà frd chưa định nghĩa expected ⇒ **KHÔNG tự chế** — ghi `Gaps`, TC đánh `blocked-by-spec`.

## 1. Trigger — đọc frd ra là biết bắt buộc kỹ thuật gì

Cột trái đọc **mệnh đề**. Mệnh đề nằm ở `Rule` của một VR, ở `Then`/`When` của một AC, hay ở nhãn nhánh trong Mermaid của một Flow — **không đổi kỹ thuật, không đổi công thức**. Chỉ **item neo** và **bucket** đổi theo chỗ mệnh đề được viết.

| Mệnh đề trong frd | Bắt buộc | Tên đầy đủ | TC neo vào | Bucket |
| --- | --- | --- | --- | --- |
| Mọi ràng buộc trên một field (kể cả `Required: yes`) | **EP** | Equivalence Partitioning — phân hoạch tương đương | item mang mệnh đề | theo item |
| Có ngưỡng: `>` `<` `≥` `≤` `min` `max` `maxLength` · khoảng ngày · "lớn hơn 0 và nhỏ hơn hoặc bằng 12" | **BVA** | Boundary Value Analysis — phân tích giá trị biên | item mang mệnh đề | theo item |
| Tập giá trị đóng **và** có event làm giá trị đổi sau khi bản ghi đã tạo | **ST** | State Transition testing — kiểm thử chuyển trạng thái | item mang mệnh đề | theo item — dạng **block** nếu không vừa cột |
| ≥2 điều kiện độc lập cùng quyết 1 kết quả · cặp field loại trừ · field dẫn xuất nhiều nguồn | **DT** | Decision Table testing — kiểm thử bảng quyết định | item mang mệnh đề | theo item |
| Mỗi Flow | **UC** | Use Case testing — kiểm thử theo use case | Flow (qua TS) | Functional |
| ≥3 biến cấu hình, tích tổ hợp > 20 | **PW** | Pairwise testing (2-wise) — kiểm thử theo cặp | AC/Flow | Functional |
| Có nguồn đoán lỗi (§2.5) | **EG** | Error Guessing — đoán lỗi | item gần nhất, oracle vẫn từ frd | theo item |

**Bucket = theo item neo**, không theo kỹ thuật: `VR → validation` · `US`/`AC` → functional · `Flow` → functional (qua TS) · `FAC` → e2e · `NFR` → nfr · `DM` → dm. Một AC mang ràng buộc field vẫn sinh TC ở bucket **functional** — **KHÔNG đẻ bucket mới**, không chuyển TC sang validation vì "trông giống VR".

**Luật thay cột (027 D4).** AC prose không có cột `Required` / `Type` như bảng VR. Cần hai thứ đó (đơn vị bước BVA, có bắt buộc hay không):
1. đọc từ **VR cùng field** nếu có;
2. không có VR nào cùng field ⇒ **`blocked-by-spec` + `Gaps`** — **không giả định** `Required: yes`, không đoán `Type`.

Cái **không** cần thay cột thì cứ sinh: `m` phân vùng accept, `n` lý do reject, số điều kiện của DT, số bề mặt quan sát đều đọc thẳng từ prose.

**Tập giá trị đóng ⇒ không tự động là ST.** `enum<VN|EN>` (lựa chọn tĩnh) → chỉ EP. `enum<Pending|Approved|Rejected>` có event *gửi/duyệt/từ chối* → vòng đời → ST. Câu hỏi phân biệt: *có event nào làm giá trị đổi sau khi record đã tạo không?* — **frd không mô tả event nào ⇒ mặc định EP**, ghi một dòng `Gaps` là đã xét (027 D12, điểm rẽ 1).

**FAC · NFR · DM: không áp kỹ thuật** — giữ 1:1 như cũ, `Technique = NA`. FAC thêm một check: `len(Spans) ≥ 2`; chỉ đi 1 story ⇒ trùng Functional ⇒ gộp về Functional hoặc trả ngược frd.

**Story AC thuần hành vi cũng được `NA` — có điều kiện.** Phần lớn AC là *Given X / When Y / Then một kết quả*, không mang ràng buộc trên field nào. Ép chúng vào `EP:1+0` thì D5 lại đòi `Field`/`Input`/`Polarity` cho thứ không có field, và người viết phải **bịa** (`Field: phiên hiện tại`). Nên: AC **không mang bất kỳ ràng buộc field nào** ⇒ `Technique = NA`, `1 = NA:1`, và **D5 không áp** (không đòi `Field`/`Input`/`Polarity`).

> ⚠ **Cổng chặn — `NA` không phải lối thoát khỏi việc sinh negative case.** AC có **bất kỳ** dấu hiệu nào dưới đây thì **VẪN** phải EP/BVA/ST, không được `NA`:
> - `Then`/`Rule` có mệnh đề **reject** (báo lỗi, từ chối, không cho phép) ⇒ **EP** `m+n`;
> - có **ngưỡng** (`>` `<` `≥` `≤` `min` `max` `maxLength`, khoảng ngày) ⇒ **BVA**;
> - có **tập giá trị đóng + event đổi giá trị** ⇒ **ST**;
> - `Then` liệt kê **≥2 bề mặt quan sát** ⇒ **EP** (1 TC / bề mặt).
>
> Nói cách khác `NA` chỉ dành cho AC **một đường đi, một kết quả, không có nhánh hỏng nào frd nói tới**. Chọn `NA` cho AC có mệnh đề reject là **giấu** việc thiếu negative case — `check-ledger` không bắt được (assert ④ chỉ kiểm hình dạng `NA:1`), nên đây là luật người review phải gác.

## 2. Công thức đủ

| Kỹ thuật | Công thức | Cách kiểm |
| --- | --- | --- |
| **EP** | **`m + n`** TC — `m` = số **phân vùng accept** (§3.1; mặc định `1`) + `n` = **1 TC cho MỖI lý do reject riêng biệt** (số mệnh đề reject trong `Rule`/`Then`, cộng `Required: yes` nếu có) | `số TC accept ≥ m` **và** `số TC negative ≥ n` |
| **BVA** | **2 TC / mỗi biên** — ngay tại biên (accept) + vượt 1 đơn vị (reject) ⇒ biên đôi `4`, biên đơn `2` | tồn tại **≥1 TC accept sát biên** (C2) |
| **DT** | liệt kê đủ `2ⁿ` tổ hợp (`n ≤ 4`) rồi mới rút gọn; **mỗi cột còn lại ≥1 TC** | `số cột có TC = số cột không đánh dấu impossible` (C4) |
| **ST** | bảng `N state × M event`, điền đủ N×M ô | `ô có TC / ô reachable = 100%` (C3) |
| **UC** | mỗi Flow: 1 main + **mọi** nhánh phụ/ngoại lệ **frd đã ghi** | mỗi TS có ≥1 TC nhánh phụ **và** ≥1 TC ngoại lệ (C5) |
| **EG** | rút từ 3 nguồn, **mỗi TC trích nguồn** | TC `EG` thiếu field nguồn ⇒ chưa đạt (C6) |
| **PW** | phủ **100% các cặp** (2-wise); chỉ dùng khi tích > 20 | ghi 2 con số: tổ hợp đầy đủ / TC sau rút gọn |

> **`1 + n` là công thức CŨ và nó sai một phía** (027 D1). `Rule` định nghĩa nhiều phân vùng **accept** — "khớp không phân biệt hoa/thường", "chấp nhận ba cách viết tên cột" — vẫn chỉ ra **đúng 1** TC accept, tức mất `m − 1` ca. Đếm cả hai phía: `m + n`.

### 2.1 BVA — chi tiết

- **Đơn vị bước** (đọc từ `Type`): `integer`/`number` → 1 · `decimal(18,2)` → 0.01 · `date`/`datetime` → 1 ngày · `string` (maxLength) → 1 ký tự. Mệnh đề ở AC prose không có `Type` ⇒ luật thay cột (§1).
- **Miền đóng `[a,b]`**: `a−1` reject · **`a` accept** · **`b` accept** · `b+1` reject.
- **Miền mở `(a,b)`**: `a` reject · **`a+ε` accept** · **`b−ε` accept** · `b` reject.
- **Cấm chỉ test phía reject** — thiếu phía accept thì code gõ `<` thay `<=` vẫn xanh.
- **Biên đôi ⇒ 4 TC · biên đơn ⇒ 2 TC.** `maxLength 255` chỉ chặn một phía ⇒ **255 accept** + 256 reject. `0 < x ≤ 12` chặn hai phía ⇒ 0 reject + **1 accept** + **12 accept** + 13 reject.
- **BVA nuốt EP khi trùng ca — CẢ HAI PHÍA, không chỉ phía reject.**
  - *phía reject:* mệnh đề reject **có ngưỡng** không sinh TC EP riêng — ca đó chính là `max+1` / `min-1`, ghi `Technique = BVA (EP)`.
  - *phía accept:* **cùng field đã có BVA** thì phân vùng accept của EP **đã nằm trong** ca "tại biên (accept)" — `1` và `12` cùng một lớp tương đương với `3`. Không sinh thêm TC "giữa miền" ⇒ term EP viết **`EP:0+n`**.
  - EP chỉ còn giữ mệnh đề reject **không** ngưỡng (`Required: yes` thiếu giá trị, không thuộc tập giá trị đóng, sai format) và, nếu `Required: no`, ca bỏ trống (§3.1 dòng 4 — ca đó **không** phải biên nên BVA không nuốt).
  - `EP:0+n` **chỉ hợp lệ khi dòng sổ có term BVA cùng field**; không có BVA mà `m = 0` là bỏ sót phía accept. `check-ledger` assert ④ kiểm đúng điều kiện này.

  Bỏ luật này ⇒ hai TC cùng input `256` (phía reject) hoặc một TC `x = 3` không thêm độ phủ nào (phía accept) — và tệ hơn: **hai lượt chạy bất đồng**, đo được ở gate tất định 2026-09-04 (`AC-F900-006`, lượt `reconcile` đẻ thêm `TC-F900-092`).

### 2.2 DT — chi tiết

- **Mặc định là DỰNG** (027 D6). Phát hiện ≥2 điều kiện độc lập cùng quyết một kết quả ⇒ **dựng bảng quyết định**, không chờ ai đồng ý. Prompt (nếu phiên có người) hỏi để **BỎ**, không phải để làm:

  ```
  AC-F002-006 có 2 điều kiện độc lập: (1) han_hoan_thanh < hôm nay  (2) trang_thai ≠ Done
  → Đã dựng bảng quyết định 4 tổ hợp. Bỏ đi? [y/N]
  ```

  **Không ai trả lời ⇒ giữ bảng.** Bất đối xứng chi phí: 3 TC thừa xoá trong một phút, ma trận quyền thiếu thì không ai biết mà xoá. Suy luận này ghi một dòng `Gaps` — *"DT dựng theo suy luận từ prose, cần QC xác nhận"* — thừa mà **thấy được** thì xoá được.
- **Bắt buộc có** tổ hợp *"cả hai đều không"* và *"cả hai đều có"* — hai ô bị bỏ nhiều nhất.
- Rút gọn được, nhưng mỗi cột gộp/bỏ phải ghi lý do `impossible` hoặc `don't-care`.
- Cột nào frd không định nghĩa expected ⇒ `blocked-by-spec`, không đoán.
- Ví dụ: hai field loại trừ A/B ⇒ **4 tổ hợp** (chỉ A · chỉ B · cả hai · không cái nào). Test một chiều là thiếu 3 ô.

### 2.3 ST — chi tiết

- Ô hợp lệ → state đích. Ô không được phép **mà vẫn gọi được** qua API/UI → TC chứng minh bị từ chối. Ô không có đường gọi ⇒ ghi `unreachable`, không TC.
- **Ba ca luôn phải có:** ① lặp lại hành động đã làm (idempotency) ② hành động trên state **terminal** ③ **nhảy cóc** bỏ bước giữa.
- Ví dụ `Pending → Approved → Active → Superseded` (+ `Rejected`): phải có TC *duyệt lại đơn đã duyệt*, *từ chối đơn đã Active*, *duyệt đơn đã Superseded*.
- Race condition (2 request đồng thời) **không thay thế** state machine — hai lớp lỗi khác nhau.

### 2.4 UC — chi tiết

- **5 nhánh bắt buộc rà:** ① huỷ giữa chừng ② dữ liệu rỗng (0 dòng) ③ double-submit ④ đồng thời (2 người / 2 request) ⑤ quá khổ / timeout.
- "Rà" = **phải xét**, không phải phải có TC. Mỗi Flow ghi đúng 5 dòng, mỗi dòng một dạng: `áp dụng → TC-F*` · `không áp dụng → {lý do}` · `frd chưa nói → blocked-by-spec`.
- ②③④ không đến từ frd ⇒ **chỉ được sinh câu hỏi**, không được sinh oracle.

### 2.5 EG — ba nguồn (mỗi TC ghi rõ nguồn nào)

| Nguồn | Lấy ở đâu |
| --- | --- |
| **A** | Finding trong `test-report.md` của feature này / feature dùng chung component (`fdd.md > Components Used`) |
| **B** | Cạm bẫy kỹ thuật ghi trong `CLAUDE.md` của repo sản phẩm (ORM, phân tách tenant, thư viện UI, kiểu số) |
| **C** | Đặc thù dữ liệu bản địa: Unicode có dấu, khoảng trắng copy-paste, dấu phân cách thập phân |

### 2.6 Phân hoạch phía KẾT QUẢ — bề mặt quan sát (027 D7)

`m + n` phân hoạch phía **input**. Cùng luật đó áp cho phía **output**:

> `Then` liệt kê **≥2 bề mặt quan sát** ⇒ **mỗi bề mặt một TC**, slug `::EP::surface-{tên}`.

Bề mặt quan sát = một chỗ người dùng hoặc hệ thống khác **đọc được** kết quả: danh sách trên màn · file export · dropdown/autocomplete · response API · thông báo · bản ghi trong DB · webhook/event.

Ba bề mặt là **ba đường code** (query của list, query của export, query của dropdown). Gộp một TC thì hỏng một bề mặt cũng chỉ ra **một** tín hiệu đỏ — và ba lần trong bốn, tín hiệu đó chỉ vào bề mặt đã đúng.

*Ví dụ:* `Then hợp đồng không còn ở danh sách, ở file export, và ở dropdown chọn hợp đồng` ⇒ **3 TC**, không phải 1.

Bề mặt mà frd **không nói** kết quả phải thế nào ⇒ không sinh TC cho nó (luật 0.3), không suy từ bề mặt khác.

## 3. Tra nhanh

### 3.1 Ba hình dạng làm `m > 1` — bảng ĐÓNG (027 D2)

"Nhiều phân vùng accept" là phán đoán; bảng dưới biến nó thành **tra cứu**. Không khớp dòng nào ⇒ **`m = 1`**, không sáng tạo thêm dòng.

| Hình dạng trong `Rule` / `Then` / `When` | `m` | Ví dụ |
| --- | --- | --- |
| **Chuẩn hoá trước khi so** — "bỏ qua hoa/thường", "cắt khoảng trắng", "bỏ dấu" | 1 (nguyên văn) **+ 1 mỗi phép chuẩn hoá** | khớp tên bỏ hoa/thường **và** cắt khoảng trắng ⇒ `m = 3` |
| **Bí danh** — "chấp nhận các cách viết A, B, C" | **1 mỗi bí danh** | `Mã HĐ` · `Ma HD` · `MaHopDong` ⇒ `m = 3` |
| **Thu hẹp phạm vi ràng buộc** — "duy nhất **trong phạm vi** bản ghi chưa xoá" | 1 (trong phạm vi) **+ 1 (phần bị loại)** | trùng mã với bản ghi đã xoá mềm ⇒ vẫn accept ⇒ `m = 2` |
| **Field không bắt buộc** — `Required: no` | 1 (có giá trị) **+ 1 (bỏ trống)** | `ghi_chu` optional, `maxLength 500` ⇒ bỏ trống là **accept**, `m = 2` |

Mỗi phân vùng accept là **một TC riêng**, slug `accept-{slug mệnh đề}` (§4). Gộp ba cách viết vào một TC "accept" là mất 2 ca — đó chính là lỗ hổng `1 + n` để lại.

**`Required` rơi vào `m` hay `n` là theo giá trị của nó, không theo thói quen:**

| | ca "bỏ trống" thuộc về | vì |
| --- | --- | --- |
| `Required: yes` | **`n`** (một lý do reject) | bỏ trống bị từ chối |
| `Required: no` | **`m`** (một phân vùng accept) | bỏ trống **được chấp nhận** — và đó là một nhánh code riêng, thường là nhánh quên `null`-check |

Đây là chỗ dễ trượt nhất của dòng thứ tư: `Required: no` hay bị đọc thành *"không có ca thiếu giá trị"* thay vì *"ca thiếu giá trị nằm ở phía accept"*. **Không cổng nào bắt được lỗi này** — `check-ledger` chỉ kiểm `m+n` khớp hình dạng, C1–C8 không đụng tới `m`. Chỉ golden của bed bắt được, tức ở dự án thật thì **không ai bắt**.

### 3.2 TC tối thiểu

| Tình huống | TC tối thiểu |
| --- | --- |
| 1 mệnh đề có `m` phân vùng accept và `n` lý do reject | `m + n` |
| 1 ngưỡng **đôi** (miền đóng hoặc mở) | `4` |
| 1 ngưỡng **đơn** (`maxLength`, `≥ n`) | `2` |
| 1 rule có `n` điều kiện nhị phân (`n ≤ 4`) | `2ⁿ` cột, mỗi cột ≥1 TC (rút gọn kèm lý do) |
| 1 tập giá trị đóng có vòng đời `N × M` | mọi ô hợp lệ + mọi ô không hợp lệ **gọi được** + 3 ca bắt buộc |
| `Then` liệt kê `k` bề mặt quan sát | `k` |
| 1 Flow | 1 main + mọi nhánh frd đã ghi |
| `k` biến cấu hình, tích > 20 | phủ 100% cặp |

> **Ba con số review nhanh:** ngưỡng đôi ⇒ **4 TC** (đơn ⇒ 2); rule 2 điều kiện ⇒ **4 tổ hợp**; `Then` ba bề mặt ⇒ **3 TC**. Thấy 1 TC ở đó là thiếu.

## 4. Ghi `Technique` vào đâu

| Bucket | Cách ghi |
| --- | --- |
| **Validation** (bảng) | **cột** `Technique` |
| **Functional** (block) | **field** `Technique` trong bảng meta, cạnh `Type` / `Autoable` |
| **E2E** | không thêm field — luôn là `UC` (ghi một dòng đầu section) |
| **Non-functional · Data & Migration** | không thêm field — ngoài phạm vi bảng trigger (`NA`) |

Một giá trị **chính**; kỹ thuật phụ ghi trong ngoặc (`BVA (EP)`). TC không gắn được kỹ thuật nào ⇒ thừa, hoặc đang trộn nhiều mục đích → tách.

**Slug phía accept đối xứng với slug phía reject (027 D3):** `m = 1` ⇒ `accept` · `m > 1` ⇒ **`accept-{slug mệnh đề}`** (`accept-nguyen-van` · `accept-bo-hoa-thuong` · `accept-cat-khoang-trang`). `Key` được tuyên bố **tất định**; slug tự chế ⇒ `reconcile` mất join key ⇒ TC ID nhảy giữa hai lượt.

TC từ **ST** vẫn dùng **đúng bảng Validation** khi neo vào VR — không cần shape mới: `Field` = field của VR, `Input` = `{state} + {event}`. Bảng `N state × M event` giữ vai **bằng chứng phủ ô**, ghi `TC-F*` vào từng ô chứ không mint TC ở đó.

Chỉ TC thật sự không vừa cột (DT nhiều field cùng lúc) mới viết **dạng block** trong chính bucket của item, và block đó **phải lộ đủ** `TC ID` · `Covers` · `Field` · `Input` · `Expected` · `Polarity` — [`/spec-test-exec`](../skills/spec-test-exec/SKILL.md) đọc đúng bộ field này để route; thiếu một cái là TC **không xuống được** test-exec mà không ai báo.

**Functional TC lộ thêm `Field` · `Input` · `Polarity` khi `Technique ∈ {EP, BVA, ST}`** (027 D5) — field **conditional**, chỉ có khi kỹ thuật là một trong ba. Lý do: một AC mang ràng buộc field sinh TC hình dạng validation nhưng ở lại bucket functional; thiếu ba field đó thì `/spec-test-exec` route nó qua harness functional mà không có gì để điền — **lệch bucket** im lặng.

**KHÔNG đẻ bucket mới** — giữ map `item → bucket` ở §1 cho Traceability Matrix và routing.

## 5. Cổng chốt — chưa đạt thì không chuyển `draft → approved`

| # | Điều kiện |
| --- | --- |
| **C1** | 100% TC ở Validation + Functional có field `Technique` |
| **C2** | Mỗi ngưỡng có TC ở **biên hợp lệ**, không chỉ biên sai |
| **C3** | Tập giá trị đóng có vòng đời ⇒ có **bảng** chuyển trạng thái phủ 100% ô gọi được; sổ derive (§5.1) ghi `ST:N×M` |
| **C4** | Rule ≥2 điều kiện ⇒ có **bảng** quyết định, mỗi cột ≥1 TC; sổ derive ghi `DT:2^n` |
| **C5** | Mỗi Flow có ≥1 TC nhánh phụ **và** ≥1 TC ngoại lệ — nếu frd ghi nhánh đó |
| **C6** | Mỗi TC `Technique=EG` có trích nguồn |
| **C7** | Mọi `Expected` **chạy tới được** từ `Preconditions` + `Steps` của chính TC đó — không có bước ẩn, không dựa state mà không TC nào dựng |
| **C8** | `Expected` là **một** oracle tất định. Nhiều kết quả cùng hợp lệ ("400 hoặc 404", "báo lỗi hoặc bỏ qua dòng") ⇒ frd chưa quyết ⇒ `blocked-by-spec` + `Gaps`, **không** viết oracle rời rạc |

> **C3/C4 đã bật** (027 D6). Trước đây hai cổng này treo *"chưa áp — cần bảng bằng chứng"*; bảng bằng chứng chính là **sổ derive** dưới đây.
>
> **C7/C8 chặn cái mà đếm số không chặn được** (027 D8): oracle rời rạc làm test **xanh cả khi code sai** — đủ TC mà vẫn không phát hiện lỗi.

### 5.1 Sổ derive — bảng bằng chứng, kiểm được bằng máy (027 D10)

Section `## Sổ derive` trong `test-design.md` — **conditional**: artifact chưa có sổ vẫn conformant, checker **skip**. Một dòng cho **mỗi frd item** (Flow · Story AC · VR · FAC · NFR · DM; `US` không có dòng riêng — nó được phủ qua các AC của nó):

| frd item | Technique | công thức đòi | đã sinh | ghi chú |
| --- | --- | --- | --- | --- |
| `VR-F900-005` | `ST` | `12 = ST:4×4` | 12 | 4 state × 4 event |
| `VR-F900-004` | `BVA+EP` | `5 = BVA:4 + EP:1+0` | 5 | biên đôi `0 < x ≤ 12` |
| `AC-F900-010` | `DT` | `4 = DT:2^2` | **1** | ⚠ thiếu 3 — `blocked-by-spec` |
| `AC-F900-011` | `EP` | `3 = EP:3+0` | 3 | 3 bề mặt quan sát (§2.6) |
| `Flow 1` | `UC` | `4 = UC:1+3` | 4 | main + 1 nhánh phụ + 2 ngoại lệ |
| `NFR-F900-001` | `NA` | `1 = NA:1` | 1 | 1:1 |

**Cú pháp cột `công thức đòi` — ĐÓNG, để máy đọc được:**

```
{tổng} = {TECH}:{expr} [+ {TECH}:{expr} ...]
```

- `{tổng}` phải **bằng tổng giá trị** của mọi `{expr}`.
- Tập `{TECH}` phải **trùng** tập ở cột `Technique` (cột đó ngăn bằng `+`, vd `BVA+EP`).
- Hình dạng `{expr}` bắt buộc theo kỹ thuật:

| `TECH` | `expr` phải là | Ý nghĩa |
| --- | --- | --- |
| `EP` | `m+n` | `m` phân vùng accept (§3.1) · `n` lý do reject. **`m = 0` chỉ hợp lệ khi dòng có term `BVA`** — BVA đã phủ phía accept (§2.1) |
| `BVA` | một số nguyên | ≥ 4 nếu ghi chú nói **đôi**, ngược lại ≥ 2 |
| `ST` | `N×M` | state × event |
| `DT` | `2^n` — rút gọn thì `2^n-k`, ghi chú **phải** có `impossible` hoặc `don't-care` | `n` điều kiện |
| `UC` | `a+b` (`a ≥ 1`) | main + số nhánh frd đã ghi |

> **`a+b` chỉ đếm đủ khi TC nhánh được neo vào Flow.** `check-ledger` tính một TS/TC thuộc `Flow N` khi `Key` mở đầu `Flow N::` **hoặc** `Covers` chứa `` `Flow N` ``. TS main có sẵn `Key: Flow N::UC::main`; TC nhánh **phải** tự neo — thêm `` `Flow N` `` vào `Covers` (khi TC đã neo vào một `AC`), hoặc mang `Key: Flow N::UC::{slug-nhánh}` (khi nhánh không thuộc `AC` nào). Thiếu bước này thì `b` luôn đếm ra 0 và assert ② báo lệch.
| `EG` · `PW` | một số nguyên ≥ 1 | |
| `NA` | `1` | FAC/NFR/DM giữ 1:1 · **Story AC thuần hành vi** không có ràng buộc field nào (§1 — có mệnh đề reject/ngưỡng/ST/đa bề mặt thì KHÔNG được NA) |

Kiểm bằng `spec-lite check-ledger .specs/tests/{F-XXX}-{slug}/test-design.md`. Bốn assert:

| # | Assert | Bắt lỗi gì |
| --- | --- | --- |
| ① | tập dòng sổ **⊇** tập frd item | **bỏ sót** — quên hẳn một item thì không có dòng nào để so |
| ② | `đã sinh` == số TS/TC thật neo vào item đó (`Key` mở đầu bằng `{item}::`, hợp với `Covers`) | sổ khai khống |
| ③ | `đã sinh` ≥ `tổng` của `công thức đòi`; thiếu ⇒ phải có `blocked-by-spec`/`Gaps` neo **cùng item** | sinh hụt so với chính phép tính của mình |
| ④ | `công thức đòi` khớp bảng cú pháp trên theo `Technique` | **khai khống cột "đòi"** — hai số tự khai khớp nhau nên ①②③ đều pass |

**① và ④ là hai assert then chốt.** Thiếu ① thì quên item không ai biết; thiếu ④ thì agent ghi `EP · đòi 1 · sinh 1` cho một item lẽ ra `DT · đòi 4` và pass sạch. Cột "công thức đòi" **vẫn do agent suy** — chưa máy hoá được vì phải đọc hiểu prose. Nhưng nó hết là *tự khai*: con số nằm trong artifact, cạnh `Technique`, QC đọc được.

> Ngưỡng thực tế của sổ: từ *"agent quên, không ai biết"* xuống *"agent suy sai, và cái sai nằm trên giấy"*.

**`Gaps` hai tầng:** (A) item có TC nhưng chưa chạy xanh → thuộc `test-report.md`, không ghi ở đây. (B) điều kiện lẽ ra phải có TC theo §1–§2 mà chưa sinh được (thiếu oracle, `blocked-by-spec`) → **ghi ở đây**.

**Trùng lặp không phải độ phủ:** cùng oracle + cùng dữ liệu viết ở cả functional lẫn e2e chỉ tốn thời gian chạy. E2E chỉ giữ case đi qua ≥2 story.

## 6. Ranh giới

File này chỉ làm **một việc**: với frd item **đã tồn tại**, sinh đủ TC. Nó **không** đi tìm item còn thiếu.

Lớp rủi ro không suy ra được từ item nào — audit log, notification retry, ma trận `role × action`, 2 người duyệt cùng lúc, regression lên component dùng chung — là **lỗ hổng của frd**. Đường xử lý: review frd → `/spec-frd` hoặc `/spec-new` bổ sung item → lần chạy `/spec-test-design` sau §1 nhặt lên bình thường.

Test-design **không có quyền định nghĩa hành vi** — chỉ verify hành vi frd đã định nghĩa.
