---
name: scope
description: Create or edit a SPADES Scope — the outcome record that everything downstream is measured against. Use when starting new work, when someone says "scope X", "create a scope", "edit a scope", or when work needs a written outcome and acceptance criteria. Fuzzy-matches existing scopes by slug or title to avoid duplicates; argument is the scope description.
version: 3.5.0
---

# /spades:scope

You are creating or editing a Scope. A Scope is the contract that
everything downstream is measured against: the Plan is drafted from
it, Evaluate verifies against its acceptance criteria, and Ship is
the moment it becomes real. A weak Scope produces a weak Plan.

Read `docs/FRAMEWORK.md` § ID Format, § .spades/ Local Layout, and
§ Output Format before running. The schema below mirrors that
contract.

### Output format

This skill produces one artefact per `docs/FRAMEWORK.md § Output
Format`:

- **Both modes** — `.spades/scopes/S-<slug>.md`, the canonical
  record every skill and sub-agent reads.
- **HTML mode** — additionally `.spades/scopes/S-<slug>.html`,
  rendered from `${CLAUDE_PLUGIN_ROOT}/skills/scope/template.html`
  by `worker-html-scope` and auto-opened. The open page is the
  human's review surface: Step 6 writes the working draft, the
  human reviews it in the browser, and iteration is a targeted edit
  to the `.md` followed by a re-render.
- **CLI mode** — the draft is pasted to the terminal for review
  before Step 6 writes it.

## Pre-Flight

1. **Confirm setup.** `.spades/config` must exist; otherwise point
   at `/spades:setup` and stop.
2. **Confirm the active project.** Read `project:` from
   `.spades/config`; if unset, point at `/spades:newproject` and stop.
3. **Read `backend:` and `review_format:`** from `.spades/config`.
4. **Verify the Project is active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`. An `abandoned` or
   `archived` Project is a hard abort with the canonical error
   shape. In Edit mode, re-check after Step 2 resolves the target.
5. **INTENT gate.** A Scope is measured against `INTENT.md`, the
   durable statement of why the project exists. Probe:

   ```bash
   [ -f INTENT.md ] && echo present || echo missing
   ```

   `present` → continue. `missing` → ask via `AskUserQuestion`:

   - **Exit and run `/spades:intent` first** *(Recommended)* — print
     *"INTENT.md is missing. Run `/spades:intent` to compose it,
     then re-run `/spades:scope`."* and stop.
   - **Proceed without INTENT** — for throwaway or prototype repos.
     Step 6 records `- YYYY-MM-DD: Scope created without INTENT.md
     (override).` in the audit trail so the drift risk is on record.

## Step 1 — Fast-track check

Walk the ten fast-track criteria in `docs/FRAMEWORK.md § Fast-Track
Path`. If every one passes, offer the quick path:

> This looks like fast-track work — it meets every gate criterion.
> Want me to run `/spades:quick` and skip the full scope flow?

Continue with this skill when any criterion fails or the human
prefers the full loop.

## Step 2 — Mode

- **Create** (default) — a new Scope.
- **Edit** — refining an existing Scope.

When the input names an `S-<slug>` ID, a slug, or a title that
fuzzy-matches an existing Scope, default to Edit.

### Fuzzy match

1. List the active project's Scopes via the backend interface
   (`list_scopes(filter)`).
2. Score each against the input: slug substring, title token
   overlap, exact ID prefix.
3. Offer up to three candidates above a soft threshold via
   `AskUserQuestion` — **Edit `S-<slug>` (<title>)** per candidate,
   plus **Create a new scope**. With no close candidate, go straight
   to Create.

## Step 3 — Slug (Create mode)

Derive the slug from the description:

1. Lowercase.
2. Replace runs outside `[a-z0-9-]` with a single hyphen.
3. Trim leading and trailing hyphens.
4. Truncate to 64 characters after the `S-` prefix.
5. Reject an empty result, a leading hyphen, or `..`.

*"Add AI Helper Bot"* → `S-add-ai-helper-bot`. Confirm via
`AskUserQuestion`: **Use this ID** / **Edit the slug**. If
`.spades/scopes/S-<slug>.md` already exists, switch to Edit mode and
say so.

## Step 4 — Conversation, one field at a time

Scope content is composition, so it stays free-form. Ask one field,
wait, reflect back what you heard, then move on. Probe vague
answers for testable detail, propose stronger wording for weak
criteria, and flag a Scope that looks too large to plan in one
session.

### 1. Statement of Intent
What is achieved and why it matters — outcome, not activity. One to
three sentences.

✓ *"Device telemetry is flowing into the intelligence platform and
available for threat analysis."*
✗ *"Build the telemetry pipeline."*

### 2. Acceptance Criteria
Specific, verifiable conditions for done. One checkbox each; aim for
3–7.

✓ *"Telemetry data appears in the Elasticsearch index within 5
minutes of device transmission."*
✗ *"Telemetry works."*

### 3. Architectural Constraints
Reference `ARCHITECTURE.md` and `PATTERNS.md` where they apply.
When nothing extra applies, record *"No additional constraints
beyond ARCHITECTURE.md"* explicitly.

### 4. Dependencies
Other Scopes, services, infrastructure, or access that must be in
place, or *"None"*.

### 5. Context
Upstream (what feeds this), downstream (what depends on it),
related (other work in the area).

### 6. Out of Scope
What this Scope explicitly excludes. Be specific; the section is
always filled.

### 7. Risk / Unknowns
Known landmines the Plan must respect, or *"None identified"*.

### 8. Delivery Preference — `AskUserQuestion`
- **Mostly AI-delivered** — standard code, config, docs work
- **Mostly human-delivered** — needs org context, vendor access
- **Hybrid** — note which tasks are which

### 9. Priority — `AskUserQuestion`
`urgent` (blocks a release or live incident) · `high` · `this-cycle`
· `medium` · `low` · `backlog` · `exploratory` (investigating
whether it is worth doing).

### 10. Type — `AskUserQuestion`
`feature` · `bug` · `chore` · `docs` · `refactor` · `investigation`.
Usually inferable from the description; confirm.

### 11. Strategy link (optional)
Ask once: *"Does this scope trace to a roadmap item, OKR, or epic
tracked elsewhere? Paste the link or ID and I'll record it as
`strategy_link:`; if it's reactive or ad-hoc, say so."* Record a
supplied reference verbatim as a free-form string. For reactive or
ad-hoc work, omit the field; `origin:` carries the rationale.

## Step 5 — Quality check

Before writing, confirm:

- [ ] Someone could start planning this without a follow-up
      conversation.
- [ ] Acceptance criteria are specific and testable.
- [ ] The Scope is small enough to plan in a single session.
- [ ] Constraints, dependencies, and risks are explicit, or
      explicitly "none".
- [ ] Out of Scope is filled.

Help the human fix any gap before continuing.

## Step 6 — Write the Scope

This step always writes the `.md`. In CLI mode, paste the assembled
draft first and write once the human approves it. In HTML mode,
write the draft straight away and let the rendered page carry the
review.

### The canonical `.md` (both modes)

Path: `.spades/scopes/S-<description-slug>.md`

```yaml
---
id: S-<slug>
title: "<title>"
project: <active-project-slug>
status: scoped
type: feature | bug | chore | docs | refactor | investigation
priority: urgent | high | this-cycle | medium | low | backlog | exploratory
origin: okr | reactive | ad-hoc
strategy_link: <URL | ID | ref>   # only when supplied in Step 4.11
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_issue_id: <id>             # only when backend: linear, injected in Step 7
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

## Architectural Constraints

<references to ARCHITECTURE.md / PATTERNS.md, or the explicit "none">

## Dependencies

<list, or "None">

## Context

- **Upstream:** <…>
- **Downstream:** <…>
- **Related:** <…>

## Out of Scope

- <thing 1>
- <thing 2>

## Risk / Unknowns

- <risk 1, or "None identified">

## Delivery Preference

<mostly AI / mostly human / hybrid, with notes on which tasks>

## Audit Trail

<!-- Appended by /spades:plan, /spades:approve, /spades:evaluate,
     /spades:ship, /spades:close. -->
```

When the INTENT gate was overridden, the audit trail opens with
`- YYYY-MM-DD: Scope created without INTENT.md (override).`

### `worker-html-scope` (HTML mode)

Dispatched in Step 7's wave per `docs/FRAMEWORK.md § worker-html-*`:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/scope/template.html`
- `output_path`: `.spades/scopes/S-<description-slug>.html`
- `frontmatter`: `{ id, title, status, project, type, priority,
  origin, created, updated }`, also embedded verbatim in
  `<script id="spades-frontmatter">`
- `criteria_count` *(scalar)*: number of acceptance criteria
- `blocks`:
  - `acceptance-items` — one per criterion. Fields: `text, checked`.
  - `objective-banner` — 0 or 1 item `{ id, title }` per
    `docs/FRAMEWORK.md § Objective banner`, resolved from this
    Scope's `strategy_link` when it names an existing
    `.spades/objectives/O-<slug>.md`; else `[]`.
  - `dependencies-items` — one per Dependencies bullet. Field: `text`.
  - `out-of-scope-items` — one per Out of Scope bullet. Field: `text`.
  - `audit-events` — one per audit entry. Fields: `date, desc`.
- `prose_sections`: `{ statement_of_intent_html, constraints_html,
  context_html, risk_unknowns_html, delivery_preference_html }`

Required markers: `acceptance-items`, `dependencies-items`,
`out-of-scope-items`, `audit-events`.

## Step 7 — Write and mirror (fan-out)

Dispatch one wave per `docs/FRAMEWORK.md § Sub-agent Dispatch
(Fan-Out)` — every sub-agent in a single assistant message,
`subagent_type: general-purpose`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-scope` | `.spades/scopes/S-<slug>.md`, written without `linear_issue_id:` | `{ status: ok }` |
| `worker-html-scope` *(HTML mode)* | `.spades/scopes/S-<slug>.html` per Step 6 | `{ status: ok, path, opened }` |
| `worker-linear-scope` *(`backend: linear`)* | Linear — a parent Issue on the active Linear Project with the Scope's title and body, workflow state for `scoped`. Carries the freshness probe. | `{ status: ok, linear_issue_id }` |

With `backend: local` the wave has no Linear worker; the local file
is the whole record.

After the wave, the coordinator:

- **All ok** → inject `linear_issue_id: <id>` into the `.md`
  frontmatter (and the embedded frontmatter block of the `.html`).
  Record the dispatch mode.
- **File worker failed** → abort with the error; a Linear Issue may
  exist without a file, so say so.
- **HTML worker failed** → keep the `.md`, surface the render error,
  continue.
- **Linear worker failed** → keep the local file, surface the
  failure, offer a retry. The local file is canonical.

## Step 8 — Confirm

```
✓ Scope created: S-add-ai-helper-bot
✓ Title:         Add AI Helper Bot
✓ Project:       closed-door-security-website
✓ Status:        scoped
✓ Linear Issue:  M-1234   (backend: linear only)

Next:
  /spades:plan S-add-ai-helper-bot     — break this scope into plans
  /spades:review S-add-ai-helper-bot   — optional second opinion before planning
```

The second-opinion suggestion is a pointer; this skill invokes no
other skill.

## Edit mode

1. Read the `.md`.
2. Show the current content and highlight weak or missing fields.
3. Walk the human through the gaps, one field at a time.
4. Write the file back, preserving `id:` and `created:`, setting
   `updated:` to today, and appending
   `- YYYY-MM-DD: Scope edited — <fields changed>.` to the audit
   trail. In HTML mode, re-dispatch `worker-html-scope`.
5. With `backend: linear` and a `linear_issue_id:`, push the updated
   description to the Linear Issue.

Where the human's edits conflict with existing content, ask before
replacing it.
