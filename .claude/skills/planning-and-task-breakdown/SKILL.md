---
name: planning-and-task-breakdown
description: Strategy guide for breaking work into ordered, verifiable tasks — format-agnostic. Covers dependency mapping, vertical slicing, and task sizing. Invoked by wrapper skills (e.g. /plan) that own the output format; can also be used standalone.
---

# Planning and Task Breakdown

## Overview

Strategy guide for decomposing work into small, verifiable tasks. This skill is **format-agnostic** — it defines *how to think* about breakdown (dependency mapping, slicing, sizing), not *how to write* the output. Output format is owned by the caller (e.g. `/plan` defines the exact markdown structure for SDD projects).

Good task breakdown is the difference between an agent that completes work reliably and one that produces a tangled mess. Every task should be small enough to implement, test, and verify in a single focused session.

## When to Use

- You have a spec and need to break it into implementable units
- A task feels too large or vague to start
- Work needs to be parallelized across multiple agents or sessions
- You need to communicate scope to a human
- The implementation order isn't obvious

**When NOT to use:** Single-file changes with obvious scope, or when the spec already contains well-defined tasks.

## The Planning Process

### Step 1: Enter Plan Mode

Before writing any code, operate in read-only mode:

- Read the spec and relevant codebase sections
- Identify existing patterns and conventions
- Map dependencies between components
- Note risks and unknowns

**Do NOT write code during planning.** The output is a plan document, not implementation.

### Step 2: Identify the Dependency Graph

Map what depends on what:

```
Database schema
    │
    ├── Domain models
    │       │
    │       └── Services
    │               │
    │               ├── Validation logic
    │               │
    │               └── API endpoints
    │                       │
    │                       ├── Middleware
    │                       │
    │                       └── Frontend API client
    │                               │
    │                               └── UI components
    │
    └── Seed data / migrations
```

Implementation order follows the dependency graph bottom-up: build foundations first.

### Step 3: Slice Vertically

Instead of building all the database, then all the API, then all the UI — build one complete feature path at a time:

**Bad (horizontal slicing):**
```
Task 1: Build entire database schema
Task 2: Build all API endpoints
Task 3: Build all UI components
Task 4: Connect everything
```

**Good (vertical slicing):**
```
Task 1: User can create an account (schema + API + UI for registration)
Task 2: User can log in (auth schema + API + UI for login)
Task 3: User can create a task (task schema + API + UI for creation)
Task 4: User can view task list (query + API + UI for list view)
```

Each vertical slice delivers working, testable functionality.

### Step 4: Write Tasks

Each task must capture:

- **Title** — short, starts with a verb
- **What it delivers** — one sentence or short paragraph
- **Dependencies** — which tasks must complete first
- **Verification conditions** — specific and testable (not just "tests pass")

**Verification rules:**

| Task type | Verify? | Example |
|-----------|---------|---------|
| Has behavior (service, endpoint, validation) | Yes — specific unit tests | unit tests: valid input, missing field 400, duplicate 409 |
| Pure infrastructure (migration, config) | Yes — smoke check | migration runs clean, rollback succeeds |
| Task IS the test (Verification phase) | Yes — result | integration tests pass — happy path + error cases |
| No behavior (docs, rename, comment) | No | *(omit)* |

Rule: add verification when *"if this code were deleted, which test would fail?"* can be answered. Must be specific enough for an agent to know what to write. Reference AC IDs when the task covers specific criteria.

### Step 5: Order and Slices

**Một slice = một `US-F*`** (`.docs/034` `D0`). Đơn vị chia việc là **Story slice**, không phải phase kỹ thuật — `### Phase 1: Backend` biến thành `### Slice 1 · US-F002-008 — {tiêu đề story}`.

Vì sao story chứ không phải AC: một story thường 2–4 AC nên vòng lặp inner còn chỗ thở; neo từng AC thì mỗi slice chỉ còn một nhịp unit và vòng trong biến mất. Vì sao không phải phase kỹ thuật: `### Phase 1: Backend` xong thì **không người dùng nào làm được gì thêm**, nên không mốc nào nói *"`AC-F002-016` đã đóng"*.

Mỗi slice mang hai dòng neo, ngay dưới heading:

```markdown
### Slice 1 · US-F002-008 — người dùng lưu trữ nhiều việc một lúc

**Outer:** TC-F002-031 · TC-F002-032   ← neo AC-F002-016 · AC-F002-017
**VR:** TC-F002-018 · TC-F002-019      ← neo VR-F002-004 (thuộc US-F002-008)
**depends:** —
```

- `**Outer:**` — TC scope `functional` neo AC của story này. Chúng **mở và đóng** slice: đỏ đầu, xanh cuối.
- `**VR:**` — TC scope `validation` của VR có story này trong `vr[].us`. Chúng **không mở** slice, nhưng slice **không được commit** nếu còn đỏ. Rỗng thì **bỏ hẳn dòng**, không ghi `(không có)`.
- Story không có AC nào ⇒ **không thành slice**.

Task `#### T00N` bên trong giữ nguyên hình dạng hôm nay (Mục tiêu · depends · Các bước · Verification).

Arrange tasks so that:

1. Dependencies are satisfied (build foundation first)
2. Each task leaves the system in a working state
3. High-risk tasks are early (fail fast)

**Slice cuối là section cuối — `/plan` không ghi phase nào sau nó** (`.docs/034` `D17`). `AC` và `VR` đã đóng xong bên trong từng slice; `FAC-F*` thì **không vào `plan.md`**: nó neo tầng feature chứ không story nào, chạy ở **④ Verify** do `/spec-test-retrofit-e2e` cầm, mà `/build` bị cấm viết e2e. Đặt task `FAC` ở đây là đặt một dòng `[ ]` không ai được phép tick, và `todo.md` hết là nguồn sự thật về tiến độ ③ Build — `/implement` Bước 4b đếm đúng số dòng đó để biết còn việc hay không.

`### Phase {N}: Review Findings (lần {k})` **không** thuộc luật này: nó do `/review-integration` append **sau** khi build xong, và task trong đó là việc `/build` sửa được.

Đóng sổ cuối lượt build vẫn có, chỉ là **không nằm trong `todo.md`**: nó là Checklist hoàn thành của [`skills/build/SKILL.md`](../build/SKILL.md) — `npm test` xanh hết · `npm run build` sạch · không dead code · tập TC của mọi slice bằng tập row đã điền-hoặc-`⏭`. Chép nó thành task là đặt một gate ở hai chỗ.

## Task Sizing Guidelines

| Size | Files | Scope | Example |
|------|-------|-------|---------|
| **XS** | 1 | Single function or config change | Add a validation rule |
| **S** | 1-2 | One component or endpoint | Add a new API endpoint |
| **M** | 3-5 | One feature slice | User registration flow |
| **L** | 5-8 | Multi-component feature | Search with filtering and pagination |
| **XL** | 8+ | **Too large — break it down further** | — |

If a task is L or larger, it should be broken into smaller tasks. An agent performs best on S and M tasks.

**When to break a task down further:**
- It would take more than one focused session (roughly 2+ hours of agent work)
- You cannot describe the acceptance criteria in 3 or fewer bullet points
- It touches two or more independent subsystems (e.g., auth and billing)
- You find yourself writing "and" in the task title (a sign it is two tasks)

## Parallelization Opportunities

When multiple agents or sessions are available:

- **Safe to parallelize:** Independent feature slices, tests for already-implemented features, documentation
- **Must be sequential:** Database migrations, shared state changes, dependency chains
- **Needs coordination:** Features that share an API contract (define the contract first, then parallelize)

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll figure it out as I go" | That's how you end up with a tangled mess and rework. 10 minutes of planning saves hours. |
| "The tasks are obvious" | Write them down anyway. Explicit tasks surface hidden dependencies and forgotten edge cases. |
| "Planning is overhead" | Planning is the task. Implementation without a plan is just typing. |
| "I can hold it all in my head" | Context windows are finite. Written plans survive session boundaries and compaction. |

## Red Flags

- Starting implementation without a written task list
- Tasks that say "implement the feature" without acceptance criteria
- No verification steps in the plan
- All tasks are XL-sized
- No checkpoints between tasks
- Dependency order isn't considered

## Verification

Before starting implementation, confirm:

- [ ] Every task with behavior has specific verification conditions (not just "tests pass")
- [ ] Task dependencies are identified and ordered correctly
- [ ] No task touches more than ~5 files
- [ ] Lúc plan vừa ghi ra, section cuối của `## Tasks` là một `### Slice N`, và không task nào neo `FAC-F*` (034 `D17`). `### Phase {N}: Review Findings` thì khác — `/review-integration` append sau, và task trong đó `/build` sửa được
- [ ] todo.md is in sync with plan.md (same slices, same task IDs)
- [ ] The human has reviewed and approved the plan
