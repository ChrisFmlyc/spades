# SPADE Lint

Five small lints that guard the framework's shape. CI runs them on every
PR; run them locally before pushing with:

```bash
./scripts/lint/run-all.sh
```

## What each check does

| Script                          | What it guards                                                                                                                        |
|---------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `lint-skill-frontmatter.sh`     | Every `.claude/skills/*/SKILL.md` parses and carries `name` + `description`.                                                         |
| `lint-examples.sh`              | `example-scope.md` has Intent / Acceptance Criteria / Constraints sections; `example-plan.md` carries `Execution posture:` on every task using the locked vocabulary. |
| `lint-fragments.sh`             | `fragments/*.md` carry no `SPADE-FRAMEWORK-*` markers (fragments are raw content; markers are added on insertion). `.spade/version` pins a valid `spade_version=X.Y.Z`. |
| `lint-learnings.sh`             | `.spade/learnings/*.md` carry the required learning frontmatter (`title`, `area`, `tags`, `created`, `status`, `public_safe`); `area` and `status` are in-vocabulary; `created` is `YYYY-MM-DD`. Warns on active entries older than 180 days. |
| `lint-onboard-idempotency.sh`   | Re-runs `tests/onboard-idempotency.sh` — 15 assertions against the Bundle A marker-replace contract.                                |

## Dependencies

- `bash` (3.2+, macOS-friendly)
- `python3` (3.11+; only used by `frontmatter.py`, stdlib only — no
  `requirements.txt`, by design)
- `awk`, `grep`, `diff` (POSIX; any modern shell has these)

No npm, no pip install, no external YAML libraries. If a future check
needs more than flat-key frontmatter, simplify the schema or accept
PyYAML — but update `ANTI-PATTERNS.md` first.

## Running a single check

```bash
./scripts/lint/lint-skill-frontmatter.sh
./scripts/lint/lint-examples.sh
./scripts/lint/lint-fragments.sh
./scripts/lint/lint-learnings.sh
./scripts/lint/lint-onboard-idempotency.sh
```

Each script exits 0 on success and non-zero with a clear failure line on
error. `run-all.sh` is a thin wrapper that runs all five and aggregates
exit status.

## Adding a new check

1. Drop a `lint-<name>.sh` in this directory.
2. Make it executable (`chmod +x`).
3. Add it to the `scripts` array in `run-all.sh`.
4. Add a matching job in `.github/workflows/lint.yml`.
5. Document it in the table above.

Keep each lint small and focused. A lint that covers two orthogonal
concerns is two lints.
