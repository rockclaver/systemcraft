# Test Coverage Reference

## Selection Heuristics

Prefer writing tests for code that has at least one of these properties:

- Multiple branches, early returns, or state transitions
- User-visible behavior or stable public APIs
- Parsing, formatting, serialization, or deserialization
- Validation and error mapping
- Security-sensitive logic, auth checks, permissions, or data access filters
- Recent changes or files adjacent to bug fixes

Lower priority targets:

- Passive data containers
- Framework boilerplate with no domain behavior
- Private helpers already exercised through stronger public-path tests

## Framework Signals

Common files worth checking:

- JavaScript/TypeScript: `package.json`, `vitest.config.*`, `jest.config.*`, `playwright.config.*`, `cypress.config.*`, `tsconfig.json`
- Python: `pyproject.toml`, `pytest.ini`, `tox.ini`, `setup.cfg`, `.coveragerc`
- Go: `go.mod`, `*_test.go`
- Java/Kotlin: `pom.xml`, `build.gradle`, `build.gradle.kts`
- Ruby: `Gemfile`, `.rspec`
- Rust: `Cargo.toml`

Coverage artifacts worth checking:

- `coverage/lcov.info`
- `coverage-final.json`
- `coverage.xml`
- `jacoco.xml`
- `.coverage`

## Test Quality Rules

- Prefer one strong test over several overlapping weak ones.
- Assert behavior from the outside in where possible.
- Keep fixtures local unless shared setup clearly reduces noise.
- Add regression tests for known failures before refactoring.
- If a branch is unreachable without major refactor, document that constraint instead of forcing brittle tests.
