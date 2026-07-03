# Product Roadmap

## Current Version

**v0.29.3** — Shipped and stable:
- Interactive REPL with MCP tool integration
- Claude / Grok / **local (llama.cpp, offline)** backends
- Session management, batch jobs, background coordinators + fan-out
- Skill loading and execution; **plugin skill-registry**
- **Durable cross-session goals + memory** (`~/.aish/aish.db`)
- Lifecycle hooks with a `PreToolUse` blocking gate

> ⚠️ **This roadmap needs a human re-plan.** Most items previously listed as
> "next" have already shipped (see below); dates (Q3/Q4 2025) are stale.

## Shipped since this roadmap was written

- [x] Local llama.cpp backend (offline inference) — *0.19.3 / 0.20.0*
- [x] Tool calling from local models — *0.19.x*
- [x] Improved error recovery in agent loops — *0.21.0*
- [x] Skill registry (plugin-contributed skills) — *Unreleased*
- [x] Durable agent state (persist across restarts) — *goals/memory in `aish.db`*

## Still open

- [ ] Agent marketplace (browsable/publishable)
- [ ] Team-scoped shells (shared agents, auditable workflows)

## v1.0.0 (Q4 2025)

- [ ] Production stability guarantee
- [ ] Kubernetes / cloud-native runners
- [ ] Enterprise features (SAML, audit logs)

## Enterprise / Managed Tier (aish.sh control plane)

The open-core, managed offering — tiered memory, LLM tracing + tuning
recommendations, managed skills, a managed MCP proxy, a marketplace, and a plugin
registry. Full market research, feature catalog, and stack-ranked build order:

- **[Enterprise Product Strategy →](./enterprise/README.md)**
  - [Market & competitive research](./enterprise/01-market-research.md)
  - [Feature catalog (9 pillars)](./enterprise/02-feature-catalog.md)
  - [Stack-ranked roadmap + pricing](./enterprise/03-stack-rank.md)

---

*See also: [Feature Proposals](./feature-proposals/), [GitHub Issues](https://github.com/LightHeart-Ventures/aish/issues)*
