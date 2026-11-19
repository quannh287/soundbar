# -*- coding: utf-8 -*-
# Phần quyết định của Stop hook `implement-guard.sh` — 6 bước của D18c-order.
# In ra stdout: `PASS` hoặc `BLOCK\n{slug}`. KHÔNG BAO GIỜ raise ra ngoài.
import json, os, sys, glob, subprocess, re

CEILING = 10   # trần cứng/lượt — dây bảo hiểm, không phải cơ chế chính

def out(code, *rest):
    # Giao thức với implement-guard.sh: dòng 1 = CODE, dòng 2 = slug, dòng 3 = đường dẫn
    # log (tương đối với root). Dòng 3 cần vì với --worktree=y log KHÔNG nằm ở
    # .specs/integrations/{slug}/ — in sai chỗ là dev đi tìm một file không tồn tại.
    print(code)
    for r in rest:
        print(r)
    sys.exit(0)

try:
    d = json.loads(sys.argv[1])
except Exception:
    out("PASS")

session = d.get("session_id") or ""
cwd = d.get("cwd") or os.getcwd()
first_block = not bool(d.get("stop_hook_active"))

root = cwd
while root != "/" and not os.path.isdir(os.path.join(root, ".specs")):
    root = os.path.dirname(root)
if not os.path.isdir(os.path.join(root, ".specs")):
    out("PASS")

# --- 1. có marker? -----------------------------------------------------------
markers = sorted(glob.glob(os.path.join(root, ".specs", "integrations", "*", ".implement-running")))
if not markers:
    out("PASS")

def rm(p):
    try:
        os.remove(p)
    except OSError:
        pass

# --- 2. marker của session mình? ---------------------------------------------
# Nhiều lượt /implement song song (mỗi lượt một worktree) ⇒ chỉ xử marker của
# CHÍNH session này. Marker của session khác: không đụng, không xoá.
mine = None
for m in markers:
    try:
        lines = open(m).read().split("\n")
    except OSError:
        continue
    if lines and lines[0].strip() == session:
        mine = (m, lines)
        break
if mine is None:
    out("PASS")

marker, lines = mine
slug = os.path.basename(os.path.dirname(marker))

# Log ở đâu: cạnh marker (chế độ thường), HOẶC trong worktree.
# `/implement --worktree=y` chuyển toàn bộ artifact của integration vào
# `.claude/worktrees/{slug}/.specs/…` (xem build/SKILL.md Bước 0b), trong khi marker do
# hook ghi vẫn nằm ở cây chính. Chỉ tìm cạnh marker thì guard **tự tháo ngòi** đúng ở chế
# độ chạy dài nhất: không thấy log ⇒ rơi vào nhánh "chưa có log" ⇒ xoá marker, cho qua.
CANDIDATES = [
    os.path.join(os.path.dirname(marker), "implement-log.md"),
    os.path.join(root, ".claude", "worktrees", slug, ".specs", "integrations", slug, "implement-log.md"),
]
log = next((c for c in CANDIDATES if os.path.isfile(c)), None)

# --- 3. có implement-log.md? -------------------------------------------------
# PreToolUse bắn TRƯỚC khi skill chạy ⇒ permission bị từ chối thì marker có mà log chưa.
if log is None:
    rm(marker)
    out("PASS")

try:
    body = open(log, encoding="utf-8").read()
except OSError:
    out("PASS")

# --- 4. Run cuối có dòng step=outcome? (QUYẾT ĐỊNH) --------------------------
# `outcome` chứ không phải "thành công": `result=stopped` cũng thoát ở đây ⇒ dừng
# đúng luật thì không bị giục.
# Log là logfmt (`- [x] key=value …`) — xem templates/integrations/implement-log-template.md.
runs = [m.start() for m in re.finditer(r"(?m)^## Run ", body)]
tail = body[runs[-1]:] if runs else body
if re.search(r"(?m)^- \[[x ]\][^\n]*\bstep=outcome\b", tail):
    rm(marker)
    out("PASS")

# --- 5. có tiến triển kể từ lần chặn trước? (CẦU CHÌ) -----------------------
nlines = body.count("\n")
try:
    head = subprocess.check_output(
        ["git", "-C", root, "rev-parse", "--short", "HEAD"],
        stderr=subprocess.DEVNULL).decode().strip()
except Exception:
    head = "?"

prev = (lines[1] if len(lines) > 1 else "").strip()
try:
    count = int((lines[2] if len(lines) > 2 else "0").strip() or "0")
except ValueError:
    count = 0

now = "%s %d" % (head, nlines)

if count >= CEILING:
    out("PASS")

# Lần chặn ĐẦU trong lượt (stop_hook_active=false) thì không có mốc để so — chặn.
# Lần sau: mốc không đổi ⇒ lần nhắc trước không đẻ ra gì ⇒ THẢ, đừng đốt token.
if not first_block and prev and prev == now:
    out("PASS")

# --- 6. chặn + cập nhật mốc --------------------------------------------------
try:
    with open(marker, "w") as f:
        f.write("%s\n%s\n%d\n" % (session, now, count + 1))
except OSError:
    out("PASS")

out("BLOCK", slug, os.path.relpath(log, root))
