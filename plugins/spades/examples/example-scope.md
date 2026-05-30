---
id: S-add-healthz-endpoint
title: "Add /healthz endpoint"
project: example-service
status: scoped
type: feature
priority: this-cycle
origin: ad-hoc
# strategy_link: https://linear.app/example/issue/ROAD-142   # optional; only when seeded from a roadmap / OKR / epic
created: 2026-05-29
updated: 2026-05-29
---

# Add /healthz endpoint

## Statement of Intent

Operators need a single endpoint they can curl from the load balancer
to confirm the service is healthy enough to receive traffic. Without
it, deployments rely on log scraping and tail-of-the-eye guesswork.

## Acceptance Criteria

- [ ] `GET /healthz` returns `200 OK` when the service is healthy
- [ ] Body is `{"status":"ok","version":"<service-version>"}`
- [ ] Returns `503 Service Unavailable` when the database connection is down
- [ ] Endpoint completes in <50ms p99 under normal load
- [ ] Endpoint is documented in the README and the ops runbook

## Architectural Constraints

No additional constraints beyond ARCHITECTURE.md. The endpoint must
use the same router and middleware stack as the existing API surface.

## Dependencies

- The service version is already exposed via `process.env.APP_VERSION`
- The DB pool exposes a `ping()` method we can reuse

## Context

- **Upstream:** Load balancer health check, deployment tooling
- **Downstream:** Ops runbook, on-call documentation
- **Related:** S-add-readiness-checks (different scope; concerns startup
  ordering, not steady-state health)

## Out of Scope

- A separate `/readyz` endpoint for startup readiness
- Authentication on `/healthz` — it's public by design
- Custom metrics on health checks (handled by the existing Prometheus
  middleware)

## Risk / Unknowns

- DB pool's `ping()` behaviour under partial connection failure isn't
  well-documented — verify with a deliberate disconnect test

## Delivery Preference

Mostly AI-delivered. Code change is small; ops runbook update can be a
human touch.

## Audit Trail

<!-- Auto-appended by the SPADES skills. Do not edit by hand. -->
