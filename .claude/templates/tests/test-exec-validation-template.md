---
id: test-exec-validation-{F-XXX}-{slug}
type: test-exec-validation
status: draft
method: automation
owner: "{DEV}"
feature_id: "{F-XXX}"
test_design_ref: "tests/{F-XXX}-{slug}/test-design.md"
version: 1                  # 016: content-version của doc này; /spec-test-exec bump khi áp delta wiring (không bump khi owner chỉ điền Test File)
test_design_version: 1      # 016: = test-design.versions.validation lúc sinh/reconcile gần nhất
platform: web
# runner theo layer pyramid — validation nằm ở đáy pyramid (unit/api)
runners:
  unit: "{vitest / jest}"
  api: "{supertest / pytest / RestAssured}"
spec_root: "{repo-path}/tests"
referenced_by:
  - 02-artifacts.md > Test Execution Artifacts > test-exec-validation.md
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/test-exec-validation.md.
EXECUTION layer — bản render VALIDATION scope, harness AUTOMATION, owner DEV. Spec của test code (result ở test-report).
Cover Validation Test Cases (neo VR-F*) — rule format/length/range/required trên field.

validation là SCOPE riêng (tách khỏi functional từ 014 Phase 0):
  - Nguồn TC: test-design "## Validation Test Cases". Mỗi TC neo đúng 1 VR-F*.
  - Hình dạng cứng: mỗi VR có ≥1 positive (giá trị hợp lệ → pass) + ≥1 negative (giá trị vi phạm → reject).
    KHÔNG lẫn với Given-When-Then của functional.
  - Validation TC gần như luôn Autoable=YES (oracle = so khớp rule tất định) → render toàn bộ.
  - Layer: đáy pyramid — unit (validator/schema thuần) hoặc api (nhánh 400 server-side).
  - Inherit CÙNG TC-F* từ test-design. KHÔNG tạo ID mới.

"Giá trị đúng" (valid/invalid nào) lấy từ VR text ở test-design, KHÔNG đọc từ code (013 §4.1).
Code chỉ cho biết "móc vào đâu" (validator/schema/nhánh 400 nào).

KHÔNG versioned: không template_version / migrations, ngoài scope /artifact-audit + /artifact-migrate.
Derived từ test-design.md → REGENERATE khi test-design đổi.

KHÔNG chứa KẾT QUẢ. test-exec = spec của test code (layer/file/assert). Result (pass/fail per-TC)
sống ở test-report.md của bundle — NƠI DUY NHẤT giữ kết quả (013 §4).
-->

# Validation Test Specification (Automation): {Feature Name}

**Feature**: {F-XXX} | **Owner**: {owner} | **Reviewer**: {reviewer} | **Status**: {status}

---

## 1. Context

| **Field** | **Detail** |
|---|---|
| **Feature Summary** | {2–3 câu từ frd.md Overview} |
| **In-Scope** | Validation TC (neo VR) — rule format/length/range/required trên field, verify bằng test code |
| **Out of Scope** | Story AC behavior → `./test-exec-functional.md` · e2e journey → `./test-exec-e2e.md` · NFR → `./test-exec-nfr.md` · DM → `./test-exec-dm.md` |
| **Source** | [test-design.md](./test-design.md) — Validation TC IDs + Traceability Matrix (VR → TC) |

---

## 2. Environment & Setup

> Validation ở đáy pyramid: ưu tiên `unit` (validator/schema thuần); dùng `api` khi rule chỉ enforce server-side (nhánh 400).

| **Layer** | **Runner / Framework** | **Dùng cho** | **Tốc độ** |
|---|---|---|---|
| unit | {vitest/jest} | validator / schema / pure rule | rất nhanh |
| api | {supertest/pytest} | rule enforce server-side, nhánh reject 400 | nhanh |

| **Field** | **Value** |
|---|---|
| Spec root | `{spec_root}` |
| Env | {test DB / in-memory / mock external} |
| Seed / fixtures | {boundary inputs — factory / fixture file} |

---

## 3. Coverage

> Mỗi `TC-F*` ở đây neo đúng 1 VR + xuất hiện ở Traceability Matrix của test-design.

### 3.1 VR Coverage

| **VR ID** | **Priority** | **Covered by TC IDs** | **Layer** | **Notes** |
|---|---|---|---|---|
| `VR-F{NNN}-001` | 🔴 P0 | `TC-F{NNN}-010`, `TC-F{NNN}-011`, `TC-F{NNN}-012` | unit | 1 pos + 2 neg |

---

## 4. Test Cases

> **TC ID:** inherit từ `test-design.md` (Validation TC). KHÔNG tạo ID mới.
>
> **Layer:** `unit` | `api`
>
> **Polarity:** `pos` (giá trị hợp lệ → pass) | `neg` (giá trị vi phạm → reject). Mỗi VR cần ≥1 pos + ≥1 neg.
>
> **Test File:** đường dẫn file code + tên test (`describe > it`). DEV điền khi implement.
>
> **Assertion:** input → expected. Giá trị hợp lệ/vi phạm lấy từ VR text (test-design), KHÔNG từ code.
>
> **Kết quả chạy (pass/fail) KHÔNG ở đây** — ghi ở `test-report.md` của bundle (Results). Doc này chỉ là spec.

| **TC ID** | **Covers** | **Layer** | **Polarity** | **Test File (`describe > it`)** | **Assertion (input → expected)** | **Priority** |
|---|---|---|---|---|---|---|
| `TC-F{NNN}-010` | `VR-F{NNN}-001` | unit | pos | `{path}/{validator}.spec.ts > {it}` | `validate("{valid}")` → pass | 🔴 P0 |
| `TC-F{NNN}-011` | `VR-F{NNN}-001` | unit | neg | `{path}/{validator}.spec.ts > {it}` | `validate("")` → reject(required) | 🔴 P0 |
| `TC-F{NNN}-012` | `VR-F{NNN}-001` | unit | neg | `{path}/{validator}.spec.ts > {it}` | `validate("{too-long}")` → reject(maxLength) | 🟡 P1 |

---

## 5. Fixtures & Test Data

> Provisioning tự động — factory/builder/fixture. KHÔNG seed thủ công.

| **Fixture / Factory** | **Type** | **Tạo gì** | **Used by (TC)** |
|---|---|---|---|
| `{boundaryInputs}` | fixture | giá trị biên (min/max/empty/over) cho mỗi VR | `TC-F{NNN}-010..012` |

---

## 6. Execution

**Commands:**

```bash
{npm test} {path}                      # full validation suite
{npm test} -- --grep "VR-F{NNN}-001"   # theo VR
{npm run test:coverage}                # coverage report
```

**CI Gate:**

| **Trigger** | **Scope** | **Gate** |
|---|---|---|
| PR → develop | validation suite (P0) | block merge nếu red |
| Merge → develop | full validation suite | alert nếu red |

---

## 7. Change Log

| **Date** | **Cycle** | **Changes** | **Author** |
|---|---|---|---|
| {YYYY-MM-DD} | {cycle/release} | Initial validation spec (derive từ test-design.md — Validation TC) | {Author} |
