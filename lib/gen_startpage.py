#!/usr/bin/env python3
"""Generuje stronę startową z dużymi kafelkami.

Wejście: kafelki "Nazwa|URL|emoji" na stdin; szablon (ścieżka) jako argv[1];
powitanie w zmiennej BABCIA_GREETING. Wyjście: HTML na stdout.
"""
import html
import os
import re
import sys

template_path = sys.argv[1]

tiles_html = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    parts = line.split("|")
    if len(parts) < 2:
        continue
    name, url = parts[0], parts[1]
    emoji = parts[2] if len(parts) > 2 else "🌐"
    tiles_html.append(
        f'      <a class="tile" href="{html.escape(url, quote=True)}">'
        f'<span class="emoji" aria-hidden="true">{html.escape(emoji)}</span>'
        f'<span class="name">{html.escape(name)}</span></a>'
    )

with open(template_path, encoding="utf-8") as f:
    page = f.read()

page = page.replace("@@GREETING@@", html.escape(os.environ.get("BABCIA_GREETING", "Dzień dobry!")))
page = page.replace("@@TILES@@", "\n".join(tiles_html))
accent = os.environ.get("ACCENT_COLOR", "").strip()
if not re.fullmatch(r"#[0-9a-fA-F]{6}", accent):
    accent = "#7b4fa8"
page = page.replace("@@ACCENT@@", accent)
sys.stdout.write(page)
