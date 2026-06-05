---
name: patterns
description: Create or maintain PATTERNS.md, the project's durable list of APPROVED conventions for how this work is run — process conventions, communication, decision making, quality bar. Use when someone says "set up PATTERNS.md", "document our process conventions", "how do we run this kind of work", "update the patterns doc", or when PATTERNS.md is missing, still an unfilled template, or flagged stale. The human composes the patterns; this skill structures and probes but never authors it.
version: 1.0.0
---

# SPADES-anywhere Patterns

### Output format

This skill honours `review_format:` from
`.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. **`PATTERNS.md`
itself stays at the repo root as human-authored Markdown.** In
HTML mode, after writing/refreshing `PATTERNS.md` the skill
renders a persistent summary at
`.spades-anywhere/patterns.html` via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/patterns/template.html`, and a
transient preview at `.spades-anywhere/.tmp/patterns.html`
during the edit flow. In CLI mode, no preview is rendered.

You are helping a human create or maintain `PATTERNS.md` — the
durable list of approved conventions for *how this work is run*.
In `spades-anywhere`, these patterns are about process — how
stages move, how the team communicates, how decisions are made,
what "good" looks like.

`PATTERNS.md` is a root reference document, peer to `INTENT.md`,
`ARCHITECTURE.md`, and `ANTI-PATTERNS.md`. It changes
infrequently. `/spades-anywhere:plan` and
`/spades-anywhere:review` cross-check Plans against it.

## The Core Rule: Facilitate, Never Author

**The human owns the patterns. You structure them. You never
invent them.**

Same rule as `/spades-anywhere:intent`. The team's conventions
are *their* decisions — capture them, don't invent new ones.

- **You MAY** ask, reflect, propose structure, suggest wording,
  draft a starting point from shared context (existing
  retrospectives, kickoff notes, attached docs).
- **You MUST NOT** invent conventions the human did not state;
  bring in generic "best practice" rules as if the team had
  decided them; save `PATTERNS.md` before the human has
  reviewed every section.

## What PATTERNS.md Is — and Is Not

`PATTERNS.md` owns **approved process conventions**. It does NOT
own:

- **Why** the project exists / for whom → `INTENT.md`.
- **How** the work is structured (stages, stakeholders,
  cadence) → `ARCHITECTURE.md`.
- **Things the team deliberately avoids** → `ANTI-PATTERNS.md`.

## Inline PATTERNS.md Template

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

## Where PATTERNS.md Lives

`PATTERNS.md` lives at the **repository root** (or knowledge
store root for chat-surface contexts), alongside `INTENT.md`,
`ARCHITECTURE.md`, `ANTI-PATTERNS.md`.

## Modes

- **No file** → **Create mode**.
- **Unfilled template** → **Create mode**.
- **Filled and complete** → **Edit mode**.

If ambiguous, confirm via `AskUserQuestion`.

### Create Mode

Walk the human through all four sections. Offer:

- *Draft a starting point from what's already shared, then I
  correct it*
- *Start blank — I'll describe it myself*

### Edit Mode

`AskUserQuestion`:

- *Refresh `last_reviewed` only*
- *Revise specific sections*
- *Full review pass*

**Always read the existing file first** — preserve what's there.

## Conversational Style

1. **One section at a time.**
2. **Probe vague answers.** "We coordinate well" — how?
3. **Suggest sharper wording.**
4. **Capture what's real, not aspirational.**
5. **Reflect and confirm before moving on.**

## The Four Sections

`PATTERNS.md` has exactly four sections. Locked schema.

### 1. Process Conventions
How stages move. Hand-offs. Definition of done per stage.

### 2. Communication
How the team coordinates. Sync vs async. Channels.

### 3. Decision Making
Who decides what. Where decisions get recorded.

### 4. Quality Bar
What "good" looks like for the work the team produces.
Concretely, not abstractly.

## The `last_reviewed` Field

Set to today's date on every Create or meaningful Edit.

## Decision Prompts (AskUserQuestion)

- **Mode confirmation** when ambiguous.
- **Create-mode start** — *Draft inferred* / *Start blank*.
- **Edit-mode scope** — *Refresh `last_reviewed` only* / *Revise
  specific sections* / *Full review pass*.

## Writing the File

Write `./PATTERNS.md` only after the human has reviewed every
section in play.

**In HTML mode, also write a persistent
`.spades-anywhere/patterns.html` alongside `PATTERNS.md`.** In
CLI mode, the `.html` is NOT written.

There is **no SCM in spades-anywhere** — the human saves both
files to their chat-surface knowledge store on their own
cadence.

### Transient HTML preview (HTML mode only)

When `review_format: html`, render to
`.spades-anywhere/.tmp/patterns.html`:

**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.**

1. Read the template at
   `${CLAUDE_PLUGIN_ROOT}/skills/patterns/template.html`.
2. Validate placeholders; abort if any missing.
3. Substitute:
   - `{{spades.project_slug}}`, `{{spades.last_reviewed}}`,
     `{{spades.rendered_at}}`, `{{spades.plugin_version}}`.
   - Prose sections: `{{spades.process_html}}`,
     `{{spades.communication_html}}`,
     `{{spades.decisions_html}}`, `{{spades.quality_html}}`.
4. Write to `.spades-anywhere/.tmp/patterns.html`.
5. Auto-open via the OPEN_CMD prelude.

`PATTERNS.md` itself stays Markdown in both modes.
