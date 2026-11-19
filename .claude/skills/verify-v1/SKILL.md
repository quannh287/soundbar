---
name: verify-v1
description: Chạy trọn bước ④ Verify của một feature bằng một lệnh — test-design → test-exec → ba tầng retrofit (validation → functional → e2e), mỗi tầng một subagent, có luật dừng. Kết thúc bằng bàn giao: in pin từng scope, số 🔴 mở, và danh sách việc tách 🤖 / 👤 DEV/BA/QC. Dùng khi feature đã có code + frd.md approved và muốn chạy dài không cần trả lời câu hỏi giữa chừng. KHÔNG có vòng lặp tự sửa — đó là /verify-v2.
---

# Verify v1

## Tổng quan

Orchestrator cho **bước ④ Verify** của Integration Pipeline ([`01-architecture.md`](../../01-architecture.md) §8), đối xứng `/implement` ở ②③. Một lệnh thay cho chuỗi gõ tay:

```
/spec-test-design → /spec-test-exec → /spec-test-retrofit-validation → -functional → -e2e
```

Thứ tự bắt buộc của chuỗi đó hôm nay nằm **trong đầu người gõ**, không ở đâu trong máy: version-gate của cả 3 tầng bắn `⛔` rồi bảo người gõ lại đúng lệnh mà nó vừa nêu tên. Skill này cầm chuỗi, và **tự chèn `/spec-test-exec`** khi gate lệch — chỗ đáng tự động nhất.

**Đọc [`references/verify-core.md`](../../references/verify-core.md) trước.** Nó giữ 4 luật bất di · bộ ba số pin/version · gate cây sạch · Bước 0–3 · sổ gộp `.progress/verify.md` · cách đọc roll-up. File này chỉ thêm: CLI surface · **Bước 4** (hậu điều kiện + exit summary) · **luật dừng**. `/verify-v2` ([`.docs/032`](../../.docs/032-verify-fix-loop.md)) import **cùng** core rồi chèn vòng lặp vào giữa Bước 3 và Bước 4.

**Không có vòng lặp ở v1.** Lượt chạy kết thúc bằng **bàn giao**, kể cả khi còn 🔴 — đỏ ở bước ④ là finding giao người ([test-core §7.4](../../references/retrofit-core.md)), không phải thứ orchestrator được sửa.

## When to Use

- Feature **đã có code** và `frd.md` `approved`, muốn dựng lưới test neo requirement + bộ report trong một lượt.
- Vừa chạy xong `/implement {slug}` và muốn verify feature mà integration đó chạm.
- Lượt trước bị ngắt giữa chuỗi — gõ lại chính lệnh này là tiếp đúng chỗ.

## When NOT to Use

- Chưa có `frd.md` → author trước (`/spec-frd` hoặc [brownfield](../../04-brownfield.md)). Retrofit không chạy trên code trần.
- Muốn đọc từng finding rồi tự quyết giữa các tầng → gõ tay từng skill con.
- Muốn agent **tự sửa** việc `🤖` rồi chạy lại → `/verify-v2`.
- Chỉ re-run **một** tầng sau khi dựng harness → `--scope=` (dưới), hoặc gõ thẳng skill tầng đó.

## Cờ trong ARGUMENT

```
/verify-v1 {F-XXX | slug-integration} [--scope=validation,functional,e2e] [--auto]
```

| Cờ / arg | Nghĩa | Vắng thì |
|---|---|---|
| `F-XXX` | một feature | — |
| `slug-integration` | đọc `features:` ở frontmatter `spec.md` → chạy **tuần tự** từng `F-XXX`, mỗi feature một lượt trọn Bước 0–4 | — |
| *(không arg)* | liệt kê feature có `test-design.md` + pin từng scope, cho chọn | — |
| `--scope=` | tập tầng chạy; thứ tự **luôn** `validation → functional → e2e` bất kể thứ tự gõ | cả 3 tầng |
| `--auto` | trả `yes` cho Check 2 của `/spec-test-exec` — prompt duy nhất còn lại của chuỗi | hỏi đúng ô đó |

`--scope=nfr` hoặc `--scope=dm` ⇒ **lỗi, dừng**:

> ⛔ `nfr`/`dm` **chưa có skill nào ghi result**, pin của chúng ở lại `0`. Nhận scope đó là hứa một thứ không tồn tại.

Re-run một tầng là ca thật (dựng harness xong rồi chạy lại `e2e` — [`06-testing.md §11`](../../06-testing.md)), nên `--scope=` tồn tại; nhưng nó chỉ nhận 3 scope **có writer**.

---

## Quy trình

**Bước 0–3 ở [`references/verify-core.md §3`](../../references/verify-core.md)** — resolve arg + gate `frd` + probe harness + refresh sổ · `test-design` nếu thiếu · `/spec-test-exec --auto` khi ① lệch hoặc thiếu file test-exec · ba tầng, mỗi tầng một subagent, gate cây sạch so với ảnh chụp Bước 0.

### Bước 4 — hậu điều kiện rồi exit summary

**4a. Assert ba mệnh đề.** Một lượt chỉ được gọi là **hoàn tất** khi cả ba đúng:

1. Mọi scope **có TC và có writer** (`validation` · `functional` · `e2e`) đạt `pin == version`.
2. **Không có thay đổi mới** so với ảnh chụp Bước 0 ở phạm vi [core §2](../../references/verify-core.md). Cây bẩn từ trước lượt chạy (WIP của dev) **không** làm mệnh đề này fail — nó đã được in ở Bước 0; `.specs/tests/**` cũng không vào mệnh đề này.
3. `test-report.md` tồn tại và `derived_from.{scope}.test_exec_version` khớp pin đọc được ở từng file scope.

`nfr`/`dm` **không** vào mệnh đề 1 — pin `0` của chúng là trạng thái đúng cho tới khi có writer.

Mệnh đề nào không đạt ⇒ đi vào luật dừng, **không** in `✅`.

**4b. Đọc roll-up và in đúng một khối** ([core §5](../../references/verify-core.md) nói đọc field nào):

```
✅ F-002 — verify xong.

  Scope:   validation v1 · functional v1 · e2e v1 · nfr v0 (chưa có writer) · dm v0 (chưa có writer)
  TC:      64 — 🟢 58 · 🔴 0 · ⏭ 3 · — 3
  🔴 mở:   0
  Report:  .specs/tests/F-002-todo-management/test-report.md

Việc còn lại — 0 🤖 · 3 👤
  👤 BA   A-VAL-1  chốt `mo_ta` vượt 2000 ký tự: cắt bớt hay từ chối lưu
  👤 BA   A-FUN-1  chốt hai nhánh `Flow 1` thành AC thật hay bỏ khỏi test-design
  👤 BA   A-E2E-1  chốt `FAC-F002-002`: mở rộng sang ≥2 story hay gộp về functional
```

- Cột `Việc` trích **nguyên văn** từ §3 `Action Items` của roll-up (vốn đã là bản trích nguyên văn §5 của từng file scope — 030 D21). Không viết lại, không rút gọn.
- Sắp `🤖` trước `👤`; trong `👤` giữ thứ tự của roll-up.
- Còn 🔴 mà ba mệnh đề đạt ⇒ **vẫn** `✅`. Dòng `🔴 mở` và danh sách việc là chỗ nó hiện ra.
- Dòng `Scope:` **chỉ in scope có TC** — ví dụ trên là `F-002` (có cả `NFR-*` và `DM-*`); feature không có `FAC-*` thì dòng đó **không có** `e2e`, không phải `e2e v0`.
- Nhánh slug: in một khối / feature, rồi một dòng tổng cuối cùng (`{n} feature · {m} 🤖 · {k} 👤`). Dòng tổng đếm **việc đang tồn đọng**, không phải việc lượt này vừa tìm ra — feature đã current vẫn góp việc cũ vào đó.

## Luật dừng

Sáu ca. Ca 2–6 in `⏸ dừng hợp lệ — {lý do}` và **nói bước tiếp theo của người là gì**; không ca nào im lặng, không ca nào dừng mà không nêu tên thứ đã chặn.

| # | Điều kiện | Thông điệp phải nói gì | Bed nghiệm thu |
|---|---|---|---|
| 1 | ba mệnh đề 4a đạt | `✅` + khối exit summary — **kể cả khi còn 🔴** | `F-002` · `F-004` lượt hai |
| 2 | `frd.md` không có | author `frd` trước (`/spec-frd` hoặc brownfield) — retrofit không chạy trên code trần | `verify-frd-thieu.sh` |
| 3 | tầng con trả `blocked` | **nguyên văn** lý do của nó, không viết lại | `verify-version-lech.sh` (gọi thẳng tầng con) |
| 4 | thay đổi **mới** so với ảnh chụp Bước 0 (phạm vi core §2) sau một tầng — **hoặc** bẩn ngay Bước 0 kèm dấu vết tầng chết giữa scope | tầng nào, **file nào mới** đổi, và rằng mutation của sanity-red có thể chưa revert ⇒ `git diff` trước khi chạy tiếp. Phân loại theo hình dạng diff (core §2) | tiêm file rác / thêm một `data-testid` chưa commit |
| 5 | version-gate còn lệch **sau** Bước 2 | scope nào lệch — `/spec-test-exec` đã chạy mà không reconcile được là **lỗi thật**, không phải ca thường | `verify-version-lech.sh` (đẩy `versions` sau Bước 2) |
| 6 | tầng tắc harness | tầng nào, `BLK-*` nào, cần hạ tầng gì — `👤 DEV`, và rằng `⏭ harness` là **kết thúc hợp lệ** | `verify-harness-thieu.sh` |

**Ca 3 và ca 5 là hai ca khác nhau trên cùng một trạng thái**, phân biệt bằng thời điểm: version-gate lệch **trước** khi gọi thì Bước 2 reconcile xong và tầng chạy bình thường (tầng con chỉ trả `blocked` khi bị gọi thẳng); lệch **sau** Bước 2 thì ca 5 bắn. Ca 3 giữ luật của `/implement`: `blocked` của con là câu của con.

**Ca 4 có ba kết luận, không phải một.** File mới đổi là test code của **đúng tầng vừa chạy** ⇒ *tầng chưa commit output của nó* (core §2); chỉ `selector-contract.md` + hunk thêm `data-testid=` ⇒ *backfill dở*; hunk khác trên file sản phẩm ⇒ *mutation chưa revert*. Đổ cả ba vào một câu là đẩy người đi debug sai chỗ.

**Ca 4 không phải "cây bẩn thì dừng cho chắc".** Nó tồn tại để bắt **mutation của sanity-red nằm lại trên code sản phẩm**. Artifact mà tầng được phép ghi, và sổ mà orchestrator được phép ghi, đều **không** nằm trong vùng gate đọc.

Ví dụ thông điệp ca 4:

```
⏸ dừng hợp lệ — cây làm việc bẩn sau tầng `functional`, không spawn tầng `e2e`.

  apps/api/src/usecase/tag.ts   hunk sửa điều kiện — KHÔNG phải thêm data-testid
  → nghi mutation của sanity-red chưa revert. Chạy `git diff apps/api/src/usecase/tag.ts`
    rồi hoàn nguyên trước khi gõ lại `/verify-v1 F-004`.
```

## Hậu điều kiện

- `pin == version` ở mọi scope có TC và có writer (mệnh đề 1).
- `git status --porcelain -- {src} {test}` không có dòng nào **mới** so với ảnh chụp Bước 0.
- `test-report.md` khớp pin từng file scope.
- `.progress/verify.md` đã refresh ở trạng thái cuối lượt.
- **Không** file nào ngoài `.progress/verify.md` bị skill này ghi.

## Ràng buộc

- **KHÔNG ghi:** code sản phẩm · `test-report*` (gồm roll-up) · `frd.md`/`test-design.md` · `test-exec-*`. Chỉ đọc.
- **KHÔNG tự dựng harness.** Probe chỉ **in**.
- **KHÔNG nâng `👤` thành `🤖`**, không tự chạy `/spec-new` hay skill cascade nào.
- **KHÔNG sửa test cho xanh**, không sửa code cho xanh — v1 không sửa gì cả.
- **KHÔNG bỏ qua thứ tự tầng**, kể cả khi `--scope=` gõ ngược.
- **KHÔNG đọc sổ để rẽ nhánh** — pin và §4 `Results` mới được (core §4 luật 2).

## Checklist hoàn thành

- [ ] Bước 0: arg resolve xong · `frd.md` có · harness đã probe và in tầng sẽ tắc · sổ đã refresh
- [ ] Bước 1–2: `test-design.md` có · version-gate ① khớp ở mọi scope — nếu ① từng lệch thì `/spec-test-exec --auto` đã chạy, ① khớp sẵn thì đã in `exec current` và **không** gọi
- [ ] Bước 3: mọi scope `pin < version` đã dispatch, mỗi tầng một subagent, gate cây sạch chạy **trước và sau** từng tầng
- [ ] Bước 4: ba mệnh đề 4a đã assert · exit summary in đủ 4 dòng đầu + danh sách việc tách `🤖`/`👤`
- [ ] `.progress/verify.md` refresh lần cuối, dòng `- [ ]` còn lại (nếu có) trỏ đúng chỗ dở
- [ ] `git status --porcelain -- {src} {test}` không có dòng **mới** so với ảnh chụp Bước 0 — nếu có, đã dừng ở ca 4 chứ không in `✅`
- [ ] Không file nào ngoài `.progress/verify.md` bị lượt này ghi (`git status` xác nhận)
