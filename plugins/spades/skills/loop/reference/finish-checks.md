# Finish checks — deploy gate and the FINISHED assertions

The probe mechanics for `/spades:loop` Stage 9 (deploy gate) and
Stage 15 (FINISHED). The stages own what must be true; this file
owns how you find out.

## Contents

- Thread sweep — the canonical unresolved-threads query
- Deploy gate — is deployment configured, did it succeed
- FINISHED — the four assertions and the probe for each

---

## Thread sweep

The canonical query for unresolved review threads. Stage 7's final
sweep uses it, Stage 8 re-runs it immediately before merging, and
FINISHED assertion 2 uses it on both PRs. It is duplicated from
`bot-review.md` so that this file reads whole; a reference file
points only at SKILL.md, never at another reference.

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

A thread is outstanding when `isResolved == false`. A `[bot]` author
goes to `/codereview:loop`; a human author is a pause.

---

## Deploy gate (Stage 9)

A deploy triggered by the merge to `main` runs against the ship PR's
merge SHA. Two questions, in order.

### 1. Does this repo deploy at all?

```bash
gh api "repos/{owner}/{repo}/deployments" --jq 'length'
```

`0` → check for deploy-shaped check runs, since some stacks (Vercel,
Netlify, some GitHub Actions setups) report deploys that way:

```bash
gh api "repos/{owner}/{repo}/commits/<merge-sha>/check-runs" \
  --jq '[.check_runs[] | select(.name | test("deploy|vercel|netlify|release"; "i"))
        | {name, status, conclusion}]'
```

Nothing in either → the repo has no deployments configured. Record
`- YYYY-MM-DD: Loop — deploy: not configured.` and continue; the
FINISHED block shows `not configured` explicitly, so the audit trail
claims only what happened.

A matching check run is treated exactly like a deployment below:
`SUCCESS` passes, a failure pauses, anything unfinished is polled.

### 2. Did it succeed?

```bash
gh api "repos/{owner}/{repo}/deployments?sha=<merge-sha>" --jq '.[0].id'
gh api "repos/{owner}/{repo}/deployments/<id>/statuses" --jq '.[0] | {state, environment_url}'
```

| `state` | Action |
|---|---|
| `success` | Record `Loop — deploy: success (<environment_url>).` and continue to Stage 10. |
| `failure`, `error` | Pause. The Plan shipped but the deploy is broken; close would write `shipped` over a broken deploy. |
| `pending`, `queued`, `in_progress` | Poll at 60–90 seconds. Deploys are slower than CI. |
| no deployment for this SHA yet | Poll. After about 15 minutes in a repo that clearly deploys, pause and say so. |

---

## FINISHED (Stage 15)

Four assertions, each verified against GitHub.

### 1. Ship PR squash-merged

```bash
gh pr view <ship-pr> --json state,mergeCommit --jq '"\(.state) \(.mergeCommit.oid)"'
```

`MERGED` with a merge SHA.

### 2. Nothing open in GitHub

Three things, on both the ship PR and the bookkeeping PR:

**Zero unresolved review threads** — the § Thread sweep query on
both PRs, counting `isResolved == false` regardless of author.

**Every check green on the merge commit.** A check still running has
`conclusion: null`; it is pending, not failed:

```bash
gh api "repos/{owner}/{repo}/commits/<merge-sha>/check-runs" \
  --jq '{ pending: ([.check_runs[] | select(.status != "completed")] | length),
          failed:  ([.check_runs[] | select(.status == "completed"
                    and .conclusion != "success"
                    and .conclusion != "neutral"
                    and .conclusion != "skipped")] | length) }'
```

- `failed > 0` → not finished; pause with the failing checks.
- `pending > 0` → not yet knowable; poll at 60–90 seconds. Post-merge
  runs on `main` routinely trail the merge by a minute or two.
- both `0` → green.

**Every linked issue closed.** `gh pr view --json` has no field for
this, so use GraphQL:

```bash
gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
      closingIssuesReferences(first:20){ nodes{ number state } } } }
  }' -F owner=<owner> -F repo=<repo> -F pr=<n>
```

A node with `state: OPEN` → not finished; the PR claimed to close an
issue and didn't.

### 3. Deploy successful, or not configured

Re-read the `Loop — deploy:` marker from Stage 9. `success` and `not
configured` both pass.

### 4. Close bookkeeping PR squash-merged

The assertion-1 probe against the bookkeeping PR.

---

## When an assertion fails

Pause with the specific assertion and its evidence; the FINISHED
block is printed only when all four hold. It is the one output the
human trusts without checking, which is why it has to be earned.
