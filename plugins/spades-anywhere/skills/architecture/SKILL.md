---
name: architecture
description: Create or maintain ARCHITECTURE.md, the project's durable statement of HOW the work is structured — stages, stakeholders, cadence, tools, constraints. Use when someone says "set up ARCHITECTURE.md", "document our process", "what stages does this work move through", "update the architecture doc", or when ARCHITECTURE.md is missing, still an unfilled template, or flagged stale. The human composes the architecture; this skill structures and probes but never authors it.
version: 1.0.0
---

# SPADES-anywhere Architecture

### Output format

This skill honours `review_format:` from
`.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`.
**`ARCHITECTURE.md` itself stays at the repo root as
human-authored Markdown.** In HTML mode, after writing/refreshing
`ARCHITECTURE.md` the skill renders a persistent summary at
`.spades-anywhere/architecture.html` via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/architecture/template.html`, and
a transient preview at `.spades-anywhere/.tmp/architecture.html`
during the edit flow. In CLI mode, no preview is rendered. The
Socratic facilitate-never-author flow is identical between modes.

You are helping a human create or maintain `ARCHITECTURE.md` —
the durable statement of HOW this project's work is structured.
In `spades-anywhere`, "architecture" is not tech-stack: it's the
**operating model** of the work. For a recurring hiring round,
ARCHITECTURE describes the stages, who's involved, how often it
happens, what tools support it. For a party, it's venue + suppliers
+ guest list + timing. For a trip, it's the itinerary + bookings
+ logistics.

`ARCHITECTURE.md` is a root reference document, peer to
`INTENT.md`, `PATTERNS.md`, and `ANTI-PATTERNS.md`. It changes
infrequently. `/spades-anywhere:plan` and
`/spades-anywhere:review` cross-check Plans against it.

## The Core Rule: Facilitate, Never Author

**The human owns the architecture. You structure it. You never
invent it.**

Same non-negotiable rule as `/spades-anywhere:intent`. The
human's team has made real decisions about how this work
operates — your job is to capture them, not invent new ones.

Concretely:

- **You MAY** ask questions, reflect answers back, propose
  *structure*, suggest *wording* for something the human has
  already expressed, and — in Create mode — offer an
  explicitly-labelled *draft starting point* inferred from
  whatever the human shares (existing process docs, a kickoff
  brief, attached files) for the human to accept, reject, or
  rewrite.
- **You MUST NOT** invent stages, stakeholders, cadences, or
  constraints the human did not state; save `ARCHITECTURE.md`
  before the human has reviewed every section.
- **Silence is not consent.**

## What ARCHITECTURE.md Is — and Is Not

`ARCHITECTURE.md` owns **how** the work operates. It does NOT
own:

- **Why** the project exists / for whom → `INTENT.md`.
- **Approved process conventions** → `PATTERNS.md`.
- **Things we deliberately avoid** → `ANTI-PATTERNS.md`.
- **Specific Scope acceptance criteria** — those live on the
  Scope itself.

## Inline ARCHITECTURE.md Template

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Architecture

## Overview

<!-- Two or three paragraphs describing what this work is at a
     high level. What does it produce, who's it for, how often
     does it happen? -->

## Stages

<!-- The phases the work moves through. For a hiring round:
     sourcing -> screening -> interviews -> offer. For a party:
     concept -> venue -> guest list -> day-of. Capture the
     sequence and what gets handed off between stages. -->

## Stakeholders

<!-- Who's involved at each stage. Roles + responsibilities.
     Be specific: name the human owners, name the consulted
     parties. -->

## Cadence

<!-- Timing. One-off vs recurring? If recurring, how often?
     Per-stage timelines, deadlines, deadlines-before-deadlines. -->

## Tools & Resources

<!-- The tools the work uses — calendars, docs, trackers,
     spreadsheets, vendors. What's the canonical place for each
     kind of artefact? -->

## Constraints

<!-- Hard constraints: budget, deadline, headcount, vendor
     availability, regulatory. What boxes does the work have
     to fit inside? -->
```

## Where ARCHITECTURE.md Lives

`ARCHITECTURE.md` lives at the **repository root** (or knowledge
store root for chat-surface contexts), alongside `INTENT.md`,
`PATTERNS.md`, `ANTI-PATTERNS.md`.

## Modes

- **No file** → **Create mode**.
- **Filled template with placeholder markers** → **Create mode**.
- **Filled and complete** → **Edit mode**.

If ambiguous, confirm via `AskUserQuestion`.

### Create Mode

Walk the human through all six sections. Before starting, offer:

- *Draft a starting point from what's already shared, then I
  correct it*
- *Start blank — I'll describe it myself*

### Edit Mode

Use `AskUserQuestion` to scope:

- *Refresh `last_reviewed` only*
- *Revise specific sections*
- *Full review pass*

**Always read the existing file first** — preserve what's there.

## Conversational Style

1. **One section at a time.**
2. **Probe vague answers.** "We have stages" — name them.
3. **Suggest sharper wording, not new substance.**
4. **Reflect and confirm before moving on.**
5. **Match ceremony to the work.**

## The Six Sections

`ARCHITECTURE.md` has exactly six sections. Locked schema.

### 1. Overview
What this work is at a high level. Two or three paragraphs.

### 2. Stages
The phases the work moves through. Capture the sequence and
what gets handed off between stages.

### 3. Stakeholders
Who's involved at each stage. Roles + responsibilities, named.

### 4. Cadence
Timing. One-off vs recurring? Per-stage timelines, deadlines.

### 5. Tools & Resources
The tools and resources the work uses. Where each artefact
lives.

### 6. Constraints
Hard constraints: budget, deadline, headcount, regulatory.

## The `last_reviewed` Field

Set to today's date on every Create or meaningful Edit.

## Decision Prompts (AskUserQuestion)

- **Mode confirmation** when ambiguous.
- **Create-mode start** — *Draft inferred* / *Start blank*.
- **Edit-mode scope** — *Refresh `last_reviewed` only* / *Revise
  specific sections* / *Full review pass*.

## Writing the File

Write `./ARCHITECTURE.md` only after the human has reviewed
every section in play.

**In HTML mode, also write a persistent
`.spades-anywhere/architecture.html` alongside `ARCHITECTURE.md`.**
Same template as the transient preview. In CLI mode,
`.spades-anywhere/architecture.html` is NOT written.

There is **no SCM in spades-anywhere** — no branch, no PR, no
wait-for-merge gate. The human saves both files to their
chat-surface knowledge store on their own cadence.

### Transient HTML preview (HTML mode only)

When `review_format: html`, also render to
`.spades-anywhere/.tmp/architecture.html` during the edit flow.

**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.**

1. Read the template at
   `${CLAUDE_PLUGIN_ROOT}/skills/architecture/template.html`.
2. Validate the placeholders listed below are present; abort if
   any are missing.
3. Substitute:
   - `{{spades.project_slug}}`, `{{spades.last_reviewed}}`,
     `{{spades.rendered_at}}`, `{{spades.plugin_version}}`.
   - The prose sections via direct substitutions:
     `{{spades.overview_html}}`, `{{spades.stages_html}}`,
     `{{spades.stakeholders_html}}`, `{{spades.cadence_html}}`,
     `{{spades.tools_html}}`, `{{spades.constraints_html}}`.
4. Write to `.spades-anywhere/.tmp/architecture.html`.
5. Auto-open via the OPEN_CMD prelude.

`ARCHITECTURE.md` itself stays Markdown in both modes — only the
preview is HTML.
