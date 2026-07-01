# Neon + pgvector — Decision Record

**Date:** 2026-07-02  
**Decision:** Use Neon Postgres + pgvector for all structured + vector data in managed aish backend (Phases 1–2). Defer Qdrant (self-host escape hatch) to Phase 3 enterprise on-prem deals.

---

## Context

Selecting a vector store for tiered memory archival (A1–A3) in the enterprise aish backend. Recall queries are always org-scoped (`WHERE org_id = $1`), so the working set is 10–100 MB per tenant, not the 6 GB corpus.

## Decision

| Dimension | Neon pgvector | Pinecone | Qdrant (Phase 3) |
|---|---|---|---|
| **Cost** | $50–150/mo Neon + storage | $50/mo net-new | $100/mo + self-host ops |
| **Multi-tenancy** | SQL FK + RLS + atomic soft-delete | Namespaces + eventual tombstones | Strong payload filtering |
| **Audit** | One DB, one PITR | Cross-system reconciliation | Self-host control |
| **Vendor risk** | Low (already own Neon) | High (lock-in, no self-host) | Low (escape hatch) |
| **SLA (<200ms p95)** | ⚠️ Cold-start mitigated | ✅ Native | ✅ Robust |
| **Phase fit** | 1–2 (core) | Fallback #1 if pgvector fails SLA | 3 (enterprise residency) |

## Why Neon pgvector wins

1. **Reuse existing infra.** Atum already uses Neon. One DB = one backup, one PITR, one audit trail. Avoids vector-store-specific security review + SLA surface.

2. **Atomic compliance.** Right-to-delete (GDPR) is a real `DELETE` in one transaction. Soft-delete via `deleted_at`. No cross-system tombstone reconciliation nightmare.

3. **Org-scoped queries don't need Pinecone's strength.** Billion-vector fast-search is wasted when every query filters to 10–100 MB. HNSW on Neon handles it.

4. **Cost is wash at Phase 1–2.** Both ~$50/mo, but pgvector is amortized over existing Neon spend; Pinecone is net-new recurring.

## Mitigations for cold-start risk

Neon's scale-to-zero can add latency. **Do all three:**

1. Pin `recall-serving` endpoint to always-on (disable autoscale-to-zero on that branch).
2. Use HNSW index (robust, no tuning needed for small tenants).
3. *Optional Phase 2:* Embed queries locally (bge-small-384 model) to remove embedding API network hop if p95 still threatens SLA.

## Fallback strategy

If load testing shows pgvector misses <200ms p95 consistently, move *only* the recall-serving path to **Pinecone serverless** (no full rewrite needed). **Design `VectorStore` interface now** — one port, swap implementations later (keeps Qdrant option open for Phase 3).

## Related docs

- `05-architecture-backend.md` — full tech stack, multi-tenant schema, Phase 0–3 roadmap.
- `03-stack-rank.md` — feature priority ranking; A1–A3 (memory intelligence) rank 2–6 overall.
- Neon skill: `/home/grhohertz/.aish/skills/neon-postgres/SKILL.md` — connection pooling, branching, cold-start best practices.
- Neon automation: `/home/grhohertz/.aish/skills/Neon-Automation/SKILL.md` — project/branch management via Composio MCP.

## Status

✅ Decided (2026-07-02). Implementation starts Phase 0 (week 1): Neon project + pgvector schema + Drizzle migrations.
