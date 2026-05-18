---
name: spade-list
description: List active SPADE Scopes from Linear, filtered by phase. Shows issues in Scoped, Planning, Approval, Delivering, or Evaluating status. Use when someone says "show my scopes", "list scopes", "what's active", "what needs planning", or wants to see what work is in progress across the SPADE pipeline.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory. This file specifies
which Linear team, project, and default assignee to use. Use these values
for all Linear operations. If the file doesn't exist, ask the human which
team and project to use, or suggest running `/spade-onboard` first.

## Mode Resolution

Before any tracker call or local-file access, resolve the operating mode
**once** per `docs/FRAMEWORK.md` § Mode Resolver:

- Read `mode:` from `.spade/config`. An explicit value (`linear`,
  `local`, or `hybrid`) wins immediately.
- If `mode:` is absent, auto-detect: probe with a `list_teams` MCP call
  (try/skip, 5-second timeout). Resolve `linear` if it returns a team
  set containing `linear.team_id`; otherwise resolve `local`.
- Failure policy: an explicit `mode` with a configured `team_id` and a
  failing probe is a **fail-loud abort**; an absent `mode` with a
  failing probe **degrades quietly to `local`**.

Do not embed the resolver algorithm — it is single-sourced in
FRAMEWORK.md. The resolved mode governs the data source below.

# SPADE List

You are showing the human their active SPADE work from Linear. This gives
a quick overview of what Scopes exist and where they are in the pipeline.

## Data Source

The resolved mode (see § Mode Resolution) decides where Scopes come
from:

- **`linear` / `hybrid` mode** — fetch Scopes from the Linear tracker
  using the `## How to Fetch` steps below. In `hybrid` mode the tracker
  is canonical; the local mirror is not consulted unless the tracker is
  unreachable.
- **`local` mode** — read Scopes from local files under `.spade/`. Make
  **zero** Linear MCP calls. See `## Local Mode Fetch` below.

Both paths produce the **same** output table (see `## Output Format`);
only the source differs.

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

Applies in `linear` / `hybrid` mode only.

1. Use `list_teams` to identify the user's team(s)
2. Use `list_issues` to fetch issues, filtering by status where possible
3. For each issue, also check if it has sub-issues (these are Plan tasks)

## Local Mode Fetch

Applies in `local` mode only. Make **zero** Linear MCP calls.

1. Glob `.spade/scopes/*.md` for Scope files (per FRAMEWORK.md § Local
   Layout). If the directory is empty or absent, treat it as the empty
   state below.
2. For each file, parse the YAML frontmatter and read `status:` (the
   SPADE phase) and `title:`. Tolerate legacy files with missing or
   unknown fields — never rewrite them.
3. Group Scopes by `status:` into the same phase sections the output
   table uses (Scoped, Planning, Approval, Delivering, Evaluating).
4. Plan and sub-issue progress columns need a tracker, so render them
   as `—` (or omit the Tasks/Done columns entirely) in `local` mode —
   local Scopes have no sub-issue counts.

The Scope-quality check (see `## Scope Quality Check`) still runs in
`local` mode: it reads the file body, not the tracker.

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
