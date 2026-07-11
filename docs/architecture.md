# Architecture

> Grounded in the aish CLI source (`LightHeart-Ventures/aish`) at version
> **0.29.3**. Regenerate with the `aish/docs-generator` skill.

aish is a single Rust binary that replaces your interactive shell. It is not a
wrapper around bash — there is no POSIX layer underneath. The shell reasons about
each line, forks/execs real binaries when appropriate, calls tools when it needs
to, and iterates until the intent is done.

## The routing core

Every line you type is classified before anything runs (`src/repl.rs`):

```
line ──▶ :command?      ──▶ handled by the REPL itself
     ──▶ alias/cd/exit? ──▶ run directly on the terminal
     ──▶ on PATH?       ──▶ run directly on the terminal  (no model, no latency)
     ──▶ otherwise      ──▶ the agent works it through tools
```

Two escape hatches override the classifier: `!line` forces direct execution,
`?line` forces the model. This is what keeps aish fast — routine commands never
pay for an LLM round-trip, and only genuine intent engages the agent.

## Backends

The agent runs against a pluggable backend, switchable live with `:backend` or at
launch with `--backend`:

- **`claude`** (default) — Anthropic Claude via `ANTHROPIC_API_KEY`.
- **`grok`** — xAI Grok.
- **`local`** — offline llama.cpp / GGUF inference, shipped built-in since 0.20.0.
  Hardware-aware model selection picks an appropriate GGUF for the host and
  downloads it from Hugging Face on first use.

## Tools & MCP

The agent acts through **tools** — file ops, process exec, git, search, and any
capability exposed by a connected **MCP** (Model Context Protocol) server.
`:mcp` manages servers; MCP tools honor their `readOnlyHint`, so the confirmation
gate (`:mode`) only prompts for genuinely mutating calls. This is the same tool
surface a background coordinator inherits.

## Coordinators & fan-out

Deferrable or parallelizable work is offloaded to a **background coordinator** — a
headless aish running in the same directory with the *complete* toolset. It runs
asynchronously, survives restarts, and can itself fan heavy sub-work out to the
Anthropic Batches API.

- `:dispatch` launches one; `:workers` / `:jobs` list them; `:output` streams
  their activity.
- `:tell` steers a running coordinator mid-flight; `:stop` stands one down.
- Isolated (writing) coordinators run in their own **git worktree** on a fresh
  branch, so parallel jobs never clobber each other's working tree — changes land
  on a branch for review, never auto-merged.
- Shift-Tab cycles between this session's coordinators.

## Skills & plugins

**Skills** are expert playbooks on disk (`~/.aish/skills/<name>/SKILL.md`). Using
one means reading its `SKILL.md` and carrying out its steps with normal tools —
there is no separate runtime. `:skill` adds/searches/lists/removes them.

**Plugins** (`~/.aish/plugins/<id>/`) extend aish without modifying the binary.
Each plugin declares a `plugin.json` that contributes:
- **Skills** — additional expert playbooks merged into the catalog
- **Lifecycle hooks** — observers/gates that run before/after tool calls
- **MCP servers** — additional Model Context Protocol integrations

Installed skills take precedence over plugin skills on name collision. Plugins are
discovered on startup and can be installed from local directories or GitHub.

*For full plugin documentation, architecture, and examples, see [Plugin System](./plugins.md).*

## Durable state & memory

State lives under `~/.aish/` (notably `aish.db`):

- **Memory** — durable facts (preferences, project facts, lessons) that persist
  across sessions and inform future turns.
- **Goals** — the cross-session goal → milestones → tasks + blockers hierarchy,
  injected into every turn while active (`:goal`).
- **Sessions** — env vars, aliases, and background jobs, with `:rename` /
  `:restart` lifecycle.

## Safety & lifecycle hooks

`:mode` sets a graded confirmation gate: `paranoid` (confirm everything),
`careful` (confirm writes), `normal` (default — confirm mutating ops), `yolo`
(confirm nothing). **Lifecycle hooks** can observe or, since 0.21.0, *block* a
tool call before it runs (`PreToolUse`), giving policy a real veto point.

---

*See also: [Command Reference](./commands.md) · [Configuration](./configuration.md) · [What's New](./whats-new.md)*
