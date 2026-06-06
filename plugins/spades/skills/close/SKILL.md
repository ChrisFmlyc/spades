---
name: close
description: Close out a Plan whose `/spades:ship` PR has been squash-merged on GitHub. Opens a small bookkeeping PR that records the `Shipped` marker on `main`, waits for the human to merge it, then mirrors completion to Linear (when applicable) and rolls up the parent Scope. Assumes the local repo is already in post-merge sync (run `/repo:sync` first). Use after `/spades:ship` opened a PR and you've merged it on GitHub, when someone says "close this", "close P-…", "the PR is merged, mark it shipped", or when a Plan is in status `shipping` with a `PR opened:` marker.
version: 3.1.2
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

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. Anywhere this
skill would today print the Plan being closed to the terminal, in
HTML mode auto-open the Plan's existing `.html` file via the
OPEN_CMD prelude. The bookkeeping-PR workflow, sync invocations,
and Linear mirror calls are identical between modes.

## Pre-Flight

**Prerequisite — post-merge git state.** `/spades:close` does NOT do
the post-merge git cleanup itself — that's `/repo:sync`'s job (in the
`repo` plugin from the `ai-skills` marketplace). Before running
`/spades:close`, the human should have already run `/repo:sync` so
the local checkout is on a clean, fast-forwarded `main` with the
merged feature branch deleted. The precondition checks in step 4
below enforce this; the skill exits with a pointer to `/repo:sync`
if they fail. It will not auto-sync the local state — that boundary
lives elsewhere by design.


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

4. **Precondition checks — local state is post-merge-clean.**

   - Current branch:

     ```bash
     git rev-parse --abbrev-ref HEAD
     ```

     Must be `main` (or whatever the default branch is). If not,
     abort with: *"Run `/repo:sync` first — `/spades:close` expects
     to start on `main` after the merged feature branch has been
     cleaned up."*

   - Working tree clean:

     ```bash
     git status --porcelain
     ```

     Must return empty. If not, abort with: *"Working tree isn't
     clean. Commit, stash, or discard before running
     `/spades:close`."*

   - Local `main` is fast-forwarded to origin:

     ```bash
     git fetch origin --quiet
     git rev-list --count main..origin/main
     ```

     Must return `0`. If not, abort with: *"Local `main` is behind
     `origin/main`. Run `/repo:sync` first."*

   These checks are minimal on purpose. `/spades:close` doesn't
   duplicate `/repo:sync`; it just refuses to run if the
   preconditions `/repo:sync` would have satisfied aren't already
   met.

5. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `status: shipping` AND audit trail contains a
     `PR opened:` line AND no later `Shipped` line.
   - **Zero-candidate suggestion:** `/spades:ship P-…` to open a ship
     PR for an evaluated Plan first.

   If exactly one candidate matches and the human passed no Plan ID,
   pick it silently and announce. Otherwise, run the interactive
   picker.
6. **Read the Plan and parent Scope.** Capture:
   - `plan_id`, `plan_id_lower` (lowercased), `plan_slug`,
     `scope_id`, `project_slug`.
   - The PR URL from the most recent `PR opened:` line in the Plan's
     audit trail.
7. **Open the artefact (HTML mode only).** Read `review_format:`
   from `.spades/config`. When `review_format: html`, run the
   OPEN_CMD prelude (`docs/FRAMEWORK.md § OPEN_CMD detection
   prelude`) and open the Plan's `.html`. **In HTML mode the open
   `.html` IS the review surface — do NOT also paste / summarise
   the Plan body or audit trail to the CLI; the human has the
   browser tab.** Short conversational text (bookkeeping-PR
   progress, the final `✓ Plan closed …` confirmation, error
   messages) stays CLI as today. In CLI mode, summarise the Plan
   inline as today. See `docs/FRAMEWORK.md § Output Format → What
   counts as review-form text` for the canonical line.

## Step 1 — Verify the ship PR is merged

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

## Step 2 — Create the bookkeeping branch

You are on a clean `main`. Branch off it for the bookkeeping commit —
commits on `main` are forbidden (`/repo:branch` enforces this).

### 2.1 Choose the branch name

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

### 2.2 Create the branch

```bash
git switch -c <bookkeeping-branch>
```

## Step 3 — Apply the close-out edits

### 3.1 Edit the Plan file

Locate `.spades/plans/<plan_id>.md` (local mode) — or, for Linear
backend, edit the local mirror under `.spades/plans/` that the other
skills maintain. Update:

- Frontmatter `status:` → `shipped`.
- Frontmatter `updated:` → today's date.
- Append to the `## Audit Trail` section:

  ```markdown
  - YYYY-MM-DD: Shipped (github). PR: <URL>. Merge: <merge-sha>. Merged by: <login>.
  ```

### 3.2 Edit the Scope file (if rolling up)

Read all sibling Plans under `scope_id`. If every one is now
`status: shipped` (counting this one as already updated):

- Update `.spades/scopes/<scope_id>.md` frontmatter `status:` →
  `done`, `updated:` → today.
- Append to the Scope's `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: All plans shipped. Scope done.
  ```

Otherwise, leave the Scope unchanged — sibling Plans still in flight.

### 3.3 Stage + commit

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

## Step 4 — Open the bookkeeping PR

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

## Step 5 — Wait for the human to confirm the merge

Ask via `AskUserQuestion`:

> *Has the bookkeeping PR been merged?*
>
> - **Yes — bookkeeping PR is merged.** Continue with cleanup.
> - **Not yet — exit, I'll merge it and re-run `/spades:close`.**

If **Not yet** → exit cleanly. The bookkeeping PR stays open. After
the human merges it on GitHub, the recovery path is to run
`/repo:sync` (cleans up the merged bookkeeping branch) — at that
point the close-out is fully complete; no need to re-run
`/spades:close` unless the human still wants Linear mirroring or a
learning prompt.

## Step 6 — Post-bookkeeping cleanup

After the human confirms the bookkeeping PR is merged:

```bash
git checkout main
git pull --ff-only
git branch -D <bookkeeping-branch>
```

Assert clean:

```bash
git status --porcelain
```

If anything shows, surface it but don't abort — we've done the work,
the human can clean residue.

## Step 7 — Linear mirror (when `backend: linear`)

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
truth is the file on `main`, already updated by Step 4's bookkeeping
merge.

## Step 8 — Suggest a Learning

Same hand-off as `/spades:ship` Step 4. Ask via `AskUserQuestion`:

- **Capture a learning** (recommended) — invokes `/spades:learn`
- **Skip** — no learning this time

If yes, hand off to `/spades:learn` with the plan ID as context. The
learning will be tagged and stored under `.spades/learnings/`.

## Step 9 — Confirm

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

The intended flow after a `/spades:ship` PR is squash-merged on
GitHub is:

1. `/repo:sync` — cleans up the local checkout (clean `main`,
   delete the merged feature branch).
2. `/spades:close P-<id>` — opens the bookkeeping PR, waits for
   merge confirmation, mirrors to Linear, suggests a learning.

A future enhancement to the `repo` plugin would have `/repo:sync`
auto-detect Plans in `status: shipping` with a `PR opened:` marker
on the just-merged branch and offer to chain into `/spades:close`
automatically. Until that lands, run the two skills in sequence.

## Edge Cases

- **Local state isn't post-merge-clean.** Pre-Flight refuses and
  points at `/repo:sync`. The boundary is deliberate — `/spades:close`
  doesn't duplicate sync logic.
- **Ship PR isn't merged.** Step 1 catches this; the skill exits
  before touching git or files. Re-run after merging.
- **Bookkeeping branch already exists.** Step 2.1 catches this;
  the human picks recovery (merge the PR or delete the branch).
- **Bookkeeping PR can't be merged (branch protection, required
  reviews).** The human merges by hand on GitHub, then selects
  *Yes* on Step 5's prompt. Or selects *Not yet*, fixes the
  protection issue, comes back later.
- **Plan was already shipped on `main`** (e.g. legacy
  `/spades:ship` Step 6 finalised it without the bookkeeping PR).
  The target resolver returns zero candidates; the skill exits
  saying so. The Plan is fine — the audit trail just lives in a
  prior commit.
