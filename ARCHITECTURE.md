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
| Utilities      | Bash (`bin/spade-update-check`)   | POSIX-friendly, must always exit 0                                    |
| Issue tracking | Linear (via Linear MCP)           | Primary integration. Other trackers are supported but manual.         |
| Agents         | Claude Code (primary)             | Skills are portable; behaviour is prose, not code                     |
| Versioning     | Fragment markers (`<!-- SPADE-FRAMEWORK-START vX.Y.Z -->`) | Gates idempotent onboarding                                           |
| CI             | None (as of v1.0.0)               | A minimal GitHub Actions lint is planned                              |

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
- **CI** should run the above on every PR (planned; not yet present).
- **Consumer projects** are responsible for their own test suites — SPADE does
  not mandate a testing approach, only that Plans describe one.
