---
name: setup
description: Configure SPADES in this repository — choose a backend (Linear MCP or local filesystem), set the active project, scaffold AGENTS.md / ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md, and write .spades/config. Use when starting fresh, when someone says "set up SPADES", "configure SPADES", "initialise SPADES", "I want to use SPADES in this repo". Re-runnable to reconfigure backend or refresh scaffolding without clobbering existing content.
version: 4.0.1
---

# /spades:setup

Configure SPADES in this repository. Every other skill assumes setup
has run and `.spades/config` exists.

**Re-runs ask every question again.** Current values appear as a
*"Currently configured: …"* context line above each `AskUserQuestion`
but never bias the recommended option. Step 2.5 diffs old vs new
and requires explicit confirm before writes; Step 2.6 offers
migration on backend switch. Setup never destroys human-written
content (scope / plan / learning files stay; the AGENTS.md marker
block is replaced in place, content outside the markers is
untouched).

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades/ Local Layout
before running — FRAMEWORK.md is canonical.

## Self-Init Guard

If this directory IS the SPADES framework repo itself
(`.claude-plugin/plugin.json` has `name: spades` or
`plugins/spades/` exists at the root), abort:

> This is the SPADES framework's own repository. Setup is for
> consumer repos that want to *use* SPADES, not for the framework
> itself.

(The framework dogfoods itself only when explicitly told *"set up
the dogfood project"*.)

## Pre-Flight

### 1. Prerequisite plugin: `ai-skills/repo`

SPADES depends on `/repo:sync` (post-merge cleanup, called by
`/spades:close`) and `/repo:branch` (branch-name regex +
no-commits-on-main, used by `/spades:do`, `/spades:ship`,
`/spades:close`).

```bash
[ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
```

`found` → continue. `missing` → show install:

```
/plugin marketplace add ChrisFmlyc/ai-skills
/plugin install repo@ai-skills
```

Then `AskUserQuestion`: *I've installed it — re-probe* / *Skip
for now (close/do/ship will refuse until installed)*. If re-probe
still `missing`, re-show and re-ask; only advance on explicit
Skip.

### 2. Git repo

```bash
git rev-parse --git-dir >/dev/null 2>&1 && echo found || echo missing
```

`found` → continue. `missing` → abort:

> *This directory isn't a git repository. Run `/repo:init` first
> (initialises git, placeholder README, wires origin, pushes
> `main`), then re-invoke `/spades:setup`.*

Do **not** auto-run `/repo:init`.

### 3. Capture existing config (re-run context)

```bash
[ -f .spades/config ] && echo present || echo missing
```

`missing` (fresh install) → all `current_*` stay unset; Step 2.5
diff and Step 2.6 migration are skipped. `present` → read and
capture:

- `current_backend` (`linear` / `local`)
- `current_scm` (`github` / `local-git`)
- `current_project` (slug)
- `current_linear_team`, `current_linear_project` (UUIDs, if Linear)
- `current_github_remote` (if GitHub)
- `current_review_format` (`cli` / `html`; defaults to `cli` on
  older configs)

These feed the *"Currently configured: …"* preamble on Steps 1,
1.5, 1.7, 2 and the diff in Step 2.5.

## Step 1 — Backend Selection

If `current_backend` is set, print above the question (never
recommend "Keep current"):

> *Currently configured: `backend: <current_backend>`. The choice
> below replaces it. Re-pick the same value if nothing's changed,
> or switch — your call, but please make it explicitly.*

`AskUserQuestion`:

- **`Linear`** — artefacts live as Linear Issues (Project, parent
  Issue, sub-issues). Requires Linear MCP.
- **`Local`** — artefacts live as Markdown files under `.spades/`.
  No external tracker; full audit trail in-repo.

No "keep current" shortcut on re-run.

### If Linear was chosen

**Probe Linear MCP** (teams-list call). At least one team
returned → continue to *Bind team and project* below.

**Probe fails** (no Linear MCP tool, 401/403, connection refused)
→ don't abort. Walk the human through install:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

Scope options: default **local** (this project only), `--scope
user` (every project on this machine), `--scope project`
(committed `.mcp.json`, shared with team). Recommend **local**
for the first run.

After adding the server, the human runs `/mcp` inside Claude
Code, picks Linear, and completes the OAuth flow in the browser.
Verify with `claude mcp list` outside Claude Code, then `/mcp`
inside — Linear should show connected with ~25 tools.

Once connected, re-run `/spades:setup` and pick Linear again.

**Bind team and project** (probe succeeded):

1. `AskUserQuestion`: which team? (list teams from probe).
2. `AskUserQuestion`: which Linear Project? (list existing under
   the chosen team + *Create new Linear Project*).
3. If *Create new* → invoke `/spades:newproject` inline.
4. Record `team_id` + `project_id` for Step 3.

### If Local was chosen

Nothing to verify externally.

## Step 1.5 — Source Code Management (SCM)

If `current_scm` is set, print *"Currently configured: `scm:
<current_scm>`. The choice below replaces it. Re-pick or
switch."*.

`AskUserQuestion`:

- **`Local git`** — work commits to local git only. If a remote
  is configured, `/spades:ship` pushes but does NOT open PRs.
  Single-phase ship.
- **`GitHub`** — work flows through GitHub PRs. `/spades:ship`
  runs two-phase publish. Requires `gh` CLI installed +
  authenticated.
- (future: GitLab, Bitbucket — see `docs/EXTENDING-SCM.md`.)

No "keep current" shortcut on re-run.

### If GitHub was chosen

Probe `gh auth status`. Authenticated → continue.

If unavailable / unauthenticated → don't abort. Install via
`brew install gh` (macOS), `winget install --id GitHub.cli`
(Windows), or the apt/dnf instructions at
<https://cli.github.com/manual/installation>. Then `gh auth
login` → pick GitHub.com / Enterprise, authenticate via browser
(recommended) or PAT, choose HTTPS or SSH to match the remote.
Verify with `gh auth status` (must include `repo` scope). Re-run
`/spades:setup` and pick GitHub again.

### If Local git was chosen

Nothing to verify externally.

## Step 1.7 — Review format

If `current_review_format` is set, print *"Currently configured:
`review_format: <current_review_format>`. Re-pick or switch."*.

`AskUserQuestion`: *How should SPADES present reviews and produce
artefacts?*

- **HTML — auto-opens nicely formatted pages in your browser**
  *(Recommended)*. Artefacts under `.spades/` are written as
  `.html`; review-form output auto-opens via `open` / `xdg-open`
  / `start`.
- **CLI — pastes plain-text/markdown output to the terminal**.
  Artefacts as `.md`; review output to CLI.

Recorded as `review_format:` in `.spades/config` (Step 3). The
choice toggles per-skill rendering only — the flow itself is
identical.

## Step 2 — Active Project

If `current_project` is set, print *"Currently active project:
`<current_project>`. Re-pick or switch."*.

`AskUserQuestion`:

- Existing `.spades/projects/<slug>.md` records → offer them +
  *Create a new project*.
- No records → *Create a new project* is the only option.

If *Create a new project* → invoke `/spades:newproject` inline;
resume here with the new slug.

Record the slug into `new_project` for Step 2.5's diff. Do **not**
write `.spades/config` yet.

## Step 2.5 — Diff & Confirm

Diff captured `current_*` vs new answers. Three cases:

### Case A — Fresh install (no `.spades/config` existed)

Skip the diff display. Go straight to Step 3.

### Case B — Config existed, nothing changed

Every new value matches its `current_*` counterpart. Print:

> *Nothing changed — backend, SCM, and active project all match
> the existing config. Continue to refresh scaffolding (AGENTS.md
> marker block re-stamp, INTENT.md scaffold prompt, etc.)?*

`AskUserQuestion`: *Yes, refresh* / *Cancel — exit without writes*.

### Case C — Config existed, something changed

Show the diff:

```
Detected pre-existing SPADES config. Confirm these changes
before any writes happen:

  Backend:        <current_backend>  →  <new_backend>
  SCM:            <current_scm>      →  <new_scm>
  Active project: <current_project>  (unchanged)
  Linear team:    (unset)            →  <new_linear_team>      # if backend changing or linear chosen
  Linear project: (unset)            →  <new_linear_project>   # same
  GitHub remote:  origin             (unchanged)               # if scm: github

The local `.spades/config` and AGENTS.md marker block will be
updated. Existing scopes / plans / learnings on disk are NEVER
deleted by this skill.
```

`(unchanged)` against fields where new = current. Only list fields
present in either old or new config.

`AskUserQuestion`:

- **Apply changes** — if `backend` is changing → Step 2.6.
  Otherwise → Step 3.
- **Cancel — exit without writes** — exits cleanly.

## Step 2.6 — Backend-switch migration

Fires **only** when `current_backend != new_backend`. SCM /
project / Linear team or project changes alone skip to Step 3.

### Direction A — `local → linear`

`AskUserQuestion`:

- **Walk the local artefacts and mirror them to Linear**
  *(Recommended)* — migration walk below.
- **Skip migration — start fresh in Linear** — local files
  untouched; Linear starts empty.
- **Cancel the backend switch** — back to Step 1.

**Migration walk:** for each artefact, search Linear under the
bound Project; match → link via frontmatter ID; no match →
create.

1. **Projects** — `.spades/projects/<slug>.md` → Linear Project
   (via `mcp__linear-server__list_projects` filtered by team, then
   `mcp__linear-server__save_project` if no match). Write
   `linear_project_id` back. Disambiguate multi-match via
   `AskUserQuestion`.
2. **Scopes** — `.spades/scopes/S-<slug>.md` → Linear Issue under
   the bound Project. Body = the Scope's markdown (Statement of
   Intent, Acceptance Criteria, Architectural Constraints, Out of
   Scope, Risk / Unknowns, Delivery Preference, Audit Trail).
   Status map: `scoped`→Triage/team-default, `planning`→Planning,
   `delivering`→In Progress, `done`→Done. Write
   `linear_issue_id` back.
3. **Plans** — `.spades/plans/P-<…>.md` → sub-Issue under the
   Scope's parent Issue. Body = Plan markdown (Technical Approach,
   Tasks, Risks & Assumptions, Testing & Verification, Delivery
   Sequence, Audit Trail). Status map: `draft`→Backlog/default,
   `approved`→Approval, `delivering`→Delivering/In Progress,
   `evaluating`→Evaluating, `shipping`→Shipping, `shipped`→Done,
   `rejected`→Cancelled. Write `linear_issue_id` back.
4. **Audit-trail entry** on each migrated artefact:

   ```markdown
   - YYYY-MM-DD: Migrated to Linear (backend switch). Linear: <id>.
   ```

5. **Learnings** — not migrated; local-only commentary. Print:
   `○ Learnings: kept local-only (N files preserved).`

6. **Migration summary:**

```
✓ Migration complete. local → linear:
    Projects:  1 (1 created, 0 linked to existing)
    Scopes:    3 (2 created, 1 linked to existing)
    Plans:    11 (8 created, 3 linked to existing)
    Learnings: skipped (4 files stay local).
```

### Direction B — `linear → local`

`AskUserQuestion`:

- **Pull Linear artefacts down to local files** *(Recommended)*
  — walks the bound Linear Project (Projects → top-level Issues
  for Scopes → sub-Issues for Plans) and writes each as a local
  file, preserving `linear_issue_id` so a future switch back
  still links. Skips comments (not SPADES artefacts).
- **Skip — start fresh locally** — local files unchanged.
- **Cancel the backend switch** — back to Step 1.

### Migration error handling (both directions)

- **Linear MCP unreachable mid-walk** — abort gracefully; already-
  linked items retain `linear_*_id` frontmatter. On retry, Step
  2.6 detects partial state and offers *Resume migration* /
  *Skip resume* / *Cancel*.
- **Duplicate title** — disambiguate via `AskUserQuestion`
  listing Linear IDs. Don't blind-pick.
- **Network / rate-limit** — surface verbatim; offer *Retry* /
  *Skip this item* / *Abort migration*.

## Step 3 — Write `.spades/config`

```yaml
backend: linear            # or: local
project: <project-slug>
scm: github                # or: local-git
review_format: html        # or: cli  (defaults to cli on older configs)
linear:                    # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>
github:                    # only when scm: github
  remote: origin
```

Re-run safety: preserve values the human didn't change. Never
blank fields the human still depends on.

## Step 4 — Write `.spades/version`

Read the plugin version from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` `"version"` and
write:

```
spades_version=<plugin-version>
```

Idempotent — overwrite is fine.

## Step 5 — Scaffold the `.spades/` subdirectories

Create if missing, no files inside:

- `.spades/projects/`
- `.spades/scopes/`
- `.spades/plans/`
- `.spades/learnings/`
- `.spades/reviews/`

## Step 5.5 — Ignore transient HTML scratch

`.spades/.tmp/` holds regenerated HTML for `/spades:status`,
`/spades:list`, `/spades:intent` and must not be committed.
Idempotent:

1. No `.gitignore` → create with one line: `.spades/.tmp/`.
2. `.gitignore` already lists `.spades/.tmp` (with or without
   trailing `/`) → do nothing.
3. Otherwise append:

   ```
   # SPADES transient HTML scratch — regenerated on every status/list/intent run
   .spades/.tmp/
   ```

Append-only — never rewrite or reorder the rest of `.gitignore`.

## Step 6 — AGENTS.md (idempotent marker block)

If `AGENTS.md` doesn't exist at the repo root, create it with one
line `# AGENTS.md` + blank line.

Insert or replace the block between these markers:

```markdown
<!-- SPADES-FRAMEWORK-START v<plugin-version> -->
…the content below…
<!-- SPADES-FRAMEWORK-END -->
```

Markers exist (any version) → replace in place. Markers absent →
append. **Never** edit content outside the markers.

Content to write inside the markers:

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

Four durable project-level docs at the repo root, each owned by
its facilitator skill:

| File | Skill | Owns |
|------|-------|------|
| `INTENT.md` | `/spades:intent` | Why the project exists, for whom, success, non-goals |
| `ARCHITECTURE.md` | `/spades:architecture` | How the system is built (tech, components, data flow, security, ops) |
| `PATTERNS.md` | `/spades:patterns` | Approved conventions (code organisation, error handling, testing, naming) |
| `ANTI-PATTERNS.md` | `/spades:anti-patterns` | Explicit prohibitions ("we don't do X") |

For each file, in the order above:

### 7.A — Detect state

1. **Missing** — file doesn't exist.
2. **Scaffolded but unfilled** — file exists and contains ≥ 2
   `<!-- Describe … -->` / `<!-- List … -->` placeholder markers.
3. **Complete** — file exists, < 2 placeholder markers.

### 7.B — Skip if complete

Print one line: `✓ INTENT.md complete (last reviewed YYYY-MM-DD).`
Don't prompt; don't re-scaffold; don't invoke the skill.

### 7.C — Otherwise ask per file via `AskUserQuestion`

> *<filename> — how would you like to handle this?*
>
> - **Create / complete now** *(recommended for the first run)* —
>   invokes the facilitator skill inline. After it returns, Step
>   7 continues to the next file.
> - **Scaffold an empty template** — write the inline template
>   the facilitator's SKILL.md documents. Doesn't invoke the
>   skill; no content questions.
> - **Skip** — write nothing. The file stays missing. The
>   facilitator can be invoked later; other SPADES skills nudge
>   if absent.

### 7.D — Template content for "Scaffold empty"

Read each facilitator SKILL.md's *"Inline ... Template"* section
and write its content verbatim. Set `last_reviewed: <today>` in
frontmatter so staleness detection doesn't immediately flag.

- `INTENT.md` → `/spades:intent` § *Inline INTENT.md Template*
- `ARCHITECTURE.md` → `/spades:architecture` § *Inline ARCHITECTURE.md Template*
- `PATTERNS.md` → `/spades:patterns` § *Inline PATTERNS.md Template*
- `ANTI-PATTERNS.md` → `/spades:anti-patterns` § *Inline ANTI-PATTERNS.md Template*

### 7.E — Re-run safety

On re-run Step 7 re-classifies each file:

- Previously *Scaffolded-but-unfilled*, now *Complete* → skip silently.
- Previously *Complete* → stay skipped.
- Previously *Skip*, still missing → asked again.

## Step 9 — Confirm and summarise

Print a concise summary. Show `→` transitions for re-runs that
changed; append `(unchanged)` for unchanged fields. Use `✓` done,
`○` skipped, `✗` failed.

```
✓ Backend:        local → linear   (team: <name>, project: <name>)
✓ SCM:            local-git        (unchanged)
✓ Active project: spades-framework (unchanged)
✓ Migrated:       1 project, 3 scopes, 11 plans → Linear      # only if Step 2.6 walked
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

If Step 2.6 ran on *Skip migration*, the Migrated line becomes:

```
○ Migration:      skipped — local artefacts stay on disk; new
                  Linear-side work starts empty.
```

On fresh installs (no prior config), `(unchanged)` doesn't apply
— show chosen values without transitions.

Be brief — the human should confirm correctness in 10 seconds.

## Why AGENTS.md, not CLAUDE.md

`AGENTS.md` is the cross-agent convention — Claude Code, Cursor,
Codex, Aider and most agentic tools honour it. A consumer repo
gets one operating-rules file every agent reads, not one per
vendor. Don't write `CLAUDE.md`, `CURSOR.md`, or similar
per-agent variants.
