# Enterprise aish — Backend Architecture & Implementation Guide

*Last updated: 2026-07-02*  
*Status: Phase 0–1 detailed design*

---

## Overview

The commercial aish backend is a **serverless control plane** that the open-source CLI plugs into via hooks, MCP, and skills — **no binary fork**. This doc specifies the AWS technology stack, data architecture, and deployment patterns for Phases 0–3.

**Key principle:** Reuse Atum's working substrate (tenancy, memory, events, cost data, usage caps); productize it under `aish.sh`.

---

## Data Architecture: Postgres + pgvector on Neon

### Why Neon + pgvector (not Pinecone/others)

**Decision:** Use **Neon Postgres with pgvector extension** for all structured + vector data (Phase 1–2). Defer Qdrant (self-host escape hatch) to Phase 3 for on-prem enterprise deals.

| Dimension | Neon pgvector | Pinecone | Why pgvector wins |
|---|---|---|---|
| **Cost at scale** | $50–150/mo Neon compute + negligible storage | $50/mo net-new SaaS | Recall queries filter `WHERE org_id = $1`, so working set is 10–100 MB (one tenant), not 6 GB corpus. Pinecone's billion-vector speedup doesn't apply. |
| **Multi-tenancy** | SQL FK + RLS + soft-delete in one transaction | Namespaces + eventual tombstones | Right-to-delete (GDPR) must be atomic. One transaction = one backup = one audit trail. |
| **Audit trail** | One DB, one PITR timeline | Cross-system reconciliation | Compliance audits require single source of truth. Soft-delete via `deleted_at` is 2 lines of SQL. |
| **Vendor risk** | Already own Neon (Atum uses it) | Lock-in + no self-host escape | Phase 3 enterprise deals want on-prem/EU residency. Design `VectorStore` port now (swap Qdrant config later). |
| **Cold-start risk** | ⚠️ Scale-to-zero adds latency (mitigated below) | Always-on native | Mitigation: pin recall-serving endpoint, HNSW index, local query embedding. |

### Neon Configuration (Production)

```yaml
Project: aish-backend-prod
Default branch: main
Compute:
  # Three separate endpoints for different access patterns
  
  1. application (primary, always-on for phase 0-1)
     - Compute: 1 CU minimum, autoscaling 1–4 CU
     - Scale-to-zero: DISABLED (production SLA)
     - Features: IP allowlist, priority, monitoring
  
  2. recall-serving (always-on, dedicated for pgvector queries)
     - Compute: 0.5–1 CU, pinned always-on
     - Scale-to-zero: DISABLED
     - Replicas: none (single writer, Neon handles HA internally)
  
  3. analytics (scale-to-zero for batch jobs)
     - Compute: 0.5 CU with scale-to-zero, 30s idle timeout
     - For: async compaction jobs, admin queries
     - Features: read-only role, point-in-time recovery

Storage:
  - Autoscaling: enabled, on-demand pricing
  - Backups: daily, 7-day retention minimum
  - PITR: enabled (14-day window)

Databases:
  - neondb (multi-tenant application schema)
  - neondb_vector (archived memories, backups)
  - neondb_cache (session-scoped data, can be truncated)

Connection pooling:
  - PgBouncer via -pooler endpoint, 10K concurrent limit
  - Use DIRECT_URL (non-pooled) for DDL migrations only
  - Local pool size: 5–10 (Drizzle/Prisma)
```

### Schema: Multi-Tenant Memory Tiers

```sql
-- Atum tenancy anchor
CREATE TABLE orgs (
  org_id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

-- Application-scoped memories (hot tier: DynamoDB in Phase 0)
-- Synced to Postgres for full history
CREATE TABLE memories (
  memory_id UUID PRIMARY KEY,
  org_id UUID NOT NULL REFERENCES orgs,
  scope_kind TEXT, -- 'tenant', 'project', 'agent'
  scope_id UUID,   -- project or agent id
  title TEXT,
  content TEXT,
  content_type TEXT DEFAULT 'text', -- 'text', 'markdown', 'json'
  tags TEXT[],
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  deleted_at TIMESTAMP, -- soft-delete for GDPR
  archived_at TIMESTAMP, -- marks for vector archival
  
  CONSTRAINT org_scope CHECK (org_id IS NOT NULL)
);

CREATE INDEX memories_org_id ON memories(org_id);
CREATE INDEX memories_org_archived ON memories(org_id, archived_at DESC)
  WHERE archived_at IS NOT NULL;
CREATE INDEX memories_deleted ON memories(deleted_at)
  WHERE deleted_at IS NOT NULL;

-- Vector embeddings (pgvector)
-- Vectors stored alongside memories for consistency
ALTER TABLE memories ADD COLUMN embedding vector(1536); -- OpenAI dim
CREATE INDEX memories_embedding_hnsw ON memories
  USING hnsw (embedding vector_cosine_ops)
  WHERE archived_at IS NOT NULL
  AND deleted_at IS NULL;

-- Memory lifecycle tracking
CREATE TABLE memory_lifecycle (
  lifecycle_id UUID PRIMARY KEY,
  memory_id UUID NOT NULL REFERENCES memories,
  org_id UUID NOT NULL,
  event TEXT, -- 'created', 'archived', 'compacted', 'deleted'
  compacted_into_id UUID, -- reference to summary memory
  reason TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- Trace / observability spine (Phase B1)
CREATE TABLE orchestration_runs (
  run_id UUID PRIMARY KEY,
  org_id UUID NOT NULL REFERENCES orgs,
  agent_id TEXT,
  status TEXT, -- 'pending', 'running', 'completed', 'failed'
  task TEXT,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP,
  synthesis TEXT, -- Final output
  
  -- Cost tracking
  input_tokens BIGINT,
  output_tokens BIGINT,
  cost_usd NUMERIC(10, 6)
);

CREATE INDEX runs_org_status ON orchestration_runs(org_id, status);
CREATE INDEX runs_org_created ON orchestration_runs(org_id, created_at DESC);

-- Per-turn traces (Phase B1)
CREATE TABLE turn_logs (
  turn_id BIGSERIAL,
  run_id UUID NOT NULL REFERENCES orchestration_runs,
  org_id UUID NOT NULL,
  turn_number INT,
  tool_name TEXT,
  tool_input JSONB,
  tool_output JSONB,
  tool_error TEXT,
  synthesis TEXT,
  status TEXT, -- 'complete', 'failed'
  latency_ms INT,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX turn_logs_run_id ON turn_logs(run_id, turn_number);

-- Audit log (Phase F4)
CREATE TABLE audit_log (
  audit_id BIGSERIAL,
  org_id UUID NOT NULL REFERENCES orgs,
  action TEXT, -- 'memory_created', 'tool_executed', 'policy_denied', etc.
  actor_id TEXT, -- user or agent id
  resource_type TEXT,
  resource_id UUID,
  details JSONB,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX audit_log_org_created ON audit_log(org_id, created_at DESC);
CREATE INDEX audit_log_action ON audit_log(org_id, action);

-- Org policy & governance (Phase G2)
CREATE TABLE org_policies (
  policy_id UUID PRIMARY KEY,
  org_id UUID NOT NULL REFERENCES orgs,
  policy_type TEXT, -- 'allowed_models', 'allowed_tools', 'allowed_mcp'
  resource_id TEXT, -- model name, tool name, MCP server id
  allow_deny TEXT, -- 'allow' or 'deny'
  reason TEXT,
  created_at TIMESTAMP DEFAULT now(),
  
  CONSTRAINT unique_policy UNIQUE (org_id, policy_type, resource_id)
);

-- Usage metering (Phase G6, reuse Atum's atum_get_usage)
CREATE TABLE usage_events (
  event_id BIGSERIAL,
  org_id UUID NOT NULL,
  meter_type TEXT, -- 'api_calls', 'tokens', 'memory_gb', 'mcp_calls'
  amount NUMERIC(12, 6),
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX usage_org_created ON usage_events(org_id, created_at DESC);

-- Org config & settings
CREATE TABLE org_config (
  config_id UUID PRIMARY KEY,
  org_id UUID NOT NULL REFERENCES orgs UNIQUE,
  backend_url TEXT,
  mcp_gateway_url TEXT,
  skill_registry_url TEXT,
  model_gateway_url TEXT,
  scale_to_zero BOOLEAN DEFAULT FALSE,
  retention_days INT DEFAULT 30,
  updated_at TIMESTAMP DEFAULT now()
);
```

### Embedding Strategy

**Embed-on-write, query-embed-on-read:**
- When a memory is archived (moved to `archived_at`), async job computes embedding via OpenAI API (1536-dim, `text-embedding-3-small` ~$0.02 per 1M tokens).
- On `recall()`, embed the *query string* only (one small API call) and search via HNSW (`vector_cosine_ops`).
- Cache recent query embeddings per session to avoid re-embedding the same question.

**Query latency targets (Phase 1–2):**
- Encode query: 50–80 ms (OpenAI API + network)
- Vector search: 20–40 ms (HNSW on 1–10M vectors, filtered by `org_id`)
- **Total p95: <200 ms** ← achievable with pinned recall compute (0.5–1 CU, no scale-to-zero)

**Cold-start mitigations (do all three):**
1. Pin `recall-serving` endpoint to always-on (disable autoscale-to-zero).
2. Use HNSW index (robust on small tenants; no need for IVFFlat tuning).
3. *Optional (Phase 2):* Run local query-embedding model (bge-small-384, ~10 ms latency) to remove embedding API network hop if p95 still threatens SLA.

---

## Serverless Backend Stack (AWS)

### Compute & API

| Layer | Service | Config |
|-------|---------|--------|
| **API Gateway** | API Gateway (HTTP, not REST for lower latency) | — `POST /v1/orgs/{orgId}/traces` (trace ingest) — `GET /v1/orgs/{orgId}/memories?q=...` (recall) — `POST /v1/orgs/{orgId}/policy/check` (governance) — All routes: API key auth (via `x-api-key` header) + tenant scoping |
| **Compute** | Lambda (Node.js 20, provisioned concurrency for always-on paths) | — `trace-ingest` (handles hook batches) — `recall-query` (vector search, provisioned) — `policy-checker` (pre-tool-use veto) — `config-server` (hook config pull) — Timeout: 30s (recall queries must finish in ~200 ms) |
| **Async queue** | SQS (standard queue for trace batching) | — Hook forwarder sends events → SQS — Lambda batch processor (5 min retention) polls, dedups, writes to Postgres — Batch size: 100 events or 5s window (whichever first) |
| **Scheduled jobs** | EventBridge + Lambda | — `memory-compaction` (nightly, summarize old memories) — `usage-metering-batch` (hourly, aggregate usage_events) — `audit-log-cleanup` (weekly, archive old audit rows) — `trace-expiry` (30-day retention policy) |

### Secrets & Auth

| Component | Service | Pattern |
|---|---|---|
| **API auth** | Secrets Manager + custom authorizer | Lambda authorizer validates `x-api-key` header against Secrets Manager org API keys |
| **MCP credentials** | Secrets Manager | GitHub/Slack/AWS tokens stored encrypted, rotated automatically, never logged or cached locally |
| **Neon connection** | Secrets Manager | Two secrets: — `NEON_DATABASE_URL_POOLED` (application queries) — `NEON_DATABASE_URL_DIRECT` (migrations only) |
| **OpenAI embedding API** | Secrets Manager | `OPENAI_API_KEY` for embedding calls |

### Monitoring & Observability

| Metric | Tool | Alerts |
|---|---|---|
| **Trace ingest latency** | CloudWatch | P95 > 500ms per batch ⚠️ |
| **Vector search p95** | CloudWatch | >200ms or >95th-pctile-slow ⚠️ |
| **Lambda cold starts** | CloudWatch | Recall Lambda: track provisioned vs. on-demand (should be <50ms) |
| **DynamoDB errors** | CloudWatch | Any 5xx on trace ingest |
| **Neon compute CPU** | Neon dashboard + CloudWatch | >80% sustained on `application` endpoint |
| **Cost tracking** | Cost Explorer | Weekly spend trend on Lambda + Neon; alert if 2× forecast |

---

## Phase 0 Substrate — 8 weeks (prerequisite)

**Deliverables:** Hook-forwarder binary + login + trace ingest pipeline + config distribution.

### aish-cli-forwarder binary (Rust, 3–4 weeks)

Located in `/LightHeart-Ventures/aish.sh/src/bin/aish-forwarder.rs` (or separate repo if licensing prefers).

**Responsibilities:**
- Authenticate once at `SessionStart` via device-code flow; cache credentials in `~/.aish/.auth/` (0600 perms).
- On each hook event, read JSON from stdin, batch events into a queue.
- Flush to backend every 5s or when queue reaches 100 events (tunable).
- On policy hooks (`PreToolUse`), make a blocking HTTP call to `/v1/orgs/{orgId}/policy/check` and return `Deny` if policy veto'd.
- Never log credential values; use `${profile:KEY}` references only.

**Tech stack:**
- Reqwest (HTTP) for backend API calls.
- Tokio for async batching.
- Serde for JSON payloads.
- Self-sign or use Let's Encrypt for cert pinning (optional Phase 1).

**Deployment:**
- Shipped in `aish` binary via `make install` (or separate `aish-forwarder` binary).
- User wires it into `~/.aish/hooks.json` once (one config line).
- Auto-detects backend URL from `~/.aish/.config/org-config.json` or env var `AISH_BACKEND_URL`.

### Phase 0 Backend API (Lambda + Neon + SQS, 3–4 weeks)

**Endpoints:**
1. **`POST /v1/login/device-code`** — Device-code flow initiation (return `device_code`, `user_code`, `verification_uri`).
2. **`POST /v1/login/token`** — Exchange device code for `access_token` (returns scoped org/tenant).
3. **`GET /v1/orgs/{orgId}/config`** — Returns hook config, MCP gateway URL, skill registry URL, org policies.
4. **`POST /v1/orgs/{orgId}/traces/ingest`** — Accepts batched hook payloads; enqueues to SQS.
5. **`POST /v1/orgs/{orgId}/policy/check`** — Blocking policy evaluation (`PreToolUse`, `PreMCPCall`).
6. **`POST /v1/orgs/{orgId}/usage/metering`** — Record usage event (called by hook forwarder after each tool use).

**Data flow:**
```
CLI hook event → forwarder → SQS batch → Lambda processor → Postgres
                                    ↓
                              policy check (blocking)
                                    ↓
                            deny → return 403
```

### Phase 0 Database Setup (Neon + Drizzle, 1–2 weeks)

- Create Neon project `aish-backend-prod`, enable pgvector extension.
- Drizzle schema migration for multi-tenant tables (above).
- Set up connection pooling (pooled + direct URLs).
- Enable PITR (14-day window), daily backups.

### Phase 0 Auth & Tenancy (Cognito or bring-your-own, 2 weeks)

- Cognito user pool + device-code flow (or Auth0 / Okta bridge for enterprise SSO later).
- Member/role provisioning (reuse Atum's schema if possible).
- API key generation for CLI forwarder (stored hashed in DynamoDB, validated by Lambda authorizer).

---

## Phase 1 Quick Wins — weeks 6–16

Parallel to Phase 0 (starts week 6, ends week 16).

### B1 — Trace Capture & Analytics

**Flow:**
- Hook forwarder sends `TurnEnd` / `PostToolUse` events → SQS → Lambda batch processor writes to `orchestration_runs` / `turn_logs`.
- `POST /v1/orgs/{orgId}/traces/search` → Lambda queries Postgres, returns runs + turn tree.
- Phase 1: raw trace listing; Phase 2: UI with waterfall diagram.

**Cost tracking (Phase B3):**
- On each turn, record `input_tokens`, `output_tokens`, `cost_usd` (computed from pricing table).
- Aggregate endpoint: `GET /v1/orgs/{orgId}/usage/summary` → rolls up costs by agent, model, day.

### C1 — Org Skill Registry

**Flow:**
- `POST /v1/orgs/{orgId}/skills/import` — Upload SKILL.md (reuse `atum_import_skill` logic).
- Store in S3 (`s3://aish-skills-prod/orgs/{orgId}/skills/{skillId}/SKILL.md`).
- CLI skill provider at `SessionStart` pulls updated skill list from `GET /v1/orgs/{orgId}/skills/list`.
- Versioning: SKILL.md frontmatter `version: X.Y.Z`; store all versions in S3.

### G6 — Usage Caps & Budgets (Surface Atum's feature)

**Flow:**
- `POST /v1/orgs/{orgId}/usage-caps` — Set soft/hard cap (reuse Atum's `atum_set_usage_caps`).
- Lambda authorizer on metering calls: if `usage_events` total > hard cap in current period, return 429 (soft cap = warn in UI).
- Audit cap changes to `audit_log`.

### A5–A6 — Scoped Memory + Hygiene

**Flow:**
- Hook forwarder sends `MemoryStored` events → SQS → Lambda → Postgres `memories` table.
- Soft-delete via `deleted_at`; retention: auto-delete rows older than 30 days or `org_config.retention_days`.
- Organizer job (nightly): dedupe (same title + similar content hash), retag, merge related memories.
- Query endpoint: `GET /v1/orgs/{orgId}/memories?scope=project&scope_id={projectId}&tags=feature:billing`.

### I6 — Notifications (Leverage Atum's `atum_send_notification`)

**Flow:**
- On `LoopGuardTripped` or `EscalationRequested` hook events, call Atum's `atum_send_notification` API from the backend.
- Phase 2: add Slack webhooks (Lambda → Slack API).

### A1 (begin) — Tiered Memory (Design Phase, start architecture)

- Design the tiered lifecycle: hot (DynamoDB) → recent (Postgres `memories` table) → archived (vector search + S3 compacted).
- Instrument promotion/demotion logic (e.g., "move to vector archive after 30 days").

### B4 (begin) — aish doctor (Telemetry collection + initial heuristics)

- Accumulate per-session telemetry in `turn_logs` (tool latencies, errors, retries).
- Batch job (nightly) identifies patterns: repeated loop exits, high token-waste tools, model-swap opportunities.
- Phase 2: call Claude API to generate recommendations.

---

## Phase 2 Platform Pillars — weeks 14–30

### A2–A3 — Memory Intelligence (Tiered + Semantic Recall)

**Architecture:**
- Summarization job: nightly, take all memories for an org older than 30 days, call Claude to summarize, store in new "compacted" memory, soft-delete originals.
- Semantic recall: user types `?` prefix, query is embedded via OpenAI API, search pgvector via HNSW (filtered by `org_id` + `archived_at > now() - 90 days`).
- Promotion/demotion: define thresholds (e.g., "promote to recent tier if recalled 3+ times in last week").

**Cost:** ~$0.02/1M embedding tokens; at 1K users with 1K compacted memories each = ~$1/mo embedding cost.

### B2 — Trace Explorer UI

**Stack:**
- Next.js frontend (deployed on Vercel or Lambda@Edge).
- Query backend via `/v1/orgs/{orgId}/traces/search` (with filtering, sorting, pagination).
- Display: waterfall diagram of turns, latencies, errors, tool calls.
- Filter: by agent, model, tool, error type, date range.

### D2–D3 — Managed OAuth + One-Click Connectors

**Pattern:**
- User clicks "Connect GitHub" in aish.sh UI.
- Backend opens OAuth redirect to GitHub; user approves.
- Backend stores token in Secrets Manager under `orgs/{orgId}/connectors/github`.
- Hook forwarder reads connector config at `SessionStart`; CLI can use `${connector:github}` to reference the token securely.
- Similar for Slack, Postgres, AWS (AssumeRole via STS).

### F10 — Secrets Vault

**Flow:**
- `POST /v1/orgs/{orgId}/secrets` — Store a secret (encrypted at rest in Secrets Manager).
- `GET /v1/orgs/{orgId}/secrets/{secretName}` — Retrieve (audit logged).
- CLI: `${vault:db_password}` reference resolved by forwarder at runtime.

### E1–E2 — Public Skill Registry + Storefront

**Stack:**
- Public S3 bucket `aish-skill-registry-public` (CloudFront CDN).
- Admin UI to publish skills (move from org-private to public).
- Next.js storefront (search, install counts, ratings via DynamoDB).
- One-command install: `aish skill add acme/release-runbook` (downloads SKILL.md from registry).

---

## Phase 3 Moats & Big Bets — weeks 28+

### D1 — MCP Gateway (the claude.ai-style proxy)

**Architecture:**
- Kong or custom Lambda-based proxy server.
- Client `.mcp.json` points to `https://mcp-gateway.aish.sh/` (authenticated).
- Gateway proxies stdio to real MCP servers (fetched from registry, authenticated).
- Metering: count tool calls per server/org, enforce rate limits, emit to `usage_events`.
- Config: org can allow/deny specific servers via policy engine.

**Highest moat.** Defers to Phase 3 because it requires:
- Durable MCP server fleet (ECS Fargate or Lambda long-running processes).
- Proxy stdio translation (complex).
- Server health/monitoring.

### H1–H3 — Model Gateway

**Stack:**
- LiteLLM proxy (or vLLM) in Fargate.
- Routing policy engine: small task → Haiku, large task → Opus (query policy via Postgres).
- Response caching: Redis (semantic caching via Prompt Caching on Claude).
- Metering: track per-model tokens, enforce spend caps.

### I3 — Cloud Runners (Hosted Coordinators)

**Architecture:**
- ECS Fargate task fleet (auto-scaled by SQS queue depth).
- Coordinator process persists state to DynamoDB (durable across restarts).
- Team can see shared background jobs in `aish.sh` dashboard.
- Scheduler: SQS dispatch → Lambda → Fargate task + instrumentation.

---

## Deployment & Operations

### CI/CD Pipeline

```yaml
# .github/workflows/deploy-backend.yml
name: Deploy aish backend

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'
      - 'deployments/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-rust
      - run: cargo build --release -p aish-forwarder
      - run: cargo test --release
  
  deploy-backend:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - run: npm run build # Lambda functions
      - run: npx sam deploy --guided # or Terraform
  
  release-forwarder:
    runs-on: [ubuntu-latest, macos-latest, macos-latest-large]
    needs: test
    steps:
      - uses: actions/checkout@v4
      - run: cargo build --release -p aish-forwarder
      - uses: softprops/action-gh-release@v2
        with:
          files: target/release/aish-forwarder-*
          tag: forwarder-v${{ env.VERSION }}
```

### Infrastructure as Code (Terraform)

Store in `deployments/terraform/`:
- VPC, security groups (API Gateway + Lambda + Neon).
- Lambda IAM roles (Secrets Manager, SQS, Neon access, Logs).
- EventBridge rules + Lambda targets (scheduled jobs).
- S3 buckets for skills + logs.
- Neon project configuration (via Composio MCP or Terraform provider).

**Use Neon automation skill (Composio MCP) to:**
- Create project + branches (dev, staging, prod).
- Rotate API keys.
- List branches for backups.

---

## Cost Model (Year 1, 1000 users)

| Component | Usage | Cost/mo |
|---|---|---|
| **Neon compute (prod)** | 1 CU always-on + 2–3 CU burst | ~$150–250 |
| **Neon storage** | ~100 GB (1M archived memories + traces) | ~$20 |
| **Lambda (trace ingest)** | 10M invocations, 50ms avg | ~$200 |
| **Lambda (recall queries)** | 1M queries, 100ms avg | ~$100 |
| **SQS (trace batching)** | 100M messages | ~$40 |
| **S3 (skills registry)** | ~10 GB, 100K PUT/mo | ~$20 |
| **OpenAI embeddings** | 10M tokens/mo | ~$100 |
| **Observability (CloudWatch)** | Logs + metrics | ~$50 |
| **Secrets Manager** | 2–3 secrets + rotation | ~$5 |
| ****Total**** | | **~$700–800/mo** |

**Revenue:** $25/user/mo (Team tier) × 1000 users = $25K/mo. **Gross margin ~96% at scale.**

---

## Anti-Patterns (Do NOT do these)

- ❌ Pinecone for Phase 1 (scales wrongly for org-scoped queries).
- ❌ Scale-to-zero Neon in production (breaks <200ms SLA).
- ❌ Store credentials in hook payloads (use Secrets Manager + references).
- ❌ No soft-delete on memories (GDPR compliance fails).
- ❌ Cross-system audit (trace in DynamoDB, policy in Lambda, costs in Atum = fragmented truth).
- ❌ Building D1 (MCP gateway) before Phase 3 (needs durable server fleet; too early).

---

## References

- **Neon docs:** https://neon.com/docs
- **pgvector:** https://github.com/pgvector/pgvector
- **Neon + Vercel integration:** https://neon.com/docs/guides/vercel-managed-integration
- **Neon automation (Composio):** https://composio.dev/toolkits/neon
- **LiteLLM:** https://docs.litellm.ai
- **AWS SAM:** https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html

---

*Next: [04-client-integration.md](./04-client-integration.md) for hook event catalog and CLI attach points.*
