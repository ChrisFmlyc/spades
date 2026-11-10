# Finish checks — merge readiness, deploy gate and the FINISHED assertions

The probe mechanics for `/spades:loop` Stage 8 (merge readiness),
Stage 9 (deploy gate) and Stage 15 (FINISHED), on GitHub (`gh`) and
GitLab (`glab`). The stages own what must be true; this file owns how
you find out.

Run GitLab probes inside the worktree, so `glab api` fills `:id` with
the configured remote's project. `<iid>` is the merge request's (MR's)
number. `glab api` has no `--jq` flag, so its JSON is piped to `jq`.
Review-request state and merging use `review_state` and `merge_review`
from `docs/FRAMEWORK.md § SCM Drivers`.

## Contents

- Thread sweep — the canonical unresolved-threads query
- Merge readiness — Stage 8's assertions
- Deploy gate — is deployment configured, did it succeed
- FINISHED — the four assertions and the probe for each

---

## Thread sweep

The canonical query for unresolved review threads. Stage 7's final
sweep uses it, Stage 8 re-runs it immediately before merging, and
FINISHED assertion 2 uses it on both PRs.

**GitHub:**

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

**GitLab:**

```bash
glab api --paginate "projects/:id/merge_requests/<iid>/discussions" \
  | jq -s '[.[][] | select(any(.notes[]; .resolvable and (.resolved | not)))
            | {id, author: .notes[0].author.username, author_id: .notes[0].author.id,
               path: .notes[0].position.new_path, body: .notes[0].body}]'
```

A discussion is outstanding when any resolvable note in it is
unresolved. Every outstanding discussion is a pause
(`bot-review.md` § 1). Name the author in the pause: note authors carry
no bot flag, but `glab api users/<author_id>` returns `bot: true` for a
bot account, and access-token bots are named `project_<n>_bot_…` or
`group_<n>_bot_…`.

---

## Merge readiness (Stage 8)

**GitHub:**

```bash
gh pr view <n> --json state,mergeable,mergeStateStatus,statusCheckRollup
```

- `state == "OPEN"`.
- `mergeable == "MERGEABLE"` — re-poll `UNKNOWN`, pause on
  `CONFLICTING`.
- No required check `FAILURE` / `ERROR` / `TIMED_OUT` / `CANCELLED`,
  none still `PENDING`.
- No **human** reviewer's latest review is `CHANGES_REQUESTED`:

  ```bash
  gh pr view <n> --json reviews \
    --jq '[.reviews[] | select(.author.login | endswith("[bot]") | not)]
          | group_by(.author.login) | map(last)
          | map(select(.state == "CHANGES_REQUESTED")) | length'
  ```

  The PR-level `reviewDecision` mixes bots and humans and lags the
  thread sweep, so the per-reviewer query is the signal. A bot's
  `CHANGES_REQUESTED` belongs to `/codereview:loop`.

**GitLab:**

```bash
glab mr view <iid> --output json \
  | jq '{state, detailed_merge_status, pipeline: .head_pipeline.status, sha}'
glab api "projects/:id/merge_requests/<iid>/reviewers" \
  | jq '[.[] | select(.state == "requested_changes") | .user.username]'
```

- `state == "opened"`.
- `detailed_merge_status == "mergeable"`. GitLab computes mergeability
  asynchronously: re-poll `checking`, `unchecked`, `preparing`,
  `approvals_syncing` and `ci_still_running`. Any other value is a pause
  that names it — `conflict`, `need_rebase`, `ci_must_pass`,
  `not_approved`, `discussions_not_resolved`, `draft_status`,
  `requested_changes`, `merge_request_blocked`, and the rest.
- The head pipeline is `success`, `skipped` or `manual`, or the MR has
  none. Poll `created`, `waiting_for_resource`, `preparing`, `pending`,
  `running` and `scheduled`; pause on `failed` and `canceled`.
- The reviewers query returns nobody. A reviewer requesting changes,
  bot or human, is a pause.

`sha` is the head SHA that `merge_review` pins.

---

## Deploy gate (Stage 9)

A deploy triggered by the merge to `main` runs against the ship PR's
merge SHA. Two questions, in order.

### 1. Does this repo deploy at all?

**GitHub:**

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

**GitLab:**

```bash
glab api "projects/:id/deployments?per_page=1" | jq 'length'
```

`0` → check the merge commit's statuses, where deploy jobs and external
services (Vercel, Netlify and similar) report:

```bash
glab api "projects/:id/repository/commits/<merge-sha>/statuses" \
  | jq '[.[] | select(.name | test("deploy|vercel|netlify|release"; "i")) | {name, status}]'
```

Nothing in either → the repo has no deployments configured. Record
`- YYYY-MM-DD: Loop — deploy: not configured.` and continue; the
FINISHED block shows `not configured` explicitly, so the audit trail
claims only what happened.

A matching check run or status is treated exactly like a deployment
below: success passes, a failure pauses, anything unfinished is polled.

### 2. Did it succeed?

**GitHub:**

```bash
gh api "repos/{owner}/{repo}/deployments?sha=<merge-sha>" --jq '.[0].id'
gh api "repos/{owner}/{repo}/deployments/<id>/statuses" --jq '.[0] | {state, environment_url}'
```

**GitLab** — the deployments API has no SHA filter, so read the most
recent deployments and match the merge SHA:

```bash
glab api "projects/:id/deployments?order_by=updated_at&sort=desc&per_page=50" \
  | jq --arg sha "<merge-sha>" '[.[] | select(.sha == $sha)] | .[0]
        | {status, environment_url: .environment.external_url}'
```

| GitHub `state` | GitLab `status` | Action |
|---|---|---|
| `success` | `success` | Record `Loop — deploy: success (<environment_url>).` and continue to Stage 10. |
| `failure`, `error` | `failed`, `canceled`, `skipped` | Pause. The Plan shipped but the deploy is broken or didn't run; close would write `shipped` over it. |
| `pending`, `queued`, `in_progress` | `created`, `running`, `blocked` | Poll at 60–90 seconds. Deploys are slower than CI; `blocked` waits for a manual approval. |
| no deployment for this SHA yet | no deployment for this SHA yet | Poll. After about 15 minutes in a repo that clearly deploys, pause and say so. |

---

## FINISHED (Stage 15)

Four assertions, each verified against the SCM host.

### 1. Ship PR squash-merged

`review_state` on the ship PR reads `MERGED` with a merge SHA.

### 2. Nothing open on the host

Three things, on both the ship PR and the bookkeeping PR:

**Zero unresolved review threads** — the § Thread sweep query on
both PRs, counting every outstanding thread regardless of author.

**Every check green on the merge commit.** A check still running is
pending, not failed.

GitHub:

```bash
gh api "repos/{owner}/{repo}/commits/<merge-sha>/check-runs" \
  --jq '{ pending: ([.check_runs[] | select(.status != "completed")] | length),
          failed:  ([.check_runs[] | select(.status == "completed"
                    and .conclusion != "success"
                    and .conclusion != "neutral"
                    and .conclusion != "skipped")] | length) }'
```

GitLab — the merge commit's pipelines, plus the statuses external
services set on it:

```bash
glab api "projects/:id/pipelines?sha=<merge-sha>" \
  | jq '{ pending: ([.[] | select(.status | IN("created","waiting_for_resource","preparing",
                      "waiting_for_callback","pending","running","scheduled","canceling"))] | length),
          failed:  ([.[] | select(.status | IN("failed","canceled"))] | length) }'
glab api "projects/:id/repository/commits/<merge-sha>/statuses" \
  | jq '[.[] | select((.status | IN("failed","canceled")) and (.allow_failure | not)) | .name]'
```

A pipeline reading `success`, `skipped` or `manual` is green; a name in
the second list counts as failed.

- `failed > 0` → not finished; pause with the failing checks.
- `pending > 0` → not yet knowable; poll at 60–90 seconds. Post-merge
  runs on `main` routinely trail the merge by a minute or two.
- both `0` → green.

**Every linked issue closed.**

GitHub — `gh pr view --json` has no field for this, so use GraphQL:

```bash
gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
      closingIssuesReferences(first:20){ nodes{ number state } } } }
  }' -F owner=<owner> -F repo=<repo> -F pr=<n>
```

A node with `state: OPEN` → not finished; the PR claimed to close an
issue and didn't.

GitLab:

```bash
glab api "projects/:id/merge_requests/<iid>/closes_issues" \
  | jq '[.[] | select(.state == "opened") | .iid]'
```

A non-empty list → not finished. GitLab closes linked issues only when
the MR merges into the default branch.

### 3. Deploy successful, or not configured

Re-read the `Loop — deploy:` marker from Stage 9. `success` and `not
configured` both pass.

### 4. Close bookkeeping PR squash-merged

The assertion-1 probe against the bookkeeping PR.

---

## When an assertion fails

Pause with the specific assertion and its evidence; print the FINISHED
block only when all four hold.
