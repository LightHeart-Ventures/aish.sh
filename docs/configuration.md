# Configuration

> Env-var inventory harvested from the aish CLI source (`src/` + `crates/`) at
> version **0.29.3**. Purpose descriptions are grounded in the source and the
> README/CHANGELOG; for exact defaults of the advanced knobs, see the CLI repo's
> [`docs/telemetry-efficiency.md`](https://github.com/LightHeart-Ventures/aish/blob/main/docs/telemetry-efficiency.md)
> and the referenced modules. Regenerate with the `aish/docs-generator` skill.

## Directory structure & config files

aish uses two separate configuration layers:

### User state & home-level config (`~/.aish/`)

Central store for all user-level state, credentials, and configurations. Created
on first launch.

```
~/.aish/
├── aish.db                 # SQLite: durable memory, sessions, coordinator logs, goals
├── aish.rc                 # Shell initialization (loaded on startup; can set env vars, aliases)
├── aish.config             # JSON/TOML: user preferences (model, backend, theme, etc.)
├── .mcp.json               # MCP server definitions (Claude Desktop compatible)
├── credentials             # INI-style: credentials, profiles, secrets (not git-tracked)
├── skills/                 # User-installed skills (`:skill add`)
│   ├── my-skill/
│   │   └── SKILL.md
│   └── ...
├── plugins/                # Third-party plugins
│   ├── my-plugin/
│   │   ├── plugin.json
│   │   ├── skills/
│   │   └── ...
│   └── ...
├── worktrees/              # Git worktrees for background coordinators
│   ├── <project>--<branch>/
│   │   └── w_<id>/
│   └── ...
└── sessions/               # Session metadata & environment snapshots
    ├── <session-id>.json
    └── ...
```

### Repository-level config (`.atum/` dir in project)

When aish runs in a git repository, it discovers and uses `.atum/` for per-project
state. This directory is typically `.gitignore`-d.

```
<project>/.atum/
├── config.json             # Project-specific settings (workspace config, integrations)
├── run-<id>.jsonl          # Agent orchestration run logs (background job transcripts)
├── .mcp.json               # Project-specific MCP overrides (optional)
└── secrets.env             # Local secrets (not git-tracked)
```

## aish.rc — Shell initialization

The `~/.aish/aish.rc` file is sourced on startup and can set environment
variables, aliases, or define functions. Syntax is shell-like (POSIX subset):

```bash
# Set a preferred model
export AISH_MODEL=claude-sonnet-4-6

# Disable telemetry
export AISH_TELEMETRY_UNBUFFERED=1

# Define an alias
alias p="!git add -A && git commit && git push"

# Control the safety mode
export AISH_MODE=careful

# Set the update channel (stable by default, dev for pre-releases)
export AISH_UPDATE_CHANNEL=stable
```

Best practices:
- Use `export VAR=value` for env vars (no spaces around `=`)
- Define aliases with `alias name="command"`
- Comment with `#`
- Avoid shell constructs like pipes or conditionals — keep it declarative

### Customizing aish.rc

Edit with:
```bash
:edit ~/.aish/aish.rc
```

Then reload (without restart):
```bash
:source
```

Or restart the shell entirely:
```bash
:restart
```

## aish.config — User preferences

The `~/.aish/aish.config` file (JSON or TOML) stores user-level preferences
such as default model, backend, theme, and safety mode.

**Example (JSON):**
```json
{
  "model": "claude-opus-4-6",
  "backend": "claude",
  "mode": "careful",
  "theme": "dark",
  "telemetry_enabled": false,
  "bell_on_complete": true,
  "reasoning_memo_enabled": true
}
```

**Example (TOML):**
```toml
model = "claude-opus-4-6"
backend = "claude"
mode = "careful"
theme = "dark"

[telemetry]
enabled = false

[notifications]
bell_on_complete = true
```

These settings are used as **defaults** and can be overridden by:
1. Environment variables (highest priority)
2. Launch flags (e.g., `aish --mode paranoid`)
3. Runtime commands (e.g., `:mode normal`, `:model claude-haiku-4`)
4. This config file

## .mcp.json — MCP server definitions

The `~/.aish/.mcp.json` file (Claude Desktop–compatible format) defines all
connected MCP servers. When aish starts, it loads this file and establishes
connections to the declared servers.

**Format:**
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@atum-ai/mcp-github"],
      "env": {
        "GITHUB_TOKEN": "${profile:github_token}"
      }
    },
    "aws": {
      "command": "npx",
      "args": ["-y", "aws-cdk-tools"],
      "env": {
        "AWS_PROFILE": "default"
      }
    },
    "sqlite": {
      "command": "sqlite3",
      "args": ["/path/to/database.db"]
    }
  }
}
```

**Key points:**
- `${profile:KEY}` references a credential from `~/.aish/credentials` — secrets
  are never stored in the JSON.
- Each server has a `command` and optional `args` + `env`.
- Servers are loaded on startup; use `:mcp list` to see connected servers.
- Use `:mcp restart` to reload the file after editing.

### Project-level MCP overrides (`.atum/.mcp.json`)

A project can provide a `.atum/.mcp.json` to define or override MCP servers
for that repository only. This is useful for project-specific integrations
(e.g., a Terraform backend, custom database, proprietary tools).

## credentials — Credentials & profiles

The `~/.aish/credentials` file stores sensitive data using an INI-like format:

```ini
[github_token]
token = ghp_...

[aws]
profile = default
region = us-east-1

[anthropic]
api_key = sk-...

[custom_api]
base_url = https://api.example.com
api_key = xxx
```

Access credentials in configs and MCP definitions using `${profile:KEY}`:
```json
{
  "env": {
    "GITHUB_TOKEN": "${profile:github_token}"
  }
}
```

This pattern ensures secrets are never hardcoded in tracked files.

### Security notes

- **Never commit credentials to git.** Add `.aish/credentials` to `.gitignore`.
- **Permissions:** aish creates `~/.aish/credentials` with mode `0600` (read/write
  by owner only).
- **Profile precedence:** `:profile list` shows active profiles; `:profile switch
  <name>` changes the context.

## .atum/config.json — Project configuration

When aish is used in a git repository, a `.atum/config.json` file can store
per-project settings:

```json
{
  "project_name": "my-app",
  "orchestration": {
    "max_rounds": 20,
    "max_failed_attempts": 3,
    "fanout_tier": "interactive"
  },
  "integrations": {
    "github_owner": "LightHeart-Ventures",
    "github_repo": "my-app",
    "slack_channel": "#dev-notifications"
  },
  "workspace": {
    "root": ".",
    "entrypoints": ["src/main.rs", "Cargo.toml"],
    "lint_cmd": "cargo clippy -- -D warnings",
    "test_cmd": "cargo test",
    "build_cmd": "cargo build --release"
  }
}
```

This allows the agent to understand the project structure and adjust its
behavior accordingly.

## Environment variable precedence

Settings are resolved in this order (highest to lowest priority):

1. **Launch flags** (e.g., `aish --mode paranoid --model claude-opus-4-6`)
2. **Environment variables** (e.g., `AISH_MODE=paranoid`)
3. **aish.rc** (e.g., `export AISH_MODE=careful`)
4. **aish.config** (JSON/TOML file)
5. **Defaults** (baked into the binary)

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

*See also: [Command Reference](./commands.md) · [Getting Started](./getting-started.md) · [Architecture](./architecture.md) · [Plugin System](./plugins.md)*
