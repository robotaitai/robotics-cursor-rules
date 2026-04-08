"""Auto-detect and install tool integrations (Cursor, Claude, Codex)."""

from __future__ import annotations

import shutil
from pathlib import Path

from .paths import get_assets_dir

TOOLS = ("cursor", "claude", "codex")


def detect(repo: Path) -> dict[str, bool]:
    """Return which tools are detected in the repo."""
    return {
        "cursor": (repo / ".cursor").is_dir(),
        "claude": (repo / ".claude").is_dir() or (repo / "CLAUDE.md").is_file(),
        "codex": (repo / ".codex").is_dir(),
    }


def _copy_template(src: Path, dst: Path, replacements: dict[str, str], *, force: bool = False) -> str:
    """Copy a template file with placeholder substitutions. Returns action taken."""
    if dst.exists() and not force:
        return "exists"
    dst.parent.mkdir(parents=True, exist_ok=True)
    content = src.read_text()
    for placeholder, value in replacements.items():
        content = content.replace(placeholder, value)
    dst.write_text(content)
    return "created" if not dst.exists() else "updated"


def install_cursor(repo: Path, *, dry_run: bool = False, force: bool = False) -> list[str]:
    """Install Cursor hooks.json integration."""
    assets = get_assets_dir()
    actions = []
    repo_abs = str(repo.resolve())

    hooks_src = assets / "templates" / "integrations" / "cursor" / "hooks.json"
    hooks_dst = repo / ".cursor" / "hooks.json"

    if hooks_dst.exists() and not force:
        actions.append(f"  exists: {hooks_dst.relative_to(repo)}")
    elif dry_run:
        actions.append(f"  [dry-run] would create: .cursor/hooks.json")
    else:
        hooks_dst.parent.mkdir(parents=True, exist_ok=True)
        content = hooks_src.read_text().replace("<repo-path>", repo_abs)
        hooks_dst.write_text(content)
        actions.append(f"  created: .cursor/hooks.json")

    return actions


def install_claude(repo: Path, *, dry_run: bool = False, force: bool = False) -> list[str]:
    """Install Claude CLAUDE.md integration."""
    assets = get_assets_dir()
    actions = []

    src = assets / "templates" / "integrations" / "claude" / "CLAUDE.md"
    dst = repo / "CLAUDE.md"

    if dst.exists() and not force:
        actions.append(f"  exists: CLAUDE.md")
    elif dry_run:
        actions.append(f"  [dry-run] would create: CLAUDE.md")
    else:
        shutil.copy2(src, dst)
        actions.append(f"  created: CLAUDE.md")

    return actions


def install_codex(repo: Path, *, dry_run: bool = False, force: bool = False) -> list[str]:
    """Install Codex .codex/AGENTS.md integration."""
    assets = get_assets_dir()
    actions = []

    src = assets / "templates" / "integrations" / "codex" / "AGENTS.md"
    dst = repo / ".codex" / "AGENTS.md"

    if dst.exists() and not force:
        actions.append(f"  exists: .codex/AGENTS.md")
    elif dry_run:
        actions.append(f"  [dry-run] would create: .codex/AGENTS.md")
    else:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        actions.append(f"  created: .codex/AGENTS.md")

    return actions


_INSTALLERS = {
    "cursor": install_cursor,
    "claude": install_claude,
    "codex": install_codex,
}


def install_all(
    repo: Path,
    detected: dict[str, bool],
    *,
    dry_run: bool = False,
    force: bool = False,
) -> dict[str, list[str]]:
    """Install bridge files for all detected (or all) integrations.

    Always installs Cursor hooks since it's the most common agent tool.
    For Claude and Codex, installs only if detected or creates minimal bridge.
    """
    results: dict[str, list[str]] = {}

    # Always install Cursor hooks -- it's the primary integration
    results["cursor"] = _INSTALLERS["cursor"](repo, dry_run=dry_run, force=force)

    # Install Claude/Codex bridges for any detected tool
    for tool in ("claude", "codex"):
        if detected.get(tool, False):
            results[tool] = _INSTALLERS[tool](repo, dry_run=dry_run, force=force)

    return results
