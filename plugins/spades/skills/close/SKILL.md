---
name: close
description: Closes a Plan, Scope, Project, Objective, or Quick item through its matching lifecycle flow. Asks the human to finalise as shipped/done/archived/complete, reject a Plan, or abandon a Scope, Project, or Objective; Quick items follow their verified PR state. Flags `--reject "reason"` and `--abandon "reason"` skip the menu with the supplied reason. Use whenever someone says "close this", "close P-…", "close S-…", "close O-…", "complete this objective", "we're not doing this", "abandon this scope", "reject this plan", "this PR got closed without merging".
version: 4.15.0
---

# /spades:close

Resolve the target and run its close-out flow. Plans, Scopes, Projects
and Objectives record their terminal state on `main` through a bookkeeping
PR. Quick items land their marker flip on `main` the same way, through a
one-commit bookkeeping PR of their own: the Quick branch is already
merged, so a commit there never reaches `main`. A dropped Quick item's
marker never reached `main`, so its deletion is local.

Four close actions:

1. **Pass** — finalise the lifecycle. Plan → `shipped` (a merged
   ship PR). Scope → `done` (every child Plan terminal). Project →
   `archived`. Objective → `complete` (the team lead's ungated
   judgement). Quick item → `shipped` (a one-commit bookkeeping PR, no
   rollup).
2. **Reject** — a non-terminal Plan → `rejected`, with a reason.
3. **Abandon** — a Scope, Project, or Objective → `abandoned`, with
   a reason.
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

The target is read from its `.md`. HTML mode opens the target's existing
`.html` via the OPEN_CMD prelude as the human's view; the terminal
carries progress, prompts, and the confirmation. CLI mode presents the
target in the CLI review pane (`docs/FRAMEWORK.md § CLI review pane`) on
the close-out question. After the close-out edit in HTML mode,
re-dispatch the producing skill's `worker-html-*` with `open_path: null`
so the already-presented page shows the terminal status.

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
| `shipped`, `rejected` | abort: *"Plan `<id>` is already `<status>`."* |

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

Every flow uses these steps by name. The Quick close skips B1's Scope
resolution and B7's parent-Issue work; `flow-quick.md` says which of
B2–B7 it runs.

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
4. **Working context.** Resolve the source Scope/worktree and approved
   pending records per § Scope Worktrees and § Carry-Forward. Keep the
   source unchanged while preparing the bookkeeping handoff. Default-branch
   checks and pulling belong to `/repo:newbranch` in B2.

5. **Verify ancestors active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`, on the Pass route only.
   Reject and Abandon create terminal status; Objectives are
   independent of their Project.
6. **Open the review surface** per § Output format.

### B2 — Bookkeeping worktree

The flow supplies its close-out description and preferred `chore/` name.
Invoke `/repo:newbranch` with those and the configured remote; it owns
validation, default-branch preparation and worktree creation. All remaining
steps operate in the returned absolute directory. Re-read the records
there before applying edits. Transfer only approved pending source changes,
merging them with the fresh records and verifying the result. Preserve the
source worktree's files and index.

On resume, locate the existing bookkeeping PR/branch for the same target
and call `/repo:newbranch --resume <branch>` to use the recorded worktree.

### B3 — Stage and commit

Follow `docs/FRAMEWORK.md § Carry-Forward → Commit contents`. Include only
this flow's edits and approved transferred records, verifying the complete
proposed commit. Commit through `/repo:branch` with the flow's
`chore(spades): <verb> <id>` subject and describe any approved extra records.

### B4 — Open the bookkeeping PR

Pass the draft title/body through `/repo:pr` and write its result to a
body file. Use the configured remote and explicit head/base branches.

```bash
git push -u <configured-remote> <bookkeeping-branch>
gh pr create --head <bookkeeping-branch> --base <default-branch> --title "<title>" --body-file <body-file>
```

Body: `## Summary`, `## Linked artefacts` (IDs, and the ship PR plus
merge SHA where relevant), `## Files touched`, and a plain statement
that the PR contains audit-trail changes and any approved transferred records.

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
  re-run `/spades:close` in the bookkeeping worktree to verify the merge
  and finish any Linear mirror. A driver that opened this PR
  and can merge it merges it here instead of exiting.
- **`CLOSED` unmerged** → surface it and stop; the edits are
  unlanded until the PR is re-opened or re-created.
- **Probe failure** (`gh` error, malformed response) → ask the human
  whether the PR merged; that is the one case only they can answer.

### B6 — Retain the worktree

Verify the bookkeeping PR is merged and retain its branch, worktree and
remaining state in the current checkout. Report the merge reference and
any uncommitted residue; default-branch preparation belongs to the next
`/repo:newbranch` call.

### B7 — Linear mirror (`backend: linear`)

Runs after the bookkeeping commit is on `main`, so Linear never
leads the audit trail. Each flow states its own transition and
comment. With `backend: local` the file on `main` is the record.

## Subsequent work

Close verifies shipment and records its audit PR. The next piece of work
calls `/repo:newbranch`; default-branch preparation happens there. Cleanup
is a separate explicit request and does not gate close-out.

## Edge cases

- **Ship PR still open** — the Plan Pass flow reports it and exits
  before touching git or files.
- **Bookkeeping PR blocked by branch protection** — B5 sees `OPEN`
  and exits; the next probe after a manual merge continues.
- **Bookkeeping branch exists from an interrupted run** — B2 resumes
  its worktree and PR.
