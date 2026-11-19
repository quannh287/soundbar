---
id: test-exec-dm-{F-XXX}-{slug}
type: test-exec-dm
status: draft
owner: "{DEV}"
feature_id: "{F-XXX}"
test_design_ref: "tests/{F-XXX}-{slug}/test-design.md"
version: 1                  # 016: content-version của doc này; /spec-test-exec bump khi áp delta wiring (không bump khi owner chỉ điền Test File)
test_design_version: 1      # 016: = test-design.versions.dm lúc sinh/reconcile gần nhất
referenced_by:
  - 02-artifacts.md > Test Execution Artifacts > test-exec-dm.md
---

<!--
Canonical format cho .specs/tests/{F-XXX}-{slug}/test-exec-dm.md.
EXECUTION layer — bền (015: 1 file/feature, ghi đè tại chỗ, history=git), harness "migration script trên dataset prod-like", owner DEV.
Cover Data & Migration (DM) — backfill, schema migration, data cũ không mất/hỏng.

KHÔNG versioned: không template_version / migrations, ngoài scope /artifact-audit + /artifact-migrate.
Derived từ test-design.md → test-design đổi thì REGENERATE.

CHỈ TẠO file này khi frd.md có `DM-F*` (test-design § Data & Migration Test Cases không rỗng).
  Feature không đụng migration → KHÔNG tạo test-exec-dm.md.

Source of truth: test-design.md > Data & Migration Test Cases.
  - ID = TC-F{NNN}-{seq} inherit từ test-design (Covers DM-F*). KHÔNG tạo ID mới.
  - Coverage master = test-design.md > Traceability Matrix.
-->

# Data & Migration Test Execution: {Feature Name}

**Feature**: {F-XXX} | **Owner**: {owner} | **Status**: {status}

---

## 1. Context

| **Field** | **Detail** |
|---|---|
| **Feature Summary** | {1–2 câu — migration/backfill scope} |
| **DM covered** | {DM IDs — `DM-F{NNN}-001`, ...} |
| **Source** | [test-design.md](./test-design.md) — TC IDs (Data & Migration Test Cases) + Traceability Matrix |
| **Migration artifact** | {ref script/EF migration: `{migration-name}` hoặc path} |

---

## 2. Dataset & Migration Setup

> Migration chạy trên dataset **prod-like** — không phải seed nhỏ. Phải snapshot trước để so khớp.

| **Field** | **Detail** |
|---|---|
| **Dataset** | {vd: 10.000 bản ghi địa chỉ format cũ — nguồn / cách load} |
| **Pre-condition chung** | Migration script đã review · dataset prod-like đã load vào env test |
| **Snapshot before** | count + checksum trước migration (baseline để assert) |
| **Rollback plan** | {cách revert nếu migration fail — backup/restore / down-migration} |

---

## 3. DM Execution

> **Input:** test-design.md § Data & Migration Test Cases (TC ID, expected — đếm/so khớp).
> **Kết quả chạy (pass/fail) KHÔNG ở đây** — ghi ở `test-report.md` của bundle (Results). Doc này chỉ là spec.

| **TC ID** | **Covers** | **Pre-condition** | **Migration Command** | **Expected** | **Priority** |
|---|---|---|---|---|---|
| `TC-F{NNN}-060` | `DM-F{NNN}-001` | Dataset prod-like loaded ({N} bản ghi cũ) · snapshot baseline | `{migration-command}` | count sau = count trước ({N}/{N}) · 0 null · format mới parse đúng | 🔴 P0 |

---

## 4. Exit Criteria

- [ ] Mọi DM P0 TC pass — data cũ nguyên vẹn (count + checksum khớp)
- [ ] 0 bản ghi mất / null / lỗi parse sau migration
- [ ] Rollback đã verify chạy được (dry-run hoặc trên copy)
- [ ] Result đã ghi ở `test-report.md` (Results) đầy đủ cho mọi DM TC

---

## 5. Change Log

| **Date** | **Cycle** | **Changes** | **Author** |
|---|---|---|---|
| {YYYY-MM-DD} | {cycle/release} | Initial DM execution (derive từ test-design.md) | {Author} |
