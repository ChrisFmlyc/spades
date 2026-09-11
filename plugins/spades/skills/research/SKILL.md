---
name: research
description: Researches a topic through an isolated researcher subagent. Use when the human says "properly research this", "look into X", "check the prior art", "second opinion on the landscape", "what does the SOTA look like for X", or asks any open question that needs external fact-finding (libraries, frameworks, benchmarks, postmortems, comparisons). Returns a structured findings report; optionally posts to a Linear parent issue with explicit human consent. Callable any time — not tied to a SPADES phase. Also matches the explicit slash-command form `/spades:research`.
version: 2.3.3
---

# /spades:research

Dispatch the question to a fresh `researcher` context and present its
report. The bundled agent at `agents/researcher.md` uses read-only tools,
web search and fetch. Its output contract requires `## Question`,
`## Findings` with footnoted citations, `## Recommendation`, and
`## Sources`.

Research is callable at any point in the loop. The researcher stays
read-only; its coordinator completes the leads handoff to capture discoveries
after the report. Posting the research report itself to Linear remains
optional and requires the human's explicit consent.

Read `docs/FRAMEWORK.md` § Freshness and § Asking the Human before
running.

## Pre-Flight

1. **Working context.** Follow `docs/FRAMEWORK.md § Freshness` and
   § Scope Worktrees. Resolve a scoped target to its worktree; for standalone
   research/review name the checkout and revision inspected. Pass that
   absolute path and intended revision to the researcher/review workers.
   Default-branch preparation is owned by `/repo:newbranch` when new work
   is created, not by this read-only check.
2. **Backend.** The report coordinator reads `.spades/config` for a
   scoped Linear post. The mandatory leads worker reads it separately for
   capture settings. Research still works without a configured backend.

## Invocation modes

**Standalone** (default) — the human asks a question; the skill
spawns the researcher, displays the report, then completes the mandatory
leads handoff. The report itself stays in the conversation.

**Scoped** — `--scope S-…` was passed, or the session is already
working on a Scope or Plan (mid-`/spades:plan`, say). The report is
prefixed with the Scope ID and the skill offers to record it against
the Scope's backend record.

## The conversation

1. **Identify the question.** An ambiguous ask (*"research auth"*)
   gets one short free-form clarifying question before anything is
   spawned; clarification is composition, not a fixed-option choice.
2. **Identify the Scope context**, if any, for the consent prompt.
3. **Spawn the researcher** via the Agent tool, `subagent_type:
   researcher`, in the foreground. Pass the question verbatim, the
   Scope ID and a brief summary when scoped, and any local repo
   paths the question implies (*"compare our X to library Y"*).
4. **Display the report** exactly as emitted; the shape is locked
   and consumers read it positionally.
5. **Standalone → mandatory completion handoff below.**
6. **Scoped → consent** via `AskUserQuestion`: *"This report can be
   posted as a comment on <issue-id>. Which would you like?"*
   - **Post this comment to <issue-id>** — post verbatim, with
     `research:` on its own first line so it reads distinctly from
     Plan comments; confirm with the comment URL.
   - **Just show me — don't post.**
   - **Let me edit it first, then post** — show the report in a
     `markdown` code block, take the edited version back, post it
     with the `research:` prefix.
   - **Cancel.**

   With `backend: local` there is no issue to post to; the consent
   question is skipped and the report stays in the conversation.

## Linear write failure

When a post fails (MCP unreachable, issue resolved mid-flight,
write rejected): surface which step failed and the error; display
the report again inline so it survives the scroll-back; retry once
for a transient failure; after two failures proceed to the mandatory leads
handoff with the posting error in its context. Research output is
ephemeral by design — the human copies it into a file if they want
it kept.

## Boundaries

Research informs judgement; it generates no Plan, creates no
sub-issue, transitions no status, invokes no `/spades:review`, and
records no learning. One question per invocation; a follow-up is a
follow-up invocation.

## After research

When the report changes the human's view of in-flight work, suggest
the next step and leave the decision with them:

- A finding that affects an in-flight Scope → `/spades:scope
  S-<slug>` (Edit mode) to fold in the new constraint or option.
- A finding that affects an in-flight Plan → revise via
  `/spades:plan` while the Plan is `draft`, or a follow-up Scope once
  delivery has started.
- A finding worth keeping for future Scopes → `/spades:learn`.

## Mandatory completion handoff

After displaying the report and completing any scoped posting decision,
run the dedicated Leads worker and verify its receipt per
`docs/FRAMEWORK.md § Leads handoff`. Supply the question, scope boundaries,
report, source evidence, privacy classification and earlier captures with
their observation keys. Standalone and scoped runs both reach this step,
including a declined or failed optional post. Return the receipt alongside
the report, with IDs, source paths and pending publication or mirror work.
