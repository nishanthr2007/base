#!/usr/bin/env bash
# Activate venv with Git Bash utilities on PATH (fixes sed/uname not found in Cursor).

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

_git_usr_bin="/c/Program Files/Git/usr/bin"
_git_bin="/c/Program Files/Git/bin"
_git_mingw="/c/Program Files/Git/mingw64/bin"

for _dir in "$_git_usr_bin" "$_git_bin" "$_git_mingw"; do
  if [ -d "$_dir" ]; then
    export PATH="$_dir:$PATH"
  fi
done

# shellcheck source=/dev/null
source "$PROJECT_ROOT/.venv/Scripts/activate"
