# Fluctseed AI Engineering Platform Constitution (`AGENTS.md`)

This repository uses the **Fluctseed Spec-Driven and Empirical Engineering Architecture** organized into **7 Lifecycle Commands**:

1. **`/setup`** (`skills/setup/SKILL.md`): Project initialization (`conductor/product.md`, `tech-stack.md`, `security-policy.md`, `code_styleguides/`, `workflow.md`) and directory-level `README.md` architecture contracts (`Interface`, `Invariants`, `Side Effects`).
2. **`/brainstorm`** (`skills/brainstorm/SKILL.md`): Upstream multi-lens ideation and hypothesis stress-testing (`resources/tactics/design-brainstorm.md`). Conducts multi-turn open-ended problem drilling without pre-canned choice anchoring, spawns the **7-Lens Fresh-Context Brainstorm Swarm (`Mode: BRAINSTORM`)**, and produces `concepts_brief.md` (`Overview`, `Multi-Lens Analysis`, `Goals vs. Non-Goals`, `Alternatives Weighed`, `Key Decisions`).
3. **`/new-track`** (`skills/new-track/SKILL.md`): Ingests `concepts_brief.md` (or runs 7-lens brainstorming), traces empirical codebase facts (`resources/tactics/how.md`, `why.md`), drafts `spec.md` and `plan.md`, runs **5-Stage Zero-Context Cross-Verification (`agents/*.md`)**, resolves findings (`design_audit_report.md`), and locks the **Stage 3 Human Gate (`scripts/gate_check.py --approve`)**.
4. **`/implement`** (`skills/implement/SKILL.md`): Verifies the **Stage 3 Human Gate (`scripts/gate_check.py --verify`)**, then executes `plan.md` tasks (`[ ] → [~] → [x]`) under **23 engineering playbooks (`resources/playbooks/`) and 24 principles (`resources/principles/`)**: Domain Modeling first (`principle-model-the-domain`), Reproduce/Failing check first (`tdd`, `principle-fix-root-causes`), Minimal diff (`principle-laziness-protocol`), real runtime proof (`scripts/capture-verify-log.sh` → `verification.log`), and Dual Audit Trail (`git notes` + `scripts/log.sh` → `decisions.tsv`).
5. **`/review`** (`skills/review/SKILL.md`): Triple Verification — **Runtime Proof & Anti-Slop (`no-comments`, `unslop`, `interrogate`)** + **Spec/Contract Drift Detection (`drift-report`)** + **Styleguide & Security Review** + **Git PR Creation (`resources/playbooks/opening-a-pr.md`)**.
6. **`/status`** (`skills/status/SKILL.md`): Unified dashboard displaying track progress, active Phase (1 vs. 2), zero-context design audit status, Human Gate lock, and `decisions.tsv` / `verification.log` status.
7. **`/revert`** (`skills/revert/SKILL.md`): Git-aware rollback of logical units (Track, Phase, or Task) with append-only superseding rows in `decisions.tsv`.

---

## Core Architectural Invariants

### 1. Two-Phase Autonomy
- **Phase 1 (Pre-Gate: `/setup`, `/brainstorm`, `/new-track`, Stage 3 Human Gate):**
  - Write **zero production code**.
  - Present architectural options (`Author Decides Architecture`) with mechanisms, trade-offs, and failure conditions without sycophancy (`No Glazing`, `Critique First`).
  - Never ask the human an empirical question about the existing codebase that you can answer yourself by reading code (`resources/tactics/how.md`, `why.md`).
- **Phase 2 (Post-Gate: `/implement`, `/review`):**
  - Do not start `/implement` unless `python3 scripts/gate_check.py --verify <track_id>` succeeds (`"human_gate_approved": true`).
  - Within the approved `spec.md` and `plan.md`, execute tasks autonomously (`principle-never-block-on-the-human`). Pause only at Phase Checkpoints, irreversible operations, or when an architectural invariant in `spec.md`, `tech-stack.md`, or `security-policy.md` must change.

### 2. Semantic Direct Binding for Zero-Context Design Reviews
- Bind `conductor/tracks/<track_id>/spec.md` to `FeatureRange` (**Stages 5–8**: `zoom_out`, `inventive_catalyst`, `comprehension`, `design_critic`, `structural`, `style`).
- Bind `conductor/tracks/<track_id>/plan.md` to `DetailedRange` (**Stage 9**: `implementation_readiness`, `codebase_details`, `style`).
- Supply `conductor/` documents and `README.md` contracts as `AuditContext` (via `python3 scripts/prepare_audit_context.py`), except Stage 6 (`comprehension`), which runs with zero context to verify self-containment.

### 3. Empirical TDD, Minimal Diffs & Dual Audit Trail
- Model the domain data shape (`principle-model-the-domain`) and system boundaries (`principle-boundary-discipline`) before writing logic.
- Reproduce bugs on the real surface first (`resources/playbooks/bug-fix.md`) and write behavioral checks (`principle-test-behavior-not-implementation`), avoiding brittle mock-only unit tests.
- Capture real verification output in `conductor/tracks/<track_id>/verification.log` via `./scripts/capture-verify-log.sh` and log every decision in `conductor/tracks/<track_id>/decisions.tsv` via `./scripts/log.sh` alongside `git notes`.

### 4. Monorepo & Module Conductor Awareness
- Multiple module-level `conductor/` directories (`<module_path>/conductor/`) can exist in monorepos alongside an optional root `conductor/`.
- Discovery commands (`prepare_audit_context.py --list-conductors`) identify module conductors automatically. Module conductors inherit root enterprise `security-policy.md` and `code_styleguides/` when not overridden locally.

### 4. Monorepo & Module Conductor Awareness
- Multiple module-level `conductor/` directories (`<module_path>/conductor/`) can exist in monorepos alongside an optional root `conductor/`.
- Discovery commands (`prepare_audit_context.py --list-conductors`) identify module conductors automatically. Module conductors inherit root enterprise `security-policy.md` and `code_styleguides/` when not overridden locally.
