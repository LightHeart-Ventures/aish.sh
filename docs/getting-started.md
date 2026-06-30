# Getting Started with aish

aish is an AI-native shell — no bash, just intent.

## Installation

```bash
# From source (requires Rust 1.70+)
git clone https://github.com/LightHeart-Ventures/aish
cd aish
cargo build --release

# The binary is at ./target/release/aish
```

## Your First Command

```bash
aish
```

This opens the interactive REPL. Type a natural-language intent:

```
> list the top 10 files by size in /home
```

aish parses your intent, invokes tools (via MCP), and streams the results.

## Key Concepts

- **Intent**: Natural language → aish parses and executes
- **MCP Tools**: Remote procedures (file ops, git, APIs) exposed via MCP servers
- **Agents**: Specialized workers (Sprint Manager, Code Reviewer, etc.)
- **Sessions**: Stateful shell with env vars, aliases, and job management

## Learn More

- [Architecture](../docs/architecture.md)
- [API Reference](../docs/api-reference/)
- [Tutorials](../docs/tutorials/)

---

Questions? [Open an issue](https://github.com/LightHeart-Ventures/aish/issues).
