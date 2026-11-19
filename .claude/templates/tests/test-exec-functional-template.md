---
id: test-exec-functional-{F-XXX}-{slug}
type: test-exec-functional
status: draft
method: automation
owner: "{DEV}"
feature_id: "{F-XXX}"
test_design_ref: "tests/{F-XXX}-{slug}/test-design.md"
version: 1                  # 016: content-version của doc này; CHỈ /spec-test-exec bump, và chỉ khi áp delta wiring vì test-design đổi.
                            # KHÔNG bump khi owner điền Test File, và KHÔNG bump khi skill outer (/spec-test-functional) điền Layer+Test File
                            # ở ③ Build — bump mỗi slice thì pin-gate ở ④ Verify thấy stale liên tục (034 DS9, test-core §7c.1)
test_design_version: 1      # 016: = test-design.versions.functional lúc sinh/reconcile gần nhất
platform: web
# runner theo TIER (test-core §2a) — chọn bậc thấp nhất khả thi cho mỗi TC
runners:
  fe_unit: "{vitest} — hàm thuần / hook FE, không DOM"
  fe_component: "{testing-library / @vue/test-utils} + {jsdom} · mobile: {flutter_test + WidgetTester / RNTL} — GAL gọi tầng này là \"widget test\""
  be_unit: "{vitest / xunit} — hàm thuần domain"
  be_handler: "{vitest + DB in-memory / fake repo}"
  be_api: "{supertest / WebApplicationFactory}"
spec_root: "{repo-path}/tests"
referenced_by:
  - 02-artifacts.md > Test Execution Artifacts > test-exec-functional.md
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/test-exec-functional.md.
EXECUTION layer — bản render FUNCTIONAL scope, harness AUTOMATION, owner DEV. Spec của test code (result ở test-report).
Cover phần AUTOMATABLE của Functional Test Cases (neo Story AC), gồm cả `fe:component` test.

functional là SCOPE riêng (tách khỏi validation từ 014 Phase 0):
  - Nguồn TC: test-design "## Functional Test Cases". Mỗi TC neo 1 AC-F*.
  - Hình dạng: Given-When-Then (điều kiện → hành động → kết quả quan sát). KHÔNG lẫn với pos/neg của validation.
  - CHỈ chứa TC automatable (Autoable=YES/MAYBE ở test-design). TC Autoable=NO (oracle visual:
    màu/layout/icon/animation) KHÔNG script được → KHÔNG render vào đây (ở lại test-design, kiểm ad-hoc).
  - KHÔNG có cột Autoable ở doc này — mọi TC ở đây đều automatable theo định nghĩa.
  - Inherit CÙNG TC-F* từ test-design. KHÔNG tạo ID mới.

Pyramid: automate ở layer THẤP NHẤT khả thi — AC ở mức 1 component → component; behavior qua endpoint →
be:api. KHÔNG có bậc `narrow-UI`: chân FE cap ở `fe:component` (+`fe:api`) — AC buộc browser thật là
đã ở cost `e2e` (test-core §2a), đẩy sang tầng e2e chứ không đẻ bậc mới. Journey xuyên
màn hình → KHÔNG ở đây, chuyển sang test-exec-e2e.

testid cho fe:component: lấy TỪ selector-contract.md của feature (nguồn chung code + test cùng
đọc). KHÔNG tự đặt testid mới. Feature chưa có contract → placeholder + note.

"Cái gì đúng" (kết quả mong đợi) lấy từ AC text ở test-design, KHÔNG đọc từ code (013 §4.1).
Code chỉ cho biết "móc vào đâu" (component/handler/endpoint/testid nào).

KHÔNG versioned: không template_version / migrations, ngoài scope /artifact-audit + /artifact-migrate.

Ô `Layer`/`Test File` RỖNG nghĩa là **slice chưa chạy tới TC này**, KHÔNG phải "không viết được".
"Đã xét và không viết được" có nhãn riêng: `⏭` + `refactor`/`harness`/`need-clarify`/`no-seam`.
Lẫn hai cái là report đẻ blocker giả (test-core §7c.1).
Derived từ test-design.md → REGENERATE khi test-design đổi.

KHÔNG chứa KẾT QUẢ. test-exec = spec của test code (layer/file/assert/testid). Result (pass/fail per-TC)
sống ở test-report.md của bundle — NƠI DUY NHẤT giữ kết quả (013 §4).
-->

# Functional Test Specification (Automation): {Feature Name}

**Feature**: {F-XXX} | **Owner**: {owner} | **Reviewer**: {reviewer} | **Status**: {status}

---

## 1. Context

| **Field** | **Detail** |
|---|---|
| **Feature Summary** | {2–3 câu từ frd.md Overview} |
| **In-Scope** | TC automatable của Functional Test Cases (Story AC) — verify bằng test code ở tier rẻ nhất mà AC enforce được |
| **Out of Scope** | TC visual không script được (ở lại test-design) · Validation rule → `./test-exec-validation.md` · e2e journey → `./test-exec-e2e.md` · NFR → `./test-exec-nfr.md` · DM → `./test-exec-dm.md` |
| **Source** | [test-design.md](./test-design.md) — Functional TC IDs (Autoable=YES/MAYBE) + Traceability Matrix (AC → TC) |

---

## 2. Environment & Setup

> Mỗi TC gắn layer thấp nhất khả thi (test pyramid). Layer quyết định runner + tốc độ + chi phí.

| **Tier** | **Runner / Framework** | **Dùng cho** | **Tốc độ** |
|---|---|---|---|
| `fe:unit` | {vitest} | hàm thuần / hook FE (selector, format, state logic) — không DOM | rất nhanh |
| `fe:component` | {testing-library} + {jsdom} · mobile: `flutter_test`+`WidgetTester` ("widget test") / RNTL | AC ở mức 1 component, render + interaction | nhanh |
| `be:unit` | {vitest/xunit} | hàm thuần domain (computed, invariant, predicate) | rất nhanh |
| `be:handler` | {fake repo / DB in-memory} | AC về data/state/side-effect do logic tự enforce | nhanh |
| `be:api` | {supertest/pytest} | AC mà rule nằm ở chính tầng HTTP (auth gate, model-binding, query param) | nhanh |

| **Field** | **Value** |
|---|---|
| Spec root | `{spec_root}` |
| Env | {test DB / in-memory / mock external} |
| Seed / fixtures | {cách provisioning tự động — factory / fixture file} |
| Selector-contract | [selector-contract.md](./selector-contract.md) *(nguồn testid cho `fe:component`; bỏ nếu feature không có UI)* |

---

## 3. Coverage (automatable subset)

> Mỗi `TC-F*` ở đây là TC automatable (Autoable=YES/MAYBE ở test-design) + xuất hiện ở Traceability Matrix.
> TC visual không script được KHÔNG lên bảng này (ở lại test-design).

### 3.1 AC Coverage

| **AC ID** | **Priority** | **Covered by TC IDs** | **Layer** | **Notes** |
|---|---|---|---|---|
| `AC-F{NNN}-001` | 🔴 P0 | `TC-F{NNN}-001` | component | |
| `AC-F{NNN}-002` | 🟡 P1 | `TC-F{NNN}-003` | api | |

---

## 4. Test Cases

> **TC ID:** inherit từ `test-design.md` (chỉ TC automatable). KHÔNG tạo ID mới.
>
> **Layer:** tier theo `test-core` §2a — `be:unit` · `be:handler` · `be:persistence` · `be:api` · `fe:unit` · `fe:component`. **KHÔNG** có bậc `narrow-UI`.
>
> **`out-of-runner`** — TC `Autoable=YES/MAYBE` nhưng **không runner nào của scope này chạy được**: cần build release trên thiết bị thật, trace bootstrap/cold-start, đo p90 ngoài process test… (vd *"cold start ≤ 3s p90"*). Đây **không** phải `Autoable=NO` (oracle vẫn lập trình được) và **không** phải `no-seam`. TC vẫn **render vào doc này** để không lọt completeness, Test File để `_Pending_`, và scope report phải mở sẵn một **`BLK-{SCOPE}-N`** nêu hạ tầng còn thiếu. KHÔNG tự chế nhãn khác (`*(ngoài runner)*`…) — một tên, để đếm được.
>
> **Test File:** đường dẫn file code + tên test (`describe > it`). DEV điền khi implement.
>
> **Given-When-Then:** điều kiện đầu → hành động → kết quả quan sát. Kết quả mong đợi lấy từ AC (test-design), KHÔNG từ code.
>
> **testid:** với `fe:component`, handle từ `selector-contract.md`. `—` nếu TC không chạm UI.
>
> **Kết quả chạy (pass/fail) KHÔNG ở đây** — ghi ở `test-report.md` của bundle (Results). Doc này chỉ là spec.

| **TC ID** | **Covers** | **Layer** | **Test File (`describe > it`)** | **Given-When-Then** | **testid** | **Priority** |
|---|---|---|---|---|---|---|
| `TC-F{NNN}-001` | `AC-F{NNN}-001` | `fe:component` | `{path}/{file}.spec.ts > {describe} > {it}` | Given {state} · When {action} · Then {expected DOM/behavior} | `{handle từ contract}` | 🔴 P0 |
| `TC-F{NNN}-003` | `AC-F{NNN}-002` | `be:handler` | `{path}/{file}.spec.ts > {it}` | Given {seed} · When gọi handler · Then {state/side-effect} | — | 🟡 P1 |

---

## 5. Fixtures & Test Data

> Provisioning tự động — factory/builder/fixture. KHÔNG login tay, KHÔNG seed thủ công.

| **Fixture / Factory** | **Type** | **Tạo gì** | **Used by (TC)** |
|---|---|---|---|
| `{userFactory}` | factory | user hợp lệ đủ field | `TC-F{NNN}-001` |
| `{stateBuilder}` | builder | dựng state Given cho AC | `TC-F{NNN}-003` |

---

## 6. Execution

**Commands:**

```bash
{npm test} {path}                       # full functional suite
{npm test} -- --grep "AC-F{NNN}-001"    # theo TC/AC
{npm run test:coverage}                 # coverage report
```

**CI Gate:**

| **Trigger** | **Scope** | **Gate** |
|---|---|---|
| PR → develop | functional suite (P0) | block merge nếu red |
| Merge → develop | full functional suite | alert nếu red |
| Nightly | full + coverage | report |

---

## 7. Change Log

| **Date** | **Cycle** | **Changes** | **Author** |
|---|---|---|---|
| {YYYY-MM-DD} | {cycle/release} | Initial functional spec (derive từ test-design.md — Functional TC automatable) | {Author} |
