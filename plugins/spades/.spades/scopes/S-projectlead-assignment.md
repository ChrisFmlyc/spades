---
id: S-projectlead-assignment
title: "Assign a project lead through a dedicated skill"
project: spades-framework
status: shipping
branch: feat/projectlead-assignment
base_commit: bbeff04f678312a4c0dd1c56c5bf87a1a1e7651b
type: feature
priority: this-cycle
origin: ad-hoc
created: 2026-09-13
updated: 2026-09-13
---

# Assign a project lead through a dedicated skill

## Statement of Intent

A user can assign a person as a SPADES project's lead through `/spades:projectlead`, either directly or from `/spades:newproject`. Local projects retain the supplied identity in their Project record; Linear projects resolve and confirm a real workspace user before assigning that person as the Linear Project lead and recording the result locally.

## Acceptance Criteria

- [ ] `/spades:projectlead` requires initialized SPADES configuration and an existing local Project record for its target. Missing setup, an unset or invalid target, or a missing Project record stops the flow with an actionable message before lookup or writes.
- [ ] A direct invocation uses the active project. With no person argument, it asks “Who is the project lead?”; `/spades:projectlead chris` and an email argument use that supplied identity without asking for it again.
- [ ] With `backend: local`, the skill records the supplied name or email as the project lead in the canonical local Project record, preserving other project metadata and recording the change in its audit trail. It makes no Linear calls.
- [ ] With `backend: linear`, the skill uses Linear MCP to look up workspace users by the supplied name or email. It presents the resolved name and email for final confirmation before assignment. Multiple matches require selection; no match or unavailable lookup offers correction, retry or cancellation without guessing an identity or changing the existing lead.
- [ ] After confirmation, the Linear flow assigns the resolved user's stable identity to the intended Linear Project's lead, verifies the result, and records the confirmed identity locally. Cancellation preserves the existing assignment. Failed or partially completed writes are reported accurately and can be retried without claiming completion.
- [ ] `/spades:newproject` asks whether to add a project lead after the new local Project exists and its Linear association is available when required. Yes invokes `/spades:projectlead` for that newly created project, including when the user leaves a different project active. No skips lead assignment. Bootstrap invocation returns to Setup after this optional handoff.
- [ ] The new skill, project-record contract, affected project rendering, skill listings and release metadata agree. Existing lints pass, and scenario checks cover direct and prompted input, local assignment, Linear confirmation, ambiguous/no matches, cancellation, missing setup/project, update failures and the Newproject handoff.

## Architectural Constraints

Follow ARCHITECTURE.md and PATTERNS.md: skill behavior is Markdown instruction, backend selection comes from configuration, local Markdown is canonical, and Linear integration uses MCP. Keep shared project metadata and persistence rules in the framework contract. Preserve existing owners and other project fields. Keep project-lead assignment separate from the existing `/spades:leads` discovery workflow. Use existing rendering and validation infrastructure; follow the plugin release gate for delivery.

## Dependencies

The consumer's Linear MCP connection must support workspace user lookup and project-lead updates for Linear-backed assignment. Local mode has no external dependency. No other Scope is a prerequisite.

## Context

- **Upstream:** SPADES Setup and Newproject establish configuration and the local Project record; Newproject creates or binds the Linear Project when selected.
- **Downstream:** Projectlead updates the target Project's lead and its canonical local record, with the corresponding Linear assignment in Linear mode.
- **Related:** Existing Project records carry owners but no dedicated project-lead contract. The current `/spades:leads` skill tracks discoveries rather than people.

## Out of Scope

- Creating or inviting Linear users, changing workspace membership, or granting permissions.
- Assigning Scope or Plan owners, issue assignees, multiple project leads, or redesigning project owners.
- Adding project-management backends or changing the discovery Lead lifecycle.
- Automatically assigning leads to existing consumer projects during upgrade.

## Risk / Unknowns

- Names may match several Linear users; selection and final identity confirmation must precede assignment.
- Local and Linear updates may complete independently; the Plan must define write ordering, partial-failure reporting and retry behavior.
- Newproject may leave another project active or run during Setup; the handoff must retain the newly created project's identity and return to the caller correctly.
- Planning must verify available MCP capabilities and define backward-compatible local lead fields and their rendering.

## Delivery Preference

Mostly AI-delivered. Verify the instruction flows and existing lints; record any live Linear validation that requires an available connected test project.

## Audit Trail

- 2026-09-13: Scope drafted from the user's projectlead request; local persistence, mostly AI delivery, this-cycle priority and feature classification confirmed.
- 2026-09-13: Scope approved by the user; recorded via subagent-dispatch.
- 2026-09-13: Plan drafted — P-projectlead-assignment-hX8p. Dispatch: subagent-dispatch.
- 2026-09-13: P-projectlead-assignment-hX8p approved by AI (/spades:loop) — routing: ai; 6/6 checks pass. Dispatch: subagent-dispatch.
- 2026-09-13: Delivery worktree established — branch: feat/projectlead-assignment; base: bbeff04f678312a4c0dd1c56c5bf87a1a1e7651b; source: docs/projectlead-scope. Approved Scope, Plan and GitHub SCM setting transferred and verified; source retained.
- 2026-09-13: P-projectlead-assignment-hX8p delivered; all five tasks complete, awaiting evaluation.
- 2026-09-13: Evaluation PASS confirmed by AI (/spades:loop); C1–C7 covered; shared Scope PR publication started.
