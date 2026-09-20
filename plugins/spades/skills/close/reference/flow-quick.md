# Flow — Quick item close

Reached from `SKILL.md` Step 0 for a `Q-<slug>-<suffix>` target.
There is no menu: the action is to verify the PR merged and flip the
marker to `shipped`, with *Drop* offered once the PR is confirmed
closed unmerged. Quick items are leaf nodes — no Scope rollup — but the
flip has to reach `main`, and the Quick branch is already merged, so a
commit there never lands. The flip travels the same way a Plan's
`Shipped` marker does: a one-commit bookkeeping branch and PR from
`main` (**B2–B6**), prepared through `/repo:newbranch`. A Drop opens
no bookkeeping PR: its marker never reached `main`. Found on a consumer
repo where four merged Quick items still read `shipping` on `main`.

## Contents

- Q1 — Pre-flight
- Q2 — Probe the PR (two outcome classes; the replacement-PR sub-flow)
- Q3 — Flip to shipped
- Q4 — Drop
- Q5 — Persist, mirror and confirm

## Q1 — Pre-flight

1. **Setup and active project** from `.spades/config`.
2. **Read the marker** `.spades/quick/<Q-id>.md`: `id`, `pr_url`,
   `branch`, `linear_issue_id`, `status`. A marker already at
   `shipped` is terminal: *"Quick item `<Q-id>` is already
   `shipped`."*
3. **`scm: github`.** With `scm: local-git` the marker was written
   at `shipped` by `/spades:quick`; there is nothing to close.
4. Read the marker from the current checkout; the Quick branch is not
   resumed. Leave the source marker unchanged until Q5: the Q3 edit is
   made in the bookkeeping worktree Q5 prepares, and the Q4 deletion
   waits for Q5's mirror. A re-run after a failed Q5 finds it here
   again.
5. Print the marker's title and `pr_url`.

## Q2 — Probe the PR

```bash
gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
```

Dispatch on the verified PR state. Offer Drop only for a confirmed
`CLOSED` PR because it deletes the canonical marker.

**Probe failure** — `gh` error, unparseable JSON, `state` missing, or
`mergeCommit.oid` missing on `MERGED` → abort:

> *Couldn't query PR `<pr_url>`. Check `gh auth status`, network, or
> rate limits, then re-run `/spades:close Q-<id>`. The marker is
> untouched at `status: shipping`.*

**Probe succeeded**:

- **`MERGED`** → Q3.
- **`OPEN`** → report that the PR is still open and exit; re-run after
  its state changes.
- **`CLOSED`** → the work may have shipped under a replacement PR.
  `AskUserQuestion`: *Update PR — the work shipped under a different
  PR* (sub-flow below) / *Drop the quick item* → Q4 / *Cancel*.

### Replacement-PR sub-flow

The marker stays read-only until the replacement probe succeeds.

1. Prompt free-form for the replacement URL.
2. Validate: a GitHub PR URL under the same `owner/repo` as the
   current `pr_url`, and different from it. Otherwise re-prompt or
   *Cancel*.
3. Probe the replacement with the same `gh pr view` call.
   - **Failure** → *Try a different URL* / *Cancel*, marker untouched.
   - **Success** → carry the replacement as the new `pr_url` (Q3's
     edit writes it; the source marker stays untouched) and dispatch
     on its `state` as above. The original URL survives in the
     `Quick-path opened` audit line.

## Q3 — Flip to shipped

Decide the edit; Q5 writes it to the marker in the bookkeeping worktree,
never to the source checkout: `status: shipped`, `updated:` today, the
replacement `pr_url` if Q2 supplied one, and append:

```markdown
- YYYY-MM-DD: Shipped (github). PR: <pr_url>. Merge: <merge-sha>. Merged by: <login>.
```

The grammar matches the Plan `Shipped` line, so every `Shipped`
entry parses the same way. Continue to Q5.

## Q4 — Drop

The PR closed unmerged, so the marker never reached `main`: there is
nothing for a bookkeeping PR to delete, and none is opened. Capture
`linear_issue_id` (Q5 needs it) and leave the source marker in place;
Q5 deletes it after the mirror. The Quick branch's commit keeps the
trace. Continue to Q5.

## Q5 — Persist, mirror and confirm

**After Q3.** The Quick branch is merged; a commit on it never reaches
`main`. Land the edit through the shared bookkeeping machinery, leaving
the source marker untouched throughout:

1. **B2** with the description *"ship <Q-id>"* and the preferred name
   `chore/ship-<q-slug>`, where `<q-slug>` is the marker's slug without
   the `Q-` prefix, truncated to fit the branch-name limit. Apply the
   Q3 edit to the marker in the returned worktree; it already carries
   `status: shipping` and `pr_url` from the Quick PR. If a replacement
   PR landed the work without the marker, copy the source marker into
   the worktree first, then apply the edit.
2. **B3** with `chore(spades): ship <Q-id>`. One commit, the marker only.
3. **B4** — push and open the bookkeeping PR. Its body uses the shared
   B4 shape: `## Summary` (the Quick item shipped), `## Linked
   artefacts` (the Q-id, its PR and merge SHA, and the Linear issue if
   any), `## Files touched` (the marker alone), and the plain statement
   that the PR contains audit-trail changes.
4. **B5** — verify that PR merged. A driver that opened it and can
   merge it (a bot-review sweep, then squash) merges it here; otherwise
   exit and re-run `/spades:close Q-<id>` after the human merges it.
5. **B6** — retain the worktree.

Verify the bookkeeping commit contains the intended marker change and
the PR merged before mirroring or confirming completion. If any step
fails, report persistence as pending, retain the Q-id, bookkeeping
branch, outcome and mirror metadata, and resume from that step; the
source marker still reads `shipping`, so a re-run re-reads it in Q1 and
resumes the bookkeeping branch in B2.

**After Q4.** No bookkeeping PR. Run the mirror below, then delete
`.spades/quick/<Q-id>.md` from the current checkout. Deleting last
means a failed mirror leaves the marker for the re-run.

With `backend: linear` and a `linear_issue_id` (**B7**, after the
bookkeeping commit is on `main` for Q3):

- **After Q3** — issue In Review → Done; comment *"Merged via
  `/spades:close Q-<id>`. Merge: `<merge-sha>` by `<login>`."*
- **After Q4** — issue → Cancelled (or Backlog, per team
  convention); comment *"Quick item dropped — PR closed without
  merging."*

Confirm in one line: `✓ Q-<id> shipped. Merge: <merge-sha>. Bookkeeping:
<bookkeeping-pr-url>.` or `✓ Q-<id> dropped. Marker deleted from the
checkout; the Quick branch keeps the trace.`
