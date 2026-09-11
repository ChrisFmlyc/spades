---
id: S-reliable-leads-workflow
title: "Reliable Leads capture and completion checks"
project: spades-framework
status: shipping
branch: fix/reliable-leads-workflow
base_commit: 3072a813e3b92e33c9464eed81e1f9782905ade0
type: bug
priority: this-cycle
origin: reactive
created: 2026-09-11
updated: 2026-09-11
---

# Reliable Leads capture and completion checks

## Statement of Intent

Discoveries made during work become durable Leads as they arise, and callers can verify that capture finished before advancing. Lead inventories explain recurring findings, lifecycle changes, publication, and mirror state across the project's worktrees.

## Acceptance Criteria

- [x] Existing Leads commands, classifications, identifiers, and field schemas remain compatible; optional `--list --all-worktrees` and `--sync L-<id>` add inventory and reconciliation capabilities.
- [x] An unresolved finding seen again produces one sighting per work context; repeated calls in that context reuse the recorded sighting.
- [x] Completion checks use actual worker results tied to the latest evaluation, persist those results, and read them back before advancement.
- [x] Capture and inventory expose local publication and mirror state; promotion and closure verify the resulting local and remote records and identify pending reconciliation.
- [x] An inventory requested across the process covers registered worktrees, deduplicates Lead identities, and identifies the authoritative source and pending publication.
- [x] Skill edits cover Leads and the relevant handoff portions of Evaluate, Ship, Loop, Learn, and Research, with corresponding shared-contract, version, and changelog updates.
- [x] Rewritten instructions describe intended behavior directly, pass the unslop rewrite audit, and pass the repository's applicable lints.

## Architectural Constraints

Follow ARCHITECTURE.md, PATTERNS.md, and ANTI-PATTERNS.md. Behavior remains in skill prose, shared rules remain in docs/FRAMEWORK.md, and canonical records remain local Markdown with YAML frontmatter. Preserve existing authorization and ownership boundaries when inspecting other worktrees or updating a backend.

## Dependencies

None beyond the repository's existing skills, templates, and lint tools. The Horizon Leads audit supplies the observed failure cases.

## Context

- **Upstream:** A cross-worktree audit found delayed capture, missing completion evidence, skipped repeat sightings, lifecycle drift, and records awaiting publication or mirrors.
- **Downstream:** Agents invoking Leads during work and callers completing Evaluate, Learn, Research, or shipment consume the revised instructions.
- **Related:** Existing Leads classification, local records, Linear mirrors, and evaluation audit markers remain the compatibility baseline.

## Out of Scope

- Rewriting unrelated skills or repairing Horizon records.
- Adding a runtime, dependencies, or a second backend.

## Risk / Unknowns

- Clear skill instructions and verification receipts improve execution evidence; the invoking harness still determines whether it follows the instructions.
- Concurrent worktree copies need explicit source ownership so an inventory does not overwrite another task's records.
- Mirror permissions can leave successful local capture awaiting a remote update; the current state must remain distinguishable from historical failures.

## Delivery Preference

Mostly AI-delivered. The user explicitly requested implementation of the targeted skill rewrites and the unslop rewrite flow, then authorized committing, pushing, opening and merging the PR after completion, followed by repo:sync on main in the SPADES repository.

## Audit Trail

- 2026-09-11: Scope recorded from the user's explicit instruction to update ../spades for Leads efficiencies, rewrite the necessary skills as green-field prose, use unslop rewrite, and keep the changes targeted. This records that implementation authorization; it does not claim a separate approval conversation occurred.
- 2026-09-11: Canonical Scope written by worker-file-scope using subagent-dispatch; backend local, review format cli.
- 2026-09-11: Plan drafted: P-reliable-leads-workflow-4Y6N.
- 2026-09-11: The coordinator assessed all six Plan approval checks as passing and proposed ai delivery. Automatic approval review rejected recording the Plan as approved from the existing implementation request, stating that it did not authorize this exact workflow transition. The approval record awaits an explicit human decision; delivery has not started.
- 2026-09-11: Chris explicitly answered the Plan approval question: “Approve AI delivery”. Plan P-reliable-leads-workflow-4Y6N is approved with delivery: ai. This decision resolves the previously pending approval; Scope status remains planning until transfer to the delivery worktree.
- 2026-09-11: Scope worktree established. Branch: fix/reliable-leads-workflow. Base: 3072a813e3b92e33c9464eed81e1f9782905ade0.
- 2026-09-11: P-reliable-leads-workflow-4Y6N delivery complete. AI verification proposes PASS; human evaluation confirmation pending.
- 2026-09-11: Scope evaluation proposes PASS. The coordinator reports all seven acceptance criteria verified, including compatibility, sighting reuse, completion receipts, lifecycle reconciliation, worktree inventory, targeted edits, and prose/lint checks. Acceptance checkboxes record those results.
- 2026-09-11: Chris explicitly instructed: “when complete commit, push, merge pr etc, then run repo:sync in the spades repo on main”. This authorizes shipment after completion checks and supersedes the earlier review-only delivery boundary. The Scope remains evaluating while shipment proceeds; no separate Confirm PASS message is claimed.
- 2026-09-11: Evaluation PASS and Leads completion verified. Publishing the approved Scope branch through GitHub as requested.
