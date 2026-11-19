#!/usr/bin/env bash
# Kiểm hậu điều kiện của một lượt /implement — chạy TRƯỚC MERGE.
#   .claude/hooks/implement/check-implement-postcondition.sh {slug}
#
# Ba điều kiện (02-artifacts.md §3.9) — spec_gap/spec_drift KHÔNG phải điều kiện, chỉ in ra
# (029 D8 · 036 D0):
#   1. todo.md không còn dòng `- [ ]`
#   2. reviewed_sha của vòng review CUỐI trong implement-log.md == HEAD
#   3. vòng review đó ghi sạch (0C/0I)
#
# Điều kiện 2 là cái dễ bỏ sót nhất: sha review cuối != HEAD nghĩa là code đã đổi
# SAU lần review cuối ⇒ workflow chưa hoàn tất, BẤT KỂ log viết gì.
#
# Script này KHÔNG phụ thuộc model — đó là điểm của nó. /implement tự assert cũng
# tốt, nhưng đó vẫn là model tự kiểm chính nó.
#
# exit 0 = đạt · exit 1 = không đạt · exit 2 = không kiểm được (thiếu file/không phải git repo)
set -u

SLUG="${1:-}"
if [ -z "$SLUG" ]; then
  echo "dùng: $(basename "$0") {slug}" >&2
  exit 2
fi

# Root = thư mục gần nhất (từ cwd đi lên) có .specs/ — KHÔNG dùng git toplevel, vì
# một project có .specs/ có thể nằm trong repo lớn hơn (vd pilot-app/ trong spec-kit).
ROOT="$PWD"
while [ "$ROOT" != "/" ] && [ ! -d "$ROOT/.specs" ]; do ROOT="$(dirname "$ROOT")"; done
[ -d "$ROOT/.specs" ] || { echo "⛔ không tìm thấy .specs/ từ $PWD đi lên" >&2; exit 2; }
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || { echo "⛔ $ROOT không nằm trong git repo" >&2; exit 2; }
# Artifact của integration nằm ở đâu — MỘT quy tắc, dùng chung với implement_guard.py:
#   `/implement --worktree=y` chuyển plan/todo/techdebt/log vào worktree (build/SKILL.md
#   Bước 0b), còn cây chính thì không có chúng. Chỉ nhìn cây chính là script báo
#   "không có todo.md" cho một lượt hoàn hảo — sai kiểu tệ nhất: phủ nhận việc đã làm đúng.
# TREE = cây git để hỏi HEAD. Với worktree, HEAD của cây chính là BASE branch, không phải
#   feat/{slug} ⇒ hỏi nhầm cây thì `reviewed_sha != HEAD` luôn luôn, cũng sai kiểu đó.
WT="$ROOT/.claude/worktrees/$SLUG/.specs/integrations/$SLUG"
if [ -d "$WT" ]; then
  DIR="$WT"
  TREE="$ROOT/.claude/worktrees/$SLUG"
  echo "ⓘ artifact nằm trong worktree: .claude/worktrees/$SLUG/"
else
  DIR="$ROOT/.specs/integrations/$SLUG"
  TREE="$ROOT"
fi
TODO="$DIR/todo.md"
LOG="$DIR/implement-log.md"

[ -d "$DIR" ] || { echo "⛔ không có integration: $DIR" >&2; exit 2; }
[ -f "$TODO" ] || { echo "⛔ không có todo.md: $TODO" >&2; exit 2; }
[ -f "$LOG" ]  || { echo "⛔ không có implement-log.md — /implement chưa từng chạy cho $SLUG" >&2; exit 2; }

fail=0

# --- 1. todo.md hết [ ] ------------------------------------------------------
pending="$(grep -c '^- \[ \]' "$TODO" 2>/dev/null || true)"
pending="${pending:-0}"
if [ "$pending" -eq 0 ]; then
  echo "✓ todo.md: hết task [ ]"
else
  echo "✗ todo.md: còn $pending task [ ]"
  grep -n '^- \[ \]' "$TODO" | head -5
  fail=1
fi

# --- logfmt helper ----------------------------------------------------------
# Log là logfmt: `- [x] key=value key=value …` (templates/integrations/implement-log-template.md).
# Đọc value theo TÊN KEY, không theo vị trí — thêm key mới không vỡ phép kiểm này.
kv() {  # kv <dòng> <key>  →  value (rỗng nếu không có)
  printf '%s' "$1" | tr ' ' '\n' | sed -nE "s/^$2=(.*)$/\1/p" | head -1
}

# --- 2 + 3. dòng review CUỐI trong log --------------------------------------
last_review="$(grep -E '^- \[[x ]\][^\n]*\bstep=review\b' "$LOG" | tail -1 || true)"
if [ -z "$last_review" ]; then
  echo "✗ implement-log.md: không có dòng review nào — 'review chưa từng chạy' không phân biệt được với 'đã chạy và sạch' nếu thiếu dòng này"
  fail=1
else
  echo "  dòng review cuối: $last_review"

  rsha="$(kv "$last_review" sha)"
  head_sha="$(git -C "$TREE" rev-parse --short HEAD)"

  if [ -z "$rsha" ]; then
    echo "✗ không đọc được reviewed_sha từ dòng review cuối (thiếu 'sha=')"
    fail=1
  elif ! git -C "$TREE" cat-file -e "$rsha^{commit}" 2>/dev/null; then
    echo "✗ sha review cuối ($rsha) không tồn tại trong repo — log tự khai, không đối chiếu được"
    fail=1
  elif [ "$(git -C "$TREE" rev-parse "$rsha")" = "$(git -C "$TREE" rev-parse HEAD)" ]; then
    echo "✓ sha review cuối == HEAD ($head_sha)"
  elif ! git -C "$TREE" merge-base --is-ancestor "$rsha" HEAD 2>/dev/null; then
    echo "✗ sha review cuối ($rsha) không phải tổ tiên của HEAD ($head_sha) — log lệch history"
    fail=1
  else
    # Sau vòng review cuối có commit thêm. Chỉ ĐỘNG ĐẾN artifact của integration này thì
    # KHÔNG phải "code đã đổi": đó là sổ sách của chính lượt chạy — `implement-log.md`
    # (bằng chứng, D22, phải nằm trong tag), `techdebt.md` + `spec-debt.md` + Phase Review
    # trong `plan.md` (do vòng review GHI RA, và `/build` không commit hộ), `todo.md`.
    # Miễn theo THƯ MỤC chứ không theo tên file: hậu điều kiện nói về CODE, và mọi thứ dưới
    # .specs/integrations/{slug}/ đều không phải code. Danh sách tên file thì mỗi lần kit
    # thêm một artifact review là script fail cho một lượt hoàn hảo.
    # Thêm ĐÚNG MỘT đường dẫn ngoài thư mục đó: sổ nợ của BA cạnh frd
    # (.specs/main/feature/{F}/spec-debt.md, .docs/039) — review ghi vào đó sau sha nó chấm.
    # Phần còn lại của .specs/main/ KHÔNG miễn — /implement không được sửa main, thấy là phải fail.
    # Đo NET thay đổi (rsha..HEAD), không đo từng commit: điều cần biết là "code có khác so
    # với lúc review không", không phải "đã có bao nhiêu commit".
    changed="$(git -C "$TREE" diff --name-only "$rsha" HEAD)"
    other="$(printf '%s\n' "$changed" | grep -v "^\.specs/integrations/$SLUG/" \
      | grep -vE '^\.specs/main/feature/[^/]+/spec-debt\.md$' | grep -v '^[[:space:]]*$' || true)"
    if [ -z "$other" ]; then
      echo "✓ sha review cuối ($rsha) != HEAD ($head_sha), nhưng net diff CHỈ chạm .specs/integrations/$SLUG/ + sổ nợ cạnh frd"
      echo "  ⇒ code không đổi kể từ lần review cuối"
    else
      echo "✗ sha review cuối ($rsha) != HEAD ($head_sha) — code đã đổi SAU lần review cuối"
      echo "  file đổi ngoài .specs/integrations/$SLUG/ và sổ nợ cạnh frd:"
      printf '%s\n' "$other" | head -10 | sed 's/^/    /'
      echo "  commit thêm sau lần review đó:"
      git -C "$TREE" --no-pager log --oneline "$rsha..HEAD" | head -10 | sed 's/^/    /'
      fail=1
    fi
  fi

  crit="$(kv "$last_review" critical)"; imp="$(kv "$last_review" important)"
  if [ "$crit" = "0" ] && [ "$imp" = "0" ]; then
    echo "✓ vòng review cuối: sạch"
  else
    echo "✗ vòng review cuối còn Critical/Important (critical=${crit:-?} important=${imp:-?})"
    fail=1
  fi

  # spec_drift KHÔNG còn là điều kiện (036 D0): code làm khác AC có lý do ⇒ một trong hai bên
  # sai, chỉ BA biết bên nào — đó là nợ của BA như gap, ghi `SD-*` vào sổ rồi đi tiếp. Log cũ
  # (`drift=true|false`, `reason=spec_drift`) vẫn qua được script: ca drift=true cũ luôn đi
  # kèm `result=stopped`, và mục 4 dưới đã fail ca đó.

  # spec_gap là THÔNG TIN, không phải điều kiện (029 D8): code đã đúng với spec approved,
  # gap là nợ của BA mà chỉ /spec-new trả được. Chặn merge vì spec THIẾU là giữ integration
  # làm con tin. In ra để nợ không chìm sau merge; KHÔNG đụng $fail.
  #
  # ĐỌC TỪ SỔ, KHÔNG đọc key `spec_gap=` của dòng review cuối: key đó đếm gap MỚI MỞ ở
  # vòng đó, nên một lượt mở 2 gap ở vòng 1 rồi vòng 2 sạch sẽ in `spec_gap=0` trong khi sổ
  # còn 2 dòng mở — đúng kiểu nợ chìm mà 029 D1 dựng cơ chế này để tránh. Sổ là nguồn sự thật.
  #
  # Hai con số riêng (029 DS7): chưa quyết = `- [ ]` KHÔNG có `→` (chờ BA) · đang làm =
  # `- [ ]` CÓ `→ {slug}` (đã lên spec, chờ integration đó xong).
  # Sổ nợ của BA là MỘT sổ mỗi feature, cạnh frd (.docs/039) — không còn sổ của integration.
  # Đếm những mục THUỘC đợt này: mục có dòng `**phát hiện:**` chứa `của `{slug}``. Sổ của feature
  # chứa cả nợ do ④ Verify hay đợt khác thấy — đếm cả sổ là báo nợ của người khác vào lượt này.
  SPEC="$DIR/spec.md"; [ -f "$SPEC" ] || SPEC="$ROOT/.specs/integrations/$SLUG/spec.md"
  FEATS="$(sed -n 's/^features:[[:space:]]*\[\(.*\)\].*/\1/p' "$SPEC" 2>/dev/null | head -1 \
    | tr -d ' "'"'"'' | tr ',' '\n' | grep -E '^F-[0-9]+' || true)"
  if [ -f "$DIR/spec-debt.md" ]; then
    echo "ⓘ sổ nợ spec kiểu cũ: $DIR/spec-debt.md — chạy: npx spec-lite migrate-spec-debt"
  fi
  MUC=""
  for F in $FEATS; do
    for BOOK in "$TREE"/.specs/main/feature/"$F"-*/spec-debt.md; do
      [ -f "$BOOK" ] || continue
      MUC="$MUC$(awk -v s="của \`$SLUG\`" '
        /^- \[[ x]\] \*\*S[GD]-/ { if (hit) print head; head=$0; hit=0; next }
        index($0, s)            { hit=1 }
        END                     { if (hit) print head }' "$BOOK")
"
    done
  done
  # *đang làm* = có con trỏ `→ {slug}` NGAY SAU số mục (SG) hoặc ngay sau `{ID}` (SD). Không đếm theo
  # "dòng có chứa →": mô tả có thể có `→` (sổ cũ), và một mục chưa quyết bị đếm thành đang làm là nợ chìm.
  CON_TRO='^- \[ \] \*\*S[GD]-[0-9]+\*\*( · `[^`]+`)? →'
  dem() { printf '%s' "$MUC" | grep -E "^- \[ \] \*\*$1-" | { if [ "$2" = wip ]; then grep -cE "$CON_TRO"; else grep -vcE "$CON_TRO"; fi; } || true; }
  gap_open="$(dem SG open)"; gap_wip="$(dem SG wip)"; drift_open="$(dem SD open)"; drift_wip="$(dem SD wip)"
  gap_open="${gap_open:-0}"; gap_wip="${gap_wip:-0}"; drift_open="${drift_open:-0}"; drift_wip="${drift_wip:-0}"
  NEXT="$(printf '%s' "$FEATS" | sed 's/^/\/spec-new /' | tr '\n' ' ')"
  if [ "$gap_open" -gt 0 ]; then
    echo "ⓘ spec_gap: $gap_open chưa quyết — sổ cạnh frd · 👤 $NEXT để BA quyết"
  fi
  if [ "$gap_wip" -gt 0 ]; then
    echo "ⓘ spec_gap: $gap_wip đang làm (đã lên spec, đóng khi /archive integration đó)"
  fi
  if [ "$gap_open" -eq 0 ] && [ "$gap_wip" -eq 0 ] && printf '%s' "$MUC" | grep -qE '^- \[[x ]\] \*\*SG-'; then
    echo "ⓘ spec_gap: mọi gap của đợt này đã được quyết"
  fi
  # Drift còn `[ ]` (kể cả có `→`) thì ④ Verify không sửa code của ID đó — in ra để người merge
  # biết mình đang merge một chỗ lệch đã biết.
  if [ "$drift_open" -gt 0 ]; then
    echo "ⓘ spec_drift: $drift_open chưa quyết — code làm khác AC, chờ BA · 👤 $NEXT"
  fi
  if [ "$drift_wip" -gt 0 ]; then
    echo "ⓘ spec_drift: $drift_wip đang làm (BA chọn sửa requirement, đóng khi /archive integration đó)"
  fi
fi

# --- 4. Run cuối đóng chưa, và đóng bằng gì ---------------------------------
# Trước đây chỗ này chỉ IN RA dòng kết luận, không rẽ nhánh: `✅ xong` và `⏸ dừng hợp lệ`
# giống hệt nhau dưới mắt script. Bốn ca dừng vẫn bị bắt, nhưng NHỜ MAY — các field khác
# tình cờ tương quan (blocked ⇒ todo còn [ ]; k=3 cũng vậy; spec_drift cũ ⇒ drift=true).
# `result=`/`reason=` là tập đóng nên giờ rẽ nhánh thẳng theo lý do dừng.
last_outcome="$(grep -E '^- \[[x ]\][^\n]*\bstep=outcome\b' "$LOG" | tail -1 || true)"
if [ -z "$last_outcome" ]; then
  echo "✗ log chưa có dòng step=outcome — lượt chạy bị đứt giữa chừng, chạy lại /implement $SLUG"
  fail=1
else
  result="$(kv "$last_outcome" result)"
  case "$result" in
    done)
      echo "✓ outcome: result=done" ;;
    stopped)
      echo "✗ outcome: result=stopped reason=$(kv "$last_outcome" reason) — dừng hợp lệ, nhưng CHƯA merge được"
      fail=1 ;;
    *)
      echo "✗ outcome: result=${result:-<rỗng>} không thuộc tập đóng {done, stopped}"
      fail=1 ;;
  esac
fi

# --- 5. mọi dòng neo vào sha THẬT (D19b) ------------------------------------
bad_sha=""
for h in $(grep -oE 'sha=[0-9a-f]{7,40}' "$LOG" | cut -d= -f2 | sort -u); do
  git -C "$TREE" cat-file -e "$h^{commit}" 2>/dev/null || bad_sha="$bad_sha $h"
done
if [ -n "$bad_sha" ]; then
  echo "✗ sha không tồn tại trong repo:$bad_sha — log tự khai, không đối chiếu được"
  fail=1
else
  echo "✓ mọi sha= trong log đều reachable"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "✅ $SLUG — hậu điều kiện ĐẠT, merge được."
  exit 0
fi
echo "⛔ $SLUG — hậu điều kiện KHÔNG đạt. Chạy lại /implement $SLUG rồi kiểm lại."
exit 1
