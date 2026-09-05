---
name: setup
description: Configure SPADES in this repository — choose a backend (Linear MCP or local filesystem), set the active project, scaffold AGENTS.md / ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md, and write .spades/config. Use when starting fresh, when someone says "set up SPADES", "configure SPADES", "initialise SPADES", "I want to use SPADES in this repo". Re-runnable to reconfigure backend or refresh scaffolding without clobbering existing content.
version: 4.10.1
---

# /spades:setup

Configure SPADES in this repository. Every other skill assumes setup
has run and `.spades/config` exists.

Setup is the one command a human runs to adopt SPADES. It completes
in a single pass and drives its own prerequisites inline: a missing
git repo is initialised via `/repo:init` (Pre-Flight 2), and a
missing project is created via `/spades:newproject` after the config
is on disk (Step 8). Both edges point away from setup and neither
points back — the acyclic bootstrap contract in `docs/FRAMEWORK.md
§ Bootstrap Order`.

Steps 1 to 4 are one `AskUserQuestion` call each, asked on every
run; the recorded value is the answer the tool returns, even when
the repo or the current config makes it look obvious. Re-runs show
the current value as context above each prompt. Step 5 diffs old against new and confirms
before any write; Step 6 offers migration on a backend switch.
Human-written content survives every re-run: Scope, Plan, and
learning files stay, and the `AGENTS.md` marker block is replaced in
place with everything outside it untouched.

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades/ Local Layout,
§ Bootstrap Order, and § Output Format before running.

## Self-init guard

When this directory is the SPADES framework repo itself
(`.claude-plugin/plugin.json` has `name: spades`, or
`plugins/spades/` exists at the root), abort: *"This is the SPADES
framework's own repository. Setup is for consumer repos that use
SPADES."* The framework dogfoods itself only when told explicitly
*"set up the dogfood project"*.

## Pre-Flight

### 1. The `repo` plugin

SPADES defers git operations to `/repo:init`, `/repo:branch`, and
`/repo:newbranch`:

```bash
[ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
```

`missing` → show the install block and ask via `AskUserQuestion`:
**I've installed it — re-probe** / **Skip for now** (`/spades:close`,
`/spades:deliver`, and `/spades:ship` refuse until it is installed).

```
/plugin marketplace add ChrisFmlyc/ai-skills
/plugin install repo@ai-skills
```

Skip is available only when the directory is already a git repo;
Pre-Flight 2 needs `/repo:init` otherwise. Record `found` or
`skipped`.

### 2. Git repo

```bash
git rev-parse --git-dir >/dev/null 2>&1 && echo found || echo missing
```

`found` → continue. `missing` → the repo is initialised now, since
setup scaffolds files under git's expectation that they are
committed:

- With the repo plugin `found`, announce *"No git repo here — I'll
  initialise one via `/repo:init`, then continue setup."* and run
  `/repo:init` inline. It initialises git, writes a placeholder
  README, wires `origin`, pushes `main`, and asks its own questions.
- With the repo plugin `skipped`, re-drive the Pre-Flight 1 install
  and then run `/repo:init` inline; git is initialised only through
  the repo plugin.

Re-probe after `/repo:init` returns. Still `missing` (cancelled or
failed) → abort: *"No git repo was initialised, so there's nothing to
configure yet. Re-run `/spades:setup` once you're ready; it will
initialise one via `/repo:init`."*

### 2.5. Setup worktree

Before writing configuration or scaffolds, invoke `/repo:newbranch` for
setup work (or resume the already-established worktree for this same run).
Use its returned directory for every following step and delegated writer.
Default-branch cleanliness and remote updates belong to that skill. If the
repo plugin was skipped, install it before continuing with file writes.

### 3. Existing config

```bash
[ -f .spades/config ] && echo present || echo missing
```

`missing` → fresh install; Steps 5 and 6 are skipped. `present` →
capture `current_backend`, `current_scm`, `current_project`,
`current_linear_team` / `current_linear_project`,
`current_github_remote`, `current_review_format` (default `cli` on
older configs), and `current_leads` (default `on`).

## Step 1 — Backend

With a current value, print *"Currently configured: `backend:
<value>`. The choice below replaces it — re-pick or switch."* The
recommended option is never "keep current". Ask via
`AskUserQuestion`:

- **Linear** — artefacts mirrored to Linear Issues (Project, parent
  Issue, sub-issues); requires the Linear MCP.
- **Local** — artefacts live only as Markdown under `.spades/`.

Both keep the local files canonical; Linear adds a mirror.

**Linear chosen** → probe the Linear MCP (list teams). A failed
probe (no MCP tool, 401/403, connection refused) walks the human
through the install rather than aborting:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

Scopes: default local (this project — recommended for a first run),
`--scope user`, or `--scope project` (a committed `.mcp.json`). Then
`/mcp` inside Claude Code → Linear → OAuth in the browser. Verify
with `claude mcp list` and `/mcp` (Linear connected, ~25 tools), and
re-run `/spades:setup`.

With teams listed: `AskUserQuestion` for the team, then for the
Linear Project (existing ones plus **Create new Linear Project**).
*Create new* records `team_id` and sets `create_new_project`; the
Linear Project is created at Step 8 by `/spades:newproject`'s
fan-out. Otherwise record `team_id` and `project_id`.

## Step 2 — SCM

Same "currently configured" preamble on re-run. Ask via
`AskUserQuestion`:

- **Local git** — commits to local git; with a remote,
  `/spades:ship` pushes and records the commit. Single-phase ship.
- **GitHub** — work flows through PRs; `/spades:ship` opens the PR
  and `/spades:close` finalises after the merge. Requires `gh`
  installed and authenticated.

Other SCMs follow `docs/EXTENDING-SCM.md`.

**GitHub chosen** → probe `gh auth status`. Unauthenticated →
install (`brew install gh`; `winget install --id GitHub.cli`; the
apt/dnf steps at <https://cli.github.com/manual/installation>), then
`gh auth login` (browser flow recommended; HTTPS or SSH to match the
remote), verify `gh auth status` shows the `repo` scope, and re-run
`/spades:setup`.

## Step 3 — Review format

Ask via `AskUserQuestion`: *How should SPADES present reviews and
artefacts?*

- **HTML** *(Recommended)* — every producing skill writes its `.md`
  and additionally an `.html` companion rendered from the bundled
  template and auto-opened in the browser; review happens on the
  rendered page.
- **CLI** — the `.md` only; review-form output prints to the
  terminal.

Recorded as `review_format:`. The choice changes the presentation
surface only; every flow, prompt, and decision is the same.

## Step 4 — Active project

Ask via `AskUserQuestion`, offering the existing
`.spades/projects/<slug>.md` records plus **Create a new project**;
with no records, only the latter. Record the intent and write
nothing yet:

- **Existing project** → `new_project: <slug>`; clear
  `create_new_project`.
- **Create a new project** (or `create_new_project` already set) →
  keep `new_project` unset. The project is created at Step 8, after
  the config is written, so `/spades:newproject`'s precondition
  holds.

## Step 5 — Diff and confirm

- **Fresh install** → Step 7.
- **Nothing changed** → *"Nothing changed — backend, SCM, review
  format, and active project all match. Refresh the scaffolding
  (marker block re-stamp, doc scaffold prompts)?"*
  `AskUserQuestion`: **Yes, refresh** / **Cancel — exit without
  writes**.
- **Something changed** → show the diff and confirm:

```
Detected pre-existing SPADES config. Confirm these changes
before any writes happen:

  Backend:        <current_backend>  →  <new_backend>
  SCM:            <current_scm>      →  <new_scm>
  Review format:  cli                (unchanged)
  Active project: <current_project>  (unchanged)
  Linear team:    (unset)            →  <new_linear_team>      # backend: linear
  Linear project: (unset)            →  <new_linear_project>   # backend: linear
  GitHub remote:  origin             (unchanged)               # scm: github

.spades/config and the AGENTS.md marker block will be updated.
Existing scopes, plans, and learnings on disk are never deleted
by this skill.
```

List only fields present in either config. With
`create_new_project`, the project line reads `<current_project> →
(new project, created after config is written)`.
`AskUserQuestion`: **Apply changes** (→ Step 6 when the backend
changed, else Step 7) / **Cancel — exit without writes**.

## Step 6 — Backend-switch migration

Fires only when `current_backend != new_backend`. **Read
[`reference/backend-migration.md`](reference/backend-migration.md)
and follow it.** It owns both directions and their error handling,
and returns here whether the walk ran, was skipped, or was
cancelled.

## Step 7 — Write `.spades/config`

```yaml
backend: linear            # or: local
project: <project-slug>    # unset when create_new_project; Step 8 fills it
scm: github                # or: local-git
review_format: html        # or: cli
leads: on                  # or: off — a kill switch; Leads mirror to Linear per backend:
linear:                    # backend: linear
  team_id: <uuid>
  project_id: <uuid>       # unset when create_new_project
github:                    # scm: github
  remote: origin
```

With `create_new_project` on a **fresh install**, write `project:`
unset (and `team_id` without `project_id` for Linear). On a
**re-run**, keep the existing `project:` and `linear.project_id`
until Step 8 overwrites them, so a cancelled newproject leaves the
prior active project intact. The config is on disk before Step 8;
that is what makes the inline `/spades:newproject` legal.

## Step 8 — Create the project (when `create_new_project`)

Invoke `/spades:newproject` inline as a sub-routine. It gathers
title, description, repos, and owners, writes
`.spades/projects/<slug>.md` (and the Linear Project via its
fan-out), and sets `project:` (and `linear.project_id`) in
`.spades/config`. Setup resumes with `project:` populated.

If it fails or the human cancels, `project:` stays unset: surface
*"No project was created — `.spades/config` has no active project
yet. Re-run `/spades:setup` or `/spades:newproject` to create one."*
and finish the remaining scaffolding.

## Step 9 — Write `.spades/version`

From `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (`version`)
and `${CLAUDE_PLUGIN_ROOT}/.spades/version` (`agents_version`):

```
spades_version=<plugin-version>
agents_version=<agents-version>
```

Overwrite is fine.

## Step 10 — Scaffold `.spades/`

Create when missing, empty: `projects/`, `objectives/`, `scopes/`,
`plans/`, `quick/`, `learnings/`, `reviews/`, `leads/`.

## Step 11 — Ignore transient scratch

`.spades/.tmp/` holds regenerated HTML for `/spades:status`,
`/spades:list`, `/spades:leads`, and the doc skills' previews.
Idempotently:

1. No `.gitignore` → create it with the one line `.spades/.tmp/`.
2. Already lists `.spades/.tmp` (with or without the slash) → done.
3. Otherwise append:

   ```
   # SPADES transient HTML scratch — regenerated on every status/list/intent run
   .spades/.tmp/
   ```

The rest of `.gitignore` is left as it is.

## Step 12 — `AGENTS.md` marker block

Create `AGENTS.md` with `# AGENTS.md` and a blank line when it
doesn't exist. Insert or replace the block between the markers,
stamped with the **AGENTS.md version** (`agents_version`), so the
marker reads stale only when the rules themselves changed:

```markdown
<!-- SPADES-FRAMEWORK-START v<agents-version> -->
…
<!-- SPADES-FRAMEWORK-END -->
```

Markers present (any version) → replace in place; absent → append.
Content outside the markers is untouched. **Read
[`reference/agents-md-block.md`](reference/agents-md-block.md) and
write its fenced content verbatim** between the markers; that file
is versioned by `agents_version`, so any edit to it bumps that
version.

## Step 13 — Project documentation

Four durable docs at the repo root, each owned by a facilitator
skill:

| File | Skill | Owns |
|---|---|---|
| `INTENT.md` | `/spades:intent` | Why the project exists, for whom, success, non-goals |
| `ARCHITECTURE.md` | `/spades:architecture` | How the system is built |
| `PATTERNS.md` | `/spades:patterns` | Approved conventions |
| `ANTI-PATTERNS.md` | `/spades:anti-patterns` | Explicit prohibitions |

For each, in that order:

1. **Detect** — *Missing*; *Scaffolded but unfilled* (two or more
   `<!-- Describe … -->` / `<!-- List … -->` placeholders);
   *Complete*.
2. **Complete** → print `✓ INTENT.md complete (last reviewed
   YYYY-MM-DD).` and move on.
3. **Otherwise ask** via `AskUserQuestion`: **Scaffold an empty
   template** *(recommended on a first run)* — write the
   facilitator's inline template verbatim with `last_reviewed:
   <today>`; / **Skip** — write nothing.

The facilitator skills fill the content later, when the human runs
them; Step 14 lists them as next steps.

## Step 14 — Confirm

`→` for re-run transitions, `(unchanged)` where nothing moved, `✓`
done, `○` skipped, `✗` failed. Fresh installs show chosen values
without transitions.

```
✓ Backend:        local → linear   (team: <name>, project: <name>)
✓ SCM:            local-git        (unchanged)
✓ Review format:  html
✓ Active project: spades-framework (unchanged)
✓ Migrated:       1 project, 3 scopes, 11 plans → Linear      # Step 6 walked
                  (4 learnings stayed local by design)
✓ Config:         .spades/config
✓ Version:        plugin <plugin-version>, rules <agents-version>
✓ Updated:        AGENTS.md (marker block re-stamped v2.0.0 → v<agents-version>)
✓ Created:        ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md  (templates)
○ Skipped:        INTENT.md (run /spades:intent to scaffold)

Next steps:
  /spades:intent           — fill INTENT.md with real content
  /spades:architecture     — fill ARCHITECTURE.md
  /spades:patterns         — fill PATTERNS.md
  /spades:anti-patterns    — fill ANTI-PATTERNS.md
  /spades:scope <title>    — start a new Scope
```

A skipped migration reads `○ Migration: skipped — local artefacts
stay on disk; new Linear-side work starts empty.` Keep it brief: the
human confirms correctness in ten seconds.

## Why `AGENTS.md`

`AGENTS.md` is the cross-agent convention honoured by Claude Code,
Cursor, Codex, Aider, and most agentic tools. A consumer repo gets
one operating-rules file every agent reads, and it is the only
agent file SPADES maintains.
