"""Subprocess wrappers for calling bundled scripts."""

from __future__ import annotations

import subprocess
import sys

from .paths import get_script


def run_bash_script(name: str, args: list[str]) -> int:
    """Run a bundled bash script and return its exit code."""
    script = get_script(name)
    result = subprocess.run(["bash", str(script)] + args)
    return result.returncode


def run_python_script(name: str, args: list[str]) -> int:
    """Run a bundled Python script and return its exit code."""
    script = get_script(name)
    result = subprocess.run([sys.executable, str(script)] + args)
    return result.returncode
