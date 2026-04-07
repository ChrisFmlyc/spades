
## SPADE Framework

This project uses the SPADE Framework for human-AI collaboration.
Read the SPADE section in AGENTS.md for mandatory behaviour rules.

### SPADE Skills

| Skill | What it does |
|-------|-------------|
| `/spade-scope` | Help write a well-formed Scope with acceptance criteria |
| `/spade-plan` | Generate a structured Plan from a Scope |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-evaluate` | Check delivered output against acceptance criteria |
| `/spade-status` | Show current SPADE phase and progress for active work |
| `/spade-onboard` | Analyse codebase and fill in architecture docs |

### Architecture Context

Read these files before generating any Plan:
- `ARCHITECTURE.md` — system architecture, constraints, and tech stack
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things not to do

### SPADE Labels

Use these labels in Linear: `ai-planned`, `ai-delivered`, `human-delivery`,
`plan-rejected`, `needs-arch-review`

### Key Rules

- Never write code without a Scope
- Never deliver without an approved Plan
- Never mark parent issues as Done (humans only)
- Always document Plans on the parent issue
- Always read architecture docs before planning
