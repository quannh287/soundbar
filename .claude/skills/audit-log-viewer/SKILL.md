---
name: audit-log-viewer
description: Mở viewer human-readable cho audit-trail (.specs/audit/audit-log.jsonl). Tự khởi động một local HTTP server (localhost-only, port ngẫu nhiên) phục vụ audit-log-viewer.html rồi gửi link localhost cho user xem — timeline theo unit, realtime (log tự đầy khi làm việc), scroll lên để xem unit cũ, click để preview diff/tool-result. Server chạy nền, dừng bằng kill PID. Dùng khi user muốn "xem audit log", "mở audit viewer", "/audit-log-viewer". Không publish ra ngoài — dữ liệu ở lại máy.
---

# audit-log-viewer

## Overview

Bật **viewer** cho audit-trail: một trang HTML tương tác đọc thẳng `.specs/audit/audit-log.jsonl` (+ sidecar `diff/`, `tool-results/`) **realtime**, chạy qua **local server** (vì `file://` không `fetch()` được sibling file).

Skill này KHÔNG sinh/parse log — chỉ **khởi động server** `.claude/audit/serve.py` và **gửi link localhost** cho user. Distiller (hook) mới là thứ ghi log; viewer chỉ đọc.

> **Local-only, không rời máy.** Server bind `127.0.0.1` (không lộ LAN). Audit-log chứa nguyên văn prompt + diff + tool-input → **tuyệt đối không** publish ra Artifact/claude.ai/host ngoài.

## When to Use

- User muốn xem audit-trail người-đọc: "xem audit log", "mở audit viewer", gõ `/audit-log-viewer`.
- Muốn theo dõi trail **realtime** trong lúc làm việc (viewer poll, tự hiện event mới).

## When NOT to Use

- Muốn **query/grep** log theo script → dùng thẳng `jq`/`grep` trên `.specs/audit/audit-log.jsonl` + sidecar.
- Chưa cài audit (`.claude/audit/serve.py` không tồn tại) → chưa chạy `npx spec-lite install` hoặc kit chưa có audit; báo user.

---

## Process

Đặt `ROOT = $CLAUDE_PROJECT_DIR` (nếu không có, dùng cwd hiện tại). Mọi path dưới đây tương đối `ROOT`.

### Bước 1 — `/audit-log-viewer stop` (nếu user yêu cầu dừng)

Nếu argument là `stop`: đọc `.specs/audit/.viewer` (dạng `<PID> <URL>`); nếu PID còn sống (`kill -0 <PID>`) → `kill <PID>`, báo đã dừng. Xong.

### Bước 2 — Tái dùng server đang chạy (idempotent)

Đọc `.specs/audit/.viewer` nếu có:
- Có `<PID> <URL>` và `kill -0 <PID>` thành công (còn sống) → **KHÔNG spawn mới**; gửi lại `<URL>` cho user (Bước 4). Xong.
- File không có / PID chết → sang Bước 3 (spawn mới). (File cũ mồ côi sẽ bị server mới ghi đè.)

### Bước 3 — Khởi động server nền

Kiểm `.claude/audit/serve.py` tồn tại; không có → báo user cài audit trước (`npx spec-lite install`), dừng.

Chạy **nền** (Bash `run_in_background: true`):

```bash
python3 "$CLAUDE_PROJECT_DIR/.claude/audit/serve.py" --root "$CLAUDE_PROJECT_DIR"
```

Đợi ~1s rồi đọc output nền, bắt dòng `AUDIT_VIEW_URL=<url>` (server in ra ngay khi bind xong). Không thấy sau vài giây → đọc stderr báo lỗi cho user (vd thiếu `audit-log-viewer.html`), dừng.

### Bước 4 — Gửi link cho user

Báo gọn:
- **Link:** `<url>` (localhost — user mở bằng trình duyệt).
- Server chạy **nền**, PID `<pid>` (đọc từ dòng `... (PID <pid> ...)` hoặc `.viewer`).
- **Dừng:** `/audit-log-viewer stop` hoặc `kill <pid>`.
- Nhắc: viewer **realtime** (tự cập nhật khi log đầy thêm); **scroll lên** để tải unit cũ; **click** `input`/`result`/`diff` để xem chi tiết; dữ liệu **chỉ ở localhost**.

---

## Notes

- **Không tự mở browser** — chỉ gửi link (môi trường có thể headless). User tự click/mở. (serve.py có `--open` nhưng skill không dùng.)
- **`.viewer` + `.lock` là file runtime** trong `.specs/audit/` — ephemeral, không nên commit (thêm vào `.gitignore` nếu nhiễu).
- Server đọc-only, phục vụ đúng 4 route whitelist (viewer + log + `diff/` + `tool-results/`), chống path-traversal — an toàn chạy nền.

## Verification

- [ ] `ROOT` = `$CLAUDE_PROJECT_DIR` (fallback cwd); mọi path tương đối ROOT.
- [ ] `stop` → kill PID trong `.viewer` nếu còn sống.
- [ ] Tái dùng khi `.viewer` PID còn sống (không spawn trùng).
- [ ] Spawn nền `serve.py`, bắt `AUDIT_VIEW_URL`, gửi link + PID + cách dừng.
- [ ] Không publish ra ngoài; nhắc realtime + scroll-up + click preview.
