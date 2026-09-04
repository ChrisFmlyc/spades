---
name: scope
description: Create or edit a SPADES Scope — the outcome record that everything downstream is measured against. Use when starting new work, when someone says "scope X", "create a scope", "edit a scope", or when work needs a written outcome and acceptance criteria. Fuzzy-matches existing scopes by slug or title to avoid duplicates; argument is the scope description.
version: 0.3.0
---

# /spades-anywhere:scope

You are creating or editing a Scope. A Scope is the contract that
everything downstream is measured against: the Plan is drafted from
it, Evaluate walks its acceptance criteria, and Ship confirms it
moved the project's intent forward. A weak Scope produces a weak
Plan.

Read `docs/FRAMEWORK.md` § ID Format, § .spades-anywhere/ Local
Layout, and § Output Format before running. The schema below
mirrors that contract.

### Output format

- **Both modes** — `.spades-anywhere/scopes/S-<slug>.md`, the
  canonical record every skill reads.
- **HTML mode** — additionally `.spades-anywhere/scopes/S-<slug>.html`,
  rendered from `${CLAUDE_PLUGIN_ROOT}/skills/scope/template.html`
  and auto-opened. The page is the human's review surface: Step 6
  writes the working draft, the human reviews in the browser, and
  iteration is a targeted `.md` edit followed by a re-render.
- **CLI mode** — the draft is pasted for review before Step 6
  writes it.

## Pre-Flight

1. **Confirm setup.** `.spades-anywhere/config` must exist;
   otherwise point at `/spades-anywhere:setup` and stop.
2. **Confirm the active project.** `project:` unset →
   `/spades-anywhere:newproject`.
3. **Read `backend:` and `review_format:`.**
4. **Verify the Project is active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`; an `abandoned` or
   `archived` Project is a hard abort. In Edit mode, re-check after
   Step 2 resolves the target.
5. **INTENT gate.** A Scope is measured against `INTENT.md`. Probe
   for it; when missing, ask via `AskUserQuestion`:
   - **Exit and run `/spades-anywhere:intent` first**
     *(Recommended)* — print *"INTENT.md is missing. Run
     `/spades-anywhere:intent` to compose it, then re-run
     `/spades-anywhere:scope`."* and stop.
   - **Proceed without INTENT** — for throwaway or sandbox projects.
     Step 6 records `- YYYY-MM-DD: Scope created without INTENT.md
     (override).` in the audit trail.

## Step 1 — Fast-track check

Walk the ten fast-track criteria in `/spades-anywhere:quick`
§ The gate. If every one passes, offer the quick path:

> This looks like fast-track work — it meets every gate criterion.
> Want me to run `/spades-anywhere:quick` and skip the full scope
> flow?

Continue here when any criterion fails or the human prefers the
full loop.

## Step 2 — Mode

- **Create** (default).
- **Edit** — when the input names an `S-<slug>` ID, a slug, or a
  title that fuzzy-matches an existing Scope.

Fuzzy match via `list_scopes(filter)` for the active project: score
slug substring, title token overlap, and ID prefix; offer up to
three candidates via `AskUserQuestion` (**Edit `S-<slug>`
(<title>)** …) plus **Create a new scope**; with no close candidate,
go straight to Create.

## Step 3 — Slug (Create mode)

Lowercase; runs outside `[a-z0-9-]` to a single hyphen; trim;
truncate to 64 characters after `S-`; reject empty, a leading
hyphen, or `..`. *"Plan the birthday party"* →
`S-plan-the-birthday-party`. Confirm via `AskUserQuestion`: **Use
this ID** / **Edit the slug**. An existing file switches to Edit.

## Step 4 — Conversation, one field at a time

Scope content is composition, so it stays free-form. Ask one field,
wait, reflect back, then move on. Probe vague answers for
verifiable detail, propose stronger wording for weak criteria, and
flag a Scope too large to plan in one session.

### 1. Statement of Intent
What is achieved and why it matters — outcome, not activity. One to
three sentences.

✓ *"Forty guests have a memorable evening and the venue, food, and
photos are settled a week ahead."*
✗ *"Organise the party."*

### 2. Acceptance Criteria
Specific, verifiable conditions for done; 3–7 checkboxes.

✓ *"Venue booked and deposit paid by 1 June, confirmation email
filed."*
✗ *"Venue sorted."*

### 3. Constraints
Budget, schedule, stakeholders, tools — referencing
`ARCHITECTURE.md` and `PATTERNS.md` where they apply, or the
explicit *"No additional constraints beyond ARCHITECTURE.md"*.

### 4. Dependencies
Other Scopes, people, bookings, or access that must be in place, or
*"None"*.

### 5. Context
Upstream, downstream, related.

### 6. Out of Scope
What this Scope explicitly excludes; always filled.

### 7. Risk / Unknowns
Known landmines, or *"None identified"*.

### 8. Delivery Preference — `AskUserQuestion`
- **Human-delivered** — the human does all the work
- **Hybrid** — the AI assists on drafts, research, or structure for
  named tasks

### 9. Priority — `AskUserQuestion`
`urgent` · `high` · `this-cycle` · `medium` · `low` · `backlog` ·
`exploratory`.

### 10. Type — `AskUserQuestion`
`feature` · `bug` · `chore` · `docs` · `refactor` · `investigation`.

### 11. Strategy link (optional)
Ask once whether the Scope traces to a roadmap item, OKR, or
Objective (`O-<slug>`). Record a supplied reference verbatim as
`strategy_link:`; for reactive or ad-hoc work, omit it and let
`origin:` carry the rationale.

## Step 5 — Quality check

- [ ] Someone could start planning without a follow-up conversation.
- [ ] Acceptance criteria are specific and verifiable by a human.
- [ ] The Scope fits one planning session.
- [ ] Constraints, dependencies, and risks are explicit or
      explicitly "none".
- [ ] Out of Scope is filled.

## Step 6 — Write the Scope

CLI mode pastes the assembled draft and writes on approval; HTML
mode writes the draft and lets the rendered page carry the review.

### The canonical `.md` (both modes)

Path: `.spades-anywhere/scopes/S-<description-slug>.md`

```yaml
---
id: S-<slug>
title: "<title>"
project: <active-project-slug>
status: scoped
type: feature | bug | chore | docs | refactor | investigation
priority: urgent | high | this-cycle | medium | low | backlog | exploratory
origin: okr | reactive | ad-hoc
strategy_link: <URL | ID | O-slug>   # only when supplied
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_issue_id: <id>                # backend: linear, injected in Step 7
---
```

```markdown
# <title>

## Statement of Intent

<one to three sentences>

## Acceptance Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>

## Constraints

<budget / schedule / stakeholders / tools, or the explicit "none">

## Dependencies

<list, or "None">

## Context

- **Upstream:** <…>
- **Downstream:** <…>
- **Related:** <…>

## Out of Scope

- <thing 1>

## Risk / Unknowns

- <risk 1, or "None identified">

## Delivery Preference

<human / hybrid, with notes on which tasks>

## Audit Trail

<!-- Appended by /spades-anywhere:plan, approve, evaluate, ship, close. -->
```

### The `.html` (HTML mode)

Rendered from `${CLAUDE_PLUGIN_ROOT}/skills/scope/template.html` to
`.spades-anywhere/scopes/S-<slug>.html` per `docs/FRAMEWORK.md §
Output Format → HTML rendering`: validate the template and the
markers, substitute, write, open.

- `frontmatter`: `{ id, title, status, project, type, priority,
  origin, created, updated }`, also embedded verbatim in
  `<script id="spades-frontmatter">`
- `criteria_count` *(scalar)*: number of acceptance criteria
- `blocks`:
  - `acceptance-items` — one per criterion. Fields: `text, checked`.
  - `objective-banner` — 0 or 1 item `{ id, title }` per
    `docs/FRAMEWORK.md § Objective banner`, from this Scope's
    `strategy_link` when it names an existing
    `.spades-anywhere/objectives/O-<slug>.md`; else `[]`.
  - `dependencies-items` — one per Dependencies bullet. Field: `text`.
  - `out-of-scope-items` — one per Out of Scope bullet. Field: `text`.
  - `audit-events` — one per audit entry. Fields: `date, desc`.
- `prose_sections`: `{ statement_of_intent_html, constraints_html,
  context_html, risk_unknowns_html, delivery_preference_html }`

Required markers: `acceptance-items`, `dependencies-items`,
`out-of-scope-items`, `audit-events`.

## Step 7 — Write and mirror (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`,
every sub-agent in a single message, `subagent_type:
general-purpose`; in `degraded` mode the coordinator does each in
turn:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-scope` | `.spades-anywhere/scopes/S-<slug>.md`, without `linear_issue_id:` | `{ status: ok }` |
| `worker-html-scope` *(HTML mode)* | `.spades-anywhere/scopes/S-<slug>.html` | `{ status: ok, path, opened }` |
| `worker-linear-scope` *(`backend: linear`)* | Linear — a parent Issue on the active Linear Project with the Scope's title and body, workflow state for `scoped`. | `{ status: ok, linear_issue_id }` |

With `backend: local` there is no Linear worker. After the wave:
all ok → inject `linear_issue_id` into the `.md` (and the `.html`
frontmatter block), record the dispatch mode; file worker failed →
abort, noting a Linear Issue may be orphaned; HTML worker failed →
keep the `.md`, surface, continue; Linear worker failed → keep the
local file, surface, offer a retry.

## Step 8 — Confirm

```
✓ Scope created: S-plan-the-birthday-party
✓ Title:         Plan the birthday party
✓ Project:       family-events
✓ Status:        scoped
✓ Linear Issue:  M-1234   (backend: linear)

Next:
  /spades-anywhere:plan S-plan-the-birthday-party     — break this scope into plans
  /spades-anywhere:review S-plan-the-birthday-party   — optional second opinion
```

The second-opinion suggestion is a pointer; this skill invokes no
other skill.

## Edit mode

1. Read the `.md`.
2. Show the current content; highlight weak or missing fields.
3. Walk the gaps one field at a time.
4. Write back, preserving `id:` and `created:`, setting `updated:`
   to today, appending `- YYYY-MM-DD: Scope edited — <fields>.` In
   HTML mode, re-render the `.html`.
5. With `backend: linear` and a `linear_issue_id:`, push the updated
   description to Linear.

Where edits conflict with existing content, ask before replacing.
