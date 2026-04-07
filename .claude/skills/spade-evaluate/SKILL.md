---
name: spade-evaluate
description: Check delivered output against the original Scope's acceptance criteria. Use when delivery is complete and work needs evaluation, when someone says "evaluate this", "check if this is done", "verify the output", or when all sub-issues under a parent issue are marked Done. Also use when a human wants to run acceptance criteria as automated or manual checks.
---

# SPADE Evaluate

You are helping a human evaluate delivered output against the original Scope.
Evaluation is distinct from Approval. Approval validates the approach.
Evaluation validates the output.

## Before You Start

1. Read the original Scope (parent issue), including all acceptance criteria
2. Read the Plan that was approved
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

### If PARTIAL (minor fixes needed)

- List the specific fixes required
- These go back to Deliver — create new sub-issues or reopen existing ones
- The fixes should be small and targeted, not a re-plan
- After fixes are delivered, run evaluation again

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
