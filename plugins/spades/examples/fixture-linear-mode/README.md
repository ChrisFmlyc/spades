# Fixture — `backend: linear`

A minimal SPADES consumer repo configured for the **Linear** backend.
Useful as a worked example of what a tracker-backed SPADES repo's
local state looks like, and as a fixture for testing the framework
against a Linear-backed configuration.

## Shape

```
.spades/
├── config                                    # backend: linear, with team_id + project_id
└── version                                   # spades_version pin
```

## Manual exercise

With this directory as the working directory, **`/spades:status`**
and **`/spades:list`** read `.spades/config`, see `backend: linear`,
and operate against the Linear MCP for any mirror operations. The
local Markdown files remain canonical.

**Pass:** the skills see `backend: linear` and call out to Linear
when active work exists. **Fail:** a skill ignores `backend:` and
skips required Linear mirroring, or auto-probes the backend.
