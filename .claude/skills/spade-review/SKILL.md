---
name: spade-review
description: Get an independent second opinion on a SPADE Scope, Plan, or both. Spawns a fresh agent with no conversation history to challenge premises, find blind spots, and surface risks the primary review might miss. Use when someone says "second opinion", "outside view", "review this", "challenge this", or when offered during /spade-approve. Non-blocking — informs the human but never gates shipping.
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

# SPADE Review — Second Opinion

You are providing an independent second opinion on SPADE work. The value
of a second opinion comes from **genuine independence** — the reviewing
agent sees a structured summary, not the full conversation. This prevents
anchoring bias and lets it spot things the primary agent is blind to.

## When This Skill Is Used

This skill operates in three modes depending on what context is available:

### 1. Scope Review (before planning)

When only a Scope exists and no Plan has been generated yet. The outside
voice challenges the Scope's premises, acceptance criteria completeness,
and whether the work is well-defined enough for planning.

### 2. Plan Review (after planning)

When a Plan exists and the human wants an independent technical review
before approving. The outside voice looks for gaps, overcomplexity,
feasibility risks, and strategic miscalibration.

### 3. Full Review (Scope + Plan together)

When both Scope and Plan are available — the default when invoked during
`/spade-approve`. The outside voice reviews both artefacts as a pair,
checking whether the Plan actually solves the Scope and whether either
has blind spots.

## Determining the Mode

1. If the human explicitly says what to review, use that mode.
2. If invoked during `/spade-approve`, default to **Full Review**.
3. If a Plan exists in context (conversation or `.spade/plans/`), use
   **Full Review** (scope + plan).
4. If only a Scope exists (Linear issue or conversation), use **Scope Review**.
5. If only a Plan exists with no clear Scope, use **Plan Review**.

## Gathering Context

Before spawning the review agent, you must assemble a structured summary.
The review agent gets ONLY this summary — no conversation history.

### For Scope Review, gather:

- **Statement of Intent** — the what and why
- **Acceptance Criteria** — the full list
- **Architectural Constraints** — from the Scope and ARCHITECTURE.md
- **Dependencies** — what must be in place
- **Risks / Unknowns** — what the scoper flagged
- **Out of Scope** — the boundaries
- **Project context** — brief description of the project (from
  ARCHITECTURE.md or repo structure)

### For Plan Review, gather:

- **Plan content** — the full plan (tasks, approach, risks, bundles)
- **Project context** — brief description of the project
- **Architecture constraints** — from ARCHITECTURE.md and PATTERNS.md

### For Full Review, gather all of the above.

If any of this context comes from Linear, fetch it via MCP. If it is in
the conversation, extract it. If a plan file exists in `.spade/plans/`,
read it.

**Truncation:** If the combined context exceeds 30KB, truncate the Plan
content (keeping task titles and approach summaries) rather than dropping
Scope fields.

## Spawning the Review Agent

Use the **Agent tool** to spawn an independent subagent. The agent must
receive a self-contained prompt — it has no access to this conversation.

### Scope Review Prompt

```
You are an independent technical reviewer examining a SPADE Scope — a
structured description of work that an AI agent will plan against. You
have NOT seen any prior discussion about this work. Your job is to find
what the people closest to this work might be blind to.

PROJECT CONTEXT:
{project_context}

SCOPE:
{scope_content}

ARCHITECTURE CONSTRAINTS:
{architecture_constraints}

Review this Scope and report:

1. PREMISE CHECK — What assumptions does this Scope make that might be
   wrong? Name the riskiest one and explain what would break if it fails.

2. ACCEPTANCE CRITERIA GAPS — Are the criteria specific and testable?
   Is there a criterion that should exist but doesn't? Would an AI
   planner know unambiguously when each criterion is met?

3. SCOPE BOUNDARIES — Is the "Out of Scope" section tight enough?
   Where might scope creep sneak in during planning or delivery?

4. SIZING — Is this the right size for a single SPADE loop? Should it
   be split? Could it be combined with something else?

5. THE THING NOBODY SAID — What is the most important consideration
   about this work that the Scope does not mention at all?

Be direct. Be terse. No preamble, no compliments. Just the problems
and your reasoning.
```

### Plan Review Prompt

```
You are a brutally honest technical reviewer examining a development plan
that will be executed by an AI agent. You have NOT seen the conversation
that produced this plan. Your job is to find what the planning process
missed — not to repeat the review that already happened.

PROJECT CONTEXT:
{project_context}

PLAN:
{plan_content}

ARCHITECTURE CONSTRAINTS:
{architecture_constraints}

Review this Plan and report:

1. LOGICAL GAPS — Are there unstated assumptions that survived planning?
   Steps that depend on something not mentioned?

2. OVERCOMPLEXITY — Is there a fundamentally simpler approach the planner
   was too deep in the weeds to see? Could fewer tasks achieve the same
   outcome?

3. FEASIBILITY RISKS — What might go wrong that the plan takes for
   granted? External dependencies, performance assumptions, integration
   points?

4. SEQUENCING — Are the task dependencies right? Could the delivery
   order cause rework? Are there tasks that should be parallel but are
   sequential (or vice versa)?

5. STRATEGIC FIT — Is this the right thing to build at all, given the
   architecture constraints? Is it solving the real problem or a symptom?

Be direct. Be terse. No preamble, no compliments. Just the problems
and your reasoning.
```

### Full Review Prompt

```
You are a brutally honest technical reviewer examining both a SPADE Scope
(the "what") and its Plan (the "how"). You have NOT seen any prior
discussion. Your job is to find what the people closest to this work are
blind to.

PROJECT CONTEXT:
{project_context}

SCOPE:
{scope_content}

PLAN:
{plan_content}

ARCHITECTURE CONSTRAINTS:
{architecture_constraints}

Review both artefacts together and report:

1. SCOPE-PLAN ALIGNMENT — Does the Plan actually solve the Scope? Are
   there acceptance criteria that no task addresses? Are there tasks
   that don't trace back to any criterion (scope creep in disguise)?

2. PREMISE CHECK — What is the riskiest assumption across both
   documents? What breaks if it is wrong?

3. GAPS — What should exist in either the Scope or Plan but doesn't?
   Missing error handling? Untested edge cases? Deployment concerns?

4. OVERCOMPLEXITY — Is there a fundamentally simpler approach? Could
   fewer tasks achieve the same outcome?

5. THE THING NOBODY SAID — What is the most important consideration
   about this work that neither document mentions?

Be direct. Be terse. No preamble, no compliments. Just the problems
and your reasoning.
```

### Agent Tool Call

When spawning the agent:

- **description**: "SPADE second opinion — {mode} review"
- **prompt**: The assembled prompt above with all `{placeholders}` filled.
  Prepend a "Think hard and reason carefully before responding." instruction
  so the reviewer uses maximal reasoning effort.
- **model**: Always use `"opus"` for the review agent. This maps to the
  latest Opus (Opus 4.7) and is required — do not substitute Sonnet or
  Haiku, even for short reviews. The whole point of a second opinion is
  the strongest available reasoning from an independent context.

Example:

```
Agent({
  description: "SPADE second opinion — full review",
  model: "opus",
  prompt: "Think hard and reason carefully before responding.\n\n<the assembled full review prompt with all context filled in>"
})
```

## Presenting the Results

Present the outside voice's findings verbatim, clearly labelled:

```
SECOND OPINION (independent review):
════════════════════════════════════════════════════════════
<full output from the review agent — do not truncate or summarise>
════════════════════════════════════════════════════════════
```

**Never truncate or summarise the outside voice.** The whole point is that
the human sees the unfiltered perspective.

## Cross-Model Synthesis

After presenting the findings, add your own synthesis. Compare the outside
voice's assessment against your understanding from the conversation:

```
CROSS-MODEL SYNTHESIS:
```

For each point the outside voice raised:

- **Where you agree**: State it briefly. Agreement from independent
  perspectives strengthens the signal.
- **Where you disagree**: State what you think differently and why.
  Include what context you have that the outside voice did not.
- **Tension points**: Where neither view is clearly right, present both
  perspectives neutrally and flag it for the human:
  ```
  TENSION: [Topic]
  Outside voice says: X
  Primary view: Y
  Context the outside voice didn't have: Z
  ```

## User Decision

After synthesis, ask the human what they want to do. Use the AskUserQuestion
tool:

```
The second opinion is above. What would you like to do?

A) **Act on specific points** — tell me which findings to address
B) **Continue as-is** — the review is noted, proceed without changes
C) **Discuss further** — talk through specific tension points before deciding
```

**This is non-blocking.** The human can acknowledge the review and move on.
The second opinion never gates approval or delivery — it only informs.

## Integration with /spade-approve

When invoked from `/spade-approve`, the flow is:

1. `/spade-approve` presents the approval checklist with assessments
2. Before asking for the human's approval decision, it offers:
   "Want a second opinion from an independent perspective before deciding?"
3. If the human says yes, `/spade-approve` invokes this skill
4. After the review and synthesis, `/spade-approve` resumes with the
   approval decision

The second opinion does NOT replace any part of the approval checklist.
It supplements it.

## What This Skill Must Never Do

- **Gate shipping.** The second opinion is informational. It does not
  have authority to reject a plan or block delivery.
- **Auto-apply findings.** The human decides what to act on.
- **Leak conversation context.** The review agent gets ONLY the structured
  summary. Do not pass conversation history, prior disagreements, or the
  primary agent's opinions into the review prompt.
- **Summarise the outside voice.** Present findings verbatim.
- **Run during fast-track (/spade-quick).** Fast-track work is too small
  to warrant a second opinion. If someone asks for a review on quick-path
  work, suggest the full loop instead.
