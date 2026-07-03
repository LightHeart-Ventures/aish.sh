# Command Reference

> Generated from aish CLI source (`src/repl.rs` · `COLON_COMMANDS`) at version **0.29.3**.
> Regenerate with the `aish/docs-generator` skill when the CLI changes.

aish routes every line you type one of four ways. Understanding routing is the
key to the shell — most lines never touch the model.

## How a line is routed

1. **`:command`** — a REPL meta-command (see the table below). Handled by the shell itself.
2. **Direct execution** — if the first word is an alias, `cd`/`exit`, or an
   executable on your `PATH`, the line **runs directly** on your terminal. No
   model, no latency, no permission prompt.
3. **The model** — anything else (including shell machinery like `|`, `>`, `$`,
   globs, and English that merely starts with a command word — `who is grace
   hopper`) goes to the **agent**, which works through tools until the intent is done.
4. **Escape hatches** — `!line` forces direct execution; `?line` forces the model.

`Ctrl-C` aborts the current turn; during a TTY hand-off (interactive programs
like `vim`, `ssh`) it interrupts the foreground child, exactly like a shell.
`→` / `Ctrl-F` accept the inline history ghost-text suggestion.

## REPL meta-commands (`:command`)

The full catalog, straight from the source dispatch table. Type a bare `:` in
the REPL to get the live-filtered palette of these.

| Command | What it does |
|---|---|
| `:allow` | List / revoke always-allowed tools & dir grants |
| `:attach` | Watch + steer a coordinator, or `goal` to watch the goal |
| `:backend` | Switch backend (`claude` \| `grok` \| `local`) |
| `:batch` | Background batch mode (`on` \| `off` \| `status`) |
| `:close` | Remove the attached (or named) coordinator from the worker list + Shift-Tab rotation |
| `:compact` | Compact history, offload to memory |
| `:context` | Show context-window usage |
| `:detach` | Stop watching the attached coordinator |
| `:dispatch` | Launch a background coordinator |
| `:dispatch-stats` | Background-job dispatch efficiency report (`all` = every session) |
| `:forget` | Remove an exited worker (`--all-exited`: every exited one) |
| `:goal` | Pursue a goal in the background (see [Goals](#goals)) |
| `:help` | Show command help |
| `:hooks` | List lifecycle hooks + provenance (`list` \| `reload`) |
| `:jobs` | List background jobs |
| `:kill` | Kill a background job |
| `:loop` | Re-run a prompt N times inline (`status` \| `stop`) |
| `:mcp` | Manage MCP servers |
| `:memories` | Stored memories / organize |
| `:mode` | Set confirmation level (`paranoid` \| `careful` \| `normal` \| `yolo`) |
| `:model` | Switch model (`opus` \| `sonnet` \| `haiku` \| id) |
| `:model-detect` | Pick the best local model for this machine |
| `:new` | Clear conversation history |
| `:output` | Stream coordinators' activity |
| `:plugin` | Plugin provenance (`list` \| `info <id>`) |
| `:quit` | Exit aish (also `Ctrl-D` / `exit`) |
| `:reasoning` | Show reasoning-quality telemetry (escalate vs guess) |
| `:rename` | Rename this session |
| `:restart` | Reload aish with the same command it started with |
| `:result` | View a finished job's result |
| `:rewrite` | AI-rewrite intent into a command (edit/accept before run) |
| `:schedule` | Run a task later/recurring (cron or `in 5 min …`); no args = list |
| `:skill` | Manage skills (`add` \| `search` \| `list` \| `remove`) |
| `:stop` | Stand down an in-flight coordinator — harsher than `:tell` (`--any`: cross-session) |
| `:suggest` | AI-suggest the next command from context (edit/accept before run) |
| `:tell` | Message an in-flight coordinator (`--any`: cross-session) |
| `:update` | Upgrade aish to the latest release |
| `:version` | Show aish version + backend |
| `:workers` | List this session's coordinators (`all` = every session) |
| `:yolo` | Toggle yolo mode |

## Goals

A **goal** is a durable, multi-session objective that outlives any single turn —
a persistent tree of **goal → milestones → tasks** plus the **blockers** standing
in the way. Goals live in `~/.aish/aish.db`, so they survive `:new`, restarts,
and `:update`. While a goal is active, its state is injected into every turn's
context so the agent keeps steering toward it.

| Subcommand | What it does |
|---|---|
| `:goal new <text>` | Create a new goal and make it the active one |
| `:goal show` | Show the active goal's full tree — milestones, tasks, blockers |
| `:goal status` | One-glance dashboard: progress rollup, phase, and elapsed time |
| `:goal link <task>` | Attach a task/coordinator run to the active goal |
| `:goal milestone <text>` | Add a milestone under the active goal |
| `:goal block <text>` | Record a blocker that's holding the goal up |
| `:goal unblock <id>` | Clear a resolved blocker |
| `:goal complete` | Mark the active goal done |

Only one goal is active at a time; `:goal new` supersedes the previous one (past
goals stay on record). Shift-Tab cycles straight into the active goal's loop.

## Scripting

`aish <file>` runs a script non-interactively, then exits with the status of its
last line:

```sh
aish deploy.aish        # run the file's lines, then exit
```

Each line is handled as if typed at the prompt. Blank lines and `#` comments are
skipped, and the `!`/`?` route prefixes work. Because the leading `#!` line is a
comment, a script can carry a shebang and run as a program directly:

```aish
#!/usr/bin/env aish
# back up the project, then summarize what changed
tar czf /backups/proj.tgz .
summarize what just got archived and flag anything unexpected
```

---

*See also: [Configuration](./configuration.md) · [Architecture](./architecture.md) · [What's New](./whats-new.md)*
