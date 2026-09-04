---
name: patterns
description: Create or maintain PATTERNS.md, the project's durable list of APPROVED conventions for how this work is run — process conventions, communication, decision making, quality bar. Use when someone says "set up PATTERNS.md", "document our process conventions", "how do we run this kind of work", "update the patterns doc", or when PATTERNS.md is missing, still an unfilled template, or flagged stale. The human composes the patterns; this skill structures and probes but never authors it.
version: 1.2.0
---

# /spades-anywhere:patterns

You are helping a human create or maintain `PATTERNS.md` — the
durable list of approved conventions for how this work is run: how
stages move, how the team communicates, how decisions are made,
what good looks like. A root reference document, peer to
`INTENT.md`, `ARCHITECTURE.md`, and `ANTI-PATTERNS.md`, that
`/spades-anywhere:plan` and `/spades-anywhere:review` cross-check
Plans against.

Read `docs/FRAMEWORK.md` § Asking the Human and § Output Format
before running.

### Output format

- **Both modes** — `PATTERNS.md` at the root of the knowledge
  store, the canonical record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/patterns/template.html`: a
  persistent `.spades-anywhere/patterns.html` and a transient
  `.spades-anywhere/.tmp/patterns.html` opened as the review surface
  for the assembled document.
- **CLI mode** — the assembled document prints once in the brief.

A root document; no backend mirror.

## The core rule: facilitate, never author

The team's conventions are their decisions; capture them. You may
ask, reflect back, propose structure, suggest wording, and, in
Create mode, offer an explicitly labelled draft from shared context
(retrospectives, kickoff notes, attached docs). Every section lands
only after the human confirms it. A convention the team does not
follow, or a generic best practice they have not adopted, is a
question rather than a line.

## What `PATTERNS.md` is

It owns **approved process conventions** — "we do X". The dual,
`ANTI-PATTERNS.md`, owns "we don't do Y". How the work is structured
is `ARCHITECTURE.md`; why it exists is `INTENT.md`.

## Inline template

The scaffold `/spades-anywhere:setup` writes and Create mode fills.
Exactly this shape:

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Patterns

## Process Conventions

<!-- How stages move. Hand-offs. Definition of done per stage.
     What needs explicit sign-off, what flows automatically. -->

## Communication

<!-- How the team coordinates. Sync vs async. Channels.
     Status-update cadence. -->

## Decision Making

<!-- Who decides what. Where decisions get recorded. How
     reversible vs irreversible decisions are handled. -->

## Quality Bar

<!-- What "good" looks like for the work the team produces.
     Concretely: not "high quality" — "every artefact has been
     reviewed by at least one person other than the author". -->
```

The placeholder comments stay when the human starts blank. Each
convention is one bullet with a bold short title — `- **Title.**
explanation.` — so the renderer can card and count them.

## Modes

Inspect `./PATTERNS.md`: **Missing** → Create; **unfilled** → Create
in place; **filled** → Edit. Confirm via `AskUserQuestion` when
ambiguous.

**Create.** Offer via `AskUserQuestion`: **Draft a starting point
from what's already shared, then I correct it** / **Start blank**.

**Edit.** Read the existing file first, then scope via
`AskUserQuestion`: **Refresh `last_reviewed` only** / **Revise
specific sections** / **Full review pass**.

## Conversational style

One section at a time. Probe vague answers ("we coordinate well" —
how?). Suggest sharper wording. Capture what is real, not
aspirational. Reflect and confirm before moving on.

## The four sections

A locked schema.

1. **Process Conventions** — how stages move, hand-offs, definition
   of done per stage.
2. **Communication** — sync versus async, channels, update cadence.
3. **Decision Making** — who decides what, where decisions are
   recorded, reversible versus irreversible.
4. **Quality Bar** — what good looks like, concretely.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit.

## Writing the file

Write `./PATTERNS.md` once the human has confirmed every section in
play.

**HTML mode** — after the write, render twice from the template per
`docs/FRAMEWORK.md § Output Format → HTML rendering`, identical
inputs, different paths: `.spades-anywhere/patterns.html`
(persistent) and `.spades-anywhere/.tmp/patterns.html` (transient,
opened).

- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version }`
- `rule_count` *(scalar)*: total conventions across the four sections
- `blocks`:
  - `process-rules`, `communication-rules`, `decisions-rules`,
    `quality-rules` — one card per bullet under the matching
    section. Fields: `title` (the bold lead), `text_html` (the rest).
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.

Required markers: the four `*-rules` blocks.

## Brief

**HTML mode:**

```
✓ PATTERNS.md written (last reviewed YYYY-MM-DD)
○ .spades-anywhere/patterns.html opened in browser
Next: /spades-anywhere:anti-patterns · /spades-anywhere:scope <title>
```

**CLI mode:** the write confirmation, the assembled `PATTERNS.md`
once, the same `Next:` line. Remind the human to save the file to
their knowledge store.
