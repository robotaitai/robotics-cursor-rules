---
name: memory-management
description: Read on session start. Manages adaptive durable memory across conversations. Use when reading or writing curated memory under agent-knowledge/Memory/.
---

# Memory Management

Manages the adaptive project memory tree. Read this skill at session start.

The memory directory path is provided by the session-start hook
(e.g., `~/.cursor/projects/<project-id>/memory/MEMORY.md`).
For project-shared memory, the canonical repo entrypoint is `./agent-knowledge`.
Durable curated memory lives at `agent-knowledge/Memory/MEMORY.md`.

---

## Tree structure

```text
agent-knowledge/
  INDEX.md
  Memory/
    MEMORY.md           ← root memory note — always loaded, keep it short
    <area>.md           ← one durable branch per functional area
    <area>/<subtopic>.md
    decisions/
      INDEX.md          ← decision index, newest first
      YYYY-MM-DD-slug.md
  Evidence/
    raw/
    imports/
  Sessions/             ← milestone-oriented temporary state
  Outputs/
  Dashboards/
```

Evidence (`agent-knowledge/Evidence/raw/` and `agent-knowledge/Evidence/imports/`) is separate from curated memory (`agent-knowledge/Memory/`).
Never copy raw evidence into memory. Distill only stable, verified facts.
Generated structural outputs, relationship graphs, and inferred summaries belong in `Evidence/` or `Outputs/` first.
Only curated notes under `Memory/` are durable project knowledge.

---

## Profile-adaptive branches

The areas in the memory tree depend on the project profile detected at bootstrap:

| Profile | Initial areas |
|---------|--------------|
| web-app | stack, architecture, conventions, gotchas, integrations |
| robotics | stack, architecture, conventions, gotchas, hardware, simulation |
| ml-platform | stack, architecture, conventions, gotchas, datasets, models |
| hybrid | stack, architecture, conventions, gotchas, deployments |

The profile is recorded in `Memory/MEMORY.md` frontmatter.
Add or remove area files as the project grows or shrinks.

---

## Durable note requirements

Every durable memory note must have YAML frontmatter.

Branch notes use these sections:

| Section | Content | Updated when |
|---------|---------|--------------|
| **Purpose** | One sentence: what this area covers | At creation; rarely changes |
| **Current State** | Verified facts about what is true now | Every writeback |
| **Recent Changes** | Rolling log, YYYY-MM-DD format, pruned after ~4 weeks | After meaningful changes |
| **Decisions** | Links to `decisions/YYYY-MM-DD-slug.md` | When a decision is recorded |
| **Open Questions** | Unresolved items for future sessions | When a question is identified; removed when resolved |
| **Subtopics** | Links to sub-files | When the area is split |

Use markdown links for portability. Avoid wiki-links and tool-specific metadata.

Evidence and generated discovery notes should carry confidence labels when practical:

- `EXTRACTED` for direct listings, copied docs, manifests, and path indexes
- `INFERRED` for machine-generated summaries or architecture guesses
- `AMBIGUOUS` for sessions, traces, or uncertain imports that may be stale or wrong

---

## Reading the tree

1. `Memory/MEMORY.md` loads automatically first.
2. Identify which branch notes the task touches from the root note.
3. Read only those area files — keep context lean.
4. Follow subtopic links only if the specific detail is needed.
5. For existing projects, scan `Outputs/architecture-summary.md`, `Outputs/structural-map.md`, or optional `Outputs/graphify/` summaries before grepping raw files.

---

## Writing to the tree

- **Memory/MEMORY.md**: short branch summaries + links. No dense detail.
- **Area file**: all durable facts for that area, organized by section.
- **Decision file**: one file per architectural decision, linked from the area.

Format for facts: lead with the fact. For lessons: add **Why:** and **How to apply:**.

---

## Bootstrap

If `agent-knowledge/Memory/MEMORY.md` is missing or empty:
→ Read and follow the `project-ontology-bootstrap` skill before any other work.

---

## When to write back

Write to memory when any of these happen:
- A new architectural decision is made
- A pattern or convention is confirmed
- A gotcha is discovered
- A feature area is substantially completed or changed
- A recurring mistake is corrected

Do NOT write:
- In-progress task state → session file only
- Speculative plans → wait until confirmed
- Facts already in git history that are easily re-discoverable
- Raw evidence → keep it in `Evidence/`
- Machine-generated structure or graph summaries → keep them in `Evidence/` or `Outputs/` until curated

---

## Compaction

When `Memory/MEMORY.md` grows noisy or an area file exceeds ~150 lines:
→ Read and follow the `memory-compaction` skill.

---

## Explicit user requests

- "Remember X" → save it immediately to the relevant area file
- "Forget X" → remove or mark stale in the relevant area file
- "Why did we choose X" → read `decisions/INDEX.md` and the linked decision file
