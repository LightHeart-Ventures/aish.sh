# Product Roadmap

## Current Version

**v0.18.5** — Feature-complete core:
- Interactive REPL with MCP tool integration
- Claude/Grok backend support
- Session management, batch jobs, background coordinators
- Skill loading and execution

## v0.19.0 (next)

- [ ] Local llama.cpp backend (offline inference)
- [ ] Tool calling from local models
- [ ] Improved error recovery in agent loops

## v0.20.0 (Q3 2025)

- [ ] Agent marketplace / skill registry
- [ ] Durable agent state (persist across restarts)
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
