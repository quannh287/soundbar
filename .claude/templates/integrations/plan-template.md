---
id: "{id}"
slug: "{slug}"
title: "{title}"
features: []
components: []
status: draft
approved_by:
created: {YYYY-MM-DD}
referenced_by:
  - 02-artifacts.md > 3. Integration Artifacts > 3.5 plan.md > Cấu trúc
  - skills/plan/SKILL.md > Output Format > plan.md
---

<!-- approved_by: để RỖNG nghĩa là người duyệt. `implement` nghĩa là /implement stamp
     status: approved trong auto-mode — plan này chưa từng qua mắt người. -->

## Summary

<!-- Mô tả ngắn những gì sẽ được implement trong integration này -->

## Dependency Graph

```
<!-- ASCII diagram — bottom = foundations, top = UI. Ví dụ:

Database schema
    │
    ├── Domain models
    │       │
    │       └── Services
    │               │
    │               └── API endpoints
    │                       │
    │                       └── UI components
-->
```

## Tasks

### Slice 1 · {US-F*} — {tiêu đề story}

<!--
ĐƠN VỊ CHIA VIỆC LÀ STORY SLICE, không phải phase kỹ thuật (.docs/034 D0).
Mỗi slice neo ĐÚNG MỘT US-F*; story không có AC nào thì không thành slice.

**Outer:** TC scope functional neo AC của story này — MỞ và ĐÓNG slice (đỏ đầu, xanh cuối).
**VR:**    TC scope validation của VR có story này trong vr[].us — KHÔNG mở slice, nhưng
           slice không được commit nếu còn đỏ. Rỗng thì BỎ HẲN DÒNG.

MỌI SLICE ĐỀU LÀ STORY SLICE — /plan không ghi phase nào sau slice cuối (034 D17). FAC-F*
không vào plan.md: nó neo tầng feature, chạy ở ④ Verify do /spec-test-retrofit-e2e cầm, và
/build bị cấm viết e2e. Đặt task FAC ở đây là đặt một dòng không ai được phép tick.
(`### Phase {N}: Review Findings` thì khác — /review-integration append sau khi build xong.)

KHÔNG nêu giá trị data-testid và KHÔNG lập task riêng cho selector-contract (026 D1 —
phần còn hiệu lực). Contract là việc của /build.
-->

**Outer:** {TC-F*} · {TC-F*}
**VR:** {TC-F*}
**depends:** —

#### T001 · {task title — bắt đầu bằng động từ}

**Mục tiêu:** {One sentence: what this task delivers}

**depends:** —

**Các bước:**
1. {Concrete implementation step}
2. {Concrete implementation step}

**Verification:**
- [ ] {specific test case hoặc observable result}

---

#### T002 · {task title}

**Mục tiêu:** {One sentence}

**depends:** T001

**Các bước:**
1. {Concrete implementation step}

**Verification:**
- [ ] {specific test case hoặc observable result}

---

## Definition of Done

<!-- Điều kiện để xem integration này là complete -->
<!-- Map 1-1 với Acceptance Criteria VÀ Verification Rules trong spec.md.
     Mỗi ID một dòng, ghi ID NGUYÊN VĂN: /implement Bước 3 trừ tập (AC ∪ VR)(nguồn) \ DoD,
     nên một điều kiện tả bằng văn xuôi không có ID sẽ bị báo thiếu dù plan đã làm. -->

- [ ] {AC-ID} — {condition từ spec.md AC}
- [ ] {VR-ID} — {rule ngắn từ bảng VR của spec.md}
