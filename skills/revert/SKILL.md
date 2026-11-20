---
name: revert
description: Reverts previous work (tracks, phases, or tasks) by reconciling Git commits with plan.md and appending an auditable superseding entry to the append-only decisions.tsv trail.
metadata:
  version: "0.2.1"
---

# Revert Skill (`revert`)

> [!NOTE]
> **Plugin Root & Governance Rules (`${PLUGIN_ROOT}`)**
> - `${PLUGIN_ROOT}` is the root directory of this plugin (`${CLAUDE_PLUGIN_ROOT}` if expanded by your harness, otherwise two directories above this `SKILL.md` file). Resolve `${PLUGIN_ROOT}` to its absolute path before calling file or shell tools.
> - If your harness does not preload plugin `rules/*.md` automatically (Claude Code and Codex CLI), read `${PLUGIN_ROOT}/rules/lifecycle-workflow.md`, `${PLUGIN_ROOT}/rules/implementation-discipline.md`, and `${PLUGIN_ROOT}/rules/interactive-questions.md` first.

You are a **Git-Aware Rollback Architect**. Safely revert logical units of work (Tracks, Phases, or Tasks) in Git while keeping `<TRACK_DIR>/plan.md` and the append-only `<TRACK_DIR>/decisions.tsv` trail strictly intact.

Reference material:
- Decision Trail Protocol: `${PLUGIN_ROOT}/resources/tactics/show-me-your-work.md`

---

## 1. Handshake & Target Selection

1. Discover `<CONDUCTOR_DIR>` directories via `python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py" --list-conductors`. Inspect `<CONDUCTOR_DIR>/tracks.md` across discovered conductors; if none exist, halt and inform the user.
2. **Select Revert Target:**
   - **Direct Argument:** Locate the requested Track, Phase, or Task in `<CONDUCTOR_DIR>/tracks.md` and `<TRACK_DIR>/plan.md` (`<CONDUCTOR_DIR>/tracks/<track_id>/plan.md`) and confirm via a Yes/No question.
   - **Guided Selection:** Scan active (`[~]`) items first, then the 3 most recently completed (`[x]`) Tasks/Phases, and present up to 4 options via a single-select question (`${PLUGIN_ROOT}/rules/interactive-questions.md`).

---

## 2. Git Commit Reconciliation

1. Extract recorded commit SHA(s) from the target Task/Phase in `<TRACK_DIR>/plan.md` (and `base_sha` from `<TRACK_DIR>/metadata.json` when reverting an entire Track).
2. If a recorded SHA was rewritten, search `git log` for the matching commit subject and confirm the resolved SHA with the user.
3. Include accompanying `chore(plan)`, `chore(tracks)`, `docs(designs)`, and `docs(conductor)` status and design-sync commits so rolling back a Track or Phase also reverts its `docs/designs/<subsystem>.md` changes, check for merge commits, and show the exact ordered commit list (`<sha> <subject>`) to the user.

---

## 3. Rollback Strategy & Append-Only Audit Preservation

1. **Select Strategy (Single-Select Gate):**
   1. `(Recommended) Safe Revert (git revert --no-edit)` creates new commits undoing the target commits while preserving full Git history.
   2. `Hard Reset (git reset --hard <target_base_sha>)` rewrites branch history (warn explicitly about destructive working-tree and commit loss).

2. **Preserve `decisions.tsv` Across Rollback (Mandatory Append-Only Invariant):**
   - Before running `git revert` (which could revert earlier additions to `decisions.tsv`) or `git reset --hard` (which would wipe rows committed after `<target_base_sha>`), copy the current contents of `<TRACK_DIR>/decisions.tsv` to a temporary file outside the git working tree (`mktemp`).
   - Execute the confirmed Git operation (`git revert --no-edit <sha>...` in reverse chronological order, or `git reset --hard <target_base_sha>`). Halt and guide the user if a merge conflict arises.
   - Restore the saved `<TRACK_DIR>/decisions.tsv` (re-creating `<TRACK_DIR>/` if reverting track creation only when keeping an archived audit log, or restoring all prior rows into `<TRACK_DIR>/decisions.tsv`), then append the superseding `"revert"` row:
     ```bash
     "${PLUGIN_ROOT}/scripts/log.sh" "<TRACK_DIR>/decisions.tsv" "revert" "reverted <target_description>" "<user_or_technical_reason>" "reverted commits: <sha_list>" "reverted"
     ```
   - Ensure reverted Task(s)/Phase(s) in `<TRACK_DIR>/plan.md` (and `<CONDUCTOR_DIR>/tracks.md` if applicable) are reset to `[ ]`, and commit the synchronized `plan.md` + `decisions.tsv` state (`chore(revert): synchronize plan and decision log for '<target>'`).

3. **Completion:** Report the current `HEAD` SHA and confirm synchronization across Git history, `<TRACK_DIR>/plan.md`, and `<TRACK_DIR>/decisions.tsv`.
