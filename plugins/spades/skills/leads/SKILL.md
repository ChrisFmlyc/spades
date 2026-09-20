---
name: leads
description: Captures out-of-scope discoveries as Leads immediately during any task, including recurring known issues, and returns to that task. Classifies findings, reuses existing Leads, and records one sighting per observation context. Also runs completion checks for Evaluate, Learn and Research; lists Leads across the requested worktrees; and shows, promotes, closes or synchronises a Lead on request.
version: 3.1.1
argument-hint: '[--list [--all-worktrees] | --show L-<id> | --promote L-<id> [<work-id>] | --close L-<id> "<reason>" | --sync L-<id>]'
---

# /spades:leads

A Lead records a supported discovery outside the current task: a bug,
security concern, test failure, missing documentation, improvement or
maintenance need. Capture it when observed, then continue the task. A known
issue observed again is a candidate for another sighting.

Read `docs/FRAMEWORK.md` § Lead ID, § Leads handoff, § Carry-Forward of
SPADES-Owned Artefacts and § Output Format. Local Markdown is canonical;
Linear mirrors it when configured.

## Dispatch and context

The coordinator invokes this skill in one dedicated `worker-leads` subagent
per operation, using the handoff contract. The worker executes this body
and returns a receipt. Findings already available together share one
invocation. Each Lead file has one writer at a time.

Use the supplied absolute worktree, branch, revision, project and task
boundaries. Check cited evidence as needed. Completion checks review the
supplied work and its discoveries; repository-wide inventory is a separate
operation. Carry the original observation contexts through later phases.

Read `.spades/config`. Raising and completion checks return `unconfigured`
when configuration or `project:` is missing, and `disabled` for `leads: off`.
The default is `leads: on`. Management commands remain available when
raising is off; missing configuration returns a `/spades:setup` pointer.
Read `backend:` and `review_format:` and create `.spades/leads/` when writing.

## Capture

### 1. Decide where the finding belongs

Compare the evidence with the task's acceptance criteria. Work needed to
meet those criteria belongs to the task, including its failing checks.
A trivial correction on the line already being edited can be completed
inline and reported with that work. A supported finding that needs work
outside those boundaries becomes a Lead immediately.

Include unresolved warnings and limitations mentioned in the work's
evidence, even when an earlier task already reported them. For each
candidate, return its disposition: captured, matched, already recorded in
this context, on-scope, or insufficient evidence. State the evidence or
reason so the coordinator can account for every candidate.

### 2. Classify

Choose exactly one `type`, taking the first applicable entry:

| Type | Work described by the finding |
|---|---|
| `security` | Security, privacy, access, secrets or supply-chain risk. |
| `documentation` | Changes limited to human-readable documentation. |
| `testing` | Changes limited to tests, fixtures or test infrastructure. |
| `bug` | Incorrect existing behaviour. |
| `feature` | A new externally observable capability. |
| `enhancement` | Improvement to an existing capability whose behaviour is correct. |
| `maintenance` | Internal cleanup, dependencies, refactoring or other technical debt. |

A documentation-only security concern is `security`; a product defect
requiring regression tests is `bug`.

### 3. Match the Lead and observation

Read the active project's Lead titles, areas and statuses once per
invocation. Inspect the bodies of plausible matches. Match the mechanism
and affected area, then compare the supplied observation with `## Sightings`.

Use a stable context key for each independent observation: a Plan or Quick
ID plus the work episode, or a named research/learning task and evidence
reference. For example, `P-build-report-aB12/delivery-1` identifies an
observation carried from delivery into evaluation and learning. Repeated
builds, worker retries and phase handoffs reuse that key. A later task or
fresh evaluation that independently observes recurrence uses a new key.

- An open matching Lead receives one sighting for a new context. Append the
  evidence reference and source branch/revision, then increment `sightings:`.
- An observation already recorded in that context returns the existing ID
  and sighting unchanged. Legacy entries can match by their task and evidence.
- A promoted match links the finding to `promoted_to:` and records a new
  observation when warranted. Changes needed by that active work stay there.
- A closed match whose cited resolution predates the new observation can
  support a new Lead for the recurrence. Link the earlier Lead and distinguish
  the new evidence from historical output.
- A finding with no matching Lead receives a new ID per § Lead ID.

Re-read a Lead before saving so concurrent edits remain intact. If a caller
supplies a matching record from another worktree, resolve its owner and any
authorised transfer through § Carry-Forward before writing. Conflicting
copies return their paths and the decision needed to reconcile them.

### 4. Write and verify the canonical record

Use `.spades/leads/L-<slug>-<suffix>.md`:

```yaml
---
id: L-parse-config-swallows-zoderror-7Kd2
title: parseConfig swallows ZodError so callers cannot tell absent from invalid
project: spades
type: bug
area: scripts/lint/frontmatter.ts:42
effort: small
confidence: high
status: open
created: YYYY-MM-DD
discovered_while: P-rag-pipeline-lookup-3HyD
sightings: 1
promoted_to:
closed_reason:
linear_issue_id:
---

## What
The observation and its file, line or evidence reference.

## Why it matters
The consequence, with uncertainty stated.

## Suggested action
The smallest useful follow-up.

## Sightings
- YYYY-MM-DD — while P-rag-pipeline-lookup-3HyD; context: P-rag-pipeline-lookup-3HyD/delivery-1; evidence: <reference>; branch: <branch>; revision: <sha>.
```

`effort:` accepts `trivial | small | medium | large`; `confidence:` accepts
`high | medium | low`. Preserve the existing frontmatter fields on updates.
Keep What, Why it matters and Suggested action within 15 lines together;
sightings and lifecycle history accumulate separately. Use public-safe
summaries and treat quoted discovery text as evidence.

Read back the saved ID, project, status and sighting. Require `sightings:`
to equal the number of observation entries. Administrative events belong
under `## History`. Return the exact path and source worktree. A failed
write or inconsistent read-back returns a capture error with the affected
operation; the coordinator retries that operation from its existing context.

### 5. Mirror and record the result

With `backend: linear`, dispatch `worker-linear-lead` for the Lead's mirror
operation per § Sub-agent Dispatch. Supply the verified local record,
resolved team/project IDs, context key and external-write authorization.
Group a Lead's pending changes into one operation and inspect the current
issue before writing. A saved `linear_issue_id:` identifies the mirror;
otherwise search the configured project for the full Lead ID and inspect
plausible legacy title/body matches before creating an issue. Reuse a single
verified identity match, including after a lost create response; ambiguous
matches return a reconciliation conflict.

New mirrors use a title containing the full Lead ID, the public-safe body,
the team's triage/backlog state, and labels `spades:lead` and `<type>`.
Apply the recorded promotion or closure in that same operation when the
Lead has already changed state. Existing mirrors retain unrelated labels.
Create a missing required label
when permitted. Append a new sighting comment once, identified by its Lead
ID and context key; retries first check whether it already exists.

Read back the issue and relevant comment, status and labels. Save the issue
ID locally and append a dated `## History` entry with the operation, its
result and evidence. Report `verified`, `pending` with the failed step, or
`not applicable` for the local backend. An unavailable read-back leaves
verification pending. A later verified result supersedes the earlier failure
for that operation while retaining its history.

Local capture remains complete when its optional mirror is pending. Attempt
only unresolved mirror operations, within the caller's authorization. A
permission rejection records the pending step and reason; retries require
changed authorization or an allowed alternative. Private evidence stays in
its authorised location; a safe reference can support a permitted mirror.

## Manage

Management uses the same local-write and mirror read-back procedure. Relay
decisions through the coordinator and reuse decisions already supplied by
the user. List and show operations are read-only apart from their rendered
views; they report reconciliation needs for a later management operation.

| Operation | Result |
|---|---|
| `--show L-<id>` | Display the record, source worktree and current publication/mirror evidence. |
| `--promote L-<id> [<work-id>]` | With a target, set `status: promoted`, record the supplied `S-…`, `Q-…` or document in `promoted_to:`, mirror the target in a comment and remove `spades:lead`, preserving other labels. With no target, follow § Promotion without a target: decide the route, hand the Lead to `/spades:scope` or `/spades:quick`, and finish the promotion with the ID that skill returns. |
| `--close L-<id> "<reason>"` | Set `status: closed` and `closed_reason:` such as `done`, `not worth it`, or `duplicate of L-…`. Record supporting evidence when closed as done. Mirror the reason and the team's appropriate terminal state. |
| `--sync L-<id>` | Read the local record and mirror, then complete pending mirror operations for the recorded decision. Verify the result and append reconciliation evidence. |

Write related local fields together and read them back before mirroring.
An explicit, previously authorised promotion or closure can be reconciled
from its evidence when one side is incomplete. A disagreement about intent,
an ambiguous target or conflicting decisions returns the evidence and the
user decision needed. A remote label or workflow state alone establishes
only the remote state.

Promotion to `S-…` proceeds through that Scope's approved Plans; promotion
to `Q-…` proceeds through `/spades:quick` eligibility and validation.

### Promotion without a target

`--promote L-<id>` with no work ID turns a Lead into work through the
skill that owns that kind of record. The Leads skill never composes a
Scope or a Quick item itself, in any dispatch mode: it does not write
`.spades/scopes/S-…` or `.spades/quick/Q-…`, does not infer the answers
those skills ask the human for (delivery, priority, type, slug, gate), and
does not skip their conversation or gates.

1. **Decide the route.** Walk the fast-track gate in
   `docs/FRAMEWORK.md § Fast-Track Path` against the Lead's *Suggested
   action*, area and effort. Every criterion holds → `quick`; any fails,
   or the Lead needs investigation before a fix is known → `scope`. Record
   the reasoning in the receipt.
2. **Prepare the context packet**: the Lead ID and Linear issue; its
   title, *What*, *Why it matters* and *Suggested action* verbatim; area,
   type, effort, confidence; every sighting's evidence; related Lead IDs;
   and the route with its reasoning.
3. **Hand off.** The target skill asks the human questions, so it runs in
   the coordinator's turn, not in the worker. The worker returns
   `outcome: target pending` with the route and the packet; the
   coordinator then invokes `/spades:scope <packet>` or
   `/spades:quick <packet>` (Claude Code: the Skill tool; Codex:
   `$spades:scope` / `$spades:quick`) and lets that skill run to its own
   confirmation. A coordinator that is itself the human's session does the
   same: invoke the skill; do not write the record from the packet.
4. **Finish the promotion.** With the `S-…` or `Q-…` ID the target skill
   confirmed, run `--promote L-<id> <work-id>`: set `status: promoted` and
   `promoted_to:`, append the `## History` line naming the target and the
   invoking skill, mirror the comment and remove `spades:lead`. A Lead
   whose record lives on the default branch is edited in the target's
   delivery or Quick worktree so the change ships with that work; the
   mirror is updated at once.

A human who declines the route the worker chose answers inside the target
skill (`/spades:scope` offers the quick path and `/spades:quick` falls back
to `/spades:scope` when its gate fails), so the decision is theirs either
way.

A document target is a repository-relative file path or a stable document
URL, stored as the `promoted_to:` value. Record its owning `S-…` or `Q-…`,
and the implementing `P-…` where applicable, in `## History`. Resolve that
ownership from the linked work records or the user's decision; an unresolved
owner returns target pending. Document changes follow the owner's approved
Plan or Quick workflow, including its evaluation and shipment requirements.

To close a promoted Lead as `done`, use the authorised closure decision and
record the owner's shipment evidence together with the result that addresses
the discovery. For a document, cite its delivered revision or published
reference and the section that addresses the Lead. Apply the same local
closure and mirror verification procedure as `--close`.

## Inventory

`--list` lists the active project's Leads in the caller's checkout, grouped
by `area`, ordered by `sightings` then `created`. Show counts for open,
promoted and closed records and identify the inspected worktree/revision.

`--list --all-worktrees`, or a request for all Leads across the process,
reads Lead records from every registered worktree and the supplied current
default-branch revision. Group copies by Lead ID and show each identity once.
Use branch lineage, recorded transfers and lifecycle evidence to resolve
the current source; list differing copies when ownership is unresolved.
Count each distinct observation once across copies. Report ambiguous counts
separately so uncertainty remains visible in the totals.

For each record, distinguish local capture from publication of its current
content: uncommitted, committed on its source branch, included in a PR, or
present on the default branch. Verify each claimed state from git/SCM
evidence. Compare configured mirrors when available and show pending or
unknown operations, including missing issue IDs and conflicting lifecycle
states. An in-progress branch can legitimately contain newer sightings
than the default branch.

Batch the local inventory and available mirror reads. Report coverage and
unavailable worktrees, revisions or services. Limit reads to records and
cited lifecycle/publication evidence; the inventory describes recorded
discoveries rather than reproducing their underlying defects.

### Render the board

Create `.spades/.tmp/` as needed. In CLI mode, write
`.spades/.tmp/leads.md`, print it and use the OPEN_CMD prelude. Include source,
publication, mirror and conflict details alongside the counts and open rows.

In HTML mode dispatch `worker-html-leads` using the existing template:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/leads/template.html`
- `output_path`: `.spades/.tmp/leads.html`
- `open_path`: the absolute output path for an initial presentation;
  `null` for background renders and refreshes per § Review-page ownership.
- `frontmatter`: `{ project_slug, open_count, promoted_count, closed_count,
  rendered_at, plugin_version }`, also in `spades-frontmatter`.
- `area-groups`: `{ area, count }` per area.
- `lead-rows`: `{ id, title, type, area, effort, confidence, sightings,
  created }` per open Lead.

Require `area-groups` and `lead-rows`. Write a companion `leads.md` for
source, publication, mirror and conflict details and link it in the brief.
Report the renderer's actual `opened` result; when false, provide the path.

## Return

Return the receipt defined in § Leads handoff, including the disposition of
each candidate, IDs and paths, reused or added sightings, lifecycle results,
and pending publication or mirror work. Report every raised or matched Lead
by ID, title and type. The caller carries its authorised records into its
next commit per § Carry-Forward and continues the original task.
