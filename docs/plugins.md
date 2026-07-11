# Plugins Guide

> Grounded in aish CLI version **0.29.3+**. Plugins enable community-driven skill contributions and customization.

## What is a Plugin?

A **plugin** is a packaged collection of **skills**, **MCP servers**, and lifecycle hooks that extend aish without modifying the core binary. Plugins live under `~/.aish/plugins/<id>/` and are discovered and loaded automatically on startup.

Plugins are the mechanism for:
- **Extending skill catalogs** — adding custom playbooks alongside built-in skills
- **Registering MCP servers** — bundling specialized Model Context Protocol integrations
- **Lifecycle customization** — hooking into aish events (`PreToolUse`, `PostToolUse`, etc.) to enforce policy, audit, or coordinate behavior
- **Community distribution** — sharing reusable workflows via public repos

## Plugin Directory Structure

```
~/.aish/plugins/
├── <plugin-id>/
│   ├── plugin.json              # Plugin manifest (required)
│   ├── skills/
│   │   ├── skill-1/SKILL.md
│   │   ├── skill-2/SKILL.md
│   │   └── ...
│   ├── mcp/
│   │   ├── server-config.json   # MCP server definitions (optional)
│   │   └── ...
│   ├── hooks/
│   │   └── lifecycle.js         # Event handlers (optional)
│   ├── resources/
│   │   └── ...                  # Bundled assets, docs, etc.
│   └── README.md                # Plugin documentation
```

## Plugin Manifest (`plugin.json`)

Every plugin must include a `plugin.json` at its root:

```json
{
  "id": "my-org/my-plugin",
  "version": "1.0.0",
  "name": "My Custom Plugin",
  "description": "Adds specialized workflows and integrations",
  "author": "Your Name <email@example.com>",
  "license": "Apache-2.0",
  "enabled": true,
  "skills": [
    {
      "id": "my-skill-1",
      "path": "skills/skill-1/SKILL.md",
      "enabled": true
    }
  ],
  "mcp_servers": [
    {
      "id": "my-mcp-server",
      "config_path": "mcp/server-config.json",
      "enabled": true
    }
  ],
  "lifecycle_hooks": {
    "enabled": true,
    "handlers": "hooks/lifecycle.js"
  },
  "dependencies": {
    "aish": ">=0.29.0"
  }
}
```

### Manifest Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique plugin identifier (namespace/name format recommended) |
| `version` | semver | Yes | Plugin version (follows semantic versioning) |
| `name` | string | Yes | Display name for the plugin |
| `description` | string | No | Short description of what the plugin does |
| `author` | string | No | Author name and email |
| `license` | string | No | License identifier (SPDX) |
| `enabled` | boolean | No | Whether the plugin is active (default: true) |
| `skills` | array | No | Array of skill definitions |
| `mcp_servers` | array | No | Array of MCP server definitions |
| `lifecycle_hooks` | object | No | Event hook configuration |
| `dependencies` | object | No | Version constraints (e.g., `"aish": ">=0.29.0"`) |

## Skills in Plugins

Each skill is a `SKILL.md` file following the standard aish skill format:

```yaml
---
name: example-skill
categories: [infrastructure, automation]
applies-to: [terraform, aws]
description: Automates Terraform workflows for AWS infrastructure
version: 1.0.0
tags: [iac, terraform, aws, devops]
license: Apache-2.0
---

# Example Skill

## Overview
[Skill documentation follows standard SKILL.md format...]

## Usage
...
```

Skills in plugins are auto-discovered and merged into the global skill catalog. If a plugin skill has the same `name` as an installed skill, the **installed skill wins**.

### Example: Adding a Custom Skill

```
~/.aish/plugins/my-org/my-plugin/
├── plugin.json
└── skills/
    └── deploy-app/
        └── SKILL.md
```

In `plugin.json`:
```json
{
  "skills": [
    {
      "id": "deploy-app",
      "path": "skills/deploy-app/SKILL.md",
      "enabled": true
    }
  ]
}
```

## MCP Servers in Plugins

Plugins can bundle MCP server definitions, allowing custom tools to be exposed to the agent:

```json
{
  "mcp_servers": [
    {
      "id": "my-custom-server",
      "config_path": "mcp/server-config.json",
      "enabled": true
    }
  ]
}
```

Example `mcp/server-config.json`:
```json
{
  "type": "stdio",
  "command": "python",
  "args": ["my_server.py"],
  "env": {
    "DEBUG": "1"
  }
}
```

MCP servers registered by plugins are loaded alongside core MCP servers and managed via `:mcp list` / `:mcp enable` / `:mcp disable`.

## Lifecycle Hooks

Plugins can observe or **block** aish events via lifecycle hooks. Hooks run in a **sandboxed JavaScript VM** within the aish process.

### Supported Events

| Event | When | Can Block? | Use Case |
|-------|------|-----------|----------|
| `PreToolUse` | Before any tool call (read/write/run) | Yes | Policy enforcement, audit, rate-limiting |
| `PostToolUse` | After a tool call completes | No | Logging, metrics, state synchronization |
| `PreCommand` | Before a `:command` is parsed | Yes | Command interception, routing override |
| `PostCommand` | After a `:command` completes | No | Analytics, cleanup |
| `SessionStart` | When aish starts | No | Initialization, setup |
| `SessionEnd` | When aish exits | No | Cleanup, final audit |

### Example: `hooks/lifecycle.js`

```javascript
// Audit all file writes
exports.PreToolUse = function(event) {
  if (event.toolName === 'write_file') {
    console.log(`[AUDIT] Writing ${event.input.path}`);
    
    // Block writes to /etc/
    if (event.input.path.startsWith('/etc/')) {
      return {
        blocked: true,
        reason: 'Write to /etc/ not allowed by policy'
      };
    }
  }
  return { blocked: false };
};

// Log all command executions
exports.PostCommand = function(event) {
  console.log(`[TELEMETRY] Command: ${event.command}`);
};
```

Register in `plugin.json`:
```json
{
  "lifecycle_hooks": {
    "enabled": true,
    "handlers": "hooks/lifecycle.js"
  }
}
```

## Current Plugins

The aish community and LightHeart Ventures maintain several reference plugins:

### Official Plugins

| Plugin | Purpose | Location |
|--------|---------|----------|
| `lightheart/agent-skills` | LightHeart Ventures standard skill library | GitHub |
| `lightheart/aws-mcp` | AWS SDK integration via MCP | GitHub |
| `lightheart/observability-mcp` | Observability tooling (SigNoz, datadog, etc.) | GitHub |

### Community-Contributed Plugins

| Plugin | Purpose | Maintained By |
|--------|---------|---|
| `community/terraform-skills` | Terraform automation playbooks | Community |
| `community/kubernetes-mcp` | Kubernetes API access | Community |
| `alirezarezvani/tdd-guide` | Test-driven development workflows | alirezarezvani |

Browse all plugins: `:plugin list`

## Installing a Plugin

### From GitHub

```bash
:plugin add https://github.com/owner/repo [--branch main]
```

aish clones the repo to `~/.aish/plugins/<owner>/<repo>` and loads it immediately.

### From Local Disk

```bash
# Manual setup
mkdir -p ~/.aish/plugins/my-org/my-plugin
git clone https://github.com/my-org/my-plugin ~/.aish/plugins/my-org/my-plugin
:restart  # Reload plugins
```

### Enabling/Disabling

```bash
:plugin enable <plugin-id>
:plugin disable <plugin-id>
```

Disabling a plugin keeps it on disk but prevents it from loading — skills and MCP servers remain unavailable until re-enabled.

## Creating a Plugin

### Step 1: Initialize the Plugin Structure

```bash
mkdir -p ~/.aish/plugins/my-org/my-plugin/skills
cd ~/.aish/plugins/my-org/my-plugin
```

### Step 2: Create `plugin.json`

```json
{
  "id": "my-org/my-plugin",
  "version": "1.0.0",
  "name": "My Custom Plugin",
  "description": "Adds specialized workflows",
  "author": "Your Name <email@example.com>",
  "license": "Apache-2.0",
  "enabled": true,
  "skills": []
}
```

### Step 3: Add a Skill

Create `skills/example/SKILL.md`:

```yaml
---
name: example-skill
description: An example skill from the plugin
version: 1.0.0
---

# Example Skill

[Your skill documentation here]
```

Update `plugin.json`:
```json
{
  "skills": [
    {
      "id": "example-skill",
      "path": "skills/example/SKILL.md",
      "enabled": true
    }
  ]
}
```

### Step 4: Test the Plugin

Restart aish:
```bash
:restart
```

Verify the plugin loaded:
```bash
:plugin info my-org/my-plugin
:skill list | grep example-skill
```

### Step 5: Publish

Convert to a Git repo and push to GitHub:

```bash
cd ~/.aish/plugins/my-org/my-plugin
git init
git add .
git commit -m "Initial commit: my-plugin"
git remote add origin https://github.com/my-org/my-plugin.git
git push -u origin main
```

Then others can install it with:
```bash
:plugin add https://github.com/my-org/my-plugin
```

## Plugin Development Best Practices

1. **Namespace your plugin ID** — use `org/name` format to avoid conflicts
2. **Semantic versioning** — follow semver for version bumps
3. **Clear SKILL.md** — each skill should have comprehensive documentation
4. **Document dependencies** — list aish version and MCP requirements in `plugin.json`
5. **Test lifecycle hooks carefully** — blocking hooks are powerful but can break aish if buggy
6. **Keep plugins focused** — one clear purpose beats a kitchen sink
7. **Publish as open-source** — share via GitHub so others can benefit
8. **Track issues** — use GitHub issues for bug reports and feature requests

## Lifecycle & Versioning

Plugins follow semantic versioning and should declare their aish version requirement:

```json
{
  "version": "1.2.3",
  "dependencies": {
    "aish": ">=0.29.0,<1.0.0"
  }
}
```

If a plugin declares a dependency on aish `>=0.30.0` but you're running `0.29.3`, aish will warn and skip loading the plugin.

## Troubleshooting

### Plugin not loading

Check the aish log:
```bash
:log view  # or tail ~/.aish/aish.log
```

Verify the `plugin.json` is valid JSON:
```bash
:plugin info <plugin-id>
```

### Skills not appearing

Confirm the plugin is enabled:
```bash
:plugin list
```

Check that skill paths in `plugin.json` are correct:
```bash
ls -la ~/.aish/plugins/<plugin-id>/skills/
```

### MCP server not connecting

Verify the MCP config:
```bash
:mcp list
:mcp debug <server-id>
```

Check file permissions and command availability.

## See Also

- [Architecture](./architecture.md) — how plugins integrate with aish internals
- [Commands Reference](./commands.md) — `:plugin`, `:mcp`, `:skill` commands
- [Configuration](./configuration.md) — `AISH_PLUGINS_DIR`, plugin env vars
