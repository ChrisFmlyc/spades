---
name: close
description: The single conversational entry point for closing out a Plan, Scope, Project, or Objective. Asks the human what they're doing — finalise as shipped/done/archived/complete (the happy path), reject (Plans only), or abandon (Scopes, Projects, and Objectives). Always asks before acting; flags `--reject "reason"` and `--abandon "reason"` are optional power-user shortcuts that skip the menu but still capture a reason. Use whenever someone says "close this", "close P-…", "close S-…", "close O-…", "complete this objective", "we're not doing this", "abandon this scope", "reject this plan", "this PR got closed without merging" — the skill figures out which flow applies.
version: 4.12.0
---

# /spades:close

You are the close-out entry point. The human names what to close;
you ask what kind of close it is and run the matching flow. Every
close lands on `main` through a small bookkeeping PR, so the audit
trail is committed history.

Four close actions:

1. **Pass** — finalise the lifecycle. Plan → `shipped` (a merged
   ship PR). Scope → `done` (every child Plan terminal). Project →
   `archived`. Objective → `complete` (the team lead's ungated
   judgement). Quick item → `shipped` (no bookkeeping PR, no rollup).
2. **Reject** — a non-terminal Plan → `rejected`, with a reason.
   Plans are attempts; rejection is the judgement on this attempt.
3. **Abandon** — a Scope, Project, or Objective → `abandoned`, with
   a reason. Containers are initiatives; abandonment is a walk-away.
4. **Drop** — a Quick item whose PR closed unmerged: delete the
   marker. Git history keeps the trace.

Read `docs/FRAMEWORK.md` § Target Resolution, § Terminal States,
§ Carry-Forward of SPADES-Owned Artefacts, and § Output Format
before running.

**Flow bodies live in `reference/`.** This file owns the entry
menus, the routing, and the bookkeeping-PR machinery every flow
shares. Read the flow file Step 3 routes you to:

| Route | Read |
|---|---|
| Pass on a Plan | [`reference/flow-plan-pass.md`](reference/flow-plan-pass.md) |
| Any Quick-item close | [`reference/flow-quick.md`](reference/flow-quick.md) |
| Reject, Abandon, Scope roll-up, Project archive, Objective complete | [`reference/flow-status-change.md`](reference/flow-status-change.md) |

### Output format

The target is read from its `.md`. HTML mode opens the target's
existing `.html` via the OPEN_CMD prelude as the human's view; the
terminal carries progress, prompts, and the confirmation. CLI mode
summarises the target inline. After the close-out edit in HTML
mode, re-dispatch the producing skill's `worker-html-*` so the page
shows the terminal status.

## Conversational entry

**Step 0 — Resolve the target.**

- **Explicit ID** — by prefix: `P-<slug>-<suffix>` → Plan;
  `O-<slug>` → Objective; `S-<slug>` → Scope; `Q-<slug>-<suffix>` →
  Quick item; a bare slug matching `.spades/projects/<slug>.md` →
  Project. Test `O-` before `S-` and `P-`.
- **No ID** — ask via `AskUserQuestion`, then run the matching
  picker: *Plan* (`approved`, `delivering`, `evaluating`,
  `shipping`) / *Scope* (any non-terminal) / *Objective* (`open`) /
  *Quick item* (`shipping`) / *Project* (`active`).
- **Ambiguous phrase** — offer the best one to three candidates.
- A Quick item skips Step 1: its action is unambiguous.

**Step 1 — Ask what kind of close.** Options depend on the target's
`status:`.

| Plan status | Menu |
|---|---|
| `draft` | *Leave in draft (no-op)* / *Reject* |
| `approved`, `delivering`, `evaluating` | *Reject* |
| `shipping` (has `PR opened:`, no `Shipped`) | *Pass — finalise as shipped* / *Reject* |
| `shipped`, `rejected` | abort: *"Plan `<id>` is already `<status>`. Terminal means terminal."* |

| Scope status | Menu |
|---|---|
| `scoped`, `planning` | *Abandon* |
| `delivering`, `evaluating`, `shipping` | *Pass — roll up to done* / *Abandon* |
| `done`, `abandoned` | abort: already terminal |

| Project status | Menu |
|---|---|
| `active` | *Pass — archive* / *Abandon* |
| `archived`, `abandoned` | abort: already terminal |

| Objective status | Menu |
|---|---|
| `open` | *Pass — mark complete* / *Abandon* |
| `complete`, `abandoned` | abort: already terminal |

**Step 2 — Capture the reason (Reject and Abandon).** Free-form:
*"Brief reason (one line) — why are you rejecting / abandoning?"*
An empty answer re-prompts: the audit trail needs the why.

**Step 3 — Route.** *Leave in draft* exits with *"Plan `<id>` left at
`draft`. Run `/spades:approve` when ready."* Pass on a Plan →
`flow-plan-pass.md`. Everything else → `flow-status-change.md`. A
Quick item → `flow-quick.md`.

## Shortcuts

- `/spades:close P-foo --reject "reason"`
- `/spades:close S-foo --abandon "reason"`
- `/spades:close <project-slug> --abandon "reason"`
- `/spades:close O-foo --abandon "reason"`

Objective completion carries no reason, so it has no flag: run
`/spades:close O-foo` and pick *Pass*. A flag on the wrong target
type, or a flag without a reason, aborts with the correct form.

## Bookkeeping-PR machinery

Every flow except the Quick close uses these steps by name.

### B1 — Preconditions

1. **Setup and active project** from `.spades/config`.
2. **`scm: github`.** Close finalises through a PR; with
   `scm: local-git` the artefact reached its terminal status inside
   `/spades:ship` and there is nothing to close — abort and say so.
3. **`repo` plugin installed**:

   ```bash
   [ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
   ```

   `missing` → abort: *"`/spades:close` requires the `repo` plugin
   from the `ai-skills` marketplace. Re-run `/spades:setup` — it
   walks through installing it."*
4. **Fetch.** `git fetch origin --quiet`. B2 branches straight off
   `origin/main`, so the current branch, a stale local `main`, and a
   dirty tree are all fine: uncommitted artefacts ride onto the
   bookkeeping branch and B3's sweep stages the SPADES-owned ones.
   Close is the final catch-all for carried-forward artefacts.
5. **Verify ancestors active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`, on the Pass route only.
   Reject and Abandon create terminal status; Objectives are
   independent of their Project.
6. **Open the review surface** per § Output format.

### B2 — Bookkeeping branch

Each flow supplies a `chore/<verb>-<slug>` name matching
`/repo:branch`'s regex
`^(feat|fix|chore|docs|refactor|rnd|hotfix)/[a-z0-9]([a-z0-9-]{0,48}[a-z0-9])?$`.
A slug over 50 characters falls back to the suffix chain
(`chore/close-9xaz-3hyd-28sd`). If the branch already exists from an
aborted run, abort: *"Bookkeeping branch `<name>` already exists.
Merge its PR on GitHub then re-run, or delete it (`git branch -D
<name>`) and re-run."*

```bash
git switch -c <bookkeeping-branch> origin/main
```

### B3 — Stage and commit

```bash
git add -- .spades AGENTS.md INTENT.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md 2>/dev/null || true
```

Commit with the flow's `chore(spades): <verb> <id>` subject and body.
Paths the sweep picked up beyond the flow's own edits are listed
under `Outstanding bookkeeping swept up:`.

### B4 — Open the bookkeeping PR

```bash
git push -u origin <bookkeeping-branch>
gh pr create --title "chore(spades): <verb> <id>" --body "…"
```

Body: `## Summary`, `## Linked artefacts` (IDs, and the ship PR plus
merge SHA where relevant), `## Files touched`, and a plain statement
that the PR is audit trail only plus anything swept from the tree.

```
○ Bookkeeping PR opened: <bookkeeping-pr-url>
○ Merge it on GitHub — squash recommended — then return here.
```

### B5 — Verify the bookkeeping PR merged

`gh` is available (B1), so probe rather than ask:

```bash
gh pr view <bookkeeping-pr> --json state,mergeCommit \
  --jq '"\(.state) \(.mergeCommit.oid // "-")"'
```

- **`MERGED`** → capture the SHA; continue to B6.
- **`OPEN`** → say so and exit cleanly. Once the human merges it,
  `/repo:sync` completes the close-out; re-running `/spades:close`
  is only needed for a Linear mirror. A driver that opened this PR
  and can merge it merges it here instead of exiting.
- **`CLOSED` unmerged** → surface it and stop; the edits are
  unlanded until the PR is re-opened or re-created.
- **Probe failure** (`gh` error, malformed response) → ask the human
  whether the PR merged; that is the one case only they can answer.

### B6 — Cleanup

```bash
git checkout main
git pull --ff-only
git branch -D <bookkeeping-branch>
git status --porcelain
```

Residue in the status is surfaced, not fatal.

### B7 — Linear mirror (`backend: linear`)

Runs after the bookkeeping commit is on `main`, so Linear never
leads the audit trail. Each flow states its own transition and
comment. With `backend: local` the file on `main` is the record.

## With `/repo:sync`

After a ship PR squash-merges: `/spades:close P-<id>` (bookkeeping
PR, merge verification, Linear mirror), then `/repo:sync` from the
merged feature branch so it deletes that branch as it brings `main`
forward. `/spades:loop` runs this sequence itself.

## Edge cases

- **Ship PR still open** — the Plan Pass flow reports it and exits
  before touching git or files.
- **Bookkeeping PR blocked by branch protection** — B5 sees `OPEN`
  and exits; the next probe after a manual merge continues.
- **Bookkeeping branch exists from an aborted run** — B2's message
  gives the two recovery paths.
