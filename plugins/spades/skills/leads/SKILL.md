---
name: leads
description: Record Leads — ideas, problems, and improvements an agent noticed while working, that are deliberately OUT of scope for the current work. Runs a scout sub-agent over what just happened and files one Lead per idea under .spades/leads/. Invoked automatically when /spades:do, /spades:learn, or /spades:review finish, or directly as `/spades:leads`. Use `--list` to publish the board, `--promote` to turn Leads into a Scope, `--decline` to close them. Never asks whether to generate Leads, and never writes code.
version: 1.1.0
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

1. **It never asks.** Generating Leads is a side effect of doing the
   work, never a question put to the human. No `AskUserQuestion` in
   the capture path, ever.
2. **It never writes code.** The scout reads and returns; this skill
   records. Nothing under this skill edits a source file.

## Pre-Flight

1. **`.spades/config` exists** and `project:` is set. Else → *"Run
   `/spades:setup` first."*
2. **Read `leads:` from `.spades/config`.** Values:

   | Value | Behaviour |
   |---|---|
   | `off` | Do nothing. Return immediately, print nothing. |
   | `local` *(default when the key is absent)* | Record Leads as files. No Linear mirror. |
   | `linear` | Record files **and** mirror each Lead to Linear. |

3. **Read `review_format:`** — `html` or `cli`. Drives what `--list`
   renders and opens.
4. **Ensure `.spades/leads/` exists.** Create if missing.

## Modes

| Invocation | Mode |
|---|---|
| `/spades:leads` | **Scout** the working state — the branch diff vs `main`, or everything since the last Lead if the tree is clean — then record, render, and open the board. |
| `/spades:leads --from do --plan P-…` | Scout the Plan's diff. Auto-invoked. |
| `/spades:leads --from learn --learning <path>` | Scout one Learning for the change it implies. Auto-invoked. |
| `/spades:leads --from review --report <path>` | Scout a review report's non-blocking findings. Auto-invoked. |
| `/spades:leads --list` | Publish the board. Records nothing. |
| `/spades:leads --promote L-a,L-b` | Turn Leads into a Scope (or a Quick item). |
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
linear_issue_id: <uuid>                     # optional; leads: linear only
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
| `worker-linear-lead` *(only when `leads: linear`)* | Linear — `save_issue(team: <linear.team_id>, project: <linear.project_id>, title: "L-<slug> — <title>", description: <body>, label: "spades:lead")` in the team's triage/backlog state. Includes the Layer-2 freshness probe. | `{ status: ok, linear_issue_id }` |

After the wave: on `leads: linear`, the coordinator injects each
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

`/spades:leads --promote L-a,L-b`

1. **Read the named Leads.** Unknown ID → abort naming it.
2. **Route by size:**
   - Every named Lead is `trivial` or `small`, and one focused
     commit covers them → say so and point at `/spades:quick`.
     Cheapest path; do not manufacture a Scope for a one-liner.
   - Otherwise → seed **`/spades:scope`**. The Leads' *What I
     noticed* become the problem statement, their *Why it might
     matter* the justification, and each Lead becomes one acceptance
     criterion. **Promote clusters, not items** — several Leads in
     one `area` make a better Scope than one Lead alone.
3. **This skill does not invoke `/spades:scope` or `/spades:quick`.**
   It prints the exact command with the seed text. Promotion is the
   human's act; the skill prepares it.
4. **On confirmation that the Scope or Quick item exists**, set
   `status: promoted` and `promoted_to:` on each Lead, and — on
   `leads: linear` — close the `L-` issue with a link to the new
   Scope issue.

**A third destination:** a Lead that is really a rule, not work,
routes to `/spades:anti-patterns` or `/spades:patterns`. Record it as
`promoted` with `promoted_to:` naming the doc.

## `--decline`

`/spades:leads --decline L-x "reason"`

Sets `status: declined` and `declined_reason:`, and cancels the
Linear issue on `leads: linear`. A reason is **required** — a board
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

**Acyclicity.** `do | learn | review → leads → scout` is one-way and
terminal. This skill invokes no SPADES skill — not `scope`, not
`quick`, not `plan`, not the loop. Promotion prints a command; it
never runs one.

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
- Recording `status: promoted` before the Scope or Quick item exists.
- Recording Leads without rendering the board — see § Render and
  open. The two exceptions are listed there and are the only ones.
- Blocking the calling skill on a Leads failure.
- Invoking another SPADES skill.
