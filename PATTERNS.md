# Patterns

Approved patterns, conventions, and libraries for this project. AI agents must
follow these patterns when generating Plans and delivering code. If a better
approach exists, flag it in the Plan and get human approval before deviating.

## Code Patterns

- **Prose over code.** Skills are Markdown. Behaviour is described in natural
  language so the agent can reason about it. Resist the temptation to write
  scripts that "enforce" skill logic — that belongs in the prose.
- **Shell portability.** `setup` uses `/bin/bash`, POSIX-safe wherever
  practical. Avoid GNU-only flags. `bin/spade-update-check` must always
  `exit 0` so a failed update check never breaks a skill invocation.
- **Idempotent writes.** Any script that modifies a consumer repo (onboarding,
  update) must be safe to run twice. Use fragment markers, not append.
- **Dual-shell parity.** Every behaviour in `setup` must have a matching
  behaviour in `setup.ps1`. When one changes, the other changes in the same PR.

## Project Structure

```
spade-framework/
├── .claude/skills/spade-*/SKILL.md   # one directory per skill
├── .claude/agents/                    # (planned) subagents for review personas
├── .spade/
│   ├── version                        # spade_version pin for this repo
│   ├── config                         # Linear team + project binding (per repo)
│   ├── docs/FRAMEWORK.md              # committed copy of full reference
│   ├── examples/                      # worked example Scopes/Plans
│   ├── plans/                         # approved Plans persisted locally
│   └── learnings/                     # (planned) compounding learnings store
├── fragments/
│   ├── AGENTS-section.md              # injected into consumer AGENTS.md
│   └── CLAUDE-section.md              # injected into consumer CLAUDE.md
├── docs/FRAMEWORK.md                  # canonical framework reference
├── examples/                          # worked example Scopes/Plans
├── bin/                               # utility scripts
├── setup                              # POSIX installer
├── setup.ps1                          # Windows installer
├── ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md  # this project's own architecture
├── AGENTS.md                          # mandatory rules for AI agents
├── CLAUDE.md                          # Claude Code surface area
└── README.md                          # quick start + philosophy
```

## Data Patterns

- **Markdown + YAML frontmatter** is the only data format. Skills, fragments,
  examples, and architecture docs are all Markdown. Structured metadata lives
  in YAML frontmatter.
- **Fragment markers** delimit framework-owned regions in consumer docs:
  `<!-- SPADE-FRAMEWORK-START vX.Y.Z -->` / `<!-- SPADE-FRAMEWORK-END -->`.
- **`.spade/version`** is a `key=value` text file, not YAML or JSON. Keep it
  that way — it is read by bash.
- **`.spade/config`** is YAML. Records per-repo binding to Linear team +
  project + default assignee.

## Integration Patterns

- **Linear MCP** is the primary tracker integration. Always check whether
  Linear MCP is available before attempting to create issues; fall back to
  asking the human if it is not.
- **Tracker-agnostic skills.** Skill prose must degrade gracefully when Linear
  is unavailable: e.g. `/spade-plan` must be able to produce a Plan document
  in-file without requiring an issue to exist.
- **No other external services.** The framework does not call out to GitHub,
  Slack, email, or any other integration. Consumer projects add their own.

## Deployment Patterns

- **"Deployment" is `git pull` + `./setup`.** No build, no packaging, no
  release pipeline owned by this repo.
- **Versioning** is coarse: the `.spade/version` file records a `spade_version`
  string. Fragments carry version markers so consumers can see which framework
  version wrote their docs section.
- **Breaking changes** to skill contracts must bump the major version and
  update the fragment marker version so `/spade-update` can rewrite safely.

## Approved Libraries

| Purpose            | Library / Tool          | Version   | Notes                                                     |
|--------------------|-------------------------|-----------|-----------------------------------------------------------|
| Shell              | bash                    | 3.2+      | macOS ships bash 3.2; avoid bash-4-only features          |
| Shell (Windows)    | PowerShell              | 5.1+      | Feature parity with bash setup                            |
| Issue tracker      | Linear (Anthropic MCP)  | n/a       | Only external integration                                 |
| CI (planned)       | GitHub Actions          | n/a       | For frontmatter/fragment validation only                  |

No npm / pip / cargo / go modules. No compiled code. If a future change
requires one, it is a major architectural shift and must be scoped explicitly.

## Documentation Patterns

- **Every skill has a SKILL.md.** It is the skill — there is nothing else.
- **Every Plan lives in two places:** the Linear parent issue (as a comment
  or description) and `.spade/plans/` (as a checked-in Markdown artefact).
- **Architecture docs (this file, ARCHITECTURE.md, ANTI-PATTERNS.md) apply to
  this repo itself.** Consumer repos get their own copies via `/spade-onboard`
  and fill them in with their own content.
- **Worked examples** (`examples/example-scope.md`, `examples/example-plan.md`)
  are the canonical shape for Scopes and Plans. Keep them in sync with skill
  prose.
