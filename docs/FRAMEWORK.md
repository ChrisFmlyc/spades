# The SPADE Framework

## A Human-AI Operating Model for Engineering Teams

This is the full reference document for the SPADE Framework. For quick-start
usage, see README.md. For agent enforcement rules, see AGENTS.md.

---

## Why This Exists

The way we build software is shifting. AI agents can now read codebases,
generate plans, write code, run tests, and manage project boards, but they
cannot decide what to build, and they should not ship without human verification.

SPADE is our framework for structuring this. It defines clear boundaries between
what humans own and what AI handles, creating a loop that is fast, auditable,
and safe.

**The core principle:** Humans own the edges (intent and verification). AI owns
the middle (planning and execution).

### Where Scopes Come From

Scopes do not appear from nowhere. They are derived from OKRs and roadmap
priorities through a collaborative process between leadership and the team.
The flow is:

1. OKRs and roadmap set the strategic direction for the quarter.
2. Leadership and the team collaboratively break those down into concrete,
   actionable Scopes.
3. A Scope should be specific enough that someone could start work on it
   without needing a follow-up conversation to clarify intent.

A bad Scope: "We need to do threat intel."
A good Scope: "Ingest Telegram messages on a regular basis into the TI stack."

The first is a strategic direction. The second is something someone can plan
against and deliver.

### What Makes a Good Milestone

A milestone is not a time-boxed container and it is not a task. It is an outcome
derived from an OKR. You look at your OKRs for the quarter and ask: what needs
to be true for this to be on track? Each answer is a milestone.

The shift from traditional project management is subtle but important. A task
describes activity: "Build the ETL pipeline." A milestone describes a verifiable
outcome: "Device telemetry is flowing into the intelligence platform and
available for analysis." The first tells you what to do. The second tells you
what done looks like.

Good milestones share a few properties: they are verifiable (you can demonstrate
whether the outcome has been achieved), they are meaningful (achieving them
materially advances the OKR), and they decompose cleanly into Scopes (you can
look at a milestone and identify the concrete pieces of work needed to get there).

### How Work Gets Picked Up

The default expectation is that team members operate with autonomy: understand
the priorities, pull work, and drive it forward. Not everyone operates the same
way though. Some people thrive with high autonomy and minimal direction. Others
need clearer sequencing, more explicit assignment, and tighter check-in points.
The framework accommodates both.

What matters is that the Scope is clear enough for either type of person to act
on it. Whether someone pulls work independently or receives a more explicitly
assigned Scope with closer check-ins, the expectation is the same: the person
who picks it up owns the outcome, not just the execution. The assignment model
might differ, but the accountability model does not.

The goal is ownership, not task assignment. But ownership requires the work to
be visible and the expectations to be unambiguous.

### Reactive and Unplanned Work

Not all Scopes originate from OKRs. Tickets, incidents, vulnerability reports,
and ad-hoc requests are a normal part of any security team's workload. SPADE
handles these the same way it handles planned work, but the loop runs at a pace
proportional to the size and urgency of the task.

For small reactive items (a bug fix, a configuration change, a quick
investigation), the loop compresses. The ticket itself is the Scope. Planning
might be a single AI-generated comment proposing an approach. Approval is a
quick check. Delivery and evaluation happen in the same session. The structure
is the same; the ceremony is lighter.

For larger reactive work (an incident requiring coordinated response, a
vulnerability investigation spanning multiple systems), the work gets a proper
parent issue in Linear, scoped with acceptance criteria just like any planned
work. It enters the active cycle and runs through the full SPADE loop.

What matters is that all work, planned or reactive, has a clear Scope and a
visible owner. The origin of the work is less important than the clarity of what
needs to happen and how you know it is done.

### Key-Person Risk

If the collaborative scoping process only exists in conversations, it creates a
single point of failure. Scopes should be written down and visible (in Linear,
or wherever the team tracks work) so that priorities are clear even if the
person who defined them is unavailable. This is not about bureaucracy. It is
about making sure the team can keep moving without depending on any one
individual being in the room.

---

## The Loop

```
SCOPE --> PLAN --> APPROVE --> DELIVER --> EVALUATE
 (H)       (AI)      (H)       (AI/H)       (H)
              ^                    |
              |                    |
              +---- Rework <-------+
```

### Scope (Human)

The engineer defines what needs to be achieved and why it matters. This is not
a task description. It is a statement of intent with clear acceptance criteria
and constraints.

A good Scope answers:
- What does success look like?
- What are the acceptance criteria?
- What architectural constraints apply? (tech stack, patterns, security requirements)
- What does this connect to upstream and downstream?

A Scope is not an Initiative or an OKR. It should be concrete enough that an AI
agent (or a human) can generate a plan from it in a single session. If you find
yourself writing a Scope that spans multiple systems, multiple teams, or multiple
months, it is probably too big. Break it down.

The Scope is the contract. Everything downstream is measured against it.

### Plan (AI)

The AI agent takes the Scope and produces a structured plan: what to build, how
to build it, what to build it with, and in what order. The Plan is broken into
3-7 discrete tasks, each scoped tightly enough that an AI agent (or human) can
pick it up and deliver it in a focused session.

The Plan also includes:
- Technical approach and rationale
- Dependencies between tasks
- Risk callouts (what might go wrong, what assumptions are being made)
- Which tasks should be AI-delivered vs human-delivered
- Testing and verification approach: for software tasks, what tests are expected
  (unit, integration, E2E) and what passing looks like. For non-software tasks,
  what evidence demonstrates completion.

The Plan is a first-class artefact, not something that happens invisibly. It
gets documented and attached to the parent issue in Linear (as a comment or
Linear doc) so the team can see the reasoning, not just the output. This
behaviour is enforced through AGENTS.md which instructs AI agents to document
their plans and attach them to the relevant issue automatically.

### Approve (Human)

The engineer reviews the AI-generated Plan against reality. This is a gate,
not a rubber stamp.

Approval checks:
- Architecture alignment: Does this conform to our established patterns and
  tech stack?
- Completeness: Are there obvious gaps or missing edge cases?
- Feasibility: Can this actually be built this way with our constraints?
- Risk: Is the AI making assumptions that need to be validated?
- Scope: Is the task breakdown at the right granularity?

If the Plan does not pass Approval, it goes back to the AI with specific
feedback. Rejection is not failure. It is the framework working.

The biggest risk in SPADE is a weak Approval gate. A bad plan that gets rubber-
stamped leads to confidently wrong execution. If you are approving every plan
in 30 seconds, the gate is not working.

### Deliver (AI or Human)

The tasks from the Plan get executed. Some by AI agents, some by humans.

AI-delivered tasks are things like: writing code, building API endpoints,
creating data pipelines, generating configuration, writing tests, producing
documentation, and managing project boards.

Human-delivered tasks are things like: stakeholder conversations, hardware
testing, vendor negotiations, security reviews requiring physical access,
relationship-building, and anything requiring organisational context that AI
cannot access.

The framework does not pretend everything is AI-deliverable. It embraces the
mix and is explicit about who does what.

### Evaluate (Human)

After delivery, the engineer verifies the output against the original Scope.
This is distinct from the Approval stage. It is output validation, not approach
validation.

Evaluation checks:
- Does the output meet the acceptance criteria from the Scope?
- Does it actually work in practice (not just in theory)?
- Are there quality issues, edge cases, or regressions?
- Would I be comfortable shipping this?

If evaluation fails, work goes back, either to Deliver (minor fixes) or to Plan
(fundamental approach was wrong).

---

## Plan Schema

Every Plan produced by `/spade-plan` must conform to a documented schema so
downstream skills (delivery, review, evaluation) can consume it
deterministically. Consumers read Plans; drift in the schema breaks them.

### Required fields

Per Plan:

- Scope reference (issue ID or link)
- Technical approach summary (2-3 sentences)
- Risks and assumptions
- Delivery sequence
- Delivery bundles (default: one; see `/spade-plan` for split rules)

Per task:

- Title
- Description — what needs to be done
- Delivery mode — `ai-delivered` or `human-delivery`
- Dependencies — which other tasks must complete first
- Effort estimate — brief, moderate, or significant
- Approach — how it will be done
- Tests — what tests are expected, or what evidence demonstrates completion
- **Execution posture** — see vocabulary below

### Execution posture

Execution posture declares the delivery strategy for a task: not *what* to
build but *how* to approach the build. Posture propagates from Plan to
delivery: `/spade-plan` emits it, and delivery skills (or humans) honour it
when picking up the task.

Vocabulary (locked; extensions require a new Scope):

| Posture                 | When to choose                                                                                                     | Typical signal                                                                                          |
|-------------------------|--------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `test-first`            | The desired behaviour is well-specified and you want failing tests to drive implementation.                        | New features with clear acceptance criteria; protocol/contract work.                                    |
| `characterization-first`| You are fixing a bug or refactoring existing code and need to pin down current behaviour *before* changing it.     | Bug fixes on code without adequate tests; pre-refactor safety nets.                                     |
| `refactor-first`        | Touching the area is only viable after a preparatory refactor; the new behaviour follows the cleanup.              | Code you cannot cleanly extend without first reshaping it.                                              |
| `spike`                 | The correct approach is genuinely unknown; the task's output is learning, not shippable code.                      | New technology evaluation; hard-to-estimate architectural choices.                                      |
| `straight-through`      | The change is mechanical enough that test-first / characterization-first ceremony adds no value.                   | Typo fixes, config bumps, docs edits, one-liners covered by existing tests.                             |

There is no silent default. Every task must declare a posture. If
`straight-through` is chosen, the Plan must state *why* — typically "covered
by existing tests" or "mechanical change". This avoids the failure mode
where posture becomes a rubber-stamp field.

A task may declare mixed posture when the work naturally splits (for
example, `characterization-first` on the existing module; `test-first` on
the new behaviour). Write it as `Execution posture: characterization-first on X; test-first on Y.`.

---

## Why SPADE Works

### It matches how AI agents actually perform

AI is excellent at planning (exploring solution spaces, breaking down problems,
identifying approaches) and delivery (writing code, following patterns, producing
output). AI is poor at deciding what matters to the business and verifying that
output works in the real world. SPADE puts AI where it is strong and humans where
AI is weak.

### It creates an audit trail

Every piece of work has: a human-written Scope (the "what"), an AI-generated
Plan (the "how"), an Approval decision (the "approved by"), delivery records
(the "done"), and an Evaluation (the "verified"). You can trace any delivered
work back through the full chain.

This matters for two specific reasons. First, AI-delivered work can easily become
opaque. Without a recorded plan, developers end up unable to explain what
frameworks, patterns, or architectural decisions went into the output. The audit
trail ensures that every piece of delivered work has a visible reasoning chain,
not just a result. Second, when something breaks in production, you need to trace
back through scope, plan, approval, and delivery to understand what went wrong
and where. Without that chain, debugging AI-delivered work is guesswork.

This is not overhead because it is automated. AGENTS.md instructs AI agents to
document plans and attach them to issues as part of the standard workflow.
Nobody is writing audit logs manually.

### It scales fractally (within limits)

The same SPADE loop works at every level of tactical and implementation scope:

- Tactical: "Build the ETL pipeline" -> AI plans the sub-tasks -> Human
  approves -> AI writes code -> Human evaluates
- Granular: "Implement schema validation" -> AI plans the approach -> Quick
  approval -> AI writes the function -> Human checks

The Approval gate gets lighter as scope gets smaller and risk gets lower.

At the strategic level, SPADE does not apply in the same way. Strategy requires
free-form thinking about business problems, customer needs, and market context.
AI can assist with research, analysis, and structuring options, but it should not
be planning your strategy for you. The output of strategic thinking feeds into
SPADE as Scopes and Milestones, but the thinking itself is human-owned.

### It prevents the two failure modes of AI-assisted work

Failure mode 1: Humans doing everything manually. Without a framework, teams use
AI as a fancy autocomplete, asking it to write individual functions but still
doing all the planning, structuring, and project management manually. SPADE
pushes planning and delivery to AI, freeing humans for judgement.

Failure mode 2: AI doing everything unsupervised. Without a framework, teams hand
AI an open-ended goal and hope for the best. The output might be technically
functional but architecturally wrong, insecure, or solving the wrong problem.
SPADE's Approve and Evaluate gates prevent this.

---

## Tooling: How It Works in Practice

SPADE is a pattern, not a product integration. The framework works regardless of
which tools you use to implement it. What follows describes our current tooling
choices, but if the tools change, the pattern holds. What matters is the human-AI
handoff loop, not the specific products.

### Linear as the System of Record

We use Linear to manage the full SPADE lifecycle. The hierarchy maps naturally:

```
Milestone (outcome derived from OKRs)
  +-- Parent Issue (SCOPE, human-written)
        |-- Sub-issue 1 (AI-planned task, AI-delivered)
        |-- Sub-issue 2 (AI-planned task, human-delivered)
        |-- Sub-issue 3 (AI-planned task, AI-delivered)
        +-- Plan Document (attached as comment or Linear doc)
```

The parent issue is the Scope. Written by a human. It contains the acceptance
criteria, constraints, and architectural context. This is the contract.

The sub-issues are the AI-generated Plan, broken into deliverable tasks. Each
sub-issue is small enough that an AI agent can complete it in a focused session.

The workflow tracks SPADE phases on the parent issue:

| Status      | Phase | Who is Active                                    |
|-------------|-------|--------------------------------------------------|
| Scoped      | S     | Human has defined the scope and acceptance criteria |
| Planning    | P     | AI is generating plan and sub-issues               |
| Approval    | A     | Human is reviewing the approach                    |
| Delivering  | D     | Sub-issues being worked (AI or human)              |
| Evaluating  | E     | Human validating against acceptance criteria       |
| Done        | ✓     | Shipped and verified                               |

Sub-issues use a simpler workflow: Todo -> In Progress -> Done

Labels indicate execution mode:

| Label              | Meaning                                    |
|--------------------|--------------------------------------------|
| ai-planned         | Plan was generated by AI                   |
| ai-delivered       | Task was completed by an AI agent          |
| human-delivery     | Task requires human hands                  |
| plan-rejected      | Plan was reviewed and sent back            |
| needs-arch-review  | Touches architecture, needs senior review  |

### Claude Code + Linear MCP

Claude Code (Anthropic's command-line AI agent) natively integrates with Linear
via MCP (Model Context Protocol). This means Claude Code can:

- Read issues: pull the Scope, acceptance criteria, and context directly from Linear
- Generate plans: create sub-issues on a parent issue with descriptions, priorities,
  labels, and assignments
- Deliver tasks: write code, build features, run tests, all with the Linear issue
  context loaded
- Update status: move issues through the SPADE workflow as work progresses
- Create documentation: attach plan documents, architecture notes, and decision
  records to projects

### Other AI Agents

SPADE is not locked to Anthropic tooling. The framework works with any AI agent
that can:

- Read a structured Scope (from Linear, Notion, or any project tool)
- Generate a structured Plan (sub-tasks with context)
- Deliver discrete tasks (code, documentation, configuration)
- Report completion status

Cursor, GitHub Copilot Workspace, Codex, or any future agent that supports MCP
can slot into the Deliver phase. The framework is tool-agnostic. It is about the
human-AI handoff pattern, not specific products.

---

## Cycle Rhythm

SPADE does not prescribe a rigid daily schedule. The rhythm is driven by two
concrete touchpoints per cycle, with everything else happening asynchronously.

Start of cycle: Scoping and Planning. The team reviews active Milestones and
agrees on the Scopes for this cycle. Each engineer owns their parent issues and
is responsible for ensuring the Scope is clear enough for AI to plan against.

End of cycle: Evaluation. Parent issue owners verify completed work against the
original Scope. Does it meet the acceptance criteria? Does it work end-to-end?
Issues that pass move to Done. Issues that fail go back with specific feedback.

Between those two points, delivery is continuous and asynchronous. Sub-issues get
worked by AI agents and humans as they become unblocked. New Scopes can be added
mid-cycle as priorities shift. The backlog is a living thing, not a quarterly
contract.

---

## Principles

1. Humans own the edges. Humans define what to build (Scope) and confirm it was
   built correctly (Evaluate). AI never decides what to build, and AI output is
   never shipped without human verification.
2. Plans are artefacts, not ephemeral. Every AI-generated plan is documented and
   attached to the work item.
3. Approval is a gate, not a rubber stamp. If you are approving every plan in
   30 seconds, the gate is not working.
4. Delivery mode is explicit. Every task is labelled as AI-delivered or
   human-delivery.
5. Feedback loops are first-class. A rejected plan goes back to Planning. A
   failed evaluation goes back to Delivery. The loop is expected to iterate.
6. Architecture constraints are codified, not memorised. Maintain living
   documents (ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md) that AI reads
   during planning.
7. Scope determines approval depth. Strategic decisions get deep review.
   Granular implementation tasks get light review.

---

## Learnings

Each pass of the SPADE loop should produce knowledge that strengthens the
next pass. Without a place to capture it, that knowledge vanishes into PR
descriptions and Evaluate comments. SPADE addresses this with a small
learnings store and a plan-time integration.

### Storage

Learnings live under `.spade/learnings/` in the consumer repo, one file
per learning, with the filename pattern
`YYYY-MM-DD-<short-slug>.md`:

- `.spade/learnings/*.md` — **public-safe** learnings. Committed with
  the rest of the repo.
- `.spade/learnings/private/*.md` — **not public-safe**. Gitignored.
  Use for entries that reference internal systems, credentials paths,
  security details, or anything else that must not leak into public
  forks.

Each file carries the following flat YAML frontmatter (no nested
structures — the framework's linter only supports flat keys):

```yaml
---
title: One-line summary of what was learned
area: onboarding | planning | delivery | review | other
tags: comma, separated, keywords
created: YYYY-MM-DD
status: active               # or "archived"
public_safe: true            # or false
scope_ref: LIN-123           # optional; link to originating Scope
---
```

Body conventionally has two sections: *What we learned* (specific
observation, not a platitude) and *Why it matters for future work* (the
concrete implication). See `.spade/learnings/` in this repo for two
worked examples distilled from the M-323 recon.

### Capture

Use `/spade-learn` to capture a learning (see
`.claude/skills/spade-learn/SKILL.md`). The skill drafts a complete
entry from context, asks whether it is public-safe, and routes to the
correct directory on write. Capture is cheap and meant to be used
freely — aim for a few learnings per Scope, not one per quarter.

### Refresh

Learnings decay. `/spade-learn --refresh` is a periodic (quarterly at
most), human-gated pass that:

- Lists active entries older than 180 days for triage (keep active /
  archive / delete).
- Flags pairs of active entries whose tags overlap ≥50% and whose titles
  appear to contradict, so the human can resolve before surfacing them
  to future Plans.
- Never silently modifies anything — every action requires explicit
  human approval, just like the Approve gate in the main loop.

The lint at `scripts/lint/lint-learnings.sh` surfaces stale entries as
warnings on every PR so staleness can't accumulate silently.

### Plan-time integration

Before producing a Plan, `/spade-plan` greps `.spade/learnings/*.md` for
entries that match the current Scope:

- A learning matches if its `scope_ref` equals the current Scope's
  Linear identifier, OR
- At least **two** of its `tags` appear in the Scope title or the tech
  stack row of `ARCHITECTURE.md`.

Matched entries surface in a `Prior Learnings Considered` section near
the top of the Plan, each with a one-line note on how the Plan honours
the learning. Archived entries are skipped. No matches = no section;
silence is cheaper than padding.

The ≥2-tag threshold is deliberate: one shared tag is usually
coincidence. A human can always ask `/spade-plan` to include a specific
learning by filename.

### Why this matters

The biggest failure mode of AI-assisted delivery is treating each task
as isolated. The same mistakes get made repeatedly because the
knowledge from Evaluate doesn't reach the next Plan. A 60-second
capture during or after Evaluate closes that loop for free.

Without a refresh mechanism, the store would rot. The pair of capture
+ refresh is what keeps the store high-signal over years, not weeks.

---

*The SPADE Framework v1.0, April 2026, M-KOPA Product Security Team*
