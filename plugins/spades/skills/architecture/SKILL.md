---
name: architecture
description: Create or maintain ARCHITECTURE.md, the project's durable statement of HOW the system is built — components, tech stack, data flow, security posture, operational posture. Use when someone says "set up ARCHITECTURE.md", "document our architecture", "what's our tech stack", "describe the system", "capture the components", "what's the data flow", "what's our threat model", "update the architecture doc", "refresh the architecture", "where does the data go", or when ARCHITECTURE.md is missing, still an unfilled template, or flagged stale by /spades:plan, /spades:approve, or /spades:review (architecture-strategist persona). Also use proactively after a major dependency change, new component introduction, or a Plan that exposes drift between the doc and reality. The human composes the architecture; this skill structures and probes but never authors it. SKIP when the human's intent is per-Plan technical approach (use the Plan's Technical Approach section instead), API-level documentation (use in-code docs / OpenAPI), or process conventions (use /spades:patterns).
version: 1.2.0
---

# SPADES Architecture

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. **`ARCHITECTURE.md`
itself stays at the repo root as human-authored Markdown — it is
not auto-converted to HTML in either mode.** In HTML mode, after
writing/refreshing `ARCHITECTURE.md` the skill renders a persistent
summary at `.spades/architecture.html` via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/architecture/template.html`, and a
transient preview at `.spades/.tmp/architecture.html` during the
edit flow — both auto-open via OPEN_CMD so the human can review
in the same B-style format they review other artefacts. In CLI
mode, no preview is rendered; the human reads `ARCHITECTURE.md`
directly. The Socratic facilitate-never-author flow is identical
between modes.

You are helping a human create or maintain `ARCHITECTURE.md` —
the durable statement of HOW this project is built.
`ARCHITECTURE.md` is a root reference document, peer to
`INTENT.md`, `PATTERNS.md`, and `ANTI-PATTERNS.md`. It changes
infrequently. It is the constraint every Plan is measured
against by `/spades:plan` and `/spades:review`
(architecture-strategist persona): when a Plan would violate the
recorded tech stack, data flow, or security posture,
`ARCHITECTURE.md` is what makes that visible.

## The Core Rule: Facilitate, Never Author

**The human owns the architecture. You structure it. You never
invent it.**

The same non-negotiable rule as `/spades:intent`. The human's
team has made real decisions about how this system is built —
your job is to capture those decisions, not invent new ones. If
an AI quietly writes the architecture, the document becomes a
fiction and every downstream Plan-review check built on it is
checking against that fiction.

Concretely:

- **You MAY** ask questions, reflect answers back, propose
  *structure*, suggest *wording* for something the human has
  already expressed, and — in Create mode — offer an
  explicitly-labelled *draft starting point* inferred from the
  repo (`package.json`, `pyproject.toml`, `go.mod`, READMEs,
  obvious dependency files) for the human to accept, reject, or
  rewrite.
- **You MUST NOT** write a section the human has not supplied or
  confirmed; present inferred content as established fact;
  invent components, services, or data flows the human did not
  state; or save `ARCHITECTURE.md` before the human has seen and
  approved every section.
- **Silence is not consent.** Every section — especially every
  draft you propose — must be actively confirmed by the human
  before it lands in the file.

If you ever find yourself typing architecture content the human
did not say, stop and ask them instead.

## What ARCHITECTURE.md Is — and Is Not

`ARCHITECTURE.md` owns **how** the project is built. It does NOT
own:

- **Why** the project exists / for whom → `INTENT.md`.
- **Approved patterns and conventions** → `PATTERNS.md`.
- **Things this codebase deliberately avoids** → `ANTI-PATTERNS.md`.
- **Detailed API documentation** → in-code docs, OpenAPI specs,
  or a separate API reference. ARCHITECTURE describes the shape;
  the implementation describes itself.
- **Per-feature design notes** → those live in SPADES Scopes and
  Plans.

This skill is distinct from its neighbours, deliberately:

- It is **not** `/spades:scope`. A Scope defines one unit of
  work. `ARCHITECTURE.md` is one durable document.
- It is **not** `/spades:patterns`. Patterns are *conventions
  the team follows when writing code*; Architecture is *what
  the system is*. A pattern says "we test-first new features";
  an architecture says "the API gateway routes requests to the
  worker pool via Redis Streams".

## Inline ARCHITECTURE.md Template

When this skill needs to scaffold a fresh `ARCHITECTURE.md`, use
exactly this shape — never copy from an external template file:

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Architecture

## Overview

<!-- Two or three paragraphs describing the system at a high
     level. What does it do, what runs where, who uses it,
     what's the headline shape? -->

## Tech Stack

<!-- Languages, frameworks, databases, infra primitives,
     third-party services. Be specific: "Node 22 + Fastify",
     "PostgreSQL 16 on AWS RDS", "Redis 7 for cache + queues". -->

## Components

<!-- Major components and their responsibilities. Don't list
     every module; list the things a new engineer needs to know
     exist. -->

## Data Flow

<!-- How information moves through the system. Where does data
     enter, where does it land, what transforms it on the way.
     Sketch the request lifecycle. -->

## Security Posture

<!-- Auth model, secrets handling, data classification,
     compliance constraints. What's the threat model? -->

## Operational Posture

<!-- Hosting, deployment cadence, monitoring, incident response,
     on-call. How does this system stay up? -->
```

Leave the placeholder comments in place if the human picks
"start blank" — they're the prompts that walk them through
filling each section.

## Where ARCHITECTURE.md Lives

`ARCHITECTURE.md` lives at the **repository root**, alongside
`INTENT.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`. This skill reads
and writes `./ARCHITECTURE.md` in the current project. It is a
plain Markdown file with a small YAML frontmatter block
(`last_reviewed`).

## Modes

Determine the mode by inspecting `./ARCHITECTURE.md`:

- **No `ARCHITECTURE.md`** → **Create mode**.
- **`ARCHITECTURE.md` exists but is still an unfilled template** —
  it contains two or more `<!-- Describe … -->` / `<!-- List … -->`
  style markers → **Create mode** (you are filling the
  scaffolded template in place).
- **`ARCHITECTURE.md` exists and is filled in** → **Edit mode**.

If the human's request is ambiguous (e.g. a filled
`ARCHITECTURE.md` exists but they said "set up our architecture
doc"), confirm the mode with `AskUserQuestion` rather than
guessing.

### Create Mode

Walk the human through all six sections from scratch (or fill
the scaffolded template). Before starting, offer — via
`AskUserQuestion` — to draft a starting point inferred from the
repo's `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`
/ README / `docker-compose.yml`:

- *Draft a starting point from the repo files, then I correct it*
- *Start blank — I'll describe it myself*

If they choose the draft, read the dependency manifests and
obvious docs, propose a draft **per section, clearly labelled as
an inference you need them to correct**, and treat their
corrections as the real content. If they choose blank, ask about
each section directly.

### Edit Mode

The human wants to refine an existing `ARCHITECTURE.md`, or a
SPADES skill flagged it (staleness nudge from `/spades:plan`,
architecture-strategist persona surfaced drift). Use
`AskUserQuestion` to scope the edit:

- *Refresh `last_reviewed` only — the content is still accurate*
- *Revise specific sections*
- *Full review pass — walk every section*

For "revise specific sections", ask which. For a full pass, walk
all six.  Show the current content of each section before
discussing changes. **Always read the existing file first** —
preserve what's there; never rewrite from scratch.

## Conversational Style

This is an interactive, guided conversation — not a form, and
not a document you write for them.

1. **One section at a time.** Ask, listen, reflect back,
   confirm, move on. Never dump all six sections at once.
2. **Probe vague answers.** "We use a database" is not enough —
   which database, where does it run, what's the data model
   like at a high level?
3. **Suggest sharper wording, not new substance.** If the
   human's point is sound but loosely worded, offer a tighter
   phrasing of *their* point.
4. **Reflect and confirm before moving on.** After each section,
   show what you captured and let the human correct it.
5. **Match ceremony to the work.** First-time Create for a
   serious system deserves a real conversation; a
   `last_reviewed` refresh is two lines.

## The Six Sections

`ARCHITECTURE.md` has exactly six sections. The set is a locked
schema — do not add, drop, or rename them. Guide the human
through each:

### 1. Overview
Two or three paragraphs. What does this system do at a high
level, what runs where, who uses it, what's the headline shape?
Push past the elevator pitch into the *physical* shape of the
system.

### 2. Tech Stack
Languages, frameworks, databases, infra primitives, third-party
services. Be specific: versions matter. Capture what's currently
running, not what was planned.

### 3. Components
Major components and their responsibilities. Don't list every
file; list the things a new engineer needs to know exist. Five
to ten is normal.

### 4. Data Flow
How information moves through the system. Where does data enter,
where does it land, what transforms it on the way. Sketch the
request lifecycle (or event lifecycle, or batch lifecycle —
whichever fits).

### 5. Security Posture
Auth model, secrets handling, data classification, compliance
constraints. What's the threat model? What can't this system be
trusted to do safely?

### 6. Operational Posture
Hosting, deployment cadence, monitoring, incident response,
on-call. How does this system stay up?

## The `last_reviewed` Field

`ARCHITECTURE.md` carries a `last_reviewed: YYYY-MM-DD` field in
its YAML frontmatter. Whenever this skill finishes a Create or a
meaningful Edit — including a "still accurate" review pass with
no content change — set `last_reviewed` to **today's date**.
That date is what `/spades:plan` reads to decide whether to
surface a staleness reminder.

## Decision Prompts (AskUserQuestion)

Architecture **content** is open-ended composition and stays
free-form. But the **fixed decisions** this skill makes along the
way use `AskUserQuestion` (per `docs/FRAMEWORK.md` § "Asking
the Human"):

- **Mode confirmation** when Create vs Edit is ambiguous.
- **Create-mode start** — *Draft a starting point from the repo*
  / *Start blank*.
- **Edit-mode scope** — *Refresh `last_reviewed` only* / *Revise
  specific sections* / *Full review pass*.

## Writing the File

Write `./ARCHITECTURE.md` only after the human has reviewed every
section in play:

- **Create mode** — write the full file: the `last_reviewed`
  frontmatter, a short `# Architecture` heading, and the six
  `##` sections with the human's confirmed content. Remove any
  template fill markers.
- **Edit mode** — apply the confirmed changes and update
  `last_reviewed`. Preserve sections the human did not touch.

**In HTML mode (`review_format: html`), also write a persistent
`.spades/architecture.html` alongside `ARCHITECTURE.md`.** Use
the same template the transient preview uses
(`${CLAUDE_PLUGIN_ROOT}/skills/architecture/template.html`) with
the same placeholder substitutions described under "Transient
HTML preview" below — the only difference is the destination
path and lifecycle:

- `.spades/architecture.html` is **persistent** (committed to git
  alongside `ARCHITECTURE.md`). It is the human's steady-state
  view of the project's architecture.
- `.spades/.tmp/architecture.html` (covered below) is
  **transient** (`.tmp/` is gitignored). It exists only for the
  in-flight edit review.

Both files use the same template content; only the path and
lifecycle differ. In CLI mode, `.spades/architecture.html` is NOT
written — only `ARCHITECTURE.md` exists.

Principle landed: artefacts the AI reads stay Markdown
(`ARCHITECTURE.md`); artefacts the human views in HTML mode get
a persistent HTML rendering.

Then confirm what changed and remind the human that
`ARCHITECTURE.md` is a living document the SPADES loop reads.

There is no Linear step — `ARCHITECTURE.md` is a committed root
document, not a tracker artefact.

### Per-section review surface (mode-branched)

**Read `review_format:` from `.spades/config` and branch.** Both
modes need a stable review surface alongside the Socratic walk —
only the surface differs.

#### CLI mode

The per-section reflect-and-confirm summary printed inline during
the walk IS the review surface. After each section, print the
captured content as a self-contained block the human can scroll back
to (don't re-emit only on demand). No file preview is rendered.
Skip ahead to "Writing the File" once all sections are confirmed.

#### HTML mode — parallel render dispatch

When `review_format: html`, after `ARCHITECTURE.md` is written,
dispatch **two** `worker-html-architecture` sub-agents in
parallel per
`docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering`:

- **Persistent**: `output_path = .spades/architecture.html`.
- **Transient**: `output_path = .spades/.tmp/architecture.html`.

Both workers take the same inputs:

- `template_path`:
  `${CLAUDE_PLUGIN_ROOT}/skills/architecture/template.html`
- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version }`
- `prose_sections`: `{ overview_html, tech_stack_html,
  components_html, data_flow_html, security_html, ops_html }`

No required block markers (this template uses prose-only
substitutions; the worker still validates the
`{{spades.<section>_html}}` placeholders are present).

**In HTML mode the open `.html` preview IS the review surface
during the walk — do NOT also paste the assembled
ARCHITECTURE body to the CLI.** The Socratic per-section
back-and-forth (the probing questions, the human's answers, the
per-section confirmations) all stay CLI — those are
conversational. What must NOT go to the CLI in HTML mode is the
*assembled ARCHITECTURE document* shown for review.

`ARCHITECTURE.md` itself stays Markdown in both modes — only the
preview is HTML.

## End-of-Skill Brief

**HTML mode** — 3 lines, no body dump:

```
✓ ARCHITECTURE.md written (last reviewed YYYY-MM-DD)
○ .spades/architecture.html opened in browser
Next: /spades:patterns · /spades:anti-patterns
```

**CLI mode** — confirm the write, then print the assembled
`ARCHITECTURE.md` body once as the review surface:

```
✓ ARCHITECTURE.md written (last reviewed YYYY-MM-DD)

<contents of ARCHITECTURE.md>

Next: /spades:patterns · /spades:anti-patterns
```
