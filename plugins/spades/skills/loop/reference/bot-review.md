# Bot review — getting a PR to zero unresolved threads

`/spades:loop` Stage 7 runs this against the ship PR; Stages 12–13
run it again against the bookkeeping PR.

`/codereview:loop` handles the findings of every review bot (CodeRabbit,
Greptile, or any other coding agent), including `CHANGES_REQUESTED`
reviews, on a GitHub pull request or a GitLab merge request (MR). This
flow checks for human threads and runs the final sweep before merge.

## Contents

- 1. Review bots → `/codereview:loop`
- 2. Human threads — always a pause
- 3. Final sweep

---

## 1. Review bots → `/codereview:loop`

Invoke **`/codereview:loop <pr-url>`** with the PR's link on GitHub: a
bare number would let `gh` pick a repository by its own rules, which can
be another remote's (`docs/FRAMEWORK.md § SCM Drivers`). On GitLab pass
the MR link and the configured review bots, which tells it the host, the
project and whose threads it may answer:

```
/codereview:loop <mr-url> --bots <username>:<kind>,<username>:<kind>
```

The entries come from `gitlab.review_bots`, in order. With
`review_bots: []` the project has no review bots, so there is nothing
for `/codereview:loop` to do: go to § 3.

It returns when the bots are clean. It owns the whole contract:
waiting for each review, pulling the open threads, handing them to
`/codereview:fix`, closing threads a fix didn't auto-resolve,
pushing, re-checking, and its own cycle cap. It reports one line at
the end — cycles run, findings found, how many fixed in code versus
answered and closed. Resume this flow when `/codereview:loop` returns.

When `/codereview:loop` stops short — cycle cap, a guardrail refusal,
or a PR closed mid-flight — it says why. Surface that reason verbatim
and pause.

## 2. Human threads — always a pause

A human's thread is theirs: no reply, no resolve, no fix on their
behalf. An unresolved human thread pauses the loop and hands it back.

## 3. Final sweep

A bot can post between `/codereview:loop` returning and the merge, so
sweep once more before Stage 8 with the § Thread sweep query in
[`finish-checks.md`](finish-checks.md) for the configured host, which
classifies each unresolved thread as a bot's or a human's:

- **A bot's** → run `/codereview:loop` again; it either hasn't
  finished or stopped and told you why.
- **A human's** → § 2; pause.

Zero unresolved threads from any author → append the `Loop — bot
review clean` marker and return to the calling stage.
