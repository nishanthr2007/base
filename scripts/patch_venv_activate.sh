#!/usr/bin/env bash
# Patch .venv/Scripts/activate to avoid uname/cygpath (Git Bash PATH issues in Cursor).
# Re-run after recreating the venv: bash scripts/patch_venv_activate.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ACTIVATE="$PROJECT_ROOT/.venv/Scripts/activate"

if [ ! -f "$ACTIVATE" ]; then
  echo "Missing $ACTIVATE — create venv first: python -m venv .venv" >&2
  exit 1
fi

if grep -q '_VENV_SCRIPT_DIR' "$ACTIVATE" 2>/dev/null; then
  echo "Already patched: $ACTIVATE"
  exit 0
fi

python - "$ACTIVATE" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
old = r"""# on Windows, a path can contain colons and backslashes and has to be converted:
case \"\$\(uname\)\" in
    CYGWIN\*\|MSYS\*\|MINGW\*\)
        # transform D:\\path\\to\\venv to /d/path/to/venv on MSYS and MINGW
        # and to /cygdrive/d/path/to/venv on Cygwin
        VIRTUAL_ENV=\$\(cygpath '[^']*'\)
        export VIRTUAL_ENV
        ;;
    \*\)
        # use the path as-is
        export VIRTUAL_ENV='[^']*'
        ;;
esac"""

new = """# Resolve venv root from this script (bash builtins only — no uname/cygpath/dirname)
_activate_script=\"${BASH_SOURCE[0]}\"
case \"$_activate_script\" in
    /*|[a-zA-Z]:*) ;;
    *) _activate_script=\"${PWD}/${_activate_script#./}\" ;;
esac
VIRTUAL_ENV=\"${_activate_script%/Scripts/activate}\"
VIRTUAL_ENV=\"${VIRTUAL_ENV%\\\\Scripts\\\\activate}\"
export VIRTUAL_ENV"""

patched, n = re.subn(
    r"# on Windows, a path can contain colons and backslashes.*?\nesac",
    new,
    text,
    count=1,
    flags=re.DOTALL,
)
if n != 1:
    print("Patch failed: activate block not found or already patched", file=sys.stderr)
    sys.exit(1)
path.write_text(patched, encoding="utf-8", newline="\n")
print(f"Patched: {path}")
PY
