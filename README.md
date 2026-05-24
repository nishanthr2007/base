# base

A **reusable Python project skeleton** with environment-based configuration, structured logging, file logs, and development watch mode (auto-restart on file changes). Copy this folder, rename it, and use it as a starting point for any new Python CLI or service project.

Modeled after the [practice](../practice) project structure, but stripped to essentials (no AI/LangChain dependencies).

## Python version

**Python 3.10+** required. **Git for Windows** recommended for Git Bash in Cursor.

## Project structure

```
base/
├── .vscode/
│   └── settings.json       # Git Bash profile for Cursor
├── env/                    # .env.dev, .env.qa, .env.prod
├── logs/                   # app.log (runtime, gitignored)
├── scripts/
│   ├── activate.sh         # Git Bash activate helper
│   └── patch_venv_activate.sh
├── src/
│   ├── main.py             # CLI, logging, --watch
│   ├── load_env.py
│   ├── core.py
│   └── app.py              # Customize your app here
├── pyproject.toml
├── README.md
├── SETUP.md
├── SETUP_STEPS.md
├── RENAME.md
└── CHALLENGES.md
```

## Quick start

```bash
python -m venv .venv
bash scripts/patch_venv_activate.sh    # Windows Git Bash — skip on Linux/macOS
source .venv/Scripts/activate          # Windows Git Bash
# source .venv/bin/activate            # Linux/macOS
pip install -e ".[dev]"
base
```

**Cursor:** Open this folder, open a **new** terminal (profile **Git Bash (base)**), then activate as above.

**Without activate:** `.venv/Scripts/base`

## How to run

| Command | What it does |
|---------|----------------|
| `base` | Run default app (dev environment) |
| `base --env qa` | Run with QA config |
| `base -v` | Debug logging |
| `base 1 2 3 4 5` | Stats mode (mean, min, max) |
| `base --watch --env dev -v` | Dev server with auto-reload |

### Examples

```bash
base
base 10 20 30 40 50
base -v --env qa
base --watch -v --env dev
```

## Features

- **Multi-environment config** — `env/.env.dev`, `.env.qa`, `.env.prod` selected via `--env`
- **Logging** — stdout + `logs/app.log` with timestamped format
- **Watch mode** — `watchdog`-based file watcher restarts app on `.py` changes
- **CLI stats mode** — optional numeric args for quick `core.compute_stats` demo
- **Editable install** — `pip install -e .` for fast iteration
- **Git Bash fixes** — patched `activate`, helper scripts, Cursor terminal profile

## Git Bash / Cursor notes

If you see `uname` or `sed: command not found`:

1. Run `bash scripts/patch_venv_activate.sh` after creating the venv.
2. Use a new terminal in Cursor, or `source scripts/activate.sh`.
3. See [SETUP.md](SETUP.md) and [CHALLENGES.md](CHALLENGES.md).

## Reuse as a template

1. Copy the `base` folder to a new directory.
2. Rename folder and update `pyproject.toml` (`name`, `[project.scripts]`).
3. Set `APP_NAME` in `env/.env.*` files.
4. Edit `src/app.py` with your application logic.
5. Run `pip install -e ".[dev]"` and `bash scripts/patch_venv_activate.sh` if using a new venv.

## Documentation

| File | Description |
|------|-------------|
| [SETUP.md](SETUP.md) | Setup commands, layout, Git Bash fixes |
| [SETUP_STEPS.md](SETUP_STEPS.md) | Step-by-step setup walkthrough |
| [RENAME.md](RENAME.md) | Rename folder vs project; copy skeleton checklist |
| [CHALLENGES.md](CHALLENGES.md) | Issues and fixes (Mermaid flowchart) |

## License

MIT
