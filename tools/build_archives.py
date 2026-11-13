#!/usr/bin/env python3
"""Constrói arquivos ZIP determinísticos e verifica correspondência com as fontes."""
import io
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCHIVES = {
    "Banco_SQL_5_Versoes_Expandidas.zip": "01_Banco_SQL_5_Versoes_Canonicas_Expandida",
    "portal_comercial_starter.zip": "portal_comercial_starter",
}
EXCLUDE = {".env", "__pycache__", ".pytest_cache", ".venv", ".DS_Store"}

def build(folder):
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for file in sorted((ROOT / folder).rglob("*")):
            if not file.is_file() or any(p in EXCLUDE for p in file.relative_to(ROOT).parts):
                continue
            name = file.relative_to(ROOT).as_posix()
            info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, file.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    return output.getvalue()

check = "--check" in sys.argv
failed = False
for name, folder in ARCHIVES.items():
    archive = ROOT / name
    expected = build(folder)
    if check:
        ok = archive.is_file() and archive.read_bytes() == expected
        print(f"{'OK' if ok else 'FAIL'} {name}: {'sincronizado' if ok else 'desatualizado'}")
        failed |= not ok
    else:
        archive.write_bytes(expected)
        print(f"Gerado {name}: {len(expected)} bytes")
sys.exit(1 if failed else 0)
