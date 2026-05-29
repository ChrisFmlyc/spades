# Extending SPADES with a New Backend

SPADES v2.0 ships with two backend drivers: **Linear** (via the Linear
MCP) and **local** (filesystem). Any system that has an MCP — Notion,
Confluence, ClickUp, GitHub Projects, Jira — can host SPADES artefacts
if a driver is written against the contract in `docs/FRAMEWORK.md`
§ Backend Interface.

This document explains how to add one.

---

## What a Driver Is

A driver is **a section of `docs/FRAMEWORK.md` plus a per-skill
mapping**, not a binary or a runtime plugin. SPADES skills are pure
Markdown instructions read by Claude. A new "driver" is a set of
prose contracts telling the AI:

1. Where each operation maps onto the backend's primitives (which MCP
   tool, which collection, which field on the record).
2. What the backend record looks like (its native schema for projects,
   scopes, plans, comments).
3. How errors are surfaced (transient retryable failures vs hard
   aborts).

Each skill that does I/O reads `.spades/config`'s `backend:` field and
picks the matching contract section. So adding a backend means:
extending FRAMEWORK.md, and updating each I/O-touching skill with a
short branch for the new backend.

---

## Contract Drivers Must Satisfy

The full operation list is in FRAMEWORK.md § Backend Interface. Every
driver must implement every operation. On a backend that cannot
naturally represent something, return a documented stub error rather
than silently succeeding.

### Mandatory behaviours

1. **Identity stability.** Once an ID is allocated to a project, scope,
   or plan, the driver MUST NOT change it. The local driver uses
   filenames as IDs; the Linear driver uses Linear issue IDs. A driver
   on, say, Notion would use the Notion page ID.

2. **Status mapping.** The driver translates SPADES statuses into the
   backend's native states. Document the mapping in your driver
   contract. The shipped Linear driver maps:

   | SPADES status   | Linear workflow state    |
   |-----------------|--------------------------|
   | scoped          | Scoped                   |
   | planning        | Planning                 |
   | approval        | Approval                 |
   | delivering      | Delivering / In Progress |
   | evaluating      | Evaluating / In Review   |
   | shipping        | Shipping                 |
   | done            | Done                     |

   Your driver should publish a similar table.

3. **Audit-trail durability.** `record_approval`, `record_evaluation`,
   and `record_shipment` MUST land in a place that the human can
   later inspect. The local driver appends to an `## Audit Trail`
   section in the relevant scope/plan file; the Linear driver posts a
   comment. A Notion driver would post a sub-page, etc.

4. **No silent retries.** A failed write surfaces to the human with the
   exact state — what landed, what didn't. Do not auto-retry
   indefinitely.

---

## Adding a Notion Driver (Worked Example)

Sketch of what adding `backend: notion` would entail:

1. **Pick the data model.** In Notion:
   - Project → a top-level Notion page (or a row in a "Projects" database).
   - Scope → a child page of the project (or a row in a "Scopes"
     database with a relation to the project).
   - Plan → a child page of the scope.

2. **Extend `.spades/config`.** Add a `notion:` block analogous to the
   `linear:` block:

   ```yaml
   backend: notion
   project: closed-door-security-website
   notion:
     workspace_id: <uuid>
     projects_db_id: <uuid>
     scopes_db_id: <uuid>
     plans_db_id: <uuid>
   ```

3. **Document the operation mapping** in FRAMEWORK.md or, preferably,
   a `docs/backends/notion.md` file:

   | Operation          | Notion MCP call                    |
   |--------------------|-------------------------------------|
   | `create_project`   | `notion-create-pages` on projects_db |
   | `get_project`      | `notion-fetch`                     |
   | `list_projects`    | `notion-query-database-view`        |
   | `create_scope`     | `notion-create-pages` on scopes_db  |
   | `record_approval`  | `notion-create-comment`             |
   | …                  | …                                   |

4. **Update each I/O-touching skill** with a `Notion` branch alongside
   the existing `Linear` and `Local` branches. The branches should be
   short — they map operations onto MCP calls, nothing more.

5. **Document the status mapping** for Notion (likely a Select property
   on the database).

6. **Add a smoke test.** A small Markdown checklist that walks a human
   through creating a project, scope, plan, approving, doing,
   evaluating, and shipping against the Notion backend. Living
   somewhere like `docs/backends/notion-smoke-test.md`.

---

## Things a Driver Author Should Resist

- **Don't invent new artefact types.** SPADES has Project, Scope, Plan,
  Learning, Review. A new backend does not get to introduce a new
  artefact tier.

- **Don't reshape the ID format.** Backends may have their own native
  IDs (Linear's `M-1234`, Notion's page IDs); store those as
  `linear_issue_id:` / `notion_page_id:` frontmatter fields. The
  SPADES ID (`S-…`, `P-…`) remains canonical for filenames and
  cross-references.

- **Don't move the gate.** Approval, evaluation, and shipping are
  always human-gated. A backend that auto-transitions on a webhook
  isn't compatible without first wiring those transitions through the
  SPADES skills.

- **Don't store secrets in `.spades/config`.** API keys, tokens,
  workspace credentials belong in the MCP server's own configuration.
  `.spades/config` names *which* workspace to use, not how to
  authenticate to it.
