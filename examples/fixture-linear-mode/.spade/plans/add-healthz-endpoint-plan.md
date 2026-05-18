---
issue: add-healthz-endpoint
title: Add a /healthz endpoint to the API
date: 2026-05-18
status: approved
---

# Plan — Add a /healthz endpoint to the API

**Technical Approach Summary:** Register one unauthenticated route that
returns a static JSON body. No persistence, no downstream calls.

**Risks and Assumptions:** None — the route is independent of
application state.

## Tasks

### Task 1: Add the /healthz route

- **Mode:** ai-delivered
- **Depends on:** none
- **Effort:** brief
- **Execution posture:** test-first — the contract (status code, body,
  no auth) is fully specified.
- **Description:** Register `GET /healthz` returning
  `200 {"status":"ok"}`, outside the auth middleware.
- **Approach:** Add the route alongside existing public routes.
- **Tests:** A request test asserting status, body, and that no auth
  header is required.

### Delivery Sequence

1. Task 1 (no dependencies).

### Delivery Bundles

#### Bundle 1: healthz
- **Branch:** `spade/add-healthz-endpoint`
- **PR title:** Add a /healthz endpoint
- **Tasks:** Task 1
- **Rationale:** Single task, single bundle.
