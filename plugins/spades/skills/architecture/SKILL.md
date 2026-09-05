---
name: architecture
description: Create or maintain ARCHITECTURE.md, the project's durable statement of HOW the system is built — components, tech stack, data flow, security posture, operational posture. Use when someone says "set up ARCHITECTURE.md", "document our architecture", "what's our tech stack", "describe the system", "capture the components", "what's the data flow", "what's our threat model", "update the architecture doc", "refresh the architecture", "where does the data go", or when ARCHITECTURE.md is missing, still an unfilled template, or flagged stale by /spades:plan, /spades:approve, or /spades:review (architecture-strategist persona). Also use proactively after a major dependency change, new component introduction, or a Plan that exposes drift between the doc and reality. The human composes the architecture; this skill structures and probes but never authors it. SKIP when the human's intent is per-Plan technical approach (use the Plan's Technical Approach section instead), API-level documentation (use in-code docs / OpenAPI), or process conventions (use /spades:patterns).
version: 1.4.1
---

# /spades:architecture

You are helping a human create or maintain `ARCHITECTURE.md` — the
durable statement of how the system is built. It is a root
reference document, peer to `INTENT.md`, `PATTERNS.md`, and
`ANTI-PATTERNS.md`, that changes infrequently and is the constraint
`/spades:plan`, `/spades:approve`, and `/spades:review`'s
architecture strategist measure every Plan against.

Read `docs/FRAMEWORK.md` § Asking the Human and § Output Format
before running.

### Output format

- **Both modes** — `ARCHITECTURE.md` at the repo root, the
  canonical record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/architecture/template.html`: a
  persistent `.spades/architecture.html` committed alongside the
  `.md`, and a transient `.spades/.tmp/architecture.html` opened as
  the review surface for the assembled document. The per-section
  conversation stays in the terminal.
- **CLI mode** — the assembled document prints once in the brief.

A committed root document; no backend mirror.

## The core rule: facilitate, never author

The human's team made real decisions about how the system is built;
your job is to capture them. You may ask, reflect back, propose
structure, suggest wording for what the human has said, and, in
Create mode, offer an explicitly labelled draft inferred from the
dependency manifests (`package.json`, `pyproject.toml`, `go.mod`,
`Cargo.toml`), READMEs, and `docker-compose.yml`. Every section
lands only after the human actively confirms it; content the human
has not said is a question to ask.

## What `ARCHITECTURE.md` is

It owns **how** the system is built. Why it exists is `INTENT.md`;
approved conventions are `PATTERNS.md`; deliberate avoidances are
`ANTI-PATTERNS.md`; API-level detail is in-code docs or OpenAPI;
per-feature design lives in Scopes and Plans. An architecture says
"the API gateway routes requests to the worker pool via Redis
Streams"; a pattern says "queue consumers are idempotent".

## Inline template

The scaffold `/spades:setup` writes and Create mode fills. Exactly
this shape:

```markdown
---
last_reviewed: YYYY-MM-DD
runtime:   # primary platform, e.g. "Node 22 / Fastify"
datastore: # system of record, e.g. "PostgreSQL 16"
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

<!-- One `### <name> — <tech>` heading per major component, then a
     one-line responsibility under it. List the things a new
     engineer needs to know exist, not every module. The renderer
     turns each into a card and counts them. -->

### Component name — tech

<!-- What this component is responsible for. -->

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

The placeholder comments stay when the human starts blank.

## Modes

Inspect `./ARCHITECTURE.md`: **Missing** → Create; **unfilled**
(two or more placeholder comments) → Create, filling in place;
**filled** → Edit. Confirm via `AskUserQuestion` when the request
is ambiguous.

**Create.** Offer via `AskUserQuestion`: **Draft a starting point
from the repo files, then I correct it** / **Start blank**.

**Edit.** Read the existing file first, then scope via
`AskUserQuestion`: **Refresh `last_reviewed` only** / **Revise
specific sections** / **Full review pass**. Show each section's
current content before discussing changes; untouched sections are
preserved.

## Conversational style

One section at a time: ask, listen, reflect back, confirm. Probe
vague answers ("we use a database" — which, where does it run, what
is the data model?). Suggest sharper wording for the human's own
point. Capture what is running, not what was planned. Match the
ceremony to the work.

## The six sections

A locked schema.

1. **Overview** — two or three paragraphs; the physical shape of the
   system, past the elevator pitch.
2. **Tech Stack** — languages, frameworks, databases, infra,
   third-party services, with versions.
3. **Components** — the things a new engineer needs to know exist,
   five to ten typically, each a `### <name> — <tech>` heading with a
   one-line responsibility so the renderer can card and count them.
   Confirm the `runtime` and `datastore` frontmatter keys here; they
   drive the page's deck.
4. **Data Flow** — where data enters, lands, and is transformed; the
   request, event, or batch lifecycle.
5. **Security Posture** — auth model, secrets, data classification,
   compliance, threat model.
6. **Operational Posture** — hosting, deployment cadence, monitoring,
   incident response, on-call.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit,
including a "still accurate" pass. `/spades:plan` reads it for the
staleness reminder.

## Writing the file

Write `./ARCHITECTURE.md` once the human has confirmed every
section in play.

**HTML mode** — after the write, dispatch two
`worker-html-architecture` sub-agents in one wave per
`docs/FRAMEWORK.md § worker-html-*`, shared content and `open_path`, different
`output_path`: `.spades/architecture.html` (persistent) and
`.spades/.tmp/architecture.html` (transient, opened).

- `open_path`: the absolute `.spades/.tmp/architecture.html` path for initial
  presentation when this document is the active task; `null` for refreshes
  or background use. Both workers inherit it per § Review-page ownership.
- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/architecture/template.html`
- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version, runtime, datastore }` — `runtime` and `datastore`
  from the file's own frontmatter, omitted when unset (the template
  shows `—`)
- `components_count` *(scalar)*: the number of `components` items
- `blocks`:
  - `components` — one per `### <name> — <tech>` heading. Fields:
    `name, tech, desc`.
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.
- `prose_sections`: `{ overview_html, tech_stack_html,
  data_flow_html, security_html, ops_html }`

Required marker: `components`. The worker also checks the
`{{spades.<section>_html}}` placeholders are present.

## Brief

**HTML mode** (report “opened” only from `opened: true`; if opening was
requested but failed, link that selected page for manual opening. With
`open_path: null`, report the write only):

```
✓ ARCHITECTURE.md written (last reviewed YYYY-MM-DD)
○ .spades/.tmp/architecture.html opened in browser
Next: /spades:patterns · /spades:anti-patterns
```

**CLI mode:** the write confirmation, the assembled
`ARCHITECTURE.md` once, the same `Next:` line.
