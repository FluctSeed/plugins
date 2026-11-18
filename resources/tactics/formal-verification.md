---
name: formal-verification
description: Verify concurrency races, retry loops, distributed protocols, parsers, and state machines using model checking (TLA+), property-based testing, or SMT solvers, and render counterexample paths as Mermaid statecharts.
---

# Formal & Statechart Verification

Unit tests check only the interleavings an author thought to write. Apply this tactic when bugs hide in ordering, retries, idempotency, state machines, parsers, or unsafe invariants where missed edge cases are costly.

## 1. Select Target & Lowest-Cost Verifier

1. **Identify the Core Invariant:** Pick the strongest correctness promise in the touched module (for example: `"a payment is never captured twice across worker retries and lease timeouts"`).
2. **Match Tool to Question:**
   - **Interleaving, concurrency, retries, or protocol state transitions:** Finite-state model checking (TLA+ / TLC, Spin, or exhaustive state-space BFS in the host language).
   - **Parsers, serializers, and pure data-structure invariants across arbitrary inputs:** Property-based / fuzz testing (`Hypothesis`, `fast-check`, `proptest`, `go test -fuzz`) or SMT/bounded verifiers (`Z3`, `Kani`) on the real code.

## 2. Mandatory Quality Rules

1. **Grounded in Real Code:** Every state variable and atomic step in the model must map `[file:symbol]` to an actual atomic boundary in the implementation.
2. **Proven Able to Fail (Mutation Check):** A property check that has never failed proves nothing. Temporarily introduce a broken variant (drop a lock/guard or reorder two steps), confirm the checker produces a counterexample, and revert the mutation before trusting a green pass.
3. **Never Weaken Invariants to Pass:** If the current code violates the invariant, report the exact counterexample trace in code terms without weakening the model.
4. **Record Sync Commit:** Document covered `[file:symbol]` paths, state bounds, the single command to rerun the check, and the `git rev-parse HEAD` commit verified.

## 3. Statechart Visualization (`stateDiagram-v2`)

When modeling state transitions or reporting a state-machine counterexample, render a clean `mermaid` `stateDiagram-v2` chart (`<= 20` transitions) using caller-meaningful state and transition labels rather than raw internal variable names:
- Ensure terminal states are explicit (`[*]`) so valid end states are not misclassified as deadlocks.
- Highlight states that violate an invariant and list the **shortest counterexample path** step by step, then replay that exact sequence as an executable regression test against the real code.
