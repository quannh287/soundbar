# Retrofit Core — đường code có trước, test viết sau

> **Đọc [`test-core.md`](test-core.md) trước.** Nó giữ phần dùng chung với họ skill outer: 4 luật bất di · điền test-exec (§2) · tier vocabulary (§2a) · reconcile + anchor 2 chiều (§2b) · seam theo tầng (§3) · prune (§6) · ghi report + roll-up (§7 · §7b). File này **không chép lại** phần đó.
>
> Shared core cho **cả 3 skill tầng retrofit** (tên đồng nhất với scope test-exec): `/spec-test-retrofit-validation` (VR), `/spec-test-retrofit-functional` (Story AC), `/spec-test-retrofit-e2e` (FAC). Mỗi skill tầng đọc `test-core.md` + file này rồi chỉ bổ sung lớp *"chọn seam + viết test"* đặc thù tầng của nó. Định nghĩa contract đầy đủ ở [`.docs/013`](../.docs/013-retrofit-implementation-plan.md) §2–§4.

**Retrofit là gì:** feature cũ đã implement từ `frd.md` nhưng **chưa có acceptance/validation test**. Retrofit = viết test **sau** code, **giá trị đúng derive từ frd (không đọc code)**, neo chặt VR/AC/FAC ID, coi test đỏ là **finding** (bug-code hoặc spec-drift — một nghĩa duy nhất, [`05-concepts.md §14`](../05-concepts.md)), **không sửa test cho xanh**.

**Số section giữ nguyên số cũ** (nên có chỗ nhảy số: không có §0, §2, §2a, §2b, §3, §6, §7) — mọi trích chéo rải khắp repo vẫn trỏ đúng chỗ. Section thiếu ở đây thì ở [`test-core.md`](test-core.md).

---

## 1. Vòng lặp lõi

Cả 3 tầng chạy **cùng một vòng lặp**; chỉ khác ở **Bước 2–3** (chọn seam + viết test) — đó là phần skill tầng tự lo. Một lượt chạy scope chia làm **hai quét**: quét A đọc code cho hết TC mà không mutate gì, quét B trả chi phí mutate-revert theo từng cụm.

```
Bước 0  Xác định feature + dựng bộ test-exec (qua /spec-test-exec) → có test-exec-{scope}.md
        (khung, ô wiring trống) + test-report-{scope}.md (khung + legend, Results rỗng, pin 0)
        + roll-up test-report.md ở .specs/tests/{F}/.
        Skill tầng CHỈ ghi test-report-{scope}.md của scope mình — không đọc, không ghi file
        scope khác. Không có luật nào phải canh để khỏi xoá kết quả tầng trước: tầng khác nằm
        ở FILE KHÁC. Commit sau mỗi tầng (git = history duy nhất, 015 §3B).
Bước 0b GATE version + pin (§1b, 016). VERSION-GATE: test-design.versions.{scope} > test-exec.test_design_version
        → STOP, báo chạy /spec-test-exec trước (retrofit KHÔNG tự reconcile wiring — D9). PIN-GATE:
        test-report-{scope}.test_exec_version (một số) == test-exec.version → scope current, KHÔNG làm gì. Tụt →
        chạy lại CẢ scope (Bước 1-7), cuối cùng nâng pin (§7).
Bước 1  Lọc TC của tầng từ test-design (VR → Validation TC · AC → Functional TC · FAC → E2E TC).
        Mỗi TC neo đúng 1 ID (VR-F*/AC-F*/FAC-F*). Phân loại NEW/MODIFIED/UNCHANGED so với lần chạy trước (§1b).
Bước 2  QUÉT A — [ĐẶC THÙ TẦNG] đọc code MỘT LƯỢT cho HẾT TC của scope, KHÔNG mutate gì:
          a. Với mỗi TC: xác định seam (§skill tầng) → điền layer + Test File + assert
             + testid (nếu có) vào test-exec. Giá trị đúng lấy từ spec (luật 1).
          b. TC KHÔNG viết được → phân loại NGAY theo cây §7.5 (refactor/harness/need-clarify/no-seam)
             → ghi row ⏭ vào §4 Results NGAY + mở BLK-* ở §3 (trừ no-seam, §7.3).
          c. Ghi test-exec MỘT LẦN ở cuối quét A — trước chu kỳ mutate đầu tiên (§7.0).
Bước 3  QUÉT B — theo từng CỤM (nhóm TC chia nhau một chu kỳ mutate-revert, §4):
          a. RECONCILE với test có sẵn (§2b) TRƯỚC khi viết mới: có test cũ ở seam đó
             → anchor TC ID + trỏ Test File vào nó; test cũ mâu thuẫn spec → finding, KHÔNG viết trùng.
          b. Chưa có → viết test code implement đúng test-exec đã điền (shape theo tầng).
          c. Chạy cụm lên code cũ → SANITY-RED (§4): mutate MỘT lần → cụm phải đỏ → REVERT → verify-green.
Bước 4  Ghi row §4 Results của CẢ CỤM vừa xong — result + `sanity-red`/`mutation`/`reverted`.
        NGAY SAU revert-verify, KHÔNG trước (§7.0), và không dồn tới cuối scope.
Bước 5  Nếu đỏ → classify finding (§5) → ghi test-report-{scope} (§2 Findings). KHÔNG sửa test cho xanh.
Bước 6  PRUNE (§6) — bỏ TC/hành vi không neo ID nào (phần cần người xử → §5 Next Actions).
Bước 7  Dựng lại trọn test-report-{scope}.md (§7: Summary/Findings/Blockers/Results/Next Actions),
        nâng pin, rồi DỰNG LẠI roll-up test-report.md (§7b) → report user.
```

Điểm mấu chốt: **Bước 2 là nơi requirement gặp code** — ghép "cái gì đúng" (spec) với "móc vào đâu" (code) thành spec-test hoàn chỉnh, rồi mới viết test code. `/spec-test-exec` mù code nên chỉ dựng khung rỗng; retrofit skill là chỗ **duy nhất** được đọc code sản phẩm.

**Vì sao tách hai quét thay vì chạy trọn vòng cho từng TC:** ba lý do đo được.

1. **`⏭ harness` biết ở phút 0 khác biết ở phút 40.** Quét A phân loại **hết** TC không viết được trước khi trả tiền cho chu kỳ mutate nào — người đọc report thấy ngay việc `👤 DEV` phải làm.
2. **Quét A là mốc bền duy nhất của phần đọc code.** Ghi test-exec một lần ở cuối quét A ⇒ bị kill giữa quét B thì phần chọn seam **không mất**; ghi rải theo từng TC thì kill giữa chừng mất trọn phán đoán chưa ghi (§7.0).
3. **Cụm chỉ biết được SAU khi đọc code.** Nhóm nào chia nhau một chu kỳ mutate-revert lộ ra ở ô `mutation` khi row đã có — nên quét B phải đứng sau quét A, không xen kẽ được.

Quét A **không** mutate gì: hết quét A thì mọi TC đã có wiring trong test-exec và mọi TC `⏭` đã có row + `BLK`, mà chưa một chu kỳ mutate-revert nào chạy.

---


---

## 1b. Version-gate + pin-gate + scope re-run (016)

Retrofit **sở hữu MỘT scope** và **làm việc ở cấp-scope** (đơn vị của version/staleness/re-run là scope, không per-TC). Hai cổng chạy trước vòng lặp:

**① VERSION-GATE — test-exec còn khớp test-design không?**
So `test-design.versions.{scope}` (frontmatter) vs `test-exec-{scope}.test_design_version`.
- **Bằng** → test-exec current với test-design, đi tiếp.
- **test-design > test-exec** → section test-design đã đổi mà wiring test-exec chưa reconcile → **STOP**, báo:
  > ⛔ test-design.{scope} v{N} > test-exec v{M}. Chạy `/spec-test-exec {F-XXX}` trước để reconcile wiring, rồi chạy lại retrofit.

  Retrofit **KHÔNG** tự áp delta wiring — đó là việc DUY NHẤT của `/spec-test-exec` (016 D9). Vi phạm = hai nơi cùng sửa wiring → drift.

  **STOP vì version-gate vẫn ghi sổ:** dựng lại `.progress/{scope}.md` với việc lớn ở dạng `⛔ /spec-test-retrofit-{scope}   chạy /spec-test-exec   ({lý do})` rồi dừng — việc nhỏ giữ nguyên (chúng derive từ `test-report-{scope}.md` §4, file đó không đổi). **KHÔNG** đụng `test-exec-*`, `test-report-*`, roll-up, hay sổ của scope khác. Không ghi sổ thì dòng `⛔` ở template + `verify-core` §4 là chữ chết: nó chỉ xuất hiện được ở đúng lượt gate lệch.

**② PIN-GATE — result đã phản ánh version test-exec hiện tại chưa?**
So `test-report-{scope}.test_exec_version` (pin — **một số**, 030 D2) vs `test-exec-{scope}.version`.
- **Bằng** → scope đã chạy đúng version hiện tại → **KHÔNG làm gì** (khỏi tốn công).
- **Pin < version** (gồm pin=0 fresh) → scope **stale** → chạy lại **CẢ scope** (Bước 1-7).

**Scope re-run — phân loại TC để chỉ trả chi phí đắt cho phần đổi (016 D11):**

| TC trong scope | Xử lý | Chi phí |
|---|---|---|
| **NEW** (mới thêm) | full-loop: điền wiring → viết test → **sanity-red mới** → classify | đắt (sanity-red) |
| **MODIFIED** (ID giữ, nội dung đổi) | full-loop: rewrite test → **sanity-red mới** → classify. Nếu dòng đang là Finding → **re-evaluate verdict** (verdict cũ có thể hết đúng khi TC đổi) | đắt (sanity-red) |
| **UNCHANGED** | **chỉ re-execute** test đã có → record result. **Inherit** sanity-red (mutation/reverted) + Finding cũ (code chưa đổi → chứng minh lại là phí) — kế thừa từ bản trước **của chính file scope này**, không xuyên scope (§7) | rẻ (chạy test) |

- Phân loại NEW/MODIFIED/UNCHANGED = so TC hiện tại của test-design với dòng §4 Results đã có trong `test-report-{scope}.md` (lần chạy trước). TC có trong report + nội dung không đổi = UNCHANGED.
- "Nội dung đổi" xét theo assert/Expected/Covers của TC (đọc test-design vs test-exec đã reconcile) — không cần hash, so live.

**③ Nâng pin (cuối, sau khi cả scope xong — §7):** set `test-report-{scope}.test_exec_version` = `test-exec-{scope}.version`. Chỉ skill này nâng pin (016 D7); nâng = "result giờ phản ánh đúng version test-exec này".

---

**Gate hiện ra trong sổ tiến độ như thế nào.** Version-gate lệch **không** phải một dòng `[ ]` đang chờ — nó là **tiền đề chưa đủ**, và người đọc cần biết gõ lệnh nào:

| Tiền đề | Đo bằng | Sổ in gì |
|---|---|---|
| tầng ← `/spec-test-exec` | `test-exec-{scope}.test_design_version` == `test-design.versions.{scope}` | lệch ⇒ việc lớn **không** phải `[ ]` mà là `⛔ chạy /spec-test-exec` |
| `/spec-test-exec` ← `/spec-test-design` | `versions` đọc được ở `test-design.md` | đọc được ⇒ không in gì |
| `e2e` ← `functional` | **pin của tầng functional** (`selector-contract.md` **không** mang dấu vết "đã backfill hay chưa" — `template_version` chỉ là detector hình dạng, 024 D18) | in kèm `⟨functional pin {p}/{v} — contract chưa backfill⟩` |

Dòng in kèm là **thông tin cho người**, không phải cổng: quyết định chạy hay không **vẫn đọc pin/version**, không đọc sổ (§1b).

---


---

## 1c. Refresh mode — cập nhật report chủ động (`--mode`)

Ngoài **đường tự động** (default no-arg: gated + phân loại NEW/MODIFIED/UNCHANGED + nâng pin, §1b), skill nhận tham số `--mode` để **chủ động refresh report của scope** — mặc định **hết TC** của scope (KHÔNG có `--select`). Đây là **maintenance _within-version_**, KHÔNG phải version-transition. Hai đường tách bạch:

| Đường | Kích | Phạm vi | Pin | Dùng khi |
|---|---|---|---|---|
| **default (no-arg)** | gated tự động | scope, phân loại per-TC | **bump pin** | TC mới / đổi nội dung (version bump) — §1b |
| **`--mode`** | thủ công | all-TC-in-scope | **pin-neutral** | code refactor / muốn re-prove / re-run **trong cùng version** |

Cả hai đường đều **dựng lại trọn** `test-report-{scope}.md` rồi sinh lại roll-up (§7/§7b) — `--mode` chỉ quyết định **cột nào được ghi mới** thay vì kế thừa.

**Ba mode — lồng nhau (`execute` ⊂ `sanity` ⊂ `full`)**, phân theo *cột report nào được ghi mới*:

| Mode | Ghi mới cột | Không đụng | Ý nghĩa |
|---|---|---|---|
| `execute` | `Result` | mọi cột khác (inherit) | chạy lại test → cập nhật pass/fail |
| `sanity` | `sanity-red` · `mutation` · `reverted` (+ `Result` kèm) + **verify `Tier`** | giá trị `Tier`, cột wiring | mutate lại seam đã ghi → chứng minh test còn bám code; drift → **flag**, KHÔNG rewrite |
| `full` | **mọi cột** (re-wire `Tier`/`Covers`/`Action`/`Note` + sanity + execute) | — | distrust-all: re-derive + re-prove toàn bộ |

`execute` ⊂ `sanity`: sanity vốn phải chạy test (revert→🟢 = `Result` tươi). `sanity` ⊂ `full`: full thêm bước đọc-code re-wire.

**Tier = DECIDE + PROVE (hai bước, hai mode):**
- **DECIDE** (chọn giá trị Tier bằng *đọc code*) → chỉ `full`. `Tier` có **nguồn-ghi DUY NHẤT = `full`**.
- **PROVE** (mutate seam → test flip 🔴) → `sanity`. Sanity **verify + flag** Tier nhưng KHÔNG rewrite (biết "sai" nhưng không biết "đúng là gì" → cần đọc code = full).
- `execute` **tier-agnostic**: chỉ chạy harness đang có, không kiểm seam.

**TC vừa chuyển 🔴 → 🟢 thì `sanity` phải ĐÚC điểm mutate mới**, không có seam cũ để mutate lại: TC đang đỏ có `mutation` = `—`. Đúc trong seam mà cột `Tier` đang chỉ, rồi mutate → phải flip 🔴 → revert → verify green, ghi `sanity-red = proven-red`. Đây là ca **luôn** xảy ra sau một lượt `/fix-findings` đóng finding, tức chính lý do vòng lặp chọn `sanity` thay `execute` ([032](../.docs/032-verify-fix-loop.md) `D5`). Giữ nguyên `n/a` là để một TC được đếm pass mà **chưa từng có bằng chứng nó biết đỏ** — câu `n/a` cũ (*"đỏ sẵn nên không cần mutate"*) mô tả code lúc còn hỏng, hết đúng ngay khi code được sửa.

**`full` reuse gì:** KHÔNG reuse verdict/result cũ — regenerate tươi hết (`inherited` → ép thử nâng `proven-red`; `red-first` **giữ nguyên**, không hạ; finding → re-evaluate verdict). CHỈ reuse **seam cũ (cột `mutation`) như hypothesis/recipe**, theo cơ chế **verify-first**: mutate seam cũ → flip? **CÓ** = wiring reused, rẻ ≈ `sanity`; **KHÔNG** = đọc code re-derive seam + rewrite `Tier` (đắt). Chi phí `full` tỉ lệ **mức code đã trôi**, không phải #TC. Giữ **batch-per-rule** (§4).

**Guardrails `--mode`:**
1. **Pin-neutral** — `--mode` KHÔNG bump/đụng pin (bump pin là việc của default gated run).
2. **Yêu cầu scope current (`pin == version`)** — stale (`pin < version`: có TC mới/đổi chưa hấp thụ) → **TỪ CHỐI**, báo chạy default gated run trước. `--mode` chỉ bypass hành vi *"pin==version → skip"* của default (để re-prove dù default no-op), **KHÔNG** bypass staleness. Lý do: `--mode` pin-neutral + không classify NEW → dùng nó hút TC mới sẽ tạo **pin-inconsistency** (report có TC mới nhưng pin cũ).
3. **Version-gate vẫn enforce** — `test-design.{scope} > test-exec` → STOP báo `/spec-test-exec` (không refresh trên wiring cũ).
4. **Chỉ `full` ghi cột wiring** (`Tier`/`Covers`/`Action`/`Note`) → Tier một nguồn-ghi. `execute`/`sanity` thấy nghi tier/seam trôi → **ghi finding**, KHÔNG tự sửa.
   **Một ngoại lệ hẹp cho `Note`:** `Note` trỏ tới một `FIND-*` **không còn ở §2** thì `execute`/`sanity` **được** gỡ đúng tham chiếu đó (về `—`, hoặc giữ phần câu còn đúng). Đây không phải derive thông tin mới — nó xoá một con trỏ chứng minh được là mồ côi, và §7.2 đòi report đọc-hiểu-được. Ngoài ca đó, `Note` vẫn kế thừa.
   **Ngoại lệ thứ hai, cho `Verdict` của finding (036 `D9` · 037 `D14`):** verdict mà §5 tra được từ `spec-debt.md` (`SD` mở ⇒ `spec-drift`, `giữ spec` ⇒ `bug-code`) **được** ghi mới ở mọi mode, kéo theo `Loại`/`PIC` của dòng §5; cùng lý do, dòng `**phát hiện:**` thêm vào mục đã có và dòng việc của phép đối chiếu ngược cũng được ghi ở mọi mode. **Mở** dòng `SD` mới thì không — đó là phán, chỉ default/`full`. Cùng lý do: đó là tra một quyết định đã ghi, không phải phán đoán mới — và đây là đường duy nhất để quyết định *giữ spec* của BA tới được `/fix-findings` mà không phải chạy `full`. Lý do có ngoại lệ: 2026-09-10 hai subagent **độc lập** đều từ chối giữ tham chiếu chết dù luật lúc đó bảo giữ — một luật mà không lượt nào tuân là luật sai chỗ, không phải người chạy sai.
5. **Chỉ ghi mới cột của mode** — cột ngoài mode **kế thừa** từ bản trước của chính file scope này (§7); **tính lại** §1 Summary/Coverage + dòng `**Mục:**` từ §4, rồi dựng lại roll-up (§7b).
6. **Revert-verify bắt buộc** cho `sanity`/`full` (§4); **không cửa hậu green** — refresh evidence, KHÔNG chỉnh verdict tay.
7. **`date` của file scope ĐƯỢC refresh** (frontmatter + dòng header), kể cả khi mọi cột §4 kế thừa nguyên văn. `date` trả lời *"lần cuối bằng chứng này được đo lại là khi nào"* — mà `execute` **có** chạy lại test thật, nên giữ ngày cũ là report nói dối về thời điểm chấm. Hệ quả: một lượt `--mode execute` trên scope đã xanh để lại **đúng một** dấu vết là `date` — đó là cách duy nhất biết nó đã chạy. Đo được 2026-09-10 trên `F-002` (032 `P4`): diff của cả lượt là 2 dòng `date` ở file scope + 3 dòng `date` ở roll-up, không cột nào của §4 đổi. Pin thì **không** — guardrail 1.

**Absorb TC mới KHÔNG phải việc của `--mode`** (đó là version-transition, xem §1b): `test-design` thêm TC → `/spec-test-exec` re-derive wiring (bump `version`) → **default gated run** (NEW = full-loop trả sanity-red đúng chỗ; UNCHANGED = re-execute inherit) → bump pin. TC `need-clarify` sau khi đã clarify (code/test-design không đổi) = **MODIFIED wiring** → đi qua `full`, KHÔNG đẻ mode mới.

---


---

## 4. Guided sanity-red (tự-áp + bắt buộc revert-verify)

Test viết sau code → phải chứng minh test **biết đỏ** trước khi tin cái xanh. Dùng **guided mutation nhẹ** (KHÔNG mutation-tool như Stryker/mutmut ở giai đoạn này).

**Quy trình mỗi TC (non-blocking, nhưng revert-verify bắt buộc):**

```
1. Agent tự chọn điểm mutate = tắt/đảo đúng cái check mà TC này bảo vệ
   (vd VR: tắt rule `required`; AC: cho handler trả cứng giá trị sai; FAC: phá 1 story member).
2. Áp mutation vào code sản phẩm (ghi rõ file:dòng + nội dung tắt gì).
3. Chạy test → PHẢI thấy nó flip 🔴 (negative/assert fail đúng chỗ).
      - Không flip đỏ → test KHÔNG thực sự kiểm cái nó tuyên bố → sửa test (đây là test-error), lặp lại.
4. REVERT mutation (bắt buộc, sạch) → chạy lại → verify code trở lại 🟢 như trước mutate.
      - verify-green FAIL (revert không sạch) → STOP TOÀN BỘ, báo user (code đang bẩn), KHÔNG tiếp tục.
      - **Harness có BUILD ARTIFACT (mobile/desktop/WASM): revert source là CHƯA đủ — phải REBUILD + cài lại**
        trước lượt verify-green. Revert `lib/` mà vẫn chạy APK cũ = verify binary đã mutate: đỏ, và người ta
        đi tìm bug trong code đã sạch. "Source sạch ⇒ binary sạch" là suy luận SAI ở mọi harness cần build.
5. Ghi bằng chứng vào **§4 Results** của `test-report-{scope}.md`: `sanity-red` = ✅ · `mutation` = file+thay-đổi đã dùng (reproduce được, đúng khuôn §7.1) · `reverted` = ✅. KHÔNG có section Ledger riêng — bằng chứng nằm ngay dòng TC.
```

**Ràng buộc:**
- **Chi phí sanity-red KHÔNG đồng nhất giữa các tầng — batch mạnh hơn ở tầng đắt.** validation/functional chạy in-process (vài giây/chu kỳ). Tầng e2e có build artifact thì mỗi chu kỳ = 2 lần build + cài + chạy (đo thật: ~6 phút/TC trên mobile). Ở tầng đó, **một mutation chứng minh cả journey THAY THẾ mutation-per-TC** (không làm thêm), và các TC dùng chung một seam gom vào **một** chu kỳ. Áp per-TC ở tầng đắt là thuế thời gian không thêm thông tin.
- **Batch theo rule khi feature lớn:** một mutation tắt 1 rule thường làm đỏ **cả cụm negative TC của cùng VR/rule** → 1 chu kỳ mutate-revert chứng minh proven-red cho cả cụm (không lặp per-TC). Ghi cột `mutation` ở từng dòng TC của §4 (cùng file+thay-đổi lặp lại cho cả cụm) nhưng share một lần mutate. Giảm số lần sửa/revert code sản phẩm từ ~#TC xuống ~#rule. (Chi phí thật của retrofit là round-trip sửa/revert code sản phẩm, KHÔNG phải tốc độ chạy test.)
- **Một chu kỳ sanity-red = MỘT lệnh, không phải bốn.** Hình dạng đúng — bước đỏ **phải** được bọc, vì nó cố ý exit non-zero:

  ```bash
  mutate && { chạy_hẹp || true; } && revert && chạy_hẹp
  ```

  Nối `&&` thẳng qua bước đỏ thì chuỗi dừng **trước** `revert` và để repo bẩn — đúng hậu quả luật này muốn tránh (đo được 2026-09-10).

  **`chạy_hẹp` là tập TC của cụm, KHÔNG phải cả file test** (`-t 'TC-F004-(009|010)'`). Ở retrofit, file test hầu như luôn có sẵn TC đỏ vì finding — chạy cả file thì bước 2 không phân biệt được *đỏ vì mutation* với *đỏ vì bug có sẵn*, và bước 4 verify-green **không bao giờ xanh**. Verify-green cũng đọc **đúng tập TC đó**. Số đo 2026-09-10 trên `F-004`: một tầng tiêu ~15 giây cho **mỗi lần gọi tool** (66 call/16.5′ · 80 call/20.7′ · 48 call/11′), nên 13 chu kỳ tách thành 4 bước = ~39 round-trip thừa ≈ 10 phút. Chốt hạ **một** lượt full suite ở cuối scope để bắt hồi quy — chạy hẹp trong chu kỳ không thấy được test của feature khác vỡ.
- Mutation **luôn** phải được revert trước khi sang TC kế. Không để lại code bị phá.
- **Ghi row §4 của TC ngay sau bước 4** (revert + verify-green xong), không dồn tới cuối scope — §7.0. Ghi sớm hơn bước 4 là ghi "xanh" cho code còn mang mutation.
- Minh bạch: mọi mutation ghi vào cột `mutation` (§4 Results) để user review sau (không hỏi confirm từng cái — an toàn dựa vào revert-verify, không dựa vào duyệt tay).
- Nếu ở bất kỳ TC nào verify-green sau revert thất bại → **dừng ngay**, đây là lỗi nghiêm trọng (repo bẩn), ưu tiên khôi phục hơn tiếp tục.
- **Oracle phải neo vào giá trị lấy từ spec hoặc từ input của chính test.** So **output hệ thống với output hệ thống** thì không phải oracle: một mutation làm cả hai bên sai *cùng một kiểu* sẽ khớp nhau và test xanh oan (vd assert `id` đọc từ `/auth/me` bằng `id` trả về lúc register — phiên resolve sai user thì cả hai cùng sai). Đây là ca `test-error` chỉ sanity-red bắt được.

---


---

## 5. Phân loại test đỏ (finding)

Test chạy lên code cũ mà đỏ **không có nghĩa test sai**. Phân loại theo bản chất, ghi verdict + evidence + action vào §2 Findings của `test-report-{scope}.md`. **KHÔNG sửa test cho xanh.** Verdict quyết `Loại`, và `Loại` quyết `PIC` — ai xử việc đó (§7.4).

| Verdict | Nghĩa | Action |
|---|---|---|
| **bug-code** | Code làm khác VR/AC/FAC và **không** có lý do nào để code có thể đúng — hoặc BA đã chốt *giữ spec* | Ghi finding → **sửa code** (ngoài skill; skill không tự sửa code sản phẩm) |
| **spec-drift** | Code làm khác VR/AC/FAC **và có dấu vết** cho thấy code có thể đúng. Chưa biết bên nào sai, BA quyết — định nghĩa duy nhất ở [`05-concepts.md §14`](../05-concepts.md) | Ghi finding + mục `SD-*` ở sổ của feature (cạnh `frd.md`) → BA quyết ở `/spec-new {F-XXX}`: sửa requirement theo code, hoặc giữ requirement (code sai) |
| **flaky** | Không tất định (timing, thứ tự, external) | Cô lập / ổn định hoá test; chưa tin kết quả |
| **test-error** | Sai ở chính test / fixture / wiring (không phải code hay spec) | Sửa test rồi chạy lại |

**Một sổ — sổ của feature, cạnh `frd.md` ([`.docs/039`](../.docs/039-spec-debt-mot-so-cap-feature.md)).** Drift sống ở `.specs/main/feature/{F-XXX}-{slug}/spec-debt.md` — sổ **duy nhất** của feature, chứa cả mục review mở ở ③ Build lẫn mục ④ Verify mở. Không có sổ integration, không có bản sao. Hình dạng mục, dòng `**phát hiện:**` và luật viết nằm ở comment của `templates/main/feature/spec-debt-template.md` — đọc trước khi ghi.

**Sổ kiểu cũ còn sót ⇒ dừng tầng, trước khi chạy test.** `find .specs/integrations .specs/tests -name spec-debt.md 2>/dev/null` ra file nào ⇒ dừng, in `Sổ nợ spec kiểu cũ: {đường dẫn} — chạy: npx spec-lite migrate-spec-debt`, không ghi gì. Tầng **đọc** sổ để phán verdict: đọc thiếu một `SD` mở nằm ở sổ cũ là xếp `bug-code` cho chỗ BA chưa quyết, và `/fix-findings` sửa mất code có thể đang đúng.

Với mỗi TC đỏ, mỗi ID trong `Covers`, tra sổ:

```bash
grep -rnE --include=spec-debt.md "^- \[[ x]\] \*\*SD-[0-9]+\*\* · \`${ID}\`" .specs/main/feature .specs/removed 2>/dev/null
```

Dùng `grep -r --include`, **không** glob `*/spec-debt.md`: glob không khớp gì thì zsh dừng hẳn.

| # | Mục quyết | Verdict | `Evidence` ghi kèm |
|---|---|---|---|
| 1 | `` - [ ] **SD-n** · `{ID}` `` — có hay không con trỏ `→` (BA chưa quyết, hoặc đã chọn sửa requirement mà integration đó chưa xong) | **`spec-drift`** — không phán lại | `SD-n của {F-XXX}-{slug}` |
| 2 | `` - [x] **SD-n** · `{ID}` … **giữ spec:** `` | **`bug-code`** — BA đã chốt requirement đúng, code sai | `SD-n giữ spec ({F-XXX}-{slug})` |
| 3 | không có mục, hoặc chỉ `[x] … → {slug}` (requirement đã đổi theo code); code lệch câu chữ **và** có dấu vết — comment trong code · commit message · một nguồn đã duyệt khác (`domain.md`, `tech.md`) mà code khớp | **`spec-drift`** | `SD-n của {F-XXX}-{slug}` + dấu vết (trỏ file:dòng hoặc sha) |
| 4 | như 3 nhưng **không** trỏ được dấu vết | **`bug-code`** | file:dòng của chỗ lệch |

**Ca 1 — thấy lại mục đã có ⇒ thêm một dòng phát hiện.** Mục chưa có dòng `**phát hiện:**` nào chứa `retrofit {scope}` ⇒ thêm **một** dòng `` ④ Verify — retrofit {scope} · `{TC}` đỏ · `{short-sha}` · {YYYY-MM-DD} `` vào cuối danh sách; hiện tượng test đo được khác mô tả của mục ⇒ thêm một vế ngắn sau `·` ở chính dòng đó (`· TC đỏ: mong đợi … , thực tế …`). Đã có dòng của tầng này ⇒ không ghi gì: chạy lại cùng tầng không thêm dòng. Không sửa mô tả, dấu vết, câu hỏi. Áp ở **mọi** mode — thêm dòng là tra cứu, không phán.

**Ca 3 — mở mục mới** ở sổ của feature (sổ chưa có ⇒ tạo từ template: `{F-XXX}-{slug}` = tên thư mục feature, `{title}` = tên feature ở H1 của `frd.md`, bỏ tiền tố `Feature:`, `{YYYY-MM-DD}`). `SD-n` = ID `SD` lớn nhất **đã từng** có trong sổ + 1.

```markdown
- [ ] **SD-n** · `{ID}` — {hiện tượng: người dùng làm gì, hệ làm gì} · {ID} nói {gì}
  - **phát hiện:**
    - ④ Verify — retrofit {scope} · `{TC}` đỏ · `{short-sha}` · {YYYY-MM-DD}
  - **dấu vết:** {comment ở `file:dòng` / commit `{short-sha}` / section của nguồn đã duyệt} — "{trích nguyên văn}"
  - **câu hỏi cho BA:** giữ {ID} hay đổi {ID} theo hành vi hiện tại?
```

Mô tả chỉ nêu **hiện tượng**, bằng chữ người dùng thấy, không tên hàm, không ký tự `→`, không chữ đánh giá; `file:dòng` chỉ được ở `**dấu vết:**`, kèm trích nguyên văn. `{short-sha}` = `HEAD` lúc tầng bắt đầu chạy — commit chứa code đang được đo.

Chỉ mở ở lượt **có phán** verdict (default · `full`). `execute`/`sanity` gặp ca 3 thì ghi finding `spec-drift` mà **không** mở mục, và nói rõ trong commit message — lượt default/`full` sau sẽ mở. Commit sổ cùng `test-report-{scope}.md`. Lượt sau rơi vào ca 1, nên verdict giữ ổn định dù report dựng lại mỗi lượt.

**Ca 4 là luật chặn trốn việc, cùng luật của review** ([`/review-integration`](../skills/review-integration/SKILL.md)): drift không đẻ việc cho `🤖`, nên đẩy một lỗi thật sang drift là cách rẻ nhất để vòng lặp kết thúc sớm. "Spec có vẻ lỗi thời" mà không trỏ được dấu vết nào ⇒ `bug-code`.

**Đối chiếu ngược — `SD` mở mà không test nào đỏ ([`.docs/037`](../.docs/037-spec-drift-mot-nghia.md) `D6` · `D7`).** Chạy sau quét B, chỉ xét ID thuộc **trụ của tầng** — `VR-*` → validation · `AC-*` → functional · `FAC-*` → e2e — và thuộc feature này (tiền tố `{P}-F{NNN}-`). Mỗi `` - [ ] **SD-n** `` trong sổ của feature neo ID của trụ mà **không** có `FIND-*` của lượt này neo cùng ID (TC xanh, hoặc không TC nào cover ID đó):

1. ghi một `A-{SCOPE}-n` ở §5 Next Actions:

| Việc | Nguồn | Loại | PIC |
|---|---|---|---|
| `SD-n` (`{ID}`) mở, không test nào đỏ — quyết ở `/spec-new {F-XXX}` | `SD-n` | `spec-drift` | `👤 BA` |

2. mục chưa có dòng phát hiện nào chứa `retrofit {scope}` ⇒ thêm `` ④ Verify — retrofit {scope} · không TC đỏ · `{short-sha}` · {YYYY-MM-DD} `` — BA đọc được là tầng này đã đo và test xanh.

Cột `Việc` giữ đúng câu này để nằm trong trần 100 ký tự (test-core §7.1). Hai khả năng — code đã về đúng requirement, hay test chưa chạm chỗ lệch — là việc BA đọc ra ở `/spec-new`, không cần nhét vào ô.

Áp ở mọi mode — đối chiếu là tra cứu, không phán. Không làm bước này thì một drift review đã ghi có thể đi qua ④ Verify mà không ai thấy (đo 2026-10-01 trên bed `F-009`: `AC-F009-003` xanh).


---


---

## 8. Red flags chung (mọi tầng)

- Lấy giá trị đúng từ code (đọc code rồi "test cho khớp code") → vỡ luật 1.
- Sửa `test-design.md` / `frd.md` trong lúc chạy skill → vỡ luật 2.
- Ghi result/finding vào doc test-exec thay vì `test-report-{scope}.md` → vỡ luật 3.
- Test xanh mà không có `sanity-red` proven-red (cột §4 Results) → không được tính pass.
- Để code sản phẩm còn mutation chưa revert khi kết thúc (hoặc giữa chừng) → repo bẩn.
- Sửa test cho xanh thay vì phân loại finding → che giấu bug-code/spec-drift.
- Tag `harness` cho TC mà thật ra **tách seam được** — hàm thuần HOẶC component props-driven test bằng infra sẵn có (→ đúng phải `refactor`) → thổi phồng "cần đầu tư infra" trong khi chỉ là refactor nhỏ; owner đọc report sai chi phí (§3b). Kinh điển: thấy rule "là render" hoặc "page lớn phải Proxy-mock" → vội gán harness mà quên hỏi "tách component ra là hết cần Proxy chưa?".
- Tự ý **extract logic ra khỏi resolver/component** (refactor cấu trúc) trong lúc retrofit thay vì defer `refactor` → vượt remit "viết test + export tối thiểu"; refactor là quyết định của owner.
- Giữ TC không neo ID nào (không prune, không nâng thành requirement) → vỡ traceability.
- Đọc hoặc ghi `test-report-{scope}.md` của **scope khác** (theo phản xạ hồi ba tầng dùng chung một file) → vỡ luật một file một writer (§7). Kế thừa chỉ áp cho file scope **của chính mình**.
- Dựng lại roll-up bằng cách **đọc bản roll-up cũ** rồi gộp thêm → vỡ §7b bước 2: roll-up dựng lại trọn từ các file scope, không giữ dữ kiện riêng.
- Glob `test-report*.md` khi dựng lại roll-up (khớp **cả** chính nó) → roll-up đọc chính mình; phải trừ `test-report.md` ra (§7b bước 1).
- Thêm section/nội dung ngoài 5 section của file scope (`Pruned`, `Observations`, `Sanity-Red Ledger`, `Change History`/timeline/run-log) hoặc viết **đoạn văn trần** / blockquote kể-chuyện → **vỡ format §7.1**. Lịch sử = git + commit message.
- Ô vượt trần ký tự, hoặc cắt tới mức ô thành **nhãn cụt** (`Vấn đề` = `harness`) → vỡ §7.1/§7.2: `Vấn đề` phải hai mệnh đề, và nhãn nào dùng thì section phải có legend.
- Dùng ID không tiền tố scope (`Finding-01`, `OBS-1`, `A1`) hoặc **đánh số lại** khi chạy lại scope → vỡ §7.3 (append-only, trích chéo mất ngữ cảnh file).
- Gán `PIC` theo cảm tính thay vì suy từ `Loại`, hoặc **tự nâng `👤` thành `🤖`** rồi tự sửa → vỡ §7.4: `👤` là vùng đóng băng, agent chỉ mô tả việc.
- `Loại` ngoài tập đóng 8 nhãn, hoặc dòng §5 có `Nguồn` không trỏ `FIND-*`/`BLK-*`/req-ID (action mồ côi) → vỡ §7.3/§7.4.
- Chép lại `Summary`/`Coverage`/dòng `**Mục:**` của lượt trước thay vì **tính lại** từ §4 → ba chỗ derive lệch với bảng nguồn (§7).
- Chép lại cột `Result` của lượt trước ("giữ nguyên cho nhanh") → `Result` là sự thật của lúc này, phải **chạy lại**; kế thừa chỉ áp cho `sanity-red`/`mutation`/`reverted`/`Tier`/`Action`/`Note` và chỉ cho TC `UNCHANGED` (§7).
- `BLK` không gắn TC nào · blocker của TC `⏭` bỏ lửng không lên `BLK` · `no-seam` đẻ `BLK` thừa · nhét thứ không-chặn-TC-nào (red có sẵn ngoài feature, việc dọn dẹp) vào §3 → **vỡ quy tắc 2 chiều §7.3** (mọi ⏭↔1 BLK; mọi BLK↔≥1 TC). Thứ không chặn TC nào là **việc** ⇒ §5.
- Ghi report mà **không commit** sau mỗi tầng → mất history (git là nguồn duy nhất, 015 §3B).
- Bỏ qua version-gate: retrofit tự sửa wiring test-exec khi version lệch (thay vì STOP báo /spec-test-exec) → vỡ 016 D9 (§1b①).
- Re-run cả scope mà bắt UNCHANGED TC trả lại chi phí sanity-red → phí (§1b: UNCHANGED chỉ re-execute, inherit sanity-red/Finding).
- Chạy xong scope mà **quên nâng pin** `test_exec_version` ở file scope → scope vẫn hiện stale, lần sau chạy lại vô ích (§1b③). Ghi pin thành một map gom cả 5 scope trong một frontmatter → sai: pin là **một số**, sống trong từng file scope (030 D2).
- Ghi file scope xong mà **không dựng lại roll-up** → roll-up cũ, `derived_from` lệch pin (§7b).
- MODIFIED TC đang là Finding mà **không re-evaluate verdict** → giữ verdict lỗi thời (016 D11).
- Dùng `--mode` để hút TC mới (khi scope stale, `pin < version`) → pin-inconsistency; absorb TC mới là việc của default gated run (§1c guardrail 2).
- `--mode` bump/đụng pin, hoặc `execute`/`sanity` tự ghi cột wiring (`Tier`/`Covers`/`Action`/`Note`) → vỡ pin-neutral + Tier một-nguồn-ghi (§1c guardrail 1, 4).
- Sửa **tay** một file `test-report*` → không ai nâng pin, và ô sửa tay bị ghi đè ở lượt dựng lại kế tiếp (030 D22 — report chỉ do skill ghi).
- Ghi row §4 **trước** khi revert + verify-green của TC đó xong → report nói TC xanh trong khi code còn mang mutation (§7.0).
- **Rác trong seeded DB sau khi bị ngắt** *(chỉ tầng e2e)* — kill giữa lúc journey đang chạy thì `afterEach` teardown không chạy, record của lượt dở **nằm lại** trong seeded DB. Lượt sau `[verify-db]` assert `count = N` gặp `N+1` → đỏ **vì rác, không vì code**; verdict đúng là `flaky`/`test-error`, **KHÔNG** `bug-code`. Đây là ca duy nhất trong ba tầng mà một lượt bị ngắt làm **sai kết quả lượt sau** ⇒ **reset seed trước khi re-execute một scope e2e**.
- Trông đợi `dup-of` được phát hiện tự động → **không ai derive được nó**: §7.3 khai `dup-of` là **luật**, ba file scope không thấy nhau và skill tầng bị cấm mở file scope khác, còn orchestrator thấy cả hai qua roll-up thì lại bị cấm ghi report. Nó chỉ điền được khi **cùng một lượt** nhìn thấy cả hai finding. Lỗ đã biết — đừng dựng cơ chế đếm nào dựa vào nó đã đầy đủ.
