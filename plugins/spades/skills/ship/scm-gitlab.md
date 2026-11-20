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

`<configured-remote>` is `gitlab.remote` (default `origin`). First check
that its URL still names `gitlab.host` and `gitlab.project`
(`docs/FRAMEWORK.md § SCM Drivers`); a mismatch is a stop that names
both. Then:

```bash
git push -u <configured-remote> <branch>
```

A rejected push stops here with the Plan at its current status: show
the remote's message and its cause per `docs/FRAMEWORK.md § SCM Drivers
→ Pushing`. The branch is never amended, rebased or force-pushed to get
past it.

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
glab mr create -R <repo-url> --head <repo-url> --source-branch <scope-branch> --target-branch <default-branch> \
  --title "<title>" --description-file <body-file> --squash-before-merge --yes
```

`<repo-url>` is `https://<gitlab.host>/<gitlab.project>`. `-R` names it
as the MR's target project and `--head` as its source project, the one
§ 3 pushed the branch to. `glab mr create` prints a summary rather than
a URL, so read the MR's `iid` and `web_url` back with
`find_review(<scope-branch>, <default-branch>)`.

The MR opens ready for review, never as a draft: review bots skip draft
MRs, and GitLab opens one as a draft when its title starts with `Draft:`
or `[Draft]`, so the title never does. Confirm with `glab mr view <iid> -R
<repo-url> --output json | jq .draft` reading `false`.

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
  status --hostname <gitlab.host>`, `glab auth login --hostname
  <gitlab.host>`); the Plan stays at `shipping`. A 404 means the
  project is missing or this account cannot see it.
- **The push is rejected** — a push rule, a lapsed SAML SSO session, or
  branch protection; § 3 and `docs/FRAMEWORK.md § SCM Drivers →
  Pushing`.
- **`glab` missing or unauthenticated** — open the MR without `glab`.
  GitLab acts on push options only when the push updates the branch.
  If the branch has commits `<configured-remote>` does not have yet,
  show the human
  `git push -u <configured-remote> <branch> -o merge_request.create -o merge_request.target=<default-branch> -o merge_request.title="<title>"`;
  GitLab prints the MR's link in the push's `remote:` lines, and the
  description goes in afterwards on GitLab, since push options carry no
  line breaks. Once the remote has the whole branch, as it does after
  § 3, give the human GitLab's new-MR page instead,
  `https://<gitlab.host>/<gitlab.project>/-/merge_requests/new?merge_request%5Bsource_branch%5D=<branch>&merge_request%5Btarget_branch%5D=<default-branch>`,
  to create the MR there with the `/repo:pr` title and body, and ask
  them for its link. On either route the human ticks the MR's "Squash
  commits when merge request is accepted" option, so a merge in the
  GitLab UI squashes; record the link as in § 5.
- **Merge conflicts** — resolved as fix commits on the branch;
  re-run `/spades:ship` once the branch is clean.
