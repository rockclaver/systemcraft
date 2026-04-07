#!/usr/bin/env bash
# check-stale.sh — Check if .claude/codegraph.md is up to date
#
# Usage:
#   bash check-stale.sh           # exits 0 if fresh, 1 if stale/missing
#   bash check-stale.sh --verbose # prints reason
#
# Used by the agent before deciding whether to re-run scan.js

GRAPH_FILE="${GRAPH_FILE:-.claude/codegraph.md}"
STALE_THRESHOLD="${STALE_THRESHOLD:-10}"  # rebuild fully if >N commits behind
VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

say() { [[ $VERBOSE -eq 1 ]] && echo "$1" >&2; }

# ── 1. Graph file must exist ───────────────────────────────────────────────────
if [[ ! -f "$GRAPH_FILE" ]]; then
  say "STALE: $GRAPH_FILE does not exist."
  exit 1
fi

# ── 2. Must not be a draft (agent hasn't annotated yet) ───────────────────────
if grep -q 'Status: DRAFT' "$GRAPH_FILE" 2>/dev/null; then
  say "STALE: graph is still a draft (unannotated)."
  exit 1
fi

# ── 3. Extract recorded commit from graph header ──────────────────────────────
RECORDED_COMMIT=$(grep -m1 "^> Commit:" "$GRAPH_FILE" | sed 's/.*Commit: \([a-f0-9]*\).*/\1/')

if [[ -z "$RECORDED_COMMIT" ]]; then
  say "STALE: no Commit field found in graph header."
  exit 1
fi

# ── 4. Check if we're in a git repo ───────────────────────────────────────────
if ! git rev-parse HEAD &>/dev/null 2>&1; then
  say "FRESH: not a git repo — treating graph as authoritative."
  exit 0
fi

CURRENT_COMMIT=$(git rev-parse --short HEAD)

# ── 5. Exact match → fresh ────────────────────────────────────────────────────
if [[ "$RECORDED_COMMIT" == "$CURRENT_COMMIT" ]]; then
  say "FRESH: graph matches current commit ($CURRENT_COMMIT)."
  exit 0
fi

# ── 6. Count commits behind ───────────────────────────────────────────────────
COMMITS_BEHIND=$(git rev-list "${RECORDED_COMMIT}..HEAD" --count 2>/dev/null || echo "999")

say "Graph is $COMMITS_BEHIND commit(s) behind (recorded: $RECORDED_COMMIT, current: $CURRENT_COMMIT)."

if [[ "$COMMITS_BEHIND" -gt "$STALE_THRESHOLD" ]]; then
  say "STALE: >$STALE_THRESHOLD commits behind — full rebuild recommended."
  echo "FULL_REBUILD"
  exit 1
fi

# ── 7. Partial update: output changed files ───────────────────────────────────
CHANGED=$(git diff --name-only "${RECORDED_COMMIT}..HEAD" 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|mjs|py|go|rs)$' | head -50)

if [[ -z "$CHANGED" ]]; then
  say "FRESH: no source files changed since $RECORDED_COMMIT."
  exit 0
fi

say "STALE: changed files since $RECORDED_COMMIT:"
say "$CHANGED"

echo "PARTIAL"
echo "SINCE_COMMIT=$RECORDED_COMMIT"
echo "$CHANGED"
exit 1
