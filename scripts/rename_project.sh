#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/rename_project.sh --new-name <name> [options]
  bash scripts/rename_project.sh <name> [options]

Options:
  --new-name <name>      New project/package/CLI name. Required unless passed positionally.
  --old-name <name>      Existing project name to replace. Default: base
  --description <text>   Optional pyproject/package description override.
  --author <text>        Optional pyproject author override.
  --skip-docs            Do not update README/setup/challenges docs.
  --keep-venv            Keep the existing .venv instead of recreating it.
  --skip-npm             Skip npm install and npm run prepare.
  -h, --help             Show this help text.

Examples:
  bash scripts/rename_project.sh longchain
  bash scripts/rename_project.sh --old-name base --new-name longchain
  bash scripts/rename_project.sh longchain --description "LongChain CLI project"
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OLD_NAME="base"
NEW_NAME=""
PROJECT_DESCRIPTION=""
PROJECT_AUTHOR=""
UPDATE_DOCS=1
RECREATE_VENV=1
RUN_NPM=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --new-name)
      NEW_NAME="${2:-}"
      shift 2
      ;;
    --old-name)
      OLD_NAME="${2:-}"
      shift 2
      ;;
    --description)
      PROJECT_DESCRIPTION="${2:-}"
      shift 2
      ;;
    --author)
      PROJECT_AUTHOR="${2:-}"
      shift 2
      ;;
    --skip-docs)
      UPDATE_DOCS=0
      shift
      ;;
    --keep-venv)
      RECREATE_VENV=0
      shift
      ;;
    --skip-npm)
      RUN_NPM=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$NEW_NAME" ]]; then
        NEW_NAME="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$NEW_NAME" ]]; then
  echo "Missing required new project name." >&2
  usage >&2
  exit 1
fi

if [[ "$NEW_NAME" == *[[:space:]]* ]]; then
  echo "Project name must not contain spaces: $NEW_NAME" >&2
  exit 1
fi

cd "$PROJECT_ROOT"

required_files=(
  "pyproject.toml"
  "src/app.py"
  "env/.env.dev"
  "env/.env.qa"
  "env/.env.prod"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
done

echo "Renaming project from '$OLD_NAME' to '$NEW_NAME' in $PROJECT_ROOT"

export PROJECT_ROOT OLD_NAME NEW_NAME PROJECT_DESCRIPTION PROJECT_AUTHOR UPDATE_DOCS
python - <<'PY'
import json
import os
import re
import sys
from pathlib import Path

root = Path(os.environ["PROJECT_ROOT"])
old = os.environ["OLD_NAME"]
new = os.environ["NEW_NAME"]
project_description = os.environ.get("PROJECT_DESCRIPTION", "")
project_author = os.environ.get("PROJECT_AUTHOR", "")
update_docs = os.environ.get("UPDATE_DOCS") == "1"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8", newline="\n")
    print(f"Updated {path.relative_to(root)}")


def replace_exact_word(text: str) -> str:
    return re.sub(rf"\b{re.escape(old)}\b", new, text)


pyproject = root / "pyproject.toml"
text = read_text(pyproject)

updated = re.sub(
    r'(^\[project\]\n(?:.*\n)*?^name = )"[^"]+"',
    lambda match: f'{match.group(1)}"{new}"',
    text,
    count=1,
    flags=re.MULTILINE,
)
if updated == text:
    print("Failed to update [project] name in pyproject.toml", file=sys.stderr)
    sys.exit(1)

updated_scripts = re.sub(
    r'(^\[project\.scripts\]\n)[^\n]+',
    lambda match: f'{match.group(1)}{new} = "main:main"',
    updated,
    count=1,
    flags=re.MULTILINE,
)
if updated_scripts == updated:
    print("Failed to update [project.scripts] in pyproject.toml", file=sys.stderr)
    sys.exit(1)

updated = updated_scripts

if project_description:
    updated = re.sub(
        r'(^description = )"[^"]*"',
        lambda match: f'{match.group(1)}"{project_description}"',
        updated,
        count=1,
        flags=re.MULTILINE,
    )

if project_author:
    updated = re.sub(
        r'(^authors = )\[.*\]',
        lambda match: f'{match.group(1)}[{{ name = "{project_author}" }}]',
        updated,
        count=1,
        flags=re.MULTILINE,
    )

write_text(pyproject, updated)

for rel_path in ("env/.env.dev", "env/.env.qa", "env/.env.prod"):
    path = root / rel_path
    text = read_text(path)
    updated = re.sub(r"^APP_NAME=.*$", f"APP_NAME={new}", text, count=1, flags=re.MULTILINE)
    if updated == text:
        print(f"Failed to update APP_NAME in {rel_path}", file=sys.stderr)
        sys.exit(1)
    write_text(path, updated)

app_py = root / "src/app.py"
text = read_text(app_py)
updated = re.sub(
    r'os\.environ\.get\("APP_NAME",\s*"[^"]+"\)',
    f'os.environ.get("APP_NAME", "{new}")',
    text,
    count=1,
)
if updated == text:
    print('Failed to update APP_NAME fallback in src/app.py', file=sys.stderr)
    sys.exit(1)
write_text(app_py, updated)

vscode = root / ".vscode/settings.json"
if vscode.exists():
    text = read_text(vscode)
    updated = text.replace(f"Git Bash ({old})", f"Git Bash ({new})")
    if updated != text:
        write_text(vscode, updated)

package_json = root / "package.json"
if package_json.exists():
    data = json.loads(read_text(package_json))
    data["name"] = new
    description = project_description or data.get("description", "")
    if description and not project_description:
        description = replace_exact_word(description)
    if description:
        data["description"] = description
    package_json.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("Updated package.json")

package_lock = root / "package-lock.json"
if package_lock.exists():
    data = json.loads(read_text(package_lock))
    if isinstance(data, dict):
        data["name"] = new
        packages = data.get("packages")
        if isinstance(packages, dict) and "" in packages and isinstance(packages[""], dict):
            packages[""]["name"] = new
    package_lock.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("Updated package-lock.json")

if update_docs:
    for rel_path in ("README.md", "SETUP.md", "SETUP_STEPS.md", "CHALLENGES.md"):
        path = root / rel_path
        if not path.exists():
            continue
        text = read_text(path)
        updated = replace_exact_word(text)
        if updated != text:
            write_text(path, updated)
PY

if [[ "$RECREATE_VENV" -eq 1 ]]; then
  echo "Recreating .venv"
  rm -rf ".venv"
  python -m venv .venv
else
  if [[ ! -d ".venv" ]]; then
    echo ".venv not found; creating a new one"
    python -m venv .venv
  else
    echo "Keeping existing .venv"
  fi
fi

if [[ -f ".venv/Scripts/python" ]]; then
  if [[ -f "scripts/patch_venv_activate.sh" ]]; then
    bash "scripts/patch_venv_activate.sh"
  fi
  VENV_PYTHON=".venv/Scripts/python"
  VENV_PIP=".venv/Scripts/pip"
  VENV_ACTIVATE_CMD="source .venv/Scripts/activate"
  VENV_CLI_PATH=".venv/Scripts/$NEW_NAME"
elif [[ -f ".venv/bin/python" ]]; then
  VENV_PYTHON=".venv/bin/python"
  VENV_PIP=".venv/bin/pip"
  VENV_ACTIVATE_CMD="source .venv/bin/activate"
  VENV_CLI_PATH=".venv/bin/$NEW_NAME"
else
  echo "Could not find venv python/pip after creation." >&2
  exit 1
fi

"$VENV_PYTHON" -m pip install --upgrade pip
"$VENV_PIP" install -e ".[dev]"

if [[ "$RUN_NPM" -eq 1 ]] && [[ -f "package.json" ]]; then
  npm install
  npm run prepare
fi

cat <<EOF

Rename complete.

Verify with:
  $VENV_CLI_PATH
  $VENV_CLI_PATH -v --env dev
  $VENV_CLI_PATH 10 20 30
  $VENV_CLI_PATH --watch --env dev -v

If you ran this in an already-open terminal, refresh that terminal before using '$NEW_NAME':
  hash -r
  $VENV_ACTIVATE_CMD
  $NEW_NAME -v --env dev

If Bash still says command not found, open a new terminal or run:
  $VENV_CLI_PATH -v --env dev
EOF
