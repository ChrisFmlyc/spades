---
name: scope
description: Creates or edits a SPADES Scope in the current documentation session and records its intended delivery branch for later execution. Use when a human asks for a change too large for /spades:quick ("add X", "we need a Y"), when starting new work, when someone says "scope X", "create a scope", "edit a scope", or when work needs a written outcome and acceptance criteria. Fuzzy-matches existing scopes by slug or title to avoid duplicates; argument is the scope description.
version: 4.2.1
---

# /spades:scope

Create or edit a Scope with the outcome, acceptance criteria and constraints
that guide Plan, Evaluate and Ship.

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
- **CLI mode** — the draft is presented in the CLI review pane (`docs/FRAMEWORK.md § CLI review pane`) for review before Step 6
  writes it.

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
Path`. When every one passes and the human asked for the change rather
than for a Scope by name, hand the description to `/spades:quick` with a
one-line reason; Quick rechecks the gate as the fix develops. Continue
with this skill when any criterion fails or the human asked for a Scope.

## Step 2 — Mode

- **Create** (default) — a new Scope.
- **Edit** — refining an existing Scope.

When the input names an `S-<slug>` ID, a slug, or a title that
fuzzy-matches an existing Scope, default to Edit.

### Fuzzy match

Include active Scopes in registered worktrees when using the local backend;
a new Scope may not yet exist in the primary checkout. Report the matching
branch and use that worktree when editing.

1. List the active project's Scopes via the backend interface
   (`list_scopes(filter)`).
2. Score each against the input: slug substring, title token
   overlap, exact ID prefix.
3. Offer up to three candidates above a soft threshold via
   `AskUserQuestion` — **Edit `S-<slug>` (<title>)** per candidate,
   plus **Create a new scope**. With no close candidate, go straight
   to Create.

## Step 2.5 — Documentation context

Use `docs/FRAMEWORK.md § Scope Worktrees → Documentation before delivery`.
Reuse the current non-default working branch for this session's Scopes,
Plans and approvals. From main/master, invoke `/repo:newbranch` once for a
documentation session and continue all writes in its returned worktree.

In Edit mode, resolve the authoritative copy per § Entering or resuming
work and re-read it there. Preserve existing edits and inclusion decisions.

## Step 3 — Slug (Create mode)

Derive the slug from the description:

1. Lowercase.
2. Replace runs outside `[a-z0-9-]` with a single hyphen.
3. Trim leading and trailing hyphens.
4. Truncate to 64 characters after the `S-` prefix.
5. Reject an empty result, a leading hyphen, or `..`.

*"Add AI Helper Bot"* → `S-add-ai-helper-bot`. The ID heads the draft,
and Step 6's confirmation covers it. If `.spades/scopes/S-<slug>.md`
already exists, switch to Edit mode and say so.

## Step 4 — Draft every field

Scope content is composition, drafted first per `docs/FRAMEWORK.md
§ Asking the Human`. Draft each field below from the request, the
conversation so far, the code, and the project documents. Write the
outcome rather than the activity, turn a vague request into testable
criteria, and flag a Scope that looks too large to plan in one session.
Every drafted value is a proposal until the human confirms it in Step 6.

A field with nothing to support a proposal is open. Ask about all open
fields together in one message, then draft them from the answers.

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
Known risks the Plan must address, or *"None identified"*.

### 8. Delivery Preference
Asked in Step 6's confirmation, the inferred value first and marked
*(Recommended)*:
- **Mostly AI-delivered** — standard code, config, docs work
- **Mostly human-delivered** — needs org context, vendor access
- **Hybrid** — note which tasks are which

### 9. Priority
Asked in Step 6's confirmation, the inferred value first and marked
*(Recommended)*:
- **urgent** — blocks a release or live incident
- **high** — must complete soon
- **this-cycle** — the current work cycle
- **medium** / **low** — important, not time-sensitive
- **backlog** — nice to have
- **exploratory** — investigating whether it is worth doing

### 10. Type
Asked in Step 6's confirmation, the inferred value first and marked
*(Recommended)*: **feature** / **bug** / **chore** / **docs** /
**refactor** / **investigation**.

### 11. Outcome — not asked here
A Scope does not name an outcome at creation. It records the
Objective it delivered against once, at `/spades:close` (Scope
roll-up), which writes `strategy_link: O-<slug>` and mirrors it to
Linear. Leave `strategy_link:` absent; `origin:` already carries the
rationale for reactive or ad-hoc work.

## Step 5 — Quality check

With every field drafted, check the draft:

- [ ] Someone could start planning this without a follow-up
      conversation.
- [ ] Acceptance criteria are specific and testable.
- [ ] The Scope is small enough to plan in a single session.
- [ ] Constraints, dependencies, and risks are explicit, or
      explicitly "none".
- [ ] Out of Scope is filled.

Fix a gap in the draft before presenting it, asking the human only
when nothing supports a fix.

## Step 6 — Confirm and write the Scope

This step always writes the `.md`. Present the whole draft once and
confirm it with one `AskUserQuestion` call. In CLI mode, present the
draft in the CLI review pane on that call (paged per section when long)
and write once the human approves it. In HTML mode, write the draft once
Step 5 is complete and ask the call once Step 7 has opened the rendered
page, which carries the review.

The call holds four questions:

1. **The Scope** — when the loop is on offer: *Use it and run
   `/spades:loop`* *(Recommended)* / *Use it and stop at the Scope* /
   *Change something*. Otherwise: *Use `S-<slug>` as drafted*
   *(Recommended)* / *Change something*. The loop is on offer when the
   request asked for the change itself rather than only its Scope; for a
   Lead promotion, when the `/spades:leads` context packet records that
   the request came through `/spades:loop`.
   The human says what to change through *Other* or a short follow-up.
   Choosing the loop is the human's invocation of it; Step 8 starts it.
2. **Delivery preference** — field 8.
3. **Priority** — field 9.
4. **Type** — field 10.

A change edits the draft, then the Scope question is asked again. Once
the `.md` exists, the change is a targeted `.md` edit, a re-render in
HTML mode, and with `backend: linear` an update of the Issue's title
and description from the `.md`. A changed title or type re-derives
`branch:`. Answered decisions stay answered unless the human changes
them.

### The canonical `.md` (both modes)

Derive and validate the intended delivery `branch:` per
`docs/FRAMEWORK.md § Scope Worktrees → Documentation before delivery` after
the title and type are settled. Record the name without creating it;
`/spades:deliver` establishes that separate worktree later.

Preserve `branch:` and any established `base_commit:` on every Edit and
render round-trip. Include them in file-worker payloads; omit `base_commit:`
until delivery establishes it. HTML is a view of the same record.

Path: `.spades/scopes/S-<description-slug>.md` in the documentation worktree
(or the established delivery worktree when editing there).

```yaml
---
id: S-<slug>
title: "<title>"
project: <active-project-slug>
status: scoped
branch: <intended delivery branch; created by /spades:deliver>
type: feature | bug | chore | docs | refactor | investigation
priority: urgent | high | this-cycle | medium | low | backlog | exploratory
origin: okr | reactive | ad-hoc
strategy_link: O-<slug>           # written by /spades:close at Scope roll-up; absent until then
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

- `open_path`: the absolute `output_path` for this skill’s initial review
  presentation; `null` for refreshes or background use, per
  `docs/FRAMEWORK.md § Review-page ownership`.
- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/scope/template.html`
- `output_path`: `.spades/scopes/S-<description-slug>.html`
- `frontmatter`: `{ id, title, status, project, type, priority,
  origin, branch, created, updated }`, plus `base_commit` when established,
  also embedded verbatim in `<script id="spades-frontmatter">`. Omit the
  template's `base_commit:` line when that field is absent.
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
| `worker-linear-scope` *(`backend: linear`)* | Linear — a parent Issue on the active Linear Project with the Scope's title and body, workflow state for `scoped`. Carries the resolved worktree context per § Freshness. | `{ status: ok, linear_issue_id }` |

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

`/spades:review` stays a separate, optional next step, named in the
`Next:` lines. When the human chose the loop in Step 6, start
`/spades:loop S-<slug>` now. A Scope written for a Lead promotion instead
returns its ID to `/spades:leads`, with the loop choice when Step 6
offered the loop; `/spades:leads` records the promotion and then starts
the loop when the human chose it.

## Edit mode

1. Read the `.md`.
2. Draft the changes the human asked for, and propose fixes for weak
   or missing fields from the sources in Step 4.
3. Present the changed fields together and confirm them with the Step 6
   call, asking only the questions whose answers change.
4. Write the file back, preserving `id:` and `created:`, setting
   `updated:` to today, and appending
   `- YYYY-MM-DD: Scope edited — <fields changed>.` to the audit
   trail. In HTML mode, re-dispatch `worker-html-scope`.
5. With `backend: linear` and a `linear_issue_id:`, push the updated
   title and description to the Linear Issue.

Where the human's edits conflict with existing content, ask before
replacing it.
