# Fluctseed — Spec-Driven & Empirical AI Engineering Platform

**Fluctseed** is a unified AI engineering platform that enforces a **5-stage engineering lifecycle** across all major AI coding agents (**Claude Code**, **OpenAI Codex CLI**, **Google Antigravity**, **Cursor**, etc.) through **7 lifecycle commands** (`/setup`, `/brainstorm`, `/new-track`, `/implement`, `/review`, `/status`, `/revert`):

1. **Stateful Document & Track Spine (`conductor/`)**: Persistent project context (`product.md`, `tech-stack.md`, `security-policy.md`, `code_styleguides/`, `workflow.md`), ideation briefs (`concepts_brief.md`), track-based specifications (`tracks/<id>/spec.md` & `plan.md`), `[ ] → [~] → [x]` task state machine, and `git notes` audit trails. **Monorepo Multi-Module Support**: Individual packages or submodules can maintain their own `<module_path>/conductor/` directories while seamlessly inheriting enterprise security policies and styleguides from the root repository.
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

## 2. Installation & Distribution

Fluctseed can be installed via **Native Agent Plugin Marketplaces** (recommended for full platform capabilities with subagents and rules) or via the **Agent Skills standard (`skills` CLI)**.

### Method A: Native Plugin Marketplace (Recommended)

#### 1. Claude Code
Install directly through Claude Code's plugin marketplace mechanism:

```bash
# 1. Register the Fluctseed marketplace
claude plugin marketplace add FluctSeed/plugins

# 2. Install the Fluctseed plugin
claude plugin install fluctseed@fluctseed
```
*(Inside an active Claude Code chat session, you can run `/plugin marketplace add FluctSeed/plugins` followed by `/plugin install fluctseed@fluctseed`.)*

#### 2. OpenAI Codex CLI
Install the complete plugin including subagent personas, playbooks, and standards:

```bash
# 1. Register the Fluctseed marketplace
codex plugin marketplace add FluctSeed/plugins

# 2. Install the Fluctseed plugin
codex plugin add fluctseed@fluctseed
```

#### 3. Google Antigravity (`agy`)
Install directly using the Antigravity CLI or UI:

```bash
# Install via agy CLI
agy plugin install https://github.com/FluctSeed/plugins
```
*(Or search and enable "Fluctseed" in the Antigravity Plugin Manager UI.)*

---

### Method B: Agent Skills Standard (`npx skills add`)

Fluctseed implements the open [Agent Skills specification](https://skills.sh/). You can install all skills or pick individual skills into any supported agent harness (**Claude Code**, **Codex**, **Cursor**, **Antigravity**, **OpenCode**, etc.):

#### 1. Install All Skills into All Detected Agents
```bash
npx skills add FluctSeed/plugins --all
```

#### 2. Install Interactively (Select Skills and Targets)
```bash
npx skills add FluctSeed/plugins
```

#### 3. Install Specific Skills
```bash
# Example: Install brainstorm and new-track into your current project
npx skills add FluctSeed/plugins --skill brainstorm new-track

# Example: Install implementation and review skills
npx skills add FluctSeed/plugins --skill implement review status
```

#### 4. Global Installation
```bash
# Install globally to user-level configuration (~/.claude/skills, ~/.agents/skills, etc.)
npx skills add FluctSeed/plugins -g
```

---

## 3. Getting Started

1. **Initialize Project Context & Directory Contracts:**
   ```
   /setup
   ```
   Creates `conductor/` context files and generates directory-level `README.md` contracts.

2. **Explore & Stress-Test a New Feature Hypothesis:**
   ```
   /brainstorm
   ```
   Conducts multi-turn problem drilling and dispatches the 7-lens fresh-context reviewer swarm to generate `concepts_brief.md`.

3. **Plan, Audit & Lock the Human Gate:**
   ```
   /new-track
   ```
   Drafts `spec.md` and `plan.md`, runs zero-context subagent audits (Stages 5–9), produces `design_audit_report.md`, and requests Stage 3 Human Gate approval.

4. **Execute with Empirical Discipline:**
   ```
   /implement
   ```
   Verifies the Human Gate lock, then executes tasks with behavioral TDD, minimal diffs, real runtime verification (`verification.log`), and decision logging (`decisions.tsv`).

5. **Verify Runtime Proof, Strip Slop & Open PR:**
   ```
   /review
   ```
   Verifies runtime logs, strips narrating comments, checks spec-to-code drift, checks security/styleguides, and opens a GitHub Pull Request.

---

## 4. Repository Structure

```text
fluctseed-plugin/
├── plugin.json                     # Google Antigravity & Root Plugin Manifest
├── .claude-plugin/                 # Claude Code Plugin & Marketplace Definition
│   ├── marketplace.json            # Claude Code Marketplace Manifest
│   ├── plugin.json                 # Claude Code Plugin Manifest
│   └── icon.png
├── .codex-plugin/                  # OpenAI Codex Plugin Definition
│   └── plugin.json                 # Codex Plugin Manifest
├── .agents/plugins/                # Codex & Cross-Platform Marketplace Catalog
│   └── marketplace.json
├── skills/                         # Open Standard Agent Skills (npx skills add)
│   ├── setup/SKILL.md
│   ├── brainstorm/SKILL.md
│   ├── new-track/SKILL.md
│   ├── implement/SKILL.md
│   ├── review/SKILL.md
│   ├── status/SKILL.md
│   └── revert/SKILL.md
├── agents/                         # 12 Specialized Subagent Personas
│   ├── zoom_out.md
│   ├── inventive_catalyst.md
│   ├── comprehension.md
│   ├── design_critic.md
│   ├── structural.md
│   ├── style.md
│   ├── implementation_readiness.md
│   ├── codebase_details.md
│   ├── synthesizer.md
│   ├── implementer.md
│   ├── comment_auditor.md
│   └── bootstrap_orchestrator.md
├── rules/                          # System Rules & Epistemic Disciplines
│   ├── lifecycle-workflow.md
│   ├── design-audit-discipline.md
│   ├── implementation-discipline.md
│   └── interactive-questions.md
├── resources/
│   ├── tactics/                    # 17 Architectural Tactics
│   ├── playbooks/                  # 23 Implementation Playbooks
│   ├── principles/                 # 24 Core Engineering Principles
│   ├── standards/                  # Review & Specification Standards
│   ├── styleguides/                # Multi-Language Style Guides
│   └── templates/                  # Document & Schema Templates
└── scripts/                        # Utility & Audit Verification Scripts
    ├── gate_check.py               # SHA-256 Gate Locking & Verification
    ├── capture-verify-log.sh       # Runtime Test/Build Log Capture
    ├── log.sh                      # Decisions.tsv Audit Trail Logger
    ├── resume.py                   # Context Loader
    ├── prepare_audit_context.py    # Zero-Context Audit Context Builder
    └── sync-agents.sh              # Local Offline Development Helper
```

---

## 5. Developer & Contributor Notes

For repository contributors developing locally without internet access or testing cross-platform symlinks, `./scripts/sync-agents.sh` can be used as an offline local testing utility:

```bash
chmod +x ./scripts/sync-agents.sh
./scripts/sync-agents.sh
```

For all regular usage and production deployments, use **Plugin Marketplace (`claude plugin install`, `codex plugin add`, `agy plugin install`)** or **Agent Skills (`npx skills add FluctSeed/plugins`)**.
