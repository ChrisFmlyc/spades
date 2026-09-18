---
name: newproject
description: Creates a new SPADES Project record — the long-lived container above Scopes (a repo, a set of repos, a service). Use when starting a brand-new initiative, when someone says "new project", "create a project", "set up a project for X", or after /spades:setup asks for an active project that doesn't exist yet. Writes .spades/projects/<slug>.md and (when backend is Linear) creates the corresponding Linear Project.
version: 3.7.1
---

# /spades:newproject

You are creating a Project record — the long-lived container above
Scopes, typically a repo or set of repos sharing one identity (a
service, a product surface, a marketing site).

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades/ Local Layout,
§ Bootstrap Order, § Project lead assignment, and § Output Format before
running.

### Output format

- **Both modes** — `.spades/projects/<slug>.md`, the canonical
  record.
- **HTML mode** — additionally `.spades/projects/<slug>.html` from
  `${CLAUDE_PLUGIN_ROOT}/skills/newproject/template.html` via
  `worker-html-project`, auto-opened as the review surface;
  iteration is a targeted `.md` edit plus a re-render.
- **CLI mode** — the record is presented in the CLI review pane (`docs/FRAMEWORK.md § CLI review pane`) on the confirmation
  question before the write.

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
   Setup calls this skill inline after writing the config, per
   § Bootstrap Order.

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
  updated, repos, owners }`, plus optional `linear_project_id`, `lead`,
  `linear_lead_id` when present in the canonical record. Replace the entire
  `<script id="spades-frontmatter">` contents with that record's YAML;
  omit absent optional fields. Serialize strings as YAML scalars, preserving
  their values when parsed. Inside the script's raw-text context use YAML
  double-quoted escapes for `<`, `>`, `&` and literal placeholder braces
  (for example `\u003c`, `\u007b`), rather than HTML entities, so identity
  text cannot close the script or become a template token.
- `scalars`: the parsed Project fields and existing computed template
  values; optional `lead` is the canonical `lead` string. With no `lead`,
  the visible property uses the template's **Unassigned** fallback.
  HTML-escape visible user strings, including `lead`; encode literal token
  braces per § Placeholder substitution and output validation. Owners keep
  their own block and meaning.
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
local file, surface, offer a retry. Track whether the new record and its
Linear binding are ready; a failed or deferred Linear operation leaves lead
assignment unavailable until the binding succeeds. Report that state without
claiming a Linear Project was created or a lead assigned.

## Step 4 — Active project

Ask via `AskUserQuestion`: **Set as active project** (recommended)
/ **Leave the active project unchanged**. When invoked inline by
`/spades:setup` during bootstrap (`project:` unset), set it active
without asking, then continue through the optional lead step and confirmation
before returning to Setup.

Setting active: replace or insert `project: <slug>` in
`.spades/config`, and with `backend: linear` likewise
`linear.project_id` when binding succeeded. If setting this Project active
while its Linear binding is still pending or failed, remove any previous
`linear.project_id` so config cannot associate it with another Linear Project.
Leaving the active project unchanged preserves both config fields. Keep the
newly created `<slug>` as the handoff target independently of this choice.

## Step 5 — Optional project lead

After the canonical `.spades/projects/<slug>.md` exists, and its
`linear_project_id` has been resolved and persisted when `backend: linear`,
ask once via `AskUserQuestion`: *"Add a project lead?"* — **Yes** / **No**.
An identity supplied in the creation request is retained for the Yes path;
`owners` do not imply a lead.

- **Yes** — invoke `/spades:projectlead --project <slug>` inline for this
  newly created Project. Pass any supplied name or email as the optional
  person argument; otherwise let Projectlead ask for it. Pass the explicit
  slug even when this Project was made active. Preserve arguments as data
  when invoking the skill. Projectlead owns identity lookup, confirmation,
  assignment, persistence and failure recovery under the shared contract.
- **No**, dismissal or cancellation — skip assignment and continue normally.
  A cancellation inside Projectlead likewise returns here without changing
  the active-project choice or treating project creation as failed.

The helper inherits this task's review-page context. Its HTML refresh uses
`skills/newproject/template.html` and the payload above with `open_path: null`
for the already-presented Project. Re-read the canonical Project after the
helper returns so the confirmation and page reflect the persisted result.
Report an incomplete or failed assignment as returned by Projectlead; project
creation remains complete, and retrying uses the same explicit Project slug.

If the local record or required Linear binding is missing, retain Step 3's
failure/retry result and skip this optional handoff. The helper requires those
prerequisites and never invokes Newproject or Setup to recreate them.

## Step 6 — Confirm

```
✓ Project created: <slug>
✓ Title:           <title>
✓ Repos:           2
✓ Owners:          2
✓ Project lead:    <canonical lead, or Unassigned>
✓ Linear Project:  <id>    (backend: linear)
✓ Active project:  <slug>  (or: unchanged)

Next:
  /spades:scope <title>   — define your first Scope under this project
```

For a Setup bootstrap invocation, return to Setup now, after the optional
lead flow completes, is skipped or is cancelled. For standalone use, show
the next Scope command. Include the Linear success line only for a confirmed
binding. For a partial or failed assignment, replace the lead success line
with the helper's outcome, distinguish the persisted local lead from any
confirmed remote change, and give the explicit-target retry command. Report
pending binding accurately; it remains a prerequisite for the optional offer.

## Edge cases

- **No repo yet** — accept a placeholder such as `tbd` in `repos:`
  and say that `code` deliverables cannot ship until a real repo is
  recorded; re-run to update.
- **Owners outside the team** — accept the strings as given;
  identity is not validated.
- **Switching a repo to a different project** — `.spades/config`
  names one active project; the human re-runs `/spades:setup` to
  pick another.
