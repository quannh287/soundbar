#!/usr/bin/env bash
# Hook ghi marker "có lượt /implement đang dở". Cắm ở HAI event:
#   UserPromptSubmit  — người gõ `/implement 004` (slash command KHÔNG sinh tool call
#                       `Skill` nào, đo được — chỉ cắm PreToolUse là tầng hook nằm im
#                       đúng ở cách dùng phổ biến nhất)
#   PreToolUse/Skill  — model tự invoke
# Cả hai ghi cùng một marker, cùng nội dung ⇒ bắn cả hai cũng vô hại.
#
# Vì sao tầng hook tự ghi marker thay vì để skill tự tạo: **agent không biết
# session_id của chính nó**. Payload PreToolUse có; agent thì không. Và để hook
# sở hữu trọn vòng đời marker thì tháo hook ra là kit vẫn nguyên vẹn.
#
# Payload (đã đo):
#   PreToolUse       { tool_name: "Skill", tool_input: { skill, args }, session_id, cwd }
#   UserPromptSubmit { prompt, session_id, cwd, prompt_id, transcript_path, permission_mode }
# Chỉ hành động khi skill là `implement` (hoặc prompt mở đầu bằng `/implement`) —
# mọi thứ khác đi qua im lặng.
# LUÔN exit 0: đây là hook ghi chú, không phải hook gác.
set -u
command -v python3 >/dev/null 2>&1 || exit 0

PAYLOAD="$(cat)" || exit 0

DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$DIR/implement_mark.py" "$PAYLOAD" 2>/dev/null || true
exit 0
