#!/usr/bin/env bash
# Stop hook — nhắc lại khi model kết lượt trong lúc `implement-log.md` chưa đóng.
#
# LÀ CÁI NHẮC, KHÔNG PHẢI CÁI KẸP. Model kẹt (không đổi được state) là nó thả.
# Nó THU HẸP lỗ đứt-giữa-chừng chứ không bịt kín — nền vẫn là resume-từ-file.
# Đã đo: Ctrl+C/SIGINT KHÔNG kích `Stop`, nên ca đó hook không đỡ.
#
# Đã đo (xem .docs/023-implement-pilot-run.md):
#   · `exit 2` CHẶN được event `Stop`, stderr được feed lại cho model  ✓
#   · `stop_hook_active` = false ở lần chặn đầu, true sau khi đã chặn  ✓
#   · subagent gọi Skill mang CÙNG session_id với main                 ✓
#
# THỨ TỰ 6 BƯỚC LÀ RÀNG BUỘC ĐÚNG-SAI, không phải mô tả:
#   1. có marker?                                    không → exit 0
#   2. marker của session mình?                      không → exit 0 (việc của session khác)
#   3. có implement-log.md?                          không → rm marker, exit 0
#   4. Run cuối CÓ dòng step=outcome?                    có   → rm marker, exit 0   ← self-heal
#   5. có tiến triển kể từ lần chặn trước?           không → exit 0 (thả)
#   6.                                                     → exit 2 + cập nhật mốc
# Bước 4 PHẢI đứng trước bước 5. Đảo lại thì một lượt VỪA HOÀN THÀNH (ghi `step=outcome`
# ⇒ log dài ra ⇒ "có tiến triển") sẽ bị chặn. `implement-log.md` là QUYẾT ĐỊNH;
# tiến triển chỉ là CẦU CHÌ, chỉ được hỏi khi bước 4 đã nói "còn mở".
#
# FAIL-OPEN TUYỆT ĐỐI. Hook này chặn được lượt của người dùng; nó lỗi thì phải im,
# không được khoá ai ra khỏi session của họ.
set -u

command -v python3 >/dev/null 2>&1 || exit 0

PAYLOAD="$(cat)" || exit 0

DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$(python3 "$DIR/implement_guard.py" "$PAYLOAD" 2>/dev/null)" || exit 0

CODE="$(printf '%s' "$OUT" | sed -n '1p')"
SLUG="$(printf '%s' "$OUT" | sed -n '2p')"
LOGPATH="$(printf '%s' "$OUT" | sed -n '3p')"
[ "$CODE" = "BLOCK" ] || exit 0
[ -n "$LOGPATH" ] || LOGPATH=".specs/integrations/${SLUG}/implement-log.md"

# Model chỉ nhận được đúng mấy dòng stderr này, không có ngữ cảnh gì khác
# ⇒ viết như viết cho người lạ, và PHẢI chỉ đường thoát.
cat >&2 <<MSG
⛔ Lượt /implement cho **${SLUG}** chưa đóng.

Block \`## Run\` cuối trong ${LOGPATH}
thiếu dòng \`step=outcome\` ⇒ theo bản ghi thì lượt này vẫn đang dở.

Chọn một trong hai:
  · tiếp tục       → /implement ${SLUG}
  · bỏ dở có chủ ý → rm .specs/integrations/${SLUG}/.implement-running
  · tắt hẳn        → gỡ hook implement-guard khỏi .claude/settings.json

Không state nào phân biệt được "đổi ý" với "bị ngắt", nên nếu bạn cố tình
dừng thì phải xoá marker — nếu không sẽ bị nhắc lại ở lượt không liên quan.
MSG
exit 2
