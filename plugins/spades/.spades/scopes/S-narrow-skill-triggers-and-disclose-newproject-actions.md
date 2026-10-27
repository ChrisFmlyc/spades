---
id: S-narrow-skill-triggers-and-disclose-newproject-actions
title: "Narrow skill triggers and disclose newproject actions"
project: spades-framework
status: shipping
branch: fix/narrow-skill-triggers-newproject-disclosure
base_commit: ff25ddd62892823e08a7926fc123d689a8df76fd
type: bug
priority: medium
origin: reactive
created: 2026-10-27
updated: 2026-10-27
---

# Narrow skill triggers and disclose newproject actions

## Statement of Intent

SPADES skills auto-load only for requests about SPADES work, and
`/spades:newproject` tells the human what it writes, creates and makes
active.

## Acceptance Criteria

- [ ] `approve`'s description triggers name a Plan ("approve this plan", "approve P-…"); the bare "approve this" and "review the plan" triggers are gone.
- [ ] `evaluate`'s description triggers name a Plan or the Scope's acceptance criteria; the bare "evaluate this", "check if this is done" and "verify the output" triggers are gone.
- [ ] `newproject`'s description triggers say "SPADES project" ("new SPADES project", "create a SPADES project"); the bare "new project", "create a project" and "set up a project for X" triggers are gone, and the `/spades:setup` bootstrap trigger stays.
- [ ] `review`'s description ties "review this", "second opinion", "outside view" and "challenge this" to a Scope or Plan.
- [ ] `status`'s description no longer claims "any question about current state"; its triggers name SPADES work, Scopes or Plans.
- [ ] `newproject`'s draft confirmation tells the human what confirming does — writes `.spades/projects/<slug>.md` and, with `backend: linear`, creates a Linear Project — and the statement is accurate in both CLI and HTML mode.
- [ ] `newproject`'s `/spades:setup` bootstrap path still sets the Project active without asking, and the human is told it is now the active project.
- [ ] Each changed skill gets a patch version bump; the plugin version is bumped in all four places; a CHANGELOG entry is added under the new plugin version; the CI lints pass.

## Architectural Constraints

Repo-root `AGENTS.md` § Writing skills: a description says what the skill
does and when to use it, in third person, key use case first; fixes refine
the instruction in positive terms without recording the history of the fix.
`plugins/spades/AGENTS.md` § Versioning: the release gate applies
(`agents_version` is n/a unless `AGENTS.md` changes). No additional
constraints beyond ARCHITECTURE.md or PATTERNS.md.

## Dependencies

None.

## Context

- **Upstream:** a `skillspector scan` of `plugins/spades/` on 2026-10-27 scored the plugin 100/100 and confirmed 11 findings in `skills/`; the human triaged them one by one and chose these seven fixes.
- **Downstream:** harness skill auto-loading, which matches requests against descriptions. Explicit slash-command invocation is unaffected.
- **Related:** #117 (harness-agnostic questions) edited these skills immediately before this Scope.

## Out of Scope

- `scope`'s "add X" / "we need a Y" triggers, `loop`'s invocation authorisation, and `loop`'s "Sensitivity is not a routing input" rule — the human chose to keep all three.
- Findings outside `skills/` (CHANGELOG.md, `.spades/`, `docs/`, root project documents, `agents/`) and findings that skillspector's own LLM check rejected (including the `architecture` template placeholder comments and the `deliver`, `plan` and `research` triggers).
- Adding a skillspector baseline, exclusion list or CI job.
- Changing when `newproject`'s Step 3 wave runs relative to the draft confirmation.

## Risk / Unknowns

- In HTML mode, `newproject` asks the draft confirmation after Step 3's wave has run, so the `.md`, `.html` and any Linear Project already exist when the human confirms. Decision: word the disclosure accurately per mode, with no behaviour change.
- Step 6 already prints `✓ Active project: <slug>` and the bootstrap path runs Step 6 before returning to Setup, so the bootstrap criterion may already hold. Decision: the Plan checks it and adds wording only where the human is not told.
- Narrower triggers may stop a skill auto-loading on a phrase people rely on.
- skillspector findings are LLM-judged; a re-scan is supporting evidence, not proof.

## Delivery Preference

Mostly AI-delivered: description and skill-body wording edits, version
bumps and a CHANGELOG entry.

## Audit Trail

<!-- Appended by /spades:plan, /spades:approve, /spades:evaluate,
     /spades:ship, /spades:close. -->

- 2026-10-27: Scope created from the human's triage of skillspector findings (seven fixes chosen, three findings kept as designed). The human chose to run `/spades:loop` on it. Written by worker-file-scope using subagent-dispatch; backend local, review format cli.
- 2026-10-27: Plan drafted — P-narrow-skill-triggers-and-newproject-disclosure-8XWy.
- 2026-10-27: Plan P-narrow-skill-triggers-and-newproject-disclosure-8XWy approved with notes by AI (/spades:loop) — routing: ai.
- 2026-10-27: Scope worktree established. Branch: fix/narrow-skill-triggers-newproject-disclosure. Base: ff25ddd62892823e08a7926fc123d689a8df76fd.
