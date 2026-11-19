#!/usr/bin/env bash
# Realtime audit distiller hook (Bước 4, 011 §Bước 4). $1 = tên hook event.
# Hook harness kích (NGOÀI agent) → giữ Cấp 2, auditor ≠ auditee (007 §8).
# Đọc payload trên stdin → distill_hook.py upsert 1 dòng vào .specs/audit/logs.jsonl.
# LUÔN exit 0 — best-effort, KHÔNG BAO GIỜ chặn tool (python vắng / lỗi cũng nuốt êm).
# Self-contained: gọi distill_hook.py NẰM CÙNG THƯ MỤC (hooks/audit/ ở repo, .claude/hooks/audit/ ở
# consumer) — không phụ thuộc $CLAUDE_PROJECT_DIR/bin, đúng cả sau khi copy đi nơi khác.
DIR="$(cd "$(dirname "$0")" && pwd)"
# Ghim root vào project dir — nếu không, distill_hook.py fallback về payload["cwd"],
# khiến mỗi session/subagent chạy ở thư mục con tự đẻ một .specs/audit/ riêng.
export AUDIT_ROOT="${AUDIT_ROOT:-$CLAUDE_PROJECT_DIR}"
python3 "$DIR/distill_hook.py" "$1" 2>/dev/null || true
exit 0
