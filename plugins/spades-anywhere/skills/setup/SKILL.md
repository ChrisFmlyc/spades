---
name: setup
description: Configure SPADES in this repository — choose a backend (Linear MCP or local filesystem), set the active project, scaffold AGENTS.md / ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md, and write .spades-anywhere/config. Use when starting fresh, when someone says "set up SPADES", "configure SPADES", "initialise SPADES", "I want to use SPADES in this repo". Re-runnable to reconfigure backend or refresh scaffolding without clobbering existing content.
version: 0.1.0
---

# /spades-anywhere:setup

You are configuring SPADES in the current repository. This is the entry
point: every other skill assumes setup has been run and that
`.spades-anywhere/config` exists.

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

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades-anywhere/ Local Layout before
running. The schemas below are mirrors of that contract; FRAMEWORK.md
is canonical.

## Self-Init Guard

If the current working directory IS the SPADES framework repo itself
(its `.claude-plugin/plugin.json` has `name: spades` or
`name: spades-anywhere`, or the `plugins/spades-anywhere/` directory
exists at the root), abort with:

> This is the SPADES framework's own repository. Setup is for
> consumer projects that want to *use* `spades-anywhere`, not for
> the framework itself.

The framework dogfoods itself by running setup against its own
`plugins/spades-anywhere/` directory — but you only do that when
explicitly told "set up the dogfood project".

## Pre-Flight

### Capture existing config (re-run context)

> `spades-anywhere` deliberately has **no `/repo` plugin
> prerequisite**, **no SCM selection**, and **no git-repo check**.
> The plugin runs in non-coding contexts (Claude Desktop, ChatGPT,
> web/mobile) where there often is no git repo at all. If the
> consumer chooses to put their `.spades-anywhere/` directory under
> version control they may, but the framework doesn't assume or
> require it.

Before asking any questions, capture the current state of
`.spades-anywhere/config` (if it exists) into context variables. The captured
values are surfaced **as context** in each subsequent question — they
do NOT route the flow or bias the recommended option. The whole point
of re-running setup is to re-engage with each choice, not to
short-circuit on previous answers.

Probe:

```bash
[ -f .spades-anywhere/config ] && echo present || echo missing
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
- **`Local`** — artefacts live as Markdown files under `.spades-anywhere/`. No
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

##### 4. Resume /spades-anywhere:setup

Once the Linear MCP is connected, re-run `/spades-anywhere:setup` and pick
**Linear** again. The probe will succeed this time and setup will
continue.

#### Bind team and project (probe succeeded)

1. Ask the human (via `AskUserQuestion`) which team to use. List the
   teams returned by the probe.
2. Ask which Linear Project to bind this SPADES project to. List
   existing projects for the chosen team and offer **Create new
   Linear Project** as an option (the next step,
   `/spades-anywhere:newproject`, handles creation).
3. Record the chosen team ID and Linear Project ID in
   `.spades-anywhere/config` (Step 3 below).

### If Local was chosen

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
  reviews) are written as `.html` files under `.spades-anywhere/` using the
  templates that ship with each skill. Skills that today paste a
  large review block to the CLI instead auto-open the relevant
  `.html` page in the default browser via `open` / `xdg-open` /
  `start`. Same content, much easier to review.
- **CLI — pastes plain-text/markdown output to the terminal** —
  artefacts are written as `.md` files (today's behaviour). Review
  output pastes to CLI. Quieter, browser-free, all-in-the-terminal.

Whichever the human picks is recorded as `review_format:` in
`.spades-anywhere/config` (Step 3 below). The choice affects:

- **Producing skills** (`/spades-anywhere:newproject`, `/spades-anywhere:scope`,
  `/spades-anywhere:plan`, `/spades-anywhere:learn`, `/spades-anywhere:review`) write
  artefacts in the chosen format.
- **Consumer skills** (`/spades-anywhere:approve`, `/spades-anywhere:evaluate`,
  `/spades-anywhere:do`, `/spades-anywhere:ship`, `/spades-anywhere:close`, `/spades-anywhere:status`,
  `/spades-anywhere:list`, `/spades-anywhere:intent`) auto-open the relevant `.html`
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

- If `.spades-anywhere/projects/` already contains records, offer them as
  options plus **Create a new project**.
- If there are no project records yet, offer **Create a new project**
  as the only option.

If the human picks **Create a new project**, invoke `/spades-anywhere:newproject`
inline and resume here once it returns with the new project's slug.

Record the project slug into a `new_project` variable for Step 2.5's
diff (do **not** write `.spades-anywhere/config` yet — that's Step 3's job
and only after the human confirms the diff).

## Step 2.5 — Diff & Confirm

Compute the diff between the captured `current_*` values (Pre-Flight § Capture existing config)
and the human's new answers (Steps 1 / 1.5 / 2). Three cases:

### Case A — No `.spades-anywhere/config` existed (fresh install)

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

The local `.spades-anywhere/config` and AGENTS.md marker block will be
updated. Existing scopes / plans / learnings on disk are NEVER
deleted by this skill.
```

Mark `(unchanged)` against any field where new value matches
current. The diff only lists fields that exist in either the
current or new config (no junk rows).

Ask via `AskUserQuestion`:

- **Apply changes** — if `backend` is changing, proceed to Step 2.6
  (migration). Otherwise straight to Step 3.
- **Cancel — exit without writes** — exits cleanly; `.spades-anywhere/config`
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

1. **Projects.** For each file in `.spades-anywhere/projects/<slug>.md`:
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

2. **Scopes.** For each `.spades-anywhere/scopes/S-<slug>.md` belonging to the
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

3. **Plans.** For each `.spades-anywhere/plans/P-<…>.md` belonging to one of
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
   under `.spades-anywhere/learnings/` and are not tracker artefacts. Print
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
  `.spades-anywhere/scopes/` or `.spades-anywhere/plans/` file with frontmatter that
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
  On retry (`/spades-anywhere:setup` re-run with backend now matching the
  target), Step 2.6 detects partial state (some files linked, some
  not) and offers **Resume migration** / **Skip resume** /
  **Cancel**.
- **Linear-side duplicate title** — disambiguate via
  `AskUserQuestion` listing candidate Linear IDs. Don't blind-pick.
- **Network / rate-limit failures** — surface the error verbatim;
  offer **Retry** / **Skip this item** / **Abort migration**. Don't
  paper over.

## Step 3 — Write `.spades-anywhere/config`

Write or update `.spades-anywhere/config` to exactly this shape:

```yaml
backend: linear            # or: local
project: <project-slug>
review_format: html        # or: cli  (defaults to cli if absent)
linear:                    # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>
```

Note: `spades-anywhere` has **no `scm:` field**. The plugin runs
in non-coding contexts where there is no SCM concern.

Re-run safety: if a value the human did not change is already in the
file, preserve it. Never blank fields the human still depends on.

## Step 4 — Write `.spades-anywhere/version`

Write the current plugin version (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` `"version"`) as:

```
spades_anywhere_version=<plugin-version>
```

(e.g. `spades_anywhere_version=2.1.0`.) Idempotent — overwrite is fine.

## Step 5 — Scaffold the .spades-anywhere/ subdirectories

Create the following empty directories if missing. Do not put any files
in them; that's the job of the per-phase skills.

- `.spades-anywhere/projects/`
- `.spades-anywhere/scopes/`
- `.spades-anywhere/plans/`
- `.spades-anywhere/learnings/`
- `.spades-anywhere/reviews/`

## Step 5.5 — Ignore transient HTML scratch (only if in a git repo)

`/spades-anywhere:status`, `/spades-anywhere:list`, and
`/spades-anywhere:intent` (HTML mode) render to
`.spades-anywhere/.tmp/<view>.html`. Those files are regenerated on
every invocation and have no archival value — they must not be
committed.

Probe whether the project is inside a git repo:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

- **Not in a git repo** — skip this step entirely. There is no
  `.gitignore` to maintain. `spades-anywhere` does not assume the
  consumer has version control; this is the common case for
  Claude Desktop projects, ChatGPT conversations, mobile clients.
- **In a git repo** — ensure `.spades-anywhere/.tmp/` is
  gitignored. Idempotent:

  1. If `.gitignore` does not exist at the repo root, create it
     with a single line: `.spades-anywhere/.tmp/`.
  2. If `.gitignore` exists and already contains a line matching
     `.spades-anywhere/.tmp/` (with or without a trailing `/`),
     do nothing.
  3. Otherwise append a trailing-newline-safe block:

     ```
     # spades-anywhere transient HTML scratch — regenerated on every status/list/intent run
     .spades-anywhere/.tmp/
     ```

  Never rewrite or reorder the rest of `.gitignore`. Append-only.

## Step 6 — AGENTS.md (idempotent marker block)

Locate `AGENTS.md` at the repo root. If it doesn't exist, create it
with a one-line header: `# AGENTS.md` and a blank line.

Insert or replace the SPADES section between these markers:

```markdown
<!-- SPADES-ANYWHERE-FRAMEWORK-START v<plugin-version> -->
…the content below…
<!-- SPADES-ANYWHERE-FRAMEWORK-END -->
```

If markers already exist (any version), replace the content between
them in place. If they don't exist, append the marker block (and
content) to the end of the file. **Never** edit content outside the
markers.

The content to write inside the markers:

```markdown

# spades-anywhere — Agent Operating Rules

These rules define mandatory behaviour for AI agents using the
`spades-anywhere` framework in this project. They apply to every
agent that reads this file — Claude Desktop, ChatGPT, the Claude
web app, mobile clients, or anything else that honours `AGENTS.md`.

`spades-anywhere` is the sister plugin to `spades` (which targets
code work in coding harnesses). The two share a framework but
target different runtimes and different kinds of work — see
[`README.md`](README.md) for what `spades-anywhere` is for.

## Operating Principles — Agile, four pillars

`spades-anywhere` is an agile-by-design operating model for
non-coding work. The whole loop, every skill, and every gate
ladder back to four pillars.

1. **Collaborate.** Humans and AI work in close-loop
   conversation. Scope, Plan, Approve, and Review are explicit
   collaboration gates.
2. **Deliver.** Working output beats documentation about output.
   Do and Ship close the loop with something real — an artefact
   produced, an action evidenced.
3. **Reflect.** Evaluate is a real human gate. The do →
   evaluate loop runs until PASS, and verdicts are captured
   with reasoning.
4. **Improve.** Learnings (`/spades-anywhere:learn`) are
   first-class. INTENT, ARCHITECTURE, PATTERNS, ANTI-PATTERNS
   all carry a `last_reviewed` field and get refreshed when
   reality drifts.

| Pillar | Where it lives |
|--------|----------------|
| Collaborate | Scope, Plan, Approve, Review |
| Deliver | Do, Ship |
| Reflect | Evaluate, Status |
| Improve | Learn, Intent / Architecture / Patterns / Anti-Patterns refresh |

## spades-anywhere Skills (v0.5)

| Skill | What it does |
|-------|-------------|
| `/spades-anywhere:setup` | Configure backend + scaffold this project (re-runnable) |
| `/spades-anywhere:newproject` | Create a new project record |
| `/spades-anywhere:intent` | Maintain `INTENT.md` — why the project exists |
| `/spades-anywhere:architecture` | Maintain `ARCHITECTURE.md` — how the work is structured (stages, stakeholders, cadence, tools, constraints) |
| `/spades-anywhere:patterns` | Maintain `PATTERNS.md` — approved process conventions |
| `/spades-anywhere:anti-patterns` | Maintain `ANTI-PATTERNS.md` — explicit "we don't do X" rules |
| `/spades-anywhere:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades-anywhere:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades-anywhere:approve` | Present a Plan for human review and record routing |
| `/spades-anywhere:do` | Mark a Plan delivering + restate the Scope's acceptance criteria back to you |
| `/spades-anywhere:evaluate` | Human verdict against the Scope's acceptance criteria — PASS / PARTIAL / FAIL |
| `/spades-anywhere:ship` | Confirmation walk through the project's `INTENT.md` success criteria |
| `/spades-anywhere:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades-anywhere:learn` | Capture a learning under `.spades-anywhere/learnings/` |
| `/spades-anywhere:research` | Read-only research via an isolated Opus subagent |
| `/spades-anywhere:list` | List active scopes, filterable by phase |
| `/spades-anywhere:status` | Show current phase + dependency graph |

**Note:** there are **no `/spades-anywhere:close` and no
`/spades-anywhere:quick`**. Close is for PR bookkeeping (code work
only); Quick is for ≤50-LoC code fast-tracks. Neither applies here.

## The Loop

Every unit of work follows six phases:

    SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP

- Humans own Scope, Approve gate, Do (the actual work), Evaluate
  gate, and Ship (the confirmation walk).
- AI owns Plan, and assists with Do under `delivery: hybrid`.
- Approve records a routing decision (`human` / `hybrid`) that
  determines whether AI helps during Do. **There is no `ai`
  routing in `spades-anywhere`** — autonomous code execution
  doesn't apply to non-code work.

Never skip a phase or combine phases without explicit human
instruction.

If the human Evaluate step returns PARTIAL or FAIL,
`/spades-anywhere:evaluate` routes back to `/spades-anywhere:do`
and the human keeps going. The do → evaluate loop runs until PASS.

## Phase Rules

### 1. Scope (Human-owned)
- Never begin planning without a signed-off Scope.
- A Scope must include: statement of intent, acceptance criteria,
  constraints (budget / schedule / tools / stakeholders),
  dependencies, context, out-of-scope, risk, delivery preference.
- Scopes have IDs of the form `S-<description-slug>`.

### 2. Plan (AI-owned, human reviews)
- Produce one or more structured Plans for a Scope before
  starting work.
- Each Plan has an ID of the form
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`.
- Plans declare dependencies on prior Plans via `depends_on:`.
- Each task in a Plan declares an execution posture (`specify-first`,
  `discover-first`, `iterate`, `spike`, `straight-through`).
- Do NOT begin Do-phase work until the Plan is approved.

### 3. Approve (Human gate)
- After producing a Plan, STOP and wait for human approval.
- Approval records a `delivery:` routing on the Plan
  (`human` or `hybrid`) and a `deliverable_type:` (`artefact` or
  `action`). **There is no `code` deliverable_type and no `ai`
  routing in `spades-anywhere`.**
- If revised or rejected, do not begin delivery.

### 4. Do (Human acts; AI marks the start)
- `/spades-anywhere:do` is a **marker**, not autonomous work. The
  AI updates the Plan's status, restates the Scope's acceptance
  criteria so the human knows what "done" looks like, and stands
  down. The human does the actual work.
- For `delivery: hybrid` plans, AI offers to help with tasks
  marked `Routing: ai` — drafts, research, structuring — but
  never executes the task autonomously.
- No assignee tracking, no cadence enforcement. `spades-anywhere`
  is not a project manager.

### 5. Evaluate (Human verdict)
- Walk the Scope's acceptance criteria, mark each met / partial /
  not met, aggregate to PASS / PARTIAL / FAIL.
- No test execution, no AI verdict — the human's word is the
  verdict.
- If not PASS, route back to `/spades-anywhere:do` and keep going.

### 6. Ship (Confirmation walk against INTENT)
- Walk the project's `INTENT.md` success criteria one at a time,
  capture evidence per criterion (URL / file / photo / note).
- For `deliverable_type: artefact` — record a primary reference
  (URL, file path, doc ID) alongside the per-criterion evidence.
- For `deliverable_type: action` — record evidence of the action
  (photos, receipts, signed docs, witness notes).
- Mark Plan `shipped`. If every Plan under the Scope is shipped,
  Scope rolls up to `done`.

## Freshness Before Read-Across

`spades-anywhere` runs in contexts where there is often no git
repo at all (Claude Desktop project, ChatGPT conversation, mobile
client). The freshness rule from the sister `spades` plugin still
applies *conceptually* — read against the latest source of truth —
but the mechanism varies:

- **Linear backend** — Linear is canonical. Sub-agents always see
  current state. No probe needed.
- **Local backend without git** — `.spades-anywhere/` files on
  disk are the source of truth. No remote to compare against.
- **Local backend inside a git repo** — if the consumer has chosen
  to version-control `.spades-anywhere/`, the same staleness rule
  applies: run `git fetch && git rev-list --count
  main..origin/main`; if non-zero, sync first.

`spades-anywhere` does NOT require any `repo` plugin. Sync is
the consumer's responsibility, by any mechanism they prefer.

The full contract lives in `docs/FRAMEWORK.md § Freshness`.

## Versioning

Every PR to the plugin must bump the plugin version. Per-skill
versions in the plugin's own SKILL.md frontmatter bump only when
that skill's body changes. The plugin version in the marker block
above (`vX.Y.Z`) tells you which framework version your AGENTS.md
was last stamped against; re-running `/spades-anywhere:setup`
after a plugin upgrade re-stamps it.

Choose major / minor / patch by semver. When in doubt, lean
higher.

## Audit Trail

Every piece of work must trace through: project → scope → plan(s)
→ approval (with routing) → do-phase marker → evaluation verdict
→ shipment record (with per-INTENT-criterion evidence). Work that
cannot be traced through this chain must not ship.
```

## Step 7 — Project documentation (per-file ask)

Four durable project-level docs live at the repo root (or
knowledge store root), each owned by its own facilitator skill:

| File | Skill | Owns |
|------|-------|------|
| `INTENT.md` | `/spades-anywhere:intent` | Why the project exists, for whom, success, non-goals |
| `ARCHITECTURE.md` | `/spades-anywhere:architecture` | How the work is structured (stages, stakeholders, cadence, tools, constraints) |
| `PATTERNS.md` | `/spades-anywhere:patterns` | Approved process conventions |
| `ANTI-PATTERNS.md` | `/spades-anywhere:anti-patterns` | Explicit prohibitions ("we don't do X") |

For each file, in the order above:

### 7.A — Detect current state

Read the file at the repo root and classify it as one of:

1. **Missing** — the file does not exist on disk.
2. **Scaffolded but unfilled** — the file exists but contains
   two or more `<!-- Describe … -->` / `<!-- List … -->` /
   placeholder comment markers.
3. **Complete** — the file exists and the placeholder markers
   have largely been replaced with real content (fewer than two
   placeholder markers).

### 7.B — Skip if complete

If the file is **Complete**, do nothing. Don't prompt; don't
re-scaffold; don't invoke the facilitator skill. The human has
already done the work.

Print a one-line confirmation: `✓ INTENT.md complete (last
reviewed YYYY-MM-DD).`

### 7.C — Otherwise, ask per file via AskUserQuestion

For each Missing / Scaffolded-but-unfilled file, ask via
`AskUserQuestion`:

> *<filename> — how would you like to handle this?*
>
> - **Create / complete now** (recommended for the first run)
>   — invokes the relevant skill inline. The skill walks the
>   human through the sections via its facilitate-never-author
>   flow. After the skill returns, this Step 7 loop continues
>   to the next file.
> - **Scaffold an empty template** — write the scaffolded
>   markdown (the same template the facilitator skill would
>   produce in "start blank" mode) so the human can fill it in
>   later. Doesn't invoke the skill; doesn't ask any content
>   questions.
> - **Skip** — write nothing. The file stays missing. The
>   facilitator skill can still be invoked later.

### 7.D — Template content for the "Scaffold empty" branch

When the human picks **Scaffold an empty template**, read the
relevant SKILL.md's "Inline ... Template" section and write that
content verbatim:

- `INTENT.md` → see `/spades-anywhere:intent` § "Inline
  INTENT.md Template"
- `ARCHITECTURE.md` → see `/spades-anywhere:architecture` §
  "Inline ARCHITECTURE.md Template"
- `PATTERNS.md` → see `/spades-anywhere:patterns` § "Inline
  PATTERNS.md Template"
- `ANTI-PATTERNS.md` → see `/spades-anywhere:anti-patterns` §
  "Inline ANTI-PATTERNS.md Template"

Set `last_reviewed: <today>` in the frontmatter.

### 7.E — Re-run safety

If the human re-runs `/spades-anywhere:setup` later, Step 7
re-classifies each file. Previously **Scaffolded** files that
are now **Complete** are skipped silently. Previously **Skipped**
files (still missing) get asked again. Idempotent.

## Step 8 — Confirm and summarise

Print a concise summary that reflects actual transitions where
applicable. For re-runs that changed something, show the `→`
transition; for unchanged fields, append `(unchanged)`:

```
✓ Backend:        local → linear   (team: <name>, project: <name>)
✓ SCM:            local-git        (unchanged)
✓ Active project: spades-framework (unchanged)
✓ Migrated:       1 project, 3 scopes, 11 plans → Linear
                  (4 learnings stayed local by design)
✓ Config:         .spades-anywhere/config
✓ Version:        <plugin-version>
✓ Updated:        AGENTS.md (marker block re-stamped from v2.0.0 → v<plugin-version>)
✓ Created:        ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md  (templates)
○ Skipped:        INTENT.md (re-run /spades-anywhere:intent to scaffold)

Next steps:
  /spades-anywhere:newproject       — if you haven't created one yet
  /spades-anywhere:scope <title>    — start a new Scope
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
