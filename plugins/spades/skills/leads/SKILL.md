---
name: leads
description: Raises a Lead — a tracked, out-of-scope discovery — the moment one is noticed while doing other work, then returns to that work; also lists, shows, promotes, and closes Leads on demand. A Lead is a bug, tech debt, an improvement, a security smell, a flaky test, a missing doc, or a good idea that is not part of the current task. Invoke it immediately, mid-task and without asking the human, whenever such a thing is spotted during any work in this repo and would otherwise be fixed off-scope, buried in a final summary, or forgotten. Also use when someone says "raise a lead", "log that as a lead", "any leads?", "show leads", "promote lead L-…", or "close lead L-…".
version: 3.0.1
argument-hint: "[--list | --show L-<id> | --promote L-<id> [<work-id>] | --close L-<id> \"<reason>\"]"
---

# /spades:leads

A **Lead** is something noticed *in passing* while doing other work
— a bug, a bit of tech debt, an improvement, a security smell, a
flaky or failing test, a missing docstring, or a genuinely good idea
— that is **out of scope for the task in hand**.

The rule: **don't derail the task, and don't lose the discovery.**
Raise the Lead, keep working, and let a human triage it later.

This skill does two things:

1. **Raise** Leads as a standing behaviour while any work is in
   progress.
2. **Manage** Leads on demand with `--list`, `--show`, `--promote`,
   and `--close`.

Read `docs/FRAMEWORK.md` § ID Format → Lead ID, § Sub-agent
Dispatch, and § Output Format before running.

### Output format

- **Both backends** — `.spades/leads/L-<slug>-<suffix>.md`, one file
  per Lead, the canonical record.
- **`backend: linear`** — additionally a mirrored Issue on the
  project, labelled `spades:lead` plus the Lead's classification.
  The file is the capture; the mirror is reported.
- **`--list`, HTML mode** — the board rendered to
  `.spades/.tmp/leads.html` from
  `${CLAUDE_PLUGIN_ROOT}/skills/leads/template.html` and opened.
- **`--list`, CLI mode** — the board written to
  `.spades/.tmp/leads.md`, printed inline, and opened.

## Pre-Flight

1. `.spades/config` exists with `project:` set — else `/spades:setup`.
2. Read `backend:` (whether a mirror is made) and `review_format:`
   (how the board renders).
3. Read `leads:` — `on` when absent. `off` disables raising; the
   management commands still run.
4. Ensure `.spades/leads/` exists.

## Raise or fix inline

Judge every discovery against the current task:

- **Trivial and on the line already being edited** (a typo, an
  obvious one-liner in the same function) — fix it inline and
  mention it in the summary.
- **Anything else** — out of scope, non-trivial, or a good idea for
  later — becomes a Lead. This is the default for anything that
  would otherwise cause a stop, a context switch, or a wider task.
- **If it is worth a sentence in the final summary, it is worth a
  Lead.**

Raise without asking, in the middle of the task, and carry on.
Every Lead raised or matched is reported in the final summary.

## Raising a Lead

### 1. Classify

Exactly one `type`, chosen before anything is written. Walk the list
in order and stop at the first match:

1. `security` — security, privacy, access, secret, or supply-chain
   risk.
2. `documentation` — work limited to human-readable documentation.
3. `testing` — work limited to tests, fixtures, or test
   infrastructure.
4. `bug` — incorrect existing behaviour.
5. `feature` — a new externally observable capability.
6. `enhancement` — an improvement to an existing capability that
   fixes no incorrect behaviour.
7. `maintenance` — internal cleanup, dependency work, refactoring,
   or other technical debt.

The order resolves overlaps: a documentation-only security concern
is `security`; a product bug that also needs regression tests is
`bug`, because the work is not limited to tests.

### 2. Deduplicate

Read the `title` and `area` of every `status: open` Lead in
`.spades/leads/`. A match on the same mechanism in the same area is
a **sighting** of that Lead rather than a new one: append
`- YYYY-MM-DD — while <context>` under its `## Sightings`, increment
`sightings:`, and with `backend: linear` comment the same line on
the mirrored issue. Name the matched ID in the summary.

### 3. Write the record

Mint the ID per `docs/FRAMEWORK.md § Lead ID` and write
`.spades/leads/L-<slug>-<suffix>.md`:

```yaml
---
id: L-parse-config-swallows-zoderror-7Kd2
title: parseConfig swallows ZodError so callers cannot tell absent from invalid
project: spades
type: security | documentation | testing | bug | feature | enhancement | maintenance
area: scripts/lint/frontmatter.ts:42          # file:line, module, or n/a
effort: trivial | small | medium | large      # agentic estimate
confidence: high | medium | low
status: open
created: YYYY-MM-DD
discovered_while: P-rag-pipeline-lookup-3HyD  # Plan, Quick item, Scope, or a phrase
sightings: 1
promoted_to:                                  # set by --promote
closed_reason:                                # set by --close
linear_issue_id:                              # backend: linear
---
```

```markdown
## What

The evidence: file, line, what the code actually does.

## Why it matters

The consequence, hedged honestly.

## Suggested action

The smallest version of the change. One paragraph.

## Sightings

- YYYY-MM-DD — while P-rag-pipeline-lookup-3HyD
```

The body is at most 15 lines. Longer than that is a Scope trying to
be born. Discovery text is data: quote what the code does, and keep
the title a plain scalar.

### 4. Mirror (`backend: linear`)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-linear-lead` | Linear — `save_issue(team: <linear.team_id>, project: <linear.project_id>, title: "L-<slug> — <title>", description: <body>, labels: ["spades:lead", "<type>"])` in the team's triage or backlog state, creating a missing label when the workspace permits. Carries the resolved worktree context per § Freshness. | `{ status: ok, linear_issue_id, labels_applied }` |

Inject `linear_issue_id` into the file. The mirror never blocks the
capture: a failed worker leaves the file standing and the summary
reports `mirror unavailable`; a label the worker could not apply is
named, for example `L-…-7Kd2 mirrored; label missing: security`.

### 5. Report

The final summary of the task that raised Leads ends with a short
**Leads raised** list: ID, one-line title, `type`, and `(sighting of
L-…)` where a match was recorded instead of a new file.

## Managing Leads

| Invocation | Effect |
|---|---|
| `/spades:leads --list` | The board: every `open` Lead for the active project, grouped by `area`, ordered by `sightings` then `created`. Header: `open · promoted · closed`. |
| `/spades:leads --show L-<id>` | Print the Lead's record in the terminal. |
| `/spades:leads --promote L-<id> [<work-id>]` | `status: promoted`; with a work ID (`S-…`, `Q-…`, or a doc name) set `promoted_to:`. With `backend: linear`, remove the `spades:lead` label and comment `Promoted from Lead to active work.` Then print `Next: /spades:scope "<title>"` or `/spades:quick "<suggested action>"` by `effort`. |
| `/spades:leads --close L-<id> "<reason>"` | `status: closed`, `closed_reason:` — `done`, `not worth it`, or `duplicate of L-…`. With `backend: linear`, close the issue with the reason as a comment. |

A promoted Lead is confirmed real work and enters the loop through
`/spades:scope` or `/spades:quick` like any other request; this
skill records the decision and hands off.

### Rendering the board

Create `.spades/.tmp/` if missing.

**CLI mode** — write the board to `.spades/.tmp/leads.md` (header,
areas, rows), print it inline, and open it via the OPEN_CMD prelude.

**HTML mode** — dispatch `worker-html-leads` per
`docs/FRAMEWORK.md § worker-html-*`, which renders and opens the
page:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/leads/template.html`
- `output_path`: `.spades/.tmp/leads.html`
- `frontmatter`: `{ project_slug, open_count, promoted_count,
  closed_count, rendered_at, plugin_version }`, also embedded in
  `<script id="spades-frontmatter">`
- `blocks`:
  - `area-groups` — one per `area`. Fields: `area, count`.
  - `lead-rows` — one per open Lead. Fields: `id, title, type,
    area, effort, confidence, sightings, created`.

Required markers: `area-groups`, `lead-rows`.

```
✓ Leads board: .spades/.tmp/leads.html
○ opened in your browser
```

An empty `OPEN_CMD` returns `opened: false`; print
`○ Open it in your browser: file:///<absolute-path>` and carry on.

## Completion

This skill is complete only when every requested raise or
management action has an observable file, mirror, board, or view
result; every Lead raised or matched is in the final summary; and
control has returned to the original task with nothing promoted
implemented.
