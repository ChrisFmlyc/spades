---
id: P-spades-v2-rework-2v0R
id_suffix: 2v0R
scope: S-spades-v2-rework
title: "SPADES v2.0 implementation"
depends_on: []
status: evaluating
delivery: ai
deliverable_type: code
created: 2026-05-29
updated: 2026-05-29
---

# SPADES v2.0 implementation

## Technical Approach

Rewrite the framework as a pure-Markdown 15-skill plugin under
`plugins/spades/`. Replace the `init` skill with a re-runnable `setup`.
Add `newproject`, `do`, `ship`. Re-shape `scope` and `plan` for the
new ID format. Replace the auto-probe Mode Resolver with explicit
`backend:` selection. Embed every template into the skill that
produces it; delete the standalone `templates/` and `fragments/`
directories.

## Risks & Assumptions

- Assumption: Claude Code's plugin loader honours arbitrary skill
  names — confirmed by the v1 marketplace plugin already running.
- Risk: skill-to-skill cross-references go stale during the rewrite.
  Mitigation: the dogfood Scope above tracks completion criteria, and
  the lint catches malformed frontmatter.

## Tasks

### Task 1: Reshape the storage contract
- **Posture:** test-first (schema validators are the tests)
- **Effort:** moderate
- **Depends on:** none
- **Description:** Define the v2 frontmatter schemas for Project,
  Scope, Plan, Learning. Update `frontmatter.py`. Replace fixtures.
- **Tests:** `lint-local-frontmatter.sh` self-test fixtures.

### Task 2: Author the four new/replaced skills
- **Posture:** test-first
- **Effort:** significant
- **Depends on:** Task 1
- **Description:** `setup`, `newproject`, `do`, `ship`. Each embeds
  its own templates inline.
- **Tests:** `lint-skill-frontmatter.sh` ensures each carries valid
  frontmatter.

### Task 3: Update the existing skills
- **Posture:** characterization-first (existing skills already work
  in v1 shape; pin behaviour, then change)
- **Effort:** significant
- **Depends on:** Task 1
- **Description:** Rewrite `scope`, `plan`, `approve` for new IDs;
  trim `evaluate`, `list`, `status`, `learn`, `research`, `review`,
  `intent`, `quick` for new references.
- **Tests:** Lint suite green.

### Task 4: Documentation
- **Posture:** straight-through (docs-only)
- **Effort:** moderate
- **Depends on:** Tasks 1–3
- **Description:** Rewrite `docs/FRAMEWORK.md`. Add
  `docs/EXTENDING-BACKENDS.md`. Update plugin and marketplace
  manifests.
- **Tests:** Examples lint validates `examples/example-*.md` still
  conform.

### Task 5: Dogfood + Verify
- **Posture:** test-first
- **Effort:** brief
- **Depends on:** Tasks 1–4
- **Description:** Re-create the framework's own project, scope, plan
  in v2 format. Run the lint suite.
- **Tests:** Full `run-all.sh` exits 0.

## Delivery Sequence

1. Task 1 (no deps)
2. Tasks 2 and 3 (parallel; both depend on Task 1)
3. Task 4 (depends on Tasks 2 and 3)
4. Task 5 (depends on Task 4)

## Testing & Verification

After delivery: lint suite green; the framework's own `.spades/`
contains a valid project, scope, and plan in v2 format; the
marketplace manifests describe 15 skills + 5 agents at version 2.0.0.

## Audit Trail

<!-- Auto-appended by SPADES skills. -->
- 2026-05-29: Plan drafted.
- 2026-05-29: Plan approved (routing: ai, deliverable: code).
- 2026-05-29: Do phase complete — all 5 tasks finished.
- 2026-05-29: Evaluate pending — lint green; awaiting end-to-end smoke.
