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
| **pre-commit** | `git commit` | `lint-staged` → `ruff check --fix` + `ruff format` on **staged** `*.py` only |
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

## Manual commands

```bash
npm run lint          # ruff check src/
npm run format        # ruff format src/
npm run lint:staged   # same as pre-commit (all staged *.py)
ruff check --fix src/
ruff format src/
```

## Copying this skeleton

Include in the new project (do not copy `node_modules/`):

- `package.json`, `package-lock.json` (after `npm install`)
- `commitlint.config.js`
- `.husky/`

Then run `npm install` and `npm run prepare` in the new repo.

## Bypass hooks (emergency only)

```bash
git commit --no-verify -m "chore: emergency fix"
```

Not recommended for normal workflow.
