---
name: spade-onboard
description: Onboard a project into the SPADE framework by analysing the codebase and helping fill in ARCHITECTURE.md, PATTERNS.md, and ANTI-PATTERNS.md. Use when SPADE has been installed but the architecture docs are still templates, when someone says "onboard this project", "set up SPADE", "fill in the architecture docs", or when ARCHITECTURE.md contains placeholder comments rather than real content.
---

# SPADE Onboard

You are onboarding a project into the SPADE framework. The setup script has
already installed AGENTS.md, CLAUDE.md, and the skills. Your job is to analyse
the codebase and help the human fill in the three architecture constraint
documents that AI agents will read during the Plan phase.

## Why This Matters

The quality of AI-generated Plans is directly proportional to the quality of
the architecture context. A blank ARCHITECTURE.md means the AI will guess.
A detailed one means the AI will propose solutions that fit your world. This
onboarding step is the single highest-leverage thing you can do to make SPADE
work well.

## Process

### Step 1: Analyse the Codebase

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

### Step 2: Present Your Understanding

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

### Step 3: Fill In ARCHITECTURE.md

Based on the validated understanding, generate the content for ARCHITECTURE.md.
Follow the template structure already in the file, but replace all placeholder
comments with real content.

Present each section to the human for approval before moving to the next.
They know things about the system that code analysis cannot reveal (planned
migrations, deprecated components, infrastructure not visible in the repo).

### Step 4: Fill In PATTERNS.md

Document the coding patterns, conventions, and approved libraries visible in
the codebase. Focus on:

- Patterns that are consistently used (these are the established conventions)
- Libraries that appear across multiple files (these are the approved choices)
- Naming conventions, error handling approaches, logging patterns
- How tests are structured and what testing libraries are used
- How services communicate (REST, gRPC, events, etc.)

Ask the human: "Are there patterns you want to enforce that are not yet
consistently applied? These are also worth documenting."

### Step 5: Fill In ANTI-PATTERNS.md

This requires the most human input because anti-patterns often come from
painful experience rather than code analysis. Ask the human directly:

- "What mistakes have been made in this project that you want to prevent?"
- "Are there technologies or approaches that have been tried and rejected?"
- "What would you warn a new team member (or AI agent) not to do?"
- "Are there dependencies or patterns that should never be introduced?"

Document each anti-pattern with a clear rationale. The rationale matters
because it helps AI agents understand why the constraint exists, not just
that it exists.

### Step 6: Verify and Commit

After all three documents are filled in:

1. Show a summary of what was documented
2. Ask the human to review and confirm
3. Suggest they commit the changes

Remind them: "These documents are living. Update them as your architecture
evolves. The better the context, the better the AI-generated Plans."

## Quality Checks

Before finishing, verify:

- [ ] ARCHITECTURE.md has no placeholder comments remaining
- [ ] Tech stack table is complete with actual technologies and versions
- [ ] PATTERNS.md reflects what the code actually does, not aspirations
- [ ] ANTI-PATTERNS.md has rationale for every entry
- [ ] All three documents are specific enough that an AI agent reading them
      could propose a solution that fits this project
- [ ] The human has reviewed and approved all content

## If Linear MCP is Available

Also help the human set up the Linear integration:

1. Check if the SPADE statuses exist in their Linear workflow
   (Scoped, Planning, Approval, Delivering, Evaluating, Done)
2. Check if the SPADE labels exist
   (ai-planned, ai-delivered, human-delivery, plan-rejected, needs-arch-review)
3. If not, advise the human on how to create them
4. Identify the relevant Linear team and projects for this repo

## Output

The onboarding is complete when:
- ARCHITECTURE.md is filled in and validated
- PATTERNS.md is filled in and validated
- ANTI-PATTERNS.md is filled in and validated
- The human understands how to use the SPADE skills
- Linear integration is configured (if applicable)
