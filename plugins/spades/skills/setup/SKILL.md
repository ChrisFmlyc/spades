---
name: setup
description: Configure SPADES in this repository — choose a backend (Linear MCP or local filesystem), set the active project, scaffold AGENTS.md / ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md, and write .spades/config. Use when starting fresh, when someone says "set up SPADES", "configure SPADES", "initialise SPADES", "I want to use SPADES in this repo". Re-runnable to reconfigure backend or refresh scaffolding without clobbering existing content.
version: 3.0.1
---

# /spades:setup

You are configuring SPADES in the current repository. This is the entry
point: every other skill assumes setup has been run and that
`.spades/config` exists.

**Setup re-runs the full interview every time** — same questions on a
fresh install and on a re-run, no short-cuts based on existing state.
Current values are surfaced as context above each question
(*"Currently configured: …"*) but never bias the recommended option;
the human re-engages with every choice. Before writing any changes,
Step 2.5 presents a diff and requires explicit confirmation. When the
human switches backend, Step 2.6 offers AI-assisted migration of
existing artefacts (local → Linear or Linear → local). Setup never
destroys human-written content — scope/plan/learning files on disk
stay where they are; the AGENTS.md marker block is replaced in
place, content outside the markers is untouched.

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades/ Local Layout before
running. The schemas below are mirrors of that contract; FRAMEWORK.md
is canonical.

## Self-Init Guard

If the current working directory IS the SPADES framework repo itself
(its `package.json` / `.claude-plugin/plugin.json` has `name: spades`
or the `plugins/spades/` directory exists at the root), abort with:

> This is the SPADES framework's own repository. Setup is for consumer
> repositories that want to *use* SPADES, not for the framework itself.

The framework dogfoods itself by running setup against its own
`plugins/spades/` directory — but you only do that when explicitly told
"set up the dogfood project".

## Pre-Flight

### Prerequisite plugin check (`ai-skills/repo`)

SPADES depends on the `repo` plugin from the **`ai-skills`** Claude
Code marketplace for two slash commands:

- `/repo:sync` — post-merge git cleanup, called before `/spades:close`.
- `/repo:branch` — branch-naming guardrail, enforces the prefix list
  and the no-commits-on-main rule that `/spades:do`, `/spades:ship`,
  and `/spades:close` all rely on.

Probe whether the plugin is already installed:

```bash
[ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
```

- **`found`** — proceed to Step 1. (The plugin's commands are
  available; no further action.)
- **`missing`** — print the install guide below and ask via
  `AskUserQuestion`:
  - *I've installed it — re-probe and continue.*
  - *Skip this for now — I'll install later. (Setup continues, but
    `/spades:close`, `/spades:do`, and `/spades:ship` will refuse to
    run until the `repo` plugin is installed.)*

### Install guide — `ai-skills` marketplace + `repo` plugin

The marketplace lives at
[`github.com/ChrisFmlyc/ai-skills`](https://github.com/ChrisFmlyc/ai-skills).
Install both the marketplace and the `repo` plugin from inside
Claude Code:

```
/plugin marketplace add ChrisFmlyc/ai-skills
/plugin install repo@ai-skills
```

After install, verify by running `/repo:sync` or
`/repo:branch` — Claude Code should recognise the slash commands.

If the human picks "I've installed it", re-run the probe before
continuing. If it still reports `missing`, re-show the install guide
and ask again — do not advance with the prerequisite unsatisfied
unless the human explicitly chose "Skip for now".

### Git repo check

SPADES expects the working directory to already be a git repository.
Scaffolded files (`AGENTS.md`, `ARCHITECTURE.md`, `.spades/config`,
etc.) are intended to be committed; the AGENTS.md marker block
carries a version stamp; the dogfood AGENTS.md rule explicitly tells
agents to defer to the `repo` plugin for git operations. None of
that works against a directory that hasn't been `git init`'d.

Probe:

```bash
git rev-parse --git-dir >/dev/null 2>&1 && echo found || echo missing
```

- **`found`** → proceed to Step 1.
- **`missing`** → abort with:

  > *This directory isn't a git repository yet. Run `/repo:init`
  > first — it initialises git, commits a placeholder README, wires
  > origin, and pushes to `main`. Once that's done, re-invoke
  > `/spades:setup` to configure SPADES on top.*

  Do not auto-run `/repo:init`. The human invokes it explicitly so
  they can confirm origin URL, branch name preferences, and any
  pre-init filesystem state. SPADES setup resumes only after
  `/repo:init` has completed and the human re-runs the slash
  command.

This belt-and-braces check complements the AGENTS.md operating rule
("defer to the `repo` plugin for git operations") below: the rule
tells *agents* what to do; this probe is the *mechanical* enforcement
at setup time so a brand-new-repo flow can't accidentally produce
SPADES files outside version control.

### Capture existing config (re-run context)

Before asking any questions, capture the current state of
`.spades/config` (if it exists) into context variables. The captured
values are surfaced **as context** in each subsequent question — they
do NOT route the flow or bias the recommended option. The whole point
of re-running setup is to re-engage with each choice, not to
short-circuit on previous answers.

Probe:

```bash
[ -f .spades/config ] && echo present || echo missing
```

- **`missing`** (fresh install) — all context variables stay unset.
  Steps 1, 1.5, 2 ask their questions without pre-fill context.
  Step 2.5's diff display is skipped (no pre-existing state to
  diff against). Step 2.6 migration is skipped (nothing to migrate).
- **`present`** — read the file and capture:
  - `current_backend` — `linear` or `local`.
  - `current_scm` — `github` or `local-git`.
  - `current_project` — active project slug.
  - `current_linear_team` — UUID if `current_backend == linear`.
  - `current_linear_project` — UUID if `current_backend == linear`.
  - `current_github_remote` — remote name if `current_scm == github`.
  - `current_review_format` — `cli` or `html` (defaults to `cli` if
    the field is absent in older configs).

These variables flow into Steps 1, 1.5, 2 as a *"Currently
configured: X"* context line above each `AskUserQuestion`. They also
feed Step 2.5's diff and Step 2.6's migration walk.

## Step 1 — Backend Selection

If `current_backend` is set (re-run case), print a context line
above the question — never recommend "Keep current":

> *Currently configured: `backend: <current_backend>`. The choice
> below replaces it. Re-pick the same value if nothing's changed,
> or switch — your call, but please make it explicitly.*

Ask the human which backend they want, via `AskUserQuestion`:

- **`Linear`** — artefacts live as Linear Issues (Project, parent Issue,
  sub-issues). Requires the Linear MCP to be configured. The skill will
  verify Linear MCP is callable before committing.
- **`Local`** — artefacts live as Markdown files under `.spades/`. No
  external tracker needed. Easiest to start; full audit trail in-repo.

Whichever the human picks is what gets written. Re-runs use the
same two options — no "keep current" shortcut — so the human always
re-engages with the choice.

### If Linear was chosen

#### Probe the Linear MCP

Probe Linear MCP with a teams list call. If it returns at least one
team, the MCP is reachable — continue to **Bind team and project**
below.

#### If the probe fails — guide the install, don't abort

If the probe fails (no Linear MCP tool available in this session,
401/403, connection refused, etc.), the Linear MCP isn't configured
yet. Don't abort — walk the human through installing it.

Tell the human something like:

> The Linear MCP isn't installed in this Claude Code session yet.
> Setup needs it to read teams and bind this repo to a Linear
> Project. Two minutes to install. Here's how.

Then present the install guide below.

##### 1. Install the Linear MCP server

Linear ships an **officially hosted remote MCP server** at
`https://mcp.linear.app/mcp`. It uses OAuth 2.1 in the browser, so
there are no API keys to manage. From a terminal outside Claude Code,
run:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

That writes the server into Claude Code's local config. The default
scope is **local** (this project only). If the human wants it
available across every repo on their machine, use `--scope user`:

```bash
claude mcp add --transport http linear --scope user https://mcp.linear.app/mcp
```

If the human wants to **share the configuration with their team via
version control**, use `--scope project` — it writes to a `.mcp.json`
at the repo root, designed to be committed:

```bash
claude mcp add --transport http linear --scope project https://mcp.linear.app/mcp
```

The three scopes are local-only (per-project), user (every project on
their machine), and project (shared via `.mcp.json`). Recommend
**local** by default for the first run; the human can broaden later.

##### 2. Authenticate via OAuth

After adding the server, open a Claude Code session in the same
project and run:

```text
/mcp
```

That opens the `/mcp` panel listing all configured MCP servers.
Linear will be flagged as needing authentication; selecting it opens
a browser window for the Linear OAuth flow. The human signs in to
Linear (or confirms they're already signed in) and grants access to
the Claude Code MCP client. The token is stored securely by Claude
Code and refreshed automatically.

If the browser doesn't open, Claude Code prints a URL the human can
open manually. If the browser redirect fails after authenticating
(connection-refused on `localhost`), Claude Code prompts for the
callback URL — paste the full URL from the browser's address bar.

##### 3. Verify the install

From a terminal outside Claude Code:

```bash
claude mcp list
```

The `linear` server should appear in the list. Then inside Claude
Code:

```text
/mcp
```

The Linear server should show as connected (not `⏸ Pending
approval`, not `✗ Failed`) and report a non-zero tool count. The
Linear MCP exposes about 25 tools — find/create/update issues,
projects, comments, initiatives, milestones, project updates.

##### 4. Resume /spades:setup

Once the Linear MCP is connected, re-run `/spades:setup` and pick
**Linear** again. The probe will succeed this time and setup will
continue.

#### Bind team and project (probe succeeded)

1. Ask the human (via `AskUserQuestion`) which team to use. List the
   teams returned by the probe.
2. Ask which Linear Project to bind this SPADES project to. List
   existing projects for the chosen team and offer **Create new
   Linear Project** as an option (the next step,
   `/spades:newproject`, handles creation).
3. Record the chosen team ID and Linear Project ID in
   `.spades/config` (Step 3 below).

### If Local was chosen

Nothing to verify externally. Continue.

## Step 1.5 — Source Code Management (SCM) selection

If `current_scm` is set (re-run case), print a context line above
the question:

> *Currently configured: `scm: <current_scm>`. The choice below
> replaces it. Re-pick the same value if unchanged, or switch.*

Ask the human which SCM their code lives in via `AskUserQuestion`.
This drives `/spades:ship`'s code-deliverable flow.

- **`Local git`** — work commits go to local git only. If a remote
  is configured, `/spades:ship` pushes to it but does NOT open PRs.
  No external tool dependency. Single-phase ship: push, record
  commit SHA, mark shipped.
- **`GitHub`** — work flows through GitHub PRs. `/spades:ship` runs
  the two-phase publish (push + `gh pr create`, then resume after
  squash-merge to record the merge SHA). Requires the `gh` CLI
  installed and authenticated.
- (future: GitLab, Bitbucket — extension points; see
  `docs/EXTENDING-SCM.md` for the contract drivers must satisfy.)

No "keep current" shortcut on re-run — same as Step 1, the human
always picks one of the two options afresh.

### If GitHub was chosen

#### Probe gh CLI

From a terminal:

```bash
gh auth status
```

If `gh` is installed and authenticated, the SCM is reachable —
continue to Step 2.

#### If gh isn't installed or unauthenticated — guide the install

Don't abort. Walk the human through it.

##### 1. Install gh CLI

GitHub publishes packaged binaries for macOS, Linux, and Windows.

- **macOS (Homebrew):** `brew install gh`
- **Linux (apt):** see <https://cli.github.com/manual/installation>
  for the apt repo setup, then `sudo apt install gh`
- **Linux (yum/dnf):** see the same page for the dnf instructions
- **Windows (winget):** `winget install --id GitHub.cli`

Confirm with `gh --version`.

##### 2. Authenticate

```bash
gh auth login
```

Pick `GitHub.com` (or `GitHub Enterprise Server` if applicable),
authenticate via browser (recommended) or paste a Personal Access
Token. Choose `HTTPS` or `SSH` for git operations to match your
existing remote.

##### 3. Verify

```bash
gh auth status
```

Should show "Logged in to github.com as <username>". Confirm
permissions include `repo` scope.

##### 4. Resume /spades:setup

Once gh CLI is installed and authenticated, re-run `/spades:setup`
and pick **GitHub** again. The probe will succeed this time and
setup will continue.

### If Local git was chosen

Nothing to verify externally. Continue.

## Step 1.7 — Review format (CLI or HTML)

If `current_review_format` is set (re-run case), print a context
line above the question — never recommend "Keep current":

> *Currently configured: `review_format: <current_review_format>`.
> The choice below replaces it. Re-pick the same value if
> unchanged, or switch.*

Ask via `AskUserQuestion`:

> *How should SPADES present reviews and produce artefacts?*

Two options:

- **HTML — auto-opens nicely formatted pages in your browser**
  *(Recommended)* — artefacts (projects, scopes, plans, learnings,
  reviews) are written as `.html` files under `.spades/` using the
  templates that ship with each skill. Skills that today paste a
  large review block to the CLI instead auto-open the relevant
  `.html` page in the default browser via `open` / `xdg-open` /
  `start`. Same content, much easier to review.
- **CLI — pastes plain-text/markdown output to the terminal** —
  artefacts are written as `.md` files (today's behaviour). Review
  output pastes to CLI. Quieter, browser-free, all-in-the-terminal.

Whichever the human picks is recorded as `review_format:` in
`.spades/config` (Step 3 below). The choice affects:

- **Producing skills** (`/spades:newproject`, `/spades:scope`,
  `/spades:plan`, `/spades:learn`, `/spades:review`) write
  artefacts in the chosen format.
- **Consumer skills** (`/spades:approve`, `/spades:evaluate`,
  `/spades:do`, `/spades:ship`, `/spades:close`, `/spades:status`,
  `/spades:list`, `/spades:intent`) auto-open the relevant `.html`
  in HTML mode; print to CLI in CLI mode.

No "keep current" shortcut on re-runs — same as the other Step 1
questions, the human always picks one of the two options afresh.

The skill flow itself doesn't change between modes — same
Pre-Flight, same Steps, same questions, same outputs. Only the
*format* of the artefact written and the *medium* of presentation
change.

## Step 2 — Active Project

If `current_project` is set (re-run case), print a context line:

> *Currently active project: `<current_project>`. The choice below
> replaces it. Re-pick the same one to keep it, or switch.*

Ask which project this repo belongs to.

- If `.spades/projects/` already contains records, offer them as
  options plus **Create a new project**.
- If there are no project records yet, offer **Create a new project**
  as the only option.

If the human picks **Create a new project**, invoke `/spades:newproject`
inline and resume here once it returns with the new project's slug.

Record the project slug into a `new_project` variable for Step 2.5's
diff (do **not** write `.spades/config` yet — that's Step 3's job
and only after the human confirms the diff).

## Step 2.5 — Diff & Confirm

Compute the diff between the captured `current_*` values (Pre-Flight § Capture existing config)
and the human's new answers (Steps 1 / 1.5 / 2). Three cases:

### Case A — No `.spades/config` existed (fresh install)

Skip the diff display entirely. The human's choices ARE the config.
Go straight to Step 3.

### Case B — Config existed and nothing changed

Every new value matches its `current_*` counterpart. Print:

> *Nothing changed — backend, SCM, and active project all match the
> existing config. Continue to refresh scaffolding (AGENTS.md
> marker block re-stamp, INTENT.md scaffold prompt, etc.)?*

Ask via `AskUserQuestion`:

- **Yes, refresh** — proceeds to Step 3+ (which writes the unchanged
  config back, idempotent, and re-stamps the AGENTS.md marker
  block to the current plugin version).
- **Cancel — exit without writes** — exits cleanly.

### Case C — Config existed and something changed

Show the diff block with each field's transition. Format:

```
Detected pre-existing SPADES config. Confirm these changes
before any writes happen:

  Backend:        <current_backend>  →  <new_backend>
  SCM:            <current_scm>      →  <new_scm>
  Active project: <current_project>  (unchanged)
  Linear team:    (unset)            →  <new_linear_team>      # only if backend changing or linear chosen
  Linear project: (unset)            →  <new_linear_project>   # same
  GitHub remote:  origin             (unchanged)               # only if scm: github

The local `.spades/config` and AGENTS.md marker block will be
updated. Existing scopes / plans / learnings on disk are NEVER
deleted by this skill.
```

Mark `(unchanged)` against any field where new value matches
current. The diff only lists fields that exist in either the
current or new config (no junk rows).

Ask via `AskUserQuestion`:

- **Apply changes** — if `backend` is changing, proceed to Step 2.6
  (migration). Otherwise straight to Step 3.
- **Cancel — exit without writes** — exits cleanly; `.spades/config`
  unchanged.

## Step 2.6 — Backend-switch migration (AI-assisted)

This step fires **only** when Step 2.5 detected a backend change
(`current_backend != new_backend`). For SCM / project / Linear team
or project changes alone (with backend the same), skip to Step 3 —
the existing artefacts already live under the right backend.

### Direction A — `local → linear`

The human had local files; they're switching to Linear. Without
migration, old scopes/plans stay as local-only files and Linear
starts empty — split-brain state. Setup offers to migrate.

Ask via `AskUserQuestion`:

- **Walk the local artefacts and mirror them to Linear**
  *(Recommended)* — performs the migration walk described below.
- **Skip migration — start fresh in Linear** — local files stay
  on disk untouched; Linear starts empty. Useful when the local
  artefacts are historical and the human is genuinely starting a
  fresh chapter.
- **Cancel the backend switch** — return to Step 1; backend stays
  `local`.

#### Migration walk (when "Walk … and mirror" is chosen)

Perform these operations in order, surfacing progress inline:

```
Migrating local → linear …
```

1. **Projects.** For each file in `.spades/projects/<slug>.md`:
   - Search the chosen Linear team for a Project with a matching
     name. Search via the Linear MCP (`mcp__linear-server__list_projects`
     filtered by team).
   - If exactly one match → link: write `linear_project_id: <uuid>`
     into the local file's frontmatter. Print:
     `✓ Project '<name>' → matched existing (proj-<id>).`
   - If multiple matches → disambiguate via `AskUserQuestion`,
     listing candidates with their Linear IDs.
   - If no match → create the Linear Project (`mcp__linear-server__save_project`)
     with the local file's body as the description. Write the
     returned ID back. Print: `✓ Project '<name>' → created (proj-<id>).`

2. **Scopes.** For each `.spades/scopes/S-<slug>.md` belonging to the
   active project:
   - Search Linear for an Issue under the bound Project with a
     matching title (`mcp__linear-server__list_issues` filtered).
   - Match → link via `linear_issue_id:` frontmatter; report.
   - No match → create the parent Issue
     (`mcp__linear-server__save_issue`) with body = the Scope's
     markdown body (Statement of Intent, Acceptance Criteria,
     Architectural Constraints, Out of Scope, Risk / Unknowns,
     Delivery Preference, current Audit Trail). Status mapped from
     SPADES → Linear (`scoped` → "Triage" or team default,
     `planning` → "Planning", `delivering` → "In Progress",
     `done` → "Done", etc.). Write `linear_issue_id` back.

3. **Plans.** For each `.spades/plans/P-<…>.md` belonging to one of
   the migrated Scopes:
   - Search under the Scope's parent Issue (via Linear MCP's
     sub-issue listing) for a matching title.
   - Match → link via `linear_issue_id:`.
   - No match → create a sub-Issue under the Scope's parent Issue.
     Body = the Plan's markdown body (Technical Approach, Tasks,
     Risks & Assumptions, Testing & Verification, Delivery
     Sequence, Audit Trail). SPADES `status:` → Linear status
     (`draft` → "Backlog" or team default, `approved` → "Approval",
     `delivering` → "Delivering" or "In Progress", `evaluating` →
     "Evaluating", `shipping` → "Shipping", `shipped` → "Done",
     `rejected` → "Cancelled"). Write `linear_issue_id` back.

4. **Audit-trail entry** on each migrated artefact (Project, Scope,
   Plan):

   ```markdown
   - YYYY-MM-DD: Migrated to Linear (backend switch). Linear: <id>.
   ```

5. **Learnings.** Not migrated. They live as local-only commentary
   under `.spades/learnings/` and are not tracker artefacts. Print
   a single summary line:
   `○ Learnings: kept local-only (4 files preserved, not migrated to Linear).`

6. **Migration summary** at the end of the walk:

```
✓ Migration complete. local → linear:
    Projects:  1 (1 created, 0 linked to existing)
    Scopes:    3 (2 created, 1 linked to existing)
    Plans:    11 (8 created, 3 linked to existing)
    Learnings: skipped (4 files stay local).
```

### Direction B — `linear → local`

The human had Linear; they're switching to local files. Without
migration, Linear remains the source of truth but new work goes to
local-only files. Setup offers reverse migration.

Ask via `AskUserQuestion`:

- **Pull Linear artefacts down to local files**
  *(Recommended for full repatriation)* — walks the bound Linear
  Project, fetches each Issue + sub-Issue, writes a corresponding
  `.spades/scopes/` or `.spades/plans/` file with frontmatter that
  preserves `linear_issue_id` (so the link survives in case the
  human later switches back).
- **Skip — start fresh locally** — local files stay as-is; new
  artefacts will be local-only.
- **Cancel the backend switch** — return to Step 1.

The pull walk shape mirrors Direction A's walk: Projects first
(probably just one — the bound Linear Project), then top-level
Issues (Scopes), then their sub-Issues (Plans), each written as
a local file. Skip Linear comments that aren't sub-Issues — they're
not SPADES artefacts.

### Migration error handling (both directions)

- **Linear MCP unreachable mid-walk** — abort gracefully. Items
  already linked have their `linear_*_id` frontmatter persisted.
  On retry (`/spades:setup` re-run with backend now matching the
  target), Step 2.6 detects partial state (some files linked, some
  not) and offers **Resume migration** / **Skip resume** /
  **Cancel**.
- **Linear-side duplicate title** — disambiguate via
  `AskUserQuestion` listing candidate Linear IDs. Don't blind-pick.
- **Network / rate-limit failures** — surface the error verbatim;
  offer **Retry** / **Skip this item** / **Abort migration**. Don't
  paper over.

## Step 3 — Write `.spades/config`

Write or update `.spades/config` to exactly this shape:

```yaml
backend: linear            # or: local
project: <project-slug>
scm: github                # or: local-git (more in docs/EXTENDING-SCM.md)
review_format: html        # or: cli  (introduced in v3.0.0; defaults to cli if absent)
linear:                    # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>
github:                    # only when scm: github
  remote: origin           # which git remote to push to (default: origin)
```

Re-run safety: if a value the human did not change is already in the
file, preserve it. Never blank fields the human still depends on.

## Step 4 — Write `.spades/version`

Write the current plugin version (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` `"version"`) as:

```
spades_version=<plugin-version>
```

(e.g. `spades_version=2.1.0`.) Idempotent — overwrite is fine.

## Step 5 — Scaffold the .spades/ subdirectories

Create the following empty directories if missing. Do not put any files
in them; that's the job of the per-phase skills.

- `.spades/projects/`
- `.spades/scopes/`
- `.spades/plans/`
- `.spades/learnings/`
- `.spades/reviews/`

## Step 5.5 — Ignore transient HTML scratch

`/spades:status`, `/spades:list`, and `/spades:intent` (HTML mode)
render to `.spades/.tmp/<view>.html`. Those files are regenerated on
every invocation and have no archival value — they must not be
committed.

Ensure `.spades/.tmp/` is gitignored. Idempotent:

1. If `.gitignore` does not exist at the repo root, create it with a
   single line: `.spades/.tmp/`.
2. If `.gitignore` exists and already contains a line matching
   `.spades/.tmp/` (with or without a trailing `/`), do nothing.
3. Otherwise append a trailing-newline-safe block:

   ```
   # SPADES transient HTML scratch — regenerated on every status/list/intent run
   .spades/.tmp/
   ```

Never rewrite or reorder the rest of `.gitignore`. Append-only.

## Step 6 — AGENTS.md (idempotent marker block)

Locate `AGENTS.md` at the repo root. If it doesn't exist, create it
with a one-line header: `# AGENTS.md` and a blank line.

Insert or replace the SPADES section between these markers:

```markdown
<!-- SPADES-FRAMEWORK-START v<plugin-version> -->
…the content below…
<!-- SPADES-FRAMEWORK-END -->
```

If markers already exist (any version), replace the content between
them in place. If they don't exist, append the marker block (and
content) to the end of the file. **Never** edit content outside the
markers.

The content to write inside the markers:

```markdown

# SPADES Framework — Agent Operating Rules

These rules define mandatory behaviour for AI agents using the SPADES
framework in this project. They augment any existing agent instructions
in this file and apply to **every** agent that reads this file —
Claude Code, Cursor, Codex, Aider, or anything else that honours
`AGENTS.md`.

## Operating Principles — Agile, four pillars

SPADES is an agile-by-design operating model. The whole loop, every
skill, and every gate ladder back to four pillars. Hold these as the
"why" behind any individual rule below.

1. **Collaborate.** Humans and AI work in close-loop conversation.
   Scope, Plan, and Approve are explicit collaboration gates — the
   AI proposes structure; the human owns intent and acceptance.
   `/spades:review` exists to broaden collaboration with multiple
   perspectives (four reviewer personas) on demand.
2. **Deliver.** Working output beats documentation about output.
   Do and Ship close the loop with something real — code merged,
   an artefact recorded, an action evidenced. Quick-path
   (`/spades:quick`) exists so small work can deliver without
   ceremony.
3. **Reflect.** Evaluate is a real gate, not a rubber stamp.
   PASS / PARTIAL / FAIL is captured with reasoning. Every Plan
   produces an evaluation HTML the human can revisit. The next
   pass starts with reflection on the last one.
4. **Improve.** Learnings (`/spades:learn`) are first-class. INTENT,
   ARCHITECTURE, PATTERNS, ANTI-PATTERNS all carry a
   `last_reviewed` field and get refreshed when reality drifts.
   Drift between docs and code is a signal to act, not paper
   over.

Skill mapping:

| Pillar | Where it lives |
|--------|----------------|
| Collaborate | Scope, Plan, Approve, Review |
| Deliver | Do, Ship, Quick |
| Reflect | Evaluate, Status |
| Improve | Learn, Intent / Architecture / Patterns / Anti-Patterns refresh |

## SPADES Skills (v2.0)

The SPADES plugin (`spades`) provides these 19 skills:

| Skill | What it does |
|-------|-------------|
| `/spades:setup` | Configure backend + scaffold this repo (re-runnable) |
| `/spades:newproject` | Create a new project record |
| `/spades:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades:approve` | Present a Plan for human review and record routing |
| `/spades:do` | Execute an approved Plan (routed AI / human / hybrid) |
| `/spades:evaluate` | Check delivered output against the Plan |
| `/spades:ship` | Open PR + review + merge (code) or record deliverable (artefact / action) |
| `/spades:close` | Conversational close-out: pass / reject / abandon based on target. Pass finalises (Plan → shipped, Scope → done, Project → archived); reject (Plans) and abandon (Scopes, Projects) require a reason. Opens a bookkeeping PR; run `/repo:sync` first. |
| `/spades:quick` | Fast-track for trivial work — quick-item marker file (`.spades/quick/Q-<id>.md`) is the canonical audit record |
| `/spades:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades:learn` | Capture a learning under `.spades/learnings/` |
| `/spades:research` | Read-only research via an isolated Opus subagent |
| `/spades:list` | List active scopes, filterable by phase |
| `/spades:status` | Show current SPADES phase + dependency graph |
| `/spades:intent` | Maintain `INTENT.md` — the durable project statement (why) |
| `/spades:architecture` | Maintain `ARCHITECTURE.md` — how the system is built |
| `/spades:patterns` | Maintain `PATTERNS.md` — approved conventions |
| `/spades:anti-patterns` | Maintain `ANTI-PATTERNS.md` — explicit prohibitions |

## The SPADES Loop

Every unit of work follows six phases:

    SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP

- Humans own Scope, Approve gate, and Evaluate gate.
- AI owns Plan, Do (when routed AI-auto), and Ship (when the deliverable
  is code).
- Approve records a routing decision (`ai` / `human` / `hybrid`) that
  determines who executes Do.

Never skip a phase or combine phases without explicit human
instruction.

**Exception — the fast-track path.** Trivial work can use
`/spades:quick` instead of the full loop. See "Fast-Track Path" below.

## Phase Rules

### 1. Scope (Human-owned)
- Never begin planning or writing code without a signed-off Scope.
- A Scope must include: intent, acceptance criteria, constraints,
  dependencies, context, out-of-scope, risk, delivery preference,
  priority.
- Scopes have IDs of the form `S-<description-slug>`.

### 2. Plan (AI-owned, human reviews)
- Produce one or more structured Plans for a Scope before writing code.
- Each Plan has an ID of the form
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`.
- Plans declare dependencies on prior Plans via `depends_on:`.
- Each task in a Plan declares an execution posture (`specify-first`,
  `discover-first`, `iterate`, `spike`, `straight-through`).
- Do NOT begin Do-phase work until the Plan is approved.

### 3. Approve (Human gate)
- After producing a Plan, STOP and wait for human approval.
- Approval records a `delivery:` routing on the Plan (`ai`, `human`,
  `hybrid`) and a `deliverable_type:` (`code`, `artefact`, `action`).
- If revised or rejected, do not begin delivery.

### 4. Do (AI or Human — routed)
- Execute the approved Plan. Routing comes from the Plan's `delivery:`
  field set at Approve time.
- For `ai`: run the work autonomously, committing as you go.
- For `human`: record the assignment in the backend; do not auto-do.
- For `hybrid`: split per the Plan's task-level routing.
- Run tests and verify before moving the Plan to Evaluate.

### 5. Evaluate (Human-owned, AI assists)
- Check delivered output against the Plan's acceptance criteria.
- Verdict is PASS / PARTIAL / FAIL.
- AI may assist but a human signs off the verdict.

### 6. Ship (Mixed)
- For `deliverable_type: code` — routed by the `scm:` field in
  `.spades/config`:
  - **`scm: github`** — two-phase: Phase 1 pushes the Do branch and
    opens the PR; address CodeRabbit feedback on the same branch;
    after squash-merge, run `/repo:sync`, then re-invoke
    `/spades:ship` to record the merge SHA and mark `shipped`.
  - **`scm: local-git`** — single-phase: push to the configured
    remote (if any), record commit SHA, mark `shipped`. No PR loop.
- For `deliverable_type: artefact` — record the artefact reference.
- For `deliverable_type: action` — record evidence of completion.
- Ship is the moment the deliverable becomes real to the outside world.

## Fast-Track Path (Small Work)

Not every change deserves a Scope. Trivial work — typos, one-line
tweaks, small config nudges, docs changes — uses `/spades:quick`. On
this path the PR description is the audit artefact; no separate Scope
or Plan is created.

### The gate — ALL must be true

1. Single concern
2. ≤ 50 lines of code changed total
3. One file or a tight cluster in one module
4. No new dependencies
5. No schema or data-layer changes
6. No architectural changes
7. No security-sensitive code
8. No public API or interface breaking changes
9. Revertible as one commit
10. Existing tests cover the area

If any criterion fails, fall back to the full loop.

## Architecture Constraints

Before generating any Plan, read these files if they exist:
- `ARCHITECTURE.md` — system architecture and constraints
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things you must not do

Flag any conflicts between proposed solutions and these documents.

## Freshness Before Read-Across

SPADES skills read files from the local filesystem, not from
`origin`. A stale local `main` produces stale findings — audits flag
issues already shipped, plans reference removed code, do-phase work
branches off the wrong base.

**The rule:** before any SPADES skill that reads cross-cutting state
or branches off `main`, verify the local checkout is in sync with
`origin/main`:

```bash
git fetch origin --quiet && git rev-list --count main..origin/main
```

Returns `0` → proceed. Non-zero → run `/repo:sync` first, then
re-invoke the SPADES skill.

**The behavioural reflex:** after any PR merge on this repo (yours
or someone else's), run `/repo:sync` immediately, before
context-switching to a new SPADES skill.

**Subagent prompts:** skills that spawn read-across subagents
(`/spades:review`, `/spades:research`) include the freshness check
in the subagent's own prompt — the subagent halts on stale-main
rather than producing findings against a stale snapshot.

The full contract lives in `docs/FRAMEWORK.md § Freshness`.

## Defer to the `repo` Plugin for Git Operations

SPADES does not own git-level operations. The `repo` plugin (from
the `ai-skills` marketplace) does. For any git operation, use the
appropriate `repo` slash command — never reinvent the equivalent
logic inside a SPADES skill.

| When you need to… | Use |
|-------------------|-----|
| Initialise a new git repo | `/repo:init` — `git init`, placeholder README, wires origin, pushes to main. |
| Create a new branch off main | `/repo:branch` (validates the name) plus `git switch -c <name>` to create in place, or `/repo:newbranch` for create-with-worktree. |
| Sync local main after a PR merge | `/repo:sync` — fetches, ff-pulls main, force-deletes the merged feature branch. |
| Refuse to commit on `main` / `master` | `/repo:branch` enforces this absolutely — no overrides. |

SPADES skills that branch off main (`/spades:do`, `/spades:close`)
go through `/repo:branch`'s regex validation. SPADES skills that
need to verify post-merge state (`/spades:close`) invoke
`/repo:sync` directly. The dependency is **one-directional**:
SPADES → `repo`, never the reverse.

**If you don't have a git repo yet**, run `/repo:init` first, then
re-invoke `/spades:setup`. SPADES expects an initialised repo — it
scaffolds files (`AGENTS.md`, `ARCHITECTURE.md`, `.spades/config`)
under git's expectation that they will be committed.

## Versioning

Every PR to the SPADES plugin must bump the plugin version. Per-skill
versions in the plugin's own SKILL.md frontmatter bump only when that
skill's body changes. Consumer repos don't carry their own version —
the plugin version in the marker block above (`vX.Y.Z`) tells you
which framework version your AGENTS.md was last stamped against;
re-running `/spades:setup` after a plugin upgrade re-stamps it.

Choose major / minor / patch by semver. When in doubt, lean higher.

## Audit Trail

Every piece of work must trace through: project → scope → plan(s) →
approval (with routing) → do-phase record → evaluation verdict →
shipment record. Work that cannot be traced through this chain must
not ship.
```

## Step 7 — Project documentation (per-file ask)

Four durable project-level docs live at the repo root, each owned by
its own facilitator skill:

| File | Skill | Owns |
|------|-------|------|
| `INTENT.md` | `/spades:intent` | Why the project exists, for whom, success, non-goals |
| `ARCHITECTURE.md` | `/spades:architecture` | How the system is built (tech stack, components, data flow, security, ops) |
| `PATTERNS.md` | `/spades:patterns` | Approved conventions (code organisation, error handling, testing, naming) |
| `ANTI-PATTERNS.md` | `/spades:anti-patterns` | Explicit prohibitions ("we don't do X") |

For each file, in the order above:

### 7.A — Detect current state

Read the file at the repo root and classify it as one of:

1. **Missing** — the file does not exist on disk.
2. **Scaffolded but unfilled** — the file exists but contains
   two or more `<!-- Describe … -->` / `<!-- List … -->` /
   placeholder comment markers. The template was scaffolded
   previously but no human has filled it in.
3. **Complete** — the file exists and the placeholder markers
   have largely been replaced with real content (fewer than two
   placeholder markers).

### 7.B — Skip if complete

If the file is **Complete**, do nothing. Don't prompt; don't
re-scaffold; don't invoke the facilitator skill. The human has
already done the work. (They can always re-invoke the relevant
skill directly when they want to refresh.)

Print a one-line confirmation: `✓ INTENT.md complete (last
reviewed YYYY-MM-DD).`

### 7.C — Otherwise, ask per file via AskUserQuestion

For each Missing / Scaffolded-but-unfilled file, ask via
`AskUserQuestion`:

> *<filename> — how would you like to handle this?*
>
> - **Create / complete now** (recommended for the first run)
>   — invokes the relevant skill inline (`/spades:intent`,
>   `/spades:architecture`, `/spades:patterns`,
>   `/spades:anti-patterns`). The skill walks the human through
>   the sections via its facilitate-never-author flow. After the
>   skill returns, this Step 7 loop continues to the next file.
> - **Scaffold an empty template** — write the scaffolded
>   markdown (the same template the facilitator skill would
>   produce in "start blank" mode) so the human can fill it in
>   later. Doesn't invoke the skill; doesn't ask any content
>   questions. Useful when the human wants the docs to exist as
>   structure but isn't ready to fill them in right now.
> - **Skip** — write nothing. The file stays missing. The
>   facilitator skill can still be invoked later, and other SPADES
>   skills (`/spades:plan`, `/spades:review`) will surface
>   gentle nudges when they notice the file is absent.

### 7.D — Template content for the "Scaffold empty" branch

When the human picks **Scaffold an empty template**, write
exactly the inline template the relevant SKILL.md documents
under its "Inline ... Template" section. Don't fabricate
alternative content here; the SKILL.md is the source of truth
for the scaffolded shape.

The skills handle their own scaffolding when invoked at "start
blank" — Step 7 only needs to reproduce that scaffold without
invoking the skill. Read each SKILL.md's template section and
write its content verbatim:

- `INTENT.md` → see `/spades:intent` § "Inline INTENT.md Template"
- `ARCHITECTURE.md` → see `/spades:architecture` § "Inline
  ARCHITECTURE.md Template"
- `PATTERNS.md` → see `/spades:patterns` § "Inline PATTERNS.md
  Template"
- `ANTI-PATTERNS.md` → see `/spades:anti-patterns` § "Inline
  ANTI-PATTERNS.md Template"

Set `last_reviewed: <today>` in the frontmatter so the staleness
detector doesn't immediately flag the scaffold.

### 7.E — Re-run safety

If the human re-runs `/spades:setup` later, Step 7 re-classifies
each file:

- A previously **Scaffolded but unfilled** file that's now
  **Complete** is skipped silently.
- A previously **Complete** file stays skipped — no churn.
- A file that the human chose to **Skip** earlier (and is still
  missing) gets asked again.

This means re-running setup is safe and idempotent: the human
gets prompted only for the docs that are still incomplete.

## Step 9 — Confirm and summarise

Print a concise summary that reflects actual transitions where
applicable. For re-runs that changed something, show the `→`
transition; for unchanged fields, append `(unchanged)`:

```
✓ Backend:        local → linear   (team: <name>, project: <name>)
✓ SCM:            local-git        (unchanged)
✓ Active project: spades-framework (unchanged)
✓ Migrated:       1 project, 3 scopes, 11 plans → Linear
                  (4 learnings stayed local by design)
✓ Config:         .spades/config
✓ Version:        <plugin-version>
✓ Updated:        AGENTS.md (marker block re-stamped from v2.0.0 → v<plugin-version>)
✓ Created:        ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md  (templates)
○ Skipped:        INTENT.md (re-run /spades:intent to scaffold)

Next steps:
  /spades:newproject       — if you haven't created one yet
  /spades:scope <title>    — start a new Scope
```

The **Migrated** line only appears when Step 2.6 actually ran (a
backend switch + the human picked Walk-and-mirror or
Pull-to-local). On Skip-migration it becomes:

```
○ Migration:      skipped — local artefacts stay on disk; new
                  Linear-side work starts empty.
```

For fresh installs (no prior config), the `(unchanged)` annotations
don't apply — the summary just shows the chosen values without
transitions.

Use `○` for skipped items, `✓` for done, `✗` for failed. Be brief —
the human should be able to confirm correctness in 10 seconds.

## Why AGENTS.md, not CLAUDE.md

SPADES targets `AGENTS.md` because it is the cross-agent convention —
Claude Code, Cursor, Codex, Aider and most other agentic coding tools
honour `AGENTS.md` as the source of project rules. A consumer repo
that adopts SPADES gets one operating-rules file that every agent
reads, instead of one file per vendor. Do not write `CLAUDE.md`,
`CURSOR.md`, or similar per-agent variants.
