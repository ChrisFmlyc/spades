---
name: setup
description: Configure spades-anywhere in this project — choose a backend (Linear MCP or local filesystem), set the active project, scaffold AGENTS.md / INTENT.md / ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md, and write .spades-anywhere/config. Use when starting fresh, when someone says "set up SPADES", "configure SPADES", "initialise SPADES", "I want to use SPADES here". Re-runnable to reconfigure backend or refresh scaffolding without clobbering existing content.
version: 0.6.0
---

# /spades-anywhere:setup

Configure `spades-anywhere` in this project. Every other skill
assumes setup has run and `.spades-anywhere/config` exists.

Setup is the one command a human runs to adopt the plugin. It
completes in a single pass and drives its own prerequisite inline: a
missing project is created via `/spades-anywhere:newproject` after
the config is on the store (Step 7). The edge points away from setup
and never back — the acyclic bootstrap contract in
`docs/FRAMEWORK.md § Bootstrap Order`. There is no git or SCM
prerequisite: the plugin runs on chat surfaces where there is often
no repo at all, and a human who keeps `.spades-anywhere/` under
version control may.

Re-runs ask every question again with the current value shown as
context. Step 4 diffs old against new and confirms before any
write; Step 5 offers migration on a backend switch. Human-written
content survives every re-run.

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades-anywhere/ Local
Layout, § Bootstrap Order, and § Output Format before running.

## Self-init guard

When this directory is the SPADES framework repo itself
(`.claude-plugin/plugin.json` has `name: spades` or
`name: spades-anywhere`, or `plugins/spades-anywhere/` exists at the
root), abort: *"This is the SPADES framework's own repository. Setup
is for consumer projects."* The framework dogfoods itself only when
told explicitly *"set up the dogfood project"*.

## Pre-Flight — existing config

```bash
[ -f .spades-anywhere/config ] && echo present || echo missing
```

`missing` → fresh install; Steps 4 and 5 are skipped. `present` →
capture `current_backend`, `current_project`, `current_linear_team`
/ `current_linear_project`, and `current_review_format` (default
`cli` on older configs).

## Step 1 — Backend — `AskUserQuestion`

With a current value, print *"Currently configured: `backend:
<value>`. The choice below replaces it — re-pick or switch."*

- **Linear** — artefacts mirrored to Linear Issues; requires the
  Linear MCP.
- **Local** — artefacts live only as Markdown under
  `.spades-anywhere/`.

Both keep the local files canonical.

**Linear chosen** → probe the Linear MCP (list teams). A failed
probe walks the human through the install rather than aborting:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

then `/mcp` inside Claude Code → Linear → OAuth in the browser;
verify with `claude mcp list`; re-run setup. With teams listed:
`AskUserQuestion` for the team, then for the Linear Project
(existing ones plus **Create new Linear Project**). *Create new*
records `team_id` and sets `create_new_project`; the Linear Project
is created at Step 7. Otherwise record `team_id` and `project_id`.

## Step 2 — Review format — `AskUserQuestion`

*How should spades-anywhere present reviews and artefacts?*

- **HTML** *(Recommended)* — every producing skill writes its `.md`
  and additionally an `.html` companion rendered from the bundled
  template and auto-opened; review happens on the rendered page.
- **CLI** — the `.md` only; review-form output prints to the
  terminal.

Recorded as `review_format:`. The presentation surface changes;
every flow, prompt, and decision is the same.

## Step 3 — Active project — `AskUserQuestion`

Offer the existing `.spades-anywhere/projects/<slug>.md` records plus
**Create a new project**. Record the intent and write nothing yet:
an existing project → `new_project: <slug>`; create → keep
`new_project` unset for Step 7.

## Step 4 — Diff and confirm

- **Fresh install** → Step 6.
- **Nothing changed** → *"Nothing changed — backend, review format,
  and active project all match. Refresh the scaffolding?"*
  `AskUserQuestion`: **Yes, refresh** / **Cancel — exit without
  writes**.
- **Something changed** → show the diff and confirm:

```
Detected pre-existing config. Confirm these changes before any
writes happen:

  Backend:        <current_backend>  →  <new_backend>
  Review format:  cli                (unchanged)
  Active project: <current_project>  (unchanged)
  Linear team:    (unset)            →  <new_linear_team>      # backend: linear
  Linear project: (unset)            →  <new_linear_project>   # backend: linear

.spades-anywhere/config and the AGENTS.md marker block will be
updated. Existing scopes, plans, and learnings are never deleted
by this skill.
```

`AskUserQuestion`: **Apply changes** (→ Step 5 when the backend
changed, else Step 6) / **Cancel — exit without writes**.

## Step 5 — Backend-switch migration

Fires only when `current_backend != new_backend`. **Read
[`reference/backend-migration.md`](reference/backend-migration.md)
and follow it.** It returns here for Step 6 whether the walk ran,
was skipped, or was cancelled.

## Step 6 — Write `.spades-anywhere/config`

```yaml
backend: linear            # or: local
project: <project-slug>    # unset when create_new_project; Step 7 fills it
review_format: html        # or: cli
linear:                    # backend: linear
  team_id: <uuid>
  project_id: <uuid>       # unset when create_new_project
```

With `create_new_project` on a fresh install, write `project:`
unset; on a re-run, keep the existing `project:` and
`linear.project_id` until Step 7 overwrites them. The config is on
the store before Step 7; that is what makes the inline
`/spades-anywhere:newproject` legal.

## Step 7 — Create the project (when `create_new_project`)

Invoke `/spades-anywhere:newproject` inline as a sub-routine. It
gathers the details, writes `.spades-anywhere/projects/<slug>.md`
(and the Linear Project), and sets `project:` (and
`linear.project_id`). If it fails or the human cancels, surface
*"No project was created — re-run `/spades-anywhere:setup` or
`/spades-anywhere:newproject`."* and finish the remaining
scaffolding.

## Step 8 — Write `.spades-anywhere/version`

From `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and
`${CLAUDE_PLUGIN_ROOT}/.spades-anywhere/version`:

```
spades_anywhere_version=<plugin-version>
agents_version=<agents-version>
```

## Step 9 — Scaffold `.spades-anywhere/`

Create when missing, empty: `projects/`, `objectives/`, `scopes/`,
`plans/`, `quick/`, `learnings/`, `reviews/`.

## Step 10 — Ignore transient scratch (git only)

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

Outside a git repo, skip. Inside one, idempotently ensure
`.gitignore` lists `.spades-anywhere/.tmp/` (create the file with
that one line, or append it under a one-line comment), leaving the
rest of the file as it is.

## Step 11 — `AGENTS.md` marker block

Create `AGENTS.md` with `# AGENTS.md` and a blank line when it
doesn't exist. Insert or replace the block between
`<!-- SPADES-ANYWHERE-FRAMEWORK-START v<agents-version> -->` and
`<!-- SPADES-ANYWHERE-FRAMEWORK-END -->`, stamped with
`agents_version`. Markers present → replace in place; absent →
append; content outside the markers is untouched. **Read
[`reference/agents-md-block.md`](reference/agents-md-block.md) and
write its fenced content verbatim** between the markers.

## Step 12 — Project documentation

| File | Skill | Owns |
|---|---|---|
| `INTENT.md` | `/spades-anywhere:intent` | Why the project exists, for whom, success, non-goals |
| `ARCHITECTURE.md` | `/spades-anywhere:architecture` | How the work is structured — stages, stakeholders, cadence, tools, constraints |
| `PATTERNS.md` | `/spades-anywhere:patterns` | Approved process conventions |
| `ANTI-PATTERNS.md` | `/spades-anywhere:anti-patterns` | Explicit prohibitions |

For each, in that order: detect *Missing* / *Scaffolded but
unfilled* (two or more placeholder comments) / *Complete*. Complete
→ `✓ INTENT.md complete (last reviewed YYYY-MM-DD).` Otherwise ask
via `AskUserQuestion`: **Scaffold an empty template** *(recommended
on a first run)* — the facilitator's inline template verbatim with
`last_reviewed: <today>` / **Skip**. The facilitator skills fill the
content when the human runs them.

## Step 13 — Confirm

```
✓ Backend:        local → linear   (team: <name>, project: <name>)
✓ Review format:  html
✓ Active project: family-events (unchanged)
✓ Migrated:       1 project, 3 scopes, 11 plans → Linear      # Step 5 walked
✓ Config:         .spades-anywhere/config
✓ Version:        plugin <plugin-version>, rules <agents-version>
✓ Updated:        AGENTS.md (marker block re-stamped)
✓ Created:        ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md  (templates)
○ Skipped:        INTENT.md (run /spades-anywhere:intent to scaffold)

Next steps:
  /spades-anywhere:intent           — fill INTENT.md with real content
  /spades-anywhere:scope <title>    — start a new Scope
```

Fresh installs show chosen values without transitions. Keep it
brief.

## Why `AGENTS.md`

`AGENTS.md` is the cross-agent convention. A consumer gets one
operating-rules file every agent reads — pasted into the
instructions field of Claude Projects, a Custom GPT, a Gem, or
whatever surface they use — and it is the only agent file the plugin
maintains.
