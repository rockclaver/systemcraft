# Refactor Reference

## Common Architecture Patterns

### Feature-based (vertical slices)
Group code by feature, not by type. Each feature folder owns its routes, components, services, and tests.
```
src/
  features/
    auth/  
      index.ts
      auth.service.ts
      auth.routes.ts
      auth.test.ts
    billing/
      ...
  shared/       ← only truly shared code goes here
  app.ts
```
**When to use**: medium-to-large apps, teams owning different features, when file-type folders cause cross-feature coupling.

### Layer-based (horizontal slices)
Group by technical concern. Classic MVC.
```
src/
  controllers/
  services/
  models/
  routes/
  utils/
```
**When to use**: small apps, solo developers, simple CRUD services where features don't bleed into each other.

### Hexagonal / Ports & Adapters
Domain logic in the center, infrastructure at the edges.
```
src/
  domain/       ← pure business logic, no I/O
  application/  ← use cases, orchestration
  infrastructure/
    db/
    http/
    external-apis/
```
**When to use**: complex business logic that must be testable without real I/O, or when you need to swap databases/frameworks.

---

## Migration Strategies

### Move + re-export shim
Safe for gradual migration. Keep the old path working during the transition.
```ts
// old path: src/utils/format.ts  ← leave this in place temporarily
export { formatDate, formatCurrency } from '../shared/formatting';
```
Remove shims in a later cleanup phase once all imports are updated.

### Codemod (automated import rewriting)
Use when moving many files at once.
- **TypeScript**: `ts-morph` or `tsc --paths`
- **JavaScript**: `jscodeshift`
- **Simple renames**: `sed -i 's|old/path|new/path|g'` (verify with git diff)

### Copy-then-delete
1. Copy file to new location.
2. Update all imports to point to new location.
3. Run tests.
4. Delete old file.

Never do step 3 and 4 in the same commit.

### Strangler fig
For large modules that can't be moved atomically:
1. Create the new module at the target location.
2. Route new code to the new module.
3. Gradually migrate callers from old → new.
4. Delete old module when empty.

---

## Phase 0: Safety Net (no tests case)

If the codebase has no automated tests, create a minimal smoke test before any structural changes:

```bash
# Example: Node.js — just assert the app starts
node -e "require('./src/app'); console.log('OK')"
```

For web apps: a single Playwright/Cypress "loads without errors" test is enough to catch import failures from mismatched refactors.

---

## Verification Commands by Stack

| Stack | Verify with |
|---|---|
| TypeScript | `tsc --noEmit` |
| Node.js | `node -e "require('./src')"` |
| React | `npm run build` or `vite build` |
| Python | `python -m py_compile **/*.py` or `pytest` |
| Go | `go build ./...` |
| Rust | `cargo check` |
| Any | run existing test suite |

Always prefer the fastest check first (type-check before full test run).

---

## Red Flags During Refactor

- A file is imported by >10 other files → extract to `shared/` carefully, don't move without updating all callers
- Circular imports appear after a move → the module boundary is wrong, reconsider the split
- Tests start relying on folder paths (snapshots with paths) → update snapshots in a dedicated commit, not mixed with moves
- Build time increases after restructure → check for duplicate bundles or barrel file issues
