# Flow — Plan Pass (finalise as shipped)

Reached from `SKILL.md` Step 3 when the target is a Plan in
`status: shipping` and the human picked *Pass* (or invoked bare
`/spades:close P-foo` with a merged PR detected).

This is the only flow with real complexity: it verifies a merge it
did not perform, and it may roll the parent Scope up. Everything
else is SKILL.md's shared bookkeeping machinery (**B1–B7**), which
this file references by name rather than restating.

## Contents

- P1 — Pre-flight (B1 plus Plan resolution)
- P2 — Verify the ship PR is merged
- P3 — Apply the close-out edits (Plan file, Scope rollup)
- P4 — Commit, PR, merge, cleanup, mirror
- P5 — Confirm

## P1 — Pre-flight

Run **B1** (setup, `scm: github`, `repo` plugin, post-merge git
state, ancestor check, HTML open), then resolve the target:

- **Artefact type:** Plan.
- **Status filter:** `status: shipping` AND the audit trail contains
  a `PR opened:` line AND no later `Shipped` line.
- **Zero candidates:** suggest `/spades:ship P-…` to open a ship PR
  for an evaluated Plan first.
- Exactly one candidate and no ID passed → pick it silently and
  announce. Otherwise run the interactive picker.

Read the Plan and parent Scope. Capture `plan_id`, `plan_id_lower`,
`plan_slug`, `scope_id`, `project_slug`, and the PR URL from the
most recent `PR opened:` line.

## P2 — Verify the ship PR is merged

Parse the PR number (last `/pull/<n>` segment) and query:

```bash
gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
```

**Probe failure** — `gh` exits non-zero, JSON parse fails, or a
required field is missing (`state` null/absent, or `mergeCommit.oid`
missing when `state: MERGED`) — abort cleanly:

> *Couldn't query PR `<URL>` — `gh` returned an error or incomplete
> data. Re-run `/spades:close <plan_id>` after fixing the underlying
> issue (check `gh auth status`, network, GitHub rate limit). The
> Plan is untouched at `status: shipping`.*

Nothing destructive happens before P3, so a probe failure is purely
re-runnable — but stating the remediation stops humans guessing.

**Probe succeeded** — branch on `state`:

- **`MERGED`** → capture `mergeCommit.oid` (full SHA),
  `mergedBy.login`, `mergedAt`. Continue to P3.
- **`OPEN`** → tell the human the PR is still open; show CI/review
  status if `gh pr view` surfaced it. `AskUserQuestion`: *Wait —
  re-run later (exit, do nothing)* / *Abort — exit without changes*.
- **`CLOSED`** (not merged) → exit with a pointer to Reject: *"PR
  `<URL>` is closed without merge. The Plan can't pass — re-run as
  `/spades:close <plan_id> --reject "reason"` to mark the Plan
  rejected, or re-open the PR on GitHub to retry the merge."* The
  skill never silently switches flows; the human picks Reject.

On any non-`MERGED` state, exit **before** P3 — nothing has changed.

Then run **B2** to create the bookkeeping branch, named
`chore/close-<lower(plan_id without the P- prefix)>` — e.g.
`chore/close-rag-pipeline-lookup-3hyd`.

## P3 — Apply the close-out edits

### P3.1 Plan file

In `.spades/plans/<plan_id>.md` (for the Linear backend, the local
mirror the other skills maintain):

- Frontmatter `status:` → `shipped`; `updated:` → today.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Shipped (github). PR: <pr_url>. Merge: <merge-sha>. Merged by: <login>.
  ```

### P3.2 Scope file — mixed-terminal-aware rollup

Read every sibling Plan under `scope_id`, counting this one as
already `shipped`. Classify each as `shipped` (terminal, success),
`rejected` (terminal, a prior explicit decision), or anything else
(still in flight).

| Situation | Action |
|---|---|
| **Every sibling `shipped`** | Roll up silently. Scope `status:` → `done`, `updated:` → today. Append `- YYYY-MM-DD: All plans shipped. Scope done.` |
| **All terminal, mix of `shipped` and `rejected`, ≥1 `shipped`** | Ask the human to acknowledge via `AskUserQuestion`, **listing the rejected siblings** so the acknowledgement is informed. |
| **Every sibling `rejected`** | No rollup — the Scope shipped nothing. Surface it and stop short of the rollup edit. The Plan's own close-out still proceeds. |
| **Any sibling still in flight** | No rollup; leave the Scope unchanged. |

On an accepted mixed-terminal acknowledgement, append to the Scope:

```markdown
- YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected: <m>
  (acknowledged: P-<id-1>, P-<id-2>). Scope done.
```

If the human declines, the Plan still closes out (`shipped`) but the
Scope stays unchanged — append to the **Plan's** audit trail:

```markdown
- YYYY-MM-DD: Scope rollup deferred (mixed-terminal; human declined).
```

## P4 — Commit, PR, merge, cleanup, mirror

Run **B3** with:

```
chore(spades): close <plan_id>

Records the Shipped marker for <plan_id> on main. Original PR:
<URL>. Squash-merge: <merge-sha> by @<login>.

Scope <scope_id> rolled up to `done`.   # omit if not rolled up
```

Then **B4** (PR body lists the Plan, Scope, ship PR, merge SHA,
merged-by, and the files touched), **B5** (wait for the merge),
**B6** (cleanup), and **B7** with this mirror:

- Plan's sub-issue → `Done`.
- Parent Issue → `Done`, but **only if** every sub-issue under it is
  now `Done`.
- Comment on the sub-issue: *"Shipped. PR: `<URL>` (squash-merge
  `<merge-sha>` by `@<login>`). Bookkeeping audit:
  `<bookkeeping-pr-url>`."*

`/spades:close` does not invoke `/spades:learn` inline — P5 surfaces
it as a suggestion and the human runs it separately.

## P5 — Confirm

```
✓ Ship PR merged:        <URL>  (merge <short-sha> by @<login>)
✓ Bookkeeping PR merged: <bookkeeping-pr-url>
✓ Plan shipped:          <plan_id>
✓ Scope:                 <scope_id> (done — all plans shipped)   # omit if not rolled up
✓ Linear mirror:         sub-issue Done, parent Issue Done       # omit when backend: local
✓ Working tree:          clean, on main
✓ Status:                shipped

Next:
  /spades:learn                            — capture a learning
  /spades:status                           — see what's still open
```
