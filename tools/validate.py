#!/usr/bin/env python3
"""Validação estrutural do projeto Godot (sem a engine).

1. gdparse em todos os ficheiros .gd
2. Todos os caminhos res:// referenciados existem
3. project.godot: autoloads e cena principal existem
4. .tscn: ficheiros referenciados em ext_resource existem; estrutura mínima
5. i18n: todas as chaves de l10n/game.csv têm EN+ES preenchidos
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures: list[str] = []
warnings: list[str] = []

def fail(msg: str) -> None:
    failures.append(msg)

def warn(msg: str) -> None:
    warnings.append(msg)

def res_path(rel: str) -> str:
    return os.path.join(ROOT, rel)

# ------------------------------------------------------------ .gd parse ----
gd_files = []
for dirpath, _dirs, files in os.walk(ROOT):
    if any(part.startswith(".") or part in {"tools"} for part in dirpath[len(ROOT):].split(os.sep) if part):
        continue
    for f in files:
        if f.endswith(".gd"):
            gd_files.append(os.path.join(dirpath, f))

print(f"[1/5] gdparse em {len(gd_files)} scripts GDScript...")
for gd in sorted(gd_files):
    try:
        result = subprocess.run(["gdparse", gd], capture_output=True, text=True)
    except FileNotFoundError:
        print("ERRO: `gdparse` não encontrado — instala com: pip3 install -r requirements-dev.txt")
        sys.exit(2)
    if result.returncode != 0 or result.stdout.strip():
        msg = (result.stderr or result.stdout).strip()
        fail(f"GDScript inválido: {os.path.relpath(gd, ROOT)}\n{msg}")

# ------------------------------------------------- res:// references -------
print("[2/5] Verificando caminhos res:// referenciados...")
res_pattern = re.compile(r'res://[A-Za-z0-9_\-./]+')
checked_ext = {".gd", ".tscn", ".godot", ".cfg", ".tres"}
for dirpath, _dirs, files in os.walk(ROOT):
    if any(part.startswith(".") for part in dirpath[len(ROOT):].split(os.sep) if part):
        continue
    for f in files:
        ext = os.path.splitext(f)[1]
        if ext not in checked_ext:
            continue
        path = os.path.join(dirpath, f)
        try:
            content = open(path, encoding="utf-8").read()
        except UnicodeDecodeError:
            continue
        for match in set(res_pattern.findall(content)):
            target = match[len("res://"):]
            # Artefactos gerados por `godot --import` (a partir de l10n/game.csv):
            # não existem antes do import nem são commitados (binários derivados).
            if target.endswith(".translation"):
                continue
            if not os.path.exists(res_path(target)):
                fail(f"res:// inexistente: '{match}' referenciado em {os.path.relpath(path, ROOT)}")

# ------------------------------------------------------ project.godot ------
print("[3/5] Verificando project.godot...")
pgodot = open(os.path.join(ROOT, "project.godot"), encoding="utf-8").read()
m = re.search(r'run/main_scene\s*=\s*"([^"]+)"', pgodot)
if not m:
    fail("project.godot: run/main_scene não definido")
elif not os.path.exists(res_path(m.group(1)[len("res://"):])):
    fail(f"project.godot: cena principal inexistente: {m.group(1)}")
for m in re.finditer(r'"\*res://([^"]+)"', pgodot):
    if not os.path.exists(res_path(m.group(1))):
        fail(f"project.godot: autoload inexistente: res://{m.group(1)}")

# ---------------------------------------------------------------- .tscn ----
print("[4/5] Verificando cenas .tscn...")
for dirpath, _dirs, files in os.walk(ROOT):
    if any(part.startswith(".") for part in dirpath[len(ROOT):].split(os.sep) if part):
        continue
    for f in files:
        if not f.endswith(".tscn"):
            continue
        path = os.path.join(dirpath, f)
        content = open(path, encoding="utf-8").read()
        if "[node" not in content:
            fail(f"{f}: nenhum nó declarado")
        for m in re.finditer(r'ext_resource[^\]]*path="res://([^"]+)"', content):
            if not os.path.exists(res_path(m.group(1))):
                fail(f"{f}: ext_resource inexistente: res://{m.group(1)}")
        ids = re.findall(r'\[sub_resource[^\]]*id="([^"]+)"', content)
        for ref in re.findall(r'SubResource\("([^"]+)"\)', content):
            if ref not in ids:
                fail(f"{f}: SubResource desconhecido: {ref}")
        for ref in re.findall(r'ExtResource\("([^"]+)"\)', content):
            ext_ids = re.findall(r'ext_resource[^\]]*id="([^"]+)"', content)
            if ref not in ext_ids:
                fail(f"{f}: ExtResource desconhecido: {ref}")

# -------------------------------------------------------- i18n (game.csv) ----
print("[5/5] Verificando localização (l10n/game.csv)...")
locale_check = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "l10n_build.py"), "--check"],
                              capture_output=True, text=True)
if locale_check.returncode != 0:
    fail("i18n: " + (locale_check.stdout or locale_check.stderr).strip())

print()
for w in warnings:
    print(f"AVISO: {w}")
if failures:
    print(f"FALHOU — {len(failures)} problema(s):")
    for f_ in failures:
        print(f"  ✗ {f_}")
    sys.exit(1)
print("VALIDAÇÃO ESTRUTURAL OK ✓")
