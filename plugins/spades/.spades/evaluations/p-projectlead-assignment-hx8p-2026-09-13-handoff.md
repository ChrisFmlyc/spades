# Newproject / Projectlead handoff instruction scenarios

Date: 2026-09-13. Evaluator: isolated `projectlead_handoff_scenarios` agent.
Revision: `bbeff04f678312a4c0dd1c56c5bf87a1a1e7651b` plus authorized uncommitted delivery changes in `/Users/chrispowell/code/spades-worktrees/feat-projectlead-assignment`.

## Method and fixtures

Read the approved Scope and Plan, the actual Newproject and Projectlead skills, Setup Steps 7–9, and the Framework Project lead assignment, Bootstrap Order, Scope Worktrees, and Carry-Forward contracts. Also read the installed repo:newbranch skill to resolve the requested main/dirty-record scenario. This is a bounded instruction walkthrough under the approved Plan, not a broad review.

Unless overridden below, use a configured local backend, CLI output, established `docs/projects` worktree, new Project `customer-portal`, old active Project `legacy-service`, and supplied identity `Chris Powell`. Both Projects have valid matching IDs. Creation questions for title, description, repositories, owners and slug have been answered and CLI record presentation confirmed. Existing owners remain distinct from lead. An unknown person answer is provided only when the actual skill asks. All Linear responses below are controlled hypothetical outcomes, not live calls.

## Scenario results

### H01 — Standalone local Newproject, Yes, new Project active: PASS

Newproject Step 3 writes customer-portal.md. Step 4 asks active-project choice; answer Set as active project updates config.project. Step 5 asks Add a project lead? exactly once; answer Yes invokes `projectlead --project customer-portal` inline. Helper resolves explicit Project and local backend, shows unassigned, then asks Who is the project lead? because no identity was supplied. Answer Chris Powell is displayed for that Project; local mode needs no Linear confirmation. Step 4 rechecks the canonical record and established context, writes lead, updated date and dated audit event, and reads back. No Linear call is made. Return outcome/customer-portal/lead to Newproject; it rereads the canonical record and confirms created, active customer-portal, lead Chris Powell, and the next Scope command.

### H02 — Standalone Newproject, No: PASS

After creation and active choice, answer No to Step 5. No helper invocation, person question, lookup or assignment. Newproject confirms canonical lead Unassigned. Owners are preserved; they never supply an implicit lead. Dismissal/cancellation of this optional question follows the same path.

### H03 — Identity supplied in Newproject request: PASS

Request includes lead identity chris@example.com. Newproject retains it independently from its title/description/repos/owners gathering. It still asks Add a project lead? after creation. Yes forwards the identity as data with `--project customer-portal`; Projectlead Step 2 uses it without asking Who is the project lead? again. Local writes that supplied string; in Linear mode it remains a lookup query and does not bypass final confirmation. No discards the optional assignment rather than auto-assigning from the request.

### H04 — Yes while a different Project remains active: PASS

Step 4 answer Leave the active project unchanged preserves config.project=legacy-service and its Linear project ID when present. Step 5 still invokes helper with customer-portal explicitly. Helper resolves and writes customer-portal.md and, in Linear mode, its own linear_project_id. Its binding-consistency check applies to config only when the target is active, so the old active binding does not redirect or reject this valid target. Confirmation reports active unchanged. No write targets legacy-service.

### H05 — Linear creation succeeds, lead confirmed: PASS

Controlled creation response returns Project ID PNEW. Newproject persists customer-portal.md.linear_project_id=PNEW before Step 5. After Yes and supplied query, helper resolves PNEW; lookup returns stable user UCHRIS with name Chris Powell and email chris@example.com, with all pages exhausted. It rereads that user's details and the remote Project/current lead, shows the name/email and target, then asks Assign this lead / Choose someone else / Cancel. Controlled answer Assign this lead authorizes UCHRIS only on PNEW. Framework requires another remote-current-lead check before `save_project({id:PNEW,lead:UCHRIS})`. Controlled read-back reports UCHRIS. Only then local fields become lead=chris@example.com and linear_lead_id=UCHRIS, with date/audit and local read-back. Newproject confirms verified binding and canonical lead. Owners and unrelated remote fields are not assigned.

### H06 — Linear creation fails and retry is deferred: PASS

Controlled Step 3 Linear worker returns failure; file worker succeeded. Newproject keeps local record, reports failure, offers retry; controlled answer defers. Required binding remains unavailable. Step 4 still resolves the active choice. Step 5 prerequisites fail, so no Add a project lead? question, helper call, user lookup or lead write occurs. Step 6 reports local creation and pending binding, omits the Linear success line, and explains binding is prerequisite. It does not claim a remote Project exists. A later successful bind permits the offer; Projectlead itself never recursively invokes Setup/Newproject.

### H07 — Switch active after failed Linear binding: PASS

Start with config.project=legacy-service and config.linear.project_id=POLD. Same failed/deferred creation as H06; answer Set as active project in Step 4. Actual prose explicitly sets project=customer-portal and removes POLD from config.linear.project_id. It does not leave the new local Project paired with the old remote Project. No lead handoff occurs until PNEW exists and is persisted. Choosing Leave unchanged instead preserves both old fields (H04/H06).

### H08 — Setup bootstrap, project unset, Yes: PASS

Setup Step 7 writes selected backend/output config with project unset (Linear team only if applicable). Step 8 calls Newproject inline. After successful creation/binding, Newproject Step 4 sets customer-portal active without the standalone active-choice question. It then asks Add a project lead?; Yes runs the explicit-target helper and completes assignment as H01/H05. Newproject rereads and confirms, then returns to Setup. Setup resumes Step 9 version stamping and remaining scaffolding. No early return at Step 4, no invocation recursion, and no standalone Scope next-step replaces Setup's continuation.

### H09 — Setup bootstrap, project unset, No: PASS

Same Setup config/creation order as H08. Newproject sets the new active Project without asking and asks the optional lead question. No skips helper and confirms Unassigned before returning to Setup Step 9. Setup remains responsible for remaining scaffolding and final next steps. A canceled optional question has the same continuation; it is not project-creation cancellation.

### H10 — Cancellation inside Projectlead: PASS

After Yes, either cancel Who is the project lead? or, in Linear mode, cancel final assignment confirmation. Helper returns cancellation before mutation; existing lead survives. Newproject explicitly treats this as optional-assignment cancellation, preserves its earlier active choice and existing new record, rereads that record and proceeds to confirmation. When bootstrapped, it returns to Setup normally. Setup Step 8's creation-failed/human-cancels fallback does not apply to this distinct helper outcome because Newproject expressly reports creation complete.

### H11 — Remote assigned, local record pending: PASS

Linear target/user are resolved and confirmed as H05. Controlled save plus remote read verifies UCHRIS, then local write fails (assume no local field change). Helper returns remote assigned, local record pending and retains Project/user identity. Newproject rereads the canonical record (still Unassigned in this fixture), replaces the lead-success line with the partial outcome, distinguishes the verified remote user from persisted local state, and provides an explicit-target retry such as `/spades:projectlead chris@example.com --project customer-portal`. Creation remains complete. Same-invocation retry rereads remote state and retries local write when still UCHRIS; if remote changed it requests renewed confirmation. Fresh invocation reruns resolution and confirmation, then reconciles already-assigned remote identity. No duplicate success or blind remote re-write is implied.

### H12 — HTML caller refresh: PASS

Newproject initial HTML worker owns customer-portal.html and has absolute output path as open_path. Yes/helper inherits this caller review context. After assignment, Projectlead Step 5 uses Newproject's owned template and full payload with optional canonical lead fields; open_path=null refreshes without opening another surface. Newproject rereads canonical Markdown before final confirmation/page state. Absent lead fields remain omitted and render Unassigned; owners retain their block. A render failure preserves the assignment and returns presentation error separately. A standalone Projectlead invocation uses the Project as its initial review surface instead, per the explicit final-step distinction. This evaluates invocation/payload intent; actual HTML rendering/escaping is separately tested by the parent workflow.

### H13 — Standalone Projectlead on main with uncommitted Newproject record: PASS (targeted rerun)

Fixture: current branch main, config exists, customer-portal.md is newly created and uncommitted in the current checkout, and active target resolves correctly. Helper Step 1 reads and verifies that current local record and retains its absolute checkout path. Step 2 consumes a supplied identity (or asks once). Local Step 3 displays the identity; Step 4 now explicitly uses the Project checkout resolved in Step 1, including Newproject's just-written record. Re-read confirms identity/existing lead are unchanged, so the local driver writes lead, date and audit entry into that same file and reads back. No branch switch, worktree creation, dirty-default cleanliness gate or lost uncommitted-record lookup is invoked by assignment. A Linear variant still performs lookup/final confirmation/read-before-write/remote verification before writing this same local file. Current-run inclusion decisions remain in force; all unrelated edits remain untouched. The skill returns the verified result and leaves later commit/publication to the caller's normal workflow, which still enforces its branch and inclusion rules.

The first snapshot unnecessarily referenced Scope Worktrees from Projectlead Step 4 and blocked here through repo:newbranch's dirty-default check. The coordinator refined Step 4 to use the resolved Project checkout. This rerun reads that actual revised prose and verifies the final behavior. It does not claim a commit on main is allowed.

## Findings and limits

No contradictory target selection, duplicate identity ask, premature lead offer, bootstrap return, cancellation mutation, partial-success reporting, or checkout continuity instruction remains in H01–H13. The affected dirty-main scenario was rerun after the coordinator fixed its unnecessary worktree dependency; all 13 final traces pass.

These are instruction-level traces of the deliverable Markdown using explicit hypothetical user/tool outcomes. No Linear MCP lookup, Project creation/update, Git operation, repo mutation, or real assignment was executed. No evidence is claimed for installed harness dispatch mechanics, MCP availability/authorization, real service pagination or remote eventual consistency. This agent wrote only this report in /tmp. Hashes below identify the instruction snapshot inspected; coordinated edits after these reads require targeted rerun of affected traces.

## Source snapshot hashes

- `plugins/spades/.spades/scopes/S-projectlead-assignment.md`: SHA-256 `5e02f9abbf2599195d1086d35436dfc766aaae7e37e8ea1b1054b79933829605`
- `plugins/spades/.spades/plans/P-projectlead-assignment-hX8p.md`: SHA-256 `da009bd8256a5570cae5398db8b98b49c4045c9e0fa3aaac45b09fcb487385f4`
- `plugins/spades/skills/newproject/SKILL.md`: SHA-256 `4272883cf3f8b32db25d7b10c463b82a62f31e460c352a74c9e3e8242b16e522`
- `plugins/spades/skills/projectlead/SKILL.md`: SHA-256 `df8fa44e51687ddd5ed61e0c2f478e66f57ed640a7c4d12d1b31ef1e9749f4cd`
- `plugins/spades/skills/setup/SKILL.md`: SHA-256 `83c1a7e4a634a827a297f4471af8c9cb6a4060f39a7e98d7754e12feac50a4ac`
- `plugins/spades/docs/FRAMEWORK.md`: SHA-256 `bf2b5395bbae9cfc2733008e7d4e95823f7bd242189e7eeb182d73ada8d4c8d4`
