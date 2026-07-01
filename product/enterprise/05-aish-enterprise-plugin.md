# Enterprise aish — the `aish_enterprise` client plugin

*Last updated: 2026-07-01*

> **Purpose.** [`04-client-integration.md`](./04-client-integration.md) proved that
> every enterprise pillar has a concrete attach point in the OSS client's existing
> seams (hooks, MCP, skills, config), and that the net-new client footprint is tiny:
> a **hook-forwarder + a config pointer + a login command**. This doc takes the next
> step the product direction asked for: **package that footprint as a single plugin,
> `aish_enterprise`**, built on the OSS client's
> [plugin system](https://github.com/LightHeart-Ventures/aish/blob/main/docs/PLUGIN_SYSTEM_DESIGN.md),
> so the commercial features ship **without touching aish OSS source** — beyond
> maturing the plugin capabilities the client needs to host such a plugin.

---

## Why a plugin (not a loose set of config edits)

04's "small net-new glue" was correct but *unpackaged* — three separate manual
touch-points (`~/.aish/hooks.json`, `.mcp.json`, skill-provider URL) plus a login
binary. The aish plugin system exists precisely to bundle exactly those artifact
types — **MCP servers, skills, tools, hooks, config** — behind one install. So the
right shape is:

```
aish plugin add aish_enterprise   +   aish login
```

Benefits over hand-wired config:

- **One install / one uninstall** — atomic enable/disable of the whole control-plane
  integration; nothing orphaned in the user's dotfiles.
- **Versioned + signed** — the plugin is delivered from the aish.sh registry with the
  same versioning/signing the registry gives org skills (Pillar E), so fleet rollout
  and rollback are first-class.
- **Clean OSS boundary** — the *only* work in the OSS repo is generic plugin
  plumbing (which benefits every plugin author); zero enterprise-specific code lands
  upstream. Open-core stays honest.
- **Discoverable capability surface** — `plugin.json` declares exactly what the
  integration touches, which is auditable by a security team before install.

## What the plugin publishes → which pillar it powers

| Plugin capability | Mechanism | OSS client seam | Pillar(s) |
|---|---|---|---|
| **Managed MCP gateway** | `.mcp.json` server merged into the client MCP set | `src/mcp.rs` loader | **D** |
| **Event hooks** | `hooks.json` merged into the **real 33-event catalog** | `src/hooks.rs` | **A, B, F, G** |
| **Event forwarder tool** | `aish-enterprise-hook` binary on PATH | `provides.tools` | A, B, F, G |
| **Login handshake + config pull** | `on_init` lifecycle hook | `provides.lifecycle_hooks` | Substrate, G |
| **Org skill registry** | `AISH_SKILL_REGISTRY` env export | `src/skill_provider.rs` | **C, E** |
| **Config / env injection** | `plugin.json` `config_schema` → session env | `provides.config` | G |
| **`aish login` / `aish_status`** | plugin-published tools | `provides.tools` / `provides.login` | Substrate |

The scaffold lives at [`/plugins/aish_enterprise/`](../../plugins/aish_enterprise/)
(`plugin.json`, `hooks.json`, `.mcp.json`, `hooks/on_init.sh`,
`bin/aish-enterprise-hook`, `README.md`).

## The critical reconciliation: two meanings of "hook"

The draft plugin design and the shipped client use the word **hook** for two
different things. The enterprise plugin depends on getting this right:

| Term | What it is | Where it's declared | Who runs it |
|---|---|---|---|
| **Lifecycle hook** | shell script at a *plugin* lifecycle point (`on_init`, `on_shell_ready`, `on_shutdown`) | `plugin.json → lifecycle_hooks_manifest` | plugin loader |
| **Event hook** | entry in the client's **33-event** agent-lifecycle catalog (`PreToolUse`, `TurnEnd`, `MemoryStored`, …) | a `hooks.json` merged via `plugin.json → event_hooks_file` | `src/hooks.rs` dispatcher |

The draft `PLUGIN_SYSTEM_DESIGN.md` modeled only lifecycle hooks (+ a separate
"webhooks" idea) and did **not** wire plugins into the real `src/hooks.rs` catalog.
**That catalog is the entire enterprise seam** (04's table). So the load-bearing OSS
change is: *let a plugin contribute entries to the client's `hooks.json` event
registry.* Everything else (memory, tracing, policy, fleet) rides on it.

## What the OSS client must add to host this plugin

Tracked in the companion PR against `LightHeart-Ventures/aish`
(`docs/PLUGIN_SYSTEM_DESIGN.md` enterprise addendum). Ranked by necessity:

1. **`event_hooks_file` merge** *(required)* — plugin-contributed `hooks.json`
   entries are merged into the client's `src/hooks.rs` catalog (same precedence
   rules as user vs project hooks; plugin entries are lowest precedence, user can
   override). **Without this, nothing works.**
2. **`provides.config` / env injection** *(required)* — a plugin can inject
   `.mcp.json` servers, exported env (`AISH_SKILL_REGISTRY`, gateway URL), and stage
   a managed `hooks.json` for merge. `on_init` emits `KEY=VALUE` on stdout.
3. **`provides.login` / auth command** *(required)* — a plugin can register a
   top-level command (`aish login`) and persist a credential the other capabilities
   reuse.
4. **Managed-config pull at `SessionStart`** *(nice-to-have)* — lets the org push
   policy/skill-allow-list updates to the fleet without re-install; can start as the
   `on_init` curl and harden later.
5. Full **webhook broker / marketplace phases** *(not required for Phase-0.5)* — the
   enterprise plugin explicitly does **not** need these; it uses the existing event
   catalog, not a new outbound-webhook subsystem.

> **Phase-0.5 unlock:** items 1–3 are small, generic, and useful to *every* plugin
> author. They are the true minimum to ship `aish_enterprise` — and they let the
> "first 5 to build" (B1 trace, C1 registry, G6 caps, A1 memory, B4 doctor) all land
> behind one plugin install.

## Parallel-workstream summary

| Repo | Change | Risk | Blocking |
|---|---|---|---|
| **aish.sh** (this repo) | `/plugins/aish_enterprise/` scaffold + these docs | none (additive) | — |
| **aish** (OSS) | plugin capabilities 1–3 in `PLUGIN_SYSTEM_DESIGN.md` + impl | low (generic plumbing) | ships the plugin |
| **aish.sh backend** | ingest / policy / gateway / registry endpoints | med (mostly Atum reuse) | server-side, parallel |

---

*See [`README.md`](./README.md) for the enterprise-docs index and
[`04-client-integration.md`](./04-client-integration.md) for the seam-level map this
doc packages.*
