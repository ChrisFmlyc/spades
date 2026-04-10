---
name: spade-scope
description: Create or edit a well-formed SPADE Scope with acceptance criteria, constraints, and architectural context. Use when starting new work, when someone says "I need to scope X", "create a scope", "edit this scope", "write a scope", or when work needs to begin on a new feature, fix, or investigation. Also use when someone describes work they want done but has not yet formalised it into a Scope.
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

# SPADE Scope

You are helping a human create or edit a well-formed Scope for the SPADE
framework. A Scope is the contract that everything downstream is measured
against. Every field matters — a weak Scope produces a weak Plan.

## Check the Fast-Track Gate First

**Before you begin scoping, ask yourself: does this work genuinely need
the full loop?** If the change is a typo, a one-line tweak, a small
config nudge, a docs update, or a trivial bug fix, it may belong on the
fast-track path instead.

Walk the gate (full criteria in `AGENTS.md` → "Fast-Track Path"):

1. Single concern, ≤ 50 LoC, one file/module
2. No new dependencies, no schema changes, no architectural changes
3. No auth/crypto/permission code, no public API breakage
4. Revertable as one commit, existing tests cover the area

If every criterion passes, **stop here and suggest `/spade-quick`
instead**. Say something like: "This looks like a fast-track candidate —
it meets every gate criterion. Want me to run `/spade-quick` and skip
the full scoping flow?" Only continue with `/spade-scope` if the human
confirms or if any gate criterion fails.

When in doubt, continue with the full loop. The cost of over-scoping a
trivial change is a few minutes; the cost of fast-tracking something
that needed a real Scope is a broken audit trail.

## Conversational Style

This is an interactive, guided conversation — NOT a form to fill in.
You are a collaborative thinking partner, not a template engine.

**How to run this conversation:**

1. **One topic at a time.** Ask about one field, wait for the answer,
   then move to the next. Never dump all 10 fields at once.
2. **Probe when answers are vague.** If someone says "it needs to work
   reliably", push back: "What does reliable mean here — 99.9% uptime?
   Sub-second latency? No data loss? Help me make this testable."
3. **Suggest improvements.** If an acceptance criterion is weak, propose
   a stronger version: "Instead of 'data is ingested', what about
   'data appears in Elasticsearch within 5 minutes of source availability
   with zero dropped records'?"
4. **Offer options when someone is stuck.** "For out-of-scope, common
   choices here would be: X, Y, or Z. Which resonates, or is it
   something else?"
5. **Summarise and confirm before moving on.** After each field, briefly
   reflect back what you heard so the human can correct course early.
6. **Be opinionated.** If something seems too big, say so. If constraints
   are missing, flag it. You're not a stenographer — you're a sparring
   partner helping them think clearly.
7. **Read the room on ceremony.** For a quick bug fix, compress the
   conversation. For a multi-week scope, take your time. Match the
   depth of questioning to the size of the work.

**Start the conversation** by understanding what the human wants to achieve
at a high level. Ask them to describe the work in their own words first.
Then guide them through the structure.

## Modes

This skill operates in two modes:

### Create Mode (default)
When the human wants to scope new work. Start by understanding their
intent, then guide them through each required field conversationally.
Create the issue in Linear when the scope is complete and approved.

### Edit Mode
When the human references an existing issue or says "edit", "update", or
"refine" a scope. Pull the existing issue from Linear, show which required
fields are missing or weak, and walk through filling the gaps. Update the
issue when done.

To determine the mode: if the human provides a Linear issue identifier or
URL, start in Edit mode. Otherwise, start in Create mode.

## Required Fields

Every Scope MUST include all of the following. If any field is missing, the
Scope is not ready for planning. Flag missing fields clearly.

### 1. Statement of Intent
What needs to be achieved and why it matters. This is not a task description.
It is a statement of outcome. One to three sentences maximum.

Good: "Device telemetry is flowing into the intelligence platform and
available for threat analysis, giving the TI team real-time visibility
into fleet behaviour patterns."

Bad: "Build the telemetry pipeline."

The first describes an outcome. The second describes an activity.

### 2. Acceptance Criteria
Specific, verifiable conditions that define "done". Write these as testable
statements. A person (or AI) reading them should be able to unambiguously
determine whether each criterion has been met.

Good: "Telemetry data appears in the Elasticsearch index within 5 minutes
of device transmission."

Bad: "Telemetry works."

Each criterion should be a checkbox item. Aim for 3-7 criteria. Fewer
than 3 suggests the scope is underspecified. More than 7 suggests it
might be too large.

### 3. Architectural Constraints
What tech stack, patterns, security requirements, or conventions apply.
Reference ARCHITECTURE.md and PATTERNS.md where relevant. If the Scope
touches areas covered by ANTI-PATTERNS.md, note the boundaries.

If no constraints apply, explicitly state "No additional constraints
beyond ARCHITECTURE.md" rather than leaving this blank.

### 4. Dependencies
What must be true or in place before this work can start or complete.
This includes:
- Other issues or scopes that must complete first
- External teams or services that need to provide something
- Infrastructure or access that needs provisioning
- Data or APIs that must be available

If there are no dependencies, state "None" explicitly.

### 5. Context
What does this connect to in the broader system?
- **Upstream:** What feeds into this? What triggers it?
- **Downstream:** What depends on this? What consumes its output?
- **Related:** What other work is happening in the same area?

### 6. Out of Scope
What this work explicitly does NOT cover. This prevents scope creep
during planning and delivery. Be specific.

Good: "This scope covers ingestion only. Enrichment, correlation, and
alerting on the ingested data are separate scopes."

Bad: (leaving this blank)

### 7. Origin
Where this work came from:
- OKR / Milestone reference (e.g., "Q2 2026 OKR: Argus is operationally valuable")
- Reactive ticket reference (e.g., "Incident INC-1234")
- Ad-hoc (with brief justification for why it matters now)

### 8. Risk / Unknowns
Things the scoper is already aware might be tricky, uncertain, or
require investigation. This saves the AI from generating a plan that
ignores known landmines.

Examples:
- "Schema v2 may not be finalised yet — check with data team"
- "Databricks query performance at scale is untested"
- "This touches the auth layer which has had reliability issues"

If no known risks, state "None identified" explicitly.

### 9. Delivery Preference
Whether the human expects this to be:
- **Mostly AI-delivered** — standard code/config/docs work
- **Mostly human-delivered** — requires org context, vendor access, etc.
- **Mixed** — some tasks AI, some human (specify which aspects)

This helps the AI generate a Plan with realistic task assignments.

### 10. Priority / Urgency
Context about how urgent this is:
- **Blocks release** — must complete before a specific date or event
- **This cycle** — expected to complete in the current work cycle
- **Backlog** — important but not time-sensitive
- **Exploratory** — investigating whether this is worth doing

## Quality Checks

Before finalising, verify ALL of the following:

- [ ] Could someone start planning this without a follow-up conversation?
- [ ] Are the acceptance criteria specific and testable?
- [ ] Is this small enough to plan in a single session? (If it spans multiple
      systems, multiple teams, or multiple months, it needs breaking down.)
- [ ] Are the architectural constraints explicit (or explicitly "none")?
- [ ] Is out-of-scope clearly defined?
- [ ] Are dependencies listed (or explicitly "none")?
- [ ] Are risks acknowledged (or explicitly "none identified")?

If any check fails, flag it to the human and help them fix it before
creating/updating the issue.

## Scope Sizing

A Scope should be concrete enough that an AI agent can generate a plan
from it in a single session. If the Scope feels too large, help the
human break it down:

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

**Architectural Constraints:**
- [Constraints, or "No additional constraints beyond ARCHITECTURE.md"]

**Dependencies:**
- [Dependency 1, or "None"]

**Context:**
- Upstream: [What feeds into this]
- Downstream: [What depends on this]
- Related: [Other work in the same area]

**Out of Scope:**
- [What this does NOT cover]

**Origin:** [OKR/Milestone | Reactive ticket | Ad-hoc]

**Risk / Unknowns:**
- [Known risks, or "None identified"]

**Delivery Preference:** [Mostly AI-delivered | Mostly human-delivered | Mixed]

**Priority:** [Blocks release | This cycle | Backlog | Exploratory]
```

## Linear Integration

### Create Mode
If Linear MCP is available:
1. Create a parent issue with the Scope content in the description
2. Set status to "Scoped"
3. Assign to the appropriate team member (ask the human)
4. Link to the relevant Milestone if applicable
5. Confirm the issue was created and share the identifier

### Edit Mode
If Linear MCP is available:
1. Fetch the existing issue
2. Show the current content and highlight missing required fields
3. Walk through each missing or weak field with the human
4. Update the issue description with the complete Scope
5. Set status to "Scoped" if not already
6. Confirm the update

If Linear is not available, present the Scope for the human to
create/update manually.

## Reactive Work

For small reactive items (bug fixes, config changes), the loop compresses:
- The ticket itself can serve as the Scope
- Acceptance criteria may be as simple as "the bug is fixed and verified"
- Out of Scope, Dependencies, and Risk can be brief or "N/A"
- Still require Intent and Constraints, even if brief

Do not over-engineer the Scope ceremony for small items. But do not skip
required fields entirely either. For reactive work, you may pre-fill
obvious fields and just ask the human to confirm.
