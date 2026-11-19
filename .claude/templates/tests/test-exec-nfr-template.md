---
id: test-exec-nfr-{F-XXX}-{slug}
type: test-exec-nfr
status: draft
owner: "{DEV}"
feature_id: "{F-XXX}"
test_design_ref: "tests/{F-XXX}-{slug}/test-design.md"
version: 1                  # 016: content-version của doc này; /spec-test-exec bump khi áp delta wiring (không bump khi owner chỉ điền Test File)
test_design_version: 1      # 016: = test-design.versions.nfr lúc sinh/reconcile gần nhất
referenced_by:
  - 02-artifacts.md > Test Execution Artifacts > test-exec-nfr.md
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/test-exec-nfr.md.
EXECUTION layer — bền (015: 1 file/feature, ghi đè tại chỗ, history=git), harness "tool đặc thù" (k6/JMeter/axe/Lighthouse/ZAP), owner DEV.
Cover Non-Functional Requirements (NFR) — perf / a11y / security / browser / i18n.

KHÔNG versioned: không template_version / migrations, ngoài scope /artifact-audit + /artifact-migrate.
Derived từ test-design.md → test-design đổi thì REGENERATE.

CHỈ TẠO file này khi frd.md có `NFR-F*` (test-design § Non-Functional Test Cases không rỗng).
  Feature không có NFR riêng → KHÔNG tạo test-exec-nfr.md.

Source of truth: test-design.md > Non-Functional Test Cases.
  - ID = TC-F{NNN}-{seq} inherit từ test-design (Covers NFR-F*). KHÔNG tạo ID mới.
  - Coverage master = test-design.md > Traceability Matrix.

Doc này gọn — WHAT (threshold/expected) đã ở test-design; đây thêm HOW (tool + command + env).
-->

# NFR Test Execution: {Feature Name}

**Feature**: {F-XXX} | **Owner**: {owner} | **Status**: {status}

---

## 1. Context

| **Field** | **Detail** |
|---|---|
| **Feature Summary** | {1–2 câu — NFR scope của feature} |
| **NFR covered** | {NFR IDs — `NFR-F{NNN}-001`, ...} |
| **Source** | [test-design.md](./test-design.md) — TC IDs (Non-Functional Test Cases) + Traceability Matrix |
| **Out of Scope** | Functional security (authz) → test-exec-functional · functional behavior → test-exec-functional/test-exec-e2e · validation rule → test-exec-validation |

---

## 2. Tooling & Environment

> Mỗi NFR Type cần harness riêng. Env phải tách khỏi functional test (load/scan ảnh hưởng môi trường).

| **NFR Type** | **Tool** | **Env Requirement** | **Notes** |
|---|---|---|---|
| performance | k6 / JMeter | env perf-test · dataset baseline đã load | isolated, không share với functional run |
| a11y | axe-playwright / Lighthouse | env app thường | audit per page |
| security scan | OWASP ZAP / scanner | env staging-like | baseline scan, không phá data |
| browser compat *(web)* | Playwright multi-project | — | chromium / firefox / webkit |
| OS/device compat *(mobile)* | Maestro (multi-device matrix) | emulator/thiết bị mỗi OS version cần cover | Android version matrix / iOS version matrix |

---

## 3. NFR Execution

> **Input:** test-design.md § Non-Functional Test Cases (TC ID, threshold, expected).
> **Kết quả chạy (pass/fail) KHÔNG ở đây** — ghi ở `test-report.md` của bundle (Results). Doc này chỉ là spec.

| **TC ID** | **Covers** | **NFR Type** | **Tool** | **Execution Command / Config** | **Threshold** | **Priority** |
|---|---|---|---|---|---|---|
| `TC-F{NNN}-050` | `NFR-F{NNN}-001` | performance | k6 | `k6 run {script}.js --vus 100 --duration 5m` | p95 ≤ 500ms · error ≤ 0.1% | 🔴 P0 |
| `TC-F{NNN}-051` | `NFR-F{NNN}-002` | a11y | axe-playwright | `npx playwright test --grep "a11y"` | WCAG AA · 0 critical | 🟡 P1 |
| `TC-F{NNN}-052` | `NFR-F{NNN}-003` | security scan | OWASP ZAP | `zap-baseline.py -t {base_url}` | 0 High · 0 Medium | 🔴 P0 |
| `TC-F{NNN}-053` | `NFR-F{NNN}-004` | browser compat *(web)* | Playwright | `npx playwright test --project=chromium,firefox,webkit` | pass Chrome/FF/Safari | 🟢 P2 |
| `TC-F{NNN}-054` | `NFR-F{NNN}-005` | OS/device compat *(mobile)* | Maestro (multi-device matrix) | `{e2e-script} {flow} --device={android-N},{android-M},{ios-N}` | pass mọi OS version trong matrix | 🟢 P2 |

---

## 4. Exit Criteria

- [ ] Mọi NFR P0 TC pass (threshold đạt)
- [ ] NFR P1 không có regression so với baseline trước
- [ ] Result đã ghi ở `test-report.md` (Results) đầy đủ cho mọi NFR TC
- [ ] Finding (nếu fail) đã ghi ở `test-report.md` (Findings) + link bug ticket

---

## 5. Change Log

| **Date** | **Cycle** | **Changes** | **Author** |
|---|---|---|---|
| {YYYY-MM-DD} | {cycle/release} | Initial NFR execution (derive từ test-design.md) | {Author} |
