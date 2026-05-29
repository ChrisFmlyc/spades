---
name: newproject
description: Create a new SPADES Project record — the long-lived container above Scopes (a repo, a set of repos, a service). Use when starting a brand-new initiative, when someone says "new project", "create a project", "set up a project for X", or after /spades:setup asks for an active project that doesn't exist yet. Writes .spades/projects/<slug>.md and (when backend is Linear) creates the corresponding Linear Project.
version: 2.0.0
---

# /spades:newproject

You are creating a new Project record. A Project is the long-lived
container above Scopes — typically a repo or set of repos that share an
identity (a service, a product surface, a marketing site).

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades/ Local Layout before
running. The Project frontmatter schema below mirrors that contract.

## Pre-Flight

1. **Confirm setup has run.** If `.spades/config` is missing, abort
   and suggest `/spades:setup` first. Setup binds a backend; new
   project creation depends on knowing the backend.
2. **Read the backend** from `.spades/config`'s `backend:` field. The
   branches below act according to that value.

## Step 1 — Gather Project Information

Ask the human (conversationally, not as a form) for:

- **Title** — human-readable name. e.g. *"Closed Door Security Website"*.
  Derive the slug from this via the rule below.
- **Description** — 2–3 sentences. What is this project? Why does it
  exist? Who owns it?
- **Repos** — list of repository URLs that compose the project. At
  least one. Multiple is fine.
- **Owners** — list of email addresses or handles. At least one.

### Slug derivation

The slug is the project's stable ID. Derive it from the title:

1. Lowercase the whole thing.
2. Replace spaces and any non-`[a-z0-9-]` runs with single hyphens.
3. Trim leading and trailing hyphens.
4. Truncate to 64 characters.
5. Reject if the result is empty, starts with a hyphen, contains `..`,
   or matches an existing project file.

Example: *"Closed Door Security Website"* → `closed-door-security-website`.

Show the derived slug to the human and ask (via `AskUserQuestion`):

- **Use this slug** (recommended)
- **Edit the slug** (free-form fallback for unusual cases)

## Step 2 — Collision Check

Before writing anything:

1. **Local check.** If `.spades/projects/<slug>.md` already exists,
   abort with: *"A project named `<slug>` already exists. Pick a
   different title or edit the existing project."*
2. **Linear check** (only when `backend: linear`). Query the backend
   for an existing Linear Project with the same name. If one exists,
   ask the human whether to:
   - **Bind to the existing Linear Project** (recommended — reuses it)
   - **Create a separate Linear Project** (you'll be asked to pick a
     differentiated name)

## Step 3 — Create the Project

### When `backend: local`

Write `.spades/projects/<slug>.md` with this exact shape:

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
created: YYYY-MM-DD
updated: YYYY-MM-DD
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

<!-- /spades:list will populate this on demand; do not maintain by hand -->
```

### When `backend: linear`

1. Create a Linear Project with the given title and description, on
   the team recorded in `.spades/config`'s `linear.team_id`.
2. Capture the new Linear Project ID.
3. Write the local `.spades/projects/<slug>.md` file as above, with an
   extra `linear_project_id: <uuid>` frontmatter field.

The local file is the canonical SPADES record; the Linear Project is
the tracker mirror. Both should always exist when `backend: linear`.

## Step 4 — Update Active Project

Ask the human (via `AskUserQuestion`):

- **Set as active project** (recommended) — updates `.spades/config`'s
  `project:` field to the new slug.
- **Leave active project unchanged** — keeps whatever was active.

If chosen "set as active":

1. Read `.spades/config`.
2. Replace the `project:` line with `project: <new-slug>`.
3. When `backend: linear`, also update the `linear.project_id` line
   with the new Linear Project ID.

## Step 5 — Confirm

Print a short summary:

```
✓ Project created: <slug>
✓ Title:           <title>
✓ Repos:           2
✓ Owners:          2
✓ Linear Project:  <id>    (only when backend: linear)
✓ Active project:  <slug>  (or: unchanged)

Next:
  /spades:scope <title>   — define your first Scope under this project
```

## Edge Cases

- **No repos yet.** If the human says the project doesn't have a repo
  yet, accept a placeholder like `tbd` in `repos:` and warn that
  `/spades:ship` will not function for `deliverable_type: code` plans
  until at least one real repo is recorded. Suggest re-running
  `/spades:newproject` to update.
- **Owners not on the human's team.** Accept email/handle strings as
  given; SPADES does not validate identity.
- **Re-binding a repo to a different project.** SPADES doesn't support
  this directly — `.spades/config` names exactly one active project.
  If the human needs to switch, they re-run `/spades:setup` and pick
  the other project there.
