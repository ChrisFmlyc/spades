---
name: architecture
description: Create or maintain ARCHITECTURE.md, the project's durable statement of HOW the work is structured — stages, stakeholders, cadence, tools, constraints. Use when someone says "set up ARCHITECTURE.md", "document our process", "what stages does this work move through", "who's involved at each stage", "what's our cadence", "what tools do we use", "what are our hard constraints", "update the architecture doc", "refresh the operating model", or when ARCHITECTURE.md is missing, still an unfilled template, or flagged stale by /spades-anywhere:plan, /spades-anywhere:approve, or /spades-anywhere:review. Also use proactively after a stakeholder change, tool migration, or cadence revision that exposes drift between the doc and reality. The human composes the architecture; this skill structures and probes but never authors it. SKIP when the human's intent is per-Scope acceptance criteria (use /spades-anywhere:scope instead) or process conventions / quality bar (use /spades-anywhere:patterns).
version: 1.2.0
---

# /spades-anywhere:architecture

You are helping a human create or maintain `ARCHITECTURE.md` — the
durable statement of how this project's work is structured. In
`spades-anywhere` the architecture is the **operating model**: for a
recurring hiring round, the stages, who is involved, how often it
runs, and what tools support it; for a party, the venue, suppliers,
guest list, and timing. A root reference document, peer to
`INTENT.md`, `PATTERNS.md`, and `ANTI-PATTERNS.md`, that
`/spades-anywhere:plan`, `/spades-anywhere:approve`, and
`/spades-anywhere:review` cross-check Plans against.

Read `docs/FRAMEWORK.md` § Asking the Human and § Output Format
before running.

### Output format

- **Both modes** — `ARCHITECTURE.md` at the root of the knowledge
  store, the canonical record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/architecture/template.html`: a
  persistent `.spades-anywhere/architecture.html` and a transient
  `.spades-anywhere/.tmp/architecture.html` opened as the review
  surface for the assembled document.
- **CLI mode** — the assembled document prints once in the brief.

A root document; no backend mirror.

## The core rule: facilitate, never author

The human's team made real decisions about how this work operates;
capture them. You may ask, reflect back, propose structure, suggest
wording, and, in Create mode, offer an explicitly labelled draft
inferred from what the human shares (process docs, a kickoff brief,
attached files). Every section lands only after the human confirms
it; stages, stakeholders, cadences, or constraints the human has
not stated are questions to ask.

## What `ARCHITECTURE.md` is

It owns **how** the work operates. Why it exists is `INTENT.md`;
approved process conventions are `PATTERNS.md`; deliberate
avoidances are `ANTI-PATTERNS.md`; per-Scope acceptance criteria
live on the Scope.

## Inline template

The scaffold `/spades-anywhere:setup` writes and Create mode fills.
Exactly this shape:

```markdown
---
last_reviewed: YYYY-MM-DD
cadence:   # one-off, or the recurrence, e.g. "quarterly"
---

# Architecture

## Overview

<!-- Two or three paragraphs describing what this work is at a
     high level. What does it produce, who's it for, how often
     does it happen? -->

## Stages

<!-- The phases the work moves through, one `### <name>` heading
     each with a one-line description. For a hiring round:
     sourcing -> screening -> interviews -> offer. For a party:
     concept -> venue -> guest list -> day-of. Capture what gets
     handed off between stages. -->

### Stage name

<!-- What happens in this stage and what it hands off. -->

## Stakeholders

<!-- Who's involved at each stage, one `- <name> — <role>` bullet
     each. Name the owners and the consulted parties. -->

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

The placeholder comments stay when the human starts blank. Stages
as `### <name>` headings and stakeholders as `<name> — <role>`
bullets let the renderer card and count them.

## Modes

Inspect `./ARCHITECTURE.md`: **Missing** → Create; **unfilled** (two
or more placeholder comments) → Create in place; **filled** → Edit.
Confirm via `AskUserQuestion` when ambiguous.

**Create.** Offer via `AskUserQuestion`: **Draft a starting point
from what's already shared, then I correct it** / **Start blank**.

**Edit.** Read the existing file first, then scope via
`AskUserQuestion`: **Refresh `last_reviewed` only** / **Revise
specific sections** / **Full review pass**. Untouched sections are
preserved.

## Conversational style

One section at a time. Probe vague answers ("we have stages" — name
them). Suggest sharper wording for the human's own point. Reflect
and confirm before moving on. Match the ceremony to the work.

## The six sections

A locked schema.

1. **Overview** — what this work is, who it is for, how often.
2. **Stages** — the phases in sequence and what each hands off.
3. **Stakeholders** — who is involved at each stage, named, with
   roles.
4. **Cadence** — one-off or recurring; per-stage timelines and
   deadlines. Confirm the `cadence` frontmatter key here; it drives
   the page's deck.
5. **Tools & Resources** — the tools in use and where each artefact
   lives.
6. **Constraints** — budget, deadline, headcount, vendor
   availability, regulatory.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit.

## Writing the file

Write `./ARCHITECTURE.md` once the human has confirmed every
section in play.

**HTML mode** — after the write, render twice from the template per
`docs/FRAMEWORK.md § Output Format → HTML rendering`, identical
inputs, different paths: `.spades-anywhere/architecture.html`
(persistent) and `.spades-anywhere/.tmp/architecture.html`
(transient, opened).

- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version, cadence }` — `cadence` from the file's own
  frontmatter, `—` when unset
- `stages_count`, `stakeholders_count` *(scalars)*
- `blocks`:
  - `stages` — one per `### <name>` heading. Fields: `name, desc`.
  - `stakeholders` — one per `<name> — <role>` bullet. Fields:
    `name, role`.
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.
- `prose_sections`: `{ overview_html, cadence_html, tools_html,
  constraints_html }`

Required markers: `stages`, `stakeholders`.

## Brief

**HTML mode:**

```
✓ ARCHITECTURE.md written (last reviewed YYYY-MM-DD)
○ .spades-anywhere/architecture.html opened in browser
Next: /spades-anywhere:patterns · /spades-anywhere:anti-patterns
```

**CLI mode:** the write confirmation, the assembled
`ARCHITECTURE.md` once, the same `Next:` line. Remind the human to
save the file to their knowledge store.
