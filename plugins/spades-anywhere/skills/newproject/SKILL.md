---
name: newproject
description: Create a new SPADES Project record — the long-lived container above Scopes (a repo, a set of repos, a service). Use when starting a brand-new initiative, when someone says "new project", "create a project", "set up a project for X", or after /spades-anywhere:setup asks for an active project that doesn't exist yet. Writes .spades-anywhere/projects/<slug>.md and (when backend is Linear) creates the corresponding Linear Project.
version: 0.2.0
---

# /spades-anywhere:newproject

You are creating a new Project record. A Project is the long-lived
container above Scopes — typically a repo or set of repos that share an
identity (a service, a product surface, a marketing site).

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades-anywhere/ Local Layout before
running. The Project frontmatter schema below mirrors that contract.

### Output format

This skill honours `review_format:` from
`.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML) → Universal
rule`. In **both** modes, write the Project record as
`.spades-anywhere/projects/<slug>.md` — this is the AI-readable
source of truth and the canonical record. In HTML mode,
**additionally** render via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/newproject/template.html` and write
`.spades-anywhere/projects/<slug>.html` for the human's view,
then auto-open via the OPEN_CMD prelude. HTML mode is additive
— the `.md` always exists; the `.html` is added in HTML mode.

**HTML mode is review-via-file, not review-via-CLI.** Do NOT paste
the Project record body to the CLI for the human's approval before
Step 3 writes the file. The file IS the review surface. Step 3
writes a working draft and auto-opens it; the human reviews in the
browser. To iterate, apply targeted edits to the file (the human
reloads to see changes) — never re-paste a new full draft to the
CLI. In CLI mode the existing draft-then-paste workflow is fine.

## Pre-Flight

1. **Confirm setup has run.** If `.spades-anywhere/config` is missing, abort
   and suggest `/spades-anywhere:setup` first. Setup binds a backend; new
   project creation depends on knowing the backend.
2. **Read the backend** from `.spades-anywhere/config`'s `backend:` field. The
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

1. **Local check.** If `.spades-anywhere/projects/<slug>.md` already exists,
   abort with: *"A project named `<slug>` already exists. Pick a
   different title or edit the existing project."*
2. **Linear check** (only when `backend: linear`). Query the backend
   for an existing Linear Project with the same name. If one exists,
   ask the human whether to:
   - **Bind to the existing Linear Project** (recommended — reuses it)
   - **Create a separate Linear Project** (you'll be asked to pick a
     differentiated name)

## Step 3 — Create the Project

**Read `review_format:` from `.spades-anywhere/config` and branch on the file
format.** Step 3 MUST write a Project file before exiting — never
print the project record to the CLI only, **and never paste the
project body to the CLI for human approval before this step writes
the file in HTML mode**. The file IS the review surface in HTML
mode (see § Output format above).

### When `backend: local`

#### Step 3.A — Write the canonical `.md` (both modes)

Write `.spades-anywhere/projects/<slug>.md` with this exact shape:

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

<!-- /spades-anywhere:list will populate this on demand; do not maintain by hand -->
```

#### Step 3.B — Additionally render the HTML (HTML mode only)

When `review_format: html`, after the `.md` in Step 3.A is
written, render the HTML companion file. The `.md` is unchanged;
the `.html` is **additive**.


**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.** Validate the template exists and the named
blocks below match the markers in the actual file before
substituting; abort and surface any mismatch. See
`docs/FRAMEWORK.md § Output Format → HTML rendering: validate and
use the bundled template` for the canonical rule.

1. **Read the template** at
   `${CLAUDE_PLUGIN_ROOT}/skills/newproject/template.html`.
2. **Validate** it contains the block markers listed below; if any
   are missing, abort.
3. **Substitute placeholders** per `docs/FRAMEWORK.md § Output
   Format`:
   - `{{spades.id}}`, `{{spades.title}}`, `{{spades.description}}`,
     `{{spades.created}}`, `{{spades.updated}}`, `{{spades.status}}`
     (optional — the project's status; the template defaults it to
     `active`), and any additional fields the template requires.
   - The frontmatter YAML block also goes verbatim into the
     `<script type="application/yaml" id="spades-frontmatter">` tag.
   - `<!-- SPADES-BLOCK:objective-banner -->` — 0 or 1 item per
     `docs/FRAMEWORK.md § Objective banner`. Pass the project's
     sole `open` Objective `{{block.id}}`, `{{block.title}}` when
     EXACTLY ONE exists in `.spades-anywhere/objectives/`, else `[]`.
   - `<!-- SPADES-BLOCK:repos-items -->` — repeated once per repo.
     Per-item: `{{block.url}}`, `{{block.label}}`.
   - `<!-- SPADES-BLOCK:owners-items -->` — repeated once per
     owner. Per-item: `{{block.name}}`, `{{block.email|—}}`.
   - `<!-- SPADES-BLOCK:status-filters -->` — repeated once per
     status filter chip rendered in the Scopes section. Per-item:
     `{{block.label}}`, `{{block.count}}`.
   - `<!-- SPADES-BLOCK:scopes-rows -->` — repeated once per Scope
     row in the embedded Scopes table. Per-item: `{{block.id}}`,
     `{{block.title}}`, `{{block.status}}`, `{{block.plans}}`,
     `{{block.updated}}`.
   - `<!-- SPADES-BLOCK:audit-events -->` — repeated once per audit
     entry in both the visible timeline and the
     `<script type="application/yaml" id="spades-audit-trail">`
     YAML block. Per-item: `{{block.date}}`, `{{block.desc}}`.
4. **Write the rendered HTML** to `.spades-anywhere/projects/<slug>.html`.
5. **Auto-open** via the OPEN_CMD prelude
   (`docs/FRAMEWORK.md § OPEN_CMD detection prelude`). Print the file
   path with "open this in your browser" if `OPEN_CMD` is empty.
6. The `.md` from Step 3.A is unchanged — both files coexist.

### When `backend: linear` — fan-out dispatch

Apply the fan-out pattern from
`docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. Spawn the two
sub-agents below **in parallel in a single assistant message with
multiple `Agent` tool calls** (`subagent_type: general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-project` | `.spades-anywhere/projects/<slug>.<ext>` — the local project file in the format chosen by Step 3.A/3.B (CLI → `.md`, HTML → render from sibling `template.html` + auto-open). The file is written **without** `linear_project_id` — the coordinator injects it post-dispatch. | `{ status: ok }` (or `fail` + `error`) |
| `worker-linear-project` | Linear — create a Project with the given title and description on the team recorded in `.spades-anywhere/config`'s `linear.team_id`. | `{ status: ok, linear_project_id: <uuid> }` (or `fail`) |

The Linear sub-agent's prompt includes the Layer-2 freshness probe
(per `FRAMEWORK.md § Sub-agent Dispatch`). Each sub-agent's prompt
is self-contained and includes its scope, inputs, and return schema.

After both sub-agents return, the coordinator (this skill body)
collects results per the failure semantics in
`FRAMEWORK.md § Sub-agent Dispatch`:

- **Both ok** → targeted edit on the local project file to inject
  `linear_project_id: <uuid>` into the frontmatter (and into the
  embedded `<script type="application/yaml" id="spades-frontmatter">`
  block in HTML mode). Record the dispatch mode used.
- **File sub-agent failed** → abort; the Linear project may have
  been created but is orphaned. Surface clearly so the human can
  delete it from Linear or re-run.
- **Linear sub-agent failed** → keep the local file (canonical),
  surface the failure with the offer to retry the Linear mirror
  later.

The local file is the canonical SPADES record; the Linear Project is
the tracker mirror. Both should always exist when `backend: linear`.

## Step 4 — Update Active Project

Ask the human (via `AskUserQuestion`):

- **Set as active project** (recommended) — updates `.spades-anywhere/config`'s
  `project:` field to the new slug.
- **Leave active project unchanged** — keeps whatever was active.

If chosen "set as active":

1. Read `.spades-anywhere/config`.
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
  /spades-anywhere:scope <title>   — define your first Scope under this project
```

## Edge Cases

- **No repos yet.** If the human says the project doesn't have a repo
  yet, accept a placeholder like `tbd` in `repos:` and warn that
  `/spades-anywhere:ship` will not function for `deliverable_type: code` plans
  until at least one real repo is recorded. Suggest re-running
  `/spades-anywhere:newproject` to update.
- **Owners not on the human's team.** Accept email/handle strings as
  given; SPADES does not validate identity.
- **Re-binding a repo to a different project.** SPADES doesn't support
  this directly — `.spades-anywhere/config` names exactly one active project.
  If the human needs to switch, they re-run `/spades-anywhere:setup` and pick
  the other project there.
