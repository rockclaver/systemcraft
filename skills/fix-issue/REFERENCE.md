# fix-issue: Language-specific quality gates

## JavaScript / TypeScript (Node)

```bash
# Type check
npx tsc --noEmit

# Lint
npm run lint
# fallback: npx eslint . --ext .ts,.tsx,.js,.jsx

# Format check
npm run format:check
# fallback: npx prettier --check .

# Tests
npm test
# or: npm run test:ci
# or: npx vitest run
# or: npx jest --ci
```

## Python

```bash
# Type check
mypy .

# Lint + format
ruff check .
ruff format --check .

# Tests
pytest
# or: python -m pytest -x --tb=short
```

## Go

```bash
go vet ./...
golangci-lint run        # if installed
go test ./...
```

## Rust

```bash
cargo clippy -- -D warnings
cargo fmt --check
cargo test
```

## Ruby / Rails

```bash
bundle exec rubocop
bundle exec rspec
```

## Detecting the stack

Look for these files to determine which commands to run:

| File | Stack |
|------|-------|
| `package.json` | Node/JS/TS |
| `tsconfig.json` | TypeScript |
| `pyproject.toml` / `setup.py` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `Gemfile` | Ruby |

Always check `package.json` scripts before falling back to defaults — the project may have custom `lint`, `test`, or `typecheck` scripts.

## Detecting the test runner (JS/TS)

```bash
# Check package.json for test script and devDependencies
cat package.json | grep -E '"test"|"vitest"|"jest"'
```

## When there is no CI config

If `.github/workflows/` exists, read it to discover the exact commands CI runs — use those commands verbatim as the quality gate.
