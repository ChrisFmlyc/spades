---
name: leads
description: Record Leads — ideas, problems, and improvements an agent noticed while working, that are deliberately OUT of scope for the current work. Runs a scout sub-agent over what just happened and files one Lead per idea under .spades/leads/. Invoked automatically when /spades:do, /spades:learn, or /spades:review finish, or directly as `/spades:leads`. Use `--list` to publish the board, `--promote` (with an optional `--as scope|quick|rule`) to turn Leads into work, `--decline` to close them. Never asks whether to generate Leads, and never writes code.
version: 2.3.0
---

# /spades:leads

A **Lead** is an idea the AI had while doing something else: a
problem noticed, an improvement it can see, a comment worth making
about the code or the project. One Lead per idea, recorded so the
human can come back later and pick what to implement.

A Lead is out of scope by construction — it exists precisely because
it was not part of the committed work. That separates it from
everything else SPADES records:

| Artefact | Difference |
|---|---|
| Learning | Retrospective (*"X bit us"*). A Lead is prospective (*"we should do X"*). A Learning can produce a Lead. |
| Plan Risks & Assumptions | Scoped to one Plan; dies with it. |
| `PATTERNS.md` / `ANTI-PATTERNS.md` | Durable human-authored rules, not candidate work. |
| Scope | A committed outcome. A Lead is uncommitted. |
| Bot review finding | A defect on a diff that blocks a merge. A Lead blocks nothing. |
| `// TODO` | Rots. A Lead has an ID, a status, and a decay policy. |

Two properties hold throughout: **capture is automatic** (a side
effect of finishing work, with no question put to the human), and
**this skill writes no code** (the scout reads and returns; the
skill records).

Read `docs/FRAMEWORK.md` § ID Format, § Sub-agent Dispatch, and
§ Output Format before running.

## Pre-Flight

1. `.spades/config` exists with `project:` set — else `/spades:setup`.
2. Read `backend:`. It decides whether a Lead reaches Linear, on the
   same terms as every other artefact: `local` → the file is the
   whole record; `linear` → the file plus a mirrored issue.
3. Read `review_format:` — decides whether § Render produces `.html`
   or `.md`.
4. Read `leads:` — `on` (default when absent) or `off`. `off` means
   return immediately, printing nothing.
5. Ensure `.spades/leads/` exists.

## Modes

| Invocation | Mode |
|---|---|
| `/spades:leads` | Scout the working state — the branch diff vs `main`, or everything since the last Lead when the tree is clean — then record, render, open. |
| `/spades:leads --from do --plan P-…` | Scout the Plan's diff. Auto-invoked by `/spades:do`. |
| `/spades:leads --from learn --learning <path>` | Scout one Learning for the change it implies. Auto-invoked by `/spades:learn`. |
| `/spades:leads --from review --report <path>` | Scout a review report's non-blocking findings. Auto-invoked by `/spades:review`. |
| `/spades:leads --list` | Publish the board; records nothing. |
| `/spades:leads --promote L-a,L-b [--as scope\|quick\|rule]` | Turn Leads into work by invoking `/spades:scope`, `/spades:quick`, or a docs skill. |
| `/spades:leads --decline L-x "reason"` | Close a Lead with a reason. |

Every recording mode ends with the receipt and the rendered board.

## Storage

One file per Lead at `.spades/leads/L-<slug>-<suffix>.md`; `<slug>`
from the title (lowercase, hyphens, ≤48 characters), `<suffix>` a
random 4-character base62 ID collision-checked as `/spades:plan`
mints its own.

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
origin_plan: P-rag-pipeline-lookup-3HyD                       # optional
learning_ref: .spades/learnings/2026-08-30-config-parse.md    # optional
promoted_to: S-harden-config-parsing                          # set by --promote
declined_reason: deliberate, documented in ANTI-PATTERNS.md   # set by --decline
linear_issue_id: <uuid>                                       # backend: linear
---
```

```markdown
## What I noticed

The evidence: file, line, what the code actually does.

## Why it might matter

The consequence, hedged honestly.

## What I'd do

The smallest version of the change. One paragraph.
```

The body is at most 15 lines. Longer than that is a Scope trying to
be born.

## The scout

One `general-purpose` sub-agent per capture run, per
`docs/FRAMEWORK.md § Sub-agent Dispatch`. It owns no resource and
returns findings.

**Prompt inputs:** the source material (the diff, the Learning file,
or the review report's non-blocking findings); `ARCHITECTURE.md`,
`PATTERNS.md`, `ANTI-PATTERNS.md`; the parent Scope's acceptance
criteria (to tell in-scope from out); the open Leads (`id`, `title`,
`area`) for dedupe; and the budget below.

**The gate** — a candidate clears all six or is not returned:

1. **Specific** — names a file, function, or mechanism.
2. **Out of scope** — inside the Scope's acceptance criteria it is
   the work, not a Lead.
3. **Not a defect on this diff** — that belongs to review and
   `/spades:evaluate`.
4. **Actionable** — implies a change, not a feeling.
5. **Costed** — carries a `size`.
6. **Survives the session** — readable in six months by someone who
   was not here.

**Budget** — rank, return the top N, report the rest as dropped:
`do` 3, `learn` 1, `review` 5, manual 3. A Learning produces a Lead
only when it implies a specific change to this project; *"remember
this when planning"* stays a Learning.

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

Duplicates of open Leads are counted for the receipt and not filed.
That is what makes re-capture safe: a Plan reworked after a PARTIAL
verdict scouts its diff again and the overlap is absorbed.

## Recording (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-lead` | `.spades/leads/L-<…>.md` — one worker per Lead | `{ status: ok }` |
| `worker-linear-lead` *(`backend: linear`)* | Linear — `save_issue(team: <linear.team_id>, project: <linear.project_id>, title: "L-<slug> — <title>", description: <body>, label: "spades:lead")` in the team's triage or backlog state. Carries the freshness probe. | `{ status: ok, linear_issue_id }` |

After the wave, with `backend: linear`, inject each
`linear_issue_id` into its Lead file. A failed file worker aborts
and surfaces; a failed Linear worker keeps the local file and
reports the mirror failure. A Leads failure is a warning to the
calling skill, which continues.

## The receipt

Every capture mode prints one line, then renders the board:

```
○ Leads — 2 filed: L-parse-config-swallows-zoderror, L-lint-accepts-nested-yaml
          (1 duplicate, 2 dropped under budget)
```

```
○ Leads — none (nothing outside scope worth recording)
```

The board is skipped in two cases: `leads: off`, and nothing filed
with no open Leads on the board. Nothing filed with open Leads still
renders, since the board answers "what is outstanding now?".

## `--list` — the board

Reads every `.spades/leads/L-*.md` for the active project.

- **Sort by provenance, then confidence.** `source: learn`
  (evidence-backed) first, then `review` (a panel flagged it), then
  `do` and `manual` (speculative).
- **Group by `area`** — how the work gets picked up.
- **Hide by default:** `declined`, `promoted`, `confidence: low`.
- **Funnel header:**

  ```
  Leads — spades      open 14 · promoted 9 · declined 21 · stale 4
                      conversion 30%  (healthy 30–50%)
  ```

  Conversion is `promoted / (promoted + declined)`. Above the band
  suggests rubber-stamping or an under-generating scout; below it,
  noise. Report the number.

## Render and open

Create `.spades/.tmp/` if missing (gitignored by `/spades:setup`).

**`review_format: cli`** — write the board to `.spades/.tmp/leads.md`
(funnel header, areas, rows), print it inline, and open the file via
the OPEN_CMD prelude so it survives the scrollback.

**`review_format: html`** — dispatch `worker-html-leads` per
`docs/FRAMEWORK.md § worker-html-*`, which renders and opens the
page, and print:

```
✓ Leads board: .spades/.tmp/leads.html
○ opened in your browser
```

An empty `OPEN_CMD` (unrecognised OS) returns `opened: false`; print
`○ Open it in your browser: file:///<absolute-path>` and carry on.

### `worker-html-leads`

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/leads/template.html`
- `output_path`: `.spades/.tmp/leads.html`
- `frontmatter`: `{ project_slug, open_count, promoted_count,
  declined_count, stale_count, conversion_pct, conversion_health,
  rendered_at, plugin_version }`, also embedded in
  `<script id="spades-frontmatter">`
- `blocks`:
  - `area-groups` — one per `area`. Fields: `area, count`.
  - `lead-rows` — one per visible Lead. Fields: `id, title, kind,
    area, size, confidence, source, source_label, created`.

Required markers: `area-groups`, `lead-rows`.

## `--promote` — turning Leads into work

```
/spades:leads --promote L-a,L-b [--as scope|quick|rule]
```

Promotion is the human's deliberate act, so it asks; it is reached
only when the human types it, never from a capture run. That is
what keeps `leads → scope → plan → do → leads` a safe cycle: every
lap needs a human to choose.

1. **Read the named Leads.** An unknown ID, or one already carrying
   `promoted_to:`, aborts naming it (and the item it became).

2. **Scope is the only destination that groups.** A Quick item is
   one focused commit for one Lead; a rule is one prohibition. Two
   Leads in one unit of work is a Scope. So N Leads to Quick is N
   Quick items, and N Leads to rule is N docs invocations, each with
   its own `promoted_to:`.

3. **Route in two passes.** First cluster by relatedness — same
   `area`, the same underlying change, or one only makes sense once
   the other lands. Then apply the matrix per Lead:

   | # | Related to another promoted Lead? | Passes `/spades:quick` § The gate? | Destination |
   |---|---|---|---|
   | 1 | Yes | not evaluated | The single Scope for its cluster, one acceptance criterion per Lead |
   | 2 | No | Yes, all ten | Its own Quick item |
   | 3 | No | No | Its own Scope; name the failing criterion |

   Row 1 short-circuits: relatedness wins, and the gate is consulted
   only for a Lead that ends up alone. The gate is
   `/spades:quick`'s ten criteria, walked from
   `${CLAUDE_PLUGIN_ROOT}/skills/quick/SKILL.md`; the scout's
   `size` ranks candidates and the gate decides. Two unrelated Leads
   in row 3 get two Scopes.

   Worked outcomes, given `l1`+`l2` related, `l3` small and isolated,
   `l4` large and unrelated, `l5` related to `l3`:

   | Promoted | Result |
   |---|---|
   | `l1, l2` | one Scope |
   | `l1, l2, l4` | one Scope for `l1`+`l2`, a second Scope for `l4` |
   | `l3, l4` | `l3` → Quick, `l4` → its own Scope |
   | `l3, l5` | one Scope — related, so the gate is never consulted |
   | `l3` alone | Quick |

4. **Propose the split, then confirm** via `AskUserQuestion`, with
   the gate verdict in one line for anything routed to Quick:

   > *Promote 3 leads — L-a and L-b look related, L-c stands alone.*
   > - **As proposed** — one Scope for L-a + L-b, one Quick for L-c.
   > - **One Scope for all three**
   > - **A Scope each**
   > - **A rule, not work** — each becomes its own entry in
   >   `ANTI-PATTERNS.md` / `PATTERNS.md`.

   The rule option is always offered because the matrix routes to
   work and a prohibition is not work. A single promoted Lead is
   still asked; Scope and Quick are both legitimate for one Lead.

5. **`--as` skips the question**, within two bounds: rule 2 still
   applies (`--as quick` on three Leads is three Quick items), and
   `--as quick` still walks the gate — a Lead that fails is reported
   with the failing criterion and left `open`.

6. **Invoke the destination**, passing the seed as its argument and
   letting it ask its own questions — the human is present because
   they typed `--promote`:

   | Destination | Invoke |
   |---|---|
   | Scope cluster | `/spades:scope` once per cluster |
   | Quick | `/spades:quick` once per Lead, in sequence |
   | Rule | `/spades:patterns` or `/spades:anti-patterns` once per Lead |

   The seed for a Scope: the Leads' *What I noticed* as the problem,
   *Why it might matter* as the justification, and one acceptance
   criterion per Lead. For a Quick item: that Lead's *What I'd do*.

7. **Record each destination as its ID is minted.** The ID comes
   from the skill that minted it. For each Lead in that destination:
   `status: promoted`, `promoted_to: <ID>` (a rule's `promoted_to:`
   names the doc), and with `backend: linear` close its `L-` issue
   with a link to the new Scope issue.

8. **A destination that aborts is scoped to itself.** Destinations
   already minted keep their `promoted` records; the Leads of the
   failed destination stay `open`. Report both halves. A Lead is
   recorded as promoted exactly when work exists for it.

### Worked examples

```
/spades:leads --promote L-lint-nested-yaml-7Kd2,L-lint-missing-fallback-3Hy9

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

```
/spades:leads --promote L-drop-unused-import-9Qc3,L-autoremove-index-join-7Kd2

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

```
/spades:leads --promote L-never-gate-on-reviewdecision-9Xa2 --as rule

○ Promoting 1 lead as a rule — invoking /spades:anti-patterns
  → add: never gate a merge on reviewDecision
✓ L-never-gate-on-reviewdecision-9Xa2 → promoted_to: ANTI-PATTERNS.md
```

## `--decline`

`/spades:leads --decline L-x "reason"` sets `status: declined` and
`declined_reason:`, and cancels the Linear issue with `backend:
linear`. The reason is required; declining stays as cheap as
promoting so the board keeps shrinking.

## Decay

A Lead goes `stale` when its `area` path no longer exists, or when
it has been `open` and untouched for six months. `--list` hides
stale Leads and counts them in the header. Nothing is deleted.

## Who may invoke this

Capture carries no trigger conditions; it fires because a phase
skill finished or because the human typed `/spades:leads`. The
callers are the human, `/spades:do` on completion, `/spades:learn`
on completion, and `/spades:review` on completion. Each phase skill
owns its own call, so capture behaves identically hand-driven and
under `/spades:loop`. The loop invokes `/spades:do` and, when there
is something to carry, `/spades:learn`; it declines `/spades:review`
as human-invoked, so `source: review` Leads appear only when a human
runs the panel.

The capture path invokes no SPADES skill: `do | learn | review →
leads → scout` is one-way and terminal. Only `--promote`, typed by a
human, invokes `/spades:scope`, `/spades:quick`, or the docs skills.
