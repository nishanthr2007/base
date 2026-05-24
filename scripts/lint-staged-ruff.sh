#!/usr/bin/env bash
# Run ruff on staged Python files using project venv when available.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT/.venv/Scripts/python.exe" ]; then
  PY="$ROOT/.venv/Scripts/python.exe"
elif [ -f "$ROOT/.venv/bin/python" ]; then
  PY="$ROOT/.venv/bin/python"
else
  PY=python
fi

if [ "$#" -eq 0 ]; then
  exit 0
fi

"$PY" -m ruff check --fix "$@"
"$PY" -m ruff format "$@"
