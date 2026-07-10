# aish.sh Enterprise Integration — Handoff Document

**Date:** 2026-07-02  
**Status:** Phase 0–1 architecture complete; ready for Phase 0 execution  
**Owner (outgoing):** grhohertz  
**Recommended next owner:** DevOps/Backend lead  

---

## Executive Summary

**What:** Enterprise tier for the aish AI shell — multi-tenant backend that CLI plugs into via hooks/MCP without forking source.

**Why:** Open-core market validation (Atum infrastructure already ships primitives). $25/user/mo Team tier pricing → 96% gross margin at 1K users.

**Current state:** Architecture locked (Phases 0–3 fully designed). Two PRs in-flight (plugin scaffold + marketing site). **Ready to begin Phase 0 execution (8-week critical path).**

**What you're inheriting:**
- Complete backend stack design (Neon pgvector, Lambda, SQS, serverless)
- Enterprise plugin structure (3 PRs, DRAFT → merge-ready after core plugin system lands)
- Phase 0–3 sequenced into micro-tasks
- Cost model validated (~$700–800/mo backend for 1K users)
- Risk register + decision log

---

## The Work — What's Done, What's Next

### ✅ Complete (Ready to hand off)

| Deliverable | Location | Status | Owner |
|---|---|---|---|
| **Architecture (Phases 0–3)** | `product/enterprise/05-architecture-backend.md` | ✅ Complete | Docs |
| **Market research** | `product/enterprise/01-market-research.md` | ✅ Complete | Strategy |
| **Feature catalog** | `product/enterprise/02-feature-catalog.md` | ✅ Complete | Strategy |
| **Stack ranking** | `product/enterprise/03-stack-rank.md` | ✅ Complete | Strategy |
| **Client integration** | `product/enterprise/04-client-integration.md` | ✅ Complete | Design |
| **Vector store decision** | `product/enterprise/DECISION-VECTOR-STORE.md` | ✅ Complete | Design |
| **Neon config + schema** | Section 2 in `05-architecture-backend.md` | ✅ Complete | Docs |
| **Lambda stack** | Section 3 in `05-architecture-backend.md` | ✅ Complete | Docs |
| **Plugin structure** | `plugins/aish_enterprise/` (PR #3) | ✅ Structured | Design |
| **Integration status** | `ENTERPRISE_INTEGRATION_STATUS.md` (this repo) | ✅ Complete | Docs |
| **Marketing copy (local models)** | `marketing/` (PR #1 merged) | ✅ Merged | Copy |

### 🔄 In-Flight (Awaiting decisions/dependencies)

| Deliverable | Status | Blocker | Next Owner Action |
|---|---|---|---|
| **Plugin discovery merge** | aish core `origin/main` has PR #322; needs review | Plugin system docs | Review + test on aish core; unblocks enterprise plugin #3 |
| **Enterprise plugin #3** | DRAFT PR, awaiting plugin system unlock | Plugin discovery | Rebase to main post-unlock; integration test |
| **Phase 0.5 (plugin system docs)** | Companion doc needed on aish core | None | Write `docs/PLUGIN_SYSTEM_DESIGN.md` update (event-hook merge, config injection, `provides.login`) |

### 📋 Ready to Start (Phase 0, weeks 1–8)

**Three parallel workstreams. Each is 3–4 weeks; can start today.**

#### 1. Forwarder Binary (Rust, 3–4 weeks)

**What:** CLI hook-event forwarder binary that batches + sends to backend.

**Where to build:** `/src/bin/aish-forwarder.rs` in aish core, or new repo `LightHeart-Ventures/aish-forwarder`.

**Key responsibilities:**
- Authenticate via device-code flow (one-time CLI handshake).
- Cache credentials in `~/.aish/.auth/` (0600 perms).
- On each hook event, batch into queue (flush every 5s or 100 events).
- On `PreToolUse` hooks, **block** (make HTTP call to `/v1/orgs/{orgId}/policy/check`, return `Deny` if policy veto'd).
- Never log credential values; use `${profile:KEY}` references only.

**Tech stack:**
- Reqwest (HTTP client).
- Tokio (async batching).
- Serde (JSON payloads).

**Deployment:**
- Release via `softprops/action-gh-release` (same as aish binary).
- Auto-discovered by hook discovery on user's first `:aish enterprise login`.

**Starting point:** Read `product/enterprise/04-client-integration.md` (hook event catalog + forwarder UX spec).

---

#### 2. Backend Ingest Pipeline (Lambda + Neon, 3–4 weeks)

**What:** 6 serverless endpoints for hook ingest, trace ingestion, policy checking, config distribution.

**Where to build:** New repo `LightHeart-Ventures/aish-backend` (or in `aish.sh` under `/backend` if keeping monorepo).

**Endpoints:**
1. `POST /v1/login/device-code` — Device-code flow initiation.
2. `POST /v1/login/token` — Exchange code for `access_token`.
3. `GET /v1/orgs/{orgId}/config` — Return hook config, MCP gateway URL, policy rules.
4. `POST /v1/orgs/{orgId}/traces/ingest` — Batch hook payloads → SQS.
5. `POST /v1/orgs/{orgId}/policy/check` — Blocking policy evaluation.
6. `POST /v1/orgs/{orgId}/usage/metering` — Record usage events.

**Data flow:**
```
CLI forwarder event → SQS → Lambda processor → Postgres
                       ↓
                 policy check (blocks PreToolUse)
```

**Infrastructure:**
- **Compute:** Lambda (Node.js 20, provisioned concurrency for recall paths).
- **Queue:** SQS (standard, 5-min retention, batch 100 events or 5s window).
- **Database:** Neon Postgres (see schema section below).
- **Auth:** Cognito (device-code flow) or Auth0 (for Phase 2 SSO).
- **Secrets:** Secrets Manager (API keys, MCP credentials, Neon DSN).

**Database schema:** See Section 2 of `05-architecture-backend.md` — 7 tables (orgs, memories, memory_lifecycle, orchestration_runs, turn_logs, audit_log, org_policies, usage_events, org_config). Start with orgs + memories; backfill traces + audit after.

**Neon setup checklist:**
- [ ] Create project `aish-backend-prod`.
- [ ] Enable pgvector extension.
- [ ] Set up 3 endpoints: app (always-on), recall-serving (pinned, always-on), analytics (scale-to-zero).
- [ ] Enable PITR (14-day window), daily backups.
- [ ] Run Drizzle/Prisma migrations.

**Starting point:** Read `product/enterprise/05-architecture-backend.md`, sections 1–2 (Neon config) and section 3 (Lambda stack).

---

#### 3. Auth & Tenancy (2 weeks)

**What:** Org membership, API key provisioning, device-code flow setup.

**Key pieces:**
- Device-code flow (CLI handshake, no browser needed).
- Org creation + member provisioning (likely reuse Atum schema if available).
- API key hashing + rotation (Secrets Manager + Lambda rotation).
- Role provisioning (owner, member, viewer; gates on API endpoints).

**Tech:**
- Cognito (preferred for simplicity; device-code is built-in).
- *Alternative:* Auth0 or bring-your-own (OIDC federation for Phase 2 enterprise SSO).

**Starting point:** Read `product/enterprise/05-architecture-backend.md`, section 3 (Auth & secrets table).

---

## Critical Decisions (Lock-in Checklist)

**These are LOCKED. Do NOT revisit unless business req changes:**

| Decision | Rationale | Consequence if changed |
|----------|-----------|------------------------|
| **Neon pgvector** (not Pinecone) | GDPR soft-delete + audit trail + org-scoped cost | Re-architect vector queries; lose atomic deletes |
| **Lambda** (not Fargate/ECS) | Phase 0 velocity; pay-per-invoke for ingest spikes | Re-write ingest pipeline; different scaling model |
| **SQS batching** (async) | Decouple CLI latency; enables async compaction jobs | Trace ingest becomes synchronous; slow CLI |
| **Device-code flow** (CLI auth) | Works in SSH/remote; no browser needed | Force browser-based login; breaks headless ops |
| **Event-hook merge in plugin** | Governance without code fork; enables org policy veto | Policy must live outside Atum; audit trail fragmented |
| **Defer MCP gateway to Phase 3** | Phase 0 focus; webhook fleet is complex | MCP proxy unavailable until week 28+ |

**Decisions NOT yet locked** (revisit in Phase 2–3):
- Model gateway vendor (Phase 3).
- Cloud runners / hosted coordinators (Phase 3).
- Secrets vault vs. Secrets Manager only (Phase 2).
- Marketplace / skills storefront (Phase 2+).

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| **Plugin system code review delays** | Blocks enterprise plugin testing | 🟡 Medium | Keep plugin #3 as DRAFT; design review in parallel while core review is live |
| **Neon scale-to-zero latency breach** | Vector search exceeds <200ms SLA | 🟡 Medium | Pin recall endpoint always-on (0.5–1 CU); accept $10–15/mo cost delta |
| **Forwarder credential leaks in logs** | Production incident | 🟢 Low | Use `${profile:KEY}` references; never log credential values; audit forwarder output |
| **Compliance audit fragmentation** | Audit failures, failed SOC 2 | 🟢 Low | Design locks all audit into single Postgres; soft-delete + PITR ensures right-to-delete |
| **Llama.cpp in release binaries (aish core)** | OOM-kills build runners | 🟢 Low | Only in release workflow (clean runners); CI tests + coordinator stay Claude-only (locked in aish SRE skill) |
| **Forwarder secret rotation race** | Forwarder can't auth during rotation | 🟡 Medium | Use Secrets Manager + Lambda rotation; test rotation without restart; cache locally with short TTL only |
| **Pricing validation fails** | $25/user/mo rejected by market | 🟡 Medium | Survey existing Atum customers on willingness-to-pay; adjust tier positioning if needed |
| **Neon connections exhaust pool** | Forwarder can't send traces | 🟢 Low | Use PgBouncer pooled endpoint (10K concurrent); test load at 2× projected scale |

---

## Timeline & Sequencing

```
Week 1–2:
  ✅ Plugin system unlock (aish core PLUGIN_SYSTEM_DESIGN.md review + merge)
  ✅ Phase 0 micro-task breakdown (this handoff doc)

Week 3–6 (parallel):
  🔄 Forwarder binary (Rust, /src/bin/aish-forwarder.rs or separate repo)
  🔄 Backend pipeline (Lambda + Neon, 6 endpoints + schema)
  🔄 Auth setup (Cognito device-code flow + org tenancy)

Week 6–8:
  🔄 Phase 0 QA + dogfood on test org
  🔄 Enterprise plugin #3 rebased to main + integration tested
  ✅ Phase 0 complete

Week 8+ (Phase 1):
  ⏭️ Trace analytics (B1)
  ⏭️ Org skill registry (C1)
  ⏭️ Usage caps + metering (G6)
  ⏭️ Scoped memory (A5–A6)
  ⏭️ Notifications (I6)
```

---

## Key Documents & Repositories

| Type | Location | Owner |
|---|---|---|
| **Architecture** | `product/enterprise/05-architecture-backend.md` | Docs (read first) |
| **Feature catalog** | `product/enterprise/02-feature-catalog.md` | Strategy (reference) |
| **Client integration spec** | `product/enterprise/04-client-integration.md` | Design (forwarder UX) |
| **Integration status** | `ENTERPRISE_INTEGRATION_STATUS.md` (this repo) | Ops (current state) |
| **aish SRE playbook** | `/home/grhohertz/.aish/skills/aish_sre/SKILL.md` | Troubleshooting (release/CI/coordinator issues) |
| **Plugin structure** | `plugins/aish_enterprise/` (PR #3) | Dev (awaits unlock) |

**Companion repositories (to create):**
- `LightHeart-Ventures/aish-backend` (Lambda + Neon backend) — or in `aish.sh/backend` monorepo.
- `LightHeart-Ventures/aish-forwarder` (Rust CLI forwarder) — or in aish core `src/bin/aish-forwarder.rs`.

---

## Cost Model (Year 1, 1000 users)

| Component | Mo Cost | Notes |
|-----------|---------|-------|
| Neon compute (prod) | $150–250 | 1 CU always-on + 2–3 CU burst |
| Neon storage + PITR | $20 | ~100 GB (1M memories + traces, 14-day PITR) |
| Lambda ingest | $200 | 10M invocations, 50ms avg |
| Lambda recall | $100 | 1M queries, 100ms avg |
| SQS batching | $40 | 100M messages |
| S3 skills registry | $20 | ~10 GB, 100K PUT/mo |
| OpenAI embeddings (Phase 2) | $100 | 10M tokens/mo |
| CloudWatch | $50 | Logs + metrics |
| Secrets Manager | $5 | 2–3 secrets + rotation |
| **Total** | **~$700–800/mo** | **96% gross margin @ $25/user/mo** |

---

## Handoff Checklist

### Before you start:

- [ ] Read `product/enterprise/05-architecture-backend.md` (backend design).
- [ ] Read `product/enterprise/04-client-integration.md` (hook event catalog).
- [ ] Read this handoff doc entirely.
- [ ] Review `ENTERPRISE_INTEGRATION_STATUS.md` for current state.
- [ ] Skim aish_sre skill for release/CI/coordinator troubleshooting patterns.
- [ ] Check PR #1 (marketing, merged) and PR #3 (plugin, DRAFT).

### Phase 0 task list:

#### Forwarder (3–4 weeks)
- [ ] Set up Rust project + Reqwest + Tokio.
- [ ] Implement device-code auth flow (CLI handshake).
- [ ] Implement hook batching (queue, 5s flush, 100-event batch).
- [ ] Implement `PreToolUse` policy blocking (HTTP call + Deny response).
- [ ] Logging (no credential values; ${profile:KEY} only).
- [ ] Release build + asset signing.
- [ ] Open PR on aish core (or new repo).

#### Backend (3–4 weeks)
- [ ] Create Neon project `aish-backend-prod`.
- [ ] Set up 3 Neon endpoints (app, recall-serving, analytics).
- [ ] Enable pgvector extension.
- [ ] Implement Drizzle/Prisma schema (7 tables, min start: orgs + memories).
- [ ] Set up SQS queue (standard, 5-min retention).
- [ ] Implement 6 Lambda functions (login, config, ingest, policy, metering, health).
- [ ] Set up Cognito device-code flow (or Auth0 for Phase 2).
- [ ] Test load at 2× scale (100K events/hr → 200K events/hr).
- [ ] Open PR on new repo + deploy to dev environment.

#### Auth (2 weeks)
- [ ] Cognito user pool + device-code config.
- [ ] Org membership + role provisioning.
- [ ] API key generation + hashing (Secrets Manager).
- [ ] Lambda authorizer on all endpoints.
- [ ] Test device-code flow end-to-end (CLI handshake → org access token).

### Deployment readiness:

- [ ] Phase 0 QA on test org (forwarder + backend + auth).
- [ ] Dogfood internally (1–2 weeks, catch unknown unknowns).
- [ ] Security review (credential handling, audit trail, GDPR).
- [ ] Cost validation (monitor actual Neon/Lambda spend vs. model).

---

## Known Unknowns / Questions for Next Owner

1. **Neon connection pooling:** Will 10K PgBouncer limit hit before 1K users? (Estimate: no, but monitor.)
2. **API key rotation without restart:** Can Secrets Manager rotation work without killing active forwarder? (Design says yes; test thoroughly.)
3. **Atum memory schema reuse:** Can we reuse Atum's scoped-memory table structure, or must we define our own? (Check Atum SDK / schema.)
4. **Device-code flow fallback:** If CLI doesn't support Cognito device-code natively, do we bundle a mini-server? (Likely yes; see forwarder spec.)
5. **Phase 1 timing:** Can we start Phase 1 work in parallel to Phase 0 QA (week 6–8), or must Phase 0 ship first? (Recommend parallel, but Phase 0 is on critical path.)

---

## Transition Contacts

| Role | Name | Availability | Handoff method |
|------|------|--------------|---|
| **Architecture owner** | grhohertz | — | Docs (this repo) + PR reviews |
| **Product lead** | — | TBD | Weekly syncs on Phase 0 progress |
| **Engineering lead** | — | TBD | Daily standups (w/ Slack escalation channel) |

---

## Sign-Off

**Outgoing:** Architecture complete, locked, and documented. All Phase 0–3 design decisions made. Two PRs in-flight (plugin + marketing); neither blocks Phase 0 execution. **Ready to hand off to engineering.**

**Recommended next owner:** Backend/DevOps lead with Lambda + Postgres experience.

**Success criteria for Phase 0:**
- Forwarder binary ships + passes release CI.
- Backend endpoints pass load test (200K events/hr).
- Auth flow works end-to-end (CLI → org dashboard).
- Phase 0 complete with <10 production incidents in dogfood.

---

*Questions? Read the architecture doc first, then open an issue on this repo. For aish core issues (build OOM, release failures, coordinator loops), consult the aish_sre skill.*
