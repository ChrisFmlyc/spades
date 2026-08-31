---
name: leads
description: Record Leads — ideas, problems, and improvements an agent noticed while working, that are deliberately OUT of scope for the current work. Runs a scout sub-agent over what just happened and files one Lead per idea under .spades/leads/. Invoked automatically when /spades:do, /spades:learn, or /spades:review finish, or directly as `/spades:leads`. Use `--list` to publish the board, `--promote` (with an optional `--as scope|quick|rule`) to turn Leads into work, `--decline` to close them. Never asks whether to generate Leads, and never writes code.
version: 2.1.0
---

# SPADES Leads

A **Lead** is an idea the AI had while doing something else: a problem
it noticed, an improvement it can see, a comment worth making about
the code or the project. One Lead per idea, recorded so the human can
come back later and pick what to implement.

The defining property: **a Lead is out of scope by construction.** It
exists precisely because it was not part of the committed work. That
is what separates it from everything else SPADES records:

| Artefact | Not a Lead because |
|---|---|
| Learning | Retrospective — *"X bit us"*. A Lead is prospective — *"we should do X"*. A Learning can **produce** a Lead. |
| Plan `Risks & Assumptions` | Scoped to one Plan; dies with it. |
| `PATTERNS.md` / `ANTI-PATTERNS.md` | Durable human-authored rules, not candidate work. |
| Scope | A committed outcome. A Lead is explicitly uncommitted. |
| Bot review finding | A defect on a diff that blocks a merge. A Lead blocks nothing and has no deadline. |
| `// TODO` | The thing that rots. A Lead has an ID, a status, and a decay policy. |

## Two invariants

1. **It never asks whether to record.** Generating Leads is a side
   effect of doing the work, never a question put to the human. No
   `AskUserQuestion` anywhere in the capture path, ever.

   `--promote` is **not** the capture path and does ask — deciding
   what a Lead becomes is the human's call, and § `--promote` is
   where that question lives. Recording is automatic; promoting is
   deliberate.
2. **It never writes code.** The scout reads and returns; this skill
   records. Nothing under this skill edits a source file.

## Pre-Flight

1. **`.spades/config` exists** and `project:` is set. Else → *"Run
   `/spades:setup` first."*
2. **Read `backend:` from `.spades/config`** — `linear` or `local`.
   This is the same key every other SPADES skill reads, and it is the
   **only** thing that decides whether a Lead reaches Linear:

   | `backend:` | Behaviour |
   |---|---|
   | `local` | The Lead file is the whole record. No mirror. |
   | `linear` | Write the file **and** mirror the Lead to Linear, per § Recording. |

   A Lead is an artefact like any other: if the project's backend is
   Linear, Leads go to Linear. Never gate the mirror on anything else.

3. **Read `review_format:`** — `html` or `cli`. Decides whether
   § Render and open produces `.html` or `.md`.
4. **Read `leads:`** — `on` *(default when the key is absent)* or
   `off`. A kill switch and nothing more: `off` means do nothing,
   return immediately, print nothing. It does **not** decide the
   backend — that is `backend:`'s job, above.
5. **Ensure `.spades/leads/` exists.** Create if missing.

## Modes

| Invocation | Mode |
|---|---|
| `/spades:leads` | **Scout** the working state — the branch diff vs `main`, or everything since the last Lead if the tree is clean — then record, render, and open the board. |
| `/spades:leads --from do --plan P-…` | Scout the Plan's diff. Auto-invoked. |
| `/spades:leads --from learn --learning <path>` | Scout one Learning for the change it implies. Auto-invoked. |
| `/spades:leads --from review --report <path>` | Scout a review report's non-blocking findings. Auto-invoked. |
| `/spades:leads --list` | Publish the board. Records nothing. |
| `/spades:leads --promote L-a,L-b [--as scope\|quick\|rule]` | Turn Leads into work — **invokes** `/spades:scope` or `/spades:quick` with the context. Confirms which unless `--as` is given. One Lead per Quick item, always. |
| `/spades:leads --decline L-x "reason"` | Close a Lead with a reason. |

**Every mode that records ends by rendering and opening the board** —
receipt first, then § Render and open. `--list` skips the recording
and goes straight there.

## Storage format

One Markdown file per Lead:

```
.spades/leads/L-<slug>-<suffix>.md
```

`<slug>` is derived from the title (lowercase, hyphens, ≤48 chars).
`<suffix>` is a random 4-character base62 ID, minted and
collision-checked exactly as `/spades:plan` mints its own.

Frontmatter — flat YAML, one key per line, no nested structures:

```yaml
---
id: L-parse-config-swallows-zoderror-7Kd2
title: parseConfig swallows ZodError so callers cannot tell absent from invalid
project: spades
kind: defect | enhancement | simplification | risk | opportunity
area: scripts/lint/frontmatter.ts
size: trivial | small | medium | large
confidence: high | medium | low
source: do | learn | review | manual
status: open | promoted | declined | stale
created: YYYY-MM-DD
origin_plan: P-rag-pipeline-lookup-3HyD    # optional
learning_ref: .spades/learnings/2026-08-30-config-parse.md   # optional
promoted_to: S-harden-config-parsing        # optional; set by --promote
declined_reason: deliberate, documented in ANTI-PATTERNS.md  # optional
linear_issue_id: <uuid>                     # set only when backend: linear
---
```

Body — three short sections, nothing else:

```markdown
## What I noticed

The evidence. Name the file and line. What the code actually does.

## Why it might matter

The consequence, hedged honestly. "Callers currently cannot
distinguish a missing config from a malformed one, so a typo in
`.spades/config` reads as an absent key."

## What I'd do

The smallest version of the change. One paragraph.
```

**Hard cap: 15 lines of body.** A Lead longer than that is a Scope
trying to be born — shorten it, or it is not a Lead.

## The scout

One sub-agent per capture run, `subagent_type: general-purpose`,
per `docs/FRAMEWORK.md § Sub-agent Dispatch`. It reads and returns;
it owns no resource and writes nothing.

**Inputs to the prompt:**

- The source material: the diff (`do`), the Learning file (`learn`),
  or the review report's non-blocking findings (`review`).
- `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`.
- The parent Scope's acceptance criteria — so it can tell in-scope
  from out-of-scope.
- **The open Leads** — `id`, `title`, and `area` for every Lead with
  `status: open`. This is what makes dedupe possible.
- The budget for this source (below).

**The gate — a candidate must clear all six or it is not returned:**

1. **Specific.** Names a file, function, or mechanism. *"Improve
   error handling"* fails. *"`parseConfig` swallows the ZodError"*
   passes.
2. **Out of scope.** If it is inside the current Scope's acceptance
   criteria it is not a Lead, it is the work.
3. **Not a defect on this diff.** That belongs to the reviewer and
   to `/spades:evaluate`. A Lead is never a reason a PR shouldn't
   merge, and never evidence for a verification row.
4. **Actionable.** Implies a change, not a feeling.
5. **Costed.** Carries a `size`.
6. **Survives the session.** Readable in six months by someone who
   was not here.

**Budget — rank, then drop the remainder:**

| Source | Max returned |
|---|---|
| `do` | 3 |
| `learn` | 1 |
| `review` | 5 |
| manual | 3 |

The scout reports how many it dropped. A source that consistently
fills its budget is a signal the threshold is too loose.

**A Learning only produces a Lead when it implies a specific change
to this project.** If its action is *"remember this when planning"*,
it stays a Learning and the scout returns nothing.

**Return schema** — a JSON code block labelled `spades-leads`:

```json
{
  "leads": [
    { "title": "...", "kind": "defect", "area": "path/to/file.ts",
      "size": "small", "confidence": "high",
      "noticed": "...", "matters": "...", "would_do": "..." }
  ],
  "duplicates": [ { "of": "L-existing-7Kd2", "title": "..." } ],
  "dropped": 2
}
```

`duplicates` are never filed. The coordinator counts them for the
receipt and moves on.

## Recording (fan-out dispatch)

Per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`, one
sub-agent per resource, all spawned in a single message:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-lead` | `.spades/leads/L-<…>.md` — one worker **per Lead**; each owns exactly one file. | `{ status: ok }` |
| `worker-linear-lead` *(only when `backend: linear`)* | Linear — `save_issue(team: <linear.team_id>, project: <linear.project_id>, title: "L-<slug> — <title>", description: <body>, label: "spades:lead")` in the team's triage/backlog state. Includes the Layer-2 freshness probe. | `{ status: ok, linear_issue_id }` |

After the wave: on `backend: linear`, the coordinator injects each
`linear_issue_id` into its Lead file's frontmatter. Sequential after
the worker wrote it — that is the sanctioned integration write.

**Failure semantics** follow FRAMEWORK: a failed file worker aborts
and surfaces; a failed Linear worker keeps the local file (it is
canonical) and reports the mirror failure. Leads never block the
skill that invoked them — a capture failure prints a warning and the
caller continues.

## The receipt

Every capture mode prints one line before rendering. Not a prompt —
a receipt:

```
○ Leads — 2 filed: L-parse-config-swallows-zoderror, L-lint-accepts-nested-yaml
          (1 duplicate, 2 dropped under budget)
```

Nothing filed:

```
○ Leads — none (nothing outside scope worth recording)
```

Then **render and open the board** per § Render and open, and return
control to the caller. Never ask a question.

Two cases skip the render, because a tab showing nothing is worse
than no tab:

- `leads: off` — nothing ran at all.
- Nothing filed **and** no open Leads already on the board.

Nothing filed but Leads *are* open → still render. The human asked
for a capture and the board is the answer to "so what is outstanding
now?".

## `--list` — the board

Reads every `.spades/leads/L-*.md` for the active project. Records
nothing.

**Sort by provenance, then confidence** — provenance is objective and
free, and it beats any score the AI could invent:

1. `source: learn` — evidence-backed; something actually went wrong.
2. `source: review` — a persona panel flagged it.
3. `source: do` / `manual` — speculative.

**Group by `area`**, because that is how the work gets done ("I'm in
the lint scripts today, what's outstanding there?").

**Hide by default:** `status: declined`, `status: promoted`, and
`confidence: low`. Everything is still on disk.

**The funnel header** — the only feedback that tells you whether the
scout is calibrated:

```
Leads — spades      open 14 · promoted 9 · declined 21 · stale 4
                    conversion 30%  (healthy 30–50%)
```

Conversion is `promoted / (promoted + declined)`. Above the band
means Leads are being rubber-stamped or the scout is under-generating;
below it means noise. Report the number, never act on it.

Then render it per § Render and open.

## Render and open

**Read `review_format:` from `.spades/config` and branch.** This step
is not optional and not conditional on how the skill was invoked — a
recorded Lead the human never sees is the same as no Lead.

Create `.spades/.tmp/` if it does not exist (it is gitignored by
`/spades:setup` § Step 5.5).

### `review_format: cli`

1. Write the board to `.spades/.tmp/leads.md` — the funnel header,
   then the areas, then the rows.
2. **Print it inline.** In CLI mode the terminal is the surface.
3. Open the file too, so it survives the scrollback: run the
   **OPEN_CMD prelude** (`docs/FRAMEWORK.md § OPEN_CMD detection
   prelude`) and `$OPEN_CMD "<absolute-path-to-leads.md>"` in the
   background.

### `review_format: html`

1. Dispatch **`worker-html-leads`** (below). Per
   `docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering` the
   worker renders **and** opens the page — the open is step 4 of its
   contract, not an afterthought.
2. **Do not also dump the board to the CLI.** The tab is the surface;
   print the two-line confirmation instead:

   ```
   ✓ Leads board: .spades/.tmp/leads.html
   ○ opened in your browser
   ```

### When the open fails

`OPEN_CMD` is empty on an unrecognised OS, and the worker returns
`opened: false` in that case. **Never treat that as a failure** —
print the path and carry on:

```
✓ Leads board: .spades/.tmp/leads.html
○ Open it in your browser: file:///<absolute-path>
```

Same fallback in CLI mode; the board was already printed inline, so
nothing is lost.

### `worker-html-leads`

Per `docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering`.

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/leads/template.html`
- `output_path`: `.spades/.tmp/leads.html`
- `frontmatter`: `{ project_slug, open_count, promoted_count,
  declined_count, stale_count, conversion_pct, conversion_health,
  rendered_at, plugin_version }`
- `blocks`:
  - `area-groups` — one per `area`. Fields: `area, count`.
  - `lead-rows` — one per visible Lead. Fields: `id, title, kind,
    area, size, confidence, source, source_label, created`.
- Required markers: `<!-- SPADES-BLOCK:area-groups -->`,
  `<!-- SPADES-BLOCK:lead-rows -->`.

The template is the Cockpit skeleton shared with `/spades:list` —
same `header.cmd` → `.deck` → `.wrap.body` → `aside.rail` + `main` →
`footer` structure, same sizing, same `.pill` / `.stat` / `.card`
vocabulary — and carries the embedded
`<script type="application/yaml" id="spades-frontmatter">` block the
other transient views use. Substitute it along with the rest.

## `--promote` — turning Leads into work

```
/spades:leads --promote L-a,L-b [--as scope|quick|rule]
```

1. **Read the named Leads.** Unknown ID → abort naming it.

2. **The one hard rule: one Lead per Quick item.** A Quick item is a
   single focused commit addressing a single Lead. Two Leads in one
   unit of work is a **Scope** — that is precisely what a Scope is
   for. Never bundle several Leads into one Quick item, whatever the
   human picks and whatever `--as` says.

3. **Route in two passes: cluster, then size.** One `--promote` can
   legitimately produce several destinations — a Scope *and* a Quick,
   or two Scopes. Do not force the whole set down one path.

   **Pass 1 — cluster by relatedness.** Group the promoted Leads:
   same `area`, the same underlying change, or one only makes sense
   once the other lands. Relatedness is about the *work*, not the
   `kind` field.

   **Pass 2 — apply the routing matrix, per Lead.**

   ### The routing matrix

   **This matrix is the routing decision. Apply it to every promoted
   Lead and follow the result. Do not substitute judgement for it, do
   not average across the set, and do not skip a row because the
   answer "obviously" looks like something else.**

   | # | Related to another promoted Lead? | Passes `/spades:quick` § The Gate? | Destination |
   |---|---|---|---|
   | 1 | **Yes** | *not evaluated* | **The single Scope for its cluster.** One acceptance criterion per Lead in that cluster. |
   | 2 | No | **Yes** — all ten | **Its own Quick item.** One Lead, one focused commit. |
   | 3 | No | **No** — one or more fail | **Its own Scope.** Name the failing criterion when you report it. |

   The rows are exhaustive and ordered. **Row 1 short-circuits** —
   relatedness is evaluated first and wins outright, so a Lead that
   would sail through the Quick gate alone still joins its cluster's
   Scope. The gate is only ever consulted for a Lead that ends up
   alone.

   Two Leads landing in row 1 for the same cluster share **one**
   Scope. Two Leads landing in row 2 get **two** Quick items, never
   one. Two unrelated Leads in row 3 get **two** Scopes, not one
   combined Scope — unrelated work does not belong in a single Scope
   any more than it belongs in a single Quick item.

   **The Quick gate is `/spades:quick`'s, not a guess.** Read
   `${CLAUDE_PLUGIN_ROOT}/skills/quick/SKILL.md § The Gate` and walk
   all ten criteria. Never route to Quick off the scout's `size`
   field: `size` is an estimate an LLM made while reading a diff, and
   routing on it is how work well past the 50-line cap has been sent
   to the fast path. `size` may *rank* candidates; only the gate
   decides.

   The criteria that disqualify most often: **≤ 50 LoC changed**
   (hard stop ~100), **single concern**, **one file or one tight
   cluster in one module**, and no schema / architectural / security
   / public-API change. The gate is all-or-nothing — one failure
   means Scope.

   ### Matrix verification cases

   Given a board where `l1`+`l2` are related, `l3` is small and
   isolated, `l4` is large and unrelated, and `l5` is related to
   `l3` — these are the required outcomes. If your routing disagrees
   with any row, your routing is wrong.

   | Promoted | Rows applied | Result |
   |---|---|---|
   | `l1, l2` | both row 1 | **one Scope** |
   | `l1, l2, l4` | `l1`,`l2` row 1 · `l4` row 3 | **one Scope** for `l1`+`l2`, **plus a second Scope** for `l4` — alone, but it fails the gate |
   | `l3, l4` | `l3` row 2 · `l4` row 3 | `l3` → **Quick** · `l4` → **its own Scope** (a mixed outcome, which is correct) |
   | `l3, l5` | both row 1 | **one Scope** — `l5` is related to `l3`, so row 1 takes `l3` before the gate is ever consulted |
   | `l3` alone | row 2 | **Quick** |
   | `l4` alone | row 3 | **its own Scope** |

4. **Propose the split, then confirm.** Show the grouping and the
   destination for each cluster, with the gate verdict in one line
   for anything routed to Quick. Then ask via `AskUserQuestion`:

   > *Promote 3 leads — L-a and L-b look related, L-c stands alone.*
   >
   > - **As proposed** — one Scope for L-a + L-b, one Quick for L-c.
   > - **One Scope for all three** — treat them as a single change.
   > - **A Scope each** — three separate Scopes, no grouping.

   Recommendation first, one line of why. A single promoted Lead
   still gets asked — Scope and Quick are both legitimate for one
   Lead, and only the human knows which the work deserves.

5. **`--as` skips the question**, with two things it cannot override:

   - **Rule 2.** `--as quick` on three Leads produces three Quick
     items, never one carrying three.
   - **The Quick gate.** `--as quick` still walks the ten criteria
     first. A Lead that fails is reported with the failing criterion
     and left `open` — do not hand it to `/spades:quick`, which
     would only refuse it at its own gate and waste the round trip.

   `--as scope` on one Lead is always fine — a Scope has no gate.
   `--as rule` routes to the docs.

6. **Invoke the destination skill(s), passing the context.** Do not
   print a command for the human to copy — that dead-ends at *"what
   is the Scope called?"* with *"it does not exist yet"*, which is no
   use to anybody.

   | Destination | What you invoke |
   |---|---|
   | Scope cluster | **`/spades:scope`** once per cluster |
   | Quick | **`/spades:quick`** once per Lead, sequentially — rule 2 |
   | Rule | **`/spades:patterns`** or **`/spades:anti-patterns`** |

   Several clusters means several invocations, in order, each
   reporting its own minted ID before the next starts.

   Pass the seed as the argument and let the destination skill do its
   own job from there — it will ask its own questions, and the human
   is present because they typed `--promote`. Never pre-empt those
   questions, and never write the Scope or Quick file yourself.

   The seed for a Scope: the Leads' *What I noticed* as the problem
   statement, their *Why it might matter* as the justification, and
   **one acceptance criterion per Lead**. For a Quick item: that one
   Lead's *What I'd do*.

7. **Capture the minted ID and record it.** `/spades:scope` returns
   an `S-…`, `/spades:quick` a `Q-…`. For each promoted Lead set
   `status: promoted` and `promoted_to: <that ID>`, and — on
   `backend: linear` — close its `L-` issue with a link to the new
   Scope issue. For a rule, `promoted_to:` names the doc.

   **The ID comes from the skill that minted it — never guess one.**
   Do not derive a slug and report it as though it exists.

8. **If a destination skill aborts or the human backs out**, the
   Leads stay `status: open` and nothing is recorded. A half-promoted
   Lead is worse than an unpromoted one: it disappears off the board
   while no work exists for it.

### Worked examples

**Two related Leads — row 1, one Scope**

```
/spades:leads --promote L-lint-nested-yaml-7Kd2,L-lint-missing-fallback-3Hy9
```

Same `area`, two halves of one change → both row 1, so the gate is
never consulted and Scope is the recommendation:

```
○ Promoting 2 leads — related (both in scripts/lint/frontmatter.ts)
  → row 1 for both: one Scope
  → invoking /spades:scope
    Problem:  the linter accepts nested YAML, and renders a missing
              required field as an empty string
    Criteria: 1. nested structures rejected with a pointed error
              2. a missing required field fails, never renders empty

  … /spades:scope runs, asks its own questions, mints the ID …

✓ S-harden-the-frontmatter-linter created
✓ L-lint-nested-yaml-7Kd2      → promoted_to: S-harden-the-frontmatter-linter
✓ L-lint-missing-fallback-3Hy9 → promoted_to: S-harden-the-frontmatter-linter
```

**Two unrelated Leads that both pass the gate — row 2 twice, two Quick items**

```
/spades:leads --promote L-typo-in-readme-4Bn7,L-drop-unused-import-9Qc3
```

Unrelated, different modules, each one file and well under 50 LoC.
Rule 2 means **two** Quick items, never one carrying both:

```
○ Promoting 2 leads — unrelated, both pass the Quick gate
  → row 2 twice: 2 separate Quick items
  → /spades:quick "fix the install command typo in README"
✓ Q-fix-readme-install-typo-2Kp1 created
  → /spades:quick "drop the unused Buffer import in lib/api.ts"
✓ Q-drop-unused-buffer-import-8Rt4 created

✓ L-typo-in-readme-4Bn7     → promoted_to: Q-fix-readme-install-typo-2Kp1
✓ L-drop-unused-import-9Qc3 → promoted_to: Q-drop-unused-buffer-import-8Rt4
```

**A mixed outcome — row 2 and row 3 in one run**

The case most likely to be got wrong. One small isolated Lead, one
large unrelated one:

```
/spades:leads --promote L-drop-unused-import-9Qc3,L-autoremove-index-join-7Kd2
```

```
○ Promoting 2 leads — unrelated to each other, routed separately
  → L-drop-unused-import-9Qc3      row 2 → Quick (gate: all ten pass)
  → L-autoremove-index-join-7Kd2   row 3 → own Scope
       gate fails: ≤50 LoC (est. ~140), and touches the schema's
       status union

  → /spades:quick "drop the unused Buffer import in lib/api.ts"
✓ Q-drop-unused-buffer-import-8Rt4 created
  → /spades:scope "the removal decision reads what it needs"
✓ S-removal-decision-reads-what-it-needs created

✓ L-drop-unused-import-9Qc3    → promoted_to: Q-drop-unused-buffer-import-8Rt4
✓ L-autoremove-index-join-7Kd2 → promoted_to: S-removal-decision-reads-what-it-needs
```

Never collapse this into one Scope covering both, and never send the
large one to Quick because its partner qualified.

**Forcing it, no question asked**

```
/spades:leads --promote L-loop-stage8-wedged-check-3Hy9 --as scope
```

`medium`, single Lead, `--as` given → invokes `/spades:scope`
immediately with no `AskUserQuestion`.

**A Lead that is really a prohibition**

```
/spades:leads --promote L-never-gate-on-reviewdecision-9Xa2 --as rule
```

```
○ Promoting 1 lead as a rule — invoking /spades:anti-patterns
  → add: never gate a merge on reviewDecision
✓ L-never-gate-on-reviewdecision-9Xa2 → promoted_to: ANTI-PATTERNS.md
```

## `--decline`

`/spades:leads --decline L-x "reason"`

Sets `status: declined` and `declined_reason:`, and cancels the
Linear issue on `backend: linear`. A reason is **required** — a board
that fills with unexplained declines teaches nobody anything.

Declining must stay as cheap as promoting, or the board never
shrinks.

## Decay

A Lead goes `stale` when its `area` path no longer exists, or when
it has been `open` and untouched for six months. `--list` hides
stale Leads and counts them in the header. Nothing is deleted.

## Who may invoke this — and what that authorizes

Capture mode carries **no trigger conditions**. It fires because a
phase skill finished, or because the human typed `/spades:leads`.
Never reach for it on your own initiative because you happen to have
an idea — that is what the phase hooks are for.

Authorized callers:

1. **The human**, typing `/spades:leads` in any mode.
2. **`/spades:do`**, on completion.
3. **`/spades:learn`**, on completion.
4. **`/spades:review`**, on completion.

**Acyclicity — the capture path invokes nothing.**
`do | learn | review → leads → scout` is one-way and terminal. A
capture run invokes **no** SPADES skill: not `scope`, not `quick`,
not `plan`, not the loop. It files Leads, renders the board, returns.

`--promote` does invoke `/spades:scope` / `/spades:quick` / the docs
skills — and that is only legal because **promote is never reachable
from a capture run.** It happens when a human types it, and nowhere
else.

That distinction is the whole safety property, so it is worth stating
what it prevents. `leads → scope → plan → do → leads` is a cycle. It
is a safe one *only* while every lap requires a human to choose to
promote. If a capture run could promote, `/spades:do` finishing would
be able to mint a Scope on its own — machinery inventing work, which
is the exact failure this skill exists to avoid. **A capture run must
never promote, for any reason, however obvious the promotion looks.**

## Under `/spades:loop`

The loop's Stage 3 is not the right moment: a PARTIAL verdict rolls
the Plan back to `delivering` and re-runs Do, so scouting there files
Leads against a diff that is about to change.

**Under the loop, the `do` capture fires after the verdict lands
(Stage 5), when the diff is final.** Standalone `/spades:do` with no
evaluate behind it fires on completion, and dedupe absorbs the
overlap if an evaluate follows later. Same scout, same
`source: do` — only the moment moves.

## Forbidden

- Asking the human whether to generate Leads, in any mode.
- Editing any source file, or letting the scout do so.
- Filing a Lead that duplicates an open one.
- Filing a candidate that failed the gate, to reach a count.
- Using a Lead as evidence for a `/spades:evaluate` verification row,
  or as a reason a PR should not merge.
- **Bundling more than one Lead into a single Quick item** — see
  § `--promote` rule 2. N Leads under Quick means N Quick items. Two
  Leads in one unit of work is a Scope, and no flag or human answer
  overrides that.
- Recording `status: promoted` before the Scope or Quick item exists.
- Recording Leads without rendering the board — see § Render and
  open. The two exceptions are listed there and are the only ones.
- Blocking the calling skill on a Leads failure.
- Invoking another SPADES skill **from a capture run**. Only
  `--promote`, typed by a human, may invoke one — see § Acyclicity.
- Promoting from an auto-invoked capture run (`--from do|learn|review`),
  under any circumstances.
- Reporting an `S-` or `Q-` ID you derived rather than one the
  destination skill actually minted.
- **Routing to Quick off the `size` field** instead of walking
  `/spades:quick` § The Gate. `size` is an estimate; the gate decides.
- Sending a whole promoted set down one path when it contains
  unrelated clusters — see § `--promote` step 3.
