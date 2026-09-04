# Flow — Plan Pass (finalise as shipped)

Reached from `SKILL.md` Step 3 for a Plan at `status: shipping`
whose human picked *Pass*. This flow verifies a merge it did not
perform, records the `Shipped` marker on `main`, and may roll the
parent Scope up. Everything else is SKILL.md's shared machinery
(**B1–B7**), referenced by name.

## Contents

- P1 — Pre-flight and target resolution
- P2 — Verify the ship PR merged
- P3 — Close-out edits (Plan, Scope rollup)
- P4 — Commit, PR, merge, cleanup, mirror
- P5 — Confirm

## P1 — Pre-flight

Run **B1**, then resolve the target: artefact type Plan; status
filter `shipping` with a `PR opened:` line and no later `Shipped`
line; zero candidates → suggest `/spades:ship P-…`. A single
candidate with no ID passed is picked and announced.

Read the Plan and parent Scope. Capture `plan_id`, `plan_slug`,
`scope_id`, `project_slug`, and the PR URL from the latest
`PR opened:` line.

## P2 — Verify the ship PR merged

```bash
gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
```

- **Probe failure** (`gh` error, unparseable JSON, `state` missing,
  or `mergeCommit.oid` missing on `MERGED`) → abort cleanly:
  *"Couldn't query PR `<URL>`. Check `gh auth status`, network, or
  rate limits, then re-run `/spades:close <plan_id>`. The Plan is
  untouched at `status: shipping`."*
- **`MERGED`** → capture `mergeCommit.oid`, `mergedBy.login`,
  `mergedAt`. Continue.
- **`OPEN`** → report it with any CI or review status shown.
  `AskUserQuestion`: *Wait — re-run later* / *Abort*. Both exit
  without changes.
- **`CLOSED`** unmerged → exit with the pointer: *"PR `<URL>` is
  closed without merge. Re-open it on GitHub to retry, or re-run as
  `/spades:close <plan_id> --reject "reason"`."* The human picks the
  flow.

Then **B2** with the branch `chore/close-<plan_id lower-cased,
without P->` (e.g. `chore/close-rag-pipeline-lookup-3hyd`).

## P3 — Close-out edits

### P3.1 — Plan

In `.spades/plans/<plan_id>.md`: `status: shipped`, `updated:` today,
and append:

```markdown
- YYYY-MM-DD: Shipped (github). PR: <pr_url>. Merge: <merge-sha>. Merged by: <login>.
```

### P3.2 — Scope rollup

Read every sibling Plan, counting this one as `shipped`, and
classify each as `shipped`, `rejected`, or in flight.

| Situation | Action |
|---|---|
| Every sibling `shipped`, acceptance criteria covered | Scope `status: done`, `updated:` today, append `- YYYY-MM-DD: All plans shipped. Scope done.` |
| Every sibling `shipped`, criteria left uncovered | Ask first (below). |
| All terminal, mix of `shipped` and `rejected`, ≥1 `shipped` | `AskUserQuestion` listing the rejected siblings. |
| Every sibling `rejected` | No rollup; the Scope shipped nothing. Say so; the Plan's own close-out proceeds. |
| A sibling in flight | No rollup. |

"All Plans terminal" is not "the Scope is done": Plans deferred at
planning and never written leave criteria untouched. Read the
Scope's acceptance criteria and check the shipped Plans cover them.
Where they don't, surface the uncovered criteria via
`AskUserQuestion`:

- **Leave the Scope open** *(recommended)* — append `- YYYY-MM-DD:
  Rollup withheld — <n>/<m> acceptance criteria uncovered: <list>.`
- **Roll up anyway** — record the uncovered criteria in the rollup
  line so the claim traces to a decision.

An accepted mixed-terminal rollup appends to the Scope:

```markdown
- YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected: <m>
  (acknowledged: P-<id-1>, P-<id-2>). Scope done.
```

A declined one leaves the Scope unchanged and appends to the Plan:

```markdown
- YYYY-MM-DD: Scope rollup deferred (mixed-terminal; human declined).
```

## P4 — Commit, PR, merge, cleanup, mirror

**B3** with:

```
chore(spades): close <plan_id>

Records the Shipped marker for <plan_id> on main. Original PR:
<URL>. Squash-merge: <merge-sha> by @<login>.

Scope <scope_id> rolled up to `done`.   # only when rolled up
```

Then **B4** (body lists the Plan, Scope, ship PR, merge SHA,
merged-by, files touched), **B5**, **B6**, and **B7** with:

- Plan sub-issue → Done.
- Parent Issue → Done, only when every sub-issue is Done.
- Comment on the sub-issue: *"Shipped. PR: `<URL>` (squash-merge
  `<merge-sha>` by `@<login>`). Bookkeeping audit:
  `<bookkeeping-pr-url>`."*

## P5 — Confirm

```
✓ Ship PR merged:        <URL>  (merge <short-sha> by @<login>)
✓ Bookkeeping PR merged: <bookkeeping-pr-url>
✓ Plan shipped:          <plan_id>
✓ Scope:                 <scope_id> (done — all plans shipped)   # when rolled up
✓ Linear mirror:         sub-issue Done, parent Issue Done       # backend: linear
✓ Working tree:          clean, on main
✓ Status:                shipped

Next:
  /spades:learn                            — capture a learning
  /spades:status                           — see what's still open
```

Omit the `/spades:learn` suggestion when the Plan's audit trail
already carries a `Loop — learning captured:` or `Loop — learning
declined.` line; that question was answered before close ran.
