---
name: implement
description: Chạy trọn bước Plan + Build của một integration bằng một lệnh — /plan rồi vòng lặp /build ↔ /review-integration cho tới khi review sạch, có luật dừng và bản ghi kiểm được. Dùng khi spec.md + tech.md đã approved và muốn chạy dài không cần trả lời câu hỏi giữa chừng.
---

# Implement

## Tổng quan

Orchestrator cho **bước ② Plan + ③ Build** của Integration Pipeline (`01-architecture.md` §8). Một lệnh thay cho chuỗi gõ tay `/plan` → `/build` → `/review-integration` → *(có finding)* → `/build` → … và **dừng trước** ④ Verify.

Skill này **không phải** wrapper gọi ba lệnh. Nó là **bộ trả lời sẵn cho mọi câu hỏi mà ba skill kia sẽ hỏi**, cộng với **luật dừng** — thứ mà chuỗi gõ tay không có, vì stop condition nằm trong đầu người đang nhìn verdict.

Ba skill giữ nguyên hành vi. `/implement` chỉ cấp cho chúng một **non-interactive profile** bằng cách **truyền xuống** cờ `--auto` mỗi lần gọi.

**Luật nền của cả skill này:** *file mang nội dung, return value chỉ mang tín hiệu điều khiển.* Subagent ghi `plan.md`/`todo.md`/`techdebt.md`; nó trả về vài field để rẽ nhánh. `/implement` giữ **zero state** — mỗi vòng đọc lại `todo.md` và `plan.md` từ đĩa. Nhờ vậy một lượt bị compact hoặc Ctrl+C giữa chừng, gõ lại `/implement {slug}` là tiếp đúng chỗ dở.

## When to Use

- `spec.md` + `tech.md` của integration **đã `approved`**, và plan đã đủ tin để không cần đọc từng task trước khi build.
- Muốn chạy dài, không có người trực để trả lời câu hỏi.

## When NOT to Use

- Đang dò requirement, muốn đọc từng finding rồi tự quyết → gõ tay `/plan`, `/build`, `/review-integration`.
- Integration to tới mức review một khối là quá tải → đó là dấu hiệu integration bị chia quá to, sửa ở `/spec-new`.
- Chỉ muốn implement **một** task → dùng `/build`.

## Cờ trong ARGUMENT

```
/implement {số hoặc slug} [--worktree=y|n]
```

| Cờ | Nghĩa |
|---|---|
| `--worktree=y` / `--worktree=n` | Trả lời sẵn câu hỏi worktree ở Bước 1 để không hỏi gì cả. Vắng cờ ⇒ **hỏi đúng một lần** |

---

## Quy trình

### Bước 0: Xác định integration và gate precondition

Parse argument: số thứ tự (`2`, `002`) hoặc slug (`002-f002-todo-management`). Quét `.specs/integrations/*/`, tìm integration khớp. Không tìm thấy → báo lỗi và dừng.

Không có argument → liệt kê integrations có `spec.md` + `tech.md` `approved`, cho user chọn.

**Gate — `spec.md` và `tech.md` phải `approved`:**

Đọc frontmatter cả hai. Bất kỳ file nào chưa `approved` (hoặc `tech.md` chưa tồn tại):

> ⛔ Không chạy được `/implement` cho **{slug}** — chưa approved:
>
> - `spec.md` — status: `{status}`
> - `tech.md` — status: `{status}` *(hoặc: chưa tồn tại)*
>
> Hai artifact này **cascade lên `.specs/main/`**, nên human gate ở đây không bỏ được.
> Chạy `/spec-tech` nếu thiếu `tech.md`, review rồi đổi `status: approved`, sau đó chạy lại `/implement`.

**Dừng hoàn toàn.**

Đây là human gate **trước** vòng lặp. Gate **sau** vòng lặp là merge (Bước 5). `/implement` bỏ các gate *giữa chừng*, không bỏ hai gate đầu–cuối này.

---

### Bước 1: Hỏi worktree — đúng một lần

Nếu ARGUMENT không có `--worktree=`:

```
Build trong worktree riêng cho integration này không? (y/n)
```

Đây là **câu hỏi duy nhất** của cả lượt chạy. Giữ đáp án lại và chở nó xuống **mọi** lần spawn `/build` bằng cờ `--worktree=`.

Chọn `y` ⇒ ghi nhớ đường dẫn cây làm việc: `.claude/worktrees/{slug}/`. Đường dẫn này quan trọng ở Bước 4b — grep sai cây là gate vỡ.

**Với `--worktree=y`, sau vòng build đầu tiên thì MỌI artifact của integration sống trong worktree** — `plan.md` · `todo.md` · `techdebt.md` · `implement-log.md`. `/build` Bước 0b chuyển chúng sang đó rồi commit (artifact do `/plan` ghi ra ở cây chính vẫn **chưa commit**, mà `git worktree add` checkout ở HEAD nên không mang chúng theo). Từ đó trở đi `/implement` đọc **và ghi** qua `.claude/worktrees/{slug}/.specs/integrations/{slug}/`, không phải cwd.

---

### Bước 2: `/plan --auto` — chạy ở main

Invoke `Skill(plan)` với args `{slug} --auto`.

`plan.md` đã tồn tại ⇒ `/plan --auto` **resume**, không ghi đè (đó là nhánh `[--auto]` của nó). Không cần kiểm gì trước.

Xong, xử **theo thứ tự** — hai nhánh thất bại khác nhau, đừng gộp (`.docs/026` D7):

1. `/plan --auto` trả về `blocked` ⇒ dừng, ghi **nguyên văn** lý do đó vào `note=` của dòng `outcome`. **Không** suy diễn thành câu khác.
2. Không `blocked` ⇒ đọc lại `plan.md` từ đĩa, xác nhận `status: approved` và `approved_by: implement`. Không có ⇒ dừng, báo `/plan` không stamp được.

> Gộp hai nhánh là **mất chẩn đoán**: gate của `/plan` dừng thật thì nó không ghi `plan.md`, và (2) sẽ báo *"`/plan` không stamp được"* cho một ca hoàn toàn khác — người đọc đi debug `/plan` thay vì chữa cái gate vừa bắn. Đã xảy ra thật với gate `test-design` khi nó còn tồn tại ở `/plan` Bước 1c. Luật này áp cho **mọi** skill con: `blocked` của con là câu của con, `/implement` không viết lại.

Ghi log (xem §`implement-log.md`).

---

### Bước 3: Coverage check — chạy ở main

Một phép **trừ tập hợp** trên ID đã approve — **AC ∪ VR** — chạy **một lần**, ngay sau `/plan`, **trước** khi build một dòng nào.

**Vì sao cần:** review là **hàm của diff**, mà thứ bị *thiếu* không có mặt trong diff. Plan sót AC → build sót theo → review vẫn xanh vì code khớp đúng thứ plan bảo làm. Mắt người ở plan gate bịt lỗ này bằng cách **so hai danh sách**; bỏ gate thì phải có phép so cơ học thay thế.

**Bước 3a — dựng tập ID nguồn = `AC ∪ VR`**, hai nguồn có thứ tự:

- **(A)** `AC-*` **và** `VR-*` xuất hiện trong section `## Changes` của `spec.md` (row VR lấy Op `NEW`/`MODIFY`). Đây là ca integration có **delta** trên frd/crd.
- **(B)** chỉ khi (A) rỗng: `AC-*` của `frd.md`/`crd.md` theo `features:`/`components:` trong frontmatter `spec.md`, cộng `VR-*` của `frd.md` **neo vào tập đó** — `Refs` trỏ một `US-*` trong tập nguồn, **hoặc** một `AC-*` thuộc một US trong tập đó (035 D1). Lấy bằng `npx spec-lite check-vr-refs <frd.md> --json` rồi giao `vr[].us` với tập US nguồn — đừng suy lại quan hệ AC → US bằng mắt, nó là phép cơ học và suy lại thì mỗi lượt ra một kiểu. In kèm cảnh báo:

  > ⓘ Nguồn là frd/crd (spec.md không liệt kê ID nào) — đây là **superset**: AC/VR do integration **trước** giao cũng lẫn vào. Lọc bằng mắt.

**Vì sao không chỉ nhận `AC-*` (035 D1).** Luật trước 035 chỉ nhận `AC-*`; ở pilot **15 trên 24 VR chỉ trỏ `US-*`**, nên đọc đúng chữ thì 15 VR đó rớt khỏi phép trừ — mà phép trừ rớt thì **không ai báo**, nó chỉ ra kết quả nhỏ hơn.

**Vì sao VR vào cùng tập (029 D4).** VR là trụ riêng trong frd, có TC riêng bên QC (`test-exec-validation`), nhưng phía build không có đường nào **bắt buộc** đi qua nó — nó chỉ lọt vào plan khi `tech.md` tình cờ nhắc. Mở rộng phép trừ này là chỗ rẻ nhất để bịt: cùng cơ chế, thêm một tập.

`spec.md` là **changeset patch**, không phải bản liệt kê AC. Ca no-delta ("implement nguyên trạng, không sửa frd") chỉ ghi *"8 AC"* bằng văn xuôi — lấy trực tiếp từ `spec.md` thì phép trừ rỗng một cách vô nghĩa đúng ở ca hay gặp nhất.

**Bước 3b — trừ với `## Definition of Done` của `plan.md`:**

```
thiếu = (AC ∪ VR)(nguồn) \ ID(## Definition of Done của plan.md)
```

Neo vào `## Definition of Done`, **không** neo vào field `verify:` của task: `02-artifacts.md` §3.5 quy định task mang `verify: [AC-…]` nhưng `plan-template.md` chỉ có `**Verification:**` free-text, không có field AC nào. DoD là chỗ **có thật và đáng tin**.

**Bước 3c — in thô:**

```
⚠ Coverage: {n} ID có trong nguồn nhưng KHÔNG có trong ## Definition of Done của plan.md
  AC-F002-011
  AC-F002-014
  VR-F002-006
(nguồn: ## Changes của spec.md)
```

**Luật in:** **in thô danh sách ID chênh, KHÔNG phán xét, KHÔNG dừng loop.** Không được tự bào chữa cho plan của chính mình (*"T014 có làm, chỉ là không ghi ID"*) — có phán xét là có chỗ để thiên vị. Không dừng vì hoãn một AC có thể là chủ ý, miễn nó **hiện trên màn hình** thay vì im lặng.

Rỗng ⇒ in `✓ Coverage: mọi AC/VR của nguồn đều có trong Definition of Done`.

> **Chỉ một phép trừ.** Phép trừ `AC(DoD) \ AC(nhắc trong Tasks)` đã bị **bỏ**: đo trên plan thật ra 5/7 AC "thiếu" dù integration đã xong và xanh — task tả việc bằng văn xuôi, template không có field bắt rải AC ID. Nhiễu ~70%, và một cảnh báo hầu như luôn sai sẽ dạy người đọc bỏ qua cả khối, phá luôn phép trừ trên. Chỉ mở lại khi `plan-template.md` có field `verify:` bắt buộc.

Ghi log.

---

### Bước 4: Vòng lặp `/build` ↔ `/review-integration`

Đơn vị của vòng lặp là **cả integration** — không phải phase, không phải task.

#### 4a. Spawn `/build` ở subagent

Đếm trước: `n0` = số dòng `- [ ]` trong `todo.md` (xem 4b để biết đọc `todo.md` của cây nào).

**`n0 = 0` ⇒ KHÔNG spawn, sang thẳng 4c.** Đây là ca **resume**: lượt trước đã build hết task nhưng review chưa chạy hoặc chưa sạch. Spawn `/build` với 0 task vừa vô nghĩa vừa có hại — Bước 0b của `/build` chạy `git checkout feat/{slug}` vô điều kiện, nên nó **kéo cây làm việc sang branch khác** nếu ta đang đứng ở chỗ khác. Ghi vào log là `- [x] step=build sha={sha} round=0 skipped=n0-zero` — **không** có `from=`/`todo_*` vì không vòng nào chạy.

Spawn một subagent bằng Task tool, prompt **copy-paste nguyên văn**:

```
invoke /build {slug} --auto --worktree={y|n}
```

Không mô tả bằng lời, không diễn đạt lại luật auto — nhánh `[--auto]` đã nằm sẵn trong `build/SKILL.md` tại từng điểm hỏi. **Quên cờ `--auto` là subagent gặp `AskUserQuestion` mà subagent không hỏi người được** ⇒ nó đoán hoặc treo.

Return của nó: `{ tasks_done: [...], blocked: null | "lý do" }`.

#### 4b. Gate `todo.md` — nguồn sự thật

Đếm lại: `n1` = số dòng `- [ ]` còn lại trong `todo.md`.

```bash
grep -c '^- \[ \]' "$TODO"
```

`$TODO` là:

| Chế độ | Đường dẫn |
|---|---|
| `--worktree=n` | `.specs/integrations/{slug}/todo.md` |
| `--worktree=y` | `.claude/worktrees/{slug}/.specs/integrations/{slug}/todo.md` |

Cùng quy tắc cho `implement-log.md` và `techdebt.md`: `--worktree=y` ⇒ chúng ở **trong worktree**.

**Grep đúng cây là bắt buộc.** Với worktree, tick `[x]` được commit **trong worktree** trên branch `feat/{slug}`; `todo.md` ở cây chính vẫn `[ ]` cho tới khi merge. Đọc sai cây ⇒ `n1 = n0` mãi ⇒ báo blocked sai ngay vòng đầu.

Rẽ nhánh theo `n1`:

| Điều kiện | Làm gì |
|---|---|
| `n1 = 0` | → **4c** (review) |
| `0 < n1 < n0` | **spawn `/build` lần nữa** (4a) — vòng chạy dở, không phải lỗi |
| `n1 = n0` | không tiến triển → retry **một** lần; vẫn `n1 = n0` → **dừng** (§Luật dừng) |

**KHÔNG tin field `blocked` của return.** Nó là tín hiệu **nhanh**, không phải nguồn sự thật. Ba hệ quả:

- Return nói dối (`blocked: null` khi `todo.md` còn `[ ]`) bị bắt.
- **Subagent cạn context không còn là failure mode** — nó chỉ là một vòng chạy dở. Không cần phân biệt "chết vì hết context" với "làm được một nửa": cùng cách xử.
- Gate là **số đo khách quan**, không phải phán đoán.

Dùng `blocked` để **ghi vào log** cho người đọc, không để rẽ nhánh.

> **Lý do `blocked` đặc thù của selector-contract** (`.docs/026`) — dừng thật, ghi nguyên văn vào `note=` của dòng `outcome`, **không** tự chữa:
> - `"need-clarify — {AC} không thực hiện được trên UI hiện tại"` (log trước [`.docs/037`](../../.docs/037-spec-drift-mot-nghia.md) mang tiền tố `spec_drift` thay cho `need-clarify` — cùng ca) — `/build` Bước 2c bắt được lệch **ý định** giữa `spec.md` và UI. Dừng như ca `blocked` ở §Luật dừng (`reason=blocked`, nguyên văn chuỗi vào `note=`): trả người, không đẻ task fix. AC không làm được trên thiết kế đã chốt, code không có cách nào đúng — nên nó dừng. Đây **không** phải spec drift (spec lệch với UI, không với code); `spec_drift` của review ở 4c ghi sổ và không dừng.
> - `"need-clarify — {AC}: {TC} đỏ dù code đúng câu chữ"` — `/build` bước 5: AC tự mâu thuẫn. Cùng cách dừng.
>
> **Không còn** `"feature {F} chưa có test-design"`: gate đó đã bỏ (`.docs/026` D2) — phase Build không đọc `test-design.md` nữa. Row contract có cột `TC` rỗng là **bình thường**, không phải blocked, không phải cảnh báo.

Ghi log sau **mỗi** vòng build.

#### 4c. Spawn `/review-integration` ở subagent

**Chỉ chạy khi `n1 = 0`.** Diff dở dang không đại diện cho trạng thái nào; reviewer chấm nó sẽ ra findings ảo về code chưa viết xong.

Spawn một subagent **riêng**. Prompt có **hai dạng**, rẽ theo **dòng `step=review` cuối trong `implement-log.md`** — kể cả dòng của một `## Run` trước:

```bash
grep -E '^- \[[x ]\].*\bstep=review\b' "$LOG" | tail -1
```

| Có dòng đó? | Prompt nguyên văn |
|---|---|
| không | `invoke /review-integration {slug} --auto` |
| có | `invoke /review-integration {slug} --auto --prev-sha={sha}` — `{sha}` là `sha=` của dòng đó |

**Rẽ theo log, không theo bộ đếm `### Phase … Review Findings` của 4d.** Hai con số khác nhau ở ca resume: lượt trước review **sạch** nhưng log chưa đóng ⇒ `plan.md` không có Phase Review nào, mà review **đã từng chạy**. Đếm theo phase thì vòng này tưởng là vòng đầu và mất tham chiếu. Log là nơi duy nhất ghi cả vòng sạch (§`implement-log.md`).

`sha=` không đọc được, hoặc `git cat-file -e` không qua ⇒ spawn dạng **vòng đầu**. Không bịa sha: `--prev-sha` sai làm reviewer tính `git diff` trên một mốc không tồn tại.

Context cấp cho nó: **chỉ** `spec.md` + `tech.md` + diff — cộng, từ vòng thứ hai, `techdebt.md` mà **chính nó tự đọc** theo `--prev-sha` (sổ `spec-debt.md` của feature thì vòng nào nó cũng tự dò trước khi mở mục). **Không** truyền lịch sử build, không truyền output prose của các vòng trước. Reviewer vẫn chấm bằng mắt sạch: nó review code, không review quá trình viết code.

**`--prev-sha` là tham chiếu, KHÔNG thu hẹp diff (029 D5).** Vòng sau vẫn chấm `merge-base..HEAD`. Cái nó mua được: `SG-*` đã ghi không bị nêu lại, item `[ ]` vòng trước được kiểm và tick, điểm ở mục *"Đã cân nhắc, không nêu"* muốn nâng thì phải ghi lý do, và finding trên code chưa đổi từ `prev-sha` phải mang dấu. Không có nó, hai vòng trên cùng một integration ra hai bộ finding khác nhau — vòng 2 nêu thứ vòng 1 đã nhìn mà bỏ qua, nhìn từ ngoài giống build phá.

Diff giữ nguyên hành vi gốc của `/review-integration`: `git diff $(git merge-base HEAD $BASE)...HEAD` — **toàn bộ integration**. Không truyền `--since`, không có cờ thu hẹp về phase.

Return: `{ critical, important, spec_gap, spec_drift, reviewed_sha }`.

**Không đọc prose findings.** Chi tiết findings ở `techdebt.md` (Critical/Important), sổ `spec-debt.md` của feature cạnh `frd.md` (`SG-*` · `SD-*`) và Phase Review của `plan.md`.

**`spec_gap` là thông tin, KHÔNG phải tín hiệu rẽ nhánh (029 D1).** Nó là số `SG-*` mới mở — finding mà reviewer **không neo được** vào `AC-*`/`VR-*`/`FAC-*`/section `tech.md`/`GUARD-*`, tức spec **im lặng**. Code đã đúng với spec approved nên nó **không** mở vòng build và **không** chặn `done`; `/implement` chỉ **ghi nó vào log** (`spec_gap={g}` trên dòng `step=review`) và **in ở Bước 5**. Rẽ nhánh chỉ theo `critical` + `important`.

**`spec_drift` cũng là thông tin, cùng vai với `spec_gap` ([`.docs/036`](../../.docs/036-spec-drift-vao-spec-debt.md) `D0`).** Nó là số `SD-*` mới mở — chỗ code làm khác một `AC-*`/`VR-*`/`FAC-*` **có dấu vết**, tức một trong hai bên sai mà chỉ BA biết bên nào. Không đẻ task (có thể đang sửa code đúng cho khớp requirement sai), **không dừng** (những việc khác của integration vẫn làm xong được trước khi raise lên BA), không chặn `done`. Ghi `spec_drift={d}` trên dòng `step=review`, in ở Bước 5.

Ghi log.

#### 4d. Rẽ nhánh sau review

Đếm số vòng review đã có, **đọc từ `plan.md`**:

```bash
grep -cE '^### Phase [0-9]+: Review Findings' plan.md
```

Neo vào **đúng** tiền tố đó, **không** neo vào `(lần {k})` — plan.md sinh trước quy ước này có heading trần và vẫn phải đếm đúng, nếu không thì resume trên integration cũ tưởng chưa review vòng nào.

| Điều kiện | Làm gì |
|---|---|
| `critical + important = 0` | **xong** → Bước 5 |
| `critical + important > 0`, số vòng `< 3` | quay lại **4a** |
| số vòng `= 3` | **dừng** — trả người |

**Chỉ Critical/Important mới đẻ vòng mới.** Suggestion/Nit/Optional/FYI **không** được phép kéo dài vòng lặp — review luôn tìm được cái gì đó nếu cứ hỏi mãi.

*(Luật vòng lặp: có finding thì **dừng, không tiếp tục `/build`** cho tới khi fix và re-review sạch. Luật này thuộc `/implement` — `/review-integration` chỉ thêm Phase Review rồi trả kết quả, nó không cầm vòng lặp.)*

---

### Bước 5: Kết thúc

Trước khi báo xong, **assert hậu điều kiện** (§Hậu điều kiện). Không đạt ⇒ **không được nói "hoàn thành"**.

Đóng block log bằng dòng `- [x] step=outcome sha={sha} result=done`, rồi in:

```
✅ {slug} — xong.

  Branch:      feat/{slug}  (chưa merge)
  Vòng build:  {n}
  Vòng review: {k} — vòng cuối sạch tại {sha}
  Spec gap:    {g} chưa quyết — .specs/main/feature/{F-XXX}-{slug}/spec-debt.md   ← chỉ in khi g>0
  Spec drift:  {d} chưa quyết — code làm khác AC, chờ BA chọn bên đúng   ← chỉ in khi d>0
  Log:         .specs/integrations/{slug}/implement-log.md

Tiếp theo:
  /spec-new {F-XXX}         — 👤 BA đọc SG-* / SD-*: gap nào lên spec, drift nào sửa requirement hay giữ   ← mỗi feature có nợ một dòng, chỉ khi g>0 hoặc d>0
  /verify-v2 {F-XXX}        — chạy trọn bước ④ Verify (test-exec + ba tầng retrofit + tự sửa bug-code)
  /verify-v1 {F-XXX}        — cùng chuỗi đó nhưng dừng ở bàn giao, không đụng code sản phẩm
  👤 đọc PR rồi merge       — human gate cuối, /implement không merge
```

`{g}` = số `SG-*` **chưa quyết** **thuộc đợt này** trong sổ `spec-debt.md` của các feature ở `features:`: dòng `- [ ]` **không** có con trỏ `→ {slug}` ngay sau số mục (đếm theo vị trí, không theo "dòng có chứa `→`"), và mục có một dòng `**phát hiện:**` chứa `` của `{slug}` `` ([`02-artifacts.md §2.3`](../../02-artifacts.md) — đếm theo đợt). Sổ của feature còn chứa nợ do ④ Verify hay đợt khác thấy; đếm cả sổ là báo nợ của người khác vào lượt này. Tính trên **mọi vòng**, không phải chỉ vòng cuối — gap của vòng 1 mà chưa ai quyết vẫn là nợ.

Dòng `- [ ]` **có** `→ {slug}` là gap **đã lên spec**, đang chờ integration đó xong; nó **không** vào `{g}` (BA không phải quyết lại) mà in riêng khi có:

```
  Spec gap:    2 chưa quyết · 1 đang làm (SG-3 → 006-todo-error-surface)
```

`{d}` đếm **y hệt** trên dòng `- [ ] **SD-`: không `→` là chưa quyết, có `→` là đang làm (in `· 1 đang làm (SD-1 → …)`). Drift còn `[ ]` — cả hai dạng — thì ④ Verify **không** sửa code của ID đó (`/fix-findings` từ chối `spec-debt-mở`); in ra để người merge biết mình đang merge một chỗ lệch đã biết.

`[x]` cho một gap/drift đang làm do **`/archive {slug giải quyết}`** đặt, không phải `/implement` (029 D9). `/implement` dừng trước merge và trước ④ Verify, nên nó không ở vị trí nói "xong".

**Vì sao phải in dù không chặn.** `spec_gap` và `spec_drift` không chặn `done` (029 D1 · 036 D0), nên nếu Bước 5 im thì lượt chạy kết thúc `✅` mang theo một **nợ BA vô hình** sau merge. In ở đây + `/archive` cảnh báo khi còn `[ ]` là hai chỗ duy nhất nó nổi lên.

**Không merge, không mở PR.** Human gate cuối vẫn nằm đúng chỗ: người đọc PR trước khi code vào `main`.

Không tự chạy `/verify-v2` — chỉ gợi ý. Bước ④ có orchestrator riêng ([`skills/verify-v2`](../verify-v2/SKILL.md), đường chính; [`skills/verify-v1`](../verify-v1/SKILL.md) khi không muốn máy chạm code sản phẩm); `/implement` dừng **trước** nó.

---

## Luật dừng

Ba cách một lượt kết thúc. **Hai trong ba là dừng hợp lệ, không phải lỗi.** *(Trước [`.docs/036`](../../.docs/036-spec-drift-vao-spec-debt.md) có ca thứ tư `spec_drift`; nay drift ghi sổ rồi đi tiếp — 4c.)*

| # | Điều kiện | Thông điệp phải nói gì | Log |
|---|---|---|---|
| 1 | review sạch, hậu điều kiện đạt | branch + bước tiếp theo (Bước 5) | `✅ xong` |
| 2 | `n1 = n0` sau retry 1 lần — **hoặc** `/build` trả `blocked: "need-clarify — …"` (4b) | task nào đang tắc (lấy từ `blocked` + task `[ ]` đầu tiên), và rằng chạy lại `/implement` **sẽ tắc y hệt** — cần người | task nào đang tắc (lấy từ `blocked` + task `[ ]` đầu tiên), và rằng chạy lại `/implement` **sẽ tắc y hệt** — cần người | `⏸ dừng hợp lệ — blocked ×2` |
| 3 | tới vòng review thứ 3 | findings còn lại ở `techdebt.md`, review đã 3 vòng chưa sạch ⇒ có gì sai ở tầng plan hoặc spec | `⏸ dừng hợp lệ — k=3` |

Mọi thông điệp dừng phải nói **dừng vì gì** và **bước tiếp theo của người là gì**. Bộ đếm ở ca 3 đọc từ `plan.md` (4d), không nhớ trong đầu — nhờ vậy compaction không reset nó về 0.

---

## `implement-log.md`

Mỗi lượt chạy ghi `.specs/integrations/{slug}/implement-log.md`. Chưa có ⇒ tạo từ `.claude/templates/integrations/implement-log-template.md`.

**Vì sao cần file này.** Có đúng một mắt xích của workflow không kiểm được, và là mắt xích cuối: **review sạch không để lại dấu vết nào.** Có finding thì có Phase Review + section trong `techdebt.md`; sạch thì không ghi gì cả ⇒ **không phân biệt được "review đã chạy và sạch" với "review chưa từng chạy"**. Log này lấp chỗ đó.

Không nhồi vào `techdebt.md`: log phủ **cả workflow** (plan · coverage · từng vòng build · từng vòng review) còn `techdebt.md` chỉ phủ vòng review, và `02-artifacts.md` §3.8 định nghĩa nó là **sổ nợ** — nhồi bản ghi "không có nợ" vào đó là làm loãng một artifact mà cả kit dựa vào định nghĩa của nó.

**Append theo `## Run {n}`, không ghi đè.** `n` = số block `## Run` hiện có + 1.

**Commit `implement-log.md` ở cuối lượt**, cùng commit với sổ `spec-debt.md` của feature mà review vừa ghi (nếu có — `git status --porcelain -- .specs/main/feature/*/spec-debt.md`). Log là bằng chứng của lượt chạy (D22) và sổ là nợ lượt chạy để lại, nên cả hai phải nằm trên branch, không để lửng ở working tree. Việc commit này đẩy `HEAD` vượt `reviewed_sha` — **đúng như thiết kế**: `check-implement-postcondition.sh` đo **net diff** `reviewed_sha..HEAD` và cho qua khi phần chênh **chỉ chạm** `.specs/integrations/{slug}/` và sổ `spec-debt.md` cạnh `frd.md`. Đừng bỏ commit vì sợ vỡ hậu điều kiện; ca đó đã được tính tới.

### Định dạng: **logfmt**, không phải văn xuôi

Mọi dòng là `- [x] key=value key=value …`, khoảng trắng ngăn cách. **Ba luật bắt buộc:**

1. có `step=` thuộc tập đóng — `plan` · `coverage` · `build` · `review` · `finding` · `outcome`
2. có `sha=` — sha **thật**, `git cat-file -e {sha}^{commit}` phải qua
3. value **không chứa khoảng trắng**, trừ `note=` — và `note=` phải là key **cuối** dòng

| `step=` | Dòng đầy đủ |
|---|---|
| `plan` | `- [x] step=plan sha={sha} approved_by=implement` |
| `coverage` | `- [x] step=coverage sha={sha} missing={n}` *(+ `ids=AC-…,VR-…` khi `missing>0`)* |
| `build` | `- [x] step=build sha={sha sau} round={i} from={sha trước} todo_before={n0} todo_after={n1} blocked={none\|yes}` |
| `build` *(bỏ vòng)* | `- [x] step=build sha={sha} round=0 skipped=n0-zero` — ca `n0 = 0` ở 4a |
| `review` | `- [x] step=review sha={reviewed_sha} round={k} critical={c} important={i} spec_gap={g} spec_drift={d}` |
| `finding` | `- [ ] step=finding sha={reviewed_sha} round={k} tasks=T00X` |
| `outcome` | `- [x] step=outcome sha={sha} result=done` **hoặc** `result=stopped reason={blocked\|k3} note={việc người cần làm}` |

**Vì sao không phải văn xuôi.** Hai script đọc file này — `implement_guard.py` ở `Stop` hook và `check-implement-postcondition.sh` trước khi merge. Bản văn xuôi cũ khiến chúng phải `grep` cụm tiếng Việt và `sed` bắt token theo vị trí; hai lượt chạy khác nhau đẻ ra hai cách diễn đạt cùng một sự kiện là parser trượt trong im lặng. `key=value` thì thứ tự field không quan trọng, thêm key mới không vỡ parser cũ, và **sai định dạng thành lỗi cứng** thay vì lệch âm thầm.

Chọn logfmt chứ không phải YAML/JSON vì hook phải chạy được ở máy **không có** PyYAML và **không có** `jq` — luật fail-open (D18f) cấm phụ thuộc thứ có thể vắng. `key=value` parse được bằng `awk` thuần lẫn python stdlib.

**Vì sao mọi dòng phải neo sha.** Không có luật đó thì log chỉ là **model tự khai** — nó bỏ được review thì viết `review ✓` cũng được. Có `sha=` ⇒ mọi dòng **đối chiếu được với `git log` + `todo.md`** mà không cần tin file. Đây là chỗ duy nhất phân biệt log này với một lời hứa, và giờ nó **kiểm được bằng máy**:

```bash
grep -oE 'sha=[0-9a-f]{7,40}' implement-log.md | cut -d= -f2 \
  | while read h; do git cat-file -e "$h^{commit}" 2>/dev/null || echo "BAD $h"; done
```

**Review có finding ⇒ MỞ một item chưa tick:**

```
- [ ] step=finding sha={reviewed_sha} round={k} tasks=T00X
```

Vòng build tiếp theo tick nó. **Review sạch ⇒ không mở item nào.**

Điều này biến luật *"có finding thì phải có action tiếp"* thành **cấu trúc** thay vì quy ước đọc: `[ ]` treo trong Run cuối = còn việc chưa làm, thấy bằng mắt không cần suy luận.

**Mỗi `## Run {n}` phải đóng bằng một dòng `step=outcome`**, ba dạng:

| Dạng | Nghĩa |
|---|---|
| `result=done` | review cuối sạch + hậu điều kiện đạt |
| `result=stopped reason={blocked\|k3}` | ca 2/3 của §Luật dừng. Log cũ còn `reason=spec_drift` (trước 036) — đọc như dừng hợp lệ |
| *(không có dòng `step=outcome`)* | **đứt giữa chừng** — gõ lại `/implement {slug}` |

"Có finding rồi tắc" nhập nhằng hai ca: bị đứt (chạy lại được) vs dừng hợp lệ (đã kết thúc đúng, cần người — chạy lại vô ích). `result=` tách chúng ra, và `reason=` là **tập đóng** nên script rẽ nhánh được theo lý do dừng thay vì suy gián tiếp từ tương quan field.

Chỗ hay của cách mã hoá này: trạng thái "chưa xong" biểu diễn bằng **sự vắng mặt** ⇒ muốn giả phải *viết* thêm, mà agent đang bị ngắt thì không viết được gì. Một field kiểu `status: done` thì model set sai rồi đi ngủ là xong.

Hai bit độc lập đọc được bằng mắt:

| `[ ]` treo | `step=outcome` | Nghĩa |
|---|---|---|
| không | `result=done` | xong |
| có | `result=stopped` | dừng đúng luật, cần người — chạy lại vô ích |
| có | **vắng** | đứt — gõ lại `/implement` |

---

## Hậu điều kiện

Một lượt chỉ được gọi là **hoàn tất** khi **cả ba** đúng:

1. `todo.md` không còn dòng `- [ ]`.
2. `reviewed_sha` của **vòng review cuối** trong log `== git rev-parse --short HEAD`.
3. Vòng review đó ghi **sạch** (`0C/0I`). `spec_gap`/`spec_drift` > 0 **không** làm vòng đó bẩn — chúng là nợ của BA, không phải của dev.

Điều kiện 2 là điều kiện quan trọng nhất và dễ bỏ sót nhất: **`reviewed_sha != HEAD` nghĩa là code đã đổi *sau* lần review cuối** ⇒ workflow chưa hoàn tất, **bất kể log viết gì**.

Assert này chạy ở Bước 5. Nó là **model tự kiểm** nên yếu — tầng thi hành thật là script `.claude/hooks/implement/check-implement-postcondition.sh` chạy **trước merge**, không phụ thuộc model chút nào.

---

## Ràng buộc

- **Một lượt `/implement` mỗi working tree.** `/build` làm `git checkout -b feat/{slug}` bắt buộc, nên hai lượt trên cùng một cây giành nhau branch và index — vỡ từ trước khi có ai kịp có ý kiến. Song song thật ⇒ mỗi lượt một worktree.
- `/implement` **không** sửa `.specs/main/`, trừ sổ `spec-debt.md` của feature do review ghi — ngoại lệ duy nhất của `.specs/main/` ([`01-architecture.md §2.3`](../../01-architecture.md), `.docs/039`). Mọi artifact khác nó chạm đều ephemeral ở integration level (`plan.md`/`todo.md`/`techdebt.md`/`implement-log.md`) + source code. Phát hiện delta cần cập nhật main ⇒ báo và đề xuất integration riêng, **không** tự sửa.
- `/implement` **không** merge, **không** mở PR, **không** chạy `/verify-v1`/`/verify-v2` (bước ④).
- `/implement` **không** đóng `spec_gap` lẫn `spec_drift`. Nó in số gap/drift và gợi `/spec-new {F-XXX}`; quyết định gap nào lên spec, drift nào sửa requirement hay giữ, là của **BA**, và cửa đóng duy nhất là `/spec-new` ([`03-skills.md`](../../03-skills.md)).

---

## Checklist hoàn thành

- [ ] Gate `spec.md` + `tech.md` `approved` đã kiểm trước khi làm gì
- [ ] Đúng **một** câu hỏi trong cả lượt (worktree), và bỏ luôn nếu có `--worktree=`
- [ ] Mọi lần spawn đều mang `--auto` (build còn mang `--worktree=`; review vòng `k≥1` còn mang `--prev-sha=`)
- [ ] Gate sau mỗi build đọc `todo.md` của **đúng cây** đang build
- [ ] Không vòng review nào chạy khi `todo.md` còn `[ ]`
- [ ] Mỗi bước đã ghi một dòng vào `implement-log.md`, mỗi dòng neo sha
- [ ] Run block đóng bằng `step=outcome` đúng dạng
- [ ] Hậu điều kiện assert xong mới báo "hoàn thành"
- [ ] Dòng `step=review` nào cũng có `spec_gap=` + `spec_drift=`; `g>0` hoặc `d>0` ⇒ Bước 5 in dòng tương ứng + gợi `/spec-new {F-XXX}`
- [ ] Kết thúc trên branch `feat/{slug}`, chưa merge
