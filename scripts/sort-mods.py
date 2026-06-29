#!/usr/bin/env python3
"""Ordena a lista de mods em ordem alfabética, removendo duplicatas e entradas inválidas."""

import re
import sys
from pathlib import Path

SCRIPTS_DIR = Path(__file__).parent
INPUT_FILES = [
    SCRIPTS_DIR / "both-mods.txt",
    SCRIPTS_DIR / "client-mods.txt",
    SCRIPTS_DIR / "server-mods.txt",
]


def is_valid_mod(line: str) -> bool:
    """Verifica se a linha é um ID de mod válido."""
    line = line.strip()
    if not line:
        return False
    # Ignora URLs
    if line.startswith(("http://", "https://")):
        return False
    # Ignora flags como --addon-id
    if line.startswith("--"):
        return False
    return True


def normalize(mod_id: str) -> str:
    """Normaliza o ID do mod para comparação (lowercase)."""
    return mod_id.strip().lower()


def process_file(input_file: Path) -> Path:
    """Processa um arquivo de mods e retorna o caminho do arquivo ordenado."""
    if not input_file.exists():
        print(f"[AVISO] Arquivo não encontrado: {input_file}", file=sys.stderr)
        return None

    with input_file.open("r", encoding="utf-8") as f:
        raw_lines = f.readlines()

    # Filtra linhas válidas
    valid_lines = [line.strip() for line in raw_lines if is_valid_mod(line)]

    # Remove duplicatas preservando a primeira ocorrência (case-insensitive)
    seen = set()
    unique_lines = []
    for line in valid_lines:
        key = normalize(line)
        if key not in seen:
            seen.add(key)
            unique_lines.append(line)

    # Ordena alfabeticamente (case-insensitive)
    unique_lines.sort(key=str.lower)

    # Escreve o resultado (substitui o arquivo original)
    with input_file.open("w", encoding="utf-8") as f:
        f.write("\n".join(unique_lines) + "\n")

    print(f"[OK] {input_file.name}: {len(unique_lines)} mods únicos")
    return input_file


def main():
    for input_file in INPUT_FILES:
        process_file(input_file)


if __name__ == "__main__":
    main()
