# Fixture — `backend: linear`

A minimal SPADES consumer repo configured for the **Linear** backend.
Useful as a worked example of what a tracker-backed SPADES repo's
local state looks like, and as a fixture for testing the framework
against a Linear-backed configuration.

## Shape

```
.spades/
├── config                                    # backend: linear, with team_id + project_id
├── version                                   # spades_version pin
├── projects/example-service.md               # one Project record
├── scopes/S-add-healthz-endpoint.md          # one Scope (status: scoped)
└── plans/P-add-healthz-endpoint-7QkP.md      # its Plan
```

This is the same shape as `examples/fixture-local-mode/`; only
`.spades/config` differs (here: `backend: linear` plus the
`linear.team_id` and `linear.project_id` block).

## Manual exercise

With this directory as the working directory:

1. **`/spades:status`** and **`/spades:list`** read `.spades/config`,
   see `backend: linear`, and operate against the Linear MCP for any
   live work. The local files mirror the canonical Linear state.
2. The local `.spades/scopes/` and `.spades/plans/` files in this
   fixture aren't tied to a real Linear workspace — they exist only
   to demonstrate the shape and parse cleanly under the v2 schema
   lint.

**Pass:** the skills see `backend: linear` and call out to Linear
when active work exists. **Fail:** a skill ignores `backend:` and
treats the local files as canonical, or auto-probes the backend.
