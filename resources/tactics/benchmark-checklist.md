---
name: benchmark-checklist
description: Vet any performance measurement (limiter, production tuning, physical bounds, error rate, interleaved repeatability, end-to-end share, and proof of execution) before reporting or acting on a speedup or regression.
---

# Benchmark Checklist

Apply this checklist whenever producing or evaluating a performance number: before/after comparisons, `perf` tracks, hillclimb loops, or library/configuration choices. Answer every question from observed run evidence rather than assumptions.

For a quick single-run estimate requested explicitly as a ballpark, verify Questions 4 and 7 and label the result as a single-run estimate. Never use a single run to pick between competing implementations.

## Pre-Run Setup

1. Write down the exact claim under test with units and dataset size (for example, `"CSV export p50 drops by >=25% on 60k rows"`).
2. Read the benchmark script in full and note what lies inside and outside the timed region.
3. Check machine load (`uptime`) and CPU count (`nproc` or `sysctl -n hw.ncpu`). Interleave runs (`A, B, A, B, ...`) so background noise affects both sides equally.

## Seven Mandatory Checks

1. **Why Not Double? (Name the Limiter):** Profile in a separate un-reported run (since profilers perturb wall time) using `perf`, `py-spy`, `node --cpu-prof`, CPU/IO stats, or syscall counts. Map the bottleneck to source code, and verify the load generator itself is not saturated.
2. **Was Both Sides Tuned as Production Runs It?** Use release builds, production flags, identical connection pools, batch sizes, indexes, and warm/cold cache states on both sides. Comparing tuned code against default debug settings measures configuration, not architecture.
3. **Does Arithmetic Respect Physical & Amdahl Limits?** Compare throughput against disk/network/memory bandwidth and core budgets, and check Amdahl's bound: removing a component that takes 10% of total runtime can speed up the whole run by at most ~11%. Numbers exceeding physical bounds indicate a cache hit, skipped work, or bug.
4. **Did Any Requests Error or Return Partial Output?** Count non-2xx responses, exceptions, and truncated outputs inside the harness. Fast rejections look like speedups; timeouts look like regressions.
5. **Does It Reproduce Across Interleaved Runs?** Run at least 5 interleaved iterations per side (`A, B, A, B, ...`) and report the median and min-to-max range. Treat a delta smaller than run-to-run spread as `"no measurable difference"`.
6. **Does It Matter End-to-End?** Alongside any microbenchmark, measure the user-facing end-to-end operation on realistic payload sizes and report the micro target's share of total latency.
7. **Did the Work Actually Execute Inside the Timed Region?** Verify side effects (rows written, bytes parsed, promises awaited, lazy iterators consumed, dead-code elimination prevented).

## Reporting Format

- State the verdict first: `faster`, `slower`, `no measurable difference`, or `inconclusive` (when the limiter is unknown, tuning is asymmetric, or Checks 4 and 7 were not verified).
- Report unit, run count, median, range, and named limiter in one line (for example: `"p50 41 ms -> 33 ms across 7 interleaved runs (range 32-35 ms), bound by single-core JSON serialization"`).
