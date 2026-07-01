# Enterprise aish — Product Strategy

*Last updated: 2026-07-01*

**Architecture:** [`LightHeart-Ventures/aish`](https://github.com/LightHeart-Ventures/aish)
is the **open-source client**; the commercial offering is a **backend / control plane**
that the OSS client plugs into through its existing extension surfaces — **hooks,
skills, MCP, and config** — *without forking the binary*. Classic **open-core**: the
CLI stays free to drive adoption, and `aish.sh` sells the managed control plane
(memory, observability, governance, registries, and MCP/model proxies).

## Read in this order

1. **[01-market-research.md](./01-market-research.md)** — the industry landscape per
   pillar: who the incumbents are (Warp, Mem0/Zep/Letta, LangSmith/Langfuse,
   Smithery/Composio, GPT Store, HashiCorp/GitLab open-core), what they charge, and
   the takeaway for aish.
2. **[02-feature-catalog.md](./02-feature-catalog.md)** — the full candidate feature
   set across 9 pillars, each tagged with demand, build effort, and whether the Atum
   backend already provides a head start.
3. **[03-stack-rank.md](./03-stack-rank.md)** — the scored, ranked, and phased build
   order (demand × ease × moat), a demand/ease 2×2, the "first 5 to build," and a
   packaging/pricing hypothesis.
4. **[04-client-integration.md](./04-client-integration.md)** — how the backend
   attaches to the OSS client: the 33-event hook catalog mapped to backend
   capabilities, the MCP-proxy and skill-registry seams, and the small net-new
   client-side glue (a hook-forwarder + login handshake). Read this to see that
   every pillar has a concrete attach point in the existing client.

## The one-paragraph thesis

aish's enterprise wedge is **open source + MCP-native + a true agent loop**, which
Warp (closed, autocomplete-first) can't match bottom-up. The named pillars —
**tiered memory, LLM tracing + tuning recommendations, managed skills, a managed
MCP proxy, a marketplace, and a plugin registry** — are all validated markets with
funded incumbents. Crucially, **the Atum backend already ships working primitives**
for tenancy, scoped memory, skill import, an agent catalog, orchestration-run traces,
FOCUS cost data, usage caps, and notifications — so much of the "enterprise" work is
**productizing existing infrastructure under `aish.sh`**, not building from zero.

## Pillars at a glance

| Pillar | Named capability | Priority signal |
|--------|------------------|-----------------|
| A | Managed tiered memory (local→recent→archived) | High demand · high moat · head start |
| B | LLM tracing + improvement recommendations | **Highest-scoring** · first-party data |
| C | Managed skills / org registry | Low-hanging fruit (import already ships) |
| D | Managed MCP servers (aish.sh proxy) | Highest-moat platform play |
| E | Marketplace + plugin/agent registry | Ties the pillars together; default-registry moat |
| F | Identity / security / compliance | Table stakes that unlock enterprise $$$ |
| G | Fleet / admin / policy | Natural upsell on the identity substrate |
| H | Model gateway / routing | Cost lever + metering surface |
| I | Team collaboration & runtime | Cloud runners, shared coordinators, scheduling |

## First 5 to build

**B1** trace capture → **C1** org skill registry → **G6** usage caps → **A1** tiered
memory → **B4** aish doctor. See [03-stack-rank.md](./03-stack-rank.md#the-first-5-to-build-if-you-only-pick-a-handful)
for rationale.

---

*This is a living strategy doc. Sources are industry-analysis + first-party knowledge
of the aish CLI and Atum backend as of 2026-07-01; competitor pricing is directional,
verify before quoting externally.*
