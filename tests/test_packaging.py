"""Verify packaging: imports, assets, entry points."""

from __future__ import annotations

from pathlib import Path


def test_package_importable():
    import agent_knowledge

    assert hasattr(agent_knowledge, "__version__")
    assert isinstance(agent_knowledge.__version__, str)


def test_assets_dir_resolves():
    from agent_knowledge.runtime.paths import get_assets_dir

    assets = get_assets_dir()
    assert assets.is_dir()


def test_bundled_scripts_exist():
    from agent_knowledge.runtime.paths import get_assets_dir

    assets = get_assets_dir()
    for name in [
        "install-project-links.sh",
        "bootstrap-memory-tree.sh",
        "import-agent-history.sh",
        "update-knowledge.sh",
        "doctor.sh",
        "validate-knowledge.sh",
        "ship.sh",
        "global-knowledge-sync.sh",
        "graphify-sync.sh",
        "compact-memory.sh",
        "measure-token-savings.py",
    ]:
        assert (assets / "scripts" / name).is_file(), f"Missing script: {name}"


def test_bundled_common_lib_exists():
    from agent_knowledge.runtime.paths import get_assets_dir

    assets = get_assets_dir()
    assert (assets / "scripts" / "lib" / "knowledge-common.sh").is_file()


def test_bundled_templates_exist():
    from agent_knowledge.runtime.paths import get_assets_dir

    assets = get_assets_dir()
    assert (assets / "templates" / "project" / ".agent-project.yaml").is_file()
    assert (assets / "templates" / "memory" / "area.template.md").is_file()
    assert (assets / "templates" / "memory" / "MEMORY.root.template.md").is_file()


def test_bundled_rules_exist():
    from agent_knowledge.runtime.paths import get_assets_dir

    assets = get_assets_dir()
    assert (assets / "rules" / "memory-bootstrap.mdc").is_file()
    assert (assets / "rules" / "memory-writeback.mdc").is_file()


def test_bundled_commands_exist():
    from agent_knowledge.runtime.paths import get_assets_dir

    assets = get_assets_dir()
    assert (assets / "commands" / "knowledge-sync.md").is_file()
    assert (assets / "commands" / "doctor.md").is_file()


def test_get_script_resolves():
    from agent_knowledge.runtime.paths import get_script

    path = get_script("doctor.sh")
    assert path.is_file()
    assert path.name == "doctor.sh"


def test_get_script_missing_raises():
    import pytest
    from agent_knowledge.runtime.paths import get_script

    with pytest.raises(FileNotFoundError):
        get_script("nonexistent-script.sh")
