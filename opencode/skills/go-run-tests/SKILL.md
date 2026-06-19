---
name: go-run-tests
description: >
  Running Go tests in a project. Load when asked to run tests, execute the test
  suite, verify tests pass, or check test results. Triggers: run tests, execute
  tests, make test, go test, run the test suite, run integration tests, run
  component tests, check if tests pass.
license: MIT
compatibility: opencode
---

# Go: Running Tests

## Decision Tree

**Before running any tests, follow this exact sequence:**

### Step 1 — Check for a Makefile

Look for a `Makefile` in the project root.

**If no Makefile exists → go to [Fallback](#fallback-no-makefile-or-no-test-targets).**

### Step 2 — Inspect Makefile for test targets

Scan the Makefile for targets whose names or recipes relate to testing.
Look for patterns like: `test`, `test-unit`, `test-integration`, `test-component`,
`integration-test`, `component-test`, `run-tests`, `check`, etc.

**If no test-related targets exist → go to [Fallback](#fallback-no-makefile-or-no-test-targets).**

### Step 3 — Identify what test targets cover

For each test target found, determine whether it covers:

| Scope | Keywords to look for in target name or recipe |
|-------|-----------------------------------------------|
| Unit tests | `unit`, `go test` without special tags, general `test` |
| Integration tests | `integration`, `integration-test`, `test-integration` |
| Component tests | `component`, `component-test`, `test-component` |

### Step 4 — Run the appropriate Makefile targets

- **Always run the primary/unit test target** (e.g., `make test`).
- **If integration tests have a dedicated target** → also run it (e.g., `make test-integration`).
- **If component tests have a dedicated target** → also run it (e.g., `make test-component`).
- Run each target separately so failures are easy to isolate.

Example (when all three scopes have dedicated targets):

```bash
make test
make test-integration
make test-component
```

---

## Fallback: No Makefile or No Test Targets

When the Makefile is absent or has no test-related targets, run all tests
directly with `go test`, **always including both build tags**:

```bash
go test -tags=integration,component ./...
```

Add flags as needed:

| Need | Extra flag |
|------|-----------|
| Verbose output | `-v` |
| Race detection | `-race` |
| Coverage | `-cover` |
| Force re-run (skip cache) | `-count=1` |
| Specific test | `-run TestName` |

Full example with common flags:

```bash
go test -tags=integration,component -race -count=1 ./...
```

**Never omit `-tags=integration,component`** — tests gated behind those build
tags will be silently skipped otherwise.

---

## Rules

- **Always check the Makefile first.** Do not jump straight to `go test`.
- **Always run integration AND component tests** — either via Makefile targets
  or via build tags in the fallback command.
- Never run only unit tests and call it done.
- If a Makefile target fails, report the error immediately; do not silently
  fall back to `go test`.
