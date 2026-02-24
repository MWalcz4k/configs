---
name: go-benchmarks
description: >
  Go benchmarking patterns and best practices. Load when writing or running benchmarks.
  Triggers: writing benchmarks, b.N, b.Loop, b.ResetTimer, -bench flag, -benchmem,
  -benchtime, benchstat, sub-benchmarks, table-driven benchmarks, memory allocation
  benchmarks, comparing benchmark results.
---

# Go Benchmarks

Write and run benchmarks for Go projects following best practices.

## When This Skill MUST Be Used

**ALWAYS invoke this skill when the user's request involves ANY of these:**

- Writing benchmark functions (`func Benchmark*`)
- Running benchmarks (`go test -bench`)
- Understanding `b.N` or `b.Loop()` patterns
- Using `b.ResetTimer()`, `b.StopTimer()`, `b.StartTimer()`
- Memory allocation benchmarks (`-benchmem`, `b.ReportAllocs()`)
- Comparing benchmarks with `benchstat`
- Sub-benchmarks or table-driven benchmarks
- Preventing compiler optimization in benchmarks

**If you're about to write or run Go benchmarks, STOP and use this skill first.**

## Critical Safety Rules

**NEVER:**

- Mix `b.N` loop and `b.Loop()` in the same benchmark
- Run benchmarks without `-count` for statistical significance
- Compare raw benchmark numbers without `benchstat`
- Use `b.N` loop in new code (use `b.Loop()` instead)

**ALWAYS:**

- Use `b.Loop()` for all new benchmarks
- Use `-benchmem` to track allocations
- Run with `-count=10` (or more) for reliable comparison
- Use `benchstat` to compare before/after results

## Quick Reference

| Task                        | Command                                  |
| --------------------------- | ---------------------------------------- |
| Run all benchmarks          | `go test -bench=. ./...`                 |
| Run specific benchmark      | `go test -bench=BenchmarkName ./...`     |
| With memory stats           | `go test -bench=. -benchmem ./...`       |
| Multiple runs for stats     | `go test -bench=. -count=10 ./...`       |
| Set minimum duration        | `go test -bench=. -benchtime=5s ./...`   |
| Save results                | `go test -bench=. -count=10 > old.txt`   |
| Compare results             | `benchstat old.txt new.txt`              |
| CPU profile                 | `go test -bench=. -cpuprofile=cpu.prof`  |
| Memory profile              | `go test -bench=. -memprofile=mem.prof`  |

---

# Benchmark Basics

## Philosophy

> "Premature optimization is the root of all evil." — Donald Knuth

Benchmarking enables **data-driven optimization**. Without measurement, optimization is guesswork.

Use benchmarks to:
- Measure performance with nanosecond precision
- Compare implementation alternatives
- Detect performance regressions (CI/CD integration)
- Understand memory allocation patterns

## File and Function Naming

Benchmarks live in `*_test.go` files:

```go
// concat_test.go
package concat

import "testing"

func BenchmarkJoinStrings(b *testing.B) {
    // benchmark code
}
```

Naming conventions:

- Function: `Benchmark<Name>` or `Benchmark<Type>_<Method>`
- File: Same as unit tests (`*_test.go`)

---

# b.Loop() - The Standard Way

Use `b.Loop()` for all benchmarks (Go 1.24+):

```go
func BenchmarkStringConversion(b *testing.B) {
    // Setup runs ONCE (not timed)
    number := 9876543210

    // No b.ResetTimer() needed
    // No result variable needed to prevent optimization

    for b.Loop() {
        strconv.Itoa(number)  // Compiler won't optimize away
    }
}
```

**Advantages of `b.Loop()`:**

| Benefit                   | Explanation                                        |
| ------------------------- | -------------------------------------------------- |
| Setup runs once           | Benchmark function executes once per `-count`      |
| No timer reset needed     | Code outside loop automatically excluded           |
| No optimization tricks    | Function call params/results kept alive by runtime |
| Cleaner code              | Less boilerplate, fewer gotchas                    |

From Go 1.24 release notes:
> Function call parameters and results are kept alive, preventing the compiler
> from fully optimizing away the loop body.

---

# Legacy: b.N Loop (Go < 1.24)

Only use when targeting Go < 1.24.

**How `b.N` works:** The framework starts with a small value (usually 1) and repeatedly
increases it until the benchmark runs for at least 1 second (configurable via `-benchtime`).
This is why the benchmark function may execute multiple times with different `b.N` values.

```go
func BenchmarkStringConversion(b *testing.B) {
    // Setup (runs multiple times!)
    number := 9876543210

    b.ResetTimer()  // REQUIRED to exclude setup

    // Must prevent optimization
    var result string
    for i := 0; i < b.N; i++ {
        result = strconv.Itoa(number)
    }

    // Use result to prevent optimization
    if len(result) == 0 {
        b.Fatal("unexpected empty string")
    }
}
```

**Gotchas with `b.N`:**

| Issue                     | Solution                                           |
| ------------------------- | -------------------------------------------------- |
| Setup counted in timing   | Call `b.ResetTimer()` after setup                  |
| Code optimized away       | Store result in variable, use it somehow           |
| Setup runs multiple times | Move expensive setup to `TestMain` or use fixture  |

---

# Legacy: Timer Control (b.N only)

When using `b.N`, control timing precisely:

```go
func BenchmarkWithSetup(b *testing.B) {
    // Expensive setup
    data := createLargeDataset()
    b.ResetTimer()  // Reset AFTER setup

    for i := 0; i < b.N; i++ {
        process(data)
    }
}

func BenchmarkWithCleanup(b *testing.B) {
    for i := 0; i < b.N; i++ {
        result := process()

        b.StopTimer()   // Pause timing
        validate(result) // Cleanup not measured
        b.StartTimer()  // Resume timing
    }
}
```

| Method            | Use Case                                    |
| ----------------- | ------------------------------------------- |
| `b.ResetTimer()`  | After expensive setup, before measured loop |
| `b.StopTimer()`   | Before cleanup or validation code           |
| `b.StartTimer()`  | After cleanup, resume measurement           |

**Note:** With `b.Loop()`, timer control is rarely needed since only loop body is measured.

---

# Legacy: Preventing Compiler Optimization (b.N only)

With `b.N`, the compiler may eliminate "dead" code:

```go
// BAD: May be optimized away
func BenchmarkMightBeOptimized(b *testing.B) {
    for i := 0; i < b.N; i++ {
        math.Sqrt(float64(i))  // Result unused - may be eliminated
    }
}

// GOOD: Result is used
func BenchmarkPreventOptimization(b *testing.B) {
    var result float64
    for i := 0; i < b.N; i++ {
        result += math.Sqrt(float64(i))
    }
    if result < 0 {
        b.Fatalf("negative result: %f", result)
    }
}
```

**With `b.Loop()`, this is handled automatically.**

---

# Memory Allocation Benchmarks

## Track Allocations

```go
func BenchmarkAllocations(b *testing.B) {
    b.ReportAllocs()  // Report in benchmark output

    for b.Loop() {
        createLargeData()
    }
}
```

Run with `-benchmem` flag:

```bash
go test -bench=. -benchmem ./...
```

## Reading Output

```
BenchmarkJoinStrings-8    5000000    264 ns/op    48 B/op    2 allocs/op
```

| Field              | Meaning                              |
| ------------------ | ------------------------------------ |
| `-8`               | GOMAXPROCS (CPU cores)               |
| `5000000`          | Iterations run                       |
| `264 ns/op`        | Nanoseconds per operation            |
| `48 B/op`          | Bytes allocated per operation        |
| `2 allocs/op`      | Allocations per operation            |

---

# Sub-benchmarks

Test different parameters with sub-benchmarks:

```go
func BenchmarkSort(b *testing.B) {
    sizes := []int{100, 1000, 10000, 100000}

    for _, size := range sizes {
        b.Run(fmt.Sprintf("size=%d", size), func(b *testing.B) {
            data := generateRandomSlice(size)

            for b.Loop() {
                // Copy to avoid sorting already sorted data
                dataCopy := make([]int, len(data))
                copy(dataCopy, data)
                sort.Ints(dataCopy)
            }
        })
    }
}
```

Run specific sub-benchmark:

```bash
go test -bench=BenchmarkSort/size=1000 ./...
```

---

# Table-Driven Benchmarks

Compare multiple implementations:

```go
func BenchmarkHashFunctions(b *testing.B) {
    benchmarks := []struct {
        name   string
        hashFn func([]byte) []byte
    }{
        {"MD5", md5Sum},
        {"SHA1", sha1Sum},
        {"SHA256", sha256Sum},
    }

    input := []byte("test data for hashing")

    for _, bm := range benchmarks {
        b.Run(bm.name, func(b *testing.B) {
            for b.Loop() {
                bm.hashFn(input)
            }
        })
    }
}
```

---

# Benchmarking Concurrent Code

```go
func BenchmarkConcurrentOperation(b *testing.B) {
    for b.Loop() {
        var wg sync.WaitGroup
        wg.Add(10)

        for j := 0; j < 10; j++ {
            go func() {
                defer wg.Done()
                processItem()
            }()
        }

        wg.Wait()
    }
}
```

## Parallel Benchmarks

Run benchmark body in parallel:

```go
func BenchmarkParallel(b *testing.B) {
    b.RunParallel(func(pb *testing.PB) {
        // Each goroutine has its own pb
        for pb.Next() {
            processItem()
        }
    })
}
```

---

# Comparing Benchmarks with benchstat

## Install

```bash
go install golang.org/x/perf/cmd/benchstat@latest
```

## Workflow

```bash
# 1. Run benchmarks, save baseline
go test -bench=. -count=10 > old.txt

# 2. Make changes to code

# 3. Run benchmarks again
go test -bench=. -count=10 > new.txt

# 4. Compare
benchstat old.txt new.txt
```

## Reading benchstat Output

```
               │   old.txt    │            new.txt             │
               │    sec/op    │    sec/op     vs base          │
JoinStrings-16   74.27n ± 15%   45.12n ± 8%   -39.25% (p=0.001 n=10)
```

| Field          | Meaning                                          |
| -------------- | ------------------------------------------------ |
| `± 15%`        | Variability in measurements                      |
| `-39.25%`      | Performance change (negative = faster)           |
| `p=0.001`      | Statistical significance (< 0.05 = significant)  |
| `n=10`         | Number of samples                                |
| `~`            | No significant difference (if shown)             |

**Important:** High p-value (> 0.05) means difference is likely random noise.

---

# Benchmark Flags

| Flag                  | Description                              | Example                    |
| --------------------- | ---------------------------------------- | -------------------------- |
| `-bench=<regex>`      | Run matching benchmarks                  | `-bench=.` (all)           |
| `-benchmem`           | Report memory allocations                | `-benchmem`                |
| `-benchtime=<d>`      | Run each benchmark for duration          | `-benchtime=5s`            |
| `-benchtime=<n>x`     | Run exactly n iterations                 | `-benchtime=1000x`         |
| `-count=<n>`          | Run each benchmark n times               | `-count=10`                |
| `-cpu=<n,...>`        | Run with different GOMAXPROCS            | `-cpu=1,2,4`               |
| `-cpuprofile=<file>`  | Write CPU profile                        | `-cpuprofile=cpu.prof`     |
| `-memprofile=<file>`  | Write memory profile                     | `-memprofile=mem.prof`     |

---

# Common Patterns

## Benchmark with Fixture

```go
type benchFixture struct {
    data   []byte
    client *Client
}

func newBenchFixture(b *testing.B) *benchFixture {
    b.Helper()
    return &benchFixture{
        data:   generateTestData(),
        client: NewClient(),
    }
}

func BenchmarkProcess(b *testing.B) {
    f := newBenchFixture(b)

    for b.Loop() {
        f.client.Process(f.data)
    }
}
```

## Benchmark HTTP Handler

```go
func BenchmarkHandler(b *testing.B) {
    handler := NewHandler()
    req := httptest.NewRequest("GET", "/api/data", nil)

    for b.Loop() {
        rec := httptest.NewRecorder()
        handler.ServeHTTP(rec, req)
    }
}
```

## Avoid Measuring Allocation in Loop

```go
func BenchmarkWithPreallocation(b *testing.B) {
    // Preallocate outside loop
    buf := make([]byte, 1024)

    for b.Loop() {
        // Reuse buffer
        process(buf)
    }
}
```

---

# Troubleshooting

| Issue                     | Cause                          | Fix                                      |
| ------------------------- | ------------------------------ | ---------------------------------------- |
| Results vary wildly       | External factors, GC           | Use `-count=10`, use `benchstat`         |
| Benchmark too fast        | Compiler optimized away        | Use `b.Loop()` or store/use result       |
| Setup included in timing  | Missing `b.ResetTimer()`       | Add `b.ResetTimer()` after setup         |
| Can't compare results     | Different run counts           | Always use same `-count` value           |
| Sub-benchmark not running | Wrong regex                    | Check `-bench` pattern matches           |
| High p-value in benchstat | Not enough samples or noise    | Increase `-count`, reduce system load    |

---

# Anti-Patterns

| Pattern                          | Problem                           | Fix                                    |
| -------------------------------- | --------------------------------- | -------------------------------------- |
| Single benchmark run             | Not statistically significant     | Use `-count=10` or more                |
| Comparing raw ns/op              | Ignores variance                  | Use `benchstat`                        |
| Mixing `b.N` and `b.Loop()`      | Undefined behavior                | Use one or the other                   |
| Heavy setup inside `b.N` loop    | Setup measured                    | Move outside, use `b.ResetTimer()`     |
| Ignoring allocations             | Memory pressure affects perf      | Always use `-benchmem`                 |
| Benchmarking debug builds        | Not representative                | Use release/default build              |

---

# Example Requests

| User Request                     | Action                                                  |
| -------------------------------- | ------------------------------------------------------- |
| "Write a benchmark for this"     | Use `b.Loop()` pattern, add `-benchmem`                 |
| "Run benchmarks"                 | `go test -bench=. -benchmem ./...`                      |
| "Compare before/after"           | Save results with `-count=10`, use `benchstat`          |
| "Benchmark different sizes"      | Use sub-benchmarks with `b.Run()`                       |
| "Why is benchmark result 0 ns?"  | Compiler optimized away - use `b.Loop()` or use result  |
| "Results are inconsistent"       | Use `-count=10`, close other programs, use `benchstat`  |
| "How do I benchmark allocations" | Add `b.ReportAllocs()` or `-benchmem` flag              |

---

# CI/CD Integration

Integrate benchmarks into your pipeline to detect performance regressions:

```bash
# In CI: compare against baseline
go test -bench=. -count=10 > new.txt
benchstat baseline.txt new.txt

# Fail if regression detected (example threshold)
benchstat -format=csv baseline.txt new.txt | \
  awk -F, '$4 > 10 { exit 1 }'  # Fail if >10% slower
```

**Best practices for CI:**

- Store baseline results in version control or artifacts
- Run on consistent hardware (or use relative comparisons)
- Use `-count=10` or higher for statistical significance
- Set acceptable regression thresholds for your project
