# docs-generator

Tooling that generates and maintains this site's documentation from **source of truth**
in both aish repos, instead of hand-written prose that drifts.

- **`SKILL.md`** — the aish skill playbook (also installed at `~/.aish/skills/aish/docs-generator/`).
  Read it first; it drives the whole generate → reconcile → PR flow.
- **`scripts/harvest.py`** — pure `python3` stdlib fact harvester. Extracts the canonical
  version, REPL commands, `AISH_*` env vars, docs inventory, changelog, and **version drift**
  from both the aish CLI repo and this site repo.

## Quick start

```
python3 tools/docs-generator/scripts/harvest.py \
    --cli  ~/projects/aish \
    --site . \
    --json
```

Or drop `--json` for a readable summary. Override repo paths with `AISH_CLI_REPO` /
`AISH_SITE_REPO`. The `canonical_version` comes from the CLI `Cargo.toml` — the single
source of truth. `version_drift` lists site lines claiming to be "current" that contradict it.

See `SKILL.md` for the full generate-and-reconcile workflow.
