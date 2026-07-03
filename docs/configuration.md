# Configuration

> Env-var inventory harvested from the aish CLI source (`src/` + `crates/`) at
> version **0.29.3**. Purpose descriptions are grounded in the source and the
> README/CHANGELOG; for exact defaults of the advanced knobs, see the CLI repo's
> [`docs/telemetry-efficiency.md`](https://github.com/LightHeart-Ventures/aish/blob/main/docs/telemetry-efficiency.md)
> and the referenced modules. Regenerate with the `aish/docs-generator` skill.

## Required

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | Claude API key — required for the default `claude` backend. Free at <https://console.anthropic.com>. |

## Launch flags

Set at launch, equivalent to the matching `:command`:

```sh
aish --backend local      # offline inference (Qwen3-1.7B, first run downloads ~4 GB)
aish --mode paranoid      # confirm every tool call
aish --mode careful       # confirm writes only
aish -c "who is alan turing"   # one-shot command, then exit
```

`:mode <paranoid|careful|normal|yolo>` is the graded safety gate — `normal`
(default) confirms only write/create/delete; `paranoid` confirms everything;
`yolo` confirms nothing. MCP tools honor the spec's `readOnlyHint`.

## Model & backend

| Variable | Purpose |
|---|---|
| `AISH_MODEL` | Default Claude model (e.g. `claude-opus-4-6`). Overridable live with `:model`. |
| `AISH_LOCAL` | Select the local inference backend. |
| `AISH_LOCAL_MODEL` / `AISH_LOCAL_MODEL_ID` | Choose the local GGUF model (e.g. `Qwen/Qwen3-4B-GGUF`) — no rebuild needed. |
| `AISH_LOCAL_MODEL_PATH` | Path to a local GGUF file instead of the HF cache. |
| `AISH_LOCAL_N_GPU_LAYERS` | Number of model layers to offload to GPU. |
| `AISH_HF_BASE` / `AISH_HF_REVISION` | Hugging Face download base URL / model revision for local-model fetch. |

## Coordinators & fan-out

| Variable | Purpose |
|---|---|
| `AISH_COORDINATOR` | Marks the process as a background coordinator (set internally). |
| `AISH_COORDINATOR_MAX_ROUNDS` | Cap on coordinator loop rounds (loop-guard). |
| `AISH_COORDINATOR_MAX_FAILED_ATTEMPTS` | Failed-attempt ceiling before a coordinator is abandoned. |
| `AISH_COORDINATOR_FAILED_KEEP` | Retain failed coordinator state for inspection. |
| `AISH_COORDINATOR_FAILED_MAX_AGE_DAYS` | Age-out window for kept failed coordinators. |
| `AISH_AUTO_RESUME_ON_CHILD_COMPLETE` | Wake the parent session when fanned-out children finish. |
| `AISH_FANOUT_TIER` | Latency tier for a fan-out (`auto` \| `interactive` \| `batch`). |

## Workers & worktrees

| Variable | Purpose |
|---|---|
| `AISH_WORKER_BELL` | Ring the terminal bell when a background job finishes (on by default; `0`/`off`/`false`/`no` to disable). |
| `AISH_WORKER_BELL_CMD` | Replace the beep with a sound player, run shell-free (e.g. `paplay …/complete.oga`). |
| `AISH_WORKER_RUNTIME` | Worker execution runtime (subprocess vs container). |
| `AISH_WORKER_CPUS` / `AISH_WORKER_CPU_SECS` | CPU count / CPU-time cap for a worker. |
| `AISH_WORKER_MEM_MB` | Memory ceiling (MB) for a worker. |
| `AISH_WORKER_PIDS` | PID limit for a worker. |
| `AISH_WORKER_NETWORK` | Worker network policy. |
| `AISH_WORKER_STATE_DIR` | Where worker state is persisted. |
| `AISH_WORKER_RETENTION_DAYS` | How long finished worker records are kept. |
| `AISH_WORKER_TRANSCRIPT_CAP` | Cap on captured worker transcript size. |
| `AISH_DRAIN_TIMEOUT` | Grace period to drain in-flight work on shutdown. |
| `AISH_WORKTREE_DIR` | Base directory for coordinator git worktrees. |
| `AISH_WORKTREE_MAX_AGE_DAYS` | Age-out window for stale worktrees. |

## Alerts

| Variable | Purpose |
|---|---|
| `AISH_ALERT_BELL` | Ring the bell when an operator alert (`:alert`) fires. |
| `AISH_ALERT_BELL_CMD` | Custom sound command for alert fires. |

## Telemetry & reasoning

All best-effort; none change behavior. See `docs/telemetry-efficiency.md` for defaults.

| Variable | Purpose |
|---|---|
| `AISH_TELEMETRY_BATCH_SIZE` | Telemetry event batch size before flush. |
| `AISH_TELEMETRY_FLUSH_SECS` | Max seconds between telemetry flushes. |
| `AISH_TELEMETRY_CACHE_SECS` | Telemetry cache TTL. |
| `AISH_TELEMETRY_UNBUFFERED` | Disable telemetry buffering (flush immediately). |
| `AISH_REASONING_LOG` | Path/toggle for the reasoning-quality JSONL log. |
| `AISH_REASONING_MEMO` | Reasoning-memo store toggle. |
| `AISH_REASONING_MEMO_FORCE_RESCAN` | Force a fresh reasoning-memo rescan. |
| `AISH_REASONING_ROTATE_MB` | JSONL rotation threshold (MB). |

## Updates

| Variable | Purpose |
|---|---|
| `AISH_UPDATE_CHANNEL` | Release channel to track (`stable` / `dev`). |
| `AISH_UPDATE_REPO` | Override the GitHub repo used by `:update`. |
| `AISH_UPDATE_CHECK_TTL` | Update-check cache TTL (force a fresh check by lowering it). |
| `AISH_UPDATE_CHECK_CACHE_PATH` | Where the update-check result is cached. |
| `AISH_RELEASE_TAG` | Pin/override the release tag for an update. |

## Skills & plugins

| Variable | Purpose |
|---|---|
| `AISH_SKILL_REGISTRY` | Override the skill registry source for `:skill add`. |
| `AISH_SKILL_DEBUG` | Verbose skill-matching diagnostics. |
| `AISH_PLUGIN_ID` / `AISH_PLUGIN_EVENTS` | Plugin identity / event subscription (set in the plugin dispatch env). |
| `AISH_IN_HOOK` / `AISH_EVENT_TYPE` | Set inside a lifecycle-hook invocation to identify the hook context. |

## Session, credentials & integrations

| Variable | Purpose |
|---|---|
| `AISH_PROFILE` | Active credentials profile (looked up in the credentials file). |
| `AISH_PROFILE_BASE` | Base for profile resolution. |
| `AISH_CREDENTIALS_FILE` | Path to the credentials file (`~/.atum/credentials`-style sections). |
| `AISH_BASE` | Base directory for aish state (defaults under `~/.aish`). |
| `AISH_SESSION_ID` | Current session id (set internally). |
| `AISH_LAUNCH_SESSION_ID` / `AISH_LAUNCH_SESSION_NAME` | Launch session identity for child processes. |
| `AISH_LOGIN_NAME` | Login-shell identity override. |
| `AISH_VERSION_STRING` | Overrides the reported version string. |
| `AISH_TENANT_ID` | Tenant scope for MCP/enterprise integrations. |
| `AISH_GITHUB_API_BASE` / `AISH_GITHUB_RAW_BASE` | Override GitHub API / raw hosts (e.g. GHES). |
| `AISH_MCPMARKET_BASE` | Base URL for the MCP marketplace. |
| `AISH_ENV_INJECTION_DISABLED` | Disable env injection into tool subprocesses. |
| `AISH_STARTUP_DIGEST` / `AISH_TIME_STARTUP` | Startup digest / timing instrumentation toggles. |

> **Note:** `AISH_PROFILE_<NAME>_*` entries you may see in tests/docs (e.g.
> `AISH_PROFILE_ACME_REGION`) are *illustrative profile keys*, not real global
> variables — they demonstrate the `${profile:KEY}` credential-reference pattern.

---

*See also: [Command Reference](./commands.md) · [Getting Started](./getting-started.md)*
