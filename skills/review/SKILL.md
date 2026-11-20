---
name: review
description: Executes the Stage 5 Triple Verification & PR pipeline for tracks, or runs standalone Zero-Context Document Review (Stages 5-9) or standalone Spec/Contract Drift Reports when invoked on a design doc or directory.
metadata:
  version: "0.2.1"
---

# Review & PR Skill (`review`)

> [!NOTE]
> **Plugin Root & Governance Rules (`${PLUGIN_ROOT}`)**
> - `${PLUGIN_ROOT}` is the root directory of this plugin (`${CLAUDE_PLUGIN_ROOT}` if expanded by your harness, otherwise two directories above this `SKILL.md` file). Resolve `${PLUGIN_ROOT}` to its absolute path before calling file or shell tools.
> - If your harness does not preload plugin `rules/*.md` automatically (Claude Code and Codex CLI), read `${PLUGIN_ROOT}/rules/lifecycle-workflow.md`, `${PLUGIN_ROOT}/rules/implementation-discipline.md`, and `${PLUGIN_ROOT}/rules/interactive-questions.md` first.

You are the **Principal Code & Architecture Reviewer**. Route execution to one of three verification modes based on the caller's target:
- **Mode A (Track Triple Verification & PR - Default):** Subject a completed or active track (`<TRACK_DIR>`) to Layer 1 (Runtime Proof + Decision Trail + `comment-auditor` + `interrogate`), Layer 2 (`drift_report.md`), Layer 3 (`code_styleguides/*.md` + `security-policy.md`), and Git PR creation (`opening-a-pr.md`).
- **Mode B (Standalone Zero-Context Document Audit):** When given a `.md` design document or RFC outside `tracks/` (for example `docs/designs/auth.md` or `<MODULE_ROOT>/docs/designs/auth.md`), run `${PLUGIN_ROOT}/resources/tactics/design-review.md` (Stages 5 to 9 isolated zero-context subagent review) and `${PLUGIN_ROOT}/resources/tactics/design-resolve.md` directly without requiring an initialized track.
- **Mode C (Standalone Codebase & Contract Drift Audit):** When given a directory path or an explicit drift-detection request without a track target, run `${PLUGIN_ROOT}/resources/tactics/drift-report.md` directly against directory `README.md` contracts / design docs and live code, writing `drift_report.md`.

Reference materials:
- Spec & Contract Drift Report: `${PLUGIN_ROOT}/resources/tactics/drift-report.md`
- Standalone Zero-Context Design Review: `${PLUGIN_ROOT}/resources/tactics/design-review.md`, `design-review-loop.md`, `design-resolve.md`
- Opening a PR: `${PLUGIN_ROOT}/resources/playbooks/opening-a-pr.md`
- Hygiene & Interrogation Tactics: `${PLUGIN_ROOT}/resources/tactics/no-comments.md`, `unslop.md`, `interrogate.md`, `formal-verification.md`, `benchmark-checklist.md`, `technical-writing.md`, `show-me-your-work.md`

---

## 1. Mode Routing, Track Scope & Accurate Diff Range

1. **Detect Mode from Target Argument:**
   - **Standalone Design Doc (`.md` file outside `tracks/`):** Execute **Mode B** following `${PLUGIN_ROOT}/resources/tactics/design-review.md` (passing `python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py"` output as `AuditContext` when `<CONDUCTOR_DIR>/index.md` exists, except Stage 6 `comprehension` which receives zero context) and halt after `design-resolve.md`.
   - **Standalone Directory / Drift Request:** Execute **Mode C** following `${PLUGIN_ROOT}/resources/tactics/drift-report.md` and halt after presenting `drift_report.md`.
   - **Track Review (Default):** Proceed with **Mode A** below.
2. **Resolve `<CONDUCTOR_DIR>` & `<TRACK_DIR>` (Mode A):**
   - Run `python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py" --list-conductors` (or `--conductor-dir "<CONDUCTOR_DIR>"`) to load active and inherited context (`security-policy.md`, `code_styleguides/*.md`, `workflow.md`).
   - Identify `<TRACK_DIR>` (`<CONDUCTOR_DIR>/tracks/<track_id>`) from the user's argument or confirm the most recently completed (`[x]`) / active (`[~]`) track in `<CONDUCTOR_DIR>/tracks.md`.
3. **Verify Gate Integrity & Compute Full Track Diff (`base_sha`):**
   - Run `python3 "${PLUGIN_ROOT}/scripts/gate_check.py" --status "<TRACK_DIR>"` and read `base_sha` from `<TRACK_DIR>/metadata.json`.
   - Compute the full implementation diff without dropping the first task commit:
     - If `base_sha` is recorded and valid: `git diff "<base_sha>..HEAD" -- . ':!conductor' ':!*/conductor'`
     - Else if `<first_task_sha>^` exists: `git diff "<first_task_sha>^..HEAD" -- . ':!conductor' ':!*/conductor'`
     - Else (initial root commit repository): `git show --root HEAD -- . ':!conductor' ':!*/conductor'`
   - Check diff size with `--shortstat`; if larger than 300 lines, inspect file by file so no file is skipped.

---

## 2. Triple Verification Protocol

### 2.1 Layer 1: Empirical Runtime Proof, Decision Trail & Hygiene Audit
1. **Real Build & Test Execution Proof (`principle-prove-it-works`):**
   - Run the build, lint, and behavioral test commands from `workflow.md` via:
     ```bash
     "${PLUGIN_ROOT}/scripts/capture-verify-log.sh" "<TRACK_DIR>" "CI=true <test_and_build_cmd>"
     ```
   - Confirm `<TRACK_DIR>/verification.log` records exit code `0` on the current `HEAD`. Missing behavioral test evidence is a **High** finding.
2. **Decision Trail Audit (`show-me-your-work`):**
   - Inspect `<TRACK_DIR>/decisions.tsv` and confirm major decisions, pivots, and task completions carry resolvable commit/log evidence pointers.
3. **Read-Only Comment & Slop Audit (`no-comments` & `unslop`):**
   - Dispatch read-only `comment-auditor` (`invoke_subagent` `comment-auditor` in Antigravity, `Agent` `fluctseed:comment-auditor` in Claude Code, or `spawn_agent` reading `${PLUGIN_ROOT}/agents/comment-auditor.md` in Codex CLI) against the diff, and check `${PLUGIN_ROOT}/resources/tactics/unslop.md`. Do **not** edit code until Section 4.1 user approval.
4. **Adversarial Diff Interrogation (`${PLUGIN_ROOT}/resources/tactics/interrogate.md`):**
   - Check for race conditions, partial failure states, non-idempotent mutations (`principle-make-operations-idempotent`), and boundary validation gaps (`principle-boundary-discipline`). Report only findings backed by a concrete failure scenario.

### 2.2 Layer 2: Spec, Living Design & Contract Drift Audit (`<TRACK_DIR>/drift_report.md`)
Follow `${PLUGIN_ROOT}/resources/tactics/drift-report.md` comparing the code diff against `<TRACK_DIR>/spec.md`, `<MODULE_ROOT>/docs/designs/<subsystem>.md` (verifying that subsystem architecture and `Key Decisions & Alternatives Rejected` are synchronized with `<TRACK_DIR>/decisions.tsv`), and affected directory `README.md` contracts (`Interface`, `Invariants`, `Side Effects`). Write the result to **`<TRACK_DIR>/drift_report.md`** (recording `"No drift detected"` when clean).

### 2.3 Layer 3: Styleguides & Enterprise Security Audit
1. **Style Compliance:** Check adherence to active and inherited `code_styleguides/*.md` (**High** severity on violation).
2. **Enterprise Security Scan (`security-policy.md`):** Check for hardcoded secrets, unvalidated external inputs, missing authz checks, injection vectors, or PII in logs (**Critical** severity on violation).

---

## 3. Consolidated Review Report (`<TRACK_DIR>/review_report.md`)

Write `<TRACK_DIR>/review_report.md` on disk first and share its clickable link and summary in chat:

```markdown
# Review Report: [Track ID]

## Summary
[1 to 2 declarative sentences on readiness, consumer impact, and maintainer impact.]

## Verification Matrix
- [ ] **Stage 3 Human Gate Lock**: [Verified / Failed]
- [ ] **Spec, Living Design (`docs/designs/`) & Contract Drift (`drift_report.md`)**: [Zero Drift / Drift Detected]
- [ ] **Runtime Proof (`verification.log`)**: [Passed (Exit 0) / Failed] (`<cmd>`)
- [ ] **Decision Trail (`decisions.tsv`)**: [Complete / Gaps Found]
- [ ] **Code Hygiene (`comment-auditor` & `unslop`)**: [Pass / Needs Cleanup]
- [ ] **Style & Security (`code_styleguides` & `security-policy.md`)**: [Pass / Fail]

## Findings (Critical -> High -> Medium -> Low)
### [Severity] [Layer] Issue Title
- **Location**: `path/to/file` (Lines LStart-LEnd)
- **Failure Mechanism**: [Concrete technical explanation]
- **Proposed Fix**: [Minimal diff or action]
```

---

## 4. Remediation, Track Cleanup & Git PR Creation

1. **Remediation Gate (if findings exist):** Ask via single-select gate (`${PLUGIN_ROOT}/rules/interactive-questions.md`):
   - `(Recommended) Apply Fixes` (apply code/comment/contract/`docs/designs/<subsystem>.md` fixes, re-run `capture-verify-log.sh` to prove exit `0`, append `- [x] Task: Apply review suggestions <short_sha>` under `## Phase: Review Fixes` in `<TRACK_DIR>/plan.md`, and log to `<TRACK_DIR>/decisions.tsv`)
   - `Manual Fix` (halt for developer edits)
   - `Proceed Without Changes` (only when zero Critical/High findings exist)
2. **Track Registry Disposition:** Confirm `<MODULE_ROOT>/docs/designs/<subsystem>.md` and `**/README.md` contracts are synchronized (so deleting `<TRACK_DIR>/` loses zero architectural or decision context), then ask whether to `(Recommended) Keep in Registry` before PR merge, `Archive` to `<CONDUCTOR_DIR>/archive/<track_id>/`, or `Delete`.
3. **Git Pull Request (`${PLUGIN_ROOT}/resources/playbooks/opening-a-pr.md`):**
   - Verify the repository is on a named branch (not detached `HEAD`), draft `<TRACK_DIR>/pr_briefing.md` (`<= 40` lines: `## Why`, `## What changed`, `## Scope`, `## Tradeoffs`, `## Blast Radius`, `## Verification`), and upon developer confirmation create the PR (`gh pr create --title "..." --body-file "<TRACK_DIR>/pr_briefing.md"`).
