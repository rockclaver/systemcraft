#!/usr/bin/env bash
# find.sh — Code and file finder for AI agents
#
# ALWAYS returns results as:  file:line: content
# so the agent can jump directly without a second scan.
#
# Usage:
#   find.sh "pattern"                       # text/regex search
#   find.sh --file "name"                   # find file by name
#   find.sh --def "Symbol"                  # find where symbol is defined
#   find.sh --callers "Symbol"              # find all usages/callers
#   find.sh --imports "moduleName"          # find all imports of a module
#   find.sh "pattern" --ext ts             # filter by extension
#   find.sh "pattern" --in src/services    # scope to a folder
#   find.sh "pattern" --flags "-i"         # pass extra grep flags
#   find.sh "pattern" --limit 100          # override result cap (default 50)

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
MODE="text"          # text | file | def | callers | imports
PATTERN=""
EXT=""               # e.g. "ts" → --include="*.ts"
SEARCH_DIR="."
EXTRA_FLAGS=""
LIMIT=50
ROOT_DIR="${PWD}"

# Directories always excluded
EXCLUDE_DIRS=(node_modules .git dist build out coverage .next .nuxt __pycache__ .venv venv tmp)

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
DIM='\033[2m'
RESET='\033[0m'

# ── Arg parsing ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)      MODE="file";    PATTERN="$2"; shift 2 ;;
    --def)       MODE="def";     PATTERN="$2"; shift 2 ;;
    --callers)   MODE="callers"; PATTERN="$2"; shift 2 ;;
    --imports)   MODE="imports"; PATTERN="$2"; shift 2 ;;
    --ext)       EXT="$2";       shift 2 ;;
    --in)        SEARCH_DIR="$2"; shift 2 ;;
    --flags)     EXTRA_FLAGS="$2"; shift 2 ;;
    --limit)     LIMIT="$2";    shift 2 ;;
    --*)         echo "Unknown option: $1" >&2; exit 1 ;;
    *)           PATTERN="$1";  shift ;;
  esac
done

if [[ -z "$PATTERN" ]]; then
  echo "Usage: find.sh [--file|--def|--callers|--imports] <pattern> [--ext EXT] [--in DIR] [--flags FLAGS]" >&2
  exit 1
fi

# ── Build exclude args ────────────────────────────────────────────────────────
GREP_EXCLUDES=()
FIND_EXCLUDES=()
for d in "${EXCLUDE_DIRS[@]}"; do
  GREP_EXCLUDES+=("--exclude-dir=$d")
  FIND_EXCLUDES+=("-not" "-path" "*/$d/*")
done

# ── Build include (extension filter) ─────────────────────────────────────────
GREP_INCLUDE=""
FIND_EXT_FILTER=""
if [[ -n "$EXT" ]]; then
  GREP_INCLUDE="--include=*.$EXT"
  FIND_EXT_FILTER="-name '*.$EXT'"
fi

# ── Header ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}find-code${RESET} mode=${MODE} pattern=\"${PATTERN}\"$(
  [[ -n "$EXT" ]] && echo " ext=$EXT"
  [[ "$SEARCH_DIR" != "." ]] && echo " in=$SEARCH_DIR"
)" >&2
echo -e "${DIM}Results: file:line: content  (capped at $LIMIT)${RESET}" >&2
echo "" >&2

# ── Search functions ──────────────────────────────────────────────────────────

do_grep() {
  local pattern="$1"
  local extra_flags="${2:-}"
  grep -rn \
    $extra_flags \
    $EXTRA_FLAGS \
    ${GREP_INCLUDE:+"$GREP_INCLUDE"} \
    "${GREP_EXCLUDES[@]}" \
    "$pattern" \
    "$SEARCH_DIR" 2>/dev/null \
  | head -n "$LIMIT" \
  | sed "s|^\./||"  # strip leading ./
}

search_text() {
  local results
  results=$(do_grep "$PATTERN")
  if [[ -z "$results" ]]; then
    echo -e "${YELLOW}No results for: $PATTERN${RESET}" >&2
    echo "EMPTY"
    return
  fi
  local count
  count=$(echo "$results" | wc -l | tr -d ' ')
  echo -e "${CYAN}$count match(es):${RESET}" >&2
  echo "$results"
}

search_file() {
  # Find files whose name matches the pattern (case-insensitive)
  local results
  results=$(find "$SEARCH_DIR" -type f \
    -iname "*${PATTERN}*" \
    "${FIND_EXCLUDES[@]}" \
    2>/dev/null \
    | sort \
    | head -n "$LIMIT" \
    | sed 's|^\./||')

  if [[ -z "$results" ]]; then
    echo -e "${YELLOW}No files matching: *${PATTERN}*${RESET}" >&2
    echo "EMPTY"
    return
  fi

  local count
  count=$(echo "$results" | wc -l | tr -d ' ')
  echo -e "${CYAN}$count file(s) found:${RESET}" >&2

  # Output with a fake line:1 so format is consistent: file:1: (filename match)
  while IFS= read -r file; do
    echo "${file}:1: [FILE MATCH]"
  done <<< "$results"
}

search_def() {
  # Find where a symbol is *defined* — export/def/func/class declarations
  # Patterns cover TS/JS, Python, Go, Ruby, Java, PHP
  local patterns=(
    # TypeScript / JavaScript
    "export[[:space:]]+(default[[:space:]]+)?(async[[:space:]]+)?(function|class|const|let|var|type|interface|enum)[[:space:]]+${PATTERN}[[:space:(<,{]"
    "export[[:space:]]+default[[:space:]]+${PATTERN}"
    # Function assigned to const/let (arrow fn)
    "(const|let|var)[[:space:]]+${PATTERN}[[:space:]]*=[[:space:]]*(async[[:space:]]+)?(\(|function)"
    # Python
    "^def[[:space:]]+${PATTERN}[[:space:]]*\("
    "^class[[:space:]]+${PATTERN}[[:space:]]*[:(]"
    # Go
    "^func[[:space:]]+((\([^)]+\)[[:space:]]+)?${PATTERN})[[:space:]]*\("
    "^type[[:space:]]+${PATTERN}[[:space:]]"
    # Generic: any assignment or declaration
    "^[[:space:]]*(public|private|protected|static|async)?[[:space:]]*${PATTERN}[[:space:]]*[=(:{]"
  )

  local all_results=""
  for pat in "${patterns[@]}"; do
    local r
    r=$(do_grep "$pat" "-E" 2>/dev/null || true)
    [[ -n "$r" ]] && all_results+="${r}"$'\n'
  done

  # Deduplicate by file:line
  all_results=$(echo "$all_results" | sort -u | grep -v '^$' | head -n "$LIMIT")

  if [[ -z "$all_results" ]]; then
    echo -e "${YELLOW}No definition found for: ${PATTERN}${RESET}" >&2
    echo -e "${DIM}Tip: try broader search: find.sh \"${PATTERN}\"${RESET}" >&2
    echo "EMPTY"
    return
  fi

  local count
  count=$(echo "$all_results" | wc -l | tr -d ' ')
  echo -e "${CYAN}$count definition(s):${RESET}" >&2
  echo "$all_results"
}

search_callers() {
  # Find all usages/calls — exclude definition lines
  local results
  results=$(do_grep "$PATTERN" "-E")

  if [[ -z "$results" ]]; then
    echo -e "${YELLOW}No usages found for: ${PATTERN}${RESET}" >&2
    echo "EMPTY"
    return
  fi

  # Filter out likely definition lines (lines with export/def/func/class before the name)
  local filtered
  filtered=$(echo "$results" | grep -vE "(^[^:]+:[0-9]+:[[:space:]]*(export|def |func |class |type |interface )|#.*${PATTERN})" || true)

  [[ -z "$filtered" ]] && filtered="$results"  # fallback to all if filtering removed everything

  local count
  count=$(echo "$filtered" | grep -c . || echo 0)
  echo -e "${CYAN}$count caller(s)/usage(s):${RESET}" >&2
  echo "$filtered" | head -n "$LIMIT"
}

search_imports() {
  # Find all files that import a given module name
  local patterns=(
    "from[[:space:]]+['\"].*${PATTERN}['\"]"          # ESM: from 'module'
    "require\(['\"].*${PATTERN}['\"]"                  # CJS: require('module')
    "import[[:space:]]+.*['\"].*${PATTERN}['\"]"       # import 'module'
    "^from[[:space:]]+${PATTERN}"                      # Python: from module import
    "^import[[:space:]]+\".*${PATTERN}\""              # Go
  )

  local all_results=""
  for pat in "${patterns[@]}"; do
    local r
    r=$(do_grep "$pat" "-E" 2>/dev/null || true)
    [[ -n "$r" ]] && all_results+="${r}"$'\n'
  done

  all_results=$(echo "$all_results" | sort -u | grep -v '^$' | head -n "$LIMIT")

  if [[ -z "$all_results" ]]; then
    echo -e "${YELLOW}No imports found for module: ${PATTERN}${RESET}" >&2
    echo "EMPTY"
    return
  fi

  local count
  count=$(echo "$all_results" | wc -l | tr -d ' ')
  echo -e "${CYAN}$count import(s):${RESET}" >&2
  echo "$all_results"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
case "$MODE" in
  text)    search_text ;;
  file)    search_file ;;
  def)     search_def ;;
  callers) search_callers ;;
  imports) search_imports ;;
esac

# ── Footer ────────────────────────────────────────────────────────────────────
echo "" >&2
echo -e "${DIM}Refine: add --in <dir>, --ext <ext>, or --flags \"-i\" for case-insensitive${RESET}" >&2
