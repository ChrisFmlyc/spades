---
name: spade-review
description: Get an independent second opinion on a SPADE Scope, Plan, or both. Spawns a PANEL of five persona subagents in parallel (scope-guardian, architecture-strategist, security-lens, yagni-simplicity, adversarial-reviewer), merges their structured findings, and presents a single deduplicated report. Use when someone says "second opinion", "outside view", "review this", "challenge this", or when offered during /spade-approve. Non-blocking — informs the human but never gates shipping.
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

# SPADE Review — Persona Panel Second Opinion

You are coordinating an independent multi-persona review of SPADE work.
The value of a panel review comes from **genuine independence across
distinct concerns** — each persona sees the same structured summary but
is primed to care about a different aspect. A generalist reviewer
collapses a review into the most obvious concern; a persona panel
surfaces five distinct perspectives and merges the findings.

This is a **second opinion**. It never gates approval or delivery — the
report is advisory. The human decides what to act on.

## When This Skill Is Used

Three modes depending on what context exists:

### 1. Scope Review (before planning)

Only a Scope exists; no Plan yet. The panel challenges premises,
acceptance criteria completeness, and whether the work is well-defined
enough for planning.

### 2. Plan Review (after planning)

A Plan exists and the human wants an independent technical review
before approval. The panel looks for gaps, overcomplexity, feasibility
risks, security concerns, and strategic miscalibration.

### 3. Full Review (Scope + Plan together)

Both artefacts available — the default when invoked during
`/spade-approve`. The panel reviews them as a pair.

## Determining the Mode

1. If the human explicitly names the mode, use it.
2. If invoked during `/spade-approve`, default to **Full Review**.
3. If a Plan exists in context (conversation or `.spade/plans/`), use
   **Full Review**.
4. If only a Scope exists (Linear issue or conversation), use
   **Scope Review**.
5. If only a Plan exists with no clear Scope, use **Plan Review**.

## Gathering Context

Before spawning the panel, assemble a structured summary. Every persona
subagent gets the same summary — no conversation history.

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

- **Plan content** — the full plan (tasks, approach, risks, bundles,
  execution posture per task)
- **Project context**
- **Architecture constraints** — from ARCHITECTURE.md, PATTERNS.md,
  ANTI-PATTERNS.md (personas read these themselves if needed).

### For Full Review, gather all of the above.

If any of this context comes from Linear, fetch it via MCP. If it is in
the conversation, extract it. If a plan file exists in `.spade/plans/`,
read it.

**Truncation rule:** If the combined context exceeds 30KB, truncate the
Plan content (keeping task titles and approach summaries) rather than
dropping Scope fields. Personas need the full Scope to review
traceability.

## The Panel

Five persona subagents, each defined under `.claude/agents/`:

| Persona file                                    | Focus                                                                   |
|-------------------------------------------------|-------------------------------------------------------------------------|
| `spade-review-scope-guardian`                   | Scope completeness, testability, Plan→Scope traceability                |
| `spade-review-architecture-strategist`          | Conflicts with ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md         |
| `spade-review-security-lens`                    | Auth, injection, secrets, supply chain, IAM, data sensitivity           |
| `spade-review-yagni-simplicity`                 | Over-engineering, premature abstraction, bundle/task proportionality    |
| `spade-review-adversarial-reviewer`             | Strongest attack on the Plan — what will fail and why                   |

Read `.claude/agents/spade-review-*.md` in the framework install
(`~/.spade/.claude/agents/` if installed globally, or `.claude/agents/`
in the consumer repo if the consumer has vendored them). Each file
defines the persona's focus, the severity rubric, and the output
contract.

## Spawning the Panel

**Spawn all five personas in parallel where the runtime supports it;
otherwise sequentially.** Parallel is a performance nicety, not a
correctness requirement — the merge logic doesn't care.

In Claude Code, use the `Task` tool (or the persona-specific
`subagent_type`) to spawn each persona. Each call gets the same
self-contained prompt:

```
You are reviewing a SPADE {mode} as the {persona} on a multi-persona
panel. Think hard and reason carefully before responding. Follow the
output contract in your persona file exactly — prose summary first,
then a JSON code block labelled `spade-findings` with strictly
schema-matching finding objects.

PROJECT CONTEXT:
{project_context}

SCOPE:
{scope_content}                 # omit for Plan-only reviews

PLAN:
{plan_content}                  # omit for Scope-only reviews

ARCHITECTURE CONSTRAINTS:
{architecture_constraints}      # ARCHITECTURE / PATTERNS / ANTI-PATTERNS
```

The `Think hard and reason carefully before responding` line is
intentional — each persona should use maximum reasoning effort since
the panel is meant to be the strongest independent view available.

If the runtime does not support parallel Task spawns, run the five
sequentially in this order: scope-guardian, architecture-strategist,
security-lens, yagni-simplicity, adversarial-reviewer. Never skip a
persona to save time — a three-persona review collapses back toward
generalist.

## Collecting the Findings

Each persona returns a short prose summary followed by a JSON code
block labelled `spade-findings`. Parse each block and collect all
findings into a single list.

If a persona's JSON block is invalid (rare; LLMs occasionally emit
trailing commas), present its prose summary verbatim and note the
parse failure alongside the report. Do not attempt to auto-repair
malformed JSON — showing the human "persona X returned malformed JSON"
is more useful than risking silent data corruption.

## Merging: Dedupe and Sort

Across all findings:

1. **Dedupe** by `(category, first 100 characters of message)`
   normalised to lower-case. When two or more findings collapse to the
   same key, keep the one with highest confidence. Append the other
   personas' names to a `also_flagged_by` array on the kept finding so
   the human sees that multiple personas converged.
2. **Sort** by severity × confidence, descending. Severity order:
   `blocking` > `major` > `minor` > `nit`. Within a severity bucket,
   higher confidence comes first.

Findings with confidence below 0.3 are filtered out before
presentation — they are below the calibration rubric each persona is
told to respect. Log the count of filtered findings so the human sees
"3 low-confidence findings hidden" rather than silent loss.

## Presenting the Report

Present the merged report in this shape:

```
PANEL SECOND OPINION
════════════════════════════════════════════════════════════

Summary from each persona (their own words, verbatim):

  scope-guardian:           <prose summary>
  architecture-strategist:  <prose summary>
  security-lens:            <prose summary>
  yagni-simplicity:         <prose summary>
  adversarial-reviewer:     <prose summary>

Merged findings (sorted by severity × confidence):

  [blocking, 0.95] architecture-strategist — <message>
    refs: ANTI-PATTERNS.md#..., Plan Task 4
  [major,    0.85] yagni-simplicity — <message>
    refs: Plan Task 3
    also_flagged_by: [adversarial-reviewer]
  ...

Hidden: N finding(s) below 0.3 confidence threshold.

════════════════════════════════════════════════════════════
```

**Never summarise a persona's prose in your own words.** The whole
point is that the human sees each independent view unfiltered. The
merge only applies to the JSON findings — the prose summaries are
always shown verbatim.

## Cross-Model Synthesis

After presenting the merged panel output, add your own synthesis as
the coordinating agent. For each finding you disagree with, state what
you think differently and why — include context the panel did not have
(conversation history, prior human decisions, and so on). Flag
genuine tensions neutrally rather than picking a side:

```
CROSS-MODEL SYNTHESIS:

Where I agree: <list of findings you second>
Where I disagree: <findings with reasoning>
Tension points (for the human to resolve):

  TENSION: <topic>
  Panel says:    X
  My view:       Y
  Context the panel didn't have: Z
```

## User Decision

After synthesis, ask the human what they want to do via the
AskUserQuestion tool:

```
The panel review is above. What would you like to do?

A) **Act on specific findings** — name which ones to address (by
   severity, persona, or message).
B) **Continue as-is** — review noted, proceed without changes.
C) **Discuss further** — work through tension points before deciding.
```

**Non-blocking.** The human can acknowledge the review and move on.
The panel never gates approval or delivery — it informs.

## Integration with /spade-approve

When invoked from `/spade-approve`:

1. `/spade-approve` presents the approval checklist with its own
   assessments.
2. Before asking for the approval decision, it offers:
   "Want a panel review from an independent perspective?"
3. If the human says yes, `/spade-approve` invokes this skill.
4. After the merged report, synthesis, and user decision,
   `/spade-approve` resumes with the approval decision.

The panel does NOT replace any part of the approval checklist. It
supplements it.

## What This Skill Must Never Do

- **Gate shipping.** The panel is informational. It does not have
  authority to reject a plan or block delivery.
- **Auto-apply findings.** The human decides what to act on. Never
  rewrite the Scope or Plan based on findings without explicit human
  instruction.
- **Leak conversation context into persona prompts.** Each persona
  sees only the structured summary. Passing "primary agent thinks X"
  into the persona prompt defeats the independence.
- **Summarise a persona's prose in your own words.** Verbatim only.
- **Run during fast-track (`/spade-quick`).** Fast-track work is too
  small to warrant a panel review. If someone asks for a review on a
  quick-path item, suggest the full loop instead.
- **Skip personas to save time.** Five personas or none. A reduced
  panel collapses back toward generalist and loses the coverage
  guarantee.
- **Repair malformed JSON from a persona.** Report the parse failure;
  do not guess.
