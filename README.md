# robotics-cursor-rules

Personal collection of [Cursor](https://cursor.sh) AI rules (`.mdc` files) tailored for ROS 2 robotics development. Symlink them into any project to get consistent, high-quality AI assistance across your workspace.

## Quick Start

```bash
# Clone
git clone git@github.com:robotaitai/robotics-cursor-rules.git ~/cursor-rules

# Install all rules into a project
~/cursor-rules/scripts/install.sh /path/to/your/ros2_ws/src/my_package

# List available rules
~/cursor-rules/scripts/list.sh
```

## Available Rules

| Rule | Description |
|------|-------------|
| `generate-architecture-doc.mdc` | Generate rich HTML architecture docs for any ROS 2 package — state machines, Mermaid diagrams, topic/service tables, data flows |

## How It Works

Rules are **symlinked** into each project's `.cursor/rules/` directory:

```
~/cursor-rules/rules/my-rule.mdc
        ↓ symlink
~/my_project/.cursor/rules/my-rule.mdc
```

- Edit a rule in `~/cursor-rules/` → every project gets the update instantly
- Project-specific (non-symlinked) rules are left untouched
- Works with any number of projects simultaneously

## Scripts

| Script | Usage | Description |
|--------|-------|-------------|
| `install.sh` | `./install.sh /path/to/project [rule.mdc]` | Symlink all or one rule into a project |
| `uninstall.sh` | `./uninstall.sh /path/to/project` | Remove symlinked rules (keeps project-local ones) |
| `list.sh` | `./list.sh` | List all available rules with descriptions |

## Adding a New Rule

Create a `.mdc` file in `rules/`:

```markdown
---
description: Short description shown in Cursor's rule picker
globs:                    # Optional file patterns (e.g. **/*.cpp)
alwaysApply: false        # true = always active, false = on-demand
---

# Rule Title

Your instructions for the AI here...
```

Then run `install.sh` on your projects to pick it up.

## Shell Aliases (Optional)

Add to `~/.bashrc` for convenience:

```bash
alias cri='~/cursor-rules/scripts/install.sh'
alias crl='~/cursor-rules/scripts/list.sh'
alias cru='~/cursor-rules/scripts/uninstall.sh'
```

Then: `cri .` to install rules into the current project.

## Structure

```
robotics-cursor-rules/
├── rules/                              # All .mdc rule files
│   └── generate-architecture-doc.mdc
├── scripts/
│   ├── install.sh                      # Symlink rules into a project
│   ├── uninstall.sh                    # Remove symlinks from a project
│   └── list.sh                         # List available rules
├── .gitignore
└── README.md
```
