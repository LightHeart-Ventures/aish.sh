# Enterprise aish — Stack-Ranked Roadmap

*Last updated: 2026-07-01*

This is the prioritized build order for enterprise aish, derived from the
[feature catalog](./02-feature-catalog.md) and [market research](./01-market-research.md).
It ranks by **market demand × ease-of-build × strategic moat**, then sequences the
result into phases that respect the shared substrate every pillar depends on.

---

## Scoring model

Each feature is scored 1–5 on three axes, then combined:

> **Priority = (2 × Demand) + (1.5 × Ease) + (1.5 × Moat)**  · max 25

- **Demand** — market pull (5 = enterprises actively ask for it).
- **Ease** — inverse of build cost (5 = low-hanging fruit; primitives already exist).
- **Moat** — differentiation / lock-in (5 = hard for Warp/others to copy).

Demand is weighted highest (it decides revenue); Ease and Moat break ties between
"ship it now" and "worth doing even though it's hard."

---

## The ranking (top ~30)

| Rank | ID | Feature | Demand | Ease | Moat | **Priority** |
|:----:|----|---------|:------:|:----:|:----:|:------------:|
| 1 | B1 | Turn-by-turn trace capture | 5 | 5 | 4 | **23.5** |
| 2 | A1 | Tiered memory engine (local→recent→archived) | 5 | 3 | 5 | **22.0** |
| 2 | B3 | Cost & token analytics | 5 | 5 | 3 | **22.0** |
| 2 | B4 | "aish doctor" improvement recommendations | 5 | 3 | 5 | **22.0** |
| 2 | C1 | Org-private skill registry | 5 | 5 | 3 | **22.0** |
| 6 | A2 | Auto-summarization / compaction | 5 | 3 | 4 | **20.5** |
| 6 | A3 | Semantic recall (vector archived tier) | 5 | 3 | 4 | **20.5** |
| 6 | D2 | Managed OAuth / secrets for MCP | 5 | 3 | 4 | **20.5** |
| 6 | D3 | One-click connectors (GitHub/Slack/…) | 5 | 3 | 4 | **20.5** |
| 6 | E1 | Public default registry | 5 | 3 | 4 | **20.5** |
| 6 | G6 | Usage caps & budgets | 5 | 5 | 2 | **20.5** |
| 12 | B2 | Trace explorer UI | 5 | 3 | 3 | **19.0** |
| 12 | D1 | MCP gateway (aish.sh proxy) | 5 | 1 | 5 | **19.0** |
| 12 | E2 | Web storefront | 5 | 3 | 3 | **19.0** |
| 12 | F10 | Managed secrets vault | 5 | 3 | 3 | **19.0** |
| 16 | F1 | SSO (SAML/OIDC) | 5 | 3 | 2 | **17.5** |
| 16 | F3 | RBAC + roles | 5 | 3 | 2 | **17.5** |
| 16 | F4 | Immutable audit logs | 5 | 3 | 2 | **17.5** |
| 16 | F6 | BYOK / bring-your-own keys | 5 | 3 | 2 | **17.5** |
| 16 | G1 | Admin console | 5 | 3 | 2 | **17.5** |
| 21 | A5 | Scoped memory (personal/team/org) | 3 | 5 | 2 | **16.5** |
| 21 | A6 | Memory hygiene (dedupe/prune/merge) | 3 | 5 | 2 | **16.5** |
| 21 | B7 | Alerting (cost/error/latency) | 3 | 5 | 2 | **16.5** |
| 21 | C3 | One-command skill import | 3 | 5 | 2 | **16.5** |
| 21 | I5 | Scheduled / triggered agents | 3 | 5 | 2 | **16.5** |
| 26 | H4 | Model-routing policy | 3 | 3 | 3 | **15.0** |
| 26 | I6 | Notifications (email/Slack) | 3 | 5 | 1 | **15.0** |
| 28 | F5 | SOC 2 Type II | 5 | 1 | 2 | **14.5** |
| 29 | E5 | Paid / rev-share listings | 3 | 1 | 4 | **13.5** |
| 29 | I3 | Cloud runners (hosted coordinators) | 3 | 1 | 4 | **13.5** |
| 31 | I1 | Shared sessions / handoff | 3 | 1 | 3 | **12.0** |
| 31 | H1 | Managed model gateway | 3 | 1 | 3 | **12.0** |

*(Full feature IDs incl. lower-ranked items in [`02-feature-catalog.md`](./02-feature-catalog.md).)*

---

## The 2×2 — demand vs. ease

```
        EASE →  hard                                    easy
  D  ┌───────────────────────────────┬───────────────────────────────┐
  E  │  BIG BETS (do deliberately)    │  QUICK WINS (do first)         │
  M  │                                │                                │
  A  │  D1 MCP gateway                │  B1 trace capture              │
  N  │  F5 SOC 2                       │  B3 cost analytics             │
  D  │  I3 cloud runners               │  C1 org skill registry         │
     │  H1 model gateway               │  G6 usage caps/budgets         │
  ↑  │  E5 paid marketplace            │  B7 alerting · C3 import       │
 high│                                │  A5/A6 scoped mem · I5/I6      │
     ├───────────────────────────────┼───────────────────────────────┤
     │  FILL-INS (later / de-risk)    │  EASY-BUT-NICHE (opportunistic)│
  low│  I1 shared sessions             │  C7 skill-authoring copilot    │
     │  F8 data residency              │  D6 MCP health dashboard       │
     └───────────────────────────────┴───────────────────────────────┘

  Signature differentiators (high demand, medium effort, HIGH moat) sit on the
  center-right and are worth pushing up the schedule despite not being "easy":
    A1 tiered memory · B4 aish doctor · A2/A3 memory intelligence · D2/D3 connectors
```

---

## Phased build order

Sequenced so shared substrate lands before the features that need it. Demand-high
but moat-low "table stakes" (SSO/RBAC/audit) are pulled early because **every other
pillar needs the same identity + event spine** — you can't sell managed anything
without accounts, roles, and an audit trail.

### Phase 0 — Substrate (weeks 0–8) · *prerequisite*
The plumbing that unblocks everything. Low glamour, non-negotiable.
- **aish CLI ↔ aish.sh login handshake** (the managed-plane client)
- **Hook-forwarder binary** wired into `~/.aish/hooks.json` — the single seam that
  feeds trace ingest, memory sync, policy vetoes, and metering (no client fork; see
  [`04-client-integration.md`](./04-client-integration.md))
- **F3 RBAC / tenancy**, **F1 SSO** (Atum members/roles head start)
- **F4 audit/event log** (Atum event bus head start)
- **Metering pipeline** + **G6 usage caps/budgets** (already in Atum)

### Phase 1 — Quick wins & signature wedge (weeks 6–16) · *ship value fast*
Mostly low-effort features riding existing Atum data, **plus** the two marquee
differentiators started in parallel.
- **B1 trace capture**, **B3 cost analytics**, **B7 alerting**, **I6 notifications**
- **C1 org skill registry**, **C3 skill import**, **A5/A6 scoped memory + hygiene**
- **I5 scheduled agents**
- *Begin the moat:* **A1 tiered memory engine** · **B4 aish doctor** recommendations

### Phase 2 — Platform pillars (weeks 14–30) · *become a platform*
- **A2/A3** full memory intelligence (summarization + semantic recall + browser UI)
- **B2 trace explorer UI**, complete **B4 aish doctor**
- **D2 managed OAuth/secrets**, **D3 one-click connectors**, **F10 secrets vault**
- **E1 public registry** + **E2 web storefront**
- **F6 BYOK**, **G1 admin console**, **G2 policy engine**

### Phase 3 — Moats & big bets (weeks 28+) · *defensibility & scale*
- **D1 MCP gateway** (the claude.ai-style proxy — highest-moat platform play)
- **E5 paid / rev-share marketplace**, **E3 verified publishers**
- **H1 model gateway** + **H2/H3** fallback/caching
- **I3 cloud runners**, **I1 shared sessions / handoff**
- **F5 SOC 2 Type II**, then **F8 residency / F9 self-host** for regulated buyers

---

## The first 5 to build (if you only pick a handful)

1. **B1 — Turn-by-turn trace capture.** Highest priority score; the data spine for
   B3/B4/B7 and the observability pillar. Atum already stores the turns.
2. **C1 — Org-private skill registry.** Low effort, high demand, `atum_import_skill`
   already exists — a near-immediate "managed" story.
3. **G6 — Usage caps & budgets.** Shipped in Atum; surfacing it is pure product win
   and the first credible "enterprise control."
4. **A1 — Tiered memory engine.** The signature differentiator aish is uniquely
   positioned to own; start early because it's medium-effort and high-moat.
5. **B4 — aish doctor recommendations.** The frontier feature nobody owns yet;
   turns our first-party trace data into a "makes your agents better/cheaper" loop.

Rationale: #1–#3 are quick, demand-heavy wins that create the paid surface fast;
#4–#5 are the medium-effort, high-moat bets that make aish un-clonable by a
closed-source terminal. Together they cover observability, skills, cost, and memory —
four of the five named pillars — while the MCP-gateway moat (D1) matures behind them.

---

## Packaging & pricing hypothesis

Open-core, three paid tiers above the free OSS shell:

| Tier | Audience | Gates | Price hypothesis |
|------|----------|-------|------------------|
| **Free / OSS** | Individuals | Local CLI, bring-your-own keys, community registry | $0 |
| **Pro** | Power users | Managed memory sync, trace history, aish doctor, hosted connectors | ~$15–25/mo |
| **Team** | Startups/teams | Org registry, shared coordinators, RBAC, usage budgets, admin console | ~$25–40/user/mo |
| **Enterprise** | Companies | SSO/SCIM, audit export, BYOK, MCP gateway policy, SOC 2, self-host/VPC | Custom |

Benchmarked against Warp Teams ($15–22/user), LangSmith ($39/seat), and Cursor
Business ($40/user). Metered add-ons (MCP-gateway calls, archived-memory storage,
LLM-gateway spend) layer on top of seats.

---

*See [`README.md`](./README.md) for the enterprise-docs index.*
