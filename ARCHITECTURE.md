# Architecture

This document defines the system architecture, infrastructure, and technical
constraints for this project. AI agents must read this file before generating
any Plan. Proposed solutions that conflict with this document must be flagged
and require explicit human approval before proceeding.

## System Overview

SPADE is a **convention + skills framework** for human–AI collaboration on
software engineering work. It is not a runtime, a service, or a package.

- **Users** are engineers working in Claude Code (or any compatible Anthropic
  agent environment) who want a documented, auditable loop for AI-assisted
  delivery.
- **Surface area** is a set of Claude Code skills (`.claude/skills/spade-*/SKILL.md`),
  a small number of shell setup scripts, markdown architecture templates, and
  fragment files that are injected into consumer repos during onboarding.
- **Core loop** is five phases with explicit ownership: Scope (human) → Plan
  (AI) → Approve (human) → Deliver (AI or human) → Evaluate (human).

The "system" is a set of files. There is no server, no database, no compiled
artefact, no runtime agent of our own. Behaviour emerges from skill prose that
the agent reads and follows.

## Infrastructure

- **Distribution:** git repository, installed by cloning and running `./setup`
  (bash) or `./setup.ps1` (PowerShell). Copies skills into `~/.claude/skills/`.
- **Storage:** per-project state in `.spade/` (version pin, config, examples,
  docs copy). Intended to be committed alongside project code.
- **Integrations:** Linear (via Anthropic's Linear MCP server) for issue
  tracking. No other external services.
- **Runtime:** whatever agent environment invokes the skills (Claude Code is
  the primary target; skills are portable Markdown).

There is no cloud provider, no orchestration, no container runtime owned by
this repo.

## Data Flow

1. Human writes a **Scope** in Linear (or any tracker) as a parent issue.
2. `/spade-plan` reads the Scope + architecture docs, produces a Plan document,
   and creates sub-issues grouped into delivery bundles.
3. `/spade-approve` gates the Plan; a human approves or rejects.
4. `/spade-review` (optional) spawns an independent reviewer for a second
   opinion on the Scope, the Plan, or both.
5. Delivery happens one bundle at a time: one branch → one PR → one or more
   sub-issues closed.
6. `/spade-evaluate` checks delivered output against acceptance criteria.
7. A human transitions the parent issue to Done.

Local state: `.spade/plans/` captures approved Plans as checked-in artefacts so
they are not lost if the Linear issue is edited.

## Tech Stack

| Layer          | Technology                        | Notes                                                                 |
|----------------|-----------------------------------|-----------------------------------------------------------------------|
| Skill format   | Markdown with YAML frontmatter    | `.claude/skills/<name>/SKILL.md`                                      |
| Setup          | Bash (`setup`) + PowerShell       | Copies skills into `~/.claude/skills/`; must stay feature-parity      |
| Utilities      | Bash (`bin/spade-update-check`, `bin/spade-marker-replace`) | Both bash 3.2-safe (macOS floor). `spade-update-check` must always exit 0. `spade-marker-replace` is the idempotent consumer-file mutator used by `/spade-onboard` and `/spade-update`; bash-only — Windows consumers use Git-Bash or WSL (see "External Toolchain Policy" below). Setup stays dual-shell (`setup` + `setup.ps1`). |
| Issue tracking | Linear (via Linear MCP)           | Primary integration. Other trackers are supported but manual.         |
| Agents         | Claude Code (primary)             | Skills are portable; behaviour is prose, not code                     |
| Versioning     | Fragment markers (`<!-- SPADE-FRAMEWORK-START vX.Y.Z -->`) | Gates idempotent onboarding                                           |
| CI             | GitHub Actions (`.github/workflows/lint.yml`) | Runs on every PR; 6 parallel lint jobs (skill-frontmatter, agents, examples, fragments, learnings, onboard-idempotency). Uses `actions/setup-python@v5` pinned to 3.11 for the stdlib-only frontmatter parser. |

## External Toolchain Policy

Two toolchains live outside the "Markdown + shell" core and are permitted
**only** under the narrow conditions below. New toolchain additions
require a new Scope; this section should not be interpreted as a general
permit.

### Python is allowed for CI lint only — never at runtime

`scripts/lint/frontmatter.py` and any other `scripts/lint/*.py` use the
**Python 3.11 standard library only**. No `requirements.txt`, no `pip`,
no third-party packages. This is acceptable because:

- CI-only: Python never ships to a consumer repo or runs in an agent
  session — it executes inside GitHub Actions via
  `actions/setup-python@v5`.
- Stdlib-only: no supply-chain surface beyond Python itself and the
  pinned GitHub Action version.
- Bounded: confined to `scripts/lint/`. Any proposal to use Python
  outside this directory — including "just a small helper" in
  `bin/` or a skill — is a runtime dependency and forbidden by
  `ANTI-PATTERNS.md#dependency-anti-patterns`.

If a future lint genuinely needs a non-stdlib YAML parser or similar, the
correct response is to simplify the schema, not to add `requirements.txt`.

### Windows consumers need Git-Bash or WSL for `/spade-update` migration

`bin/spade-marker-replace` is bash. There is no PowerShell twin. Windows
consumers who run `/spade-update` — specifically the v1.0.0 → v1.1.x
fragment-marker migration step — must do so from **Git-Bash** or
**WSL**, not native PowerShell.

Rationale:

- Claude Code on Windows already assumes a POSIX-shell posture for most
  skills. Running `/spade-update` from Git-Bash or WSL is the same shell
  environment consumers already use.
- A PowerShell twin of `spade-marker-replace` would roughly double the
  helper's surface and require its own fixture tests to keep behaviour
  parity with the bash version — high maintenance cost, low incremental
  value for a tool that runs once per minor version bump.
- Dual-shell parity is still enforced for `setup` and `setup.ps1` —
  those run once per install and must remain cross-shell.
  `spade-marker-replace` is not a setup script; it is a migration helper
  called from a skill.

If Windows-native `/spade-update` becomes a real need, the fix is a
focused Scope that ships `bin/spade-marker-replace.ps1` with its own
fixture tests, not an ad-hoc PowerShell rewrite.

## Security Requirements

- **No secrets in the repo.** Skills, examples, and fragments are public.
- **No arbitrary code execution from remote sources** during `setup` or
  `spade-update-check` beyond what is explicitly vendored or fetched from the
  pinned git remote.
- **Linear MCP permissions** must be declared in `.claude/settings.local.json`
  per consumer project; the framework does not auto-grant.
- **Setup scripts must be safe to re-run.** Idempotency is a security property
  here: non-idempotent onboarding can duplicate configuration and hide
  malicious insertions on re-run.

## API Conventions

- **Skill invocation:** slash-commands (`/spade-scope`, `/spade-plan`, etc.).
- **Skill frontmatter** (YAML) is the contract between the framework and the
  agent runtime. All skills carry at minimum `name` and `description`; richer
  fields (e.g. `phase`, `requires_mcp`, `min_spade_version`) may be added.
- **Linear labels** form a stable taxonomy. Full-loop: `ai-planned`,
  `ai-delivered`, `human-delivery`, `plan-rejected`, `needs-arch-review`,
  `bundle:<name>`. Fast-track: `spade:quick`, `type:bug|tweak|chore|docs|refactor`.
- **Fragment markers** (`<!-- SPADE-FRAMEWORK-START vX.Y.Z -->` …
  `<!-- SPADE-FRAMEWORK-END -->`) delimit framework-owned regions inside
  consumer `AGENTS.md` / `CLAUDE.md`. Only content between these markers may
  be rewritten by `/spade-onboard` or `/spade-update`.

## Testing Requirements

- **No runtime unit tests** are expected — there is no runtime to test.
- **Framework validation tests** should cover: (a) skill frontmatter parses
  and carries required fields; (b) example Scopes and Plans in `examples/`
  conform to the documented schema; (c) fragments insert idempotently into
  consumer `AGENTS.md` / `CLAUDE.md`; (d) setup scripts succeed on a clean
  `$HOME`; (e) bash and PowerShell setup produce the same installed file set.
- **CI** runs the above on every PR via `.github/workflows/lint.yml` —
  6 parallel jobs (skill-frontmatter, agents, examples, fragments,
  learnings, onboard-idempotency). Shipped in Bundle C (v1.1); extended
  by the agents lint in Bundle E.
- **Consumer projects** are responsible for their own test suites — SPADE does
  not mandate a testing approach, only that Plans describe one.
