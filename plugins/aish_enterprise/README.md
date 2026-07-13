# aish_enterprise — the aish.sh control-plane plugin

> Connects the **open-source aish client** to the **aish.sh commercial control
> plane** — managed tiered memory, LLM tracing + tuning recs, governance/policy, a
> managed MCP gateway, and an org skill registry — **entirely through aish's
> existing hooks / skills / MCP / config seams**. No fork of the OSS binary.

This is the concrete packaging of the seams identified in
[`../../product/enterprise/04-client-integration.md`](../../product/enterprise/04-client-integration.md).
Everything the commercial offering needs on the client is delivered as **one
plugin** the user installs with a single command; all the heavy lifting stays
server-side in the aish.sh backend.

## What it publishes (plugin capabilities)

| Capability | File | Client seam it uses | Pillar |
|---|---|---|---|
| **MCP gateway** | [`.mcp.json`](./.mcp.json) | client MCP set (merged) | D |
| **Event hooks** (33-event catalog contributions) | [`hooks.json`](./hooks.json) | `src/hooks.rs` registry (merged) | A, B, F, G |
| **Event forwarder** | [`bin/aish-enterprise-hook`](./bin/aish-enterprise-hook) | `provides.tools` (PATH) | A, B, F, G |
| **Lifecycle hooks** (login handshake + config pull) | [`hooks/on_init.sh`](./hooks/on_init.sh) | `provides.lifecycle_hooks` | Substrate |
| **Skill registry pointer** | `AISH_SKILL_REGISTRY` export | `src/skill_provider.rs` | C, E |
| **Config/env injection** | [`plugin.json`](./plugin.json) `config_schema` | `provides.config` | G |
| **Login command** (`aish_login`) | `provides.tools` / `provides.login` | device-code auth | Substrate |

> **Two kinds of "hook", don't conflate them:**
> - **`hooks/` (lifecycle hooks)** — shell scripts run at *plugin* lifecycle points
>   (`on_init`, `on_shell_ready`, `on_shutdown`). Declared in `plugin.json →
>   lifecycle_hooks_manifest`.
> - **`hooks.json` (event hooks)** — entries **merged into the client's real
>   33-event catalog** (`src/hooks.rs`). Declared via `plugin.json →
>   event_hooks_file`. This is the load-bearing enterprise seam.
>
> Reconciling these two notions is the main correction fed back into the OSS
> [`PLUGIN_SYSTEM_DESIGN.md`](https://github.com/LightHeart-Ventures/aish/blob/main/docs/PLUGIN_SYSTEM_DESIGN.md)
> — see the enterprise addendum in that PR.

## Install (target UX)

```
aish plugin add aish_enterprise      # from the aish.sh registry
aish login                           # device-code; binds CLI to your tenant
```

That's it. `on_init` pulls managed config; `.mcp.json` + `hooks.json` are merged;
the skill provider re-points at your org registry. The OSS binary is untouched.

## Trust model (why this is low-risk)

- **No credential values in hook payloads** — the forwarder authenticates itself
  from `${env:AISH_ENTERPRISE_API_KEY}`; export *names* only ever cross the hook
  boundary (`src/hooks.rs` guarantees this).
- **Fail-open by default** — every telemetry lane exits 0 on error; a control-plane
  outage never breaks a turn. Governance can opt into **fail-closed**
  (`policy_enforcement: enforce` + `offline_default: deny`).
- **Only `PreToolUse` blocks** — one entry, timeout-bounded, returns
  `Decision::Deny(reason)`. Everything else is observe-only.
- **Recursion-guarded** — `AISH_IN_HOOK` prevents the forwarder's own subprocesses
  from re-triggering hooks.

## Configuration

See [`plugin.json`](./plugin.json) `config_schema`. Key knobs: `gateway_url`,
`ingest_url`, `policy_url`, `skill_registry_url`, `policy_enforcement`
(`off`/`audit`/`enforce`), `offline_default` (`allow`/`deny`), `trace_sampling`,
`memory_sync`.

## Status

**v0.1.0 scaffold** — contracts + reference forwarder. Ships once the OSS client
lands the minimal plugin capabilities called out in the design addendum
(config/env injection, `event_hooks_file` merge, `provides.login`). Those three are
the Phase-0.5 unlock and do **not** require the full webhook/broker phases.
