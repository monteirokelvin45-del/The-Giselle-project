#!/usr/bin/env python3
"""Extractor de strings para localização.

Retira as strings de texto (fala, UI, notificações) dos .gd em src/ e
gera docs/l10n/strings_pt.csv — a base para traduções futuras.

NÃO ativa runtime switching (ver docs/LOCALIZATION.md); é um andaime
honesto para não perder strings quando migrarmos para tr().

Uso: python3 tools/l10n_extract.py
Saída: docs/l10n/strings_pt.csv (key,context_file,line,text)
"""
import csv
import os
import re
import sys

REPO = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(REPO, "src")
OUT = os.path.join(REPO, "docs", "l10n", "strings_pt.csv")

STRING_RE = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
IDENT_RE = re.compile(r"^[a-z0-9_./{}$%-]+$", re.IGNORECASE)

def keep(text: str) -> bool:
    if len(text) < 5:
        return False
    if " " not in text and "—" not in text and "«" not in text:
        return False
    if text.startswith(("res://", "user://", "http")):
        return False
    if IDENT_RE.match(text):
        return False
    if not any(c.isalpha() for c in text):
        return False
    return True

def main() -> int:
    rows = []
    seen = set()
    counter = 0
    for root, dirs, files in os.walk(SRC):
        dirs[:] = [d for d in dirs if d != ".git"]
        for name in sorted(files):
            if not name.endswith(".gd"):
                continue
            path = os.path.join(root, name)
            rel = os.path.relpath(path, REPO).replace(os.sep, "/")
            with open(path, encoding="utf-8") as f:
                lines = f.readlines()
            for lineno, line in enumerate(lines, start=1):
                stripped = line.strip()
                if stripped.startswith("#") or stripped.startswith("##"):
                    continue
                for match in STRING_RE.finditer(line):
                    text = match.group(1).replace('\\"', '"').replace("\\\\", "\\")
                    if not keep(text):
                        continue
                    if text in seen:
                        continue
                    seen.add(text)
                    counter += 1
                    rows.append((f"PT-{counter:04d}", rel, lineno, text))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["key", "context_file", "line", "text"])
        writer.writerows(rows)
    print(f"{len(rows)} strings → {OUT}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
