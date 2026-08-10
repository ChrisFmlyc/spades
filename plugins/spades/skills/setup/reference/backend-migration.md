# Backend-switch migration

Read this when `/spades:setup` Step 2.6 fires — i.e. when
`current_backend != new_backend`. An SCM, project, or Linear
team/project change alone does **not** reach here; it goes straight
to Step 3.

Return to SKILL.md Step 3 when the walk completes, is skipped, or is
cancelled.

## Contents

- The three options offered in both directions
- Direction A — `local → linear` (the artefact walk, status maps)
- Direction B — `linear → local`
- Error handling for both directions

## The three options

Offer these via `AskUserQuestion` in either direction:

- **Migrate** *(Recommended)* — run the walk below.
- **Skip — start fresh** — source files untouched; the target
  backend starts empty.
- **Cancel the backend switch** — return to Step 1.

## Direction A — `local → linear`

For each artefact, search Linear under the bound Project; a match
links via frontmatter ID, no match creates.

1. **Projects** — `.spades/projects/<slug>.md` → Linear Project
   (`mcp__linear-server__list_projects` filtered by team, then
   `mcp__linear-server__save_project` if no match). Write
   `linear_project_id` back. Disambiguate a multi-match via
   `AskUserQuestion`.

2. **Scopes** — `.spades/scopes/S-<slug>.md` → Linear Issue under
   the bound Project. Body = the Scope's markdown (Statement of
   Intent, Acceptance Criteria, Architectural Constraints, Out of
   Scope, Risk / Unknowns, Delivery Preference, Audit Trail). Write
   `linear_issue_id` back.

   | Scope status | Linear |
   |---|---|
   | `scoped` | Triage / team default |
   | `planning` | Planning |
   | `delivering` | In Progress |
   | `done` | Done |

3. **Plans** — `.spades/plans/P-<…>.md` → sub-Issue under the
   Scope's parent Issue. Body = Plan markdown (Technical Approach,
   Tasks, Risks & Assumptions, Testing & Verification, Delivery
   Sequence, Audit Trail). Write `linear_issue_id` back.

   | Plan status | Linear |
   |---|---|
   | `draft` | Backlog / default |
   | `approved` | Approval |
   | `delivering` | Delivering / In Progress |
   | `evaluating` | Evaluating |
   | `shipping` | Shipping |
   | `shipped` | Done |
   | `rejected` | Cancelled |

4. **Audit-trail entry** on every migrated artefact:

   ```markdown
   - YYYY-MM-DD: Migrated to Linear (backend switch). Linear: <id>.
   ```

5. **Learnings are not migrated** — they are local-only commentary.
   Print `○ Learnings: kept local-only (N files preserved).`

6. **Summary:**

   ```
   ✓ Migration complete. local → linear:
       Projects:  1 (1 created, 0 linked to existing)
       Scopes:    3 (2 created, 1 linked to existing)
       Plans:    11 (8 created, 3 linked to existing)
       Learnings: skipped (4 files stay local).
   ```

## Direction B — `linear → local`

Walk the bound Linear Project — Projects → top-level Issues for
Scopes → sub-Issues for Plans — and write each as a local file,
**preserving `linear_issue_id`** so a future switch back still
links. Skip comments; they are not SPADES artefacts.

## Error handling (both directions)

- **Linear MCP unreachable mid-walk** — abort gracefully.
  Already-linked items keep their `linear_*_id` frontmatter. On
  retry, Step 2.6 detects the partial state and offers *Resume
  migration* / *Skip resume* / *Cancel*.
- **Duplicate title** — disambiguate via `AskUserQuestion` listing
  the candidate Linear IDs. Never blind-pick.
- **Network / rate-limit** — surface the error verbatim; offer
  *Retry* / *Skip this item* / *Abort migration*.
