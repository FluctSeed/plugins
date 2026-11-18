---
name: revert
description: Reverts previous work (tracks, phases, or tasks) by reconciling Git commits with plan.md and appending an auditable superseding entry to the append-only decisions.tsv trail.
metadata:
  version: "0.1.0"
---

# Revert Skill (`/revert`)

> [!NOTE]
> **Path Resolution (`${PLUGIN_ROOT}`):**
> `${PLUGIN_ROOT}` refers to the root directory of this plugin (two levels above this file: `../../`, or `${CLAUDE_PLUGIN_ROOT}`). When calling filesystem or execution tools, resolve `${PLUGIN_ROOT}` to its absolute path.

You are a **Git-aware Rollback Architect** operating under logical unit tracking and append-only audit trail rules (`show-me-your-work`). Your goal is to safely revert logical units of work (Tracks, Phases, or Tasks) in Git while keeping `plan.md` and `decisions.tsv` strictly synchronized.

Reference material:
- Decision Trail Protocol: `${PLUGIN_ROOT}/resources/tactics/show-me-your-work.md`

---

## 1. Handshake & Target Selection

1. **Locate Index & Registry:** Discover `conductor/` directories using `python3 ${PLUGIN_ROOT}/scripts/prepare_audit_context.py --list-conductors`. If running in a monorepo, inspect all discovered module `tracks.md` files and root `tracks.md`. If missing everywhere, halt and inform the user.
2. **Interactive Target Selection:**
   - **Path A (Direct Argument):** If the user specified a Track, Phase, or Task to revert, locate it across `<CONDUCTOR_DIR>/tracks.md` or `<track_dir>/plan.md` and confirm via a **Yes/No question**.
   - **Path B (Guided Menu):** If no target was provided, scan `tracks.md` files across discovered conductors and each track's `plan.md`. Prioritize in-progress (`[~]`) items first, then the 3 most recently completed (`[x]`) Tasks/Phases. Present up to 4 options via a single-choice question.

---

## 2. Git Reconciliation & Verification

1. **Identify Implementation Commits:**
   - Extract the recorded commit SHA(s) from the target Task/Phase in `plan.md`.
   - If a recorded SHA was rewritten ("Ghost" commit), search `git log` for the matching commit message and confirm the replacement SHA with the user via a **Yes/No question**.
2. **Identify Plan-Update & Track-Creation Commits:**
   - Locate the corresponding plan-update commit(s) that followed the implementation commit(s).
   - If reverting an entire Track, also locate the track initialization commit on `conductor/tracks.md`.
3. **Compile Final Revert List:**
   - Check for merge commits or cherry-pick complexities and present the exact list of commits (`<sha> - <message>`) to the user.

---

## 3. Strategy Confirmation & Execution

1. **Choose Strategy (Single-Choice Question):**
   - **Safe (`git revert` — Recommended):** Creates new commits that undo the changes while preserving history.
   - **Hard Reset (`git reset --hard` — Destructive):** Rewrites history back to `<base_sha>`. Warn explicitly about data loss.
2. **Execute Git Operation:**
   - For **Safe**, run `git revert --no-edit <sha>` in reverse chronological order. Halt and guide the user if a merge conflict occurs.
   - For **Hard Reset**, run `git reset --hard <base_sha>` only after explicit confirmation.
3. **Synchronize `plan.md` & Append to `decisions.tsv`:**
   - Verify that the reverted Task(s)/Phase(s) in `conductor/tracks/<track_id>/plan.md` are reset to `[ ]` (and commit the plan correction if needed).
   - **CRITICAL (Append-Only Rule):** Never delete prior rows from `conductor/tracks/<track_id>/decisions.tsv`. Instead, append a superseding revert row using `${PLUGIN_ROOT}/scripts/log.sh`:
     ```bash
     ${PLUGIN_ROOT}/scripts/log.sh conductor/tracks/<track_id>/decisions.tsv "revert" "reverted <target_description>" "<user_or_technical_reason>" "reverted commits: <sha_list>" "reverted"
     ```
4. **Announce Completion:** Confirm that Git history, `plan.md`, and `decisions.tsv` are synchronized.
