# Plugin System

The aish plugin system allows you to extend the shell with custom skills, MCP servers, and lifecycle hooks without modifying the core binary.

## Overview

**Plugins** are self-contained packages that live under `~/.aish/plugins/<id>/` and contribute:
- **Skills** — expert playbooks (SKILL.md files) that augment the skill catalog
- **Lifecycle hooks** — observers and gates that run before/after tool calls
- **Configuration** — declared via `plugin.json` at the plugin root

Each plugin is identified by a unique `<id>` (e.g., `hello-world`, `custom-ops`). When aish starts, it discovers all installed plugins, merges their skills into the catalog, and registers any lifecycle hooks.

## Plugin structure

```
~/.aish/plugins/<id>/
├── plugin.json          # Metadata and lifecycle hook declarations
├── skills/              # (Optional) SKILL.md files
│   ├── my-skill/
│   │   └── SKILL.md
│   └── another-skill/
│       └── SKILL.md
├── mcp-servers/         # (Optional) MCP server definitions
│   └── custom-mcp.json
└── README.md            # Plugin documentation
```

## plugin.json schema

```json
{
  "id": "custom-ops",
  "name": "Custom Operations",
  "version": "1.0.0",
  "description": "Custom skills and hooks for team workflows",
  "author": "Your Name",
  "license": "MIT",
  "aish_version": ">=0.25.0",
  "lifecycle_hooks": [
    {
      "event": "PreToolUse",
      "handler": "custom-ops/hooks/pre_tool_use.sh"
    },
    {
      "event": "PostToolUse",
      "handler": "custom-ops/hooks/post_tool_use.sh"
    }
  ],
  "skills": [
    {
      "id": "custom-deploy",
      "path": "skills/custom-deploy/SKILL.md"
    }
  ]
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique plugin identifier (lowercase, kebab-case) |
| `name` | string | Yes | Human-readable plugin name |
| `version` | string | Yes | Semantic version (e.g., `1.0.0`) |
| `description` | string | Yes | Short description of what the plugin does |
| `author` | string | No | Plugin author name/email |
| `license` | string | No | SPDX license identifier |
| `aish_version` | string | No | Minimum aish version required (e.g., `>=0.25.0`) |
| `lifecycle_hooks` | array | No | List of event handlers (see below) |
| `skills` | array | No | List of skills contributed by this plugin |

## Lifecycle hooks

Hooks run at key points in the aish lifecycle. Two events are currently supported:

### PreToolUse

Fires **before** a tool is invoked. The handler receives:
- `TOOL_NAME` — name of the tool (e.g., `run_program`)
- `TOOL_INPUT` — tool arguments as JSON
- `MODE` — confirmation mode (`paranoid`, `careful`, `normal`, `yolo`)

**Handler must exit with:**
- `0` — allow the tool call (proceed normally)
- `1` — block the tool call (treat as a denial, emit an error)
- Any other exit code — warning, but allow the call

Example handler:

```bash
#!/bin/bash
# hooks/pre_tool_use.sh — block rm on production paths

if [[ "$TOOL_NAME" == "run_program" ]]; then
  if grep -q "rm -rf /prod" <<< "$TOOL_INPUT"; then
    echo "❌ Blocked: dangerous rm on production path"
    exit 1
  fi
fi

exit 0
```

### PostToolUse

Fires **after** a tool completes (success or failure). The handler receives:
- `TOOL_NAME` — name of the tool
- `TOOL_RESULT` — tool output/result
- `TOOL_EXIT_CODE` — exit code (0 = success)

Handler exit code is ignored; use for logging, metrics, or notifications.

Example handler:

```bash
#!/bin/bash
# hooks/post_tool_use.sh — log slow operations

start=$(date +%s%N)
duration=$(( ($(date +%s%N) - start) / 1000000 ))

if (( duration > 5000 )); then  # > 5 seconds
  echo "⚠️  Slow tool: $TOOL_NAME took ${duration}ms"
fi
```

## Skills in plugins

Skills contributed by a plugin are discovered from the `skills/` directory and merged into the global skill catalog. Each subdirectory becomes a skill:

```
plugins/custom-ops/skills/
├── deploy-k8s/
│   ├── SKILL.md
│   └── assets/
│       └── deploy.sh
└── audit-repo/
    └── SKILL.md
```

When `:skill list` runs, both `deploy-k8s` and `audit-repo` are discoverable alongside built-in skills. If a plugin skill has the same name as an installed skill, **the installed skill takes precedence**.

### Skill metadata in plugin.json (optional)

You can declare skills explicitly to add metadata:

```json
{
  "skills": [
    {
      "id": "deploy-k8s",
      "path": "skills/deploy-k8s/SKILL.md",
      "category": "devops",
      "tags": ["kubernetes", "deployment"]
    }
  ]
}
```

## Installing plugins

### From a local directory

```bash
# Copy a plugin into ~/.aish/plugins
mkdir -p ~/.aish/plugins/my-plugin
cp -r /path/to/plugin/* ~/.aish/plugins/my-plugin/

# Restart aish to load it
:restart
```

### From a GitHub repository

```bash
# Clone directly
git clone https://github.com/user/aish-plugin-example ~/.aish/plugins/example
:restart
```

## Listing and managing plugins

```bash
# List all installed plugins
:plugin list

# Show details about a plugin
:plugin info custom-ops

# Disable a plugin (rename the directory)
mv ~/.aish/plugins/custom-ops ~/.aish/plugins/custom-ops.disabled
:restart

# Remove a plugin
rm -rf ~/.aish/plugins/custom-ops
:restart
```

## Best practices

✅ **Do:**
- Use clear, unique plugin IDs (no spaces, use kebab-case)
- Version your plugin following semver
- Include a README explaining what the plugin does
- Test lifecycle hooks before deploying
- Document any environment variables or configuration required
- Use `:skill` conventions for naming and documentation

❌ **Don't:**
- Create plugins that conflict with core aish functionality
- Use PreToolUse hooks to block legitimate workflows without clear messaging
- Assume a specific aish version without declaring `aish_version` in plugin.json
- Store sensitive data (keys, tokens) inside the plugin directory
- Create plugins that require external services without clear error handling

## Example: minimal plugin

**~/.aish/plugins/hello-world/plugin.json**:
```json
{
  "id": "hello-world",
  "name": "Hello World",
  "version": "1.0.0",
  "description": "Example plugin with a simple skill",
  "author": "Your Name",
  "license": "MIT"
}
```

**~/.aish/plugins/hello-world/skills/greet/SKILL.md**:
```markdown
---
name: hello-world
description: "Greet the user"
---

# Hello World

A simple skill that greets the user.

When to use: whenever you want a friendly greeting.

Steps:
1. Echo a greeting message
2. Done!
```

**~/.aish/plugins/hello-world/README.md**:
```markdown
# Hello World Plugin

A minimal example plugin for aish.

## Install

```bash
git clone https://github.com/user/aish-plugin-hello-world ~/.aish/plugins/hello-world
:restart
```

## Usage

Use `:skill list` to see the `hello-world` skill.
```

---

*See also: [Architecture](./architecture.md) · [Commands](./commands.md) · [Configuration](./configuration.md)*
