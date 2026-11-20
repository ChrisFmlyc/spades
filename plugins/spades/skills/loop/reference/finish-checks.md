# Finish checks — merge readiness, deploy gate and the FINISHED assertions

The probe mechanics for `/spades:loop` Stage 8 (GitLab merge readiness),
Stage 9 (deploy gate) and Stage 15 (FINISHED), on GitHub (`gh`) and
GitLab (`glab`). The stages own what must be true; this file owns how
you find out.

GitHub probes name the repository behind `github.remote`, as
`docs/FRAMEWORK.md § SCM Drivers` sets out: `<gh-host>`, `<owner>` and
`<repo>` are read from that remote's URL, and `<gh-repo>` is
`<gh-host>/<owner>/<repo>`. `gh pr` takes `-R <gh-repo>`; `gh api`
takes `--hostname <gh-host>`, REST endpoints address
`repos/<owner>/<repo>`, and GraphQL queries take `-F owner=<owner> -F
repo=<repo>`. `<n>` is the pull request's (PR's) number.

GitLab probes name the project from `.spades/config`, as
`docs/FRAMEWORK.md § SCM Drivers` sets out: `<host>` is `gitlab.host`,
`<project>` is `gitlab.project` with each `/` as `%2F`, and `<repo-url>`
is `https://<host>/<gitlab.project>`. `<iid>` is the merge request's
(MR's) number. `glab api` has no `--jq` flag, so its JSON is piped to
`jq`; every such block starts with `set -o pipefail` (or `set -eo
pipefail` when it runs several), so a `glab` HTTP error fails the probe
instead of reaching `jq` as data. List endpoints
return 20 items a page: `--paginate` with `jq -s` reads them all,
whether `glab` prints one array or one per page, and an empty response
is an error rather than an empty list. Review-request
state and merging use `review_state` and `merge_review` from
`docs/FRAMEWORK.md § SCM Drivers`.

## Contents

- Thread sweep — the canonical unresolved-threads query
- Merge readiness — Stage 8's assertions
- Deploy gate — is deployment configured, did it succeed
- FINISHED — the four assertions and the probe for each

---

## Thread sweep

The canonical query for unresolved review threads. Stage 7's final
sweep uses it, Stage 8 re-runs it immediately before merging, and
FINISHED assertion 2 uses it on the ship and bookkeeping PRs.

**GitHub:**

```bash
gh api graphql --hostname <gh-host> -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes { id isResolved path
            comments(first: 10) { nodes { databaseId author { __typename login } body url } } } } } }
  }' -F owner=<owner> -F repo=<repo> -F pr=<n>
```

A thread is outstanding when `isResolved == false`. It is a bot's
when its first comment's `author.__typename` is `Bot` and every later
comment is a `Bot`'s or one of `/codereview:loop`'s and
`/codereview:fix`'s own replies; it goes to `/codereview:loop`. A
reply is theirs when it starts with `(ai-skills:` and its
`author.login` is the account `gh` is signed in as, which
`gh api --hostname <gh-host> user --jq .login` prints (look it up once
per run). Any other thread — a person's, one a person has replied in,
or one with no author — is a human's and a pause; an `(ai-skills:` reply from any
other account is a person's. GraphQL bot logins carry no `[bot]`
suffix, so match on the type rather than the login.

**GitLab:** GitLab marks no account as a review bot, so the bots are
the accounts in `gitlab.review_bots`, matched by user ID. Look each one
up once per run, and with them the ID of the account `glab` is signed
in as, which posts `/codereview:loop`'s and `/codereview:fix`'s
replies:

```bash
set -o pipefail
glab api --hostname <host> "users?username=<username>" | jq '.[0].id'
glab api --hostname <host> user | jq .id
```

The signed-in ID is an integer; anything else fails the probe. Then,
with the bot IDs as a JSON array (`[]` when there are none) and the
signed-in ID as `<self-id>`:

<!-- scm-test: gitlab-thread-sweep -->
```bash
set -o pipefail
glab api --paginate --hostname <host> "projects/<project>/merge_requests/<iid>/discussions" \
  | jq -s --argjson bots '<bot-ids>' --argjson me '<self-id>' '(if length == 0 then error("no response from glab") else add end)
      | [.[] | select(any(.notes[]; .resolvable and (.resolved | not)))
        | [.notes[] | select(.system | not)] as $n
        | {id, author: $n[0].author.username, author_id: $n[0].author.id,
           path: $n[0].position.new_path, body: $n[0].body,
           by: (if ($n[0].author.id | IN($bots[]))
                   and all($n[]; (.author.id | IN($bots[]))
                                 or (.author.id == $me and (.body | startswith("(ai-skills:"))))
                then "bot" else "human" end)}]'
```

A discussion is outstanding when any resolvable note in it is
unresolved. It is a bot's (`by: "bot"`) when a listed bot
opened it and every other note is that bot's, another listed bot's, or
one of `/codereview:loop`'s and `/codereview:fix`'s own replies — a
note that starts with `(ai-skills:` and whose `author.id` is
`<self-id>`; it goes to `/codereview:loop`. Anything else is
`by: "human"` and a pause: a thread a person opened, one a person has
replied in — including an `(ai-skills:` note from any account other
than `<self-id>` — and one opened by an unlisted account, including a
`bot: true` account or a `project_<n>_bot_…` user.

---

## Merge readiness (Stage 8)

**GitHub:** Stage 8 step 3 in [`../SKILL.md`](../SKILL.md) runs the
assertions inline.

**GitLab:**

<!-- scm-test: gitlab-merge-readiness -->
```bash
set -eo pipefail
glab mr view <iid> -R <repo-url> --output json \
  | jq -c '{state, draft, detailed_merge_status, sha, source_branch}'
glab api --hostname <host> "projects/<project>/merge_requests/<iid>/reviewers" \
  | jq -c --argjson bots '<bot-ids>' '[.[] | select(.state == "requested_changes")
          | {username: .user.username, by: (if (.user.id | IN($bots[])) then "bot" else "human" end)}]'
pushed=$(glab api --hostname <host> "projects/<project>/merge_requests/<iid>/versions" \
  | jq -r --arg sha '<sha>' '[.[] | select(.head_commit_sha == $sha)] | max_by(.id) | .created_at // ""')
glab api --paginate --hostname <host> "projects/<project>/merge_requests/<iid>/pipelines" \
  | jq -sc --arg sha '<sha>' --arg pushed "$pushed" '
      def epoch: sub("Z$"; "+00:00")
        | (.[0:19] + "Z" | fromdateiso8601) + (.[19:-6] | if . == "" then 0 else tonumber end)
          - (if .[-6:-5] == "-" then -1 else 1 end) * ((.[-5:-3] | tonumber) * 3600 + (.[-2:] | tonumber) * 60);
      (if length == 0 then error("no response from glab") else add end)
      | [.[] | select(.source != "external")
             | select(.sha == $sha
                      or (.ref == "refs/merge-requests/<iid>/merge" and $pushed != ""
                          and (.created_at | epoch) >= ($pushed | epoch)))]
      | max_by(.id) // {} | {id, status, ref}'
glab api --hostname <host> "projects/<project>" | jq -c '{squash_option, merge_method, merge_trains_enabled}'
```

- `state == "opened"` and `draft == false`.
- `detailed_merge_status == "mergeable"`. GitLab computes mergeability
  asynchronously: re-poll `checking`, `unchecked`, `preparing`,
  `approvals_syncing` and `ci_still_running`, and for up to 15 minutes
  `status_checks_must_pass` (an external status check still reporting).
  `need_rebase` returns to Stage 8 step 1. Any other value is a pause
  that names it — `conflict`, `ci_must_pass`, `not_approved`, `discussions_not_resolved`,
  `draft_status`, `requested_changes`, `merge_request_blocked`,
  `merge_time` (merging is held until a set time), and the rest.
- **The MR's CI pipeline** — the newest pipeline this MR ran for its
  current head. The MR's pipelines list holds only its own: its merge
  request pipelines and the branch pipelines on its source branch, so
  a tag or another branch that built the same commit never counts. Of
  those, a pipeline whose `sha` is the head counts, and so does a
  merged-results pipeline (`refs/merge-requests/<iid>/merge`) created
  at or after the MR version that recorded the head. A merged-results
  pipeline runs on a temporary merge commit and never carries the head
  SHA; one created before that version tested an earlier head.
  `epoch` turns GitLab's timestamps, in UTC or the instance's offset,
  into seconds so the two compare. The query also skips `external`
  pipelines: a review bot's commit status (CodeRabbit's, for one)
  creates one on a commit with no CI pipeline, and it reads `success`
  whatever CI did. The newest of the rest:
  - `success`, `skipped` or `manual` → green.
  - `created`, `waiting_for_resource`, `preparing`, `waiting_for_callback`,
    `pending`, `running`, `scheduled`, `canceling` → poll.
  - `failed` or `canceled` → pause with § Failed pipeline's evidence.
  - none → no CI ran for this commit. That passes unless
    `detailed_merge_status` says otherwise (`ci_must_pass`): then
    `.gitlab-ci.yml`'s `rules` or `workflow:rules` added no job, and
    the pause shows § Failed pipeline's lint result.
- The reviewers query returns no `human`. A human requesting changes
  is a pause, and only they or a person with merge rights clears it —
  by approving, removing the request, or bypassing it. A listed review
  bot requesting changes — GitLab Duo does whenever it has findings —
  belongs to `/codereview:loop` while its threads are open, like a
  bot's `CHANGES_REQUESTED` on GitHub; once its threads are clean, a
  `requested_changes` merge status that remains is the same pause, with
  the same remedies.
- **Squash allowed.** `squash_option == "never"` forbids a squash
  merge: pause and report it — the project setting *Squash commits when
  merging*. Every other value accepts `merge_review`'s `--squash`.

`sha` is the head SHA that `merge_review` pins.

### Failed pipeline

<!-- scm-test: gitlab-failed-pipeline -->
```bash
set -eo pipefail
glab api --hostname <host> "projects/<project>/pipelines/<pipeline-id>" | jq '{status, yaml_errors}'
glab api --paginate --hostname <host> "projects/<project>/pipelines/<pipeline-id>/jobs?scope[]=failed&scope[]=canceled" \
  | jq -s '(if length == 0 then error("no response from glab") else add end) | [.[] | {name, stage, status, failure_reason, web_url}]'
```

Failed jobs → name them with their `web_url`. A pipeline that failed
with no jobs at all, or with `yaml_errors` set, never started: the CI
configuration is invalid. Lint it at the head commit for the whole
error list and the jobs it would create:

<!-- scm-test: gitlab-ci-lint -->
```bash
set -o pipefail
glab api --hostname <host> "projects/<project>/ci/lint?content_ref=<sha>&dry_run=true&dry_run_ref=<source_branch>&include_jobs=true" \
  | jq '{valid, errors, warnings, jobs: [.jobs[]?.name]}'
```

The pause shows `yaml_errors` and `errors` as they are. GitLab stops at
the first logical error (a job in an undeclared stage, say), so fixing
one can reveal the next. `valid: true` with no `jobs` means the rules
excluded every job.

---

## Deploy gate (Stage 9)

A deploy triggered by the merge to `main` runs against the ship PR's
merge SHA. Two questions, in order.

### 1. Does this repo deploy at all?

**GitHub:**

```bash
gh api --hostname <gh-host> "repos/<owner>/<repo>/deployments" --jq 'length'
```

`0` → check for deploy-shaped check runs, since some stacks (Vercel,
Netlify, some GitHub Actions setups) report deploys that way:

```bash
gh api --hostname <gh-host> "repos/<owner>/<repo>/commits/<merge-sha>/check-runs" \
  --jq '[.check_runs[] | select(.name | test("deploy|vercel|netlify|release"; "i"))
        | {name, status, conclusion}]'
```

**GitLab:**

```bash
set -o pipefail
glab api --hostname <host> "projects/<project>/deployments?per_page=1" | jq 'length'
```

`0` → check the merge commit's statuses, where deploy jobs and external
services (Vercel, Netlify and similar) report:

```bash
set -o pipefail
glab api --paginate --hostname <host> "projects/<project>/repository/commits/<merge-sha>/statuses" \
  | jq -s '(if length == 0 then error("no response from glab") else add end) | [.[] | select(.name | test("deploy|vercel|netlify|release"; "i")) | {name, status}]'
```

Nothing in either → the repo has no deployments configured.

A matching check run or status is treated exactly like a deployment
below: success passes, a failure pauses, anything unfinished is polled.

### 2. Did it succeed?

**GitHub:**

```bash
gh api --hostname <gh-host> "repos/<owner>/<repo>/deployments?sha=<merge-sha>" --jq '.[0].id'
gh api --hostname <gh-host> "repos/<owner>/<repo>/deployments/<id>/statuses" --jq '.[0] | {state, environment_url}'
```

**GitLab** — the deployments API has no SHA filter, so read every
deployment updated since the merge and match the merge SHA. A merge's
deployments all start after it, so the bound drops none of them and
keeps the read short. `<merged-at>` is the `merged_at` that
`review_state` returned; `@uri` encodes it, since a `+hh:mm` offset
would otherwise reach GitLab as a space, and `updated_after` needs
`order_by=updated_at`. A merge can deploy to more than one
environment; each one's newest deployment counts — the highest `id`,
as a retried deploy job makes a new one:

<!-- scm-test: gitlab-deploy-status -->
```bash
set -eo pipefail
since=$(jq -rn --arg t '<merged-at>' '$t | @uri')
glab api --paginate --hostname <host> "projects/<project>/deployments?updated_after=$since&order_by=updated_at&per_page=100" \
  | jq -sc --arg sha '<merge-sha>' '(if length == 0 then error("no response from glab") else add end)
      | [.[] | select(.sha == $sha)] | group_by(.environment.name)
      | map(max_by(.id) | {environment: .environment.name, status,
                           environment_url: .environment.external_url})'
```

Every environment `success` → success; any failed one → pause; any
unfinished one → poll.

| GitHub `state` | GitLab `status` | Action |
|---|---|---|
| `success` | `success` | Record `Loop — deploy: success (<environment_url>).` and continue to Stage 10. |
| `failure`, `error` | `failed`, `canceled`, `skipped` | Pause. |
| `pending`, `queued`, `in_progress` | `created`, `running`, `blocked` | Poll at 60–90 seconds. Deploys are slower than CI; `blocked` waits for a manual approval. |
| no deployment for this SHA yet | no deployment for this SHA yet | Poll; after about 15 minutes in a repo that clearly deploys, Pause 20 (`SKILL.md § Pauses`). |

---

## FINISHED (Stage 15)

Four assertions, each verified against the SCM host.

### 1. Ship PR squash-merged

`review_state` on the ship PR reads `MERGED` with a merge SHA.

### 2. Nothing open on the host

**No PR or MR left open** — take the URL from every `PR opened:` and
`MR opened:` line in the Scope's Plans and read each distinct URL once
with `review_state`; Plans that shared a ship PR record the same URL.
`MERGED` and `CLOSED` pass. `OPEN` → not finished; the pause names the
PR or MR and the Plans that recorded it.

Then three things, on the ship PR and the bookkeeping PR where the
Scope opened them, as
[`../SKILL.md § The finished gate`](../SKILL.md#the-finished-gate)
sets out:

**Zero unresolved review threads** — the § Thread sweep query on
each PR, counting every outstanding thread regardless of author.

**Every check green on the merge commit.** A check still running is
pending, not failed.

GitHub:

<!-- scm-test: github-finished-checks -->
```bash
gh api --hostname <gh-host> "repos/<owner>/<repo>/commits/<merge-sha>/check-runs" \
  --jq '{ pending: ([.check_runs[] | select(.status != "completed")] | length),
          failed:  ([.check_runs[] | select(.status == "completed"
                    and .conclusion != "success"
                    and .conclusion != "neutral"
                    and .conclusion != "skipped")] | length) }'
```

GitLab — the merge commit's pipelines, plus the statuses external
services set on it:

<!-- scm-test: gitlab-finished-checks -->
```bash
set -eo pipefail
glab api --paginate --hostname <host> "projects/<project>/pipelines?sha=<merge-sha>&ref=<default-branch>" \
  | jq -s '(if length == 0 then error("no response from glab") else add end)
        | [.[] | select(.source != "external")] | [max_by(.id) // empty]
        | { pending: ([.[] | select(.status | IN("created","waiting_for_resource","preparing",
                      "waiting_for_callback","pending","running","scheduled","canceling"))] | length),
          failed:  ([.[] | select(.status | IN("failed","canceled"))] | length) }'
glab api --paginate --hostname <host> "projects/<project>/repository/commits/<merge-sha>/statuses" \
  | jq -sc '(if length == 0 then error("no response from glab") else add end)
      | { pending: [.[] | select(.status | IN("created","waiting_for_resource","preparing","pending","running","scheduled")) | .name],
          failed:  [.[] | select((.status | IN("failed","canceled")) and (.allow_failure | not)) | .name] }'
```

The pipelines are the default branch's on the merge commit; when GitLab
merged without a new commit, older MR pipelines on the same SHA don't
count. Of those, the newest — the highest `id` — decides, as it does
for GitLab's own commit status: running a pipeline again on the same
commit makes a new one, which replaces the one before it. A pipeline
reading `success`, `skipped` or `manual` is green. A status name under
`failed` counts as failed, and one under `pending` as pending.

- `failed > 0`, or a status under `failed` → not finished; pause with
  the failing checks.
- `pending > 0`, or a status under `pending` → not yet knowable; poll at
  60–90 seconds. Post-merge
  runs on `main` routinely trail the merge by a minute or two.
- both `0` → green.

**Every linked issue closed.**

GitHub — `gh pr view --json` has no field for this, so use GraphQL:

```bash
gh api graphql --hostname <gh-host> -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
      closingIssuesReferences(first:20){ nodes{ number state } } } }
  }' -F owner=<owner> -F repo=<repo> -F pr=<n>
```

A node with `state: OPEN` → not finished; the PR claimed to close an
issue and didn't.

GitLab:

```bash
set -eo pipefail
glab api --paginate --hostname <host> "projects/<project>/merge_requests/<iid>/closes_issues" \
  | jq -s '(if length == 0 then error("no response from glab") else add end) | [.[] | select(.state == "opened") | .iid]'
glab api --hostname <host> "projects/<project>" | jq '.autoclose_referenced_issues'
```

A non-empty list → not finished. GitLab closes linked issues only when
the MR merges into the default branch, and only while the project's
*Auto-close referenced issues on default branch* setting is on: when
the second query reads `false`, the pause names that setting.

### 3. Deploy successful, or not configured

Re-read the `Loop — deploy:` marker from Stage 9. `success` and `not
configured` both pass.

### 4. Close bookkeeping PR squash-merged

The assertion-1 probe against the bookkeeping PR.
