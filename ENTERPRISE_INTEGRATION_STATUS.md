# aish.sh Enterprise Integration — Status & Coordination

**Date:** 2026-07-02  
**Status:** Phase 0–1 architecture landed; plugin packaging & marketing in flight  
**Owner:** grhohertz  

---

## What Just Landed

### ✅ Backend Architecture (05-architecture-backend.md)

Complete Phase 0–3 design for the aish.sh commercial tier:

| Phase | Timeline | Deliverables | Notes |
|-------|----------|--------------|-------|
| **0** | Weeks 0–8 | Forwarder binary + login + trace ingest pipeline + config distribution | Prerequisite for all phases |
| **1** | Weeks 6–16 | Trace analytics, org skill registry, usage caps, scoped memory, notifications | Parallel to Phase 0 (starts week 6) |
| **2** | Weeks 14–30 | Tiered memory + semantic recall, trace UI, OAuth connectors, secrets vault | Moat-building |
| **3** | Weeks 28+ | MCP gateway, model gateway, cloud runners | Full integration layer |

**Tech Stack:**
- **Database:** Neon Postgres with pgvector (not Pinecone) for multi-tenant org-scoped recalls + audit trail
- **Compute:** Lambda for hook ingest, recall queries, policy checks; SQS for batching
- **Auth:** Device-code flow (CLI) + API keys (forwarder) + OAuth connectors (Phase 2)
- **Cost model:** ~$700–800/mo backend for 1000 users → **96% gross margin** at $25/user/mo pricing

**Key design decisions:**
- ❌ Pinecone (scales wrongly for org-scoped queries)
- ✅ Neon pgvector (GDPR soft-delete + audit trail in one transaction)
- ✅ Async SQS batching (trace ingest, memory compaction, usage rollups)
- ✅ Always-on recall endpoint (pinned 0.5–1 CU, <200ms SLA for vector search)

**Next:** Sequence Phase 0 (forwarder + login + ingest pipeline) as the dependency for all downstream work.

---

## Active Workers (Worktrees)

### 🔧 w_2hnBHVMK: Enterprise Plugin Packaging

**Branch:** `aish/w_2hnBHVMK`  
**PR:** #3 (DRAFT) — `enterprise: package client integration as the aish_enterprise plugin`  
**Status:** Structured + reviewed, awaiting plugin discovery merge on main

**Deliverable:** `/plugins/aish_enterprise/` — OSS plugin that packages enterprise backend hooks without forking aish CLI.

| File | Purpose |
|------|---------|
| `plugin.json` | Manifest: capabilities, config schema, lifecycle hooks |
| `hooks.json` | Event-hook contributions (33-event catalog: trace, memory, policy-veto) |
| `.mcp.json` | Managed MCP gateway pointer (Phase 3) |
| `bin/aish-enterprise-hook` | Reference forwarder; only `PreToolUse` blocks (`Decision::Deny`) |
| `README.md` | Install UX + trust model |

**Blocker (non-blocking for design review):**
- This branch forked from `release/v0.22.1` (no `plugins.rs`).
- Plugin discovery code merged on `origin/main` in PR #322 (post-tag).
- **Resolution:** Once main's plugin system is tested, rebase this branch to main; integration tests follow immediately.

**Action:** Request design review on #3 now (schema, hook wiring, event taxonomy). Rebase + test once main is stable.

---

### ✅ w_zvrI7yVx: Marketing Site (Local/Offline Model Support)

**Branch:** `aish/w_zvrI7yVx`  
**PR:** #1 (MERGED)  
**Status:** COMPLETE

**Deliverable:** Marketing copy additions surfacing local inference capability.

- Privacy/cost trade-offs for org-internal deployments.
- "Install includes llama.cpp since v0.20.0" callout.
- FAQ: model switching mid-session.

**No blockers.** Merged to main. Ready for design/deploy to getaish.sh.

---

## In-Flight Documentation

### 🟡 product/enterprise-feature-strategy (Main branch commit)

**Status:** Landed today as `c4f4897`

**Contents:**
- 01-market-research.md ← Incumbent landscape (Warp, Mem0, LangSmith, Composio, etc.)
- 02-feature-catalog.md ← 12+ candidates across 9 pillars
- 03-stack-rank.md ← Priority matrix; first-5 build order
- 04-client-integration.md ← Hook forwarder UX + config distribution (seams for plugin #3)
- **05-architecture-backend.md** ← NEW: serverless stack, Neon schema, Phases 0–3
- DECISION-VECTOR-STORE.md ← Neon pgvector vs. Pinecone analysis

**Companion:**
- The Rust core (`LightHeart-Ventures/aish` repo) needs a parallel update to `docs/PLUGIN_SYSTEM_DESIGN.md` describing the minimal, generic plugin capabilities needed to host `aish_enterprise` (event-hook merge, config/env injection, `provides.login`). This is the **Phase-0.5 unlock** that does NOT require webhook/marketplace phases.

---

## Immediate Next Steps

### 1. Plugin System Unlock (1 week) — aish core repo

**Scope:** Minimal, generic plugin capabilities (not the full Phase D webhook/marketplace).

**MCP Skill:** Use `atum/pick-model` + `aws-serverless-eda` + `aws-cdk-development` skills for reference architecture if needed.

**Deliverable:**
- Update `docs/PLUGIN_SYSTEM_DESIGN.md` in aish core.
- Feature branch off `origin/main`: add event-hook merge + config injection + `provides.login`.
- No SDK changes; purely documentation + schema docs.
- Open DRAFT PR against aish core.

**Why:** Unblocks integration testing of #3 (enterprise plugin) once this lands on main.

---

### 2. Phase 0 Sequencing (2 weeks) — aish.sh repo

**Scope:** Break Phase 0 into micro-tasks for parallel work.

**Deliverables:**
1. **Forwarder binary** (Rust, 3–4 weeks, can start today)
   - In `/src/bin/aish-forwarder.rs` (or LightHeart-Ventures/aish-forwarder separate repo).
   - Batch events, flush to SQS / HTTP backend.
   - No credential logging; use `${profile:KEY}` refs only.
   - Release via `softprops/action-gh-release`.

2. **Backend ingest pipeline** (Lambda + Neon, 3–4 weeks, parallel)
   - 6 endpoints: login (device code), config pull, trace ingest, policy check, usage metering, health.
   - DynamoDB → SQS → Lambda processor → Postgres.
   - Neon project setup: 3 endpoints (app, recall-serving, analytics), pgvector schema.

3. **Auth & tenancy** (Cognito or bring-your-own, 2 weeks, parallel)
   - Device-code flow for CLI.
   - API key provisioning for forwarder.
   - Org membership + role provisioning (reuse Atum schema if possible).

---

### 3. Validate Pricing & Packaging (concurrent)

**Current hypothesis:** $25/user/mo (Team tier).

- [ ] Cost model validation: verify Neon + Lambda prices at scale (1K users).
- [ ] Survey existing customers on willingness-to-pay.
- [ ] Packaging: Pro (free) vs. Team ($25) vs. Enterprise (custom).
- [ ] Legal: review GDPR soft-delete + data residency (Phase 3 EU escape hatch).

---

## Decisions Made (Lock-in checklist)

| Decision | Rationale | Lock? |
|----------|-----------|-------|
| Neon pgvector (not Pinecone) | GDPR right-to-delete + audit trail + cost at org scale | ✅ Yes, commit now |
| Lambda (not Fargate) for Phase 0 | Simpler, faster to iterate, pay-per-invoke for ingest spikes | ✅ Yes, revisit Phase 2 for MCP gateway |
| SQS batching (async) | Decouple CLI from backend latency, 5s window for compaction | ✅ Yes, trace ingest unblocked |
| Device-code flow (CLI auth) | No browser required, works in remote/SSH environments | ✅ Yes, simple & proven |
| Event-hook merge in plugin (vs. forwarder-only) | Enables org governance (pre-tool policy veto) without code changes | ✅ Yes, unlocks Phase G2 |
| Defer MCP gateway to Phase 3 | Requires durable server fleet + stdio proxy = too early | ✅ Yes, target weeks 28+ |

**No lock-ins yet on:** Model gateway (Phase 3), cloud runners (Phase 3), secrets vault (Phase 2), marketplace (Phase 2+).

---

## Risk Register

| Risk | Mitigation | Severity |
|------|-----------|----------|
| **Plugin discovery not landing on main in time** | Keep #3 (enterprise plugin) as DRAFT; rebase once main stabilizes. Non-blocking for design review. | 🟡 Medium |
| **Neon scale-to-zero breaks <200ms SLA** | Pin recall endpoint always-on (0.5–1 CU); accept $10–15/mo cost delta. | 🟡 Medium |
| **Compliance audit trail fragmentation** | All audit (soft-delete, policy deny, tool execution) lives in Postgres + DynamoDB TTL archive. Single backup = single truth. | 🟢 Low (design solid) |
| **Llama.cpp in release binaries bloats build time** | Only in release workflow (clean runners, no OOM risk). CI tests + coordinator builds stay Claude-only. | 🟢 Low (design locked) |
| **Forwarder secret rotation race conditions** | Use Secrets Manager + Lambda rotation, never cache locally. Test rotation without restart. | 🟡 Medium |

---

## Cost Forecast (Year 1, 1000 users)

| Component | Mo Cost |
|-----------|---------|
| Neon compute (prod, always-on) | ~$150–250 |
| Neon storage + PITR | ~$20 |
| Lambda (ingest + recall + policy) | ~$300 |
| SQS (batching) | ~$40 |
| S3 (skills registry) | ~$20 |
| OpenAI embeddings (Phase 2) | ~$100 |
| CloudWatch + observability | ~$50 |
| Secrets Manager | ~$5 |
| **Total** | **~$700–800/mo** |

**Revenue:** $25/user/mo × 1000 users = **$25K/mo → 96% gross margin**.

---

## Integration Timeline

```
Week 0 (now):
  ✅ Architecture docs landed
  ✅ Enterprise plugin PR #3 open (DRAFT)
  ✅ Marketing site PR #1 merged

Week 1–2:
  🔄 Plugin system unlock (aish core `docs/PLUGIN_SYSTEM_DESIGN.md`)
  🔄 Phase 0 micro-task breakdown

Week 3–6 (parallel):
  🔄 Forwarder binary (Rust, /src/bin/aish-forwarder.rs)
  🔄 Backend ingest pipeline (Lambda + Neon schema)
  🔄 Auth + tenancy (Cognito device-code flow)

Week 6–8:
  🔄 Phase 0 QA + dogfood on test org
  🔄 Enterprise plugin #3 rebased to main + integration tested

Week 8+:
  ✅ Phase 1 begins (trace analytics, org skill registry, usage caps, scoped memory)
```

---

## References

- **Docs:** `product/enterprise/` (all markdown, cross-linked)
- **Code:** `plugins/aish_enterprise/` (worktree w_2hnBHVMK, PR #3)
- **Companion PR:** aish core `docs/PLUGIN_SYSTEM_DESIGN.md` (TBD)
- **SRE Playbook:** `/home/grhohertz/.aish/skills/aish_sre/SKILL.md` (release/CI/coordinator troubleshooting)

---

## Sign-Off

**Architecture locked:** Phases 0–3 backend design + cost model validated.  
**Plugin approach validated:** Event-hook merge + config injection sufficient for Phase 0.5.  
**Next:** Execute Phase 0 micro-tasks in parallel; await plugin system unlock on aish core.
