# Ship driver — `scm: gitlab`

The GitLab driver for `/spades:ship` Branch A (`deliverable_type:
code`). It is a resource file, not a skill: `/spades:ship` reads it
when `.spades/config` has `scm: gitlab`, follows it, and takes
control back at the end.

GitLab is a two-phase SCM. This file is Phase 1: publish the branch
as a merge request (MR) and exit with the Plan at `status: shipping`.
Phase 2 — verifying the squash-merge, writing the `Shipped` marker to
`main` through a bookkeeping MR, and mirroring to Linear — is
`/spades:close P-<id>`, run after the MR merges. Commands come from
`docs/FRAMEWORK.md § SCM Drivers`.

## 1. Verify the Scope worktree

Resolve the Scope branch through `/repo:newbranch --resume <branch>` per
`docs/FRAMEWORK.md § Scope Worktrees`. Publish from its returned directory
after verifying that it matches the recorded branch.

## 2. Commit approved pending records

Follow `docs/FRAMEWORK.md § Carry-Forward → Commit contents`. Inspect the
complete index, include authorised pending records, and preserve excluded
staged/unstaged changes. Existing committed work is already part of this
branch's MR and needs no additional inclusion question. Unknown uncommitted
work needs the human's decision before adding it.

If approved records remain, commit them through `/repo:branch` with
`chore(spades): record audit artefacts for <scope_id>`.

## 3. Push

```bash
git push -u <configured-remote> <branch>
```

`<configured-remote>` is `gitlab.remote` (default `origin`).

## 4. Open or reuse the Scope MR

Look up the MR with `find_review(<scope-branch>, <default-branch>)`.
Reuse an existing open MR on resume; if it is merged or closed, surface
that state rather than creating another delivery MR from the old branch.
For a new MR, invoke `/repo:pr` with a title and body covering the Scope's
result, all participating Plan IDs, approval/evaluation evidence and
relevant validation.

Write the `/repo:pr` result to a body file, then create the MR with
`open_review`:

```bash
glab mr create --source-branch <scope-branch> --target-branch <default-branch> \
  --title "<title>" --description-file <body-file> --yes
```

Capture the MR URL from the output.

## 5. Record and exit

Append to every participating code Plan's audit trail:

```markdown
- YYYY-MM-DD: MR opened: <URL>.
```

Each participating Plan stays at `status: shipping`. Print the hand-off and
return to `/spades:ship`, which exits:

```
✓ MR opened: <URL>
○ Review bots run automatically where installed; address feedback
  by committing to this branch.

Once the MR is squash-merged:
  /spades:close P-<plan-id>  — verifies the merge, records the
                               Shipped marker on main via a
                               bookkeeping MR, mirrors to Linear
  Worktrees remain available. New work starts via /repo:newbranch.
```

## Edge cases

- **The MR fails to open** — branch not pushed, no remote, `glab`
  unauthenticated, or the remote's host isn't the one `glab` is logged
  in to. Surface the exact error with the remediation (`glab auth
  status`, `glab auth login --hostname <host>` for a self-managed
  instance); the Plan stays at `shipping`.
- **`glab` missing or unauthenticated** — show the human the exact
  `git push -u <configured-remote> <branch>` and `glab mr create`
  invocation to run by hand, then capture the resulting URL and record
  it as in § 5.
- **Merge conflicts** — resolved as fix commits on the branch;
  re-run `/spades:ship` once the branch is clean.
