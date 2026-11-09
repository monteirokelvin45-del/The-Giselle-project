#!/usr/bin/env python3
"""Gera/valida l10n/game.csv — a tabela de tradução do jogo (EN + ES).

Modelo:
  chaves = os próprios literais PT encontrados em src/*.gd (+ .tscn não usados hoje);
  a chamada tr("<literal PT>") devolve a tradução para o locale atual;
  se a chave não existir, tr() devolve a própria chave → o jogo nunca rebenta.

Uso:
  python3 tools/l10n_build.py           regenera l10n/game.csv preservando traduções
  python3 tools/l10n_build.py --check   validação (CI): falha se faltar chave/en/es ou houver chaves antigas
"""
import csv
import os
import re
import sys

REPO = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(REPO, "src")
OUT = os.path.join(REPO, "l10n", "game.csv")
LOCALES = ["pt", "en", "es"]

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

def scan_keys() -> list[str]:
    keys = []
    seen = set()
    for root, dirs, files in os.walk(SRC):
        dirs[:] = sorted(d for d in dirs if d != ".git")
        for name in sorted(files):
            if not name.endswith(".gd"):
                continue
            with open(os.path.join(root, name), encoding="utf-8") as f:
                lines = f.readlines()
            for lineno, line in enumerate(lines, start=1):
                stripped = line.strip()
                if stripped.startswith("#"):
                    continue
                for match in STRING_RE.finditer(line):
                    text = match.group(1).replace('\\"', '"').replace("\\\\", "\\")
                    if not keep(text) or text in seen:
                        continue
                    seen.add(text)
                    keys.append(text)
    return keys

def decode_csv_key(raw: str) -> str:
    return raw

def load_existing():
    data = {}
    if not os.path.exists(OUT):
        return data
    with open(OUT, encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            data[row["keys"]] = row
    return data

def main() -> int:
    check = "--check" in sys.argv
    keys = scan_keys()
    existing = load_existing()
    if check:
        problems = []
        stale = [k for k in existing if k not in set(keys)]
        if stale:
            problems.append(f"{len(stale)} chave(s) antigas no CSV (ex.: {stale[0]!r}) — correr tools/l10n_build.py")
        for k in keys:
            row = existing.get(k)
            if row is None:
                problems.append(f"chave em falta no CSV: {k!r}")
                continue
            for loc in ("en", "es"):
                v = (row.get(loc) or "").strip()
                if not v or v.startswith("__TODO"):
                    problems.append(f"[{loc}] por traduzir: {k!r}")
        if problems:
            print("i18n CHECK FALHOU:")
            for p in problems[:40]:
                print(" -", p)
            print(f"total de problemas: {len(problems)}")
            return 2
        print(f"i18n OK — {len(keys)} chaves, EN+ES completos ✓")
        return 0
    rows = []
    for k in keys:
        row = existing.get(k) or {}
        rows.append({
            "keys": k,
            "pt": (row.get("pt") or k).strip(),
            "en": (row.get("en") or f"__TODO_EN__ {k}").strip(),
            "es": (row.get("es") or f"__TODO_ES__ {k}").strip(),
        })
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=LOCALES and ["keys", "pt", "en", "es"])
        writer.writeheader()
        writer.writerows(rows)
    todo = sum(1 for r in rows if r["en"].startswith("__TODO") or r["es"].startswith("__TODO"))
    print(f"{len(rows)} chaves → {OUT} ({todo} por traduzir)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
