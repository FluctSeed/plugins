---
trigger: always_on
description: Engineering execution, root-cause debugging, behavioral TDD, runtime proof, and audit logging rules during Phase 2 (/implement and /review).
---

# Empirical Implementation & Verification Rules

1. **Restate Goal & Smallest Change**
   - On implementation tasks, state in your own words the user's goal, the problem being solved, and the smallest code change expected to meet it.
2. **Empirical Over Speculative (`Classify before AskQuestion`)**
   - Never ask the human a question that an experiment or codebase trace (`resources/tactics/how.md`, `why.md`, `resources/playbooks/prototype.md`) can answer.
3. **Model the Domain First (`principle-model-the-domain`)**
   - Before writing control flow, name the data shape and encode the domain in types, state machines, or tables rather than scattered booleans. Concentrate validation at system boundaries (`principle-boundary-discipline`, `principle-type-system-discipline`).
4. **Reproduce & Fix Root Causes (`principle-fix-root-causes`)**
   - When fixing a bug, reproduce it on the matching surface first. Trace the symptom back to the first place the system went wrong using runtime evidence. Never ship a speculative guard that hides an invalid state.
5. **Laziness Protocol & Subtract Before You Add**
   - Bias toward deletion and the smallest diff that solves the problem. Remove dead weight first, collapse one-caller wrappers (`principle-minimize-reader-load`), and delete obsolete legacy APIs after migrating callers (`principle-migrate-callers-then-delete-legacy-apis`).
6. **Prove It Works (`principle-prove-it-works`)**
   - Verify every task against the real artifact rather than a proxy or "it compiles". Record actual test and build outputs in `<TRACK_DIR>/verification.log` via `scripts/capture-verify-log.sh`.
7. **Decision Trail (`show-me-your-work`)**
   - Log every significant engineering decision, pivot, and completed task verification in `<TRACK_DIR>/decisions.tsv` using `scripts/log.sh`. The log is append-only; supersede wrong calls with a new row rather than deleting prior rows.
8. **Zero Slop & Zero Narrating Comments (`unslop` & `no-comments`)**
   - Write short declarative prose without em-dashes. Keep code comments only for non-obvious external constraints that code cannot express; audit comments with `agents/comment-auditor.md`.
