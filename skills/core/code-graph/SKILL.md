---
name: code-graph
description: Builds and maintains a `.claude/codegraph.md` index of a codebase — a structured map of every module with purpose, key exports, and dependencies — so the agent can navigate any repo by reading one file instead of scanning dozens. Use when starting work on an unfamiliar codebase, when asked to index a repo, when context costs are high from repeated scans, or at the start of any task that will touch multiple files.
---

# Code Graph

Build a persistent `.claude/codegraph.md` index so any future task can read one file and know exactly where to look. Scripts do all structural extraction — the agent only writes purpose summaries.

## Quick Start

```bash
# 1. Run the scanner (does all file discovery, export + import extraction)
node <skill-dir>/scripts/scan.js > .claude/codegraph.draft.md

# 2. Check if existing graph is still fresh
bash <skill-dir>/scripts/check-stale.sh   # exits 0 if fresh, 1 if stale

# 3. Agent annotates the draft with purpose summaries → saves as codegraph.md
```

## Workflow

### 1. Check freshness first

```bash
bash <skill-dir>/scripts/check-stale.sh
```

Exits `0` (fresh) → read `.claude/codegraph.md` directly and skip all scanning.
Exits `1` (stale or missing) → proceed to step 2.

### 2. Run the scanner

```bash
node <skill-dir>/scripts/scan.js > .claude/codegraph.draft.md
```

The script outputs a structured draft containing: file list, detected exports, local import graph, entry points, and "used-by" counts — all extracted via grep without reading full file content. No AI tokens spent.

For a partial update (only changed files since last graph):

```bash
node <skill-dir>/scripts/scan.js --since <recorded-commit> > .claude/codegraph.draft.md
```

### 3. Agent annotates — purpose summaries only

Read `.claude/codegraph.draft.md`. For each file node it will contain `Purpose: ???`. Fill in **one sentence only** describing what the file does. Do not re-extract exports or imports — the script already did that.

Use grep to clarify a file's role if the exports alone aren't enough:
```bash
grep -n "export\|class\|function" src/services/userService.ts | head -20
```

Write the annotated result to `.claude/codegraph.md` (overwrite draft).

### 4. Using the graph

Before any task: read `.claude/codegraph.md`, identify relevant files from the index, read only those. Use grep to navigate within them:
```bash
grep -rn "functionName" src/          # find where something is defined
grep -rn "import.*userService" src/   # find all callers of a module
```

### 5. Update after changes

```bash
node <skill-dir>/scripts/scan.js --since HEAD~1 > .claude/codegraph.draft.md
# Agent re-annotates only the changed nodes, merges with existing graph
```

## Guardrails

- Scripts run first — never ask the agent to discover files or extract exports manually.
- Never store line numbers in the graph — they go stale immediately.
- Graph must stay under 300 lines. If it exceeds that, the script switches to folder-level summaries.
- The graph is a navigation aid — always read the actual file before editing it.

## References

- [REFERENCE.md](REFERENCE.md) — graph file format, node template, folder-level summary, token budget.
