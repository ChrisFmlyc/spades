# Fixture — `backend: local`

A minimal SPADES consumer repo configured for the **local** backend.
Used to verify that SPADES skills work end-to-end with no external
tracker, reading canonical state from `.spades/` only.

## Shape

```
.spades/
├── config                                    # backend: local
├── version                                   # spades_version pin
├── projects/example-service.md               # one Project record
├── scopes/S-add-healthz-endpoint.md          # one Scope (status: scoped)
└── plans/P-add-healthz-endpoint-7QkP.md      # its Plan
```

This is the same shape as `examples/fixture-linear-mode/`; only
`.spades/config` differs (here: `backend: local`, with no `linear:`
block).

## Manual exercise

With this directory as the working directory:

1. **`/spades:status`** reads `.spades/config`, sees `backend: local`,
   scans `.spades/scopes/` and reports the Scope at phase **Scoped**
   with a Plan ready. It makes **zero** backend MCP calls.
2. **`/spades:list`** does the same — backend-agnostic at the call
   site, branches on `backend:` for storage.

**Pass:** the skills resolve `backend: local`, take the filesystem
path, and never reach for an external tracker. **Fail:** a skill
attempts an MCP call despite `backend: local`, or auto-probes the
backend.
