
## SPADE Framework

This project uses the SPADE Framework for human-AI collaboration.
Read the SPADE section in AGENTS.md for mandatory behaviour rules.

### SPADE Skills

| Skill | What it does |
|-------|-------------|
| `/spade-scope` | Help write a well-formed Scope with acceptance criteria |
| `/spade-plan` | Generate a structured Plan from a Scope; each task declares an execution posture; surfaces prior learnings |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-review` | Multi-persona panel second opinion (5 subagents, merged findings) on a Scope, Plan, or both |
| `/spade-learn` | Capture a learning under `.spade/learnings/` so future Plans reference it; `--refresh` for housekeeping |
| `/spade-quick` | Fast-track path for trivial work (typos, tweaks, small fixes) |
| `/spade-research` | Landscape research via an isolated Opus 4.7 subagent (read-only); optional Linear artefact with explicit consent (v1.3.0+) |
| `/spade-evaluate` | Check delivered output against acceptance criteria |
| `/spade-status` | Show current SPADE phase and progress for active work |
| `/spade-onboard` | Analyse codebase and fill in architecture docs |

### Architecture Context

Read these files before generating any Plan:
- `ARCHITECTURE.md` — system architecture, constraints, and tech stack
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things not to do

### SPADE Labels

Full-loop labels: `ai-planned`, `ai-delivered`, `human-delivery`,
`plan-rejected`, `needs-arch-review`, `bundle:<name>`

Fast-track labels: `spade:quick`, `type:bug`, `type:tweak`, `type:chore`,
`type:docs`, `type:refactor`

### Fast-Track Path

For trivial work — typos, one-line tweaks, small config changes, docs
updates — use `/spade-quick` instead of the full loop. The PR description
is the audit artefact. No sub-issues, no separate Plan, no approval gate
beyond PR review. Gate criteria and rules live in AGENTS.md under
"Fast-Track Path (Small Work)". When in doubt, use the full loop.

### Key Rules

- Never write code without a Scope (or a valid fast-track gate pass)
- Never deliver without an approved Plan (on the full loop)
- Never mark parent issues as Done (humans only)
- Always document Plans on the parent issue
- Always read architecture docs before planning
- Never create sub-issues on the fast-track path
- Never misuse `/spade-quick` for work that fails any gate criterion
