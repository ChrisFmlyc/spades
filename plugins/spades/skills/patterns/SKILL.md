---
name: patterns
description: Create or maintain PATTERNS.md, the project's durable list of APPROVED patterns and conventions — code organisation, error handling, testing, naming. Use when someone says "set up PATTERNS.md", "document our conventions", "what patterns do we use", "update the patterns doc", or when PATTERNS.md is missing, still an unfilled template, or flagged stale. The human composes the patterns; this skill structures and probes but never authors it.
version: 1.0.1
---

# SPADES Patterns

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. **`PATTERNS.md`
itself stays at the repo root as human-authored Markdown — it is
not auto-converted to HTML in either mode.** In HTML mode, after
writing/refreshing `PATTERNS.md` the skill renders a persistent
summary at `.spades/patterns.html` via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/patterns/template.html`, and a
transient preview at `.spades/.tmp/patterns.html` during the edit
flow. In CLI mode, no preview is rendered. The Socratic
facilitate-never-author flow is identical between modes.

You are helping a human create or maintain `PATTERNS.md` — the
durable list of approved patterns and conventions in this
project. `PATTERNS.md` is a root reference document, peer to
`INTENT.md`, `ARCHITECTURE.md`, and `ANTI-PATTERNS.md`. It
changes infrequently. It is the convention layer that
`/spades:plan` and `/spades:review` (architecture-strategist
persona) cross-check against: when a Plan would introduce code
that violates a recorded pattern, `PATTERNS.md` is what makes
that visible.

## The Core Rule: Facilitate, Never Author

**The human owns the patterns. You structure them. You never
invent them.**

Same non-negotiable rule as `/spades:intent` and
`/spades:architecture`. The team's conventions are *their*
decisions — the AI's job is to capture them, not invent new
ones. If the AI silently records a pattern the team doesn't
actually follow, every downstream review built on that pattern
will measure against fiction.

Concretely:

- **You MAY** ask questions, reflect answers back, propose
  *structure*, suggest *wording* for something the human has
  already expressed, and — in Create mode — offer an
  explicitly-labelled *draft starting point* inferred from the
  repo (sample files, existing test patterns, dependency
  layout) for the human to accept, reject, or rewrite.
- **You MUST NOT** write a pattern the human has not supplied or
  confirmed; present an inferred convention as established fact;
  invent rules the team does not actually follow; or save
  `PATTERNS.md` before the human has reviewed every section.
- **Silence is not consent.**

If you ever find yourself typing a pattern the human did not
say, stop and ask them instead.

## What PATTERNS.md Is — and Is Not

`PATTERNS.md` owns **approved conventions** the team follows when
writing code. It does NOT own:

- **Why** the project exists / for whom → `INTENT.md`.
- **How** the system is built (tech stack, components) →
  `ARCHITECTURE.md`.
- **Things the team deliberately avoids** → `ANTI-PATTERNS.md`.
  (The dual: PATTERNS is "we do X"; ANTI-PATTERNS is "we don't
  do Y".)
- **Style minutiae** (semicolons, tabs vs spaces) — those live
  in a formatter config (Prettier, Black, etc.) not in
  PATTERNS.md.

This skill is distinct from its neighbours:

- It is **not** `/spades:architecture`. Architecture is what
  the system *is*; patterns are how the team *codes*. An
  architecture says "Redis Streams for queues"; a pattern says
  "queue consumers are idempotent and retry on failure".
- It is **not** `/spades:anti-patterns`. They're a pair:
  PATTERNS for affirmative conventions, ANTI-PATTERNS for
  explicit prohibitions.

## Inline PATTERNS.md Template

When this skill needs to scaffold a fresh `PATTERNS.md`, use
exactly this shape:

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

Leave the placeholder comments in place if the human picks
"start blank" — they're the prompts that walk them through
filling each section.

## Where PATTERNS.md Lives

`PATTERNS.md` lives at the **repository root**, alongside
`INTENT.md`, `ARCHITECTURE.md`, `ANTI-PATTERNS.md`. This skill
reads and writes `./PATTERNS.md` in the current project. It is a
plain Markdown file with a small YAML frontmatter block
(`last_reviewed`).

## Modes

Determine the mode by inspecting `./PATTERNS.md`:

- **No `PATTERNS.md`** → **Create mode**.
- **`PATTERNS.md` exists but is still an unfilled template** —
  it contains two or more `<!-- Describe … -->` / `<!-- List … -->`
  style markers → **Create mode** (you are filling the
  scaffolded template in place).
- **`PATTERNS.md` exists and is filled in** → **Edit mode**.

If ambiguous, confirm via `AskUserQuestion`.

### Create Mode

Walk the human through all four sections from scratch. Before
starting, offer — via `AskUserQuestion` — to draft a starting
point inferred from the repo's existing patterns (sample test
files, error-handling shape in source files, file structure):

- *Draft a starting point inferred from the repo, then I correct it*
- *Start blank — I'll describe it myself*

If they choose the draft, scan a representative sample of the
codebase, propose a draft **per section, clearly labelled as an
inference you need them to correct**, and treat their
corrections as the real content.

### Edit Mode

The human wants to refine an existing `PATTERNS.md`. Use
`AskUserQuestion` to scope the edit:

- *Refresh `last_reviewed` only — the patterns are still accurate*
- *Revise specific sections*
- *Full review pass — walk every section*

**Always read the existing file first** — preserve what's there;
never rewrite from scratch.

## Conversational Style

1. **One section at a time.** Ask, listen, reflect back,
   confirm, move on.
2. **Probe vague answers.** "We test things" is not enough —
   what testing style, which layer, what does coverage look like?
3. **Suggest sharper wording.** Tighten the human's point; don't
   invent new substance.
4. **Capture what's real, not aspirational.** If the codebase
   has 30% test coverage, "we test-first new features" is
   aspirational; the *actual* pattern might be "we test the
   payment path well; everywhere else is best-effort".
5. **Reflect and confirm before moving on.**
6. **Match ceremony to the work.** A first-time Create for a
   serious codebase deserves a real conversation; a refresh is
   two lines.

## The Four Sections

`PATTERNS.md` has exactly four sections. Locked schema.

### 1. Code Organisation
How the codebase is structured. Feature folders vs layers? Where
does shared code live? What's the import boundary between
modules? What's the "house style" for laying out a new feature?

### 2. Error Handling
How does the codebase express failures? Result types?
Exceptions? Where are errors logged vs surfaced? How does the
boundary between trusted and untrusted code handle validation?

### 3. Testing
Test-first? Characterization-first? Which layer of the testing
pyramid (unit / integration / e2e) carries the most weight?
What's a "good" test in this codebase look like — concretely,
not abstractly?

### 4. Naming
Conventions for files, functions, types, variables, branches,
commits. Capture what's actually consistent in the codebase, not
what's aspirational. A pattern that's broken by 50% of the
codebase isn't a pattern.

## The `last_reviewed` Field

`PATTERNS.md` carries a `last_reviewed: YYYY-MM-DD` field in its
YAML frontmatter. Whenever this skill finishes a Create or a
meaningful Edit — including a "still accurate" review pass with
no content change — set `last_reviewed` to **today's date**.

## Decision Prompts (AskUserQuestion)

- **Mode confirmation** when Create vs Edit is ambiguous.
- **Create-mode start** — *Draft inferred from the repo* /
  *Start blank*.
- **Edit-mode scope** — *Refresh `last_reviewed` only* /
  *Revise specific sections* / *Full review pass*.

## Writing the File

Write `./PATTERNS.md` only after the human has reviewed every
section in play:

- **Create mode** — write the full file: the `last_reviewed`
  frontmatter, a short `# Patterns` heading, and the four `##`
  sections with the human's confirmed content. Remove any
  template fill markers.
- **Edit mode** — apply the confirmed changes and update
  `last_reviewed`. Preserve sections the human did not touch.

**In HTML mode, also write a persistent `.spades/patterns.html`
alongside `PATTERNS.md`.** Use the same template the transient
preview uses (`${CLAUDE_PLUGIN_ROOT}/skills/patterns/template.html`).
`.spades/patterns.html` is persistent (committed); the
`.spades/.tmp/patterns.html` preview is transient (gitignored).
In CLI mode, `.spades/patterns.html` is NOT written.

Then confirm what changed and remind the human that
`PATTERNS.md` is a living document the SPADES loop reads.

There is no Linear step.

### Transient HTML preview (HTML mode only)

When `review_format: html`, during/after the section-by-section
walk, also render a transient preview:

**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.** Validate the template exists and the named
markers match before substituting; abort and surface any
mismatch. See `docs/FRAMEWORK.md § Output Format → HTML
rendering: validate and use the bundled template` for the
canonical rule.

1. Read the template at
   `${CLAUDE_PLUGIN_ROOT}/skills/patterns/template.html`.
2. Validate it contains the placeholders listed below; if any
   are missing, abort with: *`template.html` missing required
   markers — render aborted. `PATTERNS.md` is unchanged.*
3. Substitute:
   - `{{spades.project_slug}}`, `{{spades.last_reviewed}}`,
     `{{spades.rendered_at}}`, `{{spades.plugin_version}}`.
   - The prose sections render via direct substitutions:
     `{{spades.code_organisation_html}}`,
     `{{spades.error_handling_html}}`,
     `{{spades.testing_html}}`, `{{spades.naming_html}}`.
4. Write to `.spades/.tmp/patterns.html`.
5. Auto-open via the OPEN_CMD prelude.

In HTML mode the open `.html` preview IS the review surface
during the walk — the Socratic conversation stays CLI; the
*assembled PATTERNS document* shown for review must be HTML.

`PATTERNS.md` itself stays Markdown in both modes — only the
preview is HTML.
