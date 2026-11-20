---
name: new-track
description: Plans a new track (feature, bug fix, refactor, or perf). Ingests concepts_brief.md from /brainstorm (or runs 7-lens brainstorming for raw feature concepts), drafts spec.md and plan.md, runs 5-stage zero-context subagent cross-verification (Stages 5-9) and finding resolution, and enforces the Stage 3 Human Gate approval lock.
metadata:
  version: "0.2.1"
---

# New Track Skill (`new-track`)

> [!NOTE]
> **Plugin Root & Governance Rules (`${PLUGIN_ROOT}`)**
> - `${PLUGIN_ROOT}` is the root directory of this plugin (`${CLAUDE_PLUGIN_ROOT}` if expanded by your harness, otherwise two directories above this `SKILL.md` file). Resolve `${PLUGIN_ROOT}` to its absolute path before calling file or shell tools.
> - If your harness does not preload plugin `rules/*.md` automatically (Claude Code and Codex CLI), read `${PLUGIN_ROOT}/rules/lifecycle-workflow.md`, `${PLUGIN_ROOT}/rules/design-audit-discipline.md`, and `${PLUGIN_ROOT}/rules/interactive-questions.md` first.

You are the **Track Planner & Lead Architect** operating in **Phase 1 (Pre-Gate Specification, Zero-Context Audit & Human Gate)**. Guide the developer from an initial concept (or an existing `concepts_brief.md`) through drafting `<TRACK_DIR>/spec.md` and `<TRACK_DIR>/plan.md`, verify both documents with isolated zero-context reviewer subagents, resolve findings into `<TRACK_DIR>/design_audit_report.md`, and lock the **Stage 3 Human Gate** before any production code is written.

Reference materials:
- Upstream Brainstorm & Draft Intake: `${PLUGIN_ROOT}/resources/tactics/design-brainstorm.md`, `${PLUGIN_ROOT}/resources/tactics/design-draft.md`
- Zero-Context Design Review & Loop: `${PLUGIN_ROOT}/resources/tactics/design-review.md`, `${PLUGIN_ROOT}/resources/tactics/design-review-loop.md`
- Finding Resolution Protocol: `${PLUGIN_ROOT}/resources/tactics/design-resolve.md`
- Document Standards: `${PLUGIN_ROOT}/resources/standards/*.md`
- Empirical Subsystem Trace: `${PLUGIN_ROOT}/resources/tactics/how.md`, `${PLUGIN_ROOT}/resources/tactics/why.md`

---

## Operational Standards (Phase 1 Invariants)

1. **Zero Production Code:** Do not write or edit application source code during `new-track`.
2. **Artifact-First Delivery:** Write `concepts_brief.md`, `spec.md`, `plan.md`, and `design_audit_report.md` to `<TRACK_DIR>/` on disk before summarizing and linking them in chat.
3. **Empirical Trace Before Asking (`Classify before AskQuestion`):** Trace existing modules and callers yourself using `${PLUGIN_ROOT}/resources/tactics/how.md` and `why.md`. Reserve developer questions for product intent, scope boundaries, and architectural trade-offs (`Author Decides Architecture`: up to 3 options with mechanisms, trade-offs, and failure conditions).
4. **Direct, Sequential Communication:** No flattery (`No Glazing`) or apologies. Ask strictly **one question per turn** following `${PLUGIN_ROOT}/rules/interactive-questions.md`.

---

## 1. Handshake & Monorepo Conductor Resolution (`<CONDUCTOR_DIR>`)

1. **Discover Candidate Conductors:**
   ```bash
   python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py" --list-conductors
   ```
   - If the current working directory already contains `./conductor/index.md`, or if the user named a target module/path (for example `packages/auth`), set `<CONDUCTOR_DIR>` to that module's `conductor` directory.
   - If running from a monorepo root where **multiple** `conductor` directories exist and target scope is unspecified, prompt via a single-select question choosing between the discovered module conductors and root `conductor`.
   - Otherwise default `<CONDUCTOR_DIR>` to `./conductor`.
   - If `<CONDUCTOR_DIR>/index.md` is missing, offer to run `${PLUGIN_ROOT}/skills/setup/SKILL.md` for `<CONDUCTOR_DIR>` first.

2. **Verify Context & Assemble `AuditContext`:**
   ```bash
   python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py" --conductor-dir "<CONDUCTOR_DIR>"
   ```
   Verify that `product.md`, `tech-stack.md`, `security-policy.md`, and `workflow.md` appear in `project_context` or `inherited_context`. Retain the returned `audit_context` list for Stages 5, 7, 8, and 9.

---

## 2. Track Intake, Brainstorm Check & Specification (`<TRACK_DIR>/spec.md`)

### 2.1 Polymorphic Concept Intake & Living Design Lookup
Follow `${PLUGIN_ROOT}/resources/tactics/design-draft.md` (with `<MODULE_ROOT>` set to the parent directory of `<CONDUCTOR_DIR>`):
1. Check if `./concepts_brief.md` or a `Status: Proposed` document in `<MODULE_ROOT>/docs/designs/*.md` already exists from a prior `brainstorm` run. Also inspect `<MODULE_ROOT>/docs/designs/README.md` and read any matching `Status: Active` `<MODULE_ROOT>/docs/designs/<subsystem>.md` so existing subsystem architecture and previously rejected alternatives are honored. Do **not** overwrite an `Active` document in `docs/designs/` during Phase 1 before code is implemented.
2. If no brief exists:
   - Gather the track description and run a silent codebase trace (`how.md`, `why.md`).
   - Classify track type: `feature`, `mvp`, `refactor`, `perf`, `bug`, or `chore`.
   - For a raw `feature`, `mvp`, or architectural `refactor` with unsettled trade-offs, offer a single-select gate:
     1. `(Recommended) Run 7-Lens Brainstorm first (open-ended drilling + parallel 7-lens critique into concepts_brief.md)`
     2. `Proceed directly to spec.md drafting (requirements and trade-offs are settled)`
   - If Option 1 is selected, execute `${PLUGIN_ROOT}/skills/brainstorm/SKILL.md` Steps 1 to 3 first.

### 2.2 Initialize `<TRACK_DIR>` & Draft `spec.md`
1. Generate `<track_id>` (`<shortname>_YYYYMMDD`) ensuring it does not collide with any existing track across the repository, identify the target `<subsystem>` slug (for `<MODULE_ROOT>/docs/designs/<subsystem>.md`), and set `<TRACK_DIR>` to `<CONDUCTOR_DIR>/tracks/<track_id>`.
2. Create `<TRACK_DIR>/`, move or copy `concepts_brief.md` into `<TRACK_DIR>/concepts_brief.md` if present, and write `<TRACK_DIR>/metadata.json`:
   ```json
   {
     "track_id": "<track_id>",
     "conductor_dir": "<CONDUCTOR_DIR>",
     "subsystem": "<subsystem>",
     "type": "<feature|mvp|bug|refactor|perf|chore>",
     "status": "draft",
     "phase_mode": "Phase 1 (Spec & Zero-Context Audit)",
     "design_audited": false,
     "human_gate_approved": false
   }
   ```
3. For non-trivial `feature`, `mvp`, or `refactor` tracks, ask the developer to select a **Drafting Cadence**:
   - `(Recommended) Consolidated spec.md draft` (write the complete initial `spec.md` in one pass for review)
   - `Section-by-Section interactive drafting` (approve `Why & Goals`, `Technical Design`, and `Alternatives Considered` step by step per `${PLUGIN_ROOT}/resources/tactics/design-draft.md`)
4. Resolve any remaining architectural trade-offs (`Author Decides Architecture`), then write `<TRACK_DIR>/spec.md` following `${PLUGIN_ROOT}/resources/templates/design_doc.md` and the matching standard in `${PLUGIN_ROOT}/resources/standards/`:
   - `## Why` (Overview & Problem Statement)
   - `## Goals & Non-Goals`
   - `## Domain Data Shape & Invariants` (core types, state transitions, and boundary validations per `security-policy.md`)
   - `## Technical Design & Functional Requirements`
   - `## Alternatives Considered` (carried from `concepts_brief.md` plus rejected spec options)
   - `## Acceptance Criteria & Verification Surface`
5. If `concepts_brief.md` was ingested, reconcile `<TRACK_DIR>/spec.md` against `concepts_brief.md` (`design-draft.md` Step 6.1) and flag any contradiction or new architectural interface before proceeding.
6. Link `<TRACK_DIR>/spec.md` in chat and ask via single-select gate whether to **Approve `spec.md` and Draft `plan.md`** or **Revise `spec.md`**.

---

## 3. Phased Plan Generation & Structural Validation (`<TRACK_DIR>/plan.md`)

1. Read confirmed `<TRACK_DIR>/spec.md` and `workflow.md`, then write `<TRACK_DIR>/plan.md` containing:
   - `# Implementation Plan: <Track Title>`
   - `## Throughput Checkpoint` (`${PLUGIN_ROOT}/resources/playbooks/feature.md`: blocking first steps, independent workstreams, shared mutable state, smallest verifiable decomposition)
   - `## Phase 1: ...` (and subsequent `## Phase N: ...` sections) with checkbox tasks (`- [ ] Task: ...`), ensuring behavioral Red reproduction/check tasks precede Green implementation tasks and ending each phase with `- [ ] Task: Phase Verification & Checkpoint (see workflow.md)`. Phases run uninterrupted without human pauses by default; append `[human-gate]` to a `## Phase N: ... [human-gate]` heading **only** when the developer explicitly requests a manual/visual review pause for that specific phase (never add `[human-gate]` unprompted).
2. Validate `<TRACK_DIR>/plan.md` structurally before review:
   ```bash
   node "${PLUGIN_ROOT}/scripts/check-plan.mjs" "<TRACK_DIR>/plan.md"
   ```
   Fix any reported formatting issues until `check-plan.mjs` exits `0`.
3. Link `<TRACK_DIR>/plan.md` in chat and ask whether to **Proceed to 5-Stage Zero-Context Cross-Verification** or **Revise `plan.md`**.

---

## 4. 5-Stage Zero-Context Subagent Cross-Verification

Subject `<TRACK_DIR>/spec.md` and `<TRACK_DIR>/plan.md` to isolated subagent review (`${PLUGIN_ROOT}/resources/tactics/design-review.md` and `design-review-loop.md`):
- **Antigravity:** `invoke_subagent` with `TypeName` (`zoom-out`, `inventive-catalyst`, `comprehension`, `design-critic`, `structural`, `style`, `implementation-readiness`, `codebase-details`).
- **Claude Code:** `Agent` tool dispatched directly from the primary session with `subagent_type: "fluctseed:<name>"`.
- **Codex CLI:** `spawn_agent` (read-only explorer role) reading `${PLUGIN_ROOT}/agents/<name>.md` first.

> [!IMPORTANT]
> Never review your own draft inside the primary session context. Keep Stages 5, 6, 7, 8, and 9 sequential (parallelizing only reviewers within the same stage).

### 4.1 Stage Binding (`FeatureRange` & `DetailedRange`)
1. **Stage 5 (`Zoom Out`):** Spawn `zoom-out` on `<TRACK_DIR>/spec.md` with `${PLUGIN_ROOT}/resources/standards/zoom-out-standard.md` + `audit_context`.
2. **Stage 6 (`Comprehension Test`):** Spawn `comprehension` on `<TRACK_DIR>/spec.md` and `<TRACK_DIR>/plan.md` **with NO `audit_context`** (and in Codex CLI explicitly instruct ignoring repository `AGENTS.md`) to test standalone clarity and produce the fresh-eyes paraphrase.
3. **Stage 7 (`Critic Review`):** Spawn `design-critic`, `structural`, and `style` in parallel on `<TRACK_DIR>/spec.md` with `audit_context` and the standard matching `metadata.json` `"type"`:
   - `feature`, `bug`, `perf`, or `chore`: `${PLUGIN_ROOT}/resources/standards/feature-spec-standard.md`
   - `mvp` (or research/greenfield bets): `${PLUGIN_ROOT}/resources/standards/feature-spec-standard.md` + `${PLUGIN_ROOT}/resources/standards/heilmeier-standard.md`
   - `refactor` (or migration/rewrite): `${PLUGIN_ROOT}/resources/standards/re-implementation-standard.md`
4. **Stage 8 (`Inventive Catalyst`):** Spawn `inventive-catalyst` on `<TRACK_DIR>/spec.md` with `${PLUGIN_ROOT}/resources/standards/zoom-out-standard.md` + `audit_context`.
5. **Stage 9 (`Implementation Readiness`):** Spawn `implementation-readiness`, `codebase-details`, and `style` in parallel on `<TRACK_DIR>/plan.md` with `${PLUGIN_ROOT}/resources/standards/implementation-readiness-standard.md` + `audit_context`.

*(Offer the developer a single-select choice between **Consolidated Uninterrupted Audit (Stages 5 to 9)** and **Interactive Stage-by-Stage Review** before launching Stage 5.)*

### 4.2 Primary Session Resolution (`design_audit_report.md`)
1. Follow `${PLUGIN_ROOT}/resources/tactics/design-resolve.md`. Classify every finding as `PROPOSE FIX`, `CONTEST` (citing checkable `[file:symbol]` or `<CONDUCTOR_DIR>/` evidence), `ESCALATE`, or `DECLINE`.
2. Write the consolidated report (including reviewer completion status, Stage 6 paraphrase, and all classified findings) to **`<TRACK_DIR>/design_audit_report.md`**.
3. Present the Resolution Gate (`(Recommended) Apply all proposed fixes`, `Review findings one by one`, `Edit manually`, or `Continue without changes`), apply approved edits to `spec.md` and `plan.md`, and re-run `node "${PLUGIN_ROOT}/scripts/check-plan.mjs" "<TRACK_DIR>/plan.md"`.

---

## 5. Stage 3: Developer Approval (Human Gate Lock)

1. Link `<TRACK_DIR>/spec.md`, `<TRACK_DIR>/plan.md`, and `<TRACK_DIR>/design_audit_report.md`, highlight any `ESCALATE` decisions, and present the **Stage 3 Human Gate** single-select question:
   1. `(Recommended) Approve & Lock Track for Implementation`
   2. `Revise Specification or Plan`
   3. `Re-run Zero-Context Audit`

2. **Execute Only Upon Explicit Developer Selection of Option 1:**
   - Write `<TRACK_DIR>/index.md` linking `./spec.md`, `./plan.md`, `./design_audit_report.md`, `./decisions.tsv`, and `./metadata.json` (plus `./concepts_brief.md` if present).
   - Initialize `<TRACK_DIR>/decisions.tsv` and log approval:
     ```bash
     "${PLUGIN_ROOT}/scripts/log.sh" "<TRACK_DIR>/decisions.tsv" "new-track" "approved spec and plan after zero-context design audit" "passed Stage 3 Human Gate" "design_audit_report.md" "approved"
     ```
   - Lock `spec_sha256`, `plan_structure_sha256`, and `base_sha` in `<TRACK_DIR>/metadata.json`:
     ```bash
     python3 "${PLUGIN_ROOT}/scripts/gate_check.py" --approve "<TRACK_DIR>" --conductor-dir "<CONDUCTOR_DIR>"
     ```
   - Append the track entry to standalone `<CONDUCTOR_DIR>/tracks.md` (creating `<CONDUCTOR_DIR>/tracks.md` if absent; **never** link `tracks.md` or `tracks/` inside `<CONDUCTOR_DIR>/index.md`, `product.md`, `product-guidelines.md`, `tech-stack.md`, `security-policy.md`, or `workflow.md`):
     ```markdown
     ---
     - [ ] **Track: <Track Description>**
       *Link: [./tracks/<track_id>/index.md](./tracks/<track_id>/index.md)*
     ```
   - Stage `<CONDUCTOR_DIR>/tracks.md` and `<TRACK_DIR>/` and commit:
     `chore(conductor): create and approve track '<track_id>'`
   - Announce that the Stage 3 Human Gate is locked and ready for `implement`.
