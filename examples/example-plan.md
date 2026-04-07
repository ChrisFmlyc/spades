# Example Plan: Device Telemetry Ingestion

This is a worked example of a well-formed SPADE Plan, generated from the
example Scope.

---

## Plan for: Build Databricks telemetry ingestion worker

**Technical Approach Summary:**
Build a Temporal workflow with two activities: one to query Databricks via the
SQL connector and one to normalise and index into Elasticsearch. Use the
existing consumer-template as a starting point. Data quality checks run inline
during normalisation, with failed records routed to a dead-letter index.

**Risks and Assumptions:**

- Assumes Databricks SQL connector latency is acceptable for 5-minute cycles
  (need to validate with real query volumes)
- Assumes the Argus data model v2 schema is finalised (check with team)
- Slack webhook URL for #argus-alerts needs to be provisioned (human task)
- If telemetry volume exceeds expectations, the single-worker model may need
  scaling. Plan for this in Task 3 by using Temporal's built-in worker scaling.

### Tasks

#### Task 1: Temporal worker scaffold and Databricks connection
- **Mode:** ai-delivered
- **Depends on:** none
- **Effort:** moderate (2-3 hours)
- **Description:** Set up the Temporal workflow definition, activity stubs,
  and Databricks SQL connector. Use consumer-template as the base.
  Configure the schedule trigger (default 5 minutes).
- **Approach:** Copy consumer-template, replace Kafka consumer with Databricks
  SQL query activity. Use existing Temporal Cloud connection config.
- **Tests:** Unit test for workflow definition. Integration test stub for
  Databricks connection (mocked initially).

#### Task 2: Normalisation logic for Argus data model
- **Mode:** ai-delivered
- **Depends on:** Task 1
- **Effort:** moderate (2-3 hours)
- **Description:** Implement the transformation from Databricks telemetry
  schema to Argus data model v2. Include data quality validation (reject
  malformed records, log them to dead-letter index).
- **Approach:** Define TypeScript types matching Argus schema. Write transform
  functions with Zod validation. Failed records go to a separate ES index
  with the original payload and error reason.
- **Tests:** Unit tests for every field mapping. Edge case tests for malformed
  data. Target >80% coverage on normalisation module.

#### Task 3: Elasticsearch indexing layer
- **Mode:** ai-delivered
- **Depends on:** Task 2
- **Effort:** brief (1-2 hours)
- **Description:** Write the Elasticsearch indexing activity. Bulk index
  normalised records. Handle index creation if it does not exist.
- **Approach:** Use existing ES client from shared libraries. Bulk API for
  performance. Index naming follows Argus convention: argus-telemetry-YYYY-MM.
- **Tests:** Integration test with local ES (docker-compose).

#### Task 4: Slack failure alerting
- **Mode:** ai-delivered
- **Depends on:** Task 1
- **Effort:** brief (<1 hour)
- **Description:** Add Slack notification on workflow failure. Use existing
  Slack webhook pattern from other Argus workers.
- **Approach:** Wrap workflow execution in error handler. On failure, POST
  to Slack webhook with worker name, error message, and timestamp.
- **Tests:** Unit test for message formatting. Integration test with mock
  webhook endpoint.

#### Task 5: Provision Slack webhook and validate end-to-end
- **Mode:** human-delivery
- **Depends on:** Tasks 1-4
- **Effort:** brief (<1 hour)
- **Description:** Create the Slack webhook for #argus-alerts. Run the full
  pipeline against real Databricks data. Validate data appears correctly in
  Elasticsearch and alert fires on simulated failure.
- **Approach:** Manual provisioning and end-to-end validation. This requires
  access to the Slack admin panel and real Databricks credentials.
- **Tests:** Manual verification against acceptance criteria.

### Delivery Sequence

1. Task 1 (no dependencies, start immediately)
2. Task 4 (depends on Task 1, can run in parallel with Task 2)
3. Task 2 (depends on Task 1)
4. Task 3 (depends on Task 2)
5. Task 5 (depends on all above, human-delivered)
