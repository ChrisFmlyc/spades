---
name: close
description: The single conversational entry point for closing out a Plan, Scope, Project, or Objective. Asks the human what they're doing — finalise as shipped/done/archived/complete (the happy path), reject (Plans only), or abandon (Scopes, Projects, and Objectives). Always asks before acting; flags `--reject "reason"` and `--abandon "reason"` are optional power-user shortcuts that skip the menu but still capture a reason. Use whenever someone says "close this", "close P-…", "close S-…", "close O-…", "complete this objective", "we're not doing this", "abandon this scope", "reject this plan", "this PR got closed without merging" — the skill figures out which flow applies.
version: 4.7.0
---

# /spades:close

You are the close-out entry point. The human tells you what to
close; **you ask what kind of close it is** — pass, reject, or
abandon — and do the right thing for that target type.

Four close actions:

1. **Pass** (happy path) — finalise the lifecycle. Plan → `shipped`
   (needs a merged PR + bookkeeping commit). Scope → `done` (only
   when every child Plan is terminal). Project → `archived`
   (graceful sunset). Objective → `complete` (the team lead's
   **ungated** judgement — no rollup, no gating, no cascade). Quick
   item → `shipped` (lightweight: no bookkeeping commit, no rollup).
2. **Reject** — Plan rollback → `rejected`, for any non-terminal
   Plan. A `draft` Plan doesn't need rejection; the menu offers
   *"leave in draft (no-op)"*. Requires a reason.
3. **Abandon** — terminal walk-away on a container or objective →
   `abandoned`. Plans cannot be abandoned; they are attempts, not
   initiatives (`FRAMEWORK.md § Terminal States`). Requires a reason.
4. **Drop** — quick-item bail when its PR closed unmerged: delete
   the marker. Quick items have no terminal walk-away status by
   design; git history records the delete. No reason required.

Objectives use `complete` (not `done`) and have no `rejected` state
— they are strategic statements, not attempts. Completing or
abandoning one is independent of its Project and of any Scope.

Read `docs/FRAMEWORK.md` § Target Resolution and § Terminal States
before running.

**Flow bodies live in `reference/`.** This file owns the entry
menus, the routing decision, and the shared bookkeeping-PR
machinery every flow uses. Read the matching flow file when Step 3
routes you:

| Route | Read |
|---|---|
| Pass on a Plan | [`reference/flow-plan-pass.md`](reference/flow-plan-pass.md) |
| Any Quick-item close | [`reference/flow-quick.md`](reference/flow-quick.md) |
| Reject, Abandon, Scope roll-up, Project archive, Objective complete | [`reference/flow-status-change.md`](reference/flow-status-change.md) |

### Output format

Honours `review_format:` per `docs/FRAMEWORK.md § Output Format`.
Where this skill would print the target to the terminal, HTML mode
instead auto-opens its existing `.html` via the OPEN_CMD prelude.
The bookkeeping-PR workflow, sync invocations, and Linear mirror
calls are identical between modes.

## Conversational Entry

**Step 0 — Detect the target.**

- **Explicit ID** — resolve by prefix: `P-<slug>-<suffix>` → Plan;
  `O-<slug>` → Objective; `S-<slug>` → Scope; `Q-<slug>-<suffix>` →
  Quick item; a bare slug matching `.spades/projects/<slug>.md` →
  Project. **Resolve `O-` before `S-`/`P-`** to avoid
  mis-classifying an objective slug.
- **No ID** — ask via `AskUserQuestion`, then run the matching
  picker: *Plan* (status `approved`, `delivering`, `evaluating`,
  `shipping`) / *Scope* (any non-terminal) / *Objective* (glob
  `.spades/objectives/O-*.md`, status `open`) / *Quick item* (glob
  `.spades/quick/Q-*.md`, status `shipping`) / *Project* (status
  `active`).
- **Ambiguous reference** ("close that thing", "the newsletter
  scope") — surface 1–3 best candidates and ask. Never guess
  silently.
- **Quick item resolved → skip Step 1** and go straight to
  `reference/flow-quick.md`. Quick items have no menu; the action is
  unambiguous.

**Step 1 — Ask what kind of close.** Read the target's `status:`
first; the options are conditional on it.

**Plans**

| Status | Menu |
|---|---|
| `draft` | *Leave in draft (no-op)* / *Reject* |
| `approved` | *Reject* (no pass — not delivered yet) |
| `delivering` | *Reject* (no pass — not evaluated) |
| `evaluating` | *Reject* (no pass — not shipped) |
| `shipping` (has `PR opened:`, no `Shipped`) | *Pass — finalise as shipped (requires merged PR)* / *Reject* |
| `shipped` / `rejected` | abort: *"Plan `<id>` is already `<status>`. Terminal means terminal."* |

**Scopes**

| Status | Menu |
|---|---|
| `scoped` / `planning` (no Plans started) | *Abandon* (nothing to roll up) |
| `delivering` / `evaluating` / `shipping` | *Pass — roll up to done* / *Abandon* |
| `done` / `abandoned` | abort: already terminal |

**Projects**

| Status | Menu |
|---|---|
| `active` | *Pass — archive (graceful sunset)* / *Abandon* |
| `archived` / `abandoned` | abort: already terminal |

**Objectives**

| Status | Menu |
|---|---|
| `open` | *Pass — mark complete (team-lead judgement; no gating)* / *Abandon* |
| `complete` / `abandoned` | abort: already terminal |

Objectives are **ungated** on Pass — completion is judgement, not a
rollup — and have no `rejected` option.

**Step 2 — Capture a reason (Reject / Abandon only).**

Free-form follow-up: *"Brief reason (one line) — why are you
[rejecting / abandoning]?"* **Required.** An empty string
re-prompts: *"Rejecting / abandoning needs a reason. The audit trail
loses meaning without one."*

**Step 3 — Route.**

- *Leave in draft* → exit cleanly: *"Plan `<id>` left at `draft`.
  Run `/spades:approve` when ready."*
- *Pass* on a Plan → `reference/flow-plan-pass.md`.
- *Pass* on a Scope / Project / Objective, or *Reject* / *Abandon*
  on anything → `reference/flow-status-change.md`.
- Quick item → `reference/flow-quick.md` (routed at Step 0).

## Power-user Shortcuts

Two flags skip Step 1's menu but still carry a reason:

- `/spades:close P-foo --reject "reason"` → Plan Reject.
- `/spades:close S-foo --abandon "reason"` → Scope Abandonment.
- `/spades:close <project-slug> --abandon "reason"` → Project
  Abandonment.
- `/spades:close O-foo --abandon "reason"` → Objective Abandonment.

Objective *completion* has no flag — it carries no reason; run
`/spades:close O-foo` and pick *Pass*.

Invalid combinations abort clearly:

- `--abandon` with a Plan ID → *"Plans use `rejected`, not
  `abandoned`. Use `--reject "reason"` instead."*
- `--reject` with a Scope, Project, or Objective → *"Scopes,
  Projects, and Objectives use `abandoned`, not `rejected`. Use
  `--abandon "reason"` instead."*
- Either flag with no reason → *"<flag> needs a reason. Re-run with
  `<flag> "reason text here"`."*

## Shared bookkeeping-PR machinery

Every flow except Quick Close uses this. The flow files reference
these steps by name rather than restating them.

### B1 — Preconditions

1. **Setup + active project.** Read `.spades/config`; abort
   otherwise.
2. **`scm: github`.** Anything else → abort: *"`/spades:close` is
   only meaningful for `scm: github`. Local-git is single-phase —
   artefacts reach their terminal status in-skill. Nothing to close
   out."* (For local-git the human edits the file directly.)
3. **`repo` plugin installed:**

   ```bash
   [ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
   ```

   `missing` → abort: *"`/spades:close` requires the `repo` plugin
   from the `ai-skills` marketplace (for `/repo:sync` and
   `/repo:branch`). Re-run `/spades:setup` — it walks through
   installing the prerequisite plugins."*
4. **Post-merge git state.** Run `/repo:sync` **before**
   `/spades:close`; this skill enforces the resulting state but
   never auto-syncs.
   - `git rev-parse --abbrev-ref HEAD` must be the default branch.
     Otherwise abort: *"Run `/repo:sync` first — `/spades:close`
     expects to start on `main` after the merged feature branch has
     been cleaned up."*
   - `git fetch origin --quiet && git rev-list --count
     main..origin/main` must return `0`. Otherwise abort: *"Local
     `main` is behind `origin/main`. Run `/repo:sync` first."*
   - **A dirty working tree is fine** — no check. B3's sweep picks
     up SPADES-owned paths. Close is the final catch-all in
     `docs/FRAMEWORK.md § Carry-Forward of SPADES-Owned Artefacts`:
     anything earlier phases didn't sweep lands here.

   These are deliberately minimal. `/spades:close` doesn't duplicate
   `/repo:sync`; it refuses to run if the preconditions sync would
   have satisfied aren't already met.
5. **Verify ancestors active** per `FRAMEWORK.md § Target Resolution
   → Parent-status precondition`, **on the Pass route only**. Reject
   and Abandon are exempt — they *create* terminal status.
   Objectives are exempt entirely.
6. **Open the artefact (HTML mode).** Run the OPEN_CMD prelude and
   open the target's `.html`. **That open page IS the review surface
   — do not also paste or summarise the body to the CLI.** Short
   conversational text (progress, the final `✓` confirmation,
   errors) stays in the CLI either way.

### B2 — Create the bookkeeping branch

Commits on `main` are forbidden (`/repo:branch` Rule 1). Branch off
it; any uncommitted changes ride along and B3's sweep decides what
to stage.

The name MUST match `/repo:branch`'s regex:

```
^(feat|fix|chore|docs|refactor|rnd|hotfix)/[a-z0-9]([a-z0-9-]{0,48}[a-z0-9])?$
```

Each flow supplies its own `chore/<verb>-<slug>` name. If the slug
exceeds 50 chars (chained Plan IDs run long), fall back to the
suffix chain alone — e.g. `chore/close-9xaz-3hyd-28sd`. If the
branch already exists from an aborted run, abort:

> *Bookkeeping branch `<name>` already exists from a previous run.
> Either merge its PR on GitHub then re-run `/spades:close`, or
> delete it (`git branch -D <name>`) and re-run.*

Then `git switch -c <bookkeeping-branch>`.

### B3 — Stage + commit

Sweep SPADES-owned paths. **Allowlist only — never `git add -A` or
`git add .`:**

```bash
git add -- .spades AGENTS.md INTENT.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md 2>/dev/null || true
```

Commit with the flow's `chore(spades): <verb> <id>` subject and its
body. If the sweep picked up paths beyond the flow's own edits, list
them under an `Outstanding bookkeeping swept up:` block; omit that
block when it added nothing.

### B4 — Open the bookkeeping PR

```bash
git push -u origin <bookkeeping-branch>
gh pr create --title "chore(spades): <verb> <id>" --body "…"
```

Body carries a `## Summary`, a `## Linked artefacts` list (the IDs,
the ship PR + merge SHA where relevant), and `## Files touched`.
State plainly that there are no code changes — it is pure audit
trail, plus anything swept from a dirty worktree.

Print the URL prominently:

```
○ Bookkeeping PR opened: <bookkeeping-pr-url>
○ Merge it on GitHub — squash recommended — then return here.
```

### B5 — Wait for the human to confirm the merge

`AskUserQuestion`: *Has the bookkeeping PR been merged?*

- **Yes — bookkeeping PR is merged.** Continue to B6.
- **Not yet — exit, I'll merge it and re-run.** Exit cleanly; the PR
  stays open. Once merged on GitHub, the recovery path is
  `/repo:sync` — at that point the close-out is complete and there
  is no need to re-run `/spades:close` unless the human still wants
  Linear mirroring.

### B6 — Post-bookkeeping cleanup

```bash
git checkout main
git pull --ff-only
git branch -D <bookkeeping-branch>
git status --porcelain
```

If anything shows in the status, surface it but don't abort — the
work is done and the human can clear residue.

### B7 — Linear mirror (when `backend: linear`)

Runs **only after** the bookkeeping commit is on `main` — Linear is
the live source of truth and must never lead the audit trail. Each
flow states its own status transition and comment text.

When `backend: local` there is nothing to mirror; the file on `main`
is the record.

## Workflow integration with `/repo:sync`

After a `/spades:ship` PR is squash-merged:

1. `/repo:sync` — clean `main`, delete the merged feature branch.
2. `/spades:close P-<id>` — bookkeeping PR, merge confirmation,
   Linear mirror, learning suggestion.

A future `repo` enhancement could have `/repo:sync` detect Plans in
`status: shipping` with a `PR opened:` marker on the just-merged
branch and offer to chain into `/spades:close`. Until then, run the
two in sequence. `/spades:loop` automates exactly this pairing.

## Edge Cases

- **Local state isn't post-merge-clean.** B1 refuses and points at
  `/repo:sync`. The boundary is deliberate — close doesn't duplicate
  sync logic.
- **Ship PR isn't merged.** The Plan Pass flow catches it and exits
  before touching git or files. Re-run after merging.
- **Bookkeeping branch already exists.** B2 catches it; the human
  picks recovery.
- **Bookkeeping PR can't be merged** (branch protection, required
  reviews). The human merges by hand, then answers *Yes* at B5 — or
  *Not yet*, fixes the protection, and returns.
- **Plan was already shipped on `main`** (legacy `/spades:ship` Step
  6 finalised it without a bookkeeping PR). The resolver returns
  zero candidates and the skill says so. The Plan is fine; its audit
  trail just lives in a prior commit.
- **Target is already terminal.** Each flow's pre-flight catches it
  and aborts without touching files.
- **`--abandon` with a Plan ID.** The shortcut validation catches
  it and explains that Plans use `rejected`.
