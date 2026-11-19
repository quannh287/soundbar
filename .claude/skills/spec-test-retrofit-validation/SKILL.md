---
name: spec-test-retrofit-validation
description: Retrofit acceptance test tầng VALIDATION cho MỘT feature đã có code nhưng thiếu test — viết validation test SAU code, giá trị đúng derive từ VR (không đọc code), neo chặt VR-F*, sanity-red chứng minh test biết đỏ, phân loại đỏ thành finding (bug-code/spec-drift), dựng lại test-report-validation.md rồi sinh lại roll-up. Tầng đầu tiên (VR): seam hẹp, không đụng UI. Import references/test-core.md + references/retrofit-core.md.
---

# spec-test-retrofit-validation

## Overview

Retrofit **Validation Test Cases** (neo `VR-F*`) cho một feature đã implement nhưng chưa có test. Đây là **tầng đầu tiên** trong bộ 3 skill retrofit (`validation` → `functional` → `e2e`) — VR đơn giản nhất (seam hẹp, không UI, phán đoán thấp) nên dùng làm pilot dựng cỗ máy.

**Cỗ máy lõi ở hai file, đọc cả hai trước:**

| File | Giữ gì |
|---|---|
| [`references/test-core.md`](../../references/test-core.md) | phần dùng chung với họ skill outer — 4 luật bất di (§0) · điền test-exec (§2) · tier vocabulary (§2a) · reconcile + anchor 2 chiều (§2b) · seam theo tầng (§3) · prune (§6) · **ghi `test-report-{scope}.md` (§7) + dựng lại roll-up (§7b)** |
| [`references/retrofit-core.md`](../../references/retrofit-core.md) | phần chỉ đúng cho đường **code trước, test sau** — vòng lặp lõi quét A/B (§1) · version-gate + pin-gate (§1b) · refresh mode (§1c) · **guided sanity-red mutate-revert (§4)** · phân loại đỏ thành finding (§5) · red flags (§8) |

Skill này chỉ định nghĩa lớp đặc thù VR: *chọn seam hẹp + viết 1 positive + ≥1 negative*.

**Vai trò trong bức tranh retrofit** (`.docs/013` §2):
```
references/test-core.md      ← luật dùng chung (cả outer lẫn retrofit)
references/retrofit-core.md  ← thêm phần code-trước-test (3 tầng retrofit dùng)
        ▲
  spec-test-retrofit-validation   ← skill này: core + seam VR + shape pos/neg
```

## When to Use

- Feature đã có code + `test-design.md` (có Validation Test Cases neo VR), nhưng **chưa có / thiếu / chỉ có test cũ không neo VR** → retrofit để có regression net neo chặt VR + verify code đúng VR. Test cũ chưa neo VR **không** được bỏ qua — reconcile qua core §2b.

## When NOT to Use

- Feature **chưa có** `test-design.md` → chạy `/spec-test-design` trước.
- Muốn test **Story AC** (behavior/component) → `/spec-test-retrofit-functional`. Muốn test **FAC** (e2e cross-story) → `/spec-test-retrofit-e2e`.
- Viết test **trước** code (double-loop, test-first) → đây là luồng khác (ngoài scope retrofit).
- Feature không có `VR-F*` nào ở frd → không có gì để retrofit ở tầng này.

---

## Tham số

- **No-arg (default)** — đường tự động: gated version/pin + phân loại NEW/MODIFIED/UNCHANGED + nâng pin (core §1b). Đây là đường **hấp thụ TC mới/đổi** (version-transition).
- **`--mode execute|sanity|full`** — refresh report **chủ động, all-TC-in-scope, pin-neutral** (core §1c). `execute` = chạy lại test (cột `Result`); `sanity` = mutate lại seam đã ghi → chứng minh test bám code (cột `sanity-red`/`mutation`/`reverted` + verify `Tier`); `full` = re-wire + re-prove + re-run (mọi cột; nguồn-ghi duy nhất của `Tier`). **Chỉ chạy khi scope current (`pin == version`)** — stale thì từ chối, báo chạy default trước. Ràng buộc đầy đủ: **core §1c**.

---

## Process

> **Bước 1-2, 6-7 thuộc `references/test-core.md` + `references/retrofit-core.md`** (cỗ máy lõi) — đọc file đó. Bước 3-5 dưới đây là **đặc thù VR**.
>
> **Hai quét (core §1).** Bước 3 + 3.5 là **quét A**: đọc code một lượt cho **hết** VR TC của scope, điền wiring, TC nào không viết được thì phân loại + ghi row `⏭` **ngay** (+ `BLK-VAL-*` ở §3, trừ `no-seam`), rồi ghi `test-exec-validation.md` **một lần**. Bước 4 + 5 là **quét B**: theo từng cụm negative của cùng một VR — viết/neo test cả cụm → chạy → mutate một lần → cụm đỏ → revert → verify-green → ghi row §4 của cả cụm. Quét A **không** mutate gì.

### Bước 1: Xác định feature + dựng bộ test-exec (core)

- Xác định feature có `test-design.md` (cảnh báo nếu `draft`, **không** block).
- Dựng/dùng bộ test-exec qua `/spec-test-exec` → có `test-exec-validation.md` (khung, ô wiring trống) + `test-report-validation.md` (khung + legend, `Results` rỗng, pin `0`) + roll-up `test-report.md` trong `.specs/tests/{F-XXX}-{slug}/`.
- **Ghi đúng một file report: `test-report-validation.md`** (writer duy nhất của nó). KHÔNG đọc, KHÔNG ghi `test-report-{functional,e2e,nfr,dm}.md`. Đặt frontmatter của file đó `mode: retrofit` (scaffold ra `mode: cycle` → flip sang `retrofit`, bật §2 Findings + 3 cột sanity-red ở §4).
- **Ghi thêm sổ `spec-debt.md` của feature, cạnh `frd.md`** (`.specs/main/feature/{F-XXX}-{slug}/`, [`.docs/039`](../../.docs/039-spec-debt-mot-so-cap-feature.md)) — chỉ theo core §5: thêm **một** dòng `**phát hiện:**` vào mục `SD` đã có cho ID đó nếu mục chưa có dòng của tầng này (mọi mode), hoặc mở `SD` mới cho drift chưa có mục (chỉ default/`full`). Commit cùng `test-report-validation.md`. Gặp sổ kiểu cũ (`.specs/integrations/*/` · `.specs/tests/*/`) ⇒ **dừng trước khi chạy test**, in `npx spec-lite migrate-spec-debt`. Phép đối chiếu ngược chỉ xét `SD` neo `VR-*` (trụ của tầng này) → dòng `A-VAL-n` ở §5.
- **GATE version + pin (core §1b, 016)** — làm việc ở cấp-scope `validation`:
  - **Version-gate:** `test-design.versions.validation` > `test-exec-validation.test_design_version` → **STOP**, báo chạy `/spec-test-exec {F-XXX}` trước (retrofit KHÔNG tự reconcile wiring — D9).
  - **Pin-gate:** `test-report-validation.test_exec_version` (**một số**) == `test-exec-validation.version` → scope current, dừng ("không có gì cần retrofit"). Tụt (gồm pin=0) → chạy lại **cả scope** validation.
  - Phân loại TC **NEW/MODIFIED/UNCHANGED** (core §1b): NEW/MODIFIED = full-loop (Bước 3-5, sanity-red mới); UNCHANGED = chỉ re-execute (Bước 5 chạy test), inherit sanity-red/Finding.
  - **Nếu chạy với `--mode` (core §1c):** bỏ qua nhánh phân loại NEW/MODIFIED/UNCHANGED — thay vào đó áp mode cho **hết TC** của scope theo cột mà mode sở hữu, **pin-neutral**. Chỉ hợp lệ khi `pin == version`; stale → STOP báo chạy no-arg (default) trước. Version-gate vẫn enforce như trên.

### Bước 2: Lọc Validation TC (core)

- Nguồn: `test-design.md > ## Validation Test Cases`. Mỗi TC neo đúng 1 `VR-F*`.
- Không có Validation TC → dừng, báo "feature không có VR để retrofit".

### Bước 3: Chọn seam hẹp + điền test-exec *(đặc thù VR)*

Với mỗi VR TC — **đọc code cũ** → tìm **seam hẹp nhất** enforce rule đó. Tier dùng bộ vocabulary 2-chân ở **core §2a** (prefix stack), ưu tiên bậc rẻ nhất. VR chủ yếu là **chân BE** (4 bậc) + `fe:unit` khi rule enforce client-side:

| Tier | Rule kiểu | Seam trong code | Harness test |
|---|---|---|---|
| `be:unit` | format / length / range / required thuần | validator | Contract.Tests / Domain.Tests — `new` object, không I/O |
| `be:handler` | cross-entity mà **logic C# tự enforce**: **unique · immutable · mutual-exclusion · computed-C#** | command/query **handler** | Application.Tests + **fake/mock repo + UoW** (vd `FakeRepositoryBase`/`FakeUnitOfWork`) — **KHÔNG cần DB, KHÔNG cần HTTP** |
| `be:persistence` | rule **chỉ DB enforce được**: **FK/membership · unique index · phép suy diễn nằm trong EF query · global filter/interceptor** | schema / EF config / query-handler chạy SQL | Persistence.EF.Tests — **DB thật in-memory** (vd SQLite) + DbContext |
| `be:api` | rule nằm ở **chính tầng HTTP**: model-binding 400 (field thiếu/kiểu sai) · permission/auth gate (401/403) · routing/middleware | endpoint pipeline | full-HTTP integration (vd WebApplicationFactory) — **bậc đắt nhất, chỉ khi seam thật sự ở HTTP** |
| `fe:unit` | VR enforce **client-side**: schema (zod/yup) / format thuần | schema / validate fn | test runner (vd vitest) — không DOM |

- ⚠ **Seam xác định từ CODE, KHÔNG từ cột layer của test-design** (core §3, luật 1). test-design ghi "api" nhưng rule thật enforce ở handler (vd unique check trong `CreateXCommandHandler`) → **theo code**, chọn `handler`, ghi lệch vào Note. TUYỆT ĐỐI KHÔNG mặc định "server-side ⇒ api".
- ⚠ **Seam cần harness project CHƯA có** (vd full-HTTP integration khi repo chỉ có test layer-isolated) → **KHÔNG tự dựng harness trong skill** (core §3). Ở quét A: TC đó nhận `Action = harness` + một `BLK-{SCOPE}-N`, **vẫn chạy tiếp** các TC test được ở harness đã có. **Cả scope** thiếu harness ⇒ **dừng có biên bản** (core §3): ghi trọn §4 với `⏭ harness`, `BLK`, dòng §5 `👤 DEV`, nâng pin, dựng lại roll-up, rồi mới escalate — không dừng im để lại `pin 0` + §4 rỗng.
- ⚠ **Phân biệt harness vs refactor (core §3b).** Ranh giới = **"tách seam ra rồi test bằng infra sẵn có được không?"** — KHÔNG phải "logic vs render". VR hay gặp: (a) zod/logic thuần **chôn inline** trong `.input()`/thân mutation resolver → **extract-ra-hàm/export-schema** → `be:unit`; **HOẶC (b) VR client-side là hành vi render/tương tác chôn inline trong page/component lớn** (vd popup cảnh báo non-blocking) → tách thành **component props-driven** → render độc lập bằng render-harness đã có (`fe:component`, KHÔNG mock cả graph tRPC/router). Cả hai = `refactor` (defer cho owner, ưu tiên hơn harness). Chỉ tag `harness` khi **kể cả sau khi tách vẫn buộc dựng infra chung mới** (DB in-memory / full-HTTP / Proxy-mock graph tRPC không tách khỏi được). Một **export cực nhẹ** (thêm `export` cho const/schema đã tách sẵn) skill CÓ THỂ tự làm inline + ghi report; **extract logic/tách component khỏi resolver/page** thì defer `refactor`. ⚠ Bẫy: "VR là render" hoặc "chôn trong page lớn phải Proxy-mock" → chớ vội gán harness; hỏi "tách component ra là hết cần Proxy chưa?".
- Điền vào `test-exec-validation.md`: `layer · Test File (nơi test) · assert (input → expected) · polarity`. Seam encode qua `layer` (core §2).
- **Giá trị hợp lệ/vi phạm lấy từ VR text** (test-design), KHÔNG từ code (retrofit-core luật 1). VR không cần testid.

### Bước 3.5: Reconcile với test validator có sẵn *(core §2b)*

- Quét test validator/handler hiện có cho rule đó **TRƯỚC khi viết mới**.
- Test cũ assert **đúng VR** → **inherit**: anchor TC ID (NUnit `[Category("TC-F003-0xx")]` / tên method chứa TC ID) + trỏ `Test File` vào nó, ghi `sanity-red = inherited` (inherited-anchor) ở Results. KHÔNG viết trùng.
- Test cũ assert **theo code lệch VR** (vd `ApCostZero_PassesValidation` trong khi VR đòi `>0`) → **finding**, KHÔNG tính đã cover: giữ test cũ nguyên, viết test mới neo VR → để đỏ → classify. **KHÔNG** sửa test cũ cho khớp.
- Test cũ reject **đúng ca vi phạm nhưng không kiểm lý do** (chỉ assert "có lỗi", không assert mã lỗi VR đòi) → **inherit rồi siết oracle** (core §2b): neo TC ID + thêm assert mã lỗi vào chính test đó.

### Bước 4: Viết test — 1 positive + ≥1 negative *(đặc thù VR)*

- **1 positive**: giá trị hợp lệ theo VR → pass.
- **≥1 negative**: mỗi cách vi phạm VR (rỗng / sai format / quá dài / ngoài range...) → reject đúng lý do.
- Test implement đúng test-exec vừa điền. Đây là **shape cứng của VR** — KHÔNG dùng Given-When-Then (đó là tầng functional).

### Bước 5: Sanity-red + chạy + classify *(theo core, sắc thái VR)*

- **Sanity-red (core §4):** với VR, mutation tự nhiên = **tắt đúng check đó** trong validator/schema/nhánh 400 → negative TC phải flip 🔴 → revert → verify green → ghi sanity-red/mutation/reverted ở Results. (VR không cần mutate handler phức tạp như AC.)
- **Batch per-rule (core §4):** tắt 1 rule thường làm đỏ cả cụm negative của cùng VR → 1 chu kỳ mutate-revert chứng minh proven-red cho cả cụm; ghi cột mutation từng dòng TC (cùng thay-đổi cho cả cụm) nhưng share một lần mutate (F-003: ~51 rule thay vì ~100 TC). Chi phí thật = round-trip sửa/revert code, KHÔNG phải tốc độ test.
- Chạy test thật lên code cũ → record result vào `test-report-validation.md` §4 Results.
- Đỏ → classify (core §5): **bug-code** (code không enforce VR) | **spec-drift** (code lệch VR **có dấu vết**, BA quyết — tra/ghi sổ `spec-debt.md` cạnh `frd` theo core §5) | flaky | test-error. Ghi §2 Findings, ID `FIND-VAL-NN` (core §7.3). **KHÔNG sửa test cho xanh.**

### Bước 6: Prune (core)

- Validation TC / hành vi pin mà không neo `VR-F*` nào → bỏ. KHÔNG có section `Pruned` (core §6): phần đáng nâng thành VR thật trong frd là **việc** ⇒ một dòng ở §5 Next Actions (`Loại` = `coverage-gap`, `PIC` = `👤 QC`); phần "đã bỏ, xong" → commit message.

### Bước 7: Dựng lại report + nâng pin + roll-up + report (core)

- **Dựng lại trọn `test-report-validation.md`** rồi ghi đè một lần (core §7): 5 section `1 Summary · 2 Findings · 3 Blockers · 4 Results · 5 Next Actions`. `Covers`/`Summary`/`Coverage`/dòng `**Mục:**` **tính lại**; `sanity-red`/`mutation`/`reverted`/`Tier`/`Action`/`Note` **kế thừa** từ bản trước của chính file này cho TC `UNCHANGED`; số đếm ID mang sang (append-only).
- §5 Next Actions lấy từ **ba nguồn** (core §7.5): §2 `FIND-VAL-*` còn đỏ · §3 `BLK-VAL-*` · §1 `Coverage` thiếu phủ. `PIC` **derive** từ `Loại` theo map core §7.4 — `👤` là vùng đóng băng, không tự nâng thành `🤖`.
- **Nâng pin (core §1b③, 016):** set `test_exec_version` = `test-exec-validation.version` ở frontmatter `test-report-validation.md` — đóng vòng scope.
- **Dựng lại roll-up `test-report.md`** (core §7b, 4 bước): glob `test-report-*.md` **trừ roll-up** → đọc pin + §1 + §5 + số finding đỏ mở của từng file → dựng lại trọn 3 bảng. KHÔNG đọc bản roll-up cũ. UNCHANGED TC inherit sanity-red/Finding; NEW/MODIFIED có sanity-red/Finding mới (MODIFIED đang là Finding → verdict đã re-evaluate).
- Report cho user: số VR covered, số đỏ + verdict, action items (tách `🤖` và `👤` theo `PIC`), pin validation đã tiến tới v{N}, roll-up đã sinh lại.
- **Commit** trước khi chạy tầng kế (git = history duy nhất của `.specs/tests/*`).

---

## Đơn vị tiến độ

Sổ của skill này: `.specs/tests/{F-XXX}-{slug}/.progress/validation.md` — **writer duy nhất là skill này**; KHÔNG đọc, KHÔNG ghi sổ của skill khác. Dựng lại **trọn** sổ mỗi lượt rồi ghi đè: nội dung derive từ artifact nên một ô sửa tay bị ghi đè ở lượt sau. Hình dạng + frontmatter: `templates/tests/verify-progress-template.md`; định nghĩa thư mục: `02-artifacts.md` §4.7.

**Hạt là một dòng / TC**, nhóm hiển thị theo VR. `[x]` nghĩa là *"đã có bản ghi"*, không phải *"xanh"*.

**Việc lớn** — `- [ ] /spec-test-retrofit-validation   pin {p}/{v}   ({k}/{n})` — tick khi `test-report-validation.test_exec_version` == `test-exec-validation.version`. Version-gate lệch ⇒ in `⛔ chạy /spec-test-exec` thay vì `[ ]` (core §1b).

| Việc nhỏ | Đọc file / field | Xong khi |
|---|---|---|
| `TC-…  {result}` — 1 dòng / TC của `test-exec-validation.md` §4 | `test-report-validation.md` §4: `Result` · `sanity-red` · `mutation` · `reverted` | `Result` ∈ {🟢, 🔴, 🟡} **và** bản ghi **tự nhất quán** (xem dưới) |
| *(TC hoãn)* `⏭ {Action} → {BLK}` | cùng row: `Action` · `Note` | `Action` ∈ 4 tag **và** (`Action` ≠ `no-seam` ⇒ `Note` trỏ đúng một `BLK-VAL-N` có mặt ở §3) |
| *(annotation)* `wired` | `test-exec-validation.md` §4 cột **`Test File`** khác placeholder | — |
| *(annotation)* `có test` | grep TC ID dưới `spec_root` (frontmatter của `test-exec`) | — |
| *(nhóm hiển thị)* VR | `test-exec-validation.md` §3.1 cột `Covered by TC IDs` | mọi TC dưới nó đã xong |

**Bản ghi tự nhất quán** = row §4 tồn tại **và** `sanity-red` ∈ {`proven-red`, `red-first`, `inherited`, `n/a`} **và** (`sanity-red` = `proven-red` ⇒ `mutation` có nội dung **và** `reverted` = `✅`). Tick theo "có row" thì `[x]` che đúng ca core §7.0 cấm — row ghi trước khi revert xong, tức TC đọc là xanh trong khi code sản phẩm vẫn đang mang mutation.

`Result` = `—` ⇒ **không tick**: row có mà chưa có bằng chứng (core §7.5 — `sanity-red = —` chỉ hợp lệ khi TC không chạy).

`⏭` là **xong**, cả bốn tag. Sản phẩm của một `⏭` **là** quyết định phân loại + một `BLK-VAL-*` + một dòng §5 với `PIC` = `👤`; `no-seam` thì core §7.5 gọi thẳng là "đóng". Chạy lại cũng không đổi được gì — `Action`/`Note` là cột **kế thừa**, chỉ `--mode full` ghi lại. Hậu tố `⏭ {Action} → {BLK}` là **bắt buộc**, không tuỳ chọn: `[x]` trơn đọc thành "xanh".

⚠ **Bit "đã wiring" đọc cột `Test File`, KHÔNG đọc `Layer`.** Template và fixture đều ghi `Layer` = `unit|api` (bộ từ cũ) nên cột đó luôn có giá trị; bộ 2 chân `be:unit`/`be:handler`/… chỉ sống ở cột `Tier` của report §4.

**TC đang dở giữa chu kỳ mutate-revert:** dòng là `[ ]` và sổ **không đoán** nó ở pha nào — chỉ hai bit derive được (`chưa có row §4` · `có test`). Việc "có mutation nằm lại hay không" thuộc gate cây sạch (`git status`), không phải một dòng sổ.

**Cấm đưa vào sổ:**

- Version-gate / pin-gate thành dòng việc — chúng là **điều kiện**, không phải việc (in `⛔` ở việc lớn).
- Bước 7 tách 3 dòng (dựng report · nâng pin · roll-up) — cùng một bit với `pin == version`.
- Bước 6 Prune · Bước 3.5 reconcile test cũ (đã nằm trong `sanity-red = inherited`).
- Row của §2 / §3 / §5 — chúng là **kết quả**, không phải tiến độ.
- Cụm mutate-revert làm dòng tick — cụm chỉ biết được **sau** khi đọc code (nó hiện ở cột `mutation` khi row đã có), nên dùng làm **nhóm hiển thị** thì được, làm đơn vị tick thì không.
- Dòng `step=` — biên bản là của orchestrator.

---

## Ràng buộc (nhắc lại từ core — áp cho VR)

- Đọc-xuống: **KHÔNG** sửa test-design, **KHÔNG** sửa frd (spec-drift → finding + mục `SD` ở sổ cạnh `frd` → BA quyết ở `/spec-new {F-XXX}`).
- Nhìn code chỉ để biết *móc vào đâu* (validator/schema/nhánh 400 nào), **KHÔNG** để lấy *giá trị đúng*.
- Test xanh mà **không** có `sanity-red` proven-red (cột §4 Results) = KHÔNG tính pass.
- Guided mutation phải **revert sạch + verify green** trước khi sang TC kế; verify-green fail → **STOP** (repo bẩn).
- Result + Findings ghi ở **`test-report-validation.md`**, KHÔNG ghi vào `test-exec-validation.md`, KHÔNG ghi vào file scope khác.
- **Format (core §7.1):** đúng **5** section, **toàn bảng** — 0 đoạn văn trần, ô không vượt trần ký tự, `Vấn đề` hai mệnh đề chứ không phải nhãn cụt. KHÔNG `Pruned`/`Observations`/`Sanity-Red Ledger`/`Change History`/timeline/run-log. Lịch sử = git + commit message; lý luận chung → `retrofit-core`.
- **Đọc-hiểu (core §7.2):** mọi nhãn dùng trong bảng phải có **legend** ở section định nghĩa nó; ba câu hỏi *sai gì · chưa kiểm được gì · ai làm gì tiếp* trả lời được mà không cần mở code.
- Report **chỉ do skill ghi** — không có lối người sửa tay (030 D22).

## Red Flags

- Lấy giá trị hợp lệ/vi phạm từ code thay vì từ VR text → test soi gương code.
- Mỗi VR chỉ có positive (thiếu negative) → không chứng minh rule thực sự enforce.
- Đặt validation test ở tier cao (`be:api`/`e2e`) trong khi rule enforce được ở `be:unit`/`be:handler` → sai seam (lãng phí + chậm).
- Tin cột layer của test-design thay vì đọc code → đặt test sai tầng (kinh điển: "api" cho rule enforce ở `be:handler`; hoặc đòi WebApplicationFactory trong khi seam là handler test được bằng fake repo).
- Gộp `be:persistence` vào `be:handler`: rule FK/membership/EF-query cần DB thật mà đi dùng fake repo → test không bao giờ bắt được, tưởng cover mà không (xem core §2a ranh giới handler↔persistence).
- Dùng Given-When-Then cho VR → nhầm shape tầng functional.
- Sửa test cho xanh khi gặp đỏ thay vì phân loại finding.
- Tái dùng test validator cũ mà không đối chiếu VR → nuốt mất bug-code (test cũ soi gương code, vd assert `0` hợp lệ trong khi VR đòi `>0`).
- Test (mới/inherited) không nhúng TC ID máy-đọc-được → mất tra ngược `code ↔ test-exec`.
- Còn TC không neo VR nào mà không prune.
- Mở/ghi `test-report-{functional,e2e,nfr,dm}.md` → mỗi report một writer (core §7); tầng khác nằm ở file khác.
- Ghi xong file scope mà **không dựng lại roll-up**, hoặc dựng roll-up bằng cách đọc bản cũ rồi gộp thêm → vỡ core §7b.
- ID `Finding-01`/`OBS-1`/`A1` (không tiền tố scope), hoặc đánh số lại khi chạy lại → vỡ core §7.3.
- Gán `PIC` theo cảm tính, hoặc tự nâng `👤 BA`/`👤 DEV` thành `🤖` rồi tự sửa spec/hạ tầng → vỡ core §7.4.

## Verification

- [ ] Mỗi Validation TC neo đúng 1 `VR-F*`; suite 100% traceable tới VR ID.
- [ ] Mỗi VR có **≥1 positive + ≥1 negative**, có `sanity-red`/`mutation`/`reverted` ở §4 Results (proven-red).
- [ ] Test validator cũ ở mỗi seam đã reconcile (inherit-anchor / finding), không viết trùng, không nuốt bug (core §2b).
- [ ] Mỗi test (mới/inherited) nhúng TC ID máy-đọc-được (Category/tên), 2 chiều với test-exec.
- [ ] `test-exec-validation.md` điền đủ `layer/file/assert/polarity` cho mỗi TC; **không** có ô result.
- [ ] Result + Findings **chỉ** ở `test-report-validation.md` (`mode: retrofit`); `git diff` chứng minh file scope khác **không đổi dòng nào**.
- [ ] File scope đúng 5 section, toàn bảng, 0 ô vượt trần; §1 `Summary` + số đếm ở dòng `**Mục:**` khớp đếm lại từ §4.
- [ ] Report đạt tiêu chí đọc-hiểu (core §7.2) — mọi nhãn có legend, ba câu hỏi trả lời được.
- [ ] Mọi dòng §5: `Nguồn` trỏ `FIND-VAL-*`/`BLK-VAL-*`/req-ID (không mồ côi), `Loại` thuộc 8 nhãn, `PIC` khớp map core §7.4.
- [ ] Đã **dựng lại roll-up** `test-report.md` từ mọi `test-report-*.md` (trừ chính nó); `derived_from.validation.test_exec_version` = pin vừa nâng.
- [ ] TC không viết được (⏭ deferred) đã điền cột `Action` = `refactor` / `harness` / `need-clarify` / `no-seam` (core §7.5) + trỏ 1 `BLK-VAL-N` ở `Note` (trừ `no-seam`), không để trống trơn; `harness` vs `refactor` phân đúng (core §3b — có đường tách seam (hàm thuần HOẶC component props-driven) test bằng infra sẵn có ⇒ `refactor`; render KHÔNG tự động = harness).
- [ ] Findings phân loại đúng bug-code vs spec-drift; spec-drift có action nối `/spec-new {F-XXX}` và có mục `SD` ở sổ cạnh `frd` (core §5).
- [ ] GATE version+pin đã chạy (core §1b): version lệch → STOP báo `/spec-test-exec`; pin bằng → skip; pin tụt → re-run cả scope.
- [ ] Scope re-run: NEW/MODIFIED full-loop (sanity-red mới), UNCHANGED chỉ re-execute (inherit sanity-red); MODIFIED-Finding đã re-evaluate verdict (016 D11).
- [ ] Cuối: đã **nâng pin** `test_exec_version` = `test-exec-validation.version` ở `test-report-validation.md` (core §1b③).
- [ ] Mọi mutation đã revert sạch (verify green); repo không còn code bị phá.
- [ ] TC bị bỏ: phần đáng nâng thành VR đã thành một dòng §5 (`coverage-gap`), phần còn lại ghi ở commit message — KHÔNG có section `Pruned`.
- [ ] Hai quét đúng thứ tự (core §1): hết quét A thì **mọi** TC có wiring trong `test-exec-validation.md` và mọi TC `⏭` đã có row + `BLK`, mà **chưa** chu kỳ mutate nào chạy.
- [ ] Row §4 của một cụm ghi **ngay sau** revert + verify-green của cụm đó (core §7.0), không dồn tới cuối scope.
- [ ] Đã ghi lại `.progress/validation.md` theo section `## Đơn vị tiến độ`: một dòng / TC, nhóm theo VR, mỗi dòng `[x]` mang ký hiệu result hoặc hậu tố `⏭ {Action} → {BLK}`.
