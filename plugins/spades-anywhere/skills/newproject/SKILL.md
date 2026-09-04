---
name: newproject
description: Create a new SPADES Project record — the long-lived container above Scopes (a real-world initiative, a service area, a long-lived effort). Use when starting a brand-new initiative, when someone says "new project", "create a project", "set up a project for X", or after /spades-anywhere:setup asks for an active project that doesn't exist yet. Writes .spades-anywhere/projects/<slug>.md and (when backend is Linear) creates the corresponding Linear Project.
version: 0.4.0
---

# /spades-anywhere:newproject

You are creating a Project record — the long-lived container above
Scopes: a family's events, a hiring function, a house move, a book.

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades-anywhere/ Local
Layout, § Bootstrap Order, and § Output Format before running.

### Output format

- **Both modes** — `.spades-anywhere/projects/<slug>.md`, the
  canonical record.
- **HTML mode** — additionally `.spades-anywhere/projects/<slug>.html`
  from `${CLAUDE_PLUGIN_ROOT}/skills/newproject/template.html`,
  auto-opened as the review surface; iteration is a targeted `.md`
  edit plus a re-render.
- **CLI mode** — the record is pasted for confirmation before the
  write.

## Pre-Flight

Probe `.spades-anywhere/config`. `present` → read `backend:` and
`review_format:` (this is also the state when
`/spades-anywhere:setup` invokes this skill inline during bootstrap,
with `project:` unset for Step 4 to fill). `missing` → abort: *"Run
`/spades-anywhere:setup` first — it configures the backend and, on
the same pass, creates your first project."* Setup creates the
project itself; the `setup → newproject` edge points one way.

## Step 1 — Gather

Conversationally:

- **Title** — *"Family events"*, *"Q3 hiring round"*. The slug
  derives from it.
- **Description** — two or three sentences: what it is, why it
  exists, who owns it.
- **Places** — where the project's material lives: a shared drive
  folder, a Notion space, a repo URL. Recorded under `repos:`; may
  be empty for now.
- **Owners** — names, handles, or email addresses, at least one.

### Slug

Lowercase; runs outside `[a-z0-9-]` to a single hyphen; trim;
truncate to 64 characters; reject empty, a leading hyphen, `..`, or
a slug that matches an existing project file. *"Family events"* →
`family-events`. Confirm via `AskUserQuestion`: **Use this slug** /
**Edit the slug**.

## Step 2 — Collision check

- **Local** — an existing `.spades-anywhere/projects/<slug>.md`
  aborts: *"A project named `<slug>` already exists."*
- **Linear** (`backend: linear`) — an existing Linear Project of the
  same name → `AskUserQuestion`: **Bind to the existing Linear
  Project** (recommended) / **Create a separate one**.

## Step 3 — Write and mirror (fan-out)

### The canonical `.md` (both modes)

```markdown
---
id: <slug>
title: "<title>"
description: "<description>"
repos:
  - <place-1>
owners:
  - <owner-1>
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_project_id: <uuid>        # backend: linear, injected after the wave
---

# <title>

<description>

## Places

- <place-1>

## Owners

- <owner-1>

## Scopes

<!-- /spades-anywhere:list renders the live view; not maintained by hand -->

## Audit Trail

- YYYY-MM-DD: Project created.
```

### The `.html` (HTML mode)

Rendered from `${CLAUDE_PLUGIN_ROOT}/skills/newproject/template.html`
to `.spades-anywhere/projects/<slug>.html` per `docs/FRAMEWORK.md §
Output Format → HTML rendering`:

- `frontmatter`: `{ id, title, description, status, created,
  updated }`, embedded verbatim in `<script id="spades-frontmatter">`
- `blocks`:
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`
  - `repos-items` — one per place. Fields: `url, label`.
  - `owners-items` — one per owner. Fields: `name, email` (`—` when
    absent).
  - `status-filters` — one chip per Scope status. Fields: `label,
    count`.
  - `scopes-rows` — one per Scope. Fields: `id, title, status,
    plans, updated`.
  - `audit-events` — one per audit entry. Fields: `date, desc`.

Required markers: `objective-banner`, `repos-items`, `owners-items`,
`status-filters`, `scopes-rows`, `audit-events`.

### The wave

Per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-project` | `.spades-anywhere/projects/<slug>.md`, without `linear_project_id` | `{ status: ok }` |
| `worker-html-project` *(HTML mode)* | `.spades-anywhere/projects/<slug>.html` | `{ status: ok, path, opened }` |
| `worker-linear-project` *(`backend: linear`)* | Linear — a Project with the title and description on `linear.team_id` | `{ status: ok, linear_project_id }` |

After the wave: all ok → inject `linear_project_id` into the `.md`
(and the `.html`), record the dispatch mode; file worker failed →
abort, noting a Linear Project may be orphaned; HTML failed → keep
the `.md`, continue; Linear failed → keep the local file, offer a
retry.

## Step 4 — Active project

`AskUserQuestion`: **Set as active project** (recommended) / **Leave
the active project unchanged**. When invoked inline by setup during
bootstrap (`project:` unset), set it active without asking and
return. Setting active replaces or inserts `project: <slug>` (and
`linear.project_id` with Linear) in `.spades-anywhere/config`.

## Step 5 — Confirm

```
✓ Project created: <slug>
✓ Title:           <title>
✓ Places:          1
✓ Owners:          2
✓ Linear Project:  <id>    (backend: linear)
✓ Active project:  <slug>  (or: unchanged)

Next:
  /spades-anywhere:scope <title>   — define your first Scope under this project
```

## Edge cases

- **No place yet** — `repos:` may be `[]`; the human re-runs to
  add one.
- **Owners outside the team** — accept the strings as given.
- **Switching to a different project** — `.spades-anywhere/config`
  names one active project; the human re-runs
  `/spades-anywhere:setup` to pick another.
