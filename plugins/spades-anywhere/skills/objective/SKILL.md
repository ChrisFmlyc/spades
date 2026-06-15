---
name: objective
description: Create or edit a spades-anywhere Objective — a coherent strategic action associated with a project (Rumelt/OKR sense), prefixed O-. Use when someone says "create an objective", "set an objective", "add an objective", "new objective", "add a milestone for this project", or "/spades-anywhere:objective <description>". An Objective is independent of Scopes — it never contains, requires, or gates on one. Closing an Objective is done via /spades-anywhere:close O-<slug>.
version: 1.0.0
---

# /spades-anywhere:objective

You are creating (or editing) an **Objective** — *a coherent strategic
action associated with a project*, in the *Good Strategy / Bad Strategy*
(Rumelt) sense, close to the **Objective** in OKRs (though not tied to
OKRs). It is the in-SPADES anchor that records *"this project has this
strategic objective associated with it."*

Read `docs/FRAMEWORK.md` § Hierarchy → Objectives, § ID Format, and
§ .spades-anywhere/ Local Layout before running. The schema below mirrors
that contract.

**What an Objective is NOT.** It is independent of Scopes — it never
contains, requires, attaches, or gates on a Scope, and it does not run the
six-phase loop. Do not prompt for acceptance criteria, plans, target dates,
owners, or priority. Keep it minimal. The full contract lives in
`docs/FRAMEWORK.md` § Hierarchy → Objectives.

This skill **creates and edits** Objectives. Completing or abandoning one is
`/spades-anywhere:close O-<slug>` (per skill isolation, this skill never
invokes close inline).

### Output format

This skill honours `review_format:` from `.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML) → Universal rule`. In
**both** modes, write the Objective record as
`.spades-anywhere/objectives/O-<slug>.md` — the AI-readable source of truth
and the canonical record. In HTML mode, **additionally** render via the
sibling `${CLAUDE_PLUGIN_ROOT}/skills/objective/template.html` and write
`.spades-anywhere/objectives/O-<slug>.html` for the human's view, then
auto-open via the OPEN_CMD prelude. HTML mode is additive — the `.md` always
exists; the `.html` is added in HTML mode.

**HTML mode is review-via-file, not review-via-CLI.** Do NOT paste the
Objective body to the CLI for the human's approval before Step 4 writes the
file. The file IS the review surface. To iterate, apply targeted edits to
the file (the human reloads to see changes) — never re-paste a new full
draft to the CLI. In CLI mode the draft-then-confirm workflow is fine.

## Pre-Flight

1. **Confirm setup.** If `.spades-anywhere/config` is missing, abort and
   suggest `/spades-anywhere:setup` first.
2. **Confirm active project.** Read `project:` from
   `.spades-anywhere/config`. If missing, abort and suggest
   `/spades-anywhere:newproject` to create one.
3. **Verify Project active** per `docs/FRAMEWORK.md § Target Resolution →
   Parent-status precondition`. If the active Project's status is
   `abandoned` or `archived`, abort hard with the canonical error shape. In
   Edit mode, also re-verify after Step 1 resolves the target. No override.
   (Objectives are gated on Project status for *create/edit* only; closing
   one is not — see that section.)
4. **No INTENT hard-gate.** Unlike `/spades-anywhere:scope`, this skill does
   **not** hard-gate on `INTENT.md`. An Objective is itself a strategy-level
   statement, so gating it on INTENT would be circular. If `INTENT.md` is
   missing, mention it as a soft nudge only and proceed.
5. **Read the backend.** The branches below act according to
   `.spades-anywhere/config`'s `backend:` field.

## Step 1 — Mode (Create vs Edit)

- **Create mode** (default) — a new Objective.
- **Edit mode** — refining an existing Objective.

If the human's input names a slug, an `O-<slug>` ID, or a title that
fuzzy-matches an existing Objective, default to Edit mode. Otherwise Create.

### Fuzzy match

When the human gives a description, fuzzy-match it against existing
Objectives (via the backend's `list_objectives(filter)`, filtered to the
active project):

1. Score each by slug substring, title token-overlap, and `O-` ID prefix.
2. Surface up to three candidates above a soft threshold via
   `AskUserQuestion`:
   - **Edit `O-<slug>` (<title>)** — top candidate
   - **Edit `O-<slug2>` (<title2>)** — second candidate (if any)
   - **Create a new objective** — always offered
3. If none look close, go straight to Create mode.

## Step 2 — Slug Derivation (Create mode only)

Derive the slug from the title, using the same rule as
`/spades-anywhere:newproject` and `/spades-anywhere:scope`:

1. Lowercase.
2. Replace non-`[a-z0-9-]` runs with single hyphens.
3. Trim leading and trailing hyphens.
4. Truncate to 64 characters (after the `O-` prefix).
5. Reject if empty, leading-hyphen, or `..` present.

Example: *"Q3 Trust Launch"* → `O-q3-trust-launch`.

Show the derived ID and confirm via `AskUserQuestion`: **Use this ID**
(recommended) / **Edit the slug**.

**Collision check.** If `.spades-anywhere/objectives/O-<slug>.md` already
exists, this is an Edit operation — switch modes and warn the human. When
`backend: linear`, also query for an existing milestone of the same name; if
one exists, ask via `AskUserQuestion` whether to **bind to the existing
milestone** (recommended) or **create a separate one** (pick a
differentiated name).

## Step 3 — Gather the Objective (minimal)

The Objective record is deliberately minimal. Ask the human, conversationally
(not as a form):

- **Title** — human-readable name. The slug derives from this.
- **Objective** — a 2–4 sentence description of the coherent strategic
  action/outcome. Push for a *coherent action* (Rumelt), not a vague
  aspiration or a task list. Reflect it back so the human can sharpen it.
- **Strategy link** *(optional, may be empty)* — a URL / ID / ref to the
  upstream roadmap or strategy item this objective serves, or a fuller
  written definition of it. Accept "none".

Do **not** prompt for acceptance criteria, target dates, owners, priority,
or any Scope linkage. Those are deliberately out of scope.

## Step 4 — Create (or update) the Objective

**Read `review_format:` from `.spades-anywhere/config` and branch on file
format.** Step 4 MUST write the Objective `.md` before exiting — never print
the record to the CLI only, and never paste the body to the CLI for approval
before this step writes the file in HTML mode.

### When `backend: local`

#### Step 4.A — Write the canonical `.md` (both modes)

Write `.spades-anywhere/objectives/O-<slug>.md` with this exact shape:

```markdown
---
id: O-<slug>
title: "<title>"
project: <active-project-slug>
status: open
strategy_link: <ref or empty>
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# <title>

## Objective

<the 2–4 sentence description of the coherent strategic action/outcome>

## Audit Trail

- YYYY-MM-DD: Objective created.
```

In Edit mode, apply targeted edits to the existing file: update the
`## Objective` body and/or `strategy_link:`, bump `updated:`, and append an
audit line `- YYYY-MM-DD: Objective edited.`. Never rewrite `status:` here —
that is `/spades-anywhere:close`'s job.

#### Step 4.B — HTML render (HTML mode only)

When `review_format: html`, render the `.html` companion from
`${CLAUDE_PLUGIN_ROOT}/skills/objective/template.html` to
`.spades-anywhere/objectives/O-<slug>.html` and auto-open it via the
OPEN_CMD prelude (`docs/FRAMEWORK.md § OPEN_CMD detection prelude`). The
template fills the `audit-events` block; validate it exists per
`docs/FRAMEWORK.md § Output Format → HTML rendering: validate and use the
bundled template`.

### When `backend: linear` — fan-out dispatch

Apply the fan-out pattern from `docs/FRAMEWORK.md § Sub-agent Dispatch
(Fan-Out)`. Spawn the sub-agents below **in parallel in a single assistant
message with multiple `Agent` tool calls** (`subagent_type:
general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-objective` | `.spades-anywhere/objectives/O-<slug>.<ext>` — the canonical `.md` (Step 4.A shape), written **without** `linear_milestone_id` / `linear_issue_id`; the coordinator injects them post-dispatch. | `{ status: ok }` (or `fail` + `error`) |
| `worker-html-objective` *(only when `review_format: html`)* | `.spades-anywhere/objectives/O-<slug>.html` — see Step 4.B. | `{ status: ok, path, opened }` |
| `worker-linear-objective` | Linear — creates **both** objects (the milestone alone is not a valid Objective): **(1)** `save_milestone(project: <linear.project_id>, name: "O-<slug>", description: <objective text>)` (no targetDate); then **(2)** `save_issue(team: <linear.team_id>, project: <linear.project_id>, title: "O-<slug> — <title>", description: <objective text>, milestone: "O-<slug>")` — the **sister `O-` tracking issue** bound to that milestone. | `{ status: ok, linear_milestone_id, linear_issue_id }` (or `fail`) |

The Linear sub-agent's prompt includes the Layer-2 freshness probe (per
`FRAMEWORK.md § Sub-agent Dispatch`). Each prompt is self-contained
(scope, inputs, return schema).

After the sub-agents return, the coordinator (this skill body) collects
results per the failure semantics in `FRAMEWORK.md § Sub-agent Dispatch`:

- **All ok** → targeted edit on the local `.md` to inject
  `linear_milestone_id: <id>` and `linear_issue_id: <id>` into the
  frontmatter (and into the embedded `<script id="spades-frontmatter">`
  block in HTML mode). Record the dispatch mode used.
- **File sub-agent failed** → abort; the milestone/issue may have been
  created but is orphaned. Surface clearly so the human can delete it from
  Linear or re-run.
- **Linear sub-agent failed** → keep the local file (canonical); surface
  the failure and offer to retry the Linear mirror later. If the milestone
  was created but the sister issue was not, say so explicitly — a milestone
  without its sister issue is an incomplete Objective in Linear.

The local file is the canonical SPADES record; the Linear milestone + sister
issue is the tracker mirror. Both should exist when `backend: linear`.

## Step 5 — Confirm

Print a short summary:

```
✓ Objective created: O-<slug>          (or "updated")
✓ Title:             <title>
✓ Project:           <project-slug>
✓ Strategy link:     <ref or "—">
✓ Linear milestone:  O-<slug>          (only when backend: linear)
✓ Linear issue:      <id> (sister O-)  (only when backend: linear)
✓ Status:            open

Next:
  /spades-anywhere:close O-<slug>   — mark complete when the team lead judges
                                      the objective reached (or --abandon to
                                      walk away)
```

## Edge Cases

- **Description reads like a task, not an objective.** Push back: an
  Objective is a coherent strategic action/outcome, not a unit of work.
  Suggest `/spades-anywhere:scope` if the human is actually describing
  deliverable work.
- **Human wants to attach scopes.** Explain that Objectives and Scopes are
  independent — there is no attachment. If they want to *record* that a
  Scope contributes to this Objective, they can set that Scope's optional
  `strategy_link:` to `O-<slug>` via `/spades-anywhere:scope` (Edit mode);
  it is purely documentary.
- **Project not active.** Pre-Flight Step 3 refuses create/edit under an
  abandoned/archived Project.
- **Linear milestone exists but no sister issue (legacy / partial run).**
  In Edit mode, offer to create the missing sister issue so the Objective
  is valid in Linear.
