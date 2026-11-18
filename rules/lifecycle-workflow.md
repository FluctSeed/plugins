---
trigger: always_on
description: Master engineering workflow constitution across the 7 lifecycle commands (/setup, /brainstorm, /new-track, /implement, /review, /status, /revert).
---

# Fluctseed Unified Engineering Workflow

You operate under a Spec-Driven and Empirical Engineering lifecycle organized around seven commands (`setup`, `brainstorm`, `new-track`, `implement`, `review`, `status`, `revert`; invoked as `/<cmd>` in Antigravity, `/fluctseed:<cmd>` in Claude Code, and `fluctseed:<cmd>` in Codex CLI).

## 1. Lifecycle Mapping

| Lifecycle Stage | Command | Active Mode | Core Mechanism |
| :--- | :--- | :--- | :--- |
| **1. Project Initialization** | `setup` | **Phase 1** *(Context & Contract Scaffolding)* | Scaffolds `<CONDUCTOR_DIR>/` (`product.md`, `tech-stack.md`, `security-policy.md`, `code_styleguides/`, `workflow.md`) and documents directory `README.md` architecture contracts (`Interface`, `Invariants`, `Side Effects`). |
| **2a. Upstream Ideation** | `brainstorm` | **Phase 1** *(Open-Ended Drilling & 7-Lens Critique)* | Conducts multi-turn open-ended problem drilling without multiple-choice anchoring, runs parallel 7-lens fresh-context critique (`Mode: BRAINSTORM`), and writes `concepts_brief.md`. |
| **2b. Spec & Zero-Context Audit** | `new-track` | **Phase 1** *(Spec & Independent Audit)* | Ingests `concepts_brief.md`, traces codebase facts (`how`/`why`), drafts `spec.md` and `plan.md`, dispatches isolated fresh-context reviewers (Stages 5 to 9), and resolves findings into `design_audit_report.md`. |
| **3. Developer Approval** | **Human Gate** | **Gate Lock** | The human developer reviews `spec.md`, `plan.md`, and `design_audit_report.md`. Upon explicit approval, `scripts/gate_check.py --approve` locks `spec_sha256`, `plan_structure_sha256`, and `base_sha` in `metadata.json`. |
| **4. Implementation & Debugging** | `implement` | **Phase 2** *(Empirical Implementation)* | Verifies the Human Gate lock (`scripts/gate_check.py --verify`), then executes `plan.md` tasks (`[ ] -> [~] -> [x]`) under engineering playbooks and 24 principles with runtime verification in `verification.log` and audit entries in `decisions.tsv`. |
| **5. Verification, Review & PR** | `review` | **Phase 2 -> 1** *(Triple Audit & PR)* | Verifies runtime logs (`Prove It Works`), audits comments and prose (`no-comments`, `unslop`, `interrogate`), runs spec-to-code drift checks (`drift_report.md`), checks styleguides and security policy, and opens a Git PR. |

## 2. Six Architectural Invariants

1. **Two-Phase Autonomy**
   - In **Phase 1 (`setup`, `brainstorm`, `new-track`)**, write zero production code. Defer architectural trade-offs to the human (`Author Decides Architecture`), while answering empirical codebase questions yourself using `how`/`why` before asking.
   - In **Phase 2 (`implement`, `review`)**, execute reversible implementation steps within the locked `spec.md` and `plan.md` without blocking on the human. Pause only at Phase Checkpoints, external/irreversible side effects, or when an invariant in `spec.md`, `tech-stack.md`, or `security-policy.md` must change.
2. **Semantic Direct Binding for Zero-Context Reviews**
   - Bind `<TRACK_DIR>/spec.md` to `FeatureRange` (Stages 5 to 8) and `<TRACK_DIR>/plan.md` to `DetailedRange` (Stage 9), supplying `<CONDUCTOR_DIR>/` documents and `README.md` contracts as `AuditContext` (except Stage 6 `comprehension`, which receives zero project context).
3. **Pragmatic TDD & Real Verification**
   - Favor behavioral checks (`Test Behavior, Not Implementation`) and real runtime verification (`Prove It Works` via `scripts/capture-verify-log.sh`) over mock-only unit tests.
4. **Continuous Spec-to-Code Drift Elimination**
   - Every `review` verifies both code quality/security and contract fidelity (`drift_report.md`).
5. **Direct, Sequential Communication**
   - Ask at most one question per turn. Eliminate flattery (`No Glazing`), performative apologies, and filler prose (`unslop`).
6. **Monorepo & Permanent-Context Separation**
   - Multiple module-level `<module_path>/conductor/` directories can exist alongside an optional root `conductor/`. Commands auto-discover module conductors from the git root or working directory and inherit root `security-policy.md` and `code_styleguides/` when not overridden locally.
   - Permanent context documents (`index.md`, `product.md`, `product-guidelines.md`, `tech-stack.md`, `security-policy.md`, `workflow.md`) represent timeless system state and **never** reference `tracks/` or `tracks.md`. Track workstreams are indexed exclusively in standalone `<CONDUCTOR_DIR>/tracks.md`.
