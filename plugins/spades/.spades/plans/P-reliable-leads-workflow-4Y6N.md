---
id: P-reliable-leads-workflow-4Y6N
id_suffix: 4Y6N
scope: S-reliable-leads-workflow
title: "Reliable Leads capture and completion checks"
depends_on: []
status: shipping
delivery: ai
evaluation: ai
deliverable_type: code
created: 2026-09-11
updated: 2026-09-11
---

# Reliable Leads capture and completion checks

## Technical Approach

Rewrite Leads and the shared Leads handoff contract as direct instructions for capture, reconciliation, and verified completion. Update the relevant handoff sections in Evaluate, Ship, Loop, Learn, and Research to use that contract, retaining existing records and commands. Apply the unslop rewrite workflow and the repository's existing lints, then record scenario evidence for each acceptance criterion.

## Risks & Assumptions

- Instructions depend on the invoking harness; worker receipts and record read-back provide evidence of execution.
- Registered worktrees can contain concurrent copies of a Lead. Inventory identifies the authoritative source and publication state while preserving each task's ownership.
- Successful local capture can await a mirror update. Current reconciliation state must be distinguishable from historical failures.
- Existing flags, identifiers, classifications, and field schemas remain compatible. Optional `--list --all-worktrees` and `--sync L-<id>` extend the existing command surface.
- The approach follows ARCHITECTURE.md, PATTERNS.md, and ANTI-PATTERNS.md: skill prose implements behavior and docs/FRAMEWORK.md owns the shared contract. No architecture conflict is identified.
- The user's implementation request supplies the intended scope. Approval and delivery routing remain separate recorded steps.

## Tasks

### Task 1: Inspect the current contract and audit evidence

- **Posture:** discover-first
- **Effort:** brief (<1h)
- **Depends on:** none
- **Description:** Identify the exact caller boundaries, compatibility requirements, and observed workflow gaps.
- **Approach:** Read Leads, its completion callers, the shared handoff contract, architecture constraints, and the supplied audit. Map delayed capture, recurring findings, lifecycle drift, missing receipts, pending mirrors, and unpublished records to the Scope's acceptance criteria. The coordinator has completed this inspection; preserve its findings as delivery evidence.
- **Tests:** Confirm each proposed edit belongs to the Leads workflow and that public artifacts use generic scenarios without external project details.

### Task 2: Rewrite the Leads workflow and its callers

- **Posture:** iterate
- **Effort:** moderate (1–4h)
- **Depends on:** 1
- **Description:** Produce a coherent workflow for immediate capture, contextual repeat sightings, reconciliation, inventory, and verified completion.
- **Approach:** Rewrite Leads and the shared Leads handoff contract as green-field prose. Update only the relevant sections of Evaluate, Ship, Loop, Learn, and Research. Make repeat sightings idempotent within one work context; identify authoritative records across registered worktrees through read-only inventory; report pending mirrors and carry-forward; verify lifecycle transitions; and require a checked worker receipt with marker read-back for the current evaluation cycle. Preserve existing commands and schemas while adding the two scoped optional commands. Keep shared behavior in one contract.
- **Tests:** Walk through immediate capture, a recurring unresolved finding, duplicate calls in one context, conflicting worktree copies, pending publication, failed then successful mirroring, promotion and closure, and a resumed evaluation with an old or missing marker. Confirm expected outcomes and ownership boundaries from the resulting prose.

### Task 3: Validate the prose and prepare the release

- **Posture:** straight-through — the repository already defines the lint and release procedures.
- **Effort:** moderate (1–4h)
- **Depends on:** 2
- **Description:** Validate the targeted rewrite and record reviewable release and evaluation evidence.
- **Approach:** Apply unslop's diagnosis and reconstruction flow. Record the deliberate semantic changes from original to draft separately from the draft-to-final style pass, which preserves the draft's meaning. Run existing applicable lints and document adversarial scenario walkthroughs in the evaluation. Bump the plugin from 6.1.3 to 6.2.0, Leads from 3.0.4 to 3.1.0, and the five changed caller skills by a patch version; update the changelog. Keep AGENTS.md, runtime scripts, dependencies, and the test framework unchanged.
- **Tests:** Existing repository lints pass; unslop checks pass; the final diff contains only scoped skill, contract, release, and audit artifacts; and every acceptance criterion has an evaluation result with supporting evidence.

## Delivery Sequence

1. Confirm Task 1's completed inspection and record its findings.
2. Execute Task 2 against the agreed contract and compatibility boundaries.
3. Execute Task 3 after the rewrite is stable, then evaluate the complete change.

## Testing & Verification

Use the repository's existing lints and the installed unslop rewrite workflow. Record a scenario table in the evaluation covering first capture, recurring unresolved findings, repeated calls in the same context, all-worktree inventory, pending publication, mirror recovery, promotion and closure, worker failure, and current-cycle completion evidence. The evaluation distinguishes intended semantic changes from style-only reconstruction and checks all Scope acceptance criteria. The resulting code deliverable is prepared for review; automatic merge is outside the Scope.

## Audit Trail

- 2026-09-11: Draft Plan written by worker-file-plan using subagent dispatch, from S-reliable-leads-workflow and the coordinator's completed inspection. Delivery and evaluation remain undecided pending their recorded gates.

- 2026-09-11: Approval checklist reviewed by the coordinator: alignment PASS (pure prose and existing contracts); completeness PASS (all seven Scope acceptance criteria and failure paths); feasibility PASS (existing tooling, no dependencies); risk PASS (ownership and privacy preserved, harness limits stated); granularity PASS (three sequential tasks); deliverable fit PASS (one coherent code PR).
- 2026-09-11: Approved by Chris — routing ai. Chris explicitly answered the Plan approval question with “Approve AI delivery”. Prepare reviewable changes; automatic merge remains outside the Scope. Evaluation remains undecided.
- 2026-09-11: Deliver phase started — routing: ai, branch: fix/reliable-leads-workflow. Approved records transferred and verified from documentation worktree.
- 2026-09-11: Delivery verification — five repository lint suites passed; new Plan field warning resolved and local frontmatter lint rerun without warnings. Unslop rewrite retained 113/113 draft constraints with zero banned phrases or structural flags; technical-document readability and soft silhouette signals reviewed.
- 2026-09-11: Leads receipt — source: delivery; result: L-maintainer-docs-drift-from-framework-GuUE (documentation); context: P-reliable-leads-workflow-4Y6N/delivery-1; record: .spades/leads/L-maintainer-docs-drift-from-framework-GuUE.md in fix/reliable-leads-workflow. Dedicated capture and replay workers verified one observation, sightings 1 -> 1; replay made no writes. Plan field correction is on-scope; expected lint and prose checks add no discovery. Publication: included in the next delivery commit; mirror: not applicable (local backend).
- 2026-09-11: Deliver phase complete — routing: ai. Tasks completed: 3. Commits: 04448dcb2cff835fb7a17640a94b27605da3f79e. Authorised Lead and evaluation report inclusion verified in that commit.
- 2026-09-11: Evaluation started — routing: ai. Verification methods are recorded in the approved Plan and .spades/evaluations/P-reliable-leads-workflow-4Y6N-2026-09-11-report.md. AI checks complete; proposed PASS awaits human confirmation.

- 2026-09-11: Evaluation — verdict: PASS; routing: ai. All seven Scope acceptance criteria pass as recorded in .spades/evaluations/P-reliable-leads-workflow-4Y6N-2026-09-11-report.md. Five repository lint suites pass; unslop preserves 113/113 draft constraints with zero banned-phrase or structural findings. Dedicated capture and replay verified one contextual sighting (1 -> 1) with no replay writes. Completion, lifecycle, publication, and inventory checks use documented contract walkthroughs; live Linear mutation was not exercised with this project's local backend.
- 2026-09-11: Human sign-off to ship after completed checks — Chris instructed: “when complete commit, push, merge pr etc, then run repo:sync in the spades repo on main”. This later instruction authorizes shipment and merge of the verified implementation, extending the earlier review-only boundary. It is recorded as the actual authorization evidence; no separate interactive Confirm PASS answer is claimed.
- 2026-09-11: Shipment routing — use the GitHub PR driver for this run under the user's explicit push/merge request; this overrides the absent scm field's local-git default without changing project configuration.
- 2026-09-11: Leads receipt — source: evaluate; outcome: captured (already recorded); context: P-reliable-leads-workflow-4Y6N/delivery-1; revision: 04448dcb2cff835fb7a17640a94b27605da3f79e with authorised evaluation records; worktree: fix/reliable-leads-workflow. L-maintainer-docs-drift-from-framework-GuUE at .spades/leads/L-maintainer-docs-drift-from-framework-GuUE.md is open with one sighting, byte-identical to the committed record. Dedicated worker and coordinator read-back verified the context, disposition and count. Plan field correction and expected verification outputs are on-scope; shipment routing is a task decision. Pending captures: none; publication: committed, included in this Scope PR; mirror: not applicable (local backend).
- 2026-09-11: Leads checked — source: evaluate; result: L-maintainer-docs-drift-from-framework-GuUE.
- 2026-09-11: Ship phase started — deliverable_type: code. GitHub PR and squash-merge authorised by Chris after completed checks.
- 2026-09-11: PR opened: https://github.com/ChrisFmlyc/spades/pull/101.
- 2026-09-11: CI at ffff206 exposed the existing Plan schema omission of shipping. Shipment completion requires the documented phase, so Task 3 includes aligning its enum and adding the good-shipping-plan regression fixture under the user's instruction to finish and merge. This is a CI-only compatibility change with no new dependency or skill.
- 2026-09-11: Evaluation — verdict: PASS. Shipment follow-up verified: original validator rejects good-shipping-plan.md; updated validator accepts it; all five lint suites pass. Existing Leads workflow and same-context replay evidence remain valid. User's instruction to finish, push, merge and sync remains the shipment authority.
- 2026-09-11: Leads receipt — source: evaluate; outcome: captured (already recorded). Worker checked the latest shipment-follow-up PASS at ffff2060e1024cd2f131c6d4b19e0f43e5f22676 plus authorised CI changes in fix/reliable-leads-workflow. Context P-reliable-leads-workflow-4Y6N/delivery-1 matches L-maintainer-docs-drift-from-framework-GuUE at .spades/leads/L-maintainer-docs-drift-from-framework-GuUE.md; open, sightings 1 -> 1, no writes. Shipping enum omission is a repaired on-scope blocker; validation outputs add no discovery. Lead content remains committed in 04448dc, included in this PR; mirror not applicable; pending captures none. Coordinator read-back verified.
- 2026-09-11: Leads checked — source: evaluate; result: L-maintainer-docs-drift-from-framework-GuUE.
- 2026-09-11: Evaluation — verdict: PASS. Review follow-up verified on 5c22313b: F1 already fixed and answered; F2 document promotion lifecycle, F3 code-only commit checks and F4 pending publication reporting are integrated. Overlapping Ship wording combined and inspected. All five lints pass; unslop preserves 127/127 constraints with zero banned phrases/structure flags. Live inventory across 15 worktrees deduplicates five identical Lead copies to one identity and observation. Existing user authorisation to finish and merge applies.
- 2026-09-11: Leads receipt — source: evaluate; outcome: captured (already recorded). Dedicated worker verified review-follow-up evidence at 5c22313b8375cbd8e9b8aae017cb79e0ed4edc4a plus authorised evaluation updates in fix/reliable-leads-workflow. Context P-reliable-leads-workflow-4Y6N/delivery-1 matches open L-maintainer-docs-drift-from-framework-GuUE at .spades/leads/L-maintainer-docs-drift-from-framework-GuUE.md; sightings 1 -> 1, unchanged from committed 04448dc and published PR head7600f22. Five inherited copies represent one identity and observation. Repaired review findings and validation outputs are on-scope; pending captures none. Later review fixes and evaluation updates await this push; mirror not applicable. Coordinator read-back verified.
- 2026-09-11: Leads checked — source: evaluate; result: L-maintainer-docs-drift-from-framework-GuUE.
