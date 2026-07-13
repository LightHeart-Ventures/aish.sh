# Enterprise aish — Client ↔ Backend Integration Architecture

*Last updated: 2026-07-01*

> **Framing (per product direction):** `LightHeart-Ventures/aish` is the **open-source
> client**. The commercial offering is a **backend / control plane** that the OSS
> client plugs into through its existing extension surfaces — **hooks, skills, MCP,
> and config** — *without forking the binary*. This doc maps the seams so every
> feature in the [catalog](./02-feature-catalog.md) has a concrete attach point.

---

## The three seams the OSS client already exposes

Verified against `LightHeart-Ventures/aish` source (`src/hooks.rs`,
`src/skill_provider.rs`, `.mcp.json`):

### 1. Hooks — the primary seam (`src/hooks.rs`)
A **33-event lifecycle catalog** merged from `~/.aish/hooks.json` (user) and
project-local `.aish/hooks.json`. Each hook is a **local program** spawned
fork/exec (no shell) with a **JSON payload on stdin**. Two dispatch modes exist:

- **Observe** — best-effort, timeout-bounded, *cannot* change a turn's outcome.
- **Blocking veto** — `PreToolUse` returns `Decision::Deny(reason)`; the client
  treats it like a tool error and re-plans. (Also `PermissionRequest`, `PreCompact`,
  `ModeChanged` in later phases.)

**Trust model that matters for us:** payloads carry **no credential values** (export
key *names* only, never `${profile:…}` values); a `AISH_IN_HOOK` recursion guard
prevents loops; hooks run as the user's own UID. So the backend integration is a
**thin, safe, local forwarder** — not a privileged agent.

The full event catalog and the backend capability each feeds:

| Hook event(s) | Backend capability it powers | Pillar |
|---|---|---|
| `SessionStart`, `InstructionsLoaded`, `McpServersReady` | **Login handshake** + pull managed config (skill allowlist, MCP-gateway URL, org policy, model defaults) | Substrate, G |
| `UserPromptSubmit`, `TurnEnd`, `TurnEndFailure`, `PostToolUse`, `PostToolUseFailure` | **Trace ingest** → observability + `aish doctor` recs + cost/token analytics | **B** |
| `PreToolUse` (blocking) | **Policy engine / governance** — deny disallowed tools, commands, MCP servers, models | **F, G** |
| `PermissionRequest`, `PermissionDenied` | **Audit log** + approval workflow | **F4, G** |
| `MemoryStored`, `PreCompact`, `PostCompact` | **Tiered memory sync** (hot→recent) + **archival** (recent→archived) + summarization | **A** |
| `FileChanged` | Artifact/audit trail, change tracking | F4 |
| `SkillMatched` | **Managed-skill telemetry** + registry usage metering | **C, E** |
| `WorkerStart/Stop`, `CoordinatorPhaseChanged`, `BackgroundJobStart/Stop`, `BatchFanOut` | **Fleet/runtime observability** for hosted + local coordinators | **I, B** |
| `LoopGuardTripped`, `EscalationRequested`, `OperatorMessageReceived` | **Alerting + notifications** (email/Slack), human-in-the-loop escalation | **B7, I6** |
| `UpdateAvailable`, `UpdateApplied` | **Fleet version management** / managed rollout | **G** |
| `ModeChanged`, `BackendChanged`, `CwdChanged`, `PromptRouteDecided`, `DirectCommandRun` | Session analytics + audit enrichment | B, F4 |

### 2. MCP — the managed-proxy seam (`.mcp.json`)
The client already loads MCP servers from `.mcp.json`. Point that at a **single
authenticated `aish.sh` gateway URL** and the backend becomes the claude.ai-style
**managed MCP proxy**: it holds OAuth/secrets, curates the server list, meters calls,
and enforces per-org allow/deny — all without the user installing anything locally.
→ Powers **Pillar D** (D1/D2/D3/D5).

### 3. Skills — the managed-registry seam (`src/skill_provider.rs`)
Skill providers already resolve `SKILL.md` from GitHub/community **plugin repos**
(`community-agent-plugin`, `plugins/<x>/skills/<y>/SKILL.md`). Point the default
provider at the **`aish.sh` registry** and the backend delivers **org-private skills,
versioning, signing, and push-to-fleet** (via managed `hooks.json`/config).
→ Powers **Pillars C & E**.

---

## The net-new client-side glue (small, on purpose)

The clarification sharpens the earlier finding: we are **not** building a fork or a
heavy plugin. The entire client-side footprint of the commercial offering is:

1. **One hook-forwarder binary** (e.g. `aish-cloud` / `aishd`) wired into
   `~/.aish/hooks.json` for the events above — it authenticates once and ships
   payloads to the backend over HTTPS (and returns `Deny` for policy vetoes).
2. **A config pointer** — `.mcp.json` → gateway URL; skill provider → registry URL;
   managed `hooks.json` pulled at `SessionStart`.
3. **A login command** — `aish login` / device-code flow binding the CLI to a tenant.

Everything else lives **server-side in the backend** (the Atum-style control plane),
which already has working primitives for tenancy, scoped memory, skill import, agent
catalog, orchestration-run traces, FOCUS cost data, usage caps, and notifications.

```
┌──────────────────────────── OSS client (unchanged binary) ────────────────────────────┐
│  agent loop ──fires──> HOOKS (33 events) ──stdin JSON──> [aish-cloud forwarder]        │
│  .mcp.json ─────────────────────────────────────────────> gateway URL                  │
│  skill provider ────────────────────────────────────────> registry URL                 │
└───────────────────────────────────────────────│──────────────│─────────────────────────┘
                                                 │ HTTPS (authed, no secrets in payload)
                                                 ▼              ▼
┌──────────────────────── aish.sh commercial backend / control plane ────────────────────┐
│  Auth/tenancy · Trace ingest + aish doctor · Tiered memory · Policy/audit ·             │
│  MCP gateway (OAuth/secrets/metering) · Skill & plugin registry · Admin · Billing       │
│  (Atum backend already provides working versions of most of these primitives.)          │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Why this de-risks the roadmap

- **No fork, no binary patching** — the OSS client stays clean; upgrades never
  break the commercial layer, and OSS users can opt in with one config line.
- **Every named pillar has a real attach point today** — memory (`MemoryStored`/
  `PreCompact`), tracing (`TurnEnd`/`PostToolUse`), governance (`PreToolUse` veto),
  managed MCP (`.mcp.json`), managed skills (skill provider), fleet (`Update*`,
  `Worker*`).
- **The credential-free, recursion-guarded hook model** means the forwarder is a
  low-risk, low-privilege component — fast to ship and easy to security-review.
- It confirms **"the first 5 to build"** in [`03-stack-rank.md`](./03-stack-rank.md):
  they map 1:1 onto hook events (B1←`TurnEnd`/`PostToolUse`, A1←`MemoryStored`/
  `PreCompact`, B4←trace stream, G6←policy/metering) — so the **hook-forwarder +
  login handshake is the true Phase-0 unlock**.

---

> **Next:** [`05-aish-enterprise-plugin.md`](./05-aish-enterprise-plugin.md) packages
> this net-new glue — the hook-forwarder, config pointers, and login command — as a
> single OSS-client **plugin** (`aish_enterprise`), so the commercial layer ships
> without touching aish OSS source.

---

*See [`README.md`](./README.md) for the enterprise-docs index.*
