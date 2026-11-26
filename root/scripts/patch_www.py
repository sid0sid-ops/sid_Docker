#!/usr/bin/env python3
"""Customize KasmVNC web UI for sid-bio-linux: single display, clean sidebar, no mode toasts."""

import glob
import re
from pathlib import Path

WWW = Path("/usr/share/kasmvnc/www")

HIDE_STYLE = (
    "<style>#noVNC_notification_overlay,#noVNC_displays_button{display:none!important;}</style></head>"
)

SIDEBAR_HEADER = (
    '<div style="padding:12px 10px 10px;text-align:center;'
    'border-bottom:1px solid rgba(255,255,255,.14);margin-bottom:8px;">'
    '<div style="font-weight:700;font-size:15px;color:#fff;margin-bottom:8px;">sid-bio-linux</div>'
    '<a href="/files/" target="_blank" style="display:inline-block;padding:6px 12px;'
    'background:#2d7ff9;color:#fff;border-radius:6px;text-decoration:none;'
    'font-size:12px;font-weight:600;">Upload / Files</a></div>'
)

for name in ("index.html", "vnc.html"):
    path = WWW / name
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    text = text.replace("<title>KasmVNC</title>", "<title>sid-bio-linux</title>")
    text = text.replace("</head>", HIDE_STYLE, 1)
    text = text.replace("KasmVNC encountered an error:", "Desktop encountered an error:")
    text = text.replace("Enable KasmVNC Keyboard Shortcuts", "Enable Keyboard Shortcuts")
    text = re.sub(r'<h1 class="noVNC_logo".*?</h1>', SIDEBAR_HEADER, text, flags=re.S)
    path.write_text(text, encoding="utf-8")

for js_path_str in glob.glob(str(WWW / "assets" / "ui-*.js")):
    js_path = Path(js_path_str)
    js = js_path.read_text(encoding="utf-8")
    js = js.replace('const Sx="KasmVNC"', 'const Sx="sid-bio-linux"')
    js = js.replace('document.title=n.detail.name+" - "+Sx', 'document.title="sid-bio-linux"')
    js = js.replace('rr("Connected (unencrypted) to ")', 'rr("Connected to ")')
    js = js.replace('identify(n){Al("1")}', 'identify(n){}')
    js = js.replace('o.showControlInput("noVNC_displays_button")', 'void 0')
    js = js.replace(
        '(!Qt()||o.getSettingElement(_t.SHOW_NOTIFICATIONS)||hr(_t.SHOW_NOTIFICATIONS))&&Al(s||"Mode Changed")',
        'void 0',
    )
    js_path.write_text(js, encoding="utf-8")
