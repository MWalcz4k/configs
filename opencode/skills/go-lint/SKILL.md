---
name: go-lint
description: >
  Run and fix Go lint checks after changing Go code. Use when editing .go files,
  go.mod, or Go tooling; triggers include lint, golangci-lint, gofmt, go vet,
  and static analysis.
license: MIT
compatibility: opencode
---

# Go: Linting

## Required Workflow

After changing Go code, run the project's lint checks before running tests.
Fix every lint failure caused by the change, then rerun the same lint command
until it passes.

## Decision Tree

### Step 1: Check the Makefile

Look for a `Makefile` in the project root. If it has a `lint` target, run:

```bash
make lint
```

Do not substitute another command when this target exists.

### Step 2: Check for golangci-lint

When no `lint` target exists, look for a project `golangci-lint` configuration.
If it exists, run:

```bash
golangci-lint run
```

### Step 3: Fallback

When neither a `lint` target nor a `golangci-lint` configuration exists, run:

```bash
gofmt -d .
go vet ./...
```

`gofmt -d .` must produce no output. Apply formatting with `gofmt -w` only to
the changed Go files, then rerun the checks.

## Rules

- Run the lint command after every Go-code change, including changes to tests.
- Fix failures; do not suppress linters or weaken lint configuration merely to
  make a change pass unless the user explicitly requests it.
- Do not install lint tools or add dependencies without the user's approval.
- If the required lint tool is unavailable, report the missing command and run
  the remaining available checks.
- Run the test suite only after lint checks pass.
