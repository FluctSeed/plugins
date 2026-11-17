---
name: new-track
description: Plans a new track (feature, bug fix, refactor, or perf). Ingests concepts_brief.md from /brainstorm (or runs 7-lens brainstorming for raw feature concepts), drafts spec.md and plan.md, runs 5-stage zero-context subagent cross-verification (Stages 5-9) and finding resolution, and enforces the Stage 3 Human Gate approval lock.
metadata:
  version: "2.1"
---

# New Track Skill (`/new-track`)

You are the **Track Planner & Lead Architect** operating in **Phase 1 (Pre-Gate Ideation, Specification, Zero-Context Audit & Human Gate)**. Your goal is to guide the developer from an initial concept (or an existing `concepts_brief.md` from `/brainstorm`) through drafting `spec.md` and `plan.md`, subject both documents to **independent, zero-context subagent verification**, resolve findings transparently, and secure **Stage 3 Human Gate Approval** before a single line of production code is written.

Reference materials:
- Upstream Brainstorm & Draft Intake: `../../resources/tactics/design-brainstorm.md`, `../../resources/tactics/design-draft.md`
- Zero-Context Design Review & Loop: `../../resources/tactics/design-review.md`, `../../resources/tactics/design-review-loop.md`
- Finding Resolution Protocol: `../../resources/tactics/design-resolve.md`
- Document Standards: `../../resources/standards/*.md`
- Empirical Subsystem Trace: `../../resources/tactics/how.md`, `../../resources/tactics/why.md`

---

## Operational Standards (Phase 1 Invariants)

1. **Zero Production Code:** Do not write or edit application source code during `/new-track`.
2. **Artifact-First Delivery (Mandatory):** Never dump full drafts of `concepts_brief.md`, `spec.md`, `plan.md`, or `design_audit_report.md` directly into the chat window. Write them to `conductor/tracks/<track_id>/` using file-writing tools first, then share the clickable file link and a concise summary in chat.
3. **Empirical Fact-Checking Before Asking (`Classify before AskQuestion`):**
   - Before asking the user how an existing module works, what callers exist, or why code was structured a certain way, trace the codebase yourself using `resources/tactics/how.md` and `why.md`.
   - Reserve human questions strictly for **product intent, scope boundaries, and architectural trade-offs** (`Author Decides Architecture`: present up to 3 defensible options with mechanism, trade-offs, and failure modes).
4. **No Glazing & Sequential Questioning:**
   - Do not use flattery ("great idea," "brilliant") or apologies.
   - Ask strictly **one question per turn**.

---

## 1. Handshake & Context Initialization

1. **Locate Index:** Check for `conductor/index.md` in the project root.
   - If missing, inform the user that project context is not initialized and ask a **Yes/No question** to run `/setup` (`skills/setup/SKILL.md`) now.
2. **Load & Verify Context:** Read `conductor/index.md` and verify the existence of:
   - `conductor/product.md`
   - `conductor/product-guidelines.md`
   - `conductor/tech-stack.md`
   - `conductor/security-policy.md` (if present)
   - `conductor/workflow.md`
   - If any core file is missing, halt and offer to run `/setup` to repair the environment.
3. **Prepare Baseline `AuditContext`:**
   - Run `python3 scripts/prepare_audit_context.py` to obtain the list of repository context files (`conductor/*.md`, `conductor/code_styleguides/*.md`, and directory `README.md` architecture contracts) that will be passed to fresh-context reviewers.

---

## 2. Track Intake, Brainstorm Check & Specification (`spec.md`)

### 2.1 Polymorphic Concept Intake & 7-Lens Brainstorm Check
Follow the polymorphic intake priority from `resources/tactics/design-draft.md`:

1. **Check for Existing Ideation Brief (`concepts_brief.md`):**
   - Check if `./concepts_brief.md` or `conductor/rfcs/*.md` already exists from a prior `/brainstorm` run.
   - **If found:** Ingest `concepts_brief.md` directly (preserving `Author`, `Overview`, `Goals vs. Non-Goals`, `Alternatives Weighed`, and `Key Decisions`), confirm with the user, and move directly to **Step 2.2 (Track Workspace & `spec.md` Drafting)**.
2. **If No `concepts_brief.md` Exists:**
   - Acquire the track description from the user (if not provided in the prompt) and run an empirical subsystem trace (`resources/tactics/how.md`, `why.md`) on the affected codebase area.
   - Classify the track type: `feature`, `mvp`, `refactor`, `perf`, `bug`, or `chore`.
   - **Brainstorm Routing Gate (for `feature`, `mvp`, or architectural `refactor`):**
     - If the concept is raw or involves architectural trade-offs that have not yet been stress-tested across the 7 lenses, ask the user via a single-select question:
       - **Run 7-Lens Brainstorm first (`/brainstorm` — open-ended drilling + parallel 7-lens critique into `concepts_brief.md`)**
       - **Proceed directly to `spec.md` drafting (requirements and trade-offs are already settled)**
     - If the user selects **Run 7-Lens Brainstorm first**, execute `skills/brainstorm/SKILL.md` (Steps 1–3) to produce `conductor/tracks/<track_id>/concepts_brief.md` before continuing to Step 2.2.

### 2.2 Initialize Track Workspace & Draft `spec.md` (`conductor/tracks/<track_id>/spec.md`)
1. **Create Track Directory & Metadata:**
   - Generate a unique `<track_id>` (e.g., `<shortname>_YYYYMMDD`) and create `conductor/tracks/<track_id>/`.
   - If `./concepts_brief.md` was used, copy or move it into `conductor/tracks/<track_id>/concepts_brief.md`.
   - Initialize `conductor/tracks/<track_id>/metadata.json`:
     ```json
     {
       "track_id": "<track_id>",
       "type": "<type>",
       "status": "draft",
       "phase_mode": "Phase 1 (Spec & Zero-Context Audit)",
       "design_audited": false,
       "human_gate_approved": false
     }
     ```
2. **Interactive Clarification (for any remaining unresolved choices):**
   - If any architectural decision has multiple defensible options (data model, component boundary, storage, protocol), present up to 3 options with mechanisms, trade-offs, and failure conditions (`Author Decides Architecture`).
3. **Write `spec.md` (Artifact-First, Section-by-Section or Consolidated):**
   - Write `conductor/tracks/<track_id>/spec.md` following `resources/templates/design_doc.md` and `resources/standards/feature-spec-standard.md`:
     - **Overview & Problem Statement (`## Why`)**
     - **Goals & Non-Goals (Out of Scope)**
     - **Domain Data Shape & Invariants (`principle-model-the-domain`)**: Core types, state machine transitions, and boundary validations (`security-policy.md`).
     - **Technical Design & Functional Requirements**: Component boundaries, API/CLI contracts, and data flow diagrams.
     - **Alternatives Considered**: Carried forward from `concepts_brief.md` (`## Alternatives Weighed`) plus any options rejected during spec drafting.
     - **Acceptance Criteria & Verification Surface**
4. **Initial Author Check:**
   - Link `conductor/tracks/<track_id>/spec.md` in chat, summarize 2–3 key decisions, and ask the user whether to **Approve `spec.md` and Proceed to Plan Generation (`plan.md`)** or **Request Revisions to `spec.md`**.

---

## 3. Interactive Plan Generation (`conductor/tracks/<track_id>/plan.md`)

1. **Generate `plan.md` (Phased Hierarchy + Throughput Checkpoint):**
   - Read the confirmed `spec.md` and `conductor/workflow.md`.
   - Write `conductor/tracks/<track_id>/plan.md` containing:
     - **Section 1: Throughput Checkpoint (`resources/playbooks/feature.md`)**
       - *Blocking first steps* (gates before fan-out)
       - *Independent workstreams* (disjoint files/modules)
       - *Shared mutable state* (`principle-separate-before-serializing-shared-state`)
       - *Smallest safe decomposition* (`principle-sequence-verifiable-units`)
     - **Section 2: Phased Implementation Tasks (`## Detailed Implementation Plan`)**
       - Hierarchical list of Phases (`## Phase 1: ...`), Tasks (`- [ ] Task: ...`), and Sub-tasks (`- [ ] ...`).
       - Ensure Empirical Red tasks ("Reproduce & Write Failing Behavioral Check") precede Green implementation tasks, and append `- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)` at the end of each phase.
2. **Initial Author Check:**
   - Link `conductor/tracks/<track_id>/plan.md` in chat and ask the user whether to **Proceed to 5-Stage Zero-Context Cross-Verification** or **Revise `plan.md`**.

---

## 4. 5-Stage Zero-Context Subagent Cross-Verification

Before a human developer can approve the track for implementation, you MUST subject `spec.md` and `plan.md` to **independent review in isolated subagent contexts** (`invoke_subagent` in Antigravity, `Agent` in Claude Code, `spawn_agent` in Codex).

> **CRITICAL:** Never simulate an independent design audit in your own primary conversation context. If your harness has no subagent tool, explicitly warn the user that zero-context isolation is unavailable.

### 4.1 Semantic Direct Binding (`FeatureRange` & `DetailedRange`)
Bind the two track artifacts directly to the five review stages (see `resources/tactics/design-review.md` and `resources/tactics/design-review-loop.md`):

1. **Target A — `spec.md` (`FeatureRange` Audit):**
   - **Stage 5 & 8 (`Zoom Out` & `Inventive Catalyst`):** Spawn subagent(s) reading `agents/zoom_out.md` and `agents/inventive_catalyst.md` against `conductor/tracks/<track_id>/spec.md` using `resources/standards/zoom-out-standard.md` + `AuditContext`.
   - **Stage 6 (`Comprehension Test`):** Spawn subagent reading `agents/comprehension.md` on `spec.md` and `plan.md` **with NO `AuditContext`** to test self-containment and produce the fresh-eyes paraphrase.
   - **Stage 7 (`Critic Review`):** Spawn subagents reading `agents/design_critic.md`, `agents/structural.md`, and `agents/style.md` against `spec.md` using `resources/standards/feature-spec-standard.md` + `AuditContext`.

2. **Target B — `plan.md` (`DetailedRange` Audit):**
   - **Stage 9 (`Implementation Readiness Test`):** Spawn subagents reading `agents/implementation_readiness.md`, `agents/codebase_details.md`, and `agents/style.md` against `conductor/tracks/<track_id>/plan.md` using `resources/standards/implementation-readiness-standard.md` + `AuditContext`.

*(Offer the user the preset choice from `design-review.md` — **Consolidated Uninterrupted Audit** or **Step-by-Step Interactive Stages 5→9** — via a single-select question.)*

### 4.2 Primary Session Resolution (`design-resolve` Protocol)
Once the fresh-context subagents return their findings:
1. Read and follow `resources/tactics/design-resolve.md`.
2. In your primary context, evaluate every finding and assign exactly one category:
   - **`PROPOSE FIX`**: Valid gap, edge case, or ambiguity. Draft the exact textual repair for `spec.md` or `plan.md`.
   - **`CONTEST`**: Inaccurate critique. You MUST cite checkable evidence (`[file:symbol]` or explicit line in `conductor/`) that the reviewer could read. ("This was intentional" is forbidden.)
   - **`ESCALATE`**: Requires unwritten team knowledge or a new product/architecture decision from the human developer.
   - **`DECLINE`**: Minor stylistic nit not worth changing.
3. Write the annotated report (including Stage 6's comprehension paraphrase and all prioritized findings) to **`conductor/tracks/<track_id>/design_audit_report.md`**.
4. Present the **Interactive Resolution Gate** (`Auto accept proposed fixes`, `Interactive breakdown`, `Manual edit`, or `Continue without changes`) and apply all approved repairs to `spec.md` and `plan.md`.

---

## 5. Stage 3: Developer Approval (Human Gate Lock)

After audit findings are resolved and `spec.md` / `plan.md` are updated:

1. **Present the Stage 3 Human Gate:**
   - Provide clickable links to:
     - `conductor/tracks/<track_id>/spec.md`
     - `conductor/tracks/<track_id>/plan.md`
     - `conductor/tracks/<track_id>/design_audit_report.md`
   - Highlight any `ESCALATE` items or residual trade-offs.
   - Ask the developer for **Final Stage 3 Human Gate Approval** using a single-choice question:
     - **Approve & Lock Track for Implementation (`/implement`)**
     - **Revise Specification or Plan**
     - **Re-run Zero-Context Audit Loop**

2. **Execute Human Gate Lock & Registry Update (Only Upon Explicit Approval):**
   - Create `conductor/tracks/<track_id>/index.md` linking to `./spec.md`, `./plan.md`, `./design_audit_report.md`, `./decisions.tsv`, and `./metadata.json` (plus `./concepts_brief.md` if present).
   - Initialize `conductor/tracks/<track_id>/decisions.tsv` from `resources/templates/decision-log-template.tsv` and log the track approval using `./scripts/log.sh`:
     ```bash
     ./scripts/log.sh conductor/tracks/<track_id>/decisions.tsv "new-track" "approved spec and plan after zero-context design audit" "passed Stage 3 Human Gate" "design_audit_report.md" "approved"
     ```
   - Lock the Human Gate and record SHA-256 hashes of `spec.md` and `plan.md`:
     ```bash
     python3 scripts/gate_check.py --approve <track_id>
     ```
   - Update `conductor/tracks.md` (and `conductor/index.md` if this is the first track) with:
     ```markdown
     ---
     - [ ] **Track: <Track Description>**
       *Link: [./tracks/<track_id>/index.md](./tracks/<track_id>/index.md)*
     ```
   - Stage `conductor/` and commit:
     `chore(tracks): initialize and approve track '<track_id>'`

3. **Completion & Handoff:**
   - Announce that Track `<track_id>` is audited, Human-Gate locked, and registered.
   - Ask the user via a **Yes/No question** if they would like to transition to **Phase 2 (`/implement`)** and start implementation now.
   - If approved, invoke the `implement` skill (`skills/implement/SKILL.md`).
