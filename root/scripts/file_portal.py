#!/usr/bin/env python3
"""Minimal local browser file upload/download portal for /workspace/files."""

import html
import os
import urllib.parse
from email.parser import BytesParser
from email.policy import default
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

FILES_DIR = Path(os.environ.get("FILES_DIR", "/workspace/files")).resolve()
PORT = int(os.environ.get("FILE_PORTAL_PORT", "6902"))

PAGE_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>sid-bio-linux File Channel</title>
  <link rel="icon" type="image/png" href="../favicon.png">
  <style>
    body {{ font-family: system-ui, -apple-system, sans-serif; background: #111; color: #eee; max-width: 780px; margin: 2rem auto; padding: 0 1rem; }}
    .top {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.4rem; }}
    h1 {{ font-size: 1.35rem; margin: 0; }}
    .sub {{ color: #9aa0a6; font-size: 0.9rem; margin-bottom: 1.25rem; }}
    .card {{ background: #1b1b1b; border: 1px solid #303030; border-radius: 10px; padding: 1.2rem; margin-bottom: 1.25rem; }}
    input[type=file] {{ color: #ccc; }}
    button, .btn {{ background: #2d7ff9; color: #fff; border: 0; border-radius: 6px; padding: 0.45rem 0.9rem; cursor: pointer; font-weight: 600; text-decoration: none; font-size: 0.9rem; }}
    button.del {{ background: #b93838; padding: 0.25rem 0.55rem; font-size: 0.8rem; }}
    table {{ width: 100%; border-collapse: collapse; font-size: 0.92rem; }}
    th, td {{ text-align: left; padding: 0.5rem 0.4rem; border-bottom: 1px solid #2b2b2b; }}
    a {{ color: #6ea8fe; text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
    code {{ background: #262626; padding: 0.15rem 0.35rem; border-radius: 4px; }}
  </style>
</head>
<body>
  <div class="top">
    <h1>sid-bio-linux File Channel</h1>
    <a class="btn" href="../">Back to Desktop</a>
  </div>
  <div class="sub">
    Files uploaded here are saved directly to <code>/workspace/files</code> inside Linux (and <code>files/</code> on your host).
    Any extra folder configured via <code>PROJECTS_DIR</code> is mounted at <code>/workspace/projects</code>.
  </div>
  <div class="card">
    <form action="upload" method="post" enctype="multipart/form-data">
      <input type="file" name="files" multiple required>
      <button type="submit">Upload to Linux</button>
    </form>
  </div>
  <div class="card">
    <strong>Files in <code>/workspace/files</code></strong>
    <table>
      <thead><tr><th>Name</th><th>Size</th><th>Actions</th></tr></thead>
      <tbody>{rows}</tbody>
    </table>
  </div>
</body>
</html>
"""


def human_size(num: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if num < 1024:
            return f"{num:.0f} {unit}" if unit == "B" else f"{num:.1f} {unit}"
        num /= 1024
    return f"{num:.1f} TB"


def safe_target(raw_name: str) -> Path | None:
    clean = Path(raw_name).name.strip()
    if not clean or clean in {".", ".."}:
        return None
    target = (FILES_DIR / clean).resolve()
    if target.parent != FILES_DIR:
        return None
    return target


class FilePortalHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def do_GET(self):
        FILES_DIR.mkdir(parents=True, exist_ok=True)
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path in ("/", ""):
            items = sorted(
                (p for p in FILES_DIR.iterdir() if p.is_file() and not p.name.startswith(".")),
                key=lambda p: p.name.lower(),
            )
            rows = []
            for p in items:
                qname = urllib.parse.quote(p.name)
                ename = html.escape(p.name)
                size = human_size(p.stat().st_size)
                rows.append(
                    f"<tr><td><a href='download/{qname}'>{ename}</a></td>"
                    f"<td>{size}</td>"
                    f"<td><form action='delete' method='post' style='display:inline'>"
                    f"<input type='hidden' name='name' value='{ename}'>"
                    f"<button class='del' type='submit'>Delete</button></form></td></tr>"
                )
            body = PAGE_TEMPLATE.format(
                rows="".join(rows) or "<tr><td colspan='3'>No files yet.</td></tr>"
            ).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path.startswith("/download/"):
            rel = urllib.parse.unquote(parsed.path[len("/download/"):])
            target = safe_target(rel)
            if not target or not target.is_file():
                self.send_error(404, "File not found")
                return
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", f'attachment; filename="{target.name}"')
            self.send_header("Content-Length", str(target.stat().st_size))
            self.end_headers()
            with target.open("rb") as f:
                while chunk := f.read(65536):
                    self.wfile.write(chunk)
            return

        self.send_error(404)

    def do_POST(self):
        if self.path not in ("/upload", "/delete"):
            self.send_error(405)
            return

        FILES_DIR.mkdir(parents=True, exist_ok=True)
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            self.redirect_home()
            return
        body = self.rfile.read(length)

        if self.path == "/upload":
            ctype = self.headers.get("Content-Type", "")
            raw_msg = f"Content-Type: {ctype}\r\nMIME-Version: 1.0\r\n\r\n".encode("utf-8") + body
            msg = BytesParser(policy=default).parsebytes(raw_msg)
            if msg.is_multipart():
                for part in msg.iter_parts():
                    filename = part.get_filename()
                    if not filename:
                        continue
                    target = safe_target(filename)
                    if target:
                        target.write_bytes(part.get_payload(decode=True) or b"")
            self.redirect_home()
            return

        if self.path == "/delete":
            form = urllib.parse.parse_qs(body.decode("utf-8", errors="ignore"))
            for name in form.get("name", []):
                target = safe_target(name)
                if target and target.is_file():
                    target.unlink()
            self.redirect_home()
            return

    def redirect_home(self):
        self.send_response(303)
        self.send_header("Location", "/files/")
        self.end_headers()


if __name__ == "__main__":
    FILES_DIR.mkdir(parents=True, exist_ok=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), FilePortalHandler).serve_forever()
