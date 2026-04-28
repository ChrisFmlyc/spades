---
name: spade-onboard
description: Onboard a project into the SPADE framework. Creates AGENTS.md, CLAUDE.md, architecture templates, and example files if they don't exist, then analyses the codebase to fill in architecture docs. Use when someone says "onboard this project", "set up SPADE", "spade init", or when starting SPADE in a new repo. Also use when architecture docs are still templates with placeholder comments.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

# SPADE Onboard

You are onboarding a project into the SPADE framework. Your job is twofold:

1. **Initialise** — create the SPADE project files if they don't exist
2. **Analyse** — explore the codebase and help fill in architecture docs

## Self-onboard guard (stop here)

**Before anything else**, check whether the current working directory is the
SPADE framework repository itself:

```bash
if [ -f ".claude/skills/spade-onboard/SKILL.md" ] && [ -f "fragments/AGENTS-section.md" ]; then
  echo "This looks like the SPADE framework repository."
  echo "Refusing to self-onboard — the framework's own AGENTS.md / CLAUDE.md"
  echo "are the canonical source, not fragment-wrapped copies."
  exit 0
fi
```

If the guard triggers, stop and tell the human:

> This is the SPADE framework repo itself — no onboarding needed. Its
> `AGENTS.md`, `CLAUDE.md`, and architecture docs are already the source
> of truth. If you wanted to onboard a different project, `cd` into it
> and run `/spade-onboard` there.

Do not proceed to the steps below when in the framework repo.

## Step 0: Initialise SPADE Project Files

Once the self-onboard guard has passed, initialise or update framework files
using the **marker-replace contract** implemented by
`~/.spade/bin/spade-marker-replace`:

```bash
spade-marker-replace TARGET_FILE FRAGMENT_FILE VERSION
```

The contract is deterministic and idempotent:

| Target state                                      | Outcome                                                                 |
|---------------------------------------------------|-------------------------------------------------------------------------|
| Target file absent                                | Create with START (vVERSION) + fragment + END                           |
| Target exists, no markers                         | Append blank line, then START + fragment + END; preserve existing text  |
| Target has one matching `vX.Y.Z` marker pair      | Replace block in place, re-stamping START to `vVERSION`                 |
| Target has mismatched markers (START != END)      | Exit 2, no modification                                                 |
| Target has multiple START/END pairs               | Exit 3, no modification (human must resolve)                            |

Running twice with the same inputs produces an **unchanged file** on the
second run. This is the property onboarding relies on — re-running
`/spade-onboard` must not drift the consumer repo.

### AGENTS.md

Call the helper to insert or refresh the SPADE section:

```bash
~/.spade/bin/spade-marker-replace \
  "$PWD/AGENTS.md" \
  ~/.spade/fragments/AGENTS-section.md \
  1.3.0
```

If the helper exits with code 2 (mismatched markers), stop and show the
human the error message. Do NOT try to "fix" the target file automatically
— malformed markers usually signal hand-editing the human should review.

If it exits with code 3 (duplicate markers), same behaviour — refuse, report,
ask the human to collapse the blocks by hand before re-running.

### CLAUDE.md

Same pattern, using the CLAUDE fragment:

```bash
~/.spade/bin/spade-marker-replace \
  "$PWD/CLAUDE.md" \
  ~/.spade/fragments/CLAUDE-section.md \
  1.3.0
```

### Architecture Templates

For each of these files, create them **only if they don't exist**. Read the
template from `~/.spade/` and copy it:

- `ARCHITECTURE.md` (from `~/.spade/ARCHITECTURE.md`)
- `PATTERNS.md` (from `~/.spade/PATTERNS.md`)
- `ANTI-PATTERNS.md` (from `~/.spade/ANTI-PATTERNS.md`)

If any of these already exist, decide whether to prompt the human
deterministically by **detecting unfilled template markers**. The
framework templates use HTML comments of the shape
`<!-- Describe ... -->`, `<!-- List ... -->`, `<!-- Example: ... -->`,
or `<!-- Add ... -->` to mark sections the consumer is meant to
fill in. A real filled-in document has zero such markers (the comment
prompt has been replaced with project-specific prose).

**Detection mechanism:**

```bash
# Case-insensitive match for the four canonical template marker
# openings. Two or more matches in a single file = still a template.
grep -ciE '<!--[[:space:]]*(Describe|List|Example:|Add)[[:space:]]' "$f"
```

If the count is **≥ 2**, treat the file as still a template and
prompt the human via **`AskUserQuestion`** (per `docs/FRAMEWORK.md`
§ "Asking the Human") with options:

- *Overwrite with fresh template*
- *Merge — keep existing content, add missing sections*
- *Skip — leave as-is*

If the count is **0 or 1**, leave the file untouched — the consumer
already has real project-specific content and the prompt would be
noise. (The "1 match" tolerance covers a stray HTML comment in
otherwise-filled-in prose.)

Open-ended steps later in this skill (architecture-conflict
resolution, free-form pattern descriptions) stay free-form per the
convention's exception clause — only the overwrite/merge/skip
decision is structured.

### Project Config

Create `.spade/config` if it doesn't exist. This file tells all SPADE skills
which Linear team and project to target. If Linear MCP is available, help
the human fill it in interactively:

1. Use `list_teams` to show available teams. Ask which one.
2. Use `list_projects` to show projects for that team. Ask which one.
3. Ask for a default assignee (their name or "me").

Write the config file as YAML, using the same nested shape this repo's
own `.spade/config` uses:

```yaml
# SPADE per-repo configuration.
# Read by SPADE skills to avoid prompting for team/project on every invocation.

linear:
  team: M-KOPA
  team_id: 55069140-fef8-4f1a-8d04-726227e0292b
  project: Argus
  project_id: <uuid from list_projects>
  default_assignee: me
```

`team_id` and `project_id` are optional but recommended — capturing them
during onboarding saves a `list_*` round-trip on every future skill
invocation.

If Linear MCP is not available, create the file with placeholder values
(omit the `*_id` fields) and tell the human to fill it in manually.

All SPADE skills that interact with Linear MUST read `.spade/config` first
to determine the team, project, and assignee. Do not prompt for these values
if the config file exists and is populated.

### Examples and Docs

- Create `.spade/examples/` if it doesn't exist and copy example files from
  `~/.spade/examples/`
- Create `.spade/docs/` and copy docs from `~/.spade/docs/`
- Create `.spade/version` with install metadata

### Report What Was Done

After initialisation, tell the human what was created and what was skipped:

```
SPADE project files:
  ✓ AGENTS.md created
  ✓ CLAUDE.md created
  ✓ ARCHITECTURE.md created (template)
  ! PATTERNS.md already exists, skipped
  ✓ .spade/examples/ created
```

If all files already existed, say so and move straight to the analysis step.

## Step 1: Analyse the Codebase

Before asking the human anything, explore the project:

1. Read the directory structure (top two levels)
2. Read any existing README, docs, or configuration files
3. Look at package.json, requirements.txt, go.mod, Cargo.toml, or equivalent
   to understand the dependency landscape
4. Look at Dockerfiles, docker-compose files, or infrastructure configs
5. Look at CI/CD configuration (.github/workflows, .gitlab-ci.yml, etc.)
6. Read a sample of source files to understand coding patterns
7. Check for existing test files and testing patterns
8. Look for authentication/authorisation patterns
9. Check for database migrations or schema files

## Step 2: Present Your Understanding

Summarise what you have found and present it to the human for validation:

- "Here is what I understand about your project. Please correct anything
  that is wrong or incomplete."

Cover:
- What the project does (purpose, users)
- Infrastructure and hosting
- Tech stack (languages, frameworks, databases, queues, etc.)
- Code organisation and patterns
- Testing approach
- Deployment pipeline
- Security considerations
- External integrations

## Step 3: Fill In ARCHITECTURE.md

Based on the validated understanding, generate the content for ARCHITECTURE.md.
Follow the template structure already in the file, but replace all placeholder
comments with real content.

Present each section to the human for approval before moving to the next.
They know things about the system that code analysis cannot reveal (planned
migrations, deprecated components, infrastructure not visible in the repo).

## Step 4: Fill In PATTERNS.md

Document the coding patterns, conventions, and approved libraries visible in
the codebase. Focus on:

- Patterns that are consistently used (these are the established conventions)
- Libraries that appear across multiple files (these are the approved choices)
- Naming conventions, error handling approaches, logging patterns
- How tests are structured and what testing libraries are used
- How services communicate (REST, gRPC, events, etc.)

Ask the human: "Are there patterns you want to enforce that are not yet
consistently applied? These are also worth documenting."

## Step 5: Fill In ANTI-PATTERNS.md

This requires the most human input because anti-patterns often come from
painful experience rather than code analysis. Ask the human directly:

- "What mistakes have been made in this project that you want to prevent?"
- "Are there technologies or approaches that have been tried and rejected?"
- "What would you warn a new team member (or AI agent) not to do?"
- "Are there dependencies or patterns that should never be introduced?"

Document each anti-pattern with a clear rationale. The rationale matters
because it helps AI agents understand why the constraint exists, not just
that it exists.

## Step 6: Verify and Commit

After all three documents are filled in:

1. Show a summary of what was documented
2. Ask the human to review and confirm
3. Suggest they commit the changes:

```bash
git add AGENTS.md CLAUDE.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md .claude/ .spade/
git commit -m "Onboard project with SPADE framework"
```

Remind them: "These documents are living. Update them as your architecture
evolves. The better the context, the better the AI-generated Plans."

Also remind them: "Once these files are committed, teammates who clone
this repo will have SPADE working automatically — they just need the
global skills install (`~/.spade/setup`)."

## Why This Matters

The quality of AI-generated Plans is directly proportional to the quality of
the architecture context. A blank ARCHITECTURE.md means the AI will guess.
A detailed one means the AI will propose solutions that fit your world. This
onboarding step is the single highest-leverage thing you can do to make SPADE
work well.

## Quality Checks

Before finishing, verify:

- [ ] All SPADE project files exist (AGENTS.md, CLAUDE.md, architecture docs)
- [ ] ARCHITECTURE.md has no placeholder comments remaining
- [ ] Tech stack table is complete with actual technologies and versions
- [ ] PATTERNS.md reflects what the code actually does, not aspirations
- [ ] ANTI-PATTERNS.md has rationale for every entry
- [ ] All three documents are specific enough that an AI agent reading them
      could propose a solution that fits this project
- [ ] The human has reviewed and approved all content

## If Linear MCP is Available

Also help the human set up the Linear integration:

1. Confirm the team and project from `.spade/config` are correct
2. Check if the SPADE statuses exist in their Linear workflow
   (Scoped, Planning, Approval, Delivering, Evaluating, Done)
3. Check if the SPADE labels exist
   (ai-planned, ai-delivered, human-delivery, plan-rejected, needs-arch-review)
4. If not, advise the human on how to create them

## Output

The onboarding is complete when:
- All SPADE project files are created
- ARCHITECTURE.md is filled in and validated
- PATTERNS.md is filled in and validated
- ANTI-PATTERNS.md is filled in and validated
- The human understands how to use the SPADE skills
- Linear integration is configured (if applicable)
