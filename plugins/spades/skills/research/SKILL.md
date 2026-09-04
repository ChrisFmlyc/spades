---
name: research
description: Landscape research on a topic via an isolated researcher subagent. Use when the human says "properly research this", "look into X", "check the prior art", "second opinion on the landscape", "what does the SOTA look like for X", or asks any open question that needs external fact-finding (libraries, frameworks, benchmarks, postmortems, comparisons). Returns a structured findings report; optionally posts to a Linear parent issue with explicit human consent. Callable any time — not tied to a SPADES phase. Also matches the explicit slash-command form `/spades:research`.
version: 2.2.0
---

# /spades:research

You are dispatching landscape research to an isolated subagent and
presenting its report. The skill is a thin coordinator: the research
happens inside a fresh `researcher` context (the bundled agent under
`agents/researcher.md`, read-only tools plus web search and fetch),
and the report comes back in the fixed shape that agent's output
contract defines — `## Question`, `## Findings` with footnoted
citations, `## Recommendation`, `## Sources`.

Research is callable at any point in the loop and mutates no SPADES
state. Its one optional side effect is a Linear comment, posted only
with the human's explicit consent.

Read `docs/FRAMEWORK.md` § Freshness and § Asking the Human before
running.

## Pre-Flight

1. **Freshness.** When the research is scoped (below), the
   researcher reads the local Scope for context, so:

   ```bash
   git fetch origin --quiet && git rev-list --count main..origin/main
   ```

   `0` → continue. Non-zero → abort: *"Local `main` is N commits
   behind `origin/main`. Run `/repo:sync` then re-invoke
   `/spades:research`."* The check runs for standalone research too;
   one fetch is cheap and one rule is easy to keep.
2. **Backend.** `.spades/config` is read only when a scoped run
   posts to Linear. Research works without a configured backend.

## Invocation modes

**Standalone** (default) — the human asks a question; the skill
spawns the researcher, displays the report, and stops. Nothing is
written anywhere.

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
5. **Standalone → stop.**
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
for a transient failure and stop after two. Research output is
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
