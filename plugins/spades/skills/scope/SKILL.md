---
name: scope
description: Create or edit a SPADES Scope — the outcome record that everything downstream is measured against. Use when starting new work, when someone says "scope X", "create a scope", "edit a scope", or when work needs a written outcome and acceptance criteria. Fuzzy-matches existing scopes by slug or title to avoid duplicates; argument is the scope description.
version: 3.1.3
---

# /spades:scope

You are creating or editing a Scope. A Scope is the contract that
everything downstream is measured against. Every field matters — a
weak Scope produces a weak Plan.

Read `docs/FRAMEWORK.md` § ID Format and § .spades/ Local Layout before
running. Schemas below mirror that contract.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML) → Universal
rule`. In **both** modes, write `.spades/scopes/S-<slug>.md` —
this is the AI-readable source of truth and the canonical
record. In HTML mode, **additionally** render via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/scope/template.html` and write
`.spades/scopes/S-<slug>.html` for the human's view, then
auto-open via the OPEN_CMD prelude. HTML mode is additive —
the `.md` always exists; the `.html` is added in HTML mode.

**HTML mode is review-via-file, not review-via-CLI.** Do NOT paste
the Scope body (or any substantive excerpt of it) to the CLI for
the human's approval before Step 7 writes the file. The file IS the
review surface. Step 7 writes a working draft and auto-opens it; the
human reviews in the browser. To iterate, apply targeted edits to
the file (the human reloads to see changes) — never re-paste a new
full draft to the CLI. In CLI mode the existing draft-then-paste
workflow is fine.

## Pre-Flight

1. **Confirm setup.** If `.spades/config` is missing, abort and suggest
   `/spades:setup` first.
2. **Confirm active project.** Read `project:` from `.spades/config`.
   If missing, abort and suggest `/spades:newproject` to create one.
3. **INTENT.md gate.** A Scope is measured against the project's
   `INTENT.md` (the durable statement of *why* this project exists).
   Scoping without INTENT means scope drift is silent — there is no
   north star to measure against.

   Probe:

   ```bash
   [ -f INTENT.md ] && echo present || echo missing
   ```

   - **`present`** → proceed.
   - **`missing`** → **hard gate**. Ask via `AskUserQuestion`:
     - **Run `/spades:intent` now** *(Recommended)* — compose INTENT
       before scoping. Invoke the intent skill inline; once it
       completes, resume here at Step 1.
     - **Override and proceed without INTENT** — only for
       throwaway / sandbox / prototype repos. Record the override
       in the new Scope's audit trail (see Step 7) with the line:
       `- YYYY-MM-DD: Scope created without INTENT.md (override).`
       Drift risk accepted by the human.
     - **Abort** — exit, handle manually.

   Do not silently proceed if INTENT is missing. The cost of
   running `/spades:intent` is minutes; the cost of months of
   silent scope drift is much higher. Friction is the feature.

4. **Read the backend.** Branches below act according to `.spades/config`'s
   `backend:` field.

## Step 1 — Fast-Track Check First

Before scoping, walk the fast-track gate (10 criteria — see
`docs/FRAMEWORK.md` § Fast-Track Path). If every criterion passes, stop
and suggest `/spades:quick` instead:

> This looks like fast-track work — it meets every gate criterion.
> Want me to run `/spades:quick` and skip the full scope flow?

Only continue with `/spades:scope` if the human confirms or any gate
criterion fails.

## Step 2 — Mode (Create vs Edit)

The skill operates in two modes:

- **Create mode** (default) — new scope.
- **Edit mode** — refining an existing scope.

If the human's input names a slug, an `S-<slug>` ID, or a title that
matches an existing scope (fuzzy), default to Edit mode. Otherwise,
Create mode.

### Fuzzy match

When the human provides a description, fuzzy-match it against existing
scopes:

1. List scopes for the active project (via the backend interface's
   `list_scopes(filter)` then filter to active project).
2. For each scope, compute a similarity score against the human's
   input — a substring match on the slug, a token-overlap score on
   the title, and exact-prefix on the ID all count.
3. Surface candidates with a score above a soft threshold to the human
   via `AskUserQuestion`:
   - **Edit `S-<slug>` (<title>)** — top candidate
   - **Edit `S-<slug2>` (<title2>)** — second candidate (if any)
   - **Create a new scope** — always offered

Only show up to three candidates; if none look close, just go straight
to Create mode.

## Step 3 — Slug Derivation (Create mode only)

Derive the slug from the description:

1. Lowercase.
2. Replace non-`[a-z0-9-]` runs with single hyphens.
3. Trim leading and trailing hyphens.
4. Truncate to 64 characters (after the `S-` prefix).
5. Reject if empty, leading-hyphen, or `..` present.

Example: *"Add AI Helper Bot"* → `S-add-ai-helper-bot`.

Show the derived ID to the human and confirm via `AskUserQuestion`:
**Use this ID** / **Edit the slug**.

If `.spades/scopes/S-<slug>.md` already exists, this is actually an
Edit operation — switch modes and warn the human.

## Step 4 — Conversation (One Field at a Time)

Scope content is composition (free-form prose), not a fixed-option
choice. Run the conversation collaboratively:

1. **One topic at a time.** Ask one field, wait, then the next.
2. **Probe when answers are vague.** Push for testable detail.
3. **Suggest improvements.** Propose stronger versions of weak
   acceptance criteria.
4. **Be opinionated.** Flag scope that looks too large.
5. **Summarise before moving on.** After each field, reflect back what
   you heard so the human can correct early.

The fields to walk through:

### 1. Statement of Intent
What needs to be achieved and why it matters. **Outcome, not activity.**

✓ *"Device telemetry is flowing into the intelligence platform and
available for threat analysis."*
✗ *"Build the telemetry pipeline."*

One to three sentences.

### 2. Acceptance Criteria
Specific, verifiable conditions for "done". Each criterion is a
checkbox. Aim for 3–7.

✓ *"Telemetry data appears in the Elasticsearch index within 5 minutes
of device transmission."*
✗ *"Telemetry works."*

### 3. Architectural Constraints
Reference `ARCHITECTURE.md` and `PATTERNS.md` where relevant. If
nothing extra applies, state *"No additional constraints beyond
ARCHITECTURE.md"* explicitly — never blank.

### 4. Dependencies
Other scopes, services, infrastructure, or access that must be in
place. State *"None"* if so.

### 5. Context
- **Upstream:** what feeds this?
- **Downstream:** what depends on this?
- **Related:** other work in the same area?

### 6. Out of Scope
What this scope explicitly does NOT cover. Be specific. Never blank.

### 7. Risk / Unknowns
Known landmines. The AI uses these when planning to avoid generating
something that ignores them. State *"None identified"* if so.

### 8. Delivery Preference
- **Mostly AI-delivered** — standard code/config/docs work
- **Mostly human-delivered** — needs org context, vendor access, etc.
- **Hybrid** — specify which tasks AI vs human

Ask this via `AskUserQuestion` (fixed-option).

### 9. Priority
- **urgent** — blocks a release or live incident
- **high** — must complete soon
- **this-cycle** — current work cycle
- **medium** / **low** — important but not time-sensitive
- **backlog** — nice to have
- **exploratory** — investigating whether worth doing

Ask this via `AskUserQuestion` (fixed-option).

### 10. Type
- **feature** | **bug** | **chore** | **docs** | **refactor** | **investigation**

Often inferable from the description; confirm via `AskUserQuestion`.

### 11. Strategy / Roadmap link (optional)

Ask once, plainly: *"Does this scope trace to a roadmap item, OKR,
or epic tracked elsewhere? If yes, paste the link or ID — I'll
record it as `strategy_link:`. If reactive / ad-hoc, just say so
and we'll skip it."*

If the human supplies a link or ID, record it verbatim as the
`strategy_link:` frontmatter field — free-form string, no shape
validation (URLs, Linear IDs, Notion page refs, OKR codes all
acceptable). If they say "reactive" or "ad-hoc", omit the field;
the existing `origin:` field already captures the rationale.

This bridges the gap from the Strategy / Roadmap layer above SPADES
into the audit chain. Optional; SPADES never requires it.

## Step 5 — Quality Checks

Before finalising, verify:

- [ ] Could someone start planning this without a follow-up conversation?
- [ ] Are acceptance criteria specific and testable?
- [ ] Is this small enough to plan in a single session?
- [ ] Are architectural constraints explicit (or explicitly "none")?
- [ ] Is out-of-scope clearly defined?
- [ ] Are dependencies listed (or explicitly "none")?
- [ ] Are risks acknowledged (or explicitly "none identified")?

If any check fails, flag it and help the human fix before writing.

## Step 6 — Optional Second Opinion

Before writing, offer (via `AskUserQuestion`):

- **Yes, run `/spades:review`** on this Scope
- **No, skip**

If yes, invoke `/spades:review` in Scope Review mode. After the review,
resume here and ask whether the human wants to adjust the Scope.

## Step 7 — Write the Scope

**Read `review_format:` from `.spades/config` and branch.** This step
MUST write a file — never exit Step 7 with the Scope content only
pasted to the CLI, **and never paste the Scope body to the CLI for
human approval before this step writes the file in HTML mode**. The
file IS the review surface in HTML mode (see § Output format above).

### Step 7.A — Write the canonical `.md` (both modes)

### Filename

`.spades/scopes/S-<description-slug>.md`

### Frontmatter (exactly this shape)

```yaml
---
id: S-<slug>
title: "<title>"
project: <active-project-slug>
status: scoped
type: feature | bug | chore | docs | refactor | investigation
priority: urgent | high | this-cycle | medium | low | backlog | exploratory
origin: okr | reactive | ad-hoc
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_issue_id: <id>          # only when backend: linear AND synced
---
```

### Body template

```markdown
# <title>

## Statement of Intent

<one to three sentences>

## Acceptance Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>

## Architectural Constraints

<reference ARCHITECTURE.md and PATTERNS.md, or explicit "none">

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

<!-- Auto-appended by /spades:plan, /spades:approve, /spades:evaluate,
     /spades:ship. Do not edit by hand. -->
```

### Step 7.B — Additionally render the HTML (HTML mode only)

When `review_format: html`, after the `.md` in Step 7.A is
written, render the HTML companion file. The `.md` is unchanged;
the `.html` is **additive**.

**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.** Validate the template exists and the named
blocks below match the markers in the actual file before
substituting; abort and surface any mismatch. See
`docs/FRAMEWORK.md § Output Format → HTML rendering: validate and
use the bundled template` for the canonical rule.

1. **Read the template** at
   `${CLAUDE_PLUGIN_ROOT}/skills/scope/template.html`.
2. **Validate** it contains the block markers listed below; if any
   are missing, abort.
3. **Substitute placeholders** per `docs/FRAMEWORK.md § Output
   Format`:
   - Frontmatter values fill `{{spades.id}}`, `{{spades.title}}`,
     `{{spades.status}}`, `{{spades.project}}`, `{{spades.type}}`,
     `{{spades.priority}}`, `{{spades.origin}}`,
     `{{spades.created}}`, `{{spades.updated}}`.
   - The frontmatter YAML block also goes verbatim into the
     `<script type="application/yaml" id="spades-frontmatter">` tag.
   - `<!-- SPADES-BLOCK:acceptance-items -->` — repeated once per
     bullet under `## Acceptance Criteria`. Per-item:
     `{{block.text}}` (the criterion text), `{{block.checked}}`
     (boolean flag).
   - `<!-- SPADES-BLOCK:dependencies-items -->` — repeated once per
     bullet under `## Dependencies`. Per-item: `{{block.text}}`.
   - `<!-- SPADES-BLOCK:out-of-scope-items -->` — repeated once per
     bullet under `## Out of Scope`. Per-item: `{{block.text}}`.
   - `<!-- SPADES-BLOCK:audit-events -->` — repeated once per audit
     trail entry, in both the visible timeline and the
     `<script type="application/yaml" id="spades-audit-trail">`
     YAML block. Per-item: `{{block.date}}`, `{{block.desc}}`.
   - The prose body sections (`Statement of Intent`, `Constraints`,
     `Context`, `Risk / Unknowns`, `Delivery Preference`) are
     direct `{{spades.<section>_html}}` substitutions, not
     repeating blocks.
4. **Write the rendered HTML** to
   `.spades/scopes/S-<description-slug>.html`.
5. **Auto-open** the file via the OPEN_CMD prelude from
   `docs/FRAMEWORK.md § OPEN_CMD detection prelude`. If the OS
   detection returns empty, print the file path with "open this in
   your browser". Never crash.
6. The `.md` from Step 7.A is unchanged — both files coexist.

## Step 8 — Backend Mirror (fan-out dispatch)

### When `backend: linear`

Apply the fan-out pattern from
`docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. **Step 7's file
write and this step's Linear create are dispatched together in a
single fan-out wave** — Step 7 is the file sub-agent, this step is
the Linear sub-agent. Spawn both **in parallel in a single assistant
message with multiple `Agent` tool calls** (`subagent_type:
general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-scope` | `.spades/scopes/S-<slug>.<ext>` — the scope file rendered per Step 7.A (CLI) or 7.B (HTML). Written **without** `linear_issue_id:` — the coordinator injects it post-dispatch. | `{ status: ok }` |
| `worker-linear-scope` | Linear — create a parent Issue on the active Linear Project with title + description matching the Scope, status "Scoped". Includes the Layer-2 freshness probe. | `{ status: ok, linear_issue_id: "<id>" }` |

After both return, the coordinator:

- **Both ok** → targeted edit on the scope file to inject
  `linear_issue_id: <id>` into the frontmatter (and the embedded
  `<script type="application/yaml" id="spades-frontmatter">` block
  in HTML mode). Record dispatch mode.
- **File sub-agent failed** → abort with the error; the Linear
  Issue may exist but is orphaned. Surface clearly.
- **Linear sub-agent failed** → keep the local file (canonical),
  surface the failure, recommend a manual re-run later. Do NOT
  block on Linear failure.

### When `backend: local`

No fan-out — Step 7 writes the file synchronously and exits. The
local file IS canonical. Nothing else to mirror.

## Step 9 — Confirm

```
✓ Scope created: S-add-ai-helper-bot
✓ Title:         Add AI Helper Bot
✓ Project:       closed-door-security-website
✓ Status:        scoped
✓ Linear Issue:  M-1234   (only when backend: linear)

Next:
  /spades:plan S-add-ai-helper-bot   — break this scope into plans
```

## Edit Mode

When editing an existing scope:

1. Read the file.
2. Show the current content and highlight any weak/missing fields.
3. Walk the human through filling the gaps.
4. Write the file back, preserving the `id:` and `created:`, updating
   `updated:` to today.
5. If `backend: linear` and `linear_issue_id:` is present, also push
   the description update to Linear.

Never silently overwrite a scope file. If the human's edits conflict
with current content, ask before clobbering.
