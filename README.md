# Fluctseed Corp.

**Fluctseed** (by **Fluctseed Corp.**) is a cross-platform AI engineering plugin that enforces a **5-stage engineering lifecycle** across **Claude Code**, **OpenAI Codex CLI**, and **Google Antigravity (`agy`)** through **7 lifecycle commands** (`setup`, `brainstorm`, `new-track`, `implement`, `review`, `status`, `revert`):

1. **Stateful Context, Living Designs & Track Spine (`conductor/` & `docs/designs/`)**: Permanent project charter (`conductor/product.md`, `tech-stack.md`, `security-policy.md`, `code_styleguides/`, `workflow.md`), continuously synchronized subsystem architecture and decision documents (`docs/designs/<subsystem>.md` + `docs/designs/README.md`), ephemeral track workspaces (`conductor/tracks/<id>/spec.md`, `plan.md`, `[ ] -> [~] -> [x]`), and monorepo multi-module discovery (`<module_path>/conductor/` & `<module_path>/docs/designs/`) with automatic inheritance of root security policies and styleguides.
2. **Zero-Context Multi-Lens Ideation & Design Audit (`agents/` & `resources/standards/`)**: Separation between the primary drafting session and isolated, read-only reviewer subagents that stress-test raw concepts across 7 lenses (`Mode: BRAINSTORM`), audit specifications (`Stages 5 to 8`), audit implementation plans (`Stage 9`), verify directory architecture contracts (`README.md`), and detect spec-to-code drift (`drift_report.md`).
3. **Empirical Implementation & Verification Discipline (`resources/playbooks/` & `resources/principles/`)**: 23 engineering playbooks (`bug-fix`, `feature`, `refactoring`, `opening-a-pr`, etc.) and 24 core principles (`Laziness Protocol`, `Model the Domain`, `Fix Root Causes`, `Test Behavior Not Implementation`, `Prove It Works` via `verification.log`, `Show Me Your Work` via `decisions.tsv`, `No Comments` via `comment-auditor.md`, and `Unslop`).

---

## 1. Unified Lifecycle Commands (`skills/*`)

| Stage & Skill | Active Mode | Core Execution Flow |
| :--- | :--- | :--- |
| **1. `setup`**<br>(`skills/setup/`) | **Phase 1**<br>*(Context & Contract Scaffolding)* | • Runs `scripts/resume.py` and scaffolds `<CONDUCTOR_DIR>/` (`product.md`, `product-guidelines.md`, `tech-stack.md`, `code_styleguides/*.md`, `security-policy.md`, `workflow.md`).<br>• Generates code-grounded directory `README.md` architecture contracts (`Interface`, `Invariants`, `Side Effects`) and links them in `<CONDUCTOR_DIR>/index.md`. |
| **2a. `brainstorm`**<br>(`skills/brainstorm/`) | **Phase 1**<br>*(7-Lens Ideation & Stress-Test)* | • Drills into raw concepts via sequential open-ended questions without multiple-choice anchoring.<br>• Dispatches parallel fresh-context reviewers across **7 Brainstorming Lenses** (`Contrarian/YAGNI`, `Cost/Quota`, `UX/Ergonomics`, `Migration`, `Observability/SRE`, `Tech Debt`, `Inventive Catalyst`) in `Mode: BRAINSTORM`.<br>• Writes `concepts_brief.md` (`Overview`, `Multi-Lens Analysis`, `Goals vs. Non-Goals`, `Alternatives Weighed`, `Key Decisions`) and hands off to `new-track`. |
| **2b. `new-track`**<br>(`skills/new-track/`) | **Phase 1**<br>*(Spec -> Zero-Context Audit -> Human Gate)* | • Ingests `concepts_brief.md` or triggers 7-lens brainstorming.<br>• Drafts `<TRACK_DIR>/spec.md` and `<TRACK_DIR>/plan.md` (validated with `scripts/check-plan.mjs`).<br>• Dispatches zero-context reviewers (`Stages 5 to 8` on `spec.md`, `Stage 9` on `plan.md`) and resolves findings into `design_audit_report.md`.<br>• Enforces the **Stage 3 Human Gate** (`scripts/gate_check.py --approve`), locking `spec_sha256`, `plan_structure_sha256`, and `base_sha` in `metadata.json`. |
| **3. `implement`**<br>(`skills/implement/`) | **Phase 2**<br>*(Empirical Implementation)* | • Verifies the **Stage 3 Human Gate lock** (`scripts/gate_check.py --verify`); halts immediately if unapproved or drifted.<br>• Executes `plan.md` tasks (`[ ] -> [~] -> [x]`) under the 23 playbooks, 24 principles, and 29 tactics: Domain Modeling first, Reproduce/Failing check first, Minimal diff, real test/build log capture (`scripts/capture-verify-log.sh` -> `verification.log`), audit logging (`scripts/log.sh` -> `decisions.tsv`), and end-of-track project context synchronization. |
| **4. `review`**<br>(`skills/review/`) | **Phase 2 -> 1**<br>*(Triple Audit & PR)* | • **Track Mode (Default):** Verifies `verification.log` and `decisions.tsv`, runs read-only `comment-auditor`, `unslop`, and adversarial `interrogate`, writes `drift_report.md`, checks `code_styleguides/*.md` and `security-policy.md`, and opens a Git PR (`opening-a-pr.md`).<br>• **Standalone Modes:** Also runs standalone zero-context document audits (`Stages 5 to 9`) on `.md` RFCs/specs or standalone codebase drift checks (`drift_report.md`). |
| **5. `status`**<br>(`skills/status/`) | **Read-Only** | • Displays a multi-module monorepo or single-project dashboard of track progress, active Phase, zero-context audit status, Stage 3 Human Gate lock/drift, and latest `decisions.tsv` / `verification.log` entries. |
| **6. `revert`**<br>(`skills/revert/`) | **State Rollback** | • Reconciles and reverts Git commits for a Track, Phase, or Task while preserving all prior `decisions.tsv` history and appending an auditable `"revert"` row. |

---

## 2. Installation (Native Plugin Marketplaces)

> [!IMPORTANT]
> **Install the complete plugin bundle via Native Plugin Marketplaces.**
> Standalone skill-only copy tools (such as `npx skills add`) are **not supported** because Fluctseed skills invoke shared runtime scripts (`scripts/`), reviewer personas (`agents/`), rules (`rules/`), and standards/playbooks (`resources/`) outside `skills/<name>/`.

### 1. Claude Code
```bash
# 1. Register the Fluctseed marketplace
claude plugin marketplace add FluctSeed/plugins

# 2. Install the Fluctseed plugin
claude plugin install fluctseed@fluctseed
```
*(Inside an active Claude Code chat session, run `/plugin marketplace add FluctSeed/plugins` followed by `/plugin install fluctseed@fluctseed`.)*

Invoke commands in Claude Code with the `fluctseed:` plugin namespace (avoiding collisions with built-in `/status` and `/review`):
`/fluctseed:setup`, `/fluctseed:brainstorm`, `/fluctseed:new-track`, `/fluctseed:implement`, `/fluctseed:review`, `/fluctseed:status`, `/fluctseed:revert`.

### 2. OpenAI Codex CLI
```bash
# 1. Register the Fluctseed marketplace
codex plugin marketplace add FluctSeed/plugins

# 2. Install the Fluctseed plugin
codex plugin add fluctseed@fluctseed
```
Start a new Codex session and select or invoke `fluctseed:setup`, `fluctseed:brainstorm`, `fluctseed:new-track`, `fluctseed:implement`, `fluctseed:review`, `fluctseed:status`, or `fluctseed:revert`.

### 3. Google Antigravity (`agy`)
```bash
agy plugin install https://github.com/FluctSeed/plugins
```
Invoke commands directly via `/setup`, `/brainstorm`, `/new-track`, `/implement`, `/review`, `/status`, and `/revert`.

---

## 3. Repository Structure

```text
fluctseed-plugin/
├── plugin.json                     # Google Antigravity Plugin Manifest
├── .claude-plugin/                 # Claude Code Plugin & Marketplace Manifests
│   ├── marketplace.json
│   └── plugin.json
├── .codex-plugin/                  # OpenAI Codex Plugin Manifest
│   └── plugin.json
├── .agents/plugins/                # Codex Marketplace Catalog
│   └── marketplace.json
├── LICENSE                         # Apache-2.0 License
├── NOTICE                          # Attribution Notice
├── assets/
│   └── icon.svg                    # Plugin Vector Logo
├── skills/                         # 7 Unified Lifecycle Skills
│   ├── setup/SKILL.md
│   ├── brainstorm/SKILL.md
│   ├── new-track/SKILL.md
│   ├── implement/SKILL.md
│   ├── review/SKILL.md
│   ├── status/SKILL.md
│   └── revert/SKILL.md
├── agents/                         # 12 Subagent Personas (kebab-case, tool-scoped)
│   ├── zoom-out.md
│   ├── inventive-catalyst.md
│   ├── comprehension.md
│   ├── design-critic.md
│   ├── structural.md
│   ├── style.md
│   ├── implementation-readiness.md
│   ├── codebase-details.md
│   ├── synthesizer.md
│   ├── implementer.md
│   ├── comment-auditor.md
│   └── bootstrap-orchestrator.md
├── rules/                          # Epistemic & Execution Discipline Rules
│   ├── lifecycle-workflow.md
│   ├── design-audit-discipline.md
│   ├── implementation-discipline.md
│   └── interactive-questions.md
├── resources/
│   ├── tactics/                    # 29 Architectural, Verification & Hygiene Tactics
│   ├── playbooks/                  # 23 Implementation Playbooks
│   ├── principles/                 # 24 Core Engineering Principles
│   ├── standards/                  # 5 Specification & Review Standards
│   ├── styleguides/                # 10 Language Style Guides
│   └── templates/                  # Document & Log Templates
└── scripts/                        # Runtime Gate, Context & Audit Scripts
    ├── gate_check.py               # Stage 3 Human Gate & Spec/Plan Hash Verifier
    ├── prepare_audit_context.py    # Monorepo Conductor & AuditContext Builder
    ├── capture-verify-log.sh       # Runtime Test/Build Log & GitHEAD Recorder
    ├── log.sh                      # Append-Only decisions.tsv Logger
    ├── resume.py                   # Setup Resumption & Inheritance Checker
    ├── check-plan.mjs              # Phased plan.md Structural Validator
    ├── worktree-audit.sh           # Read-Only Git Worktree Prune Auditor
    └── sync-agents.sh              # Bundle Verifier (--check) & Offline Dev Helper
```

---

## 4. Contributor Verification

Validate the plugin bundle locally across manifests, files, and CLI validators:

```bash
./scripts/sync-agents.sh --check
claude plugin validate .
agy plugin validate . --strict
```
