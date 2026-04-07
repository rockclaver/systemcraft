---
name: write-tests
description: Write high-value automated tests and improve practical code coverage by inspecting the repository, inferring the active stack, and targeting risky untested behavior first. Use when the user wants stronger tests, broader test coverage, missing test identification, coverage-driven test writing, or regression tests for an existing codebase.
---

# Test Coverage

Write valuable tests that improve confidence and coverage. Prefer behavior that is likely to regress, not low-signal assertions written only to inflate percentages.

## Quick Start

1. Explore the repository structure and identify source, test, and coverage config files.
2. Run `scripts/repo_test_probe.py` from the skill directory against the target repo to infer the stack, test tooling, and coverage artifacts.
3. If coverage reports already exist, use them to find cold spots. Otherwise infer gaps from changed code, complex logic, public APIs, and error-handling branches.
4. Write tests in the project's existing style and framework.
5. Run the narrowest relevant test command first, then broader coverage runs if needed.
6. Iterate until the new tests are stable, meaningful, and improve practical coverage.

## Workflow

### 1. Detect how the project tests itself

- Infer the language, framework, package manager, and test runner from project files rather than guessing.
- Reuse existing helpers, fixtures, factories, mocks, and setup files.
- Match naming, folder layout, and assertion style already present in the codebase.

### 2. Pick high-value targets

Prioritize:

- Business logic with branches or state transitions
- Error handling, retries, validation, and edge cases
- Serialization, parsing, adapters, and boundary code
- Bug-prone recent changes and public entry points

De-prioritize:

- Thin wrappers with no meaningful behavior
- Snapshot-heavy or implementation-coupled tests unless the repo already relies on them
- Tests that only assert mocks were called without checking observable outcomes

### 3. Write tests for behavior, not lines

- Assert outputs, side effects, and externally visible behavior.
- Cover success paths, failure paths, and representative edge cases.
- Keep each test focused and diagnosable.
- Prefer deterministic fixtures over broad random inputs unless the repo already uses fuzz/property tests.

### 4. Validate and iterate

- Run the smallest relevant test scope first.
- Fix flakiness, duplicated setup, and brittle assertions before expanding scope.
- If coverage tooling exists, confirm coverage improved in the target area.
- Stop when additional tests would mostly duplicate implementation details.

## Guardrails

- Do not chase 100% line coverage at the expense of value.
- Do not rewrite unrelated tests unless needed to unblock the new ones.
- Do not introduce a new framework if the repo already has one.
- If the code is hard to test because of design issues, note the seam and still add the best regression coverage feasible.

## References

- Use `REFERENCE.md` for target selection heuristics and framework signals.
- Use `scripts/repo_test_probe.py` to inspect the repo before choosing commands or file locations.
