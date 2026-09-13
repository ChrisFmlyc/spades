---
id: P-projectlead-assignment-hX8p
id_suffix: hX8p
scope: S-projectlead-assignment
title: "Assign and confirm project leads"
depends_on: []
status: delivering
delivery: ai
evaluation: undecided
deliverable_type: code
created: 2026-09-13
updated: 2026-09-13
---

# Assign and confirm project leads

## Technical Approach

Add a Markdown `projectlead` skill backed by the framework's local Project record and Linear driver. Extend Project metadata with optional `lead` (the supplied identity locally, confirmed email in Linear mode) and `linear_lead_id` (the resolved Linear user ID), and reuse the Project rendering surface. Newproject invokes the helper with the newly created project's explicit identity after creation and backend binding, including during Setup.

## Risks & Assumptions

- Existing projects without lead fields remain valid; project owners and discovery Leads retain their current meaning.
- Linear tool names vary by harness. The available MCP exposes list_users with query/cursor, get_user, get_project, and save_project with id and lead; the driver specifies these operations and requires capability checks before writes.
- Confirmation belongs before changing the Linear lead. Missing and ambiguous matches need a human choice, and partial writes need evidence and a retry path.
- Newproject can leave a different project active. Explicit target context prevents assigning the wrong project and preserves Setup's return path.
- Verification exercises the Markdown instructions through isolated scenarios and existing schema fixtures. Production project assignments are outside this implementation task; connected MCP reads may corroborate lookup behavior without mutating a real project.

## Tasks

### Task 1: Define the Project lead contract and schema
- **Posture:** discover-first
- **Effort:** moderate
- **Depends on:** none
- **Description:** Add backward-compatible Project lead metadata and backend operations.
- **Approach:** Read the existing schema and driver contracts; define identity lookup, confirmed assignment, persistence and partial-failure behavior in FRAMEWORK.md. Extend the CI validator's existing Project schema and fixtures for the optional fields.
- **Tests:** Existing Project fixtures remain valid; optional lead fields round-trip; invalid field types fail the existing validator.

### Task 2: Add the projectlead skill
- **Posture:** discover-first
- **Effort:** moderate
- **Depends on:** Task 1
- **Description:** Implement the direct invocation and target-aware helper flow.
- **Approach:** Require setup and an existing local Project, preserve explicit caller context, accept name/email arguments, and ask only for missing identity. Local mode records the supplied identity; Linear mode paginates lookup, disambiguates, confirms name/email, writes only the resolved target's lead, verifies and persists. Define cancellation and failure recovery; use existing worktree and rendering contracts.
- **Tests:** Walk direct/prompted local and Linear cases, missing prerequisites, zero/multiple matches, cancellation, already-assigned identity, and partial failures against the actual skill instructions.

### Task 3: Integrate Newproject and Project rendering
- **Posture:** discover-first
- **Effort:** moderate
- **Depends on:** Tasks 1, 2
- **Description:** Offer optional lead assignment after project creation and display the canonical lead in Project review output.
- **Approach:** Update Newproject's handoff with the explicit new target, preserve active-project choice, and delay bootstrap return until the optional lead flow finishes. Update its template and rendering payload, with absent lead fields supported; refresh using the established review-page rules.
- **Tests:** Yes/no/cancel cases, another project remaining active, failed Linear creation, Setup bootstrap, and rendered Project pages with and without a lead.

### Task 4: Update discovery and release metadata
- **Posture:** straight-through — existing skill listings and release files establish the format.
- **Effort:** brief
- **Depends on:** Tasks 1, 2, 3
- **Description:** Make the skill discoverable and publish a coherent minor release.
- **Approach:** Update skill inventories, necessary backend extension guidance and documentation, initialize projectlead at 1.0.0, bump affected components according to their changes, and synchronize plugin version 6.3.0 at all four release locations. Preserve unaffected historical records.
- **Tests:** Run the release gate, skill inventory checks and all five existing lints.

### Task 5: Verify acceptance and prepare shipment
- **Posture:** iterate
- **Effort:** moderate
- **Depends on:** Tasks 1, 2, 3, 4
- **Description:** Verify every Scope criterion and correct inconsistencies before PR publication.
- **Approach:** Use isolated scenario evaluation of the actual Markdown workflows with controlled user/MCP outcomes, test the real validator and rendered HTML, record evidence and limits, and complete the required leads handoff. Keep all changes in one coherent delivery commit where cross-file contract changes depend on each other.
- **Tests:** Criteria-to-evidence table covers all seven Scope criteria; no success is inferred from lints alone. All five lints, targeted schema tests, template checks and scenario checks pass.

## Delivery Sequence

1. Task 1 defines the shared fields and operations.
2. Tasks 2 and 3 implement the skill and its caller/rendering with separate file ownership after the contract is settled.
3. Task 4 updates documentation and release metadata.
4. Task 5 verifies the combined behavior before Evaluate and shipment.

## Testing & Verification

Use the existing CI-only Node validator and planted fixtures for actual schema behavior. Render the existing Project template with absent and populated lead values and inspect escaped output and placeholder completion. Run isolated agent scenarios against the actual skill and Newproject instructions, using controlled Linear responses to exercise matching, confirmation, target selection, mutation ordering, cancellation and recovery. Record scenario decisions and tool intent without writing to a production Linear project. All acceptance rows route to AI because the deliverable is the Markdown instruction and its supporting schema/template, which can be inspected and exercised locally; report live integration limits explicitly.

## Audit Trail

- 2026-09-13: Plan drafted by AI (/spades:loop). Scope summary, title, dependency-free filename, five-task breakdown and deliverable_type code confirmed by AI; no prior learnings matched. GitHub SCM recorded from the requested loop and existing repository publishing workflow.
- 2026-09-13: Approved by AI (/spades:loop) — routing: ai. Notes: 6/6 checks pass; optional fields preserve existing projects; controlled Linear scenarios verify instructions without production mutations. Dispatch: subagent-dispatch.
- 2026-09-13: Deliver phase started — routing: ai, branch: feat/projectlead-assignment. Description skipped by AI (/spades:loop).
