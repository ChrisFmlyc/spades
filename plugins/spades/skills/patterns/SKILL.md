---
name: patterns
description: Create or maintain PATTERNS.md, the project's durable list of APPROVED patterns and conventions — code organisation, error handling, testing, naming. Use when someone says "set up PATTERNS.md", "document our conventions", "what patterns do we use", "update the patterns doc", or when PATTERNS.md is missing, still an unfilled template, or flagged stale. The human composes the patterns; this skill structures and probes but never authors it.
version: 1.4.0
---

# /spades:patterns

You are helping a human create or maintain `PATTERNS.md` — the
durable list of approved patterns and conventions the team follows
when writing code. A root reference document, peer to `INTENT.md`,
`ARCHITECTURE.md`, and `ANTI-PATTERNS.md`, that `/spades:plan` and
`/spades:review`'s architecture strategist cross-check Plans
against.

Read `docs/FRAMEWORK.md` § Asking the Human and § Output Format
before running.

### Output format

- **Both modes** — `PATTERNS.md` at the repo root, the canonical
  record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/patterns/template.html`: a
  persistent `.spades/patterns.html` and a transient
  `.spades/.tmp/patterns.html` opened as the review surface for the
  assembled document. The per-section conversation stays in the
  terminal.
- **CLI mode** — the assembled document prints once in the brief.

A committed root document; no backend mirror.

## The core rule: facilitate, never author

The team's conventions are their decisions; capture them. You may
ask, reflect back, propose structure, suggest wording, and, in
Create mode, offer an explicitly labelled draft inferred from a
representative sample of the codebase (test files, error-handling
shape, file layout). Every section lands only after the human
actively confirms it. A convention the team does not follow is a
question, not a line.

## What `PATTERNS.md` is

It owns **approved conventions** — "we do X". The dual,
`ANTI-PATTERNS.md`, owns "we don't do Y". How the system is built is
`ARCHITECTURE.md`; why it exists is `INTENT.md`; style minutiae
(semicolons, tabs) belong in a formatter config.

## Inline template

The scaffold `/spades:setup` writes and Create mode fills. Exactly
this shape:

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Patterns

## Code Organisation

<!-- How the codebase is structured. Feature folders vs layers?
     Where does shared code live? What's the import boundary
     between modules? -->

## Error Handling

<!-- How does the codebase express failures? Result types?
     Exceptions? Where are errors logged vs surfaced? How does
     the boundary between trusted/untrusted layers handle
     validation? -->

## Testing

<!-- Test-first? Characterization-first? Which layer of the
     pyramid (unit/integration/e2e) carries the most weight?
     What's a "good" test in this codebase? -->

## Naming

<!-- Conventions for files, functions, types, variables, branches,
     commits. Capture what's actually consistent in the
     codebase, not what's aspirational. -->
```

The placeholder comments stay when the human starts blank. Each
convention is one bullet with a bold short title — `- **Title.**
explanation.` — so the renderer can card and count them.

## Modes

Inspect `./PATTERNS.md`: **Missing** → Create; **unfilled** (two or
more placeholder comments) → Create in place; **filled** → Edit.
Confirm via `AskUserQuestion` when ambiguous.

**Create.** Offer via `AskUserQuestion`: **Draft a starting point
inferred from the repo, then I correct it** / **Start blank**.

**Edit.** Read the existing file first, then scope via
`AskUserQuestion`: **Refresh `last_reviewed` only** / **Revise
specific sections** / **Full review pass**. Untouched sections are
preserved.

## Conversational style

One section at a time. Probe vague answers ("we test things" — which
style, which layer, what does coverage look like?). Suggest sharper
wording. Capture what is real rather than aspirational: with 30%
coverage, the pattern is "we test the payment path well; elsewhere
is best-effort", not "we test-first". A convention half the codebase
breaks is not a pattern.

## The four sections

A locked schema.

1. **Code Organisation** — feature folders or layers, where shared
   code lives, import boundaries, the house style for a new feature.
2. **Error Handling** — result types or exceptions, where errors are
   logged versus surfaced, validation at trust boundaries.
3. **Testing** — the approach, the layer that carries the weight,
   what a good test looks like concretely.
4. **Naming** — files, functions, types, variables, branches,
   commits.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit,
including a "still accurate" pass.

## Writing the file

Write `./PATTERNS.md` once the human has confirmed every section in
play.

**HTML mode** — after the write, dispatch two `worker-html-patterns`
sub-agents in one wave per `docs/FRAMEWORK.md § worker-html-*`,
identical inputs, different `output_path`: `.spades/patterns.html`
(persistent) and `.spades/.tmp/patterns.html` (transient, opened).

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/patterns/template.html`
- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version }`
- `rule_count` *(scalar)*: total conventions across the four sections
- `blocks`:
  - `code-organisation-rules`, `error-handling-rules`,
    `testing-rules`, `naming-rules` — one card per bullet under the
    matching section. Fields: `title` (the bold lead), `text_html`
    (the rest).
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.

Required markers: the four `*-rules` blocks.

## Brief

**HTML mode:**

```
✓ PATTERNS.md written (last reviewed YYYY-MM-DD)
○ .spades/patterns.html opened in browser
Next: /spades:anti-patterns · /spades:scope <title>
```

**CLI mode:** the write confirmation, the assembled `PATTERNS.md`
once, the same `Next:` line.
