# Fixture — local mode

A minimal SPADE consumer repo configured for **`local` mode**, used to
verify M-879 by hand: SPADE skills must work end-to-end with no Linear
MCP, reading canonical state from `.spade/`.

## Shape

```
.spade/config                              mode: local, no team_id
.spade/version                             spade_version pin
.spade/scopes/add-healthz-endpoint.md      one Scope (status: delivering)
.spade/plans/add-healthz-endpoint-plan.md  its Plan
```

This is the same shape as `examples/fixture-linear-mode/`; only
`.spade/config` differs (here: explicit `mode: local`, no `team_id`).

## Manual exercise

With this directory as the working directory:

1. **`/spade-status`** — resolves `local` mode (explicit `mode: local`
   wins, no probe), scans `.spade/scopes/`, and reports the Scope at
   phase **Delivering** with **Plan ready**, making **zero Linear MCP
   calls**.
2. **`/spade-list`** — resolves `local` mode and lists the Scope under
   **Delivering** from the local file, again with zero MCP calls.

**Pass:** both skills produce output from the local files alone.
**Fail:** either skill calls Linear, or aborts for lack of a tracker
(the pre-M-879 bug).
