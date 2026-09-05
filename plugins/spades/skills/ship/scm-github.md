# Ship driver — `scm: github`

The GitHub driver for `/spades:ship` Branch A (`deliverable_type:
code`). It is a resource file, not a skill: `/spades:ship` reads it
when `.spades/config` has `scm: github`, follows it, and takes
control back at the end.

GitHub is a two-phase SCM. This file is Phase 1: publish the branch
as a PR and exit with the Plan at `status: shipping`. Phase 2 —
verifying the squash-merge, writing the `Shipped` marker to `main`
through a bookkeeping PR, and mirroring to Linear — is
`/spades:close P-<id>`, run after the PR merges.

## 1. Verify the Scope worktree

Resolve the Scope branch through `/repo:newbranch --resume <branch>` per
`docs/FRAMEWORK.md § Scope Worktrees`. Use its returned directory. A
mismatched branch requires returning to the recorded worktree, not publishing
whichever checkout happens to be current.

## 2. Commit approved pending records

Follow `docs/FRAMEWORK.md § Carry-Forward → Commit contents`. Inspect the
complete index, include authorised pending records, and preserve excluded
staged/unstaged changes. Existing committed work is already part of this
branch's PR and needs no additional inclusion question. Unknown uncommitted
work needs the human's decision before adding it.

If approved records remain, commit them through `/repo:branch` with
`chore(spades): record audit artefacts for <scope_id>`.

## 3. Push

```bash
git push -u <configured-remote> <branch>
```

## 4. Open or reuse the Scope PR

Look up the PR by the Scope branch and explicit configured base branch.
Reuse an existing open PR on resume; if it is merged or closed, surface
that state rather than creating another delivery PR from the old branch.
For a new PR, invoke `/repo:pr` with a title and body covering the Scope's
result, all participating Plans and their validation, then create it with
explicit `--head <scope-branch>` and `--base <default-branch>`.

Write the `/repo:pr` result to a body file, then create:

```bash
gh pr create --head <scope-branch> --base <default-branch> --title "<title>" --body-file <body-file>
```

The description covers the Scope's result, all participating Plan IDs,
approval/evaluation evidence and relevant validation. It describes the
whole branch's reviewed result rather than only the last Plan executed.

Capture the PR URL from the output.

## 5. Record and exit

Append to every participating code Plan's audit trail:

```markdown
- YYYY-MM-DD: PR opened: <URL>.
```

Each participating Plan stays at `status: shipping`. Print the hand-off and return
to `/spades:ship`, which exits:

```
✓ PR opened: <URL>
○ Review bots run automatically where installed; address feedback
  by committing to this branch.

Once the PR is squash-merged:
  /spades:close P-<plan-id>  — verifies the merge, records the
                               Shipped marker on main via a
                               bookkeeping PR, mirrors to Linear
  Worktrees remain available. New work starts via /repo:newbranch.
```

## Edge cases

- **The PR fails to open** — branch not pushed, no remote, `gh`
  unauthenticated. Surface the exact error with the remediation; the
  Plan stays at `shipping`.
- **`gh` missing or unauthenticated** — show the human the exact
  `git push -u <configured-remote> <branch>` and `gh pr create` invocation to run
  by hand, then capture the resulting URL and record it as in § 5.
- **Merge conflicts** — resolved as fix commits on the branch;
  re-run `/spades:ship` once the branch is clean.
