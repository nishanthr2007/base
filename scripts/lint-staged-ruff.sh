#!/usr/bin/env bash
# Lint/format staged Python files.
# - Remaining lint errors => write report and exit 1
# - Auto-fixes applied => keep changes locally and exit 1 so user can review/re-stage
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$ROOT/logs/lint-staged.log"

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

mkdir -p "$ROOT/logs"

declare -A BEFORE_HASH
CHANGED_FILES=()

for file in "$@"; do
  BEFORE_HASH["$file"]="$(
    if [ -f "$file" ]; then
      git hash-object -- "$file"
    else
      echo "__missing__"
    fi
  )"
done

# 1. Format staged files (PEP 8 style via ruff format)
"$PY" -m ruff format "$@"

# 2. Apply safe auto-fixes (imports, etc.)
"$PY" -m ruff check --fix "$@" || true

# 3. Strict check — remaining violations fail the commit
CHECK_EXIT=0
CHECK_OUTPUT="$("$PY" -m ruff check "$@" 2>&1)" || CHECK_EXIT=$?

if [ "$CHECK_EXIT" -ne 0 ]; then
  {
    echo "Ruff lint failed at $(date "+%Y-%m-%d %H:%M:%S %z")"
    echo "Python lint rules: pyproject.toml [tool.ruff.lint]"
    echo ""
    echo "Staged files:"
    printf '  %s\n' "$@"
    echo ""
    echo "Errors:"
    echo "$CHECK_OUTPUT"
  } >"$LOG_FILE"

  echo "Commit blocked: Python lint errors found." >&2
  echo "Full report: logs/lint-staged.log" >&2
  echo "" >&2
  echo "$CHECK_OUTPUT" >&2
  exit 1
fi

for file in "$@"; do
  AFTER_HASH="$(
    if [ -f "$file" ]; then
      git hash-object -- "$file"
    else
      echo "__missing__"
    fi
  )"

  if [ "${BEFORE_HASH["$file"]}" != "$AFTER_HASH" ]; then
    CHANGED_FILES+=("$file")
  fi
done

if [ "${#CHANGED_FILES[@]}" -gt 0 ]; then
  {
    echo "Ruff auto-fix applied changes at $(date "+%Y-%m-%d %H:%M:%S %z")"
    echo "Commit stopped so you can review and re-stage the updated files."
    echo ""
    echo "Updated files:"
    printf '  %s\n' "${CHANGED_FILES[@]}"
    echo ""
    echo "Next steps:"
    echo "  1. Review the changes"
    echo "  2. git add <files>"
    echo "  3. git commit again"
  } >"$LOG_FILE"

  echo "Commit blocked: auto-fixes were applied to staged Python files." >&2
  echo "Review and re-stage the updated files, then commit again." >&2
  echo "Full report: logs/lint-staged.log" >&2
  exit 1
fi

# Clear stale error log on success
rm -f "$LOG_FILE"
exit 0
