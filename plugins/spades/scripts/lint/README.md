# SPADES Lint

Small lints that guard the framework's shape. CI runs them on every PR;
run them locally before pushing with:

```bash
./scripts/lint/run-all.sh
```

## What each check does

| Script                          | What it guards |
|---------------------------------|----------------|
| `lint-skill-frontmatter.sh`     | Every `skills/*/SKILL.md` parses and carries `name` + `description`. |
| `lint-agents.sh`                | Every `agents/*.md` parses and carries `name`, `description`, `model`, `tools`, `persona`, `focus`. Skips cleanly if the directory is absent. |
| `lint-examples.sh`              | `examples/example-scope.md` and `examples/example-plan.md` conform to the v2 Scope and Plan schemas; `examples/example-intent.md` has the six locked INTENT sections + `last_reviewed:`; the local-mode fixture's scopes/plans conform. |
| `lint-learnings.sh`             | `.spades/learnings/*.md` carry the required learning frontmatter (`title`, `area`, `tags`, `created`, `status`, `public_safe`); `area` is one of `scope|plan|approve|do|evaluate|ship|other`; `created` is `YYYY-MM-DD`. Warns on active entries older than 180 days. |
| `lint-local-frontmatter.sh`     | `.spades/projects/*.md`, `.spades/scopes/S-*.md`, and `.spades/plans/P-*.md` are schema-valid — hard-fails on invalid IDs, invalid enum values, or missing required fields. Self-tests against four planted fixtures (good/bad scope, good/bad plan). |

## Dependencies

- `bash` (CI-only; not in the plugin runtime)
- `python3` (3.11+; only used by `frontmatter.py`, stdlib only — no
  `requirements.txt`, by design)
- `awk`, `grep`, `diff` (POSIX; any modern shell has these)

No npm, no pip install, no external YAML libraries. If a future check
needs more than flat-key frontmatter, simplify the schema or accept
PyYAML — but update `ANTI-PATTERNS.md` first.

## Running a single check

```bash
./scripts/lint/lint-skill-frontmatter.sh
./scripts/lint/lint-agents.sh
./scripts/lint/lint-examples.sh
./scripts/lint/lint-learnings.sh
./scripts/lint/lint-local-frontmatter.sh
```

Each script exits 0 on success and non-zero with a clear failure line on
error. `run-all.sh` is a thin wrapper that runs them all and aggregates
exit status.

## Adding a new check

1. Drop a `lint-<name>.sh` in this directory.
2. Make it executable (`chmod +x`).
3. Add it to the `scripts` array in `run-all.sh`.
4. Add a matching job in `.github/workflows/lint.yml`.
5. Document it in the table above.

Keep each lint small and focused. A lint that covers two orthogonal
concerns is two lints.
