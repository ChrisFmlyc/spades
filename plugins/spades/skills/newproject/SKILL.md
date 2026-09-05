---
name: newproject
description: Create a new SPADES Project record — the long-lived container above Scopes (a repo, a set of repos, a service). Use when starting a brand-new initiative, when someone says "new project", "create a project", "set up a project for X", or after /spades:setup asks for an active project that doesn't exist yet. Writes .spades/projects/<slug>.md and (when backend is Linear) creates the corresponding Linear Project.
version: 3.6.2
---

# /spades:newproject

You are creating a Project record — the long-lived container above
Scopes, typically a repo or set of repos sharing one identity (a
service, a product surface, a marketing site).

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades/ Local Layout,
§ Bootstrap Order, and § Output Format before running.

### Output format

- **Both modes** — `.spades/projects/<slug>.md`, the canonical
  record.
- **HTML mode** — additionally `.spades/projects/<slug>.html` from
  `${CLAUDE_PLUGIN_ROOT}/skills/newproject/template.html` via
  `worker-html-project`, auto-opened as the review surface;
  iteration is a targeted `.md` edit plus a re-render.
- **CLI mode** — the record is pasted for confirmation before the
  write.

## Pre-Flight

1. **Require a backend.** Probe `.spades/config`:

   ```bash
   [ -f .spades/config ] && echo present || echo missing
   ```

   `present` → read `backend:` and `review_format:`. This is also
   the state when `/spades:setup` invokes this skill inline during
   bootstrap: setup writes the config before the call, with
   `project:` unset for Step 4 to fill.

   `missing` → abort: *"Run `/spades:setup` first — it configures the
   backend and, on the same pass, creates your first project."*
   Setup creates the project itself, so the human is never sent
   back here; the `setup → newproject` edge points one way.

## Step 1 — Gather

Ask the human for each of these in turn, conversationally rather
than as a form, and wait for the answer before moving on. A value
the request already supplies is reflected back for confirmation
rather than assumed:

- **Title** — *"Closed Door Security Website"*. The slug derives
  from it.
- **Description** — two or three sentences: what it is, why it
  exists, who owns it.
- **Repos** — the repository URLs that compose the project, at least
  one.
- **Owners** — email addresses or handles, at least one.

### Slug

1. Lowercase.
2. Replace runs outside `[a-z0-9-]` with a single hyphen.
3. Trim leading and trailing hyphens.
4. Truncate to 64 characters.
5. Reject an empty result, a leading hyphen, `..`, or a slug that
   matches an existing project file.

*"Closed Door Security Website"* → `closed-door-security-website`.
Confirm via `AskUserQuestion`: **Use this slug** / **Edit the slug**.

## Step 2 — Collision check

- **Local** — an existing `.spades/projects/<slug>.md` aborts:
  *"A project named `<slug>` already exists. Pick a different title
  or edit the existing project."*
- **Linear** (`backend: linear`) — an existing Linear Project of the
  same name → ask via `AskUserQuestion`: **Bind to the existing
  Linear Project** (recommended) / **Create a separate one** (with a
  differentiated name).

## Step 3 — Write and mirror (fan-out)

### The canonical `.md` (both modes)

```markdown
---
id: <slug>
title: "<title>"
description: "<description>"
repos:
  - <repo-url-1>
  - <repo-url-2>
owners:
  - <owner-1>
  - <owner-2>
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_project_id: <uuid>        # backend: linear, injected after the wave
---

# <title>

<description, expanded into prose if helpful>

## Repos

- <repo-url-1>
- <repo-url-2>

## Owners

- <owner-1>
- <owner-2>

## Scopes

<!-- /spades:list renders the live view; this section is not maintained by hand -->

## Audit Trail

- YYYY-MM-DD: Project created.
```

### `worker-html-project` (HTML mode)

- `open_path`: the absolute `output_path` for this skill’s initial review
  presentation; `null` for refreshes or background use, per
  `docs/FRAMEWORK.md § Review-page ownership`.
- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/newproject/template.html`
- `output_path`: `.spades/projects/<slug>.html`
- `frontmatter`: `{ id, title, description, status, created,
  updated }`, embedded verbatim in `<script id="spades-frontmatter">`
- `blocks`:
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`
  - `repos-items` — one per repo. Fields: `url, label`.
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

Per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`, in one
assistant message, `subagent_type: general-purpose`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-project` | `.spades/projects/<slug>.md`, written without `linear_project_id` | `{ status: ok }` |
| `worker-html-project` *(HTML mode)* | `.spades/projects/<slug>.html` | `{ status: ok, path, opened }` |
| `worker-linear-project` *(`backend: linear`)* | Linear — a Project with the title and description on `linear.team_id`. Carries the resolved worktree context per § Freshness. | `{ status: ok, linear_project_id }` |

With `backend: local` the wave has no Linear worker. After the wave:
all ok → inject `linear_project_id` into the `.md` (and the `.html`
frontmatter block), record the dispatch mode; file worker failed →
abort, noting a Linear Project may be orphaned; HTML worker failed →
keep the `.md`, surface, continue; Linear worker failed → keep the
local file, surface, offer a retry.

## Step 4 — Active project

Ask via `AskUserQuestion`: **Set as active project** (recommended)
/ **Leave the active project unchanged**. When invoked inline by
`/spades:setup` during bootstrap (`project:` unset), set it active
without asking and return to setup.

Setting active: replace or insert `project: <slug>` in
`.spades/config`, and with `backend: linear` likewise
`linear.project_id`.

## Step 5 — Confirm

```
✓ Project created: <slug>
✓ Title:           <title>
✓ Repos:           2
✓ Owners:          2
✓ Linear Project:  <id>    (backend: linear)
✓ Active project:  <slug>  (or: unchanged)

Next:
  /spades:scope <title>   — define your first Scope under this project
```

## Edge cases

- **No repo yet** — accept a placeholder such as `tbd` in `repos:`
  and say that `code` deliverables cannot ship until a real repo is
  recorded; re-run to update.
- **Owners outside the team** — accept the strings as given;
  identity is not validated.
- **Switching a repo to a different project** — `.spades/config`
  names one active project; the human re-runs `/spades:setup` to
  pick another.
