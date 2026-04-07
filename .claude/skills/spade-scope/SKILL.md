---
name: spade-scope
description: Help write a well-formed SPADE Scope with acceptance criteria, constraints, and architectural context. Use when starting new work, when a human says "I need to scope X", "create a scope for X", "write a scope", or when work needs to begin on a new feature, fix, or investigation. Also use when someone describes work they want done but has not yet formalised it into a Scope.
---

# SPADE Scope

You are helping a human write a well-formed Scope for the SPADE framework.
A Scope is the contract that everything downstream is measured against.

## What You Do

1. Understand what the human wants to achieve and why
2. Help them articulate it as a clear, actionable Scope
3. Ensure the Scope has all required components
4. If Linear MCP is available, create or update the parent issue

## Required Components

Every Scope must include:

### Statement of Intent
What needs to be achieved and why it matters. This is not a task description.
It is a statement of intent. One to three sentences maximum.

### Acceptance Criteria
Specific, verifiable conditions that define "done". Write these as testable
statements. A person (or AI) reading them should be able to unambiguously
determine whether each criterion has been met.

Good: "Telemetry data appears in the Elasticsearch index within 5 minutes of
device transmission."

Bad: "Telemetry works."

### Architectural Constraints
What tech stack, patterns, security requirements, or conventions apply.
Reference ARCHITECTURE.md and PATTERNS.md where relevant. If the Scope
touches areas covered by ANTI-PATTERNS.md, note the boundaries.

### Upstream and Downstream Context
What does this connect to? What depends on it? What does it depend on?
This helps the AI generate a Plan that accounts for integration points.

## Quality Checks

Before finalising, verify:

- [ ] Could someone start planning this without a follow-up conversation?
- [ ] Are the acceptance criteria specific and testable?
- [ ] Is this small enough to plan in a single session? (If it spans multiple
      systems, multiple teams, or multiple months, it needs breaking down.)
- [ ] Are the architectural constraints explicit?
- [ ] Is the origin clear? (OKR/milestone, reactive ticket, or ad-hoc)

## Scope Sizing

A Scope should be concrete enough that an AI agent can generate a plan from it
in a single session. If the Scope feels too large, help the human break it down:

- Does it span multiple systems? Split by system boundary.
- Does it span multiple teams? Split by team responsibility.
- Does it span multiple months? Split by milestone or deliverable.
- Can you identify 3-7 discrete tasks? That is roughly the right size.

## Output Format

Present the Scope in this format:

```
## Scope: [Title]

**Intent:** [What and why, 1-3 sentences]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

**Constraints:**
- [Tech stack / pattern / security constraints]

**Context:**
- Upstream: [What feeds into this]
- Downstream: [What depends on this]

**Origin:** [OKR/Milestone name | Reactive ticket reference | Ad-hoc]
```

## Linear Integration

If Linear MCP is available:
1. Create a parent issue with the Scope content
2. Set status to "Scoped"
3. Assign to the appropriate team member
4. Link to the relevant Milestone if applicable

If Linear is not available, present the Scope for the human to create manually.

## Reactive Work

For small reactive items (bug fixes, config changes), the loop compresses:
- The ticket itself can serve as the Scope
- Acceptance criteria may be as simple as "the bug is fixed and verified"
- Still document intent and constraints, even briefly

Do not over-engineer the Scope ceremony for small items. But do not skip it
entirely either. Every piece of work needs a clear "what" and "how we know
it is done."
