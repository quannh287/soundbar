---
slug: "{slug}"
created: {YYYY-MM-DD}
referenced_by:
  - 02-artifacts.md > 3. Integration Artifacts > 3.9 implement-log.md
  - skills/implement/SKILL.md > implement-log.md
---

# Implement Log — {title}

<!-- Bản ghi việc ĐÃ làm, không phải bản dự định.

     ĐỊNH DẠNG: logfmt — mọi dòng là `- [x] key=value key=value …`, khoảng trắng ngăn cách.
     Không phải văn xuôi: hai script đọc file này (implement_guard.py ở Stop hook, và
     check-implement-postcondition.sh trước khi merge). Viết tự do là chúng parse trượt.

     BA LUẬT BẮT BUỘC:
     1. Mọi dòng có `step=` thuộc tập đóng: plan · coverage · build · review · finding · outcome
     2. Mọi dòng có `sha=` — sha THẬT, `git cat-file -e {sha}^{commit}` phải qua
     3. Value KHÔNG chứa khoảng trắng, trừ `note=` — và `note=` phải là key CUỐI dòng

     Append block `## Run {n}` mới cho mỗi lượt; KHÔNG ghi đè block cũ.
     Block đóng bằng dòng `step=outcome`; vắng dòng đó = lượt bị đứt giữa chừng. -->

## Run 1

- [x] step=plan     sha={sha} approved_by=implement
- [x] step=coverage sha={sha} missing=0
- [x] step=build    sha={sha-sau} round=1 from={sha-trước} todo_before={n0} todo_after={n1} blocked=none
- [x] step=review   sha={reviewed-sha} round=1 critical={c} important={i} spec_gap={g} spec_drift={d}
- [ ] step=finding  sha={reviewed-sha} round=1 tasks=T00X
- [x] step=build    sha={sha-sau} round=2 from={sha-trước} todo_before={n0} todo_after=0 blocked=none
- [x] step=review   sha={reviewed-sha} round=2 critical=0 important=0 spec_gap=0 spec_drift=0
- [x] step=outcome  sha={sha} result=done

<!-- TỪ ĐIỂN

  step=plan      approved_by=implement|human
  step=coverage  missing={n}  [ids=AC-XXX-001,VR-XXX-006]   ← ids chỉ khi missing>0;
                 tập nguồn là AC ∪ VR (029 D4), nên ids có thể lẫn cả hai tiền tố
  step=build     round={i} from={sha} todo_before={n0} todo_after={n1} blocked={none|yes}
                 vòng bị bỏ vì không còn task:  round=0 skipped=n0-zero   (không có from/todo_*)
  step=review    round={k} critical={c} important={i} spec_gap={g} spec_drift={d}
                 spec_gap = số SG-* MỚI mở ở vòng này (finding không neo được vào
                 AC/VR/FAC/tech.md/GUARD ⇒ spec im lặng, ghi sổ spec-debt.md cạnh frd). Nó là THÔNG TIN:
                 không mở vòng build, không chặn done, không đổi cách rẽ nhánh.
                 spec_drift = số SD-* MỚI mở ở vòng này (code làm khác AC/VR/FAC CÓ dấu vết ⇒
                 chỉ BA biết bên nào đúng, ghi sổ spec-debt.md cạnh frd). Cùng vai THÔNG TIN như spec_gap.
                 Thêm dòng phát hiện vào mục đã có KHÔNG tính vào hai số này.
                 Log trước .docs/036 ghi `drift={true|false}` và có `reason=spec_drift` — đọc
                 như cũ, không phải lỗi định dạng.
  step=finding   round={k} tasks=T008[,T009]                ← CHỈ mở khi review có C/I;
                 để `- [ ]`, tick `- [x]` sau vòng build kế tiếp. Review sạch ⇒ không mở dòng nào
  step=outcome   result=done
                 result=stopped reason={blocked|k3} [note={việc người cần làm}]
                 (vắng dòng outcome) = đứt giữa chừng, gõ lại /implement {slug}

  `sha=` của mỗi dòng là trạng thái repo LÚC bước đó xong — build thì là sha sau,
  review thì là reviewed_sha. Đây là mắt xích để kiểm từ ngoài: reviewed_sha != HEAD
  nghĩa là code đã đổi SAU lần review cuối, dù log có ghi gì. -->
