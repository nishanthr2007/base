# Renaming the Project / Using as a Skeleton

This guide explains what happens when you **rename the folder** vs when you **rename the project** (package name, CLI command, and config). Use it when copying `base` to a new app or keeping a generic template.

---

## Folder rename vs project rename


| Action                                          | What changes                                 | What stays the same                                      |
| ----------------------------------------------- | -------------------------------------------- | -------------------------------------------------------- |
| **Rename folder only** (e.g. `base` → `my-api`) | Directory path on disk                       | CLI still runs as `base` until you edit `pyproject.toml` |
| **Full project rename**                         | Package name, CLI command, `APP_NAME` in env | Source layout (`src/`, `env/`, `logs/`) stays the same   |


**Summary:** Renaming the directory is fine for organization. For a **new application name and CLI**, you must update config files and reinstall the virtual environment.

---

## Fast rename with script

Instead of updating files manually, you can use the included rename helper:

Run this from the **repo root**:

```bash
bash scripts/rename_project.sh --old-name base --new-name longchain
```

Short version, since `base` is already the default old name:

```bash
bash scripts/rename_project.sh longchain
```

Project names must not contain spaces.

If you also want to set the project description and author in the same run:

```bash
bash scripts/rename_project.sh --old-name base --new-name longchain --description "LongChain CLI project" --author "Your Name"
```

What the script updates:

- `pyproject.toml` project name and CLI entry
- `env/.env.dev`, `env/.env.qa`, `env/.env.prod` → `APP_NAME`
- `src/app.py` default `APP_NAME` fallback
- `.vscode/settings.json` terminal profile label, when present
- `package.json` name/description, when present
- `package-lock.json` name, when present
- `README.md`, `SETUP.md`, `SETUP_STEPS.md`, and `CHALLENGES.md` (unless you pass `--skip-docs`)
- `.venv` recreation by default (unless you pass `--keep-venv`)
- `pip install -e ".[dev]"` after rename
- npm hook setup by default (unless you pass `--skip-npm` and `package.json` exists)

Useful options:

```bash
--skip-docs   # do not rewrite README.md, SETUP.md, SETUP_STEPS.md, CHALLENGES.md
--keep-venv   # keep existing .venv instead of recreating it
--skip-npm    # skip npm install and npm run prepare
```

Notes:

- `--skip-docs` only skips `README.md`, `SETUP.md`, `SETUP_STEPS.md`, and `CHALLENGES.md`
- `RENAME.md` and `HOOKS.md` are not rewritten by the script
- `--keep-venv` keeps the existing `.venv`, but the script still upgrades `pip` and runs `pip install -e ".[dev]"`
- If `.venv` is missing, the script creates one even when `--keep-venv` is used
- The script requires these files to exist before it runs: `pyproject.toml`, `src/app.py`, `env/.env.dev`, `env/.env.qa`, `env/.env.prod`

If you want to see the built-in help:

```bash
bash scripts/rename_project.sh --help
```

---

## What you must update

Example: new project name `**my-api`**, CLI command `**my-api**`.


| Priority        | File                                                       | What to change                                                                                           |
| --------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **Required**    | `pyproject.toml`                                           | `[project] name = "my-api"`                                                                              |
| **Required**    | `pyproject.toml`                                           | `[project.scripts]` → `my-api = "main:main"`                                                             |
| **Required**    | `env/.env.dev`                                             | `APP_NAME=my-api`                                                                                        |
| **Required**    | `env/.env.qa`                                              | `APP_NAME=my-api`                                                                                        |
| **Required**    | `env/.env.prod`                                            | `APP_NAME=my-api`                                                                                        |
| **Recommended** | `pyproject.toml`                                           | `authors`, `description` (optional)                                                                      |
| **Optional**    | `src/app.py`                                               | Default fallback: `os.environ.get("APP_NAME", "base")` → `"my-api"` (env files override this at runtime) |
| **Optional**    | `.vscode/settings.json`                                    | Profile label `"Git Bash (base)"` → `"Git Bash (my-api)"` (cosmetic only)                                |
| **Optional**    | `README.md`, `SETUP.md`, `SETUP_STEPS.md`, `CHALLENGES.md` | Examples and titles (only if you want docs to match the new name)                                        |


### `pyproject.toml` example

```toml
[project]
name = "my-api"
# ...
authors = [{ name = "Your Name" }]

[project.scripts]
my-api = "main:main"
```

### Environment files example

```bash
# env/.env.dev (and .env.qa, .env.prod)
APP_NAME=my-api
```

---

## What you do not need to change

These files are **name-agnostic** and work after a rename without edits:


| Path                             | Why                                    |
| -------------------------------- | -------------------------------------- |
| `src/main.py`                    | No hardcoded project name              |
| `src/load_env.py`                | Loads `env/.env.<ENVIRONMENT>` by path |
| `src/core.py`                    | Generic business logic                 |
| `scripts/patch_venv_activate.sh` | Uses paths relative to project root    |
| `scripts/activate.sh`            | Uses paths relative to project root    |
| `logs/`                          | Same for any project name              |
| `env/` layout                    | Same file names (`.env.dev`, etc.)     |


Environment variable `APP_DEV_SERVE` is generic (not tied to `base`).

---

## Step-by-step: copy skeleton to a new project

Replace `my-api` with your project name.

### 1. Copy the folder

```bash
cp -r base my-api
cd my-api
```

Or rename in Explorer: `base` → `my-api`.

If the copied project still uses the default template name `base`, you can rename it from the repo root with:

```bash
bash scripts/rename_project.sh my-api
```

After the script finishes in an already-open terminal, refresh the shell command cache:

```bash
hash -r
source .venv/Scripts/activate
my-api -v --env dev
```

#### What to skip when copy-pasting


| Directory          | Skip when copying?    | Why                                                                                                                                                                           |
| ------------------ | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `**.venv/**`       | **Yes — always skip** | Tied to the old folder path and package name (`base`). Contains machine-specific binaries. Create a fresh venv in the new project.                                            |
| `**.vscode/`**     | **Optional**          | Not required for the app to run. Helpful in Cursor (Git Bash PATH + profile). Copy if you want the same terminal setup; skip if you use PowerShell or will set PATH yourself. |
| `**logs/*.log`**   | **Yes**               | Runtime files; recreated when you run the app.                                                                                                                                |
| `**__pycache__/`** | **Yes**               | Auto-generated.                                                                                                                                                               |


**Minimum copy:** `src/`, `env/`, `scripts/`, `logs/.gitkeep`, `pyproject.toml`, `.gitignore`, and docs (`README.md`, `SETUP*.md`, etc.).

**If you want the same git-hook setup too:** also copy `package.json`, `package-lock.json`, `commitlint.config.cjs`, and `.husky/`.

**After copy (required):**

```bash
cd my-api
python -m venv .venv
bash scripts/patch_venv_activate.sh
pip install -e ".[dev]"
npm install
npm run prepare
```

If you use the helper script instead of editing files manually, you can replace the manual rename steps with:

```bash
bash scripts/rename_project.sh my-api
```

### 2. Edit required files

1. `**pyproject.toml**`
  - `name = "my-api"`
  - `[project.scripts]` → `my-api = "main:main"`
2. `**env/.env.dev**`, `**env/.env.qa**`, `**env/.env.prod**`
  - `APP_NAME=my-api`

### 3. Recreate virtual environment (recommended)

Old `.venv` was built for package name `base` and installs a `base` executable. A fresh venv avoids confusion.

```bash
rm -rf .venv
python -m venv .venv
bash scripts/patch_venv_activate.sh
source .venv/Scripts/activate    # Git Bash
# .\.venv\Scripts\Activate.ps1   # PowerShell
python -m pip install --upgrade pip
pip install -e ".[dev]"
npm install
npm run prepare
```

The helper script performs this setup for you automatically unless you pass `--keep-venv` and/or `--skip-npm`.

### 4. Verify

```bash
my-api
my-api -v --env dev
my-api 10 20 30
my-api --watch --env dev -v
```

Expected log line (example):

```
[INFO] app: App started | name=my-api | environment=dev | log_level=DEBUG
```

### 5. Optional cleanup

- Update `README.md` title and examples.
- Rename Cursor profile in `.vscode/settings.json` if you use it.
- Keep or remove the hook files depending on whether you want Husky + commitlint + lint-staged in the copied project.
- Remove or rewrite setup docs if this copy is a real app, not a template.

---

## If you keep the existing `.venv`

You can avoid deleting `.venv` if you only changed `pyproject.toml` and env files:

```bash
source .venv/Scripts/activate
pip install -e ".[dev]"
npm install
npm run prepare
```

Then run the **new** CLI name (`my-api`). The old `base` command may remain in `.venv/Scripts/` until you reinstall; ignore or delete it.

Still run after any `python -m venv .venv`:

```bash
bash scripts/patch_venv_activate.sh
```

---

## Two common workflows


| Goal                         | Folder name                      | File updates                                      | CLI      |
| ---------------------------- | -------------------------------- | ------------------------------------------------- | -------- |
| **Keep as generic skeleton** | `base` or `skeleton`             | None required                                     | `base`   |
| **Start a real application** | e.g. `my-api`, `billing-service` | `pyproject.toml` + `APP_NAME` in all `env/.env.`* | `my-api` |


### Keep as skeleton (template)

- Leave folder as `base` (or rename to `skeleton` for clarity only).
- Do **not** change `pyproject.toml` if you want the template to stay `base`.
- Keep the hook files only if you want every copied project to start with the same Husky/commitlint/lint-staged workflow.
- For each new app: **copy** the folder, then follow [Step-by-step](#step-by-step-copy-skeleton-to-a-new-project) on the copy.
- If you use the helper script, run it from the copied repo root: `bash scripts/rename_project.sh your-project-name`

### Start a real project

- Copy `base` → `your-project-name`.
- Update required files in the table above.
- New venv + `pip install -e ".[dev]"`, or use the helper script to do that automatically.
- If you copied hook files, run `npm install` and `npm run prepare`, or let the helper script do it unless you pass `--skip-npm`.
- Customize `src/app.py` with your logic.

---

## Rename checklist (copy-paste)

Use when creating a new project from this skeleton:

```
[ ] Copy folder: base → _______________
[ ] pyproject.toml: [project] name
[ ] pyproject.toml: [project.scripts] CLI entry
[ ] env/.env.dev:   APP_NAME
[ ] env/.env.qa:    APP_NAME
[ ] env/.env.prod:  APP_NAME
[ ] (optional) src/app.py: default APP_NAME fallback
[ ] (optional) .vscode/settings.json: terminal profile label
[ ] (optional) package.json / package-lock.json: name + description
[ ] (optional) copy hook files: package.json, package-lock.json, .husky/, commitlint.config.cjs
[ ] rm -rf .venv && python -m venv .venv
[ ] bash scripts/patch_venv_activate.sh
[ ] pip install -e ".[dev]"
[ ] (if using hooks) npm install && npm run prepare
[ ] hash -r && reactivate terminal
[ ] Run: <new-cli-name>
[ ] Run: <new-cli-name> --watch --env dev -v
```

---

## Quick reference: where names appear

```mermaid
flowchart LR
    subgraph required [Required updates]
        A[pyproject.toml name]
        B[project.scripts CLI]
        C[env/.env.* APP_NAME]
    end
    subgraph optional [Optional]
        D[src/app.py default]
        E[.vscode profile label]
        F[Documentation]
    end
    subgraph unchanged [Unchanged]
        G[src/main.py]
        H[scripts/*]
        I[logs/ structure]
    end
    A --> CLI[.venv/Scripts/my-api]
    B --> CLI
    C --> LOG[App log output]
```



---

## Related documentation


| File                             | Contents                               |
| -------------------------------- | -------------------------------------- |
| [SETUP.md](SETUP.md)             | Setup commands and project layout      |
| [SETUP_STEPS.md](SETUP_STEPS.md) | Full setup walkthrough                 |
| [HOOKS.md](HOOKS.md)             | Husky, commitlint, lint-staged flow    |
| [CHALLENGES.md](CHALLENGES.md)   | Troubleshooting (Git Bash, watch mode) |
| [README.md](README.md)           | Project overview                       |


