# Git Hooks (Husky + Conventional Commits + Ruff)

Pre-commit and commit-msg hooks for linting/formatting **staged** Python files and enforcing [Conventional Commits](https://www.conventionalcommits.org/).

## Prerequisites

- **Node.js 18+** (for Husky, commitlint, lint-staged)
- **Python venv** with dev extras (for `ruff` on PATH)

## One-time setup

```bash
# Python lint/format tool
pip install -e ".[dev]"

# Node hook tooling
npm install

# Husky installs hooks via package.json "prepare" script
npm run prepare
```

## What runs when

| Hook | Trigger | Action |
|------|---------|--------|
| **pre-commit** | `git commit` | `lint-staged --no-stash` → format, auto-fix, then **strict** `ruff check` on staged `*.py`; if lint fails or auto-fixes change files, details are written to `logs/lint-staged.log` and commit **aborted** |
| **commit-msg** | After message entered | `commitlint` validates conventional commit format |

## Conventional commit format

**Required pattern:** `type(scope): subject`

- **`type`** — commit category (see list below)
- **`(scope)`** — short context in parentheses (required, non-empty; spaces allowed)
- **`subject`** — description after `: ` (colon + space)

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Valid examples:**

```bash
git commit -m "feat(quick message): add billing module"
git commit -m "fix(cli): handle empty stats input"
git commit -m "docs(setup): update RENAME guide for copy-paste"
git commit -m "chore(hooks): add husky and commitlint"
```

**Invalid examples:**

```bash
git commit -m "feat: add billing module"           # missing (scope)
git commit -m "feat(): add billing module"         # empty scope in ()
git commit -m "feat( ): add billing module"       # whitespace-only scope
git commit -m "add billing module"               # missing type and scope
git commit -m "feat(billing)add module"          # missing ": " after scope
git commit -m "updated stuff"                    # not conventional format
```

## Pre-commit lint flow (staged `*.py` only)

1. `ruff format` — apply formatting  
2. `ruff check --fix` — safe auto-fixes  
3. `ruff check` — strict lint (PEP 8 / pyflakes / isort / naming per `pyproject.toml`)  
4. If step 3 fails → write details to **`logs/lint-staged.log`** and **exit 1** (commit cancelled)  
5. If auto-fixes changed any staged file → keep those changes locally, write review instructions to **`logs/lint-staged.log`**, and **exit 1**  
6. If no errors and no auto-fix changes remain → remove `logs/lint-staged.log` if it existed  

Open the log after a failed commit:

```bash
cat logs/lint-staged.log
```

If the hook auto-fixes files, the commit is intentionally stopped. Review the changes, run `git add ...`, then commit again.

## Manual commands

```bash
npm run lint          # ruff check src/
npm run format        # ruff format src/
npm run lint:staged   # same as pre-commit (all staged *.py)
python -m ruff check src/
python -m ruff format src/
```

## Copying this skeleton

Include in the new project (do not copy `node_modules/`):

- `package.json`, `package-lock.json` (after `npm install`)
- `commitlint.config.cjs`
- `.husky/`

Then run `npm install` and `npm run prepare` in the new repo.

## Bypass hooks (emergency only)

```bash
git commit --no-verify -m "chore: emergency fix"
```

Not recommended for normal workflow.
