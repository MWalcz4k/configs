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

### Step 2 — Scan for the well-known targets

Check whether **any** of these exact target names exist in the Makefile:

| Target | Scope |
|--------|-------|
| `integration` | Integration tests |
| `integration-test` | Integration tests |
| `e2e` | End-to-end tests |
| `component-test` | Component tests |

**If none of these targets exist and there is no other test-related target → go to [Fallback](#fallback-no-makefile-or-no-test-targets).**

### Step 3 — Find the primary test target

Look for a general test target in the Makefile: `test`, `tests`, `unit`, `run-tests`, `check`, or a target whose recipe calls `go test`.

### Step 4 — Run targets

- **Always run the primary test target first** (e.g., `make test`). If no primary target exists but well-known targets do, skip this step.
- **For every well-known target that exists** (`integration`, `integration-test`, `e2e`, `component-test`), run it — always, unconditionally.
- Run each target separately so failures are easy to isolate.

Example (primary target + all well-known targets present):

```bash
make test
make integration
make integration-test
make e2e
make component-test
```

Example (only some well-known targets present):

```bash
make test
make integration
make e2e
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
- **Always run every well-known target that exists** — no skipping.
- Never run only unit tests and call it done.
- If a Makefile target fails, report the error immediately; do not silently
  fall back to `go test`.
