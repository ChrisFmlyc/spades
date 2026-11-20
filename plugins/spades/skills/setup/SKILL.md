---
name: setup
description: Configures SPADES in a repository by choosing the backend, SCM (local git, GitHub or GitLab), review format and active project, writing .spades/config, and scaffolding agent rules and project documents. Checks that the `repo` plugin and the chosen SCM's CLI (`gh` or `glab`) are installed and authenticated, and with the Linear backend can register the Linear MCP server. Use for initial setup, reconfiguration or a scaffolding refresh, including "set up SPADES", "configure SPADES", "initialise SPADES", or "I want to use SPADES in this repo". Preserves existing content on re-runs.
version: 4.16.0
---

# /spades:setup

Configure SPADES in this repository. Every other skill assumes setup
has run and `.spades/config` exists.

Setup invokes `/repo:init` for a missing git repo (Pre-Flight 2) and
`/spades:newproject` for a missing project after writing the config
(Step 8), following `docs/FRAMEWORK.md § Bootstrap Order`.

Steps 1 to 4 are one question each, asked on every run; the
recorded value is the human's answer to it, even when
the repo or the current config makes it look obvious. Re-runs show
the current value as context above each prompt. Step 5 diffs old against new and confirms
before any write; Step 6 offers migration on a backend switch.
Human-written content survives every re-run: Scope, Plan, and
learning files stay, and the `AGENTS.md` marker block is replaced in
place with everything outside it untouched.

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades/ Local Layout,
§ Bootstrap Order, and § Output Format before running.

## Self-init guard

In the SPADES framework repo itself (`.claude-plugin/plugin.json` has
`name: spades`, or `plugins/spades/` exists at the root), setup runs
only on an explicit request to *"set up the dogfood project"*. Any
other request there aborts: *"This is the SPADES framework's own
repository. Setup is for consumer repos that use SPADES."*

## Pre-Flight

### 1. The `repo` plugin

SPADES defers git operations to `/repo:init`, `/repo:branch`, and
`/repo:newbranch`:

```bash
[ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
```

`missing` → show the install block and re-probe once the human has
installed it:

```
/plugin marketplace add ChrisFmlyc/ai-skills
/plugin install repo@ai-skills
```

### 2. Git repo

```bash
git rev-parse --git-dir >/dev/null 2>&1 && echo found || echo missing
```

`found` → continue. `missing` → announce *"No git repo here — I'll
initialise one via `/repo:init`, then continue setup."* and run
`/repo:init` inline. It initialises git, writes a placeholder README,
wires `origin`, pushes `main`, and asks its own questions.

Re-probe after `/repo:init` returns. Still `missing` (cancelled or
failed) → abort: *"No git repo was initialised, so there's nothing to
configure yet. Re-run `/spades:setup` once you're ready; it will
initialise one via `/repo:init`."*

### 2.5. Setup worktree

Before writing configuration or scaffolds, invoke `/repo:newbranch` for
setup work (or resume the already-established worktree for this same run).
Use its returned directory for every following step and delegated writer.
Default-branch cleanliness and remote updates belong to that skill.

### 3. Existing config

```bash
[ -f .spades/config ] && echo present || echo missing
```

`missing` → fresh install; Steps 5 and 6 are skipped. `present` →
capture `current_backend`, `current_scm`, `current_project`,
`current_linear_team` / `current_linear_project`,
`current_github_remote` / `current_gitlab_remote`, the `gitlab:` block's
`host`, `project` and `review_bots`,
`current_review_format` (default `cli`), and `current_leads` (default
`on`).

## Step 1 — Backend

With a current value, print *"Currently configured: `backend:
<value>`. The choice below replaces it — re-pick or switch."* The
recommended option is never "keep current". Ask:

- **Linear** — artefacts mirrored to Linear Issues (Project, parent
  Issue, sub-issues); requires the Linear MCP.
- **Local** — artefacts live only as Markdown under `.spades/`.

Both keep the local files canonical; Linear adds a mirror.

**Linear chosen** → probe the Linear MCP (list teams). A failed
probe (no MCP tool, 401/403, connection refused) walks the human
through the install:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

Scopes: default local (this project — recommended for a first run),
`--scope user`, or `--scope project` (a committed `.mcp.json`). Then
`/mcp` inside Claude Code → Linear → OAuth in the browser. Verify
with `claude mcp list` and `/mcp` (Linear connected, ~25 tools), and
re-run `/spades:setup`.

With teams listed: ask for the team with the picker of
`docs/FRAMEWORK.md § Target Resolution` step 3, then for the Linear
Project (up to three existing ones plus **Create new Linear Project**;
a typed name is matched against the team's Projects as in step 4, so
the human confirms one Project before its ID is recorded).
Record `team_id`, and the chosen Project's ID as `project_id` or, for
*Create new*, set `create_linear_project`; Step 8 creates that Linear
Project. Step 4 pairs it with the active project.

## Step 2 — SCM

Same "currently configured" preamble on re-run. An SCM's remote is
the one configured for it (`github.remote` for GitHub, `gitlab.remote`
for GitLab), else `origin`, else the sole remote. The current SCM's
remote (on a fresh install, `origin` or the sole remote) marks one
option *(Recommended)* by its URL: a `github.com` host recommends
GitHub, a host containing `gitlab` recommends GitLab, and no remote
recommends Local git; any other host marks none. Ask:

- **Local git** — commits to local git; with a remote,
  `/spades:ship` pushes and records the commit. Single-phase ship.
- **GitHub** — work flows through pull requests; `/spades:ship` opens
  the PR, `/spades:close` finalises after the merge, and Leads are filed
  as GitHub issues. Requires `gh` installed and authenticated.
- **GitLab** — the same flow through merge requests on gitlab.com or a
  self-managed instance, with Leads filed as GitLab issues. Requires
  `glab` installed and authenticated.

Other SCMs follow `docs/EXTENDING-SCM.md`. GitHub records its remote
as `github.remote`, GitLab as `gitlab.remote`.

**GitHub chosen** → probe `gh auth status`. Unauthenticated →
install (`brew install gh`; `winget install --id GitHub.cli`; the
apt/dnf steps at <https://cli.github.com/manual/installation>), then
`gh auth login` (HTTPS or SSH to match the remote), verify
`gh auth status` shows the `repo` scope, and re-run `/spades:setup`.

**GitLab chosen** → **read
[`reference/gitlab.md`](reference/gitlab.md) and follow it.** It
returns `gitlab.host`, `gitlab.project` and `gitlab.review_bots` for
Step 7.

## Step 3 — Review format

Ask: *How should SPADES present reviews and
artefacts?*

- **HTML** *(Recommended)* — every producing skill writes its `.md`
  and additionally an `.html` companion rendered from the bundled
  template; review happens on the rendered page in the browser.
- **CLI** — the `.md` only; review happens in the CLI review pane
  (`docs/FRAMEWORK.md § CLI review pane`).

Recorded as `review_format:`. The choice changes the presentation
surface only; every flow, prompt, and decision is the same.

## Step 4 — Active project

Ask, offering up to three existing
`.spades/projects/<slug>.md` records, most recently updated first,
plus **Create a new project** (a typed slug selects any other);
with no records, only the latter. Record the intent and write
nothing yet:

- **Existing project** → `new_project: <slug>`; clear
  `create_new_project`.
- **Create a new project** → set `create_new_project` and keep
  `new_project` unset. The project is created at Step 8, after
  the config is written, so `/spades:newproject`'s precondition
  holds.

With `backend: linear`, the active project's `linear_project_id` and
the config's `linear.project_id` are the same Linear Project. A new
project gets Step 1's Linear Project at Step 8. For an existing
record, its `linear_project_id` decides:

- **Step 1's Project, or none** → Step 1's answer stands; Step 8
  writes it to a record without one.
- **Another Project** (any, when Step 1 chose *Create new*) → ask:
  **Use `<its Linear Project>`** *(Recommended)* — the Project its
  Scopes mirror to; record its ID as `project_id` and clear
  `create_linear_project` / **Choose another project** — ask this
  step again.

## Step 5 — Diff and confirm

- **Fresh install** → Step 7.
- **Nothing changed** → *"Nothing changed — backend, SCM, review
  format, and active project all match. Refresh the scaffolding
  (marker block re-stamp, doc scaffold prompts)?"*
  Ask: **Yes, refresh** / **Cancel — exit without
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
  GitLab remote:  origin             (unchanged)               # scm: gitlab
  GitLab project: gitlab.com/acme/app  (unchanged)             # scm: gitlab
  Review bots:    (none)             →  acme-coderabbit (coderabbit), GitLabDuo (duo)   # scm: gitlab

.spades/config and the AGENTS.md marker block will be updated.
Existing scopes, plans, and learnings on disk are never deleted
by this skill.
```

List only fields present in either config. With
`create_new_project`, the project line reads `<current_project> →
(new project, created after config is written)`, and with
`create_linear_project` the Linear project line reads
`<current_linear_project> → (new Linear Project, created after config
is written)`.
Ask: **Apply changes** (→ Step 6 when the backend
changed, else Step 7) / **Cancel — exit without writes**.

## Step 6 — Backend-switch migration

Fires only when `current_backend != new_backend`. **Read
[`reference/backend-migration.md`](reference/backend-migration.md)
and follow it.** It owns both directions and their error handling.
Continue to Step 7 after completion or Skip; cancelling the backend switch
returns to Step 1.

## Step 7 — Write `.spades/config`

```yaml
backend: linear            # or: local
project: <project-slug>
scm: github                # or: gitlab, local-git
review_format: html        # or: cli
leads: on                  # or: off — a kill switch; Leads mirror to Linear per backend: and to GitHub or GitLab issues per scm:
linear:                    # backend: linear
  team_id: <uuid>
  project_id: <uuid>
github:                    # scm: github
  remote: origin
gitlab:                    # scm: gitlab
  remote: origin
  host: gitlab.com          # the remote's host
  project: acme/app         # the project path on that host
  review_bots:              # empty list when the project has none
    - username: acme-coderabbit
      kind: coderabbit      # or: greptile, duo, generic
```

`project:` and `linear.project_id` are written as a pair: the active
project and its Linear Project. For an existing project, write its
slug and the `project_id` Steps 1 and 4 recorded, with no `project_id`
while `create_linear_project` waits for Step 8. With
`create_new_project`, Step 8 writes both: a **fresh install** writes
`project:` unset (and `team_id` without `project_id` for Linear), and
a **re-run** keeps the existing `project:` and `linear.project_id`
until Step 8 overwrites them, so a cancelled newproject leaves the
prior active project intact.

## Step 8 — Create or bind the project

Runs with `create_new_project`, or with `backend: linear` when the
active project's record has no `linear_project_id`.

**A new project** → invoke `/spades:newproject` inline as a
sub-routine, passing Step 1's `project_id`, when recorded, as the
Linear Project to bind. It gathers title, description, repos, and
owners, writes `.spades/projects/<slug>.md`, binds that Linear Project
or creates one through its fan-out, and sets `project:` (and
`linear.project_id`) in `.spades/config`. Setup resumes with
`project:` populated.

If creation fails or the human cancels, report the retained state and
finish the remaining scaffolding. A fresh install has no active project;
a re-run keeps the prior project per Step 7. Point to `/spades:setup` or
`/spades:newproject` to retry creation.

**An existing record without `linear_project_id`** → with
`create_linear_project`, create the Linear Project on `team_id` with
the record's title and description through the Linear MCP, and record
its ID as `project_id` and `linear.project_id`. Write `project_id` to
the record as `linear_project_id`, set its `updated:` to today, and
append `- YYYY-MM-DD: Bound to Linear Project <project_id>.` to its
Audit Trail. A failed create leaves the record and config without a
Linear Project: report it and point to `/spades:setup` to retry.

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
write its fenced content verbatim** between the markers.

## Step 13 — Project documentation

Five durable docs at the repo root, each owned by a facilitator
skill:

| File | Skill | Owns |
|---|---|---|
| `INTENT.md` | `/spades:intent` | Why the project exists, for whom, success, non-goals |
| `ARCHITECTURE.md` | `/spades:architecture` | How the system is built |
| `PATTERNS.md` | `/spades:patterns` | Approved conventions |
| `ANTI-PATTERNS.md` | `/spades:anti-patterns` | Explicit prohibitions |
| `REVIEW.md` | `/spades:review-rules` | How a code change is reviewed: what blocks, what is noise, where a person signs off |

For each, in that order:

1. **Detect** — *Missing*; *Scaffolded but unfilled* (two or more
   `<!-- Describe … -->` / `<!-- List … -->` placeholders);
   *Complete*. `REVIEW.md` is *Missing* or *Complete*: its scaffold
   carries working defaults.
2. **Complete** → print `✓ INTENT.md complete (last reviewed
   YYYY-MM-DD).` and move on.
3. **Otherwise ask**: **Scaffold the template** *(recommended on a
   first run)* — write the facilitator's inline template verbatim
   with `last_reviewed: <today>`; / **Skip** — write nothing. For
   `REVIEW.md` the template is the SPADES default review rules, in
   force from the first review.

The facilitator skills fill or tune the content later, when the human
runs them; Step 14 lists them as next steps.

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
✓ Created:        ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md, REVIEW.md  (templates)
○ Skipped:        INTENT.md (run /spades:intent to scaffold)

Next steps:
  /spades:intent           — fill INTENT.md with real content
  /spades:architecture     — fill ARCHITECTURE.md
  /spades:patterns         — fill PATTERNS.md
  /spades:anti-patterns    — fill ANTI-PATTERNS.md
  /spades:review-rules     — tune REVIEW.md's default review rules
  /spades:scope <title>    — start a new Scope
```

A skipped migration reads `○ Migration: skipped — local artefacts
stay on disk; new Linear-side work starts empty.`

## Why `AGENTS.md`

`AGENTS.md` is the cross-agent convention honoured by Claude Code,
Cursor, Codex, Aider, and most agentic tools. A consumer repo gets
one operating-rules file every agent reads, and it is the only
agent file SPADES maintains.
