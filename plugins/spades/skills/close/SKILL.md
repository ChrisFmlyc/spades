---
name: close
description: Close out a Plan whose `/spades:ship` PR has been squash-merged on GitHub. Opens a small bookkeeping PR that records the `Shipped` marker on `main`, waits for the human to merge it, then mirrors completion to Linear (when applicable) and rolls up the parent Scope. Assumes the local repo is already in post-merge sync (run `/repo:sync` first). Use after `/spades:ship` opened a PR and you've merged it on GitHub, when someone says "close this", "close P-…", "the PR is merged, mark it shipped", or when a Plan is in status `shipping` with a `PR opened:` marker.
version: 2.0.0
---

# /spades:close

You are closing out a Plan whose `/spades:ship` PR has been
squash-merged on GitHub. Close opens a small bookkeeping PR that
lands the Plan-file's `Shipped` marker on `main`, waits for the human
to merge that bookkeeping PR, then mirrors completion to Linear (when
applicable) and confirms.

This skill is the consolidated replacement for the old
`/spades:ship P-<id>` resume path. `/spades:ship` Step 6 remains as a
legacy fallback; `/spades:close` is the recommended path.

Read `docs/FRAMEWORK.md` § Target Resolution before running.

## Dependency on `/repo:sync`

`/spades:close` does not duplicate `/repo:sync`'s logic — it **calls
it**. Twice. Once at the start to bring the local checkout into
post-merge state (clean `main`, merged feature branch deleted) and
once at the end to clean up the merged bookkeeping branch.

`/repo:sync` lives in the `repo` plugin from the `ai-skills`
marketplace. It's a hard prerequisite, surfaced by `/spades:setup`'s
Step 0 probe. The dependency is **one-directional**: close calls
sync; sync never calls close.

## Pre-Flight

1. **Confirm setup + active project.** Read `.spades/config`. Abort
   otherwise.
2. **Confirm `scm: github`.** If `scm: local-git` (or anything else),
   abort with:

   > *`/spades:close` is only meaningful for `scm: github`. Local-git
   > is single-phase — Plans go straight to `shipped` inside
   > `/spades:ship`. Nothing to close out.*

3. **Confirm the `repo` plugin is installed.** Probe:

   ```bash
   [ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
   ```

   If `missing`, abort with:

   > *`/spades:close` requires the `repo` plugin from the `ai-skills`
   > marketplace (for `/repo:sync` and `/repo:branch`). Re-run
   > `/spades:setup` — it walks through installing the prerequisite
   > plugins.*

4. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `status: shipping` AND audit trail contains a
     `PR opened:` line AND no later `Shipped` line.
   - **Zero-candidate suggestion:** `/spades:ship P-…` to open a ship
     PR for an evaluated Plan first.

   If exactly one candidate matches and the human passed no Plan ID,
   pick it silently and announce. Otherwise, run the interactive
   picker.
5. **Read the Plan and parent Scope.** Capture:
   - `plan_id`, `plan_id_lower` (lowercased), `plan_slug`,
     `scope_id`, `project_slug`.
   - The PR URL from the most recent `PR opened:` line in the Plan's
     audit trail.

## Step 1 — Verify the ship PR is merged

Fail fast before touching local state. `gh pr view` is a remote
query; it doesn't depend on the local checkout.

1. Parse the PR number from the captured URL (last `/pull/<n>`
   segment).
2. Query GitHub:

   ```bash
   gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
   ```

3. Branch on `state`:
   - `MERGED` → capture `mergeCommit.oid` (full SHA),
     `mergedBy.login`, `mergedAt`. Continue.
   - `OPEN` → tell the human the PR is still open. Show CI/review
     status if surfaced by `gh pr view`. Ask via `AskUserQuestion`:
     - *Wait — re-run later (exit, do nothing)*
     - *Abort — exit without changes*
   - `CLOSED` (not merged) → ask via `AskUserQuestion`:
     - *Mark the Plan rejected (status → `rejected`, audit entry)*
     - *Re-open the PR manually then re-run (exit, do nothing)*
     - *Abort*

   On any non-MERGED state, exit before Step 2 — nothing has changed.

## Step 2 — Run `/repo:sync` (initial)

The ship PR is confirmed merged. Bring the local checkout into
post-merge state by invoking the `repo` plugin's sync skill.

**Invoke `/repo:sync` now via the Skill tool.** The sync skill will:

- Detect the default branch.
- Refuse if the working tree is dirty (the human commits / stashes /
  discards then re-runs `/spades:close`).
- Fetch with `--prune` to surface the post-squash-merge `[gone]`
  upstream signal on the original feature branch.
- Check out `main`, fast-forward-pull, force-delete the merged
  feature branch.
- Print *"Ready."* on success.

If sync refuses (dirty tree, detached HEAD, indeterminate default
branch), surface its refusal message verbatim and exit. The human
fixes the underlying issue and re-runs `/spades:close`. Do not try
to bypass sync's guardrails.

On success, you are on `main`, clean, fast-forwarded to
`origin/main`, with the merged feature branch gone.

## Step 3 — Create the bookkeeping branch

You are on a clean `main`. Branch off it for the bookkeeping commit —
commits on `main` are forbidden (`/repo:branch` enforces this).

The bookkeeping branch is created in-place with `git switch -c` (not
`/repo:newbranch`, which creates a worktree). The bookkeeping edits
are small and need to land in the current checkout, not a separate
working tree.

### 3.1 Choose the branch name

The branch name MUST match the `/repo:branch` regex:

```
^(feat|fix|chore|docs|refactor|rnd|hotfix)/[a-z0-9]([a-z0-9-]{0,48}[a-z0-9])?$
```

Strategy:

1. Try `chore/close-<lower(plan_id_without_P_prefix)>`. Example:
   `chore/close-rag-pipeline-lookup-3hyd`.
2. If the slug exceeds 50 chars (chained Plan IDs can run long),
   fall back to `chore/close-<lower(suffix-chain-only)>`. Example:
   `chore/close-9xaz-3hyd-28sd`.
3. If a local branch with that name already exists (a previous
   `/spades:close` run aborted mid-flight), abort with:

   > *Bookkeeping branch `<name>` already exists from a previous
   > run. Either merge its PR on GitHub then re-run `/spades:close`,
   > or delete it (`git branch -D <name>`) and re-run.*

### 3.2 Create the branch

```bash
git switch -c <bookkeeping-branch>
```

## Step 4 — Apply the close-out edits

### 4.1 Edit the Plan file

Locate `.spades/plans/<plan_id>.md` (local mode) — or, for Linear
backend, edit the local mirror under `.spades/plans/` that the other
skills maintain. Update:

- Frontmatter `status:` → `shipped`.
- Frontmatter `updated:` → today's date.
- Append to the `## Audit Trail` section:

  ```markdown
  - YYYY-MM-DD: Shipped. PR: <URL>. Merge: <merge-sha>. Merged by: <login>.
  ```

### 4.2 Edit the Scope file (if rolling up)

Read all sibling Plans under `scope_id`. If every one is now
`status: shipped` (counting this one as already updated):

- Update `.spades/scopes/<scope_id>.md` frontmatter `status:` →
  `done`, `updated:` → today.
- Append to the Scope's `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: All plans shipped. Scope done.
  ```

Otherwise, leave the Scope unchanged — sibling Plans still in flight.

### 4.3 Stage + commit

```bash
git add .spades/plans/<plan_id>.md
# and, if the Scope was updated:
git add .spades/scopes/<scope_id>.md
git commit -m "$(cat <<'EOF'
chore(spades): close <plan_id>

Records the Shipped marker for <plan_id> on main. Original PR:
<URL>. Squash-merge: <merge-sha> by @<login>.

Scope <scope_id> rolled up to `done`.   # omit if not rolled up
EOF
)"
```

## Step 5 — Open the bookkeeping PR

```bash
git push -u origin <bookkeeping-branch>
```

```bash
gh pr create --title "chore(spades): close <plan_id>" --body "$(cat <<'EOF'
## Summary

Bookkeeping commit — records the SPADES audit trail for <plan_id>
on `main` after its ship PR was squash-merged.

## Linked artefacts

- Plan:        `<plan_id>`
- Scope:       `<scope_id>`
- Ship PR:     <URL>
- Merge SHA:   <merge-sha>
- Merged by:   @<login>

## Files touched

- `.spades/plans/<plan_id>.md` — `status: shipped`, audit entry.
- `.spades/scopes/<scope_id>.md` — `status: done`, audit entry.   # omit if not rolled up

No code changes. Pure audit trail.
EOF
)"
```

Capture the bookkeeping PR URL. Print it prominently:

```
○ Bookkeeping PR opened: <bookkeeping-pr-url>
○ Merge it on GitHub — squash recommended — then return here.
```

## Step 6 — Wait for the human to confirm the merge

Ask via `AskUserQuestion`:

> *Has the bookkeeping PR been merged?*
>
> - **Yes — bookkeeping PR is merged.** Continue with cleanup.
> - **Not yet — exit, I'll merge it and re-run `/spades:close`.**

If **Not yet** → exit cleanly. The bookkeeping PR stays open. After
the human merges it on GitHub, the recovery path is to re-run
`/spades:close` against the same Plan ID — but the target resolver
will now find zero candidates (the Plan on `main` already has
`Shipped`). The skill exits saying *"Plan already shipped on
main."* Nothing left to do; if the human wants Linear mirroring or a
learning prompt, they can run `/spades:learn` manually.

## Step 7 — Run `/repo:sync` (final)

The human has confirmed the bookkeeping PR is merged. Bring the
local checkout up to date one more time.

**Invoke `/repo:sync` now via the Skill tool.** Same skill as Step
2; this pass:

- Fetches with `--prune` to surface `[gone]` on the local
  bookkeeping branch (GitHub deleted the branch on squash-merge,
  per the bookkeeping PR's `--delete-branch` setting if used, or
  the repo's auto-delete-branches setting).
- Checks out `main`, fast-forward-pulls the squash-merge commit.
- Force-deletes the local bookkeeping branch.
- Prints *"Ready."*.

After this pass, the working tree is clean, on `main`, fast-forwarded
to `origin/main`, with no leftover branches. The audit trail for this
Plan now lives on `main` in the bookkeeping squash-merge commit.

If sync prints a warning instead of *"Ready."* (e.g. upstream still
exists because the human didn't delete the remote bookkeeping
branch), surface it but continue — the SPADES close-out is complete;
remaining git residue is harmless and the human can clean it up.

## Step 8 — Linear mirror (when `backend: linear`)

This step runs only after the bookkeeping commit is on `main` —
Linear is the live source of truth and should never lead the audit
trail.

When `backend: linear`:

- Update the Plan's sub-issue → status `Done`.
- If every sub-issue under the parent Scope's parent Issue is now
  `Done`, update the parent Issue → `Done`.
- Post a comment on the sub-issue:

  > *Shipped. PR: `<URL>` (squash-merge `<merge-sha>` by `@<login>`).
  > Bookkeeping audit: `<bookkeeping-pr-url>`.*

When `backend: local`: nothing to mirror. Local mode's source of
truth is the file on `main`, already updated by the bookkeeping
PR's merge (confirmed in Step 6).

## Step 9 — Suggest a Learning

Same hand-off as `/spades:ship` Step 4. Ask via `AskUserQuestion`:

- **Capture a learning** (recommended) — invokes `/spades:learn`
- **Skip** — no learning this time

If yes, hand off to `/spades:learn` with the plan ID as context. The
learning will be tagged and stored under `.spades/learnings/`.

## Step 10 — Confirm

One-block summary:

```
✓ Ship PR merged:        <URL>  (merge <short-sha> by @<login>)
✓ Bookkeeping PR merged: <bookkeeping-pr-url>
✓ Plan shipped:          <plan_id>
✓ Scope:                 <scope_id> (done — all plans shipped)   # omit "done" line if not rolled up
✓ Linear mirror:         sub-issue Done, parent Issue Done       # omit when backend: local
✓ Working tree:          clean, on main
✓ Status:                shipped

Next:
  /spades:learn                            — capture a learning
  /spades:status                           — see what's still open
```

## Workflow integration with `/repo:sync`

After a `/spades:ship` PR is squash-merged on GitHub, the human runs
**one** command:

    /spades:close P-<id>

That command internally invokes `/repo:sync` twice — once at the
start to bring the local checkout into post-merge state, once at the
end to clean up the merged bookkeeping branch — with the bookkeeping
PR open + merge-confirmation in between. The human never runs
`/repo:sync` directly in the SPADES close-out flow.

The dependency is **one-directional**: `/spades:close` calls
`/repo:sync`. `/repo:sync` never calls `/spades:close` — sync is a
general-purpose git-cleanup primitive and must not know about SPADES
artefacts.

## Edge Cases

- **Working tree dirty when close is invoked.** Step 2's
  `/repo:sync` call refuses on dirty trees; close surfaces sync's
  refusal verbatim and exits. The human commits / stashes / discards
  then re-runs `/spades:close`.
- **Ship PR isn't merged.** Step 1 catches this; the skill exits
  before touching git or files. Re-run after merging.
- **Bookkeeping branch already exists.** Step 3.1 catches this;
  the human picks recovery (merge the PR or delete the branch).
- **Bookkeeping PR can't be merged (branch protection, required
  reviews).** The human merges by hand on GitHub, then selects
  *Yes* on Step 6's prompt. Or selects *Not yet*, fixes the
  protection issue, comes back later.
- **Plan was already shipped on `main`** (e.g. legacy
  `/spades:ship` Step 6 finalised it without the bookkeeping PR).
  The target resolver returns zero candidates; the skill exits
  saying so. The Plan is fine — the audit trail just lives in a
  prior commit.
