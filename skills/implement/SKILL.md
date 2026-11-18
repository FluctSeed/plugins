---
name: implement
description: Executes the tasks defined in an approved track's plan under Phase 2 (Empirical Implementation Mode). Verifies the Stage 3 Human Gate lock, then applies engineering playbooks and 24 principles (domain modeling, reproduce/failing test first, minimal diff, real runtime verification logs, and dual audit logging via git notes and decisions.tsv).
metadata:
  version: "0.1.0"
---

# Implement Skill (`implement`)

> [!NOTE]
> **Plugin Root & Governance Rules (`${PLUGIN_ROOT}`)**
> - `${PLUGIN_ROOT}` is the root directory of this plugin (`${CLAUDE_PLUGIN_ROOT}` if expanded by your harness, otherwise two directories above this `SKILL.md` file). Resolve `${PLUGIN_ROOT}` to its absolute path before calling file or shell tools.
> - If your harness does not preload plugin `rules/*.md` automatically (Claude Code and Codex CLI), read `${PLUGIN_ROOT}/rules/lifecycle-workflow.md` and `${PLUGIN_ROOT}/rules/implementation-discipline.md` first.

You are the **Implementation Lead** operating in **Phase 2 (Post-Gate Empirical Implementation Mode)**. Verify the Stage 3 Human Gate lock, then execute tasks in `<TRACK_DIR>/plan.md` with minimal diffs, root-cause reproduction, behavioral tests, real runtime verification in `<TRACK_DIR>/verification.log`, and an append-only decision trail in `<TRACK_DIR>/decisions.tsv`.

Reference materials:
- Execution Mode Overview: `${PLUGIN_ROOT}/resources/tactics/execution-mode.md`
- Playbooks (23 total): `${PLUGIN_ROOT}/resources/playbooks/*.md` (`feature.md`, `bug-fix.md`, `refactoring.md`, `perf-issue.md`, `multi-phase-plan.md`, etc.)
- Principles (24 total): `${PLUGIN_ROOT}/resources/principles/principle-*.md`
- Tactics (29 total): `${PLUGIN_ROOT}/resources/tactics/tdd.md`, `architect.md`, `arena.md`, `benchmark-checklist.md`, `verification-harness.md`, `formal-verification.md`, `show-me-your-work.md`, `unslop.md`, `no-comments.md`, `teach.md`, `recall.md`

---

## Operational Standards (Phase 2 Non-Negotiables)

1. **Restate Goal & Smallest Expected Change:**
   - In your first message, state in your own words the user's goal, the problem being solved, and the smallest code change expected to meet it. Cite every `principle-*` leaf file (`${PLUGIN_ROOT}/resources/principles/principle-*.md`) shaping your choices.
2. **Phase 2 Autonomy (`principle-never-block-on-the-human`):**
   - Within the boundaries of locked `spec.md` and `plan.md`, execute reversible code and test steps without interrupting the human.
   - **Circuit Breaker Back to Phase 1:** Pause immediately for:
     - Phase Checkpoints defined in `workflow.md`,
     - External or irreversible side effects (external deploys, destructive git resets, external chat/ticket writes), or
     - Any required change to `spec.md`, `plan.md` task structure, `tech-stack.md`, or `security-policy.md`.
3. **Subagent Delegation (`${PLUGIN_ROOT}/agents/implementer.md`):**
   - When delegating scoped subtasks (`invoke_subagent` `implementer` in Antigravity, `Agent` `fluctseed:implementer` in Claude Code, or `spawn_agent` reading `${PLUGIN_ROOT}/agents/implementer.md` in Codex CLI), pass the resolved path to `${PLUGIN_ROOT}/resources/tactics/execution-mode.md` plus consolidated scope (`spec.md`, `plan.md` slice, target files, and named domain data shape).

---

## 1. Handshake, Track Selection & Stage 3 Human Gate Enforcement

1. **Resolve `<CONDUCTOR_DIR>` & `<TRACK_DIR>`:**
   - Discover conductors via `python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py" --list-conductors` (preferring `./conductor` in the current working directory if present, or the module/track specified by the user).
   - Parse `<CONDUCTOR_DIR>/tracks.md` to select the requested track or the first incomplete (`[~]` or `[ ]`) track. Set `<TRACK_DIR>` to `<CONDUCTOR_DIR>/tracks/<track_id>`.
2. **Mandatory Stage 3 Human Gate Verification (`gate_check.py`):**
   ```bash
   python3 "${PLUGIN_ROOT}/scripts/gate_check.py" --verify "<TRACK_DIR>" --conductor-dir "<CONDUCTOR_DIR>"
   ```
   - **If exit code != 0 (`"ok": false`):**
     - **Halt immediately.** Write zero production code.
     - Report the exact `reasons` from stdout (`design_audit_report.md` missing, `human_gate_approved` false, or `spec.md` / `plan.md` structure modified after lock) and offer to run `${PLUGIN_ROOT}/skills/new-track/SKILL.md` Sections 4 and 5.

---

## 2. Track Implementation Loop

1. **Mark Track In Progress & Record Base Commit:**
   - Ensure `<TRACK_DIR>/metadata.json` records `"base_sha"` (`git rev-parse HEAD` prior to implementation commits if not already set).
   - If the track is `[ ]` in `<CONDUCTOR_DIR>/tracks.md`, update it to `[~]`, commit `chore(tracks): mark track '<track_id>' as in progress`, and log run start:
     ```bash
     "${PLUGIN_ROOT}/scripts/log.sh" "<TRACK_DIR>/decisions.tsv" "start" "started Phase 2 implementation for <track_id>" "Human Gate verified" "metadata.json" "in-progress"
     ```

2. **Load Context & Matching Playbook:**
   - Read `<TRACK_DIR>/spec.md`, `<TRACK_DIR>/plan.md`, `<TRACK_DIR>/metadata.json`, active styleguides, `security-policy.md`, and affected directory `README.md` contracts (`python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py" --conductor-dir "<CONDUCTOR_DIR>"`).
   - Read the playbook and verification tactics matching `metadata.json` `"type"` and scope:
     - `bug` -> `${PLUGIN_ROOT}/resources/playbooks/bug-fix.md` + `tactics/tdd.md` + `principles/principle-fix-root-causes.md`
     - `feature` / `mvp` -> `${PLUGIN_ROOT}/resources/playbooks/feature.md` + `principles/principle-model-the-domain.md` (+ `tactics/verification-harness.md` when the primary app surface lacks scripted end-to-end verification)
     - `refactor` -> `${PLUGIN_ROOT}/resources/playbooks/refactoring.md` + `principles/principle-subtract-before-you-add.md`
     - `perf` -> `${PLUGIN_ROOT}/resources/playbooks/perf-issue.md` + `principles/principle-explain-the-number.md` + `tactics/benchmark-checklist.md`
     - Concurrency, retry loops, state machines, or parsers -> `${PLUGIN_ROOT}/resources/tactics/formal-verification.md`

3. **Sequential Task State Machine (`[ ] -> [~] -> [x]`):**
   For each pending task `- [ ] Task: ...` in `<TRACK_DIR>/plan.md` (preserving exact task wording so `plan_structure_sha256` remains intact):
   - **3.1 Mark In Progress:** Change `[ ]` to `[~]` in `<TRACK_DIR>/plan.md`.
   - **3.2 Domain Shape & Boundary First:** Define types, state transitions, and boundary validators (`principle-model-the-domain`, `principle-boundary-discipline`).
   - **3.3 Empirical Red Check:** Reproduce the bug on the real surface or write a failing behavioral check (`principle-test-behavior-not-implementation`), recording output via:
     ```bash
     "${PLUGIN_ROOT}/scripts/capture-verify-log.sh" "<TRACK_DIR>" "<repro_or_test_cmd>"
     ```
   - **3.4 Minimal Green & Hygiene Pass:** Write the smallest diff (`principle-laziness-protocol`, `no-comments.md`, `unslop.md`) and prove passing runtime verification (exit code `0`):
     ```bash
     "${PLUGIN_ROOT}/scripts/capture-verify-log.sh" "<TRACK_DIR>" "CI=true <test_and_build_cmd>"
     ```
   - **3.5 Atomic Commit & Audit Trail:**
     - Commit code changes (`<type>(<scope>): <imperative subject>`), Do NOT rebase commits already recorded in `plan.md` or `decisions.tsv`.
     - Attach local git note (`git notes add -f -m "Task: <task_name> | Verified: <TRACK_DIR>/verification.log" HEAD`) and append to `decisions.tsv`:
       ```bash
       "${PLUGIN_ROOT}/scripts/log.sh" "<TRACK_DIR>/decisions.tsv" "<phase>" "<task_name>" "<why_and_principle>" "commit <short_sha>, verification.log" "tests green"
       ```
     - Update the task checkbox in `<TRACK_DIR>/plan.md` from `[~]` to `[x] <short_sha>` and commit `chore(plan): mark task '<task_name>' complete`.
   - **3.6 Phase Checkpoint & Living Design Sync:** At the end of each phase, run the full verification suite via `capture-verify-log.sh`. Once verification exits `0`, if the phase added or altered subsystem architecture, domain data shapes, or settled architectural trade-offs recorded in `<TRACK_DIR>/decisions.tsv`, upsert those verified facts into `<MODULE_ROOT>/docs/designs/<subsystem>.md` (`Status: Active`, where `<MODULE_ROOT>` is the parent of `<CONDUCTOR_DIR>`) and `<MODULE_ROOT>/docs/designs/README.md`, then follow `workflow.md` checkpoint rules.

4. **Finalize Track Status & Synchronize Permanent Docs:**
   - Mark the track `[x]` in `<CONDUCTOR_DIR>/tracks.md` and set `"status": "implemented"` in `<TRACK_DIR>/metadata.json`.
   - **Synchronize Living Subsystem Design (`<MODULE_ROOT>/docs/designs/<subsystem>.md`):**
     - Unless the track is a pure `bug`/`chore` with zero architectural or decision changes, always create or upsert `<MODULE_ROOT>/docs/designs/<subsystem>.md` (`Status: Active`) and `<MODULE_ROOT>/docs/designs/README.md` from `<TRACK_DIR>/spec.md` and `<TRACK_DIR>/decisions.tsv`:
       - `## Overview & Why`: Subsystem purpose and problem solved.
       - `## Architecture & Domain Data Shape`: Cross-directory flows, protocols, and state transitions (keep single-directory function contracts in code `**/README.md` without duplicating every signature).
       - `## Key Decisions & Alternatives Rejected`: Cumulative architectural decisions, implementation pivots from `decisions.tsv`, and rejected alternatives with technical rationale.
     - Commit (`docs(designs): synchronize '<subsystem>' living design for '<track_id>'`).
   - Update any affected directory `README.md` architecture contracts (`Interface`, `Invariants`, `Side Effects`).
   - **Synchronize Permanent Project Context (`<CONDUCTOR_DIR>/`):**
     - Compare `<TRACK_DIR>/spec.md` against `<CONDUCTOR_DIR>/product.md`, `<CONDUCTOR_DIR>/tech-stack.md`, and `<CONDUCTOR_DIR>/product-guidelines.md` (when present locally):
       - **`product.md`:** Propose updates if the completed track materially alters user-facing capabilities or domain workflows.
       - **`tech-stack.md`:** Propose updates if approved libraries, storage engines, or runtimes were added or removed.
       - **`product-guidelines.md` (High Sensitivity):** Propose updates only for deliberate brand, UX, or voice shifts, accompanied by an explicit sensitivity warning.
     - Present a concise summary of proposed permanent-context edits and ask a single Yes/No confirmation question before modifying `product.md`, `tech-stack.md`, or `product-guidelines.md`.
     - **Permanent-Context Purity Rule:** Distill timeless domain and stack facts only. **Never** add references or links to `tracks/<track_id>/` or `tracks.md` inside `index.md`, `product.md`, `product-guidelines.md`, `tech-stack.md`, `security-policy.md`, or `workflow.md`.
   - Commit synchronized state (`docs(conductor): synchronize project context for '<track_id>'`).

---

## 3. Completion & Handoff to `review`

Summarize changed files, principles applied, and pointers to `<TRACK_DIR>/decisions.tsv` and `<TRACK_DIR>/verification.log`, then ask a single Yes/No question offering to run `${PLUGIN_ROOT}/skills/review/SKILL.md`.
