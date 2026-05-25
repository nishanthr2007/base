# Base Project — Step-by-Step Setup Process

This document walks through creating and running the **base** skeleton, mirroring the **practice** project structure.

---

## Step 1: Create project directory

Create an empty folder for the skeleton:

```bash
mkdir -p ~/PhythonWorkspace/base
cd ~/PhythonWorkspace/base
```

**Result:** Empty project root ready for files.

---

## Step 2: Add `pyproject.toml`

Define package metadata, dependencies, and CLI entry point:

- Package name: `base`
- Dependencies: `python-dotenv`
- Dev optional: `watchdog` (for `--watch`)
- Script: `base = "main:main"`
- Source layout: `src/` via `[tool.setuptools.package-dir]`

**Result:** Project is installable with `pip install -e .`

---

## Step 3: Create `src/` modules

| File | Role |
|------|------|
| `main.py` | CLI, logging setup, watch mode, stats mode |
| `load_env.py` | Load `env/.env.<ENVIRONMENT>` via python-dotenv |
| `core.py` | Example business logic (`compute_stats`) |
| `app.py` | Default application entry (replace with your logic) |

**Result:** Runnable Python package with clear separation of concerns.

---

## Step 4: Create environment files

```bash
mkdir env
```

Add three files:

- `env/.env.dev` — DEBUG, local URLs
- `env/.env.qa` — INFO, staging URLs
- `env/.env.prod` — WARNING, production URLs

**Result:** Environment-specific config without hardcoding secrets in code.

---

## Step 5: Create logs directory

```bash
mkdir logs
touch logs/.gitkeep
```

Add to `.gitignore`:

```
logs/*.log
```

**Result:** File logging writes to `logs/app.log`; directory stays in git.

---

## Step 6: Add `.gitignore`

Ignore:

- `.venv/`
- `__pycache__/`
- `logs/*.log`
- IDE/OS files

**Result:** Clean repository without virtual env or runtime logs.

---

## Step 7: Add helper scripts and Cursor terminal config

Create:

```
scripts/
├── activate.sh              # Prepends Git usr/bin, then sources activate
├── patch_venv_activate.sh   # Patches .venv/Scripts/activate (no uname)
└── rename_project.sh        # Renames package/CLI/envs/docs from repo root

.vscode/
└── settings.json            # Git Bash (base) profile + PATH
```

**Result:** Git Bash in Cursor works without `uname`/`sed` errors during activate.

---

## Step 8: Create virtual environment

```bash
python -m venv .venv
```

**Result:** Isolated Python environment for the project.

---

## Step 9: Patch and activate (Windows Git Bash)

Stock Python `activate` calls `uname`, which fails when Git `usr\bin` is not on `PATH` (common in Cursor).

```bash
bash scripts/patch_venv_activate.sh
source .venv/Scripts/activate
```

**Linux/macOS:**

```bash
source .venv/bin/activate
# patch script is only needed on Windows Git Bash with short PATH
```

**Alternatives:**

| Shell | Command |
|-------|---------|
| Git Bash (PATH issues) | `source scripts/activate.sh` |
| PowerShell | `.\.venv\Scripts\Activate.ps1` |
| Skip activate | `.venv/Scripts/base` |

**Expected:** Prompt shows `(.venv)` with **no** `uname: command not found` from activate.

**Result:** Venv active; `python` and `pip` point to `.venv`.

---

## Step 10: Install dependencies

```bash
python -m pip install --upgrade pip
pip install -e ".[dev]"
```

**Result:**

- `base` CLI command available
- `python-dotenv` and `watchdog` installed
- Editable install: code changes apply without reinstall

---

## Step 11: Run the application

### Default app mode

```bash
base
```

Expected output (example):

```
2026-05-24 16:51:14 [INFO] main: Application starting.
2026-05-24 16:51:14 [INFO] app: App started | name=base | environment=dev | log_level=DEBUG
2026-05-24 16:51:14 [INFO] app: Logs directory: .../base/logs
```

### Stats mode

```bash
base 10 20 30
```

Expected:

```
count=3 mean=20.00 min=10.00 max=30.00
```

### QA environment with verbose logging

```bash
base -v --env qa
```

### Development watch mode

```bash
base --watch -v --env dev
```

Edit any `.py` file under `src/` — the app restarts automatically.

---

## Step 12: Verify logs

```bash
cat logs/app.log
```

**Result:** Same log lines as console are appended to `logs/app.log`.

---

## Step 13: Open in Cursor (optional)

1. Open the `base` folder in Cursor.
2. Close any old terminal tabs.
3. Open a **new** terminal — should use profile **Git Bash (base)**.
4. Run `source .venv/Scripts/activate` — should work without `uname` errors.

If `sed: command not found` appears **before** you type anything, your `~/.bashrc` needs Git on `PATH`; the `.vscode/settings.json` profile fixes that for new terminals.

---

## Step 14: Optional git hooks setup

If you want Husky + commitlint + lint-staged:

```bash
npm install
npm run prepare
```

Hook behavior for staged `*.py` files:

1. `ruff format`
2. `ruff check --fix`
3. `ruff check`
4. If lint errors remain, commit fails and writes `logs/lint-staged.log`
5. If Ruff auto-fixes files, commit also fails intentionally so you can review and re-stage the updated files

Typical flow after auto-fix:

```bash
git commit -m "fix(cli): clean imports"
git add .
git commit -m "fix(cli): clean imports"
```

See [HOOKS.md](HOOKS.md) for details.

---

## Step 15: Copy skeleton for a new project

See **[RENAME.md](RENAME.md)** for the complete rename guide, checklist, and examples.

1. Copy entire `base` folder to a new name.
2. Either rename manually, or run the helper from the copied repo root:

   ```bash
   bash scripts/rename_project.sh my-api
   ```

   Example: converting `base` to `longchain`

   ```bash
   bash scripts/rename_project.sh --old-name base --new-name longchain
   # short version:
   bash scripts/rename_project.sh longchain
   # with description and author:
   bash scripts/rename_project.sh --old-name base --new-name longchain --description "LongChain CLI project" --author "Your Name"
   ```

3. The new project name must not contain spaces.
4. If you rename manually, update `pyproject.toml` (`name`, script entry), `env/.env.*` (`APP_NAME`), and optionally `src/app.py`, `.vscode/settings.json`, and docs.
5. If you rename manually, recreate `.venv` (recommended), run `python -m venv .venv`, `bash scripts/patch_venv_activate.sh`, then `pip install -e ".[dev]"`.
6. If you copied the hook files and renamed manually, run `npm install` and `npm run prepare`.
7. The helper script also updates `package.json` / `package-lock.json` when present, refreshes `.venv`, runs `pip install -e ".[dev]"`, and optionally runs npm setup.
8. Refresh the terminal if the new CLI is not picked up immediately:

   ```bash
   hash -r
   source .venv/Scripts/activate
   ```

**Result:** Reusable template for any future Python CLI/service project.

---

## Comparison with `practice` project

| Feature | practice | base (skeleton) |
|---------|----------|-----------------|
| Env files (`env/.env.*`) | Yes | Yes |
| `--env` flag | Yes | Yes |
| `--watch` + watchdog | Yes | Yes |
| Logging to stdout | Yes | Yes |
| File logging | No | Yes (`logs/app.log`) |
| LangChain / AI deps | Yes | No (minimal skeleton) |
| Dev serve env var | `PRACTICE_DEV_SERVE` | `APP_DEV_SERVE` (generic) |
| Git Bash activate fix | No | Yes (`patch_venv_activate.sh`) |
| Cursor terminal profile | No | Yes (`.vscode/settings.json`) |

---

## Next steps

- Add your business logic in `src/app.py` or new modules.
- Register new modules in `pyproject.toml` `[tool.setuptools] py-modules`.
- Add secrets to `env/.env.*` (never commit real API keys to public repos).
- After `python -m venv .venv`, always run `bash scripts/patch_venv_activate.sh`.
- See [CHALLENGES.md](CHALLENGES.md) for troubleshooting flowcharts.
