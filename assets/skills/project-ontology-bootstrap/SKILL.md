---
name: project-ontology-bootstrap
description: Bootstrap an adaptive project knowledge tree. Use when agent-knowledge/Memory/MEMORY.md is missing, broken, or too generic.
---

# Project Ontology Bootstrap

Creates an adaptive, profile-driven knowledge tree for a project from scratch.
Run this once — then maintain with the writeback rule.

## When to use

- `agent-knowledge/Memory/MEMORY.md` does not exist or is empty
- `Memory/MEMORY.md` exists but is still generic bootstrap content
- User says "initialize memory", "bootstrap memory", or "set up project memory"
- Starting work on an inherited repo with no prior agent memory

---

## Step 0 — Verify the local pointer

The project entrypoint is `./agent-knowledge`.

- `./agent-knowledge` must be a symlink or junction to the real dedicated knowledge folder
- The external folder is the source of truth
- Manual and scripted bootstrap still write through `./agent-knowledge` as the local handle

If the pointer does not exist yet, create it first with:

```bash
scripts/install-project-links.sh --slug <project-slug> --repo /path/to/project
```

---

## Step 1 — Inspect the repo before choosing a profile

Inspect:
- manifests and lockfiles
- directory structure
- docs (`README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`)
- config files
- test directories
- workflow files
- any structural evidence already present under `Evidence/imports/` or `Outputs/`

Infer the profile from the strongest verified signals:

| Signal | Profile |
|--------|---------|
| `package.xml`, `CMakeLists.txt`, `launch/`, `urdf/`, ROS/Gazebo/MoveIt docs | robotics |
| `pyproject.toml` or `requirements.txt` + `models/`, `notebooks/`, `data/`, ML framework deps | ml-platform |
| workspace files, `packages/`, `services/`, `apps/`, multiple manifests | hybrid |
| `package.json` + React/Next/Vue/Svelte/Angular/Vite without strong workspace signals | web-app |
| No strong signal | hybrid |

**If uncertain**: ask the user once — "Is this a web-app, robotics, ml-platform, or hybrid project?"

---

## Step 2 — Read the profile

Read `templates/memory/profile.<type>.yaml` from the agents-rules repo.

It contains:
- `areas`: initial durable memory branches
- `area_hints`: what each branch should cover
- bootstrap/backfill focus hints

---

## Step 3 — Run the bootstrap script

```bash
scripts/bootstrap-memory-tree.sh /path/to/project [profile]
```

This creates:
```text
agent-knowledge/
  INDEX.md
  Memory/
    MEMORY.md           ← root durable memory note
    <area>.md           ← one stub per profile area
    decisions/
      INDEX.md
  Evidence/
    raw/
    imports/
  Sessions/
  Outputs/
  Dashboards/
  Templates/
  .obsidian/
```

The real files live in the external knowledge folder. Inside the repo, agents still operate through `./agent-knowledge`.

If the script is unavailable, create the files manually using the templates in `templates/memory/`.

---

## Step 4 — Seed the tree from immediately available facts

The bootstrap pass should seed the tree from verified signals only:

- **Stack**: read `package.json`, `pyproject.toml`, `Cargo.toml`, or equivalent
- **Architecture**: inspect top-level directories, tests, workflows, and major docs
- **Conventions**: look for config files and style/tooling signals
- **Gotchas**: only record verified warnings or operational constraints
- **Profile-specific branches**: seed from the strongest matching directories and docs
- **Structural evidence outputs**: use `Outputs/architecture-summary.md` or `Outputs/structural-map.md` only as orientation, not canonical truth

For each fact you write:
- Use **Current State** section for what is true now
- Keep it concise and verified
- Do not invent facts — write only what you can verify from the repo
- If the best source is machine-generated structure, treat it as evidence and verify against the repo before promoting it into memory

---

## Step 5 — Set up Cursor symlink (if needed)

```bash
# Find the Cursor project ID for this workspace
CURSOR_PROJECT=$(ls ~/.cursor/projects/ | while read d; do
    [ -f "$HOME/.cursor/projects/$d/.project" ] && \
      grep -q "$(basename $(pwd))" "$HOME/.cursor/projects/$d/.project" 2>/dev/null && echo "$d"
done | head -1)

if [ -n "$CURSOR_PROJECT" ]; then
    ln -sf "$(pwd)/agent-knowledge/Memory" "$HOME/.cursor/projects/$CURSOR_PROJECT/memory"
    echo "Symlinked to ~/.cursor/projects/$CURSOR_PROJECT/memory"
fi
```

---

## Step 6 — Trigger history backfill

Bootstrap creates structure only. To fill it with real project history:

```bash
scripts/import-agent-history.sh /path/to/project
```

Optional structural graph imports can be added with:

```bash
scripts/graphify-sync.sh /path/to/project
```

Then follow the `history-backfill` skill to distill evidence into memory.

---

## Output checklist

After bootstrap, verify:
- [ ] `agent-knowledge/INDEX.md` exists
- [ ] `agent-knowledge/Memory/MEMORY.md` exists and uses YAML frontmatter
- [ ] Each area file has a **Purpose** and at least one entry in **Current State**
- [ ] `decisions/INDEX.md` exists (may be empty)
- [ ] `agent-knowledge/Evidence/raw/` and `agent-knowledge/Evidence/imports/` exist
- [ ] `agent-knowledge/Sessions/` exists
- [ ] `Memory/MEMORY.md` is still short enough to scan quickly
