# Finish checks — deploy gate and the FINISHED assertions

The probe mechanics for `/spades:loop` Stage 9 (deploy gate) and
Stage 15 (FINISHED). The stages own *what must be true*; this file
owns *how you find out*.

## Contents

- Thread sweep — the canonical unresolved-threads query
- Deploy gate — is deployment configured, did it succeed, what to do
  when it fails or never arrives
- FINISHED — the four assertions and the exact probe for each
- What "nothing open in GitHub" means

---

## Thread sweep

The canonical query for unresolved review threads. Stage 7's final
sweep uses it, Stage 8 re-runs it immediately before merging (a bot
can post between the sweep and the merge), and FINISHED assertion 2
uses it on both PRs.

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes { id isResolved path
            comments(first: 10) { nodes { databaseId author { login } body url } } } } } }
  }' -F owner=<owner> -F repo=<repo> -F pr=<n>
```

A thread is outstanding when `isResolved == false`. Who opened it
decides who handles it — any `[bot]` goes to `/codereview:loop`, and a
**human** is never touched and is always a pause.

---

## Deploy gate (Stage 9)

A deploy is triggered by the merge to `main`, so it runs against the
**ship PR's merge SHA**. Two questions, in order.

### 1. Does this repo deploy at all?

```bash
gh api "repos/{owner}/{repo}/deployments" --jq 'length'
```

`0` → **this repo has no deployments configured.** That is a
perfectly fine state. Record it and continue:

```markdown
- YYYY-MM-DD: Loop — deploy: not configured.
```

**Never report "deploy successful" when nothing deployed.** Saying a
deploy passed when none ran is worse than not checking — it puts a
claim in the audit trail that no evidence supports. The FINISHED
block shows `not configured` explicitly for the same reason.

Some stacks (Vercel, Netlify, some GitHub Actions setups) report
deploys as **check runs** rather than Deployments. If the count is
`0`, also look for a deploy-shaped check on the merge commit before
concluding nothing deploys:

```bash
gh api "repos/{owner}/{repo}/commits/<merge-sha>/check-runs" \
  --jq '[.check_runs[] | select(.name | test("deploy|vercel|netlify|release"; "i"))
        | {name, status, conclusion}]'
```

Treat a matching check exactly like a deployment below: `SUCCESS`
passes, a failure pauses, anything unfinished is polled.

### 2. Did it succeed?

```bash
gh api "repos/{owner}/{repo}/deployments?sha=<merge-sha>" --jq '.[0].id'
gh api "repos/{owner}/{repo}/deployments/<id>/statuses" --jq '.[0] | {state, environment_url}'
```

| `state` | Action |
|---|---|
| `success` | Record `Loop — deploy: success (<environment_url>).` and continue to Stage 10. |
| `failure`, `error` | **Pause.** The Plan shipped but the deploy is broken — that is exactly the moment a human should look. Do not close. |
| `pending`, `queued`, `in_progress` | Poll at ~60–90s. Deploys are slower than CI. |
| no deployment for this SHA yet | Poll. If none appears after ~15 minutes while the repo clearly deploys, pause and say so rather than guessing. |

**Deploy failure never closes.** Close writes `status: shipped`, and
a Plan whose deploy failed has not shipped in any sense the word
carries. Pause and let the human decide.

---

## FINISHED (Stage 15)

Four assertions. Verify every one against GitHub — never from memory
of what the loop did earlier in the run.

### 1. Ship PR squash-merged

```bash
gh pr view <ship-pr> --json state,mergeCommit --jq '"\(.state) \(.mergeCommit.oid)"'
```

Must be `MERGED` with a merge SHA.

### 2. Nothing open in GitHub

Three things, all on both the ship PR and the bookkeeping PR:

**Zero unresolved review threads** — the § Thread sweep query above,
run on both PRs. (It is duplicated from `bot-review.md` on purpose:
pointing at that file from this one would be a nested reference, and
those get partially read. Two copies beat an unreliable read.) Count `isResolved == false` regardless of author: a
human thread left open counts, and so does a bot's.

**Every check green on the merge commit.** Separate *still running*
from *failed* — a check in flight has `conclusion: null`, and
treating that as a failure would pause a Scope that is merely a
minute from done:

```bash
gh api "repos/{owner}/{repo}/commits/<merge-sha>/check-runs" \
  --jq '{ pending: ([.check_runs[] | select(.status != "completed")] | length),
          failed:  ([.check_runs[] | select(.status == "completed"
                    and .conclusion != "success"
                    and .conclusion != "neutral"
                    and .conclusion != "skipped")] | length) }'
```

- `failed > 0` → **not finished**; pause with the failing checks.
- `pending > 0` → **not yet knowable**; poll at ~60–90s. Post-merge
  runs on `main` routinely trail the merge by a minute or two. Do not
  report this as a check failure.
- both `0` → green.

**Any linked issue closed.** `gh pr view --json` has no field for
this; use GraphQL:

```bash
gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
      closingIssuesReferences(first:20){ nodes{ number state } } } }
  }' -F owner=<owner> -F repo=<repo> -F pr=<n>
```

Any node with `state: OPEN` → not finished; the PR claimed to close
an issue and didn't.

### 3. Deploy successful — or not configured

Re-read the `Loop — deploy:` marker written at Stage 9. `success` or
`not configured` both pass; anything else means Stage 9 paused and
you should not be here.

### 4. Close bookkeeping PR squash-merged

Same probe as assertion 1, against the bookkeeping PR.

---

## If any assertion fails

**Do not print FINISHED.** Pause with the specific assertion that
failed and its evidence. A FINISHED block that isn't true is worse
than no block at all — it is the one output the human relies on
without checking, which is precisely why it must be earned.
