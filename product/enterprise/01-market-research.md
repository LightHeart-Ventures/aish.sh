# Enterprise aish — Market & Competitive Research

*Last updated: 2026-07-01*

This document maps the industry landscape for each capability area of an
**enterprise / managed** version of aish. For every pillar we list the incumbents,
what they charge, and the takeaway for aish. The goal is to ground our feature
list (see [`02-feature-catalog.md`](./02-feature-catalog.md)) and stack-rank
(see [`03-stack-rank.md`](./03-stack-rank.md)) in what the market actually buys today.

---

## 0. The shape of the opportunity

aish is an **open-source, AI-native shell**. The enterprise play is a classic
**open-core + managed-cloud** model: the CLI stays free/OSS to drive adoption;
`aish.sh` sells the *control plane* — the memory, observability, governance,
registries, and proxies that a solo hacker doesn't need but a team/company can't
live without.

The closest structural analogues:

| Company | OSS core | Paid control plane | Model |
|---|---|---|---|
| **HashiCorp** | Terraform CLI | Terraform Cloud (state, policy, teams) | Open-core |
| **GitLab** | CE | EE (SSO, audit, compliance) | Open-core tiers |
| **Grafana** | Grafana OSS | Grafana Cloud (managed, SSO, SLA) | Managed cloud |
| **Sentry** | SDK + OSS | Sentry SaaS (seats, quotas) | Usage + seats |
| **Warp** | (closed) terminal | Warp for Teams/Enterprise | Per-seat SaaS |

**Warp is the single most important competitor to study** — it is an AI terminal
selling Teams ($15–22/user/mo) and Enterprise (SSO, SCIM, zero-data-retention,
on-prem-ish). It validates that developers will pay per-seat for an AI terminal
with team features. aish's wedge vs Warp: **open source, MCP-native, and a true
agent loop** (not autocomplete-on-a-terminal).

---

## 1. Managed tiered memory (local → recent → archived)

**What the market does today.** "Agent memory" is one of the hottest 2024–2026
infra categories. The tiered model (working/short-term → episodic/recent →
long-term/archived, with summarization + vector recall) is now table stakes.

| Player | What it is | Pricing signal |
|---|---|---|
| **Mem0** | Managed memory API for agents; auto extract/consolidate; graph + vector | Free tier, usage-based ($) per memory ops; enterprise |
| **Zep** | Temporal knowledge-graph memory; long-term + session summaries | Cloud usage-based; self-host OSS |
| **Letta (MemGPT)** | Tiered memory OS for agents (core/archival), agent server | OSS + cloud |
| **Pinecone / Weaviate / Turbopuffer** | Vector stores under the memory | Usage per vector/query |
| **Cognee / Memobase** | Newer memory frameworks | OSS + cloud |

**Takeaway for aish.** aish already writes `remember()`/`recall()` memories and
the Atum backend exposes tenant/project/agent-scoped memory with tags + search.
The tiering (hot local SQLite → recent server cache → archived vector store),
automatic summarization/compaction, and cross-device sync are the productizable
gap. **High demand, and we have a real head start** — this is a signature feature,
not a me-too.

---

## 2. LLM tracing / observability + improvement recommendations

**What the market does today.** The LLM-observability category is crowded and
well-funded — proof the demand is real.

| Player | Focus | Pricing signal |
|---|---|---|
| **LangSmith** (LangChain) | Traces, evals, prompt hub, monitoring | Free dev; $39+/seat; enterprise |
| **Langfuse** | OSS-core tracing/evals/prompt mgmt | OSS + cloud (usage) |
| **Helicone** | Proxy-based logging, caching, cost | Free → usage tiers |
| **Braintrust** | Evals + observability, "improve your prompts" loop | Seats + usage; enterprise |
| **Arize Phoenix / Arize AX** | OSS tracing + production ML/LLM monitoring | OSS + enterprise |
| **Portkey / OpenLLMetry / Traceloop** | Gateway + OTel-based tracing | Usage |

The frontier feature — the one aish explicitly wants — is **"improvement
recommendations"**: not just *showing* traces but *analyzing* them to suggest
prompt fixes, model swaps, cheaper routing, and failure-mode clustering. Braintrust
and a wave of "eval-copilot" startups are chasing this; nobody owns it.

**Takeaway for aish.** aish is *itself* an agent loop that emits turn-by-turn tool
calls — we have first-party trace data most tools have to scrape. Atum already
stores `orchestration_run_turns`, `agent_run_logs`, and FOCUS cost datasets.
An **"aish doctor / tuning recommendations"** report (regressions, loop detection,
token waste, model-routing suggestions) is a **strong differentiator with existing
data**.

---

## 3. Managed skills + a skills marketplace

**What the market does today.** Anthropic shipped **Agent Skills** (SKILL.md +
resources) and Claude Code's plugin/marketplace pattern in late 2025; the
`agentskills.io` / `skillfish` / `npx skills add` ecosystem sprang up around it.
Cursor has "Rules"; Windsurf has "Workflows"; OpenAI has the GPT Store.

| Pattern | Example | Monetization |
|---|---|---|
| Skill registries | agentskills.io, skillfish, awesome-claude-skills | Mostly free/community today |
| App/extension stores | VS Code Marketplace, JetBrains, Raycast Store | Free + paid extensions, rev-share |
| GPT Store | OpenAI | Creator payouts (opaque) |

**Takeaway for aish.** aish already loads `SKILL.md` skills from disk, and the
Atum backend already has `atum_import_skill` (incl. skillfish/GitHub import,
archive bundling, resources) plus a built-in/custom skill catalog. **Managed
skills** = org-private skill registries, versioning, signing/verification, and
push-to-fleet. This is **low-hanging fruit — the plumbing exists**.

---

## 4. Managed MCP servers (proxied via aish.sh, "like claude.ai")

**What the market does today.** MCP went from spec (late 2024) to ubiquitous
(2025–2026). The registry/proxy layer is a land-grab:

| Player | What it is |
|---|---|
| **Smithery** | MCP server registry + hosted/proxied servers + config |
| **Composio** | Managed tool/integration layer, auth-handled MCP tools |
| **Glama / mcp.so / PulseMCP** | MCP directories + hosted gateways |
| **Pipedream / Zapier MCP** | Hosted MCP endpoints for 1000s of apps |
| **Claude.ai / ChatGPT connectors** | First-party managed MCP connectors w/ OAuth |
| **Cloudflare / Docker MCP** | Remote MCP hosting, MCP catalog + gateway |

The value the proxy adds: **managed OAuth/secrets**, one URL instead of local
installs, allow-listing/policy, usage metering, and rate limiting — exactly the
claude.ai "connectors" experience.

**Takeaway for aish.** A **`aish.sh` MCP gateway** — one authenticated endpoint
that proxies curated MCP servers, holds the OAuth tokens, meters calls, and
enforces org policy — is the highest-leverage *platform* feature. It also creates
lock-in and a natural metering point for billing. Non-trivial to build well
(auth, multi-tenant isolation, rate limits) but very high demand.

---

## 5. Marketplace + plugin/agent registry

**What the market does today.** Every successful dev platform eventually grows a
marketplace: VS Code (>50k extensions), JetBrains, Raycast Store, GitHub
Marketplace (Actions/Apps), HashiCorp Registry (Terraform modules/providers),
npm. The winning pattern: a **registry the OSS tool reads from by default** +
a **web storefront** + optional **paid/verified listings** with rev-share.

**Takeaway for aish.** aish already ships a `registry/` directory in the OSS repo.
The marketplace ties the other pillars together: skills, MCP servers, agents, and
plugins are all *listings*. Start as a **free trust layer** (discovery, signing,
verified publishers); monetize later (paid listings, private org registries,
rev-share). The moat is the **default-registry position** — whatever aish points
to on `:skill add` wins.

---

## 6. Enterprise governance / security / compliance (table stakes)

**What the market does today.** Nothing sells to a 500-person company without:

- **SSO/SAML/OIDC + SCIM** provisioning (Okta, Entra, Google)
- **RBAC** + org/team/project scoping
- **Audit logs** (immutable, exportable, SIEM-ready)
- **SOC 2 Type II**, and increasingly **ISO 27001 / HIPAA / FedRAMP** paths
- **BYOK / bring-your-own-LLM-key**, **zero-data-retention**, **data residency**
- **On-prem / VPC / self-host** option for regulated buyers
- **Secrets management** (never store raw creds; aish already uses `${profile:KEY}` refs)

Warp, LangSmith, GitLab, and every AI-dev-tool enterprise tier gate on exactly
this list. It is unglamorous but it is **the thing that unlocks the $$$ deals**.

**Takeaway for aish.** These are **prerequisites for "enterprise," not
differentiators**. Audit logs + RBAC + SSO should be built early because every
other pillar (memory, MCP proxy, marketplace) needs the same tenancy/identity
substrate. Atum already has tenants, members/roles, projects, events (audit-ish),
and usage caps — again, a head start.

---

## 7. Cost / usage management (FinOps for LLM spend)

**What the market does today.** LLM spend is a board-level line item now. Tools:
Helicone/Portkey (cost per request), Vantage/CloudZero (cloud FinOps), and the
**FOCUS 1.3** open billing spec. Buyers want budgets, per-team/-user caps,
chargeback, and "make it cheaper" routing.

**Takeaway for aish.** Atum already exposes **FOCUS-conformant `agent_runs` /
`tenant_usage_monthly` datasets, usage caps (soft/hard), and per-project budgets**.
Surfacing this as an aish "spend dashboard + budget guardrails + model-routing to
cut cost" is **low-hanging fruit riding existing infra** and pairs naturally with
the observability pillar.

---

## 8. Model gateway / routing (BYOK, fallback, caching)

**What the market does today.** LiteLLM, OpenRouter, Portkey, Cloudflare AI
Gateway: one endpoint, many models, with retries/fallback, semantic caching,
key management, and spend controls. Enterprises want **BYOK** and **no lock-in to
one model vendor**.

**Takeaway for aish.** aish already supports Claude/Grok/local backends. A managed
**model gateway** (org keys, fallback, cache, per-model policy) both saves the
customer money and gives aish a metering/pricing surface. Overlaps heavily with
the MCP-proxy and cost pillars — build the shared gateway substrate once.

---

## 9. Fleet / admin / policy management

**What the market does today.** MDM-style control for dev tooling: push config,
allow/deny lists (which MCP servers, which models, which skills), org defaults,
and remote kill-switches. Warp Enterprise, Cursor Admin, GitHub Enterprise policy.

**Takeaway for aish.** Once teams adopt aish, admins need to **standardize and
lock down** — org-wide skill/MCP allowlists, default models, secret policies. This
is a natural upsell that depends on the identity + registry substrate.

---

## Summary — where aish is advantaged

1. **Open-source wedge** → bottom-up adoption Warp can't match.
2. **MCP-native + true agent loop** → the proxy/observability data is first-party.
3. **The Atum backend already exists** — tenants, memory, skills import, agent
   catalog, workflows, orchestration-run traces, FOCUS cost data, usage caps,
   notifications. A large share of the "enterprise" plumbing is **already built**;
   the work is **productizing and exposing** it under `aish.sh`, not inventing it.

See [`02-feature-catalog.md`](./02-feature-catalog.md) for the full feature list and
[`03-stack-rank.md`](./03-stack-rank.md) for the prioritized build order.
