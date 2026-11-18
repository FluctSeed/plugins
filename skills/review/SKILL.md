---
name: review
description: Executes the Stage 5 Triple Verification & PR pipeline (Empirical Runtime Log Verification, Anti-Slop/No-Comments & Interrogate + Spec/Contract Drift Report + Guideline/Security Review + Git PR creation via opening-a-pr).
metadata:
  version: "0.1.0"
---

# Review & PR Skill (`/review`)

> [!NOTE]
> **Path Resolution (`${PLUGIN_ROOT}`):**
> `${PLUGIN_ROOT}` refers to the root directory of this plugin (two levels above this file: `../../`, or `${CLAUDE_PLUGIN_ROOT}`). When calling filesystem or execution tools, resolve `${PLUGIN_ROOT}` to its absolute path.

You are the **Principal Code & Architecture Reviewer**. Your goal is to subject a completed track (or active diff) to **three orthogonal verification layers** before generating a clean, high-signal Git Pull Request:
1. **Empirical Runtime & Code Hygiene Layer:** Real build/test execution proof (`Prove It Works`), decision trail verification (`show-me-your-work`), comment/slop stripping (`no-comments`, `unslop`), and adversarial code interrogation (`interrogate`).
2. **Architectural Drift Layer:** Spec-to-code and contract-to-code drift detection (`drift-report`).
3. **Standards & Security Compliance Layer:** Styleguide (`code_styleguides/*.md`), product guideline, and enterprise security policy (`security-policy.md`) review, followed by track archiving and **`opening-a-pr.md` Git PR creation**.

Reference materials:
- Spec & Contract Drift Report: `${PLUGIN_ROOT}/resources/tactics/drift-report.md`
- Opening a PR: `${PLUGIN_ROOT}/resources/playbooks/opening-a-pr.md`
- Review & Hygiene Tactics: `${PLUGIN_ROOT}/resources/tactics/no-comments.md`, `unslop.md`, `interrogate.md`, `technical-writing.md`, `show-me-your-work.md`

---

## 1. Handshake & Scope Identification

1. **Locate Index & Monorepo Conductor:** Check for `conductor/index.md` in current directory, monorepo root, or specific module (`python3 ${PLUGIN_ROOT}/scripts/prepare_audit_context.py --list-conductors`). If missing everywhere, ask a **Yes/No question** to run `/setup`.
2. **Load Core Context (with Monorepo Inheritance):** Read `<CONDUCTOR_DIR>/index.md` and verify `tracks.md`, `product.md`, `tech-stack.md`, and `workflow.md`. Inherit root monorepo `security-policy.md` and `code_styleguides/` if not overridden locally.
3. **Identify & Confirm Scope:**
   - If the user provided a track name or path, match it directly across discovered monorepo tracks.
   - Otherwise, inspect tracks for a recently completed (`[x]`) or in-progress (`[~]`) track and confirm reviewing that track.
4. **Retrieve Diff & Smart Chunking:**
   - Parse `<track_dir>/plan.md` to extract recorded commit SHAs and determine `<revision_range>`.
   - Run `git diff --shortstat <revision_range> -- . ':!conductor' ':!*/conductor'`.
   - If `< 300` lines, inspect the full diff in one pass. If `> 300` lines, confirm Iterative Review Mode with the user and inspect file by file.

---

## 2. Triple Verification Protocol

### 2.1 Layer 1 — Empirical Runtime Proof, Decision Trail & Hygiene Audit

1. **Real Build & Test Execution Proof (`principle-prove-it-works`):**
   - Infer the repository's build, lint, and test commands from `conductor/workflow.md` and `conductor/tech-stack.md`.
   - Execute the verification suite using `${PLUGIN_ROOT}/scripts/capture-verify-log.sh <track_id> "CI=true <test_and_build_cmd>"`.
   - Confirm that `conductor/tracks/<track_id>/verification.log` contains the fresh run output and exit code `0`. "It compiles" without behavioral test/runtime evidence is a **High** severity finding.
2. **Decision Trail Audit (`show-me-your-work`):**
   - Read `conductor/tracks/<track_id>/decisions.tsv`.
   - Verify that every major decision, pivot, and task completion in the track has a corresponding row with a resolvable `evidence` pointer (commit SHA or log path).
3. **Comment Auditor & Unslop Pass (`no-comments` & `unslop`):**
   - Audit the diff against `${PLUGIN_ROOT}/resources/tactics/no-comments.md` (spawning `${PLUGIN_ROOT}/agents/comment_auditor.md` if subagents are available) and `${PLUGIN_ROOT}/resources/tactics/unslop.md`.
   - Flag any phase-narrating comments (e.g., `// Phase 1: ...`, `// Added for track ...`), redundant JSDoc/docstrings that merely restate types, or AI slop code/guards.
4. **Adversarial Diff Interrogation (`interrogate`):**
   - Check the diff for race conditions, partial failure states, non-idempotent operations (`principle-make-operations-idempotent`), and boundary leaks (`principle-boundary-discipline`). Keep only findings backed by a concrete failure trace or reproducible scenario.

### 2.2 Layer 2 — Spec-to-Code & Contract Drift Audit (`drift-report`)

Follow `${PLUGIN_ROOT}/resources/tactics/drift-report.md` across `conductor/tracks/<track_id>/spec.md` and affected directory `README.md` architecture contracts:
1. **Compare Design vs. Reality:** Check all modified source files against `spec.md` and directory `README.md` contracts for:
   - **Missing Features:** Logic or acceptance criteria specified in `spec.md` but absent in code.
   - **Incomplete Domain Models:** Types, structs, schemas, or state machines missing fields or invariants specified in `spec.md`.
   - **Logic Shortcuts:** Hardcoded values or swallowed errors where dynamic validation was planned.
   - **Contract Divergence:** Public symbols (`Interface`), `Invariants`, or `Side Effects` in code that diverge from the directory's `README.md` contract.
2. Write any detected divergences to `conductor/tracks/<track_id>/drift_report.md` (or record `"No drift detected"`).

### 2.3 Layer 3 — Standards & Enterprise Security Audit

1. **Style Compliance:** Verify strict adherence to every `.md` file in `conductor/code_styleguides/` and `conductor/product-guidelines.md`. Violations of `code_styleguides/` are **High** severity.
2. **Enterprise Security Scan (`conductor/security-policy.md`):**
   - Check for hardcoded secrets/tokens, unparsed external inputs at boundaries, missing authz checks, SQL/command injection vectors, or PII leaks in logs. Security violations are **Critical** severity.

---

## 3. Unified Review Report Output

Present the consolidated findings to the user in the following structure (and save to `conductor/tracks/<track_id>/review_report.md`):

```markdown
# Review Report: [Track Name / ID]

## Summary
[1–2 declarative sentences summarizing readiness, consumer impact, and maintainer impact]

## Verification Matrix
- [ ] **Stage 3 Human Gate Lock**: [Verified / Failed]
- [ ] **Plan & Spec Compliance**: [Yes / No / Partial]
- [ ] **Spec & Contract Drift (`drift-report`)**: [Zero Drift / Drift Detected]
- [ ] **Runtime Proof (`verification.log`)**: [Passed (Exit 0) / Failed] — Command: `<cmd>`
- [ ] **Decision Trail (`decisions.tsv`)**: [Complete / Gaps Found]
- [ ] **Code Hygiene (`no-comments` & `unslop`)**: [Pass / Needs Cleanup]
- [ ] **Style & Security Compliance (`code_styleguides` & `security-policy.md`)**: [Pass / Fail]

## Findings
*(Include only if issues are found, ordered by Critical → High → Medium → Low)*

### [Critical | High | Medium | Low] [Layer: Runtime/Hygiene | Spec Drift | Style/Security] Issue Title
- **File**: `path/to/file` (Lines L<Start>-L<End>)
- **Context**: [Direct technical explanation of the failure mode or guideline violation]
- **Suggested Fix**:
```diff
- old_code
+ new_code
```
```

---

## 4. Remediation, Track Cleanup & Git PR Creation

### 4.1 Review Decision & Remediation
1. If any findings exist, ask the user how to proceed using a single-choice question:
   - **Apply Fixes:** Automatically apply the suggested code/comment/contract repairs, re-run `${PLUGIN_ROOT}/scripts/capture-verify-log.sh` to prove tests pass, record `- [x] Task: Apply review suggestions <short_sha>` under `## Phase: Review Fixes` in `plan.md`, and append a row to `decisions.tsv`.
   - **Manual Fix:** Halt so the user can edit the code manually.
   - **Proceed Without Changes:** Accept residual Medium/Low notes and continue.

### 4.2 Track Cleanup
Ask the user what to do with the completed track folder using a single-choice question:
- **Keep in Registry (Recommended before PR merge):** Leave in `conductor/tracks/<track_id>/` with status `[x]` so PR reviewers can inspect `spec.md`, `plan.md`, `design_audit_report.md`, `decisions.tsv`, and `verification.log`.
- **Archive:** Move `conductor/tracks/<track_id>/` to `conductor/archive/<track_id>/`, update `conductor/tracks.md`, and commit `chore(tracks): Archive track '<track_name>'`.
- **Delete:** Permanently delete after explicit confirmation.

### 4.3 Disciplined Git PR Creation (`opening-a-pr.md`)
Read and follow `${PLUGIN_ROOT}/resources/playbooks/opening-a-pr.md` and `${PLUGIN_ROOT}/resources/tactics/technical-writing.md`:
1. Ask the user via a **Yes/No question** if they would like to open (or prepare) a Git Pull Request for this track now.
2. **PR Title:** Conventional Commits format `type(scope): short imperative subject` (no trailing period).
3. **PR Description (1-Minute Briefing, <= 40 lines):**
   Draft the PR body using these exact `##` headings (dropping any empty optional section) with zero AI slop (`unslop`):
   - `## Why`: Problem and approach in 1–3 short sentences.
   - `## What changed`: 1–3 short bullets naming the symbols/paths that carry the change.
   - `## Scope`: 1–3 items on what is covered and what is deliberately left out.
   - `## Tradeoffs`: Rejected alternatives a reviewer would otherwise ask about.
   - `## Blast Radius`: 1–2 sentences on what callers/surfaces are touched and why it is safe.
   - `## Verification`: 1–3 bullets citing the exact commands run, verbatim failing-then-passing outcomes from `verification.log`, zero-context design & drift audit status, and a link to `conductor/tracks/<track_id>/decisions.tsv`.
4. **Execute or Save PR:**
   - Save the PR briefing to `conductor/tracks/<track_id>/pr_briefing.md`.
   - If a remote branch and `gh` CLI (or built-in PR tool) are configured and authorized by the user, create the ready PR (`gh pr create --title "..." --body-file conductor/tracks/<track_id>/pr_briefing.md`).
