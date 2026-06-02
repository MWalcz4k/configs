---
name: go-test
description: >
  Go testing patterns and best practices. Load when writing or running Go tests.
  Triggers: running tests, writing test files, test coverage, benchmarks,
  integration tests, table-driven tests, mocking, fixtures, or asking about
  Go testing patterns.
license: MIT
compatibility: opencode
---

# Go Testing

Run and write tests for Go projects following best practices.

## When This Skill MUST Be Used

**ALWAYS invoke this skill when the user's request involves ANY of these:**

- Running `go test` or asking to run tests
- Writing or modifying `*_test.go` files
- Setting up integration tests with databases
- Test coverage analysis
- Benchmarking Go code
- Mocking or test fixtures
- Table-driven tests
- Race condition detection
- Test structure (GIVEN-WHEN-THEN)

**If you're about to run or write Go tests, STOP and use this skill first.**

## Critical Safety Rules

**NEVER:**
- Run integration tests without checking for required env vars
- Skip the `-race` flag in CI/CD pipelines
- Leave test containers running after tests
- Commit code with failing tests
- Use `require`/`Fatal` inside goroutines (causes panic)
- Share mocks, loggers, or DB connections between parallel tests

**AVOID:**
- Testing non-public functions unless strictly necessary (use `package foo_test`)

**ALWAYS:**
- Use `t.Parallel()` for independent tests AND subtests
- Clean up test resources with `t.Cleanup()`
- Use build tags to separate unit and integration tests
- Check test coverage for new code
- Mark helper functions with `t.Helper()`
- Use a fixture struct to manage test dependencies
- Write subtests using t.Run() instead of having subtests in separate Test functions

## Quick Reference

| Task | Command |
|------|---------|
| Run all tests | `go test -tags=integration,component,e2e ./...` |
| Verbose output | `go test -tags=integration,component,e2e -v ./...` |
| With coverage | `go test -tags=integration,component,e2e -cover ./...` |
| With race detection | `go test -tags=integration,component,e2e -race ./...` |
| Run specific test | `go test -tags=integration,component,e2e -run TestName ./...` |
| Run benchmarks | `go test -tags=integration,component,e2e -bench=. ./...` |
| Force re-run | `go test -tags=integration,component,e2e -count=1 ./...` |

## Running Tests

Always run tests with all three build tags:

```bash
go test -tags=integration,component,e2e ./...
```

Never omit the tags — tests gated behind `integration`, `component`, or `e2e` build tags will be silently skipped otherwise.

---

# Test Structure: GIVEN-WHEN-THEN

- **GIVEN**: Setup and preconditions (use `require` - stop if setup fails)
- **WHEN**: Single action being tested (use `require` - stop if action fails)
- **THEN**: Assertions on results (use `assert` - see all failures)

**Critical**: Only ONE WHEN section per test. Multiple behaviors = multiple tests.

## require vs assert

| Phase | Use | Rationale |
|-------|-----|-----------|
| GIVEN | `require` | Stop if setup fails |
| WHEN | `require` | Stop if action fails |
| THEN | `assert` | See all failures |
| Goroutines | `assert` | NEVER use require (causes panic) |

**Goroutine Warning**: Never use `require`/`Fatal` inside goroutines, HTTP handlers, or callbacks - causes "FailNow called from non-test goroutine" panic.

---

# Parallel Execution

- Always use `t.Parallel()` in tests AND subtests
- Each test creates its own fixture - no shared state
- Subtests must NOT access parent test variables

**Forbidden Sharing:**
- Loggers, database connections, singletons
- File handles, network ports
- Mock expectations defined in parent scope

**Acceptable Sharing:**
- Read-only table data in table-driven tests
- Global constants, types, and functions

---

# File Naming

| Type | File Suffix | Package Declaration | Access |
|------|-------------|---------------------|--------|
| Public tests | `*_test.go` | `package foo_test` | Exported only (preferred) |
| Private tests | `*_internal_test.go` | `package foo` | All members |
| Integration | `*_integration_test.go` | `//go:build integration` | Real deps |

**Default**: Use public tests. Add private tests only for internal invariants or combinatorial explosion.

## Test Naming

- Functions: `Test<Type>_<Method>` (e.g., `TestUserService_CreateUser`)
- Subtests: Short, descriptive (e.g., `"with valid input"`, `"returns error"`)

---

# Table-Driven Tests

## When to Use

- Simple data variations (primitives only)
- Boundary conditions and validation
- 3-4 fields maximum in table struct

## The Simplicity Test

> "Can I understand what each test case does by looking at one line in the table?"

If NO, use separate tests instead.

## Anti-patterns (Never Put in Tables)

| Anti-pattern | Why Bad |
|--------------|---------|
| Mock expectations | Behavior, not data |
| Boolean flags | Creates different test logic |
| Setup/assertion functions | Hides complexity |
| Auto-generated templates | Generic, not thoughtful |

---

# Fixture Pattern

```go
type fixture struct {
    ctx      context.Context
    mockRepo *MockRepository
    sut      *Service
}

func newFixture(t *testing.T) *fixture {
    t.Helper()
    ctrl := gomock.NewController(t)
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    t.Cleanup(cancel)
    
    mockRepo := NewMockRepository(ctrl)
    return &fixture{
        ctx:      ctx,
        mockRepo: mockRepo,
        sut:      NewService(mockRepo),
    }
}
```

---

# Mocking

- Define interfaces in `interfaces.go`
- Add `//go:generate mockgen` directive
- Store mocks in `mock_test.go` with `package foo_test`
- `gomock.Any()` when values don't matter
- `gomock.Eq()` for exact matching in happy path
- Create new mock controller per test/subtest
- Mocks should be put inside a fixture struct, with a constructor that creates that fixture
- Mocks should only verify input parameters when relevant, if test is testing successful path, otherwise they should accept "any" input

---

# Must Constructor Pattern

For test helpers that panic on error (never in production):

```go
// Production: returns error
func NewCategoryID(value string) (CategoryID, error)

// Tests only: panics on error
func MustCategoryID(value string) CategoryID {
    id, err := NewCategoryID(value)
    if err != nil {
        panic(err)
    }
    return id
}
```

Standard library examples: `regexp.MustCompile`, `template.Must`

---

# Deterministic Tests

Inject all nondeterminism:

| Source | Solution |
|--------|----------|
| `time.Now()` | `Clock` interface |
| `uuid.New()` | `UUIDGenerator` interface |
| Random numbers | Injectable generator |

---

# Contract Testing (Marshal/Unmarshal)

- Use raw JSON strings as the "contract"
- Don't use internal types for both encode and decode
- Use `testify.JSONEq()` for comparison
- Store JSON contracts in `testdata/` directory

---

# Testing Conversion Layers

What to test in HTTP/gRPC handlers:
1. Request unmarshaling and argument passing
2. Error translation (domain errors -> protocol errors)
3. Response marshaling

Pattern: Mock domain layer, verify exact arguments, verify error codes.

---

# Coverage

| Type | Goal | Build Tag |
|------|------|-----------|
| Unit tests | 100% (all deps mocked) | None |
| Integration tests | As appropriate | `integration` |

---

# Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Tests skipped | Missing env vars | Set `TEST_MYSQL_DSN` etc. |
| Tests silently missing | Forgot build tags | Always use `-tags=integration,component,e2e` |
| Connection refused | DB not running | Start container, wait for ready |
| Race detected | Concurrent access | Add mutex or redesign |
| Flaky tests | Shared state / timing | Use `t.Parallel()`, fix timing |
| Slow tests | No parallelization | Add `t.Parallel()` |
| Cache issues | Stale results | Use `-count=1` or clean cache |
| "FailNow from non-test goroutine" | `require` in goroutine | Use `assert` instead |
