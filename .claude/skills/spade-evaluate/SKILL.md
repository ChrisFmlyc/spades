---
name: spade-evaluate
description: Check delivered output against the original Scope's acceptance criteria. Use when delivery is complete and work needs evaluation, when someone says "evaluate this", "check if this is done", "verify the output", or when all sub-issues under a parent issue are marked Done. Also use when a human wants to run acceptance criteria as automated or manual checks.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory. This file specifies
which Linear team, project, and default assignee to use. Use these values
for all Linear operations. If the file doesn't exist, ask the human which
team and project to use, or suggest running `/spade-onboard` first.

# SPADE Evaluate

You are helping a human evaluate delivered output against the original Scope.
Evaluation is distinct from Approval. Approval validates the approach.
Evaluation validates the output.

## Quick-Path Branch (spade:quick items)

**Before doing anything else, check the parent issue's labels.** If it has
`spade:quick`, this is a fast-track item and the evaluation rules are
different — skip the rest of this skill's default flow and use the
quick-path procedure below.

Quick-path items have **no sub-issues**, **no separate Plan document**,
and **no Delivery Bundles**. The PR description is the audit artefact.
The `type:*` label tells you what kind of change it was.

### Quick-path evaluation steps

1. **Find the PR.** Look for a PR URL in the issue comments, or search
   for a PR that references the issue ID.
2. **Check merge status.** Is the PR merged, open, or closed without merge?
3. **Check CI.** For merged PRs, confirm CI was green at merge. For open
   PRs, confirm CI is currently green.
4. **Read the PR description.** It must follow the `/spade-quick` template:
   Type, SPADE path, Linear link, What, Why, Change, Verification checklist,
   and the Gate check with all ten boxes ticked.
5. **Validate the gate retrospectively.** Glance at the diff — does the
   actual change still match every gate criterion? Specifically check:
   - ≤ ~50 LoC changed
   - One file or tight cluster
   - No new dependencies (check package manifest files in the diff)
   - No schema / migration files touched
   - No auth, crypto, or permission-check code touched
6. **Check the labels.** Confirm `spade:quick` and a `type:*` label are
   applied, plus `ai-delivered` or `human-delivery`.

### Quick-path verdict

- **PASS** — PR merged, CI green, template filled, gate still holds on
  review. The human can move the issue to Done.
- **PARTIAL** — Something small is missing or wrong (a missed verification
  step, a typo in the fix, a gate-check box that shouldn't have been ticked
  on closer inspection).
  - If the PR has **NOT merged yet**: push fixes as **new commits to the
    same branch/PR**. Re-request review if appropriate.
  - If the PR **has merged**: open a **new quick-path PR** that references
    the original (e.g. title prefix "Follow-up to #123 for PARTIAL eval
    findings"). Run the full `/spade-quick` workflow for the follow-up PR,
    including the gate check and the template.
  - **NEVER create sub-issues to track the fix.** Sub-issues are forbidden
    on the quick path regardless of verdict.
- **FAIL** — The change fails the gate retrospectively (e.g. actually
  touched a schema, or actually broke a public API). The fast-track was
  misused. The work must be rolled back and redone through `/spade-scope`
  with a proper Plan. Apply `plan-rejected` to the original issue if it
  exists, explain in a comment what gate criterion was violated, and
  recommend re-opening the work as a full-loop Scope.

### Quick-path Linear updates

- If PASS: leave the issue in "In Review" for the human to move to Done.
  Post a brief eval comment confirming the PR meets all gate criteria and
  the acceptance criteria (from the PR description's "What" / "Why").
- If PARTIAL: post an eval comment listing the specific findings and what
  the follow-up looks like (new commits vs new PR).
- If FAIL: post an eval comment explaining the gate violation and move
  the issue back to the human for re-scoping.

Do NOT iterate sub-issues for quick-path items — they do not exist.
Do NOT look for a Plan document — there isn't one. The rest of this
skill, from "Before You Start" onward, applies only to full-loop items.

---

## Full-Loop Evaluation

For items that are NOT `spade:quick`-labelled, follow the standard
evaluation flow below.

## Before You Start

1. Read the original Scope (parent issue), including all acceptance criteria
2. Read the Plan that was approved. **Read order**: tracker first
   (the Linear parent-issue comment posted by `/spade-plan`), then
   `.spade/plans/<issue-id>-plan.md` as a fallback. The local file
   exists only for Linear-less environments (v1.2.0+) or as a
   pre-v1.2.0 historical archive — if the tracker has the Plan, that
   is the canonical copy.
3. Review what was actually delivered across all sub-issues

## Evaluation Checks

Run each acceptance criterion from the Scope as a check:

### For Each Acceptance Criterion

1. **State the criterion** exactly as written in the Scope
2. **Check the evidence** — does the delivered output meet this criterion?
   - For software: run the relevant tests, check the code, verify the behaviour
   - For non-software: check the evidence of completion specified in the Plan
3. **Verdict**: Pass, Fail, or Partial
4. **Notes**: If Fail or Partial, explain specifically what is missing or wrong

### Additional Quality Checks

Beyond the acceptance criteria, also check:

- **Does it actually work in practice?** Not just in theory, not just in tests,
  but in the real environment with real data.
- **Are there quality issues?** Code quality, edge cases, error handling,
  logging, documentation.
- **Are there regressions?** Has the delivered work broken anything that
  was previously working?
- **Would you be comfortable shipping this?** The gut-check question. If the
  answer is no, articulate why.

## Output Format

Present the evaluation in this format:

```
## Evaluation: [Scope Title]

### Acceptance Criteria

| # | Criterion | Verdict | Notes |
|---|-----------|---------|-------|
| 1 | [Criterion text] | Pass/Fail/Partial | [Explanation] |
| 2 | [Criterion text] | Pass/Fail/Partial | [Explanation] |

### Quality Assessment

- **Functionality:** [Works / Partially works / Broken]
- **Code quality:** [Good / Acceptable / Needs work]
- **Test coverage:** [Adequate / Gaps identified]
- **Edge cases:** [Handled / Partially handled / Not addressed]
- **Documentation:** [Complete / Partial / Missing]

### Overall Verdict

[PASS — ready to ship | PARTIAL — specific fixes needed | FAIL — rework required]

### Required Actions (if not passing)

1. [Specific action needed]
2. [Specific action needed]
```

## After Evaluation

### If PASS

- Ask the human to confirm they are satisfied
- If confirmed, the human moves the parent issue to "Done"
- You must NOT mark the parent issue as Done yourself

### If PARTIAL (minor fixes needed) — full loop only

- List the specific fixes required
- These go back to Deliver — create new sub-issues or reopen existing ones
- The fixes should be small and targeted, not a re-plan
- After fixes are delivered, run evaluation again

**For quick-path items, see the Quick-Path Branch at the top of this
skill — sub-issue creation is forbidden there regardless of verdict.**

### If FAIL (fundamental problems)

- Explain what went wrong and where the approach broke down
- Recommend whether to:
  - **Re-plan**: The approach was wrong. Go back to Plan with lessons learned.
  - **Re-scope**: The Scope was unclear or the problem was misunderstood.
    Go back to Scope with the human.
- Do not attempt to patch a fundamentally broken delivery

## Linear Integration

If Linear MCP is available:
1. Update parent issue status to "Evaluating"
2. Add the evaluation report as a comment on the parent issue
3. If fixes needed, create new sub-issues or reopen relevant ones
4. If passed, leave the parent issue in "Evaluating" for the human to
   move to "Done" (humans own this transition)
