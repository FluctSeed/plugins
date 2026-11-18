---
name: recall
description: Reconstruct recent working context for the active repository from workspace session transcripts, conductor track logs, and live git/PR state into a tight current-state brief.
---

# Recall

Rebuild working context before starting or resuming multi-session work and return a concise capsule of current state, open threads, recurring problems, and the single best next move.

## Protocol

1. **Lock Scope:** Restrict transcript inspection strictly to the **active workspace** (default window: last 7 days) and any named topic:
   - **Antigravity:** `<appDataDir>/brain/*/.system_generated/logs/transcript.jsonl` matching the active workspace URI.
   - **Claude Code:** `~/.claude/projects/<workspace-slug>/*.jsonl`.
   - **Codex CLI:** `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` whose header `payload.cwd` matches the workspace path.
2. **Inspect Track & Git Record in Parallel:**
   - Read `<CONDUCTOR_DIR>/tracks.md` and active `<TRACK_DIR>/decisions.tsv` / `plan.md` if present.
   - Check live repository state via `git status -sb`, `git branch -a`, `git log -n 15 --oneline`, and `gh pr list` (when `gh` is available).
3. **Verify Against Live State:** Cross-check historical chat claims against current `HEAD` commits and open PRs so reverted or superseded attempts are accurately flagged.

## Output Contract

Keep the brief compact and factual (`resources/tactics/unslop.md`):
- **Capsule:** At most 5 bullets summarizing overall state.
- **Threads:** One line per workstream prefixed with `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted]`, or `[planned]`.
- **Problems:** Up to 5 recurring blockers or previously reverted approaches not to repeat.
- **Next Move:** One concrete, immediately actionable step.
