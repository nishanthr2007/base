/** @type {import('@commitlint/types').UserConfig} */
const TYPES =
  "feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert";

module.exports = {
  extends: ["@commitlint/config-conventional"],
  parserPreset: {
    parserOpts: {
      // type(scope): subject — scope required, non-empty; spaces allowed in scope
      // Scope must start with a non-whitespace character (rejects feat( ): ...)
      headerPattern: new RegExp(`^(${TYPES})\\(([^)\\s][^)]*)\\): (.+)$`),
      headerCorrespondence: ["type", "scope", "subject"],
    },
  },
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "feat",
        "fix",
        "docs",
        "style",
        "refactor",
        "perf",
        "test",
        "build",
        "ci",
        "chore",
        "revert",
      ],
    ],
    "scope-empty": [2, "never"],
    "scope-min-length": [2, "always", 1],
    "scope-case": [0],
    "subject-empty": [2, "never"],
    "subject-case": [2, "never", ["start-case", "pascal-case", "upper-case"]],
    "subject-full-stop": [2, "never", "."],
    "type-empty": [2, "never"],
  },
};
