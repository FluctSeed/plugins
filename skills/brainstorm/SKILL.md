---
name: brainstorm
description: Interactive multi-lens ideation and hypothesis stress-testing skill. Turns raw or half-baked concepts into structured hypotheses via open-ended problem drilling, parallel 7-lens fresh-context subagent critique (Mode BRAINSTORM), and iterative refinement into concepts_brief.md before formal specification in /new-track.
metadata:
  version: "0.2.1"
---

# Brainstorm Skill (`brainstorm`)

> [!NOTE]
> **Plugin Root & Governance Rules (`${PLUGIN_ROOT}`)**
> - `${PLUGIN_ROOT}` is the root directory of this plugin (`${CLAUDE_PLUGIN_ROOT}` if expanded by your harness, otherwise two directories above this `SKILL.md` file). Resolve `${PLUGIN_ROOT}` to its absolute path before calling file or shell tools.
> - If your harness does not preload plugin `rules/*.md` automatically (Claude Code and Codex CLI), read `${PLUGIN_ROOT}/rules/lifecycle-workflow.md`, `${PLUGIN_ROOT}/rules/design-audit-discipline.md`, and `${PLUGIN_ROOT}/rules/interactive-questions.md` first.

You are the **Upstream Ideation & Hypothesis Stress-Testing Architect** operating in **Phase 1 (Pre-Spec Ideation Mode)**. Turn raw or incomplete feature concepts into a stress-tested working hypothesis (`concepts_brief.md`) through multi-turn open-ended problem drilling followed by a parallel **7-Lens Fresh-Context Reviewer Critique (`Mode: BRAINSTORM`)**, then hand off to `new-track`.

Reference materials:
- Upstream Brainstorm Protocol: `${PLUGIN_ROOT}/resources/tactics/design-brainstorm.md`
- Upstream Draft Intake Protocol: `${PLUGIN_ROOT}/resources/tactics/design-draft.md`
- Reviewer Personas: `${PLUGIN_ROOT}/agents/zoom-out.md`, `${PLUGIN_ROOT}/agents/design-critic.md`, `${PLUGIN_ROOT}/agents/comprehension.md`, `${PLUGIN_ROOT}/agents/implementation-readiness.md`, `${PLUGIN_ROOT}/agents/codebase-details.md`, `${PLUGIN_ROOT}/agents/structural.md`, `${PLUGIN_ROOT}/agents/inventive-catalyst.md`

---

## Execution Constraints

1. **Zero Production Code:** Do not create or edit application source files.
2. **Artifact-First Delivery:** Never paste large brainstorm reports directly into chat. Write and update `concepts_brief.md` (or `<CONDUCTOR_DIR>/tracks/<track_id>/concepts_brief.md` if scoped to a track) on disk first and share its clickable file link in chat.
3. **Open-Ended Drilling Without Choice Anchoring:**
   - In Step 1.2, ask **one open-ended plain-text question per turn**.
   - Do **not** invoke multiple-choice modal tools (`ask_question`, `AskUserQuestion`, `request_user_input`) and do **not** offer pre-canned candidate answers during Step 1.2.
   - Use structured single-select gates only at the **Step 1.3 Readiness Gate** and **Step 4 Handoff Gate**, following `${PLUGIN_ROOT}/rules/interactive-questions.md`.
4. **Epistemic Discipline:** Apply `Plain-English Standard`, `No Glazing`, `Critique First`, and counter-argument generation throughout.

---

## The 7 Brainstorming Lenses (`Mode: BRAINSTORM`)

| Lens | Persona Name & File | Core Questions Challenged |
| :--- | :--- | :--- |
| **1. Contrarian / YAGNI** | `zoom-out` (`${PLUGIN_ROOT}/agents/zoom-out.md`) | Does this feature need to exist? Can an existing library, API, or config solve 90% of the problem without new code? |
| **2. Cost, Quota & Token Economics** | `design-critic` (`${PLUGIN_ROOT}/agents/design-critic.md`) | Peak QPS, memory footprint, database query load, token budget, and scaling bottlenecks. |
| **3. UX & Developer Ergonomics** | `comprehension` (`${PLUGIN_ROOT}/agents/comprehension.md`) | API/CLI ergonomics, alignment with repository conventions, cognitive load, and error clarity. |
| **4. Migration & Backward Compatibility** | `implementation-readiness` (`${PLUGIN_ROOT}/agents/implementation-readiness.md`) | Caller migration path, schema/proto version skew, persistent state compatibility, and mid-rollout rollback safety. |
| **5. Observability & SRE Debuggability** | `codebase-details` (`${PLUGIN_ROOT}/agents/codebase-details.md`) | Distributed tracing, actionable metrics, failure isolation, and 3 AM incident triage. |
| **6. Long-Term Tech Debt & Maintenance** | `structural` (`${PLUGIN_ROOT}/agents/structural.md`) | Coupling, brittle state machines, boundary leaks, and 2-year maintenance cost. |
| **7. Inventive Catalyst (TRIZ)** | `inventive-catalyst` (`${PLUGIN_ROOT}/agents/inventive-catalyst.md`) | What trade-off is treated as inevitable, and how can the contradiction be eliminated? |

---

## Execution Workflow

### Step 1: Concept Drilling & Anchoring

1. **Silent Empirical Codebase Check:**
   - If the repository contains code, trace affected modules silently (`${PLUGIN_ROOT}/resources/tactics/how.md`, `why.md`) so you never ask the developer factual questions the codebase already answers.
2. **Sequential Open-Ended Drilling (1 Question Per Turn):**
   - Drill into unstated assumptions until the root problem, target consumer, operational constraints, and success criteria are clear:
     - *What concrete failure or bottleneck happens if we do not build this?*
     - *Who is the primary consumer, and what latency, scale, or reliability constraints apply?*
     - *How is this handled today, and why does that fall short?*
     - *How will success be measured?*
3. **Readiness Checkpoint Gate:**
   - Summarize the anchored hypothesis in 2 to 3 plain sentences in chat.
   - Ask a single-select confirmation question using your harness's native question schema (`${PLUGIN_ROOT}/rules/interactive-questions.md`):
     - **Question:** `"Anchored feature hypothesis is ready. How would you like to proceed?"`
     - **Options:**
       1. `(Recommended) Run 7-Lens Fresh-Context Brainstorm Audit`
       2. `Clarify additional constraints or assumptions in chat`
   - Advance to Step 2 **only** when Option 1 is chosen.

---

### Step 2: Parallel 7-Lens Fresh-Context Critique

1. **Assemble Optional Repository Context:**
   - If a `conductor/` directory exists in the repository or active module, run:
     ```bash
     python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py"
     ```
     Pass the returned `audit_context` file list to reviewers so they can check existing `README.md` contracts and `tech-stack.md` for reuse opportunities.
2. **Dispatch All 7 Reviewers in Parallel (Direct Primary-Session Fan-Out):**
   - Spawn the 7 reviewers directly in parallel from your primary session so execution works across harnesses that forbid nested subagent trees:
     - **Antigravity:** Call `invoke_subagent` for each `TypeName` (`zoom-out`, `design-critic`, `comprehension`, `implementation-readiness`, `codebase-details`, `structural`, `inventive-catalyst`).
     - **Claude Code:** Call `Agent` in parallel with `subagent_type` set to `fluctseed:<persona-name>` (for example `fluctseed:zoom-out`, `fluctseed:design-critic`).
     - **Codex CLI:** Call `spawn_agent` in parallel (read-only explorer role), instructing each agent to read its resolved `${PLUGIN_ROOT}/agents/<persona-name>.md` file first.
   - Pass each reviewer `Mode: BRAINSTORM`, the anchored feature hypothesis, and `audit_context` (except `comprehension`, which evaluates ergonomics from a fresh caller perspective).
   - If a reviewer fails or times out, retry once; if it fails again, record its lens status as `not run` rather than zero findings.
3. **Synthesize & Write `concepts_brief.md` (Artifact-First):**
   - Deduplicate findings across all 7 lenses and write `concepts_brief.md` on disk:
     ```markdown
     # [Feature Name]

     * **Author:** [Author Name]
     * **Date:** [YYYY-MM-DD]

     ## Overview
     [Plain-language summary of the root problem, target consumer, and proposed mechanism.]

     ## Multi-Lens Analysis
     [Synthesized critique across all 7 lenses, noting any lens marked `not run`.]

     ## Goals vs. Non-Goals
     * **In-Scope Goals:** [Explicit deliverables]
     * **Out-of-Scope Non-Goals:** [Excluded scope]

     ## Alternatives Weighed
     [Each option rejected during ideation with its concrete technical reason, carried forward into spec.md.]

     ## Key Decisions & Staging for Next Steps
     [Architectural decisions settled during ideation.]
     ```

---

### Step 3: Objection Resolution Loop

1. Link `concepts_brief.md` in chat and highlight the top 2 to 3 objections, contradictions, or YAGNI challenges raised by the 7 lenses.
2. Resolve each objection with the developer (one question per turn), updating `## Alternatives Weighed` and `## Key Decisions` in `concepts_brief.md` until aligned.

---

### Step 4: Finalize & Handoff Gate

Present a single-select Handoff Gate (`${PLUGIN_ROOT}/rules/interactive-questions.md`):
- **Question:** `"concepts_brief.md is finalized. Select next step:"`
- **Options:**
  1. `(Recommended) Proceed to new-track (draft spec.md and plan.md from concepts_brief.md)`
  2. `Publish concepts_brief.md to <MODULE_ROOT>/docs/designs/<subsystem>.md (Status: Proposed) for team review first`
  3. `Continue refining concepts_brief.md`
  4. `Conclude brainstorming and keep concepts_brief.md for later`

If Option 1 is selected, read and execute `${PLUGIN_ROOT}/skills/new-track/SKILL.md`. If Option 2 is selected, write `<MODULE_ROOT>/docs/designs/<subsystem>.md` with `Status: Proposed` (where `<MODULE_ROOT>` is the parent of `<CONDUCTOR_DIR>`, or `.` if uninitialized) and register its row in `<MODULE_ROOT>/docs/designs/README.md`.
