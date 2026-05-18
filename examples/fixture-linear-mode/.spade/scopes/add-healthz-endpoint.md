---
name: add-healthz-endpoint
title: Add a /healthz endpoint to the API
status: delivering
type: feature
phase: delivery
created: 2026-05-18
updated: 2026-05-18
origin: ad-hoc
priority: medium
delivery: ai-delivered
---

## Scope: Add a /healthz endpoint to the API

**Intent:** Operators and uptime monitors can confirm the API is alive
with a single unauthenticated request, instead of inferring health
from a business endpoint.

**Acceptance Criteria:**

- [ ] `GET /healthz` returns `200` with body `{"status":"ok"}` when the
  process is serving.
- [ ] The endpoint requires no authentication and touches no database.
- [ ] Response time is under 50ms at p99.

**Architectural Constraints:** No additional constraints beyond
ARCHITECTURE.md.

**Dependencies:** None.

**Out of Scope:** Deep health checks (database, downstream services) —
a separate Scope.

**Origin:** Ad-hoc — fixture Scope for the M-879 `linear` mode
verification fixture. Not real work.

**Risk / Unknowns:** None identified.

**Delivery Preference:** Mostly AI-delivered.

**Priority:** Backlog.
