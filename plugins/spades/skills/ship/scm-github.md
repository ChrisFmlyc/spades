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

## 1. Verify the branch

```bash
git rev-parse --abbrev-ref HEAD
```

- On `main` / `master` → abort; `/spades:do` creates the feature
  branch, so something upstream went wrong and the human checks.
- Compare with the `Do phase started — … branch:` line in the Plan's
  audit trail. On a mismatch ask via `AskUserQuestion`: **Push the
  current branch anyway** / **Switch to the recorded branch and
  continue** / **Abort**.

## 2. Pre-push sweep

The last chance for pending SPADES artefacts to reach the deliverable
PR (`docs/FRAMEWORK.md § Carry-Forward of SPADES-Owned Artefacts`):

```bash
git add -- .spades AGENTS.md INTENT.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md 2>/dev/null || true
```

If anything was staged, commit it:

```bash
git commit -m "chore(spades): carry forward audit artefacts for <plan_id>"
```

Uncommitted files outside the allowlist are the human's work in
progress: they stay in the tree, out of the PR, and are named in one
line of the push report. Commits on the branch that don't belong to
this Plan are a review question for the human — surface them and
ask whether to rebase, split, or proceed.

## 3. Push

```bash
git push -u origin <branch>
```

## 4. Open the PR

```bash
gh pr create --title "<title>" --body "<body>"
```

**Title** — `<verb> <thing> (<plan-id>)`, e.g.
`Add RAG pipeline lookup (P-rag-pipeline-lookup-3HyD)`.

**Body** — from the Plan:

```markdown
## Summary

<2–3 sentences from the Plan's Technical Approach>

## SPADES audit trail

- Project: `<project-slug>`
- Scope:   `S-<scope-slug>`
- Plan:    `P-<plan-slug>-<suffix>`
- Approved: <YYYY-MM-DD> — routing: ai|human|hybrid
- Evaluation verdict: PASS

## Tasks completed

- [x] Task 1: <title>
- [x] Task 2: <title>

## Test plan

<from the Plan's Testing & Verification section>
```

Capture the PR URL from the output.

## 5. Record and exit

Append to the Plan's audit trail:

```markdown
- YYYY-MM-DD: PR opened: <URL>.
```

The Plan stays at `status: shipping`. Print the hand-off and return
to `/spades:ship`, which exits:

```
✓ PR opened: <URL>
○ Review bots run automatically where installed; address feedback
  by committing to this branch.

Once the PR is squash-merged:
  /spades:close P-<plan-id>  — verifies the merge, records the
                               Shipped marker on main via a
                               bookkeeping PR, mirrors to Linear
  /repo:sync                 — then brings main forward and deletes
                               the merged feature branch
```

## Edge cases

- **The PR fails to open** — branch not pushed, no remote, `gh`
  unauthenticated. Surface the exact error with the remediation; the
  Plan stays at `shipping`.
- **`gh` missing or unauthenticated** — show the human the exact
  `git push -u origin <branch>` and `gh pr create` invocation to run
  by hand, then capture the resulting URL and record it as in § 5.
- **Merge conflicts** — resolved as fix commits on the branch;
  re-run `/spades:ship` once the branch is clean.
