---
name: objective
description: Create or edit a spades-anywhere Objective — a coherent strategic action associated with a project (Rumelt/OKR sense), prefixed O-. Use when someone says "create an objective", "set an objective", "add an objective", "new objective", "add a milestone for this project", or "/spades-anywhere:objective <description>". An Objective is independent of Scopes — it never contains, requires, or gates on one. Closing an Objective is done via /spades-anywhere:close O-<slug>.
version: 1.2.0
---

# /spades-anywhere:objective

You are creating or editing an **Objective** — a coherent strategic
action associated with a project, in the *Good Strategy / Bad
Strategy* sense and close to the Objective in OKRs. It is the
in-SPADES anchor that records *"this project has this strategic
objective."*

An Objective is independent of Scopes: it never contains, requires,
or gates on one, and it does not run the six-phase loop. Its record
is minimal — a title, a 2–4 sentence description, an optional
strategy link — with no acceptance criteria, dates, owners, or
priority. Completing or abandoning one is `/spades-anywhere:close
O-<slug>`.

Read `docs/FRAMEWORK.md` § Hierarchy → Objectives, § ID Format,
§ .spades-anywhere/ Local Layout, and § Output Format before running.

### Output format

- **Both modes** — `.spades-anywhere/objectives/O-<slug>.md`, the
  canonical record.
- **HTML mode** — additionally
  `.spades-anywhere/objectives/O-<slug>.html` from
  `${CLAUDE_PLUGIN_ROOT}/skills/objective/template.html`,
  auto-opened as the review surface; iteration is a targeted `.md`
  edit plus a re-render.
- **CLI mode** — the record is pasted for confirmation before the
  write.

## Pre-Flight

1. **Confirm setup and active project.** Missing config →
   `/spades-anywhere:setup`; missing `project:` →
   `/spades-anywhere:newproject`.
2. **Read `backend:` and `review_format:`.**
3. **Verify the Project is active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`; an `abandoned` or
   `archived` Project is a hard abort for create and edit.
4. **INTENT is a soft nudge here** — an Objective is itself a
   strategy-level statement.

## Step 1 — Mode

**Create** (default), or **Edit** when the input names an
`O-<slug>` ID, a slug, or a fuzzy-matching title. Fuzzy match via
`list_objectives(filter)`; offer up to three candidates via
`AskUserQuestion` plus **Create a new objective**.

## Step 2 — Slug (Create mode)

Same rule as Scopes, prefixed `O-`. *"Q3 Trust Launch"* →
`O-q3-trust-launch`. Confirm via `AskUserQuestion`: **Use this ID**
/ **Edit the slug**. An existing file switches to Edit. With
`backend: linear`, an existing milestone of the same name → **Bind
to the existing milestone** (recommended) / **Create a separate
one**.

## Step 3 — Gather

- **Title.**
- **Objective** — 2–4 sentences describing the coherent strategic
  action or outcome; push for a coherent action rather than a
  vague aspiration or a task list, and reflect it back.
- **Strategy link** (optional) — a URL, ID, or reference upstream.
  "None" is fine.

## Step 4 — Write and mirror

### The canonical `.md` (both modes)

```markdown
---
id: O-<slug>
title: "<title>"
project: <active-project-slug>
status: open
strategy_link: <ref or empty>
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_milestone_id: <id>       # backend: linear, injected after the wave
linear_issue_id: <id>           # backend: linear, injected after the wave
---

# <title>

## Objective

<the 2–4 sentence description>

## Audit Trail

- YYYY-MM-DD: Objective created.
```

Edit mode applies targeted edits — the body and/or
`strategy_link:`, `updated:` today, `- YYYY-MM-DD: Objective
edited.` — leaving `status:` to `/spades-anywhere:close`.

### The `.html` (HTML mode)

Rendered from `${CLAUDE_PLUGIN_ROOT}/skills/objective/template.html`
to `.spades-anywhere/objectives/O-<slug>.html` per
`docs/FRAMEWORK.md § Output Format → HTML rendering`. The page is
the objective, so it carries no `objective-banner`.

- `frontmatter`: `{ id, title, project, status, strategy_link,
  created, updated }`, embedded verbatim
- `linked_count` *(scalar)*: the number of `linked-scopes`
- `blocks`:
  - `linked-scopes` — one per Scope in `.spades-anywhere/scopes/*.md`
    whose `strategy_link` equals `O-<slug>`. Fields: `id, title,
    status`.
  - `audit-events` — one per audit entry. Fields: `date, desc`.

Required markers: `linked-scopes`, `audit-events`.

### The wave

Per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-objective` | `.spades-anywhere/objectives/O-<slug>.md`, without the Linear IDs | `{ status: ok }` |
| `worker-html-objective` *(HTML mode)* | `.spades-anywhere/objectives/O-<slug>.html` | `{ status: ok, path, opened }` |
| `worker-linear-objective` *(`backend: linear`)* | Linear — both objects: **(1)** `save_milestone(project: <linear.project_id>, name: "O-<slug>", description: <text>)`; **(2)** `save_issue(team: <linear.team_id>, project: <linear.project_id>, title: "O-<slug> — <title>", description: <text>, milestone: "O-<slug>")`, the sister tracking issue whose Done state is the completion signal | `{ status: ok, linear_milestone_id, linear_issue_id }` |

After the wave: all ok → inject both IDs into the `.md` (and
`.html`), record the dispatch mode; file failed → abort, noting
possible orphans; HTML failed → keep the `.md`, continue; Linear
failed → keep the local file, offer a retry, and say explicitly when
the milestone exists without its sister issue.

## Step 5 — Confirm

```
✓ Objective created: O-<slug>          (or "updated")
✓ Title:             <title>
✓ Project:           <project-slug>
✓ Strategy link:     <ref or "—">
✓ Linear milestone:  O-<slug>          (backend: linear)
✓ Linear issue:      <id> (sister O-)  (backend: linear)
✓ Status:            open

Next:
  /spades-anywhere:close O-<slug>   — mark complete when the team lead
                                      judges it reached (or --abandon)
```

## Edge cases

- **The description reads like a task** — push back; deliverable
  work is a Scope.
- **The human wants to attach Scopes** — a Scope records its
  contribution by setting its own `strategy_link:` to `O-<slug>`
  via `/spades-anywhere:scope` (Edit mode); the link is documentary.
- **A milestone exists without its sister issue** — in Edit mode,
  offer to create the missing sister issue.
