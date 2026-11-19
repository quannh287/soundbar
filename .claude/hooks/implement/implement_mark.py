# -*- coding: utf-8 -*-
# Phần ghi marker của hook `implement-mark.sh`.
#
# HAI đường vào, vì `/implement` khởi động được bằng hai cách KHÁC NHAU về mặt hook:
#
#   1. `UserPromptSubmit` — người gõ `/implement 004`. Đo được: slash command chạy skill
#      NHƯNG **không** sinh tool call `Skill` nào, nên PreToolUse im. Đây là cách dùng
#      phổ biến nhất; chỉ cắm PreToolUse thì cả tầng hook nằm im đúng ở ca hay gặp nhất.
#   2. `PreToolUse` matcher `Skill` — model tự invoke (vd một skill khác gọi `/implement`).
#
# Cả hai ghi cùng một marker, cùng nội dung ⇒ bắn cả hai cũng chỉ ghi đè chính nó.
# Im lặng với mọi thứ khác. LUÔN exit 0.
import json, os, sys, glob, re

try:
    d = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)

event = d.get("hook_event_name")
argstr = None

if event == "UserPromptSubmit":
    # Chỉ nhận `/implement …` ở ĐẦU prompt — nhắc tới giữa câu ("đừng chạy /implement")
    # không phải là chạy nó.
    m = re.match(r"\s*/implement\b(.*)", (d.get("prompt") or "").split("\n")[0])
    if not m:
        sys.exit(0)
    argstr = m.group(1)
else:
    if d.get("tool_name") != "Skill":
        sys.exit(0)
    ti = d.get("tool_input") or {}
    if ti.get("skill") != "implement":
        sys.exit(0)
    argstr = ti.get("args") or ""

session = d.get("session_id") or ""
cwd = d.get("cwd") or os.getcwd()

# root = thư mục gần nhất từ cwd đi lên có .specs/
root = cwd
while root != "/" and not os.path.isdir(os.path.join(root, ".specs")):
    root = os.path.dirname(root)
if not os.path.isdir(os.path.join(root, ".specs")):
    sys.exit(0)

# slug = token đầu tiên của args, bỏ mọi cờ --…
tokens = [a for a in argstr.split() if not a.startswith("--")]
if not tokens:
    sys.exit(0)
key = tokens[0]

dirs = sorted(glob.glob(os.path.join(root, ".specs", "integrations", "*")))
dirs = [x for x in dirs if os.path.isdir(x)]
match = None
for x in dirs:
    name = os.path.basename(x)
    if name == key or name.startswith(key + "-") or name.startswith(key.zfill(3) + "-"):
        match = x
        break
if match is None:
    # số không zero-pad: `2` → `002-…`
    m = re.fullmatch(r"\d+", key)
    if m:
        pad = key.zfill(3)
        for x in dirs:
            if os.path.basename(x).startswith(pad + "-"):
                match = x
                break
if match is None:
    sys.exit(0)

# dòng 1 = session_id · dòng 2 = mốc lần chặn trước (rỗng) · dòng 3 = số lần chặn
with open(os.path.join(match, ".implement-running"), "w") as f:
    f.write(session + "\n\n0\n")
