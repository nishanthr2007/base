# Base Project — Setup Reference

Quick reference for setting up this skeleton from scratch (or copying it to a new directory).

## Prerequisites

- **Python 3.10+**
- **Git for Windows** (recommended for Git Bash in Cursor)
- Git (optional, for version control)

## One-time setup commands

Run from the project root (directory containing `pyproject.toml`):

```bash
# 1. Create virtual environment
python -m venv .venv

# 2. Patch activate for Git Bash (no uname/cygpath required)
bash scripts/patch_venv_activate.sh

# 3. Activate virtual environment
source .venv/Scripts/activate          # Git Bash (after patch)
# source scripts/activate.sh           # Alternative: also fixes PATH for sed
# .\.venv\Scripts\Activate.ps1         # PowerShell

# 4. Upgrade pip (recommended)
python -m pip install --upgrade pip

# 5. Install project in editable mode with dev tools (watchdog)
pip install -e ".[dev]"
```

### Cursor / VS Code terminal

Open this folder in Cursor so `.vscode/settings.json` applies. Use a **new terminal** after opening the project (profile: **Git Bash (base)**) so Git `usr\bin` is on `PATH`.

If you do not use Cursor: run `bash scripts/patch_venv_activate.sh` after every `python -m venv .venv`.

## Run commands

| Command | Description |
|---------|-------------|
| `base` | Run default app (loads `env/.env.dev`) |
| `base --env qa` | Run with QA environment |
| `base --env prod` | Run with production environment |
| `base -v` | Verbose (DEBUG) logging |
| `base 10 20 30` | Stats CLI mode (mean, min, max) |
| `base --watch` | Dev server: auto-restart on `.py` changes |
| `base --watch -v --env dev` | Watch + verbose + dev env |
| `python -m main` | Same as `base` (after editable install) |

### Without activating the venv

```bash
.venv/Scripts/base --watch --env dev -v
```

### Without installed script

```bash
# From project root (Git Bash)
PYTHONPATH=src .venv/Scripts/python -m main
```

## Project layout

```
base/
├── .vscode/
│   └── settings.json       # Git Bash profile + PATH for Cursor
├── env/
│   ├── .env.dev            # Development variables
│   ├── .env.qa             # QA / staging
│   └── .env.prod           # Production
├── logs/
│   ├── .gitkeep
│   └── app.log             # Created at runtime (gitignored)
├── package.json            # Husky / commitlint / lint-staged config
├── scripts/
│   ├── activate.sh         # Activate + prepend Git usr/bin to PATH
│   ├── patch_venv_activate.sh  # Patch .venv after venv recreate
│   └── rename_project.sh   # Rename package, CLI, envs, docs, and setup
├── src/
│   ├── main.py             # CLI, logging, watch mode
│   ├── load_env.py         # Loads env/.env.<ENVIRONMENT>
│   ├── core.py             # Reusable business logic
│   └── app.py              # Default app entry (customize this)
├── .venv/                  # Virtual environment (gitignored)
├── HOOKS.md                # Hook setup and behavior
├── pyproject.toml
├── README.md
├── SETUP.md                # This file
├── SETUP_STEPS.md          # Detailed step-by-step guide
├── RENAME.md               # Rename folder vs project; skeleton checklist
└── CHALLENGES.md           # Issues and fixes (flowchart)
```

## Helper scripts

| Script | When to use |
|--------|-------------|
| `bash scripts/patch_venv_activate.sh` | After `python -m venv .venv` (fixes `uname` errors on activate) |
| `source scripts/activate.sh` | Git Bash when `sed` still missing from `~/.bashrc` at startup |
| `bash scripts/rename_project.sh <new-name>` | Rename package/CLI/envs and refresh local setup from the repo root |

## Environment variables

| Variable | Set by | Purpose |
|----------|--------|---------|
| `ENVIRONMENT` | `--env` flag / `.env.*` | Selects `env/.env.<name>` |
| `LOG_LEVEL` | `.env.*` | Documented log level hint |
| `APP_NAME` | `.env.*` | Application display name |
| `APP_DEV_SERVE` | Watch mode parent | Child process stays alive until reload |

## Renaming this skeleton for a new project

See **[RENAME.md](RENAME.md)** for the full guide (required vs optional files, venv steps, checklist).

You have two options:

### Option 1: Manual rename

1. Copy or rename the folder (e.g. `base` → `my-service`).
2. Use a project name without spaces.
3. Update:
   - `pyproject.toml` → `[project] name`
   - `pyproject.toml` → `[project.scripts]`
   - `env/.env.dev`, `env/.env.qa`, `env/.env.prod` → `APP_NAME=my-service`
   - optionally `src/app.py`, `.vscode/settings.json`, and docs
4. Recreate `.venv` (recommended), then:

```bash
python -m venv .venv
bash scripts/patch_venv_activate.sh
pip install -e ".[dev]"
```

5. If you use hook files, also run:

```bash
npm install
npm run prepare
```

6. Refresh the terminal if needed, then run with the new CLI name:

```bash
hash -r
source .venv/Scripts/activate
my-service
```

### Option 2: Bash helper script

Run this from the repo root:

```bash
bash scripts/rename_project.sh my-service
```

Project names must not contain spaces.

Or the full form:

```bash
bash scripts/rename_project.sh --old-name base --new-name my-service
```

With description and author:

```bash
bash scripts/rename_project.sh --old-name base --new-name my-service --description "My Service CLI project" --author "Your Name"
```

Example: converting `base` to `longchain`

Run this from the repo root:

```bash
bash scripts/rename_project.sh --old-name base --new-name longchain
```

Short version, since `base` is already the default old name:

```bash
bash scripts/rename_project.sh longchain
```

If you also want to set the project description and author in the same run:

```bash
bash scripts/rename_project.sh --old-name base --new-name longchain --description "LongChain CLI project" --author "Your Name"
```

Useful options:

```bash
bash scripts/rename_project.sh my-service --skip-docs
bash scripts/rename_project.sh my-service --keep-venv
bash scripts/rename_project.sh my-service --skip-npm
```

What the script also does for you:

- updates `package.json` / `package-lock.json` when present
- rewrites `README.md`, `SETUP.md`, `SETUP_STEPS.md`, and `CHALLENGES.md` unless `--skip-docs` is used
- recreates `.venv` by default, patches activate, upgrades `pip`, and runs `pip install -e ".[dev]"`
- runs `npm install` and `npm run prepare` when `package.json` exists, unless `--skip-npm` is used
- keeps `RENAME.md` and `HOOKS.md` unchanged

After the script finishes, refresh the terminal if needed and run the new CLI:

```bash
hash -r
source .venv/Scripts/activate
my-service
```

## Logs

- Console: all runs log to stdout with format `timestamp [LEVEL] module: message`.
- File: `logs/app.log` (append mode, created on each run).

## Dev watch mode

Requires `watchdog` (`pip install -e ".[dev]"`).

```bash
base --watch -v --env dev
```

Watches `src/` and project root for `.py` changes, restarts the child process automatically.

## Git Bash: `sed` / `uname: command not found`

Two different sources:

| When it appears | Cause | Fix |
|-----------------|-------|-----|
| Only when running `source .venv/Scripts/activate` | Stock `activate` uses `uname` | Run `bash scripts/patch_venv_activate.sh` (included in setup above) |
| As soon as terminal opens (before any command) | Your `~/.bashrc` + short `PATH` | Open a **new** terminal in Cursor, or `export PATH="/c/Program Files/Git/usr/bin:/c/Program Files/Git/bin:$PATH"` |

**Activation options (pick one):**

```bash
# 1. Patched activate (recommended after patch script)
source .venv/Scripts/activate

# 2. Wrapper — adds Git bins to PATH, then activates
source scripts/activate.sh

# 3. No activate — run CLI directly
.venv/Scripts/base

# 4. PowerShell — no bash tools needed
.\.venv\Scripts\Activate.ps1
```

See [CHALLENGES.md](CHALLENGES.md) for the full troubleshooting flowchart.

## Git hooks (optional)

Husky + conventional commits + Ruff on staged files. See [HOOKS.md](HOOKS.md).

```bash
pip install -e ".[dev]"
npm install
npm run prepare
```

Pre-commit behavior for staged `*.py` files:

1. `ruff format`
2. `ruff check --fix`
3. `ruff check`
4. If lint errors remain, commit fails and details are written to `logs/lint-staged.log`
5. If Ruff auto-fixes files, commit also fails intentionally so you can review and re-stage the updated files

Typical flow after auto-fix:

```bash
git commit -m "fix(cli): clean imports"
# hook updates files and stops commit
git add .
git commit -m "fix(cli): clean imports"
```

## Related docs

- [SETUP_STEPS.md](SETUP_STEPS.md) — Full step-by-step walkthrough
- [RENAME.md](RENAME.md) — Rename folder vs project; skeleton copy checklist
- [HOOKS.md](HOOKS.md) — Husky, commitlint, lint-staged
- [CHALLENGES.md](CHALLENGES.md) — Problems and fixes (flowchart)
- [README.md](README.md) — Project overview
