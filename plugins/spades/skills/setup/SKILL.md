---
name: setup
description: Configure SPADES in this repository — choose a backend (Linear MCP or local filesystem), set the active project, scaffold AGENTS.md / ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md, and write .spades/config. Use when starting fresh, when someone says "set up SPADES", "configure SPADES", "initialise SPADES", "I want to use SPADES in this repo". Re-runnable to reconfigure backend or refresh scaffolding without clobbering existing content.
version: 4.4.0
---

# /spades:setup

Configure SPADES in this repository. Every other skill assumes setup
has run and `.spades/config` exists.

**Re-runs ask every question again.** Current values appear as a
*"Currently configured: …"* context line above each
`AskUserQuestion` but never bias the recommended option. Step 2.5
diffs old vs new and requires explicit confirm before writes; Step
2.6 offers migration on backend switch. Setup never destroys
human-written content — scope / plan / learning files stay, and the
AGENTS.md marker block is replaced in place with content outside the
markers untouched.

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades/ Local Layout, and
§ Bootstrap Order before running — FRAMEWORK.md is canonical.

## Single-pass contract

`/spades:setup` is the **one** command a human runs to start using
SPADES in a repo. It completes in a **single pass** and **drives its
own prerequisites inline** — it NEVER exits to ask the human to run
another skill and come back.

- **Not a git repo?** Setup runs `/repo:init` inline (Pre-Flight 2).
- **No active project?** Setup writes `.spades/config` first (so the
  backend is on disk), then invokes `/spades:newproject` inline
  (Step 3.5).

Both edges point **one way** (`setup → /repo:init`, `setup →
/spades:newproject`) and neither points back. This is the acyclic
bootstrap contract in `FRAMEWORK.md § Bootstrap Order`; any edit
reintroducing an exit-and-come-back reopens the setup ⇄ repo:init ⇄
newproject deadlock. Don't.

## Self-Init Guard

If this directory IS the SPADES framework repo
(`.claude-plugin/plugin.json` has `name: spades`, or
`plugins/spades/` exists at the root), abort:

> This is the SPADES framework's own repository. Setup is for
> consumer repos that want to *use* SPADES, not for the framework
> itself.

(The framework dogfoods itself only when explicitly told *"set up
the dogfood project"*.)

## Pre-Flight

### 1. Prerequisite plugin: `ai-skills/repo`

SPADES depends on `/repo:sync` and `/repo:branch`.

```bash
[ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
```

`found` → continue. `missing` → show the install block, then
`AskUserQuestion`: *I've installed it — re-probe* / *Skip for now
(close/do/ship will refuse until installed)*. Re-probe still
`missing` → re-show and re-ask; only advance on explicit Skip.

```
/plugin marketplace add ChrisFmlyc/ai-skills
/plugin install repo@ai-skills
```

**Skip is conditional** — safe only when this directory is already a
git repo, where the plugin is merely deferred. If step 2 finds no
git repo, `/repo:init` is required *now*, so step 2 re-drives this
install instead. Record `found` or `skipped` so step 2 can branch.

### 2. Git repo (auto-init — never bounce)

```bash
git rev-parse --git-dir >/dev/null 2>&1 && echo found || echo missing
```

`found` → continue to Pre-Flight 3. `missing` → the repo must be
bootstrapped **now**, before setup can scaffold committable files:

- **Repo plugin `found`** → **run `/repo:init` inline.** Do not
  abort and hand off. Announce in one line (*"No git repo here —
  I'll initialise one via `/repo:init`, then continue setup."*) and
  invoke it. It initialises git, writes a placeholder README, wires
  `origin`, pushes `main`, and asks its own questions — that is
  `/repo:init`'s interaction, not a bounce back to setup.
- **Repo plugin `skipped`** → the skip doesn't apply when git is
  missing, because `/repo:init` is exactly what's needed. Re-drive
  step 1's install, then run `/repo:init` inline. If the human still
  refuses, abort per below — never hand-roll `git init`, which would
  violate the defer-to-`repo` rule.

Re-probe after `/repo:init` returns. `found` → continue. `missing`
(cancelled, declined, or failed) → **only now** abort: *"No git repo
was initialised, so there's nothing to configure yet. Re-run
`/spades:setup` once the repo exists (it will initialise one for you
via `/repo:init`)."* A terminal stop, not a bounce.

`/repo:init` never calls back into SPADES — the edge is
one-directional.

### 3. Capture existing config (re-run context)

```bash
[ -f .spades/config ] && echo present || echo missing
```

`missing` (fresh install) → all `current_*` stay unset; Steps 2.5
and 2.6 are skipped. `present` → read and capture `current_backend`,
`current_scm`, `current_project`, `current_linear_team` /
`current_linear_project` (if Linear), `current_github_remote` (if
GitHub), and `current_review_format` (defaults to `cli` on older
configs). These feed the *"Currently configured: …"* preambles and
the Step 2.5 diff.

## Step 1 — Backend

If `current_backend` is set, print above the question (never
recommend "Keep current"):

> *Currently configured: `backend: <current_backend>`. The choice
> below replaces it. Re-pick the same value if nothing's changed,
> or switch — your call, but please make it explicitly.*

`AskUserQuestion`:

- **`Linear`** — artefacts live as Linear Issues (Project, parent
  Issue, sub-issues). Requires Linear MCP.
- **`Local`** — artefacts live as Markdown under `.spades/`. No
  external tracker; full audit trail in-repo.

No "keep current" shortcut on re-run. **Local** needs no external
verification.

### If Linear was chosen

**Probe Linear MCP** (teams-list call). At least one team → bind
below.

**Probe fails** (no MCP tool, 401/403, connection refused) → don't
abort; walk the human through install:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

Scopes: default **local** (this project — recommended for a first
run), `--scope user` (every project on this machine), `--scope
project` (committed `.mcp.json`, shared). Then the human runs `/mcp`
inside Claude Code, picks Linear, and completes OAuth in the
browser. Verify with `claude mcp list` outside, `/mcp` inside —
Linear should show connected with ~25 tools. Re-run `/spades:setup`
and pick Linear again.

**Bind team and project** (probe succeeded):

1. `AskUserQuestion`: which team? (from the probe).
2. `AskUserQuestion`: which Linear Project? (existing under that
   team, plus *Create new Linear Project*).
3. *Create new* → **do not exit.** Record `team_id`, set
   `create_new_project`; the Linear Project is created in Step 3.5
   when setup invokes `/spades:newproject` inline, whose Linear
   fan-out creates it and writes the ID back to config.
4. Otherwise record `team_id` + `project_id` for Step 3.

## Step 1.5 — SCM

If `current_scm` is set, print *"Currently configured: `scm:
<current_scm>`. The choice below replaces it. Re-pick or switch."*

`AskUserQuestion`:

- **`Local git`** — commits to local git only. With a remote,
  `/spades:ship` pushes but opens no PR. Single-phase ship.
- **`GitHub`** — work flows through GitHub PRs; `/spades:ship` runs
  two-phase publish. Requires `gh` installed + authenticated.
- (Future: GitLab, Bitbucket — see `docs/EXTENDING-SCM.md`.)

No "keep current" shortcut. **Local git** needs no verification.

**If GitHub was chosen**, probe `gh auth status`. Authenticated →
continue. Otherwise don't abort: install via `brew install gh`
(macOS), `winget install --id GitHub.cli` (Windows), or the
apt/dnf instructions at <https://cli.github.com/manual/installation>.
Then `gh auth login` → pick GitHub.com / Enterprise, authenticate by
browser (recommended) or PAT, and choose HTTPS or SSH to match the
remote. Verify `gh auth status` includes `repo` scope, then re-run
`/spades:setup` and pick GitHub again.

## Step 1.7 — Review format

If `current_review_format` is set, print the same
"Currently configured / re-pick or switch" preamble.

`AskUserQuestion` — *How should SPADES present reviews and produce
artefacts?*

- **HTML — auto-opens nicely formatted pages in your browser**
  *(Recommended)*. Artefacts under `.spades/` are written as
  `.html`; review-form output auto-opens via `open` / `xdg-open` /
  `start`.
- **CLI — pastes plain-text/markdown output to the terminal**.
  Artefacts as `.md`; review output to CLI.

Recorded as `review_format:` in Step 3. The choice toggles
per-skill rendering only — the flow is identical.

## Step 2 — Active project

If `current_project` is set, print the same preamble.

`AskUserQuestion`: existing `.spades/projects/<slug>.md` records →
offer them plus *Create a new project*. No records → *Create a new
project* is the only option (the fresh-install path, and — with
`create_new_project` from Step 1's Linear branch — the
create-new-Linear-Project path).

Both outcomes are **deferred**; Step 2 records intent only and
writes nothing:

- **Existing project picked** → record the slug into `new_project`
  for Step 2.5's diff. Clear `create_new_project`.
- **Create a new project** (or `create_new_project` already set) →
  set `create_new_project`, leave `new_project` unset. **Do not
  exit, do not bounce to `/spades:newproject`.** It is created in
  Step 3.5, after Step 3 writes config — so the backend is on disk
  and newproject's precondition holds.

Do **not** write `.spades/config` yet.

## Step 2.5 — Diff & confirm

Diff captured `current_*` against the new answers.

- **Fresh install** (no config existed) → skip the display, go to
  Step 3.
- **Nothing changed** → print *"Nothing changed — backend, SCM, and
  active project all match the existing config. Continue to refresh
  scaffolding (AGENTS.md marker block re-stamp, INTENT.md scaffold
  prompt, etc.)?"* then `AskUserQuestion`: *Yes, refresh* / *Cancel —
  exit without writes*.
- **Something changed** → show the diff:

```
Detected pre-existing SPADES config. Confirm these changes
before any writes happen:

  Backend:        <current_backend>  →  <new_backend>
  SCM:            <current_scm>      →  <new_scm>
  Active project: <current_project>  (unchanged)
  Linear team:    (unset)            →  <new_linear_team>      # if linear
  Linear project: (unset)            →  <new_linear_project>   # same
  GitHub remote:  origin             (unchanged)               # if scm: github

The local `.spades/config` and AGENTS.md marker block will be
updated. Existing scopes / plans / learnings on disk are NEVER
deleted by this skill.
```

Mark `(unchanged)` where new = current, and list only fields present
in either config. When `create_new_project` is set, the
Active-project line reads `<current_project> → (new project, created
after config is written)` — the slug doesn't exist until Step 3.5.

`AskUserQuestion`: **Apply changes** (→ Step 2.6 if `backend` is
changing, else Step 3) / **Cancel — exit without writes**.

## Step 2.6 — Backend-switch migration

Fires **only** when `current_backend != new_backend`. SCM, project,
or Linear team/project changes alone skip to Step 3.

**Read [`reference/backend-migration.md`](reference/backend-migration.md)
and follow it.** It owns both directions — the `local → linear`
artefact walk with its status maps, the `linear → local` pull, and
the error handling for each. It returns here for Step 3 whether the
walk ran, was skipped, or was cancelled.

## Step 3 — Write `.spades/config`

```yaml
backend: linear            # or: local
project: <project-slug>    # unset when create_new_project (Step 3.5 fills it)
scm: github                # or: local-git
review_format: html        # or: cli  (defaults to cli on older configs)
linear:                    # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>       # unset when create_new_project
github:                    # only when scm: github
  remote: origin
```

- **Existing project picked** → write `project:` (and, for Linear,
  `linear.project_id`).
- **`create_new_project` set** — *fresh install*: write config now
  with `project:` unset and, for Linear, `team_id` written but
  `project_id` unset. *Re-run*: **keep** the existing `project:` and
  `linear.project_id` — do NOT blank them. Step 3.5 overwrites them
  on success, so a cancelled newproject leaves the prior active
  project intact.

Either way **the config MUST be on disk before Step 3.5** — that
on-disk backend is what makes the inline `/spades:newproject` legal.

Re-run safety: preserve values the human didn't change; never blank
a field they still depend on.

## Step 3.5 — Create the project (inline, only when `create_new_project`)

Skip entirely when an existing project was picked.

Invoke `/spades:newproject` **inline, as a sub-routine of this run**.
Config is on disk with the settled backend and — for Linear —
`team_id`, so its precondition holds. It gathers title / description
/ repos / owners, writes `.spades/projects/<slug>.md` (creating the
Linear Project via its fan-out where applicable), and sets
`.spades/config`'s `project:` (and `linear.project_id`) in its own
Step 4. Setup then resumes here with `project:` populated.

One-directional edge — newproject never bounces back, because setup
guaranteed its precondition before invoking it.

If it fails or the human cancels mid-flow, config is left with
`project:` unset. Surface that clearly (*"No project was created —
`.spades/config` has no active project yet. Re-run `/spades:setup`
or run `/spades:newproject` to create one."*) and still finish the
remaining scaffolding. Setup does not loop.

## Step 4 — Write `.spades/version`

Read the plugin version from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` `"version"` and
the AGENTS.md version from `${CLAUDE_PLUGIN_ROOT}/.spades/version`
(`agents_version=`), then write both to the consumer's
`.spades/version`:

```
spades_version=<plugin-version>
agents_version=<agents-version>
```

Idempotent — overwrite is fine.

## Step 5 — Scaffold `.spades/` subdirectories

Create if missing, no files inside: `projects/`, `scopes/`,
`plans/`, `learnings/`, `reviews/`.

## Step 5.5 — Ignore transient HTML scratch

`.spades/.tmp/` holds regenerated HTML for `/spades:status`,
`/spades:list`, and `/spades:intent`, and must not be committed.
Idempotent:

1. No `.gitignore` → create it with one line: `.spades/.tmp/`.
2. Already lists `.spades/.tmp` (with or without trailing `/`) → do
   nothing.
3. Otherwise append:

   ```
   # SPADES transient HTML scratch — regenerated on every status/list/intent run
   .spades/.tmp/
   ```

Append-only — never rewrite or reorder the rest of `.gitignore`.

## Step 6 — AGENTS.md (idempotent marker block)

If `AGENTS.md` doesn't exist at the repo root, create it with one
line `# AGENTS.md` plus a blank line.

Insert or replace the block between these markers, stamping the
**AGENTS.md version** (`agents_version` from `.spades/version`) —
not the plugin version — so the marker only reads stale when the
rules themselves changed:

```markdown
<!-- SPADES-FRAMEWORK-START v<agents-version> -->
…the content below…
<!-- SPADES-FRAMEWORK-END -->
```

Markers present (any version) → replace in place. Absent → append.
**Never** edit content outside the markers.

**Read [`reference/agents-md-block.md`](reference/agents-md-block.md)
and write its fenced content verbatim** between the markers. That
file is the template; it is versioned by `agents_version`, so any
edit to it must bump that version.

## Step 7 — Project documentation (per-file ask)

Four durable docs at the repo root, each owned by a facilitator
skill:

| File | Skill | Owns |
|------|-------|------|
| `INTENT.md` | `/spades:intent` | Why the project exists, for whom, success, non-goals |
| `ARCHITECTURE.md` | `/spades:architecture` | How the system is built (tech, components, data flow, security, ops) |
| `PATTERNS.md` | `/spades:patterns` | Approved conventions (code organisation, error handling, testing, naming) |
| `ANTI-PATTERNS.md` | `/spades:anti-patterns` | Explicit prohibitions ("we don't do X") |

For each, in that order:

1. **Detect state** — *Missing*; *Scaffolded but unfilled* (exists,
   ≥ 2 `<!-- Describe … -->` / `<!-- List … -->` placeholders); or
   *Complete* (< 2 placeholders).
2. **Complete → skip.** Print one line — `✓ INTENT.md complete (last
   reviewed YYYY-MM-DD).` Don't prompt, re-scaffold, or invoke the
   skill.
3. **Otherwise ask** via `AskUserQuestion`:

   > *<filename> — how would you like to handle this?*
   >
   > - **Scaffold an empty template** *(recommended for the first
   >   run)* — write the facilitator's inline template with
   >   `last_reviewed: <today>`. Asks no content questions.
   > - **Skip** — write nothing; the file stays missing.

4. **Template content** comes from each facilitator SKILL.md's
   *"Inline … Template"* section, written verbatim with
   `last_reviewed: <today>` so staleness detection doesn't
   immediately flag: `/spades:intent`, `/spades:architecture`,
   `/spades:patterns`, `/spades:anti-patterns`.

**Setup never invokes facilitator skills inline.** Step 9's brief
lists them as next steps for the human to run when they want real
content.

**Re-run safety:** each file is re-classified. Previously unfilled
and now Complete → skip silently. Previously Complete → stays
skipped. Previously Skipped and still missing → asked again.

## Step 9 — Confirm

Print a concise summary. Show `→` for re-run transitions, append
`(unchanged)` where nothing moved. `✓` done, `○` skipped, `✗`
failed.

```
✓ Backend:        local → linear   (team: <name>, project: <name>)
✓ SCM:            local-git        (unchanged)
✓ Active project: spades-framework (unchanged)
✓ Migrated:       1 project, 3 scopes, 11 plans → Linear      # only if Step 2.6 walked
                  (4 learnings stayed local by design)
✓ Config:         .spades/config
✓ Version:        plugin <plugin-version>, rules <agents-version>
✓ Updated:        AGENTS.md (marker block re-stamped from v2.0.0 → v<agents-version>)
✓ Created:        ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md  (templates)
○ Skipped:        INTENT.md (re-run /spades:intent to scaffold)

Next steps:
  /spades:intent           — fill INTENT.md with real content
  /spades:architecture     — fill ARCHITECTURE.md with real content
  /spades:patterns         — fill PATTERNS.md with real content
  /spades:anti-patterns    — fill ANTI-PATTERNS.md with real content
  /spades:newproject       — if you haven't created one yet
  /spades:scope <title>    — start a new Scope
```

Suppress lines for files already Complete; keep those that were
Scaffolded-but-unfilled or Missing. If Step 2.6 ran on *Skip
migration*, the Migrated line becomes:

```
○ Migration:      skipped — local artefacts stay on disk; new
                  Linear-side work starts empty.
```

On fresh installs `(unchanged)` doesn't apply — show chosen values
without transitions. Be brief: the human should confirm correctness
in 10 seconds.

## Why AGENTS.md, not CLAUDE.md

`AGENTS.md` is the cross-agent convention — Claude Code, Cursor,
Codex, Aider and most agentic tools honour it. A consumer repo gets
one operating-rules file every agent reads, not one per vendor.
Don't write `CLAUDE.md`, `CURSOR.md`, or similar per-agent variants.
