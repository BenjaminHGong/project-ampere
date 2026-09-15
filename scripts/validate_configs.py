#!/usr/bin/env python3
"""Validate every tracked *.example config in the repo.

Usage: python3 scripts/validate_configs.py

Strict-JSON examples are parsed with json; the TOML example
(Simple Discord Link) is parsed with tomllib (Python 3.11+).
Exits non-zero on the first failing file so CI catches regressions.
"""
import json
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

JSON_EXAMPLES = [
    "factorio-server/config/factocord.config.example.json",
    "factorio-server/config/mod-list.example.json",
    "factorio-server/config/server-settings.example.json",
]

TOML_EXAMPLES = [
    "minecraft-server/config/simple-discord-link/simple-discord-link.example.toml",
]


def check_json(rel: str) -> bool:
    path = ROOT / rel
    if not path.exists():
        print(f"  missing: {rel}", file=sys.stderr)
        return False
    try:
        json.loads(path.read_text(encoding="utf-8"))
        print(f"  ok:     {rel}")
        return True
    except json.JSONDecodeError as exc:
        print(f"  FAIL:   {rel}: {exc}", file=sys.stderr)
        return False


def check_toml(rel: str) -> bool:
    path = ROOT / rel
    if not path.exists():
        print(f"  missing: {rel}", file=sys.stderr)
        return False
    try:
        tomllib.loads(path.read_text(encoding="utf-8"))
        print(f"  ok:     {rel}")
        return True
    except tomllib.TOMLDecodeError as exc:
        print(f"  FAIL:   {rel}: {exc}", file=sys.stderr)
        return False


def main() -> int:
    results = [check_json(rel) for rel in JSON_EXAMPLES] + [
        check_toml(rel) for rel in TOML_EXAMPLES
    ]
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())