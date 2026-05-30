# Ship driver — `scm: github`

This file is the GitHub driver for `/spades:ship`. SKILL.md loads it
when `.spades/config` has `scm: github` and the Plan being shipped is
`deliverable_type: code`. It is not a skill on its own — it has no
frontmatter and is not invoked directly. Read it from SKILL.md, follow
the phase that matches the current run, then return.

Two phases:

- **Phase 1 — Fresh ship.** Push the branch, open the PR, exit. The
  Plan stays in `status: shipping`.
- **Phase 2 — Resume after merge.** Triggered when SKILL.md's Step 0
  finds a `PR opened:` marker in the audit trail with no later
  `Shipped:` marker. Verifies the merge, records the merge SHA, marks
  the Plan `shipped`.

SKILL.md decides which phase you're in and points you here. If you
arrived from Step 2 (fresh) → run Phase 1. If you arrived from Step 6
(resume) → run Phase 2.

## Phase 1 — Fresh ship

`/spades:do` created the branch and committed; this phase publishes
via PR. No auto-merge — squash-merge happens in GitHub after
CodeRabbit review.

### 1. Verify on the right branch

- `git rev-parse --abbrev-ref HEAD` — current branch
- If on `main` / `master`: error. `/spades:do` should have created a
  feature branch. Abort and suggest the human verifies what
  happened.
- Read the Plan's audit trail. Find the `Do phase started — branch:`
  line. If the current branch doesn't match, warn via
  `AskUserQuestion`:
  - *Push the current branch anyway (overrides the audit-trail
    branch)*
  - *Switch to the recorded branch and continue*
  - *Abort*

### 2. Pre-push checks

- Are there uncommitted changes? Surface them; ask via
  `AskUserQuestion` whether to commit (with a follow-up free-form
  message), stash, or discard before pushing.
- Does the branch include commits that don't belong to this Plan?
  If so, surface them; ask whether to rebase / split or proceed.

### 3. Push

Push the branch to origin:

```bash
git push -u origin <branch>
```

Capture the output.

### 4. Open the PR

Open a PR via `gh pr create`. Title and body derived from the Plan:

**Title** — short, descriptive. Suggested form:
`<verb> <thing> (<plan-id>)`. e.g.
`Add RAG pipeline lookup (P-rag-pipeline-lookup-3HyD)`.

**Body** — generated from the Plan:

```markdown
## Summary

<2-3 sentences from the Plan's Technical Approach>

## SPADES audit trail

- Project: `<project-slug>`
- Scope:   `S-<scope-slug>`
- Plan:    `P-<plan-slug>-<suffix>`
- Approved: <YYYY-MM-DD> — routing: ai|human|hybrid
- Evaluation verdict: PASS

## Tasks completed

- [x] Task 1: <title>
- [x] Task 2: <title>
- [x] Task 3: <title>

## Test plan

<from the Plan's Testing & Verification section>
```

Capture the PR URL from `gh pr create`'s output.

### 5. Record Phase 1 completion and exit

Append to the Plan's audit trail:

```markdown
- YYYY-MM-DD: PR opened: <URL>.
```

Plan stays in `status: shipping`. Print the hand-off:

```
✓ PR opened: <URL>
○ CodeRabbit will run automatically (if installed on the repo).
○ Address review feedback by committing to this branch.

Once the PR is squash-merged:
  /repo:sync                — clean up main + the local branch
  /spades:ship P-<plan-id>  — record the merge SHA, mark shipped

Plan stays in `shipping` until the resume runs.
```

**Exit here.** Do NOT continue past Phase 1 — return to SKILL.md, which
exits without running Steps 3+ on a Phase 1 run.

## Phase 2 — Resume after merge

You arrive here because SKILL.md's Step 0 detected a `PR opened:` line
in the audit trail with no `Shipped:` line, and SKILL.md routed to
Step 6 → this driver's Phase 2.

1. **Parse the PR URL** from the most recent `PR opened:` line.
   Extract the PR number (last segment of `/pull/<n>`).
2. **Verify merge state:**

   ```bash
   gh pr view <number> --json state,mergeCommit,mergedAt,mergedBy
   ```

   - `state == "MERGED"` → capture `mergeCommit.oid` and
     `mergedAt`. Continue.
   - `state == "OPEN"` → tell the human the PR is still open; show
     a one-line summary (CI status, reviews). Ask via
     `AskUserQuestion`:
     - *Wait — re-run later*
     - *Abort — record nothing, exit*
   - `state == "CLOSED"` (not merged) → ask the human how to
     handle: re-open the PR (manual), mark the Plan rejected, or
     abort.

3. **Record the shipment.** Append to the audit trail:

   ```markdown
   - YYYY-MM-DD: Shipped. PR: <URL>. Merge: <sha>. Merged by: <login>.
   ```

4. **Return to SKILL.md Step 3** to finalise the Plan status.

## Edge cases (GitHub-specific)

- **The PR fails to open.** Common causes: branch not pushed, no remote
  set, `gh` not authenticated. Surface the exact error and offer
  remediation. Do NOT mark the Plan shipped.
- **Merge conflicts.** The Plan author resolves these as fix commits.
  `/spades:ship` resumes when the branch is clean again.
- **`gh` not installed or unauthenticated.** Show the human exactly
  what command they'd run to open the PR manually (`git push -u
  origin <branch>`, then a `gh pr create` invocation), then capture
  the resulting URL once they've completed it.
