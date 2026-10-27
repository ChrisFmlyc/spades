---
id: P-narrow-skill-triggers-and-newproject-disclosure-8XWy
id_suffix: 8XWy
scope: S-narrow-skill-triggers-and-disclose-newproject-actions
title: "Narrow skill triggers and newproject disclosure"
depends_on: []
status: shipping
delivery: ai
evaluation: ai
deliverable_type: code
created: 2026-10-27
updated: 2026-10-27
---

# Narrow skill triggers and newproject disclosure

## Technical Approach

Rewrite the `description:` frontmatter of `approve`, `evaluate`,
`newproject`, `review` and `status` so every trigger phrase names a SPADES
Scope, Plan or Project, keeping each description's what-then-when shape,
and bring the two README skill-table rows that quote those triggers into
line. Rewrite `newproject`'s Step 1 draft confirmation so the question says
what the record and any Linear Project mean in each review mode, and verify
that the Setup-bootstrap path already reports the active project. Ship as
plugin 6.8.1 with patch bumps for the five skills and a CHANGELOG entry.

## Risks & Assumptions

- Assumption: harnesses choose skills from the description alone, so narrowing phrases changes auto-loading only; explicit `/spades:<name>` invocation is unaffected.
- Risk: someone relying on a dropped phrase ("review this", "evaluate this") no longer auto-loads the skill. Each replacement keeps the same verb and ties it to a Scope or Plan.
- Risk: the HTML-mode wording misstates the order of writes. Step 3's wave runs before the HTML-mode confirmation, so the HTML-mode sentence says the record already exists rather than that confirming will write it.
- Assumption: Step 6's `✓ Active project: <slug>` line prints on the Setup-bootstrap path, since Step 4 continues "through the optional lead step and confirmation before returning to Setup". If Task 4 finds otherwise, it adds one sentence to Step 4.
- Risk: the lints cannot run on the local distro Node (no TypeScript stripping); the PR's CI run is the lint authority.
- Risk: skillspector findings are LLM-judged and vary between runs; a re-scan is supporting evidence, not an acceptance gate.
- No ANTI-PATTERNS.md conflict: one Scope, one PR, no new skill.

## Tasks

### Task 1: Narrow the five skill descriptions
- **Posture:** straight-through — the target wording is fixed below, so there is nothing to discover or pin down first.
- **Effort:** brief
- **Depends on:** none
- **Description:** Replace the `description:` value on line 3 of five `SKILL.md` files.
- **Approach:** Each value becomes exactly:

  ```text
  skills/approve/SKILL.md
  Presents a SPADES Plan for human review against the approval checklist, then records the routing decision (AI / human / hybrid) on the Plan. Use when a Plan has been drafted and needs approval, when someone says "approve this plan" or "approve P-…", or when a Plan is in status `draft`.

  skills/evaluate/SKILL.md
  Checks delivered output against the Scope's acceptance criteria. Returns PASS / PARTIAL / FAIL. Use after `/spades:deliver` has completed delivery, when someone says "evaluate this plan", "evaluate P-…" or "check this against the acceptance criteria", or when a Plan is in status `evaluating`. Quick-path items (`/spades:quick`) skip the full evaluation and validate the PR directly.

  skills/newproject/SKILL.md
  Creates a new SPADES Project record — the long-lived container above Scopes (a repo, a set of repos, a service). Use when a new initiative needs its own SPADES Project, when someone says "new SPADES project", "create a SPADES project" or "set up a SPADES project for X", or after /spades:setup asks for an active project that doesn't exist yet. Writes .spades/projects/<slug>.md and (when backend is Linear) creates the corresponding Linear Project.

  skills/review/SKILL.md
  Provides an independent second opinion on a SPADES Scope, Plan, or both. Spawns a PANEL of four persona subagents in parallel (scope-guardian, architecture-strategist, security-lens, adversarial-reviewer), merges their structured findings, and presents a single tiered report. Use when someone wants a Scope or Plan reviewed or challenged — "review this Scope", "review P-…", "second opinion on this Plan", "outside view on this Scope", "challenge this Plan" — or when offered during /spades:approve. Non-blocking — informs the human but never gates shipping.

  skills/status/SKILL.md
  Shows the current SPADES phase, progress, and dependency graph for active work. Use when someone asks where SPADES work stands — "where are we on this Scope", "what's the SPADES status", "show Plan progress". Renders the Plan dependency graph so the human can see which plans are unblocked vs waiting.
  ```

- **Tests:** The frontmatter lint parses all five (CI). A grep finds none of the retired bare phrases in these descriptions.

### Task 2: Align the README skill table
- **Posture:** straight-through — two rows quote the retired phrases verbatim.
- **Effort:** brief
- **Depends on:** Task 1
- **Description:** In `plugins/spades/README.md`, the `/spades:review` and `/spades:status` rows list **Use when you say:** phrases that Task 1 retires.
- **Approach:** The review row's phrases become "review this Scope", "second opinion on this Plan", "challenge this Plan"; the status row's become "where are we on this Scope", "what's the SPADES status", "what should I work on next". The approve, evaluate and newproject rows quote no triggers and stay as they are.
- **Tests:** A grep of the README finds none of the retired bare phrases.

### Task 3: Say what newproject's draft confirmation does
- **Posture:** straight-through — one paragraph, wording below.
- **Effort:** brief
- **Depends on:** none
- **Description:** Step 1 § Confirm the draft asks *Use `<slug>` as drafted* without saying what follows.
- **Approach:** Its second paragraph becomes: "Then confirm the draft, slug included, with one question: *Use `<slug>` as drafted* *(Recommended)* / *Change something*, the change arriving through *Other* or a short follow-up. CLI mode presents the draft in the CLI review pane on that question before the write and says that confirming writes `.spades/projects/<slug>.md` and, with `backend: linear`, creates or binds its Linear Project. HTML mode asks it once Step 3 has opened the page and says that the record is written and, with `backend: linear`, which Linear Project it is bound to; a change is then a targeted `.md` edit plus a re-render." The first sentence of the paragraph block (asking about unsupported fields together) is unchanged.
- **Tests:** A read-through against Steps 2 and 3 confirms the per-mode order of writes; a grep finds the new sentences.

### Task 4: Verify the bootstrap path reports the active project
- **Posture:** discover-first — the Scope left open whether the human is already told.
- **Effort:** brief
- **Depends on:** none
- **Description:** Scope acceptance criterion 7.
- **Approach:** Trace Step 4's bootstrap branch through Steps 5 and 6 and confirm that Step 6's block, including `✓ Active project: <slug>`, prints before the return to Setup. When it does, record the trace as evidence and leave Step 4 unchanged. When it does not, add one sentence to Step 4's bootstrap branch saying that the human is told the Project is now active.
- **Tests:** The trace, quoted in the evaluation.

### Task 5: Release gate — versions and CHANGELOG
- **Posture:** straight-through — mechanical under `AGENTS.md § Versioning`.
- **Effort:** brief
- **Depends on:** Tasks 1–4
- **Description:** Plugin 6.8.0 → 6.8.1 in `plugins/spades/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (`metadata.version` and the `spades` entry) and `plugins/spades/.spades/version` (`spades_version`). Skills: approve 3.4.1 → 3.4.2, evaluate 3.10.1 → 3.10.2, newproject 3.8.1 → 3.8.2, review 3.9.5 → 3.9.6, status 3.6.4 → 3.6.5. `agents_version`: n/a. CHANGELOG: a `## [6.8.1] — 2026-10-27` patch entry describing the narrowed triggers and the newproject confirmation.
- **Approach:** Edit each field, then report the four-line release gate with old → new values before committing.
- **Tests:** CI lints (frontmatter, version presence, release gate); a grep shows all four plugin version values equal 6.8.1.

## Delivery Sequence

1. Tasks 1, 3 and 4 (independent; start immediately)
2. Task 2 (after Task 1)
3. Task 5 (after Tasks 1–4)

## Testing & Verification

- A grep finds none of "approve this", "review the plan", "evaluate this", "check if this is done", "verify the output", bare "new project" / "create a project" / "set up a project for X", bare "review this" / "challenge this", or "any question about current state" as quoted triggers in the five descriptions or the README table.
- `scripts/lint/run-all.sh` passes in the PR's CI run.
- The release gate shows four matching 6.8.1 plugin values, five skill bumps and the CHANGELOG entry.
- Supporting evidence: `skillspector scan` of each changed skill directory, expecting no confirmed SQP-1 finding on the five descriptions and no confirmed newproject disclosure finding. Recorded, not gating.
- Shipped means the delivery PR is squash-merged to main with green CI.

## Audit Trail

<!-- Appended by /spades:approve, /spades:deliver, /spades:evaluate,
     /spades:ship, /spades:close. -->

- 2026-10-27: Plan drafted by AI (/spades:loop); dependencies none; deliverable_type code. Written by worker-file-plan using subagent-dispatch; backend local, review format cli.
- 2026-10-27: Approved by AI (/spades:loop) — routing: ai. Notes: 6/6 checks clean. Task 3 replaces the text of § Confirm the draft from "Then confirm the draft" to the end of that single paragraph; its first sentence stays.
- 2026-10-27: Deliver phase started — routing: ai, branch: fix/narrow-skill-triggers-newproject-disclosure.
- 2026-10-27: Deviation (Task 3): the HTML-mode sentence reports whether the Linear binding is done or pending rather than naming the bound project, because Step 3 allows a failed or deferred binding.
- 2026-10-27: Task 4 verified with no change: Step 4's bootstrap branch continues through Step 6, whose block prints `✓ Active project: <slug>` before the return to Setup.
- 2026-10-27: Deliver phase complete — routing: ai. Tasks completed: 5. Commits: bd5f1f8, 75e91fb, a1647f3, 1b3716e.
- 2026-10-27: Plan ready for evaluation — routing: ai.
- 2026-10-27: Evaluation started — routing: ai.
- 2026-10-27: Verification plan agreed:
    - C1: AI (approve description: Plan-specific triggers; no bare "approve this" / "review the plan") — PASS (line 3 carries "approve this plan" and "approve P-…"; neither retired phrase present)
    - C2: AI (evaluate description: Plan / acceptance-criteria triggers; no bare "evaluate this" / "check if this is done" / "verify the output") — PASS ("evaluate this plan", "evaluate P-…", "check this against the acceptance criteria"; retired phrases absent)
    - C3: AI (newproject description: "SPADES project" triggers; bare project phrases gone; /spades:setup trigger kept) — PASS ("new SPADES project", "create a SPADES project", "set up a SPADES project for X"; /spades:setup trigger kept)
    - C4: AI (review description: every trigger tied to a Scope or Plan) — PASS (all five triggers name a Scope, Plan or P-…; no bare "review this" / "challenge this" / "outside view" / "second opinion")
    - C5: AI (status description: no "any question about current state"; triggers name SPADES work) — PASS ("where are we on this Scope", "what's the SPADES status", "show Plan progress"; catch-all removed)
    - C6: AI (read newproject § Confirm the draft against Steps 2–3 for CLI and HTML write order) — PASS (CLI: confirm precedes Step 2 bind/create and Step 3 writes; HTML: asked after Step 3, "bound or still pending" covers lines 192–194)
    - C7: AI (trace newproject Step 4 bootstrap branch through Step 6's report) — PASS (Step 4 lines 202–204 continue through Step 6, whose block prints "✓ Active project: <slug>" before the Setup return)
    - C8: AI (release gate values; emulate lint-skill-frontmatter and lint-local-frontmatter rules on changed files; CI result asserted at loop Stage 8) — PASS (four plugin values 6.8.1; five skill bumps; [6.8.1] entry; 23 skills and all scope/plan records pass emulated lint rules; CI asserted at Stage 8)
    - Q1: AI (`git diff --stat ff25ddd..HEAD` touches only planned files) — PASS (12 planned files only; uncommitted changes are this run's audit lines)
    - Q2: AI (README skill table matches the new review and status triggers) — PASS (review and status rows list the new phrases)
- 2026-10-27: Verification plan APPROVED by AI (/spades:loop).
- 2026-10-27: Evaluation — verdict: PASS. Notes: All ten AI rows pass. The five descriptions tie every trigger to a Scope, Plan or SPADES Project; newproject's draft confirmation states its writes accurately in CLI and HTML mode; the bootstrap path already reports the active project in Step 6. A skillspector re-scan of the five skills shows no remaining trigger or fan-out finding; it still flags newproject Step 4's bootstrap line (EA2) read alone, which Step 6's report answers. CI lints are asserted at loop Stage 8. Confirmed by AI (/spades:loop).
- 2026-10-27: Leads handoff receipt (worker-leads, revision 1b3716e): captured L-lint-wrappers-need-node-type-stripping-xU3s (eval:8XWy:local-lint-node-ts; GitHub #118 verified) and L-skillspector-plugin-root-scan-saturates-qgwl (eval:8XWy:skillspector-plugin-root-noise; GitHub #119 verified); eval:8XWy:skillspector-newproject-ea2 on-scope (row C7); eval:8XWy:skillspector-review-template-sqp3 and eval:8XWy:skillspector-newproject-tp4 excluded for insufficient evidence. Lead files ship with this Scope's PR.
- 2026-10-27: Leads checked — source: evaluate; result: L-lint-wrappers-need-node-type-stripping-xU3s, L-skillspector-plugin-root-scan-saturates-qgwl.
- 2026-10-27: Loop — evaluate sign-off: AI (all 10 rows AI-verified).
- 2026-10-27: Ship phase started — deliverable_type: code.
