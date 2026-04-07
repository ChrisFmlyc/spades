---
name: spade-list
description: List active SPADE Scopes from Linear, filtered by phase. Shows issues in Scoped, Planning, Approval, Delivering, or Evaluating status. Use when someone says "show my scopes", "list scopes", "what's active", "what needs planning", or wants to see what work is in progress across the SPADE pipeline.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

# SPADE List

You are showing the human their active SPADE work from Linear. This gives
a quick overview of what Scopes exist and where they are in the pipeline.

## Requirements

This skill requires Linear MCP. If Linear MCP is not available, tell the
user and suggest they check their MCP configuration.

## Default Behaviour

When invoked without arguments, show all parent issues (Scopes) that are
in any active SPADE status:

- **Scoped** — ready for planning
- **Planning** — AI is generating a plan
- **Approval** — plan awaiting human review
- **Delivering** — work in progress
- **Evaluating** — output being verified

Do NOT show issues in "Done", "Cancelled", "Backlog", "Triage", or
other non-SPADE statuses by default.

## Filtering

The user can filter by phase:

- `/spade-list scoped` — only show Scoped issues (ready for planning)
- `/spade-list delivering` — only show Delivering issues
- `/spade-list all` — show everything including Done

If the user provides a filter argument, respect it. If not, use the
default (all active statuses).

## How to Fetch

1. Use `list_teams` to identify the user's team(s)
2. Use `list_issues` to fetch issues, filtering by status where possible
3. For each issue, also check if it has sub-issues (these are Plan tasks)

## Output Format

Present results as a clean table grouped by SPADE phase:

```
## Active Scopes

### Scoped (ready for planning)
| Issue | Title | Assignee | Priority |
|-------|-------|----------|----------|
| TEAM-123 | Build telemetry ingestion worker | @kevin | High |
| TEAM-456 | Add Slack alerting to pipeline | @kevin | Medium |

### Delivering (in progress)
| Issue | Title | Assignee | Tasks | Done |
|-------|-------|----------|-------|------|
| TEAM-100 | Auth middleware rewrite | @kevin | 5 | 3/5 |

### Approval (awaiting review)
(none)
```

For issues in Delivering status, show task progress (how many sub-issues
are done out of total).

## Scope Quality Check

For issues in "Scoped" status, do a quick check of the description against
the required Scope fields (Intent, Acceptance Criteria, Constraints,
Dependencies, Context, Out of Scope, Origin, Risk, Delivery Preference,
Priority). Flag any Scopes that are missing required fields:

```
⚠ TEAM-123 is missing: Out of Scope, Risk/Unknowns, Delivery Preference
  Run /spade-scope TEAM-123 to fill in the gaps
```

## Empty State

If there are no active Scopes, say so clearly:

```
No active SPADE Scopes found. Run /spade-scope to create one.
```

## Follow-up Suggestions

After showing the list, suggest relevant next actions based on what's there:

- If there are Scoped issues: "Run `/spade-plan TEAM-123` to generate a plan"
- If there are Approval issues: "Run `/spade-approve TEAM-456` to review"
- If all Delivering tasks are complete: "Run `/spade-evaluate TEAM-789` to verify"
- If Scoped issues have missing fields: "Run `/spade-scope TEAM-123` to complete the scope"
