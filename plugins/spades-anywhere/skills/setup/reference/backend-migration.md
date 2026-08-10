# Backend-switch migration

Read this when `/spades-anywhere:setup` Step 2.6 fires — i.e. when
`current_backend != new_backend`. A project or review-format change
alone does **not** reach here; it goes straight to Step 3.

Return to SKILL.md Step 3 when the walk completes, is skipped, or is
cancelled.

## Contents

- The options offered in both directions
- `local → linear` — the artefact walk and status maps
- `linear → local` — the pull
- Error handling for both directions

---

## Step 2.6 — Backend-switch migration

Fires **only** when `current_backend != new_backend`. Project /
Linear team or project changes alone skip to Step 3.

### Direction A — `local → linear`

`AskUserQuestion`:

- **Walk the local artefacts and mirror them to Linear**
  *(Recommended)* — migration walk below.
- **Skip migration — start fresh in Linear** — local files
  untouched; Linear starts empty.
- **Cancel the backend switch** — back to Step 1.

**Migration walk:** for each artefact, search Linear under the
bound Project; match → link via frontmatter ID; no match →
create.

1. **Projects** — `.spades-anywhere/projects/<slug>.md` → Linear
   Project (via `mcp__linear-server__list_projects` filtered by
   team, then `mcp__linear-server__save_project` if no match).
   Write `linear_project_id` back. Disambiguate multi-match via
   `AskUserQuestion`.
2. **Scopes** — `.spades-anywhere/scopes/S-<slug>.md` → Linear
   Issue under the bound Project. Body = Scope markdown
   (Statement of Intent, Acceptance Criteria, Architectural
   Constraints, Out of Scope, Risk / Unknowns, Delivery
   Preference, Audit Trail). Status map: `scoped`→Triage/default,
   `planning`→Planning, `delivering`→In Progress, `done`→Done.
   Write `linear_issue_id` back.
3. **Plans** — `.spades-anywhere/plans/P-<…>.md` → sub-Issue
   under the Scope's parent Issue. Body = Plan markdown
   (Technical Approach, Tasks, Risks & Assumptions, Testing &
   Verification, Delivery Sequence, Audit Trail). Status map:
   `draft`→Backlog/default, `approved`→Approval,
   `delivering`→Delivering/In Progress, `evaluating`→Evaluating,
   `shipping`→Shipping, `shipped`→Done, `rejected`→Cancelled.
   Write `linear_issue_id` back.
4. **Audit-trail entry** on each migrated artefact:

   ```markdown
   - YYYY-MM-DD: Migrated to Linear (backend switch). Linear: <id>.
   ```

5. **Learnings** — not migrated; local-only commentary. Print:
   `○ Learnings: kept local-only (N files preserved).`

6. **Migration summary:**

```
✓ Migration complete. local → linear:
    Projects:  1 (1 created, 0 linked to existing)
    Scopes:    3 (2 created, 1 linked to existing)
    Plans:    11 (8 created, 3 linked to existing)
    Learnings: skipped (4 files stay local).
```

### Direction B — `linear → local`

`AskUserQuestion`:

- **Pull Linear artefacts down to local files** *(Recommended)*
  — walks the bound Linear Project (Projects → top-level Issues
  for Scopes → sub-Issues for Plans) and writes each as a local
  file, preserving `linear_issue_id`. Skips comments.
- **Skip — start fresh locally** — local files unchanged.
- **Cancel the backend switch** — back to Step 1.

### Migration error handling (both directions)

- **Linear MCP unreachable mid-walk** — abort gracefully;
  already-linked items retain `linear_*_id` frontmatter. On
  retry, Step 2.6 detects partial state and offers *Resume
  migration* / *Skip resume* / *Cancel*.
- **Duplicate title** — disambiguate via `AskUserQuestion`
  listing Linear IDs. Don't blind-pick.
- **Network / rate-limit** — surface verbatim; offer *Retry* /
  *Skip this item* / *Abort migration*.
