---
name: setup
description: Configure SPADES in this repository — choose a backend (Linear MCP or local filesystem), set the active project, scaffold AGENTS.md / ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md, and write .spades-anywhere/config. Use when starting fresh, when someone says "set up SPADES", "configure SPADES", "initialise SPADES", "I want to use SPADES in this repo". Re-runnable to reconfigure backend or refresh scaffolding without clobbering existing content.
version: 0.3.0
---

# /spades-anywhere:setup

Configure `spades-anywhere` in this project. Every other skill
assumes setup has run and `.spades-anywhere/config` exists.

**Re-runs ask every question again.** Current values appear as a
*"Currently configured: …"* context line above each
`AskUserQuestion` but never bias the recommended option. Step 2.5
diffs old vs new and requires explicit confirm before writes; Step
2.6 offers migration on backend switch. Setup never destroys
human-written content — scope / plan / learning files stay; the
AGENTS.md marker block is replaced in place, content outside the
markers is untouched.

`spades-anywhere` deliberately has **no `/repo` plugin
prerequisite**, **no SCM selection**, and **no git-repo check**.
The plugin runs in non-coding contexts (Claude Desktop, ChatGPT,
web/mobile) where there often is no git repo at all. If the
consumer chooses to put `.spades-anywhere/` under version control
they may, but the framework doesn't assume or require it.

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades-anywhere/
Local Layout before running — FRAMEWORK.md is canonical.

## Self-Init Guard

If this directory IS the SPADES framework repo itself
(`.claude-plugin/plugin.json` has `name: spades` or
`name: spades-anywhere`, or `plugins/spades-anywhere/` exists at
the root), abort:

> This is the SPADES framework's own repository. Setup is for
> consumer projects that want to *use* `spades-anywhere`, not for
> the framework itself.

(Dogfood only when explicitly told *"set up the dogfood project"*.)

## Pre-Flight — Capture existing config

```bash
[ -f .spades-anywhere/config ] && echo present || echo missing
```

`missing` (fresh install) → all `current_*` stay unset; Step 2.5
diff and Step 2.6 migration are skipped. `present` → read and
capture:

- `current_backend` (`linear` / `local`)
- `current_project` (slug)
- `current_linear_team`, `current_linear_project` (UUIDs, if Linear)
- `current_review_format` (`cli` / `html`; defaults to `cli` on
  older configs)

These feed the *"Currently configured: …"* preamble on Steps 1,
1.7, 2 and the diff in Step 2.5.

## Step 1 — Backend Selection

If `current_backend` is set, print above the question (never
recommend "Keep current"):

> *Currently configured: `backend: <current_backend>`. The choice
> below replaces it. Re-pick the same value if nothing's changed,
> or switch — your call, but please make it explicitly.*

`AskUserQuestion`:

- **`Linear`** — artefacts live as Linear Issues. Requires Linear
  MCP.
- **`Local`** — artefacts live as Markdown files under
  `.spades-anywhere/`. No external tracker; full audit trail
  in-store.

No "keep current" shortcut on re-run.

### If Linear was chosen

**Probe Linear MCP** (teams-list call). At least one team
returned → continue to *Bind team and project*.

**Probe fails** (no Linear MCP tool, 401/403, connection refused)
→ don't abort. Walk the human through install:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

Scope options: default **local** (this project only), `--scope
user` (every project on this machine), `--scope project`
(committed `.mcp.json`, shared with team). Recommend **local**
for the first run.

After adding, the human runs `/mcp` inside Claude Code, picks
Linear, completes the OAuth flow in the browser. Verify with
`claude mcp list` outside Claude Code, then `/mcp` inside —
Linear should show connected with ~25 tools. Re-run
`/spades-anywhere:setup` once connected.

**Bind team and project** (probe succeeded):

1. `AskUserQuestion`: which team? (list teams from probe).
2. `AskUserQuestion`: which Linear Project? (existing under the
   chosen team + *Create new Linear Project*).
3. If *Create new* → invoke `/spades-anywhere:newproject` inline.
4. Record `team_id` + `project_id` for Step 3.

### If Local was chosen

Nothing to verify externally.

## Step 1.7 — Review format

If `current_review_format` is set, print *"Currently configured:
`review_format: <current_review_format>`. Re-pick or switch."*.

`AskUserQuestion`: *How should `spades-anywhere` present reviews
and produce artefacts?*

- **HTML — auto-opens nicely formatted pages in your browser**
  *(Recommended)*. Artefacts under `.spades-anywhere/` are
  written as `.html`; review-form output auto-opens via `open` /
  `xdg-open` / `start`.
- **CLI — pastes plain-text/markdown output to the terminal**.
  Artefacts as `.md`; review output to CLI.

Recorded as `review_format:` in `.spades-anywhere/config` (Step
3). The choice toggles per-skill rendering only — the flow
itself is identical.

## Step 2 — Active Project

If `current_project` is set, print *"Currently active project:
`<current_project>`. Re-pick or switch."*.

`AskUserQuestion`:

- Existing `.spades-anywhere/projects/<slug>.md` records → offer
  them + *Create a new project*.
- No records → *Create a new project* only.

If *Create a new project* → invoke
`/spades-anywhere:newproject` inline; resume here with the new
slug.

Record the slug into `new_project` for Step 2.5's diff. Do **not**
write `.spades-anywhere/config` yet.

## Step 2.5 — Diff & Confirm

Diff captured `current_*` vs new answers. Three cases:

### Case A — Fresh install (no config existed)

Skip diff. Go straight to Step 3.

### Case B — Config existed, nothing changed

Every new value matches `current_*`. Print:

> *Nothing changed — backend and active project all match the
> existing config. Continue to refresh scaffolding (AGENTS.md
> marker block re-stamp, INTENT.md scaffold prompt, etc.)?*

`AskUserQuestion`: *Yes, refresh* / *Cancel — exit without writes*.

### Case C — Config existed, something changed

Show the diff:

```
Detected pre-existing config. Confirm these changes
before any writes happen:

  Backend:        <current_backend>  →  <new_backend>
  Active project: <current_project>  (unchanged)
  Linear team:    (unset)            →  <new_linear_team>      # if backend changing or linear chosen
  Linear project: (unset)            →  <new_linear_project>   # same

The local `.spades-anywhere/config` and AGENTS.md marker block
will be updated. Existing scopes / plans / learnings on disk are
NEVER deleted by this skill.
```

`(unchanged)` against fields where new = current. Only list
fields present in either old or new config.

`AskUserQuestion`:

- **Apply changes** — if `backend` is changing → Step 2.6.
  Otherwise → Step 3.
- **Cancel — exit without writes** — exits cleanly.

## Step 2.6 — Backend-switch migration

Fires **only** when `current_backend != new_backend`. Project /
Linear team or project changes alone skip to Step 3.

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

1. **Projects** — `.spades-anywhere/projects/<slug>.md` → Linear
   Project (via `mcp__linear-server__list_projects` filtered by
   team, then `mcp__linear-server__save_project` if no match).
   Write `linear_project_id` back. Disambiguate multi-match via
   `AskUserQuestion`.
2. **Scopes** — `.spades-anywhere/scopes/S-<slug>.md` → Linear
   Issue under the bound Project. Body = Scope markdown
   (Statement of Intent, Acceptance Criteria, Architectural
   Constraints, Out of Scope, Risk / Unknowns, Delivery
   Preference, Audit Trail). Status map: `scoped`→Triage/default,
   `planning`→Planning, `delivering`→In Progress, `done`→Done.
   Write `linear_issue_id` back.
3. **Plans** — `.spades-anywhere/plans/P-<…>.md` → sub-Issue
   under the Scope's parent Issue. Body = Plan markdown
   (Technical Approach, Tasks, Risks & Assumptions, Testing &
   Verification, Delivery Sequence, Audit Trail). Status map:
   `draft`→Backlog/default, `approved`→Approval,
   `delivering`→Delivering/In Progress, `evaluating`→Evaluating,
   `shipping`→Shipping, `shipped`→Done, `rejected`→Cancelled.
   Write `linear_issue_id` back.
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
  file, preserving `linear_issue_id`. Skips comments.
- **Skip — start fresh locally** — local files unchanged.
- **Cancel the backend switch** — back to Step 1.

### Migration error handling (both directions)

- **Linear MCP unreachable mid-walk** — abort gracefully;
  already-linked items retain `linear_*_id` frontmatter. On
  retry, Step 2.6 detects partial state and offers *Resume
  migration* / *Skip resume* / *Cancel*.
- **Duplicate title** — disambiguate via `AskUserQuestion`
  listing Linear IDs. Don't blind-pick.
- **Network / rate-limit** — surface verbatim; offer *Retry* /
  *Skip this item* / *Abort migration*.

## Step 3 — Write `.spades-anywhere/config`

```yaml
backend: linear            # or: local
project: <project-slug>
review_format: html        # or: cli  (defaults to cli on older configs)
linear:                    # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>
```

`spades-anywhere` has **no `scm:` field** — non-coding contexts
have no SCM concern.

Re-run safety: preserve values the human didn't change. Never
blank fields the human still depends on.

## Step 4 — Write `.spades-anywhere/version`

Read the plugin version from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` `"version"` and the
AGENTS.md version from
`${CLAUDE_PLUGIN_ROOT}/.spades-anywhere/version` (`agents_version=`),
then write both:

```
spades_anywhere_version=<plugin-version>
agents_version=<agents-version>
```

Idempotent — overwrite is fine.

## Step 5 — Scaffold the `.spades-anywhere/` subdirectories

Create if missing, no files inside:

- `.spades-anywhere/projects/`
- `.spades-anywhere/scopes/`
- `.spades-anywhere/plans/`
- `.spades-anywhere/learnings/`
- `.spades-anywhere/reviews/`

## Step 5.5 — Ignore transient HTML scratch (only if in a git repo)

`.spades-anywhere/.tmp/` holds regenerated HTML for status /
list / intent and must not be committed.

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

**Not in a git repo** → skip entirely. No `.gitignore` to
maintain. (Common case for Claude Desktop projects, ChatGPT,
mobile.)

**In a git repo** → idempotent:

1. No `.gitignore` → create with one line:
   `.spades-anywhere/.tmp/`.
2. `.gitignore` already lists `.spades-anywhere/.tmp` (with or
   without trailing `/`) → do nothing.
3. Otherwise append:

   ```
   # spades-anywhere transient HTML scratch — regenerated on every status/list/intent run
   .spades-anywhere/.tmp/
   ```

Append-only — never rewrite or reorder the rest of `.gitignore`.

## Step 6 — AGENTS.md (idempotent marker block)

If `AGENTS.md` doesn't exist at the repo root, create with one
line `# AGENTS.md` + blank line.

Insert or replace the block between these markers, stamping the
**AGENTS.md version** (`agents_version` from `.spades-anywhere/version`)
— not the plugin version — so the marker only signals stale when the
rules themselves changed:

```markdown
<!-- SPADES-ANYWHERE-FRAMEWORK-START v<agents-version> -->
…the content below…
<!-- SPADES-ANYWHERE-FRAMEWORK-END -->
```

Markers exist (any version) → replace in place. Markers absent
→ append. **Never** edit content outside the markers.

Content to write inside the markers:

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
| `/spades-anywhere:ship` | Capture shipment evidence + confirmation walk through `INTENT.md` success criteria; Plan → `shipping` |
| `/spades-anywhere:close` | Conversational close-out: pass / reject / abandon based on target. Pass finalises (Plan → shipped, Scope → done, Project → archived); reject (Plans) and abandon (Scopes, Projects) require a reason. Pure metadata — no SCM, no PR. |
| `/spades-anywhere:quick` | Fast-track for trivial human work — quick-item marker file (`.spades-anywhere/quick/Q-<id>.md`) is the canonical audit record |
| `/spades-anywhere:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades-anywhere:learn` | Capture a learning under `.spades-anywhere/learnings/` |
| `/spades-anywhere:research` | Read-only research via an isolated Opus subagent |
| `/spades-anywhere:list` | List active scopes, filterable by phase |
| `/spades-anywhere:status` | Show current phase + dependency graph |

**Note:** the spades-anywhere `/close` and `/quick` skills mirror
the **process** of their `spades` siblings, but the **mechanics**
differ. `/close` has no bookkeeping PR (no SCM); it's pure metadata
finalisation. `/quick`'s gate is time- and action-based (≤30 min,
single concrete action, no project-intent shift) rather than
LoC-based, because the work it covers is human, not code.

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
that skill's body changes, and the **AGENTS.md version** bumps only
when the operating rules change. The marker block above (`vX.Y.Z`)
carries the AGENTS.md version — it tells you which version of the
rules your AGENTS.md was last stamped against, and only reads as
stale when those rules actually changed (not on every unrelated
plugin upgrade). Re-running `/spades-anywhere:setup` re-stamps it.

Choose major / minor / patch by semver. When in doubt, lean
higher.

## Audit Trail

Every piece of work must trace through: project → scope → plan(s)
→ approval (with routing) → do-phase marker → evaluation verdict
→ shipment record (with per-INTENT-criterion evidence). Work that
cannot be traced through this chain must not ship.
```

## Step 7 — Project documentation (per-file ask)

Four durable project-level docs at the repo root (or knowledge
store root), each owned by its facilitator skill:

| File | Skill | Owns |
|------|-------|------|
| `INTENT.md` | `/spades-anywhere:intent` | Why the project exists, for whom, success, non-goals |
| `ARCHITECTURE.md` | `/spades-anywhere:architecture` | How the work is structured (stages, stakeholders, cadence, tools, constraints) |
| `PATTERNS.md` | `/spades-anywhere:patterns` | Approved process conventions |
| `ANTI-PATTERNS.md` | `/spades-anywhere:anti-patterns` | Explicit prohibitions ("we don't do X") |

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
>   facilitator can be invoked later.

### 7.D — Template content for "Scaffold empty"

Read each facilitator SKILL.md's *"Inline ... Template"* section
and write its content verbatim. Set `last_reviewed: <today>` in
frontmatter so staleness detection doesn't immediately flag.

- `INTENT.md` → `/spades-anywhere:intent` § *Inline INTENT.md Template*
- `ARCHITECTURE.md` → `/spades-anywhere:architecture` § *Inline ARCHITECTURE.md Template*
- `PATTERNS.md` → `/spades-anywhere:patterns` § *Inline PATTERNS.md Template*
- `ANTI-PATTERNS.md` → `/spades-anywhere:anti-patterns` § *Inline ANTI-PATTERNS.md Template*

### 7.E — Re-run safety

Previously *Scaffolded* files now *Complete* → skip silently.
Previously *Skipped* files (still missing) → asked again.
Idempotent.

## Step 8 — Confirm and summarise

Print a concise summary. Show `→` transitions for re-runs that
changed; append `(unchanged)` for unchanged fields. Use `✓` done,
`○` skipped, `✗` failed.

```
✓ Backend:        local → linear   (team: <name>, project: <name>)
✓ Active project: spades-framework (unchanged)
✓ Migrated:       1 project, 3 scopes, 11 plans → Linear      # only if Step 2.6 walked
                  (4 learnings stayed local by design)
✓ Config:         .spades-anywhere/config
✓ Version:        plugin <plugin-version>, rules <agents-version>
✓ Updated:        AGENTS.md (marker block re-stamped from v2.0.0 → v<agents-version>)
✓ Created:        ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md  (templates)
○ Skipped:        INTENT.md (re-run /spades-anywhere:intent to scaffold)

Next steps:
  /spades-anywhere:newproject       — if you haven't created one yet
  /spades-anywhere:scope <title>    — start a new Scope
```

If Step 2.6 ran on *Skip migration*, the Migrated line becomes:

```
○ Migration:      skipped — local artefacts stay on disk; new
                  Linear-side work starts empty.
```

On fresh installs (no prior config), `(unchanged)` doesn't apply.
Be brief — the human should confirm correctness in 10 seconds.

## Why AGENTS.md, not CLAUDE.md

`AGENTS.md` is the cross-agent convention — Claude Code, Cursor,
Codex, Aider, Claude Desktop, ChatGPT, and most agentic tools
honour it. A consumer gets one operating-rules file every agent
reads, not one per vendor. Don't write `CLAUDE.md`, `CURSOR.md`,
or similar per-agent variants.
