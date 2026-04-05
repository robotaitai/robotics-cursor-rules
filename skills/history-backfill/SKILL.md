---
name: history-backfill
description: Backfill project memory from existing repo evidence (codebase, docs, configs, git history, tasks, sessions, agent traces). Use when the memory tree is new or sparse and the project has existing history.
---

# History Backfill

Reads raw evidence from the repo and existing artifacts, then distills stable facts
into the curated memory tree.

Use this after `project-ontology-bootstrap` when the project has existing history.

---

## Separation rule — enforced, never relaxed

| Location | What goes here | Who edits it |
|----------|----------------|--------------|
| `agent-docs/evidence/` | Raw extracted artifacts — git log, manifests, docs, session lists | Only the import script (overwritten on each run) |
| `agent-docs/memory/` | Curated, stable, distilled facts | Only the agent, via writeback rule |

Never write raw evidence into memory. Never treat evidence as authoritative — it is input for judgment, not truth.

---

## Step 1 — Collect evidence

Run the import script:

```bash
scripts/import-agent-history.sh /path/to/project
```

This creates `agent-docs/evidence/`:
- `git-log.txt` — last 300 commits (oneline)
- `git-log-detail.txt` — last 50 commits with body
- `git-authors.txt` — contributor list
- `structure.txt` — directory tree depth 3
- `manifests.txt` — package/dependency files
- `existing-docs.txt` — README, CLAUDE.md, AGENTS.md content
- `doc-index.txt` — all markdown paths
- `tasks.txt` — tasks/todo.md, tasks/lessons.md if present
- `sessions.txt` — session file listing (no content)
- `ci-workflows.txt` — CI pipeline definitions

---

## Step 2 — Read evidence in priority order

Read these files in order. Each source has different signal quality:

1. **`existing-docs.txt`** — highest signal. README, CLAUDE.md, AGENTS.md contain curated human intent.
2. **`manifests.txt`** — authoritative for stack and dependencies.
3. **`structure.txt`** — reveals actual architecture (dirs, packages, test structure).
4. **`tasks.txt`** — reveals active work areas and lessons learned.
5. **`git-log-detail.txt`** — reveals what has been changing and why.
6. **`git-log.txt`** — reveals patterns of activity (hotspots, refactors, releases).
7. **`ci-workflows.txt`** — reveals build requirements and deployment targets.
8. **`sessions.txt`** — listing only; do not read session content (ephemeral).

For agent traces (Cursor transcripts): treat as evidence with low confidence — the agent may have been wrong. Extract patterns, not individual claims.

---

## Step 3 — Distill into memory

For each stable fact extracted from evidence:

1. Identify which memory area it belongs to (stack, architecture, conventions, gotchas, etc.)
2. Read the current area file
3. Place the fact in the correct section:
   - **Current State**: for verified facts about the project as it is now
   - **Recent Changes**: for things that changed recently (prune after ~4 weeks)
   - **Open Questions**: for things the evidence hints at but doesn't resolve
   - **Decisions**: link to a decision file if it's an architectural choice
4. Lead with the fact. Do not pad with context the reader can find in git.

---

## Step 4 — Quality filters

Only write a fact to memory if it passes all of:
- **Stable**: unlikely to change in the next few weeks
- **Non-obvious**: not immediately derivable from reading the code
- **Useful**: would save a future agent meaningful time or prevent a mistake
- **Verified**: supported by at least one evidence source (not inferred)

Do not write:
- Commit-level implementation details
- Speculative interpretations of code intent
- Facts already in project docs that agents can read directly
- Anything marked as in-progress or planned (goes in session file until confirmed)

---

## Step 5 — Update MEMORY.md

After updating area files, check that MEMORY.md reflects the new content:
- Update the one-line description for any area that changed significantly
- Add new area entries if backfill reveals areas not in the initial profile
- Remove placeholder entries (`<placeholder:...>`) that now have real content

---

## Output checklist

- [ ] Each area file has populated **Current State** (not just TODO markers)
- [ ] Any patterns from git log are captured in **conventions** or **gotchas**
- [ ] Active decisions found in docs are recorded in `decisions/`
- [ ] Open questions are listed for anything evidence hints at but doesn't resolve
- [ ] MEMORY.md descriptions are updated to match real content
- [ ] No evidence content was written directly into memory files
