---
last_reviewed: 2026-05-29
---

# Project Intent — Example Service

## Problem

Customers can't easily verify whether they're affected by an incident.
The status page is updated manually, sometimes hours after the issue
starts. Support tickets pile up asking "is this me or you?"

## Users

- **Customer engineering teams** — need to know whether to pause
  deployments or wait out an incident
- **Internal on-call** — need a single source of truth for current
  service health
- **Not for:** end-users of customers' own products (they shouldn't see
  this page; the customer surfaces incidents to their own users)

## What it does

Reads the live health of every public-facing service in our fleet and
renders a status page that auto-updates. When a service fails its
health check for 60s, the page flips that component to "degraded";
when it recovers, it flips back.

## Success

- Customer support tickets asking "is X broken?" drop by 80% relative
  to the pre-launch baseline
- The on-call team uses the status page as their primary diagnostic
  during incidents (not the chat channel)
- The status page is live within 60s of an incident starting

## Non-goals

- This service does NOT take remediation action — it only reports
- This service does NOT host customer-written incident notes — those
  live in our incident-management system
- This service is NOT a metrics dashboard — Prometheus and Grafana
  already do that better

## Maturity

In production since 2025-Q3. Currently serving the four customer-facing
services. Expanding to internal services is on the roadmap but not yet
scoped.
