# Backend-switch migration

`/spades:setup` Step 6 reads this file when
`current_backend != new_backend`.

## Contents

- The three options offered in both directions
- Direction A — `local → linear` (the artefact walk)
- Direction B — `linear → local`
- Error handling for both directions

## The three options

Offer these as a question in either direction:

- **Migrate** *(Recommended)* — run the walk below.
- **Skip — start fresh** — source files untouched; the target
  backend starts empty.
- **Cancel the backend switch** — return to Step 1.

## Direction A — `local → linear`

The walk covers the active project chosen at Step 4 and its Scopes and
Plans; other local projects and their artefacts stay as they are. For
each Scope and Plan, search Linear under the active project's Linear
Project; a match links via frontmatter ID, no match creates. Each Scope
and Plan takes the workflow state that `docs/FRAMEWORK.md § Drift
detection → Status-type mapping (canonical)` gives its status.

1. **Active project** — bind `.spades/projects/<slug>.md` to the
   `project_id` Steps 1 and 4 recorded. With `create_linear_project`,
   first create the Linear Project on `team_id` with the record's title
   and description (`mcp__linear-server__save_project`), record its ID
   as `project_id` and clear `create_linear_project`. Write
   `linear_project_id` back. With `create_new_project` there is no
   record yet: Step 8 creates and binds it, and the walk has nothing to
   migrate.

2. **Scopes** — each of the active project's
   `.spades/scopes/S-<slug>.md` → Linear Issue under its Linear
   Project. Body = the Scope's markdown. Write `linear_issue_id` back.

3. **Plans** — `.spades/plans/P-<…>.md` → sub-Issue under the
   Scope's parent Issue. Body = the Plan's markdown. Write
   `linear_issue_id` back.

4. **Audit-trail entry** on every migrated artefact:

   ```markdown
   - YYYY-MM-DD: Migrated to Linear (backend switch). Linear: <id>.
   ```

5. **Learnings are not migrated** — they are local-only commentary.
   Print `○ Learnings: kept local-only (N files preserved).`

6. **Summary:**

   ```
   ✓ Migration complete. local → linear:
       Project:   closed-door-security-website (bound to an existing Linear Project)
       Scopes:    3 (2 created, 1 linked to existing)
       Plans:    11 (8 created, 3 linked to existing)
       Other projects: 2 kept local.
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
  retry, Step 6 detects the partial state and offers *Resume
  migration* / *Skip resume* / *Cancel*.
- **Duplicate title** — disambiguate with a picker of the candidate
  Linear IDs per `docs/FRAMEWORK.md § Target Resolution` step 3.
  Never blind-pick.
- **Network / rate-limit** — surface the error verbatim; offer
  *Retry* / *Skip this item* / *Abort migration*.
