---
name: project-ontology-bootstrap
description: Bootstrap a project-specific memory tree. Use when agent-docs/memory/MEMORY.md is missing, obviously generic, or when the user asks to initialize project memory.
---

# Project Ontology Bootstrap

Creates a typed, populated memory tree for a project from scratch.
Run this once — then maintain with the writeback rule.

## When to use

- `agent-docs/memory/MEMORY.md` does not exist or is empty
- MEMORY.md exists but contains only template placeholders (no real facts)
- User says "initialize memory", "bootstrap memory", or "set up project memory"
- Starting work on an inherited repo with no prior agent memory

---

## Step 1 — Detect project type

Check the following signals in order. Stop at the first match.

| Signal | Profile |
|--------|---------|
| `package.json` + React/Next/Vue/Svelte/Angular in deps | web-app |
| `package.xml` anywhere in tree, or `CMakeLists.txt` with ROS/catkin/ament | robotics |
| Python project (`pyproject.toml` or `requirements.txt`) + `notebooks/`, `models/`, or `data/`, or ML libs (torch, tensorflow, jax, sklearn) | ml-platform |
| Multiple language manifests, or `packages/` / `services/` / `apps/` dirs, or workspace config (pnpm-workspace.yaml, nx.json, turbo.json) | hybrid |
| No strong signal | hybrid |

**If uncertain**: ask the user once — "Is this a web-app, robotics, ml-platform, or hybrid project?"

---

## Step 2 — Read the profile

Read `templates/memory/profile.<type>.yaml` from the agents-rules repo.

It contains:
- `areas`: the initial memory branches for this project type
- `area_hints`: one-line description for each area

---

## Step 3 — Run the bootstrap script

```bash
scripts/bootstrap-memory-tree.sh /path/to/project [profile]
```

This creates:
```
agent-docs/memory/
  MEMORY.md              ← root index (from template + profile areas)
  <area>.md              ← one stub per profile area
  decisions/
    INDEX.md             ← empty decisions index
agent-docs/evidence/     ← placeholder for raw evidence
```

If the script is unavailable, create the files manually using the templates in `templates/memory/`.

---

## Step 4 — Populate from immediately available facts

Read the project root. For each area file, fill in what you already know:

- **Stack**: read `package.json`, `pyproject.toml`, `Cargo.toml`, or equivalent
- **Architecture**: read top-level directory structure and any existing README/CLAUDE.md
- **Conventions**: look for `.eslintrc`, `.editorconfig`, existing code style in a few files
- **Gotchas**: check existing CLAUDE.md, AGENTS.md, or README for warnings and constraints

For each fact you write:
- Use **Current State** section for what is true now
- Leave `<!-- TODO: backfill -->` only where evidence is genuinely missing
- Do not invent facts — write only what you can verify from the repo

Every area node uses this structure (from `area.template.md`):
- **Purpose** — what this area covers
- **Current State** — verified facts
- **Recent Changes** — rolling log, pruned periodically
- **Decisions** — links to `decisions/`
- **Open Questions** — unresolved items
- **Subtopics** — links to sub-files if the area grows large

---

## Step 5 — Set up Cursor symlink (if needed)

```bash
# Find the Cursor project ID for this workspace
CURSOR_PROJECT=$(ls ~/.cursor/projects/ | while read d; do
    [ -f "$HOME/.cursor/projects/$d/.project" ] && \
      grep -q "$(basename $(pwd))" "$HOME/.cursor/projects/$d/.project" 2>/dev/null && echo "$d"
done | head -1)

if [ -n "$CURSOR_PROJECT" ]; then
    ln -sf "$(pwd)/agent-docs/memory" "$HOME/.cursor/projects/$CURSOR_PROJECT/memory"
    echo "Symlinked to ~/.cursor/projects/$CURSOR_PROJECT/memory"
fi
```

---

## Step 6 — Trigger history backfill

Bootstrap creates structure only. To fill it with real project history:

```bash
scripts/import-agent-history.sh /path/to/project
```

Then follow the `history-backfill` skill to distill evidence into memory.

---

## Output checklist

After bootstrap, verify:
- [ ] `agent-docs/memory/MEMORY.md` exists and has real content (not just placeholders)
- [ ] Each area file has a **Purpose** and at least one entry in **Current State**
- [ ] `decisions/INDEX.md` exists (may be empty)
- [ ] `agent-docs/evidence/` exists (may be empty until import script runs)
- [ ] MEMORY.md is under 200 lines
