# What's New

> Distilled from the aish CLI [`CHANGELOG.md`](https://github.com/LightHeart-Ventures/aish/blob/main/CHANGELOG.md).
> Canonical shipping version: **0.29.3** (`Cargo.toml`). Regenerate with the
> `aish/docs-generator` skill.

> ⚠️ The upstream `CHANGELOG.md` is currently annotated through **0.21.1** while
> `Cargo.toml` reports **0.29.3** — the changelog lags the version. Entries below
> reflect what the changelog documents; newer point releases (0.22–0.29) exist as
> tags but aren't yet written up.

## Unreleased

**Fixed**
- **Container worker image self-builds the aish binary** — `Dockerfile.worker`
  is now a multi-stage build that compiles `aish` *inside* a `rust:1-bookworm`
  stage and copies it into a matching `debian:bookworm-slim` runtime, killing the
  `GLIBC_2.39 not found` class of opaque container-worker failures. Adds a
  `.dockerignore` and a pre-launch `--version` probe that degrades to the host
  subprocess with a real diagnostic instead of launching a doomed container.
- **Shift-Tab with no coordinators is a silent no-op** — no more screen
  clear/redraw when there's nothing to cycle to.

**Changed**
- **Dev release reuses same-commit CI/CD builds** instead of recompiling —
  `release-dev.yml` re-publishes byte-identical binaries when a matching
  `ci-<run>-<sha>` release exists, saving ~4–6 min of runner time per unchanged commit.
- **Collapsed tool-output activity stream + symmetric Ctrl-O toggle** — the
  activity stream shows a `… N lines — Ctrl-O to expand` summary; Ctrl-O toggles
  the full last-turn output in and out.

**Added**
- **`:goal` long-horizon goals** — durable, cross-session goal → milestones →
  tasks + blockers hierarchy in `~/.aish/aish.db`, injected into every turn.
- **Audible finish-bell** when a background worker/batch/coordinator completes
  (`AISH_WORKER_BELL=0` to mute, `AISH_WORKER_BELL_CMD` for a custom sound).
- **Plugin system — skill-registry expansion** — aish discovers plugins under
  `~/.aish/plugins/<id>/` and merges each enabled plugin's skills into the catalog.

## 0.21.1

- Interactive system-prompt refresh to the current LightHeart persona.
- **NEVER FABRICATE, ALWAYS VERIFY** guardrail added to system + worker prompts:
  agents must confirm claims with real tool output, not assert unverified results.

## 0.21.0

- **Lifecycle hooks — `PreToolUse` blocking gate**: hooks can *block* a tool call
  before it runs, not just observe it.
- **`:stop` coordinator stand-down channel** — harder than `:tell`.
- Parent session **wakes when fanned-out coordinators complete**.
- `read_file` gains **1-based line-range slicing**.
- **Ctrl-C interrupts an attached worker's current turn** without killing the run.
- **Local backend auto-downloads** the detected GGUF from Hugging Face on first use.

## 0.20.0

- **Release binaries now ship with the local backend built in** (`--features
  local`) — the published `aish` includes the llama.cpp / GGUF backend out of the
  box, no from-source rebuild to run offline.

## 0.19.3

- **Hardware-aware local model selection** — the local backend inspects the host
  and picks an appropriate GGUF model/parameters for the detected hardware.
- Final, clean release of the llama.cpp local-backend line (recovering the burned
  v0.19.0 tag onto `main`).

---

*See also: [Command Reference](./commands.md) · [Configuration](./configuration.md)*
