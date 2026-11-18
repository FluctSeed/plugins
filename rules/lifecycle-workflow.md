---
trigger: always_on
description: Master engineering workflow constitution across the 7 lifecycle commands (/setup, /brainstorm, /new-track, /implement, /review, /status, /revert).
---

# Fluctseed Unified Engineering Workflow

You operate under a Spec-Driven and Empirical Engineering lifecycle organized around seven commands (`/setup`, `/brainstorm`, `/new-track`, `/implement`, `/review`, `/status`, `/revert`).

## 1. Lifecycle Mapping

| Lifecycle Stage | Command | Active Mode | Core Mechanism |
| :--- | :--- | :--- | :--- |
| **1. Project Initialization** | `/setup` | **Phase 1** *(Context & Contract Scaffolding)* | Scaffolds `conductor/` (`product.md`, `tech-stack.md`, `security-policy.md`, `code_styleguides/`, `workflow.md`) and documents directory architecture contracts (`Interface`, `Invariants`, `Side Effects`). |
| **2a. Upstream Ideation & Hypothesis Stress-Testing** | `/brainstorm` | **Phase 1** *(Open-Ended Drilling & 7-Lens Critique)* | Conducts multi-turn open-ended problem drilling (without pre-canned choice anchoring), runs parallel **7-Lens Fresh-Context Critique (`Mode: BRAINSTORM`)**, and writes `concepts_brief.md` (`Alternatives Weighed` & `Key Decisions`). |
| **2b. Spec & Zero-Context Audit** | `/new-track` | **Phase 1** *(Spec & Independent Audit)* | Ingests `concepts_brief.md` (or runs 7-lens brainstorm), traces empirical codebase facts (`how`/`why`), drafts `spec.md` and `plan.md`, spawns isolated **Fresh-Context Reviewer subagents** (`Stages 5–8` on `spec.md`, `Stage 9` on `plan.md`), and resolves findings into `design_audit_report.md`. |
| **3. Developer Approval** | **Human Gate** | **Gate Lock** | The human developer reviews `spec.md`, `plan.md`, and `design_audit_report.md`. Upon explicit approval, `scripts/gate_check.py --approve` locks the track hashes in `metadata.json`. |
| **4. Implementation & Debugging** | `/implement` | **Phase 2** *(Empirical Implementation)* | Verifies the Human Gate lock (`scripts/gate_check.py --verify`), then executes `plan.md` tasks (`[ ] → [~] → [x]`) under strict engineering playbooks and 24 principles (Domain Modeling first, Reproduce/Failing check first, Minimal diff, real runtime verification in `verification.log`, and dual audit logging via `git notes` and `decisions.tsv`). |
| **5. Verification, Review & PR** | `/review` | **Phase 2 → 1** *(Triple Audit & PR)* | Verifies runtime logs (`Prove It Works`), strips narrating comments and AI slop (`no-comments`, `unslop`), runs **Spec-to-Code Drift Detection** against `spec.md` and `README.md` contracts, checks styleguides and security policy, and opens a Git PR. |

## 2. The Six Architectural Invariants

1. **Two-Phase Autonomy:**
   - In **Phase 1 (`/setup`, `/brainstorm`, `/new-track`)**, write **zero production code**. Defer architectural trade-offs to the human (`Author Decides Architecture`), but resolve empirical codebase questions yourself using `how`/`why` before asking.
   - In **Phase 2 (`/implement`, `/review`)**, never block on the human for reversible implementation steps (`Never Block on the Human`). Halt and return to Phase 1 only if an invariant in `spec.md`, `tech-stack.md`, or `security-policy.md` must change.
2. **Semantic Direct Binding for Zero-Context Reviews:**
   - Bind `conductor/tracks/<id>/spec.md` to `FeatureRange` (Stages 5–8) and `conductor/tracks/<id>/plan.md` to `DetailedRange` (Stage 9), feeding `conductor/` documents and `README.md` contracts as `AuditContext`.
3. **Pragmatic TDD & Real Verification:**
   - Replace mock-heavy boilerplate tests with behavioral checks (`Test Behavior, Not Implementation`) and real runtime verification (`Prove It Works` via `scripts/capture-verify-log.sh`).
4. **Continuous Spec-to-Code Drift Elimination:**
   - Every `/review` checks both code quality/security and architectural contract fidelity (`drift-report`).
5. **Unslopped, Sequential Communication:**
   - Ask at most one question per turn. Eliminate sycophancy (`No Glazing`), polite apologies, and AI slop (`unslop`).
6. **Monorepo & Module Conductor Awareness:**
   - In monorepo structures, multiple module-level `conductor/` directories (`<module_path>/conductor/`) can exist alongside an optional root `conductor/`.
   - Commands auto-discover module conductors, scope track execution to the active module, and inherit monorepo-wide security policies (`security-policy.md`) and style guides (`code_styleguides/`) from the root when not overridden locally.
