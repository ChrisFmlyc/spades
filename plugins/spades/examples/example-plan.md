---
id: P-add-healthz-endpoint-7QkP
id_suffix: 7QkP
scope: S-add-healthz-endpoint
title: "Add /healthz endpoint"
depends_on: []
status: draft
delivery: undecided
deliverable_type: code
created: 2026-05-29
updated: 2026-05-29
---

# Add /healthz endpoint

## Technical Approach

Add a new route handler under `src/routes/health.ts` that returns the
service status, version, and database connectivity. Mount it in the
existing router. Wire it into the deployment pipeline's smoke test.

## Risks & Assumptions

- Assumption: DB pool `ping()` returns within 50ms under normal load.
  If not, criterion 4 fails.
- Risk: a slow `ping()` could cascade across many health-check probes.
  Mitigation: add a 100ms timeout on the ping call.

## Tasks

### Task 1: Add the route handler
- **Posture:** test-first
- **Effort:** brief
- **Depends on:** none
- **Description:** Create `src/routes/health.ts` exporting the handler.
- **Approach:** Single function. Returns `{status, version}`. On DB
  ping failure, returns 503 with `{status: "unhealthy", reason: ...}`.
- **Tests:** Unit test with mocked DB pool; integration test against a
  real running service.

### Task 2: Mount the route
- **Posture:** straight-through (mechanical change covered by existing
  routing tests)
- **Effort:** brief
- **Depends on:** Task 1
- **Description:** Register the handler in `src/routes/index.ts`.
- **Approach:** One line.
- **Tests:** Existing route registration test covers presence.

### Task 3: Document the endpoint
- **Posture:** straight-through (docs-only)
- **Effort:** brief
- **Depends on:** Task 2
- **Description:** Add a section to README; add a curl command to
  ops runbook.
- **Approach:** Plain Markdown.
- **Tests:** N/A — visual review.

## Delivery Sequence

1. Task 1 (no deps)
2. Task 2 (depends on Task 1)
3. Task 3 (depends on Task 2)

## Testing & Verification

After delivery: curl the endpoint locally, confirm 200/{status,version};
disconnect the DB, confirm 503. CI smoke test green.

## Audit Trail

<!-- Auto-appended by the SPADES skills. Do not edit by hand. -->
