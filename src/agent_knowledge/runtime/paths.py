"""Asset and path resolution for the agent-knowledge package."""

from __future__ import annotations

from pathlib import Path

_cached_assets_dir: Path | None = None


def get_assets_dir() -> Path:
    """Return the root of the bundled assets directory.

    When installed via pip, assets live under agent_knowledge/assets/.
    When running from a repo checkout (editable install), falls back to the
    repository root where scripts/, templates/, etc. live directly.
    """
    global _cached_assets_dir
    if _cached_assets_dir is not None:
        return _cached_assets_dir

    marker = Path("scripts", "lib", "knowledge-common.sh")

    # Installed package: assets/ is a sibling of runtime/
    package_assets = Path(__file__).resolve().parent.parent / "assets"
    if (package_assets / marker).is_file():
        _cached_assets_dir = package_assets
        return _cached_assets_dir

    # Dev fallback: repo_root/assets/ (src/agent_knowledge/runtime -> 4 levels up)
    repo_assets = Path(__file__).resolve().parent.parent.parent.parent / "assets"
    if (repo_assets / marker).is_file():
        _cached_assets_dir = repo_assets
        return _cached_assets_dir

    raise FileNotFoundError(
        "Cannot locate agent-knowledge assets. "
        "Ensure the package is installed correctly or you are running from the repo checkout."
    )


def get_script(name: str) -> Path:
    """Return the path to a bundled script (shell or Python)."""
    path = get_assets_dir() / "scripts" / name
    if not path.is_file():
        raise FileNotFoundError(f"Script not found: {path}")
    return path
