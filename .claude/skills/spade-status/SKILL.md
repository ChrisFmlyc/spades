---
name: spade-status
description: Show the current SPADE phase and progress for active work. Use when someone asks "where are we", "what is the status", "show me progress", "what phase are we in", or any question about the current state of work in progress. Also use at the start of a session to orient on active work.
---

# SPADE Status

You are providing a status overview of active SPADE work. This helps humans
understand where things stand at a glance.

## What To Show

### If Linear MCP is available

1. Query for active parent issues (status not "Done")
2. For each active issue, show:
   - Issue ID and title
   - Current SPADE phase (based on status)
   - Number of sub-issues: total, completed, in progress, pending
   - Delivery mode breakdown: how many AI-delivered vs human-delivered
   - Any blocked or flagged items
3. Present as a clean summary table

### If Linear MCP is not available

Ask the human to tell you about their active work, then help them
assess which SPADE phase each item is in.

## Output Format

```
## SPADE Status

| Issue | Phase | Progress | Blocked |
|-------|-------|----------|---------|
| M-68: Build telemetry worker | Delivering | 3/5 tasks done | None |
| M-72: Knox Guard analysis | Approval | Plan ready, awaiting review | None |
| M-75: Slack alerting | Scoped | Not yet planned | None |

### Detail: M-68 — Build telemetry worker

Phase: **Delivering** (3 of 5 sub-issues complete)

| Sub-issue | Mode | Status |
|-----------|------|--------|
| M-68-1: Temporal worker scaffold | ai-delivered | Done |
| M-68-2: Databricks connection | ai-delivered | Done |
| M-68-3: Normalisation logic | ai-delivered | Done |
| M-68-4: Elasticsearch indexing | ai-delivered | In Progress |
| M-68-5: Slack failure alerting | human-delivery | Todo |

Next action: Complete M-68-4, then M-68-5 needs human attention.
```

## Phase Identification

Map issue statuses to SPADE phases:

| Status | Phase | What is happening |
|--------|-------|-------------------|
| Scoped | S | Scope written, not yet planned |
| Planning | P | AI generating plan and sub-issues |
| Approval | A | Plan ready, awaiting human review |
| Delivering | D | Sub-issues being worked |
| Evaluating | E | Delivery complete, human verifying |
| Done | ✓ | Shipped and verified |

If an issue has no status or an unrecognised status, flag it and ask
the human to clarify.

## Recommendations

After showing status, suggest next actions:

- Issues in "Scoped" → suggest running `/spade-plan`
- Issues in "Approval" → remind the human to review the plan
- Issues in "Delivering" with all sub-issues done → suggest `/spade-evaluate`
- Issues stuck in any phase for too long → flag for attention
