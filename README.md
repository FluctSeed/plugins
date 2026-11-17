# Fluctseed Plugin — Spec-Driven & Empirical AI Engineering Platform

**Fluctseed** is a cross-platform AI engineering plugin that enforces a unified **5-stage engineering pipeline** through **7 lifecycle commands** (`/setup`, `/brainstorm`, `/new-track`, `/implement`, `/review`, `/status`, `/revert`):

1. **Stateful Document & Track Spine (`conductor/`)**: Persistent project context (`product.md`, `tech-stack.md`, `security-policy.md`, `code_styleguides/`, `workflow.md`), ideation briefs (`concepts_brief.md`), track-based specifications (`tracks/<id>/spec.md` & `plan.md`), `[ ] → [~] → [x]` task state machine, and `git notes` audit trails.
2. **Zero-Context Multi-Lens Ideation & Design Audit (`agents/` & `resources/standards/`)**: Cognitive separation between the primary drafting session and isolated, fresh-context reviewer subagents that stress-test raw concepts across 7 lenses (`Mode: BRAINSTORM`), audit specifications (`Stages 5–8`), audit implementation plans (`Stage 9`), verify directory architecture contracts (`README.md`), and detect spec-to-code drift (`drift-report.md`).
3. **Empirical Implementation & Verification Discipline (`resources/playbooks/` & `resources/principles/`)**: 23 engineering playbooks (`bug-fix`, `feature`, `refactoring`, `opening-a-pr`, etc.) and 24 core principles (`Laziness Protocol`, `Model the Domain`, `Fix Root Causes`, `Test Behavior Not Implementation`, `Prove It Works` via `verification.log`, `Show Me Your Work` via `decisions.tsv`, `No Comments` via `comment_auditor.md`, and `Unslop`).

---

## 1. Unified Lifecycle Commands (`skills/*`)

| Stage & Command | Active Mode | Core Execution Flow |
| :--- | :--- | :--- |
| **1. `/setup`**<br>(`skills/setup/`) | **Phase 1**<br>*(Context & Contract Scaffolding)* | • Runs `scripts/resume.py` and scaffolds `conductor/` (`product.md`, `product-guidelines.md`, `tech-stack.md`, `code_styleguides/*.md`, `security-policy.md`, and `workflow.md`).<br>• Generates code-grounded directory `README.md` architecture contracts (`Interface`, `Invariants`, `Side Effects`) and links them in `conductor/index.md`. |
| **2a. `/brainstorm`**<br>(`skills/brainstorm/`) | **Phase 1**<br>*(7-Lens Ideation & Hypothesis Stress-Test)* | • Drills into raw concepts via multi-turn open-ended questions (without pre-canned multiple-choice anchoring).<br>• Spawns parallel fresh-context reviewers across **7 Brainstorming Lenses** (`Contrarian/YAGNI`, `Cost/Quota`, `UX/Ergonomics`, `Migration`, `Observability/SRE`, `Tech Debt`, `Inventive Catalyst`) in `Mode: BRAINSTORM`.<br>• Writes `concepts_brief.md` (`Overview`, `Multi-Lens Analysis`, `Goals vs. Non-Goals`, `Alternatives Weighed`, `Key Decisions`) and hands off to `/new-track`. |
| **2b. `/new-track`**<br>(`skills/new-track/`) | **Phase 1**<br>*(Spec → Zero-Context Audit → Human Gate)* | • Ingests `concepts_brief.md` (carrying `Alternatives Weighed` into `spec.md`) or triggers 7-lens brainstorming if needed.<br>• Drafts `conductor/tracks/<id>/spec.md` and `plan.md` (with **Throughput Checkpoint** & **Domain Data Shape**).<br>• Spawns zero-context reviewer subagents (`Stages 5–8` on `spec.md`, `Stage 9` on `plan.md`) and resolves findings into `design_audit_report.md`.<br>• Enforces the **Stage 3 Human Gate** (`scripts/gate_check.py --approve <id>`), locking `spec.md` & `plan.md` SHA-256 hashes in `metadata.json`. |
| **3. `/implement`**<br>(`skills/implement/`) | **Phase 2**<br>*(Empirical Implementation)* | • Verifies the **Stage 3 Human Gate lock** (`scripts/gate_check.py --verify <id>`); halts immediately if unapproved.<br>• Executes `plan.md` tasks (`[ ] → [~] → [x]`) using the **23 playbooks & 24 principles**: Domain Modeling first, Reproduce/Failing check first (`tdd`), Minimal diff (`Laziness Protocol`), real test/build log capture (`scripts/capture-verify-log.sh` → `verification.log`), and Dual Audit Trail (`git notes` + `scripts/log.sh` → `decisions.tsv`). |
| **4. `/review`**<br>(`skills/review/`) | **Phase 2 → 1**<br>*(Triple Audit & PR)* | • **Layer 1 (Runtime & Hygiene):** Verifies `verification.log` (`Prove It Works`) and `decisions.tsv`, strips narrating comments (`comment_auditor.md` / `no-comments`) and AI slop (`unslop`), and runs adversarial `interrogate`.<br>• **Layer 2 (Spec Drift):** Runs `drift-report` comparing `spec.md` & `README.md` contracts against implemented code.<br>• **Layer 3 (Standards & PR):** Checks `code_styleguides/*.md` & `security-policy.md`, archives the track, and opens a Git PR using `opening-a-pr.md`. |
| **5. `/status`**<br>(`skills/status/`) | **Read-Only** | • Displays a unified dashboard of track progress, active Phase, zero-context design audit status, Stage 3 Human Gate lock, and latest `decisions.tsv` / `verification.log` entries. |
| **6. `/revert`**<br>(`skills/revert/`) | **State Rollback** | • Reconciles and safely reverts Git commits for a Track, Phase, or Task while appending an auditable superseding row to `decisions.tsv`. |

---

## 2. Cross-Platform Installation & Synchronization (`./scripts/sync-agents.sh`)

`./scripts/sync-agents.sh` maps the open-standard core (`skills/`, `agents/`, `rules/`, `resources/`, `scripts/`) into the native configuration directories of **Claude Code**, **OpenAI Codex CLI**, **Google Antigravity (`agy`)**, and **Grok (CLI / API)**:

```bash
chmod +x ./scripts/sync-agents.sh
./scripts/sync-agents.sh
```
