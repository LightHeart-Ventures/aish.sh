# Getting Started with aish

aish is an AI-native shell — no bash, just intent. Current release: **0.29.3**.

## Prerequisites

- An **`ANTHROPIC_API_KEY`** for the default Claude backend — free at
  <https://console.anthropic.com>. (Or run fully offline with `--backend local`.)
- A **Rust toolchain** (`rustup`) if building from source.

## Installation

```bash
git clone https://github.com/LightHeart-Ventures/aish
cd aish
make install        # builds --release and installs the binary onto your PATH
```

<details>
<summary>From source without <code>make</code></summary>

```bash
cargo build --release   # binary at ./target/release/aish
```
</details>

Then point aish at your key (add to your shell profile to persist):

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

## Your First Command

```bash
aish
```

This opens the interactive REPL. Type a natural-language intent:

```
> list the top 10 files by size in /home
```

aish classifies the line, invokes tools as needed, and streams the results.
Routine commands (`git status`, `ls`, anything on your `PATH`) run **directly** —
no model, no latency. Only genuine intent engages the agent. Force the route with
`!line` (direct) or `?line` (model).

## Offline mode

No API key? Run the built-in local backend (first launch downloads a
hardware-appropriate GGUF model, ~4 GB):

```bash
aish --backend local
```

## Key Concepts

- **Intent** — natural language → aish parses and executes.
- **Routing** — `:command` / direct-exec / agent / `!`·`?` escape hatches.
- **Tools & MCP** — file ops, git, and remote capabilities exposed via MCP servers.
- **Coordinators** — background agents (`:dispatch`) that run deferrable work with
  the full toolset and survive restarts.
- **Skills** — expert playbooks on disk (`:skill`) the agent reads and follows.
- **Goals & Memory** — durable, cross-session objectives and facts in `~/.aish`.

## Learn More

- [Command Reference](./commands.md)
- [Configuration](./configuration.md)
- [Architecture](./architecture.md)
- [What's New](./whats-new.md)

---

Questions? [Open an issue](https://github.com/LightHeart-Ventures/aish/issues).
