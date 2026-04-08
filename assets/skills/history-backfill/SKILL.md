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
| `agent-knowledge/Evidence/raw/` | Direct snapshots from the current repo state | Only the import script |
| `agent-knowledge/Evidence/imports/` | Imported docs, tasks, sessions, traces, graph exports, and structural notes | Only the import script |
| `agent-knowledge/Outputs/` | Generated discovery summaries and structural maps | Only scripts or agents treating them as non-canonical outputs |
| `agent-knowledge/Memory/` | Curated, stable, distilled facts | Only the agent, via writeback rule |

Never write raw evidence into memory. Never treat evidence as authoritative — it is input for judgment, not truth.

---

## Step 1 — Collect evidence

Run the import script:

```bash
scripts/import-agent-history.sh /path/to/project
```

This creates:
- `Evidence/raw/git-log.txt`
- `Evidence/raw/git-log-detail.txt`
- `Evidence/raw/git-authors.txt`
- `Evidence/raw/structure.txt`
- `Evidence/raw/manifests.txt`
- `Evidence/raw/config-files.txt`
- `Evidence/raw/tests.txt`
- `Evidence/raw/ci-workflows.txt`
- `Evidence/imports/existing-docs.txt`
- `Evidence/imports/doc-index.txt`
- `Evidence/imports/tasks.txt`
- `Evidence/imports/session-files.txt`
- `Evidence/imports/cursor-sessions.txt`
- `Evidence/imports/trace-index.txt`
- `Evidence/imports/structural-summary.md`
- `Outputs/architecture-summary.md`
- `Outputs/structural-map.md`
- `Evidence/imports/graphify/` and `Outputs/graphify/` when optional graph imports exist

---

## Step 2 — Read evidence in priority order

Read these files in order. Each source has different signal quality:

1. **`imports/existing-docs.txt`** — highest signal. README, CLAUDE.md, AGENTS.md, and project metadata contain curated intent.
2. **`raw/manifests.txt`** — authoritative for stack and dependency boundaries.
3. **`raw/config-files.txt`** — strongest signal for conventions and tooling.
4. **`raw/tests.txt`** and **`raw/ci-workflows.txt`** — how the project proves and ships behavior.
5. **`raw/structure.txt`** — actual architecture shape.
6. **`imports/tasks.txt`** and **`imports/session-files.txt`** — recurring work areas and unresolved questions.
7. **`raw/git-log-detail.txt`** and **`raw/git-log.txt`** — what changed and why.
8. **`imports/trace-index.txt`** — supplemental traces only; never canonical truth.

Read confidence labels before trusting a source:

- `EXTRACTED` means direct structural evidence
- `INFERRED` means a derived summary that still needs review
- `AMBIGUOUS` means the source may be stale, partial, or wrong

For agent traces (Cursor transcripts) and graph summaries: treat them as evidence with lower confidence than direct repo scans. Extract patterns, not individual claims.

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
- Machine-generated relationship graphs or architecture summaries unless they have been verified against the repo

---

## Step 5 — Update Memory/MEMORY.md

After updating branch notes, check that `Memory/MEMORY.md` reflects the new content:
- Keep the root note short
- Update branch summaries if their durable state changed
- Add branch links if backfill reveals a needed new branch

---

## Output checklist

- [ ] Each area file has populated **Current State** (not just TODO markers)
- [ ] Any patterns from git log are captured in **conventions** or **gotchas**
- [ ] Active decisions found in docs are recorded in `decisions/`
- [ ] Open questions are listed for anything evidence hints at but doesn't resolve
- [ ] `Memory/MEMORY.md` reflects the real branch state
- [ ] No evidence content was written directly into memory files
