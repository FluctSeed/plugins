---
name: status
description: Displays a unified progress dashboard of the project by parsing the Tracks Registry and track plans alongside zero-context design audit status, Stage 3 Human Gate locks, and decisions.tsv and verification.log trails, with full monorepo multi-module conductor support.
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

## 1. Handshake & Monorepo Conductor Discovery

1. **Discover All Conductors:**
   - Run `python3 ${PLUGIN_ROOT}/scripts/prepare_audit_context.py --list-conductors` to discover all `conductor/` directories in the monorepo.
   - If the user explicitly asks for a specific module in their request (e.g. `/status packages/auth` or "status of auth module"), scope inspection to that directory.
   - If no `conductor/index.md` is found anywhere, announce that project context is not initialized and ask a **Yes/No question** to run `/setup` (`skills/setup/SKILL.md`).

---

## 2. Status Collection Protocol

For each discovered `CONDUCTOR_DIR` (e.g. `./conductor` or `<module_path>/conductor`):
1. **Read Tracks Registry:**
   - Parse `<CONDUCTOR_DIR>/tracks.md` (if present) for registered tracks (`- [ ] **Track:`, `- [~] **Track:`, `- [x] **Track:`).
2. **Inspect Each Track Directory (`<CONDUCTOR_DIR>/tracks/<track_id>/`):**
   - Run `python3 ${PLUGIN_ROOT}/scripts/gate_check.py --status <track_id_or_path>` to read `metadata.json` and artifact existence flags.
   - Read `plan.md` to count total phases, total tasks, completed tasks (`[x]`), in-progress tasks (`[~]`), and pending tasks (`[ ]`).
   - If `decisions.tsv` exists, count the logged decisions and read the last 1–2 rows.
   - If `verification.log` exists, read the last `[VERIFY END]` line to extract the latest `ExitCode` and `OutputSHA256`.

---

## 3. Present Unified Status Dashboard

Output the status overview in clean, unslopped Markdown:

```markdown
# Project Status Dashboard

- **Timestamp:** `<ISO-8601 current time>`
- **Monorepo Mode:** `[Single Module | Monorepo Multi-Module (<count> modules)]`
- **Overall Health:** `[On Track | Awaiting Human Gate | Blocked | Ready for Review]`
```

### Monorepo Module Overview (if >1 conductor exists):

```markdown
| Module / Directory | Tracks (Done/Total) | Active Mode | Stage 3 Gate | Decisions Trail | Latest Runtime Proof |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `packages/auth` (`packages/auth/conductor/`) | 1 / 2 | Phase 2 (Implementation) | Locked & Approved | 14 rows | PASS (Exit 0) |
| `packages/billing` (`packages/billing/conductor/`) | 0 / 1 | Phase 1 (Zero-Context Audit) | Pending Developer Gate | 4 rows | - |
| Root Monorepo (`conductor/`) | 3 / 3 | Stable | Locked & Approved | 38 rows | PASS (Exit 0) |
```

### Active & Recent Tracks Detail:

```markdown
### Track: `<track_id>` (`<type>`) [Module: `<module_path>`]
- **Active Mode:** `[Phase 1: Spec & Zero-Context Audit | Stage 3: Awaiting Human Gate | Phase 2: Empirical Implementation | Stage 5: Verified / Reviewed]`
- **Zero-Context Design Audit:** `[Completed (design_audit_report.md) | Pending]`
- **Stage 3 Human Gate:** `[Locked & Approved | Pending Developer Approval]`
- **Plan Progress:** `<completed>/<total>` tasks (`<percentage>%`) across `<phases>` phases
- **Current Task (`[~]`):** `<current in-progress task or None>`
- **Next Action (`[ ]`):** `<next pending task or Next Lifecycle Command>`
- **Decisions Logged:** `<count>` entries in `decisions.tsv` (Latest: `<decision>`)
- **Runtime Proof:** `[Exit Code 0 (SHA: <hash>) in verification.log | Not yet run]`
```
