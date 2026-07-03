---
name: aish/docs-generator
description: >
  Generate and maintain the aish.sh documentation site from BOTH source repos —
  the aish CLI repo (technical: version, REPL commands, env vars, docs, changelog)
  and the aish.sh site repo (marketing/product: positioning, roadmap, design system).
  Use when creating or refreshing docs pages for aish.sh, reconciling version/command
  drift between the site and the CLI, or standing up a new docs section. Grounds every
  generated page in harvested source-of-truth facts instead of hallucinated prose, then
  opens a review PR (never auto-merges).
allowed-tools: [read_file, write_file, edit_file, run_program, glob_expand, grep_files, list_dir]
---

# aish/docs-generator

Build the aish.sh docs site from **ground truth in two repos**, not from memory.
The #1 failure mode of hand-written docs here is **drift**: the site claims
`v0.18.5` while `Cargo.toml` says `0.29.3`, lists 8 REPL commands when there are
dozens, and omits env vars. This skill harvests the real facts first, then writes.

## The two repos (know what lives where)

| Repo | Default path | Override env | Provides |
|------|--------------|--------------|----------|
| **aish CLI** | `~/projects/aish` | `AISH_CLI_REPO` | version (Cargo.toml = source of truth), REPL commands, `AISH_*` env vars, `docs/*.md`, `CHANGELOG.md`, `README.md` — the **technical** reference |
| **aish.sh site** | current worktree / repo root | `AISH_SITE_REPO` | positioning, roadmap, enterprise product docs, design system/brand, the docs pages you generate — the **marketing/product** layer |

Rule: **technical facts come from the CLI repo; voice, positioning, and page
structure come from the site repo.** Never invent a command, env var, or version —
if the harvester didn't find it, grep the CLI source before writing it down.

## Step 1 — Harvest facts (always first)

Run the bundled harvester. It is pure `python3` stdlib (aish can exec `python3`
directly; it refuses `bash`, so there is intentionally no `.sh` wrapper):

```
run_program python3 <skill_dir>/scripts/harvest.py \
    --cli  ~/projects/aish \
    --site <site-repo-root> \
    --json
```

Drop `--json` for a human-readable summary. The payload gives you:

- `canonical_version` — from `Cargo.toml`, the **single source of truth** for the version.
- `version_sources` — every place a version is declared (Cargo.toml, `.repospec.json`); these routinely disagree.
- `version_drift` — lines on the site that **claim to be current/latest** but contradict `canonical_version`. **Fix these.**
- `version_other_mentions` — roadmap/future version strings; review manually (a `v1.0.0` roadmap target is expected, not drift).
- `repl_commands` — the `:command` set documented in the CLI README. This is the **documented** subset; for the *full* dispatch table grep the source (Step 2).
- `env_vars` — every `AISH_*` variable referenced in `src/` + `crates/`, deduped & sorted.
- `cli_docs` / `site_docs` — markdown inventory of each repo (path + size) so you know what raw material exists.
- `changelog_top` — the top CHANGELOG section, for a "What's new" page.

## Step 2 — Fill the gaps from source

The harvester is deliberately conservative. Before writing a reference page, deepen it:

- **REPL commands (full list):** `grep_files` `src/repl.rs` (and any command dispatch module)
  for the match arms / help table — the README lists only the headline commands.
  Cross-check each against `--help` output if you can run the binary.
- **Env vars (meaning):** for each `AISH_*` var, `grep_files` its name in the CLI repo to
  learn its default and effect before documenting it. Skip the `AISH_PROFILE_<EXAMPLE>_*`
  entries — those are illustrative profile keys from tests/docs, not real global vars.
- **Feature narrative:** pull from the site's `product/` and `marketing/` docs for the
  "why", and from CLI `docs/*.md` for the "how".

## Step 3 — Generate / update pages

Target a conventional docs taxonomy under the site repo (adapt to what already exists —
check `site_docs` first, don't duplicate):

| Page | Sourced from |
|------|--------------|
| `docs/getting-started.md` | site getting-started + CLI README quickstart |
| `docs/commands.md` | `repl_commands` + `src/repl.rs` dispatch (full reference table) |
| `docs/configuration.md` | `env_vars` (grouped: coordinator, worker, telemetry, profile, update, local-model…) |
| `docs/whats-new.md` | `changelog_top` + recent CHANGELOG sections |
| `docs/architecture.md` | CLI `.repospec.json` modules + `docs/` design notes |
| `index` / overview | site `marketing/positioning.md` + `product/roadmap.md` |

Write with `write_file`; for surgical updates to an existing page use `edit_file`.
Stamp generated reference pages with the `canonical_version` and a note that they
were generated from source so future runs can detect staleness.

## Step 4 — Reconcile drift (the payoff)

For every entry in `version_drift`, update the site file to `canonical_version`.
For `version_other_mentions`, judge each: fix stale "current version" prose, leave
genuine roadmap targets. Also reconcile:

- REPL command list on the site vs the real dispatch table.
- Env-var reference vs the harvested `env_vars` set (add missing, drop removed).
- `.repospec.json` version vs `Cargo.toml` if you're also touching the CLI repo
  (flag it — don't silently edit the CLI repo unless that's the task).

## Step 5 — Ship as a review PR (never auto-merge)

Feature branch only. Commit the generated/updated pages, push, open a PR with a body
that summarizes: pages added/changed, version reconciled (old → `canonical_version`),
and any drift left for a human to judge. **Do not merge to main/master.** If you find
local commits already on main, STOP and report it.

## Guardrails

- **Source of truth = `Cargo.toml`.** When versions disagree, Cargo.toml wins.
- **No invented facts.** A command/env var/flag goes in the docs only if it exists in
  the CLI source. When unsure, grep before you write.
- **Idempotent.** Re-running should converge, not duplicate. Check `site_docs` before
  creating a page; prefer `edit_file` over rewriting.
- **Two-repo hygiene.** Read from both, but only *write* to the site repo unless the
  task explicitly includes fixing the CLI repo (e.g. the `.repospec.json` version drift).
- **Escalate hard reconciliations.** If drift implies a released-version mistake
  (tag ↔ Cargo.toml mismatch), consult the `aish_sre` skill rather than guessing.
