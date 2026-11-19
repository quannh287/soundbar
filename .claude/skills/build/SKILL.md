---
name: build
description: Implement task tiếp theo trong plan.md/todo.md theo TDD incremental — viết test thất bại, implement, verify, commit, lặp lại. Dùng khi thực thi tasks từ plan.md/todo.md.
---

# Build

## Tổng quan

Implement từng task trong `plan.md`/`todo.md` theo TDD bên trong vòng lặp incremental. Mỗi task kết thúc bằng test suite xanh, build sạch, và một atomic commit trước khi chuyển sang task tiếp theo.

Invoke `incremental-implementation` và `test-driven-development` cùng nhau cho mỗi task. Với task UI/UX: invoke `frontend-ui-engineering` luôn; invoke thêm `frontend-design` chỉ khi greenfield (chưa có design system).

## Quy trình

### Cờ trong ARGUMENT

ARGUMENT có thể chứa cờ ngoài slug:

| Cờ | Nghĩa |
|---|---|
| `--auto` | Bật **non-interactive profile** — không hỏi câu nào; mỗi điểm hỏi rẽ theo nhánh **`[--auto]`** ghi ngay tại chỗ đó |
| `--worktree=y` / `--worktree=n` | Chở sẵn quyết định worktree (Bước 0b) để không phải hỏi. Vắng cờ trong `--auto` ⇒ coi như `n`. **Bước 0b.0 thắng cờ này** — đang ở sẵn trong worktree khớp `feat/{slug}` thì build tại đó, kể cả khi cờ là `n` (cờ nói "có tạo worktree mới không", không nói "có rời worktree đang đứng không") |

Bỏ cờ ra khỏi ARGUMENT **trước** khi khớp slug ở Bước 0.

Cờ có phạm vi **đúng một lần gọi** — không ghi trạng thái ra file, nên lần gõ tay sau vẫn hỏi đầy đủ. `/implement` là caller duy nhất truyền `--auto`.

**Phạm vi task không đổi vì `--auto`:** cả hai chế độ đều chạy **hết** task `[ ]` trong `todo.md`.

---

### Bước 0: Xác định integration

**Nếu có ARGUMENT:**
- Parse argument: có thể là số thứ tự (`2`, `002`) hoặc slug (`002-implement-todo`)
- Quét `.specs/integrations/*/todo.md`, tìm integration khớp với argument
- Nếu không tìm thấy → báo lỗi:
  > Không tìm thấy integration khớp với "{argument}". Kiểm tra lại tên hoặc số thứ tự.
- Nếu tìm thấy → dùng `.specs/integrations/{slug}/` làm working integration, bắt đầu luôn

**Nếu không có ARGUMENT:**
- Quét `.specs/integrations/*/todo.md`, liệt kê tất cả integrations có todo.md, đánh dấu tiến độ:

```
Integrations:

  [1] 001-implement-auth    — Implement Auth             (8/8 done) ✓
  [2] 002-implement-todo    — Implement Todo Management  (0/10 pending)

Chọn số integration:
```

  Format: `({done}/{total} done)` hoặc `({pending} pending)` — đếm từ todo.md
  - Nếu chỉ có 1 integration có task pending → chọn luôn, không hỏi
  - Nếu tất cả đều done → thông báo: "Tất cả integration đã hoàn thành."

### Bước 0a: Gate check — plan.md phải approved

Đọc frontmatter của `.specs/integrations/{slug}/plan.md`.

Nếu `plan.md` chưa tồn tại:

> ⛔ Chưa có `plan.md` cho integration **{slug}**.
>
> Để tiếp tục:
> 1. Chạy `/plan` để tạo plan.md và todo.md
> 2. Review và đổi `status: approved` trong plan.md
>
> Sau đó chạy lại `/build`.

**Dừng hoàn toàn.**

**`[--auto]`** Vẫn **dừng thật**, và return `{ tasks_done: [], blocked: "chưa có plan.md" }`. Không tự chạy `/plan` để chữa — caller mới biết có được phép sinh plan hay không.

Nếu `plan.md` tồn tại nhưng `status` **không phải** `approved`:

> ⛔ `plan.md` của integration **{slug}** chưa được approve (status hiện tại: `{status}`).
>
> Để tiếp tục:
> 1. Review `.specs/integrations/{slug}/plan.md`
> 2. Đổi `status: draft` → `status: approved` trong frontmatter
>
> Sau khi approve xong, chạy lại `/build`.

**Dừng hoàn toàn. Không tiếp tục.**

**`[--auto]`** Vẫn **dừng thật**, và return `{ tasks_done: [], blocked: "plan.md chưa approved" }`. Trong luồng `/implement` thì `/plan --auto` đã stamp `approved` trước đó, nên tới được đây mà vẫn `draft` là có gì sai — không được tự stamp để đi tiếp.

Nếu `status: approved` → tiếp tục sang Bước 0b.

---

### Bước 0b: Tạo branch và chọn chế độ worktree

**0b.0 — Đang ở sẵn trong worktree KHỚP integration này ⇒ nhận luôn, KHÔNG hỏi.**

Kiểm trước khi làm bất cứ gì khác trong 0b:

```bash
git rev-parse --git-dir           # khác --git-common-dir ⇒ đang ở worktree phụ (linked)
git rev-parse --git-common-dir
git branch --show-current         # nhánh của cây hiện tại
basename "$(git rev-parse --show-toplevel)"
```

| Điều kiện | Xử |
|---|---|
| `--git-dir` ≠ `--git-common-dir` **và** nhánh hiện tại == `feat/{slug}` | **Nhận worktree này**, bỏ qua phần còn lại của 0b (không tạo branch, không `worktree add`, không hỏi). Báo một dòng: `worktree sẵn có, nhánh khớp — build tại đây`. |
| Cây phụ nhưng nhánh là `feat/{slug-khác}` | **STOP**, báo blocked: đang ở worktree của integration khác. Đừng build `{slug}` ở đây — commit sẽ rơi vào nhánh của integration kia. |
| Cây chính, nhánh đã là `feat/{slug}` | Coi như chế độ `n` đã chọn: **không hỏi**, build tại chỗ. Branch đã có, bỏ qua bước tạo. |
| Còn lại | Đi tiếp 0b như thường (tạo branch → hỏi/nhận cờ worktree). |

Nhánh khớp mà `basename` của cây khác `{slug}` thì **vẫn nhận** — nhánh là căn cứ, tên thư mục chỉ là quy ước.

Sau khi nhận worktree sẵn có, **kiểm artifact có mặt** trước khi rời 0b: `.specs/integrations/{slug}/plan.md` + `todo.md` phải tồn tại **trong cây này**. Thiếu ⇒ chúng còn chưa commit ở cây chính ⇒ áp đúng bước **3** dưới (chuyển sang worktree rồi commit trong worktree), nếu không Bước 0a gate cứng trên `plan.md status: approved` và báo blocked oan.

> **Vì sao tự nhận mà không hỏi:** câu hỏi worktree chỉ có nghĩa khi còn lựa chọn. Đang đứng trong đúng worktree của integration rồi thì "y" là no-op và "n" là sai (build ở cây khác trong khi nhánh đã checkout ở đây — `git worktree add` cũng sẽ từ chối). Hỏi một câu chỉ có một đáp án đúng là chặn `/implement` không vì lý do gì.

---

**Tạo branch (bắt buộc):**

Luôn có branch `feat/{integration-slug}` trước khi build, bất kể có dùng worktree hay không. Điều này đảm bảo `/review-integration` luôn có base để diff chính xác (`git merge-base HEAD $BASE`).

**Hai chế độ tạo branch khác nhau — không dùng lẫn:**

| Chế độ | Lệnh |
|---|---|
| `n` (build tại cây hiện tại) | `git checkout -b feat/{slug}` — branch đã có thì `git checkout feat/{slug}` |
| `y` (build trong worktree) | `git branch feat/{slug}` — **tạo mà KHÔNG chuyển cây**; branch đã có thì bỏ qua |

**Với `y` tuyệt đối không `checkout -b`.** `git worktree add` **từ chối** một branch đang được checkout ở cây khác:

```
$ git checkout -b feat/004-x && git worktree add .claude/worktrees/004-x feat/004-x
fatal: 'feat/004-x' is already checked out at '…'
```

Đây là lỗi cứng của git, không phải trường hợp biên — làm sai thứ tự là chế độ worktree **không chạy được lần nào**.

---

**Chọn worktree (tùy chọn):** — chỉ tới đây khi **0b.0 không khớp** (đang ở cây chính, nhánh chưa phải `feat/{slug}`).

Hỏi user:

```
Bạn muốn build trong worktree riêng cho integration này không? (y/n)
```

**`[--auto]`** Không hỏi — lấy giá trị từ cờ `--worktree=y|n`. Cờ vắng ⇒ `n`. `/implement` đã hỏi câu này **đúng một lần** lúc vào và chở đáp án xuống đây, nên lựa chọn của người vẫn được tôn trọng mà loop không bị chặn.

**Nếu chọn "n":** Tiếp tục build trong working directory hiện tại trên branch vừa tạo.

**Nếu chọn "y":**

1. **Thêm `.claude/worktrees/` vào `.gitignore`**
   - Kiểm tra `.gitignore` ở root repo, nếu chưa có dòng `.claude/worktrees/` thì append:
     ```bash
     echo '.claude/worktrees/' >> .gitignore
     ```

2. **Tạo worktree mới** từ branch vừa tạo
   - Đường dẫn worktree: `.claude/worktrees/{integration-slug}` (ví dụ: `.claude/worktrees/002-implement-todo`)
   - Lệnh:
     ```bash
     git worktree add .claude/worktrees/{slug} feat/{slug}
     ```

3. **Chuyển artifact của integration sang worktree** *(bắt buộc — bỏ qua là blocked ngay vòng đầu)*
   - `git worktree add` checkout branch ở **HEAD**, nên mọi file **chưa commit** ở cây chính **không có mặt** trong worktree. Khi caller là `/implement`, `plan.md` + `todo.md` vừa do `/plan --auto` ghi ra và **chưa commit** ⇒ worktree không có chúng ⇒ Bước 0a gate cứng trên `plan.md status: approved` và báo blocked, dù plan hoàn toàn ổn.
   - **Chuyển** (không phải copy) rồi commit **trong worktree**, để cây chính sạch và base branch không dính commit nào:
     ```bash
     W=.claude/worktrees/{slug}
     mkdir -p "$W/.specs/integrations/{slug}"
     mv .specs/integrations/{slug}/*.md "$W/.specs/integrations/{slug}/" 2>/dev/null || true
     git -C "$W" add ".specs/integrations/{slug}"
     git -C "$W" commit -m "docs({slug}): plan + todo từ /plan"
     ```
   - Từ đây **mọi artifact của integration sống trong worktree**. Caller đọc/ghi qua `.claude/worktrees/{slug}/.specs/integrations/{slug}/` — `todo.md`, `techdebt.md`, `implement-log.md` đều vậy.

4. **Detect package manager**
   - Kiểm tra theo thứ tự: `pnpm-lock.yaml` → `yarn.lock` → `package-lock.json` → `package.json`
   - Dùng package manager tương ứng: `pnpm install` / `yarn install` / `npm install`
   - Nếu không có `package.json` → bỏ qua bước install.

5. **Copy env files**
   - Tìm tất cả file `.env*` ở root của working directory gốc (`.env`, `.env.local`, `.env.development`, v.v.)
   - Copy từng file vào worktree mới:
     ```bash
     cp .env* .claude/worktrees/{slug}/
     ```
   - Bỏ qua nếu không có file `.env*` nào.

6. **Chuyển working context sang worktree mới**
   - Tất cả các bước build tiếp theo đều chạy trong đường dẫn worktree mới.
   - Nhắc user biết đang build tại: `.claude/worktrees/{slug}`

### Với mỗi Slice — nhịp outer bọc quanh vòng inner (034 `DS2`)

Đơn vị của `/build` nay là **Slice**, không phải task lẻ: `plan.md` chia theo `### Slice N · {US-F*}`. Tám bước, vòng task cũ nằm gọn trong bước 4.

| # | Bước | Ai làm | Ghi ra đâu |
|---|---|---|---|
| 1 | Đọc `**Outer:**` của slice → danh sách `TC-F*` | `/build` | — |
| 2 | Điền `Layer` + `Test File`; TC tier `fe:component` thì **khai chuỗi testid** thành row; viết outer test; chạy → phải **ĐỎ**; ghi ngay row `sanity-red: red-first` với `Result: —` | `/spec-test-functional --phase=write` | `test-exec-functional.md` · `selector-contract.md` · `test-report-functional.md` |
| 3 | Đỏ đúng lý do *"chưa có code"* ⇒ đi tiếp; ngược lại → bảng phân loại dưới | `/build` | — |
| 4 | **Vòng inner**: TC của `VR` đỏ → code validator → xanh, **xen kẽ** unit test dev tự nghĩ; component gắn **đúng** chuỗi testid đã khai | `/build` + `/spec-test-validation` | code + test + `test-exec-validation.md` |
| 5 | Chạy lại outer test → phải **XANH** | `/build` | — |
| 6 | **Kiểm hai chiều** `contract ⊆ code` + `code ⊆ contract` cho mọi row slice này chạm, **và** mọi file sản phẩm slice này tạo có ít nhất một file không-phải-test import | `/build` | — |
| 7 | Cập nhật `Result` `—` → `🟢` trên row đã ghi ở bước 2/4; `sanity-red` giữ nguyên | `/spec-test-functional` **và** `/spec-test-validation`, `--phase=record` | `test-report-functional.md` · `test-report-validation.md` |
| 8 | **Commit**: code + outer test + VR test + unit test + row contract + row report + tick `[x]` | `/build` | git |

Bước 2 chạy **một lần cho cả slice** (mọi TC của story), không mỗi TC một lần gọi.
Bước 5 không xanh sau khi mọi task của slice xong ⇒ phân loại theo bảng dưới, **không sang slice kế**.

**TC của `VR` KHÔNG gom lên đầu cùng TC của `AC`.** Mỗi VR test viết **ngay trước** đoạn code làm nó xanh (bước 4), không batch upfront — gom cả ba tầng rồi mới gõ code là test-first waterfall.

**Slice chạm một VR: chưa có test thì viết, có rồi thì chạy lại.** Cả hai trường hợp VR đó phải xanh trước khi commit. VR dùng chung hai story thì slice thứ hai **chỉ chạy lại** — không viết trùng.

**Kiểm hai chiều ở bước 6, KHÔNG ở bước 4.** Ngay sau bước 2 thì `contract ⊆ code` **phải sai** — đó chính là lý do outer test đỏ. Chạy sớm là báo lỗi oan đúng lúc hệ đang ở trạng thái đúng.

**Không viết test cho dead code — kiểm ở bước 6 (034 `D15`).** Mọi file sản phẩm slice này **tạo mới** phải được ít nhất một file sản phẩm khác `import`; file test **không tính**. Không ai import ngoài test ⇒ slice **chưa xong**, không tick, không commit.

```bash
npx spec-lite check-dead-code {file slice vừa tạo...} --root={src-root}
```

Exit `1` ⇒ có file không ai dùng ⇒ slice chưa xong. Entry point (`main.tsx`) không ai import là **đúng**, miễn trừ bằng `--entry=`.

⚠ **KHÔNG tự grep tên module.** Đã thử và sai hai lần trên cùng một bed: (1) `types.ts` · `index.ts` **trùng tên** khắp repo nên grep basename báo *"có người import"* trong khi 11 file khớp đều import một `types.ts` **khác**; (2) TS ESM viết `from '../domain/viec-con.js'` trong khi trên đĩa là `.ts`, nên mẫu grep theo đuôi file trượt sạch. Lệnh trên **resolve** specifier về đường dẫn thật rồi mới so.

Lý do luật này tồn tại: test tier `fe:component` **tự dựng** component lên rồi kiểm (`render(<X />)`), nên nó xanh dù **không trang nào mount `X`**. Đo thật trên bed `F-007`: `ViecConPanel.tsx` xanh 2/2, task đã tick, phép trừ TC `25 == 25`, kiểm hai chiều contract↔code `9/9` — **bốn cổng đều xanh** mà mở trình duyệt lên không thấy gì, vì file đó chỉ được chính file test của nó import. Tầng `e2e` ở ④ Verify là thứ duy nhất bắt được, và bắt ở dạng `bug-code` trông như lỗi logic sâu.

Luật không riêng cho FE: một `usecase` không route nào gọi, một `repo` không usecase nào gọi, đều là cùng một hình dạng.

**Chỉ một bước import, cố ý.** Không đi ngược cây tới entry — phép đó cần mỗi project khai entry, mà cái nó mua thêm (bắt được **chuỗi** file cùng chết) gần như không xảy ra trong phạm vi một slice. Giới hạn đã biết: `A` import `B` mà chính `A` cũng chết thì vẫn lọt.

**Kiểm ở bước 6, KHÔNG ở bước 2.** Ở bước 2 chưa có dòng code nào — *mọi thứ* đều là dead code, đó chính là định nghĩa của nhịp RED. Luật này chỉ có nghĩa lúc slice đóng.

#### Phân loại outer test đỏ (034 `DS5`)

| Tình huống | Là gì | Làm gì |
|---|---|---|
| Đỏ ở bước 2, chưa có code | **bình thường** — nhịp RED | đi tiếp bước 4 |
| **Xanh** ở bước 2, row đã mang `sanity-red: red-first` | **bình thường** — slice này đang chạy lại sau khi bị ngắt (034 `D18`) | đi tiếp bước 4, **không** báo động |
| Đỏ ở bước 2 vì lý do khác (harness thiếu, seam gõ nhầm, thiếu dev dependency) | test-error | sửa test, **không** tính là finding |
| `module not found` của chính module slice này sắp viết | **bình thường** — vẫn là nhịp RED | đi tiếp; phân biệt bằng đường dẫn có trong bảng seam `tech.md` hay không |
| Đỏ ở bước 5, code **chưa** làm đúng câu chữ AC | chưa xong | quay lại bước 4 |
| Đỏ ở bước 5, code **đã** đúng câu chữ AC mà test vẫn đỏ | `need-clarify` — AC tự mâu thuẫn hoặc chỏi `tech.md`; spec không lệch với code ([`05 §7`](../../05-concepts.md), [`.docs/037`](../../.docs/037-spec-drift-mot-nghia.md) `D3`) | **dừng slice**, không tick, trả người |
| TC **đã xanh ở slice trước**, slice này chạy lại thành đỏ | **regression — defect thật** | dừng, không tick. Một TC đã từng xanh thì lần đỏ sau không thể là *"chưa code tới"* |
| AC không quyết được vì spec im lặng | `spec_gap` | sổ `spec-debt.md` của feature (review ghi), không đẻ vòng, không chặn slice khác |

Ba loại finding vẫn theo [`05-concepts.md §14`](../../05-concepts.md) — không thêm loại mới.

**`[--auto]`** Nhánh `need-clarify` và `regression` trả `blocked` kèm `TC-F*` + `AC-F*` cụ thể, **không** tự chọn một cách hiểu: `blocked: "need-clarify — {AC}: {TC} đỏ dù code đúng câu chữ"`.

---

### Với mỗi task pending *(bên trong bước 4 của slice)*

**1. Chọn task** (`incremental-implementation` — Increment Cycle)
Lấy task `[ ]` tiếp theo trong `todo.md` của integration đã chọn. Đọc acceptance criteria trong `plan.md` tương ứng.

**2. Load context** (`incremental-implementation` — Rule 0: Simplicity First)
Đọc code, types, patterns liên quan. Hỏi: "Cách đơn giản nhất có thể làm việc là gì?"

**2b. UI/UX check** — Nếu task liên quan đến UI/UX (xem dấu hiệu bên dưới), xác định ngữ cảnh rồi invoke:

- **Existing project** (đã có design system — tokens, component library, style guide): chỉ invoke `frontend-ui-engineering`
- **Greenfield** (chưa có design system, component mới hoàn toàn ngoài design system hiện tại): invoke `frontend-design` trước → sau đó `frontend-ui-engineering`

Dấu hiệu "existing design system": có file config Tailwind/CSS tokens, có thư mục `components/ui`, có Storybook, hoặc `sad.md`/`tech.md` đề cập design system.

**2c. Selector contract** — chỉ task UI. Đây là nơi `data-testid` được gắn và `.specs/tests/{F-XXX}-{slug}/selector-contract.md` được cập nhật (`.docs/026`).

Contract là **sổ đăng ký phía cung**: danh sách mọi `data-testid` sống trong code. Từ [`.docs/034`](../../.docs/034-double-tdd.md) `D10` nó có **hai loại row**, và thứ tự làm việc đổi theo:

| Row sinh từ | cột `TC` | Ai ghi | Lúc nào |
|---|---|---|---|
| **outer test đặt hàng** (TC tier `fe:component`) | **đã điền** — TC là lý do row tồn tại | `/spec-test-functional --phase=write` | bước 2 của slice |
| luật gắn testid sẵn có (khoản 1 · khoản 2 dưới) | rỗng — hợp lệ như hôm nay | `/build` bước 2c | bước 4 của slice |

⚠ **TRA CONTRACT TRƯỚC KHI TỰ ĐẶT TÊN.** Chuỗi nào outer test đã khai thì component **phải gắn đúng chuỗi đó** — đừng nghĩ tên mới rồi để hai bên lệch. Chỉ tự đặt tên cho element **còn lại**, tức element không TC nào đặt hàng.

`/build` **được đọc** `test-design.md` cho việc chia slice (034 `D2`), nhưng **không** derive cột `TC` của contract từ nó — cột đó do phía đọc điền.

Làm theo thứ tự:

0. **Đọc `.specs/tests/{F-XXX}-{slug}/selector-contract.md`** — lấy danh sách chuỗi đã khai ở bước 2 của slice.

1. **Gắn `data-testid` trong code** theo **hai khoản** (`.docs/026` D3):

   | | Gắn khi | Lấy từ |
   |---|---|---|
   | **1** | element **tương tác** được — nút, input, select, checkbox, link điều hướng | component vừa viết |
   | **2** | element **hiển thị thứ `spec.md` nói người dùng thấy** — thông báo lỗi, bộ đếm, nhãn trạng thái, badge, toast, dòng danh sách, trạng thái rỗng, vỏ render theo điều kiện | AC/VR trong `spec.md` |

   **Khoản 2 là nửa oracle** — chỗ test đọc để biết đúng/sai. Bỏ nó thì contract chỉ có nửa "bấm vào đâu", và ④ phải quay lại sửa code sản phẩm để bù. Đây cũng là nửa dễ sót nhất, vì element loại này thường chỉ render ở nhánh lỗi.

   ⚠ **Mỗi element khoản 2 phải trỏ được về một câu AC/VR cụ thể.** Không trỏ được ⇒ **không gắn**. Đó là thứ duy nhất chặn contract trôi thành ảnh chụp DOM. Phản ví dụ (không gắn): `<div>` layout, wrapper flex/grid, element thuần trang trí.

2. **Đặt tên** theo `{feature-slug}-{element}[-{qualifier}]` (`02-artifacts.md` §2.3). Element **dùng chung với feature khác** → giữ nguyên tên gốc, không đổi prefix.

   **Cú pháp gắn theo platform** (`references/testid-conventions.md` §1-2): `data-testid` (web-react) · `testID` (react-native) · **flutter: bọc widget bằng `Semantics(identifier: '<id>', child: ...)`** — Maestro đọc semantics tree, không thấy `Key`; giữ `Key` cũ nếu có cho widget test (hai cơ chế song song, không thay nhau).

3. **Merge row vào contract cho MỌI testid vừa gắn**, cột `TC` để **rỗng**. Tạo `.specs/tests/{F-XXX}-{slug}/selector-contract.md` từ `.claude/templates/tests/selector-contract-template.md` nếu chưa có (copy cả `template_version`).

   - **Testid nào vào code thì vào contract** — một luật, không tách. Không có "báo cáo element chưa TC nào phủ" nữa: nó chính là các row `TC` rỗng, đọc trực tiếp trong contract.
   - **Cột `TC` để rỗng.** Nó là **annotation** của phía đọc — `/spec-test-exec` điền lúc viết POM, retrofit điền lúc backfill. `/build` không biết TC nào tồn tại nên không đoán.
   - **Merge theo key `testid`**: chỉ thêm/sửa row của element vừa chạm. **KHÔNG** rewrite cả file — feature build qua nhiều integration, contract là artifact tích luỹ. Giá trị `TC` mà lượt trước đã điền: **giữ nguyên**.
   - Row bị xoá **chỉ khi** element bị gỡ khỏi code trong task này.

   **Registry global (flutter, hoặc react-native khi e2e của project là Maestro)** — `references/testid-conventions.md` §2b/§3: nguồn thật là file **GLOBAL** (vd `.maestro/selector-contract.md`), file per-feature chỉ reference. Ghi identifier mới vào global trước, đồng bộ row per-feature **trong cùng commit**. Vì `/build` chưa viết flow nào dùng đến id này → ghi vào bucket **Reserved**, KHÔNG vào bảng Identifiers chính (`references/testid-conventions.md` §5) — tránh vỡ check "id chết" hai chiều của harness (vd `tool/e2e.sh`). Promote Reserved → Identifiers là việc của `/spec-test-retrofit-e2e` khi flow thật sự dùng đến.

   **Cùng nhánh Maestro trên:** thêm assertion cho identifier MỚI vào widget/component test guard (vd `test/ui/selector_contract_test.dart`) — `find.bySemanticsIdentifier('<id>')` (flutter) hoặc `getByTestId('<id>')` (react-native) phải tìm thấy. Test hành vi cũ xanh **KHÔNG** chứng minh identifier mới có mặt (`references/testid-conventions.md` §2c).

   **Nâng cấp hình dạng contract (024 D18) — làm TRƯỚC khi merge, tự động, không hỏi.** Detector **hai bước**, đúng thứ tự:

   1. So `template_version` trong frontmatter artifact với của `.claude/templates/tests/selector-contract-template.md`. **Khớp ⇒ dừng ở đây**, merge row như bình thường.
   2. Lệch ⇒ **kiểm shape thật** trước khi đổi gì: header bảng của artifact có khớp header của template không?

   | Kết quả detector | Làm gì |
   |---|---|
   | version khớp | không nâng cấp |
   | version lệch, **shape đã khớp** template | **CHỈ stamp `template_version`** mới. KHÔNG đụng một dòng nào trong bảng, KHÔNG sửa `Notes`. Ca này có thật: file được sửa tay đúng hình dạng mới nhưng chưa ai stamp version |
   | version lệch, **shape cũ** | nâng cấp đầy đủ (dưới) |

   Nâng cấp đầy đủ — **đổi hình dạng, GIỮ nội dung**:

   1. Đổi header bảng sang hình dạng của template hiện tại.
   2. **Giữ nguyên mọi giá trị `TC` đang có.** Ô ghi `— (legacy)` hoặc `—` → đổi thành **rỗng** (v3 không còn phân biệt ba trạng thái; rỗng là hợp lệ).
   3. Stamp `template_version` mới vào frontmatter artifact.
   4. Rồi merge row của element task này chạm (bước 3 trên).
   5. Báo ở output cuối: `contract nâng cấp v{cũ}→v{mới}: {n} row`.

   ⚠ **Hai cái bẫy, cả hai đã xảy ra thật:**
   - **Bỏ bước 2 của detector là ăn dữ liệu.** Suy "version lệch ⇒ shape cũ" rồi đổi cả bảng sẽ ghi đè row người ta đã neo tay. Nâng cấp là thao tác **một chiều không hoàn tác được trong cùng commit**.
   - **Đừng derive lại cột `TC` hàng loạt.** `/build` không đọc `test-design.md` nên không có gì để derive; và ngay cả khi đọc, cột `TC` **không tất định** (hai lượt chọn witness khác nhau mà đều đúng). Bed ở pilot đo được: khớp **18/40** row, và **2 lỗi thật chìm trong 20 dòng lệch vô hại** (`.docs/024` D18).

   Nâng cấp nằm **trong cùng commit** với task (024 D5). `/artifact-migrate` **không** tham gia.

4. **Kiểm hai chiều** trong phạm vi file vừa chạm (`.docs/026` D6):
   - `contract ⊆ code` — mọi testid vừa ghi grep được trong code: `grep -r 'data-testid="{id}"'`.
   - `code ⊆ contract` — mọi `data-testid` trong file component vừa sửa có row trong contract. Thiếu ⇒ thêm row, không bỏ qua.

**Lệch giữa `spec.md` và UI** — `/build` không đọc `test-design.md` nữa, nên nó **không** phát hiện được lệch giữa TC và UI. Việc đó về ④ (`.docs/026` D8): `/spec-test-exec` viết POM và thấy bước của TC không thực hiện được trên UI thật, rồi xử bằng `need-clarify` / `blocked-by-spec` sẵn có.

Ở ③ chỉ còn một loại lệch, và nó nằm trong tầm `/build`: **`spec.md` mô tả thứ UI không làm được**, hoặc ngược lại UIUX design chỏi `spec.md`.

| Lệch chặn tới đâu | Làm gì |
|---|---|
| **Cả task** — không AC nào của task thực hiện được trên UI đã thiết kế | Dừng task, `need-clarify`, trả người. Không code tiếp |
| **Một/vài AC**, phần còn lại vẫn đúng | **Giao phần đúng**; AC bị chặn ghi rõ trong output. Task vẫn `[ ]` cho tới khi người quyết; báo `need-clarify` kèm danh sách AC bị chặn |

**KHÔNG** tự thêm UI để `spec.md` khớp, **KHÔNG** tự sửa `spec.md` để UI khớp — cả hai là cách **giấu** chỗ lệch, đắt nhất vì lần sau không ai biết nó từng tồn tại. Trọng tài là `frd.md`: cả `spec.md` lẫn UIUX design đều là hạ nguồn của nó.

**KHÔNG** bịa row contract cho element không tồn tại.

**Bước này CHỈ gắn testid, KHÔNG viết/chạy e2e test.** Gate additive dùng test suite hiện có (unit/widget/component ở bước 5) — KHÔNG kéo Playwright/Maestro vào build. Viết + chạy e2e (journey cross-story, sanity-red, verify-db/verify-api) là việc của `/spec-test-retrofit-e2e`, chạy **sau** khi feature build xong.

**`[--auto]`** Lệch **bề mặt** (cùng ý định, khác widget — `spec.md` ghi *"chọn mức ưu tiên"*, design dùng segmented control thay `select`) → xử luôn, không hỏi: gắn testid theo UI thật. Lệch **ý định** → dừng, return `blocked: "need-clarify — {AC} không thực hiện được trên UI hiện tại"`. Đây là spec lệch với UI, không lệch với code — không phải spec drift (`05 §14`).

**3. RED — Viết failing test** (`test-driven-development` — Step 1: RED)
Viết test trước. Chạy và xác nhận nó fail. Test pass ngay từ đầu không chứng minh gì.

**4. GREEN — Implement code tối thiểu** (`test-driven-development` — Step 2: GREEN)
Viết code ít nhất để test pass. Không over-engineer.

**5. Chạy toàn bộ test suite** (`incremental-implementation` — Increment Checklist)
```bash
npm test
```
Tất cả test hiện có phải vẫn pass. Nếu có regression → invoke `debugging-and-error-recovery`.

**6. Build** (`incremental-implementation` — Rule 2: Keep It Compilable)
```bash
npm run build
```
Build phải thành công trước khi commit. Nếu fail → invoke `debugging-and-error-recovery`.

**7. Đánh dấu hoàn thành trong `todo.md`**
Check `[x]` cho task này trong `todo.md` của integration đang build. Làm **trước** commit — bước 8 commit cả hai cùng lúc.

**8. Commit** (`incremental-implementation` — Increment Cycle)
Commit **gồm cả code lẫn tick `[x]`** vừa đánh, message mô tả rõ, giới hạn trong phạm vi task này. Một thay đổi logic mỗi commit. Task UI có sửa contract → `selector-contract.md` nằm **trong cùng commit đó** (contract lệch pha với code dù một commit là đã mở cửa cho drift).

> **Tick và code phải nằm trong CÙNG một commit.** Commit mang nghĩa *"task này đã xong"* — tách hai thao tác thì chết đúng khe giữa chúng để lại code đã commit nhưng `todo.md` còn `[ ]`, và lần chạy sau làm lại task đó. Đây cũng là điều kiện để `todo.md` là **nguồn sự thật về tiến độ** — thứ mọi cơ chế resume và mọi gate của `/implement` đang dựa vào.

**9. Tiếp tục**
Lặp lại từ bước 1 cho task `[ ]` tiếp theo, cho tới khi `todo.md` không còn `[ ]` nào.

## Dấu hiệu task UI/UX

Invoke `frontend-design` + `frontend-ui-engineering` khi task có bất kỳ dấu hiệu nào sau:

- Tạo hoặc sửa page, screen, route
- Tạo hoặc sửa form, input, dialog, modal
- Tạo hoặc sửa component có render HTML/JSX
- Refactor UI layout, spacing, typography
- Thêm hoặc sửa animation, transition
- Thêm hoặc sửa responsive behavior
- Bất kỳ thay đổi nào người dùng cuối có thể nhìn thấy

Nếu task chỉ liên quan đến logic, API, data, test — **không** invoke.

## Khi có bước thất bại

Invoke `debugging-and-error-recovery`:
1. STOP — không chuyển sang task tiếp theo
2. PRESERVE — lưu error output
3. DIAGNOSE — theo Triage Checklist (Reproduce → Localize → Reduce → Fix → Guard)
4. RESUME — chỉ sau khi test pass và build sạch

**`[--auto]`** Thử tối đa như trên. Vẫn bí ⇒ **không hỏi người** (subagent không hỏi được): dừng tại task đang tắc, **không** tick `[x]`, không commit code dở, rồi return `blocked: "{lý do ngắn — task nào, tắc ở đâu}"`. Task còn `[ ]` trong `todo.md` chính là cách caller biết còn việc.

## Quy tắc phạm vi (`incremental-implementation` — Rule 0.5: Scope Discipline)

- Chỉ chạm vào những gì task yêu cầu
- Không refactor code liền kề "tiện thể"
- Không implement chức năng của task tương lai
- Nếu thấy gì cần sửa ngoài phạm vi — ghi chú lại, không sửa
- **KHÔNG đọc, KHÔNG sửa `spec-debt.md`.** Sổ nợ của BA cạnh `frd.md` — `spec_gap` (hành vi hệ cần mà spec **không nói gì**) và `spec_drift` ([`02-artifacts.md §2.3`](../../02-artifacts.md)). Nó chờ **BA** quyết qua `/spec-new {F-XXX}`, không chờ dev. Đọc rồi tự implement là quyết hành vi sản phẩm thay BA — đúng thứ mà `spec_gap` được đặt ra để chặn. `techdebt.md` thì khác: đó là nợ dev, `/build` trả bằng Phase Review.

## Checklist hoàn thành

- [ ] Task có element trong `selector-contract.md` của feature: đã gắn testid đúng contract + đúng platform (`references/testid-conventions.md`); flutter → đã đồng bộ file global + per-feature
- [ ] Cây làm việc đúng chỗ: nhánh hiện tại == `feat/{slug}` (`git branch --show-current`), và nếu đang ở worktree phụ thì đó là worktree của **đúng** integration này — không có commit nào rơi vào nhánh của integration khác
- [ ] Mỗi task có test tương ứng
- [ ] Toàn bộ test suite pass: `npm test`
- [ ] Build sạch: `npm run build`
- [ ] Mỗi task có atomic commit riêng
- [ ] Tất cả task đánh dấu `[x]` trong `todo.md`
- [ ] Commit của mỗi task **chứa cả `todo.md`**: `git show --stat {sha}` phải thấy `todo.md` trong danh sách file
- [ ] Không còn uncommitted changes
- [ ] Task UI: `template_version` của contract **khớp** template hiện tại (lệch ⇒ đã nâng cấp tại chỗ theo D18, cùng commit; row legacy không map được TC để `—` + `Notes`, không xoá)
- [ ] **Kiểm hai chiều ở CUỐI SLICE** (bước 6), không ở cuối từng task UI — mọi row contract slice này chạm grep được trong code (`grep -r 'data-testid="{id}"'`), **và** mọi `data-testid` trong component vừa sửa có row trong contract (`.docs/026` D6). Cột `TC` rỗng là **hợp lệ** với row do `/build` tự đặt; row do outer test đặt hàng thì `TC` đã có sẵn
- [ ] **Không dead code:** mọi file sản phẩm các slice của lượt này **tạo mới** đều có ≥1 file không-phải-test `import` nó. Rỗng ⇒ slice chưa xong (034 `D15`)
- [ ] **Cuối lượt `/build`:** tập TC của mọi slice trong `plan.md` **bằng** tập row đã điền-hoặc-`⏭` trong `test-exec-{scope}.md`. Lệch ⇒ có TC thuộc slice bị bỏ sót. Row rỗng của TC thuộc **story không có trong integration này** KHÔNG tính vào phép trừ — đó là phần của lượt khác
- [ ] Task UI: `selector-contract.md` nằm trong `git show --stat {sha}` của đúng task đã sửa nó; row của integration trước **còn nguyên** (merge, không overwrite)

## Sau khi hoàn thành

Khi tất cả task trong session này đã done, thông báo:

```
Tất cả task đã hoàn thành. Bước tiếp theo: chạy /review-integration để kiểm tra toàn bộ implementation trước khi merge.
```

Không tự động invoke `/review-integration` — để user chủ động gọi.

**Nếu Bước 2c có nâng cấp contract**, báo kèm: `contract nâng cấp v{cũ}→v{mới}: {n} row`.

Không còn khối báo cáo *"element tương tác chưa TC nào phủ"* (`.docs/026` D4) — element như vậy **đã có row** trong contract với cột `TC` rỗng, đọc trực tiếp ở đó.

### `[--auto]` — return có cấu trúc

Thay vì đoạn thông báo trên, kết thúc bằng **đúng hai field**:

```
{ tasks_done: [T012, T013], blocked: null | "lý do ngắn" }
```

- `tasks_done` — task vừa tick `[x]` trong lượt này.
- `blocked` — `null` nếu chạy hết `todo.md`; ngược lại một câu ngắn. Lý do đặc thù của contract: `"need-clarify — {AC} không thực hiện được trên UI hiện tại"` (Bước 2c). Log trước [`.docs/037`](../../.docs/037-spec-drift-mot-nghia.md) mang tiền tố `spec_drift` thay cho `need-clarify` — cùng ca. **Không còn** `"feature {F} chưa có test-design"` — gate đó đã bỏ (`.docs/026` D2). Row có cột `TC` rỗng **không** phải blocked, cũng không phải cảnh báo.

Không kèm prose findings, không kèm tóm tắt code. Caller (`/implement`) **không** dùng return này làm nguồn sự thật — nó đếm `[ ]` còn lại trong `todo.md`; return chỉ là tín hiệu nhanh. Nghĩa là: báo `blocked: null` khi `todo.md` còn `[ ]` sẽ bị bắt, nên đừng làm.
