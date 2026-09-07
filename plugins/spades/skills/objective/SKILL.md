---
name: objective
description: Create or edit a SPADES Objective — a coherent strategic action associated with a project (Rumelt/OKR sense), prefixed O-. Use when someone says "create an objective", "set an objective", "add an objective", "new objective", "add a milestone for this project", or "/spades:objective <description>". An Objective is independent of Scopes — it never contains, requires, or gates on one. Closing an Objective is done via /spades:close O-<slug>.
version: 1.3.2
---

# /spades:objective

You are creating or editing an **Objective** — a coherent strategic
action associated with a project, in the *Good Strategy / Bad
Strategy* sense and close to the Objective in OKRs. It is the
in-SPADES anchor that records *"this project has this strategic
objective."*

An Objective is independent of Scopes: it never contains, requires,
or gates on one, and it does not run the six-phase loop. Its record
is minimal — a title, a 2–4 sentence description, an optional
strategy link — with no acceptance criteria, dates, owners, or
priority; those live upstream. Completing or abandoning one is
`/spades:close O-<slug>`.

Read `docs/FRAMEWORK.md` § Hierarchy → Objectives, § ID Format,
§ .spades/ Local Layout, and § Output Format before running.

### Output format

- **Both modes** — `.spades/objectives/O-<slug>.md`, the canonical
  record.
- **HTML mode** — additionally `.spades/objectives/O-<slug>.html`
  from `${CLAUDE_PLUGIN_ROOT}/skills/objective/template.html` via
  `worker-html-objective`, auto-opened as the review surface;
  iteration is a targeted `.md` edit plus a re-render.
- **CLI mode** — the record is pasted for confirmation before the
  write.

## Pre-Flight

1. **Confirm setup and active project.** Missing config →
   `/spades:setup`; missing `project:` → `/spades:newproject`.
2. **Read `backend:` and `review_format:`.**
3. **Verify the Project is active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`; an `abandoned` or
   `archived` Project is a hard abort for create and edit. (Closing
   an Objective is exempt.)
4. **INTENT is a soft nudge here.** An Objective is itself a
   strategy-level statement, so a missing `INTENT.md` is mentioned
   and the skill proceeds.

## Step 1 — Mode

- **Create** (default).
- **Edit** — when the input names an `O-<slug>` ID, a slug, or a
  title that fuzzy-matches an existing Objective.

Fuzzy match via `list_objectives(filter)` for the active project:
score slug substring, title token overlap, and ID prefix; offer up
to three candidates via `AskUserQuestion` (**Edit `O-<slug>`
(<title>)** …) plus **Create a new objective**; with no close
candidate, go straight to Create.

## Step 2 — Slug (Create mode)

Same rule as Scopes: lowercase; runs outside `[a-z0-9-]` to a single
hyphen; trim; truncate to 64 characters after `O-`; reject empty, a
leading hyphen, or `..`. *"Q3 Trust Launch"* → `O-q3-trust-launch`.
Confirm via `AskUserQuestion`: **Use this ID** / **Edit the slug**.

An existing `.spades/objectives/O-<slug>.md` switches to Edit. With
`backend: linear`, an existing milestone of the same name → ask:
**Bind to the existing milestone** (recommended) / **Create a
separate one** (with a differentiated name).

## Step 3 — Gather

**Ask for the strategy reference first, after confirming the slug and before
writing any local or Linear records.** Ask: *"Which roadmap outcome or strategy
item does this Objective support? Paste its link or ID. For Horizon, copy the
outcome's ULID from its drawer, or paste a link containing that ULID."* Wait
for the answer. If already supplied, reflect the reference back for confirmation.
In Edit mode, show the stored reference and ask whether to retain or replace it;
a missing reference takes the same prompt as Create.

For a Horizon binding, require exactly one distinct 26-character ULID matching
`[0-7][0-9A-HJKMNP-TV-Z]{25}` (case-insensitive, with alphanumeric boundaries)
in the answer. Store the extracted, uppercased ULID as `strategy_link`. A generic
Horizon URL, an `O-` slug, or a hyphenated Linear UUID does not identify a Horizon
outcome: explain this and ask for its ULID. Use an accessible roadmap to verify
the ID and show its outcome title; if unavailable, ask the human to confirm the
ID copied from that outcome. Resolve conflicting IDs before writing.

For objectives outside Horizon, retain the supplied URL, ID or reference as
`strategy_link`. An explicit "None" leaves it empty and means no roadmap binding;
optional refers to the value, never to skipping the question. A Horizon-linking
request needs its outcome ULID unless the human explicitly changes the intent
to creating an unbound Objective.

Then gather any remaining content conversationally:

- **Title.**
- **Objective** — 2–4 sentences describing the coherent strategic
  action or outcome. Push for a coherent action rather than a vague
  aspiration or a task list, and reflect it back.

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

Edit mode applies targeted edits — the `## Objective` body and/or
`strategy_link:`, `updated:` today, and `- YYYY-MM-DD: Objective
edited.` — leaving `status:` to `/spades:close`.

### `worker-html-objective` (HTML mode)

The page is the objective, so it carries no `objective-banner`.

- `open_path`: the absolute `output_path` for this skill’s initial review
  presentation; `null` for refreshes or background use, per
  `docs/FRAMEWORK.md § Review-page ownership`.
- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/objective/template.html`
- `output_path`: `.spades/objectives/O-<slug>.html`
- `frontmatter`: `{ id, title, project, status, strategy_link,
  created, updated }`, embedded verbatim in
  `<script id="spades-frontmatter">`
- `linked_count` *(scalar)*: the number of `linked-scopes`
- `blocks`:
  - `linked-scopes` — one per Scope in `.spades/scopes/*.md` whose
    `strategy_link` equals `O-<slug>`. Fields: `id, title, status`.
  - `audit-events` — one per audit entry. Fields: `date, desc`.

Required markers: `linked-scopes`, `audit-events`.

### The wave

Per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`, in one
assistant message, `subagent_type: general-purpose`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-objective` | `.spades/objectives/O-<slug>.md`, written without the Linear IDs | `{ status: ok }` |
| `worker-html-objective` *(HTML mode)* | `.spades/objectives/O-<slug>.html` | `{ status: ok, path, opened }` |
| `worker-linear-objective` *(`backend: linear`)* | Linear — three objects: **(1)** `save_milestone(project: <linear.project_id>, name: "O-<slug>", description: <objective text>)`; **(2)** `save_issue(team: <linear.team_id>, project: <linear.project_id>, title: "O-<slug> — <title>", description: <objective text>, milestone: "O-<slug>")`, the sister tracking issue whose Done state is the Objective's completion signal; **(3)** the outcome label: ensure a workspace-level label group named `outcome` exists (`issueLabelCreate` with no `teamId`; idempotent — reuse it when found), then `issueLabelCreate(name: "O-<slug>", parentId: <group id>, description: <strategy_link, or the title when empty>)`. Label groups are exclusive, so a Scope can carry at most one outcome. `/spades:close` applies this label to a Scope's parent Issue at roll-up; nothing applies it at creation. Carries the resolved worktree context per § Freshness. | `{ status: ok, linear_milestone_id, linear_issue_id, linear_label_id }` |

For Linear edits, reuse the recorded label ID (or its match under `outcome`)
and update its description; create it only when absent. Read back the label
and check its description contains the confirmed Horizon ULID before reporting
the reference saved. Horizon reads ULIDs from the milestone, then sister issue,
then label description: surface any conflicting IDs or read-back failure.
Report the saved reference separately from whether Horizon has synced it.

With `backend: local` the file is the whole Objective. After the
wave: all ok → inject the three Linear IDs into the `.md` (and the
`.html` frontmatter block), record the dispatch mode; file worker
failed → abort, noting Linear objects may be orphaned; HTML worker
failed → keep the `.md`, surface, continue; Linear worker failed →
keep the local file, surface, offer a retry, and say explicitly when
the milestone exists without its sister issue.

## Step 5 — Confirm

```
✓ Objective created: O-<slug>          (or "updated")
✓ Title:             <title>
✓ Project:           <project-slug>
✓ Strategy link:     <ref or "—">
✓ Linear milestone:  O-<slug>          (backend: linear)
✓ Linear issue:      <id> (sister O-)  (backend: linear)
✓ Linear label:      outcome/O-<slug>  (backend: linear)
✓ Status:            open

Next:
  /spades:close O-<slug>   — mark complete when the team lead judges
                             the objective reached (or --abandon)
```

## Edge cases

- **The description reads like a task.** Push back: an Objective is
  a strategic action or outcome. Deliverable work is a Scope.
- **The human wants to attach Scopes.** There is no attachment at
  creation. A Scope records the Objective it delivered against once,
  at `/spades:close` (Scope roll-up), which writes `strategy_link:
  O-<slug>` locally and applies the `outcome/O-<slug>` label to the
  parent Issue in Linear.
- **A milestone exists without its sister issue** (a partial run).
  In Edit mode, offer to create the missing sister issue.
