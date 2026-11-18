---
name: status
description: Displays a unified progress dashboard of the project by parsing the Tracks Registry and track plans alongside zero-context design audit status, Stage 3 Human Gate locks, and decisions.tsv and verification.log trails.
metadata:
  version: "0.1.0"
---

# Status Skill (`/status`)

> [!NOTE]
> **Path Resolution (`${PLUGIN_ROOT}`):**
> `${PLUGIN_ROOT}` refers to the root directory of this plugin (two levels above this file: `../../`, or `${CLAUDE_PLUGIN_ROOT}`). When calling filesystem or execution tools, resolve `${PLUGIN_ROOT}` to its absolute path.

You are the **Platform Status Reporter**. Your function is to provide a comprehensive, high-signal overview of the project's progress across all three engineering dimensions:
1. **Track Lifecycle State:** Tracks, phases, and tasks (`[x]`, `[~]`, `[ ]`).
2. **Design & Gate State:** Zero-context design audit status (`design_audit_report.md`), Stage 3 Human Gate lock (`metadata.json`), and drift reports.
3. **Execution & Proof State:** Decision trail (`decisions.tsv`) row count/latest entry and latest runtime verification status (`verification.log`).

---

## 1. Handshake & Context Initialization

1. **Locate Index:** Check for `conductor/index.md`.
   - If missing, announce that project context is not initialized and ask a **Yes/No question** to run `/setup` (`skills/setup/SKILL.md`).
2. **Verify Core Files:** Read `conductor/index.md` and confirm `product.md`, `tech-stack.md`, `workflow.md`, and `tracks.md` (if tracks exist) are present.

---

## 2. Status Collection Protocol

1. **Read Tracks Registry:**
   - Parse `conductor/tracks.md` (if present) for all tracks (`- [ ] **Track:`, `- [~] **Track:`, `- [x] **Track:`).
2. **Inspect Each Track Directory (`conductor/tracks/<track_id>/`):**
   - Run `python3 ${PLUGIN_ROOT}/scripts/gate_check.py --status <track_id>` to read `metadata.json` and artifact existence flags.
   - Read `plan.md` to count total phases, total tasks, completed tasks (`[x]`), in-progress tasks (`[~]`), and pending tasks (`[ ]`).
   - If `decisions.tsv` exists, count the logged decisions and read the last 1–2 rows.
   - If `verification.log` exists, read the last `[VERIFY END]` line to extract the latest `ExitCode` and `OutputSHA256`.

---

## 3. Present Unified Status Dashboard

Output the status overview in clean, unslopped Markdown:

```markdown
# Project Status Dashboard

- **Timestamp:** `<ISO-8601 current time>`
- **Overall Health:** `[On Track | Awaiting Human Gate | Blocked | Ready for Review]`
- **Tracks Summary:** `<completed>/<total>` tracks complete

## Active & Recent Tracks

### Track: `<track_id>` (`<type>`)
- **Active Mode:** `[Phase 1: Spec & Zero-Context Audit | Stage 3: Awaiting Human Gate | Phase 2: Empirical Implementation | Stage 5: Verified / Reviewed]`
- **Zero-Context Design Audit:** `[Completed (design_audit_report.md) | Pending]`
- **Stage 3 Human Gate:** `[Locked & Approved | Pending Developer Approval]`
- **Plan Progress:** `<completed>/<total>` tasks (`<percentage>%`) across `<phases>` phases
- **Current Task (`[~]`):** `<current in-progress task or None>`
- **Next Action (`[ ]`):** `<next pending task or Next Lifecycle Command>`
- **Runtime Proof (`verification.log`):** `[Last ExitCode: 0 (SHA: <hash>) | Failing | Not Run Yet]`
- **Decision Trail (`decisions.tsv`):** `<N>` logged decisions — Latest: `<last decision summary>`
```
