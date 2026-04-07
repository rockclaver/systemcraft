# Code Graph Reference

## How the Scripts Work

```
scan.js            → discovers files (find), extracts exports (grep), maps imports (grep)
                     outputs a DRAFT with ??? placeholders
                     no AI tokens spent

check-stale.sh     → reads graph header commit vs git HEAD
                     exits 0 (fresh), or prints PARTIAL/FULL_REBUILD + changed files

Agent              → reads draft, fills in ??? Purpose fields only
                     never re-extracts exports or imports
```

---

## Full Build Flow

```bash
mkdir -p .claude

# Run scanner — all structural work done here
node <skill-dir>/scripts/scan.js > .claude/codegraph.draft.md

# Agent reads draft and fills in ??? fields, then saves final:
# cp .claude/codegraph.draft.md .claude/codegraph.md
# (after annotating purpose fields)
```

---

## Partial Update Flow

```bash
# 1. Check staleness
bash <skill-dir>/scripts/check-stale.sh --verbose
# Outputs: PARTIAL + SINCE_COMMIT=abc1234 + list of changed files

# 2. Re-scan only changed files
node <skill-dir>/scripts/scan.js --since abc1234 > .claude/codegraph.patch.md

# 3. Agent merges patch into existing graph:
#    - Replace rows for changed files
#    - Fill in new ??? fields
#    - Update Commit: header
```

---

## Graph File Format

Saved to `.claude/codegraph.md`. The `Status: DRAFT` line is removed once the agent annotates it.

```markdown
# Code Graph
> Commit: abc1234f | Date: 2026-04-02 | Files: 34 | Lang: js/ts

## Architecture Overview
Express REST API backed by PostgreSQL via Prisma. Requests enter through
auth middleware, route to handlers, pass to a service layer, then a repository
layer. Auth is managed by better-auth. Background jobs run on BullMQ/Redis.

## Entry Points

| File | Purpose |
|---|---|
| `src/index.ts` | HTTP server bootstrap — loads env, registers middleware, starts Express |
| `src/worker.ts` | BullMQ worker — processes email and notification queues |

## Module Index

### src/handlers/

| File | Purpose | Key Exports | Used by |
|---|---|---|---|
| `users.ts` | User CRUD endpoint handlers | getUser, createUser, updateUser, deleteUser | 1 file(s) |
| `auth.ts` | Sign-in, sign-up, session refresh | signIn, signUp, signOut | 1 file(s) |

### src/services/

| File | Purpose | Key Exports | Used by |
|---|---|---|---|
| `userService.ts` | User DB queries + password hashing | UserService | 2 file(s) |
| `authService.ts` | JWT generation + session management | signToken, verifyToken | 2 file(s) |

### src/lib/

| File | Purpose | Key Exports | Used by |
|---|---|---|---|
| `errors.ts` | Typed error classes | AppError, NotFoundError, ValidationError | 8 file(s) |
| `env.ts` | Validated env vars via Zod | env | 6 file(s) |

## Config & Schema Files

- `prisma/schema.prisma`
- `tsconfig.json`

---
_Regenerate: `node <skill-dir>/scripts/scan.js > .claude/codegraph.draft.md`_
```

---

## Agent Annotation Rules

When filling in `???` fields, the agent must:

1. **Architecture Overview** — read the entry point files + package.json only, write 3-5 sentences
2. **Entry Point purpose** — read the first 30 lines of each entry file (`grep -n "" file | head -30`)
3. **Module purpose** — use the already-extracted exports column as context; only `grep` the file if the exports are ambiguous
4. **Do not** read entire files — the exports list is enough for 90% of purpose descriptions

Grep shortcuts for ambiguous files:
```bash
# What does this service do?
grep -n "export\|async\|function\|class" src/services/foo.ts | head -20

# What routes does this handler register?
grep -n "router\.\|app\." src/handlers/foo.ts | head -20

# What model does this touch?
grep -n "prisma\.\|db\." src/services/foo.ts | head -20
```

---

## Folder-Level Summary Format (repos > 60 files)

When `scan.js` detects > 60 source files it switches to folder summaries automatically:

```markdown
### src/features/billing/
> Stripe webhook handling, subscription lifecycle, invoice generation.
> (8 files — exports include: BillingService, requireActiveSubscription, createInvoice)
```

The agent fills in the description line; the exports are already populated by the script.

---

## Token Budget

| Repo size | Script output (draft) | After annotation |
|---|---|---|
| < 20 files | ~40 lines | ~60 lines |
| 20–60 files | ~80–120 lines | ~100–150 lines |
| 60–150 files | ~100–160 lines (folder mode) | ~120–200 lines |
| 150+ files | ~150–200 lines (folder mode) | ~200–280 lines |

The graph must fit in one read. If it exceeds 300 lines after annotation, the agent should collapse smaller folders into single-line entries.

---

## Supported Languages

| Language | Export extraction | Import extraction |
|---|---|---|
| TypeScript / TSX | `export const/function/class/type/interface/enum` | `from './...'` |
| JavaScript / JSX | `export const/function/class`, `module.exports`, `exports.x` | `require('./...')`, `from './...'` |
| Python | `def`, `class` | `from .module import` |
| Go | `func`, `type`, `var`, `const` (capitalized = exported) | `"./..."` |
| Other | Falls back to empty exports — agent infers from filename | — |
