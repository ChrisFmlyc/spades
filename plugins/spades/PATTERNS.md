# Patterns

Approved patterns, conventions, and libraries for the SPADES framework
itself. AI agents must follow these patterns when generating Plans and
delivering code. If a better approach exists, flag it in the Plan and
get human approval before deviating.

## Code Patterns

- **Prose over code.** Skills are Markdown. Behaviour is described in
  natural language so the agent can reason about it. Resist the
  temptation to write scripts or binaries that "enforce" skill logic —
  that belongs in the prose. The marker-block state machine inside
  `skills/setup/SKILL.md` is the canonical example.
- **Idempotent writes.** Any prose flow that modifies a consumer repo
  (setup, marker-block refresh) must be safe to run twice. Use marker
  blocks, never append. Same inputs → same outputs.
- **Pure-Markdown plugin.** No bash, no helper binaries on PATH, no
  `bin/` directory. The plugin tree contains only `.md` files,
  `.json` manifests, and the `scripts/lint/` CI helpers (Python
  stdlib only).
- **Templates live inside the producing skill.** v2 embeds AGENTS.md,
  INTENT.md, ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md
  scaffolding, Scope body shape, and Plan body shape inline in the
  SKILL.md that produces each one. There is no separate `templates/`
  or `fragments/` directory.

## Project Structure

```text
spades/                                       # repo root (this repo)
├── .claude-plugin/
│   └── marketplace.json                      # marketplace entry
├── .github/workflows/lint.yml                # CI lint jobs
└── plugins/
    └── spades/                               # the SPADES plugin
        ├── .claude-plugin/
        │   └── plugin.json                   # plugin manifest
        ├── skills/<name>/SKILL.md            # one directory per skill (15 skills)
        ├── agents/<name>.md                  # subagent definitions (4 reviewers + researcher)
        ├── docs/
        │   ├── FRAMEWORK.md                  # canonical framework reference
        │   └── EXTENDING-BACKENDS.md         # contract for adding a backend driver
        ├── examples/                         # worked example Scopes, Plans, Intent + fixture repos
        ├── scripts/lint/                     # CI lint scripts (Python 3.11 stdlib + bash)
        ├── tests/fixtures/local-frontmatter/ # planted fixtures for lint self-tests
        ├── .spades/                          # SPADES dogfooding its own loop
        │   ├── version                       # spades_version pin for this repo
        │   ├── config                        # backend + active project
        │   ├── projects/                     # project records
        │   ├── scopes/                       # scope records (S-<slug>.md)
        │   ├── plans/                        # plan records (P-<slug>-<suffix>[-<dep>...].md)
        │   ├── learnings/                    # compounding learnings store
        │   └── reviews/                      # persisted panel-review reports (gitignored)
        ├── ARCHITECTURE.md                   # this project's own architecture
        ├── PATTERNS.md                       # this file
        ├── ANTI-PATTERNS.md                  # this project's own anti-patterns
        ├── INTENT.md                         # this project's durable intent
        ├── AGENTS.md                         # mandatory rules for AI agents (cross-vendor)
        ├── CHANGELOG.md
        └── README.md                         # quick start + philosophy
```

There is no `fragments/` or `templates/` directory in v2 — every
template the framework injects into a consumer repo lives inline in
the SKILL.md of the producing skill.

## Data Patterns

- **Markdown + YAML frontmatter** is the only data format. Skills,
  examples, and architecture docs are all Markdown. Structured
  metadata lives in flat-key YAML frontmatter (no nested structures —
  see the stdlib-only parser in `scripts/lint/frontmatter.py`).
- **Marker blocks** delimit framework-owned regions in consumer
  `AGENTS.md`: `<!-- SPADES-FRAMEWORK-START vX.Y.Z -->` /
  `<!-- SPADES-FRAMEWORK-END -->`. The marker-replace state machine
  inside `skills/setup/SKILL.md` is the single source of truth for
  the rewrite contract.
- **`.spades/version`** is a `key=value` text file, not YAML or JSON
  (the file is tiny and machine-readable as plain text).
- **`.spades/config`** is YAML. Records `backend:` (`linear` or
  `local`), `project:` (the active project slug), and an optional
  driver-specific block (`linear:` with `team_id` / `project_id`).
- **IDs are semantic.** Projects use `<project-slug>`. Scopes use
  `S-<description-slug>`. Plans use
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`. Learnings
  use `YYYY-MM-DD-<short-slug>`. See `docs/FRAMEWORK.md` § ID Format.
- **Plugin path references** are not needed in v2. Skills do NOT
  cross-reference siblings via `${CLAUDE_PLUGIN_ROOT}/...` — the
  Claude Code runtime auto-loads bundled agents by name, and skills
  carry their own templates inline. The substitution is still
  technically supported but unused by this plugin.

## Integration Patterns

- **Backend interface** is documented in `docs/FRAMEWORK.md` § Backend
  Interface. Skills call the documented operations
  (`create_scope`, `record_approval`, etc.); the active backend driver
  (Linear MCP or local FS) implements them. Other MCPs become
  backends by writing a driver — see `docs/EXTENDING-BACKENDS.md`.
- **Explicit backend selection.** `.spades/config` carries an explicit
  `backend:` field set by `/spades:setup`. No auto-probe, no silent
  degradation.
- **No other external services** are wired in by default. Consumer
  projects add their own integrations.

## Deployment Patterns

- **"Deployment" is `/plugin update`.** Claude Code's plugin
  marketplace handles distribution. There is no separate release
  pipeline beyond the version bump in
  `plugins/spades/.claude-plugin/plugin.json` (mirrored in
  `.claude-plugin/marketplace.json`) and the git tag.
- **Versioning** is semver. The plugin's `version` field is the
  source of truth. The AGENTS.md marker block carries the version so
  consumers can see which framework version wrote their docs section.
  Re-running `/spades:setup` after a plugin upgrade re-stamps the
  marker block in place.
- **Breaking changes** to skill contracts or frontmatter schemas must
  bump the major version. The marker-replace state machine handles
  the consumer-file refresh.

## Approved Libraries

| Purpose       | Library / Tool          | Version | Notes |
|---------------|-------------------------|---------|-------|
| Skill format  | Markdown + YAML frontmatter | n/a | The only runtime "language" |
| Backend       | Linear (via Linear MCP), local filesystem | n/a | Two drivers in-tree; others via `docs/EXTENDING-BACKENDS.md` |
| CI lints      | Python 3.11 stdlib + bash | n/a   | Lives in `scripts/lint/` only; never ships at runtime |
| CI runner     | GitHub Actions          | n/a     | For lint validation on every PR |

No npm / pip / cargo / go modules. No compiled code in the plugin
tree. If a future change requires one, it is a major architectural
shift and must be scoped explicitly.

## Documentation Patterns

- **Every skill has a SKILL.md.** It IS the skill — there is nothing
  else. Behaviour lives in prose, not in a sidecar binary.
- **Each skill embeds its own templates.** The setup skill carries
  the AGENTS.md marker-block content and the ARCHITECTURE / PATTERNS
  / ANTI-PATTERNS scaffolding inline. The intent skill carries the
  INTENT.md template. The scope and plan skills carry their body
  shapes. Editing a template means editing the producing skill.
- **The single source of truth** for framework contracts is
  `docs/FRAMEWORK.md`. Skills link to its sections (`§ ID Format`,
  `§ Backend Interface`, `§ Fast-Track Path`) rather than restating.
- **Architecture docs at the plugin root** (`ARCHITECTURE.md`,
  `PATTERNS.md`, `ANTI-PATTERNS.md`, `INTENT.md`) apply to this repo
  itself. Consumer repos get blank templates scaffolded by
  `/spades:setup` and fill them in with their own content.
- **Worked examples** (`examples/example-scope.md`,
  `examples/example-plan.md`, `examples/example-intent.md`) are the
  canonical shape consumers can reference. Keep them in sync with the
  v2 schemas.
