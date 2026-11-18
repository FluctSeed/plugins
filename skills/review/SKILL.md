---
name: review
description: Executes the Stage 5 Triple Verification & PR pipeline (Empirical Runtime Log Verification, Anti-Slop/No-Comments & Interrogate + Spec/Contract Drift Report + Guideline/Security Review + Git PR creation via opening-a-pr).
metadata:
  version: "0.1.0"
---

# Review & PR Skill (`review`)

> [!NOTE]
> **Plugin Root & Governance Rules (`${PLUGIN_ROOT}`)**
> - `${PLUGIN_ROOT}` is the root directory of this plugin (`${CLAUDE_PLUGIN_ROOT}` if expanded by your harness, otherwise two directories above this `SKILL.md` file). Resolve `${PLUGIN_ROOT}` to its absolute path before calling file or shell tools.
> - If your harness does not preload plugin `rules/*.md` automatically (Claude Code and Codex CLI), read `${PLUGIN_ROOT}/rules/lifecycle-workflow.md`, `${PLUGIN_ROOT}/rules/implementation-discipline.md`, and `${PLUGIN_ROOT}/rules/interactive-questions.md` first.

You are the **Principal Code & Architecture Reviewer**. Subject a completed track (or active diff) to three orthogonal verification layers before preparing or opening a Git Pull Request:
1. **Layer 1 (Empirical Runtime & Code Hygiene):** Fresh build/test execution proof (`Prove It Works`), decision trail check (`show-me-your-work`), comment/workaround audit (`comment-auditor` / `no-comments` / `unslop`), and adversarial failure interrogation (`interrogate`).
2. **Layer 2 (Architectural Drift):** Spec-to-code and `README.md` contract-to-code drift detection (`drift_report.md`).
3. **Layer 3 (Standards & Security Compliance):** Styleguide (`code_styleguides/*.md`), product guideline, and enterprise security policy (`security-policy.md`) verification, followed by PR creation (`opening-a-pr.md`).

Reference materials:
- Spec & Contract Drift Report: `${PLUGIN_ROOT}/resources/tactics/drift-report.md`
- Opening a PR: `${PLUGIN_ROOT}/resources/playbooks/opening-a-pr.md`
- Hygiene & Interrogation Tactics: `${PLUGIN_ROOT}/resources/tactics/no-comments.md`, `unslop.md`, `interrogate.md`, `technical-writing.md`, `show-me-your-work.md`

---

## 1. Handshake, Track Scope & Accurate Diff Range

1. **Resolve `<CONDUCTOR_DIR>` & `<TRACK_DIR>`:**
   - Run `python3 "${PLUGIN_ROOT}/scripts/prepare_audit_context.py" --list-conductors` (or `--conductor-dir "<CONDUCTOR_DIR>"`) to load active and inherited context (`security-policy.md`, `code_styleguides/*.md`, `workflow.md`).
   - Identify `<TRACK_DIR>` (`<CONDUCTOR_DIR>/tracks/<track_id>`) from the user's argument or confirm the most recently completed (`[x]`) / active (`[~]`) track in `<CONDUCTOR_DIR>/tracks.md`.
2. **Verify Gate Integrity & Compute Full Track Diff (`base_sha`):**
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

### 2.2 Layer 2: Spec-to-Code & Contract Drift Audit (`<TRACK_DIR>/drift_report.md`)
Follow `${PLUGIN_ROOT}/resources/tactics/drift-report.md` comparing the code diff against `<TRACK_DIR>/spec.md` and affected directory `README.md` contracts (`Interface`, `Invariants`, `Side Effects`). Write the result to **`<TRACK_DIR>/drift_report.md`** (recording `"No drift detected"` when clean).

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
- [ ] **Spec & Contract Drift (`drift_report.md`)**: [Zero Drift / Drift Detected]
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
   - `(Recommended) Apply Fixes` (apply code/comment/contract fixes, re-run `capture-verify-log.sh` to prove exit `0`, append `- [x] Task: Apply review suggestions <short_sha>` under `## Phase: Review Fixes` in `<TRACK_DIR>/plan.md`, and log to `<TRACK_DIR>/decisions.tsv`)
   - `Manual Fix` (halt for developer edits)
   - `Proceed Without Changes` (only when zero Critical/High findings exist)
2. **Track Registry Disposition:** Ask whether to `(Recommended) Keep in Registry` before PR merge, `Archive` to `<CONDUCTOR_DIR>/archive/<track_id>/`, or `Delete`.
3. **Git Pull Request (`${PLUGIN_ROOT}/resources/playbooks/opening-a-pr.md`):**
   - Verify the repository is on a named branch (not detached `HEAD`), draft `<TRACK_DIR>/pr_briefing.md` (`<= 40` lines: `## Why`, `## What changed`, `## Scope`, `## Tradeoffs`, `## Blast Radius`, `## Verification`), and upon developer confirmation create the PR (`gh pr create --title "..." --body-file "<TRACK_DIR>/pr_briefing.md"`).
