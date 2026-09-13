# Projectlead instruction scenario execution

Date: 2026-09-13. Executor: isolated Task 5 scenario agent.

## Method and scope

Read the actual uncommitted implementation, including the final Step 2/3 identity-replacement refinement, at `/Users/chrispowell/code/spades-worktrees/feat-projectlead-assignment`; verified branch `feat/projectlead-assignment` and HEAD `bbeff04f678312a4c0dd1c56c5bf87a1a1e7651b`. Read Scope `S-projectlead-assignment`, approved Plan `P-projectlead-assignment-hX8p`, `skills/projectlead/SKILL.md`, the Framework Project lead assignment/ID/worktree/carry-forward/output contracts, and Newproject's inherited HTML payload.

These are instruction executions with controlled input and simulated filesystem/MCP responses. Ordered traces below are decisions made by following the Markdown workflow. They are not live integration tests, executable product tests, or evidence of production writes. No live Linear tools were invoked. Only this report was written. All mentioned Project writes and MCP calls are intended operations in the simulation. The default fixture repository is an established writable feature worktree with approved inclusion decisions. The final Step 4 was reread after its caller-checkout refinement: record updates use the Project checkout resolved in Step 1, including Newproject’s newly written record, preserving caller context and existing inclusion decisions. No branch creation or commit is part of these executions. Default output mode is CLI unless stated.

Evidence shorthand:

- **S1**: Projectlead lines 28–46: prerequisite checks, binding validation, retained explicit target.
- **S2**: Step 2: supplied/prompted identity and data treatment.
- **S3**: Step 3: backend handling, selection, final confirmation.
- **S4**: Step 4: rereads, writes, verification, idempotency, partial state/retries.
- **S5**: Step 5: output, helper return, persistence.
- **F**: Framework lines 357–422, Project lead assignment; Project ID lines 220–224.
- **H**: Newproject lines 128–162, `worker-html-project` payload and raw-script YAML serialization.

Scope criteria are numbered in their existing order, AC1–AC7. PASS means the observed instruction trace satisfies the relevant criterion for the supplied controlled outcome. This report alone does not certify all AC6 integration branches or AC7 lints/schema/release checks.

## Controlled fixture

Active project: `customer-portal`, title `Customer Portal`; local canonical path `<fixture>/.spades/projects/customer-portal.md`. Project ID P = `10000000-0000-4000-8000-000000000001`; config and local Linear binding agree. Existing lead: `old@example.com`, ID OLD = `20000000-0000-4000-8000-000000000001`. Other preserved metadata: owners `[owner@example.com]`, description `Customer service portal`, repo `https://example.com/portal`, `status: active`, `created: 2026-01-01`, existing audit history. Initial `updated: 2026-09-01`.

Lookup users:

- U1 = `30000000-0000-4000-8000-000000000001`, Chris Powell, `chris@example.com`.
- U2 = `30000000-0000-4000-8000-000000000002`, Chris Pine, `pine@example.com`.
- U3 = `30000000-0000-4000-8000-000000000003`, Chris Park, `park@example.com`.
- OTHER = `30000000-0000-4000-8000-000000000004`, Pat Example, `pat@example.com`.

MCP names denote intended equivalent operations, with symbolic IDs expanded to the valid UUIDs above. Reads that return a Project include its ID and current lead. Successful writes return normally unless a scenario overrides them.

A successful changed local write means: edit only target `lead` and optional `linear_lead_id`; set `updated: 2026-09-13`; append a dated audit entry naming the identity and verified UUID in Linear mode; preserve owners and unrelated fields; read back those fields and audit entry before reporting success. Reading the target immediately before writing compares its identity and previously displayed lead, as required by S4.

## Ordered executions

### 1. Missing configuration — PASS (AC1)

Input `/spades:projectlead chris`; `.spades/config` is absent.

1. Read config → absent.
2. Report `Run /spades:setup first to initialize SPADES.` Stop.

Asks: none. Project writes: none. MCP calls: none. The supplied name does not bypass initialization. Evidence: S1.

### 2. Missing active slug — PASS (AC1)

Input `/spades:projectlead`; config exists with `backend: local` and no `project:`; no explicit slug.

1. Read config.
2. Resolve active target → unset.
3. Stop with `/spades:newproject` or target-correction guidance.

Asks: no person question. Writes and MCP calls: none. Evidence: S1, F.

### 3. Path traversal target — PASS (AC1)

Input `/spades:projectlead chris --project ../../outside`.

1. Read config.
2. Validate explicit slug against lowercase `[a-z0-9-]{1,64}`, no leading hyphen, no `..` → invalid.
3. Stop with target correction guidance before constructing or reading an outside Project path.

Asks: none. Writes and MCP calls: none. Evidence: S1, Framework Project ID.

### 4. Existing configuration, missing local Project — PASS (AC1)

Input `/spades:projectlead`, active `customer-portal`, backend Linear; local Project absent.

1. Read config and validate slug.
2. Read canonical Project → missing.
3. Report `Project customer-portal has no local record. Run /spades:newproject to create or bind it before assigning a lead.` Stop.

Asks: none. Writes and MCP calls: none, including no remote Project discovery. Evidence: S1.

### 5. Local direct email with stale Linear identity — PASS (AC2, AC3)

Input `/spades:projectlead chris@example.com`; backend local; old local fields include OLD.

1. Resolve active Project and display Customer Portal / old@example.com.
2. Accept the supplied email without asking for it again.
3. Display Customer Portal / chris@example.com as intended local assignment.
4. Reread local target → same ID and old lead.
5. Write `lead: "chris@example.com"`, remove `linear_lead_id`, update date, append `2026-09-13: Project lead assigned to chris@example.com.`
6. Read back lead, absent stale ID, preserved owners/other metadata, and audit entry.
7. Return project slug, lead and successful local assignment.

Asks: none. MCP calls: none. An unrelated staged source edit and an excluded unstaged README edit remain untouched: this operation changes only Project lead metadata/audit, does not stage or commit, and does not transfer records to another checkout. Evidence: S2, S3 Local, S4, F.

### 6. Local prompted full name — PASS (AC2, AC3)

Input `/spades:projectlead`; backend local.

1. Resolve and display active Project/current lead.
2. Ask exactly `Who is the project lead?` → controlled answer `Chris Alex Powell`.
3. Preserve the complete name and display it for Customer Portal.
4. Reread local target; write `lead: "Chris Alex Powell"`, clear stale ID if present, date and append audit.
5. Read back and report success.

Asks: one identity question, no unnecessary second identity question or Linear confirmation. MCP calls: none. Evidence: S2, S3 Local, S4.

### 7. Linear exact email, user confirmed — PASS (AC2, AC4, AC5)

Input `/spades:projectlead chris@example.com`.

1. Read/validate config and local target/binding; display current lead.
2. Inspect available MCP capabilities → lookup, get-user, get-project and update supported.
3. `list_users({query: "chris@example.com"})` → `[U1]`, complete page.
4. Show lookup name/email. `get_user({id: U1})` → current Chris Powell / chris@example.com, usable account.
5. `get_project({id: P})` → OLD. Show target/current lead and candidate.
6. Ask `Assign Chris Powell (chris@example.com) as the lead of Customer Portal?` with Assign this lead / Choose someone else / Cancel → Assign this lead.
7. Reread local target/binding; `get_project({id: P})` → OLD still matches confirmation.
8. `save_project({id: P, lead: U1})`, with no unrelated update fields.
9. `get_project({id: P})` → U1 verifies assignment.
10. Reread local target as needed; write `lead: "chris@example.com"`, `linear_lead_id: U1`, date/audit; read back local fields/audit.
11. Report verified remote/local result.

Asks: final confirmation only. Exact email still requires it. Evidence: S1–S4, F.

### 8. Two matches plus a third on the next page — PASS (AC4, AC5)

Input `/spades:projectlead chris`.

1. Resolve Project/binding and inspect capabilities.
2. `list_users({query: "chris"})` → `[U1, U2]`, next cursor `page-2`.
3. `list_users({query: "chris", cursor: "page-2"})` → `[U3]`, no next cursor.
4. Ask user to choose from Chris Powell / chris@example.com, Chris Pine / pine@example.com, Chris Park / park@example.com → controlled answer Chris Park / park@example.com.
5. `get_user({id: U3})` → U3 current identity; `get_project({id: P})` → OLD.
6. Ask final assignment confirmation for Customer Portal and Chris Park / park@example.com → Assign this lead.
7. Reread target/local identity and remote OLD; `save_project({id: P, lead: U3})`; `get_project({id: P})` → U3.
8. Write/read-back local `lead: "park@example.com"`, UUID U3 and dated audit. Report success.

No selection or write occurs from the first page alone. All three identities appear in selection. Evidence: S3, F pagination/selection contract.

### 9. Zero matches — PASS (AC4, AC5)

Input `/spades:projectlead nobody@example.com`.

1. Validate target/binding/capabilities.
2. `list_users({query: "nobody@example.com"})` → empty, search complete.
3. Offer corrected name/email or cancellation → Cancel.
4. Return cancelled; preserve original local and remote lead.

MCP mutations: none; no `get_user` for an invented ID, no creation/invitation. Local writes: none. Evidence: S3 No match, F.

### 10. Missing MCP capability — PASS (AC4, AC5)

Two controlled subcases:

A. No lookup capability. Resolve valid Linear target, inspect available capabilities → no workspace user lookup equivalent. Explain unavailable lookup; offer retry/cancel → Cancel. No user guessed, no local write, no backend fallback or mutation.

B. Lookup works, update capability absent. Inspect capabilities → no project-lead update equivalent. Return explicit missing-update error with assignment pending. No `save_project`, no local assignment change. If inspection is delayed until driver assignment, lookup/confirmation may already have occurred, but a write still cannot proceed. The exact prompt for missing update is not prescribed beyond explicit error; retry can begin when support exists.

Evidence: F explicitly requires capability inspection and explicit errors for missing lookup/update, S3 unavailable lookup, S4 failure handling.

### 11. Cancellation after a match — PASS (AC4, AC5)

1. Exact-email lookup returns U1; get current U1 and Project P/OLD.
2. Display resolved identity and target/current lead; ask final Assign / Choose someone else / Cancel → Cancel.
3. Return cancelled without assignment.

MCP calls: `list_users`, `get_user`, `get_project` only. Local fields, date and audit unchanged; no `save_project`. Evidence: S3 lines 84–88, F cancellation.

### 12. Remote lead changes after confirmation — PASS (AC5)

1. Perform lookup and confirmation of U1 for P with displayed remote OLD as in case 7.
2. Before update, `get_project({id: P})` → OTHER instead of OLD.
3. Return conflict; display current Pat Example / pat@example.com and candidate U1. Renew final assignment confirmation → controlled answer Cancel.
4. Stop without `save_project` or local write; retain original local metadata, remote OTHER remains as supplied by the fixture.

A previous confirmation does not authorize silently overwriting newly observed state. Evidence: S4 lines 95–98, F explicit read-before-write conflict. Limitation: the contract acknowledges this is not atomic compare-and-swap; a change after the reread cannot be excluded by the available operations.

### 13. Remote write times out, read shows selected ID — PASS (AC5)

1. Complete U1 confirmation and matching prewrite reads.
2. `save_project({id: P, lead: U1})` → timeout, completion unknown.
3. Keep prior local lead intact; report/retain pending remote uncertainty rather than success.
4. `get_project({id: P})` → U1. This read, not the timeout, establishes successful remote assignment.
5. Do not repeat the already-completed remote update. Reread and reconcile the local target to chris@example.com / U1, update date/audit, read back.
6. Report verified remote/local success after local verification.

Exactly one intended remote write. Evidence: S4 lines 115–120, F uncertain-write and idempotency rules.

### 14. Remote verified, local write fails, retry succeeds — PASS (AC5)

1. Lookup, confirm, prewrite reread, `save_project({id: P, lead: U1})`, postwrite `get_project({id: P})` → U1.
2. Local write attempt → controlled permission error before modifying bytes.
3. Return/report `remote assigned, local record pending`, retaining Project P/customer-portal and confirmed U1/chris@example.com plus local error. Do not report completion.
4. Controlled retry after permission repair: `get_project({id: P})` → still U1; reread local target → original OLD metadata.
5. Retry only local write, then read back lead, UUID, updated date and new audit entry. Return success.

No duplicate remote update, no duplicate audit entry. If retry read instead returned OTHER, S4/F require renewed confirmation before reconciliation. A fresh invocation must resolve Project/person again rather than blindly using this retained continuation state. Evidence: S4 lines 115–122, F recovery paragraphs.

### 15. Already matching remote and local — PASS (AC4, AC5)

Fixture remote lead U1; local lead chris@example.com and UUID U1; prior assignment audit already exists.

1. Validate/read Project and resolve supplied email via `list_users`, `get_user`.
2. `get_project({id: P})` → U1; show matching current lead and still ask final confirmation → Assign this lead.
3. Reread remote/local state → unchanged and matching.
4. Verify assignment; skip `save_project` and skip local write.
5. Return already-assigned verified result. Do not change `updated` or append an audit entry.

Evidence: S4 lines 105–113, F unchanged assignment/idempotency.

### 16. Explicit target while another project remains active — PASS (AC2 target override; AC5; helper portion of AC6)

The helper fixture runs in Newproject’s existing checkout with its newly written, uncommitted customer-portal record and an unrelated staged source edit. Config active `existing-service`, binding Q = `10000000-0000-4000-8000-000000000002`. Newproject calls `/spades:projectlead chris@example.com --project customer-portal` after creating/binding local customer-portal to P. Q and P differ legitimately.

1. Read config; resolve explicit `customer-portal`, validate its local ID and record's P binding.
2. Do not compare P to active existing-service's Q as a conflict: S1 applies config binding agreement only when the target is active.
3. Display Customer Portal/current lead; lookup U1 and get Project P.
4. Ask final confirmation explicitly naming Customer Portal → Assign this lead.
5. Prewrite read P, update only `save_project({id: P, lead: U1})`, verify P/U1.
6. Write/read back only customer-portal's canonical record in that same checkout; leave its other creation content and the unrelated staged edit intact. Do not create or switch worktrees. Preserve config `project: existing-service`, config Q, and existing-service Project record.
7. Return customer-portal result to Newproject. In HTML helper mode refresh customer-portal using inherited `open_path: null`; Newproject resumes its confirmation.

No remote call targets Q. Evidence: S1 lines 18–20, 39–46; S3 confirmation; S5 helper return. This executes the helper's receiving behavior, not Newproject's own offer timing/bootstrap sequence.

### 17. Identity containing quotes and a script-closing token — PASS for instructed data/serialization behavior (AC3, AC7 rendering contract)

Input identity supplied as data in local HTML mode:

```text
Chris "Quoted" </script><script>alert("x")</script> & {{spades.title}}
```

1. Resolve valid local target; use the entire input as identity, without execution or interpreting placeholder text as instructions.
2. Show the intended literal identity for the target; reread local Project.
3. Intended canonical frontmatter uses a quoted YAML scalar, for example:

```yaml
lead: 'Chris "Quoted" </script><script>alert("x")</script> & {{spades.title}}'
```

4. Set date and append dated audit naming the same literal identity; preserve unrelated fields; read back confirms the exact string.
5. Render inherited Newproject template: HTML-escape visible identity (`&lt;/script&gt;`, `&quot;`, `&amp;`) and encode literal template braces. Do not process the user's `{{spades.title}}` as a template instruction.
6. In embedded YAML raw-script context use YAML double-quoted escapes. Intended serialized lead:

```yaml
lead: "Chris \"Quoted\" \u003c/script\u003e\u003cscript\u003ealert(\"x\")\u003c/script\u003e \u0026 \u007b\u007bspades.title\u007d\u007d"
```

7. The embedded scalar has no literal closing script token, and YAML parsing restores the same identity. Apply the inherited string serialization to audit text embedded in raw-script YAML too. Report local assignment and page result independently; a renderer failure cannot undo the canonical assignment.

Asks: none. MCP calls: none. Evidence: S2 data preservation, S4 quoting, S5 inherited H payload; H explicitly specifies YAML Unicode escapes for raw-script `<`, `>`, `&`, and token braces. This is an instruction-derived rendering trace, not a parser/browser execution. Actual rendering round-trip verification is delegated separately in Task 5.

### 18. Direct argument, choose someone else, replacement email — PASS (AC2, AC4, AC5)

Final revised instructions were reread from the actual skill. Step 2 now uses the supplied identity only for the initial attempt and states that corrections replace prior input. Step 3 explicitly clears prior input on Choose someone else and asks for a replacement.

Input `/spades:projectlead chris@example.com`.

1. Resolve valid Project P/customer-portal and binding; inspect supported capabilities.
2. `list_users({query: "chris@example.com"})` → U1 only; `get_user({id: U1})` → Chris Powell / chris@example.com; `get_project({id: P})` → OLD.
3. Ask final confirmation for U1 and Customer Portal → controlled answer Choose someone else.
4. Clear `chris@example.com` as current input. No local or remote write. Return to Step 2 and ask `Who is the project lead?` → `pine@example.com`.
5. Store replacement input `pine@example.com`; `list_users({query: "pine@example.com"})` → U2 only. No repeated query for the original email.
6. `get_user({id: U2})` → Chris Pine / pine@example.com; `get_project({id: P})` → OLD.
7. Ask a new final confirmation for Chris Pine / pine@example.com and Customer Portal → Assign this lead. U1's prior selection confers no confirmation on U2.
8. Reread local target and remote P → unchanged OLD. `save_project({id: P, lead: U2})`; `get_project({id: P})` → U2.
9. Write/read-back local `lead: "pine@example.com"`, UUID U2, updated date and a single dated U2 assignment entry; preserve unrelated metadata/edits. Report verified success for U2.

Asks in order: U1 final confirmation; replacement identity; U2 final confirmation. Exactly one remote mutation, for U2 only. Evidence: revised S2 and S3 identity replacement, S4/F verification.

### 19. No match, corrected email — PASS (AC2, AC4, AC5)

Input `/spades:projectlead typo@example.com`.

1. Resolve valid Project/binding and inspect supported capabilities.
2. `list_users({query: "typo@example.com"})` → empty, complete search.
3. Offer corrected name/email or cancellation → controlled answer `chris@example.com`.
4. Replace current input with `chris@example.com` per revised Step 2. `list_users({query: "chris@example.com"})` → U1 only. Do not query `typo@example.com` again or create/invite that identity.
5. `get_user({id: U1})` → Chris Powell / chris@example.com; `get_project({id: P})` → OLD.
6. Ask final confirmation for Chris Powell / chris@example.com and Customer Portal → Assign this lead.
7. Reread local and remote targets → unchanged; `save_project({id: P, lead: U1})`; `get_project({id: P})` → U1.
8. Write/read-back verified local email/UUID/date/audit and report success. No assignment write occurred while the lookup was empty.

Asks in order: correction/cancel; final resolved-user confirmation. No redundant identity prompt follows the supplied correction. Evidence: revised S2 correction replacement, S3 no-match branch, S4/F write ordering.

## Bounded limitations

1. **Unknown local partial-write extent is not specified.** Case 14 injects an error before file modification. Instructions require partial reporting/readback and retry, but do not explicitly require an atomic file replacement. A failure after partial bytes are written could need record repair beyond the documented retry. The Scope asks accurate failure reporting and retry, which the controlled case verifies; crash-safe persistence is not claimed.
2. **No atomic concurrency promise.** F explicitly acknowledges read-before-write cannot prevent changes between the remote check and update. Case 12 verifies observed conflicts only.
3. **Tool equivalence and server behavior remain integration limits.** MCP capability discovery, pagination result shapes, permissions, eventual consistency, valid account status, and actual lead-update acceptance were controlled responses. The operation contract supplies names and semantics; no real server was contacted and no supported tool schema was assumed beyond that contract.
4. **Coverage boundaries.** AC1–AC5 have direct scenario evidence above. AC6 only the explicit-target helper and return portion is exercised here. Newproject Yes/No/bootstrap/failed-create paths, actual YAML/schema/template checks, release agreement and all lints are other Task 5 evidence, not inferred from this report. No scenario outcome is inferred from lints.

## Result

All 19 scenario groups (the original 17 plus replacement and correction traces against the final revised instructions) produce traces consistent with their applicable Scope criteria under controlled outcomes. The initially observed input-reset ambiguity is resolved explicitly in the final instructions; cases 18 and 19 verify both retry routes. No remaining blocking instruction gap was found in the tested flows. No live assignment or production integration success is claimed.
