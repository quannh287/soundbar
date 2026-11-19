#!/usr/bin/env python3
"""serve.py — local viewer server cho audit-trail (011 Bước 7).

Phục vụ `audit-log-viewer.html` + dữ liệu (`audit-log.jsonl` + sidecar) qua HTTP
localhost, để viewer `fetch()` được (file:// bị trình duyệt chặn fetch sibling).

Ràng buộc thiết kế (011 §7 V2):
  * bind 127.0.0.1 ONLY, port ngẫu nhiên (0) — KHÔNG lộ ra LAN.
  * chỉ phục vụ route whitelist (viewer + audit-log + diff/tool-results/says), chống path-traversal.
  * giải mã %23 -> # (id sidecar có '#edit'/'#say').
  * hỗ trợ If-Modified-Since -> 304 (poll realtime rẻ) và Range (load-full file lớn).
  * in `AUDIT_VIEW_URL=<url>` ra stdout để skill /audit-log-viewer đọc & relay.
  * stdlib thuần, zero dep.

Layout (007 §7):
  <viewer_dir>/audit-log-viewer.html        # cạnh serve.py (.claude/audit/)
  <root>/.specs/audit/audit-log.jsonl       # data
  <root>/.specs/audit/diff/<id>             # edit.diff sidecar
  <root>/.specs/audit/tool-results/<id>     # tool.result sidecar
  <root>/.specs/audit/says/<id>             # say.text sidecar (lời agent, 011 Bước 9)
"""

from __future__ import annotations

import argparse
import email.utils
import os
import signal
import sys
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse

VIEWER_NAME = "audit-log-viewer.html"


def _guess_type(path):
    if path.endswith(".html"):
        return "text/html; charset=utf-8"
    if path.endswith(".jsonl") or path.endswith(".json"):
        return "application/json; charset=utf-8"
    return "text/plain; charset=utf-8"


def _safe_join(base, name):
    """Nối base+name, đảm bảo kết quả KHÔNG thoát khỏi base (chống ../ traversal).

    Trả path tuyệt đối hợp lệ hoặc None nếu name độc hại / thoát ra ngoài.
    """
    # name đã được unquote; cấm ký tự phân tách để một segment không leo lên
    if not name or "/" in name or "\\" in name or "\x00" in name:
        return None
    if name in (".", ".."):
        return None
    base_abs = os.path.abspath(base)
    full = os.path.abspath(os.path.join(base_abs, name))
    # realpath resolve symlink rồi so lại — chặn cả symlink trỏ ra ngoài
    if os.path.commonpath([base_abs, full]) != base_abs:
        return None
    return full


def make_handler(viewer_dir, data_dir):
    diff_dir = os.path.join(data_dir, "diff")
    results_dir = os.path.join(data_dir, "tool-results")
    says_dir = os.path.join(data_dir, "says")

    class Handler(BaseHTTPRequestHandler):
        server_version = "audit-log-viewer/1"

        def log_message(self, *a):  # im lặng — không spam stdout của skill
            pass

        def _resolve(self, url_path):
            """URL path -> (abs file path, base dir) theo whitelist, hoặc None."""
            path = unquote(urlparse(url_path).path)  # %23 -> #
            if path in ("/", "/index.html", "/" + VIEWER_NAME):
                return os.path.join(viewer_dir, VIEWER_NAME), viewer_dir
            if path == "/audit-log.jsonl":
                return os.path.join(data_dir, "audit-log.jsonl"), data_dir
            for prefix, base in (("/diff/", diff_dir), ("/tool-results/", results_dir), ("/says/", says_dir)):
                if path.startswith(prefix):
                    full = _safe_join(base, path[len(prefix):])
                    return (full, base) if full else None
            return None

        def do_GET(self):
            self._serve(head_only=False)

        def do_HEAD(self):
            self._serve(head_only=True)

        def _serve(self, head_only):
            resolved = self._resolve(self.path)
            if resolved is None or not os.path.isfile(resolved[0]):
                self.send_error(404, "Not found")
                return
            path = resolved[0]
            st = os.stat(path)
            lastmod = email.utils.formatdate(st.st_mtime, usegmt=True)

            # conditional GET (poll realtime rẻ)
            ims = self.headers.get("If-Modified-Since")
            if ims:
                ims_t = email.utils.parsedate_to_datetime(ims)
                if ims_t and int(ims_t.timestamp()) >= int(st.st_mtime):
                    self.send_response(304)
                    self.send_header("Last-Modified", lastmod)
                    self.end_headers()
                    return

            size = st.st_size
            ctype = _guess_type(path)
            rng = self.headers.get("Range")
            start, end = 0, size - 1
            partial = False
            if rng and rng.startswith("bytes="):
                try:
                    s, _, e = rng[len("bytes="):].partition("-")
                    start = int(s) if s else 0
                    end = int(e) if e else size - 1
                    end = min(end, size - 1)
                    if start > end or start >= size:
                        raise ValueError
                    partial = True
                except ValueError:
                    self.send_response(416)
                    self.send_header("Content-Range", f"bytes */{size}")
                    self.end_headers()
                    return

            self.send_response(206 if partial else 200)
            self.send_header("Content-Type", ctype)
            self.send_header("Last-Modified", lastmod)
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Cache-Control", "no-cache")
            length = end - start + 1
            self.send_header("Content-Length", str(length))
            if partial:
                self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.end_headers()
            if head_only:
                return
            with open(path, "rb") as f:
                f.seek(start)
                remaining = length
                while remaining > 0:
                    chunk = f.read(min(65536, remaining))
                    if not chunk:
                        break
                    try:
                        self.wfile.write(chunk)
                    except (BrokenPipeError, ConnectionResetError):
                        return
                    remaining -= len(chunk)

    return Handler


def main(argv=None):
    ap = argparse.ArgumentParser(description="local viewer server cho audit-trail")
    ap.add_argument("--root", default=os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd(),
                    help="project root (chứa .specs/audit/); mặc định CLAUDE_PROJECT_DIR hoặc cwd")
    ap.add_argument("--host", default="127.0.0.1", help="chỉ nên là 127.0.0.1 (localhost-only)")
    ap.add_argument("--port", type=int, default=0, help="0 = port trống ngẫu nhiên")
    ap.add_argument("--open", action="store_true", help="tự mở browser (mặc định off)")
    args = ap.parse_args(argv)

    viewer_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.join(os.path.abspath(args.root), ".specs", "audit")

    if not os.path.isfile(os.path.join(viewer_dir, VIEWER_NAME)):
        print(f"LỖI: không thấy {VIEWER_NAME} cạnh serve.py ({viewer_dir})", file=sys.stderr)
        return 1
    if not os.path.isdir(data_dir):
        print(f"⚠ chưa có {data_dir} — audit-log rỗng? Viewer vẫn mở, chờ log sinh ra.", file=sys.stderr)

    httpd = ThreadingHTTPServer((args.host, args.port), make_handler(viewer_dir, data_dir))
    httpd.daemon_threads = True
    port = httpd.server_address[1]
    url = f"http://{args.host}:{port}/{VIEWER_NAME}"

    # pidfile để /audit-log-viewer nhận diện & tái dùng server đang chạy (khỏi đẻ process thừa).
    viewer_file = os.path.join(data_dir, ".viewer")
    try:
        os.makedirs(data_dir, exist_ok=True)
        with open(viewer_file, "w", encoding="utf-8") as f:
            f.write(f"{os.getpid()} {url}\n")
    except OSError:
        viewer_file = None

    # Dòng máy-đọc cho skill /audit-log-viewer; đứng trước để dễ grep.
    print(f"AUDIT_VIEW_URL={url}", flush=True)
    print(f"audit-log-viewer: phục vụ tại {url}  (PID {os.getpid()}, Ctrl-C để dừng)", flush=True)
    if args.open:
        webbrowser.open(url)
    # SIGTERM (từ `/audit-log-viewer stop` = kill <PID>) → dừng gọn để chạy cleanup pidfile,
    # thay vì kết thúc đột ngột (Python không tự biến SIGTERM thành exception).
    def _term(*_a):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, _term)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
        if viewer_file and os.path.isfile(viewer_file):
            try:
                os.remove(viewer_file)
            except OSError:
                pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
