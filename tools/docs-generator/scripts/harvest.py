#!/usr/bin/env python3
"""
aish/docs-generator — fact harvester.

Extracts ground-truth documentation facts from BOTH aish repos so the docs
site is generated from source-of-truth data instead of hallucinated prose:

  * aish CLI repo   (technical: version, REPL commands, env vars, docs, changelog)
  * aish.sh site    (marketing/product: positioning, roadmap, design system)

Pure Python 3 stdlib. aish can exec `python3` directly (it refuses bash), so run
this via:  run_program python3 scripts/harvest.py --cli <path> --site <path> [--json]

Exit code is 0 always; drift is reported in the payload, not via exit status.
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path

VERSION_RE = re.compile(r'v?(\d+\.\d+\.\d+)')
ENVVAR_RE = re.compile(r'AISH_[A-Z0-9]+(?:_[A-Z0-9]+)*')
CARGO_VER_RE = re.compile(r'^\s*version\s*=\s*"([^"]+)"', re.M)
CMD_RE = re.compile(r'`?(:[a-z][a-z0-9-]+)`?')


def read(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def walk_rs(root: Path):
    for base in ("src", "crates"):
        d = root / base
        if not d.is_dir():
            continue
        for p in d.rglob("*.rs"):
            yield p


def cli_version(cli: Path) -> str:
    txt = read(cli / "Cargo.toml")
    # first version = "..." after the [package] table
    m = CARGO_VER_RE.search(txt)
    return m.group(1) if m else "?"


def repospec_version(cli: Path) -> str:
    txt = read(cli / ".repospec.json")
    try:
        return json.loads(txt).get("version", "?")
    except Exception:
        return "?"


def env_vars(cli: Path) -> list:
    found = set()
    for p in walk_rs(cli):
        for m in ENVVAR_RE.findall(read(p)):
            # drop truncated prefix stubs (kept short on purpose in source)
            if m.endswith("_") or len(m) <= 5:
                continue
            found.add(m)
    # drop obvious test-only sentinels
    junk = {"AISH_DEFINITELY_UNSET_XYZ", "AISH_NO_SUCH_VAR_42", "AISH_TEST_MCP"}
    return sorted(found - junk)


def repl_commands(cli: Path) -> list:
    """Pull the : command tokens from the README 'REPL Commands' section."""
    txt = read(cli / "README.md")
    lo = txt.find("REPL Commands")
    if lo == -1:
        return []
    seg = txt[lo: lo + 2000]
    seg = seg.split("\n## ")[0]  # stop at next h2
    cmds = []
    for m in CMD_RE.findall(seg):
        if m not in cmds:
            cmds.append(m)
    return cmds


EXCLUDE_DIRS = {".git", "target", "node_modules", "aish-restore", "aish-restore-bak",
                ".aish", "worktrees", "dist", "build"}


def docs_inventory(root: Path, _subdirs=None) -> list:
    """Every *.md under root, deduped, skipping VCS/build/backup dirs."""
    out = []
    for p in sorted(root.rglob("*.md")):
        rel = p.relative_to(root)
        if EXCLUDE_DIRS & set(rel.parts):
            continue
        out.append({"path": str(rel), "bytes": p.stat().st_size})
    return out


def changelog_top(cli: Path) -> dict:
    txt = read(cli / "CHANGELOG.md")
    # first '## [x]' heading block
    heads = [m.start() for m in re.finditer(r'^## ', txt, re.M)]
    if not heads:
        return {}
    start = heads[0]
    end = heads[1] if len(heads) > 1 else len(txt)
    block = txt[start:end].strip()
    head_line = block.splitlines()[0].lstrip("# ").strip()
    return {"heading": head_line, "excerpt": block[:1200]}


def version_mentions(site: Path) -> list:
    """Every vX.Y.Z string in the site's markdown, with file + context — drift hunt."""
    hits = []
    for p in sorted(site.rglob("*.md")):
        rel = p.relative_to(site)
        if EXCLUDE_DIRS & set(rel.parts):
            continue
        for i, line in enumerate(read(p).splitlines(), 1):
            low = line.lower()
            is_current = ("current version" in low) or ("current release" in low) or ("latest" in low)
            for m in re.finditer(r'v?\d+\.\d+\.\d+', line):
                hits.append({
                    "file": str(p.relative_to(site)),
                    "line": i,
                    "match": m.group(0),
                    "ver": VERSION_RE.search(m.group(0)).group(1),
                    "current_claim": is_current,
                    "text": line.strip()[:100],
                })
    return hits


def main():
    ap = argparse.ArgumentParser(description="Harvest aish docs facts from both repos.")
    ap.add_argument("--cli", default=os.environ.get("AISH_CLI_REPO", str(Path.home() / "projects/aish")),
                    help="Path to the aish CLI repo (default ~/projects/aish or $AISH_CLI_REPO).")
    ap.add_argument("--site", default=os.environ.get("AISH_SITE_REPO", os.getcwd()),
                    help="Path to the aish.sh site repo (default cwd or $AISH_SITE_REPO).")
    ap.add_argument("--json", action="store_true", help="Emit machine-readable JSON.")
    args = ap.parse_args()

    cli = Path(args.cli).expanduser().resolve()
    site = Path(args.site).expanduser().resolve()

    errs = []
    if not (cli / "Cargo.toml").is_file():
        errs.append(f"CLI repo not found or missing Cargo.toml at {cli}")
    if not site.is_dir():
        errs.append(f"Site repo not found at {site}")

    cver = cli_version(cli) if not errs else "?"
    mentions = version_mentions(site) if site.is_dir() else []
    # critical drift = a line CLAIMING to be current/latest whose version != canonical.
    # roadmap mentions (future targets) are informational, not drift.
    drift = [m for m in mentions if m["ver"] != cver and cver != "?" and m["current_claim"]]
    other = [m for m in mentions if m["ver"] != cver and cver != "?" and not m["current_claim"]]

    payload = {
        "cli_repo": str(cli),
        "site_repo": str(site),
        "errors": errs,
        "canonical_version": cver,
        "version_sources": {
            "Cargo.toml": cver,
            ".repospec.json": repospec_version(cli) if not errs else "?",
        },
        "repl_commands": repl_commands(cli) if not errs else [],
        "env_vars": env_vars(cli) if not errs else [],
        "cli_docs": docs_inventory(cli, ["docs", ""]) if not errs else [],
        "site_docs": docs_inventory(site, ["docs", "marketing", "product", "design", ""]) if site.is_dir() else [],
        "changelog_top": changelog_top(cli) if not errs else {},
        "version_drift": drift,
        "version_other_mentions": other,
    }

    if args.json:
        print(json.dumps(payload, indent=2))
        return

    # human summary
    def hr(t): print(f"\n=== {t} ===")
    if errs:
        print("ERRORS:")
        for e in errs:
            print("  !", e)
    print(f"canonical version (Cargo.toml): {cver}")
    print(f".repospec.json version         : {payload['version_sources']['.repospec.json']}")
    hr(f"REPL commands ({len(payload['repl_commands'])})")
    print("  " + "  ".join(payload["repl_commands"]))
    hr(f"AISH_* env vars ({len(payload['env_vars'])})")
    for v in payload["env_vars"]:
        print("  " + v)
    hr(f"CLI docs ({len(payload['cli_docs'])})")
    for d in payload["cli_docs"]:
        print(f"  {d['path']} ({d['bytes']}b)")
    hr(f"site docs ({len(payload['site_docs'])})")
    for d in payload["site_docs"]:
        print(f"  {d['path']} ({d['bytes']}b)")
    hr("changelog (top section)")
    print("  " + payload["changelog_top"].get("heading", "(none)"))
    hr(f"CRITICAL VERSION DRIFT ({len(drift)} stale current-version claim(s) vs {cver})")
    if not drift:
        print("  none — no 'current version' line contradicts the CLI canonical version.")
    for m in drift:
        print(f"  {m['file']}:{m['line']}  {m['match']}  ->  should be {cver}   | {m['text']}")
    hr(f"other version mentions ({len(other)} — roadmap/future, review manually)")
    for m in other:
        print(f"  {m['file']}:{m['line']}  {m['match']}   | {m['text']}")


if __name__ == "__main__":
    main()
