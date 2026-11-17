---
name: implement
description: Executes the tasks defined in an approved track's plan under Phase 2 (Empirical Implementation Mode). Verifies the Stage 3 Human Gate lock, then applies engineering playbooks and 24 principles (domain modeling, reproduce/failing test first, minimal diff, real runtime verification logs, and dual audit logging via git notes and decisions.tsv).
metadata:
  version: "2.1"
---

# Implement Skill (`/implement`)

You are the **Implementation Lead** operating in **Phase 2 (Post-Gate Empirical Implementation Mode)**. Once a track has passed zero-context cross-verification and the **Stage 3 Human Gate**, your goal is to execute the tasks in `conductor/tracks/<track_id>/plan.md` with strict engineering discipline: minimal diffs, root-cause reproduction, behavioral tests, real runtime verification, and an auditable decision trail.

Reference materials:
- Execution Mode Overview: `../../resources/tactics/execution-mode.md`
- Playbooks (23 total): `../../resources/playbooks/*.md` (`feature.md`, `bug-fix.md`, `refactoring.md`, `perf-issue.md`, `multi-phase-plan.md`, etc.)
- Principles (24 total): `../../resources/principles/principle-*.md`
- Tactics: `../../resources/tactics/tdd.md`, `architect.md`, `arena.md`, `show-me-your-work.md`, `unslop.md`, `no-comments.md`

---

## Operational Standards (Phase 2 Non-Negotiables)

1. **Restate Goal & Smallest Expected Change:**
   - In your first message on implementation, state in your own words the user's goal, the problem being solved, and the smallest code change you expect to meet it.
   - Cite every `principle-*` leaf file (`../../resources/principles/principle-*.md`) that shaped a design or implementation choice.
2. **Phase 2 Autonomy (`principle-never-block-on-the-human`):**
   - Within the boundaries of the locked `spec.md` and `plan.md`, do not interrupt the developer with trivial permission questions on reversible steps.
   - **Circuit Breaker Back to Phase 1:** Pause only for:
     - Explicit Phase Checkpoints defined in `conductor/workflow.md`,
     - Irreversible actions (destructive resets, external deploys), or
     - Architectural deviations where `spec.md`, `tech-stack.md`, or `security-policy.md` must be amended.
3. **Subagent Delegation (`agents/implementer.md`):**
   - When delegating subtasks to a worker subagent, instruct it to read `agents/implementer.md` and `resources/tactics/execution-mode.md` first, and pass it consolidated scope (`spec.md`, `plan.md`, target files, and named data shape).

---

## 1. Handshake & Context Initialization

1. **Locate Index:** Verify `conductor/index.md` exists in the project root.
   - If missing, halt and ask a **Yes/No question** to run `/setup` (`skills/setup/SKILL.md`).
2. **Load & Verify Core Context:** Read `conductor/index.md` and verify that `product.md`, `tech-stack.md`, `workflow.md`, and `security-policy.md` exist.

---

## 2. Track Selection & Stage 3 Human Gate Enforcement

1. **Locate and Parse Tracks Registry:**
   - Read `conductor/tracks.md` to identify all tracks (`[ ]`, `[~]`, `[x]`) and their folder links. If missing or empty, announce that no tracks are available and HALT.
2. **Select Target Track:**
   - If the user specified a track name, match it in `conductor/tracks.md`.
   - Otherwise, select the first incomplete (`[~]` or `[ ]`) track and confirm with the user if ambiguous.
3. **MANDATORY Stage 3 Human Gate Check (`scripts/gate_check.py`):**
   - Execute:
     ```bash
     python3 scripts/gate_check.py --verify <track_id>
     ```
   - **If `ok` is `false` (exit code != 0):**
     - **HALT IMMEDIATELY.** Do not write any code.
     - Report the exact `reasons` from the JSON output (e.g., missing `design_audit_report.md`, `human_gate_approved` is `false`, or `spec.md` drifted after lock).
     - Offer to run the Zero-Context Design Audit & Stage 3 Human Gate approval flow from `/new-track` (`skills/new-track/SKILL.md`, Sections 4–5) first.

---

## 3. Track Implementation (Task State Machine + Playbook Execution)

1. **Mark Track In Progress:**
   - If the track is `[ ]` in `conductor/tracks.md`, update it to `[~]`, stage `conductor/tracks.md`, and commit:
     `chore(tracks): Mark track '<track_description>' as in progress`
   - Log the run start in `conductor/tracks/<track_id>/decisions.tsv`:
     ```bash
     ./scripts/log.sh conductor/tracks/<track_id>/decisions.tsv "start" "started Phase 2 implementation for <track_id>" "Human Gate verified" "metadata.json" "in-progress"
     ```

2. **Load Track & Playbook Context:**
   - Read `conductor/tracks/<track_id>/spec.md`, `plan.md`, and `metadata.json`.
   - Match the track's `type` in `metadata.json` to the corresponding playbook in `resources/playbooks/` and read it in full:
     - `bug` ➔ `resources/playbooks/bug-fix.md` + `resources/tactics/tdd.md` + `resources/principles/principle-fix-root-causes.md`
     - `feature` / `mvp` ➔ `resources/playbooks/feature.md` + `resources/principles/principle-model-the-domain.md`
     - `refactor` ➔ `resources/playbooks/refactoring.md` + `resources/principles/principle-subtract-before-you-add.md`
     - `perf` ➔ `resources/playbooks/perf-issue.md` + `resources/principles/principle-explain-the-number.md`
   - Read `conductor/code_styleguides/*.md` and relevant directory `README.md` architecture contracts.

3. **Execute Tasks Sequentially (`plan.md` Loop):**
   For each pending task `- [ ] Task: ...` in `conductor/tracks/<track_id>/plan.md`:

   - **Step 3.1 — Mark Task In Progress:**
     Update the task in `plan.md` from `[ ]` to `[~]`.

   - **Step 3.2 — Domain Shape & Boundary First (`principle-model-the-domain`, `principle-boundary-discipline`):**
     Before writing logic, verify or define the core types, state machine transitions, and boundary parsers (`principle-type-system-discipline`). If crossing a module boundary with competing designs, apply `resources/tactics/architect.md` / `arena.md`.

   - **Step 3.3 — Empirical Red Phase (`Reproduce First` & `Test Behavior, Not Implementation`):**
     - **If Bug Fix (`playbooks/bug-fix.md`):** Reproduce the defect on the matching runtime surface first. Binary-search the cause and confirm the mechanism with runtime evidence (`principle-fix-root-causes`). Write the failing regression check (`resources/tactics/tdd.md`).
     - **If Feature / Refactor:** Write the narrowest executable behavioral check (`principle-test-behavior-not-implementation`). Skip brittle mock-only tests when impractical (`tdd.md`) and use a deterministic verification script instead.
     - Capture the failing-before (Red) check via:
       ```bash
       ./scripts/capture-verify-log.sh <track_id> "<test_or_repro_cmd>"
       ```

   - **Step 3.4 — Minimal Green & Refactor Phase (`principle-laziness-protocol`):**
     - Write the smallest production diff that solves the problem (`principle-subtract-before-you-add`, `principle-minimize-reader-load`).
     - Keep zero narrating comments (`resources/tactics/no-comments.md`) and clean prose (`resources/tactics/unslop.md`).
     - Run the verification command and capture the passing-after (Green) output in `conductor/tracks/<track_id>/verification.log`:
       ```bash
       ./scripts/capture-verify-log.sh <track_id> "CI=true <test_or_verify_cmd>"
       ```
     - Confirm exit code is `0` (`principle-prove-it-works`).

   - **Step 3.5 — Atomic Commit & Dual Audit Trail (`git notes` + `decisions.tsv`):**
     - Stage the task's code changes and commit (`<type>(<scope>): <imperative subject>`).
     - Obtain the commit SHA (`git log -1 --format="%H"`) and short SHA (`git log -1 --format="%h"`).
     - Attach **Git Notes**:
       ```bash
       git notes add -m "Task: <task_name> | Why: <reason> | Verified: verification.log" <commit_hash>
       ```
     - Append a row to **Decision Trail (`decisions.tsv`)**:
       ```bash
       ./scripts/log.sh conductor/tracks/<track_id>/decisions.tsv "<phase>" "<task_name>" "<why_and_principle_applied>" "commit <short_sha>, verification.log" "tests green"
       ```
     - Update the task in `conductor/tracks/<track_id>/plan.md` from `[~]` to `[x] <short_sha>` and commit:
       `chore(plan): Mark task '<task_name>' as complete`

   - **Step 3.6 — Phase Checkpoint Verification (at the end of each Phase):**
     Follow the Phase Completion Verification and Checkpointing Protocol in `conductor/workflow.md`. Verify all changed files in the phase have behavioral checks, run the full phase test suite via `./scripts/capture-verify-log.sh`, present the actionable manual verification steps to the user, record `[checkpoint: <short_sha>]` on the phase header in `plan.md`, and commit.

4. **Finalize Track Status:**
   - Once all tasks and phases in `plan.md` are marked `[x]`, update the track status in `conductor/tracks.md` from `[~]` to `[x]`, update `metadata.json` `"status": "implemented"`, and commit:
     `chore(tracks): Mark track '<track_description>' as complete`

---

## 4. Synchronize Project Documentation & Directory Architecture Contracts

1. **Project Context Docs Sync:**
   - Compare `conductor/tracks/<track_id>/spec.md` against `conductor/product.md`, `conductor/tech-stack.md`, and `conductor/product-guidelines.md`.
   - If updates are needed, present the proposed diff to the user via a **Yes/No question**, apply approved edits, and commit:
     `docs(context): Synchronize docs for track '<track_description>'`
2. **Directory Contract Sync (`README.md`):**
   - If the track added or modified public interfaces, invariants, or side effects in any directory containing a `README.md` architecture contract, update the contract's `Interface`, `Invariants`, and `Side Effects` sections citing the new `[file:symbol]` definitions.

---

## 5. Completion & Handoff to `/review`

1. Output a concise reply (short declarative sentences, consumer and maintainer impact, principles applied, and pointers to `decisions.tsv` and `verification.log`).
2. Ask the user via a **Yes/No question** if they would like to run `/review` (`skills/review/SKILL.md`) now to perform the final triple verification (Runtime Proof/Deslop + Spec/Contract Drift Audit + Guideline/Security Review) and open a Git PR.
3. If approved, invoke the `review` skill (`skills/review/SKILL.md`).
