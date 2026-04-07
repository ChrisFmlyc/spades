# Example Scope: Device Telemetry Ingestion

This is a worked example of a well-formed SPADE Scope.

---

## Scope: Build Databricks telemetry ingestion worker

**Intent:** Build a Temporal worker that pulls device telemetry signals from
Databricks, normalises them into the shared Argus data model, and writes to
Elasticsearch. This gives the threat intelligence team real-time visibility
into device behaviour patterns across the fleet.

**Acceptance Criteria:**

- [ ] Temporal worker runs on a configurable schedule (default: every 5 minutes)
- [ ] Telemetry data appears in the Elasticsearch index within 5 minutes of
      Databricks availability
- [ ] Data conforms to the shared Argus data model schema (see ARCHITECTURE.md)
- [ ] Basic data quality checks reject malformed records and log them
- [ ] Slack alerting fires on worker failure (channel: #argus-alerts)
- [ ] Unit tests cover normalisation logic with >80% coverage
- [ ] Integration test validates end-to-end flow with sample data

**Constraints:**

- Must use Temporal Cloud (existing infrastructure, see ARCHITECTURE.md)
- Must use the existing Elasticsearch cluster (no new infrastructure)
- Normalisation must follow the Argus data model v2 schema
- No direct Databricks credentials in code (use existing secrets management)
- Worker must be deployable to the existing EKS cluster

**Context:**

- Upstream: Databricks telemetry tables (populated by data engineering team)
- Downstream: Argus relevancy engine consumes normalised data from Elasticsearch
- Related: Existing Kafka consumers follow a similar pattern (see consumer-template/)

**Origin:** Q2 2026 OKR: "Argus platform is operationally valuable" /
Milestone: "Device telemetry is flowing into the intelligence platform"
