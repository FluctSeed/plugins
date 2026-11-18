---
name: setup
description: Scaffolds the project context in conductor/ (product definition, tech stack, styleguides, security policy, and workflow standard) and bootstraps directory-level README.md architecture contracts. Use whenever a project needs to be initialized or if conductor/index.md is missing.
metadata:
  version: "0.1.0"
---

# Project Setup Skill (`setup`)

> [!NOTE]
> **Plugin Root & Governance Rules (`${PLUGIN_ROOT}`)**
> - `${PLUGIN_ROOT}` is the root directory of this plugin (`${CLAUDE_PLUGIN_ROOT}` if expanded by your harness, otherwise two directories above this `SKILL.md` file). Resolve `${PLUGIN_ROOT}` to its absolute path before calling file or shell tools.
> - If your harness does not preload plugin `rules/*.md` automatically (Claude Code and Codex CLI), read `${PLUGIN_ROOT}/rules/lifecycle-workflow.md`, `${PLUGIN_ROOT}/rules/design-audit-discipline.md`, and `${PLUGIN_ROOT}/rules/interactive-questions.md` first.

You are the **System Architect** operating in **Phase 1 (Pre-Gate Context & Architecture Contract Scaffolding)**. Initialize the repository (or target monorepo module) for Spec-Driven and Empirical Development by creating persistent context documents in `<CONDUCTOR_DIR>/` and grounding existing directories in code-verified `README.md` architecture contracts (`Interface`, `Invariants`, `Side Effects`).

Reference materials:
- Workflow Template: `${PLUGIN_ROOT}/resources/templates/workflow.md`
- Security Policy Template: `${PLUGIN_ROOT}/resources/templates/security-policy.md`
- Code Style Guides: `${PLUGIN_ROOT}/resources/styleguides/*.md`
- Directory Contract Bootstrapping: `${PLUGIN_ROOT}/resources/tactics/bootstrap-contracts.md` and `${PLUGIN_ROOT}/resources/templates/contract_templates.md`

---

## Operational Standards

- **Zero Production Code (Phase 1):** Restrict operations to discovery, configuration, and documentation. Do not write or modify application source code.
- **Tool Validation:** Verify the output and exit code of every tool call before advancing.
- **Plain-English Standard & No Glazing:** Explain technical value directly without promotional adjectives or flattery.
- **Sequential Questioning:** Follow `${PLUGIN_ROOT}/rules/interactive-questions.md`. Ask strictly **one question per turn** using your harness's native question schema (or a numbered plain-text single question when no modal tool is active).
- **Monorepo & Module Scope (`<CONDUCTOR_DIR>`):**
  - In a single-package repository, set `<CONDUCTOR_DIR>` to `./conductor`.
  - In a **Monorepo** (`packages/`, `services/`, `apps/`, `modules/`, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, `Cargo.toml` workspace, `go.work`), detect module boundaries and prompt the user if scope is unspecified:
    - `(Recommended) Monorepo Root (./conductor)` for organization-wide security policy, shared styleguides, and root blueprint.
    - `Module-Specific Context (<module_path>/conductor)` for module product definition, local stack, and local workflow (inheriting root security policy and styleguides when omitted locally).

---

## 1. Project Audit & Resumption Check

### 1.1 Pre-Initialization Overview

Present a brief overview adapted to the target `<CONDUCTOR_DIR>`:
1. **Project Discovery:** Audit repository state (Greenfield vs. Brownfield).
2. **Product & Stack Definition:** Establish `product.md`, `product-guidelines.md`, and `tech-stack.md`.
3. **Standards & Workflow:** Configure `code_styleguides/`, `security-policy.md`, and `workflow.md`.
4. **Directory Architecture Contracts:** Map directory-level `Interface`, `Invariants`, and `Side Effects` in `README.md` files.

### 1.2 Resumption Check

Run the resumption helper:
```bash
python3 "${PLUGIN_ROOT}/scripts/resume.py" --conductor-dir "<CONDUCTOR_DIR>"
```

Inspect the JSON output:
- If `setup_complete` is `true`, report that `<CONDUCTOR_DIR>/index.md` and all required governance files are already initialized, offer to refresh **Section 2.7 (Directory Architecture Contracts)**, or halt.
- If partial setup exists, list completed files and ask a single Yes/No question to resume from `next_step`.

---

## 2. Interactive Scaffolding & Context Gathering

1. **Detect Project Maturity:**
   - **Brownfield:** Presence of dependency manifests (`package.json`, `go.mod`, `requirements.txt`, `pyproject.toml`, `pom.xml`, `Cargo.toml`) or source directories (`src/`, `app/`, `lib/`, `cmd/`). Check `git status --porcelain` (excluding `conductor/`) and warn if uncommitted work exists.
   - **Greenfield:** No existing source or dependency manifests.
2. **Execute Maturity Discovery:**
   - **If Brownfield:** Ask permission to run a read-only scan, then inspect tracked files via `git ls-files` and manifests to infer the tech stack and build/test commands (`npm test`, `pytest`, `go test ./...`, `cargo test`, etc.).
   - **If Greenfield:** Run `git init` if `.git` is absent, then ask one open-ended question: *"What do you want to build?"*

### 2.1 Product Definition (`<CONDUCTOR_DIR>/product.md`)
1. Propose a Project Title and 1-paragraph summary from discovery or the user's concept and confirm.
2. Ask the user to select **Interactive Mode** (up to 4 sequential questions) or **Autogenerate Mode**.
3. Write `<CONDUCTOR_DIR>/product.md` first, link it in chat, and ask to **Approve**, **Revise**, or **Refine**.

### 2.2 Product Guidelines (`<CONDUCTOR_DIR>/product-guidelines.md`)
1. If initializing a monorepo module and root `conductor/product-guidelines.md` exists, offer to inherit the root guidelines or create a module override.
2. Otherwise offer **Interactive Mode** or **Autogenerate Mode**, write `<CONDUCTOR_DIR>/product-guidelines.md`, and confirm.

### 2.3 Technology Stack (`<CONDUCTOR_DIR>/tech-stack.md`)
1. Confirm the inferred stack (Brownfield) or gather language/framework/storage choices (Greenfield).
2. Write `<CONDUCTOR_DIR>/tech-stack.md`.

### 2.4 Code Style Guides (`<CONDUCTOR_DIR>/code_styleguides/`)
1. Propose matching style guides from `${PLUGIN_ROOT}/resources/styleguides/` (`general.md`, `typescript.md`, `javascript.md`, `python.md`, `go.md`, `cpp.md`, `csharp.md`, `dart.md`, `ruby.md`, `html-css.md`). In a monorepo module, offer inheriting root `conductor/code_styleguides/` or copying module-specific guides.
2. Copy selected `.md` files into `<CONDUCTOR_DIR>/code_styleguides/`.

### 2.5 Enterprise Security Policy (`<CONDUCTOR_DIR>/security-policy.md`)
1. Explain that `security-policy.md` defines mandatory invariants (secrets hygiene, boundary parsing, authz checks, dependency rules) checked during both zero-context design audits and code reviews.
2. Copy `${PLUGIN_ROOT}/resources/templates/security-policy.md` to `<CONDUCTOR_DIR>/security-policy.md` (or inherit root `conductor/security-policy.md` for a monorepo module) and apply any requested organization rules.

### 2.6 Workflow Configuration (`<CONDUCTOR_DIR>/workflow.md`)
1. Copy `${PLUGIN_ROOT}/resources/templates/workflow.md` to `<CONDUCTOR_DIR>/workflow.md` (or inherit root `conductor/workflow.md`) and adapt `Development Commands` to the project's real build, lint, and test commands.

### 2.7 Directory Architecture Contracts (`README.md` Bootstrap)
1. **Brownfield:** Recommend generating directory-level `README.md` contracts (`Interface`, `Invariants`, `Side Effects` with `[file:symbol]` citations).
2. **Greenfield:** Offer generating the root `README.md` blueprint contract now or deferring until source directories exist.
3. **Execution (when approved):**
   - Read `${PLUGIN_ROOT}/resources/tactics/bootstrap-contracts.md` and `${PLUGIN_ROOT}/resources/templates/contract_templates.md`.
   - Count code-bearing subdirectories (ignoring `.git`, `node_modules`, `dist`, `build`, `venv`, `vendor`, `target`, `conductor`). If more than **15** subdirectories exist, pause for explicit approval before full-tree bootstrapping.
   - Extract real `[file:symbol]` definitions directly or via `bootstrap-orchestrator` (`invoke_subagent` `bootstrap-orchestrator` in Antigravity, `Agent` `fluctseed:bootstrap-orchestrator` in Claude Code, or `spawn_agent` reading `${PLUGIN_ROOT}/agents/bootstrap-orchestrator.md` in Codex CLI).
   - Write or update `README.md` contracts without deleting existing human-authored prose.

---

## 3. Handshake Index (`<CONDUCTOR_DIR>/index.md`) & Commit

Write `<CONDUCTOR_DIR>/index.md` linking all active local (or inherited root) documents:

```markdown
# Project Context

## Definition
- [Product Definition](./product.md)
- [Product Guidelines](./product-guidelines.md)
- [Tech Stack](./tech-stack.md)

## Governance & Workflow
- [Workflow](./workflow.md)
- [Security Policy](./security-policy.md)
- [Code Style Guides](./code_styleguides/)

## Architecture Contracts
- [Module / Repository Blueprint](../README.md)
```

1. Verify every linked path in `<CONDUCTOR_DIR>/index.md` resolves on disk.
2. Stage `<CONDUCTOR_DIR>/` (and any approved `README.md` contracts) and commit:
   `chore(setup): initialize project context, security policy, and workflow standards`

---

## 4. Completion & Handoff

1. Summarize the created files in `<CONDUCTOR_DIR>/`.
2. Ask a single Yes/No question asking whether to start the first feature concept (`brainstorm`) or formal track (`new-track`) now.
