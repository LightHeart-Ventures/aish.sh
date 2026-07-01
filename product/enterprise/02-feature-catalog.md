# Enterprise aish — Feature Catalog

*Last updated: 2026-07-01*

The complete candidate feature set for **enterprise / managed aish**, grouped by
pillar. Each feature has a stable ID (used by the stack-rank), a one-line
description, and three signals:

- **Demand** — how badly the market wants it (H/M/L)
- **Effort** — build cost (H/M/L; **L = low-hanging fruit**)
- **Head start** — does the Atum backend or aish CLI already provide primitives?

> The stack-rank and phased roadmap live in [`03-stack-rank.md`](./03-stack-rank.md).
> The competitive grounding lives in [`01-market-research.md`](./01-market-research.md).

---

## Pillar A — Managed Tiered Memory

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| A1 | **Tiered memory engine**: hot (local SQLite) → recent (server cache) → archived (vector store) with automatic promotion/demotion | H | M | `remember`/`recall` + Atum memory scopes exist |
| A2 | **Auto-summarization / compaction** of old memories into durable facts | H | M | Context-offload transcripts already exist |
| A3 | **Semantic recall** (vector search over archived tier) | H | M | sqlite-vec skill + vector infra patterns |
| A4 | **Cross-device / cross-session sync** of memory via aish.sh | H | M | Atum tenant/project memory store |
| A5 | **Scoped memory** (personal / project / team / org) with inheritance | M | L | Atum scopeKind tenant/project/agent |
| A6 | **Memory hygiene**: dedupe, retag, prune, merge (managed organizer) | M | L | `atum_memory_organize` exists |
| A7 | **Memory governance**: retention policies, PII redaction, right-to-delete | M | M | Notification PII guardrails as pattern |
| A8 | **Memory browser UI** on aish.sh (search, edit, pin, expire) | M | M | — |

## Pillar B — LLM Observability & Tuning

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| B1 | **Turn-by-turn trace capture** (tool calls, tokens, latency, errors) | H | L | Atum `orchestration_run_turns` + `agent_run_logs` |
| B2 | **Trace explorer UI** (waterfall, filter by run/agent/tool) | H | M | Search-logs/traces MCP tools exist |
| B3 | **Cost & token analytics** per session/agent/model | H | L | FOCUS `agent_runs` dataset |
| B4 | **"aish doctor" improvement recommendations**: prompt fixes, loop detection, token-waste, model-swap suggestions | H | M | First-party trace data; novel |
| B5 | **Failure-mode clustering** (recurring errors, stuck loops, retries) | M | M | Turn audit journals |
| B6 | **Evals / regression suite** for skills & agents | M | H | — |
| B7 | **Alerting** on cost spikes, error-rate, latency SLA breaches | M | L | `atum_send_notification`, usage caps |
| B8 | **OTel export** to customer SIEM/observability (Datadog, Grafana) | M | M | OTel collector already in stack |

## Pillar C — Managed Skills

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| C1 | **Org-private skill registry** (publish/share within tenant) | H | L | Atum custom skills + project scope |
| C2 | **Skill versioning + semver + changelog** | M | L | Skill `version` field exists |
| C3 | **One-command import** from GitHub / skillfish / archives | M | L | `atum_import_skill` shipped |
| C4 | **Skill signing & verification** (trust, supply-chain) | M | M | — |
| C5 | **Push-to-fleet** (admin distributes skills to all seats) | M | M | Needs fleet substrate (G) |
| C6 | **Skill resources bundling** (references, assets) | M | L | Archive/reference bundling shipped |
| C7 | **Managed skill authoring copilot** (guided SKILL.md builder) | L | L | `atum/build-skill` MCP skill |

## Pillar D — Managed MCP Servers (aish.sh proxy)

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| D1 | **MCP gateway**: single authenticated aish.sh endpoint proxying curated servers | H | H | Atum is already an MCP server |
| D2 | **Managed OAuth / secrets** for connected MCP servers (no local creds) | H | M | `${profile:KEY}` ref model |
| D3 | **One-click connectors** (GitHub, Slack, Postgres, AWS, …) like claude.ai | H | M | — |
| D4 | **Per-org allow/deny lists** for MCP servers | M | L | Depends on policy substrate (G) |
| D5 | **Call metering + rate limiting** per server/tenant | M | M | Usage metering infra |
| D6 | **MCP server health / status** dashboard | M | L | `atum_list_orchestrator_endpoints` pattern |
| D7 | **Self-host / bring-your-own MCP** registration into the gateway | M | M | Runner registration model (SPR-066) |

## Pillar E — Marketplace & Registry

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| E1 | **Public registry** aish reads by default (`:skill add`, MCP add) | H | M | OSS `registry/` dir exists |
| E2 | **Web storefront** on aish.sh (browse skills / MCP / agents / plugins) | H | M | — |
| E3 | **Verified publishers** + signing + trust badges | M | M | Ties to C4 |
| E4 | **Private / org-scoped registries** | M | M | Atum project/tenant scoping |
| E5 | **Paid & rev-share listings** (monetization) | M | H | Billing substrate needed |
| E6 | **Ratings, reviews, install counts, dependency metadata** | M | M | — |
| E7 | **Agent marketplace** (publish/hire pre-built agents) | M | M | Atum agent catalog + invoke |

## Pillar F — Identity, Security & Compliance (table stakes)

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| F1 | **SSO — SAML / OIDC** (Okta, Entra, Google) | H | M | — |
| F2 | **SCIM provisioning** (auto user lifecycle) | M | M | — |
| F3 | **RBAC + org/team/project roles** | H | M | Atum members/roles exist |
| F4 | **Immutable audit logs** (exportable, SIEM-ready) | H | M | Atum events log is the seed |
| F5 | **SOC 2 Type II** (then ISO 27001 / HIPAA path) | H | H | Process/compliance work |
| F6 | **BYOK / bring-your-own model keys** | H | M | Multi-backend support |
| F7 | **Zero-data-retention mode** | M | M | — |
| F8 | **Data residency** (region pinning) | M | H | — |
| F9 | **Self-host / VPC deployment** option | M | H | Runner/worker Docker exists |
| F10 | **Secrets vault** (managed, never store raw creds) | H | M | Credential-ref convention |

## Pillar G — Fleet, Admin & Policy

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| G1 | **Admin console** on aish.sh (seats, usage, config) | H | M | — |
| G2 | **Org policy engine**: allowed models / MCP / skills / commands | M | M | OPA skill; policy-as-code |
| G3 | **Config push / managed defaults** to all seats | M | M | — |
| G4 | **Seat management + license enforcement** | H | M | Billing substrate |
| G5 | **Remote kill-switch / revoke** for a seat or connector | M | L | — |
| G6 | **Usage caps & budgets** (soft/hard, per team) | H | L | `atum_set_usage_caps` shipped |

## Pillar H — Model Gateway / Routing

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| H1 | **Managed LLM gateway** (one endpoint, many models) | M | H | Multi-backend loop |
| H2 | **Fallback / retry / load-balance** across providers | M | M | — |
| H3 | **Semantic response caching** (cut cost) | M | M | — |
| H4 | **Model routing policy** (cheap model for cheap tasks) | M | M | `atum/pick-model` skill |
| H5 | **Spend controls at the gateway** (hard budget stop) | M | L | Usage caps |

## Pillar I — Team Collaboration & Runtime

| ID | Feature | Demand | Effort | Head start |
|----|---------|:------:|:------:|------------|
| I1 | **Shared sessions / handoff** (pair on a shell) | M | H | — |
| I2 | **Shared background coordinators** (team-visible jobs) | M | M | Background coordinator model |
| I3 | **Cloud runners** (hosted coordinators, no local box) | M | H | Runner registration (SPR-066), worker Dockerfile |
| I4 | **Durable agent state** across restarts | M | M | Durable coordinator runs exist |
| I5 | **Scheduled / triggered agents** (cron, event-driven) | M | L | Atum workflows + `scheduledAt` |
| I6 | **Notifications** (email/Slack on job done, escalations) | M | L | `atum_send_notification` shipped |

---

## Cross-cutting substrate (build once, everything depends on it)

These aren't sold as features but every pillar needs them — sequence them first:

1. **Identity & tenancy** (F1/F3) — accounts, orgs, teams, roles.
2. **Metering & billing** (G4, D5, E5, H5) — usage events + Stripe.
3. **aish CLI ↔ aish.sh auth handshake** — the CLI logging into the managed plane.
4. **Audit/event log** (F4) — the spine for compliance + observability.

Atum already provides working versions of #1, most of #4, usage caps toward #2,
and the event bus. The critical net-new glue is the **aish-CLI-to-aish.sh login +
managed-plane client**.
