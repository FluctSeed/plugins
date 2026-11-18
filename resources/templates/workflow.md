# Project Workflow Standard (`workflow.md`)

## Guiding Principles

1. **The Plan is the Source of Truth:** Every implementation unit is tracked against its approved `plan.md` task checklist (`[ ] -> [~] -> [x] <sha>`). Permanent context documents in `conductor/` (`index.md`, `product.md`, `product-guidelines.md`, `tech-stack.md`, `security-policy.md`, `workflow.md`) describe timeless project state only and never reference `tracks/` or `tracks.md`.
2. **Deliberate Tech Stack & Security Boundaries:** Any change to languages, frameworks, data stores, or security boundaries must be approved and updated in `tech-stack.md` and `security-policy.md` before shipping code.
3. **Cognitive Separation (Draft in Context, Audit with Fresh Context):**
   - Specifications (`spec.md`) and implementation plans (`plan.md`) are drafted with full project context, then audited by isolated fresh-context reviewers against project standards and directory `README.md` contracts before developer approval.
4. **Two-Phase Autonomy:**
   - **Phase 1 (Pre-Gate Ideation, Spec & Audit):** Write zero production code. Present architectural trade-offs without flattery so the developer makes the architectural call. Answer empirical codebase questions by reading code before asking.
   - **Phase 2 (Post-Gate Implementation & Review):** After explicit Stage 3 Human Gate approval, execute reversible steps within the locked specification and plan without unnecessary prompts, pausing only at Phase Checkpoints, irreversible/external actions, or architectural deviations.
5. **Empirical Engineering & Minimal Diffs:**
   - **Model the Domain First:** Define types, state transitions, and boundary parsers before writing control flow.
   - **Reproduce & Test Behavior:** Reproduce defects on the matching runtime surface first. Write behavioral checks asserting caller-observable outcomes rather than mock-heavy implementation wiring.
   - **Laziness Protocol:** Prefer deletion and the smallest diff that solves the problem. Keep zero narrating comments.
   - **Prove It Works:** Record actual build and test outputs, exit codes, and commit state in the track verification log rather than relying on compilation alone.
6. **Non-Interactive & CI-Aware Execution:** Use `CI=true` and non-interactive flags for test runners and linters so checks terminate deterministically.

---

## Standard Task Lifecycle

1. **Verify Gate Lock:** Confirm the active specification and plan are approved and unmodified since lock.
2. **Select Next Pending Task (`[ ] -> [~]`):** Mark the next sequential task in `plan.md` as in-progress (`[~]`).
3. **Domain & Boundary Check:** Confirm types, invariants, and boundary validations before editing logic.
4. **Empirical Red Phase:**
   - **Bug Fix:** Reproduce the failure on the matching surface, trace the root cause with runtime evidence, and capture a failing regression check.
   - **Feature / Refactor:** Write a focused failing behavioral check (or deterministic verification script when unit tests would only exercise mocks) and record the failing run.
5. **Minimal Green & Hygiene Phase:**
   - Implement the smallest code change needed to satisfy the check, strip superfluous comments and AI filler, and run the verification suite until exit code `0` is recorded.
6. **Atomic Commit & Audit Trail:**
   - Commit the code change using Conventional Commits (`<type>(<scope>): <imperative subject>`). Do not rebase commits already recorded in `plan.md` or the decision trail.
   - Attach a concise `git notes` summary to the commit and append a decision/verification row to the append-only `decisions.tsv` trail.
   - Mark the task `[x] <short_sha>` in `plan.md` and commit the plan update.

---

## Phase Completion & Checkpointing Protocol

Immediately after completing the final task of a phase in `plan.md`:

1. **Verify Phase Scope Coverage:** List code files changed since the phase start (`git diff --name-only <previous_checkpoint_or_base_sha> HEAD`) and confirm behavioral test coverage exists for modified logic.
2. **Run Full Automated Verification Suite:** Announce and run the non-interactive build, lint, and test command (`CI=true ...`), recording the passing exit code `0`. If tests fail twice after targeted debugging, stop and report the root cause to the developer.
3. **Present Actionable Manual Verification Steps:** Provide concrete commands, URLs, or API requests with expected observable outputs derived from `product.md` and `spec.md`, and pause for developer confirmation.
4. **Synchronize Subsystem Design & Stamp Checkpoint:** If the completed phase added or modified cross-directory architecture, domain data shapes, or settled architectural trade-offs recorded in `decisions.tsv`, upsert those verified facts into `docs/designs/<subsystem>.md` (`Status: Active`) and `docs/designs/README.md`. Record `[checkpoint: <short_sha>]` on the completed phase heading in `plan.md`, attach the verification summary via `git notes`, and commit.

---

## Quality Gates

Before marking any task or phase complete:
- [ ] Behavioral and regression tests pass (`exit 0` captured in verification log)
- [ ] Code adheres to `code_styleguides/` and `security-policy.md`
- [ ] Public interfaces, invariants, and side effects match directory `README.md` contracts, and cross-directory architecture/decisions are current in `docs/designs/`
- [ ] Type checks and linters pass with zero new suppressions
- [ ] Decision trail (`decisions.tsv`) and `git notes` are updated

---

## Development Commands

*Adapt this section during `setup` to match the repository's actual toolchain:*

```bash
# Install / Setup:
# Build / Typecheck:
# Lint:
# Test (CI mode): CI=true <test_command>
```

---

## Commit Guidelines

Use Conventional Commits without trailing periods:
- `feat(<scope>): ...`
- `fix(<scope>): ...`
- `refactor(<scope>): ...`
- `perf(<scope>): ...`
- `test(<scope>): ...`
- `docs(<scope>): ...`
- `chore(<scope>): ...`
