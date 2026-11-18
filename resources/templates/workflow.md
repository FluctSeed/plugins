# Project Workflow Standard (`workflow.md`)

## Guiding Principles

1. **The Plan is the Source of Truth:** All work is tracked in `conductor/tracks/<track_id>/plan.md` and registered in `conductor/tracks.md`.
2. **The Tech Stack & Security Policy are Deliberate:** Changes to the technology stack or security boundaries must be documented in `conductor/tech-stack.md` and `conductor/security-policy.md` before implementation.
3. **Cognitive Separation (Draft in Context, Audit with Fresh Context):**
   - Never jump directly from a chat prompt into production code.
   - The primary session drafts `spec.md` and `plan.md`, then spawns zero-context reviewer subagents to adversarially audit both documents against `conductor/` standards and codebase contracts (`README.md`) before human approval.
4. **Two-Phase Autonomy:**
   - **Phase 1 (Pre-Gate: `setup`, `brainstorm`, `new-track`, Stage 3 Human Gate):** Write zero production code. Present architectural trade-offs without flattery (`No Glazing`, `Critique First`) so the human developer makes the final design call (`Author Decides Architecture`). Resolve empirical codebase questions yourself using `how`/`why` before asking.
   - **Phase 2 (Post-Gate: `/implement`, `/review`):** Once the human developer approves the track at the Stage 3 Human Gate (`metadata.json` `"human_gate_approved": true`), execute tasks with full engineering autonomy (`Never Block on the Human` for reversible steps) unless an architectural deviation requires returning to Phase 1.
5. **Empirical Engineering & Minimal Diffs:**
   - **Model the Domain First:** Define data shapes, types, and state boundaries before writing logic.
   - **Reproduce & Test Behavior:** For bugs, reproduce on the matching runtime surface and trace root causes (`Fix Root Causes`) before touching production code. For features, write behavioral tests (`Test Behavior, Not Implementation`), avoiding brittle mock-only tests.
   - **Laziness Protocol:** Bias toward deletion and the smallest diff that solves the problem.
   - **Prove It Works:** Never rely on "it compiles." Capture real test/build stdout/stderr and exit codes in `verification.log`.
6. **Non-Interactive & CI-Aware:** Prefer non-interactive commands. Use `CI=true` for watch-mode tools (tests, linters) to ensure deterministic single execution.

---

## Task Workflow

All tasks in `conductor/tracks/<track_id>/plan.md` follow this strict lifecycle during `/implement`:

### Standard Task Workflow

1. **Verify Human Gate Lock:**
   - Ensure `python3 scripts/gate_check.py --verify <track_id>` passes before executing any task.

2. **Select Task & Mark In Progress:**
   - Choose the next pending task `[ ]` from `plan.md` in sequential order.
   - Edit `plan.md` and change the task marker from `[ ]` to `[~]`.

3. **Domain Shape & Boundary Check (`Foundational Thinking` & `Model the Domain`):**
   - Before writing logic, name the core data structures, state machine transitions, or boundary schemas (`Boundary Discipline`, `Type System Discipline`).
   - If the change crosses a module/function boundary with multiple valid shapes, run `architect` / `arena` exploration first.

4. **Empirical Red Phase (`tdd` & `Fix Root Causes`):**
   - **For Bug Fixes (`playbooks/bug-fix.md`):**
     - Reproduce the defect on the matching runtime surface first.
     - Binary-search the root cause using runtime evidence (`Fix Root Causes`).
     - Write a focused failing regression test or reproduction script and capture the verbatim failing output.
   - **For Features / Refactorings (`playbooks/feature.md`, `playbooks/refactoring.md`):**
     - Write the narrowest executable behavioral test that asserts user-observable behavior (`Test Behavior, Not Implementation`).
     - Run the check via `./scripts/capture-verify-log.sh <track_id> "<test_cmd>"` and confirm it fails as expected (Red state). If a unit test would only test mocks, use a deterministic verification script instead.

5. **Implement Minimal Diff to Pass (Green Phase — `Laziness Protocol`):**
   - Write the smallest, cleanest production change necessary to satisfy the behavior (`Subtract Before You Add`, `Minimize Reader Load`).
   - Do not add speculative guards, dead compatibility layers, or narrating comments (`no-comments`).
   - Run `./scripts/capture-verify-log.sh <track_id> "<test_cmd>"` and confirm all checks pass (Green state).

6. **Refactor & Hygiene Pass:**
   - Collapse one-caller wrappers, shrink mutable scope, and strip AI slop (`unslop`).
   - Re-run verification to confirm green status.

7. **Document Deviations (Circuit Breaker to Phase 1):**
   - If implementation requires diverging from `tech-stack.md`, `security-policy.md`, or an invariant in `spec.md`:
     - **STOP** implementation immediately.
     - Present the evidence and trade-offs to the developer.
     - Update `spec.md` / `tech-stack.md` and re-lock the Human Gate (`scripts/gate_check.py --approve <track_id>`) before resuming.

8. **Commit Code Changes (`Sequence Verifiable Units`):**
   - Stage all code changes related to the task.
   - Commit with a Conventional Commit message (`<type>(<scope>): <imperative subject>`).

9. **Dual Audit Trail (`git notes` + `decisions.tsv`):**
   - **Step 9.1 — Git Notes:**
     - Obtain the commit hash via `git log -1 --format="%H"`.
     - Attach task summary via `git notes add -m "<Task Name, Summary, Modified Files, Core Why>" <commit_hash>`.
   - **Step 9.2 — Decision Trail (`decisions.tsv`):**
     - Append a single-line row to `conductor/tracks/<track_id>/decisions.tsv` using `./scripts/log.sh`:
       `./scripts/log.sh conductor/tracks/<track_id>/decisions.tsv "<phase>" "<decision>" "<why>" "commit <short_sha>, verification.log" "tests green"`

10. **Record Task Commit SHA in Plan:**
    - Update the task in `plan.md` from `[~]` to `[x] <short_sha>` (first 7 characters of the commit hash).
    - Stage `plan.md` and commit with message `chore(plan): Mark task '<task_name>' as complete`.

---

### Phase Completion Verification and Checkpointing Protocol

**Trigger:** Executed immediately after a task is completed that concludes a phase in `plan.md`.

1. **Announce Protocol Start:** Inform the user that the phase is complete and checkpoint verification has begun.
2. **Verify Changed Files & Behavioral Coverage:**
   - Identify files changed since the previous phase checkpoint via `git diff --name-only <previous_checkpoint_or_base_sha> HEAD`.
   - Ensure every modified production code module has behavioral test coverage or an executable verification script.
3. **Execute Automated Verification with Proactive Debugging (`Prove It Works`):**
   - Announce and execute the test suite via `./scripts/capture-verify-log.sh <track_id> "CI=true <test_cmd>"`.
   - If tests fail, debug using root-cause tracing (maximum 2 fix attempts before halting to report evidence and ask the user).
4. **Present Actionable Manual Verification Plan & Await Confirmation:**
   - Provide step-by-step verification commands and expected outcomes grounded in `product.md` and `spec.md`.
   - Pause and await explicit developer confirmation.
5. **Attach Phase Verification Report & Checkpoint SHA:**
   - Attach the verification report to the phase's last functional commit via `git notes`.
   - Append `[checkpoint: <short_sha>]` to the phase heading in `plan.md` and commit with message `chore(plan): Mark phase '<PHASE NAME>' as complete`.

---

## Quality Gates (Pre-Review Checklist)

Before marking a track ready for `/review`, verify:

- [ ] Stage 3 Human Gate was approved and locked (`metadata.json`).
- [ ] All tasks in `plan.md` are marked `[x] <sha>`.
- [ ] Real build/test execution output is recorded in `conductor/tracks/<track_id>/verification.log` with exit code `0`.
- [ ] Every key engineering decision and verification pointer is logged in `conductor/tracks/<track_id>/decisions.tsv`.
- [ ] Zero narrating comments (`no-comments`) and zero AI slop prose (`unslop`).
- [ ] Code strictly complies with `conductor/code_styleguides/*.md` and `conductor/security-policy.md`.
- [ ] Directory architecture contracts (`README.md`) have zero drift against the implemented code.

---

## Commit & PR Guidelines (`opening-a-pr`)

### Commit Message Format
```text
<type>(<scope>): <short imperative subject naming the real symbol>
```
Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`.

### Pull Request Briefing Structure (`opening-a-pr.md`)
Keep PR descriptions under ~40 lines as a 1-minute engineering briefing:
- `## Why`: Problem and approach in 1–3 declarative sentences.
- `## What changed`: 1–3 bullets naming the symbols/paths that carry the change.
- `## Scope`: What is covered and what is deliberately left out.
- `## Tradeoffs`: Rejected alternatives a reviewer would ask about.
- `## Blast Radius`: 1–2 sentences on affected callers/surfaces and safety evidence.
- `## Verification`: Real commands run and verbatim outcomes (referencing `verification.log` and `decisions.tsv`).
