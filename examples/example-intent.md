---
last_reviewed: 2026-05-12
---

*This is a worked example of a well-formed SPADE `INTENT.md` — the durable
project-intent document for a fictional security platform, "Argus". Compare it
against `templates/INTENT.md` to see a filled-in version of each section. It
shares its fictional universe with `examples/example-scope.md`.*

# Project Intent

Argus exists so the threat-intelligence team can see what is happening across
the device fleet and act on it before customers are harmed — turning scattered
telemetry, vendor feeds, and analyst knowledge into one operational picture.

## Problem

Security-relevant signal about the fleet is spread across Databricks tables,
vendor threat feeds, ticketing systems, and analysts' heads. By the time
someone correlates a device-behaviour anomaly with a known threat campaign, the
window to act has often closed.

The threat-intelligence team needs one place where fleet telemetry, external
intelligence, and prior investigations come together — without each analyst
rebuilding that picture by hand, every time.

## Users

- **Threat-intelligence analysts** — the primary users. They triage
  device-behaviour anomalies, pivot from a signal to related devices and
  campaigns, and record findings other analysts can build on.
- **Incident responders** — need fast answers during an active incident: which
  devices are affected, what the platform already knows, what changed.
- **Security leadership** — need a defensible view of fleet risk posture over
  time, not a raw alert stream.

Argus is not built for end customers, and not for general-purpose device
management — those audiences are served by other systems.

## What it does

Argus ingests device telemetry and external threat intelligence on a continuous
schedule, normalises it into one data model, and makes it queryable and
correlatable. Analysts search across the fleet, pivot between devices,
indicators, and campaigns, and attach investigation notes that persist.

It surfaces relevancy-ranked anomalies so the team spends attention where it
matters, and alerts when fleet behaviour crosses defined thresholds.

## Success

- Analysts answer "is this device behaviour a known threat?" in minutes, using
  Argus alone, without ad-hoc data pulls.
- New anomalies are correlated with existing intelligence automatically often
  enough that analysts trust the relevancy ranking.
- Investigation knowledge compounds — a finding recorded once is found again by
  the next analyst.
- Leadership reports fleet risk posture from Argus rather than from hand-built
  spreadsheets.

## Non-goals

- Argus does **not** take automated remediation action on devices — it informs
  human decisions; it never quarantines, patches, or disables a device itself.
- Argus is **not** a SIEM or a log-retention system — it holds
  security-relevant intelligence, not the full firehose of operational logs.
- Argus does **not** serve customer-facing dashboards — its audience is the
  internal security team only.
- Sub-minute "real-time" detection is out of scope until the ingestion pipeline
  is proven at fleet scale; the platform targets a five-minute correlation
  window today.

## Maturity

In production and operationally relied upon by the threat-intelligence team.
Core ingestion, search, and correlation are stable; the relevancy-ranking model
is still being tuned and is the area of most active development.
