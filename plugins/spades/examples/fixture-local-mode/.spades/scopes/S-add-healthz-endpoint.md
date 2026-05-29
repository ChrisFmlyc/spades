---
id: S-add-healthz-endpoint
title: "Add /healthz endpoint"
project: example-service
status: scoped
type: feature
priority: this-cycle
origin: ad-hoc
created: 2026-05-29
updated: 2026-05-29
---

# Add /healthz endpoint

See `examples/example-scope.md` for the worked example. This file is
the fixture-mode mirror — kept lean so the lint exercises the schema
without re-stating the full prose.

## Statement of Intent

Operators need a `/healthz` endpoint for load-balancer health checks.

## Acceptance Criteria

- [ ] `GET /healthz` returns 200 OK when healthy
- [ ] Body includes `{"status":"ok","version":"<version>"}`
- [ ] Returns 503 when the DB is unreachable
- [ ] p99 latency under 50ms
- [ ] Documented in README + ops runbook
