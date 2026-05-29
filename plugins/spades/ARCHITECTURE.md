# Architecture

This document defines the system architecture, infrastructure, and
technical constraints for this project — the SPADES framework itself.
AI agents must read this file before generating any Plan. Proposed
solutions that conflict with this document must be flagged and require
explicit human approval before proceeding.

## System Overview

SPADES is a **convention + skills framework** for human–AI
collaboration on engineering work. It is not a runtime, a service, or
a package.

- **Users** are engineers working in any coding agent that honours
  `AGENTS.md` (Claude Code, Cursor, Codex, Aider, …). The SPADES
  Claude Code plugin adds 15 slash-commands; in other agents, the
  rules still apply via `AGENTS.md`.
- **Surface area** is a set of Markdown skill files
  (`plugins/spades/skills/<name>/SKILL.md`), five subagent definitions
  (`plugins/spades/agents/*.md`), framework reference docs under
  `plugins/spades/docs/`, and CI-only lint scripts.
- **Core loop** is six phases with explicit ownership:
  Scope (H) → Plan (AI) → Approve (H gate) → Do (routed) →
  Evaluate (H gate) → Ship (mixed).

The "system" is a set of files. There is no server, no database, no
compiled artefact, no runtime agent of our own. Behaviour emerges from
skill prose that the agent reads and follows.

## Hierarchy

A new layer above Scope, introduced in v2.0:

```
Project (a repo, a service, or a set of repos)
└── Scope (one outcome, S-<description-slug>)
    └── Plan (one unit of executable work, P-<slug>-<suffix>[-<dep>...])
```

Plans can depend on prior plans within the same Scope; the dependency
chain is encoded in the filename and authoritatively in the
`depends_on:` frontmatter field. See `docs/FRAMEWORK.md` § Hierarchy
and § ID Format for the contracts.

## Backend Abstraction

SPADES v2.0 is **backend-agnostic**. The active backend is named
explicitly in `.spades/config` (`backend: linear | local`) — no
auto-probe. Two drivers ship today:

- **Linear** (via the Linear MCP) — Project ↔ Linear Project; Scope ↔
  parent Issue; Plan ↔ sub-issue; audit records post as comments.
- **Local** (filesystem) — every artefact is a Markdown file under
  `.spades/`; audit records append to an `## Audit Trail` heading on
  the relevant record.

Adding a backend (Notion, Confluence, GitHub Issues, …) means writing
a driver against the contract in `docs/FRAMEWORK.md` § Backend
Interface plus per-skill branches. See `docs/EXTENDING-BACKENDS.md` for
the worked example.

## Infrastructure

- **Distribution:** Claude Code plugin, installed from the
  marketplace at the root of this repo
  (`.claude-plugin/marketplace.json`). The plugin tree under
  `plugins/spades/` contains everything the framework needs at
  runtime — skills, agent definitions, docs, examples.
- **Storage:** per-repo state in `.spades/` (`config`, `version`,
  `projects/`, `scopes/`, `plans/`, `learnings/`, `reviews/`).
  Intended to be committed alongside project code, except
  `.spades/reviews/` (full panel-review reports) which is gitignored
  by default.
- **Integrations:** any system reachable via an MCP server. Linear is
  the only driver shipped in-tree today; the rest are extension
  points.
- **Runtime:** any coding agent that honours `AGENTS.md`. Skills are
  pure-Markdown prose the agent reads and follows; behaviour is
  described, not coded. Zero bash in the runtime path.

There is no cloud provider, no orchestration, no container runtime,
no helper binary on PATH owned by this framework.

## Data Flow

1. Human runs `/spades:setup` to bind a backend and bootstrap the
   repo.
2. Human runs `/spades:newproject` to create a Project record (or
   binds to an existing one).
3. Human runs `/spades:scope` to define an outcome. The skill writes
   `.spades/scopes/S-<slug>.md` (and the backend mirror).
4. `/spades:plan` reads the Scope + architecture docs + matching
   learnings, produces a structured Plan, writes
   `.spades/plans/P-<slug>-<suffix>[-<dep>…].md`.
5. `/spades:approve` gates the Plan; a human approves or rejects, and
   records the routing decision (`ai` / `human` / `hybrid`) on the
   Plan.
6. `/spades:do` executes per the routing.
7. `/spades:evaluate` checks delivered output against the Scope's
   acceptance criteria.
8. `/spades:ship` releases the deliverable — PR + review + merge for
   code, or a recorded reference for artefact / action deliverables.

`/spades:review` is available throughout as an independent panel-based
second opinion (advisory, never gating). `/spades:learn` captures
post-hoc knowledge under `.spades/learnings/`, which `/spades:plan`
later surfaces automatically on related Scopes.

## Tech Stack

| Layer            | Technology                              | Notes |
|------------------|------------------------------------------|-------|
| Skill format     | Markdown with YAML frontmatter           | `plugins/spades/skills/<name>/SKILL.md`. Plugin-namespaced as `/spades:<name>`. |
| Distribution     | Claude Code plugin marketplace           | `.claude-plugin/marketplace.json` at repo root; plugin at `plugins/spades/`. |
| Bundled resources| `agents/`, `docs/`, `examples/`          | All siblings of `skills/` in the plugin tree. Skills do NOT cross-reference siblings via `${CLAUDE_PLUGIN_ROOT}` — the runtime auto-loads agents by name and skills carry their own templates inline. |
| Backend drivers  | Linear MCP, local filesystem             | Linear is the only MCP-backed driver shipped today; local is filesystem-only. Other MCPs (Notion, Confluence) are extension points documented in `docs/EXTENDING-BACKENDS.md`. |
| Agents           | Any AGENTS.md-honouring coding agent     | Skills target Claude Code first because of the plugin surface, but the rules in `AGENTS.md` apply to every agent. |
| Versioning       | Marker block + `.spades/version`          | `<!-- SPADES-FRAMEWORK-START vX.Y.Z -->` delimits the framework-owned block inside consumer `AGENTS.md`. Version sourced from `.claude-plugin/plugin.json`. |
| CI               | GitHub Actions (`.github/workflows/lint.yml`) | Parallel lint jobs — see `scripts/lint/README.md` for the list. Python 3.11 (stdlib only) for the frontmatter parser. |

## External Toolchain Policy

Python is the only non-Markdown toolchain permitted in this repo, and
only under the narrow conditions below. New toolchain additions
require a new Scope.

### Python is allowed for CI lint only — never at runtime

`scripts/lint/frontmatter.py` and any other `scripts/lint/*.py` use
the **Python 3.11 standard library only**. No `requirements.txt`, no
`pip`, no third-party packages. This is acceptable because:

- CI-only: Python never ships inside the plugin or runs in an agent
  session — it executes inside GitHub Actions via
  `actions/setup-python@v5`.
- Stdlib-only: no supply-chain surface beyond Python itself and the
  pinned GitHub Action version.
- Bounded: confined to `scripts/lint/`. Any proposal to use Python
  outside this directory is a runtime dependency and forbidden by
  `ANTI-PATTERNS.md#dependency-anti-patterns`.

If a future lint genuinely needs a non-stdlib YAML parser, the correct
response is to simplify the schema, not to add `requirements.txt`.

### No bash in the runtime path

The framework has no helper binaries on `PATH`, no `bin/` directory,
no setup scripts. Everything a skill needs to do — including the
marker-block state machine inside consumer `AGENTS.md` — is described
in skill prose and executed by Claude (or any other agent) through
the standard Read / Edit / Bash tools. This is the property that
makes SPADES cross-platform: it works on macOS, Linux, and native
Windows alike, with no PowerShell parity to maintain.

### Templates and fragments are embedded in skill prose

v1 carried a `templates/` and a `fragments/` directory of files that
the `init` skill copied into consumer repos. v2.0 embeds those
templates directly into the SKILL.md of the producing skill — the
AGENTS.md block lives inside `skills/setup/SKILL.md`, the INTENT.md
template inside `skills/intent/SKILL.md`, the Scope body shape inside
`skills/scope/SKILL.md`, and so on. There is no separate file to copy
and no `${CLAUDE_PLUGIN_ROOT}` substitution needed.

## Security Requirements

- **No secrets in the repo.** Skills, examples, and embedded templates
  are public.
- **No arbitrary code execution from remote sources.** Skills never
  `curl | bash`, never download a script from a remote and run it.
  Plugin distribution is handled by Claude Code itself.
- **Backend MCP permissions** must be declared in
  `.claude/settings.local.json` per consumer project; the framework
  does not auto-grant.
- **Setup must be safe to re-run.** Idempotency is a security property
  here: non-idempotent setup can duplicate configuration and hide
  malicious insertions on re-run.

## API Conventions

- **Skill invocation:** slash-commands (`/spades:scope`,
  `/spades:plan`, …) — the plugin namespace is `spades`.
- **Skill frontmatter** (YAML) is the contract between the framework
  and the agent runtime. All skills carry at minimum `name` and
  `description`.
- **Backend labels** (Linear): full-loop labels are `ai-planned`,
  `ai-delivered`, `human-delivery`, `hybrid-delivery`, `plan-rejected`,
  `needs-arch-review`, `deliverable_type:<value>`; fast-track labels
  are `spades:quick`, `type:bug|tweak|chore|docs|refactor`.
- **Marker block** (`<!-- SPADES-FRAMEWORK-START vX.Y.Z -->` …
  `<!-- SPADES-FRAMEWORK-END -->`) delimits framework-owned regions
  inside consumer `AGENTS.md`. Only content between these markers may
  be rewritten by `/spades:setup`.

## Testing Requirements

- **No runtime unit tests** are expected — there is no runtime to test.
- **Framework validation tests** cover: (a) every skill's frontmatter
  parses and carries required fields; (b) every reviewer/researcher
  agent's frontmatter parses and carries the persona fields;
  (c) example Scopes and Plans under `examples/` conform to the v2
  schemas; (d) every project/scope/plan/learning under `.spades/`
  conforms to the schema, with planted-fixture self-tests in
  `tests/fixtures/local-frontmatter/`; (e) the plugin manifest and
  marketplace manifest parse and carry the expected fields.
- **CI** runs these on every PR via `.github/workflows/lint.yml`. The
  set of lint jobs is enumerated in that workflow.
- **Consumer projects** are responsible for their own test suites —
  SPADES does not mandate a testing approach, only that Plans declare
  one per task (via execution posture).
